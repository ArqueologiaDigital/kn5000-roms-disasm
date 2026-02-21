; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
	; (no addr) DEC 6, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 006h), XDE
	; (no addr) LD XIZ, XBC
	; (no addr) LD XWA, (81B0h)
	; (no addr) CP XIZ, 01c00018h
	; (no addr) JRL Z, LABEL_F8EAE9
	; (no addr) CP XIZ, 01c00017h
	; (no addr) JRL Z, LABEL_F8EAE9
	; (no addr) CP XIZ, 01c0000bh
	; (no addr) JRL Z, LABEL_F8EAD5
	; (no addr) CP XIZ, 01e50004h
	; (no addr) JRL Z, LABEL_F8EAA1
	; (no addr) CP XIZ, 01c00013h
	; (no addr) JRL NZ, LABEL_F8ECAD
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000003h
	; (no addr) JRL Z, LABEL_F8EA9B
	; (no addr) CP XWA, 00000002h
	; (no addr) JRL NZ, LABEL_F8ECAD
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8E9AC
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8E9AC:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JRL Z, LABEL_F8EA52
	; (no addr) CP WA, 0
	; (no addr) JR Z, LABEL_F8EA38
	; (no addr) CP WA, 5
	; (no addr) JR Z, LABEL_F8E9F7
	; (no addr) CPW (850Ah), 0000h
	; (no addr) JR GE, LABEL_F8E9D8
	; (no addr) CALL LABEL_F8B16F
	; (no addr) LD (850Ah), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8E9D8:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) JRL T, LABEL_F8ECA9

LABEL_F8E9F7:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0048h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 000h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8EA94

LABEL_F8EA38:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007dh
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) JRL T, LABEL_F8ECAD

LABEL_F8EA52:
	CALR ResetProgressIndication
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0048h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 002h
	; (no addr) LD WA, 00eeh

LABEL_F8EA94:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, LABEL_F8ECAD

LABEL_F8EA9B:
	CALR CancelOperationCleanup
	; (no addr) JRL T, LABEL_F8ECAD

LABEL_F8EAA1:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD (81B0h), XWA
	; (no addr) CALL LABEL_F8B015
	; (no addr) LD (81B4h), HL
	; (no addr) CP HL, 0
	; (no addr) JR GE, LABEL_F8EABA
	; (no addr) LDW (81B4h), 0000h

LABEL_F8EABA:
	; (no addr) LD WA, (81B4h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (81B0h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) JRL T, LABEL_F8ECA9

LABEL_F8EAD5:
	; (no addr) LD BC, (81B4h)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	MULS_BC 0xa
	CALR DisplaySmfSequenceList
	; (no addr) JRL T, LABEL_F8ECAD

LABEL_F8EAE9:
	; (no addr) LD XBC, 01c50001h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD HL, (81B4h)
	; (no addr) LD (XSP + 004h), HL
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) OR XWA, XWA
	; (no addr) JR NZ, LABEL_F8EB2D
	; (no addr) LD XWA, XIZ
	; (no addr) CP XWA, 01c00018h
	; (no addr) JR NZ, LABEL_F8EB1B
	; (no addr) LD WA, HL
	; (no addr) INC 1, WA
	; (no addr) CP WA, (850Ah)
	; (no addr) JRL GE, LABEL_F8EC05
	; (no addr) INC 1, HL
	; (no addr) JR T, LABEL_F8EB62

LABEL_F8EB1B:
	; (no addr) CP XWA, 01c00017h
	; (no addr) JRL NZ, LABEL_F8EC05
	; (no addr) CP HL, 0
	; (no addr) JRL LE, LABEL_F8EC05
	; (no addr) DEC 1, HL
	; (no addr) JR T, LABEL_F8EB62

LABEL_F8EB2D:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000001h
	; (no addr) JR NZ, LABEL_F8EB45
	; (no addr) CP HL, 000ah
	; (no addr) JRL LT, LABEL_F8EC05
	; (no addr) SUB HL, 000ah
	; (no addr) JR T, LABEL_F8EB62

LABEL_F8EB45:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000002h
	; (no addr) JR NZ, LABEL_F8EB95
	; (no addr) LD WA, HL
	; (no addr) ADD WA, 000ah
	; (no addr) LD DE, (850Ah)
	; (no addr) CP WA, DE
	; (no addr) JR GE, LABEL_F8EB6B
	; (no addr) ADD HL, 000ah

LABEL_F8EB62:
	; (no addr) LD (81B4h), HL
	; (no addr) LD BC, HL
	; (no addr) JRL T, LABEL_F8EC09

