; =============================================================================
; UI BITMAPS, UI FRAME PIECES, AND FACTORY IMAGE BANKS (0x912C00 - 0x937FFF)
; =============================================================================
; This region was formerly a single opaque blob, includes/wallpaper1_to_icons.bin,
; whose name ("gap between Wallpaper_1 and the icons") hid two live UI drawing
; sources and six factory images.  The build still emits the pixel runs as
; offset/length .incbin slices of that same file, so the blob stays byte-exact
; on disk for the archived ASL mirror (which bincludes it whole).  A better
; name for the file would be ui_bitmaps_and_frames.bin (comment-only proposal;
; renaming would break the ASL mirror build).
;
; LAYOUT:
;   0x912C00  Wallpaper_1 trailer: zeros + five 16-entry shade-ramp tables
;   0x913000  BitmapDescriptorTable   34 x {w16,h16,ptr32} + null terminator
;   0x913118  bitmap pixel runs       8bpp, rows padded to 16-bit alignment
;   0x91CE1A  0xFF fill (486 bytes)
;   0x91D000  section banks 6, 28-32  factory UI images (see below)
;   0x934000  FrameDescriptorTable    53 x {w16,h16,ptr32} + null terminator
;   0x9341B0  frame pixel runs        8bpp, rows padded to 16-bit alignment
;   0x9373F4  0xFF fill (3084 bytes)
;
; PIXEL FORMAT (both descriptor tables):
;   8bpp indexed, 2 pixels per 16-bit word; odd-width images carry one pad
;   byte per row (DrawFrameSP_Impl_OddWidthPad advances the source pointer,
;   and DrawBitmap_Impl reads `ld wa, (xix)` a word at a time).
;   Color 0xf7 = transparent (skipped).  In frame pieces color 0xf6 is a
;   template color replaced at draw time by the color argument, which is how
;   one green master shape serves every button state.
;
; CONSUMERS (Main CPU ROM v7/v9/v10, ui/drawing_primitives.s):
;   DrawBitmap / DrawBitmapFast  index * 8 into 0x913000 (BitmapDescriptorTable)
;   DrawFrameSP                  index * 8 into 0x934000 (FrameDescriptorTable)
; v10 addresses (2026-09-25): DrawBitmap_Impl 0xFABC98 (add xhl,0x913000),
; DrawBitmapFast_Impl 0xFABE6F (add xiz,0x913000), DrawFrameSP_Impl 0xFAC0E7
; (add xbc,0x934000); GetFrameSPSize (0xFB25F3, display/graphics_text_vga.s)
; also reads a frame piece's {w,h} at 0x934000 + 8*index.
; The maincpu code still uses the numeric addresses (`add xhl, 0x913000` /
; `add xbc, 0x934000`); those sites should eventually reference these labels.
; =============================================================================

; -----------------------------------------------------------------------------
; Wallpaper_1 trailer (0x912C00): shade-ramp tables
; -----------------------------------------------------------------------------
; Each 320x240 wallpaper is followed by a 1 KB trailer whose +0x380 slot holds
; a 16-entry ramp of {r, g, b, 0x00} quadruplets, ascending in brightness --
; the shade lookup for that wallpaper's texture.  Wallpaper_0's trailer (the
; former includes/wallpaper_gap.bin, see Wallpaper0_ShadeRamp) carries the
; navy ramp; Wallpaper_1's carries the blue one.  This trailer additionally
; holds a bank of four candidate ramps at +0x80.  No code reference to these
; tables has been found yet, so the RGB interpretation is tentative (the
; values behave like one: monotonically brightening triplets).
; CORRECTED 2026-09-25 -- the two sentences above are superseded.  The whole
; trailer is a 256-entry x 4-byte palette: v10's wallpaper table at 0xEAAE62
; has record 1 = {Wallpaper_1, 0x912C00, 0}, and ChangePalette_Impl
; (0xFAF2F3), called with index 1 by AcWelcomScreenProc (0xF7F4A6), copies
; entries 0x20-0xDF of it (trailer +0x80..+0x37F) into the RAM palette at
; 0x324FC through SetPaletteRGB (0xFB2895).  VGA_WritePaletteEntry (0xFB31AB)
; sends bytes +0, +1, +2 of each entry to DAC port 0x3C9 in that order, so an
; entry is {red, green, blue, 0}.  The four ramps below are therefore palette
; entries 0x20-0x2F, 0x30-0x3F, 0x40-0x4F and 0x50-0x5F; the +0x380 ramp is
; entries 0xE0-0xEF, the only values Wallpaper_1's pixels use.  The loader of
; entries 0xE0-0xEF (ChangeWallPalette_Impl, via the RAM table at 0x3F1E4)
; was not traced back to this slot.
	.zero 128

