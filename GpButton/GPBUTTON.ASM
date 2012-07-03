;**
;** File   : gpbutton.asm
;** Author : TK 
;** Date   :  6/06/94
;**
        name    gpbutton
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
include gpbutton.inc

;*****************************************************************************
;**
;** Equates & Macros
;**

TICK_TIME_MS    equ     18                      ; Approx ms of a tick
DELAY_TIME      equ     (500 / TICK_TIME_MS)    ; Time to display hook msg

EUR_SAVGAM_OFF  equ     0030h
US_SAVGAM_OFF   equ     0000h

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

                public  ja_btn1c
                public  ja_btn2c
                public  jb_btn1c
                public  jb_btn2c
ja_btn1c        db      0
ja_btn2c        db      0
jb_btn1c        db      0
jb_btn2c        db      0

joystick        db      ?

ja_btn1         db      10h
ja_btn1p        db      10h
ja_btn2         db      20h
ja_btn2p        db      20h
jb_btn1         db      40h
jb_btn1p        db      40h
jb_btn2         db      80h
jb_btn2p        db      80h

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
GP_US_RET_ADDR  equ     0b727h
MATCH_BYTES     equ     10
MATCH_OFFSET    equ     6

gp_code         db      0b0h, 00h, 0b4h, 30h, 0cdh, 21h, 0ah, 0c0h, 75h, 03h
        
;*****************************************************************************

game_sg_off     dw      ?
game_eur        db      ?

hooked_msg      db      CR, LF, "GpButton activated OK", CR, LF, '$'

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
        mov     game_eur, 1
        mov     game_sg_off, EUR_SAVGAM_OFF
        cmp     di, GP_EUR_RET_ADDR
        jz      check_match
        mov     game_eur, 0
        mov     game_sg_off, US_SAVGAM_OFF
        cmp     di, GP_US_RET_ADDR
        jnz     no_match
check_match:
        sub     di, MATCH_OFFSET
        mov     si, OFFSET TSR:gp_code
        mov     cx, MATCH_BYTES
        cld
        repe    cmpsb
        jnz     no_match

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
        mov     dx, HOOK1_US_MSW
        mov     bx, HOOK1_US_LSW
        call    get_hook_offset
        mov     si, OFFSET cs:hook_1_start
        mov     cx, HOOK1_LENGTH
        call    copy_patch_block_pos

        mov     cx, HOOK2_EUR_MSW 
        mov     ax, HOOK2_EUR_LSW
        mov     dx, HOOK2_US_MSW
        mov     bx, HOOK2_US_LSW
        call    get_hook_offset
        mov     si, OFFSET cs:hook_2_start
        mov     cx, HOOK2_LENGTH
        call    copy_patch_block_neg

        mov     cx, HOOK3_EUR_MSW 
        mov     ax, HOOK3_EUR_LSW
        mov     dx, HOOK3_US_MSW
        mov     bx, HOOK3_US_LSW
        call    get_hook_offset
        mov     si, OFFSET cs:hook_3_start
        mov     cx, HOOK3_LENGTH
        call    copy_patch_block_neg

        ret

hook_gp_exe endp

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Determines which hook address to use, European or US.
;**
;** Returns:    DX:BX = Hook
;**
;** Notes  :    CX:AX = European hook.
;**             DX:BX = US hook.
;**

TSR_CODE        segment

get_hook_offset proc near

        cmp     game_eur, 1
        jnz     get_hook_offset_do_us

        mov     bx, ax
        mov     dx, cx
get_hook_offset_do_us:
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

copy_patch_block_pos proc near

        mov     di, sp
        les     di, ss:[di + ((PUSHA_SIZE + push_end - push_start) * 2) + 2 + 2]
        sub     bx, 2
        add     di, bx
        mov     bx, es
        add     bx, dx
        mov     es, bx

copy_patch_block2_pos:
        lodsb
        stosb
        loop    copy_patch_block2_pos

        ret

copy_patch_block_pos endp

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
;** Purpose:    Code executed to obtain joystick buttons.
;**
;** Returns:    Nothing.
;**
;** Notes  : 
;**
;** GPU.EXE:    08d3c5H - 06d2eaH = 0200dbH
;** USU.EXE:    08d325H - 06d295H = 020090H
;**
;** (DOS VER hook point = 06d2eaH in GPU.EXE)
;** (DOS VER hook point = 06d295H in USU.EXE)
;**

HOOK1_EUR_MSW   equ     2000h
HOOK1_EUR_LSW   equ     00dbh
HOOK1_US_MSW    equ     2000h
HOOK1_US_LSW    equ     0090h

TSR_DATA                segment

hook_1_start:
                        nop
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
        mov     dx, 0201h
        in      al, dx
        mov     ss:[08f4h], al

        ;**
        ;** Our code.
        ;**
        pushf
        pusha
        push    ds
        push    es

        push    cs
        pop     ds

        call    check_buttons

hskip:  pop     es
        pop     ds
        popa
        popf
        retf

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Games "Pause" loop - pause pressed.
;**
;** Returns:    Nothing.
;**
;** Notes  : 
;**
;** GPU.EXE:    06d2eaH - 00f3dbh = 05df0fh
;** USU.EXE:    06d295H = 00f3dbh = 05debah
;**
;** (DOS VER hook point = 06d2eaH in GPU.EXE)
;** (DOS VER hook point = 06d295H in USU.EXE)
;**

