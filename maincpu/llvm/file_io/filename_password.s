; =============================================================================
; file_io/filename_password.asm - Filename and Password UI
; =============================================================================
; Password entry and filename input routines.
;
; Key routines:
;   FmmPasswordFunc                  - Password entry dialog
;   FmmFileNameFunc                  - Filename input/display
; =============================================================================

FmmPasswordFunc:
	dec 4, XSP
	push XIZ
	ld XIZ, XDE
	ld (XSP + 0x4), XWA
	ld WA, IZ
	cp XBC, 0x1e50010
	jrl Z, LABEL_F8CA7F
	lda XDE, 0x8A0C
	cp XBC, 0x1e5000f
	jrl Z, LABEL_F8C9FC
	cp XBC, 0x1e5000e
	jr Z, LABEL_F8C980
	cp XBC, 0x1e5000d
	jrl NZ, LABEL_F8CAA6
	call LABEL_F94242
	cp L, 0
	jr NZ, LABEL_F8C95A
	call LABEL_F94262
	cp L, 0
	jr Z, LABEL_F8C969

LABEL_F8C95A:
	ld (0x7F42), 0xa
	ld WA, 0xee
	call LABEL_F994BD
	jrl LABEL_F8CAA6

LABEL_F8C969:
	ld WA, IZ
	call LABEL_F9420F
	ld WA, IZ
	call LABEL_F9424A
	lda XWA, 0x8A0D
	set 7, (XWA)
	set 6, (XWA)
	jrl LABEL_F8CAA6

LABEL_F8C980:
	cp (XDE), 0x3
	jr NZ, LABEL_F8C9AB
	call LABEL_F94236
	cp L, 0
	jr Z, LABEL_F8C9AB
	ld WA, IZ
	call LABEL_F94256
	cp L, 0
	jr Z, LABEL_F8C9AB
	lda XWA, 0x8A0D
	set 7, (XWA)
	set 6, (XWA)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 4
	jr LABEL_F8C9EB

LABEL_F8C9AB:
	cp (0x8A0C), 0x1
	jr NZ, LABEL_F8C9CC
	ld WA, IZ
	call LABEL_F94236
	cp L, 0
	jr Z, LABEL_F8C9CC
	set 7, (0x8A0D)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 4
	jr LABEL_F8C9EB

LABEL_F8C9CC:
	cp (0x8A0C), 0x2
	jr NZ, LABEL_F8C9F1
	ld WA, IZ
	call LABEL_F94256
	cp L, 0
	jr Z, LABEL_F8C9F1
	set 6, (0x8A0D)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 4

LABEL_F8C9EB:
	CALR FmmFileNameFunc
	jrl LABEL_F8CAA6

LABEL_F8C9F1:
	ld (0x7F42), 0xb
	ld WA, 0xee
	jrl LABEL_F8CAA2

LABEL_F8C9FC:
	cp (XDE), 0x3
	jr NZ, LABEL_F8CA2A
	call LABEL_F94236
	cp L, 0
	jr Z, LABEL_F8CA2A
	ld WA, IZ
	call LABEL_F94256
	cp L, 0
	jr Z, LABEL_F8CA2A
	lda XWA, 0x8A0D
	set 7, (XWA)
	set 6, (XWA)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 0xa
	jr LABEL_F8CA70

LABEL_F8CA2A:
	cp (0x8A0C), 0x1
	jr NZ, LABEL_F8CA4E
	ld WA, IZ
	call LABEL_F94236
	cp L, 0
	jr Z, LABEL_F8CA4E
	set 7, (0x8A0D)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 0xa
	jr LABEL_F8CA70

LABEL_F8CA4E:
	cp (0x8A0C), 0x2
	jr NZ, LABEL_F8CA75
	ld WA, IZ
	call LABEL_F94256
	cp L, 0
	jr Z, LABEL_F8CA75
	set 6, (0x8A0D)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 0xa

LABEL_F8CA70:
	CALR FmmSaveFilterFunc
	jr LABEL_F8CAA6

LABEL_F8CA75:
	ld (0x7F42), 0xb
	ld WA, 0xee
	jr LABEL_F8CAA2

LABEL_F8CA7F:
	call LABEL_F94236
	cp L, 0
	jr Z, LABEL_F8CA9A
	set 7, (0x8A0D)
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c00017
	ld XDE, 4
	CALR FmmSeqSongNameFunc
	jr LABEL_F8CAA6

