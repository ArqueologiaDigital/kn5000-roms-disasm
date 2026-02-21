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
	; (no addr) DEC 2, XSP
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c00018h
	; (no addr) JRL Z, LABEL_F8D380
	; (no addr) CP XBC, 01c00017h
	; (no addr) JRL Z, LABEL_F8D380
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JRL Z, LABEL_F8D30B
	; (no addr) CP XBC, 01e50004h
	; (no addr) JRL Z, LABEL_F8D2D7
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8D4CA
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, LABEL_F8D2D1
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8D4CA
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8D1E4
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8D1E4:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JRL Z, LABEL_F8D289
	; (no addr) CP WA, 0
	; (no addr) JR Z, LABEL_F8D26F
	; (no addr) CP WA, 5
	; (no addr) JR Z, LABEL_F8D22F
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, LABEL_F8D210
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8D210:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) JRL T, LABEL_F8D4C6

LABEL_F8D22F:
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
	; (no addr) LD (7F42h), 000h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8D2CA

LABEL_F8D26F:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007dh
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JRL T, LABEL_F8D4CA

LABEL_F8D289:
	CALR ResetProgressIndication
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
	; (no addr) LD (7F42h), 002h
	; (no addr) LD WA, 00eeh

LABEL_F8D2CA:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, LABEL_F8D4CA

LABEL_F8D2D1:
	CALR CancelOperationCleanup
	; (no addr) JRL T, LABEL_F8D4CA

LABEL_F8D2D7:
	; (no addr) LD (7F7Ch), XDE
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD (7F80h), HL
	; (no addr) CP HL, 0
	; (no addr) JR LT, LABEL_F8D2F7
	; (no addr) EXTS XHL
	; (no addr) LD XWA, (7F7Ch)
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	; (no addr) JRL T, LABEL_F8D4C6

LABEL_F8D2F7:
	; (no addr) LDW (7F80h), 0000h
	; (no addr) LD XWA, (7F7Ch)
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, 0
	; (no addr) JRL T, LABEL_F8D4C6

LABEL_F8D30B:
	; (no addr) LD IZ, 0

LABEL_F8D30D:
	; (no addr) LD WA, IZ
	; (no addr) LD HL, WA
	; (no addr) SLL 5, HL
	; (no addr) LDA XDE, 850Ch
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XDE
	; (no addr) LD C, IZL
	; (no addr) LD (XHL), C
	; (no addr) LD BC, 3
	; (no addr) CALL LABEL_F89408
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D335
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) JR T, LABEL_F8D33A

LABEL_F8D335:
	; (no addr) LDA XBC, 0EA06ECh

LABEL_F8D33A:
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
	; (no addr) LD XWA, (7F7Ch)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0014h
	; (no addr) JR LT, LABEL_F8D30D
	; (no addr) JRL T, LABEL_F8D4CA

LABEL_F8D380:
	; (no addr) LD WA, (7F80h)
	; (no addr) LD (XSP + 002h), WA
	; (no addr) OR XDE, XDE
	; (no addr) JR NZ, LABEL_F8D3B0
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, LABEL_F8D39E
	; (no addr) CP WA, 0013h
	; (no addr) JRL GE, LABEL_F8D473
	; (no addr) INC 1, WA
	; (no addr) JR T, LABEL_F8D3DE

LABEL_F8D39E:
	; (no addr) CP XBC, 01c00017h
	; (no addr) JRL NZ, LABEL_F8D473
	; (no addr) CP WA, 0
	; (no addr) JRL LE, LABEL_F8D473
	; (no addr) DEC 1, WA
	; (no addr) JR T, LABEL_F8D3DE

LABEL_F8D3B0:
	; (no addr) CP XDE, 00000001h
	; (no addr) JR NZ, LABEL_F8D3C5
	; (no addr) CP WA, 000ah
	; (no addr) JRL LT, LABEL_F8D473
	; (no addr) SUB WA, 000ah
	; (no addr) JR T, LABEL_F8D3DE

LABEL_F8D3C5:
	; (no addr) CP XDE, 00000002h
	; (no addr) JR NZ, LABEL_F8D3E5
	; (no addr) LD BC, WA
	; (no addr) ADD BC, 000ah
	; (no addr) CP BC, 0013h
	; (no addr) JRL GT, LABEL_F8D473
	; (no addr) ADD WA, 000ah

LABEL_F8D3DE:
	; (no addr) LD (7F80h), WA
	; (no addr) JRL T, LABEL_F8D477

LABEL_F8D3E5:
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL NZ, LABEL_F8D473
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8D473
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD IZ, 0

