; =============================================================================
; file_io/smf_operations.asm - Standard MIDI File Operations
; =============================================================================
; SMF (Standard MIDI File) load, save, and naming routines.
;
; Key routines:
;   FmmSmfLoadTitleFunc              - SMF load title
;   FmmSmfSaveTitleFunc              - SMF save title
;   SaveFileNameSmfFunc              - SMF filename saving
;   SmfSeqToSongNumFunc              - SMF sequence to song number
;   SmfSeqFromSongNumFunc            - SMF sequence from song number
;   SmfSeqSongNameFunc               - SMF sequence song name
;   SmfLoadAsFunc                    - SMF load-as function
;   FmmSmfFileNameFunc               - SMF filename handling
; =============================================================================

FmmSmfLoadTitleFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JRL Z, LABEL_F8DCE2
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8DCFD
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, LABEL_F8DCDD
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8DCFD
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	LD_8_8 0x808A, 0x8D37
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8DBA6
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8DBA6:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JRL Z, LABEL_F8DC70
	; (no addr) CP WA, 0
	; (no addr) JRL Z, LABEL_F8DC5A
	; (no addr) CP WA, 5
	; (no addr) JR Z, LABEL_F8DC16
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR GE, LABEL_F8DBD3
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8DBD3:
	; (no addr) CPW (8504h), 0000h
	; (no addr) JRL NZ, LABEL_F8DCBB
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, LABEL_F8DBEF
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	CALR SignalProgressUpdate

LABEL_F8DBEF:
	; (no addr) CPW (8502h), 0000h
	; (no addr) JRL LE, LABEL_F8DCBB
	; (no addr) CP (808Ah), 061h
	; (no addr) JRL Z, LABEL_F8DCBB
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0061h
	; (no addr) JRL T, LABEL_F8DCF9

LABEL_F8DC16:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (808Ah)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 000h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8DCB5

LABEL_F8DC5A:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007dh
	; (no addr) JRL T, LABEL_F8DCF9

LABEL_F8DC70:
	CALR ResetProgressIndication
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (808Ah)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 002h
	; (no addr) LD WA, 00eeh

LABEL_F8DCB5:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JR T, LABEL_F8DCFD

LABEL_F8DCBB:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8DCFD

LABEL_F8DCDD:
	CALR CancelOperationCleanup
	; (no addr) JR T, LABEL_F8DCFD

LABEL_F8DCE2:
	; (no addr) CP XDE, 0000000fh
	; (no addr) JR NZ, LABEL_F8DCFD
	; (no addr) CP (8D34h), 007h
	; (no addr) JR NZ, LABEL_F8DCF6
	; (no addr) LD WA, 00d6h
	; (no addr) JR T, LABEL_F8DCF9

LABEL_F8DCF6:
	; (no addr) LD WA, 0060h

LABEL_F8DCF9:
	; (no addr) CALL UI_PostModeChangeEvent

LABEL_F8DCFD:
	; (no addr) LD XHL, 0
	; (no addr) RET

FmmSmfSaveTitleFunc:
	; (no addr) CP XBC, 01c00013h
	; (no addr) JR NZ, LABEL_F8DD72
	; (no addr) CP XDE, 00000003h
	; (no addr) JR Z, LABEL_F8DD6F
	; (no addr) CP XDE, 00000002h
	; (no addr) JR NZ, LABEL_F8DD72
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR GE, LABEL_F8DD4D
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8DD4D:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8DD72

LABEL_F8DD6F:
	CALR CancelOperationCleanup

LABEL_F8DD72:
	; (no addr) LD XHL, 0
	; (no addr) RET

RenderSmfFilename:
	; (no addr) EXTZ BC
	; (no addr) LD (XWA + BC), 000h
	; (no addr) LD IX, 0
	; (no addr) LDA XHL, 0EED778h
	; (no addr) JR T, LABEL_F8DD97

LABEL_F8DD86:
	; (no addr) EXTZ BC
	; (no addr) LD C, (XHL + BC)
	; (no addr) AND C, 007h
	; (no addr) JR NZ, LABEL_F8DD95
	; (no addr) LD (XDE), 05fh

