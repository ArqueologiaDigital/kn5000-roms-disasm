; =============================================================================
; RVari (Rhythm Variation) Screen
; =============================================================================
;
; Rhythm variation selection screen renderer and interaction
; handlers. Displays and navigates rhythm variation options
; with type-specific rendering (Type E/Other).
; =============================================================================

RVari_Select_CalcVisibleCount:
	ld (xsp + 4), 0x9
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld bc, (xbc)
	sub bc, wa
	jr ge, RVari_Select_CheckTypeE
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 4), c

RVari_Select_CheckTypeE:
	ld xwa, (xiz + 56)
	cpw (xwa), 0xe
	jrl nz, RVari_Select_TypeNotE
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	exts xwa
	divs wa, 0x4
	inc 1, wa
	cp wa, (xbc)
	jrl nz, RVari_Select_OtherItem
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	exts xwa
	divs wa, 0xa
	ldto_werp HL, 0xe2
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelectE_FirstItem_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	jr RVari_SelectE_FirstItem_Draw

RVari_SelectE_FirstItem_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137

RVari_SelectE_FirstItem_Draw:
	lda xwa, (xsp+536)
	ld bc, 0:i3
	ldw de, 0xf5
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 64)
	ld bc, (xbc)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+283)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x22, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	exts xwa
	divs wa, 0x4
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_SelectE_SecondItem_Setup
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	extz wa
	div a, 0xa
	ld e, w
	extz de
	add de, bc
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	cp wa, de
	jr nz, RVari_SelectE_SecondItem_Setup
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_SelectE_SecondItem_Setup:
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelectE_SecondItem_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x1e
	jr RVari_SelectE_SecondItem_Draw

RVari_SelectE_SecondItem_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0xbe

RVari_SelectE_SecondItem_Draw:
	dec_sriw 0, 0xfd, 0x16, 0x02
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	extz wa
	div a, 0xa
	ld a, w
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw RVari_SelectE_SecondItem_Draw_Str_Fmtd@hi16
	pushw RVari_SelectE_SecondItem_Draw_Str_Fmtd@lo16
	lda xwa, (xsp + 26)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp + 20)
	ld xwa, 3:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	add wa, 0xc
	ld (xbc), wa
	lda xde, (xsp+536)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelectE_SecondItem_BtnNotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_SelectE_SecondItem_BtnDraw

RVari_SelectE_SecondItem_BtnNotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_SelectE_SecondItem_BtnDraw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+277)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify

RVari_Select_OtherItem:
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	exts xwa
	divs wa, 0x4
	inc 1, wa
	cp wa, (xbc)
	jrl nz, RVari_Select_ReturnZero
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	exts xwa
	divs wa, 0xa
	ldto_werp HL, 0xe2
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelectO_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	jr RVari_SelectO_Item_Draw

RVari_SelectO_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137

RVari_SelectO_Item_Draw:
	lda xwa, (xsp+536)
	ldw bc, 0xc1
	ld de, 7:i3
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 60)
	ld bc, (xbc)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+283)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x22, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	exts xwa
	divs wa, 0x4
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_SelectO_SecondItem_Setup
	ld xwa, (xiz + 44)
	ld de, (xwa)
	muls de, 0xa
	sub de, 0xa
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	add hl, de
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	cp wa, hl
	jr nz, RVari_SelectO_SecondItem_Setup
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_SelectO_SecondItem_Setup:
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelectO_SecondItem_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x1e
	jr RVari_SelectO_SecondItem_Draw

RVari_SelectO_SecondItem_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0xbe

RVari_SelectO_SecondItem_Draw:
	dec_sriw 0, 0xfd, 0x16, 0x02
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	extz wa
	div a, 0xa
	ld a, w
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw RVari_SelectO_SecondItem_Draw_Str_Fmtd@hi16
	pushw RVari_SelectO_SecondItem_Draw_Str_Fmtd@lo16
	lda xwa, (xsp + 26)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp + 20)
	ld xwa, 3:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	add wa, 0xc
	ld (xbc), wa
	lda xde, (xsp+536)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelectO_SecondBtn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_SelectO_SecondBtn_Draw

