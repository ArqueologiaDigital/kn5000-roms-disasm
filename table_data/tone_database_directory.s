; =============================================================================
; TONE DATABASE -- Directory, Program Maps and Tone-Record Offset Table
; =============================================================================
; ROM range 0x830000-0x8324D3.  This is the head of the tone/voice database
; that the Main CPU ships to the Sub CPU at boot: SubCPU_Send_Payload
; (maincpu) copies ROM 0x830000-0x87FFFF into Sub-CPU work RAM 0x050000-
; 0x09FFFF as five 64KB InterCPU E1 bulk transfers.  DSP_System_Init (subcpu)
; then stores the RAM base 0x050000 at ToneDB_RelBase (0x045310) and
; ToneDB_RootPtr (0x045314).  ALL offsets inside the database are relative to
; ToneDB_Base, so every value here is equally valid as a Sub-CPU address
; (0x050000 + offset) -- keep this aliasing in mind when reading the subcpu
; disassembly, which never sees the 0x83xxxx addresses.
;
; The Sub CPU addresses the database exclusively through the directory below:
; a table of 4-byte little-endian entries at ToneDB_Base, each entry either a
; database-relative offset, a scalar parameter, or 0xFFFFFFFF/0 (unused).
; Subcpu code reads a slot as (ToneDB_RootPtr)[slot offset] and adds
; ToneDB_RelBase.
;
; DATABASE LAYOUT (this module covers the first three regions):
;   0x830000  ToneDB_Directory        4-byte slots, consumers noted per line
;   0x830100  ToneDB_BankMap_Main     bank-select byte map (128 entries)
;   0x830180  ToneDB_ToneNumBanks_Main 11 banks x 128 LE16 tone numbers
;   0x830C80  ToneDB_BankMap_Coeff    bank-select byte map (128 entries)
;   0x830D00  ToneDB_ToneNumBanks_Coeff 14 banks x 128 LE16 tone numbers
;   0x831B00  ToneDB_ToneOffsetTable  629 LE32 offsets -> tone records
;   0x8324D4  tone/voice records (ToneRec_000...), variable length, 16-char
;             space-padded name first; drum-kit and drawbar records plus all
;             auxiliary wave/coefficient tables follow at 0x8558AE+ (see the
;             per-slot comments; those labels are defined with the aux data).
;
; TONE LOOKUP (ToneDB_Find_PatchRecord, subcpu): the caller presents a bank
; selector (high byte) and a program number (low 7 bits).  The bank selector
; indexes ToneDB_BankMap_Main to fetch a bank byte b; bank bytes 0x10, 0x15,
; 0x50, 0x55 divert to RAM-resident user/edit banks, otherwise tone number =
; u16[ToneDB_ToneNumBanks_Main + (b*128 + program)*2].  The tone number then
; indexes ToneDB_ToneOffsetTable; record = ToneDB_Base + entry.
; ToneDB_Find_ToneRecord_CoeffPath performs the same walk through
; ToneDB_BankMap_Coeff (slot +0x6C) with no bank-validity filter.
;
; SET LOOKUP (WaveSel_StageA2_FindSetDesc, subcpu 0x032750): a multisample SET
; is selected by two bytes, passed in C and A.  [INFERENCE] nothing in the ROM
; names them; C behaves as a family/sub-bank selector and A as a wave index.
; family = C & 0xC0 picks the slot pair; sub = C & 0x0F and wave = A & 0x7F
; form the index:
;   set number = u16[ dir[+0x24|+0x28|+0x2C] + 2*((sub << 7) | wave) ]
;     family 0x00/0xC0 -> +0x24 ToneIndexMapC, family 0x80 -> +0x28
;     ToneIndexMapD, family 0x40 -> +0x2C DrumToneIndexMap
;   descriptor = ToneDB_Base + dir[+0x30|+0x34|+0x38]
;                + set * dir_u16[+0xEC|+0xF2]   (both stride words = 15)
; Bit 2 of the global mode word 0x041343 substitutes slots +0x9C/+0xA0/+0xA4
; for the three index tables; they hold the same three offsets in this ROM, so
; that path is a no-op here.  All three descriptor slots hold one offset and
; both stride words are 15, so the three families share a single 487-record
; block -- ToneDB_EnvDescTable, documented in the aux-tables module.
;
; DSP1 STREAM BIAS (slot +0x88) -- verified against DSP1_ResolveStreamPtr in
; the subcpu disassembly: the routine loads XBC from (base + 0x88) -- the
; dword 338 below -- adds BC to the caller's stream index WA, fetches the
; dword at base + (word at base+0x08) + 4*index, i.e. this module's
; ToneDB_ToneOffsetTable[index + 338], and returns XHL = base + entry.  So
; "stream" indices used by DSP_Reinit_VoiceSlots (its only 3 call sites) are
; biased past the first 338 entries: the region starting at ToneRec_338 holds
; the records that DSP1 streams are resolved from.  Consistently, the
; ToneNumBanks_Main tables only hold tone numbers 0-337 while the
; ToneNumBanks_Coeff tables hold 311-628.
; =============================================================================

ToneDB_Base:
ToneDB_Directory:
	.long 0xFFFFFFFF						; slot +0x00: unused
	.long ToneDB_BankMap_Main - ToneDB_Base				; slot +0x04: bank map + tone-number banks (preset lookup path)
	.long ToneDB_ToneOffsetTable - ToneDB_Base			; slot +0x08: tone-record offset table (629 entries)
	.long ToneDB_ToneIndexMapA - ToneDB_Base			; slot +0x0C: WaveSel_StageA1 index table, SET families 0x00/0xC0
	.long ToneDB_ToneIndexMapB - ToneDB_Base			; slot +0x10: WaveSel_StageA1 index table, family 0x80
	.long ToneDB_PercSourceIndexMapA - ToneDB_Base			; slot +0x14: WaveSel_StageA1 index table, family 0x40
	.long ToneDB_MixerDefaultTable - ToneDB_Base			; slot +0x18: wave-select records, families 0x00/0xC0 (stride = word +0xEA)
	.long ToneDB_MixerDefaultTable - ToneDB_Base			; slot +0x1C: family 0x80 shares the family-0x00 records
	.long ToneDB_PercMixerDefaultTable - ToneDB_Base		; slot +0x20: wave-select records, family 0x40 (stride = word +0xF0)
	.long ToneDB_ToneIndexMapC - ToneDB_Base			; slot +0x24: WaveSel_StageA2 index table, families 0x00/0xC0
	.long ToneDB_ToneIndexMapD - ToneDB_Base			; slot +0x28: WaveSel_StageA2 index table, family 0x80
	.long ToneDB_DrumToneIndexMap - ToneDB_Base			; slot +0x2C: WaveSel_StageA2 index table, family 0x40
	.long ToneDB_EnvDescTable - ToneDB_Base				; slot +0x30: wave-set descriptors, families 0x00/0xC0 (stride = word +0xEC)
	.long ToneDB_EnvDescTable - ToneDB_Base				; slot +0x34: family 0x80 (same descriptor block)
	.long ToneDB_EnvDescTable - ToneDB_Base				; slot +0x38: family 0x40 (same block, stride = word +0xF2)
	.long 0xFFFFFFFF						; slot +0x3C: unused
	.long 0xFFFFFFFF						; slot +0x40: unused
	.long ToneDB_SourceIndexMapA - ToneDB_Base			; slot +0x44: DSP_RouteCoeffs_TypeA row-index table, selectors 00/11
	.long ToneDB_SourceIndexMapB - ToneDB_Base			; slot +0x48: DSP_RouteCoeffs_TypeA row-index table, selector 10
	.long ToneDB_PercSourceIndexMapB - ToneDB_Base			; slot +0x4C: DSP_RouteCoeffs_TypeA row-index table, selector 01
	.long ToneDB_SourceNameList1 - ToneDB_Base			; slot +0x50: wave catalogue A, 16-byte named rows ("Piano L", ...)
	.long ToneDB_SourceList1_Footer - ToneDB_Base			; slot +0x54: DSP_AlgoCoeffLookup bank 0/default (self-sized block)
	.long ToneDB_SourceIndexMapC - ToneDB_Base			; slot +0x58: DSP_VoiceCoeffRoute2 row-index table, selectors 00/11
	.long ToneDB_SourceIndexMapD - ToneDB_Base			; slot +0x5C: DSP_VoiceCoeffRoute2 row-index table, selector 10
	.long ToneDB_PercSourceIndexMapC - ToneDB_Base			; slot +0x60: DSP_VoiceCoeffRoute2 row-index table, selector 01
	.long ToneDB_SourceNameList2 - ToneDB_Base			; slot +0x64: wave catalogue B, 16-byte named rows
	.long ToneDB_SourceList2_Footer - ToneDB_Base			; slot +0x68: DSP_AlgoCoeffLookup bank 1
	.long ToneDB_BankMap_Coeff - ToneDB_Base			; slot +0x6C: coefficient-path bank map (sole consumer: ToneDB_Find_ToneRecord_CoeffPath)
	.long DrawbarPreset_EnvDescTable - ToneDB_Base			; slot +0x70: alternate 15-byte descriptor records (stride = word +0xEC)
	.long DrumKit_NoteMapA - ToneDB_Base				; slot +0x74: drum-instrument index table (ToneDB_Resolve_NamedToneRecord)
	.long PercInst_000_Silent - ToneDB_Base				; slot +0x78: drum-instrument records, 13-char name + params (stride = word +0xEE)
	.long DrumKit_NoteMapB - ToneDB_Base				; slot +0x7C: DSP_RouteCoeffs four-way row-index table (all selectors)
	.long ToneDB_DrumSourceNameList - ToneDB_Base			; slot +0x80: wave catalogue C, 16-byte named rows (custom-tone loader)
	.long ToneDB_DrumList_Footer - ToneDB_Base			; slot +0x84: DSP_AlgoCoeffLookup bank 2
	.long 338							; slot +0x88: DSP1 stream-index bias -- see header (DSP1_ResolveStreamPtr)
	.long ToneDB_PercSourceNameList1 - ToneDB_Base			; slot +0x8C: sub-unit wave catalogue (VoiceParam_CustomTone_Apply_Catalog8C)
	.long ToneDB_PercList1_Footer - ToneDB_Base			; slot +0x90: DSP_AlgoCoeffLookup bank 3
	.long ToneDB_PercSourceNameList2 - ToneDB_Base			; slot +0x94: pair-mode wave catalogue (VoiceParam_CustomTone_Apply_Catalog94)
	.long ToneDB_PercList2_Footer - ToneDB_Base			; slot +0x98: DSP_AlgoCoeffLookup bank 4
	.long ToneDB_ToneIndexMapC - ToneDB_Base			; slot +0x9C: StageA2 alt-mode alias (ToneGen_GlobalFlags bit 2), fam 0x00/0xC0
	.long ToneDB_ToneIndexMapD - ToneDB_Base			; slot +0xA0: StageA2 alt-mode alias, family 0x80
	.long ToneDB_DrumToneIndexMap - ToneDB_Base			; slot +0xA4: StageA2 alt-mode alias, family 0x40
	.long 0xFFFFFFFF						; slot +0xA8: unused
	.long ToneDB_DefaultLayerParams - ToneDB_Base			; slot +0xAC: fallback descriptor bound when a patch partial is absent (EFF slot scan)
	.long PercName_Pack - ToneDB_Base				; slot +0xB0: packed 10-char percussion-source names (stride 10, no terminators)
	.long 0xFFFFFFFF						; slot +0xB4: unused
	.long 0xFFFFFFFF						; slot +0xB8: unused
	.long 0xFFFFFFFF						; slot +0xBC: unused