LABEL_F8DD95:
	; (no addr) INC 1, IX

LABEL_F8DD97:
	; (no addr) CP IX, 0008h
	; (no addr) JR GE, LABEL_F8DDA8
	; (no addr) LDA XDE, XWA + IX
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 0
	; (no addr) JR NZ, LABEL_F8DD86

LABEL_F8DDA8:
	; (no addr) CP IX, 0008h
	; (no addr) RET GE

LABEL_F8DDAE:
	; (no addr) LD (XWA + IX), 05fh
	; (no addr) INC 1, IX
	; (no addr) CP IX, 0008h
	; (no addr) JR LT, LABEL_F8DDAE
	; (no addr) RET

SaveFileNameSmfFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 004h), XDE
	; (no addr) LDA XWA, 8850h
	; (no addr) CP XBC, 01e00086h
	; (no addr) JR Z, LABEL_F8DE48
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JR Z, LABEL_F8DE1C
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8DDF2
	; (no addr) CP XBC, 01e50004h
	; (no addr) JRL NZ, LABEL_F8DE74
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD (808Ch), XWA
	; (no addr) JRL T, LABEL_F8DE74

LABEL_F8DDF2:
	; (no addr) LD (XWA), 000h
	; (no addr) LDA XIZ, XWA + 001h
	; (no addr) CALL LABEL_F892D5
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LDA XWA, 8851h
	; (no addr) CALL LABEL_F8929D
	; (no addr) LD XWA, (808Ch)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00008850h
	; (no addr) JR T, LABEL_F8DE42

LABEL_F8DE1C:
	; (no addr) LD XIZ, XWA
	; (no addr) CALL LABEL_F892D5
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 00008850h
	; (no addr) LD BC, 0008h
	CALR RenderSmfFilename
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01e00086h
	; (no addr) LD XDE, 00008850h

LABEL_F8DE42:
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8DE74

LABEL_F8DE48:
	; (no addr) LD XBC, (XSP + 004h)
	; (no addr) LD DE, 0008h
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD XWA, 00008850h
	; (no addr) LD BC, 0008h
	CALR RenderSmfFilename
	; (no addr) LD XWA, 00008850h
	; (no addr) LD XBC, 00ea0736h
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, 00008850h
	; (no addr) CALL LABEL_F892DB

LABEL_F8DE74:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

SmfSeqToSongNumFunc:
	; (no addr) PUSH XIZ
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8DE91
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, LABEL_F8DECD
	; (no addr) LD (8090h), XDE
	; (no addr) JR T, LABEL_F8DECD

LABEL_F8DE91:
	; (no addr) LDA XWA, 8094h
	; (no addr) LD (XWA+), 000h
	; (no addr) LD XBC, 00ea073ch
	; (no addr) CALL LABEL_F890DC
	; (no addr) LDA XIZ, 8095h
	; (no addr) LD A, (8948h)
	; (no addr) INC 1, A
	; (no addr) EXTZ WA
	; (no addr) LD BC, 2
	CALR LABEL_F8B67F
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, (8090h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00008094h
	; (no addr) CALL ApPostEvent

LABEL_F8DECD:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) RET

SmfSeqFromSongNumFunc:
	; (no addr) PUSH XIZ
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8DEE8
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, LABEL_F8DF24
	; (no addr) LD (8114h), XDE
	; (no addr) JR T, LABEL_F8DF24

LABEL_F8DEE8:
	; (no addr) LDA XWA, 8118h
	; (no addr) LD (XWA+), 000h
	; (no addr) LD XBC, 00ea0748h
	; (no addr) CALL LABEL_F890DC
	; (no addr) LDA XIZ, 8119h
	; (no addr) LD A, (8948h)
	; (no addr) INC 1, A
	; (no addr) EXTZ WA
	; (no addr) LD BC, 2
	CALR LABEL_F8B67F
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, (8114h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00008118h
	; (no addr) CALL ApPostEvent

LABEL_F8DF24:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) RET

SmfSeqSongNameFunc:
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8DF3E
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, LABEL_F8DF5A
	; (no addr) LD (8198h), XDE
	; (no addr) JR T, LABEL_F8DF5A

