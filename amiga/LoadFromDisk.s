*********************************************************************************************

                          opt            P=68020

*********************************************************************************************

                          incdir         "includes"
                          include        "AB3DI.i"
                          include        "macros.i"
                          include        "defs.i"

                          include        "exec/memory.i"

*********************************************************************************************
; SFX name,size and number

SFX_NAMES:
                          dc.l           ScreamName,4400                        ; 0
                          dc.l           ShootName,7200                         ; 1
                          dc.l           MunchName,5400                         ; 2
                          dc.l           PooGunName,4600                        ; 3
                          dc.l           CollectName,3400                       ; 4

                          dc.l           DoorNoiseName,8400                     ; 5
                          dc.l           BassName,8000                          ; 6
                          dc.l           StompName,4000                         ; 7
                          dc.l           LowScreamName,8600                     ; 8
                          dc.l           BaddieGunName,6200                     ; 9

                          dc.l           SwitchNoiseName,1200                   ; 10
                          dc.l           ReloadName,4000                        ; 11
                          dc.l           NoAmmoName,2200                        ; 12
                          dc.l           SplotchName,3000                       ; 13
                          dc.l           SplatPopName,5600                      ; 14
 
                          dc.l           BoomName,11600                         ; 15
                          dc.l           HissName,7200                          ; 16
                          dc.l           Howl1Name,7400                         ; 17
                          dc.l           Howl2Name,9200                         ; 18
                          dc.l           PantName,5000                          ; 19

                          dc.l           WhooshName,4000                        ; 20
                          dc.l           ShotGunName,8800                       ; 21

                          dc.l           FlameName,9000                         ; 22
                          dc.l           MuffledName,1800                       ; 23
                          dc.l           ClopName,3400                          ; 24
 
                          dc.l           ClankName,1600                         ; 25
                          dc.l           TeleportName,11000                     ; 26
                          dc.l           HALFWORMPAINNAME,8400                  ; 27
                          dc.l           -1

*********************************************************************************************

ShotGunName:              dc.b           'disk/sounds/shotgun',0
                          even 
ScreamName:               dc.b           'disk/sounds/scream',0
                          even
LowScreamName:            dc.b           'disk/sounds/lowscream',0
                          even
BaddieGunName:            dc.b           'disk/sounds/baddiegun',0
                          even
BassName:                 dc.b           'disk/sounds/splash',0
                          even
ShootName:                dc.b           'disk/sounds/fire!',0
                          even
MunchName:                dc.b           'disk/sounds/munch',0
                          even
PooGunName:               dc.b           'disk/sounds/shoot.dm',0
                          even
CollectName:              dc.b           'disk/sounds/collect',0
                          even
DoorNoiseName:            dc.b           'disk/sounds/newdoor',0
                          even
StompName:                dc.b           'disk/sounds/footstep3',0
                          even
SwitchNoiseName:          dc.b           'disk/sounds/switch',0
                          even
ReloadName:               dc.b           'disk/sounds/switch1.sfx',0
                          even
NoAmmoName:               dc.b           'disk/sounds/noammo',0
                          even
SplotchName:              dc.b           'disk/sounds/splotch',0
                          even
SplatPopName:             dc.b           'disk/sounds/splatpop',0
                          even
BoomName:                 dc.b           'disk/sounds/boom',0
                          even
HissName:                 dc.b           'disk/sounds/newhiss',0
                          even
Howl1Name:                dc.b           'disk/sounds/howl1',0
                          even
Howl2Name:                dc.b           'disk/sounds/howl2',0
                          even
PantName:                 dc.b           'disk/sounds/pant',0
                          even
WhooshName:               dc.b           'disk/sounds/whoosh',0
                          even
RoarName:                 dc.b           'disk/sounds/bigscream',0
                          even
FlameName:                dc.b           'disk/sounds/flame',0 
                          even
MuffledName:              dc.b           'disk/sounds/MuffledFoot',0
                          even
