*********************************************************************************************

                          opt           P=68020

*********************************************************************************************

                          incdir        "includes"
                          include       "AB3DI.i"
                          include       "macros.i"

*********************************************************************************************

                          ifnd          ENABLEFACES
ENABLEFACES equ 0
                          endc

*********************************************************************************************

Flash:
; D0=number of a zone
; D1=brightness change

                          cmp.w         #-20,d1
                          bgt.s         .okflash
                          move.w        #-20,d1

.okflash:
                          movem.l       d0/a0/a1,-(a7)

                          move.l        #currentPointBrights,a1

                          move.l        zoneAdds,a0
                          move.l        (a0,d0.w*4),a0
                          add.l         LEVELDATA,a0
 
                          move.l        a0,-(a7)
                          add.w         ToZonePts(a0),a0

flashpts:
                          move.w        (a0)+,d2
                          blt.s         flashedall

                          add.w         d1,(a1,d2.w*4)
                          add.w         d1,2(a1,d2.w*4)
                          bra           flashpts

flashedall:
                          move.l        (a7)+,a0

                          move.l        #zoneBrightTable,a1
                          add.w         d1,(a1,d0.w*4)
                          add.w         d1,2(a1,d0.w*4)

                          add.l         #ToListOfGraph,a0

doemall:
                          move.w        (a0),d0
                          blt.s         doneemall

                          add.w         d1,(a1,d0.w*4)
                          add.w         d1,2(a1,d0.w*4)
                          addq          #8,a0
                          bra.s         doemall

doneemall:
                          movem.l       (a7)+,d0/a0/a1
                          rts

*********************************************************************************************

radius:                   dc.w          0

*********************************************************************************************

ExplodeIntoBits:
; d0=
; d2=
; d3=radius

                          move.w        d3,radius

                          cmp.w         #7,d2
                          ble.s         .oksplut
                          move.w        #7,d2

.oksplut:
                          move.l        NastyShotData,a5
                          move.w        #19,d1

.findeight:
                          move.w        objZone(a5),d0
                          blt.s         .gotonehere

                          adda.w        #ObjectSize,a5
                          dbra          d1,.findeight
                          rts
 
.gotonehere:
                          move.b        #0,damagetaken(a5)
                          move.b        #0,numlives(a5)

                          move.l        ObjectPoints,a2
                          move.w        (a5),d3
                          lea           (a2,d3.w*8),a2

****************************************************
                    ; jsr GetRand
                    ; lsr.w #4,d0
                    ; move.w radius,d1
                    ; and.w d1,d0
                    ; asr.w #1,d1
                    ; sub.w d1,d0
****************************************************

                          move.w        newx,d0
                          move.w        d0,(a2)

****************************************************
                    ; jsr GetRand
                    ; lsr.w #4,d0
                    ; move.w radius,d1
                    ; and.w d1,d0
                    ; asr.w #1,d1
                    ; sub.w d1,d0
****************************************************

                          move.w        newz,d0
                          move.w        d0,4(a2)

                          jsr           GetRand
                          and.w         #8190,d0
                          move.l        #SineTable,a2
                          adda.w        d0,a2
                          move.w        (a2),d3
                          move.w        2048(a2),d4
                          jsr           GetRand
                          and.w         #3,d0
                          add.w         #1,d0
                          ext.l         d3
                          ext.l         d4
                          asl.l         d0,d3
                          asl.l         d0,d4
                          move.l        ImpactX(a0),d0
                          swap          d4
                          asr.w         #1,d0
                          add.w         d0,d4
                          swap          d0
                          move.w        d4,shotzvel(a5)
                          swap          d3
                          asr.w         #1,d0
                          add.w         d0,d3
                          move.w        d3,shotxvel(a5)
                          jsr           GetRand
                          and.w         #1023,d0
                          add.w         #2*128,d0
                          neg.w         d0
                          move.w        d0,shotyvel(a5)
                          move.l        #0,EnemyFlags(a5)
                          move.w        objZone(a0),objZone(a5)
 
 ****************************************************
                    ; jsr GetRand
                    ; lsr.w #4,d0
                    ; move.w radius,d1
                    ; and.w d1,d0
                    ; asr.w #1,d1
                    ; sub.w d1,d0
****************************************************

                          move.w        4(a0),d0
                          add.w         #6,d0
                          ext.l         d0
                          asl.l         #7,d0
 
                          move.l        d0,accypos(a5)
                          move.w        d2,d0
                          and.w         #3,d0
                          add.w         #50,d0
                          move.b        d0,shotsize(a5)
                          move.w        #40,shotgrav(a5)
                          move.w        #0,shotflags(a5)
                          move.w        #-1,shotlife(a5)
                          move.b        #2,16(a5)
                          clr.b         shotstatus(a5)
                          move.b        objInTop(a0),objInTop(a5)
                          st            objWorry(a0)
                          adda.w        #64,a5
                          sub.w         #1,d2
                          blt.s         .gotemall
                          dbra          d1,.findeight

.gotemall:
                          rts

*********************************************************************************************

BrightAnimHandler:

                          move.l        #brightAnimTable,a1
                          move.l        #brightAnimPtrs,a3
                          move.l        #brightAnimStarts,a4

doBrightAnims:
                          move.l        (a3),d0
                          blt           noMoreAnims

                          move.l        d0,a2
                          move.w        (a2)+,d0
                          cmp.w         #999,d0
                          bne.s         itsABright

                          move.l        (a4),a2
                          move.w        (a2)+,d0

itsABright:
                          move.l        a2,(a3)+
                          addq          #4,a4
                          move.w        d0,(a1)+
                          bra.s         doBrightAnims

noMoreAnims:
                          rts
 
*********************************************************************************************

brightAnimTable:          ds.w          20

brightAnimPtrs:
                          dc.l          pulseANIM
                          dc.l          flickerANIM
                          dc.l          fireFlickerANIM
                          dc.l          -1

*********************************************************************************************

brightAnimStarts:
                          dc.l          pulseANIM
                          dc.l          flickerANIM
                          dc.l          fireFlickerANIM

*********************************************************************************************

pulseANIM:
                          dc.w          -10,-10,-9,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10
                          dc.w          10,9,8,7,6,5,4,3,2,1,0,-1,-2,-3,-4,-5,-6,-7,-8,-9
                          dc.w          999

*********************************************************************************************

flickerANIM:
                          dcb.w         20,10
                          dc.w          -10
                          dcb.w         30,10
                          dc.w          -10
                          dcb.w         5,10
                          dc.w          -10
                          dc.w          999

*********************************************************************************************

fireFlickerANIM:
                          dc.w          -10,-9,-6,-10,-6,-5,-5,-7,-5,-10,-9,-8,-7,-5,-5,-5,-5
                          dc.w          -5,-5,-5,-5,-6,-7,-8,-9,-5,-10,-9,-10,-6,-5,-5,-5,-5,-5
                          dc.w          -5,-5
                          dc.w          999

*********************************************************************************************

objvels:                  ds.l          8

*********************************************************************************************

FramesToDraw:             dc.w          0
TempFrames:               dc.w          0

*********************************************************************************************

ObjMoveAnim:

                          move.l        PLR1_Roompt,a0
                          move.w        (a0),PLR1_Zone
                   
                          move.l        PLR2_Roompt,a0
                          move.w        (a0),PLR2_Zone

                          bsr           Player1Shot
                          bsr           Player2Shot

                          bsr           SwitchRoutine
                          bsr           DoorRoutine
                          bsr           LiftRoutine

                          bsr           ObjectDataHandler
                          bsr           BrightAnimHandler
 
                          subq.w        #1,animTimer
                          bgt.s         notzero
                          move.w        #2,animTimer

                          move.l        otherrip,d0
                          move.l        RipTear,otherrip
                          move.l        d0,RipTear

notzero:
                          rts
 
*********************************************************************************************

liftheighttab:            ds.w          40
doorheighttab:            ds.w          40

PLR1_stoodonlift:         dc.b          0
PLR2_stoodonlift:         dc.b          0

liftattop:                dc.b          0
liftatbot:                dc.b          0

zoneBrightTable:          ds.l          300

*********************************************************************************************

DoWaterAnims:
; a0=LiftData

                          move.w        #20,d0

waterAnimLop:
                          move.l        (a0)+,d1
                          move.l        (a0)+,d2
                          move.l        (a0),d3
                          move.w        4(a0),d4
                          move.w        d4,d5
                          muls          TempFrames,d5
                          add.l         d5,d3
                          cmp.l         d1,d3
                          bgt.s         waterNotAtTop
 
                          move.l        d1,d3
                          move.w        #128,d4
                          bra           waterDone
 
waterNotAtTop:
                          cmp.l         d2,d3
                          blt.s         waterDone
 
                          move.l        d2,d3
                          move.w        #-128,d4

waterDone:
                          move.l        d3,(a0)+
                          move.w        d4,(a0)+
                          move.l        d3,d1

moreZones:
                          move.w        (a0)+,d2
                          bge.s         okZone
  
                          dbra          d0,waterAnimLop
                          rts

