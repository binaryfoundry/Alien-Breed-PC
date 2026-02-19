*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"

                          include    "exec/memory.i"

*********************************************************************************************

InitCopperScrn:

 *********************************************************************
; View setup

                          move.l     copScrn1,a1
                          move.l     copScrn2,a2
                          move.l     copScrnBuff,a3

                          move.l     #(scrwidth*scrheight)-1,d0        ; Copper view size 104*4*80
                          move.l     #copperNOP,d1                     ; Copper NOP
              
clrCop:
                          move.l     d1,(a1)+                          ; +4
                          move.l     d1,(a2)+                          ; +4
                          move.l     d1,(a3)+                          ; +4
                          dbra       d0,clrCop
 
 **********************************************************
              ; add.l #widthOffset*scrheight,a1
              ; add.l #widthOffset*scrheight,a2
**********************************************************

*********************************************************************
; Panel setup

                          move.l     #$01060c42,(a1)+                  ; BPLCON3
                          move.l     #$01060c42,(a2)+                  ; BPLCON3

                          move.w     #$0080,(a1)+                      ; cop1lch
                          move.w     #$0080,(a2)+                      ; cop1lch

                          move.l     #PanelCop,d0
                          swap       d0
                          move.w     d0,(a1)+
                          move.w     d0,(a2)+
                          move.w     #$0082,(a1)+                      ; cop1lcl
                          move.w     #$0082,(a2)+                      ; cop1lcl
                          swap       d0
                          move.w     d0,(a1)+
                          move.w     d0,(a2)+

                          move.l     #$00880000,(a1)+                  ; copjmp1
                          move.l     #$00880000,(a2)+                  ; copjmp1
  
                          clr.b      bigSmall
                          jsr        PutInSmallScr
  
                          rts

*********************************************************************************************

PutInLargeScr:

                          move.l     #$1000000,statskip
                          move.l     #$fffffffe,statskip+4

***************************************************************************
; Copper chunky lines

                          move.l     #HealthPal,a5
                          move.l     copScrn1,a0
                          move.l     copScrn2,a2
                          move.w     #scrheight-1,d0                   ; ie. 80
                          moveq      #0,d6
                          move.w     #0,d3
                          move.w     #$29df,startwait
                          move.w     #$2b01,endwait

.fillcop:
                          move.l     a0,a1
                          move.l     a2,a3
                          move.w     #$10c,(a1)+                       ; bplcon4     
                          move.w     #$10c,(a3)+                       ; bplcon4
                          move.w     d3,(a1)+
                          move.w     d3,(a3)+
                          eor.w      #$8000,d3

                          move.w     #$106,(a1)+                       ; bplcon3
                          move.w     #$106,(a3)+                       ; bplcon3
                          move.w     #$2c42,d5
                          or.w       d3,d5
                          and.w      #$fffe,d5
                          move.w     d5,(a1)+
                          move.w     d5,(a3)+
                          bsr        do32                              ; 32 Color register (32*8=256)

                          move.w     #$106,(a1)+                       ; bplcon3
                          move.w     #$106,(a3)+                       ; bplcon3
                          move.w     #$4c42,d5
                          or.w       d3,d5
                          and.w      #$fffe,d5
                          move.w     d5,(a1)+
                          move.w     d5,(a3)+
                          bsr        do32                              ; 32 Color register (32*8=256)

                          move.w     #$106,(a1)+                       ; bplcon3
                          move.w     #$106,(a3)+                       ; bplcon3
                          move.w     #$6c42,d5
                          or.w       d3,d5
                          and.w      #$fffe,d5
                          move.w     d5,(a1)+
                          move.w     d5,(a3)+
                          bsr        do32                              ; 32 Color register (32*8=256)
 
                          move.w     startwait,(a1)+
                          move.w     #$fffe,(a1)+

                          move.w     endwait,(a1)+
                          move.w     #$ff00,(a1)+

                          move.w     startwait,(a3)+
                          move.w     #$fffe,(a3)+

                          move.w     endwait,(a3)+
                          move.w     #$ff00,(a3)+

**********************************************************
                        ; move.l $1fe0000,(a1)+
                        ; move.l $1fe0000,(a3)+
                        ; move.l $1fe0000,(a1)+
                        ; move.l $1fe0000,(a3)+
 **********************************************************

                          add.w      #$300,startwait
                          add.w      #$300,endwait

**********************************************************
                        ; move.l #$1060c42,(a1)+
                        ; move.l #$1060c42,(a3)+
                        ; move.w #$19e,(a1)+
                        ; move.w (a5),(a1)+
                        ; move.w #$19e,(a3)+
                        ; move.w (a5)+,(a3)+
**********************************************************

                          adda.w     #widthOffset,a0
                          adda.w     #widthOffset,a2
                          dbra       d0,.fillcop

***************************************************************************

                          move.w     #$38,fetchstart
                          move.w     #$b8,fetchstop
                          move.w     #$2c81,winstart
                          move.w     #$2cc1,winstop
                          move.w     #-40,modulo
                          move.w     #-40,modulo+4

***************************************************************************
; Clear sprites 

                          move.l     #nullSpr,d0
                          move.w     d0,s0l
                          move.w     d0,s1l
                          move.w     d0,s2l
                          move.w     d0,s3l
                          move.w     d0,s4l
                          move.w     d0,s5l
                          move.w     d0,s6l
                          move.w     d0,s7l
                          swap       d0
                          move.w     d0,s0h
                          move.w     d0,s1h
                          move.w     d0,s2h
                          move.w     d0,s3h
                          move.w     d0,s4h
                          move.w     d0,s5h
                          move.w     d0,s6h
                          move.w     d0,s7h 
 
***************************************************************************
; Create bitplane pattern

                          move.l     #scrn+40,a0
                          move.l     #scrn+160,a1
                          move.l     #scrn+280,a2
                          move.l     #scrnTab,a3
                          move.w     #319,d7                           ; counter
                          move.w     #0,d1                             ; xpos

.plotScrnLoop:
                          move.b     (a3)+,d0
                          move.w     d1,d2
                          asr.w      #3,d2
                          move.b     d1,d3
                          not.b      d3
                          bclr.b     d3,-40(a0,d2.w)
                          bclr.b     d3,(a0,d2.w)
                          bclr.b     d3,40(a0,d2.w)
                          bclr.b     d3,-40(a1,d2.w)
                          bclr.b     d3,(a1,d2.w)
                          bclr.b     d3,40(a1,d2.w)
                          bclr.b     d3,-40(a2,d2.w)
                          btst       #0,d0
                          beq.s      .nobp1
                          bset.b     d3,-40(a0,d2.w)

.nobp1:
                          btst       #1,d0
                          beq.s      .nobp2
                          bset.b     d3,(a0,d2.w)

.nobp2:
                          btst       #2,d0
                          beq.s      .nobp3
                          bset.b     d3,40(a0,d2.w)

.nobp3:
                          btst       #3,d0
                          beq.s      .nobp4
                          bset.b     d3,-40(a1,d2.w)

.nobp4:
                          btst       #4,d0
                          beq.s      .nobp5
                          bset.b     d3,(a1,d2.w)

.nobp5:
                          btst       #5,d0
                          beq.s      .nobp6
                          bset.b     d3,40(a1,d2.w)

.nobp6:
                          btst       #6,d0
                          beq.s      .nobp7
                          bset.b     d3,-40(a2,d2.w)

.nobp7:
                          addq       #1,d1
                          dbra       d7,.plotScrnLoop

***************************************************************************

                          rts

*********************************************************************************************

PutInSmallScr:

                          move.l     #$1fe0000,statskip
                          move.l     #$1fe0000,statskip+4

***************************************************************************
; Copper chunky lines

                          move.l     #HealthPal,a5
                          move.l     copScrn1,a0                       ; filled with CopNop
                          move.l     copScrn2,a2
                          move.w     #scrheight-1,d0                   ; ie. 80-1
                          moveq      #0,d6
                          move.w     #0,d3
                          move.w     #$2bdf,startwait
                          move.w     #$2d01,endwait

.fillcop:
                          move.l     a0,a1
                          move.l     a2,a3

                          move.w     #bplcon4,(a1)+                    ; bplcon4 
                          move.w     #bplcon4,(a3)+                    ; bplcon4 
                          move.w     d3,(a1)+          
                          move.w     d3,(a3)+                          ; ->4
                          eor.w      #$8000,d3                         ; 

                        ; Copper pixel line

                        ; Bank 1
                          move.w     #bplcon3,(a1)+                    ; bplcon3  
                          move.w     #bplcon3,(a3)+                    ; bplcon3  
                          move.w     #$2c42,d5                         ; %00101100 01000010
                          or.w       d3,d5
                          and.w      #$fffe,d5
                          move.w     d5,(a1)+
                          move.w     d5,(a3)+                          ; ->8
                          bsr        do32                              ; 32 Color register (32*4=124)
                                                                               ; <= Note: fromPt ptr is first color value (10)
                        ; Bank 2
                          move.w     #bplcon3,(a1)+                    ; bplcon3  
                          move.w     #bplcon3,(a3)+                    ; bplcon3  
                          move.w     #$4c42,d5
                          or.w       d3,d5
                          and.w      #$fffe,d5
                          move.w     d5,(a1)+                                                              
                          move.w     d5,(a3)+                          ; ->12
                          bsr        do32                              ; 32 Color register (32*4=124)

                        ; Bank 3
                          move.w     #bplcon3,(a1)+                    ; bplcon3
                          move.w     #bplcon3,(a3)+                    ; bplcon3
                          move.w     #$6c42,d5
                          or.w       d3,d5
                          and.w      #$fffe,d5
                          move.w     d5,(a1)+
                          move.w     d5,(a3)+                          ; ->16
                          bsr        do32                              ; 32 Color register (32*4=124)
                          
                        ; => 96 color registers

                          move.w     #bplcon3,(a1)+                    ; bplcon3
                          move.w     #$0c42,(a1)+                      ; 1100 01000010
                          move.w     #bplcon3,(a3)+                    ; bplcon3
                          move.w     #$0c42,(a3)+                      ; 1100 01000010

                          move.w     #color15,(a1)+                              
                          move.w     (a5),(a1)+                        ; HealthPal
                          move.w     #color15,(a3)+
                          move.w     (a5)+,(a3)+                       ; ->24

                        ; = 124*3+24 => 396
                        ; skip to "fromPt" = 10 bytes : +(bplcon4.w + value.w + bplcon3.w + value.w + 180.w) -> value.w
                        ; skip from "fromPt" to "midpt" = CopLineSpace * (height/2) = (104*4)*40 = 16 640 
                        ; CopLineSpace = 416 bytes (416-396=20 CopNops)

                        ; Next copper pixel line
                          adda.w     #widthOffset,a0                   ; +416 (
                          adda.w     #widthOffset,a2                                                            
                          dbra       d0,.fillcop

***************************************************************************

                          move.w     #$48,fetchstart
                          move.w     #$88,fetchstop
                          move.w     #$2cb1,winstart
                          move.w     #$2c91,winstop
                          move.w     #-24,modulo
                          move.w     #-24,modulo+4

***************************************************************************
; Clear sprites 

                          move.l     #nullSpr,d0
                          move.w     d0,s4l
                          move.w     d0,s5l
                          move.w     d0,s6l
                          move.w     d0,s7l
                          swap       d0
                          move.w     d0,s4h
                          move.w     d0,s5h
                          move.w     d0,s6h
                          move.w     d0,s7h 

***************************************************************************

                          move.l     #borders,d0
                          move.w     d0,s0l
                          swap       d0
                          move.w     d0,s0h
                          move.l     #borders+2592,d0
                          move.w     d0,s1l
                          swap       d0
                          move.w     d0,s1h
                          move.l     #borders+2592*2,d0
                          move.w     d0,s2l
                          swap       d0
                          move.w     d0,s2h
                          move.l     #borders+2592*3,d0
                          move.w     d0,s3l
                          swap       d0
                          move.w     d0,s3h

***************************************************************************
; Create bitplane pattern

                          move.l     #scrn+40,a0
                          move.l     #scrn+160,a1
                          move.l     #scrn+280,a2
                          move.l     #smallScrnTab,a3
                          move.w     #191,d7                           ; counter
                          move.w     #0,d1                             ; xpos

.plotScrnLoop:
                          move.b     (a3)+,d0
                          move.w     d1,d2
                          asr.w      #3,d2
                          move.b     d1,d3
                          not.b      d3
                          bclr.b     d3,-40(a0,d2.w)
                          bclr.b     d3,(a0,d2.w)
                          bclr.b     d3,40(a0,d2.w)
                          bclr.b     d3,-40(a1,d2.w)
                          bclr.b     d3,(a1,d2.w)
                          bclr.b     d3,40(a1,d2.w)
                          bclr.b     d3,-40(a2,d2.w)
                          btst       #0,d0
                          beq.s      .nobp1
                          bset.b     d3,-40(a0,d2.w)

.nobp1:
                          btst       #1,d0
                          beq.s      .nobp2
                          bset.b     d3,(a0,d2.w)

.nobp2:
                          btst       #2,d0
                          beq.s      .nobp3
                          bset.b     d3,40(a0,d2.w)

.nobp3:
                          btst       #3,d0
                          beq.s      .nobp4
                          bset.b     d3,-40(a1,d2.w)

.nobp4:
                          btst       #4,d0
                          beq.s      .nobp5
                          bset.b     d3,(a1,d2.w)

.nobp5:
                          btst       #5,d0
                          beq.s      .nobp6
                          bset.b     d3,40(a1,d2.w)

.nobp6:
                          btst       #6,d0
                          beq.s      .nobp7
                          bset.b     d3,-40(a2,d2.w)

.nobp7:
                          addq       #1,d1
                          dbra       d7,.plotScrnLoop

***************************************************************************

                          rts

*********************************************************************************************

AllocCopperScrnMemory:
; Allocate copper screen & buffer memory

                          move.l     #MEMF_CHIP|MEMF_CLEAR,d1
                          move.l     #(widthOffset*scrheight)+16,d0
                          move.l     4.w,a6
                          jsr        _LVOAllocMem(a6)
                          move.l     d0,copScrn1
              
                          move.l     #MEMF_CHIP|MEMF_CLEAR,d1
                          move.l     #(widthOffset*scrheight)+16,d0
                          move.l     4.w,a6
                          jsr        _LVOAllocMem(a6)
                          move.l     d0,copScrn2

                          move.l     #MEMF_FAST|MEMF_CLEAR,d1
                          move.l     #(widthOffset*scrheight)+16,d0
                          move.l     4.w,a6
                          jsr        _LVOAllocMem(a6)
                          move.l     d0,copScrnBuff

                          rts

*********************************************************************************************

ReleaseCopperScrnMemory:
; Release copper screen & buffer memory

                          move.l     copScrn1,d1
                          beq        skipCopScr1

                          move.l     d1,a1
                          move.l     #(widthOffset*scrheight)+16,d0
                          move.l     4.w,a6
                          jsr        _LVOFreeMem(a6)
                          move.l     #0,copScrn1

skipCopScr1:
                          move.l     copScrn2,d1
                          beq        skipCopScr2

                          move.l     d1,a1
                          move.l     #(widthOffset*scrheight)+16,d0
                          move.l     4.w,a6
                          jsr        _LVOFreeMem(a6)
                          move.l     #0,copScrn2

skipCopScr2:
                          move.l     copScrnBuff,d1
                          beq        skipCopScrBuff

                          move.l     d1,a1
                          move.l     #(widthOffset*scrheight)+16,d0
                          move.l     4.w,a6
                          jsr        _LVOFreeMem(a6)
                          move.l     #0,copScrnBuff

skipCopScrBuff:
                          rts 

*********************************************************************************************

copScrn1:                 dc.l       0
copScrn2:                 dc.l       0
copScrnBuff:              dc.l       0

*********************************************************************************************