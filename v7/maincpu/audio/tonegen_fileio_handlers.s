; =============================================================================
; Tone Generator Config & File I/O Handlers (1K lines)
; =============================================================================
;
; ToneGen_Config initialization, DSP configuration entry setup,
; FileIO callback handlers, and audio mode dispatch. Late-ROM
; routines before the main audio control engine.
; =============================================================================
; Ported from v10 by scripts/converters/port_v10_span_to_v7.py: every
; instruction below was re-assembled to the v7 bytes; `.byte` rows are v7
; bytes with no byte-identical v10 counterpart.  Comments carried over
; from v10 may cite v10 addresses.

ToneGen_IncrementWrap128:
	inc	1, ix
	cp	ix, 128
	jr	c, ToneGen_IncrementWrap128_Return
	ld	ix, 0:i3
ToneGen_IncrementWrap128_Return:
	ret
	cp	ix, 0:i3
	jr	nz, ToneGen_IncrementWrap128_Skip
	ldw	ix, 127
	ret
ToneGen_IncrementWrap128_Skip:
	dec	1, ix
	ret
ToneGen_Config_AlignByte:
	ret
; Validate the live panel -- block 0 at RAM 0xF9A0, block 1 at 0xFD60 -- then ToneGen_DispatchByMode.
PanelTlv_ValidateLivePanel:
	ld	xwa, 0xf9a0
	calr	PanelTlv_ValidateBlock0
	ld	xwa, 0xfd60
	calr	PanelTlv_ValidateBlock1
	call	ToneGen_DispatchByMode
	jp	SwbtWr_NullRet
; Validate block 0 of each of the 80 panel memories (RAM 0x1ED400 + 960*n).
PanelTlv_ValidatePanelMemories:
	dec	2, xsp
	push	xiz
	ldw	(xsp + 4), 0x0
	lda	xiz, (0x1ed400:24)
PanelTlv_ValidatePanelMemories_Loop:
	ld	xwa, xiz
	calr	PanelTlv_ValidateBlock0
	incw	1, (xsp + 4)
	lda	xiz, (xiz+960)
	cpw	(xsp + 4), 0x50
	jr	c, PanelTlv_ValidatePanelMemories_Loop
	pop	xiz
	inc	2, xsp
	ret
; Validate block 0 of panel memory wa, at RAM 0x1ED400 + 960*wa (wa >= 80 returns at once).
PanelTlv_ValidatePanelMemory:
	cp	wa, 80
	ret	nc
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	calr	PanelTlv_ValidateBlock0
	ret
; Validate the live panel, then the 80 panel memories.
PanelTlv_ValidateAll:
	calr	PanelTlv_ValidateLivePanel
	jr	PanelTlv_ValidatePanelMemories
; AND each PanelTlv_ResetMasks entry's mask into its live-panel byte (tag 0x80 payload byte 0, tag 0x98
; payload bytes 1, 3, 2 and 11), then BitMapOut_PrepareRender_CheckBit2(0) and fill the 16-character panel
; name (tag 0x78's payload at 0xF9A2) with spaces.  First step of Audio_ReinitToneGen and
; Audio_ReinitToneGenAndOutput, before PanelTlv_ValidateAll.
PanelTlv_ApplyResetMasks:
	lda	xwa, (PanelTlv_ResetMasks:24)
	lda	xbc, (xwa + 4)
	ld	xde, xwa
	lda	xhl, (xwa + 25)
PanelTlv_ApplyResetMasks_Loop:
	ld	xix, (xde)
	ld	a, (xbc)
	and	(xix), a
	inc	5, xde
	inc	5, xbc
	cp	xde, xhl
	jr	c, PanelTlv_ApplyResetMasks_Loop
	ld	wa, 0:i3
	call	BitMapOut_PrepareRender_CheckBit2
	pushw	0x10
	pushw	0x20
	pushw	0x0
	pushw	0xf9a2
	call	Memset
	inc	8, xsp
	ret
; Write every record header ([tag][len]) of the live panel and of the 80 panel memories.
PanelTlv_WriteAllHeaders:
	calr	PanelTlv_WriteLivePanelHeaders
	jrl	PanelTlv_WritePanelMemoryHeaders
SeqChan_WriteField_Data_E_Helper2:
	lda	xwa, (0xf480:16)
	jrl	PanelTlv_ValidateBlock0
; a jr to PanelTlv_ResolvePartCompanions, for callers outside its calr reach
PanelTlv_ResolvePartCompanions_Entry:
	jr	PanelTlv_ResolvePartCompanions
; For each of the 23 tags in PanelTlv_CompanionPartTags: the record's payload (PanelTlv_PayloadOfTag) and its
; companion record (PanelTlv_CompanionOfPart: 0xC0 + part, or tag 0x49 for the style record 0x48); a
; 5-byte frame {+0 offset, +1 value, +2 tag, +3 payload[0], +4 payload[1]} goes to
; SndParam_ResolveVoiceEntry, which fills +0/+1 from the record's sound; companion[+0] = +1.  A tag without
; a payload or a companion (0xFFFFFFFF) is skipped.
PanelTlv_ResolvePartCompanions:
	lda	xsp, (xsp - 14)
	push	xiz
	ldw	(xsp + 10), 0x0
PanelTlv_ResolvePartCompanions_Loop:
	ld	wa, (xsp + 10)
	extz	xwa
	ld	xbc, PanelTlv_CompanionPartTags
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xsp + 8), a
	extz	wa
	call	PanelTlv_PayloadOfTag
	ld	xiz, xhl
	cp	xiz, 0xffffffff
	jr	z, PanelTlv_ResolvePartCompanions_Next
	ld	a, (xsp + 8)
	extz	wa
	call	PanelTlv_CompanionOfPart
	ld	(xsp + 4), xhl
	ld	xwa, (xsp + 4)
	cp	xwa, 0xffffffff
	jr	z, PanelTlv_ResolvePartCompanions_Next
	lda	xwa, (xsp + 12)
	ld	c, (xiz)
	ld	(xwa + 3), c
	ld	c, (xiz + 1)
	ld	(xwa + 4), c
	ld	c, (xsp + 8)
	ld	(xwa + 2), c
	call	SndParam_ResolveVoiceEntry
	lda	xbc, (xsp + 12)
	ld	e, (xbc)
	extz	de
	ld	xwa, (xsp + 4)
	ld	c, (xbc + 1)
	ld	(xwa+de), c