LABEL_F8DF3E:
	; (no addr) LD A, (8948h)
	; (no addr) EXTZ WA
	; (no addr) LD BC, 0
	; (no addr) LD DE, 0
	CALR LABEL_F919E3
	; (no addr) LD XDE, XHL
	; (no addr) LD XWA, (8198h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent

LABEL_F8DF5A:
	; (no addr) LD XHL, 0
	; (no addr) RET

SmfLoadAsFunc:
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8DF73
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, LABEL_F8DF93
	; (no addr) LD (819Ch), XDE
	; (no addr) JR T, LABEL_F8DF93

LABEL_F8DF73:
	; (no addr) LD A, (8946h)
	; (no addr) EXTZ WA
	; (no addr) SLA 002h, WA
	; (no addr) LDA XBC, 0EA0754h
	; (no addr) LD XDE, (XBC + WA)
	; (no addr) LD XWA, (819Ch)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent

LABEL_F8DF93:
	; (no addr) LD XHL, 0
	; (no addr) RET

TrimAndPadSmfFilename:
	; (no addr) LD IX, 0
	; (no addr) LD XHL, XWA
	; (no addr) JR T, LABEL_F8DFB6

LABEL_F8DF9C:
	; (no addr) CP E, 07eh
	; (no addr) JR NZ, LABEL_F8DFA5
	LD_E 0x5f
	; (no addr) JR T, LABEL_F8DFAE

LABEL_F8DFA5:
	; (no addr) LD E, (XWA)
	; (no addr) CP E, 020h
	; (no addr) JR NC, LABEL_F8DFB0
	LD_E 0x20

LABEL_F8DFAE:
	; (no addr) LD (XWA), E

LABEL_F8DFB0:
	; (no addr) INC 1, IX
	; (no addr) INC 1, XWA
	; (no addr) INC 1, XHL

LABEL_F8DFB6:
	; (no addr) CP IX, BC
	; (no addr) JR NC, LABEL_F8DFC0
	; (no addr) LD E, (XHL)
	; (no addr) CP E, 0
	; (no addr) JR NZ, LABEL_F8DF9C

LABEL_F8DFC0:
	; (no addr) CP IX, BC
	; (no addr) JR NC, LABEL_F8DFCE

LABEL_F8DFC4:
	; (no addr) LD (XWA+), 020h
	; (no addr) INC 1, IX
	; (no addr) CP IX, BC
	; (no addr) JR C, LABEL_F8DFC4

LABEL_F8DFCE:
	; (no addr) LD (XWA), 000h
	; (no addr) RET

DisplaySmfFileList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), BC
	; (no addr) LD (XSP + 004h), XWA
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD IZ, 0

LABEL_F8DFE2:
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD A, IZL
	; (no addr) LD (XDE), A
	; (no addr) LD WA, (XSP + 002h)
	; (no addr) ADD WA, IZ
	; (no addr) CALL LABEL_F89BF0
	; (no addr) LD XBC, XHL
	; (no addr) LD WA, IZ
	; (no addr) SLL 5, WA
	; (no addr) LD DE, 1
	; (no addr) ADD DE, WA
	; (no addr) LDA XHL, 850Ch
	; (no addr) LD WA, DE
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XHL
	; (no addr) LD DE, (XSP + 002h)
	; (no addr) ADD DE, IZ
	; (no addr) INC 1, DE
	; (no addr) PUSHW 000ch
	; (no addr) PUSHW 0001h
	; (no addr) CALL LABEL_F891DD
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR LT, LABEL_F8DFE2
	; (no addr) POP IZ
	; (no addr) INC 6, XSP
	; (no addr) RET

ValidateSmfFilename:
	; (no addr) LD IY, 0
	; (no addr) LD HL, 0
	; (no addr) JR T, LABEL_F8E05A

LABEL_F8E04E:
	; (no addr) CP E, 020h
	; (no addr) JR Z, LABEL_F8E056
	LD_L 0x0
	; (no addr) RET

LABEL_F8E056:
	; (no addr) INC 1, IY
	; (no addr) INC 1, HL

