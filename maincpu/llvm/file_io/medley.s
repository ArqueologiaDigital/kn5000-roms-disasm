; =============================================================================
; file_io/medley.asm - Medley Playback Operations
; =============================================================================
; All medley playback modes: internal, disk, SMF, performance data, document.
;
; Key routines:
;   FmmSeqSongNameFunc               - Sequence song name
;   FmmIntMedleyFunc                 - Internal medley
;   FmmDiskMedley1Func               - Disk medley 1
;   FmmDiskMedley2Func               - Disk medley 2
;   FmmDiskMedleySelectFunc          - Disk medley selection
;   FmmSmfMedleyFunc                 - SMF medley
;   FmmPdFileNameFunc                - Performance data filename
;   FmmPdMedleyFunc                  - Performance data medley
;   DocDiskNameFunc                  - Document disk name
;   FmmDocFileNameFunc               - Document filename
;   FmmDocMedleyFunc                 - Document medley
; =============================================================================

FmmSeqSongNameFunc:
	push IZ
	cp XBC, 0x1e50003
	jrl Z, SeqName_GetIndexReturn
	ld HL, (0x82D8)
	cp XBC, 0x1e50002
	jrl Z, SeqName_SetIndexPlaying
	cp XBC, 0x1c00018
	jr Z, SeqName_HandleNavigation
	cp XBC, 0x1c00017
	jr Z, SeqName_HandleNavigation
	cp XBC, 0x1c0000b
	jr Z, SeqName_InitAllSlots
	cp XBC, 0x1e50004
	jr NZ, SeqName_ReturnZero
	ld (0x82D4), XDE
	cp (0x84FE), 0x0
	jr NZ, SeqName_SendCurrentIndex
	ldw (0x82D8), 0x0

SeqName_SendCurrentIndex:
	ld DE, (0x82D8)
	extz XDE
	ld XWA, (0x82D4)
	ld XBC, 0x1e50002
	jrl SeqName_PostEventExit

SeqName_InitAllSlots:
	ld IZ, 0

SeqName_SendSlotLoop:
	ld BC, IZ
	ld WA, BC
	ld DE, 1
	CALR LABEL_F919E3
	ld XDE, XHL
	ld XWA, (0x82D4)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr LT, SeqName_SendSlotLoop

SeqName_ReturnZero:
	ld XHL, 0
	jrl SeqName_Exit

SeqName_HandleNavigation:
	ld WA, HL
	ld IZ, HL
	or XDE, XDE
	jr NZ, SeqName_HandlePlayAction
	cp (0x84FE), 0x0
	jr NZ, SeqName_HandlePlayAction
	cp XBC, 0x1c00018
	jr NZ, SeqName_CheckPrevKey
	cp WA, 0x9
	jrl NC, SeqName_GetCurrentIndex
	inc 1, WA
	jr SeqName_UpdateIndex

SeqName_CheckPrevKey:
	cp XBC, 0x1c00017
	jrl NZ, SeqName_GetCurrentIndex
	cp WA, 0
	jrl Z, SeqName_GetCurrentIndex
	dec 1, WA

SeqName_UpdateIndex:
	ld (0x82D8), WA
	ld DE, WA
	jrl SeqName_UpdateDisplay

SeqName_HandlePlayAction:
	cp XDE, 0x4
	jrl NZ, SeqName_HandleAction32
	cp (0x84FE), 0x0
	jrl NZ, SeqName_HandleAction32
	call CheckSongSlotHasData
	cp L, 0
	jr Z, SeqName_CheckDiskAvail
	lda XWA, 0x8A0C
	bit 7, (XWA + 0x1)
	jr NZ, SeqName_CheckDiskAvail
	ld (XWA), 0x1
	ld XDE, 1
	ld XWA, 0xffffffff
	ld XBC, 0x1c50004
	jr SeqName_PostAndExit

SeqName_CheckDiskAvail:
	call CheckFileSystemStatus
	cp HL, 0
	jr Z, SeqName_LoadAndPlay
	cp (0x340EA), 0x0
	jr Z, SeqName_LoadAndPlay
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x600037
	ld XBC, 0x1c00001
	ld XDE, 0

SeqName_PostAndExit:
	call ApPostEvent
	jrl SeqName_GetCurrentIndex

SeqName_LoadAndPlay:
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld WA, (0x82D8)
	call LABEL_F880AD
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502), HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jr SeqName_ShowAndExit

SeqName_HandleAction32:
	cp XDE, 0x32
	jr NZ, SeqName_GetCurrentIndex
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld WA, (0x82D8)
	call LABEL_F880AD
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502), HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee

SeqName_ShowAndExit:
	call LABEL_F994BD

SeqName_GetCurrentIndex:
	ld DE, (0x82D8)

SeqName_UpdateDisplay:
	cp IZ, DE
	jrl Z, SeqName_ReturnZero
	extz XDE
	ld XWA, (0x82D4)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld WA, IZ
	ld BC, IZ
	ld DE, 1
	CALR LABEL_F919E3
	ld XDE, XHL
	ld XWA, (0x82D4)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld BC, (0x82D8)
	ld WA, BC
	ld DE, 1
	CALR LABEL_F919E3
	ld XDE, XHL
	ld XWA, (0x82D4)
	ld XBC, 0x1c0000f
	jr SeqName_PostEventExit

SeqName_SetIndexPlaying:
	cp (0x84FE), 0x0
	jrl Z, SeqName_ReturnZero
	ld IZ, HL
	ld (0x82D8), DE
	extz XDE
	ld XWA, (0x82D4)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld WA, IZ
	ld BC, IZ
	ld DE, 1
	CALR LABEL_F919E3
	ld XDE, XHL
	ld XWA, (0x82D4)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld BC, (0x82D8)
	ld WA, BC
	ld DE, 1
	CALR LABEL_F919E3
	ld XDE, XHL
	ld XWA, (0x82D4)
	ld XBC, 0x1c0000f

SeqName_PostEventExit:
	call ApPostEvent
	jrl SeqName_ReturnZero

SeqName_GetIndexReturn:
	ld HL, (0x82D8)
	extz XHL

SeqName_Exit:
	pop IZ
	ret

FormatMedleyNumber:
	ld (XWA+), E
	cp C, 0xff
	jr NZ, FmtNum_CheckMarked
	LD_C 0x20
	jr FmtNum_WriteSpacePad

FmtNum_CheckMarked:
	cp C, 0xfe
	jr NZ, FmtNum_FormatNumber
	LD_C 0x4d

FmtNum_WriteSpacePad:
	ld (XWA+), C
	ld (XWA+), 0x20
	ld (XWA), 0x20
	ret

FmtNum_FormatNumber:
	inc 1, C
	cp C, 0x64
	jr C, FmtNum_WriteM
	LDA_XHL_XWA_plus__e0__
	ld E, C
	extz DE
	DIV_E 0x64
	add E, 0x30
	ld (XHL), E
	extz BC
	DIV_C 0x64
	ld C, B
	jr FmtNum_WriteTensUnits

FmtNum_WriteM:
	ld (XWA+), 0x4d

FmtNum_WriteTensUnits:
	cp C, 0xa
	jr NC, FmtNum_WriteTwoDigits
	ld (XWA+), 0x30
	add C, 0x30
	ld (XWA), C
	ret

FmtNum_WriteTwoDigits:
	LDA_XHL_XWA_plus__e0__
	ld E, C
	extz DE
	DIV_E 0xa
	add E, 0x30
	ld (XHL), E
	extz BC
	DIV_C 0xa
	ld C, B
	add C, 0x30
	ld (XWA), C
	ret

FmmIntMedleyFunc:
	dec 8, XSP
	push IZ
	ld (XSP + 0x6), XWA
	cp XBC, 0x1e5000a
	jrl Z, IntMed_CheckContinue
	ld XWA, XDE
	cp XBC, 0x1e50008
	jrl Z, IntMed_StoreDelayFlag
	cp XBC, 0x1c00018
	jrl Z, IntMed_HandleNavToggle
	cp XBC, 0x1c00017
	jrl Z, IntMed_HandleNavToggle
	cp XBC, 0x1c0000b
	jrl Z, IntMed_InitSlotDisplay
	cp XBC, 0x1e50004
	jrl Z, IntMed_StoreWindowPtr
	cp XBC, 0x1c00013
	jrl NZ, IntMed_Exit
	cp XDE, 0x3
	jrl Z, IntMed_HandleStop
	cp XDE, 0x2
	jrl NZ, IntMed_Exit
	cp (0x8D37), 0x7a
	jr Z, IntMed_CheckPlaying
	call LABEL_F20ACD
	ld (0x84FE), 0x0
	ld (0x889C), 0x0
	ld (0x889A), 0x0
	ld IZ, 0

IntMed_CheckSlotLoop:
	ld A, IZL
	extz WA
	call LABEL_F2065A
	cp L, 0
	jr Z, IntMed_MarkSlotEmpty
	lda XWA, 0x8890
	ld BC, IZ
	extz XBC
	add XBC, XWA
	ld (XBC), (0x889A)
	inc 1, (0x889A)
	jr IntMed_NextSlot

IntMed_MarkSlotEmpty:
	lda XWA, 0x8890
	ld BC, IZ
	extz XBC
	add XBC, XWA
	ld (XBC), 0xff

IntMed_NextSlot:
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_CheckSlotLoop
	ld XWA, 0
	ld (0x82DE), XWA
	jrl IntMed_Exit

IntMed_CheckPlaying:
	call LABEL_F2076D
	cp L, 1
	jrl NZ, IntMed_HandleError
	ld (0x84FE), 0x1
	ld A, (0x889C)
	cp A, (0x889A)
	jr NC, IntMed_CheckRepeat
	ld IZ, 0
	lda XBC, 0x8890

IntMed_FindCurrentSong:
	ld DE, IZ
	extz XDE
	add XDE, XBC
	cp (XDE), A
	jr NZ, IntMed_NextSongSearch
	ld DE, IZ
	extz XDE
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1e50002
	CALR FmmSeqSongNameFunc
	ld A, IZL
	extz WA
	call LABEL_F20BCE
	inc 1, (0x889C)
	ld XWA, (0x82DE)
	or XWA, XWA
	jrl Z, IntMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e
	jr IntMed_PostDelayEvent

IntMed_NextSongSearch:
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_FindCurrentSong
	jrl IntMed_Exit

IntMed_CheckRepeat:
	cp (0x889E), 0x0
	jr Z, IntMed_ClearPlayFlag
	ld (0x889C), 0x0
	ld IZ, 0
	lda XWA, 0x8890

IntMed_PlayFromStart:
	ld BC, IZ
	extz XBC
	add XBC, XWA
	cp (XBC), 0x0
	jr NZ, IntMed_NextSongLoop
	ld DE, IZ
	extz XDE
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1e50002
	CALR FmmSeqSongNameFunc
	ld A, IZL
	extz WA
	call LABEL_F20BCE
	inc 1, (0x889C)
	ld XWA, (0x82DE)
	or XWA, XWA
	jrl Z, IntMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e

IntMed_PostDelayEvent:
	call ApPostEvent
	jrl IntMed_Exit

IntMed_NextSongLoop:
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_PlayFromStart
	jrl IntMed_Exit

IntMed_ClearPlayFlag:
	ld (0x84FE), 0x0
	jrl IntMed_Exit

IntMed_HandleError:
	call LABEL_F2076D
	ld (0x84FE), 0x0
	cp L, 0
	jrl Z, IntMed_Exit
	ld (0x7F42), 0xe
	ld WA, 0xee
	call LABEL_F994BD
	jrl IntMed_Exit

IntMed_HandleStop:
	cp (0x8D36), 0x7a
	jrl Z, IntMed_Exit
	call LABEL_F20B70
	ld (0x84FE), 0x0
	jrl IntMed_Exit

IntMed_StoreWindowPtr:
	ld (0x82DA), XWA
	jrl IntMed_Exit

IntMed_InitSlotDisplay:
	ld IZ, 0

