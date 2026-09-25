import sys, re
p = sys.argv[1]
s = open(p, encoding='latin-1').read()
def rep(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:70], s.count(old))
    s = s.replace(old, new)

rep('''AccPedal_BytecodeBlock1:
	pushw wa
	push xiy
	and (0x32c7:16), 0xfe''', '''; -----------------------------------------------------------------------------
; AccPedal_LoadFlagFromStyleMem -- bit 0 of RAM 0x32C7 := bit 0 of the byte at
; RAM 0x094810.  Preserves WA and XIY.  (v10: the same routine on 0x3363.)
; 0x094800 is the RAM copy of the composer factory user-style memory
; (technics-docs memory-map.md), so the byte read is offset 0x10 of it.
; Sibling of AccPedal_SetFlag13155 below, which sets the same bit.
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v7 0xF533A5 -- one
; absolute hit, at 0xF62013, is the operand bytes of `cp iy,(0x33a5)`; no
; calr/jr/jrl lands here.  Was `.byte` until 2026-09-25
; (notes/sequi-2026-09-25/reframe-v7-seq_audio_mode.log).
; -----------------------------------------------------------------------------
AccPedal_LoadFlagFromStyleMem:
	pushw wa
	push xiy
	and (0x32c7:16), 0xfe''')
rep('''AccPedal_BytecodeBlock1_Code:
	popw	wa''', '''	popw	wa''')

rep('''AccPedal_PartOffsetTable:
	.byte 0x00, 0x00, 0x30, 0x00, 0x00, 0x98, 0x31, 0x00
	.byte 0x00, 0x00, 0x33, 0x00, 0x00, 0x98, 0x34, 0x00
	.byte 0x00, 0x00, 0x36, 0x00, 0x00, 0x98, 0x37, 0x00
	.byte 0x00, 0x00, 0x39, 0x00
''', '''; -----------------------------------------------------------------------------
; AccPedal_BankBaseTableCopy -- 7 x 32-bit addresses, value-for-value the same
; as AccVoice_BankBaseTable entries 1-7 (Custom Data Flash window).  Extent:
; to AccPedal_ProcessAllChanges, a called routine (28 bytes = 7 longs).
; NO READER FOUND: scripts/analysis/sequi_find_refs.py v7 --window 64 0xF533D0
; -- the hits are the call to AccPedal_ProcessAllChanges (+28) and operand
; bytes of unrelated instructions.  Kept as data: 0x98 at +5 does not decode.
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
	ld a, (0x3259:16)''', '''; -----------------------------------------------------------------------------
; AccChannel_StoreStateIfChanged -- the conditional form of
; AccChannel_StoreCurrentState (just above): when RAM 0x3259 differs from
; 0x325A, or it is below 0x80 and the low 3 bits of 0x325B and 0x325C differ,
; copy 0x3259 -> 0x324B and 0x325B -> 0x324C.  (v10: 0x32F5.. / 0x32E7..;
; the `and w` masks apply to W, not to the A that is stored.)
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v7 0xF534E8 -> none.
; Was `.byte` until 2026-09-25; decodes cleanly, both decoders agree.
; -----------------------------------------------------------------------------
AccChannel_StoreStateIfChanged:
	ld a, (0x3259:16)''')

