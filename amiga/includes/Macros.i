*********************************************************************************************

                          IFND        macros_i
macros_i EQU 1

*********************************************************************************************

FILTER                    macro
                          bchg        #1,$bfe001
                          endm

*********************************************************************************************

BLACK                     macro
                          move.w      #0,$dff180
                          endm

RED                       macro
                          move.w      #$f00,$dff180
                          endm

GREEN                     macro
                          move.w      #$0f0,$dff180
                          endm

BLUE                      macro
                          move.w      #$f,$dff180
                          endm

*********************************************************************************************

SAVEREGS                  MACRO
                          movem.l     d0-d7/a0-a6,-(a7)
                          ENDM

*********************************************************************************************

GETREGS                   MACRO
                          movem.l     (a7)+,d0-d7/a0-a6
                          ENDM

*********************************************************************************************

WT                        MACRO
; a0 = $bfd000
; a3 = $bfe001
; CIAB_COMCTS = 4
\@bf:
                        ;btst        #6,(a3)
                        ;bne.s       \@bd
                        ;rts
\@bd: 
                          btst        #CIAB_COMCTS,(a0)
                          beq.s       \@bf
                          ENDM

*********************************************************************************************

WTNOT                     MACRO
; a0 = $bfd000
; a3 = $bfe001
; CIAB_COMCTS = 4
\@bf:
                        ;btst        #6,(a3)
                        ;bne.s       \@bd
                        ;rts
\@bd: 
                          btst        #CIAB_COMCTS,(a0)
                          bne.s       \@bf
                          ENDM

*********************************************************************************************

SUPERVISOR                MACRO
                          SAVEREGS
                          move.l      $4,a6
                          lea.l       \1(pc),a5                                                       
                          jsr         _LVOSupervisor(a6)
                          GETREGS
                          ENDM

*********************************************************************************************

DUGDOS                    MACRO
                          move.l      DosBase,a6
                          Jsr         _LVO\1(a6)                                               ; DosCall
                          ENDM

*********************************************************************************************

DUGREQ                    MACRO
                          move.l      ReqBase,a6
                          Jsr         _LVO\1(a6)                                               ; ReqCall
                          ENDM

*********************************************************************************************

PALETTE32COL              MACRO
                          dc.l        $1800000,$1820000,$1840000,$1860000,$1880000,$18a0000
                          dc.l        $18c0000,$18e0000,$1900000,$1920000,$1940000,$1960000
                          dc.l        $1980000,$19a0000,$19c0000,$19e0000,$1a00000,$1a20000
                          dc.l        $1a40000,$1a60000,$1a80000,$1aa0000,$1ac0000,$1ae0000
                          dc.l        $1b00000,$1b20000,$1b40000,$1b60000,$1b80000,$1ba0000
                          dc.l        $1bc0000,$1be0000
                          ENDM

*********************************************************************************************
; QMOVE  move a constant into a reg the quickest way (probbly)              
; qmove.w 123,d0 NB:if word or byte, will still use moveq!!! if it can      

QMOVE                     MACRO
                          IFGE        \1
                          IFLE        \1-127
                          moveq       #\1,\2
                          MEXIT
                          ENDC
                          IFLE        \1-255
                          moveq       #256-\1,\2
                          neg.b       \2
                          MEXIT
                          ENDC
                          move.\0     #\1,\2
                          MEXIT
                          ELSEIF
                          move.\0     #\1,\2
                          ENDC
                          ENDM

*********************************************************************************************

SCALE                     MACRO
                          dc.w        64*0
                          dc.w        64*1
                          dc.w        64*1
                          dc.w        64*2
                          dc.w        64*2
                          dc.w        64*3
                          dc.w        64*3
                          dc.w        64*4
                          dc.w        64*4
                          dc.w        64*5
                          dc.w        64*5
                          dc.w        64*6
                          dc.w        64*6
                          dc.w        64*7
                          dc.w        64*7
                          dc.w        64*8
                          dc.w        64*8
                          dc.w        64*9
                          dc.w        64*9
                          dc.w        64*10
                          dc.w        64*10
                          dc.w        64*11
                          dc.w        64*11
                          dc.w        64*12
                          dc.w        64*12
                          dc.w        64*13
                          dc.w        64*13
                          dc.w        64*14
                          dc.w        64*14
                          dc.w        64*15
                          dc.w        64*15
                          dc.w        64*16
                          dc.w        64*16
                          dc.w        64*17
                          dc.w        64*17
                          dc.w        64*18
                          dc.w        64*18
                          dc.w        64*19
                          dc.w        64*19
                          dc.w        64*20
                          dc.w        64*20
                          dc.w        64*21
                          dc.w        64*21
                          dc.w        64*22
                          dc.w        64*22
                          dc.w        64*23
                          dc.w        64*23
                          dc.w        64*24
                          dc.w        64*24
                          dc.w        64*25
                          dc.w        64*25
                          dc.w        64*26
                          dc.w        64*26
                          dc.w        64*27
                          dc.w        64*27
                          dc.w        64*28
                          dc.w        64*28
                          dc.w        64*29
                          dc.w        64*29
                          dc.w        64*30
                          dc.w        64*30
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          dc.w        64*31
                          ENDM
                  
*********************************************************************************************

WAITFORTBEREQ             MACRO
; a6 = $dff000
\@checkTBE:
                        ;btst.b      #5,serdatrl(a6)                                           ; bit 13 = TBE (Serial port transmit buffer empty)
                          btst.b      #0,intreqrl(a6)                                          ; bit 0 = TBE (Serial port transmit buffer empty)
                          beq.b       \@checkTBE                                               ; wait until last byte sent
                          move.w      #%0000000000000001,intreq(a6)                            ; TBE request done
                          ENDM

*********************************************************************************************

WAITFORVERTBREQ           MACRO
; a6 = $dff000
\@waitFrame:
                          btst        #5,intreqrl(a6)
                          beq.s       \@waitFrame
                          move.w      #$0020,intreq(a6)
                          ENDM

*********************************************************************************************

WAITFORMSB                MACRO
\@waitMsb:
                          btst        #6,$bfe001
                          bne.s       \@waitMsb
                          ENDM

*********************************************************************************************

                          ENDC  