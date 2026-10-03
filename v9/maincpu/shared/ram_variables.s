; ram_variables.s -- main-CPU RAM variables named in the technics-docs pages, beyond the constants
; files (cpanel_constants.s, midi_encoder_constants.s).  The pages give v10's addresses; these are
; v9's, derived by scripts/tools/name_kn5000_ram.py from the same instructions in the same routines
; (a corrected line says so).  Names it could not derive for v9 are left out (RHYTHM_PATTERN_SEL_A,
; RHYTHM_PATTERN_TYPE, RHYTHM_PATTERN_BUF_B).  Each line cites the page that establishes the variable.

; sequencer.md "State Machine Variable (8D36h)": written only by SeqState_TransitionMode
	.equ SEQ_MASTER_STATE,		0x8d36	; master sequencer state; 0x10-0x16 = Seq_DispatcherTick skips
; sequencer.md "Key RAM Addresses"
	.equ RHYTHM_VARIATION_INDEX,	0x3476	; variation index, 0..0x1E
	.equ RHYTHM_PATTERN_SEL_B,	0x348e	; pattern selector B
	.equ RHYTHM_PATTERN_BUF_A,	0x94800	; pattern buffer A, 1,024 bytes per pattern
; memory-map.md "Medley State Variables"
	.equ MEDLEY_PLAY_FLAG,		0x84fe	; 0 = stopped, 1 = playing
	.equ MEDLEY_ORDER_ARRAY,	0x8890	; play order, 10 bytes; 0xFF = unused, 0xFE = marked
	.equ MEDLEY_SONG_COUNT,		0x889a	; songs in the current playlist
	.equ MEDLEY_CURRENT_INDEX,	0x889c	; the song playing
	.equ MEDLEY_REPEAT_FLAG,	0x889e	; 0 = no repeat, 1 = repeat all
; data-wheel-investigation.md "Key DRAM Addresses"
	.equ SWBTWR_EVENT_QUEUE,	0xbd3c	; SwbtWr main event queue, 4-byte events, 0xFF sentinel
	.equ SWBTWR_PAYLOAD_1,		0xc07d	; payload byte 1 (0x21 identifies the data wheel)
	.equ SWBTWR_PAYLOAD_2,		0xc07e	; payload byte 2 (the signed detent count)
	.equ SWBTWR_PAYLOAD_3,		0xc07f	; payload byte 3
	.equ SWBTWR_EVENT_TYPE,		0xc080	; event type, written during dispatch
