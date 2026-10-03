; ram_variables.s -- main-CPU RAM variables named in the technics-docs pages, beyond the constants
; files (cpanel_constants.s, midi_encoder_constants.s).  The pages give v10's addresses; these are
; v7's, derived by scripts/tools/name_kn5000_ram.py from the same instructions in the same routines
; (a corrected line says so).  Names it could not derive for v7 are left out (RHYTHM_PATTERN_SEL_A,
; RHYTHM_PATTERN_TYPE, RHYTHM_PATTERN_BUF_B).  Each line cites the page that establishes the variable.

; sequencer.md "State Machine Variable (8D36h)": written only by SeqState_TransitionMode
	.equ SEQ_MASTER_STATE,		0x8c9a	; master sequencer state; 0x10-0x16 = Seq_DispatcherTick skips	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8d36
; sequencer.md "Key RAM Addresses"
	.equ RHYTHM_VARIATION_INDEX,	0x33da	; variation index, 0..0x1E	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x3476
	.equ RHYTHM_PATTERN_SEL_B,	0x33f2	; pattern selector B	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x348e
	.equ RHYTHM_PATTERN_BUF_A,	0x94800	; pattern buffer A, 1,024 bytes per pattern
; memory-map.md "Medley State Variables"
	.equ MEDLEY_PLAY_FLAG,		0x8462	; 0 = stopped, 1 = playing	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x84fe
	.equ MEDLEY_ORDER_ARRAY,	0x87f4	; play order, 10 bytes; 0xFF = unused, 0xFE = marked	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8890
	.equ MEDLEY_SONG_COUNT,		0x87fe	; songs in the current playlist	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x889a
	.equ MEDLEY_CURRENT_INDEX,	0x8800	; the song playing	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x889c
	.equ MEDLEY_REPEAT_FLAG,	0x8802	; 0 = no repeat, 1 = repeat all	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x889e
; data-wheel-investigation.md "Key DRAM Addresses"
	.equ SWBTWR_EVENT_QUEUE,	0xbca0	; SwbtWr main event queue, 4-byte events, 0xFF sentinel	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xbd3c
	.equ SWBTWR_PAYLOAD_1,		0xbfe1	; payload byte 1 (0x21 identifies the data wheel)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xc07d
	.equ SWBTWR_PAYLOAD_2,		0xbfe2	; payload byte 2 (the signed detent count)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xc07e
	.equ SWBTWR_PAYLOAD_3,		0xbfe3	; payload byte 3	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xc07f
	.equ SWBTWR_EVENT_TYPE,		0xbfe4	; event type, written during dispatch	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xc080
; named from the writer census (python3 scripts/analysis/kn5000_ram_writers.py --tree v10 <addr>)
	.equ SEQ_ERROR_CODE,		0x287a	; sequencer-data error code: 0 = none; 1..11 / 255 set by the end-mark, overflow and bad-parameter paths (SeqData_HandleEndMark_SetError1, SeqBuf_PageOverflowError, Part_ValidateSetup_ErrorEnd ...); cleared before operations, tested against 0 after
	.equ GLOBAL_ERROR_CODE,		0x7ea6	; set by SetGlobalError and the error / status paths of disk, medley, drum-kit, password ... code (values 1..74, 255); compared against constants	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x7f42
; MidiSeq_SwapActiveBuffers exchanges (0xBCAC) with (0xBCB0) and (0xBC54) with (0xBC58): two
; active / spare pointer pairs (MidiChan_InitAllBufferPtrs sets them up)
	.equ MIDISEQ_ACTIVE_BUF_PTR,	0xbc10	; the active buffer; read at 220 sites	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xbcac
	.equ MIDISEQ_SPARE_BUF_PTR,	0xbc14	; the one MidiSeq_SwapActiveBuffers exchanges it with	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xbcb0
	.equ MIDISEQ_ACTIVE_BLOCK_PTR,	0xbbb8	; the second pair's active pointer (its +10 / +14 words are compared)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xbc54
	.equ MIDISEQ_SPARE_BLOCK_PTR,	0xbbbc	; and its spare	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xbc58
