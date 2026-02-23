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
	push xiz
	ld xiz, xde
	cp xbc, 0x1C00018
	jrl z, LABEL_F8BC38
	cp xbc, 0x1C00017
	jrl z, LABEL_F8BC38
	cp xbc, 0x1C0000B
	jr z, LABEL_F8BC00
	cp xbc, 0x1E50004
	jrl nz, LABEL_F8BE18
	stda32 32608, xiz
	call 0xF895EF
	stda16 32612, xhl
	cps hl, 0
	jr lt, LABEL_F8BBF1
	cp hl, 0x13
	jr ge, LABEL_F8BBE8
	inc 1, hl
	stda16 32614, xhl
	jrl LABEL_F8BE18

LABEL_F8BBE8:
	dec 1, hl
	stda16 32614, xhl
	jrl LABEL_F8BE18

LABEL_F8BBF1:
	stdi16 32612, 0
	stdi16 32614, 1
	jrl LABEL_F8BE18

LABEL_F8BC00:
	stdi8 34060, 0
	ldda16 xwa, 32614
	call LABEL_F89623
	ld xbc, xhl
	ldada xwa, 34061
	ldda16 xde, 32614
	inc 1, de
	pushw 0x6
	pushw 0x0
	call LABEL_F891DD
	ldda32 xwa, 32608
	ld xbc, 0x1C0000F
	ld xde, 0x850C
	call 0xFA9D58
	jrl LABEL_F8BE18

LABEL_F8BC38:
	or xiz, xiz
	jrl nz, LABEL_F8BCD7
	ldda16 xwa, 32614
	ld de, wa
	cp xbc, 0x1C00018
	jr nz, LABEL_F8BCAB
	cps wa, 0
	jr le, LABEL_F8BC55
	dec 1, wa
	stda16 32614, xwa

LABEL_F8BC55:
	ldda16 xwa, 32614
	cpda16 xwa, 32612
	jr nz, LABEL_F8BC6F
	cps wa, 0
	jr le, LABEL_F8BC6B
	dec 1, wa
	stda16 32614, xwa
	jr LABEL_F8BC73

LABEL_F8BC6B:
	stda16 32614, xde

LABEL_F8BC6F:
	ldda16 xwa, 32614

LABEL_F8BC73:
	cp wa, de
	jrl z, LABEL_F8BE18
	stdi8 34060, 0
	ldda16 xwa, 32614
	call LABEL_F89623
	ld xbc, xhl
	ldada xwa, 34061
	ldda16 xde, 32614
	inc 1, de
	pushw 0x6
	pushw 0x0
	call LABEL_F891DD
	ldda32 xwa, 32608
	ld xbc, 0x1C0000F
	ld xde, 0x850C
	jr LABEL_F8BD19

LABEL_F8BCAB:
	cp xbc, 0x1C00017
	jr nz, LABEL_F8BC6F
	cp wa, 0x13
	jr ge, LABEL_F8BCBF
	inc 1, wa
	stda16 32614, xwa

LABEL_F8BCBF:
	ldda16 xwa, 32614
	cpda16 xwa, 32612
	jr nz, LABEL_F8BC6F
	cp wa, 0x13
	jr ge, LABEL_F8BC6B
	inc 1, wa
	stda16 32614, xwa
	jr LABEL_F8BC73

LABEL_F8BCD7:
	cp xiz, 0x8
	jrl nz, LABEL_F8BD97
	call 0xF8943E
	cps hl, 0
	jrl z, LABEL_F8BD97
	ldda16 xwa, 32614
	call LABEL_F8945F
	cps hl, 0
	jr z, LABEL_F8BD20
	cpdi8_24 213226, 0
	jr z, LABEL_F8BD20
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0

LABEL_F8BD19:
	call 0xFA9D58
	jrl LABEL_F8BE18

LABEL_F8BD20:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 32614
	call LABEL_F889D9
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x7B
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jr LABEL_F8BE14

LABEL_F8BD97:
	cp xiz, 0x32
	jr nz, LABEL_F8BE18
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 32614
	call LABEL_F889D9
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x7B
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE

LABEL_F8BE14:
	call LABEL_F994BD

