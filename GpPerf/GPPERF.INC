;*****************************************************************************
;**
;** Equates & Macros
;**

TRUE            equ     1
FALSE           equ     0

DOS             equ     21h                     ; Dos interrupt call
DOS_TERMINATE   equ     20h                     ; Terminate interrupt.
ROM_BIOS        equ     10h                     ; PC Rom bios interrupt call
CR              equ     13                      ; Caridge return
LF              equ     10                      ; Line Feed
BELL            equ     07h                     ; Bell Code

MAGIC_CX_IN     equ     0c0deh 
MAGIC_DX_IN     equ     0dea0h
MAGIC_CX_OUT    equ     05a5ah
MAGIC_DX_OUT    equ     03612h

BEEP_ERROR      equ     20
BEEP_2_TIME     equ     3
BEEP_1_TIME     equ     (3 + BEEP_2_TIME)

BEEP_1_FREQ     equ     0f00h
BEEP_2_FREQ     equ     0900h

;*****************************************************************************
;**
;** Externals
;**

     global    old08_hndlr:dword
     global    old08_off:word
     global    old08_seg:word

     global    old11_hndlr:dword
     global    old11_off:word
     global    old11_seg:word

     global    old21_hndlr:dword
     global    old21_off:word
     global    old21_seg:word

     global    delay_count:byte
     global    beep_count:byte
     global    enabled:byte
     global    q_filename:byte

     global    psp_env:dword
     global    psp_seg:word
     global    psp_env_off:word

     global    hook_code_off:word
     global    hook_seg_off:word
     global    hook_pit_off:word
     global    hook_kbd_off:word
     global    hook_led_off:word
     global    hook_tim_off:word
