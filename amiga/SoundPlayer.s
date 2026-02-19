*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                          include    "Macros.i"

*********************************************************************************************

                          ifnd       ENABLETIMER
ENABLETIMER equ 0
                          endc

*********************************************************************************************

swappedem:                dc.w       0

*********************************************************************************************
; Called from coppper interrrupt

newSampBitl:
                          lea        $dff000,a6
                          move.w     #$820f,dmacon(a6)                          ; Enable audio + master
                          move.w     #$200,intreq(a6)                           ; 9 = AUD2
 
                    ; tst.b CHANNELDATA
                    ; bne nochannel0
 
                          move.l     pos0LEFT,a0
                          move.l     pos2LEFT,a1

                          move.l     #tab,a2
 
                          moveq      #0,d0
                          moveq      #0,d1
                          move.b     vol0left,d0
                          move.b     vol2left,d1
                          cmp.b      d1,d0
                          slt        swappedem
                          bge.s      fbig0

; d1 is bigger so scale d0 and use d1 as audiochannel volume.

                          exg        a0,a1
                          asl.w      #6,d0
                          divs       d1,d0
                          lsl.w      #8,d0
                          adda.w     d0,a2
                          move.w     d1,$dff0a8
                          bra.s      donechan0

fbig0:
                          tst.w      d0
                          beq.s      donechan0
                          asl.w      #6,d1
                          divs       d0,d1
                          lsl.w      #8,d1
                          adda.w     d1,a2
                          move.w     d0,$dff0a8

donechan0:
                          move.l     Aupt0,a3
                          move.l     a3,$dff0a0
                          move.l     Auback0,Aupt0
                          move.l     a3,Auback0
 
                          move.l     Auback0,a3
 
                          moveq      #0,d0
                          moveq      #0,d1
                          moveq      #0,d2
                          moveq      #0,d3
                          moveq      #0,d4
                          moveq      #0,d5
                          move.w     #49,d7

loop:
                          move.l     (a0)+,d0
                          move.b     (a1)+,d1
                          move.b     (a1)+,d2
                          move.b     (a1)+,d3
                          move.b     (a1)+,d4
                          move.b     (a2,d3.w),d5
                          swap       d5
                          move.b     (a2,d1.w),d5
                          asl.l      #8,d5
                          move.b     (a2,d2.w),d5
                          swap       d5
                          move.b     (a2,d4.w),d5
                          add.l      d5,d0
                          move.l     d0,(a3)+
                          dbra       d7,loop

                          tst.b      swappedem
                          beq.s      .ok23
                          exg        a0,a1

.ok23:
                          cmp.l      Samp0endLEFT,a0
                          blt.s      .notoffendsamp1
                          move.l     SampleList+6*8,a0
                          move.l     SampleList+6*8+4,Samp0endLEFT
                          move.b     #63,vol0left
                          st         LEFTCHANDATA+1
                          move.w     #0,LEFTCHANDATA+2

.notoffendsamp1:
                          cmp.l      Samp2endLEFT,a1
                          blt.s      .notoffendsamp2
                          move.l     #empty,a1
                          move.l     #emptyend,Samp2endLEFT
                          move.b     #0,vol2left
                          st         LEFTCHANDATA+1+8
                          move.w     #0,LEFTCHANDATA+2+8

.notoffendsamp2:
                          move.l     a0,pos0LEFT
                          move.l     a1,pos2LEFT

nochannel0:
                          tst.b      CHANNELDATA+16
                          bne        nochannel1

                          move.l     pos0RIGHT,a0
                          move.l     pos2RIGHT,a1

                          move.l     Aupt1,a3
                          move.l     a3,$dff0b0
                          move.l     Auback1,Aupt1
                          move.l     a3,Auback1

                          move.l     #tab,a2
 
                          moveq      #0,d0
                          moveq      #0,d1
                          move.b     vol0right,d0
                          move.b     vol2right,d1
                          cmp.b      d1,d0
                          slt        swappedem
                          bge.s      fbig1

; d1 is bigger so scale d0 and use d1 as audiochannel volume.

                          exg        a0,a1
                          asl.w      #6,d0
                          divs       d1,d0
                          lsl.w      #8,d0
                          adda.w     d0,a2
                          move.w     d1,$dff0b8
                          bra.s      donechan1

fbig1:
                          tst.w      d0
                          beq.s      donechan1
                          asl.w      #6,d1
                          divs       d0,d1
                          lsl.w      #8,d1
                          adda.w     d1,a2
                          move.w     d0,$dff0b8

donechan1:
                          moveq      #0,d0
                          moveq      #0,d1
                          moveq      #0,d2
                          moveq      #0,d3
                          moveq      #0,d4
                          moveq      #0,d5
                          move.w     #49,d7

