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


; USR - call user assembly routine
; --------------------------------

        ; From interpreter.asm
        .import         pop_stack_y
        .importzp       next_instruction

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_USR_PARAM   ; Stores AX as an usr parameter
        pha
        txa
        pha
        jmp     pop_stack_y
.endproc

.proc   EXE_USR_ADDR
        ; Store out return address into the CPU stack
        jsr     next_instruction
        jmp     next_instruction
.endproc

.proc   EXE_USR_CALL
        ; Calls the routine, address is in AX
        sta     jump+1
        stx     jump+2
jump:   jmp     $FFFF
.endproc

        .include "../deftok.inc"
        deftoken "USR_PARAM"
        deftoken "USR_ADDR"
        deftoken "USR_CALL"

; vi:syntax=asm_ca65
