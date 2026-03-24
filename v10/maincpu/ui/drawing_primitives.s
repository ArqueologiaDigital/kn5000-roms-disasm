; =============================================================================
; Drawing Primitives
; =============================================================================
;
; Low-level drawing routines: Bresenham line drawing, rectangle
; fill, and reverse string rendering. Used by higher-level UI
; widgets for all graphical output.
; =============================================================================

DrawLine_Epilogue:
	popw iz
	inc 6, xsp
	ret

; =============================================================================
; DrawLine - Draw a line between two points (Bresenham algorithm)
;
; Draws a line from point A to point B on OFFSCREEN_BUFFER_1 (0x43c00).
; Uses Bresenham's line algorithm with separate fast paths for horizontal,
; vertical, and diagonal lines.
;
; Input:
;   XWA = pointer to point A: word[0]=x1, word[2]=y1
;   XBC = pointer to point B: word[0]=x2, word[2]=y2
;   DE  = color index (low byte)
;
; Special color 0xf5 reads the pixel from a secondary buffer instead of
; using a fixed color (used for pattern/texture line drawing).
;
; Calls SetChangeRect on completion to mark the drawn region as dirty.
; =============================================================================
DrawLine:
	dec 6, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawLine_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawLine_Return
	ld xwa, xiz
	ld xbc, (xsp + 6)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	jr DrawLine_Return

DrawLine_DeferredPath:
	ldw wa, 0xe
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawLine_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 6)
	ld xiy, xbc
	lda xix, (xwa + 8)
	ldiw
	ldiw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	calr DisplayCmd_DequeueAndExecute

DrawLine_Return:
	pop xiz
	inc 6, xsp
	ret

DrawLine_ParamBlock:
	.byte 0xb8, 0x04, 0x33, 0xb8, 0x08, 0x31, 0x98, 0x0c
	.byte 0x22, 0xd2, 0x4e, 0x04, 0x03, 0x3f, 0x00, 0x00
	.byte 0xb0, 0xf6, 0xeb, 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawLine_Impl:
	lda xsp, (xsp - 66)
	push xiz
	ld (xsp + 60), de
	ld (xsp + 62), xbc
	ld (xsp + 66), xwa
	ld xwa, (xsp + 66)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawLine_Impl_Return
	ld xwa, (xsp + 62)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawLine_Impl_Return
	ld xde, 0xffffffff
	ld xwa, (xsp + 62)
	ld bc, (xwa)
	ld xwa, (xsp + 66)
	cp bc, (xwa)
	jr le, DrawLine_Impl_XStepPositive
	lds32 xde, 1

DrawLine_Impl_XStepPositive:
	ld (xsp + 12), xde
	ld xbc, 0xffffffff
	ld xwa, (xsp + 62)
	ld wa, (xwa + 2)
	ld (xsp + 46), wa
	ld xwa, (xsp + 66)
	ld wa, (xwa + 2)
	ld (xsp + 44), wa
	ld wa, (xsp + 46)
	cp wa, (xsp + 44)
	jr le, DrawLine_Impl_YStepPositive
	lds32 xbc, 1

DrawLine_Impl_YStepPositive:
	ld (xsp + 16), xbc
	ld xwa, (xsp + 12)
	cp xwa, 0x1
	jr nz, DrawLine_Impl_CalcDxReverse
	ld xwa, (xsp + 62)
	ld bc, (xwa)
	ld xwa, (xsp + 66)
	sub bc, (xwa)
	jr DrawLine_Impl_CalcDxDone

DrawLine_Impl_CalcDxReverse:
	ld xwa, (xsp + 66)
	ld bc, (xwa)
	ld xwa, (xsp + 62)
	sub bc, (xwa)

DrawLine_Impl_CalcDxDone:
	exts xbc
	ld (xsp + 4), xbc
	ld xwa, (xsp + 16)
	cp xwa, 0x1
	jr nz, DrawLine_Impl_CalcDyReverse
	ld wa, (xsp + 46)
	sub wa, (xsp + 44)
	jr DrawLine_Impl_CalcDyDone

DrawLine_Impl_CalcDyReverse:
	ld wa, (xsp + 44)
	sub wa, (xsp + 46)

DrawLine_Impl_CalcDyDone:
	exts xwa
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, DrawLine_Impl_CopyStartPos
	ld xwa, (xsp + 8)
	or xwa, xwa
	jrl z, DrawLine_Impl_Return

DrawLine_Impl_CopyStartPos:
	ld xwa, (xsp + 66)
	ld xiy, xwa
	lda xix, (xsp + 56)
	ldiw
	ldiw
	lda_24 xwa, 0x043c00
	ld (xsp + 36), xwa
	ld (xsp + 20), xwa
	ld xwa, (xsp + 4)
	ld (xsp + 40), xwa
	sla xwa, 0
	ld (xsp + 40), xwa
	ld xbc, (xsp + 8)
	sla xbc, 0
	ld wa, (xsp + 46)
	exts xwa
	ld (xsp + 44), xwa
	ld xwa, xbc
	ld xbc, (xsp + 4)
	call Math_DivideSigned32
	ld (xsp + 28), xhl
	ld xwa, (xsp + 40)
	ld xbc, (xsp + 8)
	call Math_DivideSigned32
	ld (xsp + 24), xhl
	ld xbc, (xsp + 44)
	ld (xsp + 32), xbc
	ld xwa, xbc
	sll xwa, 2
	ld (xsp + 32), xwa
	add (xsp + 32), xbc
	ld xwa, (xsp + 32)
	sll xwa, 6
	ld (xsp + 32), xwa
	ld xwa, (xsp + 4)
	ld bc, wa
	inc 1, bc
	cpw (xsp + 60), 0xf5
	jrl z, DrawLine_Impl_PatternSetup
	or xwa, xwa
	jr nz, DrawLine_Impl_HorizontalCheck
	lds32 xbc, 0
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl lt, DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_VerticalLoop:
	lda xde, (xsp + 56)
	lda xwa, (xde + 2)
	ld (xsp + 44), xwa
	ld wa, (xwa)
	exts xwa
	ld xhl, xwa
	sll xhl, 2
	add xhl, xwa
	sll xhl, 6
	ld wa, (xde)
	exts xwa
	add xwa, xhl
	ld xde, (xsp + 36)
	add xde, xwa
	ld wa, (xsp + 60)
	ld (xde), a
	ld xde, (xsp + 16)
	ld xwa, (xsp + 44)
	add (xwa), de
	inc 1, xbc
	cp xbc, (xsp + 8)
	jr le, DrawLine_Impl_VerticalLoop
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_HorizontalCheck:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, DrawLine_Impl_SteepCheck
	ld wa, (xsp + 60)
	extz wa
	pushw bc
	pushw wa
	ld xwa, (xsp + 16)
	cp xwa, 0x1
	jr nz, DrawLine_Impl_HorzCalcNegDir
	lda xwa, (xsp + 60)
	ld bc, (xwa + 2)
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xbc, (xsp + 24)
	add xbc, xwa
	push xbc
	jr DrawLine_Impl_HorzMemset

DrawLine_Impl_HorzCalcNegDir:
	ld xwa, (xsp + 66)
	ld bc, (xwa)
	ld xwa, (xsp + 36)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xbc, (xsp + 24)
	add xbc, xwa
	push xbc

DrawLine_Impl_HorzMemset:
	call Memset
	inc 8, xsp
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_SteepCheck:
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 4)
	jr le, DrawLine_Impl_ShallowSetup
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 24)
	call Math_MultiplyAccumulate
	ld (xsp + 12), xhl
	lda xwa, (xsp + 56)
	ld (xsp + 40), xwa
	ld wa, (xwa)
	exts xwa
	ld (xsp + 4), xwa
	sla xwa, 0
	ld (xsp + 4), xwa
	ld xwa, 0x8000
	add (xsp + 4), xwa
	lds32 xbc, 0
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl lt, DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_SteepLoop:
	ld xhl, (xsp + 40)
	lda xwa, (xhl + 2)
	ld (xsp + 44), xwa
	ld wa, (xwa)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xhl)
	exts xwa
	add xwa, xde
	ld xde, (xsp + 36)
	add xde, xwa
	ld wa, (xsp + 60)
	ld (xde), a
	ld xwa, (xsp + 12)
	add (xsp + 4), xwa
	ld xde, (xsp + 4)
	sra xde, 0
	ld (xhl), de
	ld xde, (xsp + 16)
	ld xwa, (xsp + 44)
	add (xwa), de
	inc 1, xbc
	cp xbc, (xsp + 8)
	jr le, DrawLine_Impl_SteepLoop
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_ShallowSetup:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 28)
	call Math_MultiplyAccumulate
	ld (xsp + 16), xhl
	lda xwa, (xsp + 56)
	ld (xsp + 40), xwa
	inc 2, xwa
	ld (xsp + 44), xwa
	ld wa, (xwa)
	exts xwa
	ld (xsp + 8), xwa
	sla xwa, 0
	ld (xsp + 8), xwa
	ld xwa, 0x8000
	add (xsp + 8), xwa
	lds32 xbc, 0
	ld xwa, (xsp + 4)
	cp xwa, 0x0
	jrl lt, DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_ShallowLoop:
	ld xix, (xsp + 44)
	ld wa, (xix)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld xhl, (xsp + 40)
	ld wa, (xhl)
	exts xwa
	add xwa, xde
	ld xde, (xsp + 36)
	add xde, xwa
	ld wa, (xsp + 60)
	ld (xde), a
	ld xwa, (xsp + 16)
	add (xsp + 8), xwa
	ld xde, (xsp + 8)
	sra xde, 0
	ld (xix), de
	ld xde, (xsp + 12)
	add (xhl), de
	inc 1, xbc
	cp xbc, (xsp + 4)
	jr le, DrawLine_Impl_ShallowLoop
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_PatternSetup:
	lda xwa, (xsp + 56)
	ld (xsp + 40), xwa
	inc 2, xwa
	ld (xsp + 44), xwa
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, DrawLine_Impl_PatternNonVert
	lds32 xbc, 0
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl lt, DrawLine_Impl_BuildDirtyRect
	ld xwa, (xsp + 40)
	ld (xsp + 32), xwa
	ld xde, (xsp + 44)
	ld xiy, (xsp + 36)
	ld xix, (xsp + 40)
	ld xhl, (xsp + 16)

DrawLine_Impl_PatternVertLoop:
	ld wa, (xde)
	ld (xsp + 46), wa
	ld wa, (xsp + 46)
	exts xwa
	ld xiz, xwa
	sll xiz, 2
	add xiz, xwa
	sll xiz, 6
	ld xwa, (xsp + 32)
	ld wa, (xwa)
	exts xwa
	add xwa, xiz
	ld xiz, xiy
	add xiz, xwa
	ld wa, (xsp + 46)
	muls wa, 0x140
	add wa, (xix)
	extz xwa
	addda32_24 xwa, 0x030452
	ld a, (xwa)
	ld (xiz), a
	add (xde), hl
	inc 1, xbc
	cp xbc, (xsp + 8)
	jr le, DrawLine_Impl_PatternVertLoop
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_PatternNonVert:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, DrawLine_Impl_PatternDiagCheck
	pushw bc
	ld xwa, (xsp + 14)
	cp xwa, 0x1
	jr nz, DrawLine_Impl_PatternHorzNegDir
	ld xwa, (xsp + 46)
	ld wa, (xwa)
	ld (xsp + 48), wa
	ld bc, (xsp + 48)
	muls bc, 0x140
	ld xde, (xsp + 42)
	add bc, (xde)
	extz xbc
	addda32_24 xbc, 0x030452
	push xbc
	ld wa, (xsp + 52)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 26)
	add xbc, xwa
	push xbc
	jr DrawLine_Impl_PatternHorzMemcpy

DrawLine_Impl_PatternHorzNegDir:
	ld xwa, (xsp + 46)
	ld bc, (xwa)
	muls bc, 0x140
	ld xwa, (xsp + 42)
	add bc, (xwa)
	extz xbc
	addda32_24 xbc, 0x030452
	push xbc
	ld xwa, (xsp + 68)
	ld bc, (xwa)
	ld xwa, (xsp + 38)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xbc, (xsp + 26)
	add xbc, xwa
	push xbc

DrawLine_Impl_PatternHorzMemcpy:
	call Mem_Copy
	lda xsp, (xsp + 10)
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_PatternDiagCheck:
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 4)
	jrl le, DrawLine_Impl_PatternShallowSetup
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 24)
	call Math_MultiplyAccumulate
	ld (xsp + 12), xhl
	ld xwa, (xsp + 40)
	ld (xsp + 32), xwa
	ld wa, (xwa)
	exts xwa
	ld (xsp + 4), xwa
	sla xwa, 0
	ld (xsp + 4), xwa
	ld xwa, 0x8000
	add (xsp + 4), xwa
	lds32 xbc, 0
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl lt, DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_PatternSteepLoop:
	ld xhl, (xsp + 32)
	lda xwa, (xhl + 2)
	ld (xsp + 42), xwa
	ld wa, (xwa)
	ld (xsp + 46), wa
	ld wa, (xsp + 46)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xhl)
	st_dri3b B, 0x07, 0xe8, 0xe0
	ld xwa, (xsp + 36)
	add xwa, xde
	ld (xsp + 28), xwa
	ld de, (xsp + 46)
	muls de, 0x140
	add de, (xhl)
	ld wa, de
	extz xwa
	addda32_24 xwa, 0x030452
	ld xde, (xsp + 28)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xsp + 12)
	add (xsp + 4), xwa
	ld xde, (xsp + 4)
	sra xde, 0
	ld (xhl), de
	ld xde, (xsp + 16)
	ld xwa, (xsp + 42)
	add (xwa), de
	inc 1, xbc
	cp xbc, (xsp + 8)
	jr le, DrawLine_Impl_PatternSteepLoop
	jrl DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_PatternShallowSetup:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 28)
	call Math_MultiplyAccumulate
	ld (xsp + 16), xhl
	ld xwa, (xsp + 40)
	ld (xsp + 32), xwa
	ld xwa, (xsp + 44)
	ld (xsp + 40), xwa
	ld wa, (xwa)
	exts xwa
	ld (xsp + 8), xwa
	sla xwa, 0
	ld (xsp + 8), xwa
	ld xwa, 0x8000
	add (xsp + 8), xwa
	lds32 xbc, 0
	ld xwa, (xsp + 4)
	cp xwa, 0x0
	jr lt, DrawLine_Impl_BuildDirtyRect

DrawLine_Impl_PatternShallowLoop:
	ld xix, (xsp + 40)
	ld wa, (xix)
	ld (xsp + 46), wa
	ld wa, (xsp + 46)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld xhl, (xsp + 32)
	ld wa, (xhl)
	st_dri3b B, 0x07, 0xe8, 0xe0
	ld xwa, (xsp + 36)
	add xwa, xde
	ld (xsp + 28), xwa
	ld de, (xsp + 46)
	muls de, 0x140
	add de, (xhl)
	ld wa, de
	extz xwa
	addda32_24 xwa, 0x030452
	ld xde, (xsp + 28)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xsp + 16)
	add (xsp + 8), xwa
	ld xde, (xsp + 8)
	sra xde, 0
	ld (xix), de
	ld xde, (xsp + 12)
	add (xhl), de
	inc 1, xbc
	cp xbc, (xsp + 4)
	jr le, DrawLine_Impl_PatternShallowLoop

