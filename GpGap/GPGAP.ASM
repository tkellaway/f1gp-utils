;**
;** File   : gpgap.asm
;** Author : TK 
;** Date   :  6/06/94
;**
        name    gpgap
        title   'Joystick Button to Key Converter'

;*****************************************************************************
;**
;** Include files
;**

;*****************************************************************************
;**
;** Segments
;**

include segments.inc
include gpgap.inc

;*****************************************************************************
;**
;** Equates & Macros
;**

TICK_TIME_MS    equ     18                      ; Approx ms of a tick
DELAY_TIME      equ     (500 / TICK_TIME_MS)    ; Time to display hook msg
DOS             equ     21h                     ; Dos interrupt call

;*****************************************************************************
;**
;** Externals.
;**

TSR_CODE        segment

                extrn   install:far
                extrn   LogEntry:near

TSR_CODE        ends

;*****************************************************************************
;**
;** Data
;**

TSR_DATA        segment

psp_env         label   dword
psp_env_off     dw      002ch           ; Offset of env pointer in PSP
psp_seg         dw      ?               ; PSP segment

old21_hndlr     label   dword           ; DOS Int 21 handler
old21_off       dw      ?
old21_seg       dw      ?

delay_count     db      0
                
game_ds         dw      ?
game_ss         dw      ?

show_pos        dw      0
tmp_sp          dw      ?

                public  top
top             dw      6

                public  hold_delay
hold_delay      dw      3000

positions       db      27 dup(0)
times           dd      27 dup(0)

;*****************************************************************************
;** 
;** European V1.05 GP.EXE - DOS Version code fragment
;** 
;** 92D2:5C76  B0 00 mov	al,0
;** 92D2:5C78  B4 30 mov	ah,30h
;** 92D2:5C7A  CD 21 int	21h	        @06d2eaH in GPU.EXE
;** 92D2:5C7C  0A C0 or	        al,al	
;** 92D2:5C7E  75 03 jnz	loc_5593
;** 

GP_EUR_RET_ADDR equ     0b74ch
GP_ITA_RET_ADDR equ     0b74ch
GP_USA_RET_ADDR equ     0b727h
MATCH_OFFSET    equ     6

gp_code_eur     db      0B0h, 000h
                db      0B4h, 030h
                db      0CDh, 021h
                db      00Ah, 0C0h
                db      075h, 003h
                db      0B8h, 001h, 000h
                db      036h, 0A3h, 0C6h, 005h
                db      03Ch, 003h
                db      073h, 009h
                db      036h, 0C6h, 006h, 031h, 009h, 007h
                db      0E9h, 067h, 001h
                db      00Eh
                db      0E8h, 062h, 0F7h
                db      00Eh
                db      0E8h, 0EDh, 0F8h
                db      032h, 0C0h
                db      09Ah, 043h, 019h
MATCH_BYTES_EUR equ     $ - gp_code_eur
                
gp_code_ita     db      0B0h, 000h
                db      0B4h, 030h
                db      0CDh, 021h
                db      00Ah, 0C0h
                db      075h, 003h
                db      0B8h, 001h, 000h
                db      036h, 0A3h, 0C6h, 005h
                db      03Ch, 003h
                db      073h, 009h
                db      036h, 0C6h, 006h, 031h, 009h, 007h
                db      0E9h, 067h, 001h
                db      00Eh
                db      0E8h, 062h, 0F7h
                db      00Eh
                db      0E8h, 0EDh, 0F8h
                db      032h, 0C0h
                db      09Ah, 0ebh, 018h
MATCH_BYTES_ITA equ     $ - gp_code_ita

gp_code_usa     db      0b0h, 00h, 0b4h, 30h, 0cdh, 21h, 0ah, 0c0h, 75h, 03h
MATCH_BYTES_USA equ     $ - gp_code_usa
        
;*****************************************************************************

game_eur        db      0
game_ita        db      0
game_usa        db      0

hooked_msg      db      CR, LF, "GpGap activated OK", CR, LF, '$'

TSR_DATA        ends

;****************************************************************************
;** 
;** Our DOS Int 21 handler
;** 

TSR_CODE        segment

        public  new21_hndlr
new21_hndlr     proc near

        ;**
        ;** Is it DOS Get Version?
        ;** 
        cmp     ah, 30h
        jz      push_start
        jmp     do_orig_int21

        PUSHA_SIZE equ (8 - 1)
push_start:
        pushf
        pusha
        push    ds
        push    es