loop2:
                          move.l     (a0)+,d0
                          move.b     (a1)+,d1
                          move.b     (a1)+,d2
                          move.b     (a1)+,d3
                          move.b     (a1)+,d4
                          move.b     (a2,d3.w),d5
                          swap       d5
                          move.b     (a2,d1.w),d5
                          asl.l      #8,d5
                          move.b     (a2,d2.w),d5
                          swap       d5
                          move.b     (a2,d4.w),d5
                          add.l      d5,d0
                          move.l     d0,(a3)+
                          dbra       d7,loop2
 
                          tst.b      swappedem
                          beq.s      ok01
                          exg        a0,a1

ok01:
                          cmp.l      Samp0endRIGHT,a0
                          blt.s      .notoffendsamp1
                          move.l     #empty,a0
                          move.l     #emptyend,Samp0endRIGHT
                          move.b     #0,vol0right
                          st         RIGHTCHANDATA+1
                          move.w     #0,RIGHTCHANDATA+2

.notoffendsamp1:
                          cmp.l      Samp2endRIGHT,a1
                          blt.s      .notoffendsamp2
                          move.l     #empty,a1
                          move.l     #emptyend,Samp2endRIGHT
                          move.b     #0,vol2right
                          st         RIGHTCHANDATA+1+8
                          move.w     #0,RIGHTCHANDATA+2+8

.notoffendsamp2:
                          move.l     a0,pos0RIGHT
                          move.l     a1,pos2RIGHT

nochannel1:
; Other two channels

                          move.l     pos1LEFT,a0
                          move.l     pos3LEFT,a1

                          move.l     #tab,a2
 
                          moveq      #0,d0
                          moveq      #0,d1
                          move.b     vol1left,d0
                          move.b     vol3left,d1
                          cmp.b      d1,d0
                          slt        swappedem
                          bge.s      fbig2

; d1 is bigger so scale d0 and use d1 as audiochannel volume.

                          exg        a0,a1
                          asl.w      #6,d0
                          divs       d1,d0
                          lsl.w      #8,d0
                          adda.w     d0,a2
                          move.w     d1,$dff0d8
                          bra.s      donechan2

fbig2:
                          tst.w      d0
                          beq.s      donechan2
                          asl.w      #6,d1
                          divs       d0,d1
                          lsl.w      #8,d1
                          adda.w     d1,a2
                          move.w     d0,$dff0d8

donechan2:
                          move.l     Aupt2,a3
                          move.l     a3,$dff0d0
                          move.l     Auback2,Aupt2
                          move.l     a3,Auback2
 
                          moveq      #0,d0
                          moveq      #0,d1
                          moveq      #0,d2
                          moveq      #0,d3
                          moveq      #0,d4
                          moveq      #0,d5
                          move.w     #49,d7

loop3:
                          move.l     (a0)+,d0
                          move.b     (a1)+,d1
                          move.b     (a1)+,d2
                          move.b     (a1)+,d3
                          move.b     (a1)+,d4
                          move.b     (a2,d3.w),d5
                          swap       d5
                          move.b     (a2,d1.w),d5
                          asl.l      #8,d5
                          move.b     (a2,d2.w),d5
                          swap       d5
                          move.b     (a2,d4.w),d5
                          add.l      d5,d0
                          move.l     d0,(a3)+
                          dbra       d7,loop3

                          tst.b      swappedem
                          beq.s      .ok23
                          exg        a0,a1

.ok23:
                          cmp.l      Samp1endLEFT,a0
                          blt.s      .notoffendsamp3
                          move.l     #empty,a0
                          move.l     #emptyend,Samp1endLEFT
                          move.b     #0,vol1left
                          st         LEFTCHANDATA+1+4
                          move.w     #0,LEFTCHANDATA+2+4

.notoffendsamp3:
                          cmp.l      Samp3endLEFT,a1
                          blt.s      .notoffendsamp4
                          move.l     #empty,a1
                          move.l     #emptyend,Samp3endLEFT
                          move.b     #0,vol3left
                          st         LEFTCHANDATA+1+12
                          move.w     #0,LEFTCHANDATA+2+12

.notoffendsamp4:
                          move.l     a0,pos1LEFT
                          move.l     a1,pos3LEFT
 
                          move.l     pos1RIGHT,a0
                          move.l     pos3RIGHT,a1

                          move.l     Aupt3,a3
                          move.l     a3,$dff0c0
                          move.l     Auback3,Aupt3
                          move.l     a3,Auback3

                          move.l     #tab,a2
 
                          moveq      #0,d0
                          moveq      #0,d1
                          move.b     vol1right,d0
                          move.b     vol3right,d1
                          cmp.b      d1,d0
                          slt        swappedem
                          bge.s      fbig3

                          exg        a0,a1
                          asl.w      #6,d0
                          divs       d1,d0
                          lsl.w      #8,d0
                          adda.w     d0,a2
                          move.w     d1,$dff0c8
                          bra.s      donechan3