PanelTlv_ResolvePartCompanions_Next:
	incw	1, (xsp + 10)
	cpw	(xsp + 10), 0x17
	jr	c, PanelTlv_ResolvePartCompanions_Loop
	pop	xiz
	lda	xsp, (xsp + 14)
	ret
Voice_CopyFromScratch:
	pushw	0x620
	pushw	0x3
	pushw	0xc8e4
	pushw	0x0
	pushw	0xf9a0
	call	Mem_Copy
	lda	xsp, (xsp + 10)
	ret
; Write the record headers of the live panel: block 0 at RAM 0xF9A0, block 1 at 0xFD60.
PanelTlv_WriteLivePanelHeaders:
	ld	xwa, 0xf9a0
	calr	PanelTlv_WriteBlock0Headers
	ld	xwa, 0xfd60
	jrl	PanelTlv_WriteBlock1Headers
; Write the block-0 record headers of each of the 80 panel memories (RAM 0x1ED400 + 960*n).
PanelTlv_WritePanelMemoryHeaders:
	dec	2, xsp
	push	xiz
	ldw	(xsp + 4), 0x0
	lda	xiz, (0x1ed400:24)
PanelTlv_WritePanelMemoryHeaders_Loop:
	ld	xwa, xiz
	calr	PanelTlv_WriteBlock0Headers
	incw	1, (xsp + 4)
	lda	xiz, (xiz+960)
	cpw	(xsp + 4), 0x50
	jr	c, PanelTlv_WritePanelMemoryHeaders_Loop
	pop	xiz
	inc	2, xsp
	ret
; xwa = a block-0 base.  PanelTlv_WriteRecordHeader for each of the 46 PanelTlv_Block0_Layout records
; (10 bytes each: index*5*2).
PanelTlv_WriteBlock0Headers:
	dec	4, xsp
	pushw	iz
	ld	(xsp + 2), xwa
	ld	iz, 0:i3
PanelTlv_WriteBlock0Headers_Loop:
	ld	bc, iz
	extz	xbc
	ld	xwa, xbc
	sll	xwa, 2
	add	xwa, xbc
	add	xwa, xwa
	ld	xbc, PanelTlv_Block0_Layout
	add	xbc, xwa
	ld	xwa, (xsp + 2)
	calr	PanelTlv_WriteRecordHeader
	inc	1, iz
	cp	iz, 0x2e
	jr	c, PanelTlv_WriteBlock0Headers_Loop
	popw	iz
	inc	4, xsp
	ret
; xwa = a block-0 base.  PanelTlv_ValidateRecord for each of the 46 PanelTlv_Block0_Layout records; then
; the five effect records go to DSPCfg_WriteAllSlots_Combined as slots 0..4 -- tags 0x61, 0x63, 0x65, 0x66,
; 0x64, whose payloads sit at base + 0x2D4, 0x2EE, 0x322, 0x33C, 0x308 (spelled 0xFC74.. - 0xF9A0 below).
PanelTlv_ValidateBlock0:
	dec	4, xsp
	pushw	iz
	ld	(xsp + 2), xwa
	ld	iz, 0:i3
PanelTlv_ValidateBlock0_Loop:
	ld	wa, iz
	extz	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	add	xde, xde
	ld	xbc, PanelTlv_Block0_Layout
	add	xbc, xde
	ld	xwa, (xsp + 2)
	calr	PanelTlv_ValidateRecord
	inc	1, iz
	cp	iz, 0x2e
	jr	c, PanelTlv_ValidateBlock0_Loop
	lda	xbc, (0xfc74:16)
	sub	xbc, 0xf9a0
	add	xbc, (xsp + 2)
	ld	wa, 0:i3
	call	DSPCfg_WriteAllSlots_Combined
	lda	xbc, (0xfc8e:16)
	sub	xbc, 0xf9a0
	add	xbc, (xsp + 2)
	ld	wa, 1:i3
	call	DSPCfg_WriteAllSlots_Combined
	lda	xbc, (0xfcc2:16)
	sub	xbc, 0xf9a0
	add	xbc, (xsp + 2)
	ld	wa, 2:i3
	call	DSPCfg_WriteAllSlots_Combined
	lda	xbc, (0xfcdc:16)
	sub	xbc, 0xf9a0
	add	xbc, (xsp + 2)
	ld	wa, 3:i3
	call	DSPCfg_WriteAllSlots_Combined
	lda	xbc, (0xfca8:16)
	sub	xbc, 0xf9a0
	add	xbc, (xsp + 2)
	ld	wa, 4:i3
	call	DSPCfg_WriteAllSlots_Combined
	popw	iz
	inc	4, xsp
	ret
; xwa = a block-1 base.  PanelTlv_ValidateRecord for each of the 30 PanelTlv_Block1_Layout records.
PanelTlv_ValidateBlock1:
	dec	4, xsp
	pushw	iz
	ld	(xsp + 2), xwa
	ld	iz, 0:i3
PanelTlv_ValidateBlock1_Loop:
	ld	bc, iz
	extz	xbc
	ld	xwa, xbc
	sll	xwa, 2
	add	xwa, xbc
	add	xwa, xwa
	ld	xbc, PanelTlv_Block1_Layout
	add	xbc, xwa
	ld	xwa, (xsp + 2)
	calr	PanelTlv_ValidateRecord
	inc	1, iz
	cp	iz, 0x1e
	jr	c, PanelTlv_ValidateBlock1_Loop
	popw	iz
	inc	4, xsp
	ret
