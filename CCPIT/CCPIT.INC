;*****************************************************************************
;**
;** Equates & Macros
;**

TRUE            equ     1
FALSE           equ     0

DOS             equ     21h                     ; Dos interrupt call
ROM_BIOS        equ     10h                     ; PC Rom bios interrupt call
CR              equ     13                      ; Caridge return
LF              equ     10                      ; Line Feed
BELL            equ     07h                     ; Bell Code

MAGIC_CX_IN     equ     0c0deh 
MAGIC_DX_IN     equ     0deafh
MAGIC_CX_OUT    equ     05a5ah
MAGIC_DX_OUT    equ     03512h

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

     global    psp_env:dword
     global    psp_seg:word
     global    psp_env_off:word

     global    hook_sg_code_off:word
     global    hook_st_code_off:word
     global    hook_pt_code_off:word
     global    hook_sf_code_off:word
     global    hook_oj_code_off:word

     global    pit_laps:word
     global    pit_index:byte
     global    pit_times:byte

     global    tmp_max_cars_in_pit:byte
