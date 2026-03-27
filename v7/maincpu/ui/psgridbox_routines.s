; =============================================================================
; PS Grid Box Widget
; =============================================================================
;
; Parameter Selection Grid Box widget: initialization, memory
; allocation, visibility control, and event handling.
; =============================================================================

PsGridBox_Init:
	ld	xwa, (xsp+334)
	call	16408153
	ld	xiz, xhl
	ld	wa, (xiz+38)
	sll	wa, 1
	inc	2, wa
	pushw	wa
	call	16713379
	ld	xwa, (xiz+50)
	ld	(xwa), xhl
	ld	wa, (xiz+36)
	sll	wa, 1
	inc	2, wa
	pushw	wa
	call	16713379
	ld	xwa, (xiz+54)
	ld	(xwa), xhl
	ld	wa, (xiz+36)
	sll	wa, 1
	inc	2, wa
	pushw	wa
	call	16713379
	inc	6, xsp
	ld	xwa, (xiz+58)
	ld	(xwa), xhl
	ld	xwa, (xsp+334)
	ld	xbc, (xsp+330)
	ld	xde, (xsp+326)
	jrl	758
PsGridBox_Close:
	ld	xwa, (xsp+334)
	ld	xbc, (xsp+330)
	ld	xde, (xsp+326)
	calr	61005
	ld	xwa, (xsp+334)
	call	16408153
	ld	xiz, xhl
	lda	xbc, (xiz+50)
	ld	xwa, (xbc)
	ld	xwa, (xwa)
	or	xwa, xwa
	jr	z, 18
	ld	xwa, (xbc)
	ld	xwa, (xwa)
	push	xwa
	call	16712469
	inc	4, xsp
	ld	xbc, (xiz+50)
	lds32	xwa, 0
	ld	(xbc), xwa
PsGridBox_Close_FreeRows:
	ld	xbc, (xiz+54)
	ld	xwa, (xbc)
	or	xwa, xwa
	jr	z, 16
	ld	xwa, (xbc)
	push	xwa
	call	16712469
	inc	4, xsp
	ld	xbc, (xiz+54)
	lds32	xwa, 0
	ld	(xbc), xwa
PsGridBox_Close_FreeRowAlt:
	ld	xbc, (xiz+58)
	ld	xwa, (xbc)
	or	xwa, xwa
	jr	z, 16
	ld	xwa, (xbc)
	push	xwa
	call	16712469
	inc	4, xsp
	ld	xbc, (xiz+58)
	lds32	xwa, 0
	ld	(xbc), xwa
PsGridBox_ReturnZero:
	lds32 xhl, 0
	jrl PsGridBox_Return

PsGridBox_ShowHide:
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld (xsp + 20), xhl
	ld xwa, (xsp + 20)
	ld (xsp + 4), xwa
	lda xde, (xsp + 42)
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008a
	call SendEvent
	ldw (xsp + 14), 0x0
	ldw (xsp + 18), 0x0
	jr PsGridBox_ShowHide_CountLoop

PsGridBox_ShowHide_CountPipe:
	cp a, 0x7c
	jr nz, PsGridBox_ShowHide_CountNext
	incm 1, (xsp + 18)

PsGridBox_ShowHide_CountNext:
	incm 1, (xsp + 14)

PsGridBox_ShowHide_CountLoop:
	.byte 0x9f, 0x0e, 0x21, 0xe9, 0x12, 0xbf, 0x2a, 0x30
	.byte 0xe9, 0x80, 0x80, 0x21, 0xc9, 0xd8, 0x6e, 0xe5
	.byte 0xf3, 0xfd, 0x3e, 0x01, 0x31, 0xe3, 0xfd, 0x4e
	.byte 0x01, 0x20, 0x1e, 0x8e, 0xb6, 0xf3, 0xfd, 0x3e
	.byte 0x01, 0x31, 0x99, 0x04, 0x20, 0xbf, 0x08, 0x50
	.byte 0x91, 0x20, 0x9f, 0x08, 0xa8, 0x9f, 0x08, 0x69
	.byte 0xbf, 0x2a, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xef, 0x64, 0x9f, 0x12, 0x20, 0xd8, 0xa3, 0xbf
	.byte 0x0a, 0x53, 0xbf, 0x0e, 0x02, 0x00, 0x00, 0xaf
	.byte 0x04, 0x22, 0xaa, 0x32, 0x20, 0xa0, 0x21, 0xd3
	.byte 0xfd, 0x3e, 0x01, 0x20, 0xb1, 0x50, 0xbf, 0x0c
	.byte 0x02, 0x01, 0x00, 0x9a, 0x26, 0x3f, 0x01, 0x00
	.byte 0x67, 0x76
