; =============================================================================
; file_io/misc_ui.asm - Miscellaneous UI and Utilities
; =============================================================================
; Jump insert, file priority, setup, waiting, and filename box UI.
;
; Key routines:
;   JumpInsertFunc                   - Jump insert function
;   FilePriorityFunc                 - File priority handling
;   SetupOkFunc                      - Setup OK handler
;   SetupExitFunc                    - Setup exit handler
;   WaitingFunc                      - Waiting state handler
;   DiskMedleyShowHideFunc           - Disk medley show/hide
;   PsFileNameBoxProc                - Filename input box UI
; =============================================================================

JumpInsertFunc:
	push XIZ
	ld XIZ, XWA
	sub XBC, 0x1e0003e
	cp XBC, 0x0
	jr LT, LABEL_F950D6
	cp XBC, 0x9
	jr GT, LABEL_F950D6
	add XBC, XBC
	add XBC, 0xea96e4
	ld BC, (XBC)
	lda XIX, 0xF950B0
	jp XIX + BC
LABEL_F950B0:
	.byte 0xAA, 0xE, 0x20, 0xE8, 0xEE, 0x2, 0x41, 0x8A
	.byte 0x96, 0xEA, 0x0, 0xE8, 0x81, 0xA1, 0x20, 0x38
	.byte 0xAA, 0x12, 0x20, 0x38, 0x1D, 0x4D, 0xF, 0xFF
	.byte 0xEF, 0x60, 0xEE, 0x8B, 0x68, 0x11, 0xEB, 0xA9
	.byte 0x68, 0xD, 0xEB, 0xAC, 0x68, 0x9

LABEL_F950D6:
	ld XHL, 0
	jr LABEL_F950DF
	lda XHL, 0x340F2

LABEL_F950DF:
	pop XIZ
	ret

FilePriorityFunc:
	push XIZ
	ld XIZ, XWA
	cp XBC, 0x1e00065
	jr Z, LABEL_F95132
	cp XBC, 0x1e00064
	jr Z, LABEL_F9512E
	cp XBC, 0x1e00063
	jr Z, LABEL_F95127
	cp XBC, 0x1e00062
	jr NZ, LABEL_F95132
	ld WA, (XDE + 0x8)
	and WA, 0x1
	sla WA, 0x2
	lda XBC, 0xEA96F8
	ld XWA, (XBC + WA)
	push XWA
	ld XWA, (XDE + 0xa)
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	ld XHL, XIZ
	jr LABEL_F95134

LABEL_F95127:
	lda XHL, 0x340F4
	jr LABEL_F95134

LABEL_F9512E:
	ld XHL, 1
	jr LABEL_F95134

LABEL_F95132:
	ld XHL, 0

LABEL_F95134:
	pop XIZ
	ret

SetupOkFunc:
	cp XBC, 0x1c00007
	jr NZ, LABEL_F9514C
	ld XWA, 0x1450030
	ld XBC, 0x1e5000b
	call MainFuncCall

LABEL_F9514C:
	ld XHL, 0
	ret

SetupExitFunc:
	push XIZ
	ld XIZ, XDE
	cp XBC, 0x1c00002
	jr NZ, LABEL_F951B6
	ld XDE, XIZ
	call InheritedProc
	or XIZ, XIZ
	jr NZ, LABEL_F951B6
	ld WA, 6
	call LABEL_FC56A1
	cp HL, 0
	jr Z, LABEL_F951B6
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call SendEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call PostEvent
	ld (0x7F42), 0x48
	ld XWA, 0xffffffff
	ld XBC, 0x1c00016
	ld XDE, 0x1a000ee
	call PostEvent
	ld XWA, 0x1450030
	ld XBC, 0x1e5000c
	ld XDE, XIZ
	call MainFuncCall

LABEL_F951B6:
	ld XHL, 0
	pop XIZ
	ret

TechnicsFileNaming:
	dec 4, XSP
	push XIZ
	ld XIZ, XBC
	ld (XSP + 0x4), XWA
	cp XIZ, 0x1c00007
	jr Z, LABEL_F95200
	cp XIZ, 0x1e0007c
	jr Z, LABEL_F951FC
	cp XIZ, 0x1e00084
	jr Z, LABEL_F951F8
	cp XIZ, 0x1e0003a
	jr NZ, LABEL_F9523A
	call GetNamingWindowID
	ld XWA, 0x145000e
	ld XBC, XIZ
	ld XDE, XHL
	call MainFuncCall
	ld XHL, (XSP + 0x4)
	jr LABEL_F9523C

