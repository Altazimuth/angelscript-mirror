;
;  AngelCode Scripting Library
;  Copyright (c) 2003-2020 Andreas Jonsson
;
;  This software is provided 'as-is', without any express or implied
;  warranty. In no event will the authors be held liable for any
;  damages arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any
;  purpose, including commercial applications, and to alter it and
;  redistribute it freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you
;     must not claim that you wrote the original software. If you use
;     this software in a product, an acknowledgment in the product
;     documentation would be appreciated but is not required.
;
;  2. Altered source versions must be plainly marked as such, and
;     must not be misrepresented as being the original software.
;
;  3. This notice may not be removed or altered from any source
;     distribution.
;
;  The original version of this library can be located at:
;  http://www.angelcode.com/angelscript/
;
;  Andreas Jonsson
;  andreas@angelcode.com
;


; Assembly routines for the ARM64/AArch64 call convention used for Windows 10 on ARM
; Written by Max Waine in July 2020, based on as_callfunc_arm_msvc.asm

; MSVC currently doesn't support inline assembly for the ARM64 platform,
; and if they're treating it like x64 /won't/ ever support inline assembly,
; so this separate file is needed.

; Compile with Microsoft ARM64 assembler (armasm64)
; http://msdn.microsoft.com/en-us/library/hh873190.aspx

    AREA    |.rdata|, DATA, READONLY
    EXPORT  arm64Func
    EXPORT arm64FuncR0
    EXPORT arm64FuncR0R1
    EXPORT arm64FuncObjLast
    EXPORT arm64FuncR0ObjLast

    AREA    |.text|, CODE, ALIGN=3

    ALIGN   8
arm64Func PROC
    stp     fp,lr,[sp,#-0x30]!
    mov     fp,sp
    str     x19,[sp,#0x18] ; arg table
    str     w20,[sp,#0x10] ; arg size
    str     x21,[sp,#0x20] ; function address
    mov     w22, #0
    cmps    w20, #0 ; set the condition code flags so that we detect if there are no arguments

    beq    |nomoreargs|
; TODO: MIDDLE
|nomoreargs|
    blr     x21
    ldp     fp,lr,[sp],#0x30
    ret
    ENDP ; arm64Func

    ALIGN   8
arm64FuncR0 PROC
    ENDP ; arm64FuncR0

        ALIGN 8
arm64FuncR0R1 PROC
; TODO: EVERYTHING
    ENDP ; arm64FuncR0R1

    ALIGN 8
arm64FuncObjLast PROC
; TODO: EVERYTHING
    ENDP ; arm64FuncObjLast

    ALIGN 8
arm64FuncR0ObjLast PROC
; TODO: EVERYTHING
    ENDP ; arm64FuncR0ObjLast

    END
