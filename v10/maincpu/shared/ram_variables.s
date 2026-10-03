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
; custom-data-flash.md "Section Pointer Table": Flash_InitExtMemAddrs computes the eight section pointers
; of the Custom Data Flash (0x300000 + 0, 0x19800, 0x30000 ...) and stores them here; it also points
; RHYTHM_PATTERN_BUF_PTR at RHYTHM_PATTERN_BUF_A
	.equ FLASH_SECTION_PTR_0,	0x0c76	; section 0: custom accompaniment styles
	.equ FLASH_SECTION_PTR_1,	0x0c7a	; section 1: custom accompaniment styles
	.equ FLASH_SECTION_PTR_2,	0x0c7e	; section 2: custom accompaniment styles
	.equ FLASH_SECTION_PTR_3,	0x0c82	; section 3: custom accompaniment styles
	.equ FLASH_SECTION_PTR_4,	0x0c86	; section 4: custom accompaniment styles
	.equ FLASH_SECTION_PTR_5,	0x0c8a	; section 5: custom accompaniment styles
	.equ FLASH_SECTION_PTR_6,	0x0c8e	; section 6: custom accompaniment styles
	.equ FLASH_SECTION_PTR_7,	0x0c92	; section 7: sub-CPU performance data
	.equ RHYTHM_PATTERN_BUF_PTR,	0x0c6e	; set to RHYTHM_PATTERN_BUF_A by Flash_InitExtMemAddrs
; FDC state (fdc-subsystem.md "FDC Memory Map", taken only where the code agrees -- the page and
; reverse-engineering.md disagree about 0x8A2B-0x8A4A)
	.equ FDC_SECTOR_COUNT,		0x8a1c	; cleared per command, incremented per sector
	.equ FDC_ERROR_CODE,		0x8a24	; cleared at command start, set by FDC_Set_Status; 32 compares
	.equ FDC_TARGET_TRACK,		0x8a36	; the caller's target track (fdc_routines.s's own comment)
	.equ FDC_COMMAND_INDEX,		0x8a40	; the command FDC dispatches on, 0..11 (12 handlers)
; control-panel-protocol.md "MIDI Message Format (at 0x9127-0x912A)": one MIDI message staged before it is
; sent -- statuses 0xB0..0xB3 written, word stores of status + first data byte
	.equ MIDI_MSG_STATUS,		0x9127
	.equ MIDI_MSG_DATA1,		0x9128	; e.g. the controller number
	.equ MIDI_MSG_DATA2,		0x9129	; e.g. the value
	.equ MIDI_MSG_DATA3,		0x912a
; feature-demo.md / ssf-presentation.md "Key DRAM Addresses" -- the demo selection's own writers agree
	.equ DEMO_TIMER_COUNTDOWN,	0x0d2f	; Demo_ResetCountdownTimer sets 15, Demo_SelectEntry_TimerTick counts
	.equ DEMO_TARGET_SONG,		0x1157	; target song index
	.equ DEMO_CURRENT_SONG,		0x1158	; current song index (Demo_SelectEntry_*, clamped to 18)
	.equ DEMO_ACTIVE_ENTRY,		0x28a4	; active demo entry index
	.equ DEMO_CONTROL_FLAGS,	0x28ad	; demo control flags, bit 3 = auto-play
; boot-cpserial-link.md "Rings and transfer-control blocks": the boot-time control-panel serial driver
	.equ BOOTSERIAL_STATE,		0x0f62	; state byte, a raw dispatch-table offset
	.equ BOOTSERIAL_FLAGS,		0x0f64	; bit 0 RX active, 1 TX pending, 2 RX busy, 4 decode-collapse sentinel, 7:6 link mode
	.equ BOOTSERIAL_STATUS,		0x0f6a	; bit 0 RX overflow, 1 TX arbitration failed, 3 frame discarded, 7 done / abort
	.equ BOOTSERIAL_RX_TAIL,	0x0f75	; RX serial ring tail
	.equ BOOTSERIAL_RX_HEAD,	0x0f77	; RX serial ring head
	.equ BOOTSERIAL_RX_RING,	0x0f79	; RX serial ring, 0x5C bytes
	.equ BOOTSERIAL_TX_SEND_INDEX,	0x0fd5	; TX serial ring send index
	.equ BOOTSERIAL_TX_PENDING,	0x0fd7	; TX serial ring pending count
	.equ BOOTSERIAL_TX_RING,	0x0fd9	; TX serial ring, 0x3C bytes
	.equ BOOTSERIAL_RX_TCB,		0x988a	; RX transfer-control block, 0x80 bytes (tail -8, head -4, free count -2)
	.equ BOOTSERIAL_TX_TCB,		0x9914	; TX transfer-control block, same layout
; data-wheel-investigation.md "Dial Callback Table (RAM 0x3EF50-0x3EF6A)"
	.equ DIAL_ENABLE,		0x3ef50	; enable flag (word)
	.equ DIAL_UP_CALLBACK,		0x3ef52	; SetDialUp callback (the XWA component, clockwise)
	.equ DIAL_DOWN_CALLBACK,	0x3ef56	; SetDialDown callback (XWA, counter-clockwise)
	.equ DIAL_UP_EVENT,		0x3ef5a	; SetDialUp event (XBC, e.g. 0x1C00007)
	.equ DIAL_DOWN_EVENT,		0x3ef5e	; SetDialDown event (XBC)
	.equ DIAL_UP_PARAM,		0x3ef62	; SetDialUp parameter (XDE)
	.equ DIAL_DOWN_PARAM,		0x3ef66	; SetDialDown parameter (XDE)
	.equ DIAL_FOCUS,		0x3ef6a	; the UI object the dial is focused on (32-bit)
; boot-sequence.md / hdae5000-homebrew.md: "the flag at 0x03DD04 is the only gate" for the extension ROM
	.equ XAPR_PRESENT_FLAG,		0x3dd04	; 1 = extension ROM (XAPR) detected
; display-subsystem.md "Change Tracking" / "Palette-Based Fade Effects"
	.equ DISPLAY_UPDATE_FLAG,	0x3045e	; non-zero = needs refresh
	.equ PALETTE_INDEX_PREVIOUS,	0x3efa0	; previous palette index, for partial updates
; the song clock -- the firmware exports these three by name (GetAdr_sq_beadt / GetAdr_sqbtof / GetAdr_sqsrtc,
; Hama Function table entries 65 / 64 / 66) for the HD-AE5000's lyric display (hdae5000-filesystem.md
; "Lyric Files").  The timer ISR (INTTR4_CheckAltSeqEnable) and the MIDI-clock path
; (ClkTick_Src3ClickCheck, +4 per clock = 24 ppqn) advance them while SEQ_TRANSPORT_STATE bit 2 is set.
	.equ SEQ_BEAT_TICK,		0x041b	; sq_beadt: tick within the beat, 0..95 (96 per quarter note); wraps into SEQ_BEAT_COUNT
	.equ SEQ_BEAT_COUNT,		0x041c	; sqbtof: beats since the start (word)
	.equ SEQ_TRANSPORT_STATE,	0x0421	; sqsrtc, bit set: 0 start pending, 1-2 running (2 gates the clock), 3 stop requested (the ISR then writes 16), 4 stopped; 0 = idle
