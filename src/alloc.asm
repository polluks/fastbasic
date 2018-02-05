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


; Memory functions
; ----------------

; The memory areas are arranged as:
;  prog_ptr:    -> current program output pos
;               Buffer zone (at least 0x100 free bytes)
;  array_buf:   STRING/ARRAY AREA
;  array_ptr:   -> next available pos
;  var_buf:     VARIABLE TABLE AREA (during parsing) and VARIABLE VALUE AREA
;               (during interpreting)
;  var_ptr:     -> next available pos
;  top_mem:     TOP OF MEMORY
;
        .export         alloc_prog, alloc_array, alloc_laddr, clear_data
        .export         parser_alloc_init, alloc_area_8, clear_memory
        .exportzp       prog_ptr, array_ptr, var_buf, var_ptr, mem_end
        .exportzp       label_buf, label_ptr, laddr_buf, laddr_ptr

        ; From runtime.asm
        .import         move_dwn_src, move_dwn_dst, move_dwn
        .importzp       tmp1, tmp2
        ; From interpreter.asm
        .importzp       var_count

        .zeropage

        ;           During Parsing           During Execution
        ;           ---------------------------------------------
        ; Pointer to program buffer        / current program
mem_start:
prog_ptr:       .res    2
prog_end:       .res    2
        ; Pointer to variable name table   / variable value table
var_buf=        prog_end
var_ptr:        .res    2
var_end=        var_ptr
        ; Pointer to labels name table     / strings/arrays table
array_buf=      var_end
array_ptr:      .res    2
array_end=      array_ptr
label_buf=      array_buf
label_ptr=      array_ptr
label_end=      array_end
        ; Pointer to labels address table  / unused at runtime
laddr_buf=      array_end
laddr_ptr:      .res    2
laddr_end=      laddr_ptr
        ; End of used memory
mem_end=        laddr_end
        ; Top of available memory
MEMTOP=         $2E5

        ; Allocation size
alloc_size=     tmp1

;----------------------------------------------------------
; Following routines are part of the runtime
        .segment        "RUNTIME"

        ; Clears data pointers before starting the interpreter
.proc   clear_data
        ; Init all pointers to end of program data
        lda     prog_ptr
        ldy     prog_ptr+1
        ldx     #(mem_end-prog_ptr)
loop:
        sta     prog_ptr, x
        sty     prog_ptr+1, x
        dex
        dex
        bpl     loop
        ; Adds 2 bytes for each variable
        ldy     #0
        lda     var_count
        asl
        sta     alloc_size
        bcc     :+
        iny
:       sty     alloc_size+1
        ldx     #var_end - mem_start
        jsr     add_pointers
        ; And clears variable area (we have size in "alloc_size")
        lda     var_buf
        sta     tmp2
        lda     var_buf+1
        sta     tmp2+1
.endproc        ; Fall through

        ; Clears memory from (tmp2) of (alloc_size) size
.proc   clear_memory
        lda     alloc_size+1
        tax
        clc
        adc     tmp2+1
        sta     tmp2+1
        lda     #0
        inx
        ldy     alloc_size
        beq     nxt
        .byte   $2C   ; Skip 2 bytes over next "DEC"

pgloop: dec     tmp2+1
loop:   dey
        sta     (tmp2), y
        bne     loop

nxt:    dex
        bne     pgloop

        rts
.endproc

        ; This should be outside of runtime, but it's shorter here
.proc   alloc_laddr
        ldx     #laddr_end - mem_start
.endproc        ; Fall through

        ; Increase program memory area X by A (size in bytes)
alloc_area_8:
        ldy     #0
        ; Increase program memory area X by AY (size in bytes)
.proc   alloc_area
        sty     alloc_size+1
skip_y: sta     alloc_size

        clc
        adc     mem_end
        tay
        lda     alloc_size+1
        adc     mem_end+1
        cpy     MEMTOP
        sbc     MEMTOP+1
        bcs     err_nomem

        ; Move memory up by "alloc_size"
        stx     save_x+1
        jsr     move_mem_up
        ; Adjust pointers
save_x: ldx     #0
        jmp     add_pointers
.endproc

        ; Allocate space for a new array AX = SIZE
.proc alloc_array
        stx     alloc_size + 1
        ldx     #array_end - mem_start
        bne     alloc_area::skip_y
.endproc

.proc   err_nomem
        sec
        rts
.endproc

        ; Move memory up.
        ;  Y          : index to pointer to move from
        ;  alloc_size : amount to move up
        ;
.proc   move_mem_up
        ;       Setup pointers
        lda     mem_start, x
        sta     move_dwn_src
        clc
        adc     alloc_size
        sta     move_dwn_dst
        lda     mem_start+1, x
        sta     move_dwn_src+1
        adc     #0
        sta     move_dwn_dst+1

        ; Get LEN into AX
        lda     mem_end
        sec
        sbc     mem_start, x
        pha
        lda     mem_end+1
        sbc     mem_start+1, x
        tax
        pla
        jmp     move_dwn
.endproc

        ; Increase all pointers from "Y" to the last by AX
.proc   add_pointers
loop:   clc
        lda     mem_start, x
        adc     alloc_size
        sta     mem_start, x
        inx
        lda     mem_start, x
        adc     alloc_size+1
        sta     mem_start, x
        inx
        cpx     #mem_end - mem_start + 2
        bne     loop
        clc
        rts
.endproc

;----------------------------------------------------------
; Following routines are part of the parser/editor
        .code

;----------------------------------------------------------
; Parser initialization here:
.proc   parser_alloc_init
        ; Init all pointers to AY
        ldx     #(mem_end-mem_start)
loop:
        sta     mem_start, x
        sty     mem_start+1, x
        dex
        dex
        bpl     loop
        ; Adds 256 bytes as program buffer
        ldx     #prog_end - mem_start
        ldy     #0
        sty     alloc_size
        iny
        sty     alloc_size+1
        jmp     add_pointers
.endproc

        ; Increase program memory area by A (size in bytes)
.proc alloc_prog
        ; Move from "prog_end", up by "alloc_size"
        ldx     #prog_end - mem_start
        jsr     alloc_area_8
        ; Special case - we need to adjust prog_ptr, but we
        ; don't move that areas as it has the current parsed line.
        lda     prog_ptr
        clc
        adc     alloc_size
        sta     prog_ptr
        bcc     :+
        inc     prog_ptr+1
:       rts
.endproc

; vi:syntax=asm_ca65
