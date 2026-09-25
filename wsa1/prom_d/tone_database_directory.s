; ==============================================================================
; Technics SX-WSA1R -- prom_d -- THE TONE DATABASE
; DIRECTORY, PROGRAM MAPS AND THE TONE-RECORD OFFSET TABLE
; ==============================================================================
;
; ⚠ GENERATED.  Edit scripts/analysis/gen_prom_d_asm.py, never this file;
; then run the gate:
;     python3 scripts/analysis/gen_prom_d_asm.py
;     python3 scripts/analysis/assert_byte_identical.py
;
; ⚠ NOT A TRANSLATION UNIT.  It is `.include`d by prom_d/wsa1_prom_d.s,
; which carries this image's whole provenance -- how the base 0x00F00000
; was established two independent ways, why prom_d/prom_d.ld's ORIGIN stays
; 0, the label census graded by provenance, and every standing caveat.
; READ THAT FILE FIRST.  None of it is repeated here, and none of it was
; reworded to make this split: the split MOVES lines, it does not edit them.
;
; file 0x00000 .. 0x013C7   (5,064 bytes)
;
; First of the three, mirroring
; ../kn5000-roms-disasm/table_data/tone_database_directory.s, which holds the
; same three things for the KN5000: the slot directory, the program maps and
; the tone-record offset table (its ROM 0x830000-0x8324D3).
;
; ★ THE BOUNDARY IS THE IMAGE'S OWN.  This file ends at 0x013C8, the smallest
; offset in the tone-record table at directory slot +0x08 -- i.e. at the first
; tone record.  That is the same rule the KN5000 module follows; over there the
; first record is ToneRec_000 at 0x8324D4.
;
; ⚠ ONE REGION HERE HAS NO KN5000 COUNTERPART.  Slot +0xA8 is UNUSED in the
; KN5000, so ToneDB_OctaveShiftByProgram has no sibling region to mirror and no
; name to transplant.  It is in this file because the boundary rule is `the head
; of the database, up to the first tone record`, and because it is a
; program-indexed map like the two tables above it -- not because the KN5000
; puts anything there.  Its own banner below states what is established about it
; and what is not.
;
; WHAT IS IN IT -- read back out of this file's own region banners:
;   ToneDB_Directory -- the 48-slot section directory          0x00000 .. 0x000FF   (256 bytes)
;   ToneDB_BankMap -- directory slot +0x6C                     0x00100 .. 0x0017F   (128 bytes)
;   ToneDB_ToneNumBanks -- directory slot +0x04                0x00180 .. 0x00B7F   (2560 bytes)
;   ToneDB_ToneOffsetTable -- directory slot +0x08             0x00B80 .. 0x00FC7   (1096 bytes)
;   ToneDB_OctaveShiftByProgram -- directory slot +0xA8        0x00FC8 .. 0x013C7   (1024 bytes)
; ==============================================================================

; ==========================================================================
; ToneDB_Directory -- the 48-slot section directory
; file 0x00000 .. 0x000FF   (256 bytes)
; --------------------------------------------------------------------------
; Every other region in this file is reached from here.  Each slot is a
; 4-byte little-endian FILE OFFSET (0-based; prom_d holds no absolute
; pointers), except that some slots in the KN5000's equivalent table are
; SCALARS -- see slot +0x88 below, which is the one prom_d slot whose
; reading is genuinely ambiguous.
; 
; The KN5000 has the same table, slot for slot, at its ToneDB_Base
; (ROM 0x830000) -- ../kn5000-roms-disasm/table_data/tone_database_directory.s.
; The 'KN5000:' note on each line is that file's label for the SAME slot.
; Cross-checks that hold: slot +0x08 is the tone-record offset table in
; both; +0x9C/+0xA0/+0xA4 alias +0x24/+0x28/+0x2C in both; +0x18==+0x1C
; and +0x30==+0x34 in both; the tail scalars +0xD0..+0xDA and +0xE8 have
; IDENTICAL values in both.
; 
; ⚠ The NAMES are still transplanted, not derived.  Where prom_d's content
; contradicts the KN5000 role the label follows the CONTENT and says so.
; 
; Evidence: ★ THIS TABLE IS READ BY prom_c, and that is new in wave 7 round 3.
; prom_d's base is 0x00F00000 on CPU 2's bus, held in RAM 0x00D7ED and
; 0x00D7F1; the ONLY two instructions in prom_c that write either address
; are 0xFB0523 and 0xFB0528, both storing the 0x00F00000 that 0xFB051E loads
; as an immediate, so the base is a compile-time constant everywhere.
; notes/prom_d_documentation_round3.py then finds 99 reads of this table --
; a load of that base immediately followed by a load from (base + slot) --
; covering 33 distinct slots, and RE-DECODES every one from prom_c's ROM
; bytes at the address it cites.  Which slots, and which sites, is printed
; on each region's own banner below.
; 
; ★ AND THE POINTER/SCALAR SPLIT IS prom_c's TOO.  Every read of a slot
; BELOW +0xC0 loads a 32-BIT register; every read of a slot AT OR ABOVE
; +0xC0 loads a 16-BIT one.  99 of 99, no exception.  Until round 3 the
; 'offsets here, scalars there' reading was borrowed from the KN5000's
; table; it is now this machine's own instruction encodings that say it.
; 
; The 0-BASED reading is prom_c's as well: at 0xFB429D it loads a tone
; record's entry out of the table at slot +0x08 and at 0xFB429F it ADDS THE
; BASE AGAIN.  A stored absolute address would not need that second add.
; 
; ★ CORRECTED 2026-09-25 (lane promcd).  This paragraph said 13 of the 39
; filled primary slots lacked any reader and that no field of any record
; had been read.  All 13 have one now: +0x0C/+0x10/+0x14 and +0x18/+0x1C/+0x20
; ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3), +0x24/+0x28/+0x2C and
; +0x30/+0x34/+0x38 ToneDB_ResolveEnvDescriptor (0xFB45C0), +0x48 at 0xFC0435
; and +0x5C at 0xFC05C3 (ToneQuery_ReplySourceName1/2_ViaIndexMap) -- each
; banner cites its own.  Fields read by the firmware are listed, with the
; instruction for each, in prom_d/wsa1_prom_d.s's wave-17 block; most other
; bytes still carry no name.
; ==========================================================================
ToneDB_Base:
ToneDB_Directory:
	.long 0xFFFFFFFF			; +0x00  unused
	.long 0x00000180			; +0x04  ToneDB_ToneNumBanks          10 x 128 LE16 tone numbers (program map)
					;        KN5000: ToneDB_BankMap_Main
	.long 0x00000B80			; +0x08  ToneDB_ToneOffsetTable       274 LE32 offsets -> tone records
					;        KN5000: ToneDB_ToneOffsetTable
	.long 0x0001C965			; +0x0C  ToneDB_ToneIndexMapA         1024 LE16 index map
					;        KN5000: ToneDB_ToneIndexMapA
	.long 0x0001D165			; +0x10  ToneDB_ToneIndexMapB         1024 LE16 index map
					;        KN5000: ToneDB_ToneIndexMapB
	.long 0x0002DF5C			; +0x14  ToneDB_PercSourceIndexMapA   1024 LE16 index map
					;        KN5000: ToneDB_PercSourceIndexMapA
	.long 0x0001D965			; +0x18  ToneDB_MixerDefaultTable     322 x 43-byte wave-select records
					;        KN5000: ToneDB_MixerDefaultTable
	.long 0x0001D965			; +0x1C  ToneDB_MixerDefaultTable     (alias of +0x18)
					;        KN5000: ToneDB_MixerDefaultTable
	.long 0x000416AC			; +0x20  ToneDB_PercMixerDefaultTable 208 x 43-byte wave-select records
					;        KN5000: ToneDB_PercMixerDefaultTable
	.long 0x00021A3B			; +0x24  ToneDB_ToneIndexMapC         1024 LE16 index map
					;        KN5000: ToneDB_ToneIndexMapC
	.long 0x0002223B			; +0x28  ToneDB_ToneIndexMapD         1024 LE16 index map + 768 unaccounted bytes
					;        KN5000: ToneDB_ToneIndexMapD
	.long 0x0002E75C			; +0x2C  ToneDB_DrumToneIndexMap      1024 LE16 index map
					;        KN5000: ToneDB_DrumToneIndexMap
	.long 0x00022D3B			; +0x30  ToneDB_EnvDescTable          descriptor block, stride word +0xEC = 14
					;        KN5000: ToneDB_EnvDescTable
	.long 0x00022D3B			; +0x34  ToneDB_EnvDescTable          (alias of +0x30)
					;        KN5000: ToneDB_EnvDescTable
	.long 0x0004399C			; +0x38  ToneDB_EnvDescTable_Perc     descriptor block, stride word +0xF2 = 14
					;        KN5000: ToneDB_EnvDescTable (shared)
	.long 0x00020F7B			; +0x3C  ToneDB_WaveSelTailPresets    64 x 43-byte wave-select records
					;        KN5000: UNUSED in the KN5000
	.long 0x00020F7B			; +0x40  ToneDB_WaveSelTailPresets    (alias of +0x3C)
					;        KN5000: UNUSED in the KN5000
	.long 0x0004809A			; +0x44  ToneDB_SourceIndexMapA       1024 LE16 index map
					;        KN5000: ToneDB_SourceIndexMapA
	.long 0x0004889A			; +0x48  ToneDB_SourceIndexMapB       1024 LE16 index map
					;        KN5000: ToneDB_SourceIndexMapB
	.long 0x0004F0DC			; +0x4C  ToneDB_PercSourceIndexMapB   1024 LE16 index map
					;        KN5000: ToneDB_PercSourceIndexMapB
	.long 0x00046D6A			; +0x50  ToneDB_SourceNameList1       307 x 16-byte named wave-catalogue rows
					;        KN5000: ToneDB_SourceNameList1
	.long 0x0004909A			; +0x54  ToneDB_SourceList1_Footer    count 307 + 15 bytes
					;        KN5000: ToneDB_SourceList1_Footer
	.long 0x0004A44C			; +0x58  ToneDB_SourceIndexMapC       1024 LE16 index map
					;        KN5000: ToneDB_SourceIndexMapC
	.long 0x0004AC4C			; +0x5C  ToneDB_SourceIndexMapD       1024 LE16 index map
					;        KN5000: ToneDB_SourceIndexMapD
	.long 0x000502FA			; +0x60  ToneDB_PercSourceIndexMapC   1024 LE16 index map
					;        KN5000: ToneDB_PercSourceIndexMapC
	.long 0x000490AC			; +0x64  ToneDB_SourceNameList2       314 x 16-byte named wave-catalogue rows
					;        KN5000: ToneDB_SourceNameList2
	.long 0x0004B44C			; +0x68  ToneDB_SourceList2_Footer    count 314 + 15 bytes
					;        KN5000: ToneDB_SourceList2_Footer
	.long 0x00000100			; +0x6C  ToneDB_BankMap               128-byte bank-select map
					;        KN5000: ToneDB_BankMap_Coeff
	.long 0x00044AEE			; +0x70  DrawbarPreset_EnvDescTable   descriptor block, framing NOT established
					;        KN5000: DrawbarPreset_EnvDescTable
	.long 0x0002CF5C			; +0x74  DrumKit_NoteMapA             2048 LE16 drum-instrument indices
					;        KN5000: DrumKit_NoteMapA
	.long 0x0002EF5C			; +0x78  PercInst_000_Silent          504 x 150-byte drum-instrument records
					;        KN5000: PercInst_000_Silent
	.long 0x0004D3CE			; +0x7C  DrumKit_NoteMapB             2048 LE16 drum-instrument indices
					;        KN5000: DrumKit_NoteMapB
	.long 0x0004B45E			; +0x80  ToneDB_DrumSourceNameList    503 x 16-byte named wave-catalogue rows
					;        KN5000: ToneDB_DrumSourceNameList
	.long 0x0004E3CE			; +0x84  ToneDB_DrumList_Footer       count 503 + 11 bytes
					;        KN5000: ToneDB_DrumList_Footer
	.long 0x00000125			; +0x88  (scalar or offset 0x125)     unresolved -- see the notes
					;        KN5000: 338, a SCALAR (DSP1 stream bias)
	.long 0x0004E3DC			; +0x8C  ToneDB_PercSourceNameList1   208 x 16-byte named wave-catalogue rows
					;        KN5000: ToneDB_PercSourceNameList1
	.long 0x0004F8DC			; +0x90  ToneDB_PercList1_Footer      count 208 + 11 bytes
					;        KN5000: ToneDB_PercList1_Footer
	.long 0x0004F8EA			; +0x94  ToneDB_PercSourceNameList2   161 x 16-byte named wave-catalogue rows
					;        KN5000: ToneDB_PercSourceNameList2
	.long 0x00050AFA			; +0x98  ToneDB_PercList2_Footer      count 161 + 11 bytes
					;        KN5000: ToneDB_PercList2_Footer
	.long 0x00021A3B			; +0x9C  ToneDB_ToneIndexMapC         (alias of +0x24, exactly as in the KN5000)
					;        KN5000: ToneDB_ToneIndexMapC alias
	.long 0x0002223B			; +0xA0  ToneDB_ToneIndexMapD         (alias of +0x28, exactly as in the KN5000)
					;        KN5000: ToneDB_ToneIndexMapD alias
	.long 0x0002E75C			; +0xA4  ToneDB_DrumToneIndexMap      (alias of +0x2C, exactly as in the KN5000)
					;        KN5000: ToneDB_DrumToneIndexMap alias
	.long 0x00000FC8			; +0xA8  ToneDB_OctaveShiftByProgram  8 banks x 128 programs, signed octave shift
					;        KN5000: UNUSED in the KN5000
	.long 0x0001C58A			; +0xAC  ToneDB_DefaultLayerParams    one 81-byte element block + one 43-byte wave-select record
					;        KN5000: ToneDB_DefaultLayerParams
	.long 0x0001C606			; +0xB0  ToneRec_Template_Clear       a 713-byte 4-element tone record named 'Clear'
					;        KN5000: PercName_Pack (DIFFERENT)
	.long 0x0001C8CF			; +0xB4  PercInst_Template_Silent     a 150-byte drum-instrument record named 'Silent'
					;        KN5000: UNUSED in the KN5000
	.long 0xFFFFFFFF			; +0xB8  unused
	.long 0xFFFFFFFF			; +0xBC  unused

; Directory tail -- scalars, read as 16-bit words.  The KN5000's reader
; takes +0xEA/+0xEC/+0xEE/+0xF0/+0xF2 as record STRIDES for the blocks
; behind the pointer slots; the values here differ from the KN5000's but
; three of them are confirmed by this image's own geometry (43, 150).
;
; Evidence: ★ prom_c reads SIX of these tail words, always into a 16-bit
; register, and it uses two of them AS STRIDES rather than as data:
;   +0xEC = 14  0xFC299A `ld BC,(XWA+0x00ec)` then 0xFC299F `mul XBC,HL`,
;               walking the 14-byte descriptor array at slot +0x70;
;   +0xEE = 150 0xFB493D `ld IY,(XIX+0x00ee)` then 0xFB495A `mul XIY,WA`,
;               scaling a drum-instrument index into the 150-byte records.
; The other four (+0xE0, +0xEA, +0xF0, +0xF2) are read at 22 sites in all
; and parked in a frame slot; what they are then multiplied BY is not
; traced, so they are NOT claimed as strides on the strength of the reads.
; Sites and byte-level decodes: notes/prom_d_documentation_round3.py Q3/Q4.
	.short 0     				; +0xC0  
	.short 0     				; +0xC2  
	.short 0     				; +0xC4  
	.short 0     				; +0xC6  
	.short 0     				; +0xC8  
	.short 0     				; +0xCA  
	.short 0     				; +0xCC  
	.short 0     				; +0xCE  
	.short 3     				; +0xD0  3, same in the KN5000
	.short 0     				; +0xD2  0
	.short 3     				; +0xD4  3, same in the KN5000
	.short 2     				; +0xD6  2, same
	.short 3     				; +0xD8  3, same in the KN5000
	.short 2     				; +0xDA  2, same
	.short 0     				; +0xDC  
	.short 0     				; +0xDE  
	.short 24    				; +0xE0  24 (KN5000: 28)
	.short 0     				; +0xE2  
	.short 0     				; +0xE4  
	.short 0     				; +0xE6  
	.short 426   				; +0xE8  426 -- IDENTICAL to the KN5000, where it is 21+5*81, its longest tone record
	.short 43    				; +0xEA  43 = the wave-select record stride, CONFIRMED (KN5000: 11)
	.short 14    				; +0xEC  14 = descriptor stride (KN5000: 15)
	.short 150   				; +0xEE  150 = the drum-instrument record stride, CONFIRMED (KN5000: 58)
	.short 43    				; +0xF0  43 = wave-select stride, percussion family (KN5000: 11)
	.short 14    				; +0xF2  14 = descriptor stride, percussion family (KN5000: 15)
	.short 0     				; +0xF4  
	.short 0     				; +0xF6  
	.short 0     				; +0xF8  
	.short 0     				; +0xFA  
	.short 0     				; +0xFC  
	.short 0     				; +0xFE  