; xwa = block base, xbc -> a layout record {u32 record_offset, u32 -> field rules, u8 tag, u8 len}
; (PanelTlv_Block0_Layout / PanelTlv_Block1_Layout, typed as panel_tlv_layout_t in
; ui_widgets/naka_extension_device.c).  The payload starts at base + record_offset + 2; the rules are
; applied in order, each by PanelTlv_ApplyFieldRule, which returns the rule's length in hl, up to the 0xFF
; that ends the list.
PanelTlv_ValidateRecord:
	dec	4, xsp
	push	xiz
	ld	(xsp + 4), xwa
	ld	xwa, (xbc)
	inc	2, xwa
	add	(xsp + 4), xwa
	ld	xiz, (xbc + 4)
	cp	(xiz), 0xff
	jr	z, PanelTlv_ValidateRecord_Return
PanelTlv_ValidateRecord_Loop:
	ld	xwa, (xsp + 4)
	ld	xbc, xiz
	calr	PanelTlv_ApplyFieldRule
	extz	xhl
	add	xiz, xhl
	cp	(xiz), 0xff
	jr	nz, PanelTlv_ValidateRecord_Loop
PanelTlv_ValidateRecord_Return:
	pop	xiz
	inc	4, xsp
	ret
; xwa = record payload, xbc -> one field rule.  Byte 0 is the type; the case named below applies it and
; returns its length in hl.  `off` is a payload byte; a reset keeps the bits outside the mask:
;   0 {0, off, mask}                  payload[off] &= mask                          KeepBits
;   1 {1, off, mask}                  payload[off] &= ~mask                         ClearBits
;   2 {2, off, mask}                  payload[off] |= mask                          SetBits
;   3 {3, off, mask, lo, hi, dflt}    (byte & mask) outside lo..hi -> dflt          ResetOutsideRange
;   4 {4, off, mask, lo, hi, dflt}    (byte & mask) inside lo..hi -> dflt           ResetInsideRange
;   5 {5, off, mask, n, dflt, v1..vn} (byte & mask) not among v1..vn -> dflt        ResetUnlessListed
;   6 {6, off, mask, n, dflt, v1..vn} (byte & mask) among v1..vn -> dflt            ResetIfListed
;   7 {7, off, value}                 payload[off] = value                          StoreByte
;   8 {8, off}                        payload[off] = 0                              ZeroByte
; The rule lists are PanelTlv_FieldRules (ui_widgets/extension_device_screens.s), written out with RULE_*
; macros in ui_widgets/naka_extension_device.c.
PanelTlv_ApplyFieldRule:
	ld	e, (xbc)
	extz	de
	cp	de, 0:i3
	jr	mi, PanelTlv_ApplyFieldRule_UnknownType
	cp	de, 0x8
	jr	gt, PanelTlv_ApplyFieldRule_UnknownType
	add	de, de
	lda	xix, (PanelTlv_ApplyFieldRule_CaseOffsets:24)
	ld	de, (xix+de)
	lda	xix, (PanelTlv_ApplyFieldRule_Case0:24)
	jp	t, (xix+de)
; the nine cases, by type byte, through PanelTlv_ApplyFieldRule_CaseOffsets
PanelTlv_ApplyFieldRule_Case0:
	calr	PanelTlv_Rule_KeepBits
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case1:
	calr	PanelTlv_Rule_ClearBits
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case2:
	calr	PanelTlv_Rule_SetBits
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case3:
	calr	PanelTlv_Rule_ResetOutsideRange
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case4:
	calr	PanelTlv_Rule_ResetInsideRange
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case5:
	calr	PanelTlv_Rule_ResetUnlessListed
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case6:
	calr	PanelTlv_Rule_ResetIfListed
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case7:
	calr	PanelTlv_Rule_StoreByte
	jr	PanelTlv_ApplyFieldRule_Return
PanelTlv_ApplyFieldRule_Case8:
	calr	PanelTlv_Rule_ZeroByte
	jr	PanelTlv_ApplyFieldRule_Return
; a type byte above 8 counts as a 1-byte rule
PanelTlv_ApplyFieldRule_UnknownType:
	ld	hl, 1:i3
PanelTlv_ApplyFieldRule_Return:
	ret
PanelTlv_Rule_KeepBits:
	ld	xde, xbc
	ld	l, (xde+0x1)
	extz	hl
	ld	c, (xde+0x2)
	and	(xwa+hl), c
	ld	hl, 3:i3
	ret
PanelTlv_Rule_ClearBits:
	ld	xde, xwa
	ld	l, (xbc+0x1)
	extz	hl
	ld	a, (xbc+0x2)
	cpl	a
	and	(xde+hl), a
	ld	hl, 3:i3
	ret
PanelTlv_Rule_SetBits:
	ld	xde, xbc
	ld	l, (xde+0x1)
	extz	hl
	ld	c, (xde+0x2)
	or	(xwa+hl), c
	ld	hl, 3:i3
	ret
PanelTlv_Rule_ResetOutsideRange:
	ld	xde, xwa
	ld	a, (xbc+0x1)
	extz	wa
	lda	xde, (xde+wa)
	ld	l, (xbc+0x2)
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x3), a
	jr	ugt, PanelTlv_Rule_ResetOutsideRange_Reset
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x4), a
	jr	nc, PanelTlv_Rule_ResetOutsideRange_Return
PanelTlv_Rule_ResetOutsideRange_Reset:
	cpl	l
	and	(xde), l
	ld	a, (xbc+0x5)
	or	(xde), a
PanelTlv_Rule_ResetOutsideRange_Return:
	ld	hl, 6:i3
	ret
PanelTlv_Rule_ResetInsideRange:
	ld	xde, xwa
	ld	a, (xbc+0x1)
	extz	wa
	lda	xde, (xde+wa)
	ld	l, (xbc+0x2)
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x3), a
	jr	ugt, PanelTlv_Rule_ResetInsideRange_Return
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x4), a
	jr	c, PanelTlv_Rule_ResetInsideRange_Return
	cpl	l
	and	(xde), l
	ld	a, (xbc+0x5)
	or	(xde), a
