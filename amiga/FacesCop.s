*********************************************************************************************

                          opt        P=68020

*********************************************************************************************
               
                          incdir     "includes"

*********************************************************************************************

                          dc.w       color00,$fff
                          dc.w       $f801,$ff00
                          dc.w       color01,$0050
                          dc.w       $f901,$ff00
                          dc.w       color01,$0090
                          dc.w       $fa01,$ff00
                          dc.w       color01,$00f0
                          dc.w       $fb01,$ff00
                          dc.w       color01,$00f0
                          dc.w       $fc01,$ff00
                          dc.w       color01,$0090
                          dc.w       $fd01,$ff00
                          dc.w       color01,$0050
                          dc.w       $fe01,$ff00
                          dc.w       color01,$fff
                          dc.w       $ffdf,$fffe

***********************************************************

                          dc.w       $0a01,$ff00
                          
                          dc.w       ddfstrt,$48 
                          dc.w       ddfstop,$88 
                          dc.w       diwstrt,$2c81
                          dc.w       diwstop,$2cc1

                          dc.w       bplcon0
                          dc.w       $201 

                          dc.w       bpl1mod
                          dc.w       0 
                          dc.w       bpl2mod
                          dc.w       0 
         
                          dc.w       bplcon3
                          dc.w       $0
                          dc.w       bplcon4
                          dc.w       $0

*********************************************************************

                          include    "data/copper/faces2cols.s"

*********************************************************************
; Note: Inline include for BigFieldCop.s

                          dc.w       bpl1pth
f1h:                      dc.w       0
                          dc.w       bpl1ptl
f1l:                      dc.w       0

                          dc.w       bpl2pth
f2h:                      dc.w       0
                          dc.w       bpl2ptl
f2l:                      dc.w       0

                          dc.w       bpl3pth
f3h:                      dc.w       0
                          dc.w       bpl3ptl
f3l:                      dc.w       0

                          dc.w       bpl4pth
f4h:                      dc.w       0
                          dc.w       bpl4ptl
f4l:                      dc.w       0

                          dc.w       bpl5pth
f5h:                      dc.w       0
                          dc.w       bpl5ptl
f5l:                      dc.w       0
 
                          dc.w       $0c01,$ff00

                          dc.w       bplcon0
                          dc.w       $5201                         ; $201

*********************************************************************************************