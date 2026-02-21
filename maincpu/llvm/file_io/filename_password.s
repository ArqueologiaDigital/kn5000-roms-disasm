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
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XDE
	; (no addr) LD (XSP + 004h), XWA
	; (no addr) LD WA, IZ
	; (no addr) CP XBC, 01e50010h
	; (no addr) JRL Z, LABEL_F8CA7F
	; (no addr) LDA XDE, 8A0Ch
	; (no addr) CP XBC, 01e5000fh
	; (no addr) JRL Z, LABEL_F8C9FC
	; (no addr) CP XBC, 01e5000eh
	; (no addr) JR Z, LABEL_F8C980
	; (no addr) CP XBC, 01e5000dh
	; (no addr) JRL NZ, LABEL_F8CAA6
	; (no addr) CALL LABEL_F94242
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8C95A
	; (no addr) CALL LABEL_F94262
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8C969

LABEL_F8C95A:
	; (no addr) LD (7F42h), 00ah
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, LABEL_F8CAA6

LABEL_F8C969:
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F9420F
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F9424A
	; (no addr) LDA XWA, 8A0Dh
	; (no addr) SET 7, (XWA)
	; (no addr) SET 6, (XWA)
	; (no addr) JRL T, LABEL_F8CAA6

LABEL_F8C980:
	; (no addr) CP (XDE), 003h
	; (no addr) JR NZ, LABEL_F8C9AB
	; (no addr) CALL LABEL_F94236
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8C9AB
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F94256
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8C9AB
	; (no addr) LDA XWA, 8A0Dh
	; (no addr) SET 7, (XWA)
	; (no addr) SET 6, (XWA)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 4
	; (no addr) JR T, LABEL_F8C9EB

LABEL_F8C9AB:
	; (no addr) CP (8A0Ch), 001h
	; (no addr) JR NZ, LABEL_F8C9CC
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F94236
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8C9CC
	; (no addr) SET 7, (8A0Dh)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 4
	; (no addr) JR T, LABEL_F8C9EB

LABEL_F8C9CC:
	; (no addr) CP (8A0Ch), 002h
	; (no addr) JR NZ, LABEL_F8C9F1
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F94256
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8C9F1
	; (no addr) SET 6, (8A0Dh)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 4

LABEL_F8C9EB:
	CALR FmmFileNameFunc
	; (no addr) JRL T, LABEL_F8CAA6

LABEL_F8C9F1:
	; (no addr) LD (7F42h), 00bh
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8CAA2

LABEL_F8C9FC:
	; (no addr) CP (XDE), 003h
	; (no addr) JR NZ, LABEL_F8CA2A
	; (no addr) CALL LABEL_F94236
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CA2A
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F94256
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CA2A
	; (no addr) LDA XWA, 8A0Dh
	; (no addr) SET 7, (XWA)
	; (no addr) SET 6, (XWA)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 0000000ah
	; (no addr) JR T, LABEL_F8CA70

LABEL_F8CA2A:
	; (no addr) CP (8A0Ch), 001h
	; (no addr) JR NZ, LABEL_F8CA4E
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F94236
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CA4E
	; (no addr) SET 7, (8A0Dh)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 0000000ah
	; (no addr) JR T, LABEL_F8CA70

LABEL_F8CA4E:
	; (no addr) CP (8A0Ch), 002h
	; (no addr) JR NZ, LABEL_F8CA75
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F94256
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CA75
	; (no addr) SET 6, (8A0Dh)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 0000000ah

LABEL_F8CA70:
	CALR FmmSaveFilterFunc
	; (no addr) JR T, LABEL_F8CAA6

LABEL_F8CA75:
	; (no addr) LD (7F42h), 00bh
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8CAA2

LABEL_F8CA7F:
	; (no addr) CALL LABEL_F94236
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CA9A
	; (no addr) SET 7, (8A0Dh)
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c00017h
	; (no addr) LD XDE, 4
	CALR FmmSeqSongNameFunc
	; (no addr) JR T, LABEL_F8CAA6

LABEL_F8CA9A:
	; (no addr) LD (7F42h), 00bh
	; (no addr) LD WA, 00eeh

LABEL_F8CAA2:
	; (no addr) CALL LABEL_F994BD

LABEL_F8CAA6:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

SelectPasswordMode:
	; (no addr) PUSH XIZ
	; (no addr) LD QIZH, 0
	; (no addr) LD QIZL, 0
	; (no addr) LD WA, 2
	; (no addr) CALL LABEL_F89353
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CACE
	; (no addr) CALL LABEL_F94242
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CACE
	; (no addr) BIT 7, (8A0Dh)
	; (no addr) JR NZ, LABEL_F8CACE
	; (no addr) LD QIZL, 1

