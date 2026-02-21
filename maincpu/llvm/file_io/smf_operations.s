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
	cp XBC, 0x1c00007
	jrl Z, LABEL_F8DCE2
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8DCFD
	cp XDE, 0x3
	jrl Z, LABEL_F8DCDD
	cp XDE, 0x2
	jrl NZ, LABEL_F8DCFD
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	LD_8_8 0x808A, 0x8D37
	cpw (0x8500), 0x0
	jr GE, LABEL_F8DBA6
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8DBA6:
	ld WA, (0x8500)
	cp WA, 1
	jrl Z, LABEL_F8DC70
	cp WA, 0
	jrl Z, LABEL_F8DC5A
	cp WA, 5
	jr Z, LABEL_F8DC16
	cpw (0x8504), 0x0
	jr GE, LABEL_F8DBD3
	call GetFileCountEncoded
	ld (0x8504), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8DBD3:
	cpw (0x8504), 0x0
	jrl NZ, LABEL_F8DCBB
	cpw (0x8502), 0x0
	jr GE, LABEL_F8DBEF
	call GetEncodedFileSizeData
	ld (0x8502), HL
	CALR SignalProgressUpdate

LABEL_F8DBEF:
	cpw (0x8502), 0x0
	jrl LE, LABEL_F8DCBB
	cp (0x808A), 0x61
	jrl Z, LABEL_F8DCBB
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x61
	jrl LABEL_F8DCF9

LABEL_F8DC16:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x808A)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x0
	ld WA, 0xee
	jr LABEL_F8DCB5

LABEL_F8DC5A:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x7d
	jrl LABEL_F8DCF9

LABEL_F8DC70:
	CALR ResetProgressIndication
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x808A)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x2
	ld WA, 0xee

LABEL_F8DCB5:
	call LABEL_F994BD
	jr LABEL_F8DCFD

LABEL_F8DCBB:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	jr LABEL_F8DCFD

LABEL_F8DCDD:
	CALR CancelOperationCleanup
	jr LABEL_F8DCFD

LABEL_F8DCE2:
	cp XDE, 0xf
	jr NZ, LABEL_F8DCFD
	cp (0x8D34), 0x7
	jr NZ, LABEL_F8DCF6
	ld WA, 0xd6
	jr LABEL_F8DCF9

LABEL_F8DCF6:
	ld WA, 0x60

LABEL_F8DCF9:
	call UI_PostModeChangeEvent

LABEL_F8DCFD:
	ld XHL, 0
	ret

FmmSmfSaveTitleFunc:
	cp XBC, 0x1c00013
	jr NZ, LABEL_F8DD72
	cp XDE, 0x3
	jr Z, LABEL_F8DD6F
	cp XDE, 0x2
	jr NZ, LABEL_F8DD72
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	cpw (0x8504), 0x0
	jr GE, LABEL_F8DD4D
	call GetFileCountEncoded
	ld (0x8504), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8DD4D:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	jr LABEL_F8DD72

LABEL_F8DD6F:
	CALR CancelOperationCleanup

LABEL_F8DD72:
	ld XHL, 0
	ret

RenderSmfFilename:
	extz BC
	ld (XWA + BC), 0x0
	ld IX, 0
	lda XHL, 0xEED778
	jr LABEL_F8DD97

LABEL_F8DD86:
	extz BC
	ld C, (XHL + BC)
	and C, 0x7
	jr NZ, LABEL_F8DD95
	ld (XDE), 0x5f

LABEL_F8DD95:
	inc 1, IX

LABEL_F8DD97:
	cp IX, 0x8
	jr GE, LABEL_F8DDA8
	lda XDE, XWA + IX
	ld C, (XDE)
	cp C, 0
	jr NZ, LABEL_F8DD86

LABEL_F8DDA8:
	cp IX, 0x8
	ret GE

LABEL_F8DDAE:
	ld (XWA + IX), 0x5f
	inc 1, IX
	cp IX, 0x8
	jr LT, LABEL_F8DDAE
	ret