; ==========================================================================
; ToneDB_BankMap -- directory slot +0x6C
; file 0x00100 .. 0x0017F   (128 bytes)
; --------------------------------------------------------------------------
; 128 bytes, indexed by a MIDI-style bank selector; the value is the row
; of ToneDB_ToneNumBanks (below) to use.  Only 10 selectors resolve:
; 0..7 -> rows 0..7 (the melodic rows), 0x20 -> row 8 and 0x27 -> row 9
; (the two drum rows).  Every other selector reads 0.
; 
; This is the KN5000's ToneDB_BankMap_Main / _Coeff structure and it sits
; exactly 0x80 below the tone-number banks there too.  ⚠ In the KN5000 it
; is directory slot +0x04 that names this table and +0x6C that names the
; second copy; in prom_d it is +0x6C that names THIS table and +0x04 that
; names the tone-number banks 0x80 above it.  There is only one copy here.
; 
; Evidence: prom_c reads directory slot +0x6C at 2 sites.  The first is
; 0xFA72FC `ld XBC,(0x00D7F1)` -- prom_d's base 0x00F00000 -- followed at
; 0xFA7301 by `ld XWA,(XBC+0x6C)`.  All 2: 0xFA7301, 0xFB424F.
; Every one re-decoded from prom_c's ROM bytes at the cited address by
; notes/prom_d_documentation_round3.py Q2 (99 reads over 33 slots, 0 that
; fail to decode).  The base is a compile-time constant: the only two
; instructions in prom_c that write 0x00D7ED / 0x00D7F1 are 0xFB0523 and
; 0xFB0528, both storing the 0x00F00000 loaded at 0xFB051E.
; ==========================================================================
ToneDB_BankMap:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00100  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00110  |................|
	.byte 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00120  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00130  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00140  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00150  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00160  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00170  |................|

; ==========================================================================
; ToneDB_ToneNumBanks -- directory slot +0x04
; file 0x00180 .. 0x00B7F   (2560 bytes)
; --------------------------------------------------------------------------
; 10 rows x 128 LE16.  Row r, program p gives the TONE INDEX into
; ToneDB_ToneOffsetTable.  Rows 0-7 only ever name melodic tones
; (index 0x000-0x0FF); rows 8-9 only ever name drum kits (0x100-0x111).
; Asserted over all 1280 entries by scripts/analysis/prom_d_tone_database.py.
; 
; ★ NEW IN ROUND 5 -- TWO OF THE TEN ROW LABELS NOW SAY WHAT THE ROW IS,
; and they say it from what the row SELECTS, since every record a row
; selects carries its own 16-byte ASCII name:
; 
;   ToneNumBank_DrumKits      row 8.  All 128 of its entries name a record
;                             whose own name ENDS IN 'Kit' -- 128 of 128,
;                             checked at program 127 as well as program 0.
;   ToneNumBank_SpecialSound  row 9.  127 of its entries hold tone 0x100
;                             'Jazz Kit'; the entry at program 127 holds
;                             tone 0x110 ' Special sound ', and row 9 is the
;                             ONLY row in all 1,280 entries in which 0x110
;                             occurs.  That one entry is the whole of what
;                             distinguishes this row, so it is what names it.
; 
; ⚠ AND ROWS 0-7 KEEP A NUMBER, deliberately.  What they share is measured
; (no entry >= 256 in any of the 1,024) and it is not enough to tell them
; apart; against row 0 they differ in 36/37/25/18/9/9/6 of 128 entries
; respectively, and NOTHING in this image says what that variation means.
; `Melodic_<r>` states the class and admits the gap; it is not a name.
; The row-name rule is derived, not typed: notes/prom_d_understanding_round5.py
; row_names(), and this generator refuses to emit if it stops producing the
; audited ten.  round 5 Q2.
; 
; The program ORDER is NOT General MIDI: program 1 of row 0 is
; 'Honky-Tonk Piano' where GM has Bright Acoustic Piano, and programs
; 32-39 are Harp/Banjo/Harp/Mandolin/Shamisen/Koto/Sitar/Kalimba where GM
; has the bass family.  It is a Technics-internal ordering; nothing here
; identifies which panel control it corresponds to.
; 
; Evidence: prom_c reads directory slot +0x04 at 1 site.  The first is
; 0xFB4266 `ld XWA,(0x00D7F1)` -- prom_d's base 0x00F00000 -- followed at
; 0xFB426B by `ld XIY,(XWA+0x04)`.  All 1: 0xFB426B.
; Every one re-decoded from prom_c's ROM bytes at the cited address by
; notes/prom_d_documentation_round3.py Q2 (99 reads over 33 slots, 0 that
; fail to decode).  The base is a compile-time constant: the only two
; instructions in prom_c that write 0x00D7ED / 0x00D7F1 are 0xFB0523 and
; 0xFB0528, both storing the 0x00F00000 loaded at 0xFB051E.
; 
; ★ AND THE 10 x 128 SHAPE IS prom_c's, not an inference from the span.
; The reader scales the index before it adds the table:
;     0xFB4271  sll 0x07,BC          row * 128
;     0xFB4274  add BC,DE            + program number
;     0xFB4276  add BC,BC            * 2, so the entry is an LE16
;     0xFB427C  add XIY,(0x00d7ed)   + the base  => the absolute entry
;     0xFB4281  ld HL,(XIY)          the tone index
; and the value it produces goes straight into ToneDB_ToneOffsetTable at
; 0xFB4283.  notes/prom_d_documentation_round3.py Q4a decodes all fifteen
; instructions of that chain from the ROM bytes.
; ==========================================================================
ToneDB_ToneNumBanks:

; --- row 0 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; This is the row the other seven are compared against; they
; differ from it in 36, 37, 25, 18, 9, 9, 6 of their 128 entries
; respectively, so the eight rows are not copies of one another.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 0 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_0:
	.short 0x0000	; 00180  [  0] prog   0 -> tone 0x000 '     Piano      '
	.short 0x0003	; 00182  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00184  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00186  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000D	; 00188  [  4] prog   4 -> tone 0x00D '  Modern E.P.2  '
	.short 0x0008	; 0018A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000C	; 0018C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0026	; 0018E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00190  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00192  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00194  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x0016	; 00196  [ 11] prog  11 -> tone 0x016 '   Xylophone    '
	.short 0x0017	; 00198  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0019A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x001A	; 0019C  [ 14] prog  14 -> tone 0x01A ' Tubular Bells  '
	.short 0x0018	; 0019E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 001A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 001A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 001A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 001A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 001A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x002A	; 001AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 001AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 001AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 001B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 001B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x0032	; 001B4  [ 26] prog  26 -> tone 0x032 'Bright Solid Gtr'
	.short 0x003B	; 001B6  [ 27] prog  27 -> tone 0x03B ' Rock Harmonics '
	.short 0x0033	; 001B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0036	; 001BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0038	; 001BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003F	; 001BE  [ 31] prog  31 -> tone 0x03F 'Hawaiian Guitar2'
	.short 0x0022	; 001C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 001C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 001C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 001C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 001C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 001CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 001CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00BA	; 001CE  [ 39] prog  39 -> tone 0x0BA '    Kalimba     '
	.short 0x006A	; 001D0  [ 40] prog  40 -> tone 0x06A ' Electric Bass  '
	.short 0x0072	; 001D2  [ 41] prog  41 -> tone 0x072 '  Slap Bass 1   '
	.short 0x0070	; 001D4  [ 42] prog  42 -> tone 0x070 ' Picked E.Bass  '
	.short 0x0068	; 001D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 001D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 001DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x0078	; 001DC  [ 46] prog  46 -> tone 0x078 '   Wow Bass 1   '
	.short 0x0071	; 001DE  [ 47] prog  47 -> tone 0x071 '   Mute Bass    '
	.short 0x0088	; 001E0  [ 48] prog  48 -> tone 0x088 '   Trumpet 1    '
	.short 0x008F	; 001E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 001E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 001E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 001E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 001EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0093	; 001EC  [ 54] prog  54 -> tone 0x093 ' Closed Fr.Horn '
	.short 0x0096	; 001EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0080	; 001F0  [ 56] prog  56 -> tone 0x080 '     Brass      '
	.short 0x0080	; 001F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 001F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 001F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x0084	; 001F8  [ 60] prog  60 -> tone 0x084 ' Synth Brass 1  '
	.short 0x00CF	; 001FA  [ 61] prog  61 -> tone 0x0CF '  Sleigh Synth  '
	.short 0x00E4	; 001FC  [ 62] prog  62 -> tone 0x0E4 '   Sweep Pad    '
	.short 0x0085	; 001FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00A8	; 00200  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00202  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00204  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00206  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00208  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0020A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0020C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0020E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AD	; 00210  [ 72] prog  72 -> tone 0x0AD '   Pan Flute    '
	.short 0x00B7	; 00212  [ 73] prog  73 -> tone 0x0B7 '    Bagpipe     '
	.short 0x00AF	; 00214  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00B3	; 00216  [ 75] prog  75 -> tone 0x0B3 '   Shakuhachi   '
	.short 0x0098	; 00218  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0021A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009C	; 0021C  [ 78] prog  78 -> tone 0x09C ' Breathy Tenor  '
	.short 0x009D	; 0021E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00220  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00222  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00224  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00226  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00228  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0022A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0022C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0022E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00230  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00232  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00234  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00236  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00238  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x005C	; 0023A  [ 93] prog  93 -> tone 0x05C ' Jazz Drawbars  '
	.short 0x00C2	; 0023C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0023E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004A	; 00240  [ 96] prog  96 -> tone 0x04A '     Violin     '
	.short 0x004E	; 00242  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x004F	; 00244  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00246  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0041	; 00248  [100] prog 100 -> tone 0x041 'ClassicalStrings'
	.short 0x0043	; 0024A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0024C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0048	; 0024E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0051	; 00250  [104] prog 104 -> tone 0x051 '  Pop Vocal Ah  '
	.short 0x0054	; 00252  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00EE	; 00254  [106] prog 106 -> tone 0x0EE '    Goblins     '
	.short 0x00DA	; 00256  [107] prog 107 -> tone 0x0DA '  Synth Vocal   '
	.short 0x00E2	; 00258  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0055	; 0025A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0025C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0025E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00260  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00262  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00264  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00266  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x000F	; 00268  [116] prog 116 -> tone 0x00F '   Bell Piano   '
	.short 0x00C0	; 0026A  [117] prog 117 -> tone 0x0C0 '  Square Lead   '
	.short 0x00C1	; 0026C  [118] prog 118 -> tone 0x0C1 '    Saw Lead    '
	.short 0x00CD	; 0026E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00270  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00EC	; 00272  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F0	; 00274  [122] prog 122 -> tone 0x0F0 '     Agogo      '
	.short 0x00FC	; 00276  [123] prog 123 -> tone 0x0FC '   Telephone    '
	.short 0x00F4	; 00278  [124] prog 124 -> tone 0x0F4 '   Synth Drum   '
	.short 0x00FB	; 0027A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0027C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0027E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 1 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 36 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 1 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_1:
	.short 0x0000	; 00280  [  0] prog   0 -> tone 0x000 '     Piano      '
	.short 0x0003	; 00282  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00284  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00286  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000D	; 00288  [  4] prog   4 -> tone 0x00D '  Modern E.P.2  '
	.short 0x0008	; 0028A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000C	; 0028C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0026	; 0028E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00290  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00292  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00294  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x001E	; 00296  [ 11] prog  11 -> tone 0x01E 'Caribbean Mallet'
	.short 0x0017	; 00298  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0029A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x001A	; 0029C  [ 14] prog  14 -> tone 0x01A ' Tubular Bells  '
	.short 0x0019	; 0029E  [ 15] prog  15 -> tone 0x019 'Power Steel Drum'
	.short 0x0010	; 002A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 002A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 002A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 002A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0029	; 002A8  [ 20] prog  20 -> tone 0x029 ' Spanish Guitar '
	.short 0x002A	; 002AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 002AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 002AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 002B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 002B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x0034	; 002B4  [ 26] prog  26 -> tone 0x034 'Clean Solid Gtr '
	.short 0x003B	; 002B6  [ 27] prog  27 -> tone 0x03B ' Rock Harmonics '
	.short 0x0033	; 002B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0036	; 002BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0038	; 002BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003D	; 002BE  [ 31] prog  31 -> tone 0x03D ' Country Guitar '
	.short 0x0022	; 002C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 002C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 002C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 002C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 002C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 002CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BF	; 002CC  [ 38] prog  38 -> tone 0x0BF '    Dulcimer    '
	.short 0x00BB	; 002CE  [ 39] prog  39 -> tone 0x0BB ' Metal Kalimba  '
	.short 0x006B	; 002D0  [ 40] prog  40 -> tone 0x06B ' Bright E.Bass  '
	.short 0x0073	; 002D2  [ 41] prog  41 -> tone 0x073 '  Slap Bass 2   '
	.short 0x0076	; 002D4  [ 42] prog  42 -> tone 0x076 '   Soul Bass    '
	.short 0x0069	; 002D6  [ 43] prog  43 -> tone 0x069 ' Mellow Ac.Bass '
	.short 0x0077	; 002D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 002DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x0075	; 002DC  [ 46] prog  46 -> tone 0x075 '  Analog Bass   '
	.short 0x0071	; 002DE  [ 47] prog  47 -> tone 0x071 '   Mute Bass    '
	.short 0x008A	; 002E0  [ 48] prog  48 -> tone 0x08A ' Mellow Trumpet '
	.short 0x008F	; 002E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008D	; 002E4  [ 50] prog  50 -> tone 0x08D 'Straight MuteTpt'
	.short 0x008E	; 002E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 002E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 002EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0094	; 002EC  [ 54] prog  54 -> tone 0x094 '  Open Fr.Horn  '
	.short 0x0097	; 002EE  [ 55] prog  55 -> tone 0x097 ' Marching Tuba  '
	.short 0x0082	; 002F0  [ 56] prog  56 -> tone 0x082 '  Octave Brass  '
	.short 0x0080	; 002F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 002F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 002F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x0084	; 002F8  [ 60] prog  60 -> tone 0x084 ' Synth Brass 1  '
	.short 0x00CF	; 002FA  [ 61] prog  61 -> tone 0x0CF '  Sleigh Synth  '
	.short 0x00E4	; 002FC  [ 62] prog  62 -> tone 0x0E4 '   Sweep Pad    '
	.short 0x0085	; 002FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00AB	; 00300  [ 64] prog  64 -> tone 0x0AB '   Alto Flute   '
	.short 0x00AA	; 00302  [ 65] prog  65 -> tone 0x0AA 'Classical Flute '
	.short 0x00A3	; 00304  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00306  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00308  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0030A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0030C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0030E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AD	; 00310  [ 72] prog  72 -> tone 0x0AD '   Pan Flute    '
	.short 0x00B6	; 00312  [ 73] prog  73 -> tone 0x0B6 '     Shanai     '
	.short 0x00B0	; 00314  [ 74] prog  74 -> tone 0x0B0 '    Ocarina     '
	.short 0x00B4	; 00316  [ 75] prog  75 -> tone 0x0B4 '     Quena      '
	.short 0x0098	; 00318  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x009A	; 0031A  [ 77] prog  77 -> tone 0x09A 'Mellow Alto Sax '
	.short 0x009C	; 0031C  [ 78] prog  78 -> tone 0x09C ' Breathy Tenor  '
	.short 0x009E	; 0031E  [ 79] prog  79 -> tone 0x09E '  Baritone Sax  '
	.short 0x0067	; 00320  [ 80] prog  80 -> tone 0x067 '   Bandoneon    '
	.short 0x0065	; 00322  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00324  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A7	; 00326  [ 83] prog  83 -> tone 0x0A7 'Blues Harmonica '
	.short 0x0060	; 00328  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0032A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0032C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0032E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00330  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00332  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00334  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00336  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00338  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x005C	; 0033A  [ 93] prog  93 -> tone 0x05C ' Jazz Drawbars  '
	.short 0x00C2	; 0033C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0033E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004B	; 00340  [ 96] prog  96 -> tone 0x04B '  Jazz Violin   '
	.short 0x004E	; 00342  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x0045	; 00344  [ 98] prog  98 -> tone 0x045 '  Bass Strings  '
	.short 0x0047	; 00346  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0041	; 00348  [100] prog 100 -> tone 0x041 'ClassicalStrings'
	.short 0x0043	; 0034A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0034C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0049	; 0034E  [103] prog 103 -> tone 0x049 'Synth Strings 2 '
	.short 0x0051	; 00350  [104] prog 104 -> tone 0x051 '  Pop Vocal Ah  '
	.short 0x0054	; 00352  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00C3	; 00354  [106] prog 106 -> tone 0x0C3 '    Air Vox     '
	.short 0x00D8	; 00356  [107] prog 107 -> tone 0x0D8 'Mellow Ensemble '
	.short 0x00E2	; 00358  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0055	; 0035A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0035C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0035E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00360  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00362  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00364  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00366  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x000F	; 00368  [116] prog 116 -> tone 0x00F '   Bell Piano   '
	.short 0x00C0	; 0036A  [117] prog 117 -> tone 0x0C0 '  Square Lead   '
	.short 0x00C1	; 0036C  [118] prog 118 -> tone 0x0C1 '    Saw Lead    '
	.short 0x00ED	; 0036E  [119] prog 119 -> tone 0x0ED '   Soundtrack   '
	.short 0x00DD	; 00370  [120] prog 120 -> tone 0x0DD '   Star Theme   '
	.short 0x00EC	; 00372  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F1	; 00374  [122] prog 122 -> tone 0x0F1 '   Wood Block   '
	.short 0x00FD	; 00376  [123] prog 123 -> tone 0x0FD '   Helicopter   '
	.short 0x00F8	; 00378  [124] prog 124 -> tone 0x0F8 '   Fret Noise   '
	.short 0x00FB	; 0037A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0037C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0037E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 2 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 37 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 2 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_2:
	.short 0x0005	; 00380  [  0] prog   0 -> tone 0x005 '  Midi Grand 1  '
	.short 0x0003	; 00382  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00384  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0002	; 00386  [  3] prog   3 -> tone 0x002 '   Rock Piano   '
	.short 0x000A	; 00388  [  4] prog   4 -> tone 0x00A ' Suitcase E.P.  '
	.short 0x0009	; 0038A  [  5] prog   5 -> tone 0x009 '   E.Piano 2    '
	.short 0x000C	; 0038C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0027	; 0038E  [  7] prog   7 -> tone 0x027 'Christmas Piano '
	.short 0x0014	; 00390  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x001F	; 00392  [  9] prog   9 -> tone 0x01F ' Synth Glocken  '
	.short 0x0015	; 00394  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x0016	; 00396  [ 11] prog  11 -> tone 0x016 '   Xylophone    '
	.short 0x0017	; 00398  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0039A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x001B	; 0039C  [ 14] prog  14 -> tone 0x01B '  Tinkle Bell   '
	.short 0x0018	; 0039E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 003A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 003A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 003A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 003A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 003A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x002A	; 003AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 003AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 003AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 003B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x002E	; 003B2  [ 25] prog  25 -> tone 0x02E 'ElectroAc.Guitar'
	.short 0x003C	; 003B4  [ 26] prog  26 -> tone 0x03C 'Synth Solid Gtr '
	.short 0x003A	; 003B6  [ 27] prog  27 -> tone 0x03A 'Overdrive Guitar'
	.short 0x0035	; 003B8  [ 28] prog  28 -> tone 0x035 'Fusion Solid Gtr'
	.short 0x0036	; 003BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0038	; 003BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003F	; 003BE  [ 31] prog  31 -> tone 0x03F 'Hawaiian Guitar2'
	.short 0x0022	; 003C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 003C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 003C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 003C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 003C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 003CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 003CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00BA	; 003CE  [ 39] prog  39 -> tone 0x0BA '    Kalimba     '
	.short 0x006E	; 003D0  [ 40] prog  40 -> tone 0x06E 'Fretless Bass 1 '
	.short 0x0074	; 003D2  [ 41] prog  41 -> tone 0x074 '  Slap Bass 3   '
	.short 0x0070	; 003D4  [ 42] prog  42 -> tone 0x070 ' Picked E.Bass  '
	.short 0x0068	; 003D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 003D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 003DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x00CE	; 003DC  [ 46] prog  46 -> tone 0x0CE '  Bass & Lead   '
	.short 0x007C	; 003DE  [ 47] prog  47 -> tone 0x07C '   House Bass   '
	.short 0x008B	; 003E0  [ 48] prog  48 -> tone 0x08B 'Orchest.Trumpet '
	.short 0x008F	; 003E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 003E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 003E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 003E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 003EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0093	; 003EC  [ 54] prog  54 -> tone 0x093 ' Closed Fr.Horn '
	.short 0x0096	; 003EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0083	; 003F0  [ 56] prog  56 -> tone 0x083 'Mute Brass Ens. '
	.short 0x0080	; 003F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 003F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 003F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x0084	; 003F8  [ 60] prog  60 -> tone 0x084 ' Synth Brass 1  '
	.short 0x00CF	; 003FA  [ 61] prog  61 -> tone 0x0CF '  Sleigh Synth  '
	.short 0x00E4	; 003FC  [ 62] prog  62 -> tone 0x0E4 '   Sweep Pad    '
	.short 0x0085	; 003FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00A8	; 00400  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00402  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00404  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00406  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A1	; 00408  [ 68] prog  68 -> tone 0x0A1 'Jazz Clarinet 2 '
	.short 0x00A2	; 0040A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0040C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0040E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00B1	; 00410  [ 72] prog  72 -> tone 0x0B1 '  Blown Bottle  '
	.short 0x00B5	; 00412  [ 73] prog  73 -> tone 0x0B5 '      Ney       '
	.short 0x00AF	; 00414  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00B3	; 00416  [ 75] prog  75 -> tone 0x0B3 '   Shakuhachi   '
	.short 0x0098	; 00418  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0041A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009F	; 0041C  [ 78] prog  78 -> tone 0x09F ' Distortion Sax '
	.short 0x009D	; 0041E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00420  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00422  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00424  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00426  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00428  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0042A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0042C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0042E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00430  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005E	; 00432  [ 89] prog  89 -> tone 0x05E '   Pop Organ    '
	.short 0x005E	; 00434  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00436  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00438  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x005C	; 0043A  [ 93] prog  93 -> tone 0x05C ' Jazz Drawbars  '
	.short 0x00C2	; 0043C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0043E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004C	; 00440  [ 96] prog  96 -> tone 0x04C '     Fiddle     '
	.short 0x004D	; 00442  [ 97] prog  97 -> tone 0x04D '     Viola      '
	.short 0x004F	; 00444  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00446  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0046	; 00448  [100] prog 100 -> tone 0x046 'Tremolo Strings '
	.short 0x0043	; 0044A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x00E8	; 0044C  [102] prog 102 -> tone 0x0E8 '   Poly Synth   '
	.short 0x0048	; 0044E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0053	; 00450  [104] prog 104 -> tone 0x053 '   Vocal Ooh    '
	.short 0x0054	; 00452  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00DC	; 00454  [106] prog 106 -> tone 0x0DC '   Metal Pad    '
	.short 0x00DB	; 00456  [107] prog 107 -> tone 0x0DB '   Spacy Pad    '
	.short 0x00E2	; 00458  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0056	; 0045A  [109] prog 109 -> tone 0x056 '   Vocal Daa    '
	.short 0x0057	; 0045C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0045E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00460  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00462  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00464  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00466  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x00E1	; 00468  [116] prog 116 -> tone 0x0E1 '    Bell Pad    '
	.short 0x00C4	; 0046A  [117] prog 117 -> tone 0x0C4 '  Chiffer Lead  '
	.short 0x00CC	; 0046C  [118] prog 118 -> tone 0x0CC '   Voco Synth   '
	.short 0x00CD	; 0046E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00470  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00EC	; 00472  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F3	; 00474  [122] prog 122 -> tone 0x0F3 '  Melodic Tom   '
	.short 0x00FF	; 00476  [123] prog 123 -> tone 0x0FF '    Gun Shot    '
	.short 0x00F9	; 00478  [124] prog 124 -> tone 0x0F9 '  Breath Noise  '
	.short 0x00FB	; 0047A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0047C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0024	; 0047E  [127] prog 127 -> tone 0x024 'Orchestra Hit 2 '

