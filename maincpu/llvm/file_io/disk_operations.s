; =============================================================================
; file_io/disk_operations.asm - Disk and File Operations
; =============================================================================
; File copy, rename, format, and disk information routines.
;
; Key routines:
;   FileCopyFunc, FileRenameFunc     - File copy and rename
;   FileRenameSmfFunc                - SMF file rename
;   FmmFormatFunc                    - Disk format
;   UtilityTtlJgFunc                 - Utility title handler
;   FmmLoadTitleFunc, FmmSaveTitleFunc - Load/Save titles
;   DiskNameFunc, DiskInfoFunc       - Disk information
;   SongNameFunc                     - Song naming
;   SaveFileNameNumFunc, SaveFileNameFunc - Save filename handling
;   CurFileNameFunc                  - Current filename
; =============================================================================

FileCopyFunc:
	; (no addr) PUSH XIZ
	; (no addr) LD XIZ, XDE
	; (no addr) CP XBC, 01c00018h
	; (no addr) JRL Z, LABEL_F8BC38
	; (no addr) CP XBC, 01c00017h
	; (no addr) JRL Z, LABEL_F8BC38
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR Z, LABEL_F8BC00
	; (no addr) CP XBC, 01e50004h
	; (no addr) JRL NZ, LABEL_F8BE18
	; (no addr) LD (7F60h), XIZ
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD (7F64h), HL
	; (no addr) CP HL, 0
	; (no addr) JR LT, LABEL_F8BBF1
	; (no addr) CP HL, 0013h
	; (no addr) JR GE, LABEL_F8BBE8
	; (no addr) INC 1, HL
	; (no addr) LD (7F66h), HL
	; (no addr) JRL T, LABEL_F8BE18

LABEL_F8BBE8:
	; (no addr) DEC 1, HL
	; (no addr) LD (7F66h), HL
	; (no addr) JRL T, LABEL_F8BE18

LABEL_F8BBF1:
	; (no addr) LDW (7F64h), 0000h
	; (no addr) LDW (7F66h), 0001h
	; (no addr) JRL T, LABEL_F8BE18

LABEL_F8BC00:
	; (no addr) LD (850Ch), 000h
	; (no addr) LD WA, (7F66h)
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) LDA XWA, 850Dh
	; (no addr) LD DE, (7F66h)
	; (no addr) INC 1, DE
	; (no addr) PUSHW 0006h
	; (no addr) PUSHW 0000h
	; (no addr) CALL LABEL_F891DD
	; (no addr) LD XWA, (7F60h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 0000850ch
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, LABEL_F8BE18

LABEL_F8BC38:
	; (no addr) OR XIZ, XIZ
	; (no addr) JRL NZ, LABEL_F8BCD7
	; (no addr) LD WA, (7F66h)
	; (no addr) LD DE, WA
	; (no addr) CP XBC, 01c00018h
	; (no addr) JR NZ, LABEL_F8BCAB
	; (no addr) CP WA, 0
	; (no addr) JR LE, LABEL_F8BC55
	; (no addr) DEC 1, WA
	; (no addr) LD (7F66h), WA

LABEL_F8BC55:
	; (no addr) LD WA, (7F66h)
	; (no addr) CP WA, (7F64h)
	; (no addr) JR NZ, LABEL_F8BC6F
	; (no addr) CP WA, 0
	; (no addr) JR LE, LABEL_F8BC6B
	; (no addr) DEC 1, WA
	; (no addr) LD (7F66h), WA
	; (no addr) JR T, LABEL_F8BC73

LABEL_F8BC6B:
	; (no addr) LD (7F66h), DE

LABEL_F8BC6F:
	; (no addr) LD WA, (7F66h)

LABEL_F8BC73:
	; (no addr) CP WA, DE
	; (no addr) JRL Z, LABEL_F8BE18
	; (no addr) LD (850Ch), 000h
	; (no addr) LD WA, (7F66h)
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) LDA XWA, 850Dh
	; (no addr) LD DE, (7F66h)
	; (no addr) INC 1, DE
	; (no addr) PUSHW 0006h
	; (no addr) PUSHW 0000h
	; (no addr) CALL LABEL_F891DD
	; (no addr) LD XWA, (7F60h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 0000850ch
	; (no addr) JR T, LABEL_F8BD19

LABEL_F8BCAB:
	; (no addr) CP XBC, 01c00017h
	; (no addr) JR NZ, LABEL_F8BC6F
	; (no addr) CP WA, 0013h
	; (no addr) JR GE, LABEL_F8BCBF
	; (no addr) INC 1, WA
	; (no addr) LD (7F66h), WA

LABEL_F8BCBF:
	; (no addr) LD WA, (7F66h)
	; (no addr) CP WA, (7F64h)
	; (no addr) JR NZ, LABEL_F8BC6F
	; (no addr) CP WA, 0013h
	; (no addr) JR GE, LABEL_F8BC6B
	; (no addr) INC 1, WA
	; (no addr) LD (7F66h), WA
	; (no addr) JR T, LABEL_F8BC73

LABEL_F8BCD7:
	; (no addr) CP XIZ, 00000008h
	; (no addr) JRL NZ, LABEL_F8BD97
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JRL Z, LABEL_F8BD97
	; (no addr) LD WA, (7F66h)
	; (no addr) CALL LABEL_F8945F
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8BD20
	; (no addr) CP (0340EAh), 000h
	; (no addr) JR Z, LABEL_F8BD20
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c50000h
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 00600037h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0

LABEL_F8BD19:
	; (no addr) CALL ApPostEvent
	; (no addr) JRL T, LABEL_F8BE18

LABEL_F8BD20:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD WA, (7F66h)
	; (no addr) CALL LABEL_F889D9
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
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007bh
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8BE14

LABEL_F8BD97:
	; (no addr) CP XIZ, 00000032h
	; (no addr) JR NZ, LABEL_F8BE18
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD WA, (7F66h)
	; (no addr) CALL LABEL_F889D9
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
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007bh
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh

LABEL_F8BE14:
	; (no addr) CALL LABEL_F994BD

LABEL_F8BE18:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) RET

FileRenameFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 004h), XDE
	; (no addr) CP XBC, 01e00086h
	; (no addr) JRL Z, LABEL_F8BEB6
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JRL NZ, LABEL_F8BF15
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) CP HL, 0
	; (no addr) JR LT, LABEL_F8BE95
	; (no addr) LDA XIZ, 8870h
	; (no addr) LD WA, HL
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD IY, 0
	; (no addr) LDA XIX, 0EED778h
	; (no addr) LDA XWA, 8870h
	; (no addr) LD XHL, XWA
	; (no addr) JR T, LABEL_F8BE6E

LABEL_F8BE5D:
	; (no addr) EXTZ BC
	; (no addr) LD C, (XIX + BC)
	; (no addr) AND C, 007h
	; (no addr) JR NZ, LABEL_F8BE6C
	; (no addr) LD (XDE), 05fh

LABEL_F8BE6C:
	; (no addr) INC 1, IY

LABEL_F8BE6E:
	; (no addr) CP IY, 6
	; (no addr) JR GE, LABEL_F8BE7D
	; (no addr) LDA XDE, XHL + IY
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 0
	; (no addr) JR NZ, LABEL_F8BE5D

LABEL_F8BE7D:
	; (no addr) CP IY, 6
	; (no addr) JR GE, LABEL_F8BE8F
	; (no addr) LD XBC, XWA

LABEL_F8BE83:
	; (no addr) LD (XBC + IY), 05fh
	; (no addr) INC 1, IY
	; (no addr) CP IY, 6
	; (no addr) JR LT, LABEL_F8BE83

LABEL_F8BE8F:
	; (no addr) LD (XWA + 006h), 000h
	; (no addr) JR T, LABEL_F8BEA3

LABEL_F8BE95:
	; (no addr) LD XWA, 00008870h
	; (no addr) LD XBC, 00ea06beh
	; (no addr) CALL LABEL_F890DC

LABEL_F8BEA3:
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01e00086h
	; (no addr) LD XDE, 00008870h
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8BF15

LABEL_F8BEB6:
	; (no addr) CALL CheckFileSystemStatus
	; (no addr) CP HL, 0
	; (no addr) JR Z, LABEL_F8BF15
	; (no addr) LD XWA, 00008870h
	; (no addr) LD XBC, (XSP + 004h)
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD XWA, 00008870h
	; (no addr) CALL LABEL_F8879E
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
	; (no addr) CALL LABEL_F994BD

LABEL_F8BF15:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

FileRenameSmfFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 004h), XDE
	; (no addr) CP XBC, 01e00086h
	; (no addr) JRL Z, LABEL_F8BFBB
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JRL NZ, LABEL_F8C020
	; (no addr) CALL LABEL_F89AC7
	; (no addr) CP HL, 0
	; (no addr) JR LT, LABEL_F8BF9A
	; (no addr) LDA XIZ, 8870h
	; (no addr) LD WA, HL
	; (no addr) CALL LABEL_F89BF0
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD IY, 0
	; (no addr) LDA XIX, 0EED778h
	; (no addr) LDA XWA, 8870h
	; (no addr) LD XHL, XWA
	; (no addr) JR T, LABEL_F8BF6D

LABEL_F8BF5C:
	; (no addr) EXTZ BC
	; (no addr) LD C, (XIX + BC)
	; (no addr) AND C, 007h
	; (no addr) JR NZ, LABEL_F8BF6B
	; (no addr) LD (XDE), 05fh

LABEL_F8BF6B:
	; (no addr) INC 1, IY

LABEL_F8BF6D:
	; (no addr) CP IY, 0008h
	; (no addr) JR GE, LABEL_F8BF7E
	; (no addr) LDA XDE, XHL + IY
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 0
	; (no addr) JR NZ, LABEL_F8BF5C

LABEL_F8BF7E:
	; (no addr) CP IY, 0008h
	; (no addr) JR GE, LABEL_F8BF94
	; (no addr) LD XBC, XWA

LABEL_F8BF86:
	; (no addr) LD (XBC + IY), 05fh
	; (no addr) INC 1, IY
	; (no addr) CP IY, 0008h
	; (no addr) JR LT, LABEL_F8BF86

LABEL_F8BF94:
	; (no addr) LD (XWA + 008h), 000h
	; (no addr) JR T, LABEL_F8BFA8

LABEL_F8BF9A:
	; (no addr) LD XWA, 00008870h
	; (no addr) LD XBC, 00ea06c6h
	; (no addr) CALL LABEL_F890DC

LABEL_F8BFA8:
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01e00086h
	; (no addr) LD XDE, 00008870h
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8C020

LABEL_F8BFBB:
	; (no addr) LD XWA, 00008870h
	; (no addr) LD XBC, (XSP + 004h)
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 00008870h
	; (no addr) LD XBC, 00ea06d0h
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD XWA, 00008870h
	; (no addr) CALL LABEL_F88B3A
	; (no addr) LD WA, HL
	; (no addr) LD BC, 5
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	CALR SignalProgressUpdate
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD

LABEL_F8C020:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

FmmFormatFunc:
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c00007h
	; (no addr) JRL Z, LABEL_F8C0BE
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8C20A
	; (no addr) CP XDE, 00000003h
	; (no addr) JR Z, LABEL_F8C0AE
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8C20A
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	LD_8_8 0x7F6A, 0x8D37
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8C06A
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8C06A:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 2
	; (no addr) JR Z, LABEL_F8C076
	; (no addr) CP WA, 3
	; (no addr) JR NZ, LABEL_F8C091

LABEL_F8C076:
	; (no addr) LD (7F68h), A
	; (no addr) LD XWA, 007b0036h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (84FEh), 000h
	; (no addr) JR T, LABEL_F8C0A6

LABEL_F8C091:
	; (no addr) LD XWA, 007b003fh
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (84FEh), 002h

LABEL_F8C0A6:
	; (no addr) LD (7F6Ch), 001h
	; (no addr) JRL T, LABEL_F8C20A

LABEL_F8C0AE:
	CALR CancelOperationCleanup
	; (no addr) LD (84FEh), 000h
	; (no addr) LD (7F6Ch), 000h
	; (no addr) JRL T, LABEL_F8C20A

LABEL_F8C0BE:
	; (no addr) CP (7F6Ch), 000h
	; (no addr) JRL Z, LABEL_F8C20A
	; (no addr) LD A, (7F6Ah)
	; (no addr) EXTZ WA
	; (no addr) CP XDE, 0000000fh
	; (no addr) JRL Z, LABEL_F8C1FC
	; (no addr) LD C, (84FEh)
	; (no addr) CP XDE, 0000000bh
	; (no addr) JRL Z, LABEL_F8C1C0
	; (no addr) CP XDE, 0000000ah
	; (no addr) JRL NZ, LABEL_F8C20A
	; (no addr) LD A, C
	; (no addr) CP C, 0
	; (no addr) JRL NZ, LABEL_F8C199
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD A, (7F68h)
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89091
	; (no addr) LD IZ, HL
	CALR SignalProgressUpdate
	CALR ResetProgressIndication
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) CP IZ, 0
	; (no addr) JR GE, LABEL_F8C172
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F6Ah)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD (7F6Ch), 000h
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, IZ
	; (no addr) LD BC, 0008h
	CALR LABEL_F8B48E
	; (no addr) LD (7F42h), L
	; (no addr) LD WA, 00eeh
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, LABEL_F8C205