PanelTlv_Rule_ResetInsideRange_Return:
	ld	hl, 6:i3
	ret
PanelTlv_Rule_ResetUnlessListed:
	dec	6, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+0x1)
	extz	bc
	lda	xwa, (xwa+bc)
	ld	ix, 0:i3
	lda	xbc, (xde+0x3)
	ld	(xsp+0x2), xbc
	ld	c, (xbc)
	ld	(xsp+0x6), c
	ldfr_berp	c, 248
	extz	iz
	ld	l, (xde+0x2)
	ld	h, l
	and	h, (xwa)
	ld	xiy, 5:i3
	cp	ix, iz
	jr	nc, PanelTlv_Rule_ResetUnlessListed_Reset
PanelTlv_Rule_ResetUnlessListed_Loop:
	ld	xbc, xiy
	add	xbc, xde
	cp	(xbc), h
	jr	nz, PanelTlv_Rule_ResetUnlessListed_Next
	ld	a, (xsp+0x6)
	jr	PanelTlv_Rule_ResetUnlessListed_Return
PanelTlv_Rule_ResetUnlessListed_Next:
	inc	1, ix
	inc	1, xiy
	cp	ix, iz
	jr	c, PanelTlv_Rule_ResetUnlessListed_Loop
PanelTlv_Rule_ResetUnlessListed_Reset:
	cpl	l
	and	(xwa), l
	ld	c, (xde+0x4)
	or	(xwa), c
	ld	xwa, (xsp+0x2)
	ld	a, (xwa)
PanelTlv_Rule_ResetUnlessListed_Return:
	inc	5, a
	ld	l, a
	extz	hl
	popw	iz
	inc	6, xsp
	ret
PanelTlv_Rule_ResetIfListed:
	dec	4, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+0x1)
	extz	bc
	lda	xwa, (xwa+bc)
	ld	iy, 0:i3
	lda	xbc, (xde+0x3)
	ld	(xsp+0x2), xbc
	ld	c, (xbc)
	ldfr_berp	c, 248
	extz	iz
	ld	l, (xde+0x2)
	ld	h, l
	and	h, (xwa)
	ld	xix, 5:i3
	cp	iy, iz
	jr	nc, PanelTlv_Rule_ResetIfListed_Return
PanelTlv_Rule_ResetIfListed_Loop:
	ld	xbc, xix
	add	xbc, xde
	cp	(xbc), h
	jr	nz, PanelTlv_Rule_ResetIfListed_Next
	cpl	l
	and	(xwa), l
	ld	c, (xde+0x4)
	or	(xwa), c
	jr	PanelTlv_Rule_ResetIfListed_Return
PanelTlv_Rule_ResetIfListed_Next:
	inc	1, iy
	inc	1, xix
	cp	iy, iz
	jr	c, PanelTlv_Rule_ResetIfListed_Loop
PanelTlv_Rule_ResetIfListed_Return:
	ld	xwa, (xsp+0x2)
	ld	l, (xwa)
	inc	5, l
	extz	hl
	popw	iz
	inc	4, xsp
	ret
PanelTlv_Rule_StoreByte:
	ld	xde, xbc
	ld	l, (xde+0x1)
	extz	hl
	ld	c, (xde+0x2)
	ld	(xwa+hl), c
	ld	hl, 3:i3
	ret
PanelTlv_Rule_ZeroByte:
	ld	c, (xbc+0x1)
	extz	bc
	.byte	0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x00	; ld (XWA+BC),0x00
	ld	hl, 2:i3
	ret
	lda_d16	xwa, (0xf480)
	jrl	PanelTlv_WriteBlock0Headers
; xwa = a block-1 base.  PanelTlv_WriteRecordHeader for each of the 30 PanelTlv_Block1_Layout records.
PanelTlv_WriteBlock1Headers:
	dec	4, xsp
	pushw	iz
	ld	(xsp + 2), xwa
	ld	iz, 0:i3
PanelTlv_WriteBlock1Headers_Loop:
	ld	bc, iz
	extz	xbc
	ld	xwa, xbc
	sll	xwa, 2
	add	xwa, xbc
	add	xwa, xwa
	ld	xbc, PanelTlv_Block1_Layout
	add	xbc, xwa
	ld	xwa, (xsp + 2)
	calr	PanelTlv_WriteRecordHeader
	inc	1, iz
	cp	iz, 0x1e
	jr	c, PanelTlv_WriteBlock1Headers_Loop
	popw	iz
	inc	4, xsp
	ret
; xwa = block base, xbc -> a layout record: base[record_offset] = tag, base[record_offset + 1] = len.
PanelTlv_WriteRecordHeader:
	ld	xde, xbc
	ld	xbc, (xde)
	add	xwa, xbc
	ld	c, (xde + 8)
	ld	(xwa), c
	ld	c, (xde + 9)
	ld	(xwa + 1), c
	ret
DSPCfg_SyncBitmapData:
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+18), xbc
	ld	xiz, xwa
	lda	xwa, (SWBTWR_EVENT_QUEUE:16)
	ld	(xsp+14), xwa
	ld	(xsp+10), xwa
	ld	bc, (0x9042:16)
	jrl	DSPCfg_CopyEntryValues_Entry
DSPCfg_CopyEntryValues_Loop:
	ld	(xsp+6), 0
	ld	a, (xiz+)
	ld	(xsp+8), a
	ld	xwa, 2:i3
	add	(xsp+18), xwa
	.byte	0x8f
	ld	(PFFC:8), 0:io
	jr	z, DSPCfg_CopyEntryValues_Entry