PsGridBox_ShowHide_CalcWidths:
	ld wa, (xsp + 14)
	extz xwa
	lda xde, (xsp + 42)
	ld (xsp + 16), xde
	add (xsp + 16), xwa
	jr PsGridBox_ShowHide_ScanLoop

PsGridBox_ShowHide_ScanPipe:
	cp a, 0x7c
	jr nz, PsGridBox_ShowHide_AdvChar
	ld (xbc), 0x0
	incm 1, (xsp + 14)
	jr PsGridBox_ShowHide_CalcWidth

PsGridBox_ShowHide_AdvChar:
	incm 1, (xsp + 14)

PsGridBox_ShowHide_ScanLoop:
	ld wa, (xsp + 14)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsGridBox_ShowHide_ScanPipe

PsGridBox_ShowHide_CalcWidth:
	.byte 0xaf, 0x10, 0x20, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xef, 0x64, 0x9f, 0x08, 0x20, 0xdb, 0x40, 0x9f
	.byte 0x0a, 0x21, 0xe8, 0x12, 0xd9, 0x50, 0xd8, 0x8b
	.byte 0x9f, 0x0c, 0x21, 0xd9, 0x69, 0xe9, 0x12, 0xe9
	.byte 0x81, 0xaf, 0x04, 0x24, 0xac, 0x32, 0x20, 0xa0
	.byte 0x20, 0xe8, 0x8a, 0xe9, 0x82, 0x92, 0x22, 0xdb
	.byte 0x82, 0x9f, 0x0c, 0x21, 0xe9, 0x12, 0xe9, 0x81
	.byte 0xe9, 0x80, 0xb0, 0x52, 0x9f, 0x0c, 0x61, 0x9f
	.byte 0x0c, 0x21, 0x9c, 0x26, 0xf1, 0x63, 0x8a
PsGridBox_ShowHide_ParseRows:
	lda xde, (xsp + 42)
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008b
	call SendEvent
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ldw (xsp + 10), 0x0
	ldw (xsp + 14), 0x0
	ldw (xsp + 12), 0x1
	ld xwa, (xsp + 20)
	lda xwa, (xwa + 36)
	ld (xsp + 20), xwa
	cpw (xwa), 0x1
	jrl c, PsGridBox_ShowHide_FinalRow

PsGridBox_ShowHide_RowScan:
	ld wa, (xsp + 14)
	extz xwa
	lda xde, (xsp + 42)
	ld (xsp + 16), xde
	add (xsp + 16), xwa
	jr PsGridBox_ShowHide_RowLoop

PsGridBox_ShowHide_RowPipe:
	cp a, 0x7c
	jr nz, PsGridBox_ShowHide_RowNext
	ld (xbc), 0x0
	incm 1, (xsp + 14)
	jr PsGridBox_ShowHide_ClassifyCell

PsGridBox_ShowHide_RowNext:
	incm 1, (xsp + 14)

PsGridBox_ShowHide_RowLoop:
	ld wa, (xsp + 14)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsGridBox_ShowHide_RowPipe

PsGridBox_ShowHide_ClassifyCell:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	ldb_erp A, 0xee
	ld de, (xsp + 12)
	dec 1, de
	extz xde
	add xde, xde
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 58)
	cp_erpb 0xee, 0x2d
	jr z, PsGridBox_ShowHide_CellDash
	cpib_erp 0xee, 0
	jr nz, PsGridBox_ShowHide_CellNormal
	lds wa, 0
	jr PsGridBox_ShowHide_StoreType