LABEL_F8CACE:
	; (no addr) LD WA, 3
	; (no addr) CALL LABEL_F89353
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CAE9
	; (no addr) CALL LABEL_F94262
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CAE9
	; (no addr) BIT 6, (8A0Dh)
	; (no addr) JR NZ, LABEL_F8CAE9
	; (no addr) LD QIZH, 1

LABEL_F8CAE9:
	; (no addr) CP QIZL, 0
	; (no addr) JR Z, LABEL_F8CB0B
	; (no addr) CP QIZH, 0
	; (no addr) JR Z, LABEL_F8CB0B
	; (no addr) CALL LABEL_F94250
	; (no addr) LD IZ, HL
	; (no addr) CALL LABEL_F941F9
	LD_A 0x1
	; (no addr) CP HL, IZ
	; (no addr) JR NZ, LABEL_F8CB05
	LD_A 0x3

LABEL_F8CB05:
	; (no addr) LD (8A0Ch), A
	; (no addr) JR T, LABEL_F8CB24

LABEL_F8CB0B:
	; (no addr) LDA XBC, 8A0Ch
	; (no addr) CP QIZL, 0
	; (no addr) JR Z, LABEL_F8CB19
	; (no addr) LD (XBC), 001h
	; (no addr) JR T, LABEL_F8CB24

LABEL_F8CB19:
	LD_A 0x0
	; (no addr) CP QIZH, 0
	; (no addr) JR Z, LABEL_F8CB22
	LD_A 0x2

LABEL_F8CB22:
	; (no addr) LD (XBC), A

LABEL_F8CB24:
	; (no addr) LD L, (8A0Ch)
	; (no addr) EXTZ HL
	; (no addr) POP XIZ
	; (no addr) RET

FmmFileNameFunc:
	; (no addr) DEC 8, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XDE
	; (no addr) LD (XSP + 008h), XBC
	; (no addr) LD XBC, XIZ
	; (no addr) LD XWA, (XSP + 008h)
	; (no addr) CP XWA, 01e50000h
	; (no addr) JRL Z, LABEL_F8D106
	; (no addr) CP XWA, 01c00018h
	; (no addr) JRL Z, LABEL_F8CC0C
	; (no addr) CP XWA, 01c00017h
	; (no addr) JRL Z, LABEL_F8CC0C
	; (no addr) CP XWA, 01c0000bh
	; (no addr) JR Z, LABEL_F8CBA2
	; (no addr) CP XWA, 01e50004h
	; (no addr) JRL NZ, LABEL_F8D16D
	; (no addr) LD (7F72h), XBC
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD (7F7Ah), HL
	; (no addr) CP HL, 0
	; (no addr) JR LT, LABEL_F8CB84
	; (no addr) EXTS XHL
	; (no addr) LD XWA, (7F72h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, XHL
	; (no addr) JR T, LABEL_F8CB95

LABEL_F8CB84:
	; (no addr) LDW (7F7Ah), 0000h
	; (no addr) LD XWA, (7F72h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) LD XDE, 0

LABEL_F8CB95:
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0
	; (no addr) LD (7F76h), XWA
	; (no addr) JRL T, LABEL_F8D16D

LABEL_F8CBA2:
	; (no addr) LDW (XSP + 006h:8), 0000h

LABEL_F8CBA7:
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) LD HL, WA
	; (no addr) SLL 5, HL
	; (no addr) LDA XDE, 850Ch
	; (no addr) EXTZ XHL
	; (no addr) ADD XHL, XDE
	; (no addr) LD BC, (XSP + 006h)
	; (no addr) LD (XHL), C
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) LD DE, (XSP + 006h)
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
	; (no addr) LD DE, (XSP + 006h)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (7F72h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) INCW 1, (XSP + 006h)
	; (no addr) CPW (XSP + 006h), 0014h
	; (no addr) JR LT, LABEL_F8CBA7
	; (no addr) JRL T, LABEL_F8D16D

LABEL_F8CC0C:
	; (no addr) LDW (XSP + 006h), (7F7Ah)
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) LD (XSP + 004h), WA
	; (no addr) OR XIZ, XIZ
	; (no addr) JR NZ, LABEL_F8CC49
	; (no addr) LD XWA, (XSP + 008h)
	; (no addr) CP XWA, 01c00018h
	; (no addr) JR NZ, LABEL_F8CC33
	; (no addr) CPW (XSP + 006h), 0013h
	; (no addr) JRL GE, LABEL_F8CFF8
	; (no addr) INCW 1, (XSP + 006h)
	; (no addr) JR T, LABEL_F8CC7B

