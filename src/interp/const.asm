;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017,2018 Daniel Serpell
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program.  If not, see <http://www.gnu.org/licenses/>
;
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; Load constants (Byte/Word and String)
; -------------------------------------

        ; From interpreter.asm
        .importzp       next_instruction, cptr
        .import         pushAX

        .segment        "RUNTIME"

.proc   EXE_NUM  ; AX = read from op (load byte first!)
        jsr     pushAX
        ldy     #1              ; 2     2
        lda     (cptr), y       ; 5     2
        tax                     ; 2     1
        dey                     ; 2     1
        lda     (cptr), y       ; 5     2
        ldy     cptr            ; 3     2
        cpy     #254            ; 2     2
        iny                     ; 2     1
        iny                     ; 2     1
        sty     cptr            ; 3     2
        bcs     inc_cptr_1      ; 2 =30 2 =18
        jmp     next_instruction
.endproc

.proc   EXE_BYTE  ; AX = read 1 byte from op
        jsr     pushAX
        ldx     #0
        lda     (cptr, x)
        inc     cptr
        beq     inc_cptr_1
        jmp     next_instruction
.endproc

.proc   EXE_CSTRING     ; AX = address of string
        jsr     pushAX
        ldy     #0      ; Get string length into A
        sec
        lda     cptr
        tax
        adc     (cptr), y
        sta     cptr
        txa
        ldx     cptr+1
        bcc     xit
::inc_cptr_1:
        inc     cptr+1
xit:    jmp     next_instruction
.endproc

        .include "../deftok.inc"
        deftoken "NUM"
        deftoken "BYTE"
        deftoken "CSTRING"

; vi:syntax=asm_ca65