ClopName:                 dc.b           'disk/sounds/footclop',0
                          even
ClankName:                dc.b           'disk/sounds/footclank',0
                          even
TeleportName:             dc.b           'disk/sounds/teleport',0
                          even
HALFWORMPAINNAME:         dc.b           'disk/sounds/HALFWORMPAIN',0
                          even
 
*********************************************************************************************

;-102
;7c
 
OBJ_NAMES:
                          dc.l           wad1n
                          dc.l           ptr1n
 
                          dc.l           wad2n
                          dc.l           ptr2n

*************************************************************************
; Missing ugly monster
;                   dc.l                   wad3n                                  
;                   dc.l                   ptr3n
*************************************************************************

                          dc.l           wad4n
                          dc.l           ptr4n
 
                          dc.l           wad5n
                          dc.l           ptr5n
 
                          dc.l           wad6n
                          dc.l           ptr6n
 
                          dc.l           wad7n
                          dc.l           ptr7n
 
                          dc.l           wad8n
                          dc.l           ptr8n
 
                          dc.l           wad9n
                          dc.l           ptr9n
 
                          dc.l           wadan
                          dc.l           ptran
 
                          dc.l           wadbn
                          dc.l           ptrbn
 
                          dc.l           wadcn
                          dc.l           ptrcn
 
                          dc.l           waddn
                          dc.l           ptrdn

                          dc.l           waden
                          dc.l           ptren
 
                          dc.l           wadfn
                          dc.l           ptrfn
 
                          dc.l           -1,-1

*********************************************************************************************

wad1n:
                          dc.b           'disk/includes/ALIEN2.wad',0
                          even
ptr1n:
                          dc.b           'disk/includes/ALIEN2.ptr',0
                          even
wad2n:
                          dc.b           'disk/includes/PICKUPS.wad',0
                          even
ptr2n:
                          dc.b           'disk/includes/PICKUPS.ptr',0
                          even

*************************************************************************                   
; Missing ugly monster
;wad3n:
;                   dc.b                   'disk/includes/uglymonster.wad',0
;                   even
;ptr3n:
;                   dc.b                   'disk/includes/uglymonster.ptr',0
;                   even
*************************************************************************

wad4n:
                          dc.b           'disk/includes/flyingalien.wad',0
                          even
ptr4n:
                          dc.b           'disk/includes/flyingalien.ptr',0
                          even
wad5n:
                          dc.b           'disk/includes/keys.wad',0
                          even
ptr5n:
                          dc.b           'disk/includes/keys.ptr',0
                          even
wad6n:
                          dc.b           'disk/includes/rockets.wad',0
                          even
ptr6n:
                          dc.b           'disk/includes/rockets.ptr',0
                          even
wad7n:
                          dc.b           'disk/includes/barrel.wad',0
                          even
ptr7n:
                          dc.b           'disk/includes/barrel.ptr',0
                          even
wad8n:
                          dc.b           'disk/includes/bigbullet.wad',0
                          even
ptr8n:
                          dc.b           'disk/includes/bigbullet.ptr',0
                          even
wad9n:
                          dc.b           'disk/includes/newgunsinhand.wad',0
                          even
ptr9n:
                          dc.b           'disk/includes/newgunsinhand.ptr',0
                          even
wadan:
                          dc.b           'disk/includes/newmarine.wad',0
                          even
ptran:
                          dc.b           'disk/includes/newmarine.ptr',0
                          even
wadbn:
                          dc.b           'disk/includes/lamps.wad',0
                          even
ptrbn:
                          dc.b           'disk/includes/lamps.ptr',0
                          even
wadcn:
                          dc.b           'disk/includes/worm.wad',0
                          even
ptrcn:
                          dc.b           'disk/includes/worm.ptr',0
                          even
waddn:
                          dc.b           'disk/includes/explosion.wad',0
                          even
ptrdn:
                          dc.b           'disk/includes/explosion.ptr',0
                          even
