; =============================================================================
; file_io/composer_filters.asm - Composer Load and Filter Operations
; =============================================================================
; Composer file loading and load/save filter routines.
;
; Key routines:
;   FmmComposerLoadFunc              - Composer file loading
;   FmmLoadFilterFunc                - Load filter settings
;   FmmSaveFilterFunc                - Save filter settings
; =============================================================================

FmmComposerLoadFunc:
	dec 2, XSP
	push IZ
	cp XBC, 0x1c00018
	jrl Z, LABEL_F8D380
	cp XBC, 0x1c00017
	jrl Z, LABEL_F8D380
	cp XBC, 0x1c0000b
	jrl Z, LABEL_F8D30B
	cp XBC, 0x1e50004
	jrl Z, LABEL_F8D2D7
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8D4CA
	cp XDE, 0x3
	jrl Z, LABEL_F8D2D1
	cp XDE, 0x2
	jrl NZ, LABEL_F8D4CA
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	cpw (0x8500), 0x0
	jr GE, LABEL_F8D1E4
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8D1E4:
	ld WA, (0x8500)
	cp WA, 1
	jrl Z, LABEL_F8D289
	cp WA, 0
	jr Z, LABEL_F8D26F
	cp WA, 5
	jr Z, LABEL_F8D22F
	cpw (0x8502), 0x0
	jr GE, LABEL_F8D210
	call GetEncodedFileSizeData
	ld (0x8502), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8D210:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	jrl LABEL_F8D4C6

LABEL_F8D22F:
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
	ld (0x7F42), 0x0
	ld WA, 0xee
	jr LABEL_F8D2CA

LABEL_F8D26F:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x7d
	call UI_PostModeChangeEvent
	jrl LABEL_F8D4CA

LABEL_F8D289:
	CALR ResetProgressIndication
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
	ld (0x7F42), 0x2
	ld WA, 0xee

LABEL_F8D2CA:
	call LABEL_F994BD
	jrl LABEL_F8D4CA

LABEL_F8D2D1:
	CALR CancelOperationCleanup
	jrl LABEL_F8D4CA

LABEL_F8D2D7:
	ld (0x7F7C), XDE
	call GetCurrentFileIndex
	ld (0x7F80), HL
	cp HL, 0
	jr LT, LABEL_F8D2F7
	exts XHL
	ld XWA, (0x7F7C)
	ld XBC, 0x1e50002
	ld XDE, XHL
	jrl LABEL_F8D4C6

LABEL_F8D2F7:
	ldw (0x7F80), 0x0
	ld XWA, (0x7F7C)
	ld XBC, 0x1e50002
	ld XDE, 0
	jrl LABEL_F8D4C6

LABEL_F8D30B:
	ld IZ, 0

LABEL_F8D30D:
	ld WA, IZ
	ld HL, WA
	sll HL, 5
	lda XDE, 0x850C
	extz XHL
	add XHL, XDE
	ld C, IZL
	ld (XHL), C
	ld BC, 3
	call LABEL_F89408
	cp L, 0
	jr Z, LABEL_F8D335
	ld WA, IZ
	call LABEL_F89623
	ld XBC, XHL
	jr LABEL_F8D33A

LABEL_F8D335:
	lda XBC, 0xEA06EC

LABEL_F8D33A:
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
	ld XWA, (0x7F7C)
	ld XBC, 0x1c0000f
	call ApPostEvent
	inc 1, IZ
	cp IZ, 0x14
	jr LT, LABEL_F8D30D
	jrl LABEL_F8D4CA

LABEL_F8D380:
	ld WA, (0x7F80)
	ld (XSP + 0x2), WA
	or XDE, XDE
	jr NZ, LABEL_F8D3B0
	cp XBC, 0x1c00018
	jr NZ, LABEL_F8D39E
	cp WA, 0x13
	jrl GE, LABEL_F8D473
	inc 1, WA
	jr LABEL_F8D3DE

LABEL_F8D39E:
	cp XBC, 0x1c00017
	jrl NZ, LABEL_F8D473
	cp WA, 0
	jrl LE, LABEL_F8D473
	dec 1, WA
	jr LABEL_F8D3DE

