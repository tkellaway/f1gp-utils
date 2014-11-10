/*
** File   : logentry.c
** Author : TK
** Date   : 31/08/94
**
** $Header:   F:/TK/GPPERF/VCS/LOGENTRY.C__   1.3   15 Oct 1995 16:06:06   tk  $
**
** Fill in car performance entry.
*/

/*---------------------------------------------------------------------------
** Includes
*/

#include "gpperf.h"
#include "version.i"

/*---------------------------------------------------------------------------
** Defines and Macros
*/

#define GetWord(p)                 (*((_word far *)(p)))
#define GetDWord(p)                (*((_dword far *)(p)))

/*---------------------------------------------------------------------------
** Typedefs
*/

typedef struct {
     unsigned char si[0xc0];
} CAR;

/*---------------------------------------------------------------------------
** Local function prototypes
*/

/*---------------------------------------------------------------------------
** Data
*/

/*---------------------------------------------------------------------------
** Functions
*/

void
LogEntry(
     PERFORMANCE_ENTRY   *pe,           /* Out Complete data structure     */
     CAR far             *pCar,         /* In  Car data structure          */
     _word               circuit,       /* In  Circuit (LSB only)          */
     _word               braking,       /* In  Braking                     */
     _dword              session_time   /* In  Session time                */
) {
     _word               track_segment_id;

     track_segment_id = GetWord(&pCar->si[0x12]);

     pe->track_segment_id     = (VERSION_MAJOR << 12) | ((track_segment_id - 0x30) / 0x2e);
     if (pCar->si[0x23] & 0x20) {
          pe->track_segment_id |= IN_PIT_LANE_MASK;
     }
     pe->time                 = session_time;
     pe->circuit              = (_byte) circuit;
     pe->gear                 = pCar->si[0x24];
     if (pe->gear == 1) {
          if (pCar->si[0x7e] & 0x10) {
               pe->gear = 7;
          }
     }
     pe->revs                 = GetWord(&pCar->si[0x62]);
     pe->speed                = (_word) ((GetWord(&pCar->si[0x10]) * 0x02baL) >> 16);
     pe->tyre_compound        = pCar->si[0xb2] & 0x07;
     pe->car_number           = pCar->si[0xac];

     /*
     ** New to V2.0 PRF
     */
     pe->steering             = (_word) GetWord(&pCar->si[0x7c]);
     pe->accelerator          = (_word) GetWord(&pCar->si[0x98]);
     pe->brake                = braking;
     pe->x                    = (_dword) GetDWord(&pCar->si[0x28]);
     pe->y                    = (_dword) GetDWord(&pCar->si[0x2c]);

     /*
     ** Possible future extensions.
     */
#if 0 /*<TK>*/
     pe->angle_momentum       = GetWord(&pCar->si[0x00]);
     pe->angle_facing         = GetWord(&pCar->si[0x1a]);
     pe->track_deviation      = GetWord(&pCar->si[0x8c]);
     pe->fuel_load            = GetWord(&pCar->si[0xa4]);
     pe->tyre_grip            = GetWord(&pCar->si[0x46]);
#endif
}

/*---------------------------------------------------------------------------
** End of File
*/

