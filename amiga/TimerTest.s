*********************************************************************************************
; Test timer routine
*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                                     
*********************************************************************************************

                          SECTION    TimerCode,CODE_F

*********************************************************************************************

SetupCopperForTimerTest:

                          move.l     #timerScr,d0
                          move.w     d0,p1l
                          swap       d0
                          move.w     d0,p1h
                          clr.l      d0
                          move.w     #-24,d0
                          move.w     d0,pMod1
                          move.w     d0,pMod2

                          move.w     #$9201,Panelcon
                          
                          rts

*********************************************************************************************

InitTimer:

                          move.l     #0,timeCount
                          move.l     #0,numTimes
                          clr.b      counting                                                             
                          clr.b      oktodisplay

                          rts

*********************************************************************************************

StartCount:

                          move.l     d0,-(a7)
                          lea        $dff000,a6
                          move.l     vposr(a6),d0
                          and.l      #$1ffff,d0
                          move.l     d0,oldtime
                          st         counting
                          move.l     (a7)+,d0
                          rts

*********************************************************************************************

StopCount:

                          move.l     d0,-(a7)
                          lea        $dff000,a6
                          move.l     vposr(a6),d0
                          and.l      #$1ffff,d0
 
                          sub.l      oldtime,d0
                          cmp.l      #-256,d0
                          bge.s      okcount
                          add.l      #313*256,d0

okcount:
                          add.l      d0,timeCount
                          addq.l     #1,numTimes
                          clr.b      counting
                          move.l     (a7)+,d0
                          rts

*********************************************************************************************

StopCountNoAdd:

                          move.l     d0,-(a7)
                          lea        $dff000,a6
                          move.l     vposr(a6),d0
                          and.l      #$1ffff,d0
 
                          sub.l      oldtime,d0
                          cmp.l      #-256,d0
                          bge.s      okcount2
                          add.l      #313*256,d0

okcount2:
                          add.l      d0,timeCount
                          clr.b      counting
                          move.l     (a7)+,d0
                          rts

*********************************************************************************************

StopTimer:

                          st         oktodisplay
                          rts

*********************************************************************************************

TimerInterruptHandler: 

                          tst.b      counting
                          beq        noStopCounter
                          bsr        StopCountNoAdd

noStopCounter:
                          tst.b      oktodisplay
                          beq        dontshowtime
                          
                          clr.b      oktodisplay 
                          move.l     #timerScr+17+24*8,a0
                          move.l     timeCount,d0
                          bge.s      timenotneg
                          move.l     #1111*256,d0

timenotneg:
                          asr.l      #8,d0
                          move.l     #digits,a1
                          move.w     #7,d2

digitlop:
                          divs       #10,d0
                          swap       d0
                          lea        (a1,d0.w*8),a2
                          move.b     (a2)+,(a0)
                          move.b     (a2)+,24(a0)
                          move.b     (a2)+,24*2(a0)
                          move.b     (a2)+,24*3(a0)
                          move.b     (a2)+,24*4(a0)
                          move.b     (a2)+,24*5(a0)
                          move.b     (a2)+,24*6(a0)
                          move.b     (a2)+,24*7(a0)
                          subq       #1,a0
                          swap       d0
                          ext.l      d0
                          dbra       d2,digitlop

                          move.l     #timerScr+17+24*18,a0
                          move.l     numTimes,d0
                          move.l     #digits,a1
                          move.w     #3,d2

digitlop2:
                          divs       #10,d0
                          swap       d0
                          lea        (a1,d0.w*8),a2
                          move.b     (a2)+,(a0)
                          move.b     (a2)+,24(a0)
                          move.b     (a2)+,24*2(a0)
                          move.b     (a2)+,24*3(a0)
                          move.b     (a2)+,24*4(a0)
                          move.b     (a2)+,24*5(a0)
                          move.b     (a2)+,24*6(a0)
                          move.b     (a2)+,24*7(a0)
                          subq       #1,a0
                          swap       d0
                          ext.l      d0
                          dbra       d2,digitlop2

                          move.l     #timerScr+17+24*28,a0
                          moveq      #0,d0
                          move.w     FramesToDraw,d0
                          move.l     #digits,a1
                          move.w     #2,d2

digitlop3:
                          divs       #10,d0
                          swap       d0
                          lea        (a1,d0.w*8),a2
                          move.b     (a2)+,(a0)
                          move.b     (a2)+,24(a0)
                          move.b     (a2)+,24*2(a0)
                          move.b     (a2)+,24*3(a0)
                          move.b     (a2)+,24*4(a0)
                          move.b     (a2)+,24*5(a0)
                          move.b     (a2)+,24*6(a0)
                          move.b     (a2)+,24*7(a0)
                          subq       #1,a0
                          swap       d0
                          ext.l      d0
                          dbra       d2,digitlop3

dontshowtime:          
                          rts


*********************************************************************************************

StartCounting:
                          tst.b      counting
                          beq.b      .nostartcounter1
                          bsr        StartCount
                          
.nostartcounter1:
                          rts

*********************************************************************************************

numTimes:                 dc.l       0
timeCount:                dc.l       0
oldtime:                  dc.l       0
counting:                 dc.b       0
oktodisplay:              dc.b       0
                          even

*********************************************************************************************

maxBot:                   dc.w       0
tstNeg:                   dc.l       0

*********************************************************************************************

digits:                   incbin     "data/fonts/numbers"
                          even

*********************************************************************************************
*********************************************************************************************

                          SECTION    TestData,DATA_C

*********************************************************************************************

timerScr:                 ds.b       80*96                    ; 40*64
                          even    

*********************************************************************************************