waden:
                          dc.b           'disk/includes/bigclaws.wad',0
                          even
ptren:
                          dc.b           'disk/includes/bigclaws.ptr',0
                          even
wadfn:
                          dc.b           'disk/includes/tree.wad',0
ptrfn:
                          dc.b           'disk/includes/tree.ptr',0
                          even

*********************************************************************************************

OBJ_ADDRS:                ds.l           80

*********************************************************************************************

blocklen:                 dc.l           0
blockname:                dc.l           0
blockstart:               dc.l           0

********************************************************************************************* 

BOTPICNAME:               dc.b           'disk/includes/panelraw',0
                          even
PanelLen:                 dc.l           0

*********************************************************************************************
; Lower key panel picture

ReleasePanelMemory:

                          move.l         Panel,d1
                          move.l         d1,a1
                          move.l         PanelLen,d0
                          move.l         4.w,a6
                          jsr            _LVOFreeMem(a6)
                          rts

*********************************************************************************************
; Lower key panel picture

LoadPanel:

                          move.l         #BOTPICNAME,blockname

                          move.l         doslib,a6
                          move.l         blockname,d1
                          move.l         #1005,d2
                          jsr            _LVOOpen(a6)
                          move.l         d0,handle
 
                          lea            fib,a5
                          move.l         handle,d1
                          move.l         a5,d2
                          jsr            _LVOExamineFH(a6)
 
                          move.l         fib_Size(a5),blocklen
                          move.l         #PanelSize,PanelLen
 
                          move.l         #MEMF_CHIP|MEMF_CLEAR,d1
                          move.l         4.w,a6
                          move.l         PanelLen,d0
                          jsr            _LVOAllocMem(a6)
                          move.l         d0,blockstart

                          move.l         doslib,a6
                          move.l         handle,d1
                          move.l         LEVELDATA,d2
                          move.l         blocklen,d3
                          jsr            _LVORead(a6)

                          move.l         doslib,a6
                          move.l         handle,d1
                          jsr            _LVOClose(a6)
 
                          move.l         blockstart,Panel
 
                          move.l         LEVELDATA,d0
                          moveq          #0,d1
                          move.l         Panel,a0
                          lea            WorkSpace,a1
                          suba.l         a2,a2
                          jsr            UnLHA

                          rts

*********************************************************************************************

LoadObjects:

                          move.l         #OBJ_ADDRS,a2
                          move.l         #OBJ_NAMES,a0

                          move.l         #Objects,a1
                          bsr            LoadAnObj
                          move.l         blockstart,(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,16(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,16+4(a1)

*************************************************************************
; Missing ugly monster
;                   bsr                    LoadAnObj
;                   move.l                 blockstart,(16*3)(a1)
;                   bsr                    LoadAnObj
;                   move.l                 blockstart,(16*3)+4(a1)
*************************************************************************

                          bsr            LoadAnObj
                          move.l         blockstart,(16*4)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*4)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*5)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*5)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*6)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*6)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*7)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*7)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*2)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*2)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*9)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*9)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*10)(a1)
                          move.l         blockstart,(16*16)(a1)
                          move.l         blockstart,(16*17)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*10)+4(a1)
                          move.l         blockstart,(16*16)+4(a1)
                          move.l         blockstart,(16*17)+4(a1)

*************************************************************************
; load big monster here
*************************************************************************

                          bsr            LoadAnObj
                          move.l         blockstart,(16*12)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*12)+4(a1) 

                          bsr            LoadAnObj
                          move.l         blockstart,(16*13)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*13)+4(a1) 

                          bsr            LoadAnObj
                          move.l         blockstart,(16*8)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*8)+4(a1)

                          bsr            LoadAnObj
                          move.l         blockstart,(16*14)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*14)+4(a1) 

                          bsr            LoadAnObj
                          move.l         blockstart,(16*15)(a1)
                          bsr            LoadAnObj
                          move.l         blockstart,(16*15)+4(a1) 


