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
	.zero 128

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
Bitmap_WormWearingHat:			.incbin "includes/wallpaper1_to_icons.bin", 0x518, 576	; 24x24 -- green worm in a straw hat (easter egg; same bytes as maincpu 0xea9f20 copy)
Bitmap_TechnicsLogoOutline:		.incbin "includes/wallpaper1_to_icons.bin", 0x758, 13860	; 307x45 -- olive "Technics" wordmark with white outline on transparent background
Bitmap_VerticalFader:			.incbin "includes/wallpaper1_to_icons.bin", 0x3d7c, 1344	; 27x48 -- on-screen fader: dark slot, black cap, tick scale on the right
Bitmap_RedBarGauge:			.incbin "includes/wallpaper1_to_icons.bin", 0x42bc, 240	; 19x12 -- small bevelled panel with a red level bar (exact use not yet traced)
Bitmap_RecordDot:			.incbin "includes/wallpaper1_to_icons.bin", 0x43ac, 306	; 17x17 -- dark-red filled circle (transport record symbol)
Bitmap_TinyCross:			.incbin "includes/wallpaper1_to_icons.bin", 0x44de, 12	; 3x3 -- white 3x3 plus/cross marker
Bitmap_TransportFastForward:		.incbin "includes/wallpaper1_to_icons.bin", 0x44ea, 504	; 27x18
Bitmap_TransportRewind:			.incbin "includes/wallpaper1_to_icons.bin", 0x46e2, 504	; 27x18
Bitmap_TransportPause:			.incbin "includes/wallpaper1_to_icons.bin", 0x48da, 504	; 27x18
Bitmap_TransportPlayStop:		.incbin "includes/wallpaper1_to_icons.bin", 0x4ad2, 504	; 27x18
Bitmap_TransportSkipToStart:		.incbin "includes/wallpaper1_to_icons.bin", 0x4cca, 504	; 27x18
Bitmap_TransportSkipToEnd:		.incbin "includes/wallpaper1_to_icons.bin", 0x4ec2, 504	; 27x18
Bitmap_SoundIcon_Violin:		.incbin "includes/wallpaper1_to_icons.bin", 0x50ba, 1024	; 32x32 -- violin and bow
Bitmap_SoundIcon_Trumpet:		.incbin "includes/wallpaper1_to_icons.bin", 0x54ba, 1024	; 32x32
Bitmap_SoundIcon_DrumKit:		.incbin "includes/wallpaper1_to_icons.bin", 0x58ba, 1024	; 32x32
Bitmap_SoundIcon_Flutes:		.incbin "includes/wallpaper1_to_icons.bin", 0x5cba, 1024	; 32x32 -- concert flute over pan flute
Bitmap_SoundIcon_ElectricGuitar:	.incbin "includes/wallpaper1_to_icons.bin", 0x60ba, 1024	; 32x32
Bitmap_SoundIcon_NoteInCloud:		.incbin "includes/wallpaper1_to_icons.bin", 0x64ba, 1024	; 32x32 -- eighth note inside a sparkling cloud (pad/atmosphere sounds)
Bitmap_SoundIcon_MalletPercussion:	.incbin "includes/wallpaper1_to_icons.bin", 0x68ba, 1024	; 32x32 -- tubular chimes and timpani with mallets
Bitmap_PageIconA:			.incbin "includes/wallpaper1_to_icons.bin", 0x6cba, 1024	; 32x32 -- dog-eared page labelled "A"
Bitmap_PageIconB:			.incbin "includes/wallpaper1_to_icons.bin", 0x70ba, 1024	; 32x32 -- dog-eared page labelled "B"
Bitmap_SoundIcon_MixerModule:		.incbin "includes/wallpaper1_to_icons.bin", 0x74ba, 1024	; 32x32 -- rack sound module above mixer faders
Bitmap_SoundIcon_FiddleAndBanjo:	.incbin "includes/wallpaper1_to_icons.bin", 0x78ba, 1024	; 32x32 -- crossed fiddle/bow with banjo head
Bitmap_SoundIcon_GrandPiano:		.incbin "includes/wallpaper1_to_icons.bin", 0x7cba, 1024	; 32x32
Bitmap_SoundIcon_SaxAndClarinet:	.incbin "includes/wallpaper1_to_icons.bin", 0x80ba, 1024	; 32x32
Bitmap_SoundIcon_FiddleAndMandolin:	.incbin "includes/wallpaper1_to_icons.bin", 0x84ba, 1024	; 32x32 -- crossed fiddle/bow with oval mandolin body
Bitmap_SoundIcon_SynthKeyboard:		.incbin "includes/wallpaper1_to_icons.bin", 0x88ba, 1024	; 32x32 -- digital workstation keyboard
Bitmap_SoundIcon_Drawbars:		.incbin "includes/wallpaper1_to_icons.bin", 0x8cba, 1024	; 32x32 -- three numbered organ drawbars pulled to different lengths
Bitmap_SoundIcon_Accordion:		.incbin "includes/wallpaper1_to_icons.bin", 0x90ba, 1024	; 32x32
Bitmap_GreenLedButtonBright:		.incbin "includes/wallpaper1_to_icons.bin", 0x94ba, 176	; 15x11 -- small green LED button, lit
Bitmap_GreenLedButtonDim:		.incbin "includes/wallpaper1_to_icons.bin", 0x956a, 176	; 15x11 -- small green LED button, dimmed
Bitmap_GeneralMidiSpecialLogo:		.incbin "includes/wallpaper1_to_icons.bin", 0x961a, 1024	; 32x32 -- "GENERAL MIDI SPECIAL" text logo
Bitmap_SoundIcon_Metronome:		.incbin "includes/wallpaper1_to_icons.bin", 0x9a1a, 1024	; 32x32
Bitmap_SoundIcon_Microphone:		.incbin "includes/wallpaper1_to_icons.bin", 0x9e1a, 1024	; 32x32

	.fill 486, 1, 0xff

