; =============================================================================
; PS Grid Box Widget
; =============================================================================
;
; Parameter Selection Grid Box widget: initialization, memory
; allocation, visibility control, and event handling.
; =============================================================================

PsGridBox_Init:
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld xiz, xhl
	ld wa, (xiz + 38)
	sll wa, 1
	inc 2, wa
	pushw wa
	call Malloc
	ld xwa, (xiz + 50)
	ld (xwa), xhl
	ld wa, (xiz + 36)
	sll wa, 1
	inc 2, wa
	pushw wa
	call Malloc
	ld xwa, (xiz + 54)
	ld (xwa), xhl
	ld wa, (xiz + 36)
	sll wa, 1
	inc 2, wa
	pushw wa
	call Malloc
	inc 6, xsp
	ld xwa, (xiz + 58)
	ld (xwa), xhl
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)
	jrl PsGridBox_ShowHide_Tail

PsGridBox_Close:
	ld_sril XWA, (xsp + 0x014e)
	ld_sril XBC, (xsp + 0x014a)
	ld_sril XDE, (xsp + 0x0146)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xiz + 50)
	ld xwa, (xbc)
	ld xwa, (xwa)
	or xwa, xwa
	jr z, PsGridBox_Close_FreeRows
	ld xwa, (xbc)
	ld xwa, (xwa)
	push xwa
	call Free
	inc 4, xsp
	ld xbc, (xiz + 50)
	lds32 xwa, 0
	ld (xbc), xwa

PsGridBox_Close_FreeRows:
	ld xbc, (xiz + 54)
	ld xwa, (xbc)
	or xwa, xwa
	jr z, PsGridBox_Close_FreeRowAlt
	ld xwa, (xbc)
	push xwa
	call Free
	inc 4, xsp
	ld xbc, (xiz + 54)
	lds32 xwa, 0
	ld (xbc), xwa