LABEL_F8BE18:
	lds32 xhl, 0
	pop xiz
	ret

FileRenameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, LABEL_F8BEB6
	cp xbc, 0x1E0003A
	jrl nz, LABEL_F8BF15
	call 0xF895EF
	cps hl, 0
	jr lt, LABEL_F8BE95
	ldada xiz, 34928
	ld wa, hl
	call LABEL_F89623
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	ldada_24 xix, 15652728
	ldada xwa, 34928
	ld xhl, xwa
	jr LABEL_F8BE6E

LABEL_F8BE5D:
	extz bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	and c, 0x7
	jr nz, LABEL_F8BE6C
	ldmi8 (xde), 0x5F

LABEL_F8BE6C:
	inc 1, iy

LABEL_F8BE6E:
	cps iy, 6
	jr ge, LABEL_F8BE7D
	st_dri3b B, 0x07, 0xEC, 0xF4
	ld c, (xde)
	cps c, 0
	jr nz, LABEL_F8BE5D

LABEL_F8BE7D:
	cps iy, 6
	jr ge, LABEL_F8BE8F
	ld xbc, xwa

LABEL_F8BE83:
	x_dri5_o00_t1 0x07, 0xE4, 0xF4, 0x5F
	inc 1, iy
	cps iy, 6
	jr lt, LABEL_F8BE83

LABEL_F8BE8F:
	ldmi8 (xwa + 6), 0x0
	jr LABEL_F8BEA3

LABEL_F8BE95:
	ld xwa, 0x8870
	ld xbc, 0xEA06BE
	call LABEL_F890DC

LABEL_F8BEA3:
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086
	ld xde, 0x8870
	call 0xFA9D58
	jr LABEL_F8BF15

LABEL_F8BEB6:
	call 0xF8943E
	cps hl, 0
	jr z, LABEL_F8BF15
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x8870
	call LABEL_F8879E
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

LABEL_F8BF15:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FileRenameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, LABEL_F8BFBB
	cp xbc, 0x1E0003A
	jrl nz, LABEL_F8C020
	call LABEL_F89AC7
	cps hl, 0
	jr lt, LABEL_F8BF9A
	ldada xiz, 34928
	ld wa, hl
	call LABEL_F89BF0
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	ldada_24 xix, 15652728
	ldada xwa, 34928
	ld xhl, xwa
	jr LABEL_F8BF6D

LABEL_F8BF5C:
	extz bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	and c, 0x7
	jr nz, LABEL_F8BF6B
	ldmi8 (xde), 0x5F

LABEL_F8BF6B:
	inc 1, iy

LABEL_F8BF6D:
	cp iy, 0x8
	jr ge, LABEL_F8BF7E
	st_dri3b B, 0x07, 0xEC, 0xF4
	ld c, (xde)
	cps c, 0
	jr nz, LABEL_F8BF5C

LABEL_F8BF7E:
	cp iy, 0x8
	jr ge, LABEL_F8BF94
	ld xbc, xwa

LABEL_F8BF86:
	x_dri5_o00_t1 0x07, 0xE4, 0xF4, 0x5F
	inc 1, iy
	cp iy, 0x8
	jr lt, LABEL_F8BF86

LABEL_F8BF94:
	ldmi8 (xwa + 8), 0x0
	jr LABEL_F8BFA8

LABEL_F8BF9A:
	ld xwa, 0x8870
	ld xbc, 0xEA06C6
	call LABEL_F890DC

LABEL_F8BFA8:
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086
	ld xde, 0x8870
	call 0xFA9D58
	jr LABEL_F8C020

LABEL_F8BFBB:
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	ld xwa, 0x8870
	ld xbc, 0xEA06D0
	call LABEL_F89113
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x8870
	call LABEL_F88B3A
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call 0xF89C78
	stda16 34052, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

LABEL_F8C020:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmFormatFunc:
	pushw iz
	cp xbc, 0x1C00007
	jrl z, LABEL_F8C0BE
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8C20A
	cp xde, 0x3
	jr z, LABEL_F8C0AE
	cp xde, 0x2
	jrl nz, LABEL_F8C20A
	lds wa, 1
	calr InitializeOperationState
	ldmm8 32618, 36151
	cpdi16 34048, 0
	jr ge, LABEL_F8C06A
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8C06A:
	ldda16 xwa, 34048
	cps wa, 2
	jr z, LABEL_F8C076
	cps wa, 3
	jr nz, LABEL_F8C091