LABEL_F8CC33:
	; (no addr) CP XWA, 01c00017h
	; (no addr) JRL NZ, LABEL_F8CFF8
	; (no addr) CPW (XSP + 006h), 0000h
	; (no addr) JRL LE, LABEL_F8CFF8
	; (no addr) DECW 1, (XSP + 006h)
	; (no addr) JR T, LABEL_F8CC7B

LABEL_F8CC49:
	; (no addr) CP XIZ, 00000001h
	; (no addr) JR NZ, LABEL_F8CC60
	; (no addr) CPW (XSP + 006h), 000ah
	; (no addr) JRL LT, LABEL_F8CFF8
	; (no addr) SUBW (XSP + 006h), 000ah
	; (no addr) JR T, LABEL_F8CC7B

LABEL_F8CC60:
	; (no addr) CP XIZ, 00000002h
	; (no addr) JR NZ, LABEL_F8CC86
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) ADD WA, 000ah
	; (no addr) CP WA, 0013h
	; (no addr) JRL GT, LABEL_F8CFF8
	; (no addr) ADDW (XSP + 006h), 000ah

LABEL_F8CC7B:
	; (no addr) LDW (7F7Ah), (XSP + 006h)
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) JRL T, LABEL_F8CFFC

LABEL_F8CC86:
	; (no addr) CP XIZ, 00000003h
	; (no addr) JRL NZ, LABEL_F8CD39
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8CD39
	; (no addr) CALL LABEL_F892EF
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8CD39
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, (7F7Ah)
	; (no addr) EXTZ WA
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
	; (no addr) JR Z, LABEL_F8CD1D
	; (no addr) LD WA, 2
	; (no addr) CALL LABEL_F892F5
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CD1D
	; (no addr) LD WA, 2
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR NZ, LABEL_F8CD18
	; (no addr) LD WA, 0008h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8CD1D

LABEL_F8CD18:
	; (no addr) LD WA, 000ah
	; (no addr) JR T, LABEL_F8CD1F

LABEL_F8CD1D:
	; (no addr) LD WA, 1

LABEL_F8CD1F:
	; (no addr) CALL LABEL_F99463
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8CFF4

LABEL_F8CD39:
	; (no addr) CP XIZ, 00000004h
	; (no addr) JRL NZ, LABEL_F8CE07
	; (no addr) CALL LABEL_F8934D
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8CE07
	CALR SelectPasswordMode
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8CD65
	; (no addr) LD XDE, 0
	; (no addr) LD E, (8A0Ch)
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50004h
	; (no addr) JRL T, LABEL_F8CEB7

LABEL_F8CD65:
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8CD94
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, LABEL_F8CD94
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) JRL T, LABEL_F8CEB7

LABEL_F8CD94:
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
	; (no addr) JRL T, LABEL_F8CFF4

LABEL_F8CE07:
	; (no addr) CP XIZ, 00000032h
	; (no addr) JR NZ, LABEL_F8CE82
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
	; (no addr) JRL T, LABEL_F8CFF4

LABEL_F8CE82:
	; (no addr) CP XIZ, 00000005h
	; (no addr) JRL NZ, LABEL_F8CF0B
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8CF0B
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, LABEL_F8CEBE
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 007b0051h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0

LABEL_F8CEB7:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, LABEL_F8CFF8

LABEL_F8CEBE:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F8872D
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8CFF4

LABEL_F8CF0B:
	; (no addr) CP XIZ, 00000033h
	; (no addr) JR NZ, LABEL_F8CF60
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F8872D
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) CALL LABEL_F89568
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JRL T, LABEL_F8CFF4

LABEL_F8CF60:
	; (no addr) CP XIZ, 00000006h
	; (no addr) JRL NZ, LABEL_F8CFF8
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8CFF8
	; (no addr) LD XBC, (XSP + 008h)
	; (no addr) LD WA, (7F7Ah)
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, LABEL_F8CF91
	; (no addr) LD BC, WA
	; (no addr) CP WA, 0013h
	; (no addr) JR GE, LABEL_F8CFA5
	; (no addr) INC 1, BC
	; (no addr) LD (7F7Ah), BC
	; (no addr) JR T, LABEL_F8CFA5

