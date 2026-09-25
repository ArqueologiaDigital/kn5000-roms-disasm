; =============================================================================
; SECTION DIRECTORY + BITMAP BANK (0x800000 - 0x82FFFF)
; =============================================================================
; ROM range 0x800000-0x82FFFF (plus entries 6 and 28-32, which live in
; ui_bitmaps.s): a 34-entry directory of 4-byte little-endian pointers
; (33 targets + a null terminator) and the 8bpp BITMAPS it points at.
; Directory order is not address order: entry 7 lies after entries 8-27,
; and entries 6 and 28-32 point forward into the UI-bitmap half (0x91D000-
; 0x92DDA0).  Byte facts kept from the earlier reading: entries 3-5 differ
; pairwise in 162-260 bytes (the knob), 25/26 in 48 and 25/27 in 1,260 (the
; arrows of the diagrams), and the split pictures 13-24 recolour 260..1,700
; white (0xFF -> 0xFE) and 0..580 black (0x00 -> 0xFC) pixels of picture 12.
;
; WHAT THE ENTRIES ARE (established 2026-09-25): every one of the 33 targets
; is an 8bpp indexed bitmap, byte-identical to an image the program ROM
; carries for itself and that this tree already extracts under
; v10/maincpu/images/ (the PNG there is the build source, via
; scripts/build/indexed_images.py).  So each is emitted from that file, the
; single-sourcing ui_bitmaps.s already used for entries 6 and 28-32.  Two
; independent confirmations of the geometry:
;   * the 17 accessor routines at 0x82F000 (SectionInfo_SecNN, end of this
;     module) return (base, width, height) for entries 0-11 and 28-32, and
;     width x height is each image's size (entry 10: 113 x 25 in 114-byte
;     rows);
;   * the entries tile 0x800088-0x82E9C1 with no gap: each target is the
;     previous one plus its image size.
;
; READERS: none found for the directory or for these copies.  Every target
; address was searched as a 24-bit and a 32-bit little-endian constant in
; the v7/v9/v10 program ROMs, the v142 sub-CPU program, custom data (IC19)
; and the HD-AE5000 ROM: the only hits are byte coincidences (v10/v9
; 0xFA4081, v7 0xFA3C74: operand bytes of an add xwa,(xsp+0x0088); v7
; 0xEAFD41: a 0x00 byte followed by two bytes of the 24-bit value 0xF991D0).
; The program draws its OWN copies (v10 labels quoted per entry below).
; Within this ROM, the accessor routines hold the only references.  The
; firmware does write this half of the chip:
; its flash primitives unlock it with AMD command cycles at 0x815554/0x80AAA8
; (chip word addresses 0xAAAA/0x5554, which merely fall inside entries 25
; and 10), and "Technics KN5000 Table    DATA FILE 1/2" update floppies
; rewrite the whole 0x800000 half via HANDLE_UPDATE_FILE_TYPE_ID_003h ->
; Flash_BurnWithProgress + FDC_WriteSectors (maincpu boot/system_handlers.s).
;
; CORRECTED 2026-09-25.  This module used to be called "PRESET DATA BANKS"
; and read the region as "the rewritable user-data area ... factory defaults
; for the user's sound/registration/composer memories", with a fill-pattern
; legend (0xF7/0xF8 "erased-flash background", 0x07/0x06 "default parameter
; values") and "record grids" found by autocorrelation (sec 0/1: 95 x 120 B,
; sec 3-5: 222 x 22 B, sec 12-24: 13 "user slots" of 52 x 58 B, sec 25-27:
; "user banks" of 108 x 296 B, ...).  The grids were real -- they are the
; images' row lengths and heights -- but the reading was wrong: the byte
; values are palette indices (0xF7 is the transparent colour), and the
; per-slot "re-marking" of entries 12-24 (0xFF -> 0xFE, 0x00 -> 0xFC) is the
; split-point pictures recolouring the keys on one side of the split.  The
; 12,000 lines of .byte rows are replaced by 26 .incbin lines; labels
; PresetBank_SecNN became SectionBankNN_<image> (map:
; scripts/renaming/rename_tdata_section_banks.sed).
;
; This file was bootstrapped by scripts/generators/generate_preset_banks.py
; (commit e50f3c99) and has been hand-maintained since; regenerating it
; would discard this conversion.
; Check: python3 scripts/analysis/tdata_evidence_probes.py  (sections)
; =============================================================================

