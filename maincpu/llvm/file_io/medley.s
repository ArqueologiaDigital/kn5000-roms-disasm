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
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01e50003h
	; (no addr) JRL Z, SeqName_GetIndexReturn
	; (no addr) LD HL, (82D8h)
	; (no addr) CP XBC, 01e50002h
	; (no addr) JRL Z, SeqName_SetIndexPlaying
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR Z, SeqName_HandleNavigation
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR Z, SeqName_HandleNavigation
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, SeqName_InitAllSlots
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, SeqName_ReturnZero
	; (no addr) LD (82D4h), XDE
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, SeqName_SendCurrentIndex
	; (no addr) LDW (82D8h), 0000h

SeqName_SendCurrentIndex:
	; (no addr) LD DE, (82D8h)
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) JRL T, SeqName_PostEventExit

SeqName_InitAllSlots:
	; (no addr) LD IZ, 0

SeqName_SendSlotLoop:
	; (no addr) LD BC, IZ
	; (no addr) LD WA, BC
	; (no addr) LD DE, 1
	CALR LABEL_F919E3
	; (no addr) LD XDE, XHL
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR LT, SeqName_SendSlotLoop

SeqName_ReturnZero:
	; (no addr) LD XHL, 0
	; (no addr) JRL T, SeqName_Exit

SeqName_HandleNavigation:
	; (no addr) LD WA, HL
	; (no addr) LD IZ, HL
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, SeqName_HandlePlayAction
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, SeqName_HandlePlayAction
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, SeqName_CheckPrevKey
	; (no addr) CP WA, 0009h
	; (no addr) JRL NC, SeqName_GetCurrentIndex
	; (no addr) INC 1, WA
	; (no addr) JR T, SeqName_UpdateIndex

SeqName_CheckPrevKey:
	; (no addr) CP XBC, 01c00017h
	; (no addr) JRL NZ, SeqName_GetCurrentIndex
	; (no addr) CP WA, 0
	; (no addr) JRL Z, SeqName_GetCurrentIndex
	; (no addr) DEC 1, WA

SeqName_UpdateIndex:
	; (no addr) LD (82D8h), WA
	; (no addr) LD DE, WA
	; (no addr) JRL T, SeqName_UpdateDisplay

SeqName_HandlePlayAction:
	; (no addr) CP XDE, 00000004h
	; (no addr) JRL NZ, SeqName_HandleAction32
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, SeqName_HandleAction32
	; (no addr) CALL CheckSongSlotHasData
	; (no addr) CP L, 0
	; (no addr) JR Z, SeqName_CheckDiskAvail
	; (no addr) LDA XWA, 8A0Ch
	; (no addr) BIT 7, (XWA + 001h)
	; (no addr) JR NZ, SeqName_CheckDiskAvail
	; (no addr) LD (XWA), 001h
	; (no addr) LD XDE, 1
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50004h
	; (no addr) JR T, SeqName_PostAndExit

SeqName_CheckDiskAvail:
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JR Z, SeqName_LoadAndPlay
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, SeqName_LoadAndPlay
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0

SeqName_PostAndExit:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, SeqName_GetCurrentIndex

SeqName_LoadAndPlay:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD WA, (82D8h)
	; (no addr) CALL LABEL_F880AD
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, SeqName_ShowAndExit

SeqName_HandleAction32:
	; (no addr) CP XDE, 00000032h
	; (no addr) JR NZ, SeqName_GetCurrentIndex
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD WA, (82D8h)
	; (no addr) CALL LABEL_F880AD
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh

SeqName_ShowAndExit:
	; (no addr) CALL LABEL_F994BD

SeqName_GetCurrentIndex:
	; (no addr) LD DE, (82D8h)

SeqName_UpdateDisplay:
	; (no addr) CP IZ, DE
	; (no addr) JRL Z, SeqName_ReturnZero
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, IZ
	; (no addr) LD BC, IZ
	; (no addr) LD DE, 1
	CALR LABEL_F919E3
	; (no addr) LD XDE, XHL
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LD BC, (82D8h)
	; (no addr) LD WA, BC
	; (no addr) LD DE, 1
	CALR LABEL_F919E3
	; (no addr) LD XDE, XHL
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) JR T, SeqName_PostEventExit

SeqName_SetIndexPlaying:
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL Z, SeqName_ReturnZero
	; (no addr) LD IZ, HL
	; (no addr) LD (82D8h), DE
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, IZ
	; (no addr) LD BC, IZ
	; (no addr) LD DE, 1
	CALR LABEL_F919E3
	; (no addr) LD XDE, XHL
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LD BC, (82D8h)
	; (no addr) LD WA, BC
	; (no addr) LD DE, 1
	CALR LABEL_F919E3
	; (no addr) LD XDE, XHL
	; (no addr) LD XWA, (82D4h)
	; (no addr) LD XBC, 01c0000fh

SeqName_PostEventExit:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, SeqName_ReturnZero

SeqName_GetIndexReturn:
	; (no addr) LD HL, (82D8h)
	; (no addr) EXTZ XHL

SeqName_Exit:
	; (no addr) POP IZ
	; (no addr) RET

FormatMedleyNumber:
	; (no addr) LD (XWA+), E
	; (no addr) CP C, 0ffh
	; (no addr) JR NZ, FmtNum_CheckMarked
	LD_C 0x20
	; (no addr) JR T, FmtNum_WriteSpacePad

FmtNum_CheckMarked:
	; (no addr) CP C, 0feh
	; (no addr) JR NZ, FmtNum_FormatNumber
	LD_C 0x4d

FmtNum_WriteSpacePad:
	; (no addr) LD (XWA+), C
	; (no addr) LD (XWA+), 020h
	; (no addr) LD (XWA), 020h
	; (no addr) RET

FmtNum_FormatNumber:
	; (no addr) INC 1, C
	; (no addr) CP C, 064h
	; (no addr) JR C, FmtNum_WriteM
	LDA_XHL_XWA_plus__e0__
	; (no addr) LD E, C
	; (no addr) EXTZ DE
	DIV_E 0x64
	; (no addr) ADD E, 030h
	; (no addr) LD (XHL), E
	; (no addr) EXTZ BC
	DIV_C 0x64
	; (no addr) LD C, B
	; (no addr) JR T, FmtNum_WriteTensUnits

FmtNum_WriteM:
	; (no addr) LD (XWA+), 04dh

FmtNum_WriteTensUnits:
	; (no addr) CP C, 00ah
	; (no addr) JR NC, FmtNum_WriteTwoDigits
	; (no addr) LD (XWA+), 030h
	; (no addr) ADD C, 030h
	; (no addr) LD (XWA), C
	; (no addr) RET

FmtNum_WriteTwoDigits:
	LDA_XHL_XWA_plus__e0__
	; (no addr) LD E, C
	; (no addr) EXTZ DE
	DIV_E 0xa
	; (no addr) ADD E, 030h
	; (no addr) LD (XHL), E
	; (no addr) EXTZ BC
	DIV_C 0xa
	; (no addr) LD C, B
	; (no addr) ADD C, 030h
	; (no addr) LD (XWA), C
	; (no addr) RET

FmmIntMedleyFunc:
	; (no addr) DEC 8, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 006h), XWA
	; (no addr) CP XBC, 01e5000ah
	; (no addr) JRL Z, IntMed_CheckContinue
	; (no addr) LD XWA, XDE
	; (no addr) CP XBC, 01e50008h
	; (no addr) JRL Z, IntMed_StoreDelayFlag
	; (no addr) CP XBC, 01c00018h
	; (no addr) JRL Z, IntMed_HandleNavToggle
	; (no addr) CP XBC, 01c00017h
	; (no addr) JRL Z, IntMed_HandleNavToggle
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JRL Z, IntMed_InitSlotDisplay
	; (no addr) CP XBC, 01e50004h
	; (no addr) JRL Z, IntMed_StoreWindowPtr
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, IntMed_Exit
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, IntMed_HandleStop
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, IntMed_Exit
	; (no addr) CP (8D37h), 07ah
	; (no addr) JR Z, IntMed_CheckPlaying
	; (no addr) CALL LABEL_F20ACD
	; (no addr) LD (84FEh), 000h
	; (no addr) LD (889Ch), 000h
	; (no addr) LD (889Ah), 000h
	; (no addr) LD IZ, 0

IntMed_CheckSlotLoop:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F2065A
	; (no addr) CP L, 0
	; (no addr) JR Z, IntMed_MarkSlotEmpty
	; (no addr) LDA XWA, 8890h
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD (XBC), (889Ah)
	; (no addr) INC 1, (889Ah)
	; (no addr) JR T, IntMed_NextSlot

IntMed_MarkSlotEmpty:
	; (no addr) LDA XWA, 8890h
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD (XBC), 0ffh

IntMed_NextSlot:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_CheckSlotLoop
	; (no addr) LD XWA, 0
	; (no addr) LD (82DEh), XWA
	; (no addr) JRL T, IntMed_Exit

IntMed_CheckPlaying:
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 1
	; (no addr) JRL NZ, IntMed_HandleError
	; (no addr) LD (84FEh), 001h
	; (no addr) LD A, (889Ch)
	; (no addr) CP A, (889Ah)
	; (no addr) JR NC, IntMed_CheckRepeat
	; (no addr) LD IZ, 0
	; (no addr) LDA XBC, 8890h

IntMed_FindCurrentSong:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), A
	; (no addr) JR NZ, IntMed_NextSongSearch
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01e50002h
	CALR FmmSeqSongNameFunc
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F20BCE
	; (no addr) INC 1, (889Ch)
	; (no addr) LD XWA, (82DEh)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, IntMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh
	; (no addr) JR T, IntMed_PostDelayEvent

IntMed_NextSongSearch:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_FindCurrentSong
	; (no addr) JRL T, IntMed_Exit

IntMed_CheckRepeat:
	; (no addr) CP (889Eh), 000h
	; (no addr) JR Z, IntMed_ClearPlayFlag
	; (no addr) LD (889Ch), 000h
	; (no addr) LD IZ, 0
	; (no addr) LDA XWA, 8890h

IntMed_PlayFromStart:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) CP (XBC), 000h
	; (no addr) JR NZ, IntMed_NextSongLoop
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01e50002h
	CALR FmmSeqSongNameFunc
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F20BCE
	; (no addr) INC 1, (889Ch)
	; (no addr) LD XWA, (82DEh)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, IntMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh

IntMed_PostDelayEvent:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, IntMed_Exit

IntMed_NextSongLoop:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_PlayFromStart
	; (no addr) JRL T, IntMed_Exit

IntMed_ClearPlayFlag:
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, IntMed_Exit

IntMed_HandleError:
	; (no addr) CALL LABEL_F2076D
	; (no addr) LD (84FEh), 000h
	; (no addr) CP L, 0
	; (no addr) JRL Z, IntMed_Exit
	; (no addr) LD (7F42h), 00eh
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, IntMed_Exit

IntMed_HandleStop:
	; (no addr) CP (8D36h), 07ah
	; (no addr) JRL Z, IntMed_Exit
	; (no addr) CALL LABEL_F20B70
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, IntMed_Exit

IntMed_StoreWindowPtr:
	; (no addr) LD (82DAh), XWA
	; (no addr) JRL T, IntMed_Exit

IntMed_InitSlotDisplay:
	; (no addr) LD IZ, 0

IntMed_FormatSlotLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 82E2h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LDA XBC, 8890h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD C, (XDE)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 82E2h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (82DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_FormatSlotLoop
	; (no addr) JRL T, IntMed_Exit

IntMed_HandleNavToggle:
	; (no addr) LDA XWA, 8890h
	; (no addr) CP XDE, 0000000ah
	; (no addr) JRL NZ, IntMed_HandleSelectToggle
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, IntMed_HandleSelectToggle
	; (no addr) LD IZ, 0

IntMed_FindMarkedSlot:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) CP (XBC), 0feh
	; (no addr) JR Z, IntMed_CheckAllMarked
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_FindMarkedSlot

IntMed_CheckAllMarked:
	; (no addr) CP IZ, 000ah
	; (no addr) JR NC, IntMed_RemoveOrderLoop
	; (no addr) LD IZ, 0