DSPCfg_CopyEntryValues_Loop2:
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	.byte	0x86, 0xf1
	jr	z, DSPCfg_CopyEntryValues_Skip2
	cp	bc, 500
	jr	c, DSPCfg_CopyEntryValues_Skip
	extz	xbc
	add	xbc, (xsp+10)
	ld	(xbc), 255
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	bc, 0:i3
DSPCfg_CopyEntryValues_Skip:
	ld	de, bc
	inc	1, bc
	extz	xde
	add	xde, (xsp+10)
	ld	a, (xsp+4)
	ld	(xde), a
	ld	de, bc
	inc	1, bc
	extz	xde
	add	xde, (xsp+10)
	ld	a, (xsp+6)
	ld	(xde), a
	ld	de, bc
	inc	1, bc
	extz	xde
	add	xde, (xsp+10)
	ld	a, (xiz)
	ld	(xde), a
	ld	xwa, (xsp+18)
	ld	e, (xwa)
	xor	e, (xiz)
	ld	wa, bc
	inc	1, bc
	extz	xwa
	add	xwa, (xsp+10)
	ld	(xwa), e
DSPCfg_CopyEntryValues_Skip2:
	incm8	1, (xsp+6)
	decm8	1, (xsp+8)
	inc	1, xiz
	ld	xwa, 1:i3
	add	(xsp+18), xwa
	cp	(xsp+8), 0
	jr	nz, DSPCfg_CopyEntryValues_Loop2
DSPCfg_CopyEntryValues_Entry:
	ld	a, (xiz+)
	ld	(xsp+4), a
	cp	(xsp+4), 255
	jrl	nz, DSPCfg_CopyEntryValues_Loop
	ld	wa, bc
	extz	xwa
	add	xwa, (xsp+14)
	ld	(xwa), 255
	ld	(0x9042:16), bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
	ret
	ret
SndParam_SyncDisplayBitmap:
	ld	xwa, 0:i3
	call	AcApcToggleProc_Helper
	ld	(0x8dd0:16), l
	ld	xwa, 0x102
	call	AcApcToggleProc_Helper
	ld	(0x8dd2:16), l
	ld	xwa, 0x103
	call	AcApcToggleProc_Helper
	ld	(0x8dd4:16), l
	ld	xwa, 0x300
	call	AcApcToggleProc_Helper
	ld	(0x8dd6:16), l
	ld	xwa, 0x4006
	call	AcApcToggleProc_Helper
	ld	(0x8dd8:16), l
	pushw	0x620
	pushw	0x0
	pushw	0xf9a0
	pushw	0x3
	pushw	0xc8e4
	call	Mem_Copy
	lda	xsp, (xsp + 10)
	lda	xbc, (0xf9a0:16)
	lda	xwa, (0xf9b6:16)
	sub	xwa, xbc
	lda	xde, (0x03c8e4:24)
	add	xwa, xde
	xormi8	(xwa), 0x1
	lda	xwa, (0xf9d0:16)
	sub	xwa, xbc
	add	xwa, xde
	xormi8	(xwa), 0x1
	lda	xwa, (0xf9ea:16)
	sub	xwa, xbc
	add	xwa, xde
	xormi8	(xwa), 0x1
	lda	xwa, (0xfd97:16)
	sub	xwa, xbc
	add	xwa, xde
	ormi8	(xwa), 0x7f
	ret
SoundParam_NotifyMultipleChanges:
	ld	c, (0x8dd0:16)
	extz	bc
	ld	xwa, 0:i3
	ld	de, 0:i3
	call	Audio_ResetAfterPayloadError_Helper
	ld	c, (0x8dd2:16)
	extz	bc
	ld	xwa, 0x102
	ld	de, 0:i3
	call	Audio_ResetAfterPayloadError_Helper
	ld	c, (0x8dd4:16)
	extz	bc
	ld	xwa, 0x103
	ld	de, 0:i3
	call	Audio_ResetAfterPayloadError_Helper
	call	BitMapOut_DetectChanges
	jr	ToneGen_DiffScanAndUpdate
ToneGen_DiffScanAndUpdate:
	lda	xsp, (xsp - 14)
	pushw	iz
	ld	bc, (0x9042:16)
	lda	xwa, (SWBTWR_EVENT_QUEUE:16)
	ld	(xsp + 12), xwa
	ld	(xsp + 8), xwa
	ld	iz, 0:i3
	jrl	ToneGen_DiffScanCheckEnd
ToneGen_DiffScanOuter:
	ld	wa, iz
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xsp + 2), a
	ld	(xsp + 6), 0x0
	inc	1, iz
	ld	wa, iz
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xsp + 4), a
	cp	(xsp + 4), 0x0
	jrl	z, ToneGen_DiffOuterNext
ToneGen_DiffScanInner:
	inc	1, iz
	lda	xde, (0xfd60:16)
	ld	xwa, xde
	sub	xwa, 0xf9a0
	ld	hl, iz
	extz	xhl
	add	xhl, xwa
	lda	xwa, (0x03c8e4:24)
	add	xhl, xwa
	ld	wa, iz
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	cp	a, (xhl)
	jr	z, ToneGen_DiffInnerNext
	cp	bc, 0x1f4
	jr	c, ToneGen_DiffRecordChange
	extz	xbc
	add	xbc, (xsp + 8)
	ld	(xbc), 0xff
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	bc, 0:i3
ToneGen_DiffRecordChange:
	ld	de, bc
	inc	1, bc
	extz	xde
	add	xde, (xsp + 8)
	ld	a, (xsp + 2)
	ld	(xde), a
	ld	de, bc
	inc	1, bc
	extz	xde
	add	xde, (xsp + 8)
	ld	a, (xsp + 6)
	ld	(xde), a
	ld	wa, bc
	inc	1, bc
	extz	xwa
	ld	xix, xwa
	add	xix, (xsp + 8)
	lda	xhl, (0xfd60:16)
	ld	de, iz
	extz	xde
	add	xde, xhl
	ld	a, (xde)
	ld	(xix), a
	sub	xhl, 0xf9a0
	ld	xwa, xhl
	ld	hl, iz
	extz	xhl
	add	xhl, xwa
	lda	xwa, (0x03c8e4:24)
	add	xhl, xwa
	ld	e, (xde)
	xor	e, (xhl)
	ld	wa, bc
	inc	1, bc
	extz	xwa
	add	xwa, (xsp + 8)
	ld	(xwa), e