LABEL_F8C172:
	; (no addr) LD XWA, 007b0036h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 007b0031h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (84FEh), 001h
	; (no addr) JR T, LABEL_F8C20A

LABEL_F8C199:
	; (no addr) CP A, 2
	; (no addr) JR NZ, LABEL_F8C20A
	; (no addr) LD (7F68h), 003h
	; (no addr) LD XWA, 007b003fh
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 007b0036h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8C1F6

LABEL_F8C1C0:
	; (no addr) LD E, C
	; (no addr) CP C, 0
	; (no addr) JR NZ, LABEL_F8C1D1
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD (7F6Ch), 000h
	; (no addr) JR T, LABEL_F8C20A

LABEL_F8C1D1:
	; (no addr) CP E, 2
	; (no addr) JR NZ, LABEL_F8C20A
	; (no addr) LD (7F68h), 002h
	; (no addr) LD XWA, 007b003fh
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 007b0036h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 0

LABEL_F8C1F6:
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8C205

LABEL_F8C1FC:
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD (7F6Ch), 000h

LABEL_F8C205:
	; (no addr) LD (84FEh), 000h

LABEL_F8C20A:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) RET

UtilityTtlJgFunc:
	; (no addr) CP XBC, 01c00007h
	; (no addr) JR NZ, LABEL_F8C21F
	; (no addr) LD WA, 007bh
	; (no addr) LD BC, 007ch
	CALR LABEL_F8B36E

LABEL_F8C21F:
	; (no addr) LD XHL, 0
	; (no addr) RET

FmmLoadTitleFunc:
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c00007h
	; (no addr) JRL Z, LABEL_F8C435
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8C450
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, LABEL_F8C420
	; (no addr) CP XDE, 00000009h
	; (no addr) JRL Z, LABEL_F8C3FE
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8C450
	; (no addr) LD (84FEh), 000h
	LDW_16_16 0x7F70, 0x8500
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	LD_8_8 0x7F6E, 0x8D37
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8C28B
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F8C28B:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JRL Z, LABEL_F8C355
	; (no addr) CP WA, 0
	; (no addr) JRL Z, LABEL_F8C33F
	; (no addr) CP WA, 5
	; (no addr) JR Z, LABEL_F8C2FB
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, LABEL_F8C2B8
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8C2B8:
	; (no addr) CPW (8502h), 0000h
	; (no addr) JRL NZ, LABEL_F8C3A1
	; (no addr) CPW (8504h), 0000h
	; (no addr) JR GE, LABEL_F8C2D4
	; (no addr) CALL GetFileCountEncoded
	; (no addr) LD (8504h), HL
	CALR SignalProgressUpdate

LABEL_F8C2D4:
	; (no addr) CPW (8504h), 0000h
	; (no addr) JRL LE, LABEL_F8C3A1
	; (no addr) CP (7F6Eh), 064h
	; (no addr) JRL Z, LABEL_F8C3A1
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 0064h
	; (no addr) JRL T, LABEL_F8C44C

LABEL_F8C2FB:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F6Eh)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 000h
	; (no addr) LD WA, 00eeh
	; (no addr) JR T, LABEL_F8C39A

LABEL_F8C33F:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD WA, 007dh
	; (no addr) JRL T, LABEL_F8C44C

LABEL_F8C355:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	CALR ResetProgressIndication
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) LD A, (7F6Eh)
	; (no addr) EXTZ WA
	; (no addr) CALL UI_PostModeChangeEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01e0009eh
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (7F42h), 002h
	; (no addr) LD WA, 00eeh

LABEL_F8C39A:
	; (no addr) CALL LABEL_F994BD
	; (no addr) JRL T, LABEL_F8C450

LABEL_F8C3A1:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD (89FCh), 000h
	; (no addr) LD (89FEh), 000h
	; (no addr) LD (8A00h), 000h
	; (no addr) LD (8A02h), 000h
	; (no addr) LD (8A04h), 000h
	; (no addr) LD (8A06h), 000h
	; (no addr) LD (8A08h), 000h
	; (no addr) LD IZ, 0