IntMed_AssignOrderLoop:
	; (no addr) LDA XWA, 8890h
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0feh
	; (no addr) JR NZ, IntMed_NextAssignSlot
	; (no addr) LD A, (889Ah)
	; (no addr) LD (XBC), A
	; (no addr) INC 1, (889Ah)
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XDE, 82E2h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XDE
	; (no addr) LD C, (XBC)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 82E2h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (82DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent

IntMed_NextAssignSlot:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_AssignOrderLoop
	; (no addr) JRL T, IntMed_Exit

IntMed_RemoveOrderLoop:
	; (no addr) LD IZ, 0

IntMed_UnmarkSlotLoop:
	; (no addr) LDA XWA, 8890h
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, IntMed_NextUnmark
	; (no addr) LD (XBC), 0feh
	; (no addr) DEC 1, (889Ah)
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XDE, 82E2h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XDE
	; (no addr) LD C, (XBC)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 82E2h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (82DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent

IntMed_NextUnmark:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_UnmarkSlotLoop
	; (no addr) JRL T, IntMed_Exit

IntMed_HandleSelectToggle:
	; (no addr) CP XDE, 0000000bh
	; (no addr) JRL NZ, IntMed_HandleRepeatToggle
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, IntMed_HandleRepeatToggle
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmSeqSongNameFunc
	; (no addr) LD IZ, HL
	; (no addr) LDA XWA, 8890h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LDA XBC, 82E2h
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 0feh
	; (no addr) JR NZ, IntMed_RemoveFromOrder
	; (no addr) LD C, (889Ah)
	; (no addr) LD (XDE), C
	; (no addr) INC 1, (889Ah)
	; (no addr) LD C, (XDE)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XBC, 82E2h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (82DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, IntMed_Exit

IntMed_RemoveFromOrder:
	; (no addr) CP C, 0fdh
	; (no addr) JRL UGT, IntMed_Exit
	; (no addr) LD (XSP + 004h), C
	; (no addr) LD (XDE), 0feh
	; (no addr) DEC 1, (889Ah)
	; (no addr) LD C, (XDE)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XBC, 82E2h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (82DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LDW (XSP + 002h:8), 0000h
	; (no addr) LD IZ, 0
	; (no addr) LD A, (889Ah)
	; (no addr) EXTZ WA
	; (no addr) CP WA, 0
	; (no addr) JRL ULE, IntMed_Exit

IntMed_ReorderLoop:
	; (no addr) LDA XWA, 8890h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 0fdh
	; (no addr) JR UGT, IntMed_NextReorder
	; (no addr) INCW 1, (XSP + 002h)
	; (no addr) CP C, (XSP + 004h)
	; (no addr) JR ULE, IntMed_NextReorder
	; (no addr) DEC 1, C
	; (no addr) LD (XDE), C
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XDE, 82E2h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XDE
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 82E2h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (82DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent

IntMed_NextReorder:
	; (no addr) INC 1, IZ
	; (no addr) LD A, (889Ah)
	; (no addr) EXTZ WA
	; (no addr) CP (XSP + 002h), WA
	; (no addr) JR C, IntMed_ReorderLoop
	; (no addr) JRL T, IntMed_Exit

IntMed_HandleRepeatToggle:
	; (no addr) CP XDE, 0000000ch
	; (no addr) JR NZ, IntMed_HandlePlay
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, IntMed_SetRepeatOff
	; (no addr) LD (889Eh), 001h
	; (no addr) JRL T, IntMed_Exit

IntMed_SetRepeatOff:
	; (no addr) LD (889Eh), 000h
	; (no addr) JRL T, IntMed_Exit

IntMed_HandlePlay:
	; (no addr) CP XDE, 0000000dh
	; (no addr) JRL NZ, IntMed_Exit
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, IntMed_Exit
	; (no addr) LD (889Ch), 000h
	; (no addr) LD IZ, 0

IntMed_StartPlayLoop:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) CP (XBC), 000h
	; (no addr) JR NZ, IntMed_NextPlaySlot
	; (no addr) LD (84FEh), 001h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01e50002h
	CALR FmmSeqSongNameFunc
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F20BCE
	; (no addr) INC 1, (889Ch)
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007ah
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, IntMed_Exit

IntMed_NextPlaySlot:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, IntMed_StartPlayLoop
	; (no addr) JR T, IntMed_Exit

IntMed_StoreDelayFlag:
	; (no addr) LD (82DEh), XWA
	; (no addr) JR T, IntMed_Exit

IntMed_CheckContinue:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR Z, IntMed_Exit
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007ah
	; (no addr) CALL UI_PostModeChangeEvent

IntMed_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) INC 8, XSP
	; (no addr) RET

FmmDiskMedley1Func:
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, DiskMed1_InitLoop
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, DiskMed1_Exit
	; (no addr) LD (8332h), XDE
	; (no addr) JR T, DiskMed1_Exit

DiskMed1_InitLoop:
	; (no addr) LD IZ, 0

DiskMed1_FormatLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 8336h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LDA XBC, 8926h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD C, (XDE)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 8336h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (8332h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, DiskMed1_FormatLoop

DiskMed1_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) RET

FmmDiskMedley2Func:
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, DiskMed2_InitLoop
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, DiskMed2_Exit
	; (no addr) LD (8386h), XDE
	; (no addr) JR T, DiskMed2_Exit

DiskMed2_InitLoop:
	; (no addr) LD IZ, 000ah

DiskMed2_FormatLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 00833Ah:24
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LDA XBC, 8926h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD C, (XDE)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	; (no addr) SUB DE, 000ah
	CALR FormatMedleyNumber
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 00833Ah:24
	; (no addr) LD DE, WA
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (8386h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JR C, DiskMed2_FormatLoop

DiskMed2_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) RET

DiskMed_PlayNextHelper:
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR Z, DiskMed_InitPlayOrder
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR Z, DiskMed_InitPlayOrder
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, DiskMed_ReturnZero
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, DiskMed_ReturnZero
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, DiskMed_ReturnZero
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL Z, DiskMed_ReturnZero
	; (no addr) LD A, (889Ch)
	; (no addr) CP A, (889Ah)
	; (no addr) JR NC, DiskMed_ReturnFinished
	; (no addr) LD IZ, 0
	; (no addr) LDA XBC, 8890h

DiskMed_FindSongLoop:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), A
	; (no addr) JR NZ, DiskMed_NextSong
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) JRL T, DiskMed_PlaySong

DiskMed_NextSong:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, DiskMed_FindSongLoop
	; (no addr) JRL T, DiskMed_ReturnZero

DiskMed_ReturnFinished:
	; (no addr) LD XHL, 2
	; (no addr) JRL T, DiskMed_HelperExit

DiskMed_InitPlayOrder:
	; (no addr) CP XDE, 0000000dh
	; (no addr) JRL NZ, DiskMed_ReturnZero
	; (no addr) LD (889Ch), 000h
	; (no addr) LD (889Ah), 000h
	; (no addr) LD (889Eh), 000h
	; (no addr) LD IZ, 0

DiskMed_CheckSlotLoop:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F2065A
	; (no addr) LDA XBC, 8890h
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) CP L, 0
	; (no addr) JR Z, DiskMed_MarkUnused
	; (no addr) LD (XWA), 0feh
	; (no addr) JR T, DiskMed_NextSlotCheck

DiskMed_MarkUnused:
	; (no addr) LD (XWA), 0ffh

DiskMed_NextSlotCheck:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, DiskMed_CheckSlotLoop
	; (no addr) CP (8940h), 000h
	; (no addr) JR Z, DiskMed_SingleSlotCheck
	; (no addr) LDA XHL, 8890h
	; (no addr) LD XBC, XHL
	; (no addr) LDA XDE, XHL + 00ah

DiskMed_AssignOrder:
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0feh
	; (no addr) JR NZ, DiskMed_NextAssign
	; (no addr) LD (XBC), (889Ah)
	; (no addr) INC 1, (889Ah)

DiskMed_NextAssign:
	; (no addr) INC 1, XBC
	; (no addr) CP XBC, XDE
	; (no addr) JR C, DiskMed_AssignOrder
	; (no addr) LD IZ, 0

DiskMed_FindFirstSong:
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XHL
	; (no addr) LD A, (XWA)
	; (no addr) CP A, (889Ch)
	; (no addr) JR NZ, DiskMed_NextFirst
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) JR T, DiskMed_PlaySong

DiskMed_NextFirst:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, DiskMed_FindFirstSong
	; (no addr) JR T, DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	; (no addr) LDA XBC, 8890h
	; (no addr) CP (XBC), 0feh
	; (no addr) JR NZ, DiskMed_SingleSlotInit
	; (no addr) LD (XBC), (889Ah)
	; (no addr) INC 1, (889Ah)

DiskMed_SingleSlotInit:
	; (no addr) LD IZ, 0

DiskMed_FindFirstLoop:
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD A, (XWA)
	; (no addr) CP A, (889Ch)
	; (no addr) JR NZ, DiskMed_NextFindFirst
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA

DiskMed_PlaySong:
	; (no addr) CALL LABEL_F20BCE
	; (no addr) INC 1, (889Ch)
	; (no addr) LD XHL, 1
	; (no addr) JR T, DiskMed_HelperExit

DiskMed_NextFindFirst:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, DiskMed_FindFirstLoop

DiskMed_ReturnZero:
	; (no addr) LD XHL, 0

DiskMed_HelperExit:
	; (no addr) POP IZ
	; (no addr) RET

FmmDiskMedleySelectFunc:
	; (no addr) LDA XSP, XSP - 14
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 006h), XDE
	; (no addr) LD (XSP + 00ah), XBC
	; (no addr) LD (XSP + 00eh), XWA
	; (no addr) LD XWA, (XSP + 00ah)
	; (no addr) CP XWA, 01c00018h
	; (no addr) JRL Z, DiskSel_HandleNavigation
	; (no addr) CP XWA, 01c00017h
	; (no addr) JRL Z, DiskSel_HandleNavigation
	; (no addr) CP XWA, 01c0000bh
	; (no addr) JRL Z, DiskSel_InitDisplay
	; (no addr) CP XWA, 01e50004h
	; (no addr) JRL Z, DiskSel_StoreWindowPtr
	; (no addr) CP XWA, 01c00013h
	; (no addr) JRL NZ, DiskSel_Exit
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000003h
	; (no addr) JRL Z, DiskSel_HandleStopEvent
	; (no addr) CP XWA, 00000002h
	; (no addr) JRL NZ, DiskSel_Exit
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CP (8D37h), 078h
	; (no addr) JRL Z, DiskSel_CheckPlaying
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, DiskSel_InitState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	CALR SignalProgressUpdate

DiskSel_InitState:
	; (no addr) LD (84FEh), 000h
	; (no addr) LD (893Ch), 000h
	; (no addr) LD (893Ah), 000h
	; (no addr) LD IZ, 0

DiskSel_CheckFileLoop:
	; (no addr) LD WA, IZ
	; (no addr) LD BC, 2
	; (no addr) CALL LABEL_F89408
	; (no addr) CP L, 0
	; (no addr) JR NZ, DiskSel_FileAvailable
	; (no addr) LD WA, IZ
	; (no addr) LD BC, 0008h
	; (no addr) CALL LABEL_F89408
	; (no addr) CP L, 0
	; (no addr) JR Z, DiskSel_MarkUnavail

DiskSel_FileAvailable:
	; (no addr) LDA XWA, 8926h
	; (no addr) LD (XWA + IZ), (893Ah)
	; (no addr) INC 1, (893Ah)
	; (no addr) JR T, DiskSel_NextFile

DiskSel_MarkUnavail:
	; (no addr) LDA XWA, 8926h
	; (no addr) LD (XWA + IZ), 0ffh

DiskSel_NextFile:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JR LT, DiskSel_CheckFileLoop
	; (no addr) CALL LABEL_F20ACD
	; (no addr) JRL T, DiskSel_Exit

DiskSel_CheckPlaying:
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 1
	; (no addr) JRL NZ, DiskSel_HandleError
	; (no addr) LD (84FEh), 001h
	; (no addr) LD XWA, (XSP + 00eh)
	; (no addr) LD XBC, (XSP + 00ah)
	; (no addr) LD XDE, (XSP + 006h)
	CALR DiskMed_PlayNextHelper
	; (no addr) CP L, 1
	; (no addr) JR NZ, DiskSel_CheckFinished
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0078h
	; (no addr) JRL T, DiskSel_CallPauseMode

DiskSel_CheckFinished:
	; (no addr) CP L, 2
	; (no addr) JRL NZ, DiskSel_Exit
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (893Ch)
	; (no addr) CP A, (893Ah)
	; (no addr) JRL NC, DiskSel_CheckRepeat
	; (no addr) LD IZ, 0

DiskSel_ClearSelections:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89321
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0008h
	; (no addr) JR LT, DiskSel_ClearSelections
	; (no addr) LD IZ, 0

DiskSel_FindSongLoop:
	; (no addr) LDA XWA, 8926h
	; (no addr) LD A, (XWA + IZ)
	; (no addr) CP A, (893Ch)
	; (no addr) JRL NZ, DiskSel_NextSongLoop
	; (no addr) LD (83DEh), IZ
	; (no addr) LD WA, IZ
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) LD DE, (83DEh)
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD QIZ, 0

DiskSel_SendFileInfo:
	; (no addr) LD DE, QIZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, QIZ
	; (no addr) CP QIZ, 0014h
	; (no addr) JR LT, DiskSel_SendFileInfo
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDiskMedley1Func
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDiskMedley2Func
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 00770008h
	CALR DiskNameFunc
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 00770009h
	CALR DiskInfoFunc
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F87A08
	; (no addr) LD QIZ, HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CP QIZ, 0
	; (no addr) JR GE, DiskSel_PlayNext
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 0060h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD WA, QIZ
	; (no addr) LD BC, 1
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, DiskSel_ShowErrorAndExit

DiskSel_PlayNext:
	; (no addr) INC 1, (893Ch)
	; (no addr) LD XWA, (XSP + 00eh)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 0000000dh
	CALR DiskMed_PlayNextHelper
	; (no addr) CP L, 1
	; (no addr) JR NZ, DiskSel_NextSongLoop
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0078h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, DiskSel_ClearPlaying

DiskSel_NextSongLoop:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JRL LT, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, DiskSel_Exit

DiskSel_CheckRepeat:
	; (no addr) CP (893Eh), 000h
	; (no addr) JR Z, DiskSel_ClearPlaying
	; (no addr) LD (893Ch), 000h
	; (no addr) LD IZ, 0

DiskSel_RepeatClear:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89321
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0008h
	; (no addr) JR LT, DiskSel_RepeatClear
	; (no addr) LD IZ, 0

DiskSel_RepeatFindLoop:
	; (no addr) LDA XWA, 8926h
	; (no addr) LD A, (XWA + IZ)
	; (no addr) CP A, (893Ch)
	; (no addr) JRL NZ, DiskSel_RepeatNext
	; (no addr) LD (83DEh), IZ
	; (no addr) LD WA, IZ
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) LD DE, (83DEh)
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD QIZ, 0

DiskSel_RepeatSendInfo:
	; (no addr) LD DE, QIZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, QIZ
	; (no addr) CP QIZ, 0014h
	; (no addr) JR LT, DiskSel_RepeatSendInfo
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDiskMedley1Func
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDiskMedley2Func
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 00770008h
	CALR DiskNameFunc
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 00770009h
	CALR DiskInfoFunc
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F87A08
	; (no addr) LD QIZ, HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CP QIZ, 0
	; (no addr) JR GE, DiskSel_RepeatPlayNext
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 0060h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD WA, QIZ
	; (no addr) LD BC, 1
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, DiskSel_ShowErrorAndExit

DiskSel_RepeatPlayNext:
	; (no addr) INC 1, (893Ch)
	; (no addr) LD XWA, (XSP + 00eh)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 0000000dh
	CALR DiskMed_PlayNextHelper
	; (no addr) CP L, 1
	; (no addr) JR NZ, DiskSel_RepeatNext
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0078h

DiskSel_CallPauseMode:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JRL T, DiskSel_Exit

DiskSel_RepeatNext:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JRL LT, DiskSel_RepeatFindLoop
	; (no addr) JRL T, DiskSel_Exit

DiskSel_HandleError:
	; (no addr) CALL LABEL_F2076D
	; (no addr) LD (84FEh), 000h
	; (no addr) CP L, 0
	; (no addr) JR NZ, DiskSel_ShowError
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, DiskSel_Exit

DiskSel_ShowError:
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 00eh
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, DiskSel_ShowErrorAndExit