push_end:

        mov     ax, cs
        mov     ds, ax

        mov     game_ds, 0
        mov     game_ss, ss

        ;**
        ;** Get return address
        ;**
        mov     di, sp
        les     di, ss:[di + ((PUSHA_SIZE + push_end - push_start) * 2)]

        ;**
        ;** Is it GP.EXE calling us?
        ;**
        cmp     di, GP_EUR_RET_ADDR
        jnz     try_us
        sub     di, MATCH_OFFSET
        mov     bx, di
        mov     si, OFFSET TSR:gp_code_eur
        mov     cx, MATCH_BYTES_EUR
        cld
        repe    cmpsb
        jz      its_eur

        mov     di, bx
        mov     si, OFFSET TSR:gp_code_ita
        mov     cx, MATCH_BYTES_ITA
        cld
        repe    cmpsb
        jnz     no_match
its_ita:
        mov     game_ita, 1
        jmp     got_match

its_eur:
        mov     game_eur, 1
        jmp     got_match

        ;**
        ;** Is it US GP.EXE calling us?
        ;**
try_us: cmp     di, GP_USA_RET_ADDR
        jnz     no_match
        sub     di, MATCH_OFFSET
        mov     si, OFFSET TSR:gp_code_usa
        mov     cx, MATCH_BYTES_USA
        cld
        repe    cmpsb
        jnz     no_match

        mov     game_usa, 1

got_match:
        call    announce_hook
        call    hook_gp_exe

no_match:
        pop     es
        pop     ds
        popa
        popf

do_orig_int21:
        ;**
        ;** Perform normal DOS call.
        ;**
        jmp     dword ptr cs:old21_hndlr

new21_hndlr     endp

TSR_CODE        ends

;*****************************************************************************
;** Purpose: Hook our code.
;**
;** Returns: Nothing.
;**
;** Notes  : 
;**

TSR_CODE        segment

        public  hook_gp_exe
hook_gp_exe proc near

        mov     cx, HOOK1_EUR_MSW 
        mov     ax, HOOK1_EUR_LSW
        mov     dx, HOOK1_USA_MSW
        mov     bx, HOOK1_USA_LSW
        mov     si, HOOK1_ITA_MSW
        mov     di, HOOK1_ITA_LSW
        call    get_hook_offset
        mov     si, OFFSET cs:hook_1_start
        mov     cx, HOOK1_LENGTH
        call    copy_patch_block_neg

        mov     cx, HOOK2_EUR_MSW 
        mov     ax, HOOK2_EUR_LSW
        mov     dx, HOOK2_USA_MSW
        mov     bx, HOOK2_USA_LSW
        mov     si, HOOK2_ITA_MSW
        mov     di, HOOK2_ITA_LSW
        call    get_hook_offset
        mov     si, OFFSET cs:hook_2_start
        mov     cx, HOOK2_LENGTH
        call    copy_patch_block_neg

        mov     cx, HOOK2A_EUR_MSW 
        mov     ax, HOOK2A_EUR_LSW
        mov     dx, HOOK2A_USA_MSW
        mov     bx, HOOK2A_USA_LSW
        mov     si, HOOK2A_ITA_MSW
        mov     di, HOOK2A_ITA_LSW
        call    get_hook_offset
        mov     si, OFFSET cs:hook_2a_start
        mov     cx, HOOK2A_LENGTH
        call    move_patch_block_neg

        cmp     cs:game_usa, 1
        jz      do_usa
        cmp     cs:game_eur, 1
        jz      do_eur 
        jmp     do_ita

do_eur:
        mov     cs:hook_2b_off, 202ch
        mov     cs:hook_2c_off, 17cfh
        mov     cs:hook_2d_off, 1805h
        mov     cs:hook_2e_off, 18c1h
        mov     cs:hook_2f_off, 18f1h
        mov     cs:hook_2g_off, 1924h
        mov     cs:hook_2h_off, 184bh
        mov     cs:hook_2i_off, 1924h
        mov     cs:hook_2j_off, 18f1h
        jmp     done

do_usa:
        mov     cs:hook_2b_off, 2000h
        mov     cs:hook_2c_off, 17a3h
        mov     cs:hook_2d_off, 17d9h
        mov     cs:hook_2e_off, 1895h
        mov     cs:hook_2f_off, 18c5h
        mov     cs:hook_2g_off, 18f8h
        mov     cs:hook_2h_off, 181fh
        mov     cs:hook_2i_off, 18f8h
        mov     cs:hook_2j_off, 18c5h
        jmp     done

