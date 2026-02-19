*********************************************************************************************

                          opt        P=68020

*********************************************************************************************
; Supervisor commands

SetInstCacheOn:

                          move.l     d0,-(a7)
                          movec.l    CACR,d0
                          or.l       #1,d0
                          movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************

SetInstCacheOff:

                          move.l     d0,-(a7)
                          movec.l    CACR,d0
                          and.l      #-2,d0
                          movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************

SetInstCacheFreezeOn:

                          move.l     d0,-(a7)
                          Movec.l    CACR,d0
                          or.l       #2,d0
                          Movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************
SetInstCacheFreezeOff: 

                          move.l     d0,-(a7)
                          Movec.l    CACR,d0
                          and.l      #%11111111111111111111111111111101,d0
                          Movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************
ClearInstCache:

                          move.l     d0,-(a7)
                          Movec.l    CACR,d0
                          or.l       #8,d0
                          Movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************

SetDataCacheOn:

                          move.l     d0,-(a7)
                          Movec.l    CACR,d0
                          or.l       #$10,d0
                          Movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************

SetDataCacheOff:

                          move.l     d0,-(a7)
                          Movec.l    CACR,d0
                          and.l      #%11111111111111111111111011111111,d0
                          Movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

**************************************************************

ClearDataCache: 

                          move.l     d0,-(a7)
                          Movec.l    CACR,d0
                          or.l       #%100000000000,d0
                          Movec.l    d0,CACR
                          move.l     (a7)+,d0
                          rte

********************************************************************************************* 