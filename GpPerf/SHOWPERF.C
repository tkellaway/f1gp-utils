/*
** File   : showperf.c
** Author : TK
** Date   :  1/09/94
**
** $Header:   F:/TK/GPPERF/VCS/SHOWPERF.C__   1.7   15 Oct 1995 16:06:06   tk  $
**
** Display performance log.
**
** V1.0 18/Nov/94   First version.
** V2.0 11-Jun-94   Added support for new record format.
** V2.1 19-Jun-94   Added missing <CR> to default output.
** V3.0 15-Oct-95   Added support for extra parameters.
*/

#define VERSION     "V3.0 15-Oct-95"

/*---------------------------------------------------------------------------
** Includes
*/

/*lint -elib(???) */
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
/*lint +elib(???) */
#include "gpperf.h"

/*---------------------------------------------------------------------------
** Defines and Macros
*/

#define DEFAULT_FILENAME           "GPPERF.PRF"
#define TMP_FILENAME               "GPPERF.@@@"

#define SUPPORTED_LOG_VERSION      2

/*---------------------------------------------------------------------------
** Typedefs
*/

typedef int              bool;
typedef unsigned long    ulong;

/*---------------------------------------------------------------------------
** Local function prototypes
*/

static void Usage(void);
static const char * LapTimeToAscii(ulong tim);
static const char * LapTimeToFilename(ulong tim);

/*---------------------------------------------------------------------------
** Data
*/

/*lint -esym(528,sccsid) */
static const char sccsid[] = "@(#)" __FILE__ "\t" VERSION;

/*---------------------------------------------------------------------------
** Functions
*/

