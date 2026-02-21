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
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, LABEL_F8B808
	; (no addr) LD WA, 0061h
	; (no addr) LD BC, 0064h
	CALR LABEL_F8B36E

LABEL_F8B808:
	; (no addr) LD XHL, 0
	; (no addr) RET

SaveTtlJgFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, LABEL_F8B819
	; (no addr) LD WA, 0067h
	CALR LABEL_F8B435

LABEL_F8B819:
	; (no addr) LD XHL, 0
	; (no addr) RET

SaveSmfTtlJgFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, LABEL_F8B82A
	; (no addr) LD WA, 006bh
	CALR LABEL_F8B435

LABEL_F8B82A:
	; (no addr) LD XHL, 0
	; (no addr) RET

DirectPlayTtlJgFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) CALL Z, LABEL_F8B3D8
	; (no addr) LD XHL, 0
	; (no addr) RET

SongMedleyTtlJgFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, LABEL_F8B849
	; (no addr) LD WA, 0077h
	CALR LABEL_F8B435

LABEL_F8B849:
	; (no addr) LD XHL, 0
	; (no addr) RET

SetupFlashFunc:
	; (no addr) CP XBC, 01e5000ch
	; (no addr) JR Z, LABEL_F8B87C
	; (no addr) CP XBC, 01e5000bh
	; (no addr) JR NZ, LABEL_F8B882
	; (no addr) LD (7F42h), 025h
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD
	; (no addr) LD WA, 6
	; (no addr) CALL LABEL_FC55A9
	; (no addr) LD (7F42h), 023h
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD
	; (no addr) JR T, LABEL_F8B882

LABEL_F8B87C:
	; (no addr) LD WA, 6
	; (no addr) CALL LABEL_FC5625

LABEL_F8B882:
	; (no addr) LD XHL, 0
	; (no addr) RET

FmmUtilityTitleFunc:
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8BA11
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, LABEL_F8BA0E
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8BA11
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 007b0013h
	; (no addr) LD XBC, 01e50005h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	LD_8_8 0x7F5C, 0x8D37
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8B8D5
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8B8D5:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JRL Z, LABEL_F8B9A1
	; (no addr) CP WA, 0
	; (no addr) JRL Z, LABEL_F8B988
	; (no addr) CP WA, 5
	; (no addr) JR Z, LABEL_F8B944
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, LABEL_F8B902
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8B902:
	; (no addr) CPW (8502h), 0000h
	; (no addr) JRL NZ, LABEL_F8B9EC
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR GE, LABEL_F8B91E
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	CALR SignalProgressUpdate

LABEL_F8B91E:
	; (no addr) CPW (8504h), 0000h
	; (no addr) JRL LE, LABEL_F8B9EC
	; (no addr) CP (7F5Ch), 07ch
	; (no addr) JRL Z, LABEL_F8B9EC
	; (no addr) LD XWA, 007b0013h
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD WA, 007ch
	; (no addr) JR T, LABEL_F8B99B

LABEL_F8B944:
	; (no addr) LD XWA, 007b0013h
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F5Ch)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 000h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8B9E6

LABEL_F8B988:
	; (no addr) LD XWA, 007b0013h
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD WA, 007dh

LABEL_F8B99B:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, LABEL_F8BA11

LABEL_F8B9A1:
	CALR ResetProgressIndication
	; (no addr) LD XWA, 007b0013h
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F5Ch)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 002h
	; (no addr) LD WA, 00eeh

LABEL_F8B9E6:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JR T, LABEL_F8BA11

LABEL_F8B9EC:
	; (no addr) LD XWA, 007b0013h
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8BA11

LABEL_F8BA0E:
	CALR CancelOperationCleanup

LABEL_F8BA11:
	; (no addr) LD XHL, 0
	; (no addr) RET

FmmSmfUtilityTitleFunc:
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8BBA0
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, LABEL_F8BB9D
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8BBA0
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 007b002ah
	; (no addr) LD XBC, 01e50005h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	LD_8_8 0x7F5E, 0x8D37
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8BA64
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8BA64:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JRL Z, LABEL_F8BB30
	; (no addr) CP WA, 0
	; (no addr) JRL Z, LABEL_F8BB17
	; (no addr) CP WA, 5
	; (no addr) JR Z, LABEL_F8BAD3
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR GE, LABEL_F8BA91
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8BA91:
	; (no addr) CPW (8504h), 0000h
	; (no addr) JRL NZ, LABEL_F8BB7B
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, LABEL_F8BAAD
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	CALR SignalProgressUpdate

LABEL_F8BAAD:
	; (no addr) CPW (8502h), 0000h
	; (no addr) JRL LE, LABEL_F8BB7B
	; (no addr) CP (7F5Eh), 07bh
	; (no addr) JRL Z, LABEL_F8BB7B
	; (no addr) LD XWA, 007b002ah
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD WA, 007bh
	; (no addr) JR T, LABEL_F8BB2A

LABEL_F8BAD3:
	; (no addr) LD XWA, 007b002ah
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F5Eh)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 000h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8BB75

LABEL_F8BB17:
	; (no addr) LD XWA, 007b002ah
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD WA, 007dh

LABEL_F8BB2A:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JR T, LABEL_F8BBA0

LABEL_F8BB30:
	CALR ResetProgressIndication
	; (no addr) LD XWA, 007b002ah
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F5Eh)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 002h
	; (no addr) LD WA, 00eeh

LABEL_F8BB75:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JR T, LABEL_F8BBA0

LABEL_F8BB7B:
	; (no addr) LD XWA, 007b002ah
	; (no addr) LD XBC, 01e50006h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApDeliveryEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8BBA0

LABEL_F8BB9D:
	CALR CancelOperationCleanup

LABEL_F8BBA0:
	; (no addr) LD XHL, 0
	; (no addr) RET

