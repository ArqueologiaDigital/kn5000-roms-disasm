; ram_variables.s -- main-CPU RAM variables named in the technics-docs pages, beyond the constants
; files (cpanel_constants.s, midi_encoder_constants.s).  Values are v10's; scripts/tools/
; name_kn5000_ram.py derives each tree's own from the same instructions in the same routines.
; Each line cites the page that establishes the variable.

; MainTitleControl (the title / mode object) -- EVT_CHANGE_MODE: `ldmm8 PREVIOUS_MODE, CURRENT_MODE / ld (CURRENT_MODE), l`;
; EVT_CHANGE_TITLE -> MainTitleCtrl_ChangeTitle: PREVIOUS_TITLE := CURRENT_TITLE, CURRENT_TITLE := l.  sequencer.md
; called 0x8D36 the "master sequencer state": its skip range 0x10-0x16 is exactly the TT_STYLCNV* titles
	.equ CURRENT_MODE,		0x8d34	; the current mode id (NAKA_MODE_* - 0x1800000), set by EVT_CHANGE_MODE
	.equ PREVIOUS_MODE,		0x8d35	; the mode before the last EVT_CHANGE_MODE
	.equ CURRENT_TITLE,		0x8d36	; the current title id (TITLE_* - 0x1A00000); Seq_DispatcherTick skips while a style-conversion title (0x10-0x16) is current
; sequencer.md "Key RAM Addresses"
	.equ PREVIOUS_TITLE,		0x8d37	; the title before the last EVT_CHANGE_TITLE
	.equ RHYTHM_VARIATION_INDEX,	0x3476	; variation index, 0..0x1E
	.equ RHYTHM_PATTERN_SEL_A,	0x348d	; pattern selector A
	.equ RHYTHM_PATTERN_SEL_B,	0x348e	; pattern selector B
	.equ RHYTHM_PATTERN_TYPE,	0x348f	; pattern selector: type
	.equ RHYTHM_PATTERN_BUF_A,	0x94800	; pattern buffer A, 1,024 bytes per pattern
	.equ RHYTHM_PATTERN_BUF_B,	0x95c00	; pattern buffer B (double buffer)
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
; named from the writer census (python3 scripts/analysis/kn5000_ram_writers.py --tree v10 <addr>)
	.equ SEQ_ERROR_CODE,		0x287a	; sequencer-data error code: 0 = none; 1..11 / 255 set by the end-mark, overflow and bad-parameter paths (SeqData_HandleEndMark_SetError1, SeqBuf_PageOverflowError, Part_ValidateSetup_ErrorEnd ...); cleared before operations, tested against 0 after
	.equ GLOBAL_ERROR_CODE,		0x7f42	; set by SetGlobalError and the error / status paths of disk, medley, drum-kit, password ... code (values 1..74, 255); compared against constants
; MidiSeq_SwapActiveBuffers exchanges (0xBCAC) with (0xBCB0) and (0xBC54) with (0xBC58): two
; active / spare pointer pairs (MidiChan_InitAllBufferPtrs sets them up)
	.equ MIDISEQ_ACTIVE_BUF_PTR,	0xbcac	; the active buffer; read at 220 sites
	.equ MIDISEQ_SPARE_BUF_PTR,	0xbcb0	; the one MidiSeq_SwapActiveBuffers exchanges it with
	.equ MIDISEQ_ACTIVE_BLOCK_PTR,	0xbc54	; the second pair's active pointer (its +10 / +14 words are compared)
	.equ MIDISEQ_SPARE_BLOCK_PTR,	0xbc58	; and its spare
; the ACTIVE title: EVT_CHANGE_TITLE, EVT_RETURN_TITLE and EVT_INTERRUPT_TITLE all set it (`ldmm8
; ACTIVE_TITLE_PREVIOUS, ACTIVE_TITLE / ld (ACTIVE_TITLE), l`); MainTitleCtrl_ChangeTitle's header names the
; transition variables
	.equ ACTIVE_TITLE,	0x8d38	; the title on screen: CURRENT_TITLE, or an interrupting / returned-to one
	.equ ACTIVE_TITLE_PREVIOUS,	0x8d39	; its previous value, saved before each change
	.equ TRANSITION_PROGRESS,	0x2749a	; transition progress counter (cleared on every title change)
	.equ TRANSITION_TIMER,		0x2749e	; transition timer
	.equ TRANSITION_FLAGS,		0x274a2	; transition type / flags
; the palette routine's header (ui/ui_window_procs.s) and UpdateScreen's (ui/ui_widget_defs.s)
	.equ PALETTE_DATA_PTR_CACHED,	0x3ef94	; current palette data pointer (cached)
	.equ PALETTE_INDEX_CACHED,	0x3ef9e	; current palette index (cached); a pending update is checked here
	.equ PALETTE_UPDATE_FLAG,	0x30460	; set to 1 to trigger the VRAM palette update
	.equ DIRTY_BBOX,		0x30456	; dirty bounding box Gfx_BlitDirtyRegions examines
; ColorBlit / ColorBlit2 (ui/ui_window_procs.s): the caller's (0x3EFA8) is copied to (0x3EFAA) -- or
; into the deferred draw-queue entry -- and ColorBlit_Impl dispatches on (0x3EFAA): 2 -> ColorBlit_Mode2_Entry,
; 1 -> ColorBlit_Mode1_Entry, 0 -> the mode-0 path
	.equ COLORBLIT_MODE,		0x3efa8	; the blit mode the next ColorBlit uses, 0..2 (set by ~150 drawing sites)
	.equ COLORBLIT_MODE_ACTIVE,	0x3efaa	; the mode ColorBlit_Impl is running with
; FileIO_ReadBlockToBuffer stores FileIO_ReadBlock's result (it reads 0x400 bytes into 0x13FA) here; the
; 113 readers do `ld xwa,(this) / cp xwa,xbc / jr lt, ..._FileUnderflow` -- fewer bytes than they need.
; SMF_WriteByte also stores 2 here (not explained)
	.equ FILEIO_BLOCK_BYTES,	0x1a2d	; bytes the last block read returned (32-bit)