RVari_SelectO_SecondBtn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_SelectO_SecondBtn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+277)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	jrl RVari_Select_ReturnZero

RVari_Select_TypeNotE:
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xbc)
	jrl nz, RVari_SelNE_SecondItem
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	ldto_werp HL, 0xe2
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelNE_FirstItem_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	jr RVari_SelNE_FirstItem_Draw

RVari_SelNE_FirstItem_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137

RVari_SelNE_FirstItem_Draw:
	lda xwa, (xsp+536)
	ld bc, 0:i3
	ldw de, 0xf5
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 44)
	ld bc, (xbc)
	dec 1, bc
	mul c, 0xa
	ld e, c
	ld xbc, (xiz + 64)
	ld bc, (xbc)
	extz bc
	div c, 0xa
	ld c, b
	add c, e
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+283)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x22, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_SelNE_FirstItem_Deselect
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld e, w
	extz de
	add de, bc
	ld xwa, (xiz + 60)
	cp (xwa), de
	jr nz, RVari_SelNE_FirstItem_Deselect
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_SelNE_FirstItem_Deselect:
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelNE_FirstBtn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_SelNE_FirstBtn_Draw

RVari_SelNE_FirstBtn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_SelNE_FirstBtn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+277)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify

RVari_SelNE_SecondItem:
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xbc)
	jrl nz, RVari_Select_ReturnZero
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	ldto_werp HL, 0xe2
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelNE_SecondItem_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	jr RVari_SelNE_SecondItem_Draw

RVari_SelNE_SecondItem_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137

RVari_SelNE_SecondItem_Draw:
	lda xwa, (xsp+536)
	ldw bc, 0xc1
	ld de, 7:i3
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 44)
	ld bc, (xbc)
	dec 1, bc
	mul c, 0xa
	ld e, c
	ld xbc, (xiz + 60)
	ld bc, (xbc)
	extz bc
	div c, 0xa
	ld c, b
	add c, e
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+283)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x22, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_SelNE_SecondItem_Deselect
	ld xwa, (xiz + 44)
	ld de, (xwa)
	muls de, 0xa
	sub de, 0xa
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	extz wa
	div a, 0xa
	ld a, w
	extz wa
	add wa, de
	cp (xbc), wa
	jr nz, RVari_SelNE_SecondItem_Deselect
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_SelNE_SecondItem_Deselect:
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_SelNE_SecondBtn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_SelNE_SecondBtn_Draw

RVari_SelNE_SecondBtn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_SelNE_SecondBtn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+277)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify

RVari_Select_ReturnZero:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_Confirm:
	ld XWA, (xsp + 0x0228)
	ld XBC, (xsp + 0x0224)
	ld XDE, (xsp + 0x0220)
	call InheritedProc
	ld XWA, (xsp + 0x0228)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xhl + 56)
	cpw (xwa), 0xf
	jrl nz, RVari_Confirm_TypeNotF
	ld (xsp + 8), 0x0