ToneGen_DiffInnerNext:
	incm8	1, (xsp + 6)
	decm8	1, (xsp + 4)
	jrl	nz, ToneGen_DiffScanInner
ToneGen_DiffOuterNext:
	inc	1, iz
ToneGen_DiffScanCheckEnd:
	lda	xde, (0xfd60:16)
	lda	xwa, (0xffbe:16)
	sub	xwa, xde
	ld	hl, iz
	extz	xhl
	cp	xhl, xwa
	jrl	lt, ToneGen_DiffScanOuter
	ld	wa, bc
	extz	xwa
	add	xwa, (xsp + 12)
	ld	(xwa), 0xff
	ld	(0x9042:16), bc
	popw	iz
	lda	xsp, (xsp + 14)
	ret
ToneGen_FileIO_SaveAndSync:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	calr	SndParam_SyncDisplayBitmap
	lda	xwa, (xsp + 4)
	ldmi16	(xwa), 0xfd50
	ldmi16	(xwa + 1), 0xfd52
	ldmi16	(xwa + 2), 0xfd54
	lda	xwa, (0xfda2:16)
	lda	xbc, (0xf9a0:16)
	sub	xwa, xbc
	pushw	wa
	push	xiz
	push	xbc
	call	Mem_Copy
	lda	xsp, (xsp + 10)
	lda	xwa, (xsp + 4)
	mrib4	0x80, 0x19, 0x50, 0xfd
	mrdb5	0x88, 0x01, 0x19, 0x52, 0xfd
	mrdb5	0x88, 0x02, 0x19, 0x54, 0xfd
	call	PanelTlv_ValidateLivePanel
	call	PanelTlv_ResolvePartCompanions_Entry
	calr	SoundParam_NotifyMultipleChanges
	pop	xiz
	inc	4, xsp
	ret
ToneGen_FileIO_RestoreFromBackup:
	calr	SndParam_SyncDisplayBitmap
	pushw	0x620
	pushw	0x3
	pushw	0xcf04
	pushw	0x0
	pushw	0xf9a0
	call	Mem_Copy
	lda	xsp, (xsp + 10)
	set	5, (0x8dda:16)
	calr	SoundParam_NotifyMultipleChanges
	call	SwbtWr_ReinitOutputBank
	call	ToneGen_DispatchByMode
	call	CtrlPanel_RefreshIndicatorState
	call	SwbtWr_NullRet
	res	5, (0x8dda:16)
	ret
; Compare the first 3 bytes of Custom Data Flash 0x3D3000 with SndParamBank_DefaultHeader ("HK "); on any
; difference fall into SndParamBank_WriteFlashDefaults.
SndParamBank_CheckFlash:
	lda	xhl, (SndParamBank_DefaultHeader:24)
	ld	xde, 0x3d3000
	ld	bc, 0:i3
SndParamBank_CheckFlash_Loop:
	ld	A, (xhl+)
	cp	A, (xde+)
	jr	nz, SndParamBank_WriteFlashDefaults
	inc	1, bc
	cp	bc, 3:i3
	jr	c, SndParamBank_CheckFlash_Loop
	ret
; FlashWrite the factory defaults of the sound-parameter banks: header + bank 0 (0xFA bytes) to 0x3D3000,
; SndParamBank_Default1 / _Default2 (0xEA each) to 0x3D3110 / 0x3D3210, then the 0x50-byte option block,
; assembled in a Malloc'd buffer from the five SndParamBank_OptionDefault_NN pieces, to 0x3D3400.
SndParamBank_WriteFlashDefaults:
	push	xiz
	ld	xwa, 0x3d3000
	push	xwa
	ld	wa, 1:i3
	ld	xbc, SndParamBank_DefaultHeader
	ldw	de, 0xfa
	call	FlashWrite
	lda	xbc, (SndParamBank_Default1:24)
	ld	xwa, 0x3d3110
	push	xwa
	ld	wa, 1:i3
	ldw	de, 0xea
	call	FlashWrite
	lda	xbc, (SndParamBank_Default2:24)
	ld	xwa, 0x3d3210
	push	xwa
	ld	wa, 1:i3
	ldw	de, 0xea
	call	FlashWrite
	pushw	0x50
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, SndParamBank_WriteFlashDefaults_Return
	pushw	0x0
	pushw	0x50
	push	xiz
	call	Memset
	pushw	0x2
	pushw	SndParamBank_OptionDefault_00@hi16
	pushw	SndParamBank_OptionDefault_00@lo16
	push	xiz
	call	Mem_Copy
	pushw	0xc
	pushw	SndParamBank_OptionDefault_10@hi16
	pushw	SndParamBank_OptionDefault_10@lo16
	lda	xwa, (xiz + 16)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp + 28)
	pushw	0x4
	pushw	SndParamBank_OptionDefault_20@hi16
	pushw	SndParamBank_OptionDefault_20@lo16
	lda	xwa, (xiz + 32)
	push	xwa
	call	Mem_Copy
	pushw	0x4
	pushw	SndParamBank_OptionDefault_30@hi16
	pushw	SndParamBank_OptionDefault_30@lo16
	lda	xwa, (xiz + 48)
	push	xwa
	call	Mem_Copy
	pushw	0x6
	pushw	SndParamBank_OptionDefault_40@hi16
	pushw	SndParamBank_OptionDefault_40@lo16
	lda	xwa, (xiz + 64)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp + 30)
	ld	xwa, 0x3d3400
	push	xwa
	ld	wa, 1:i3
	ld	xbc, xiz
	ldw	de, 0x50
	call	FlashWrite
	push	xiz
	call	Free
	inc	4, xsp
SndParamBank_WriteFlashDefaults_Return:
	pop	xiz
	ret