DiskSel_HandleStopEvent:
	; (no addr) CP (8D36h), 078h
	; (no addr) JR Z, DiskSel_PostStopEvent
	; (no addr) CALL LABEL_F20B70
	; (no addr) LD (84FEh), 000h

DiskSel_PostStopEvent:
	CALR CancelOperationCleanup
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) JRL T, DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD (83DAh), XWA
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD (83DEh), HL
	; (no addr) CP HL, 0
	; (no addr) JR LT, DiskSel_DefaultIndex
	; (no addr) EXTS XHL
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	; (no addr) JRL T, DiskSel_PostEvent

DiskSel_DefaultIndex:
	; (no addr) LDW (83DEh), 0000h
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, 0
	; (no addr) JRL T, DiskSel_PostEvent

DiskSel_InitDisplay:
	; (no addr) LD IZ, 0

DiskSel_DisplayLoop:
	; (no addr) LD WA, IZ
	; (no addr) LD HL, WA
	; (no addr) SLL 5, HL
	; (no addr) LDA XDE, 850Ch
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XDE
	; (no addr) LD C, IZL
	; (no addr) LD (XHL), C
	; (no addr) LD BC, 2
	; (no addr) CALL LABEL_F89408
	; (no addr) LD WA, IZ
	; (no addr) CP L, 0
	; (no addr) JR NZ, DiskSel_GetFileName
	; (no addr) LD BC, 0008h
	; (no addr) CALL LABEL_F89408
	; (no addr) CP L, 0
	; (no addr) JR Z, DiskSel_EmptyFileName
	; (no addr) LD WA, IZ

DiskSel_GetFileName:
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) JR T, DiskSel_FormatEntry

DiskSel_EmptyFileName:
	; (no addr) LDA XBC, 0EA0A54h

DiskSel_FormatEntry:
	; (no addr) LD DE, IZ
	; (no addr) LD WA, DE
	; (no addr) SLL 5, WA
	; (no addr) LD HL, 1
	; (no addr) ADD HL, WA
	; (no addr) LDA XIX, 850Ch
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XIX
	; (no addr) INC 1, DE
	; (no addr) PUSHW 0006h
	; (no addr) PUSHW 0000h
	; (no addr) LD XWA, XHL
	; (no addr) CALL LABEL_F891DD
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JR LT, DiskSel_DisplayLoop
	; (no addr) JRL T, DiskSel_Exit

DiskSel_HandleNavigation:
	; (no addr) LD DE, (83DEh)
	; (no addr) LD (XSP + 004h), DE
	; (no addr) LD XBC, (XSP + 00ah)
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) OR XWA, XWA
	; (no addr) JR NZ, DiskSel_CheckPage
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DiskSel_CheckPage
	; (no addr) LD XWA, XBC
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, DiskSel_CheckPrevKey
	; (no addr) CP DE, 0013h
	; (no addr) JRL GE, DiskSel_GetCurrentIndex
	; (no addr) INC 1, DE
	; (no addr) JR T, DiskSel_SaveIndex

DiskSel_CheckPrevKey:
	; (no addr) CP XWA, 01c00017h
	; (no addr) JRL NZ, DiskSel_GetCurrentIndex
	; (no addr) CP DE, 0
	; (no addr) JRL LE, DiskSel_GetCurrentIndex
	; (no addr) DEC 1, DE
	; (no addr) JR T, DiskSel_SaveIndex

DiskSel_CheckPage:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000001h
	; (no addr) JR NZ, DiskSel_CheckPageDown
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DiskSel_CheckPageDown
	; (no addr) CP DE, 000ah
	; (no addr) JRL LT, DiskSel_GetCurrentIndex
	; (no addr) SUB DE, 000ah
	; (no addr) JR T, DiskSel_SaveIndex

DiskSel_CheckPageDown:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000002h
	; (no addr) JR NZ, DiskSel_HandleToggle
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DiskSel_HandleToggle
	; (no addr) LD WA, DE
	; (no addr) ADD WA, 000ah
	; (no addr) CP WA, 0013h
	; (no addr) JRL GT, DiskSel_GetCurrentIndex
	; (no addr) ADD DE, 000ah

DiskSel_SaveIndex:
	; (no addr) LD (83DEh), DE
	; (no addr) JRL T, DiskSel_UpdateDisplay

DiskSel_HandleToggle:
	; (no addr) LDA XHL, 8926h
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 0000000ah
	; (no addr) JR NZ, DiskSel_HandleSelect
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DiskSel_HandleSelect
	; (no addr) LD IZ, 0

DiskSel_FindMarkedLoop:
	; (no addr) CP (XHL + IZ), 0feh
	; (no addr) JR Z, DiskSel_ToggleStart
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JR LT, DiskSel_FindMarkedLoop

DiskSel_ToggleStart:
	; (no addr) LDA XDE, XHL + 014h
	; (no addr) CP IZ, 0014h
	; (no addr) JR GE, DiskSel_UnmarkLoop

DiskSel_AssignLoop:
	; (no addr) LD A, (XHL)
	; (no addr) CP A, 0feh
	; (no addr) JR NZ, DiskSel_NextAssign
	; (no addr) LD (XHL), (893Ah)
	; (no addr) INC 1, (893Ah)

DiskSel_NextAssign:
	; (no addr) INC 1, XHL
	; (no addr) CP XHL, XDE
	; (no addr) JR C, DiskSel_AssignLoop
	; (no addr) JR T, DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	; (no addr) LD A, (XHL)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, DiskSel_NextUnmark
	; (no addr) LD (XHL), 0feh
	; (no addr) DEC 1, (893Ah)

DiskSel_NextUnmark:
	; (no addr) INC 1, XHL
	; (no addr) CP XHL, XDE
	; (no addr) JR C, DiskSel_UnmarkLoop

DiskSel_RefreshDisplay:
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDiskMedley1Func
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	; (no addr) JR T, DiskSel_RefreshBoth

DiskSel_HandleSelect:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 0000000bh
	; (no addr) JR NZ, DiskSel_HandleRepeat
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DiskSel_HandleRepeat
	; (no addr) LD XIX, XHL
	; (no addr) LDA XBC, XHL + DE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0feh
	; (no addr) JR NZ, DiskSel_RemoveSelect
	; (no addr) LD (XBC), (893Ah)
	; (no addr) INC 1, (893Ah)
	; (no addr) JR T, DiskSel_RefreshAfterSelect

DiskSel_RemoveSelect:
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, DiskSel_RefreshAfterSelect
	; (no addr) CP DE, 0014h
	; (no addr) JR GE, DiskSel_ReorderSlots
	; (no addr) LD (XBC), 0feh
	; (no addr) DEC 1, (893Ah)

DiskSel_ReorderSlots:
	; (no addr) LD XDE, XIX
	; (no addr) LDA XHL, XIX + 014h

DiskSel_ReorderLoop:
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 0fdh
	; (no addr) JR UGT, DiskSel_NextReorder
	; (no addr) CP C, A
	; (no addr) JR ULE, DiskSel_NextReorder
	; (no addr) DEC 1, C
	; (no addr) LD (XDE), C

DiskSel_NextReorder:
	; (no addr) INC 1, XDE
	; (no addr) CP XDE, XHL
	; (no addr) JR C, DiskSel_ReorderLoop

DiskSel_RefreshAfterSelect:
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDiskMedley1Func
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0

DiskSel_RefreshBoth:
	CALR FmmDiskMedley2Func
	; (no addr) JRL T, DiskSel_GetCurrentIndex

DiskSel_HandleRepeat:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 0000000ch
	; (no addr) JR NZ, DiskSel_HandlePlayStart
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, DiskSel_SetRepeatOff
	; (no addr) LD (893Eh), 001h
	; (no addr) JRL T, DiskSel_GetCurrentIndex

DiskSel_SetRepeatOff:
	; (no addr) LD (893Eh), 000h
	; (no addr) JRL T, DiskSel_GetCurrentIndex

DiskSel_HandlePlayStart:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 0000000dh
	; (no addr) JRL NZ, DiskSel_HandleAllCheck
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, DiskSel_HandleAllCheck
	; (no addr) LD (893Ch), 000h
	; (no addr) LD IZ, 0

DiskSel_PlayClearLoop:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89321
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0008h
	; (no addr) JR LT, DiskSel_PlayClearLoop
	; (no addr) LD IZ, 0

DiskSel_PlayFindLoop:
	; (no addr) LDA XWA, 8926h
	; (no addr) LD A, (XWA + IZ)
	; (no addr) CP A, (893Ch)
	; (no addr) JRL NZ, DiskSel_PlayNextLoop
	; (no addr) LD (83DEh), IZ
	; (no addr) LD WA, IZ
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) LD DE, (83DEh)
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL LABEL_F87A08
	; (no addr) LD QIZ, HL
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CP QIZ, 0
	; (no addr) JR GE, DiskSel_PlayNextSong
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 0060h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD WA, QIZ
	; (no addr) LD BC, 1
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) LD WA, 00eeh

DiskSel_ShowErrorAndExit:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, DiskSel_Exit

DiskSel_PlayNextSong:
	; (no addr) LDW (XSP + 004h), (83DEh)
	; (no addr) INC 1, (893Ch)
	; (no addr) LD XWA, (XSP + 00eh)
	; (no addr) LD XBC, (XSP + 00ah)
	; (no addr) LD XDE, (XSP + 006h)
	CALR DiskMed_PlayNextHelper
	; (no addr) CP L, 1
	; (no addr) JR NZ, DiskSel_PlayNextLoop
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0078h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, DiskSel_GetCurrentIndex

DiskSel_PlayNextLoop:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JRL LT, DiskSel_PlayFindLoop
	; (no addr) JR T, DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 0000000eh
	; (no addr) JR NZ, DiskSel_GetCurrentIndex
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, DiskSel_SetAllOff
	; (no addr) LD (8940h), 001h
	; (no addr) JR T, DiskSel_GetCurrentIndex

DiskSel_SetAllOff:
	; (no addr) LD (8940h), 000h

DiskSel_GetCurrentIndex:
	; (no addr) LD DE, (83DEh)

DiskSel_UpdateDisplay:
	; (no addr) CP (XSP + 004h), DE
	; (no addr) JR Z, DiskSel_Exit
	; (no addr) LD WA, DE
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) LD DE, (83DEh)
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD DE, (XSP + 004h)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LD DE, (83DEh)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (83DAh)
	; (no addr) LD XBC, 01c0000fh

DiskSel_PostEvent:
	; (no addr) CALL ApPostEvent

DiskSel_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) LDA XSP, XSP + 00eh
	; (no addr) RET

GetPlayState1:
	; (no addr) LD L, (8942h)
	; (no addr) RET

GetPlayState2:
	; (no addr) LD L, (8944h)
	; (no addr) RET

SmfMedley_RawData:
	.byte 0xC9, 0xD8, 0xD8, 0x7E, 0xF1, 0x44, 0x89, 0x41
	.byte 0xE

NavigateSongList:
	; (no addr) DEC 2, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), WA
	; (no addr) CPW (XSP + 002h), 0001h
	; (no addr) JR Z, NavSong_CheckBounds
	; (no addr) CPW (XSP + 002h), 0ffffh
	; (no addr) JR NZ, NavSong_Exit

NavSong_CheckBounds:
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR LE, NavSong_Exit
	; (no addr) CALL LABEL_F89AC7
	; (no addr) CP HL, 0
	; (no addr) JR LT, NavSong_Exit
	; (no addr) LD IZ, HL
	; (no addr) ADD IZ, (XSP + 002h)
	; (no addr) JR GE, NavSong_WrapToEnd
	; (no addr) LD IZ, (8504h)
	; (no addr) DEC 1, IZ
	; (no addr) JR T, NavSong_CheckEnd

NavSong_WrapToEnd:
	; (no addr) CP IZ, (8504h)
	; (no addr) JR LT, NavSong_CheckEnd
	; (no addr) LD IZ, 0

NavSong_CheckEnd:
	; (no addr) CP HL, IZ
	; (no addr) JR Z, NavSong_Exit
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F89BA4
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F8A07F

NavSong_Exit:
	; (no addr) POP IZ
	; (no addr) INC 2, XSP
	; (no addr) RET

NavigateDocList:
	; (no addr) PUSH IZ
	; (no addr) LD IZ, WA
	; (no addr) CP IZ, 1
	; (no addr) JR Z, NavDoc_CheckBounds
	; (no addr) CP IZ, 0ffffh
	; (no addr) JR NZ, NavDoc_Exit

NavDoc_CheckBounds:
	; (no addr) CPW (8508h), 0000h
	; (no addr) JR LE, NavDoc_Exit
	; (no addr) CALL LABEL_F8A7CE
	; (no addr) CP HL, 0
	; (no addr) JR LT, NavDoc_Exit
	; (no addr) LD WA, HL
	; (no addr) ADD WA, IZ
	; (no addr) JR GE, NavDoc_WrapToEnd
	; (no addr) LD WA, (8508h)
	; (no addr) DEC 1, WA
	; (no addr) JR T, NavDoc_CheckEnd

NavDoc_WrapToEnd:
	; (no addr) CP WA, (8508h)
	; (no addr) JR LT, NavDoc_CheckEnd
	; (no addr) LD WA, 0

NavDoc_CheckEnd:
	; (no addr) CP HL, WA
	; (no addr) CALL NZ, LABEL_F8A956

NavDoc_Exit:
	; (no addr) POP IZ
	; (no addr) RET

NavigatePdList:
	; (no addr) PUSH IZ
	; (no addr) LD IZ, WA
	; (no addr) CP IZ, 1
	; (no addr) JR Z, NavPd_CheckBounds
	; (no addr) CP IZ, 0ffffh
	; (no addr) JR NZ, NavPd_Exit

NavPd_CheckBounds:
	; (no addr) CPW (8506h), 0000h
	; (no addr) JR LE, NavPd_Exit
	; (no addr) CALL LABEL_F8A4C8
	; (no addr) CP HL, 0
	; (no addr) JR LT, NavPd_Exit
	; (no addr) LD WA, HL
	; (no addr) ADD WA, IZ
	; (no addr) JR GE, NavPd_WrapToEnd
	; (no addr) LD WA, (8506h)
	; (no addr) DEC 1, WA
	; (no addr) JR T, NavPd_CheckEnd

NavPd_WrapToEnd:
	; (no addr) CP WA, (8506h)
	; (no addr) JR LT, NavPd_CheckEnd
	; (no addr) LD WA, 0

