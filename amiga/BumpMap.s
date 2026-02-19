*********************************************************************************************

                          opt           P=68020

*********************************************************************************************

                          incdir        "includes"
                          include       "AB3DI.i"
                          include       "macros.i"

*********************************************************************************************

BumpMap:

                          tst.b         smoothbumps
                          bne           SmoothMap

                          move.w        ConstCol,d0
                          move.w        (a1,d0.w*2),a2
                          move.w        #0,a2

                          tst.w         above
                          beq           bumpthefloor
 
                          move.l        #24*128,d0
                          divs          dst,d0
                          subq          #1,d0
                          blt.s         ordinary
                          beq.s         OneBelow
                          subq.w        #2,d0
                          blt           TwoBelow
                          beq           ThreeBelow
                          subq.w        #2,d0
                          blt           FourBelow
                          beq           FiveBelow
                          subq.w        #2,d0
                          blt           SixBelow
                          beq           SevenBelow
                          subq.w        #2,d0
                          blt           EightBelow
                          beq           NineBelow
                          subq          #2,d0
                          blt           TenBelow
                          beq           ElevenBelow
                          bra           TwelveBelow
                          rts
  
****************************************************************
 
OneBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts
 
****************************************************************
 
TwoBelow:

                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*2(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
ThreeBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*3(a3)       ; 104*12
                          move.w        a2,widthOffset*2(a3)                ; 104*8
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
FourBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
FiveBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
SixBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforehigh
                          move.w        (a1,d0.w*2),widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforehigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
SevenBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
EightBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
NineBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
TenBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*10(a3)
                          move.w        a2,widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)

**********************************************************
; move.w a2,widthOffset*2(a3)
; move.w a2,widthOffset(a3)
**********************************************************

                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*10(a3)
                          move.w        a2,widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)

**********************************************************
; move.w a2,widthOffset*2(a3)
; move.w a2,widthOffset(a3)
**********************************************************

                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
ElevenBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*11(a3)
                          move.w        a2,widthOffset*10(a3)
                          move.w        a2,widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)

**********************************************************                          
; move.w a2,widthOffset*3(a3)
; move.w a2,widthOffset*2(a3)
; move.w a2,widthOffset(a3)
**********************************************************

                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*11(a3)
                          move.w        a2,widthOffset*10(a3)
                          move.w        a2,widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)

**********************************************************
; move.w a2,widthOffset*3(a3)
; move.w a2,widthOffset*2(a3)
; move.w a2,widthOffset(a3)
**********************************************************

                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
TwelveBelow:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset*12(a3)
                          move.w        a2,widthOffset*11(a3)
                          move.w        a2,widthOffset*10(a3)
                          move.w        a2,widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)

**********************************************************
; move.w a2,widthOffset*4(a3)
; move.w a2,widthOffset*3(a3)
; move.w a2,widthOffset*2(a3)
; move.w a2,widthOffset(a3)
**********************************************************

                          moveq         #0,d0

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset*12(a3)
                          move.w        a2,widthOffset*11(a3)
                          move.w        a2,widthOffset*10(a3)
                          move.w        a2,widthOffset*9(a3)
                          move.w        a2,widthOffset*8(a3)
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)

**********************************************************
; move.w a2,widthOffset*4(a3)
; move.w a2,widthOffset*3(a3)
; move.w a2,widthOffset*2(a3)
; move.w a2,widthOffset(a3)
**********************************************************

                          moveq         #0,d0

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************

bumpthefloor:
                          move.l        #14*128,d0
                          divs          dst,d0
                          subq.w        #1,d0
                          blt           ordinary
                          beq.s         OneAbove
                          subq.w        #2,d0
                          blt           TwoAbove
                          beq           ThreeAbove
                          subq.w        #2,d0
                          blt           FourAbove
                          beq           FiveAbove
                          subq.w        #2,d0
                          blt           SixAbove
                          beq           SevenAbove

                          bra           EightAbove

                          moveq         #0,d0
                          rts

****************************************************************
 
OneAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset)(a3)
 
.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts
 
****************************************************************
 
TwoAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
ThreeAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
FourAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
FiveAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
SixAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*6)(a3)
                          move.w        a2,-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*6)(a3)
                          move.w        a2,-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
SevenAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*7)(a3)
                          move.w        a2,-(widthOffset*6)(a3)
                          move.w        a2,-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*7)(a3)
                          move.w        a2,-(widthOffset*6)(a3)
                          move.w        a2,-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
EightAbove:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),-(widthOffset*8)(a3)
                          move.w        a2,-(widthOffset*7)(a3)
                          move.w        a2,-(widthOffset*6)(a3)
                          move.w        a2,-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),-(widthOffset*8)(a3)
                          move.w        a2,-(widthOffset*7)(a3)
                          move.w        a2,-(widthOffset*6)(a3)
                          move.w        a2,-(widthOffset*5)(a3)
                          move.w        a2,-(widthOffset*4)(a3)
                          move.w        a2,-(widthOffset*3)(a3)
                          move.w        a2,-(widthOffset*2)(a3)
                          move.w        a2,-(widthOffset)(a3)

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

