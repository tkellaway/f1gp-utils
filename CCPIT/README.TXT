CCPIT V3.0 29th Oct 1994                     Trevor Kellaway (CIS:100331,2330)

            Grand Prix/World Circuit Computer Car Pit Strategy TSR
            ======================================================

CCPIT modifies the computer cars pit strategy (in the MicroProse Grand
Prix/World Circuit simulation game). CCPIT has been tested with V1.05 of both
the European and the US versions of GP.EXE.

*** PLEASE READ THE REST OF THIS FILE, IT MAY ANSWER YOUR QUESTIONS! <g> ***

Programs (WCF1GP & GPEDITOR) are available which increase the amount of grip
the computer cars (CC) have, allowing them to brake later and be more
competitive; unfortunately on 100% race distances the CC tend to wear out
their tyres towards the end of a race and their pace drops off dramatically.

CCPIT modifies the standard game's pit strategy in a fully user configurable
manner. The standard game randomly sets on average 5 cars to pit in a >75%
race distance (which isn't wet). The game hard codes the pit stop lap at
roughly 45% race distance.

CCPIT allows you to configure how many stops the CC make and when they
make them. CCPIT allows you to define two groups of cars which have
different pit strategies. For each group you can specify the number of
cars in the group, how many stops they will make, and at what percentage
race distance they should stop at.

CCPIT also allows you to specify which tyre compound the CC should use
at the start of the race and at subsequent pit stops.

CCPIT now also supports local multi-player games (when you select
more than one active driver in F1GP's "Driver/Team Selection" menu).
When the computer is driving a player's car at pit time the car will
be called in and the tyres will be changed to those selected for that
player's car (specify the compound in F1GP's "CAR SETUP MENU", brake
whilst in the pits to enter this menu). If a player is actually
driving the car at pit time the yellow pit call light will be turned
on requesting they pit.

****************************************************************************

Installation
------------
Copy the CCPIT.EXE file to any directory on your hard disk. Note that the
TSR is now an EXE file instead of a COM file. Make sure that you delete
your old CCPIT.COM as DOS loads COM files before EXE files so the old version
will be run if you keep both CCPIT.COM and CCPIT.EXE in the same directory.

Command Line Options
--------------------
Usage: ccpit [-h?] [-u] [-pN] [-r] [-m] [-t] {-g -cN -lN [-lN] [-lN]} {...}

       -h,-?     This help message.
       -u        Unload TSR.

       -pN       Max. number cars in pits at one time (default 13).
       -r        Randomise group allocation on grid (default grid order).

       -g        Pit group.
        -cN      Stop N cars (for this group).
        -lN      Trigger cars to stop at race percentage N (for this group).

       -t?       Specify tyres for all computer cars where ? is one of ABCD.
       -m        Enable local multi-player mode (player's car called to pit).

For the top 15 cars to pit at 30% and 60%, next 8 cars at 45% & the rest 0:

       ccpit -g -c15 -l30 -l60  -g -c8 -l45

If you start CCPIT with no parameters it defaults to:

     Group 1   13 cars to pit at 25% and 55%.
     Group 2   13 cars to pit at 35% and 65%.
               Non-randomised grid (i.e. group 1 is allocated for the cars
               at the front of grid).
               Maximum of 10 cars in the pit at once.
               Normal game (not multi-player).
               CC tyre compounds allocated by F1GP (as per original game).

Starting CCPIT
--------------
Before you run GP (or F1GP) load CCPIT with your specified parameters.
When you start GP.EXE directly you should see "CCPIT Activated OK" displayed
on the text screen for half a second before the game starts up.

If you start GP using F1GP you should see "CCPIT Activated OK" at the top
of the graphics screen.

If you wish to unload CCPIT after finishing playing GP then use "CCPIT -u".

Pit Groups 
---------- 
A pit group definition should start with a '-g'. A pit group should contain
the number of cars in the group using the '-c' option.  Up to three pit stop
points may be specified using the '-l' option the appropriate number of
times. Note that the stopping points are specified as a *percentage* of the
current race distance (they are scaled if you specify less than a 100% race
distance, less than 75% races won't have any pit stops, neither will wet
races). Two pit stop groups can be defined.

So, for a race where 13 cars stop at 25% and 55%, and 10 cars stop at 45%:

     CCPIT -g -c13 -l25 -l55  -g -c10 -l45

Note that you must specify the '-l' (note this is the letter "ell" *not* the
digit one!) stopping points in increasing percentage order, CCPIT won't
validate this! The total number of cars specified with the '-c' option can't
exceed 26. If the total number of cars specified is less than 26 then the
remaining cars will go through the race without stopping.

Pitting
-------
The '-l' option specifies the *percentage* of the race distance when the cars
will pit. For example, at Silverstone which is a 59 lap race if we specify
a stop at 30% the pit stop lap will be calculated as:

     30 * 59 / 100 = 17.7, rounded down to Lap 17.

The CC will be called into the pit as they pass the start/finish line on
the lap prior to the stopping point (lap 16). Note that potentially not
all of the group will stop on the specified lap. If a driver's team mate has
already been marked to pit then that car will be marked to pit the next
time it crosses the start/finish line and its team's pit bay is empty.

You can also control the maximum number of cars which may be in the pits
simultaneously using the '-p' option. By default this is 13, but if you
wanted to change this to 8 then use '-p8'. If the pits are full (the number of
cars that have requested to come into the pit and cars that are already in
the pits has reached the '-p' value) then any cars waiting to pit will be
marked to do so when they next cross the start/finish line and a pit space
is available.

Note that for smaller values of '-p' it can take as many as 5 laps for all
the cars in a group to pit. So when deciding on a pit stop percentage keep
this in mind.

Group Allocation
----------------
Two methods of specifying how the groups are allocated to specific cars are
available, random and non-random (linear).

Linear allocation will allocate the specified number of cars in the first
group to the cars in grid order (i.e., qualifying order) from 1st place.
When all the cars from the first group have been allocated the second group
(if present) will be allocated to the next car on the grid. So for our
example of:

     CCPIT -g -c13 -l25 -l55  -g -c10 -l45

We would have:
     1st: G1, G1, G1, G1, G1, G1, G1, G1, G1, G1, G1, G1, G1,
    14th: G2, G2, G2, G2, G2, G2, G2, G2, G2, G2, 
    24th: --, --, --

This allows the fairly realistic situation where the faster cars will
make two stops, the slower cars one stop, and maybe the tail enders
attempt to go through the race without a single stop. To even this out
you will have to use fairly high values of CC grip, say about AIG=10, thus
the no stop and one stop cars will slow down towards the end of the race.

Alternatively you may use random allocation. This will randomly allocate
the G1/G2/-- entries amongst the entire grid.

Player's Car
------------
The player's car is treated in the same manner as the CC cars when allocating
when a car will stop, thus it could be in any of the groups specified and
taking up a slot that one of the CC would have occupied.

However, the player's car will NOT be called into the pits for tyres! It is
entirely up to you to decide when you should pit. The exception to this rule
is if you use the '-m' multi-player option. This option is intended to ensure
that player's cars being driven by the computer will be called in for a tyre
change.

Saved Games
-----------
CCPIT may be used with save games. CCPIT saves its current configuration in
the saved game file written by the game. The only reliable place CCPIT can
use for this information is the four driver name fields for the last two
teams. These teams are normally disabled. It doesn't matter if these teams
are enabled but if they are you will see the driver names as "#37", "#38",
"#39" and "#40".

To save a game use the normal "Save Game" feature of F1GP. When you come to
restart F1GP and reload a saved game make sure you have started CCPIT
before starting F1GP. When you restore a saved game the values used for
CCPIT will be those that were originally in use for that game (if you saved
the game whilst in the Race), not those specified on the command line for
this session. If you start a new race the current command line parameters
will take effect. In other words only restored games which were saved during
a race will use the original parameters, no matter how many times you switch
between new races and saved games.

Linked Modem Play
-----------------
Linked player games should work OK (I haven't tested this yet though). Make
sure that both players use the same GP.EXE and specify the same parameters
for CCPIT. If you experience "Link Data Mismatches" then ensure that modem
compression is turned off and that the GP.EXE at each machine is *identical*,
including any patch information (e.g., when modified by GPeditor).

Multi-Player Games
------------------
When you run a local multi-player game (by enabling more than one driver in
F1GP's "Driver/Team Selection" menu) you should also use the "-m" option.
This option ensures that any player's car being driven by the computer when
it is time to pit will be called in. The player who happens to be driving
their own car at pit time will see their yellow "Pit Call" light come on,
they may choose to cancel this, or request to come in at any other time.

CC Tyre Compounds
-----------------
By default F1GP will start most of the CC on C and B compound tyres, and
subsequent pit stops will . You can modify this behaviour by using the "-t"
option. E.g., to force all the CC to start the race on Ds use "'-tD",
subsequent CC pit stops will also use the specified tyres (Ds in this case).

Player's Tyre Compound
----------------------
The player's car will start the race on the compound specified in F1GP's pit
garage "CAR SETUP MENU" (brake whilst in the pits to enter this menu).
Subsequent pit stops will automatically select the race start compound
(unlike F1GP's default behaviour of always selecting C compound), the player
may manually select any other compound for this stop whilst on the jacks.

Stops for Damage
-----------------
CCPIT has special handling for cars that stop early due to damage to the
car. If more than 60% of the race distance is complete no futher stops will
be made. If less than 60% of the race distance is left then a single
further stop will be made within 40% of the *remaining* distance. So for
a typical first lap accident the car will then only make one stop at 40% 
of the remaining race distance.

Notes
-----
CCPIT currently requires 2.5Kb when resident and ~6Kb when loading.
CCPIT may be loaded high (into upper memory blocks) but don't forget that
it will need ~6Kb to install itself before shrinking down to its 2.5Kb
resident size.

CCPIT works with Quick Races as long as they are >75% race distance.

CCPIT will work fine alongside GPLAPTIM and SPLITTIM. Note that you
should unload the TSRs in the opposite order to that used to load them.

Change History
--------------
V0.1 Beta      First test release.
V1.0           First non-beta release. Added proper handling for cars making
               stops for to have damage repaired.
V2.0           Bug fix for double-pitting at some tracks if the first pit
               stop percentage is below 30% (this varies between tracks).
V3.0 29/10/94  Added tyre handling and multi-player support.

Further Info
------------
Please send any suggestions, comments, or bug reports (include the version 
of CCPIT you are using and the version of the game EXE) to the author
Trevor Kellaway at:

CompuServe:    100331,2330
Internet:      100331.2330@compuserve.com

This program may be freely copied and distributed, as long as it is not
modified in any way, no fee is charged and this file is always included.
This program is provided "as is" with no warranties expressed or implied.
The author will not be held responsible for any losses incurred, either
directly or indirectly by the use of this program.

This is *not* an MPS product. If you have problems with the game then try 
it without this program loaded.