LABEL_F8CA9A:
	ld (0x7F42), 0xb
	ld WA, 0xee

LABEL_F8CAA2:
	call LABEL_F994BD

LABEL_F8CAA6:
	ld XHL, 0
	pop XIZ
	inc 4, XSP
	ret

SelectPasswordMode:
	push XIZ
	ld QIZH, 0
	ld QIZL, 0
	ld WA, 2
	call LABEL_F89353
	cp L, 0
	jr Z, LABEL_F8CACE
	call LABEL_F94242
	cp L, 0
	jr Z, LABEL_F8CACE
	bit 7, (0x8A0D)
	jr NZ, LABEL_F8CACE
	ld QIZL, 1

LABEL_F8CACE:
	ld WA, 3
	call LABEL_F89353
	cp L, 0
	jr Z, LABEL_F8CAE9
	call LABEL_F94262
	cp L, 0
	jr Z, LABEL_F8CAE9
	bit 6, (0x8A0D)
	jr NZ, LABEL_F8CAE9
	ld QIZH, 1

LABEL_F8CAE9:
	cp QIZL, 0
	jr Z, LABEL_F8CB0B
	cp QIZH, 0
	jr Z, LABEL_F8CB0B
	call LABEL_F94250
	ld IZ, HL
	call LABEL_F941F9
	LD_A 0x1
	cp HL, IZ
	jr NZ, LABEL_F8CB05
	LD_A 0x3

LABEL_F8CB05:
	ld (0x8A0C), A
	jr LABEL_F8CB24

LABEL_F8CB0B:
	lda XBC, 0x8A0C
	cp QIZL, 0
	jr Z, LABEL_F8CB19
	ld (XBC), 0x1
	jr LABEL_F8CB24

LABEL_F8CB19:
	LD_A 0x0
	cp QIZH, 0
	jr Z, LABEL_F8CB22
	LD_A 0x2

LABEL_F8CB22:
	ld (XBC), A

LABEL_F8CB24:
	ld L, (0x8A0C)
	extz HL
	pop XIZ
	ret

FmmFileNameFunc:
	dec 8, XSP
	push XIZ
	ld XIZ, XDE
	ld (XSP + 0x8), XBC
	ld XBC, XIZ
	ld XWA, (XSP + 0x8)
	cp XWA, 0x1e50000
	jrl Z, LABEL_F8D106
	cp XWA, 0x1c00018
	jrl Z, LABEL_F8CC0C
	cp XWA, 0x1c00017
	jrl Z, LABEL_F8CC0C
	cp XWA, 0x1c0000b
	jr Z, LABEL_F8CBA2
	cp XWA, 0x1e50004
	jrl NZ, LABEL_F8D16D
	ld (0x7F72), XBC
	call GetCurrentFileIndex
	ld (0x7F7A), HL
	cp HL, 0
	jr LT, LABEL_F8CB84
	exts XHL
	ld XWA, (0x7F72)
	ld XBC, 0x1e50002
	ld XDE, XHL
	jr LABEL_F8CB95

LABEL_F8CB84:
	ldw (0x7F7A), 0x0
	ld XWA, (0x7F72)
	ld XBC, 0x1e50002
	ld XDE, 0

LABEL_F8CB95:
	call ApPostEvent
	ld XWA, 0
	ld (0x7F76), XWA
	jrl LABEL_F8D16D

LABEL_F8CBA2:
	ldw (XSP + 0x6), 0x0

LABEL_F8CBA7:
	ld WA, (XSP + 0x6)
	ld HL, WA
	sll HL, 5
	lda XDE, 0x850C
	extz XHL
	add XHL, XDE
	ld BC, (XSP + 0x6)
	ld (XHL), C
	call LABEL_F89623
	ld XBC, XHL
	ld DE, (XSP + 0x6)
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
	ld DE, (XSP + 0x6)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x7F72)
	ld XBC, 0x1c0000f
	call ApPostEvent
	INCW 1, (XSP + 0x6)
	cpw (XSP + 0x6), 0x14
	jr LT, LABEL_F8CBA7
	jrl LABEL_F8D16D

LABEL_F8CC0C:
	ldw (XSP + 0x6), (0x7F7A)
	ld WA, (XSP + 0x6)
	ld (XSP + 0x4), WA
	or XIZ, XIZ
	jr NZ, LABEL_F8CC49
	ld XWA, (XSP + 0x8)
	cp XWA, 0x1c00018
	jr NZ, LABEL_F8CC33
	cpw (XSP + 0x6), 0x13
	jrl GE, LABEL_F8CFF8
	INCW 1, (XSP + 0x6)
	jr LABEL_F8CC7B