LABEL_F8D3B0:
	cp XDE, 0x1
	jr NZ, LABEL_F8D3C5
	cp WA, 0xa
	jrl LT, LABEL_F8D473
	sub WA, 0xa
	jr LABEL_F8D3DE

LABEL_F8D3C5:
	cp XDE, 0x2
	jr NZ, LABEL_F8D3E5
	ld BC, WA
	add BC, 0xa
	cp BC, 0x13
	jrl GT, LABEL_F8D473
	add WA, 0xa

LABEL_F8D3DE:
	ld (0x7F80), WA
	jrl LABEL_F8D477

LABEL_F8D3E5:
	cp XDE, 0x3
	jrl NZ, LABEL_F8D473
	call CheckFileSystemStatus
	cp HL, 0
	jr Z, LABEL_F8D473
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld IZ, 0

LABEL_F8D408:
	ld A, IZL
	extz WA
	call LABEL_F89335
	inc 1, IZ
	cp IZ, 0x8
	jr LT, LABEL_F8D408
	ld WA, 3
	call LABEL_F89321
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F87A08
	ld WA, HL
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
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
	call LABEL_F994BD

LABEL_F8D473:
	ld WA, (0x7F80)

LABEL_F8D477:
	cp (XSP + 0x2), WA
	jr Z, LABEL_F8D4CA
	call NotifyUIOfSelectionChange
	ld DE, (0x7F80)
	exts XDE
	ld XWA, (0x7F7C)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld DE, (XSP + 0x2)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x7F7C)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld DE, (0x7F80)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x7F7C)
	ld XBC, 0x1c0000f

LABEL_F8D4C6:
	call ApPostEvent

LABEL_F8D4CA:
	ld XHL, 0
	pop IZ
	inc 2, XSP
	ret

RenderFilterDisplay:
	dec 6, XSP
	ld (XSP), C
	ld (XSP + 0x2), XWA
	ld XWA, (XSP + 0x2)
	ld C, (XSP)
	ld (XWA+), C
	ld (XSP + 0x2), XWA
	cp (XSP), 0x0
	jr NZ, LABEL_F8D4FA
	call LABEL_F8964C
	cp L, 0
	jr Z, LABEL_F8D4FA
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea06ee
	jrl LABEL_F8D5A9

LABEL_F8D4FA:
	cp (XSP), 0x1
	jr NZ, LABEL_F8D53A
	call LABEL_F8964C
	cp L, 0
	jr Z, LABEL_F8D53A
	ld WA, 0
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D530
	ld WA, 0
	call LABEL_F892F5
	cp L, 0
	jr Z, LABEL_F8D526
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea06f4
	jrl LABEL_F8D5A9

LABEL_F8D526:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea06fa
	jr LABEL_F8D5A9

LABEL_F8D530:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea0700
	jr LABEL_F8D5A9

LABEL_F8D53A:
	ld A, (XSP)
	extz WA
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D566
	ld A, (XSP)
	extz WA
	call LABEL_F892F5
	cp L, 0
	jr Z, LABEL_F8D55C
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea0706
	jr LABEL_F8D5A9

LABEL_F8D55C:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea070c
	jr LABEL_F8D5A9

LABEL_F8D566:
	cp (XSP), 0x2
	jr NZ, LABEL_F8D5A1
	ld WA, 0x8
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D5A1
	ld WA, 0x9
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D5A1
	ld A, (XSP)
	extz WA
	call LABEL_F892F5
	cp L, 0
	jr Z, LABEL_F8D597
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea0712
	jr LABEL_F8D5A9

LABEL_F8D597:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea0718
	jr LABEL_F8D5A9

LABEL_F8D5A1:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea071e

LABEL_F8D5A9:
	call LABEL_F890DC
	inc 6, XSP
	ret

FmmLoadFilterFunc:
	dec 6, XSP
	ld (XSP + 0x2), XDE
	cp XBC, 0x1c00018
	jr Z, LABEL_F8D61D
	cp XBC, 0x1c00017
	jr Z, LABEL_F8D61D
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8D5E0
	cp XBC, 0x1e50004
	jrl NZ, LABEL_F8D77F
	ld XWA, (XSP + 0x2)
	ld (0x7F82), XWA
	jrl LABEL_F8D77F