LABEL_F8CF91:
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, LABEL_F8CFA5
	; (no addr) LD BC, WA
	; (no addr) CP WA, 0
	; (no addr) JR LE, LABEL_F8CFA5
	; (no addr) DEC 1, BC
	; (no addr) LD (7F7Ah), BC

LABEL_F8CFA5:
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) CP WA, (7F7Ah)
	; (no addr) JR Z, LABEL_F8CFF8
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD WA, (7F7Ah)
	; (no addr) CALL LABEL_F88838
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh

LABEL_F8CFF4:
	; (no addr) CALL LABEL_F994BD

LABEL_F8CFF8:
	; (no addr) LD WA, (7F7Ah)

LABEL_F8CFFC:
	; (no addr) CP (XSP + 004h), WA
	; (no addr) JRL Z, LABEL_F8D16D
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) LD (89F8h), 004h
	; (no addr) LD DE, (7F7Ah)
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (7F72h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD DE, (XSP + 004h)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (7F72h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LD DE, (7F7Ah)
	; (no addr) SLL 5, DE
	; (no addr) LDA XBC, 850Ch
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (7F72h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) LDW (XSP + 006h:8), 0000h

LABEL_F8D05A:
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F893D1
	; (no addr) LD WA, (XSP + 006h)
	; (no addr) EXTZ WA
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D072
	; (no addr) CALL LABEL_F89321
	; (no addr) JR T, LABEL_F8D076

LABEL_F8D072:
	; (no addr) CALL LABEL_F89335

LABEL_F8D076:
	; (no addr) INCW 1, (XSP + 006h)
	; (no addr) CPW (XSP + 006h), 0008h
	; (no addr) JR LT, LABEL_F8D05A
	; (no addr) LD WA, 0008h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D09C
	; (no addr) LD WA, 0009h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D09C
	; (no addr) LD WA, 2
	; (no addr) CALL LABEL_F89321

LABEL_F8D09C:
	; (no addr) LD XWA, (7F76h)
	; (no addr) OR XWA, XWA
	; (no addr) JRL Z, LABEL_F8D16D
	; (no addr) CP (8D36h), 067h
	; (no addr) JR Z, LABEL_F8D0F3
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) LD IZ, HL
	; (no addr) LD WA, 0008h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D0CB
	; (no addr) LD WA, 0009h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D0CB
	; (no addr) SET 002h, IZ

LABEL_F8D0CB:
	; (no addr) CALL LABEL_F892EF
	; (no addr) AND IZ, HL
	; (no addr) BIT 000h, IZ
	; (no addr) JR Z, LABEL_F8D0E4
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D0E4
	; (no addr) RES 000h, IZ
	; (no addr) SET 001h, IZ

LABEL_F8D0E4:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (7F76h)
	; (no addr) LD XBC, 01e50001h
	; (no addr) JR T, LABEL_F8D169

LABEL_F8D0F3:
	; (no addr) CALL LABEL_F8934D
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, (7F76h)
	; (no addr) LD XBC, 01e50001h
	; (no addr) LD XDE, XHL
	; (no addr) JR T, LABEL_F8D169

LABEL_F8D106:
	; (no addr) LD (7F76h), XBC
	; (no addr) CP (8D36h), 067h
	; (no addr) JR Z, LABEL_F8D158
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) LD IZ, HL
	; (no addr) LD WA, 0008h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D130
	; (no addr) LD WA, 0009h
	; (no addr) CALL LABEL_F893D1
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D130
	; (no addr) SET 002h, IZ

LABEL_F8D130:
	; (no addr) CALL LABEL_F892EF
	; (no addr) AND IZ, HL
	; (no addr) BIT 000h, IZ
	; (no addr) JR Z, LABEL_F8D149
	; (no addr) CALL LABEL_F8964C
	; (no addr) CP L, 0
	; (no addr) JR Z, LABEL_F8D149
	; (no addr) RES 000h, IZ
	; (no addr) SET 001h, IZ

LABEL_F8D149:
	; (no addr) LD DE, IZ
	; (no addr) EXTZ XDE
	; (no addr) LD XWA, (7F76h)
	; (no addr) LD XBC, 01e50001h
	; (no addr) JR T, LABEL_F8D169

LABEL_F8D158:
	; (no addr) CALL LABEL_F8934D
	; (no addr) EXTZ XHL
	; (no addr) LD XWA, (7F76h)
	; (no addr) LD XBC, 01e50001h
	; (no addr) LD XDE, XHL

LABEL_F8D169:
	; (no addr) CALL ApPostEvent

LABEL_F8D16D:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 8, XSP
	; (no addr) RET