; Directory tail: scalar parameters (read as 16-bit words by the subcpu).
; The four stride/length words +0xEA/+0xEC/+0xEE/+0xF0 (and +0xF2) size the
; records behind the pointer slots above; word offsets not listed in a
; comment have no reader in the v1.42 subcpu image.
	.long 0, 0, 0, 0						; +0xC0..+0xCF: unused (zero)
	.short 3							; +0xD0: unread in v1.42
	.short 0
	.short 3							; +0xD4: unread in v1.42
	.short 2
	.short 3							; +0xD8: unread in v1.42
	.short 2
	.short 0, 0
	.short 28							; +0xE0: unread in v1.42
	.short 0, 0, 0
	.short 426							; +0xE8: unread in v1.42
	.short 11							; +0xEA: wave-select record stride/copy length, families 0x00/0x80/0xC0
	.short 15							; +0xEC: set-descriptor stride, families 0x00/0x80/0xC0 (also SetDescRecs_Alt)
	.short 58							; +0xEE: drum-instrument record stride/copy length
	.short 11							; +0xF0: wave-select record stride/copy length, family 0x40
	.short 15							; +0xF2: set-descriptor stride, family 0x40
	.short 0, 0, 0, 0, 0, 0

; =============================================================================
; BANK-SELECT MAPS AND TONE-NUMBER BANKS
; =============================================================================
; A bank map is 128 bytes indexed by the bank selector byte of a tone lookup;
; the fetched value picks one 128-entry tone-number bank below (values 0x10/
; 0x15/0x50/0x55 would divert to RAM edit buffers -- none occur in this ROM).
; Tone numbers index ToneDB_ToneOffsetTable.
; =============================================================================
ToneDB_BankMap_Main:
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x00-0x0F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x10-0x1F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x20-0x2F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x30-0x3F
	.byte 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x40-0x4F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x50-0x5F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x60-0x6F
	.byte 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x70-0x7F

; 11 banks x 128 LE16 tone numbers for the preset lookup path (slot +0x04).
; Only tone numbers 0-337 appear here (the un-biased half of the offset
; table).  Unassigned program slots repeat a default tone of the bank.
ToneDB_ToneNumBanks_Main:
; Bank 0: selector(s) 0x00 (and every selector the map leaves at 0); tone numbers 0-289.
ToneDB_ToneNumBank_Main00:
	.short 0, 1, 2, 7, 15, 9, 14, 32
	.short 21, 20, 23, 24, 25, 29, 26, 69
	.short 16, 18, 17, 16, 40, 42, 45, 46
	.short 49, 48, 50, 245, 51, 54, 56, 62
	.short 33, 60, 77, 61, 65, 64, 68, 66
	.short 212, 219, 217, 210, 212, 228, 224, 218
	.short 157, 157, 160, 162, 163, 164, 166, 247
	.short 150, 151, 169, 154, 155, 155, 155, 156
	.short 190, 191, 185, 186, 180, 183, 187, 180
	.short 196, 248, 199, 203, 170, 171, 175, 176
	.short 145, 146, 147, 188, 140, 139, 246, 142
	.short 130, 131, 135, 133, 137, 132, 252, 252
	.short 95, 99, 100, 92, 82, 88, 89, 93
	.short 102, 105, 289, 106, 280, 108, 105, 202
	.short 253, 30, 19, 19, 15, 250, 251, 263
	.short 275, 250, 230, 240, 234, 38, 37, 34
; Bank 1: selector(s) 0x01; tone numbers 3-288.
ToneDB_ToneNumBank_Main01:
	.short 3, 6, 4, 7, 15, 9, 14, 32
	.short 21, 20, 23, 31, 25, 29, 28, 69
	.short 16, 18, 17, 16, 41, 42, 45, 46
	.short 49, 48, 52, 245, 51, 54, 56, 58
	.short 33, 60, 77, 61, 65, 64, 74, 67
	.short 213, 220, 223, 211, 212, 228, 222, 218
	.short 157, 157, 161, 162, 163, 164, 167, 168
	.short 153, 151, 169, 154, 155, 155, 155, 156
	.short 193, 192, 185, 186, 182, 184, 187, 180
	.short 197, 249, 200, 204, 170, 172, 175, 177
	.short 148, 146, 110, 189, 140, 139, 246, 142
	.short 130, 131, 135, 133, 137, 132, 138, 252
	.short 96, 99, 90, 92, 82, 88, 89, 94
	.short 102, 105, 107, 270, 280, 108, 105, 202
	.short 253, 30, 19, 19, 15, 250, 251, 288
	.short 274, 250, 231, 241, 236, 38, 39, 34
; Bank 2: selector(s) 0x02; tone numbers 1-285.
ToneDB_ToneNumBank_Main02:
	.short 8, 1, 2, 5, 11, 10, 14, 15
	.short 21, 269, 23, 24, 25, 29, 244, 69
	.short 16, 18, 17, 16, 40, 42, 45, 46
	.short 49, 47, 50, 57, 53, 54, 56, 62
	.short 33, 60, 77, 61, 65, 64, 75, 66
	.short 216, 219, 217, 210, 212, 228, 264, 226
	.short 159, 157, 160, 162, 163, 164, 166, 247
	.short 153, 151, 169, 154, 155, 155, 282, 156
	.short 190, 191, 185, 186, 181, 183, 187, 180
	.short 201, 205, 199, 203, 170, 171, 178, 179
	.short 120, 146, 111, 188, 140, 139, 246, 142
	.short 130, 136, 135, 134, 137, 132, 252, 252
	.short 97, 98, 100, 92, 91, 88, 285, 93
	.short 104, 105, 273, 272, 280, 109, 105, 208
	.short 206, 30, 19, 19, 279, 253, 261, 263
	.short 275, 250, 233, 243, 237, 239, 37, 34
; Bank 3: selector(s) 0x03; tone numbers 2-303.
ToneDB_ToneNumBank_Main03:
	.short 4, 6, 2, 7, 15, 9, 15, 32
	.short 21, 20, 23, 24, 25, 29, 70, 69
	.short 16, 18, 17, 16, 40, 276, 45, 46
	.short 49, 48, 50, 254, 51, 55, 56, 59
	.short 33, 60, 77, 61, 65, 64, 76, 66
	.short 215, 219, 217, 210, 212, 228, 224, 225
	.short 157, 157, 160, 162, 165, 164, 166, 247
	.short 152, 151, 169, 154, 155, 155, 155, 156
	.short 194, 191, 185, 186, 180, 183, 187, 180
	.short 198, 248, 199, 203, 170, 171, 173, 173
	.short 121, 146, 112, 188, 140, 139, 246, 143
	.short 130, 131, 135, 133, 137, 132, 252, 252
	.short 95, 99, 100, 303, 80, 88, 290, 93
	.short 101, 105, 284, 283, 281, 108, 105, 202
	.short 198, 30, 19, 19, 277, 250, 251, 263
	.short 275, 287, 235, 232, 238, 242, 37, 34
; Bank 4: selector(s) 0x04; tone numbers 1-302.
ToneDB_ToneNumBank_Main04:
	.short 8, 1, 2, 7, 12, 9, 14, 32
	.short 22, 20, 23, 24, 25, 70, 27, 69
	.short 16, 18, 295, 16, 43, 42, 45, 46
	.short 49, 48, 50, 44, 51, 54, 56, 63
	.short 266, 60, 77, 78, 65, 64, 68, 66
	.short 214, 219, 217, 210, 212, 228, 224, 229
	.short 158, 157, 160, 162, 163, 164, 166, 247
	.short 150, 151, 169, 154, 260, 257, 286, 156
	.short 190, 209, 185, 186, 180, 183, 187, 180
	.short 207, 248, 199, 195, 170, 171, 174, 176
	.short 122, 128, 149, 126, 140, 139, 141, 144
	.short 130, 131, 135, 133, 137, 132, 252, 252
	.short 95, 99, 100, 293, 83, 81, 84, 300
	.short 103, 298, 289, 106, 302, 108, 105, 202
	.short 253, 30, 19, 19, 15, 250, 251, 263
	.short 275, 250, 230, 79, 234, 38, 37, 35
; Bank 5: selector(s) 0x05; tone numbers 1-307.
ToneDB_ToneNumBank_Main05:
	.short 292, 1, 2, 7, 13, 9, 14, 32
	.short 21, 20, 23, 267, 25, 71, 26, 69
	.short 16, 18, 17, 16, 40, 42, 45, 46
	.short 49, 48, 50, 245, 51, 54, 56, 62
	.short 33, 60, 77, 61, 65, 64, 68, 66
	.short 212, 219, 217, 210, 212, 228, 227, 221
	.short 157, 157, 160, 162, 163, 164, 299, 247
	.short 150, 151, 169, 154, 265, 155, 271, 156
	.short 190, 191, 185, 186, 180, 183, 187, 180
	.short 196, 248, 199, 195, 170, 171, 175, 176
	.short 123, 129, 113, 127, 140, 139, 296, 144
	.short 130, 131, 135, 133, 137, 132, 252, 252
	.short 95, 99, 100, 92, 297, 307, 85, 93
	.short 102, 105, 259, 106, 280, 108, 105, 202
	.short 253, 30, 19, 19, 15, 256, 251, 263
	.short 275, 258, 230, 240, 234, 38, 37, 36
