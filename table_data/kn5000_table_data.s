
	.text

	.include "shared/macros.s"
	.include "shared/sfr_tmp94c241.s"

; =============================================================================
; TABLE DATA ROM — Structure Overview
; =============================================================================
; Address range: 0x800000 - 0x9FFFFF (2MB)
; At boot time, this ROM is mapped at 0xE00000-0xFFFFFF (same as Program ROM).
; After memory controller reconfiguration by Boot_Init, it moves to 0x800000.
;
; ROM LAYOUT:
;
; 0x800000-0x82FFFF  Section Directory + Preset Data Banks (preset_banks.s)
;                     - 34-entry pointer directory + 27 in-half sections
;                     - Factory defaults: 0xF7 (erased flash), 0x07, 0x00, or 0xFF
;                     - Entries 12-24: 13 x 3,016-byte slots (52 x 58-B records)
;                     - Entries 25-27: 3 x 31,968-byte slots (0xFF-dominant)
;                     CORRECTED 2026-09-25: all 33 directory entries are 8bpp
;                     bitmaps (0xF7 = transparent), byte-identical to images
;                     the program ROM also carries -- entries 12-24 are the
;                     58x52 split-point pictures, 25-27 the 296x108 MIDI
;                     connection diagrams; see preset_banks.s
; 0x830000-0x87FFEF  Tone Database (copied to SubCPU RAM 0x50000 at boot)
;                     - 0x830000 directory/program maps/offset table (tone_database_directory.s)
;                     - 0x8324D4 579 tone/voice records (tone_database_records.s)
;                     - 0x855A48 drum kits, percussion, name lists, env data (tone_database_aux.s)
; 0x87FFF0-0x8CFFFF  Feature Demo Data (SSF file, BMP bitmaps, file entries)
; 0x8D0000-0x8DFFFF  Unused (0xFF fill)
; 0x8E0000-0x8ECFFF  LZSS Compressed Preset Data (SLIDE4K format, ~28KB)
; 0x8ED000-0x912FFF  Wallpapers (2 x 320x240 8bpp), each followed by a 1KB
;                     trailer holding 16-entry {r,g,b,0} shade-ramp tables
; 0x913000-0x91CFFF  UI bitmap descriptor table (34) + 8bpp pixel runs
;                     (DrawBitmap/DrawBitmapFast source -- see ui_bitmaps.s)
; 0x91D000-0x933FFF  Section banks 6, 28-32: factory UI images (Technics
;                     logo, KN5000 picture, note/drum-edit screen backgrounds)
; 0x934000-0x937FFF  UI frame-piece descriptor table (53) + pixel runs
;                     (DrawFrameSP construction kit) + 0xFF fill
; 0x938000-0x938587  Icon descriptor table (176 entries + terminator)
; 0x938588-0x944D77  Icon pixel data (176 x 24x24 4bpp + 1 unreferenced
;                     "E.L.S." signature icon + 0xFF pad)
; 0x944D78-0x945BFF  Unused (0xFF fill)
; 0x945C00-0x945CAF  Font Descriptor Table (10 fonts x 16 bytes + null slot; fonts.s)
; 0x945CB0-0x950A5F  Font Glyph Bitmaps (1bpp, chars 0x20-0xFF per font; fonts.s)
; 0x950A60-0x950FFF  Unused (0xFF fill)
; 0x951000-0x98156F  Music Stylist preset records (1000 x 198 B, style_records.s)
; 0x981570-0x983B39  Unreferenced residue after the record grid (+ ramp remnant)
; 0x983B3A-0x985FFF  Stale truncated SLIDE8K help DB (old German revision)
; 0x986000-0x986FFF  Music Stylist pointer table (UI states 0xC2/0xC5)
; 0x987000-0x987FFF  Music Stylist pointer table (all other UI states)
; 0x988000-0x98868F  HELP language index (2 x 6 pointers) + intro strings
; 0x988690-0x9999CB  SLIDE8K HELP Databases (EN, DE, FR, ES, Indonesian)
; 0x9999CC-0x9999D2  Stray table residue after the help DBs (7 bytes)
; 0x9999D3-0x99EBFF  Unused (0xFF fill)
; 0x99EC00-0x99EC9F  Panel Memory factory bank names (10 x 16 chars)
; 0x99ECA0-0x9ABF3F  Panel Memory factory presets (80 x 674-byte chunk records)
; 0x9ABF40-0x9B3FFF  Unused (0xFF fill)
; 0x9B4000-0x9C3FFF  Composer factory user-style memory image (to RAM 0x94800)
; 0x9C4000-0x9C404F  Demo Song Preset Pointer Table (19 entries x 4 bytes + null)
;                     Each 4-byte LE pointer -> SLIDE4K compressed preset block
;                     Entry 18 (0x008E0000) = Feature Demo preset
; 0x9C4050-0x9F9FFF  SLIDE4K Compressed Demo Song Presets (entries 0-17)
; 0x9FA000-0x9FA14F  File Identifier Strings (floppy disk format IDs)
; 0x9FA150-0x9FB495  Boot Screen Bitmaps (1bpp: "Flash Memory Update", etc.)
; 0x9FB496-0x9FB4D1  FDC Bootloader Dispatch Offset Tables
; 0x9FB4D2-0x9FB4E7  Boot Data (bit mask table, init params)
; 0x9FB4E8-0x9FFFFF  First-Stage Bootloader Code + IVT
;
; KEY TABLES (accessed by Main CPU ROM):
;   Font Descriptors @ 0x945C00: 10 fonts, 16 bytes/entry (w,h,desc,asc,glyph_ptr,kern_ptr)
;   Demo Presets    @ 0x9C4000: 19 entries, 4 bytes/entry (pointers to SLIDE4K blocks)
;   Stylist Presets  @ 0x986000/0x987000: selected by UI state ID (RAM 0x8D38)
;   Help Lang Index  @ 0x988000: 12 entries, 4 bytes/entry (6 intro-string ptrs
;                      + 6 SLIDE8K help-database ptrs; slot 4 of each = English)
;   Section Directory@ 0x800000: 33 entries indexing preset data banks for floppy I/O
;                      (CORRECTED 2026-09-25: 33 bitmaps; no firmware reader
;                      found -- see preset_banks.s)
; =============================================================================

; =============================================================================
; Subcpu boot ROM handler addresses (cross-ROM references for IVT)
; =============================================================================
; Table Data flash: two x16 AMD-command-set chips side by side on the 32-bit bus
; (Flash_ReadID_32bit accepts AM29F800B / AM29LV800B), so every command word below
; carries the 8-bit command in both 16-bit halves, and the chips' word addresses
; 0x5555 / 0x2AAA appear at byte offsets 0x5555 * 4 and 0x2AAA * 4.
.equ TD_FLASH_BASE, 0x800000		; first 1 MB: disk "1/2" is copied here
.equ TD_FLASH_HALF2, 0x900000		; second 1 MB: disk "2/2" (Boot_LoadDiskData)
.equ TD_FLASH_UNLOCK1, TD_FLASH_BASE + 0x5555 * 4
.equ TD_FLASH_UNLOCK2, TD_FLASH_BASE + 0x2aaa * 4
.equ FLASH2_CMD_UNLOCK1, 0x00aa00aa
.equ FLASH2_CMD_UNLOCK2, 0x00550055
.equ FLASH2_CMD_RESET, 0x00f000f0
.equ FLASH2_CMD_AUTOSELECT, 0x00900090	; manufacturer / device ID read
.equ FLASH2_CMD_PROGRAM, 0x00a000a0
.equ FLASH2_CMD_ERASE_SETUP, 0x00800080
.equ FLASH2_CMD_CHIP_ERASE, 0x00100010
.equ FLASH2_CMD_SECTOR_ERASE, 0x00300030

; CORRECTED 2026-09-25: these are not sub-CPU boot ROM addresses.  Each value
; is the boot-time alias (ROM label + 0x600000) of a handler in THIS ROM --
; e.g. 0xFFFEE0 = RESET_HANDLER at 0x9FFEE0 -- which the IVT at 0x9FFF00
; must hold because the CPU fetches it while this ROM is mapped at 0xE00000.
; Now written symbolically; values unchanged (byte gate).
.equ BOOT_RESET_HANDLER, RESET_HANDLER + 0x600000
.equ BOOT_EMPTY_HANDLER, Empty_Handler + 0x600000
.equ BOOT_NMI_HANDLER, BootCode_NMI_Handler + 0x600000
.equ BOOT_INT4_HANDLER, Handler_INT4 + 0x600000
.equ BOOT_INTA_HANDLER, Handler_INTA + 0x600000
.equ BOOT_INTT1_HANDLER, BootCode_INTT1_Handler + 0x600000
.equ BOOT_INTRX1_HANDLER, Handler_INTRX1 + 0x600000
.equ BOOT_INTTX1_HANDLER, Handler_INTTX1 + 0x600000
.equ BOOT_INTTC3_HANDLER, BootTimer_InterruptHandler + 0x600000

; Program-ROM fixed entry stubs the bootloader jumps to once the program ROM
; is mapped (cross-ROM).  Each is a 4-byte `jp` at the same address in v7, v9
; and v10 (targets differ per version; v10 shown, read from the dumps):
.equ PROGRAM_ROM_ENTRY_HDAE5000, 0x00FFFED8	; v10: jp HDAE5000_Init_DetectAndVerify (0xEF4B54)
.equ PROGRAM_ROM_ENTRY_BOOT, 0x00FFFEDC	; v10: jp Boot_InitIOPorts (0xEF050F)

; =============================================================================
; Constants for shared boot routines
; =============================================================================
.equ REGION_CODE_VAR, 0xC06	; RAM address for region code
.equ BOOT_ENTRY_POINT, Boot_Init	; Entry point for watchdog reset

	; Section directory + preset data banks (0x800000 - 0x82FFFF): the
	; 34-entry directory (SectionDirectory_Table) and all 27 in-half preset
	; data banks are fully source-level in preset_banks.s -- see that
	; module's header for the directory semantics, per-section record grids
	; and the fill-pattern legend.  (includes/initial_data.bin is no longer
	; referenced by the LLVM build; the file stays on disk because the
	; archived ASL mirror still bincludes it in full.)
	; Since 2026-09-25 that header shows the "banks" are bitmaps, emitted
	; from v10/maincpu/images/.
	.org 0x800000 - 0x800000, 0xFF
	.include "preset_banks.s"

	; Tone database (0x830000 - 0x87FFEF): shipped to SubCPU RAM 0x50000 at
	; boot via five InterCPU E1 bulk transfers (see maincpu SubCPU_Send_Payload).
	.include "tone_database_directory.s"	; 0x830000-0x8324D3 directory, program maps, offset table
	.include "tone_database_records.s"	; 0x8324D4-0x855A47 579 tone/voice records
	.include "tone_database_aux.s"		; 0x855A48-0x87FFEF drum kits, percussion, name lists, env data

	.org 0x87FFF0 - 0x800000, 0xFF

; The filename field below does double duty as a version stamp: the maincpu
; boot routine Boot_ParseSubCPUTimestamp points ParseInt16 at 0x87FFF5 -- the
; "55" inside "hkst_55.ssf" -- so the digits embedded in this filename are
; also the table-data revision number that boot parses.
; Cross-ref: v10/maincpu/kn5000_v10_program.s (Boot_ParseSubCPUTimestamp),
; same in v9; v7 predates the check.
;
; Record layout (28 bytes, 0x87FFF0-0x88000B) as its readers use it (v10):
;   +0x00  "hkst_55.ssf",0   digits at +0x05 parsed by Boot_ParseSubCPUTimestamp
;                            (0xEF07E6)
;   +0x0C  .long 0           } neither field is read by the routines listed
;   +0x10  .long -> HKstSSF_Padding (two zero bytes) } here
;   +0x14  .long -> Feature_Demo_XML: Seq_CopyResourcePtrs (0xF862B5) handles
;          demo number 18 only -- it loads (0x880000 + 12*(n-18) + 4), i.e.
;          this field, and stores it at RAM 0x0249CC/0x0249D4 as the SSF
;          script position (any other n takes the pointer at RAM 0x0249D0)
;   +0x18  .long -> FeatureDemo_FileEntry1: FDemo_LinkedListSearch (0xF8682F)
;          starts its bitmap-name search with `ld xiz, (0x880008)`
; A v10 search for 0x87FFxx/0x8800xx constants finds only those three
; readers.  Demo number 18 is also the Feature Demo's preset slot
; (DemoSongPreset18 at 0x8E0000).
FeatureDemo_FileMetadata:
	.asciz "hkst_55.ssf"	; Filename for the feature demo SSF file
	.long 0x0
	.long HKstSSF_Padding
	.long Feature_Demo_XML
	.long FeatureDemo_FileEntry1

HKstSSF_Padding:
	.short 0x0

; Feature-demo slideshow script in the XML-like SSF "ACTION" format: 27
; sequential steps, each showing one display object.  The ftdemoNN objects
; are the slide images (drawn from the Feature_Bitmap_1..6 BMPs below);
; "Accordion", "Drawbar" and "Sdmixer" bring up live UI widget pages between
; slides.  Object/widget vocabulary is tracked by issue kn5000-x13.
; The ROM bytes are one unbroken ASCII run with no line terminators; the
; .ascii lines below are split per ACT for readability only and emit
; identical bytes.  includes/hkst_55.ssf stays on disk because the archived
; ASL mirror still bincludes it.
Feature_Demo_XML:
	.ascii "<ACTION>"
	.ascii "<ACT NO=1><SHOW OBJ=\"ftdemo01\"></ACT>"
	.ascii "<ACT NO=2><SHOW OBJ=\"ftdemo04\"></ACT>"
	.ascii "<ACT NO=3><SHOW OBJ=\"ftdemo05\"></ACT>"
	.ascii "<ACT NO=4><SHOW OBJ=\"ftdemo41\"></ACT>"
	.ascii "<ACT NO=5><SHOW OBJ=\"ftdemo42\"></ACT>"
	.ascii "<ACT NO=6><SHOW OBJ=\"ftdemo43\"></ACT>"
	.ascii "<ACT NO=7><SHOW OBJ=\"ftdemo44\"></ACT>"
	.ascii "<ACT NO=8><SHOW OBJ=\"ftdemo45\"></ACT>"
	.ascii "<ACT NO=9><SHOW OBJ=\"ftdemo46\"></ACT>"
	.ascii "<ACT NO=10><SHOW OBJ=\"ftdemo47\"></ACT>"
	.ascii "<ACT NO=11><SHOW OBJ=\"ftdemo48\"></ACT>"
	.ascii "<ACT NO=12><SHOW OBJ=\"ftdemo06\"></ACT>"
	.ascii "<ACT NO=13><SHOW OBJ=\"ftdemo07\"></ACT>"
	.ascii "<ACT NO=14><SHOW OBJ=\"ftdemo08\"></ACT>"
	.ascii "<ACT NO=15><SHOW OBJ=\"ftdemo09\"></ACT>"
	.ascii "<ACT NO=16><SHOW OBJ=\"Accordion\"></ACT>"
	.ascii "<ACT NO=17><SHOW OBJ=\"Accordion\"></ACT>"
	.ascii "<ACT NO=18><SHOW OBJ=\"ftdemo10\"></ACT>"
	.ascii "<ACT NO=19><SHOW OBJ=\"Drawbar\"></ACT>"
	.ascii "<ACT NO=20><SHOW OBJ=\"Drawbar\"></ACT>"
	.ascii "<ACT NO=21><SHOW OBJ=\"ftdemo20\"></ACT>"
	.ascii "<ACT NO=22><SHOW OBJ=\"ftdemo21\"></ACT>"
	.ascii "<ACT NO=23><SHOW OBJ=\"ftdemo22\"></ACT>"
	.ascii "<ACT NO=24><SHOW OBJ=\"ftdemo23\"></ACT>"
	.ascii "<ACT NO=25><SHOW OBJ=\"Sdmixer\"></ACT>"
	.ascii "<ACT NO=26><SHOW OBJ=\"ftdemo24\"></ACT>"
	.ascii "<ACT NO=27><SHOW OBJ=\"ftdemo25\"></ACT>"
	.ascii "</ACTION>"
	.byte 0x00

; Feature-demo slide images: standard Windows 3.x BMP files (8bpp indexed,
; 256-color palette, 320 px wide), stored verbatim; the sizes and addresses
; are echoed by the FeatureDemo_FileEntry records below.
; What the firmware checks (DrawBitmapFile_Impl, 0xFAC6F3): "BM" against the
; string at 0xEAADF2, biSize == 40, biPlanes == 1, biBitCount <= 8,
; biClrUsed <= 256 and bfOffBits - 54 <= 1024; it then copies the palette
; from file offset 54.  FDemoText_RenderTextLine (0xF85F8C) also reads
; biWidth (file offset 18) to lay out text around a slide.  All six pass.
	.org 0x880418 - 0x800000, 0xFF
; FTBMP01.BMP, 320x240 8bpp, 256-colour palette, 77,878 B: the "Technics" wordmark over a world-map globe.
; FeatureDemo_FileEntry1 names it; VwUserBitmapByNameProc (0xF9C5FC) appends
; ".BMP" to a widget's key "FTBMP01", FDemo_LinkedListLookupField (0xF868EF)
; returns this address and DrawBitmapFile (0xFAC697) draws it.
Feature_Bitmap_1:	.incbin "images/FTBMP01.BMP"

	.org 0x89344E - 0x800000, 0xFF
; FTBMP02.BMP, 320x130 8bpp, 256-colour palette, 42,678 B: the keyboard seen from above with coloured rings
; marking its speaker positions.
; FeatureDemo_FileEntry2 names it; VwUserBitmapByNameProc (0xF9C5FC) appends
; ".BMP" to a widget's key "FTBMP02", FDemo_LinkedListLookupField (0xF868EF)
; returns this address and DrawBitmapFile (0xFAC697) draws it.
Feature_Bitmap_2:	.incbin "images/FTBMP02.BMP"

	.org 0x89DB04 - 0x800000, 0xFF
; FTBMP03.BMP, 320x120 8bpp, 256-colour palette, 39,478 B: a fan of floppy disks.
; FeatureDemo_FileEntry3 names it; VwUserBitmapByNameProc (0xF9C5FC) appends
; ".BMP" to a widget's key "FTBMP03", FDemo_LinkedListLookupField (0xF868EF)
; returns this address and DrawBitmapFile (0xFAC697) draws it.
Feature_Bitmap_3:	.incbin "images/FTBMP03.BMP"

	.org 0x8A753A - 0x800000, 0xFF
; FTBMP04.BMP, 320x120 8bpp, 256-colour palette, 39,478 B: floppy disks going into the keyboard's disk drive.
; FeatureDemo_FileEntry4 names it; VwUserBitmapByNameProc (0xF9C5FC) appends
; ".BMP" to a widget's key "FTBMP04", FDemo_LinkedListLookupField (0xF868EF)
; returns this address and DrawBitmapFile (0xFAC697) draws it.
Feature_Bitmap_4:	.incbin "images/FTBMP04.BMP"

	.org 0x8B0F70 - 0x800000, 0xFF
; FTBMP05.BMP, 320x125 8bpp, 256-colour palette, 41,078 B: the keyboard circled by two curved arrows.
; FeatureDemo_FileEntry5 names it; VwUserBitmapByNameProc (0xF9C5FC) appends
; ".BMP" to a widget's key "FTBMP05", FDemo_LinkedListLookupField (0xF868EF)
; returns this address and DrawBitmapFile (0xFAC697) draws it.
Feature_Bitmap_5:	.incbin "images/FTBMP05.BMP"

	.org 0x8BAFE6 - 0x800000, 0xFF
; FTBMP06.BMP, 320x240 8bpp, 256-colour palette, 77,878 B: "KN5000" and a rainbow comet over a starfield.
; FeatureDemo_FileEntry6 names it; VwUserBitmapByNameProc (0xF9C5FC) appends
; ".BMP" to a widget's key "FTBMP06", FDemo_LinkedListLookupField (0xF868EF)
; returns this address and DrawBitmapFile (0xFAC697) draws it.
Feature_Bitmap_6:	.incbin "images/FTBMP06.BMP"


	.org 0x8CE01C - 0x800000, 0xFF