LABEL_F951F8:
	ld XHL, 1
	jr LABEL_F9523C

LABEL_F951FC:
	ld XHL, 6
	jr LABEL_F9523C

LABEL_F95200:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x2742c
	call SendEvent
	ld XWA, 0x145000e
	ld XBC, 0x1e00086
	ld XDE, 0x2742c
	call MainFuncCall
	ld XWA, 0xffffffff
	ld XBC, 0x1c00015
	ld XDE, 0x1a00067
	call SendEvent

LABEL_F9523A:
	ld XHL, 0

LABEL_F9523C:
	pop XIZ
	inc 4, XSP
	ret

TechnicsFileRename:
	dec 4, XSP
	push XIZ
	ld XIZ, XBC
	ld (XSP + 0x4), XWA
	cp XIZ, 0x1c00007
	jr Z, LABEL_F95286
	cp XIZ, 0x1e0007c
	jr Z, LABEL_F95282
	cp XIZ, 0x1e00084
	jr Z, LABEL_F9527E
	cp XIZ, 0x1e0003a
	jr NZ, LABEL_F952BD
	call GetNamingWindowID
	ld XWA, 0x1450022
	ld XBC, XIZ
	ld XDE, XHL
	call MainFuncCall
	ld XHL, (XSP + 0x4)
	jr LABEL_F952BF

LABEL_F9527E:
	ld XHL, 1
	jr LABEL_F952BF

LABEL_F95282:
	ld XHL, 6
	jr LABEL_F952BF

LABEL_F95286:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x2743e
	call SendEvent
	ld XWA, 0x1450022
	ld XBC, 0x1e00086
	ld XDE, 0x2743e
	call MainFuncCall
	ld XWA, 0x7b0000
	ld XBC, 0x1c00001
	ld XDE, 0
	call PostEvent

LABEL_F952BD:
	ld XHL, 0

LABEL_F952BF:
	pop XIZ
	inc 4, XSP
	ret

SmfFileNaming:
	dec 4, XSP
	push XIZ
	ld XIZ, XBC
	ld (XSP + 0x4), XWA
	cp XIZ, 0x1c00007
	jr Z, LABEL_F9530C
	cp XIZ, 0x1e0007c
	jr Z, LABEL_F95305
	cp XIZ, 0x1e00084
	jr Z, LABEL_F95301
	cp XIZ, 0x1e0003a
	jr NZ, LABEL_F95346
	call GetNamingWindowID
	ld XWA, 0x145002f
	ld XBC, XIZ
	ld XDE, XHL
	call MainFuncCall
	ld XHL, (XSP + 0x4)
	jr LABEL_F95348

LABEL_F95301:
	ld XHL, 1
	jr LABEL_F95348

LABEL_F95305:
	ld XHL, 0x8
	jr LABEL_F95348

LABEL_F9530C:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x27450
	call SendEvent
	ld XWA, 0x145002f
	ld XBC, 0x1e00086
	ld XDE, 0x27450
	call MainFuncCall
	ld XWA, 0xffffffff
	ld XBC, 0x1c00015
	ld XDE, 0x1a0006b
	call SendEvent

LABEL_F95346:
	ld XHL, 0

LABEL_F95348:
	pop XIZ
	inc 4, XSP
	ret

SmfFileRename:
	dec 4, XSP
	push XIZ
	ld XIZ, XBC
	ld (XSP + 0x4), XWA
	cp XIZ, 0x1c00007
	jr Z, LABEL_F95395
	cp XIZ, 0x1e0007c
	jr Z, LABEL_F9538E
	cp XIZ, 0x1e00084
	jr Z, LABEL_F9538A
	cp XIZ, 0x1e0003a
	jr NZ, LABEL_F953CC
	call GetNamingWindowID
	ld XWA, 0x1450023
	ld XBC, XIZ
	ld XDE, XHL
	call MainFuncCall
	ld XHL, (XSP + 0x4)
	jr LABEL_F953CE

LABEL_F9538A:
	ld XHL, 1
	jr LABEL_F953CE

LABEL_F9538E:
	ld XHL, 0x8
	jr LABEL_F953CE

LABEL_F95395:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x27462
	call SendEvent
	ld XWA, 0x1450023
	ld XBC, 0x1e00086
	ld XDE, 0x27462
	call MainFuncCall
	ld XWA, 0x7b0019
	ld XBC, 0x1c00001
	ld XDE, 0
	call PostEvent