okZone:
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          move.l        d1,d3
                          asr.l         #6,d3
                          move.w        d3,2(a1)
                          move.l        zoneAdds,a1
                          move.l        (a1,d2.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        d1,ToZoneWater(a1)

                          bra.s         moreZones
                          rts

*********************************************************************************************

LiftRoutine:

                          move.l        LiftData,a0
                          move.l        #liftheighttab,a6
 
doalift:
                          move.w        (a0)+,d0                                                        ; bottom of lift movement
                          cmp.w         #999,d0
                          bne           notallliftsdone
                          move.w        #999,(a6)
 
                          bsr           DoWaterAnims
                          rts
 
notallliftsdone:
                          move.w        (a0)+,d1                                                        ; top of lift movement.
 
                          move.w        (a0),d3
                          move.w        d3,(a6)+
                          move.w        2(a0),d2
                          move.w        d2,d7
                          muls          TempFrames,d2
                          add.w         d2,d3
                          move.w        2(a0),d2
                          cmp.w         d3,d0
                          sle           liftatbot
                          bgt.s         .nolower
                          moveq         #0,d2
                          move.w        d0,d3

.nolower:
                          cmp.w         d3,d1
                          sge           liftattop
                          blt.s         .noraise
                          moveq         #0,d2
                          move.w        d1,d3

.noraise:
                          sub.w         d3,d0
                          cmp.w         #15*16,d0
                          slt           d6

                          move.w        d3,(a0)+
                          move.l        a0,a5
                          move.w        d2,(a0)+
                          move.w        d2,d7
 
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          asr.w         #2,d3
                          move.w        d3,d0
                          asl.w         #2,d0
                          move.w        d0,2(a1)
                          move.w        d3,d0
                          muls          #256,d3
                          move.w        (a0)+,d5
                          move.l        zoneAdds,a1
                          move.l        (a1,d5.w*4),a1
                          add.l         LEVELDATA,a1
                          move.w        (a1),d5
                          move.l        PLR1_Roompt,a3
                          move.l        d3,2(a1)
                          neg.w         d0
 
                          cmp.w         (a3),d5
                          seq           PLR1_stoodonlift
                          move.l        PLR2_Roompt,a3
                          cmp.w         (a3),d5
                          seq           PLR2_stoodonlift
 
                          move.w        (a0)+,d2                                                        ; conditions
                          and.w         Conditions,d2
                          cmp.w         -2(a0),d2
                          beq.s         .satisfied 
 
                          move.w        (a0)+,d5
 
.dothesimplething:
                          move.l        FloorLines,a3

.simplecheck:
                          move.w        (a0)+,d5
                          blt           nomoreliftwalls
                          asl.w         #4,d5
                          lea           (a3,d5.w),a4
                          move.w        #0,14(a4)
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          move.l        (a0)+,a2
                          adda.w        d0,a2
                          move.l        a2,10(a1)
                          move.l        d3,20(a1)
                          bra.s         .simplecheck
                          bra           nomoreliftwalls 
 
.satisfied:
                          move.l        FloorLines,a3
                          moveq         #0,d4
                          moveq         #0,d5
                          move.b        (a0)+,d4
                          move.b        (a0)+,d5
                          tst.b         liftattop
                          bne           tstliftlower
                          tst.b         liftatbot
                          bne           tstliftraise
                          move.w        #0,d1
 
backfromlift:
                          and.w         #255,d0

liftwalls:
                          move.w        (a0)+,d5
                          blt           nomoreliftwalls

                          asl.w         #4,d5
                          lea           (a3,d5.w),a4
                          move.w        14(a4),d4
                          move.w        #$8000,14(a4)
                          and.w         d1,d4
                          beq.s         .nothinghit
                          move.w        d7,(a5)
                          move.w        #0,Noisex
                          move.w        #0,Noisez
                          move.w        #50,Noisevol
                          move.w        #5,Samplenum
                          move.b        #1,chanpick
                          st            notifplaying
                          move.b        #$fe,IDNUM
                          movem.l       a0/a3/a4/d0/d1/d2/d3/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a3/a4/d0/d1/d2/d3/d6/d7
.nothinghit:
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          move.l        (a0)+,a2
                          adda.w        d0,a2
                          move.l        a2,10(a1)
                          move.l        d3,20(a1)
                          bra           liftwalls
 
nomoreliftwalls 
                          bra           doalift
                          rts
 
tstliftlower:
                          cmp.b         #1,d5
                          blt.s         lift0
                          beq.s         lift1
                          cmp.b         #3,d5
                          blt.s         lift2
                          beq.s         lift3

lift0:
                          moveq         #0,d1
                          tst.b         p1_spctap
                          beq.s         .noplr1
                          move.w        #%100000000,d1
                          move.w        #4,d7
                          tst.b         PLR1_stoodonlift
                          beq.s         .noplr1
                          move.w        #$8000,d1
                          bra           backfromlift
 
.noplr1:
                          tst.b         p2_spctap
                          beq.s         .noplr2
                          or.w          #%100000000000,d1
                          move.w        #4,d7
                          tst.b         PLR2_stoodonlift
                          beq.s         .noplr2
                          move.w        #$8000,d1
                          bra           backfromlift
 
.noplr2:
                          bra           backfromlift

lift1:
                          move.w        #4,d7
                          tst.b         PLR1_stoodonlift
                          bne.s         lift1b
                          tst.b         PLR2_stoodonlift
                          bne.s         lift1b
                          move.w        #%100100000000,d1
                          bra           backfromlift

lift1b:
                          move.w        #$8000,d1
                          bra           backfromlift
 
lift2:
                          move.w        #$8000,d1
                          move.w        #4,d7
                          bra           backfromlift

lift3:
                          move.w        #$0,d1
                          bra           backfromlift

tstliftraise:
                          cmp.b         #1,d4
                          blt.s         rlift0
                          beq.s         rlift1
                          cmp.b         #3,d4
                          blt.s         rlift2
                          beq.s         rlift3

rlift0:
                          moveq         #0,d1
                          tst.b         p1_spctap
                          beq.s         .noplr1
                          move.w        #%100000000,d1
                          move.w        #-4,d7
                          tst.b         PLR1_stoodonlift
                          beq.s         .noplr1
                          move.w        #$8000,d1
                          bra           backfromlift
 
.noplr1:
                          tst.b         p2_spctap
                          beq.s         .noplr2
                          or.w          #%100000000000,d1
                          move.w        #-4,d7
                          tst.b         PLR2_stoodonlift
                          beq.s         .noplr2
                          move.w        #$8000,d1
                          bra           backfromlift
 
.noplr2:
                          bra           backfromlift

rlift1:
                          move.w        #-4,d7
                          tst.b         PLR1_stoodonlift
                          bne.s         rlift1b
                          tst.b         PLR2_stoodonlift
                          bne.s         rlift1b
                          move.w        #%100100000000,d1
                          bra           backfromlift

rlift1b:
                          move.w        #$8000,d1
                          bra           backfromlift

rlift2:
                          move.w        #$8000,d1
                          move.w        #-4,d7
                          bra           backfromlift

rlift3:
                          move.w        #$0,d1
                          bra           backfromlift

*********************************************************************************************

animTimer:                dc.w          2
  
doorDir:                  dc.w          -1
doorPos:                  dc.w          -9

doorOpen:                 dc.b          0
doorClosed:               dc.b          0 
                          even 

*********************************************************************************************

DoorRoutine:

                          move.l        #doorheighttab,a6
                          move.l        DoorData,a0
 
doadoor: 
                          move.w        (a0)+,d0                                                        ; bottom of door movement
                          cmp.w         #999,d0
                          bne           notalldoorsdone
                          move.w        #999,(a6)+
                          rts

notalldoorsdone:
                          move.w        (a0)+,d1                                                        ; top of door movement.
 
                          move.w        (a0),d3
                          move.w        d3,(a6)+
                          move.w        2(a0),d2
                          muls          TempFrames,d2
                          add.w         d2,d3
                          move.w        2(a0),d2
                          cmp.w         d3,d0
                          sle           doorClosed
                          bgt.s         nolower

                          moveq         #0,d2

nolower:
                          cmp.w         d3,d1
                          sge           doorOpen
                          blt.s         noraise
                          moveq         #0,d2
                          move.w        d1,d3

noraise:
                          sub.w         d3,d0
                          cmp.w         #15*16,d0
                          sge           d6

                          move.w        d3,(a0)+
                          move.l        a0,a5
                          move.w        d2,(a0)+
                          move.w        d2,d7
 
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          asr.w         #2,d3
                          move.w        d3,d0
                          asl.w         #2,d0
                          move.w        d0,2(a1)
                          move.w        d3,d0
                          muls          #256,d3
                          move.l        zoneAdds,a1
                          move.w        (a0)+,d5
 
                          move.l        (a1,d5.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        d3,6(a1)
                          neg.w         d0
                          and.w         #255,d0

****************************************************
                    ; add.w #64,d0
****************************************************

                          cmp.w         PLR1_Zone,d5
                          bne.s         NotGoBackUp
                          tst.b         doorOpen
                          bne.s         NotGoBackUp

                          tst.w         d2
                          blt.s         NotGoBackUp
                          move.w        #-16,d7
                          move.w        #$8000,d1
                          move.w        (a0)+,d2
                          move.w        (a0)+,d5
                          bra           backfromtst

NotGoBackUp:
                          move.w        (a0)+,d2                                                        ; conditions
                          and.w         Conditions,d2
                          cmp.w         -2(a0),d2
                          beq.s         satisfied 

                          move.w        (a0)+,d5

dothesimplething:
                          move.l        FloorLines,a3

simplecheck:
                          move.w        (a0)+,d5
                          blt           nomoredoorwalls
                          asl.w         #4,d5
                          lea           (a3,d5.w),a4
                          move.w        #0,14(a4)
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          move.l        (a0)+,a2
                          adda.w        d0,a2
                          move.l        a2,10(a1)
                          move.l        d3,24(a1)
                          bra.s         simplecheck
                          bra           nomoredoorwalls 
 
satisfied:
                          moveq         #0,d4
                          moveq         #0,d5
                          move.b        (a0)+,d5
                          move.b        (a0)+,d4

                          tst.b         doorOpen
                          bne           tstdoortoclose

                          tst.b         doorClosed
                          bne           tstdoortoopen

                          move.w        #$0,d1

backfromtst:
                          move.l        FloorLines,a3

doorwalls:
                          move.w        (a0)+,d5
                          blt.s         nomoredoorwalls

                          asl.w         #4,d5
                          lea           (a3,d5.w),a4
                          move.w        14(a4),d4
                          move.w        #$8000,14(a4)
                          and.w         d1,d4
                          beq.s         nothinghit
                          move.w        d7,(a5)
                          move.w        #0,Noisex
                          move.w        #0,Noisez
                          move.w        #50,Noisevol
                          move.w        #5,Samplenum
                          move.b        #1,chanpick
                          clr.b         notifplaying
                          move.b        #$fd,IDNUM
                          movem.l       a0/a3/d0/d1/d2/d3/d6,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a3/d0/d1/d2/d3/d6

nothinghit:
                          move.l        (a0)+,a1
                          add.l         LEVELGRAPHICS,a1
                          move.l        (a0)+,a2
                          adda.w        d0,a2
                          move.l        a2,10(a1)
                          move.l        d3,24(a1)
                          bra.s         doorwalls
 
nomoredoorwalls:
                          bra           doadoor
                          rts
 
****************************************************

tstdoortoopen:
                          cmp.w         #1,d5
                          blt.s         door0
                          beq.s         door1
                          cmp.w         #3,d5
                          blt.s         door2
                          beq.s         door3
                          cmp.w         #5,d5
                          blt.s         door4
                          beq.s         door5
 
door0:
                          move.w        #$0,d1
                          tst.b         p1_spctap
                          beq.s         .noplr1
                          move.w        #%100000000,d1

.noplr1:
                          tst.b         p2_spctap
                          beq.s         .noplr2
                          or.w          #%100000000000,d1
                   
.noplr2:
                          move.w        #-16,d7
                          bra           backfromtst

door1:
                          move.w        #%100100000000,d1
                          move.w        #-16,d7
                          bra           backfromtst

door2:
                          move.w        #%10000000000,d1
                          move.w        #-16,d7
                          bra           backfromtst

door3:
                          move.w        #%1000000000,d1
                          move.w        #-16,d7
                          bra           backfromtst

door4:
                          move.w        #$8000,d1
                          move.w        #-16,d7
                          bra           backfromtst
 
door5:
                          move.w        #$0,d1
                          bra           backfromtst
 
****************************************************

tstdoortoclose:
                          tst.w         d4
                          beq.s         dclose0
                          bra.s         dclose1

dclose0:
                          move.w        #4,d7
                          move.w        #$8000,d1
                          bra           backfromtst

dclose1:
                          move.w        #$0,d1
                          bra           backfromtst
 
****************************************************

SwitchRoutine:
                          move.l        SwitchData,a0
                          move.w        #7,d0
                          move.l        Points,a1

CheckSwitches:
                          tst.b         p1_spctap
                          bne           p1_SpaceIsPressed

backtop2
                          tst.b         p2_spctap
                          bne           p2_SpaceIsPressed

backtoend:
                          tst.b         2(a0)
                          beq           nobutt

                          tst.b         10(a0)
                          beq           nobutt
 
                          move.w        TempFrames,d1
                          add.w         d1,d1
                          add.w         d1,d1
                          sub.b         d1,3(a0)
                          bne           nobutt
 
                          move.b        #0,10(a0)
                          move.l        6(a0),a3
                          add.l         LEVELGRAPHICS,a3
                          move.w        #11,4(a3)
                          move.w        (a3),d3
                          and.w         #%00000111100,d3
                          move.w        d3,(a3)
                   
                          move.w        #7,d3
                          sub.w         d0,d3
                          addq          #4,d3
                          move.w        Conditions,d4
                          bclr          d3,d4
                          move.w        d4,Conditions

                          move.w        #0,Noisex
                          move.w        #0,Noisez
                          move.w        #50,Noisevol
                          move.w        #10,Samplenum
                          move.b        #1,chanpick
                          st            notifplaying
                          move.b        #$fc,IDNUM
                          movem.l       a0/a3/d0/d1/d2/d3/d6,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a3/d0/d1/d2/d3/d6

nobutt:
                          adda.w        #14,a0
                          dbra          d0,CheckSwitches
                          rts

p1_SpaceIsPressed:
                          move.w        p1_xoff,d1
                          move.w        p1_zoff,d2
                          move.w        (a0),d3
                          blt           .NotCloseEnough

                          move.w        4(a0),d3
                          lea           (a1,d3.w*4),a2
                          move.w        (a2),d3
                          add.w         4(a2),d3
                          asr.w         #1,d3
                          move.w        2(a2),d4
                          add.w         6(a2),d4
                          asr.w         #1,d4
                          sub.w         d1,d3
                          muls          d3,d3
                          sub.w         d2,d4
                          muls          d4,d4
                          add.l         d3,d4
                          cmp.l         #60*60,d4
                          bge           .NotCloseEnough

                          move.l        6(a0),a3
                          add.l         LEVELGRAPHICS,a3
                          move.w        #11,4(a3)
                          move.w        (a3),d3
                          and.w         #%00000111100,d3
                          not.b         10(a0)
                          beq.s         .switchoff
                          or.w          #2,d3

.switchoff: 
                          move.w        d3,(a3)
                          move.w        #7,d3
                          sub.w         d0,d3
                          addq          #4,d3
                          move.w        Conditions,d4
                          bchg          d3,d4
                          move.w        d4,Conditions

                          move.b        #0,3(a0)
                          move.w        #0,Noisex
                          move.w        #0,Noisez
                          move.w        #50,Noisevol
                          move.w        #10,Samplenum
                          move.b        #1,chanpick
                          st            notifplaying
                          move.b        #$fc,IDNUM
                          movem.l       a0/a3/d0/d1/d2/d3/d6,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a3/d0/d1/d2/d3/d6
 
.NotCloseEnough:
                          bra           backtop2

p2_SpaceIsPressed:
                          move.w        p2_xoff,d1
                          move.w        p2_zoff,d2
                          move.w        (a0),d3
                          blt           .NotCloseEnough

                          move.w        4(a0),d3
                          lea           (a1,d3.w*4),a2
                          move.w        (a2),d3
                          add.w         4(a2),d3
                          asr.w         #1,d3
                          move.w        2(a2),d4
                          add.w         6(a2),d4
                          asr.w         #1,d4
                          sub.w         d1,d3
                          muls          d3,d3
                          sub.w         d2,d4
                          muls          d4,d4
                          add.l         d3,d4
                          cmp.l         #60*60,d4
                          bge           .NotCloseEnough

                          move.l        6(a0),a3
                          add.l         LEVELGRAPHICS,a3
                          move.w        #11,4(a3)
                          move.w        (a3),d3
                          and.w         #%00000111100,d3
                          not.b         10(a0)
                          beq.s         .switchoff
                          or.w          #2,d3

.switchoff: 
                          move.w        d3,(a3)
                          move.w        #7,d3
                          sub.w         d0,d3
                          addq          #4,d3
                          move.w        Conditions,d4
                          bchg          d3,d4
                          move.w        d4,Conditions

                          movem.l       a0/a1/d0,-(a7)
                          move.w        #0,Noisex
                          move.w        #0,Noisez
                          move.w        #50,Noisevol
                          move.w        #10,Samplenum
                          move.b        #1,chanpick
                          st            notifplaying
                          move.b        #$fc,IDNUM
                          movem.l       a0/a3/d0/d1/d2/d3/d6,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a3/d0/d1/d2/d3/d6
                          movem.l       (a7)+,a0/a1/d0
 
.NotCloseEnough:
                          bra           backtoend

*********************************************************************************************
  
tempGotBigGun:            dc.w          0 
tempGunDamage:            dc.w          0
tempGunNoise:             dc.w          1
tempxoff:                 dc.w          0
tempzoff:                 dc.w          0
tempRoompt:               dc.l          0

PLR1_GotBigGun:           dc.w          0
PLR1_GunDamage:           dc.w          0
PLR1_GunNoise:            dc.w          0
PLR2_GotBigGun:           dc.w          0
PLR2_GunDamage:           dc.w          0
PLR2_GunNoise:            dc.w          0
bulyspd:                  dc.w          0 
closedist:                dc.w          0
 
PLR1_ObsInLine:
                          ds.b          400 
PLR2_ObsInLine:
                          ds.b          400 
 
rotcount:
                          dc.w          0
 
shotvels:                 ds.l          20

*********************************************************************************************

                          include       "PlayerShoot.s"

*********************************************************************************************

PLR1_GunFrame:            dc.w          0
PLR2_GunFrame:            dc.w          0

duh:                      dc.w          0
double:                   dc.w          0
ivescreamed:              dc.w          0

*********************************************************************************************
; Handle level object data

ObjectDataHandler:

                          move.l        ObjectData,a0

Objectloop:
                          tst.w         (a0)
                          blt           doneAllObj

                          move.w        objZone(a0),GraphicRoom(a0)

                          tst.b         objWorry(a0)
                          beq           dontWorryYourPrettyHead

                          move.b        objNumber(a0),d0                  
                          blt.s         doneObj
                          beq           JUMPNASTY

                          cmp.b         #2,d0
                          blt           JUMPMEDI
                          beq           JUMPBULLET

                          cmp.b         #4,d0
                          blt           JUMPGUN
                          beq           JUMPKEY

                          cmp.b         #6,d0
                          blt           doneObj                                                         ; 5 = Plr1
                          beq           JUMPROBOT

                          cmp.b         #8,d0
                          blt           doneObj                                                         ; 7 = Big Nasty Alien
                          beq           JUMPFLYINGNASTY

                          cmp.b         #10,d0
                          blt           JUMPAMMO
                          beq           JUMPBARREL

                          cmp.b         #12,d0
                          blt           doneObj                                                         ; 11 = Plr2
                          beq           JUMPMARINE

                          cmp.b         #14,d0
                          blt           JUMPWORM
                          beq           JUMPWELLHARD

                          cmp.b         #16,d0
                          beq           JUMPTREE

                          cmp.b         #18,d0
                          blt           JUMPEYEBALL
                          beq           JUMPTOUGHMARINE

                          cmp.b         #20,d0
                          blt           JUMPFLAMEMARINE
                          beq           JUMPGASPIPE

doneObj:
dontWorryYourPrettyHead:
                          adda.w        #ObjectSize,a0
                          bra           Objectloop

doneAllObj:
                          rts

*********************************************************
; Level object jump table

JUMPNASTY: 
                          jsr           ItsANasty                                                       ; 0
                          bra           doneObj

JUMPMEDI:
                          jsr           ItsAMediKit                                                     ; 1
                          bra           doneObj

JUMPBULLET:
                          jsr           ItsABullet                                                      ; 2
                          bra           doneObj

JUMPGUN:
                          jsr           ItsABigGun                                                      ; 3
                          bra           doneObj

JUMPKEY:
                          jsr           ItsAKey                                                         ; 4
                          bra           doneObj

; 5 - FIVE IS PLAYER 1

JUMPROBOT:
                          jsr           ItsARobot                                                       ; 6 
                          bra           doneObj
 
JUMPBIGNASTY: 
                          jsr           ItsABigNasty                                                    ; 7
                          bra           doneObj
 
JUMPFLYINGNASTY:
                          jsr           ItsAFlyingNasty                                                 ; 8
                          bra           doneObj


JUMPAMMO:
                          jsr           ItsAnAmmoClip                                                   ; 9
                          bra           doneObj


JUMPBARREL:
                          jsr           ItsABarrel                                                      ; 10
                          bra           doneObj

; 11 - ELEVEN IS PLAYER 2

JUMPMARINE:
                          jsr           ItsAMutantMarine                                                ; 12 - Marine
                          bra           doneObj

JUMPWORM:
                          jsr           ItsAHalfWorm                                                    ; 13
                          bra           doneObj

JUMPWELLHARD:
                          jsr           ItsABigRedThing                                                 ; 14
                          bra           doneObj

; 15 - Small Red Thing

JUMPTREE:
                          jsr           ItsATree                                                        ; 16
                          bra           doneObj

JUMPEYEBALL:
                          jsr           ItsAEyeBall                                                     ; 17
                          bra           doneObj

JUMPTOUGHMARINE:
                          jsr           ItsAToughMarine                                                 ; 18
                          bra           doneObj

JUMPFLAMEMARINE:
                          jsr           ItsAFlameMarine                                                 ; 19
                          bra           doneObj

JUMPGASPIPE:
                          jsr           ItsAGasPipe                                                     ; 20
                          bra           doneObj

*********************************************************************************************
*********************************************************************************************

ItsAGasPipe:
                          clr.b         objWorry(a0)
 
                          move.w        TempFrames,d0
                          tst.w         ThirdTimer(a0)
                          ble.s         maybeflame

                          sub.w         d0,ThirdTimer(a0)
                          move.w        #5,SecTimer(a0)
                          move.w        #10,FourthTimer(a0)
                          rts

maybeflame:
                          sub.w         d0,FourthTimer(a0)
                          blt.s         yesflame
                          rts

yesflame:
                          move.w        #10,FourthTimer(a0)
                          sub.w         #1,SecTimer(a0)
                          bgt.s         notdoneflame

                          move.w        ObjTimer(a0),ThirdTimer(a0)

notdoneflame:
                          cmp.w         #4,SecTimer(a0)
                          bne.s         .nowhoosh

                          SAVEREGS
                          move.l        #ObjRotated,a1
                          move.w        (a0),d0
                          lea           (a1,d0.w*8),a1
                          move.l        (a1),Noisex
                          move.w        #200,Noisevol
                          move.w        #22,Samplenum
                          move.b        #1,chanpick
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          jsr           MakeSomeNoise
                          GETREGS

.nowhoosh:

; Gas pipe: facing direction is given by leved (perpendicular to wall) so just continuously spray out flame!

                          move.l        NastyShotData,a5
                          move.w        #19,d1

.findonefree
                          move.w        objZone(a5),d0
                          blt.s         .foundonefree

                          adda.w        #ObjectSize,a5
                          dbra          d1,.findonefree

                          rts

.foundonefree:
                          move.b        #2,objNumber(a5)
                          move.w        objZone(a0),objZone(a5)
                          move.w        4(a0),d0
                          sub.w         #80,d0
                          move.w        d0,4(a5)
                          ext.l         d0
                          asl.l         #7,d0
                          move.l        d0,accypos(a5)
                          clr.b         shotstatus(a5)
                          move.w        #0,shotyvel(a5)
                          move.w        (a0),d0
                          move.w        (a5),d1
                          move.l        ObjectPoints,a1
                          move.l        (a1,d0.w*8),(a1,d1.w*8)
                          move.l        4(a1,d0.w*8),4(a1,d1.w*8)
                          move.b        #3,shotsize(a5)
                          move.w        #0,shotflags(a5)
                          move.w        #0,shotgrav(a5)
                          move.b        #7,shotpower(a5)
                          move.l        #%100000100000,EnemyFlags(a5)
                          move.w        #0,shotanim(a5)
                          move.w        #0,shotlife(a5)
                          move.l        #SineTable,a1
                          move.w        Facing(a0),d0
                          move.w        (a1,d0.w),d1
                          adda.w        #2048,a1
                          move.w        (a1,d0.w),d2
                          ext.l         d1
                          ext.l         d2
                          asl.l         #4,d1
                          asl.l         #4,d2
                          swap          d1
                          swap          d2
                          move.w        d1,shotxvel(a5)
                          move.w        d2,shotzvel(a5)
                          st            objWorry(a5)
 
                          rts

*********************************************************************************************
; ItsAMarine

                    ; include "AI.s"

*********************************************************************************************

ItsABarrel:
                          clr.b         objWorry(a0)
                          move.w        objZone(a0),GraphicRoom(a0)

                          cmp.w         #8,8(a0)
                          bne.s         notexploding

                          add.w         #$404,6(a0)

                          move.w        10(a0),d0
                          add.w         #1,d0
                          cmp.w         #8,d0
                          bne.s         .notdone
 
                          move.w        #-1,objZone(a0)
                          move.w        #-1,GraphicRoom(a0)
                          rts
 
.notdone:
                          move.w        d0,10(a0)
                          rts

notexploding:
                          move.w        objZone(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        ToZoneFloor(a1),d0
                          tst.b         objInTop(a0)
                          beq.s         .okinbot
                          move.l        ToUpperFloor(a1),d0

.okinbot:
                          asr.l         #7,d0
                          sub.w         #60,d0
                          move.w        d0,4(a0)
 
                          moveq         #0,d2
                          move.b        damagetaken(a0),d2
                          beq.s         nodamage
                          move.b        #0,damagetaken(a0)
                          sub.b         d2,numlives(a0)
                          bgt.s         nodamage
                          move.b        #0,numlives(a0)

                          SAVEREGS
                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),Viewerx
                          move.w        4(a1,d0.w*8),Viewerz
                          move.w        #40,d0
                          jsr           ComputeBlast
 
                          move.w        (a0),d0
                          move.l        #ObjRotated,a1
                          move.l        (a1,d0.w*8),Noisex
                          move.w        #300,Noisevol
                          move.w        #15,Samplenum
                          jsr           MakeSomeNoise
                          GETREGS

                          move.w        #8,8(a0)
                          move.w        #0,10(a0)
                          move.w        #$2020,14(a0)
                          move.w        #-30,2(a0)
 
                          rts
 
nodamage:
                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),Viewerx
                          move.w        4(a1,d0.w*8),Viewerz
                          move.b        objInTop(a0),ViewerTop
                          move.b        PLR1_StoodInTop,TargetTop
                          move.l        PLR1_Roompt,ToRoom
 
                          move.w        objZone(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        a1,FromRoom
  
                          move.w        PLR1_xoff,Targetx
                          move.w        PLR1_zoff,Targetz
                          move.l        PLR1_yoff,d0
                          asr.l         #7,d0
                          move.w        d0,Targety
                          move.w        4(a0),Viewery
                          jsr           CanItBeSeen
 
                          clr.b         17(a0)
                          tst.b         CanSee
                          beq           .noseeplr1
                          move.b        #1,17(a0)
 
.noseeplr1:
                          move.b        PLR2_StoodInTop,TargetTop
                          move.l        PLR2_Roompt,ToRoom
                          move.w        PLR2_xoff,Targetx
                          move.w        PLR2_zoff,Targetz
                          move.l        PLR2_yoff,d0
                          asr.l         #7,d0
                          move.w        d0,Targety
                          move.w        4(a0),Viewery
                          jsr           CanItBeSeen
 
                          tst.b         CanSee
                          beq           .noseeplr2
                          or.b          #2,17(a0)
 
.noseeplr2:
                          rts

*********************************************************************************************

                          include       "AlienControl.s"

*********************************************************************************************

nextCPt:                  dc.w          0

RipTear:                  dc.l          256*17*65536
otherrip:                 dc.l          256*18*65536

*********************************************************************************************

HealFactor  EQU 18

ItsAMediKit:

                          clr.b         objWorry(a0)
                          move.w        objZone(a0),GraphicRoom(a0)

                          move.w        objZone(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        ToZoneFloor(a1),d0
                          tst.b         objInTop(a0)
                          beq.s         .okinbot

                          move.l        ToUpperFloor(a1),d0

.okinbot:
                          asr.l         #7,d0
                          sub.w         #32,d0
                          move.w        d0,4(a0)

                          cmp.w         #PlayerMaxEnergy,PLR1_energy
                          bge           .NotSameZone

                          move.b        PLR1_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone
 
                          move.w        PLR1_xoff,oldx
                          move.w        PLR1_zoff,oldz
                          move.w        PLR1_Zone,d7
 
                          cmp.w         objZone(a0),d7
                          bne           .NotSameZone

                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

                          move.l        PLR1_Obj,a2
                          move.w        (a2),d0
                          move.l        #ObjRotated,a2
                          move.l        (a2,d0.w*8),Noisex
                          move.w        #50,Noisevol
                          move.w        #4,Samplenum                                                    ; Collect (4)
                          move.b        #2,chanpick
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
                          IFNE          ENABLEFACES
                          move.l        #cheeseFace,facesPtr
                          move.w        #-1,facesCounter
                          ENDC 

                          move.w        #-1,objZone(a0)
                          move.w        #-1,GraphicRoom(a0)
                          move.w        HealFactor(a0),d0
                          add.w         PLR1_energy,d0
                          cmp.w         #PlayerMaxEnergy,d0
                          ble.s         .okokokokokok

                          move.w        #PlayerMaxEnergy,d0

.okokokokokok:
                          move.w        d0,PLR1_energy

.NotPickedUp:
.NotSameZone:
MEDIPLR2:
                          cmp.w         #PlayerMaxEnergy,PLR2_energy
                          bge           .NotSameZone

                          move.b        PLR2_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone
 
                          move.w        PLR2_xoff,oldx
                          move.w        PLR2_zoff,oldz
                          move.w        PLR2_Zone,d7
                          move.w        objZone(a0),d0
 
                          cmp.w         objZone(a0),d7
                          bne           .NotSameZone

                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

                          move.l        PLR2_Obj,a2
                          move.w        (a2),d0
                          move.l        #ObjRotated,a2
                          move.l        (a2,d0.w*8),Noisex
                          move.w        #50,Noisevol
                          move.w        #4,Samplenum                                                    ; Collect (4)
                          move.b        #2,chanpick
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
                          move.w        #-1,objZone(a0)
                          move.w        #-1,GraphicRoom(a0)
                          move.w        HealFactor(a0),d0
                          add.w         PLR2_energy,d0
                          cmp.w         #PlayerMaxEnergy,d0
                          ble.s         .okokokokokok
                          move.w        #PlayerMaxEnergy,d0

.okokokokokok:
                          move.w        d0,PLR2_energy

.NotPickedUp:
.NotSameZone:
                          rts

*********************************************************************************************

AMGR:                     dc.w          3,4,5,0,29,0,0,28

*********************************************************************************************

AmmoType    EQU 18

ItsAnAmmoClip:
                          clr.b         objWorry(a0)
                          move.w        objZone(a0),GraphicRoom(a0)

                          move.w        AmmoType(a0),d0
                          move.w        AMGR(pc,d0.w*2),10(a0)

                          move.b        PLR1_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone
                          move.w        PLR1_xoff,oldx
                          move.w        PLR1_zoff,oldz
                          move.w        PLR1_Zone,d7
                          move.w        objZone(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        ToZoneFloor(a1),d0
                          tst.b         objInTop(a0)
                          beq.s         .okinbot
                          move.l        ToUpperFloor(a1),d0

.okinbot:
                          asr.l         #7,d0
                          sub.w         #32,d0
                          move.w        d0,4(a0)
 
                          cmp.w         objZone(a0),d7
                          bne           .NotSameZone

                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

                          move.w        AmmoType(a0),d0
                          lea           PLR1_GunData,a6
                          lsl.w         #2,d0
                          lea           (a6,d0.w*8),a6
                          cmp.w         #80*8,(a6)
                          bge           .NotPickedUp

                          move.l        PLR1_Obj,a2
                          move.w        (a2),d0
                          move.l        #ObjRotated,a2
                          move.l        (a2,d0.w*8),Noisex
                          move.w        #50,Noisevol
                          move.w        #11,Samplenum
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
                          move.w        #-1,objZone(a0)
                          move.w        #-1,GraphicRoom(a0)
                          move.w        AmmoType(a0),d0
                          lea           PLR1_GunData,a6
                          lsl.w         #2,d0
                          lea           (a6,d0.w*8),a6
                          moveq         #0,d0
                          move.b        4(a6),d0                                                        ; AmmoLeft(?)
                          asl.w         #3,d0
                          move.w        (a6),d1                                                         ;  
                          add.w         d0,d1
                          move.w        d1,(a6)

.NotPickedUp:
.NotSameZone:
AMMOPLR2:
                          move.b        PLR2_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone
                          move.w        PLR2_xoff,oldx
                          move.w        PLR2_zoff,oldz
                          move.w        PLR2_Zone,d7
                          move.w        objZone(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        ToZoneFloor(a1),d0
                          tst.b         objInTop(a0)
                          beq.s         .okinbot
                          move.l        ToUpperFloor(a1),d0

.okinbot:
                          asr.l         #7,d0
                          sub.w         #16,d0
                          move.w        d0,4(a0)
 
                          cmp.w         objZone(a0),d7
                          bne           .NotSameZone

                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

                          move.w        AmmoType(a0),d0
                          lea           PLR2_GunData,a6
                          lsl.w         #2,d0
                          lea           (a6,d0.w*8),a6
                          cmp.w         #80*8,(a6)
                          bge           .NotPickedUp


                          move.l        PLR2_Obj,a2
                          move.w        (a2),d0
                          move.l        #ObjRotated,a2
                          move.l        (a2,d0.w*8),Noisex
                          move.w        #50,Noisevol
                          move.w        #11,Samplenum
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
                          move.w        #-1,objZone(a0)
                          move.w        #-1,GraphicRoom(a0)
                          move.w        AmmoType(a0),d0
                          lea           PLR2_GunData,a6
                          lsl.w         #2,d0
                          lea           (a6,d0.w*8),a6
                          moveq         #0,d0
                          move.b        4(a6),d0
                          asl.w         #3,d0
                          move.w        (a6),d1
                          add.w         d0,d1
                          move.w        d1,(a6)

.NotPickedUp:
.NotSameZone:
                          rts
 
*********************************************************************************************

ItsABigGun:
                          move.w        objZone(a0),GraphicRoom(a0)

                          clr.b         objWorry(a0)

                          move.b        PLR1_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone
                          move.w        PLR1_xoff,oldx
                          move.w        PLR1_zoff,oldz
                          move.w        PLR1_Zone,d7
                          move.w        objZone(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        ToZoneFloor(a1),d0
                          tst.b         objInTop(a0)
                          beq.s         .okinbot
                          move.l        ToUpperFloor(a1),d0

.okinbot:
                          asr.l         #7,d0
                    ; add.w #16,d0
                          moveq         #0,d1
                          move.b        7(a0),d1
                          sub.w         d1,d0
 
                          move.w        d0,4(a0)
                          cmp.w         objZone(a0),d7
                          bne           .NotSameZone

                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

                          move.l        PLR1_Obj,a2
                          move.w        (a2),d0
                          move.l        #ObjRotated,a2
                          move.l        (a2,d0.w*8),Noisex
                          move.w        #50,Noisevol
                          move.w        #4,Samplenum                                                    ; Collect (4)
                          move.b        #2,chanpick
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
                          IFNE          ENABLEFACES
                          move.l        #cheeseFace,facesPtr
                          move.w        #-1,facesCounter
                          ENDC 

                          moveq         #0,d0
                          move.b        17(a0),d0
                          move.l        #PLR1_GunData+32,a1
                          move.l        #AmmoInGuns,a2
                          move.w        d0,d1
                          lsl.w         #2,d0
                          st            7(a1,d0.w*8)
                          move.w        (a2,d1.w*2),d1
                          add.w         d1,(a1,d0.w*8)

                          move.w        #-1,12(a0)
                          move.w        #-1,GraphicRoom(a0)

.NotPickedUp:
.NotSameZone:

************************************************************

GUNPLR2:
                          move.b        PLR2_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone
                          move.w        PLR2_xoff,oldx
                          move.w        PLR2_zoff,oldz
                          move.w        PLR2_Zone,d7
                          move.w        12(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        ToZoneFloor(a1),d0
                          tst.b         objInTop(a0)
                          beq.s         .okinbot
                          move.l        ToUpperFloor(a1),d0

.okinbot:
                          asr.l         #7,d0
                    ; add.w #16,d0
                          moveq         #0,d1
                          move.b        7(a0),d1
                          sub.w         d1,d0
 
                          move.w        d0,4(a0)
                          cmp.w         12(a0),d7
                          bne           .NotSameZone
                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

                          move.l        PLR2_Obj,a2
                          move.w        (a2),d0
                          move.l        #ObjRotated,a2
                          move.l        (a2,d0.w*8),Noisex
                          move.w        #50,Noisevol
                          move.w        #4,Samplenum                                                    ; Collect (4)
                          move.b        #2,chanpick
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
                          moveq         #0,d0
                          move.b        17(a0),d0
                          move.l        #PLR2_GunData+32,a1
                          move.l        #AmmoInGuns,a2
                          move.w        d0,d1
                          lsl.w         #2,d0
                          st            7(a1,d0.w*8)
                          move.w        (a2,d1.w*2),d1
                          add.w         d1,(a1,d0.w*8)
 
 
                          move.w        #-1,12(a0)
                          move.w        #-1,GraphicRoom(a0)

.NotPickedUp:
.NotSameZone:
                          rts

*********************************************************************************************

AmmoInGuns:               dc.w          0
                          dc.w          5
                          dc.w          1
                          dc.w          0
                          dc.w          1
                          dc.w          0
                          dc.w          0
                          dc.w          5

*********************************************************************************************

ItsAKey:
; Pickup key and draw it to the panel
; Note: Only the master (plr1) can pickup a key in coop mode 

                          tst.b         NASTY
                          bne           .yesnas
                          move.w        #-1,12(a0)
                          rts

.yesnas:
                          move.w        12(a0),GraphicRoom(a0)
                          clr.b         objWorry(a0)

*********************************************************

                          move.b        PLR1_StoodInTop,d0
                          move.b        objInTop(a0),d1
                          eor.b         d1,d0
                          bne           .NotSameZone

                          move.w        PLR1_xoff,oldx
                          move.w        PLR1_zoff,oldz
                          move.w        PLR1_Zone,d7
                          move.w        12(a0),d0
                          move.l        zoneAdds,a1
                          move.l        (a1,d0.w*4),a1
                          add.l         LEVELDATA,a1
                          move.l        2(a1),d0
                          asr.l         #7,d0
                          sub.w         #16,d0
                          move.w        d0,4(a0)
                          cmp.w         12(a0),d7
                          bne           .NotSameZone

*********************************************************

                          move.w        (a0),d0
                          move.l        ObjectPoints,a1
                          move.w        (a1,d0.w*8),newx
                          move.w        4(a1,d0.w*8),newz
                          move.l        #100*100,d2
                          jsr           CheckHit
                          tst.b         hitwall
                          beq           .NotPickedUp

*********************************************************
; Pickup key - sound

                          move.w        #0,Noisex
                          move.w        #0,Noisez
                          move.w        #50,Noisevol
                          move.w        #4,Samplenum                                                    ; Collect (4)
                          move.b        #2,chanpick
                          clr.b         notifplaying
                          move.b        1(a0),IDNUM
                          movem.l       a0/a1/d2/d6/d7,-(a7)
                          jsr           MakeSomeNoise
                          movem.l       (a7)+,a0/a1/d2/d6/d7
 
*********************************************************
; Pickup key - set conditions flag and draw to the panel

                          move.w        #-1,12(a0)
                          move.w        #-1,GraphicRoom(a0)
                          move.b        17(a0),d0
                          or.b          d0,Conditions+1

                          moveq         #0,d1
                          lsr.b         #1,d0                                                           ; Conditions
                          bcs.s         .done

                          addq          #1,d1
                          lsr.b         #1,d0
                          bcs.s         .done

                          addq          #1,d1
                          lsr.b         #1,d0
                          bcs.s         .done

                          addq          #1,d1 

.done:
                          move.l        #OffsetToGraph,a1
                          move.l        Panel,a2                                                        ; Panel picture    
                          add.l         (a1,d1.w*4),a2                                                  ; Select place

                          move.l        #PanelKeys,a1                                                   ; key incbins
                          muls          #6*22*8,d1                                                      ; 6*22*8 = 1056                   
                          adda.w        d1,a1

                          move.w        #22*8-1,d0                                                      ; key lines

.lines:
                          move.l        (a1)+,d1                                                        ; 4 bytes
                          or.l          d1,(a2)
                          move.w        (a1)+,d1                                                        ; 2 bytes
                          or.w          d1,4(a2)

                          adda.w        #40,a2
                          dbra          d0,.lines

*********************************************************

.NotPickedUp:
.NotSameZone:
                          rts

*********************************************************************************************
; .w 
; 15 =
; 14 =
; 13 =
; 12 =
; 11 =
; 10 =
; 9 =
; 8 = key
; 7 = key
; 6 = key
; 5 = key
; 4 =
; 3 =
; 2 =
; 1 =
; 0 =

Conditions:               dc.l          0

*********************************************************************************************

OffsetToGraph:
                          dc.l          (40*8)*43+10                                                    ; Right DOWN
                          dc.l          (40*8)*11+12                                                    ; Left  UP    
                          dc.l          (40*8)*11+22                                                    ; Right UP
                          dc.l          (40*8)*43+24                                                    ; Left DOWN  

*********************************************************************************************

; Format of animations:
; Size (-1 = and of anim) (w)
; Address of Frame. (l)
; height offset (w)
 
Bul1Anim:
                          dc.w          20*256+15
                          dc.w          6,8
                          dc.w          0
                          dc.w          17*256+17
                          dc.w          6,9
                          dc.w          0
                          dc.w          15*256+20
                          dc.w          6,10
                          dc.w          0
                          dc.w          17*256+17
                          dc.w          6,11
                          dc.w          0
                          dc.l          -1

Bul1Pop
                          dc.b          25,25
                          dc.w          1,6
                          dc.w          0
                          dc.b          25,25
                          dc.w          1,7
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,8
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,9
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,10
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,11
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,12
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,13
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,14
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,15
                          dc.w          -4
                          dc.b          25,25
                          dc.w          1,16
                          dc.w          -4
                          dc.l          -1
 
Bul3Anim:
                          dc.b          25,25
                          dc.w          0,12
                          dc.w          0
                          dc.b          25,25
                          dc.w          0,13
                          dc.w          0
                          dc.b          25,25
                          dc.w          0,14
                          dc.w          0
                          dc.b          25,25
                          dc.w          0,15
                          dc.w          0
                          dc.l          -1

Bul3Pop:
                          dc.l          -1
 
Bul4Anim:
                          dc.b          25,25
                          dc.w          6,4
                          dc.w          0
                          dc.b          25,25
                          dc.w          6,5
                          dc.w          0
                          dc.b          25,25
                          dc.w          6,6
                          dc.w          0
                          dc.b          25,25
                          dc.w          6,7
                          dc.w          0
                          dc.l          -1
 
Bul4Pop:
                          dc.b          20,20
                          dc.w          6,4
                          dc.w          0
                          dc.b          15,15
                          dc.w          6,5
                          dc.w          0
                          dc.b          10,10
                          dc.w          6,6
                          dc.w          0
                          dc.b          5,5
                          dc.w          6,7
                          dc.w          0
                          dc.l          -1

Bul5Anim:
                          dc.b          10,10
                          dc.w          6,4
                          dc.w          0
                          dc.b          10,10
                          dc.w          6,5
                          dc.w          0
                          dc.b          10,10
                          dc.w          6,6
                          dc.w          0
                          dc.b          10,10
                          dc.w          6,7
                          dc.w          0
                          dc.l          -1
 
Bul5Pop:
                          dc.b          8,8
                          dc.w          6,4
                          dc.w          0
                          dc.b          6,6
                          dc.w          6,5
                          dc.w          0
                          dc.b          4,4
                          dc.w          6,6
                          dc.w          0
                          dc.l          -1
 
grenAnim:
                          dc.b          25,25
                          dc.w          1,21
                          dc.w          0
                          dc.b          25,25
                          dc.w          1,22
                          dc.w          0
                          dc.b          25,25
                          dc.w          1,23
                          dc.w          0
                          dc.b          25,25
                          dc.w          1,24
                          dc.w          0
                          dc.l          -1

Bul2Anim:
                          dc.b          25,25
                          dc.w          2,0
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,1
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,2
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,3
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,4
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,5
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,6
                          dc.w          0
                          dc.b          25,25
                          dc.w          2,7
                          dc.w          0
                          dc.w          -1
 

Bul2Pop:
                          dc.b          25,25
                          dc.w          2,8
                          dc.w          -4
                          dc.b          29,29
                          dc.w          2,9
                          dc.w          -4
                          dc.b          33,33
                          dc.w          2,10
                          dc.w          -4
                          dc.b          37,37
                          dc.w          2,11
                          dc.w          -4
                          dc.b          41,41
                          dc.w          2,12
                          dc.w          -4
                          dc.b          45,45
                          dc.w          2,13
                          dc.w          -4
                          dc.b          49,49
                          dc.w          2,14
                          dc.w          -4
                          dc.b          53,53
                          dc.w          2,15
                          dc.w          -4
                          dc.b          57,57
                          dc.w          2,16
                          dc.w          -4
                          dc.b          61,61
                          dc.w          2,17
                          dc.w          -4
                          dc.b          65,65
                          dc.w          2,18
                          dc.w          -4
                          dc.b          69,69
                          dc.w          2,19
                          dc.w          -4
                          dc.w          -1
 
RockAnim:
                          dc.b          16,16
                          dc.w          6,0
                          dc.w          0
                          dc.b          16,16
                          dc.w          6,1
                          dc.w          0
                          dc.b          16,16
                          dc.w          6,2
                          dc.w          0
                          dc.b          16,16
                          dc.w          6,3
                          dc.w          0  
                          dc.l          -1

val                       SET           100

RockPop:
                          dc.b          val,val
                          dc.w          8,0
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,1
                          dc.w          0
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,2
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,3
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,4
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,4
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,5
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,5
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,6
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,6
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          -4
val                       SET           val+10 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          -4
                          dc.l          -1


val                       SET           5

FlameAnim:

                          dc.b          val,val
                          dc.w          8,0
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,1
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,2
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,3
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,4
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,4
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,5
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,5
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,5
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,6
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,6
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,6
                          dc.w          0
val                       SET           val+6 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+8 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+8 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+8 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+8 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          0
val                       SET           val+8 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          0
val                       SET           val+8 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          0

                          dc.l          -1
 
FlamePop:
val                       SET           4*35
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,7
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          0
val                       SET           val+4 
                          dc.b          val,val
                          dc.w          8,8
                          dc.w          0

                          dc.l          -1

Explode1Anim: 
                          dc.b          25,25
                          dc.w          0,16
                          dc.w          0
                          dc.b          25,25
                          dc.w          0,17
                          dc.w          0
                          dc.b          25,25
                          dc.w          0,18
                          dc.w          0
                          dc.b          25,25
                          dc.w          0,19
                          dc.w          0
                          dc.l          -1
 
Explode1Pop:
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,16
                          dc.w          1
 
                          dc.b          17,17
                          dc.w          0,16
                          dc.w          1
 
                          dc.b          13,13
                          dc.w          0,16
                          dc.w          1
 
                          dc.b          9,9
                          dc.w          0,16
                          dc.w          1
 
                          dc.l          -1

Explode2Anim: 
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,21
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,22
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,23
                          dc.w          0
                          dc.l          -1
 
Explode2Pop:
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,20
                          dc.w          1
 
                          dc.b          17,17
                          dc.w          0,20
                          dc.w          1
 
                          dc.b          13,13
                          dc.w          0,20
                          dc.w          1
 
                          dc.b          9,9
                          dc.w          0,20
                          dc.w          1
 
                          dc.l          -1


Explode3Anim: 
                          dc.b          20,20
                          dc.w          0,24
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,25
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,26
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,27
                          dc.w          0
                          dc.l          -1
 
Explode3Pop:
 
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
                          dc.b          17,17
                          dc.w          0,24
                          dc.w          1
 
                          dc.b          13,13
                          dc.w          0,24
                          dc.w          1
 
                          dc.b          9,9
                          dc.w          0,24
                          dc.w          1
 
                          dc.l          -1

Explode4Anim: 
                          dc.b          30,30
                          dc.w          0,28
                          dc.w          0
                          dc.b          30,30
                          dc.w          0,29
                          dc.w          0
                          dc.b          30,30
                          dc.w          0,30
                          dc.w          0
                          dc.b          30,30
                          dc.w          0,31
                          dc.w          0
                          dc.l          -1
 
Explode4Pop:
 
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          0
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
                          dc.b          20,20
                          dc.w          0,28
                          dc.w          1
 
                          dc.b          17,17
                          dc.w          0,28
                          dc.w          1
 
                          dc.b          13,13
                          dc.w          0,28
                          dc.w          1
 
                          dc.b          9,9
                          dc.w          0,28
                          dc.w          1
 
                          dc.l          -1
  
BulletSizes:
                          dc.w          $1010,$808
                          dc.w          $1010,$1010
                          dc.w          $1010,$2020
                          dc.w          $2020,$2020
                          dc.w          $0808,$2020
                          dc.w          $1010,$1010
                          dc.w          $1010,$1010
                          dc.w          $808,$808
                          dc.w          0,0,0,0
;10 
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
;20
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
;30
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
;40
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
;50
                          dc.w          $0808,$0808,$0808,$0808
                          dc.w          $0808,$0808,$0808,$0808

HitNoises:
                          dc.l          -1,-1
                          dc.w          15,200
                          dc.l          -1
                          dc.w          15,200
                          dc.l          -1,-1,-1,-1,-1
                          dc.l          -1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                          dc.l          -1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                          dc.l          -1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                          dc.l          -1,-1,-1,-1,-1,-1,-1,-1,-1,-1
 
                          dc.w          13,50,13,50,13,50,13,50
 
ExplosiveForce:
                          dc.w          0,0,64,0,40,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0,0,0,0,0,0,0
                          dc.w          0,0,0,0
  
BulletTypes:
                          dc.l          Bul1Anim,Bul1Pop
                          dc.l          Bul2Anim,Bul2Pop
                          dc.l          RockAnim,RockPop
                          dc.l          FlameAnim,FlamePop
                          dc.l          grenAnim,RockPop
                          dc.l          Bul4Anim,Bul4Pop
                          dc.l          Bul5Anim,Bul5Pop
                          dc.l          Bul1Anim,Bul1Pop
                          dc.l          0,0
                          dc.l          0,0
 
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
 
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
 
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
 
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
                          dc.l          0,0
 
                          dc.l          Explode1Anim,Explode1Pop
                          dc.l          Explode2Anim,Explode2Pop
                          dc.l          Explode3Anim,Explode3Pop
                          dc.l          Explode4Anim,Explode4Pop
 
tsta:                     dc.l          0
timeout:                  dc.w          0

*********************************************************************************************

ItsABullet:

                          move.b        #0,timeout
                          move.w        objZone(a0),d0
                          move.w        d0,GraphicRoom(a0)
                          blt           doneshot
 
                          tst.b         shotstatus(a0)
                          bne.s         noworrylife
 
                          moveq         #0,d1
                          move.w        shotlife(a0),d2
                          blt.s         infinite
                          move.b        shotsize(a0),d1
                          move.l        #PLR1_GunData,a1
                          lsl.w         #2,d1
                          move.w        10(a1,d1.w*8),d1
                          blt.s         infinite
 
                          cmp.w         d2,d1
                          bge.s         notdone
 
                          st            timeout
                          bra.s         infinite 
 
notdone:
                          move.w        TempFrames,d2
                          add.w         d2,shotlife(a0)
 
infinite:
noworrylife:
                          move.w        #0,extlen
                          move.b        #$ff,awayfromwall

                          moveq         #0,d1
                          move.b        shotsize(a0),d1
                          move.l        #BulletTypes,a1
                          lea           (a1,d1.w*8),a1 
 
                          tst.b         shotstatus(a0)
                          beq.s         notpopping

                          moveq         #0,d1
                          move.b        shotsize(a0),d1
                          move.l        #BulletSizes,a2
                          move.w        2(a2,d1.w*4),14(a0)

                          moveq         #0,d1
                          move.b        shotanim(a0),d1

                          move.l        4(a1),a2
                          move.w        (a2,d1.w*8),d2
                          cmp.w         #-1,d2
                          bne.s         notdonepopping
                          move.w        #-1,12(a0)
                          move.w        #-1,GraphicRoom(a0)
                          clr.b         shotstatus(a0)
                          move.b        #0,shotanim(a0)
                          rts

notdonepopping:
                          add.b         #1,shotanim(a0)
                          move.w        d2,6(a0)
                          move.l        2(a2,d1.w*8),8(a0)
                          move.w        6(a2,d1.w*8),d3
                          add.w         d3,4(a0)
                          ext.l         d3
                          asl.l         #7,d3
                          add.l         d3,accypos(a0)
                          rts

notpopping:
                          moveq         #0,d1
                          move.b        shotsize(a0),d1
                          move.l        #BulletSizes,a2
                          move.w        (a2,d1.w*4),14(a0)

                          moveq         #0,d1
                          move.b        shotanim(a0),d1

                          move.l        (a1),a2
                          add.b         #1,shotanim(a0)
                          move.w        (a2,d1.w*8),d2
                          bge.s         notdoneanim

                          move.b        #0,shotanim(a0)
                          move.w        #0,d1

notdoneanim:
                          move.w        (a2,d1.w*8),6(a0)
                          move.l        2(a2,d1.w*8),8(a0)
                          move.w        6(a2,d1.w*8),d3
                          ext.l         d3
                          asl.l         #7,d3
                          add.l         d3,accypos(a0)

                          move.l        zoneAdds,a2
                          move.l        (a2,d0.w*4),d0
                          add.l         LEVELDATA,d0
                          move.l        d0,objroom
 
                          move.l        objroom,a3
 
                          tst.b         objInTop(a0)
                          beq.s         .notintop
                          adda.w        #8,a3

.notintop:
                          move.l        6(a3),d0
                          sub.l         accypos(a0),d0
                          cmp.l         #10*128,d0
                          blt           .nohitroof 
 
                          btst          #0,shotflags+1(a0)
                          beq.s         .nobounce
 
                          neg.w         shotyvel(a0)
 
                          move.l        6(a3),d0
                          add.l         #10*128,d0
                          move.l        d0,accypos(a0)
 
                          btst          #1,shotflags+1(a0)
                          beq           .nohitroof
 
                          move.l        shotxvel(a0),d0
                          asr.l         #1,d0
                          move.l        d0,shotxvel(a0)
                          move.l        shotzvel(a0),d0
                          asr.l         #1,d0
                          move.l        d0,shotzvel(a0) 
 
                          bra           .nohitroof

.nobounce:
                          move.b        #0,shotanim(a0)
                          move.b        #1,shotstatus(a0)
 
                          SAVEREGS
                          move.l        #HitNoises,a2
                          moveq         #0,d0
                          move.b        shotsize(a0),d0
                          move.l        (a2,d0.w*4),d0
                          blt.s         .nohitnoise

                          move.l        #ObjRotated,a1
                          move.w        (a0),d1
                          move.l        (a1,d1.w*8),Noisex
                          move.w        d0,Noisevol
                          swap          d0
                          move.w        d0,Samplenum
                          move.b        d1,IDNUM
                          jsr           MakeSomeNoise
 
.nohitnoise:
                          moveq         #0,d0
                          move.l        #ExplosiveForce,a2
                          move.b        shotsize(a0),d0
                          move.w        (a2,d0.w*2),d0
                          beq.s         .noexplosion
 
                          move.w        newx,Viewerx
                          move.w        newz,Viewerz
 
                          move.w        4(a0),Viewery
                          move.b        objInTop(a0),ViewerTop
 
                          bsr           ComputeBlast
 
.noexplosion:
                          GETREGS

.nohitroof:
                          move.l        2(a3),d0
                          sub.l         accypos(a0),d0
                          cmp.l         #10*128,d0
                          bgt           .nohitfloor 

                          btst          #0,shotflags+1(a0)
                          beq.s         .nobounceup
 
                          tst.w         shotyvel(a0)
                          blt           .nohitfloor
 
                          moveq         #0,d0
                          move.w        shotyvel(a0),d0
                          asr.w         #1,d0
                          neg.w         d0
                          move.w        d0,shotyvel(a0)
 
                          move.l        2(a3),d0
                          sub.l         #10*128,d0
                          move.l        d0,accypos(a0)

                          btst          #1,shotflags+1(a0)
                          beq           .nohitfloor
 
                          move.l        shotxvel(a0),d0
                          asr.l         #1,d0
                          move.l        d0,shotxvel(a0)
                          move.l        shotzvel(a0),d0
                          asr.l         #1,d0
                          move.l        d0,shotzvel(a0) 
 
                          bra           .nohitfloor

.nobounceup: 
                          move.b        #0,shotanim(a0)
                          move.b        #1,shotstatus(a0)

                          SAVEREGS
                          move.l        #HitNoises,a2
                          moveq         #0,d0
                          move.b        shotsize(a0),d0
                          move.l        (a2,d0.w*4),d0
                          blt.s         .nohitnoise2

                          move.l        #ObjRotated,a1
                          move.w        (a0),d1
                          move.l        (a1,d1.w*8),Noisex
                          move.w        d0,Noisevol
                          swap          d0
                          move.w        d0,Samplenum
                          move.b        d1,IDNUM
                          jsr           MakeSomeNoise

.nohitnoise2:
                          moveq         #0,d0
                          move.l        #ExplosiveForce,a2
                          move.b        shotsize(a0),d0
                          move.w        (a2,d0.w*2),d0
                          beq.s         .noexplosion2
 
                          move.w        4(a0),Viewery
                          move.w        newx,Viewerx
                          move.w        newz,Viewerz
                          move.b        objInTop(a0),ViewerTop
                          bsr           ComputeBlast
 
.noexplosion2:
                          GETREGS

.nohitfloor:
                          move.l        ObjectPoints,a1
                          move.w        (a0),d1
                          lea           (a1,d1.w*8),a1
                          move.l        (a1),d2
                          move.l        d2,oldx
                          move.l        shotxvel(a0),d3
                          move.w        d3,d4
                          swap          d3
                          move.w        TempFrames,d5
                          muls          d5,d3
                          mulu          d5,d4
                          swap          d3
                          clr.w         d3
                          add.l         d4,d3
                          add.l         d3,d2
                          move.l        d2,newx
                          move.l        4(a1),d2
                          move.l        d2,oldz
                          move.l        shotzvel(a0),d3
                          move.w        d3,d4
                          swap          d3
                          muls          d5,d3
                          mulu          d5,d4
                          swap          d3
                          clr.w         d3
                          add.l         d4,d3
                          add.l         d3,d2
                          move.l        d2,newz
                          move.l        accypos(a0),oldy 

                          move.w        shotyvel(a0),d3
                          muls          TempFrames,d3
                          move.w        shotgrav(a0),d5
                          beq.s         nograv
                          muls          TempFrames,d5
                          add.l         d5,d3
                          move.w        shotyvel(a0),d6
                          ext.l         d6
                          add.l         d5,d6
                          cmp.l         #10*256,d6
                          blt.s         okgrav
                          move.l        #10*256,d6
                          okgrav        :
                          move.w        d6,shotyvel(a0)

nograv:
                          move.l        accypos(a0),d4 
                          add.l         d3,d4
 
                          move.l        d4,accypos(a0)
                          sub.l         #5*128,d4
                          move.l        d4,newy
                          add.l         #5*128,d4
                          asr.l         #7,d4
                          move.w        d4,4(a0)
                          btst          #0,shotflags+1(a0)
                          sne           wallbounce
                          seq           exitfirst

                          clr.b         hitwall
                          move.b        objInTop(a0),StoodInTop
                          move.w        #%0000010000000000,wallflags
                          move.l        #0,StepUpVal
                          move.l        #$1000000,StepDownVal
                          move.l        #10*128,thingheight
                          move.w        oldx,d0
                          cmp.w         newx,d0
                          bne.s         lalal
                          move.w        oldz,d0
                          cmp.w         newz,d0
                          beq.s         nomovebul
                          move.w        #1,walllength
 
lalal:
                          movem.l       d0/d7/a0/a1/a2/a4/a5,-(a7)
                          jsr           MoveObject
                          movem.l       (a7)+,d0/d7/a0/a1/a2/a4/a5

nomovebul:
                          move.b        StoodInTop,objInTop(a0)
  
                          tst.b         wallbounce
                          beq.s         .notabouncything
 
                          tst.b         hitwall
                          beq           .nothitwall

; we have hit a wall....

                          move.w        shotzvel(a0),d0
                          muls          wallxsize,d0
                          move.w        shotxvel(a0),d1
                          muls          wallzsize,d1
                          sub.l         d1,d0
                          divs          walllength,d0
 
                          move.w        shotxvel(a0),d1
                          move.w        wallzsize,d2
                          add.w         d2,d2
                          muls          d0,d2
                          divs          walllength,d2
                          add.w         d2,d1
                          move.w        d1,shotxvel(a0)
 
                          move.w        shotzvel(a0),d1
                          move.w        wallxsize,d2
                          add.w         d2,d2
                          muls          d0,d2
                          divs          walllength,d2
                          sub.w         d2,d1
                          move.w        d1,shotzvel(a0)
 
                          btst          #1,shotflags+1(a0)
                          beq           .nothitwall
 
                          move.l        shotxvel(a0),d0
                          asr.l         #1,d0
                          move.l        d0,shotxvel(a0)
                          move.l        shotzvel(a0),d0
                          asr.l         #1,d0
                          move.l        d0,shotzvel(a0) 
  
 
                          bra           .nothitwall

.notabouncything:
                          tst.b         hitwall
                          beq           .nothitwall
 
                          move.l        wallhitheight,d4
                          move.l        d4,accypos(a0)
                          asr.l         #7,d4
                          move.w        d4,4(a0)
 
.hitsomething:
                          clr.b         timeout
                          move.b        #0,shotanim(a0)
                          move.b        #1,shotstatus(a0)

                          SAVEREGS
                          move.l        #HitNoises,a2
                          moveq         #0,d0
                          move.b        shotsize(a0),d0
                          move.l        (a2,d0.w*4),d0
                          blt.s         .nohitnoise

                          move.l        #ObjRotated,a1
                          move.w        (a0),d1
                          move.l        (a1,d1.w*8),Noisex
                          move.w        d0,Noisevol
                          swap          d0
                          move.w        d0,Samplenum
                          move.b        d1,IDNUM
                          jsr           MakeSomeNoise

.nohitnoise:
                          moveq         #0,d0
                          move.l        #ExplosiveForce,a2
                          move.b        shotsize(a0),d0
                          move.w        (a2,d0.w*2),d0
                          beq.s         .noexplosion
 
                          move.w        newx,Viewerx
                          move.w        newz,Viewerz
                          move.w        4(a0),Viewery
                          move.b        objInTop(a0),ViewerTop
                          bsr           ComputeBlast
 
.noexplosion:
                          GETREGS

                    ; bra doneshot
                    ; rts
 
.nothitwall:
                          tst.b         timeout
                          bne           .hitsomething

lab:
                          move.l        objroom,a3
                          move.w        (a3),objZone(a0)
                          move.w        (a3),GraphicRoom(a0)
                          move.l        newx,(a1)
                          move.l        newz,4(a1)

; Check if hit a nasty

                          tst.l         EnemyFlags(a0)
                          bne.s         notasplut
                          rts

notasplut:
                          move.l        ObjectData,a3
                          move.l        ObjectPoints,a1
                          move.w        newx,d2
                          sub.w         oldx,d2
                          move.w        d2,xdiff
                          move.w        newz,d1
                          sub.w         oldz,d1
                          move.w        d1,zdiff
                          move.w        d1,d3
                          move.w        d2,d4
                          muls          d2,d2
                          muls          d1,d1
                          move.l        #1,d0
                          add.l         d1,d2
                          beq           .oksqr

                          move.w        #31,d0

.findhigh:
                          btst          d0,d2
                          bne           .foundhigh
                          dbra          d0,.findhigh

.foundhigh:
                          asr.w         #1,d0
                          clr.l         d3
                          bset          d0,d3
                          move.l        d3,d0

                          move.w        d0,d1
                          muls          d1,d1                                                           ; x*x
                          sub.l         d2,d1                                                           ; x*x-a
                          asr.l         #1,d1                                                           ; (x*x-a)/2
                          divs          d0,d1                                                           ; (x*x-a)/2x
                          sub.w         d1,d0                                                           ; second approx
                          bgt           .stillnot0
                          move.w        #1,d0

.stillnot0:
                          move.w        d0,d1
                          muls          d1,d1
                          sub.l         d2,d1
                          asr.l         #1,d1
                          divs          d0,d1
                          sub.w         d1,d0                                                           ; second approx
                          bgt           .stillnot02
                          move.w        #1,d0

.stillnot02:
                          move.w        d0,d1
                          muls          d1,d1
                          sub.l         d2,d1
                          asr.l         #1,d1
                          divs          d0,d1
                          sub.w         d1,d0                                                           ; second approx
                          bgt           .stillnot03
                          move.w        #1,d0

.stillnot03:
.oksqr:
                          move.w        d0,Range
                          add.w         #40,d0
                          muls          d0,d0
                          move.l        d0,sqrnum

.checkloop:
                          tst.w         (a3)
                          blt           .checkedall

                          tst.w         objZone(a3)
                          blt           .notanasty

                          moveq         #0,d1
                          move.b        objNumber(a3),d1
                          move.l        EnemyFlags(a0),d7
                          btst          d1,d7
                          beq           .notanasty

                          tst.b         numlives(a3)
                          beq           .notanasty
 
                          move.l        #ColBoxTable,a6
                          lea           (a6,d1.w*8),a6
 
                          move.w        4(a3),d1
                          move.w        4(a0),d2
                          sub.w         d1,d2
                          bge           .okh
                          neg.w         d2

.okh:
                          cmp.w         2(a6),d2
                          bgt           .notanasty
 
                          move.w        (a3),d1
                          move.w        (a1,d1.w*8),d2
                          move.w        d2,d4
                          move.w        4(a1,d1.w*8),d3
                          move.w        d3,d5
                          sub.w         newx,d4
                          sub.w         oldx,d2
                          move.w        d2,d6
                          sub.w         newz,d5
                          sub.w         oldz,d3
                          move.w        d3,d7
                          muls          zdiff,d6
                          muls          xdiff,d7
                          sub.l         d7,d6
                          bgt.s         .pos
                          neg.l         d6

.pos:
                          divs          Range,d6
                          cmp.w         (a6),d6
                          bgt           .stillgoing
 
                          muls          d2,d2
                          muls          d3,d3
                          add.l         d3,d2
                          cmp.l         sqrnum,d2
                          bgt           .stillgoing
                          muls          d4,d4
                          muls          d5,d5
                          add.l         d5,d4
                          cmp.l         sqrnum,d4
                          bgt           .stillgoing
 
                          move.b        shotpower(a0),d6
                          add.b         d6,damagetaken(a3)
                          move.w        shotxvel(a0),ImpactX(a3)
                          move.w        shotzvel(a0),ImpactZ(a3)
                          move.b        #0,shotanim(a0)
                          move.b        #1,shotstatus(a0)
 
                          SAVEREGS
                          move.l        #HitNoises,a2
                          moveq         #0,d0
                          move.b        shotsize(a0),d0
                          move.l        (a2,d0.w*4),d0
                          blt.s         .nohitnoise3

                          move.l        #ObjRotated,a1
                          move.w        (a0),d1
                          move.l        (a1,d1.w*8),Noisex
                          move.w        d0,Noisevol
                          swap          d0
                          move.w        d0,Samplenum
                          move.b        d1,IDNUM
                          jsr           MakeSomeNoise

.nohitnoise3:
                          moveq         #0,d0
                          move.l        #ExplosiveForce,a2
                          move.b        shotsize(a0),d0
                          move.w        (a2,d0.w*2),d0
                          beq.s         .noexplosion3
 
                          move.w        4(a0),Viewery
                          move.w        newx,Viewerx
                          move.w        newz,Viewerz
                          bsr           ComputeBlast
 
.noexplosion3:
                          GETREGS
 
                          bra           .hitnasty

.stillgoing:
.notanasty:
                          add.w         #64,a3
                          bra           .checkloop

.hitnasty:
.checkedall
doneshot:
                          rts

*********************************************************************************************

tmpnewx:                  dc.l          0
tmpnewz:                  dc.l          0
hithit:                   dc.l          0
sqrnum:                   dc.l          0
tmpangpos:                dc.l          0

NUMTOCHECK:               dc.w          0 

*********************************************************************************************
*********************************************************************************************

allbars:                  dc.l          0
backrout:                 ds.b          800

*********************************************************************************************
; Monkey business!

MAKEBACKROUT:

                          move.l        #backrout+256,d0
                          clr.b         d0
                          move.l        d0,allbars
                          move.l        d0,a1

                          lea           fromback,a0
                          move.w        #400,d0

putinback:
                          move.b        (a0)+,(a1)+
                          dbra          d0,putinback

                          rts

*********************************************************************************************

putinbackdrop:

                          move.l        a0,-(a7)

                          move.w        tmpangpos,d5
                          and.w         #8191,d5
                          muls          #432,d5
                          divs          #8192,d5
                          muls          #38*2,d5

                          SUPERVISOR    SetInstCacheOn

                          move.l        fromPt,a0                                                       ; Copper chunky
                          adda.w        #widthOffset,a0
                          lea           EndBackPicture,a3
                          lea           BackPicture,a1
                          add.l         d5,a1
                          move.w        #2,d4

                          move.l        allbars(pc),a2                                                  
                          jmp           (a2)

*********************************************************************************************

fromback:
                          move.w        #31,d3
onebar:
vertline:	

val                       SET           0
                          REPT          19
                          move.l        (a1)+,d0
                          move.w        d0,(val+widthOffset)(a0)
                          swap          d0
                          move.w        d0,val(a0)
val                       SET           val+(widthOffset*2)
                          ENDR
 
                          cmp.l         a3,a1
                          blt.s         notoffrightend
                          move.l        #BackPicture,a1
                   
notoffrightend:
                          addq          #4,a0
                          dbra          d3,onebar

                          addq          #4,a0
                          dbra          d4,fromback
 
                          move.l        (a7)+,a0
                          rts

*********************************************************************************************
*********************************************************************************************

MaxDamage:                dc.w          0

*********************************************************************************************

ComputeBlast:

                          clr.w         doneflames
 
                          move.w        d0,d6
                          move.w        d0,MaxDamage
 
                          move.w        d0,d1
                          ext.l         d6
                          neg.w         d1
                          move.w        12(a0),d0
                          jsr           Flash

                          move.l        zoneAdds,a2
                          move.l        (a2,d0.w*4),a2
                          add.l         LEVELDATA,a2
                          move.l        a2,middleRoom

                          move.l        ObjectData,a2
                          suba.w        #64,a2
                          move.l        #TESTAB,a6

                          move.l        a0,-(a7)
 
HitObjLoop:
                          move.l        middleRoom,FromRoom
                          add.w         #64,a2
                          move.w        (a2),d0
                          blt           CheckedEmAll
                          tst.w         12(a2)
                          blt.s         HitObjLoop
                          moveq         #0,d1
                          move.b        16(a2),d1
                          move.l        #%1111111111110111100001,d7                                     ; possible targets
                          btst          d1,d7
                          beq.s         HitObjLoop

                          move.w        12(a2),d1
                          move.l        zoneAdds,a3
                          move.l        (a3,d1.w*4),a3
                          add.l         LEVELDATA,a3
                          move.l        a3,ToRoom
                          move.l        ObjectPoints,a3
                          move.w        (a3,d0.w*8),Targetx
                          move.w        4(a3,d0.w*8),Targetz
                          move.w        4(a2),Targety
                          move.b        objInTop(a2),TargetTop
                          jsr           CanItBeSeen
                          tst.b         CanSee
                          beq           HitObjLoop
 
                          move.w        Targetx,d0
                          sub.w         Viewerx,d0
                          move.w        d0,d2
                          move.w        Targetz,d1
                          sub.w         Viewerz,d1
                          move.w        d1,d3
                          muls          d2,d2
                          muls          d3,d3
                          add.l         d3,d2 
                          beq           .oksqr
                          move.w        #31,d4

.findhigh:
                          btst          d4,d2
                          dbne          d4,.findhigh

.foundhigh:
                          asr.w         #1,d4
                          clr.l         d3
                          bset          d4,d3
                          move.l        d3,d4

                          move.w        d4,d3
                          muls          d3,d3                                                           ; x*x
                          sub.l         d2,d3                                                           ; x*x-a
                          asr.l         #1,d3                                                           ; (x*x-a)/2
                          divs          d4,d3                                                           ; (x*x-a)/2x
                          sub.w         d3,d4                                                           ; second approx
                          bgt           .stillnot0
                          move.w        #1,d4

.stillnot0:
                          move.w        d4,d3
                          muls          d1,d3
                          sub.l         d2,d3
                          asr.l         #1,d3
                          divs          d4,d3
                          sub.w         d3,d4                                                           ; second approx
                          bgt           .stillnot02
                          move.w        #1,d4

.stillnot02:
                          move.w        d4,d3
                          muls          d3,d3
                          sub.l         d2,d3
                          asr.l         #1,d3
                          divs          d4,d3
                          sub.w         d3,d4                                                           ; second approx
                          bgt           .stillnot03
                          move.w        #1,d4
 
.stillnot03:
                          .oksqr:
                          move.w        d4,d3
                          asr.w         #3,d3
 
                          sub.w         #4,d3
                          bge.s         OkItsnotzero
                          moveq         #0,d3

OkItsnotzero:
                          cmp.w         #31,d3
                          bgt           HitObjLoop
                          neg.w         d3
                          add.w         32,d3
 
                          move.w        d6,d5
                          muls          d3,d5
                          asr.l         #5,d5
                          cmp.w         MaxDamage,d5
                          blt.s         okdamage
                          move.w        MaxDamage,d5

okdamage:
                          add.b         d5,damagetaken(a2)
                          ext.l         d0
                          ext.l         d1
                          asl.l         #4,d0
                          asl.l         #4,d1
                          divs          d3,d0
                          divs          d3,d1
                          move.w        d0,ImpactX(a2)
                          move.w        d1,ImpactZ(a2)
 
                          bra           HitObjLoop 
 
CheckedEmAll:

; Now put in the flames!
                          move.l        (a7)+,a0

                          move.w        (a0),d0
                          move.l        ObjectPoints,a2
                          move.w        (a2,d0.w*8),d1
                          move.w        4(a2,d0.w*8),d2
 
                          move.w        d1,middlex
                          move.w        d2,middlez

                          move.w        #9,d7
 
                          clr.b         exitfirst
                          clr.b         wallbounce
                          move.w        12(a0),d0
                          move.l        zoneAdds,a3
                          move.l        (a3,d0.w*4),a3
                          add.l         LEVELDATA,a3
                          move.l        a3,middleRoom
 
                          move.l        PlayerShotData,a3
                          move.w        4(a0),d0
                          ext.l         d0
                          asl.l         #7,d0
                          move.l        d0,oldy
 
                          moveq         #2,d5
                          move.w        #19,NUMTOCHECK
 
                          move.w        #3,d6

radiusloop:
                          move.w        #2,d7
 
DOFLAMES:
                          move.w        NUMTOCHECK,d1

.findonefree:
                          move.w        12(a3),d2
                          blt.s         .foundonefree
                          adda.w        #64,a3
                          dbra          d1,.findonefree
                          rts

.foundonefree:
                          move.w        d1,NUMTOCHECK

                          add.w         #1,doneflames
                          move.w        middlex,d1
                          move.w        middlez,d2
                          move.w        d1,oldx
                          move.w        d2,oldz
                          move.b        objInTop(a0),StoodInTop
 
                          jsr           GetRand
                          ext.w         d0
                          muls          d5,d0
                          asr.w         #1,d0
                          bne.s         .xnz
                          moveq         #2,d0

.xnz:
                          add.w         d0,d1
                          jsr           GetRand
                          ext.w         d0
                          muls          d5,d0
                          asr.w         #1,d0
                          bne.s         .znz
                          moveq         #2,d0

.znz: 
                          add.w         d0,d2
                          move.l        oldy,d3
                          jsr           GetRand
                          muls          d5,d0
                          asr.l         #3,d0
                          add.l         d0,d3
                          move.l        d3,newy
 
                          move.w        d1,newx
                          move.w        d2,newz
                          move.l        middleRoom,objroom
 

                          movem.l       d5/d6/a0/a1/a3/d7/a6,-(a7)
                          move.w        #80,extlen
                          move.b        #1,awayfromwall
                          jsr           MoveObject
                          movem.l       (a7)+,d5/d6/a0/a1/a3/d7/a6
 
                          move.l        objroom,a2
                          move.w        (a2),12(a3)

                          move.l        newy,d0

                          move.l        ToZoneFloor(a2),d1
                          move.l        ToZoneRoof(a2),d2
                          tst.b         objInTop(a0)
                          beq.s         .okinbot
                          move.l        ToUpperFloor(a2),d1
                          move.l        ToUpperRoof(a2),d2

.okinbot:
                          cmp.l         d0,d1
                          bgt.s         .abovefloor
                          move.l        d1,d0

.abovefloor: 
                          cmp.l         d0,d2
                          blt.s         .belowroof
                          move.l        d2,d0
 
.belowroof:
                          move.l        d0,accypos(a3)
                          asr.l         #7,d0
                          move.w        d0,4(a3)
                          move.b        #2,16(a3)
                          move.b        #5,shotanim(a3)
                          sub.b         d5,shotanim(a3)
                          st            shotstatus(a3)
                          move.b        StoodInTop,objInTop(a3)
                          move.b        #2,shotsize(a3)
                          st            objWorry(a3)
                          move.w        (a3),d0
                          move.l        ObjectPoints,a2
                          move.w        newx,(a2,d0.w*8)
                          move.w        newz,4(a2,d0.w*8)
 
                          adda.w        #64,a3
 
                          dbra          d7,DOFLAMES
                          add.w         #1,d5
                          dbra          d6,radiusloop
 
                          rts

*********************************************************************************************

middleRoom:               dc.l          0
middlex:                  dc.w          0
middlez:                  dc.w          0
doneflames:               dc.w          0

*********************************************************************************************

TESTAB:                   ds.l          200

*********************************************************************************************