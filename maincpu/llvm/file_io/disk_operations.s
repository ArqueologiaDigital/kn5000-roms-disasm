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
	push XIZ
	ld XIZ, XDE
	cp XBC, 0x1c00018
	jrl Z, LABEL_F8BC38
	cp XBC, 0x1c00017
	jrl Z, LABEL_F8BC38
	cp XBC, 0x1c0000b
	jr Z, LABEL_F8BC00
	cp XBC, 0x1e50004
	jrl NZ, LABEL_F8BE18
	ld (0x7F60), XIZ
	call GetCurrentFileIndex
	ld (0x7F64), HL
	cp HL, 0
	jr LT, LABEL_F8BBF1
	cp HL, 0x13
	jr GE, LABEL_F8BBE8
	inc 1, HL
	ld (0x7F66), HL
	jrl LABEL_F8BE18

LABEL_F8BBE8:
	dec 1, HL
	ld (0x7F66), HL
	jrl LABEL_F8BE18

LABEL_F8BBF1:
	ldw (0x7F64), 0x0
	ldw (0x7F66), 0x1
	jrl LABEL_F8BE18

LABEL_F8BC00:
	ld (0x850C), 0x0
	ld WA, (0x7F66)
	call LABEL_F89623
	ld XBC, XHL
	lda XWA, 0x850D
	ld DE, (0x7F66)
	inc 1, DE
	pushw 0x6
	pushw 0x0
	call LABEL_F891DD
	ld XWA, (0x7F60)
	ld XBC, 0x1c0000f
	ld XDE, 0x850c
	call ApPostEvent
	jrl LABEL_F8BE18

LABEL_F8BC38:
	or XIZ, XIZ
	jrl NZ, LABEL_F8BCD7
	ld WA, (0x7F66)
	ld DE, WA
	cp XBC, 0x1c00018
	jr NZ, LABEL_F8BCAB
	cp WA, 0
	jr LE, LABEL_F8BC55
	dec 1, WA
	ld (0x7F66), WA

LABEL_F8BC55:
	ld WA, (0x7F66)
	cp WA, (0x7F64)
	jr NZ, LABEL_F8BC6F
	cp WA, 0
	jr LE, LABEL_F8BC6B
	dec 1, WA
	ld (0x7F66), WA
	jr LABEL_F8BC73

LABEL_F8BC6B:
	ld (0x7F66), DE

LABEL_F8BC6F:
	ld WA, (0x7F66)

LABEL_F8BC73:
	cp WA, DE
	jrl Z, LABEL_F8BE18
	ld (0x850C), 0x0
	ld WA, (0x7F66)
	call LABEL_F89623
	ld XBC, XHL
	lda XWA, 0x850D
	ld DE, (0x7F66)
	inc 1, DE
	pushw 0x6
	pushw 0x0
	call LABEL_F891DD
	ld XWA, (0x7F60)
	ld XBC, 0x1c0000f
	ld XDE, 0x850c
	jr LABEL_F8BD19

LABEL_F8BCAB:
	cp XBC, 0x1c00017
	jr NZ, LABEL_F8BC6F
	cp WA, 0x13
	jr GE, LABEL_F8BCBF
	inc 1, WA
	ld (0x7F66), WA

LABEL_F8BCBF:
	ld WA, (0x7F66)
	cp WA, (0x7F64)
	jr NZ, LABEL_F8BC6F
	cp WA, 0x13
	jr GE, LABEL_F8BC6B
	inc 1, WA
	ld (0x7F66), WA
	jr LABEL_F8BC73

LABEL_F8BCD7:
	cp XIZ, 0x8
	jrl NZ, LABEL_F8BD97
	call CheckFileSystemStatus
	cp HL, 0
	jrl Z, LABEL_F8BD97
	ld WA, (0x7F66)
	call LABEL_F8945F
	cp HL, 0
	jr Z, LABEL_F8BD20
	cp (0x340EA), 0x0
	jr Z, LABEL_F8BD20
	ld XWA, 0xffffffff
	ld XBC, 0x1c50000
	ld XDE, 1
	call ApPostEvent
	ld XWA, 0x600037
	ld XBC, 0x1c00001
	ld XDE, 0

LABEL_F8BD19:
	call ApPostEvent
	jrl LABEL_F8BE18

