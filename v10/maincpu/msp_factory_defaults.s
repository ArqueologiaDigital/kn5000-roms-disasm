; MSP_FACTORY_DEFAULTS -- factory image of the accompaniment stream-buffer pool
;
; 5,376 bytes = 21 x 256.  Voice_InitBankData copies this to RAM 0x1E8B00 with
; `ldw bc, 0xa80` + `ldirw` (0xA80 WORDS), and Voice_GetSlotAddress computes
; `0x1e8b00 + (index << 8)`, so the destination is an array of 256-byte blocks
; and this image preloads the first 21 of the pool's 57.
;
; The record structure and every field name now live in msp_factory_defaults.c,
; which `clang -target tlcs900` compiles to the byte-identical 5,376 bytes
; .incbin'd below.  Each field there is named after the instruction that reads
; or writes it (allocation bit, prev/next block links, the two 0x87 guards the
; runtime cursor can never reach, and the accompaniment opcode stream), and the
; stream rows are split at event boundaries.
;
; The 5,376 bytes are byte-identical in v7, v9 and v10 (verified by
; scripts/generators/gen_msp_factory_defaults_c.py), so the same .c is used for
; all three images.
;
; !! The old header here called this "MSP (Music Style Preset) Factory Default
; Data ... default values for all MSP parameters".  The readers contradict
; that: every instruction found touching these bytes treats them as pool
; blocks and byte streams (below), none as parameters.  The label is kept only
; because the assembly references it by name.
;
; READERS (addresses v10 = v9 / v7):
;   Voice_InitBankData        0xF6F309 / 0xF6EF05  copies all 0xA80 words to
;                                                  RAM 0x1E8B00 (`ldirw`)
;   Voice_GetSlotAddress      0xF6F3D0 / 0xF6EFCC  block n = 0x1E8B00 + n*256
;   CountAvailableVoiceSlots  0xF6F3B0 / 0xF6EFAC  `bitm 7` on block byte +0
;   AccompSeq_ParseSequenceData 0xF6EE26 / 0xF6EA22 walks the stream at
;       +0x06..+0xFE through ResolveVRAMAddressForVoice
;       (0x1E8B00 + (blk & 0xFFF)*256 + cursor), dispatching on the opcode.
;
; STREAM FRAMING, now read off a reader and not only off the tiling test in
; msp_factory_defaults.c.  AccompSeq_ParseSequenceData steps over each event
; with one AccompSeq_AdvancePosition (0xF6DEE0 / 0xF6DADC) per byte:
;   0x90  6 bytes  (six AdvancePosition calls, AccompSeq_SeqParse_CheckNoteOn)
;   0x91  8 bytes  (eight calls, AccompSeq_SeqParse_CheckNoteOn8)
;   0xD1..0xD7  3 bytes: +1 tick, +2 value; low nibble of the opcode is sent
;         as the control index with the value (AccompSeq_WriteMidiToBuffer)
;   0xC0  6 bytes: +2 -> 0x7E55, +3 flags (bit 0 tested), +4 low nibble -> 0x7E57
;   0x81  1 byte, increments the beat counter at 0x7E46
;   0x83  1 byte, end of sequence (AccompSeq_CleanupSequence)
;   0x84  tempo reset (AccompSeq_SeqParse_TempoReset), no advance
;   (0x84, 0xC0, 0xD4, 0xD5 and 0xD7 are dispatched but do not occur in these
;   21 blocks: the generator's tiling uses only 0x90/0x91/0xD1-0xD3/0x81/0x83.)
;   0x87  block guard: AccompSeq_AdvancePosition and AccompSeq_CheckPatternEnd
;         (0xF6DEC5 / 0xF6DAC1) test for it and hop to the next block.
; These are exactly the lengths the generator's tiling test found (558 events,
; twelve chains); the reader and the test agree independently.
; Byte +1 of every MIDI-class event is its TICK: AccompSeq_CheckPatternEnd
; returns (xiy+1), and AccompSeq_SeqParse_MidiEvent compares
; (beat << 8 | tick) with the target position in 0x7E64:0x7E63, stopping when
; the event lies beyond it.
; Open: this parser only steps over bytes +2..+5 of a 0x90 and +2..+7 of a
; 0x91 (it replays program and control changes up to a position, not notes).
; The player, AccompSeq_ParseEvents (0xF6E07A / 0xF6DC76), copies them with
; AccompSeq_ReadParams (0xF6E15D / 0xF6DD59) into RAM 0x7E56..0x7E59 (a 0x91's
; +6/+7 into 0x7E5A/0x7E5B) and hands them to AccompSeq_ProcessNoteOn6 /
; AccompSeq_ProcessNoteOn8; which byte is note, velocity or length is decided
; there and is not traced here, so msp_factory_defaults.c leaves them unnamed.

MSP_FACTORY_DEFAULTS:
	.incbin "includes/generated/msp_factory_defaults.bin"
