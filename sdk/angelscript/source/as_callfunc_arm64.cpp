/*
   AngelCode Scripting Library
   Copyright (c) 2003-2020 Andreas Jonsson

   This software is provided 'as-is', without any express or implied
   warranty. In no event will the authors be held liable for any
   damages arising from the use of this software.

   Permission is granted to anyone to use this software for any
   purpose, including commercial applications, and to alter it and
   redistribute it freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you
      must not claim that you wrote the original software. If you use
      this software in a product, an acknowledgment in the product
      documentation would be appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and
      must not be misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
      distribution.

   The original version of this library can be located at:
   http://www.angelcode.com/angelscript/

   Andreas Jonsson
   andreas@angelcode.com
*/


//
// as_callfunc_arm64.cpp
//
// These functions handle the actual calling of system functions on the arm64 platform
//
// Written by Max Waine in July 2020, based on as_callfunc_arm.cpp
//


#include "as_config.h"

#ifndef AS_MAX_PORTABILITY
#ifdef AS_ARM64

#include "as_callfunc.h"
#include "as_scriptengine.h"
#include "as_texts.h"
#include "as_tokendef.h"
#include "as_context.h"

// ARM64 targets use has no software floating-point ABI, it's all hardware (or totally disabled)

#define HFA_RET_REGISTERS   4 // s0-s3/d0-d3
#define GP_ARG_REGISTERS    8 // x0-x7
#define FLOAT_ARG_REGISTERS 8 // v0-v7

BEGIN_AS_NAMESPACE

// x0-7:   Argument registers (pass params or return results. OK as volatile local variables)
// x8:     Indirect result register (e.g. address of large returned struct)
// x9-15:  Volatile local variable registers
// x16-17: Intra-procedure-call temporary registers
// x18:    Platform register (reserved for use of platform ABIs)
// x19-29: Non-volatile variable registers (must be saved and restored if modified)
// x29:    Frame pointer register
// x30:    Link register (where to return to)

extern "C" void GetHFAReturnDouble(void *out, asQWORD returnSize);
extern "C" void GetHFAReturnFloat(void *out, asQWORD returnSize);

extern "C" asQWORD CallARM64RetInMemory(
	const asQWORD *gpRegArgs,    asQWORD numGPRegArgs,
	const asQWORD *floatRegArgs, asQWORD numFloatRegArgs,
	const asQWORD *stackArgs,    asQWORD numStackArgs,
	void *retPointer,            asFUNCTION_t func
);
extern "C" double CallARM64Double(
	const asQWORD *gpRegArgs,    asQWORD numGPRegArgs,
	const asQWORD *floatRegArgs, asQWORD numFloatRegArgs,
	const asQWORD *stackArgs,    asQWORD numStackArgs,
	asFUNCTION_t func
);
extern "C" float CallARM64Float(
	const asQWORD *gpRegArgs,    asQWORD numGPRegArgs,
	const asQWORD *floatRegArgs, asQWORD numFloatRegArgs,
	const asQWORD *stackArgs,    asQWORD numStackArgs,
	asFUNCTION_t func
);
extern "C" asQWORD CallARM64(
	const asQWORD *gpRegArgs,    asQWORD numGPRegArgs,
	const asQWORD *floatRegArgs, asQWORD numFloatRegArgs,
	const asQWORD *stackArgs,    asQWORD numStackArgs,
	asFUNCTION_t func
);