LABEL_F8CC33:
	cp XWA, 0x1c00017
	jrl NZ, LABEL_F8CFF8
	cpw (XSP + 0x6), 0x0
	jrl LE, LABEL_F8CFF8
	DECW 1, (XSP + 0x6)
	jr LABEL_F8CC7B

LABEL_F8CC49:
	cp XIZ, 0x1
	jr NZ, LABEL_F8CC60
	cpw (XSP + 0x6), 0xa
	jrl LT, LABEL_F8CFF8
	subw (XSP + 0x6), 0xa
	jr LABEL_F8CC7B

LABEL_F8CC60:
	cp XIZ, 0x2
	jr NZ, LABEL_F8CC86
	ld WA, (XSP + 0x6)
	add WA, 0xa
	cp WA, 0x13
	jrl GT, LABEL_F8CFF8
	addw (XSP + 0x6), 0xa

LABEL_F8CC7B:
	ldw (0x7F7A), (XSP + 0x6)
	ld WA, (XSP + 0x6)
	jrl LABEL_F8CFFC

LABEL_F8CC86:
	cp XIZ, 0x3
	jrl NZ, LABEL_F8CD39
	call CheckFileSystemStatus
	cp HL, 0
	jrl Z, LABEL_F8CD39
	call LABEL_F892EF
	cp HL, 0
	jrl Z, LABEL_F8CD39
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, (0x7F7A)
	extz WA
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
	jr Z, LABEL_F8CD1D
	ld WA, 2
	call LABEL_F892F5
	cp L, 0
	jr Z, LABEL_F8CD1D
	ld WA, 2
	call LABEL_F893D1
	cp L, 0
	jr NZ, LABEL_F8CD18
	ld WA, 0x8
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8CD1D

LABEL_F8CD18:
	ld WA, 0xa
	jr LABEL_F8CD1F

LABEL_F8CD1D:
	ld WA, 1

LABEL_F8CD1F:
	call LABEL_F99463
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jrl LABEL_F8CFF4

LABEL_F8CD39:
	cp XIZ, 0x4
	jrl NZ, LABEL_F8CE07
	call LABEL_F8934D
	cp HL, 0
	jrl Z, LABEL_F8CE07
	CALR SelectPasswordMode
	cp HL, 0
	jr Z, LABEL_F8CD65
	ld XDE, 0
	ld E, (0x8A0C)
	ld XWA, 0xffffffff
	ld XBC, 0x1c50004
	jrl LABEL_F8CEB7

LABEL_F8CD65:
	call CheckFileSystemStatus
	cp HL, 0
	jr Z, LABEL_F8CD94
	cp (0x340EA), 0x0
	jr Z, LABEL_F8CD94
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x600037
	ld XBC, 0x1c00001
	ld XDE, 0
	jrl LABEL_F8CEB7

LABEL_F8CD94:
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
	jrl LABEL_F8CFF4

LABEL_F8CE07:
	cp XIZ, 0x32
	jr NZ, LABEL_F8CE82
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
	jrl LABEL_F8CFF4

LABEL_F8CE82:
	cp XIZ, 0x5
	jrl NZ, LABEL_F8CF0B
	call CheckFileSystemStatus
	cp HL, 0
	jr Z, LABEL_F8CF0B
	cp (0x340EA), 0x0
	jr Z, LABEL_F8CEBE
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x7b0051
	ld XBC, 0x1c00001
	ld XDE, 0

LABEL_F8CEB7:
	call ApPostEvent
	jrl LABEL_F8CFF8

LABEL_F8CEBE:
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F8872D
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jrl LABEL_F8CFF4

LABEL_F8CF0B:
	cp XIZ, 0x33
	jr NZ, LABEL_F8CF60
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F8872D
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	call LABEL_F89568
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jrl LABEL_F8CFF4

LABEL_F8CF60:
	cp XIZ, 0x6
	jrl NZ, LABEL_F8CFF8
	call CheckFileSystemStatus
	cp HL, 0
	jrl Z, LABEL_F8CFF8
	ld XBC, (XSP + 0x8)
	ld WA, (0x7F7A)
	cp XBC, 0x1c00018
	jr NZ, LABEL_F8CF91
	ld BC, WA
	cp WA, 0x13
	jr GE, LABEL_F8CFA5
	inc 1, BC
	ld (0x7F7A), BC
	jr LABEL_F8CFA5