; Bank 6: selector(s) 0x06; tone numbers 0-309.
ToneDB_ToneNumBank_Main06:
	.short 0, 1, 2, 7, 15, 9, 14, 32
	.short 21, 20, 23, 24, 25, 72, 268, 69
	.short 16, 18, 17, 16, 40, 42, 45, 46
	.short 49, 48, 50, 245, 51, 54, 56, 62
	.short 33, 60, 77, 61, 65, 64, 68, 66
	.short 212, 219, 217, 210, 212, 228, 227, 218
	.short 157, 157, 160, 162, 163, 164, 308, 247
	.short 150, 151, 169, 154, 155, 280, 278, 156
	.short 190, 191, 185, 186, 309, 183, 187, 180
	.short 196, 248, 199, 203, 170, 171, 175, 176
	.short 124, 118, 114, 116, 140, 139, 246, 142
	.short 130, 131, 135, 133, 137, 132, 252, 252
	.short 95, 99, 100, 92, 291, 305, 86, 93
	.short 102, 105, 271, 294, 280, 108, 105, 202
	.short 253, 30, 19, 255, 257, 250, 251, 263
	.short 275, 250, 230, 240, 234, 38, 37, 34
; Bank 7: selector(s) 0x07; tone numbers 0-306.
ToneDB_ToneNumBank_Main07:
	.short 0, 1, 2, 7, 15, 9, 14, 32
	.short 21, 20, 23, 24, 25, 73, 70, 69
	.short 16, 18, 17, 16, 40, 42, 45, 46
	.short 49, 48, 50, 245, 51, 54, 56, 62
	.short 33, 60, 77, 61, 65, 64, 68, 66
	.short 212, 219, 217, 210, 212, 228, 224, 218
	.short 157, 157, 160, 162, 163, 164, 166, 247
	.short 150, 151, 169, 154, 262, 93, 301, 156
	.short 190, 191, 185, 186, 180, 183, 187, 180
	.short 196, 248, 199, 203, 170, 171, 175, 176
	.short 125, 119, 115, 117, 140, 139, 246, 142
	.short 130, 131, 135, 133, 137, 132, 252, 252
	.short 95, 99, 100, 92, 306, 88, 87, 304
	.short 102, 105, 289, 106, 280, 108, 105, 202
	.short 253, 30, 19, 19, 15, 250, 251, 263
	.short 275, 250, 230, 240, 234, 38, 37, 34
; Bank 8: selector(s) 0x40; tone numbers 0-332.
ToneDB_ToneNumBank_Main08:
	.short 315, 310, 327, 318, 329, 312, 314, 321
	.short 323, 326, 324, 325, 330, 332, 320, 315
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
; Bank 9: selector(s) 0x41; tone numbers 0-335.
ToneDB_ToneNumBank_Main09:
	.short 316, 319, 322, 328, 317, 311, 313, 331
	.short 333, 326, 324, 325, 330, 332, 320, 334
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 0
	.short 0, 0, 0, 0, 0, 0, 0, 335
; Bank 10: selector(s) 0x70; tone numbers 336-337.
ToneDB_ToneNumBank_Main10:
	.short 336, 337, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336
	.short 336, 336, 336, 336, 336, 336, 336, 336

ToneDB_BankMap_Coeff:
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0	; selectors 0x00-0x0F
	.byte 10, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0	; selectors 0x10-0x1F
	.byte 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x20-0x2F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x30-0x3F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x40-0x4F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x50-0x5F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	; selectors 0x60-0x6F
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 13, 0, 0, 0, 0, 0, 0, 0	; selectors 0x70-0x7F

; 14 banks x 128 LE16 tone numbers for the unfiltered coefficient path
; (slot +0x6C).  Only tone numbers 311-628 appear here -- the drum kits,
; drawbar records and the DSP1 stream region of the offset table.
ToneDB_ToneNumBanks_Coeff:
; Bank 0: selector(s) 0x00 (and every selector the map leaves at 0); tone numbers 400-625.
ToneDB_ToneNumBank_Coeff00:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 593, 599, 603, 609, 619, 625
; Bank 1: selector(s) 0x01; tone numbers 400-626.
ToneDB_ToneNumBank_Coeff01:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 475, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 502, 503, 504, 506, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 535, 538, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 557, 558, 559, 560, 562, 564
	.short 566, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 589, 592, 594, 600, 604, 610, 620, 626
; Bank 2: selector(s) 0x02; tone numbers 400-627.
ToneDB_ToneNumBank_Coeff02:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 563, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 590, 591, 595, 601, 605, 611, 621, 627
; Bank 3: selector(s) 0x03; tone numbers 400-628.
ToneDB_ToneNumBank_Coeff03:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 596, 602, 606, 612, 622, 628
; Bank 4: selector(s) 0x04; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff04:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 597, 599, 607, 613, 623, 625
; Bank 5: selector(s) 0x05; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff05:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 598, 599, 608, 614, 624, 625
; Bank 6: selector(s) 0x06; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff06:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 593, 599, 603, 615, 619, 625
; Bank 7: selector(s) 0x07; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff07:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 593, 599, 603, 616, 619, 625
; Bank 8: selector(s) 0x08; tone numbers 401-625.
ToneDB_ToneNumBank_Coeff08:
	.short 401, 404, 406, 408, 410, 414, 417, 420
	.short 421, 422, 423, 425, 427, 428, 430, 432
	.short 434, 438, 440, 442, 444, 446, 447, 448
	.short 450, 454, 457, 459, 461, 463, 465, 467
	.short 468, 469, 470, 471, 472, 473, 476, 478
	.short 481, 482, 483, 484, 485, 486, 487, 488
	.short 490, 491, 493, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 508, 510, 513
	.short 515, 517, 519, 520, 521, 522, 523, 525
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 536, 539, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 570, 571, 572, 573, 574
	.short 575, 576, 577, 579, 581, 583, 585, 587
	.short 588, 591, 593, 599, 603, 617, 619, 625
; Bank 9: selector(s) 0x09; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff09:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 431, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 586, 587
	.short 588, 591, 593, 599, 603, 618, 619, 625
; Bank 10: selector(s) 0x10; tone numbers 402-625.
ToneDB_ToneNumBank_Coeff10:
	.short 402, 403, 405, 407, 411, 415, 418, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 435, 437, 440, 443, 444, 445, 447, 448
	.short 451, 455, 456, 458, 462, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 479
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 511, 514
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 593, 599, 603, 609, 619, 625
; Bank 11: selector(s) 0x18; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff11:
	.short 400, 403, 405, 407, 412, 413, 419, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 433, 437, 440, 441, 444, 445, 447, 448
	.short 449, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 495, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 593, 599, 603, 609, 619, 625
; Bank 12: selector(s) 0x20; tone numbers 400-625.
ToneDB_ToneNumBank_Coeff12:
	.short 400, 403, 405, 407, 409, 413, 416, 420
	.short 421, 422, 423, 424, 426, 428, 429, 432
	.short 436, 439, 440, 441, 444, 445, 447, 448
	.short 452, 453, 456, 458, 460, 463, 464, 466
	.short 468, 469, 470, 471, 472, 473, 474, 477
	.short 480, 482, 483, 484, 485, 486, 487, 488
	.short 489, 491, 492, 494, 496, 497, 498, 499
	.short 500, 501, 503, 504, 505, 507, 509, 512
	.short 515, 516, 518, 520, 521, 522, 523, 524
	.short 526, 527, 528, 529, 530, 531, 532, 533
	.short 534, 537, 540, 541, 542, 543, 544, 545
	.short 546, 547, 548, 549, 550, 551, 552, 553
	.short 554, 555, 556, 558, 559, 560, 561, 564
	.short 565, 567, 568, 569, 571, 572, 573, 574
	.short 575, 576, 577, 578, 580, 582, 584, 587
	.short 588, 591, 593, 599, 603, 609, 619, 625
; Bank 13: selector(s) 0x78; tone numbers 311-333.
ToneDB_ToneNumBank_Coeff13:
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 319, 319, 319, 319, 319, 319, 319, 319
	.short 322, 322, 322, 322, 322, 322, 322, 322
	.short 328, 317, 328, 328, 328, 328, 328, 328
	.short 311, 311, 311, 311, 311, 311, 311, 311
	.short 313, 313, 313, 313, 313, 313, 313, 313
	.short 331, 331, 331, 331, 331, 331, 331, 331
	.short 333, 333, 333, 333, 333, 333, 333, 333
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316
	.short 316, 316, 316, 316, 316, 316, 316, 316