IntMed_FormatSlotLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x82E2
	extz XWA
	add XWA, XBC
	lda XBC, 0x8890
	ld DE, IZ
	extz XDE
	add XDE, XBC
	ld C, (XDE)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x82E2
	extz XDE
	add XDE, XWA
	ld XWA, (0x82DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_FormatSlotLoop
	jrl IntMed_Exit

IntMed_HandleNavToggle:
	lda XWA, 0x8890
	cp XDE, 0xa
	jrl NZ, IntMed_HandleSelectToggle
	cp (0x84FE), 0x0
	jrl NZ, IntMed_HandleSelectToggle
	ld IZ, 0

IntMed_FindMarkedSlot:
	ld BC, IZ
	extz XBC
	add XBC, XWA
	cp (XBC), 0xfe
	jr Z, IntMed_CheckAllMarked
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_FindMarkedSlot

IntMed_CheckAllMarked:
	cp IZ, 0xa
	jr NC, IntMed_RemoveOrderLoop
	ld IZ, 0

IntMed_AssignOrderLoop:
	lda XWA, 0x8890
	ld BC, IZ
	extz XBC
	add XBC, XWA
	ld A, (XBC)
	cp A, 0xfe
	jr NZ, IntMed_NextAssignSlot
	ld A, (0x889A)
	ld (XBC), A
	inc 1, (0x889A)
	ld WA, IZ
	sll WA, 3
	lda XDE, 0x82E2
	extz XWA
	add XWA, XDE
	ld C, (XBC)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x82E2
	extz XDE
	add XDE, XWA
	ld XWA, (0x82DA)
	ld XBC, 0x1c0000f
	call ApPostEvent

IntMed_NextAssignSlot:
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_AssignOrderLoop
	jrl IntMed_Exit

IntMed_RemoveOrderLoop:
	ld IZ, 0

IntMed_UnmarkSlotLoop:
	lda XWA, 0x8890
	ld BC, IZ
	extz XBC
	add XBC, XWA
	ld A, (XBC)
	cp A, 0xfd
	jr UGT, IntMed_NextUnmark
	ld (XBC), 0xfe
	dec 1, (0x889A)
	ld WA, IZ
	sll WA, 3
	lda XDE, 0x82E2
	extz XWA
	add XWA, XDE
	ld C, (XBC)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x82E2
	extz XDE
	add XDE, XWA
	ld XWA, (0x82DA)
	ld XBC, 0x1c0000f
	call ApPostEvent

IntMed_NextUnmark:
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_UnmarkSlotLoop
	jrl IntMed_Exit

IntMed_HandleSelectToggle:
	cp XDE, 0xb
	jrl NZ, IntMed_HandleRepeatToggle
	cp (0x84FE), 0x0
	jrl NZ, IntMed_HandleRepeatToggle
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmSeqSongNameFunc
	ld IZ, HL
	lda XWA, 0x8890
	ld DE, IZ
	extz XDE
	add XDE, XWA
	lda XBC, 0x82E2
	ld WA, IZ
	sll WA, 3
	extz XWA
	add XWA, XBC
	ld C, (XDE)
	cp C, 0xfe
	jr NZ, IntMed_RemoveFromOrder
	ld C, (0x889A)
	ld (XDE), C
	inc 1, (0x889A)
	ld C, (XDE)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XBC, 0x82E2
	extz XDE
	add XDE, XBC
	ld XWA, (0x82DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	jrl IntMed_Exit

IntMed_RemoveFromOrder:
	cp C, 0xfd
	jrl UGT, IntMed_Exit
	ld (XSP + 0x4), C
	ld (XDE), 0xfe
	dec 1, (0x889A)
	ld C, (XDE)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XBC, 0x82E2
	extz XDE
	add XDE, XBC
	ld XWA, (0x82DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ldw (XSP + 0x2), 0x0
	ld IZ, 0
	ld A, (0x889A)
	extz WA
	cp WA, 0
	jrl ULE, IntMed_Exit

IntMed_ReorderLoop:
	lda XWA, 0x8890
	ld DE, IZ
	extz XDE
	add XDE, XWA
	ld C, (XDE)
	cp C, 0xfd
	jr UGT, IntMed_NextReorder
	INCW 1, (XSP + 0x2)
	cp C, (XSP + 0x4)
	jr ULE, IntMed_NextReorder
	dec 1, C
	ld (XDE), C
	ld WA, IZ
	sll WA, 3
	lda XDE, 0x82E2
	extz XWA
	add XWA, XDE
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x82E2
	extz XDE
	add XDE, XWA
	ld XWA, (0x82DA)
	ld XBC, 0x1c0000f
	call ApPostEvent

IntMed_NextReorder:
	inc 1, IZ
	ld A, (0x889A)
	extz WA
	cp (XSP + 0x2), WA
	jr C, IntMed_ReorderLoop
	jrl IntMed_Exit

IntMed_HandleRepeatToggle:
	cp XDE, 0xc
	jr NZ, IntMed_HandlePlay
	cp XBC, 0x1c00017
	jr NZ, IntMed_SetRepeatOff
	ld (0x889E), 0x1
	jrl IntMed_Exit

IntMed_SetRepeatOff:
	ld (0x889E), 0x0
	jrl IntMed_Exit

IntMed_HandlePlay:
	cp XDE, 0xd
	jrl NZ, IntMed_Exit
	cp (0x84FE), 0x0
	jr NZ, IntMed_Exit
	ld (0x889C), 0x0
	ld IZ, 0

IntMed_StartPlayLoop:
	ld BC, IZ
	extz XBC
	add XBC, XWA
	cp (XBC), 0x0
	jr NZ, IntMed_NextPlaySlot
	ld (0x84FE), 0x1
	ld DE, IZ
	extz XDE
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1e50002
	CALR FmmSeqSongNameFunc
	ld A, IZL
	extz WA
	call LABEL_F20BCE
	inc 1, (0x889C)
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x7a
	call UI_PostModeChangeEvent
	jr IntMed_Exit

IntMed_NextPlaySlot:
	inc 1, IZ
	cp IZ, 0xa
	jr C, IntMed_StartPlayLoop
	jr IntMed_Exit

IntMed_StoreDelayFlag:
	ld (0x82DE), XWA
	jr IntMed_Exit

IntMed_CheckContinue:
	cp (0x84FE), 0x0
	jr Z, IntMed_Exit
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x7a
	call UI_PostModeChangeEvent

IntMed_Exit:
	ld XHL, 0
	pop IZ
	inc 8, XSP
	ret

FmmDiskMedley1Func:
	push IZ
	cp XBC, 0x1c0000b
	jr Z, DiskMed1_InitLoop
	cp XBC, 0x1e50004
	jr NZ, DiskMed1_Exit
	ld (0x8332), XDE
	jr DiskMed1_Exit

DiskMed1_InitLoop:
	ld IZ, 0

DiskMed1_FormatLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x8336
	extz XWA
	add XWA, XBC
	lda XBC, 0x8926
	ld DE, IZ
	extz XDE
	add XDE, XBC
	ld C, (XDE)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x8336
	extz XDE
	add XDE, XWA
	ld XWA, (0x8332)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr C, DiskMed1_FormatLoop

DiskMed1_Exit:
	ld XHL, 0
	pop IZ
	ret

FmmDiskMedley2Func:
	push IZ
	cp XBC, 0x1c0000b
	jr Z, DiskMed2_InitLoop
	cp XBC, 0x1e50004
	jr NZ, DiskMed2_Exit
	ld (0x8386), XDE
	jr DiskMed2_Exit

DiskMed2_InitLoop:
	ld IZ, 0xa

DiskMed2_FormatLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x833A
	extz XWA
	add XWA, XBC
	lda XBC, 0x8926
	ld DE, IZ
	extz XDE
	add XDE, XBC
	ld C, (XDE)
	extz BC
	ld DE, IZ
	sub DE, 0xa
	CALR FormatMedleyNumber
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x833A
	ld DE, WA
	extz XDE
	add XDE, XBC
	ld XWA, (0x8386)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0x14
	jr C, DiskMed2_FormatLoop

DiskMed2_Exit:
	ld XHL, 0
	pop IZ
	ret

DiskMed_PlayNextHelper:
	push IZ
	cp XBC, 0x1c00018
	jr Z, DiskMed_InitPlayOrder
	cp XBC, 0x1c00017
	jr Z, DiskMed_InitPlayOrder
	cp XBC, 0x1c00013
	jrl NZ, DiskMed_ReturnZero
	cp XDE, 0x3
	jrl Z, DiskMed_ReturnZero
	cp XDE, 0x2
	jrl NZ, DiskMed_ReturnZero
	cp (0x84FE), 0x0
	jrl Z, DiskMed_ReturnZero
	ld A, (0x889C)
	cp A, (0x889A)
	jr NC, DiskMed_ReturnFinished
	ld IZ, 0
	lda XBC, 0x8890

DiskMed_FindSongLoop:
	ld DE, IZ
	extz XDE
	add XDE, XBC
	cp (XDE), A
	jr NZ, DiskMed_NextSong
	ld A, IZL
	extz WA
	jrl DiskMed_PlaySong

DiskMed_NextSong:
	inc 1, IZ
	cp IZ, 0xa
	jr C, DiskMed_FindSongLoop
	jrl DiskMed_ReturnZero

DiskMed_ReturnFinished:
	ld XHL, 2
	jrl DiskMed_HelperExit

DiskMed_InitPlayOrder:
	cp XDE, 0xd
	jrl NZ, DiskMed_ReturnZero
	ld (0x889C), 0x0
	ld (0x889A), 0x0
	ld (0x889E), 0x0
	ld IZ, 0

DiskMed_CheckSlotLoop:
	ld A, IZL
	extz WA
	call LABEL_F2065A
	lda XBC, 0x8890
	ld WA, IZ
	extz XWA
	add XWA, XBC
	cp L, 0
	jr Z, DiskMed_MarkUnused
	ld (XWA), 0xfe
	jr DiskMed_NextSlotCheck

DiskMed_MarkUnused:
	ld (XWA), 0xff

DiskMed_NextSlotCheck:
	inc 1, IZ
	cp IZ, 0xa
	jr C, DiskMed_CheckSlotLoop
	cp (0x8940), 0x0
	jr Z, DiskMed_SingleSlotCheck
	lda XHL, 0x8890
	ld XBC, XHL
	lda XDE, XHL + 0xa

DiskMed_AssignOrder:
	ld A, (XBC)
	cp A, 0xfe
	jr NZ, DiskMed_NextAssign
	ld (XBC), (0x889A)
	inc 1, (0x889A)

DiskMed_NextAssign:
	inc 1, XBC
	cp XBC, XDE
	jr C, DiskMed_AssignOrder
	ld IZ, 0

DiskMed_FindFirstSong:
	ld WA, IZ
	extz XWA
	add XWA, XHL
	ld A, (XWA)
	cp A, (0x889C)
	jr NZ, DiskMed_NextFirst
	ld A, IZL
	extz WA
	jr DiskMed_PlaySong

DiskMed_NextFirst:
	inc 1, IZ
	cp IZ, 0xa
	jr C, DiskMed_FindFirstSong
	jr DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	lda XBC, 0x8890
	cp (XBC), 0xfe
	jr NZ, DiskMed_SingleSlotInit
	ld (XBC), (0x889A)
	inc 1, (0x889A)

DiskMed_SingleSlotInit:
	ld IZ, 0

DiskMed_FindFirstLoop:
	ld WA, IZ
	extz XWA
	add XWA, XBC
	ld A, (XWA)
	cp A, (0x889C)
	jr NZ, DiskMed_NextFindFirst
	ld A, IZL
	extz WA

DiskMed_PlaySong:
	call LABEL_F20BCE
	inc 1, (0x889C)
	ld XHL, 1
	jr DiskMed_HelperExit

DiskMed_NextFindFirst:
	inc 1, IZ
	cp IZ, 0xa
	jr C, DiskMed_FindFirstLoop

DiskMed_ReturnZero:
	ld XHL, 0

DiskMed_HelperExit:
	pop IZ
	ret

FmmDiskMedleySelectFunc:
	lda XSP, XSP - 14
	push XIZ
	ld (XSP + 0x6), XDE
	ld (XSP + 0xa), XBC
	ld (XSP + 0xe), XWA
	ld XWA, (XSP + 0xa)
	cp XWA, 0x1c00018
	jrl Z, DiskSel_HandleNavigation
	cp XWA, 0x1c00017
	jrl Z, DiskSel_HandleNavigation
	cp XWA, 0x1c0000b
	jrl Z, DiskSel_InitDisplay
	cp XWA, 0x1e50004
	jrl Z, DiskSel_StoreWindowPtr
	cp XWA, 0x1c00013
	jrl NZ, DiskSel_Exit
	ld XWA, (XSP + 0x6)
	cp XWA, 0x3
	jrl Z, DiskSel_HandleStopEvent
	cp XWA, 0x2
	jrl NZ, DiskSel_Exit
	ld WA, 0
	CALR InitializeOperationState
	cp (0x8D37), 0x78
	jrl Z, DiskSel_CheckPlaying
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	cpw (0x8502), 0x0
	jr GE, DiskSel_InitState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call GetEncodedFileSizeData
	ld (0x8502), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	CALR SignalProgressUpdate

DiskSel_InitState:
	ld (0x84FE), 0x0
	ld (0x893C), 0x0
	ld (0x893A), 0x0
	ld IZ, 0

DiskSel_CheckFileLoop:
	ld WA, IZ
	ld BC, 2
	call LABEL_F89408
	cp L, 0
	jr NZ, DiskSel_FileAvailable
	ld WA, IZ
	ld BC, 0x8
	call LABEL_F89408
	cp L, 0
	jr Z, DiskSel_MarkUnavail

DiskSel_FileAvailable:
	lda XWA, 0x8926
	ld (XWA + IZ), (0x893A)
	inc 1, (0x893A)
	jr DiskSel_NextFile

DiskSel_MarkUnavail:
	lda XWA, 0x8926
	ld (XWA + IZ), 0xff

DiskSel_NextFile:
	inc 1, IZ
	cp IZ, 0x14
	jr LT, DiskSel_CheckFileLoop
	call LABEL_F20ACD
	jrl DiskSel_Exit

DiskSel_CheckPlaying:
	call LABEL_F2076D
	cp L, 1
	jrl NZ, DiskSel_HandleError
	ld (0x84FE), 0x1
	ld XWA, (XSP + 0xe)
	ld XBC, (XSP + 0xa)
	ld XDE, (XSP + 0x6)
	CALR DiskMed_PlayNextHelper
	cp L, 1
	jr NZ, DiskSel_CheckFinished
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x78
	jrl DiskSel_CallPauseMode

DiskSel_CheckFinished:
	cp L, 2
	jrl NZ, DiskSel_Exit
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	ld A, (0x893C)
	cp A, (0x893A)
	jrl NC, DiskSel_CheckRepeat
	ld IZ, 0

DiskSel_ClearSelections:
	ld A, IZL
	extz WA
	call LABEL_F89321
	inc 1, IZ
	cp IZ, 0x8
	jr LT, DiskSel_ClearSelections
	ld IZ, 0

DiskSel_FindSongLoop:
	lda XWA, 0x8926
	ld A, (XWA + IZ)
	cp A, (0x893C)
	jrl NZ, DiskSel_NextSongLoop
	ld (0x83DE), IZ
	ld WA, IZ
	call NotifyUIOfSelectionChange
	ld DE, (0x83DE)
	exts XDE
	ld XWA, (0x83DA)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld QIZ, 0

DiskSel_SendFileInfo:
	ld DE, QIZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x83DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, QIZ
	cp QIZ, 0x14
	jr LT, DiskSel_SendFileInfo
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDiskMedley1Func
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDiskMedley2Func
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0x770008
	CALR DiskNameFunc
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0x770009
	CALR DiskInfoFunc
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F87A08
	ld QIZ, HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	cp QIZ, 0
	jr GE, DiskSel_PlayNext
	ld (0x84FE), 0x0
	ld WA, 0x60
	call UI_PostModeChangeEvent
	ld WA, QIZ
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
	ld WA, 0xee
	jrl DiskSel_ShowErrorAndExit

DiskSel_PlayNext:
	inc 1, (0x893C)
	ld XWA, (XSP + 0xe)
	ld XBC, 0x1c00017
	ld XDE, 0xd
	CALR DiskMed_PlayNextHelper
	cp L, 1
	jr NZ, DiskSel_NextSongLoop
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x78
	call UI_PostModeChangeEvent
	jr DiskSel_ClearPlaying

DiskSel_NextSongLoop:
	inc 1, IZ
	cp IZ, 0x14
	jrl LT, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	ld (0x84FE), 0x0
	jrl DiskSel_Exit

DiskSel_CheckRepeat:
	cp (0x893E), 0x0
	jr Z, DiskSel_ClearPlaying
	ld (0x893C), 0x0
	ld IZ, 0

DiskSel_RepeatClear:
	ld A, IZL
	extz WA
	call LABEL_F89321
	inc 1, IZ
	cp IZ, 0x8
	jr LT, DiskSel_RepeatClear
	ld IZ, 0

DiskSel_RepeatFindLoop:
	lda XWA, 0x8926
	ld A, (XWA + IZ)
	cp A, (0x893C)
	jrl NZ, DiskSel_RepeatNext
	ld (0x83DE), IZ
	ld WA, IZ
	call NotifyUIOfSelectionChange
	ld DE, (0x83DE)
	exts XDE
	ld XWA, (0x83DA)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld QIZ, 0

DiskSel_RepeatSendInfo:
	ld DE, QIZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x83DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, QIZ
	cp QIZ, 0x14
	jr LT, DiskSel_RepeatSendInfo
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDiskMedley1Func
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDiskMedley2Func
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0x770008
	CALR DiskNameFunc
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0x770009
	CALR DiskInfoFunc
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F87A08
	ld QIZ, HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	cp QIZ, 0
	jr GE, DiskSel_RepeatPlayNext
	ld (0x84FE), 0x0
	ld WA, 0x60
	call UI_PostModeChangeEvent
	ld WA, QIZ
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
	ld WA, 0xee
	jrl DiskSel_ShowErrorAndExit

DiskSel_RepeatPlayNext:
	inc 1, (0x893C)
	ld XWA, (XSP + 0xe)
	ld XBC, 0x1c00017
	ld XDE, 0xd
	CALR DiskMed_PlayNextHelper
	cp L, 1
	jr NZ, DiskSel_RepeatNext
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x78

DiskSel_CallPauseMode:
	call UI_PostModeChangeEvent
	jrl DiskSel_Exit

DiskSel_RepeatNext:
	inc 1, IZ
	cp IZ, 0x14
	jrl LT, DiskSel_RepeatFindLoop
	jrl DiskSel_Exit

DiskSel_HandleError:
	call LABEL_F2076D
	ld (0x84FE), 0x0
	cp L, 0
	jr NZ, DiskSel_ShowError
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	jrl DiskSel_Exit

DiskSel_ShowError:
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0xe
	ld WA, 0xee
	jrl DiskSel_ShowErrorAndExit

DiskSel_HandleStopEvent:
	cp (0x8D36), 0x78
	jr Z, DiskSel_PostStopEvent
	call LABEL_F20B70
	ld (0x84FE), 0x0

DiskSel_PostStopEvent:
	CALR CancelOperationCleanup
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	jrl DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	ld XWA, (XSP + 0x6)
	ld (0x83DA), XWA
	call GetCurrentFileIndex
	ld (0x83DE), HL
	cp HL, 0
	jr LT, DiskSel_DefaultIndex
	exts XHL
	ld XWA, (0x83DA)
	ld XBC, 0x1e50002
	ld XDE, XHL
	jrl DiskSel_PostEvent

DiskSel_DefaultIndex:
	ldw (0x83DE), 0x0
	ld XWA, (0x83DA)
	ld XBC, 0x1e50002
	ld XDE, 0
	jrl DiskSel_PostEvent

DiskSel_InitDisplay:
	ld IZ, 0

DiskSel_DisplayLoop:
	ld WA, IZ
	ld HL, WA
	sll HL, 5
	lda XDE, 0x850C
	extz XHL
	add XHL, XDE
	ld C, IZL
	ld (XHL), C
	ld BC, 2
	call LABEL_F89408
	ld WA, IZ
	cp L, 0
	jr NZ, DiskSel_GetFileName
	ld BC, 0x8
	call LABEL_F89408
	cp L, 0
	jr Z, DiskSel_EmptyFileName
	ld WA, IZ

DiskSel_GetFileName:
	call LABEL_F89623
	ld XBC, XHL
	jr DiskSel_FormatEntry

DiskSel_EmptyFileName:
	lda XBC, 0xEA0A54

DiskSel_FormatEntry:
	ld DE, IZ
	ld WA, DE
	sll WA, 5
	ld HL, 1
	add HL, WA
	lda XIX, 0x850C
	extz XHL
	add XHL, XIX
	inc 1, DE
	pushw 0x6
	pushw 0x0
	ld XWA, XHL
	call LABEL_F891DD
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x83DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0x14
	jr LT, DiskSel_DisplayLoop
	jrl DiskSel_Exit

DiskSel_HandleNavigation:
	ld DE, (0x83DE)
	ld (XSP + 0x4), DE
	ld XBC, (XSP + 0xa)
	ld XWA, (XSP + 0x6)
	or XWA, XWA
	jr NZ, DiskSel_CheckPage
	cp (0x84FE), 0x0
	jr NZ, DiskSel_CheckPage
	ld XWA, XBC
	cp XBC, 0x1c00018
	jr NZ, DiskSel_CheckPrevKey
	cp DE, 0x13
	jrl GE, DiskSel_GetCurrentIndex
	inc 1, DE
	jr DiskSel_SaveIndex

DiskSel_CheckPrevKey:
	cp XWA, 0x1c00017
	jrl NZ, DiskSel_GetCurrentIndex
	cp DE, 0
	jrl LE, DiskSel_GetCurrentIndex
	dec 1, DE
	jr DiskSel_SaveIndex

DiskSel_CheckPage:
	ld XWA, (XSP + 0x6)
	cp XWA, 0x1
	jr NZ, DiskSel_CheckPageDown
	cp (0x84FE), 0x0
	jr NZ, DiskSel_CheckPageDown
	cp DE, 0xa
	jrl LT, DiskSel_GetCurrentIndex
	sub DE, 0xa
	jr DiskSel_SaveIndex

DiskSel_CheckPageDown:
	ld XWA, (XSP + 0x6)
	cp XWA, 0x2
	jr NZ, DiskSel_HandleToggle
	cp (0x84FE), 0x0
	jr NZ, DiskSel_HandleToggle
	ld WA, DE
	add WA, 0xa
	cp WA, 0x13
	jrl GT, DiskSel_GetCurrentIndex
	add DE, 0xa

DiskSel_SaveIndex:
	ld (0x83DE), DE
	jrl DiskSel_UpdateDisplay

DiskSel_HandleToggle:
	lda XHL, 0x8926
	ld XWA, (XSP + 0x6)
	cp XWA, 0xa
	jr NZ, DiskSel_HandleSelect
	cp (0x84FE), 0x0
	jr NZ, DiskSel_HandleSelect
	ld IZ, 0

DiskSel_FindMarkedLoop:
	cp (XHL + IZ), 0xfe
	jr Z, DiskSel_ToggleStart
	inc 1, IZ
	cp IZ, 0x14
	jr LT, DiskSel_FindMarkedLoop

DiskSel_ToggleStart:
	lda XDE, XHL + 0x14
	cp IZ, 0x14
	jr GE, DiskSel_UnmarkLoop

DiskSel_AssignLoop:
	ld A, (XHL)
	cp A, 0xfe
	jr NZ, DiskSel_NextAssign
	ld (XHL), (0x893A)
	inc 1, (0x893A)

DiskSel_NextAssign:
	inc 1, XHL
	cp XHL, XDE
	jr C, DiskSel_AssignLoop
	jr DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	ld A, (XHL)
	cp A, 0xfd
	jr UGT, DiskSel_NextUnmark
	ld (XHL), 0xfe
	dec 1, (0x893A)

DiskSel_NextUnmark:
	inc 1, XHL
	cp XHL, XDE
	jr C, DiskSel_UnmarkLoop

DiskSel_RefreshDisplay:
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDiskMedley1Func
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	jr DiskSel_RefreshBoth

DiskSel_HandleSelect:
	ld XWA, (XSP + 0x6)
	cp XWA, 0xb
	jr NZ, DiskSel_HandleRepeat
	cp (0x84FE), 0x0
	jr NZ, DiskSel_HandleRepeat
	ld XIX, XHL
	lda XBC, XHL + DE
	ld A, (XBC)
	cp A, 0xfe
	jr NZ, DiskSel_RemoveSelect
	ld (XBC), (0x893A)
	inc 1, (0x893A)
	jr DiskSel_RefreshAfterSelect

DiskSel_RemoveSelect:
	cp A, 0xfd
	jr UGT, DiskSel_RefreshAfterSelect
	cp DE, 0x14
	jr GE, DiskSel_ReorderSlots
	ld (XBC), 0xfe
	dec 1, (0x893A)

DiskSel_ReorderSlots:
	ld XDE, XIX
	lda XHL, XIX + 0x14

DiskSel_ReorderLoop:
	ld C, (XDE)
	cp C, 0xfd
	jr UGT, DiskSel_NextReorder
	cp C, A
	jr ULE, DiskSel_NextReorder
	dec 1, C
	ld (XDE), C

DiskSel_NextReorder:
	inc 1, XDE
	cp XDE, XHL
	jr C, DiskSel_ReorderLoop

DiskSel_RefreshAfterSelect:
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDiskMedley1Func
	ld XWA, 0
	ld XBC, 0x1c0000b
	ld XDE, 0

DiskSel_RefreshBoth:
	CALR FmmDiskMedley2Func
	jrl DiskSel_GetCurrentIndex

DiskSel_HandleRepeat:
	ld XWA, (XSP + 0x6)
	cp XWA, 0xc
	jr NZ, DiskSel_HandlePlayStart
	cp XBC, 0x1c00017
	jr NZ, DiskSel_SetRepeatOff
	ld (0x893E), 0x1
	jrl DiskSel_GetCurrentIndex

DiskSel_SetRepeatOff:
	ld (0x893E), 0x0
	jrl DiskSel_GetCurrentIndex

DiskSel_HandlePlayStart:
	ld XWA, (XSP + 0x6)
	cp XWA, 0xd
	jrl NZ, DiskSel_HandleAllCheck
	cp (0x84FE), 0x0
	jrl NZ, DiskSel_HandleAllCheck
	ld (0x893C), 0x0
	ld IZ, 0

DiskSel_PlayClearLoop:
	ld A, IZL
	extz WA
	call LABEL_F89321
	inc 1, IZ
	cp IZ, 0x8
	jr LT, DiskSel_PlayClearLoop
	ld IZ, 0

DiskSel_PlayFindLoop:
	lda XWA, 0x8926
	ld A, (XWA + IZ)
	cp A, (0x893C)
	jrl NZ, DiskSel_PlayNextLoop
	ld (0x83DE), IZ
	ld WA, IZ
	call NotifyUIOfSelectionChange
	ld DE, (0x83DE)
	exts XDE
	ld XWA, (0x83DA)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call LABEL_F87A08
	ld QIZ, HL
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	cp QIZ, 0
	jr GE, DiskSel_PlayNextSong
	ld (0x84FE), 0x0
	ld WA, 0x60
	call UI_PostModeChangeEvent
	ld WA, QIZ
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
	ld WA, 0xee

DiskSel_ShowErrorAndExit:
	call LABEL_F994BD
	jrl DiskSel_Exit

DiskSel_PlayNextSong:
	ldw (XSP + 0x4), (0x83DE)
	inc 1, (0x893C)
	ld XWA, (XSP + 0xe)
	ld XBC, (XSP + 0xa)
	ld XDE, (XSP + 0x6)
	CALR DiskMed_PlayNextHelper
	cp L, 1
	jr NZ, DiskSel_PlayNextLoop
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x78
	call UI_PostModeChangeEvent
	jr DiskSel_GetCurrentIndex

DiskSel_PlayNextLoop:
	inc 1, IZ
	cp IZ, 0x14
	jrl LT, DiskSel_PlayFindLoop
	jr DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	ld XWA, (XSP + 0x6)
	cp XWA, 0xe
	jr NZ, DiskSel_GetCurrentIndex
	cp XBC, 0x1c00017
	jr NZ, DiskSel_SetAllOff
	ld (0x8940), 0x1
	jr DiskSel_GetCurrentIndex

DiskSel_SetAllOff:
	ld (0x8940), 0x0

DiskSel_GetCurrentIndex:
	ld DE, (0x83DE)

DiskSel_UpdateDisplay:
	cp (XSP + 0x4), DE
	jr Z, DiskSel_Exit
	ld WA, DE
	call NotifyUIOfSelectionChange
	ld DE, (0x83DE)
	exts XDE
	ld XWA, (0x83DA)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld DE, (XSP + 0x4)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x83DA)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld DE, (0x83DE)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x83DA)
	ld XBC, 0x1c0000f

DiskSel_PostEvent:
	call ApPostEvent

DiskSel_Exit:
	ld XHL, 0
	pop XIZ
	lda XSP, XSP + 0xe
	ret

GetPlayState1:
	ld L, (0x8942)
	ret

GetPlayState2:
	ld L, (0x8944)
	ret

SmfMedley_RawData:
	.byte 0xC9, 0xD8, 0xD8, 0x7E, 0xF1, 0x44, 0x89, 0x41
	.byte 0xE

NavigateSongList:
	dec 2, XSP
	push IZ
	ld (XSP + 0x2), WA
	cpw (XSP + 0x2), 0x1
	jr Z, NavSong_CheckBounds
	cpw (XSP + 0x2), 0xffff
	jr NZ, NavSong_Exit

NavSong_CheckBounds:
	cpw (0x8504), 0x0
	jr LE, NavSong_Exit
	call LABEL_F89AC7
	cp HL, 0
	jr LT, NavSong_Exit
	ld IZ, HL
	add IZ, (XSP + 0x2)
	jr GE, NavSong_WrapToEnd
	ld IZ, (0x8504)
	dec 1, IZ
	jr NavSong_CheckEnd

NavSong_WrapToEnd:
	cp IZ, (0x8504)
	jr LT, NavSong_CheckEnd
	ld IZ, 0

NavSong_CheckEnd:
	cp HL, IZ
	jr Z, NavSong_Exit
	ld WA, IZ
	call LABEL_F89BA4
	ld WA, IZ
	call LABEL_F8A07F

NavSong_Exit:
	pop IZ
	inc 2, XSP
	ret

NavigateDocList:
	push IZ
	ld IZ, WA
	cp IZ, 1
	jr Z, NavDoc_CheckBounds
	cp IZ, 0xffff
	jr NZ, NavDoc_Exit

NavDoc_CheckBounds:
	cpw (0x8508), 0x0
	jr LE, NavDoc_Exit
	call LABEL_F8A7CE
	cp HL, 0
	jr LT, NavDoc_Exit
	ld WA, HL
	add WA, IZ
	jr GE, NavDoc_WrapToEnd
	ld WA, (0x8508)
	dec 1, WA
	jr NavDoc_CheckEnd

NavDoc_WrapToEnd:
	cp WA, (0x8508)
	jr LT, NavDoc_CheckEnd
	ld WA, 0

NavDoc_CheckEnd:
	cp HL, WA
	call NZ, LABEL_F8A956

NavDoc_Exit:
	pop IZ
	ret

NavigatePdList:
	push IZ
	ld IZ, WA
	cp IZ, 1
	jr Z, NavPd_CheckBounds
	cp IZ, 0xffff
	jr NZ, NavPd_Exit

NavPd_CheckBounds:
	cpw (0x8506), 0x0
	jr LE, NavPd_Exit
	call LABEL_F8A4C8
	cp HL, 0
	jr LT, NavPd_Exit
	ld WA, HL
	add WA, IZ
	jr GE, NavPd_WrapToEnd
	ld WA, (0x8506)
	dec 1, WA
	jr NavPd_CheckEnd

NavPd_WrapToEnd:
	cp WA, (0x8506)
	jr LT, NavPd_CheckEnd
	ld WA, 0

NavPd_CheckEnd:
	cp HL, WA
	call NZ, LABEL_F8A5A5

NavPd_Exit:
	pop IZ
	ret

SmfMed_FormatSlotList:
	dec 6, XSP
	push XIZ
	ld IZ, BC
	ld (XSP + 0x6), XWA
	ld XWA, 0
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmSmfFileNameFunc
	ld QIZ, HL
	ld WA, QIZ
	extz XWA
	DIVW_WA 0xa
	ld QIZ, WA
	MULW_WA 0xa
	ld QIZ, WA
	ldw (XSP + 0x4), 0xa
	ld WA, QIZ
	add WA, 0xa
	cp WA, IZ
	jr C, SmfFmt_CalcVisible
	ld (XSP + 0x4), IZ
	ld WA, QIZ
	sub (XSP + 0x4), WA

SmfFmt_CalcVisible:
	ld IZ, 0
	cpw (XSP + 0x4), 0x0
	jr ULE, SmfFmt_FillEmpty

SmfFmt_FormatLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x83E0
	extz XWA
	add XWA, XBC
	ld BC, QIZ
	add BC, IZ
	lda XDE, 0x88A0
	extz XBC
	add XBC, XDE
	ld C, (XBC)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x83E0
	extz XDE
	add XDE, XWA
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, (XSP + 0x4)
	jr C, SmfFmt_FormatLoop

SmfFmt_FillEmpty:
	cp IZ, 0xa
	jr NC, SmfFmt_Exit

SmfFmt_EmptyLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x83E0
	extz XWA
	add XWA, XBC
	ld BC, 0xff
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x83E0
	extz XDE
	add XDE, XWA
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr C, SmfFmt_EmptyLoop

SmfFmt_Exit:
	pop XIZ
	inc 6, XSP
	ret

FmmSmfMedleyFunc:
	dec 4, XSP
	push IZ
	ld XHL, XBC
	ld (XSP + 0x2), XWA
	cp XHL, 0x1e5000a
	jrl Z, SmfMed_CheckContinue
	ld XWA, XDE
	cp XHL, 0x1e50008
	jrl Z, SmfMed_StoreDelayFlag
	ld BC, (0x8438)
	cp XHL, 0x1c00018
	jrl Z, SmfMed_HandleNavToggle
	cp XHL, 0x1c00017
	jrl Z, SmfMed_HandleNavToggle
	cp XHL, 0x1c0000b
	jrl Z, SmfMed_RefreshDisplay
	cp XHL, 0x1e50004
	jrl Z, SmfMed_StoreWindowPtr
	cp XHL, 0x1c00013
	jrl NZ, SmfMed_Exit
	cp XDE, 0x3
	jrl Z, SmfMed_HandleStop
	cp XDE, 0x2
	jrl NZ, SmfMed_Exit
	ld WA, 0
	CALR InitializeOperationState
	ld A, (0x8D37)
	ld (0x843A), A
	cp A, 0x6f
	jr Z, SmfMed_CheckNotPlaying
	cp A, 0x72
	jr NZ, SmfMed_CheckPlayMode

SmfMed_CheckNotPlaying:
	ld (0x84FE), 0x0
	call LABEL_F2076D
	cp L, 4
	jr Z, SmfMed_Error3F
	cp L, 3
	jr Z, SmfMed_Error31
	cp L, 2
	jrl NZ, SmfMed_Exit
	ld (0x7F42), 0x1
	ld WA, 0xee
	jr SmfMed_ShowError

SmfMed_Error31:
	ld (0x7F42), 0x31
	ld WA, 0xee
	jr SmfMed_ShowError

SmfMed_Error3F:
	ld (0x7F42), 0x3f
	ld WA, 0xee

SmfMed_ShowError:
	call LABEL_F994BD
	jrl SmfMed_Exit

SmfMed_CheckPlayMode:
	cp A, 0x73
	jr Z, SmfMed_CheckPlaying
	cp A, 0x76
	jrl NZ, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	call LABEL_F2076D
	cp L, 1
	jrl C, SmfMed_CheckNotPlayError
	call LABEL_F2076D
	cp L, 4
	jr Z, SmfMed_PlayError3F
	cp L, 3
	jr Z, SmfMed_PlayError31
	cp L, 2
	jr NZ, SmfMed_SetPlaying
	ld (0x7F42), 0x1
	ld WA, 0xee
	jr SmfMed_ShowPlayError

SmfMed_PlayError31:
	ld (0x7F42), 0x31
	ld WA, 0xee
	jr SmfMed_ShowPlayError

SmfMed_PlayError3F:
	ld (0x7F42), 0x3f
	ld WA, 0xee

SmfMed_ShowPlayError:
	call LABEL_F994BD
	inc 1, (0x843C)

SmfMed_SetPlaying:
	ld (0x84FE), 0x1
	ld A, (0x8922)
	cp A, (0x8920)
	jr NC, SmfMed_CheckRepeat
	ld IZ, 0
	ld BC, (0x8438)
	cp BC, 0
	jrl ULE, SmfMed_Exit
	lda XDE, 0x88A0

SmfMed_FindSongLoop:
	ld HL, IZ
	extz XHL
	add XHL, XDE
	cp (XHL), A
	jr NZ, SmfMed_NextSong
	ld DE, IZ
	extz XDE
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1e50002
	CALR FmmSmfFileNameFunc
	ld XWA, (0x8430)
	ld BC, (0x8438)
	CALR SmfMed_FormatSlotList
	inc 1, (0x8922)
	ld WA, IZ
	call LABEL_F8A07F
	ld XWA, (0x8434)
	or XWA, XWA
	jrl Z, SmfMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e
	jr SmfMed_PostDelayEvent

SmfMed_NextSong:
	inc 1, IZ
	cp IZ, BC
	jr C, SmfMed_FindSongLoop
	jrl SmfMed_Exit

SmfMed_CheckRepeat:
	cp (0x8924), 0x0
	jr Z, SmfMed_ClearRepeatCount
	cp (0x843C), A
	jr NC, SmfMed_ClearRepeatCount
	ld (0x8922), 0x0
	ld (0x843C), 0x0
	ld IZ, 0
	ld WA, (0x8438)
	cp WA, 0
	jrl ULE, SmfMed_Exit
	lda XBC, 0x88A0

SmfMed_RepeatFindLoop:
	ld DE, IZ
	extz XDE
	add XDE, XBC
	cp (XDE), 0x0
	jr NZ, SmfMed_RepeatNext
	ld DE, IZ
	extz XDE
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1e50002
	CALR FmmSmfFileNameFunc
	ld XWA, (0x8430)
	ld BC, (0x8438)
	CALR SmfMed_FormatSlotList
	inc 1, (0x8922)
	ld WA, IZ
	call LABEL_F8A07F
	ld XWA, (0x8434)
	or XWA, XWA
	jrl Z, SmfMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e

SmfMed_PostDelayEvent:
	call ApPostEvent
	jrl SmfMed_Exit

SmfMed_RepeatNext:
	inc 1, IZ
	cp IZ, WA
	jr C, SmfMed_RepeatFindLoop
	jrl SmfMed_Exit

SmfMed_ClearRepeatCount:
	ld (0x843C), 0x0
	jr SmfMed_ClearPlaying

SmfMed_CheckNotPlayError:
	call LABEL_F2076D
	cp L, 0
	jrl NZ, SmfMed_Exit

SmfMed_ClearPlaying:
	ld (0x84FE), 0x0
	jrl SmfMed_Exit

SmfMed_InitFromDisk:
	ld XDE, 0
	ld E, (0x8944)
	ld XWA, 0x6c0018
	ld XBC, 0x1e0003b
	call ApPostEvent
	cpw (0x8504), 0x0
	jr GE, SmfMed_InitState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call GetFileCountEncoded
	ld (0x8504), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	CALR SignalProgressUpdate

SmfMed_InitState:
	ld (0x84FE), 0x0
	ld (0x8922), 0x0
	ld (0x8920), 0x0
	ld BC, 0x80
	ld WA, (0x8504)
	cp WA, 0x80
	jr UGT, SmfMed_ClampFileCount
	ld BC, WA

SmfMed_ClampFileCount:
	ld (0x8438), BC
	ld IZ, 0
	cp BC, 0
	jr ULE, SmfMed_FinishInit
	lda XWA, 0x88A0

SmfMed_ClearSlotsLoop:
	ld BC, IZ
	extz XBC
	add XBC, XWA
	ld (XBC), 0xff
	inc 1, IZ
	cp IZ, (0x8438)
	jr C, SmfMed_ClearSlotsLoop

SmfMed_FinishInit:
	call LABEL_F20ACD
	ld XWA, 0
	ld (0x8434), XWA
	jrl SmfMed_Exit

SmfMed_HandleStop:
	ld A, (0x8D36)
	cp A, 0x6f
	jrl Z, SmfMed_Exit
	cp A, 0x72
	jrl Z, SmfMed_Exit
	cp A, 0x73
	jrl Z, SmfMed_Exit
	cp A, 0x76
	jrl Z, SmfMed_Exit
	call LABEL_F20B70
	CALR CancelOperationCleanup
	ld (0x84FE), 0x0
	jrl SmfMed_Exit

SmfMed_StoreWindowPtr:
	ld (0x8430), XWA
	jrl SmfMed_Exit

SmfMed_RefreshDisplay:
	ld XWA, (0x8430)
	CALR SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleNavToggle:
	lda XWA, 0x88A0
	cp XDE, 0xa
	jr NZ, SmfMed_HandleSelectToggle
	cp (0x84FE), 0x0
	jr NZ, SmfMed_HandleSelectToggle
	ld IZ, 0
	ld DE, BC
	cp BC, 0
	jr ULE, SmfMed_CheckAllUnmarked

SmfMed_FindUnmarkedLoop:
	ld BC, IZ
	extz XBC
	add XBC, XWA
	cp (XBC), 0xff
	jr Z, SmfMed_CheckAllUnmarked
	inc 1, IZ
	cp IZ, DE
	jr C, SmfMed_FindUnmarkedLoop

SmfMed_CheckAllUnmarked:
	cp IZ, DE
	jr NC, SmfMed_RemoveOrderLoop
	ld IZ, 0
	cp DE, 0
	jr ULE, SmfMed_RefreshAfterToggle
	lda XDE, 0x88A0

SmfMed_AssignOrderLoop:
	ld BC, IZ
	extz XBC
	add XBC, XDE
	ld A, (XBC)
	cp A, 0xff
	jr NZ, SmfMed_NextAssign
	ld (XBC), (0x8920)
	inc 1, (0x8920)

SmfMed_NextAssign:
	inc 1, IZ
	cp IZ, (0x8438)
	jr C, SmfMed_AssignOrderLoop
	jr SmfMed_RefreshAfterToggle

SmfMed_RemoveOrderLoop:
	ld IZ, 0
	cp DE, 0
	jr ULE, SmfMed_RefreshAfterToggle
	lda XDE, 0x88A0

SmfMed_UnmarkLoop:
	ld BC, IZ
	extz XBC
	add XBC, XDE
	ld A, (XBC)
	cp A, 0xfd
	jr UGT, SmfMed_NextUnmark
	ld (XBC), 0xff
	dec 1, (0x8920)

SmfMed_NextUnmark:
	inc 1, IZ
	cp IZ, (0x8438)
	jr C, SmfMed_UnmarkLoop

SmfMed_RefreshAfterToggle:
	ld XWA, (0x8430)
	ld BC, (0x8438)
	jr SmfMed_CallFormatSlots

SmfMed_HandleSelectToggle:
	cp XDE, 0xb
	jr NZ, SmfMed_HandleRepeat
	cp (0x84FE), 0x0
	jr NZ, SmfMed_HandleRepeat
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmSmfFileNameFunc
	ld IZ, HL
	lda XHL, 0x88A0
	ld WA, IZ
	extz XWA
	add XWA, XHL
	ld C, (XWA)
	cp C, 0xff
	jr NZ, SmfMed_RemoveFromOrder
	ld (XWA), (0x8920)
	inc 1, (0x8920)
	jr SmfMed_RefreshAfterSelect

SmfMed_RemoveFromOrder:
	cp C, 0xfd
	jr UGT, SmfMed_RefreshAfterSelect
	ld (XWA), 0xff
	ld A, (0x8920)
	dec 1, A
	ld (0x8920), A
	ld IY, 0
	ld IZ, 0
	extz WA
	cp WA, 0
	jr ULE, SmfMed_RefreshAfterSelect
	ld IX, WA

SmfMed_ReorderLoop:
	ld DE, IZ
	extz XDE
	add XDE, XHL
	ld A, (XDE)
	cp A, 0xfd
	jr UGT, SmfMed_NextReorder
	inc 1, IY
	cp A, C
	jr ULE, SmfMed_NextReorder
	dec 1, A
	ld (XDE), A

SmfMed_NextReorder:
	inc 1, IZ
	cp IY, IX
	jr C, SmfMed_ReorderLoop

SmfMed_RefreshAfterSelect:
	ld XWA, (0x8430)
	ld BC, (0x8438)

SmfMed_CallFormatSlots:
	CALR SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleRepeat:
	cp XDE, 0xc
	jr NZ, SmfMed_HandlePlay
	cp XHL, 0x1c00017
	jr NZ, SmfMed_SetRepeatOff
	ld (0x8924), 0x1
	jrl SmfMed_Exit

SmfMed_SetRepeatOff:
	ld (0x8924), 0x0
	jrl SmfMed_Exit

SmfMed_HandlePlay:
	cp XDE, 0xd
	jrl NZ, SmfMed_Exit
	cp (0x84FE), 0x0
	jrl NZ, SmfMed_Exit
	ld (0x8922), 0x0
	ld (0x843C), 0x0
	ld IZ, 0
	ld BC, (0x8438)
	cp BC, 0
	jr ULE, SmfMed_CheckAutoPlay

SmfMed_PlayFindLoop:
	ld DE, IZ
	extz XDE
	add XDE, XWA
	cp (XDE), 0x0
	jr NZ, SmfMed_PlayNextLoop
	ld (0x84FE), 0x1
	ld DE, IZ
	extz XDE
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1e50002
	CALR FmmSmfFileNameFunc
	inc 1, (0x8922)
	ld WA, IZ
	call LABEL_F8A07F
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x73
	call UI_PostModeChangeEvent
	jr SmfMed_CheckAutoPlay

SmfMed_PlayNextLoop:
	inc 1, IZ
	cp IZ, BC
	jr C, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	cp (0x84FE), 0x0
	jr NZ, SmfMed_Exit
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmSmfFileNameFunc
	ld IZ, HL
	ld WA, IZ
	call LABEL_F8A07F
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x6f
	jr SmfMed_CallPauseMode

SmfMed_StoreDelayFlag:
	ld (0x8434), XWA
	jr SmfMed_Exit

SmfMed_CheckContinue:
	cp (0x84FE), 0x0
	jr Z, SmfMed_Exit
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld A, (0x843A)
	extz WA

SmfMed_CallPauseMode:
	call UI_PostModeChangeEvent

SmfMed_Exit:
	ld XHL, 0
	pop IZ
	inc 4, XSP
	ret

PdMed_FormatFileList:
	dec 6, XSP
	push IZ
	ld (XSP + 0x2), BC
	ld (XSP + 0x4), XWA
	ld IZ, 0

PdFmt_FormatLoop:
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld A, IZL
	ld (XDE), A
	ld WA, (XSP + 0x2)
	add WA, IZ
	call LABEL_F8A5F1
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
	pushw 0x14
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
	jr LT, PdFmt_FormatLoop
	pop IZ
	inc 6, XSP
	ret

FmmPdFileNameFunc:
	dec 4, XSP
	push IZ
	ld (XSP + 0x2), XWA
	cp XBC, 0x1e50003
	jrl Z, PdName_GetIndexReturn
	ld WA, (0x8442)
	ld IZ, WA
	cp XBC, 0x1e50002
	jrl Z, PdName_SetIndexPlaying
	ld HL, WA
	exts XHL
	DIVS_HL 0xa
	cp XBC, 0x1c00018
	jr Z, PdName_HandleNavigation
	cp XBC, 0x1c00017
	jr Z, PdName_HandleNavigation
	cp XBC, 0x1c0000b
	jr Z, PdName_RefreshList
	cp XBC, 0x1e50004
	jr NZ, PdName_ReturnZero
	ld (0x843E), XDE
	call LABEL_F8A4C8
	ld (0x8442), HL
	cp HL, 0
	jr GE, PdName_UpdateIndex
	ldw (0x8442), 0x0

PdName_UpdateIndex:
	ld WA, (0x8442)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x843E)
	ld XBC, 0x1e50002
	jrl PdName_PostEvent

