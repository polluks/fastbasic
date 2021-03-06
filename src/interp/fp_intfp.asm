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


; Integer to Floating Point
; -------------------------

        ; From fpmain.asm
        .import         save_push_fr0
        .importzp       fp_tmp_a, fp_tmp_x
        ; From runtime.asm
        .import         int_to_fp
        ; From interpreter.asm
        .import         pop_stack

        .segment        "RUNTIME"

.proc   EXE_INT_FP      ; Convert INT to FP
        ; Save INT stack, push FP stack
        jsr     save_push_fr0
        ; Restore TOS
        lda     fp_tmp_a
        ldx     fp_tmp_x
        ; Convert to FP
        jsr     int_to_fp
        ; Discard top of INT stack
        jmp     pop_stack
.endproc

        .include "../deftok.inc"
        deftoken "INT_FP"

; vi:syntax=asm_ca65