PsGridBox_Close_FreeRowAlt:
	ld xbc, (xiz + 58)
	ld xwa, (xbc)
	or xwa, xwa
	jr z, PsGridBox_ReturnZero
	ld xwa, (xbc)
	push xwa
	call Free
	inc 4, xsp
	ld xbc, (xiz + 58)
	lds32 xwa, 0
	ld (xbc), xwa

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
	ld bc, (xsp + 14)
	extz xbc
	lda xwa, (xsp + 42)
	add xwa, xbc
	ld a, (xwa)
	cps a, 0
	jr nz, PsGridBox_ShowHide_CountPipe
	st_dri3b A, 0xfd, 0x3e, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	st_dri3b A, 0xfd, 0x3e, 0x01
	ld wa, (xbc + 4)
	ld (xsp + 8), wa
	ld wa, (xbc)
	sub (xsp + 8), wa
	decm 1, (xsp + 8)
	lda xwa, (xsp + 42)
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 18)
	sub hl, wa
	ld (xsp + 10), hl
	ldw (xsp + 14), 0x0
	ld xde, (xsp + 4)
	ld xwa, (xde + 50)
	ld xbc, (xwa)
	ld_sriw WA, (xsp + 0x013e)
	ld (xbc), wa
	ldw (xsp + 12), 0x1
	cpw (xde + 38), 0x1
	jr c, PsGridBox_ShowHide_ParseRows

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
	ld xwa, (xsp + 16)
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 8)
	mul xwa, xhl
	ld bc, (xsp + 10)
	extz xwa
	div xwa, xbc
	ld hl, wa
	ld bc, (xsp + 12)
	dec 1, bc
	extz xbc
	add xbc, xbc
	ld xix, (xsp + 4)
	ld xwa, (xix + 50)
	ld xwa, (xwa)
	ld xde, xwa
	add xde, xbc
	ld de, (xde)
	add de, hl
	ld bc, (xsp + 12)
	extz xbc
	add xbc, xbc
	add xwa, xbc
	ld (xwa), de
	incm 1, (xsp + 12)
	ld bc, (xsp + 12)
	cp bc, (xix + 38)
	jr ule, PsGridBox_ShowHide_CalcWidths

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
	ldfr_berp A, 0xee
	ld de, (xsp + 12)
	dec 1, de
	extz xde
	add xde, xde
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 58)
	cp_erpb 0xee, 0x2d
	jr z, PsGridBox_ShowHide_CellDash
	cpi_berp 0xee, 0
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
	st_dri3b W, 0xfd, 0x3e, 0x01
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
	st_dri3b A, 0xfd, 0x3e, 0x01
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
	st_dri3b W, 0xfd, 0x3e, 0x01
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
	st_dri3b A, 0xfd, 0x32, 0x01
	calr GetBoxCenter
	st_dri3b B, 0xfd, 0x3e, 0x01
	st_dri3b A, 0xfd, 0x32, 0x01
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
	st_dri3b A, 0xfd, 0x3e, 0x01
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
	st_dri3b W, 0xfd, 0x3e, 0x01
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
	st_dri3b A, 0xfd, 0x32, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xfd, 0x3e, 0x01
	st_dri3b B, 0xfd, 0x32, 0x01
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
	st_dri3b A, 0xfd, 0x36, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	st_dri3b W, 0xfd, 0x2e, 0x01
	st_dri3b B, 0xfd, 0x36, 0x01
	ld bc, (xde)
	ld (xwa), bc
	st_dri3b A, 0xfd, 0x2a, 0x01
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
	st_dri3b A, 0xfd, 0x3e, 0x01
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
	st_dri3b W, 0xfd, 0x3e, 0x01
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
	st_dri3b A, 0xfd, 0x3e, 0x01
	ld_sril XWA, (xsp + 0x014e)
	calr GetClientBox
	st_dri3b A, 0xfd, 0x3e, 0x01
	ld wa, (xbc + 2)
	st_dri3w WA, 0xfd, 0x30, 0x01
	ld wa, (xbc + 6)
	st_dri3w WA, 0xfd, 0x2c, 0x01
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
	st_dri3b W, 0xfd, 0x2e, 0x01
	ld bc, (xbc)
	ld (xwa), bc
	ld xbc, (xhl)
	ld xhl, (xbc)
	add xhl, xde
	st_dri3b A, 0xfd, 0x2a, 0x01
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
	st_dri3b A, 0xfd, 0x3e, 0x01
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
	st_dri3b W, 0xfd, 0x3e, 0x01
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
	cp_sril_rm XBC, 0xfd, 0x46, 0x01
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
	st_dri3b W, 0xfd, 0x3e, 0x01
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
	st_dri3b A, 0xfd, 0x32, 0x01
	calr GetBoxCenter
	calr GetDialFocus
	cp_sril_rm XHL, 0xfd, 0x4e, 0x01
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
	st_dri3b C, 0xfd, 0x3e, 0x01
	st_dri3b A, 0xfd, 0x32, 0x01
	ld xix, (xsp + 20)
	ld xwa, (xix + 28)
	push xwa
	pushm (xix + 32)
	ld xwa, xix
	pushm (xwa + 22)
	ld a, (xwa + 34)
	extz wa
	pushw wa
	pushw de
	ld xde, (xsp + 40)
	ld xwa, xhl
	call DrawStringReverse
	jrl PsGridBox_ReturnZero
	lda xde, (xsp + 24)
	ld_sril XWA, (xsp + 0x0146)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xde), wa
	lda xbc, (xde + 2)
	ld_sril XWA, (xsp + 0x0146)
	ld (xbc), wa
	lda xwa, (xsp + 32)
	ld (xde + 4), xwa
	pushm (xbc)
	pushm (xde)
	pushw 0xea
	pushw 0xa1ec
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	lda xde, (xsp + 24)
	ld_sril XWA, (xsp + 0x014e)
	ld xbc, 0x1e0008c
	jrl PsGridBox_DispatchEvent
	ld xwa, Data_SoundEditorCharsLayout_0x320_
	jr PsGridBox_Scroll_CopyStr
	ld xwa, Data_SoundEditorCharsLayout_0x340_

PsGridBox_Scroll_CopyStr:
	push xwa
	ld_sril XWA, (xsp + 0x014a)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl PsGridBox_ReturnZero
	ld_sril XWA, (xsp + 0x014e)
	call GetViewInstance
	ld (xsp + 20), xhl
	ld_sril XWA, (xsp + 0x0146)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld iz, wa
	cp iz, 0xffff
	jr nz, PsGridBox_Scroll_DefaultRow
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 46)
	ld iz, (xwa)

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
	ldi_werp 0xe6, 0
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
	cp_sril_rm XWA, 0xfd, 0x46, 0x01
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
	st_dri3b L, 0xfd, 0x4e, 0x01
	ret