LABEL_F8E05A:
	; (no addr) LD E, (XWA + IY)
	; (no addr) CP E, 0
	; (no addr) JR Z, LABEL_F8E067
	; (no addr) CP HL, BC
	; (no addr) JR C, LABEL_F8E04E

LABEL_F8E067:
	LD_L 0x1
	; (no addr) RET

FmmSmfFileNameFunc:
	; (no addr) LDA XSP, XSP - 020h
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XDE
	; (no addr) LD (XSP + 01ch), XBC
	; (no addr) LD (XSP + 020h), XWA
	; (no addr) LD XDE, (XSP + 01ch)
	; (no addr) LD XWA, (81A0h)
	; (no addr) LD XBC, (XSP + 01ch)
	; (no addr) CP XBC, 01c00018h
	; (no addr) JRL Z, LABEL_F8E134
	; (no addr) CP XBC, 01c00017h
	; (no addr) JRL Z, LABEL_F8E134
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JRL Z, LABEL_F8E11E
	; (no addr) LD XBC, XIZ
	; (no addr) SUB XDE, 01e50002h
	; (no addr) CP XDE, 00000000h
	; (no addr) JRL LT, LABEL_F8E12F
	; (no addr) CP XDE, 00000005h
	; (no addr) JR GT, LABEL_F8E12F
	; (no addr) ADD XDE, XDE
	; (no addr) ADD XDE, 00ea079eh
	; (no addr) LD DE, (XDE)
	; (no addr) LDA XIX, 0F8E0C8h
	; (no addr) JP T, XIX + DE
LABEL_F8E0C8:
	.byte 0xF1, 0xA0, 0x81, 0x61, 0xE8, 0xA8, 0xF1, 0xA4
	.byte 0x81, 0x60, 0xF1, 0xA8, 0x81, 0x60, 0xC1, 0x36
	.byte 0x8D, 0x3F, 0x6B, 0x66, 0x14, 0x1D, 0xC7, 0x9A
	.byte 0xF8, 0xF1, 0xAC, 0x81, 0x53, 0xDB, 0xD8, 0x69
	.byte 0x1A, 0xF1, 0xAC, 0x81, 0x2, 0x0, 0x0, 0x68
	.byte 0x12, 0xD1, 0x4, 0x85, 0x20, 0xF1, 0xAC, 0x81
	.byte 0x50, 0xD8, 0xD8, 0x62, 0x2, 0xD8, 0x69, 0x1D
	.byte 0xA4, 0x9B, 0xF8, 0xD1, 0xAC, 0x81, 0x20, 0xE8
	.byte 0x13, 0xD8, 0xB, 0xA, 0x0, 0xD7, 0xE2, 0x8A
	.byte 0xEA, 0x13, 0xE1, 0xA0, 0x81, 0x20, 0x41, 0x2
	.byte 0x0, 0xE5, 0x1, 0x78, 0x89, 0x7

LABEL_F8E11E:
	; (no addr) LD BC, (81ACh)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	MULS_BC 0xa
	CALR DisplaySmfFileList

LABEL_F8E12F:
	; (no addr) LD XHL, 0
	; (no addr) JRL T, LABEL_F8E8B4

LABEL_F8E134:
	; (no addr) LD XBC, 01c50001h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD IX, (81ACh)
	; (no addr) LD (XSP + 004h), IX
	; (no addr) OR XIZ, XIZ
	; (no addr) JR NZ, LABEL_F8E192
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, LABEL_F8E192
	; (no addr) LD XWA, (XSP + 01ch)
	; (no addr) CP XWA, 01c00018h
	; (no addr) JR NZ, LABEL_F8E180
	; (no addr) LD BC, IX
	; (no addr) INC 1, BC
	; (no addr) CP (8D36h), 06bh
	; (no addr) JR Z, LABEL_F8E170
	; (no addr) CP BC, (8504h)
	; (no addr) JR LT, LABEL_F8E17B
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E170:
	; (no addr) LD WA, (8504h)
	; (no addr) INC 1, WA
	; (no addr) CP BC, WA
	; (no addr) JRL GE, LABEL_F8E75D

LABEL_F8E17B:
	; (no addr) INC 1, IX
	; (no addr) JRL T, LABEL_F8E211