LABEL_F8D5E0:
	ldw (XSP), 0x0

LABEL_F8D5E4:
	ld WA, (XSP)
	sll WA, 4
	lda XBC, 0x7F86
	extz XWA
	add XWA, XBC
	ld BC, (XSP)
	extz BC
	CALR RenderFilterDisplay
	ld DE, (XSP)
	sll DE, 4
	lda XBC, 0x7F86
	extz XDE
	add XDE, XBC
	ld XWA, (0x7F82)
	ld XBC, 0x1c0000f
	call ApPostEvent
	INCW 1, (XSP)
	cpw (XSP), 0x8
	jr LT, LABEL_F8D5E4
	jrl LABEL_F8D77F

LABEL_F8D61D:
	ld XWA, (XSP + 0x2)
	cp XWA, 0x8
	jrl NC, LABEL_F8D6C6
	cp XBC, 0x1c00017
	jr NZ, LABEL_F8D65F
	cp XWA, 0x1
	jr NZ, LABEL_F8D645
	call LABEL_F8964C
	cp L, 0
	jr Z, LABEL_F8D645
	ld WA, 0
	jr LABEL_F8D659

LABEL_F8D645:
	ld XWA, (XSP + 0x2)
	or XWA, XWA
	jr NZ, LABEL_F8D654
	call LABEL_F8964C
	cp L, 0
	jr NZ, LABEL_F8D68E

LABEL_F8D654:
	ld XWA, (XSP + 0x2)
	extz WA

LABEL_F8D659:
	call LABEL_F89321
	jr LABEL_F8D68E

LABEL_F8D65F:
	ld XWA, (XSP + 0x2)
	cp XWA, 0x1
	jr NZ, LABEL_F8D676
	call LABEL_F8964C
	cp L, 0
	jr Z, LABEL_F8D676
	ld WA, 0
	jr LABEL_F8D68A

LABEL_F8D676:
	ld XWA, (XSP + 0x2)
	or XWA, XWA
	jr NZ, LABEL_F8D685
	call LABEL_F8964C
	cp L, 0
	jr NZ, LABEL_F8D68E

LABEL_F8D685:
	ld XWA, (XSP + 0x2)
	extz WA

LABEL_F8D68A:
	call LABEL_F89335

LABEL_F8D68E:
	ld XWA, (XSP + 0x2)
	ld C, A
	extz BC
	ld WA, BC
	sla WA, 0x4
	lda XDE, 0x7F86
	exts XWA
	add XWA, XDE
	CALR RenderFilterDisplay
	ld XWA, (XSP + 0x2)
	extz WA
	sla WA, 0x4
	lda XBC, 0x7F86
	lda XDE, XBC + WA
	ld XWA, (0x7F82)
	ld XBC, 0x1c0000f
	call ApPostEvent
	jrl LABEL_F8D77F

LABEL_F8D6C6:
	ld XWA, (XSP + 0x2)
	cp XWA, 0xa
	jrl NZ, LABEL_F8D77F
	call CheckFileSystemStatus
	cp HL, 0
	jrl Z, LABEL_F8D77F
	call LABEL_F892EF
	cp HL, 0
	jrl Z, LABEL_F8D77F
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	call GetCurrentFileIndex
	extz HL
	ld WA, HL
	CALR LABEL_F8B337
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F87A08
	ld WA, HL
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	cpw (0xF19E), 0x0
	jr Z, LABEL_F8D762
	ld WA, 2
	call LABEL_F892F5
	cp L, 0
	jr Z, LABEL_F8D762
	ld WA, 2
	call LABEL_F893D1
	cp L, 0
	jr NZ, LABEL_F8D75D
	ld WA, 0x8
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D762

LABEL_F8D75D:
	ld WA, 0xa
	jr LABEL_F8D764

LABEL_F8D762:
	ld WA, 1

LABEL_F8D764:
	call LABEL_F99463
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	call LABEL_F994BD

LABEL_F8D77F:
	ld XHL, 0
	inc 6, XSP
	ret

