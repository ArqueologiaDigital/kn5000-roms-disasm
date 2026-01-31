; =============================================================================
; file_io/title_handlers.asm - Load/Save Title Entry Handlers
; =============================================================================
; Entry point handlers for file manager dialogs.
;
; Key routines:
;   LoadTtlJgFunc, SaveTtlJgFunc     - Load/Save title handlers
;   SaveSmfTtlJgFunc                 - SMF save handler
;   DirectPlayTtlJgFunc              - Direct play handler
;   SongMedleyTtlJgFunc              - Song medley handler
;   SetupFlashFunc                   - Flash setup
;   FmmUtilityTitleFunc              - File Manager utility menu
;   FmmSmfUtilityTitleFunc           - SMF utility menu
; =============================================================================

LoadTtlJgFunc:
	CP XBC, 01c00007h
	JR NZ, LABEL_F8B808
	LD WA, 0061h
	LD BC, 0064h
	CALR LABEL_F8B36E

LABEL_F8B808:
	LD XHL, 0
	RET

SaveTtlJgFunc:
	CP XBC, 01c00007h
	JR NZ, LABEL_F8B819
	LD WA, 0067h
	CALR LABEL_F8B435

LABEL_F8B819:
	LD XHL, 0
	RET

SaveSmfTtlJgFunc:
	CP XBC, 01c00007h
	JR NZ, LABEL_F8B82A
	LD WA, 006bh
	CALR LABEL_F8B435

LABEL_F8B82A:
	LD XHL, 0
	RET

DirectPlayTtlJgFunc:
	CP XBC, 01c00007h
	CALL Z, LABEL_F8B3D8
	LD XHL, 0
	RET

SongMedleyTtlJgFunc:
	CP XBC, 01c00007h
	JR NZ, LABEL_F8B849
	LD WA, 0077h
	CALR LABEL_F8B435

LABEL_F8B849:
	LD XHL, 0
	RET

SetupFlashFunc:
	CP XBC, 01e5000ch
	JR Z, LABEL_F8B87C
	CP XBC, 01e5000bh
	JR NZ, LABEL_F8B882
	LD (7F42h), 025h
	LD WA, 00eeh
	CALL LABEL_F994BD
	LD WA, 6
	CALL LABEL_FC55A9
	LD (7F42h), 023h
	LD WA, 00eeh
	CALL LABEL_F994BD
	JR T, LABEL_F8B882

LABEL_F8B87C:
	LD WA, 6
	CALL LABEL_FC5625

LABEL_F8B882:
	LD XHL, 0
	RET

FmmUtilityTitleFunc:
	CP XBC, 01c00013h
	JRL NZ, LABEL_F8BA11
	CP XDE, 00000003h
	JRL Z, LABEL_F8BA0E
	CP XDE, 00000002h
	JRL NZ, LABEL_F8BA11
	LD (84FEh), 000h
	LD WA, 1
	CALR InitializeOperationState
	LD XWA, 007b0013h
	LD XBC, 01e50005h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD_8_8 07F5Ch, 08D37h
	CPW (8500h), 0000h
	JR GE, LABEL_F8B8D5
	CALL GetDiskSizeInfo
	EXTZ HL
	LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8B8D5:
	LD WA, (8500h)
	CP WA, 1
	JRL Z, LABEL_F8B9A1
	CP WA, 0
	JRL Z, LABEL_F8B988
	CP WA, 5
	JR Z, LABEL_F8B944
	CPW (8502h), 0000h
	JR GE, LABEL_F8B902
	CALL GetEncodedFileSizeData
	LD (8502h), HL
	CALL LABEL_F8958D
	CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8B902:
	CPW (8502h), 0000h
	JRL NZ, LABEL_F8B9EC
	CPW (8504h), 0000h
	JR GE, LABEL_F8B91E
	CALL GetFileCountEncoded
	LD (8504h), HL
	CALR SignalProgressUpdate