SaveFileNameSmfFunc:
	dec 4, XSP
	push XIZ
	ld (XSP + 0x4), XDE
	lda XWA, 0x8850
	cp XBC, 0x1e00086
	jr Z, LABEL_F8DE48
	cp XBC, 0x1e0003a
	jr Z, LABEL_F8DE1C
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8DDF2
	cp XBC, 0x1e50004
	jrl NZ, LABEL_F8DE74
	ld XWA, (XSP + 0x4)
	ld (0x808C), XWA
	jrl LABEL_F8DE74

LABEL_F8DDF2:
	ld (XWA), 0x0
	lda XIZ, XWA + 0x1
	call LABEL_F892D5
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	lda XWA, 0x8851
	call LABEL_F8929D
	ld XWA, (0x808C)
	ld XBC, 0x1c0000f
	ld XDE, 0x8850
	jr LABEL_F8DE42

LABEL_F8DE1C:
	ld XIZ, XWA
	call LABEL_F892D5
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld XWA, 0x8850
	ld BC, 0x8
	CALR RenderSmfFilename
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1e00086
	ld XDE, 0x8850

LABEL_F8DE42:
	call ApPostEvent
	jr LABEL_F8DE74

LABEL_F8DE48:
	ld XBC, (XSP + 0x4)
	ld DE, 0x8
	call LABEL_F890F2
	ld XWA, 0x8850
	ld BC, 0x8
	CALR RenderSmfFilename
	ld XWA, 0x8850
	ld XBC, 0xea0736
	call LABEL_F89113
	ld XWA, 0x8850
	call LABEL_F892DB

LABEL_F8DE74:
	ld XHL, 0
	pop XIZ
	inc 4, XSP
	ret

SmfSeqToSongNumFunc:
	push XIZ
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8DE91
	cp XBC, 0x1e50004
	jr NZ, LABEL_F8DECD
	ld (0x8090), XDE
	jr LABEL_F8DECD

LABEL_F8DE91:
	lda XWA, 0x8094
	ld (XWA+), 0x0
	ld XBC, 0xea073c
	call LABEL_F890DC
	lda XIZ, 0x8095
	ld A, (0x8948)
	inc 1, A
	extz WA
	ld BC, 2
	CALR LABEL_F8B67F
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F89113
	ld XWA, (0x8090)
	ld XBC, 0x1c0000f
	ld XDE, 0x8094
	call ApPostEvent

LABEL_F8DECD:
	ld XHL, 0
	pop XIZ
	ret

SmfSeqFromSongNumFunc:
	push XIZ
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8DEE8
	cp XBC, 0x1e50004
	jr NZ, LABEL_F8DF24
	ld (0x8114), XDE
	jr LABEL_F8DF24

LABEL_F8DEE8:
	lda XWA, 0x8118
	ld (XWA+), 0x0
	ld XBC, 0xea0748
	call LABEL_F890DC
	lda XIZ, 0x8119
	ld A, (0x8948)
	inc 1, A
	extz WA
	ld BC, 2
	CALR LABEL_F8B67F
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F89113
	ld XWA, (0x8114)
	ld XBC, 0x1c0000f
	ld XDE, 0x8118
	call ApPostEvent

LABEL_F8DF24:
	ld XHL, 0
	pop XIZ
	ret

SmfSeqSongNameFunc:
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8DF3E
	cp XBC, 0x1e50004
	jr NZ, LABEL_F8DF5A
	ld (0x8198), XDE
	jr LABEL_F8DF5A

LABEL_F8DF3E:
	ld A, (0x8948)
	extz WA
	ld BC, 0
	ld DE, 0
	CALR LABEL_F919E3
	ld XDE, XHL
	ld XWA, (0x8198)
	ld XBC, 0x1c0000f
	call ApPostEvent

LABEL_F8DF5A:
	ld XHL, 0
	ret