LABEL_F8BD20:
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld WA, (0x7F66)
	call LABEL_F889D9
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
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 0x7b
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	jr LABEL_F8BE14

LABEL_F8BD97:
	cp XIZ, 0x32
	jr NZ, LABEL_F8BE18
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld WA, (0x7F66)
	call LABEL_F889D9
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
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 0x7b
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee

LABEL_F8BE14:
	call LABEL_F994BD

LABEL_F8BE18:
	ld XHL, 0
	pop XIZ
	ret

FileRenameFunc:
	dec 4, XSP
	push XIZ
	ld (XSP + 0x4), XDE
	cp XBC, 0x1e00086
	jrl Z, LABEL_F8BEB6
	cp XBC, 0x1e0003a
	jrl NZ, LABEL_F8BF15
	call GetCurrentFileIndex
	cp HL, 0
	jr LT, LABEL_F8BE95
	lda XIZ, 0x8870
	ld WA, HL
	call LABEL_F89623
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld IY, 0
	lda XIX, 0xEED778
	lda XWA, 0x8870
	ld XHL, XWA
	jr LABEL_F8BE6E

LABEL_F8BE5D:
	extz BC
	ld C, (XIX + BC)
	and C, 0x7
	jr NZ, LABEL_F8BE6C
	ld (XDE), 0x5f

LABEL_F8BE6C:
	inc 1, IY

LABEL_F8BE6E:
	cp IY, 6
	jr GE, LABEL_F8BE7D
	lda XDE, XHL + IY
	ld C, (XDE)
	cp C, 0
	jr NZ, LABEL_F8BE5D

LABEL_F8BE7D:
	cp IY, 6
	jr GE, LABEL_F8BE8F
	ld XBC, XWA

LABEL_F8BE83:
	ld (XBC + IY), 0x5f
	inc 1, IY
	cp IY, 6
	jr LT, LABEL_F8BE83

LABEL_F8BE8F:
	ld (XWA + 0x6), 0x0
	jr LABEL_F8BEA3

LABEL_F8BE95:
	ld XWA, 0x8870
	ld XBC, 0xea06be
	call LABEL_F890DC

LABEL_F8BEA3:
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1e00086
	ld XDE, 0x8870
	call ApPostEvent
	jr LABEL_F8BF15

LABEL_F8BEB6:
	call CheckFileSystemStatus
	cp HL, 0
	jr Z, LABEL_F8BF15
	ld XWA, 0x8870
	ld XBC, (XSP + 0x4)
	call LABEL_F890DC
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld XWA, 0x8870
	call LABEL_F8879E
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
	call LABEL_F994BD

LABEL_F8BF15:
	ld XHL, 0
	pop XIZ
	inc 4, XSP
	ret

FileRenameSmfFunc:
	dec 4, XSP
	push XIZ
	ld (XSP + 0x4), XDE
	cp XBC, 0x1e00086
	jrl Z, LABEL_F8BFBB
	cp XBC, 0x1e0003a
	jrl NZ, LABEL_F8C020
	call LABEL_F89AC7
	cp HL, 0
	jr LT, LABEL_F8BF9A
	lda XIZ, 0x8870
	ld WA, HL
	call LABEL_F89BF0
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld IY, 0
	lda XIX, 0xEED778
	lda XWA, 0x8870
	ld XHL, XWA
	jr LABEL_F8BF6D

LABEL_F8BF5C:
	extz BC
	ld C, (XIX + BC)
	and C, 0x7
	jr NZ, LABEL_F8BF6B
	ld (XDE), 0x5f

LABEL_F8BF6B:
	inc 1, IY

LABEL_F8BF6D:
	cp IY, 0x8
	jr GE, LABEL_F8BF7E
	lda XDE, XHL + IY
	ld C, (XDE)
	cp C, 0
	jr NZ, LABEL_F8BF5C

LABEL_F8BF7E:
	cp IY, 0x8
	jr GE, LABEL_F8BF94
	ld XBC, XWA

LABEL_F8BF86:
	ld (XBC + IY), 0x5f
	inc 1, IY
	cp IY, 0x8
	jr LT, LABEL_F8BF86

LABEL_F8BF94:
	ld (XWA + 0x8), 0x0
	jr LABEL_F8BFA8

LABEL_F8BF9A:
	ld XWA, 0x8870
	ld XBC, 0xea06c6
	call LABEL_F890DC