LABEL_F953CC:
	ld XHL, 0

LABEL_F953CE:
	pop XIZ
	inc 4, XSP
	ret

FormatDiskNaming:
	dec 4, XSP
	push XIZ
	ld XIZ, XBC
	ld (XSP + 0x4), XWA
	cp XIZ, 0x1c00007
	jr Z, LABEL_F9541B
	cp XIZ, 0x1e0007c
	jr Z, LABEL_F95414
	cp XIZ, 0x1e00084
	jr Z, LABEL_F95410
	cp XIZ, 0x1e0003a
	jr NZ, LABEL_F95442
	call GetNamingWindowID
	ld XWA, 0x145000b
	ld XBC, XIZ
	ld XDE, XHL
	call MainFuncCall
	ld XHL, (XSP + 0x4)
	jr LABEL_F95444

LABEL_F95410:
	ld XHL, 1
	jr LABEL_F95444

LABEL_F95414:
	ld XHL, 0xb
	jr LABEL_F95444

LABEL_F9541B:
	call GetNamingWindowID
	ld XWA, XHL
	ld XBC, 0x1e0003a
	ld XDE, 0x27474
	call SendEvent
	ld XWA, 0x145000b
	ld XBC, 0x1e00086
	ld XDE, 0x27474
	call MainFuncCall

LABEL_F95442:
	ld XHL, 0

LABEL_F95444:
	pop XIZ
	inc 4, XSP
	ret

DrawString_Centered:
	lda XSP, XSP - 12
	push IZ
	ld (XSP + 0x4), DE
	ld (XSP + 0x6), XBC
	ld (XSP + 0xa), XWA
	ld XWA, (XSP + 0x6)
	push XWA
	call LABEL_FF0FA0
	inc 4, XSP
	ld (XSP + 0x2), HL
	ld DE, 0
	ld BC, (XSP + 0x12)
	cpw (XSP + 0x4), 0x0
	jr ULE, LABEL_F954A7

LABEL_F9546E:
	ld IY, (XSP + 0x2)
	ld IZ, DE
	add IZ, BC
	ld HL, BC
	extz XHL
	ld XWA, (XSP + 0xa)
	lda XIX, XWA + DE
	lda XWA, XHL + DE
	add XWA, (XSP + 0x6)
	cp IZ, IY
	jr NC, LABEL_F95493
	ld A, (XWA)
	ld (XIX), A
	jr LABEL_F9549E

LABEL_F95493:
	ld HL, (XSP + 0x2)
	exts XHL
	sub XWA, XHL
	ld A, (XWA)
	ld (XIX), A

LABEL_F9549E:
	inc 1, DE
	ld WA, DE
	cp WA, (XSP + 0x4)
	jr C, LABEL_F9546E

LABEL_F954A7:
	ld XWA, (XSP + 0xa)
	ld (XWA + DE), 0x0
	ld HL, 0
	ld DE, (XSP + 0x2)
	inc 1, BC
	cp BC, DE
	jr NC, LABEL_F954BD
	ld HL, BC

LABEL_F954BD:
	pop IZ
	lda XSP, XSP + 0xc
	retd 0x2

WaitingFunc:
	lda XSP, XSP - 0x44
	push XIZ
	ld (XSP + 0x44), XDE
	cp XBC, 0x1c0000b
	jr Z, LABEL_F954EC
	cp XBC, 0x1c00001
	jr NZ, LABEL_F9552D
	ld XWA, (XSP + 0x44)
	ld (0x2748A), WA
	ldw (0x2748C), 0x0
	jr LABEL_F9552D

LABEL_F954EC:
	ld A, (0x340E4)
	extz WA
	sla WA, 0x2
	lda XBC, 0xEA9718
	ld XIZ, (XBC + WA)
	push XIZ
	call LABEL_FF0FA0
	inc 4, XSP
	srl HL, 1
	pushw (0x2748C)
	lda XWA, XSP + 0x6
	ld XBC, XIZ
	ld DE, HL
	CALR DrawString_Centered
	ld (0x2748C), HL
	ld XWA, (XSP + 0x44)
	lda XDE, XSP + 0x4
	ld XBC, 0x1c0000f
	call SendEvent

LABEL_F9552D:
	ld XHL, 0
	pop XIZ
	lda XSP, XSP + 0x44
	ret