; --- row 3 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 25 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 3 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_3:
	.short 0x0000	; 00480  [  0] prog   0 -> tone 0x000 '     Piano      '
	.short 0x0007	; 00482  [  1] prog   1 -> tone 0x007 '  Jangle Piano  '
	.short 0x0001	; 00484  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00486  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000D	; 00488  [  4] prog   4 -> tone 0x00D '  Modern E.P.2  '
	.short 0x0008	; 0048A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000E	; 0048C  [  6] prog   6 -> tone 0x00E '  Modern E.P.3  '
	.short 0x0026	; 0048E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00490  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00492  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00494  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x0016	; 00496  [ 11] prog  11 -> tone 0x016 '   Xylophone    '
	.short 0x0017	; 00498  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0049A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x00BD	; 0049C  [ 14] prog  14 -> tone 0x0BD '   Gamelan 1    '
	.short 0x0018	; 0049E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 004A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 004A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 004A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 004A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 004A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x00DF	; 004AA  [ 21] prog  21 -> tone 0x0DF '   Atmosphere   '
	.short 0x002C	; 004AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 004AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 004B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 004B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x0032	; 004B4  [ 26] prog  26 -> tone 0x032 'Bright Solid Gtr'
	.short 0x00C5	; 004B6  [ 27] prog  27 -> tone 0x0C5 '    Charang     '
	.short 0x0033	; 004B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0037	; 004BA  [ 29] prog  29 -> tone 0x037 'Funk Mute Guitar'
	.short 0x0038	; 004BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003E	; 004BE  [ 31] prog  31 -> tone 0x03E 'Hawaiian Guitar1'
	.short 0x0022	; 004C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 004C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 004C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 004C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 004C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 004CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 004CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00BA	; 004CE  [ 39] prog  39 -> tone 0x0BA '    Kalimba     '
	.short 0x006D	; 004D0  [ 40] prog  40 -> tone 0x06D '  Funky E.Bass  '
	.short 0x0072	; 004D2  [ 41] prog  41 -> tone 0x072 '  Slap Bass 1   '
	.short 0x007D	; 004D4  [ 42] prog  42 -> tone 0x07D ' Metallic Bass  '
	.short 0x0068	; 004D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 004D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 004DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x0078	; 004DC  [ 46] prog  46 -> tone 0x078 '   Wow Bass 1   '
	.short 0x007B	; 004DE  [ 47] prog  47 -> tone 0x07B '   Dance Bass   '
	.short 0x0088	; 004E0  [ 48] prog  48 -> tone 0x088 '   Trumpet 1    '
	.short 0x008F	; 004E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 004E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 004E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0092	; 004E8  [ 52] prog  52 -> tone 0x092 'CupMuteTrombone '
	.short 0x0091	; 004EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0093	; 004EC  [ 54] prog  54 -> tone 0x093 ' Closed Fr.Horn '
	.short 0x0096	; 004EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0081	; 004F0  [ 56] prog  56 -> tone 0x081 ' Brass & Synth  '
	.short 0x0080	; 004F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 004F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 004F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x0084	; 004F8  [ 60] prog  60 -> tone 0x084 ' Synth Brass 1  '
	.short 0x00CF	; 004FA  [ 61] prog  61 -> tone 0x0CF '  Sleigh Synth  '
	.short 0x00E4	; 004FC  [ 62] prog  62 -> tone 0x0E4 '   Sweep Pad    '
	.short 0x0085	; 004FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00A8	; 00500  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00502  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00504  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00506  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00508  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0050A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0050C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0050E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AE	; 00510  [ 72] prog  72 -> tone 0x0AE ' Synth Calliope '
	.short 0x00B7	; 00512  [ 73] prog  73 -> tone 0x0B7 '    Bagpipe     '
	.short 0x00AF	; 00514  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00B3	; 00516  [ 75] prog  75 -> tone 0x0B3 '   Shakuhachi   '
	.short 0x0098	; 00518  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0051A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009B	; 0051C  [ 78] prog  78 -> tone 0x09B '   Tenor Sax    '
	.short 0x009D	; 0051E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00520  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00522  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00524  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00526  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00528  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0052A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0052C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0052E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00530  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00532  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00534  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00536  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00538  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x005C	; 0053A  [ 93] prog  93 -> tone 0x05C ' Jazz Drawbars  '
	.short 0x00C2	; 0053C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0053E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004A	; 00540  [ 96] prog  96 -> tone 0x04A '     Violin     '
	.short 0x004E	; 00542  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x004F	; 00544  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00546  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0040	; 00548  [100] prog 100 -> tone 0x040 'SymphonicStrings'
	.short 0x0043	; 0054A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0054C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0048	; 0054E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0050	; 00550  [104] prog 104 -> tone 0x050 '    Vocal Ah    '
	.short 0x0054	; 00552  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00E6	; 00554  [106] prog 106 -> tone 0x0E6 '   Echo Drops   '
	.short 0x00E5	; 00556  [107] prog 107 -> tone 0x0E5 '    Halo Pad    '
	.short 0x00E3	; 00558  [108] prog 108 -> tone 0x0E3 '      Mist      '
	.short 0x0055	; 0055A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0055C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0055E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00560  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00562  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00564  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00566  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x00E0	; 00568  [116] prog 116 -> tone 0x0E0 '    Fantasia    '
	.short 0x00C0	; 0056A  [117] prog 117 -> tone 0x0C0 '  Square Lead   '
	.short 0x00D6	; 0056C  [118] prog 118 -> tone 0x0D6 '   Funky Lead   '
	.short 0x00CD	; 0056E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00570  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00EC	; 00572  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F5	; 00574  [122] prog 122 -> tone 0x0F5 ' Reverse Cymbal '
	.short 0x00F2	; 00576  [123] prog 123 -> tone 0x0F2 '   Taiko Drum   '
	.short 0x00FA	; 00578  [124] prog 124 -> tone 0x0FA '    Seashore    '
	.short 0x00FE	; 0057A  [125] prog 125 -> tone 0x0FE '    Applause    '
	.short 0x0025	; 0057C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0057E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 4 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 18 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 4 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_4:
	.short 0x0006	; 00580  [  0] prog   0 -> tone 0x006 '  Midi Grand 2  '
	.short 0x0003	; 00582  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00584  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00586  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000B	; 00588  [  4] prog   4 -> tone 0x00B 'Tremolo E.Piano '
	.short 0x0008	; 0058A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000C	; 0058C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0026	; 0058E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00590  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00592  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00594  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x0016	; 00596  [ 11] prog  11 -> tone 0x016 '   Xylophone    '
	.short 0x0017	; 00598  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0059A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x001A	; 0059C  [ 14] prog  14 -> tone 0x01A ' Tubular Bells  '
	.short 0x0018	; 0059E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 005A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 005A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 005A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 005A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 005A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x002A	; 005AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 005AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 005AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 005B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 005B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x0032	; 005B4  [ 26] prog  26 -> tone 0x032 'Bright Solid Gtr'
	.short 0x002B	; 005B6  [ 27] prog  27 -> tone 0x02B 'Guitar Harmonics'
	.short 0x0033	; 005B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0036	; 005BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0039	; 005BC  [ 30] prog  30 -> tone 0x039 'Distortion Gtr 2'
	.short 0x003F	; 005BE  [ 31] prog  31 -> tone 0x03F 'Hawaiian Guitar2'
	.short 0x00D1	; 005C0  [ 32] prog  32 -> tone 0x0D1 '   Synth Harp   '
	.short 0x0020	; 005C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 005C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 005C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 005C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 005CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 005CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00F7	; 005CE  [ 39] prog  39 -> tone 0x0F7 '    Berimbau    '
	.short 0x006C	; 005D0  [ 40] prog  40 -> tone 0x06C ' Fusion E.Bass  '
	.short 0x0072	; 005D2  [ 41] prog  41 -> tone 0x072 '  Slap Bass 1   '
	.short 0x0070	; 005D4  [ 42] prog  42 -> tone 0x070 ' Picked E.Bass  '
	.short 0x0068	; 005D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 005D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 005DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x0079	; 005DC  [ 46] prog  46 -> tone 0x079 '   Wow Bass 2   '
	.short 0x0071	; 005DE  [ 47] prog  47 -> tone 0x071 '   Mute Bass    '
	.short 0x0089	; 005E0  [ 48] prog  48 -> tone 0x089 '   Trumpet 2    '
	.short 0x008F	; 005E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 005E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 005E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 005E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 005EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0095	; 005EC  [ 54] prog  54 -> tone 0x095 '  Fr.Horn Ens.  '
	.short 0x0096	; 005EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0080	; 005F0  [ 56] prog  56 -> tone 0x080 '     Brass      '
	.short 0x0080	; 005F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 005F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 005F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x00CB	; 005F8  [ 60] prog  60 -> tone 0x0CB '  Olymp Synth   '
	.short 0x00CF	; 005FA  [ 61] prog  61 -> tone 0x0CF '  Sleigh Synth  '
	.short 0x0086	; 005FC  [ 62] prog  62 -> tone 0x086 ' Synth Brass 3  '
	.short 0x0087	; 005FE  [ 63] prog  63 -> tone 0x087 ' Synth Brass 4  '
	.short 0x00A8	; 00600  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00602  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00604  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00606  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00608  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0060A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0060C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0060E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AD	; 00610  [ 72] prog  72 -> tone 0x0AD '   Pan Flute    '
	.short 0x00B7	; 00612  [ 73] prog  73 -> tone 0x0B7 '    Bagpipe     '
	.short 0x00AF	; 00614  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00B3	; 00616  [ 75] prog  75 -> tone 0x0B3 '   Shakuhachi   '
	.short 0x0098	; 00618  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0061A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009C	; 0061C  [ 78] prog  78 -> tone 0x09C ' Breathy Tenor  '
	.short 0x009D	; 0061E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00620  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00622  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00624  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00626  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00628  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0062A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0062C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0062E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00630  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00632  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00634  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00636  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00638  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x005C	; 0063A  [ 93] prog  93 -> tone 0x05C ' Jazz Drawbars  '
	.short 0x00C2	; 0063C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0063E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004A	; 00640  [ 96] prog  96 -> tone 0x04A '     Violin     '
	.short 0x004E	; 00642  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x004F	; 00644  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00646  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0042	; 00648  [100] prog 100 -> tone 0x042 'Marcato Strings '
	.short 0x0043	; 0064A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0064C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0048	; 0064E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0052	; 00650  [104] prog 104 -> tone 0x052 'Stereo Vocal Ah '
	.short 0x0054	; 00652  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00EB	; 00654  [106] prog 106 -> tone 0x0EB ' Dark Universe  '
	.short 0x00DA	; 00656  [107] prog 107 -> tone 0x0DA '  Synth Vocal   '
	.short 0x00E2	; 00658  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0055	; 0065A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0065C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0065E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00660  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00662  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00664  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00666  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x000F	; 00668  [116] prog 116 -> tone 0x00F '   Bell Piano   '
	.short 0x00C0	; 0066A  [117] prog 117 -> tone 0x0C0 '  Square Lead   '
	.short 0x00D7	; 0066C  [118] prog 118 -> tone 0x0D7 '     Sweppy     '
	.short 0x00CD	; 0066E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00670  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00EC	; 00672  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F0	; 00674  [122] prog 122 -> tone 0x0F0 '     Agogo      '
	.short 0x00F6	; 00676  [123] prog 123 -> tone 0x0F6 '  Talking Drum  '
	.short 0x00F4	; 00678  [124] prog 124 -> tone 0x0F4 '   Synth Drum   '
	.short 0x00FB	; 0067A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0067C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0067E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 5 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 9 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 5 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_5:
	.short 0x0000	; 00680  [  0] prog   0 -> tone 0x000 '     Piano      '
	.short 0x0003	; 00682  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00684  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00686  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000D	; 00688  [  4] prog   4 -> tone 0x00D '  Modern E.P.2  '
	.short 0x0008	; 0068A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000C	; 0068C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0026	; 0068E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00690  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00692  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00694  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x00D2	; 00696  [ 11] prog  11 -> tone 0x0D2 '   Afro Dance   '
	.short 0x0017	; 00698  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0069A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x001A	; 0069C  [ 14] prog  14 -> tone 0x01A ' Tubular Bells  '
	.short 0x0018	; 0069E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 006A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 006A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 006A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 006A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 006A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x002A	; 006AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 006AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 006AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 006B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 006B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x0032	; 006B4  [ 26] prog  26 -> tone 0x032 'Bright Solid Gtr'
	.short 0x003B	; 006B6  [ 27] prog  27 -> tone 0x03B ' Rock Harmonics '
	.short 0x0033	; 006B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0036	; 006BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0038	; 006BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003F	; 006BE  [ 31] prog  31 -> tone 0x03F 'Hawaiian Guitar2'
	.short 0x0022	; 006C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 006C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 006C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 006C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 006C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 006CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 006CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00BA	; 006CE  [ 39] prog  39 -> tone 0x0BA '    Kalimba     '
	.short 0x006A	; 006D0  [ 40] prog  40 -> tone 0x06A ' Electric Bass  '
	.short 0x0072	; 006D2  [ 41] prog  41 -> tone 0x072 '  Slap Bass 1   '
	.short 0x0070	; 006D4  [ 42] prog  42 -> tone 0x070 ' Picked E.Bass  '
	.short 0x0068	; 006D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 006D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 006DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x007E	; 006DC  [ 46] prog  46 -> tone 0x07E '  Plastic Bass  '
	.short 0x0071	; 006DE  [ 47] prog  47 -> tone 0x071 '   Mute Bass    '
	.short 0x0088	; 006E0  [ 48] prog  48 -> tone 0x088 '   Trumpet 1    '
	.short 0x008F	; 006E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 006E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 006E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 006E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 006EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0093	; 006EC  [ 54] prog  54 -> tone 0x093 ' Closed Fr.Horn '
	.short 0x0096	; 006EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0080	; 006F0  [ 56] prog  56 -> tone 0x080 '     Brass      '
	.short 0x0080	; 006F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 006F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 006F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x00D0	; 006F8  [ 60] prog  60 -> tone 0x0D0 ' Talking Synth  '
	.short 0x00CF	; 006FA  [ 61] prog  61 -> tone 0x0CF '  Sleigh Synth  '
	.short 0x00D9	; 006FC  [ 62] prog  62 -> tone 0x0D9 ' Warm Synth Pad '
	.short 0x0085	; 006FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00A8	; 00700  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00702  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00704  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00706  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00708  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0070A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0070C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0070E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AD	; 00710  [ 72] prog  72 -> tone 0x0AD '   Pan Flute    '
	.short 0x00B7	; 00712  [ 73] prog  73 -> tone 0x0B7 '    Bagpipe     '
	.short 0x00AF	; 00714  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00AC	; 00716  [ 75] prog  75 -> tone 0x0AC ' Flatter Flute  '
	.short 0x0098	; 00718  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0071A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009C	; 0071C  [ 78] prog  78 -> tone 0x09C ' Breathy Tenor  '
	.short 0x009D	; 0071E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00720  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00722  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00724  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00726  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00728  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0072A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0072C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0072E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00730  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00732  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00734  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00736  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00738  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x005C	; 0073A  [ 93] prog  93 -> tone 0x05C ' Jazz Drawbars  '
	.short 0x00C2	; 0073C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0073E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004A	; 00740  [ 96] prog  96 -> tone 0x04A '     Violin     '
	.short 0x004E	; 00742  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x004F	; 00744  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00746  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0041	; 00748  [100] prog 100 -> tone 0x041 'ClassicalStrings'
	.short 0x0043	; 0074A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0074C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0048	; 0074E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0051	; 00750  [104] prog 104 -> tone 0x051 '  Pop Vocal Ah  '
	.short 0x0054	; 00752  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00CA	; 00754  [106] prog 106 -> tone 0x0CA '  Steamy Keys   '
	.short 0x00E7	; 00756  [107] prog 107 -> tone 0x0E7 ' Happy Ensemble '
	.short 0x00E2	; 00758  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0055	; 0075A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0075C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0075E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00760  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00762  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00764  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00766  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x000F	; 00768  [116] prog 116 -> tone 0x00F '   Bell Piano   '
	.short 0x00C7	; 0076A  [117] prog 117 -> tone 0x0C7 '  Talking Lead  '
	.short 0x00C1	; 0076C  [118] prog 118 -> tone 0x0C1 '    Saw Lead    '
	.short 0x00CD	; 0076E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00770  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00C9	; 00772  [121] prog 121 -> tone 0x0C9 "   80's Solo    "
	.short 0x00F0	; 00774  [122] prog 122 -> tone 0x0F0 '     Agogo      '
	.short 0x00FC	; 00776  [123] prog 123 -> tone 0x0FC '   Telephone    '
	.short 0x00F4	; 00778  [124] prog 124 -> tone 0x0F4 '   Synth Drum   '
	.short 0x00FB	; 0077A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0077C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0077E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 6 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 9 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 6 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_6:
	.short 0x0000	; 00780  [  0] prog   0 -> tone 0x000 '     Piano      '
	.short 0x0003	; 00782  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00784  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00786  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000D	; 00788  [  4] prog   4 -> tone 0x00D '  Modern E.P.2  '
	.short 0x0008	; 0078A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000C	; 0078C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0026	; 0078E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00790  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00792  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00794  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x0016	; 00796  [ 11] prog  11 -> tone 0x016 '   Xylophone    '
	.short 0x0017	; 00798  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0079A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x00D3	; 0079C  [ 14] prog  14 -> tone 0x0D3 '   Digi Bells   '
	.short 0x0018	; 0079E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 007A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 007A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 007A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 007A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 007A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x002A	; 007AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 007AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 007AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 007B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 007B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x0032	; 007B4  [ 26] prog  26 -> tone 0x032 'Bright Solid Gtr'
	.short 0x003B	; 007B6  [ 27] prog  27 -> tone 0x03B ' Rock Harmonics '
	.short 0x0033	; 007B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0036	; 007BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0038	; 007BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003F	; 007BE  [ 31] prog  31 -> tone 0x03F 'Hawaiian Guitar2'
	.short 0x0022	; 007C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 007C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 007C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 007C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 007C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 007CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 007CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00BA	; 007CE  [ 39] prog  39 -> tone 0x0BA '    Kalimba     '
	.short 0x006F	; 007D0  [ 40] prog  40 -> tone 0x06F 'Fretless Bass 2 '
	.short 0x0072	; 007D2  [ 41] prog  41 -> tone 0x072 '  Slap Bass 1   '
	.short 0x0070	; 007D4  [ 42] prog  42 -> tone 0x070 ' Picked E.Bass  '
	.short 0x0068	; 007D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 007D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 007DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x007F	; 007DC  [ 46] prog  46 -> tone 0x07F '   Dr.M Bass    '
	.short 0x0071	; 007DE  [ 47] prog  47 -> tone 0x071 '   Mute Bass    '
	.short 0x0088	; 007E0  [ 48] prog  48 -> tone 0x088 '   Trumpet 1    '
	.short 0x008F	; 007E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 007E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 007E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 007E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 007EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0093	; 007EC  [ 54] prog  54 -> tone 0x093 ' Closed Fr.Horn '
	.short 0x0096	; 007EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0080	; 007F0  [ 56] prog  56 -> tone 0x080 '     Brass      '
	.short 0x0080	; 007F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 007F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 007F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x0084	; 007F8  [ 60] prog  60 -> tone 0x084 ' Synth Brass 1  '
	.short 0x00E9	; 007FA  [ 61] prog  61 -> tone 0x0E9 '  Voxmosphere   '
	.short 0x00E4	; 007FC  [ 62] prog  62 -> tone 0x0E4 '   Sweep Pad    '
	.short 0x0085	; 007FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00A8	; 00800  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00802  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00804  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00806  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00808  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0080A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0080C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0080E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AD	; 00810  [ 72] prog  72 -> tone 0x0AD '   Pan Flute    '
	.short 0x00B7	; 00812  [ 73] prog  73 -> tone 0x0B7 '    Bagpipe     '
	.short 0x00AF	; 00814  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00B3	; 00816  [ 75] prog  75 -> tone 0x0B3 '   Shakuhachi   '
	.short 0x0098	; 00818  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0081A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009C	; 0081C  [ 78] prog  78 -> tone 0x09C ' Breathy Tenor  '
	.short 0x009D	; 0081E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00820  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00822  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00824  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00826  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00828  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0082A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0082C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0082E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00830  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00832  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00834  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00836  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00838  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x0059	; 0083A  [ 93] prog  93 -> tone 0x059 '<<< Drawbar 2>>>'
	.short 0x00C2	; 0083C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0083E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004A	; 00840  [ 96] prog  96 -> tone 0x04A '     Violin     '
	.short 0x004E	; 00842  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x004F	; 00844  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00846  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0041	; 00848  [100] prog 100 -> tone 0x041 'ClassicalStrings'
	.short 0x0043	; 0084A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0084C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0048	; 0084E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0051	; 00850  [104] prog 104 -> tone 0x051 '  Pop Vocal Ah  '
	.short 0x0054	; 00852  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00EF	; 00854  [106] prog 106 -> tone 0x0EF '  Windy Sweep   '
	.short 0x00DA	; 00856  [107] prog 107 -> tone 0x0DA '  Synth Vocal   '
	.short 0x00E2	; 00858  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0055	; 0085A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0085C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0085E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00860  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00862  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00864  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x00C6	; 00866  [115] prog 115 -> tone 0x0C6 ' Metallica Solo '
	.short 0x00C8	; 00868  [116] prog 116 -> tone 0x0C8 '   Digi Stack   '
	.short 0x00D4	; 0086A  [117] prog 117 -> tone 0x0D4 ' Fusion Lead 1  '
	.short 0x00C1	; 0086C  [118] prog 118 -> tone 0x0C1 '    Saw Lead    '
	.short 0x00CD	; 0086E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00870  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00EC	; 00872  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F0	; 00874  [122] prog 122 -> tone 0x0F0 '     Agogo      '
	.short 0x00FC	; 00876  [123] prog 123 -> tone 0x0FC '   Telephone    '
	.short 0x00F4	; 00878  [124] prog 124 -> tone 0x0F4 '   Synth Drum   '
	.short 0x00FB	; 0087A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0087C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0087E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 7 (melodic) ---