; =============================================================================
; TONE-RECORD OFFSET TABLE -- 629 LE32 database-relative offsets
; =============================================================================
; Entry n is the offset of tone record ToneRec_n from ToneDB_Base.  Records
; carry a 16-char space-padded name first; the name is quoted per entry.
; Entries 310-335 are the 26 drum-kit records and 336/337 the two drawbar
; records; those live past the plain tone records, among the aux tables.
; Entries 378-399 are unused slots aliasing entry 0.  Entries 338 and up form
; the DSP1 stream region (see the bias note in the module header).
; =============================================================================
ToneDB_ToneOffsetTable:
	.long ToneRec_000 - ToneDB_Base	; 0: "Piano"
	.long ToneRec_001 - ToneDB_Base	; 1: "Bright Piano"
	.long ToneRec_002 - ToneDB_Base	; 2: "Mellow Piano"
	.long ToneRec_003 - ToneDB_Base	; 3: "Piano 1 Octave"
	.long ToneRec_004 - ToneDB_Base	; 4: "Piano 2 Octave"
	.long ToneRec_005 - ToneDB_Base	; 5: "Rock Piano"
	.long ToneRec_006 - ToneDB_Base	; 6: "Honky-Tonk Piano"
	.long ToneRec_007 - ToneDB_Base	; 7: "Electric Grand"
	.long ToneRec_008 - ToneDB_Base	; 8: "Midi Grand"
	.long ToneRec_009 - ToneDB_Base	; 9: "E.Piano 1"
	.long ToneRec_010 - ToneDB_Base	; 10: "E.Piano 2"
	.long ToneRec_011 - ToneDB_Base	; 11: "Suitcase E.P."
	.long ToneRec_012 - ToneDB_Base	; 12: "Tremolo E.Piano"
	.long ToneRec_013 - ToneDB_Base	; 13: "Wurly E.Piano"
	.long ToneRec_014 - ToneDB_Base	; 14: "Modern E.P.1"
	.long ToneRec_015 - ToneDB_Base	; 15: "Modern E.P.2"
	.long ToneRec_016 - ToneDB_Base	; 16: "Harpsichord"
	.long ToneRec_017 - ToneDB_Base	; 17: "Cembalo"
	.long ToneRec_018 - ToneDB_Base	; 18: "Clavi"
	.long ToneRec_019 - ToneDB_Base	; 19: "Synth Clavi"
	.long ToneRec_020 - ToneDB_Base	; 20: "Glockenspiel"
	.long ToneRec_021 - ToneDB_Base	; 21: "Vibraphone"
	.long ToneRec_022 - ToneDB_Base	; 22: "Vibes&JazzGuitar"
	.long ToneRec_023 - ToneDB_Base	; 23: "Marimba"
	.long ToneRec_024 - ToneDB_Base	; 24: "Xylophone"
	.long ToneRec_025 - ToneDB_Base	; 25: "Celesta"
	.long ToneRec_026 - ToneDB_Base	; 26: "Tubular Bells"
	.long ToneRec_027 - ToneDB_Base	; 27: "Carillon"
	.long ToneRec_028 - ToneDB_Base	; 28: "Wind Chime"
	.long ToneRec_029 - ToneDB_Base	; 29: "Bottle Marimba"
	.long ToneRec_030 - ToneDB_Base	; 30: "African Mallet"
	.long ToneRec_031 - ToneDB_Base	; 31: "Caribbean Mallet"
	.long ToneRec_032 - ToneDB_Base	; 32: "Music Box"
	.long ToneRec_033 - ToneDB_Base	; 33: "Harp"
	.long ToneRec_034 - ToneDB_Base	; 34: "Orchestra Hit"
	.long ToneRec_035 - ToneDB_Base	; 35: "Dance Hit 1"
	.long ToneRec_036 - ToneDB_Base	; 36: "Dance Hit 2"
	.long ToneRec_037 - ToneDB_Base	; 37: "Timpani"
	.long ToneRec_038 - ToneDB_Base	; 38: "Sleigh Bell"
	.long ToneRec_039 - ToneDB_Base	; 39: "Gong"
	.long ToneRec_040 - ToneDB_Base	; 40: "Classical Guitar"
	.long ToneRec_041 - ToneDB_Base	; 41: "Spanish Guitar"
	.long ToneRec_042 - ToneDB_Base	; 42: "Jazz Ac.Guitar"
	.long ToneRec_043 - ToneDB_Base	; 43: "Bossa Guitar"
	.long ToneRec_044 - ToneDB_Base	; 44: "Guitar Harmonics"
	.long ToneRec_045 - ToneDB_Base	; 45: "Folk Guitar"
	.long ToneRec_046 - ToneDB_Base	; 46: "12 String Guitar"
	.long ToneRec_047 - ToneDB_Base	; 47: "ElectroAc.Guitar"
	.long ToneRec_048 - ToneDB_Base	; 48: "Jazz Guitar 1"
	.long ToneRec_049 - ToneDB_Base	; 49: "Jazz Guitar 2"
	.long ToneRec_050 - ToneDB_Base	; 50: "Bright Solid Gtr"
	.long ToneRec_051 - ToneDB_Base	; 51: "Mellow Solid Gtr"
	.long ToneRec_052 - ToneDB_Base	; 52: "Clean Solid Gtr"
	.long ToneRec_053 - ToneDB_Base	; 53: "Fusion Solid Gtr"
	.long ToneRec_054 - ToneDB_Base	; 54: "Mute Guitar"
	.long ToneRec_055 - ToneDB_Base	; 55: "Funk Mute Guitar"
	.long ToneRec_056 - ToneDB_Base	; 56: "Distortion Gtr"
	.long ToneRec_057 - ToneDB_Base	; 57: "Overdrive Guitar"
	.long ToneRec_058 - ToneDB_Base	; 58: "Country Guitar"
	.long ToneRec_059 - ToneDB_Base	; 59: "Nashville Steel"
	.long ToneRec_060 - ToneDB_Base	; 60: "Banjo"
	.long ToneRec_061 - ToneDB_Base	; 61: "Mandolin"
	.long ToneRec_062 - ToneDB_Base	; 62: "Hawaiian Guitar1"
	.long ToneRec_063 - ToneDB_Base	; 63: "Hawaiian Guitar2"
	.long ToneRec_064 - ToneDB_Base	; 64: "Koto"
	.long ToneRec_065 - ToneDB_Base	; 65: "Shamisen"
	.long ToneRec_066 - ToneDB_Base	; 66: "Kalimba"
	.long ToneRec_067 - ToneDB_Base	; 67: "Metal Kalimba"
	.long ToneRec_068 - ToneDB_Base	; 68: "Sitar"
	.long ToneRec_069 - ToneDB_Base	; 69: "Steel Drum"
	.long ToneRec_070 - ToneDB_Base	; 70: "Bonang"
	.long ToneRec_071 - ToneDB_Base	; 71: "Sarrons"
	.long ToneRec_072 - ToneDB_Base	; 72: "Kenong"
	.long ToneRec_073 - ToneDB_Base	; 73: "Slentem"
	.long ToneRec_074 - ToneDB_Base	; 74: "Dulcimer"
	.long ToneRec_075 - ToneDB_Base	; 75: "Kanun"
	.long ToneRec_076 - ToneDB_Base	; 76: "Cumbus"
	.long ToneRec_077 - ToneDB_Base	; 77: "Ukulele"
	.long ToneRec_078 - ToneDB_Base	; 78: "Bouzouki"
	.long ToneRec_079 - ToneDB_Base	; 79: "Talking Drum"
	.long ToneRec_080 - ToneDB_Base	; 80: "SymphonicStrings"
	.long ToneRec_081 - ToneDB_Base	; 81: "Concert Strings"
	.long ToneRec_082 - ToneDB_Base	; 82: "ClassicalStrings"
	.long ToneRec_083 - ToneDB_Base	; 83: "Marcato Strings"
	.long ToneRec_084 - ToneDB_Base	; 84: "Violin Ensemble"
	.long ToneRec_085 - ToneDB_Base	; 85: "Viola Ensemble"
	.long ToneRec_086 - ToneDB_Base	; 86: "Cello Ensemble"
	.long ToneRec_087 - ToneDB_Base	; 87: "Bass Ensemble"
	.long ToneRec_088 - ToneDB_Base	; 88: "Slow Strings"
	.long ToneRec_089 - ToneDB_Base	; 89: "Octave Strings"
	.long ToneRec_090 - ToneDB_Base	; 90: "Bass Strings"
	.long ToneRec_091 - ToneDB_Base	; 91: "Tremolo Strings"
	.long ToneRec_092 - ToneDB_Base	; 92: "Pizzicato Str."
	.long ToneRec_093 - ToneDB_Base	; 93: "Synth Strings 1"
	.long ToneRec_094 - ToneDB_Base	; 94: "Synth Strings 2"
	.long ToneRec_095 - ToneDB_Base	; 95: "Violin"
	.long ToneRec_096 - ToneDB_Base	; 96: "Jazz Violin"
	.long ToneRec_097 - ToneDB_Base	; 97: "Country Fiddle"
	.long ToneRec_098 - ToneDB_Base	; 98: "Viola"
	.long ToneRec_099 - ToneDB_Base	; 99: "Cello"
	.long ToneRec_100 - ToneDB_Base	; 100: "Bowed Bass"
	.long ToneRec_101 - ToneDB_Base	; 101: "Vocal Ah"
	.long ToneRec_102 - ToneDB_Base	; 102: "Pop Vocal Ah"
	.long ToneRec_103 - ToneDB_Base	; 103: "Stereo Vocal Ah"
	.long ToneRec_104 - ToneDB_Base	; 104: "Vocal Ooh"
	.long ToneRec_105 - ToneDB_Base	; 105: "Humming"
	.long ToneRec_106 - ToneDB_Base	; 106: "Synth Vocal"
	.long ToneRec_107 - ToneDB_Base	; 107: "Air Vox"
	.long ToneRec_108 - ToneDB_Base	; 108: "Vocal Doo"
	.long ToneRec_109 - ToneDB_Base	; 109: "Vocal Daa"
	.long ToneRec_110 - ToneDB_Base	; 110: "German Acdn 1"
	.long ToneRec_111 - ToneDB_Base	; 111: "German Acdn 2"
	.long ToneRec_112 - ToneDB_Base	; 112: "German Acdn 3"
	.long ToneRec_113 - ToneDB_Base	; 113: "German Acdn 4"
	.long ToneRec_114 - ToneDB_Base	; 114: "German Acdn 5"
	.long ToneRec_115 - ToneDB_Base	; 115: "German Acdn 6"
	.long ToneRec_116 - ToneDB_Base	; 116: "German Acdn 7"
	.long ToneRec_117 - ToneDB_Base	; 117: "German Acdn 8"
	.long ToneRec_118 - ToneDB_Base	; 118: "German Acdn Bs1"
	.long ToneRec_119 - ToneDB_Base	; 119: "German Acdn Bs2"
	.long ToneRec_120 - ToneDB_Base	; 120: "Italian Acdn 1"
	.long ToneRec_121 - ToneDB_Base	; 121: "Italian Acdn 2"
	.long ToneRec_122 - ToneDB_Base	; 122: "Italian Acdn 3"
	.long ToneRec_123 - ToneDB_Base	; 123: "Italian Acdn 4"
	.long ToneRec_124 - ToneDB_Base	; 124: "Italian Acdn 5"
	.long ToneRec_125 - ToneDB_Base	; 125: "Italian Acdn 6"
	.long ToneRec_126 - ToneDB_Base	; 126: "Italian Acdn 7"
	.long ToneRec_127 - ToneDB_Base	; 127: "Italian Acdn 8"
	.long ToneRec_128 - ToneDB_Base	; 128: "Italian Acdn Bs1"
	.long ToneRec_129 - ToneDB_Base	; 129: "Italian Acdn Bs2"
	.long ToneRec_130 - ToneDB_Base	; 130: "Perc Organ"
	.long ToneRec_131 - ToneDB_Base	; 131: "Full Drawbars"
	.long ToneRec_132 - ToneDB_Base	; 132: "Jazz Drawbars"
	.long ToneRec_133 - ToneDB_Base	; 133: "16' & 1'"
	.long ToneRec_134 - ToneDB_Base	; 134: "Accomp Drawbars"
	.long ToneRec_135 - ToneDB_Base	; 135: "Pop Organ"
	.long ToneRec_136 - ToneDB_Base	; 136: "Soul Organ"
	.long ToneRec_137 - ToneDB_Base	; 137: "Rock Organ"
	.long ToneRec_138 - ToneDB_Base	; 138: "Organ Bass"
	.long ToneRec_139 - ToneDB_Base	; 139: "Chapel Organ"
	.long ToneRec_140 - ToneDB_Base	; 140: "Full Organ"
	.long ToneRec_141 - ToneDB_Base	; 141: "Cathedral Organ"
	.long ToneRec_142 - ToneDB_Base	; 142: "Theatre Organ"
	.long ToneRec_143 - ToneDB_Base	; 143: "Theatre Accomp"
	.long ToneRec_144 - ToneDB_Base	; 144: "Theatre Novelty"
	.long ToneRec_145 - ToneDB_Base	; 145: "Bright Accordion"
	.long ToneRec_146 - ToneDB_Base	; 146: "Mellow Accordion"
	.long ToneRec_147 - ToneDB_Base	; 147: "Musette"
	.long ToneRec_148 - ToneDB_Base	; 148: "Bandoneon"
	.long ToneRec_149 - ToneDB_Base	; 149: "Folk Accordion"
	.long ToneRec_150 - ToneDB_Base	; 150: "Bigband Brass"
	.long ToneRec_151 - ToneDB_Base	; 151: "Marching Brass"
	.long ToneRec_152 - ToneDB_Base	; 152: "Brass & Synth"
	.long ToneRec_153 - ToneDB_Base	; 153: "Octave Brass"
	.long ToneRec_154 - ToneDB_Base	; 154: "Octave Horns"
	.long ToneRec_155 - ToneDB_Base	; 155: "Synth Brass 1"
	.long ToneRec_156 - ToneDB_Base	; 156: "Synth Brass 2"
	.long ToneRec_157 - ToneDB_Base	; 157: "Trumpet"
	.long ToneRec_158 - ToneDB_Base	; 158: "Solo Trumpet"
	.long ToneRec_159 - ToneDB_Base	; 159: "Orchest.Trumpet"
	.long ToneRec_160 - ToneDB_Base	; 160: "Harmon Mute Tpt"
	.long ToneRec_161 - ToneDB_Base	; 161: "StraightMuteTpt"
	.long ToneRec_162 - ToneDB_Base	; 162: "Flugel Horn"
	.long ToneRec_163 - ToneDB_Base	; 163: "Bright Trombone"
	.long ToneRec_164 - ToneDB_Base	; 164: "Mellow Trombone"
	.long ToneRec_165 - ToneDB_Base	; 165: "CupMuteTrombone"
	.long ToneRec_166 - ToneDB_Base	; 166: "Closed Fr.Horn"
	.long ToneRec_167 - ToneDB_Base	; 167: "Open Fr.Horn"
	.long ToneRec_168 - ToneDB_Base	; 168: "Marching Tuba"
	.long ToneRec_169 - ToneDB_Base	; 169: "Brass Fall"
	.long ToneRec_170 - ToneDB_Base	; 170: "Soprano Sax"
	.long ToneRec_171 - ToneDB_Base	; 171: "Alto Sax"
	.long ToneRec_172 - ToneDB_Base	; 172: "Mellow Alto Sax"
	.long ToneRec_173 - ToneDB_Base	; 173: "Tenor Sax 1"
	.long ToneRec_174 - ToneDB_Base	; 174: "Tenor Sax 2"
	.long ToneRec_175 - ToneDB_Base	; 175: "Breathy Tenor"
	.long ToneRec_176 - ToneDB_Base	; 176: "Rock Tenor Sax"
	.long ToneRec_177 - ToneDB_Base	; 177: "Baritone Sax"
	.long ToneRec_178 - ToneDB_Base	; 178: "Distortion Sax"
	.long ToneRec_179 - ToneDB_Base	; 179: "Unison Saxes"
	.long ToneRec_180 - ToneDB_Base	; 180: "Jazz Clarinet 1"
	.long ToneRec_181 - ToneDB_Base	; 181: "Jazz Clarinet 2"
	.long ToneRec_182 - ToneDB_Base	; 182: "Mellow Clarinet"
	.long ToneRec_183 - ToneDB_Base	; 183: "Classic Clarinet"
	.long ToneRec_184 - ToneDB_Base	; 184: "Bass Clarinet"
	.long ToneRec_185 - ToneDB_Base	; 185: "Oboe"
	.long ToneRec_186 - ToneDB_Base	; 186: "English Horn"
	.long ToneRec_187 - ToneDB_Base	; 187: "Bassoon"
	.long ToneRec_188 - ToneDB_Base	; 188: "Harmonica"
	.long ToneRec_189 - ToneDB_Base	; 189: "Blues Harmonica"
	.long ToneRec_190 - ToneDB_Base	; 190: "Piccolo"
	.long ToneRec_191 - ToneDB_Base	; 191: "Jazz Flute"
	.long ToneRec_192 - ToneDB_Base	; 192: "Classical Flute"
	.long ToneRec_193 - ToneDB_Base	; 193: "Alto Flute"
	.long ToneRec_194 - ToneDB_Base	; 194: "Alto Ensemble"
	.long ToneRec_195 - ToneDB_Base	; 195: "Flutter Flute"
	.long ToneRec_196 - ToneDB_Base	; 196: "Pan Flute 1"
	.long ToneRec_197 - ToneDB_Base	; 197: "Pan Flute 2"
	.long ToneRec_198 - ToneDB_Base	; 198: "Synth Calliope"
	.long ToneRec_199 - ToneDB_Base	; 199: "Recorder"
	.long ToneRec_200 - ToneDB_Base	; 200: "Ocarina"
	.long ToneRec_201 - ToneDB_Base	; 201: "Blown Bottle"
	.long ToneRec_202 - ToneDB_Base	; 202: "Whistle"
	.long ToneRec_203 - ToneDB_Base	; 203: "Shakuhachi"
	.long ToneRec_204 - ToneDB_Base	; 204: "Quena"
	.long ToneRec_205 - ToneDB_Base	; 205: "Ney"
	.long ToneRec_206 - ToneDB_Base	; 206: "Chopper Flute"
	.long ToneRec_207 - ToneDB_Base	; 207: "Penny Whistle"
	.long ToneRec_208 - ToneDB_Base	; 208: "Marching Whistle"
	.long ToneRec_209 - ToneDB_Base	; 209: "Chiff Flute"
	.long ToneRec_210 - ToneDB_Base	; 210: "Acoustic Bass"
	.long ToneRec_211 - ToneDB_Base	; 211: "Mellow Ac.Bass"
	.long ToneRec_212 - ToneDB_Base	; 212: "Electric Bass"
	.long ToneRec_213 - ToneDB_Base	; 213: "Bright E.Bass"
	.long ToneRec_214 - ToneDB_Base	; 214: "Fusion E.Bass"
	.long ToneRec_215 - ToneDB_Base	; 215: "Funky E.Bass"
	.long ToneRec_216 - ToneDB_Base	; 216: "Fretless Bass"
	.long ToneRec_217 - ToneDB_Base	; 217: "Picked E.Bass"
	.long ToneRec_218 - ToneDB_Base	; 218: "Mute Bass"
	.long ToneRec_219 - ToneDB_Base	; 219: "Slap Bass 1"
	.long ToneRec_220 - ToneDB_Base	; 220: "Slap Bass 2"
	.long ToneRec_221 - ToneDB_Base	; 221: "Killer Bass"
	.long ToneRec_222 - ToneDB_Base	; 222: "Analog Bass"
	.long ToneRec_223 - ToneDB_Base	; 223: "Soul Bass"
	.long ToneRec_224 - ToneDB_Base	; 224: "Wow Bass"
	.long ToneRec_225 - ToneDB_Base	; 225: "Dance Bass"
	.long ToneRec_226 - ToneDB_Base	; 226: "House Bass"
	.long ToneRec_227 - ToneDB_Base	; 227: "Plastic Bass"
	.long ToneRec_228 - ToneDB_Base	; 228: "Basic Synth Bass"
	.long ToneRec_229 - ToneDB_Base	; 229: "Techno Bass"
	.long ToneRec_230 - ToneDB_Base	; 230: "Agogo"
	.long ToneRec_231 - ToneDB_Base	; 231: "Wood Block"
	.long ToneRec_232 - ToneDB_Base	; 232: "Taiko Drum"
	.long ToneRec_233 - ToneDB_Base	; 233: "Melodic Tom"
	.long ToneRec_234 - ToneDB_Base	; 234: "Synth Drum"
	.long ToneRec_235 - ToneDB_Base	; 235: "Reverse Cymbal"
	.long ToneRec_236 - ToneDB_Base	; 236: "Fret Noise"
	.long ToneRec_237 - ToneDB_Base	; 237: "Breath Noise"
	.long ToneRec_238 - ToneDB_Base	; 238: "Seashore"
	.long ToneRec_239 - ToneDB_Base	; 239: "Bird Tweet"
	.long ToneRec_240 - ToneDB_Base	; 240: "Telephone"
	.long ToneRec_241 - ToneDB_Base	; 241: "Helicopter"
	.long ToneRec_242 - ToneDB_Base	; 242: "Applause"
	.long ToneRec_243 - ToneDB_Base	; 243: "Gun Shot"
	.long ToneRec_244 - ToneDB_Base	; 244: "Tinkle Bell"
	.long ToneRec_245 - ToneDB_Base	; 245: "Rock Harmonics"
	.long ToneRec_246 - ToneDB_Base	; 246: "Harmonium"
	.long ToneRec_247 - ToneDB_Base	; 247: "Orchestral Tuba"
	.long ToneRec_248 - ToneDB_Base	; 248: "Bagpipe"
	.long ToneRec_249 - ToneDB_Base	; 249: "Shanai"
	.long ToneRec_250 - ToneDB_Base	; 250: "Square Lead"
	.long ToneRec_251 - ToneDB_Base	; 251: "Saw Lead"
	.long ToneRec_252 - ToneDB_Base	; 252: "Sine Lead"
	.long ToneRec_253 - ToneDB_Base	; 253: "Chiffer Lead"
	.long ToneRec_254 - ToneDB_Base	; 254: "Charang"
	.long ToneRec_255 - ToneDB_Base	; 255: "Metallica Solo"
	.long ToneRec_256 - ToneDB_Base	; 256: "Talking Lead"
	.long ToneRec_257 - ToneDB_Base	; 257: "Digi Stack"
	.long ToneRec_258 - ToneDB_Base	; 258: "80's Solo"
	.long ToneRec_259 - ToneDB_Base	; 259: "Steamy Keys"
	.long ToneRec_260 - ToneDB_Base	; 260: "Olymp Synth"
	.long ToneRec_261 - ToneDB_Base	; 261: "Voco Synth"
	.long ToneRec_262 - ToneDB_Base	; 262: "Block Synth"
	.long ToneRec_263 - ToneDB_Base	; 263: "5th Wave"
	.long ToneRec_264 - ToneDB_Base	; 264: "Bass & Lead"
	.long ToneRec_265 - ToneDB_Base	; 265: "Talking Synth"
	.long ToneRec_266 - ToneDB_Base	; 266: "Synth Harp"
	.long ToneRec_267 - ToneDB_Base	; 267: "Afro Dance"
	.long ToneRec_268 - ToneDB_Base	; 268: "Digi Bells"
	.long ToneRec_269 - ToneDB_Base	; 269: "Crystal"
	.long ToneRec_270 - ToneDB_Base	; 270: "Mellow Ensemble"
	.long ToneRec_271 - ToneDB_Base	; 271: "Warm Synth Pad"
	.long ToneRec_272 - ToneDB_Base	; 272: "Spacy Pad"
	.long ToneRec_273 - ToneDB_Base	; 273: "Metal Pad"
	.long ToneRec_274 - ToneDB_Base	; 274: "Star Theme"
	.long ToneRec_275 - ToneDB_Base	; 275: "Bowed Glass"
	.long ToneRec_276 - ToneDB_Base	; 276: "Atmosphere"
	.long ToneRec_277 - ToneDB_Base	; 277: "Fantasia"
	.long ToneRec_278 - ToneDB_Base	; 278: "Multi Sweeper"
	.long ToneRec_279 - ToneDB_Base	; 279: "Bell Pad"
	.long ToneRec_280 - ToneDB_Base	; 280: "Dream"
	.long ToneRec_281 - ToneDB_Base	; 281: "Mist"
	.long ToneRec_282 - ToneDB_Base	; 282: "Sweep Pad"
	.long ToneRec_283 - ToneDB_Base	; 283: "Halo Pad"
	.long ToneRec_284 - ToneDB_Base	; 284: "Echo Drops"
	.long ToneRec_285 - ToneDB_Base	; 285: "Poly Synth"
	.long ToneRec_286 - ToneDB_Base	; 286: "Warm Synth Brass"
	.long ToneRec_287 - ToneDB_Base	; 287: "Ice Rain"
	.long ToneRec_288 - ToneDB_Base	; 288: "Soundtrack"
	.long ToneRec_289 - ToneDB_Base	; 289: "Goblins"
	.long ToneRec_290 - ToneDB_Base	; 290: "Strings & Horns"
	.long ToneRec_291 - ToneDB_Base	; 291: "Strings & Flutes"
	.long ToneRec_292 - ToneDB_Base	; 292: "Piano & Strings"
	.long ToneRec_293 - ToneDB_Base	; 293: "Heavenly Strings"
	.long ToneRec_294 - ToneDB_Base	; 294: "Warm String Pad"
	.long ToneRec_295 - ToneDB_Base	; 295: "Chamber Orch"
	.long ToneRec_296 - ToneDB_Base	; 296: "Cathedral"
	.long ToneRec_297 - ToneDB_Base	; 297: "Movie Musical"
	.long ToneRec_298 - ToneDB_Base	; 298: "Field of Voices"
	.long ToneRec_299 - ToneDB_Base	; 299: "Horns & Woods"
	.long ToneRec_300 - ToneDB_Base	; 300: "Dark Movie Scene"
	.long ToneRec_301 - ToneDB_Base	; 301: "Orchestral Sweep"
	.long ToneRec_302 - ToneDB_Base	; 302: "Moonlight Pad"
	.long ToneRec_303 - ToneDB_Base	; 303: "Orchestra Pizz"
	.long ToneRec_304 - ToneDB_Base	; 304: "Synth Orchestra"
	.long ToneRec_305 - ToneDB_Base	; 305: "Unison Strings"
	.long ToneRec_306 - ToneDB_Base	; 306: "Springtime Orch"
	.long ToneRec_307 - ToneDB_Base	; 307: "Dreamy Strings"
	.long ToneRec_308 - ToneDB_Base	; 308: "Many Horns"
	.long ToneRec_309 - ToneDB_Base	; 309: "Big Band Pad"
	.long DrumKit_05_JazzKit - ToneDB_Base	; 310: "Jazz Kit" (drum kit)
	.long DrumKit_19_JazzKit - ToneDB_Base	; 311: "Jazz Kit" (drum kit)
	.long DrumKit_07_BrushKit - ToneDB_Base	; 312: "Brush Kit" (drum kit)
	.long DrumKit_20_BrushKit - ToneDB_Base	; 313: "Brush Kit" (drum kit)
	.long DrumKit_06_TradKit - ToneDB_Base	; 314: "Trad Kit" (drum kit)
	.long DrumKit_00_StandardKit - ToneDB_Base	; 315: "Standard Kit" (drum kit)
	.long DrumKit_14_StandardKit - ToneDB_Base	; 316: "Standard Kit" (drum kit)
	.long DrumKit_18_AnalogKit - ToneDB_Base	; 317: "Analog Kit" (drum kit)
	.long DrumKit_01_RoomKit - ToneDB_Base	; 318: "Room Kit" (drum kit)
	.long DrumKit_15_RoomKit - ToneDB_Base	; 319: "Room Kit" (drum kit)
	.long DrumKit_03_LightRockKit - ToneDB_Base	; 320: "Light Rock Kit" (drum kit)
	.long DrumKit_02_PowerKit - ToneDB_Base	; 321: "Power Kit" (drum kit)
	.long DrumKit_16_PowerKit - ToneDB_Base	; 322: "Power Kit" (drum kit)
	.long DrumKit_04_FunkKit - ToneDB_Base	; 323: "Funk Kit" (drum kit)
	.long DrumKit_08_DanceKit - ToneDB_Base	; 324: "Dance Kit" (drum kit)
	.long DrumKit_09_HouseKit - ToneDB_Base	; 325: "House Kit" (drum kit)
	.long DrumKit_10_SoulKit - ToneDB_Base	; 326: "Soul Kit" (drum kit)
	.long DrumKit_11_ElectricKit - ToneDB_Base	; 327: "Electric Kit" (drum kit)
	.long DrumKit_17_ElectricKit - ToneDB_Base	; 328: "Electric Kit" (drum kit)
	.long DrumKit_23_SynthKit - ToneDB_Base	; 329: "Synth Kit" (drum kit)
	.long DrumKit_12_OrchestralKit - ToneDB_Base	; 330: "Orchestral Kit" (drum kit)
	.long DrumKit_21_OrchestralKit - ToneDB_Base	; 331: "Orchestral Kit" (drum kit)
	.long DrumKit_24_SoundEffectKit - ToneDB_Base	; 332: "Sound Effect Kit" (drum kit)
	.long DrumKit_25_SoundEffectKit - ToneDB_Base	; 333: "Sound Effect Kit" (drum kit)
	.long DrumKit_13_MSPKit - ToneDB_Base	; 334: "MSP Kit" (drum kit)
	.long DrumKit_22_SpecialKit - ToneDB_Base	; 335: "Special Kit" (drum kit)
	.long DrawbarPreset_Jazz - ToneDB_Base	; 336: "<Jazz Drawbars>" (drawbar organ)
	.long DrawbarPreset_Rock - ToneDB_Base	; 337: "<Rock Drawbars>" (drawbar organ)