; -----------------------------------------------------------------------------
; Section banks 6 and 28-32 (0x91D000 - 0x933FFF): factory UI images
; -----------------------------------------------------------------------------
; These six blocks are indexed by SectionDirectory_Table entries 6 and 28-32
; (floppy save/load banks), but their factory content is a set of full UI
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
Frame_RoundCorner1_TL:			.incbin "includes/wallpaper1_to_icons.bin", 0x215b0, 2	; 1x1
Frame_RoundCorner1_TR:			.incbin "includes/wallpaper1_to_icons.bin", 0x215b2, 2	; 1x1
Frame_RoundCorner1_BR:			.incbin "includes/wallpaper1_to_icons.bin", 0x215b4, 2	; 1x1
Frame_RoundCorner1_BL:			.incbin "includes/wallpaper1_to_icons.bin", 0x215b6, 2	; 1x1
Frame_RoundCorner2_TL:			.incbin "includes/wallpaper1_to_icons.bin", 0x215b8, 4	; 2x2
Frame_RoundCorner2_TR:			.incbin "includes/wallpaper1_to_icons.bin", 0x215bc, 4	; 2x2
Frame_RoundCorner2_BR:			.incbin "includes/wallpaper1_to_icons.bin", 0x215c0, 4	; 2x2
Frame_RoundCorner2_BL:			.incbin "includes/wallpaper1_to_icons.bin", 0x215c4, 4	; 2x2
Frame_RoundCorner5_TL:			.incbin "includes/wallpaper1_to_icons.bin", 0x215c8, 30	; 5x5
Frame_RoundCorner5_TR:			.incbin "includes/wallpaper1_to_icons.bin", 0x215e6, 30	; 5x5
Frame_RoundCorner5_BR:			.incbin "includes/wallpaper1_to_icons.bin", 0x21604, 30	; 5x5
Frame_RoundCorner5_BL:			.incbin "includes/wallpaper1_to_icons.bin", 0x21622, 30	; 5x5
Frame_RoundCorner9_TL:			.incbin "includes/wallpaper1_to_icons.bin", 0x21640, 90	; 9x9
Frame_RoundCorner9_TR:			.incbin "includes/wallpaper1_to_icons.bin", 0x2169a, 90	; 9x9
Frame_RoundCorner9_BR:			.incbin "includes/wallpaper1_to_icons.bin", 0x216f4, 90	; 9x9
Frame_RoundCorner9_BL:			.incbin "includes/wallpaper1_to_icons.bin", 0x2174e, 90	; 9x9
Frame_RoundCorner14_TL:			.incbin "includes/wallpaper1_to_icons.bin", 0x217a8, 196	; 14x14
Frame_RoundCorner14_TR:			.incbin "includes/wallpaper1_to_icons.bin", 0x2186c, 196	; 14x14
Frame_RoundCorner14_BR:			.incbin "includes/wallpaper1_to_icons.bin", 0x21930, 196	; 14x14
Frame_RoundCorner14_BL:			.incbin "includes/wallpaper1_to_icons.bin", 0x219f4, 196	; 14x14
Frame_ChevronRight_5x12:		.incbin "includes/wallpaper1_to_icons.bin", 0x21ab8, 72	; 5x12
Frame_ChevronRight_6x16:		.incbin "includes/wallpaper1_to_icons.bin", 0x21b00, 96	; 6x16
Frame_ChevronRight_8x24:		.incbin "includes/wallpaper1_to_icons.bin", 0x21b60, 192	; 8x24
Frame_ChevronRight_10x32:		.incbin "includes/wallpaper1_to_icons.bin", 0x21c20, 320	; 10x32
Frame_ChevronRight_15x48:		.incbin "includes/wallpaper1_to_icons.bin", 0x21d60, 768	; 15x48
Frame_ChevronLeft_5x12:			.incbin "includes/wallpaper1_to_icons.bin", 0x22060, 72	; 5x12
Frame_ChevronLeft_6x16:			.incbin "includes/wallpaper1_to_icons.bin", 0x220a8, 96	; 6x16
Frame_ChevronLeft_8x24:			.incbin "includes/wallpaper1_to_icons.bin", 0x22108, 192	; 8x24
Frame_ChevronLeft_10x32:		.incbin "includes/wallpaper1_to_icons.bin", 0x221c8, 320	; 10x32
Frame_ChevronLeft_15x48:		.incbin "includes/wallpaper1_to_icons.bin", 0x22308, 768	; 15x48
Frame_OnOffTabLeft_20x16:		.incbin "includes/wallpaper1_to_icons.bin", 0x22608, 320	; 20x16
Frame_OnOffTabLeft_24x24:		.incbin "includes/wallpaper1_to_icons.bin", 0x22748, 576	; 24x24
Frame_OnOffTabLeft_29x32:		.incbin "includes/wallpaper1_to_icons.bin", 0x22988, 960	; 29x32
Frame_OnOffTabLeft_34x48:		.incbin "includes/wallpaper1_to_icons.bin", 0x22d48, 1632	; 34x48
Frame_OnOffTabRight_20x16:		.incbin "includes/wallpaper1_to_icons.bin", 0x233a8, 320	; 20x16
Frame_OnOffTabRight_24x24:		.incbin "includes/wallpaper1_to_icons.bin", 0x234e8, 576	; 24x24
Frame_OnOffTabRight_29x32:		.incbin "includes/wallpaper1_to_icons.bin", 0x23728, 960	; 29x32
Frame_OnOffTabRight_34x48:		.incbin "includes/wallpaper1_to_icons.bin", 0x23ae8, 1632	; 34x48
Frame_RedArrowLeft:			.incbin "includes/wallpaper1_to_icons.bin", 0x24148, 256	; 16x16
Frame_RedArrowRight:			.incbin "includes/wallpaper1_to_icons.bin", 0x24248, 256	; 16x16
Frame_BevelCornerRaised_TL:		.incbin "includes/wallpaper1_to_icons.bin", 0x24348, 30	; 5x5
Frame_BevelCornerRaised_TR:		.incbin "includes/wallpaper1_to_icons.bin", 0x24366, 30	; 5x5
Frame_BevelCornerRaised_BR:		.incbin "includes/wallpaper1_to_icons.bin", 0x24384, 30	; 5x5
Frame_BevelCornerRaised_BL:		.incbin "includes/wallpaper1_to_icons.bin", 0x243a2, 30	; 5x5
Frame_BevelCornerOutlined_TL:		.incbin "includes/wallpaper1_to_icons.bin", 0x243c0, 30	; 5x5
Frame_BevelCornerOutlined_TR:		.incbin "includes/wallpaper1_to_icons.bin", 0x243de, 30	; 5x5
Frame_BevelCornerOutlined_BR:		.incbin "includes/wallpaper1_to_icons.bin", 0x243fc, 30	; 5x5
Frame_BevelCornerOutlined_BL:		.incbin "includes/wallpaper1_to_icons.bin", 0x2441a, 30	; 5x5
Frame_BevelCornerSunken_TL:		.incbin "includes/wallpaper1_to_icons.bin", 0x24438, 30	; 5x5
Frame_BevelCornerSunken_TR:		.incbin "includes/wallpaper1_to_icons.bin", 0x24456, 30	; 5x5
Frame_BevelCornerSunken_BR:		.incbin "includes/wallpaper1_to_icons.bin", 0x24474, 30	; 5x5
Frame_BevelCornerSunken_BL:		.incbin "includes/wallpaper1_to_icons.bin", 0x24492, 30	; 5x5
Frame_WideTabBar:			.incbin "includes/wallpaper1_to_icons.bin", 0x244b0, 836	; 76x11

	.fill 3084, 1, 0xff