PsGridBox_ShowHide_CellDash:
	lds wa, 1
	jr PsGridBox_ShowHide_StoreType

PsGridBox_ShowHide_CellNormal:
	lds wa, 2

PsGridBox_ShowHide_StoreType:
	ld xbc, (xbc)
	ld xbc, (xbc)
	add xbc, xde
	ld (xbc), wa
	ld bc, (xsp + 12)
	extz xbc
	ld xwa, (xsp + 4)
	lda xde, (xwa + 54)
	add xbc, xbc
	ld xwa, (xsp + 16)
	cp (xwa), 0x2d
	jr z, PsGridBox_ShowHide_DashRow
	ld xwa, (xde)
	ld xde, (xwa)
	add xde, xbc
	ld wa, hl
	sla wa, 2
	ld (xde), wa
	jr PsGridBox_ShowHide_AccumHeight

PsGridBox_ShowHide_DashRow:
	ld xwa, (xde)
	ld xwa, (xwa)
	add xwa, xbc
	ld (xwa), hl

PsGridBox_ShowHide_AccumHeight:
	ld bc, (xsp + 12)
	extz xbc
	add xbc, xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 54)
	ld xwa, (xwa)
	add xwa, xbc
	ld wa, (xwa)
	add (xsp + 10), wa
	incm 1, (xsp + 12)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 12)
	cp bc, (xwa)
	jrl ule, PsGridBox_ShowHide_RowScan

PsGridBox_ShowHide_FinalRow:
	ld bc, (xsp + 12)
	dec 1, bc
	extz xbc
	add xbc, xbc
	ld xde, (xsp + 4)
	ld xwa, (xde + 58)
	ld xwa, (xwa)
	add xwa, xbc
	ldw (xwa), 0x5
	stb_dri W, 0xfd, 0x3e, 0x01
	ld bc, (xwa + 2)
	ld hl, (xwa + 6)
	sub hl, bc
	dec 1, hl
	lda xde, (xde + 54)
	ld xwa, (xde)
	ld xwa, (xwa)
	ld (xwa), bc
	ldw (xsp + 12), 0x1
	ld xwa, (xsp + 20)
	cpw (xwa), 0x1
	jr c, PsGridBox_ShowHide_Forward

PsGridBox_ShowHide_BoundLoop:
	ld wa, (xsp + 12)
	dec 1, wa
	extz xwa
	add xwa, xwa
	ld xix, (xde)
	ld xiy, (xix)
	add xiy, xwa
	ld bc, (xsp + 12)
	extz xbc
	add xbc, xbc
	ld xiz, (xix)
	add xiz, xbc
	ld wa, hl
	mriw2 0x96, 0x48
	ld iz, wa
	exts xiz
	mrdw3 0x9f, 0x0a, 0x5e
	add iz, (xiy)
	ld xwa, (xix)
	add xwa, xbc
	ld (xwa), iz
	incm 1, (xsp + 12)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 12)
	cp bc, (xwa)
	jr ule, PsGridBox_ShowHide_BoundLoop

PsGridBox_ShowHide_Forward:
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)

PsGridBox_ShowHide_Tail:
	calr VwBoxProc
	jrl PsGridBox_ReturnZero

PsGridBox_Paint:
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 42)
	ld de, (xwa)
	ldw (xwa), 0xffff
	exts xde
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1c0000e
	jrl PsGridBox_DispatchEvent

PsGridBox_Confirm:
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld (xsp + 20), xhl
	ld xwa, (xsp + 20)
	ld (xsp + 4), xwa
	lda xde, (xsp + 42)
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008a
	call SendEvent
	stb_dri A, 0xfd, 0x3e, 0x01
	ld xhl, (xsp + 20)
	lda xde, (xhl + 54)
	ld xwa, (xde)
	ld xwa, (xwa)
	ld wa, (xwa)
	inc 3, wa
	ld (xbc + 2), wa
	ld xwa, (xde)
	ld xwa, (xwa)
	ld wa, (xwa + 2)
	dec 1, wa
	ld (xbc + 6), wa
	ldw (xsp + 14), 0x0
	ldw (xsp + 12), 0x0
	cpw (xhl + 38), 0x0
	jrl ule, PsGridBox_Confirm_Rows

