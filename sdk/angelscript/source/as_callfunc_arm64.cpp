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

#define VFP_OFFSET 70
#define STACK_OFFSET 6
#define PARAM_BUFFER_SIZE 104

BEGIN_AS_NAMESPACE

// x0-7:   Argument registers (pass params or return results. OK as volatile local variables)
// x8:     Indirect result register (e.g. address of large returned struct)
// x9-15:  Volatile local variable registers
// x16-17: Intra-procedure-call temporary registers
// x18:    Platform register (reserved for use of platform ABIs)
// x19-29: Non-volatile variable registers (must be saved and restored if modified)
// x29:    Frame pointer register
// x30:    Link register (where to return to)

extern "C" asQWORD arm64Func(const asQWORD *args, int paramSize, asFUNCTION_t func);

asQWORD CallSystemFunctionNative(asCContext *context, asCScriptFunction *descr, void *obj, asDWORD *args, void *retPointer, asQWORD &/*retQW2*/, void *secondObject)
{
	asCScriptEngine *engine = context->m_engine;
	asSSystemFunctionInterface *sysFunc = descr->sysFuncIntf;
	int callConv = sysFunc->callConv;

	asQWORD       retQW     = 0;
	asFUNCTION_t  func      = sysFunc->func;
	int           paramSize = sysFunc->paramSize;
	asFUNCTION_t *vftable;

	asQWORD *argsQW = (asQWORD*)args;

	retQW = arm64Func(argsQW, paramSize << 2, func);

	return retQW;
}

END_AS_NAMESPACE

#endif // AS_ARM64
#endif // AS_MAX_PORTABILITY