LABEL_F8C3E6:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F89321
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 0008h
	; (no addr) JR LT, LABEL_F8C3E6
	; (no addr) LD (89F8h), 004h
	; (no addr) JR T, LABEL_F8C450

LABEL_F8C3FE:
	; (no addr) CPW (7F70h), 0000h
	; (no addr) JR LT, LABEL_F8C450
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD IZ, HL
	; (no addr) CP IZ, 0
	; (no addr) JR LT, LABEL_F8C450
	; (no addr) CP IZ, 0013h
	; (no addr) JR GE, LABEL_F8C450
	; (no addr) LD WA, IZ
	; (no addr) INC 1, WA
	; (no addr) CALL NotifyUIOfSelectionChange
	; (no addr) JR T, LABEL_F8C450

LABEL_F8C420:
	CALR CancelOperationCleanup
	; (no addr) LD XWA, 00610001h
	; (no addr) LD XBC, 01e0007fh
	; (no addr) LD XDE, 1
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8C450

LABEL_F8C435:
	; (no addr) CP XDE, 0000000fh
	; (no addr) JR NZ, LABEL_F8C450
	; (no addr) CP (8D34h), 007h
	; (no addr) JR NZ, LABEL_F8C449
	; (no addr) LD WA, 00d6h
	; (no addr) JR T, LABEL_F8C44C

LABEL_F8C449:
	; (no addr) LD WA, 0060h

LABEL_F8C44C:
	; (no addr) CALL UI_PostModeChangeEvent

LABEL_F8C450:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) RET

FmmSaveTitleFunc:
	; (no addr) PUSH IZ
	; (no addr) CP XBC, 01c00007h
	; (no addr) JRL Z, LABEL_F8C515
	; (no addr) CP XBC, 01c00013h
	; (no addr) JRL NZ, LABEL_F8C524
	; (no addr) CP XDE, 00000003h
	; (no addr) JRL Z, LABEL_F8C500
	; (no addr) CP XDE, 00000002h
	; (no addr) JRL NZ, LABEL_F8C524
	; (no addr) LD (84FEh), 000h
	; (no addr) LD WA, 1
	CALR InitializeOperationState
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00001h
	; (no addr) LD XDE, 5
	; (no addr) CALL ApPostEvent
	; (no addr) CPW (8502h), 0000h
	; (no addr) JR GE, LABEL_F8C4AE
	; (no addr) CALL GetEncodedFileSizeData
	; (no addr) LD (8502h), HL
	; (no addr) CALL LABEL_F8958D
	; (no addr) CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8C4AE:
	; (no addr) CP (8D37h), 066h
	; (no addr) JR Z, LABEL_F8C4E2
	; (no addr) LD IZ, 0

LABEL_F8C4B7:
	; (no addr) LD A, IZL
	; (no addr) EXTZ WA
	; (no addr) CALL LABEL_F8937F
	; (no addr) INC 1, IZ
	; (no addr) CP IZ, 6
	; (no addr) JR LT, LABEL_F8C4B7
	; (no addr) LD WA, 6
	; (no addr) CALL LABEL_F89393
	; (no addr) LD WA, 7
	; (no addr) CALL LABEL_F89393
	; (no addr) CALL LABEL_F893CA
	; (no addr) LD XIY, 00ea066ah
	; (no addr) LD XIX, 00008a0ch
	LDIW

LABEL_F8C4E2:
	; (no addr) LD XWA, 00600026h
	; (no addr) LD XBC, 01c00002h
	; (no addr) LD XDE, 0
	; (no addr) CALL ApPostEvent
	; (no addr) LD XWA, 0ffffffffh
	; (no addr) LD XBC, 01c0000ah
	; (no addr) LD XDE, 0
	; (no addr) JR T, LABEL_F8C50F

LABEL_F8C500:
	CALR CancelOperationCleanup
	; (no addr) LD XWA, 00670001h
	; (no addr) LD XBC, 01e0007fh
	; (no addr) LD XDE, 1

LABEL_F8C50F:
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8C524

LABEL_F8C515:
	; (no addr) CP XDE, 0000000fh
	; (no addr) JR NZ, LABEL_F8C524
	; (no addr) LD WA, 0060h
	; (no addr) CALL UI_PostModeChangeEvent

