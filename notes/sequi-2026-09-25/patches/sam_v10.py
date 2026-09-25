import sys
p = sys.argv[1]
s = open(p, encoding='latin-1').read()
def rep(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:60], s.count(old))
    s = s.replace(old, new)

rep('''AccPedal_BytecodeBlock1:
	pushw wa
	push xiy
	and (0x3363:16), 0xfe
	ld xiy, 0x00094800''', '''; -----------------------------------------------------------------------------
; AccPedal_CopyStyleMemBit0ToFlag13155 -- bit 0 of RAM 0x3363 (13155) :=
; bit 0 of the byte at RAM 0x094810.  Preserves WA and XIY.
; 0x094800 is the RAM copy of the composer factory user-style memory
; (technics-docs memory-map.md: table data 0x9B4000-0x9C3FFF is copied to RAM
; 0x94800), so the byte read is offset 0x10 of that image.  Sibling of
; AccPedal_SetFlag13155 below, which sets the same bit unconditionally.
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v10 0xF537A9 finds no
; absolute 24-bit reference in any KN5000 image and no calr/jr/jrl landing
; here (computed word-offset jumps not searched).  Was `.byte` until
; 2026-09-25; decodes cleanly, both decoders agree
; (notes/sequi-2026-09-25/reframe-v10-seq_audio_mode.log).
; -----------------------------------------------------------------------------
AccPedal_CopyStyleMemBit0ToFlag13155:
	pushw wa
	push xiy
	and (0x3363:16), 0xfe
	ld xiy, 0x00094800''')

rep('''AccPedal_PartOffsetTable:
	.byte 0x00, 0x00, 0x30, 0x00, 0x00, 0x98, 0x31, 0x00
	.byte 0x00, 0x00, 0x33, 0x00, 0x00, 0x98, 0x34, 0x00
	.byte 0x00, 0x00, 0x36, 0x00, 0x00, 0x98, 0x37, 0x00
	.byte 0x00, 0x00, 0x39, 0x00
''', '''; -----------------------------------------------------------------------------
; AccPedal_BankBaseTableCopy -- 7 x 32-bit addresses, value-for-value the same
; as AccVoice_BankBaseTable entries 1-7 (all in the Custom Data Flash window
; 0x300000-0x3FFFFF).  Extent: from here to AccPedal_ProcessAllChanges, a
; called routine (28 bytes = 7 longs).
; NO READER FOUND: scripts/analysis/sequi_find_refs.py v10 --window 64 0xF537D4
; -- the only hits are the call to AccPedal_ProcessAllChanges (+28), operand
; bytes of unrelated instructions and table-data bytes.  Kept as data: the bytes
; do not decode as code (0x98 at +5 is undecodable) and they follow a `ret`.
; -----------------------------------------------------------------------------
AccPedal_BankBaseTableCopy:
	.long 0x00300000
	.long 0x00319800
	.long 0x00330000
	.long 0x00349800
	.long 0x00360000
	.long 0x00379800
	.long 0x00390000
''')

rep('''AccChannel_BytecodeBlock2:
	ld a, (0x32f5:16)''', '''; -----------------------------------------------------------------------------
; AccChannel_StoreStateIfChanged -- the conditional form of
; AccChannel_StoreCurrentState (just above): when RAM 0x32F5 differs from
; 0x32F6, or it is below 0x80 and the low 3 bits of 0x32F7 and 0x32F8 differ,
; copy 0x32F5 -> 0x32E7 and 0x32F7 -> 0x32E8.  (Like the routine above, the
; `and w` masks are applied to W, not to the A that is stored.)
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v10 0xF538EC (forms as
; above).  Was `.byte` until 2026-09-25; decodes cleanly, both decoders agree.
; -----------------------------------------------------------------------------
AccChannel_StoreStateIfChanged:
	ld a, (0x32f5:16)''')