fbig3:
                          tst.w      d0
                          beq.s      donechan3
                          asl.w      #6,d1
                          divs       d0,d1
                          lsl.w      #8,d1
                          adda.w     d1,a2
                          move.w     d0,$dff0c8

donechan3:
                          moveq      #0,d0
                          moveq      #0,d1
                          moveq      #0,d2
                          moveq      #0,d3
                          moveq      #0,d4
                          moveq      #0,d5
                          move.w     #49,d7

loop4:
                          move.l     (a0)+,d0
                          move.b     (a1)+,d1
                          move.b     (a1)+,d2
                          move.b     (a1)+,d3
                          move.b     (a1)+,d4
                          move.b     (a2,d3.w),d5
                          swap       d5
                          move.b     (a2,d1.w),d5
                          asl.l      #8,d5
                          move.b     (a2,d2.w),d5
                          swap       d5
                          move.b     (a2,d4.w),d5
                          add.l      d5,d0
                          move.l     d0,(a3)+
                          dbra       d7,loop4
 
                          tst.b      swappedem
                          beq.s      .ok23
                          exg        a0,a1

.ok23:
                          cmp.l      Samp1endRIGHT,a0
                          blt.s      notoffendsamp3
                          move.l     #empty,a0
                          move.l     #emptyend,Samp1endRIGHT
                          move.b     #0,vol1right
                          st         RIGHTCHANDATA+1+4
                          move.w     #0,RIGHTCHANDATA+2+4

notoffendsamp3:
                          cmp.l      Samp3endRIGHT,a1
                          blt.s      notoffendsamp4
                          move.l     #empty,a1
                          move.l     #emptyend,Samp3endRIGHT
                          move.b     #0,vol3right
                          st         RIGHTCHANDATA+1+12
                          move.w     #0,RIGHTCHANDATA+2+12

notoffendsamp4:
                          move.l     a0,pos1RIGHT
                          move.l     a1,pos3RIGHT

                          GETREGS

                          IFNE       ENABLETIMER
                          jsr        StartCounting
                          ENDC

                          moveq      #0,d0
                          rts

*********************************************************************************************
; 4 channel sound routine

fourchannel:

                          lea        $dff000,a6

                          btst       #7,intreqrl(a6)                            ; 7 = Audi 0 block not finnished
                          beq.s      nofinish0

                    ; move.w #0,LEFTCHANDATA+2
                    ; st LEFTCHANDATA+1

                          move.l     #null,$0a0(a6)                             ; aud0
                          move.w     #100,$0a4(a6)                              ; aud0 + ac_len  
                          move.w     #$0080,intreq(a6)                          ; 7 = aud0 block finnished
nofinish0:
 
                          tst.b      NoiseMade0pLEFT
                          beq.s      NoChan0sound

                          move.l     Samp0endLEFT,d0
                          move.l     pos0LEFT,d1
                          sub.l      d1,d0
                          lsr.l      #1,d0
                          move.w     d0,$a4(a6)
                          move.l     d1,$a0(a6)
                          move.w     #$8201,dmacon(a6)
                          moveq      #0,d0
                          move.b     vol0left,d0
                          move.w     d0,$a8(a6)

NoChan0sound:
                          btst       #0,intreqr(a6)                             ; 0 = AUD1
                          beq.s      nofinish1
                          move.l     #null,$b0(a6)
                          move.w     #100,$b4(a6)
                          move.w     #$0100,intreq(a6)                          ; 0 = AUD1

nofinish1:
                          tst.b      NoiseMade0pRIGHT
                          beq.s      NoChan1sound

                          move.l     Samp0endRIGHT,d0
                          move.l     pos0RIGHT,d1
                          sub.l      d1,d0
                          lsr.l      #1,d0
                          move.w     d0,$b4(a6)
                          move.l     d1,$b0(a6)
                          move.w     d0,playnull1
                          move.w     #$8202,dmacon(a6)
                          moveq      #0,d0
                          move.b     vol0right,d0
                          move.w     d0,$b8(a6)

NoChan1sound:
                          btst       #1,intreqr(a6)                             ; 0 = AUD2
                          beq.s      nofinish2
                          move.l     #null,$c0(a6)
                          move.w     #100,$c4(a6)
                          move.w     #$0200,intreq(a6)                          ; 0 = AUD2

nofinish2:
                          tst.b      NoiseMade1pRIGHT
                          beq.s      NoChan2sound

                          move.l     Samp1endRIGHT,d0
                          move.l     pos1RIGHT,d1
                          sub.l      d1,d0
                          lsr.l      #1,d0
                          move.w     d0,$c4(a6)
                          move.w     d0,playnull2
 
                          move.l     d1,$c0(a6)
                          move.w     #$8204,dmacon(a6)
                          moveq      #0,d0
                          move.b     vol1right,d0
                          move.w     d0,$c8(a6)

