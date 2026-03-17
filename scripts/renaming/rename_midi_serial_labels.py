#!/usr/bin/env python3
"""
rename_midi_serial_labels.py
Rename all LABEL_* symbols in midi_serial_routines.s to meaningful names.

Binary I/O with ASCII encoding is used throughout so that no bytes are
altered by codec translation.  Only ASCII-range content is present in
this file, so the approach is safe.

External references (labels defined here and used by other .s files):
  LABEL_FCF962  -> MIDI_SC0_DISPATCH_TABLE   (function-pointer table entry in EE8C7E)
  LABEL_FCF972  -> MIDI_SC0_TX_DISPATCH      (public TX dispatch, called from many sites)
  LABEL_FCF991  -> MIDI_SC0_ENABLE_TX        (called from FDB7xx RX byte handler)

Usage:
    python3 rename_midi_serial_labels.py          # dry-run (print diff)
    python3 rename_midi_serial_labels.py --apply  # write file in-place
"""

import sys
import re

# ---------------------------------------------------------------------------
# Rename map
# Each entry maps the old LABEL_* name to a new descriptive name.
#
# Naming convention: <FunctionAbbrev>_<ActionOrRole>
#
# Analysis notes per label:
# ---------------------------------------------------------------------------
# MIDI_INIT_SEQUENCES area (FCF130..FCF13C)
#
#   LABEL_FCF130  – loop body inside MIDI_INIT_SEQUENCES: STI word to 0xE1,
#                   compares xwa/xbc, loops back while carry.  This is the
#                   fill-loop tail of the initialisation sequence.
#   LABEL_FCF13A  – isolated `ret`, padding stub after the loop.
#   LABEL_FCF13B  – isolated `ret`, padding stub.
#   LABEL_FCF13C  – isolated `ret`, padding stub.
#
# INTTX0_HANDLER area (FCF15B..FCF1ED)
# Interrupt handler for MIDI TX (serial channel 0 transmit).
# Bits 0-4 of SC0CR (reg 1065) select the baud-rate preset to write to
# SC0BUF.  Each LABEL_FCFxxx block: clear the matching flag bit, check
# whether the "hold" flag (bit 4 of 64848) is set; if set, fall through to
# the common "send 0xFE" path; otherwise write the per-preset byte.
#
#   LABEL_FCF18B  – INTTX0 branch: flag bit 0 was set → clear it, then
#                   send SC0BUF=0xF8 (or fall through to 0xFE hold).
#   LABEL_FCF19C  – INTTX0 branch: flag bit 4 was set → clear it, fall
#                   directly through to send 0xFE (hold active).
#   LABEL_FCF1A0  – INTTX0 common path: hold flag active → send 0xFE to
#                   SC0BUF (MIDI Active-Sense / hold byte).
#   LABEL_FCF1A7  – INTTX0 branch: flag bit 1 was set → send 0xFA (or hold).
#   LABEL_FCF1B8  – INTTX0 branch: flag bit 2 was set → send 0xFB (or hold).
#   LABEL_FCF1C9  – INTTX0 branch: no pending flags → dequeue next byte from
#                   TX FIFO (call 0xEF280E), send it if valid.
#   LABEL_FCF1D7  – INTTX0 common tail: re-read SC0CR flags; if all clear,
#                   check whether TX queue is empty (LABEL_EF2853); if so,
#                   disable TX interrupt (SC0MOD ← 0xFD).
#   LABEL_FCF1ED  – INTTX0 epilogue: restore registers, reti.
#
# MIDI_RX_BYTE_DISPATCHER area (FCF208..FCF28C)
# Top-level RX dispatcher called from INTRX0_HANDLER.
#
#   LABEL_FCF245  – RxDisp branch: status byte (bit 7 set), not SysEx-end
#                   (≤0xF7) → store as running-status (mem 1059), handle
#                   SysEx continuation or reset SysEx state.
#   LABEL_FCF271  – RxDisp: clear running-status and SysEx-in-progress flags,
#                   fall through to common exit.
#   LABEL_FCF27D  – RxDisp: SysEx continuation but unexpected status → reset
#                   SysEx, set SysEx error flag.
#   LABEL_FCF289  – RxDisp: data byte (bit 7 clear) → dispatch to
#                   MIDI_CHANNEL_MESSAGE_DISPATCHER.
#   LABEL_FCF28C  – RxDisp common exit: save context registers, pop all,
#                   ret.
#
# MIDI_SYSTEM_MESSAGE_HANDLER area (FCF221..FCF2A1)
#
#   LABEL_FCF2A0  – SysMsg: early return (Active-Sense handled, or
#                   suppressed message).
#   LABEL_FCF2A1  – SysMsg: not 0xFE → check hold flag (64848 bit 4);
#                   if hold active, return.  Handle 0xFA/0xFB/0xFC.
#   LABEL_FCF2C3  – SysMsg: not 0xFA → check if 0xFC (Stop); if so, set
#                   Stop flag in mem 32565.
#   LABEL_FCF2CC  – SysMsg: common path for clock/transport messages (0xF8,
#                   0xFA, 0xFB, 0xFC); saves byte in D, checks clock-enable
#                   flag (64848 bit 2), dispatches clock or transport logic.
#
# Clock tick processing (0xF8 path inside FCF2CC block):
#
#   LABEL_FCF2E4  – ClkTick: compare tempo accumulator against threshold
#                   (0x70); dispatch to high or low tempo sub-path.
#   LABEL_FCF2F7  – ClkTick: mid-range tempo → multiply accumulator by
#                   fixed factor via muls_sd16w, converge to common update.
#   LABEL_FCF301  – ClkTick: high-tempo path → load alternate timing value
#                   (mem 47062).
#   LABEL_FCF305  – ClkTick: common update: write timing register (TREG5L),
#                   clear tempo accumulator (mem 1066), update master timing
#                   flag (mem 1055).
#   LABEL_FCF319  – ClkTick: check beat counter (mem 1055 bit 2); if set,
#                   advance beat-subdivision counter and queue track event
#                   when bar boundary reached.
#   LABEL_FCF342  – ClkTick / transport: common entry for per-clock actions
#                   on clock-source-dependent counters (mem 1056 flags 0/2).
#   LABEL_FCF369  – ClkTick: source-1 beat counter updated → propagate to
#                   source-1 fine counter (mem 1054).
#   LABEL_FCF374  – ClkTick: source-1 fine counter updated → propagate to
#                   source-1 coarse counter (mem 1057), then jump to 0xF8
#                   tail.
#   LABEL_FCF377  – ClkTick: mem 1056 bit 2 set → advance source-2 click
#                   counter (mem 1047/1048).
#   LABEL_FCF395  – ClkTick: check source-2 fine-beat counter (mem 1054 bit
#                   2); advance source-2 fine counter and queue track event
#                   when boundary reached.
#   LABEL_FCF3C0  – ClkTick: source-2 fine counter matched threshold →
#                   advance coarse counters (mem 1076/1077), check overflow,
#                   clear if exceeded limit.
#   LABEL_FCF3EC  – ClkTick: compute delta for source-2 error accumulator
#                   (mem 1045); update running sum (mem 1120-1124).
#   LABEL_FCF3FD  – ClkTick: store new source-2 snapshot, accumulate delta
#                   into error sums, handle carry into high word.
#   LABEL_FCF419  – ClkTick: write back updated 32-bit error accumulator
#                   (mem 1120).
#   LABEL_FCF41D  – ClkTick: check source-3 counter (mem 1057 bit 2);
#                   advance source-3 click counter (mem 1051), check sync
#                   thresholds (mem 1073).
#   LABEL_FCF452  – ClkTick: source-3 lower sync threshold check (bit 3 of
#                   mem 1073 / mem 1072 compare).
#   LABEL_FCF474  – ClkTick: source-3 click counter overflow (96 ticks) →
#                   advance source-3 beat counter (mem 1052), queue track
#                   event.
#   LABEL_FCF48F  – Transport: handle 0xFC (MIDI Stop) when clock-output
#                   enabled (64850 bit 2): set Stop flags in mem 1056/1054/
#                   1057, queue event pair if sequencer active.
#   LABEL_FCF4AF  – Transport: Stop path with source-1 active (mem 1054
#                   bit 2): set Stop state, queue 0x86 event pair.
#   LABEL_FCF4C1  – Transport: Stop path with source-3 (mem 1057 bit 2):
#                   snapshot source-2 position (mem 1045/1046) into
#                   mem 1078/1079.
#   LABEL_FCF4DE  – common `ret` shared by transport and clock handlers.
#   LABEL_FCF4DF  – Transport: clock-source flags all clear → check clock-
#                   output (64850 bit 2) and handle 0xFA/0xFB when not
#                   recording.
#   LABEL_FCF4F6  – Transport: early return (no relevant clock-output state).
#
# MIDI_START_PLAYBACK_REQUEST / MIDI_RESET_PLAYBACK_STATE area:
#
#   LABEL_FCF509  – StartPlay: return (sequencer already running, skip
#                   reset).
#   LABEL_FCF50A  – StartPlay body: set clock-enable flag (mem 10412 bit 5),
#                   clear tick accumulator (mem 1108); if sequencer not
#                   running, branch to MIDI_RESET_PLAYBACK_STATE.
#   LABEL_FCF556  – ResetPlay: source-2 flags cleared → check source-3
#                   (mem 10407 bit 0); if set, clear source-3 counters.
#   LABEL_FCF56B  – ResetPlay: return.
#
# MIDI_APPLY_STARTUP_TIMING area:
#
#   LABEL_FCF59A  – StartTiming: source-1 timing active (mem 1055 bit 0) →
#                   add offset to mem 1130 as well.
#   LABEL_FCF5A9  – StartTiming: source-2 timing active (mem 1054 bit 0) →
#                   apply offset to source-2 counter (mem 1045).
#   LABEL_FCF5B8  – StartTiming: clear tick buffer (mem 1108), return.
#
# 0xFB (MIDI Continue) path (LABEL_FCF5BE):
#
#   LABEL_FCF5BE  – Continue: set source-3 running (mem 1056/1057 bit 2);
#                   if source-2 also active and position unknown, snapshot
#                   position counters.
#   LABEL_FCF5E4  – Continue: clear source-2 position (mem 1076/1077),
#                   reset source-1 state (mem 10406 bit 0), set source-1
#                   running (mem 1054).
#   LABEL_FCF5F8  – Continue: return.
#
# LABEL_FCF5F9: alternate clock-message path entered when clock-output is
# disabled (64848 bit 2 clear, from MIDI_SYSTEM_MESSAGE_HANDLER):
#
#   LABEL_FCF5F9  – AltClk: handle messages when internal clock disabled:
#                   clear tempo acc, check source flags, handle 0xFC Stop.
#   LABEL_FCF629  – AltClk Stop: set source-1 Stop state, queue 0x86 event.
#   LABEL_FCF63B  – AltClk Stop: set source-3 Stop state, snapshot source-2
#                   position.
#   LABEL_FCF658  – AltClk: return.
#   LABEL_FCF659  – AltClk: clock-source flags all clear → handle 0xFA/0xFB
#                   via separate mini-dispatcher.
#   LABEL_FCF66F  – AltClk: return (no matching message).
#   LABEL_FCF670  – AltClk Start (0xFA): set TX flag bit 1 (mem 1065), arm
#                   TX interrupt (SC0MOD ← 0xDD), jump to FCF50A start path.
#   LABEL_FCF67C  – AltClk Continue (0xFB): if source-3 enabled (mem 10407
#                   bit 0), set TX flag bit 2 (mem 1065), arm TX interrupt,
#                   jump to Continue path.
#   LABEL_FCF68E  – AltClk: return (source-3 not enabled).
#
# MIDI_QUEUE_TRACK_EVENT area:
#
#   LABEL_FCF6B7  – QueueTrack: FIFO had room or was empty → clear tick
#                   counter (mem 1141), return.
#   LABEL_FCF6BF  – QueueTrack: non-FIFO path → use fixed buffer (xix=0x477)
#                   for linear write; advance write pointer, return.
#
# MIDI_QUEUE_EVENT_PAIR area:
#
#   LABEL_FCF70C  – QueuePair: FIFO path, insufficient space → clear tick
#                   counter, return.
#   LABEL_FCF713  – QueuePair: non-FIFO path → linear-buffer write of two
#                   bytes (status + data from mem 1051), advance pointer.
#
# MIDI_QUEUE_EVENT_TO_SEQUENCER area:
#
#   LABEL_FCF79F  – QueueToSeq: sequencer queue depth < 3 (full) → set
#                   overflow flag (mem 1063 bit 2) and increment overflow
#                   counter (mem 47069), return.
#
# MIDI_CHANNEL_MESSAGE_DISPATCHER area:
#
#   LABEL_FCF781  – ChanDisp: running-status byte is 0 (no status) → return
#                   immediately.
#   LABEL_FCF7A8  – ChanDisp: set "overflow" flag (mem 1063 bit 6), save
#                   data byte in C, return.  Reached when event queue is full.
#   LABEL_FCF7AF  – ChanDisp: SysEx-in-progress (mem 1063 bit 6) → override
#                   status with 0xF2 if "substitute" flag set (bit 1), then
#                   route as a three-byte message.
#   LABEL_FCF7B7  – ChanDisp: check sequencer queue depth, determine routing
#                   for three-byte channel messages.
#   LABEL_FCF7D1  – ChanDisp: dispatch three-byte channel event to sequencer
#                   queue (call 0xEF276D ×3), clear SysEx flag.
#   LABEL_FCF7F6  – ChanDisp: return (NoteOn with velocity 0 treated as
#                   NoteOff, queue suppressed).
#   LABEL_FCF7F7  – ChanDisp: queue overflow → set overflow flag, increment
#                   overflow counter.
#
# MIDI_SYSTEM_EXCLUSIVE_HANDLER area:
#
#   LABEL_FCF815  – SysEx: status is 0xF2 (Song Position Pointer) → set
#                   SysEx-continuation bits in mem 1063, store data byte in C.
#   LABEL_FCF81D  – SysEx: status is 0xF3 (Song Select) → queue to
#                   sequencer via MIDI_QUEUE_EVENT_TO_SEQUENCER.
#   LABEL_FCF820  – SysEx: status is 0xF0 (SysEx start) → set SysEx-in-
#                   progress flag (mem 1074), check manufacturer ID.
#   LABEL_FCF834  – SysEx: manufacturer ID matches (0x50/0x41/0x7E) → set
#                   "capture" flag (mem 1074 bit 1), queue first two bytes
#                   to SysEx buffer (LABEL_EF28C9 ×2).
#   LABEL_FCF848  – SysEx: return.
#   LABEL_FCF849  – SysEx: SysEx already in progress (mem 1074 bit 0) →
#                   if capture active and not end-of-SysEx, queue byte.
#   LABEL_FCF85C  – SysEx: return.
#
# Initialisation / SC0 setup area (FCF897..FCF9AB):
#
#   LABEL_FCF897  – SC0Init: top-level SC0 initialisation called during
#                   firmware boot; clears SC0 state, reads COM-SELECT switch,
#                   calls baud-rate setup and SC0 register init.
#   LABEL_FCF8B1  – SC0Init: standard baud-rate table setup: load MIDI
#                   timing constants into mem 47060-47068 for non-FC clock.
#   LABEL_FCF8D8  – SC0Init: alternate baud-rate table setup for FC-based
#                   clock (cps l, 4 matched).
#   LABEL_FCF8F5  – SC0Init: return from baud-rate setup.
#   LABEL_FCF91C  – SC0Init: clear all MIDI RX context-save slots (mem
#                   1080-1104), return.
#   LABEL_FCF940  – SC0Init: enable SC0 registers: set baud rate (BR0CR),
#                   configure SC0MOD/SC0CR, enable TX interrupt (ei 0).
#                   Documented in file header as "SC0 serial port
#                   initialisation".
#   LABEL_FCF961  – SC0Init: isolated `ret` stub (padding / alignment).
#
# FCF962 / FCF972 / FCF991 — public entry points (externally referenced):
#
#   LABEL_FCF962  – Dispatch-table block: 16-byte table of four function
#                   pointers (entries for MIDI/PC/MAC port dispatcher).
#                   Referenced as a .long in the global port-dispatcher
#                   jump-table at EE8C7E.
#   LABEL_FCF972  – Public TX dispatch wrapper: saves all registers, checks
#                   COM_SELECT (mem 47072); if 0 (MIDI), calls internal MIDI
#                   TX enable; otherwise calls FDB903 (PC/MAC path). Restores
#                   registers, returns.  Called from many sites that need to
#                   initiate a MIDI/serial transmit burst.
#   LABEL_FCF985  – SC0TxDisp: non-MIDI path within FCF972 → call FDB903
#                   (PC/MAC transmit handler).
#   LABEL_FCF989  – SC0TxDisp: restore registers and return (common epilogue
#                   of FCF972).
#   LABEL_FCF991  – Public TX enable entry: called from RX byte handler when
#                   a queued reply needs to be sent. Checks whether MIDI mode
#                   is active (mem 1140 == 0x55); if so, clears pending
#                   flags and calls LABEL_EF286B to arm TX interrupt.
#                   Otherwise arms TX interrupt directly (SC0MOD ← 0xDD).
#   LABEL_FCF9A2  – SC0TxEnable: "MIDI active" path → call LABEL_EF286B,
#                   clear TX-state register (mem 1065).
#   LABEL_FCF9AB  – SC0TxEnable: restore interrupt state (pop_sr), return.
# ---------------------------------------------------------------------------