LABEL_F8D408:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89335
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0008h
	; (no addr) JR LT, LABEL_F8D408
	; (no addr) LD WA, 3
	; (no addr) CALL LABEL_F89321
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F87A08
	; (no addr) LD WA, HL
	; (no addr) LD BC, 1
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
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
	; (no addr) CALL LABEL_F994BD

LABEL_F8D473:
	; (no addr) LD WA, (7F80h)

LABEL_F8D477:
	; (no addr) CP (XSP + 002h), WA
	; (no addr) JR Z, LABEL_F8D4CA
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) LD DE, (7F80h)
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (7F7Ch)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD DE, (XSP + 002h)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (7F7Ch)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LD DE, (7F80h)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (7F7Ch)
	; (no addr) LD XBC, 01c0000fh

LABEL_F8D4C6:
	; (no addr) CALL ApPostEvent

LABEL_F8D4CA:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) INC 2, XSP
	; (no addr) RET

RenderFilterDisplay:
	; (no addr) DEC 6, XSP
	; (no addr) LD (XSP), C
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD C, (XSP)
	; (no addr) LD (XWA+), C
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) CP (XSP), 000h
	; (no addr) JR NZ, LABEL_F8D4FA
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D4FA
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea06eeh
	; (no addr) JRL T, LABEL_F8D5A9

LABEL_F8D4FA:
	; (no addr) CP (XSP), 001h
	; (no addr) JR NZ, LABEL_F8D53A
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D53A
	; (no addr) LD WA, 0
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D530
	; (no addr) LD WA, 0
	; (no addr) CALL LABEL_F892F5
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D526
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea06f4h
	; (no addr) JRL T, LABEL_F8D5A9

LABEL_F8D526:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea06fah
	; (no addr) JR T, LABEL_F8D5A9

LABEL_F8D530:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea0700h
	; (no addr) JR T, LABEL_F8D5A9

LABEL_F8D53A:
	; (no addr) LD A, (XSP)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D566
	; (no addr) LD A, (XSP)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F892F5
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D55C
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea0706h
	; (no addr) JR T, LABEL_F8D5A9

LABEL_F8D55C:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea070ch
	; (no addr) JR T, LABEL_F8D5A9

LABEL_F8D566:
	; (no addr) CP (XSP), 002h
	; (no addr) JR NZ, LABEL_F8D5A1
	; (no addr) LD WA, 0008h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D5A1
	; (no addr) LD WA, 0009h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D5A1
	; (no addr) LD A, (XSP)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F892F5
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D597
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea0712h
	; (no addr) JR T, LABEL_F8D5A9

LABEL_F8D597:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea0718h
	; (no addr) JR T, LABEL_F8D5A9

LABEL_F8D5A1:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea071eh

LABEL_F8D5A9:
	; (no addr) CALL LABEL_F890DC
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmLoadFilterFunc:
	; (no addr) DEC 6, XSP
	; (no addr) LD (XSP + 002h), XDE
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR Z, LABEL_F8D61D
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR Z, LABEL_F8D61D
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8D5E0
	; (no addr) CP XBC, 01e50004h
	; (no addr) JRL NZ, LABEL_F8D77F
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD (7F82h), XWA
	; (no addr) JRL T, LABEL_F8D77F

LABEL_F8D5E0:
	; (no addr) LDW (XSP), 0000h

LABEL_F8D5E4:
	; (no addr) LD WA, (XSP)
	; (no addr) SLL 4, WA
	; (no addr) LDA XBC, 7F86h
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, (XSP)
	; (no addr) EXTZ BC
	CALR RenderFilterDisplay
	; (no addr) LD DE, (XSP)
	; (no addr) SLL 4, DE
	; (no addr) LDA XBC, 7F86h
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (7F82h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INCW 1, (XSP)
	; (no addr) CPW (XSP), 0008h
	; (no addr) JR LT, LABEL_F8D5E4
	; (no addr) JRL T, LABEL_F8D77F

LABEL_F8D61D:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 00000008h
	; (no addr) JRL NC, LABEL_F8D6C6
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, LABEL_F8D65F
	; (no addr) CP XWA, 00000001h
	; (no addr) JR NZ, LABEL_F8D645
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D645
	; (no addr) LD WA, 0
	; (no addr) JR T, LABEL_F8D659

LABEL_F8D645:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) OR XWA, XWA
	; (no addr) JR NZ, LABEL_F8D654
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8D68E

LABEL_F8D654:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA

LABEL_F8D659:
	; (no addr) CALL LABEL_F89321
	; (no addr) JR T, LABEL_F8D68E