NoChan2sound:
                          btst       #2,intreqr(a6)                             ; 0 = AUD3
                          beq.s      nofinish3
                          move.l     #null,$d0(a6)
                          move.w     #100,$d4(a6)
                          move.w     #$0400,intreq(a6)                          ; 0 = AUD3

nofinish3:
                          tst.b      NoiseMade1pLEFT
                          beq.s      NoChan3sound

                          move.l     Samp1endLEFT,d0
                          move.l     pos1LEFT,d1
                          sub.l      d1,d0
                          lsr.l      #1,d0
                          move.w     d0,$d4(a6)
                          move.w     d0,playnull3
                          move.l     d1,$d0(a6)
                          move.w     #$8208,dmacon(a6)
                          moveq      #0,d0
                          move.b     vol1left,d0
                          move.w     d0,$d8(a6)
 
NoChan3sound:
nomorechannels:
                          move.l     NoiseMade0LEFT,NoiseMade0pLEFT
                          move.l     #0,NoiseMade0LEFT
                          move.l     NoiseMade0RIGHT,NoiseMade0pRIGHT
                          move.l     #0,NoiseMade0RIGHT

                    ; tst.b playnull0
                    ; beq.s .nnul
                    ; sub.b #1,playnull0
                    ; bra.s chan0still
                    ;.nnul:
                    ; 
                    ;chan0still:

                          tst.b      NoiseMade0pLEFT
                          bne.s      chan0still
                          tst.w      playnull0
                          beq.s      nnul0
                          sub.w      #100,playnull0
                          bra.s      chan0still

nnul0:
                          move.w     #0,LEFTCHANDATA+2
                          st         LEFTCHANDATA+1

chan0still:
                          tst.b      NoiseMade0pRIGHT
                          bne.s      chan1still
                          tst.w      playnull1
                          beq.s      nnul1
                          sub.w      #100,playnull1
                          bra.s      chan1still

nnul1:
                          move.w     #0,RIGHTCHANDATA+2
                          st         RIGHTCHANDATA+1

chan1still:
                          tst.b      NoiseMade1pRIGHT
                          bne.s      chan2still
                          tst.w      playnull2
                          beq.s      nnul2
                          sub.w      #100,playnull2
                          bra.s      chan2still

nnul2:
                          move.w     #0,RIGHTCHANDATA+2+4
                          st         RIGHTCHANDATA+1+4

chan2still:
                          tst.b      NoiseMade1pLEFT
                          bne.s      chan3still
                          tst.w      playnull3
                          beq.s      nnul3
                          sub.w      #100,playnull3
                          bra.s      chan3still

nnul3:
                          move.w     #0,LEFTCHANDATA+2+4
                          st         LEFTCHANDATA+1+4
 
chan3still:
                          GETREGS

                          IFNE       ENABLETIMER
                          jsr        StartCounting
                          ENDC

                          moveq      #0,d0
                          rts

*********************************************************************************************

backbeat:                 dc.w       0

playnull0:                dc.w       0
playnull1:                dc.w       0
playnull2:                dc.w       0
playnull3:                dc.w       0

*********************************************************************************************

Samp0endRIGHT:            dc.l       emptyend
Samp1endRIGHT:            dc.l       emptyend
Samp2endRIGHT:            dc.l       emptyend
Samp3endRIGHT:            dc.l       emptyend
Samp0endLEFT:             dc.l       emptyend
Samp1endLEFT:             dc.l       emptyend
Samp2endLEFT:             dc.l       emptyend
Samp3endLEFT:             dc.l       emptyend

Aupt0:                    dc.l       null
Auback0:                  dc.l       null+500
Aupt2:                    dc.l       null3
Auback2:                  dc.l       null3+500
Aupt3:                    dc.l       null4
Auback3:                  dc.l       null4+500
Aupt1:                    dc.l       null2
Auback1:                  dc.l       null2+500

NoiseMade0LEFT:           dc.b       0
NoiseMade1LEFT:           dc.b       0
NoiseMade2LEFT:           dc.b       0
NoiseMade3LEFT:           dc.b       0
NoiseMade0pLEFT:          dc.b       0
NoiseMade1pLEFT:          dc.b       0
NoiseMade2pLEFT:          dc.b       0
NoiseMade3pLEFT:          dc.b       0
NoiseMade0RIGHT:          dc.b       0
NoiseMade1RIGHT:          dc.b       0
NoiseMade2RIGHT:          dc.b       0
NoiseMade3RIGHT:          dc.b       0
NoiseMade0pRIGHT:         dc.b       0
NoiseMade1pRIGHT:         dc.b       0
NoiseMade2pRIGHT:         dc.b       0
NoiseMade3pRIGHT:         dc.b       0

