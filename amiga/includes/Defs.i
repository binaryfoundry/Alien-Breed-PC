******************************************************************

  IFND    defs_i

defs_i              EQU 1

******************************************************************
; Object constants

ObjectSize          equ 64 ; bytes

******************************************************************
; Object numbers (offset 16)

objNbrDead          equ -1
objNbrAlien         equ 0
objNbrMedikit       equ 1
objNbrBullet        equ 2
objNbrBigGun        equ 3
objNbrKey           equ 4
objNbrPlr1          equ 5 ; Marine
objNbrRobot         equ 6
objNbrBigNasty      equ 7 ; (?)
objNbrFlyingNasty   equ 8
objNbrAmmo          equ 9
objNbrBarrel        equ 10
objNbrPlr2          equ 11
objNbrMarine        equ 12
objNbrWorm          equ 13
objNbrHugeRedThing  equ 14 ; WellHard
objNbrSmallRedThing equ 15    
objNbrTree          equ 16
objNbrEyeBall       equ 17
objNbrToughMarine   equ 18
objNbrFlameMarine   equ 19 ; Shot gun marine
objNbrGasPipe       equ 20

******************************************************************
; Generic object definitions 

objCollisionId      equ 0 ; .w
objIdentifierNbr    equ 1 ; .b 
objUnknown2         equ 2 ; .w :: ie. -30
objUnknown4         equ 4 ; .w :: Object Y?
objunknown6         equ 6 ; .b :: ie. $2020 / $ff = Vector object
objunknown7         equ 7 ; .b :: ie. $2020
objDeadFrameH       equ 8 ; .w :: ie. $50003 / e = ?, 10 = ?, 8 = Exploding
objDeadFrameL       equ 10 ; .w :: ie. 0 = ? / 9 = OnFloorDead
objZone             equ 12 ; .w : -1 = not exists
objUnknown14        equ 14 ; .w :: ie. $1010 / $2020 / 64*256+64
objNumber           equ 16 ; .b :: ie. 4
objCanSee           equ 17 ; .b : %1 = Plr2, %10 = Plr1 :: ie. %1000 

objWorry            EQU 62 ; .b 
objInTop            EQU 63 ; .b

******************************************************************
; - Bullet object definitions 

shotxvel            EQU 18 ; .w
shotzvel            EQU 22 ; .w

shotpower           EQU 28 ; .b (.w?)
unknownB9           EQU 29 ; .b
shotstatus          EQU 30 ; .b
shotsize            EQU 31 ; .b

shotyvel            EQU 42 ; .w
accypos             EQU 44 ; .l
shotanim            EQU 52 ; .b (.w?)
unknownB29          EQU 53 ; .b
shotgrav            EQU 54 ; .w
shotimpact          EQU 56 ; .w?
shotlife            EQU 58 ; .w
shotflags           EQU 60 ; .w

******************************************************************
; - Nasty definitions

numlives            equ 18
damagetaken         equ 19
maxspd              equ 20
currspd             equ 22
targheight          equ 24

GraphicRoom         equ 26
CurrCPt             Equ 28

Facing              equ 30
Lead                equ 32
ObjTimer            equ 34
EnemyFlags          equ 36 ; .l : (lw)
SecTimer            equ 40
ImpactX             equ 42
ImpactZ             equ 44
ImpactY             equ 46
objyvel             EQU 48
TurnSpeed           EQU 50
ThirdTimer          EQU 52
FourthTimer         EQU 54

******************************************************************
; Vector object definitions

objVectUnknown0     equ 0 ; .w
objVectBright       equ 2 ; .w
objVectUnknown4     equ 4 ; .w
objVectUnknown6     equ 6 ; .w
objVectNumber       equ 8 ; .w
objVectFrameNumber  equ 10 ; .w

objVectFacing       equ 30 ; .w

******************************************************************
; Door Definitions 

DR_Plr_SPC          EQU 0
DR_Plr              EQU 1
DR_Bul              EQU 2
DR_Alien            EQU 3
DR_Timeout          EQU 4
DR_Never            EQU 5

DL_Timeout          EQU 0
DL_Never            EQU 1

******************************************************************
; Data Offset Defs 

ToZoneFloor         EQU 2
ToZoneRoof          EQU 6
ToUpperFloor        EQU 10
ToUpperRoof         EQU 14
ToZoneWater         EQU 18
ToZoneBrightness    EQU 22
ToUpperBrightness   EQU 24
ToZoneCpt           EQU 26
ToWallList          EQU 28
ToExitList          EQU 32
ToZonePts           EQU 34
ToBack              EQU 36
ToTelZone           EQU 38
ToTelX              EQU 40
ToTelZ              EQU 42
ToFloorNoise        EQU 44
ToUpperFloorNoise   EQU 46
ToListOfGraph       EQU 48

******************************************************************
; Graphics definitions 

KeyGraph0           EQU 256*65536*19
KeyGraph1           EQU 256*65536*19+32
KeyGraph2           EQU (256*19+128)*65536
KeyGraph3           EQU (256*19+128)*65536+32
Nas1ClosedMouth     EQU 256*5*65536
MediKit_Graph       EQU 256*10*65536
BigGun_Graph        EQU 256*10*65536+32

  ENDC     