LABEL_F8C076:
	stda8 32616, a
	ld xwa, 0x7B0036
	ld xbc, 0x1C00001
	lds32 xde, 0
	call 0xFA9D58
	stdi8 34046, 0
	jr LABEL_F8C0A6

LABEL_F8C091:
	ld xwa, 0x7B003F
	ld xbc, 0x1C00001
	lds32 xde, 0
	call 0xFA9D58
	stdi8 34046, 2

LABEL_F8C0A6:
	stdi8 32620, 1
	jrl LABEL_F8C20A

LABEL_F8C0AE:
	calr CancelOperationCleanup
	stdi8 34046, 0
	stdi8 32620, 0
	jrl LABEL_F8C20A

LABEL_F8C0BE:
	cpdi8 32620, 0
	jrl z, LABEL_F8C20A
	ldda8 a, 32618
	extz wa
	cp xde, 0xF
	jrl z, LABEL_F8C1FC
	ldda8 c, 34046
	cp xde, 0xB
	jrl z, LABEL_F8C1C0
	cp xde, 0xA
	jrl nz, LABEL_F8C20A
	ld a, c
	cps c, 0
	jrl nz, LABEL_F8C199
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 32616
	extz wa
	call LABEL_F89091
	ld iz, hl
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	cps iz, 0
	jr ge, LABEL_F8C172
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32618
	extz wa
	call 0xF99490
	stdi8 32620, 0
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ld wa, iz
	ldw bc, 0x8
	calr LABEL_F8B48E
	stda8 32578, l
	ldw wa, 0xEE
	call LABEL_F994BD
	jrl LABEL_F8C205

LABEL_F8C172:
	ld xwa, 0x7B0036
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0x7B0031
	ld xbc, 0x1C00001
	lds32 xde, 0
	call 0xFA9D58
	stdi8 34046, 1
	jr LABEL_F8C20A

LABEL_F8C199:
	cps a, 2
	jr nz, LABEL_F8C20A
	stdi8 32616, 3
	ld xwa, 0x7B003F
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0x7B0036
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr LABEL_F8C1F6

LABEL_F8C1C0:
	ld e, c
	cps c, 0
	jr nz, LABEL_F8C1D1
	call 0xF99490
	stdi8 32620, 0
	jr LABEL_F8C20A

LABEL_F8C1D1:
	cps e, 2
	jr nz, LABEL_F8C20A
	stdi8 32616, 2
	ld xwa, 0x7B003F
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0x7B0036
	ld xbc, 0x1C00001
	lds32 xde, 0

LABEL_F8C1F6:
	call 0xFA9D58
	jr LABEL_F8C205

LABEL_F8C1FC:
	call 0xF99490
	stdi8 32620, 0

LABEL_F8C205:
	stdi8 34046, 0

LABEL_F8C20A:
	lds32 xhl, 0
	popw iz
	ret

UtilityTtlJgFunc:
	cp xbc, 0x1C00007
	jr nz, LABEL_F8C21F
	ldw wa, 0x7B
	ldw bc, 0x7C
	calr LABEL_F8B36E

LABEL_F8C21F:
	lds32 xhl, 0
	ret

FmmLoadTitleFunc:
	pushw iz
	cp xbc, 0x1C00007
	jrl z, LABEL_F8C435
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8C450
	cp xde, 0x3
	jrl z, LABEL_F8C420
	cp xde, 0x9
	jrl z, LABEL_F8C3FE
	cp xde, 0x2
	jrl nz, LABEL_F8C450
	stdi8 34046, 0
	ldmm16 32624, 34048
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	ldmm8 32622, 36151
	cpdi16 34048, 0
	jr ge, LABEL_F8C28B
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8C28B:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, LABEL_F8C355
	cps wa, 0
	jrl z, LABEL_F8C33F
	cps wa, 5
	jr z, LABEL_F8C2FB
	cpdi16 34050, 0
	jr ge, LABEL_F8C2B8
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8C2B8:
	cpdi16 34050, 0
	jrl nz, LABEL_F8C3A1
	cpdi16 34052, 0
	jr ge, LABEL_F8C2D4
	call 0xF89C78
	stda16 34052, xhl
	calr SignalProgressUpdate

