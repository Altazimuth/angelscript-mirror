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
;    EXPORT arm64FuncR0
;    EXPORT arm64FuncR0R1
;    EXPORT arm64FuncObjLast
;    EXPORT arm64FuncR0ObjLast

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

    ; Load the first 4 arguments into w0-w3
    cmp     w20, #4
    ldrge   w0, [x19],#4
    cmp     w20, #2*4
    ldrge   w1, [x19],#4
    cmp     w20, #3*4
    ldrge   w2, [x19],#4
    cmp     w20, #4*4
    ldrge   w3, [x19],#4
    ble     |nomoreargs|
;
;    ; Load the rest of the arguments onto the stack
;    sub     r7, r7, #4*4    ; skip the 4 registers already loaded into r0-r3
;    sub     sp, sp, r7
;    mov     r8, r7
;|stackargsloop|
;    ldr     r5, [r6], #4
;    str     r5, [sp], #4
;    subs    r7, r7, #4
;    bne     |stackargsloop|
|nomoreargs|
    blr     x2
    ldp     fp,lr,[sp],#0x30
    ret
    ENDP

    END