LABEL_F8BFA8:
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1e00086
	ld XDE, 0x8870
	call ApPostEvent
	jr LABEL_F8C020

LABEL_F8BFBB:
	ld XWA, 0x8870
	ld XBC, (XSP + 0x4)
	call LABEL_F890DC
	ld XWA, 0x8870
	ld XBC, 0xea06d0
	call LABEL_F89113
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld XWA, 0x8870
	call LABEL_F88B3A
	ld WA, HL
	ld BC, 5
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	call GetFileCountEncoded
	ld (0x8504), HL
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	call LABEL_F994BD

LABEL_F8C020:
	ld XHL, 0
	pop XIZ
	inc 4, XSP
	ret

FmmFormatFunc:
	push IZ
	cp XBC, 0x1c00007
	jrl Z, LABEL_F8C0BE
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8C20A
	cp XDE, 0x3
	jr Z, LABEL_F8C0AE
	cp XDE, 0x2
	jrl NZ, LABEL_F8C20A
	ld WA, 1
	CALR InitializeOperationState
	LD_8_8 0x7F6A, 0x8D37
	cpw (0x8500), 0x0
	jr GE, LABEL_F8C06A
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8C06A:
	ld WA, (0x8500)
	cp WA, 2
	jr Z, LABEL_F8C076
	cp WA, 3
	jr NZ, LABEL_F8C091

LABEL_F8C076:
	ld (0x7F68), A
	ld XWA, 0x7b0036
	ld XBC, 0x1c00001
	ld XDE, 0
	call ApPostEvent
	ld (0x84FE), 0x0
	jr LABEL_F8C0A6

LABEL_F8C091:
	ld XWA, 0x7b003f
	ld XBC, 0x1c00001
	ld XDE, 0
	call ApPostEvent
	ld (0x84FE), 0x2

LABEL_F8C0A6:
	ld (0x7F6C), 0x1
	jrl LABEL_F8C20A

LABEL_F8C0AE:
	CALR CancelOperationCleanup
	ld (0x84FE), 0x0
	ld (0x7F6C), 0x0
	jrl LABEL_F8C20A

LABEL_F8C0BE:
	cp (0x7F6C), 0x0
	jrl Z, LABEL_F8C20A
	ld A, (0x7F6A)
	extz WA
	cp XDE, 0xf
	jrl Z, LABEL_F8C1FC
	ld C, (0x84FE)
	cp XDE, 0xb
	jrl Z, LABEL_F8C1C0
	cp XDE, 0xa
	jrl NZ, LABEL_F8C20A
	ld A, C
	cp C, 0
	jrl NZ, LABEL_F8C199
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	ld A, (0x7F68)
	extz WA
	call LABEL_F89091
	ld IZ, HL
	CALR SignalProgressUpdate
	CALR ResetProgressIndication
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	cp IZ, 0
	jr GE, LABEL_F8C172
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F6A)
	extz WA
	call UI_PostModeChangeEvent
	ld (0x7F6C), 0x0
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, IZ
	ld BC, 0x8
	CALR LABEL_F8B48E
	ld (0x7F42), L
	ld WA, 0xee
	call LABEL_F994BD
	jrl LABEL_F8C205

LABEL_F8C172:
	ld XWA, 0x7b0036
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0x7b0031
	ld XBC, 0x1c00001
	ld XDE, 0
	call ApPostEvent
	ld (0x84FE), 0x1
	jr LABEL_F8C20A

LABEL_F8C199:
	cp A, 2
	jr NZ, LABEL_F8C20A
	ld (0x7F68), 0x3
	ld XWA, 0x7b003f
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0x7b0036
	ld XBC, 0x1c00001
	ld XDE, 0
	jr LABEL_F8C1F6

LABEL_F8C1C0:
	ld E, C
	cp C, 0
	jr NZ, LABEL_F8C1D1
	call UI_PostModeChangeEvent
	ld (0x7F6C), 0x0
	jr LABEL_F8C20A

LABEL_F8C1D1:
	cp E, 2
	jr NZ, LABEL_F8C20A
	ld (0x7F68), 0x2
	ld XWA, 0x7b003f
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0x7b0036
	ld XBC, 0x1c00001
	ld XDE, 0

LABEL_F8C1F6:
	call ApPostEvent
	jr LABEL_F8C205