; palette entries 0x20-0x2F (trailer +0x80), loaded by ChangePalette_Impl
; (0xFAF2F3) for wallpaper record 1
WallpaperRamp_Beige:	; ends at pure white
	.byte 0xb5, 0x94, 0x18, 0x00
	.byte 0xb5, 0x94, 0x29, 0x00
	.byte 0xc6, 0xa5, 0x29, 0x00
	.byte 0xc6, 0xa5, 0x35, 0x00
	.byte 0xc5, 0xa7, 0x3c, 0x00
	.byte 0xd0, 0xb2, 0x47, 0x00
	.byte 0xce, 0xaf, 0x57, 0x00
	.byte 0xd3, 0xb7, 0x60, 0x00
	.byte 0xd6, 0xb5, 0x73, 0x00
	.byte 0xe2, 0xc1, 0x73, 0x00
	.byte 0xd6, 0xbd, 0x84, 0x00
	.byte 0xe7, 0xc6, 0x84, 0x00
	.byte 0xe7, 0xce, 0x8c, 0x00
	.byte 0xef, 0xce, 0x8c, 0x00
	.byte 0xe7, 0xd6, 0x94, 0x00
	.byte 0xff, 0xff, 0xff, 0x00
; palette entries 0x30-0x3F (trailer +0xC0), loaded by ChangePalette_Impl
; (0xFAF2F3) for wallpaper record 1
WallpaperRamp_Brown:
	.byte 0x0d, 0x0d, 0x0d, 0x00
	.byte 0x3d, 0x20, 0x0d, 0x00
	.byte 0x3d, 0x20, 0x0d, 0x00
	.byte 0x45, 0x27, 0x0d, 0x00
	.byte 0x4d, 0x2f, 0x0d, 0x00
	.byte 0x4d, 0x2f, 0x0d, 0x00
	.byte 0x4d, 0x2f, 0x0d, 0x00
	.byte 0x50, 0x36, 0x0d, 0x00
	.byte 0x54, 0x36, 0x0d, 0x00
	.byte 0x56, 0x3c, 0x0d, 0x00
	.byte 0x54, 0x36, 0x0d, 0x00
	.byte 0x59, 0x3f, 0x0d, 0x00
	.byte 0x63, 0x46, 0x0d, 0x00
	.byte 0x6b, 0x54, 0x18, 0x00
	.byte 0x72, 0x54, 0x18, 0x00
	.byte 0x6b, 0x5b, 0x20, 0x00
; palette entries 0x40-0x4F (trailer +0x100), loaded by ChangePalette_Impl
; (0xFAF2F3) for wallpaper record 1
WallpaperRamp_Blue:
	.byte 0x0d, 0x20, 0x2b, 0x00
	.byte 0x0f, 0x28, 0x3d, 0x00
	.byte 0x0d, 0x2e, 0x45, 0x00
	.byte 0x1b, 0x32, 0x3d, 0x00
	.byte 0x13, 0x34, 0x45, 0x00
	.byte 0x16, 0x30, 0x4b, 0x00
	.byte 0x1c, 0x34, 0x51, 0x00
	.byte 0x23, 0x3d, 0x4b, 0x00
	.byte 0x1d, 0x3c, 0x5a, 0x00
	.byte 0x28, 0x3f, 0x58, 0x00
	.byte 0x28, 0x49, 0x5b, 0x00
	.byte 0x29, 0x47, 0x63, 0x00
	.byte 0x24, 0x4d, 0x66, 0x00
	.byte 0x30, 0x51, 0x62, 0x00
	.byte 0x33, 0x51, 0x6a, 0x00
	.byte 0x40, 0x64, 0x7a, 0x00