DrawLine_Impl_BuildDirtyRect:
	lda xwa, (xsp + 48)
	ld xde, (xsp + 66)
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	ld bc, (xde)
	ld (xwa), bc
	ld xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa + 4), bc
	ld bc, (xde + 2)
	ld (xwa + 6), bc
	calr SetChangeRect

DrawLine_Impl_Return:
	pop xiz
	lda xsp, (xsp + 66)
	ret

; =============================================================================
; DrawLineEx - Extended line drawing with multiple drawing modes
;
; Like DrawLine, but supports all drawing modes from ModifyPixelEx:
; direct write, clear, OR, AND, XOR. Also supports the 0xf5 pattern mode
; which reads pixel colors from a secondary buffer.
;
; Input:
;   XWA = pointer to point A: word[0]=x1, word[2]=y1
;   XBC = pointer to point B: word[0]=x2, word[2]=y2
;   DE  = drawing mode (same codes as ModifyPixelEx: 0x201-0x205)
;
; Uses Bresenham's algorithm with optimized paths for axis-aligned and
; diagonal lines. Calls SetChangeRect to update dirty region.
; =============================================================================
DrawLineEx:
	lda xsp, (xsp - 50)
	push xiz
	ld (xsp + 44), de
	ld (xsp + 46), xbc
	ld (xsp + 50), xwa
	ld xwa, (xsp + 50)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawLineEx_Return
	ld xwa, (xsp + 46)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawLineEx_Return
	ld xde, 0xffffffff
	ld xwa, (xsp + 46)
	ld bc, (xwa)
	ld xwa, (xsp + 50)
	cp bc, (xwa)
	jr le, DrawLineEx_XStepPositive
	lds32 xde, 1

DrawLineEx_XStepPositive:
	ld (xsp + 12), xde
	ld xde, 0xffffffff
	ld xwa, (xsp + 46)
	inc 2, xwa
	ld (xsp + 20), xwa
	ld xwa, (xsp + 50)
	inc 2, xwa
	ld (xsp + 24), xwa
	ld xwa, (xsp + 20)
	ld bc, (xwa)
	ld xwa, (xsp + 24)
	ld hl, (xwa)
	cp bc, hl
	jr le, DrawLineEx_YStepPositive
	lds32 xde, 1

DrawLineEx_YStepPositive:
	ld (xsp + 16), xde
	ld xwa, (xsp + 12)
	cp xwa, 0x1
	jr nz, DrawLineEx_CalcDxReverse
	ld xwa, (xsp + 46)
	ld de, (xwa)
	ld xwa, (xsp + 50)
	sub de, (xwa)
	jr DrawLineEx_CalcDxDone

DrawLineEx_CalcDxReverse:
	ld xwa, (xsp + 50)
	ld de, (xwa)
	ld xwa, (xsp + 46)
	sub de, (xwa)

DrawLineEx_CalcDxDone:
	exts xde
	ld (xsp + 4), xde
	ld xwa, (xsp + 16)
	cp xwa, 0x1
	jr nz, DrawLineEx_CalcDyReverse
	sub bc, hl
	ld hl, bc
	jr DrawLineEx_CalcDyDone

DrawLineEx_CalcDyReverse:
	sub hl, bc

DrawLineEx_CalcDyDone:
	exts xhl
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, DrawLineEx_CopyStartPos
	ld xwa, (xsp + 8)
	or xwa, xwa
	jrl z, DrawLineEx_Return

DrawLineEx_CopyStartPos:
	ld xwa, (xsp + 50)
	ld xiy, xwa
	lda xix, (xsp + 40)
	ldiw
	ldiw
	ld xwa, (xsp + 4)
	or xwa, xwa
	jrl nz, DrawLineEx_HorzCheck
	lds32 xwa, 0
	ld (xsp + 28), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl lt, DrawLineEx_BuildDirtyRect

DrawLineEx_VertLoop:
	ld wa, (xsp + 58)
	cpw (xsp + 58), 0x205
	jr z, DrawLineEx_VertXorPixel
	cp wa, 0x201
	jrl nz, DrawLineEx_Return
	lda xwa, (xsp + 40)
	ld bc, (xwa + 2)
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xbc, 0x43c00
	add xbc, xwa
	ld wa, (xsp + 44)
	ld (xbc), a

DrawLineEx_VertAdvance:
	ld xwa, (xsp + 16)
	add (xsp + 42), wa
	lds32 xwa, 1
	add (xsp + 28), xwa
	ld xwa, (xsp + 28)
	cp xwa, (xsp + 8)
	jr le, DrawLineEx_VertLoop
	jrl DrawLineEx_BuildDirtyRect

DrawLineEx_VertXorPixel:
	lda xwa, (xsp + 40)
	ld bc, (xwa + 2)
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xbc, 0x43c00
	add xbc, xwa
	ld wa, (xsp + 44)
	xor (xbc), a
	jr DrawLineEx_VertAdvance

DrawLineEx_HorzCheck:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jrl nz, DrawLineEx_DiagSetup
	lds32 xwa, 0
	ld (xsp + 28), xwa
	ld xwa, (xsp + 4)
	cp xwa, 0x0
	jrl lt, DrawLineEx_BuildDirtyRect

DrawLineEx_HorzLoop:
	ld wa, (xsp + 58)
	cpw (xsp + 58), 0x205
	jr z, DrawLineEx_HorzXorPixel
	cp wa, 0x201
	jrl nz, DrawLineEx_Return
	lda xwa, (xsp + 40)
	ld bc, (xwa + 2)
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xbc, 0x43c00
	add xbc, xwa
	ld wa, (xsp + 44)
	ld (xbc), a

DrawLineEx_HorzAdvance:
	ld xwa, (xsp + 12)
	add (xsp + 40), wa
	lds32 xwa, 1
	add (xsp + 28), xwa
	ld xwa, (xsp + 28)
	cp xwa, (xsp + 4)
	jr le, DrawLineEx_HorzLoop
	jrl DrawLineEx_BuildDirtyRect

DrawLineEx_HorzXorPixel:
	lda xwa, (xsp + 40)
	ld bc, (xwa + 2)
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xbc, 0x43c00
	add xbc, xwa
	ld wa, (xsp + 44)
	xor (xbc), a
	jr DrawLineEx_HorzAdvance

DrawLineEx_DiagSetup:
	lda xwa, (xsp + 40)
	ld (xsp + 28), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 4)
	jrl le, DrawLineEx_ShallowSetup
	ld xwa, (xsp + 4)
	sla xwa, 0
	ld xbc, (xsp + 8)
	call Math_DivideSigned32
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, xiz
	call Math_MultiplyAccumulate
	ld (xsp + 12), xhl
	ld xbc, (xsp + 28)
	ld xwa, xbc
	ld wa, (xwa)
	exts xwa
	ld (xsp + 4), xwa
	sla xwa, 0
	ld (xsp + 4), xwa
	ld xwa, 0x8000
	add (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 28), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl lt, DrawLineEx_BuildDirtyRect

DrawLineEx_SteepLoop:
	ld iz, (xsp + 58)
	lda xiy, (xbc + 2)
	ld wa, (xiy)
	exts xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	sll xix, 6
	ld de, (xsp + 44)
	lda_24 xhl, 0x043c00
	cpw (xsp + 58), 0x205
	jr z, DrawLineEx_SteepXorPixel
	cp iz, 0x201
	jrl nz, DrawLineEx_Return
	ld wa, (xbc)
	exts xwa
	add xwa, xix
	add xhl, xwa
	ld (xhl), e

DrawLineEx_SteepAdvance:
	ld xwa, (xsp + 12)
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	sra xwa, 0
	ld (xbc), wa
	ld xwa, (xsp + 16)
	add (xiy), wa
	lds32 xwa, 1
	add (xsp + 28), xwa
	ld xwa, (xsp + 28)
	cp xwa, (xsp + 8)
	jr le, DrawLineEx_SteepLoop
	jrl DrawLineEx_BuildDirtyRect

DrawLineEx_SteepXorPixel:
	ld wa, (xbc)
	exts xwa
	add xwa, xix
	add xhl, xwa
	xor (xhl), e
	jr DrawLineEx_SteepAdvance

DrawLineEx_ShallowSetup:
	ld xwa, (xsp + 8)
	sla xwa, 0
	ld xbc, (xsp + 4)
	call Math_DivideSigned32
	ld xiz, xhl
	ld xwa, (xsp + 16)
	ld xbc, xiz
	call Math_MultiplyAccumulate
	ld (xsp + 16), xhl
	ld xbc, (xsp + 28)
	ld xwa, xbc
	lda xde, (xwa + 2)
	ld wa, (xde)
	exts xwa
	ld (xsp + 8), xwa
	sla xwa, 0
	ld (xsp + 8), xwa
	ld xwa, 0x8000
	add (xsp + 8), xwa
	lds32 xwa, 0
	ld (xsp + 28), xwa
	ld xwa, (xsp + 4)
	cp xwa, 0x0
	jr lt, DrawLineEx_BuildDirtyRect

DrawLineEx_ShallowLoop:
	ld iz, (xsp + 58)
	ld wa, (xsp + 44)
	ldfr_berp A, 0xf0
	lda_24 xiy, 0x043c00
	ld wa, (xde)
	exts xwa
	ld xhl, xwa
	sll xhl, 2
	add xhl, xwa
	sll xhl, 6
	cpw (xsp + 58), 0x205
	jr z, DrawLineEx_ShallowXorPixel
	cp iz, 0x201
	jr nz, DrawLineEx_Return
	ld wa, (xbc)
	exts xwa
	add xwa, xhl
	add xiy, xwa
	ldto_berp A, 0xf0
	ld (xiy), a

DrawLineEx_ShallowAdvance:
	ld xwa, (xsp + 16)
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	sra xwa, 0
	ld (xde), wa
	ld xwa, (xsp + 12)
	add (xbc), wa
	lds32 xwa, 1
	add (xsp + 28), xwa
	ld xwa, (xsp + 28)
	cp xwa, (xsp + 4)
	jr le, DrawLineEx_ShallowLoop

DrawLineEx_BuildDirtyRect:
	lda xwa, (xsp + 32)
	ld xbc, (xsp + 24)
	ld bc, (xbc)
	ld (xwa + 2), bc
	ld xbc, (xsp + 50)
	ld bc, (xbc)
	ld (xwa), bc
	ld xbc, (xsp + 46)
	ld bc, (xbc)
	ld (xwa + 4), bc
	ld xbc, (xsp + 20)
	ld bc, (xbc)
	ld (xwa + 6), bc
	calr SetChangeRect
	jr DrawLineEx_Return

DrawLineEx_ShallowXorPixel:
	ld wa, (xbc)
	exts xwa
	add xwa, xhl
	add xiy, xwa
	ldto_berp A, 0xf0
	xor (xiy), a
	jr DrawLineEx_ShallowAdvance

DrawLineEx_Return:
	pop xiz
	lda xsp, (xsp + 50)
	retd 0x2

; =============================================================================
; DrawBox - Draw a filled rectangle on the offscreen buffer
;
; Fills a rectangular area defined by a 4-word bounding box with a solid color.
; Clips to screen bounds (0,0)-(319,239).
;
; Input:
;   XWA = pointer to bounding box: {x_min, y_min, x_max, y_max} (4 words)
;   BC  = fill color (low byte)
;
; Output:
;   Rectangle filled in OFFSCREEN_BUFFER_1 (0x43c00)
;   SetChangeRect called with filled region
; =============================================================================
DrawBox:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBox_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBox_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr DrawBox_Impl
	jr DrawBox_Return

DrawBox_DeferredPath:
	ldw wa, 0xe
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawBox_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	calr DisplayCmd_DequeueAndExecute

DrawBox_Return:
	pop xiz
	inc 2, xsp
	ret

DrawBox_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0x98, 0x0c, 0x21, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawBox_Impl:
	lda xsp, (xsp - 16)
	pushw iz
	ld (xsp + 12), bc
	ld (xsp + 14), xwa
	ld xwa, (xsp + 14)
	lda xbc, (xwa + 4)
	ld wa, (xwa)
	cp wa, (xbc)
	jrl gt, DrawBox_Impl_Return
	ld xwa, (xsp + 14)
	lda xhl, (xwa + 2)
	lda xde, (xwa + 6)
	ld wa, (xhl)
	cp wa, (xde)
	jrl gt, DrawBox_Impl_Return
	cps wa, 0
	jr ge, DrawBox_Impl_ClipYMin
	ldw (xhl), 0x0

DrawBox_Impl_ClipYMin:
	ld xwa, (xsp + 14)
	cpw (xwa), 0x0
	jr ge, DrawBox_Impl_ClipXMin
	ldw (xwa), 0x0

DrawBox_Impl_ClipXMin:
	cpw (xbc), 0x140
	jr lt, DrawBox_Impl_ClipXMax
	ldw (xbc), 0x13f

DrawBox_Impl_ClipXMax:
	cpw (xde), 0xf0
	jr lt, DrawBox_Impl_ClipYMax
	ldw (xde), 0xef

DrawBox_Impl_ClipYMax:
	cpw (xsp + 12), 0xf7
	jrl z, DrawBox_Impl_Return
	ld hl, (xhl)
	ld wa, hl
	exts xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	sll xix, 6
	ld xwa, (xsp + 14)
	ld wa, (xwa)
	exts xwa
	add xwa, xix
	ld xiy, 0x43c00
	add xiy, xwa
	ld (xsp + 2), xiy
	ld bc, (xbc)
	ld xwa, (xsp + 14)
	sub bc, (xwa)
	inc 1, bc
	ld (xsp + 10), bc
	cpw (xsp + 12), 0xf5
	jr z, DrawBox_Impl_PatternSetup
	ld iz, hl
	cp hl, (xde)
	jr gt, DrawBox_Impl_SetChangeRect

DrawBox_Impl_FillRowLoop:
	pushm (xsp + 10)
	pushm (xsp + 14)
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	inc 8, xsp
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0x40, 0x01
	ld (xsp + 2), xwa
	inc 1, iz
	ld xwa, (xsp + 14)
	cp iz, (xwa + 6)
	jr le, DrawBox_Impl_FillRowLoop
	jr DrawBox_Impl_SetChangeRect

DrawBox_Impl_PatternSetup:
	ld32_24 xwa, 0x030452
	ld (xsp + 6), xwa
	ld xwa, (xsp + 14)
	ld wa, (xwa)
	exts xwa
	add xix, xwa
	add (xsp + 6), xix
	ld iz, hl
	cp hl, (xde)
	jr gt, DrawBox_Impl_SetChangeRect

DrawBox_Impl_PatternRowLoop:
	pushm (xsp + 10)
	ld xwa, (xsp + 8)
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x140
	add (xsp + 6), xwa
	ld xwa, (xsp + 2)
	st_dri3b W, 0xe1, 0x40, 0x01
	ld (xsp + 2), xwa
	inc 1, iz
	ld xwa, (xsp + 14)
	cp iz, (xwa + 6)
	jr le, DrawBox_Impl_PatternRowLoop

DrawBox_Impl_SetChangeRect:
	ld xwa, (xsp + 14)
	calr SetChangeRect