SmoothMap:
                          move.w        #0,a2

                          tst.w         above
                          beq           smooththefloor
 
                          move.l        #14*128,d0
                          divs          dst,d0
                          subq          #1,d0
                          blt           ordinary
                          beq.s         OneBelowS
                          subq.w        #2,d0
                          blt           TwoBelowS
                          beq           ThreeBelowS
                          subq.w        #2,d0
                          blt           FourBelowS
                          beq           FiveBelowS
                          subq.w        #2,d0
                          blt           SixBelowS
                          beq           SevenBelowS
; bra EightBelowS
                          rts
  
****************************************************************
 
OneBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),widthOffset(a3)
  
.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),widthOffset(a3)
 
.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross

                          SUPERVISOR    SetInstCacheFreezeOn
                          rts
 
****************************************************************
 
TwoBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
 
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBHH
                          move.w        a2,widthOffset*2(a3)

.BBHH:
                          move.w        a2,widthOffset(a3)
 
.BumpBeforeHigh:
.BBbumped:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAHH
                          move.w        a2,widthOffset*2(a3)

.BAHH: 
                          move.w        a2,widthOffset(a3)

.BumpAcrossHigh:
.BAbumped:
                          move.w        (a1,d0.w*2),(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
ThreeBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBL
 
                          move.w        a2,widthOffset*3(a3)

.BBL:
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BBB

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBB
                          move.w        a2,widthOffset(a3)
 
.BBB:
                          move.w        a2,(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh

                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAL
 
                          move.w        a2,widthOffset*3(a3)

.BAL:
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BAB

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAB
                          move.w        a2,widthOffset(a3)
 
.BAB:
                          move.w        a2,(a3)

                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
FourBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBL
 
                          move.w        a2,widthOffset*4(a3)

.BBL:
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BBB

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBB
                          move.w        a2,widthOffset(a3)
 
.BBB:
                          move.w        a2,(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh

                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAL
 
                          move.w        a2,widthOffset*4(a3)

.BAL:
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BAB

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAB
                          move.w        a2,widthOffset(a3)
 
.BAB:
                          move.w        a2,(a3)

                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
FiveBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBL
 
                          move.w        a2,widthOffset*5(a3)

.BBL:
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BBB

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBB
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
 
.BBB:
                          move.w        a2,(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh

                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAL
 
                          move.w        a2,widthOffset*5(a3)

.BAL:
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BAB

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAB
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
 
.BAB:
                          move.w        a2,(a3)

                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross

tstend:
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************
 
SixBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBL
 
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)

.BBL:
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BBB

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBB
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
 
.BBB:
                          move.w        a2,(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh

                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAL
 
                          move.w        a2,widthOffset*6(a3)
                          move.w        a2,widthOffset*5(a3)

.BAL:
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BAB

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAB
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
 
.BAB:
                          move.w        a2,(a3)

                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************

SevenBelowS:
                          moveq         #0,d0
                          dbra          d7,.BumpAcross
 
.BumpBefore:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpBeforeHigh
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBL
 
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)

.BBL:
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BBB

.BumpBeforeHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BBB
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
 
.BBB:
                          move.w        a2,(a3)
                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d6,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 
                          bra.s         .Bumppast1
 
.BumpAcross:
                          and.w         d1,d5
                          move.b        (a0,d5.w*4),d0
                          blt.s         .BumpAcrossHigh

                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAL
 
                          move.w        a2,widthOffset*7(a3)
                          move.w        a2,widthOffset*6(a3)

.BAL:
                          move.w        a2,widthOffset*5(a3)
                          move.w        a2,widthOffset*4(a3)
                          move.w        a2,widthOffset*3(a3)
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
                          bra.s         .BAB

.BumpAcrossHigh:
                          move.w        (a1,d0.w*2),a2
                          lsr.b         #1,d0
                          bcc.s         .BAB
                          move.w        a2,widthOffset*2(a3)
                          move.w        a2,widthOffset(a3)
 
.BAB:
                          move.w        a2,(a3)

                          addq          #4,a3
                          add.w         a4,d3
                          addx.l        d2,d5
                          dbcs          d7,.BumpAcross
                          dbcc          d7,.BumpBefore
                          bcc.s         .Bumppast1
                          add.w         #256,d5 

.Bumppast1:
                          move.w        d4,d7
                          bne.s         .notdoneyet
                          rts

.notdoneyet:
                          cmp.w         #32,d7
                          ble.s         .notoowide
                          move.w        #32,d7

.notoowide:
                          sub.w         d7,d4  
                          addq          #4,a3
 
                          dbra          d7,.BumpAcross
                          SUPERVISOR    SetInstCacheFreezeOn
                          rts

****************************************************************

smooththefloor:
                          move.l        #14*128,d0
                          divs          dst,d0
                          subq.w        #1,d0
                          blt           ordinary
; beq.s OneAbove
                          subq.w        #2,d0
; blt TwoAbove
; beq ThreeAbove
                          subq.w        #2,d0
; blt FourAbove
; beq FiveAbove
                          subq.w        #2,d0
; blt SixAbove
; beq SevenAbove

; bra EightAbove

                          moveq         #0,d0
                          rts

*********************************************************************************************