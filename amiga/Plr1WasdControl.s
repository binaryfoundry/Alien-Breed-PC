*********************************************************************************************

                          opt       P=68020

*********************************************************************************************
; Inline source
; For : Plr1Control.s
; Description : Plr1 mouse+keyboard control (activate by 'n' -> 'wasd' move + mouse angle + lmb fire + rmb space)
*********************************************************************************************
; Definitions

Plr1WalkSpeed       EQU 2 
Plr1RunSpeed        EQU 3
Plr1MouseActinDelay EQU 15

****************************************************************
; Mouse

                          jsr       ReadMouse

                          move.l    #SineTable,a0
                          move.w    PLR1s_angspd,d1
                          move.w    angpos,d0
                          and.w     #8190,d0
                          move.w    d0,PLR1s_angpos
                          move.w    (a0,d0.w),PLR1s_sinval
                          adda.w    #2048,a0
                          move.w    (a0,d0.w),PLR1s_cosval

****************************************************************

                          tst.b     PLR1_fire
                          beq.s     .firenotpressedPlr1MouseLMB
; fire was pressed last time.
                          btst      #6,$bfe001
                          bne.s     .firenownotpressedPlr1MouseLMB
; fire is still pressed this time.
                          st        PLR1_fire
                          bra       .donePLR1MouseLMB
 
.firenownotpressedPlr1MouseLMB:
; fire has been released.
                          clr.b     PLR1_fire
                          bra       .donePLR1MouseLMB
 
.firenotpressedPlr1MouseLMB:
; fire was not pressed last frame...
                          btst      #6,$bfe001
; if it has still not been pressed, go back above
                          bne.s     .firenownotpressedPlr1MouseLMB
; fire was not pressed last time, and was this time, so has
; been clicked.
                          st        PLR1_clicked
                          st        PLR1_fire

.donePLR1MouseLMB:

****************************************************************

                          move.w    $dff016,d0
                          btst      #10,d0
                          bne.s     .donePLR1MouseRMB

                          move.w    PLR1_msbActinDelay,d1
                          sub.w     #1,d1
                          bpl.s     .donePLR1MouseRMB
                          st        PLR1_SPCTAP
                          move.w    #Plr1MouseActinDelay,d1

.donePLR1MouseRMB:
                          move.w    d1,PLR1_msbActinDelay

****************************************************************
; Kbd

                          move.l    #SineTable,a0
                          move.l    #KeyMap,a5
                          move.l    #0,d7

                          move.w    PLR1s_angspd,d3
                          move.w    #Plr1WalkSpeed,d2
                          moveq     #0,d7

                          tst.b     $60(a5)                           ; Left shift (run_key)
                          beq.s     .nofasterPlr1Kbd

                          move.w    #Plr1RunSpeed,d2

.nofasterPlr1Kbd:
                          tst.b     PLR1_Ducked
                          beq.s     .nohalvePlr1Kbd
                          asr.w     #1,d2

.nohalvePlr1Kbd:
                          moveq     #0,d4 
                  
                          move.w    d3,d5
                          add.w     d5,d5
                          add.w     d5,d3
                          asr.w     #2,d3
                          bge.s     .nnegPlr1Kbd
                          addq      #1,d3

.nnegPlr1Kbd:

                          tst.b     $20(a5)                           ; A
                          beq.s     noleftslidePlr1Kbd
                          add.w     d2,d4
                          add.w     d2,d4
                          asr.w     #1,d4

noleftslidePlr1Kbd:
                          tst.b     $22(a5)                           ; D
                          beq.s     norightslidePlr1Kbd
                          add.w     d2,d4
                          add.w     d2,d4
                          asr.w     #1,d4
                          neg.w     d4

norightslidePlr1Kbd:

                          move.l    PLR1s_xspdval,d6
                          move.l    PLR1s_zspdval,d7

                          neg.l     d6
                          ble.s     .nobug1Plr1Kbd
                          asr.l     #3,d6
                          add.l     #1,d6
                          bra.s     .bug1Plr1Kbd

.nobug1Plr1Kbd:
                          asr.l     #3,d6

.bug1Plr1Kbd:
                          neg.l     d7
                          ble.s     .nobug2Plr1Kbd
                          asr.l     #3,d7
                          add.l     #1,d7
                          bra.s     .bug2Plr1Kbd

.nobug2Plr1Kbd:
                          asr.l     #3,d7

.bug2Plr1Kbd: 
                          moveq     #0,d3
                          moveq     #0,d5

                          tst.b     $11(a5)                           ; W 
                          beq.s     noforwardPlr1Kbd
                          neg.w     d2
                          move.w    d2,d3
 
noforwardPlr1Kbd:
                          tst.b     $21(a5)                           ; S
                          beq.s     nobackwardPlr1Kbd
                          move.w    d2,d3

nobackwardPlr1Kbd:

****************************************************************

                          move.w    d3,d2
                          asl.w     #6,d2
                          move.w    d2,d1
                          move.w    d1,d2

                          add.w     PLR1_bobble,d1
                          and.w     #8190,d1
                          move.w    d1,PLR1_bobble

                          add.w     PLR1_clumptime,d2
                          move.w    d2,d1
                          and.w     #4095,d2
                          move.w    d2,PLR1_clumptime

                          and.w     #-4096,d1
                          beq.s     .noclumpPlr1Kbd

                          bsr       PLR1clump
 
.noclumpPlr1Kbd:

****************************************************************

                          move.w    PLR1s_sinval,d1
                          muls      d3,d1
                          move.w    PLR1s_cosval,d2
                          muls      d3,d2

                          sub.l     d1,d6
                          sub.l     d2,d7
                          move.w    PLR1s_sinval,d1
                          muls      d4,d1
                          move.w    PLR1s_cosval,d2
                          muls      d4,d2
                          sub.l     d2,d6
                          add.l     d1,d7
                  
                          add.l     d6,PLR1s_xspdval
                          add.l     d7,PLR1s_zspdval
                          move.l    PLR1s_xspdval,d6
                          move.l    PLR1s_zspdval,d7
                          add.l     d6,PLR1s_xoff
                          add.l     d7,PLR1s_zoff
 
.donePLR1Kbd:

****************************************************************

                          move.l    #KeyMap,a5
                          move.l    #0,d7

                          move.b    forward_key,d7
                          clr.b     (a5,d7.w)
                          move.b    backward_key,d7
                          clr.b     (a5,d7.w)

                          move.b    duck_key,d7
                          move.w    d7,-(a7) 
                          move.b    #$23,duck_key                     ; F

                          jsr       PLR1_alwayskeys

                          move.l    #0,d7
                          move.w    (a7)+,d7
                          move.b    d7,duck_key 

****************************************************************

                          bsr       Plr1Fall

*********************************************************************************************