RVari_Confirm_TypeF_Loop:
	ld xde, (xiz + 56)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	srl a, 2
	sll a, 2
	add a, (xsp + 8)
	ld c, a
	extz bc
	ld wa, (xde)
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+282)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x21, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp BC, 0xe2
	ld a, (xsp + 8)
	extz wa
	cp wa, bc
	jr nz, RVari_ConfirmF_CheckSelected
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_ConfirmF_CheckSelected:
	ld a, (xsp + 8)
	extz wa
	lda xbc, (NakaInst_Rock_Pop_0x24:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld a, (xsp + 8)
	extz wa
	lda xbc, (NakaInst_Rock_Pop_0x24:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_ConfirmF_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x1e
	jr RVari_ConfirmF_Item_Draw

RVari_ConfirmF_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0xbe

RVari_ConfirmF_Item_Draw:
	dec_sriw 0, 0xfd, 0x16, 0x02
	ld a, (xsp + 8)
	extz wa
	sla wa, 2
	lda xbc, (ParamStr_Table_04:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw RVari_ConfirmF_Item_Draw_Str_Fmts@hi16
	pushw RVari_ConfirmF_Item_Draw_Str_Fmts@lo16
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp + 20)
	ld xwa, 3:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	add wa, 0xc
	ld (xbc), wa
	lda xde, (xsp+536)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_ConfirmF_Btn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_ConfirmF_Btn_Draw

RVari_ConfirmF_Btn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_ConfirmF_Btn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+276)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	incm8 1, (xsp + 8)
	cp (xsp + 8), 0x3
	jrl ule, RVari_Confirm_TypeF_Loop
	ld (xsp + 8), 0x0

RVari_Confirm_TypeF_SubItems:
	ld a, (xsp + 8)
	extz wa
	lda xbc, (NakaInst_Rock_Pop_0x28:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld a, (xsp + 8)
	extz wa
	lda xbc, (NakaInst_Rock_Pop_0x28:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xwa, (xsp+536)
	lda xde, (xsp+532)
	lda xhl, (xde + 2)
	ld bc, (xhl)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xhl)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x2d
	ldw (xwa + 4), 0xac
	ld c, (xsp + 8)
	extz bc
	sla bc, 2
	lda xhl, (RVari_Select_CheckSameBank_PtrTable:24)
	ld_sril3 XHL, 0x07, 0xec, 0xe4
	ld xbc, 1:i3
	push xbc
	pushw 0xff
	pushw 0xf7
	ld xbc, xde
	ld xde, xhl
	call DrawStringLeftJustify
	incm8 1, (xsp + 8)
	cp (xsp + 8), 0x2
	jrl ule, RVari_Confirm_TypeF_SubItems
	jrl RVari_Confirm_ReturnZero

RVari_Confirm_TypeNotF:
	lda xwa, (xsp+536)
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xf5
	ldw (xwa + 4), 0x13b
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	lda xde, (xsp+536)
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	lda xhl, (xsp+532)
	ld (xhl), bc
	ld bc, (xde + 2)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	inc 1, bc
	ld (xhl + 2), bc
	ld xwa, (xiz + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	pushw wa
	ld xwa, (xiz + 44)
	pushm (xwa)
	pushw RVari_Confirm_TypeNotF_Str_PAGE_Fmtd_Fmtd@hi16
	pushw RVari_Confirm_TypeNotF_Str_PAGE_Fmtd_Fmtd@lo16
	lda xwa, (xsp+284)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	lda xwa, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+276)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringCentered
	ld (xsp + 4), 0x9
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld bc, (xbc)
	sub bc, wa
	jr ge, RVari_Confirm_CalcVisible
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 4), c

RVari_Confirm_CalcVisible:
	ld xwa, (xiz + 56)
	cpw (xwa), 0xe
	jrl nz, RVari_ConfirmNE_Setup
	ld (xsp + 8), 0x0
	cp (xsp + 4), 0x0
	jrl c, RVari_Confirm_ReturnZero

RVari_ConfirmE_Loop:
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 44)
	ld bc, (xbc)
	dec 1, bc
	mul c, 0x28
	ld e, c
	ld c, (xsp + 8)
	sll c, 2
	add c, e
	ld e, c
	ld xbc, (xiz + 60)
	ld bc, (xbc)
	exts xbc
	divs bc, 0x4
	ldto_werp BC, 0xe6
	add c, e
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+283)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x22, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	exts xwa
	divs wa, 0x4
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_ConfirmE_CheckSelected
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld e, (xsp + 8)
	extz de
	add de, bc
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	cp wa, de
	jr nz, RVari_ConfirmE_CheckSelected
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_ConfirmE_CheckSelected:
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld l, (xsp + 8)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld l, (xsp + 8)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_ConfirmE_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x1e
	jr RVari_ConfirmE_Item_Draw

RVari_ConfirmE_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0xbe