SmfLoadAsFunc:
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8DF73
	cp XBC, 0x1e50004
	jr NZ, LABEL_F8DF93
	ld (0x819C), XDE
	jr LABEL_F8DF93

LABEL_F8DF73:
	ld A, (0x8946)
	extz WA
	sla WA, 0x2
	lda XBC, 0xEA0754
	ld XDE, (XBC + WA)
	ld XWA, (0x819C)
	ld XBC, 0x1c0000f
	call ApPostEvent

LABEL_F8DF93:
	ld XHL, 0
	ret

TrimAndPadSmfFilename:
	ld IX, 0
	ld XHL, XWA
	jr LABEL_F8DFB6

LABEL_F8DF9C:
	cp E, 0x7e
	jr NZ, LABEL_F8DFA5
	LD_E 0x5f
	jr LABEL_F8DFAE

LABEL_F8DFA5:
	ld E, (XWA)
	cp E, 0x20
	jr NC, LABEL_F8DFB0
	LD_E 0x20

LABEL_F8DFAE:
	ld (XWA), E

LABEL_F8DFB0:
	inc 1, IX
	inc 1, XWA
	inc 1, XHL

LABEL_F8DFB6:
	cp IX, BC
	jr NC, LABEL_F8DFC0
	ld E, (XHL)
	cp E, 0
	jr NZ, LABEL_F8DF9C

LABEL_F8DFC0:
	cp IX, BC
	jr NC, LABEL_F8DFCE

LABEL_F8DFC4:
	ld (XWA+), 0x20
	inc 1, IX
	cp IX, BC
	jr C, LABEL_F8DFC4

LABEL_F8DFCE:
	ld (XWA), 0x0
	ret

DisplaySmfFileList:
	dec 6, XSP
	push IZ
	ld (XSP + 0x2), BC
	ld (XSP + 0x4), XWA
	ld WA, 0
	CALR InitializeOperationState
	ld IZ, 0

LABEL_F8DFE2:
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld A, IZL
	ld (XDE), A
	ld WA, (XSP + 0x2)
	add WA, IZ
	call LABEL_F89BF0
	ld XBC, XHL
	ld WA, IZ
	sll WA, 5
	ld DE, 1
	add DE, WA
	lda XHL, 0x850C
	ld WA, DE
	extz XWA
	add XWA, XHL
	ld DE, (XSP + 0x2)
	add DE, IZ
	inc 1, DE
	pushw 0xc
	pushw 0x1
	call LABEL_F891DD
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr LT, LABEL_F8DFE2
	pop IZ
	inc 6, XSP
	ret

ValidateSmfFilename:
	ld IY, 0
	ld HL, 0
	jr LABEL_F8E05A

LABEL_F8E04E:
	cp E, 0x20
	jr Z, LABEL_F8E056
	LD_L 0x0
	ret

LABEL_F8E056:
	inc 1, IY
	inc 1, HL

LABEL_F8E05A:
	ld E, (XWA + IY)
	cp E, 0
	jr Z, LABEL_F8E067
	cp HL, BC
	jr C, LABEL_F8E04E

LABEL_F8E067:
	LD_L 0x1
	ret

FmmSmfFileNameFunc:
	lda XSP, XSP - 0x20
	push XIZ
	ld XIZ, XDE
	ld (XSP + 0x1c), XBC
	ld (XSP + 0x20), XWA
	ld XDE, (XSP + 0x1c)
	ld XWA, (0x81A0)
	ld XBC, (XSP + 0x1c)
	cp XBC, 0x1c00018
	jrl Z, LABEL_F8E134
	cp XBC, 0x1c00017
	jrl Z, LABEL_F8E134
	cp XBC, 0x1c0000b
	jrl Z, LABEL_F8E11E
	ld XBC, XIZ
	sub XDE, 0x1e50002
	cp XDE, 0x0
	jrl LT, LABEL_F8E12F
	cp XDE, 0x5
	jr GT, LABEL_F8E12F
	add XDE, XDE
	add XDE, 0xea079e
	ld DE, (XDE)
	lda XIX, 0xF8E0C8
	jp XIX + DE
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
	ld BC, (0x81AC)
	exts XBC
	DIVS_BC 0xa
	MULS_BC 0xa
	CALR DisplaySmfFileList