NavPd_CheckEnd:
	; (no addr) CP HL, WA
	; (no addr) CALL NZ, LABEL_F8A5A5

NavPd_Exit:
	; (no addr) POP IZ
	; (no addr) RET

SmfMed_FormatSlotList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD IZ, BC
	; (no addr) LD (XSP + 006h), XWA
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmSmfFileNameFunc
	; (no addr) LD QIZ, HL
	; (no addr) LD WA, QIZ
	; (no addr) EXTZ XWA
	DIVW_WA 0xa
	; (no addr) LD QIZ, WA
	MULW_WA 0xa
	; (no addr) LD QIZ, WA
	; (no addr) LDW (XSP + 004h:8), 000ah
	; (no addr) LD WA, QIZ
	; (no addr) ADD WA, 000ah
	; (no addr) CP WA, IZ
	; (no addr) JR C, SmfFmt_CalcVisible
	; (no addr) LD (XSP + 004h), IZ
	; (no addr) LD WA, QIZ
	; (no addr) SUB (XSP + 004h), WA

SmfFmt_CalcVisible:
	; (no addr) LD IZ, 0
	; (no addr) CPW (XSP + 004h), 0000h
	; (no addr) JR ULE, SmfFmt_FillEmpty

SmfFmt_FormatLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 83E0h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, QIZ
	; (no addr) ADD BC, IZ
	; (no addr) LDA XDE, 88A0h
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD C, (XBC)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 83E0h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, (XSP + 004h)
	; (no addr) JR C, SmfFmt_FormatLoop

SmfFmt_FillEmpty:
	; (no addr) CP IZ, 000ah
	; (no addr) JR NC, SmfFmt_Exit

SmfFmt_EmptyLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 83E0h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, 00ffh
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 83E0h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, SmfFmt_EmptyLoop

SmfFmt_Exit:
	; (no addr) POP XIZ
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmSmfMedleyFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH IZ
	; (no addr) LD XHL, XBC
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) CP XHL, 01e5000ah
	; (no addr) JRL Z, SmfMed_CheckContinue
	; (no addr) LD XWA, XDE
	; (no addr) CP XHL, 01e50008h
	; (no addr) JRL Z, SmfMed_StoreDelayFlag
	; (no addr) LD BC, (8438h)
	; (no addr) CP XHL, 01c00018h
	; (no addr) JRL Z, SmfMed_HandleNavToggle
	; (no addr) CP XHL, 01c00017h
	; (no addr) JRL Z, SmfMed_HandleNavToggle
	; (no addr) CP XHL, 01c0000bh
	; (no addr) JRL Z, SmfMed_RefreshDisplay
	; (no addr) CP XHL, 01e50004h
	; (no addr) JRL Z, SmfMed_StoreWindowPtr
	; (no addr) CP XHL, 01c00013h
	; (no addr) JRL NZ, SmfMed_Exit
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, SmfMed_HandleStop
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, SmfMed_Exit
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD A, (8D37h)
	; (no addr) LD (843Ah), A
	; (no addr) CP A, 06fh
	; (no addr) JR Z, SmfMed_CheckNotPlaying
	; (no addr) CP A, 072h
	; (no addr) JR NZ, SmfMed_CheckPlayMode

SmfMed_CheckNotPlaying:
	; (no addr) LD (84FEh), 000h
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 4
	; (no addr) JR Z, SmfMed_Error3F
	; (no addr) CP L, 3
	; (no addr) JR Z, SmfMed_Error31
	; (no addr) CP L, 2
	; (no addr) JRL NZ, SmfMed_Exit
	; (no addr) LD (7F42h), 001h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, SmfMed_ShowError

SmfMed_Error31:
	; (no addr) LD (7F42h), 031h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, SmfMed_ShowError

SmfMed_Error3F:
	; (no addr) LD (7F42h), 03fh
	; (no addr) LD WA, 00eeh

SmfMed_ShowError:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, SmfMed_Exit

SmfMed_CheckPlayMode:
	; (no addr) CP A, 073h
	; (no addr) JR Z, SmfMed_CheckPlaying
	; (no addr) CP A, 076h
	; (no addr) JRL NZ, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 1
	; (no addr) JRL C, SmfMed_CheckNotPlayError
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 4
	; (no addr) JR Z, SmfMed_PlayError3F
	; (no addr) CP L, 3
	; (no addr) JR Z, SmfMed_PlayError31
	; (no addr) CP L, 2
	; (no addr) JR NZ, SmfMed_SetPlaying
	; (no addr) LD (7F42h), 001h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, SmfMed_ShowPlayError

SmfMed_PlayError31:
	; (no addr) LD (7F42h), 031h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, SmfMed_ShowPlayError

SmfMed_PlayError3F:
	; (no addr) LD (7F42h), 03fh
	; (no addr) LD WA, 00eeh

SmfMed_ShowPlayError:
	; (no addr) CALL LABEL_F994BD
	; (no addr) INC 1, (843Ch)

SmfMed_SetPlaying:
	; (no addr) LD (84FEh), 001h
	; (no addr) LD A, (8922h)
	; (no addr) CP A, (8920h)
	; (no addr) JR NC, SmfMed_CheckRepeat
	; (no addr) LD IZ, 0
	; (no addr) LD BC, (8438h)
	; (no addr) CP BC, 0
	; (no addr) JRL ULE, SmfMed_Exit
	; (no addr) LDA XDE, 88A0h

SmfMed_FindSongLoop:
	; (no addr) LD HL, IZ
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XDE
	; (no addr) CP (XHL), A
	; (no addr) JR NZ, SmfMed_NextSong
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01e50002h
	CALR FmmSmfFileNameFunc
	; (no addr) LD XWA, (8430h)
	; (no addr) LD BC, (8438h)
	CALR SmfMed_FormatSlotList
	; (no addr) INC 1, (8922h)
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F8A07F
	; (no addr) LD XWA, (8434h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, SmfMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh
	; (no addr) JR T, SmfMed_PostDelayEvent

SmfMed_NextSong:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, BC
	; (no addr) JR C, SmfMed_FindSongLoop
	; (no addr) JRL T, SmfMed_Exit

SmfMed_CheckRepeat:
	; (no addr) CP (8924h), 000h
	; (no addr) JR Z, SmfMed_ClearRepeatCount
	; (no addr) CP (843Ch), A
	; (no addr) JR NC, SmfMed_ClearRepeatCount
	; (no addr) LD (8922h), 000h
	; (no addr) LD (843Ch), 000h
	; (no addr) LD IZ, 0
	; (no addr) LD WA, (8438h)
	; (no addr) CP WA, 0
	; (no addr) JRL ULE, SmfMed_Exit
	; (no addr) LDA XBC, 88A0h

SmfMed_RepeatFindLoop:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), 000h
	; (no addr) JR NZ, SmfMed_RepeatNext
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01e50002h
	CALR FmmSmfFileNameFunc
	; (no addr) LD XWA, (8430h)
	; (no addr) LD BC, (8438h)
	CALR SmfMed_FormatSlotList
	; (no addr) INC 1, (8922h)
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F8A07F
	; (no addr) LD XWA, (8434h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, SmfMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh

SmfMed_PostDelayEvent:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, SmfMed_Exit

SmfMed_RepeatNext:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, WA
	; (no addr) JR C, SmfMed_RepeatFindLoop
	; (no addr) JRL T, SmfMed_Exit

SmfMed_ClearRepeatCount:
	; (no addr) LD (843Ch), 000h
	; (no addr) JR T, SmfMed_ClearPlaying

SmfMed_CheckNotPlayError:
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 0
	; (no addr) JRL NZ, SmfMed_Exit

SmfMed_ClearPlaying:
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, SmfMed_Exit

SmfMed_InitFromDisk:
	; (no addr) LD XDE, 0
	; (no addr) LD E, (8944h)
	; (no addr) LD XWA, 006c0018h
	; (no addr) LD XBC, 01e0003bh
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR GE, SmfMed_InitState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	CALR SignalProgressUpdate

SmfMed_InitState:
	; (no addr) LD (84FEh), 000h
	; (no addr) LD (8922h), 000h
	; (no addr) LD (8920h), 000h
	; (no addr) LD BC, 0080h
	; (no addr) LD WA, (8504h)
	; (no addr) CP WA, 0080h
	; (no addr) JR UGT, SmfMed_ClampFileCount
	; (no addr) LD BC, WA

SmfMed_ClampFileCount:
	; (no addr) LD (8438h), BC
	; (no addr) LD IZ, 0
	; (no addr) CP BC, 0
	; (no addr) JR ULE, SmfMed_FinishInit
	; (no addr) LDA XWA, 88A0h

SmfMed_ClearSlotsLoop:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD (XBC), 0ffh
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, (8438h)
	; (no addr) JR C, SmfMed_ClearSlotsLoop

SmfMed_FinishInit:
	; (no addr) CALL LABEL_F20ACD
	; (no addr) LD XWA, 0
	; (no addr) LD (8434h), XWA
	; (no addr) JRL T, SmfMed_Exit

SmfMed_HandleStop:
	; (no addr) LD A, (8D36h)
	; (no addr) CP A, 06fh
	; (no addr) JRL Z, SmfMed_Exit
	; (no addr) CP A, 072h
	; (no addr) JRL Z, SmfMed_Exit
	; (no addr) CP A, 073h
	; (no addr) JRL Z, SmfMed_Exit
	; (no addr) CP A, 076h
	; (no addr) JRL Z, SmfMed_Exit
	; (no addr) CALL LABEL_F20B70
	CALR CancelOperationCleanup
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, SmfMed_Exit

SmfMed_StoreWindowPtr:
	; (no addr) LD (8430h), XWA
	; (no addr) JRL T, SmfMed_Exit

SmfMed_RefreshDisplay:
	; (no addr) LD XWA, (8430h)
	CALR SmfMed_FormatSlotList
	; (no addr) JRL T, SmfMed_Exit

SmfMed_HandleNavToggle:
	; (no addr) LDA XWA, 88A0h
	; (no addr) CP XDE, 0000000ah
	; (no addr) JR NZ, SmfMed_HandleSelectToggle
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, SmfMed_HandleSelectToggle
	; (no addr) LD IZ, 0
	; (no addr) LD DE, BC
	; (no addr) CP BC, 0
	; (no addr) JR ULE, SmfMed_CheckAllUnmarked

SmfMed_FindUnmarkedLoop:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) CP (XBC), 0ffh
	; (no addr) JR Z, SmfMed_CheckAllUnmarked
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, DE
	; (no addr) JR C, SmfMed_FindUnmarkedLoop

SmfMed_CheckAllUnmarked:
	; (no addr) CP IZ, DE
	; (no addr) JR NC, SmfMed_RemoveOrderLoop
	; (no addr) LD IZ, 0
	; (no addr) CP DE, 0
	; (no addr) JR ULE, SmfMed_RefreshAfterToggle
	; (no addr) LDA XDE, 88A0h

SmfMed_AssignOrderLoop:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0ffh
	; (no addr) JR NZ, SmfMed_NextAssign
	; (no addr) LD (XBC), (8920h)
	; (no addr) INC 1, (8920h)

SmfMed_NextAssign:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, (8438h)
	; (no addr) JR C, SmfMed_AssignOrderLoop
	; (no addr) JR T, SmfMed_RefreshAfterToggle

SmfMed_RemoveOrderLoop:
	; (no addr) LD IZ, 0
	; (no addr) CP DE, 0
	; (no addr) JR ULE, SmfMed_RefreshAfterToggle
	; (no addr) LDA XDE, 88A0h

SmfMed_UnmarkLoop:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, SmfMed_NextUnmark
	; (no addr) LD (XBC), 0ffh
	; (no addr) DEC 1, (8920h)

SmfMed_NextUnmark:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, (8438h)
	; (no addr) JR C, SmfMed_UnmarkLoop

SmfMed_RefreshAfterToggle:
	; (no addr) LD XWA, (8430h)
	; (no addr) LD BC, (8438h)
	; (no addr) JR T, SmfMed_CallFormatSlots

SmfMed_HandleSelectToggle:
	; (no addr) CP XDE, 0000000bh
	; (no addr) JR NZ, SmfMed_HandleRepeat
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, SmfMed_HandleRepeat
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmSmfFileNameFunc
	; (no addr) LD IZ, HL
	; (no addr) LDA XHL, 88A0h
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XHL
	; (no addr) LD C, (XWA)
	; (no addr) CP C, 0ffh
	; (no addr) JR NZ, SmfMed_RemoveFromOrder
	; (no addr) LD (XWA), (8920h)
	; (no addr) INC 1, (8920h)
	; (no addr) JR T, SmfMed_RefreshAfterSelect

SmfMed_RemoveFromOrder:
	; (no addr) CP C, 0fdh
	; (no addr) JR UGT, SmfMed_RefreshAfterSelect
	; (no addr) LD (XWA), 0ffh
	; (no addr) LD A, (8920h)
	; (no addr) DEC 1, A
	; (no addr) LD (8920h), A
	; (no addr) LD IY, 0
	; (no addr) LD IZ, 0
	; (no addr) EXTZ WA
	; (no addr) CP WA, 0
	; (no addr) JR ULE, SmfMed_RefreshAfterSelect
	; (no addr) LD IX, WA

SmfMed_ReorderLoop:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XHL
	; (no addr) LD A, (XDE)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, SmfMed_NextReorder
	; (no addr) INC 1, IY
	; (no addr) CP A, C
	; (no addr) JR ULE, SmfMed_NextReorder
	; (no addr) DEC 1, A
	; (no addr) LD (XDE), A

SmfMed_NextReorder:
	; (no addr) INC 1, IZ
	; (no addr) CP IY, IX
	; (no addr) JR C, SmfMed_ReorderLoop

SmfMed_RefreshAfterSelect:
	; (no addr) LD XWA, (8430h)
	; (no addr) LD BC, (8438h)

SmfMed_CallFormatSlots:
	CALR SmfMed_FormatSlotList
	; (no addr) JRL T, SmfMed_Exit

SmfMed_HandleRepeat:
	; (no addr) CP XDE, 0000000ch
	; (no addr) JR NZ, SmfMed_HandlePlay
	; (no addr) CP XHL, 01c00017h
	; (no addr) JR NZ, SmfMed_SetRepeatOff
	; (no addr) LD (8924h), 001h
	; (no addr) JRL T, SmfMed_Exit