DiskMedleyShowHideFunc:
	cp XBC, 0x1c00002
	jr Z, LABEL_F95554
	cp XBC, 0x1c00001
	jr NZ, LABEL_F95554
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call SendEvent

LABEL_F95554:
	ld XHL, 0
	ret

PsFileNameBoxProc:
	lda XSP, XSP - 0xaa
	push XIZ
	ld (XSP + 0xa2), XDE
	ld (XSP + 0xa6), XBC
	ld (XSP + 0xaa), XWA
	ld XWA, (XSP + 0xa6)
	cp XWA, 0x1c50001
	jrl Z, LABEL_F95A80
	cp XWA, 0x1c50000
	jrl Z, LABEL_F95A50
	cp XWA, 0x1c00002
	jrl Z, LABEL_F95A2F
	cp XWA, 0x1c0001a
	jrl Z, LABEL_F959CB
	cp XWA, 0x1c00019
	jrl Z, LABEL_F959CB
	cp XWA, 0x1c00018
	jrl Z, LABEL_F95957
	cp XWA, 0x1c00017
	jrl Z, LABEL_F95957
	cp XWA, 0x1e50002
	jrl Z, LABEL_F95941
	cp XWA, 0x1c0000f
	jrl Z, LABEL_F95777
	cp XWA, 0x1c0000b
	jrl Z, LABEL_F95669
	cp XWA, 0x1c00001
	jrl NZ, LABEL_F95AB0
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld XIZ, XHL
	ld XWA, (XIZ + 0x32)
	ldw (XWA), 0x1
	ld XWA, (XIZ + 0x36)
	ldw (XWA), 0x1
	ld XDE, (XSP + 0xaa)
	ld XWA, (XIZ + 0x22)
	ld XBC, 0x1e50004
	call MainFuncCall
	cpw (XIZ + 0x2e), 0x0
	jr Z, LABEL_F95657
	cpw (XIZ + 0x28), 0x1
	jr NZ, LABEL_F95631
	cpw (XIZ + 0x26), 0x1
	jr NZ, LABEL_F95631
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00017
	ld XDE, 0
	call SetDialUp
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00018
	ld XDE, 0
	jr LABEL_F9564D

LABEL_F95631:
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00018
	ld XDE, 0
	call SetDialUp
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00017
	ld XDE, 0

LABEL_F9564D:
	call SetDialDown
	ld WA, 1
	call SetDialEnable

LABEL_F95657:
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	jrl LABEL_F95ABF

LABEL_F95669:
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	call InheritedProc
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld (XSP + 0xe), XHL
	ld XWA, (XSP + 0xe)
	ld XWA, (XWA + 0x22)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	call MainFuncCall
	ld XWA, (XSP + 0xe)
	cpw (XWA + 0x26), 0x2
	jr LT, LABEL_F95717
	lda XBC, XSP + 0x92
	ld XWA, (XSP + 0xaa)
	call GetClientBox
	lda XDE, XSP + 0x92
	ld BC, (XDE + 0x4)
	sub BC, (XDE)
	exts XBC
	ld XWA, (XSP + 0xe)
	divs XBC, (XWA + 0x26)
	ld (XSP + 0x8), BC
	ld WA, (XDE + 0x2)
	inc 1, WA
	ld (XSP + 0xa0), WA
	ld WA, (XDE + 0x6)
	dec 1, WA
	ld (XSP + 0x9c), WA
	ldw (XSP + 0xc), 0x1
	jr LABEL_F9570C

LABEL_F956E4:
	ld WA, (XSP + 0x8)
	mul XWA, (XSP + 0xc)
	ld BC, (XSP + 0x92)
	add BC, WA
	dec 1, BC
	lda XWA, XSP + 0x9e
	ld (XWA), BC
	lda XBC, XSP + 0x9a
	ld DE, (XWA)
	ld (XBC), DE
	ld DE, 7
	call DrawLine
	INCW 1, (XSP + 0xc)

LABEL_F9570C:
	ld XWA, (XSP + 0xe)
	ld WA, (XWA + 0x26)
	cp (XSP + 0xc), WA
	jr C, LABEL_F956E4

LABEL_F95717:
	ld XWA, (XSP + 0xe)
	cpw (XWA + 0x2e), 0x0
	jrl Z, LABEL_F95A2A
	cpw (XWA + 0x28), 0x1
	jr NZ, LABEL_F9574E
	cpw (XWA + 0x26), 0x1
	jr NZ, LABEL_F9574E
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00017
	ld XDE, 0
	call SetDialUp
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00018
	ld XDE, 0
	jr LABEL_F9576A

