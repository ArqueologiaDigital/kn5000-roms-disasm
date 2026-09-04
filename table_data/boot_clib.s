; =============================================================================
; Boot-time C runtime library: heap allocator, memcmp, 32-bit divide/modulo
; ROM 0x9FFB2F-0x9FFE7F (this module covers Boot_sbrk - formerly the tail of
; includes/bootcode_serial_state.bin - plus the allocator/compare/divide
; groups and the 0xFF pad up to the debug group in boot_debug.s).
;
; BOOT-TIME ALIAS: this code executes at 0xFFFB56-0xFFFE7F. At reset the
; table-data ROM is mapped at 0xE00000-0xFFFFFF; after the CS2 remap it
; appears at 0x800000-0x9FFFFF. All labels below are at ROM (0x9Fxxxx)
; addresses; every address cited in comments is given as the boot-time
; (0xFFxxxx) alias when it refers to runtime control flow.
;
; This group is a small compiler-runtime/libc subset used by the first-stage
; bootloader: a first-fit linked-list heap (head at RAM 0x0099A0, backed by
; the Boot_sbrk bump allocator at 0xFFFB2F), a bounded memory compare, and a
; 32-bit unsigned/signed divide-modulo runtime.
;
; Heap block layout (all blocks, free or allocated):
;   +0x00  u32  next        (free-list link; undefined while allocated)
;   +0x04  u16  size        (usable bytes, always even)
;   +0x06  ...  data        (pointer returned to callers)
; =============================================================================

; -----------------------------------------------------------------------------
; Boot_sbrk - bump allocator over the boot heap arena
; Boot addr 0xFFFB2F.
;
; Purpose:  Carve XWA bytes off the arena tracked by RAM (0x009998) current
;           pointer / (0x00999C) bytes remaining.
; Inputs:   XWA = byte count; 0 queries the remaining size.
; Outputs:  XHL = block address (old current pointer), bytes remaining for a
;           size-0 query, or 0xFFFFFFFF when the arena is exhausted.
; Callers:  Boot_malloc (grow-heap path below).
;
; Boot_free_DeadTail9998 pokes the same (0x009998) block, which is why that
; orphaned tail was likely written against this allocator.
; -----------------------------------------------------------------------------
Boot_sbrk:
	or	xwa, xwa
	jr	nz, Boot_sbrk__alloc
	ld	xhl, (0x00999c:24)		; size 0: report bytes remaining
	ret
Boot_sbrk__alloc:
	cp (0x00999c:24), xwa	; enough left?
	jr	nc, Boot_sbrk__fits
	ld	xhl, 0xffffffff		; arena exhausted
	ret
Boot_sbrk__fits:
	ld	xhl, (0x009998:24)		; XHL = current pointer
	addl_da	(0x009998), xwa
	subdm32_24 (0x00999c), xwa
	ret

; -----------------------------------------------------------------------------
; Boot_malloc - first-fit heap allocate
; Boot addr 0xFFFB56.
;
; Purpose:  Allocate a block of at least the requested size from the free
;           list at (0x0099A0); grow the heap via Boot_sbrk when no free
;           block fits.
; Inputs:   cdecl - u16 requested size at (XSP+6) (after the IZ save).
;           The request is rounded up to the next even size.
; Outputs:  XHL = pointer to the data area (header+6), or 0 on exhaustion.
; Clobbers: XWA, XBC, XDE, XIX, F.
; Callers:  Boot_DetectDiskType (boot 0xFFBFCE - sector-signature buffer),
;           LZSS_Decompress (boot 0xFFCA57 - 4KB sliding-window buffer).
;
; A free block whose size exceeds the request by 10 or more bytes is split:
; the front part (request size) is returned and the remainder (old size -
; request - 6 bytes, losing 6 to the new header) stays on the free list.
; -----------------------------------------------------------------------------
Boot_malloc:
	pushw iz
	ld wa, (xsp + 6)	; requested size
	inc 1, wa
	srl wa, 1
	ld iz, wa
	add iz, iz		; IZ = size rounded up to even
	ld xhl, (0x0099a0:24)	; XHL = free-list head
	jr t, Boot_malloc__scan_test