LABEL_F8E180:
	; (no addr) CP XWA, 01c00017h
	; (no addr) JRL NZ, LABEL_F8E75D
	; (no addr) CP IX, 0
	; (no addr) JRL LE, LABEL_F8E75D
	; (no addr) DEC 1, IX
	; (no addr) JR T, LABEL_F8E211

LABEL_F8E192:
	; (no addr) CP XIZ, 00000001h
	; (no addr) JR NZ, LABEL_F8E1AE
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, LABEL_F8E1AE
	; (no addr) CP IX, 000ah
	; (no addr) JRL LT, LABEL_F8E75D
	; (no addr) SUB IX, 000ah
	; (no addr) JR T, LABEL_F8E211

LABEL_F8E1AE:
	; (no addr) CP XIZ, 00000002h
	; (no addr) JRL NZ, LABEL_F8E23C
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, LABEL_F8E23C
	; (no addr) LD IY, IX
	; (no addr) ADD IY, 000ah
	; (no addr) LD BC, (8504h)
	; (no addr) LD DE, IX
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) CP (8D36h), 06bh
	; (no addr) JR Z, LABEL_F8E205
	; (no addr) LD HL, BC
	; (no addr) CP IY, BC
	; (no addr) JR LT, LABEL_F8E20D
	; (no addr) LD BC, HL
	; (no addr) DEC 1, BC
	; (no addr) LD WA, BC
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) CP DE, WA
	; (no addr) JRL GE, LABEL_F8E75D
	; (no addr) EXTS XHL
	DIVS_HL 0xa
	; (no addr) LD WA, QHL
	; (no addr) CP WA, 0
	; (no addr) JRL Z, LABEL_F8E75D
	; (no addr) LD (81ACh), BC
	; (no addr) LD HL, BC
	; (no addr) JRL T, LABEL_F8E761

LABEL_F8E205:
	; (no addr) LD HL, BC
	; (no addr) INC 1, BC
	; (no addr) CP IY, BC
	; (no addr) JR GE, LABEL_F8E21A

LABEL_F8E20D:
	; (no addr) ADD IX, 000ah

LABEL_F8E211:
	; (no addr) LD (81ACh), IX
	; (no addr) LD HL, IX
	; (no addr) JRL T, LABEL_F8E761

LABEL_F8E21A:
	; (no addr) LD WA, HL
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) CP DE, WA
	; (no addr) JRL GE, LABEL_F8E75D
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	; (no addr) LD WA, QBC
	; (no addr) CP WA, 0
	; (no addr) JRL Z, LABEL_F8E75D
	; (no addr) LD (81ACh), HL
	; (no addr) JRL T, LABEL_F8E761

LABEL_F8E23C:
	; (no addr) CP XIZ, 00000003h
	; (no addr) JRL NZ, LABEL_F8E348
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD A, (8948h)
	; (no addr) EXTZ WA
	; (no addr) LD C, (8946h)
	; (no addr) EXTZ BC
	; (no addr) CALL LoadFileSMF
	; (no addr) LD (XSP + 006h), HL
	CALR SignalProgressUpdate
	; (no addr) CPW (XSP + 006h), 0000h
	; (no addr) JR LT, LABEL_F8E2F3
	; (no addr) LD WA, (81ACh)
	; (no addr) CALL LABEL_F8A07F
	; (no addr) LD XBC, XHL
	; (no addr) LDA XWA, XSP + 008h
	; (no addr) LD DE, 0010h
	; (no addr) CALL LABEL_F890F2
	; (no addr) LDA XWA, XSP + 008h
	; (no addr) LD BC, 0010h
	CALR ValidateSmfFilename
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8E2AC
	; (no addr) LD WA, (81ACh)
	; (no addr) CALL LABEL_F89BF0
	; (no addr) LD XBC, XHL
	; (no addr) LDA XWA, XSP + 008h
	; (no addr) LD DE, 0008h
	; (no addr) CALL LABEL_F890F2