SectionDirectory_Table:
	.long	SectionBank00_AccordionGer16		; entry  0: 120x95
	.long	SectionBank01_AccordionIta16		; entry  1: 120x95
	.long	SectionBank02_ArrowStrip		; entry  2: 294x6
	.long	SectionBank03_DrawbarSlider1		; entry  3: 22x222
	.long	SectionBank04_DrawbarSlider2		; entry  4: 22x222
	.long	SectionBank05_DrawbarSlider3		; entry  5: 22x222
	.long	SectionBank06_TechnicsLogo		; entry  6: (UI-bitmap half, ui_bitmaps.s)
	.long	SectionBank07_KN5000Logo		; entry  7: 199x36 (in this module, below)
	.long	SectionBank08_FadeInPicture		; entry  8: 112x25
	.long	SectionBank09_FadeInText		; entry  9: 80x18
	.long	SectionBank10_FadeOutPicture		; entry 10: 113x25
	.long	SectionBank11_FadeOutText		; entry 11: 108x20
	.long	SectionBank12_SplitPoint_None		; entry 12: 58x52
	.long	SectionBank13_SplitPoint_C		; entry 13: 58x52
	.long	SectionBank14_SplitPoint_Db		; entry 14: 58x52
	.long	SectionBank15_SplitPoint_D		; entry 15: 58x52
	.long	SectionBank16_SplitPoint_Eb		; entry 16: 58x52
	.long	SectionBank17_SplitPoint_E		; entry 17: 58x52
	.long	SectionBank18_SplitPoint_F		; entry 18: 58x52
	.long	SectionBank19_SplitPoint_Gb		; entry 19: 58x52
	.long	SectionBank20_SplitPoint_G		; entry 20: 58x52
	.long	SectionBank21_SplitPoint_Ab		; entry 21: 58x52
	.long	SectionBank22_SplitPoint_A		; entry 22: 58x52
	.long	SectionBank23_SplitPoint_Bb		; entry 23: 58x52
	.long	SectionBank24_SplitPoint_B		; entry 24: 58x52
	.long	SectionBank25_MIDIConnections1		; entry 25: 296x108
	.long	SectionBank26_MIDIConnections2		; entry 26: 296x108
	.long	SectionBank27_MIDIConnections3		; entry 27: 296x108
	.long	SectionBank28_KN5000Picture		; entry 28: (UI-bitmap half, ui_bitmaps.s)
	.long	SectionBank29_NoteEditKeyboard		; entry 29: (UI-bitmap half, ui_bitmaps.s)
	.long	SectionBank30_NoteEditGrid		; entry 30: (UI-bitmap half, ui_bitmaps.s)
	.long	SectionBank31_DrumEditRows		; entry 31: (UI-bitmap half, ui_bitmaps.s)
	.long	SectionBank32_DrumEditGrid		; entry 32: (UI-bitmap half, ui_bitmaps.s)
	.long	0x00000000				; terminator

