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
	cp XBC, 0x1c00007
	jr NZ, LABEL_F8B808
	ld WA, 0x61
	ld BC, 0x64
	CALR LABEL_F8B36E

LABEL_F8B808:
	ld XHL, 0
	ret

SaveTtlJgFunc:
	cp XBC, 0x1c00007
	jr NZ, LABEL_F8B819
	ld WA, 0x67
	CALR LABEL_F8B435

LABEL_F8B819:
	ld XHL, 0
	ret

SaveSmfTtlJgFunc:
	cp XBC, 0x1c00007
	jr NZ, LABEL_F8B82A
	ld WA, 0x6b
	CALR LABEL_F8B435

LABEL_F8B82A:
	ld XHL, 0
	ret

DirectPlayTtlJgFunc:
	cp XBC, 0x1c00007
	call Z, LABEL_F8B3D8
	ld XHL, 0
	ret

SongMedleyTtlJgFunc:
	cp XBC, 0x1c00007
	jr NZ, LABEL_F8B849
	ld WA, 0x77
	CALR LABEL_F8B435

LABEL_F8B849:
	ld XHL, 0
	ret

SetupFlashFunc:
	cp XBC, 0x1e5000c
	jr Z, LABEL_F8B87C
	cp XBC, 0x1e5000b
	jr NZ, LABEL_F8B882
	ld (0x7F42), 0x25
	ld WA, 0xee
	call LABEL_F994BD
	ld WA, 6
	call LABEL_FC55A9
	ld (0x7F42), 0x23
	ld WA, 0xee
	call LABEL_F994BD
	jr LABEL_F8B882

LABEL_F8B87C:
	ld WA, 6
	call LABEL_FC5625

LABEL_F8B882:
	ld XHL, 0
	ret

FmmUtilityTitleFunc:
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8BA11
	cp XDE, 0x3
	jrl Z, LABEL_F8BA0E
	cp XDE, 0x2
	jrl NZ, LABEL_F8BA11
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x7b0013
	ld XBC, 0x1e50005
	ld XDE, 0
	call ApDeliveryEvent
	LD_8_8 0x7F5C, 0x8D37
	cpw (0x8500), 0x0
	jr GE, LABEL_F8B8D5
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8B8D5:
	ld WA, (0x8500)
	cp WA, 1
	jrl Z, LABEL_F8B9A1
	cp WA, 0
	jrl Z, LABEL_F8B988
	cp WA, 5
	jr Z, LABEL_F8B944
	cpw (0x8502), 0x0
	jr GE, LABEL_F8B902
	call GetEncodedFileSizeData
	ld (0x8502), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8B902:
	cpw (0x8502), 0x0
	jrl NZ, LABEL_F8B9EC
	cpw (0x8504), 0x0
	jr GE, LABEL_F8B91E
	call GetFileCountEncoded
	ld (0x8504), HL
	CALR SignalProgressUpdate

LABEL_F8B91E:
	cpw (0x8504), 0x0
	jrl LE, LABEL_F8B9EC
	cp (0x7F5C), 0x7c
	jrl Z, LABEL_F8B9EC
	ld XWA, 0x7b0013
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld WA, 0x7c
	jr LABEL_F8B99B

LABEL_F8B944:
	ld XWA, 0x7b0013
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F5C)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x0
	ld WA, 0xee
	jr LABEL_F8B9E6

LABEL_F8B988:
	ld XWA, 0x7b0013
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld WA, 0x7d

LABEL_F8B99B:
	call UI_PostModeChangeEvent
	jr LABEL_F8BA11

LABEL_F8B9A1:
	CALR ResetProgressIndication
	ld XWA, 0x7b0013
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F5C)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x2
	ld WA, 0xee

LABEL_F8B9E6:
	call LABEL_F994BD
	jr LABEL_F8BA11

LABEL_F8B9EC:
	ld XWA, 0x7b0013
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	jr LABEL_F8BA11

LABEL_F8BA0E:
	CALR CancelOperationCleanup

LABEL_F8BA11:
	ld XHL, 0
	ret

FmmSmfUtilityTitleFunc:
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8BBA0
	cp XDE, 0x3
	jrl Z, LABEL_F8BB9D
	cp XDE, 0x2
	jrl NZ, LABEL_F8BBA0
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x7b002a
	ld XBC, 0x1e50005
	ld XDE, 0
	call ApDeliveryEvent
	LD_8_8 0x7F5E, 0x8D37
	cpw (0x8500), 0x0
	jr GE, LABEL_F8BA64
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8BA64:
	ld WA, (0x8500)
	cp WA, 1
	jrl Z, LABEL_F8BB30
	cp WA, 0
	jrl Z, LABEL_F8BB17
	cp WA, 5
	jr Z, LABEL_F8BAD3
	cpw (0x8504), 0x0
	jr GE, LABEL_F8BA91
	call GetFileCountEncoded
	ld (0x8504), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8BA91:
	cpw (0x8504), 0x0
	jrl NZ, LABEL_F8BB7B
	cpw (0x8502), 0x0
	jr GE, LABEL_F8BAAD
	call GetEncodedFileSizeData
	ld (0x8502), HL
	CALR SignalProgressUpdate

LABEL_F8BAAD:
	cpw (0x8502), 0x0
	jrl LE, LABEL_F8BB7B
	cp (0x7F5E), 0x7b
	jrl Z, LABEL_F8BB7B
	ld XWA, 0x7b002a
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld WA, 0x7b
	jr LABEL_F8BB2A

LABEL_F8BAD3:
	ld XWA, 0x7b002a
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F5E)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x0
	ld WA, 0xee
	jr LABEL_F8BB75

LABEL_F8BB17:
	ld XWA, 0x7b002a
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld WA, 0x7d

LABEL_F8BB2A:
	call UI_PostModeChangeEvent
	jr LABEL_F8BBA0

LABEL_F8BB30:
	CALR ResetProgressIndication
	ld XWA, 0x7b002a
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F5E)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x2
	ld WA, 0xee

LABEL_F8BB75:
	call LABEL_F994BD
	jr LABEL_F8BBA0

LABEL_F8BB7B:
	ld XWA, 0x7b002a
	ld XBC, 0x1e50006
	ld XDE, 0
	call ApDeliveryEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	jr LABEL_F8BBA0

LABEL_F8BB9D:
	CALR CancelOperationCleanup

LABEL_F8BBA0:
	ld XHL, 0
	ret

