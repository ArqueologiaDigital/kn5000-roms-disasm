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
	PUSH IZ
	CP XBC, 01e50003h
	JRL Z, SeqName_GetIndexReturn
	LD HL, (82D8h)
	CP XBC, 01e50002h
	JRL Z, SeqName_SetIndexPlaying
	CP XBC, 01c00018h
	JR Z, SeqName_HandleNavigation
	CP XBC, 01c00017h
	JR Z, SeqName_HandleNavigation
	CP XBC, 01c0000bh
	JR Z, SeqName_InitAllSlots
	CP XBC, 01e50004h
	JR NZ, SeqName_ReturnZero
	LD (82D4h), XDE
	CP (84FEh), 000h
	JR NZ, SeqName_SendCurrentIndex
	LDW (82D8h), 0000h

SeqName_SendCurrentIndex:
	LD DE, (82D8h)
	EXTZ XDE
	LD XWA, (82D4h)
	LD XBC, 01e50002h
	JRL T, SeqName_PostEventExit

SeqName_InitAllSlots:
	LD IZ, 0

SeqName_SendSlotLoop:
	LD BC, IZ
	LD WA, BC
	LD DE, 1
	CALR LABEL_F919E3
	LD XDE, XHL
	LD XWA, (82D4h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR LT, SeqName_SendSlotLoop

SeqName_ReturnZero:
	LD XHL, 0
	JRL T, SeqName_Exit

SeqName_HandleNavigation:
	LD WA, HL
	LD IZ, HL
	OR XDE, XDE
	JR NZ, SeqName_HandlePlayAction
	CP (84FEh), 000h
	JR NZ, SeqName_HandlePlayAction
	CP XBC, 01c00018h
	JR NZ, SeqName_CheckPrevKey
	CP WA, 0009h
	JRL NC, SeqName_GetCurrentIndex
	INC 1, WA
	JR T, SeqName_UpdateIndex

SeqName_CheckPrevKey:
	CP XBC, 01c00017h
	JRL NZ, SeqName_GetCurrentIndex
	CP WA, 0
	JRL Z, SeqName_GetCurrentIndex
	DEC 1, WA

SeqName_UpdateIndex:
	LD (82D8h), WA
	LD DE, WA
	JRL T, SeqName_UpdateDisplay

SeqName_HandlePlayAction:
	CP XDE, 00000004h
	JRL NZ, SeqName_HandleAction32
	CP (84FEh), 000h
	JRL NZ, SeqName_HandleAction32
	CALL CheckSongSlotHasData
	CP L, 0
	JR Z, SeqName_CheckDiskAvail
	LDA XWA, 8A0Ch
	BIT 7, (XWA + 001h)
	JR NZ, SeqName_CheckDiskAvail
	LD (XWA), 001h
	LD XDE, 1
	LD XWA, 0ffffffffh
	LD XBC, 01c50004h
	JR T, SeqName_PostAndExit

SeqName_CheckDiskAvail:
	CALL CheckFileSystemStatus
	CP HL, 0
	JR Z, SeqName_LoadAndPlay
	CP (0340EAh), 000h
	JR Z, SeqName_LoadAndPlay
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 1
	CALL ApPostEvent
	LD XWA, 00600037h
	LD XBC, 01c00001h
	LD XDE, 0

SeqName_PostAndExit:
	CALL ApPostEvent
	JRL T, SeqName_GetCurrentIndex

SeqName_LoadAndPlay:
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR InitializeOperationState
	LD WA, (82D8h)
	CALL LABEL_F880AD
	LD WA, HL
	LD BC, 5
	CALR LABEL_F8B48E
	LD (7F42h), L
	CALL LABEL_F89568
	CALL GetEncodedFreeSpaceData
	CALL GetEncodedFileSizeData
	LD (8502h), HL
	CALR SignalProgressUpdate
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00eeh
	JR T, SeqName_ShowAndExit

SeqName_HandleAction32:
	CP XDE, 00000032h
	JR NZ, SeqName_GetCurrentIndex
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR InitializeOperationState
	LD WA, (82D8h)
	CALL LABEL_F880AD
	LD WA, HL
	LD BC, 5
	CALR LABEL_F8B48E
	LD (7F42h), L
	CALL LABEL_F89568
	CALL GetEncodedFreeSpaceData
	CALL GetEncodedFileSizeData
	LD (8502h), HL
	CALR SignalProgressUpdate
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00eeh

SeqName_ShowAndExit:
	CALL LABEL_F994BD

SeqName_GetCurrentIndex:
	LD DE, (82D8h)

SeqName_UpdateDisplay:
	CP IZ, DE
	JRL Z, SeqName_ReturnZero
	EXTZ XDE
	LD XWA, (82D4h)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD WA, IZ
	LD BC, IZ
	LD DE, 1
	CALR LABEL_F919E3
	LD XDE, XHL
	LD XWA, (82D4h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LD BC, (82D8h)
	LD WA, BC
	LD DE, 1
	CALR LABEL_F919E3
	LD XDE, XHL
	LD XWA, (82D4h)
	LD XBC, 01c0000fh
	JR T, SeqName_PostEventExit

SeqName_SetIndexPlaying:
	CP (84FEh), 000h
	JRL Z, SeqName_ReturnZero
	LD IZ, HL
	LD (82D8h), DE
	EXTZ XDE
	LD XWA, (82D4h)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD WA, IZ
	LD BC, IZ
	LD DE, 1
	CALR LABEL_F919E3
	LD XDE, XHL
	LD XWA, (82D4h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LD BC, (82D8h)
	LD WA, BC
	LD DE, 1
	CALR LABEL_F919E3
	LD XDE, XHL
	LD XWA, (82D4h)
	LD XBC, 01c0000fh

SeqName_PostEventExit:
	CALL ApPostEvent
	JRL T, SeqName_ReturnZero

SeqName_GetIndexReturn:
	LD HL, (82D8h)
	EXTZ XHL

SeqName_Exit:
	POP IZ
	RET

FormatMedleyNumber:
	LD (XWA+), E
	CP C, 0ffh
	JR NZ, FmtNum_CheckMarked
	LD_C 020h
	JR T, FmtNum_WriteSpacePad

FmtNum_CheckMarked:
	CP C, 0feh
	JR NZ, FmtNum_FormatNumber
	LD_C 04dh

FmtNum_WriteSpacePad:
	LD (XWA+), C
	LD (XWA+), 020h
	LD (XWA), 020h
	RET

FmtNum_FormatNumber:
	INC 1, C
	CP C, 064h
	JR C, FmtNum_WriteM
	LDA_XHL_XWA_plus__e0__
	LD E, C
	EXTZ DE
	DIV_E 064h
	ADD E, 030h
	LD (XHL), E
	EXTZ BC
	DIV_C 064h
	LD C, B
	JR T, FmtNum_WriteTensUnits

FmtNum_WriteM:
	LD (XWA+), 04dh

FmtNum_WriteTensUnits:
	CP C, 00ah
	JR NC, FmtNum_WriteTwoDigits
	LD (XWA+), 030h
	ADD C, 030h
	LD (XWA), C
	RET

FmtNum_WriteTwoDigits:
	LDA_XHL_XWA_plus__e0__
	LD E, C
	EXTZ DE
	DIV_E 00ah
	ADD E, 030h
	LD (XHL), E
	EXTZ BC
	DIV_C 00ah
	LD C, B
	ADD C, 030h
	LD (XWA), C
	RET

FmmIntMedleyFunc:
	DEC 8, XSP
	PUSH IZ
	LD (XSP + 006h), XWA
	CP XBC, 01e5000ah
	JRL Z, IntMed_CheckContinue
	LD XWA, XDE
	CP XBC, 01e50008h
	JRL Z, IntMed_StoreDelayFlag
	CP XBC, 01c00018h
	JRL Z, IntMed_HandleNavToggle
	CP XBC, 01c00017h
	JRL Z, IntMed_HandleNavToggle
	CP XBC, 01c0000bh
	JRL Z, IntMed_InitSlotDisplay
	CP XBC, 01e50004h
	JRL Z, IntMed_StoreWindowPtr
	CP XBC, 01c00013h
	JRL NZ, IntMed_Exit
	CP XDE, 00000003h
	JRL Z, IntMed_HandleStop
	CP XDE, 00000002h
	JRL NZ, IntMed_Exit
	CP (8D37h), 07ah
	JR Z, IntMed_CheckPlaying
	CALL LABEL_F20ACD
	LD (84FEh), 000h
	LD (889Ch), 000h
	LD (889Ah), 000h
	LD IZ, 0

IntMed_CheckSlotLoop:
	LD A, IZL
	EXTZ WA
	CALL LABEL_F2065A
	CP L, 0
	JR Z, IntMed_MarkSlotEmpty
	LDA XWA, 8890h
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	LD (XBC), (889Ah)
	INC 1, (889Ah)
	JR T, IntMed_NextSlot

IntMed_MarkSlotEmpty:
	LDA XWA, 8890h
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	LD (XBC), 0ffh

IntMed_NextSlot:
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_CheckSlotLoop
	LD XWA, 0
	LD (82DEh), XWA
	JRL T, IntMed_Exit

IntMed_CheckPlaying:
	CALL LABEL_F2076D
	CP L, 1
	JRL NZ, IntMed_HandleError
	LD (84FEh), 001h
	LD A, (889Ch)
	CP A, (889Ah)
	JR NC, IntMed_CheckRepeat
	LD IZ, 0
	LDA XBC, 8890h

IntMed_FindCurrentSong:
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), A
	JR NZ, IntMed_NextSongSearch
	LD DE, IZ
	EXTZ XDE
	LD XWA, (XSP + 006h)
	LD XBC, 01e50002h
	CALR FmmSeqSongNameFunc
	LD A, IZL
	EXTZ WA
	CALL LABEL_F20BCE
	INC 1, (889Ch)
	LD XWA, (82DEh)
	OR XWA, XWA
	JRL Z, IntMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh
	JR T, IntMed_PostDelayEvent

IntMed_NextSongSearch:
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_FindCurrentSong
	JRL T, IntMed_Exit

IntMed_CheckRepeat:
	CP (889Eh), 000h
	JR Z, IntMed_ClearPlayFlag
	LD (889Ch), 000h
	LD IZ, 0
	LDA XWA, 8890h

IntMed_PlayFromStart:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	CP (XBC), 000h
	JR NZ, IntMed_NextSongLoop
	LD DE, IZ
	EXTZ XDE
	LD XWA, (XSP + 006h)
	LD XBC, 01e50002h
	CALR FmmSeqSongNameFunc
	LD A, IZL
	EXTZ WA
	CALL LABEL_F20BCE
	INC 1, (889Ch)
	LD XWA, (82DEh)
	OR XWA, XWA
	JRL Z, IntMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh

IntMed_PostDelayEvent:
	CALL ApPostEvent
	JRL T, IntMed_Exit

IntMed_NextSongLoop:
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_PlayFromStart
	JRL T, IntMed_Exit

IntMed_ClearPlayFlag:
	LD (84FEh), 000h
	JRL T, IntMed_Exit

IntMed_HandleError:
	CALL LABEL_F2076D
	LD (84FEh), 000h
	CP L, 0
	JRL Z, IntMed_Exit
	LD (7F42h), 00eh
	LD WA, 00eeh
	CALL LABEL_F994BD
	JRL T, IntMed_Exit

IntMed_HandleStop:
	CP (8D36h), 07ah
	JRL Z, IntMed_Exit
	CALL LABEL_F20B70
	LD (84FEh), 000h
	JRL T, IntMed_Exit

IntMed_StoreWindowPtr:
	LD (82DAh), XWA
	JRL T, IntMed_Exit

IntMed_InitSlotDisplay:
	LD IZ, 0

IntMed_FormatSlotLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 82E2h
	EXTZ XWA
	ADD XWA, XBC
	LDA XBC, 8890h
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XBC
	LD C, (XDE)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 82E2h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (82DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_FormatSlotLoop
	JRL T, IntMed_Exit

IntMed_HandleNavToggle:
	LDA XWA, 8890h
	CP XDE, 0000000ah
	JRL NZ, IntMed_HandleSelectToggle
	CP (84FEh), 000h
	JRL NZ, IntMed_HandleSelectToggle
	LD IZ, 0

IntMed_FindMarkedSlot:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	CP (XBC), 0feh
	JR Z, IntMed_CheckAllMarked
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_FindMarkedSlot

IntMed_CheckAllMarked:
	CP IZ, 000ah
	JR NC, IntMed_RemoveOrderLoop
	LD IZ, 0

IntMed_AssignOrderLoop:
	LDA XWA, 8890h
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	LD A, (XBC)
	CP A, 0feh
	JR NZ, IntMed_NextAssignSlot
	LD A, (889Ah)
	LD (XBC), A
	INC 1, (889Ah)
	LD WA, IZ
	SLL 3, WA
	LDA XDE, 82E2h
	EXTZ XWA
	ADD XWA, XDE
	LD C, (XBC)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 82E2h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (82DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent

IntMed_NextAssignSlot:
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_AssignOrderLoop
	JRL T, IntMed_Exit

IntMed_RemoveOrderLoop:
	LD IZ, 0

IntMed_UnmarkSlotLoop:
	LDA XWA, 8890h
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	LD A, (XBC)
	CP A, 0fdh
	JR UGT, IntMed_NextUnmark
	LD (XBC), 0feh
	DEC 1, (889Ah)
	LD WA, IZ
	SLL 3, WA
	LDA XDE, 82E2h
	EXTZ XWA
	ADD XWA, XDE
	LD C, (XBC)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 82E2h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (82DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent

IntMed_NextUnmark:
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_UnmarkSlotLoop
	JRL T, IntMed_Exit

IntMed_HandleSelectToggle:
	CP XDE, 0000000bh
	JRL NZ, IntMed_HandleRepeatToggle
	CP (84FEh), 000h
	JRL NZ, IntMed_HandleRepeatToggle
	LD XWA, (XSP + 006h)
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmSeqSongNameFunc
	LD IZ, HL
	LDA XWA, 8890h
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XWA
	LDA XBC, 82E2h
	LD WA, IZ
	SLL 3, WA
	EXTZ XWA
	ADD XWA, XBC
	LD C, (XDE)
	CP C, 0feh
	JR NZ, IntMed_RemoveFromOrder
	LD C, (889Ah)
	LD (XDE), C
	INC 1, (889Ah)
	LD C, (XDE)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XBC, 82E2h
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (82DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	JRL T, IntMed_Exit

IntMed_RemoveFromOrder:
	CP C, 0fdh
	JRL UGT, IntMed_Exit
	LD (XSP + 004h), C
	LD (XDE), 0feh
	DEC 1, (889Ah)
	LD C, (XDE)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XBC, 82E2h
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (82DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LDW (XSP + 002h:8), 0000h
	LD IZ, 0
	LD A, (889Ah)
	EXTZ WA
	CP WA, 0
	JRL ULE, IntMed_Exit

IntMed_ReorderLoop:
	LDA XWA, 8890h
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XWA
	LD C, (XDE)
	CP C, 0fdh
	JR UGT, IntMed_NextReorder
	INCW 1, (XSP + 002h)
	CP C, (XSP + 004h)
	JR ULE, IntMed_NextReorder
	DEC 1, C
	LD (XDE), C
	LD WA, IZ
	SLL 3, WA
	LDA XDE, 82E2h
	EXTZ XWA
	ADD XWA, XDE
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 82E2h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (82DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent

IntMed_NextReorder:
	INC 1, IZ
	LD A, (889Ah)
	EXTZ WA
	CP (XSP + 002h), WA
	JR C, IntMed_ReorderLoop
	JRL T, IntMed_Exit

IntMed_HandleRepeatToggle:
	CP XDE, 0000000ch
	JR NZ, IntMed_HandlePlay
	CP XBC, 01c00017h
	JR NZ, IntMed_SetRepeatOff
	LD (889Eh), 001h
	JRL T, IntMed_Exit

IntMed_SetRepeatOff:
	LD (889Eh), 000h
	JRL T, IntMed_Exit

IntMed_HandlePlay:
	CP XDE, 0000000dh
	JRL NZ, IntMed_Exit
	CP (84FEh), 000h
	JR NZ, IntMed_Exit
	LD (889Ch), 000h
	LD IZ, 0

IntMed_StartPlayLoop:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	CP (XBC), 000h
	JR NZ, IntMed_NextPlaySlot
	LD (84FEh), 001h
	LD DE, IZ
	EXTZ XDE
	LD XWA, (XSP + 006h)
	LD XBC, 01e50002h
	CALR FmmSeqSongNameFunc
	LD A, IZL
	EXTZ WA
	CALL LABEL_F20BCE
	INC 1, (889Ch)
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 007ah
	CALL LABEL_F99490
	JR T, IntMed_Exit

IntMed_NextPlaySlot:
	INC 1, IZ
	CP IZ, 000ah
	JR C, IntMed_StartPlayLoop
	JR T, IntMed_Exit

IntMed_StoreDelayFlag:
	LD (82DEh), XWA
	JR T, IntMed_Exit

IntMed_CheckContinue:
	CP (84FEh), 000h
	JR Z, IntMed_Exit
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 007ah
	CALL LABEL_F99490

IntMed_Exit:
	LD XHL, 0
	POP IZ
	INC 8, XSP
	RET

FmmDiskMedley1Func:
	PUSH IZ
	CP XBC, 01c0000bh
	JR Z, DiskMed1_InitLoop
	CP XBC, 01e50004h
	JR NZ, DiskMed1_Exit
	LD (8332h), XDE
	JR T, DiskMed1_Exit

DiskMed1_InitLoop:
	LD IZ, 0

DiskMed1_FormatLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 8336h
	EXTZ XWA
	ADD XWA, XBC
	LDA XBC, 8926h
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XBC
	LD C, (XDE)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 8336h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (8332h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR C, DiskMed1_FormatLoop

DiskMed1_Exit:
	LD XHL, 0
	POP IZ
	RET

FmmDiskMedley2Func:
	PUSH IZ
	CP XBC, 01c0000bh
	JR Z, DiskMed2_InitLoop
	CP XBC, 01e50004h
	JR NZ, DiskMed2_Exit
	LD (8386h), XDE
	JR T, DiskMed2_Exit

DiskMed2_InitLoop:
	LD IZ, 000ah

DiskMed2_FormatLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 00833Ah:24
	EXTZ XWA
	ADD XWA, XBC
	LDA XBC, 8926h
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XBC
	LD C, (XDE)
	EXTZ BC
	LD DE, IZ
	SUB DE, 000ah
	CALR FormatMedleyNumber
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 00833Ah:24
	LD DE, WA
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (8386h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 0014h
	JR C, DiskMed2_FormatLoop

DiskMed2_Exit:
	LD XHL, 0
	POP IZ
	RET

DiskMed_PlayNextHelper:
	PUSH IZ
	CP XBC, 01c00018h
	JR Z, DiskMed_InitPlayOrder
	CP XBC, 01c00017h
	JR Z, DiskMed_InitPlayOrder
	CP XBC, 01c00013h
	JRL NZ, DiskMed_ReturnZero
	CP XDE, 00000003h
	JRL Z, DiskMed_ReturnZero
	CP XDE, 00000002h
	JRL NZ, DiskMed_ReturnZero
	CP (84FEh), 000h
	JRL Z, DiskMed_ReturnZero
	LD A, (889Ch)
	CP A, (889Ah)
	JR NC, DiskMed_ReturnFinished
	LD IZ, 0
	LDA XBC, 8890h

DiskMed_FindSongLoop:
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), A
	JR NZ, DiskMed_NextSong
	LD A, IZL
	EXTZ WA
	JRL T, DiskMed_PlaySong

DiskMed_NextSong:
	INC 1, IZ
	CP IZ, 000ah
	JR C, DiskMed_FindSongLoop
	JRL T, DiskMed_ReturnZero

DiskMed_ReturnFinished:
	LD XHL, 2
	JRL T, DiskMed_HelperExit

DiskMed_InitPlayOrder:
	CP XDE, 0000000dh
	JRL NZ, DiskMed_ReturnZero
	LD (889Ch), 000h
	LD (889Ah), 000h
	LD (889Eh), 000h
	LD IZ, 0

DiskMed_CheckSlotLoop:
	LD A, IZL
	EXTZ WA
	CALL LABEL_F2065A
	LDA XBC, 8890h
	LD WA, IZ
	EXTZ XWA
	ADD XWA, XBC
	CP L, 0
	JR Z, DiskMed_MarkUnused
	LD (XWA), 0feh
	JR T, DiskMed_NextSlotCheck

DiskMed_MarkUnused:
	LD (XWA), 0ffh

DiskMed_NextSlotCheck:
	INC 1, IZ
	CP IZ, 000ah
	JR C, DiskMed_CheckSlotLoop
	CP (8940h), 000h
	JR Z, DiskMed_SingleSlotCheck
	LDA XHL, 8890h
	LD XBC, XHL
	LDA XDE, XHL + 00ah

DiskMed_AssignOrder:
	LD A, (XBC)
	CP A, 0feh
	JR NZ, DiskMed_NextAssign
	LD (XBC), (889Ah)
	INC 1, (889Ah)

DiskMed_NextAssign:
	INC 1, XBC
	CP XBC, XDE
	JR C, DiskMed_AssignOrder
	LD IZ, 0

DiskMed_FindFirstSong:
	LD WA, IZ
	EXTZ XWA
	ADD XWA, XHL
	LD A, (XWA)
	CP A, (889Ch)
	JR NZ, DiskMed_NextFirst
	LD A, IZL
	EXTZ WA
	JR T, DiskMed_PlaySong

DiskMed_NextFirst:
	INC 1, IZ
	CP IZ, 000ah
	JR C, DiskMed_FindFirstSong
	JR T, DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	LDA XBC, 8890h
	CP (XBC), 0feh
	JR NZ, DiskMed_SingleSlotInit
	LD (XBC), (889Ah)
	INC 1, (889Ah)

DiskMed_SingleSlotInit:
	LD IZ, 0

DiskMed_FindFirstLoop:
	LD WA, IZ
	EXTZ XWA
	ADD XWA, XBC
	LD A, (XWA)
	CP A, (889Ch)
	JR NZ, DiskMed_NextFindFirst
	LD A, IZL
	EXTZ WA

DiskMed_PlaySong:
	CALL LABEL_F20BCE
	INC 1, (889Ch)
	LD XHL, 1
	JR T, DiskMed_HelperExit

DiskMed_NextFindFirst:
	INC 1, IZ
	CP IZ, 000ah
	JR C, DiskMed_FindFirstLoop

DiskMed_ReturnZero:
	LD XHL, 0

DiskMed_HelperExit:
	POP IZ
	RET

FmmDiskMedleySelectFunc:
	LDA XSP, XSP - 14
	PUSH XIZ
	LD (XSP + 006h), XDE
	LD (XSP + 00ah), XBC
	LD (XSP + 00eh), XWA
	LD XWA, (XSP + 00ah)
	CP XWA, 01c00018h
	JRL Z, DiskSel_HandleNavigation
	CP XWA, 01c00017h
	JRL Z, DiskSel_HandleNavigation
	CP XWA, 01c0000bh
	JRL Z, DiskSel_InitDisplay
	CP XWA, 01e50004h
	JRL Z, DiskSel_StoreWindowPtr
	CP XWA, 01c00013h
	JRL NZ, DiskSel_Exit
	LD XWA, (XSP + 006h)
	CP XWA, 00000003h
	JRL Z, DiskSel_HandleStopEvent
	CP XWA, 00000002h
	JRL NZ, DiskSel_Exit
	LD WA, 0
	CALR InitializeOperationState
	CP (8D37h), 078h
	JRL Z, DiskSel_CheckPlaying
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CPW (8502h), 0000h
	JR GE, DiskSel_InitState
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CALL GetEncodedFileSizeData
	LD (8502h), HL
	CALL LABEL_F8958D
	CALL GetEncodedFreeSpaceData
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CALR SignalProgressUpdate

DiskSel_InitState:
	LD (84FEh), 000h
	LD (893Ch), 000h
	LD (893Ah), 000h
	LD IZ, 0

DiskSel_CheckFileLoop:
	LD WA, IZ
	LD BC, 2
	CALL LABEL_F89408
	CP L, 0
	JR NZ, DiskSel_FileAvailable
	LD WA, IZ
	LD BC, 0008h
	CALL LABEL_F89408
	CP L, 0
	JR Z, DiskSel_MarkUnavail

DiskSel_FileAvailable:
	LDA XWA, 8926h
	LD (XWA + IZ), (893Ah)
	INC 1, (893Ah)
	JR T, DiskSel_NextFile

DiskSel_MarkUnavail:
	LDA XWA, 8926h
	LD (XWA + IZ), 0ffh

DiskSel_NextFile:
	INC 1, IZ
	CP IZ, 0014h
	JR LT, DiskSel_CheckFileLoop
	CALL LABEL_F20ACD
	JRL T, DiskSel_Exit

DiskSel_CheckPlaying:
	CALL LABEL_F2076D
	CP L, 1
	JRL NZ, DiskSel_HandleError
	LD (84FEh), 001h
	LD XWA, (XSP + 00eh)
	LD XBC, (XSP + 00ah)
	LD XDE, (XSP + 006h)
	CALR DiskMed_PlayNextHelper
	CP L, 1
	JR NZ, DiskSel_CheckFinished
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0078h
	JRL T, DiskSel_CallPauseMode

DiskSel_CheckFinished:
	CP L, 2
	JRL NZ, DiskSel_Exit
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	LD A, (893Ch)
	CP A, (893Ah)
	JRL NC, DiskSel_CheckRepeat
	LD IZ, 0

DiskSel_ClearSelections:
	LD A, IZL
	EXTZ WA
	CALL LABEL_F89321
	INC 1, IZ
	CP IZ, 0008h
	JR LT, DiskSel_ClearSelections
	LD IZ, 0

DiskSel_FindSongLoop:
	LDA XWA, 8926h
	LD A, (XWA + IZ)
	CP A, (893Ch)
	JRL NZ, DiskSel_NextSongLoop
	LD (83DEh), IZ
	LD WA, IZ
	CALL NotifyUIOfSelectionChange
	LD DE, (83DEh)
	EXTS XDE
	LD XWA, (83DAh)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD QIZ, 0

DiskSel_SendFileInfo:
	LD DE, QIZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (83DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, QIZ
	CP QIZ, 0014h
	JR LT, DiskSel_SendFileInfo
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDiskMedley1Func
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDiskMedley2Func
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 00770008h
	CALR DiskNameFunc
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 00770009h
	CALR DiskInfoFunc
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR InitializeOperationState
	CALL LABEL_F87A08
	LD QIZ, HL
	CALR SignalProgressUpdate
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CP QIZ, 0
	JR GE, DiskSel_PlayNext
	LD (84FEh), 000h
	LD WA, 0060h
	CALL LABEL_F99490
	LD WA, QIZ
	LD BC, 1
	CALR LABEL_F8B48E
	LD (7F42h), L
	LD WA, 00eeh
	JRL T, DiskSel_ShowErrorAndExit

DiskSel_PlayNext:
	INC 1, (893Ch)
	LD XWA, (XSP + 00eh)
	LD XBC, 01c00017h
	LD XDE, 0000000dh
	CALR DiskMed_PlayNextHelper
	CP L, 1
	JR NZ, DiskSel_NextSongLoop
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0078h
	CALL LABEL_F99490
	JR T, DiskSel_ClearPlaying

DiskSel_NextSongLoop:
	INC 1, IZ
	CP IZ, 0014h
	JRL LT, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	LD (84FEh), 000h
	JRL T, DiskSel_Exit

DiskSel_CheckRepeat:
	CP (893Eh), 000h
	JR Z, DiskSel_ClearPlaying
	LD (893Ch), 000h
	LD IZ, 0

DiskSel_RepeatClear:
	LD A, IZL
	EXTZ WA
	CALL LABEL_F89321
	INC 1, IZ
	CP IZ, 0008h
	JR LT, DiskSel_RepeatClear
	LD IZ, 0

DiskSel_RepeatFindLoop:
	LDA XWA, 8926h
	LD A, (XWA + IZ)
	CP A, (893Ch)
	JRL NZ, DiskSel_RepeatNext
	LD (83DEh), IZ
	LD WA, IZ
	CALL NotifyUIOfSelectionChange
	LD DE, (83DEh)
	EXTS XDE
	LD XWA, (83DAh)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD QIZ, 0

DiskSel_RepeatSendInfo:
	LD DE, QIZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (83DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, QIZ
	CP QIZ, 0014h
	JR LT, DiskSel_RepeatSendInfo
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDiskMedley1Func
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDiskMedley2Func
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 00770008h
	CALR DiskNameFunc
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 00770009h
	CALR DiskInfoFunc
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR InitializeOperationState
	CALL LABEL_F87A08
	LD QIZ, HL
	CALR SignalProgressUpdate
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CP QIZ, 0
	JR GE, DiskSel_RepeatPlayNext
	LD (84FEh), 000h
	LD WA, 0060h
	CALL LABEL_F99490
	LD WA, QIZ
	LD BC, 1
	CALR LABEL_F8B48E
	LD (7F42h), L
	LD WA, 00eeh
	JRL T, DiskSel_ShowErrorAndExit

DiskSel_RepeatPlayNext:
	INC 1, (893Ch)
	LD XWA, (XSP + 00eh)
	LD XBC, 01c00017h
	LD XDE, 0000000dh
	CALR DiskMed_PlayNextHelper
	CP L, 1
	JR NZ, DiskSel_RepeatNext
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0078h

DiskSel_CallPauseMode:
	CALL LABEL_F99490
	JRL T, DiskSel_Exit

DiskSel_RepeatNext:
	INC 1, IZ
	CP IZ, 0014h
	JRL LT, DiskSel_RepeatFindLoop
	JRL T, DiskSel_Exit

DiskSel_HandleError:
	CALL LABEL_F2076D
	LD (84FEh), 000h
	CP L, 0
	JR NZ, DiskSel_ShowError
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	JRL T, DiskSel_Exit

DiskSel_ShowError:
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 00eh
	LD WA, 00eeh
	JRL T, DiskSel_ShowErrorAndExit

DiskSel_HandleStopEvent:
	CP (8D36h), 078h
	JR Z, DiskSel_PostStopEvent
	CALL LABEL_F20B70
	LD (84FEh), 000h

DiskSel_PostStopEvent:
	CALR CancelOperationCleanup
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	JRL T, DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	LD XWA, (XSP + 006h)
	LD (83DAh), XWA
	CALL GetCurrentFileIndex
	LD (83DEh), HL
	CP HL, 0
	JR LT, DiskSel_DefaultIndex
	EXTS XHL
	LD XWA, (83DAh)
	LD XBC, 01e50002h
	LD XDE, XHL
	JRL T, DiskSel_PostEvent

DiskSel_DefaultIndex:
	LDW (83DEh), 0000h
	LD XWA, (83DAh)
	LD XBC, 01e50002h
	LD XDE, 0
	JRL T, DiskSel_PostEvent

DiskSel_InitDisplay:
	LD IZ, 0

DiskSel_DisplayLoop:
	LD WA, IZ
	LD HL, WA
	SLL 5, HL
	LDA XDE, 850Ch
	EXTZ XHL
	ADD XHL, XDE
	LD C, IZL
	LD (XHL), C
	LD BC, 2
	CALL LABEL_F89408
	LD WA, IZ
	CP L, 0
	JR NZ, DiskSel_GetFileName
	LD BC, 0008h
	CALL LABEL_F89408
	CP L, 0
	JR Z, DiskSel_EmptyFileName
	LD WA, IZ

DiskSel_GetFileName:
	CALL LABEL_F89623
	LD XBC, XHL
	JR T, DiskSel_FormatEntry

DiskSel_EmptyFileName:
	LDA XBC, 0EA0A54h

DiskSel_FormatEntry:
	LD DE, IZ
	LD WA, DE
	SLL 5, WA
	LD HL, 1
	ADD HL, WA
	LDA XIX, 850Ch
	EXTZ XHL
	ADD XHL, XIX
	INC 1, DE
	PUSHW 0006h
	PUSHW 0000h
	LD XWA, XHL
	CALL LABEL_F891DD
	LD DE, IZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (83DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 0014h
	JR LT, DiskSel_DisplayLoop
	JRL T, DiskSel_Exit

DiskSel_HandleNavigation:
	LD DE, (83DEh)
	LD (XSP + 004h), DE
	LD XBC, (XSP + 00ah)
	LD XWA, (XSP + 006h)
	OR XWA, XWA
	JR NZ, DiskSel_CheckPage
	CP (84FEh), 000h
	JR NZ, DiskSel_CheckPage
	LD XWA, XBC
	CP XBC, 01c00018h
	JR NZ, DiskSel_CheckPrevKey
	CP DE, 0013h
	JRL GE, DiskSel_GetCurrentIndex
	INC 1, DE
	JR T, DiskSel_SaveIndex

DiskSel_CheckPrevKey:
	CP XWA, 01c00017h
	JRL NZ, DiskSel_GetCurrentIndex
	CP DE, 0
	JRL LE, DiskSel_GetCurrentIndex
	DEC 1, DE
	JR T, DiskSel_SaveIndex

DiskSel_CheckPage:
	LD XWA, (XSP + 006h)
	CP XWA, 00000001h
	JR NZ, DiskSel_CheckPageDown
	CP (84FEh), 000h
	JR NZ, DiskSel_CheckPageDown
	CP DE, 000ah
	JRL LT, DiskSel_GetCurrentIndex
	SUB DE, 000ah
	JR T, DiskSel_SaveIndex

DiskSel_CheckPageDown:
	LD XWA, (XSP + 006h)
	CP XWA, 00000002h
	JR NZ, DiskSel_HandleToggle
	CP (84FEh), 000h
	JR NZ, DiskSel_HandleToggle
	LD WA, DE
	ADD WA, 000ah
	CP WA, 0013h
	JRL GT, DiskSel_GetCurrentIndex
	ADD DE, 000ah

DiskSel_SaveIndex:
	LD (83DEh), DE
	JRL T, DiskSel_UpdateDisplay

DiskSel_HandleToggle:
	LDA XHL, 8926h
	LD XWA, (XSP + 006h)
	CP XWA, 0000000ah
	JR NZ, DiskSel_HandleSelect
	CP (84FEh), 000h
	JR NZ, DiskSel_HandleSelect
	LD IZ, 0

DiskSel_FindMarkedLoop:
	CP (XHL + IZ), 0feh
	JR Z, DiskSel_ToggleStart
	INC 1, IZ
	CP IZ, 0014h
	JR LT, DiskSel_FindMarkedLoop

DiskSel_ToggleStart:
	LDA XDE, XHL + 014h
	CP IZ, 0014h
	JR GE, DiskSel_UnmarkLoop

DiskSel_AssignLoop:
	LD A, (XHL)
	CP A, 0feh
	JR NZ, DiskSel_NextAssign
	LD (XHL), (893Ah)
	INC 1, (893Ah)

DiskSel_NextAssign:
	INC 1, XHL
	CP XHL, XDE
	JR C, DiskSel_AssignLoop
	JR T, DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	LD A, (XHL)
	CP A, 0fdh
	JR UGT, DiskSel_NextUnmark
	LD (XHL), 0feh
	DEC 1, (893Ah)

DiskSel_NextUnmark:
	INC 1, XHL
	CP XHL, XDE
	JR C, DiskSel_UnmarkLoop

DiskSel_RefreshDisplay:
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDiskMedley1Func
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	JR T, DiskSel_RefreshBoth

DiskSel_HandleSelect:
	LD XWA, (XSP + 006h)
	CP XWA, 0000000bh
	JR NZ, DiskSel_HandleRepeat
	CP (84FEh), 000h
	JR NZ, DiskSel_HandleRepeat
	LD XIX, XHL
	LDA XBC, XHL + DE
	LD A, (XBC)
	CP A, 0feh
	JR NZ, DiskSel_RemoveSelect
	LD (XBC), (893Ah)
	INC 1, (893Ah)
	JR T, DiskSel_RefreshAfterSelect

DiskSel_RemoveSelect:
	CP A, 0fdh
	JR UGT, DiskSel_RefreshAfterSelect
	CP DE, 0014h
	JR GE, DiskSel_ReorderSlots
	LD (XBC), 0feh
	DEC 1, (893Ah)

DiskSel_ReorderSlots:
	LD XDE, XIX
	LDA XHL, XIX + 014h

DiskSel_ReorderLoop:
	LD C, (XDE)
	CP C, 0fdh
	JR UGT, DiskSel_NextReorder
	CP C, A
	JR ULE, DiskSel_NextReorder
	DEC 1, C
	LD (XDE), C

DiskSel_NextReorder:
	INC 1, XDE
	CP XDE, XHL
	JR C, DiskSel_ReorderLoop

DiskSel_RefreshAfterSelect:
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDiskMedley1Func
	LD XWA, 0
	LD XBC, 01c0000bh
	LD XDE, 0

DiskSel_RefreshBoth:
	CALR FmmDiskMedley2Func
	JRL T, DiskSel_GetCurrentIndex

DiskSel_HandleRepeat:
	LD XWA, (XSP + 006h)
	CP XWA, 0000000ch
	JR NZ, DiskSel_HandlePlayStart
	CP XBC, 01c00017h
	JR NZ, DiskSel_SetRepeatOff
	LD (893Eh), 001h
	JRL T, DiskSel_GetCurrentIndex

DiskSel_SetRepeatOff:
	LD (893Eh), 000h
	JRL T, DiskSel_GetCurrentIndex

DiskSel_HandlePlayStart:
	LD XWA, (XSP + 006h)
	CP XWA, 0000000dh
	JRL NZ, DiskSel_HandleAllCheck
	CP (84FEh), 000h
	JRL NZ, DiskSel_HandleAllCheck
	LD (893Ch), 000h
	LD IZ, 0

DiskSel_PlayClearLoop:
	LD A, IZL
	EXTZ WA
	CALL LABEL_F89321
	INC 1, IZ
	CP IZ, 0008h
	JR LT, DiskSel_PlayClearLoop
	LD IZ, 0

DiskSel_PlayFindLoop:
	LDA XWA, 8926h
	LD A, (XWA + IZ)
	CP A, (893Ch)
	JRL NZ, DiskSel_PlayNextLoop
	LD (83DEh), IZ
	LD WA, IZ
	CALL NotifyUIOfSelectionChange
	LD DE, (83DEh)
	EXTS XDE
	LD XWA, (83DAh)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CALL LABEL_F87A08
	LD QIZ, HL
	CALR SignalProgressUpdate
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CP QIZ, 0
	JR GE, DiskSel_PlayNextSong
	LD (84FEh), 000h
	LD WA, 0060h
	CALL LABEL_F99490
	LD WA, QIZ
	LD BC, 1
	CALR LABEL_F8B48E
	LD (7F42h), L
	LD WA, 00eeh

DiskSel_ShowErrorAndExit:
	CALL LABEL_F994BD
	JRL T, DiskSel_Exit

DiskSel_PlayNextSong:
	LDW (XSP + 004h), (83DEh)
	INC 1, (893Ch)
	LD XWA, (XSP + 00eh)
	LD XBC, (XSP + 00ah)
	LD XDE, (XSP + 006h)
	CALR DiskMed_PlayNextHelper
	CP L, 1
	JR NZ, DiskSel_PlayNextLoop
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0078h
	CALL LABEL_F99490
	JR T, DiskSel_GetCurrentIndex

DiskSel_PlayNextLoop:
	INC 1, IZ
	CP IZ, 0014h
	JRL LT, DiskSel_PlayFindLoop
	JR T, DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	LD XWA, (XSP + 006h)
	CP XWA, 0000000eh
	JR NZ, DiskSel_GetCurrentIndex
	CP XBC, 01c00017h
	JR NZ, DiskSel_SetAllOff
	LD (8940h), 001h
	JR T, DiskSel_GetCurrentIndex

DiskSel_SetAllOff:
	LD (8940h), 000h

DiskSel_GetCurrentIndex:
	LD DE, (83DEh)

DiskSel_UpdateDisplay:
	CP (XSP + 004h), DE
	JR Z, DiskSel_Exit
	LD WA, DE
	CALL NotifyUIOfSelectionChange
	LD DE, (83DEh)
	EXTS XDE
	LD XWA, (83DAh)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD DE, (XSP + 004h)
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (83DAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LD DE, (83DEh)
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (83DAh)
	LD XBC, 01c0000fh

DiskSel_PostEvent:
	CALL ApPostEvent

DiskSel_Exit:
	LD XHL, 0
	POP XIZ
	LDA XSP, XSP + 00eh
	RET

GetPlayState1:
	LD L, (8942h)
	RET

GetPlayState2:
	LD L, (8944h)
	RET

SmfMedley_RawData:
	db 0C9h, 0D8h, 0D8h, 07Eh, 0F1h, 044h, 089h, 041h
	db 00Eh

NavigateSongList:
	DEC 2, XSP
	PUSH IZ
	LD (XSP + 002h), WA
	CPW (XSP + 002h), 0001h
	JR Z, NavSong_CheckBounds
	CPW (XSP + 002h), 0ffffh
	JR NZ, NavSong_Exit

NavSong_CheckBounds:
	CPW (8504h), 0000h
	JR LE, NavSong_Exit
	CALL LABEL_F89AC7
	CP HL, 0
	JR LT, NavSong_Exit
	LD IZ, HL
	ADD IZ, (XSP + 002h)
	JR GE, NavSong_WrapToEnd
	LD IZ, (8504h)
	DEC 1, IZ
	JR T, NavSong_CheckEnd

NavSong_WrapToEnd:
	CP IZ, (8504h)
	JR LT, NavSong_CheckEnd
	LD IZ, 0

NavSong_CheckEnd:
	CP HL, IZ
	JR Z, NavSong_Exit
	LD WA, IZ
	CALL LABEL_F89BA4
	LD WA, IZ
	CALL LABEL_F8A07F

NavSong_Exit:
	POP IZ
	INC 2, XSP
	RET

NavigateDocList:
	PUSH IZ
	LD IZ, WA
	CP IZ, 1
	JR Z, NavDoc_CheckBounds
	CP IZ, 0ffffh
	JR NZ, NavDoc_Exit

NavDoc_CheckBounds:
	CPW (8508h), 0000h
	JR LE, NavDoc_Exit
	CALL LABEL_F8A7CE
	CP HL, 0
	JR LT, NavDoc_Exit
	LD WA, HL
	ADD WA, IZ
	JR GE, NavDoc_WrapToEnd
	LD WA, (8508h)
	DEC 1, WA
	JR T, NavDoc_CheckEnd

NavDoc_WrapToEnd:
	CP WA, (8508h)
	JR LT, NavDoc_CheckEnd
	LD WA, 0

NavDoc_CheckEnd:
	CP HL, WA
	CALL NZ, LABEL_F8A956

NavDoc_Exit:
	POP IZ
	RET

NavigatePdList:
	PUSH IZ
	LD IZ, WA
	CP IZ, 1
	JR Z, NavPd_CheckBounds
	CP IZ, 0ffffh
	JR NZ, NavPd_Exit

NavPd_CheckBounds:
	CPW (8506h), 0000h
	JR LE, NavPd_Exit
	CALL LABEL_F8A4C8
	CP HL, 0
	JR LT, NavPd_Exit
	LD WA, HL
	ADD WA, IZ
	JR GE, NavPd_WrapToEnd
	LD WA, (8506h)
	DEC 1, WA
	JR T, NavPd_CheckEnd

NavPd_WrapToEnd:
	CP WA, (8506h)
	JR LT, NavPd_CheckEnd
	LD WA, 0

NavPd_CheckEnd:
	CP HL, WA
	CALL NZ, LABEL_F8A5A5

NavPd_Exit:
	POP IZ
	RET

SmfMed_FormatSlotList:
	DEC 6, XSP
	PUSH XIZ
	LD IZ, BC
	LD (XSP + 006h), XWA
	LD XWA, 0
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmSmfFileNameFunc
	LD QIZ, HL
	LD WA, QIZ
	EXTZ XWA
	DIVW_WA 000ah
	LD QIZ, WA
	MULW_WA 000ah
	LD QIZ, WA
	LDW (XSP + 004h:8), 000ah
	LD WA, QIZ
	ADD WA, 000ah
	CP WA, IZ
	JR C, SmfFmt_CalcVisible
	LD (XSP + 004h), IZ
	LD WA, QIZ
	SUB (XSP + 004h), WA

SmfFmt_CalcVisible:
	LD IZ, 0
	CPW (XSP + 004h), 0000h
	JR ULE, SmfFmt_FillEmpty

SmfFmt_FormatLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 83E0h
	EXTZ XWA
	ADD XWA, XBC
	LD BC, QIZ
	ADD BC, IZ
	LDA XDE, 88A0h
	EXTZ XBC
	ADD XBC, XDE
	LD C, (XBC)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 83E0h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (XSP + 006h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, (XSP + 004h)
	JR C, SmfFmt_FormatLoop

SmfFmt_FillEmpty:
	CP IZ, 000ah
	JR NC, SmfFmt_Exit

SmfFmt_EmptyLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 83E0h
	EXTZ XWA
	ADD XWA, XBC
	LD BC, 00ffh
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 83E0h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (XSP + 006h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR C, SmfFmt_EmptyLoop

SmfFmt_Exit:
	POP XIZ
	INC 6, XSP
	RET

FmmSmfMedleyFunc:
	DEC 4, XSP
	PUSH IZ
	LD XHL, XBC
	LD (XSP + 002h), XWA
	CP XHL, 01e5000ah
	JRL Z, SmfMed_CheckContinue
	LD XWA, XDE
	CP XHL, 01e50008h
	JRL Z, SmfMed_StoreDelayFlag
	LD BC, (8438h)
	CP XHL, 01c00018h
	JRL Z, SmfMed_HandleNavToggle
	CP XHL, 01c00017h
	JRL Z, SmfMed_HandleNavToggle
	CP XHL, 01c0000bh
	JRL Z, SmfMed_RefreshDisplay
	CP XHL, 01e50004h
	JRL Z, SmfMed_StoreWindowPtr
	CP XHL, 01c00013h
	JRL NZ, SmfMed_Exit
	CP XDE, 00000003h
	JRL Z, SmfMed_HandleStop
	CP XDE, 00000002h
	JRL NZ, SmfMed_Exit
	LD WA, 0
	CALR InitializeOperationState
	LD A, (8D37h)
	LD (843Ah), A
	CP A, 06fh
	JR Z, SmfMed_CheckNotPlaying
	CP A, 072h
	JR NZ, SmfMed_CheckPlayMode

SmfMed_CheckNotPlaying:
	LD (84FEh), 000h
	CALL LABEL_F2076D
	CP L, 4
	JR Z, SmfMed_Error3F
	CP L, 3
	JR Z, SmfMed_Error31
	CP L, 2
	JRL NZ, SmfMed_Exit
	LD (7F42h), 001h
	LD WA, 00eeh
	JR T, SmfMed_ShowError

SmfMed_Error31:
	LD (7F42h), 031h
	LD WA, 00eeh
	JR T, SmfMed_ShowError

SmfMed_Error3F:
	LD (7F42h), 03fh
	LD WA, 00eeh

SmfMed_ShowError:
	CALL LABEL_F994BD
	JRL T, SmfMed_Exit

SmfMed_CheckPlayMode:
	CP A, 073h
	JR Z, SmfMed_CheckPlaying
	CP A, 076h
	JRL NZ, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	CALL LABEL_F2076D
	CP L, 1
	JRL C, SmfMed_CheckNotPlayError
	CALL LABEL_F2076D
	CP L, 4
	JR Z, SmfMed_PlayError3F
	CP L, 3
	JR Z, SmfMed_PlayError31
	CP L, 2
	JR NZ, SmfMed_SetPlaying
	LD (7F42h), 001h
	LD WA, 00eeh
	JR T, SmfMed_ShowPlayError

SmfMed_PlayError31:
	LD (7F42h), 031h
	LD WA, 00eeh
	JR T, SmfMed_ShowPlayError

SmfMed_PlayError3F:
	LD (7F42h), 03fh
	LD WA, 00eeh

SmfMed_ShowPlayError:
	CALL LABEL_F994BD
	INC 1, (843Ch)

SmfMed_SetPlaying:
	LD (84FEh), 001h
	LD A, (8922h)
	CP A, (8920h)
	JR NC, SmfMed_CheckRepeat
	LD IZ, 0
	LD BC, (8438h)
	CP BC, 0
	JRL ULE, SmfMed_Exit
	LDA XDE, 88A0h

SmfMed_FindSongLoop:
	LD HL, IZ
	EXTZ XHL
	ADD XHL, XDE
	CP (XHL), A
	JR NZ, SmfMed_NextSong
	LD DE, IZ
	EXTZ XDE
	LD XWA, (XSP + 002h)
	LD XBC, 01e50002h
	CALR FmmSmfFileNameFunc
	LD XWA, (8430h)
	LD BC, (8438h)
	CALR SmfMed_FormatSlotList
	INC 1, (8922h)
	LD WA, IZ
	CALL LABEL_F8A07F
	LD XWA, (8434h)
	OR XWA, XWA
	JRL Z, SmfMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh
	JR T, SmfMed_PostDelayEvent

SmfMed_NextSong:
	INC 1, IZ
	CP IZ, BC
	JR C, SmfMed_FindSongLoop
	JRL T, SmfMed_Exit

SmfMed_CheckRepeat:
	CP (8924h), 000h
	JR Z, SmfMed_ClearRepeatCount
	CP (843Ch), A
	JR NC, SmfMed_ClearRepeatCount
	LD (8922h), 000h
	LD (843Ch), 000h
	LD IZ, 0
	LD WA, (8438h)
	CP WA, 0
	JRL ULE, SmfMed_Exit
	LDA XBC, 88A0h

SmfMed_RepeatFindLoop:
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), 000h
	JR NZ, SmfMed_RepeatNext
	LD DE, IZ
	EXTZ XDE
	LD XWA, (XSP + 002h)
	LD XBC, 01e50002h
	CALR FmmSmfFileNameFunc
	LD XWA, (8430h)
	LD BC, (8438h)
	CALR SmfMed_FormatSlotList
	INC 1, (8922h)
	LD WA, IZ
	CALL LABEL_F8A07F
	LD XWA, (8434h)
	OR XWA, XWA
	JRL Z, SmfMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh

SmfMed_PostDelayEvent:
	CALL ApPostEvent
	JRL T, SmfMed_Exit

SmfMed_RepeatNext:
	INC 1, IZ
	CP IZ, WA
	JR C, SmfMed_RepeatFindLoop
	JRL T, SmfMed_Exit

SmfMed_ClearRepeatCount:
	LD (843Ch), 000h
	JR T, SmfMed_ClearPlaying

SmfMed_CheckNotPlayError:
	CALL LABEL_F2076D
	CP L, 0
	JRL NZ, SmfMed_Exit

SmfMed_ClearPlaying:
	LD (84FEh), 000h
	JRL T, SmfMed_Exit

SmfMed_InitFromDisk:
	LD XDE, 0
	LD E, (8944h)
	LD XWA, 006c0018h
	LD XBC, 01e0003bh
	CALL ApPostEvent
	CPW (8504h), 0000h
	JR GE, SmfMed_InitState
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CALL GetFileCountEncoded
	LD (8504h), HL
	CALL LABEL_F8958D
	CALL GetEncodedFreeSpaceData
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CALR SignalProgressUpdate

SmfMed_InitState:
	LD (84FEh), 000h
	LD (8922h), 000h
	LD (8920h), 000h
	LD BC, 0080h
	LD WA, (8504h)
	CP WA, 0080h
	JR UGT, SmfMed_ClampFileCount
	LD BC, WA

SmfMed_ClampFileCount:
	LD (8438h), BC
	LD IZ, 0
	CP BC, 0
	JR ULE, SmfMed_FinishInit
	LDA XWA, 88A0h

SmfMed_ClearSlotsLoop:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	LD (XBC), 0ffh
	INC 1, IZ
	CP IZ, (8438h)
	JR C, SmfMed_ClearSlotsLoop

SmfMed_FinishInit:
	CALL LABEL_F20ACD
	LD XWA, 0
	LD (8434h), XWA
	JRL T, SmfMed_Exit

SmfMed_HandleStop:
	LD A, (8D36h)
	CP A, 06fh
	JRL Z, SmfMed_Exit
	CP A, 072h
	JRL Z, SmfMed_Exit
	CP A, 073h
	JRL Z, SmfMed_Exit
	CP A, 076h
	JRL Z, SmfMed_Exit
	CALL LABEL_F20B70
	CALR CancelOperationCleanup
	LD (84FEh), 000h
	JRL T, SmfMed_Exit

SmfMed_StoreWindowPtr:
	LD (8430h), XWA
	JRL T, SmfMed_Exit

SmfMed_RefreshDisplay:
	LD XWA, (8430h)
	CALR SmfMed_FormatSlotList
	JRL T, SmfMed_Exit

SmfMed_HandleNavToggle:
	LDA XWA, 88A0h
	CP XDE, 0000000ah
	JR NZ, SmfMed_HandleSelectToggle
	CP (84FEh), 000h
	JR NZ, SmfMed_HandleSelectToggle
	LD IZ, 0
	LD DE, BC
	CP BC, 0
	JR ULE, SmfMed_CheckAllUnmarked

SmfMed_FindUnmarkedLoop:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XWA
	CP (XBC), 0ffh
	JR Z, SmfMed_CheckAllUnmarked
	INC 1, IZ
	CP IZ, DE
	JR C, SmfMed_FindUnmarkedLoop

SmfMed_CheckAllUnmarked:
	CP IZ, DE
	JR NC, SmfMed_RemoveOrderLoop
	LD IZ, 0
	CP DE, 0
	JR ULE, SmfMed_RefreshAfterToggle
	LDA XDE, 88A0h

SmfMed_AssignOrderLoop:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XDE
	LD A, (XBC)
	CP A, 0ffh
	JR NZ, SmfMed_NextAssign
	LD (XBC), (8920h)
	INC 1, (8920h)

SmfMed_NextAssign:
	INC 1, IZ
	CP IZ, (8438h)
	JR C, SmfMed_AssignOrderLoop
	JR T, SmfMed_RefreshAfterToggle

SmfMed_RemoveOrderLoop:
	LD IZ, 0
	CP DE, 0
	JR ULE, SmfMed_RefreshAfterToggle
	LDA XDE, 88A0h

SmfMed_UnmarkLoop:
	LD BC, IZ
	EXTZ XBC
	ADD XBC, XDE
	LD A, (XBC)
	CP A, 0fdh
	JR UGT, SmfMed_NextUnmark
	LD (XBC), 0ffh
	DEC 1, (8920h)

SmfMed_NextUnmark:
	INC 1, IZ
	CP IZ, (8438h)
	JR C, SmfMed_UnmarkLoop

SmfMed_RefreshAfterToggle:
	LD XWA, (8430h)
	LD BC, (8438h)
	JR T, SmfMed_CallFormatSlots

SmfMed_HandleSelectToggle:
	CP XDE, 0000000bh
	JR NZ, SmfMed_HandleRepeat
	CP (84FEh), 000h
	JR NZ, SmfMed_HandleRepeat
	LD XWA, (XSP + 002h)
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmSmfFileNameFunc
	LD IZ, HL
	LDA XHL, 88A0h
	LD WA, IZ
	EXTZ XWA
	ADD XWA, XHL
	LD C, (XWA)
	CP C, 0ffh
	JR NZ, SmfMed_RemoveFromOrder
	LD (XWA), (8920h)
	INC 1, (8920h)
	JR T, SmfMed_RefreshAfterSelect

SmfMed_RemoveFromOrder:
	CP C, 0fdh
	JR UGT, SmfMed_RefreshAfterSelect
	LD (XWA), 0ffh
	LD A, (8920h)
	DEC 1, A
	LD (8920h), A
	LD IY, 0
	LD IZ, 0
	EXTZ WA
	CP WA, 0
	JR ULE, SmfMed_RefreshAfterSelect
	LD IX, WA

SmfMed_ReorderLoop:
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XHL
	LD A, (XDE)
	CP A, 0fdh
	JR UGT, SmfMed_NextReorder
	INC 1, IY
	CP A, C
	JR ULE, SmfMed_NextReorder
	DEC 1, A
	LD (XDE), A

SmfMed_NextReorder:
	INC 1, IZ
	CP IY, IX
	JR C, SmfMed_ReorderLoop

SmfMed_RefreshAfterSelect:
	LD XWA, (8430h)
	LD BC, (8438h)

SmfMed_CallFormatSlots:
	CALR SmfMed_FormatSlotList
	JRL T, SmfMed_Exit

SmfMed_HandleRepeat:
	CP XDE, 0000000ch
	JR NZ, SmfMed_HandlePlay
	CP XHL, 01c00017h
	JR NZ, SmfMed_SetRepeatOff
	LD (8924h), 001h
	JRL T, SmfMed_Exit

SmfMed_SetRepeatOff:
	LD (8924h), 000h
	JRL T, SmfMed_Exit

SmfMed_HandlePlay:
	CP XDE, 0000000dh
	JRL NZ, SmfMed_Exit
	CP (84FEh), 000h
	JRL NZ, SmfMed_Exit
	LD (8922h), 000h
	LD (843Ch), 000h
	LD IZ, 0
	LD BC, (8438h)
	CP BC, 0
	JR ULE, SmfMed_CheckAutoPlay

SmfMed_PlayFindLoop:
	LD DE, IZ
	EXTZ XDE
	ADD XDE, XWA
	CP (XDE), 000h
	JR NZ, SmfMed_PlayNextLoop
	LD (84FEh), 001h
	LD DE, IZ
	EXTZ XDE
	LD XWA, (XSP + 002h)
	LD XBC, 01e50002h
	CALR FmmSmfFileNameFunc
	INC 1, (8922h)
	LD WA, IZ
	CALL LABEL_F8A07F
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0073h
	CALL LABEL_F99490
	JR T, SmfMed_CheckAutoPlay

SmfMed_PlayNextLoop:
	INC 1, IZ
	CP IZ, BC
	JR C, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	CP (84FEh), 000h
	JR NZ, SmfMed_Exit
	LD XWA, (XSP + 002h)
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmSmfFileNameFunc
	LD IZ, HL
	LD WA, IZ
	CALL LABEL_F8A07F
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 006fh
	JR T, SmfMed_CallPauseMode

SmfMed_StoreDelayFlag:
	LD (8434h), XWA
	JR T, SmfMed_Exit

SmfMed_CheckContinue:
	CP (84FEh), 000h
	JR Z, SmfMed_Exit
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD A, (843Ah)
	EXTZ WA

SmfMed_CallPauseMode:
	CALL LABEL_F99490

SmfMed_Exit:
	LD XHL, 0
	POP IZ
	INC 4, XSP
	RET

PdMed_FormatFileList:
	DEC 6, XSP
	PUSH IZ
	LD (XSP + 002h), BC
	LD (XSP + 004h), XWA
	LD IZ, 0

PdFmt_FormatLoop:
	LD DE, IZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD A, IZL
	LD (XDE), A
	LD WA, (XSP + 002h)
	ADD WA, IZ
	CALL LABEL_F8A5F1
	LD XBC, XHL
	LD WA, IZ
	SLL 5, WA
	LD DE, 1
	ADD DE, WA
	LDA XHL, 850Ch
	LD WA, DE
	EXTZ XWA
	ADD XWA, XHL
	LD DE, (XSP + 002h)
	ADD DE, IZ
	INC 1, DE
	PUSHW 0014h
	PUSHW 0001h
	CALL LABEL_F891DD
	LD DE, IZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (XSP + 004h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR LT, PdFmt_FormatLoop
	POP IZ
	INC 6, XSP
	RET

FmmPdFileNameFunc:
	DEC 4, XSP
	PUSH IZ
	LD (XSP + 002h), XWA
	CP XBC, 01e50003h
	JRL Z, PdName_GetIndexReturn
	LD WA, (8442h)
	LD IZ, WA
	CP XBC, 01e50002h
	JRL Z, PdName_SetIndexPlaying
	LD HL, WA
	EXTS XHL
	DIVS_HL 000ah
	CP XBC, 01c00018h
	JR Z, PdName_HandleNavigation
	CP XBC, 01c00017h
	JR Z, PdName_HandleNavigation
	CP XBC, 01c0000bh
	JR Z, PdName_RefreshList
	CP XBC, 01e50004h
	JR NZ, PdName_ReturnZero
	LD (843Eh), XDE
	CALL LABEL_F8A4C8
	LD (8442h), HL
	CP HL, 0
	JR GE, PdName_UpdateIndex
	LDW (8442h), 0000h

PdName_UpdateIndex:
	LD WA, (8442h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (843Eh)
	LD XBC, 01e50002h
	JRL T, PdName_PostEvent

PdName_RefreshList:
	MULS_HL 000ah
	LD XWA, (843Eh)
	LD BC, HL
	CALR PdMed_FormatFileList

PdName_ReturnZero:
	LD XHL, 0
	JRL T, PdName_Exit

PdName_HandleNavigation:
	OR XDE, XDE
	JR NZ, PdName_CheckPageUp
	CP (84FEh), 000h
	JR NZ, PdName_CheckPageUp
	CP XBC, 01c00018h
	JR NZ, PdName_CheckPrevKey
	LD BC, WA
	INC 1, BC
	CP BC, (8506h)
	JR GE, PdName_GetCurrentIndex
	INC 1, WA
	JR T, PdName_SaveIndex

PdName_CheckPrevKey:
	CP XBC, 01c00017h
	JR NZ, PdName_GetCurrentIndex
	CP WA, 0
	JR LE, PdName_GetCurrentIndex
	DEC 1, WA
	JR T, PdName_SaveIndex

PdName_CheckPageUp:
	CP XDE, 00000001h
	JR NZ, PdName_CheckPageDown
	CP (84FEh), 000h
	JR NZ, PdName_CheckPageDown
	CP WA, 000ah
	JR LT, PdName_GetCurrentIndex
	SUB WA, 000ah
	JR T, PdName_SaveIndex

PdName_CheckPageDown:
	CP XDE, 00000002h
	JR NZ, PdName_GetCurrentIndex
	CP (84FEh), 000h
	JR NZ, PdName_GetCurrentIndex
	LD BC, WA
	ADD BC, 000ah
	LD DE, (8506h)
	CP BC, DE
	JR GE, PdName_CheckEndBound
	ADD WA, 000ah

PdName_SaveIndex:
	LD (8442h), WA
	JR T, PdName_UpdateDisplay

PdName_CheckEndBound:
	LD BC, DE
	DEC 1, BC
	LD WA, BC
	EXTS XWA
	DIVS_WA 000ah
	CP HL, WA
	JR GE, PdName_GetCurrentIndex
	EXTS XDE
	DIVS_DE 000ah
	LD WA, QDE
	CP WA, 0
	JR Z, PdName_GetCurrentIndex
	LD (8442h), BC

PdName_GetCurrentIndex:
	LD WA, (8442h)

PdName_UpdateDisplay:
	CP IZ, WA
	JRL Z, PdName_ReturnZero
	CALL LABEL_F8A5A5
	LD WA, (8442h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (843Eh)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD BC, (8442h)
	EXTS XBC
	DIVS_BC 000ah
	LD DE, IZ
	EXTS XDE
	DIVS_DE 000ah
	LD XWA, (843Eh)
	CP DE, BC
	JR NZ, PdName_RefreshPage
	LD BC, IZ
	EXTS XBC
	DIVS_BC 000ah
	LD BC, QBC
	SLL 5, BC
	LDA XHL, 850Ch
	LD DE, BC
	EXTZ XDE
	ADD XDE, XHL
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LD WA, (8442h)
	EXTS XWA
	DIVS_WA 000ah
	LD WA, QWA
	SLL 5, WA
	LDA XBC, 850Ch
	LD DE, WA
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (843Eh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	JRL T, PdName_ReturnZero

PdName_RefreshPage:
	MULS_BC 000ah
	CALR PdMed_FormatFileList
	LD XWA, (XSP + 002h)
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmPdMedleyFunc
	JRL T, PdName_ReturnZero

PdName_SetIndexPlaying:
	CP (84FEh), 000h
	JRL Z, PdName_ReturnZero
	LD (8442h), DE
	LD WA, DE
	CALL LABEL_F8A5A5
	LD WA, (8442h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (843Eh)
	LD XBC, 01e50002h

PdName_PostEvent:
	CALL ApPostEvent
	JRL T, PdName_ReturnZero

PdName_GetIndexReturn:
	LD HL, (8442h)
	EXTS XHL

PdName_Exit:
	POP IZ
	INC 4, XSP
	RET

PdMed_FormatSlotList:
	DEC 6, XSP
	PUSH XIZ
	LD IZ, BC
	LD (XSP + 006h), XWA
	LD XWA, 0
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmPdFileNameFunc
	LD QIZ, HL
	LD WA, QIZ
	EXTZ XWA
	DIVW_WA 000ah
	LD QIZ, WA
	MULW_WA 000ah
	LD QIZ, WA
	LDW (XSP + 004h:8), 000ah
	LD WA, QIZ
	ADD WA, 000ah
	CP WA, IZ
	JR C, PdFmtSlot_CalcVisible
	LD (XSP + 004h), IZ
	LD WA, QIZ
	SUB (XSP + 004h), WA

PdFmtSlot_CalcVisible:
	LD IZ, 0
	CPW (XSP + 004h), 0000h
	JR ULE, PdFmtSlot_FillEmpty

PdFmtSlot_FormatLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 8444h
	EXTZ XWA
	ADD XWA, XBC
	LD BC, QIZ
	ADD BC, IZ
	LDA XDE, 88A0h
	EXTZ XBC
	ADD XBC, XDE
	LD C, (XBC)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 8444h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (XSP + 006h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, (XSP + 004h)
	JR C, PdFmtSlot_FormatLoop

PdFmtSlot_FillEmpty:
	CP IZ, 000ah
	JR NC, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 8444h
	EXTZ XWA
	ADD XWA, XBC
	LD BC, 00ffh
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 8444h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (XSP + 006h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR C, PdFmtSlot_EmptyLoop

PdFmtSlot_Exit:
	POP XIZ
	INC 6, XSP
	RET

FmmPdMedleyFunc:
	PUSH XIZ
	LD XHL, XDE
	LD XDE, XBC
	LD XIZ, XWA
	CP XDE, 01e5000ah
	JRL Z, PdMed_CheckContinue
	LD XWA, XHL
	CP XDE, 01e50008h
	JRL Z, PdMed_StoreDelayFlag
	LD BC, (849Ch)
	CP XDE, 01c00018h
	JRL Z, PdMed_HandleNavToggle
	CP XDE, 01c00017h
	JRL Z, PdMed_HandleNavToggle
	CP XDE, 01c0000bh
	JRL Z, PdMed_RefreshDisplay
	CP XDE, 01e50004h
	JRL Z, PdMed_StoreWindowPtr
	CP XDE, 01c00013h
	JRL NZ, PdMed_Exit
	CP XHL, 00000003h
	JRL Z, PdMed_HandleStop
	CP XHL, 00000002h
	JRL NZ, PdMed_Exit
	LD WA, 0
	CALL InitializeOperationState
	LD A, (8D37h)
	CP A, 071h
	JR NZ, PdMed_CheckPlayMode
	LD (84FEh), 000h
	CALL LABEL_F2076D
	CP L, 2
	JRL C, PdMed_Exit
	LD (7F42h), 001h
	LD WA, 00eeh
	JRL T, PdMed_ShowError

PdMed_CheckPlayMode:
	CP A, 075h
	JRL NZ, PdMed_InitFromDisk
	CALL LABEL_F2076D
	CP L, 1
	JRL NZ, PdMed_HandleError
	LD (84FEh), 001h
	LD C, (8922h)
	LDA XWA, 88A0h
	CP C, (8920h)
	JR NC, PdMed_CheckRepeat
	LD HL, 0
	LD DE, (849Ch)
	CP DE, 0
	JRL ULE, PdMed_Exit

PdMed_FindSongLoop:
	LD IX, HL
	EXTZ XIX
	ADD XIX, XWA
	CP (XIX), C
	JR NZ, PdMed_NextSong
	EXTZ XHL
	LD XWA, XIZ
	LD XBC, 01e50002h
	LD XDE, XHL
	CALR FmmPdFileNameFunc
	LD XWA, (8494h)
	LD BC, (849Ch)
	CALR PdMed_FormatSlotList
	INC 1, (8922h)
	LD XWA, (8498h)
	OR XWA, XWA
	JRL Z, PdMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh
	JR T, PdMed_PostDelayEvent

PdMed_NextSong:
	INC 1, HL
	CP HL, DE
	JR C, PdMed_FindSongLoop
	JRL T, PdMed_Exit

PdMed_CheckRepeat:
	CP (8924h), 000h
	JR Z, PdMed_ClearPlaying
	LD (8922h), 000h
	LD HL, 0
	LD BC, (849Ch)
	CP BC, 0
	JRL ULE, PdMed_Exit

PdMed_RepeatFindLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XWA
	CP (XDE), 000h
	JR NZ, PdMed_RepeatNext
	EXTZ XHL
	LD XWA, XIZ
	LD XBC, 01e50002h
	LD XDE, XHL
	CALR FmmPdFileNameFunc
	LD XWA, (8494h)
	LD BC, (849Ch)
	CALR PdMed_FormatSlotList
	INC 1, (8922h)
	LD XWA, (8498h)
	OR XWA, XWA
	JRL Z, PdMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh

PdMed_PostDelayEvent:
	CALL ApPostEvent
	JRL T, PdMed_Exit

PdMed_RepeatNext:
	INC 1, HL
	CP HL, BC
	JR C, PdMed_RepeatFindLoop
	JRL T, PdMed_Exit

PdMed_ClearPlaying:
	LD (84FEh), 000h
	JRL T, PdMed_Exit

PdMed_HandleError:
	CALL LABEL_F2076D
	LD (84FEh), 000h
	CP L, 0
	JRL Z, PdMed_Exit
	LD (7F42h), 001h
	LD WA, 00eeh

PdMed_ShowError:
	CALL LABEL_F994BD
	JRL T, PdMed_Exit

PdMed_InitFromDisk:
	CPW (8506h), 0000h
	JR GE, PdMed_InitState
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CALL LABEL_F8A625
	LD (8506h), HL
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CALL SignalProgressUpdate

PdMed_InitState:
	LD (84FEh), 000h
	LD (8922h), 000h
	LD (8920h), 000h
	LD BC, 0080h
	LD WA, (8506h)
	CP WA, 0080h
	JR UGT, PdMed_ClampCount
	LD BC, WA

PdMed_ClampCount:
	LD (849Ch), BC
	LD HL, 0
	CP BC, 0
	JR ULE, PdMed_FinishInit
	LDA XWA, 88A0h

PdMed_ClearSlotsLoop:
	LD BC, HL
	EXTZ XBC
	ADD XBC, XWA
	LD (XBC), 0ffh
	INC 1, HL
	CP HL, (849Ch)
	JR C, PdMed_ClearSlotsLoop

PdMed_FinishInit:
	CALL LABEL_F20ACD
	LD XWA, 0
	LD (8498h), XWA
	JRL T, PdMed_Exit

PdMed_HandleStop:
	LD A, (8D36h)
	CP A, 071h
	JRL Z, PdMed_Exit
	CP A, 075h
	JRL Z, PdMed_Exit
	CALL LABEL_F20B70
	CALL CancelOperationCleanup
	LD (84FEh), 000h
	JRL T, PdMed_Exit

PdMed_StoreWindowPtr:
	LD (8494h), XWA
	JRL T, PdMed_Exit

PdMed_RefreshDisplay:
	LD XWA, (8494h)
	CALR PdMed_FormatSlotList
	JRL T, PdMed_Exit

PdMed_HandleNavToggle:
	CP XHL, 0000000ah
	JRL NZ, PdMed_HandleSelectToggle
	CP (84FEh), 000h
	JR NZ, PdMed_HandleSelectToggle
	LD HL, 0
	LD WA, BC
	CP BC, 0
	JR ULE, PdMed_CheckAllUnmarked
	LDA XBC, 88A0h

PdMed_FindUnmarkedLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), 0ffh
	JR Z, PdMed_CheckAllUnmarked
	INC 1, HL
	CP HL, WA
	JR C, PdMed_FindUnmarkedLoop

PdMed_CheckAllUnmarked:
	CP HL, WA
	JR NC, PdMed_RemoveOrderLoop
	LD HL, 0
	CP WA, 0
	JR ULE, PdMed_RefreshAfterToggle
	LDA XDE, 88A0h

PdMed_AssignOrderLoop:
	LD BC, HL
	EXTZ XBC
	ADD XBC, XDE
	LD A, (XBC)
	CP A, 0ffh
	JR NZ, PdMed_NextAssign
	LD (XBC), (8920h)
	INC 1, (8920h)

PdMed_NextAssign:
	INC 1, HL
	CP HL, (849Ch)
	JR C, PdMed_AssignOrderLoop
	JR T, PdMed_RefreshAfterToggle

PdMed_RemoveOrderLoop:
	LD HL, 0
	CP WA, 0
	JR ULE, PdMed_RefreshAfterToggle
	LDA XDE, 88A0h

PdMed_UnmarkLoop:
	LD BC, HL
	EXTZ XBC
	ADD XBC, XDE
	LD A, (XBC)
	CP A, 0fdh
	JR UGT, PdMed_NextUnmark
	LD (XBC), 0ffh
	DEC 1, (8920h)

PdMed_NextUnmark:
	INC 1, HL
	CP HL, (849Ch)
	JR C, PdMed_UnmarkLoop

PdMed_RefreshAfterToggle:
	LD XWA, (8494h)
	LD BC, (849Ch)
	JR T, PdMed_CallFormatSlots

PdMed_HandleSelectToggle:
	CP XHL, 0000000bh
	JR NZ, PdMed_HandleRepeat
	CP (84FEh), 000h
	JR NZ, PdMed_HandleRepeat
	LD XWA, XIZ
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmPdFileNameFunc
	LDA XIX, 88A0h
	EXTZ XHL
	ADD XHL, XIX
	LD C, (XHL)
	CP C, 0ffh
	JR NZ, PdMed_RemoveFromOrder
	LD (XHL), (8920h)
	INC 1, (8920h)
	JR T, PdMed_RefreshAfterSelect

PdMed_RemoveFromOrder:
	CP C, 0fdh
	JR UGT, PdMed_RefreshAfterSelect
	LD (XHL), 0ffh
	LD A, (8920h)
	DEC 1, A
	LD (8920h), A
	LD IZ, 0
	LD HL, 0
	EXTZ WA
	CP WA, 0
	JR ULE, PdMed_RefreshAfterSelect
	LD IY, WA

PdMed_ReorderLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XIX
	LD A, (XDE)
	CP A, 0fdh
	JR UGT, PdMed_NextReorder
	INC 1, IZ
	CP A, C
	JR ULE, PdMed_NextReorder
	DEC 1, A
	LD (XDE), A

PdMed_NextReorder:
	INC 1, HL
	CP IZ, IY
	JR C, PdMed_ReorderLoop

PdMed_RefreshAfterSelect:
	LD XWA, (8494h)
	LD BC, (849Ch)

PdMed_CallFormatSlots:
	CALR PdMed_FormatSlotList
	JRL T, PdMed_Exit

PdMed_HandleRepeat:
	CP XHL, 0000000ch
	JR NZ, PdMed_HandlePlay
	CP XDE, 01c00017h
	JR NZ, PdMed_SetRepeatOff
	LD (8924h), 001h
	JRL T, PdMed_Exit

PdMed_SetRepeatOff:
	LD (8924h), 000h
	JRL T, PdMed_Exit

PdMed_HandlePlay:
	CP XHL, 0000000dh
	JRL NZ, PdMed_Exit
	CP (84FEh), 000h
	JRL NZ, PdMed_Exit
	LD (8922h), 000h
	LD HL, 0
	LD WA, (849Ch)
	CP WA, 0
	JR ULE, PdMed_CheckAutoPlay
	LDA XBC, 88A0h

PdMed_PlayFindLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), 000h
	JR NZ, PdMed_PlayNextLoop
	LD (84FEh), 001h
	EXTZ XHL
	LD XWA, XIZ
	LD XBC, 01e50002h
	LD XDE, XHL
	CALR FmmPdFileNameFunc
	INC 1, (8922h)
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0075h
	CALL LABEL_F99490
	JR T, PdMed_CheckAutoPlay

PdMed_PlayNextLoop:
	INC 1, HL
	CP HL, WA
	JR C, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	CP (84FEh), 000h
	JR NZ, PdMed_Exit
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0071h
	JR T, PdMed_CallPauseMode

PdMed_StoreDelayFlag:
	LD (8498h), XWA
	JR T, PdMed_Exit

PdMed_CheckContinue:
	CP (84FEh), 000h
	JR Z, PdMed_Exit
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0075h

PdMed_CallPauseMode:
	CALL LABEL_F99490

PdMed_Exit:
	LD XHL, 0
	POP XIZ
	RET

DocDiskNameFunc:
	PUSH XIZ
	LD XIZ, XDE
	CP XBC, 01c0000bh
	JR NZ, DocDisk_Exit
	CALL LABEL_F8958D
	LD IX, 0
	JR T, DocDisk_CopyLoop

DocDisk_CopyCharLoop:
	CP (XHL), 020h
	JR Z, DocDisk_SkipSpace
	LD DE, IX
	INC 1, IX
	LD A, (XHL)
	LD (XBC + DE), A

DocDisk_SkipSpace:
	INC 1, XHL

DocDisk_CopyLoop:
	LDA XBC, 878Ch
	CP (XHL), 000h
	JR Z, DocDisk_TerminateStr
	CP IX, 001eh
	JR LT, DocDisk_CopyCharLoop

DocDisk_TerminateStr:
	LD XDE, XBC
	LD (XBC + IX), 000h
	JR T, DocDisk_TrimLoop

DocDisk_ClearTrailing:
	LD (XWA), 000h

DocDisk_TrimLoop:
	DEC 1, IX
	LDA XWA, XDE + IX
	CP (XWA), 020h
	JR NZ, DocDisk_PostEvent
	CP IX, 0
	JR GT, DocDisk_ClearTrailing

DocDisk_PostEvent:
	LD XWA, XIZ
	LD XBC, 01c0000fh
	CALL ApPostEvent

DocDisk_Exit:
	LD XHL, 0
	POP XIZ
	RET

DocMed_FormatFileList:
	DEC 6, XSP
	PUSH IZ
	LD (XSP + 002h), BC
	LD (XSP + 004h), XWA
	LD IZ, 0

DocFmt_FormatLoop:
	LD DE, IZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD A, IZL
	LD (XDE), A
	LD WA, (XSP + 002h)
	ADD WA, IZ
	CALL LABEL_F8ABBB
	LD XBC, XHL
	LD WA, IZ
	SLL 5, WA
	LD DE, 1
	ADD DE, WA
	LDA XHL, 850Ch
	LD WA, DE
	EXTZ XWA
	ADD XWA, XHL
	LD DE, (XSP + 002h)
	ADD DE, IZ
	INC 1, DE
	PUSHW 000ch
	PUSHW 0000h
	CALL LABEL_F891DD
	LD DE, IZ
	SLL 5, DE
	LDA XBC, 850Ch
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (XSP + 004h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR LT, DocFmt_FormatLoop
	POP IZ
	INC 6, XSP
	RET

FmmDocFileNameFunc:
	DEC 4, XSP
	PUSH IZ
	LD (XSP + 002h), XWA
	CP XBC, 01e50003h
	JRL Z, DocName_GetIndexReturn
	LD WA, (84A2h)
	LD IZ, WA
	CP XBC, 01e50002h
	JRL Z, DocName_SetIndexPlaying
	LD HL, WA
	EXTS XHL
	DIVS_HL 000ah
	CP XBC, 01c00018h
	JR Z, DocName_HandleNavigation
	CP XBC, 01c00017h
	JR Z, DocName_HandleNavigation
	CP XBC, 01c0000bh
	JR Z, DocName_RefreshList
	CP XBC, 01e50004h
	JR NZ, DocName_ReturnZero
	LD (849Eh), XDE
	CALL LABEL_F8A7CE
	LD (84A2h), HL
	CP HL, 0
	JR GE, DocName_UpdateIndex
	LDW (84A2h), 0000h

DocName_UpdateIndex:
	LD WA, (84A2h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (849Eh)
	LD XBC, 01e50002h
	JRL T, DocName_PostEvent

DocName_RefreshList:
	MULS_HL 000ah
	LD XWA, (849Eh)
	LD BC, HL
	CALR DocMed_FormatFileList

DocName_ReturnZero:
	LD XHL, 0
	JRL T, DocName_Exit

DocName_HandleNavigation:
	OR XDE, XDE
	JR NZ, DocName_CheckPageUp
	CP (84FEh), 000h
	JR NZ, DocName_CheckPageUp
	CP XBC, 01c00018h
	JR NZ, DocName_CheckPrevKey
	LD BC, WA
	INC 1, BC
	CP BC, (8508h)
	JR GE, DocName_GetCurrentIndex
	INC 1, WA
	JR T, DocName_SaveIndex

DocName_CheckPrevKey:
	CP XBC, 01c00017h
	JR NZ, DocName_GetCurrentIndex
	CP WA, 0
	JR LE, DocName_GetCurrentIndex
	DEC 1, WA
	JR T, DocName_SaveIndex

DocName_CheckPageUp:
	CP XDE, 00000001h
	JR NZ, DocName_CheckPageDown
	CP (84FEh), 000h
	JR NZ, DocName_CheckPageDown
	CP WA, 000ah
	JR LT, DocName_GetCurrentIndex
	SUB WA, 000ah
	JR T, DocName_SaveIndex

DocName_CheckPageDown:
	CP XDE, 00000002h
	JR NZ, DocName_GetCurrentIndex
	CP (84FEh), 000h
	JR NZ, DocName_GetCurrentIndex
	LD BC, WA
	ADD BC, 000ah
	LD DE, (8508h)
	CP BC, DE
	JR GE, DocName_CheckEndBound
	ADD WA, 000ah

DocName_SaveIndex:
	LD (84A2h), WA
	JR T, DocName_UpdateDisplay

DocName_CheckEndBound:
	LD BC, DE
	DEC 1, BC
	LD WA, BC
	EXTS XWA
	DIVS_WA 000ah
	CP HL, WA
	JR GE, DocName_GetCurrentIndex
	EXTS XDE
	DIVS_DE 000ah
	LD WA, QDE
	CP WA, 0
	JR Z, DocName_GetCurrentIndex
	LD (84A2h), BC

DocName_GetCurrentIndex:
	LD WA, (84A2h)

DocName_UpdateDisplay:
	CP IZ, WA
	JRL Z, DocName_ReturnZero
	CALL LABEL_F8A956
	LD WA, (84A2h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (849Eh)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD BC, (84A2h)
	EXTS XBC
	DIVS_BC 000ah
	LD DE, IZ
	EXTS XDE
	DIVS_DE 000ah
	LD XWA, (849Eh)
	CP DE, BC
	JR NZ, DocName_RefreshPage
	LD BC, IZ
	EXTS XBC
	DIVS_BC 000ah
	LD BC, QBC
	SLL 5, BC
	LDA XHL, 850Ch
	LD DE, BC
	EXTZ XDE
	ADD XDE, XHL
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LD WA, (84A2h)
	EXTS XWA
	DIVS_WA 000ah
	LD WA, QWA
	SLL 5, WA
	LDA XBC, 850Ch
	LD DE, WA
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (849Eh)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	JRL T, DocName_ReturnZero

DocName_RefreshPage:
	MULS_BC 000ah
	CALR DocMed_FormatFileList
	LD XWA, (XSP + 002h)
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR FmmDocMedleyFunc
	JRL T, DocName_ReturnZero

DocName_SetIndexPlaying:
	CP (84FEh), 000h
	JRL Z, DocName_ReturnZero
	LD (84A2h), DE
	LD WA, DE
	CALL LABEL_F8A956
	LD WA, (84A2h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (849Eh)
	LD XBC, 01e50002h

DocName_PostEvent:
	CALL ApPostEvent
	JRL T, DocName_ReturnZero

DocName_GetIndexReturn:
	LD HL, (84A2h)
	EXTS XHL

DocName_Exit:
	POP IZ
	INC 4, XSP
	RET

DocMed_FormatSlotList:
	DEC 6, XSP
	PUSH XIZ
	LD IZ, BC
	LD (XSP + 006h), XWA
	LD XWA, 0
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmDocFileNameFunc
	LD QIZ, HL
	LD WA, QIZ
	EXTZ XWA
	DIVW_WA 000ah
	LD QIZ, WA
	MULW_WA 000ah
	LD QIZ, WA
	LDW (XSP + 004h:8), 000ah
	LD WA, QIZ
	ADD WA, 000ah
	CP WA, IZ
	JR C, DocFmtSlot_CalcVisible
	LD (XSP + 004h), IZ
	LD WA, QIZ
	SUB (XSP + 004h), WA

DocFmtSlot_CalcVisible:
	LD IZ, 0
	CPW (XSP + 004h), 0000h
	JR ULE, DocFmtSlot_FillEmpty

DocFmtSlot_FormatLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 84A4h
	EXTZ XWA
	ADD XWA, XBC
	LD BC, QIZ
	ADD BC, IZ
	LDA XDE, 88A0h
	EXTZ XBC
	ADD XBC, XDE
	LD C, (XBC)
	EXTZ BC
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 84A4h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (XSP + 006h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, (XSP + 004h)
	JR C, DocFmtSlot_FormatLoop

DocFmtSlot_FillEmpty:
	CP IZ, 000ah
	JR NC, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	LD WA, IZ
	SLL 3, WA
	LDA XBC, 84A4h
	EXTZ XWA
	ADD XWA, XBC
	LD BC, 00ffh
	LD DE, IZ
	CALR FormatMedleyNumber
	LD DE, IZ
	SLL 3, DE
	LDA XWA, 84A4h
	EXTZ XDE
	ADD XDE, XWA
	LD XWA, (XSP + 006h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	INC 1, IZ
	CP IZ, 000ah
	JR C, DocFmtSlot_EmptyLoop

DocFmtSlot_Exit:
	POP XIZ
	INC 6, XSP
	RET

FmmDocMedleyFunc:
	PUSH XIZ
	LD XHL, XDE
	LD XDE, XBC
	LD XIZ, XWA
	CP XDE, 01e5000ah
	JRL Z, DocMed_CheckContinue
	LD XWA, XHL
	CP XDE, 01e50008h
	JRL Z, DocMed_StoreDelayFlag
	LD BC, (84FCh)
	CP XDE, 01c00018h
	JRL Z, DocMed_HandleNavToggle
	CP XDE, 01c00017h
	JRL Z, DocMed_HandleNavToggle
	CP XDE, 01c0000bh
	JRL Z, DocMed_RefreshDisplay
	CP XDE, 01e50004h
	JRL Z, DocMed_StoreWindowPtr
	CP XDE, 01c00013h
	JRL NZ, DocMed_Exit
	CP XHL, 00000003h
	JRL Z, DocMed_HandleStop
	CP XHL, 00000002h
	JRL NZ, DocMed_Exit
	LD WA, 0
	CALL InitializeOperationState
	LD A, (8D37h)
	CP A, 070h
	JR NZ, DocMed_CheckPlayMode
	LD (84FEh), 000h
	CALL LABEL_F2076D
	CP L, 2
	JRL C, DocMed_Exit
	LD (7F42h), 001h
	LD WA, 00eeh
	JRL T, DocMed_ShowError

DocMed_CheckPlayMode:
	CP A, 074h
	JRL NZ, DocMed_CheckInit
	CALL LABEL_F2076D
	CP L, 1
	JRL NZ, DocMed_HandleError
	LD (84FEh), 001h
	LD C, (8922h)
	LDA XWA, 88A0h
	CP C, (8920h)
	JR NC, DocMed_CheckRepeat
	LD HL, 0
	LD DE, (84FCh)
	CP DE, 0
	JRL ULE, DocMed_Exit

DocMed_FindSongLoop:
	LD IX, HL
	EXTZ XIX
	ADD XIX, XWA
	CP (XIX), C
	JR NZ, DocMed_NextSong
	EXTZ XHL
	LD XWA, XIZ
	LD XBC, 01e50002h
	LD XDE, XHL
	CALR FmmDocFileNameFunc
	LD XWA, (84F4h)
	LD BC, (84FCh)
	CALR DocMed_FormatSlotList
	INC 1, (8922h)
	LD XWA, (84F8h)
	OR XWA, XWA
	JRL Z, DocMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh
	JR T, DocMed_PostDelayEvent

DocMed_NextSong:
	INC 1, HL
	CP HL, DE
	JR C, DocMed_FindSongLoop
	JRL T, DocMed_Exit

DocMed_CheckRepeat:
	CP (8924h), 000h
	JR Z, DocMed_ClearPlaying
	LD (8922h), 000h
	LD HL, 0
	LD BC, (84FCh)
	CP BC, 0
	JRL ULE, DocMed_Exit

DocMed_RepeatFindLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XWA
	CP (XDE), 000h
	JR NZ, DocMed_RepeatNext
	EXTZ XHL
	LD XWA, XIZ
	LD XBC, 01e50002h
	LD XDE, XHL
	CALR FmmDocFileNameFunc
	LD XWA, (84F4h)
	LD BC, (84FCh)
	CALR DocMed_FormatSlotList
	INC 1, (8922h)
	LD XWA, (84F8h)
	OR XWA, XWA
	JRL Z, DocMed_Exit
	LD XBC, 01e50009h
	LD XDE, 0000001eh

DocMed_PostDelayEvent:
	CALL ApPostEvent
	JRL T, DocMed_Exit

DocMed_RepeatNext:
	INC 1, HL
	CP HL, BC
	JR C, DocMed_RepeatFindLoop
	JRL T, DocMed_Exit

DocMed_ClearPlaying:
	LD (84FEh), 000h
	JRL T, DocMed_Exit

DocMed_HandleError:
	CALL LABEL_F2076D
	LD (84FEh), 000h
	CP L, 0
	JRL Z, DocMed_Exit
	LD (7F42h), 001h
	LD WA, 00eeh

DocMed_ShowError:
	CALL LABEL_F994BD
	JRL T, DocMed_Exit

DocMed_CheckInit:
	CPW (8508h), 0000h
	JR LT, DocMed_InitFromDisk
	CPW (8504h), 0000h
	JR NZ, DocMed_InitState

DocMed_InitFromDisk:
	LDW (8504h), 0ffffh
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CALL LABEL_F8A9D6
	LD (8508h), HL
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	CALL SignalProgressUpdate

DocMed_InitState:
	LD (84FEh), 000h
	LD (8922h), 000h
	LD (8920h), 000h
	LD BC, 0080h
	LD WA, (8508h)
	CP WA, 0080h
	JR UGT, DocMed_ClampCount
	LD BC, WA

DocMed_ClampCount:
	LD (84FCh), BC
	LD HL, 0
	CP BC, 0
	JR ULE, DocMed_FinishInit
	LDA XWA, 88A0h

DocMed_ClearSlotsLoop:
	LD BC, HL
	EXTZ XBC
	ADD XBC, XWA
	LD (XBC), 0ffh
	INC 1, HL
	CP HL, (84FCh)
	JR C, DocMed_ClearSlotsLoop

DocMed_FinishInit:
	CALL LABEL_F20ACD
	LD XWA, 0
	LD (84F8h), XWA
	JRL T, DocMed_Exit

DocMed_HandleStop:
	LD A, (8D36h)
	CP A, 070h
	JRL Z, DocMed_Exit
	CP A, 074h
	JRL Z, DocMed_Exit
	CALL LABEL_F20B70
	CALL CancelOperationCleanup
	LD (84FEh), 000h
	JRL T, DocMed_Exit

DocMed_StoreWindowPtr:
	LD (84F4h), XWA
	JRL T, DocMed_Exit

DocMed_RefreshDisplay:
	LD XWA, (84F4h)
	CALR DocMed_FormatSlotList
	JRL T, DocMed_Exit

DocMed_HandleNavToggle:
	CP XHL, 0000000ah
	JRL NZ, DocMed_HandleSelectToggle
	CP (84FEh), 000h
	JR NZ, DocMed_HandleSelectToggle
	LD HL, 0
	LD WA, BC
	CP BC, 0
	JR ULE, DocMed_CheckAllUnmarked
	LDA XBC, 88A0h

DocMed_FindUnmarkedLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), 0ffh
	JR Z, DocMed_CheckAllUnmarked
	INC 1, HL
	CP HL, WA
	JR C, DocMed_FindUnmarkedLoop

DocMed_CheckAllUnmarked:
	CP HL, WA
	JR NC, DocMed_RemoveOrderLoop
	LD HL, 0
	CP WA, 0
	JR ULE, DocMed_RefreshAfterToggle
	LDA XDE, 88A0h

DocMed_AssignOrderLoop:
	LD BC, HL
	EXTZ XBC
	ADD XBC, XDE
	LD A, (XBC)
	CP A, 0ffh
	JR NZ, DocMed_NextAssign
	LD (XBC), (8920h)
	INC 1, (8920h)

DocMed_NextAssign:
	INC 1, HL
	CP HL, (84FCh)
	JR C, DocMed_AssignOrderLoop
	JR T, DocMed_RefreshAfterToggle

DocMed_RemoveOrderLoop:
	LD HL, 0
	CP WA, 0
	JR ULE, DocMed_RefreshAfterToggle
	LDA XDE, 88A0h

DocMed_UnmarkLoop:
	LD BC, HL
	EXTZ XBC
	ADD XBC, XDE
	LD A, (XBC)
	CP A, 0fdh
	JR UGT, DocMed_NextUnmark
	LD (XBC), 0ffh
	DEC 1, (8920h)

DocMed_NextUnmark:
	INC 1, HL
	CP HL, (84FCh)
	JR C, DocMed_UnmarkLoop

DocMed_RefreshAfterToggle:
	LD XWA, (84F4h)
	LD BC, (84FCh)
	JR T, DocMed_CallFormatSlots

DocMed_HandleSelectToggle:
	CP XHL, 0000000bh
	JR NZ, DocMed_HandleRepeat
	CP (84FEh), 000h
	JR NZ, DocMed_HandleRepeat
	LD XWA, XIZ
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmDocFileNameFunc
	LDA XIX, 88A0h
	EXTZ XHL
	ADD XHL, XIX
	LD C, (XHL)
	CP C, 0ffh
	JR NZ, DocMed_RemoveFromOrder
	LD (XHL), (8920h)
	INC 1, (8920h)
	JR T, DocMed_RefreshAfterSelect

DocMed_RemoveFromOrder:
	CP C, 0fdh
	JR UGT, DocMed_RefreshAfterSelect
	LD (XHL), 0ffh
	LD A, (8920h)
	DEC 1, A
	LD (8920h), A
	LD IZ, 0
	LD HL, 0
	EXTZ WA
	CP WA, 0
	JR ULE, DocMed_RefreshAfterSelect
	LD IY, WA

DocMed_ReorderLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XIX
	LD A, (XDE)
	CP A, 0fdh
	JR UGT, DocMed_NextReorder
	INC 1, IZ
	CP A, C
	JR ULE, DocMed_NextReorder
	DEC 1, A
	LD (XDE), A

DocMed_NextReorder:
	INC 1, HL
	CP IZ, IY
	JR C, DocMed_ReorderLoop

DocMed_RefreshAfterSelect:
	LD XWA, (84F4h)
	LD BC, (84FCh)

DocMed_CallFormatSlots:
	CALR DocMed_FormatSlotList
	JRL T, DocMed_Exit

DocMed_HandleRepeat:
	CP XHL, 0000000ch
	JR NZ, DocMed_HandlePlay
	CP XDE, 01c00017h
	JR NZ, DocMed_SetRepeatOff
	LD (8924h), 001h
	JRL T, DocMed_Exit

DocMed_SetRepeatOff:
	LD (8924h), 000h
	JRL T, DocMed_Exit

DocMed_HandlePlay:
	CP XHL, 0000000dh
	JRL NZ, DocMed_Exit
	CP (84FEh), 000h
	JRL NZ, DocMed_Exit
	LD (8922h), 000h
	LD HL, 0
	LD WA, (84FCh)
	CP WA, 0
	JR ULE, DocMed_CheckAutoPlay
	LDA XBC, 88A0h

DocMed_PlayFindLoop:
	LD DE, HL
	EXTZ XDE
	ADD XDE, XBC
	CP (XDE), 000h
	JR NZ, DocMed_PlayNextLoop
	LD (84FEh), 001h
	EXTZ XHL
	LD XWA, XIZ
	LD XBC, 01e50002h
	LD XDE, XHL
	CALR FmmDocFileNameFunc
	INC 1, (8922h)
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0074h
	CALL LABEL_F99490
	JR T, DocMed_CheckAutoPlay

DocMed_PlayNextLoop:
	INC 1, HL
	CP HL, WA
	JR C, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	CP (84FEh), 000h
	JR NZ, DocMed_Exit
	LD XWA, XIZ
	LD XBC, 01e50003h
	LD XDE, 0
	CALR FmmDocFileNameFunc
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0070h
	JR T, DocMed_CallPauseMode

DocMed_StoreDelayFlag:
	LD (84F8h), XWA
	JR T, DocMed_Exit

DocMed_CheckContinue:
	CP (84FEh), 000h
	JR Z, DocMed_Exit
	LD XWA, 0ffffffffh
	LD XBC, 01e0009ah
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 0074h

DocMed_CallPauseMode:
	CALL LABEL_F99490

DocMed_Exit:
	LD XHL, 0
	POP XIZ
	RET

SetSongSlotValue:
	CP WA, 000ah
	RET NC
	LDA XHL, 0AB000h
	LD DE, WA
	SLL 11, DE
	EXTZ XDE
	ADD XHL, XDE
	ADD XHL, 0000001ch
	LD (XHL), BC
	LD E, (0FFE3h:24)
	EXTZ DE
	CP DE, WA
	RET NZ
	LDA XHL, 0F180h:24
	ADD XHL, 0000001ch
	LD (XHL), BC
	RET

GetSongSlotValue:
	LD HL, 0
	CP WA, 000ah
	RET NC
	LDA XBC, 0AB000h
	SLL 11, WA
	EXTZ XWA
	ADD XBC, XWA
	ADD XBC, 0000001ch
	LD HL, (XBC)
	RET

CheckSongSlotHasData:
	CALR GetSongSlotValue
	CP HL, 0
	SCC NZ, HL
	RET

SongSlot_RawData:
	db 02Eh, 0D9h, 08Eh, 01Eh, 0D5h, 0FFh, 0DEh, 0F3h
	db 0DBh, 076h, 04Eh, 00Eh

FindFirstEmptySlot:
	PUSH IZ
	LD IZ, 0

FindEmpty_Loop:
	LD WA, IZ
	CALR GetSongSlotValue
	CP HL, 0
	JR NZ, FindEmpty_Exit
	INC 1, IZ
	CP IZ, 000ah
	JR C, FindEmpty_Loop

FindEmpty_Exit:
	POP IZ
	RET

ClearAllSongSlots:
	PUSH XIZ
	LD IZ, WA
	LD QIZ, 0

ClearSlots_Loop:
	LD WA, QIZ
	LD BC, IZ
	CALR SetSongSlotValue
	INC 1, QIZ
	CP QIZ, 000ah
	JR C, ClearSlots_Loop
	POP XIZ
	RET

ResetSlotsIfEmpty:
	CALR FindFirstEmptySlot
	LD WA, HL
	CP WA, 0
	RET Z
	CALR ClearAllSongSlots
	RET

CheckSlotIsSelected:
	PUSH IZ
	LD IZ, WA
	CALR FindFirstEmptySlot
	CP HL, IZ
	SCC Z, HL
	POP IZ
	RET

CheckAnySlotHasData:
	CALR FindFirstEmptySlot
	CP HL, 0
	SCC NZ, HL
	RET

SetCurrentSlotIndex:
	LD (09480Eh), WA
	RET

GetCurrentSlotIndex:
	LD HL, (09480Eh)
	RET

CheckIsCurrentSlot:
	PUSH IZ
	LD IZ, WA
	CALR GetCurrentSlotIndex
	CP HL, IZ
	SCC Z, HL
	POP IZ
	RET

CheckSlotIndexValid:
	CALR GetCurrentSlotIndex
	CP HL, 0
	SCC NZ, HL
	RET

InitializeCheap:
	LDA XSP, XSP - 14

	RegObjTable 01600004h, 0FA44E2h, 0EA1186h,	0EA0F46h, 0165h
	RegObjTable 0160000ch, 0FA58FBh, 0EA11F2h,	0EA1188h, 01c5h
	RegObjTable 0160000dh, 0FA5948h, 0EA1358h,	0EA11F4h, 01e5h
	RegObjTabl  01600002h, 0FA496Ch, 001dh,		0EA0A56h, 0125h
	RegObjTabl  01600002h, 0FA496Ch, 001dh,		0EA0ACEh, 0425h
	RegObjTabl  01600001h, 0FA48A9h, 000dh,		0EA135Ah, 0105h
	RegObjTabl  01600001h, 0FA48A9h, 000dh,		0EA1392h, 0405h
	RegObjTabl  01600003h, 0FA4A18h, 0039h,		0EA7FCEh, 0145h
	RegObjTabl  01600003h, 0FA4A18h, 0039h,		0EA80B6h, 0445h
	RegObjTabl  01600010h, 0FA5995h, 004ah,		0EA67B6h, 0060h
	RegObjTabl  0160000fh, 0FA62CBh, 004ah,		0EA6FE2h, 0360h
	RegObjTabl  01600010h, 0FA5995h, 0080h,		0EA68E2h, 0061h
	RegObjTabl  0160000fh, 0FA62CBh, 0080h,		0EA7228h, 0361h
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6AE6h, 0062h
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA75C6h, 0362h
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6AEAh, 0063h
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA75CCh, 0363h
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6AEEh, 0064h
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA75D2h, 0364h
	RegObjTabl  01600010h, 0FA5995h, 0003h,		0EA6AF2h, 0065h
	RegObjTabl  0160000fh, 0FA62CBh, 0003h,		0EA75D8h, 0365h
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6B02h, 0066h
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA75FCh, 0366h
	RegObjTabl  01600010h, 0FA5995h, 0047h,		0EA6B06h, 0067h
	RegObjTabl  0160000fh, 0FA62CBh, 0047h,		0EA7602h, 0367h
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6C26h, 006ah
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA77E4h, 036ah
	RegObjTabl  01600010h, 0FA5995h, 0015h,		0EA6C2Ah, 006bh
	RegObjTabl  0160000fh, 0FA62CBh, 0015h,		0EA77EAh, 036bh
	RegObjTabl  01600010h, 0FA5995h, 0053h,		0EA6C82h, 006ch
	RegObjTabl  0160000fh, 0FA62CBh, 0053h,		0EA7878h, 036ch
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6DD2h, 006dh
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA7ACAh, 036dh
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6DD6h, 006eh
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA7AD0h, 036eh
	RegObjTabl  01600010h, 0FA5995h, 0015h,		0EA6DDAh, 0077h
	RegObjTabl  0160000fh, 0FA62CBh, 0015h,		0EA7AD6h, 0377h
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6E32h, 0079h
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA7B8Ch, 0379h
	RegObjTabl  01600010h, 0FA5995h, 005eh,		0EA6E36h, 007bh
	RegObjTabl  0160000fh, 0FA62CBh, 005eh,		0EA7B92h, 037bh
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6FB2h, 007ch
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA7E98h, 037ch
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6FB6h, 007dh
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA7E9Eh, 037dh
	RegObjTabl  01600010h, 0FA5995h, 0008h,		0EA6FBAh, 007eh
	RegObjTabl  0160000fh, 0FA62CBh, 0008h,		0EA7EA4h, 037eh
	RegObjTabl  01600010h, 0FA5995h, 0000h,		0EA6FDEh, 00bch
	RegObjTabl  0160000fh, 0FA62CBh, 0000h,		0EA7EE2h, 03bch

	RegMode 0005h, 00eah, 7ee8h, 00000006h, 01200000h, 01a00060h

	RegTitle 0005h, 00eah, 7ef0h, 00000060h, 01200000h, 00600000h
	RegTitle 0005h, 00eah, 7efah, 00000061h, 01450027h, 00610000h
	RegTitle 0005h, 00eah, 7f02h, 00000062h, 01450036h, 00610069h
	RegTitle 0005h, 00eah, 7f10h, 00000063h, 01450037h, 0060002bh
	RegTitle 0005h, 00eah, 7f1ah, 00000064h, 01450029h, 0061004bh
	RegTitle 0005h, 00eah, 7f26h, 00000065h, 01200000h, 00650000h
	RegTitle 0005h, 00eah, 7f32h, 00000066h, 01200000h, 00600018h
	RegTitle 0005h, 00eah, 7f3eh, 00000067h, 01450028h, 00670000h
	RegTitle 0005h, 00eah, 7f46h, 0000006ah, 01200000h, 00600028h
	RegTitle 0005h, 00eah, 7f56h, 0000006bh, 0145002dh, 006b0000h
	RegTitle 0005h, 00eah, 7f62h, 0000006ch, 0145001ch, 006c0000h
	RegTitle 0005h, 00eah, 7f6eh, 0000006dh, 0145001eh, 006c0026h
	RegTitle 0005h, 00eah, 7f7ah, 0000006eh, 0145001dh, 006c003dh
	RegTitle 0005h, 00eah, 7f84h, 00000077h, 01450026h, 00770000h
	RegTitle 0005h, 00eah, 7f8eh, 00000079h, 01450011h, 0060000ah
	RegTitle 0005h, 00eah, 7f98h, 0000007bh, 01450031h, 007b0000h
	RegTitle 0005h, 00eah, 7fa0h, 0000007ch, 01450032h, 007b0019h
	RegTitle 0005h, 00eah, 7fach, 0000007dh, 01450021h, 007b0018h
	RegTitle 0005h, 00eah, 7fb8h, 0000007eh, 01200000h, 007e0000h
	RegTitle 0005h, 00eah, 7fc4h, 000000bch, 01450025h, 0060001bh

	LDA XSP, XSP + 14
	RET

PasswordText:
	CP XBC, 01e0009fh
	JR NZ, PasswordText_Exit
	LDA XHL, 0EA85C8h
	RET

PasswordText_Exit:
	LD XHL, 0
	RET

CheckPasswordText:
	CP XBC, 01e0009fh
	JR NZ, CheckPwd_Exit
	LD A, (02748Eh)
	CP A, 2
	JR Z, CheckPwd_Type2
	CP A, 1
	JR NZ, CheckPwd_Type0
	LD XHL, 00ea8832h
	JR T, CheckPwd_Return

CheckPwd_Type2:
	LD XHL, 00ea8a0ch
	JR T, CheckPwd_Return

CheckPwd_Type0:
	LD XHL, 00ea868eh

CheckPwd_Return:
	RET

CheckPwd_Exit:
	LD XHL, 0
	RET

WakeUpPassword:
	DEC 4, XSP
	PUSH XIZ
	LD (XSP + 004h), XDE
	LD XIZ, XWA
	CP XBC, 01c50004h
	JRL Z, WakeUp_StoreType
	CP XBC, 01c00007h
	JR Z, WakeUp_HandleOk
	CP XBC, 01c00001h
	JR Z, WakeUp_HandleInit
	CP XBC, 01c0000dh
	JR Z, WakeUp_HandleDirect
	CP XBC, 01e00085h
	JR Z, WakeUp_Return1
	LD XWA, XIZ
	LD XDE, (XSP + 004h)
	CALL InheritedProc
	JRL T, WakeUp_Exit

WakeUp_Return1:
	LD XHL, 1
	JRL T, WakeUp_Exit

WakeUp_HandleDirect:
	LD XWA, XIZ
	LD XDE, (XSP + 004h)
	CALL InheritedProc
	LD XWA, XIZ
	LD XBC, 01c0000fh
	LD XDE, 00ea8bf0h
	CALL SendEvent
	JRL T, WakeUp_ReturnZero

WakeUp_HandleInit:
	LD XWA, XIZ
	LD XDE, (XSP + 004h)
	CALL InheritedProc
	LD (02741Ah), 000h
	JRL T, WakeUp_ReturnZero

WakeUp_HandleOk:
	LD XWA, XIZ
	LD XDE, (XSP + 004h)
	CALL InheritedProc
	LD XWA, 00670001h
	LD XBC, 01e00056h
	LD XDE, 0
	CALL SendEvent
	CP XHL, 00000003h
	JR Z, WakeUp_ReturnZero
	LD XWA, (XSP + 004h)
	CP XWA, 0000008ch
	JR NZ, WakeUp_ClearCounter
	INC 1, (02741Ah)
	CP (02741Ah), 007h
	JR NZ, WakeUp_ReturnZero
	LD (02741Ah), 000h
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 1
	CALL PostEvent
	LD XWA, 00600040h
	LD XBC, 01c00001h
	LD XDE, 0
	JR T, WakeUp_PostEvent

WakeUp_ClearCounter:
	LD (02741Ah), 000h
	JR T, WakeUp_ReturnZero

WakeUp_StoreType:
	LD XWA, (XSP + 004h)
	LD (02748Eh), A
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 1
	CALL PostEvent
	LD XWA, 00600045h
	LD XBC, 01c00001h
	LD XDE, 0

WakeUp_PostEvent:
	CALL PostEvent

WakeUp_ReturnZero:
	LD XHL, 0

WakeUp_Exit:
	POP XIZ
	INC 4, XSP
	RET

PasswordOk:
	PUSH XIZ
	LD XIZ, XWA
	CP XBC, 01c00007h
	JR Z, PwdOk_HandleConfirm
	CP XBC, 01e0007ch
	JR Z, PwdOk_Return2
	CP XBC, 01e00084h
	JR Z, PwdOk_ReturnZero
	CP XBC, 01e0003ah
	JR NZ, PwdOk_ReturnZero
	PUSHW 00eah
	PUSHW 8bf6h
	PUSH XDE
	CALL LABEL_FF0F4D
	INC 8, XSP
	LD XHL, XIZ
	JR T, PwdOk_Exit

PwdOk_Return2:
	LD XHL, 2
	JR T, PwdOk_Exit

PwdOk_HandleConfirm:
	CALL GetNamingWindowID
	LD XWA, XHL
	LD XBC, 01e0003ah
	LD XDE, 0002741ch
	CALL SendEvent
	LD XWA, 00600040h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent
	LD DE, (02741Ch)
	EXTZ XDE
	LD XWA, 01450038h
	LD XBC, 01e5000dh
	CALL MainFuncCall

PwdOk_ReturnZero:
	LD XHL, 0

PwdOk_Exit:
	POP XIZ
	RET

CheckPasswordOk:
	PUSH XIZ
	LD XIZ, XWA
	CP XBC, 01c00007h
	JR Z, CheckOk_HandleConfirm
	CP XBC, 01e0007ch
	JR Z, CheckOk_Return2
	CP XBC, 01e00084h
	JRL Z, CheckOk_ReturnZero
	CP XBC, 01e0003ah
	JRL NZ, CheckOk_ReturnZero
	PUSHW 00eah
	PUSHW 8bfah
	PUSH XDE
	CALL LABEL_FF0F4D
	INC 8, XSP
	LD XHL, XIZ
	JRL T, CheckOk_Exit

CheckOk_Return2:
	LD XHL, 2
	JRL T, CheckOk_Exit

CheckOk_HandleConfirm:
	CALL GetNamingWindowID
	LD XWA, XHL
	LD XBC, 01e0003ah
	LD XDE, 00027424h
	CALL SendEvent
	LD XWA, 00600045h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent
	LD XWA, 00670001h
	LD XBC, 01e00056h
	LD XDE, 0
	CALL SendEvent
	LDA XWA, 027424h
	CP HL, 1
	JR NZ, CheckOk_Type2
	LD DE, (XWA)
	EXTZ XDE
	LD XWA, 01450038h
	LD XBC, 01e5000eh
	JR T, CheckOk_CallFunc

CheckOk_Type2:
	CP HL, 2
	JR NZ, CheckOk_Type3
	LD DE, (XWA)
	EXTZ XDE
	LD XWA, 01450038h
	LD XBC, 01e5000fh
	JR T, CheckOk_CallFunc

CheckOk_Type3:
	CP HL, 3
	JR NZ, CheckOk_ReturnZero
	LD DE, (XWA)
	EXTZ XDE
	LD XWA, 01450038h
	LD XBC, 01e50010h

CheckOk_CallFunc:
	CALL MainFuncCall

CheckOk_ReturnZero:
	LD XHL, 0

CheckOk_Exit:
	POP XIZ
	RET

PasswordNo:
	CP XBC, 01c00007h
	JR NZ, PwdNo_Exit
	LD XWA, 00600040h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent

PwdNo_Exit:
	LD XHL, 0
	RET

CheckPasswordNo:
	CP XBC, 01c00007h
	JR NZ, CheckNo_HandleConfirm
	LD XWA, 00600045h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent

CheckNo_HandleConfirm:
	LD XHL, 0
	RET

DiskAttention:
	CP XBC, 01e0009fh
	JR NZ, CheckNo_Type1
	LDA XHL, 0EA8BFEh
	RET

CheckNo_Type1:
	LD XHL, 0
	RET

DiskSure:
	CP XBC, 01e0009fh
	JR NZ, CheckNo_Type2
	LDA XHL, 0EA8C5Ch
	RET

CheckNo_Type2:
	LD XHL, 0
	RET

FormatText:
	CP XBC, 01e0009fh
	JR NZ, CheckNo_Type3
	LDA XHL, 0EA8CDCh
	RET

CheckNo_Type3:
	LD XHL, 0
	RET

DeleteText:
	CP XBC, 01e0009fh
	JR NZ, CheckNo_CallFunc
	LDA XHL, 0EA8E70h
	RET

CheckNo_CallFunc:
	LD XHL, 0
	RET

DeleteYes:
	CP XBC, 01c00007h
	JR NZ, PwdChange_HandleOk
	LD XWA, 007b0051h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c00017h
	LD XDE, 00000033h
	CALL PostEvent

PwdChange_HandleOk:
	LD XHL, 0
	RET

DeleteNo:
	CP XBC, 01c00007h
	JR NZ, PwdChange_Type1
	LD XWA, 007b0051h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent

PwdChange_Type1:
	LD XHL, 0
	RET

SaveText:
	CP XBC, 01e0009fh
	JR NZ, PwdChange_CallFunc
	LDA XHL, 0EA912Ah
	RET

PwdChange_CallFunc:
	LD XHL, 0
	RET

SaveYes:
	CP XBC, 01c00007h
	JR NZ, PwdDel_HandleOk
	LD XWA, 00600037h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c00017h
	LD XDE, 00000032h
	CALL PostEvent

PwdDel_HandleOk:
	LD XHL, 0
	RET

SaveNo:
	CP XBC, 01c00007h
	JR NZ, PwdDel_Type1
	LD XWA, 00600037h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL SendEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c50000h
	LD XDE, 0
	CALL PostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL PostEvent

PwdDel_Type1:
	LD XHL, 0
	RET

InsertOptionText:
	CP XBC, 01e0009fh
	JR NZ, PwdDel_Type2
	LDA XHL, 0EA943Ch
	RET

PwdDel_Type2:
	LD XHL, 0
	RET

TypePriorityText:
	CP XBC, 01e0009fh
	JR NZ, PwdDel_CallFunc
	LDA XHL, 0EA9558h
	RET

PwdDel_CallFunc:
	LD XHL, 0
	RET