do_ita:
        mov     cs:hook_2b_off, 1ff8h
        mov     cs:hook_2c_off, 179bh
        mov     cs:hook_2d_off, 17d1h
        mov     cs:hook_2e_off, 188dh
        mov     cs:hook_2f_off, 18bdh
        mov     cs:hook_2g_off, 18f0h
        mov     cs:hook_2h_off, 1817h
        mov     cs:hook_2i_off, 18f0h
        mov     cs:hook_2j_off, 18bdh

done:   ret

hook_gp_exe endp

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Determines which hook address to use, European or US or
;**             Italian.
;**
;** Returns:    DX:BX = Hook
;**
;** Notes  :    CX:AX = European hook.
;**             DX:BX = USA hook.
;**             SI:DI = Italian hook.
;**

TSR_CODE        segment

get_hook_offset proc near

        cmp     game_usa, 1
        jz      get_hook_offset_do_usa
        cmp     game_ita, 1
        jz      get_hook_offset_do_ita
        
        mov     bx, ax
        mov     dx, cx
get_hook_offset_do_usa:
        ret

get_hook_offset_do_ita:
        mov     bx, di
        mov     dx, si
        ret

get_hook_offset endp

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Copy patch block to correct destination.
;**
;** Returns:    Nothing.
;**
;** Notes  :    SI = offset of local code fragment.
;**             DX = Hook segment
;**             BX = Hook offset
;**             CX = Hook block length.

TSR_CODE        segment

copy_patch_block_neg proc near

        mov     di, sp
        les     di, ss:[di + ((PUSHA_SIZE + push_end - push_start) * 2) + 2 + 2]
        add     bx, 2
        sub     di, bx
        mov     bx, es
        sub     bx, dx
        mov     es, bx

copy_patch_block2_neg:
        lodsb
        stosb
        loop    copy_patch_block2_neg

        ret

copy_patch_block_neg endp

move_patch_block_neg proc near

        mov     di, sp
        les     di, ss:[di + ((PUSHA_SIZE + push_end - push_start) * 2) + 2 + 2]
        add     bx, 2
        sub     di, bx
        mov     bx, es
        sub     bx, dx
        mov     es, bx

        mov     ax, ds
        mov     bx, es
        xchg    ax, bx
        mov     es, bx
        mov     ds, ax
        xchg    si, di

move_patch_block2_neg:
        lodsb
        stosb
        loop    move_patch_block2_neg

        ret

move_patch_block_neg endp

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Show user that we've hooked in OK.
;**
;** Returns:    Nothing.
;**
;** Notes  : 
;**

TSR_CODE        segment

        public  announce_hook
announce_hook proc near
        mov     dx, OFFSET TSR:hooked_msg
        mov     ah, 09h
        int     DOS
        sti
        mov     delay_count, DELAY_TIME
do_delay:        
        cmp     delay_count, 0
        jnz     do_delay
        ret

announce_hook endp

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Code executed when 'G' key is pressed.
;**
;** Returns:    Nothing.
;**
;** Notes  : 
;**
;** GPU.EXE:    06d2eaH - 0033d4h = 069f16h
;** ITU.EXE:    06d2aaH - 0033d4h = 069ed6h
;** USU.EXE:    06d295H - 0033d4h = 069ec1h
;**
;** (DOS VER hook point = 06d2eaH in GPU.EXE)
;** (DOS VER hook point = 06d295H in USU.EXE)
;**

HOOK1_EUR_MSW   equ     6000h
HOOK1_EUR_LSW   equ     9f16h
HOOK1_ITA_MSW   equ     6000h
HOOK1_ITA_LSW   equ     9ed6h
HOOK1_USA_MSW   equ     6000h
HOOK1_USA_LSW   equ     9ec1h

TSR_DATA                segment

hook_1_start:           
                        nop
                        nop
                        db     09ah
hook_1_off              dw     ?
hook_1_seg              dw     ?
hook_1_end:
HOOK1_LENGTH            equ     (hook_1_end - hook_1_start)

TSR_DATA                ends

TSR_CODE                segment
        public  hook1
hook1:
        ;**
        ;** Original code
        ;**
        mov     si, ds:[097fh]
        mov     ax, ds:[si+04h]

        ;**
        ;** Our code.
        ;**
        pushf
        pusha
        push    ds
        push    es

        ;**
        ;** Set index, if it was already set then assume the user
        ;** pressed 'G' again to cancel the display.
        ;**
        cmp     cs:show_pos, 0
        jz      do_it
        mov     cs:show_pos, 0
        jmp     hskip

