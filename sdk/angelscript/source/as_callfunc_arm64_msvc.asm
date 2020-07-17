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


; Assembly routines for the ARM64/AArch64 call convention used for Windows CE
; Written by Max Waine in July 2020

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
    stmdb   sp!, {r4-r8, lr}
    mov     r6, r0  ; arg table
    movs    r7, r1  ; arg size (also set the condition code flags so that we detect if there are no arguments)
    mov     r4, r2  ; function address
    mov     r8, #0

    beq     |nomoreargs|

    ; Load the first 4 arguments into r0-r3
    cmp     r7, #4
    ldrge   r0, [r6],#4
    cmp     r7, #2*4
    ldrge   r1, [r6],#4
    cmp     r7, #3*4
    ldrge   r2, [r6],#4
    cmp     r7, #4*4
    ldrge   r3, [r6],#4
    ble     |nomoreargs|

    ; Load the rest of the arguments onto the stack
    sub     r7, r7, #4*4    ; skip the 4 registers already loaded into r0-r3
    sub     sp, sp, r7
    mov     r8, r7
|stackargsloop|
    ldr     r5, [r6], #4
    str     r5, [sp], #4
    subs    r7, r7, #4
    bne     |stackargsloop|
|nomoreargs|
    sub     sp, sp, r8
    blx     r4
    add     sp, sp, r8
    ldmia   sp!, {r4-r8, pc}
    ENDP

    END