PsGridBox_Confirm_ColScan:
	ld wa, (xsp + 14)
	extz xwa
	lda xde, (xsp + 42)
	ld (xsp + 16), xde
	add (xsp + 16), xwa
	jr PsGridBox_Confirm_ColLoop

PsGridBox_Confirm_ColPipe:
	cp a, 0x7c
	jr nz, PsGridBox_Confirm_ColNext
	ld (xbc), 0x0
	incm 1, (xsp + 14)
	jr PsGridBox_Confirm_DrawCol

PsGridBox_Confirm_ColNext:
	incm 1, (xsp + 14)

PsGridBox_Confirm_ColLoop:
	ld wa, (xsp + 14)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsGridBox_Confirm_ColPipe

PsGridBox_Confirm_DrawCol:
	ld bc, (xsp + 12)
	extz xbc
	add xbc, xbc
	ld xwa, (xsp + 20)
	lda xde, (xwa + 50)
	ld xwa, (xde)
	ld xhl, (xwa)
	add xhl, xbc
	stb_dri W, 0xfd, 0x3e, 0x01
	ld bc, (xhl)
	ld (xwa), bc
	ld hl, (xsp + 12)
	inc 1, hl
	extz xhl
	add xhl, xhl
	ld xbc, (xde)
	ld xbc, (xbc)
	add xbc, xhl
	ld bc, (xbc)
	ld (xwa + 4), bc
	stb_dri A, 0xfd, 0x32, 0x01
	calr GetBoxCenter
	stb_dri B, 0xfd, 0x3e, 0x01
	stb_dri A, 0xfd, 0x32, 0x01
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 28)
	push xwa
	pushw 0xf1
	ld xwa, (xsp + 10)
	pushm (xwa + 22)
	ld a, (xwa + 34)
	extz wa
	pushw wa
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringAlignment
	incm 1, (xsp + 12)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 12)
	cp bc, (xwa + 38)
	jrl c, PsGridBox_Confirm_ColScan

PsGridBox_Confirm_Rows:
	lda xde, (xsp + 42)
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008b
	call SendEvent
	stb_dri A, 0xfd, 0x3e, 0x01
	ld xhl, (xsp + 20)
	lda xde, (xhl + 50)
	ld xwa, (xde)
	ld xwa, (xwa)
	ld wa, (xwa)
	ld (xbc), wa
	ld xwa, (xde)
	ld xwa, (xwa)
	ld wa, (xwa + 2)
	ld (xbc + 4), wa
	ldw (xsp + 14), 0x0
	ldw (xsp + 12), 0x0
	cpw (xhl + 36), 0x0
	jrl ule, PsGridBox_Confirm_CellSelect

PsGridBox_Confirm_RowScan:
	ld wa, (xsp + 14)
	extz xwa
	lda xde, (xsp + 42)
	ld (xsp + 16), xde
	add (xsp + 16), xwa
	jr PsGridBox_Confirm_RowLoop

PsGridBox_Confirm_RowPipe:
	cp a, 0x7c
	jr nz, PsGridBox_Confirm_RowAdv
	ld (xbc), 0x0
	incm 1, (xsp + 14)
	jr PsGridBox_Confirm_DrawRow

PsGridBox_Confirm_RowAdv:
	incm 1, (xsp + 14)

PsGridBox_Confirm_RowLoop:
	ld wa, (xsp + 14)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsGridBox_Confirm_RowPipe