LABEL_F8C524:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) RET

DiskNameFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 004h), XDE
	; (no addr) CP XBC, 01e00086h
	; (no addr) JRL Z, LABEL_F8C5E2
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JR Z, LABEL_F8C56C
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JRL NZ, LABEL_F8C609
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LDA XIZ, 878Ch
	; (no addr) CALL LABEL_F8958D
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 0000878ch
	; (no addr) JR T, LABEL_F8C5DC

LABEL_F8C56C:
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LDA XIZ, 878Ch
	; (no addr) CALL LABEL_F8958D
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD IY, 0
	; (no addr) LDA XIX, 8870h
	; (no addr) LDA XIZ, 0EED778h
	; (no addr) LDA XDE, 878Ch
	; (no addr) LD XHL, XDE
	; (no addr) JR T, LABEL_F8C5AA

LABEL_F8C594:
	; (no addr) LD A, (XIX + IY)
	; (no addr) EXTZ WA
	; (no addr) LD A, (XIZ + WA)
	; (no addr) AND A, 007h
	; (no addr) JR NZ, LABEL_F8C5A8
	; (no addr) LD (XBC), 05fh

LABEL_F8C5A8:
	; (no addr) INC 1, IY

LABEL_F8C5AA:
	; (no addr) CP IY, 000bh
	; (no addr) JR GE, LABEL_F8C5BA
	; (no addr) LDA XBC, XHL + IY
	; (no addr) CP (XBC), 000h
	; (no addr) JR NZ, LABEL_F8C594

LABEL_F8C5BA:
	; (no addr) CP IY, 000bh
	; (no addr) JR GE, LABEL_F8C5D0
	; (no addr) LD XWA, XDE

LABEL_F8C5C2:
	; (no addr) LD (XWA + IY), 05fh
	; (no addr) INC 1, IY
	; (no addr) CP IY, 000bh
	; (no addr) JR LT, LABEL_F8C5C2

LABEL_F8C5D0:
	; (no addr) LD (XDE + 00bh), 000h
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01e00086h

LABEL_F8C5DC:
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8C609

LABEL_F8C5E2:
	; (no addr) LD XWA, 0000878ch
	; (no addr) LD XBC, (XSP + 004h)
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LD XWA, 0000878ch
	; (no addr) CALL LABEL_F5289C
	CALR SignalProgressUpdate
	CALR ResetProgressIndication
	; (no addr) LD WA, 0060h
	; (no addr) CALL UI_PostModeChangeEvent

LABEL_F8C609:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

DiskInfoFunc:
	; (no addr) LDA XSP, XSP - 010h
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 010h), XDE
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JRL NZ, LABEL_F8C735
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) CPW (8500h), 0000h
	; (no addr) JR GE, LABEL_F8C636
	; (no addr) CALL GetDiskSizeInfo
	; (no addr) EXTZ HL
	; (no addr) LD (8500h), HL

LABEL_F8C636:
	; (no addr) LD WA, (8500h)
	; (no addr) CP WA, 1
	; (no addr) JR Z, LABEL_F8C65A
	; (no addr) CP WA, 0
	; (no addr) JR Z, LABEL_F8C65A
	; (no addr) CP WA, 2
	; (no addr) JR Z, LABEL_F8C64A
	; (no addr) CP WA, 3
	; (no addr) JR NZ, LABEL_F8C65D

LABEL_F8C64A:
	; (no addr) CALL GetEncodedFreeSpaceData
	; (no addr) LD (XSP + 004h), XHL
	; (no addr) CALL LABEL_F89573
	; (no addr) LD (XSP + 00ch), XHL
	; (no addr) JR T, LABEL_F8C665

LABEL_F8C65A:
	CALR ResetProgressIndication

LABEL_F8C65D:
	; (no addr) LD XWA, 0
	; (no addr) LD (XSP + 00ch), XWA
	; (no addr) LD (XSP + 004h), XWA

LABEL_F8C665:
	; (no addr) LD XWA, (XSP + 00ch)
	; (no addr) CP XWA, 00000000h
	; (no addr) JR LE, LABEL_F8C68F
	; (no addr) LD XWA, (XSP + 00ch)
	; (no addr) SUB XWA, (XSP + 004h)
	; (no addr) LD XBC, 00000064h
	; (no addr) CALL LABEL_FF0A5C
	; (no addr) LD XIZ, XHL
	; (no addr) LD XBC, (XSP + 00ch)
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_FF0C0E
	; (no addr) LD (XSP + 008h), XHL
	; (no addr) JR T, LABEL_F8C694

