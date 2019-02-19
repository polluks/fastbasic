;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2019 Daniel Serpell
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


; Block-GET and Block-PUT
; -----------------------

        .import CIOV_CMD_POP2

        ; From runtime.asm
        .importzp       IOCHN

        ; From interpreter.asm
        .importzp       sptr
        .import         stack_l, stack_h

        .include "atari.inc"

        .segment        "RUNTIME"

.proc   EXE_BPUT
        clc
        .byte   $B0     ; BCS not taken, skips next SEC
.endproc        ; Fall through
.proc   EXE_BGET
        sec

        php

        pha
        txa
        pha

        lda     stack_l+1,y
        asl
        asl
        asl
        asl
        tax

        pla
        sta     ICBLH, x
        pla
        sta     ICBLL, x        ; Length

        lda     stack_l, y
        sta     ICBAL, x        ; Address
        lda     stack_h, y

        plp
        ldy     #GETCHR
        bcs     bget
        ldy     #PUTCHR
bget:
        jmp     CIOV_CMD_POP2   ; Note: A is never 0
.endproc

        .include "../deftok.inc"
        deftoken "BPUT"
        deftoken "BGET"

; vi:syntax=asm_ca65