; palette entries 0x50-0x5F (trailer +0x140), loaded by ChangePalette_Impl
; (0xFAF2F3) for wallpaper record 1
WallpaperRamp_Navy:	; same values as Wallpaper0_ShadeRamp
	.byte 0x1f, 0x1f, 0x28, 0x00
	.byte 0x1f, 0x1f, 0x2d, 0x00
	.byte 0x1f, 0x24, 0x2d, 0x00
	.byte 0x1f, 0x1f, 0x33, 0x00
	.byte 0x1f, 0x24, 0x33, 0x00
	.byte 0x1f, 0x24, 0x38, 0x00
	.byte 0x1f, 0x27, 0x38, 0x00
	.byte 0x1f, 0x2c, 0x38, 0x00
	.byte 0x1f, 0x27, 0x3d, 0x00
	.byte 0x1f, 0x2c, 0x3d, 0x00
	.byte 0x24, 0x27, 0x38, 0x00
	.byte 0x24, 0x2c, 0x38, 0x00
	.byte 0x24, 0x2c, 0x3d, 0x00
	.byte 0x24, 0x2c, 0x43, 0x00
	.byte 0x27, 0x2e, 0x41, 0x00
	.byte 0x2b, 0x33, 0x46, 0x00
	.zero 512
; palette entries 0xE0-0xEF (trailer +0x380): the 16 values Wallpaper_1's
; pixels use.  Not in ChangePalette_Impl's 0x20-0xDF range.
Wallpaper1_ShadeRamp:	; active ramp slot (+0x380); same values as WallpaperRamp_Blue
	.byte 0x0d, 0x20, 0x2b, 0x00
	.byte 0x0f, 0x28, 0x3d, 0x00
	.byte 0x0d, 0x2e, 0x45, 0x00
	.byte 0x1b, 0x32, 0x3d, 0x00
	.byte 0x13, 0x34, 0x45, 0x00
	.byte 0x16, 0x30, 0x4b, 0x00
	.byte 0x1c, 0x34, 0x51, 0x00
	.byte 0x23, 0x3d, 0x4b, 0x00
	.byte 0x1d, 0x3c, 0x5a, 0x00
	.byte 0x28, 0x3f, 0x58, 0x00
	.byte 0x28, 0x49, 0x5b, 0x00
	.byte 0x29, 0x47, 0x63, 0x00
	.byte 0x24, 0x4d, 0x66, 0x00
	.byte 0x30, 0x51, 0x62, 0x00
	.byte 0x33, 0x51, 0x6a, 0x00
	.byte 0x40, 0x64, 0x7a, 0x00
	.zero 64

; -----------------------------------------------------------------------------
; BitmapDescriptorTable (0x913000): 34 entries + null terminator
; -----------------------------------------------------------------------------
; Indexed by the bitmap number passed to DrawBitmap/DrawBitmapFast.
BitmapDescriptorTable:
	desc_entry	24, 24, Bitmap_WormWearingHat	; 0
	desc_entry	307, 45, Bitmap_TechnicsLogoOutline	; 1
	desc_entry	27, 48, Bitmap_VerticalFader	; 2
	desc_entry	19, 12, Bitmap_RedBarGauge	; 3
	desc_entry	17, 17, Bitmap_RecordDot	; 4
	desc_entry	3, 3, Bitmap_TinyCross	; 5
	desc_entry	27, 18, Bitmap_TransportFastForward	; 6
	desc_entry	27, 18, Bitmap_TransportRewind	; 7
	desc_entry	27, 18, Bitmap_TransportPause	; 8
	desc_entry	27, 18, Bitmap_TransportPlayStop	; 9
	desc_entry	27, 18, Bitmap_TransportSkipToStart	; 10
	desc_entry	27, 18, Bitmap_TransportSkipToEnd	; 11
	desc_entry	32, 32, Bitmap_SoundIcon_Violin	; 12
	desc_entry	32, 32, Bitmap_SoundIcon_Trumpet	; 13
	desc_entry	32, 32, Bitmap_SoundIcon_DrumKit	; 14
	desc_entry	32, 32, Bitmap_SoundIcon_Flutes	; 15
	desc_entry	32, 32, Bitmap_SoundIcon_ElectricGuitar	; 16
	desc_entry	32, 32, Bitmap_SoundIcon_NoteInCloud	; 17
	desc_entry	32, 32, Bitmap_SoundIcon_MalletPercussion	; 18
	desc_entry	32, 32, Bitmap_PageIconA	; 19
	desc_entry	32, 32, Bitmap_PageIconB	; 20
	desc_entry	32, 32, Bitmap_SoundIcon_MixerModule	; 21
	desc_entry	32, 32, Bitmap_SoundIcon_FiddleAndBanjo	; 22
	desc_entry	32, 32, Bitmap_SoundIcon_GrandPiano	; 23
	desc_entry	32, 32, Bitmap_SoundIcon_SaxAndClarinet	; 24
	desc_entry	32, 32, Bitmap_SoundIcon_FiddleAndMandolin	; 25
	desc_entry	32, 32, Bitmap_SoundIcon_SynthKeyboard	; 26
	desc_entry	32, 32, Bitmap_SoundIcon_Drawbars	; 27
	desc_entry	32, 32, Bitmap_SoundIcon_Accordion	; 28
	desc_entry	15, 11, Bitmap_GreenLedButtonBright	; 29
	desc_entry	15, 11, Bitmap_GreenLedButtonDim	; 30
	desc_entry	32, 32, Bitmap_GeneralMidiSpecialLogo	; 31
	desc_entry	32, 32, Bitmap_SoundIcon_Metronome	; 32
	desc_entry	32, 32, Bitmap_SoundIcon_Microphone	; 33
	desc_entry	0, 0, 0		; terminator