LABEL_F8EB6B:
	; (no addr) LD BC, DE
	; (no addr) DEC 1, BC
	; (no addr) LD IX, BC
	; (no addr) EXTS XIX
	DIVS_IX 0xa
	; (no addr) EXTS XHL
	DIVS_HL 0xa
	; (no addr) CP HL, IX
	; (no addr) JRL GE, LABEL_F8EC05
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD WA, QDE
	; (no addr) CP WA, 0
	; (no addr) JR Z, LABEL_F8EC05
	; (no addr) LD (81B4h), BC
	; (no addr) JR T, LABEL_F8EC09

LABEL_F8EB95:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) CP XWA, 00000003h
	; (no addr) JR NZ, LABEL_F8EC05
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CALL LABEL_F88B8B
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
	; (no addr) LD WA, 0048h
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD

LABEL_F8EC05:
	; (no addr) LD BC, (81B4h)

LABEL_F8EC09:
	; (no addr) CP (XSP + 004h), BC
	; (no addr) JRL Z, LABEL_F8EC9E
	; (no addr) LD WA, BC
	; (no addr) CALL LABEL_F8B0F1
	; (no addr) LD WA, (81B4h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD DE, QWA
	; (no addr) EXTS XDE
	; (no addr) LD XWA, (81B0h)
	; (no addr) LD XBC, 01e50002h
	; (no addr) CALL ApPostEvent
	; (no addr) LD BC, (81B4h)
	; (no addr) EXTS XBC
	DIVS_BC 0xa
	; (no addr) LD DE, (XSP + 004h)
	; (no addr) EXTS XDE
	DIVS_DE 0xa
	; (no addr) LD XWA, (81B0h)
	; (no addr) CP DE, BC
	; (no addr) JR NZ, LABEL_F8EC97
	; (no addr) LD BC, (XSP + 004h)
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
	; (no addr) LD WA, (81B4h)
	; (no addr) EXTS XWA
	DIVS_WA 0xa
	; (no addr) LD WA, QWA
	; (no addr) SLL 5, WA
	; (no addr) LDA XBC, 850Ch
	; (no addr) LD DE, WA
	; (no addr) EXTZ XDE
	; (no addr) ADD XDE, XBC
	; (no addr) LD XWA, (81B0h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8EC9E

LABEL_F8EC97:
	MULS_BC 0xa
	CALR DisplaySmfSequenceList

LABEL_F8EC9E:
	; (no addr) LD XWA, (81B0h)
	; (no addr) LD XBC, 01c50001h
	; (no addr) LD XDE, 0

LABEL_F8ECA9:
	; (no addr) CALL ApPostEvent

LABEL_F8ECAD:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 6, XSP
	; (no addr) RET

LABEL_F8ECB3:
	; (no addr) PUSH XIZ
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) LD QIZ, HL
	; (no addr) LDW (89F6h), 0000h
	; (no addr) LD IZ, 0

LABEL_F8ECC3:
	; (no addr) LD BC, IZ
	; (no addr) EXTZ XBC
	; (no addr) LD XWA, 00ea07aah
	; (no addr) ADD XWA, XBC
	; (no addr) LD C, (XWA)
	; (no addr) LD DE, 1
	; (no addr) LD A, C
	; (no addr) AND A, 00fh
	; (no addr) JR Z, LABEL_F8ECDB
	; (no addr) SLL A, DE

LABEL_F8ECDB:
	; (no addr) AND DE, QIZ
	; (no addr) JRL Z, LABEL_F8ED7A
	; (no addr) CP C, 3
	; (no addr) JR NZ, LABEL_F8ED11
	; (no addr) CALL LABEL_F872E5
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8ED7A
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) LD XBC, 00ea07aah
	; (no addr) ADD XBC, XWA
	; (no addr) LD DE, 1
	; (no addr) LD A, (XBC)
	; (no addr) AND A, 00fh
	; (no addr) JR Z, LABEL_F8ED04
	; (no addr) SLL A, DE

LABEL_F8ED04:
	; (no addr) OR (89F6h), DE
	; (no addr) CP (89F8h), 004h
	; (no addr) JR NC, LABEL_F8ED73
	; (no addr) JR T, LABEL_F8ED7A

LABEL_F8ED11:
	; (no addr) LD A, C
	; (no addr) CP C, 2
	; (no addr) JR NZ, LABEL_F8ED4A
	; (no addr) CALL LABEL_F87218
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8ED7A
	; (no addr) CALL LABEL_F87366
	; (no addr) CP HL, 0
	; (no addr) JR NZ, LABEL_F8ED7A
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) LD XBC, 00ea07aah
	; (no addr) ADD XBC, XWA
	; (no addr) LD DE, 1
	; (no addr) LD A, (XBC)
	; (no addr) AND A, 00fh
	; (no addr) JR Z, LABEL_F8ED3D
	; (no addr) SLL A, DE