SmfMed_SetRepeatOff:
	; (no addr) LD (8924h), 000h
	; (no addr) JRL T, SmfMed_Exit

SmfMed_HandlePlay:
	; (no addr) CP XDE, 0000000dh
	; (no addr) JRL NZ, SmfMed_Exit
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, SmfMed_Exit
	; (no addr) LD (8922h), 000h
	; (no addr) LD (843Ch), 000h
	; (no addr) LD IZ, 0
	; (no addr) LD BC, (8438h)
	; (no addr) CP BC, 0
	; (no addr) JR ULE, SmfMed_CheckAutoPlay

SmfMed_PlayFindLoop:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) CP (XDE), 000h
	; (no addr) JR NZ, SmfMed_PlayNextLoop
	; (no addr) LD (84FEh), 001h
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01e50002h
	CALR FmmSmfFileNameFunc
	; (no addr) INC 1, (8922h)
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F8A07F
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0073h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, SmfMed_CheckAutoPlay

SmfMed_PlayNextLoop:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, BC
	; (no addr) JR C, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, SmfMed_Exit
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmSmfFileNameFunc
	; (no addr) LD IZ, HL
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F8A07F
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 006fh
	; (no addr) JR T, SmfMed_CallPauseMode

SmfMed_StoreDelayFlag:
	; (no addr) LD (8434h), XWA
	; (no addr) JR T, SmfMed_Exit

SmfMed_CheckContinue:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR Z, SmfMed_Exit
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (843Ah)
	; (no addr) EXTZ WA

SmfMed_CallPauseMode:
	; (no addr) CALL UI_PostModeChangeEvent

SmfMed_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) INC 4, XSP
	; (no addr) RET

PdMed_FormatFileList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), BC
	; (no addr) LD (XSP + 004h), XWA
	; (no addr) LD IZ, 0

PdFmt_FormatLoop:
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD A, IZL
	; (no addr) LD (XDE), A
	; (no addr) LD WA, (XSP + 002h)
	; (no addr) ADD WA, IZ
	; (no addr) CALL LABEL_F8A5F1
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
	; (no addr) PUSHW 0014h
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
	; (no addr) JR LT, PdFmt_FormatLoop
	; (no addr) POP IZ
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmPdFileNameFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) CP XBC, 01e50003h
	; (no addr) JRL Z, PdName_GetIndexReturn
	; (no addr) LD WA, (8442h)
	; (no addr) LD IZ, WA
	; (no addr) CP XBC, 01e50002h
	; (no addr) JRL Z, PdName_SetIndexPlaying
	; (no addr) LD HL, WA
	; (no addr) EXTS XHL
	DIVS_HL 0xa
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR Z, PdName_HandleNavigation
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR Z, PdName_HandleNavigation
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, PdName_RefreshList
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, PdName_ReturnZero
	; (no addr) LD (843Eh), XDE
	; (no addr) CALL LABEL_F8A4C8
	; (no addr) LD (8442h), HL
	; (no addr) CP HL, 0
	; (no addr) JR GE, PdName_UpdateIndex
	; (no addr) LDW (8442h), 0000h

PdName_UpdateIndex:
	; (no addr) LD WA, (8442h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (843Eh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) JRL T, PdName_PostEvent

PdName_RefreshList:
	MULS_HL 0xa
	; (no addr) LD XWA, (843Eh)
	; (no addr) LD BC, HL
	CALR PdMed_FormatFileList

PdName_ReturnZero:
	; (no addr) LD XHL, 0
	; (no addr) JRL T, PdName_Exit

PdName_HandleNavigation:
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, PdName_CheckPageUp
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, PdName_CheckPageUp
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, PdName_CheckPrevKey
	; (no addr) LD BC, WA
	; (no addr) INC 1, BC
	; (no addr) CP BC, (8506h)
	; (no addr) JR GE, PdName_GetCurrentIndex
	; (no addr) INC 1, WA
	; (no addr) JR T, PdName_SaveIndex

PdName_CheckPrevKey:
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, PdName_GetCurrentIndex
	; (no addr) CP WA, 0
	; (no addr) JR LE, PdName_GetCurrentIndex
	; (no addr) DEC 1, WA
	; (no addr) JR T, PdName_SaveIndex

PdName_CheckPageUp:
	; (no addr) CP XDE, 00000001h
	; (no addr) JR NZ, PdName_CheckPageDown
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, PdName_CheckPageDown
	; (no addr) CP WA, 000ah
	; (no addr) JR LT, PdName_GetCurrentIndex
	; (no addr) SUB WA, 000ah
	; (no addr) JR T, PdName_SaveIndex

PdName_CheckPageDown:
	; (no addr) CP XDE, 00000002h
	; (no addr) JR NZ, PdName_GetCurrentIndex
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, PdName_GetCurrentIndex
	; (no addr) LD BC, WA
	; (no addr) ADD BC, 000ah
	; (no addr) LD DE, (8506h)
	; (no addr) CP BC, DE
	; (no addr) JR GE, PdName_CheckEndBound
	; (no addr) ADD WA, 000ah

PdName_SaveIndex:
	; (no addr) LD (8442h), WA
	; (no addr) JR T, PdName_UpdateDisplay

PdName_CheckEndBound:
	; (no addr) LD BC, DE
	; (no addr) DEC 1, BC
	; (no addr) LD WA, BC
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) CP HL, WA
	; (no addr) JR GE, PdName_GetCurrentIndex
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD WA, QDE
	; (no addr) CP WA, 0
	; (no addr) JR Z, PdName_GetCurrentIndex
	; (no addr) LD (8442h), BC

PdName_GetCurrentIndex:
	; (no addr) LD WA, (8442h)