; Bitmap pixel runs (0x913118): 8bpp slices of the on-disk blob.
; Entry 0 is byte-identical to v10/maincpu/images/BitmapWormWearingHat.bin
; (the maincpu ROM carries its own copy at 0xea9f20).
Bitmap_WormWearingHat:			.incbin "includes/generated/Bitmap_WormWearingHat.bin"	; 24x24 -- green worm in a straw hat (easter egg; same bytes as maincpu 0xea9f20 copy)
Bitmap_TechnicsLogoOutline:		.incbin "includes/generated/Bitmap_TechnicsLogoOutline.bin"	; 307x45 -- olive "Technics" wordmark with white outline on transparent background
Bitmap_VerticalFader:			.incbin "includes/generated/Bitmap_VerticalFader.bin"	; 27x48 -- on-screen fader: dark slot, black cap, tick scale on the right
Bitmap_RedBarGauge:			.incbin "includes/generated/Bitmap_RedBarGauge.bin"	; 19x12 -- small bevelled panel with a red level bar (exact use not yet traced)
Bitmap_RecordDot:			.incbin "includes/generated/Bitmap_RecordDot.bin"	; 17x17 -- dark-red filled circle (transport record symbol)
Bitmap_TinyCross:			.incbin "includes/generated/Bitmap_TinyCross.bin"	; 3x3 -- white 3x3 plus/cross marker
Bitmap_TransportFastForward:		.incbin "includes/generated/Bitmap_TransportFastForward.bin"	; 27x18
Bitmap_TransportRewind:			.incbin "includes/generated/Bitmap_TransportRewind.bin"	; 27x18
Bitmap_TransportPause:			.incbin "includes/generated/Bitmap_TransportPause.bin"	; 27x18
Bitmap_TransportPlayStop:		.incbin "includes/generated/Bitmap_TransportPlayStop.bin"	; 27x18
Bitmap_TransportSkipToStart:		.incbin "includes/generated/Bitmap_TransportSkipToStart.bin"	; 27x18
Bitmap_TransportSkipToEnd:		.incbin "includes/generated/Bitmap_TransportSkipToEnd.bin"	; 27x18
Bitmap_SoundIcon_Violin:		.incbin "includes/generated/Bitmap_SoundIcon_Violin.bin"	; 32x32 -- violin and bow
Bitmap_SoundIcon_Trumpet:		.incbin "includes/generated/Bitmap_SoundIcon_Trumpet.bin"	; 32x32
Bitmap_SoundIcon_DrumKit:		.incbin "includes/generated/Bitmap_SoundIcon_DrumKit.bin"	; 32x32
Bitmap_SoundIcon_Flutes:		.incbin "includes/generated/Bitmap_SoundIcon_Flutes.bin"	; 32x32 -- concert flute over pan flute
Bitmap_SoundIcon_ElectricGuitar:	.incbin "includes/generated/Bitmap_SoundIcon_ElectricGuitar.bin"	; 32x32
Bitmap_SoundIcon_NoteInCloud:		.incbin "includes/generated/Bitmap_SoundIcon_NoteInCloud.bin"	; 32x32 -- eighth note inside a sparkling cloud (pad/atmosphere sounds)
Bitmap_SoundIcon_MalletPercussion:	.incbin "includes/generated/Bitmap_SoundIcon_MalletPercussion.bin"	; 32x32 -- tubular chimes and timpani with mallets
Bitmap_PageIconA:			.incbin "includes/generated/Bitmap_PageIconA.bin"	; 32x32 -- dog-eared page labelled "A"
Bitmap_PageIconB:			.incbin "includes/generated/Bitmap_PageIconB.bin"	; 32x32 -- dog-eared page labelled "B"
Bitmap_SoundIcon_MixerModule:		.incbin "includes/generated/Bitmap_SoundIcon_MixerModule.bin"	; 32x32 -- rack sound module above mixer faders
Bitmap_SoundIcon_FiddleAndBanjo:	.incbin "includes/generated/Bitmap_SoundIcon_FiddleAndBanjo.bin"	; 32x32 -- crossed fiddle/bow with banjo head
Bitmap_SoundIcon_GrandPiano:		.incbin "includes/generated/Bitmap_SoundIcon_GrandPiano.bin"	; 32x32
Bitmap_SoundIcon_SaxAndClarinet:	.incbin "includes/generated/Bitmap_SoundIcon_SaxAndClarinet.bin"	; 32x32
Bitmap_SoundIcon_FiddleAndMandolin:	.incbin "includes/generated/Bitmap_SoundIcon_FiddleAndMandolin.bin"	; 32x32 -- crossed fiddle/bow with oval mandolin body
Bitmap_SoundIcon_SynthKeyboard:		.incbin "includes/generated/Bitmap_SoundIcon_SynthKeyboard.bin"	; 32x32 -- digital workstation keyboard
Bitmap_SoundIcon_Drawbars:		.incbin "includes/generated/Bitmap_SoundIcon_Drawbars.bin"	; 32x32 -- three numbered organ drawbars pulled to different lengths
Bitmap_SoundIcon_Accordion:		.incbin "includes/generated/Bitmap_SoundIcon_Accordion.bin"	; 32x32
Bitmap_GreenLedButtonBright:		.incbin "includes/generated/Bitmap_GreenLedButtonBright.bin"	; 15x11 -- small green LED button, lit
Bitmap_GreenLedButtonDim:		.incbin "includes/generated/Bitmap_GreenLedButtonDim.bin"	; 15x11 -- small green LED button, dimmed
Bitmap_GeneralMidiSpecialLogo:		.incbin "includes/generated/Bitmap_GeneralMidiSpecialLogo.bin"	; 32x32 -- "GENERAL MIDI SPECIAL" text logo
Bitmap_SoundIcon_Metronome:		.incbin "includes/generated/Bitmap_SoundIcon_Metronome.bin"	; 32x32
Bitmap_SoundIcon_Microphone:		.incbin "includes/generated/Bitmap_SoundIcon_Microphone.bin"	; 32x32

	.fill 486, 1, 0xff

