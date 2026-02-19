*********************************************************************************************

                          opt         P=68020

*********************************************************************************************

                          incdir      "includes"                                    
                          include     "AB3DI.i"
                          include     "macros.i"

*********************************************************************************************

SyncMaster:

                          SAVEREGS

                          jsr         SENDFIRST                     ; Sync slave

          ; XOff              
                          move.l      p1_xoff,d0
                          jsr         SENDFIRST
                          move.l      d0,p2_xoff

          ; ZOff
                          move.l      p1_zoff,d0
                          jsr         SENDFIRST
                          move.l      d0,p2_zoff 

          ; YOff
                          move.l      p1_yoff,d0
                          jsr         SENDFIRST
                          move.l      d0,p2_yoff

          ; Height
                          move.l      p1_height,d0
                          jsr         SENDFIRST
                          move.l      d0,p2_height

          ; Angpos & Bobble
                          move.w      p1_angpos,d0
                          swap        d0
                          move.w      p1_bobble,d0
                          jsr         SENDFIRST
                          move.w      d0,p2_bobble
                          swap        d0
                          move.w      d0,p2_angpos

          ; Frames & Space & Click
                          move.w      TempFrames,d0
                          swap        d0
                          move.b      p1_spctap,d0
                          lsl.w       #8,d0
                          move.b      p1_clicked,d0
                          jsr         SENDFIRST
                          move.b      d0,p2_clicked
                          lsr.w       #8,d0
                          move.b      d0,p2_spctap

          ; Rnd & Duck & Gun
                          move.w      Rand1,d0
                          swap        d0
                          move.b      p1_ducked,d0
                          lsl.w       #8,d0
                          move.b      p1_gunselected,d0
                          jsr         SENDFIRST
                          move.b      d0,p2_gunselected
                          lsr.w       #8,d0
                          move.b      d0,p2_ducked
            
          ; Fire & Pause & Quit
                          move.b      p1_fire,d0
                          lsl.w       #8,d0
                          move.b      MASTERQUITTING,d0
                          or.b        d0,SLAVEQUITTING
                          swap        d0
                          move.b      MASTERPAUSE,d0
                          or.b        d0,SLAVEPAUSE
                          jsr         SENDFIRST
                          or.b        d0,MASTERPAUSE
                          or.b        d0,SLAVEPAUSE
                          swap        d0
                          or.b        d0,MASTERQUITTING
                          or.b        d0,SLAVEQUITTING
                          lsr.w       #8,d0
                          move.b      d0,p2_fire

                          GETREGS
                          rts


****************************************************************************

SyncSlave:

                          SAVEREGS
            
                          jsr         RECFIRST                      ; Wait master

          ; XOff
                          move.l      p2_xoff,d0
                          jsr         RECFIRST
                          move.l      d0,p1_xoff

          ; ZOff  
                          move.l      p2_zoff,d0
                          jsr         RECFIRST
                          move.l      d0,p1_zoff

          ; YOff  
                          move.l      p2_yoff,d0
                          jsr         RECFIRST
                          move.l      d0,p1_yoff

          ; Height  
                          move.l      p2_height,d0
                          jsr         RECFIRST
                          move.l      d0,p1_height

          ; Angpos & Bobble  
                          move.w      p2_angpos,d0
                          swap        d0
                          move.w      p2_bobble,d0
                          jsr         RECFIRST
                          move.w      d0,p1_bobble
                          swap        d0
                          move.w      d0,p1_angpos

          ; Space & Click  
                          move.b      p2_spctap,d0
                          lsl.w       #8,d0
                          move.b      p2_clicked,d0
                          jsr         RECFIRST
          ; Space & Click & Frames 
                          move.b      d0,p1_clicked
                          lsr.w       #8,d0
                          move.b      d0,p1_spctap
                          swap        d0
                          move.w      d0,TempFrames

          ; Duck & gun  
                          move.b      p2_ducked,d0
                          lsl.w       #8,d0
                          move.b      p2_gunselected,d0
                          jsr         RECFIRST
          ; Duck & Gun & Rnd 
                          move.b      d0,p1_gunselected
                          lsr.w       #8,d0
                          move.b      d0,p1_ducked
                          swap        d0
                          move.w      d0,Rand1
            
          ; Fire & Pause & Quit
                          move.b      p2_fire,d0
                          lsl.w       #8,d0
                          move.b      SLAVEQUITTING,d0
                          or.b        d0,MASTERQUITTING
                          swap        d0
                          move.b      SLAVEPAUSE,d0
                          or.b        d0,MASTERPAUSE
                          jsr         RECFIRST
                          or.b        d0,SLAVEPAUSE
                          or.b        d0,MASTERPAUSE
                          swap        d0
                          or.b        d0,SLAVEQUITTING
                          or.b        d0,MASTERQUITTING
                          lsr.w       #8,d0
                          move.b      d0,p1_fire

                          GETREGS                       
                          rts

*********************************************************************************************

