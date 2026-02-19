*********************************************************************************************

                          opt     P=68020

*********************************************************************************************

TextCop:

                          dc.w    intreq,$8030     ; SET 4 = COPER, 5 = VERTB

                          dc.w    spr0ptl
txs0l:                    dc.w    0
                          dc.w    spr0pth
txs0h:                    dc.w    0
                          dc.w    spr1ptl
txs1l:                    dc.w    0
                          dc.w    spr1pth
txs1h:                    dc.w    0
                          dc.w    spr2ptl
txs2l:                    dc.w    0
                          dc.w    spr2pth
txs2h:                    dc.w    0
                          dc.w    spr3ptl
txs3l:                    dc.w    0
                          dc.w    spr3pth
txs3h:                    dc.w    0
                          dc.w    spr4ptl
txs4l:                    dc.w    0
                          dc.w    spr4pth
txs4h:                    dc.w    0
                          dc.w    spr5ptl
txs5l:                    dc.w    0
                          dc.w    spr5pth
txs5h:                    dc.w    0
                          dc.w    spr6ptl
txs6l:                    dc.w    0
                          dc.w    spr6pth
txs6h:                    dc.w    0
                          dc.w    spr7ptl
txs7l:                    dc.w    0
                          dc.w    spr7pth
txs7h:                    dc.w    0

                          dc.w    bplcon4,$0088
                          dc.w    fmode,$000f
                          dc.w    diwstrt,$2c81    ; Top left corner of screen.
                          dc.w    diwstop,$2cc1    ; Bottom right corner of screen.
                          dc.w    ddfstrt,$38      ; Data fetch start.
                          dc.w    ddfstop,$c8      ; Data fetch stop.

                          dc.w    bplcon0
TSCP:                     dc.w    $9201

                          dc.w    bplcon3
                          dc.w    $0c40

                          dc.w    $2a01,$ff00

                          dc.w    color00
TXTBGCOL:                 dc.w    0
                          dc.w    color01
TOPLET:
TXTCOLL:                  dc.w    0
                          dc.w    color02
BOTLET:                   dc.w    0
                          dc.w    color03
ALLTEXT:                  dc.w    $fff

                          dc.w    bplcon3,$0e40

                          dc.w    color03
ALLTEXTLOW:               dc.w    $0

                          dc.w    bpl1pth
TSPTh:                    dc.w    0
                          dc.w    bpl1ptl
TSPTl:                    dc.w    0
                          dc.w    bpl2pth
TSPTh2:                   dc.w    0
                          dc.w    bpl2ptl
TSPTl2:                   dc.w    0
 
                          dc.w    bpl1mod,0
                          dc.w    bpl2mod,0

                          dc.w    $ffff,$fffe      ; End of copper list


*********************************************************************************************