; Factory reset (Boot_HandleFactoryReset): rebuild the 0x50-byte option block at 0x3D3400 from the
; SndParamBank_OptionDefault_NN pieces, keeping the flash's own first 2 bytes, then Gfx_ClearFrameBuffers.
SndParamBank_RestoreOptionBlock:
	push	xiz
	pushw	0x50
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, SndParamBank_RestoreOptionBlock_Return
	pushw	0x0
	pushw	0x50
	push	xiz
	call	Memset
	pushw	0x2
	ld	xwa, 0x3d3400
	push	xwa
	push	xiz
	call	Mem_Copy
	pushw	0xc
	pushw	SndParamBank_OptionDefault_10@hi16
	pushw	SndParamBank_OptionDefault_10@lo16
	lda	xwa, (xiz + 16)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp + 28)
	pushw	0x4
	pushw	SndParamBank_OptionDefault_20@hi16
	pushw	SndParamBank_OptionDefault_20@lo16
	lda	xwa, (xiz + 32)
	push	xwa
	call	Mem_Copy
	pushw	0x4
	pushw	SndParamBank_OptionDefault_30@hi16
	pushw	SndParamBank_OptionDefault_30@lo16
	lda	xwa, (xiz + 48)
	push	xwa
	call	Mem_Copy
	pushw	0x6
	pushw	SndParamBank_OptionDefault_40@hi16
	pushw	SndParamBank_OptionDefault_40@lo16
	lda	xwa, (xiz + 64)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp + 30)
	ld	xwa, 0x3d3400
	push	xwa
	ld	wa, 1:i3
	ld	xbc, xiz
	ldw	de, 0x50
	call	FlashWrite
	push	xiz
	call	Free
	inc	4, xsp
	call	Gfx_ClearFrameBuffers
SndParamBank_RestoreOptionBlock_Return:
	pop	xiz
	ret
; Copy the five fields of the option block (0x3D3400 +0x00/+0x10/+0x20/+0x30/+0x40; 2, 12, 4, 4, 6 bytes)
; to RAM 0x340E4 / 0x340E6 / 0x340F2 / 0x340F6 / 0x340FA.
SndParamBank_LoadOptionBlock:
	pushw	0x2
	ld	xwa, 0x3d3400
	push	xwa
	pushw	0x3
	pushw	0x40e4
	call	Mem_Copy
	pushw	0xc
	ld	xwa, 0x3d3410
	push	xwa
	pushw	0x3
	pushw	0x40e6
	call	Mem_Copy
	pushw	0x4
	ld	xwa, 0x3d3420
	push	xwa
	pushw	0x3
	pushw	0x40f2
	call	Mem_Copy
	lda	xsp, (xsp + 30)
	pushw	0x4
	ld	xwa, 0x3d3430
	push	xwa
	pushw	0x3
	pushw	0x40f6
	call	Mem_Copy
	pushw	0x6
	ld	xwa, 0x3d3440
	push	xwa
	pushw	0x3
	pushw	0x40fa
	call	Mem_Copy
	lda	xsp, (xsp + 20)
	ret
CtrlPanel_IndicatorJumpTable:
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 0x8
	ret	gt
	add	wa, wa
	lda	xix, (CtrlPanel_IndicatorJumpTable_Data:24)
	ld	wa, (xix+wa)
	lda	xix, (DSPCfg_Param_CaseC:24)
	jp	t, (xix+wa)
; DSP config parameter handler C
DSPCfg_Param_CaseC:
	ret
CtrlPanel_IndicatorJumpTable_Case4:
	ld	xwa, 0x3d3400
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340e4
	ld	de, 2:i3
	jr	CtrlPanel_IndicatorJumpTable_Join
CtrlPanel_IndicatorJumpTable_Case5:
	ld	xwa, 0x3d3410
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340e6
	ldw	de, 12
	jr	CtrlPanel_IndicatorJumpTable_Join
CtrlPanel_IndicatorJumpTable_Case6:
	ld	xwa, 0x3d3420
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340f2
	ld	de, 4:i3
	jr	CtrlPanel_IndicatorJumpTable_Join
CtrlPanel_IndicatorJumpTable_Case7:
	ld	xwa, 0x3d3430
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340f6
	ld	de, 4:i3
	jr	CtrlPanel_IndicatorJumpTable_Join
CtrlPanel_IndicatorJumpTable_Case8:
	ld	xwa, 0x3d3440
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340fa
	ld	de, 6:i3
CtrlPanel_IndicatorJumpTable_Join:
	call	FlashWrite
	ret
Audio_DispatchCommand:
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 0x8
	ret	gt
	add	wa, wa
	lda	xix, (Audio_DispatchCommand_Data:24)
	ld	wa, (xix+wa)
	lda	xix, (DSPCfg_Param_CaseD:24)
	jp	t, (xix+wa)
; DSP config parameter handler D
DSPCfg_Param_CaseD:
	ret
Audio_DispatchCommand_Case4:
	pushw	2
	ld	xwa, 0x3d3400
	push	xwa
	ld	xwa, 0x0340e4
	jr	Audio_DispatchCommand_Join
Audio_DispatchCommand_Case5:
	pushw	12
	ld	xwa, 0x3d3410
	push	xwa
	ld	xwa, 0x0340e6
	jr	Audio_DispatchCommand_Join
Audio_DispatchCommand_Case6:
	pushw	4
	.asciz	"@ 4="
	push	xwa
	ld	xwa, 0x0340f2
Audio_DispatchCommand_Join:
	push	xwa
	jr	Audio_DispatchCommand_Join2
Audio_DispatchCommand_Case7:
	pushw	4
	ld	xwa, 0x3d3430
	push	xwa
	pushw	3
	pushw	0x40f6
	jr	Audio_DispatchCommand_Join2
Audio_DispatchCommand_Case8:
	pushw	6
	ld	xwa, 0x3d3440
	push	xwa
	pushw	3
	pushw	0x40fa
