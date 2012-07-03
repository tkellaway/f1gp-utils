/*
** File   : parse.c
** Author : TK 
** Date   :  9/04/94
**
** $Header:   F:/TK/GPGAP/VCS/PARSE.C__   1.0   29 Jul 1995 19:59:34   tk  $
**
** Parse the command line.
*/

/*---------------------------------------------------------------------------
** Includes
*/

#include "gpgap.h"
#include "version.i"

/*---------------------------------------------------------------------------
** Defines and Macros
*/

#ifndef TRUE
#define TRUE        1
#endif

#ifndef FALSE
#define FALSE       0
#endif

#define WHAT_OFFSET 4

/*---------------------------------------------------------------------------
** Typedefs
*/

/*---------------------------------------------------------------------------
** Local function prototypes
*/

void wrt_msg(void);

void Usage(void);
void display_msg(char near *msg);
void display_chr(char c);
short atoi(register const char far *p);

/*---------------------------------------------------------------------------
** Data
*/

char title_msg[] =
     "@(#)"
     "GpGap " VERSION " - Grand Prix/World Circuit Gap Display.\n"
     "Copyright (c) Trevor Kellaway (CIS:100331,2330) 1995 - All Rights Reserved.\n\n";

/*---------------------------------------------------------------------------
** Functions
*/

int
parse(
     void
) {
     register int   i;
     int            option_next;
     short          n;

     display_msg(&title_msg[WHAT_OFFSET]);

     for (i = 0; i <= cmd_line_len; i++) {
          if ( cmd_line[i] == '\r' || cmd_line[i] == '\n' || cmd_line[i] == '\t') {
               cmd_line[i] = '\0';
          }
     }

     option_next = FALSE;
     while (cmd_line_len--) {
          if (option_next) {
               option_next = FALSE;

               /*
               ** Don't use switch as indirect table gets it wrong for a COM file.
               */
               if (*cmd_line == 'd') {
                    n = atoi(&cmd_line[1]);
                    if (n >= 1 && n <= 20) {
                         hold_delay = n * 1000;
                    }
                    else {
                         display_msg("GpGap: -d value should be between 1 and 20 (default 3s).\n");
                         return FALSE;
                    }
               }
               else if (*cmd_line == 't') {
                    n = atoi(&cmd_line[1]);
                    if (n >= 3 && n <= 26) {
                         top = n;
                    }
                    else {
                         display_msg("GpGap: -t value should be between 3 and 26 (default 6).\n");
                         return FALSE;
                    }
               }
               else if (*cmd_line == 'u') {
                    unload_flag = TRUE;
                    return TRUE;
               }
               else {
                    Usage();
                    return FALSE;
               }
          }
          else if (*cmd_line == '-' || *cmd_line == '/') {
               option_next = TRUE;
          }
          ++cmd_line;
     }

     return TRUE;
}

void
Usage(
     void
) {
     display_msg(   "Usage: GpGap [-h?] [-dN] [-tN] [-u]\n"
                    "       -dN       Delay N seconds between display (default 3s).\n"
                    "       -tN       Display top N places (default 6).\n"
                    "       -h,-?     This help message.\n"
                    "       -u        Unload TSR.\n"
                    "\n"
               );
}

void
display_msg(
     char near *msg                     /* In Msg to display               */
) {
     while (*msg) {
          if (*msg == '\n') {
               display_chr('\r');
          }
          display_chr(*msg++);
     }
}

/*lint -e789 Ignore assigning auto to static */

void
display_chr(
     char c                             /* In Character to display         */
) {
     char cs[2];

     cs[0]     = c;
     cs[1]     = '$';
     msg_text  = cs;
     wrt_msg();
}

/*lint +e789 Ignore assigning auto to static */

short
atoi(
     register const char far *p         /* In  Pointer to ASCII string     */
) {
     register int n;
     register int f;

     n = 0;
     f = 0;
     for ( ; ; p++) {
          switch (*p) {
          case ' ':
          case '\t':
               continue;
          case '-':
               f++;
               /*lint fall throught */
          case '+':
               p++;
               break;

          default:
               break;
          }
          break;
     }
     while (*p >= '0' && *p <= '9') {
          n = n * 10 + *p++ - '0';
     }
     return (f ? -n : n);
}

/*---------------------------------------------------------------------------
** End of File
*/