empty:                    ds.l       100
emptyend:

*********************************************************************************************
; I want a routine to calculate all the info needed for the sound player to work, 
; given say position of noise, volume and sample number.

Samplenum:                dc.w       0
Noisex:                   dc.w       0
Noisez:                   dc.w       0
Noisevol:                 dc.w       0
chanpick:                 dc.w       0
IDNUM:                    dc.w       0
needleft:                 dc.b       0
needright:                dc.b       0
STEREO:                   dc.b       $0
                          even
 
CHANNELDATA:
LEFTCHANDATA:             dc.l       $00000000
                          dc.l       $00000000
                          dc.l       $FF000000
                          dc.l       $FF000000

RIGHTCHANDATA:            dc.l       $00000000
                          dc.l       $00000000
                          dc.l       $FF000000
                          dc.l       $FF000000
 
RIGHTPLAYEDTAB:           ds.l       20
LEFTPLAYEDTAB:            ds.l       20

*********************************************************************************************

MakeSomeNoise:

; Plan for new sound handler:
; It is sent a sample number,
; a position relative to the
; player, an id number and a volume.
; Also notifplaying.

; indirect inputs are the available
; channel flags and whether or not
; stereo sound is selected.

; the algorithm must decide
; whether the new sound is more
; important than the ones already
; playing. Thus an 'importance'
; must be calculated, probably
; using volume.

; The output needs to be:

; Write the pointers and volumes of
; the sound channels


                          tst.b      notifplaying
                          beq.s      dontworry

; find if we are already playing

                          move.b     IDNUM,d0
                          move.w     #7,d1
                          lea        CHANNELDATA,a3

findsameasme:
                          tst.b      (a3)
                          bne.s      notavail
                          cmp.b      1(a3),d0
                          beq.b      SameAsMe

notavail:
                          add.w      #4,a3
                          dbra       d1,findsameasme
                          bra.b      dontworry

SameAsMe:
                          rts

*********************************************************************************************

noiseloud:                dc.w       0

*********************************************************************************************

dontworry:

; Ok its fine for us to play a sound.
; So calculate left/right volume.

                          move.w     Noisex,d1
                          muls       d1,d1
                          move.w     Noisez,d2
                          muls       d2,d2
                          move.w     #64,d3
                          move.w     #32767,noiseloud
                          moveq      #1,d0
                          add.l      d1,d2
                          beq.b      pastcalc

                          move.w     #31,d0

.findhigh:
                          btst       d0,d2
                          bne.b      .foundhigh
                          dbra       d0,.findhigh

.foundhigh:
                          asr.w      #1,d0
                          clr.l      d3
                          bset       d0,d3
                          move.l     d3,d0

                          move.w     d0,d3
                          muls       d3,d3                                      ; x*x
                          sub.l      d2,d3                                      ; x*x-a
                          asr.l      #1,d3                                      ; (x*x-a)/2
                          divs       d0,d3                                      ; (x*x-a)/2x
                          sub.w      d3,d0                                      ; second approx
                          bgt.b      .stillnot0
                          move.w     #1,d0

.stillnot0:
                          move.w     d0,d3
                          muls       d3,d3
                          sub.l      d2,d3
                          asr.l      #1,d3
                          divs       d0,d3
                          sub.w      d3,d0                                      ; second approx
                          bgt.b      .stillnot02
                          move.w     #1,d0

.stillnot02:
                          move.w     Noisevol,d3
                          ext.l      d3
                          asl.l      #6,d3
                          cmp.l      #32767,d3
                          ble.s      .nnnn
                          move.l     #32767,d3

.nnnn:
                          asr.w      #2,d0
                          addq       #1,d0
                          divs       d0,d3
 
                          move.w     d3,noiseloud

                          cmp.w      #64,d3
                          ble.s      notooloud
                          move.w     #64,d3

notooloud:
pastcalc:
	; d3 contains volume of noise.
	
                          move.w     d3,d4
 
                          move.w     d3,d2
                          muls       Noisex,d2
                          asl.w      #3,d0
                          divs       d0,d2
 
                          bgt.s      quietleft
                          add.w      d2,d4
                          bge.s      donequiet
                          move.w     #0,d4
                          bra.s      donequiet

quietleft:
                          sub.w      d2,d3
                          bge.s      donequiet
                          move.w     #0,d3

donequiet:
; d3=leftvol?
; d4=rightvol?

                          clr.w      needleft

                          cmp.b      d3,d4
                          bgt.s      RightLouder
 
; Left is louder; is it MUCH louder?

                          st         needleft
                          move.w     d3,d2
                          sub.w      d4,d2
                          cmp.w      #32,d2
                          slt        needright
                          bra.b      aboutsame
 