LABEL_F8ED3D:
	; (no addr) OR (89F6h), DE
	; (no addr) CP (89F8h), 004h
	; (no addr) JR NC, LABEL_F8ED73
	; (no addr) JR T, LABEL_F8ED7A

LABEL_F8ED4A:
	; (no addr) CALL LABEL_F87218
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8ED7A
	; (no addr) LD WA, IZ
	; (no addr) EXTZ XWA
	; (no addr) LD XBC, 00ea07aah
	; (no addr) ADD XBC, XWA
	; (no addr) LD DE, 1
	; (no addr) LD A, (XBC)
	; (no addr) AND A, 00fh
	; (no addr) JR Z, LABEL_F8ED68
	; (no addr) SLL A, DE

LABEL_F8ED68:
	; (no addr) OR (89F6h), DE
	; (no addr) CP (89F8h), 004h
	; (no addr) JR C, LABEL_F8ED7A

LABEL_F8ED73:
	; (no addr) LD A, IZL
	; (no addr) LD (89F8h), A

LABEL_F8ED7A:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 4
	; (no addr) JRL C, LABEL_F8ECC3
	; (no addr) POP XIZ
	; (no addr) RET

LABEL_F8ED83:
	; (no addr) PUSH IZ
	; (no addr) LD A, (89F8h)
	; (no addr) CP A, 4
	; (no addr) JR NC, LABEL_F8EDCE
	; (no addr) LD BC, (89F6h)
	; (no addr) CP BC, 0
	; (no addr) JR Z, LABEL_F8EDCE
	; (no addr) LD IZ, 1
	; (no addr) EXTZ WA
	; (no addr) LD QBC, WA
	; (no addr) LDA XDE, 0EA07AAh

LABEL_F8EDA0:
	; (no addr) LD HL, QBC
	; (no addr) ADD HL, IZ
	; (no addr) AND HL, 0003h
	; (no addr) LD WA, HL
	; (no addr) EXTZ XWA
	; (no addr) LD XIX, XDE
	; (no addr) ADD XIX, XWA
	; (no addr) LD IY, 1
	; (no addr) LD A, (XIX)
	; (no addr) AND A, 00fh
	; (no addr) JR Z, LABEL_F8EDBC
	; (no addr) SLL A, IY

LABEL_F8EDBC:
	; (no addr) AND IY, BC
	; (no addr) JR Z, LABEL_F8EDC8
	; (no addr) LD (89F8h), L
	LD_L 0x1
	; (no addr) JR T, LABEL_F8EDD0

LABEL_F8EDC8:
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 4
	; (no addr) JR C, LABEL_F8EDA0

LABEL_F8EDCE:
	LD_L 0x0

LABEL_F8EDD0:
	; (no addr) POP IZ
	; (no addr) RET

; -----------------------------------------------------------------------------
; Wallpaper Name Getter Routines
; -----------------------------------------------------------------------------
; These routines retrieve wallpaper display names from various sources:
; - User RAM structures (0x1ED350, 0x1E0000, 0x1E4980, 0x1E4AA7)
; - ROM lookup tables (0xEA07AE, 0xEA07EA, 0xEA083E, 0xEA08DA)
;
; Common calling convention:
;   XWA = destination buffer pointer
;   BC = index or selection parameter
;   E = type marker byte
; -----------------------------------------------------------------------------

; Get wallpaper name from config structure by index
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetConfigName:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) LDA XHL, 01ED350h	; Wallpaper config base address
	; (no addr) EXTZ XBC
	; (no addr) SLL 4, XBC	; index * 16
	; (no addr) ADD XHL, XBC
	; (no addr) LDA XHL, XHL + 010h	; Offset to name field
	; (no addr) LD (XIZ+), E	; Store type marker
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, XHL
	; (no addr) LD DE, 0010h	; Copy 16 bytes
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD (XIZ + 010h), 000h	; Null terminate
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

; Get wallpaper name with calculated offset
; Input: XWA = dest buffer, BC = multiplier, E = type marker
WP_GetNameByOffset:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) LDA XWA, 01ED350h
	; (no addr) LD HL, (XWA + 00Dh)	; Get entry size from config
	; (no addr) LD XIX, XWA
	; (no addr) MUL XHL, BC	; Calculate offset
	; (no addr) ADD XIX, XHL
	; (no addr) LDA XBC, XIX + 0B2h	; Offset to name field
	; (no addr) LD (XIZ+), E
	; (no addr) LD XWA, XIZ
	; (no addr) LD DE, 0010h
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD (XIZ + 010h), 000h
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

