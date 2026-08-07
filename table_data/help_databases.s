; =============================================================================
; HELP SYSTEM -- Multilingual Intro Strings + SLIDE8K Help Databases
; (plus the two effect-preset pointer tables that overwrote a stale block)
; =============================================================================
; ROM range 0x983B3A-0x9999CB.  This is the on-screen HELP system's data:
; press the HELP button, then any panel button, and the firmware looks the
; button up in the active language's database and renders the explanation.
;
; LAYOUT:
;   0x983B3A  HelpDB_German_Stale         truncated SLIDE8K remnant (see below)
;   0x986000  EffectPreset_PtrTable_C2C5     1000 x 4-byte LE ptrs + 96 B residue
;   0x987000  EffectPreset_PtrTable_Default  1000 x 4-byte LE ptrs + 96 B residue
;   0x988000  HelpIntro_LanguageTable     6 x 4-byte LE pointers -> intro strings
;   0x988018  HelpDB_LanguageTable        6 x 4-byte LE pointers -> SLIDE8K blocks
;   0x988030  Str_HelpIntro_*             5 null-terminated intro strings (Latin-1)
;   0x988690  HelpDB_English              SLIDE8K -> 0x9000 bytes
;   0x98BB3A  HelpDB_German               SLIDE8K -> 0x9000 bytes
;   0x98F0DA  HelpDB_French               SLIDE8K -> 0x9000 bytes
;   0x992A0C  HelpDB_Spanish              SLIDE8K -> 0x9000 bytes
;   0x9963FA  HelpDB_Indonesian           SLIDE8K -> 0x9000 bytes
;
; The two pointer tables at 0x988000/0x988018 form one 12-entry language
; index.  Both are indexed by the help-language number in RAM 0x0340E4; both
; have SIX slots whose 5th entry reuses English (only 5 distinct languages).
;
; CONSUMERS (Main CPU ROM): the help-language load path near HELPLANGCHKMAIN
; (0xF477AD region) computes 0x988018 + 4*language, loads the SLIDE8K block
; pointer, and calls SLIDE_Parse_Header with destination RAM 0x69800
; (v10/maincpu/boot/system_handlers.s dispatches on the '8' of the magic to
; SLIDE_Decompress_8K_Init).  Each database decompresses to exactly 0x9000
; bytes: a self-referential pointer table plus help-string pool, based at
; RAM 0x69800.  Strings use "~0d" as the newline escape.
;
; SLIDE8K CONTAINER (see scripts/build/decompress_slide8k.py for the full
; format, and SLIDE_Decompress_8K_Init for the hardware decoder):
;   * 11-byte header: "SLIDE8K\0" magic + 24-bit BIG-endian decompressed size
;   * LZSS bitstream: flag byte LSB-first (1=literal, 0=match); a match is 2
;     bytes encoding a 13-bit absolute ring position and a 3..10 byte count
;     over a 0x2000-byte ring (zero-prefilled to the 0x1FF6 start position)
;   * termination purely by output count; the final flag byte may be only
;     partially consumed and its unused bits are NONZERO in these blocks, so
;     only decision-replay against the factory stream is byte-exact
;   * each stream is odd-length and followed by ONE alignment pad byte of
;     arbitrary leftover value (0x20/0x7F/0xCF/0xCD/0xCE) that the decoder
;     never reads; the pad is preserved inside each *_compressed.bin
;
; BUILD: the five live compressed payloads are BUILD PRODUCTS.  The checked-in
; sources are the decompressed databases in includes/help_databases/; the
; Makefile recompresses them with scripts/build/compress_slide8k.py --strict
; --reference original_ROMs/help_db_<lang>_compressed.original.bin, which
; replays the factory encoder's decisions for byte-identical output (same
; flow as the SLIDE4K demo-song presets).  `make verify-help-databases`
; byte-compares all rebuilt payloads against the original slices.
;
; THE STALE GERMAN BLOCK IS TRUNCATED, NOT MERELY CORRUPT: its SLIDE8K
; stream is intact only up to ROM 0x985FFF.  Decoding it tracks the live
; German database byte-for-byte for exactly 0x55E0 output bytes, and the
; element that produces output 0x55E0 is the first one to read past
; 0x985FFF -- the factory image wrote the two effect-preset pointer tables
; at 0x986000/0x987000 straight over the tail of this obsolete block (no
; pointer to 0x983B3A exists in any program ROM: v7, v9 or v10).  The
; remnant is therefore kept as a raw slice of the dump, byte-exact; it is
; NOT rebuilt from a decompressed source because its tail no longer exists.
; A whole-extent reference slice (original_ROMs/help_db_german_stale_
; compressed.original.bin, covering 0x983B45-0x987A33 as the decoder would
; walk it) is still round-trip-verified by `make verify-help-databases` to
; pin these bytes down.  Do not "fix" any of this.
; =============================================================================

	.org 0x983B3A - 0x800000, 0xFF