LABEL_F8C2D4:
	cpdi16 34052, 0
	jrl le, LABEL_F8C3A1
	cpdi8 32622, 100
	jrl z, LABEL_F8C3A1
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x64
	jrl LABEL_F8C44C

LABEL_F8C2FB:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32622
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8C39A

LABEL_F8C33F:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	jrl LABEL_F8C44C

LABEL_F8C355:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	calr ResetProgressIndication
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32622
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8C39A:
	call LABEL_F994BD
	jrl LABEL_F8C450

LABEL_F8C3A1:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	stdi8 35324, 0
	stdi8 35326, 0
	stdi8 35328, 0
	stdi8 35330, 0
	stdi8 35332, 0
	stdi8 35334, 0
	stdi8 35336, 0
	lds iz, 0

LABEL_F8C3E6:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89321
	inc 1, iz
	cp iz, 0x8
	jr lt, LABEL_F8C3E6
	stdi8 35320, 4
	jr LABEL_F8C450

LABEL_F8C3FE:
	cpdi16 32624, 0
	jr lt, LABEL_F8C450
	call 0xF895EF
	ld iz, hl
	cps iz, 0
	jr lt, LABEL_F8C450
	cp iz, 0x13
	jr ge, LABEL_F8C450
	ld wa, iz
	inc 1, wa
	call 0xF89605
	jr LABEL_F8C450

LABEL_F8C420:
	calr CancelOperationCleanup
	ld xwa, 0x610001
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call 0xFA9D58
	jr LABEL_F8C450

LABEL_F8C435:
	cp xde, 0xF
	jr nz, LABEL_F8C450
	cpdi8 36148, 7
	jr nz, LABEL_F8C449
	ldw wa, 0xD6
	jr LABEL_F8C44C

LABEL_F8C449:
	ldw wa, 0x60

LABEL_F8C44C:
	call 0xF99490

LABEL_F8C450:
	lds32 xhl, 0
	popw iz
	ret

FmmSaveTitleFunc:
	pushw iz
	cp xbc, 0x1C00007
	jrl z, LABEL_F8C515
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8C524
	cp xde, 0x3
	jrl z, LABEL_F8C500
	cp xde, 0x2
	jrl nz, LABEL_F8C524
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34050, 0
	jr ge, LABEL_F8C4AE
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8C4AE:
	cpdi8 36151, 102
	jr z, LABEL_F8C4E2
	lds iz, 0

LABEL_F8C4B7:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F8937F
	inc 1, iz
	cps iz, 6
	jr lt, LABEL_F8C4B7
	lds wa, 6
	call LABEL_F89393
	lds wa, 7
	call LABEL_F89393
	call LABEL_F893CA
	ld xiy, 0xEA066A
	ld xix, 0x8A0C
	ldiw

LABEL_F8C4E2:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jr LABEL_F8C50F

LABEL_F8C500:
	calr CancelOperationCleanup
	ld xwa, 0x670001
	ld xbc, 0x1E0007F
	lds32 xde, 1

LABEL_F8C50F:
	call 0xFA9D58
	jr LABEL_F8C524

LABEL_F8C515:
	cp xde, 0xF
	jr nz, LABEL_F8C524
	ldw wa, 0x60
	call 0xF99490

LABEL_F8C524:
	lds32 xhl, 0
	popw iz
	ret

DiskNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, LABEL_F8C5E2
	cp xbc, 0x1E0003A
	jr z, LABEL_F8C56C
	cp xbc, 0x1C0000B
	jrl nz, LABEL_F8C609
	lds wa, 0
	calr InitializeOperationState
	ldada xiz, 34700
	call LABEL_F8958D
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000F
	ld xde, 0x878C
	jr LABEL_F8C5DC

LABEL_F8C56C:
	lds wa, 0
	calr InitializeOperationState
	ldada xiz, 34700
	call LABEL_F8958D
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	ldada xix, 34928
	ldada_24 xiz, 15652728
	ldada xde, 34700
	ld xhl, xde
	jr LABEL_F8C5AA