RightLouder:
                          st         needright
                          move.w     d4,d2
                          sub.w      d3,d2
                          cmp.w      #32,d2
                          slt        needleft
 
aboutsame:
                          tst.b      STEREO
                          beq        NOSTEREO

; Find least important sound on left

                          move.l     #0,a2
                          move.l     #0,d5
                          move.w     #32767,d2
                          move.b     IDNUM,d0
                          lea        LEFTCHANDATA,a3
                          move.w     #3,d1

FindLeftChannel
                          tst.b      (a3)
                          bne.s      .notactive
                          cmp.b      1(a3),d0
                          beq.s      FOUNDLEFT
                          cmp.w      2(a3),d2
                          blt.s      .notactive
                          move.w     2(a3),d2
                          move.l     a3,a2
                          move.w     d5,d6

.notactive:
                          add.w      #4,a3
                          add.w      #1,d5
                          dbra       d1,FindLeftChannel
                          move.l     a2,a3
                          bra.s      gopastleft

FOUNDLEFT:
                          move.w     d5,d6

gopastleft:
                          tst.l      a3
                          bne.s      FOUNDALEFT
                          rts

FOUNDALEFT:
; d6 = channel number
                          move.b     d0,1(a3)
                          move.w     d3,2(a3)

                          move.w     Samplenum,d5
                          move.l     #SampleList,a3
                          move.l     (a3,d5.w*8),a1
                          move.l     4(a3,d5.w*8),a2

                          tst.b      d6
                          seq        NoiseMade0LEFT
                          beq.s      .chan0
                          cmp.b      #2,d6
                          slt        NoiseMade1LEFT
                          blt.b      .chan1
                          seq        NoiseMade2LEFT
                          beq.b      .chan2
                          st         NoiseMade3LEFT

                          move.b     d5,LEFTPLAYEDTAB+9
                          move.b     d3,LEFTPLAYEDTAB+1+9
                          move.b     d4,LEFTPLAYEDTAB+2+9
                          move.b     d3,vol3left
                          move.l     a1,pos3LEFT
                          move.l     a2,Samp3endLEFT
                          bra.b      dorightchan
 
.chan0: 
                          move.b     d5,LEFTPLAYEDTAB
                          move.b     d3,LEFTPLAYEDTAB+1
                          move.b     d4,LEFTPLAYEDTAB+2
                          move.l     a1,pos0LEFT
                          move.l     a2,Samp0endLEFT
                          move.b     d3,vol0left
                          bra.b      dorightchan
 
.chan1:
                          move.b     d5,LEFTPLAYEDTAB+3
                          move.b     d3,LEFTPLAYEDTAB+1+3
                          move.b     d4,LEFTPLAYEDTAB+2+3
                          move.b     d3,vol1left
                          move.l     a1,pos1LEFT
                          move.l     a2,Samp1endLEFT
                          bra.b      dorightchan

.chan2: 
                          move.b     d5,LEFTPLAYEDTAB+6
                          move.b     d3,LEFTPLAYEDTAB+1+6
                          move.b     d4,LEFTPLAYEDTAB+2+6
                          move.l     a1,pos2LEFT
                          move.l     a2,Samp2endLEFT
                          move.b     d3,vol2left
 
dorightchan:
; Find least important sound on right

                          move.l     #0,a2
                          move.l     #0,d5
                          move.w     #10000,d2
                          move.b     IDNUM,d0
                          lea        RIGHTCHANDATA,a3
                          move.w     #3,d1

FindRightChannel:
                          tst.b      (a3)
                          bne.s      .notactive
                          cmp.b      1(a3),d0
                          beq.s      FOUNDRIGHT
                          cmp.w      2(a3),d2
                          blt.s      .notactive
                          move.w     2(a3),d2
                          move.l     a3,a2
                          move.w     d5,d6

.notactive:
                          add.w      #4,a3
                          add.w      #1,d5
                          dbra       d1,FindRightChannel
                          move.l     a2,a3
                          bra.s      gopastright
FOUNDRIGHT:
                          move.w     d5,d6
gopastright:
                          tst.l      a3
                          bne.s      FOUNDARIGHT
                          rts

FOUNDARIGHT:
; d6 = channel number
                          move.b     d0,1(a3)
                          move.w     d3,2(a3)

                          move.w     Samplenum,d5
                          move.l     #SampleList,a3
                          move.l     (a3,d5.w*8),a1
                          move.l     4(a3,d5.w*8),a2

                          tst.b      d6
                          seq        NoiseMade0RIGHT
                          beq.s      .chan0
                          cmp.b      #2,d6
                          slt        NoiseMade1RIGHT
                          blt.b      .chan1
                          seq        NoiseMade2RIGHT
                          beq.b      .chan2
                          st         NoiseMade3RIGHT

                          move.b     d5,RIGHTPLAYEDTAB+9
                          move.b     d3,RIGHTPLAYEDTAB+1+9
                          move.b     d4,RIGHTPLAYEDTAB+2+9
                          move.b     d4,vol3right
                          move.l     a1,pos3RIGHT
                          move.l     a2,Samp3endRIGHT
                          rts
 