AdvSyncMaster:

                          SAVEREGS

                          jsr         INITSEND                      ; Sync slave
                          jsr         SENDLONG                      ; +4 buffer
               
          ; XOff      
                          move.l      p1_xoff,d0
                          jsr         SENDLONG
            
          ; ZOff   
                          move.l      p1_zoff,d0
                          jsr         SENDLONG
            
          ; YOff  
                          move.l      p1_yoff,d0
                          jsr         SENDLONG
            
          ; Height  
                          move.l      p1_height,d0
                          jsr         SENDLONG
            
          ; Angpos & Bobble  
                          move.w      p1_angpos,d0
                          swap        d0
                          move.w      p1_bobble,d0
                          jsr         SENDLONG

          ; Frames & Space & Click
                          move.w      TempFrames,d0
                          swap        d0
                          move.b      p1_spctap,d0
                          lsl.w       #8,d0
                          move.b      p1_clicked,d0
                          jsr         SENDLONG
            
          ; Rnd & Duck & Gun
                          move.w      Rand1,d0
                          swap        d0
                          move.b      p1_ducked,d0
                          lsl.w       #8,d0
                          move.b      p1_gunselected,d0
                          jsr         SENDLONG

          ; Fire & Quit & Pause
                          move.b      p1_fire,d0
                          lsl.w       #8,d0
                          move.b      MASTERQUITTING,d0
                          or.b        d0,SLAVEQUITTING
                          swap        d0
                          move.b      MASTERPAUSE,d0
                          or.b        d0,SLAVEPAUSE
                          jsr         SENDLAST


                          move.l      BUFFER,p2_xoff
                          move.l      BUFFER+4,p2_zoff
                          move.l      BUFFER+8,p2_yoff
                          move.l      BUFFER+12,p2_height

                          move.w      BUFFER+16,p2_angpos
                          move.w      BUFFER+18,p2_bobble
                    
                          move.b      BUFFER+22,p2_spctap
                          move.b      BUFFER+23,p2_clicked

                          move.b      BUFFER+26,p2_ducked
                          move.b      BUFFER+27,p2_gunselected

                          move.b      BUFFER+28,p2_fire

                          move.b      MASTERQUITTING,d0 
                          or.b        BUFFER+29,d0
                          move.b      d0,MASTERQUITTING
                          or.b        d0,SLAVEQUITTING

                          move.b      MASTERPAUSE,d0 
                          or.b        BUFFER+30,d0
                          move.b      d0,MASTERPAUSE
                          or.b        d0,SLAVEPAUSE

                          GETREGS
                          rts

*********************************************************************************************

AdvSyncSlave:

                          SAVEREGS

                          jsr         INITREC                       ; Wait master
                          jsr         RECEIVE                       ; Receives all at once to buffer

                          jsr         INITSEND

          ; XOff
                          move.l      p2_xoff,d0
                          jsr         SENDLONG
            
          ; ZOff  
                          move.l      p2_zoff,d0
                          jsr         SENDLONG
            
          ; YOff   
                          move.l      p2_yoff,d0
                          jsr         SENDLONG
            
          ; Height  
                          move.l      p2_height,d0
                          jsr         SENDLONG
            
          ; Angpos & Bobble    
                          move.w      p2_angpos,d0
                          swap        d0
                          move.w      p2_bobble,d0
                          jsr         SENDLONG 
            
          ; Space & Click  
                          move.b      p2_spctap,d0
                          lsl.w       #8,d0
                          move.b      p2_clicked,d0
                          jsr         SENDLONG
            
          ; Duck & Gun  
                          move.b      p2_ducked,d0
                          lsl.w       #8,d0
                          move.b      p2_gunselected,d0
                          jsr         SENDLONG
            
          ; Fire & Quit & Pause
                          move.b      p2_fire,d0
                          lsl.w       #8,d0
                          move.b      SLAVEQUITTING,d0
                          or.b        d0,MASTERQUITTING
                          swap        d0
                          move.b      SLAVEPAUSE,d0
                          or.b        d0,MASTERPAUSE
                          jsr         SENDLAST


                          move.l      BUFFER+4,p1_xoff
                          move.l      BUFFER+4+4,p1_zoff
                          move.l      BUFFER+4+8,p1_yoff
                          move.l      BUFFER+4+12,p1_height

                          move.w      BUFFER+4+16,p1_angpos
                          move.w      BUFFER+4+18,p1_bobble

                          move.w      BUFFER+4+20,TempFrames
                          move.b      BUFFER+4+22,p1_spctap
                          move.b      BUFFER+4+23,p1_clicked

                          move.w      BUFFER+4+24,Rand1
                          move.b      BUFFER+4+26,p1_ducked
                          move.b      BUFFER+4+27,p1_gunselected

                          move.b      BUFFER+4+28,p1_fire

                          move.b      SLAVEQUITTING,d0 
                          or.b        BUFFER+4+29,d0
                          move.b      d0,SLAVEQUITTING
                          or.b        d0,MASTERQUITTING

                          move.b      SLAVEPAUSE,d0 
                          or.b        BUFFER+4+30,d0
                          move.b      d0,SLAVEPAUSE
                          or.b        d0,MASTERPAUSE
            
                          GETREGS
                          rts

****************************************************************************