*********************************************************************************************
; Test face animation
*********************************************************************************************

                          opt        P=68020

*********************************************************************************************

                          incdir     "includes"
                          include    "AB3DI.i"
                                     
*********************************************************************************************

                          SECTION    FaceCode,CODE_F

*********************************************************************************************

SetupCopperForFaceTest:  

                          move.l     #facePlace,d0
                          move.w     d0,f1l
                          swap       d0
                          move.w     d0,f1h
                          move.l     #facePlace+32*24,d0
                          move.w     d0,f2l
                          swap       d0
                          move.w     d0,f2h
                          move.l     #facePlace+32*24*2,d0
                          move.w     d0,f3l
                          swap       d0
                          move.w     d0,f3h
                          move.l     #facePlace+32*24*3,d0
                          move.w     d0,f4l
                          swap       d0
                          move.w     d0,f4h
                          move.l     #facePlace+32*24*4,d0
                          move.w     d0,f5l
                          swap       d0
                          move.w     d0,f5h

                          rts

*********************************************************************************************
; Faces

PlaceFace:

                          move.w     facesCounter,d0
                          subq       #1,d0
                          bgt        noNewFace

*****************************************************************

                          move.l     facesPtr,a0
                          move.w     2(a0),d0                              ; d0 = facesCounter
                          move.w     (a0),expression
                          addq       #4,a0 
                          cmp.w      #-1,(a0)
                          bne        notFirstFace

*****************************************************************

                          move.w     PLR1_energy,d3

                          cmp.w      #110,d3
                          bmi        nextPhase1

                          lea        faceAnims1,a0 
                          move.l     cheeseFace1,cheeseFace
                          move.l     painFace1,painFace
                          bra        notFirstFace

nextPhase1:
                          cmp.w      #80,d3
                          bmi        nextPhase2

                          lea        faceAnims2,a0
                          move.l     cheeseFace2,cheeseFace
                          move.l     painFace2,painFace
                          bra        notFirstFace

nextPhase2:
                          cmp.w      #40,d3
                          bmi        nextPhase3

                          lea        faceAnims3,a0
                          move.l     cheeseFace3,cheeseFace
                          move.l     painFace3,painFace
                          bra        notFirstFace

nextPhase3:
                          cmp.w      #20,d3
                          bmi        nextPhase4

                          lea        faceAnims4,a0
                          move.l     cheeseFace4,cheeseFace
                          move.l     painFace4,painFace
                          bra        notFirstFace

nextPhase4:
                          lea        faceAnims5,a0
                          move.l     cheeseFace5,cheeseFace
                          move.l     painFace5,painFace

*****************************************************************

notFirstFace:
                          move.l     a0,facesPtr

*****************************************************************

noNewFace:
                          move.w     d0,facesCounter

*****************************************************************

                          move.l     #faces,a1
                          move.w     faceToPlace,d0
                          muls       #5,d0
                          add.w      expression,d0
                          muls       #(4*32*5),d0
                          adda.w     d0,a1

                          move.w     #4,d0
                          move.w     #24,d1
                          move.w     #4,d3
                          move.l     #facePlace+10,a0

bitplaneloop:
                          move.w     #31,d2 

PlaceFaceToPlaceInFacePlaceLoop:
                          move.l     (a1),(a0)
                          adda.w     d0,a1
                          adda.w     d1,a0
                          dbra       d2,PlaceFaceToPlaceInFacePlaceLoop
                          dbra       d3,bitplaneloop
 
                          rts                          

*********************************************************************************************

faceToPlace:              dc.w       0
expression:               dc.w       0

facesPtr:                 dc.l       faceAnims1
facesCounter:             dc.w       0

*********************************************************************************************

painFace:                 dc.w       3,15
                          dc.w       -1

cheeseFace:               dc.w       4,15
                          dc.w       -1

*********************************************************************************************
; 0-4
faceAnims1:               dc.w       0,4*4
                          dc.w       1,2*4
                          dc.w       0,2*4
                          dc.w       2,2*4
                          dc.w       0,2*4
                          dc.w       1,3*4
                          dc.w       0,2*4
                          dc.w       2,3*4
                          dc.w       0,5*4
                          dc.w       1,2*4
                          dc.w       0,2*4
                          dc.w       2,2*4
                          dc.w       0,2*4
                          dc.w       1,2*4
                          dc.w       0,2*4
                          dc.w       2,3*4
                          dc.w       0,1*4
                          dc.w       1,3*4
                          dc.w       0,1*4
                          dc.w       2,3*4
                          dc.w       0,1*4
                          dc.w       -1

painFace1:                dc.w       3,15
cheeseFace1:              dc.w       4,15

*********************************************************************************************
; 5-9
faceAnims2:               dc.w       5,9*4
                          dc.w       6,5*4
                          dc.w       7,2*4
                          dc.w       6,5*4
                          dc.w       -1

painFace2:                dc.w       8,15
cheeseFace2:              dc.w       9,15

*********************************************************************************************
; 10-14
faceAnims3:               dc.w       10,9*4
                          dc.w       11,5*4
                          dc.w       12,3*4
                          dc.w       11,2*4
                          dc.w       -1

painFace3:                dc.w       13,15
cheeseFace3:              dc.w       14,15

*********************************************************************************************
; 15-19
faceAnims4:               dc.w       15,9*4
                          dc.w       16,5*4
                          dc.w       17,3*4
                          dc.w       16,2*4
                          dc.w       -1

painFace4:                dc.w       18,15
cheeseFace4:              dc.w       19,15

*********************************************************************************************
; 20-24
faceAnims5:               dc.w       20,9*4
                          dc.w       21,5*4
                          dc.w       22,3*4
                          dc.w       21,2*4
                          dc.w       -1

painFace5:                dc.w       23,15
cheeseFace5:              dc.w       24,15

*********************************************************************************************

faces:                    incbin     "data/gfx/faces2raw"
                          even

*********************************************************************************************
*********************************************************************************************

                          SECTION    FaceData,DATA_C

*********************************************************************************************

facePlace:                ds.l       6*32*5

*********************************************************************************************