; ⚠ NO NAME, and the gap is measured rather than assumed: all 128
; entries select a melodic tone (index < 0x100), which is what
; `Melodic` states.
; 6 of the 128 differ from row 0's, so this row is not a copy of
; it.
; Nothing in this image says what the variation between them means,
; and the BankMap at 0x00100 maps bank-select value 7 to this row,
; which is what the suffix already says.
; ★ ROUND 8 RULES OUT THE OBVIOUS READING, which round 6 left
; standing by not testing it: that the rows are an ORDERED LADDER,
; row r being the r-th alternative wherever one exists.  If they
; were, the programs at which row r+1 differs would be a SUBSET of
; those at which row r does.  They are not, at 6 of the 6 steps
; -- row 2 differs at program 0 where row 1 does not.
; round 6 Q1, verdict NAMELESS-UNDIFFERENTIATED; round 7 Q1;
; notes/prom_d_inventory_round8.py Q6.
ToneNumBank_Melodic_7:
	.short 0x0000	; 00880  [  0] prog   0 -> tone 0x000 '     Piano      '
	.short 0x0003	; 00882  [  1] prog   1 -> tone 0x003 'Honky-Tonk Piano'
	.short 0x0001	; 00884  [  2] prog   2 -> tone 0x001 '   WSA Piano    '
	.short 0x0004	; 00886  [  3] prog   3 -> tone 0x004 ' Electric Grand '
	.short 0x000D	; 00888  [  4] prog   4 -> tone 0x00D '  Modern E.P.2  '
	.short 0x0008	; 0088A  [  5] prog   5 -> tone 0x008 '   E.Piano 1    '
	.short 0x000C	; 0088C  [  6] prog   6 -> tone 0x00C '  Modern E.P.1  '
	.short 0x0026	; 0088E  [  7] prog   7 -> tone 0x026 '   Music Box    '
	.short 0x0014	; 00890  [  8] prog   8 -> tone 0x014 '   Vibraphone   '
	.short 0x0013	; 00892  [  9] prog   9 -> tone 0x013 '  Glockenspiel  '
	.short 0x0015	; 00894  [ 10] prog  10 -> tone 0x015 '    Marimba     '
	.short 0x0016	; 00896  [ 11] prog  11 -> tone 0x016 '   Xylophone    '
	.short 0x0017	; 00898  [ 12] prog  12 -> tone 0x017 '    Celesta     '
	.short 0x001C	; 0089A  [ 13] prog  13 -> tone 0x01C ' Bottle Marimba '
	.short 0x00BE	; 0089C  [ 14] prog  14 -> tone 0x0BE '   Gamelan 2    '
	.short 0x0018	; 0089E  [ 15] prog  15 -> tone 0x018 '   Steel Drum   '
	.short 0x0010	; 008A0  [ 16] prog  16 -> tone 0x010 '  Harpsichord   '
	.short 0x0011	; 008A2  [ 17] prog  17 -> tone 0x011 '     Clavi      '
	.short 0x0010	; 008A4  [ 18] prog  18 -> tone 0x010 '  Harpsichord   '
	.short 0x0010	; 008A6  [ 19] prog  19 -> tone 0x010 '  Harpsichord   '
	.short 0x0028	; 008A8  [ 20] prog  20 -> tone 0x028 'Classical Guitar'
	.short 0x002A	; 008AA  [ 21] prog  21 -> tone 0x02A ' Jazz Ac.Guitar '
	.short 0x002C	; 008AC  [ 22] prog  22 -> tone 0x02C '  Folk Guitar   '
	.short 0x002D	; 008AE  [ 23] prog  23 -> tone 0x02D '12 String Guitar'
	.short 0x0031	; 008B0  [ 24] prog  24 -> tone 0x031 ' Jazz Guitar 2  '
	.short 0x0030	; 008B2  [ 25] prog  25 -> tone 0x030 ' Jazz Guitar 1  '
	.short 0x002F	; 008B4  [ 26] prog  26 -> tone 0x02F ' Square Guitar  '
	.short 0x003B	; 008B6  [ 27] prog  27 -> tone 0x03B ' Rock Harmonics '
	.short 0x0033	; 008B8  [ 28] prog  28 -> tone 0x033 'Mellow Solid Gtr'
	.short 0x0036	; 008BA  [ 29] prog  29 -> tone 0x036 '  Mute Guitar   '
	.short 0x0038	; 008BC  [ 30] prog  30 -> tone 0x038 'Distortion Gtr 1'
	.short 0x003F	; 008BE  [ 31] prog  31 -> tone 0x03F 'Hawaiian Guitar2'
	.short 0x0022	; 008C0  [ 32] prog  32 -> tone 0x022 '      Harp      '
	.short 0x0020	; 008C2  [ 33] prog  33 -> tone 0x020 '     Banjo      '
	.short 0x0022	; 008C4  [ 34] prog  34 -> tone 0x022 '      Harp      '
	.short 0x0021	; 008C6  [ 35] prog  35 -> tone 0x021 '    Mandolin    '
	.short 0x00B9	; 008C8  [ 36] prog  36 -> tone 0x0B9 '    Shamisen    '
	.short 0x00B8	; 008CA  [ 37] prog  37 -> tone 0x0B8 '      Koto      '
	.short 0x00BC	; 008CC  [ 38] prog  38 -> tone 0x0BC '     Sitar      '
	.short 0x00BA	; 008CE  [ 39] prog  39 -> tone 0x0BA '    Kalimba     '
	.short 0x007A	; 008D0  [ 40] prog  40 -> tone 0x07A ' Crossfade Bass '
	.short 0x0072	; 008D2  [ 41] prog  41 -> tone 0x072 '  Slap Bass 1   '
	.short 0x0070	; 008D4  [ 42] prog  42 -> tone 0x070 ' Picked E.Bass  '
	.short 0x0068	; 008D6  [ 43] prog  43 -> tone 0x068 ' Acoustic Bass  '
	.short 0x0077	; 008D8  [ 44] prog  44 -> tone 0x077 ' Synth Chopper  '
	.short 0x0077	; 008DA  [ 45] prog  45 -> tone 0x077 ' Synth Chopper  '
	.short 0x0078	; 008DC  [ 46] prog  46 -> tone 0x078 '   Wow Bass 1   '
	.short 0x0071	; 008DE  [ 47] prog  47 -> tone 0x071 '   Mute Bass    '
	.short 0x0088	; 008E0  [ 48] prog  48 -> tone 0x088 '   Trumpet 1    '
	.short 0x008F	; 008E2  [ 49] prog  49 -> tone 0x08F '     Cornet     '
	.short 0x008C	; 008E4  [ 50] prog  50 -> tone 0x08C 'Harmon Mute Tpt '
	.short 0x008E	; 008E6  [ 51] prog  51 -> tone 0x08E '  Flugel Horn   '
	.short 0x0090	; 008E8  [ 52] prog  52 -> tone 0x090 'Bright Trombone '
	.short 0x0091	; 008EA  [ 53] prog  53 -> tone 0x091 'Mellow Trombone '
	.short 0x0093	; 008EC  [ 54] prog  54 -> tone 0x093 ' Closed Fr.Horn '
	.short 0x0096	; 008EE  [ 55] prog  55 -> tone 0x096 'Orchestral Tuba '
	.short 0x0080	; 008F0  [ 56] prog  56 -> tone 0x080 '     Brass      '
	.short 0x0080	; 008F2  [ 57] prog  57 -> tone 0x080 '     Brass      '
	.short 0x0080	; 008F4  [ 58] prog  58 -> tone 0x080 '     Brass      '
	.short 0x0080	; 008F6  [ 59] prog  59 -> tone 0x080 '     Brass      '
	.short 0x0084	; 008F8  [ 60] prog  60 -> tone 0x084 ' Synth Brass 1  '
	.short 0x00EA	; 008FA  [ 61] prog  61 -> tone 0x0EA '  Wide Window   '
	.short 0x00E4	; 008FC  [ 62] prog  62 -> tone 0x0E4 '   Sweep Pad    '
	.short 0x0085	; 008FE  [ 63] prog  63 -> tone 0x085 ' Synth Brass 2  '
	.short 0x00A8	; 00900  [ 64] prog  64 -> tone 0x0A8 '    Piccolo     '
	.short 0x00A9	; 00902  [ 65] prog  65 -> tone 0x0A9 '   Jazz Flute   '
	.short 0x00A3	; 00904  [ 66] prog  66 -> tone 0x0A3 '      Oboe      '
	.short 0x00A4	; 00906  [ 67] prog  67 -> tone 0x0A4 '  English Horn  '
	.short 0x00A0	; 00908  [ 68] prog  68 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00A2	; 0090A  [ 69] prog  69 -> tone 0x0A2 'Classic Clarinet'
	.short 0x00A5	; 0090C  [ 70] prog  70 -> tone 0x0A5 '    Bassoon     '
	.short 0x00A0	; 0090E  [ 71] prog  71 -> tone 0x0A0 'Jazz Clarinet 1 '
	.short 0x00AD	; 00910  [ 72] prog  72 -> tone 0x0AD '   Pan Flute    '
	.short 0x00B7	; 00912  [ 73] prog  73 -> tone 0x0B7 '    Bagpipe     '
	.short 0x00AF	; 00914  [ 74] prog  74 -> tone 0x0AF '    Recorder    '
	.short 0x00B3	; 00916  [ 75] prog  75 -> tone 0x0B3 '   Shakuhachi   '
	.short 0x0098	; 00918  [ 76] prog  76 -> tone 0x098 '  Soprano Sax   '
	.short 0x0099	; 0091A  [ 77] prog  77 -> tone 0x099 '    Alto Sax    '
	.short 0x009C	; 0091C  [ 78] prog  78 -> tone 0x09C ' Breathy Tenor  '
	.short 0x009D	; 0091E  [ 79] prog  79 -> tone 0x09D ' Rock Tenor Sax '
	.short 0x0064	; 00920  [ 80] prog  80 -> tone 0x064 'Bright Accordion'
	.short 0x0065	; 00922  [ 81] prog  81 -> tone 0x065 'Mellow Accordion'
	.short 0x0066	; 00924  [ 82] prog  82 -> tone 0x066 '    Musette     '
	.short 0x00A6	; 00926  [ 83] prog  83 -> tone 0x0A6 '   Harmonica    '
	.short 0x0060	; 00928  [ 84] prog  84 -> tone 0x060 '  Pipe Organ 1  '
	.short 0x0061	; 0092A  [ 85] prog  85 -> tone 0x061 '  Pipe Organ 2  '
	.short 0x0063	; 0092C  [ 86] prog  86 -> tone 0x063 '   Harmonium    '
	.short 0x0062	; 0092E  [ 87] prog  87 -> tone 0x062 ' Theatre Organ  '
	.short 0x005A	; 00930  [ 88] prog  88 -> tone 0x05A '   Jazz Organ   '
	.short 0x005B	; 00932  [ 89] prog  89 -> tone 0x05B ' Full Drawbars  '
	.short 0x005E	; 00934  [ 90] prog  90 -> tone 0x05E '   Pop Organ    '
	.short 0x005D	; 00936  [ 91] prog  91 -> tone 0x05D "    16' & 1'    "
	.short 0x005F	; 00938  [ 92] prog  92 -> tone 0x05F '   Rock Organ   '
	.short 0x0058	; 0093A  [ 93] prog  93 -> tone 0x058 '<<< Drawbar 1>>>'
	.short 0x00C2	; 0093C  [ 94] prog  94 -> tone 0x0C2 '   Sine Lead    '
	.short 0x005F	; 0093E  [ 95] prog  95 -> tone 0x05F '   Rock Organ   '
	.short 0x004A	; 00940  [ 96] prog  96 -> tone 0x04A '     Violin     '
	.short 0x004E	; 00942  [ 97] prog  97 -> tone 0x04E '     Cello      '
	.short 0x004F	; 00944  [ 98] prog  98 -> tone 0x04F '   Bowed Bass   '
	.short 0x0047	; 00946  [ 99] prog  99 -> tone 0x047 ' Pizzicato Str. '
	.short 0x0041	; 00948  [100] prog 100 -> tone 0x041 'ClassicalStrings'
	.short 0x0043	; 0094A  [101] prog 101 -> tone 0x043 '  Slow Strings  '
	.short 0x0044	; 0094C  [102] prog 102 -> tone 0x044 ' Octave Strings '
	.short 0x0048	; 0094E  [103] prog 103 -> tone 0x048 'Synth Strings 1 '
	.short 0x0051	; 00950  [104] prog 104 -> tone 0x051 '  Pop Vocal Ah  '
	.short 0x0054	; 00952  [105] prog 105 -> tone 0x054 '    Humming     '
	.short 0x00EE	; 00954  [106] prog 106 -> tone 0x0EE '    Goblins     '
	.short 0x00DA	; 00956  [107] prog 107 -> tone 0x0DA '  Synth Vocal   '
	.short 0x00E2	; 00958  [108] prog 108 -> tone 0x0E2 '     Dream      '
	.short 0x0055	; 0095A  [109] prog 109 -> tone 0x055 '   Vocal Doo    '
	.short 0x0057	; 0095C  [110] prog 110 -> tone 0x057 '   Vocal Mmm    '
	.short 0x00B2	; 0095E  [111] prog 111 -> tone 0x0B2 '    Whistle     '
	.short 0x001D	; 00960  [112] prog 112 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00962  [113] prog 113 -> tone 0x01D ' African Mallet '
	.short 0x001D	; 00964  [114] prog 114 -> tone 0x01D ' African Mallet '
	.short 0x0012	; 00966  [115] prog 115 -> tone 0x012 '  Synth Clavi   '
	.short 0x000F	; 00968  [116] prog 116 -> tone 0x00F '   Bell Piano   '
	.short 0x00D5	; 0096A  [117] prog 117 -> tone 0x0D5 ' Fusion Lead 2  '
	.short 0x00C1	; 0096C  [118] prog 118 -> tone 0x0C1 '    Saw Lead    '
	.short 0x00CD	; 0096E  [119] prog 119 -> tone 0x0CD '    5th Wave    '
	.short 0x00DE	; 00970  [120] prog 120 -> tone 0x0DE '  Bowed Glass   '
	.short 0x00EC	; 00972  [121] prog 121 -> tone 0x0EC '    Ice Rain    '
	.short 0x00F0	; 00974  [122] prog 122 -> tone 0x0F0 '     Agogo      '
	.short 0x00FC	; 00976  [123] prog 123 -> tone 0x0FC '   Telephone    '
	.short 0x00F4	; 00978  [124] prog 124 -> tone 0x0F4 '   Synth Drum   '
	.short 0x00FB	; 0097A  [125] prog 125 -> tone 0x0FB '   Bird Tweet   '
	.short 0x0025	; 0097C  [126] prog 126 -> tone 0x025 '    Timpani     '
	.short 0x0023	; 0097E  [127] prog 127 -> tone 0x023 'Orchestra Hit 1 '