PsGridBox_Confirm_DrawRow:
	ld xwa, (xsp + 16)
	cp (xwa), 0x2d
	jr z, PsGridBox_Confirm_DrawSep
	ld de, (xsp + 12)
	extz xde
	add xde, xde
	ld xwa, (xsp + 20)
	lda xbc, (xwa + 54)
	ld xwa, (xbc)
	ld xwa, (xwa)
	add xwa, xde
	ld de, (xwa)
	inc 3, de
	stb_dri W, 0xfd, 0x3e, 0x01
	ld (xwa + 2), de
	ld de, (xsp + 12)
	inc 1, de
	extz xde
	add xde, xde
	ld xbc, (xbc)
	ld xbc, (xbc)
	add xbc, xde
	ld bc, (xbc)
	dec 1, bc
	ld (xwa + 6), bc
	stb_dri A, 0xfd, 0x32, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x3e, 0x01
	stb_dri B, 0xfd, 0x32, 0x01
	ld xbc, (xsp + 20)
	ld xbc, (xbc + 28)
	push xbc
	ld xbc, (xsp + 8)
	pushm (xbc + 32)
	pushm (xbc + 22)
	ld c, (xbc + 34)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, (xsp + 26)
	call DrawStringAlignment
	jr PsGridBox_Confirm_RowDone

PsGridBox_Confirm_DrawSep:
	stb_dri A, 0xfd, 0x36, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	stb_dri W, 0xfd, 0x2e, 0x01
	stb_dri B, 0xfd, 0x36, 0x01
	ld bc, (xde)
	ld (xwa), bc
	stb_dri A, 0xfd, 0x2a, 0x01
	ld de, (xde + 4)
	ld (xbc), de
	ld hl, (xsp + 12)
	extz xhl
	add xhl, xhl
	ld xde, (xsp + 20)
	ld xde, (xde + 54)
	ld xde, (xde)
	ld xix, xde
	add xix, xhl
	ld hl, (xsp + 12)
	inc 1, hl
	extz xhl
	add xhl, xhl
	add xde, xhl
	ld de, (xde)
	add de, (xix)
	exts xde
	divs de, 0x2
	inc 2, de
	ld (xwa + 2), de
	ld (xbc + 2), de
	ldw de, 0xff
	call DrawLine

PsGridBox_Confirm_RowDone:
	incm 1, (xsp + 12)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 12)
	cp bc, (xwa + 36)
	jrl c, PsGridBox_Confirm_RowScan

PsGridBox_Confirm_CellSelect:
	ldw (xsp + 14), 0x0
	ld xwa, (xsp + 20)
	cpw (xwa + 36), 0x0
	jrl ule, PsGridBox_ReturnZero

PsGridBox_Confirm_OuterLoop:
	ldw (xsp + 12), 0x1
	ld xwa, (xsp + 20)
	cpw (xwa + 38), 0x1
	jr ule, PsGridBox_Confirm_OuterNext

PsGridBox_Confirm_InnerLoop:
	ld bc, (xsp + 14)
	extz xbc
	ld xde, xbc
	add xde, xde
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 58)
	ld xwa, (xwa)
	add xwa, xde
	cpw (xwa), 0x2
	jr nz, PsGridBox_Confirm_InnerNext
	ld de, (xsp + 12)
	extz xde
	sll xde, 0
	add xde, xbc
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008d
	call SendEvent

PsGridBox_Confirm_InnerNext:
	incm 1, (xsp + 12)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 12)
	cp bc, (xwa + 38)
	jr c, PsGridBox_Confirm_InnerLoop

PsGridBox_Confirm_OuterNext:
	incm 1, (xsp + 14)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 14)
	cp bc, (xwa + 36)
	jr c, PsGridBox_Confirm_OuterLoop
	jrl PsGridBox_ReturnZero

PsGridBox_Select:
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld (xsp + 20), xhl
	ld_sril XWA, (xsp + 0x0146)
	ld (xsp + 18), wa
	ld bc, (xsp + 18)
	exts xbc
	add xbc, xbc
	ld xde, (xsp + 20)
	ld xwa, (xde + 58)
	ld xwa, (xwa)
	add xwa, xbc
	cpw (xwa), 0x2
	jrl nz, PsGridBox_ReturnZero
	ld xbc, (xde + 42)
	ld wa, (xbc)
	cp wa, (xsp + 18)
	jrl z, PsGridBox_ReturnZero
	cpw (xbc), 0xffff
	jr z, PsGridBox_Select_NoOld
	ld wa, (xbc)
	ld (xsp + 18), wa
	stb_dri A, 0xfd, 0x3e, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	ld xix, (xsp + 20)
	lda xbc, (xix + 42)
	ld xwa, (xbc)
	ld hl, (xwa)
	exts xhl
	add xhl, xhl
	lda xde, (xix + 54)
	ld xwa, (xde)
	ld xwa, (xwa)
	add xwa, xhl
	ld hl, (xwa)
	inc 1, hl
	stb_dri W, 0xfd, 0x3e, 0x01
	ld (xwa + 2), hl
	incm 1, (xwa)
	decm 1, (xwa + 4)
	ld xbc, (xbc)
	ld hl, (xbc)
	inc 1, hl
	exts xhl
	add xhl, xhl
	ld xbc, (xde)
	ld xbc, (xbc)
	add xbc, xhl
	ld bc, (xbc)
	inc 2, bc
	ld (xwa + 6), bc
	pushm (xix + 22)
	lds bc, 1
	lds de, 2
	calr DrawDesignFrame
	jr PsGridBox_Select_Scroll