LABEL_F8C594:
	ld_srib3 A, 0x07, 0xF0, 0xF4
	extz wa
	ld_srib3 A, 0x07, 0xF8, 0xE0
	and a, 0x7
	jr nz, LABEL_F8C5A8
	ldmi8 (xbc), 0x5F

LABEL_F8C5A8:
	inc 1, iy

LABEL_F8C5AA:
	cp iy, 0xB
	jr ge, LABEL_F8C5BA
	st_dri3b A, 0x07, 0xEC, 0xF4
	cpmi8 (xbc), 0x0
	jr nz, LABEL_F8C594

LABEL_F8C5BA:
	cp iy, 0xB
	jr ge, LABEL_F8C5D0
	ld xwa, xde

LABEL_F8C5C2:
	x_dri5_o00_t1 0x07, 0xE0, 0xF4, 0x5F
	inc 1, iy
	cp iy, 0xB
	jr lt, LABEL_F8C5C2

LABEL_F8C5D0:
	ldmi8 (xde + 11), 0x0
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086

LABEL_F8C5DC:
	call 0xFA9D58
	jr LABEL_F8C609

LABEL_F8C5E2:
	ld xwa, 0x878C
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x878C
	call LABEL_F5289C
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ldw wa, 0x60
	call 0xF99490

LABEL_F8C609:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

DiskInfoFunc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xde
	cp xbc, 0x1C0000B
	jrl nz, LABEL_F8C735
	lds wa, 0
	calr InitializeOperationState
	cpdi16 34048, 0
	jr ge, LABEL_F8C636
	call 0xF89520
	extz hl
	stda16 34048, xhl

LABEL_F8C636:
	ldda16 xwa, 34048
	cps wa, 1
	jr z, LABEL_F8C65A
	cps wa, 0
	jr z, LABEL_F8C65A
	cps wa, 2
	jr z, LABEL_F8C64A
	cps wa, 3
	jr nz, LABEL_F8C65D

LABEL_F8C64A:
	call 0xF8953B
	ld (xsp + 4), xhl
	call LABEL_F89573
	ld (xsp + 12), xhl
	jr LABEL_F8C665

LABEL_F8C65A:
	calr ResetProgressIndication

LABEL_F8C65D:
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld (xsp + 4), xwa

LABEL_F8C665:
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr le, LABEL_F8C68F
	ld xwa, (xsp + 12)
	sub xwa, (xsp + 4)
	ld xbc, 0x64
	call LABEL_FF0A5C
	ld xiz, xhl
	ld xbc, (xsp + 12)
	ld xwa, xiz
	call LABEL_FF0C0E
	ld (xsp + 8), xhl
	jr LABEL_F8C694

LABEL_F8C68F:
	lds32 xwa, 0
	ld (xsp + 8), xwa

LABEL_F8C694:
	ld xwa, (xsp + 4)
	ld xbc, xwa
	sra xbc, 15
	sra xbc, 0
	and xbc, 0x3FF
	add xbc, xwa
	ld (xsp + 4), xbc
	sra xbc, 10
	ld (xsp + 4), xbc
	ldda16 xwa, 34048
	sla wa, 2
	ldada_24 xbc, 15336792
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld xwa, 0x87CE
	call LABEL_F890DC
	ld xwa, 0x87CE
	ld xbc, 0xEA06D6
	call LABEL_F89113
	ldada xwa, 34766
	ld (xsp + 12), xwa
	ld xwa, (xsp + 4)
	lds bc, 4
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call LABEL_F89113
	ld xwa, 0x87CE
	ld xbc, 0xEA06DA
	call LABEL_F89113
	ldada xwa, 34766
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	lds bc, 3
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call LABEL_F89113
	ld xwa, 0x87CE
	ld xbc, 0xEA06E4
	call LABEL_F89113
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000F
	ld xde, 0x87CE
	call 0xFA9D58

LABEL_F8C735:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