asQWORD CallSystemFunctionNative(asCContext *context, asCScriptFunction *descr, void *obj, asDWORD *args, void *retPointer, asQWORD &/*retQW2*/, void *secondObject)
{
	//asCScriptEngine *engine = context->m_engine;
	const asSSystemFunctionInterface *const sysFunc = descr->sysFuncIntf;
	const asCDataType &retType = descr->returnType;
	const asCTypeInfo *const retTypeInfo = retType.GetTypeInfo();
	asFUNCTION_t func = sysFunc->func;
	int callConv = sysFunc->callConv;
	asQWORD       retQW     = 0;

	asQWORD       gpRegArgs[GP_ARG_REGISTERS];
	asQWORD       floatRegArgs[FLOAT_ARG_REGISTERS];
	asQWORD       stackArgs[64]; // It's how many x64 users can have
	asQWORD       numGPRegArgs    = 0;
	asQWORD       numFloatRegArgs = 0;
	asQWORD       numStackArgs    = 0;

	// Optimization to avoid check 12 values (all ICC_ that contains THISCALL)
	if( (callConv >= ICC_THISCALL && callConv <= ICC_VIRTUAL_THISCALL_RETURNINMEM) ||
		(callConv >= ICC_THISCALL_OBJLAST && callConv <= ICC_VIRTUAL_THISCALL_OBJFIRST_RETURNINMEM) )
	{
		// Add the object pointer as the first parameter
		gpRegArgs[numGPRegArgs++] = (asQWORD)obj;
	}

	asUINT spos = 0;
	for( asUINT n = 0; n < descr->parameterTypes.GetLength(); n++ )
	{
		const asCDataType &parmType = descr->parameterTypes[n];
		const asCTypeInfo *const parmTypeInfo = parmType.GetTypeInfo();

		if( parmType.IsObject() && !parmType.IsObjectHandle() && !parmType.IsReference() )
		{

		}
		else if( parmType.IsFloatType() && !parmType.IsReference() )
		{
			if( numFloatRegArgs >= FLOAT_ARG_REGISTERS )
				stackArgs[numStackArgs++] = args[spos];
			else
				floatRegArgs[numFloatRegArgs++] = args[spos];
			spos++;
		}
		else if( parmType.IsDoubleType() && !parmType.IsReference() )
		{
			if( numFloatRegArgs >= FLOAT_ARG_REGISTERS )
				stackArgs[numStackArgs++] = *(asQWORD*)&args[spos];
			else
				floatRegArgs[numFloatRegArgs++] = *(asQWORD*)&args[spos];
			spos += 2;
		}
		else
		{
			// Copy the value directly
			asUINT parmDWords = parmType.GetSizeOnStackDWords();
			asUINT parmQWords = (parmDWords >> 1) + (parmDWords & 1);

			//const bool fitsInRegisters = numGPRegArgs + parmQWords <= GP_ARG_REGISTERS;
			//asQWORD *const argsArray = fitsInRegisters ? gpRegArgs : stackArgs;
			//asQWORD &numArgs = fitsInRegisters ? numGPRegArgs : numStackArgs;

			//for(asUINT i = 0; i < parmDWords; i++)
			//{
			//	if(i & 1)
			//	{
			//		numArgs[argsArray++] = *(asQWORD*)&args[spos];
			//		spos += 2;
			//	}
			//	else if(i + 1 == parmDWords)
			//	{
			//		numArgs[argsArray++] = args[spos++];
			//	}
			//}

			if(numGPRegArgs + parmQWords <= GP_ARG_REGISTERS)
			{
				for(asUINT i = 0; i < parmDWords; i++)
				{
					if(i & 1)
					{
						gpRegArgs[numGPRegArgs++] = *(asQWORD*)&args[spos];
						spos += 2;
					}
					else if(i + 1 == parmDWords)
					{
						gpRegArgs[numGPRegArgs++] = args[spos++];
					}
				}
			}
			else
			{
				for(asUINT i = 0; i < parmDWords; i++)
				{
					if(i & 1)
					{
						stackArgs[numStackArgs++] = *(asQWORD*)&args[spos];
						spos += 2;
					}
					else if(i + 1 == parmDWords)
					{
						stackArgs[numStackArgs++] = args[spos++];
					}
				}
			}
		}
	}

	if( retTypeInfo && (retTypeInfo->flags & asOBJ_APP_CLASS_ALLFLOATS) )
	{
		// This is to deal with HFAs (Homogeneous Floating-point Aggregates):
		// ARM64 will place all-float composite types (of equal precision)
		// with <= 4 members in the float return registers

		const bool doubles = (retTypeInfo->flags & asOBJ_APP_CLASS_ALIGN8) != 0;
		const int maxAllowedSize = doubles ? sizeof(double) * HFA_RET_REGISTERS : sizeof(float) * HFA_RET_REGISTERS;
		const int structSize = retType.GetSizeInMemoryBytes();

		CallARM64(gpRegArgs, numGPRegArgs, floatRegArgs, numFloatRegArgs, stackArgs, numStackArgs, func);
		if( structSize > maxAllowedSize )
		{

		}
		else if( doubles )
		{
			GetHFAReturnDouble(retPointer, structSize);
		}
		else
		{
			GetHFAReturnFloat(retPointer, structSize);
		}
	}
	else if( sysFunc->hostReturnFloat )
	{
		if( sysFunc->hostReturnSize == 1 )
			*(float*)&retQW = CallARM64Float(gpRegArgs, numGPRegArgs, floatRegArgs, numFloatRegArgs, stackArgs, numStackArgs, func);
		else
			*(double*)&retQW = CallARM64Double(gpRegArgs, numGPRegArgs, floatRegArgs, numFloatRegArgs, stackArgs, numStackArgs, func);
	}
	else if( sysFunc->hostReturnInMemory )
		retQW = CallARM64RetInMemory(gpRegArgs, numGPRegArgs, floatRegArgs, numFloatRegArgs, stackArgs, numStackArgs, retPointer, func);
	else
		retQW = CallARM64(gpRegArgs, numGPRegArgs, floatRegArgs, numFloatRegArgs, stackArgs, numStackArgs, func);

	return retQW;
}

END_AS_NAMESPACE

#endif // AS_ARM64
#endif // AS_MAX_PORTABILITY