LABEL_F8E2AC:
	; (no addr) LDA XWA, XSP + 008h
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) LDA XWA, 0AB000h
	; (no addr) LD XBC, 0
	; (no addr) LD C, (8948h)
	; (no addr) SLL 11, XBC
	; (no addr) ADD XWA, XBC
	; (no addr) LDA XWA, XWA + 0100h
	; (no addr) LDA XBC, XSP + 008h
	; (no addr) LD DE, 0010h
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD A, (00FFE3h:24)
	; (no addr) CP A, (8948h)
	; (no addr) JR NZ, LABEL_F8E2F3
	; (no addr) LDA XWA, 0F180h:24
	; (no addr) LDA XWA, XWA + 0100h
	; (no addr) LDA XBC, XSP + 008h
	; (no addr) LD DE, 0010h
	; (no addr) CALL LABEL_F890F2

LABEL_F8E2F3:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (0F19Eh), 0000h
	; (no addr) JR Z, LABEL_F8E320
	; (no addr) LD WA, 000ah
	; (no addr) JR T, LABEL_F8E322

LABEL_F8E320:
	; (no addr) LD WA, 1

LABEL_F8E322:
	; (no addr) CALL LABEL_F99463
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) LD BC, 1
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8E5A5

LABEL_F8E348:
	; (no addr) CP XIZ, 00000004h
	; (no addr) JRL NZ, LABEL_F8E41B
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL LABEL_F892D5
	; (no addr) LD XWA, XHL
	; (no addr) CALL LABEL_F8947D
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8E3A6
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, LABEL_F8E3A6
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) JRL T, LABEL_F8E759

LABEL_F8E3A6:
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD A, (8948h)
	; (no addr) EXTZ WA
	; (no addr) LD C, (894Ah)
	; (no addr) EXTZ BC
	; (no addr) LD E, (894Ch)
	; (no addr) EXTZ DE
	; (no addr) CALL LABEL_F8805B
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 1
	; (no addr) CALL LABEL_F99463
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8E5A5

LABEL_F8E41B:
	; (no addr) CP XIZ, 00000032h
	; (no addr) JRL NZ, LABEL_F8E4A9
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD A, (8948h)
	; (no addr) EXTZ WA
	; (no addr) LD C, (894Ah)
	; (no addr) EXTZ BC
	; (no addr) LD E, (894Ch)
	; (no addr) EXTZ DE
	; (no addr) CALL LABEL_F8805B
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 1
	; (no addr) CALL LABEL_F99463
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8E5A5

LABEL_F8E4A9:
	; (no addr) CP XIZ, 00000005h
	; (no addr) JRL NZ, LABEL_F8E53C
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, LABEL_F8E4D9
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 007b0051h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) JRL T, LABEL_F8E759

LABEL_F8E4D9:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F88B22
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, (81ACh)
	; (no addr) CP WA, (8504h)
	; (no addr) JR LT, LABEL_F8E537
	; (no addr) CP WA, 0
	; (no addr) JR LE, LABEL_F8E537
	; (no addr) DEC 1, WA
	; (no addr) LD (81ACh), WA
	; (no addr) LD (XSP + 004h), WA

LABEL_F8E537:
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8E5A5

LABEL_F8E53C:
	; (no addr) CP XIZ, 00000033h
	; (no addr) JR NZ, LABEL_F8E5AC
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F88B22
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, (81ACh)
	; (no addr) CP WA, (8504h)
	; (no addr) JR LT, LABEL_F8E5A2
	; (no addr) CP WA, 0
	; (no addr) JR LE, LABEL_F8E5A2
	; (no addr) DEC 1, WA
	; (no addr) LD (81ACh), WA
	; (no addr) LD (XSP + 004h), WA

LABEL_F8E5A2:
	; (no addr) LD WA, 00eeh

