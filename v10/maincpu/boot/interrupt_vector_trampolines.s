; =============================================================================
; MIDI RX record-type handler table, part 2 of 2 (types 0x3C-0xBF)
; =============================================================================
; ⚠ NOT INTERRUPT VECTORS.  Until 2026-09-25 this file was titled "Interrupt
; Vector Trampolines - TMP94C241 hardware interrupt entry points" and said
; "each 8-byte slot corresponds to a hardware interrupt vector", spelling the
; bytes as `.fill 8, 1, 0xff` rows plus `swi 7` / `decf` / `adc` / `ld xiy`
; lines.  Proven wrong: the CPU's vector table is the 4-byte-per-vector table
; at 0xFFFF00 (boot/rom_end_structure.s), and these 525 bytes are the tail of
; the 192-entry handler table MidiStream_HandleRunningStatus_0x98
; (0xFCCF01-0xFCD200; the name is a .set in shared/positional_labels.s).
; Entries 0-59 and three bytes of entry 60 end audio/audio_control_engine.s;
; this file holds the last byte of entry 60 and entries 61-191.
;
; Reader: MidiStream_DispatchLoop (0xFCC868, audio/audio_control_engine.s),
; entered from MidiStream_ProcessRxBuffer (0xFCC856):
;     ld xix, 0xc039 / ld hl, (0x9133) / ld a, (xix+hl)    record type byte
;     cp a, 0xff -> done;  cp a, 0xbf / jr ugt -> skip       types 0x00-0xBF
;     extz wa / sll wa, 2 / ld xiy, MidiStream_HandleRunningStatus_0x98
;     ld xiy, (xiy + wa) / cp xiy, 0xffffffff / jr z -> skip
;     BC = record word 0 -> (0x915B), DE = record word 1 -> (0x915D)
;     call (xiy);  then (0x9133) += 4 and loop
; So the RX buffer at RAM 0xC039 holds 4-byte records, byte 0 is the record
; type, and entry <type> of this table is its handler; 0xFFFFFFFF = no
; handler, the record is skipped.  Stride 4 = `sll wa, 2`; count 192 = the
; `cp a, 0xbf` bound, and the table ends exactly where SoundParam_NotifyChange
; (0xFCD201) begins.  Types 0x00-0x1F all use MidiStream_StatusPrecheck (in
; part 1); the only other handlers are types 0x48, 0x60 and 0x98 below, each
; a short dispatcher on the record's byte 1 that sits directly in front of the
; jump table it indexes (written as <table> - <its length> because the
; dispatchers have no labels of their own in audio/audio_control_engine.s).
; Open question, for whoever documents the writers of the RX buffer: which
; incoming MIDI traffic produces record types 0x48, 0x60 and 0x98.
;
; Earlier notes on two of these rows (kept; both regions are table entries):
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFCD01C-0xFCD02C (16 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=100% dist=5 near MidiStream_HandleRunningStatus_0x98+283
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFCD15C-0xFCD16C (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=5 near MidiStream_HandleRunningStatus_0x98+603

	.byte	0xff					; last byte of entry 60 (type 0x3C): 0xFFFFFFFF
	.long	0xffffffff, 0xffffffff, 0xffffffff	; types 0x3D-0x3F
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x40-0x43
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x44-0x47
	.long	MidiStream_SysExJumpTable - 23		; type 0x48: the dispatcher right before MidiStream_SysExJumpTable;
						; it switches on record byte 1 (`cp l, 3`) through that table
	.long	0xffffffff, 0xffffffff, 0xffffffff	; types 0x49-0x4B
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x4C-0x4F
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x50-0x53
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x54-0x57
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x58-0x5B
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x5C-0x5F
	.long	MidiStream_CtrlJumpTable - 23		; type 0x60: the dispatcher right before MidiStream_CtrlJumpTable;
						; it switches on record byte 1 (`cp l, 1`) through that table
	.long	0xffffffff, 0xffffffff, 0xffffffff	; types 0x61-0x63
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x64-0x67
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x68-0x6B
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x6C-0x6F
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x70-0x73
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x74-0x77
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x78-0x7B
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x7C-0x7F
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x80-0x83
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x84-0x87
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x88-0x8B
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x8C-0x8F
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x90-0x93
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x94-0x97
	.long	MidiStream_CmdJumpTable - 24		; type 0x98: the dispatcher right before MidiStream_CmdJumpTable;
						; it switches on record byte 1 (`cp l, 0x0b`) through that table
	.long	0xffffffff, 0xffffffff, 0xffffffff	; types 0x99-0x9B
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0x9C-0x9F
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xA0-0xA3
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xA4-0xA7
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xA8-0xAB
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xAC-0xAF
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xB0-0xB3
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xB4-0xB7
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xB8-0xBB
	.long	0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; types 0xBC-0xBF