PdName_UpdateDisplay:
	; (no addr) CP IZ, WA
	; (no addr) JRL Z, PdName_ReturnZero
	; (no addr) CALL LABEL_F8A5A5
	; (no addr) LD WA, (8442h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (843Eh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD BC, (8442h)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	; (no addr) LD DE, IZ
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD XWA, (843Eh)
	; (no addr) CP DE, BC
	; (no addr) JR NZ, PdName_RefreshPage
	; (no addr) LD BC, IZ
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
	; (no addr) LD WA, (8442h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD WA, QWA
	; (no addr) SLL 5, WA
	; (no addr) LDA XBC, 850Ch
	; (no addr) LD DE, WA
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (843Eh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, PdName_ReturnZero

PdName_RefreshPage:
	MULS_BC 0xa
	CALR PdMed_FormatFileList
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmPdMedleyFunc
	; (no addr) JRL T, PdName_ReturnZero

PdName_SetIndexPlaying:
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL Z, PdName_ReturnZero
	; (no addr) LD (8442h), DE
	; (no addr) LD WA, DE
	; (no addr) CALL LABEL_F8A5A5
	; (no addr) LD WA, (8442h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (843Eh)
	; (no addr) LD XBC, 01e50002h

PdName_PostEvent:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, PdName_ReturnZero

PdName_GetIndexReturn:
	; (no addr) LD HL, (8442h)
	; (no addr) EXTS XHL

PdName_Exit:
	; (no addr) POP IZ
	; (no addr) INC 4, XSP
	; (no addr) RET

PdMed_FormatSlotList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD IZ, BC
	; (no addr) LD (XSP + 006h), XWA
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmPdFileNameFunc
	; (no addr) LD QIZ, HL
	; (no addr) LD WA, QIZ
	; (no addr) EXTZ XWA
	DIVW_WA 0xa
	; (no addr) LD QIZ, WA
	MULW_WA 0xa
	; (no addr) LD QIZ, WA
	; (no addr) LDW (XSP + 004h:8), 000ah
	; (no addr) LD WA, QIZ
	; (no addr) ADD WA, 000ah
	; (no addr) CP WA, IZ
	; (no addr) JR C, PdFmtSlot_CalcVisible
	; (no addr) LD (XSP + 004h), IZ
	; (no addr) LD WA, QIZ
	; (no addr) SUB (XSP + 004h), WA

PdFmtSlot_CalcVisible:
	; (no addr) LD IZ, 0
	; (no addr) CPW (XSP + 004h), 0000h
	; (no addr) JR ULE, PdFmtSlot_FillEmpty

PdFmtSlot_FormatLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 8444h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, QIZ
	; (no addr) ADD BC, IZ
	; (no addr) LDA XDE, 88A0h
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD C, (XBC)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 8444h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, (XSP + 004h)
	; (no addr) JR C, PdFmtSlot_FormatLoop

PdFmtSlot_FillEmpty:
	; (no addr) CP IZ, 000ah
	; (no addr) JR NC, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 8444h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, 00ffh
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 8444h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, PdFmtSlot_EmptyLoop

PdFmtSlot_Exit:
	; (no addr) POP XIZ
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmPdMedleyFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XHL, XDE
	; (no addr) LD XDE, XBC
	; (no addr) LD XIZ, XWA
	; (no addr) CP XDE, 01e5000ah
	; (no addr) JRL Z, PdMed_CheckContinue
	; (no addr) LD XWA, XHL
	; (no addr) CP XDE, 01e50008h
	; (no addr) JRL Z, PdMed_StoreDelayFlag
	; (no addr) LD BC, (849Ch)
	; (no addr) CP XDE, 01c00018h
	; (no addr) JRL Z, PdMed_HandleNavToggle
	; (no addr) CP XDE, 01c00017h
	; (no addr) JRL Z, PdMed_HandleNavToggle
	; (no addr) CP XDE, 01c0000bh
	; (no addr) JRL Z, PdMed_RefreshDisplay
	; (no addr) CP XDE, 01e50004h
	; (no addr) JRL Z, PdMed_StoreWindowPtr
	; (no addr) CP XDE, 01c00013h
	; (no addr) JRL NZ, PdMed_Exit
	; (no addr) CP XHL, 00000003h
	; (no addr) JRL Z, PdMed_HandleStop
	; (no addr) CP XHL, 00000002h
	; (no addr) JRL NZ, PdMed_Exit
	; (no addr) LD WA, 0
	; (no addr) CALL InitializeOperationState
	; (no addr) LD A, (8D37h)
	; (no addr) CP A, 071h
	; (no addr) JR NZ, PdMed_CheckPlayMode
	; (no addr) LD (84FEh), 000h
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 2
	; (no addr) JRL C, PdMed_Exit
	; (no addr) LD (7F42h), 001h
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, PdMed_ShowError

PdMed_CheckPlayMode:
	; (no addr) CP A, 075h
	; (no addr) JRL NZ, PdMed_InitFromDisk
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 1
	; (no addr) JRL NZ, PdMed_HandleError
	; (no addr) LD (84FEh), 001h
	; (no addr) LD C, (8922h)
	; (no addr) LDA XWA, 88A0h
	; (no addr) CP C, (8920h)
	; (no addr) JR NC, PdMed_CheckRepeat
	; (no addr) LD HL, 0
	; (no addr) LD DE, (849Ch)
	; (no addr) CP DE, 0
	; (no addr) JRL ULE, PdMed_Exit

PdMed_FindSongLoop:
	; (no addr) LD IX, HL
	; (no addr) EXTZ XIX
	; (no addr) ADD XIX, XWA
	; (no addr) CP (XIX), C
	; (no addr) JR NZ, PdMed_NextSong
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	CALR FmmPdFileNameFunc
	; (no addr) LD XWA, (8494h)
	; (no addr) LD BC, (849Ch)
	CALR PdMed_FormatSlotList
	; (no addr) INC 1, (8922h)
	; (no addr) LD XWA, (8498h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, PdMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh
	; (no addr) JR T, PdMed_PostDelayEvent

PdMed_NextSong:
	; (no addr) INC 1, HL
	; (no addr) CP HL, DE
	; (no addr) JR C, PdMed_FindSongLoop
	; (no addr) JRL T, PdMed_Exit

PdMed_CheckRepeat:
	; (no addr) CP (8924h), 000h
	; (no addr) JR Z, PdMed_ClearPlaying
	; (no addr) LD (8922h), 000h
	; (no addr) LD HL, 0
	; (no addr) LD BC, (849Ch)
	; (no addr) CP BC, 0
	; (no addr) JRL ULE, PdMed_Exit

PdMed_RepeatFindLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) CP (XDE), 000h
	; (no addr) JR NZ, PdMed_RepeatNext
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	CALR FmmPdFileNameFunc
	; (no addr) LD XWA, (8494h)
	; (no addr) LD BC, (849Ch)
	CALR PdMed_FormatSlotList
	; (no addr) INC 1, (8922h)
	; (no addr) LD XWA, (8498h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, PdMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh

PdMed_PostDelayEvent:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, PdMed_Exit

PdMed_RepeatNext:
	; (no addr) INC 1, HL
	; (no addr) CP HL, BC
	; (no addr) JR C, PdMed_RepeatFindLoop
	; (no addr) JRL T, PdMed_Exit

PdMed_ClearPlaying:
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, PdMed_Exit

PdMed_HandleError:
	; (no addr) CALL LABEL_F2076D
	; (no addr) LD (84FEh), 000h
	; (no addr) CP L, 0
	; (no addr) JRL Z, PdMed_Exit
	; (no addr) LD (7F42h), 001h
	; (no addr) LD WA, 00eeh

PdMed_ShowError:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, PdMed_Exit

PdMed_InitFromDisk:
	; (no addr) CPW (8506h), 0000h
	; (no addr) JR GE, PdMed_InitState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL LABEL_F8A625
	; (no addr) LD (8506h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CALL SignalProgressUpdate

PdMed_InitState:
	; (no addr) LD (84FEh), 000h
	; (no addr) LD (8922h), 000h
	; (no addr) LD (8920h), 000h
	; (no addr) LD BC, 0080h
	; (no addr) LD WA, (8506h)
	; (no addr) CP WA, 0080h
	; (no addr) JR UGT, PdMed_ClampCount
	; (no addr) LD BC, WA

PdMed_ClampCount:
	; (no addr) LD (849Ch), BC
	; (no addr) LD HL, 0
	; (no addr) CP BC, 0
	; (no addr) JR ULE, PdMed_FinishInit
	; (no addr) LDA XWA, 88A0h

PdMed_ClearSlotsLoop:
	; (no addr) LD BC, HL
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD (XBC), 0ffh
	; (no addr) INC 1, HL
	; (no addr) CP HL, (849Ch)
	; (no addr) JR C, PdMed_ClearSlotsLoop

PdMed_FinishInit:
	; (no addr) CALL LABEL_F20ACD
	; (no addr) LD XWA, 0
	; (no addr) LD (8498h), XWA
	; (no addr) JRL T, PdMed_Exit

PdMed_HandleStop:
	; (no addr) LD A, (8D36h)
	; (no addr) CP A, 071h
	; (no addr) JRL Z, PdMed_Exit
	; (no addr) CP A, 075h
	; (no addr) JRL Z, PdMed_Exit
	; (no addr) CALL LABEL_F20B70
	; (no addr) CALL CancelOperationCleanup
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, PdMed_Exit

PdMed_StoreWindowPtr:
	; (no addr) LD (8494h), XWA
	; (no addr) JRL T, PdMed_Exit

PdMed_RefreshDisplay:
	; (no addr) LD XWA, (8494h)
	CALR PdMed_FormatSlotList
	; (no addr) JRL T, PdMed_Exit

PdMed_HandleNavToggle:
	; (no addr) CP XHL, 0000000ah
	; (no addr) JRL NZ, PdMed_HandleSelectToggle
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, PdMed_HandleSelectToggle
	; (no addr) LD HL, 0
	; (no addr) LD WA, BC
	; (no addr) CP BC, 0
	; (no addr) JR ULE, PdMed_CheckAllUnmarked
	; (no addr) LDA XBC, 88A0h

PdMed_FindUnmarkedLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), 0ffh
	; (no addr) JR Z, PdMed_CheckAllUnmarked
	; (no addr) INC 1, HL
	; (no addr) CP HL, WA
	; (no addr) JR C, PdMed_FindUnmarkedLoop

PdMed_CheckAllUnmarked:
	; (no addr) CP HL, WA
	; (no addr) JR NC, PdMed_RemoveOrderLoop
	; (no addr) LD HL, 0
	; (no addr) CP WA, 0
	; (no addr) JR ULE, PdMed_RefreshAfterToggle
	; (no addr) LDA XDE, 88A0h

PdMed_AssignOrderLoop:
	; (no addr) LD BC, HL
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0ffh
	; (no addr) JR NZ, PdMed_NextAssign
	; (no addr) LD (XBC), (8920h)
	; (no addr) INC 1, (8920h)

PdMed_NextAssign:
	; (no addr) INC 1, HL
	; (no addr) CP HL, (849Ch)
	; (no addr) JR C, PdMed_AssignOrderLoop
	; (no addr) JR T, PdMed_RefreshAfterToggle

PdMed_RemoveOrderLoop:
	; (no addr) LD HL, 0
	; (no addr) CP WA, 0
	; (no addr) JR ULE, PdMed_RefreshAfterToggle
	; (no addr) LDA XDE, 88A0h

PdMed_UnmarkLoop:
	; (no addr) LD BC, HL
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, PdMed_NextUnmark
	; (no addr) LD (XBC), 0ffh
	; (no addr) DEC 1, (8920h)

PdMed_NextUnmark:
	; (no addr) INC 1, HL
	; (no addr) CP HL, (849Ch)
	; (no addr) JR C, PdMed_UnmarkLoop

PdMed_RefreshAfterToggle:
	; (no addr) LD XWA, (8494h)
	; (no addr) LD BC, (849Ch)
	; (no addr) JR T, PdMed_CallFormatSlots

PdMed_HandleSelectToggle:
	; (no addr) CP XHL, 0000000bh
	; (no addr) JR NZ, PdMed_HandleRepeat
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, PdMed_HandleRepeat
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmPdFileNameFunc
	; (no addr) LDA XIX, 88A0h
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XIX
	; (no addr) LD C, (XHL)
	; (no addr) CP C, 0ffh
	; (no addr) JR NZ, PdMed_RemoveFromOrder
	; (no addr) LD (XHL), (8920h)
	; (no addr) INC 1, (8920h)
	; (no addr) JR T, PdMed_RefreshAfterSelect

PdMed_RemoveFromOrder:
	; (no addr) CP C, 0fdh
	; (no addr) JR UGT, PdMed_RefreshAfterSelect
	; (no addr) LD (XHL), 0ffh
	; (no addr) LD A, (8920h)
	; (no addr) DEC 1, A
	; (no addr) LD (8920h), A
	; (no addr) LD IZ, 0
	; (no addr) LD HL, 0
	; (no addr) EXTZ WA
	; (no addr) CP WA, 0
	; (no addr) JR ULE, PdMed_RefreshAfterSelect
	; (no addr) LD IY, WA

PdMed_ReorderLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XIX
	; (no addr) LD A, (XDE)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, PdMed_NextReorder
	; (no addr) INC 1, IZ
	; (no addr) CP A, C
	; (no addr) JR ULE, PdMed_NextReorder
	; (no addr) DEC 1, A
	; (no addr) LD (XDE), A

PdMed_NextReorder:
	; (no addr) INC 1, HL
	; (no addr) CP IZ, IY
	; (no addr) JR C, PdMed_ReorderLoop

PdMed_RefreshAfterSelect:
	; (no addr) LD XWA, (8494h)
	; (no addr) LD BC, (849Ch)

PdMed_CallFormatSlots:
	CALR PdMed_FormatSlotList
	; (no addr) JRL T, PdMed_Exit

PdMed_HandleRepeat:
	; (no addr) CP XHL, 0000000ch
	; (no addr) JR NZ, PdMed_HandlePlay
	; (no addr) CP XDE, 01c00017h
	; (no addr) JR NZ, PdMed_SetRepeatOff
	; (no addr) LD (8924h), 001h
	; (no addr) JRL T, PdMed_Exit

PdMed_SetRepeatOff:
	; (no addr) LD (8924h), 000h
	; (no addr) JRL T, PdMed_Exit

PdMed_HandlePlay:
	; (no addr) CP XHL, 0000000dh
	; (no addr) JRL NZ, PdMed_Exit
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, PdMed_Exit
	; (no addr) LD (8922h), 000h
	; (no addr) LD HL, 0
	; (no addr) LD WA, (849Ch)
	; (no addr) CP WA, 0
	; (no addr) JR ULE, PdMed_CheckAutoPlay
	; (no addr) LDA XBC, 88A0h

PdMed_PlayFindLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), 000h
	; (no addr) JR NZ, PdMed_PlayNextLoop
	; (no addr) LD (84FEh), 001h
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	CALR FmmPdFileNameFunc
	; (no addr) INC 1, (8922h)
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0075h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, PdMed_CheckAutoPlay

PdMed_PlayNextLoop:
	; (no addr) INC 1, HL
	; (no addr) CP HL, WA
	; (no addr) JR C, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, PdMed_Exit
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0071h
	; (no addr) JR T, PdMed_CallPauseMode

PdMed_StoreDelayFlag:
	; (no addr) LD (8498h), XWA
	; (no addr) JR T, PdMed_Exit

PdMed_CheckContinue:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR Z, PdMed_Exit
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0075h

PdMed_CallPauseMode:
	; (no addr) CALL UI_PostModeChangeEvent

PdMed_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) RET

DocDiskNameFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XDE
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR NZ, DocDisk_Exit
	; (no addr) CALL LABEL_F8958D
	; (no addr) LD IX, 0
	; (no addr) JR T, DocDisk_CopyLoop

DocDisk_CopyCharLoop:
	; (no addr) CP (XHL), 020h
	; (no addr) JR Z, DocDisk_SkipSpace
	; (no addr) LD DE, IX
	; (no addr) INC 1, IX
	; (no addr) LD A, (XHL)
	; (no addr) LD (XBC + DE), A

DocDisk_SkipSpace:
	; (no addr) INC 1, XHL

DocDisk_CopyLoop:
	; (no addr) LDA XBC, 878Ch
	; (no addr) CP (XHL), 000h
	; (no addr) JR Z, DocDisk_TerminateStr
	; (no addr) CP IX, 001eh
	; (no addr) JR LT, DocDisk_CopyCharLoop

DocDisk_TerminateStr:
	; (no addr) LD XDE, XBC
	; (no addr) LD (XBC + IX), 000h
	; (no addr) JR T, DocDisk_TrimLoop

DocDisk_ClearTrailing:
	; (no addr) LD (XWA), 000h

DocDisk_TrimLoop:
	; (no addr) DEC 1, IX
	; (no addr) LDA XWA, XDE + IX
	; (no addr) CP (XWA), 020h
	; (no addr) JR NZ, DocDisk_PostEvent
	; (no addr) CP IX, 0
	; (no addr) JR GT, DocDisk_ClearTrailing

DocDisk_PostEvent:
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent

DocDisk_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) RET

DocMed_FormatFileList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), BC
	; (no addr) LD (XSP + 004h), XWA
	; (no addr) LD IZ, 0

DocFmt_FormatLoop:
	; (no addr) LD DE, IZ
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD A, IZL
	; (no addr) LD (XDE), A
	; (no addr) LD WA, (XSP + 002h)
	; (no addr) ADD WA, IZ
	; (no addr) CALL LABEL_F8ABBB
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
	; (no addr) PUSHW 0000h
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
	; (no addr) JR LT, DocFmt_FormatLoop
	; (no addr) POP IZ
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmDocFileNameFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) CP XBC, 01e50003h
	; (no addr) JRL Z, DocName_GetIndexReturn
	; (no addr) LD WA, (84A2h)
	; (no addr) LD IZ, WA
	; (no addr) CP XBC, 01e50002h
	; (no addr) JRL Z, DocName_SetIndexPlaying
	; (no addr) LD HL, WA
	; (no addr) EXTS XHL
	DIVS_HL 0xa
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR Z, DocName_HandleNavigation
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR Z, DocName_HandleNavigation
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, DocName_RefreshList
	; (no addr) CP XBC, 01e50004h
	; (no addr) JR NZ, DocName_ReturnZero
	; (no addr) LD (849Eh), XDE
	; (no addr) CALL LABEL_F8A7CE
	; (no addr) LD (84A2h), HL
	; (no addr) CP HL, 0
	; (no addr) JR GE, DocName_UpdateIndex
	; (no addr) LDW (84A2h), 0000h

DocName_UpdateIndex:
	; (no addr) LD WA, (84A2h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (849Eh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) JRL T, DocName_PostEvent

DocName_RefreshList:
	MULS_HL 0xa
	; (no addr) LD XWA, (849Eh)
	; (no addr) LD BC, HL
	CALR DocMed_FormatFileList

DocName_ReturnZero:
	; (no addr) LD XHL, 0
	; (no addr) JRL T, DocName_Exit

DocName_HandleNavigation:
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, DocName_CheckPageUp
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DocName_CheckPageUp
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, DocName_CheckPrevKey
	; (no addr) LD BC, WA
	; (no addr) INC 1, BC
	; (no addr) CP BC, (8508h)
	; (no addr) JR GE, DocName_GetCurrentIndex
	; (no addr) INC 1, WA
	; (no addr) JR T, DocName_SaveIndex

DocName_CheckPrevKey:
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, DocName_GetCurrentIndex
	; (no addr) CP WA, 0
	; (no addr) JR LE, DocName_GetCurrentIndex
	; (no addr) DEC 1, WA
	; (no addr) JR T, DocName_SaveIndex

DocName_CheckPageUp:
	; (no addr) CP XDE, 00000001h
	; (no addr) JR NZ, DocName_CheckPageDown
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DocName_CheckPageDown
	; (no addr) CP WA, 000ah
	; (no addr) JR LT, DocName_GetCurrentIndex
	; (no addr) SUB WA, 000ah
	; (no addr) JR T, DocName_SaveIndex

DocName_CheckPageDown:
	; (no addr) CP XDE, 00000002h
	; (no addr) JR NZ, DocName_GetCurrentIndex
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DocName_GetCurrentIndex
	; (no addr) LD BC, WA
	; (no addr) ADD BC, 000ah
	; (no addr) LD DE, (8508h)
	; (no addr) CP BC, DE
	; (no addr) JR GE, DocName_CheckEndBound
	; (no addr) ADD WA, 000ah

DocName_SaveIndex:
	; (no addr) LD (84A2h), WA
	; (no addr) JR T, DocName_UpdateDisplay

DocName_CheckEndBound:
	; (no addr) LD BC, DE
	; (no addr) DEC 1, BC
	; (no addr) LD WA, BC
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) CP HL, WA
	; (no addr) JR GE, DocName_GetCurrentIndex
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD WA, QDE
	; (no addr) CP WA, 0
	; (no addr) JR Z, DocName_GetCurrentIndex
	; (no addr) LD (84A2h), BC

DocName_GetCurrentIndex:
	; (no addr) LD WA, (84A2h)

DocName_UpdateDisplay:
	; (no addr) CP IZ, WA
	; (no addr) JRL Z, DocName_ReturnZero
	; (no addr) CALL LABEL_F8A956
	; (no addr) LD WA, (84A2h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (849Eh)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD BC, (84A2h)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	; (no addr) LD DE, IZ
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD XWA, (849Eh)
	; (no addr) CP DE, BC
	; (no addr) JR NZ, DocName_RefreshPage
	; (no addr) LD BC, IZ
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
	; (no addr) LD WA, (84A2h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD WA, QWA
	; (no addr) SLL 5, WA
	; (no addr) LDA XBC, 850Ch
	; (no addr) LD DE, WA
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (849Eh)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, DocName_ReturnZero

DocName_RefreshPage:
	MULS_BC 0xa
	CALR DocMed_FormatFileList
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01c0000bh
	; (no addr) LD XDE, 0
	CALR FmmDocMedleyFunc
	; (no addr) JRL T, DocName_ReturnZero

DocName_SetIndexPlaying:
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL Z, DocName_ReturnZero
	; (no addr) LD (84A2h), DE
	; (no addr) LD WA, DE
	; (no addr) CALL LABEL_F8A956
	; (no addr) LD WA, (84A2h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (849Eh)
	; (no addr) LD XBC, 01e50002h

DocName_PostEvent:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, DocName_ReturnZero

DocName_GetIndexReturn:
	; (no addr) LD HL, (84A2h)
	; (no addr) EXTS XHL

DocName_Exit:
	; (no addr) POP IZ
	; (no addr) INC 4, XSP
	; (no addr) RET

DocMed_FormatSlotList:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD IZ, BC
	; (no addr) LD (XSP + 006h), XWA
	; (no addr) LD XWA, 0
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmDocFileNameFunc
	; (no addr) LD QIZ, HL
	; (no addr) LD WA, QIZ
	; (no addr) EXTZ XWA
	DIVW_WA 0xa
	; (no addr) LD QIZ, WA
	MULW_WA 0xa
	; (no addr) LD QIZ, WA
	; (no addr) LDW (XSP + 004h:8), 000ah
	; (no addr) LD WA, QIZ
	; (no addr) ADD WA, 000ah
	; (no addr) CP WA, IZ
	; (no addr) JR C, DocFmtSlot_CalcVisible
	; (no addr) LD (XSP + 004h), IZ
	; (no addr) LD WA, QIZ
	; (no addr) SUB (XSP + 004h), WA

DocFmtSlot_CalcVisible:
	; (no addr) LD IZ, 0
	; (no addr) CPW (XSP + 004h), 0000h
	; (no addr) JR ULE, DocFmtSlot_FillEmpty

DocFmtSlot_FormatLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 84A4h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, QIZ
	; (no addr) ADD BC, IZ
	; (no addr) LDA XDE, 88A0h
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD C, (XBC)
	; (no addr) EXTZ BC
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 84A4h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, (XSP + 004h)
	; (no addr) JR C, DocFmtSlot_FormatLoop

DocFmtSlot_FillEmpty:
	; (no addr) CP IZ, 000ah
	; (no addr) JR NC, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	; (no addr) LD WA, IZ
	; (no addr) SLL 3, WA
	; (no addr) LDA XBC, 84A4h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, 00ffh
	; (no addr) LD DE, IZ
	CALR FormatMedleyNumber
	; (no addr) LD DE, IZ
	; (no addr) SLL 3, DE
	; (no addr) LDA XWA, 84A4h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, DocFmtSlot_EmptyLoop

DocFmtSlot_Exit:
	; (no addr) POP XIZ
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmDocMedleyFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XHL, XDE
	; (no addr) LD XDE, XBC
	; (no addr) LD XIZ, XWA
	; (no addr) CP XDE, 01e5000ah
	; (no addr) JRL Z, DocMed_CheckContinue
	; (no addr) LD XWA, XHL
	; (no addr) CP XDE, 01e50008h
	; (no addr) JRL Z, DocMed_StoreDelayFlag
	; (no addr) LD BC, (84FCh)
	; (no addr) CP XDE, 01c00018h
	; (no addr) JRL Z, DocMed_HandleNavToggle
	; (no addr) CP XDE, 01c00017h
	; (no addr) JRL Z, DocMed_HandleNavToggle
	; (no addr) CP XDE, 01c0000bh
	; (no addr) JRL Z, DocMed_RefreshDisplay
	; (no addr) CP XDE, 01e50004h
	; (no addr) JRL Z, DocMed_StoreWindowPtr
	; (no addr) CP XDE, 01c00013h
	; (no addr) JRL NZ, DocMed_Exit
	; (no addr) CP XHL, 00000003h
	; (no addr) JRL Z, DocMed_HandleStop
	; (no addr) CP XHL, 00000002h
	; (no addr) JRL NZ, DocMed_Exit
	; (no addr) LD WA, 0
	; (no addr) CALL InitializeOperationState
	; (no addr) LD A, (8D37h)
	; (no addr) CP A, 070h
	; (no addr) JR NZ, DocMed_CheckPlayMode
	; (no addr) LD (84FEh), 000h
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 2
	; (no addr) JRL C, DocMed_Exit
	; (no addr) LD (7F42h), 001h
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, DocMed_ShowError

DocMed_CheckPlayMode:
	; (no addr) CP A, 074h
	; (no addr) JRL NZ, DocMed_CheckInit
	; (no addr) CALL LABEL_F2076D
	; (no addr) CP L, 1
	; (no addr) JRL NZ, DocMed_HandleError
	; (no addr) LD (84FEh), 001h
	; (no addr) LD C, (8922h)
	; (no addr) LDA XWA, 88A0h
	; (no addr) CP C, (8920h)
	; (no addr) JR NC, DocMed_CheckRepeat
	; (no addr) LD HL, 0
	; (no addr) LD DE, (84FCh)
	; (no addr) CP DE, 0
	; (no addr) JRL ULE, DocMed_Exit

DocMed_FindSongLoop:
	; (no addr) LD IX, HL
	; (no addr) EXTZ XIX
	; (no addr) ADD XIX, XWA
	; (no addr) CP (XIX), C
	; (no addr) JR NZ, DocMed_NextSong
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	CALR FmmDocFileNameFunc
	; (no addr) LD XWA, (84F4h)
	; (no addr) LD BC, (84FCh)
	CALR DocMed_FormatSlotList
	; (no addr) INC 1, (8922h)
	; (no addr) LD XWA, (84F8h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, DocMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh
	; (no addr) JR T, DocMed_PostDelayEvent

DocMed_NextSong:
	; (no addr) INC 1, HL
	; (no addr) CP HL, DE
	; (no addr) JR C, DocMed_FindSongLoop
	; (no addr) JRL T, DocMed_Exit

DocMed_CheckRepeat:
	; (no addr) CP (8924h), 000h
	; (no addr) JR Z, DocMed_ClearPlaying
	; (no addr) LD (8922h), 000h
	; (no addr) LD HL, 0
	; (no addr) LD BC, (84FCh)
	; (no addr) CP BC, 0
	; (no addr) JRL ULE, DocMed_Exit

DocMed_RepeatFindLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XWA
	; (no addr) CP (XDE), 000h
	; (no addr) JR NZ, DocMed_RepeatNext
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	CALR FmmDocFileNameFunc
	; (no addr) LD XWA, (84F4h)
	; (no addr) LD BC, (84FCh)
	CALR DocMed_FormatSlotList
	; (no addr) INC 1, (8922h)
	; (no addr) LD XWA, (84F8h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, DocMed_Exit
	; (no addr) LD XBC, 01e50009h
	; (no addr) LD XDE, 0000001eh

DocMed_PostDelayEvent:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, DocMed_Exit

DocMed_RepeatNext:
	; (no addr) INC 1, HL
	; (no addr) CP HL, BC
	; (no addr) JR C, DocMed_RepeatFindLoop
	; (no addr) JRL T, DocMed_Exit

DocMed_ClearPlaying:
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, DocMed_Exit

DocMed_HandleError:
	; (no addr) CALL LABEL_F2076D
	; (no addr) LD (84FEh), 000h
	; (no addr) CP L, 0
	; (no addr) JRL Z, DocMed_Exit
	; (no addr) LD (7F42h), 001h
	; (no addr) LD WA, 00eeh

DocMed_ShowError:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, DocMed_Exit

DocMed_CheckInit:
	; (no addr) CPW (8508h), 0000h
	; (no addr) JR LT, DocMed_InitFromDisk
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR NZ, DocMed_InitState

DocMed_InitFromDisk:
	; (no addr) LDW (8504h), 0ffffh
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL LABEL_F8A9D6
	; (no addr) LD (8508h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CALL SignalProgressUpdate

DocMed_InitState:
	; (no addr) LD (84FEh), 000h
	; (no addr) LD (8922h), 000h
	; (no addr) LD (8920h), 000h
	; (no addr) LD BC, 0080h
	; (no addr) LD WA, (8508h)
	; (no addr) CP WA, 0080h
	; (no addr) JR UGT, DocMed_ClampCount
	; (no addr) LD BC, WA

DocMed_ClampCount:
	; (no addr) LD (84FCh), BC
	; (no addr) LD HL, 0
	; (no addr) CP BC, 0
	; (no addr) JR ULE, DocMed_FinishInit
	; (no addr) LDA XWA, 88A0h

DocMed_ClearSlotsLoop:
	; (no addr) LD BC, HL
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XWA
	; (no addr) LD (XBC), 0ffh
	; (no addr) INC 1, HL
	; (no addr) CP HL, (84FCh)
	; (no addr) JR C, DocMed_ClearSlotsLoop

DocMed_FinishInit:
	; (no addr) CALL LABEL_F20ACD
	; (no addr) LD XWA, 0
	; (no addr) LD (84F8h), XWA
	; (no addr) JRL T, DocMed_Exit

DocMed_HandleStop:
	; (no addr) LD A, (8D36h)
	; (no addr) CP A, 070h
	; (no addr) JRL Z, DocMed_Exit
	; (no addr) CP A, 074h
	; (no addr) JRL Z, DocMed_Exit
	; (no addr) CALL LABEL_F20B70
	; (no addr) CALL CancelOperationCleanup
	; (no addr) LD (84FEh), 000h
	; (no addr) JRL T, DocMed_Exit

DocMed_StoreWindowPtr:
	; (no addr) LD (84F4h), XWA
	; (no addr) JRL T, DocMed_Exit

DocMed_RefreshDisplay:
	; (no addr) LD XWA, (84F4h)
	CALR DocMed_FormatSlotList
	; (no addr) JRL T, DocMed_Exit

DocMed_HandleNavToggle:
	; (no addr) CP XHL, 0000000ah
	; (no addr) JRL NZ, DocMed_HandleSelectToggle
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DocMed_HandleSelectToggle
	; (no addr) LD HL, 0
	; (no addr) LD WA, BC
	; (no addr) CP BC, 0
	; (no addr) JR ULE, DocMed_CheckAllUnmarked
	; (no addr) LDA XBC, 88A0h

DocMed_FindUnmarkedLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), 0ffh
	; (no addr) JR Z, DocMed_CheckAllUnmarked
	; (no addr) INC 1, HL
	; (no addr) CP HL, WA
	; (no addr) JR C, DocMed_FindUnmarkedLoop

DocMed_CheckAllUnmarked:
	; (no addr) CP HL, WA
	; (no addr) JR NC, DocMed_RemoveOrderLoop
	; (no addr) LD HL, 0
	; (no addr) CP WA, 0
	; (no addr) JR ULE, DocMed_RefreshAfterToggle
	; (no addr) LDA XDE, 88A0h

DocMed_AssignOrderLoop:
	; (no addr) LD BC, HL
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0ffh
	; (no addr) JR NZ, DocMed_NextAssign
	; (no addr) LD (XBC), (8920h)
	; (no addr) INC 1, (8920h)

DocMed_NextAssign:
	; (no addr) INC 1, HL
	; (no addr) CP HL, (84FCh)
	; (no addr) JR C, DocMed_AssignOrderLoop
	; (no addr) JR T, DocMed_RefreshAfterToggle

DocMed_RemoveOrderLoop:
	; (no addr) LD HL, 0
	; (no addr) CP WA, 0
	; (no addr) JR ULE, DocMed_RefreshAfterToggle
	; (no addr) LDA XDE, 88A0h

DocMed_UnmarkLoop:
	; (no addr) LD BC, HL
	; (no addr) EXTZ XBC
	; (no addr) ADD XBC, XDE
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, DocMed_NextUnmark
	; (no addr) LD (XBC), 0ffh
	; (no addr) DEC 1, (8920h)

DocMed_NextUnmark:
	; (no addr) INC 1, HL
	; (no addr) CP HL, (84FCh)
	; (no addr) JR C, DocMed_UnmarkLoop

DocMed_RefreshAfterToggle:
	; (no addr) LD XWA, (84F4h)
	; (no addr) LD BC, (84FCh)
	; (no addr) JR T, DocMed_CallFormatSlots

DocMed_HandleSelectToggle:
	; (no addr) CP XHL, 0000000bh
	; (no addr) JR NZ, DocMed_HandleRepeat
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DocMed_HandleRepeat
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmDocFileNameFunc
	; (no addr) LDA XIX, 88A0h
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XIX
	; (no addr) LD C, (XHL)
	; (no addr) CP C, 0ffh
	; (no addr) JR NZ, DocMed_RemoveFromOrder
	; (no addr) LD (XHL), (8920h)
	; (no addr) INC 1, (8920h)
	; (no addr) JR T, DocMed_RefreshAfterSelect

DocMed_RemoveFromOrder:
	; (no addr) CP C, 0fdh
	; (no addr) JR UGT, DocMed_RefreshAfterSelect
	; (no addr) LD (XHL), 0ffh
	; (no addr) LD A, (8920h)
	; (no addr) DEC 1, A
	; (no addr) LD (8920h), A
	; (no addr) LD IZ, 0
	; (no addr) LD HL, 0
	; (no addr) EXTZ WA
	; (no addr) CP WA, 0
	; (no addr) JR ULE, DocMed_RefreshAfterSelect
	; (no addr) LD IY, WA

DocMed_ReorderLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XIX
	; (no addr) LD A, (XDE)
	; (no addr) CP A, 0fdh
	; (no addr) JR UGT, DocMed_NextReorder
	; (no addr) INC 1, IZ
	; (no addr) CP A, C
	; (no addr) JR ULE, DocMed_NextReorder
	; (no addr) DEC 1, A
	; (no addr) LD (XDE), A

DocMed_NextReorder:
	; (no addr) INC 1, HL
	; (no addr) CP IZ, IY
	; (no addr) JR C, DocMed_ReorderLoop

DocMed_RefreshAfterSelect:
	; (no addr) LD XWA, (84F4h)
	; (no addr) LD BC, (84FCh)

DocMed_CallFormatSlots:
	CALR DocMed_FormatSlotList
	; (no addr) JRL T, DocMed_Exit

DocMed_HandleRepeat:
	; (no addr) CP XHL, 0000000ch
	; (no addr) JR NZ, DocMed_HandlePlay
	; (no addr) CP XDE, 01c00017h
	; (no addr) JR NZ, DocMed_SetRepeatOff
	; (no addr) LD (8924h), 001h
	; (no addr) JRL T, DocMed_Exit

DocMed_SetRepeatOff:
	; (no addr) LD (8924h), 000h
	; (no addr) JRL T, DocMed_Exit

DocMed_HandlePlay:
	; (no addr) CP XHL, 0000000dh
	; (no addr) JRL NZ, DocMed_Exit
	; (no addr) CP (84FEh), 000h
	; (no addr) JRL NZ, DocMed_Exit
	; (no addr) LD (8922h), 000h
	; (no addr) LD HL, 0
	; (no addr) LD WA, (84FCh)
	; (no addr) CP WA, 0
	; (no addr) JR ULE, DocMed_CheckAutoPlay
	; (no addr) LDA XBC, 88A0h

DocMed_PlayFindLoop:
	; (no addr) LD DE, HL
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) CP (XDE), 000h
	; (no addr) JR NZ, DocMed_PlayNextLoop
	; (no addr) LD (84FEh), 001h
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	CALR FmmDocFileNameFunc
	; (no addr) INC 1, (8922h)
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0074h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, DocMed_CheckAutoPlay

DocMed_PlayNextLoop:
	; (no addr) INC 1, HL
	; (no addr) CP HL, WA
	; (no addr) JR C, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR NZ, DocMed_Exit
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01e50003h
	; (no addr) LD XDE, 0
	CALR FmmDocFileNameFunc
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0070h
	; (no addr) JR T, DocMed_CallPauseMode

DocMed_StoreDelayFlag:
	; (no addr) LD (84F8h), XWA
	; (no addr) JR T, DocMed_Exit

DocMed_CheckContinue:
	; (no addr) CP (84FEh), 000h
	; (no addr) JR Z, DocMed_Exit
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0074h

DocMed_CallPauseMode:
	; (no addr) CALL UI_PostModeChangeEvent

DocMed_Exit:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) RET

SetSongSlotValue:
	; (no addr) CP WA, 000ah
	; (no addr) RET NC
	; (no addr) LDA XHL, 0AB000h
	; (no addr) LD DE, WA
	; (no addr) SLL 11, DE
	; (no addr) EXTZ XDE
	; (no addr) ADD XHL, XDE
	; (no addr) ADD XHL, 0000001ch
	; (no addr) LD (XHL), BC
	; (no addr) LD E, (0FFE3h:24)
	; (no addr) EXTZ DE
	; (no addr) CP DE, WA
	; (no addr) RET NZ
	; (no addr) LDA XHL, 0F180h:24
	; (no addr) ADD XHL, 0000001ch
	; (no addr) LD (XHL), BC
	; (no addr) RET

GetSongSlotValue:
	; (no addr) LD HL, 0
	; (no addr) CP WA, 000ah
	; (no addr) RET NC
	; (no addr) LDA XBC, 0AB000h
	; (no addr) SLL 11, WA
	; (no addr) EXTZ XWA
	; (no addr) ADD XBC, XWA
	; (no addr) ADD XBC, 0000001ch
	; (no addr) LD HL, (XBC)
	; (no addr) RET

CheckSongSlotHasData:
	CALR GetSongSlotValue
	; (no addr) CP HL, 0
	; (no addr) SCC NZ, HL
	; (no addr) RET

SongSlot_RawData:
	.byte 0x2E, 0xD9, 0x8E, 0x1E, 0xD5, 0xFF, 0xDE, 0xF3
	.byte 0xDB, 0x76, 0x4E, 0xE

FindFirstEmptySlot:
	; (no addr) PUSH IZ
	; (no addr) LD IZ, 0

FindEmpty_Loop:
	; (no addr) LD WA, IZ
	CALR GetSongSlotValue
	; (no addr) CP HL, 0
	; (no addr) JR NZ, FindEmpty_Exit
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 000ah
	; (no addr) JR C, FindEmpty_Loop

FindEmpty_Exit:
	; (no addr) POP IZ
	; (no addr) RET

ClearAllSongSlots:
	; (no addr) PUSH XIZ
	; (no addr) LD IZ, WA
	; (no addr) LD QIZ, 0

ClearSlots_Loop:
	; (no addr) LD WA, QIZ
	; (no addr) LD BC, IZ
	CALR SetSongSlotValue
	; (no addr) INC 1, QIZ
	; (no addr) CP QIZ, 000ah
	; (no addr) JR C, ClearSlots_Loop
	; (no addr) POP XIZ
	; (no addr) RET

ResetSlotsIfEmpty:
	CALR FindFirstEmptySlot
	; (no addr) LD WA, HL
	; (no addr) CP WA, 0
	; (no addr) RET Z
	CALR ClearAllSongSlots
	; (no addr) RET

CheckSlotIsSelected:
	; (no addr) PUSH IZ
	; (no addr) LD IZ, WA
	CALR FindFirstEmptySlot
	; (no addr) CP HL, IZ
	; (no addr) SCC Z, HL
	; (no addr) POP IZ
	; (no addr) RET

CheckAnySlotHasData:
	CALR FindFirstEmptySlot
	; (no addr) CP HL, 0
	; (no addr) SCC NZ, HL
	; (no addr) RET

SetCurrentSlotIndex:
	; (no addr) LD (09480Eh), WA
	; (no addr) RET

GetCurrentSlotIndex:
	; (no addr) LD HL, (09480Eh)
	; (no addr) RET

CheckIsCurrentSlot:
	; (no addr) PUSH IZ
	; (no addr) LD IZ, WA
	CALR GetCurrentSlotIndex
	; (no addr) CP HL, IZ
	; (no addr) SCC Z, HL
	; (no addr) POP IZ
	; (no addr) RET

CheckSlotIndexValid:
	CALR GetCurrentSlotIndex
	; (no addr) CP HL, 0
	; (no addr) SCC NZ, HL
	; (no addr) RET

InitializeCheap:
	; (no addr) LDA XSP, XSP - 14

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

	; (no addr) LDA XSP, XSP + 14
	; (no addr) RET

PasswordText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, PasswordText_Exit
	; (no addr) LDA XHL, 0EA85C8h
	; (no addr) RET

PasswordText_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

CheckPasswordText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, CheckPwd_Exit
	; (no addr) LD A, (02748Eh)
	; (no addr) CP A, 2
	; (no addr) JR Z, CheckPwd_Type2
	; (no addr) CP A, 1
	; (no addr) JR NZ, CheckPwd_Type0
	; (no addr) LD XHL, 00ea8832h
	; (no addr) JR T, CheckPwd_Return

CheckPwd_Type2:
	; (no addr) LD XHL, 00ea8a0ch
	; (no addr) JR T, CheckPwd_Return

CheckPwd_Type0:
	; (no addr) LD XHL, 00ea868eh

CheckPwd_Return:
	; (no addr) RET

CheckPwd_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

WakeUpPassword:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 004h), XDE
	; (no addr) LD XIZ, XWA
	; (no addr) CP XBC, 01c50004h
	; (no addr) JRL Z, WakeUp_StoreType
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR Z, WakeUp_HandleOk
	; (no addr) CP XBC, 01c00001h
	; (no addr) JR Z, WakeUp_HandleInit
	; (no addr) CP XBC, 01c0000dh
	; (no addr) JR Z, WakeUp_HandleDirect
	; (no addr) CP XBC, 01e00085h
	; (no addr) JR Z, WakeUp_Return1
	; (no addr) LD XWA, XIZ
	; (no addr) LD XDE, (XSP + 004h)
	; (no addr) CALL InheritedProc
	; (no addr) JRL T, WakeUp_Exit

WakeUp_Return1:
	; (no addr) LD XHL, 1
	; (no addr) JRL T, WakeUp_Exit

WakeUp_HandleDirect:
	; (no addr) LD XWA, XIZ
	; (no addr) LD XDE, (XSP + 004h)
	; (no addr) CALL InheritedProc
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00ea8bf0h
	; (no addr) CALL SendEvent
	; (no addr) JRL T, WakeUp_ReturnZero

WakeUp_HandleInit:
	; (no addr) LD XWA, XIZ
	; (no addr) LD XDE, (XSP + 004h)
	; (no addr) CALL InheritedProc
	; (no addr) LD (02741Ah), 000h
	; (no addr) JRL T, WakeUp_ReturnZero

WakeUp_HandleOk:
	; (no addr) LD XWA, XIZ
	; (no addr) LD XDE, (XSP + 004h)
	; (no addr) CALL InheritedProc
	; (no addr) LD XWA, 00670001h
	; (no addr) LD XBC, 01e00056h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) CP XHL, 00000003h
	; (no addr) JR Z, WakeUp_ReturnZero
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) CP XWA, 0000008ch
	; (no addr) JR NZ, WakeUp_ClearCounter
	; (no addr) INC 1, (02741Ah)
	; (no addr) CP (02741Ah), 007h
	; (no addr) JR NZ, WakeUp_ReturnZero
	; (no addr) LD (02741Ah), 000h
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 00600040h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) JR T, WakeUp_PostEvent