RenderSaveFilterDisplay:
	dec 6, XSP
	ld (XSP), C
	ld (XSP + 0x2), XWA
	ld XWA, (XSP + 0x2)
	ld C, (XSP)
	ld (XWA+), C
	ld (XSP + 0x2), XWA
	ld A, C
	extz WA
	call LABEL_F89353
	cp L, 0
	jr Z, LABEL_F8D7C3
	cp (XSP), 0x1
	jr NZ, LABEL_F8D7B9
	call LABEL_F893AB
	cp L, 0
	jr Z, LABEL_F8D7B9
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea0724
	jr LABEL_F8D7CB

LABEL_F8D7B9:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea072a
	jr LABEL_F8D7CB

LABEL_F8D7C3:
	ld XWA, (XSP + 0x2)
	ld XBC, 0xea0730

LABEL_F8D7CB:
	call LABEL_F890DC
	inc 6, XSP
	ret

FmmSaveFilterFunc:
	dec 6, XSP
	ld (XSP + 0x2), XDE
	cp XBC, 0x1c00018
	jr Z, LABEL_F8D83F
	cp XBC, 0x1c00017
	jr Z, LABEL_F8D83F
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8D802
	cp XBC, 0x1e50004
	jrl NZ, LABEL_F8DB48
	ld XWA, (XSP + 0x2)
	ld (0x8006), XWA
	jrl LABEL_F8DB48

LABEL_F8D802:
	ldw (XSP), 0x0

LABEL_F8D806:
	ld WA, (XSP)
	sll WA, 4
	lda XBC, 0x800A
	extz XWA
	add XWA, XBC
	ld BC, (XSP)
	extz BC
	CALR RenderSaveFilterDisplay
	ld DE, (XSP)
	sll DE, 4
	lda XBC, 0x800A
	extz XDE
	add XDE, XBC
	ld XWA, (0x8006)
	ld XBC, 0x1c0000f
	call ApPostEvent
	INCW 1, (XSP)
	cpw (XSP), 0x8
	jr LT, LABEL_F8D806
	jrl LABEL_F8DB48

LABEL_F8D83F:
	ld XWA, (XSP + 0x2)
	cp XWA, 0x8
	jrl NC, LABEL_F8D8EF
	cp XWA, 0x1
	jr NZ, LABEL_F8D8A4
	cp XBC, 0x1c00017
	jr NZ, LABEL_F8D875
	call LABEL_F893AB
	cp L, 0
	jr Z, LABEL_F8D86E
	call LABEL_F893CA
	ld XWA, (XSP + 0x2)
	extz WA
	jr LABEL_F8D8B7

LABEL_F8D86E:
	ld XWA, (XSP + 0x2)
	extz WA
	jr LABEL_F8D8B1

LABEL_F8D875:
	ld XWA, (XSP + 0x2)
	extz WA
	call LABEL_F89353
	cp L, 0
	jr Z, LABEL_F8D891
	call LABEL_F893AB
	cp L, 0
	jr NZ, LABEL_F8D8BB
	ld XWA, (XSP + 0x2)
	extz WA
	jr LABEL_F8D8B7

LABEL_F8D891:
	call LABEL_F893AB
	cp L, 0
	jr NZ, LABEL_F8D8BB
	call LABEL_F893C3
	ld XWA, (XSP + 0x2)
	extz WA
	jr LABEL_F8D8B1

LABEL_F8D8A4:
	ld XWA, (XSP + 0x2)
	extz WA
	cp XBC, 0x1c00017
	jr NZ, LABEL_F8D8B7

LABEL_F8D8B1:
	call LABEL_F8937F
	jr LABEL_F8D8BB

LABEL_F8D8B7:
	call LABEL_F89393

LABEL_F8D8BB:
	ld XWA, (XSP + 0x2)
	ld C, A
	extz BC
	ld WA, BC
	sla WA, 0x4
	lda XDE, 0x800A
	exts XWA
	add XWA, XDE
	CALR RenderSaveFilterDisplay
	ld XWA, (XSP + 0x2)
	extz WA
	sla WA, 0x4
	lda XBC, 0x800A
	lda XDE, XBC + WA
	ld XWA, (0x8006)
	ld XBC, 0x1c0000f
	jrl LABEL_F8D9FD