; --- row 8 (drum kits) ---
; Evidence: this row's own 128 LE16 entries, at file 0x00980..0x00A7F,
; and the 16-byte ASCII name of every record they select.
; All 128 select a record whose own name ends in 'Kit' -- checked
; at program 127 ('Jazz Kit') as well as program 0 ('Standard Kit').
; 17 distinct tone indices in the row.  round 5 Q2 row_names().
ToneNumBank_DrumKits:
	.short 0x0103	; 00980  [  0] prog   0 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 00982  [  1] prog   1 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 00984  [  2] prog   2 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 00986  [  3] prog   3 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 00988  [  4] prog   4 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 0098A  [  5] prog   5 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 0098C  [  6] prog   6 -> tone 0x103 ' Standard Kit   '
	.short 0x0103	; 0098E  [  7] prog   7 -> tone 0x103 ' Standard Kit   '
	.short 0x0104	; 00990  [  8] prog   8 -> tone 0x104 '   Room Kit     '
	.short 0x0105	; 00992  [  9] prog   9 -> tone 0x105 ' Light Rock Kit '
	.short 0x0107	; 00994  [ 10] prog  10 -> tone 0x107 '   Funk Kit     '
	.short 0x0104	; 00996  [ 11] prog  11 -> tone 0x104 '   Room Kit     '
	.short 0x0104	; 00998  [ 12] prog  12 -> tone 0x104 '   Room Kit     '
	.short 0x0104	; 0099A  [ 13] prog  13 -> tone 0x104 '   Room Kit     '
	.short 0x0104	; 0099C  [ 14] prog  14 -> tone 0x104 '   Room Kit     '
	.short 0x0104	; 0099E  [ 15] prog  15 -> tone 0x104 '   Room Kit     '
	.short 0x0106	; 009A0  [ 16] prog  16 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009A2  [ 17] prog  17 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009A4  [ 18] prog  18 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009A6  [ 19] prog  19 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009A8  [ 20] prog  20 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009AA  [ 21] prog  21 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009AC  [ 22] prog  22 -> tone 0x106 '   Power Kit    '
	.short 0x0106	; 009AE  [ 23] prog  23 -> tone 0x106 '   Power Kit    '
	.short 0x010B	; 009B0  [ 24] prog  24 -> tone 0x10B ' Electric Kit   '
	.short 0x010A	; 009B2  [ 25] prog  25 -> tone 0x10A '   Soul Kit     '
	.short 0x0108	; 009B4  [ 26] prog  26 -> tone 0x108 '   Dance Kit    '
	.short 0x0109	; 009B6  [ 27] prog  27 -> tone 0x109 '   House Kit    '
	.short 0x010B	; 009B8  [ 28] prog  28 -> tone 0x10B ' Electric Kit   '
	.short 0x010C	; 009BA  [ 29] prog  29 -> tone 0x10C '   Synth Kit    '
	.short 0x010D	; 009BC  [ 30] prog  30 -> tone 0x10D ' Modeling Kit   '
	.short 0x010D	; 009BE  [ 31] prog  31 -> tone 0x10D ' Modeling Kit   '
	.short 0x0100	; 009C0  [ 32] prog  32 -> tone 0x100 '   Jazz Kit     '
	.short 0x0102	; 009C2  [ 33] prog  33 -> tone 0x102 '   Trad Kit     '
	.short 0x0100	; 009C4  [ 34] prog  34 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009C6  [ 35] prog  35 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009C8  [ 36] prog  36 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009CA  [ 37] prog  37 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009CC  [ 38] prog  38 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009CE  [ 39] prog  39 -> tone 0x100 '   Jazz Kit     '
	.short 0x0101	; 009D0  [ 40] prog  40 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009D2  [ 41] prog  41 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009D4  [ 42] prog  42 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009D6  [ 43] prog  43 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009D8  [ 44] prog  44 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009DA  [ 45] prog  45 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009DC  [ 46] prog  46 -> tone 0x101 '  Brush Kit     '
	.short 0x0101	; 009DE  [ 47] prog  47 -> tone 0x101 '  Brush Kit     '
	.short 0x0111	; 009E0  [ 48] prog  48 -> tone 0x111 'GM Orchestra Kit'
	.short 0x0100	; 009E2  [ 49] prog  49 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009E4  [ 50] prog  50 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009E6  [ 51] prog  51 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009E8  [ 52] prog  52 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009EA  [ 53] prog  53 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009EC  [ 54] prog  54 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009EE  [ 55] prog  55 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009F0  [ 56] prog  56 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009F2  [ 57] prog  57 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009F4  [ 58] prog  58 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009F6  [ 59] prog  59 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009F8  [ 60] prog  60 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009FA  [ 61] prog  61 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009FC  [ 62] prog  62 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 009FE  [ 63] prog  63 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A00  [ 64] prog  64 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A02  [ 65] prog  65 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A04  [ 66] prog  66 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A06  [ 67] prog  67 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A08  [ 68] prog  68 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A0A  [ 69] prog  69 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A0C  [ 70] prog  70 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A0E  [ 71] prog  71 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A10  [ 72] prog  72 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A12  [ 73] prog  73 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A14  [ 74] prog  74 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A16  [ 75] prog  75 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A18  [ 76] prog  76 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A1A  [ 77] prog  77 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A1C  [ 78] prog  78 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A1E  [ 79] prog  79 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A20  [ 80] prog  80 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A22  [ 81] prog  81 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A24  [ 82] prog  82 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A26  [ 83] prog  83 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A28  [ 84] prog  84 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A2A  [ 85] prog  85 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A2C  [ 86] prog  86 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A2E  [ 87] prog  87 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A30  [ 88] prog  88 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A32  [ 89] prog  89 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A34  [ 90] prog  90 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A36  [ 91] prog  91 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A38  [ 92] prog  92 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A3A  [ 93] prog  93 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A3C  [ 94] prog  94 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A3E  [ 95] prog  95 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A40  [ 96] prog  96 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A42  [ 97] prog  97 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A44  [ 98] prog  98 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A46  [ 99] prog  99 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A48  [100] prog 100 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A4A  [101] prog 101 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A4C  [102] prog 102 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A4E  [103] prog 103 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A50  [104] prog 104 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A52  [105] prog 105 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A54  [106] prog 106 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A56  [107] prog 107 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A58  [108] prog 108 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A5A  [109] prog 109 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A5C  [110] prog 110 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A5E  [111] prog 111 -> tone 0x100 '   Jazz Kit     '
	.short 0x010E	; 00A60  [112] prog 112 -> tone 0x10E ' Orchestra Kit  '
	.short 0x0100	; 00A62  [113] prog 113 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A64  [114] prog 114 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A66  [115] prog 115 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A68  [116] prog 116 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A6A  [117] prog 117 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A6C  [118] prog 118 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A6E  [119] prog 119 -> tone 0x100 '   Jazz Kit     '
	.short 0x010F	; 00A70  [120] prog 120 -> tone 0x10F 'Sound Effect Kit'
	.short 0x0100	; 00A72  [121] prog 121 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A74  [122] prog 122 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A76  [123] prog 123 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A78  [124] prog 124 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A7A  [125] prog 125 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A7C  [126] prog 126 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A7E  [127] prog 127 -> tone 0x100 '   Jazz Kit     '

; --- row 9 (drum kits) ---
; Evidence: this row's own 128 LE16 entries, at file 0x00A80..0x00B7F,
; and the 16-byte ASCII name of every record they select.
; 127 of the 128 hold tone 0x100 'Jazz Kit'.  The one that does not is at
; program 127, holding tone 0x110 'Special sound' -- which occurs 1 time
; in all 1,280 entries of this table, so it is unique to this
; row.  That entry is the whole of what distinguishes this row, so it
; is what names it.
; 2 distinct tone indices in the row.  round 5 Q2 row_names().
ToneNumBank_SpecialSound:
	.short 0x0100	; 00A80  [  0] prog   0 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A82  [  1] prog   1 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A84  [  2] prog   2 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A86  [  3] prog   3 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A88  [  4] prog   4 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A8A  [  5] prog   5 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A8C  [  6] prog   6 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A8E  [  7] prog   7 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A90  [  8] prog   8 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A92  [  9] prog   9 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A94  [ 10] prog  10 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A96  [ 11] prog  11 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A98  [ 12] prog  12 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A9A  [ 13] prog  13 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A9C  [ 14] prog  14 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00A9E  [ 15] prog  15 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AA0  [ 16] prog  16 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AA2  [ 17] prog  17 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AA4  [ 18] prog  18 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AA6  [ 19] prog  19 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AA8  [ 20] prog  20 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AAA  [ 21] prog  21 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AAC  [ 22] prog  22 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AAE  [ 23] prog  23 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AB0  [ 24] prog  24 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AB2  [ 25] prog  25 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AB4  [ 26] prog  26 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AB6  [ 27] prog  27 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AB8  [ 28] prog  28 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ABA  [ 29] prog  29 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ABC  [ 30] prog  30 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ABE  [ 31] prog  31 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AC0  [ 32] prog  32 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AC2  [ 33] prog  33 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AC4  [ 34] prog  34 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AC6  [ 35] prog  35 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AC8  [ 36] prog  36 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ACA  [ 37] prog  37 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ACC  [ 38] prog  38 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ACE  [ 39] prog  39 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AD0  [ 40] prog  40 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AD2  [ 41] prog  41 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AD4  [ 42] prog  42 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AD6  [ 43] prog  43 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AD8  [ 44] prog  44 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ADA  [ 45] prog  45 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ADC  [ 46] prog  46 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00ADE  [ 47] prog  47 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AE0  [ 48] prog  48 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AE2  [ 49] prog  49 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AE4  [ 50] prog  50 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AE6  [ 51] prog  51 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AE8  [ 52] prog  52 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AEA  [ 53] prog  53 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AEC  [ 54] prog  54 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AEE  [ 55] prog  55 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AF0  [ 56] prog  56 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AF2  [ 57] prog  57 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AF4  [ 58] prog  58 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AF6  [ 59] prog  59 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AF8  [ 60] prog  60 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AFA  [ 61] prog  61 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AFC  [ 62] prog  62 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00AFE  [ 63] prog  63 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B00  [ 64] prog  64 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B02  [ 65] prog  65 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B04  [ 66] prog  66 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B06  [ 67] prog  67 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B08  [ 68] prog  68 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B0A  [ 69] prog  69 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B0C  [ 70] prog  70 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B0E  [ 71] prog  71 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B10  [ 72] prog  72 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B12  [ 73] prog  73 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B14  [ 74] prog  74 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B16  [ 75] prog  75 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B18  [ 76] prog  76 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B1A  [ 77] prog  77 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B1C  [ 78] prog  78 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B1E  [ 79] prog  79 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B20  [ 80] prog  80 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B22  [ 81] prog  81 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B24  [ 82] prog  82 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B26  [ 83] prog  83 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B28  [ 84] prog  84 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B2A  [ 85] prog  85 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B2C  [ 86] prog  86 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B2E  [ 87] prog  87 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B30  [ 88] prog  88 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B32  [ 89] prog  89 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B34  [ 90] prog  90 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B36  [ 91] prog  91 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B38  [ 92] prog  92 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B3A  [ 93] prog  93 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B3C  [ 94] prog  94 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B3E  [ 95] prog  95 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B40  [ 96] prog  96 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B42  [ 97] prog  97 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B44  [ 98] prog  98 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B46  [ 99] prog  99 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B48  [100] prog 100 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B4A  [101] prog 101 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B4C  [102] prog 102 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B4E  [103] prog 103 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B50  [104] prog 104 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B52  [105] prog 105 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B54  [106] prog 106 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B56  [107] prog 107 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B58  [108] prog 108 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B5A  [109] prog 109 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B5C  [110] prog 110 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B5E  [111] prog 111 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B60  [112] prog 112 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B62  [113] prog 113 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B64  [114] prog 114 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B66  [115] prog 115 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B68  [116] prog 116 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B6A  [117] prog 117 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B6C  [118] prog 118 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B6E  [119] prog 119 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B70  [120] prog 120 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B72  [121] prog 121 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B74  [122] prog 122 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B76  [123] prog 123 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B78  [124] prog 124 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B7A  [125] prog 125 -> tone 0x100 '   Jazz Kit     '
	.short 0x0100	; 00B7C  [126] prog 126 -> tone 0x100 '   Jazz Kit     '
	.short 0x0110	; 00B7E  [127] prog 127 -> tone 0x110 ' Special sound  '