RENAMES = {
    # MIDI_INIT_SEQUENCES helpers
    "LABEL_FCF130": "MidiInit_FillLoop",
    "LABEL_FCF13A": "MidiInit_Stub1",
    "LABEL_FCF13B": "MidiInit_Stub2",
    "LABEL_FCF13C": "MidiInit_Stub3",

    # INTTX0_HANDLER branches
    "LABEL_FCF18B": "IntTx0_FlagBit0Branch",
    "LABEL_FCF19C": "IntTx0_FlagBit4Branch",
    "LABEL_FCF1A0": "IntTx0_SendHoldByte",
    "LABEL_FCF1A7": "IntTx0_FlagBit1Branch",
    "LABEL_FCF1B8": "IntTx0_FlagBit2Branch",
    "LABEL_FCF1C9": "IntTx0_DequeueAndSend",
    "LABEL_FCF1D7": "IntTx0_CheckQueueEmpty",
    "LABEL_FCF1ED": "IntTx0_Epilogue",

    # MIDI_RX_BYTE_DISPATCHER branches
    "LABEL_FCF245": "RxDisp_StatusByte",
    "LABEL_FCF271": "RxDisp_ClearSysExState",
    "LABEL_FCF27D": "RxDisp_SysExError",
    "LABEL_FCF289": "RxDisp_DataByteDispatch",
    "LABEL_FCF28C": "RxDisp_SaveContextAndReturn",

    # MIDI_SYSTEM_MESSAGE_HANDLER branches
    "LABEL_FCF2A0": "SysMsg_Return",
    "LABEL_FCF2A1": "SysMsg_NotActiveSense",
    "LABEL_FCF2C3": "SysMsg_CheckStop",
    "LABEL_FCF2CC": "SysMsg_ClockTransportDispatch",

    # Clock-tick sub-handlers (0xF8 path)
    "LABEL_FCF2E4": "ClkTick_TempoThresholdCheck",
    "LABEL_FCF2F7": "ClkTick_MidRangeTempoMul",
    "LABEL_FCF301": "ClkTick_HighTempoLoad",
    "LABEL_FCF305": "ClkTick_WriteTimingReg",
    "LABEL_FCF319": "ClkTick_BeatSubdivCheck",
    "LABEL_FCF342": "ClkTick_PerClockCounters",
    "LABEL_FCF369": "ClkTick_Src1FineUpdate",
    "LABEL_FCF374": "ClkTick_Src1CoarseUpdate",
    "LABEL_FCF377": "ClkTick_Src2ClickIncrement",
    "LABEL_FCF395": "ClkTick_Src2FineBeatCheck",
    "LABEL_FCF3C0": "ClkTick_Src2CoarseOverflow",
    "LABEL_FCF3EC": "ClkTick_Src2ErrorDelta",
    "LABEL_FCF3FD": "ClkTick_Src2ErrorAccumulate",
    "LABEL_FCF419": "ClkTick_Src2ErrorWriteback",
    "LABEL_FCF41D": "ClkTick_Src3ClickCheck",
    "LABEL_FCF452": "ClkTick_Src3LowerSyncCheck",
    "LABEL_FCF474": "ClkTick_Src3OverflowQueue",
    "LABEL_FCF48F": "Transport_StopHandler",
    "LABEL_FCF4AF": "Transport_StopSrc1QueueEvent",
    "LABEL_FCF4C1": "Transport_StopSrc3Snapshot",
    "LABEL_FCF4DE": "Transport_Return",
    "LABEL_FCF4DF": "Transport_NoClockSourcePath",
    "LABEL_FCF4F6": "Transport_NoClockReturn",

    # MIDI_START_PLAYBACK_REQUEST helpers
    "LABEL_FCF509": "StartPlay_Return",
    "LABEL_FCF50A": "StartPlay_Body",

    # MIDI_RESET_PLAYBACK_STATE helpers
    "LABEL_FCF556": "ResetPlay_Src3Check",
    "LABEL_FCF56B": "ResetPlay_Return",

    # MIDI_APPLY_STARTUP_TIMING helpers
    "LABEL_FCF59A": "StartTiming_Src1Adjust",
    "LABEL_FCF5A9": "StartTiming_Src2Adjust",
    "LABEL_FCF5B8": "StartTiming_ClearAndReturn",

    # MIDI Continue (0xFB) path
    "LABEL_FCF5BE": "Continue_SetRunning",
    "LABEL_FCF5E4": "Continue_ClearPositionAndSetSrc1",
    "LABEL_FCF5F8": "Continue_Return",

    # Alternate clock path (clock-output disabled)
    "LABEL_FCF5F9": "AltClk_DisabledClockPath",
    "LABEL_FCF629": "AltClk_StopSrc1Queue",
    "LABEL_FCF63B": "AltClk_StopSrc3Snapshot",
    "LABEL_FCF658": "AltClk_Return",
    "LABEL_FCF659": "AltClk_NoSrcFlagPath",
    "LABEL_FCF66F": "AltClk_NoMatchReturn",
    "LABEL_FCF670": "AltClk_StartArmTx",
    "LABEL_FCF67C": "AltClk_ContinueArmTx",
    "LABEL_FCF68E": "AltClk_Src3DisabledReturn",

    # MIDI_QUEUE_TRACK_EVENT helpers
    "LABEL_FCF6B7": "QueueTrack_FifoWriteOrClear",
    "LABEL_FCF6BF": "QueueTrack_LinearBufWrite",

    # MIDI_QUEUE_EVENT_PAIR helpers
    "LABEL_FCF70C": "QueuePair_FifoFullReturn",
    "LABEL_FCF713": "QueuePair_LinearBufWrite",

    # MIDI_QUEUE_EVENT_TO_SEQUENCER helpers
    "LABEL_FCF79F": "QueueToSeq_OverflowFlag",

    # MIDI_CHANNEL_MESSAGE_DISPATCHER helpers
    "LABEL_FCF781": "ChanDisp_NoStatusReturn",
    "LABEL_FCF7A8": "ChanDisp_QueueOverflow",
    "LABEL_FCF7AF": "ChanDisp_SysExInProgress",
    "LABEL_FCF7B7": "ChanDisp_ThreeByteRoute",
    "LABEL_FCF7D1": "ChanDisp_EnqueueThreeBytes",
    "LABEL_FCF7F6": "ChanDisp_NoteOnZeroReturn",
    "LABEL_FCF7F7": "ChanDisp_QueueOverflowSet",

    # MIDI_SYSTEM_EXCLUSIVE_HANDLER helpers
    "LABEL_FCF815": "SysEx_SongPositionSetup",
    "LABEL_FCF81D": "SysEx_SongSelectQueue",
    "LABEL_FCF820": "SysEx_StartByte",
    "LABEL_FCF834": "SysEx_CaptureManufacturerId",
    "LABEL_FCF848": "SysEx_Return",
    "LABEL_FCF849": "SysEx_InProgressByte",
    "LABEL_FCF85C": "SysEx_InProgressReturn",

    # SC0 initialisation chain
    "LABEL_FCF897": "SC0Init_Entry",
    "LABEL_FCF8B1": "SC0Init_StandardBaudTable",
    "LABEL_FCF8D8": "SC0Init_AlternateBaudTable",
    "LABEL_FCF8F5": "SC0Init_BaudTableReturn",
    "LABEL_FCF91C": "SC0Init_ClearContextSlots",
    "LABEL_FCF940": "SC0Init_EnableRegisters",
    "LABEL_FCF961": "SC0Init_PaddingStub",

    # Externally referenced public entry points
    # LABEL_FCF962: referenced as .long in global port-dispatcher table EE8C7E
    "LABEL_FCF962": "MIDI_SC0_DISPATCH_TABLE",
    # LABEL_FCF972: called from many sites to initiate a MIDI/serial TX burst
    "LABEL_FCF972": "MIDI_SC0_TX_DISPATCH",
    "LABEL_FCF985": "SC0TxDisp_NonMidiPath",
    "LABEL_FCF989": "SC0TxDisp_RestoreAndReturn",
    # LABEL_FCF991: called from RX byte handler to arm TX interrupt for reply
    "LABEL_FCF991": "MIDI_SC0_ENABLE_TX",
    "LABEL_FCF9A2": "SC0TxEnable_MidiActivePath",
    "LABEL_FCF9AB": "SC0TxEnable_Return",
}


