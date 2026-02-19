*********************************************************************************************
* 
*   Unpack =SB= archives 
*
*********************************************************************************************

             opt         P=68020

*********************************************************************************************

WorkBuf16K      EQU 1024*16
WorkBuf65K      EQU 1024*65
DestBuf128K     EQU 1024*128 ; $020000
DefUnpackedSize EQU 1024*64

*********************************************************************************************

             incdir      "includes"
             include     "AB3DI.i"
             include     "macros.i"

             include     "exec/memory.i"
             include     "dos/dos.i"

*********************************************************************************************

             SECTION     UnSBCode,CODE_F

*********************************************************************************************

UnSB:

             move.l      #dosLibName,a1
             moveq       #36,d0                                                ; v37 - Kickstart 2.04
             move.l      4.w,a6
             jsr         _LVOOpenLibrary(a6)
             move.l      d0,dosLib
             beq         noDosLib

***************************************************

             move.l      dosLib,a6  
             jsr         _LVOOutput(a6)   
             move.l      d0,out

***************************************************

             lea         desc,a0  
             jsr         Print

***************************************************

             clr.l       d0
             move.l      #template,d1
             move.l      #params,d2
             move.l      #0,d3
             move.l      dosLib,a6
             jsr         _LVOReadArgs(a6)
             move.l      d0,rdArgs
             beq         showArgs

***************************************************

             move.l      fillChar,a0
             move.b      (a0),d0
             beq         showArgs

             move.l      srcFile,d0
             beq         showArgs
             move.l      d0,a0
             jsr         Print

             lea         toMarker,a0  
             jsr         Print

             move.l      dstFile,d0
             beq         showArgs
             move.l      d0,a0
             jsr         Print

             lea         newLine,a0  
             jsr         Print

***************************************************

             lea         readFile,a0                   
             jsr         Print

***************************************************

             move.l      srcFile,d1
             move.l      #MODE_OLDFILE,d2
             move.l      dosLib,a6
             jsr         _LVOOpen(a6)
             move.l      d0,srcHandle
             beq         failed

             lea         fib,a5
             move.l      a5,d2
             move.l      srcHandle,d1             
             move.l      dosLib,a6
             jsr         _LVOExamineFH(a6)
 
             move.l      fib_Size(a5),srcLen
 
             move.l      #MEMF_FAST|MEMF_PUBLIC|MEMF_CLEAR,d1
             move.l      srcLen,d0
             move.l      4.w,a6
             jsr         _LVOAllocMem(a6)
             move.l      d0,srcBuf
             beq         failed

             move.l      srcHandle,d1
             move.l      srcBuf,d2
             move.l      srcLen,d3
             move.l      dosLib,a6
             jsr         _LVORead(a6)

             move.l      srcHandle,d1
             move.l      dosLib,a6
             jsr         _LVOClose(a6)

***************************************************

             move.l      #MEMF_FAST|MEMF_PUBLIC|MEMF_CLEAR,d1
             move.l      #WorkBuf16K,d0
             move.l      4.w,a6
             jsr         _LVOAllocMem(a6)
             move.l      d0,workBuf16
             beq         failed

             move.l      #MEMF_FAST|MEMF_PUBLIC|MEMF_CLEAR,d1
             move.l      #WorkBuf65K,d0
             move.l      4.w,a6
             jsr         _LVOAllocMem(a6)
             move.l      d0,workBuf65
             beq         failed

***************************************************

             move.l      #MEMF_FAST|MEMF_PUBLIC|MEMF_CLEAR,d1
             move.l      #DestBuf128K,d0
             move.l      4.w,a6
             jsr         _LVOAllocMem(a6)
             move.l      d0,dstBuf
             beq         failed

***************************************************

             move.l      #DestBuf128K,d0
             move.l      fillChar,a0
             move.b      (a0),d1
             move.l      dstBuf,a0

clearLoop:
             move.b      d1,(a0)
             add.l       #1,a0
             sub.l       #1,d0
             bne         clearLoop

***************************************************

             lea         unPack,a0                   
             jsr         Print

***************************************************

             move.l      srcBuf,d0
             move.l      dstBuf,a0
             move.l      workBuf16,a1
             move.l      workBuf65,a2
             clr.l       d1
             jsr         UnLHA

***************************************************

             move.l      #(DestBuf128K-1),d0
             move.l      fillChar,a0
             move.b      (a0),d1
             move.l      dstBuf,a0

searchLoop:
             cmp.b       (a0,d0.l),d1
             bne         foundEnd
             sub.l       #1,d0
             bne         searchLoop
             bra         skip

foundEnd:
             add.l       #1,d0
             move.l      a0,a1
             add.l       d0,a0
             sub.l       a1,a0
             move.l      a0,dstLen

skip:

***************************************************

             lea         writeFile,a0                   
             jsr         Print