rep('''AccVoice_BytecodeBlock3:
	calr 13
	calr 21
	calr 29
	calr 37
	calr 45
	ret
	ld (0x3246:16), 6
	ld (0x3247:16), 0
	ret
	ld (0x324d:16), 0
	ld (0x324e:16), 0
	ret
	ld (0x3254:16), 0
	ld (0x3255:16), 0
	ret
	ld (0x325b:16), 0
	ld (0x325c:16), 0
	ret
	ld (0x3262:16), 0
	ld (0x3263:16), 0
	ret
	ld (0x32f5:16), 15
	and (0x32f7:16), 0xf8
	or (0x32f7:16), 0x00
	ret
	ret
	call Rhythm_DispatchNote_Helper
	ld (0x332b:16), e
	ret
	ld a, (0xfc5a:16)
	ld d, (0xfc5b:16)
	call Rhythm_DispatchNote
	ld (0x332b:16), a
	ret
''', '''; -----------------------------------------------------------------------------
; Nine small routines between VoiceParams_LoadFiveSequential and
; RhythmROM_CheckValid, `.byte` until 2026-09-25.  Both decoders agree on every
; instruction (notes/sequi-2026-09-25/reframe-v10-seq_audio_mode.log), every
; internal calr lands on an instruction boundary, and the calls reach the
; independently known Rhythm_DispatchNote / Rhythm_DispatchNote_Helper.
; NO CALLER FOUND for the four entry points that nothing here calls
; (AccVoice_ResetRecords3246, AccChannel_ResetCurrentState,
; AccVoice_EmptyStub, Rhythm_DispatchHelperToFlag332B,
; Rhythm_DispatchNoteFromFC5A): scripts/analysis/sequi_find_refs.py v10
; 0xF544BD 0xF54504 0xF54514 0xF54515 0xF5451E -> none.
; -----------------------------------------------------------------------------

; Clears two bytes in each of five 7-byte-spaced RAM records at 0x3246,
; 0x324D, 0x3254, 0x325B, 0x3262 (the first byte of the first record is set
; to 6, every other cleared byte to 0).  What the records are is not
; established.
AccVoice_ResetRecords3246:
	calr AccVoice_ResetRecords3246_Rec0
	calr AccVoice_ResetRecords3246_Rec1
	calr AccVoice_ResetRecords3246_Rec2
	calr AccVoice_ResetRecords3246_Rec3
	calr AccVoice_ResetRecords3246_Rec4
	ret
AccVoice_ResetRecords3246_Rec0:
	ld (0x3246:16), 6
	ld (0x3247:16), 0
	ret
AccVoice_ResetRecords3246_Rec1:
	ld (0x324d:16), 0
	ld (0x324e:16), 0
	ret
AccVoice_ResetRecords3246_Rec2:
	ld (0x3254:16), 0
	ld (0x3255:16), 0
	ret
AccVoice_ResetRecords3246_Rec3:
	ld (0x325b:16), 0
	ld (0x325c:16), 0
	ret
AccVoice_ResetRecords3246_Rec4:
	ld (0x3262:16), 0
	ld (0x3263:16), 0
	ret

; RAM 0x32F5 := 15 and the low 3 bits of 0x32F7 := 0 -- the two bytes
; AccChannel_StoreCurrentState copies out.
AccChannel_ResetCurrentState:
	ld (0x32f5:16), 15
	and (0x32f7:16), 0xf8
	or (0x32f7:16), 0x00
	ret

AccVoice_EmptyStub:
	ret

; Stores the E that Rhythm_DispatchNote_Helper returns into RAM 0x332B.
Rhythm_DispatchHelperToFlag332B:
	call Rhythm_DispatchNote_Helper
	ld (0x332b:16), e
	ret

; Rhythm_DispatchNote with A = RAM 0xFC5A and D = RAM 0xFC5B; the A it
; returns is stored into RAM 0x332B.
Rhythm_DispatchNoteFromFC5A:
	ld a, (0xfc5a:16)
	ld d, (0xfc5b:16)
	call Rhythm_DispatchNote
	ld (0x332b:16), a
	ret
''')

rep('''RhythmROM_BytecodeBlock4:
	ld	xwa, 1024''', '''; -----------------------------------------------------------------------------
; Heap_AllocAndFreeTwoBlocks -- Malloc(0x400) (pointer kept in RAM 0x355C),
; Malloc(0x1000), Free(second), Free(first), return.  A heap round trip with
; no lasting effect except RAM 0x355C.  C-compiler shaped (`ld xwa,xhl;
; ld xwa,xwa; push xwa`).  NO CALLER FOUND: scripts/analysis/sequi_find_refs.py
; v10 0xF5455C -> none.  Was a mix of `.byte`, `.asciz "\\\\5c@"` and `addr24`
; until 2026-09-25 (the text was the operand bytes of `ld (0x355c:16), xhl`).
; -----------------------------------------------------------------------------
Heap_AllocAndFreeTwoBlocks:
	ld	xwa, 1024''')

rep('''AccVoice_PartOffsetTable2:
	.byte 0x00, 0x48, 0x09, 0x00, 0x00, 0x00, 0x30, 0x00
	.byte 0x00, 0x98, 0x31, 0x00, 0x00, 0x00, 0x33, 0x00
	.byte 0x00, 0x98, 0x34, 0x00, 0x00, 0x00, 0x36, 0x00
	.byte 0x00, 0x98, 0x37, 0x00, 0x00, 0x00, 0x39, 0x00
''', '''; -----------------------------------------------------------------------------
; AccVoice_BankBaseTable -- 8 x 32-bit base addresses indexed by RAM byte
; 0x32E6.
; Reader: AccVoice_ComputeParamOffset (0xF53D2E, the tail of
; AccVoice_ResolveParamAddr 0xF53D20): `ld xix, AccVoice_BankBaseTable` then
; `ld_sril3 XIX, 0x07, 0xf0, 0xe0` = ld xix, (xix + wa) with wa = (0x32E6)*4.
; The entry is added to the 32-bit offset the routine first loaded from
; RhythmTiming_OffsetTable[A] (A clamped to 0..0x1D), plus 0x60; the sum is
; returned in XIY.  So each entry is the base of a bank that those offsets
; index into.
; Stride 4 (the reader's `sla wa, 2`); 8 entries = 32 bytes, from here to
; AccVoice_ComputeChannelIndex (a called routine).
; Entry 0 is RAM 0x094800, the RAM copy of the composer factory user-style
; memory (technics-docs memory-map.md); entries 1-7 lie in the Custom Data
; Flash window 0x300000-0x3FFFFF, alternately 0x19800 and 0x16800 apart.
; Which user-style slots banks 1-7 are is not established.
; -----------------------------------------------------------------------------
AccVoice_BankBaseTable:
	.long 0x00094800
	.long 0x00300000
	.long 0x00319800
	.long 0x00330000
	.long 0x00349800
	.long 0x00360000
	.long 0x00379800
	.long 0x00390000
''')
rep('''	ld xix, AccVoice_PartOffsetTable2''', '''	ld xix, AccVoice_BankBaseTable''')
open(p, 'w', encoding='latin-1').write(s)
print("ok")
