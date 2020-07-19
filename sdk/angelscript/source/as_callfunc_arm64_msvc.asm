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

    AREA    |.text|, CODE, ALIGN=3

    ALIGN   8
arm64Func PROC
    stp     fp,  lr, [sp,#-0x30]! ; Store fp/lr
    mov     fp,  sp
    ; Store non-volatile register
    str     x22, [fp,#0x10]

    mov     x13, x0 ; arg table
    mov     x14, x1 ; arg size (in bytes)
    mov     x15, x2 ; function address
    mov     x22, #0 ; Called function's stack pointer offset

    ; If 0 args jump to end.  If >=8 we can skip dynamic jump
    cbz     x14, |noMoreArgs|
    cmp     x14, #8*8
    bge     |populateRegisterArgsStart|

    ; Calculate amount to jump forward, avoiding pointless instructions
    adr     x9, |populateRegisterArgsEnd|
    sub     x9, x9, x20
    br      x9

    ; Load args
|populateRegisterArgsStart|
    ldr     x7, [x13],#8
    ldr     x6, [x13],#8
    ldr     x5, [x13],#8
    ldr     x4, [x13],#8
    ldr     x3, [x13],#8
    ldr     x2, [x13],#8
    ldr     x1, [x13],#8
    ldr     x0, [x13],#8
|populateRegisterArgsEnd|

    ; Jump to end if 8 or fewer args
    subs    x14, x14, #8*8 ; TODO: Correctness check, should be 8*8 and not 16 because multiplication is later
    ble     |noMoreArgs|

    ; Load the rest of the arguments onto the stack. The earlier
    ; reduction of x14 by 8*8 skips registers already loaded into x0-x7
    lsl     x14, x14, #1 ; multiply by 2 (<<= 1)
    sub     sp, sp, x14
    mov     x22, x14
    ; Bear in mind variables must be aligned at 16 bytes
|stackArgsLoop|
    ldr     x9,  [x13],#8
    str     x9,  [sp],#16
    subs    x14, x14,#16
    bne     |stackArgsLoop|

    ; Call the actual function
|noMoreArgs|
    sub     sp, sp, x22
    blr     x15
    add     sp, sp, x22

    ; Restore non-volatile register and fp/lr
    ldr     x22, [fp,#0x10]
    ldp     fp,lr,[sp],#0x30

    ret
    ENDP ; arm64Func

    END