LABEL_F8C1FC:
	call UI_PostModeChangeEvent
	ld (0x7F6C), 0x0

LABEL_F8C205:
	ld (0x84FE), 0x0

LABEL_F8C20A:
	ld XHL, 0
	pop IZ
	ret

UtilityTtlJgFunc:
	cp XBC, 0x1c00007
	jr NZ, LABEL_F8C21F
	ld WA, 0x7b
	ld BC, 0x7c
	CALR LABEL_F8B36E

LABEL_F8C21F:
	ld XHL, 0
	ret

FmmLoadTitleFunc:
	push IZ
	cp XBC, 0x1c00007
	jrl Z, LABEL_F8C435
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8C450
	cp XDE, 0x3
	jrl Z, LABEL_F8C420
	cp XDE, 0x9
	jrl Z, LABEL_F8C3FE
	cp XDE, 0x2
	jrl NZ, LABEL_F8C450
	ld (0x84FE), 0x0
	LDW_16_16 0x7F70, 0x8500
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	LD_8_8 0x7F6E, 0x8D37
	cpw (0x8500), 0x0
	jr GE, LABEL_F8C28B
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8C28B:
	ld WA, (0x8500)
	cp WA, 1
	jrl Z, LABEL_F8C355
	cp WA, 0
	jrl Z, LABEL_F8C33F
	cp WA, 5
	jr Z, LABEL_F8C2FB
	cpw (0x8502), 0x0
	jr GE, LABEL_F8C2B8
	call GetEncodedFileSizeData
	ld (0x8502), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8C2B8:
	cpw (0x8502), 0x0
	jrl NZ, LABEL_F8C3A1
	cpw (0x8504), 0x0
	jr GE, LABEL_F8C2D4
	call GetFileCountEncoded
	ld (0x8504), HL
	CALR SignalProgressUpdate

LABEL_F8C2D4:
	cpw (0x8504), 0x0
	jrl LE, LABEL_F8C3A1
	cp (0x7F6E), 0x64
	jrl Z, LABEL_F8C3A1
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x64
	jrl LABEL_F8C44C

LABEL_F8C2FB:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F6E)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x0
	ld WA, 0xee
	jr LABEL_F8C39A

LABEL_F8C33F:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x7d
	jrl LABEL_F8C44C

LABEL_F8C355:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	CALR ResetProgressIndication
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld A, (0x7F6E)
	extz WA
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x2
	ld WA, 0xee

LABEL_F8C39A:
	call LABEL_F994BD
	jrl LABEL_F8C450

LABEL_F8C3A1:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	call ApPostEvent
	ld (0x89FC), 0x0
	ld (0x89FE), 0x0
	ld (0x8A00), 0x0
	ld (0x8A02), 0x0
	ld (0x8A04), 0x0
	ld (0x8A06), 0x0
	ld (0x8A08), 0x0
	ld IZ, 0

LABEL_F8C3E6:
	ld A, IZL
	extz WA
	call LABEL_F89321
	inc 1, IZ
	cp IZ, 0x8
	jr LT, LABEL_F8C3E6
	ld (0x89F8), 0x4
	jr LABEL_F8C450

LABEL_F8C3FE:
	cpw (0x7F70), 0x0
	jr LT, LABEL_F8C450
	call GetCurrentFileIndex
	ld IZ, HL
	cp IZ, 0
	jr LT, LABEL_F8C450
	cp IZ, 0x13
	jr GE, LABEL_F8C450
	ld WA, IZ
	inc 1, WA
	call NotifyUIOfSelectionChange
	jr LABEL_F8C450

LABEL_F8C420:
	CALR CancelOperationCleanup
	ld XWA, 0x610001
	ld XBC, 0x1e0007f
	ld XDE, 1
	call ApPostEvent
	jr LABEL_F8C450

LABEL_F8C435:
	cp XDE, 0xf
	jr NZ, LABEL_F8C450
	cp (0x8D34), 0x7
	jr NZ, LABEL_F8C449
	ld WA, 0xd6
	jr LABEL_F8C44C

LABEL_F8C449:
	ld WA, 0x60

LABEL_F8C44C:
	call UI_PostModeChangeEvent

LABEL_F8C450:
	ld XHL, 0
	pop IZ
	ret