RVari_ConfirmE_Item_Draw:
	dec_sriw 0, 0xfd, 0x16, 0x02
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld a, (xsp + 8)
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw RVari_ConfirmE_Item_Draw_Str_Fmtd@hi16
	pushw RVari_ConfirmE_Item_Draw_Str_Fmtd@lo16
	lda xwa, (xsp + 26)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp + 20)
	ld xwa, 3:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	add wa, 0xc
	ld (xbc), wa
	lda xde, (xsp+536)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_ConfirmE_Btn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_ConfirmE_Btn_Draw

RVari_ConfirmE_Btn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_ConfirmE_Btn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+277)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	incm8 1, (xsp + 8)
	ld a, (xsp + 8)
	cp a, (xsp + 4)
	jrl ule, RVari_ConfirmE_Loop
	jrl RVari_Confirm_ReturnZero

RVari_ConfirmNE_Setup:
	ld (xsp + 8), 0x0
	cp (xsp + 4), 0x0
	jrl c, RVari_Confirm_ReturnZero

RVari_ConfirmNE_Loop:
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 44)
	ld bc, (xbc)
	dec 1, bc
	mul c, 0xa
	add c, (xsp + 8)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	lda xwa, (xsp+283)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x22, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_ConfirmNE_CheckSelected
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld e, (xsp + 8)
	extz de
	add de, bc
	ld xwa, (xiz + 60)
	cp (xwa), de
	jr nz, RVari_ConfirmNE_CheckSelected
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_ConfirmNE_CheckSelected:
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld l, (xsp + 8)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld l, (xsp + 8)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_ConfirmNE_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_ConfirmNE_Item_Draw

RVari_ConfirmNE_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_ConfirmNE_Item_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+277)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	incm8 1, (xsp + 8)
	ld a, (xsp + 8)
	cp a, (xsp + 4)
	jrl ule, RVari_ConfirmNE_Loop

RVari_Confirm_ReturnZero:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_EnumNotify:
	ld XWA, (xsp + 0x0228)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0220)
	ld (xsp + 6), xwa
	ld xwa, (xhl + 56)
	cpw (xwa), 0xf
	jrl nz, RVari_EnumNotify_CalcVisible
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp BC, 0xe2
	ld xwa, (xsp + 6)
	ld a, (xwa)
	extz wa
	cp wa, bc
	jr nz, RVari_EnumNotifyF_CheckSelected
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_EnumNotifyF_CheckSelected:
	ld xwa, (xsp + 6)
	ld a, (xwa)
	extz wa
	lda xbc, (NakaInst_Rock_Pop_0x24:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld xwa, (xsp + 6)
	ld a, (xwa)
	extz wa
	lda xbc, (NakaInst_Rock_Pop_0x24:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_EnumNotifyF_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x1e
	jr RVari_EnumNotifyF_Item_Draw

RVari_EnumNotifyF_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0xbe

RVari_EnumNotifyF_Item_Draw:
	dec_sriw 0, 0xfd, 0x16, 0x02
	ld xwa, (xsp + 6)
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda xbc, (ParamStr_Table_04:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1672
	lda xwa, (xsp+284)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+276)
	ld xwa, 3:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	add wa, 0xc
	ld (xbc), wa
	lda xde, (xsp+536)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_EnumNotifyF_Btn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_EnumNotifyF_Btn_Draw

RVari_EnumNotifyF_Btn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_EnumNotifyF_Btn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	ld xwa, (xsp + 6)
	lda xde, (xwa + 1)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	jrl RVari_EnumNotify_ReturnZero

RVari_EnumNotify_CalcVisible:
	ld (xsp + 4), 0x9
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld bc, (xbc)
	sub bc, wa
	jr ge, RVari_EnumNotify_SetupDisplay
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 4), c

RVari_EnumNotify_SetupDisplay:
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xsp + 6)
	ld l, (xwa)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 4)
	srl c, 1
	extz bc
	sla bc, 2
	lda xde, (0x03f214:24)
	ld xwa, (xsp + 6)
	ld l, (xwa)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda xbc, (xsp+532)
	call GetEditSwPoint
	ld xwa, (xiz + 56)
	cpw (xwa), 0xe
	jrl nz, RVari_EnumNotifyNE_CheckSelected
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	exts xwa
	divs wa, 0x4
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_EnumNotifyE_CheckSelected
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xsp + 6)
	ld e, (xwa)
	extz de
	add de, bc
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	cp wa, de
	jr nz, RVari_EnumNotifyE_CheckSelected
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_EnumNotifyE_CheckSelected:
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_EnumNotifyE_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x1e
	jr RVari_EnumNotifyE_Item_Draw