Boot_malloc__scan_loop:
	cp (xhl + 4), iz	; block size >= request?
	jr nc, Boot_malloc__scan_done
	ld xde, xhl		; XDE = previous block
	ld xhl, (xhl)		; XHL = block->next
Boot_malloc__scan_test:
	or xhl, xhl
	jr nz, Boot_malloc__scan_loop
Boot_malloc__scan_done:
	or xhl, xhl
	jr z, Boot_malloc__grow_heap	; no block fits - extend the heap
	lda xbc, (xhl + 4)	; XBC = &block->size
	ld wa, (xbc)
	sub wa, iz		; leftover = block size - request
	cp wa, 0x000a
	jr c, Boot_malloc__unlink	; leftover < 10: take the whole block
	; Split: carve the remainder off the back into its own free block
	ld wa, iz
	extz xwa
	inc 6, xwa		; request + 6-byte header
	ld xix, xhl
	add xix, xwa		; XIX = remainder block
	ld xwa, (xhl)
	ld (xix), xwa		; remainder->next = block->next
	ld wa, (xbc)
	dec 6, wa
	sub wa, iz
	ld (xix + 4), wa	; remainder->size = old - request - 6
	ld (xhl), xix		; block->next = remainder (unlinked below)
	ld (xbc), iz		; block->size = request
Boot_malloc__unlink:
	cp xhl, (0x0099a0)	; is the chosen block the list head?
	jr nz, Boot_malloc__unlink_mid
	ld xwa, (xhl)
	stl_da (0x0099a0), xwa	; head = block->next
	jr t, Boot_malloc__return_data
Boot_malloc__unlink_mid:
	ld xwa, (xhl)
	ld (xde), xwa		; prev->next = block->next
	jr t, Boot_malloc__return_data
Boot_malloc__grow_heap:
	ld wa, iz
	inc 6, wa
	extz xwa		; XWA = request + 6-byte header
	call Boot_sbrk + 0x600000	; boot-time alias of the bump
					; allocator defined above
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr nz, Boot_malloc__init_new
	lds32 xhl, 0		; heap exhausted: return NULL
	jr t, Boot_malloc__exit
Boot_malloc__init_new:
	lds32 xbc, 0
	ld (xwa), xbc		; new block: next = 0
	ld (xwa + 4), iz	; new block: size = request
Boot_malloc__return_data:
	inc 6, xhl		; return the data area, not the header
Boot_malloc__exit:
	popw iz
	ret

; -----------------------------------------------------------------------------
; Boot_memcmp - bounded memory compare (with strncmp-style NUL early-exit)
; Boot addr 0xFFFBDC.
;
; Purpose:  Compare two buffers byte-by-byte for up to len bytes.
; Inputs:   cdecl - (XSP+4) = u32 ptr a, (XSP+8) = u32 ptr b,
;           (XSP+12) = u16 len.
; Outputs:  HL = 0 if equal, else sign-extended (a[i] - b[i]) at the first
;           difference. NOTE: a matching 0x00 byte in a terminates the
;           compare early with HL = 0, so this is strncmp semantics, not
;           pure memcmp; the boot code only feeds it fixed-length signature
;           fields, where the distinction never matters.
; Clobbers: A, BC, XDE, XIX, F.
; Callers:  Boot_DetectDiskType (8 sites, boot 0xFFBFEC-0xFFC0C1 - disk
;           type signatures), LZSS_ParseHeader (boot 0xFFC9F5 - "SLIDE"
;           header magic).
; -----------------------------------------------------------------------------
Boot_memcmp:
	ld bc, (xsp + 12)	; len
	ld xde, (xsp + 8)	; b
	ld xix, (xsp + 4)	; a
	jr t, Boot_memcmp__test
