*********************************************************************************************

                          opt         P=68020

*********************************************************************************************

                          incdir      "includes"
                          include     "AB3DI.i"
                          include     "macros.i"

                          include     "graphics/gfxbase.i"
                          include     "libraries/dosextens.i"
                          include     "workbench/startup.i"


*********************************************************************************************
; OS safe startup

OSFriendlyStartup:

                          SAVEREGS

                          suba.l      a1,a1
                          movea.l     $4,a6
                          jsr         _LVOFindTask(a6)
                          move.l      d0,task
                          movea.l     d0,a2

                          tst.l       pr_CLI(a2)
                          bne.s       NoWorkbench

********************************************************

                          lea         pr_MsgPort(a2),a0
                          jsr         _LVOWaitPort(a6)
               
                          lea         pr_MsgPort(a2),a0
                          jsr         _LVOGetMsg(a6)
                          move.l      d0,wbMsg

                          move.l      d0,a0
                          move.l      sm_NumArgs(a0),d0       
                          beq         skipCurrentDir

                          move.l      sm_ArgList(a0),a1       
                          move.l      wa_Lock(a1),curDirLock
            
                          move.l      #dosName,a1              
                          moveq       #0,d0                    
                          jsr         _LVOOpenLibrary(a6)      
                          move.l      d0,dosBase   

                          move.l      d0,a6
                          move.l      curDirLock,d1
                          move.l      dosBase,a6
                          jsr         _LVOCurrentDir(a6)

                          move.l      $4,a6
                          move.l      dosBase,a1
                          jsr         _LVOCloseLibrary(a6)
                          move.l      #0,dosBase
            
skipCurrentDir:

********************************************************

NoWorkbench:
                          move.l      task,a1
                          moveq       #127,d0                    
                          jsr         _LVOSetTaskPri(a6)
           	
                          move.l      #gfxName,a1              
                          moveq       #0,d0                    
                          jsr         _LVOOpenLibrary(a6)      
                          move.l      d0,gfxBase               

                          move.l      d0,a6                    
                          move.l      gb_ActiView(a6),oldview    
                          move.l      gb_copinit(a6),oldcopper
                
                          move.l      #0,a1
                          jsr         _LVOLoadView(a6)        

                          jsr         _LVOWaitTOF(a6)          
                          jsr         _LVOWaitTOF(a6)         
            
                          jsr         _LVOOwnBlitter(a6)       
                          jsr         _LVOWaitBlit(a6)        

                          lea         $dff000,a6 

                          move.w      dmaconr(a6),d0
                          or.w        #$8000,d0  	
                          move.w      d0,olddmareq	

                          move.w      intenar(a6),d0
                          or.w        #$8000,d0
                          move.w      d0,oldintena

                          move.w      intreqr(a6),d0
                          or.w        #$8000,d0
                          move.w      d0,oldintreq

                          move.w      adkconr(a6),d0
                          or.w        #$8000,d0
                          move.w      d0,oldadkcon

                          GETREGS
                          rts

*********************************************************************************************
; Restore os values

OSFriendlyExit:	

                          SAVEREGS

                          lea         $dff000,a6 
      	
                          move.w      oldintena,intena(a6)
                          move.w      oldintreq,intreq(a6)
                          move.w      olddmareq,dmacon(a6)
                          move.w      oldadkcon,adkcon(a6)

                          move.l      oldcopper,cop1lch(a6)
                          clr.w       copjmp1(a6)

                          move.l      gfxBase,a6
                          move.l      oldview,a1
                          jsr         _LVOLoadView(a6)

                          jsr         _LVOWaitTOF(a6)
                          jsr         _LVOWaitTOF(a6)

                          jsr         _LVOWaitBlit(a6)
                          jsr         _LVODisownBlitter(a6)

                          move.l      $4,a6
                          move.l      gfxBase,a1
                          jsr         _LVOCloseLibrary(a6)
                          move.l      #0,gfxBase
				
                          tst.l       wbMsg
                          beq.s       NoReplyNeeded

********************************************************

                          move.l      $4,a6
                          jsr         _LVOForbid(a6)   

                          move.l      $4,a6
                          movea.l     wbMsg,a1
                          jsr         _LVOReplyMsg(a6)

********************************************************

NoReplyNeeded:  
                          GETREGS
                          rts

*********************************************************************************************

olddmareq:                dc.w        0
oldintena:                dc.w        0
oldintreq:                dc.w        0
oldadkcon:                dc.w        0

oldview:                  dc.l        0
oldcopper:                dc.l        0

wbMsg:                    dc.l        0
task:                     dc.l        0

curDirLock:               dc.l        0

*********************************************************************************************

gfxName:                  dc.b        "graphics.library",0
                          cnop        0,32

gfxBase:                  dc.l        0

dosName:                  dc.b        "dos.library",0
                          cnop        0,32

dosBase:                  dc.l        0

*********************************************************************************************