Audio_DispatchCommand_Join2:
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
PanelDisplay_DispatchByMode:
	extz	wa
	cp	wa, 0:i3
	jrl	mi, DSPCfg_Param_Default
	cp	wa, 0x8
	jrl	gt, DSPCfg_Param_Default
	add	wa, wa
	lda	xix, (PanelDisplay_DispatchByMode_Data:24)
	ld	wa, (xix+wa)
	lda	xix, (PanelDisplay_DispatchData:24)
	jp	t, (xix+wa)
PanelDisplay_DispatchData:
	ld	xde, 0x3d3400
	lda	xhl, (0x0340e4:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 2:i3
	jr	c, PanelDisplay_DispatchByMode_Loop
	jr	DSPCfg_Param_Default
PanelDisplay_DispatchByMode_Case5:
	ld	xde, 0x3d3410
	lda	xhl, (0x0340e6:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop2:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 12
	jr	c, PanelDisplay_DispatchByMode_Loop2
	jr	DSPCfg_Param_Default
PanelDisplay_DispatchByMode_Case6:
	ld	xde, 0x3d3420
	lda	xhl, (0x0340f2:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop3:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 4:i3
	jr	c, PanelDisplay_DispatchByMode_Loop3
	jr	DSPCfg_Param_Default
PanelDisplay_DispatchByMode_Case7:
	ld	xde, 0x3d3430
	lda	xhl, (0x0340f6:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop4:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 4:i3
	jr	c, PanelDisplay_DispatchByMode_Loop4
	jr	t, DSPCfg_Param_Default
PanelDisplay_DispatchByMode_Case8:
	ld	xde, 0x3d3440	; was .asciz "B@4="
	lda	xhl, (0x0340fa:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop5:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	z, PanelDisplay_DispatchByMode_Skip2
PanelDisplay_DispatchByMode_Skip:
	ld	hl, 1:i3
	ret
PanelDisplay_DispatchByMode_Skip2:
	inc	1, bc
	cp	bc, 6:i3
	jr	c, PanelDisplay_DispatchByMode_Loop5
; DSP config parameter default handler
DSPCfg_Param_Default:
	ld	hl, 0:i3
	ret
Encoder_MarkInvalid:
	ld	(0xbf9d:16), 255
	ret
Encoder_Stub1:
	ret
Encoder_Stub2:
	ret
Encoder_Stub3:
	ret
Encoder_AlignByte:
	ret
; Dispatch every queued panel change (PanelButton_FetchChange, then PanelButton_DispatchChange), end the
; event queue at (0xC039) with 0xFF, clear the change queue, then VoiceEntry_FindMasterVolume.
PanelButton_ProcessChanges:
	ld	(0x8df0:16), 0
	ld	(0x8df2:16), 0
	jr	PanelButton_ProcessChanges_Loop
PanelButton_ProcessChanges_Next:
	calr	PanelButton_FetchChange
	calr	PanelButton_DispatchChange
PanelButton_ProcessChanges_Loop:
	call	PanelInput_ChangeQueue
	ld	a, (0x8df0:16)
	extz	wa
	muls	wa, 0x3
	ld	a, (xhl+wa)
	ld	(0x8df4:16), a
	cp	a, 0xff
	jr	nz, PanelButton_ProcessChanges_Next
	ld	a, (0x8df2:16)
	extz	wa
	sll	wa, 2
	lda	xbc, (0xbf9d:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0xff
	call	PanelInput_ClearChangeQueue
	jrl	VoiceEntry_FindMasterVolume
PanelButton_FetchChange:
	call	PanelInput_ChangeQueue
	ld	a, (0x8df0:16)
	extz	wa
	muls	wa, 0x3
	lda	xiy, (xhl+wa)
	ld	xix, 0x8ddc
	ldi85
	ldiw
	inc	1, (0x8df0:16)
	ret
; One queued panel change {event index, new state, changed bits} (RAM 0x8E78, the index also at 0x8E90): walk
; PanelButton_ActionLists[index] (PanelButton_HelpModeActionLists in mode 20, MD_HELP).  The frame at
; (0x8E7C) gets {0xAA, index, state, changed} at +4; per action, +0..+3 = {event_id, event_arg, state & mask,
; changed & mask} shifted by the action's shift; the handler is called when the masked changed bits are not 0.
PanelButton_DispatchChange:
	push	xiz
	ld	c, (0x8df4:16)
	extz	bc
	sla	bc, 2
	ld	xwa, PanelButton_ActionLists
	cp	(CURRENT_MODE:16), 20
	jr	nz, PanelButton_DispatchChange_Frame
	ld	xwa, PanelButton_HelpModeActionLists
PanelButton_DispatchChange_Frame:
	ld	xiz, (xwa+bc)
	lda	xbc, (0x8de0:16)
	ld	(xbc + 4), 0xaa
	ldmi16	(xbc + 5), 0x8df4
	lda	xde, (0x8ddc:16)
	ld	a, (xde + 1)
	ld	(xbc + 6), a
	ld	a, (xde + 2)
	ld	(xbc + 7), a
	jr	PanelButton_DispatchChange_Loop
PanelButton_DispatchChange_Action:
	lda	xhl, (0x8ddc:16)
	ld	e, (xiz + 3)
	ld	d, e
	and	d, (xhl + 1)
	and	e, (xhl + 2)
	ld	l, e
	ld	e, (xiz + 2)
	bit	4, e
	jr	z, PanelButton_DispatchChange_ShiftRight
	res	4, e
	ld	a, e
	and	a, 0xf
	jr	z, PanelButton_DispatchChange_ShiftNewLeft
	slla	d
PanelButton_DispatchChange_ShiftNewLeft:
	ld	a, e
	and	a, 0xf
	jr	z, PanelButton_DispatchChange_Shifted
	slla	l
PanelButton_DispatchChange_Shifted:
	jr	PanelButton_DispatchChange_Call
; --- Audio Control, File I/O & MIDI Processing ---
; (pre-port v7 note about the bytes at 0xFC506F:)
; --- Audio Control, File I/O & MIDI Processing ---