PsGridBox_Select_NoOld:
	ldw (xsp + 18), 0xffff

PsGridBox_Select_Scroll:
	ld xwa, (xsp + 20)
	cpw (xwa + 40), 0x0
	jr z, PsGridBox_Select_StoreSel
	stb_dri A, 0xfd, 0x3e, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	stb_dri A, 0xfd, 0x3e, 0x01
	ld wa, (xbc + 2)
	stw_dri WA, 0xfd, 0x30, 0x01
	ld wa, (xbc + 6)
	stw_dri WA, 0xfd, 0x2c, 0x01
	ldw (xsp + 12), 0x1
	ld xwa, (xsp + 20)
	cpw (xwa + 38), 0x1
	jr ule, PsGridBox_Select_StoreSel

PsGridBox_Select_ScrollLoop:
	ld de, (xsp + 12)
	extz xde
	add xde, xde
	ld xwa, (xsp + 20)
	lda xhl, (xwa + 50)
	ld xwa, (xhl)
	ld xbc, (xwa)
	add xbc, xde
	stb_dri W, 0xfd, 0x2e, 0x01
	ld bc, (xbc)
	ld (xwa), bc
	ld xbc, (xhl)
	ld xhl, (xbc)
	add xhl, xde
	stb_dri A, 0xfd, 0x2a, 0x01
	ld de, (xhl)
	ld (xbc), de
	ldw de, 0xff
	call DrawLine
	incm 1, (xsp + 12)
	ld xwa, (xsp + 20)
	ld bc, (xsp + 12)
	cp bc, (xwa + 38)
	jr c, PsGridBox_Select_ScrollLoop

PsGridBox_Select_StoreSel:
	ld xde, (xsp + 20)
	ld xbc, (xde + 42)
	ld_sril XWA, (xsp + 0x0146)
	ld (xbc), wa
	cpw (xsp + 18), 0xffff
	jr z, PsGridBox_Select_SendCurr
	ld bc, (xsp + 18)
	extz xbc
	ld xwa, (xde + 46)
	ld wa, (xwa)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008d
	call SendEvent

PsGridBox_Select_SendCurr:
	ld xde, (xsp + 20)
	ld xwa, (xde + 42)
	ld bc, (xwa)
	extz xbc
	ld xwa, (xde + 46)
	ld wa, (xwa)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008d
	call SendEvent
	stb_dri A, 0xfd, 0x3e, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	ld xde, (xsp + 20)
	lda xbc, (xde + 42)
	ld xwa, (xbc)
	ld hl, (xwa)
	exts xhl
	add xhl, xhl
	lda xde, (xde + 54)
	ld xwa, (xde)
	ld xwa, (xwa)
	add xwa, xhl
	ld hl, (xwa)
	inc 1, hl
	stb_dri W, 0xfd, 0x3e, 0x01
	ld (xwa + 2), hl
	incm 1, (xwa)
	decm 1, (xwa + 4)
	ld xbc, (xbc)
	ld hl, (xbc)
	inc 1, hl
	exts xhl
	add xhl, xhl
	ld xbc, (xde)
	ld xbc, (xbc)
	add xbc, xhl
	ld bc, (xbc)
	inc 2, bc
	ld (xwa + 6), bc
	pushw 0xf2
	lds bc, 1
	lds de, 2
	calr DrawDesignFrame
	jrl PsGridBox_ReturnZero