PdName_RefreshList:
	MULS_HL 0xa
	ld XWA, (0x843E)
	ld BC, HL
	CALR PdMed_FormatFileList

PdName_ReturnZero:
	ld XHL, 0
	jrl PdName_Exit

PdName_HandleNavigation:
	or XDE, XDE
	jr NZ, PdName_CheckPageUp
	cp (0x84FE), 0x0
	jr NZ, PdName_CheckPageUp
	cp XBC, 0x1c00018
	jr NZ, PdName_CheckPrevKey
	ld BC, WA
	inc 1, BC
	cp BC, (0x8506)
	jr GE, PdName_GetCurrentIndex
	inc 1, WA
	jr PdName_SaveIndex

PdName_CheckPrevKey:
	cp XBC, 0x1c00017
	jr NZ, PdName_GetCurrentIndex
	cp WA, 0
	jr LE, PdName_GetCurrentIndex
	dec 1, WA
	jr PdName_SaveIndex

PdName_CheckPageUp:
	cp XDE, 0x1
	jr NZ, PdName_CheckPageDown
	cp (0x84FE), 0x0
	jr NZ, PdName_CheckPageDown
	cp WA, 0xa
	jr LT, PdName_GetCurrentIndex
	sub WA, 0xa
	jr PdName_SaveIndex

PdName_CheckPageDown:
	cp XDE, 0x2
	jr NZ, PdName_GetCurrentIndex
	cp (0x84FE), 0x0
	jr NZ, PdName_GetCurrentIndex
	ld BC, WA
	add BC, 0xa
	ld DE, (0x8506)
	cp BC, DE
	jr GE, PdName_CheckEndBound
	add WA, 0xa

PdName_SaveIndex:
	ld (0x8442), WA
	jr PdName_UpdateDisplay

PdName_CheckEndBound:
	ld BC, DE
	dec 1, BC
	ld WA, BC
	exts XWA
	DIVS_WA 0xa
	cp HL, WA
	jr GE, PdName_GetCurrentIndex
	exts XDE
	DIVS_DE 0xa
	ld WA, QDE
	cp WA, 0
	jr Z, PdName_GetCurrentIndex
	ld (0x8442), BC

PdName_GetCurrentIndex:
	ld WA, (0x8442)

PdName_UpdateDisplay:
	cp IZ, WA
	jrl Z, PdName_ReturnZero
	call LABEL_F8A5A5
	ld WA, (0x8442)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x843E)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld BC, (0x8442)
	exts XBC
	DIVS_BC 0xa
	ld DE, IZ
	exts XDE
	DIVS_DE 0xa
	ld XWA, (0x843E)
	cp DE, BC
	jr NZ, PdName_RefreshPage
	ld BC, IZ
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
	ld WA, (0x8442)
	exts XWA
	DIVS_WA 0xa
	ld WA, QWA
	sll WA, 5
	lda XBC, 0x850C
	ld DE, WA
	extz XDE
	add XDE, XBC
	ld XWA, (0x843E)
	ld XBC, 0x1c0000f
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_RefreshPage:
	MULS_BC 0xa
	CALR PdMed_FormatFileList
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmPdMedleyFunc
	jrl PdName_ReturnZero

PdName_SetIndexPlaying:
	cp (0x84FE), 0x0
	jrl Z, PdName_ReturnZero
	ld (0x8442), DE
	ld WA, DE
	call LABEL_F8A5A5
	ld WA, (0x8442)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x843E)
	ld XBC, 0x1e50002

PdName_PostEvent:
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_GetIndexReturn:
	ld HL, (0x8442)
	exts XHL

PdName_Exit:
	pop IZ
	inc 4, XSP
	ret

PdMed_FormatSlotList:
	dec 6, XSP
	push XIZ
	ld IZ, BC
	ld (XSP + 0x6), XWA
	ld XWA, 0
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmPdFileNameFunc
	ld QIZ, HL
	ld WA, QIZ
	extz XWA
	DIVW_WA 0xa
	ld QIZ, WA
	MULW_WA 0xa
	ld QIZ, WA
	ldw (XSP + 0x4), 0xa
	ld WA, QIZ
	add WA, 0xa
	cp WA, IZ
	jr C, PdFmtSlot_CalcVisible
	ld (XSP + 0x4), IZ
	ld WA, QIZ
	sub (XSP + 0x4), WA

PdFmtSlot_CalcVisible:
	ld IZ, 0
	cpw (XSP + 0x4), 0x0
	jr ULE, PdFmtSlot_FillEmpty

PdFmtSlot_FormatLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x8444
	extz XWA
	add XWA, XBC
	ld BC, QIZ
	add BC, IZ
	lda XDE, 0x88A0
	extz XBC
	add XBC, XDE
	ld C, (XBC)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x8444
	extz XDE
	add XDE, XWA
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, (XSP + 0x4)
	jr C, PdFmtSlot_FormatLoop

PdFmtSlot_FillEmpty:
	cp IZ, 0xa
	jr NC, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x8444
	extz XWA
	add XWA, XBC
	ld BC, 0xff
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x8444
	extz XDE
	add XDE, XWA
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr C, PdFmtSlot_EmptyLoop

PdFmtSlot_Exit:
	pop XIZ
	inc 6, XSP
	ret

FmmPdMedleyFunc:
	push XIZ
	ld XHL, XDE
	ld XDE, XBC
	ld XIZ, XWA
	cp XDE, 0x1e5000a
	jrl Z, PdMed_CheckContinue
	ld XWA, XHL
	cp XDE, 0x1e50008
	jrl Z, PdMed_StoreDelayFlag
	ld BC, (0x849C)
	cp XDE, 0x1c00018
	jrl Z, PdMed_HandleNavToggle
	cp XDE, 0x1c00017
	jrl Z, PdMed_HandleNavToggle
	cp XDE, 0x1c0000b
	jrl Z, PdMed_RefreshDisplay
	cp XDE, 0x1e50004
	jrl Z, PdMed_StoreWindowPtr
	cp XDE, 0x1c00013
	jrl NZ, PdMed_Exit
	cp XHL, 0x3
	jrl Z, PdMed_HandleStop
	cp XHL, 0x2
	jrl NZ, PdMed_Exit
	ld WA, 0
	call InitializeOperationState
	ld A, (0x8D37)
	cp A, 0x71
	jr NZ, PdMed_CheckPlayMode
	ld (0x84FE), 0x0
	call LABEL_F2076D
	cp L, 2
	jrl C, PdMed_Exit
	ld (0x7F42), 0x1
	ld WA, 0xee
	jrl PdMed_ShowError

PdMed_CheckPlayMode:
	cp A, 0x75
	jrl NZ, PdMed_InitFromDisk
	call LABEL_F2076D
	cp L, 1
	jrl NZ, PdMed_HandleError
	ld (0x84FE), 0x1
	ld C, (0x8922)
	lda XWA, 0x88A0
	cp C, (0x8920)
	jr NC, PdMed_CheckRepeat
	ld HL, 0
	ld DE, (0x849C)
	cp DE, 0
	jrl ULE, PdMed_Exit

PdMed_FindSongLoop:
	ld IX, HL
	extz XIX
	add XIX, XWA
	cp (XIX), C
	jr NZ, PdMed_NextSong
	extz XHL
	ld XWA, XIZ
	ld XBC, 0x1e50002
	ld XDE, XHL
	CALR FmmPdFileNameFunc
	ld XWA, (0x8494)
	ld BC, (0x849C)
	CALR PdMed_FormatSlotList
	inc 1, (0x8922)
	ld XWA, (0x8498)
	or XWA, XWA
	jrl Z, PdMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e
	jr PdMed_PostDelayEvent

PdMed_NextSong:
	inc 1, HL
	cp HL, DE
	jr C, PdMed_FindSongLoop
	jrl PdMed_Exit

PdMed_CheckRepeat:
	cp (0x8924), 0x0
	jr Z, PdMed_ClearPlaying
	ld (0x8922), 0x0
	ld HL, 0
	ld BC, (0x849C)
	cp BC, 0
	jrl ULE, PdMed_Exit

PdMed_RepeatFindLoop:
	ld DE, HL
	extz XDE
	add XDE, XWA
	cp (XDE), 0x0
	jr NZ, PdMed_RepeatNext
	extz XHL
	ld XWA, XIZ
	ld XBC, 0x1e50002
	ld XDE, XHL
	CALR FmmPdFileNameFunc
	ld XWA, (0x8494)
	ld BC, (0x849C)
	CALR PdMed_FormatSlotList
	inc 1, (0x8922)
	ld XWA, (0x8498)
	or XWA, XWA
	jrl Z, PdMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e

PdMed_PostDelayEvent:
	call ApPostEvent
	jrl PdMed_Exit

PdMed_RepeatNext:
	inc 1, HL
	cp HL, BC
	jr C, PdMed_RepeatFindLoop
	jrl PdMed_Exit

PdMed_ClearPlaying:
	ld (0x84FE), 0x0
	jrl PdMed_Exit

PdMed_HandleError:
	call LABEL_F2076D
	ld (0x84FE), 0x0
	cp L, 0
	jrl Z, PdMed_Exit
	ld (0x7F42), 0x1
	ld WA, 0xee

PdMed_ShowError:
	call LABEL_F994BD
	jrl PdMed_Exit

PdMed_InitFromDisk:
	cpw (0x8506), 0x0
	jr GE, PdMed_InitState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call LABEL_F8A625
	ld (0x8506), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	call SignalProgressUpdate

PdMed_InitState:
	ld (0x84FE), 0x0
	ld (0x8922), 0x0
	ld (0x8920), 0x0
	ld BC, 0x80
	ld WA, (0x8506)
	cp WA, 0x80
	jr UGT, PdMed_ClampCount
	ld BC, WA

PdMed_ClampCount:
	ld (0x849C), BC
	ld HL, 0
	cp BC, 0
	jr ULE, PdMed_FinishInit
	lda XWA, 0x88A0

PdMed_ClearSlotsLoop:
	ld BC, HL
	extz XBC
	add XBC, XWA
	ld (XBC), 0xff
	inc 1, HL
	cp HL, (0x849C)
	jr C, PdMed_ClearSlotsLoop

PdMed_FinishInit:
	call LABEL_F20ACD
	ld XWA, 0
	ld (0x8498), XWA
	jrl PdMed_Exit

PdMed_HandleStop:
	ld A, (0x8D36)
	cp A, 0x71
	jrl Z, PdMed_Exit
	cp A, 0x75
	jrl Z, PdMed_Exit
	call LABEL_F20B70
	call CancelOperationCleanup
	ld (0x84FE), 0x0
	jrl PdMed_Exit

PdMed_StoreWindowPtr:
	ld (0x8494), XWA
	jrl PdMed_Exit

PdMed_RefreshDisplay:
	ld XWA, (0x8494)
	CALR PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleNavToggle:
	cp XHL, 0xa
	jrl NZ, PdMed_HandleSelectToggle
	cp (0x84FE), 0x0
	jr NZ, PdMed_HandleSelectToggle
	ld HL, 0
	ld WA, BC
	cp BC, 0
	jr ULE, PdMed_CheckAllUnmarked
	lda XBC, 0x88A0

PdMed_FindUnmarkedLoop:
	ld DE, HL
	extz XDE
	add XDE, XBC
	cp (XDE), 0xff
	jr Z, PdMed_CheckAllUnmarked
	inc 1, HL
	cp HL, WA
	jr C, PdMed_FindUnmarkedLoop

PdMed_CheckAllUnmarked:
	cp HL, WA
	jr NC, PdMed_RemoveOrderLoop
	ld HL, 0
	cp WA, 0
	jr ULE, PdMed_RefreshAfterToggle
	lda XDE, 0x88A0

PdMed_AssignOrderLoop:
	ld BC, HL
	extz XBC
	add XBC, XDE
	ld A, (XBC)
	cp A, 0xff
	jr NZ, PdMed_NextAssign
	ld (XBC), (0x8920)
	inc 1, (0x8920)

PdMed_NextAssign:
	inc 1, HL
	cp HL, (0x849C)
	jr C, PdMed_AssignOrderLoop
	jr PdMed_RefreshAfterToggle

PdMed_RemoveOrderLoop:
	ld HL, 0
	cp WA, 0
	jr ULE, PdMed_RefreshAfterToggle
	lda XDE, 0x88A0

PdMed_UnmarkLoop:
	ld BC, HL
	extz XBC
	add XBC, XDE
	ld A, (XBC)
	cp A, 0xfd
	jr UGT, PdMed_NextUnmark
	ld (XBC), 0xff
	dec 1, (0x8920)

PdMed_NextUnmark:
	inc 1, HL
	cp HL, (0x849C)
	jr C, PdMed_UnmarkLoop

PdMed_RefreshAfterToggle:
	ld XWA, (0x8494)
	ld BC, (0x849C)
	jr PdMed_CallFormatSlots

PdMed_HandleSelectToggle:
	cp XHL, 0xb
	jr NZ, PdMed_HandleRepeat
	cp (0x84FE), 0x0
	jr NZ, PdMed_HandleRepeat
	ld XWA, XIZ
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmPdFileNameFunc
	lda XIX, 0x88A0
	extz XHL
	add XHL, XIX
	ld C, (XHL)
	cp C, 0xff
	jr NZ, PdMed_RemoveFromOrder
	ld (XHL), (0x8920)
	inc 1, (0x8920)
	jr PdMed_RefreshAfterSelect

PdMed_RemoveFromOrder:
	cp C, 0xfd
	jr UGT, PdMed_RefreshAfterSelect
	ld (XHL), 0xff
	ld A, (0x8920)
	dec 1, A
	ld (0x8920), A
	ld IZ, 0
	ld HL, 0
	extz WA
	cp WA, 0
	jr ULE, PdMed_RefreshAfterSelect
	ld IY, WA

PdMed_ReorderLoop:
	ld DE, HL
	extz XDE
	add XDE, XIX
	ld A, (XDE)
	cp A, 0xfd
	jr UGT, PdMed_NextReorder
	inc 1, IZ
	cp A, C
	jr ULE, PdMed_NextReorder
	dec 1, A
	ld (XDE), A

PdMed_NextReorder:
	inc 1, HL
	cp IZ, IY
	jr C, PdMed_ReorderLoop

PdMed_RefreshAfterSelect:
	ld XWA, (0x8494)
	ld BC, (0x849C)

PdMed_CallFormatSlots:
	CALR PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleRepeat:
	cp XHL, 0xc
	jr NZ, PdMed_HandlePlay
	cp XDE, 0x1c00017
	jr NZ, PdMed_SetRepeatOff
	ld (0x8924), 0x1
	jrl PdMed_Exit

PdMed_SetRepeatOff:
	ld (0x8924), 0x0
	jrl PdMed_Exit

PdMed_HandlePlay:
	cp XHL, 0xd
	jrl NZ, PdMed_Exit
	cp (0x84FE), 0x0
	jrl NZ, PdMed_Exit
	ld (0x8922), 0x0
	ld HL, 0
	ld WA, (0x849C)
	cp WA, 0
	jr ULE, PdMed_CheckAutoPlay
	lda XBC, 0x88A0

PdMed_PlayFindLoop:
	ld DE, HL
	extz XDE
	add XDE, XBC
	cp (XDE), 0x0
	jr NZ, PdMed_PlayNextLoop
	ld (0x84FE), 0x1
	extz XHL
	ld XWA, XIZ
	ld XBC, 0x1e50002
	ld XDE, XHL
	CALR FmmPdFileNameFunc
	inc 1, (0x8922)
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x75
	call UI_PostModeChangeEvent
	jr PdMed_CheckAutoPlay

PdMed_PlayNextLoop:
	inc 1, HL
	cp HL, WA
	jr C, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	cp (0x84FE), 0x0
	jr NZ, PdMed_Exit
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x71
	jr PdMed_CallPauseMode

PdMed_StoreDelayFlag:
	ld (0x8498), XWA
	jr PdMed_Exit

PdMed_CheckContinue:
	cp (0x84FE), 0x0
	jr Z, PdMed_Exit
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x75

PdMed_CallPauseMode:
	call UI_PostModeChangeEvent

PdMed_Exit:
	ld XHL, 0
	pop XIZ
	ret

DocDiskNameFunc:
	push XIZ
	ld XIZ, XDE
	cp XBC, 0x1c0000b
	jr NZ, DocDisk_Exit
	call LABEL_F8958D
	ld IX, 0
	jr DocDisk_CopyLoop

DocDisk_CopyCharLoop:
	cp (XHL), 0x20
	jr Z, DocDisk_SkipSpace
	ld DE, IX
	inc 1, IX
	ld A, (XHL)
	ld (XBC + DE), A

DocDisk_SkipSpace:
	inc 1, XHL

DocDisk_CopyLoop:
	lda XBC, 0x878C
	cp (XHL), 0x0
	jr Z, DocDisk_TerminateStr
	cp IX, 0x1e
	jr LT, DocDisk_CopyCharLoop

DocDisk_TerminateStr:
	ld XDE, XBC
	ld (XBC + IX), 0x0
	jr DocDisk_TrimLoop

DocDisk_ClearTrailing:
	ld (XWA), 0x0

DocDisk_TrimLoop:
	dec 1, IX
	lda XWA, XDE + IX
	cp (XWA), 0x20
	jr NZ, DocDisk_PostEvent
	cp IX, 0
	jr GT, DocDisk_ClearTrailing

DocDisk_PostEvent:
	ld XWA, XIZ
	ld XBC, 0x1c0000f
	call ApPostEvent

DocDisk_Exit:
	ld XHL, 0
	pop XIZ
	ret

DocMed_FormatFileList:
	dec 6, XSP
	push IZ
	ld (XSP + 0x2), BC
	ld (XSP + 0x4), XWA
	ld IZ, 0

DocFmt_FormatLoop:
	ld DE, IZ
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld A, IZL
	ld (XDE), A
	ld WA, (XSP + 0x2)
	add WA, IZ
	call LABEL_F8ABBB
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
	pushw 0x0
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
	jr LT, DocFmt_FormatLoop
	pop IZ
	inc 6, XSP
	ret

FmmDocFileNameFunc:
	dec 4, XSP
	push IZ
	ld (XSP + 0x2), XWA
	cp XBC, 0x1e50003
	jrl Z, DocName_GetIndexReturn
	ld WA, (0x84A2)
	ld IZ, WA
	cp XBC, 0x1e50002
	jrl Z, DocName_SetIndexPlaying
	ld HL, WA
	exts XHL
	DIVS_HL 0xa
	cp XBC, 0x1c00018
	jr Z, DocName_HandleNavigation
	cp XBC, 0x1c00017
	jr Z, DocName_HandleNavigation
	cp XBC, 0x1c0000b
	jr Z, DocName_RefreshList
	cp XBC, 0x1e50004
	jr NZ, DocName_ReturnZero
	ld (0x849E), XDE
	call LABEL_F8A7CE
	ld (0x84A2), HL
	cp HL, 0
	jr GE, DocName_UpdateIndex
	ldw (0x84A2), 0x0

DocName_UpdateIndex:
	ld WA, (0x84A2)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x849E)
	ld XBC, 0x1e50002
	jrl DocName_PostEvent

DocName_RefreshList:
	MULS_HL 0xa
	ld XWA, (0x849E)
	ld BC, HL
	CALR DocMed_FormatFileList

DocName_ReturnZero:
	ld XHL, 0
	jrl DocName_Exit

DocName_HandleNavigation:
	or XDE, XDE
	jr NZ, DocName_CheckPageUp
	cp (0x84FE), 0x0
	jr NZ, DocName_CheckPageUp
	cp XBC, 0x1c00018
	jr NZ, DocName_CheckPrevKey
	ld BC, WA
	inc 1, BC
	cp BC, (0x8508)
	jr GE, DocName_GetCurrentIndex
	inc 1, WA
	jr DocName_SaveIndex

DocName_CheckPrevKey:
	cp XBC, 0x1c00017
	jr NZ, DocName_GetCurrentIndex
	cp WA, 0
	jr LE, DocName_GetCurrentIndex
	dec 1, WA
	jr DocName_SaveIndex

DocName_CheckPageUp:
	cp XDE, 0x1
	jr NZ, DocName_CheckPageDown
	cp (0x84FE), 0x0
	jr NZ, DocName_CheckPageDown
	cp WA, 0xa
	jr LT, DocName_GetCurrentIndex
	sub WA, 0xa
	jr DocName_SaveIndex

DocName_CheckPageDown:
	cp XDE, 0x2
	jr NZ, DocName_GetCurrentIndex
	cp (0x84FE), 0x0
	jr NZ, DocName_GetCurrentIndex
	ld BC, WA
	add BC, 0xa
	ld DE, (0x8508)
	cp BC, DE
	jr GE, DocName_CheckEndBound
	add WA, 0xa

DocName_SaveIndex:
	ld (0x84A2), WA
	jr DocName_UpdateDisplay

DocName_CheckEndBound:
	ld BC, DE
	dec 1, BC
	ld WA, BC
	exts XWA
	DIVS_WA 0xa
	cp HL, WA
	jr GE, DocName_GetCurrentIndex
	exts XDE
	DIVS_DE 0xa
	ld WA, QDE
	cp WA, 0
	jr Z, DocName_GetCurrentIndex
	ld (0x84A2), BC

DocName_GetCurrentIndex:
	ld WA, (0x84A2)

DocName_UpdateDisplay:
	cp IZ, WA
	jrl Z, DocName_ReturnZero
	call LABEL_F8A956
	ld WA, (0x84A2)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x849E)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld BC, (0x84A2)
	exts XBC
	DIVS_BC 0xa
	ld DE, IZ
	exts XDE
	DIVS_DE 0xa
	ld XWA, (0x849E)
	cp DE, BC
	jr NZ, DocName_RefreshPage
	ld BC, IZ
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
	ld WA, (0x84A2)
	exts XWA
	DIVS_WA 0xa
	ld WA, QWA
	sll WA, 5
	lda XBC, 0x850C
	ld DE, WA
	extz XDE
	add XDE, XBC
	ld XWA, (0x849E)
	ld XBC, 0x1c0000f
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_RefreshPage:
	MULS_BC 0xa
	CALR DocMed_FormatFileList
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1c0000b
	ld XDE, 0
	CALR FmmDocMedleyFunc
	jrl DocName_ReturnZero

DocName_SetIndexPlaying:
	cp (0x84FE), 0x0
	jrl Z, DocName_ReturnZero
	ld (0x84A2), DE
	ld WA, DE
	call LABEL_F8A956
	ld WA, (0x84A2)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x849E)
	ld XBC, 0x1e50002

DocName_PostEvent:
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_GetIndexReturn:
	ld HL, (0x84A2)
	exts XHL

DocName_Exit:
	pop IZ
	inc 4, XSP
	ret

DocMed_FormatSlotList:
	dec 6, XSP
	push XIZ
	ld IZ, BC
	ld (XSP + 0x6), XWA
	ld XWA, 0
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmDocFileNameFunc
	ld QIZ, HL
	ld WA, QIZ
	extz XWA
	DIVW_WA 0xa
	ld QIZ, WA
	MULW_WA 0xa
	ld QIZ, WA
	ldw (XSP + 0x4), 0xa
	ld WA, QIZ
	add WA, 0xa
	cp WA, IZ
	jr C, DocFmtSlot_CalcVisible
	ld (XSP + 0x4), IZ
	ld WA, QIZ
	sub (XSP + 0x4), WA

DocFmtSlot_CalcVisible:
	ld IZ, 0
	cpw (XSP + 0x4), 0x0
	jr ULE, DocFmtSlot_FillEmpty

DocFmtSlot_FormatLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x84A4
	extz XWA
	add XWA, XBC
	ld BC, QIZ
	add BC, IZ
	lda XDE, 0x88A0
	extz XBC
	add XBC, XDE
	ld C, (XBC)
	extz BC
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x84A4
	extz XDE
	add XDE, XWA
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, (XSP + 0x4)
	jr C, DocFmtSlot_FormatLoop

DocFmtSlot_FillEmpty:
	cp IZ, 0xa
	jr NC, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	ld WA, IZ
	sll WA, 3
	lda XBC, 0x84A4
	extz XWA
	add XWA, XBC
	ld BC, 0xff
	ld DE, IZ
	CALR FormatMedleyNumber
	ld DE, IZ
	sll DE, 3
	lda XWA, 0x84A4
	extz XDE
	add XDE, XWA
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0xa
	jr C, DocFmtSlot_EmptyLoop

DocFmtSlot_Exit:
	pop XIZ
	inc 6, XSP
	ret

FmmDocMedleyFunc:
	push XIZ
	ld XHL, XDE
	ld XDE, XBC
	ld XIZ, XWA
	cp XDE, 0x1e5000a
	jrl Z, DocMed_CheckContinue
	ld XWA, XHL
	cp XDE, 0x1e50008
	jrl Z, DocMed_StoreDelayFlag
	ld BC, (0x84FC)
	cp XDE, 0x1c00018
	jrl Z, DocMed_HandleNavToggle
	cp XDE, 0x1c00017
	jrl Z, DocMed_HandleNavToggle
	cp XDE, 0x1c0000b
	jrl Z, DocMed_RefreshDisplay
	cp XDE, 0x1e50004
	jrl Z, DocMed_StoreWindowPtr
	cp XDE, 0x1c00013
	jrl NZ, DocMed_Exit
	cp XHL, 0x3
	jrl Z, DocMed_HandleStop
	cp XHL, 0x2
	jrl NZ, DocMed_Exit
	ld WA, 0
	call InitializeOperationState
	ld A, (0x8D37)
	cp A, 0x70
	jr NZ, DocMed_CheckPlayMode
	ld (0x84FE), 0x0
	call LABEL_F2076D
	cp L, 2
	jrl C, DocMed_Exit
	ld (0x7F42), 0x1
	ld WA, 0xee
	jrl DocMed_ShowError

DocMed_CheckPlayMode:
	cp A, 0x74
	jrl NZ, DocMed_CheckInit
	call LABEL_F2076D
	cp L, 1
	jrl NZ, DocMed_HandleError
	ld (0x84FE), 0x1
	ld C, (0x8922)
	lda XWA, 0x88A0
	cp C, (0x8920)
	jr NC, DocMed_CheckRepeat
	ld HL, 0
	ld DE, (0x84FC)
	cp DE, 0
	jrl ULE, DocMed_Exit

DocMed_FindSongLoop:
	ld IX, HL
	extz XIX
	add XIX, XWA
	cp (XIX), C
	jr NZ, DocMed_NextSong
	extz XHL
	ld XWA, XIZ
	ld XBC, 0x1e50002
	ld XDE, XHL
	CALR FmmDocFileNameFunc
	ld XWA, (0x84F4)
	ld BC, (0x84FC)
	CALR DocMed_FormatSlotList
	inc 1, (0x8922)
	ld XWA, (0x84F8)
	or XWA, XWA
	jrl Z, DocMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e
	jr DocMed_PostDelayEvent

DocMed_NextSong:
	inc 1, HL
	cp HL, DE
	jr C, DocMed_FindSongLoop
	jrl DocMed_Exit

DocMed_CheckRepeat:
	cp (0x8924), 0x0
	jr Z, DocMed_ClearPlaying
	ld (0x8922), 0x0
	ld HL, 0
	ld BC, (0x84FC)
	cp BC, 0
	jrl ULE, DocMed_Exit

DocMed_RepeatFindLoop:
	ld DE, HL
	extz XDE
	add XDE, XWA
	cp (XDE), 0x0
	jr NZ, DocMed_RepeatNext
	extz XHL
	ld XWA, XIZ
	ld XBC, 0x1e50002
	ld XDE, XHL
	CALR FmmDocFileNameFunc
	ld XWA, (0x84F4)
	ld BC, (0x84FC)
	CALR DocMed_FormatSlotList
	inc 1, (0x8922)
	ld XWA, (0x84F8)
	or XWA, XWA
	jrl Z, DocMed_Exit
	ld XBC, 0x1e50009
	ld XDE, 0x1e

DocMed_PostDelayEvent:
	call ApPostEvent
	jrl DocMed_Exit

DocMed_RepeatNext:
	inc 1, HL
	cp HL, BC
	jr C, DocMed_RepeatFindLoop
	jrl DocMed_Exit

DocMed_ClearPlaying:
	ld (0x84FE), 0x0
	jrl DocMed_Exit

DocMed_HandleError:
	call LABEL_F2076D
	ld (0x84FE), 0x0
	cp L, 0
	jrl Z, DocMed_Exit
	ld (0x7F42), 0x1
	ld WA, 0xee

DocMed_ShowError:
	call LABEL_F994BD
	jrl DocMed_Exit

DocMed_CheckInit:
	cpw (0x8508), 0x0
	jr LT, DocMed_InitFromDisk
	cpw (0x8504), 0x0
	jr NZ, DocMed_InitState

DocMed_InitFromDisk:
	ldw (0x8504), 0xffff
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call LABEL_F8A9D6
	ld (0x8508), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	call SignalProgressUpdate

DocMed_InitState:
	ld (0x84FE), 0x0
	ld (0x8922), 0x0
	ld (0x8920), 0x0
	ld BC, 0x80
	ld WA, (0x8508)
	cp WA, 0x80
	jr UGT, DocMed_ClampCount
	ld BC, WA

DocMed_ClampCount:
	ld (0x84FC), BC
	ld HL, 0
	cp BC, 0
	jr ULE, DocMed_FinishInit
	lda XWA, 0x88A0

DocMed_ClearSlotsLoop:
	ld BC, HL
	extz XBC
	add XBC, XWA
	ld (XBC), 0xff
	inc 1, HL
	cp HL, (0x84FC)
	jr C, DocMed_ClearSlotsLoop

DocMed_FinishInit:
	call LABEL_F20ACD
	ld XWA, 0
	ld (0x84F8), XWA
	jrl DocMed_Exit

DocMed_HandleStop:
	ld A, (0x8D36)
	cp A, 0x70
	jrl Z, DocMed_Exit
	cp A, 0x74
	jrl Z, DocMed_Exit
	call LABEL_F20B70
	call CancelOperationCleanup
	ld (0x84FE), 0x0
	jrl DocMed_Exit

DocMed_StoreWindowPtr:
	ld (0x84F4), XWA
	jrl DocMed_Exit

DocMed_RefreshDisplay:
	ld XWA, (0x84F4)
	CALR DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleNavToggle:
	cp XHL, 0xa
	jrl NZ, DocMed_HandleSelectToggle
	cp (0x84FE), 0x0
	jr NZ, DocMed_HandleSelectToggle
	ld HL, 0
	ld WA, BC
	cp BC, 0
	jr ULE, DocMed_CheckAllUnmarked
	lda XBC, 0x88A0

DocMed_FindUnmarkedLoop:
	ld DE, HL
	extz XDE
	add XDE, XBC
	cp (XDE), 0xff
	jr Z, DocMed_CheckAllUnmarked
	inc 1, HL
	cp HL, WA
	jr C, DocMed_FindUnmarkedLoop

DocMed_CheckAllUnmarked:
	cp HL, WA
	jr NC, DocMed_RemoveOrderLoop
	ld HL, 0
	cp WA, 0
	jr ULE, DocMed_RefreshAfterToggle
	lda XDE, 0x88A0

DocMed_AssignOrderLoop:
	ld BC, HL
	extz XBC
	add XBC, XDE
	ld A, (XBC)
	cp A, 0xff
	jr NZ, DocMed_NextAssign
	ld (XBC), (0x8920)
	inc 1, (0x8920)

DocMed_NextAssign:
	inc 1, HL
	cp HL, (0x84FC)
	jr C, DocMed_AssignOrderLoop
	jr DocMed_RefreshAfterToggle

DocMed_RemoveOrderLoop:
	ld HL, 0
	cp WA, 0
	jr ULE, DocMed_RefreshAfterToggle
	lda XDE, 0x88A0

DocMed_UnmarkLoop:
	ld BC, HL
	extz XBC
	add XBC, XDE
	ld A, (XBC)
	cp A, 0xfd
	jr UGT, DocMed_NextUnmark
	ld (XBC), 0xff
	dec 1, (0x8920)

DocMed_NextUnmark:
	inc 1, HL
	cp HL, (0x84FC)
	jr C, DocMed_UnmarkLoop

DocMed_RefreshAfterToggle:
	ld XWA, (0x84F4)
	ld BC, (0x84FC)
	jr DocMed_CallFormatSlots

DocMed_HandleSelectToggle:
	cp XHL, 0xb
	jr NZ, DocMed_HandleRepeat
	cp (0x84FE), 0x0
	jr NZ, DocMed_HandleRepeat
	ld XWA, XIZ
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmDocFileNameFunc
	lda XIX, 0x88A0
	extz XHL
	add XHL, XIX
	ld C, (XHL)
	cp C, 0xff
	jr NZ, DocMed_RemoveFromOrder
	ld (XHL), (0x8920)
	inc 1, (0x8920)
	jr DocMed_RefreshAfterSelect

DocMed_RemoveFromOrder:
	cp C, 0xfd
	jr UGT, DocMed_RefreshAfterSelect
	ld (XHL), 0xff
	ld A, (0x8920)
	dec 1, A
	ld (0x8920), A
	ld IZ, 0
	ld HL, 0
	extz WA
	cp WA, 0
	jr ULE, DocMed_RefreshAfterSelect
	ld IY, WA

DocMed_ReorderLoop:
	ld DE, HL
	extz XDE
	add XDE, XIX
	ld A, (XDE)
	cp A, 0xfd
	jr UGT, DocMed_NextReorder
	inc 1, IZ
	cp A, C
	jr ULE, DocMed_NextReorder
	dec 1, A
	ld (XDE), A

DocMed_NextReorder:
	inc 1, HL
	cp IZ, IY
	jr C, DocMed_ReorderLoop

DocMed_RefreshAfterSelect:
	ld XWA, (0x84F4)
	ld BC, (0x84FC)

DocMed_CallFormatSlots:
	CALR DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleRepeat:
	cp XHL, 0xc
	jr NZ, DocMed_HandlePlay
	cp XDE, 0x1c00017
	jr NZ, DocMed_SetRepeatOff
	ld (0x8924), 0x1
	jrl DocMed_Exit

DocMed_SetRepeatOff:
	ld (0x8924), 0x0
	jrl DocMed_Exit

DocMed_HandlePlay:
	cp XHL, 0xd
	jrl NZ, DocMed_Exit
	cp (0x84FE), 0x0
	jrl NZ, DocMed_Exit
	ld (0x8922), 0x0
	ld HL, 0
	ld WA, (0x84FC)
	cp WA, 0
	jr ULE, DocMed_CheckAutoPlay
	lda XBC, 0x88A0

DocMed_PlayFindLoop:
	ld DE, HL
	extz XDE
	add XDE, XBC
	cp (XDE), 0x0
	jr NZ, DocMed_PlayNextLoop
	ld (0x84FE), 0x1
	extz XHL
	ld XWA, XIZ
	ld XBC, 0x1e50002
	ld XDE, XHL
	CALR FmmDocFileNameFunc
	inc 1, (0x8922)
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x74
	call UI_PostModeChangeEvent
	jr DocMed_CheckAutoPlay

DocMed_PlayNextLoop:
	inc 1, HL
	cp HL, WA
	jr C, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	cp (0x84FE), 0x0
	jr NZ, DocMed_Exit
	ld XWA, XIZ
	ld XBC, 0x1e50003
	ld XDE, 0
	CALR FmmDocFileNameFunc
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x70
	jr DocMed_CallPauseMode

DocMed_StoreDelayFlag:
	ld (0x84F8), XWA
	jr DocMed_Exit

DocMed_CheckContinue:
	cp (0x84FE), 0x0
	jr Z, DocMed_Exit
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009a
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x74

DocMed_CallPauseMode:
	call UI_PostModeChangeEvent

DocMed_Exit:
	ld XHL, 0
	pop XIZ
	ret

SetSongSlotValue:
	cp WA, 0xa
	ret NC
	lda XHL, 0xAB000
	ld DE, WA
	sll DE, 11
	extz XDE
	add XHL, XDE
	add XHL, 0x1c
	ld (XHL), BC
	ld E, (0xFFE3)
	extz DE
	cp DE, WA
	ret NZ
	lda XHL, 0xF180
	add XHL, 0x1c
	ld (XHL), BC
	ret

GetSongSlotValue:
	ld HL, 0
	cp WA, 0xa
	ret NC
	lda XBC, 0xAB000
	sll WA, 11
	extz XWA
	add XBC, XWA
	add XBC, 0x1c
	ld HL, (XBC)
	ret

CheckSongSlotHasData:
	CALR GetSongSlotValue
	cp HL, 0
	scc NZ, HL
	ret

SongSlot_RawData:
	.byte 0x2E, 0xD9, 0x8E, 0x1E, 0xD5, 0xFF, 0xDE, 0xF3
	.byte 0xDB, 0x76, 0x4E, 0xE

FindFirstEmptySlot:
	push IZ
	ld IZ, 0

FindEmpty_Loop:
	ld WA, IZ
	CALR GetSongSlotValue
	cp HL, 0
	jr NZ, FindEmpty_Exit
	inc 1, IZ
	cp IZ, 0xa
	jr C, FindEmpty_Loop

FindEmpty_Exit:
	pop IZ
	ret

ClearAllSongSlots:
	push XIZ
	ld IZ, WA
	ld QIZ, 0

ClearSlots_Loop:
	ld WA, QIZ
	ld BC, IZ
	CALR SetSongSlotValue
	inc 1, QIZ
	cp QIZ, 0xa
	jr C, ClearSlots_Loop
	pop XIZ
	ret

ResetSlotsIfEmpty:
	CALR FindFirstEmptySlot
	ld WA, HL
	cp WA, 0
	ret Z
	CALR ClearAllSongSlots
	ret

CheckSlotIsSelected:
	push IZ
	ld IZ, WA
	CALR FindFirstEmptySlot
	cp HL, IZ
	scc Z, HL
	pop IZ
	ret

CheckAnySlotHasData:
	CALR FindFirstEmptySlot
	cp HL, 0
	scc NZ, HL
	ret

SetCurrentSlotIndex:
	ld (0x9480E), WA
	ret

GetCurrentSlotIndex:
	ld HL, (0x9480E)
	ret

CheckIsCurrentSlot:
	push IZ
	ld IZ, WA
	CALR GetCurrentSlotIndex
	cp HL, IZ
	scc Z, HL
	pop IZ
	ret

CheckSlotIndexValid:
	CALR GetCurrentSlotIndex
	cp HL, 0
	scc NZ, HL
	ret

InitializeCheap:
	lda XSP, XSP - 14

	RegObjTable 0x1600004, 0xFA44E2, 0xEA1186,	0xEA0F46, 0x165
	RegObjTable 0x160000c, 0xFA58FB, 0xEA11F2,	0xEA1188, 0x1c5
	RegObjTable 0x160000d, 0xFA5948, 0xEA1358,	0xEA11F4, 0x1e5
	RegObjTabl  0x1600002, 0xFA496C, 0x1d,		0xEA0A56, 0x125
	RegObjTabl  0x1600002, 0xFA496C, 0x1d,		0xEA0ACE, 0x425
	RegObjTabl  0x1600001, 0xFA48A9, 0xd,		0xEA135A, 0x105
	RegObjTabl  0x1600001, 0xFA48A9, 0xd,		0xEA1392, 0x405
	RegObjTabl  0x1600003, 0xFA4A18, 0x39,		0xEA7FCE, 0x145
	RegObjTabl  0x1600003, 0xFA4A18, 0x39,		0xEA80B6, 0x445
	RegObjTabl  0x1600010, 0xFA5995, 0x4a,		0xEA67B6, 0x60
	RegObjTabl  0x160000f, 0xFA62CB, 0x4a,		0xEA6FE2, 0x360
	RegObjTabl  0x1600010, 0xFA5995, 0x80,		0xEA68E2, 0x61
	RegObjTabl  0x160000f, 0xFA62CB, 0x80,		0xEA7228, 0x361
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6AE6, 0x62
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA75C6, 0x362
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6AEA, 0x63
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA75CC, 0x363
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6AEE, 0x64
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA75D2, 0x364
	RegObjTabl  0x1600010, 0xFA5995, 0x3,		0xEA6AF2, 0x65
	RegObjTabl  0x160000f, 0xFA62CB, 0x3,		0xEA75D8, 0x365
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6B02, 0x66
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA75FC, 0x366
	RegObjTabl  0x1600010, 0xFA5995, 0x47,		0xEA6B06, 0x67
	RegObjTabl  0x160000f, 0xFA62CB, 0x47,		0xEA7602, 0x367
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6C26, 0x6a
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA77E4, 0x36a
	RegObjTabl  0x1600010, 0xFA5995, 0x15,		0xEA6C2A, 0x6b
	RegObjTabl  0x160000f, 0xFA62CB, 0x15,		0xEA77EA, 0x36b
	RegObjTabl  0x1600010, 0xFA5995, 0x53,		0xEA6C82, 0x6c
	RegObjTabl  0x160000f, 0xFA62CB, 0x53,		0xEA7878, 0x36c
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6DD2, 0x6d
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA7ACA, 0x36d
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6DD6, 0x6e
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA7AD0, 0x36e
	RegObjTabl  0x1600010, 0xFA5995, 0x15,		0xEA6DDA, 0x77
	RegObjTabl  0x160000f, 0xFA62CB, 0x15,		0xEA7AD6, 0x377
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6E32, 0x79
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA7B8C, 0x379
	RegObjTabl  0x1600010, 0xFA5995, 0x5e,		0xEA6E36, 0x7b
	RegObjTabl  0x160000f, 0xFA62CB, 0x5e,		0xEA7B92, 0x37b
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6FB2, 0x7c
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA7E98, 0x37c
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6FB6, 0x7d
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA7E9E, 0x37d
	RegObjTabl  0x1600010, 0xFA5995, 0x8,		0xEA6FBA, 0x7e
	RegObjTabl  0x160000f, 0xFA62CB, 0x8,		0xEA7EA4, 0x37e
	RegObjTabl  0x1600010, 0xFA5995, 0x0,		0xEA6FDE, 0xbc
	RegObjTabl  0x160000f, 0xFA62CB, 0x0,		0xEA7EE2, 0x3bc

	RegMode 0x5, 0xea, 0x7ee8, 0x6, 0x1200000, 0x1a00060

	RegTitle 0x5, 0xea, 0x7ef0, 0x60, 0x1200000, 0x600000
	RegTitle 0x5, 0xea, 0x7efa, 0x61, 0x1450027, 0x610000
	RegTitle 0x5, 0xea, 0x7f02, 0x62, 0x1450036, 0x610069
	RegTitle 0x5, 0xea, 0x7f10, 0x63, 0x1450037, 0x60002b
	RegTitle 0x5, 0xea, 0x7f1a, 0x64, 0x1450029, 0x61004b
	RegTitle 0x5, 0xea, 0x7f26, 0x65, 0x1200000, 0x650000
	RegTitle 0x5, 0xea, 0x7f32, 0x66, 0x1200000, 0x600018
	RegTitle 0x5, 0xea, 0x7f3e, 0x67, 0x1450028, 0x670000
	RegTitle 0x5, 0xea, 0x7f46, 0x6a, 0x1200000, 0x600028
	RegTitle 0x5, 0xea, 0x7f56, 0x6b, 0x145002d, 0x6b0000
	RegTitle 0x5, 0xea, 0x7f62, 0x6c, 0x145001c, 0x6c0000
	RegTitle 0x5, 0xea, 0x7f6e, 0x6d, 0x145001e, 0x6c0026
	RegTitle 0x5, 0xea, 0x7f7a, 0x6e, 0x145001d, 0x6c003d
	RegTitle 0x5, 0xea, 0x7f84, 0x77, 0x1450026, 0x770000
	RegTitle 0x5, 0xea, 0x7f8e, 0x79, 0x1450011, 0x60000a
	RegTitle 0x5, 0xea, 0x7f98, 0x7b, 0x1450031, 0x7b0000
	RegTitle 0x5, 0xea, 0x7fa0, 0x7c, 0x1450032, 0x7b0019
	RegTitle 0x5, 0xea, 0x7fac, 0x7d, 0x1450021, 0x7b0018
	RegTitle 0x5, 0xea, 0x7fb8, 0x7e, 0x1200000, 0x7e0000
	RegTitle 0x5, 0xea, 0x7fc4, 0xbc, 0x1450025, 0x60001b

	lda XSP, XSP + 14
	ret

PasswordText:
	cp XBC, 0x1e0009f
	jr NZ, PasswordText_Exit
	lda XHL, 0xEA85C8
	ret

PasswordText_Exit:
	ld XHL, 0
	ret

CheckPasswordText:
	cp XBC, 0x1e0009f
	jr NZ, CheckPwd_Exit
	ld A, (0x2748E)
	cp A, 2
	jr Z, CheckPwd_Type2
	cp A, 1
	jr NZ, CheckPwd_Type0
	ld XHL, 0xea8832
	jr CheckPwd_Return

CheckPwd_Type2:
	ld XHL, 0xea8a0c
	jr CheckPwd_Return

CheckPwd_Type0:
	ld XHL, 0xea868e

CheckPwd_Return:
	ret

CheckPwd_Exit:
	ld XHL, 0
	ret

WakeUpPassword:
	dec 4, XSP
	push XIZ
	ld (XSP + 0x4), XDE
	ld XIZ, XWA
	cp XBC, 0x1c50004
	jrl Z, WakeUp_StoreType
	cp XBC, 0x1c00007
	jr Z, WakeUp_HandleOk
	cp XBC, 0x1c00001
	jr Z, WakeUp_HandleInit
	cp XBC, 0x1c0000d
	jr Z, WakeUp_HandleDirect
	cp XBC, 0x1e00085
	jr Z, WakeUp_Return1
	ld XWA, XIZ
	ld XDE, (XSP + 0x4)
	call InheritedProc
	jrl WakeUp_Exit

WakeUp_Return1:
	ld XHL, 1
	jrl WakeUp_Exit

WakeUp_HandleDirect:
	ld XWA, XIZ
	ld XDE, (XSP + 0x4)
	call InheritedProc
	ld XWA, XIZ
	ld XBC, 0x1c0000f
	ld XDE, 0xea8bf0
	call SendEvent
	jrl WakeUp_ReturnZero

WakeUp_HandleInit:
	ld XWA, XIZ
	ld XDE, (XSP + 0x4)
	call InheritedProc
	ld (0x2741A), 0x0
	jrl WakeUp_ReturnZero

WakeUp_HandleOk:
	ld XWA, XIZ
	ld XDE, (XSP + 0x4)
	call InheritedProc
	ld XWA, 0x670001
	ld XBC, 0x1e00056
	ld XDE, 0
	call SendEvent
	cp XHL, 0x3
	jr Z, WakeUp_ReturnZero
	ld XWA, (XSP + 0x4)
	cp XWA, 0x8c
	jr NZ, WakeUp_ClearCounter
	inc 1, (0x2741A)
	cp (0x2741A), 0x7
	jr NZ, WakeUp_ReturnZero
	ld (0x2741A), 0x0
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call PostEvent
	ld XWA, 0x600040
	ld XBC, 0x1c00001
	ld XDE, 0
	jr WakeUp_PostEvent

WakeUp_ClearCounter:
	ld (0x2741A), 0x0
	jr WakeUp_ReturnZero

WakeUp_StoreType:
	ld XWA, (XSP + 0x4)
	ld (0x2748E), A
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call PostEvent
	ld XWA, 0x600045
	ld XBC, 0x1c00001
	ld XDE, 0

WakeUp_PostEvent:
	call PostEvent

WakeUp_ReturnZero:
	ld XHL, 0

WakeUp_Exit:
	pop XIZ
	inc 4, XSP
	ret

PasswordOk:
	push XIZ
	ld XIZ, XWA
	cp XBC, 0x1c00007
	jr Z, PwdOk_HandleConfirm
	cp XBC, 0x1e0007c
	jr Z, PwdOk_Return2
	cp XBC, 0x1e00084
	jr Z, PwdOk_ReturnZero
	cp XBC, 0x1e0003a
	jr NZ, PwdOk_ReturnZero
	pushw 0xea
	pushw 0x8bf6
	push XDE
	call LABEL_FF0F4D
	inc 8, XSP
	ld XHL, XIZ
	jr PwdOk_Exit

PwdOk_Return2:
	ld XHL, 2
	jr PwdOk_Exit

PwdOk_HandleConfirm:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x2741c
	call SendEvent
	ld XWA, 0x600040
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent
	ld DE, (0x2741C)
	extz XDE
	ld XWA, 0x1450038
	ld XBC, 0x1e5000d
	call MainFuncCall

PwdOk_ReturnZero:
	ld XHL, 0

PwdOk_Exit:
	pop XIZ
	ret

CheckPasswordOk:
	push XIZ
	ld XIZ, XWA
	cp XBC, 0x1c00007
	jr Z, CheckOk_HandleConfirm
	cp XBC, 0x1e0007c
	jr Z, CheckOk_Return2
	cp XBC, 0x1e00084
	jrl Z, CheckOk_ReturnZero
	cp XBC, 0x1e0003a
	jrl NZ, CheckOk_ReturnZero
	pushw 0xea
	pushw 0x8bfa
	push XDE
	call LABEL_FF0F4D
	inc 8, XSP
	ld XHL, XIZ
	jrl CheckOk_Exit

CheckOk_Return2:
	ld XHL, 2
	jrl CheckOk_Exit

CheckOk_HandleConfirm:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x27424
	call SendEvent
	ld XWA, 0x600045
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent
	ld XWA, 0x670001
	ld XBC, 0x1e00056
	ld XDE, 0
	call SendEvent
	lda XWA, 0x27424
	cp HL, 1
	jr NZ, CheckOk_Type2
	ld DE, (XWA)
	extz XDE
	ld XWA, 0x1450038
	ld XBC, 0x1e5000e
	jr CheckOk_CallFunc

CheckOk_Type2:
	cp HL, 2
	jr NZ, CheckOk_Type3
	ld DE, (XWA)
	extz XDE
	ld XWA, 0x1450038
	ld XBC, 0x1e5000f
	jr CheckOk_CallFunc

CheckOk_Type3:
	cp HL, 3
	jr NZ, CheckOk_ReturnZero
	ld DE, (XWA)
	extz XDE
	ld XWA, 0x1450038
	ld XBC, 0x1e50010

CheckOk_CallFunc:
	call MainFuncCall

CheckOk_ReturnZero:
	ld XHL, 0

CheckOk_Exit:
	pop XIZ
	ret

PasswordNo:
	cp XBC, 0x1c00007
	jr NZ, PwdNo_Exit
	ld XWA, 0x600040
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent

PwdNo_Exit:
	ld XHL, 0
	ret

CheckPasswordNo:
	cp XBC, 0x1c00007
	jr NZ, CheckNo_HandleConfirm
	ld XWA, 0x600045
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent

CheckNo_HandleConfirm:
	ld XHL, 0
	ret

DiskAttention:
	cp XBC, 0x1e0009f
	jr NZ, CheckNo_Type1
	lda XHL, 0xEA8BFE
	ret

CheckNo_Type1:
	ld XHL, 0
	ret

DiskSure:
	cp XBC, 0x1e0009f
	jr NZ, CheckNo_Type2
	lda XHL, 0xEA8C5C
	ret

CheckNo_Type2:
	ld XHL, 0
	ret

FormatText:
	cp XBC, 0x1e0009f
	jr NZ, CheckNo_Type3
	lda XHL, 0xEA8CDC
	ret

CheckNo_Type3:
	ld XHL, 0
	ret

DeleteText:
	cp XBC, 0x1e0009f
	jr NZ, CheckNo_CallFunc
	lda XHL, 0xEA8E70
	ret

CheckNo_CallFunc:
	ld XHL, 0
	ret

DeleteYes:
	cp XBC, 0x1c00007
	jr NZ, PwdChange_HandleOk
	ld XWA, 0x7b0051
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c00017
	ld XDE, 0x33
	call PostEvent

PwdChange_HandleOk:
	ld XHL, 0
	ret

DeleteNo:
	cp XBC, 0x1c00007
	jr NZ, PwdChange_Type1
	ld XWA, 0x7b0051
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent

PwdChange_Type1:
	ld XHL, 0
	ret

SaveText:
	cp XBC, 0x1e0009f
	jr NZ, PwdChange_CallFunc
	lda XHL, 0xEA912A
	ret

PwdChange_CallFunc:
	ld XHL, 0
	ret

SaveYes:
	cp XBC, 0x1c00007
	jr NZ, PwdDel_HandleOk
	ld XWA, 0x600037
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c00017
	ld XDE, 0x32
	call PostEvent

PwdDel_HandleOk:
	ld XHL, 0
	ret

SaveNo:
	cp XBC, 0x1c00007
	jr NZ, PwdDel_Type1
	ld XWA, 0x600037
	ld XBC, 0x1c00002
	ld XDE, 0
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 0
	call PostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call PostEvent

PwdDel_Type1:
	ld XHL, 0
	ret

InsertOptionText:
	cp XBC, 0x1e0009f
	jr NZ, PwdDel_Type2
	lda XHL, 0xEA943C
	ret

PwdDel_Type2:
	ld XHL, 0
	ret

TypePriorityText:
	cp XBC, 0x1e0009f
	jr NZ, PwdDel_CallFunc
	lda XHL, 0xEA9558
	ret

PwdDel_CallFunc:
	ld XHL, 0
	ret