; --- DSP1 stream region: entries 338+ = stream index 0+ after the +338 bias ---
	.long ToneRec_338 - ToneDB_Base	; 338: "Rock Piano 2"
	.long ToneRec_339 - ToneDB_Base	; 339: "Midi Grand 2"
	.long ToneRec_340 - ToneDB_Base	; 340: "Bell Piano"
	.long ToneRec_341 - ToneDB_Base	; 341: "Crystal E.P."
	.long ToneRec_342 - ToneDB_Base	; 342: "Jangle Piano"
	.long ToneRec_343 - ToneDB_Base	; 343: "Fancy Folk"
	.long ToneRec_344 - ToneDB_Base	; 344: "Midi Guitar"
	.long ToneRec_345 - ToneDB_Base	; 345: "SynthJazzGuitar"
	.long ToneRec_346 - ToneDB_Base	; 346: "Synth Strings 3"
	.long ToneRec_347 - ToneDB_Base	; 347: "Synth Strings 4"
	.long ToneRec_348 - ToneDB_Base	; 348: "Mute Brass Ens."
	.long ToneRec_349 - ToneDB_Base	; 349: "Stereo Brass"
	.long ToneRec_350 - ToneDB_Base	; 350: "Unihorns"
	.long ToneRec_351 - ToneDB_Base	; 351: "Bright S.Brass"
	.long ToneRec_352 - ToneDB_Base	; 352: "Old Wow Brass"
	.long ToneRec_353 - ToneDB_Base	; 353: "Digi Organ"
	.long ToneRec_354 - ToneDB_Base	; 354: "Misty Flute"
	.long ToneRec_355 - ToneDB_Base	; 355: "Straight Bass"
	.long ToneRec_356 - ToneDB_Base	; 356: "Wet Bass"
	.long ToneRec_357 - ToneDB_Base	; 357: "Analog Bass 2"
	.long ToneRec_358 - ToneDB_Base	; 358: "Clavi Lead"
	.long ToneRec_359 - ToneDB_Base	; 359: "Telstar"
	.long ToneRec_360 - ToneDB_Base	; 360: "Sleigh Synth"
	.long ToneRec_361 - ToneDB_Base	; 361: "Sweppy"
	.long ToneRec_362 - ToneDB_Base	; 362: "Synth Chimes"
	.long ToneRec_363 - ToneDB_Base	; 363: "Knock Whistle"
	.long ToneRec_364 - ToneDB_Base	; 364: "Fusion Lead 1"
	.long ToneRec_365 - ToneDB_Base	; 365: "Fusion Lead 2"
	.long ToneRec_366 - ToneDB_Base	; 366: "Synth Slap"
	.long ToneRec_367 - ToneDB_Base	; 367: "Voxmosphere"
	.long ToneRec_368 - ToneDB_Base	; 368: "Glimmer"
	.long ToneRec_369 - ToneDB_Base	; 369: "Happy Ensemble"
	.long ToneRec_370 - ToneDB_Base	; 370: "Synth Voices"
	.long ToneRec_371 - ToneDB_Base	; 371: "Dark Universe"
	.long ToneRec_372 - ToneDB_Base	; 372: "Windy Sweep"
	.long ToneRec_373 - ToneDB_Base	; 373: "Piano Trio"
	.long ToneRec_374 - ToneDB_Base	; 374: "Funk Staff"
	.long ToneRec_375 - ToneDB_Base	; 375: "Bonanza"
	.long ToneRec_376 - ToneDB_Base	; 376: "Multi Pitch"
	.long ToneRec_377 - ToneDB_Base	; 377: "Under Water"
	.long ToneRec_000 - ToneDB_Base	; 378: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 379: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 380: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 381: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 382: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 383: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 384: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 385: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 386: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 387: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 388: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 389: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 390: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 391: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 392: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 393: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 394: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 395: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 396: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 397: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 398: unused slot, aliases entry 0 "Piano"
	.long ToneRec_000 - ToneDB_Base	; 399: unused slot, aliases entry 0 "Piano"
	.long ToneRec_400 - ToneDB_Base	; 400: "Piano"
	.long ToneRec_401 - ToneDB_Base	; 401: "Piano"
	.long ToneRec_402 - ToneDB_Base	; 402: "Piano"
	.long ToneRec_403 - ToneDB_Base	; 403: "Bright Piano"
	.long ToneRec_404 - ToneDB_Base	; 404: "Bright Piano"
	.long ToneRec_405 - ToneDB_Base	; 405: "Electric Grand"
	.long ToneRec_406 - ToneDB_Base	; 406: "Electric Grand"
	.long ToneRec_407 - ToneDB_Base	; 407: "Honky-Tonk Piano"
	.long ToneRec_408 - ToneDB_Base	; 408: "Honky-Tonk Piano"
	.long ToneRec_409 - ToneDB_Base	; 409: "E.Piano"
	.long ToneRec_410 - ToneDB_Base	; 410: "E.Piano"
	.long ToneRec_411 - ToneDB_Base	; 411: "E.Piano"
	.long ToneRec_412 - ToneDB_Base	; 412: "E.Piano"
	.long ToneRec_413 - ToneDB_Base	; 413: "Modern E.P."
	.long ToneRec_414 - ToneDB_Base	; 414: "Modern E.P."
	.long ToneRec_415 - ToneDB_Base	; 415: "Modern E.P."
	.long ToneRec_416 - ToneDB_Base	; 416: "Harpsichord"
	.long ToneRec_417 - ToneDB_Base	; 417: "Harpsichord"
	.long ToneRec_418 - ToneDB_Base	; 418: "Harpsichord"
	.long ToneRec_419 - ToneDB_Base	; 419: "Harpsichord"
	.long ToneRec_420 - ToneDB_Base	; 420: "Clavi"
	.long ToneRec_421 - ToneDB_Base	; 421: "Celesta"
	.long ToneRec_422 - ToneDB_Base	; 422: "Glockenspiel"
	.long ToneRec_423 - ToneDB_Base	; 423: "Music Box"
	.long ToneRec_424 - ToneDB_Base	; 424: "Vibraphone"
	.long ToneRec_425 - ToneDB_Base	; 425: "Vibraphone"
	.long ToneRec_426 - ToneDB_Base	; 426: "Marimba"
	.long ToneRec_427 - ToneDB_Base	; 427: "Marimba"
	.long ToneRec_428 - ToneDB_Base	; 428: "Xylophone"
	.long ToneRec_429 - ToneDB_Base	; 429: "Tubular Bells"
	.long ToneRec_430 - ToneDB_Base	; 430: "Tubular Bells"
	.long ToneRec_431 - ToneDB_Base	; 431: "Tubular Bells"
	.long ToneRec_432 - ToneDB_Base	; 432: "Dulcimer"
	.long ToneRec_433 - ToneDB_Base	; 433: "Full Drawbars"
	.long ToneRec_434 - ToneDB_Base	; 434: "Full Drawbars"
	.long ToneRec_435 - ToneDB_Base	; 435: "Full Drawbars"
	.long ToneRec_436 - ToneDB_Base	; 436: "Full Drawbars"
	.long ToneRec_437 - ToneDB_Base	; 437: "Perc Organ"
	.long ToneRec_438 - ToneDB_Base	; 438: "Perc Organ"
	.long ToneRec_439 - ToneDB_Base	; 439: "Perc Organ"
	.long ToneRec_440 - ToneDB_Base	; 440: "Rock Organ"
	.long ToneRec_441 - ToneDB_Base	; 441: "Pipe Organ"
	.long ToneRec_442 - ToneDB_Base	; 442: "Pipe Organ"
	.long ToneRec_443 - ToneDB_Base	; 443: "Pipe Organ"
	.long ToneRec_444 - ToneDB_Base	; 444: "Harmonium"
	.long ToneRec_445 - ToneDB_Base	; 445: "Accordion"
	.long ToneRec_446 - ToneDB_Base	; 446: "Accordion"
	.long ToneRec_447 - ToneDB_Base	; 447: "Harmonica"
	.long ToneRec_448 - ToneDB_Base	; 448: "Bandoneon"
	.long ToneRec_449 - ToneDB_Base	; 449: "Jazz Ac.Guitar"
	.long ToneRec_450 - ToneDB_Base	; 450: "Jazz Ac.Guitar"
	.long ToneRec_451 - ToneDB_Base	; 451: "Jazz Ac.Guitar"
	.long ToneRec_452 - ToneDB_Base	; 452: "Jazz Ac.Guitar"
	.long ToneRec_453 - ToneDB_Base	; 453: "Folk Guitar"
	.long ToneRec_454 - ToneDB_Base	; 454: "Folk Guitar"
	.long ToneRec_455 - ToneDB_Base	; 455: "Folk Guitar"
	.long ToneRec_456 - ToneDB_Base	; 456: "Jazz Guitar"
	.long ToneRec_457 - ToneDB_Base	; 457: "Jazz Guitar"
	.long ToneRec_458 - ToneDB_Base	; 458: "Solid Guitar"
	.long ToneRec_459 - ToneDB_Base	; 459: "Solid Guitar"
	.long ToneRec_460 - ToneDB_Base	; 460: "Mute Guitar"
	.long ToneRec_461 - ToneDB_Base	; 461: "Mute Guitar"
	.long ToneRec_462 - ToneDB_Base	; 462: "Mute Guitar"
	.long ToneRec_463 - ToneDB_Base	; 463: "Overdrive Guitar"
	.long ToneRec_464 - ToneDB_Base	; 464: "Distortion Gtr"
	.long ToneRec_465 - ToneDB_Base	; 465: "Distortion Gtr"
	.long ToneRec_466 - ToneDB_Base	; 466: "Rock Harmonics"
	.long ToneRec_467 - ToneDB_Base	; 467: "Rock Harmonics"
	.long ToneRec_468 - ToneDB_Base	; 468: "Acoustic Bass"
	.long ToneRec_469 - ToneDB_Base	; 469: "Bright Bass"
	.long ToneRec_470 - ToneDB_Base	; 470: "Picked E.Bass"
	.long ToneRec_471 - ToneDB_Base	; 471: "Fretless Bass"
	.long ToneRec_472 - ToneDB_Base	; 472: "Slap Bass 1"
	.long ToneRec_473 - ToneDB_Base	; 473: "Slap Bass 2"
	.long ToneRec_474 - ToneDB_Base	; 474: "Wow Bass"
	.long ToneRec_475 - ToneDB_Base	; 475: "Wow Bass"
	.long ToneRec_476 - ToneDB_Base	; 476: "Wow Bass"
	.long ToneRec_477 - ToneDB_Base	; 477: "Plastic Bass"
	.long ToneRec_478 - ToneDB_Base	; 478: "Plastic Bass"
	.long ToneRec_479 - ToneDB_Base	; 479: "Plastic Bass"
	.long ToneRec_480 - ToneDB_Base	; 480: "Violin"
	.long ToneRec_481 - ToneDB_Base	; 481: "Violin"
	.long ToneRec_482 - ToneDB_Base	; 482: "Viola"
	.long ToneRec_483 - ToneDB_Base	; 483: "Cello"
	.long ToneRec_484 - ToneDB_Base	; 484: "Bowed Bass"
	.long ToneRec_485 - ToneDB_Base	; 485: "Tremolo Strings"
	.long ToneRec_486 - ToneDB_Base	; 486: "Pizzicato Str."
	.long ToneRec_487 - ToneDB_Base	; 487: "Harp"
	.long ToneRec_488 - ToneDB_Base	; 488: "Timpani"
	.long ToneRec_489 - ToneDB_Base	; 489: "Strings"
	.long ToneRec_490 - ToneDB_Base	; 490: "Strings"
	.long ToneRec_491 - ToneDB_Base	; 491: "Slow Strings"
	.long ToneRec_492 - ToneDB_Base	; 492: "Synth String 1"
	.long ToneRec_493 - ToneDB_Base	; 493: "Synth String 1"
	.long ToneRec_494 - ToneDB_Base	; 494: "Synth String 2"
	.long ToneRec_495 - ToneDB_Base	; 495: "Vocal Ah"
	.long ToneRec_496 - ToneDB_Base	; 496: "Vocal Ah"
	.long ToneRec_497 - ToneDB_Base	; 497: "Vocal Doo"
	.long ToneRec_498 - ToneDB_Base	; 498: "Synth Vocal"
	.long ToneRec_499 - ToneDB_Base	; 499: "Orchestra Hit"
	.long ToneRec_500 - ToneDB_Base	; 500: "Trumpet"
	.long ToneRec_501 - ToneDB_Base	; 501: "Trombone"
	.long ToneRec_502 - ToneDB_Base	; 502: "Trombone"
	.long ToneRec_503 - ToneDB_Base	; 503: "Tuba"
	.long ToneRec_504 - ToneDB_Base	; 504: "Harmon Mute Tpt"
	.long ToneRec_505 - ToneDB_Base	; 505: "Open Fr.Horn"
	.long ToneRec_506 - ToneDB_Base	; 506: "Open Fr.Horn"
	.long ToneRec_507 - ToneDB_Base	; 507: "Bigband Brass"
	.long ToneRec_508 - ToneDB_Base	; 508: "Bigband Brass"
	.long ToneRec_509 - ToneDB_Base	; 509: "Synth Brass 1"
	.long ToneRec_510 - ToneDB_Base	; 510: "Synth Brass 1"
	.long ToneRec_511 - ToneDB_Base	; 511: "Synth Brass 1"
	.long ToneRec_512 - ToneDB_Base	; 512: "Synth Brass 2"
	.long ToneRec_513 - ToneDB_Base	; 513: "Synth Brass 2"
	.long ToneRec_514 - ToneDB_Base	; 514: "Synth Brass 2"
	.long ToneRec_515 - ToneDB_Base	; 515: "Soprano Sax"
	.long ToneRec_516 - ToneDB_Base	; 516: "Alto Sax"
	.long ToneRec_517 - ToneDB_Base	; 517: "Alto Sax"
	.long ToneRec_518 - ToneDB_Base	; 518: "Tenor Sax"
	.long ToneRec_519 - ToneDB_Base	; 519: "Tenor Sax"
	.long ToneRec_520 - ToneDB_Base	; 520: "Baritone Sax"
	.long ToneRec_521 - ToneDB_Base	; 521: "Oboe"
	.long ToneRec_522 - ToneDB_Base	; 522: "English Horn"
	.long ToneRec_523 - ToneDB_Base	; 523: "Bassoon"
	.long ToneRec_524 - ToneDB_Base	; 524: "Jazz Clarinet"
	.long ToneRec_525 - ToneDB_Base	; 525: "Jazz Clarinet"
	.long ToneRec_526 - ToneDB_Base	; 526: "Piccolo"
	.long ToneRec_527 - ToneDB_Base	; 527: "Jazz Flute"
	.long ToneRec_528 - ToneDB_Base	; 528: "Recorder"
	.long ToneRec_529 - ToneDB_Base	; 529: "Pan Flute"
	.long ToneRec_530 - ToneDB_Base	; 530: "Blown Bottle"
	.long ToneRec_531 - ToneDB_Base	; 531: "Shakuhachi"
	.long ToneRec_532 - ToneDB_Base	; 532: "Whistle"
	.long ToneRec_533 - ToneDB_Base	; 533: "Ocarina"
	.long ToneRec_534 - ToneDB_Base	; 534: "Square Lead"
	.long ToneRec_535 - ToneDB_Base	; 535: "Square Lead"
	.long ToneRec_536 - ToneDB_Base	; 536: "Square Lead"
	.long ToneRec_537 - ToneDB_Base	; 537: "Saw Lead"
	.long ToneRec_538 - ToneDB_Base	; 538: "Saw Lead"
	.long ToneRec_539 - ToneDB_Base	; 539: "Saw Lead"
	.long ToneRec_540 - ToneDB_Base	; 540: "Synth Calliope"
	.long ToneRec_541 - ToneDB_Base	; 541: "Chiffer Lead"
	.long ToneRec_542 - ToneDB_Base	; 542: "Charang"
	.long ToneRec_543 - ToneDB_Base	; 543: "Air Vox"
	.long ToneRec_544 - ToneDB_Base	; 544: "5th Wave"
	.long ToneRec_545 - ToneDB_Base	; 545: "Bass & Lead"
	.long ToneRec_546 - ToneDB_Base	; 546: "Fantasia"
	.long ToneRec_547 - ToneDB_Base	; 547: "Warm Pad"
	.long ToneRec_548 - ToneDB_Base	; 548: "Poly Synth"
	.long ToneRec_549 - ToneDB_Base	; 549: "Spacy Pad"
	.long ToneRec_550 - ToneDB_Base	; 550: "Bowed Glass"
	.long ToneRec_551 - ToneDB_Base	; 551: "Metal Pad"
	.long ToneRec_552 - ToneDB_Base	; 552: "Halo Pad"
	.long ToneRec_553 - ToneDB_Base	; 553: "Sweep Pad"
	.long ToneRec_554 - ToneDB_Base	; 554: "Ice Rain"
	.long ToneRec_555 - ToneDB_Base	; 555: "Soundtrack"
	.long ToneRec_556 - ToneDB_Base	; 556: "Crystal"
	.long ToneRec_557 - ToneDB_Base	; 557: "Crystal"
	.long ToneRec_558 - ToneDB_Base	; 558: "Atmosphere"
	.long ToneRec_559 - ToneDB_Base	; 559: "Brightness"
	.long ToneRec_560 - ToneDB_Base	; 560: "Goblins"
	.long ToneRec_561 - ToneDB_Base	; 561: "Echo Drops"
	.long ToneRec_562 - ToneDB_Base	; 562: "Echo Drops"
	.long ToneRec_563 - ToneDB_Base	; 563: "Echo Drops"
	.long ToneRec_564 - ToneDB_Base	; 564: "Star Theme"
	.long ToneRec_565 - ToneDB_Base	; 565: "Sitar"
	.long ToneRec_566 - ToneDB_Base	; 566: "Sitar"
	.long ToneRec_567 - ToneDB_Base	; 567: "Banjo"
	.long ToneRec_568 - ToneDB_Base	; 568: "Shamisen"
	.long ToneRec_569 - ToneDB_Base	; 569: "Koto"
	.long ToneRec_570 - ToneDB_Base	; 570: "Koto"
	.long ToneRec_571 - ToneDB_Base	; 571: "Kalimba"
	.long ToneRec_572 - ToneDB_Base	; 572: "Bagpipe"
	.long ToneRec_573 - ToneDB_Base	; 573: "Country Fiddle"
	.long ToneRec_574 - ToneDB_Base	; 574: "Shanai"
	.long ToneRec_575 - ToneDB_Base	; 575: "Tinkle Bell"
	.long ToneRec_576 - ToneDB_Base	; 576: "Agogo"
	.long ToneRec_577 - ToneDB_Base	; 577: "Steel Drum"
	.long ToneRec_578 - ToneDB_Base	; 578: "Wood Block"
	.long ToneRec_579 - ToneDB_Base	; 579: "Wood Block"
	.long ToneRec_580 - ToneDB_Base	; 580: "Taiko Drum"
	.long ToneRec_581 - ToneDB_Base	; 581: "Taiko Drum"
	.long ToneRec_582 - ToneDB_Base	; 582: "Melodic Tom"
	.long ToneRec_583 - ToneDB_Base	; 583: "Melodic Tom"
	.long ToneRec_584 - ToneDB_Base	; 584: "Synth Drum"
	.long ToneRec_585 - ToneDB_Base	; 585: "Synth Drum"
	.long ToneRec_586 - ToneDB_Base	; 586: "Synth Drum"
	.long ToneRec_587 - ToneDB_Base	; 587: "Reverse Cymbal"
	.long ToneRec_588 - ToneDB_Base	; 588: "Fret Noise"
	.long ToneRec_589 - ToneDB_Base	; 589: "Fret Noise"
	.long ToneRec_590 - ToneDB_Base	; 590: "Fret Noise"
	.long ToneRec_591 - ToneDB_Base	; 591: "Breath Noise"
	.long ToneRec_592 - ToneDB_Base	; 592: "Breath Noise"
	.long ToneRec_593 - ToneDB_Base	; 593: "Seashore"
	.long ToneRec_594 - ToneDB_Base	; 594: "Seashore"
	.long ToneRec_595 - ToneDB_Base	; 595: "Seashore"
	.long ToneRec_596 - ToneDB_Base	; 596: "Seashore"
	.long ToneRec_597 - ToneDB_Base	; 597: "Seashore"
	.long ToneRec_598 - ToneDB_Base	; 598: "Seashore"
	.long ToneRec_599 - ToneDB_Base	; 599: "Bird Tweet"
	.long ToneRec_600 - ToneDB_Base	; 600: "Bird Tweet"
	.long ToneRec_601 - ToneDB_Base	; 601: "Bird Tweet"
	.long ToneRec_602 - ToneDB_Base	; 602: "Bird Tweet"
	.long ToneRec_603 - ToneDB_Base	; 603: "Telephone"
	.long ToneRec_604 - ToneDB_Base	; 604: "Telephone"
	.long ToneRec_605 - ToneDB_Base	; 605: "Telephone"
	.long ToneRec_606 - ToneDB_Base	; 606: "Telephone"
	.long ToneRec_607 - ToneDB_Base	; 607: "Telephone"
	.long ToneRec_608 - ToneDB_Base	; 608: "Telephone"
	.long ToneRec_609 - ToneDB_Base	; 609: "Helicopter"
	.long ToneRec_610 - ToneDB_Base	; 610: "Helicopter"
	.long ToneRec_611 - ToneDB_Base	; 611: "Helicopter"
	.long ToneRec_612 - ToneDB_Base	; 612: "Helicopter"
	.long ToneRec_613 - ToneDB_Base	; 613: "Helicopter"
	.long ToneRec_614 - ToneDB_Base	; 614: "Helicopter"
	.long ToneRec_615 - ToneDB_Base	; 615: "Helicopter"
	.long ToneRec_616 - ToneDB_Base	; 616: "Helicopter"
	.long ToneRec_617 - ToneDB_Base	; 617: "Helicopter"
	.long ToneRec_618 - ToneDB_Base	; 618: "Helicopter"
	.long ToneRec_619 - ToneDB_Base	; 619: "Applause"
	.long ToneRec_620 - ToneDB_Base	; 620: "Applause"
	.long ToneRec_621 - ToneDB_Base	; 621: "Applause"
	.long ToneRec_622 - ToneDB_Base	; 622: "Applause"
	.long ToneRec_623 - ToneDB_Base	; 623: "Applause"
	.long ToneRec_624 - ToneDB_Base	; 624: "Applause"
	.long ToneRec_625 - ToneDB_Base	; 625: "Gun Shot"
	.long ToneRec_626 - ToneDB_Base	; 626: "Gun Shot"
	.long ToneRec_627 - ToneDB_Base	; 627: "Gun Shot"
	.long ToneRec_628 - ToneDB_Base	; 628: "Gun Shot"
