*********************************************************************************************

                          opt        P=68020
              
*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                          include    "macros.i"
                          include    "defs.i"

                          include    "exec/memory.i"

*********************************************************************************************

ReleaseWallMemory:

                          move.l     #walltiles,a0
                          move.l     #wallchunkdata,a5

relmem:
                          move.l     4(a5),d0
                          beq.s      relall
 
                          move.l     (a0),d1
                          beq.s      notthismem

                          move.l     d1,a1
                          move.l     4.w,a6
                          movem.l    a0/a5,-(a7)
                          jsr        _LVOFreeMem(a6)
                          movem.l    (a7)+,a0/a5


notthismem:
                          addq       #8,a5
                          addq       #4,a0
                          bra.s      relmem
 
relall:
                          rts

*********************************************************************************************

LoadWalls:

                          move.l     #walltiles,a0
                          moveq      #39,d7

emptywalls:
                          move.l     #0,(a0)+
                          dbra       d7,emptywalls

                          move.l     #walltiles,a4
                          move.l     #wallchunkdata,a3

loademin:
                          move.l     4(a3),d0
                          beq        loadedall
 
                          move.l     d0,UNPACKED
 
                          movem.l    a4/a3,-(a7)
 
                          move.l     (a3),blockname
 
                          move.l     doslib,a6
                          move.l     blockname,d1
                          move.l     #1005,d2
                          jsr        _LVOOpen(a6)
                          move.l     d0,handle
                          tst.l      d0
                          beq        ErrorFileNotFound
 
                          lea        fib,a5
                          move.l     handle,d1
                          move.l     a5,d2
                          jsr        _LVOExamineFH(a6)
                          move.l     fib_Size(a5),d0
                          move.l     d0,blocklen
                          tst.l      d0
                          beq        ErrorFileSizeZero

                          move.l     #MEMF_FAST|MEMF_CLEAR,d1
                          move.l     4.w,a6
                          move.l     UNPACKED,d0
                          jsr        _LVOAllocMem(a6)
                          move.l     d0,blockstart

                          move.l     doslib,a6
                          move.l     handle,d1
                          move.l     #WorkSpace,d2
                          move.l     blocklen,d3
                          jsr        _LVORead(a6)

                          move.l     doslib,a6
                          move.l     handle,d1
                          jsr        _LVOClose(a6)
 
                          move.l     #WorkSpace,d0
                          moveq      #0,d1
                          move.l     blockstart,a0
                          move.l     LEVELDATA,a1
                          lea        $0,a2
                          jsr        UnLHA
 
                          movem.l    (a7)+,a4/a3
 
                          move.l     blockstart,(a4)+
                          move.l     UNPACKED,4(a3)
 
                          addq       #8,a3
                          bra        loademin
 
loadedall:
                          rts

ErrorFileNotFound:
                          nop
                          movem.l    (a7)+,a4/a3
                          rts

ErrorFileSizeZero:
                          nop
                          movem.l    (a7)+,a4/a3
                          rts

*********************************************************************************************

handle:                   dc.l       0

UNPACKED:                 dc.l       0

walltiles:                ds.l       40

*********************************************************************************************
 
wallchunkdata:
                          dc.l       GreenMechanicNAME,18560
                          dc.l       BlueGreyMetalNAME,13056
                          dc.l       TechnoDetailNAME,13056
                          dc.l       BlueStoneNAME,4864
                          dc.l       RedAlertNAME,7552
                          dc.l       RockNAME,10368
                          dc.l       scummyNAME,13056
                          dc.l       stairfrontsNAME,2400
                          dc.l       bigdoorNAME,13056
                          dc.l       redrockNAME,13056
                          dc.l       dirtNAME,24064
                          dc.l       SwitchesNAME,3456
                          dc.l       shinyNAME,24064
                          dc.l       bluemechNAME,15744
                          dc.l       0,0

GreenMechanicNAME:
                          dc.b       'disk/includes/walls/greenmechanic.wad'
                          dc.b       0 
                          even
BlueGreyMetalNAME:
                          dc.b       'disk/includes/walls/bluegreymetal.wad'
                          dc.b       0
                          even
TechnoDetailNAME:
                          dc.b       'disk/includes/walls/technodetail.wad'
                          dc.b       0
                          even
BlueStoneNAME:
                          dc.b       'disk/includes/walls/bluestone.wad'
                          dc.b       0
                          even
RedAlertNAME:
                          dc.b       'disk/includes/walls/redalert.wad'
                          dc.b       0
                          even
RockNAME:
                          dc.b       'disk/includes/walls/rock.wad'
                          dc.b       0
                          even
scummyNAME:
                          dc.b       'disk/includes/walls/scummy.wad'
                          dc.b       0
                          even
stairfrontsNAME:
                          dc.b       'disk/includes/walls/stairfronts.wad'
                          dc.b       0
                          even
bigdoorNAME:
                          dc.b       'disk/includes/walls/bigdoor.wad'
                          dc.b       0
                          even
redrockNAME:
                          dc.b       'disk/includes/walls/redrock.wad'
                          dc.b       0
                          even
dirtNAME:
                          dc.b       'disk/includes/walls/dirt.wad'
                          dc.b       0
                          even
SwitchesNAME:
                          dc.b       'disk/includes/walls/switches.wad'
                          dc.b       0
                          even 
shinyNAME:
                          dc.b       'disk/includes/walls/shinymetal.wad'
                          dc.b       0
                          even
bluemechNAME:
                          dc.b       'disk/includes/walls/bluemechanic.wad'
                          dc.b       0
                          even
 
*********************************************************************************************