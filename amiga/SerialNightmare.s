*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

PAUSE                     MACRO
                          move.l     #0,tstchip
                          move.l     #0,tstchip
                          move.l     #0,tstchip
                          move.l     #0,tstchip
                          move.l     #0,tstchip
                          move.l     #0,tstchip
                          move.l     #0,tstchip
                          ENDM

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                          include    "macros.i"
                          
                          include    "hardware/cia.i"

*********************************************************************************************

                          cnop       0,32

*********************************************************************************************
; sends the lower byte of d1 accross serial port corrupts bit 8 of d1

SERSEND:
; a6 = $dff000 
; in: d1.b = data
; red = waiting
; white = ready

.checkTBE:

                          btst.b     #5,serdatr(a6)       ; bit 13 = TBE (Serial port transmit buffer empty)
                          beq.b      .checkTBE            ; wait until last byte sent
         
                          and.w      #$00ff,d1
                          bset.l     #8,d1                ; add stop bit (8N1)
                          move.w     d1,serdat(a6)
                          move.w     #$0001,intreq(a6)    ; level 1 - bit 0 = TBE (Serial port transmit buffer empty)
         
                          rts

*********************************************************************************************
; waits for serial data and returns it in lower byte of d1

SERREC:
; a6 = $dff000  
; out: d1.b = data
; blue = waiting
; white = ready

.checkRBF:   

                          btst.b     #6,serdatr(a6)       ; bit 14 = RBF (Serial port receive buffer full)
                          beq.b      .checkRBF            ; wait util data available

                          move.w     serdatr(a6),d1
                          move.w     #$0800,intreq(a6)    ; level 5 - bit 11 = RBF (Serial port receive buffer full)
                          and.w      #$00ff,d1            ; 8N1

                          rts

*********************************************************************************************
; Sends and receives an interleaved long word from d0 into d0 (sends first)

SENDFIRST:
; in: d0.l = Data
; out: d0.l = Data

                          movem.l    d1-d7/a0-a6,-(a7)
                          lea        $dff000,a6

                          move.b     d0,d1
                          bsr        SERSEND
                          bsr        SERREC
                          move.b     d1,d2
                          ror.l      #8,d2
                          lsr.w      #8,d0
                          move.b     d0,d1
                          bsr        SERSEND
                          bsr        SERREC
                          move.b     d1,d2
                          ror.l      #8,d2
                          swap       d0
                          move.b     d0,d1
                          bsr        SERSEND
                          bsr        SERREC
                          move.b     d1,d2
                          ror.l      #8,d2
                          lsr.w      #8,d0
                          move.b     d0,d1
                          bsr        SERSEND
                          bsr        SERREC
                          move.b     d1,d2
                          ror.l      #8,d2
                          move.l     d2,d0

                          movem.l    (a7)+,d1-d7/a0-a6 
                          rts

*********************************************************************************************
; sends and receives an interleaved long word from d0 into d0 (receives first)
; in: d0.l = Data
; out: d0.l = Data

RECFIRST:

                          movem.l    d1-d7/a0-a6,-(a7)
                          lea        $dff000,a6

                          bsr        SERREC
                          move.b     d1,d2
                          move.b     d0,d1
                          bsr        SERSEND
                          ror.l      #8,d2
                          bsr        SERREC
                          move.b     d1,d2
                          lsr.w      #8,d0
                          move.b     d0,d1
                          bsr        SERSEND
                          ror.l      #8,d2
                          bsr        SERREC
                          move.b     d1,d2
                          swap       d0
                          move.b     d0,d1
                          bsr        SERSEND
                          ror.l      #8,d2
                          bsr        SERREC
                          move.b     d1,d2
                          lsr.w      #8,d0
                          move.b     d0,d1
                          bsr        SERSEND
                          ror.l      #8,d2
                          move.l     d2,d0

                          movem.l    (a7)+,d1-d7/a0-a6
                          rts

*********************************************************************************************
*********************************************************************************************
; Send with rts/cts, etc
; $bfd000 =>
; cts=4 <-> rts=6
; dsr=3 <-> dtr=7 - winuae?
;CIAB_COMDTR	  EQU	(7)   * serial Data Terminal Ready*
;CIAB_COMRTS	  EQU	(6)   * serial Request to Send*
;CIAB_COMCD	  EQU	(5)   * serial Carrier Detect*
;CIAB_COMCTS	  EQU	(4)   * serial Clear to Send*
;CIAB_COMDSR	  EQU	(3)   * serial Data Set Ready*


