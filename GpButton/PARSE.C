/*
** File   : parse.c
** Author : TK 
** Date   :  9/04/94
**
** $Header:   L:/GPBUTTON/VCS/PARSE.C__   1.1   14 May 1995 12:02:30   tk  $
**
** Parse the command line.
*/

/*---------------------------------------------------------------------------
** Includes
*/

#include "gpbutton.h"
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

#define NUM_ELEMENTS(x)       (sizeof(x) / sizeof(x[0]))

/*---------------------------------------------------------------------------
** Typedefs
*/

typedef struct {
     char key;
     char scan_code;
} SCAN_CODES;

/*---------------------------------------------------------------------------
** Local function prototypes
*/

void wrt_msg(void);

void Usage(void);
void display_msg(char near *msg);
void display_chr(char c);

char decode(char far *p, char *n);

/*---------------------------------------------------------------------------
** Data
*/

char title_msg[] =
     "@(#)"
     "GpButton " VERSION "\nGrand Prix/World Circuit Joystick Button to Key Converter.\n"
     "Copyright (c) Trevor Kellaway (CIS:100331,2330) 1995 - All Rights Reserved.\n\n";

static const SCAN_CODES scan_codes[] = {
     {    ' ',  0x39     },

     {    '1',  0x02     },
     {    '2',  0x03     },
     {    '3',  0x04     },
     {    '4',  0x05     },
     {    '5',  0x06     },
     {    '6',  0x07     },
     {    '7',  0x08     },
     {    '8',  0x09     },
     {    '9',  0x0a     },
     {    '0',  0x0b     },

     {    'q', 0x10      },
     {    'w', 0x11      },
     {    'e', 0x12      },
     {    'r', 0x13      },
     {    't', 0x14      },
     {    'y', 0x15      },
     {    'u', 0x16      },
     {    'i', 0x17      },
     {    'o', 0x18      },
     {    'p', 0x19      },

     {    'a', 0x1e      },
     {    's', 0x1f      },
     {    'd', 0x20      },
     {    'f', 0x21      },
     {    'g', 0x22      },
     {    'h', 0x23      },
     {    'j', 0x24      },
     {    'k', 0x25      },
     {    'l', 0x26      },

     {    'z', 0x2c      },
     {    'x', 0x2d      },
     {    'c', 0x2e      },
     {    'v', 0x2f      },
     {    'b', 0x30      },
     {    'n', 0x31      },
     {    'm', 0x32      },

     {    'Q', 0x10      },
     {    'W', 0x11      },
     {    'E', 0x12      },
     {    'R', 0x13      },
     {    'T', 0x14      },
     {    'Y', 0x15      },
     {    'U', 0x16      },
     {    'I', 0x17      },
     {    'O', 0x18      },
     {    'P', 0x19      },

     {    'A', 0x1e      },
     {    'S', 0x1f      },
     {    'D', 0x20      },
     {    'F', 0x21      },
     {    'G', 0x22      },
     {    'H', 0x23      },
     {    'J', 0x24      },
     {    'K', 0x25      },
     {    'L', 0x26      },

     {    'Z', 0x2c      },
     {    'X', 0x2d      },
     {    'C', 0x2e      },
     {    'V', 0x2f      },
     {    'B', 0x30      },
     {    'N', 0x31      },
     {    'M', 0x32      },
};

/*---------------------------------------------------------------------------
** Functions
*/

int
parse(
     void
) {
     register int   i;
     int            option_next;
     char           n;

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
               if ((cmd_line[0] == 'A' || cmd_line[0] == 'a') && cmd_line[1] == '1' && cmd_line[2] == '=') {
                    cmd_line += 3;
                    cmd_line_len -= 3;
                    ja_btn1c = decode(cmd_line, &n);
                    if (!ja_btn1c) {
                         return FALSE;
                    }
                    cmd_line += n - 1;
                    cmd_line_len -= n - 1;
               }
               else if ((cmd_line[0] == 'A' || cmd_line[0] == 'a') && cmd_line[1] == '2' && cmd_line[2] == '=') {
                    cmd_line += 3;
                    cmd_line_len -= 3;
                    ja_btn2c = decode(cmd_line, &n);
                    if (!ja_btn2c) {
                         return FALSE;
                    }
                    cmd_line += n - 1;
                    cmd_line_len -= n - 1;
               }
               else if ((cmd_line[0] == 'B' || cmd_line[0] == 'b') && cmd_line[1] == '1' && cmd_line[2] == '=') {
                    cmd_line += 3;
                    cmd_line_len -= 3;
                    jb_btn1c = decode(cmd_line, &n);
                    if (!jb_btn1c) {
                         return FALSE;
                    }
                    cmd_line += n - 1;
                    cmd_line_len -= n - 1;
               }
               else if ((cmd_line[0] == 'B' || cmd_line[0] == 'b') && cmd_line[1] == '2' && cmd_line[2] == '=') {
                    cmd_line += 3;
                    cmd_line_len -= 3;
                    jb_btn2c = decode(cmd_line, &n);
                    if (!jb_btn2c) {
                         return FALSE;
                    }
                    cmd_line += n - 1;
                    cmd_line_len -= n - 1;
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

     if (ja_btn1c == 0 && ja_btn2c == 0 && jb_btn1c == 0 && jb_btn2c == 0) {
          display_msg("GpButton: You must specify a function for at least one button.\n");
          return FALSE;
     }

     return TRUE;
}

void
Usage(
     void
) {
     display_msg(   "Usage: GpButton [-A1='?'] [-A2='?'] [-B1='?'] [-B2='?'] [-h?] [-u]\n"
                    "       -A1='?'   Joystick A Button 1=?.\n"
                    "       -A2='?'   Joystick A Button 2=?.\n"
                    "       -B1='?'   Joystick B Button 1=?.\n"
                    "       -B2='?'   Joystick B Button 2=?.\n"
                    "       -h,-?     This help message.\n"
                    "       -u        Unload TSR.\n"
                    "\n"
                    "'?' may be one of:\n"
                    "       1234567890 abcdefghijklmnopqrstuvwxyz\n"
                    "       F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 Ent\n"
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

char
decode(
     char far  *p,
     char      *n
) {
     char           r = 0;
     unsigned int   i;

     if (p[0] == '\'' && p[2] == '\'') {
          for (i = 0; i < NUM_ELEMENTS(scan_codes); i++) {
               if (scan_codes[i].key == p[1]) {
                    r = scan_codes[i].scan_code;
                    break;
               }
          }
          *n = 3;
     }
     else if (p[0] == '\'' && p[1] == 'F' && p[3] == '\'') {
          r = (p[2] - '0') + (0x3b - 1);
          *n = 4;
     }
     else if (p[0] == '\'' && p[1] == 'F' && p[2] == '1' && p[3] == '0' && p[4] == '\'') {
          r = 0x44;
          *n = 5;
     }
     else if (p[0] == '\'' && p[1] == 'E' && p[2] == 'n' && p[3] == 't' && p[4] == '\'') {
          r = 0x1c;
          *n = 5;
     }

     if (r == 0) {
          display_msg("GpButton: Invalid key specification.\n");
     }

     return r;
}

/*---------------------------------------------------------------------------
** End of File
*/