PsGridBox_Scroll:
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld de, (xhl + 26)
	cp de, 0xffff
	jrl z, PsGridBox_ReturnZero
	ld bc, de
	exts xbc
	cpl_sri_rm XBC, 0xfd, 0x46, 0x01
	jrl z, PsGridBox_ReturnZero
	ld_sril XWA, (xsp + 0x0146)
	sub wa, de
	cp wa, (xhl + 38)
	jrl nc, PsGridBox_ReturnZero
	ld_sril XWA, (xsp + 0x0146)
	sub xwa, xbc
	ld bc, wa
	extz xbc
	sll xbc, 0
	ld xwa, (xhl + 42)
	ld de, (xwa)
	extz xde
	add xde, xbc
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008e
	jrl PsGridBox_DispatchEvent
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld (xsp + 20), xhl
	ld_sril XWA, (xsp + 0x0146)
	ld xiy, xwa
	lda xix, (xsp + 24)
	lds bc, 4
	ldirw
	lda xde, (xsp + 24)
	cpw (xde), 0xffff
	jr nz, PsGridBox_Scroll_DefaultCol
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 46)
	ld wa, (xwa)
	ld (xde), wa

PsGridBox_Scroll_DefaultCol:
	lda xhl, (xde + 2)
	cpw (xhl), 0xffff
	jr nz, PsGridBox_Scroll_CalcBounds
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 42)
	ld wa, (xwa)
	ld (xhl), wa

PsGridBox_Scroll_CalcBounds:
	ld bc, (xhl)
	exts xbc
	add xbc, xbc
	ld xiy, (xsp + 20)
	lda xix, (xiy + 54)
	ld xwa, (xix)
	ld xwa, (xwa)
	add xwa, xbc
	ld bc, (xwa)
	inc 3, bc
	stb_dri W, 0xfd, 0x3e, 0x01
	ld (xwa + 2), bc
	ld iz, (xde)
	exts xiz
	add xiz, xiz
	lda xiy, (xiy + 50)
	ld xbc, (xiy)
	ld xbc, (xbc)
	add xbc, xiz
	ld bc, (xbc)
	inc 4, bc
	ld (xwa), bc
	ld de, (xde)
	inc 1, de
	exts xde
	add xde, xde
	ld xbc, (xiy)
	ld xbc, (xbc)
	add xbc, xde
	ld bc, (xbc)
	dec 4, bc
	ld (xwa + 4), bc
	ld de, (xhl)
	inc 1, de
	exts xde
	add xde, xde
	ld xbc, (xix)
	ld xbc, (xbc)
	add xbc, xde
	ld bc, (xbc)
	dec 1, bc
	ld (xwa + 6), bc
	stb_dri A, 0xfd, 0x32, 0x01
	calr GetBoxCenter
	calr GetDialFocus
	cpl_sri_rm XHL, 0xfd, 0x4e, 0x01
	jr nz, PsGridBox_Scroll_Unfocused
	lda xbc, (xsp + 24)
	ld xde, (xsp + 20)
	ld xwa, (xde + 42)
	ld wa, (xwa)
	cp wa, (xbc + 2)
	jr nz, PsGridBox_Scroll_Unfocused
	ld xwa, (xde + 46)
	ld wa, (xwa)
	cp wa, (xbc)
	jr nz, PsGridBox_Scroll_Unfocused
	lds de, 1
	jr PsGridBox_Scroll_Render

PsGridBox_Scroll_Unfocused:
	lds de, 0