LABEL_F8E5A5:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E5AC:
	; (no addr) CP XIZ, 0000000ah
	; (no addr) JRL Z, LABEL_F8E75D
	; (no addr) CP XIZ, 0000000bh
	; (no addr) JRL Z, LABEL_F8E75D
	; (no addr) CP XIZ, 0000000ch
	; (no addr) JRL Z, LABEL_F8E75D
	; (no addr) CP XIZ, 0000000dh
	; (no addr) JRL Z, LABEL_F8E75D
	; (no addr) CP XIZ, 00000014h
	; (no addr) JR NZ, LABEL_F8E5FA
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, LABEL_F8E5FA
	; (no addr) LD XWA, (XSP + 01ch)
	; (no addr) CP XWA, 01c00017h
	; (no addr) JR NZ, LABEL_F8E5F2
	; (no addr) LD (8942h), 001h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E5F2:
	; (no addr) LD (8942h), 000h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E5FA:
	; (no addr) CP XIZ, 00000015h
	; (no addr) JR NZ, LABEL_F8E635
	; (no addr) LD C, (8946h)
	; (no addr) LD A, C
	; (no addr) INC 1, A
	; (no addr) CP A, 3
	; (no addr) JR NC, LABEL_F8E620
	; (no addr) INC 1, C
	; (no addr) LD (8946h), C
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8E62F

LABEL_F8E620:
	; (no addr) LD (8946h), 000h
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0

LABEL_F8E62F:
	CALR SmfLoadAsFunc
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E635:
	; (no addr) CP XIZ, 00000016h
	; (no addr) JR NZ, LABEL_F8E658
	; (no addr) LD XWA, (XSP + 01ch)
	; (no addr) CP XWA, 01c00017h
	; (no addr) JR NZ, LABEL_F8E650
	; (no addr) LD (894Ah), 001h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E650:
	; (no addr) LD (894Ah), 000h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E658:
	; (no addr) LD XWA, (XSP + 01ch)
	; (no addr) CP XIZ, 00000017h
	; (no addr) JR NZ, LABEL_F8E67B
	; (no addr) CP XWA, 01c00017h
	; (no addr) JR NZ, LABEL_F8E673
	; (no addr) LD (894Ch), 001h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E673:
	; (no addr) LD (894Ch), 000h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E67B:
	; (no addr) CP XIZ, 00000018h
	; (no addr) JR NZ, LABEL_F8E69B
	; (no addr) CP XWA, 01c00017h
	; (no addr) JR NZ, LABEL_F8E693
	; (no addr) LD (8944h), 001h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E693:
	; (no addr) LD (8944h), 000h
	; (no addr) JRL T, LABEL_F8E75D

LABEL_F8E69B:
	; (no addr) LD C, (8948h)
	; (no addr) LD A, C
	; (no addr) INC 1, A
	; (no addr) CP XIZ, 0000001eh
	; (no addr) JR NZ, LABEL_F8E6ED
	; (no addr) CP A, 00ah
	; (no addr) JR NC, LABEL_F8E6CF
	; (no addr) INC 1, C
	; (no addr) LD (8948h), C
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR SmfSeqToSongNumFunc
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8E735

LABEL_F8E6CF:
	; (no addr) LD (8948h), 000h
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR SmfSeqToSongNumFunc
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8E735

LABEL_F8E6ED:
	; (no addr) CP XIZ, 0000001fh
	; (no addr) JR NZ, LABEL_F8E73A
	; (no addr) CP A, 00ah
	; (no addr) JR NC, LABEL_F8E719
	; (no addr) INC 1, C
	; (no addr) LD (8948h), C
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR SmfSeqFromSongNumFunc
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8E735

LABEL_F8E719:
	; (no addr) LD (8948h), 000h
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR SmfSeqFromSongNumFunc
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0

LABEL_F8E735:
	CALR SmfSeqSongNameFunc
	; (no addr) JR T, LABEL_F8E75D

LABEL_F8E73A:
	; (no addr) CP XIZ, 00000028h
	; (no addr) JR NZ, LABEL_F8E75D
	; (no addr) CPW (81AEh), 0000h
	; (no addr) JR Z, LABEL_F8E75D
	; (no addr) LD XWA, (81A4h)
	; (no addr) OR XWA, XWA
	; (no addr) JR Z, LABEL_F8E75D
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0

LABEL_F8E759:
	; (no addr) CALL ApPostEvent

LABEL_F8E75D:
	; (no addr) LD HL, (81ACh)