DrawBox_Impl_Return:
	popw iz
	lda xsp, (xsp + 16)
	ret

; =============================================================================
; DrawFrame - Draw a rectangle outline (border only, no fill)
;
; Draws the border of a rectangle defined by a 4-word bounding box.
; Renders 4 lines (top, bottom, left, right edges) using the specified color.
;
; Input:
;   XWA = pointer to bounding box: {x_min, y_min, x_max, y_max} (4 words)
;   BC  = border color (low byte)
; =============================================================================
DrawFrame:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawFrame_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawFrame_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr DrawFrame_Impl
	jr DrawFrame_Return

DrawFrame_DeferredPath:
	ldw wa, 0xe
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawFrame_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	calr DisplayCmd_DequeueAndExecute

DrawFrame_Return:
	pop xiz
	inc 2, xsp
	ret

DrawFrame_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0x98, 0x0c, 0x21, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawFrame_Impl:
	lda xsp, (xsp - 44)
	push xiz
	ld (xsp + 42), bc
	ld (xsp + 44), xwa
	ld xwa, (xsp + 44)
	inc 2, xwa
	ld (xsp + 38), xwa
	cpw (xwa), 0x0
	jr ge, DrawFrame_Impl_ClipYMin
	ld xwa, (xsp + 38)
	ldw (xwa), 0x0

DrawFrame_Impl_ClipYMin:
	ld xwa, (xsp + 44)
	cpw (xwa), 0x0
	jr ge, DrawFrame_Impl_ClipXMin
	ldw (xwa), 0x0

DrawFrame_Impl_ClipXMin:
	ld xwa, (xsp + 44)
	inc 4, xwa
	ld (xsp + 30), xwa
	cpw (xwa), 0x140
	jr lt, DrawFrame_Impl_ClipXMax
	ld xwa, (xsp + 30)
	ldw (xwa), 0x13f

DrawFrame_Impl_ClipXMax:
	ld xwa, (xsp + 44)
	inc 6, xwa
	ld (xsp + 26), xwa
	cpw (xwa), 0xf0
	jr lt, DrawFrame_Impl_ClipYMax
	ld xwa, (xsp + 26)
	ldw (xwa), 0xef

DrawFrame_Impl_ClipYMax:
	ld xwa, (xsp + 38)
	ld wa, (xwa)
	ld (xsp + 34), wa
	ld wa, (xsp + 34)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	cpw (xsp + 42), 0xf5
	jrl z, DrawFrame_Impl_PatternSetup
	ld wa, (xsp + 42)
	extz wa
	ld (xsp + 40), wa
	ld (xsp + 36), xbc
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	cp wa, (xsp + 34)
	jr nz, DrawFrame_Impl_SolidTwoEdges
	ld xwa, (xsp + 30)
	ld bc, (xwa)
	ld xwa, (xsp + 44)
	sub bc, (xwa)
	inc 1, bc
	pushw bc
	pushm (xsp + 42)
	ld bc, (xwa)
	ld xwa, (xsp + 40)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	call Memset
	inc 8, xsp
	jrl DrawFrame_Impl_SetChangeRect

DrawFrame_Impl_SolidTwoEdges:
	ld xwa, (xsp + 30)
	ld bc, (xwa)
	ld xwa, (xsp + 44)
	sub bc, (xwa)
	inc 1, bc
	pushw bc
	pushm (xsp + 42)
	ld bc, (xwa)
	ld xwa, (xsp + 40)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	call Memset
	ld xde, (xsp + 52)
	ld bc, (xde + 4)
	sub bc, (xde)
	inc 1, bc
	pushw bc
	ld wa, (xsp + 52)
	extz wa
	pushw wa
	ld wa, (xde + 6)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	call Memset
	lda xsp, (xsp + 16)
	ldw (xsp + 28), 0xffff
	ld xbc, (xsp + 44)
	lda xwa, (xbc + 6)
	ld (xsp + 30), xwa
	ld wa, (xwa)
	ld (xsp + 40), wa
	ld wa, (xbc + 2)
	ld (xsp + 38), wa
	ld wa, (xsp + 40)
	cp wa, (xsp + 38)
	jr le, DrawFrame_Impl_SolidYStepPositive
	ldw (xsp + 28), 0x1

DrawFrame_Impl_SolidYStepPositive:
	ld wa, (xsp + 28)
	ld (xsp + 26), wa
	ld wa, (xsp + 38)
	add wa, (xsp + 28)
	cp wa, (xsp + 40)
	jrl z, DrawFrame_Impl_SetChangeRect
	ld xhl, (xsp + 44)
	lda xwa, (xhl + 4)
	ld (xsp + 34), xwa
	ld wa, (xsp + 28)
	add wa, (xsp + 38)
	exts xwa
	ld (xsp + 38), xwa
	ld xbc, xwa
	ld xwa, (xsp + 34)
	ld de, (xwa)
	cp de, (xhl)
	jr nz, DrawFrame_Impl_SolidTwoSideCheck
	ld xiy, (xsp + 44)
	lda_24 xix, 0x043c00
	ld hl, (xsp + 42)
	ld xwa, (xsp + 38)
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	jr DrawFrame_Impl_SolidOneSideCheck

DrawFrame_Impl_SolidOneSideLoop:
	ld wa, (xiy)
	exts xwa
	add xwa, xde
	ld xiz, xix
	add xiz, xwa
	ld (xiz), l
	inc 1, xbc
	add xde, 0x140

DrawFrame_Impl_SolidOneSideCheck:
	ld xwa, (xsp + 30)
	ld wa, (xwa)
	sub wa, (xsp + 28)
	exts xwa
	cp xbc, xwa
	jr ule, DrawFrame_Impl_SolidOneSideLoop
	jrl DrawFrame_Impl_SetChangeRect

DrawFrame_Impl_SolidTwoSideLoop:
	ld xhl, xbc
	sll xhl, 2
	add xhl, xbc
	sll xhl, 6
	ld xwa, (xsp + 44)
	ld wa, (xwa)
	st_dri3b B, 0x07, 0xec, 0xe0
	lda_24 xwa, 0x043c00
	ld (xsp + 38), xwa
	add xwa, xde
	ld xix, xwa
	ld de, (xsp + 42)
	ld (xix), e
	ld xwa, (xsp + 34)
	ld wa, (xwa)
	exts xwa
	add xwa, xhl
	ld xhl, (xsp + 38)
	add xhl, xwa
	ld (xhl), e
	inc 1, xbc

DrawFrame_Impl_SolidTwoSideCheck:
	ld xwa, (xsp + 30)
	ld wa, (xwa)
	sub wa, (xsp + 26)
	exts xwa
	cp xbc, xwa
	jr ule, DrawFrame_Impl_SolidTwoSideLoop
	jrl DrawFrame_Impl_SetChangeRect

DrawFrame_Impl_PatternSetup:
	ld (xsp + 38), xbc
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	cp wa, (xsp + 34)
	jr nz, DrawFrame_Impl_PatternTwoEdges
	ld xwa, (xsp + 30)
	ld bc, (xwa)
	ld xde, (xsp + 44)
	sub bc, (xde)
	inc 1, bc
	pushw bc
	ld wa, (xde)
	exts xwa
	ld xbc, (xsp + 40)
	add xbc, xwa
	addda32_24 xbc, 0x030452
	push xbc
	ld bc, (xde)
	ld xwa, (xsp + 44)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	jrl DrawFrame_Impl_SetChangeRect

DrawFrame_Impl_PatternTwoEdges:
	ld xwa, (xsp + 30)
	ld bc, (xwa)
	ld xde, (xsp + 44)
	sub bc, (xde)
	inc 1, bc
	pushw bc
	ld wa, (xde)
	exts xwa
	ld xbc, (xsp + 40)
	add xbc, xwa
	addda32_24 xbc, 0x030452
	push xbc
	ld bc, (xde)
	ld xwa, (xsp + 44)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	call Mem_Copy
	ld xhl, (xsp + 54)
	ld bc, (xhl + 4)
	sub bc, (xhl)
	inc 1, bc
	pushw bc
	ld de, (xhl)
	exts xde
	ld wa, (xhl + 6)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld xwa, xbc
	add xwa, xde
	addda32_24 xwa, 0x030452
	push xwa
	ld wa, (xhl)
	exts xwa
	add xwa, xbc
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)
	ldw (xsp + 4), 0xffff
	ld xde, (xsp + 44)
	lda xwa, (xde + 6)
	ld (xsp + 22), xwa
	ld bc, (xwa)
	ld de, (xde + 2)
	cp bc, de
	jr le, DrawFrame_Impl_PatternYStepPositive
	ldw (xsp + 4), 0x1

DrawFrame_Impl_PatternYStepPositive:
	ld wa, de
	add wa, (xsp + 4)
	cp wa, bc
	jrl z, DrawFrame_Impl_SetChangeRect
	ld xhl, (xsp + 44)
	lda xwa, (xhl + 4)
	ld (xsp + 26), xwa
	ld wa, (xsp + 4)
	add wa, de
	exts xwa
	ld (xsp + 30), xwa
	ld xbc, xwa
	lda_24 xwa, 0x043c00
	ld (xsp + 34), xwa
	ld (xsp + 38), xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	ld (xsp + 38), xwa
	sll xwa, 6
	ld (xsp + 38), xwa
	ld xbc, (xsp + 30)
	ld xwa, (xsp + 26)
	ld de, (xwa)
	cp de, (xhl)
	jr nz, DrawFrame_Impl_PatternTwoSideSetup
	ld xwa, xhl
	ld (xsp + 30), xwa
	ld xhl, (xsp + 34)
	ld xix, (xsp + 44)
	ld xde, (xsp + 38)
	jr DrawFrame_Impl_PatternOneSideCheck

DrawFrame_Impl_PatternOneSideLoop:
	ld xwa, (xsp + 30)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xiz, xhl
	add xiz, xwa
	ld wa, (xix)
	exts xwa
	ld xiy, xde
	add xiy, xwa
	addda32_24 xiy, 0x030452
	ld a, (xiy)
	ld (xiz), a
	inc 1, xbc
	add xde, 0x140

DrawFrame_Impl_PatternOneSideCheck:
	ld xwa, (xsp + 22)
	ld wa, (xwa)
	sub wa, (xsp + 4)
	exts xwa
	cp xbc, xwa
	jr ule, DrawFrame_Impl_PatternOneSideLoop
	jr DrawFrame_Impl_SetChangeRect

DrawFrame_Impl_PatternTwoSideSetup:
	ld xwa, (xsp + 44)
	ld (xsp + 10), xwa
	ld xhl, (xsp + 34)
	ld (xsp + 6), xhl
	ld (xsp + 14), xwa
	ld xde, (xsp + 26)
	ld (xsp + 30), xde
	ld (xsp + 18), xhl
	ld (xsp + 34), xde
	ld xde, (xsp + 38)
	jr DrawFrame_Impl_PatternTwoSideCheck

DrawFrame_Impl_PatternTwoSideLoop:
	ld xwa, (xsp + 10)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xix, (xsp + 6)
	add xix, xwa
	ld xwa, (xsp + 14)
	ld wa, (xwa)
	exts xwa
	ld xhl, xde
	add xhl, xwa
	addda32_24 xhl, 0x030452
	ld a, (xhl)
	ld (xix), a
	ld xwa, (xsp + 30)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	ld xix, (xsp + 18)
	add xix, xwa
	ld xwa, (xsp + 34)
	ld wa, (xwa)
	exts xwa
	ld xhl, xde
	add xhl, xwa
	addda32_24 xhl, 0x030452
	ld a, (xhl)
	ld (xix), a
	inc 1, xbc
	add xde, 0x140

DrawFrame_Impl_PatternTwoSideCheck:
	ld xwa, (xsp + 22)
	ld wa, (xwa)
	sub wa, (xsp + 4)
	exts xwa
	cp xbc, xwa
	jr ule, DrawFrame_Impl_PatternTwoSideLoop

DrawFrame_Impl_SetChangeRect:
	ld xwa, (xsp + 44)
	calr SetChangeRect
	pop xiz
	lda xsp, (xsp + 44)
	ret

; =============================================================================
; DrawFrameEx - Draw styled rectangle frame with XOR support
;
; Extended frame drawing that supports multiple rendering styles.
; Clips bounding box to screen (0,0)-(319,239) before drawing.
; Supports XOR mode for invertible selection rectangles.
;
; Input:
;   XWA = pointer to bounding box: {x_min, y_min, x_max, y_max} (4 words)
;   BC  = border color (low byte)
;   DE  = drawing mode (0x201=write, 0x205=XOR, etc.)
; =============================================================================
DrawFrameEx:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 14), de
	ld (xsp + 16), bc
	lda xde, (xwa + 2)
	cpw (xde), 0x0
	jr ge, DrawFrameEx_ClipYMin
	ldw (xde), 0x0

DrawFrameEx_ClipYMin:
	cpw (xwa), 0x0
	jr ge, DrawFrameEx_ClipXMin
	ldw (xwa), 0x0

DrawFrameEx_ClipXMin:
	lda xbc, (xwa + 4)
	ld (xsp + 8), xbc
	cpw (xbc), 0x140
	jr lt, DrawFrameEx_ClipXMax
	ld xbc, (xsp + 8)
	ldw (xbc), 0x13f

DrawFrameEx_ClipXMax:
	lda xbc, (xwa + 6)
	ld (xsp + 4), xbc
	cpw (xbc), 0xf0
	jr lt, DrawFrameEx_ClipYMax
	ld xbc, (xsp + 4)
	ldw (xbc), 0xef

DrawFrameEx_ClipYMax:
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	cp bc, (xde)
	jr nz, DrawFrameEx_MultiRowTopBottom
	ld hl, (xwa)
	ld xbc, (xsp + 8)
	cp hl, (xbc)
	jrl gt, DrawFrameEx_SetChangeRect

DrawFrameEx_SingleRowLoop:
	ld iy, (xsp + 14)
	ld ix, (xde)
	exts xix
	ld xbc, xix
	sll xbc, 2
	add xbc, xix
	sll xbc, 6
	st_dri3b A, 0x07, 0xe4, 0xec
	cpw (xsp + 14), 0x205
	jr z, DrawFrameEx_SingleRowXorPixel
	cp iy, 0x201
	jrl nz, DrawFrameEx_Return
	ld xix, 0x43c00
	add xix, xbc
	ld bc, (xsp + 16)
	ld (xix), c

DrawFrameEx_SingleRowAdvance:
	inc 1, hl
	ld xbc, (xsp + 8)
	cp hl, (xbc)
	jr le, DrawFrameEx_SingleRowLoop
	jrl DrawFrameEx_SetChangeRect

DrawFrameEx_SingleRowXorPixel:
	ld xix, 0x43c00
	add xix, xbc
	ld bc, (xsp + 16)
	xor (xix), c
	jr DrawFrameEx_SingleRowAdvance

DrawFrameEx_MultiRowTopBottom:
	ld hl, (xwa)
	ld xbc, (xsp + 8)
	cp hl, (xbc)
	jr gt, DrawFrameEx_SidesSetup