RVari_EnumNotifyE_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0xbe

RVari_EnumNotifyE_Item_Draw:
	dec_sriw 0, 0xfd, 0x16, 0x02
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xsp + 6)
	ld a, (xwa)
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xed
	pushw 0x1676
	lda xwa, (xsp+282)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	lda xde, (xsp+276)
	ld xwa, 3:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	add wa, 0xc
	ld (xbc), wa
	lda xde, (xsp+536)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_EnumNotifyE_Btn_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_EnumNotifyE_Btn_Draw

RVari_EnumNotifyE_Btn_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_EnumNotifyE_Btn_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	ld xwa, (xsp + 6)
	lda xde, (xwa + 1)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	jrl RVari_EnumNotify_ReturnZero

RVari_EnumNotifyNE_CheckSelected:
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xbc)
	jr nz, RVari_EnumNotifyNE_Setup
	ld xwa, (xiz + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xsp + 6)
	ld e, (xwa)
	extz de
	add de, bc
	ld xwa, (xiz + 60)
	cp (xwa), de
	jr nz, RVari_EnumNotifyNE_Setup
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_EnumNotifyNE_Setup:
	lda xde, (xsp+536)
	lda xhl, (xsp+532)
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	cpw (xhl), 0x0
	jr nz, RVari_EnumNotifyNE_Item_NotFirst
	lda xwa, (xsp+536)
	ldw (xwa), 0x1c
	ldw (xwa + 4), 0xb0
	jr RVari_EnumNotifyNE_Item_Draw

RVari_EnumNotifyNE_Item_NotFirst:
	lda xwa, (xsp+536)
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b

RVari_EnumNotifyNE_Item_Draw:
	lda xhl, (xsp+536)
	lda xbc, (xsp+532)
	ld xwa, (xsp + 6)
	lda xde, (xwa + 1)
	ld xwa, 1:i3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify

RVari_EnumNotify_ReturnZero:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK:
	ld XWA, (xsp + 0x0228)
	ld XBC, (xsp + 0x0224)
	ld XDE, (xsp + 0x0220)
	call InheritedProc
	ld XWA, (xsp + 0x0228)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xhl + 56)
	cpw (xwa), 0xf
	jrl nz, RVari_OK_TypeE_CalcVisible
	ld XBC, (xsp + 0x0220)
	ld xwa, xbc
	cp xwa, 0xc
	jrl z, RVari_OK_TypeF_InputC
	cp xbc, 0xb
	jrl z, RVari_OK_TypeF_InputB
	cp xbc, 0xa
	jrl z, RVari_OK_TypeF_InputA
	cp xbc, 0x9
	jrl z, RVari_OK_TypeF_Input9
	cp xbc, 0x8b
	jrl z, RVari_OK_TypeF_Input8B
	cp xbc, 0x8a
	jr z, RVari_OK_TypeF_Input8A
	cp xbc, 0x89
	jrl nz, RVari_OK_PageScroll
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeF_Input8A:
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	inc 4, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeF_Input8B:
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	inc 8, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeF_Input9:
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	sla wa, 2
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeF_InputA:
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	sla wa, 2
	inc 1, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeF_InputB:
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	sla wa, 2
	inc 2, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeF_InputC:
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	sla wa, 2
	inc 3, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_CalcVisible:
	ld (xsp + 4), 0x9
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld bc, (xbc)
	sub bc, wa
	jr ge, RVari_OK_TypeE_DispatchInput
	ld xbc, (xiz + 52)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 4), c