rep('''AccVoice_PartOffsetTable2:
	.byte 0x00, 0x48, 0x09, 0x00, 0x00, 0x00, 0x30, 0x00
	.byte 0x00, 0x98, 0x31, 0x00, 0x00, 0x00, 0x33, 0x00
	.byte 0x00, 0x98, 0x34, 0x00, 0x00, 0x00, 0x36, 0x00
	.byte 0x00, 0x98, 0x37, 0x00, 0x00, 0x00, 0x39, 0x00
''', '''; -----------------------------------------------------------------------------
; AccVoice_BankBaseTable -- 8 x 32-bit base addresses indexed by RAM byte
; 0x324A (v10: 0x32E6).
; Reader: AccVoice_ComputeParamOffset (0xF5392A, the tail of
; AccVoice_ResolveParamAddr 0xF5391C): `ld xix, AccVoice_BankBaseTable`,
; `ld_rrl xix, xix, wa` with wa = (0x324A)*4; the entry is added to the
; 32-bit offset loaded from the RhythmTiming_OffsetTable entry (A clamped to
; 0..0x1D) plus 0x60, and the sum returned in XIY -- each entry is the base
; of a bank those offsets index into.
; Stride 4 (`sla wa, 2`); 8 entries = 32 bytes, to AccVoice_ComputeChannelIndex.
; Entry 0 is RAM 0x094800, the RAM copy of the composer factory user-style
; memory (technics-docs memory-map.md); entries 1-7 lie in the Custom Data
; Flash window 0x300000-0x3FFFFF.  Which user-style slots they are is not
; established.
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
rep('''	ld	xix, 16070995
	ld_rrl	xix, xix, wa''', '''	ld	xix, AccVoice_BankBaseTable
	ld_rrl	xix, xix, wa''')

rep('''AccVoice_BytecodeBlock3:
	calr 13
	calr 21
	calr 29
	calr 37
	calr 45
	ret
	ld (0x31aa:16), 6
	ld (0x31ab:16), 0
	ret
	ld (0x31b1:16), 0
	ld (0x31b2:16), 0
	ret
	ld (0x31b8:16), 0
	ld (0x31b9:16), 0
	ret
	ld (0x31bf:16), 0
	ld (0x31c0:16), 0
	ret
	ld (0x31c6:16), 0
	ld (0x31c7:16), 0
	ret
	ld (0x3259:16), 15
	and (0x325b:16), 0xf8
	or (0x325b:16), 0x00
	ret
	ret
	call Rhythm_DispatchNote_Helper
	ld (0x328f:16), e
	ret
	ld a, (0xfc5a:16)
	ld d, (0xfc5b:16)
	call Rhythm_DispatchNote
	ld (0x328f:16), a
	ret
''', '''; -----------------------------------------------------------------------------
; Nine small routines between VoiceParams_LoadFiveSequential and
; RhythmROM_CheckValid, `.byte` until 2026-09-25.  Both decoders agree on every
; instruction (notes/sequi-2026-09-25/reframe-v7-seq_audio_mode.log), every
; internal calr lands on an instruction boundary, and the calls reach the
; independently known Rhythm_DispatchNote / Rhythm_DispatchNote_Helper.
; NO CALLER FOUND for the five entry points nothing here calls:
; scripts/analysis/sequi_find_refs.py v7 0xF540B9 0xF54100 0xF54110 0xF54111
; 0xF5411A -> none (one table-data byte match).  v10 carries the same nine.
; -----------------------------------------------------------------------------

; Writes the first two bytes of the first five 7-byte records at RAM 0x31AA,
; 0x31B1, 0x31B8, 0x31BF, 0x31C6 (record 0 byte 0 := 6, the other nine := 0).
; v10 does the same at 0x3246.., where AccTuning_CopyAllPartsFromStyle and
; AccVoice_LoadTuningBlock show these are the 7-byte per-part tuning records.
AccTuning_ResetFiveParts:
	calr AccTuning_ResetFiveParts_Rec0
	calr AccTuning_ResetFiveParts_Rec1
	calr AccTuning_ResetFiveParts_Rec2
	calr AccTuning_ResetFiveParts_Rec3
	calr AccTuning_ResetFiveParts_Rec4
	ret
AccTuning_ResetFiveParts_Rec0:
	ld (0x31aa:16), 6
	ld (0x31ab:16), 0
	ret
AccTuning_ResetFiveParts_Rec1:
	ld (0x31b1:16), 0
	ld (0x31b2:16), 0
	ret
AccTuning_ResetFiveParts_Rec2:
	ld (0x31b8:16), 0
	ld (0x31b9:16), 0
	ret
AccTuning_ResetFiveParts_Rec3:
	ld (0x31bf:16), 0
	ld (0x31c0:16), 0
	ret
AccTuning_ResetFiveParts_Rec4:
	ld (0x31c6:16), 0
	ld (0x31c7:16), 0
	ret

; RAM 0x3259 := 15 and the low 3 bits of 0x325B := 0 -- the two bytes
; AccChannel_StoreCurrentState copies out.
AccChannel_ResetCurrentState:
	ld (0x3259:16), 15
	and (0x325b:16), 0xf8
	or (0x325b:16), 0x00
	ret

AccVoice_EmptyStub:
	ret

; Stores the E that Rhythm_DispatchNote_Helper returns into RAM 0x328F.
Rhythm_StoreDispatchHelperResult:
	call Rhythm_DispatchNote_Helper
	ld (0x328f:16), e
	ret

; Rhythm_DispatchNote with A = RAM 0xFC5A and D = RAM 0xFC5B; the A it
; returns is stored into RAM 0x328F.
Rhythm_DispatchNoteFromFC5A:
	ld a, (0xfc5a:16)
	ld d, (0xfc5b:16)
	call Rhythm_DispatchNote
	ld (0x328f:16), a
	ret
''')

rep('''RhythmROM_BytecodeBlock4:
	ld	xwa, 1024''', '''; -----------------------------------------------------------------------------
; Heap_AllocAndFreeTwoBlocks -- Malloc(0x400) (pointer kept in RAM 0x34C0),
; Malloc(0x1000), Free(second), Free(first), return.  NO CALLER FOUND:
; scripts/analysis/sequi_find_refs.py v7 0xF54158 -> none.
; The two callees carry misleading v7 names: 0xFF06A3
; (`SLIDE_Decompress_4K_Init_Helper2`) is v10's Malloc (0xFF0E80) -- 63 of
; their first 64 bytes equal, the odd one a relocated call operand -- and
; 0xFF0315 (`SLIDE_Decompress_4K_Init_Helper`) is v10's Free (0xFF0AF2), 62/64
; equal.  v10's copy of this routine calls Malloc / Free by name.
; -----------------------------------------------------------------------------
Heap_AllocAndFreeTwoBlocks:
	ld	xwa, 1024''')
open(p, 'w', encoding='latin-1').write(s)
print('ok')