LABEL_F8CF91:
	cp XBC, 0x1c00017
	jr NZ, LABEL_F8CFA5
	ld BC, WA
	cp WA, 0
	jr LE, LABEL_F8CFA5
	dec 1, BC
	ld (0x7F7A), BC

LABEL_F8CFA5:
	ld WA, (XSP + 0x6)
	cp WA, (0x7F7A)
	jr Z, LABEL_F8CFF8
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld WA, (0x7F7A)
	call LABEL_F88838
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	call GetEncodedFileSizeData
	ld (0x8502), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee

LABEL_F8CFF4:
	call LABEL_F994BD

LABEL_F8CFF8:
	ld WA, (0x7F7A)

LABEL_F8CFFC:
	cp (XSP + 0x4), WA
	jrl Z, LABEL_F8D16D
	call NotifyUIOfSelectionChange
	ld (0x89F8), 0x4
	ld DE, (0x7F7A)
	exts XDE
	ld XWA, (0x7F72)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld DE, (XSP + 0x4)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x7F72)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld DE, (0x7F7A)
	sll DE, 5
	lda XBC, 0x850C
	extz XDE
	add XDE, XBC
	ld XWA, (0x7F72)
	ld XBC, 0x1c0000f
	call ApPostEvent
	ldw (XSP + 0x6), 0x0

LABEL_F8D05A:
	ld WA, (XSP + 0x6)
	extz WA
	call LABEL_F893D1
	ld WA, (XSP + 0x6)
	extz WA
	cp L, 0
	jr Z, LABEL_F8D072
	call LABEL_F89321
	jr LABEL_F8D076

LABEL_F8D072:
	call LABEL_F89335

LABEL_F8D076:
	INCW 1, (XSP + 0x6)
	cpw (XSP + 0x6), 0x8
	jr LT, LABEL_F8D05A
	ld WA, 0x8
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D09C
	ld WA, 0x9
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D09C
	ld WA, 2
	call LABEL_F89321

LABEL_F8D09C:
	ld XWA, (0x7F76)
	or XWA, XWA
	jrl Z, LABEL_F8D16D
	cp (0x8D36), 0x67
	jr Z, LABEL_F8D0F3
	call CheckFileSystemStatus
	ld IZ, HL
	ld WA, 0x8
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D0CB
	ld WA, 0x9
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D0CB
	set 0x2, IZ

LABEL_F8D0CB:
	call LABEL_F892EF
	and IZ, HL
	bit 0x0, IZ
	jr Z, LABEL_F8D0E4
	call LABEL_F8964C
	cp L, 0
	jr Z, LABEL_F8D0E4
	res 0x0, IZ
	set 0x1, IZ

LABEL_F8D0E4:
	ld DE, IZ
	extz XDE
	ld XWA, (0x7F76)
	ld XBC, 0x1e50001
	jr LABEL_F8D169

LABEL_F8D0F3:
	call LABEL_F8934D
	extz XHL
	ld XWA, (0x7F76)
	ld XBC, 0x1e50001
	ld XDE, XHL
	jr LABEL_F8D169

LABEL_F8D106:
	ld (0x7F76), XBC
	cp (0x8D36), 0x67
	jr Z, LABEL_F8D158
	call CheckFileSystemStatus
	ld IZ, HL
	ld WA, 0x8
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D130
	ld WA, 0x9
	call LABEL_F893D1
	cp L, 0
	jr Z, LABEL_F8D130
	set 0x2, IZ

LABEL_F8D130:
	call LABEL_F892EF
	and IZ, HL
	bit 0x0, IZ
	jr Z, LABEL_F8D149
	call LABEL_F8964C
	cp L, 0
	jr Z, LABEL_F8D149
	res 0x0, IZ
	set 0x1, IZ

LABEL_F8D149:
	ld DE, IZ
	extz XDE
	ld XWA, (0x7F76)
	ld XBC, 0x1e50001
	jr LABEL_F8D169

LABEL_F8D158:
	call LABEL_F8934D
	extz XHL
	ld XWA, (0x7F76)
	ld XBC, 0x1e50001
	ld XDE, XHL

LABEL_F8D169:
	call ApPostEvent

LABEL_F8D16D:
	ld XHL, 0
	pop XIZ
	inc 8, XSP
	ret

