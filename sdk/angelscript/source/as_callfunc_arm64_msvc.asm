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
    stp     fp,  lr, [sp,#-0x30]!
    mov     fp,  sp

    ; Store non-volatile registers (TODO: VERIFY THIS WORKS)
    str     x19, [fp,#0x18]
    str     w20, [fp,#0x10]
    str     x21, [fp,#0x20]

    mov     x19, x0 ; arg table
    mov     w20, w1 ; arg size (in bytes)
    mov     x21, w2 ; function address
    mov     x22, #0 ; TODO: Is this a valid next general-purpose register number?

    ; If 0 args jump to end.  If >=8 we can skip dynamic jump
    cbz     w20, |noMoreArgs|
    cmp     w20, #8*8
    bge     |populateStackRegistersStart|

    ; Calculate amount to jump forward, avoiding pointless instructions
    adr     x9, |populateStackRegistersEnd|
    sub     x9, x9, x20
    br      x9

    ; Load args
|populateStackRegistersStart|
    ldr     x7, [x19],#8
    ldr     x6, [x19],#8
    ldr     x5, [x19],#8
    ldr     x4, [x19],#8
    ldr     x3, [x19],#8
    ldr     x2, [x19],#8
    ldr     x1, [x19],#8
    ldr     x0, [x19],#8
|populateStackRegistersEnd|
; simpler way to do things that is probably less efficient
;    cmp     w20, #8*1
;    blt     |noMoreArgs|
;    ldr     x0, [x19],#8
; do the last 3 instructions 8 times going through the registers and increasing the 8's multiplier in the cmp by 1 each time

    ; Jump to end if 8 or fewer args
    subs    x9, x20, #8*8
    ble     |noMoreArgs|

; TODO: MIDDLE

|noMoreArgs|
    blr     x21
    ldp     fp,lr,[sp],#0x30

    ; Restore non-volatile registers (TODO: VERIFY THIS WORKS)
    ldr     x19, [fp,#0x18]
    ldr     w20, [fp,#0x10]
    ldr     x21, [fp,#0x20]

    ret
    ENDP ; arm64Func

    END