LABEL_F8B91E:
	CPW (8504h), 0000h
	JRL LE, LABEL_F8B9EC
	CP (7F5Ch), 07ch
	JRL Z, LABEL_F8B9EC
	LD XWA, 007b0013h
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD WA, 007ch
	JR T, LABEL_F8B99B

LABEL_F8B944:
	LD XWA, 007b0013h
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD A, (7F5Ch)
	EXTZ WA
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 000h
	LD WA, 00eeh
	JR T, LABEL_F8B9E6

LABEL_F8B988:
	LD XWA, 007b0013h
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD WA, 007dh

LABEL_F8B99B:
	CALL LABEL_F99490
	JR T, LABEL_F8BA11

LABEL_F8B9A1:
	CALR ResetProgressIndication
	LD XWA, 007b0013h
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD A, (7F5Ch)
	EXTZ WA
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 002h
	LD WA, 00eeh

LABEL_F8B9E6:
	CALL LABEL_F994BD
	JR T, LABEL_F8BA11

LABEL_F8B9EC:
	LD XWA, 007b0013h
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	JR T, LABEL_F8BA11

LABEL_F8BA0E:
	CALR CancelOperationCleanup

LABEL_F8BA11:
	LD XHL, 0
	RET

FmmSmfUtilityTitleFunc:
	CP XBC, 01c00013h
	JRL NZ, LABEL_F8BBA0
	CP XDE, 00000003h
	JRL Z, LABEL_F8BB9D
	CP XDE, 00000002h
	JRL NZ, LABEL_F8BBA0
	LD (84FEh), 000h
	LD WA, 1
	CALR InitializeOperationState
	LD XWA, 007b002ah
	LD XBC, 01e50005h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD_8_8 07F5Eh, 08D37h
	CPW (8500h), 0000h
	JR GE, LABEL_F8BA64
	CALL GetDiskSizeInfo
	EXTZ HL
	LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8BA64:
	LD WA, (8500h)
	CP WA, 1
	JRL Z, LABEL_F8BB30
	CP WA, 0
	JRL Z, LABEL_F8BB17
	CP WA, 5
	JR Z, LABEL_F8BAD3
	CPW (8504h), 0000h
	JR GE, LABEL_F8BA91
	CALL GetFileCountEncoded
	LD (8504h), HL
	CALL LABEL_F8958D
	CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8BA91:
	CPW (8504h), 0000h
	JRL NZ, LABEL_F8BB7B
	CPW (8502h), 0000h
	JR GE, LABEL_F8BAAD
	CALL GetEncodedFileSizeData
	LD (8502h), HL
	CALR SignalProgressUpdate

LABEL_F8BAAD:
	CPW (8502h), 0000h
	JRL LE, LABEL_F8BB7B
	CP (7F5Eh), 07bh
	JRL Z, LABEL_F8BB7B
	LD XWA, 007b002ah
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD WA, 007bh
	JR T, LABEL_F8BB2A

LABEL_F8BAD3:
	LD XWA, 007b002ah
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD A, (7F5Eh)
	EXTZ WA
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 000h
	LD WA, 00eeh
	JR T, LABEL_F8BB75

LABEL_F8BB17:
	LD XWA, 007b002ah
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD WA, 007dh

LABEL_F8BB2A:
	CALL LABEL_F99490
	JR T, LABEL_F8BBA0

LABEL_F8BB30:
	CALR ResetProgressIndication
	LD XWA, 007b002ah
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD A, (7F5Eh)
	EXTZ WA
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 002h
	LD WA, 00eeh

LABEL_F8BB75:
	CALL LABEL_F994BD
	JR T, LABEL_F8BBA0

LABEL_F8BB7B:
	LD XWA, 007b002ah
	LD XBC, 01e50006h
	LD XDE, 0
	CALL ApDeliveryEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	JR T, LABEL_F8BBA0

LABEL_F8BB9D:
	CALR CancelOperationCleanup

LABEL_F8BBA0:
	LD XHL, 0
	RET