RVari_OK_TypeE_DispatchInput:
	ld xwa, (xiz + 56)
	cpw (xwa), 0xe
	jrl nz, RVari_OK_TypeNE_DispatchInput
	ld XBC, (xsp + 0x0220)
	ld xwa, xbc
	cp xwa, 0xc
	jrl z, RVari_OK_TypeE_InputC
	cp xbc, 0xb
	jrl z, RVari_OK_TypeE_InputB
	cp xbc, 0xa
	jrl z, RVari_OK_TypeE_InputA
	cp xbc, 0x9
	jrl z, RVari_OK_TypeE_Input9
	cp xbc, 0x8
	jrl z, RVari_OK_TypeE_Input8
	cp xbc, 0x8c
	jrl z, RVari_OK_TypeE_Input8C
	cp xbc, 0x8b
	jrl z, RVari_OK_TypeE_Input8B
	cp xbc, 0x8a
	jrl z, RVari_OK_TypeE_Input8A
	cp xbc, 0x89
	jr z, RVari_OK_TypeE_Input89
	cp xbc, 0x88
	jrl nz, RVari_OK_PageScroll
	ld a, (xsp + 4)
	extz wa
	ld bc, 0:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input88_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp DE, 0xe2
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x28
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input88_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_Input89:
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input89_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp DE, 0xe2
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x24
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input89_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_Input8A:
	ld a, (xsp + 4)
	extz wa
	ld bc, 2:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input8A_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp DE, 0xe2
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x20
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input8A_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_Input8B:
	ld a, (xsp + 4)
	extz wa
	ld bc, 3:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input8B_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp DE, 0xe2
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x1c
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input8B_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_Input8C:
	ld a, (xsp + 4)
	extz wa
	ld bc, 4:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input8C_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp DE, 0xe2
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x18
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input8C_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_Input8:
	ld a, (xsp + 4)
	extz wa
	ld bc, 0:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input8_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 0:i3
	calr VariScreen_CalcValidNoteRow
	sll l, 2
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x28
	ld de, wa
	add de, hl
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input8_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_Input9:
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_Input9_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	calr VariScreen_CalcValidNoteRow
	sll l, 2
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x28
	ld de, wa
	add de, hl
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_Input9_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_InputA:
	ld a, (xsp + 4)
	extz wa
	ld bc, 2:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_InputA_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 2:i3
	calr VariScreen_CalcValidNoteRow
	sll l, 2
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x28
	ld de, wa
	add de, hl
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_InputA_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_InputB:
	ld a, (xsp + 4)
	extz wa
	ld bc, 3:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_InputB_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 3:i3
	calr VariScreen_CalcValidNoteRow
	sll l, 2
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x28
	ld de, wa
	add de, hl
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_InputB_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeE_InputC:
	ld a, (xsp + 4)
	extz wa
	ld bc, 4:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeE_InputC_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 4:i3
	calr VariScreen_CalcValidNoteRow
	sll l, 2
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sla wa, 2
	sub wa, 0x28
	ld de, wa
	add de, hl
	ld xbc, (xiz + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xe2
	add wa, de
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeE_InputC_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_DispatchInput:
	ld XBC, (xsp + 0x0220)
	ld xwa, xbc
	cp xwa, 0xc
	jrl z, RVari_OK_TypeNE_InputC
	cp xbc, 0xb
	jrl z, RVari_OK_TypeNE_InputB
	cp xbc, 0xa
	jrl z, RVari_OK_TypeNE_InputA
	cp xbc, 0x9
	jrl z, RVari_OK_TypeNE_Input9
	cp xbc, 0x8
	jrl z, RVari_OK_TypeNE_Input8
	cp xbc, 0x8c
	jrl z, RVari_OK_TypeNE_Input8C
	cp xbc, 0x8b
	jrl z, RVari_OK_TypeNE_Input8B
	cp xbc, 0x8a
	jrl z, RVari_OK_TypeNE_Input8A
	cp xbc, 0x89
	jr z, RVari_OK_TypeNE_Input89
	cp xbc, 0x88
	jrl nz, RVari_OK_PageScroll
	ld a, (xsp + 4)
	extz wa
	ld bc, 0:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input88_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input88_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_Input89:
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input89_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0x9
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input89_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_Input8A:
	ld a, (xsp + 4)
	extz wa
	ld bc, 2:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input8A_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 8, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input8A_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_Input8B:
	ld a, (xsp + 4)
	extz wa
	ld bc, 3:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input8B_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 7, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input8B_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_Input8C:
	ld a, (xsp + 4)
	extz wa
	ld bc, 4:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input8C_Done
	ld xde, (xiz + 64)
	lda xbc, (xiz + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 6, wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input8C_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_Input8:
	ld a, (xsp + 4)
	extz wa
	ld bc, 0:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input8_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 0:i3
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, hl
	ld xbc, (xiz + 60)
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input8_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_Input9:
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_Input9_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, hl
	ld xbc, (xiz + 60)
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_Input9_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_InputA:
	ld a, (xsp + 4)
	extz wa
	ld bc, 2:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_InputA_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 2:i3
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, hl
	ld xbc, (xiz + 60)
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_InputA_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_InputB:
	ld a, (xsp + 4)
	extz wa
	ld bc, 3:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_InputB_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 3:i3
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, hl
	ld xbc, (xiz + 60)
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_InputB_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_TypeNE_InputC:
	ld a, (xsp + 4)
	extz wa
	ld bc, 4:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, RVari_OK_TypeNE_InputC_Done
	ld xbc, (xiz + 64)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 4)
	extz wa
	ld bc, 4:i3
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, hl
	ld xbc, (xiz + 60)
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0228)
	calr RVari_UpdateDisplayNotify