; -----------------------------------------------------------------------------
; The 26 bitmaps of entries 0-5 and 8-27, in address order (0x800088-0x82CDA1).
; Each: 8bpp palette indices, row-major, 0xF7 = transparent; the comment names
; the byte-identical program-ROM copy (v10 label and address).
; -----------------------------------------------------------------------------
; entry 0, 120x95: accordion picture, grey bellows on green ("accger16")
; == program ROM Bitmap_Accger16 (v10 0xE892FE)
; SectionInfo_Sec00 returns (base, 120, 95)
SectionBank00_AccordionGer16:	.incbin "../v10/maincpu/images/BitmapAccger16.bin"
; entry 1, 120x95: the same accordion recoloured orange ("accita16"): 3,280
; of entry 0's 3,981 index-0xF8 pixels read 0x0A here, and nothing else
; differs
; == program ROM Bitmap_Accita16 (v10 0xE86676)
; SectionInfo_Sec01 returns (base, 120, 95)
SectionBank01_AccordionIta16:	.incbin "../v10/maincpu/images/BitmapAccita16.bin"
; entry 2, 294x6: strip of small orange/green triangles
; == program ROM Bitmap_SomeArrows (v10 0xE8BF86)
; SectionInfo_Sec02 returns (base, 294, 6)
SectionBank02_ArrowStrip:	.incbin "../v10/maincpu/images/BitmapSomeArrows.bin"
; entry 3, 22x222: drawbar scale 8..1 with a red knob
; == program ROM BitmapBound_DrawbarSlider1_Start (v10 0xE8C66A)
; SectionInfo_Sec03 returns (base, 22, 222)
SectionBank03_DrawbarSlider1:	.incbin "../v10/maincpu/images/BitmapDrawbarNumberedSlider_1.bin"
; entry 4, 22x222: drawbar scale 8..1 with a white knob
; == program ROM BitmapBound_DrawbarSlider2_Start (v10 0xE8D97E)
; SectionInfo_Sec04 returns (base, 22, 222)
SectionBank04_DrawbarSlider2:	.incbin "../v10/maincpu/images/BitmapDrawbarNumberedSlider_2.bin"
; entry 5, 22x222: drawbar scale 8..1 with a black knob
; == program ROM BitmapBound_DrawbarSlider3_Start (v10 0xE8EC92)
; SectionInfo_Sec05 returns (base, 22, 222)
SectionBank05_DrawbarSlider3:	.incbin "../v10/maincpu/images/BitmapDrawbarNumberedSlider_3.bin"
; entry 8, 112x25: widening grey wedge (fade-in symbol)
; == program ROM Bitmap_FadeInPicture (v10 0xEB8072)
; SectionInfo_Sec08 returns (base, 112, 25)
SectionBank08_FadeInPicture:	.incbin "../v10/maincpu/images/BitmapFadeInPicture.bin"
; entry 9, 80x18: "FADE IN" lettering
; == program ROM Bitmap_FadeInText (v10 0xEB8B62)
; SectionInfo_Sec09 returns (base, 80, 18)
SectionBank09_FadeInText:	.incbin "../v10/maincpu/images/BitmapFadeInText.bin"
; entry 10, 113x25: narrowing grey wedge (fade-out symbol); odd width, so
; each row carries one pad byte (0x00 at +113 of all 25 rows) -- 2,850 B
; == program ROM Bitmap_FadeOutPicture (v10 0xEB9102)
; SectionInfo_Sec10 returns (base, 113, 25)
SectionBank10_FadeOutPicture:	.incbin "../v10/maincpu/images/BitmapFadeOutPicture.bin"
; entry 11, 108x20: "FADE OUT" lettering
; == program ROM Bitmap_FadeOutText (v10 0xEB9C24)
; SectionInfo_Sec11 returns (base, 108, 20)
SectionBank11_FadeOutText:	.incbin "../v10/maincpu/images/BitmapFadeOutText.bin"
; entry 12, 58x52: one-octave keyboard picture, no split marked
; == program ROM Bitmap_SplitPoint_no_split (v10 0xE5AE4A)
SectionBank12_SplitPoint_None:	.incbin "../v10/maincpu/images/BitmapSplitPoint_no_split.bin"
; entry 13, 58x52: one-octave keyboard picture with the split at C marked
; == program ROM Bitmap_SplitPoint_C (v10 0xE5BA12)
SectionBank13_SplitPoint_C:	.incbin "../v10/maincpu/images/BitmapSplitPoint_C.bin"
; entry 14, 58x52: one-octave keyboard picture with the split at Db marked
; == program ROM Bitmap_SplitPoint_Db (v10 0xE5C5DA)
SectionBank14_SplitPoint_Db:	.incbin "../v10/maincpu/images/BitmapSplitPoint_Db.bin"
; entry 15, 58x52: one-octave keyboard picture with the split at D marked
; == program ROM Bitmap_SplitPoint_D (v10 0xE5D1A2)
SectionBank15_SplitPoint_D:	.incbin "../v10/maincpu/images/BitmapSplitPoint_D.bin"
; entry 16, 58x52: one-octave keyboard picture with the split at Eb marked
; == program ROM Bitmap_SplitPoint_Eb (v10 0xE5DD6A)
SectionBank16_SplitPoint_Eb:	.incbin "../v10/maincpu/images/BitmapSplitPoint_Eb.bin"
; entry 17, 58x52: one-octave keyboard picture with the split at E marked
; == program ROM Bitmap_SplitPoint_E (v10 0xE5E932)
SectionBank17_SplitPoint_E:	.incbin "../v10/maincpu/images/BitmapSplitPoint_E.bin"
; entry 18, 58x52: one-octave keyboard picture with the split at F marked
; == program ROM Bitmap_SplitPoint_F (v10 0xE5F4FA)
SectionBank18_SplitPoint_F:	.incbin "../v10/maincpu/images/BitmapSplitPoint_F.bin"
; entry 19, 58x52: one-octave keyboard picture with the split at Gb marked
; == program ROM Bitmap_SplitPoint_Gb (v10 0xE600C2)
SectionBank19_SplitPoint_Gb:	.incbin "../v10/maincpu/images/BitmapSplitPoint_Gb.bin"
; entry 20, 58x52: one-octave keyboard picture with the split at G marked
; == program ROM Bitmap_SplitPoint_G (v10 0xE60C8A)
SectionBank20_SplitPoint_G:	.incbin "../v10/maincpu/images/BitmapSplitPoint_G.bin"
; entry 21, 58x52: one-octave keyboard picture with the split at Ab marked
; == program ROM Bitmap_SplitPoint_Ab (v10 0xE61852)
SectionBank21_SplitPoint_Ab:	.incbin "../v10/maincpu/images/BitmapSplitPoint_Ab.bin"
; entry 22, 58x52: one-octave keyboard picture with the split at A marked
; == program ROM Bitmap_SplitPoint_A (v10 0xE6241A)
SectionBank22_SplitPoint_A:	.incbin "../v10/maincpu/images/BitmapSplitPoint_A.bin"
; entry 23, 58x52: one-octave keyboard picture with the split at Bb marked
; == program ROM Bitmap_SplitPoint_Bb (v10 0xE62FE2)
SectionBank23_SplitPoint_Bb:	.incbin "../v10/maincpu/images/BitmapSplitPoint_Bb.bin"
; entry 24, 58x52: one-octave keyboard picture with the split at B marked
; == program ROM Bitmap_SplitPoint_B (v10 0xE63BAA)
SectionBank24_SplitPoint_B:	.incbin "../v10/maincpu/images/BitmapSplitPoint_B.bin"
; entry 25, 296x108: MIDI connection diagram 1 -- PC, MASTER KEYBOARD and
; EXTERNAL MODULE wired to the KN5000 COMPUTER, MIDI IN and MIDI OUT sockets
; == program ROM Bitmap_MIDIConnections_1 (v10 0xE64772)
SectionBank25_MIDIConnections1:	.incbin "../v10/maincpu/images/BitmapMIDIConnections_1.bin"
; entry 26, 296x108: MIDI connection diagram 2 -- PC, MASTER KEYBOARD and
; EXTERNAL MODULE wired to the KN5000 COMPUTER, MIDI IN and MIDI OUT sockets
; == program ROM Bitmap_MIDIConnections_2 (v10 0xE6C452)
SectionBank26_MIDIConnections2:	.incbin "../v10/maincpu/images/BitmapMIDIConnections_2.bin"
; entry 27, 296x108: MIDI connection diagram 3 -- PC, MASTER KEYBOARD and
; EXTERNAL MODULE wired to the KN5000 COMPUTER, MIDI IN and MIDI OUT sockets
; == program ROM Bitmap_MIDIConnections_3 (v10 0xE74132)
SectionBank27_MIDIConnections3:	.incbin "../v10/maincpu/images/BitmapMIDIConnections_3.bin"

