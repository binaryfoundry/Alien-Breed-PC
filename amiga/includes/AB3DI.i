*********************************************************************************************

                          IFND       AB3DI_i
AB3DI_i                  EQU 1

*********************************************************************************************

                          incdir     "includes"

*********************************************************************************************
; Exec

                          include    "funcdef.i"
                          include    "exec/exec_lib.i"

*********************************************************************************************
; Dos

                          include    "lvo/dos_lib.i"

;  >= v36 
_LVODosNameFromAnchor    equ -852

*********************************************************************************************
; Graphics
  
                          include    "lvo/graphics_lib.i"

*********************************************************************************************
; Intuition

                          include    "lvo/intuition_lib.i"

*********************************************************************************************
 ; lowlevel.library

                          include    "lvo/lowlevel_lib.i"

*********************************************************************************************
; Custom chips 

                          include    "hardware/custom.i"

vhposrl                  EQU $007

serdatrl                 EQU $019 

intreqrl                 EQU $01F 

cop1lch                  equ $080
cop1lcl                  equ $082
cop2lch                  equ $084
cop2lcl                  equ $086

aud0vol                  equ $0a8
aud1vol                  equ $0b8
aud2vol                  equ $0c8
aud3vol                  equ $0d8

spr0pth                  equ $120
spr0ptl                  equ $122
spr1pth                  equ $124
spr1ptl                  equ $126
spr2pth                  equ $128
spr2ptl                  equ $12a
spr3pth                  equ $12c
spr3ptl                  equ $12e
spr4pth                  equ $130
spr4ptl                  equ $132
spr5pth                  equ $134
spr5ptl                  equ $136
spr6pth                  equ $138
spr6ptl                  equ $13a
spr7pth                  equ $13c
spr7ptl                  equ $13e
spr0ctl                  equ $142
spr1ctl                  equ $14a
spr2ctl                  equ $152
spr3ctl                  equ $15a
spr4ctl                  equ $162
spr5ctl                  equ $16a
spr6ctl                  equ $172
spr7ctl                  equ $17a
spr0pos                  equ $140
spr1pos                  equ $148
spr2pos                  equ $150
spr3pos                  equ $158
spr4pos                  equ $160
spr5pos                  equ $168
spr6pos                  equ $170
spr7pos                  equ $178

bpl1pth                  equ $0e0
bpl1ptl                  equ $0e2
bpl2pth                  equ $0e4
bpl2ptl                  equ $0e6
bpl3pth                  equ $0e8
bpl3ptl                  equ $0ea
bpl4pth                  equ $0ec
bpl4ptl                  equ $0ee
bpl5pth                  equ $0f0
bpl5ptl                  equ $0f2
bpl6pth                  equ $0f4
bpl6ptl                  equ $0f6
bpl7pth                  equ $0f8
bpl7ptl                  equ $0fa
bpl8pth                  equ $0fc
bpl8ptl                  equ $0fe

; +--------+-------------+-------------+-------------+-------------+
; | BIT#   | 15,14,13,12 | 11,10,09,08 | 07,06,05,04 | 03,02,01,00 |
; +--------+-------------+-------------+-------------+-------------+
; | LOCT=0 | T  X  X  X  | R7 R6 R5 R4 | G7 G6 G5 G4 | B7 B6 B5 B4 |
; | LOCT=1 | X  X  X  X  | R3 R2 R1 R0 | G3 G2 G1 G0 | B3 B2 B1 B0 |
; +--------+-------------+-------------+-------------+-------------+
; 
; T = TRANSPARENCY, R = RED, G = GREEN, B = BLUE, X = UNUSED
; 
; T bit of COLOR00 thru COLOR31 sets ZD_pin HI, When that color is
;   selected in all video modes.
; 
; SEE ALSO: BPLCON3 for color bank switching, LOCT-bit and
; using transparency bit with a Genlock

color00                  equ $180
color01                  equ $182
color02                  equ $184
color03                  equ $186
color04                  equ $188
color05                  equ $18a
color06                  equ $18c
color07                  equ $18e
color08                  equ $190
color09                  equ $192
color10                  equ $194
color11                  equ $196
color12                  equ $198
color13                  equ $19a
color14                  equ $19c
color15                  equ $19e

*********************************************************************************************
; AB3DI Game constants
; k/j/m
; 4/8
; s/x
; b/n

maxscrdiv                EQU 8
max3ddiv                 EQU 5

scrwidth                 EQU 104                                                                                          
scrheight                EQU 80 

fromPtOffset             EQU 10
widthOffset              EQU 104*4                                                                                          
midOffset                EQU 104*4*40 

copperNOP                EQU $01fe0000

playerheight             EQU 12*1024
playercrouched           EQU 8*1024

*********************************************************************************************

TextScrSize              EQU 10240*4
LevelDataSize            EQU 120000
LevelGraphicsSize        EQU 50000
LevelClipsSize           EQU 40000

*********************************************************************************************

TitleScrAddrSize         EQU 10240*7
OptSprAddrSize           EQU 258*16*5
PanelSize                EQU 30720

*********************************************************************************************

FloorTileSize            EQU 65536

*********************************************************************************************

PlayerMaxEnergy          EQU 127

*********************************************************************************************

                          endc  