FmmSaveTitleFunc:
	push IZ
	cp XBC, 0x1c00007
	jrl Z, LABEL_F8C515
	cp XBC, 0x1c00013
	jrl NZ, LABEL_F8C524
	cp XDE, 0x3
	jrl Z, LABEL_F8C500
	cp XDE, 0x2
	jrl NZ, LABEL_F8C524
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	cpw (0x8502), 0x0
	jr GE, LABEL_F8C4AE
	call GetEncodedFileSizeData
	ld (0x8502), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8C4AE:
	cp (0x8D37), 0x66
	jr Z, LABEL_F8C4E2
	ld IZ, 0

LABEL_F8C4B7:
	ld A, IZL
	extz WA
	call LABEL_F8937F
	inc 1, IZ
	cp IZ, 6
	jr LT, LABEL_F8C4B7
	ld WA, 6
	call LABEL_F89393
	ld WA, 7
	call LABEL_F89393
	call LABEL_F893CA
	ld XIY, 0xea066a
	ld XIX, 0x8a0c
	LDIW

LABEL_F8C4E2:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	jr LABEL_F8C50F

LABEL_F8C500:
	CALR CancelOperationCleanup
	ld XWA, 0x670001
	ld XBC, 0x1e0007f
	ld XDE, 1

LABEL_F8C50F:
	call ApPostEvent
	jr LABEL_F8C524

LABEL_F8C515:
	cp XDE, 0xf
	jr NZ, LABEL_F8C524
	ld WA, 0x60
	call UI_PostModeChangeEvent

LABEL_F8C524:
	ld XHL, 0
	pop IZ
	ret

DiskNameFunc:
	dec 4, XSP
	push XIZ
	ld (XSP + 0x4), XDE
	cp XBC, 0x1e00086
	jrl Z, LABEL_F8C5E2
	cp XBC, 0x1e0003a
	jr Z, LABEL_F8C56C
	cp XBC, 0x1c0000b
	jrl NZ, LABEL_F8C609
	ld WA, 0
	CALR InitializeOperationState
	lda XIZ, 0x878C
	call LABEL_F8958D
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c0000f
	ld XDE, 0x878c
	jr LABEL_F8C5DC

LABEL_F8C56C:
	ld WA, 0
	CALR InitializeOperationState
	lda XIZ, 0x878C
	call LABEL_F8958D
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld IY, 0
	lda XIX, 0x8870
	lda XIZ, 0xEED778
	lda XDE, 0x878C
	ld XHL, XDE
	jr LABEL_F8C5AA

LABEL_F8C594:
	ld A, (XIX + IY)
	extz WA
	ld A, (XIZ + WA)
	and A, 0x7
	jr NZ, LABEL_F8C5A8
	ld (XBC), 0x5f

LABEL_F8C5A8:
	inc 1, IY

LABEL_F8C5AA:
	cp IY, 0xb
	jr GE, LABEL_F8C5BA
	lda XBC, XHL + IY
	cp (XBC), 0x0
	jr NZ, LABEL_F8C594

LABEL_F8C5BA:
	cp IY, 0xb
	jr GE, LABEL_F8C5D0
	ld XWA, XDE

LABEL_F8C5C2:
	ld (XWA + IY), 0x5f
	inc 1, IY
	cp IY, 0xb
	jr LT, LABEL_F8C5C2

LABEL_F8C5D0:
	ld (XDE + 0xb), 0x0
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1e00086

LABEL_F8C5DC:
	call ApPostEvent
	jr LABEL_F8C609

LABEL_F8C5E2:
	ld XWA, 0x878c
	ld XBC, (XSP + 0x4)
	call LABEL_F890DC
	ld WA, 0
	CALR InitializeOperationState
	ld XWA, 0x878c
	call LABEL_F5289C
	CALR SignalProgressUpdate
	CALR ResetProgressIndication
	ld WA, 0x60
	call UI_PostModeChangeEvent

LABEL_F8C609:
	ld XHL, 0
	pop XIZ
	inc 4, XSP
	ret

DiskInfoFunc:
	lda XSP, XSP - 0x10
	push XIZ
	ld (XSP + 0x10), XDE
	cp XBC, 0x1c0000b
	jrl NZ, LABEL_F8C735
	ld WA, 0
	CALR InitializeOperationState
	cpw (0x8500), 0x0
	jr GE, LABEL_F8C636
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL

LABEL_F8C636:
	ld WA, (0x8500)
	cp WA, 1
	jr Z, LABEL_F8C65A
	cp WA, 0
	jr Z, LABEL_F8C65A
	cp WA, 2
	jr Z, LABEL_F8C64A
	cp WA, 3
	jr NZ, LABEL_F8C65D

LABEL_F8C64A:
	call GetEncodedFreeSpaceData
	ld (XSP + 0x4), XHL
	call LABEL_F89573
	ld (XSP + 0xc), XHL
	jr LABEL_F8C665

LABEL_F8C65A:
	CALR ResetProgressIndication

LABEL_F8C65D:
	ld XWA, 0
	ld (XSP + 0xc), XWA
	ld (XSP + 0x4), XWA

LABEL_F8C665:
	ld XWA, (XSP + 0xc)
	cp XWA, 0x0
	jr LE, LABEL_F8C68F
	ld XWA, (XSP + 0xc)
	sub XWA, (XSP + 0x4)
	ld XBC, 0x64
	call LABEL_FF0A5C
	ld XIZ, XHL
	ld XBC, (XSP + 0xc)
	ld XWA, XIZ
	call LABEL_FF0C0E
	ld (XSP + 0x8), XHL
	jr LABEL_F8C694

LABEL_F8C68F:
	ld XWA, 0
	ld (XSP + 0x8), XWA

LABEL_F8C694:
	ld XWA, (XSP + 0x4)
	ld XBC, XWA
	sra XBC, 15
	SRA_0_XBC
	and XBC, 0x3ff
	add XBC, XWA
	ld (XSP + 0x4), XBC
	sra XBC, 10
	ld (XSP + 0x4), XBC
	ld WA, (0x8500)
	sla WA, 0x2
	lda XBC, 0xEA0558
	ld XBC, (XBC + WA)
	ld XWA, 0x87ce
	call LABEL_F890DC
	ld XWA, 0x87ce
	ld XBC, 0xea06d6
	call LABEL_F89113
	lda XWA, 0x87CE
	ld (XSP + 0xc), XWA
	ld XWA, (XSP + 0x4)
	ld BC, 4
	CALR LABEL_F8B67F
	ld XBC, XHL
	ld XWA, (XSP + 0xc)
	call LABEL_F89113
	ld XWA, 0x87ce
	ld XBC, 0xea06da
	call LABEL_F89113
	lda XWA, 0x87CE
	ld (XSP + 0xc), XWA
	ld XWA, (XSP + 0x8)
	ld BC, 3
	CALR LABEL_F8B67F
	ld XBC, XHL
	ld XWA, (XSP + 0xc)
	call LABEL_F89113
	ld XWA, 0x87ce
	ld XBC, 0xea06e4
	call LABEL_F89113
	ld XWA, (XSP + 0x10)
	ld XBC, 0x1c0000f
	ld XDE, 0x87ce
	call ApPostEvent

LABEL_F8C735:
	ld XHL, 0
	pop XIZ
	lda XSP, XSP + 0x10
	ret

SongNameFunc:
	dec 8, XSP
	push IZ
	ld (XSP + 0x6), XDE
	cp XBC, 0x1c0000b
	jr NZ, LABEL_F8C7AD
	call LABEL_F89AC7
	ld IZ, HL
	cp IZ, 0
	jr LT, LABEL_F8C797
	ld WA, 0
	CALR InitializeOperationState
	lda XWA, 0x880E
	ld (XSP + 0x2), XWA
	ld WA, IZ
	call LABEL_F8A07F
	ld XBC, XHL
	ld XWA, (XSP + 0x2)
	call LABEL_F890DC
	lda XWA, 0x880E
	ld (XWA + 0x1e), 0x0
	lda XBC, XWA + 0x1d
	ld XDE, XBC
	lda XHL, XBC - 0x1d
	jr LABEL_F8C786

LABEL_F8C781:
	ld (XDE), 0x0
	dec 1, XDE

LABEL_F8C786:
	ld C, (XDE)
	cp C, 0x20
	jr NZ, LABEL_F8C791
	cp XDE, XHL
	jr UGT, LABEL_F8C781

LABEL_F8C791:
	call LABEL_F8929D
	jr LABEL_F8C79C

LABEL_F8C797:
	ld (0x880E), 0x0