def build_pattern(old_names):
    """Return a compiled regex that matches any of the old symbol names."""
    # Sort longest-first to avoid partial matches (all are unique hex strings,
    # but defensive ordering costs nothing).
    escaped = [re.escape(n) for n in sorted(old_names, key=len, reverse=True)]
    return re.compile(r'\b(' + '|'.join(escaped) + r')\b')


def apply_renames(src_bytes, renames):
    """
    Replace every occurrence of each old symbol name in src_bytes with its
    new name.  src_bytes must be a bytes object.  Returns a bytes object.
    """
    text = src_bytes.decode('ascii')
    pattern = build_pattern(renames.keys())
    result = pattern.sub(lambda m: renames[m.group(0)], text)
    return result.encode('ascii')


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Rename LABEL_* symbols in midi_serial_routines.s")
    parser.add_argument(
        '--apply', action='store_true',
        help="Write the renamed content back to the file (default: dry-run)")
    args = parser.parse_args()

    target = (
        "/mnt/shared/kn5000-roms-disasm/maincpu/midi_serial_routines.s"
    )

    with open(target, 'rb') as fh:
        original = fh.read()

    renamed = apply_renames(original, RENAMES)

    if args.apply:
        with open(target, 'wb') as fh:
            fh.write(renamed)
        print(f"Applied {len(RENAMES)} renames to {target}")
    else:
        # Dry-run: show a unified diff
        import difflib
        old_lines = original.decode('ascii').splitlines(keepends=True)
        new_lines = renamed.decode('ascii').splitlines(keepends=True)
        diff = difflib.unified_diff(
            old_lines, new_lines,
            fromfile=target + " (original)",
            tofile=target + " (renamed)",
        )
        sys.stdout.writelines(diff)
        print(f"\n[dry-run] {len(RENAMES)} symbols would be renamed.")


if __name__ == '__main__':
    main()
