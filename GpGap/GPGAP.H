/*
** File   : gpgap.h
** Author : TK
** Date   :  9/06/94
**
** $Header:   F:/TK/GPGAP/VCS/GPGAP.H__   1.0   29 Jul 1995 19:59:34   tk  $
**
** Gap Display.
*/

#ifndef   gpgap_h
#define   gpgap_h

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
extern short        top;
extern short        hold_delay;

/*---------------------------------------------------------------------------
** Functions
*/

#endif    /* gpgap_h */
/*---------------------------------------------------------------------------
** End of File
*/