.chan0: 
                          move.b     d5,RIGHTPLAYEDTAB
                          move.b     d3,RIGHTPLAYEDTAB+1
                          move.b     d4,RIGHTPLAYEDTAB+2
                          move.l     a1,pos0RIGHT
                          move.l     a2,Samp0endRIGHT
                          move.b     d4,vol0right
                          rts
 
.chan1:
                          move.b     d5,RIGHTPLAYEDTAB+3
                          move.b     d3,RIGHTPLAYEDTAB+1+3
                          move.b     d4,RIGHTPLAYEDTAB+2+3
                          move.b     d3,vol1right
                          move.l     a1,pos1RIGHT
                          move.l     a2,Samp1endRIGHT
                          rts

.chan2: 
                          move.b     d5,RIGHTPLAYEDTAB+6
                          move.b     d3,RIGHTPLAYEDTAB+1+6
                          move.b     d4,RIGHTPLAYEDTAB+2+6
                          move.l     a1,pos2RIGHT
                          move.l     a2,Samp2endRIGHT
                          move.b     d3,vol2right
                          rts

NOSTEREO:
                          move.l     #0,a2
                          move.l     #-1,d5
                          move.w     #32767,d2
                          move.b     IDNUM,d0
                          lea        CHANNELDATA,a3
                          move.w     #7,d1
FindChannel
                          tst.b      (a3)
                          bne.s      .notactive
                          cmp.b      1(a3),d0
                          beq.s      FOUNDCHAN
                          cmp.w      2(a3),d2
                          blt.s      .notactive
                          move.w     2(a3),d2
                          move.l     a3,a2
                          move.w     d5,d6
                          add.w      #1,d6

.notactive:
                          add.w      #4,a3
                          add.w      #1,d5
                          dbra       d1,FindChannel
 
                          move.l     a2,a3
                          bra.s      gopastchan

FOUNDCHAN:
                          move.w     d5,d6
                          add.w      #1,d6

gopastchan:
                          tst.w      d6
                          bge.s      FOUNDACHAN

tooquiet:
                          rts

FOUNDACHAN:
; d6 = channel number

                          cmp.w      noiseloud,d2
                          bgt.s      tooquiet

                          move.b     d0,1(a3)
                          move.w     noiseloud,2(a3)

                          move.w     Samplenum,d5
                          move.l     #SampleList,a3
                          move.l     (a3,d5.w*8),a1
                          move.l     4(a3,d5.w*8),a2

                          tst.b      d6
                          beq.b      .chan0
                          cmp.b      #2,d6
                          blt        .chan1
                          beq        .chan2
                          cmp.b      #4,d6
                          blt.b      .chan3
                          beq        .chan4
                          cmp.b      #6,d6
                          blt        .chan5
                          beq        .chan6
                          st         NoiseMade3RIGHT

                          move.b     d5,RIGHTPLAYEDTAB+9
                          move.b     d3,RIGHTPLAYEDTAB+1+9
                          move.b     d4,RIGHTPLAYEDTAB+2+9
                          move.b     d4,vol3right
                          move.l     a1,pos3RIGHT
                          move.l     a2,Samp3endRIGHT
                          rts

.chan3:
                          st         NoiseMade3LEFT
                          move.b     d5,LEFTPLAYEDTAB+9
                          move.b     d3,LEFTPLAYEDTAB+1+9
                          move.b     d4,LEFTPLAYEDTAB+2+9
                          move.b     d3,vol3left
                          move.l     a1,pos3LEFT
                          move.l     a2,Samp3endLEFT
                          bra        dorightchan
 
.chan0: 
                          st         NoiseMade0LEFT
                          move.b     d5,LEFTPLAYEDTAB
                          move.b     d3,LEFTPLAYEDTAB+1
                          move.b     d4,LEFTPLAYEDTAB+2
                          move.l     a1,pos0LEFT
                          move.l     a2,Samp0endLEFT
                          move.b     d3,vol0left
                          rts
 
.chan1:
                          st         NoiseMade1LEFT
                          move.b     d5,LEFTPLAYEDTAB+3
                          move.b     d3,LEFTPLAYEDTAB+1+3
                          move.b     d4,LEFTPLAYEDTAB+2+3
                          move.b     d3,vol1left
                          move.l     a1,pos1LEFT
                          move.l     a2,Samp1endLEFT
                          rts

