; =============================================================================
; UI TEXT FONTS -- Descriptor Table + 1bpp Glyph Banks (0x944D78-0x950FFF)
; =============================================================================
; The KN5000's on-screen text renderer draws from ten bitmap fonts stored
; here.  The descriptor table at 0x945C00 has 16-byte entries:
;
;   +0x00  word  width      pixels per character (0 = proportional font)
;   +0x02  word  height     pixels
;   +0x04  word  descender  pixels below baseline
;   +0x06  word  ascender   pixels above cap height
;   +0x08  long  glyph-bank pointer (1bpp bitmaps)
;   +0x0C  long  kern-table pointer (0 = fixed width)
;
; CONSUMERS (Main CPU ROM, numeric cross-ROM references): TextRender_LoadFontData
; (v10/maincpu/kn5000_v10_program.s) and DrawString_Impl_ClipCursorYMin
; (v10/maincpu/ui/drawing_primitives.s) both compute 0x945C00 + 16*font_id;
; when the kern pointer is null they read +0x00 and +0x06 for fixed-width
; advance, otherwise the kern table drives per-character widths.
;
; GLYPH BANK FORMAT: every bank covers characters 0x20-0xFF (224 glyphs; the
; renderer subtracts 0x20, see DrawString_Impl_KerningLookup `sub c, 0x20`).
; A glyph is stored column-major: ceil(width/8) columns, each column `height`
; bytes top-to-bottom, MSB = leftmost pixel of the 8-pixel column slice.
; Fixed-width glyph size = ceil(width/8)*height; the nine fixed banks tile
; their address ranges exactly (224 glyphs each, no gaps).
;
; UPPER CODE PAGES (0x7F-0xFF) come in two flavours:
;   * fonts 0/1/2/3/4/6: UI-symbol page -- arrows/markers in 0x7F-0xAC and
;     empty-box placeholder glyphs in the Latin-1 letter slots
;   * fonts 5/7/8/9: Latin-1 accent page (A-umlaut at 0xC4, e-acute at 0xE9,
;     ...) used by the multilingual UI/help text; fonts 7/8/9 are otherwise
;     byte-identical to fonts 0/1/4 over 0x20-0x7E
;
; FONT 5 is the only proportional font: its descriptor width is 0 and its
; kern table (Font5_KernTable) holds 224 {word char_width, word glyph_offset}
; pairs; each glyph occupies ceil(char_width/8)*16 bytes at
; Font5_Glyphs + glyph_offset, and the entries tile 0x94B7B0-0x94C61F exactly.
;
; NOTE: Font9's bank runs past 0x950000 -- characters 0xAD-0xFF live at
; 0x950000-0x950A5F.  (This area was previously misfiled as standalone
; "sparse bitmap-like data"; it is simply the tail of Font9.)
;
; Rendered previews: extracted_fonts/font_00..font_09.{bdf,pgm,png}, produced
; by scripts/analysis/extract_fonts.py from this very table (ASCII subset).
; =============================================================================

	.org 0x944D78 - 0x800000, 0xFF

	; unused gap before the font area (previously mislabelled
	; "Miscellaneous data tables")
	.fill 3720, 1, 0xff	; 0x944D78-0x945BFF

; -----------------------------------------------------------------------------
; Font descriptor table: 10 entries {w, h, descender, ascender, glyphs, kern}
; plus one all-zero unused slot.
; -----------------------------------------------------------------------------
FontDescriptor_Table:
	; Font 0 -- 8x16 fixed, UI-symbol upper page; same letterforms as
	; Font 7 over 0x20-0x7E
	.short	8, 16, 4, 1
	.long	Font0_Glyphs, 0

	; Font 1 -- 8x16 fixed, UI-symbol upper page; glyphs sit 2 px higher
	; in the cell than Font 0 (same style otherwise)
	.short	8, 16, 4, 1
	.long	Font1_Glyphs, 0

	; Font 2 -- 16x16 fixed double-width headline font, UI-symbol upper page
	.short	16, 16, 2, 2
	.long	Font2_Glyphs, 0

	; Font 3 -- 6x8 fixed small font, UI-symbol upper page
	.short	6, 8, 1, 1
	.long	Font3_Glyphs, 0

	; Font 4 -- 11x16 fixed large font, UI-symbol upper page; same
	; letterforms as Font 9 over 0x20-0x7E
	.short	11, 16, 2, 2
	.long	Font4_Glyphs, 0

	; Font 5 -- proportional (width 0: per-character widths 3-10 from the
	; kern table), 16 px tall, Latin-1 accent upper page
	.short	0, 16, 4, 0
	.long	Font5_Glyphs, Font5_KernTable

	; Font 6 -- 8x10 fixed compact font, UI-symbol upper page
	.short	8, 10, 0, 1
	.long	Font6_Glyphs, 0

	; Font 7 -- 8x16 fixed, Latin-1 accent upper page (Font 0 letterforms)
	.short	8, 16, 4, 1
	.long	Font7_Glyphs, 0

	; Font 8 -- 8x16 fixed, Latin-1 accent upper page (Font 1 letterforms)
	.short	8, 16, 4, 1
	.long	Font8_Glyphs, 0

	; Font 9 -- 11x16 fixed, Latin-1 accent upper page (Font 4 letterforms)
	.short	11, 16, 2, 2
	.long	Font9_Glyphs, 0

	; unused 11th slot
	.short	0, 0, 0, 0
	.long	0, 0