HelpDB_German_Stale:
	.asciz	"SLIDE8K"
	.byte	0x00, 0x90, 0x00	; decompressed size = 0x9000 (24-bit big-endian)
	; stream remnant, ROM 0x983B45-0x985FFF (raw slice; tail overwritten,
	; see module header)
	.incbin	"includes/icons_to_strings.bin", 0x3EDCD, 0x24BB

; -----------------------------------------------------------------------------
; Effect-preset pointer tables (written over the stale block's tail).
; Selected on the model code in RAM 0x8D38: 0xC2 (KN3000) / 0xC5 (KN5000) use
; the first table, every other model code the second (maincpu
; EffectMode_ClampAndLookup, v10/maincpu/ui/ui_mode_handlers.s -- the index
; is clamped to 1000 there, matching the 1000 entries).  Each 4KB page holds
; 1000 4-byte LE pointers to preset records in the 0x951000 region, followed
; by 96 bytes of unreferenced residue.
; TODO: convert to symbolic .long entries once the 0x951000 preset-record
; region has labels; maincpu references these tables numerically for now.
; -----------------------------------------------------------------------------
EffectPreset_PtrTable_C2C5:	.incbin	"includes/icons_to_strings.bin", 0x41288, 0x1000
EffectPreset_PtrTable_Default:	.incbin	"includes/icons_to_strings.bin", 0x42288, 0x1000

; -----------------------------------------------------------------------------
; Help language index (0x988000): two parallel 6-slot pointer tables indexed
; by the help-language number (RAM 0x0340E4).  Slot 4 reuses English in BOTH.
; -----------------------------------------------------------------------------
HelpIntro_LanguageTable:
	.long	Str_HelpIntro_English
	.long	Str_HelpIntro_German
	.long	Str_HelpIntro_French
	.long	Str_HelpIntro_Spanish
	.long	Str_HelpIntro_English	; slot 4: no 5th translation, reuses English
	.long	Str_HelpIntro_Indonesian

HelpDB_LanguageTable:
	.long	HelpDB_English
	.long	HelpDB_German
	.long	HelpDB_French
	.long	HelpDB_Spanish
	.long	HelpDB_English		; slot 4: no 5th translation, reuses English
	.long	HelpDB_Indonesian

; -----------------------------------------------------------------------------
; Intro strings shown on the HELP start screen (Latin-1 accents as \NNN octal
; escapes, "~0d" = newline escape understood by the help renderer).  Strings
; start on even addresses; a single arbitrary-value filler byte follows a
; string whose terminator lands on an even address.
; -----------------------------------------------------------------------------
Str_HelpIntro_English:
	.ascii	"After pressing the Help button, press any button on the KN5000 and the "
	.ascii	"screen will give you information about the button's use. Press the HELP "
	.ascii	"button again, or the EXIT button to turn off the HELP function.~0dUse "
	.ascii	"the buttons at the bottom of the this screen to change the Help language "
	.asciz	"and press OK.~0d"
	.byte	0xAC			; even-alignment filler (arbitrary leftover value)

Str_HelpIntro_German:
	.ascii	"Dr\374cken Sie eine beliebige Taste am KN5000 und das Display gibt Ihnen "
	.ascii	"Informationen \374ber die Funktion der gew\344hlten Taste. Mit den Tasten HELP "
	.ascii	"oder EXIT schalten Sie die HELP Funktion wieder aus.~0dVerwenden Sie die "
	.ascii	"Tasten unter dem Display um die gew\374nschte Sprache auszuw\344hlen und "
	.asciz	"best\344tigen Sie mit OK.~0d"
	.byte	0x00			; even-alignment filler

Str_HelpIntro_French:
	.ascii	"Apr\350s avoir activ\351 le bouton Help, pressez n'importe quel bouton du "
	.ascii	"KN5000 et l'\351cran vous donnera des informations sur la d\351finition et "
	.ascii	"l'utilisation de ce bouton. Pressez \340 nouveau le bouton HELP, ou le "
	.ascii	"bouton EXIT pour d\351sactiver la fonction HELP.~0dA l'aide des boutons "
	.ascii	"situ\351s en haut de l'\351cran, s\351lectionnez une langue d'affichage de HELP, "
	.asciz	"puis pressez OK.~0d"

Str_HelpIntro_Spanish:
	.ascii	"Despu\351s de oprimir el bot\363n HELP (ayuda), presione cualquier bot\363n del "
	.ascii	"KN5000 y la pantalla le suministrar\341 informaci\363n acerca del mismo. "
	.ascii	"Oprima el bot\363n HELP nuevamente o el bot\363n EXIT (salir) para finalizar "
	.ascii	"la funci\363n de ayuda.~0dUtilice los botones en la parte inferior de esta "
	.asciz	"pantalla para cambiar el idioma del Help (Ayuda) y oprima OK.~0d"

Str_HelpIntro_Indonesian:
	.ascii	"Setelah menekan tombol Help, tekan sembarang tombol pada KN5000 dan "
	.ascii	"layar akan memberikan informasi kepada anda mengenai fungsi tombol "
	.ascii	"tersebut, atau tekan tombol Exit untuk mengakhiri fungsi Help.~0dGunakan "
	.ascii	"tombol-tombol yg ada pada bagian bawah layar untuk mengubah instruksi "
	.asciz	"HELP, kemudian tekan OK.~0d"

; -----------------------------------------------------------------------------
; The five live SLIDE8K help databases (see module header for format and
; build).  Blocks tile contiguously: each *_compressed.bin ends with the one
; alignment pad byte, so the next block starts immediately after it.
; -----------------------------------------------------------------------------
HelpDB_English:
	.asciz	"SLIDE8K"
	.byte	0x00, 0x90, 0x00	; decompressed size = 0x9000 (24-bit big-endian)
	.incbin	"includes/help_databases/help_db_english_compressed.bin"

HelpDB_German:
	.asciz	"SLIDE8K"
	.byte	0x00, 0x90, 0x00	; decompressed size = 0x9000 (24-bit big-endian)
	.incbin	"includes/help_databases/help_db_german_compressed.bin"

HelpDB_French:
	.asciz	"SLIDE8K"
	.byte	0x00, 0x90, 0x00	; decompressed size = 0x9000 (24-bit big-endian)
	.incbin	"includes/help_databases/help_db_french_compressed.bin"

HelpDB_Spanish:
	.asciz	"SLIDE8K"
	.byte	0x00, 0x90, 0x00	; decompressed size = 0x9000 (24-bit big-endian)
	.incbin	"includes/help_databases/help_db_spanish_compressed.bin"

HelpDB_Indonesian:
	.asciz	"SLIDE8K"
	.byte	0x00, 0x90, 0x00	; decompressed size = 0x9000 (24-bit big-endian)
	.incbin	"includes/help_databases/help_db_indonesian_compressed.bin"