LABEL_F8E761:
	; (no addr) CP (XSP + 004h), HL
	; (no addr) JRL Z, LABEL_F8E85B
	; (no addr) LD WA, HL
	; (no addr) CALL LABEL_F89BA4
	; (no addr) LD WA, (81ACh)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (81A0h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD BC, (81ACh)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	; (no addr) LD DE, (XSP + 004h)
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD XWA, (81A0h)
	; (no addr) CP DE, BC
	; (no addr) JR NZ, LABEL_F8E7EF
	; (no addr) LD BC, (XSP + 004h)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	; (no addr) LD BC, QBC
	; (no addr) SLL 5, BC
	; (no addr) LDA XHL, 850Ch
	; (no addr) LD DE, BC
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XHL
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, (81ACh)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD WA, QWA
	; (no addr) SLL 5, WA
	; (no addr) LDA XBC, 850Ch
	; (no addr) LD DE, WA
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (81A0h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8E80A

LABEL_F8E7EF:
	MULS_BC 0xa
	CALR DisplaySmfFileList
	; (no addr) CP (8D36h), 06ch
	; (no addr) JR NZ, LABEL_F8E80A
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmSmfMedleyFunc

LABEL_F8E80A:
	; (no addr) CP (8D36h), 06bh
	; (no addr) JR NZ, LABEL_F8E85B
	; (no addr) LDA XIZ, 8850h
	; (no addr) LD WA, (81ACh)
	; (no addr) CP WA, (8504h)
	; (no addr) JR LT, LABEL_F8E830
	; (no addr) CP WA, 0
	; (no addr) JR LE, LABEL_F8E830
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 00ea0790h
	; (no addr) CALL LABEL_F890DC
	; (no addr) JR T, LABEL_F8E845

LABEL_F8E830:
	; (no addr) CALL LABEL_F89BF0
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 00008850h
	; (no addr) CALL LABEL_F8929D

LABEL_F8E845:
	; (no addr) LD XWA, 00008850h
	; (no addr) CALL LABEL_F892DB
	; (no addr) LD XWA, (XSP + 020h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR SaveFileNameSmfFunc

LABEL_F8E85B:
	; (no addr) LD XWA, (81A0h)
	; (no addr) LD XBC, 01c50001h
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8E8A7
	; (no addr) LD (81A4h), XBC
	; (no addr) JRL T, LABEL_F8E12F
	; (no addr) LD (81A8h), XBC
	; (no addr) JRL T, LABEL_F8E12F
	; (no addr) LD (81AEh), IZ
	; (no addr) JRL T, LABEL_F8E12F
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL Z, LABEL_F8E12F
	; (no addr) LD WA, IZ
	; (no addr) LD (81ACh), WA
	; (no addr) CALL LABEL_F89BA4
	; (no addr) LD WA, (81ACh)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (81A0h)
	; (no addr) LD XBC, 01e50002h

LABEL_F8E8A7:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, LABEL_F8E12F
	; (no addr) LD HL, (81ACh)
	; (no addr) EXTS XHL

LABEL_F8E8B4:
	; (no addr) POP XIZ
	; (no addr) LDA XSP, XSP + 020h
	; (no addr) RET

DisplaySmfSequenceList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), BC
	; (no addr) LD (XSP + 004h), XWA
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD IZ, 0

LABEL_F8E8C9:
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD A, IZL
	; (no addr) LD (XDE), A
	; (no addr) LD WA, (XSP + 002h)
	; (no addr) ADD WA, IZ
	; (no addr) CALL LABEL_F8B13D
	; (no addr) LD XBC, XHL
	; (no addr) LD WA, IZ
	; (no addr) SLL 5, WA
	; (no addr) LD DE, 1
	; (no addr) ADD DE, WA
	; (no addr) LDA XHL, 850Ch
	; (no addr) LD WA, DE
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XHL
	; (no addr) LD DE, (XSP + 002h)
	; (no addr) ADD DE, IZ
	; (no addr) INC 1, DE
	; (no addr) PUSHW 000ch
	; (no addr) PUSHW 0001h
	; (no addr) CALL LABEL_F891DD
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR LT, LABEL_F8E8C9
	; (no addr) POP IZ
	; (no addr) INC 6, XSP
	; (no addr) RET