LABEL_F8D8EF:
	ld XWA, (XSP + 0x2)
	cp XWA, 0x8
	jr NZ, LABEL_F8D94F
	call LABEL_F893CA
	ldw (XSP), 0x0

LABEL_F8D902:
	ld WA, (XSP)
	extz WA
	cpw (XSP), 0x6
	jr GE, LABEL_F8D912
	call LABEL_F8937F
	jr LABEL_F8D916

LABEL_F8D912:
	call LABEL_F89393

LABEL_F8D916:
	ld WA, (XSP)
	sll WA, 4
	lda XBC, 0x800A
	extz XWA
	add XWA, XBC
	ld BC, (XSP)
	extz BC
	CALR RenderSaveFilterDisplay
	ld DE, (XSP)
	sll DE, 4
	lda XBC, 0x800A
	extz XDE
	add XDE, XBC
	ld XWA, (0x8006)
	ld XBC, 0x1c0000f
	call ApPostEvent
	INCW 1, (XSP)
	cpw (XSP), 0x8
	jr LT, LABEL_F8D902
	jrl LABEL_F8DB48

LABEL_F8D94F:
	ld XWA, (XSP + 0x2)
	cp XWA, 0x9
	jr NZ, LABEL_F8D9A3
	call LABEL_F893CA
	ldw (XSP), 0x0

LABEL_F8D962:
	ld WA, (XSP)
	extz WA
	call LABEL_F8937F
	ld WA, (XSP)
	sll WA, 4
	lda XBC, 0x800A
	extz XWA
	add XWA, XBC
	ld BC, (XSP)
	extz BC
	CALR RenderSaveFilterDisplay
	ld DE, (XSP)
	sll DE, 4
	lda XBC, 0x800A
	extz XDE
	add XDE, XBC
	ld XWA, (0x8006)
	ld XBC, 0x1c0000f
	call ApPostEvent
	INCW 1, (XSP)
	cpw (XSP), 0x8
	jr LT, LABEL_F8D962
	jrl LABEL_F8DB48

LABEL_F8D9A3:
	ld XWA, (XSP + 0x2)
	cp XWA, 0xa
	jrl NZ, LABEL_F8DA76
	call LABEL_F8934D
	cp HL, 0
	jrl Z, LABEL_F8DA76
	CALR SelectPasswordMode
	cp HL, 0
	jr Z, LABEL_F8D9D1
	ld XDE, 0
	ld E, (0x8A0C)
	ld XWA, 0xffffffff
	ld XBC, 0x1c50004
	jr LABEL_F8D9FD

LABEL_F8D9D1:
	call CheckFileSystemStatus
	cp HL, 0
	jr Z, LABEL_F8DA04
	cp (0x340EA), 0x0
	jr Z, LABEL_F8DA04
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x600037
	ld XBC, 0x1c00001
	ld XDE, 0

LABEL_F8D9FD:
	call ApPostEvent
	jrl LABEL_F8DB48

LABEL_F8DA04:
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F87EAD
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
	jr LABEL_F8DAF1

LABEL_F8DA76:
	ld XWA, (XSP + 0x2)
	cp XWA, 0x32
	jr NZ, LABEL_F8DAF7
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F87EAD
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

LABEL_F8DAF1:
	call LABEL_F994BD
	jr LABEL_F8DB48

LABEL_F8DAF7:
	ld XWA, (XSP + 0x2)
	cp XWA, 0xb
	jr NZ, LABEL_F8DB48
	call LABEL_F893CA
	ldw (XSP), 0x0

LABEL_F8DB0A:
	ld WA, (XSP)
	extz WA
	call LABEL_F89393
	ld WA, (XSP)
	sll WA, 4
	lda XBC, 0x800A
	extz XWA
	add XWA, XBC
	ld BC, (XSP)
	extz BC
	CALR RenderSaveFilterDisplay
	ld DE, (XSP)
	sll DE, 4
	lda XBC, 0x800A
	extz XDE
	add XDE, XBC
	ld XWA, (0x8006)
	ld XBC, 0x1c0000f
	call ApPostEvent
	INCW 1, (XSP)
	cpw (XSP), 0x8
	jr LT, LABEL_F8DB0A

LABEL_F8DB48:
	ld XHL, 0
	inc 6, XSP
	ret