; -----------------------------------------------------------------------------
; Glyph banks 0-5 (1bpp, column-major, chars 0x20-0xFF; offsets are into
; includes/icons_to_strings.bin, whose file offset 0 = ROM 0x944D78)
; -----------------------------------------------------------------------------
Font0_Glyphs:	.incbin	"includes/generated/Font0_Glyphs.bin"	; 224 x 16 B (8x16)
Font1_Glyphs:	.incbin	"includes/generated/Font1_Glyphs.bin"	; 224 x 16 B (8x16)
Font2_Glyphs:	.incbin	"includes/generated/Font2_Glyphs.bin"	; 224 x 32 B (16x16)
Font3_Glyphs:	.incbin	"includes/generated/Font3_Glyphs.bin"	; 224 x 8 B (6x8)
Font4_Glyphs:	.incbin	"includes/generated/Font4_Glyphs.bin"	; 224 x 32 B (11x16)
Font5_Glyphs:	.incbin	"includes/icons_to_strings.bin", 0x6A38, 0xE70	; 224 variable-size glyphs, tiled per kern table

; -----------------------------------------------------------------------------
; Font 5 kern table: one {word char_width, word glyph_offset} pair per
; character 0x20-0xFF.  glyph_offset is relative to Font5_Glyphs; each glyph
; occupies ceil(char_width/8)*16 bytes and the 224 entries tile the bank
; exactly (offsets strictly ascending, no gaps).
; -----------------------------------------------------------------------------
Font5_KernTable:
	.short	8, 0x000	; 0x20 ' '
	.short	5, 0x010	; 0x21 '!'
	.short	8, 0x020	; 0x22 '"'
	.short	8, 0x030	; 0x23 '#'
	.short	8, 0x040	; 0x24 '$'
	.short	8, 0x050	; 0x25 '%'
	.short	8, 0x060	; 0x26 '&'
	.short	5, 0x070	; 0x27 apostrophe
	.short	8, 0x080	; 0x28 '('
	.short	8, 0x090	; 0x29 ')'
	.short	8, 0x0A0	; 0x2A '*'
	.short	8, 0x0B0	; 0x2B '+'
	.short	5, 0x0C0	; 0x2C ','
	.short	8, 0x0D0	; 0x2D '-'
	.short	5, 0x0E0	; 0x2E '.'
	.short	8, 0x0F0	; 0x2F '/'
	.short	8, 0x100	; 0x30 '0'
	.short	7, 0x110	; 0x31 '1'
	.short	8, 0x120	; 0x32 '2'
	.short	8, 0x130	; 0x33 '3'
	.short	8, 0x140	; 0x34 '4'
	.short	8, 0x150	; 0x35 '5'
	.short	8, 0x160	; 0x36 '6'
	.short	8, 0x170	; 0x37 '7'
	.short	8, 0x180	; 0x38 '8'
	.short	8, 0x190	; 0x39 '9'
	.short	5, 0x1A0	; 0x3A ':'
	.short	5, 0x1B0	; 0x3B ';'
	.short	7, 0x1C0	; 0x3C '<'
	.short	8, 0x1D0	; 0x3D '='
	.short	7, 0x1E0	; 0x3E '>'
	.short	8, 0x1F0	; 0x3F '?'
	.short	8, 0x200	; 0x40 '@'
	.short	8, 0x210	; 0x41 'A'
	.short	8, 0x220	; 0x42 'B'
	.short	8, 0x230	; 0x43 'C'
	.short	8, 0x240	; 0x44 'D'
	.short	8, 0x250	; 0x45 'E'
	.short	8, 0x260	; 0x46 'F'
	.short	8, 0x270	; 0x47 'G'
	.short	8, 0x280	; 0x48 'H'
	.short	7, 0x290	; 0x49 'I'
	.short	8, 0x2A0	; 0x4A 'J'
	.short	8, 0x2B0	; 0x4B 'K'
	.short	8, 0x2C0	; 0x4C 'L'
	.short	10, 0x2D0	; 0x4D 'M'
	.short	8, 0x2F0	; 0x4E 'N'
	.short	8, 0x300	; 0x4F 'O'
	.short	8, 0x310	; 0x50 'P'
	.short	8, 0x320	; 0x51 'Q'
	.short	8, 0x330	; 0x52 'R'
	.short	8, 0x340	; 0x53 'S'
	.short	7, 0x350	; 0x54 'T'
	.short	8, 0x360	; 0x55 'U'
	.short	8, 0x370	; 0x56 'V'
	.short	10, 0x380	; 0x57 'W'
	.short	8, 0x3A0	; 0x58 'X'
	.short	7, 0x3B0	; 0x59 'Y'
	.short	8, 0x3C0	; 0x5A 'Z'
	.short	8, 0x3D0	; 0x5B '['
	.short	8, 0x3E0	; 0x5C backslash
	.short	8, 0x3F0	; 0x5D ']'
	.short	7, 0x400	; 0x5E '^'
	.short	8, 0x410	; 0x5F '_'
	.short	5, 0x420	; 0x60 '`'
	.short	8, 0x430	; 0x61 'a'
	.short	8, 0x440	; 0x62 'b'
	.short	8, 0x450	; 0x63 'c'
	.short	8, 0x460	; 0x64 'd'
	.short	8, 0x470	; 0x65 'e'
	.short	7, 0x480	; 0x66 'f'
	.short	8, 0x490	; 0x67 'g'
	.short	8, 0x4A0	; 0x68 'h'
	.short	5, 0x4B0	; 0x69 'i'
	.short	8, 0x4C0	; 0x6A 'j'
	.short	8, 0x4D0	; 0x6B 'k'
	.short	6, 0x4E0	; 0x6C 'l'
	.short	9, 0x4F0	; 0x6D 'm'
	.short	8, 0x510	; 0x6E 'n'
	.short	8, 0x520	; 0x6F 'o'
	.short	8, 0x530	; 0x70 'p'
	.short	8, 0x540	; 0x71 'q'
	.short	8, 0x550	; 0x72 'r'
	.short	8, 0x560	; 0x73 's'
	.short	7, 0x570	; 0x74 't'
	.short	8, 0x580	; 0x75 'u'
	.short	8, 0x590	; 0x76 'v'
	.short	10, 0x5A0	; 0x77 'w'
	.short	8, 0x5C0	; 0x78 'x'
	.short	8, 0x5D0	; 0x79 'y'
	.short	8, 0x5E0	; 0x7A 'z'
	.short	8, 0x5F0	; 0x7B '{'
	.short	5, 0x600	; 0x7C '|'
	.short	8, 0x610	; 0x7D '}'
	.short	8, 0x620	; 0x7E '~'
	.short	8, 0x630	; 0x7F
	.short	8, 0x640	; 0x80
	.short	8, 0x650	; 0x81
	.short	5, 0x660	; 0x82
	.short	7, 0x670	; 0x83
	.short	8, 0x680	; 0x84
	.short	10, 0x690	; 0x85
	.short	8, 0x6B0	; 0x86
	.short	8, 0x6C0	; 0x87
	.short	5, 0x6D0	; 0x88
	.short	10, 0x6E0	; 0x89
	.short	8, 0x700	; 0x8A
	.short	4, 0x710	; 0x8B
	.short	8, 0x720	; 0x8C
	.short	8, 0x730	; 0x8D
	.short	8, 0x740	; 0x8E
	.short	8, 0x750	; 0x8F
	.short	8, 0x760	; 0x90
	.short	5, 0x770	; 0x91
	.short	5, 0x780	; 0x92
	.short	7, 0x790	; 0x93
	.short	7, 0x7A0	; 0x94
	.short	5, 0x7B0	; 0x95
	.short	6, 0x7C0	; 0x96
	.short	10, 0x7D0	; 0x97
	.short	6, 0x7F0	; 0x98
	.short	8, 0x800	; 0x99
	.short	8, 0x810	; 0x9A
	.short	4, 0x820	; 0x9B
	.short	8, 0x830	; 0x9C
	.short	8, 0x840	; 0x9D
	.short	8, 0x850	; 0x9E
	.short	7, 0x860	; 0x9F
	.short	8, 0x870	; 0xA0
	.short	3, 0x880	; 0xA1
	.short	8, 0x890	; 0xA2
	.short	8, 0x8A0	; 0xA3
	.short	8, 0x8B0	; 0xA4
	.short	8, 0x8C0	; 0xA5
	.short	3, 0x8D0	; 0xA6
	.short	8, 0x8E0	; 0xA7
	.short	6, 0x8F0	; 0xA8
	.short	8, 0x900	; 0xA9
	.short	8, 0x910	; 0xAA
	.short	8, 0x920	; 0xAB
	.short	8, 0x930	; 0xAC
	.short	5, 0x940	; 0xAD
	.short	8, 0x950	; 0xAE
	.short	8, 0x960	; 0xAF
	.short	5, 0x970	; 0xB0
	.short	8, 0x980	; 0xB1
	.short	5, 0x990	; 0xB2
	.short	5, 0x9A0	; 0xB3
	.short	4, 0x9B0	; 0xB4
	.short	8, 0x9C0	; 0xB5
	.short	8, 0x9D0	; 0xB6
	.short	8, 0x9E0	; 0xB7
	.short	5, 0x9F0	; 0xB8
	.short	4, 0xA00	; 0xB9
	.short	5, 0xA10	; 0xBA
	.short	8, 0xA20	; 0xBB
	.short	8, 0xA30	; 0xBC
	.short	8, 0xA40	; 0xBD
	.short	8, 0xA50	; 0xBE
	.short	8, 0xA60	; 0xBF
	.short	8, 0xA70	; 0xC0
	.short	8, 0xA80	; 0xC1
	.short	8, 0xA90	; 0xC2
	.short	8, 0xAA0	; 0xC3
	.short	8, 0xAB0	; 0xC4
	.short	8, 0xAC0	; 0xC5
	.short	8, 0xAD0	; 0xC6
	.short	8, 0xAE0	; 0xC7
	.short	8, 0xAF0	; 0xC8
	.short	8, 0xB00	; 0xC9
	.short	8, 0xB10	; 0xCA
	.short	8, 0xB20	; 0xCB
	.short	7, 0xB30	; 0xCC
	.short	7, 0xB40	; 0xCD
	.short	8, 0xB50	; 0xCE
	.short	7, 0xB60	; 0xCF
	.short	8, 0xB70	; 0xD0
	.short	8, 0xB80	; 0xD1
	.short	8, 0xB90	; 0xD2
	.short	8, 0xBA0	; 0xD3
	.short	8, 0xBB0	; 0xD4
	.short	8, 0xBC0	; 0xD5
	.short	8, 0xBD0	; 0xD6
	.short	8, 0xBE0	; 0xD7
	.short	8, 0xBF0	; 0xD8
	.short	8, 0xC00	; 0xD9
	.short	8, 0xC10	; 0xDA
	.short	8, 0xC20	; 0xDB
	.short	8, 0xC30	; 0xDC
	.short	7, 0xC40	; 0xDD
	.short	8, 0xC50	; 0xDE
	.short	8, 0xC60	; 0xDF
	.short	8, 0xC70	; 0xE0
	.short	8, 0xC80	; 0xE1
	.short	8, 0xC90	; 0xE2
	.short	8, 0xCA0	; 0xE3
	.short	8, 0xCB0	; 0xE4
	.short	8, 0xCC0	; 0xE5
	.short	8, 0xCD0	; 0xE6
	.short	8, 0xCE0	; 0xE7
	.short	8, 0xCF0	; 0xE8
	.short	8, 0xD00	; 0xE9
	.short	8, 0xD10	; 0xEA
	.short	8, 0xD20	; 0xEB
	.short	4, 0xD30	; 0xEC
	.short	4, 0xD40	; 0xED
	.short	5, 0xD50	; 0xEE
	.short	7, 0xD60	; 0xEF
	.short	8, 0xD70	; 0xF0
	.short	8, 0xD80	; 0xF1
	.short	8, 0xD90	; 0xF2
	.short	8, 0xDA0	; 0xF3
	.short	8, 0xDB0	; 0xF4
	.short	8, 0xDC0	; 0xF5
	.short	8, 0xDD0	; 0xF6
	.short	8, 0xDE0	; 0xF7
	.short	8, 0xDF0	; 0xF8
	.short	8, 0xE00	; 0xF9
	.short	8, 0xE10	; 0xFA
	.short	8, 0xE20	; 0xFB
	.short	8, 0xE30	; 0xFC
	.short	8, 0xE40	; 0xFD
	.short	8, 0xE50	; 0xFE
	.short	8, 0xE60	; 0xFF

; -----------------------------------------------------------------------------
; Glyph banks 6-9.  Font9's bank crosses 0x950000: chars 0xAD-0xFF occupy
; 0x950000-0x950A5F (see module header).
; -----------------------------------------------------------------------------
Font6_Glyphs:	.incbin	"includes/generated/Font6_Glyphs.bin"	; 224 x 10 B (8x10)
Font7_Glyphs:	.incbin	"includes/generated/Font7_Glyphs.bin"	; 224 x 16 B (8x16)
Font8_Glyphs:	.incbin	"includes/generated/Font8_Glyphs.bin"	; 224 x 16 B (8x16)
Font9_Glyphs:	.incbin	"includes/generated/Font9_Glyphs.bin"	; 224 x 32 B (11x16), ends 0x950A5F

	; unused gap up to the style/preset record area at 0x951000
	.fill 1440, 1, 0xff	; 0x950A60-0x950FFF