; Get wallpaper name from ROM table 1 (0xEA07AE)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName1:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) LD (XIZ+), E
	; (no addr) LD WA, BC
	; (no addr) EXTZ XWA
	; (no addr) SLL 2, XWA	; index * 4 (pointer size)
	; (no addr) LD XBC, 0EA07AEh	; ROM table address
	; (no addr) ADD XBC, XWA
	; (no addr) LD XBC, (XBC)	; Get string pointer
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

; Simple wallpaper pointer lookup from ROM table 2 (0xEA07EA)
; Input: WA = index
; Output: XHL = pointer to name string
WP_GetPresetPtr:
	; (no addr) EXTZ XWA
	; (no addr) SLL 2, XWA	; index * 4
	; (no addr) LD XBC, 0EA07EAh
	; (no addr) ADD XBC, XWA
	; (no addr) LD XHL, (XBC)
	; (no addr) RET

; Get wallpaper name with bank/memory selection
; Input: XWA = dest buffer, BC = bank, DE = memory slot, stack+8 = type marker
WP_GetBankMemName:
	; (no addr) PUSH XIZ
	; (no addr) LD HL, BC
	; (no addr) LD XIZ, XWA
	.byte 0xf5, 0xf8, 0x31	; LDA XBC, XIZ+
	; (no addr) LD WA, (XSP + 008h)
	; (no addr) LD (XBC), A	; Store type marker
	; (no addr) CP DE, 4
	; (no addr) JR NC, WP_GetBankMemName_FromROM
	; From RAM at 0x0948A0
	; (no addr) LDA XBC, 0948A0h
	; (no addr) SLL 2, HL
	; (no addr) ADD HL, DE
	MUL_HL 0x60	; Entry size = 96 bytes
	; (no addr) ADD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) LD DE, 000Dh	; Copy 13 bytes
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD (XIZ + 00Dh), 000h
	; (no addr) JR T, WP_GetBankMemName_Format
WP_GetBankMemName_FromROM:
	; (no addr) EXTZ XDE
	; (no addr) SLL 2, XDE
	; (no addr) LD XBC, 0EA083Eh	; ROM table address
	; (no addr) ADD XBC, XDE
	; (no addr) LD XBC, (XBC)
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
WP_GetBankMemName_Format:
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RETD 2

; Get wallpaper name from ROM table 3 (0xEA08DA)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName3:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) LD (XIZ+), E
	; (no addr) LD WA, BC
	; (no addr) EXTZ XWA
	; (no addr) SLL 2, XWA
	; (no addr) LD XBC, 0EA08DAh
	; (no addr) ADD XBC, XWA
	; (no addr) LD XBC, (XBC)
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

; Get wallpaper name from structure at 0x1E0000 (stride 0x1D6)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName1:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) LDA XHL, 01E0000h
	; (no addr) LDA XHL, XHL + 010h
	MUL_BC 0x1D6	; Entry stride
	; (no addr) ADD XHL, XBC
	; (no addr) LD (XIZ+), E
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, XHL
	; (no addr) LD DE, 0010h
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD (XIZ + 010h), 000h
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

; Get wallpaper name from RAM at 0x1E4980
; Input: XWA = dest buffer, BC = (unused), E = type marker
WP_GetUserName2:
	; (no addr) PUSH XIZ
	; (no addr) LD DE, BC
	; (no addr) LD XIZ, XWA
	; (no addr) LDA XBC, 01E4980h
	; (no addr) LD (XIZ+), E
	; (no addr) LD XWA, XIZ
	; (no addr) LD DE, 0010h
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD (XIZ + 010h), 000h
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 0010h
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

; Get wallpaper name from structure at 0x1E4AA7 (stride 0x50)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName3:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XWA
	; (no addr) LDA XHL, 01E4AA7h
	MUL_BC 0x50	; Entry stride
	; (no addr) ADD XHL, XBC
	; (no addr) LD (XIZ+), E
	; (no addr) LD (XIZ+), 020h	; Space character
	; (no addr) LD XWA, XIZ
	; (no addr) LD XBC, XHL
	; (no addr) LD DE, 000Dh	; Copy 13 bytes
	; (no addr) CALL LABEL_F890F2
	; (no addr) LD (XIZ + 00Dh), 000h
	; (no addr) LD XWA, XIZ
	; (no addr) LD BC, 000Fh
	CALR TrimAndPadSmfFilename
	; (no addr) POP XIZ
	; (no addr) RET