DrawFrameEx_TopBottomLoop:
	ld iy, (xsp + 14)
	ld ix, (xde)
	exts xix
	ld xbc, xix
	sll xbc, 2
	add xbc, xix
	sll xbc, 6
	st_dri3b A, 0x07, 0xe4, 0xec
	cpw (xsp + 14), 0x205
	jr z, DrawFrameEx_TopBottomXorPixel
	cp iy, 0x201
	jrl nz, DrawFrameEx_Return
	lda_24 xix, 0x043c00
	ld xiy, xix
	add xiy, xbc
	ld bc, (xsp + 16)
	ldfr_berp C, 0xee
	ld (xiy), c
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	exts xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	sll xiy, 6
	st_dri3b A, 0x07, 0xf4, 0xec
	add xix, xbc
	ldto_berp C, 0xee
	ld (xix), c

DrawFrameEx_TopBottomAdvance:
	inc 1, hl
	ld xbc, (xsp + 8)
	cp hl, (xbc)
	jr le, DrawFrameEx_TopBottomLoop

DrawFrameEx_SidesSetup:
	ld xhl, 0xffffffff
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	ld ix, (xde)
	cp bc, ix
	jr le, DrawFrameEx_SidesStepComputed
	lds32 xhl, 1

DrawFrameEx_SidesStepComputed:
	ld xiy, xhl
	ld de, bc
	exts xde
	ld bc, ix
	exts xbc
	add xbc, xhl
	cp xbc, xde
	jrl z, DrawFrameEx_SetChangeRect
	ld de, iy
	ld hl, de
	add hl, ix
	ld xbc, (xsp + 8)
	ld bc, (xbc)
	cp bc, (xwa)
	jrl nz, DrawFrameEx_TwoColSetup
	ld (xsp + 12), de
	jr DrawFrameEx_SingleColCheck

DrawFrameEx_TopBottomXorPixel:
	lda_24 xix, 0x043c00
	ld xiy, xix
	add xiy, xbc
	ld bc, (xsp + 16)
	ldfr_berp C, 0xee
	xor (xiy), c
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	exts xbc
	ld xiy, xbc
	sll xiy, 2
	add xiy, xbc
	sll xiy, 6
	st_dri3b A, 0x07, 0xf4, 0xec
	add xix, xbc
	ldto_berp C, 0xee
	xor (xix), c
	jr DrawFrameEx_TopBottomAdvance

DrawFrameEx_SingleColLoop:
	ld bc, (xsp + 14)
	lda_24 xde, 0x043c00
	cpw (xsp + 14), 0x205
	jr z, DrawFrameEx_SingleColXorPixel
	cp bc, 0x201
	jrl nz, DrawFrameEx_Return
	ld bc, hl
	exts xbc
	ld xix, xbc
	sll xix, 2
	add xix, xbc
	sll xix, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xix
	add xde, xbc
	ld bc, (xsp + 16)
	ld (xde), c

DrawFrameEx_SingleColAdvance:
	inc 1, hl

DrawFrameEx_SingleColCheck:
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	sub bc, (xsp + 12)
	cp hl, bc
	jr le, DrawFrameEx_SingleColLoop
	jr DrawFrameEx_SetChangeRect

DrawFrameEx_SingleColXorPixel:
	ld bc, hl
	exts xbc
	ld xix, xbc
	sll xix, 2
	add xix, xbc
	sll xix, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xix
	add xde, xbc
	ld bc, (xsp + 16)
	xor (xde), c
	jr DrawFrameEx_SingleColAdvance

DrawFrameEx_TwoColSetup:
	ld (xsp + 12), de
	jr DrawFrameEx_TwoColCheck

DrawFrameEx_TwoColLoop:
	ld iz, (xsp + 14)
	ld iy, hl
	exts xiy
	ld de, (xsp + 16)
	ld xix, xiy
	sll xix, 2
	add xix, xiy
	sll xix, 6
	cpw (xsp + 14), 0x205
	jr z, DrawFrameEx_TwoColXorPixel
	cp iz, 0x201
	jr nz, DrawFrameEx_Return
	ld bc, (xwa)
	exts xbc
	add xbc, xix
	lda_24 xiy, 0x043c00
	ld xiz, xiy
	add xiz, xbc
	ld (xiz), e
	ld xbc, (xsp + 8)
	ld bc, (xbc)
	exts xbc
	add xbc, xix
	add xiy, xbc
	ld (xiy), e

DrawFrameEx_TwoColAdvance:
	inc 1, hl

DrawFrameEx_TwoColCheck:
	ld xbc, (xsp + 4)
	ld bc, (xbc)
	sub bc, (xsp + 12)
	cp hl, bc
	jr le, DrawFrameEx_TwoColLoop

DrawFrameEx_SetChangeRect:
	calr SetChangeRect
	jr DrawFrameEx_Return

DrawFrameEx_TwoColXorPixel:
	ld bc, (xwa)
	exts xbc
	add xbc, xix
	lda_24 xiy, 0x043c00
	ld xiz, xiy
	add xiz, xbc
	xor (xiz), e
	ld xbc, (xsp + 8)
	ld bc, (xbc)
	exts xbc
	add xbc, xix
	add xiy, xbc
	xor (xiy), e
	jr DrawFrameEx_TwoColAdvance

DrawFrameEx_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret

; =============================================================================
; MovePixels - Copy a rectangular pixel region within the offscreen buffer
;
; Copies a rectangular block of pixels from a source region to a destination
; region within OFFSCREEN_BUFFER_1 (0x43c00). Used for scrolling, sprite
; movement, and UI element repositioning.
;
; Input:
;   XWA = pointer to source rect: word[0]=src_x, word[2]=src_y,
;         word[4]=dest_x, word[6]=dest_y
;   XBC = pointer to size: word[0]=width, word[2]=height
;
; Copies pixel-by-pixel with nested row/column loops.
; Calls SetChangeRect on completion.
; =============================================================================
MovePixels:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, MovePixels_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, MovePixels_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr MovePixels_Impl
	jr MovePixels_Return

MovePixels_DeferredPath:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, MovePixels_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld xbc, (xsp + 4)
	ld xiy, xbc
	lda xix, (xwa + 12)
	ldiw
	ldiw
	calr DisplayCmd_DequeueAndExecute

MovePixels_Return:
	pop xiz
	inc 4, xsp
	ret

MovePixels_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0xb8, 0x0c, 0x31, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

MovePixels_Impl:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xbc
	ld bc, (xwa + 4)
	ld (xsp + 4), bc
	ld bc, (xwa)
	sub (xsp + 4), bc
	jrl lt, MovePixels_Impl_Return
	lda xbc, (xwa + 2)
	ld (xsp + 10), xbc
	ld bc, (xwa + 6)
	ld (xsp + 6), bc
	ld xbc, (xsp + 10)
	ld bc, (xbc)
	sub (xsp + 6), bc
	jrl lt, MovePixels_Impl_Return
	ldw (xsp + 8), 0x0
	cpw (xsp + 6), 0x0
	jr lt, MovePixels_Impl_SetChangeRect

MovePixels_Impl_RowLoop:
	lds hl, 0
	cpw (xsp + 4), 0x0
	jr lt, MovePixels_Impl_RowAdvance

MovePixels_Impl_ColLoop:
	lda xix, (xsp + 18)
	ld bc, (xwa)
	add bc, hl
	ld (xix), bc
	lda xde, (xix + 2)
	ld xbc, (xsp + 10)
	ld bc, (xbc)
	add bc, (xsp + 8)
	ld (xde), bc
	lda xiy, (xsp + 14)
	ld xbc, (xsp + 22)
	ld bc, (xbc)
	add bc, hl
	ld (xiy), bc
	ld xbc, (xsp + 22)
	ld bc, (xbc + 2)
	add bc, (xsp + 8)
	ld (xiy + 2), bc
	exts xbc
	ld xiz, xbc
	sll xiz, 2
	add xiz, xbc
	sll xiz, 6
	ld bc, (xiy)
	exts xbc
	add xbc, xiz
	lda_24 xiy, 0x043c00
	ld xiz, xiy
	add xiz, xbc
	ld bc, (xde)
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld bc, (xix)
	exts xbc
	add xbc, xde
	add xiy, xbc
	ld c, (xiy)
	ld (xiz), c
	inc 1, hl
	cp hl, (xsp + 4)
	jr le, MovePixels_Impl_ColLoop

MovePixels_Impl_RowAdvance:
	incm 1, (xsp + 8)
	ld bc, (xsp + 8)
	cp bc, (xsp + 6)
	jr le, MovePixels_Impl_RowLoop

MovePixels_Impl_SetChangeRect:
	calr SetChangeRect

MovePixels_Impl_Return:
	pop xiz
	lda xsp, (xsp + 22)
	ret

; =============================================================================
; DrawWall - Fill entire screen / draw wallpaper
;
; Copies the full framebuffer (2 × 38400 words = 2 half-screens) from a
; source address at 0x030452 to OFFSCREEN_BUFFER_1 (0x43c00), then marks
; the entire screen as changed (0,0)-(319,239).
;
; This is used for drawing full-screen backgrounds (wallpaper/splash).
; =============================================================================
DrawWall:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawWall_DirectPath
	sti16_24 0x030450, 0x0001
	sti16_24 0x03044e, 0x0001
	jr DrawWall_DoCopy

DrawWall_DirectPath:
	sti16_24 0x030450, 0x0000
	cpdi16_24 0x03044e, 0
	jr z, DrawWall_SetCopyFlag

DrawWall_WaitVblankBefore:
	lds wa, 1
	call Audio_Lock_Release
	lds wa, 3
	call TaskSched_YieldToQueue
	cpdi16_24 0x03044e, 0
	jr nz, DrawWall_WaitVblankBefore

DrawWall_SetCopyFlag:
	sti16_24 0x030450, 0x0001
	cpdi16_24 0x03044e, 0
	jr nz, DrawWall_Deferred

DrawWall_WaitVblankAfter:
	lds wa, 1
	call Audio_Lock_Release
	lds wa, 3
	call TaskSched_YieldToQueue
	cpdi16_24 0x03044e, 0
	jr z, DrawWall_WaitVblankAfter

DrawWall_Deferred:
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfabbe5
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr DrawWall_DoCopy

DrawWall_DoCopy:
	lda xsp, (xsp - 12)
	push xiz
	ld32_24 xiz, 0x030452
	lda_24 xwa, 0x043c00
	ld (xsp + 4), xwa
	pushw 0x9600
	push xiz
	push xwa
	call Mem_Copy
	ld xwa, 0x9600
	add (xsp + 14), xwa
	add xiz, 0x9600
	pushw 0x9600
	push xiz
	ld xwa, (xsp + 20)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	lda xwa, (xsp + 8)
	ldw (xwa + 2), 0x0
	ldw (xwa), 0x0
	ldw (xwa + 4), 0x13f
	ldw (xwa + 6), 0xef
	calr SetChangeRect
	pop xiz
	lda xsp, (xsp + 12)
	ret

; =============================================================================
; DrawBitmap - Draw an indexed bitmap/sprite from the bitmap table
;
; Draws a bitmap from the ROM bitmap descriptor table at 0x913000.
; Each descriptor is 8 bytes: {word width, word height, long pixel_data_ptr}.
; Pixel data is stored as packed 16-bit entries (2 pixels per word).
; Color 0xf7 is treated as transparent (pixel skipped).
;
; Input:
;   XWA = pointer to position: word[0]=x, word[2]=y
;   XBC = bitmap index (used as: table[index * 8])
;
; Output:
;   Bitmap rendered to OFFSCREEN_BUFFER_1 (0x43c00)
;   SetChangeRect called with bitmap bounding box
;
; Returns immediately if bitmap index is 0xffffffff (no bitmap).
; Clips against screen bottom edge (y >= 240 -> skip row).
; =============================================================================
DrawBitmap:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBitmap_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBitmap_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr DrawBitmap_Impl
	jr DrawBitmap_Return

DrawBitmap_DeferredPath:
	ldw wa, 0xc
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawBitmap_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xwa + 8), xbc
	calr DisplayCmd_DequeueAndExecute

DrawBitmap_Return:
	pop xiz
	inc 4, xsp
	ret

DrawBitmap_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0xa8, 0x08, 0x21, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawBitmap_Impl:
	lda xsp, (xsp - 26)
	push xiz
	ld xiz, xbc
	ld (xsp + 26), xwa
	cp xiz, 0xffffffff
	jrl z, DrawBitmap_Impl_Return
	ld xwa, (xsp + 26)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawBitmap_Impl_Return
	ld xhl, xiz
	sll xhl, 3
	add xhl, 0x913000
	ld xix, (xhl + 4)
	ldw (xsp + 4), 0x0
	jrl DrawBitmap_Impl_RowCheck

DrawBitmap_Impl_RowLoop:
	lda xbc, (xsp + 22)
	lda xwa, (xbc + 2)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 26)
	ld wa, (xwa + 2)
	add wa, (xsp + 4)
	ld iy, wa
	ld xwa, (xsp + 10)
	ld (xwa), iy
	cp iy, 0xf0
	jrl ge, DrawBitmap_Impl_BuildDirtyRect
	ld wa, iy
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	lda_24 xiz, 0x043c00
	ld xde, xiz
	add xde, xwa
	ld (xsp + 6), xde
	lds iy, 0
	jr DrawBitmap_Impl_ColLoop

DrawBitmap_Impl_PixelPair:
	ld wa, (xix)
	srl wa, 8
	cp wa, 0xf7
	jr z, DrawBitmap_Impl_LoTransparent
	cp (xix), 0xf7
	jr z, DrawBitmap_Impl_HiTransparent
	ld xde, (xsp + 6)
	ld wa, (xix)
	ld (xde), wa
	jr DrawBitmap_Impl_PixelAdvance

DrawBitmap_Impl_HiTransparent:
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	add wa, de
	inc 1, wa
	ld (xbc), wa
	ld xwa, (xsp + 10)
	ld wa, (xwa)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xbc)
	exts xwa
	add xwa, xde
	ld xde, xiz
	add xde, xwa
	ld wa, (xix)
	srl wa, 8
	ld (xde), a
	jr DrawBitmap_Impl_PixelAdvance

DrawBitmap_Impl_LoTransparent:
	cp (xix), 0xf7
	jr z, DrawBitmap_Impl_PixelAdvance
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	add wa, de
	ld (xbc), wa
	ld xwa, (xsp + 10)
	ld wa, (xwa)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xbc)
	exts xwa
	add xwa, xde
	ld xde, xiz
	add xde, xwa
	ld a, (xix)
	ld (xde), a

DrawBitmap_Impl_PixelAdvance:
	inc 2, xix
	lds32 xwa, 2
	add (xsp + 6), xwa
	inc 1, iy

DrawBitmap_Impl_ColLoop:
	ld wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld de, iy
	add de, de
	cp iy, wa
	jrl c, DrawBitmap_Impl_PixelPair
	ld wa, (xhl)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xe2
	cps wa, 0
	jr z, DrawBitmap_Impl_RowAdvance
	cp (xix), 0xf7
	jr z, DrawBitmap_Impl_OddPixelSkip
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	add wa, de
	ld (xbc), wa
	ld xwa, (xsp + 10)
	ld wa, (xwa)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xbc)
	exts xwa
	add xwa, xde
	add xiz, xwa
	ld a, (xix)
	ld (xiz), a

DrawBitmap_Impl_OddPixelSkip:
	inc 2, xix