*************************************************************************
; Just for charles
                    ; move.l doslib,a6
                    ; move.l #TESTNAME,d1
                    ; move.l #1005,d2
                    ; jsr -30(a6)
                    ; move.l d0,handle
                    ;
                    ; move.l handle,d1
                    ; move.l #Spider_des,d2
                    ; move.l #100000,d3
                    ; jsr -42(a6)
                    ; move.l doslib,a6
                    ; move.l handle,d1
                    ; jsr -36(a6)
************************************************************************* 

                          rts
 
 *************************************************************************
;TESTNAME: dc.b 'data/TESTOBJ'
; dc.b 0
; even
*************************************************************************

*********************************************************************************************

                          CNOP           0,4
fib:                      ds.l           75

*********************************************************************************************

LoadAnObj:
                          movem.l        a0/a1/a2,-(a7)
 
                          move.l         (a0),blockname
 
                          move.l         doslib,a6
                          move.l         blockname,d1
                          move.l         #1005,d2
                          jsr            _LVOOpen(a6)
                          move.l         d0,handle
 
                          lea            fib,a5
                          move.l         handle,d1
                          move.l         a5,d2
                          jsr            _LVOExamineFH(a6)
 
                          move.l         fib_Size(a5),blocklen
 
                          move.l         #MEMF_FAST|MEMF_CLEAR,d1
                          move.l         4.w,a6
                          move.l         blocklen,d0
                          jsr            _LVOAllocMem(a6)
                          move.l         d0,blockstart

                          move.l         doslib,a6
                          move.l         handle,d1
                          move.l         blockstart,d2
                          move.l         blocklen,d3
                          jsr            _LVORead(a6)
                      
                          move.l         doslib,a6
                          move.l         handle,d1
                          jsr            _LVOClose(a6)

                          movem.l        (a7)+,a0/a1/a2
 
                          move.l         blockstart,(a2)+
                          move.l         blocklen,(a2)+
                          addq           #4,a0

                          rts

*********************************************************************************************

ReleaseObjectMemory:

                          move.l         #OBJ_NAMES,a0
                          move.l         #OBJ_ADDRS,a2

relobjlop:
                          move.l         (a2)+,blockstart
                          move.l         (a2)+,blocklen
                          addq           #8,a0
                          tst.l          blockstart
                          ble.s          nomoreovj
 
                          movem.l        a0/a2,-(a7)
 
                          move.l         blockstart,d1
                          move.l         d1,a1
                          move.l         blocklen,d0
                          move.l         4.w,a6
                          jsr            _LVOFreeMem(a6)
 
                          movem.l        (a7)+,a0/a2
                          bra.s          relobjlop
 
nomoreovj:

                          rts

*********************************************************************************************
 
LoadSFX:

                          move.l         #SFX_NAMES,a0
                          move.l         #SampleList,a1

loadSamps:
                          move.l         (a0)+,a2
                          move.l         a2,d0
                          tst.l          d0
                          bgt.s          oktoload
                          blt.s          doneload

                          addq           #4,a0
                          addq           #8,a1
                          bra            loadSamps

doneload:
                          move.l         #-1,(a1)+
                          rts
                      
oktoload:
                          move.l         (a0)+,blocklen
                          move.l         a2,blockname
                          movem.l        a0/a1,-(a7)

                          move.l         #MEMF_CHIP|MEMF_CLEAR,d1
                          move.l         4.w,a6
                          move.l         blocklen,d0
                          jsr            _LVOAllocMem(a6)
                          move.l         d0,blockstart

                          move.l         doslib,a6
                          move.l         blockname,d1
                          move.l         #1005,d2
                          jsr            _LVOOpen(a6)

                          move.l         doslib,a6
                          move.l         d0,handle
                          move.l         d0,d1
                          move.l         blockstart,d2
                          move.l         blocklen,d3
                          jsr            _LVORead(a6)

                          move.l         doslib,a6
                          move.l         handle,d1
                          jsr            _LVOClose(a6)

                          movem.l        (a7)+,a0/a1
                          move.l         blockstart,d0
                          move.l         d0,(a1)+
                          add.l          blocklen,d0
                          move.l         d0,(a1)+
                          bra            loadSamps