LABEL_F8E12F:
	ld XHL, 0
	jrl LABEL_F8E8B4

LABEL_F8E134:
	ld XBC, 0x1c50001
	ld XDE, 1
	call ApPostEvent
	ld IX, (0x81AC)
	ld (XSP + 0x4), IX
	or XIZ, XIZ
	jr NZ, LABEL_F8E192
	cp (0x84FE), 0x0
	jr NZ, LABEL_F8E192
	ld XWA, (XSP + 0x1c)
	cp XWA, 0x1c00018
	jr NZ, LABEL_F8E180
	ld BC, IX
	inc 1, BC
	cp (0x8D36), 0x6b
	jr Z, LABEL_F8E170
	cp BC, (0x8504)
	jr LT, LABEL_F8E17B
	jrl LABEL_F8E75D

LABEL_F8E170:
	ld WA, (0x8504)
	inc 1, WA
	cp BC, WA
	jrl GE, LABEL_F8E75D

LABEL_F8E17B:
	inc 1, IX
	jrl LABEL_F8E211

LABEL_F8E180:
	cp XWA, 0x1c00017
	jrl NZ, LABEL_F8E75D
	cp IX, 0
	jrl LE, LABEL_F8E75D
	dec 1, IX
	jr LABEL_F8E211

LABEL_F8E192:
	cp XIZ, 0x1
	jr NZ, LABEL_F8E1AE
	cp (0x84FE), 0x0
	jr NZ, LABEL_F8E1AE
	cp IX, 0xa
	jrl LT, LABEL_F8E75D
	sub IX, 0xa
	jr LABEL_F8E211

LABEL_F8E1AE:
	cp XIZ, 0x2
	jrl NZ, LABEL_F8E23C
	cp (0x84FE), 0x0
	jr NZ, LABEL_F8E23C
	ld IY, IX
	add IY, 0xa
	ld BC, (0x8504)
	ld DE, IX
	exts XDE
	DIVS_DE 0xa
	cp (0x8D36), 0x6b
	jr Z, LABEL_F8E205
	ld HL, BC
	cp IY, BC
	jr LT, LABEL_F8E20D
	ld BC, HL
	dec 1, BC
	ld WA, BC
	exts XWA
	DIVS_WA 0xa
	cp DE, WA
	jrl GE, LABEL_F8E75D
	exts XHL
	DIVS_HL 0xa
	ld WA, QHL
	cp WA, 0
	jrl Z, LABEL_F8E75D
	ld (0x81AC), BC
	ld HL, BC
	jrl LABEL_F8E761

LABEL_F8E205:
	ld HL, BC
	inc 1, BC
	cp IY, BC
	jr GE, LABEL_F8E21A

LABEL_F8E20D:
	add IX, 0xa

LABEL_F8E211:
	ld (0x81AC), IX
	ld HL, IX
	jrl LABEL_F8E761

LABEL_F8E21A:
	ld WA, HL
	exts XWA
	DIVS_WA 0xa
	cp DE, WA
	jrl GE, LABEL_F8E75D
	exts XBC
	DIVS_BC 0xa
	ld WA, QBC
	cp WA, 0
	jrl Z, LABEL_F8E75D
	ld (0x81AC), HL
	jrl LABEL_F8E761