; ==========================================================================
; ToneDB_ToneOffsetTable -- directory slot +0x08
; file 0x00B80 .. 0x00FC7   (1096 bytes)
; --------------------------------------------------------------------------
; 274 LE32 file offsets.  Entry i is tone index i; the scan that finds the
; end stops on the zero word at 0x0FC8, which is the FIRST BYTES OF THE NEXT
; REGION, not a terminator inside this one.  Entry i is tone
; index i; the first 16 bytes at the target are the tone's displayed name,
; space-padded and centred.  Indices 0x000-0x0FF are melodic tone records,
; 0x100-0x111 are the 18 drum kits.  All 274 offsets are distinct.
; 
; Same structure and same directory slot as the KN5000's table of the same
; name (629 entries there).
; 
; ★★ WAVE 7 ROUND 11 -- THE INDEX ORDER IS THE PANEL'S SOUND GROUP ORDER.
; Rounds 4-10 left this table's ORDER unexplained.  It is 34 groups of 8:
; tone index k is group k/8, member k%8, and the group's displayed name is
; prom_b's 16 ASCII bytes at 0xF068B4 + 16*group.  The 34 groups, in this
; table's own order:
;      0 PIANO               1 E.PIANO             2 HARPSI. & MALLET 
;      3 SPECIAL MALLET      4 SPECIAL PERC.       5 GUITAR 1         
;      6 GUITAR 2            7 GUITAR 3            8 STRINGS 1        
;      9 STRINGS 2          10 VOCAL              11 ORGAN            
;     12 PIPE & ACCORDION   13 BASS 1             14 BASS 2           
;     15 BASS 3             16 BRASS              17 TRUMPET          
;     18 DEEP BRASS         19 SAXOPHONE          20 REED             
;     21 FLUTE              22 OTHER FLUTE&REED   23 ETHNIC PERC.     
;     24 SYNTH LEAD 1       25 SYNTH LEAD 2       26 SYNTH LEAD 3     
;     27 SYNTH PAD 1        28 SYNTH PAD 2        29 SYNTH PAD 3      
;     30 PERCUSSION         31 EFFECT             32 DRUMS 1          
;     33 DRUMS 2          
; 
; Evidence: prom_a 0xFC231D `add XBC,0x00F06EF4` reaches prom_b's
; group/member table after 0xFC230C `mul WA,0x0010` (group) and 0xFC2317
; `mul BC,0x0002` (member), so a group's row holds 16/2 = 8 entries; entry
; k of that table is a (program, bank-select) pair which THIS image's own
; ToneDB_BankMap and ToneDB_ToneNumBanks resolve to tone k, for 272
; consecutive entries k = 0..271 (entry 272 is the first that is not its own
; index); 272/8 = 34, and prom_b's name table has exactly 34 named rows
; before row 34 becomes `----------------`.
; ⚠ WHICH NAME GOES WITH WHICH OCTET is a separate claim and is witnessed
; twice: 23 of the 34 group names share a word with one of the 8 tone names
; in their octet against a best rotation of 7, and the 16 tone names ending
; in `Kit` occupy exactly the groups whose names spell DRUM.  11 groups
; share no word; Q21 lists them.
; ⚠ AND THE PROGRAM ORDER OF ToneDB_ToneNumBanks IS A DIFFERENT THING and is
; still unexplained -- it is not General MIDI (round 9 Q14) and this finding
; says nothing about it.
; notes/prom_d_inventory_round8.py Q21.
; 
; Evidence: prom_c reads directory slot +0x08 at 1 site.  The first is
; 0xFB4283 `ld XBC,(0x00D7F1)` -- prom_d's base 0x00F00000 -- followed at
; 0xFB4288 by `ld XWA,(XBC+0x08)`.  All 1: 0xFB4288.
; Every one re-decoded from prom_c's ROM bytes at the cited address by
; notes/prom_d_documentation_round3.py Q2 (99 reads over 33 slots, 0 that
; fail to decode).  The base is a compile-time constant: the only two
; instructions in prom_c that write 0x00D7ED / 0x00D7F1 are 0xFB0523 and
; 0xFB0528, both storing the 0x00F00000 loaded at 0xFB051E.
; 
; ★ THE ENTRY WIDTH AND THE 0-BASED READING ARE prom_c's TOO:
;     0xFB4288  ld XWA,(XBC+0x08)    this table's file offset
;     0xFB4290  sll 0x02,IY          tone index * 4, so entries are LE32
;     0xFB4298  add XIY,(0x00d7ed)   + base => the absolute entry
;     0xFB429D  ld XWA,(XIY)         the entry: a tone record's FILE OFFSET
;     0xFB429F  add XWA,(0x00d7ed)   + base AGAIN => the record itself
; That second add is the whole argument for `0-based file offsets`: the
; value stored here is NOT an address, and prom_c adds the base to it.
; notes/prom_d_documentation_round3.py Q4a.
; ==========================================================================
ToneDB_ToneOffsetTable:
	.long 0x000013C8	; tone 0x000  '     Piano      '
	.long 0x00001599	; tone 0x001  '   WSA Piano    '
	.long 0x0000176A	; tone 0x002  '   Rock Piano   '
	.long 0x0000193B	; tone 0x003  'Honky-Tonk Piano'
	.long 0x00001B0C	; tone 0x004  ' Electric Grand '
	.long 0x00001CDD	; tone 0x005  '  Midi Grand 1  '
	.long 0x00001F2A	; tone 0x006  '  Midi Grand 2  '
	.long 0x00002177	; tone 0x007  '  Jangle Piano  '
	.long 0x000023C4	; tone 0x008  '   E.Piano 1    '
	.long 0x00002519	; tone 0x009  '   E.Piano 2    '
	.long 0x0000266E	; tone 0x00A  ' Suitcase E.P.  '
	.long 0x000027C3	; tone 0x00B  'Tremolo E.Piano '
	.long 0x00002918	; tone 0x00C  '  Modern E.P.1  '
	.long 0x00002A6D	; tone 0x00D  '  Modern E.P.2  '
	.long 0x00002C3E	; tone 0x00E  '  Modern E.P.3  '
	.long 0x00002E8B	; tone 0x00F  '   Bell Piano   '
	.long 0x000030D8	; tone 0x010  '  Harpsichord   '
	.long 0x00003325	; tone 0x011  '     Clavi      '
	.long 0x000034F6	; tone 0x012  '  Synth Clavi   '
	.long 0x0000364B	; tone 0x013  '  Glockenspiel  '
	.long 0x0000381C	; tone 0x014  '   Vibraphone   '
	.long 0x000039ED	; tone 0x015  '    Marimba     '
	.long 0x00003B42	; tone 0x016  '   Xylophone    '
	.long 0x00003C97	; tone 0x017  '    Celesta     '
	.long 0x00003DEC	; tone 0x018  '   Steel Drum   '
	.long 0x00003FBD	; tone 0x019  'Power Steel Drum'
	.long 0x0000418E	; tone 0x01A  ' Tubular Bells  '
	.long 0x000042E3	; tone 0x01B  '  Tinkle Bell   '
	.long 0x000044B4	; tone 0x01C  ' Bottle Marimba '
	.long 0x00004609	; tone 0x01D  ' African Mallet '
	.long 0x000047DA	; tone 0x01E  'Caribbean Mallet'
	.long 0x00004A27	; tone 0x01F  ' Synth Glocken  '
	.long 0x00004C74	; tone 0x020  '     Banjo      '
	.long 0x00004DC9	; tone 0x021  '    Mandolin    '
	.long 0x00004F1E	; tone 0x022  '      Harp      '
	.long 0x000050EF	; tone 0x023  'Orchestra Hit 1 '
	.long 0x00005244	; tone 0x024  'Orchestra Hit 2 '
	.long 0x00005491	; tone 0x025  '    Timpani     '
	.long 0x000055E6	; tone 0x026  '   Music Box    '
	.long 0x0000573B	; tone 0x027  'Christmas Piano '
	.long 0x0000590C	; tone 0x028  'Classical Guitar'
	.long 0x00005A61	; tone 0x029  ' Spanish Guitar '
	.long 0x00005BB6	; tone 0x02A  ' Jazz Ac.Guitar '
	.long 0x00005D0B	; tone 0x02B  'Guitar Harmonics'
	.long 0x00005EDC	; tone 0x02C  '  Folk Guitar   '
	.long 0x000060AD	; tone 0x02D  '12 String Guitar'
	.long 0x00006376	; tone 0x02E  'ElectroAc.Guitar'
	.long 0x000064CB	; tone 0x02F  ' Square Guitar  '
	.long 0x00006620	; tone 0x030  ' Jazz Guitar 1  '
	.long 0x00006775	; tone 0x031  ' Jazz Guitar 2  '
	.long 0x00006946	; tone 0x032  'Bright Solid Gtr'
	.long 0x00006B17	; tone 0x033  'Mellow Solid Gtr'
	.long 0x00006C6C	; tone 0x034  'Clean Solid Gtr '
	.long 0x00006DC1	; tone 0x035  'Fusion Solid Gtr'
	.long 0x00006F16	; tone 0x036  '  Mute Guitar   '
	.long 0x00007163	; tone 0x037  'Funk Mute Guitar'
	.long 0x00007334	; tone 0x038  'Distortion Gtr 1'
	.long 0x00007489	; tone 0x039  'Distortion Gtr 2'
	.long 0x000075DE	; tone 0x03A  'Overdrive Guitar'
	.long 0x000077AF	; tone 0x03B  ' Rock Harmonics '
	.long 0x00007980	; tone 0x03C  'Synth Solid Gtr '
	.long 0x00007B51	; tone 0x03D  ' Country Guitar '
	.long 0x00007CA6	; tone 0x03E  'Hawaiian Guitar1'
	.long 0x00007DFB	; tone 0x03F  'Hawaiian Guitar2'
	.long 0x00007F50	; tone 0x040  'SymphonicStrings'
	.long 0x00008121	; tone 0x041  'ClassicalStrings'
	.long 0x00008276	; tone 0x042  'Marcato Strings '
	.long 0x000083CB	; tone 0x043  '  Slow Strings  '
	.long 0x00008520	; tone 0x044  ' Octave Strings '
	.long 0x000086F1	; tone 0x045  '  Bass Strings  '
	.long 0x000088C2	; tone 0x046  'Tremolo Strings '
	.long 0x00008A93	; tone 0x047  ' Pizzicato Str. '
	.long 0x00008C64	; tone 0x048  'Synth Strings 1 '
	.long 0x00008EB1	; tone 0x049  'Synth Strings 2 '
	.long 0x00009082	; tone 0x04A  '     Violin     '
	.long 0x000091D7	; tone 0x04B  '  Jazz Violin   '
	.long 0x0000932C	; tone 0x04C  '     Fiddle     '
	.long 0x000094FD	; tone 0x04D  '     Viola      '
	.long 0x00009652	; tone 0x04E  '     Cello      '
	.long 0x000097A7	; tone 0x04F  '   Bowed Bass   '
	.long 0x000098FC	; tone 0x050  '    Vocal Ah    '
	.long 0x00009A51	; tone 0x051  '  Pop Vocal Ah  '
	.long 0x00009BA6	; tone 0x052  'Stereo Vocal Ah '
	.long 0x00009D77	; tone 0x053  '   Vocal Ooh    '
	.long 0x00009ECC	; tone 0x054  '    Humming     '
	.long 0x0000A09D	; tone 0x055  '   Vocal Doo    '
	.long 0x0000A26E	; tone 0x056  '   Vocal Daa    '
	.long 0x0000A43F	; tone 0x057  '   Vocal Mmm    '
	.long 0x000446B4	; tone 0x058  '<<< Drawbar 1>>>'
	.long 0x000448D1	; tone 0x059  '<<< Drawbar 2>>>'
	.long 0x0000A594	; tone 0x05A  '   Jazz Organ   '
	.long 0x0000A6E9	; tone 0x05B  ' Full Drawbars  '
	.long 0x0000A83E	; tone 0x05C  ' Jazz Drawbars  '
	.long 0x0000A993	; tone 0x05D  "    16' & 1'    "
	.long 0x0000AAE8	; tone 0x05E  '   Pop Organ    '
	.long 0x0000AD35	; tone 0x05F  '   Rock Organ   '
	.long 0x0000AF82	; tone 0x060  '  Pipe Organ 1  '
	.long 0x0000B153	; tone 0x061  '  Pipe Organ 2  '
	.long 0x0000B324	; tone 0x062  ' Theatre Organ  '
	.long 0x0000B571	; tone 0x063  '   Harmonium    '
	.long 0x0000B742	; tone 0x064  'Bright Accordion'
	.long 0x0000B897	; tone 0x065  'Mellow Accordion'
	.long 0x0000B9EC	; tone 0x066  '    Musette     '
	.long 0x0000BBBD	; tone 0x067  '   Bandoneon    '
	.long 0x0000BD8E	; tone 0x068  ' Acoustic Bass  '
	.long 0x0000BEE3	; tone 0x069  ' Mellow Ac.Bass '
	.long 0x0000C038	; tone 0x06A  ' Electric Bass  '
	.long 0x0000C18D	; tone 0x06B  ' Bright E.Bass  '
	.long 0x0000C2E2	; tone 0x06C  ' Fusion E.Bass  '
	.long 0x0000C437	; tone 0x06D  '  Funky E.Bass  '
	.long 0x0000C58C	; tone 0x06E  'Fretless Bass 1 '
	.long 0x0000C6E1	; tone 0x06F  'Fretless Bass 2 '
	.long 0x0000C836	; tone 0x070  ' Picked E.Bass  '
	.long 0x0000C98B	; tone 0x071  '   Mute Bass    '
	.long 0x0000CAE0	; tone 0x072  '  Slap Bass 1   '
	.long 0x0000CCB1	; tone 0x073  '  Slap Bass 2   '
	.long 0x0000CE82	; tone 0x074  '  Slap Bass 3   '
	.long 0x0000D053	; tone 0x075  '  Analog Bass   '
	.long 0x0000D1A8	; tone 0x076  '   Soul Bass    '
	.long 0x0000D2FD	; tone 0x077  ' Synth Chopper  '
	.long 0x0000D452	; tone 0x078  '   Wow Bass 1   '
	.long 0x0000D5A7	; tone 0x079  '   Wow Bass 2   '
	.long 0x0000D6FC	; tone 0x07A  ' Crossfade Bass '
	.long 0x0000D8CD	; tone 0x07B  '   Dance Bass   '
	.long 0x0000DA22	; tone 0x07C  '   House Bass   '
	.long 0x0000DB77	; tone 0x07D  ' Metallic Bass  '
	.long 0x0000DCCC	; tone 0x07E  '  Plastic Bass  '
	.long 0x0000DE21	; tone 0x07F  '   Dr.M Bass    '
	.long 0x0000DFF2	; tone 0x080  '     Brass      '
	.long 0x0000E1C3	; tone 0x081  ' Brass & Synth  '
	.long 0x0000E410	; tone 0x082  '  Octave Brass  '
	.long 0x0000E65D	; tone 0x083  'Mute Brass Ens. '
	.long 0x0000E8AA	; tone 0x084  ' Synth Brass 1  '
	.long 0x0000EA7B	; tone 0x085  ' Synth Brass 2  '
	.long 0x0000EC4C	; tone 0x086  ' Synth Brass 3  '
	.long 0x0000EDA1	; tone 0x087  ' Synth Brass 4  '
	.long 0x0000EF72	; tone 0x088  '   Trumpet 1    '
	.long 0x0000F0C7	; tone 0x089  '   Trumpet 2    '
	.long 0x0000F21C	; tone 0x08A  ' Mellow Trumpet '
	.long 0x0000F371	; tone 0x08B  'Orchest.Trumpet '
	.long 0x0000F4C6	; tone 0x08C  'Harmon Mute Tpt '
	.long 0x0000F61B	; tone 0x08D  'Straight MuteTpt'
	.long 0x0000F770	; tone 0x08E  '  Flugel Horn   '
	.long 0x0000F8C5	; tone 0x08F  '     Cornet     '
	.long 0x0000FA1A	; tone 0x090  'Bright Trombone '
	.long 0x0000FB6F	; tone 0x091  'Mellow Trombone '
	.long 0x0000FCC4	; tone 0x092  'CupMuteTrombone '
	.long 0x0000FE19	; tone 0x093  ' Closed Fr.Horn '
	.long 0x0000FF6E	; tone 0x094  '  Open Fr.Horn  '
	.long 0x000100C3	; tone 0x095  '  Fr.Horn Ens.  '
	.long 0x00010294	; tone 0x096  'Orchestral Tuba '
	.long 0x000103E9	; tone 0x097  ' Marching Tuba  '
	.long 0x000105BA	; tone 0x098  '  Soprano Sax   '
	.long 0x0001078B	; tone 0x099  '    Alto Sax    '
	.long 0x0001095C	; tone 0x09A  'Mellow Alto Sax '
	.long 0x00010B2D	; tone 0x09B  '   Tenor Sax    '
	.long 0x00010CFE	; tone 0x09C  ' Breathy Tenor  '
	.long 0x00010F4B	; tone 0x09D  ' Rock Tenor Sax '
	.long 0x0001111C	; tone 0x09E  '  Baritone Sax  '
	.long 0x00011369	; tone 0x09F  ' Distortion Sax '
	.long 0x000115B6	; tone 0x0A0  'Jazz Clarinet 1 '
	.long 0x00011787	; tone 0x0A1  'Jazz Clarinet 2 '
	.long 0x000119D4	; tone 0x0A2  'Classic Clarinet'
	.long 0x00011B29	; tone 0x0A3  '      Oboe      '
	.long 0x00011C7E	; tone 0x0A4  '  English Horn  '
	.long 0x00011DD3	; tone 0x0A5  '    Bassoon     '
	.long 0x00011F28	; tone 0x0A6  '   Harmonica    '
	.long 0x0001207D	; tone 0x0A7  'Blues Harmonica '
	.long 0x000121D2	; tone 0x0A8  '    Piccolo     '
	.long 0x00012327	; tone 0x0A9  '   Jazz Flute   '
	.long 0x0001247C	; tone 0x0AA  'Classical Flute '
	.long 0x0001264D	; tone 0x0AB  '   Alto Flute   '
	.long 0x0001281E	; tone 0x0AC  ' Flatter Flute  '
	.long 0x000129EF	; tone 0x0AD  '   Pan Flute    '
	.long 0x00012B44	; tone 0x0AE  ' Synth Calliope '
	.long 0x00012D91	; tone 0x0AF  '    Recorder    '
	.long 0x00012EE6	; tone 0x0B0  '    Ocarina     '
	.long 0x0001303B	; tone 0x0B1  '  Blown Bottle  '
	.long 0x00013288	; tone 0x0B2  '    Whistle     '
	.long 0x000133DD	; tone 0x0B3  '   Shakuhachi   '
	.long 0x00013532	; tone 0x0B4  '     Quena      '
	.long 0x0001377F	; tone 0x0B5  '      Ney       '
	.long 0x00013950	; tone 0x0B6  '     Shanai     '
	.long 0x00013B9D	; tone 0x0B7  '    Bagpipe     '
	.long 0x00013D6E	; tone 0x0B8  '      Koto      '
	.long 0x00013EC3	; tone 0x0B9  '    Shamisen    '
	.long 0x00014018	; tone 0x0BA  '    Kalimba     '
	.long 0x000141E9	; tone 0x0BB  ' Metal Kalimba  '
	.long 0x000143BA	; tone 0x0BC  '     Sitar      '
	.long 0x0001450F	; tone 0x0BD  '   Gamelan 1    '
	.long 0x0001475C	; tone 0x0BE  '   Gamelan 2    '
	.long 0x000149A9	; tone 0x0BF  '    Dulcimer    '
	.long 0x00014B7A	; tone 0x0C0  '  Square Lead   '
	.long 0x00014D4B	; tone 0x0C1  '    Saw Lead    '
	.long 0x00014F1C	; tone 0x0C2  '   Sine Lead    '
	.long 0x000150ED	; tone 0x0C3  '    Air Vox     '
	.long 0x000152BE	; tone 0x0C4  '  Chiffer Lead  '
	.long 0x0001550B	; tone 0x0C5  '    Charang     '
	.long 0x00015758	; tone 0x0C6  ' Metallica Solo '
	.long 0x000159A5	; tone 0x0C7  '  Talking Lead  '
	.long 0x00015BF2	; tone 0x0C8  '   Digi Stack   '
	.long 0x00015E3F	; tone 0x0C9  "   80's Solo    "
	.long 0x0001608C	; tone 0x0CA  '  Steamy Keys   '
	.long 0x000162D9	; tone 0x0CB  '  Olymp Synth   '
	.long 0x00016526	; tone 0x0CC  '   Voco Synth   '
	.long 0x00016773	; tone 0x0CD  '    5th Wave    '
	.long 0x00016944	; tone 0x0CE  '  Bass & Lead   '
	.long 0x00016B15	; tone 0x0CF  '  Sleigh Synth  '
	.long 0x00016CE6	; tone 0x0D0  ' Talking Synth  '
	.long 0x00016EB7	; tone 0x0D1  '   Synth Harp   '
	.long 0x00017088	; tone 0x0D2  '   Afro Dance   '
	.long 0x00017259	; tone 0x0D3  '   Digi Bells   '
	.long 0x000174A6	; tone 0x0D4  ' Fusion Lead 1  '
	.long 0x00017677	; tone 0x0D5  ' Fusion Lead 2  '
	.long 0x00017848	; tone 0x0D6  '   Funky Lead   '
	.long 0x00017A19	; tone 0x0D7  '     Sweppy     '
	.long 0x00017BEA	; tone 0x0D8  'Mellow Ensemble '
	.long 0x00017DBB	; tone 0x0D9  ' Warm Synth Pad '
	.long 0x00017F8C	; tone 0x0DA  '  Synth Vocal   '
	.long 0x0001815D	; tone 0x0DB  '   Spacy Pad    '
	.long 0x0001832E	; tone 0x0DC  '   Metal Pad    '
	.long 0x000184FF	; tone 0x0DD  '   Star Theme   '
	.long 0x0001874C	; tone 0x0DE  '  Bowed Glass   '
	.long 0x0001891D	; tone 0x0DF  '   Atmosphere   '
	.long 0x00018AEE	; tone 0x0E0  '    Fantasia    '
	.long 0x00018D3B	; tone 0x0E1  '    Bell Pad    '
	.long 0x00018F0C	; tone 0x0E2  '     Dream      '
	.long 0x00019159	; tone 0x0E3  '      Mist      '
	.long 0x000193A6	; tone 0x0E4  '   Sweep Pad    '
	.long 0x00019577	; tone 0x0E5  '    Halo Pad    '
	.long 0x000197C4	; tone 0x0E6  '   Echo Drops   '
	.long 0x00019995	; tone 0x0E7  ' Happy Ensemble '
	.long 0x00019B66	; tone 0x0E8  '   Poly Synth   '
	.long 0x00019DB3	; tone 0x0E9  '  Voxmosphere   '
	.long 0x0001A000	; tone 0x0EA  '  Wide Window   '
	.long 0x0001A1D1	; tone 0x0EB  ' Dark Universe  '
	.long 0x0001A49A	; tone 0x0EC  '    Ice Rain    '
	.long 0x0001A6E7	; tone 0x0ED  '   Soundtrack   '
	.long 0x0001A934	; tone 0x0EE  '    Goblins     '
	.long 0x0001AB81	; tone 0x0EF  '  Windy Sweep   '
	.long 0x0001ADCE	; tone 0x0F0  '     Agogo      '
	.long 0x0001AF23	; tone 0x0F1  '   Wood Block   '
	.long 0x0001B078	; tone 0x0F2  '   Taiko Drum   '
	.long 0x0001B1CD	; tone 0x0F3  '  Melodic Tom   '
	.long 0x0001B322	; tone 0x0F4  '   Synth Drum   '
	.long 0x0001B477	; tone 0x0F5  ' Reverse Cymbal '
	.long 0x0001B5CC	; tone 0x0F6  '  Talking Drum  '
	.long 0x0001B721	; tone 0x0F7  '    Berimbau    '
	.long 0x0001B876	; tone 0x0F8  '   Fret Noise   '
	.long 0x0001B9CB	; tone 0x0F9  '  Breath Noise  '
	.long 0x0001BB20	; tone 0x0FA  '    Seashore    '
	.long 0x0001BCF1	; tone 0x0FB  '   Bird Tweet   '
	.long 0x0001BEC2	; tone 0x0FC  '   Telephone    '
	.long 0x0001C017	; tone 0x0FD  '   Helicopter   '
	.long 0x0001C16C	; tone 0x0FE  '    Applause    '
	.long 0x0001C33D	; tone 0x0FF  '    Gun Shot    '
	.long 0x0002BAA4	; tone 0x100  '   Jazz Kit     '
	.long 0x0002BDD4	; tone 0x101  '  Brush Kit     '
	.long 0x0002BC3C	; tone 0x102  '   Trad Kit     '
	.long 0x0002B2AC	; tone 0x103  ' Standard Kit   '
	.long 0x0002B444	; tone 0x104  '   Room Kit     '
	.long 0x0002B774	; tone 0x105  ' Light Rock Kit '
	.long 0x0002B5DC	; tone 0x106  '   Power Kit    '
	.long 0x0002B90C	; tone 0x107  '   Funk Kit     '
	.long 0x0002BF6C	; tone 0x108  '   Dance Kit    '
	.long 0x0002C104	; tone 0x109  '   House Kit    '
	.long 0x0002C29C	; tone 0x10A  '   Soul Kit     '
	.long 0x0002C434	; tone 0x10B  ' Electric Kit   '
	.long 0x0002CA94	; tone 0x10C  '   Synth Kit    '
	.long 0x0002C8FC	; tone 0x10D  ' Modeling Kit   '
	.long 0x0002C5CC	; tone 0x10E  ' Orchestra Kit  '
	.long 0x0002C764	; tone 0x10F  'Sound Effect Kit'
	.long 0x0002CC2C	; tone 0x110  ' Special sound  '
	.long 0x0002CDC4	; tone 0x111  'GM Orchestra Kit'

