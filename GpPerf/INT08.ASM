;**
;** File   : int08.asm
;** Author : TK
;** Date   :  8/06/94
;**
;** $Header:   F:/TK/GPPERF/VCS/INT08.AS_   1.1   15 Oct 1995 16:06:04   tk  $
;**
;** IRQ 0 tick timer
;**

                name    int08
                title   'IRQ 0 tick timer'

;*****************************************************************************
;**
;** Segments
;**

include segments.inc
include gpperf.inc

;*****************************************************************************
;**
;** Equates & Macros
;**

;*****************************************************************************
;**
;** Data
;**

TSR_DATA        segment

old08_hndlr     label   dword           ; IRQ 0 Timer tick
old08_off       dw      ?
old08_seg       dw      ?

TSR_DATA        ends

;****************************************************************************
;**        
;** Our IRQ 0 tick timer
;**        

TSR_CODE        segment

        public  new08_hndlr
new08_hndlr     proc near

        pushf
        call    DWORD PTR cs:old08_hndlr

        push    ax

        ;**
        ;** Decrement delay count
        ;**
        cmp     cs:delay_count, 0
        jz      no_delay
        dec     cs:delay_count
no_delay:

        ;**
        ;** Check beep count
        ;**
        cmp     BYTE PTR cs:beep_count, 0
        jz      no_beep
        cmp     BYTE PTR cs:beep_count, 1
        jz      end_beep
        cmp     BYTE PTR cs:beep_count, BEEP_1_TIME
        jge     beep_1
        cmp     BYTE PTR cs:beep_count, BEEP_2_TIME
        jnz     not_beep_2
        
	mov	al, 0B6h
	out	43h, al				; port 43h, 8253 wrt timr mode
	mov	ax, BEEP_2_FREQ
        jmp     beep
beep_1:
	mov	al, 0B6h
	out	43h, al				; port 43h, 8253 wrt timr mode
	mov	ax, BEEP_1_FREQ
beep:	out	42h, al				; port 42h, 8253 timer 2 spkr
	mov	al, ah
	out	42h, al				; port 42h, 8253 timer 2 spkr

	in	al, 61h				; port 61h, 8255 port B, read
	or	al, 3
	out	61h, al				; port 61h, 8255 B - spkr, etc
        jmp     not_beep_2

end_beep:
	in	al, 61h				; port 61h, 8255 port B, read
	and	al, 0FDh
	out	61h, al				; port 61h, 8255 B - spkr, etc

not_beep_2:
        dec     BYTE PTR cs:beep_count
   
no_beep:
        pop     ax
        iret

new08_hndlr     endp

TSR_CODE        ends

;*****************************************************************************

                end