***************************************************

             move.l      dstFile,d1
             move.l      #MODE_READWRITE,d2
             move.l      dosLib,a6
             jsr         _LVOOpen(a6)
             move.l      d0,dstHandle
             beq         failed

             move.l      dstHandle,d1
             move.l      dstBuf,d2
             move.l      dstLen,d3
             move.l      dosLib,a6
             jsr         _LVOWrite(a6)

             move.l      dstHandle,d1
             move.l      dosLib,a6
             jsr         _LVOClose(a6)  

***************************************************

             lea         ready,a0                   
             jsr         Print

***************************************************

errorExit:
             move.l      srcBuf,d0
             beq.s       noSrcBuf

             move.l      d0,a1
             move.l      srcLen,d0
             move.l      4.w,a6
             jsr         _LVOFreeMem(a6)
             move.l      #0,srcBuf

noSrcBuf:

***************************************************

             move.l      workBuf16,d0
             beq.s       noWorkBuf16

             move.l      d0,a1
             move.l      #WorkBuf16K,d0
             move.l      4.w,a6
             jsr         _LVOFreeMem(a6)
             move.l      #0,workBuf16

noWorkBuf16:
             move.l      workBuf65,d0
             beq.s       noWorkBuf65

             move.l      d0,a1
             move.l      #WorkBuf65K,d0
             move.l      4.w,a6
             jsr         _LVOFreeMem(a6)
             move.l      #0,workBuf65

noWorkBuf65:

***************************************************

             move.l      dstBuf,d0
             beq         noDstBuf

             move.l      d0,a1
             move.l      #DestBuf128K,d0
             move.l      4.w,a6
             jsr         _LVOFreeMem(a6)
             move.l      #0,dstBuf

noDstBuf:

***************************************************

             move.l      rdArgs,d1
             beq         noRdArgs
             move.l      dosLib,a6             
             jsr         _LVOFreeArgs(a6)

noRdArgs:

***************************************************

onlyCloseLib:
             move.l      dosLib,a1
             move.l      4.w,a6
             jsr         _LVOCloseLibrary(a6)

***************************************************

noDosLib:
             moveq       #0,d0
             rts

*********************************************************************************************

Print:
; a0=description

             SAVEREGS
             move.l      out,d1
             beq.b       noPrint

             move.l      a0,a1

charLoop:
             tst.b       (a1)+
             bne.b       charLoop

             sub.l       a0,a1
             move.l      a1,d3

             move.l      a0,d2 
             move.l      dosLib,a6
             jsr         _LVOWrite(a6)            

noPrint:
             GETREGS
             rts

*********************************************************************************************

failed:
             lea         failedDesc,a0                   
             jsr         Print

             bra         errorExit

*********************************************************************************************

showArgs:
             lea         template,a0                   
             jsr         Print

             lea         newLine,a0  
             jsr         Print

             bra         onlyCloseLib

*********************************************************************************************

desc:        dc.b        "UnSB v1.0 - AB3D tool",10,0
unPack:      dc.b        "Unpack..",10,0
readFile:    dc.b        "Read file..",10,0
writeFile:   dc.b        "Write file..",10,0
ready:       dc.b        "Ready!",10,0
failedDesc:  dc.b        "Failed!",10,0
newLine:     dc.b        10,0
toMarker:    dc.b        " -> ",0
             even

*********************************************************************************************

rdArgs:      dc.l        0

params:
srcFile:     dc.l        packed
dstFile:     dc.l        unpacked
fillChar:    dc.l        char

template:    dc.b        "P=PACKED/A/K,U=UNPACKED/A/K,C=SIZECHAR/K",0
             even
*********************************************************************************************

packed:      dc.b        "packed",0             ; 9301 ($2455) bytes
unpacked:    dc.b        "unpacked",0           ; 41920 ($A3C0) bytes = rate 4,51
char:        dc.b        $23,0                  ; "#"

*********************************************************************************************

srcHandle:   dc.l        0
dstHandle:   dc.l        0

*********************************************************************************************

dosLib:      dc.l        0
dosLibName:  dc.b        "dos.library",0
             even
            
*********************************************************************************************

out:         dc.l        0

*********************************************************************************************

             CNOP        0,4
fib:         ds.l        75

*********************************************************************************************

srcLen:      dc.l        0
dstLen:      dc.l        DestBuf128K

*********************************************************************************************

srcBuf:      dc.l        0
dstBuf:      dc.l        0
workBuf16:   dc.l        0
workBuf65:   dc.l        0

*********************************************************************************************

             SECTION     Decomp4,CODE_F

*********************************************************************************************

UnLHA:
; D0 = Source pointer
; A0 = Destination memory pointer
; A1 = 16K Workspace
; A2 = 65K Workspace
; D1 = Pointer to list of the form:
;
;   LONG <offset>
;   LONG <length>
;
; NB: Terminated by _two_ zero longwords.
;
; (If D1 = 0 then the entire source file is decompressed).
;
; Result:
; Note: d2/a2-a5 unchanged

             incbin      "../data/code/DeComp4.bin"

*********************************************************************************************