INITSEND:

                          move.l     #$bfd000,a0
                          move.w     #15,d7
                          move.l     #$bfe001,a3
                          rts

*********************************************************************************************

SENDLONG:

                          bset       #CIAB_COMRTS,(a0)
                          PAUSE
                          WT
                          move.w     d7,d6

SENDLOOP:
                          add.l      d0,d0
                          bcc.s      SENDZERO
                          bset       #CIAB_COMDTR,(a0)
                          bra.s      SEND1

SENDZERO:
                          bclr       #CIAB_COMDTR,(a0)

SEND1:
                          PAUSE
                          bclr       #CIAB_COMRTS,(a0)
                          PAUSE
                          WTNOT
                          add.l      d0,d0
                          bcc.s      SENDZERO2
                          bset       #CIAB_COMDTR,(a0)
                          bra.s      SEND12

SENDZERO2:
                          bclr       #CIAB_COMDTR,(a0)

SEND12:
                          PAUSE
                          bset       #CIAB_COMRTS,(a0)
                          PAUSE
                          WT
                          dbra       d6,SENDLOOP

                          bclr       #CIAB_COMDTR,(a0)
                          bclr       #CIAB_COMRTS,(a0)

balls:
                          btst       #CIAB_COMDSR,(a0)
                          beq.s      balls

                          rts

*********************************************************************************************

SENDLAST:

                          bset       #CIAB_COMRTS,(a0)
                          PAUSE
                          WT
                          move.w     d7,d6

SENDLOOPLAST:
                          add.l      d0,d0
                          bcc.s      SENDZEROLAST
                          bset       #CIAB_COMDTR,(a0)
                          bra.s      SEND1LAST

SENDZEROLAST:
                          bclr       #CIAB_COMDTR,(a0)

SEND1LAST:
                          PAUSE
                          bclr       #CIAB_COMRTS,(a0)
                          PAUSE
                          WTNOT

                          add.l      d0,d0
                          bcc.s      SENDZERO2LAST
                          bset       #CIAB_COMDTR,(a0)
                          bra.s      SEND12LAST

SENDZERO2LAST:
                          bclr       #CIAB_COMDTR,(a0)

SEND12LAST:
                          PAUSE
                          bset       #CIAB_COMRTS,(a0)
                          PAUSE
                          WT
                          dbra       d6,SENDLOOPLAST

                          bset       #CIAB_COMDTR,(a0)
                          PAUSE
                          bclr       #CIAB_COMRTS,(a0)
                          PAUSE

ballsLAST:
                          btst       #CIAB_COMDSR,(a0)
                          beq.s      ballsLAST

                          rts

*********************************************************************************************

INITREC:

                          move.l     #$bfd000,a0
                          move.l     #BUFFER,a1
                          move.w     #15,d7
                          move.l     #$bfe001,a3
                          rts

*********************************************************************************************

BACKRECEIVE:

                          PAUSE
                          bclr       #CIAB_COMRTS,(a0)
                          PAUSE
                          bset       #CIAB_COMDTR,(a0)
                          move.l     d0,(a1)+
 
RECEIVE:
; d0.l = data

                          PAUSE
                          WT
                          bclr.b     #CIAB_COMDTR,(a0)
                          move.w     d7,d6

RECIEVELOOP:
                          bset       #CIAB_COMRTS,(a0)
                          PAUSE
                          WTNOT
                          add.l      d0,d0
                          btst       #CIAB_COMDSR,(a0)
                          beq.s      noadd1
                          addq       #1,d0

noadd1:
                          PAUSE
                          bclr       #CIAB_COMRTS,(a0)
                          PAUSE
                          WT
                          PAUSE
                          add.l      d0,d0
                          btst       #CIAB_COMDSR,(a0)
                          beq.s      noadd2
                          addq       #1,d0

noadd2:
                          dbra       d6,RECIEVELOOP
                          PAUSE
                          bset       #CIAB_COMRTS,(a0)
                          PAUSE
                          WTNOT
                          PAUSE
                          btst       #CIAB_COMDSR,(a0)
                          beq        BACKRECEIVE
                          PAUSE
                          bset       #CIAB_COMDTR,(a0)
                          bclr       #CIAB_COMRTS,(a0)
                          move.l     d0,(a1)+

                          rts

*********************************************************************************************

BUFFER:                   ds.l       2000

*********************************************************************************************

tstchip:                  dc.l       0

*********************************************************************************************