; Feature-demo bitmap file list: 24-byte records walked by
; FDemo_LinkedListSearch (0xF8682F) from the pointer at 0x880008:
;   +0x00  12-byte NUL-padded name, compared with Strcmp
;   +0x0C  .long 0 (not read by the search)
;   +0x10  .long data pointer; 0 ends the list (the 24 zero bytes after
;          entry 6 are that terminator)
;   +0x14  .long size in bytes (equals each BMP's own bfSize field)
; FDemo_LinkedListLookupField (0xF868EF) returns +0x10 of the match.
FeatureDemo_FileEntry1:
	.asciz "FTBMP01.BMP"
	.long 0x0
	.long Feature_Bitmap_1
	.long 77878	; Actual BMP file size

FeatureDemo_FileEntry2:
	.asciz "FTBMP02.BMP"
	.long 0x0
	.long Feature_Bitmap_2
	.long 42678	; Actual BMP file size

FeatureDemo_FileEntry3:
	.asciz "FTBMP03.BMP"
	.long 0x0
	.long Feature_Bitmap_3
	.long 39478	; Actual BMP file size

FeatureDemo_FileEntry4:
	.asciz "FTBMP04.BMP"
	.long 0x0
	.long Feature_Bitmap_4
	.long 39478	; Actual BMP file size

FeatureDemo_FileEntry5:
	.asciz "FTBMP05.BMP"
	.long 0x0
	.long Feature_Bitmap_5
	.long 41078	; Actual BMP file size

FeatureDemo_FileEntry6:
	.asciz "FTBMP06.BMP"
	.long 0x0
	.long Feature_Bitmap_6
	.long 77878	; Actual BMP file size

	.zero 30

	; Unused ROM space:
	.fill 32768, 1, 0xff
	.fill 32768, 1, 0xff
	.fill 7990, 1, 0xff


	.org 0x8E0000 - 0x800000, 0xFF

Compressed_Preset_Data_LZSS:
	; LZSS-compressed data (SLIDE4K format)
	; Decompresses to 38,144 bytes of parameter-like data (MIDI-range values 0-127).
	; This does NOT appear to be the SubCPU executable (~192KB).
	;
	; NOTE: The SubCPU executable payload transfer during boot is complex:
	; - Memory map reconfiguration changes address visibility between boot stages
	; - SubCPU_Send_Payload references multiple source addresses (0x830000, 0x3E0000)
	; - The payload may come from different addresses in Stage 1 vs Stage 2 boot
	; - Further analysis needed to trace the full SubCPU payload transfer path
	;
	; Referenced by SLIDE_Parse_Header in maincpu via SubCPU_Send_Payload.
	; If decompression fails, firmware falls back to data at 0x830000.
	;
	; CORRECTED 2026-09-25: the two lines above do not hold for this block.
	; LABEL_EF41E3 is now SLIDE_Parse_Header (v10 0xEF41E3), and
	; SubCPU_Send_Payload (v10 kn5000_v10_program.s) calls it on 0x3E0000
	; (custom-data flash), falling back to xiz = 0x800000 -- neither is
	; 0x8E0000.  This block's reader is DemoSongPreset_PointerTable[18]
	; (0x9C4048): Demo_ParseSlideHeader (0xF87189) passes it to
	; SLIDE_Parse_Header with destination RAM 0x69800, like demo songs 0-17.
	; The decompressed image starts "ZZZZ" like theirs (demo song format; see
	; includes/demo_presets/README.md), and Seq_CopyResourcePtrs (0xF862B5)
	; pairs demo number 18 with the Feature Demo script (hkst_55.ssf).
	;
	; Files:
	;   includes/demo_presets/demo_preset_18.bin            - decompressed source (38,144 bytes)
	;   includes/demo_presets/demo_preset_18_compressed.bin - LZSS payload (27,956 bytes)
	;
	; The header is 11 bytes: 8-byte "SLIDE4K\0" magic + 24-bit BIG-ENDIAN uncompressed
	; size (evidence: the v142 SubCPU update image's size field 03 00 00 = 0x030000 = 196,608).
	; It used to be written here as 14 literal bytes ending 0x7D, 0x5A, 0xEE -- but those
	; three bytes are the first flag byte and first two payload bytes of the LZSS stream,
	; not header fields. Verified against the firmware's own decompressor running in MAME.
	;
	; Tools:
	;   Decompress: make decompress-demo-presets
	;   Compress:   make rebuild-demo-presets (byte-identical, via --reference)
DemoSongPreset18:
	.asciz "SLIDE4K"
	.byte 0x00, 0x95, 0x00	; uncompressed size = 38144 bytes
	.incbin "includes/demo_presets/demo_preset_18_compressed.bin"

	; Unused space after compressed data
	.fill 25281, 1, 0xff


; =============================================================================
; PRESET WALLPAPERS
; =============================================================================
; These 320x240 8bpp wallpaper images are referenced by the SetWallPaper
; routine in the Main CPU ROM via the wallpaper table at 0xEAAE62.
; Each wallpaper is 76,800 bytes (320 * 240).
;
; Readers, precisely (v10): the table at 0xEAAE62 holds five 10-byte records
; {+0 pixel pointer, +4 palette pointer, +8 zero word}; records 0 and 1 are
; {Wallpaper_0, 0x8FFC00} and {Wallpaper_1, 0x912C00}, i.e. each image and
; the 1 KB trailer that follows it (records 2-4 point into custom-data flash
; 0x3C0000 and RAM).  SetWallPaper (0xF9A9EF) jumps to ChangeWall;
; ChangeWall_Impl (0xFAF237) stores record+0 at RAM 0x03EF98 and 0x030452,
; and DrawWall (0xFABB73) copies 2 x 0x9600 bytes from (0x030452) to the
; offscreen buffer at 0x43C00.  ChangePalette_Impl (0xFAF2F3) reads
; record+4 and copies trailer entries 0x20-0xDF (4 bytes each) into the RAM
; palette at 0x324FC via SetPaletteRGB (0xFB2895); VGA_WritePaletteEntry
; (0xFB31AB) later sends entry bytes +0, +1, +2 to the DAC data port 0x3C9
; in that order -- so the trailer entries are {red, green, blue, 0}.
; Every pixel of both images is in 0xE0-0xEF (a 16-shade ramp), matching the
; only non-zero entries of Wallpaper_0's trailer (+0x380-+0x3BF).
; =============================================================================

	.org 0x8ED000 - 0x800000, 0xFF
; Wallpaper record 0 (0xEAAE62): 320 x 240 x 8bpp, row-major, pixel values
; 0xE0-0xEF only; drawn by DrawWall (0xFABB73) after ChangeWall_Impl
; (0xFAF237) selects it.  Source: images/Wallpaper_0.bin (+ .png).
Wallpaper_0:	; Blue textured pattern
	.incbin "images/Wallpaper_0.bin"

	; Wallpaper_0 trailer (0x8FFC00 - 0x8FFFFF, formerly includes/
	; wallpaper_gap.bin -- the file stays on disk for the archived ASL
	; mirror).  Like Wallpaper_1's trailer (see ui_bitmaps.s), the +0x380
	; slot holds a 16-entry shade ramp of ascending {r, g, b, 0x00}
	; quadruplets; this one matches WallpaperRamp_Navy.  No code reference
	; found yet, so the RGB interpretation is tentative.
	; CORRECTED 2026-09-25: the sentence above is superseded.  This
	; trailer is the 256 x 4-byte palette that wallpaper record 0
	; (0xEAAE62+4) points at; see the PRESET WALLPAPERS banner for
	; ChangePalette_Impl and the DAC byte order.
	; Only entries 0xE0-0xEF (this ramp) are non-zero, and the image uses
	; exactly those pixel values.  The routine that loads entries 0xE0-0xEF
	; for a wallpaper (ChangeWallPalette_Impl, via the RAM table at 0x3F1E4)
	; was not traced to this slot.
	.zero 896
Wallpaper0_ShadeRamp:
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
	.zero 64

	.org 0x900000 - 0x800000, 0xFF
; Wallpaper record 1 (0xEAAE6C): 320 x 240 x 8bpp, row-major, pixel values
; 0xE0-0xEF only; drawn by DrawWall (0xFABB73) after ChangeWall_Impl
; (0xFAF237) selects it; its palette trailer follows (see ui_bitmaps.s).
; Source: images/Wallpaper_1.bin (+ .png).
Wallpaper_1:	; Technics branded texture
	.incbin "images/Wallpaper_1.bin"

	; Wallpaper_1 trailer, UI bitmap/frame descriptor tables and pixel
	; runs, and factory image banks (0x912C00 - 0x937FFF)
	.include "ui_bitmaps.s"


; =============================================================================
; UI ICONS
; =============================================================================
; These icons are used in menus and UI elements. Referenced by the
; DrawIcons routine at 0xFABF9B in Main CPU ROM.
; (In v10 0xFABF9B is DrawIcons_Impl, reached through DrawIcons at 0xFABF3F;
; it loads 0x938000 and indexes it by icon number * 8.)
;
; Format: ALL 176 icons are 24x24 pixels @ 4bpp (16 colors), 288 bytes each
;   - 2 pixels per byte: high nibble = first pixel, low nibble = second
;   - DrawIcons has hardcoded loops: 12 bytes/row × 24 rows
;
; Icon table format (8 bytes per entry):
;   Bytes 0-1: Bounding box width (for UI hit-testing, NOT pixel width)
;   Bytes 2-3: Bounding box height (for UI hit-testing, NOT pixel height)
;   Bytes 4-7: Pointer to pixel data (absolute address)
;
; Note: Icons 173-175 have larger bounding boxes (27x27 or 28x28) but still
;       use standard 24x24 pixel data - the dims field is for UI purposes only.
;
; Color Palette (16 colors, CGA/EGA-style):
;   The color lookup table at 0xEAABF2 (Main CPU ROM) expands 4-bit nibbles
;   to 8-bit palette indices, which reference the main palette at 0xEB37DE:
;
;   Nibble  Palette Index  Color           RGB
;   ------  -------------  --------------  ---------------
;      0       0x00        Black           (0, 0, 0)
;      1       0x01        Dark Red        (128, 0, 0)
;      2       0x02        Dark Green      (0, 128, 0)
;      3       0x03        Olive           (128, 128, 0)
;      4       0x04        Dark Blue       (0, 0, 128)
;      5       0x05        Dark Magenta    (128, 0, 128)
;      6       0x06        Dark Cyan       (0, 128, 128)
;      7       0x07        Light Gray      (136, 136, 136)  <- background
;      8       0xF8        Dark Gray       (96, 96, 96)
;      9       0xF9        Bright Red      (255, 0, 0)
;     10       0xFA        Bright Green    (0, 255, 0)
;     11       0xFB        Yellow          (255, 255, 0)
;     12       0xFC        Bright Blue     (0, 0, 255)
;     13       0xFD        Magenta         (255, 0, 255)
;     14       0xFE        Cyan            (0, 255, 255)
;     15       0xFF        White           (255, 255, 255)
;
; See scripts/analysis/extract_icons.py for the extraction tool.
; =============================================================================

	.org 0x938000 - 0x800000, 0xFF
; The icon descriptor table was formerly includes/icon_table.bin (the file
; stays on disk for the archived ASL mirror; the LLVM build no longer uses it).
; Indexed by the icon number passed to DrawIcons.  The bounding-box fields are
; UI hit-test dimensions -- pixel data is always 24x24 @ 4bpp (288 bytes).
IconTable:
Icon_000:	desc_entry	24, 24, IconPixels_000
Icon_001:	desc_entry	24, 24, IconPixels_001
Icon_002:	desc_entry	24, 24, IconPixels_002
Icon_003:	desc_entry	24, 24, IconPixels_003
Icon_004:	desc_entry	24, 24, IconPixels_004
Icon_005:	desc_entry	24, 24, IconPixels_005
Icon_006:	desc_entry	24, 24, IconPixels_006
Icon_007:	desc_entry	24, 24, IconPixels_007
Icon_008:	desc_entry	24, 24, IconPixels_008
Icon_009:	desc_entry	24, 24, IconPixels_009
Icon_010:	desc_entry	24, 24, IconPixels_010
Icon_011:	desc_entry	24, 24, IconPixels_011
Icon_012:	desc_entry	24, 24, IconPixels_012
Icon_013:	desc_entry	24, 24, IconPixels_013
Icon_014:	desc_entry	24, 24, IconPixels_014
Icon_015:	desc_entry	24, 24, IconPixels_015
Icon_016:	desc_entry	24, 24, IconPixels_016
Icon_017:	desc_entry	24, 24, IconPixels_017
Icon_018:	desc_entry	24, 24, IconPixels_018
Icon_019:	desc_entry	24, 24, IconPixels_019
Icon_020:	desc_entry	24, 24, IconPixels_020
Icon_021:	desc_entry	24, 24, IconPixels_021
Icon_022:	desc_entry	24, 24, IconPixels_022
Icon_023:	desc_entry	24, 24, IconPixels_023
Icon_024:	desc_entry	24, 24, IconPixels_024
Icon_025:	desc_entry	24, 24, IconPixels_025
Icon_026:	desc_entry	24, 24, IconPixels_026
Icon_027:	desc_entry	24, 24, IconPixels_027
Icon_028:	desc_entry	24, 24, IconPixels_028
Icon_029:	desc_entry	24, 24, IconPixels_029
Icon_030:	desc_entry	24, 24, IconPixels_030
Icon_031:	desc_entry	24, 24, IconPixels_031
Icon_032:	desc_entry	24, 24, IconPixels_032
Icon_033:	desc_entry	24, 24, IconPixels_033
Icon_034:	desc_entry	24, 24, IconPixels_034
Icon_035:	desc_entry	24, 24, IconPixels_035
Icon_036:	desc_entry	24, 24, IconPixels_036
Icon_037:	desc_entry	24, 24, IconPixels_037
Icon_038:	desc_entry	24, 24, IconPixels_038
Icon_039:	desc_entry	24, 24, IconPixels_039
Icon_040:	desc_entry	24, 24, IconPixels_040
Icon_041:	desc_entry	24, 24, IconPixels_041
Icon_042:	desc_entry	24, 24, IconPixels_042
Icon_043:	desc_entry	24, 24, IconPixels_043
Icon_044:	desc_entry	24, 24, IconPixels_044
Icon_045:	desc_entry	24, 24, IconPixels_045
Icon_046:	desc_entry	24, 24, IconPixels_046
Icon_047:	desc_entry	24, 24, IconPixels_047
Icon_048:	desc_entry	24, 24, IconPixels_048
Icon_049:	desc_entry	24, 24, IconPixels_049
Icon_050:	desc_entry	24, 24, IconPixels_050
Icon_051:	desc_entry	24, 24, IconPixels_051
Icon_052:	desc_entry	24, 24, IconPixels_052
Icon_053:	desc_entry	24, 24, IconPixels_053
Icon_054:	desc_entry	24, 24, IconPixels_054
Icon_055:	desc_entry	24, 24, IconPixels_055
Icon_056:	desc_entry	24, 24, IconPixels_056
Icon_057:	desc_entry	24, 24, IconPixels_057
Icon_058:	desc_entry	24, 24, IconPixels_058
Icon_059:	desc_entry	24, 24, IconPixels_059
Icon_060:	desc_entry	24, 24, IconPixels_060
Icon_061:	desc_entry	24, 24, IconPixels_061
Icon_062:	desc_entry	24, 24, IconPixels_062
Icon_063:	desc_entry	24, 24, IconPixels_063
Icon_064:	desc_entry	24, 24, IconPixels_064
Icon_065:	desc_entry	24, 24, IconPixels_065
Icon_066:	desc_entry	24, 24, IconPixels_066
Icon_067:	desc_entry	24, 24, IconPixels_067
Icon_068:	desc_entry	24, 24, IconPixels_068
Icon_069:	desc_entry	24, 24, IconPixels_069
Icon_070:	desc_entry	24, 24, IconPixels_070
Icon_071:	desc_entry	24, 24, IconPixels_071
Icon_072:	desc_entry	24, 24, IconPixels_072
Icon_073:	desc_entry	24, 24, IconPixels_073
Icon_074:	desc_entry	24, 24, IconPixels_074
Icon_075:	desc_entry	24, 24, IconPixels_075
Icon_076:	desc_entry	24, 24, IconPixels_076
Icon_077:	desc_entry	24, 24, IconPixels_077
Icon_078:	desc_entry	24, 24, IconPixels_078
Icon_079:	desc_entry	24, 24, IconPixels_079
Icon_080:	desc_entry	24, 24, IconPixels_080
Icon_081:	desc_entry	24, 24, IconPixels_081
Icon_082:	desc_entry	24, 24, IconPixels_082
Icon_083:	desc_entry	24, 24, IconPixels_083
Icon_084:	desc_entry	24, 24, IconPixels_084
Icon_085:	desc_entry	24, 24, IconPixels_085
Icon_086:	desc_entry	24, 24, IconPixels_086
Icon_087:	desc_entry	24, 24, IconPixels_087
Icon_088:	desc_entry	24, 24, IconPixels_088
Icon_089:	desc_entry	24, 24, IconPixels_089
Icon_090:	desc_entry	24, 24, IconPixels_090
Icon_091:	desc_entry	24, 24, IconPixels_091
Icon_092:	desc_entry	24, 24, IconPixels_092
Icon_093:	desc_entry	24, 24, IconPixels_093
Icon_094:	desc_entry	24, 24, IconPixels_094
Icon_095:	desc_entry	24, 24, IconPixels_095
Icon_096:	desc_entry	24, 24, IconPixels_096
Icon_097:	desc_entry	24, 24, IconPixels_097
Icon_098:	desc_entry	24, 24, IconPixels_098
Icon_099:	desc_entry	24, 24, IconPixels_099
Icon_100:	desc_entry	24, 24, IconPixels_100
Icon_101:	desc_entry	24, 24, IconPixels_101
Icon_102:	desc_entry	24, 24, IconPixels_102
Icon_103:	desc_entry	24, 24, IconPixels_103
Icon_104:	desc_entry	24, 24, IconPixels_104
Icon_105:	desc_entry	24, 24, IconPixels_105
Icon_106:	desc_entry	24, 24, IconPixels_106
Icon_107:	desc_entry	24, 24, IconPixels_107
Icon_108:	desc_entry	24, 24, IconPixels_108
Icon_109:	desc_entry	24, 24, IconPixels_109
Icon_110:	desc_entry	24, 24, IconPixels_110
Icon_111:	desc_entry	24, 24, IconPixels_111
Icon_112:	desc_entry	24, 24, IconPixels_112
Icon_113:	desc_entry	24, 24, IconPixels_113
Icon_114:	desc_entry	24, 24, IconPixels_114
Icon_115:	desc_entry	24, 24, IconPixels_115
Icon_116:	desc_entry	24, 24, IconPixels_116
Icon_117:	desc_entry	24, 24, IconPixels_117
Icon_118:	desc_entry	24, 24, IconPixels_118
Icon_119:	desc_entry	24, 24, IconPixels_119
Icon_120:	desc_entry	24, 24, IconPixels_120
Icon_121:	desc_entry	24, 24, IconPixels_121
Icon_122:	desc_entry	24, 24, IconPixels_122
Icon_123:	desc_entry	24, 24, IconPixels_123
Icon_124:	desc_entry	24, 24, IconPixels_124
Icon_125:	desc_entry	24, 24, IconPixels_125
Icon_126:	desc_entry	24, 24, IconPixels_126
Icon_127:	desc_entry	24, 24, IconPixels_127
Icon_128:	desc_entry	24, 24, IconPixels_128
Icon_129:	desc_entry	24, 24, IconPixels_129
Icon_130:	desc_entry	24, 24, IconPixels_130
Icon_131:	desc_entry	24, 24, IconPixels_131
Icon_132:	desc_entry	24, 24, IconPixels_132
Icon_133:	desc_entry	24, 24, IconPixels_133
Icon_134:	desc_entry	24, 24, IconPixels_134
Icon_135:	desc_entry	24, 24, IconPixels_135
Icon_136:	desc_entry	24, 24, IconPixels_136
Icon_137:	desc_entry	24, 24, IconPixels_137
Icon_138:	desc_entry	24, 24, IconPixels_138
Icon_139:	desc_entry	24, 24, IconPixels_139
Icon_140:	desc_entry	24, 24, IconPixels_140
Icon_141:	desc_entry	24, 24, IconPixels_141
Icon_142:	desc_entry	24, 24, IconPixels_142
Icon_143:	desc_entry	24, 24, IconPixels_143
Icon_144:	desc_entry	24, 24, IconPixels_144
Icon_145:	desc_entry	24, 24, IconPixels_145
Icon_146:	desc_entry	24, 24, IconPixels_146
Icon_147:	desc_entry	24, 24, IconPixels_147
Icon_148:	desc_entry	24, 24, IconPixels_148
Icon_149:	desc_entry	24, 24, IconPixels_149
Icon_150:	desc_entry	24, 24, IconPixels_150
Icon_151:	desc_entry	24, 24, IconPixels_151
Icon_152:	desc_entry	24, 24, IconPixels_152
Icon_153:	desc_entry	24, 24, IconPixels_153
Icon_154:	desc_entry	24, 24, IconPixels_154
Icon_155:	desc_entry	24, 24, IconPixels_155
Icon_156:	desc_entry	24, 24, IconPixels_156
Icon_157:	desc_entry	24, 24, IconPixels_157
Icon_158:	desc_entry	24, 24, IconPixels_158
Icon_159:	desc_entry	24, 24, IconPixels_159
Icon_160:	desc_entry	24, 24, IconPixels_160
Icon_161:	desc_entry	24, 24, IconPixels_161
Icon_162:	desc_entry	24, 24, IconPixels_162
Icon_163:	desc_entry	24, 24, IconPixels_163
Icon_164:	desc_entry	24, 24, IconPixels_164
Icon_165:	desc_entry	24, 24, IconPixels_165
Icon_166:	desc_entry	24, 24, IconPixels_166
Icon_167:	desc_entry	24, 24, IconPixels_167
Icon_168:	desc_entry	24, 24, IconPixels_168
Icon_169:	desc_entry	24, 24, IconPixels_169
Icon_170:	desc_entry	24, 24, IconPixels_170
Icon_171:	desc_entry	24, 24, IconPixels_171
Icon_172:	desc_entry	24, 24, IconPixels_172
Icon_173:	desc_entry	27, 27, IconPixels_173
Icon_174:	desc_entry	27, 27, IconPixels_174
Icon_175:	desc_entry	28, 28, IconPixels_175
	desc_entry	0, 0, 0		; terminator

; Icon pixel data: 4bpp, 2 pixels/byte, 12 bytes/row x 24 rows (288 bytes per
; icon; DrawIcons hardcodes the geometry).  Emitted as offset/length slices of
; includes/icon_pixel_data.bin so each icon is individually addressable.
; Extracted gallery: table_data/images/icons/Icon_NNN.png.
; DrawIcons_Impl (v10 0xFABF9B) reaches each run through the +4 pointer of
; its IconTable entry.
IconPixels_000:	.incbin "includes/generated/IconPixels_000.bin"
IconPixels_001:	.incbin "includes/generated/IconPixels_001.bin"
IconPixels_002:	.incbin "includes/generated/IconPixels_002.bin"
IconPixels_003:	.incbin "includes/generated/IconPixels_003.bin"
IconPixels_004:	.incbin "includes/generated/IconPixels_004.bin"
IconPixels_005:	.incbin "includes/generated/IconPixels_005.bin"
IconPixels_006:	.incbin "includes/generated/IconPixels_006.bin"
IconPixels_007:	.incbin "includes/generated/IconPixels_007.bin"
IconPixels_008:	.incbin "includes/generated/IconPixels_008.bin"
IconPixels_009:	.incbin "includes/generated/IconPixels_009.bin"
IconPixels_010:	.incbin "includes/generated/IconPixels_010.bin"
IconPixels_011:	.incbin "includes/generated/IconPixels_011.bin"
IconPixels_012:	.incbin "includes/generated/IconPixels_012.bin"
IconPixels_013:	.incbin "includes/generated/IconPixels_013.bin"
IconPixels_014:	.incbin "includes/generated/IconPixels_014.bin"
IconPixels_015:	.incbin "includes/generated/IconPixels_015.bin"
IconPixels_016:	.incbin "includes/generated/IconPixels_016.bin"
IconPixels_017:	.incbin "includes/generated/IconPixels_017.bin"
IconPixels_018:	.incbin "includes/generated/IconPixels_018.bin"
IconPixels_019:	.incbin "includes/generated/IconPixels_019.bin"
IconPixels_020:	.incbin "includes/generated/IconPixels_020.bin"
IconPixels_021:	.incbin "includes/generated/IconPixels_021.bin"
IconPixels_022:	.incbin "includes/generated/IconPixels_022.bin"
IconPixels_023:	.incbin "includes/generated/IconPixels_023.bin"
IconPixels_024:	.incbin "includes/generated/IconPixels_024.bin"
IconPixels_025:	.incbin "includes/generated/IconPixels_025.bin"
IconPixels_026:	.incbin "includes/generated/IconPixels_026.bin"
IconPixels_027:	.incbin "includes/generated/IconPixels_027.bin"
IconPixels_028:	.incbin "includes/generated/IconPixels_028.bin"
IconPixels_029:	.incbin "includes/generated/IconPixels_029.bin"
IconPixels_030:	.incbin "includes/generated/IconPixels_030.bin"
IconPixels_031:	.incbin "includes/generated/IconPixels_031.bin"
IconPixels_032:	.incbin "includes/generated/IconPixels_032.bin"
IconPixels_033:	.incbin "includes/generated/IconPixels_033.bin"
IconPixels_034:	.incbin "includes/generated/IconPixels_034.bin"
IconPixels_035:	.incbin "includes/generated/IconPixels_035.bin"
IconPixels_036:	.incbin "includes/generated/IconPixels_036.bin"
IconPixels_037:	.incbin "includes/generated/IconPixels_037.bin"
IconPixels_038:	.incbin "includes/generated/IconPixels_038.bin"
IconPixels_039:	.incbin "includes/generated/IconPixels_039.bin"
IconPixels_040:	.incbin "includes/generated/IconPixels_040.bin"
IconPixels_041:	.incbin "includes/generated/IconPixels_041.bin"
IconPixels_042:	.incbin "includes/generated/IconPixels_042.bin"
IconPixels_043:	.incbin "includes/generated/IconPixels_043.bin"
IconPixels_044:	.incbin "includes/generated/IconPixels_044.bin"
IconPixels_045:	.incbin "includes/generated/IconPixels_045.bin"
IconPixels_046:	.incbin "includes/generated/IconPixels_046.bin"
IconPixels_047:	.incbin "includes/generated/IconPixels_047.bin"
IconPixels_048:	.incbin "includes/generated/IconPixels_048.bin"
IconPixels_049:	.incbin "includes/generated/IconPixels_049.bin"
IconPixels_050:	.incbin "includes/generated/IconPixels_050.bin"
IconPixels_051:	.incbin "includes/generated/IconPixels_051.bin"
IconPixels_052:	.incbin "includes/generated/IconPixels_052.bin"
IconPixels_053:	.incbin "includes/generated/IconPixels_053.bin"
IconPixels_054:	.incbin "includes/generated/IconPixels_054.bin"
IconPixels_055:	.incbin "includes/generated/IconPixels_055.bin"
IconPixels_056:	.incbin "includes/generated/IconPixels_056.bin"
IconPixels_057:	.incbin "includes/generated/IconPixels_057.bin"
IconPixels_058:	.incbin "includes/generated/IconPixels_058.bin"
IconPixels_059:	.incbin "includes/generated/IconPixels_059.bin"
IconPixels_060:	.incbin "includes/generated/IconPixels_060.bin"
IconPixels_061:	.incbin "includes/generated/IconPixels_061.bin"
IconPixels_062:	.incbin "includes/generated/IconPixels_062.bin"
IconPixels_063:	.incbin "includes/generated/IconPixels_063.bin"
IconPixels_064:	.incbin "includes/generated/IconPixels_064.bin"
IconPixels_065:	.incbin "includes/generated/IconPixels_065.bin"
IconPixels_066:	.incbin "includes/generated/IconPixels_066.bin"
IconPixels_067:	.incbin "includes/generated/IconPixels_067.bin"
IconPixels_068:	.incbin "includes/generated/IconPixels_068.bin"
IconPixels_069:	.incbin "includes/generated/IconPixels_069.bin"
IconPixels_070:	.incbin "includes/generated/IconPixels_070.bin"
IconPixels_071:	.incbin "includes/generated/IconPixels_071.bin"
IconPixels_072:	.incbin "includes/generated/IconPixels_072.bin"
IconPixels_073:	.incbin "includes/generated/IconPixels_073.bin"
IconPixels_074:	.incbin "includes/generated/IconPixels_074.bin"
IconPixels_075:	.incbin "includes/generated/IconPixels_075.bin"
IconPixels_076:	.incbin "includes/generated/IconPixels_076.bin"
IconPixels_077:	.incbin "includes/generated/IconPixels_077.bin"
IconPixels_078:	.incbin "includes/generated/IconPixels_078.bin"
IconPixels_079:	.incbin "includes/generated/IconPixels_079.bin"
IconPixels_080:	.incbin "includes/generated/IconPixels_080.bin"
IconPixels_081:	.incbin "includes/generated/IconPixels_081.bin"
IconPixels_082:	.incbin "includes/generated/IconPixels_082.bin"
IconPixels_083:	.incbin "includes/generated/IconPixels_083.bin"
IconPixels_084:	.incbin "includes/generated/IconPixels_084.bin"
IconPixels_085:	.incbin "includes/generated/IconPixels_085.bin"
IconPixels_086:	.incbin "includes/generated/IconPixels_086.bin"
IconPixels_087:	.incbin "includes/generated/IconPixels_087.bin"
IconPixels_088:	.incbin "includes/generated/IconPixels_088.bin"
IconPixels_089:	.incbin "includes/generated/IconPixels_089.bin"
IconPixels_090:	.incbin "includes/generated/IconPixels_090.bin"
IconPixels_091:	.incbin "includes/generated/IconPixels_091.bin"
IconPixels_092:	.incbin "includes/generated/IconPixels_092.bin"
IconPixels_093:	.incbin "includes/generated/IconPixels_093.bin"
IconPixels_094:	.incbin "includes/generated/IconPixels_094.bin"
IconPixels_095:	.incbin "includes/generated/IconPixels_095.bin"
IconPixels_096:	.incbin "includes/generated/IconPixels_096.bin"
IconPixels_097:	.incbin "includes/generated/IconPixels_097.bin"
IconPixels_098:	.incbin "includes/generated/IconPixels_098.bin"
IconPixels_099:	.incbin "includes/generated/IconPixels_099.bin"
IconPixels_100:	.incbin "includes/generated/IconPixels_100.bin"
IconPixels_101:	.incbin "includes/generated/IconPixels_101.bin"
IconPixels_102:	.incbin "includes/generated/IconPixels_102.bin"
IconPixels_103:	.incbin "includes/generated/IconPixels_103.bin"
IconPixels_104:	.incbin "includes/generated/IconPixels_104.bin"
IconPixels_105:	.incbin "includes/generated/IconPixels_105.bin"
IconPixels_106:	.incbin "includes/generated/IconPixels_106.bin"
IconPixels_107:	.incbin "includes/generated/IconPixels_107.bin"
IconPixels_108:	.incbin "includes/generated/IconPixels_108.bin"
IconPixels_109:	.incbin "includes/generated/IconPixels_109.bin"
IconPixels_110:	.incbin "includes/generated/IconPixels_110.bin"
IconPixels_111:	.incbin "includes/generated/IconPixels_111.bin"
IconPixels_112:	.incbin "includes/generated/IconPixels_112.bin"
IconPixels_113:	.incbin "includes/generated/IconPixels_113.bin"
IconPixels_114:	.incbin "includes/generated/IconPixels_114.bin"
IconPixels_115:	.incbin "includes/generated/IconPixels_115.bin"
IconPixels_116:	.incbin "includes/generated/IconPixels_116.bin"
IconPixels_117:	.incbin "includes/generated/IconPixels_117.bin"
IconPixels_118:	.incbin "includes/generated/IconPixels_118.bin"
IconPixels_119:	.incbin "includes/generated/IconPixels_119.bin"
IconPixels_120:	.incbin "includes/generated/IconPixels_120.bin"
IconPixels_121:	.incbin "includes/generated/IconPixels_121.bin"
IconPixels_122:	.incbin "includes/generated/IconPixels_122.bin"
IconPixels_123:	.incbin "includes/generated/IconPixels_123.bin"
IconPixels_124:	.incbin "includes/generated/IconPixels_124.bin"
IconPixels_125:	.incbin "includes/generated/IconPixels_125.bin"
IconPixels_126:	.incbin "includes/generated/IconPixels_126.bin"
IconPixels_127:	.incbin "includes/generated/IconPixels_127.bin"
IconPixels_128:	.incbin "includes/generated/IconPixels_128.bin"
IconPixels_129:	.incbin "includes/generated/IconPixels_129.bin"
IconPixels_130:	.incbin "includes/generated/IconPixels_130.bin"
IconPixels_131:	.incbin "includes/generated/IconPixels_131.bin"
IconPixels_132:	.incbin "includes/generated/IconPixels_132.bin"
IconPixels_133:	.incbin "includes/generated/IconPixels_133.bin"
IconPixels_134:	.incbin "includes/generated/IconPixels_134.bin"
IconPixels_135:	.incbin "includes/generated/IconPixels_135.bin"
IconPixels_136:	.incbin "includes/generated/IconPixels_136.bin"
IconPixels_137:	.incbin "includes/generated/IconPixels_137.bin"
IconPixels_138:	.incbin "includes/generated/IconPixels_138.bin"
IconPixels_139:	.incbin "includes/generated/IconPixels_139.bin"
IconPixels_140:	.incbin "includes/generated/IconPixels_140.bin"
IconPixels_141:	.incbin "includes/generated/IconPixels_141.bin"
IconPixels_142:	.incbin "includes/generated/IconPixels_142.bin"
IconPixels_143:	.incbin "includes/generated/IconPixels_143.bin"
IconPixels_144:	.incbin "includes/generated/IconPixels_144.bin"
IconPixels_145:	.incbin "includes/generated/IconPixels_145.bin"
IconPixels_146:	.incbin "includes/generated/IconPixels_146.bin"
IconPixels_147:	.incbin "includes/generated/IconPixels_147.bin"
IconPixels_148:	.incbin "includes/generated/IconPixels_148.bin"
IconPixels_149:	.incbin "includes/generated/IconPixels_149.bin"
IconPixels_150:	.incbin "includes/generated/IconPixels_150.bin"
IconPixels_151:	.incbin "includes/generated/IconPixels_151.bin"
IconPixels_152:	.incbin "includes/generated/IconPixels_152.bin"
IconPixels_153:	.incbin "includes/generated/IconPixels_153.bin"
IconPixels_154:	.incbin "includes/generated/IconPixels_154.bin"
IconPixels_155:	.incbin "includes/generated/IconPixels_155.bin"
IconPixels_156:	.incbin "includes/generated/IconPixels_156.bin"
IconPixels_157:	.incbin "includes/generated/IconPixels_157.bin"
IconPixels_158:	.incbin "includes/generated/IconPixels_158.bin"
IconPixels_159:	.incbin "includes/generated/IconPixels_159.bin"
IconPixels_160:	.incbin "includes/generated/IconPixels_160.bin"
IconPixels_161:	.incbin "includes/generated/IconPixels_161.bin"
IconPixels_162:	.incbin "includes/generated/IconPixels_162.bin"
IconPixels_163:	.incbin "includes/generated/IconPixels_163.bin"
IconPixels_164:	.incbin "includes/generated/IconPixels_164.bin"
IconPixels_165:	.incbin "includes/generated/IconPixels_165.bin"
IconPixels_166:	.incbin "includes/generated/IconPixels_166.bin"
IconPixels_167:	.incbin "includes/generated/IconPixels_167.bin"
IconPixels_168:	.incbin "includes/generated/IconPixels_168.bin"
IconPixels_169:	.incbin "includes/generated/IconPixels_169.bin"
IconPixels_170:	.incbin "includes/generated/IconPixels_170.bin"
IconPixels_171:	.incbin "includes/generated/IconPixels_171.bin"
IconPixels_172:	.incbin "includes/generated/IconPixels_172.bin"
IconPixels_173:	.incbin "includes/generated/IconPixels_173.bin"
IconPixels_174:	.incbin "includes/generated/IconPixels_174.bin"
IconPixels_175:	.incbin "includes/generated/IconPixels_175.bin"
; A 177th icon sits after the last referenced icon: yellow "E.L.S." lettering
; with small glyphs below -- apparently a developer signature.  No IconTable
; entry points at it (entry 176 is the null terminator), so it is unreachable
; art.  Extracted to the gallery as Icon_176.png.
IconPixels_176_Unreferenced:	.incbin "includes/generated/IconPixels_176.bin"
	.fill 208, 1, 0xff	; pad to 0x944D78

; =============================================================================
; MIXED DATA TABLES (0x944D78 - 0x9F9FFF)
; =============================================================================
; This 753KB region contains multiple data structures referenced by the main
; CPU ROM. Key sub-regions:
;
;   0x944D78-0x950FFF  UI text fonts -- fully split out into fonts.s
;                       (descriptor table @0x945C00, ten 1bpp glyph banks
;                       covering chars 0x20-0xFF, Font5 kern table, and the
;                       0xFF fill on either side -- see that module's header)
;   0x951000-0x98156F  Music Stylist preset records -- fully split out into
;                       style_records.s (1000 x 198-byte StyleRec_NNN records:
;                       250 styles x 4 arrangements in 10 categories; see that
;                       module's header for the record layout and consumers)
;   0x981570-0x983B39  Unreferenced residue after the record grid (raw slice
;                       + labeled 16-bit ramp remnant, also in style_records.s)
;   0x983B3A-0x9999CB  HELP system + Music Stylist pointer tables -- fully
;                       split out into help_databases.s (stale truncated
;                       SLIDE8K remnant, StyleRec_PtrTable_C2C5/_Default in
;                       style_record_ptr_tables.s,
;                       HelpIntro_LanguageTable + HelpDB_LanguageTable at
;                       0x988000/0x988018, five intro strings, five live
;                       SLIDE8K help databases rebuilt from decompressed
;                       sources -- see that module's header)
;   0x9999CC-0x9999D2  Stray residue bytes after the Indonesian help DB
;   0x9999D3-0x99EBFF  Unused (0xFF fill)
;   0x99EC00-0x9ABF3F  Panel Memory factory data -- fully split out into
;                       panel_memory_presets.s: 10 bank names "Tour Of The
;                       5000".."World" plus 80 preset records (the old
;                       "Demo Category Names" reading of this region was
;                       wrong -- see that module's header)
;   0x9ABF40-0x9B3FFF  Unused (0xFF fill)
;   0x9B4000-0x9C3FFF  Composer factory user-style memory image, copied to
;                       RAM 0x94800 at boot (see Composer_FactoryMemoryImage)
;   0x9C4000-0x9C404F  Demo Song Preset Pointer Table (19 x 4-byte LE pointers + null)
;                       Accessed by main CPU: sla wa,2; add xwa,0x9C4000; ld xwa,(xwa)
;                       Each pointer -> SLIDE4K compressed preset data
;                       Entry 18 points to 0x8E0000 (Feature Demo, same as LZSS preset data)
;   0x9C4050-0x9F9FFF  SLIDE4K Compressed Demo Song Presets (entries 0-17, variable size)
; =============================================================================

; -----------------------------------------------------------------------------
; BACKING BLOB: includes/icons_to_strings.bin -- what is still live in it
; -----------------------------------------------------------------------------
; 742,024 bytes; sha256
;   0df126455434ccc35a9f40609ec26dc68edc2a170910de602a6fbe814f31379d
; The file is a verbatim slice of the factory dump covering exactly the region
; mapped above: file offset 0 = ROM 0x944D78, last byte = ROM 0x9F9FFF.  It
; predates the source conversion, so most of what it holds is now emitted from
; real source.
;
; ★ CORRECTED 2026-09-02: this comment used to list 13 sized .incbin slices
; (126,674 B, 17% of the file) as "still read from it" -- Font0..Font9 and
; Composer_FactoryMemoryImage.  That was stale: fonts.s has since moved to
; round-trip PNGs (includes/generated/Font*_Glyphs.bin) and
; Composer_FactoryMemoryImage below now .incbins includes/generated/
; Composer_FactoryMemoryImage.bin, rebuilt from custom_data/styles/.  Neither
; reads this blob's bytes at build time any more (style_events.py's EXTRA
; entry still reads it, but only to VERIFY the round trip, not to emit).
;
; Then style_records.s's StyleRecords_Residue and help_databases.s's
; HelpDB_German_Stale body (17,570 B total; see table_data_debt.py's
; 'stale-remnant' class) also stopped reading it, once scripts/generators/
; gen_stale_help_duplicate.py established they are the live English+German
; SLIDE8K streams duplicated 0x8000 lower and can be derived from those
; build products instead (see the module headers in style_records.s and
; help_databases.s).
;
; NET RESULT: as of 2026-09-02, `scripts/analysis/audit_icons_blob_coverage.py`
; reports ZERO live .incbin slices of this blob anywhere in table_data/.  The
; file is kept only as a verification reference (its sha256 above, and the
; EXTRA entry in style_events.py) -- see that script and
; `python3 scripts/analysis/table_data_debt.py` for the up-to-date accounting.
;
; ASL MIRROR: archive/asl/table_data/kn5000_table_data.asm bincludes the file
; as ONE 0x7F2D8-byte block (ROM 0x944D78-0x9C404F) and then ORGs to 0x9C4050,
; which is why the file may not be rewritten or re-sliced on disk.  The 80
; bytes at file 0x7F288-0x7F2D7 (ROM 0x9C4000-0x9C404F) are the only ones the
; mirror still takes from the blob while this build emits them from source:
; they are DemoSongPreset_PointerTable's 19 pointers plus its null terminator.
;
; DEAD TAIL: file 0x7F2D8-0xB5287 (221,104 B = ROM 0x9C4050-0x9F9FFF) is read
; by NOTHING -- not this build, not the ASL mirror, not any script.  It is a
; stale second copy of demo-song presets 0-17: eighteen SLIDE4K blocks laid
; end to end, one 0xFF alignment byte after preset 00 (ROM 0x9C9017), and
; 2,869 bytes of 0xFF fill after preset 17's block ends at ROM 0x9F94CA.  Its
; payloads are byte-identical to the reference slices in original_ROMs/
; (demo_preset_NN_compressed.original.bin), and the ROM's live copy of those
; bytes is rebuilt further down this file from includes/demo_presets/midi/
; *.mid + sidecar/*.yaml.  The bootstrap extraction (`make decompress-demo-
; presets`) reads original_ROMs/kn5000_table_data.rom, not this blob, so
; nothing depends on the duplicate.  Deleting the tail would save 221 KB and
; break neither build, but it would rewrite a checked-in dump artifact whose
; hash is quoted in analysis/binclude-audit-2026-08-07/ -- so it is
; documented, not removed.  Note for future scans: sweeping this file for the
; SLIDE4K magic finds eighteen extra headers past 0x7F2D8; they are this
; residue, not a newly discovered compressed region.
;
; `python3 scripts/analysis/audit_icons_blob_coverage.py -v` re-derives this
; whole map from the tree and the factory dump and fails if any of it drifts.
; -----------------------------------------------------------------------------
	; UI text fonts (0x944D78-0x950FFF): descriptor table + 1bpp glyph
	; banks + Font5 kern table (see that module's header)
	.include "fonts.s"

	; Music Stylist preset records (0x951000-0x98156F) and the unreferenced
	; residue after the record grid (0x981570-0x983B39), fully symbolic
	; (generated by scripts/generators/gen_style_records.py)
	.include "style_records.s"

	; HELP system data + effect-preset pointer tables (0x983B3A-0x9999CB):
	; stale truncated German SLIDE8K remnant, the two live effect-preset
	; pointer tables that overwrote its tail, the help language index, the
	; five intro strings, and the five live SLIDE8K help databases (build
	; products recompressed from decompressed sources, demo-preset style).
	.include "help_databases.s"

	; Seven stray bytes left over after the Indonesian help database: three
	; (0x7f, N) pairs with N stepping 0xd8/0xe2/0xec (+10 each) plus a lone
	; 0x7e -- the tail of some stride-10 table from an earlier factory build.
	; No pointer to this address exists in any program or table-data ROM.
HelpDB_TrailingResidue:
	.byte	0x7f, 0xd8, 0x7f, 0xe2, 0x7f, 0xec, 0x7e

	.org 0x99EC00 - 0x800000, 0xFF

	; Panel Memory factory data (0x99EC00-0x9ABF3F): the 10 factory bank
	; names and 80 chunk-format preset records (10 banks x 8 buttons).
	; See the module header for the record format and the maincpu loader
	; routines that copy this block to RAM 0x1ED350/0x1ED360/0x1ED400.
	.include "panel_memory_presets.s"

	.org 0x9B4000 - 0x800000, 0xFF

; -----------------------------------------------------------------------------
; COMPOSER FACTORY MEMORY IMAGE (0x9B4000-0x9C3FFF)
; -----------------------------------------------------------------------------
; 64KB image of the COMPOSER (user rhythm style) memory, copied wholesale to
; RAM 0x94800 by the v10 maincpu routine at 0xF6413A (LABEL_F6413A):
;   ld XIY,0x9b4000 / ld XIX,0x94800 / ld BC,0x8000 / ldirw
; (0x8000 words = 64KB; v7/v9 carry the same routine at shifted addresses).
; [2026-09-25: LABEL_F6413A no longer exists; in v10 the routine at 0xF6413A
; is labelled AccWidget_DispatchTable (sequencer/accompaniment_engine.s),
; a name that does not describe this copy.]
;
; Observed layout (image offsets):
;   +0x0000  header (memory-config words, part lists 01 02 03 04, "ZZZ" tag)
;   +0x0080  30 style-slot records, 0x60 bytes each, 16-char name at +0x20:
;            " Pop Samba 1".." Pop Samba 4", "GentleSwing 1".."GentleSwing 4",
;            "German 3/4 1".."German 3/4 4", and 18 x "    Clear       "
;            (3 factory user styles x 4 variations + 18 empty slots)
;   +0xC000  rhythm cell streams: 6-byte note events (90 nn vv dd tt 00)
;            behind 80 xx 00 ff ff 87 cell headers -- the same cell format
;            the factory rhythms use
; No code addresses the image interior directly (access goes through the RAM
; copy), so the block stays a single labeled include.
; -----------------------------------------------------------------------------
Composer_FactoryMemoryImage:	.incbin	"includes/generated/Composer_FactoryMemoryImage.bin"
	; Built from custom_data/styles/Composer_FactoryMemoryImage.styles. Same cell/chain
	; container as the IC19 accompaniment styles -- 234 cells, 168/168 pointers resolving,
	; 84/84 back-links, 7,457 events with none malformed. It was "no field spec, no parser"
	; until that container was solved.

	.org 0x9C4000 - 0x800000, 0xFF

; Demo Song preset pointer table: indexed demo-part number * 4 by the
; Demo_GetPresetBaseForPart family (v7 maincpu/demo/file_demo_proc.s; same
; code in v9/v10).  A non-null entry means the SLIDE4K block it points to was
; decompressed to RAM 0x69800; a null index 0-18 falls back to the live
; preset area at 0x0AB000.  Entry 18 is the Feature Demo preset, stored apart
; from the others at 0x8E0000.
; v10 readers of this table (file_demo_proc.s; all compute 0x9C4000 + 4*n):
;   Demo_ParseSlideHeader (0xF87189)  if the entry is non-null, calls
;       SLIDE_Parse_Header (0xEF41E3) with it and destination RAM 0x69800;
;       "SLIDE" + '4' dispatches to SLIDE_Decompress_4K_Init (0xEF3FAB)
;   Demo_GetPresetBaseForPart (0xF86F48), ..Alt (0xF86F6D), ..Ext (0xF86F92)
;       null test only: non-null -> 0x69800, null -> 0x0AB000
;   Voice_GetPresetFieldWord (0xF86FB7) / Voice_GetPresetFieldAddr (0xF86FDC)
;       the same test, then the u16 at +0x1E (track-enable mask) / the address
;       +0x20 (track types) of the decompressed image
	.long	DemoSongPreset00
	.long	DemoSongPreset01
	.long	DemoSongPreset02
	.long	DemoSongPreset03
	.long	DemoSongPreset04
	.long	DemoSongPreset05
	.long	DemoSongPreset06
	.long	DemoSongPreset07
	.long	DemoSongPreset08
	.long	DemoSongPreset09
	.long	DemoSongPreset10
	.long	DemoSongPreset11
	.long	DemoSongPreset12
	.long	DemoSongPreset13
	.long	DemoSongPreset14
	.long	DemoSongPreset15
	.long	DemoSongPreset16
	.long	DemoSongPreset17
	.long	DemoSongPreset18
	.long	0	; terminator

; -----------------------------------------------------------------------------
; SLIDE4K-compressed demo song presets, entries 0-17 (entry 18 is at 0x8E0000).
; Each block: 8-byte "SLIDE4K\0" magic + 24-bit BIG-ENDIAN uncompressed size
; (see the Makefile's demo-preset section for the endianness evidence), then
; the LZSS payload, which the Makefile regenerates from the decompressed source
; in includes/demo_presets/ (byte-identical via compress_lzss.py --reference).
; The blocks run end to end from 0x9C4050 to 0x9F94CA, with one 0xFF alignment
; byte at 0x9C9017 and 2,869 bytes of 0xFF fill from 0x9F94CB to 0x9F9FFF.
;
; The same bytes also survive verbatim in the dead tail of
; includes/icons_to_strings.bin (file offsets 0x7F2D8-0xB5287): a pre-conversion
; duplicate that no build reads -- see the backing-blob note in the region
; banner above.
; -----------------------------------------------------------------------------

	.org 0x9C4050 - 0x800000, 0xFF
; Demo song 00 (pointer-table slot 0): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 26,880 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "MAIN".
; Built from includes/demo_presets/midi/demo_preset_00.mid + sidecar/.yaml.
DemoSongPreset00:
	.asciz "SLIDE4K"
	.byte 0x00, 0x69, 0x00	; uncompressed size = 26880 bytes
	.incbin "includes/demo_presets/demo_preset_00_compressed.bin"

	.org 0x9C9018 - 0x800000, 0xFF
; Demo song 01 (pointer-table slot 1): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 28,928 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "ACCORD".
; Built from includes/demo_presets/midi/demo_preset_01.mid + sidecar/.yaml.
DemoSongPreset01:
	.asciz "SLIDE4K"
	.byte 0x00, 0x71, 0x00	; uncompressed size = 28928 bytes
	.incbin "includes/demo_presets/demo_preset_01_compressed.bin"

	.org 0x9CE17C - 0x800000, 0xFF
; Demo song 02 (pointer-table slot 2): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 18,944 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) is all underscores.
; Built from includes/demo_presets/midi/demo_preset_02.mid + sidecar/.yaml.
DemoSongPreset02:
	.asciz "SLIDE4K"
	.byte 0x00, 0x4A, 0x00	; uncompressed size = 18944 bytes
	.incbin "includes/demo_presets/demo_preset_02_compressed.bin"

	.org 0x9D16F2 - 0x800000, 0xFF
; Demo song 03 (pointer-table slot 3): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 27,392 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) is all underscores.
; Built from includes/demo_presets/midi/demo_preset_03.mid + sidecar/.yaml.
DemoSongPreset03:
	.asciz "SLIDE4K"
	.byte 0x00, 0x6B, 0x00	; uncompressed size = 27392 bytes
	.incbin "includes/demo_presets/demo_preset_03_compressed.bin"

	.org 0x9D645C - 0x800000, 0xFF
; Demo song 04 (pointer-table slot 4): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 22,016 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "SHOW".
; Built from includes/demo_presets/midi/demo_preset_04.mid + sidecar/.yaml.
DemoSongPreset04:
	.asciz "SLIDE4K"
	.byte 0x00, 0x56, 0x00	; uncompressed size = 22016 bytes
	.incbin "includes/demo_presets/demo_preset_04_compressed.bin"

	.org 0x9DA016 - 0x800000, 0xFF
; Demo song 05 (pointer-table slot 5): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 25,088 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "CONTEMP".
; Built from includes/demo_presets/midi/demo_preset_05.mid + sidecar/.yaml.
DemoSongPreset05:
	.asciz "SLIDE4K"
	.byte 0x00, 0x62, 0x00	; uncompressed size = 25088 bytes
	.incbin "includes/demo_presets/demo_preset_05_compressed.bin"

	.org 0x9DE072 - 0x800000, 0xFF
; Demo song 06 (pointer-table slot 6): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 17,408 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "STRINGS".
; Built from includes/demo_presets/midi/demo_preset_06.mid + sidecar/.yaml.
DemoSongPreset06:
	.asciz "SLIDE4K"
	.byte 0x00, 0x44, 0x00	; uncompressed size = 17408 bytes
	.incbin "includes/demo_presets/demo_preset_06_compressed.bin"

	.org 0x9E0CE2 - 0x800000, 0xFF
; Demo song 07 (pointer-table slot 7): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 8,448 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) is all underscores.
; Built from includes/demo_presets/midi/demo_preset_07.mid + sidecar/.yaml.
DemoSongPreset07:
	.asciz "SLIDE4K"
	.byte 0x00, 0x21, 0x00	; uncompressed size = 8448 bytes
	.incbin "includes/demo_presets/demo_preset_07_compressed.bin"

	.org 0x9E2358 - 0x800000, 0xFF
; Demo song 08 (pointer-table slot 8): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 23,040 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "GUITAR".
; Built from includes/demo_presets/midi/demo_preset_08.mid + sidecar/.yaml.
DemoSongPreset08:
	.asciz "SLIDE4K"
	.byte 0x00, 0x5A, 0x00	; uncompressed size = 23040 bytes
	.incbin "includes/demo_presets/demo_preset_08_compressed.bin"

	.org 0x9E61C2 - 0x800000, 0xFF
; Demo song 09 (pointer-table slot 9): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 6,912 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) is all underscores.
; Built from includes/demo_presets/midi/demo_preset_09.mid + sidecar/.yaml.
DemoSongPreset09:
	.asciz "SLIDE4K"
	.byte 0x00, 0x1B, 0x00	; uncompressed size = 6912 bytes
	.incbin "includes/demo_presets/demo_preset_09_compressed.bin"

	.org 0x9E72E8 - 0x800000, 0xFF
; Demo song 10 (pointer-table slot 10): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 17,408 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "SAX".
; Built from includes/demo_presets/midi/demo_preset_10.mid + sidecar/.yaml.
DemoSongPreset10:
	.asciz "SLIDE4K"
	.byte 0x00, 0x44, 0x00	; uncompressed size = 17408 bytes
	.incbin "includes/demo_presets/demo_preset_10_compressed.bin"

	.org 0x9EA1F2 - 0x800000, 0xFF
; Demo song 11 (pointer-table slot 11): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 23,296 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "JAZZORG".
; Built from includes/demo_presets/midi/demo_preset_11.mid + sidecar/.yaml.
DemoSongPreset11:
	.asciz "SLIDE4K"
	.byte 0x00, 0x5B, 0x00	; uncompressed size = 23296 bytes
	.incbin "includes/demo_presets/demo_preset_11_compressed.bin"

	.org 0x9EDFFC - 0x800000, 0xFF
; Demo song 12 (pointer-table slot 12): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 6,912 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "Hokie Dance".
; Built from includes/demo_presets/midi/demo_preset_12.mid + sidecar/.yaml.
DemoSongPreset12:
	.asciz "SLIDE4K"
	.byte 0x00, 0x1B, 0x00	; uncompressed size = 6912 bytes
	.incbin "includes/demo_presets/demo_preset_12_compressed.bin"

	.org 0x9EEC62 - 0x800000, 0xFF
; Demo song 13 (pointer-table slot 13): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 11,264 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) is blank.
; Built from includes/demo_presets/midi/demo_preset_13.mid + sidecar/.yaml.
DemoSongPreset13:
	.asciz "SLIDE4K"
	.byte 0x00, 0x2C, 0x00	; uncompressed size = 11264 bytes
	.incbin "includes/demo_presets/demo_preset_13_compressed.bin"

	.org 0x9F0E72 - 0x800000, 0xFF
; Demo song 14 (pointer-table slot 14): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 6,656 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "Organ Combo Demo".
; Built from includes/demo_presets/midi/demo_preset_14.mid + sidecar/.yaml.
DemoSongPreset14:
	.asciz "SLIDE4K"
	.byte 0x00, 0x1A, 0x00	; uncompressed size = 6656 bytes
	.incbin "includes/demo_presets/demo_preset_14_compressed.bin"

	.org 0x9F1C70 - 0x800000, 0xFF
; Demo song 15 (pointer-table slot 15): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 11,520 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "Big Band Mid".
; Built from includes/demo_presets/midi/demo_preset_15.mid + sidecar/.yaml.
DemoSongPreset15:
	.asciz "SLIDE4K"
	.byte 0x00, 0x2D, 0x00	; uncompressed size = 11520 bytes
	.incbin "includes/demo_presets/demo_preset_15_compressed.bin"

	.org 0x9F3B52 - 0x800000, 0xFF
; Demo song 16 (pointer-table slot 16): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 6,656 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) reads "Bavarian Polka".
; Built from includes/demo_presets/midi/demo_preset_16.mid + sidecar/.yaml.
DemoSongPreset16:
	.asciz "SLIDE4K"
	.byte 0x00, 0x1A, 0x00	; uncompressed size = 6656 bytes
	.incbin "includes/demo_presets/demo_preset_16_compressed.bin"

	.org 0x9F494E - 0x800000, 0xFF
; Demo song 17 (pointer-table slot 17): Demo_ParseSlideHeader (0xF87189)
; hands this block to SLIDE_Parse_Header (0xEF41E3), which inflates it to
; RAM 0x69800 -- 5,888 B, an image starting "ZZZZ";
; its 16-character title field (+0x100) is all underscores.
; Built from includes/demo_presets/midi/demo_preset_17.mid + sidecar/.yaml.
DemoSongPreset17:
	.asciz "SLIDE4K"
	.byte 0x00, 0x17, 0x00	; uncompressed size = 5888 bytes
	.incbin "includes/demo_presets/demo_preset_17_compressed.bin"

	.org 0x9FA000 - 0x800000, 0xFF
FileIdentifierStringsTable:
	; File type identifier strings used for detecting file formats
	aligned_string "Technics KN5000 Program  DATA FILE 1/2"	; 9FA000
	aligned_string "Technics KN5000 Program  DATA FILE 2/2"	; 9FA028
	aligned_string "Technics KN5000 Program  DATA FILE PCK"	; 9FA050
	aligned_string "Technics KN5000 Table    DATA FILE 1/2"	; 9FA078
	aligned_string "Technics KN5000 Table    DATA FILE 2/2"	; 9FA0A0
	aligned_string "Technics KN5000 Table    DATA FILE PCK"	; 9FA0C8
	.asciz "Technics KN5000 CMPCUSTOMDATA FILE    "
	.byte 0x00	; 9FA0F0
	.asciz "Technics KN5000 HD-AEPRG DATA FILE    "
	.byte 0xf0	; 9FA118
	; Data between strings and SLIDE marker (0x9FA140 - 0x9FA14F)
; IDENTIFIED 2026-09-25: Boot_LoadDiskData's jump-offset table.  Boot_LoadDiskData
; (0x9FC40B) checks disk type 1..8, computes 2*(type-1), loads the word at
; boot address 0xFFA140 + 2*(type-1) (ldw_sri) and jumps to
; Boot_LoadDiskData__ldd_Program12 + word (jp_ind).  Types as Boot_DetectDiskType
; (0x9FBFC4) assigns them from the FileIdentifierStringsTable slot matched:
; 1 Program 1/2, 2 Program 2/2, 3 Table 1/2, 4 Table 2/2, 5 CMPCUSTOMDATA,
; 6 HD-AEPRG, 7 Program PCK, 8 Table PCK.  The second disks of a set (2, 4)
; go to the error handler.  The program ROM's own update dispatcher
; (HANDLE_UPDATE_OFFSETS, the commented ASL listing further down) has the same
; 8-way shape, with its two second-disk slots sending to
; SHOW_ILLEGAL_DISK_MESSAGE.  (The handlers were labelled __ldd_type1..5 and
; __ldd_type678 in address order until 2026-09-25; renamed after the disk
; type that reaches them -- scripts/renaming/rename_tdata_loaddiskdata_handlers.sed.)
Boot_LoadDiskData_JumpOffsets:
	.short	Boot_LoadDiskData__ldd_Program12 - Boot_LoadDiskData__ldd_Program12	; type 1
	.short	Boot_LoadDiskData__ldd_error - Boot_LoadDiskData__ldd_Program12	; type 2
	.short	Boot_LoadDiskData__ldd_Table12 - Boot_LoadDiskData__ldd_Program12	; type 3
	.short	Boot_LoadDiskData__ldd_error - Boot_LoadDiskData__ldd_Program12	; type 4
	.short	Boot_LoadDiskData__ldd_CustomData - Boot_LoadDiskData__ldd_Program12	; type 5
	.short	Boot_LoadDiskData__ldd_HDAEPrg - Boot_LoadDiskData__ldd_Program12	; type 6
	.short	Boot_LoadDiskData__ldd_ProgramPCK - Boot_LoadDiskData__ldd_Program12	; type 7
	.short	Boot_LoadDiskData__ldd_TablePCK - Boot_LoadDiskData__ldd_Program12	; type 8

;HANDLE_UPDATE_BASE_ADDR		EQU HANDLE_UPDATE_FILE_TYPE_ID_001h
;
;HANDLE_UPDATE_OFFSETS:			; E00178
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_001h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 ;Program DATA FILE 1/2"
;	dw (SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Program DATA FILE 2/2"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_003h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE 1/2"
;	dw (SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE 2/2"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_005h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 CMPCUSTOMDATA FILE"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_006h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 HD-AEPRG DATA FILE"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_007h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Program DATA FILE PCK"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_008h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE PCK"


	.org 0x9FA150 - 0x800000, 0xFF

; The 5-byte signature LZSS_ParseHeader (0x9FC9B3) compares the first bytes
; of a compressed update stream against: it pushes 0x00FF / 0xA150, i.e. the
; pointer 0x00FFA150 = this string's boot-time alias, with length 5.  (Renamed
; from BootscreenSlideMarker 2026-09-25; nothing referenced the old name.)
LZSS_SlideSignature:
	.asciz "SLIDE"

; Boot/flash-update screen bitmaps (headerless 1bpp, 224x22, 616 bytes
; each): byte-identical duplicates of the eight bitmaps in the maincpu ROM
; at 0xE0018E-0xE0148D, re-emitted verbatim from the same image files under
; v10/maincpu/images/ so the duplication stays single-sourced.
; Cross-ref: v10/maincpu/boot/boot_data_tables.s
Bitmap_1bit_Flash_Memory_Update:	.incbin "../v10/maincpu/images/Bitmap_1bit_Flash_Memory_Update.bin"
Bitmap_1bit_Now_Erasing:		.incbin "../v10/maincpu/images/Bitmap_1bit_Now_Erasing.bin"
Bitmap_1bit_FD_to_Flash_Memory:		.incbin "../v10/maincpu/images/Bitmap_1bit_FD_to_Flash_Memory.bin"
Bitmap_1bit_Completed:			.incbin "../v10/maincpu/images/Bitmap_1bit_Completed.bin"
Bitmap_1bit_Please_Wait:		.incbin "../v10/maincpu/images/Bitmap_1bit_Please_Wait.bin"
Bitmap_1bit_Change_FD_2_of_2:		.incbin "../v10/maincpu/images/Bitmap_1bit_Change_FD_2_of_2.bin"
Bitmap_1bit_Illegal_Disk:		.incbin "../v10/maincpu/images/Bitmap_1bit_Illegal_Disk.bin"
Bitmap_1bit_Turn_On_AGAIN:		.incbin "../v10/maincpu/images/Bitmap_1bit_Turn_On_AGAIN.bin"

; =============================================================================
; FDC Bootloader Dispatch Offset Tables (0x9FB496 - 0x9FB4D1)
; Boot-time alias: 0xFFB496 - 0xFFB4D1 (the CPU sees this ROM at
; 0xE00000-0xFFFFFF while the bootloader runs, so the consuming code
; references these tables as 0xFFB4xx).
;
; Three .short offset tables driving the `JP T, XIX+WA` dispatches of the
; first-stage bootloader's FDC driver (boot_fdc_driver.s) -- a compact port
; of the maincpu FDC driver (v10/maincpu/storage/fdc_routines.s), which
; carries byte-identical copies of the first two tables at 0xEA98A6/0xEA98B2
; and its own handler table FDC_HANDLER_OFFSETS at 0xEA98CA.  Each dispatch
; site doubles the index, fetches `LD WA, (XIX+WA)` with XIX = table address,
; then executes `JP T, XIX+WA` with XIX = the base label the entries are
; relative to.  All targets are now labeled in boot_fdc_driver.s, so the
; entries are symbolic label differences.
;
; The driver's RAM state block is documented at the top of boot_fdc_driver.s.
; =============================================================================

; -----------------------------------------------------------------------------
; FDC_DiskTypeStanza_Offsets - media-type configuration stanza offsets
; Consumed at 0xFFD98F inside FDC_MediaConfigAndRecalibrate: index = low
; nibble of the media-type code (0x0C9C), dispatched for values 0-5; values
; 6-15 skip the table and run FDC_MediaStanza_Default.  Offsets are relative
; to FDC_MediaStanza_Type0.  Each stanza stores a media-format id to 0x0C9A
; and picks the data rate for the aux control-internal-mode command; the
; shared tail FDC_MediaStanza_Submit submits it and, on success, runs
; FDC_CmdMotorOn and FDC_CmdRecalibrate.
; -----------------------------------------------------------------------------
FDC_DiskTypeStanza_Offsets:
	.short FDC_MediaStanza_Type0 - FDC_MediaStanza_Type0	; type 0: fmt id 0, 250 kbps
	.short FDC_MediaStanza_Type1 - FDC_MediaStanza_Type0	; type 1: fmt id 0, 300 kbps
	.short FDC_MediaStanza_Type2 - FDC_MediaStanza_Type0	; type 2: fmt id 2, 500 kbps
	.short FDC_MediaStanza_Type3 - FDC_MediaStanza_Type0	; type 3: fmt id 3, 500 kbps
	.short FDC_MediaStanza_Type4 - FDC_MediaStanza_Type0	; type 4: fmt id 4, 250 kbps
	.short FDC_MediaStanza_Type5 - FDC_MediaStanza_Type0	; type 5: fmt id 5, 250 kbps

; -----------------------------------------------------------------------------
; FDC_ValidateCmd_Offsets - per-command parameter-validation offsets
; Consumed at 0xFFDA97 inside FDC_ValidateRequest (called by FDC_Request
; before dispatching): index = command word (0x0C6E), 0-11; commands > 11
; branch straight into the FDC_Validate_DriveTrackSector path.  Offsets are
; relative to FDC_Validate_FormatParams.  Returns L = status (0 = command
; accepted).  Only four distinct validators exist; maincpu twin labels:
; FDC_CMD_HANDLER_BASE / FDC_ReturnZero / FDC_ErrorInvalidDrive /
; FDC_CheckDriveCount.
; -----------------------------------------------------------------------------
FDC_ValidateCmd_Offsets:
	.short FDC_Validate_FormatParams - FDC_Validate_FormatParams	; cmd  0 (initialize)         geometry check + program
	.short FDC_Validate_DriveTrackSector - FDC_Validate_FormatParams	; cmd  1 (recalibrate)        drive check (chain accepts, L=0)
	.short FDC_Validate_DriveTrackSector - FDC_Validate_FormatParams	; cmd  2 (seek)               drive + track + head checks
	.short FDC_Validate_DriveTrackSector - FDC_Validate_FormatParams	; cmd  3 (read sectors)       drive + track + sector checks
	.short FDC_Validate_DriveTrackSector - FDC_Validate_FormatParams	; cmd  4 (write sectors)      drive + track + sector checks
	.short FDC_Validate_DriveTrackSector - FDC_Validate_FormatParams	; cmd  5 (format)             drive check + stub epilogue
	.short FDC_Validate_AcceptAlways - FDC_Validate_FormatParams	; cmd  6 (motor on)           always accepted
	.short FDC_Validate_AcceptAlways - FDC_Validate_FormatParams	; cmd  7 (motor off)          always accepted
	.short FDC_Validate_AcceptAlways - FDC_Validate_FormatParams	; cmd  8 (get last error)     always accepted
	.short FDC_Validate_HeadDrive - FDC_Validate_FormatParams	; cmd  9 (set disk-changed)   flag/drive precheck
	.short FDC_Validate_AcceptAlways - FDC_Validate_FormatParams	; cmd 10 (controller reset)   always accepted
	.short FDC_Validate_DriveTrackSector - FDC_Validate_FormatParams	; cmd 11 (sense drive status) drive check (chain accepts, L=0)

; -----------------------------------------------------------------------------
; FDC_CommandDispatch_Offsets - per-command execution stub offsets
; Consumed at 0xFFE9F4 in FDC_Request: after validation the executor
; dispatches here; commands > 11 report error 0xFF.  Offsets are relative to
; FDC_Dispatch_Initialize: twelve uniform 5-byte stubs
; `calr <handler>; jr T, FDC_Request__finish`.
; Maincpu twin: FDC_HANDLER_OFFSETS (0xEA98CA) -> FDC_HANDLER_DISPATCH_BASE
; (offsets differ there because the maincpu stubs vary in length); the
; maincpu handler name for each command is given in parentheses.
; -----------------------------------------------------------------------------
FDC_CommandDispatch_Offsets:
	.short FDC_Dispatch_Initialize - FDC_Dispatch_Initialize	; cmd  0 -> FDC_CmdInitialize      (FDC_InitSequence_Full)
	.short FDC_Dispatch_Recalibrate - FDC_Dispatch_Initialize	; cmd  1 -> FDC_CmdRecalibrate     (FDC_CmdRecalibrate)
	.short FDC_Dispatch_Seek - FDC_Dispatch_Initialize	; cmd  2 -> FDC_CmdSeek            (FDC_CmdSeek)
	.short FDC_Dispatch_ReadSectors - FDC_Dispatch_Initialize	; cmd  3 -> FDC_CmdReadSectors     (FDC_CMD_EXEC)
	.short FDC_Dispatch_WriteSectors - FDC_Dispatch_Initialize	; cmd  4 -> FDC_CmdWriteSectors    (FDC_SECTOR_XFER)
	.short FDC_Dispatch_Format - FDC_Dispatch_Initialize	; cmd  5 -> FDC_CmdFormat          (FDC_MODE_CONFIG)
	.short FDC_Dispatch_MotorOn - FDC_Dispatch_Initialize	; cmd  6 -> FDC_CmdMotorOn         (FDC_CMD_ENABLE)
	.short FDC_Dispatch_MotorOff - FDC_Dispatch_Initialize	; cmd  7 -> FDC_CmdMotorOff        (FDC_CMD_DISABLE)
	.short FDC_Dispatch_GetLastError - FDC_Dispatch_Initialize	; cmd  8 -> FDC_CmdGetLastError    (FDC_STATUS_COPY)
	.short FDC_Dispatch_SetDiskChanged - FDC_Dispatch_Initialize	; cmd  9 -> FDC_CmdSetDiskChanged  (FDC_OUTPUT_CTRL)
	.short FDC_Dispatch_ControllerReset - FDC_Dispatch_Initialize	; cmd 10 -> FDC_CmdControllerReset (FDC_CMD_DISPATCH_SUB)
	.short FDC_Dispatch_SenseDriveStatus - FDC_Dispatch_Initialize	; cmd 11 -> FDC_CmdSenseDriveStatus (FDC_INTERRUPT_HANDLER)


; =============================================================================
; FIRST-STAGE BOOTLOADER CODE
; =============================================================================
; This code runs when the CPU boots, before memory remapping.
; At boot time, this ROM is mapped at 0xE00000-0xFFFFFF.
; After remapping, it's at 0x800000-0x9FFFFF.
;
; The interrupt vectors contain boot-time addresses (0xFFxxxx), so we define
; them as constants here.
; =============================================================================

; Boot-time addresses (CPU sees ROM at 0xE00000-0xFFFFFF at boot)
.equ BOOT_EMPTY_HANDLER, 0xFFB705
.equ BOOT_RESET_HANDLER, 0xFFFEE0
.equ BOOT_NMI_HANDLER, 0xFFB7FB
.equ BOOT_INT4_HANDLER, 0xFFEAB2
.equ BOOT_INTA_HANDLER, 0xFFF229
.equ BOOT_INTT1_HANDLER, 0xFFB7F2
.equ BOOT_INTRX1_HANDLER, 0xFFF2D0
.equ BOOT_INTTX1_HANDLER, 0xFFF2AE
.equ BOOT_INTTC3_HANDLER, 0xFFEA9D
.equ BOOT_ENTRY, 0xFFB4E8

; -----------------------------------------------------------------------------
; Boot Data Section - Constants copied to RAM during initialization
; These are referenced by Boot_ClearRAM routine
; -----------------------------------------------------------------------------
	.org 0x9FB4D2 - 0x800000, 0xFF
Boot_BitMaskTable:	; Copied to RAM 0x1044 by Boot_ClearRAM (10 bytes)
	; Bit mask pattern for bit manipulation operations (bits 7..0, plus 2 zeros)
	.byte 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01, 0x00, 0x00

Boot_InitParams:	; Copied to RAM 0x9998 by Boot_ClearRAM (12 bytes)
	; Stack/display initialization parameters
	.byte 0x7e, 0x10	; Values at 0x9998-9999
	.byte 0x00, 0x00	; Values at 0x999A-999B
	.byte 0x00, 0x80	; Values at 0x999C-999D
	.byte 0x00, 0x00	; Values at 0x999E-999F
	.byte 0x00, 0x00	; Values at 0x99A0-99A1
	.byte 0x00, 0x00	; Values at 0x99A2-99A3


	.org 0x9FB4E8 - 0x800000, 0xFF
; -----------------------------------------------------------------------------
; Boot_Init - First-stage bootloader entry point
; Initializes CPU, memory controller, and hands off to main program ROM
; -----------------------------------------------------------------------------
Boot_Init:
	; Hardware initialization code shared with maincpu ROM
	.include "shared/boot_hw_init.s"
	; End of shared boot code (315 bytes)

	; === Stack Pointer Setup ===
	lda xwa, (0x00987e:24)
	ld xsp, xwa

	; === Clear RAM Variable ===
	ld xwa, 0:i3
	ld (3072:16), xwa	; LD (0x0C00), XWA

	; === Call Boot_ClearRAM ===
	calr Boot_ClearRAM

	; === Reload Stack Pointer ===
	lda xwa, (0x00987e:24)
	ld xsp, xwa

	; === Enable Interrupts ===
	ei 0

	; === Detect Boot Mode ===
	calr Detect_Region_Code

	; === Call Main Hardware Init ===
	call Flash_Init_Custom_And_Table + 0x600000	; Flash_Init_Custom_And_Table (boot-time address)

	; === Configure Interrupt Enable Register ===
	lda_dd8l XBC, (0xE4)
	ld a, (xbc)
	and a, 0x8F
	or a, 0x30
	ld (xbc), a

	; === Check Boot Source ===
	jr __jrt_nop_9FB652	; nop-like branch
__jrt_nop_9FB652:
	bit_dd8 0, 0x38	; Check Port E bit 0
	jr nz, Boot_SkipFDCCheck

	; === Get Boot Mode and Check FDC ===
	calr Get_Region_Code
	cp l, 4:i3
	call nz, (HDAE5000_InitializeParallelPort + 0x600000:24)	; CALL NZ, HDAE5000_InitializeParallelPort (boot-time alias of 0x9FC6B2)

Boot_SkipFDCCheck:
	call Boot_CheckDiskPresent + 0x600000	; Boot_CheckDiskPresent: L=1 disk present (PD6 low)
	cp l, 0:i3
	jr z, Boot_PrepareJump

	; === Bring up the boot CP-serial link ===
	ld xhl, (BootSerial_InitVectorTable + 0x600000:24)	; BootSerial_InitVectorTable[0] -> BootSerial_Init
	call (xhl)

	; === Probe the device on the CP-serial link ===
	call Boot_ProbeExternalDevice + 0x600000	; Boot_ProbeExternalDevice: HL=device class
	cp l, 4:i3
	jr nz, Boot_PrepareJump

	; === Flash Update Sequence ===
	call FDC_Reset + 0x600000	; was "Boot_InitDisplay": the target issues FDC_Request cmd 0 (FDC init)
	call VGA_Setup + 0x600000	; was "Boot_ShowMessage": the target programs the VGA controller
	pushw 0x8
	pushw 0x3
	ld xwa, Bitmap_1bit_Please_Wait + 0x600000	; message addr
	ldw bc, 0x30	; width
	ldw de, 0x50	; height
	call DrawBitmap_UpdateDisplay + 0x600000	; Boot_DrawBitmap
	call Boot_DetectDiskType + 0x600000	; was "Boot_WaitForInput": returns L = update-disk type 1-8 or 0xFF
	cp l, 3:i3
	jr z, Boot_PrepareJump
	cp l, 0x8
	jr z, Boot_PrepareJump
	cp l, 0xFF
	jr z, Boot_PrepareJump
	call Boot_FlashUpdate_Main + 0x600000	; Boot_PerformUpdate

Boot_HaltLoop:
	jr Boot_HaltLoop

Boot_PrepareJump:
	; === Prepare to Jump to Main Program ROM ===
	ei 7	; disable maskable interrupts

	; === Clear Interrupt Flags ===
	ld (0xE4:8), 0x00:io
	ld (0xE0:8), 0x00:io
	ld (0xED:8), 0x00:io
	ld (0xE3:8), 0x00:io
	ld (0xEB:8), 0x00:io

	; === Setup for Jump to Main Program ===
	ld xsp, 0xC00
	ld xwa, PROGRAM_ROM_ENTRY_BOOT	; target address
	ldw ix, 0x14B	; CS2 register
	extz xix
	sll xbc, 16	; with the next line: XBC <<= 32 = 0 (XBC is not read before the jump)
	sll xbc, 16
	ld (xix), 0x80	; CS2 config
	jp (xwa)	; jump to main program!

Boot_Ret:
	ret

; =============================================================================
; Shared boot routines (Detect_Region_Code, Get_Region_Code, handlers)
; Uses REGION_CODE_VAR and BOOT_ENTRY_POINT defined at top of file
; =============================================================================
	.include "shared/boot_routines.s"

; Alias labels for backward compatibility with existing code
.equ Boot_Handler_End, Watchdog_Reset_Handler + 4

; =============================================================================
; Boot_CallInitHandlers - Call initialization handlers from table (Shared)
; Address: 0x9FB70A (boot-time: 0xFFB70A)
; Configuration for table_data: word comparison, boot-time indirect call helper
; =============================================================================
.equ INIT_FLAG_COMPARE_WORD, 1	; table_data uses word comparison
.equ INDIRECT_CALL_HELPER, 0xFFFA75	; indirect call helper (boot-time address)

	.include "shared/boot_call_init_handlers.s"

; -----------------------------------------------------------------------------
; Boot_ClearRAM - Initialize RAM and copy ROM data to RAM
; Address: 0xFFB740 (boot-time), 0x9FB740 (ROM)
;
; Operations performed:
;   1. Clear 0x894A bytes (35,146) at RAM 0x104E
;   2. Clear 0x0443 bytes (1,091) at RAM 0x0C00
;   3. Copy 12 bytes from ROM 0xFFB4DC to RAM 0x9998
;   4. Copy 10 bytes from ROM 0xFFB4D2 to RAM 0x1044
;
; Uses LDIRW for efficient word-mode block operations
; -----------------------------------------------------------------------------
	.org 0x9FB740 - 0x800000, 0xFF
Boot_ClearRAM:
	; === Clear RAM block 1: 0x104E for 0x894A bytes ===
	ld xde, 0x104E	; destination
	ld xbc, 0x894A	; count = 35146 bytes
	ld ix, bc	; save original count
	srl xbc, 1	; SRL 1, XBC (divide by 2 for word count)
	jr z, Boot_ClearRAM__clear1_done	; skip if zero
	ld xhl, xde	; source = dest for fill
	ldw (xde+), 0x0000	; LD (XDE+), 0x0000 (store first zero word)
	dec 1, xbc	; DEC 1, XBC
	or xbc, xbc	; test if zero
	jr z, Boot_ClearRAM__clear1_done
	ldirw93	; word block copy - fills with zeros
	cpiw_erp 0xE6, 0	; CP QBC, 0 (check high dword)
	jr z, Boot_ClearRAM__clear1_done
	ldto_werp WA, 0xE6	; LD WA, QBC
	ldirw93
	djnz16 wa, -5	; DJNZ WA, -5
Boot_ClearRAM__clear1_done:
	bit 0, ix	; BIT 0, IX (check if odd byte)
	jr z, Boot_ClearRAM__clear1_aligned
	ld (xde), 0x0	; clear last odd byte
Boot_ClearRAM__clear1_aligned:

	; === Clear RAM block 2: 0x0C00 for 0x0443 bytes ===
	ld xde, 0xC00	; destination
	ld xbc, 0x443	; count = 1091 bytes
	ld ix, bc
	srl xbc, 1	; SRL 1, XBC
	jr z, Boot_ClearRAM__clear2_done
	ld xhl, xde
	ldw (xde+), 0x0000	; LD (XDE+), 0x0000
	dec 1, xbc	; DEC 1, XBC
	or xbc, xbc
	jr z, Boot_ClearRAM__clear2_done
	ldirw93
	cpiw_erp 0xE6, 0	; CP QBC, 0
	jr z, Boot_ClearRAM__clear2_done
	ldto_werp WA, 0xE6	; LD WA, QBC
	ldirw93
	djnz16 wa, -5	; DJNZ WA, -5
Boot_ClearRAM__clear2_done:
	bit 0, ix	; BIT 0, IX
	jr z, Boot_ClearRAM__clear2_aligned
	ld (xde), 0x0
Boot_ClearRAM__clear2_aligned:

	; === Copy ROM data 1: 12 bytes from 0xFFB4DC to RAM 0x9998 ===
	ld xde, 0x9998	; destination
	ld xhl, Boot_InitParams + 0x600000	; source in boot ROM
	ld xbc, 0xC	; count = 12 bytes
	or xbc, xbc
	jr z, Boot_ClearRAM__copy1_done
	ldir83	; byte block copy
	cpiw_erp 0xE6, 0	; CP QBC, 0
	jr z, Boot_ClearRAM__copy1_done
	ldto_werp WA, 0xE6	; LD WA, QBC
	ldir83
	djnz16 wa, -5	; DJNZ WA, -5
Boot_ClearRAM__copy1_done:

	; === Copy ROM data 2: 10 bytes from 0xFFB4D2 to RAM 0x1044 ===
	ld xde, 0x1044	; destination
	ld xhl, Boot_BitMaskTable + 0x600000	; source in boot ROM
	ld xbc, 0xA	; count = 10 bytes
	or xbc, xbc
	jr z, Boot_ClearRAM__copy2_done
	ldir83
	cpiw_erp 0xE6, 0	; CP QBC, 0
	jr z, Boot_ClearRAM__copy2_done
	ldto_werp WA, 0xE6	; LD WA, QBC
	ldir83
	djnz16 wa, -5	; DJNZ WA, -5
Boot_ClearRAM__copy2_done:
	jrl Boot_Init+0x14B	; return to caller at 0xFFB633
	ret	; never reached

; =============================================================================
; BOOT INTERRUPT HANDLERS
; Addresses 0x9FB7F2-0x9FB811
; =============================================================================

	.org 0x9FB7F2 - 0x800000, 0xFF

; -----------------------------------------------------------------------------
; BootCode_INTT1_Handler - Timer 1 interrupt handler
; Address: 0x9FB7F2
; Increments 32-bit tick counter at RAM 0x0C00
; -----------------------------------------------------------------------------
BootCode_INTT1_Handler:
	push xwa	; 38
	ld xwa, 1:i3	; e8 a9
	add (3072:16), xwa	; e1 00 0c 88
	pop xwa	; 58
	reti	; 07

; -----------------------------------------------------------------------------
; BootCode_NMI_Handler - Non-maskable interrupt handler
; Address: 0x9FB7FB
; Fatal error - disables DRAM refresh and halts
; -----------------------------------------------------------------------------
BootCode_NMI_Handler:
	res 7, (354:16)	; f1 62 01 b7 - Disable DRAM refresh
BootCode_NMI_Handler__halt_loop:
	halt	; 05
	jr BootCode_NMI_Handler__halt_loop	; 68 fd

; -----------------------------------------------------------------------------
; Boot stub routines - return 0 in HL
; Addresses: 0x9FB802-0x9FB80D
; -----------------------------------------------------------------------------
BootStub_ReturnSuccessSlot1:
	ld hl, 0:i3	; db a8
	ret	; 0e

BootStub_ReturnSuccessSlot2:
	ld hl, 0:i3	; db a8
	ret	; 0e

BootStub_ReturnSuccessSlot3:
	ld hl, 0:i3	; db a8
	ret	; 0e

BootStub_ReturnSuccessSlot4:
	ld hl, 0:i3	; db a8
	ret	; 0e

; -----------------------------------------------------------------------------
; Boot stub - return 0xFFFF in HL (error/not found)
; Address: 0x9FB80E
; -----------------------------------------------------------------------------
BootStub_ReturnError:
	ldw hl, 0xFFFF	; 33 ff ff
	ret	; 0e

; =============================================================================
; 16-BIT FLASH PROGRAMMING ROUTINES
; For HDAE5000 expansion ROM (0x280000) and Custom Data Flash (0x300000)
; These use 16-bit bus width access
; =============================================================================

; -----------------------------------------------------------------------------
; Flash_Reset_16bit - Send software reset command to flash chip
; Address: 0x9FB812
;
; Entry: A = target (0=HDAE5000 at 0x280000, 1=Custom Data at 0x300000)
; Uses AMD/Atmel flash protocol: AA-55-F0 sequence
; For region code 4, also resets high bank at base+0x80000
; -----------------------------------------------------------------------------
Flash_Reset_16bit:
	push xiz	; 3e
	ld xbc, 0x280000	; 41 00 00 28 00 - HDAE5000 base
	cp a, 1:i3	; c9 d9
	jr nz, Flash_Reset_16bit__got_base	; 6e 05
	ld xbc, 0x300000	; 41 00 00 30 00 - Custom Data base
Flash_Reset_16bit__got_base:
	ld xiz, xbc	; e9 8e
Flash_Reset_16bit__wait_ready:
	bit_dd8 5, 0x1C	; f0 1c cd - Wait for P3 bit 5 (flash ready)
	jr z, Flash_Reset_16bit__wait_ready	; 66 fb
	ei 6	; 06 06 - Disable lower interrupts
	; Send unlock sequence: base+AAAA = AA
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	; Send unlock sequence: base+5554 = 55
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	; Send reset command: base+AAAA = F0
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xF0	; LD (XWA), 00F0h (word store)
	; Read to complete cycle
	ld	wa, (xiz+12850)              ; LD WA, (XIZ+3232h)
	ei 0	; 06 00 - Re-enable interrupts
	; Check if region code = 4 (high bank exists)
	call Get_Region_Code + 0x600000	; Get_Region_Code - returns region code in L
	cp l, 4:i3
	jr nz, Flash_Reset_16bit__done
	; Reset high bank at base+0x80000
	add xiz, 0x80000	; ee c8 00 00 08 00
	ei 6	; 06 06
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xF0	; LD (XWA), 00F0h (word store)
	ld	wa, (xiz+12850)              ; LD WA, (XIZ+3232h)
	ei 0	; 06 00
Flash_Reset_16bit__done:
	pop xiz	; 5e
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_ReadID_16bit - Read flash manufacturer and device ID
; Address: 0x9FB888
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
; Exit:  HL = device ID (or 0xFFFF if not recognized)
;
; Validated device IDs: 0x2223 (AM29F040), 0x22AB (AM29F400B),
;                       0x22D6 (AM29F800B), 0x2258 (AM29LV800B)
; Manufacturer IDs: 0x01 (AMD), 0x04 (Fujitsu)
; -----------------------------------------------------------------------------
Flash_ReadID_16bit:
	dec 8, xsp	; allocate 8 bytes of locals
	push xiz	; 3e
	ld (xsp + 10), a	; LD (XSP+0Ah), A - save target
	ldw (xsp + 8), 0xFFFF	; LD (XSP+08h), 0FFFFh - default return
	ld xwa, 0x280000	; 40 00 00 28 00 - HDAE5000 base
	cp (xsp + 10), 0x1	; CP (XSP+0Ah), 01h
	jr nz, Flash_ReadID_16bit__got_base	; 6e 05
	ld xwa, 0x300000	; 40 00 00 30 00 - Custom Data base
Flash_ReadID_16bit__got_base:
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA - save base address
	ei 6	; 06 06
	; Send unlock and ID command
	ld xbc, (xsp + 4)	; LD XBC, (XSP+04h)
	add xbc, 0xAAAA	; e9 c8 aa aa 00 00
	ldw (xbc), 0xAA	; LD (XBC), 00AAh (word store)
	ld xde, (xsp + 4)	; LD XDE, (XSP+04h)
	ldw	(xde+21844), 0x0055	; LD (XDE+5554h), 0055h
	ldw (xbc), 0x90	; LD (XBC), 0090h - ID command (word store)
	; Read manufacturer ID
	ld wa, (xde)	; 92 20
	ldfr_werp WA, 0xFA	; LD QIZ, WA - store manufacturer ID
	; Read device ID at base+2
	ld xbc, xde	; ea 89
	ld iz, (xbc + 2)	; LD IZ, (XBC+02h)
	ei 0	; 06 00
	; Validate manufacturer (01=AMD, 04=Fujitsu)
	cpiw_erp 0xFA, 1	; CP QIZ, 1
	jr z, Flash_ReadID_16bit__valid_mfr	; 66 05
	cpiw_erp 0xFA, 4	; CP QIZ, 4
	jr nz, Flash_ReadID_16bit__reset_exit	; 6e 23
Flash_ReadID_16bit__valid_mfr:
	; Validate device ID
	cp iz, 0x2223	; CP IZ, 2223h (AM29F040)
	jr z, Flash_ReadID_16bit__valid_id	; 66 12
	cp iz, 0x22AB	; CP IZ, 22ABh (AM29F400B)
	jr z, Flash_ReadID_16bit__valid_id	; 66 0c
	cp iz, 0x22D6	; CP IZ, 22D6h (AM29F800B)
	jr z, Flash_ReadID_16bit__valid_id	; 66 06
	cp iz, 0x2258	; CP IZ, 2258h (AM29LV800B)
	jr nz, Flash_ReadID_16bit__store_return	; 6e 03
Flash_ReadID_16bit__valid_id:
	ld (xsp + 8), iz	; LD (XSP+08h), IZ - store valid device ID
Flash_ReadID_16bit__store_return:
	ld a, (xsp + 10)	; LD A, (XSP+0Ah) - restore target
	extpfx2 0xD8, 0x12	; d8 12
	calr Flash_Reset_16bit	; CALR Flash_Reset_16bit (relative call back)
Flash_ReadID_16bit__reset_exit:
	ld hl, (xsp + 8)	; LD HL, (XSP+08h) - return device ID
	pop xiz	; 5e
	inc 8, xsp	; ef 60 - deallocate stack
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_ProgramWord_16bit - Program a word to flash memory
; Address: 0x9FB903
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
;        XBC = destination address
;        DE = data word to program
;
; Skips programming if data = 0xFFFF (erased state)
; Handles high bank (0x380000+) for Custom Data when region code = 4
; -----------------------------------------------------------------------------
Flash_ProgramWord_16bit:
	dec 6, xsp	; ef 6e - allocate 6 bytes stack frame
	push xiz	; 3e
	ld (xsp + 4), de	; LD (XSP+04h), DE - save data
	ld (xsp + 6), xbc	; LD (XSP+06h), XBC - save destination
	cpw (xsp + 4), 0xFFFF	; CP (XSP+04h), 0FFFFh
	jr z, Flash_ProgramWord_16bit__exit	; 66 51 - skip if already erased
	; Wait for flash ready
Flash_ProgramWord_16bit__wait_ready:
	bit_dd8 5, 0x1C	; f0 1c cd
	jr z, Flash_ProgramWord_16bit__wait_ready	; 66 fb
	; Check target
	cp a, 1:i3	; c9 d9
	jr nz, Flash_ProgramWord_16bit__hdae_target	; 6e 20
	; Custom Data target - check for high bank
	lda xiz, (0x300000:24); f2 00 00 30 36
	call Get_Region_Code + 0x600000	; CALL Boot_Get_Region_Code (at 0xFFB700)
	cp l, 4:i3	; cf dc
	jr nz, Flash_ProgramWord_16bit__do_program	; 6e 18
	; Check if address is in high bank (>= 0x380000)
	ld xwa, (xsp + 6)	; LD XWA, (XSP+06h)
	cp xwa, 0x380000	; e8 cf 00 00 38 00
	jr c, Flash_ProgramWord_16bit__do_program	; 67 0d
	add xiz, 0x80000	; ee c8 00 00 08 00
	jr Flash_ProgramWord_16bit__do_program	; 68 05
Flash_ProgramWord_16bit__hdae_target:
	lda xiz, (0x280000:24); f2 00 00 28 36
Flash_ProgramWord_16bit__do_program:
	ei 6	; 06 06
	; Send program command sequence
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	ldw (xwa), 0xA0	; LD (XWA), 00A0h - Program command (word store)
	; Write data to destination
	ld xwa, (xsp + 6)	; LD XWA, (XSP+06h) - destination
	ld bc, (xsp + 4)	; LD BC, (XSP+04h) - data
	ld (xwa), bc	; b0 51
	ei 0	; 06 00
Flash_ProgramWord_16bit__exit:
	pop xiz	; 5e
	inc 6, xsp	; ef 66 - deallocate stack
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_ChipErase_16bit - Erase entire flash chip
; Address: 0x9FB968
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
;
; Uses 6-byte chip erase sequence: AA-55-80-AA-55-10
; For Custom Data with region code = 4, also erases high bank
; -----------------------------------------------------------------------------
Flash_ChipErase_16bit:
	dec 2, xsp	; DEC 2, XSP - allocate 2 bytes
	push xiz	; 3e
	ld (xsp + 4), a	; LD (XSP+04h), A - save target
	ld xwa, 0x280000	; 40 00 00 28 00
	cp (xsp + 4), 0x1	; CP (XSP+04h), 01h
	jr nz, Flash_ChipErase_16bit__got_base	; 6e 05
	ld xwa, 0x300000	; 40 00 00 30 00
Flash_ChipErase_16bit__got_base:
	ld xiz, xwa	; e8 8e
	ei 6	; 06 06
	; Send chip erase sequence (6 bytes)
	; Byte 1: base+AAAA = AA
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	; Byte 2: base+5554 = 55
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	; Byte 3: base+AAAA = 80
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0x80	; LD (XWA), 0080h (word store)
	; Byte 4: base+AAAA = AA
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	; Byte 5: base+5554 = 55
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	; Byte 6: base+AAAA = 10 (chip erase command)
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0x10	; LD (XWA), 0010h (word store)
	; Check region code for high bank
	call Get_Region_Code + 0x600000	; CALL Boot_Get_Region_Code (at 0xFFB700)
	cp l, 4:i3	; cf dc
	jr nz, Flash_ChipErase_16bit__done	; 6e 49
	cp (xsp + 4), 0x1	; CP (XSP+04h), 01h
	jr nz, Flash_ChipErase_16bit__done	; 6e 43
	; Also erase high bank at 0x380000
	lda xiz, (0x380000:24); f2 00 00 38 36
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0x80	; LD (XWA), 0080h (word store)
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0x10	; LD (XWA), 0010h (word store)
Flash_ChipErase_16bit__done:
	ei 0	; 06 00
	pop xiz	; 5e
	inc 2, xsp	; INC 2, XSP - deallocate stack
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_SectorErase_16bit - Erase a single sector
; Address: 0x9FBA17
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
;        XBC = sector address
;
; Complex sector handling for boot block chips (AM29F400/800)
; Handles different sector layouts for bottom boot devices
; -----------------------------------------------------------------------------
Flash_SectorErase_16bit:
	lda xsp, (xsp - 10)	; LDA XSP, XSP+0F6h - allocate 10 bytes
	push xiz	; 3e
	ld (xsp + 8), xbc	; LD (XSP+08h), XBC - save sector address
	ld (xsp + 12), a	; LD (XSP+0Ch), A - save target
	ld xwa, 0x280000	; 40 00 00 28 00
	cp (xsp + 12), 0x1	; CP (XSP+0Ch), 01h
	jr nz, Flash_SectorErase_16bit__got_base	; 6e 05
	ld xwa, 0x300000	; 40 00 00 30 00
Flash_SectorErase_16bit__got_base:
	ld xiz, xwa	; e8 8e
	; Mask sector address to get bank offset
	ld xwa, (xsp + 8)	; LD XWA, (XSP+08h)
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA
	ld xwa, 0xFF0000	; 40 00 00 ff 00
	and (xsp + 4), xwa	; AND (XSP+04h), XWA
	; Check region and bank for Custom Data
	call Get_Region_Code + 0x600000	; CALL Boot_Get_Region_Code (at 0xFFB700)
	cp l, 4:i3	; cf dc
	jr nz, Flash_SectorErase_16bit__do_erase	; 6e 11
	ld xwa, (xsp + 4)	; LD XWA, (XSP+04h)
	cp xwa, 0x380000	; e8 cf 00 00 38 00
	jr c, Flash_SectorErase_16bit__do_erase	; 67 06
	add xiz, 0x80000	; ee c8 00 00 08 00
Flash_SectorErase_16bit__do_erase:
	ei 6	; 06 06
	; Send sector erase sequence
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0x80	; LD (XWA), 0080h (word store)
	ld xwa, xiz	; ee 88
	add xwa, 0xAAAA	; e8 c8 aa aa 00 00
	ldw (xwa), 0xAA	; LD (XWA), 00AAh (word store)
	ldw	(xiz+21844), 0x0055	; LD (XIZ+5554h), 0055h
	; Send 0x30 to sector address
	ld xwa, (xsp + 4)	; LD XWA, (XSP+04h)
	ldw (xwa), 0x30	; LD (XWA), 0030h - Sector erase command (word store)

	; The rest of this routine handles special boot block sectors
	; This is complex sector layout handling for AM29F400B/AM29F800B

	; Check if Custom Data flash (target 1) with region code 4
	call Get_Region_Code + 0x600000	; CALL Boot_Get_Region_Code (0xFFB700)
	cp l, 4:i3	; cf dc
	jr nz, Flash_SectorErase_16bit__check_non_region4	; 6e 5f - skip if not region 4

	; Region 4: Check if Custom Data flash (target 1)
	cp (xsp + 12), 0x1	; CP (XSP+0Ch), 01h - check target
	jrl nz, Flash_SectorErase_16bit__sector_done	; JRL NZ, .sector_done - skip if HDAE

	; Custom Data region 4: Check 0x070000 and 0x0F0000 sectors
	lda xwa, (0x300000:24); f2 00 00 30 30
	ld xbc, xwa	; e8 89
	add xbc, 0x70000	; e9 c8 00 00 07 00
	cp xbc, (xsp + 4)	; CP XBC, (XSP+04h)
	jr z, Flash_SectorErase_16bit__erase_region4_boot	; 66 0e

	ld xbc, xwa	; e8 89
	add xbc, 0xF0000	; e9 c8 00 00 0f 00
	cp xbc, (xsp + 4)	; CP XBC, (XSP+04h)
	jrl nz, Flash_SectorErase_16bit__sector_done	; JRL NZ, .sector_done

Flash_SectorErase_16bit__erase_region4_boot:
	; Erase 8KB boot block sectors at 0x78000, 0x7A000, 0x7C000
	ld xbc, xiz	; ee 89
	add xbc, 0x78000	; e9 c8 00 80 07 00
	ldw (xbc), 0x30	; LD (XBC), 0030h (word store)
	ld xbc, xiz	; ee 89
	add xbc, 0x7A000	; e9 c8 00 a0 07 00
	ldw (xbc), 0x30	; LD (XBC), 0030h (word store)
	ld xbc, xiz	; ee 89
	add xbc, 0x7C000	; e9 c8 00 c0 07 00
	ldw (xbc), 0x30	; LD (XBC), 0030h (word store)

	; Check if sector address is at top of 1MB
	add xwa, 0xFFFFF	; e8 c8 ff ff 0f 00
	cp (xsp + 8), xwa	; CP (XSP+08h), XWA
	jrl nz, Flash_SectorErase_16bit__sector_done	; JRL NZ, .sector_done
	ld xwa, 0x60000	; 40 00 00 06 00
	jrl Flash_SectorErase_16bit__erase_last_sector	; JRL T, .erase_last_sector

Flash_SectorErase_16bit__check_non_region4:
	; Check target 1 (Custom Data) for non-region-4
	cp (xsp + 12), 0x1	; CP (XSP+0Ch), 01h
	jr nz, Flash_SectorErase_16bit__check_hdae	; 6e 6e - skip to HDAE handling

	; Custom Data (target 1) - check if AM29LV800B (0x2258)
	lda xwa, (0x300000:24); f2 00 00 30 30
	cpw (39316:24), 8792; CP (009994h), 2258h
	jr nz, Flash_SectorErase_16bit__custom_check_f0000	; 6e 1c

	; AM29LV800B: Check if base sector needs boot block erase
	cp xwa, (xsp + 4)	; CP XWA, (XSP+04h)
	jrl nz, Flash_SectorErase_16bit__sector_done	; JRL NZ, .sector_done

	; Erase 8KB sectors at 0x4000 and 0x6000
	ldw	(xiz+16384), 0x0030	; LD (XIZ+4000h), 0030h
	ldw	(xiz+24576), 0x0030	; LD (XIZ+6000h), 0030h
	ld xwa, 0x8000	; 40 00 80 00 00
	jrl Flash_SectorErase_16bit__erase_last_sector	; JRL T, .erase_last_sector

Flash_SectorErase_16bit__custom_check_f0000:
	; Custom Data: Check 0x0F0000 sector
	ld xbc, xwa	; e8 89
	add xwa, 0xF0000	; e8 c8 00 00 0f 00
	cp xwa, (xsp + 4)	; CP XWA, (XSP+04h)
	jrl nz, Flash_SectorErase_16bit__sector_done	; JRL NZ, .sector_done

	; Erase boot block sectors at 0xF8000, 0xFA000, 0xFC000
	ld xwa, xiz	; ee 88
	add xwa, 0xF8000	; e8 c8 00 80 0f 00
	ldw (xwa), 0x30	; LD (XWA), 0030h (word store)
	ld xwa, xiz	; ee 88
	add xwa, 0xFA000	; e8 c8 00 a0 0f 00
	ldw (xwa), 0x30	; LD (XWA), 0030h (word store)
	ld xwa, xiz	; ee 88
	add xwa, 0xFC000	; e8 c8 00 c0 0f 00
	ldw (xwa), 0x30	; LD (XWA), 0030h (word store)

	; Check if top sector
	add xbc, 0xFFFFF	; e9 c8 ff ff 0f 00
	cp (xsp + 8), xbc	; CP (XSP+08h), XBC
	jr nz, Flash_SectorErase_16bit__sector_done	; 6e 5f
	ld xwa, 0xE0000	; 40 00 00 0e 00
	jr Flash_SectorErase_16bit__erase_last_sector	; 68 50

Flash_SectorErase_16bit__check_hdae:
	; HDAE5000 (target 0) - check if AM29F400B (0x22AB)
	lda xwa, (0x280000:24); f2 00 00 28 30
	cpw (39318:24), 8875; CP (009996h), 22ABh
	jr nz, Flash_SectorErase_16bit__hdae_check_top	; 6e 1a

	; AM29F400B on HDAE: Check base sector
	cp xwa, (xsp + 4)	; CP XWA, (XSP+04h)
	jr nz, Flash_SectorErase_16bit__sector_done	; 6e 45

	; Erase 8KB boot block sectors at 0x4000 and 0x6000
	ldw	(xiz+16384), 0x0030	; LD (XIZ+4000h), 0030h
	ldw	(xiz+24576), 0x0030	; LD (XIZ+6000h), 0030h
	ld xwa, 0x8000	; 40 00 80 00 00
	jr Flash_SectorErase_16bit__erase_last_sector	; 68 28

Flash_SectorErase_16bit__hdae_check_top:
	; HDAE: Check 0x070000 sector (XWA already = 0x280000)
	add xwa, 0x70000	; e8 c8 00 00 07 00
	cp xwa, (xsp + 4)	; CP XWA, (XSP+04h)
	jr nz, Flash_SectorErase_16bit__sector_done	; 6e 25

	; Erase boot block sectors at 0x78000, 0x7A000
	ld xwa, xiz	; ee 88
	add xwa, 0x78000	; e8 c8 00 80 07 00
	ldw (xwa), 0x30	; LD (XWA), 0030h (word store)
	ld xwa, xiz	; ee 88
	add xwa, 0x7A000	; e8 c8 00 a0 07 00
	ldw (xwa), 0x30	; LD (XWA), 0030h (word store)
	ld xwa, 0x7C000	; 40 00 c0 07 00

Flash_SectorErase_16bit__erase_last_sector:
	; Common code to erase the last 8KB sector
	; XWA = sector offset within bank
	ld xbc, xiz	; ee 89
	add xbc, xwa	; e8 81
	ldw (xbc), 0x30	; LD (XBC), 0030h (word store)

Flash_SectorErase_16bit__sector_done:
	ei 0	; 06 00
	pop xiz	; 5e
	lda xsp, (xsp + 10)	; LDA XSP, XSP+0Ah - deallocate stack
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_WaitComplete - Wait for flash operation to complete
; Address: 0x9FBBCF
;
; Purpose: Poll bit 5 of port 0x1C until flash operation completes
;
; Entry: None
; Exit: HL = 0 if success, 0xFFFF if still busy
; -----------------------------------------------------------------------------
Flash_WaitComplete:
	bit_dd8 5, 0x1C	; f0 1c cd
	jr z, Flash_WaitComplete__not_ready	; 66 03
	ld hl, 0:i3	; db a8
	ret	; 0e
Flash_WaitComplete__not_ready:
	ldw hl, 0xFFFF	; 33 ff ff
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_ChipErase_16bit_Wait - Erase chip and wait for completion
; Address: 0x9FBBDB
;
; Purpose: Call Flash_ChipErase_16bit and poll until complete
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
; Exit: None
; -----------------------------------------------------------------------------
Flash_ChipErase_16bit_Wait:
	extz wa	; d8 12
	calr Flash_ChipErase_16bit	; CALR Flash_ChipErase_16bit (0x9FB968)
Flash_ChipErase_16bit_Wait__wait_loop:
	calr Flash_WaitComplete	; CALR Flash_WaitComplete (0x9FBBCF)
	cp hl, 0xFFFF	; db cf ff ff
	ret nz	; b0 fe
Flash_ChipErase_16bit_Wait__recheck:
	calr Flash_WaitComplete	; CALR Flash_WaitComplete
	cp hl, 0xFFFF	; db cf ff ff
	jr z, Flash_ChipErase_16bit_Wait__recheck	; JR Z, recheck
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_Init_Custom_And_Table - Initialize Custom Data and Table Data flash
; Address: 0x9FBBF3
;
; Purpose: Send reset to Custom Data flash and read IDs for both flashes
;
; Entry: None
; Exit: (0x9994) = Custom Data device ID
;       (0x9996) = HDAE5000 device ID
; -----------------------------------------------------------------------------
Flash_Init_Custom_And_Table:
	ld wa, 1:i3	; d8 a9 - Custom Data low bank
	calr Flash_Reset_16bit	; CALR Flash_Reset_16bit (0x9FB812)
	ld wa, 2:i3	; d8 aa - Custom Data high bank
	calr Flash_Reset_16bit	; CALR Flash_Reset_16bit (0x9FB812)

	; Check region and reset Table Data ROM if not region 4
	call Get_Region_Code + 0x600000	; CALL Boot_Get_Region_Code (0xFFB700)
	cp l, 4:i3	; cf dc
	call nz, (Flash_Reset_32bit + 0x600000:24)	; CALL NZ, Flash_Reset_32bit (0xFFBC2D)

	; Read Custom Data device ID
	ld wa, 1:i3	; d8 a9
	calr Flash_ReadID_16bit	; CALR Flash_ReadID_16bit (0x9FB888)
	ld (0x009994:24), hl; LD (009994h), HL

	; Read HDAE5000 device ID
	ld wa, 2:i3	; d8 aa
	calr Flash_ReadID_16bit	; CALR Flash_ReadID_16bit (0x9FB888)
	ld (0x009996:24), hl; LD (009996h), HL
	ret	; 0e

; -----------------------------------------------------------------------------
; MemBlock_FillWithZeros - Clear a memory block with zeros
; Address: 0x9FBC1D
;
; Purpose: Fill memory from XWA for BC dwords with zeros
;
; Entry: XWA = destination address
;        BC = count (dwords)
; Exit: XWA = address after filled region
;       DE = BC (loop counter)
; -----------------------------------------------------------------------------
MemBlock_FillWithZeros:
	ld de, 0:i3	; da a8
	cp bc, 0:i3	; d9 d8
	ret ule	; b0 f3 - return if count <= 0
MemBlock_FillWithZeros__fill_loop:
	ld (xwa+), DE	; LD (XWA+), DE - store 0 and advance
	inc 1, de	; da 61
	cp de, bc	; d9 f2
	jr c, MemBlock_FillWithZeros__fill_loop	; 67 f7
	ret	; 0e


; =============================================================================
; 32-BIT FLASH PROGRAMMING ROUTINES
; =============================================================================
; These routines operate on the interleaved Table Data ROM using 32-bit bus access.
; The ROM uses two interleaved 16-bit flash chips:
;   - IC1 (odd bytes) and IC3 (even bytes)
;
; Address Translation (16-bit -> 32-bit):
;   16-bit 0x5555 -> 32-bit 0x15554 (bit 16 set due to A16 routing)
;   16-bit 0x2AAA -> 32-bit 0x0AAA8
;
; Data values use 32-bit interleaved format:
;   16-bit 0xAA   -> 32-bit 0x00AA00AA (same byte to both chips)
;   16-bit 0x55   -> 32-bit 0x00550055
;   16-bit 0xF0   -> 32-bit 0x00F000F0
; =============================================================================

; -----------------------------------------------------------------------------
; Flash_Reset_32bit - Reset Table Data ROM flash chips
; Address: 0x9FBC2D (boot-time: 0xFFBC2D)
;
; Purpose: Send software reset command to both interleaved flash chips
;
; Entry: None
; Exit: XWA = data read from base+0x6464 (completion cycle)
;
; Sequence:
;   Write 0x00AA00AA to base+0x15554 (unlock 1)
;   Write 0x00550055 to base+0x0AAA8 (unlock 2)
;   Write 0x00F000F0 to base+0x15554 (reset command)
;   Read any address to complete cycle
; -----------------------------------------------------------------------------
Flash_Reset_32bit:
	ld xde, TD_FLASH_BASE	; Table Data ROM base address
Flash_Reset_32bit__wait_ready:
	bit_dd8 5, 0x1C	; Wait for P3 bit 5 (flash ready)
	jr z, Flash_Reset_32bit__wait_ready

	ld xbc, xde	; XBC = base
	add xbc, 0x15554	; XBC = base + unlock addr 1
	ld xwa, FLASH2_CMD_UNLOCK1	; Unlock value 1 (both chips)
	ld (xbc), xwa	; Write unlock

	ld xbc, xde	; Reset XBC
	add xbc, 0xAAA8	; XBC = base + unlock addr 2
	ld xwa, FLASH2_CMD_UNLOCK2	; Unlock value 2 (both chips)
	ld (xbc), xwa	; Write unlock

	ld xbc, xde	; Reset XBC
	add xbc, 0x15554	; XBC = base + command addr
	ld xwa, FLASH2_CMD_RESET	; Software reset command (both chips)
	ld (xbc), xwa	; Send reset

	ld XWA, (xde + 0x6464)             ; LD XWA, (XDE+6464h) - completion read
	ret

; -----------------------------------------------------------------------------
; Flash_ReadID_32bit - Read Table Data ROM flash IDs
; Address: 0x9FBC6A (boot-time: 0xFFBC6A)
;
; Purpose: Read manufacturer and device IDs from both flash chips
;
; Entry: None
; Exit: XHL = device ID if valid, 0xFFFFFFFF if not recognized
;
; Validated Device IDs:
;   0x22D622D6 - AM29F800B (both chips)
;   0x22582258 - AM29LV800B (both chips)
;
; Manufacturer IDs:
;   0x00010001 - AMD/Spansion (both chips)
;   0x00040004 - Fujitsu (both chips)
; -----------------------------------------------------------------------------
Flash_ReadID_32bit:
	dec 8, xsp	; DEC 0, XSP - allocate 8 bytes
	push xiz	; Save XIZ

	ld xwa, 0xFFFFFFFF	; Default: invalid
	ld (xsp + 8), xwa	; LD (XSP+08h), XWA - save default

	ei 6	; Disable lower-priority interrupts

	; Send ID read command sequence
	ld xwa, FLASH2_CMD_UNLOCK1	; Unlock 1
	ld (TD_FLASH_UNLOCK1:24), xwa; LD (815554h), XWA

	ld xwa, FLASH2_CMD_UNLOCK2	; Unlock 2
	ld (TD_FLASH_UNLOCK2:24), xwa; LD (80AAA8h), XWA

	ld xwa, FLASH2_CMD_AUTOSELECT	; ID read command
	ld (TD_FLASH_UNLOCK1:24), xwa; LD (815554h), XWA

	; Read manufacturer ID from base address
	ld xwa, (TD_FLASH_BASE:24); LD XWA, (800000h)
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA - save mfr ID

	; Read device ID from base+4
	ld xwa, TD_FLASH_BASE
	ld xiz, (xwa + 4)	; LD XIZ, (XWA+04h)

	ei 0	; Re-enable interrupts

	; Validate manufacturer ID
	ld xwa, (xsp + 4)	; LD XWA, (XSP+04h) - get mfr ID
	cp xwa, 0x10001	; AMD?
	jr z, Flash_ReadID_32bit__check_device
	cp xwa, 0x40004	; Fujitsu?
	jr nz, Flash_ReadID_32bit__done

Flash_ReadID_32bit__check_device:
	cp xiz, 0x22D622D6	; AM29F800B?
	jr z, Flash_ReadID_32bit__valid_device
	cp xiz, 0x22582258	; AM29LV800B?
	jr nz, Flash_ReadID_32bit__call_reset

Flash_ReadID_32bit__valid_device:
	ld (xsp + 8), xiz	; LD (XSP+08h), XIZ - store device ID

Flash_ReadID_32bit__call_reset:
	calr Flash_Reset_32bit	; Exit ID mode

Flash_ReadID_32bit__done:
	ld xhl, (xsp + 8)	; LD XHL, (XSP+08h) - return device ID
	pop xiz
	inc 8, xsp	; INC 0, XSP - deallocate 8 bytes
	ret

; -----------------------------------------------------------------------------
; Flash_ProgramWord_32bit - Program 32-bit word to Table Data ROM
; Address: 0x9FBCD7 (boot-time: 0xFFBCD7)
;
; Entry: XWA = destination address
;        XBC = data (32 bits, interleaved for both chips)
; Exit: None
;
; Notes:
;   - Skips programming if data = 0xFFFFFFFF (erased state)
;   - Writes unlock sequence, then 0xA0 program command
;   - Data is written directly to destination address
; -----------------------------------------------------------------------------
Flash_ProgramWord_32bit:
	dec 4, xsp	; DEC 4, XSP - allocate 4 bytes
	push xiz	; Save XIZ

	ld xiz, xbc	; XIZ = data
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA - save dest addr

	cp xiz, 0xFFFFFFFF	; Is data erased state?
	jr z, Flash_ProgramWord_32bit__skip_program	; Yes, skip

Flash_ProgramWord_32bit__wait_ready:
	bit_dd8 5, 0x1C	; Wait for flash ready
	jr z, Flash_ProgramWord_32bit__wait_ready

	ei 6	; Disable lower-priority interrupts

	; Send program command sequence
	ld xwa, FLASH2_CMD_UNLOCK1	; Unlock 1
	ld (TD_FLASH_UNLOCK1:24), xwa; LD (815554h), XWA

	ld xwa, FLASH2_CMD_UNLOCK2	; Unlock 2
	ld (TD_FLASH_UNLOCK2:24), xwa; LD (80AAA8h), XWA

	ld xwa, FLASH2_CMD_PROGRAM	; Program command
	ld (TD_FLASH_UNLOCK1:24), xwa; LD (815554h), XWA

	; Write data to destination
	ld xwa, (xsp + 4)	; LD XWA, (XSP+04h) - get dest addr
	ld (xwa), xiz	; LD (XWA), XIZ - write data

	ei 0	; Re-enable interrupts

Flash_ProgramWord_32bit__skip_program:
	pop xiz
	inc 4, xsp	; INC 4, XSP - deallocate 4 bytes
	ret

; -----------------------------------------------------------------------------
; Flash_ChipErase_32bit - Erase Table Data ROM
; Address: 0x9FBD17 (boot-time: 0xFFBD17)
;
; Purpose: Erase entire Table Data ROM (both flash chips)
;
; Entry: None
; Exit: None
;
; Uses standard 6-byte chip erase sequence:
;   1. base+0x15554 = 0x00AA00AA (unlock 1)
;   2. base+0x0AAA8 = 0x00550055 (unlock 2)
;   3. base+0x15554 = 0x00800080 (erase setup)
;   4. base+0x15554 = 0x00AA00AA (unlock 1)
;   5. base+0x0AAA8 = 0x00550055 (unlock 2)
;   6. base+0x15554 = 0x00100010 (chip erase command)
; -----------------------------------------------------------------------------
Flash_ChipErase_32bit:
	push xiz
	ld xiz, TD_FLASH_BASE	; Table Data ROM base

	ei 6	; Disable lower-priority interrupts

	; Unlock sequence 1
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH2_CMD_UNLOCK1
	ld (xbc), xwa

	; Unlock sequence 2
	ld xbc, xiz
	add xbc, 0xAAA8
	ld xwa, FLASH2_CMD_UNLOCK2
	ld (xbc), xwa

	; Erase setup command
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH2_CMD_ERASE_SETUP
	ld (xbc), xwa

	; Unlock sequence 1 (again)
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH2_CMD_UNLOCK1
	ld (xbc), xwa

	; Unlock sequence 2 (again)
	ld xbc, xiz
	add xbc, 0xAAA8
	ld xwa, FLASH2_CMD_UNLOCK2
	ld (xbc), xwa

	; Chip erase command
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH2_CMD_CHIP_ERASE
	ld (xbc), xwa

	ei 0	; Re-enable interrupts

	pop xiz
	ret

; -----------------------------------------------------------------------------
; Flash_SectorErase_32bit - Erase all Table Data ROM sectors
; Address: 0x9FBD7D (boot-time: 0xFFBD7D)
;
; Purpose: Erase all 18 sectors in the 2MB Table Data ROM
;          Uses sector erase (0x30) instead of chip erase (0x10)
;
; Entry: None
; Exit: None
;
; Sector layout (2MB = 32 x 64KB sectors in each interleaved chip):
;   0x00000, 0x20000, 0x40000, 0x60000, 0x80000, 0xA0000, 0xC0000, 0xE0000,
;   0x100000, 0x120000, 0x140000, 0x160000, 0x180000, 0x1A0000, 0x1C0000,
;   0x1E0000, 0x1F0000, 0x1F4000 (boot sectors at top)
; -----------------------------------------------------------------------------
Flash_SectorErase_32bit:
	push xiz	; 3e
	ld xiz, TD_FLASH_BASE	; 46 00 00 80 00 - Table Data base
	ei 6	; 06 06 - disable lower-priority IRQs

	; Send erase setup sequence
	ld xbc, xiz	; ee 89
	add xbc, 0x15554	; e9 c8 54 55 01 00
	ld xwa, FLASH2_CMD_UNLOCK1	; 40 aa 00 aa 00 - Unlock 1
	ld (xbc), xwa	; b1 60

	ld xbc, xiz	; ee 89
	add xbc, 0xAAA8	; e9 c8 a8 aa 00 00
	ld xwa, FLASH2_CMD_UNLOCK2	; 40 55 00 55 00 - Unlock 2
	ld (xbc), xwa	; b1 60

	ld xbc, xiz	; ee 89
	add xbc, 0x15554	; e9 c8 54 55 01 00
	ld xwa, FLASH2_CMD_ERASE_SETUP	; 40 80 00 80 00 - Erase setup
	ld (xbc), xwa	; b1 60

	ld xbc, xiz	; ee 89
	add xbc, 0x15554	; e9 c8 54 55 01 00
	ld xwa, FLASH2_CMD_UNLOCK1	; 40 aa 00 aa 00 - Unlock 1
	ld (xbc), xwa	; b1 60

	ld xbc, xiz	; ee 89
	add xbc, 0xAAA8	; e9 c8 a8 aa 00 00
	ld xwa, FLASH2_CMD_UNLOCK2	; 40 55 00 55 00 - Unlock 2
	ld (xbc), xwa	; b1 60

	; Now send 0x30 sector erase command to each sector
	ld xwa, FLASH2_CMD_SECTOR_ERASE	; 40 30 00 30 00 - Sector erase cmd
	ld (xiz), xwa	; b6 60 - Sector 0

	ld xbc, xiz	; ee 89
	add xbc, 0x20000	; e9 c8 00 00 02 00
	ld (xbc), xwa	; b1 60 - Sector 0x20000

	ld xbc, xiz	; ee 89
	add xbc, 0x40000	; e9 c8 00 00 04 00
	ld (xbc), xwa	; b1 60 - Sector 0x40000

	ld xbc, xiz	; ee 89
	add xbc, 0x60000	; e9 c8 00 00 06 00
	ld (xbc), xwa	; b1 60 - Sector 0x60000

	ld xbc, xiz	; ee 89
	add xbc, 0x80000	; e9 c8 00 00 08 00
	ld (xbc), xwa	; b1 60 - Sector 0x80000

	ld xbc, xiz	; ee 89
	add xbc, 0xA0000	; e9 c8 00 00 0a 00
	ld (xbc), xwa	; b1 60 - Sector 0xA0000

	ld xbc, xiz	; ee 89
	add xbc, 0xC0000	; e9 c8 00 00 0c 00
	ld (xbc), xwa	; b1 60 - Sector 0xC0000

	ld xbc, xiz	; ee 89
	add xbc, 0xE0000	; e9 c8 00 00 0e 00
	ld (xbc), xwa	; b1 60 - Sector 0xE0000

	ld xbc, xiz	; ee 89
	add xbc, 0x100000	; e9 c8 00 00 10 00
	ld (xbc), xwa	; b1 60 - Sector 0x100000

	ld xbc, xiz	; ee 89
	add xbc, 0x120000	; e9 c8 00 00 12 00
	ld (xbc), xwa	; b1 60 - Sector 0x120000

	ld xbc, xiz	; ee 89
	add xbc, 0x140000	; e9 c8 00 00 14 00
	ld (xbc), xwa	; b1 60 - Sector 0x140000

	ld xbc, xiz	; ee 89
	add xbc, 0x160000	; e9 c8 00 00 16 00
	ld (xbc), xwa	; b1 60 - Sector 0x160000

	ld xbc, xiz	; ee 89
	add xbc, 0x180000	; e9 c8 00 00 18 00
	ld (xbc), xwa	; b1 60 - Sector 0x180000

	ld xbc, xiz	; ee 89
	add xbc, 0x1A0000	; e9 c8 00 00 1a 00
	ld (xbc), xwa	; b1 60 - Sector 0x1A0000

	ld xbc, xiz	; ee 89
	add xbc, 0x1C0000	; e9 c8 00 00 1c 00
	ld (xbc), xwa	; b1 60 - Sector 0x1C0000

	ld xbc, xiz	; ee 89
	add xbc, 0x1E0000	; e9 c8 00 00 1e 00
	ld (xbc), xwa	; b1 60 - Sector 0x1E0000

	ld xbc, xiz	; ee 89
	add xbc, 0x1F0000	; e9 c8 00 00 1f 00
	ld (xbc), xwa	; b1 60 - Sector 0x1F0000 (boot area)

	ld xbc, xiz	; ee 89
	add xbc, 0x1F4000	; e9 c8 00 40 1f 00
	ld (xbc), xwa	; b1 60 - Sector 0x1F4000 (boot area)

	ei 0	; 06 00 - re-enable interrupts
	pop xiz	; 5e
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_WaitComplete_32bit - Wait for flash operation to complete
; Address: 0x9FBE85 (boot-time: 0xFFBE85)
;
; Purpose: Poll bit 5 of port 0x1C until flash operation completes
;
; Entry: None
; Exit: HL = 0 if success, 0xFFFF if still busy
; -----------------------------------------------------------------------------
Flash_WaitComplete_32bit:
	bit_dd8 5, 0x1C	; f0 1c cd
	jr z, Flash_WaitComplete_32bit__not_ready	; 66 03
	ld hl, 0:i3	; db a8
	ret	; 0e
Flash_WaitComplete_32bit__not_ready:
	ldw hl, 0xFFFF	; 33 ff ff
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_ChipErase_32bit_Wait - Erase chip and wait for completion
; Address: 0x9FBE91 (boot-time: 0xFFBE91)
;
; Purpose: Call Flash_ChipErase_32bit and poll until complete
;
; Entry: None
; Exit: None
; -----------------------------------------------------------------------------
Flash_ChipErase_32bit_Wait:
	calr Flash_ChipErase_32bit	; CALR Flash_ChipErase_32bit (0x9FBD17)
Flash_ChipErase_32bit_Wait__wait_loop:
	calr Flash_WaitComplete_32bit	; CALR Flash_WaitComplete_32bit (0x9FBE85)
	cp hl, 0xFFFF	; db cf ff ff
	ret nz	; b0 fe
Flash_ChipErase_32bit_Wait__recheck:
	calr Flash_WaitComplete_32bit	; CALR Flash_WaitComplete_32bit
	cp hl, 0xFFFF	; db cf ff ff
	jr z, Flash_ChipErase_32bit_Wait__recheck	; JR Z, recheck
	ret	; 0e

; -----------------------------------------------------------------------------
; Flash_Update_TableData - Update Table Data ROM from RAM buffer
; Address: 0x9FBEA7 (boot-time: 0xFFBEA7)
;
; Purpose: High-level routine to update entire Table Data ROM
;
; Entry: Source data at RAM 0x080000 (8000 dwords = 32KB)
; Exit: HL = 0 if success, 0xFFFF if flash not detected
;
; Process:
;   1. Read flash device ID to verify hardware
;   2. Erase entire Table Data ROM
;   3. Copy 8000 dwords from RAM 0x080000 to flash 0x800000
;   4. Wait for completion
; -----------------------------------------------------------------------------
Flash_Update_TableData:
	dec 4, xsp	; DEC 4, XSP - allocate 4 bytes
	push xiz	; 3e

	ld xwa, 0x80000	; 40 00 00 08 00 - source RAM addr
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA - save src ptr

	; Verify flash is present by reading device ID
	calr Flash_ReadID_32bit	; CALR Flash_ReadID_32bit (0x9FBC6A)
	cp xhl, 0xFFFFFFFF	; eb cf ff ff ff ff
	jr nz, Flash_Update_TableData__flash_detected	; 6e 05

	ldw hl, 0xFFFF	; 33 ff ff - error: no flash
	jr Flash_Update_TableData__done	; 68 41

Flash_Update_TableData__flash_detected:
	; Erase Table Data ROM
	calr Flash_ChipErase_32bit	; CALR Flash_ChipErase_32bit (0x9FBD17)

	; Initialize destination and count
	ld xwa, 0x80000	; 40 00 00 08 00 - reinit src ptr
	ld xbc, 0x10000	; 41 00 00 01 00 - count = 64K dwords
	call MemBlock_FillWithZeros + 0x600000	; CALL MemBlock_FillWithZeros (0xFFBC1D)

	; Wait for erase to complete
Flash_Update_TableData__wait_erase:
	calr Flash_WaitComplete_32bit	; CALR Flash_WaitComplete_32bit (0x9FBE85)
	cp hl, 0xFFFF	; db cf ff ff
	jr nz, Flash_Update_TableData__program_loop_start	; 6e 09
Flash_Update_TableData__wait_erase_loop:
	calr Flash_WaitComplete_32bit	; CALR Flash_WaitComplete_32bit (0x9FBE85)
	cp hl, 0xFFFF	; db cf ff ff
	jr z, Flash_Update_TableData__wait_erase_loop	; JR Z, .wait_erase_loop

Flash_Update_TableData__program_loop_start:
	ld xiz, 0:i3	; ee a8 - dest offset counter

Flash_Update_TableData__program_loop:
	ld xwa, (xsp + 4)	; LD XWA, (XSP+04h) - get src ptr
	lda xbc, (xwa+:4)	; LDA XBC, XWA+ - load data, advance ptr
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA - save updated ptr

	ld xwa, xbc	; e9 88 - XWA = data
	ld xbc, xiz	; ee 89 - XBC = dest offset
	calr Flash_ProgramWord_32bit	; CALR Flash_ProgramWord_32bit (0x9FBCD7)

	inc 1, xiz	; ee 61 - next dword
	cp xiz, 0x1F40	; ee cf 40 1f 00 00 - 8000 dwords
	jr c, Flash_Update_TableData__program_loop	; 67 e6

	ld hl, 0:i3	; db a8 - success
Flash_Update_TableData__done:
	pop xiz	; 5e
	inc 4, xsp	; INC 4, XSP - deallocate 4 bytes
	ret	; 0e

; =============================================================================
; BOOT ROM FDC ROUTINES
; =============================================================================
; FDC routines for reading firmware update data from floppy disk during
; boot-time recovery mode.
; =============================================================================

; -----------------------------------------------------------------------------
; FDC_Reset - Initialize FDC controller for update mode
; Address: 0x9FBF07 (boot-time: 0xFFBF07)
;
; Purpose: Set up FDC parameters for reading update disks
;
; Stack frame (16 bytes at XSP):
;   +0x00: Drive number (0)
;   +0x02: Reserved (0)
;   +0x04: Reserved (0)
;   +0x06: Data rate (0x00D3 = 500kbps HD)
;   +0x08: Sectors per track (1)
;   +0x0A: Heads (1)
;   +0x0C: Reserved (0)
;
; Entry: None
; Exit: FDC initialized
; -----------------------------------------------------------------------------
FDC_Reset:
	lda xsp, (xsp - 16)	; LDA XSP, XSP+F0h - allocate 16 bytes
	lda xbc, (xsp)	; LDA XBC, XSP - XBC points to params
	ldw (xbc), 0x0	; LD (XBC), 0000h - drive 0
	ldw (xbc + 2), 0x0	; LD (XBC+02h), 0000h
	ldw (xbc + 4), 0x0	; LD (XBC+04h), 0000h
	ldw (xbc + 6), 0xD3	; LD (XBC+06h), 00D3h - data rate
	ldw (xbc + 8), 0x1	; LD (XBC+08h), 0001h - sectors/track
	ldw (xbc + 10), 0x1	; LD (XBC+0Ah), 0001h - heads
	ld xwa, 0:i3	; e8 a8
	ld (xbc + 12), xwa	; LD (XBC+0Ch), XWA
	push xbc	; 39
	call FDC_Request + 0x600000	; CALL 0xFFE944 (FDC_Init)
	lda xsp, (xsp + 20)	; LDA XSP, XSP+14h - deallocate 20 bytes
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_ReadSector - Read a single sector from floppy
; Address: 0x9FBF37 (boot-time: 0xFFBF37)
;
; Entry: XWA = sector info (passed to FDC driver)
;        BC = sector number
;        XDE = destination buffer
;
; Exit: HL = result (0 = success)
;
; Calculates head/track from linear sector number:
;   Track = sector_number >> 1
;   Head = sector_number & 1
;
; Uses FDC parameters at RAM 0x0C10
; -----------------------------------------------------------------------------
FDC_ReadSector:
	lda xsp, (xsp - 14)	; LDA XSP, XSP+F2h - allocate 14 bytes
	push xiz	; 3e
	ld (xsp + 8), xde	; LD (XSP+08h), XDE - save dest buffer
	ld (xsp + 12), bc	; LD (XSP+0Ch), BC - save sector num
	ld (xsp + 14), xwa	; LD (XSP+0Eh), XWA - save sector info
	ld xwa, (xsp + 14)	; LD XWA, (XSP+0Eh)
	ld xbc, 0x12	; 41 12 00 00 00 - param size
	call Boot_UDivMod32 + 0x600000	; CALL 0xFFFC63
	lda xiz, (3088:16); LDA XIZ, 0x0C10 - FDC params in RAM
	ldw (xiz + 2), 0x0	; LD (XIZ+02h), 0000h
	ld wa, hl	; LD WA, HL
	srl wa, 1	; SRL 1, WA - track = sector >> 1
	ld (xiz + 6), wa	; LD (XIZ+06h), WA - store track
	and hl, 0x1	; AND HL, 0001h - head = sector & 1
	ld (xiz + 4), hl	; LD (XIZ+04h), HL - store head
	lda xwa, (xiz + 8)	; LDA XWA, (XIZ+08h)
	ld (xsp + 4), xwa	; LD (XSP+04h), XWA
	ld xwa, (xsp + 14)	; LD XWA, (XSP+0Eh)
	ld xbc, 0x12	; 41 12 00 00 00
	call Boot_UMod32 + 0x600000	; CALL 0xFFFC5D
	inc 1, xhl	; INC 1, XHL
	ld xwa, (xsp + 4)	; LD XWA, (XSP+04h)
	ld (xwa), hl	; LD (XWA), HL
	ld wa, (xsp + 12)	; LD WA, (XSP+0Ch) - sector num
	ld (xiz + 10), wa	; LD (XIZ+0Ah), WA
	ld xwa, (xsp + 8)	; LD XWA, (XSP+08h) - dest buffer
	ld (xiz + 12), xwa	; LD (XIZ+0Ch), XWA
	pop xiz	; 5e
	lda xsp, (xsp + 14)	; LDA XSP, XSP+0Eh - deallocate
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_ReadSectorWrapper - Wrapper for sector read with retry
; Address: 0x9FBF92 (boot-time: 0xFFBF92)
;
; Entry: XWA = sector info
;        BC = sector number
;        XDE = destination buffer
;
; Exit: HL = result
; -----------------------------------------------------------------------------
FDC_ReadSectorWrapper:
	dec 6, xsp	; DEC 6, XSP - allocate 6 bytes
	push xiz	; 3e
	ld (xsp + 4), xde	; LD (XSP+04h), XDE
	ld (xsp + 8), bc	; LD (XSP+08h), BC
	ld xiz, xwa	; e8 8e - save sector info
FDC_ReadSectorWrapper__retry:
	ld xwa, xiz	; ee 88
	ld bc, (xsp + 8)	; LD BC, (XSP+08h)
	ld xde, (xsp + 4)	; LD XDE, (XSP+04h)
	calr FDC_ReadSector	; CALR FDC_ReadSector
	lda xwa, (3088:16); LDA XWA, 0x0C10
	ldw (xwa), 0x3	; LD (XWA), 0003h
	push xwa	; 38
	call FDC_Request + 0x600000	; CALL 0xFFE944
	inc 4, xsp	; INC 4, XSP - deallocate
	cp hl, 0:i3	; CP HL, 0
	jr z, FDC_ReadSectorWrapper__read_ok	; 66 05 - skip retry if success

	; Read failed, try FDC reset and retry
	calr FDC_Reset	; CALR FDC_Reset (0x9FBF07)
	jr t, FDC_ReadSectorWrapper__retry	; JR T, retry from start

FDC_ReadSectorWrapper__read_ok:
	pop xiz	; 5e
	inc 6, xsp	; INC 6, XSP - deallocate
	ret	; 0e

; -----------------------------------------------------------------------------
; Boot_DetectDiskType - Detect firmware update disk type
; Address: 0x9FBFC4 (boot-time: 0xFFBFC4)
;
; Purpose: Read boot sector and check for known disk signatures at various
;          offsets to determine the disk type (1-8) or unknown (0xFF)
;
; Signature offsets checked:
;   0xA000 -> type 1    0xA0A0 -> type 4    0xA118 -> type 6
;   0xA028 -> type 2    0xA0F0 -> type 5    0xA050 -> type 7
;   0xA078 -> type 3    0xA0C8 -> type 8
;
; Entry: None
; Exit: L = disk type (1-8) or 0xFF if unknown
; -----------------------------------------------------------------------------
Boot_DetectDiskType:
	dec 2, xsp	; DEC 2, XSP - allocate 2 bytes
	push xiz	; 3e
	ld (xsp + 4), 0xFF	; LD (XSP+04h), 0xFF - default type
	pushw 0x200	; PUSH 0200h - sector size
	call Boot_malloc + 0x600000	; CALL 0xFFFB56 - allocate buffer
	inc 2, xsp	; INC 2, XSP - pop arg
	ld xiz, xhl	; LD XIZ, XHL - save buffer ptr
	ld xwa, 0x21	; 40 21 00 00 00 - sector 33 (boot sector)
	ld bc, 1:i3	; LD BC, 1 - read 1 sector
	ld xde, xiz	; ee 8a - dest buffer
	calr FDC_ReadSectorWrapper	; CALR FDC_ReadSectorWrapper

	; Check signature at offset 0xA000 -> type 1
	pushw 0x26	; PUSH 0026h - signature length
	pushw 0xFF	; PUSH 00FFh - high word of the pointer 0x00FFA000 = boot alias of FileIdentifierStringsTable
	pushw 0xA000	; PUSH 0A000h - offset
	push xiz	; 3e - buffer ptr
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC - check signature
	add xsp, 0xA	; ADD XSP, 0Ah - pop 10 bytes
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type2	; 6e 07
	ld (xsp + 4), 0x1	; LD (XSP+04h), 01h - type 1
	jrl Boot_DetectDiskType__done	; JRL T, .done

Boot_DetectDiskType__check_type2:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA028	; PUSH 0A028h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type3	; 6e 07
	ld (xsp + 4), 0x2	; LD (XSP+04h), 02h - type 2
	jrl Boot_DetectDiskType__done	; JRL T, .done

Boot_DetectDiskType__check_type3:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA078	; PUSH 0A078h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type4	; 6e 07
	ld (xsp + 4), 0x3	; LD (XSP+04h), 03h - type 3
	jrl Boot_DetectDiskType__done	; JRL T, .done

Boot_DetectDiskType__check_type4:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA0A0	; PUSH 0A0A0h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type5	; 6e 06
	ld (xsp + 4), 0x4	; LD (XSP+04h), 04h - type 4
	jr Boot_DetectDiskType__done	; JR T, .done

Boot_DetectDiskType__check_type5:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA0F0	; PUSH 0A0F0h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type6	; 6e 06
	ld (xsp + 4), 0x5	; LD (XSP+04h), 05h - type 5
	jr Boot_DetectDiskType__done	; JR T, .done

Boot_DetectDiskType__check_type6:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA118	; PUSH 0A118h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type7	; 6e 06
	ld (xsp + 4), 0x6	; LD (XSP+04h), 06h - type 6
	jr Boot_DetectDiskType__done	; JR T, .done

Boot_DetectDiskType__check_type7:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA050	; PUSH 0A050h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__check_type8	; 6e 06
	ld (xsp + 4), 0x7	; LD (XSP+04h), 07h - type 7
	jr Boot_DetectDiskType__done	; JR T, .done

Boot_DetectDiskType__check_type8:
	pushw 0x26	; PUSH 0026h
	pushw 0xFF	; PUSH 00FFh
	pushw 0xA0C8	; PUSH 0A0C8h - offset
	push xiz	; 3e
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC
	add xsp, 0xA	; ADD XSP, 0Ah
	cp hl, 0:i3	; CP HL, 0
	jr nz, Boot_DetectDiskType__done	; 6e 04
	ld (xsp + 4), 0x8	; LD (XSP+04h), 08h - type 8

Boot_DetectDiskType__done:
	push xiz	; 3e - free buffer
	call Boot_free + 0x600000	; CALL 0xFFFCDD - free memory
	inc 4, xsp	; INC 4, XSP
	ld l, (xsp + 4)	; LD L, (XSP+04h) - return type
	pop xiz	; 5e
	inc 2, xsp	; INC 2, XSP - deallocate
	ret	; 0e

; =============================================================================
; BOOT SECTOR COPY ROUTINES (0x9FC0E1-0x9FC212)
; =============================================================================
; Boot_CopySectors - Copy sectors from disk to RAM with callback
; Parameters:
;   XBC = destination address pointer (address table)
;   WA  = starting sector number
; Calls 0xFFBF92 to read sector, 0xFFBCD7 to write with callback
; =============================================================================

Boot_CopySectors:
	lda xsp, (xsp - 16)	; LDA XSP, XSP+0xF0 - allocate 16 bytes
	push xiz	; 3e
	ld (xsp + 14), xbc	; LD (XSP+0x0E), XBC - save dest ptr
	ld (xsp + 18), wa	; LD (XSP+0x12), WA - save start sector
	ld wa, (xsp + 18)	; LD WA, (XSP+0x12)
	ld (xsp + 6), wa	; LD (XSP+0x06), WA - current sector
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	div wa, 0x12	; DIV WA, 0x0012 - sectors per track
	ldto_werp WA, 0xE2	; LD WA, QWA - get remainder
	ld iz, 0:i3	; LD IZ, 0 - offset = 0
	cp wa, 0:i3	; CP WA, 0
	jr z, Boot_CopySectors__cs_skip_partial	; 66 48

	; Handle partial first track
	ldw iz, 0x12	; LD IZ, 0x0012 - sectors per track
	sub iz, wa	; SUB IZ, WA - IZ = 18 - remainder
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	ld bc, iz	; LD BC, IZ - sectors to read
	ld xde, 0x99A4	; LD XDE, 0x000099A4 - buffer
	calr FDC_ReadSectorWrapper	; CALR 0x9FBF92 (FDC_ReadSectorRange)
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (xsp + 10), xwa	; LD (XSP+0x0A), XWA - source ptr
	ldiw_erp 0xFA, 0	; LD QIZ, 0 - counter

	; Loop: write partial track bytes
	jr Boot_CopySectors__cs_partial_check	; 68 1b
Boot_CopySectors__cs_partial_loop:
	ld xwa, (xsp + 14)	; LD XWA, (XSP+0x0E) - dest table ptr
	lda xbc, (xwa+:4)	; LDA XBC, XWA+ - get dest addr
	ld (xsp + 14), xwa	; LD (XSP+0x0E), XWA
	ld xwa, xbc	; LD XWA, XBC
	ld xde, (xsp + 10)	; LD XDE, (XSP+0x0A) - source ptr
	ld XBC, (xde+)	; LD XBC, (XDE+) - get callback addr
	ld (xsp + 10), xde	; LD (XSP+0x0A), XDE
	call Flash_ProgramWord_32bit + 0x600000	; CALL 0xFFBCD7 - write with callback
	inc1w_erp 0xFA	; INC 1, QIZ
Boot_CopySectors__cs_partial_check:
	ld bc, iz	; LD BC, IZ
	sla bc, 7	; SLA 7, BC - BC = IZ * 128
	ldto_werp WA, 0xFA	; LD WA, QIZ
	cp wa, bc	; CP WA, BC
	jr c, Boot_CopySectors__cs_partial_loop	; 67 d9

Boot_CopySectors__cs_skip_partial:
	add (xsp + 6), iz	; ADD (XSP+0x06), IZ - advance sector
	ldw (xsp + 8), 0x800	; LD (XSP+0x08), 0x0800 - total size
	sub (xsp + 8), iz	; SUB (XSP+0x08), IZ
	ld wa, (xsp + 8)	; LD WA, (XSP+0x08)
	exts xwa	; EXTS XWA
	divs wa, 0x12	; DIVS WA, 0x0012 - full tracks
	ld (xsp + 8), wa	; LD (XSP+0x08), WA - track count
	ldw (xsp + 4), 0x0	; LD (XSP+0x04), 0x0000 - counter
	ld wa, (xsp + 8)	; LD WA, (XSP+0x08)
	cp wa, 0:i3	; CP WA, 0
	jr ule, Boot_CopySectors__cs_check_remainder	; 63 4d

Boot_CopySectors__cs_track_loop:
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	ldw bc, 0x12	; LD BC, 0x0012 - full track
	ld xde, 0x99A4	; LD XDE, 0x000099A4
	calr FDC_ReadSectorWrapper	; CALR 0x9FBF92
	addiw_da (xsp + 6), 0x12	; ADD (XSP+0x06), 0x0012
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (xsp + 10), xwa	; LD (XSP+0x0A), XWA
	ldiw_erp 0xFA, 0	; LD QIZ, 0

Boot_CopySectors__cs_full_loop:
	ld xwa, (xsp + 14)	; LD XWA, (XSP+0x0E)
	lda xbc, (xwa+:4)	; LDA XBC, XWA+
	ld (xsp + 14), xwa	; LD (XSP+0x0E), XWA
	ld xwa, xbc	; LD XWA, XBC
	ld xde, (xsp + 10)	; LD XDE, (XSP+0x0A)
	ld XBC, (xde+)	; LD XBC, (XDE+)
	ld (xsp + 10), xde	; LD (XSP+0x0A), XDE
	call Flash_ProgramWord_32bit + 0x600000	; CALL 0xFFBCD7
	inc1w_erp 0xFA	; INC 1, QIZ
	cp_erpw 0xFA, 0x00, 0x09	; CP QIZ, 0x0900 (18*128)
	jr c, Boot_CopySectors__cs_full_loop	; 67 de
	incw 1, (xsp + 4)	; INCW 1, (XSP+0x04)
	ld wa, (xsp + 8)	; LD WA, (XSP+0x08)
	cp (xsp + 4), wa	; CP (XSP+0x04), WA
	jr c, Boot_CopySectors__cs_track_loop	; 67 b3

Boot_CopySectors__cs_check_remainder:
	ld wa, (xsp + 18)	; LD WA, (XSP+0x12)
	add wa, 0x800	; ADD WA, 0x0800
	sub wa, (xsp + 6)	; SUB WA, (XSP+0x06)
	ld iz, wa	; LD IZ, WA
	cp iz, 0:i3	; CP IZ, 0
	jr z, Boot_CopySectors__cs_done	; 66 43

	; Read remainder
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	ld bc, iz	; LD BC, IZ
	ld xde, 0x99A4	; LD XDE, 0x000099A4
	calr FDC_ReadSectorWrapper	; CALR 0x9FBF92
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (xsp + 10), xwa	; LD (XSP+0x0A), XWA
	ldiw_erp 0xFA, 0	; LD QIZ, 0
	jr Boot_CopySectors__cs_rem_check	; 68 1b

Boot_CopySectors__cs_rem_loop:
	ld xwa, (xsp + 14)	; LD XWA, (XSP+0x0E)
	lda xbc, (xwa+:4)	; LDA XBC, XWA+
	ld (xsp + 14), xwa	; LD (XSP+0x0E), XWA
	ld xwa, xbc	; LD XWA, XBC
	ld xde, (xsp + 10)	; LD XDE, (XSP+0x0A)
	ld XBC, (xde+)	; LD XBC, (XDE+)
	ld (xsp + 10), xde	; LD (XSP+0x0A), XDE
	call Flash_ProgramWord_32bit + 0x600000	; CALL 0xFFBCD7
	inc1w_erp 0xFA	; INC 1, QIZ
Boot_CopySectors__cs_rem_check:
	ld bc, iz	; LD BC, IZ
	sla bc, 7	; SLA 7, BC
	ldto_werp WA, 0xFA	; LD WA, QIZ
	cp wa, bc	; CP WA, BC
	jr c, Boot_CopySectors__cs_rem_loop	; 67 d9

Boot_CopySectors__cs_done:
	pop xiz	; 5e
	lda xsp, (xsp + 16)	; LDA XSP, XSP+0x10
	ret	; 0e

; =============================================================================
; Boot_CopySectorsEx - Extended sector copy with byte write
; Address: 0x9FC213
; Parameters: XDE=dest table, BC=start sector, A=bank number
; Calls 0xFFB903 (Flash_ProgramWord_16bit) instead of 0xFFBCD7
; =============================================================================
Boot_CopySectorsEx:
	lda xsp, (xsp - 18)	; LDA XSP, XSP+0xEE - allocate 18 bytes
	push xiz	; 3e
	ld (xsp + 14), xde	; LD (XSP+0x0E), XDE - dest table
	ld (xsp + 18), bc	; LD (XSP+0x12), BC - start sector
	ld (xsp + 20), a	; LD (XSP+0x14), A - bank number
	ld wa, (xsp + 18)	; LD WA, (XSP+0x12)
	ld (xsp + 6), wa	; LD (XSP+0x06), WA
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	div wa, 0x12	; DIV WA, 0x0012
	ldto_werp WA, 0xE2	; LD WA, QWA
	ld iz, 0:i3	; LD IZ, 0
	cp wa, 0:i3	; CP WA, 0
	jr z, Boot_CopySectorsEx__cse_skip_partial	; 66 4d

	ldw iz, 0x12	; LD IZ, 0x0012
	sub iz, wa	; SUB IZ, WA
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	ld bc, iz	; LD BC, IZ
	ld xde, 0x99A4	; LD XDE, 0x000099A4
	calr FDC_ReadSectorWrapper	; CALR 0x9FBF92
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (xsp + 10), xwa	; LD (XSP+0x0A), XWA
	ldiw_erp 0xFA, 0	; LD QIZ, 0
	jr Boot_CopySectorsEx__cse_partial_check	; 68 20

Boot_CopySectorsEx__cse_partial_loop:
	ld a, (xsp + 20)	; LD A, (XSP+0x14) - bank
	extz wa	; EXTZ WA
	ld xbc, (xsp + 14)	; LD XBC, (XSP+0x0E)
	lda xde, (xbc+:2)	; LDA XDE, XBC+
	ld (xsp + 14), xbc	; LD (XSP+0x0E), XBC
	ld xbc, xde	; LD XBC, XDE
	ld xhl, (xsp + 10)	; LD XHL, (XSP+0x0A)
	ld DE, (xhl+)	; LD DE, (XHL+)
	ld (xsp + 10), xhl	; LD (XSP+0x0A), XHL
	call Flash_ProgramWord_16bit + 0x600000	; CALL 0xFFB903 (Flash_ProgramWord_16bit)
	inc1w_erp 0xFA	; INC 1, QIZ
Boot_CopySectorsEx__cse_partial_check:
	ld bc, iz	; LD BC, IZ
	sla bc, 8	; SLA 8, BC - BC = IZ * 256
	ldto_werp WA, 0xFA	; LD WA, QIZ
	cp wa, bc	; CP WA, BC
	jr c, Boot_CopySectorsEx__cse_partial_loop	; 67 d4

Boot_CopySectorsEx__cse_skip_partial:
	add (xsp + 6), iz	; ADD (XSP+0x06), IZ
	ld wa, iz	; LD WA, IZ
	ld bc, (xsp + 26)	; LD BC, (XSP+0x1A) - total size
	sub bc, wa	; SUB BC, WA
	extz xbc	; EXTZ XBC
	div bc, 0x12	; DIV BC, 0x0012
	ld (xsp + 8), bc	; LD (XSP+0x08), BC
	ldw (xsp + 4), 0x0	; LD (XSP+0x04), 0x0000
	ld wa, (xsp + 8)	; LD WA, (XSP+0x08)
	cp wa, 0:i3	; CP WA, 0
	jr ule, Boot_CopySectorsEx__cse_check_rem	; 63 52

Boot_CopySectorsEx__cse_track_loop:
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	ldw bc, 0x12	; LD BC, 0x0012
	ld xde, 0x99A4	; LD XDE, 0x000099A4
	calr FDC_ReadSectorWrapper	; CALR 0x9FBF92
	addiw_da (xsp + 6), 0x12	; ADD (XSP+0x06), 0x0012
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (xsp + 10), xwa	; LD (XSP+0x0A), XWA
	ldiw_erp 0xFA, 0	; LD QIZ, 0

Boot_CopySectorsEx__cse_full_loop:
	ld a, (xsp + 20)	; LD A, (XSP+0x14)
	extz wa	; EXTZ WA
	ld xbc, (xsp + 14)	; LD XBC, (XSP+0x0E)
	lda xde, (xbc+:2)	; LDA XDE, XBC+
	ld (xsp + 14), xbc	; LD (XSP+0x0E), XBC
	ld xbc, xde	; LD XBC, XDE
	ld xhl, (xsp + 10)	; LD XHL, (XSP+0x0A)
	ld DE, (xhl+)	; LD DE, (XHL+)
	ld (xsp + 10), xhl	; LD (XSP+0x0A), XHL
	call Flash_ProgramWord_16bit + 0x600000	; CALL 0xFFB903
	inc1w_erp 0xFA	; INC 1, QIZ
	cp_erpw 0xFA, 0x00, 0x12	; CP QIZ, 0x1200 (18*256)
	jr c, Boot_CopySectorsEx__cse_full_loop	; 67 d9
	incw 1, (xsp + 4)	; INCW 1, (XSP+0x04)
	ld wa, (xsp + 8)	; LD WA, (XSP+0x08)
	cp (xsp + 4), wa	; CP (XSP+0x04), WA
	jr c, Boot_CopySectorsEx__cse_track_loop	; 67 ae

Boot_CopySectorsEx__cse_check_rem:
	ld wa, (xsp + 18)	; LD WA, (XSP+0x12)
	add wa, (xsp + 26)	; ADD WA, (XSP+0x1A)
	sub wa, (xsp + 6)	; SUB WA, (XSP+0x06)
	ld iz, wa	; LD IZ, WA
	cp iz, 0:i3	; CP IZ, 0
	jr z, Boot_CopySectorsEx__cse_done	; 66 48

	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	extz xwa	; EXTZ XWA
	ld bc, iz	; LD BC, IZ
	ld xde, 0x99A4	; LD XDE, 0x000099A4
	calr FDC_ReadSectorWrapper	; CALR 0x9FBF92
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (xsp + 10), xwa	; LD (XSP+0x0A), XWA
	ldiw_erp 0xFA, 0	; LD QIZ, 0
	jr Boot_CopySectorsEx__cse_rem_check	; 68 20

Boot_CopySectorsEx__cse_rem_loop:
	ld a, (xsp + 20)	; LD A, (XSP+0x14)
	extz wa	; EXTZ WA
	ld xbc, (xsp + 14)	; LD XBC, (XSP+0x0E)
	lda xde, (xbc+:2)	; LDA XDE, XBC+
	ld (xsp + 14), xbc	; LD (XSP+0x0E), XBC
	ld xbc, xde	; LD XBC, XDE
	ld xhl, (xsp + 10)	; LD XHL, (XSP+0x0A)
	ld DE, (xhl+)	; LD DE, (XHL+)
	ld (xsp + 10), xhl	; LD (XSP+0x0A), XHL
	call Flash_ProgramWord_16bit + 0x600000	; CALL 0xFFB903
	inc1w_erp 0xFA	; INC 1, QIZ
Boot_CopySectorsEx__cse_rem_check:
	ld bc, iz	; LD BC, IZ
	sla bc, 8	; SLA 8, BC
	ldto_werp WA, 0xFA	; LD WA, QIZ
	cp wa, bc	; CP WA, BC
	jr c, Boot_CopySectorsEx__cse_rem_loop	; 67 d4

Boot_CopySectorsEx__cse_done:
	pop xiz	; 5e
	lda xsp, (xsp + 18)	; LDA XSP, XSP+0x12
	retd 0x2	; RETD 0x0002

; =============================================================================
; Boot_ClearScreen - Clear screen display
; Address: 0x9FC354
; =============================================================================
Boot_ClearScreen:
	pushw 0x8	; PUSH 0x0008 - color
	pushw 0x2	; PUSH 0x0002 - mode
	ld xwa, Bitmap_1bit_FD_to_Flash_Memory + 0x600000	; LD XWA, 0x00FFA626 - bitmap addr
	ldw bc, 0x30	; LD BC, 0x0030 - X pos
	ldw de, 0xA0	; LD DE, 0x00A0 - Y pos
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL 0xFFCCFB (DrawBitmap_UpdateDisplay)
	ret	; 0e

; =============================================================================
; Boot_WaitDiskInsert - Wait for disk insert and verify type
; Address: 0x9FC36A
; Waits for FDC ready, checks disk type matches expected
; =============================================================================
Boot_WaitDiskInsert:
	dec 2, xsp	; DEC 2, XSP - allocate 2 bytes
	ld (xsp), a	; LD (XSP), A - save expected type
Boot_WaitDiskInsert__display_prompt:
	pushw 0x8	; PUSH 0x0008
	pushw 0x2	; PUSH 0x0002
	ld xwa, Bitmap_1bit_Change_FD_2_of_2 + 0x600000	; LD XWA, 0x00FFAD5E - insert disk msg
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xA0	; LD DE, 0x00A0
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL 0xFFCCFB

Boot_WaitDiskInsert__wdi_wait_remove:
	call Boot_CheckDiskPresent + 0x600000	; CALL 0xFFEC63 - check disk present
	cp l, 0:i3	; CP L, 0
	jr z, Boot_WaitDiskInsert__wdi_check_insert	; 66 08
Boot_WaitDiskInsert__wdi_recheck_remove:
	call Boot_CheckDiskPresent + 0x600000	; CALL 0xFFEC63
	cp l, 0:i3	; CP L, 0
	jr nz, Boot_WaitDiskInsert__wdi_recheck_remove	; JR NZ, recheck disk removal

Boot_WaitDiskInsert__wdi_check_insert:
	ld xwa, 0:i3	; LD XWA, 0
Boot_WaitDiskInsert__wdi_delay1:
	inc 1, xwa	; INC 1, XWA
	cp xwa, 0x40000	; CP XWA, 0x00040000
	jr c, Boot_WaitDiskInsert__wdi_delay1	; 67 f6

Boot_WaitDiskInsert__wdi_wait_insert:
	call Boot_CheckDiskPresent + 0x600000	; CALL 0xFFEC63
	cp l, 0:i3	; CP L, 0
	jr nz, Boot_WaitDiskInsert__wdi_delay2	; 6e 08
Boot_WaitDiskInsert__wdi_recheck_insert:
	call Boot_CheckDiskPresent + 0x600000	; CALL 0xFFEC63
	cp l, 0:i3	; CP L, 0
	jr z, Boot_WaitDiskInsert__wdi_recheck_insert	; JR Z, recheck disk insert

Boot_WaitDiskInsert__wdi_delay2:
	ld xwa, 0:i3	; LD XWA, 0
Boot_WaitDiskInsert__wdi_delay2_loop:
	inc 1, xwa	; INC 1, XWA
	cp xwa, 0x200000	; CP XWA, 0x00200000
	jr c, Boot_WaitDiskInsert__wdi_delay2_loop	; 67 f6

	; Check disk type
	calr Boot_DetectDiskType	; CALR Boot_DetectDiskType
	cp l, (xsp)	; CP L, (XSP) - compare with expected
	jr nz, Boot_WaitDiskInsert__display_prompt	; JR NZ, wrong type, re-prompt

	; Type matches - clear screen and return
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	inc 2, xsp	; INC 2, XSP
	ret	; 0e

; =============================================================================
; Boot_WaitFDCReady - Wait for FDC to become ready
; Address: 0x9FC3C8
; Polls FDC status with timeout display
; =============================================================================
Boot_WaitFDCReady:
	pushw iz	; 2e
	ldw iz, 0x32	; LD IZ, 0x0032 - timeout counter
Boot_WaitFDCReady__wfdc_poll:
	ld xwa, 0:i3	; LD XWA, 0
	ld (3072:16), xwa	; LD (0x0C00), XWA
	call Flash_ChipErase_32bit + 0x600000	; CALL 0xFFBD17 - reset FDC
	call Flash_WaitComplete_32bit + 0x600000	; CALL 0xFFBE85 - check FDC ready
	cp hl, 0xFFFF	; CP HL, 0xFFFF - error?
	jr nz, Boot_WaitFDCReady__wfdc_done	; 6e 29

	; Timeout handling
Boot_WaitFDCReady__wfdc_timeout_check:
	ld xwa, (3072:16); LD XWA, (0x0C00)
	cp xwa, 0x1F4	; CP XWA, 0x000001F4 (500)
	jr ule, Boot_WaitFDCReady__wfdc_continue	; 63 13

	; Update display
	inc 8, iz	; INC 0, IZ - increment progress
	ld wa, iz	; LD WA, IZ
	ldw bc, 0xB4	; LD BC, 0x00B4 - X pos
	ld de, 5:i3	; LD DE, 5 - mode
	call InitProgressDisplay_FillRegion + 0x600000	; CALL 0xFFCD9A (display progress)
	ld xwa, 0:i3	; LD XWA, 0
	ld (3072:16), xwa	; LD (0x0C00), XWA

Boot_WaitFDCReady__wfdc_continue:
	call Flash_WaitComplete_32bit + 0x600000	; CALL 0xFFBE85
	cp hl, 0xFFFF	; CP HL, 0xFFFF
	jr z, Boot_WaitFDCReady__wfdc_timeout_check	; JR Z, recheck with timeout

Boot_WaitFDCReady__wfdc_done:
	popw iz	; 4e
	ret	; 0e

; =============================================================================
; Boot_LoadDiskData - Main disk data loading dispatcher
; Address: 0x9FC40B
; Dispatches based on disk type (1-8) to appropriate handler
; =============================================================================
Boot_LoadDiskData:
	dec 2, xsp	; DEC 2, XSP
	ld (xsp), a	; LD (XSP), A - save disk type
	pushw 0x8	; PUSH 0x0008
	pushw 0x2	; PUSH 0x0002
	ld xwa, Bitmap_1bit_Now_Erasing + 0x600000	; LD XWA, 0x00FFA3BE - loading msg
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xA0	; LD DE, 0x00A0
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL 0xFFCCFB

	; Validate disk type 1-8
	ld a, (xsp)	; LD A, (XSP)
	extz wa	; EXTZ WA
	dec 1, wa	; DEC 1, WA
	cp wa, 0:i3	; CP WA, 0
	jrl lt, Boot_LoadDiskData__ldd_error	; JRL LT, .ldd_error (type < 1)
	cp wa, 7:i3	; CP WA, 7
	jrl gt, Boot_LoadDiskData__ldd_error	; JRL GT, .ldd_error (type > 8)

	; Dispatch via jump table
	add wa, wa	; ADD WA, WA - WA *= 2
	lda xix, (Boot_LoadDiskData_JumpOffsets + 0x600000:24); LDA XIX, 0xFFA140 - jump table
	ld	wa, (xix+wa)	; LD WA, (XIX+WA)
	lda xix, (Boot_LoadDiskData__ldd_Program12 + 0x600000:24); LDA XIX, 0xFFC44A - base addr
	jp	t, (xix+wa)	; JP T, XIX+WA - dispatch

; Disk type 1 handler, "Program DATA FILE 1/2" (0x9FC44A): copies disk 1 to
; 0x800000, asks for disk 2 (type 2) and copies it to 0x900000
Boot_LoadDiskData__ldd_Program12:
	calr Boot_WaitFDCReady	; CALR Boot_WaitFDCReady
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	ldw wa, 0x24	; LD WA, 0x0024 - start sector
	ld xbc, TD_FLASH_BASE	; LD XBC, 0x00800000 - dest
	calr Boot_CopySectors	; CALR Boot_CopySectors
	ld wa, 2:i3	; LD WA, 2 - disk 2
	calr Boot_WaitDiskInsert	; CALR Boot_WaitDiskInsert
	ldw wa, 0x24	; LD WA, 0x0024
	ld xbc, TD_FLASH_HALF2	; LD XBC, 0x00900000
	jr Boot_LoadDiskData__ldd_copy2	; 68 1e

; Disk type 3 handler, "Table DATA FILE 1/2" (0x9FC46A): same shape as type 1,
; asking for disk type 4 (Table 2/2) second.  Boot_Init skips the update for
; types 3 and 8 (cp l,3 / cp l,8 -> Boot_PrepareJump)
Boot_LoadDiskData__ldd_Table12:
	calr Boot_WaitFDCReady	; CALR Boot_WaitFDCReady
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	ldw wa, 0x24	; LD WA, 0x0024
	ld xbc, TD_FLASH_BASE	; LD XBC, 0x00800000
	calr Boot_CopySectors	; CALR Boot_CopySectors
	ld wa, 4:i3	; LD WA, 4 - next is disk 4
	calr Boot_WaitDiskInsert	; CALR Boot_WaitDiskInsert
	ldw wa, 0x24	; LD WA, 0x0024
	ld xbc, TD_FLASH_HALF2	; LD XBC, 0x00900000

Boot_LoadDiskData__ldd_copy2:
	calr Boot_CopySectors	; CALR Boot_CopySectors
	jr Boot_LoadDiskData__ldd_done	; 68 55

; Disk type 5 handler, "CMPCUSTOMDATA" (0x9FC48D): Custom data flash
Boot_LoadDiskData__ldd_CustomData:
	ld wa, 1:i3	; LD WA, 1
	call Flash_ChipErase_16bit_Wait + 0x600000	; CALL 0xFFBBDB
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	pushw 0x800	; PUSH 0x0800 - size
	ld wa, 1:i3	; LD WA, 1 - bank 1
	ldw bc, 0x24	; LD BC, 0x0024 - start sector
	ld xde, 0x300000	; LD XDE, 0x00300000 - dest
	jr Boot_LoadDiskData__ldd_copy_ext	; 68 16

; Disk type 6 handler, "HD-AEPRG" (0x9FC4A5): HDAE5000 firmware
Boot_LoadDiskData__ldd_HDAEPrg:
	ld wa, 2:i3	; LD WA, 2
	call Flash_ChipErase_16bit_Wait + 0x600000	; CALL 0xFFBBDB
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	pushw 0x400	; PUSH 0x0400 - size
	ld wa, 2:i3	; LD WA, 2 - bank 2
	ldw bc, 0x24	; LD BC, 0x0024
	ld xde, 0x280000	; LD XDE, 0x00280000

Boot_LoadDiskData__ldd_copy_ext:
	calr Boot_CopySectorsEx	; CALR Boot_CopySectorsEx
	jr Boot_LoadDiskData__ldd_done	; 68 22

; Disk type 7 handler, "Program DATA FILE PCK" (0x9FC4C0): Erase and reprogram
Boot_LoadDiskData__ldd_ProgramPCK:
	ld wa, 1:i3	; LD WA, 1
	ld xbc, 0x3FFFFF	; LD XBC, 0x003FFFFF - end addr
	call Flash_SectorErase_16bit + 0x600000	; CALL 0xFFBA17 (Flash_SectorErase)
	calr Boot_WaitFDCReady	; CALR Boot_WaitFDCReady
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	calr LZSS_Decompress	; CALR Flash_ProgramHDAE_Initialization
	calr LZSS_ParseHeader	; CALR Boot_ProgramCustomFlash
	jr Boot_LoadDiskData__ldd_done	; 68 09

; Disk type 8 handler, "Table DATA FILE PCK" (0x9FC4D9) -- the only type that
; reaches this entry (the old "Type 6/7/8" note predates the jump table)
Boot_LoadDiskData__ldd_TablePCK:
	calr Boot_WaitFDCReady	; CALR Boot_WaitFDCReady
	calr Boot_ClearScreen	; CALR Boot_ClearScreen
	calr LZSS_Decompress	; CALR Flash_ProgramHDAE_Initialization

Boot_LoadDiskData__ldd_done:
	inc 2, xsp	; INC 2, XSP
	ret	; 0e

Boot_LoadDiskData__ldd_error:
	pushw 0x8	; PUSH 0x0008
	pushw 0x2	; PUSH 0x0002
	ld xwa, Bitmap_1bit_Illegal_Disk + 0x600000	; LD XWA, 0x00FFAFC6 - error msg
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xA0	; LD DE, 0x00A0
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL 0xFFCCFB
	inc 2, xsp	; INC 2, XSP
Boot_LoadDiskData__ldd_halt:
	jr Boot_LoadDiskData__ldd_halt	; 68 fe - infinite loop

; =============================================================================
; Boot_DelayLoop - Simple delay routine
; Address: 0x9FC4FE
; =============================================================================
Boot_DelayLoop:
	ld xbc, 0:i3	; LD XBC, 0
	cp xbc, xwa	; CP XBC, XWA
	ret nc	; RET NC
Boot_DelayLoop__delay_loop:
	inc 1, xbc	; INC 1, XBC
	cp xbc, xwa	; CP XBC, XWA
	jr c, Boot_DelayLoop__delay_loop	; 67 fa
	ret	; 0e

; =============================================================================
; Boot_BlinkLED - Cycle through LED pattern
; Address: 0x9FC50B
; Controls LED at 0x160004 (HDAE5000 PPI port)
; =============================================================================
Boot_BlinkLED:
	inc 1, (3080:16); INC 1, (0x0C08) - LED counter
	ld a, (3080:16); LD A, (0x0C08)
	and a, 0x3	; AND A, 0x03 - mask to 0-3
	cp a, 3:i3	; CP A, 3
	jr z, Boot_BlinkLED__led_pattern3	; 66 24
	cp a, 2:i3	; CP A, 2
	jr z, Boot_BlinkLED__led_pattern2	; 66 18
	cp a, 1:i3	; CP A, 1
	jr z, Boot_BlinkLED__led_pattern1	; 66 0c
	cp a, 0:i3	; CP A, 0
	jr nz, Boot_BlinkLED__led_delay	; 6e 1e

	; Pattern 0: bit 0
	ld (0x160004:24), 0x01; LD (0x160004), 0x01
	jr Boot_BlinkLED__led_delay	; 68 16

Boot_BlinkLED__led_pattern1:
	ld (0x160004:24), 0x02; LD (0x160004), 0x02
	jr Boot_BlinkLED__led_delay	; 68 0e

Boot_BlinkLED__led_pattern2:
	ld (0x160004:24), 0x04; LD (0x160004), 0x04
	jr Boot_BlinkLED__led_delay	; 68 06

Boot_BlinkLED__led_pattern3:
	ld (0x160004:24), 0x08; LD (0x160004), 0x08

Boot_BlinkLED__led_delay:
	ld xwa, 0x186A0	; LD XWA, 0x000186A0 (100000)
	jr Boot_DelayLoop	; 68 b3 -> tail call

; =============================================================================
; LED_ToggleBit2 - Toggle LED bit 2 animation loop
; Address: 0x9FC54B
; =============================================================================
LED_ToggleBit2:
	chg 2, (1441796:24); CHG 2, (0x160004) - toggle bit 2
	ld xwa, 0x249F0	; LD XWA, 0x000249F0 (150000)
	calr Boot_DelayLoop	; CALR Boot_DelayLoop
	jr LED_ToggleBit2	; 68 f1

; =============================================================================
; LED_ToggleBit3 - Toggle LED bit 3 animation loop
; Address: 0x9FC55A
; =============================================================================
LED_ToggleBit3:
	chg 3, (1441796:24); CHG 3, (0x160004) - toggle bit 3
	ld xwa, 0x249F0	; LD XWA, 0x000249F0
	calr Boot_DelayLoop	; CALR Boot_DelayLoop
	jr LED_ToggleBit3	; 68 f1

; =============================================================================
; Flash_SearchFirstNonEmptyBlock - Find first valid (non-empty) 64-byte block
; Address: 0x9FC569
; Input: XWA = start address, XBC = end address
; Returns: XHL = block address or 0 if not found
; =============================================================================
Flash_SearchFirstNonEmptyBlock:
	ld xhl, xwa	; LD XHL, XWA
Flash_SearchFirstNonEmptyBlock__fvb_check:
	ld xde, (xhl)	; LD XDE, (XHL)
	cp xde, 0xFFFFFFFF	; CP XDE, 0xFFFFFFFF
	ret nz	; RET NZ - found valid data
Flash_SearchFirstNonEmptyBlock__fvb_next:
	lda xhl, (xhl + 64)	; LDA XHL, XHL+0x40 - next 64-byte block
	cp xhl, xbc	; CP XHL, XBC
	jr nz, Flash_SearchFirstNonEmptyBlock__fvb_not_end	; 6e 03
	ld xhl, 0:i3	; LD XHL, 0 - not found
	ret	; 0e
Flash_SearchFirstNonEmptyBlock__fvb_not_end:
	ld xde, (xhl)	; LD XDE, (XHL)
	cp xde, 0xFFFFFFFF	; CP XDE, 0xFFFFFFFF
	jr z, Flash_SearchFirstNonEmptyBlock__fvb_next	; 66 ec
	ret	; 0e - found valid

; =============================================================================
; Boot_VerifyFlash - Verify flash programming against source
; Address: 0x9FC58A
; Input: XWA = flash addr, XBC = source addr, (XSP+4) = bank count
; Returns: XHL = 0 if match, non-zero if mismatch
; =============================================================================
Boot_VerifyFlash:
	ld xhl, xwa	; LD XHL, XWA - flash addr
	ld w, e	; LD W, E - bank number
	ld a, (xsp + 4)	; LD A, (XSP+0x04) - max bank
	cp w, a	; CP W, A
	jr ugt, Boot_VerifyFlash__vf_success	; 6b 22

Boot_VerifyFlash__vf_bank_loop:
	ld (0x160000:24), w; LD (0x160000), W - set bank
	ld xix, xbc	; LD XIX, XBC - source addr
	ld xiy, 0x3FFFF	; LD XIY, 0x0003FFFF - 256KB-1

Boot_VerifyFlash__vf_compare:
	ld DE, (xix+)	; LD DE, (XIX+) - read source
	cp DE, (xhl+)	; CP DE, (XHL+) - compare with flash
	jr nz, Boot_VerifyFlash__vf_mismatch	; 6e 10
	ld xde, xiy	; LD XDE, XIY
	dec 1, xiy	; DEC 1, XIY
	or xde, xde	; OR XDE, XDE
	jr nz, Boot_VerifyFlash__vf_compare	; 6e f0
	inc 1, w	; INC 1, W - next bank
	cp w, a	; CP W, A
	jr ule, Boot_VerifyFlash__vf_bank_loop	; 63 de

Boot_VerifyFlash__vf_success:
	ld xhl, 0:i3	; LD XHL, 0 - success
Boot_VerifyFlash__vf_mismatch:
	retd 0x2	; RETD 0x0002

; =============================================================================
; Boot_ProgramCustomFlash - Program custom data flash (0x300000)
; Address: 0x9FC5BC
; Copies 256KB from table_data ROM (0x800000) to custom data (0x300000)
; Uses 2 banks
; =============================================================================
Boot_ProgramCustomFlash:
	lda xsp, (xsp - 10)	; LDA XSP, XSP+0xF6 - allocate 10 bytes
	push xiz	; 3e
	lda xwa, (0x300000:24); LDA XWA, 0x300000 - dest
	ld (xsp + 8), xwa	; LD (XSP+0x08), XWA
	ld (xsp + 12), 0x0	; LD (XSP+0x0C), 0x00 - bank

Boot_ProgramCustomFlash__pcf_bank_loop:
	ld a, (xsp + 12)	; LD A, (XSP+0x0C)
	ld (0x160000:24), a; LD (0x160000), A - set bank
	lda xwa, (0x200000:24); LDA XWA, 0x200000 - source
	ld (xsp + 4), xwa	; LD (XSP+0x04), XWA
	ld xiz, 0:i3	; LD XIZ, 0 - counter

Boot_ProgramCustomFlash__pcf_copy_loop:
	ld xwa, (xsp + 8)	; LD XWA, (XSP+0x08) - dest ptr
	lda xbc, (xwa+:2)	; LDA XBC, XWA+
	ld (xsp + 8), xwa	; LD (XSP+0x08), XWA
	ld xwa, (xsp + 4)	; LD XWA, (XSP+0x04) - source ptr
	ld DE, (xwa+)	; LD DE, (XWA+)
	ld (xsp + 4), xwa	; LD (XSP+0x04), XWA
	ld wa, 1:i3	; LD WA, 1 - bank 1
	call Flash_ProgramWord_16bit + 0x600000	; CALL 0xFFB903 (Flash_ProgramWord_16bit)
	inc 1, xiz	; INC 1, XIZ
	cp xiz, 0x40000	; CP XIZ, 0x00040000 (256K)
	jr c, Boot_ProgramCustomFlash__pcf_copy_loop	; 67 de

	incm8 1, (xsp + 12)	; INC 1, (XSP+0x0C)
	cp (xsp + 12), 0x2	; CP (XSP+0x0C), 0x02
	jr c, Boot_ProgramCustomFlash__pcf_bank_loop	; 67 c3

	pop xiz	; 5e
	lda xsp, (xsp + 10)	; LDA XSP, XSP+0x0A
	ret	; 0e

; =============================================================================
; Flash_ProgramHDAE_Initialization - Program HDAE5000 ROM banks 0-3
; Address: 0x9FC60E
; Copies from table_data (0x800000) to HDAE5000 (0x280000)
; =============================================================================
Flash_ProgramHDAE_Initialization:
	lda xsp, (xsp - 10)	; LDA XSP, XSP+0xF6
	push xiz	; 3e
	ld xwa, TD_FLASH_BASE	; LD XWA, 0x00800000 - source
	ld (xsp + 8), xwa	; LD (XSP+0x08), XWA
	ld (xsp + 12), 0x0	; LD (XSP+0x0C), 0x00 - bank

Flash_ProgramHDAE_Initialization__phd1_bank_loop:
	ld a, (xsp + 12)	; LD A, (XSP+0x0C)
	ld (0x160000:24), a; LD (0x160000), A - set bank
	lda xwa, (0x280000:24); LDA XWA, 0x280000 - dest
	ld (xsp + 4), xwa	; LD (XSP+0x04), XWA
	ld xiz, 0:i3	; LD XIZ, 0

Flash_ProgramHDAE_Initialization__phd1_copy_loop:
	ld xwa, (xsp + 8)	; LD XWA, (XSP+0x08)
	lda xbc, (xwa+:4)	; LDA XBC, XWA+
	ld (xsp + 8), xwa	; LD (XSP+0x08), XWA
	ld xwa, xbc	; LD XWA, XBC
	ld xde, (xsp + 4)	; LD XDE, (XSP+0x04)
	ld XBC, (xde+)	; LD XBC, (XDE+)
	ld (xsp + 4), xde	; LD (XSP+0x04), XDE
	call Flash_ProgramWord_32bit + 0x600000	; CALL 0xFFBCD7 (write with callback)
	inc 1, xiz	; INC 1, XIZ
	cp xiz, 0x20000	; CP XIZ, 0x00020000 (128K)
	jr c, Flash_ProgramHDAE_Initialization__phd1_copy_loop	; 67 de

	incm8 1, (xsp + 12)	; INC 1, (XSP+0x0C)
	cp (xsp + 12), 0x4	; CP (XSP+0x0C), 0x04
	jr c, Flash_ProgramHDAE_Initialization__phd1_bank_loop	; 67 c3

	pop xiz	; 5e
	lda xsp, (xsp + 10)	; LDA XSP, XSP+0x0A
	ret	; 0e

; =============================================================================
; Flash_ProgramHDAE_Payload - Program HDAE5000 ROM banks 4-7
; Address: 0x9FC660
; =============================================================================
Flash_ProgramHDAE_Payload:
	lda xsp, (xsp - 10)	; LDA XSP, XSP+0xF6
	push xiz	; 3e
	ld xwa, TD_FLASH_BASE	; LD XWA, 0x00800000
	ld (xsp + 8), xwa	; LD (XSP+0x08), XWA
	ld (xsp + 12), 0x4	; LD (XSP+0x0C), 0x04 - start at bank 4

Flash_ProgramHDAE_Payload__phd2_bank_loop:
	ld a, (xsp + 12)	; LD A, (XSP+0x0C)
	ld (0x160000:24), a; LD (0x160000), A
	lda xwa, (0x280000:24); LDA XWA, 0x280000
	ld (xsp + 4), xwa	; LD (XSP+0x04), XWA
	ld xiz, 0:i3	; LD XIZ, 0

Flash_ProgramHDAE_Payload__phd2_copy_loop:
	ld xwa, (xsp + 8)	; LD XWA, (XSP+0x08)
	lda xbc, (xwa+:4)	; LDA XBC, XWA+
	ld (xsp + 8), xwa	; LD (XSP+0x08), XWA
	ld xwa, xbc	; LD XWA, XBC
	ld xde, (xsp + 4)	; LD XDE, (XSP+0x04)
	ld XBC, (xde+)	; LD XBC, (XDE+)
	ld (xsp + 4), xde	; LD (XSP+0x04), XDE
	call Flash_ProgramWord_32bit + 0x600000	; CALL 0xFFBCD7
	inc 1, xiz	; INC 1, XIZ
	cp xiz, 0x20000	; CP XIZ, 0x00020000
	jr c, Flash_ProgramHDAE_Payload__phd2_copy_loop	; 67 de

	incm8 1, (xsp + 12)	; INC 1, (XSP+0x0C)
	cp (xsp + 12), 0x8	; CP (XSP+0x0C), 0x08 - end at bank 8
	jr c, Flash_ProgramHDAE_Payload__phd2_bank_loop	; 67 c3

	pop xiz	; 5e
	lda xsp, (xsp + 10)	; LDA XSP, XSP+0x0A
	ret	; 0e

; =============================================================================
; HDAE5000_InitializeParallelPort - Factory HDAE5000/custom flash programming
; Address: 0x9FC6B2 (boot-time alias 0xFFC6B2)
;
; Full factory-programming sequence:
;   1. Set up the 8255 PPI at 0x160000-0x160006 and wait for the Port B bit 0
;      handshake.
;   2. Probe the 32-bit table-data flash and the 16-bit custom-data flash
;      (LED bit 2/3 + halt if either is missing).
;   3. Chip-erase whichever devices are not blank, blinking the LEDs while the
;      erase runs.
;   4. Program HDAE5000 banks 0-3 (Flash_ProgramHDAE_Initialization) and the
;      custom-data flash (Boot_ProgramCustomFlash), LED bit 0 lit.
;   5. Verify both devices, LED bit 1 lit (LED_ToggleBit2/3 forever on
;      mismatch).
;   6. Check the "hkt_" signature at 0x2FFFC0 (HDAE bank 7 selected), remap
;      CS2 and jump into the Program ROM at 0xFFFED8.
;
; Inputs:  none (QIZ saved on entry; drives PPI/LEDs at 0x160000-0x160006)
; Outputs: does not return on success - jumps to Program ROM entry 0xFFFED8;
;          halts in a self-loop with an LED diagnostic on any failure
; Callers: Boot_Init (call_24 nz at boot alias 0xFFB65C, when region code != 4)
; =============================================================================
HDAE5000_InitializeParallelPort:
	pushw_erp 0xFA	; PUSH QIZ
	ldib_erp 0xFB, 0	; LD QIZH, 0
	ld (0xE4:8), 0x00:io	; LD (0xE4), 0x00 - TMP94C241 SFR init
	ld (0xE0:8), 0x00:io	; LD (0xE0), 0x00
	ld (0xED:8), 0x00:io	; LD (0xED), 0x00
	ld (0xE3:8), 0x00:io	; LD (0xE3), 0x00
	ld (0xEB:8), 0x00:io	; LD (0xEB), 0x00
	ld (340:16), 102; LD (0x0154), 0x66
	ld (0x160006:24), 0x82; LD (0x160006), 0x82 - PPI mode
	ld (0x160000:24), 0x00; LD (0x160000), 0x00 - Port A
	ld (0x160004:24), 0x00; LD (0x160004), 0x00 - Port C
	ld (0x160004:24), 0x0f; LD (0x160004), 0x0F - LED bits on
	ld xwa, 0xDBBA0	; LD XWA, 0x000DBBA0 (900000)
	calr Boot_DelayLoop	; CALR Boot_DelayLoop
	ld (0x160004:24), 0x00; LD (0x160004), 0x00 - LEDs off
HDAE5000_InitializeParallelPort__ppi_wait_loop:
	ld a, (0x160002:24)	; LD A, (0x160002) - poll PPI Port B handshake
	extz wa	; EXTZ WA
	bit 0, wa	; BIT 0, WA - HDAE5000 ready when bit 0 clears
	jr nz, HDAE5000_InitializeParallelPort__ppi_wait_loop	; 6e f4

	; === Probe both flash devices; light an LED and halt on failure ===
	call Flash_ReadID_32bit + 0x600000	; CALL Flash_ReadID_32bit (boot-time alias of 0x9FBC6A)
	cp xhl, 0xFFFFFFFF	; CP XHL, 0xFFFFFFFF - no/unknown device?
	jr nz, HDAE5000_InitializeParallelPort__probe_16bit	; 6e 08
	set 2, (0x160004:24)	; SET 2, (0x160004) - LED bit 2 = table flash probe failed
	ldib_erp 0xFB, 1	; LD QIZH, 1 - record probe failure
HDAE5000_InitializeParallelPort__probe_16bit:
	ld wa, 1:i3	; LD WA, 1 - custom-data flash bank
	call Flash_ReadID_16bit + 0x600000	; CALL Flash_ReadID_16bit (boot-time alias of 0x9FB888)
	cp hl, 0xFFFF	; CP HL, 0xFFFF - no/unknown device?
	jr nz, HDAE5000_InitializeParallelPort__check_probe_result	; 6e 0a
	set 3, (0x160004:24)	; SET 3, (0x160004) - LED bit 3 = custom flash probe failed
	ldib_erp 0xFB, 1	; LD QIZH, 1
	jr HDAE5000_InitializeParallelPort__probe_fail_halt	; 68 08
HDAE5000_InitializeParallelPort__check_probe_result:
	cpib_erp 0xFB, 1	; CP QIZH, 1 - did the 32-bit probe fail?
	jr nz, HDAE5000_InitializeParallelPort__erase_flash	; 6e 05
	popw_erp 0xFA	; POP QIZ - unwind saved register before halting
HDAE5000_InitializeParallelPort__probe_fail_halt:
	jr HDAE5000_InitializeParallelPort__probe_fail_halt	; 68 fe - halt with LED diagnostic

	; === Erase both flash devices (only if not already blank) ===
HDAE5000_InitializeParallelPort__erase_flash:
	ld (0x160004:24), 0x00	; LD (0x160004), 0x00 - LEDs off
	ld xwa, TD_FLASH_BASE	; table-data flash start
	ld xbc, 0xA00000	; table-data flash end
	calr Flash_SearchFirstNonEmptyBlock
	or xhl, xhl	; XHL != 0 -> data present, needs erase
	call nz, (Flash_ChipErase_32bit + 0x600000:24)	; CALL NZ, Flash_ChipErase_32bit (boot-time alias of 0x9FBD17)
	lda xwa, (0x300000:24)	; custom-data flash start
	ld xbc, xwa	; LD XBC, XWA
	add xbc, 0x100000	; custom-data flash end = 0x400000
	calr Flash_SearchFirstNonEmptyBlock
	or xhl, xhl
	jr z, HDAE5000_InitializeParallelPort__wait_erase	; 66 06
	ld wa, 1:i3	; LD WA, 1
	call Flash_ChipErase_16bit + 0x600000	; CALL Flash_ChipErase_16bit (boot-time alias of 0x9FB968)
HDAE5000_InitializeParallelPort__wait_erase:
	call Flash_WaitComplete_32bit + 0x600000	; CALL Flash_WaitComplete_32bit (boot-time alias of 0x9FBE85)
	cp hl, 0xFFFF	; still busy?
	jr nz, HDAE5000_InitializeParallelPort__program_flash	; 6e 0d
HDAE5000_InitializeParallelPort__erase_blink:
	calr Boot_BlinkLED	; cycle LED pattern while the chip erase runs
	call Flash_WaitComplete_32bit + 0x600000	; CALL Flash_WaitComplete_32bit
	cp hl, 0xFFFF
	jr z, HDAE5000_InitializeParallelPort__erase_blink	; 66 f3

	; === Program initialization image + custom flash (LED bit 0 while busy) ===
HDAE5000_InitializeParallelPort__program_flash:
	ld (0x160004:24), 0x00	; LD (0x160004), 0x00 - LEDs off
	set 0, (0x160004:24)	; SET 0, (0x160004)
	calr Flash_ProgramHDAE_Initialization	; program HDAE5000 banks 0-3
	res 0, (0x160004:24)	; RES 0, (0x160004)
	ld xwa, 0xDBBA0	; LD XWA, 0x000DBBA0 (900000)
	calr Boot_DelayLoop
	set 0, (0x160004:24)	; SET 0, (0x160004)
	calr Boot_ProgramCustomFlash	; program custom-data flash (2 banks)
	res 0, (0x160004:24)	; RES 0, (0x160004)

	; === Verify both devices (LED bit 1; on mismatch toggle bit 2/3 forever) ===
	set 1, (0x160004:24)	; SET 1, (0x160004)
	pushw 0x3	; last bank to verify = 3
	ld xwa, TD_FLASH_BASE	; reference: table-data image
	ld xbc, 0x280000	; HDAE5000 banked window
	ld de, 0:i3	; LD DE, 0 - first bank
	calr Boot_VerifyFlash
	or xhl, xhl
	call nz, (LED_ToggleBit2 + 0x600000:24)	; CALL NZ, LED_ToggleBit2 (boot-time alias of 0x9FC54B; never returns)
	pushw 0x1	; last bank to verify = 1
	ld xwa, 0x300000	; reference: custom-data flash
	ld xbc, 0x200000	; source window
	ld de, 0:i3	; LD DE, 0 - first bank
	calr Boot_VerifyFlash
	or xhl, xhl
	call nz, (LED_ToggleBit3 + 0x600000:24)	; CALL NZ, LED_ToggleBit3 (boot-time alias of 0x9FC55A; never returns)

	; === Check "hkt_" signature, remap CS2 and jump into the Program ROM ===
	ld (0x160000:24), 0x07	; LD (0x160000), 0x07 - select HDAE5000 bank 7
	ld xwa, (0x2fffc0:24)	; LD XWA, (0x2FFFC0) - signature dword
	cp xwa, 0x5F746B68	; CP XWA, 0x5F746B68 - ASCII "hkt_"
	jr z, HDAE5000_InitializeParallelPort__handoff	; 66 05
	popw_erp 0xFA	; POP QIZ
HDAE5000_InitializeParallelPort__sig_fail_halt:
	jr HDAE5000_InitializeParallelPort__sig_fail_halt	; 68 fe - bad signature, halt
HDAE5000_InitializeParallelPort__handoff:
	ei 7	; disable maskable interrupts
	ld xwa, PROGRAM_ROM_ENTRY_HDAE5000	; entry in Program ROM (Boot_Init's own handoff uses 0xFFFEDC)
	ldw ix, 0x14B	; CS2 register
	extz xix
	sll xbc, 16	; with the next line: XBC <<= 32 = 0 (XBC is not read before the jump)
	sll xbc, 16
	ld (xix), 0x80	; CS2 config
	jp (xwa)	; jump into main program ROM - never returns
	popw_erp 0xFA	; unreachable canonical epilogue: POP QIZ
	ret	; 0e

; =============================================================================
; HDAE5000_ProgramPayloadOnly - Reprogram only the HDAE5000 payload banks 4-7
; Address: 0x9FC80F (boot-time alias 0xFFC80F)
;
; Second factory-programming entry: probes the 32-bit table-data flash, erases
; it if non-blank (blinking the LEDs while the erase runs), programs HDAE5000
; banks 4-7 via Flash_ProgramHDAE_Payload, then verifies banks 4-7 of the
; 0x280000 window against the table-data image at 0x800000.
; Skips the PPI setup, the 16-bit custom-flash path and the "hkt_" handoff of
; HDAE5000_InitializeParallelPort.
;
; Inputs:  none (drives the HDAE5000 PPI LEDs at 0x160004)
; Outputs: never returns - halts when done (or LED_ToggleBit2 on mismatch)
; Callers: HDAE5000_ReinitPPI_ProgramPayload (jrl); no other xref in this ROM
; =============================================================================
HDAE5000_ProgramPayloadOnly:
	ld (0x160004:24), 0x00	; LD (0x160004), 0x00 - LEDs off
	call Flash_ReadID_32bit + 0x600000	; CALL Flash_ReadID_32bit (boot-time alias of 0x9FBC6A)
	cp xhl, 0xFFFFFFFF	; CP XHL, 0xFFFFFFFF - no/unknown device?
	jr nz, HDAE5000_ProgramPayloadOnly__erase_flash	; 6e 07
	set 2, (0x160004:24)	; SET 2, (0x160004) - LED bit 2 = probe failed
HDAE5000_ProgramPayloadOnly__probe_fail_halt:
	jr HDAE5000_ProgramPayloadOnly__probe_fail_halt	; 68 fe
HDAE5000_ProgramPayloadOnly__erase_flash:
	ld xwa, TD_FLASH_BASE	; table-data flash start
	ld xbc, 0xA00000	; table-data flash end
	calr Flash_SearchFirstNonEmptyBlock
	or xhl, xhl	; XHL != 0 -> data present, needs erase
	jr z, HDAE5000_ProgramPayloadOnly__program_flash	; 66 21
	call Flash_ChipErase_32bit + 0x600000	; CALL Flash_ChipErase_32bit (boot-time alias of 0x9FBD17)
	call Flash_WaitComplete_32bit + 0x600000	; CALL Flash_WaitComplete_32bit (boot-time alias of 0x9FBE85)
	cp hl, 0xFFFF	; still busy?
	jr nz, HDAE5000_ProgramPayloadOnly__program_flash	; 6e 13
HDAE5000_ProgramPayloadOnly__erase_blink:
	calr Boot_BlinkLED	; cycle LED pattern while the chip erase runs
	ld (0x160004:24), 0x00	; LD (0x160004), 0x00 - LEDs off between patterns
	call Flash_WaitComplete_32bit + 0x600000	; CALL Flash_WaitComplete_32bit
	cp hl, 0xFFFF
	jr z, HDAE5000_ProgramPayloadOnly__erase_blink	; 66 ed
HDAE5000_ProgramPayloadOnly__program_flash:
	set 0, (0x160004:24)	; SET 0, (0x160004) - LED bit 0 while programming
	calr Flash_ProgramHDAE_Payload	; program HDAE5000 banks 4-7
	res 0, (0x160004:24)	; RES 0, (0x160004)
	set 1, (0x160004:24)	; SET 1, (0x160004) - LED bit 1 while verifying
	pushw 0x7	; last bank to verify = 7
	ld xwa, TD_FLASH_BASE	; reference: table-data image
	ld xbc, 0x280000	; HDAE5000 banked window
	ld de, 4:i3	; LD DE, 4 - first bank
	calr Boot_VerifyFlash
	or xhl, xhl
	call nz, (LED_ToggleBit2 + 0x600000:24)	; CALL NZ, LED_ToggleBit2 (boot-time alias of 0x9FC54B; never returns)
HDAE5000_ProgramPayloadOnly__done_halt:
	jr HDAE5000_ProgramPayloadOnly__done_halt	; 68 fe - done, halt

; =============================================================================
; HDAE5000_ReinitPPI_ProgramPayload - PPI re-init + payload-only programming
; Address: 0x9FC887 (boot-time alias 0xFFC887)
;
; Repeats HDAE5000_InitializeParallelPort's PPI setup (without the SFR
; interrupt-enable clears), waits for the PPI Port B handshake, then continues
; at HDAE5000_ProgramPayloadOnly.
;
; Inputs:  none
; Outputs: never returns (tail-jumps into HDAE5000_ProgramPayloadOnly)
; Callers: NONE in this ROM - the preceding instruction is a self-loop and no
;          xref exists, so this entry is reachable only externally (factory
;          jig / ICE). Kept because it is genuine reachable-by-entry code.
; =============================================================================
HDAE5000_ReinitPPI_ProgramPayload:
	ld (0x154:16), 0x66	; LD (0x0154), 0x66
	ld (0x160006:24), 0x82	; LD (0x160006), 0x82 - PPI mode
	ld (0x160000:24), 0x00	; LD (0x160000), 0x00 - Port A
	ld (0x160004:24), 0x00	; LD (0x160004), 0x00 - Port C
	ld (0x160004:24), 0x0f	; LD (0x160004), 0x0F - LED bits on
	ld xwa, 0xDBBA0	; LD XWA, 0x000DBBA0 (900000)
	calr Boot_DelayLoop
	ld (0x160004:24), 0x00	; LD (0x160004), 0x00 - LEDs off
HDAE5000_ReinitPPI_ProgramPayload__ppi_wait_loop:
	ld a, (0x160002:24)	; LD A, (0x160002) - poll PPI Port B handshake
	extz wa	; EXTZ WA
	bit 0, wa	; BIT 0, WA - HDAE5000 ready when bit 0 clears
	jr nz, HDAE5000_ReinitPPI_ProgramPayload__ppi_wait_loop	; 6e f4
	jrl HDAE5000_ProgramPayloadOnly	; 78 4e ff
	ret	; unreachable - alignment filler before LZSS_ReadByte


; =============================================================================
; LZSS DECOMPRESSOR (SLIDE4K FORMAT)
; =============================================================================
; The KN5000 bootloader includes an LZSS decompressor for handling compressed
; firmware data. This implementation uses the standard SLIDE4K format:
;   - 4KB sliding window (0x1000 bytes)
;   - 12-bit window offset (masked with 0x0FFF)
;   - 4-bit match length (stored in high nibble of second byte)
;   - Flag byte determines literal (bit=1) vs back-reference (bit=0)
;   - Window pre-filled with zeros for first 4078 (0xFEE) bytes
;
; RAM Variables Used:
;   0x0C20: Expected output size
;   0x0C24: Current output position
;   0x0C28: Source ROM address pointer
;   0x0C2C: Sector read buffer pointer
;   0x0C30: Current sector X position
;   0x0C32: Current sector Y position
;   0x0C34: Sector offset for display
;   0x0C36: Output byte counter (0-3 for 32-bit writes)
;
; Stack Frame (XSP+offset):
;   +0x04: Flag byte (shifted right each iteration)
;   +0x06: Copy counter for back-reference
;   +0x08: Match length
;   +0x0A: Window write position
;   +0x0C: Window base address (copy of +0x10)
;   +0x10: Window buffer pointer (from malloc)
; =============================================================================

	.org 0x9FC8C2 - 0x800000, 0xFF
; -----------------------------------------------------------------------------
; LZSS_ReadByte - Read next byte from compressed input stream
; Address: 0xFFC8C2
; Returns: HL = byte read (or 0xFFFF if end of data)
;
; Handles sector buffering - reads 0x2400 bytes per sector from table_data ROM
; -----------------------------------------------------------------------------
LZSS_ReadByte:
	pushw iz	; PUSH IZ
	ld xwa, (3108:16); LD XWA, (0x0C24) - current position
	cp xwa, (3104:16)	; CP XWA, (0x0C20) - compare with expected size
	jr c, LZSS_ReadByte__not_eof	; JR C, .not_eof
	ldw hl, 0xFFFF	; LD HL, 0xFFFF - return EOF
	jr LZSS_ReadByte__exit	; JR T, .exit
LZSS_ReadByte__not_eof:
	; Check if need to read next sector
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	add xwa, 0x9000	; ADD XWA, 0x00009000
	cp xwa, (3116:16)	; CP XWA, (0x0C2C) - buffer limit
	jr nz, LZSS_ReadByte__read_byte	; JR NZ, .read_byte
	; Need to read next sector
	incw 8, (3120:16); INCW 0, (0x0C30) - next sector X
	ld wa, (3120:16); LD WA, (0x0C30)
	ld bc, (3122:16); LD BC, (0x0C32)
	ld de, 6:i3	; LD DE, 6 - sector size index
	call InitProgressDisplay_FillRegion + 0x600000	; CALL 0xFFCD9A (display progress)
	ld iz, 0:i3	; LD IZ, 0
LZSS_ReadByte__read_sectors:
	ld wa, (3124:16); LD WA, (0x0C34)
	extz xwa	; EXTZ XWA
	ldw bc, 0x2400	; LD BC, 0x2400 - sector size
	mul xbc, iz	; MUL XBC, IZ
	ld xde, 0x99A4	; LD XDE, 0x000099A4 - buffer base
	add xde, xbc	; ADD XDE, XBC
	ldw bc, 0x12	; LD BC, 0x0012
	calr FDC_ReadSectorWrapper	; CALR 0xFFBF92 (read sector data)
	addw (3124:16), 18	; ADD (0x0C34), 0x0012
	inc 1, iz	; INC 1, IZ
	cp iz, 4:i3	; CP IZ, 4
	jr c, LZSS_ReadByte__read_sectors	; JR C, .read_sectors
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4
	ld (3116:16), xwa	; LD (0x0C2C), XWA - reset buffer pointer
LZSS_ReadByte__read_byte:
	ld xwa, (3116:16); LD XWA, (0x0C2C) - get buffer pointer
	lda xbc, (xwa+:1)	; LDA XBC, XWA+ (post-increment read)
	ld (3116:16), xwa	; LD (0x0C2C), XWA - save updated pointer
	ld l, (xbc)	; LD L, (XBC) - read byte into L
	extz hl	; EXTZ HL - zero-extend to HL
LZSS_ReadByte__exit:
	popw iz	; POP IZ
	ret	; RET

; -----------------------------------------------------------------------------
; LZSS_OutputByte - Write decompressed byte to output buffer
; Address: 0xFFC935
; Input: A = byte to output
;
; Buffers 4 bytes and writes as 32-bit word to destination
; -----------------------------------------------------------------------------
	.org 0x9FC935 - 0x800000, 0xFF
LZSS_OutputByte:
	ld e, (3126:16); LD E, (0x0C36) - output index
	extz de	; EXTZ DE
	lda xbc, (3082:16); LDA XBC, 0x0C0A - temp buffer
	extz xde	; EXTZ XDE
	add xde, xbc	; ADD XDE, XBC
	ld (xde), a	; LD (XDE), A - store byte
	ld a, (3126:16); LD A, (0x0C36)
	ld e, a	; LD E, A
	inc 1, a	; INC 1, A
	ld (3126:16), a; LD (0x0C36), A
	cp e, 3:i3	; CP E, 3 - check if 4 bytes buffered
	jr nz, LZSS_OutputByte__not_full	; JR NZ, .not_full
	; Flush 4-byte buffer to destination
	ld xwa, (3112:16); LD XWA, (0x0C28) - dest ptr
	lda xde, (xwa+:4)	; LDA XDE, XWA+ (post-increment)
	ld (3112:16), xwa	; LD (0x0C28), XWA
	ld xbc, (xbc)	; LD XBC, (XBC) - load 4 bytes from buffer
	ld xwa, xde	; LD XWA, XDE
	call Flash_ProgramWord_32bit + 0x600000	; CALL 0xFFBCD7 (write to dest)
	ld (3126:16), 0; LD (0x0C36), 0x00 - reset index
LZSS_OutputByte__not_full:
	ld xwa, 1:i3	; LD XWA, 1
	add (3108:16), xwa	; ADD (0x0C24), XWA - increment output pos
	ret	; RET

; -----------------------------------------------------------------------------
; Routine at 0xFFC974 - alternate output handler
; Used when writing to a different buffer (0x0C0E instead of 0x0C0A)
; -----------------------------------------------------------------------------
	.org 0x9FC974 - 0x800000, 0xFF
LZSS_OutputByte_Alt:
	ld c, (3126:16); LD C, (0x0C36)
	extz bc	; EXTZ BC
	lda xde, (3086:16); LDA XDE, 0x0C0E
	extz xbc	; EXTZ XBC
	add xbc, xde	; ADD XBC, XDE
	ld (xbc), a	; LD (XBC), A
	ld a, (3126:16); LD A, (0x0C36)
	ld c, a	; LD C, A
	inc 1, a	; INC 1, A
	ld (3126:16), a; LD (0x0C36), A
	cp c, 1:i3	; CP C, 1
	jr nz, LZSS_OutputByte_Alt__not_full	; JR NZ, .not_full
	ld xwa, (3128:16); LD XWA, (0x0C38)
	lda xbc, (xwa+:2)	; LDA XBC, XWA+
	ld (3128:16), xwa	; LD (0x0C38), XWA
	ld de, (xde)	; LD DE, (XDE)
	ld wa, 1:i3	; LD WA, 1
	call Flash_ProgramWord_16bit + 0x600000	; CALL 0xFFB903
	ld (3126:16), 0; LD (0x0C36), 0x00
LZSS_OutputByte_Alt__not_full:
	ld xwa, 1:i3	; LD XWA, 1
	add (3108:16), xwa	; ADD (0x0C24), XWA
	ret	; RET

; -----------------------------------------------------------------------------
; Routine at 0xFFC9B3 - LZSS header parsing helper for flash update
; Sets up source address (0x3E0000 = Table Data ROM) and validates header
; -----------------------------------------------------------------------------
	.org 0x9FC9B3 - 0x800000, 0xFF
LZSS_ParseHeader:
	dec 6, xsp	; DEC 6, XSP (allocate 6 bytes)
	pushw iz	; PUSH IZ
	ld (3126:16), 0; LD (0x0C36), 0x00
	lda xwa, (0x300000:24); LDA XWA, 0x300000
	add xwa, 0xE0000	; ADD XWA, 0x000E0000 (XWA = 0x3E0000)
	ld (3128:16), xwa	; LD (0x0C38), XWA - store source ptr
	ld xwa, 0x20000	; LD XWA, 0x00020000
	add (3104:16), xwa	; ADD (0x0C20), XWA
	ld iz, 0:i3	; LD IZ, 0
LZSS_ParseHeader__read_header:
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	ld bc, iz	; LD BC, IZ
	extz xbc	; EXTZ XBC
	lda xwa, (xsp + 2)	; LDA XWA, XSP+0x02
	ld xde, xwa	; LD XDE, XWA
	add xde, xbc	; ADD XDE, XBC
	ld (xde), l	; LD (XDE), L
	inc 1, iz	; INC 1, IZ
	cp iz, 6:i3	; CP IZ, 6
	jr c, LZSS_ParseHeader__read_header	; JR C, .read_header
	; Validate header against expected signature
	pushw 0x5	; PUSH 0x0005
	pushw 0xFF	; PUSH 0x00FF
	pushw 0xA150	; PUSH 0xA150 (expected signature addr)
	push xwa	; PUSH XWA
	call Boot_memcmp + 0x600000	; CALL 0xFFFBDC (memcmp)
	add xsp, 0xA	; ADD XSP, 0x0A
	cp hl, 0:i3	; CP HL, 0
	jr z, LZSS_ParseHeader__valid	; JR Z, .valid
	ldw hl, 0xFFFF	; LD HL, 0xFFFF
	jr LZSS_ParseHeader__exit	; JR T, .exit
LZSS_ParseHeader__valid:
	; Output the 6 header bytes via OutputByte_Alt
	ld iz, 0:i3	; LD IZ, 0
LZSS_ParseHeader__read_more:
	ld bc, iz	; LD BC, IZ
	extz xbc	; EXTZ XBC
	lda xwa, (xsp + 2)	; LDA XWA, XSP+0x02
	add xwa, xbc	; ADD XWA, XBC
	ld a, (xwa)	; LD A, (XWA)
	extz wa	; EXTZ WA
	calr LZSS_OutputByte_Alt	; CALR LZSS_OutputByte_Alt
	inc 1, iz	; INC 1, IZ
	cp iz, 6:i3	; CP IZ, 6
	jr c, LZSS_ParseHeader__read_more	; JR C, .read_more
	; Set display coordinates for progress indicator
	ldw (3120:16), 42; LD (0x0C30), 0x002A
	ldw (3122:16), 200; LD (0x0C32), 0x00C8
	; Check if already at target size
	ld xwa, (3108:16); LD XWA, (0x0C24)
	cp xwa, (3104:16)	; CP XWA, (0x0C20)
	jr nc, LZSS_ParseHeader__done	; JR NC, .exit (already done)
	; Copy remaining raw bytes
LZSS_ParseHeader__decompress_loop:
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	extz hl	; EXTZ HL
	ld wa, hl	; LD WA, HL
	calr LZSS_OutputByte_Alt	; CALR LZSS_OutputByte_Alt
	ld xwa, (3108:16); LD XWA, (0x0C24)
	cp xwa, (3104:16)	; CP XWA, (0x0C20)
	jr c, LZSS_ParseHeader__decompress_loop	; JR C, .decompress_loop
LZSS_ParseHeader__done:
	ld hl, 0:i3	; LD HL, 0 (success)
LZSS_ParseHeader__exit:
	popw iz	; POP IZ
	inc 6, xsp	; INC 6, XSP
	ret	; RET

; -----------------------------------------------------------------------------
; LZSS_Decompress - Main SLIDE4K decompression routine
; Address: 0xFFCA50
;
; Decompresses LZSS-encoded data from table_data ROM to RAM.
; Uses standard SLIDE4K format with 4KB window.
; -----------------------------------------------------------------------------
	.org 0x9FCA50 - 0x800000, 0xFF
LZSS_Decompress:
	; === Prologue: Allocate stack frame ===
	lda xsp, (xsp - 16)	; LDA XSP, XSP+0xF0 (allocate 16 bytes)
	push xiz	; PUSH XIZ

	; === Allocate 4KB sliding window buffer ===
	pushw 0x1000	; PUSH 0x1000 (4KB)
	call Boot_malloc + 0x600000	; CALL 0xFFFB56 (malloc)
	inc 2, xsp	; INC 2, XSP (pop arg)
	ld (xsp + 16), xhl	; LD (XSP+0x10), XHL - save window ptr
	ld xwa, (xsp + 16)	; LD XWA, (XSP+0x10)
	ld (xsp + 12), xwa	; LD (XSP+0x0C), XWA - copy to working ptr

	; === Pre-fill window with zeros (positions 0 to 0x0FED) ===
	ld xwa, 0:i3	; LD XWA, 0
	ld (3108:16), xwa	; LD (0x0C24), XWA - window fill index
LZSS_Decompress__prefill_loop:
	ld xwa, (3108:16); LD XWA, (0x0C24)
	ld xbc, (xsp + 16)	; LD XBC, (XSP+0x10) - window base
	add xbc, xwa	; ADD XBC, XWA
	ld (xbc), 0x0	; LD (XBC), 0x00
	ld xwa, (3108:16); LD XWA, (0x0C24)
	inc 1, xwa	; INC 1, XWA
	ld (3108:16), xwa	; LD (0x0C24), XWA
	cp xwa, 0xFEE	; CP XWA, 0x00000FEE
	jr c, LZSS_Decompress__prefill_loop	; JR C, .prefill_loop

	; === Initialize decompression state ===
	ldw (xsp + 10), 0xFEE	; LD (XSP+0x0A), 0x0FEE - window write pos
	ldw (xsp + 4), 0x0	; LD (XSP+0x04), 0x0000 - flag byte
	ld (3126:16), 0; LD (0x0C36), 0x00 - output counter
	ld xwa, 0:i3	; LD XWA, 0
	ld (3108:16), xwa	; LD (0x0C24), XWA - output position

	; === Setup source and display parameters ===
	lda xwa, (0x0099a4:24); LDA XWA, 0x0099A4 - sector buffer
	ld (3116:16), xwa	; LD (0x0C2C), XWA
	ld xwa, TD_FLASH_BASE	; LD XWA, 0x00800000 - source ROM base
	ld (3112:16), xwa	; LD (0x0C28), XWA
	ldw (3120:16), 50; LD (0x0C30), 0x0032 - display X
	ldw (3122:16), 180; LD (0x0C32), 0x00B4 - display Y
	ldw wa, 0x32	; LD WA, 0x0032
	ldw bc, 0xB4	; LD BC, 0x00B4
	ld de, 6:i3	; LD DE, 6
	call InitProgressDisplay_FillRegion + 0x600000	; CALL 0xFFCD9A (init display)

	; === Read expected decompressed size (3 bytes, little-endian) ===
	ld xwa, 0x3E8	; LD XWA, 0x000003E8 - initial guess
	ld (3104:16), xwa	; LD (0x0C20), XWA
	ldw (3124:16), 36; LD (0x0C34), 0x0024

	; === Pre-read 4 sectors for initial buffer fill ===
	ldiw_erp 0xFA, 0	; LD QIZ, 0
LZSS_Decompress__preread_loop:
	ld wa, (3124:16); LD WA, (0x0C34)
	extz xwa	; EXTZ XWA
	ldw bc, 0x2400	; LD BC, 0x2400
	mul xbc, qiz	; MUL XBC, QIZ
	ld xde, 0x99A4	; LD XDE, 0x000099A4
	add xde, xbc	; ADD XDE, XBC
	ldw bc, 0x12	; LD BC, 0x0012
	calr FDC_ReadSectorWrapper	; CALR 0xFFBF92
	addw (3124:16), 18	; ADD (0x0C34), 0x0012
	inc1w_erp 0xFA	; INC 1, QIZ
	cpiw_erp 0xFA, 4	; CP QIZ, 4
	jr c, LZSS_Decompress__preread_loop	; JR C, .preread_loop

	; === Read 8 header bytes ===
	ldiw_erp 0xFA, 0	; LD QIZ, 0
LZSS_Decompress__read_header_loop:
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	inc1w_erp 0xFA	; INC 1, QIZ
	cp_erpw 0xFA, 0x08, 0x00	; CP QIZ, 0x0008
	jr c, LZSS_Decompress__read_header_loop	; JR C, .read_header_loop

	; === Parse decompressed size (3 bytes) ===
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	extz xhl	; EXTZ XHL
	sla xhl, 16	; first (high) size byte -> bits 23..16
	ld (3104:16), xhl	; LD (0x0C20), XHL
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	sll hl, 8	; SLL 8, HL
	extz xhl	; EXTZ XHL
	add (3104:16), xhl	; ADD (0x0C20), XHL
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	extz xhl	; EXTZ XHL
	ld xwa, (3104:16); LD XWA, (0x0C20)
	add xwa, xhl	; ADD XWA, XHL
	ld (3104:16), xwa	; LD (0x0C20), XWA
	cp (3108:16), xwa	; CP (0x0C24), XWA
	jrl nc, LZSS_Decompress__done	; JRL NC, .done - already past size

; -----------------------------------------------------------------------------
; Main decompression loop
; Processes flag bytes and handles literal/back-reference encoding
; -----------------------------------------------------------------------------
LZSS_Decompress__decompress_loop:
	; === Shift flag byte and check if need new flags ===
	mrdw3 0x9F, 0x04, 0x7F	; SRLW (XSP+0x04) - shift flags right
	ld wa, (xsp + 4)	; LD WA, (XSP+0x04)
	bit 8, wa	; BIT 8, WA - check sentinel bit
	jr nz, LZSS_Decompress__flags_valid	; JR NZ, .flags_valid

	; === Read new flag byte ===
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	ld iz, hl	; LD IZ, HL
	cp iz, 0xFFFF	; CP IZ, 0xFFFF - check for EOF
	jrl z, LZSS_Decompress__done	; JRL Z, .done
	ld (xsp + 4), iz	; LD (XSP+0x04), IZ - store flags
	ormi16 (xsp + 4), 0xFF00	; OR (XSP+0x04), 0xFF00 - set sentinel

LZSS_Decompress__flags_valid:
	; === Check bit 0: 1=literal, 0=back-reference ===
	ld wa, (xsp + 4)	; LD WA, (XSP+0x04)
	bit 0, wa	; BIT 0, WA
	jr z, LZSS_Decompress__back_reference	; JR Z, .back_reference

	; === LITERAL BYTE: Read and output directly ===
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	ld iz, hl	; LD IZ, HL
	cp iz, 0xFFFF	; CP IZ, 0xFFFF
	jrl z, LZSS_Decompress__done	; JRL Z, .done
	ldto_berp A, 0xF8	; LD A, IZL - get byte value
	extz wa	; EXTZ WA
	calr LZSS_OutputByte	; CALR LZSS_OutputByte
	; Store byte in sliding window
	ld bc, (xsp + 10)	; LD BC, (XSP+0x0A) - window position
	incw 1, (xsp + 10)	; INCW 1, (XSP+0x0A)
	extz xbc	; EXTZ XBC
	add xbc, (xsp + 16)	; ADD XBC, (XSP+0x10) - add window base
	ldto_berp A, 0xF8	; LD A, IZL
	ld (xbc), a	; LD (XBC), A - store in window
	andmi16 (xsp + 10), 0xFFF	; AND (XSP+0x0A), 0x0FFF - wrap window pos
	jr LZSS_Decompress__check_done	; JR T, .check_done

LZSS_Decompress__back_reference:
	; === BACK-REFERENCE: Read offset and length ===
	; First byte: low 8 bits of offset
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	ldfr_werp HL, 0xFA	; LD QIZ, HL - save low offset
	cp_erpw 0xFA, 0xFF, 0xFF	; CP QIZ, 0xFFFF
	jr z, LZSS_Decompress__done	; JR Z, .done

	; Second byte: high 4 bits of offset + 4-bit length
	calr LZSS_ReadByte	; CALR LZSS_ReadByte
	ld (xsp + 8), hl	; LD (XSP+0x08), HL
	cpw (xsp + 8), 0xFFFF	; CP (XSP+0x08), 0xFFFF
	jr z, LZSS_Decompress__done	; JR Z, .done

	; Combine offset: (high_nibble << 8) | low_byte
	ld bc, (xsp + 8)	; LD BC, (XSP+0x08)
	and bc, 0xF0	; AND BC, 0x00F0 - extract high nibble
	sll bc, 4	; SLL 4, BC - shift to bits 11-8
	ldto_werp WA, 0xFA	; LD WA, QIZ
	or wa, bc	; OR WA, BC - combine with low byte
	ldfr_werp WA, 0xFA	; LD QIZ, WA - QIZ = 12-bit offset

	; Extract length: (byte & 0x0F) + 2
	andmi16 (xsp + 8), 0xF	; AND (XSP+0x08), 0x000F - extract length
	incw 2, (xsp + 8)	; INCW 2, (XSP+0x08) - length + 2

	; === Copy from sliding window ===
	ldw (xsp + 6), 0x0	; LD (XSP+0x06), 0x0000 - copy counter
	cpw (xsp + 8), 0x0	; CP (XSP+0x08), 0x0000 - check length
	jr c, LZSS_Decompress__check_done	; JR C, .check_done

LZSS_Decompress__copy_loop:
	; Calculate source position in window
	ldto_werp WA, 0xFA	; LD WA, QIZ - get offset
	add wa, (xsp + 6)	; ADD WA, (XSP+0x06) - add counter
	and wa, 0xFFF	; AND WA, 0x0FFF - wrap to window
	extz xwa	; EXTZ XWA
	add xwa, (xsp + 12)	; ADD XWA, (XSP+0x0C) - add window base
	ld a, (xwa)	; LD A, (XWA) - read from window
	ldfr_berp A, 0xF8	; LD IZL, A
	extz iz	; EXTZ IZ
	ldto_berp A, 0xF8	; LD A, IZL
	extz wa	; EXTZ WA
	calr LZSS_OutputByte	; CALR LZSS_OutputByte

	; Store byte in sliding window at write position
	ld bc, (xsp + 10)	; LD BC, (XSP+0x0A)
	incw 1, (xsp + 10)	; INCW 1, (XSP+0x0A)
	extz xbc	; EXTZ XBC
	add xbc, (xsp + 12)	; ADD XBC, (XSP+0x0C)
	ldto_berp A, 0xF8	; LD A, IZL
	ld (xbc), a	; LD (XBC), A
	andmi16 (xsp + 10), 0xFFF	; AND (XSP+0x0A), 0x0FFF - wrap position

	; Increment counter and check if done
	incw 1, (xsp + 6)	; INCW 1, (XSP+0x06)
	ld wa, (xsp + 6)	; LD WA, (XSP+0x06)
	cp wa, (xsp + 8)	; CP WA, (XSP+0x08) - compare with length
	jr ule, LZSS_Decompress__copy_loop	; JR ULE, .copy_loop

LZSS_Decompress__check_done:
	; === Check if decompression complete ===
	ld xwa, (3108:16); LD XWA, (0x0C24)
	cp xwa, (3104:16)	; CP XWA, (0x0C20)
	jrl c, LZSS_Decompress__decompress_loop	; JRL C, .decompress_loop

LZSS_Decompress__done:
	; === Epilogue: Free window buffer and return ===
	ld xwa, (xsp + 16)	; LD XWA, (XSP+0x10)
	push xwa	; PUSH XWA
	call Boot_free + 0x600000	; CALL 0xFFFCDD (free)
	inc 4, xsp	; INC 4, XSP
	pop xiz	; POP XIZ
	lda xsp, (xsp + 16)	; LDA XSP, XSP+0x10 (deallocate frame)
	ret	; RET

; =============================================================================
; BOOT UPDATE AND DISPLAY ROUTINES
; Addresses 0x9FCC2A to 0x9FFEE0 (12982 bytes)
;
; This section contains the main firmware update dispatcher and UI routines:
;
; FLASH UPDATE DISPATCHER (0x9FCC2A-0x9FCCFA):
;   0x9FCC2A: Boot_FlashUpdate_Main - Main update entry point
;             - Calls 0xFFEC63 to check update conditions
;             - Calls Detect_Disk_Type (0x9FBFC4)
;             - Calls Boot_Get_Region_Code (0xFFB700)
;             - Dispatches to appropriate handler based on disk type
;             - Displays UI bitmaps during erase/write
;
; DISPLAY ROUTINES (0x9FCCFB-0x9FD7FF):
;   0x9FCCFB: DrawBitmap_UpdateDisplay - Render bitmap to screen
;   0x9FCD9A: InitProgressDisplay_FillRegion - Initialize progress indicator
;   0x9FCDFC: VGA_WritePort - Write to VGA I/O port
;   0x9FCE12: VGA_ReadPort - Read from VGA I/O port
;   0x9FCE1E-0x9FD7BD: VGA_Init - Complete VGA initialization sequence
;
; FLASH UPDATE HANDLERS (0x9FD800-0x9FEA9C):
;   Handlers for different update file types (1-8):
;   - Program ROM disk 1/2
;   - Table Data ROM disk 1/2
;   - Compressed custom data
;   - HDAE5000 firmware
;   - Compressed Program/Table ROM
;
; INTERRUPT HANDLERS:
;   0x9FEA9D: INTTC3_HANDLER - Timer counter 3
;   0x9FEAB2: INT4_HANDLER - External interrupt 4
;   0x9FF229: INTA_HANDLER - External interrupt A
;   0x9FF2AE: INTTX1_HANDLER - Serial TX 1
;   0x9FF2D0: INTRX1_HANDLER - Serial RX 1
;
; MEMORY ALLOCATION (0x9FFB00-0x9FFCFF):
;   0x9FFB56: malloc - Allocate memory from heap
;   0x9FFCDD: free - Free allocated memory
;
; See also: ../technics-docs/boot-sequence.md for boot flow documentation
; =============================================================================

; =============================================================================
; Boot_FlashUpdate_Main - Main flash update entry point
; Address: 0x9FCC2A
; Called from boot sequence to check for and perform flash updates
; =============================================================================
Boot_FlashUpdate_Main:
	pushw_erp 0xFA	; PUSH QIZ
	call Boot_CheckDiskPresent + 0x600000	; CALL 0xFFEC63 - check disk present
	cp l, 0:i3	; CP L, 0
	jrl z, Boot_FlashUpdate_Main__update_done	; JRL Z, .update_done - no disk

	; Initialize FDC and detect disk type
	calr FDC_Reset	; CALR 0x9FBF07 (FDC_Init)
	calr Boot_DetectDiskType	; CALR Boot_DetectDiskType
	ldfr_berp L, 0xFB	; LD QIZH, L - save disk type

	; Check region code
	call Get_Region_Code + 0x600000	; CALL 0xFFB700 (Boot_Get_Region_Code)
	cp l, 4:i3	; CP L, 4
	jr z, Boot_FlashUpdate_Main__update_check_flash	; 66 58

	; Check flash ID
	call Flash_ReadID_32bit + 0x600000	; CALL 0xFFBC6A
	cp xhl, 0xFFFFFFFF	; CP XHL, 0xFFFFFFFF
	jr z, Boot_FlashUpdate_Main__update_check_flash	; 66 4c

	; Check disk type 6 (skip for type 6)
	cpib_erp 0xFB, 6	; CP QIZH, 6
	jr z, Boot_FlashUpdate_Main__update_check_flash	; 66 47

	; Display "Flash Memory Update" message
	pushw 0x8	; PUSH 0x0008 - color
	pushw 0x2	; PUSH 0x0002 - mode
	ld xwa, Bitmap_1bit_Flash_Memory_Update + 0x600000	; LD XWA, 0x00FFA156 - bitmap addr
	ldw bc, 0x30	; LD BC, 0x0030 - X
	ldw de, 0x50	; LD DE, 0x0050 - Y
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL DrawBitmap_UpdateDisplay

	; Execute disk type handler
	ldto_berp A, 0xFB	; LD A, QIZH
	extz wa	; EXTZ WA
	calr Boot_LoadDiskData	; CALR Boot_LoadDiskData

	; Display "Completed" message
	pushw 0x8	; PUSH 0x0008
	pushw 0x1	; PUSH 0x0001
	ld xwa, Bitmap_1bit_Completed + 0x600000	; LD XWA, 0x00FFA88E
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xA0	; LD DE, 0x00A0
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL DrawBitmap_UpdateDisplay

	; Display "Turn On Again" message
	pushw 0x8	; PUSH 0x0008
	pushw 0x1	; PUSH 0x0001
	ld xwa, Bitmap_1bit_Turn_On_AGAIN + 0x600000	; LD XWA, 0x00FFB22E
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xC8	; LD DE, 0x00C8
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL DrawBitmap_UpdateDisplay

Boot_FlashUpdate_Main__update_check_flash:
	; Read flash ID with bank 2
	ld wa, 2:i3	; LD WA, 2
	call Flash_ReadID_16bit + 0x600000	; CALL 0xFFB888 (Flash_ReadID_16bit)
	cp hl, 0xFFFF	; CP HL, 0xFFFF
	jr z, Boot_FlashUpdate_Main__update_done	; 66 4c

	; Only proceed if disk type 6
	cpib_erp 0xFB, 6	; CP QIZH, 6
	jr nz, Boot_FlashUpdate_Main__update_done	; 6e 47

	; Display update messages and perform update
	pushw 0x8	; PUSH 0x0008
	pushw 0x2	; PUSH 0x0002
	ld xwa, Bitmap_1bit_Flash_Memory_Update + 0x600000	; LD XWA, 0x00FFA156
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0x50	; LD DE, 0x0050
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL DrawBitmap_UpdateDisplay

	ldto_berp A, 0xFB	; LD A, QIZH
	extz wa	; EXTZ WA
	calr Boot_LoadDiskData	; CALR Boot_LoadDiskData

	pushw 0x8	; PUSH 0x0008
	pushw 0x1	; PUSH 0x0001
	ld xwa, Bitmap_1bit_Completed + 0x600000	; LD XWA, 0x00FFA88E
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xA0	; LD DE, 0x00A0
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL DrawBitmap_UpdateDisplay

	pushw 0x8	; PUSH 0x0008
	pushw 0x1	; PUSH 0x0001
	ld xwa, Bitmap_1bit_Turn_On_AGAIN + 0x600000	; LD XWA, 0x00FFB22E
	ldw bc, 0x30	; LD BC, 0x0030
	ldw de, 0xC8	; LD DE, 0x00C8
	call DrawBitmap_UpdateDisplay + 0x600000	; CALL DrawBitmap_UpdateDisplay

Boot_FlashUpdate_Main__update_done:
	popw_erp 0xFA	; POP QIZ
	ret	; 0e

; =============================================================================
; DrawBitmap_UpdateDisplay - Render 1-bit bitmap to VGA framebuffer
; Address: 0x9FCCFB
; Stack params: XWA=bitmap addr, BC=X pos, DE=Y pos, +4=mode, +6=color
; VGA framebuffer at 0x1A0000
; =============================================================================
DrawBitmap_UpdateDisplay:
	dec 4, xsp	; DEC 4, XSP - allocate 4 bytes
	pushw iz	; 2e
	ld hl, bc	; LD HL, BC - save X
	ld (xsp + 2), xwa	; LD (XSP+0x02), XWA - bitmap addr
	ld iy, hl	; LD IY, HL - IY = X position
	ld ix, de	; LD IX, DE - IX = Y position
	inc 1, ix	; INC 1, IX - Y + 1
	ld iz, 0:i3	; LD IZ, 0 - row counter

DrawBitmap_UpdateDisplay__db_row_loop:
	ld wa, iz	; LD WA, IZ
	extz xwa	; EXTZ XWA
	div wa, 0x1C	; DIV WA, 0x001C - 28 bytes per row
	ldto_werp WA, 0xE2	; LD WA, QWA - get remainder
	cp wa, 0:i3	; CP WA, 0
	jr nz, DrawBitmap_UpdateDisplay__db_not_row_start	; 6e 04
	ld iy, hl	; LD IY, HL - reset X to start
	dec 1, ix	; DEC 1, IX - decrement Y

DrawBitmap_UpdateDisplay__db_not_row_start:
	ldiw_erp 0xEE, 0	; LD QHL, 0 - bit counter
DrawBitmap_UpdateDisplay__db_next_pixel:
	ld de, iz	; LD DE, IZ
	extz xde	; EXTZ XDE
	add xde, (xsp + 2)	; ADD XDE, (XSP+0x02) - bitmap offset
	lda xwa, (4164:16); LDA XWA, 0x1044
	ldto_werp BC, 0xEE	; LD BC, QHL
	extz xbc	; EXTZ XBC
	add xbc, xwa	; ADD XBC, XWA
	ld a, (xbc)	; LD A, (XBC) - get bitmask byte
	and a, (xde)	; AND A, (XDE) - mask with bitmap data
	ldfr_berp A, 0xF2	; LD QIXL, A

DrawBitmap_UpdateDisplay__db_calc_addr:
	ld de, ix	; LD DE, IX - Y position
	extz xde	; EXTZ XDE
	lda xbc, (0x043c00:24); LDA XBC, 0x043C00 - VGA base
	ld xwa, xde	; LD XWA, XDE
	sll xwa, 2	; SLL 2, XWA - Y * 4
	add xwa, xde	; ADD XWA, XDE - Y * 5
	sll xwa, 6	; SLL 6, XWA - Y * 320

	; Check if bit set (foreground or background)
	cpib_erp 0xF2, 0	; CP QIXL, 0
	jr z, DrawBitmap_UpdateDisplay__db_background	; 66 13

	; Foreground pixel
	ld de, iy	; LD DE, IY
	inc 1, iy	; INC 1, IY
	extz xde	; EXTZ XDE
	add xwa, xde	; ADD XWA, XDE - add X offset
	ld xde, xbc	; LD XDE, XBC
	add xde, xwa	; ADD XDE, XWA - final framebuffer addr
	ld a, (xsp + 10)	; LD A, (XSP+0x0A) - foreground color
	ld (xde), a	; LD (XDE), A
	jr DrawBitmap_UpdateDisplay__db_next_bit	; 68 11

DrawBitmap_UpdateDisplay__db_background:
	ld de, iy	; LD DE, IY
	inc 1, iy	; INC 1, IY
	extz xde	; EXTZ XDE
	add xwa, xde	; ADD XWA, XDE
	ld xde, xbc	; LD XDE, XBC
	add xde, xwa	; ADD XDE, XWA
	ld a, (xsp + 12)	; LD A, (XSP+0x0C) - background color
	ld (xde), a	; LD (XDE), A

DrawBitmap_UpdateDisplay__db_next_bit:
	inc1w_erp 0xEE	; INC 1, QHL
	cp_erpw 0xEE, 0x08, 0x00	; CP QHL, 0x0008 - 8 bits per byte
	jr c, DrawBitmap_UpdateDisplay__db_next_pixel	; JR C, next bit in same byte

	; Next row byte
	inc 1, iz	; INC 1, IZ
	cp iz, 0x268	; CP IZ, 0x0268 - 616 bytes total
	jr c, DrawBitmap_UpdateDisplay__db_row_loop	; 67 83

	; Flush VGA display
	lda xwa, (0x1a0000:24); LDA XWA, 0x1A0000
	ldw de, 0x9600	; LD DE, 0x9600 - framebuffer size
	call BootRAM_MemoryCopy	; CALL 0xFFFB0F

	popw iz	; 4e
	inc 4, xsp	; INC 4, XSP
	retd 0x4	; RETD 0x0004

; =============================================================================
; InitProgressDisplay_FillRegion - Initialize progress display bar
; Address: 0x9FCD9A
; Stack params: WA=start value, BC=X pos, DE=mode, E=bar width
; Writes to VGA framebuffer at 0x1A0000
; =============================================================================
InitProgressDisplay_FillRegion:
	dec 6, xsp	; DEC 6, XSP
	push xiz	; 3e
	ld (xsp + 6), e	; LD (XSP+0x06), E
	ld (xsp + 8), wa	; LD (XSP+0x08), WA
	ld ix, bc	; LD IX, BC
	ld (xsp + 4), bc	; LD (XSP+0x04), BC
	addiw_da (xsp + 4), 0xC	; ADD (XSP+0x04), 0x000C - X + 12
	cp ix, (xsp + 4)	; CP IX, (XSP+0x04)
	jr nc, InitProgressDisplay_FillRegion__idp_done	; 6f 46

InitProgressDisplay_FillRegion__idp_x_loop:
	ld iy, (xsp + 8)	; LD IY, (XSP+0x08)
	ld bc, iy	; LD BC, IY
	inc 6, bc	; INC 6, BC - IY + 6
	cp iy, bc	; CP IY, BC
	jr nc, InitProgressDisplay_FillRegion__idp_next_x	; 6f 34

InitProgressDisplay_FillRegion__idp_y_loop:
	ld de, iy	; LD DE, IY
	extz xde	; EXTZ XDE
	ld wa, ix	; LD WA, IX
	extz xwa	; EXTZ XWA
	ld xhl, xwa	; LD XHL, XWA
	sll xhl, 2	; SLL 2, XHL
	add xhl, xwa	; ADD XHL, XWA
	sll xhl, 6	; SLL 6, XHL - Y * 320
	add xhl, xde	; ADD XHL, XDE
	srl xhl, 1	; SRL 1, XHL - word align
	add xhl, xhl	; ADD XHL, XHL
	ld xiz, 0x1A0000	; LD XIZ, 0x001A0000
	add xiz, xhl	; ADD XIZ, XHL
	ld a, (xsp + 6)	; LD A, (XSP+0x06)
	extz wa	; EXTZ WA
	ld de, wa	; LD DE, WA
	sll de, 8	; SLL 8, DE
	or wa, de	; OR WA, DE - duplicate byte
	ld (xiz), wa	; LD (XIZ), WA

	inc 2, iy	; INC 2, IY
	cp iy, bc	; CP IY, BC
	jr c, InitProgressDisplay_FillRegion__idp_y_loop	; 67 cc

InitProgressDisplay_FillRegion__idp_next_x:
	inc 1, ix	; INC 1, IX
	cp ix, (xsp + 4)	; CP IX, (XSP+0x04)
	jr c, InitProgressDisplay_FillRegion__idp_x_loop	; 67 ba

InitProgressDisplay_FillRegion__idp_done:
	pop xiz	; 5e
	inc 6, xsp	; INC 6, XSP
	ret	; 0e

; =============================================================================
; VGA Helper Routines and Constants
; =============================================================================

; VGA Constants (shared with maincpu)
	.include "shared/vga_constants.s"

; Additional constants for VGA init
.equ OFFSCREEN_BUFFER_1, 0x43c00	; Offscreen video buffer

; Memory routines in high RAM (boot code is copied there during update)
.equ BootRAM_MemoryFill, 0xFFFB18	; Fill memory with pattern
.equ BootRAM_MemoryCopy, 0xFFFB0F	; Copy memory block

; =============================================================================
; VGA Register I/O Routines - Shared with maincpu ROM
; Address: 0x9FCDFC-0x9FCE1D (34 bytes)
; =============================================================================
	.include "shared/vga_io.s"

; =============================================================================
; VGA_Init - VGA Register Initialization (Shared with maincpu)
; Address: 0x9FCE1E-0x9FD7E7 (2506 bytes)
;
; Extensive initialization of VGA hardware registers using shared code.
; The VGA controller is memory-mapped at 0x170000 for I/O ports.
; Framebuffer is at 0x1A0000 (320x240, 8bpp).
; =============================================================================
	.include "shared/vga_init.s"

	; === ROM-specific ending: initialize video buffers ===
	; (Boot code runs from high RAM, so these are absolute calls)
	call BootRAM_MemoryFill
	lda xwa, (0x1a0000:24)
	ld xbc, 0x43C00
	ldw de, 0x9600
	call BootRAM_MemoryCopy

	; Turn screen on (RET_VGA_SEQUENCER 01h, 001h with JRL optimization)
	VGA_WRITE VGA_SEQ_ADDR, 0x1
	ldw wa, 0x3C5
	ld bc, 1:i3
	jrl Write_VGA_Register

; Small utility routine at 0x9FD7E2 (table_data specific, not in maincpu)
; Purpose unknown - possibly initialization/cleanup
VGA_FinalizeInitialization:
	ld (xwa), 0x0
	ld hl, 0:i3
	ret

; =============================================================================
; FDC HELPER ROUTINES (0x9FD7E8-0x9FD8A4)
; Low-level FDC register access at 0x110000
; =============================================================================

; -----------------------------------------------------------------------------
; FDC_ReadStatus - Read FDC main status register
; Address: 0x9FD7E8
; Returns: L = status byte from 0x110008
; -----------------------------------------------------------------------------
FDC_ReadStatus:
	ld l, (0x110008:24); LD L, (0x110008)
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_ReadData - Read FDC data register
; Address: 0x9FD7EE
; Returns: L = data byte from 0x11000A
; -----------------------------------------------------------------------------
FDC_ReadData:
	ld l, (0x11000a:24); LD L, (0x11000A)
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_WriteStatus - Write to the FDC AUXILIARY COMMAND register
; Address: 0x9FD7F4
; Input: A = auxiliary command byte
; 0x110008 reads as the uPD72068 main status register but WRITES reach its
; auxiliary command register (0x36 software reset, rate|0x0B control internal
; mode, drives|0x0E enable motors, 0x4F select format, 0x33/0x34/0x35).
; The name is kept for history; see boot_fdc_driver.s for the command layer.
; -----------------------------------------------------------------------------
FDC_WriteStatus:
	ld (0x110008:24), a; LD (0x110008), A
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_SaveCommand - Save command to history buffer
; Address: 0x9FD7FA
; Saves current command at 0x0D50 to 0x0D4E, stores new command
; -----------------------------------------------------------------------------
FDC_SaveCommand:
	ldmm8 3406, 3408	; LD (0x0D4E), (0x0D50)
	ld (3408:16), a; LD (0x0D50), A
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_WriteData - Write to FDC data register
; Address: 0x9FD805
; Input: A = value to write
; -----------------------------------------------------------------------------
FDC_WriteData:
	ld (0x11000a:24), a; LD (0x11000A), A
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_WaitReady - Wait until the FDC is idle
; Address: 0x9FD80B
; Polls the main status register until the busy bits (mask 0x1F: D0B-D3B
; drive-seek busy + CB command busy) all clear; 500-tick timeout raises
; error 1 via FDC_Error (0x9FE231)
; -----------------------------------------------------------------------------
FDC_WaitReady:
	push xiz	; 3e
	ld iz, (3072:16); LD IZ, (0x0C00) - get timer
	ldi_erpw 0xFA, 0x80, 0x00	; LD QIZ, 0x0080 - flag = pending

FDC_WaitReady__fwr_check:
	cp_erpw 0xFA, 0x80, 0x00	; CP QIZ, 0x0080
	jr nz, FDC_WaitReady__fwr_check_result	; 6e 29
FDC_WaitReady__fwr_loop:
	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	and l, 0x1F	; AND L, 0x1F - mask status bits
	ld a, l	; LD A, L
	extz wa	; EXTZ WA
	cp wa, 0:i3	; CP WA, 0 - check if ready
	jr nz, FDC_WaitReady__fwr_not_ready	; 6e 03
	ldiw_erp 0xFA, 0	; LD QIZ, 0 - flag = success

FDC_WaitReady__fwr_not_ready:
	ld wa, (3072:16); LD WA, (0x0C00)
	sub wa, iz	; SUB WA, IZ
	cp wa, 0x1F4	; CP WA, 0x01F4 (500) - timeout
	jr ule, FDC_WaitReady__fwr_continue	; 63 05
	ldi_erpw 0xFA, 0xFF, 0xFF	; LD QIZ, 0xFFFF - flag = timeout

FDC_WaitReady__fwr_continue:
	cp_erpw 0xFA, 0x80, 0x00	; CP QIZ, 0x0080
	jr z, FDC_WaitReady__fwr_loop	; 66 d7

FDC_WaitReady__fwr_check_result:
	cpiw_erp 0xFA, 0	; CP QIZ, 0
	jr z, FDC_WaitReady__fwr_done	; 66 05
	ld wa, 1:i3	; LD WA, 1 - error code
	calr FDC_Error	; CALR FDC_Error

FDC_WaitReady__fwr_done:
	pop xiz	; 5e
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_WaitComplete - Wait for the FDC parameter phase
; Address: 0x9FD851
; Polls for RQM|CB (mask 0x90): command busy and requesting the next byte;
; 500-tick timeout raises error 1
; -----------------------------------------------------------------------------
FDC_WaitComplete:
	push xiz	; 3e
	ld iz, (3072:16); LD IZ, (0x0C00)
	ldi_erpw 0xFA, 0x80, 0x00	; LD QIZ, 0x0080

FDC_WaitComplete__fwc_check:
	cp_erpw 0xFA, 0x80, 0x00	; CP QIZ, 0x0080
	jr nz, FDC_WaitComplete__fwc_check_result	; 6e 26
FDC_WaitComplete__fwc_loop:
	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	and l, 0x90	; AND L, 0x90 - mask DIO+RQM
	cp l, 0x90	; CP L, 0x90 - both set?
	jr nz, FDC_WaitComplete__fwc_not_done	; 6e 03
	ldiw_erp 0xFA, 0	; LD QIZ, 0 - success

FDC_WaitComplete__fwc_not_done:
	ld wa, (3072:16); LD WA, (0x0C00)
	sub wa, iz	; SUB WA, IZ
	cp wa, 0x1F4	; CP WA, 0x01F4 - timeout
	jr ule, FDC_WaitComplete__fwc_continue	; 63 05
	ldi_erpw 0xFA, 0xFF, 0xFF	; LD QIZ, 0xFFFF

FDC_WaitComplete__fwc_continue:
	cp_erpw 0xFA, 0x80, 0x00	; CP QIZ, 0x0080
	jr z, FDC_WaitComplete__fwc_loop	; 66 da

FDC_WaitComplete__fwc_check_result:
	cpiw_erp 0xFA, 0	; CP QIZ, 0
	jr z, FDC_WaitComplete__fwc_done	; 66 05
	ld wa, 1:i3	; LD WA, 1
	calr FDC_Error	; CALR FDC_Error

FDC_WaitComplete__fwc_done:
	pop xiz	; 5e
	ret	; 0e

; -----------------------------------------------------------------------------
; FDC_Seek - Strobe an FDC software reset and invalidate the track cache
; Address: 0x9FD894
; MISNOMER kept for history: 0x36 is the uPD72068 SOFTWARE RESET auxiliary
; command, not a seek.  After a 2-tick delay it marks the current track
; unknown (0x0D32 = 0xFF) so the next FDC_CmdSeek really seeks.
; -----------------------------------------------------------------------------
FDC_Seek:
	ldw wa, 0x36	; LD WA, 0x0036 - aux cmd 0x36 = software reset
	calr FDC_WriteStatus	; CALR FDC_WriteStatus
	ld wa, 2:i3	; LD WA, 2 - delay parameter
	calr Boot_Delay	; CALR Boot_Delay
	ld (3378:16), 255; LD (0x0D32), 0xFF - track cache = unknown
	ret	; 0e

; =============================================================================
; First-stage bootloader FDC command-layer driver
; Address: 0x9FD8A5-0x9FEA9C (boot-time alias 0xFFD8A5-0xFFEA9C), 4600 bytes
;
; Full disassembly in boot_fdc_driver.s (this was previously a set of seven
; .incbin slices of bootcode_flash_handlers.bin, mislabeled "Flash Update
; Type Handlers").  Public entry: FDC_Request.  Renames, kept greppable:
;   Boot_TimerTick     -> FDC_PulseTC          (pulses the FDC TC line, PH0)
;   Boot_ClearWatchdog -> FDC_WaitRQM_Timeout  (FDC status wait, no watchdog)
; =============================================================================
	.include "boot_fdc_driver.s"

; =============================================================================
; BootTimer_InterruptHandler - Timer Counter 3 Interrupt Handler
; Address: 0x9FEA9D (boot-time: 0xFFEA9D)
;
; Periodic housekeeping while the bootloader runs:
;   - Saves all registers
;   - Calls FDC_PulseTC (0x9FDD17) to pulse the FDC terminal-count line so a
;     stuck multi-sector transfer cannot hang the boot
;   - Calls Boot_UpdateDisplay (0x9FDD26) to request a display refresh
;   - Restores registers and returns from interrupt
; =============================================================================
BootTimer_InterruptHandler:
	push xiz	; 3e - save all registers
	push xiy	; 3d
	push xix	; 3c
	push xhl	; 3b
	push xde	; 3a
	push xbc	; 39
	push xwa	; 38
	calr FDC_PulseTC	; CALR FDC_PulseTC (formerly Boot_TimerTick)
	calr Boot_UpdateDisplay	; CALR Boot_UpdateDisplay
	pop xwa	; 58 - restore all registers
	pop xbc	; 59
	pop xde	; 5a
	pop xhl	; 5b
	pop xix	; 5c
	pop xiy	; 5d
	pop xiz	; 5e
	reti	; 07

; =============================================================================
; Handler_INT4 - FDC (Floppy Disk Controller) Interrupt Handler
; Address: 0x9FEAB2 (boot-time: 0xFFEAB2)
;
; Handles FDC interrupt during firmware update:
;   - Timeout counter (100 iterations max)
;   - Polls FDC status for RQM (bit 7) and DIO (bit 6)
;   - Reads result bytes from FDC data register
;   - Stores results at 0x0C8E buffer
;   - Calls FDC_ProcessResults (0x9FDF17) when complete
; =============================================================================
Handler_INT4:
	push xiz	; 3e
	push xiy	; 3d
	push xix	; 3c
	push xhl	; 3b
	push xde	; 3a
	push xbc	; 39
	push xwa	; 38
	ld iz, 0:i3	; LD IZ, 0 - timeout counter

Handler_INT4__int4_check_timeout:
	ld wa, iz	; LD WA, IZ - get current count
	inc 1, iz	; INC 1, IZ
	cp wa, 0x64	; CP WA, 0x0064 (100)
	jr gt, Handler_INT4__int4_done	; 6a 59 - timeout exceeded

	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	bit 7, l	; BIT 7, L - check RQM (request for master)
	jr z, Handler_INT4__int4_check_timeout	; 66 ee - not ready, keep polling

Handler_INT4__int4_wait_rqm:
	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	bit 7, l	; BIT 7, L
	jr z, Handler_INT4__int4_wait_rqm	; 66 f8

	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	bit 6, l	; BIT 6, L - check DIO (data direction)
	jr nz, Handler_INT4__int4_setup_buffer	; 6e 18 - FDC has data for us

	; FDC needs data from us - send sense interrupt command
	ld l, 0x0:opc	; LD L, 0x00
	cp l, 0x80	; CP L, 0x80
	jr z, Handler_INT4__int4_send_cmd	; 66 0b

Handler_INT4__int4_poll_ready:
	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	and l, 0xF0	; AND L, 0xF0 - mask status bits
	cp l, 0x80	; CP L, 0x80 - RQM set, DIO clear?
	jr nz, Handler_INT4__int4_poll_ready	; 6e f5

Handler_INT4__int4_send_cmd:
	ldw wa, 0x8	; LD WA, 0x0008 - sense interrupt command
	calr FDC_WriteData	; CALR FDC_WriteData

Handler_INT4__int4_setup_buffer:
	lda xiz, (3214:16); LDA XIZ, 0x0C8E - result buffer
	inc 1, xiz	; INC 1, XIZ

Handler_INT4__int4_read_loop:
	calr FDC_WaitRQM_Timeout	; CALR FDC_WaitRQM_Timeout (formerly Boot_ClearWatchdog)
	calr FDC_ReadData	; CALR FDC_ReadData
	ld (xiz+), l	; LD (XIZ+), L - store result byte

Handler_INT4__int4_check_more:
	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	bit 7, l	; BIT 7, L - RQM set?
	jr z, Handler_INT4__int4_check_more	; 66 f8 - wait for ready

	calr FDC_ReadStatus	; CALR FDC_ReadStatus
	bit 6, l	; BIT 6, L - DIO set?
	jr nz, Handler_INT4__int4_read_loop	; 6e e7 - more data to read

	calr FDC_ProcessResults	; CALR FDC_ProcessResults
	cp (3215:16), 128; CP (0x0C8F), 0x80 - check status
	jr nz, Handler_INT4__int4_wait_rqm	; 6e af - not done, continue

Handler_INT4__int4_done:
	ld (3214:16), 0; LD (0x0C8E), 0x0000 - clear buffer
	pop xwa	; 58
	pop xbc	; 59
	pop xde	; 5a
	pop xhl	; 5b
	pop xix	; 5c
	pop xiy	; 5d
	pop xiz	; 5e
	reti	; 07

	.include "boot_disk_probe.s"	; 0x9FEB2B-0x9FEC6D FDC disk-format probe
	.include "boot_cpserial.s"	; 0x9FEC6E-0x9FF228 boot-time CP-serial driver

	.org 0x9FF229 - 0x800000, 0xFF
	.include "boot_cpserial_isr.s"	; 0x9FF229-0x9FF2F1 INTA/INTTX1/INTRX1 ISRs + state dispatch table
	.include "boot_cpserial_states.s"	; 0x9FF2F2-0x9FFB2E state handlers, packet codecs, shared AudioMix/memory library

; =============================================================================
; Boot C Runtime and Debug Output (formerly includes/bootcode_malloc_and_after.bin
; and the tail of includes/bootcode_serial_state.bin)
; Address: 0x9FFB2F-0x9FFEDF (RESET_HANDLER begins at 0x9FFEE0)
;
; boot_clib.s also opens with Boot_sbrk (0x9FFB2F), the bump allocator
; backing Boot_malloc.
;
; boot_clib.s - compiler-runtime/libc subset used by the bootloader:
;   Boot_malloc (0x9FFB56)     first-fit heap allocate, list head RAM 0x0099A0
;   Boot_memcmp (0x9FFBDC)     bounded compare (strncmp-style NUL early-exit)
;   Boot_SDivMod32 (0x9FFC0E)  signed 32-bit divide/modulo wrapper, mode in D
;   Boot_SMod32 (0x9FFC55) / Boot_SDiv32 (0x9FFC59)  unreferenced entry stubs
;   Boot_UMod32 (0x9FFC5D)     unsigned modulo entry
;   Boot_UDivMod32 (0x9FFC63)  unsigned 32/32 divide core (XHL=q, XDE=r)
;   Boot_free (0x9FFCDD)       address-ordered coalescing free
;   Boot_free_DeadTail9998 (0x9FFD7D)  UNREACHABLE orphaned copy of the
;       Boot_free tail (pool 0x009998) - dead code with no entry point
;
; boot_debug.s - debug character output, DISABLED in shipped firmware:
;   Debug_OutputChar (0x9FFE80), Debug_OutputHexByte (0x9FFE86),
;   Debug_OutputString (0x9FFEA1), Debug_NibbleToHex (0x9FFEB4),
;   Debug_SendChar (0x9FFEC1) - NOP-patched stub, emits nothing
; =============================================================================
	.include "boot_clib.s"
	.include "boot_debug.s"

	.org 0x9FFEE0 - 0x800000, 0xFF
RESET_HANDLER:
	jp BOOT_ENTRY
	ret	; Dead code (never reached, but present in ROM)

; Reserved area between RESET_HANDLER and interrupt vector table
	.fill 9, 1, 0xff	; Padding
; IDENTIFIED 2026-09-25 (the four ".byte ... Reserved entry N?" lines that
; stood here, re-framed on the reader's boundaries): Boot_CallInitHandlers
; (shared/boot_call_init_handlers.s, table_data variant) compares the word
; at boot address 0xFFFEEE with 0xFFFF and, only if equal, walks four 32-bit
; entries at 0xFFFEF0 (ld_sril3 xbc,(xde+4*i)) and calls
; AudioMix_WriteChannelGroup with each.  Here the word is 0x0000, so the
; loop never runs; the entries all hold 0x00000400.
BootInit_EnableFlag:
	.short	0x0000
BootInit_EntryTable:
	.long	0x00000400, 0x00000400, 0x00000400, 0x00000400



	.org 0x9FFF00 - 0x800000, 0xFF

; TMP94C241F Interrupt Vector Table
; These addresses are what the CPU sees at boot time (ROM at 0xE00000)

	.long BOOT_RESET_HANDLER	; RESET

	.long BOOT_EMPTY_HANDLER	; SWI 1
	.long BOOT_EMPTY_HANDLER	; SWI 2
	.long BOOT_EMPTY_HANDLER	; SWI 3
	.long BOOT_EMPTY_HANDLER	; SWI 4
	.long BOOT_EMPTY_HANDLER	; SWI 5
	.long BOOT_EMPTY_HANDLER	; SWI 6
	.long BOOT_EMPTY_HANDLER	; SWI 7

	.long BOOT_NMI_HANDLER	; NMI

	.long BOOT_EMPTY_HANDLER	; INTWD (watchdog)
	.long BOOT_EMPTY_HANDLER	; INT0 Pin

	.long BOOT_INT4_HANDLER	; INT4 Pin

	.long BOOT_EMPTY_HANDLER	; INT5 Pin
	.long BOOT_EMPTY_HANDLER	; INT6 Pin
	.long BOOT_EMPTY_HANDLER	; INT7 Pin
	.long BOOT_EMPTY_HANDLER	; (RESERVED)
	.long BOOT_EMPTY_HANDLER	; INT8 Pin
	.long BOOT_EMPTY_HANDLER	; INT9 Pin

	.long BOOT_INTA_HANDLER	; INTA Pin

	.long BOOT_EMPTY_HANDLER	; INTB Pin
	.long BOOT_EMPTY_HANDLER	; INTT0

	.long BOOT_INTT1_HANDLER	; INTT1

	.long BOOT_EMPTY_HANDLER	; INTT2
	.long BOOT_EMPTY_HANDLER	; INTT3
	.long BOOT_EMPTY_HANDLER	; INTTR4
	.long BOOT_EMPTY_HANDLER	; INTTR5
	.long BOOT_EMPTY_HANDLER	; INTTR6
	.long BOOT_EMPTY_HANDLER	; INTTR7
	.long BOOT_EMPTY_HANDLER	; INTTR8
	.long BOOT_EMPTY_HANDLER	; INTTR9
	.long BOOT_EMPTY_HANDLER	; INTTRA
	.long BOOT_EMPTY_HANDLER	; INTTRB
	.long BOOT_EMPTY_HANDLER	; INTRX0
	.long BOOT_EMPTY_HANDLER	; INTTX0

	.long BOOT_INTRX1_HANDLER	; INTRX1
	.long BOOT_INTTX1_HANDLER	; INTTX1

	.long BOOT_EMPTY_HANDLER	; INTAD
	.long BOOT_EMPTY_HANDLER	; INTTC0
	.long BOOT_EMPTY_HANDLER	; INTTC1
	.long BOOT_EMPTY_HANDLER	; INTTC2

	.long BOOT_INTTC3_HANDLER	; INTTC3

	.long BOOT_EMPTY_HANDLER	; INTTC4
	.long BOOT_EMPTY_HANDLER	; INTTC5
	.long BOOT_EMPTY_HANDLER	; INTTC6
	.long BOOT_EMPTY_HANDLER	; INTTC7

; RESERVED:
	.fill 12, 1, 0xff
	.asciz "hkt_87.ssf"
	.zero 5
; RESERVED:
	.fill 48, 1, 0xff