DrawBitmap_Impl_RowAdvance:
	incm 1, (xsp + 4)

DrawBitmap_Impl_RowCheck:
	lda xde, (xhl + 2)
	ld wa, (xde)
	cp (xsp + 4), wa
	jrl c, DrawBitmap_Impl_RowLoop

DrawBitmap_Impl_BuildDirtyRect:
	lda xwa, (xsp + 14)
	ld xiy, (xsp + 26)
	lda xix, (xiy + 2)
	ld bc, (xix)
	ld (xwa + 2), bc
	ld bc, (xiy)
	ld (xwa), bc
	ld hl, (xhl)
	add hl, (xiy)
	ld (xwa + 4), hl
	ld bc, (xde)
	add bc, (xix)
	ld (xwa + 6), bc
	calr SetChangeRect

DrawBitmap_Impl_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

; =============================================================================
; DrawBitmapFast - Optimized bitmap drawing (no transparency check)
;
; Like DrawBitmap but skips the per-pixel 0xf7 transparency check.
; Faster for opaque bitmaps that don't require transparency.
;
; Input:
;   XWA = pointer to position: word[0]=x, word[2]=y
;   XBC = bitmap index (table at 0x913000, 8 bytes per entry)
; =============================================================================
DrawBitmapFast:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBitmapFast_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBitmapFast_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr DrawBitmapFast_Impl
	jr DrawBitmapFast_Return

DrawBitmapFast_DeferredPath:
	ldw wa, 0xc
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawBitmapFast_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xwa + 8), xbc
	calr DisplayCmd_DequeueAndExecute

DrawBitmapFast_Return:
	pop xiz
	inc 4, xsp
	ret

DrawBitmapFast_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0xa8, 0x08, 0x21, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawBitmapFast_Impl:
	lda xsp, (xsp - 24)
	push xiz
	ld xiz, xbc
	ld (xsp + 24), xwa
	cp xiz, 0xffffffff
	jrl z, DrawBitmapFast_Impl_Return
	ld xwa, (xsp + 24)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawBitmapFast_Impl_Return
	ld xhl, (xsp + 24)
	ld bc, (xhl + 2)
	ld wa, bc
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xhl)
	exts xwa
	add xwa, xde
	ld xde, 0x43c00
	add xde, xwa
	ld (xsp + 12), xde
	ld (xsp + 8), bc
	sll xiz, 3
	add xiz, 0x913000
	ld xwa, (xiz + 4)
	ld (xsp + 4), xwa
	ldw (xsp + 10), 0x0
	jr DrawBitmapFast_Impl_RowCheck

DrawBitmapFast_Impl_RowLoop:
	cpw (xsp + 8), 0xf0
	jr nc, DrawBitmapFast_Impl_BuildDirtyRect
	ld wa, (xiz)
	pushw wa
	ld xwa, (xsp + 6)
	push xwa
	ld xwa, (xsp + 18)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld wa, (xiz)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xe2
	add wa, (xiz)
	exts xwa
	divs wa, 0x2
	exts xwa
	add xwa, xwa
	add (xsp + 4), xwa
	ld xwa, (xsp + 12)
	st_dri3b W, 0xe1, 0x40, 0x01
	ld (xsp + 12), xwa
	incm 1, (xsp + 8)
	incm 1, (xsp + 10)

DrawBitmapFast_Impl_RowCheck:
	lda xde, (xiz + 2)
	ld wa, (xde)
	cp (xsp + 10), wa
	jr c, DrawBitmapFast_Impl_RowLoop

DrawBitmapFast_Impl_BuildDirtyRect:
	lda xwa, (xsp + 16)
	ld xiy, (xsp + 24)
	lda xhl, (xiy + 2)
	ld bc, (xhl)
	ld (xwa + 2), bc
	ld bc, (xiy)
	ld (xwa), bc
	ld ix, (xiz)
	add ix, (xiy)
	ld (xwa + 4), ix
	ld bc, (xde)
	add bc, (xhl)
	ld (xwa + 6), bc
	calr SetChangeRect

DrawBitmapFast_Impl_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

; =============================================================================
; DrawIcons - Draw icon sprite from the icon descriptor table
;
; Draws an icon from the ROM icon descriptor table at 0x938000.
; Same format as bitmap table (8 bytes/entry: width, height, data_ptr)
; but uses a separate base address for UI icons.
;
; Input:
;   XWA = pointer to position: word[0]=x, word[2]=y
;   XBC = icon index (used as: table[index * 8])
;
; Returns immediately if icon index is 0 (no icon).
; =============================================================================
DrawIcons:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawIcons_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawIcons_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr DrawIcons_Impl
	jr DrawIcons_Return

DrawIcons_DeferredPath:
	ldw wa, 0xc
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawIcons_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xwa + 8), xbc
	calr DisplayCmd_DequeueAndExecute

DrawIcons_Return:
	pop xiz
	inc 4, xsp
	ret

DrawIcons_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0xa8, 0x08, 0x21, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawIcons_Impl:
	lda xsp, (xsp - 36)
	push xiz
	ld (xsp + 32), xbc
	ld (xsp + 36), xwa
	ld xwa, (xsp + 32)	; ICON ID
	or xwa, xwa
	jrl z, DrawIcons_Impl_Return

	ld xwa, (xsp + 36)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawIcons_Impl_Return
	ld xwa, (xsp + 32)	; ICON ID
	ld (xsp + 4), xwa
	sll xwa, 3
	ld (xsp + 4), xwa	; 8 * ICON ID
	ld xwa, 0x938000	; <-- base address for icon data
				;    (this is at the end of the
				;     "table_data" ROM at IC1 and IC3)
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xsp + 8), xwa
	lda xwa, (xsp + 30)
	ld (xsp + 16), xwa
	ld xde, (xsp + 36)
	lda xwa, (xde + 2)
	ld (xsp + 12), xwa
	ld xbc, (xsp + 16)
	ld wa, (xwa)
	ld (xbc), wa
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	ld xhl, 0x43c00
	add xhl, xwa
	lds de, 0

DrawIcons_Impl_RowLoop:
	ld xwa, (xsp + 16)
	cpw (xwa), 0xf0
	jr ge, DrawIcons_Impl_BuildDirtyRect
	ld xiz, xhl
	lds iy, 0

DrawIcons_Impl_ColLoop:
	st_dpib D, 0xf9
	ld xwa, (xsp + 8)
	ld_spib C, 0xe0
	ld (xsp + 8), xwa
	ld a, c
	extz wa
	add wa, wa
	lda_24 xbc, 0xeaabf2
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	ld (xix), wa
	inc 1, iy
	cp iy, 0xc
	jr lt, DrawIcons_Impl_ColLoop
	ld xwa, (xsp + 16)
	incm 1, (xwa)
	st_dri3b C, 0xed, 0x40, 0x01
	inc 1, de
	cp de, 0x18
	jr lt, DrawIcons_Impl_RowLoop

DrawIcons_Impl_BuildDirtyRect:
	lda xwa, (xsp + 20)
	ld xhl, (xsp + 12)
	ld bc, (xhl)
	ld (xwa + 2), bc
	ld xiy, (xsp + 36)
	ld bc, (xiy)
	ld (xwa), bc
	ld xix, (xsp + 4)
	ld de, (xix)
	add de, (xiy)
	ld (xwa + 4), de
	ld de, (xix + 2)
	add de, (xhl)
	ld (xwa + 6), de
	calr SetChangeRect

DrawIcons_Impl_Return:
	pop xiz
	lda xsp, (xsp + 36)
	ret

DrawFrameSP:
	dec 4, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawFrameSP_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawFrameSP_Return
	ld xwa, xiz
	ld bc, (xsp + 6)
	ld de, (xsp + 4)
	calr DrawFrameSP_Impl
	jr DrawFrameSP_Return

DrawFrameSP_DeferredPath:
	ldw wa, 0xc
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawFrameSP_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld bc, (xsp + 6)
	ld (xwa + 8), bc
	ld bc, (xsp + 4)
	ld (xwa + 10), bc
	calr DisplayCmd_DequeueAndExecute

DrawFrameSP_Return:
	pop xiz
	inc 4, xsp
	ret

DrawFrameSP_ParamBlock:
	.byte 0xb8, 0x04, 0x33, 0x98, 0x08, 0x21, 0x98, 0x0a
	.byte 0x22, 0xd2, 0x4e, 0x04, 0x03, 0x3f, 0x00, 0x00
	.byte 0xb0, 0xf6, 0xeb, 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawFrameSP_Impl:
	lda xsp, (xsp - 34)
	ld (xsp + 26), de
	ld (xsp + 28), bc
	ld (xsp + 30), xwa
	ld xwa, (xsp + 30)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawFrameSP_Impl_Return
	ld bc, (xsp + 28)
	extz xbc
	sll xbc, 3
	add xbc, 0x934000
	ld xwa, (xbc + 4)
	ld (xsp), xwa
	ldw (xsp + 4), 0x0
	lda xwa, (xbc + 2)
	ld (xsp + 6), xwa
	cpw (xwa), 0x0
	jrl le, DrawFrameSP_Impl_BuildDirtyRect

DrawFrameSP_Impl_RowLoop:
	lda xde, (xsp + 22)
	lda xwa, (xde + 2)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 30)
	ld hl, (xwa + 2)
	add hl, (xsp + 4)
	ld xwa, (xsp + 10)
	ld (xwa), hl
	cp hl, 0xf0
	jrl ge, DrawFrameSP_Impl_BuildDirtyRect
	lds hl, 0
	cpw (xbc), 0x0
	jr le, DrawFrameSP_Impl_OddWidthPad

DrawFrameSP_Impl_ColLoop:
	ld xwa, (xsp + 30)
	ld wa, (xwa)
	add wa, hl
	ld (xde), wa
	ld xwa, (xsp)
	ld a, (xwa)
	ldfr_berp A, 0xee
	cp_erpb 0xee, 0xf7
	jr z, DrawFrameSP_Impl_PixelAdvance
	lda_24 xiy, 0x043c00
	ld xwa, (xsp + 10)
	ld wa, (xwa)
	exts xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	sll xix, 6
	cp_erpb 0xee, 0xf6
	jr nz, DrawFrameSP_Impl_DrawNormal
	ld wa, (xde)
	exts xwa
	add xwa, xix
	add xiy, xwa
	ld wa, (xsp + 26)
	ld (xiy), a
	jr DrawFrameSP_Impl_PixelAdvance

DrawFrameSP_Impl_DrawNormal:
	ld wa, (xde)
	exts xwa
	add xwa, xix
	add xiy, xwa
	ld xwa, (xsp)
	ld a, (xwa)
	ld (xiy), a

DrawFrameSP_Impl_PixelAdvance:
	lds32 xwa, 1
	add (xsp), xwa
	inc 1, hl
	cp hl, (xbc)
	jr lt, DrawFrameSP_Impl_ColLoop

DrawFrameSP_Impl_OddWidthPad:
	ld wa, (xbc)
	exts xwa
	divs wa, 0x2
	add wa, wa
	cp wa, (xbc)
	jr z, DrawFrameSP_Impl_RowAdvance
	lds32 xwa, 1
	add (xsp), xwa

DrawFrameSP_Impl_RowAdvance:
	incm 1, (xsp + 4)
	ld xwa, (xsp + 6)
	ld de, (xsp + 4)
	cp de, (xwa)
	jrl lt, DrawFrameSP_Impl_RowLoop

DrawFrameSP_Impl_BuildDirtyRect:
	lda xwa, (xsp + 14)
	ld xix, (xsp + 30)
	lda xhl, (xix + 2)
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xix)
	ld (xwa), de
	ld de, (xbc)
	add de, (xix)
	ld (xwa + 4), de
	ld xbc, (xsp + 6)
	ld bc, (xbc)
	add bc, (xhl)
	ld (xwa + 6), bc
	calr SetChangeRect

DrawFrameSP_Impl_Return:
	lda xsp, (xsp + 34)
	ret

; =============================================================================
; DrawBitmapSP - Draw bitmap with special positioning/effects
;
; Like DrawBitmap but with additional parameters for sprite-like rendering
; with per-pixel color mapping and separate foreground/background handling.
;
; Input:
;   XWA = pointer to position: word[0]=x, word[2]=y
;   XBC = bitmap index
;   Stack: additional rendering parameters
; =============================================================================
DrawBitmapSP:
	dec 6, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBitmapSP_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBitmapSP_Return
	pushm (xsp + 14)
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld de, (xsp + 6)
	calr DrawBitmapSP_Impl
	jr DrawBitmapSP_Return

DrawBitmapSP_DeferredPath:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfac24a
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 6)
	ld (xwa + 8), xbc
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld bc, (xsp + 14)
	ld (xwa + 14), bc
	calr DisplayCmd_DequeueAndExecute

DrawBitmapSP_Return:
	pop xiz
	inc 6, xsp
	retd 0x2
	lda xbc, (xwa + 4)
	ld xhl, (xwa + 8)
	ld de, (xwa + 12)
	ld wa, (xwa + 14)
	cpdi16_24 0x03044e, 0
	ret z
	pushw wa
	ld xwa, xbc
	ld xbc, xhl
	calr DrawBitmapSP_Impl
	ret

DrawBitmapSP_Impl:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 20), de
	ld (xsp + 22), xbc
	ld (xsp + 26), xwa
	ld xwa, (xsp + 26)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawBitmapSP_Impl_Return
	ldw (xsp + 4), 0x0
	ld wa, (xsp + 34)
	ld (xsp + 6), wa
	cpw (xsp + 6), 0x0
	jrl ule, DrawBitmapSP_Impl_BuildDirtyRect

DrawBitmapSP_Impl_RowLoop:
	lda xde, (xsp + 16)
	lda xbc, (xde + 2)
	ld xix, (xsp + 26)
	ld hl, (xix + 2)
	add hl, (xsp + 4)
	ld wa, hl
	ld (xbc), hl
	cp hl, 0xf0
	jrl ge, DrawBitmapSP_Impl_BuildDirtyRect
	exts xwa
	ld xhl, xwa
	sll xhl, 2
	add xhl, xwa
	sll xhl, 6
	ld wa, (xix)
	exts xwa
	add xwa, xhl
	lda_24 xhl, 0x043c00
	ld xiy, xhl
	add xiy, xwa
	lds ix, 0
	jrl DrawBitmapSP_Impl_ColLoop

DrawBitmapSP_Impl_PixelPair:
	ld xwa, (xsp + 22)
	ld wa, (xwa)
	srl wa, 8
	cp wa, 0xf7
	jr z, DrawBitmapSP_Impl_LoTransparent
	ld xwa, (xsp + 22)
	cp (xwa), 0xf7
	jr z, DrawBitmapSP_Impl_HiTransparent
	ld wa, (xwa)
	ld (xiy), wa
	jr DrawBitmapSP_Impl_PixelAdvance

DrawBitmapSP_Impl_HiTransparent:
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	add wa, iz
	inc 1, wa
	ld (xde), wa
	ld wa, (xbc)
	exts xwa
	ld xiz, xwa
	sll xiz, 2
	add xiz, xwa
	sll xiz, 6
	ld wa, (xde)
	exts xwa
	add xwa, xiz
	ld xiz, xhl
	add xiz, xwa
	ld xwa, (xsp + 22)
	ld wa, (xwa)
	srl wa, 8
	ld (xiz), a
	jr DrawBitmapSP_Impl_PixelAdvance