; -----------------------------------------------------------------------------
; Section banks 6 and 28-32 (0x91D000 - 0x933FFF): factory UI images
; -----------------------------------------------------------------------------
; These six blocks are indexed by SectionDirectory_Table entries 6 and 28-32
; (floppy save/load banks), but their factory content is a set of full UI
; [CORRECTED 2026-09-25: nothing supported "floppy save/load banks"; every
; directory entry is a bitmap, and a search of all our ROMs for the
; directory's target addresses finds only the table-data accessor routines
; (preset_banks.s), which also give these six images' width and height]
; images, each byte-identical to an extraction already checked in under
; v10/maincpu/images/ -- so they are emitted from those files here (same
; single-sourcing as the Bitmap_1bit_* boot screens below).  The maincpu
; program ROM carries its own copy of each (addresses noted per image); the
; extracted .png versions are in the documentation gallery.
; Original Matsushita asset names (bmphk, ntedt0k, ntedt0d, dredt0k, dredt0d)
; survive in maincpu routine/widget names (e.g. BitmapBmphk dimension helper,
; NakaInst_BitmapBmphk widget descriptor).
; 312x45; black wordmark, 0xf7 transparent; maincpu copy at 0xe8ffa6
SectionBank06_TechnicsLogo:		.incbin "../v10/maincpu/images/BitmapTechnicsLogo.bin"
; 100x120; the KN5000 itself on teal ("bmphk"); maincpu copy at 0xe7be12
SectionBank28_KN5000Picture:		.incbin "../v10/maincpu/images/BitmapBmphk.bin"
; 16x127; vertical piano ruler for the note-edit screen ("ntedt0k"); maincpu copy at 0xe34e78
SectionBank29_NoteEditKeyboard:		.incbin "../v10/maincpu/images/BitmapNtedt0k.bin"
; 240x127; dotted note-edit grid ("ntedt0d"); maincpu copy at 0xe35668
SectionBank30_NoteEditGrid:		.incbin "../v10/maincpu/images/BitmapNtedt0d.bin"
; 88x119; ruled instrument rows for the drum-edit screen ("dredt0k"); maincpu copy at 0xe3cd78
SectionBank31_DrumEditRows:		.incbin "../v10/maincpu/images/BitmapDredt0k.bin"
; 168x119; drum-edit grid ("dredt0d"); maincpu copy at 0xe3f660
SectionBank32_DrumEditGrid:		.incbin "../v10/maincpu/images/BitmapDredt0d.bin"
	.fill 5192, 1, 0xff	; tail of section bank 32

; -----------------------------------------------------------------------------
; FrameDescriptorTable (0x934000): 53 entries + null terminator
; -----------------------------------------------------------------------------
; Indexed by the frame-piece number passed to DrawFrameSP (which also takes
; the runtime color that replaces template color 0xf6).  The set is a UI
; frame construction kit:
;   0-19   rounded-rectangle corner pieces, sizes 1/2/5/9/14, in TL,TR,BR,BL
;          order (size-1 pieces degenerate to a single black pixel)
;   20-29  chevron arrowheads pointing right/left, five sizes each
;   30-37  "ON/OFF" soft-button bodies with a pointed tab on the left/right
;          side (they point at the physical buttons beside the LCD)
;   38-39  solid red arrows, left/right
;   40-51  5x5 anti-aliased bevel corner overlays, three shading styles
;          (raised highlight / outlined / sunken shadow) in TL,TR,BR,BL order
;   52     wide rounded tab-bar body
FrameDescriptorTable:
	desc_entry	1, 1, Frame_RoundCorner1_TL	; 0
	desc_entry	1, 1, Frame_RoundCorner1_TR	; 1
	desc_entry	1, 1, Frame_RoundCorner1_BR	; 2
	desc_entry	1, 1, Frame_RoundCorner1_BL	; 3
	desc_entry	2, 2, Frame_RoundCorner2_TL	; 4
	desc_entry	2, 2, Frame_RoundCorner2_TR	; 5
	desc_entry	2, 2, Frame_RoundCorner2_BR	; 6
	desc_entry	2, 2, Frame_RoundCorner2_BL	; 7
	desc_entry	5, 5, Frame_RoundCorner5_TL	; 8
	desc_entry	5, 5, Frame_RoundCorner5_TR	; 9
	desc_entry	5, 5, Frame_RoundCorner5_BR	; 10
	desc_entry	5, 5, Frame_RoundCorner5_BL	; 11
	desc_entry	9, 9, Frame_RoundCorner9_TL	; 12
	desc_entry	9, 9, Frame_RoundCorner9_TR	; 13
	desc_entry	9, 9, Frame_RoundCorner9_BR	; 14
	desc_entry	9, 9, Frame_RoundCorner9_BL	; 15
	desc_entry	14, 14, Frame_RoundCorner14_TL	; 16
	desc_entry	14, 14, Frame_RoundCorner14_TR	; 17
	desc_entry	14, 14, Frame_RoundCorner14_BR	; 18
	desc_entry	14, 14, Frame_RoundCorner14_BL	; 19
	desc_entry	5, 12, Frame_ChevronRight_5x12	; 20
	desc_entry	6, 16, Frame_ChevronRight_6x16	; 21
	desc_entry	8, 24, Frame_ChevronRight_8x24	; 22
	desc_entry	10, 32, Frame_ChevronRight_10x32	; 23
	desc_entry	15, 48, Frame_ChevronRight_15x48	; 24
	desc_entry	5, 12, Frame_ChevronLeft_5x12	; 25
	desc_entry	6, 16, Frame_ChevronLeft_6x16	; 26
	desc_entry	8, 24, Frame_ChevronLeft_8x24	; 27
	desc_entry	10, 32, Frame_ChevronLeft_10x32	; 28
	desc_entry	15, 48, Frame_ChevronLeft_15x48	; 29
	desc_entry	20, 16, Frame_OnOffTabLeft_20x16	; 30
	desc_entry	24, 24, Frame_OnOffTabLeft_24x24	; 31
	desc_entry	29, 32, Frame_OnOffTabLeft_29x32	; 32
	desc_entry	34, 48, Frame_OnOffTabLeft_34x48	; 33
	desc_entry	20, 16, Frame_OnOffTabRight_20x16	; 34
	desc_entry	24, 24, Frame_OnOffTabRight_24x24	; 35
	desc_entry	29, 32, Frame_OnOffTabRight_29x32	; 36
	desc_entry	34, 48, Frame_OnOffTabRight_34x48	; 37
	desc_entry	16, 16, Frame_RedArrowLeft	; 38
	desc_entry	16, 16, Frame_RedArrowRight	; 39
	desc_entry	5, 5, Frame_BevelCornerRaised_TL	; 40
	desc_entry	5, 5, Frame_BevelCornerRaised_TR	; 41
	desc_entry	5, 5, Frame_BevelCornerRaised_BR	; 42
	desc_entry	5, 5, Frame_BevelCornerRaised_BL	; 43
	desc_entry	5, 5, Frame_BevelCornerOutlined_TL	; 44
	desc_entry	5, 5, Frame_BevelCornerOutlined_TR	; 45
	desc_entry	5, 5, Frame_BevelCornerOutlined_BR	; 46
	desc_entry	5, 5, Frame_BevelCornerOutlined_BL	; 47
	desc_entry	5, 5, Frame_BevelCornerSunken_TL	; 48
	desc_entry	5, 5, Frame_BevelCornerSunken_TR	; 49
	desc_entry	5, 5, Frame_BevelCornerSunken_BR	; 50
	desc_entry	5, 5, Frame_BevelCornerSunken_BL	; 51
	desc_entry	76, 11, Frame_WideTabBar	; 52
	desc_entry	0, 0, 0		; terminator

; Frame pixel runs (0x9341B0)
Frame_RoundCorner1_TL:			.incbin "includes/generated/Frame_RoundCorner1_TL.bin"	; 1x1
Frame_RoundCorner1_TR:			.incbin "includes/generated/Frame_RoundCorner1_TR.bin"	; 1x1
Frame_RoundCorner1_BR:			.incbin "includes/generated/Frame_RoundCorner1_BR.bin"	; 1x1
Frame_RoundCorner1_BL:			.incbin "includes/generated/Frame_RoundCorner1_BL.bin"	; 1x1
Frame_RoundCorner2_TL:			.incbin "includes/generated/Frame_RoundCorner2_TL.bin"	; 2x2
Frame_RoundCorner2_TR:			.incbin "includes/generated/Frame_RoundCorner2_TR.bin"	; 2x2
Frame_RoundCorner2_BR:			.incbin "includes/generated/Frame_RoundCorner2_BR.bin"	; 2x2
Frame_RoundCorner2_BL:			.incbin "includes/generated/Frame_RoundCorner2_BL.bin"	; 2x2
Frame_RoundCorner5_TL:			.incbin "includes/generated/Frame_RoundCorner5_TL.bin"	; 5x5
Frame_RoundCorner5_TR:			.incbin "includes/generated/Frame_RoundCorner5_TR.bin"	; 5x5
Frame_RoundCorner5_BR:			.incbin "includes/generated/Frame_RoundCorner5_BR.bin"	; 5x5
Frame_RoundCorner5_BL:			.incbin "includes/generated/Frame_RoundCorner5_BL.bin"	; 5x5
Frame_RoundCorner9_TL:			.incbin "includes/generated/Frame_RoundCorner9_TL.bin"	; 9x9
Frame_RoundCorner9_TR:			.incbin "includes/generated/Frame_RoundCorner9_TR.bin"	; 9x9
Frame_RoundCorner9_BR:			.incbin "includes/generated/Frame_RoundCorner9_BR.bin"	; 9x9
Frame_RoundCorner9_BL:			.incbin "includes/generated/Frame_RoundCorner9_BL.bin"	; 9x9
Frame_RoundCorner14_TL:			.incbin "includes/generated/Frame_RoundCorner14_TL.bin"	; 14x14
Frame_RoundCorner14_TR:			.incbin "includes/generated/Frame_RoundCorner14_TR.bin"	; 14x14
Frame_RoundCorner14_BR:			.incbin "includes/generated/Frame_RoundCorner14_BR.bin"	; 14x14
Frame_RoundCorner14_BL:			.incbin "includes/generated/Frame_RoundCorner14_BL.bin"	; 14x14
Frame_ChevronRight_5x12:		.incbin "includes/generated/Frame_ChevronRight_5x12.bin"	; 5x12
Frame_ChevronRight_6x16:		.incbin "includes/generated/Frame_ChevronRight_6x16.bin"	; 6x16
Frame_ChevronRight_8x24:		.incbin "includes/generated/Frame_ChevronRight_8x24.bin"	; 8x24
Frame_ChevronRight_10x32:		.incbin "includes/generated/Frame_ChevronRight_10x32.bin"	; 10x32
Frame_ChevronRight_15x48:		.incbin "includes/generated/Frame_ChevronRight_15x48.bin"	; 15x48
Frame_ChevronLeft_5x12:			.incbin "includes/generated/Frame_ChevronLeft_5x12.bin"	; 5x12
Frame_ChevronLeft_6x16:			.incbin "includes/generated/Frame_ChevronLeft_6x16.bin"	; 6x16
Frame_ChevronLeft_8x24:			.incbin "includes/generated/Frame_ChevronLeft_8x24.bin"	; 8x24
Frame_ChevronLeft_10x32:		.incbin "includes/generated/Frame_ChevronLeft_10x32.bin"	; 10x32
Frame_ChevronLeft_15x48:		.incbin "includes/generated/Frame_ChevronLeft_15x48.bin"	; 15x48
Frame_OnOffTabLeft_20x16:		.incbin "includes/generated/Frame_OnOffTabLeft_20x16.bin"	; 20x16
Frame_OnOffTabLeft_24x24:		.incbin "includes/generated/Frame_OnOffTabLeft_24x24.bin"	; 24x24
Frame_OnOffTabLeft_29x32:		.incbin "includes/generated/Frame_OnOffTabLeft_29x32.bin"	; 29x32
Frame_OnOffTabLeft_34x48:		.incbin "includes/generated/Frame_OnOffTabLeft_34x48.bin"	; 34x48
Frame_OnOffTabRight_20x16:		.incbin "includes/generated/Frame_OnOffTabRight_20x16.bin"	; 20x16
Frame_OnOffTabRight_24x24:		.incbin "includes/generated/Frame_OnOffTabRight_24x24.bin"	; 24x24
Frame_OnOffTabRight_29x32:		.incbin "includes/generated/Frame_OnOffTabRight_29x32.bin"	; 29x32
Frame_OnOffTabRight_34x48:		.incbin "includes/generated/Frame_OnOffTabRight_34x48.bin"	; 34x48
Frame_RedArrowLeft:			.incbin "includes/generated/Frame_RedArrowLeft.bin"	; 16x16
Frame_RedArrowRight:			.incbin "includes/generated/Frame_RedArrowRight.bin"	; 16x16
Frame_BevelCornerRaised_TL:		.incbin "includes/generated/Frame_BevelCornerRaised_TL.bin"	; 5x5
Frame_BevelCornerRaised_TR:		.incbin "includes/generated/Frame_BevelCornerRaised_TR.bin"	; 5x5
Frame_BevelCornerRaised_BR:		.incbin "includes/generated/Frame_BevelCornerRaised_BR.bin"	; 5x5
Frame_BevelCornerRaised_BL:		.incbin "includes/generated/Frame_BevelCornerRaised_BL.bin"	; 5x5
Frame_BevelCornerOutlined_TL:		.incbin "includes/generated/Frame_BevelCornerOutlined_TL.bin"	; 5x5
Frame_BevelCornerOutlined_TR:		.incbin "includes/generated/Frame_BevelCornerOutlined_TR.bin"	; 5x5
Frame_BevelCornerOutlined_BR:		.incbin "includes/generated/Frame_BevelCornerOutlined_BR.bin"	; 5x5
Frame_BevelCornerOutlined_BL:		.incbin "includes/generated/Frame_BevelCornerOutlined_BL.bin"	; 5x5
Frame_BevelCornerSunken_TL:		.incbin "includes/generated/Frame_BevelCornerSunken_TL.bin"	; 5x5
Frame_BevelCornerSunken_TR:		.incbin "includes/generated/Frame_BevelCornerSunken_TR.bin"	; 5x5
Frame_BevelCornerSunken_BR:		.incbin "includes/generated/Frame_BevelCornerSunken_BR.bin"	; 5x5
Frame_BevelCornerSunken_BL:		.incbin "includes/generated/Frame_BevelCornerSunken_BL.bin"	; 5x5
Frame_WideTabBar:			.incbin "includes/generated/Frame_WideTabBar.bin"	; 76x11

	.fill 3084, 1, 0xff