LABEL_F8E23C:
	cp XIZ, 0x3
	jrl NZ, LABEL_F8E348
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld A, (0x8948)
	extz WA
	ld C, (0x8946)
	extz BC
	call LoadFileSMF
	ld (XSP + 0x6), HL
	CALR SignalProgressUpdate
	cpw (XSP + 0x6), 0x0
	jr LT, LABEL_F8E2F3
	ld WA, (0x81AC)
	call LABEL_F8A07F
	ld XBC, XHL
	lda XWA, XSP + 0x8
	ld DE, 0x10
	call LABEL_F890F2
	lda XWA, XSP + 0x8
	ld BC, 0x10
	CALR ValidateSmfFilename
	cp L, 0
	jr Z, LABEL_F8E2AC
	ld WA, (0x81AC)
	call LABEL_F89BF0
	ld XBC, XHL
	lda XWA, XSP + 0x8
	ld DE, 0x8
	call LABEL_F890F2

LABEL_F8E2AC:
	lda XWA, XSP + 0x8
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	lda XWA, 0xAB000
	ld XBC, 0
	ld C, (0x8948)
	sll XBC, 11
	add XWA, XBC
	lda XWA, XWA + 0x100
	lda XBC, XSP + 0x8
	ld DE, 0x10
	call LABEL_F890F2
	ld A, (0xFFE3)
	cp A, (0x8948)
	jr NZ, LABEL_F8E2F3
	lda XWA, 0xF180
	lda XWA, XWA + 0x100
	lda XBC, XSP + 0x8
	ld DE, 0x10
	call LABEL_F890F2

LABEL_F8E2F3:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	cpw (0xF19E), 0x0
	jr Z, LABEL_F8E320
	ld WA, 0xa
	jr LABEL_F8E322

LABEL_F8E320:
	ld WA, 1

LABEL_F8E322:
	call LABEL_F99463
	ld WA, (XSP + 0x6)
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jrl LABEL_F8E5A5

LABEL_F8E348:
	cp XIZ, 0x4
	jrl NZ, LABEL_F8E41B
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call LABEL_F892D5
	ld XWA, XHL
	call LABEL_F8947D
	cp L, 0
	jr Z, LABEL_F8E3A6
	cp (0x340EA), 0x0
	jr Z, LABEL_F8E3A6
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x600037
	ld XBC, 0x1c00001
	ld XDE, 0
	jrl LABEL_F8E759

LABEL_F8E3A6:
	ld WA, 0
	CALR InitializeOperationState
	ld A, (0x8948)
	extz WA
	ld C, (0x894A)
	extz BC
	ld E, (0x894C)
	extz DE
	call LABEL_F8805B
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8504), HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 1
	call LABEL_F99463
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jrl LABEL_F8E5A5

LABEL_F8E41B:
	cp XIZ, 0x32
	jrl NZ, LABEL_F8E4A9
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld A, (0x8948)
	extz WA
	ld C, (0x894A)
	extz BC
	ld E, (0x894C)
	extz DE
	call LABEL_F8805B
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8504), HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 1
	call LABEL_F99463
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jrl LABEL_F8E5A5

LABEL_F8E4A9:
	cp XIZ, 0x5
	jrl NZ, LABEL_F8E53C
	cp (0x340EA), 0x0
	jr Z, LABEL_F8E4D9
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x7b0051
	ld XBC, 0x1c00001
	ld XDE, 0
	jrl LABEL_F8E759

LABEL_F8E4D9:
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F88B22
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8504), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, (0x81AC)
	cp WA, (0x8504)
	jr LT, LABEL_F8E537
	cp WA, 0
	jr LE, LABEL_F8E537
	dec 1, WA
	ld (0x81AC), WA
	ld (XSP + 0x4), WA

LABEL_F8E537:
	ld WA, 0xee
	jr LABEL_F8E5A5

LABEL_F8E53C:
	cp XIZ, 0x33
	jr NZ, LABEL_F8E5AC
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F88B22
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8504), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, (0x81AC)
	cp WA, (0x8504)
	jr LT, LABEL_F8E5A2
	cp WA, 0
	jr LE, LABEL_F8E5A2
	dec 1, WA
	ld (0x81AC), WA
	ld (XSP + 0x4), WA

LABEL_F8E5A2:
	ld WA, 0xee

LABEL_F8E5A5:
	call LABEL_F994BD
	jrl LABEL_F8E75D