PsGridBox_Scroll_Render:
	.byte 0xf3, 0xfd, 0x3e, 0x01, 0x33, 0xf3, 0xfd, 0x32
	.byte 0x01, 0x31, 0xaf, 0x14, 0x24, 0xac, 0x1c, 0x20
	.byte 0x38, 0x9c, 0x20, 0x04, 0xec, 0x88, 0x98, 0x16
	.byte 0x04, 0x88, 0x22, 0x21, 0xd8, 0x12, 0x28, 0x2a
	.byte 0xaf, 0x28, 0x22, 0xeb, 0x88, 0x1d, 0x77, 0xcc
	.byte 0xfa, 0x78, 0x40, 0xf7, 0xbf, 0x18, 0x32, 0xe3
	.byte 0xfd, 0x46, 0x01, 0x20, 0xe8, 0xef, 0x00, 0xd7
	.byte 0xe2, 0xa8, 0xb2, 0x50, 0xba, 0x02, 0x31, 0xe3
	.byte 0xfd, 0x46, 0x01, 0x20, 0xb1, 0x50, 0xbf, 0x20
	.byte 0x30, 0xba, 0x04, 0x60, 0x91, 0x04, 0x92, 0x04
	.byte 0x0b, 0xea, 0x00, 0x0b, 0xec, 0xa1, 0x38, 0x1d
	.byte 0x95, 0x02, 0xff, 0xbf, 0x0c, 0x37, 0xbf, 0x18
	.byte 0x32, 0xe3, 0xfd, 0x4e, 0x01, 0x20, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x78, 0xf1, 0x00, 0x40, 0xf2
	.byte 0xa1, 0xea, 0x00, 0x68, 0x05, 0x40, 0x12, 0xa2
	.byte 0xea, 0x00
PsGridBox_Scroll_CopyStr:
	push	xwa
	ld	xwa, (xsp+330)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	-2334
	ld	xwa, (xsp+334)
	call	16408153
	ld	(xsp+20), xhl
	ld	xwa, (xsp+326)
	srl	xwa, 0
	ld	qwa, 0
	ld	iz, wa
	cp	iz, 65535
	jr	nz, 8
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+46)
	ld	iz, (xwa)
PsGridBox_Scroll_DefaultRow:
	ld_sril XWA, (xsp + 0x0146)
	ld (xsp + 18), wa
	cpw (xsp + 18), 0xffff
	jr nz, PsGridBox_Scroll_CheckRowChange
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 42)
	ld wa, (xwa)
	ld (xsp + 18), wa

PsGridBox_Scroll_CheckRowChange:
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 42)
	ld wa, (xwa)
	cp wa, (xsp + 18)
	jr z, PsGridBox_Scroll_CheckColChange
	ld de, (xsp + 18)
	exts xde
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1c0000e
	call SendEvent

PsGridBox_Scroll_CheckColChange:
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 46)
	cp (xwa), iz
	jrl z, PsGridBox_ReturnZero
	ldw iz, 0xffff
	cpw (xwa), 0x0
	jr le, PsGridBox_Scroll_StoreCol
	ld iz, (xwa)

PsGridBox_Scroll_StoreCol:
	ld_sril XBC, (xsp + 0x0146)
	srl xbc, 0
	ldiw_erp 0xe6, 0
	cp bc, 0xffff
	jr z, PsGridBox_Scroll_SendOldCell
	ld (xwa), bc

PsGridBox_Scroll_SendOldCell:
	cp iz, 0xffff
	jr z, PsGridBox_Scroll_SendNewCell
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 42)
	ld bc, (xwa)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008d
	call SendEvent

PsGridBox_Scroll_SendNewCell:
	ld xde, (xsp + 20)
	ld xwa, (xde + 42)
	ld bc, (xwa)
	extz xbc
	ld xwa, (xde + 46)
	ld wa, (xwa)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008d

PsGridBox_DispatchEvent:
	call SendEvent
	jrl PsGridBox_ReturnZero
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld xwa, (xhl + 42)
	ld bc, (xwa)
	extz xbc
	ld xwa, (xhl + 46)
	ld wa, (xwa)
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr PsGridBox_Return
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld de, (xhl + 26)
	cp de, 0xffff
	jrl z, PsGridBox_ReturnZero
	ld wa, de
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x46, 0x01
	jrl z, PsGridBox_ReturnZero
	ld_sril XWA, (xsp + 0x0146)
	sub wa, de
	cp wa, (xhl + 38)
	jrl nc, PsGridBox_ReturnZero
	lds32 xhl, 1
	jr PsGridBox_Return

PsGridBox_Default:
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)
	calr VwBoxProc

PsGridBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x4e, 0x01
	ret