Boot_memcmp__bytes_equal:
	cp (xix), 0x00		; equal AND NUL: stop, report equal
	jr nz, Boot_memcmp__advance
	lds hl, 0
	ret
Boot_memcmp__advance:
	inc 1, xix
	inc 1, xde
	dec 1, bc
Boot_memcmp__test:
	cps bc, 0
	jr z, Boot_memcmp__diff
	ld a, (xde)
	cp a, (xix)
	jr z, Boot_memcmp__bytes_equal
Boot_memcmp__diff:
	ldb l, 0x00
	cps bc, 0		; len exhausted: difference is 0
	jr z, Boot_memcmp__sign_extend
	ld a, (xix)
	sub a, (xde)		; a[i] - b[i]
	ld l, a
Boot_memcmp__sign_extend:
	exts hl
	ret

; -----------------------------------------------------------------------------
; Boot_SDivMod32 - signed 32-bit divide/modulo, common wrapper
; Boot addr 0xFFFC0E.
;
; Purpose:  Signed wrapper around Boot_UDivMod32: strips the operand signs,
;           divides the absolute values, then fixes the result sign.
; Inputs:   XWA = dividend, XBC = divisor,
;           D = mode: 0 = return remainder, 1 = return quotient.
;           Entered via the Boot_SMod32 / Boot_SDiv32 stubs below.
; Outputs:  XHL = result. Remainder takes the sign of the dividend (C
;           semantics); quotient is negative iff exactly one operand was.
; Clobbers: XWA, XBC, XDE, E, F.
; Callers:  none in this ROM - unreferenced compiler-runtime entry, kept
;           because the two entry stubs below jump here.
; -----------------------------------------------------------------------------
Boot_SDivMod32:
	ldb e, 0x00		; E = sign flags: bit0 dividend, bit1 divisor
	bit 15, qwa		; dividend negative?
	jr z, Boot_SDivMod32__abs_divisor
	ldb e, 0x01
	cpl qwa			; negate XWA (two's complement, 32-bit)
	cpl wa
	inc 1, xwa
Boot_SDivMod32__abs_divisor:
	bit 15, qbc		; divisor negative?
	jr z, Boot_SDivMod32__divide
	or e, 0x02
	cpl qbc			; negate XBC
	cpl bc
	inc 1, xbc
Boot_SDivMod32__divide:
	pushw de		; save mode (D) + sign flags (E)
	calr Boot_UDivMod32
	popw wa			; W = mode, A = sign flags
	cps w, 1
	jr z, Boot_SDivMod32__quotient
	ld xhl, xde		; remainder mode: result = remainder
	bit 0, a
	scc8 nz, a		; A = 1 iff the dividend was negative
	jr t, Boot_SDivMod32__fix_sign
Boot_SDivMod32__quotient:
	cps a, 3		; both negative: quotient stays positive
	ret z
Boot_SDivMod32__fix_sign:
	or xhl, xhl		; zero result needs no sign fix
	ret z
	cps a, 0		; both positive: no sign fix
	ret z
	cpl qhl			; negate XHL
	cpl hl
	inc 1, xhl
	ret

; -----------------------------------------------------------------------------
; Boot_SMod32 / Boot_SDiv32 - signed modulo / divide entry stubs
; Boot addr 0xFFFC55 / 0xFFFC59.
; Load the Boot_SDivMod32 mode selector (D=0 remainder, D=1 quotient).
; Callers: none in this ROM (unreferenced compiler-runtime entries).
; -----------------------------------------------------------------------------
Boot_SMod32:
	ldb d, 0x00
	jr t, Boot_SDivMod32
Boot_SDiv32:
	ldb d, 0x01
	jr t, Boot_SDivMod32

; -----------------------------------------------------------------------------
; Boot_UMod32 - unsigned 32-bit modulo
; Boot addr 0xFFFC5D.
;
; Inputs:   XWA = dividend, XBC = divisor.
; Outputs:  XHL = XWA mod XBC (remainder copied from XDE).
; Clobbers: XWA, XBC, XDE, F (everything Boot_UDivMod32 clobbers).
; Callers:  FDC_ReadSector (boot 0xFFBF76 - sector-within-track =
;           linear sector mod sectors-per-track).
; -----------------------------------------------------------------------------
Boot_UMod32:
	calr Boot_UDivMod32
	ld xhl, xde
	ret

; -----------------------------------------------------------------------------
; Boot_UDivMod32 - unsigned 32-bit divide/modulo core
; Boot addr 0xFFFC63.
;
; Purpose:  32/32 unsigned division producing quotient and remainder.
;           Uses the hardware 32/16 `div` when the divisor fits in 16 bits
;           (with a two-step long division on overflow), else a restoring
;           shift-subtract loop with the bit count in D.
; Inputs:   XWA = dividend, XBC = divisor.
; Outputs:  XHL = quotient, XDE = remainder.
;           Divide by zero returns XHL = 0xFFFFFFFF, XDE = 0.
; Clobbers: XWA, XBC, D, F.
; Callers:  FDC_ReadSector (boot 0xFFBF4C - track = linear sector /
;           sectors-per-track); Boot_UMod32 and Boot_SDivMod32 above.
; -----------------------------------------------------------------------------
Boot_UDivMod32:
	cp xbc, 0x00000001
	jr z, Boot_UDivMod32__divisor_one
	jr c, Boot_UDivMod32__divisor_zero
	cp xwa, xbc
	jr ule, Boot_UDivMod32__dividend_small
	cp qbc, 0		; divisor fits in 16 bits?
	jr nz, Boot_UDivMod32__long_division
	ld xde, xwa		; save dividend for the overflow path
	div xwa, xbc		; hardware 32/16: WA = quotient, QWA = remainder
	jr ov, Boot_UDivMod32__hw_overflow
	lds32 xhl, 0
	ld xde, xhl
	ld hl, wa		; XHL = zero-extended quotient
	ld de, qwa		; XDE = zero-extended remainder
	ret
Boot_UDivMod32__hw_overflow:
	; Quotient needs >16 bits: divide the high word first, then the low
	; word with the interim remainder carried in the upper half of XWA.
	ld wa, qde		; high word of the saved dividend
	extz xwa
	div xwa, xbc
	ld qhl, wa		; quotient high word
	ld wa, de		; low word of the saved dividend
	div xwa, xbc
	ld hl, wa		; quotient low word
	ld de, qwa		; remainder
	extz xde
	ret
Boot_UDivMod32__divisor_one:
	ld xhl, xwa		; q = dividend, r = 0
	lds32 xde, 0
	ret
Boot_UDivMod32__divisor_zero:
	lds32 xhl, 0
	ld xde, xhl
	dec 1, xhl		; q = 0xFFFFFFFF, r = 0
	ret
Boot_UDivMod32__dividend_small:
	; dividend <= divisor: equal gives q=1 r=0, less gives q=0 r=dividend
	lds32 xhl, 1
	lds32 xde, 0
	ret z			; Z still holds dividend == divisor
	dec 1, xhl
	ld xde, xwa
	ret
Boot_UDivMod32__long_division:
	ldb d, 0x00		; D = number of quotient bits
Boot_UDivMod32__normalize:
	cp xwa, xbc
	jr c, Boot_UDivMod32__norm_done
	inc 1, d
	add xbc, xbc		; shift divisor up to just above the dividend
	jr nc, Boot_UDivMod32__normalize
	rr xbc			; MSB shifted out: rotate it back through carry
	jr t, Boot_UDivMod32__bit_init
Boot_UDivMod32__norm_done:
	srl xbc, 1
Boot_UDivMod32__bit_init:
	lds32 xhl, 0
Boot_UDivMod32__bit_loop:
	add xhl, xhl		; quotient <<= 1
	cp xwa, xbc
	jr c, Boot_UDivMod32__bit_next
	set 0, l		; quotient |= 1
	sub xwa, xbc
Boot_UDivMod32__bit_next:
	srl xbc, 1
	djnz8 d, Boot_UDivMod32__bit_loop
	ld xde, xwa		; what is left of the dividend is the remainder
	ret

; -----------------------------------------------------------------------------
; Boot_free - return a block to the free list, coalescing neighbours
; Boot addr 0xFFFCDD.
;
; Purpose:  Insert the block back into the address-ordered free list at
;           (0x0099A0), merging it with the adjacent free block on either
;           side when they touch (forward merge absorbs the successor into
;           this block; backward merge absorbs this block into the
;           predecessor). Merging reclaims the absorbed block's 6-byte
;           header into the size field.
; Inputs:   cdecl - (XSP+8) = u32 data pointer as returned by Boot_malloc
;           (may be 0: no-op). A pointer already on the free list is
;           ignored (double-free guard via the address scan).
; Outputs:  none.
; Clobbers: XWA, XBC, XDE, XHL, XIX, XIY, F.
; Callers:  Boot_DetectDiskType (boot 0xFFC0D4 - frees the signature
;           buffer), LZSS_Decompress (boot 0xFFCC1F - frees the 4KB
;           sliding-window buffer).
; -----------------------------------------------------------------------------
Boot_free:
	push xiz
	ld xde, (xsp + 8)
	or xde, xde
	jrl z, Boot_free__exit	; free(NULL) is a no-op
	dec 6, xde		; data pointer -> block header
	ld xwa, (0x0099a0:24)
	or xwa, xwa
	jr nz, Boot_free__scan_init
	lds32 xwa, 0		; empty list: block becomes the only entry
	jr t, Boot_free__insert_head
Boot_free__scan_init:
	; Address-ordered scan: XIZ = cursor, XIX = predecessor of cursor
	ld xiz, xwa
	ld xix, xwa
	or xwa, xwa
	jr z, Boot_free__scan_done
Boot_free__scan_loop:
	cp xde, xiz		; advance while the cursor is below the block
	jr ule, Boot_free__scan_done
	ld xix, xiz
	ld xiz, (xiz)
	or xiz, xiz
	jr nz, Boot_free__scan_loop
Boot_free__scan_done:
	cp xde, xiz		; block already on the list: ignore
	jr z, Boot_free__exit
	lda xbc, (xde + 4)	; XBC = &block->size
	ld hl, (xbc)
	extz xhl
	ld xiy, xde
	inc 6, xiy
	add xiy, xhl		; XIY = end of block (header + size)
	cp xiz, xwa		; does the block sort before the list head?
	jr nz, Boot_free__mid_list
	cp xiy, xwa		; block end == old head: forward merge
	jr nz, Boot_free__insert_head
	ld xwa, (xwa)
	ld (xde), xwa		; block->next = head->next
	ld xwa, (0x0099a0:24)
	ld hl, (xwa + 4)
	inc 6, hl
	ld wa, (xbc)
	add wa, hl
	ld (xbc), wa		; block->size += head->size + 6
	jr t, Boot_free__set_head
Boot_free__insert_head:
	ld (xde), xwa		; block->next = old head (or 0)
Boot_free__set_head:
	stl_da (0x0099a0), xde
	jr t, Boot_free__exit
Boot_free__mid_list:
	or xiz, xiz		; at list end: nothing after to merge with
	jr z, Boot_free__link_next
	cp xiy, xiz		; block end == cursor: forward merge
	jr nz, Boot_free__link_next
	ld xwa, (xiz)
	ld (xde), xwa		; block->next = cursor->next
	ld wa, (xiz + 4)
	add wa, (xbc)
	inc 6, wa
	ld (xbc), wa		; block->size += cursor->size + 6
	jr t, Boot_free__backward_merge
Boot_free__link_next:
	ld (xde), xiz		; block->next = cursor
Boot_free__backward_merge:
	lda xhl, (xix + 4)	; XHL = &prev->size
	ld wa, (xhl)
	extz xwa
	ld xiy, xix
	inc 6, xiy
	add xiy, xwa		; XIY = end of predecessor
	cp xiy, xde		; predecessor end == block: backward merge
	jr nz, Boot_free__link_prev
	ld xwa, (xde)
	ld (xix), xwa		; prev->next = block->next
	ld wa, (xbc)
	add wa, (xhl)
	inc 6, wa
	ld (xhl), wa		; prev->size += block->size + 6
	jr t, Boot_free__exit
Boot_free__link_prev:
	ld (xix), xde		; prev->next = block
Boot_free__exit:
	pop xiz
	ret

; -----------------------------------------------------------------------------
; UNREACHABLE DEAD CODE - orphaned copy of the Boot_free tail
; Boot addr 0xFFFD7D-0xFFFDF9. No xref anywhere in the ROM, and there is no
; prologue: control cannot reach these labels. This is NOT a callable
; "secondary-heap free()": it is a byte-for-byte copy of Boot_free from its
; `extz xhl` onward with the free-list head address 0x0099A0 replaced by
; 0x009998 (the Boot_sbrk state block) - most likely leftover from an
; earlier firmware revision or an alternate build of the same source.
; Disassembled (rather than kept as raw bytes) purely for documentation.
; -----------------------------------------------------------------------------
Boot_free_DeadTail9998:
	extz xhl
	ld xiy, xde
	inc 6, xiy
	add xiy, xhl
	cp xiz, xwa
	jr nz, Boot_free_DeadTail9998__mid_list
	cp xiy, xwa
	jr nz, Boot_free_DeadTail9998__insert_head
	ld xwa, (xwa)
	ld (xde), xwa
	ld xwa, (0x009998:24)	; sbrk state block, NOT the 0x0099A0 list head
	ld hl, (xwa + 4)
	inc 6, hl
	ld wa, (xbc)
	add wa, hl
	ld (xbc), wa
	jr t, Boot_free_DeadTail9998__set_head
Boot_free_DeadTail9998__insert_head:
	ld (xde), xwa
Boot_free_DeadTail9998__set_head:
	stl_da (0x009998), xde
	jr t, Boot_free_DeadTail9998__exit
Boot_free_DeadTail9998__mid_list:
	or xiz, xiz
	jr z, Boot_free_DeadTail9998__link_next
	cp xiy, xiz
	jr nz, Boot_free_DeadTail9998__link_next
	ld xwa, (xiz)
	ld (xde), xwa
	ld wa, (xiz + 4)
	add wa, (xbc)
	inc 6, wa
	ld (xbc), wa
	jr t, Boot_free_DeadTail9998__backward_merge
Boot_free_DeadTail9998__link_next:
	ld (xde), xiz
Boot_free_DeadTail9998__backward_merge:
	lda xhl, (xix + 4)
	ld wa, (xhl)
	extz xwa
	ld xiy, xix
	inc 6, xiy
	add xiy, xwa
	cp xiy, xde
	jr nz, Boot_free_DeadTail9998__link_prev
	ld xwa, (xde)
	ld (xix), xwa
	ld wa, (xbc)
	add wa, (xhl)
	inc 6, wa
	ld (xhl), wa
	jr t, Boot_free_DeadTail9998__exit
Boot_free_DeadTail9998__link_prev:
	ld (xix), xde
Boot_free_DeadTail9998__exit:
	pop xiz
	ret

; -----------------------------------------------------------------------------
; UNREACHABLE DEAD CODE - second orphan: the last stanza of the same tail
; (backward-merge epilogue) duplicated once more. Also without any xref.
; -----------------------------------------------------------------------------
Boot_free_DeadTailFragment:
	ld xwa, (xde)
	ld (xix), xwa
	ld wa, (xbc)
	add wa, (xhl)
	inc 6, wa
	ld (xhl), wa
	jr t, Boot_free_DeadTailFragment__exit
	ld (xix), xde		; skipped by the jr above; kept for the copy
Boot_free_DeadTailFragment__exit:
	pop xiz
	ret

; 0xFF padding up to the debug-output group at ROM 0x9FFE80
	.fill 134, 1, 0xff