LABEL_F9574E:
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00018
	ld XDE, 0
	call SetDialUp
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00017
	ld XDE, 0

LABEL_F9576A:
	call SetDialDown
	ld WA, 1
	call SetDialEnable
	jrl LABEL_F95A2A

LABEL_F95777:
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld (XSP + 0xa), XHL
	ld XWA, (XSP + 0xa)
	ld (XSP + 0x4), XWA
	ld XWA, (XWA + 0x32)
	cpw (XWA), 0x0
	jrl Z, LABEL_F95A2A
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	call InheritedProc
	ld XWA, (XSP + 0xa2)
	or XWA, XWA
	jrl Z, LABEL_F95A2A
	ld XWA, (XSP + 0xa)
	lda XHL, XWA + 0x26
	ld DE, (XWA + 0x28)
	lda XBC, XSP + 0x92
	cp DE, 1
	jrl NZ, LABEL_F95844
	cpw (XHL), 0x1
	jr NZ, LABEL_F95844
	ld XWA, (XSP + 0xaa)
	call GetClientBox
	lda XWA, XSP + 0x92
	lda XBC, XSP + 0x9e
	call GetBoxCenter
	ld XWA, (XSP + 0xa2)
	inc 1, XWA
	push XWA
	lda XWA, XSP + 0x16
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	ld XHL, (XSP + 0xa)
	ld XBC, (XHL + 0x2a)
	lda XDE, XSP + 0x12
	lda XIX, XHL + 0x16
	ld XWA, (XSP + 0x4)
	lda XIY, XWA + 0x20
	lda XHL, XHL + 0x1c
	cpw (XBC), 0x0
	jr NZ, LABEL_F95826
	lda XWA, XSP + 0x92
	lda XBC, XSP + 0x9e
	ld XHL, (XHL)
	push XHL
	pushw (XIY)
	pushw (XIX)
	pushw 0x0
	pushw 0x1
	jr LABEL_F9583D

LABEL_F95826:
	lda XWA, XSP + 0x92
	lda XBC, XSP + 0x9e
	ld XHL, (XHL)
	push XHL
	pushw (XIY)
	pushw (XIX)
	pushw 0x0
	pushw 0x0

LABEL_F9583D:
	call DrawStringReverse
	jrl LABEL_F95A2A

LABEL_F95844:
	ld WA, (XHL)
	muls XWA, DE
	ld DE, WA
	ld XWA, (XSP + 0xa2)
	ld A, (XWA)
	exts WA
	cp WA, DE
	jrl GE, LABEL_F95A2A
	ld XWA, (XSP + 0xaa)
	call GetClientBox
	lda XBC, XSP + 0x92
	lda XWA, XBC + 0x4
	ld (XSP + 0xe), XWA
	ld DE, (XWA)
	sub DE, (XBC)
	exts XDE
	ld XWA, (XSP + 0xa)
	divs XDE, (XWA + 0x26)
	ld (XSP + 0x8), DE
	lda XIY, XBC + 0x6
	lda XIX, XBC + 0x2
	ld HL, (XIX)
	ld IZ, (XIY)
	sub IZ, HL
	ld XWA, (XSP + 0x4)
	ld DE, (XWA + 0x28)
	exts XIZ
	divs XIZ, DE
	ld XWA, (XSP + 0xa2)
	ld A, (XWA)
	exts WA
	exts XWA
	divs XWA, DE
	ld WA, QWA
	ld QDE, WA
	ld XWA, (XSP + 0xa2)
	ld A, (XWA)
	exts WA
	exts XWA
	divs XWA, DE
	ld DE, WA
	ld WA, IZ
	mul XWA, QDE
	inc 2, WA
	add HL, WA
	ld (XIX), HL
	add HL, IZ
	ld (XIY), HL
	ld WA, (XSP + 0x8)
	mul XWA, DE
	inc 2, WA
	add (XBC), WA
	ld DE, (XBC)
	add DE, (XSP + 0x8)
	ld XWA, (XSP + 0xe)
	ld (XWA), DE
	lda XDE, XSP + 0x9e
	ld WA, (XBC)
	ld (XDE), WA
	ld WA, (XIX)
	ld (XDE + 0x2), WA
	ld XWA, (XSP + 0xa2)
	inc 1, XWA
	push XWA
	lda XWA, XSP + 0x16
	push XWA
	call LABEL_FF0F4D
	inc 8, XSP
	ld XWA, (XSP + 0xa)
	ld XIX, (XWA + 0x2a)
	ld XWA, (XSP + 0xa2)
	ld A, (XWA)
	ld IYL, A
	exts IY
	ld XWA, (XSP + 0x4)
	lda XHL, XWA + 0x1c
	lda XBC, XSP + 0x9e
	lda XDE, XSP + 0x12
	cp IY, (XIX)
	jr NZ, LABEL_F95929
	lda XWA, XSP + 0x92
	ld XHL, (XHL)
	push XHL
	pushw 0x0
	pushw 0xff
	jr LABEL_F9593A