DrawBitmapSP_Impl_LoTransparent:
	ld xwa, (xsp + 22)
	cp (xwa), 0xf7
	jr z, DrawBitmapSP_Impl_PixelAdvance
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	add wa, iz
	ld (xde), wa
	ld wa, (xbc)
	exts xwa
	ld xiz, xwa
	sll xiz, 2
	add xiz, xwa
	sll xiz, 6
	ld wa, (xde)
	exts xwa
	add xwa, xiz
	ld xiz, xhl
	add xiz, xwa
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld (xiz), a

DrawBitmapSP_Impl_PixelAdvance:
	lds32 xwa, 2
	add (xsp + 22), xwa
	inc 2, xiy
	inc 1, ix

DrawBitmapSP_Impl_ColLoop:
	ld wa, (xsp + 20)
	exts xwa
	divs wa, 0x2
	ld iz, ix
	add iz, iz
	cp ix, wa
	jrl c, DrawBitmapSP_Impl_PixelPair
	ld wa, (xsp + 20)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xe2
	cps wa, 0
	jr z, DrawBitmapSP_Impl_RowAdvance
	ld xix, (xsp + 22)
	cp (xix), 0xf7
	jr z, DrawBitmapSP_Impl_OddPixelAdvance
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	add wa, iz
	ld (xde), wa
	ld wa, (xbc)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	add xhl, xwa
	ld a, (xix)
	ld (xhl), a

DrawBitmapSP_Impl_OddPixelAdvance:
	lds32 xwa, 2
	add (xsp + 22), xwa

DrawBitmapSP_Impl_RowAdvance:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, (xsp + 6)
	jrl c, DrawBitmapSP_Impl_RowLoop

DrawBitmapSP_Impl_BuildDirtyRect:
	lda xwa, (xsp + 8)
	ld xhl, (xsp + 26)
	lda xde, (xhl + 2)
	ld bc, (xde)
	ld (xwa + 2), bc
	ld bc, (xhl)
	ld (xwa), bc
	ld bc, (xhl)
	add bc, (xsp + 20)
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, (xsp + 34)
	ld (xwa + 6), bc
	calr SetChangeRect

DrawBitmapSP_Impl_Return:
	pop xiz
	lda xsp, (xsp + 26)
	retd 0x2

DrawBitmapSPFast:
	dec 6, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBitmapSPFast_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBitmapSPFast_Return
	pushm (xsp + 14)
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld de, (xsp + 6)
	calr DrawBitmapSPFast_Impl
	jr DrawBitmapSPFast_Return

DrawBitmapSPFast_DeferredPath:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfac439
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 6)
	ld (xwa + 8), xbc
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld bc, (xsp + 14)
	ld (xwa + 14), bc
	calr DisplayCmd_DequeueAndExecute

DrawBitmapSPFast_Return:
	pop xiz
	inc 6, xsp
	retd 0x2
	lda xbc, (xwa + 4)
	ld xhl, (xwa + 8)
	ld de, (xwa + 12)
	ld wa, (xwa + 14)
	cpdi16_24 0x03044e, 0
	ret z
	pushw wa
	ld xwa, xbc
	ld xbc, xhl
	calr DrawBitmapSPFast_Impl
	ret

DrawBitmapSPFast_Impl:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 16), de
	ld (xsp + 18), xbc
	ld (xsp + 22), xwa
	ld xwa, (xsp + 22)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawBitmapSPFast_Impl_Return
	ld xhl, (xsp + 22)
	ld bc, (xhl + 2)
	ld wa, bc
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xhl)
	exts xwa
	add xwa, xde
	ld xde, 0x43c00
	add xde, xwa
	ld xiz, xde
	ld (xsp + 6), bc
	ldw (xsp + 4), 0x0
	ld wa, (xsp + 30)
	cps wa, 0
	jr ule, DrawBitmapSPFast_Impl_BuildDirtyRect

DrawBitmapSPFast_Impl_RowLoop:
	cpw (xsp + 6), 0xf0
	jr nc, DrawBitmapSPFast_Impl_BuildDirtyRect
	ld wa, (xsp + 16)
	pushw wa
	ld xwa, (xsp + 20)
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 16)
	inc 1, wa
	exts xwa
	divs wa, 0x2
	exts xwa
	add xwa, xwa
	add (xsp + 18), xwa
	st_dri3b H, 0xf9, 0x40, 0x01
	incm 1, (xsp + 6)
	incm 1, (xsp + 4)
	ld wa, (xsp + 30)
	cp (xsp + 4), wa
	jr c, DrawBitmapSPFast_Impl_RowLoop

DrawBitmapSPFast_Impl_BuildDirtyRect:
	lda xwa, (xsp + 8)
	ld xhl, (xsp + 22)
	lda xde, (xhl + 2)
	ld bc, (xde)
	ld (xwa + 2), bc
	ld bc, (xhl)
	ld (xwa), bc
	ld bc, (xhl)
	add bc, (xsp + 16)
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, (xsp + 30)
	ld (xwa + 6), bc
	calr SetChangeRect

DrawBitmapSPFast_Impl_Return:
	pop xiz
	lda xsp, (xsp + 22)
	retd 0x2

DrawBitmapSP2:
	dec 6, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBitmapSP2_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBitmapSP2_Return
	pushm (xsp + 18)
	pushm (xsp + 18)
	pushm (xsp + 18)
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld de, (xsp + 10)
	calr DrawBitmapSP2_Impl
	jr DrawBitmapSP2_Return

DrawBitmapSP2_DeferredPath:
	ldw wa, 0x14
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfac579
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 6)
	ld (xwa + 8), xbc
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld bc, (xsp + 18)
	ld (xwa + 14), bc
	ld bc, (xsp + 16)
	ld (xwa + 16), bc
	ld bc, (xsp + 14)
	ld (xwa + 18), bc
	calr DisplayCmd_DequeueAndExecute

DrawBitmapSP2_Return:
	pop xiz
	inc 6, xsp
	retd 0x6
	lda xhl, (xwa + 4)
	ld xbc, (xwa + 8)
	ld de, (xwa + 12)
	ld iy, (xwa + 14)
	ld ix, (xwa + 16)
	ld wa, (xwa + 18)
	cpdi16_24 0x03044e, 0
	ret z
	pushw iy
	pushw ix
	pushw wa
	ld xwa, xhl
	calr DrawBitmapSP2_Impl
	ret

DrawBitmapSP2_Impl:
	lda xsp, (xsp - 22)
	pushw iz
	ld (xsp + 14), de
	ld (xsp + 16), xbc
	ld (xsp + 20), xwa
	ld xwa, (xsp + 20)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawBitmapSP2_Impl_Return
	lds hl, 0
	ld bc, (xsp + 32)
	ld de, bc
	cps de, 0
	jrl ule, DrawBitmapSP2_Impl_BuildDirtyRect

DrawBitmapSP2_Impl_RowLoop:
	ld xiy, (xsp + 20)
	ld wa, (xiy + 2)
	sub wa, hl
	add wa, de
	ld ix, wa
	ld (xsp + 12), ix
	cp ix, 0xf0
	jrl ge, DrawBitmapSP2_Impl_BuildDirtyRect
	exts xwa
	ld xix, xwa
	sll xix, 2
	add xix, xwa
	sll xix, 6
	ld wa, (xiy)
	exts xwa
	add xwa, xix
	lda_24 xix, 0x043c00
	add xix, xwa
	ld xwa, (xsp + 16)
	ld iy, (xwa)
	srl iy, 8
	ldi_berp 0xf5, 0
	ld wa, (xwa)
	ldb w, 0x0
	sll wa, 8
	add iy, wa
	lds iz, 0
	jr DrawBitmapSP2_Impl_MaskWordCheck

DrawBitmapSP2_Impl_LoadMaskWord:
	ldi_werp 0xe6, 0

DrawBitmapSP2_Impl_BitLoop:
	ld wa, (xsp + 14)
	ldfr_werp WA, 0xe2
	ld wa, iz
	sll wa, 4
	add_werp WA, 0xe6
	cp_werp WA, 0xe2
	jr nc, DrawBitmapSP2_Impl_MaskWordAdvance
	ldw wa, 0xf
	sub_werp WA, 0xe6
	ldi_werp 0xea, 1
	and a, 0xf
	jr z, DrawBitmapSP2_Impl_DrawPixel
	sla_a_werp 0xea

DrawBitmapSP2_Impl_DrawPixel:
	ldto_werp WA, 0xea
	ldfr_werp WA, 0xe2
	ld wa, iy
	and_werp WA, 0xe2
	jr z, DrawBitmapSP2_Impl_BitAdvance
	ld wa, (xsp + 30)
	ld (xix), a

DrawBitmapSP2_Impl_BitAdvance:
	inc 1, xix
	inc1_werp 0xe6
	cp_erpw 0xe6, 0x10, 0x00
	jr c, DrawBitmapSP2_Impl_BitLoop

DrawBitmapSP2_Impl_MaskWordAdvance:
	lds32 xwa, 2
	add (xsp + 16), xwa
	inc 1, iz

DrawBitmapSP2_Impl_MaskWordCheck:
	ld wa, (xsp + 14)
	add wa, 0xf
	exts xwa
	divs wa, 0x10
	cp iz, wa
	jr c, DrawBitmapSP2_Impl_LoadMaskWord
	inc 1, hl
	cp hl, de
	jrl c, DrawBitmapSP2_Impl_RowLoop

DrawBitmapSP2_Impl_BuildDirtyRect:
	lda xwa, (xsp + 2)
	ld xix, (xsp + 20)
	lda xhl, (xix + 2)
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xix)
	ld (xwa), de
	ld de, (xix)
	add de, (xsp + 14)
	ld (xwa + 4), de
	ld de, (xhl)
	add de, bc
	ld (xwa + 6), de
	calr SetChangeRect

DrawBitmapSP2_Impl_Return:
	popw iz
	lda xsp, (xsp + 22)
	retd 0x6

DrawBitmapFile:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawBitmapFile_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawBitmapFile_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr DrawBitmapFile_Impl
	jr DrawBitmapFile_Return

DrawBitmapFile_DeferredPath:
	ldw wa, 0xc
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, DrawBitmapFile_ParamBlock
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xwa + 8), xbc
	calr DisplayCmd_DequeueAndExecute

DrawBitmapFile_Return:
	pop xiz
	inc 4, xsp
	ret

DrawBitmapFile_ParamBlock:
	.byte 0xb8, 0x04, 0x32, 0xa8, 0x08, 0x21, 0xd2, 0x4e
	.byte 0x04, 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xea
	.byte 0x88, 0x1e, 0x01, 0x00, 0x0e

DrawBitmapFile_Impl:
	st_dri3b L, 0xfd, 0xc8, 0xfb
	push xiz
	st_dri3l XBC, 0xfd, 0x34, 0x04
	st_dri3l XWA, 0xfd, 0x38, 0x04
	pushw 0x2
	pushw 0xea
	pushw 0xadf2
	ld_sril XWA, (xsp + 0x043a)
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jrl nz, DrawBitmapFile_Impl_Return
	ld_sril XWA, (xsp + 0x0434)
	lda xwa, (xwa + 14)
	ld (xsp + 36), xwa
	ld (xsp + 4), xwa
	ld xwa, (xsp + 36)
	ld xwa, (xwa)
	cp xwa, 0x28
	jrl nz, DrawBitmapFile_Impl_Return
	ld xwa, (xsp + 36)
	cpw (xwa + 12), 0x1
	jrl nz, DrawBitmapFile_Impl_Return
	ld xwa, (xsp + 36)
	cpw (xwa + 14), 0x8
	jrl ugt, DrawBitmapFile_Impl_Return
	ld xwa, (xsp + 36)
	ld xwa, (xwa + 32)
	cp xwa, 0x100
	jrl ugt, DrawBitmapFile_Impl_Return
	ld_sril XWA, (xsp + 0x0434)
	ld xwa, (xwa + 10)
	ld (xsp + 32), xwa
	ld xwa, 0x36
	sub (xsp + 32), xwa
	ld xwa, (xsp + 32)
	cp xwa, 0x400
	jrl ugt, DrawBitmapFile_Impl_Return
	ld xwa, (xsp + 32)
	pushw wa
	ld_sril XWA, (xsp + 0x0436)
	lda xwa, (xwa + 54)
	push xwa
	lda xwa, (xsp + 58)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 32)
	srl xwa, 2
	ld (xsp + 32), xwa
	ld xbc, 0x69400
	lds32 xwa, 0
	ld (xsp + 12), xwa

DrawBitmapFile_Impl_InitPalette:
	ld xde, (xsp + 12)
	sll xde, 2
	add xde, 0x69400
	ld xwa, 0xff000000
	ld (xde), xwa
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x100
	jr lt, DrawBitmapFile_Impl_InitPalette
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, (xsp + 32)
	cp xwa, 0x0
	jr ule, DrawBitmapFile_Impl_ParseDimensions

DrawBitmapFile_Impl_LoadPalette:
	ld xde, (xsp + 12)
	sll xde, 2
	ld xwa, xde
	lda xhl, (xsp + 52)
	ld xix, xhl
	add xix, xwa
	ld a, (xix)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	sll xix, 8
	ld xwa, xde
	ld xiy, xhl
	add xiy, xwa
	lds32 xwa, 0
	ld a, (xiy + 1)
	add xix, xwa
	sll xix, 8
	add xhl, xde
	lds32 xwa, 0
	ld a, (xhl + 2)
	add xix, xwa
	st_dpil XIX, 0xe6
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xde, (xsp + 12)
	cp xde, (xsp + 32)
	jr c, DrawBitmapFile_Impl_LoadPalette

DrawBitmapFile_Impl_ParseDimensions:
	ld xbc, (xsp + 36)
	ld xwa, (xbc + 4)
	ld (xsp + 16), xwa
	ld xwa, (xbc + 8)
	ld (xsp + 8), xwa
	ld xbc, 0x8
	ld xwa, (xsp + 4)
	mrdw3 0x98, 0x0e, 0x51
	ld iz, bc
	extz xiz
	ld xbc, xiz
	sla xbc, 2
	ld xwa, xbc
	dec 1, xwa
	add xwa, (xsp + 16)
	call Math_DivideSigned32
	ld (xsp + 20), xhl
	sla xhl, 2
	ld (xsp + 20), xhl
	ld xwa, xhl
	ld xbc, xiz
	call Math_MultiplyAccumulate
	pushw hl
	call Malloc
	inc 2, xsp
	ld (xsp + 40), xhl
	ld xwa, (xsp + 40)
	ld (xsp + 24), xwa
	ld xwa, (xsp + 32)
	sll xwa, 2
	add xwa, 0x36
	add_sril_mr XWA, 0xfd, 0x34, 0x04
	ld xwa, (xsp + 8)
	cp xwa, 0xf0
	jr le, DrawBitmapFile_Impl_ComputeStride
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xbc, (xsp + 8)
	sub xbc, 0xf0
	jr le, DrawBitmapFile_Impl_ClampHeight