SongNameFunc:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xde
	cp xbc, 0x1C0000B
	jr nz, LABEL_F8C7AD
	call LABEL_F89AC7
	ld iz, hl
	cps iz, 0
	jr lt, LABEL_F8C797
	lds wa, 0
	calr InitializeOperationState
	ldada xwa, 34830
	ld (xsp + 2), xwa
	ld wa, iz
	call LABEL_F8A07F
	ld xbc, xhl
	ld xwa, (xsp + 2)
	call LABEL_F890DC
	ldada xwa, 34830
	ldmi8 (xwa + 30), 0x0
	lda xbc, (xwa + 29)
	ld xde, xbc
	lda xhl, (xbc - 29)
	jr LABEL_F8C786

LABEL_F8C781:
	ldmi8 (xde), 0x0
	dec 1, xde

LABEL_F8C786:
	ld c, (xde)
	cp c, 0x20
	jr nz, LABEL_F8C791
	cp xde, xhl
	jr ugt, LABEL_F8C781

LABEL_F8C791:
	call LABEL_F8929D
	jr LABEL_F8C79C

LABEL_F8C797:
	stdi8 34830, 0

LABEL_F8C79C:
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	ld xde, 0x880E
	call 0xFA9D58

LABEL_F8C7AD:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

SaveFileNameNumFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1C0000B
	jr nz, LABEL_F8C7FC
	call 0xF895EF
	ld iz, hl
	cps iz, 0
	jr lt, LABEL_F8C7E6
	call LABEL_F892BC
	ld xbc, xhl
	ld de, iz
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, 0x8850
	call LABEL_F891DD
	jr LABEL_F8C7EB

LABEL_F8C7E6:
	stdi8 34896, 0

LABEL_F8C7EB:
	ld xwa, (xsp + 2)
	ld xbc, 0x1C0000F
	ld xde, 0x8850
	call 0xFA9D58

LABEL_F8C7FC:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

SaveFileNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, LABEL_F8C8AD
	cp xbc, 0x1E0003A
	jr z, LABEL_F8C84A
	cp xbc, 0x1C0000B
	jrl nz, LABEL_F8C8C2
	ldada xiz, 34896
	call LABEL_F892BC
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, 0x8850
	call LABEL_F8929D
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000F
	ld xde, 0x8850
	jr LABEL_F8C8A7

LABEL_F8C84A:
	ldada xiz, 34896
	call LABEL_F892BC
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	ldada_24 xix, 15652728
	ldada xde, 34896
	ld xhl, xde
	jr LABEL_F8C87A

LABEL_F8C869:
	extz wa
	ld_srib3 A, 0x07, 0xF0, 0xE0
	and a, 0x7
	jr nz, LABEL_F8C878
	ldmi8 (xbc), 0x5F

LABEL_F8C878:
	inc 1, iy

LABEL_F8C87A:
	cps iy, 6
	jr ge, LABEL_F8C889
	st_dri3b A, 0x07, 0xEC, 0xF4
	ld a, (xbc)
	cps a, 0
	jr nz, LABEL_F8C869

LABEL_F8C889:
	cps iy, 6
	jr ge, LABEL_F8C89B
	ld xwa, xde

LABEL_F8C88F:
	x_dri5_o00_t1 0x07, 0xE0, 0xF4, 0x5F
	inc 1, iy
	cps iy, 6
	jr lt, LABEL_F8C88F

LABEL_F8C89B:
	ldmi8 (xde + 6), 0x0
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086

LABEL_F8C8A7:
	call 0xFA9D58
	jr LABEL_F8C8C2

LABEL_F8C8AD:
	ld xwa, 0x8850
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	ld xwa, 0x8850
	call LABEL_F892C2

LABEL_F8C8C2:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

CurFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1C0000B
	jr nz, LABEL_F8C913
	call 0xF895EF
	ld iz, hl
	cps iz, 0
	jr lt, LABEL_F8C8FD
	ld wa, iz
	call LABEL_F89623
	ld xbc, xhl
	ld de, iz
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, 0x8870
	call LABEL_F891DD
	jr LABEL_F8C902

LABEL_F8C8FD:
	stdi8 34928, 0

LABEL_F8C902:
	ld xwa, (xsp + 2)
	ld xbc, 0x1C0000F
	ld xde, 0x8870
	call 0xFA9D58

LABEL_F8C913:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