*********************************************************************************************

LoadFloor:

                          move.l         #FloorTileSize,d0
                          move.l         #MEMF_FAST|MEMF_CLEAR,d1
                          move.l         4.w,a6
                          jsr            _LVOAllocMem(a6)
                          move.l         d0,floortile

                          move.l         #floortilename,d1
                          move.l         #1005,d2
                          move.l         doslib,a6
                          jsr            _LVOOpen(a6)

                          move.l         doslib,a6
                          move.l         d0,handle
                          move.l         d0,d1
                          move.l         floortile,d2
                          move.l         #FloorTileSize,d3
                          jsr            _LVORead(a6)

                          move.l         doslib,a6
                          move.l         handle,d1
                          jsr            _LVOClose(a6)
 
                          rts

 *********************************************************************************************
 
floortilename:            dc.b           'disk/includes/floortile',0
                          even

*********************************************************************************************
; Load saved levels

LoadPasswords:

                          move.l         doslib,a6
                          move.l         #levelFile,d1
                          move.l         #MODE_OLDFILE,d2
                          jsr            _LVOOpen(a6)
                          tst.l          d0
                          beq            .levelFileNotFound

                          move.l         doslib,a6
                          move.l         d0,handle
                          move.l         d0,d1
                          move.l         #PasswordStorage,d2
                          move.l         #17*16,d3
                          jsr            _LVORead(a6)

                          move.l         doslib,a6
                          move.l         handle,d1
                          jsr            _LVOClose(a6)

.levelFileNotFound:
                          rts

*********************************************************************************************
; Load saved levels

SavePasswords:

                          move.l         doslib,a6
                          move.l         #levelFile,d1
                          move.l         #MODE_READWRITE,d2
                          jsr            _LVOOpen(a6)
                          tst.l          d0
                          beq            .fileError

                          move.l         doslib,a6
                          move.l         d0,handle
                          move.l         d0,d1
                          move.l         #PasswordStorage,d2
                          move.l         #17*16,d3
                          jsr            _LVOWrite(a6)

                          move.l         doslib,a6
                          move.l         handle,d1
                          jsr            _LVOClose(a6)

                          .fileError:
                          rts

*********************************************************************************************

levelFile:                dc.b           'savegame',0
                          even

*********************************************************************************************

ReleaseSampleMemory:

                          move.l         #SampleList,a0

.relmem:
                          move.l         (a0)+,d1
                          bge.s          .okrel
                          rts

.okrel:
                          move.l         (a0)+,d0
                          sub.l          d1,d0
                          move.l         d1,a1
                          move.l         4.w,a6
                          move.l         a0,-(a7)
                          jsr            _LVOFreeMem(a6)
                          move.l         (a7)+,a0
                          bra            .relmem

*********************************************************************************************

ReleaseFloorMemory:

                          move.l         floortile,d1
                          beq            SkipFloorTile

                          move.l         d1,a1
                          move.l         #FloorTileSize,d0
                          move.l         4.w,a6
                          jsr            _LVOFreeMem(a6)
                          move.l         #0,floortile

SkipFloorTile:
                          rts
 
*********************************************************************************************

UnLHA:
; D0 = Source pointer
; A0 = Destination memory pointer
; A1 = 16K Workspace
; A2 = 65K Workspace
; D1 = Pointer to list of the form:
;
;   LONG <offset>
;   LONG <length>
;
; NB: Terminated by _two_ zero longwords.
;
; (If D1 = 0 then the entire source file is decompressed).

                          incbin         "data/code/Decomp4.bin"

*********************************************************************************************