; -----------------------------------------------------------------------------
; Section 7 (0x82CDA2): the "KN-5000" wordmark, a 199 x 36 8bpp bitmap
; -----------------------------------------------------------------------------
; Directory entry 7.  Its accessor SectionInfo_Sec07 (0x82F1B5, below) returns
; base 0x82CDA2, width 199 (0xC7) and height 36 (0x24) -- the (base, w, h)
; shape the accessors give for the other bitmap entries 6 and 28-32.  The
; pixels are 36 rows of 200 bytes (199 pixels + one 0x20 pad byte per row,
; i.e. rows padded to a 16-bit boundary), 7,200 bytes, 0xF7 = transparent,
; palette indices 0x20-0x2E.  The program ROM describes its own copy the
; same way: v10 BitmapKn5000 (0xF7B5A5, ui/drawbar_panel_ui.s) answers
; messages 0x1E000A1/A2/A3 with Bitmap_KN5000_Logo, width 0xC7, height
; 0x24 -- the message-driven twin of this ROM's selector-driven accessor
; (BitmapTechnics, 0xF7B578, does the same for section 6's 312x45).  They are
; byte-identical to v10/maincpu/images/BitmapKN5000Logo.bin -- the program
; ROM carries its own copy at ROM 0xE9367E in v7, v9 and v10 -- so they are
; emitted from that file, the single-sourcing ui_bitmaps.s already uses for
; sections 6 and 28-32.  Earlier revisions emitted these bytes as .byte rows
; described as "bitmap-like line art, section extent 983,646 bytes, head
; only"; 983,646 is merely the address-order distance to the next-higher
; directory target (0x91D000), and the accessor pins the real extent.
; Check: python3 scripts/analysis/tdata_evidence_probes.py  (section 7)
; -----------------------------------------------------------------------------
SectionBank07_KN5000Logo:	.incbin "../v10/maincpu/images/BitmapKN5000Logo.bin"
	.fill	1598, 1, 0xff		; erased flash up to the accessor routines

; =============================================================================
; SECTION ACCESSOR ROUTINES (0x82F000 - 0x82F2E8): 17 leaf routines -- CODE
; =============================================================================
; Emitted as .byte rows of "section 7" until 2026-09-25.  Every routine has
; the same shape:
;     ld xwa, (xsp+8)      selector = the second 32-bit stack argument
;     selector 0 -> XHL = section base (lda of a SectionDirectory_Table target)
;     selector 1 -> XHL = bitmap width in pixels
;     selector 2 -> XHL = bitmap height in rows
;     (written "record size / record count" before 2026-09-25, when entries
;     0-5 and 8-11 were still read as data banks -- they are bitmaps too)
;     otherwise  -> XHL = 0
; one routine per directory entry 0-5, 8-11, 7, 6, 28-32 (that address order);
; entries 12-27 have none.  Why this is code and what it returns:
;   * clean decode by unidasm and by llvm-mc (this listing reassembles to the
;     ROM bytes -- the byte gate); each jr lands on an instruction boundary of
;     its own routine; every routine ends in ret;
;   * each base is exactly a SectionDirectory_Table target, and for entries
;     0-5, 8, 9, 11 width x height equals the directory extent (120 x 95 =
;     11,400 ...); entry 10 reports 113 x 25 = 2,825 against an extent of
;     2,850, i.e. 113-pixel rows stored 114 bytes apart;
;   * for the bitmap entries (w, h) equals the independently known image size:
;     06 312x45, 07 199x36, 28 100x120, 29 16x127, 30 240x127, 31 88x119,
;     32 168x119 (see ui_bitmaps.s and scripts/build/convert_images.py);
;   * the program ROM has message-driven twins of the bitmap accessors that
;     return the same constants for its own copies of the images, e.g. v10
;     BitmapKn5000 (0xF7B5A5): 0x1E000A1 -> Bitmap_KN5000_Logo, 0x1E000A2 ->
;     0xC7, 0x1E000A3 -> 0x24 (ui/drawbar_panel_ui.s).
; Callers: none found.  Each entry address was searched as a 24-bit and as a
; 32-bit little-endian constant in the v7, v9 and v10 program ROMs, the v142
; sub-CPU program, custom data (IC19), the HD-AE5000 ROM and this ROM: no
; hits apart from two 24-bit coincidences, present in v7/v9/v10 alike: at
; v10 0xE1B609 the bytes are the tail of the address 0xE182F0 in a NakaNode
; list, and at v10 0xEF5E6F they are operand bytes of an instruction in
; ParamDigit_ExtractAndFormat.  A computed address (base + 44*k) or a
; caller in a ROM we do not hold is not excluded.
; Check: python3 scripts/analysis/tdata_evidence_probes.py  (accessors)
; =============================================================================

; entry 0, SectionBank00_AccordionGer16: 120 x 95 pixels
SectionInfo_Sec00:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec00_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec00_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec00_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec00_Base:
	lda	xhl, (SectionBank00_AccordionGer16:24)
	ret
SectionInfo_Sec00_Width:
	ld	xhl, 120
	ret
SectionInfo_Sec00_Height:
	ld	xhl, 95
	ret

; entry 1, SectionBank01_AccordionIta16: 120 x 95 pixels
SectionInfo_Sec01:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec01_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec01_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec01_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec01_Base:
	lda	xhl, (SectionBank01_AccordionIta16:24)
	ret
SectionInfo_Sec01_Width:
	ld	xhl, 120
	ret
SectionInfo_Sec01_Height:
	ld	xhl, 95
	ret

; entry 2, SectionBank02_ArrowStrip: 294 x 6 pixels
SectionInfo_Sec02:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec02_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec02_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec02_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec02_Base:
	lda	xhl, (SectionBank02_ArrowStrip:24)
	ret
SectionInfo_Sec02_Width:
	ld	xhl, 294
	ret
SectionInfo_Sec02_Height:
	ld	xhl, 6:i3
	ret

; entry 3, SectionBank03_DrawbarSlider1: 22 x 222 pixels
SectionInfo_Sec03:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec03_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec03_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec03_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec03_Base:
	lda	xhl, (SectionBank03_DrawbarSlider1:24)
	ret
SectionInfo_Sec03_Width:
	ld	xhl, 22
	ret
SectionInfo_Sec03_Height:
	ld	xhl, 222
	ret

; entry 4, SectionBank04_DrawbarSlider2: 22 x 222 pixels
SectionInfo_Sec04:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec04_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec04_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec04_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec04_Base:
	lda	xhl, (SectionBank04_DrawbarSlider2:24)
	ret
SectionInfo_Sec04_Width:
	ld	xhl, 22
	ret
SectionInfo_Sec04_Height:
	ld	xhl, 222
	ret

; entry 5, SectionBank05_DrawbarSlider3: 22 x 222 pixels
SectionInfo_Sec05:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec05_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec05_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec05_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec05_Base:
	lda	xhl, (SectionBank05_DrawbarSlider3:24)
	ret
SectionInfo_Sec05_Width:
	ld	xhl, 22
	ret
SectionInfo_Sec05_Height:
	ld	xhl, 222
	ret

; entry 8, SectionBank08_FadeInPicture: 112 x 25 pixels
SectionInfo_Sec08:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec08_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec08_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec08_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec08_Base:
	lda	xhl, (SectionBank08_FadeInPicture:24)
	ret
SectionInfo_Sec08_Width:
	ld	xhl, 112
	ret
SectionInfo_Sec08_Height:
	ld	xhl, 25
	ret

; entry 9, SectionBank09_FadeInText: 80 x 18 pixels
SectionInfo_Sec09:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec09_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec09_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec09_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec09_Base:
	lda	xhl, (SectionBank09_FadeInText:24)
	ret
SectionInfo_Sec09_Width:
	ld	xhl, 80
	ret
SectionInfo_Sec09_Height:
	ld	xhl, 18
	ret

; entry 10, SectionBank10_FadeOutPicture: 113 x 25 pixels
SectionInfo_Sec10:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec10_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec10_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec10_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec10_Base:
	lda	xhl, (SectionBank10_FadeOutPicture:24)
	ret
SectionInfo_Sec10_Width:
	ld	xhl, 113
	ret
SectionInfo_Sec10_Height:
	ld	xhl, 25
	ret

; entry 11, SectionBank11_FadeOutText: 108 x 20 pixels
SectionInfo_Sec11:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec11_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec11_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec11_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec11_Base:
	lda	xhl, (SectionBank11_FadeOutText:24)
	ret
SectionInfo_Sec11_Width:
	ld	xhl, 108
	ret
SectionInfo_Sec11_Height:
	ld	xhl, 20
	ret

; entry 7, SectionBank07_KN5000Logo: 199 x 36 pixels
SectionInfo_Sec07:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec07_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec07_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec07_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec07_Base:
	lda	xhl, (SectionBank07_KN5000Logo:24)
	ret
SectionInfo_Sec07_Width:
	ld	xhl, 199
	ret
SectionInfo_Sec07_Height:
	ld	xhl, 36
	ret

; entry 6, SectionBank06_TechnicsLogo: 312 x 45 pixels
SectionInfo_Sec06:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec06_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec06_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec06_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec06_Base:
	lda	xhl, (SectionBank06_TechnicsLogo:24)
	ret
SectionInfo_Sec06_Width:
	ld	xhl, 312
	ret
SectionInfo_Sec06_Height:
	ld	xhl, 45
	ret

; entry 28, SectionBank28_KN5000Picture: 100 x 120 pixels
SectionInfo_Sec28:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec28_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec28_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec28_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec28_Base:
	lda	xhl, (SectionBank28_KN5000Picture:24)
	ret
SectionInfo_Sec28_Width:
	ld	xhl, 100
	ret
SectionInfo_Sec28_Height:
	ld	xhl, 120
	ret

; entry 29, SectionBank29_NoteEditKeyboard: 16 x 127 pixels
SectionInfo_Sec29:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec29_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec29_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec29_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec29_Base:
	lda	xhl, (SectionBank29_NoteEditKeyboard:24)
	ret
SectionInfo_Sec29_Width:
	ld	xhl, 16
	ret
SectionInfo_Sec29_Height:
	ld	xhl, 127
	ret

; entry 30, SectionBank30_NoteEditGrid: 240 x 127 pixels
SectionInfo_Sec30:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec30_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec30_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec30_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec30_Base:
	lda	xhl, (SectionBank30_NoteEditGrid:24)
	ret
SectionInfo_Sec30_Width:
	ld	xhl, 240
	ret
SectionInfo_Sec30_Height:
	ld	xhl, 127
	ret

; entry 31, SectionBank31_DrumEditRows: 88 x 119 pixels
SectionInfo_Sec31:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec31_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec31_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec31_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec31_Base:
	lda	xhl, (SectionBank31_DrumEditRows:24)
	ret
SectionInfo_Sec31_Width:
	ld	xhl, 88
	ret
SectionInfo_Sec31_Height:
	ld	xhl, 119
	ret

; entry 32, SectionBank32_DrumEditGrid: 168 x 119 pixels
SectionInfo_Sec32:
	ld	xwa, (xsp+8)
	cp	xwa, 2
	jr	z, SectionInfo_Sec32_Height
	cp	xwa, 1
	jr	z, SectionInfo_Sec32_Width
	or	xwa, xwa
	jr	z, SectionInfo_Sec32_Base
	ld	xhl, 0:i3
	ret
SectionInfo_Sec32_Base:
	lda	xhl, (SectionBank32_DrumEditGrid:24)
	ret
SectionInfo_Sec32_Width:
	ld	xhl, 168
	ret
SectionInfo_Sec32_Height:
	ld	xhl, 119
	ret

	.fill	3351, 1, 0xff		; erased flash up to the tone database at 0x830000