LABEL_F8C68F:
	; (no addr) LD XWA, 0
	; (no addr) LD (XSP + 008h), XWA

LABEL_F8C694:
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, XWA
	; (no addr) SRA 15, XBC
	SRA_0_XBC
	; (no addr) AND XBC, 000003ffh
	; (no addr) ADD XBC, XWA
	; (no addr) LD (XSP + 004h), XBC
	; (no addr) SRA 10, XBC
	; (no addr) LD (XSP + 004h), XBC
	; (no addr) LD WA, (8500h)
	; (no addr) SLA 002h, WA
	; (no addr) LDA XBC, 0EA0558h
	; (no addr) LD XBC, (XBC + WA)
	; (no addr) LD XWA, 000087ceh
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 000087ceh
	; (no addr) LD XBC, 00ea06d6h
	; (no addr) CALL LABEL_F89113
	; (no addr) LDA XWA, 87CEh
	; (no addr) LD (XSP + 00ch), XWA
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD BC, 4
	CALR LABEL_F8B67F
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, (XSP + 00ch)
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, 000087ceh
	; (no addr) LD XBC, 00ea06dah
	; (no addr) CALL LABEL_F89113
	; (no addr) LDA XWA, 87CEh
	; (no addr) LD (XSP + 00ch), XWA
	; (no addr) LD XWA, (XSP + 008h)
	; (no addr) LD BC, 3
	CALR LABEL_F8B67F
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, (XSP + 00ch)
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, 000087ceh
	; (no addr) LD XBC, 00ea06e4h
	; (no addr) CALL LABEL_F89113
	; (no addr) LD XWA, (XSP + 010h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 000087ceh
	; (no addr) CALL ApPostEvent

LABEL_F8C735:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) LDA XSP, XSP + 010h
	; (no addr) RET

SongNameFunc:
	; (no addr) DEC 8, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 006h), XDE
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR NZ, LABEL_F8C7AD
	; (no addr) CALL LABEL_F89AC7
	; (no addr) LD IZ, HL
	; (no addr) CP IZ, 0
	; (no addr) JR LT, LABEL_F8C797
	; (no addr) LD WA, 0
	CALR InitializeOperationState
	; (no addr) LDA XWA, 880Eh
	; (no addr) LD (XSP + 002h), XWA
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F8A07F
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) CALL LABEL_F890DC
	; (no addr) LDA XWA, 880Eh
	; (no addr) LD (XWA + 01eh), 000h
	; (no addr) LDA XBC, XWA + 01dh
	; (no addr) LD XDE, XBC
	; (no addr) LDA XHL, XBC - 01dh
	; (no addr) JR T, LABEL_F8C786

LABEL_F8C781:
	; (no addr) LD (XDE), 000h
	; (no addr) DEC 1, XDE

LABEL_F8C786:
	; (no addr) LD C, (XDE)
	; (no addr) CP C, 020h
	; (no addr) JR NZ, LABEL_F8C791
	; (no addr) CP XDE, XHL
	; (no addr) JR UGT, LABEL_F8C781

LABEL_F8C791:
	; (no addr) CALL LABEL_F8929D
	; (no addr) JR T, LABEL_F8C79C

LABEL_F8C797:
	; (no addr) LD (880Eh), 000h

LABEL_F8C79C:
	; (no addr) LD XWA, (XSP + 006h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 0000880eh
	; (no addr) CALL ApPostEvent

LABEL_F8C7AD:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) INC 8, XSP
	; (no addr) RET

SaveFileNameNumFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), XDE
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR NZ, LABEL_F8C7FC
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD IZ, HL
	; (no addr) CP IZ, 0
	; (no addr) JR LT, LABEL_F8C7E6
	; (no addr) CALL LABEL_F892BC
	; (no addr) LD XBC, XHL
	; (no addr) LD DE, IZ
	; (no addr) INC 1, DE
	; (no addr) PUSHW 0006h
	; (no addr) PUSHW 0000h
	; (no addr) LD XWA, 00008850h
	; (no addr) CALL LABEL_F891DD
	; (no addr) JR T, LABEL_F8C7EB

LABEL_F8C7E6:
	; (no addr) LD (8850h), 000h

