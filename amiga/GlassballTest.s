*********************************************************************************************
; Test glass routine
*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                                     
*********************************************************************************************

                          SECTION    GlassCode,CODE_F

*********************************************************************************************
; scrwidth  104                                                                                          
; scrheight 80 
; = 8320 chunky pixels
; Glassball data: skip = $FFBF 

TestGlassball:  

                          move.l     #WorkSpace,a0
                          move.l     fromPt,a2                 ; Copper chunky

; 1. Copy current screen to work space (4*16*32*2 = 4096 chunky pixels)

                          move.w     #widthOffset,d3
                          move.w     #1,d6                  

ribl:
                          move.w     #31,d0                

readInto:
                          move.w     #15,d1                 
                          move.l     a2,a1

readIntoDown:
                          move.w     (a1),(a0)+
                          adda.w     d3,a1
                          move.w     (a1),(a0)+
                          adda.w     d3,a1
                          move.w     (a1),(a0)+
                          adda.w     d3,a1
                          move.w     (a1),(a0)+
                          adda.w     d3,a1

                          dbra       d1,readIntoDown

                          addq       #4,a2
                          dbra       d0,readInto

                          addq       #4,a2
                          dbra       d6,ribl

; End of part 1
; We now have the screen in a buffer for squidging.
; 2. Bend workspace chunky pixels and write to screen (4*16*32*2 = 4096 chunky pixels))

                          move.l     fromPt,a2                 ; Copper chunky
                          move.l     #WorkSpace,a0
                          move.l     glassballPtr,a3


                          move.w     #$fff,d7
                          move.w     #1,d6

rfbl:
                          move.w     #31,d0

readOutFrom:
                          move.w     #15,d1
                          move.l     a2,a1                                      

                          move.w     #0,d5

readOutFromDown:
                          move.w     (a3)+,d2                  ; 1
                          beq.s      nono3                          
                          cmp.w      #$FFBF,d2
                          beq.s      nono1
                          
                          move.w     (a0,d2.w*2),d2
                          and.w      d7,d2
                          move.w     d2,(a1)

nono1:
                          addq       #1,d5
                          add.w      d3,a1


                          move.w     (a3)+,d2                  ; 2
                          beq.s      nono3                          
                          cmp.w      #$FFBF,d2
                          beq.s      nono2

                          move.w     (a0,d2.w*2),d2
                          and.w      d7,d2
                          move.w     d2,(a1)

nono2:
                          addq       #1,d5
                          add.w      d3,a1


                          move.w     (a3)+,d2                  ; 3
                          beq.s      nono3
                          cmp.w      #$FFBF,d2
                          beq.s      nono3

                          move.w     (a0,d2.w*2),d2
                          and.w      d7,d2
                          move.w     d2,(a1)

nono3:
                          addq       #1,d5
                          add.w      d3,a1


                          move.w     (a3)+,d2                  ; 4
                          beq.s      nono3
                          cmp.w      #$FFBF,d2
                          beq.s      nono4

                          move.w     (a0,d2.w*2),d2
                          and.w      d7,d2
                          move.w     d2,(a1)

nono4:
                          addq       #1,d5
                          add.w      d3,a1

                          dbra       d1,readOutFromDown

                          addq       #4,a2
                          dbra       d0,readOutFrom

                          addq       #4,a2
                          dbra       d6,rfbl

; end of part 2

                          move.l     glassballPtr,d0
                          add.l      #64*64*2,d0
                          cmp.l      #endOfGlassballData,d0
                          blt        notOffGlass

                          move.l     #glassballData,d0

notOffGlass:
                          move.l     d0,glassballPtr
 
noglass:
                          rts

*********************************************************************************************