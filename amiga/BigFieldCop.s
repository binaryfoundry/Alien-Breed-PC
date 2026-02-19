*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"

*********************************************************************************************

                          ifnd       ENABLEFACES
ENABLEFACES equ 0
                          endc

*********************************************************************************************

BigFieldCop:    
; Start of our game copper list

                          dc.w       dmacon,$8020                ; Enable sprite
                          dc.w       intreq,%1000000000110000    ; $8011 : SET 4=COPER, 5=VBLANK
                          dc.w       fmode,$000f
                          dc.w       diwstrt
winstart:                 dc.w       $2cb1
                          dc.w       diwstop
winstop:                  dc.w       $2c91
                          dc.w       ddfstrt
fetchstart:               dc.w       $48
                          dc.w       ddfstop
fetchstop:                dc.w       $88

*********************************************************************

borderCols:               incbin     "data/copper/borderpal"

*********************************************************************

                          dc.w       spr0ptl
s0l:                      dc.w       0
                          dc.w       spr0pth
s0h:                      dc.w       0
                          dc.w       spr1ptl
s1l:                      dc.w       0
                          dc.w       spr1pth
s1h:                      dc.w       0
                          dc.w       spr2ptl
s2l:                      dc.w       0
                          dc.w       spr2pth
s2h:                      dc.w       0
                          dc.w       spr3ptl
s3l:                      dc.w       0
                          dc.w       spr3pth
s3h:                      dc.w       0
                          dc.w       spr4ptl
s4l:                      dc.w       0
                          dc.w       spr4pth
s4h:                      dc.w       0
                          dc.w       spr5ptl
s5l:                      dc.w       0
                          dc.w       spr5pth
s5h:                      dc.w       0
                          dc.w       spr6ptl
s6l:                      dc.w       0
                          dc.w       spr6pth
s6h:                      dc.w       0
                          dc.w       spr7ptl
s7l:                      dc.w       0
                          dc.w       spr7pth
s7h:                      dc.w       0

                          dc.w       bplcon3,$0c42

*********************************************************************

                          incbin     "data/copper/borderpal"

*********************************************************************

                          dc.w       bplcon3,$8c42
                          dc.w       color00
hitcol:                   dc.w       $0
                          dc.w       bplcon3,$0c42
                          dc.w       color00
hitcol2:                  dc.w       0

                          dc.w       bplcon0,$7201
                          dc.w       bplcon1
smoff:                    dc.w       $0

                          dc.w       $108
modulo:                   dc.w       -24
                          dc.w       $10a
                          dc.w       -24

                          dc.w       bpl1pth
pl1h:                     dc.w       0
                          dc.w       bpl1ptl
pl1l:                     dc.w       0

                          dc.w       bpl2pth
pl2h:                     dc.w       0
                          dc.w       bpl2ptl
pl2l:                     dc.w       0

                          dc.w       bpl3pth
pl3h:                     dc.w       0
                          dc.w       bpl3ptl
pl3l:                     dc.w       0

                          dc.w       bpl4pth
pl4h:                     dc.w       0
                          dc.w       bpl4ptl
pl4l:                     dc.w       0

                          dc.w       bpl5pth
pl5h:                     dc.w       0
                          dc.w       bpl5ptl
pl5l:                     dc.w       0

                          dc.w       bpl6pth
pl6h:                     dc.w       0
                          dc.w       bpl6ptl
pl6l:                     dc.w       0
                          
                          dc.w       bpl7pth
pl7h:                     dc.w       0
                          dc.w       bpl7ptl
pl7l:                     dc.w       0

                          dc.w       $1001,$ff00
                          dc.w       intreq,%0000000000110000    ; $0011 : RESET 4=COPER, 5=VBLANK
                          
yposcop:                  dc.w       $2a11,$fffe
                          dc.w       copjmp2,0                   ; Chunky screen

; jump to chunky screen...
*********************************************************************


                          ; ds.l               104*12

; colbars:
; val                       SET                $2a

;                           dcb.l              scrwidth*scrheight,copperNOP
;                           dc.w               bplcon3,$c42
                         
;                           dc.w               $80
; pch1:                     dc.w               0
;                           dc.w               $82
; pcl1:                     dc.w               0 
                           
;                           dc.w               $88,0
                           
;                           dc.w               $ffff,$fffe                                                          ; End copper list.

;                           ds.l               104*12

; colbars2:

; val                       SET                $2a

;                           dcb.l              scrwidth*scrheight,copperNOP                          
;                           dc.w               bplcon3,$c42
                           
;                           dc.w               $80
; pch2:                     dc.w               0
;                           dc.w               $82
; pcl2:                     dc.w               0
                           
;                           dc.w               $88,0
                           
;                           dc.w               $ffff,$fffe                                                          ; End copper list.

;                           ds.l               104*10

*********************************************************************************************
; ..continue with panel:

PanelCop:

                          dc.w       cop1lch
och:                      dc.w       0
                          dc.w       cop1lcl
ocl:                      dc.w       0

statskip:                 dc.w       $1fe                        ; NOP (large/small screen)
                          dc.w       0
                          dc.w       $1fe                        ; NOP 
                          dc.w       0

                          dc.w       bplcon4
                          dc.w       0

                          dc.w       bplcon0
                          dc.w       $1201

                          dc.w       bpl1ptl
n1l:                      dc.w       0

                          dc.w       bpl1pth
n1h:                      dc.w       0

*********************************************************************

                          incbin     "data/copper/Panelpal"

*********************************************************************

                          dc.w       bpl2pth
p2h:                      dc.w       0
                          dc.w       bpl2ptl
p2l:                      dc.w       0

                          dc.w       bpl3pth
p3h:                      dc.w       0
                          dc.w       bpl3ptl
p3l:                      dc.w       0

                          dc.w       bpl4pth
p4h:                      dc.w       0
                          dc.w       bpl4ptl
p4l:                      dc.w       0

                          dc.w       bpl5pth
p5h:                      dc.w       0
                          dc.w       bpl5ptl
p5l:                      dc.w       0
                          dc.w       bpl6pth

p6h:                      dc.w       0
                          dc.w       bpl6ptl
p6l:                      dc.w       0

                          dc.w       bpl7pth
p7h:                      dc.w       0
                          dc.w       bpl7ptl
p7l:                      dc.w       0

                          dc.w       bpl8pth
p8h:                      dc.w       0
                          dc.w       bpl8ptl
p8l:                      dc.w       0
 
                          dc.w       ddfstrt,$38
                          dc.w       ddfstop,$b8
                          dc.w       diwstrt,$2c81
                          dc.w       diwstop,$2cc1
 
                          dc.w       bplcon0
Panelcon:                 dc.w       $0211

                          dc.w       bpl1mod
pMod1:                    dc.w       40*7
                          dc.w       bpl2mod
pMod2:                    dc.w       40*7

                          dc.w       bpl1pth
p1h:                      dc.w       0
                          dc.w       bpl1ptl
p1l:                      dc.w       0

*********************************************************************

                          IFNE       ENABLEFACES
                          include    "FacesCop.s"
                          ENDC

*********************************************************************

                          dc.w       $ffff,$fffe                 ; End of copper list
                          cnop       0,64

*********************************************************************************************