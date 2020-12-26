; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc
include    kernel.inc

           org     8000h
           lbr     0ff00h
           db      'sys',0
           dw      9000h
           dw      endrom+7000h
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           db      0
 
           org     2000h
           br      start

include    date.inc
include    build.inc
           db      'Written by Michael H. Riley',0

start:
           lda     ra                  ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                  ; move back to non-space character
           ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           bdf     loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldn     rf                  ; get byte from argument
           lbnz    good                ; jump if filename given
           sep     scall               ; otherwise display usage message
           dw      f_inmsg
           db      'Usage: sys filename',10,13,0
           sep     sret                ; and return to os

good:      ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           bnf     opened              ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           lbr     o_wrmboot           ; and return to os
opened:    push    rd                  ; save file descriptor
           mov     rf,kernel           ; point to kernel data
           mov     rc,8192             ; 8k to read
           sep     scall               ; read file
           dw      o_read
           lbnf    success             ; jump if read was good
           sep     scall               ; indicate error
           dw      f_inmsg
           db      'Error writing to file',10,13,0
           pop     rd
           lbr     o_wrmboot           ; return to OS
success:   pop     rd                  ; recover file descriptor
           sep     scall               ; close file
           dw      o_close

           ldi     1                   ; setup sector address
           plo     r7
           mov     rf,kernel           ; point to memory to place kernel image
bootrd:    glo     r7                  ; save R7
           str     r2
           out     4
           dec     r2
           stxd
           ldi     0                   ; prepare other registers
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           sep     scall               ; call bios to read sector
           dw      f_idewrite
           irx                         ; recover R7
           ldxa
           plo     r7
           inc     r7                  ; point to next sector
           glo     r7                  ; get count
           smi     15                  ; was last sector (16) read?
           lbnz    bootrd              ; jump if not

           sep     scall               ; display completion message
           dw      f_inmsg
           db      'Kernel updated, press any key to reboot system',0
           sep     scall               ; read a key
           dw      f_read
           ldi     0ch                 ; clear screen
           sep     scall
           dw      f_type
           sep     scall               ; Booting message
           dw      f_inmsg
           db      'Booting system...',10,13,0
           lbr     0ff00h              ; jump to system cold boot



filename:  db      0,0
errmsg:    db      'File not found',10,13,0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

buffer:    ds      20
cbuffer:   ds      80
dta:       ds      512

kernel:    ds      8192