DrawBitmapFile_Impl_SkipExtraRows:
	ld xwa, (xsp + 20)
	add_sril_mr XWA, 0xfd, 0x34, 0x04
	lds32 xwa, 1
	add (xsp + 12), xwa
	cp (xsp + 12), xbc
	jr lt, DrawBitmapFile_Impl_SkipExtraRows

DrawBitmapFile_Impl_ClampHeight:
	ld xwa, 0xf0
	ld (xsp + 8), xwa

DrawBitmapFile_Impl_ComputeStride:
	ld xwa, 0x140
	ld (xsp + 32), xwa
	ld xbc, (xsp + 8)
	dec 1, xbc
	ld xwa, (xsp + 32)
	call Math_MultiplyAccumulate
	ld (xsp + 32), xhl
	add xhl, 0x56800
	ld (xsp + 28), xhl
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x0
	jrl le, DrawBitmapFile_Impl_FillRemaining

DrawBitmapFile_Impl_DecodeRowLoop:
	ld xwa, (xsp + 20)
	pushw wa
	ld_sril XWA, (xsp + 0x0436)
	push xwa
	ld xwa, (xsp + 30)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 4)
	ld de, (xwa + 14)
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	calr Gfx_ProcessSplashData
	ld xwa, (xsp + 16)
	cp xwa, 0x140
	jr lt, DrawBitmapFile_Impl_TileRow
	pushw 0x140
	ld xwa, (xsp + 26)
	push xwa
	ld xwa, (xsp + 34)
	push xwa
	jr DrawBitmapFile_Impl_RowCopy

DrawBitmapFile_Impl_TileRow:
	lds32 xiz, 0
	ld xbc, (xsp + 16)
	ld xwa, 0x140
	call Math_DivideSigned32
	cp xhl, 0x0
	jr le, DrawBitmapFile_Impl_TileRemainder

DrawBitmapFile_Impl_TileLoop:
	ld xwa, (xsp + 16)
	pushw wa
	ld xwa, (xsp + 26)
	push xwa
	ld xwa, xiz
	ld xbc, (xsp + 22)
	call Math_MultiplyAccumulate
	add xhl, (xsp + 34)
	push xhl
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 1, xiz
	ld xbc, (xsp + 16)
	ld xwa, 0x140
	call Math_DivideSigned32
	cp xiz, xhl
	jr lt, DrawBitmapFile_Impl_TileLoop

DrawBitmapFile_Impl_TileRemainder:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	call Math_MultiplyAccumulate
	ld xwa, 0x140
	sub xwa, xhl
	pushw wa
	ld xwa, (xsp + 26)
	push xwa
	add xhl, (xsp + 34)
	push xhl

DrawBitmapFile_Impl_RowCopy:
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x140
	sub (xsp + 28), xwa
	ld xwa, (xsp + 20)
	add_sril_mr XWA, 0xfd, 0x34, 0x04
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 8)
	jrl lt, DrawBitmapFile_Impl_DecodeRowLoop

DrawBitmapFile_Impl_FillRemaining:
	ld xbc, (xsp + 8)
	cp xbc, 0xf0
	jr ge, DrawBitmapFile_Impl_CopyToVRAM
	ld xwa, 0x140
	add (xsp + 32), xwa
	ld xiz, 0x56800
	ld xwa, (xsp + 32)
	add xwa, 0x56800
	ld (xsp + 28), xwa
	ld (xsp + 12), xbc
	cp xbc, 0xf0
	jr ge, DrawBitmapFile_Impl_CopyToVRAM

DrawBitmapFile_Impl_FillLoop:
	pushw 0x140
	push xiz
	ld xwa, (xsp + 34)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	st_dri3b H, 0xf9, 0x40, 0x01
	ld xwa, 0x140
	add (xsp + 28), xwa
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0xf0
	jr lt, DrawBitmapFile_Impl_FillLoop

DrawBitmapFile_Impl_CopyToVRAM:
	ld xwa, (xsp + 40)
	push xwa
	call Free
	inc 4, xsp
	calr Gfx_DecodeImageToBuffer
	ld_sril XWA, (xsp + 0x0438)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawBitmapFile_Impl_Return
	ld xbc, (xsp + 36)
	ld xwa, (xbc + 4)
	ld (xsp + 40), wa
	ld xwa, (xbc + 8)
	ld (xsp + 42), wa
	ld_sril XHL, (xsp + 0x0438)
	ld bc, (xhl + 2)
	ld wa, bc
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xhl)
	exts xwa
	add xwa, xde
	ld xde, 0x43c00
	add xde, xwa
	ld xiz, xde
	ld xwa, 0x56800
	ld (xsp + 36), xwa
	ld (xsp + 34), bc
	ldw (xsp + 32), 0x0
	ld wa, (xsp + 42)
	cps wa, 0
	jr ule, DrawBitmapFile_Impl_BuildDirtyRect

DrawBitmapFile_Impl_VRAMRowLoop:
	cpw (xsp + 34), 0xf0
	jr nc, DrawBitmapFile_Impl_BuildDirtyRect
	ld wa, (xsp + 40)
	pushw wa
	ld xwa, (xsp + 38)
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x140
	add (xsp + 36), xwa
	st_dri3b H, 0xf9, 0x40, 0x01
	incm 1, (xsp + 34)
	incm 1, (xsp + 32)
	ld wa, (xsp + 42)
	cp (xsp + 32), wa
	jr c, DrawBitmapFile_Impl_VRAMRowLoop

DrawBitmapFile_Impl_BuildDirtyRect:
	lda xwa, (xsp + 44)
	ld_sril XHL, (xsp + 0x0438)
	lda xde, (xhl + 2)
	ld bc, (xde)
	ld (xwa + 2), bc
	ld bc, (xhl)
	ld (xwa), bc
	ld bc, (xhl)
	add bc, (xsp + 40)
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, (xsp + 42)
	ld (xwa + 6), bc
	calr SetChangeRect
	lds wa, 3
	calr ChangePalette_Impl

DrawBitmapFile_Impl_Return:
	pop xiz
	st_dri3b L, 0xfd, 0x38, 0x04
	ret

; =============================================================================
; DrawString - Render a text string to the offscreen buffer
;
; Core text rendering function. Draws a null-terminated string using the
; font glyph table at 0x945c00. Each font entry is 16 bytes:
;   +0x00: word width (pixels)
;   +0x02: word height (pixels)
;   +0x04: word descent
;   +0x06: word ascent
;   +0x08: long glyph_data_ptr (pointer to glyph bitmap)
;   +0x0c: long kerning_table_ptr (0 = fixed-width)
;
; Characters are rendered as 1bpp bitmaps (8 pixels per byte, MSB first).
; Each glyph is divided into 8-pixel-wide columns, rendered left-to-right.
; Supports clipping against a clip rectangle.
;
; Input:
;   XWA = pointer to position/clip rect (8 words)
;   XBC = pointer to cursor state (2 words: x_cursor, y_cursor)
;   XDE = pointer to null-terminated string
;   Stack: font_id (word), foreground_color (word), background_color (word)
;
; Output:
;   Text rendered to OFFSCREEN_BUFFER_1 (0x43c00)
;   SetChangeRect called with text bounding box
; =============================================================================
DrawString:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawString_DeferredPath
	cpdi16_24 0x03044e, 0
	jr z, DrawString_Return
	ld xwa, (xsp + 28)
	push xwa
	pushm (xsp + 30)
	pushm (xsp + 30)
	ld xde, (xiz + 16)
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	calr DrawString_Impl
	jr DrawString_Return

DrawString_DeferredPath:
	ld xwa, (xsp + 8)
	push xwa
	call Strlen
	inc 4, xsp
	inc 1, hl
	ld wa, hl
	calr DrawQueue_Alloc
	ld (xsp + 4), xhl
	ldw wa, 0x1c
	calr DrawQueue_Alloc
	ld xiz, xhl
	lda_24 xwa, 0xfacb69
	ld (xhl), xwa
	ld xwa, (xsp + 16)
	ld xiy, xwa
	lda xix, (xhl + 4)
	lds bc, 4
	ldirw
	ld xwa, (xsp + 12)
	ld xiy, xwa
	lda xix, (xhl + 12)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xhl + 16), xbc
	ld xwa, (xsp + 8)
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 28)
	ld (xiz + 20), xwa
	ld wa, (xsp + 26)
	ld (xiz + 24), wa
	ld wa, (xsp + 24)
	ld (xiz + 26), wa
	ld xwa, xiz
	calr DisplayCmd_DequeueAndExecute

DrawString_Return:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x8
	push xiz
	ld xiz, xwa
	lda xwa, (xiz + 4)
	lda xbc, (xiz + 12)
	ld xix, (xiz + 20)
	ld hl, (xiz + 24)
	ld de, (xiz + 26)
	cpdi16_24 0x03044e, 0
	jr z, DrawString_DeferredDispatch
	push xix
	pushw hl
	pushw de
	ld xde, (xiz + 16)
	calr DrawString_Impl

DrawString_DeferredDispatch:
	ld xwa, (xiz + 16)
	calr DrawFunc_Return
	pop xiz
	ret

DrawString_Impl:
	st_dri3b L, 0xfd, 0xc4, 0xfe
	push xiz
	st_dri3l XDE, 0xfd, 0x38, 0x01
	st_dri3l XWA, 0xfd, 0x3c, 0x01
	ld_sril XWA, (xsp + 0x0138)
	cp (xwa), 0x0
	jrl z, DrawString_Impl_Return
	ld_sril XWA, (xsp + 0x013c)
	lda xde, (xwa + 2)
	cpw (xde), 0x0
	jr ge, DrawString_Impl_ClipYMin
	ldw (xde), 0x0

DrawString_Impl_ClipYMin:
	ld_sril XWA, (xsp + 0x013c)
	cpw (xwa), 0x0
	jr ge, DrawString_Impl_ClipXMin
	ldw (xwa), 0x0

DrawString_Impl_ClipXMin:
	ld_sril XWA, (xsp + 0x013c)
	inc 4, xwa
	cpw (xwa), 0x140
	jr lt, DrawString_Impl_ClipXMax
	ldw (xwa), 0x13f

DrawString_Impl_ClipXMax:
	ld_sril XWA, (xsp + 0x013c)
	lda xhl, (xwa + 6)
	cpw (xhl), 0xf0
	jr lt, DrawString_Impl_ClipYMax
	ldw (xhl), 0xef

DrawString_Impl_ClipYMax:
	ld xiy, xbc
	st_dri3b D, 0xfd, 0x2c, 0x01
	ldiw
	ldiw
	st_dri3b D, 0xfd, 0x2c, 0x01
	cpw (xix), 0x0
	jr ge, DrawString_Impl_ClipCursorXMin
	ldw (xix), 0x0

DrawString_Impl_ClipCursorXMin:
	lda xbc, (xix + 2)
	cpw (xbc), 0x0
	jr ge, DrawString_Impl_ClipCursorYMin
	ldw (xbc), 0x0

DrawString_Impl_ClipCursorYMin:
	ld_sril XWA, (xsp + 0x0148)
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	ld xwa, 0x945c00
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 12)
	ld xiy, (xwa + 8)
	or xiz, xiz
	jr nz, DrawString_Impl_FixedWidthKerning
	ld wa, (xwa)
	ld (xsp + 16), wa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 6)
	ld (xsp + 18), wa
	jr DrawString_Impl_FontSetup

DrawString_Impl_FixedWidthKerning:
	ld (xsp + 8), xiz

DrawString_Impl_FontSetup:
	ld (xsp + 12), xiy
	st_dri3b H, 0xfd, 0x30, 0x01
	lda xiy, (xiz + 2)
	ld wa, (xbc)
	ld (xiy), wa
	ld wa, (xix)
	ld (xiz), wa
	ld wa, (xix)
	dec 1, wa
	ld (xiz + 4), wa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	add wa, (xbc)
	lda xbc, (xiz + 6)
	ld (xbc), wa
	ld wa, (xde)
	cp (xiy), wa
	jr ge, DrawString_Impl_ClampDirtyTop
	ld (xiy), wa

DrawString_Impl_ClampDirtyTop:
	ld wa, (xhl)
	cp (xbc), wa
	jr le, DrawString_Impl_ClampDirtyBottom
	ld (xbc), wa

DrawString_Impl_ClampDirtyBottom:
	lda xbc, (xsp + 40)
	ld_sril XWA, (xsp + 0x0138)
	call ConvertStrings
	lda xwa, (xsp + 40)
	ld (xsp + 24), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 12)
	or xwa, xwa
	jr nz, DrawString_Impl_VariableWidthLoop
	ld xwa, (xsp + 24)
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 16)
	mul xwa, xhl
	jr DrawString_Impl_ComputeDirtyRect

DrawString_Impl_VariableWidthLoop:
	ld xwa, (xsp + 24)
	cp (xwa), 0x0
	jr z, DrawString_Impl_KerningDone

DrawString_Impl_KerningLookup:
	ld xwa, (xsp + 24)
	ld_spib C, 0xe0
	ld (xsp + 24), xwa
	sub c, 0x20
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	exts xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 16), wa
	ld xwa, (xsp + 24)
	cp (xwa), 0x0
	jr nz, DrawString_Impl_KerningLookup

DrawString_Impl_KerningDone:
	ld wa, (xsp + 16)

DrawString_Impl_ComputeDirtyRect:
	add_sriw_mr WA, 0xfd, 0x34, 0x01
	st_dri3b W, 0xfd, 0x30, 0x01
	lda xde, (xwa + 2)
	ld_sril XBC, (xsp + 0x013c)
	ld bc, (xbc + 2)
	cp (xde), bc
	jr ge, DrawString_Impl_ClampDirtyLeft
	ld (xde), bc

DrawString_Impl_ClampDirtyLeft:
	ld de, (xwa)
	ld_sril XBC, (xsp + 0x013c)
	cp de, (xbc)
	jr ge, DrawString_Impl_ClampDirtyRight
	ld bc, (xbc)
	ld (xwa), bc

DrawString_Impl_ClampDirtyRight:
	lda xde, (xwa + 4)
	ld_sril XBC, (xsp + 0x013c)
	ld bc, (xbc + 4)
	cp (xde), bc
	jr le, DrawString_Impl_ClampDirtyRight2
	ld (xde), bc

DrawString_Impl_ClampDirtyRight2:
	lda xde, (xwa + 6)
	ld_sril XBC, (xsp + 0x013c)
	ld bc, (xbc + 6)
	cp (xde), bc
	jr le, DrawString_Impl_FillBackground
	ld (xde), bc

DrawString_Impl_FillBackground:
	ld_sriw BC, (xsp + 0x0144)
	cp bc, 0xf7
	call_24 nz, DrawBox_Impl
	lda xwa, (xsp + 40)
	ld (xsp + 24), xwa
	cp (xwa), 0x0
	jrl z, DrawString_Impl_SetChangeRect

DrawString_Impl_CharLoop:
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 12)
	or xwa, xwa
	jr nz, DrawString_Impl_CharVariableWidth
	ld bc, (xbc + 2)
	ld xwa, (xsp + 24)
	ld a, (xwa)
	sub a, 0x20
	extz wa
	mrdw3 0x9f, 0x12, 0x40
	mul xwa, xbc
	ld xde, xwa
	add xde, (xsp + 12)
	jr DrawString_Impl_GlyphSetup