.chan2: 
                          st         NoiseMade2LEFT
                          move.b     d5,LEFTPLAYEDTAB+6
                          move.b     d3,LEFTPLAYEDTAB+1+6
                          move.b     d4,LEFTPLAYEDTAB+2+6
                          move.l     a1,pos2LEFT
                          move.l     a2,Samp2endLEFT
                          move.b     d3,vol2left
                          rts
 
.chan4: 
                          st         NoiseMade0RIGHT
                          move.b     d5,RIGHTPLAYEDTAB
                          move.b     d3,RIGHTPLAYEDTAB+1
                          move.b     d4,RIGHTPLAYEDTAB+2
                          move.l     a1,pos0RIGHT
                          move.l     a2,Samp0endRIGHT
                          move.b     d4,vol0right
                          rts
 
.chan5:
                          st         NoiseMade1RIGHT
                          move.b     d5,RIGHTPLAYEDTAB+3
                          move.b     d3,RIGHTPLAYEDTAB+1+3
                          move.b     d4,RIGHTPLAYEDTAB+2+3
                          move.b     d3,vol1right
                          move.l     a1,pos1RIGHT
                          move.l     a2,Samp1endRIGHT
                          rts

.chan6: 
                          st         NoiseMade2RIGHT
                          move.b     d5,RIGHTPLAYEDTAB+6
                          move.b     d3,RIGHTPLAYEDTAB+1+6
                          move.b     d4,RIGHTPLAYEDTAB+2+6
                          move.l     a1,pos2RIGHT
                          move.l     a2,Samp2endRIGHT
                          move.b     d3,vol2right
                          rts

*********************************************************************************************
; SFX memory begin, end and sample number

SampleList:
                          dc.l       0,0                                        ; 0 : Scream,EndScream
                          dc.l       0,0                                        ; 1 : Shoot,EndShoot
                          dc.l       0,0                                        ; 2 : Munch,EndMunch
                          dc.l       0,0                                        ; 3 : PooGun,EndPooGun
                          dc.l       0,0                                        ; 4 : Collect,EndCollect

                          dc.l       0,0                                        ; 5 : DoorNoise,EndDoorNoise 
                          dc.l       0,0                                        ; 6 : Bass,BassEnd
                          dc.l       0,0                                        ; 7 : Stomp,EndStomp
                          dc.l       0,0                                        ; 8 : LowScream,EndLowScream
                          dc.l       0,0                                        ; 9 : BaddieGun,EndBaddieGun

                          dc.l       0,0                                        ; 10 : SwitchNoise,EndSwitch
                          dc.l       0,0                                        ; 11 : Reload,EndReload
                          dc.l       0,0                                        ; 12 : NoAmmo,EndNoAmmo
                          dc.l       0,0                                        ; 13 : Splotch,EndSplotch 
                          dc.l       0,0                                        ; 14 : SplatPop,EndSplatPop

                          dc.l       0,0                                        ; 15 : Boom,EndBoom
                          dc.l       0,0                                        ; 16 : Hiss,EndHiss
                          dc.l       0,0                                        ; 17 : Howl1,EndHowl1
                          dc.l       0,0                                        ; 18 : Howl2,EndHowl2
                          dc.l       0,0                                        ; 19 : Pant,EndPant

                          dc.l       0,0                                        ; 20 : Whoosh,EndWhoosh
                          dc.l       0,0                                        ; 21  ShotGun : ROAR,EndROAR

                          dc.l       0,0                                        ; 22 : Flame,EndFlame 
                          dc.l       0,0                                        ; 23  Muffled
                          dc.l       0,0                                        ; 24  Clop
                          dc.l       0,0                                        ; 25  Clank
                          dc.l       0,0                                        ; 26  Teleport 
                          dc.l       0,0                                        ; 27  HalfWormPain

                          dc.l       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                          dc.l       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                          dc.l       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                          dc.l       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

                          dc.l       0

*********************************************************************************************

notifplaying:             dc.w       0

audpos1:                  dc.w       0
audpos1b:                 dc.w       0
audpos2:                  dc.w       0
audpos2b:                 dc.w       0
audpos3:                  dc.w       0
audpos3b:                 dc.w       0
audpos4:                  dc.w       0
audpos4b:                 dc.w       0

vol0left:                 dc.w       0
vol0right:                dc.w       0
vol1left:                 dc.w       0
vol1right:                dc.w       0
vol2left:                 dc.w       0
vol2right:                dc.w       0
vol3left:                 dc.w       0
vol3right:                dc.w       0

pos:                      dc.l       0

pos0LEFT:                 dc.l       empty
pos1LEFT:                 dc.l       empty
pos2LEFT:                 dc.l       empty
pos3LEFT:                 dc.l       empty
pos0RIGHT:                dc.l       empty
pos1RIGHT:                dc.l       empty
pos2RIGHT:                dc.l       empty
pos3RIGHT:                dc.l       empty

*********************************************************************************************