LABEL_F8D65F:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 00000001h
	; (no addr) JR NZ, LABEL_F8D676
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D676
	; (no addr) LD WA, 0
	; (no addr) JR T, LABEL_F8D68A

LABEL_F8D676:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) OR XWA, XWA
	; (no addr) JR NZ, LABEL_F8D685
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8D68E

LABEL_F8D685:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA

LABEL_F8D68A:
	; (no addr) CALL LABEL_F89335

LABEL_F8D68E:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD C, A
	; (no addr) EXTZ BC
	; (no addr) LD WA, BC
	; (no addr) SLA 004h, WA
	; (no addr) LDA XDE, 7F86h
	; (no addr) EXTS XWA
	; (no addr) ADD XWA, XDE
	CALR RenderFilterDisplay
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) SLA 004h, WA
	; (no addr) LDA XBC, 7F86h
	; (no addr) LDA XDE, XBC + WA
	; (no addr) LD XWA, (7F82h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, LABEL_F8D77F

LABEL_F8D6C6:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 0000000ah
	; (no addr) JRL NZ, LABEL_F8D77F
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8D77F
	; (no addr) CALL LABEL_F892EF
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8D77F
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) EXTZ HL
	; (no addr) LD WA, HL
	CALR LABEL_F8B337
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F87A08
	; (no addr) LD WA, HL
	; (no addr) LD BC, 1
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (0F19Eh), 0000h
	; (no addr) JR Z, LABEL_F8D762
	; (no addr) LD WA, 2
	; (no addr) CALL LABEL_F892F5
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D762
	; (no addr) LD WA, 2
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8D75D
	; (no addr) LD WA, 0008h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D762

LABEL_F8D75D:
	; (no addr) LD WA, 000ah
	; (no addr) JR T, LABEL_F8D764

LABEL_F8D762:
	; (no addr) LD WA, 1

LABEL_F8D764:
	; (no addr) CALL LABEL_F99463
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD

LABEL_F8D77F:
	; (no addr) LD XHL, 0
	; (no addr) INC 6, XSP
	; (no addr) RET

RenderSaveFilterDisplay:
	; (no addr) DEC 6, XSP
	; (no addr) LD (XSP), C
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD C, (XSP)
	; (no addr) LD (XWA+), C
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) LD A, C
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89353
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D7C3
	; (no addr) CP (XSP), 001h
	; (no addr) JR NZ, LABEL_F8D7B9
	; (no addr) CALL LABEL_F893AB
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D7B9
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea0724h
	; (no addr) JR T, LABEL_F8D7CB

LABEL_F8D7B9:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea072ah
	; (no addr) JR T, LABEL_F8D7CB

LABEL_F8D7C3:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 00ea0730h

LABEL_F8D7CB:
	; (no addr) CALL LABEL_F890DC
	; (no addr) INC 6, XSP
	; (no addr) RET

FmmSaveFilterFunc:
	; (no addr) DEC 6, XSP
	; (no addr) LD (XSP + 002h), XDE
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR Z, LABEL_F8D83F
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR Z, LABEL_F8D83F
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8D802
	; (no addr) CP XBC, 01e50004h
	; (no addr) JRL NZ, LABEL_F8DB48
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD (8006h), XWA
	; (no addr) JRL T, LABEL_F8DB48

LABEL_F8D802:
	; (no addr) LDW (XSP), 0000h

LABEL_F8D806:
	; (no addr) LD WA, (XSP)
	; (no addr) SLL 4, WA
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, (XSP)
	; (no addr) EXTZ BC
	CALR RenderSaveFilterDisplay
	; (no addr) LD DE, (XSP)
	; (no addr) SLL 4, DE
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (8006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INCW 1, (XSP)
	; (no addr) CPW (XSP), 0008h
	; (no addr) JR LT, LABEL_F8D806
	; (no addr) JRL T, LABEL_F8DB48

LABEL_F8D83F:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 00000008h
	; (no addr) JRL NC, LABEL_F8D8EF
	; (no addr) CP XWA, 00000001h
	; (no addr) JR NZ, LABEL_F8D8A4
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, LABEL_F8D875
	; (no addr) CALL LABEL_F893AB
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D86E
	; (no addr) CALL LABEL_F893CA
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) JR T, LABEL_F8D8B7

LABEL_F8D86E:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) JR T, LABEL_F8D8B1

LABEL_F8D875:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89353
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D891
	; (no addr) CALL LABEL_F893AB
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8D8BB
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) JR T, LABEL_F8D8B7

LABEL_F8D891:
	; (no addr) CALL LABEL_F893AB
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8D8BB
	; (no addr) CALL LABEL_F893C3
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) JR T, LABEL_F8D8B1