WakeUp_ClearCounter:
	; (no addr) LD (02741Ah), 000h
	; (no addr) JR T, WakeUp_ReturnZero

WakeUp_StoreType:
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD (02748Eh), A
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 00600045h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0

WakeUp_PostEvent:
	; (no addr) CALL PostEvent

WakeUp_ReturnZero:
	; (no addr) LD XHL, 0

WakeUp_Exit:
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

PasswordOk:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR Z, PwdOk_HandleConfirm
	; (no addr) CP XBC, 01e0007ch
	; (no addr) JR Z, PwdOk_Return2
	; (no addr) CP XBC, 01e00084h
	; (no addr) JR Z, PwdOk_ReturnZero
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JR NZ, PwdOk_ReturnZero
	; (no addr) PUSHW 00eah
	; (no addr) PUSHW 8bf6h
	; (no addr) PUSH XDE
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LD XHL, XIZ
	; (no addr) JR T, PwdOk_Exit

PwdOk_Return2:
	; (no addr) LD XHL, 2
	; (no addr) JR T, PwdOk_Exit

PwdOk_HandleConfirm:
	; (no addr) CALL GetNamingWindowID
	; (no addr) LD XWA, XHL
	; (no addr) LD XBC, 01e0003ah
	; (no addr) LD XDE, 0002741ch
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 00600040h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD DE, (02741Ch)
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, 01450038h
	; (no addr) LD XBC, 01e5000dh
	; (no addr) CALL MainFuncCall