LABEL_F95929:
	lda XWA, XSP + 0x92
	ld XHL, (XHL)
	push XHL
	ld XHL, (XSP + 0xe)
	pushw (XHL + 0x20)
	pushw (XHL + 0x16)

LABEL_F9593A:
	call DrawString
	jrl LABEL_F95A2A

LABEL_F95941:
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld XBC, (XHL + 0x2a)
	ld XWA, (XSP + 0xa2)
	ld (XBC), WA
	jrl LABEL_F95A2A

LABEL_F95957:
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld XIZ, XHL
	ld XWA, (XIZ + 0x22)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	call MainFuncCall
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	call InheritedProc
	cpw (XIZ + 0x30), 0x0
	jrl Z, LABEL_F95A2A
	ld XWA, (XSP + 0xa2)
	or XWA, XWA
	jrl NZ, LABEL_F95A2A
	ld XWA, (XSP + 0xa6)
	cp XWA, 0x1c00017
	jr NZ, LABEL_F959B6
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c00019
	ld XDE, (XSP + 0xa2)
	jr LABEL_F959C5

LABEL_F959B6:
	ld XWA, (XSP + 0xaa)
	ld XBC, 0x1c0001a
	ld XDE, (XSP + 0xa2)

LABEL_F959C5:
	call SetAutoInc
	jr LABEL_F95A2A

LABEL_F959CB:
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	call InheritedProc
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	cpw (XHL + 0x30), 0x0
	jr Z, LABEL_F95A2A
	ld XWA, (XSP + 0xa2)
	or XWA, XWA
	jr NZ, LABEL_F95A2A
	ld XWA, (XHL + 0x36)
	cpw (XWA), 0x0
	jr Z, LABEL_F95A2A
	ld XBC, (XSP + 0xa6)
	ld XWA, (XHL + 0x22)
	cp XBC, 0x1c00019
	jr NZ, LABEL_F95A1C
	ld XBC, 0x1c00017
	ld XDE, (XSP + 0xa2)
	jr LABEL_F95A26

LABEL_F95A1C:
	ld XBC, 0x1c00018
	ld XDE, (XSP + 0xa2)

LABEL_F95A26:
	call MainFuncCall

LABEL_F95A2A:
	ld XHL, 0
	jrl LABEL_F95AC3

LABEL_F95A2F:
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld XWA, (XHL + 0x32)
	ldw (XWA), 0x0
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	jr LABEL_F95ABF

LABEL_F95A50:
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld XBC, (XHL + 0x32)
	ld XWA, (XSP + 0xa2)
	or XWA, XWA
	jr Z, LABEL_F95A6B
	ldw (XBC), 0x0
	jr LABEL_F95A6F

LABEL_F95A6B:
	ldw (XBC), 0x1

LABEL_F95A6F:
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	jr LABEL_F95ABF

LABEL_F95A80:
	ld XWA, (XSP + 0xaa)
	call GetViewInstance
	ld XBC, (XHL + 0x36)
	ld XWA, (XSP + 0xa2)
	or XWA, XWA
	jr Z, LABEL_F95A9B
	ldw (XBC), 0x0
	jr LABEL_F95A9F

LABEL_F95A9B:
	ldw (XBC), 0x1

LABEL_F95A9F:
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)
	jr LABEL_F95ABF

LABEL_F95AB0:
	ld XWA, (XSP + 0xaa)
	ld XBC, (XSP + 0xa6)
	ld XDE, (XSP + 0xa2)

LABEL_F95ABF:
	call InheritedProc

LABEL_F95AC3:
	pop XIZ
	lda XSP, XSP + 0xaa
	ret