LABEL_F8D8A4:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, LABEL_F8D8B7

LABEL_F8D8B1:
	; (no addr) CALL LABEL_F8937F
	; (no addr) JR T, LABEL_F8D8BB

LABEL_F8D8B7:
	; (no addr) CALL LABEL_F89393

LABEL_F8D8BB:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD C, A
	; (no addr) EXTZ BC
	; (no addr) LD WA, BC
	; (no addr) SLA 004h, WA
	; (no addr) LDA XDE, 800Ah
	; (no addr) EXTS XWA
	; (no addr) ADD XWA, XDE
	CALR RenderSaveFilterDisplay
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) EXTZ WA
	; (no addr) SLA 004h, WA
	; (no addr) LDA XBC, 800Ah
	; (no addr) LDA XDE, XBC + WA
	; (no addr) LD XWA, (8006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) JRL T, LABEL_F8D9FD

LABEL_F8D8EF:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 00000008h
	; (no addr) JR NZ, LABEL_F8D94F
	; (no addr) CALL LABEL_F893CA
	; (no addr) LDW (XSP), 0000h

LABEL_F8D902:
	; (no addr) LD WA, (XSP)
	; (no addr) EXTZ WA
	; (no addr) CPW (XSP), 0006h
	; (no addr) JR GE, LABEL_F8D912
	; (no addr) CALL LABEL_F8937F
	; (no addr) JR T, LABEL_F8D916

LABEL_F8D912:
	; (no addr) CALL LABEL_F89393

LABEL_F8D916:
	; (no addr) LD WA, (XSP)
	; (no addr) SLL 4, WA
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, (XSP)
	; (no addr) EXTZ BC
	CALR RenderSaveFilterDisplay
	; (no addr) LD DE, (XSP)
	; (no addr) SLL 4, DE
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (8006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INCW 1, (XSP)
	; (no addr) CPW (XSP), 0008h
	; (no addr) JR LT, LABEL_F8D902
	; (no addr) JRL T, LABEL_F8DB48

LABEL_F8D94F:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 00000009h
	; (no addr) JR NZ, LABEL_F8D9A3
	; (no addr) CALL LABEL_F893CA
	; (no addr) LDW (XSP), 0000h

LABEL_F8D962:
	; (no addr) LD WA, (XSP)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F8937F
	; (no addr) LD WA, (XSP)
	; (no addr) SLL 4, WA
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, (XSP)
	; (no addr) EXTZ BC
	CALR RenderSaveFilterDisplay
	; (no addr) LD DE, (XSP)
	; (no addr) SLL 4, DE
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (8006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INCW 1, (XSP)
	; (no addr) CPW (XSP), 0008h
	; (no addr) JR LT, LABEL_F8D962
	; (no addr) JRL T, LABEL_F8DB48

LABEL_F8D9A3:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 0000000ah
	; (no addr) JRL NZ, LABEL_F8DA76
	; (no addr) CALL LABEL_F8934D
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8DA76
	CALR SelectPasswordMode
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8D9D1
	; (no addr) LD XDE, 0
	; (no addr) LD E, (8A0Ch)
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50004h
	; (no addr) JR T, LABEL_F8D9FD

LABEL_F8D9D1:
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8DA04
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, LABEL_F8DA04
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0

LABEL_F8D9FD:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, LABEL_F8DB48

LABEL_F8DA04:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F87EAD
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
	; (no addr) JR T, LABEL_F8DAF1

LABEL_F8DA76:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 00000032h
	; (no addr) JR NZ, LABEL_F8DAF7
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F87EAD
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

LABEL_F8DAF1:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JR T, LABEL_F8DB48

LABEL_F8DAF7:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CP XWA, 0000000bh
	; (no addr) JR NZ, LABEL_F8DB48
	; (no addr) CALL LABEL_F893CA
	; (no addr) LDW (XSP), 0000h

LABEL_F8DB0A:
	; (no addr) LD WA, (XSP)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89393
	; (no addr) LD WA, (XSP)
	; (no addr) SLL 4, WA
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XWA
	; (no addr) ADD XWA, XBC
	; (no addr) LD BC, (XSP)
	; (no addr) EXTZ BC
	CALR RenderSaveFilterDisplay
	; (no addr) LD DE, (XSP)
	; (no addr) SLL 4, DE
	; (no addr) LDA XBC, 800Ah
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (8006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INCW 1, (XSP)
	; (no addr) CPW (XSP), 0008h
	; (no addr) JR LT, LABEL_F8DB0A

LABEL_F8DB48:
	; (no addr) LD XHL, 0
	; (no addr) INC 6, XSP
	; (no addr) RET