; ==========================================================================
; ToneDB_OctaveShiftByProgram -- directory slot +0xA8
; file 0x00FC8 .. 0x013C7   (1024 bytes)
; --------------------------------------------------------------------------
; 8 records of 128 bytes.  The period is not assumed: the only non-zero
; bytes sit at record-relative +0x0E, +0x58..+0x5F, +0x7A and +0x7E, and
; they repeat on a 0x80 grid in all 8 records.  Values are 0xF4 (and 0x0C
; at +0x7A in five of the eight).  Everything else is zero.
; 
; ⚠ The KN5000 leaves directory slot +0xA8 UNUSED, so there is no name to
; transplant.  ⚠ CORRECTED IN ROUND 6: this sentence used to end 'and none is
; invented here', and the block was called Unk_0FC8_Table.  The name it now
; carries is not invented and not transplanted either -- it is DERIVED from
; the one prom_c routine that reads the block; see the round-6 section below.
; 
; ★ ROUND 5 adds the two facts that a per-record label could not then carry.
;   (a) THE EIGHT RECORDS ARE ONLY 3 DISTINCT BYTE STRINGS: {0,4,5,6,7}; {1,3}; {2}.
;       A table whose eight rows take three values is not eight independent
;       settings, whatever it is.
;   (b) AND THERE IS NO NAME IN IT TO TAKE: 0 of the 1024 bytes are printable
;       at all, so the round-4 mechanism has nothing to work with here.
;       ⚠ (b) IS STILL TRUE and round 6 does not overturn it: this block is
;       named by its READER, not by its content.  And (a) now has a reading --
;       the three classes differ only at programs 14 and 122, which is what
;       the per-record comments below list.
;   notes/prom_d_understanding_round5.py Q1c.
; 
; Evidence: prom_c reads directory slot +0xA8 at 1 site.  The first is
; 0xFA732D `ld XWA,(0x00D7F1)` -- prom_d's base 0x00F00000 -- followed at
; 0xFA7332 by `ld XIY,(XWA+0xA8)`.  All 1: 0xFA7332.
; Every one re-decoded from prom_c's ROM bytes at the cited address by
; notes/prom_d_documentation_round3.py Q2 (99 reads over 33 slots, 0 that
; fail to decode).  The base is a compile-time constant: the only two
; instructions in prom_c that write 0x00D7ED / 0x00D7F1 are 0xFB0523 and
; 0xFB0528, both storing the 0x00F00000 loaded at 0xFB051E.
; 
; ★ NEW in wave 7 round 3: the 128-byte RECORD SIZE is now prom_c's, not
; just a zero/non-zero column pattern.  The one reader indexes it by 128:
;     0xFA7332  ld XIY,(XWA+0x00a8)  this table's file offset
;     0xFA734A  add XIY,XBC          + a byte fetched from RAM 0x1523
;     0xFA7351  sll 0x07,BC          record index * 128
;     0xFA7356  add XIY,XBC
;     0xFA7358  add XIY,(0x00d7ed)   + base
;     0xFA735D  ld BC,(XIY)          a 16-bit word out of the record
; notes/prom_d_documentation_round3.py Q4f decodes all of it from bytes.
; 
; ⚠ THE THREE LINES ABOVE ARE ROUND 3'S AND ARE NOW SUPERSEDED: they ended
; 'STILL NOT ESTABLISHED: what a record MEANS, what selects one, or what the
; 16-bit word at the computed offset is for.'  Round 6 answers all three, out
; of the SAME routine, by reading what it does with the value and what its
; other arm does instead.
; 
; ★★ THE BLOCK IS AN OCTAVE-SHIFT TABLE, INDEXED [BANK][PROGRAM].
; 
;   * sub_FA72E9 is called from ONE place, Voice_ComputePitch (0xFA7F7A), and
;     both of its arms return a pitch offset in WA.
;   * ITS OTHER ARM reads a 16-entry table at prom_c 0xFDF22A --
;         -96, -84, -72, -60, -48, -36, -24, -12, +0, +12, +24, +36, +48, +60, +72, +84
;     -- with `and C,0x0f` (0xFA7375), `ld A,(XBC)`, `exts WA`, `sll 0x08,WA`.
;     Every entry is a multiple of 12.  It is an OCTAVE SELECT, centred on
;     entry 8 = 0.
;   * THIS ARM produces the value the same way: 0xFA735D `ld BC,(XIY)` then
;     0xFA735F `sll 0x08,BC`.  The shift discards the word's high byte, which
;     is why a byte table can be read with a word instruction -- and why the
;     0xF4 at +0x58..+0x5F reads as -12 eight times over rather than as
;     0xF4F4.  The two shifts are the SAME opcode with a different count:
;     prom_c bytes d9 ee 07 at 0xFA7351 and d9 ee 08 at 0xFA735F.
;   * SO THE VALUES ARE OCTAVES.  This table holds only 0xF4 (-12) and 0x0C
;     (+12), in 84 cells of 1024.
;   * AND THE TWO INDICES ARE A BANK AND A PROGRAM.  0xFA7301 reads directory
;     slot +0x6C -- ToneDB_BankMap -- and turns a byte from the voice's RAM
;     block into a bank ROW; 0xFA7351 `sll 0x07,BC` scales that row by 128,
;     which is this table's record size AND the program map's row width; the
;     within-record byte comes from the ADJACENT byte of the same RAM block
;     (+27 against +28).  A tone index cannot be the second index: it runs
;     0..273 and would address the next bank's record for 146 of 274 tones.
; 
; ★ AND THE MARKED CELLS NAME THEMSELVES, which is what makes the reading
; checkable rather than merely consistent.  The 84 marks fall in only 11
; columns of 128 -- 85 marks placed at random would fill about 62 -- and eight
; of the eleven columns are ONE CONSECUTIVE RUN, programs 88-95, which the
; program map fills with the drawbar/organ family in every one of the 8 banks:
; 
;     prog  14  -12  Digi Bells, Gamelan 1, Gamelan 2, Tubular Bells
;     prog  88  -12  Jazz Organ
;     prog  89  -12  Full Drawbars, Pop Organ
;     prog  90  -12  Pop Organ
;     prog  91  -12  16' & 1'
;     prog  92  -12  Rock Organ
;     prog  93  -12  <<< Drawbar 1>>>, <<< Drawbar 2>>>, Jazz Drawbars
;     prog  94  -12  Sine Lead
;     prog  95  -12  Rock Organ
;     prog 122  +12  Agogo
;     prog 126  -12  Timpani
; 
; Program 122 is the only +12 in the image.  The column structure and the
; values are MEASURED; notes/prom_d_understanding_round6.py Q4 and Q8c, where
; the shift bytes are re-decoded from prom_c's ROM.
; ⚠ That these particular instruments are ones a player expects an octave away
; from written pitch is an INTERPRETATION of the list and is not measured.  It
; is why the list is printed in full rather than summarised: a reader who
; disagrees with it can see exactly what the table marks.
; 
; ⚠ NOT established: the numeric UNIT.  What is measured is that the two arms
; encode identically and that prom_c's arm holds only multiples of 12.  Also
; NOT established: what the RAM byte at voice+27 is set from -- the reading
; 'program number' comes from the record size, the BankMap and the marked
; columns, not from a write to that byte.
; ==========================================================================
ToneDB_OctaveShiftByProgram:

; --- bank 0: the octave shift for each of the 128 programs of ToneNumBank_Melodic_0 ---
; 11 nonzero cells: prog 14 -12 'Tubular Bells'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 'Jazz Drawbars'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 122 +12 'Agogo'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank0:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 00FC8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00FD8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00FE8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 00FF8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01008  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01018  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01028  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01038  |................|

; --- bank 1: the octave shift for each of the 128 programs of ToneNumBank_Melodic_1 ---
; 10 nonzero cells: prog 14 -12 'Tubular Bells'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 'Jazz Drawbars'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank1:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01048  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01058  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01068  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01078  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01088  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01098  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 010A8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 010B8  |................|

; --- bank 2: the octave shift for each of the 128 programs of ToneNumBank_Melodic_2 ---
; 9 nonzero cells: prog 88 -12 'Jazz Organ'; prog 89 -12 'Pop Organ'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 'Jazz Drawbars'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank2:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 010C8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 010D8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 010E8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 010F8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01108  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01118  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01128  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01138  |................|

; --- bank 3: the octave shift for each of the 128 programs of ToneNumBank_Melodic_3 ---
; 10 nonzero cells: prog 14 -12 'Gamelan 1'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 'Jazz Drawbars'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank3:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01148  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01158  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01168  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01178  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01188  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01198  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 011A8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 011B8  |................|

; --- bank 4: the octave shift for each of the 128 programs of ToneNumBank_Melodic_4 ---
; 11 nonzero cells: prog 14 -12 'Tubular Bells'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 'Jazz Drawbars'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 122 +12 'Agogo'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank4:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 011C8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 011D8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 011E8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 011F8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01208  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01218  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01228  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01238  |................|

; --- bank 5: the octave shift for each of the 128 programs of ToneNumBank_Melodic_5 ---
; 11 nonzero cells: prog 14 -12 'Tubular Bells'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 'Jazz Drawbars'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 122 +12 'Agogo'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank5:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01248  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01258  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01268  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01278  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01288  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01298  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 012A8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0xF4, 0x00	; 012B8  |................|

; --- bank 6: the octave shift for each of the 128 programs of ToneNumBank_Melodic_6 ---
; 11 nonzero cells: prog 14 -12 'Digi Bells'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 '<<< Drawbar 2>>>'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 122 +12 'Agogo'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank6:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 012C8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 012D8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 012E8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 012F8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01308  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01318  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01328  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01338  |................|

; --- bank 7: the octave shift for each of the 128 programs of ToneNumBank_Melodic_7 ---
; 11 nonzero cells: prog 14 -12 'Gamelan 2'; prog 88 -12 'Jazz Organ'; prog 89 -12 'Full Drawbars'; prog 90 -12 'Pop Organ'; prog 91 -12 "16' & 1'"; prog 92 -12 'Rock Organ'; prog 93 -12 '<<< Drawbar 1>>>'; prog 94 -12 'Sine Lead'; prog 95 -12 'Rock Organ'; prog 122 +12 'Agogo'; prog 126 -12 'Timpani'
ToneDB_OctaveShiftByProgram_Bank7:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0x00	; 01348  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01358  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01368  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01378  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 01388  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4, 0xF4	; 01398  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 013A8  |................|
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0xF4, 0x00	; 013B8  |................|