int
main(
     int  argc,
     char **argv
) {
     PERFORMANCE_ENTRY   pe;
     FILE                *fp;
     FILE                *ofp           = NULL;
     char                *filename      = DEFAULT_FILENAME;
     char                option;
     bool                f_flag         = FALSE;
     bool                w_flag         = FALSE;
     bool                c_flag         = FALSE;
     bool                x_flag         = FALSE;
     bool                k_flag         = FALSE;
     bool                i_flag         = FALSE;
     bool                t_flag         = FALSE;
     bool                s_flag         = FALSE;
     bool                r_flag         = FALSE;
     bool                g_flag         = FALSE;
     bool                d_flag         = FALSE;
     bool                a_flag         = FALSE;
     bool                b_flag         = FALSE;
     float               kph_scale      = 1.0;
     unsigned int        rpm_scale      = 1;
     unsigned int        gear_scale     = 1;
     bool                writing;
     const char          *fname;
     ulong               best_time;
     long                file_pos;
     long                prev_pos;
     long                last_pos;

     for (--argc, ++argv; argc; argc--, argv++) {
          if (**argv == '-' || **argv == '/') {
               while (*++*argv) {
                    option = (char) ((isupper(**argv)) ? tolower(**argv) : **argv);
                    switch (option) {
                    case 'c':
                         c_flag = TRUE;
                         break;

                    case 'f':
                         f_flag = TRUE;
                         break;

                    case 'w':
                         w_flag = TRUE;
                         break;

                    case 'i':
                         i_flag = TRUE;
                         break;

                    case 't':
                         t_flag = TRUE;
                         break;

                    case 's':
                         s_flag = TRUE;
                         break;

                    case 'r':
                         r_flag = TRUE;
                         break;

                    case 'g':
                         g_flag = TRUE;
                         break;

                    case 'k':
                         k_flag = TRUE;
                         kph_scale = 1.609;
                         break;

                    case 'x':
                         x_flag = TRUE;
                         break;

                    case 'd':
                         d_flag = TRUE;
                         break;

                    case 'a':
                         a_flag = TRUE;
                         break;

                    case 'b':
                         b_flag = TRUE;
                         break;

                    case 'h':
                    case '?':
                         Usage();
                         break;

                    default:
                         (void) printf("ShowPerf: unknown option '-%c'.\n", **argv);
                         Usage();
                         break;
                    }
               }
          }
          else {
               filename = *argv;
          }
     }

     if (x_flag) {
          if (k_flag) {
               rpm_scale  = 50;
               gear_scale = 10;
          }
          else {
               rpm_scale  = 100;
               gear_scale = 10;
          }
     }

     fp = fopen(filename, "rb");
     if (fp == 0) {
          (void) printf("ShowPerf: Can't open file called '%s'\n", filename);
          return 1;
     }

     if (w_flag) {
          /*
          ** Write all times to files.
          */
          writing = FALSE;
          (void) fseek(fp, 0L, 0);
          while (fread(&pe, sizeof(pe), 1, fp) == 1) {
               if (TRACK_SEGMENT_ID(pe.track_segment_id) == 0) {
                    if (writing) {
                         (void) fwrite(&pe, sizeof(pe), 1, ofp);
                         writing = FALSE;
                         (void) fclose(ofp);

                         if (pe.time != 0 && !(pe.time & TIME_MASK)) {
                              fname = LapTimeToFilename(pe.time);
                              if (fname) {
                                   (void) unlink(fname);
                                   if (rename(TMP_FILENAME, fname) == 0) {
                                        (void) printf("%s lap written to '%s'\n", LapTimeToAscii(pe.time), fname);
                                   }
                                   else {
                                        (void) unlink(TMP_FILENAME);
                                        (void) printf("ShowPerf: unable to rename temporary file to '%s'\n", fname);
                                   }
                              }
                         }
                    }

                    pe.time = 0L;
                    if ((ofp = fopen(TMP_FILENAME, "wb")) != NULL) {
                         writing = TRUE;
                    }
                    else {
                         (void) printf("ShowPerf: unable to write to temporary file '%s'\n", TMP_FILENAME);
                         return 1;
                    }
               }

               if (writing) {
                    (void) fwrite(&pe, sizeof(pe), 1, ofp);
               }
          }
          (void) fclose(ofp);
          (void) unlink(TMP_FILENAME);
          return 0;
     }
     else if (f_flag) {
          /*
          ** Write fastest time to file.
          */
          best_time = 999999L;
          file_pos  = -1;
          prev_pos  = -1;
          last_pos  = -1;

          (void) fseek(fp, 0L, 0);
          while (fread(&pe, sizeof(pe), 1, fp) == 1) {
               if (TRACK_SEGMENT_ID(pe.track_segment_id) == 0) {
                    if (last_pos != -1 && pe.time != 0 && !(pe.time & TIME_MASK) && pe.time < best_time) {
                         best_time = pe.time;
                         prev_pos = last_pos;
                         file_pos = ftell(fp) - sizeof(pe);
                    }
                    last_pos = ftell(fp) - sizeof(pe);
               }
          }

          if (file_pos < 0L) {
               (void) printf("ShowPerf: No completed laps found!\n");
               return 1;
          }

          (void) fseek(fp, prev_pos, 0);
          if ((ofp = fopen(TMP_FILENAME, "wb")) != NULL) {
               while (fread(&pe, sizeof(pe), 1, fp) == 1) {
                    if (TRACK_SEGMENT_ID(pe.track_segment_id) == 0 && pe.time != best_time) {
                         pe.time = 0L;
                    }
                    (void) fwrite(&pe, sizeof(pe), 1, ofp);
                    if (TRACK_SEGMENT_ID(pe.track_segment_id) == 0 && pe.time == best_time) {
                         break;
                    }
               }
          }
          else {
               (void) printf("ShowPerf: unable to write to temporary file '%s'\n", TMP_FILENAME);
               return 1;
          }
          (void) fclose(ofp);

          fname = LapTimeToFilename(best_time);
          if (fname) {
               (void) unlink(fname);
               if (rename(TMP_FILENAME, fname) == 0) {
                    (void) printf("Fastest lap was %s and was written to '%s'\n", LapTimeToAscii(pe.time), LapTimeToFilename(pe.time));
               }
               else {
                    (void) unlink(TMP_FILENAME);
                    (void) printf("ShowPerf: unable to rename temporary file to '%s'\n", fname);
               }
          }

          (void) unlink(TMP_FILENAME);
          return 0;
     }

     (void) fseek(fp, 0L, 0);
     while (fread(&pe, sizeof(pe), 1, fp) == 1) {
          if (LOG_VERSION(pe.track_segment_id) != SUPPORTED_LOG_VERSION) {
               (void) printf("This version of ShowPerf only supports V%u.x GpPerf logs.\n", SUPPORTED_LOG_VERSION);
               return 1;
          }

          if (c_flag) {
               if (pe.gear == 7) {
                    pe.gear = 1;
               }
               if (!i_flag && !t_flag && !s_flag && !r_flag && !g_flag && !d_flag && !a_flag && !b_flag) {
                    (void) printf("%2u, %2u, %4u, %5lu.%03lu, %4u, %5d, %5u, %5u, %5u, %5u, %5u\n",
                                   CAR_NUMBER(pe.car_number),
                                   pe.circuit,
                                   TRACK_SEGMENT_ID(pe.track_segment_id),
                                   pe.time / 1000L, pe.time % 1000L,
                                   pe.tyre_compound,
                                   (pe.gear == 255) ? (-1 * gear_scale) : pe.gear * gear_scale,
                                   pe.revs / rpm_scale,
                                   (unsigned) (pe.speed * kph_scale),
                                   pe.steering,
                                   pe.accelerator,
                                   pe.brake
                         );
               }
               else {
                    if (i_flag)    (void) printf("%4u, ", TRACK_SEGMENT_ID(pe.track_segment_id));
                    if (t_flag)    (void) printf("%5lu.%03lu, ", pe.time / 1000L, pe.time % 1000L);
                    if (s_flag)    (void) printf("%5u, ", (unsigned) (pe.speed * kph_scale));
                    if (r_flag)    (void) printf("%5u, ", pe.revs / rpm_scale);
                    if (g_flag)    (void) printf("%5u, ", (pe.gear == 255) ? (-1 * gear_scale) : pe.gear * gear_scale);
                    if (d_flag)    (void) printf("%5u, ", pe.steering);
                    if (a_flag)    (void) printf("%5u, ", pe.accelerator);
                    if (b_flag)    (void) printf("%5u, ", pe.brake);
                    (void) printf("\n");
               }
          }
          else {
               if (!i_flag && !t_flag && !s_flag && !r_flag && !g_flag && !d_flag && !a_flag && !b_flag) {
                    (void) printf("#%02u Circuit:%02u Segment:%04u Time:%s Tyres:%c Gear:%c Revs:%05u %3s:%03u",
                                   CAR_NUMBER(pe.car_number),
                                   pe.circuit,
                                   TRACK_SEGMENT_ID(pe.track_segment_id),
                                   LapTimeToAscii(pe.time),
                                   "ABCDQW??"[(pe.tyre_compound & 0x07)],
                                   "RN123456S"[(pe.gear & 0x07) + 1],
                                   pe.revs,
                                   (kph_scale == 1.0) ? "MPH" : "KPH",
                                   (unsigned) (pe.speed * kph_scale)
                         );
                    (void) printf("\n");
               }
               else {
                    if (i_flag)    (void) printf("Segm:%04u ", TRACK_SEGMENT_ID(pe.track_segment_id));
                    if (t_flag)    (void) printf("Time:%s ", LapTimeToAscii(pe.time));
                    if (s_flag)    (void) printf("%3s:%03u ", (kph_scale == 1.0) ? "MPH" : "KPH", (unsigned) (pe.speed * kph_scale));
                    if (r_flag)    (void) printf("Revs:%05u ", pe.revs);
                    if (g_flag)    (void) printf("Gear:%c ", "RN123456S"[(pe.gear & 0x07) + 1]);
                    if (d_flag)    (void) printf("Dir:%05u ", pe.steering);
                    if (a_flag)    (void) printf("Acc:%05u ", pe.accelerator);
                    if (b_flag)    (void) printf("Brk:%05u ", pe.brake);
                    (void) printf("\n");
               }
          }
     }
     (void) fclose(fp);

     return 0;
}

