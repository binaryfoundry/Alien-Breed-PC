*********************************************************************************************

            opt           P=68020

*********************************************************************************************

            incdir        "includes"
            include       "macros.i"
            include       "AB3DI.i"

*********************************************************************************************

LOG         MACRO
            move.l        \1,logText
            jsr           WriteLog
            ENDM

*********************************************************************************************

WriteLog:
; logText = text to log (4 bytes)

            SAVEREGS

            tst.l         doslib
            beq           noLog

            move.l        doslib,a6
            move.l        #logFile,d1
            move.l        #MODE_READWRITE,d2
            jsr           _LVOOpen(a6)
            move.l        d0,logHandle

            move.l        doslib,a6
            move.l        logHandle,d1
            move.l        #0,d2
            move.l        #OFFSET_END,d3
            jsr           _LVOSeek(a6)

            move.l        doslib,a6
            move.l        logHandle,d1
            move.l        #logText,d2
            move.l        #5,d3
            jsr           _LVOWrite(a6)

            move.l        doslib,a6
            move.l        logHandle,d1
            jsr           _LVOClose(a6)  

noLog:
            GETREGS
            rts

*********************************************************************************************
logText:    dc.b          "    ",13,0
            even
logHandle:  dc.l          0
logFile:    dc.b          "log.txt",0
            even

*********************************************************************************************

MSG         MACRO
            move.l        \1,logMsg
            jsr           Message
            ENDM

*********************************************************************************************

Message:

            SAVEREGS

            lea           intuiName(PC),a1
            move.l        $4,a6
            jsr           _LVOOpenLibrary(a6)
            tst.l         d0
            beq.s         .libError
            
            move.l        d0,a6
            move.l        #$01234567,d0
            moveq         #28,d1
            lea           logMsg(PC),a0
            jsr           _LVODisplayAlert(a6)
 
            move.l        a6,a1
            move.l        $4,a6
            jsr           _LVOCloseLibrary(a6)

.libError:
            GETREGS
            rts

*********************************************************************************************

logMsg:     dc.b          "    ",0
            even

intuiName:  dc.b          "intuition.library",0

*********************************************************************************************