do_it:  mov     cs:show_pos, 1

        ;**
        ;** Save current positions.
        ;**
        push    ds
        push    ss
        pop     ds
        push    cs
        pop     es
        mov     di, OFFSET TSR:positions
        mov     si, 193fh
        mov     cx, 27
copy_pos:
        lodsb
        stosb
        loop    copy_pos
        pop     ds

        mov     cx, 26
        mov     bx, OFFSET TSR:positions+1
        mov     di, OFFSET TSR:times
copy_times:
        mov     al, cs:[bx]
        call    find_car
        mov     ax, ds:[si+04h]
        mov     cs:[di], ax
        inc     di
        inc     di
        mov     ax, ds:[si+06h]
        mov     cs:[di], ax
        inc     di
        inc     di
        inc     bx
        loop    copy_times

hskip:  pop     es
        pop     ds
        popa
        popf
        retf

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Code executed when Gap display normally finishes.
;**
;** Returns:    Nothing.
;**
;** Notes  : 
;**
;** GPU.EXE:    06d2eaH - 003782h = 069b68h
;** ITU.EXE:    06d2aaH - 003782h = 069b28h
;** USU.EXE:    06d295H = 003782h = 069b13h
;**
;** GPU.EXE:    06d2eaH - 0033ebh = 069effh
;** ITU.EXE:    06d2aaH - 0033ebh = 069ebfh
;** USU.EXE:    06d295H = 0033ebh = 069eaah
;**
;** (DOS VER hook point = 06d2eaH in GPU.EXE)
;** (DOS VER hook point = 06d295H in USU.EXE)
;**

HOOK2_EUR_MSW   equ     6000h
HOOK2_EUR_LSW   equ     9b68h
HOOK2_ITA_MSW   equ     6000h
HOOK2_ITA_LSW   equ     9b28h
HOOK2_USA_MSW   equ     6000h
HOOK2_USA_LSW   equ     9b13h

HOOK2A_EUR_MSW  equ     6000h
HOOK2A_EUR_LSW  equ     9effh
HOOK2A_ITA_MSW  equ     6000h
HOOK2A_ITA_LSW  equ     9ebfh
HOOK2A_USA_MSW  equ     6000h
HOOK2A_USA_LSW  equ     9eaah

TSR_DATA                segment

hook_2_start:           
                        nop
                        db     09ah
hook_2_off              dw     ?
hook_2_seg              dw     ?
hook_2_end:
HOOK2_LENGTH            equ     (hook_2_end - hook_2_start)

TSR_DATA                ends

TSR_CODE                segment

        public  hook2
hook2:
        ;**
        ;** Original code
        ;**
        mov     WORD PTR ds:[0020h], 0000h
                
        ;**
        ;** Our code.
        ;**
        mov     cs:tmp_sp, sp
        push    ax
        mov     ax, ds
        mov     cs:game_ds, ax
        pop     ax
        pushf
        pusha
        push    ds
        push    es

        ;**
        ;** Games DS from here on...
        ;**

        ;**
        ;** Are we currently display positions?
        ;**
        cmp     cs:show_pos, 0
        jne     hook2_1
        jmp     hook2_exit

hook2_1:
        ;**
        ;** Quit if something else requires the display area.
        ;**
        cmp    BYTE PTR ds:[0064h], 0c8h
        je     hook2_ok
        cmp    BYTE PTR ds:[0064h], 0a4h
        je     hook2_ok
        cmp    BYTE PTR ds:[0064h], 0ech
        je     hook2_ok
hook2_done_a:
        jmp    hook2_done

hook2_ok:
        mov     ax, cs:hook_2a_seg
        mov     cs:hook_2b_seg, ax
        mov     cs:hook_2c_seg, ax
        mov     cs:hook_2d_seg, ax
        mov     cs:hook_2e_seg, ax
        mov     cs:hook_2f_seg, ax
        mov     cs:hook_2g_seg, ax
        mov     cs:hook_2h_seg, ax
        mov     cs:hook_2i_seg, ax
        mov     cs:hook_2j_seg, ax

        cmp     cs:show_pos, 1
        jne     hook2_2

        ;**
        ;** Clear display & repaint original.
        ;**
        mov     si, ds:[097fh]

        mov    BYTE PTR ds:[0064h], 00h
        db      09ah                            ; Clear
hook_2b_off dw 0
hook_2b_seg dw 0

        db      09ah                            ; Lap
hook_2c_off dw 0
hook_2c_seg dw 0

        db      09ah                            ; Pos
hook_2d_off dw 0
hook_2d_seg dw 0

        db      09ah                            ; Of
hook_2e_off dw 0
hook_2e_seg dw 0

        db      09ah                            ; Car
hook_2f_off dw 0
hook_2f_seg dw 0

        db      09ah                            ; Runners
hook_2g_off dw 0
hook_2g_seg dw 0

        db      09ah                            ; MPH
hook_2h_off dw 0
hook_2h_seg dw 0

        ;**
        ;** Hold bottom of display.
        ;**
        mov    BYTE PTR ds:[0064h], 0a4h

hook2_2:
        ;**
        ;** Confirm a car hasn't crashed out since start of display.
        ;**
        mov     ax, cs:show_pos
        cmp     al, ds:[2967h]
        jg      hook2_done_a
        cmp     ax, cs:top
        jg      hook2_done_a

        ;**
        ;** Display this position.
        ;**
        mov     ax, cs:show_pos
        cmp     ax, 1
        je      no_2a
        xor     ax, ax
        xor     dx, dx
        mov     cx, cs:show_pos
        mov     bx, OFFSET TSR:positions+1
        dec     cx
        inc     bx
        mov     si, OFFSET TSR:times+4

nxt_2a:
        test    cs:[si+02h], 8000h
        jnz     no_2a
        add     ax, cs:[si+00h]
        adc     dx, cs:[si+02h]
        inc     bx
        add     si, 4
        loop    nxt_2a
        jmp     do_2a

no_2a:  xor     ax, ax
        mov     dx, 8000h

do_2a:  push    ax
        push    dx
        mov     bx, cs:show_pos
        add     bx, OFFSET TSR:positions
        mov     al, cs:[bx]
        call    find_car
        pop     dx
        pop     ax

        mov     bx, si
        mov     cx, 9

        db      09ah
hook_2a_start:           
hook_2a_off dw  ?
hook_2a_seg dw  ?
hook_2a_end:
HOOK2A_LENGTH           equ     (hook_2a_end - hook_2a_start)

        ;**
        ;** Write position on bottom by using "Runners" routine & value.
        ;**
        mov     BYTE PTR ds:[0064h], 084h
        mov     ax, ds:[2967h]
        push    ax
        mov     ax, cs:show_pos
        mov     ds:[2967h], ax
        db      09ah                            ; Runners
hook_2i_off dw 0
hook_2i_seg dw 0
        pop     ax
        mov     ds:[2967h], ax
        mov     BYTE PTR ds:[0064h], 0a4h

        ;**
        ;** If this is the leader then display his lap # in Car # field (if <64)
        ;** 
        mov     ax, cs:show_pos
        cmp     ax, 1
        jnz     no_leaders_lap
        mov     al, ds:[si+22h]
        cmp     al, 64
        jge     no_leaders_lap
        mov     BYTE PTR ds:[0064h], 0a0h
        mov     al, ds:[si+0ach]
        push    ax
        mov     al, ds:[si+22h]
        mov     ds:[si+0ach], al
        db      09ah                            ; Car #
hook_2j_off dw 0
hook_2j_seg dw 0
        pop     ax
        mov     ds:[si+0ach], al
        mov     BYTE PTR ds:[0064h], 0a4h
no_leaders_lap:

        ;**
        ;** Our DS from here on...
        ;**
        push    cs
        pop     ds

        ;**
        ;** Last position? Note compare against # cars in race.
        ;**
        mov     es, game_ds
        mov     ax, show_pos
        cmp     al, es:[2967h]
        jg      hook2_done
        cmp     ax, top
        jg      hook2_done
        inc     show_pos

        ;**
        ;** Force Ns delay, and skip screen update.
        ;**
        mov     ax, es:[294fh]
        mov     dx, es:[2951h]
        add     ax, hold_delay
        adc     dx, 0
        mov     es:[001eh], ax
        mov     es:[0020h], dx
        mov     bp, cs:tmp_sp
        add     WORD PTR ss:[bp], 3

        jmp     hook2_exit

hook2_done:
        mov     cs:show_pos, 0

hook2_exit:
        pop     es
        pop     ds
        popa
        popf
        retf

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Find SI index for car number in AL.
;**
;** Returns:    SI points to car.
;**
;** Notes  : 
;**

TSR_CODE        segment

find_car:       push    cx
                mov     si, 0d1bh
                mov     cx, 26
next_car:       cmp     ds:[si+0ach], al
                je      found_car
                add     si, 00c0h
                loop    next_car
                mov     si, 0d1bh
found_car:      pop     cx
                ret     

TSR_CODE        ends

;****************************************************************************

        end     