HOOK2_EUR_MSW   equ     5d00h
HOOK2_EUR_LSW   equ     00f0fh
HOOK2_US_MSW    equ     5d00h
HOOK2_US_LSW    equ     00ebah

TSR_DATA                segment

hook_2_start:           db     09ah
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
        test    BYTE PTR [bp + 0a27h], 0ffh

        ;**
        ;** Our code.
        ;**
        pushf
        pusha
        push    ds
        push    es

        push    cs
        pop     ds

        mov     dx, 0201h
        in      al, dx
        call    check_buttons

        pop     es
        pop     ds
        popa
        popf
        retf

TSR_CODE        ends

;*****************************************************************************
;** Purpose:    Games "Pause" loop - pause release.
;**
;** Returns:    Nothing.
;**
;** Notes  : 
;**
;** GPU.EXE:    06d2eaH - 00f3edh = 05defdh
;** USU.EXE:    06d295H = 00f3edh = 05debah
;**
;** (DOS VER hook point = 06d2eaH in GPU.EXE)
;** (DOS VER hook point = 06d295H in USU.EXE)
;**

HOOK3_EUR_MSW   equ     5d00h
HOOK3_EUR_LSW   equ     00efdh
HOOK3_US_MSW    equ     5d00h
HOOK3_US_LSW    equ     00ea8h

TSR_DATA                segment

hook_3_start:           db     09ah
hook_3_off              dw     ?
hook_3_seg              dw     ?
hook_3_end:
HOOK3_LENGTH            equ     (hook_3_end - hook_3_start)

TSR_DATA                ends

TSR_CODE                segment

        public  hook3
hook3:
        ;**
        ;** Original code
        ;**
        mov     BYTE PTR ds:[2227h], 80h

        ;**
        ;** Our code.
        ;**
        pushf
        pusha
        push    ds
        push    es

        push    cs
        pop     ds

        mov     dx, 0201h
        in      al, dx
        call    check_buttons

        pop     es
        pop     ds
        popa
        popf
        retf

TSR_CODE        ends

;****************************************************************************

TSR_CODE        segment

        public  check_buttons

check_buttons:
        mov     joystick, al

        ;**
        ;** Joystick A - Button 1
        ;**
        cmp     ja_btn1c, 0
        jz      no_ja_btn1
        mov     al, joystick
        and     al, 10h
        mov     ja_btn1, al
        cmp     al, BYTE PTR ja_btn1p
        je      no_ja_btn1
        xor     ah, ah
        test    al, 10h
        jz      ja_btn1_dwn
ja_btn1_up:
        mov     ah, 80h
ja_btn1_dwn:
        mov     al, ja_btn1c
        or      al, ah
        mov     ah, ja_btn1
        mov     ja_btn1p, ah
        mov     ah, 4fh
        clc
        int     15h
no_ja_btn1:

        ;**
        ;** Joystick A - Button 2
        ;**
        cmp     ja_btn2c, 0
        jz      no_ja_btn2
        mov     al, joystick
        and     al, 20h
        mov     ja_btn2, al
        cmp     al, BYTE PTR ja_btn2p
        je      no_ja_btn2
        xor     ah, ah
        test    al, 20h
        jz      ja_btn2_dwn
ja_btn2_up:
        mov     ah, 80h
ja_btn2_dwn:
        mov     al, ja_btn2c
        or      al, ah
        mov     ah, ja_btn2
        mov     ja_btn2p, ah
        mov     ah, 4fh
        clc
        int     15h
no_ja_btn2:

        ;**
        ;** Joystick B - Button 1
        ;**
        cmp     jb_btn1c, 0
        jz      no_jb_btn1
        mov     al, joystick
        and     al, 40h
        mov     jb_btn1, al
        cmp     al, BYTE PTR jb_btn1p
        je      no_jb_btn1
        xor     ah, ah
        test    al, 40h
        jz      jb_btn1_dwn
jb_btn1_up:
        mov     ah, 80h
jb_btn1_dwn:
        mov     al, jb_btn1c
        or      al, ah
        mov     ah, jb_btn1
        mov     jb_btn1p, ah
        mov     ah, 4fh
        clc
        int     15h
no_jb_btn1:

        ;**
        ;** Joystick B - Button 2
        ;**
        cmp     jb_btn2c, 0
        jz      no_jb_btn2
        mov     al, joystick
        and     al, 80h
        mov     jb_btn2, al
        cmp     al, BYTE PTR jb_btn2p
        je      no_jb_btn2
        xor     ah, ah
        test    al, 80h
        jz      jb_btn2_dwn
jb_btn2_up:
        mov     ah, 80h
jb_btn2_dwn:
        mov     al, jb_btn2c
        or      al, ah
        mov     ah, jb_btn2
        mov     jb_btn2p, ah
        mov     ah, 4fh
        clc
        int     15h
no_jb_btn2:

        ret

TSR_CODE        ends

;****************************************************************************

        end     