LABEL_F8C7EB:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00008850h
	; (no addr) CALL ApPostEvent

LABEL_F8C7FC:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) INC 4, XSP
	; (no addr) RET

SaveFileNameFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH XIZ
	; (no addr) LD (XSP + 004h), XDE
	; (no addr) CP XBC, 01e00086h
	; (no addr) JRL Z, LABEL_F8C8AD
	; (no addr) CP XBC, 01e0003ah
	; (no addr) JR Z, LABEL_F8C84A
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JRL NZ, LABEL_F8C8C2
	; (no addr) LDA XIZ, 8850h
	; (no addr) CALL LABEL_F892BC
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 00008850h
	; (no addr) CALL LABEL_F8929D
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00008850h
	; (no addr) JR T, LABEL_F8C8A7

LABEL_F8C84A:
	; (no addr) LDA XIZ, 8850h
	; (no addr) CALL LABEL_F892BC
	; (no addr) LD XBC, XHL
	; (no addr) LD XWA, XIZ
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD IY, 0
	; (no addr) LDA XIX, 0EED778h
	; (no addr) LDA XDE, 8850h
	; (no addr) LD XHL, XDE
	; (no addr) JR T, LABEL_F8C87A

LABEL_F8C869:
	; (no addr) EXTZ WA
	; (no addr) LD A, (XIX + WA)
	; (no addr) AND A, 007h
	; (no addr) JR NZ, LABEL_F8C878
	; (no addr) LD (XBC), 05fh

LABEL_F8C878:
	; (no addr) INC 1, IY

LABEL_F8C87A:
	; (no addr) CP IY, 6
	; (no addr) JR GE, LABEL_F8C889
	; (no addr) LDA XBC, XHL + IY
	; (no addr) LD A, (XBC)
	; (no addr) CP A, 0
	; (no addr) JR NZ, LABEL_F8C869

LABEL_F8C889:
	; (no addr) CP IY, 6
	; (no addr) JR GE, LABEL_F8C89B
	; (no addr) LD XWA, XDE

LABEL_F8C88F:
	; (no addr) LD (XWA + IY), 05fh
	; (no addr) INC 1, IY
	; (no addr) CP IY, 6
	; (no addr) JR LT, LABEL_F8C88F

LABEL_F8C89B:
	; (no addr) LD (XDE + 006h), 000h
	; (no addr) LD XWA, (XSP + 004h)
	; (no addr) LD XBC, 01e00086h

LABEL_F8C8A7:
	; (no addr) CALL ApPostEvent
	; (no addr) JR T, LABEL_F8C8C2

LABEL_F8C8AD:
	; (no addr) LD XWA, 00008850h
	; (no addr) LD XBC, (XSP + 004h)
	; (no addr) CALL LABEL_F890DC
	; (no addr) LD XWA, 00008850h
	; (no addr) CALL LABEL_F892C2

LABEL_F8C8C2:
	; (no addr) LD XHL, 0
	; (no addr) POP XIZ
	; (no addr) INC 4, XSP
	; (no addr) RET

CurFileNameFunc:
	; (no addr) DEC 4, XSP
	; (no addr) PUSH IZ
	; (no addr) LD (XSP + 002h), XDE
	; (no addr) CP XBC, 01c0000bh
	; (no addr) JR NZ, LABEL_F8C913
	; (no addr) CALL GetCurrentFileIndex
	; (no addr) LD IZ, HL
	; (no addr) CP IZ, 0
	; (no addr) JR LT, LABEL_F8C8FD
	; (no addr) LD WA, IZ
	; (no addr) CALL LABEL_F89623
	; (no addr) LD XBC, XHL
	; (no addr) LD DE, IZ
	; (no addr) INC 1, DE
	; (no addr) PUSHW 0006h
	; (no addr) PUSHW 0000h
	; (no addr) LD XWA, 00008870h
	; (no addr) CALL LABEL_F891DD
	; (no addr) JR T, LABEL_F8C902

LABEL_F8C8FD:
	; (no addr) LD (8870h), 000h

LABEL_F8C902:
	; (no addr) LD XWA, (XSP + 002h)
	; (no addr) LD XBC, 01c0000fh
	; (no addr) LD XDE, 00008870h
	; (no addr) CALL ApPostEvent

LABEL_F8C913:
	; (no addr) LD XHL, 0
	; (no addr) POP IZ
	; (no addr) INC 4, XSP
	; (no addr) RET