RVari_OK_TypeNE_InputC_Done:
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_OK_PageScroll:
	ld xwa, (xiz + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	ld (0x0340bc:24), wa
	ld XWA, (xsp + 0x0220)
	cp xwa, 0x10
	jr nz, RVari_OK_CheckPageDown
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	cp wa, (0x0340bc:24)
	jr ge, RVari_OK_PageUp_AtMax
	ld xwa, (xiz + 44)
	incw 1, (xwa)
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	jr RVari_OK_CheckPageDown

RVari_OK_PageUp_AtMax:
	cpw (0x0340bc:24), 1
	jr le, RVari_OK_CheckPageDown
	ld xwa, (xiz + 44)
	ldw (xwa), 0x1
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent

RVari_OK_CheckPageDown:
	ld XWA, (xsp + 0x0220)
	cp xwa, 0x90
	jr nz, RVari_OK_ForwardDefault
	ld xwa, (xiz + 44)
	cpw (xwa), 0x1
	jr le, RVari_OK_PageDown_AtMin
	ld xwa, (xiz + 44)
	decm 1, (xwa)
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	jr RVari_OK_ForwardDefault

RVari_OK_PageDown_AtMin:
	cpw (0x0340bc:24), 1
	jr le, RVari_OK_ForwardDefault
	ld xbc, (xiz + 44)
	ld wa, (0x0340bc:24)
	ld (xbc), wa
	ld XWA, (xsp + 0x0228)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent

RVari_OK_ForwardDefault:
	ld XWA, (xsp + 0x0228)
	ld XBC, (xsp + 0x0224)
	ld XDE, (xsp + 0x0220)
	call InheritedProc
	jr RVari_Epilogue

RVari_Default:
	ld XWA, (xsp + 0x0228)
	ld XBC, (xsp + 0x0224)
	ld XDE, (xsp + 0x0220)
	call InheritedProc

RVari_Epilogue:
	pop xiz
	lda xsp, (xsp+552)
	ret

RVari_UpdateDisplayNotify:
	dec 4, xsp
	push xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 48)
	ld wa, (xwa)
	ld (xiz), a
	ld (xiz + 1), 0x0
	ld xwa, (xbc + 56)
	ld wa, (xwa)
	ld (xiz + 2), a
	ld xwa, (xbc + 60)
	ld wa, (xwa)
	ld (xiz + 3), a
	ld xwa, NAKA_MAINFUNC_MainVariSet
	ld xbc, EVT_VARI_WRITE
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call MainFuncCall
	pop xiz
	inc 4, xsp
	ret
RVari_UpdateNotify_End:

