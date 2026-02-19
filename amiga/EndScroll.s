*********************************************************************************************
; The game has been finished!
;
; Deallocate all memory, ask for scroll screen memory. Load end of game music (whatever that is).
; Print top 16 lines of text then fade up.
; After a few seconds, scroll it upwards with the text following....
*********************************************************************************************

                          opt                P=68020

*********************************************************************************************

                          incdir             "includes"
                          include            "AB3DI.i"
                          include            "macros.i"

*********************************************************************************************

EndGameScroll:

                          lea                KeyMap,a5
                          clr.b              $45(a5)                       ; Esc
            
                          move.w             #14,LINESLEFTTOSCROLL
                          move.w             #0,DONEXTLINE
                          move.w             #3,scrolldownaline
                          move.w             #0,SCROLLPOS
                          move.l             #0,SCROLLPT
                          move.l             #0,OLDSCROLL
                          move.w             #0,NEXTLINE
                          move.w             #0,LASTLINE

*********************************************************

                          move.l             TEXTSCRN,d0
                          move.w             d0,TSPTl
                          swap               d0
                          move.w             d0,TSPTh
                          swap               d0
                          move.w             d0,TSPTl2
                          swap               d0
                          move.w             d0,TSPTh2

*********************************************************

                          move.w             #$0,TXTCOLL
                          move.w             #$0,BOTLET
                          move.w             #$0,ALLTEXT
                          move.w             #$0,ALLTEXTLOW
                          move.w             #$0,TXTBGCOL

                          lea                $dff000,a6                    ; a6 points at the first custom chip register.

                          move.l             #TextCop,cop1lch(a6)          ; Point the copper at our copperlist.
                          move.w             #$a201,TSCP                   ; Bitplane control register 0
                          move.w             #$20,beamcon0(a6)             ; 5 = PAL

*********************************************************
; Cleanup

                          bsr                ClearScreen                 
   
*********************************************************
; Still text

                          move.l             #ENDGAMETEXT,a0
                          move.w             #0,d0
                          moveq              #15,d7

PUTONS:
                          move.l             TEXTSCRN,a1
                          bsr                DrawLineOfText 
                          add.w              #82,a0
                          addq               #1,d0
                          dbra               d7,PUTONS
 
*********************************************************
; Text fade

                          lea                $dff000,a6 
                          move.w             #$000,d0
                          move.w             #15,d1

fdup2:
                          move.w             #15,d3
                          move.w             #0,d2

fdup3:
                          move.w             d0,ALLTEXT
                          move.w             d2,ALLTEXTLOW
                          add.w              #$111,d2

                          WAITFORVERTBREQ

                          dbra               d3,fdup3
                          add.w              #$111,d0

skipBgCol:
                          dbra               d1,fdup2
                    
*********************************************************
; Text delay

                          lea                $dff000,a6 
                          move.w             #300,d3

fdupwt:
                          move.l             #KeyMap,a5                                                           
                          tst.b              $45(a5)                       ; (esc) Exit key
                          bne                ExitEndScroll
                    
                          WAITFORVERTBREQ
                          dbra               d3,fdupwt
 
*********************************************************
; Init BG music

                          move.l             #endGame,mt_data                         
                          st                 UseAllChannels
                          clr.b              reachedend
                          jsr                mt_init

*********************************************************
; Scroll loop

                          move.w             #0,SCROLLPOS
                          move.l             #ENDOFGAMESCROLL,SCROLLPT
                          move.l             #ENDOFGAMESCROLL,OLDSCROLL
                          move.w             #17,NEXTLINE
                          move.w             #16,LASTLINE

SCROLLINGLOOP:
                          move.l             #KeyMap,a5                                                           
                          tst.b              $45(a5)                       ; (esc) Exit key
                          bne                ExitEndScroll

                          lea                $dff000,a6 
                          WAITFORVERTBREQ

                          jsr                mt_music

                          bsr                DoTheScroll

                          bra                SCROLLINGLOOP

*********************************************************************************************
; Pixel scroll 

DoTheScroll:

                          move.w             TOPLET,d0                     
                          move.w             BOTLET,d1
                          sub.w              #$222,d1
                          add.w              #$222,d0
                          move.w             d0,TOPLET
                          move.w             d1,BOTLET

**************************************************************

                          sub.w              #1,scrolldownaline
                          bgt                skipScrolling

**************************************************************

                          move.w             #$333,TOPLET
                          move.w             #$ccc,BOTLET

**************************************************************
; Pixel scroll counter

                          sub.w              #1,LINESLEFTTOSCROLL
                          bgt.s              .NONOTHERLINE

                          move.w             #16,LINESLEFTTOSCROLL

                          move.b             LazyAssHack,d0
                          beq.b              .NONOTHERLINE

                          move.w             #0,d0                  
                          bsr                ClearLineOfText
                          move.b             d0,LazyAssHack 

.NONOTHERLINE:

**************************************************************
; Handle upper text line

                          cmp.w              #16,LINESLEFTTOSCROLL
                          bne.b              .SkipNewTextLineUpper

                          bsr                UpdateTextLineCounter
                          bsr                NewUpperLine

.SkipNewTextLineUpper:

******************************************************************
; Bitmap scroll

                          move.w             SCROLLPOS,d0
                          move.w             d0,d1
                          add.w              #1,d0
                          and.w              #255,d0                       ; y=256px -> 16px height line * 16 pcs
                          move.w             d0,SCROLLPOS

******************************************************************
; Delayd lower line?

                          move.w             SCROLLPOS,d3
                          cmp.b              #254,d3
                          bne.b              noDelayForLowerLine
                          move.b             #1,DelayLowerLine

noDelayForLowerLine:

******************************************************************
; Pixel scroll 

                          muls               #80,d0                        ; x=640px
                          muls               #80,d1                         
                    
                          add.l              TEXTSCRN,d0
                          add.l              TEXTSCRN,d1
                    
                          move.w             d0,TSPTl
                          swap               d0
                          move.w             d0,TSPTh

                          move.w             d1,TSPTl2
                          swap               d1
                          move.w             d1,TSPTh2

******************************************************************
; Handle delayed lower text line               

                          move.l             DELAYDSCRPT,d0
                          beq.b              skipNewDelaydLine
                    
                          move.w             SCROLLPOS,d0
                          cmp.w              #1,d0
                          bne.b              skipNewDelaydLine

                          bsr                NewDelaydLowerLine
                          clr.l              DELAYDSCRPT
                          clr.w              DELAYDNEXTLINE

skipNewDelaydLine:

******************************************************************
; Handle lower text line

                          cmp.w              #16,LINESLEFTTOSCROLL
                          bne.b              SkipNewTextLineLower

                          move.b             DelayLowerLine,d0
                          beq.b              skipDelaySetup

                          move.l             SCROLLPT,DELAYDSCRPT
                          move.w             NEXTLINE,DELAYDNEXTLINE
                          clr.b              DelayLowerLine

skipDelaySetup:
                          move.l             DELAYDSCRPT,d0
                          bne.b              skipLine

                          bsr                NewLowerLine

skipLine:
                          bsr                UpdateScreenCounter

SkipNewTextLineLower:

******************************************************************
; Reset vblank delay counter

                          move.w             #3,scrolldownaline
 
skipScrolling:
                          rts

*********************************************************************************************

UpdateScreenCounter:

                          move.w             NEXTLINE,d0                   ; Lower
                          sub.w              #16,d0
                          move.w             d0,LASTLINE                   ; Upper
                          add.w              #1,d0
                          and.w              #15,d0                        ; %1111 -> 17 -> 1
                          add.w              #16,d0
                          move.w             d0,NEXTLINE

                          rts

*********************************************************************************************

UpdateTextLineCounter:

                          move.l             SCROLLPT,a0                   ; a0=Scroll text ptr
                          move.l             a0,OLDSCROLL
                    
                          tst.b              (a0)
                          blt.s              .notex

                          add.w              #80,a0

.notex:
                          adda.w             #2,a0                         ; ControlCodes+TextInLine=2+80
                          cmp.l              #ENDOFEND,a0                  ; End of text
                          blt.s              .nostartscroll

                          move.l             #ENDOFGAMESCROLL,a0

.nostartscroll:
                          move.l             a0,SCROLLPT                   ; a0=Scroll text ptr

                          rts

*********************************************************************************************

NewUpperLine:

                          move.l             OLDSCROLL,a0
                          move.w             LASTLINE,d0
                          move.l             TEXTSCRN,a1

                          bsr                ClearLineOfText
                          tst.b              (a0)
                          blt.s              okitsatwo
                          bsr                DrawLineOfText

okitsatwo:
                          rts

*********************************************************************************************

NewLowerLine:

                          move.l             SCROLLPT,a0
                          move.w             NEXTLINE,d0
                          move.l             TEXTSCRN,a1

                          bsr                ClearLineOfText
                          tst.b              (a0)
                          blt.s              okEmptyLine
                          bsr                DrawLineOfText

okEmptyLine:
                          rts

*********************************************************************************************

NewDelaydLowerLine:

                          move.l             DELAYDSCRPT,a0
                          move.w             DELAYDNEXTLINE,d0             
                          move.l             TEXTSCRN,a1

                          bsr                ClearLineOfText
                          tst.b              (a0)
                          blt.s              okitsaline
                          bsr                DrawLineOfText

okitsaline:
                          rts

*********************************************************************************************

ExitEndScroll: 

                          bsr                ClearScreen

                          jsr                mt_end

                          move.w             #0,TXTBGCOL

                          move.l             TEXTSCRN,d0
                          move.w             d0,TSPTl
                          swap               d0
                          move.w             d0,TSPTh

                          move.w             #0,TSPTl2
                          move.w             #0,TSPTh2

                          move.w             #$9201,TSCP

                          lea                KeyMap,a5 
                          clr.b              $45(a5)
                          rts

*********************************************************************************************

ClearLineOfText:
; d0 = row
                          move.l             d0,-(a7)
 
                          muls               #80*16,d0
                          moveq              #0,d1
                          move.l             TEXTSCRN,a2
                          add.l              d0,a2
                          move.w             #(20*2),d0

CLRIT:
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          move.l             d1,(a2)+
                          dbra               d0,CLRIT
 
                          move.l             (a7)+,d0
                          rts

*********************************************************************************************

ClearScreen:

                          bsr                ClrWeenScrn                   ; 10240

                          add.l              #10240,TEXTSCRN               ; *4
                          bsr                ClrWeenScrn                   

                          add.l              #10240,TEXTSCRN
                          bsr                ClrWeenScrn                   

                          add.l              #10240,TEXTSCRN
                          bsr                ClrWeenScrn                   

                          sub.l              #3*10240,TEXTSCRN
                          rts

*********************************************************************************************

LINESLEFTTOSCROLL:        dc.w               14

*********************************************************************************************

DONEXTLINE:               dc.w               0
scrolldownaline:          dc.w               3
SCROLLPOS:                dc.w               0
SCROLLPT:                 Dc.l               0
OLDSCROLL:                dc.l               0
NEXTLINE:                 dc.w               0
LASTLINE:                 dc.w               0

*********************************************************************************************

DelayLowerLine:           dc.w               0
DELAYDSCRPT:              dc.l               0
DELAYDNEXTLINE:           dc.w               0

LazyAssHack:              dc.b               1                    
                          even

*********************************************************************************************