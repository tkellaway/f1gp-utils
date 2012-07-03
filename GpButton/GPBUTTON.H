/*
** File   : gpbutton.h
** Author : TK
** Date   :  9/06/94
**
** $Header:   L:/GPBUTTON/VCS/GPBUTTON.H__   1.0   08 May 1995 11:40:42   tk  $
**
** Car Performance.
*/

#ifndef   gpbutton_h
#define   gpbutton_h

/*---------------------------------------------------------------------------
** Includes
*/

/*---------------------------------------------------------------------------
** Defines and Macros
*/

#define TRUE                  1
#define FALSE                 0


/*---------------------------------------------------------------------------
** Data
*/

extern char         unload_flag;
extern char    far  *cmd_line;
extern char         cmd_line_len;
extern char    near *msg_text;
extern char         beep_count;

extern char         ja_btn1c;
extern char         ja_btn2c;
extern char         jb_btn1c;
extern char         jb_btn2c;

/*---------------------------------------------------------------------------
** Functions
*/

#endif    /* gpbutton_h */
/*---------------------------------------------------------------------------
** End of File
*/

