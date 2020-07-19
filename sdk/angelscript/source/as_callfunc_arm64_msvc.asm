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
    ; Store non-volatile registers
    stp     x19, x20, [fp,#0x10]
    stp     x21, x22, [fp,#0x20]

    mov     x19, x0 ; arg table
    mov     w20, w1 ; arg size (in bytes)
    mov     x21, x2 ; function address
    mov     x22, #0 ; Called function's stack pointer offset

    ; If 0 args jump to end.  If >=8 we can skip dynamic jump
    cbz     w20, |noMoreArgs|
    cmp     w20, #8*8
    bge     |populateRegisterArgsStart|

    ; Calculate amount to jump forward, avoiding pointless instructions
    adr     x9, |populateRegisterArgsEnd|
    sub     x9, x9, x20
    br      x9

    ; Load args
|populateRegisterArgsStart|
    ldr     x7, [x19],#8
    ldr     x6, [x19],#8
    ldr     x5, [x19],#8
    ldr     x4, [x19],#8
    ldr     x3, [x19],#8
    ldr     x2, [x19],#8
    ldr     x1, [x19],#8
    ldr     x0, [x19],#8
|populateRegisterArgsEnd|

    ; Jump to end if 8 or fewer args
    subs    x20, x20, #8*8
    ble     |noMoreArgs|

    ; Load the rest of the arguments onto the stack. The earlier
    ; reduction of x20 by 8*8 skips registers already loaded into x0-x7
    sub     sp, sp, x20
    mov     x22, x20
|stackArgsLoop|
    ldr     x9, [x19],#8
    str     x9, [sp],#8
    subs    w20, w20,#8
    bne     |stackArgsLoop|

    ; Call the actual function
|noMoreArgs|
    sub     sp, sp, x22
    blr     x21
    add     sp, sp, x22

    ; Restore non-volatile registers and fp/lr
    ldp     x19, x20, [fp,#0x10]
    ldp     x21, x22, [fp,#0x20]
    ldp     fp,lr,[sp],#0x30

    ret
    ENDP ; arm64Func

    END