static void
Usage(
     void
) {
     (void) printf("ShowPerf " VERSION " - Grand Prix/World Circuit Car Performance.\n");
     (void) printf("Copyright (c) Trevor Kellaway (CIS:100331,2330) 1995 - All Rights Reserved.\n\n");

     (void) printf( "Usage: ShowPerf [-fwcxk] [-itsrgdab] [-h?] [log filename]\n"
                    "       -?/-h  This usage message.\n"
                    "\n"
                    "       -f     Write fastest lap to '?m??s???.PRF' file.\n"
                    "       -w     Write all laps to '?m??s???.PRF' files.\n"
                    "\n"
                    "       -c     Display in CSV export format.\n"
                    "       -x     Scale RPM & Gears to match speed scale (for CSV export).\n"
                    "       -k     Display speed in KPH.\n"
                    "\n"
                    "Filter options (all on by default)\n"
                    "       -i     Identity of track segment.\n"
                    "       -t     Time (elapsed time of session).\n"
                    "       -s     Speed in MPH (or KPH).\n"
                    "       -r     RPM.\n"
                    "       -g     Gear.\n"
                    "       -d     Direction (steering).\n"
                    "       -a     Accelerator.\n"
                    "       -b     Brake.\n"
               );
     exit(1);
}

static const char *
LapTimeToAscii(
     ulong  tim                         /* In   Lap time                   */
) {
     static char    buff[20];
     ulong          thous;
     ulong          secs;
     ulong          mins;

     if (tim & TIME_MASK) {
          (void) sprintf(buff, "-:--.---");
          return buff;
     }
     thous = tim % 1000U;
     tim /= 1000L;

     secs = tim % 60U;
     tim /= 60U;

     mins = tim % 60U;
     tim /= 60U;

     (void) sprintf(buff, "%lu:%02lu.%03lu", mins, secs, thous);
     return buff;
}

static const char *
LapTimeToFilename(
     ulong  tim                         /* In   Lap time                   */
) {
     static char    buff[20];
     ulong          thous;
     ulong          secs;
     ulong          mins;

     if (tim & TIME_MASK) {
          return NULL;
     }
     thous = tim % 1000U;
     tim /= 1000L;

     secs = tim % 60U;
     tim /= 60U;

     mins = tim % 60U;
     tim /= 60U;

     (void) sprintf(buff, "%lum%02lus%03lu.prf", mins, secs, thous);
     return buff;
}

/*---------------------------------------------------------------------------
** End of File
*/