LABEL_F8C79C:
	ld XWA, (XSP + 0x6)
	ld XBC, 0x1c0000f
	ld XDE, 0x880e
	call ApPostEvent

LABEL_F8C7AD:
	ld XHL, 0
	pop IZ
	inc 8, XSP
	ret

SaveFileNameNumFunc:
	dec 4, XSP
	push IZ
	ld (XSP + 0x2), XDE
	cp XBC, 0x1c0000b
	jr NZ, LABEL_F8C7FC
	call GetCurrentFileIndex
	ld IZ, HL
	cp IZ, 0
	jr LT, LABEL_F8C7E6
	call LABEL_F892BC
	ld XBC, XHL
	ld DE, IZ
	inc 1, DE
	pushw 0x6
	pushw 0x0
	ld XWA, 0x8850
	call LABEL_F891DD
	jr LABEL_F8C7EB

LABEL_F8C7E6:
	ld (0x8850), 0x0

LABEL_F8C7EB:
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1c0000f
	ld XDE, 0x8850
	call ApPostEvent

LABEL_F8C7FC:
	ld XHL, 0
	pop IZ
	inc 4, XSP
	ret

SaveFileNameFunc:
	dec 4, XSP
	push XIZ
	ld (XSP + 0x4), XDE
	cp XBC, 0x1e00086
	jrl Z, LABEL_F8C8AD
	cp XBC, 0x1e0003a
	jr Z, LABEL_F8C84A
	cp XBC, 0x1c0000b
	jrl NZ, LABEL_F8C8C2
	lda XIZ, 0x8850
	call LABEL_F892BC
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld XWA, 0x8850
	call LABEL_F8929D
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1c0000f
	ld XDE, 0x8850
	jr LABEL_F8C8A7

LABEL_F8C84A:
	lda XIZ, 0x8850
	call LABEL_F892BC
	ld XBC, XHL
	ld XWA, XIZ
	call LABEL_F890DC
	ld IY, 0
	lda XIX, 0xEED778
	lda XDE, 0x8850
	ld XHL, XDE
	jr LABEL_F8C87A

LABEL_F8C869:
	extz WA
	ld A, (XIX + WA)
	and A, 0x7
	jr NZ, LABEL_F8C878
	ld (XBC), 0x5f

LABEL_F8C878:
	inc 1, IY

LABEL_F8C87A:
	cp IY, 6
	jr GE, LABEL_F8C889
	lda XBC, XHL + IY
	ld A, (XBC)
	cp A, 0
	jr NZ, LABEL_F8C869

LABEL_F8C889:
	cp IY, 6
	jr GE, LABEL_F8C89B
	ld XWA, XDE

LABEL_F8C88F:
	ld (XWA + IY), 0x5f
	inc 1, IY
	cp IY, 6
	jr LT, LABEL_F8C88F

LABEL_F8C89B:
	ld (XDE + 0x6), 0x0
	ld XWA, (XSP + 0x4)
	ld XBC, 0x1e00086

LABEL_F8C8A7:
	call ApPostEvent
	jr LABEL_F8C8C2

LABEL_F8C8AD:
	ld XWA, 0x8850
	ld XBC, (XSP + 0x4)
	call LABEL_F890DC
	ld XWA, 0x8850
	call LABEL_F892C2

LABEL_F8C8C2:
	ld XHL, 0
	pop XIZ
	inc 4, XSP
	ret

CurFileNameFunc:
	dec 4, XSP
	push IZ
	ld (XSP + 0x2), XDE
	cp XBC, 0x1c0000b
	jr NZ, LABEL_F8C913
	call GetCurrentFileIndex
	ld IZ, HL
	cp IZ, 0
	jr LT, LABEL_F8C8FD
	ld WA, IZ
	call LABEL_F89623
	ld XBC, XHL
	ld DE, IZ
	inc 1, DE
	pushw 0x6
	pushw 0x0
	ld XWA, 0x8870
	call LABEL_F891DD
	jr LABEL_F8C902

LABEL_F8C8FD:
	ld (0x8870), 0x0

LABEL_F8C902:
	ld XWA, (XSP + 0x2)
	ld XBC, 0x1c0000f
	ld XDE, 0x8870
	call ApPostEvent

LABEL_F8C913:
	ld XHL, 0
	pop IZ
	inc 4, XSP
	ret