LABEL_F8E5AC:
	cp XIZ, 0xa
	jrl Z, LABEL_F8E75D
	cp XIZ, 0xb
	jrl Z, LABEL_F8E75D
	cp XIZ, 0xc
	jrl Z, LABEL_F8E75D
	cp XIZ, 0xd
	jrl Z, LABEL_F8E75D
	cp XIZ, 0x14
	jr NZ, LABEL_F8E5FA
	cp (0x84FE), 0x0
	jr NZ, LABEL_F8E5FA
	ld XWA, (XSP + 0x1c)
	cp XWA, 0x1c00017
	jr NZ, LABEL_F8E5F2
	ld (0x8942), 0x1
	jrl LABEL_F8E75D

LABEL_F8E5F2:
	ld (0x8942), 0x0
	jrl LABEL_F8E75D

LABEL_F8E5FA:
	cp XIZ, 0x15
	jr NZ, LABEL_F8E635
	ld C, (0x8946)
	ld A, C
	inc 1, A
	cp A, 3
	jr NC, LABEL_F8E620
	inc 1, C
	ld (0x8946), C
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	jr LABEL_F8E62F

LABEL_F8E620:
	ld (0x8946), 0x0
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0

LABEL_F8E62F:
	CALR SmfLoadAsFunc
	jrl LABEL_F8E75D

LABEL_F8E635:
	cp XIZ, 0x16
	jr NZ, LABEL_F8E658
	ld XWA, (XSP + 0x1c)
	cp XWA, 0x1c00017
	jr NZ, LABEL_F8E650
	ld (0x894A), 0x1
	jrl LABEL_F8E75D

LABEL_F8E650:
	ld (0x894A), 0x0
	jrl LABEL_F8E75D

LABEL_F8E658:
	ld XWA, (XSP + 0x1c)
	cp XIZ, 0x17
	jr NZ, LABEL_F8E67B
	cp XWA, 0x1c00017
	jr NZ, LABEL_F8E673
	ld (0x894C), 0x1
	jrl LABEL_F8E75D

LABEL_F8E673:
	ld (0x894C), 0x0
	jrl LABEL_F8E75D

LABEL_F8E67B:
	cp XIZ, 0x18
	jr NZ, LABEL_F8E69B
	cp XWA, 0x1c00017
	jr NZ, LABEL_F8E693
	ld (0x8944), 0x1
	jrl LABEL_F8E75D

LABEL_F8E693:
	ld (0x8944), 0x0
	jrl LABEL_F8E75D

LABEL_F8E69B:
	ld C, (0x8948)
	ld A, C
	inc 1, A
	cp XIZ, 0x1e
	jr NZ, LABEL_F8E6ED
	cp A, 0xa
	jr NC, LABEL_F8E6CF
	inc 1, C
	ld (0x8948), C
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR SmfSeqToSongNumFunc
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	jr LABEL_F8E735

LABEL_F8E6CF:
	ld (0x8948), 0x0
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR SmfSeqToSongNumFunc
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	jr LABEL_F8E735

LABEL_F8E6ED:
	cp XIZ, 0x1f
	jr NZ, LABEL_F8E73A
	cp A, 0xa
	jr NC, LABEL_F8E719
	inc 1, C
	ld (0x8948), C
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR SmfSeqFromSongNumFunc
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	jr LABEL_F8E735

LABEL_F8E719:
	ld (0x8948), 0x0
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR SmfSeqFromSongNumFunc
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0

LABEL_F8E735:
	CALR SmfSeqSongNameFunc
	jr LABEL_F8E75D

LABEL_F8E73A:
	cp XIZ, 0x28
	jr NZ, LABEL_F8E75D
	cpw (0x81AE), 0x0
	jr Z, LABEL_F8E75D
	ld XWA, (0x81A4)
	or XWA, XWA
	jr Z, LABEL_F8E75D
	ld XBC, 0x1c0000a
	ld XDE, 0

LABEL_F8E759:
	call ApPostEvent

LABEL_F8E75D:
	ld HL, (0x81AC)

LABEL_F8E761:
	cp (XSP + 0x4), HL
	jrl Z, LABEL_F8E85B
	ld WA, HL
	call LABEL_F89BA4
	ld WA, (0x81AC)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x81A0)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld BC, (0x81AC)
	exts XBC
	DIVS_BC 0xa
	ld DE, (XSP + 0x4)
	exts XDE
	DIVS_DE 0xa
	ld XWA, (0x81A0)
	cp DE, BC
	jr NZ, LABEL_F8E7EF
	ld BC, (XSP + 0x4)
	exts XBC
	DIVS_BC 0xa
	ld BC, QBC
	sll BC, 5
	lda XHL, 0x850C
	ld DE, BC
	extz XDE
	add XDE, XHL
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld WA, (0x81AC)
	exts XWA
	DIVS_WA 0xa
	ld WA, QWA
	sll WA, 5
	lda XBC, 0x850C
	ld DE, WA
	extz XDE
	add XDE, XBC
	ld XWA, (0x81A0)
	ld XBC, 0x1c0000f
	call ApPostEvent
	jr LABEL_F8E80A

LABEL_F8E7EF:
	MULS_BC 0xa
	CALR DisplaySmfFileList
	cp (0x8D36), 0x6c
	jr NZ, LABEL_F8E80A
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmSmfMedleyFunc

LABEL_F8E80A:
	cp (0x8D36), 0x6b
	jr NZ, LABEL_F8E85B
	lda XIZ, 0x8850
	ld WA, (0x81AC)
	cp WA, (0x8504)
	jr LT, LABEL_F8E830
	cp WA, 0
	jr LE, LABEL_F8E830
	ld XWA, XIZ
	ld XBC, 0xea0790
	call LABEL_F890DC
	jr LABEL_F8E845

LABEL_F8E830:
	call LABEL_F89BF0
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld XWA, 0x8850
	call LABEL_F8929D

LABEL_F8E845:
	ld XWA, 0x8850
	call LABEL_F892DB
	ld XWA, (XSP + 0x20)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR SaveFileNameSmfFunc

LABEL_F8E85B:
	ld XWA, (0x81A0)
	ld XBC, 0x1c50001
	ld XDE, 0
	jr LABEL_F8E8A7
	ld (0x81A4), XBC
	jrl LABEL_F8E12F
	ld (0x81A8), XBC
	jrl LABEL_F8E12F
	ld (0x81AE), IZ
	jrl LABEL_F8E12F
	cp (0x84FE), 0x0
	jrl Z, LABEL_F8E12F
	ld WA, IZ
	ld (0x81AC), WA
	call LABEL_F89BA4
	ld WA, (0x81AC)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x81A0)
	ld XBC, 0x1e50002

LABEL_F8E8A7:
	call ApPostEvent
	jrl LABEL_F8E12F
	ld HL, (0x81AC)
	exts XHL

LABEL_F8E8B4:
	pop XIZ
	lda XSP, XSP + 0x20
	ret

DisplaySmfSequenceList:
	dec 6, XSP
	push IZ
	ld (XSP + 0x2), BC
	ld (XSP + 0x4), XWA
	ld WA, 0
	CALR InitializeOperationState
	ld IZ, 0

LABEL_F8E8C9:
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld A, IZL
	ld (XDE), A
	ld WA, (XSP + 0x2)
	add WA, IZ
	call LABEL_F8B13D
	ld XBC, XHL
	ld WA, IZ
	sll WA, 5
	ld DE, 1
	add DE, WA
	lda XHL, 0x850C
	ld WA, DE
	extz XWA
	add XWA, XHL
	ld DE, (XSP + 0x2)
	add DE, IZ
	inc 1, DE
	pushw 0xc
	pushw 0x1
	call LABEL_F891DD
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr LT, LABEL_F8E8C9
	pop IZ
	inc 6, XSP
	ret