DrawString_Impl_CharVariableWidth:
	ld xwa, (xsp + 24)
	ld c, (xwa)
	sub c, 0x20
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	exts xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 16), wa
	ld (xsp + 18), wa
	srl wa, 3
	inc 1, wa
	ld (xsp + 18), wa
	ld de, (xbc + 2)
	extz xde
	add xde, (xsp + 12)

DrawString_Impl_GlyphSetup:
	ldw (xsp + 20), 0x0
	cpw (xsp + 18), 0x0
	jrl ule, DrawString_Impl_CharAdvance

DrawString_Impl_ColumnLoop:
	ld wa, (xsp + 20)
	sll wa, 3
	ld bc, (xsp + 16)
	sub bc, wa
	cp bc, 0x8
	jr c, DrawString_Impl_ColumnSetup
	ldw bc, 0x8

DrawString_Impl_ColumnSetup:
	st_dri3b W, 0xfd, 0x2c, 0x01
	ld (xsp + 32), xwa
	inc 2, xwa
	ld (xsp + 36), xwa
	ld wa, (xwa)
	exts xwa
	ld xhl, xwa
	sll xhl, 2
	add xhl, xwa
	sll xhl, 6
	ld xwa, (xsp + 32)
	ld wa, (xwa)
	st_dri3b C, 0x07, 0xec, 0xe0
	lda_24 xwa, 0x043c00
	add xwa, xhl
	ld (xsp + 28), xwa
	ldw (xsp + 22), 0x0
	jr DrawString_Impl_RowCheck

DrawString_Impl_RowLoop:
	cp (xde), 0x0
	jr z, DrawString_Impl_RowAdvance
	st_dri3b C, 0xfd, 0x28, 0x01
	ld xwa, (xsp + 36)
	ld wa, (xwa)
	add wa, (xsp + 22)
	ld ix, wa
	ld iy, ix
	ld (xhl + 2), ix
	ld_sril XWA, (xsp + 0x013c)
	cp ix, (xwa + 2)
	jr lt, DrawString_Impl_RowAdvance
	ld xix, (xsp + 28)
	cp iy, (xwa + 6)
	jr gt, DrawString_Impl_ColumnAdvance
	lds iy, 0
	cps bc, 0
	jr ule, DrawString_Impl_RowAdvance

DrawString_Impl_PixelLoop:
	ld xwa, (xsp + 32)
	ld wa, (xwa)
	add wa, iy
	ld (xhl), wa
	ld_sril XIZ, (xsp + 0x013c)
	cp wa, (xiz)
	jr lt, DrawString_Impl_PixelAdvance
	ld wa, (xhl)
	cp wa, (xiz + 4)
	jr gt, DrawString_Impl_RowAdvance
	lds wa, 7
	sub wa, iy
	lds iz, 1
	and a, 0xf
	jr z, DrawString_Impl_TestBit
	slaa iz

DrawString_Impl_TestBit:
	ld a, (xde)
	extz wa
	and wa, iz
	jr z, DrawString_Impl_PixelAdvance
	ld_sriw WA, (xsp + 0x0146)
	ld (xix), a

DrawString_Impl_PixelAdvance:
	inc 1, xix
	inc 1, iy
	cp iy, bc
	jr c, DrawString_Impl_PixelLoop

DrawString_Impl_RowAdvance:
	inc 1, xde
	ld xwa, 0x140
	add (xsp + 28), xwa
	incm 1, (xsp + 22)

DrawString_Impl_RowCheck:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 22), wa
	jrl c, DrawString_Impl_RowLoop

DrawString_Impl_ColumnAdvance:
	ld xwa, (xsp + 32)
	add (xwa), bc
	incm 1, (xsp + 20)
	ld wa, (xsp + 20)
	cp wa, (xsp + 18)
	jrl c, DrawString_Impl_ColumnLoop

DrawString_Impl_CharAdvance:
	lds32 xwa, 1
	add (xsp + 24), xwa
	ld xwa, (xsp + 24)
	cp (xwa), 0x0
	jrl nz, DrawString_Impl_CharLoop

DrawString_Impl_SetChangeRect:
	st_dri3b W, 0xfd, 0x30, 0x01
	calr SetChangeRect

DrawString_Impl_Return:
	pop xiz
	st_dri3b L, 0xfd, 0x3c, 0x01
	retd 0x8

; =============================================================================
; DrawStringCentered - Draw text centered within a bounding rectangle
;
; Calculates the text width using CalcTotalWidth, then offsets the x/y
; position to center the string both horizontally and vertically within
; the specified rectangle.
;
; Input:
;   XWA = pointer to bounding rectangle
;   XBC = pointer to cursor state
;   XDE = pointer to null-terminated string
;   Stack: font_id (word), foreground_color (word), background_color (word)
; =============================================================================
DrawStringCentered:
	st_dri3b L, 0xfd, 0xf2, 0xfe
	pushw iz
	st_dri3l XBC, 0xfd, 0x08, 0x01
	st_dri3l XWA, 0xfd, 0x0c, 0x01
	lda xbc, (xsp + 4)
	ld xwa, xde
	call ConvertStrings
	lda xwa, (xsp + 4)
	ld_sril XBC, (xsp + 0x0118)
	call CalcTotalWidth
	ld iz, hl
	ld_sril XWA, (xsp + 0x0118)
	call GetCharHeight
	ld (xsp + 2), hl
	ld_sril XWA, (xsp + 0x0118)
	call GetCharDescent
	ld_sril XWA, (xsp + 0x0108)
	ld xiy, xwa
	st_dri3b D, 0xfd, 0x04, 0x01
	ldiw
	ldiw
	st_dri3b A, 0xfd, 0x04, 0x01
	ld wa, iz
	exts xwa
	divs wa, 0x2
	sub (xbc), wa
	ld wa, (xsp + 2)
	sub wa, hl
	exts xwa
	divs wa, 0x2
	sub (xbc + 2), wa
	ld_sril XWA, (xsp + 0x0118)
	call GetCenteredDelta
	st_dri3b A, 0xfd, 0x04, 0x01
	add (xbc + 2), hl
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0118)
	push xwa
	push_sriw 0xfd, 0x1a, 0x01
	push_sriw 0xfd, 0x1a, 0x01
	ld_sril XWA, (xsp + 0x0114)
	calr DrawString
	popw iz
	st_dri3b L, 0xfd, 0x0e, 0x01
	retd 0x8

; =============================================================================
; DrawStringLeftJustify - Draw text left-aligned, vertically centered
;
; Positions text at x = rect.left + 4, vertically centered within the rect.
; =============================================================================
DrawStringLeftJustify:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 10), xde
	ld xiz, xbc
	ld (xsp + 14), xwa
	ld xwa, (xsp + 26)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 26)
	call GetCharDescent
	ld xiy, xiz
	lda xix, (xsp + 6)
	ldiw
	ldiw
	lda xbc, (xsp + 6)
	ld xwa, (xsp + 14)
	ld wa, (xwa)
	inc 4, wa
	ld (xbc), wa
	ld wa, (xsp + 4)
	sub wa, hl
	exts xwa
	divs wa, 0x2
	sub (xbc + 2), wa
	ld xwa, (xsp + 26)
	call GetCenteredDelta
	lda xbc, (xsp + 6)
	add (xbc + 2), hl
	ld xwa, (xsp + 26)
	push xwa
	pushm (xsp + 28)
	pushm (xsp + 28)
	ld xwa, (xsp + 22)
	ld xde, (xsp + 18)
	calr DrawString
	pop xiz
	lda xsp, (xsp + 14)
	retd 0x8

; =============================================================================
; DrawStringRightJustify - Draw text right-aligned, vertically centered
;
; Positions text at x = rect.right - 4 - text_width, vertically centered.
; =============================================================================
DrawStringRightJustify:
	st_dri3b L, 0xfd, 0xf0, 0xfe
	push xiz
	st_dri3l XBC, 0xfd, 0x0c, 0x01
	st_dri3l XWA, 0xfd, 0x10, 0x01
	lda xbc, (xsp + 8)
	ld xwa, xde
	call ConvertStrings
	lda xwa, (xsp + 8)
	ld_sril XIZ, (xsp + 0x011c)
	ld xbc, xiz
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld xwa, xiz
	call GetCharHeight
	ld (xsp + 6), hl
	ld xwa, xiz
	call GetCharDescent
	ld_sril XWA, (xsp + 0x010c)
	ld xiy, xwa
	st_dri3b D, 0xfd, 0x08, 0x01
	ldiw
	ldiw
	st_dri3b A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0110)
	ld wa, (xwa + 4)
	dec 4, wa
	sub wa, (xsp + 4)
	ld (xbc), wa
	ld wa, (xsp + 6)
	sub wa, hl
	exts xwa
	divs wa, 0x2
	sub (xbc + 2), wa
	ld xwa, xiz
	call GetCenteredDelta
	st_dri3b A, 0xfd, 0x08, 0x01
	add (xbc + 2), hl
	lda xde, (xsp + 8)
	push xiz
	push_sriw 0xfd, 0x1e, 0x01
	push_sriw 0xfd, 0x1e, 0x01
	ld_sril XWA, (xsp + 0x0118)
	calr DrawString
	pop xiz
	st_dri3b L, 0xfd, 0x10, 0x01
	retd 0x8

; =============================================================================
; DrawStringAlignment - Draw text with specified alignment mode
;
; Dispatches to the appropriate aligned text drawing function based on mode.
;
; Input:
;   Stack byte: alignment mode (0=center, 1=left, 2=right)
;   Other args forwarded to the selected DrawString* variant
; =============================================================================
DrawStringAlignment:
	push xiz
	ld xiy, xbc
	ld hl, (xsp + 10)
	ld ix, (xsp + 12)
	ld xiz, (xsp + 14)
	ld c, (xsp + 8)
	cps c, 2		; mode 2 = right-justify
	jr z, DrawStringAlignment_RightJustify
	cps c, 1		; mode 1 = left-justify
	jr z, DrawStringAlignment_LeftJustify
	cps c, 0		; mode 0 = centered
	jr nz, DrawStringAlignment_Return
	push xiz
	pushw ix
	pushw hl
	ld xbc, xiy
	calr DrawStringCentered
	jr DrawStringAlignment_Return

DrawStringAlignment_LeftJustify:
	push xiz
	pushw ix
	pushw hl
	ld xbc, xiy
	calr DrawStringLeftJustify
	jr DrawStringAlignment_Return

DrawStringAlignment_RightJustify:
	push xiz
	pushw ix
	pushw hl
	ld xbc, xiy
	calr DrawStringRightJustify

DrawStringAlignment_Return:
	pop xiz
	retd 0xa

; =============================================================================
; DrawStringReverse - Draw text with inverted/reverse video appearance
;
; Renders text with swapped foreground and background colors relative to
; normal rendering. Supports all three alignment modes (0=center, 1=left,
; 2=right). Used for selected/highlighted menu items.
;
; Input:
;   XWA = pointer to bounding rectangle
;   XBC = pointer to cursor state
;   XDE = pointer to null-terminated string
;   Stack: alignment (byte), font_id, foreground, background
; =============================================================================
DrawStringReverse:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld (xsp + 24), xwa
	ld xiy, xbc
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 40)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld xwa, (xsp + 40)
	call GetCharHeight
	ld (xsp + 6), hl
	ld xwa, (xsp + 40)
	call GetCharDescent
	ld iz, hl
	ld xwa, (xsp + 40)
	call GetCenteredDelta
	lda xde, (xsp + 8)
	lda xbc, (xde + 2)
	ld wa, (xsp + 6)
	sub wa, iz
	ld ix, wa
	exts xix
	divs ix, 0x2
	ld wa, (xbc)
	sub wa, ix
	ld (xbc), wa
	add wa, hl
	ld (xbc), wa
	ld a, (xsp + 34)
	cps a, 2
	jr z, DrawStringReverse_AlignRight
	cps a, 1
	jr z, DrawStringReverse_AlignLeft
	cps a, 0
	jr nz, DrawStringReverse_ComputeTextBox
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub (xde), wa
	jr DrawStringReverse_ComputeTextBox

DrawStringReverse_AlignLeft:
	ld xwa, (xsp + 24)
	ld wa, (xwa)
	inc 4, wa
	ld (xde), wa
	jr DrawStringReverse_ComputeTextBox

DrawStringReverse_AlignRight:
	ld xwa, (xsp + 24)
	ld wa, (xwa + 4)
	dec 4, wa
	sub wa, (xsp + 4)
	ld (xde), wa

DrawStringReverse_ComputeTextBox:
	ld ix, hl
	add ix, ix
	ld wa, (xbc)
	dec 2, wa
	ld iy, wa
	sub iy, ix
	lda xwa, (xsp + 12)
	lda xix, (xwa + 2)
	ld (xix), iy
	ld iy, (xde)
	dec 3, iy
	ld (xwa), iy
	lda xiy, (xwa + 4)
	ld de, (xde)
	add de, (xsp + 4)
	inc 3, de
	ld (xiy), de
	lda xiz, (xwa + 6)
	ld bc, (xbc)
	add bc, (xsp + 6)
	add bc, hl
	ld (xiz), bc
	ld xbc, (xsp + 24)
	ld bc, (xbc + 2)
	cp (xix), bc
	jr ge, DrawStringReverse_ClampLeft
	ld (xix), bc

DrawStringReverse_ClampLeft:
	ld de, (xwa)
	ld xbc, (xsp + 24)
	cp de, (xbc)
	jr ge, DrawStringReverse_ClampLeftX
	ld bc, (xbc)
	ld (xwa), bc

DrawStringReverse_ClampLeftX:
	ld xbc, (xsp + 24)
	ld bc, (xbc + 4)
	cp (xiy), bc
	jr le, DrawStringReverse_ClampRight
	ld (xiy), bc

DrawStringReverse_ClampRight:
	ld xbc, (xsp + 24)
	ld bc, (xbc + 6)
	cp (xiz), bc
	jr le, DrawStringReverse_ClampBottom
	ld (xiz), bc

DrawStringReverse_ClampBottom:
	ld bc, (xix)
	cp bc, (xiz)
	jr gt, DrawStringReverse_Return
	ld bc, (xwa)
	cp bc, (xiy)
	jr gt, DrawStringReverse_Return
	ld iz, (xsp + 36)
	cpw (xsp + 32), 0x0
	jr z, DrawStringReverse_DrawNoHighlight
	ld bc, (xsp + 38)
	calr DrawBox
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 8)
	cp iz, 0xf5
	jr nz, DrawStringReverse_DrawNonPattern
	ld xde, (xsp + 40)
	push xde
	pushw 0x0
	pushw 0xf7
	ld xde, (xsp + 28)
	jr DrawStringReverse_CallDrawString

DrawStringReverse_DrawNonPattern:
	ld xde, (xsp + 40)
	push xde
	pushw iz
	pushw 0xf7
	ld xde, (xsp + 28)
	jr DrawStringReverse_CallDrawString

DrawStringReverse_DrawNoHighlight:
	ld bc, iz
	calr DrawBox
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 8)
	ld xde, (xsp + 40)
	push xde
	pushm (xsp + 42)
	pushw 0xf7
	ld xde, (xsp + 28)

DrawStringReverse_CallDrawString:
	calr DrawString

DrawStringReverse_Return:
	pop xiz
	lda xsp, (xsp + 24)
	retd 0xc