PwdOk_ReturnZero:
	; (no addr) LD XHL, 0

PwdOk_Exit:
	; (no addr) POP XIZ
	; (no addr) RET

CheckPasswordOk:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR Z, CheckOk_HandleConfirm
	; (no addr) CP XBC, 01e0007ch
	; (no addr) JR Z, CheckOk_Return2
	; (no addr) CP XBC, 01e00084h
	; (no addr) JRL Z, CheckOk_ReturnZero
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JRL NZ, CheckOk_ReturnZero
	; (no addr) PUSHW 00eah
	; (no addr) PUSHW 8bfah
	; (no addr) PUSH XDE
	; (no addr) CALL LABEL_FF0F4D
	; (no addr) INC 8, XSP
	; (no addr) LD XHL, XIZ
	; (no addr) JRL T, CheckOk_Exit

CheckOk_Return2:
	; (no addr) LD XHL, 2
	; (no addr) JRL T, CheckOk_Exit

CheckOk_HandleConfirm:
	; (no addr) CALL GetNamingWindowID
	; (no addr) LD XWA, XHL
	; (no addr) LD XBC, 01e0003ah
	; (no addr) LD XDE, 00027424h
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 00600045h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 00670001h
	; (no addr) LD XBC, 01e00056h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LDA XWA, 027424h
	; (no addr) CP HL, 1
	; (no addr) JR NZ, CheckOk_Type2
	; (no addr) LD DE, (XWA)
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, 01450038h
	; (no addr) LD XBC, 01e5000eh
	; (no addr) JR T, CheckOk_CallFunc

CheckOk_Type2:
	; (no addr) CP HL, 2
	; (no addr) JR NZ, CheckOk_Type3
	; (no addr) LD DE, (XWA)
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, 01450038h
	; (no addr) LD XBC, 01e5000fh
	; (no addr) JR T, CheckOk_CallFunc

CheckOk_Type3:
	; (no addr) CP HL, 3
	; (no addr) JR NZ, CheckOk_ReturnZero
	; (no addr) LD DE, (XWA)
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, 01450038h
	; (no addr) LD XBC, 01e50010h

CheckOk_CallFunc:
	; (no addr) CALL MainFuncCall

CheckOk_ReturnZero:
	; (no addr) LD XHL, 0

CheckOk_Exit:
	; (no addr) POP XIZ
	; (no addr) RET

PasswordNo:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, PwdNo_Exit
	; (no addr) LD XWA, 00600040h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent

PwdNo_Exit:
	; (no addr) LD XHL, 0
	; (no addr) RET

CheckPasswordNo:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, CheckNo_HandleConfirm
	; (no addr) LD XWA, 00600045h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent

CheckNo_HandleConfirm:
	; (no addr) LD XHL, 0
	; (no addr) RET

DiskAttention:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, CheckNo_Type1
	; (no addr) LDA XHL, 0EA8BFEh
	; (no addr) RET

CheckNo_Type1:
	; (no addr) LD XHL, 0
	; (no addr) RET

DiskSure:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, CheckNo_Type2
	; (no addr) LDA XHL, 0EA8C5Ch
	; (no addr) RET

CheckNo_Type2:
	; (no addr) LD XHL, 0
	; (no addr) RET

FormatText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, CheckNo_Type3
	; (no addr) LDA XHL, 0EA8CDCh
	; (no addr) RET

CheckNo_Type3:
	; (no addr) LD XHL, 0
	; (no addr) RET

DeleteText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, CheckNo_CallFunc
	; (no addr) LDA XHL, 0EA8E70h
	; (no addr) RET

CheckNo_CallFunc:
	; (no addr) LD XHL, 0
	; (no addr) RET

DeleteYes:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, PwdChange_HandleOk
	; (no addr) LD XWA, 007b0051h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 00000033h
	; (no addr) CALL PostEvent

PwdChange_HandleOk:
	; (no addr) LD XHL, 0
	; (no addr) RET

DeleteNo:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, PwdChange_Type1
	; (no addr) LD XWA, 007b0051h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent

PwdChange_Type1:
	; (no addr) LD XHL, 0
	; (no addr) RET

SaveText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, PwdChange_CallFunc
	; (no addr) LDA XHL, 0EA912Ah
	; (no addr) RET

PwdChange_CallFunc:
	; (no addr) LD XHL, 0
	; (no addr) RET

SaveYes:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, PwdDel_HandleOk
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 00000032h
	; (no addr) CALL PostEvent

PwdDel_HandleOk:
	; (no addr) LD XHL, 0
	; (no addr) RET

SaveNo:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, PwdDel_Type1
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL SendEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL PostEvent

PwdDel_Type1:
	; (no addr) LD XHL, 0
	; (no addr) RET

InsertOptionText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, PwdDel_Type2
	; (no addr) LDA XHL, 0EA943Ch
	; (no addr) RET

PwdDel_Type2:
	; (no addr) LD XHL, 0
	; (no addr) RET

TypePriorityText:
	; (no addr) CP XBC, 01e0009fh
	; (no addr) JR NZ, PwdDel_CallFunc
	; (no addr) LDA XHL, 0EA9558h
	; (no addr) RET

PwdDel_CallFunc:
	; (no addr) LD XHL, 0
	; (no addr) RET

