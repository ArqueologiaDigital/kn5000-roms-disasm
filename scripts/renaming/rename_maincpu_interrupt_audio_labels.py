#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in maincpu interrupt handlers and audio routines.

Covers six function groups in kn5000_v10_program.s:
  1. INTTR4_HANDLER  (EF0E21-EF1235)  — Timer 4 interrupt: tick counters, MIDI clock sync
  2. RhythmBuf_DispatchEvent (EF1525-EF17F3) — Rhythm buffer event dispatch & helpers
  3. INTT3_HANDLER   (EF1965-EF1B9C)  — Timer 3 interrupt: cooperative task scheduler
  4. Audio_Lock_Acquire (EF1FF6-EF23E5) — Audio lock/mutex & message-passing primitives
  5. Stop_and_Clear_8bit_Timer_3 area (EF23E8-EF25AC) — Timer cleanup & seq buffer ops
  6. SeqAlt1_ReadByte area (EF2810-EF2A25) — Sequencer Alt1 buffer operations

Each rename was verified by analysing the routine's code, register usage, called
functions, branch targets, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s — it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source.
#
#   EF0E21-EF1235  INTTR4_HANDLER: Timer 4 tick counters, MIDI sync, sequencer
#   EF1525-EF17F3  Rhythm/Seq buffer dispatch, timing snapshot, AltSeq timing
#   EF1965-EF1B9C  INTT3_HANDLER: cooperative multi-task scheduler
#   EF1FF6-EF23E5  Audio lock/mutex, message send/receive, task priority
#   EF23E8-EF25AC  Timer 3 start/stop, SeqBuf and TempoRingBuf operations
#   EF2810-EF2A25  SeqAlt1 buffer read/write/init/check operations
# ---------------------------------------------------------------------------

RENAMES = [
    # ==================================================================
    # INTTR4_HANDLER (EF0E21-EF1235) — Timer 4 interrupt handler
    # Increments multiple tick counters gated by enable bits, manages
    # MIDI clock synchronisation, and computes tempo accumulator deltas.
    # ==================================================================

    ('LABEL_EF0E37', 'INTTR4_TickWrapped',
     'Tick counter wrapped past 0x60: check main enable bit'),

    ('LABEL_EF0E41', 'INTTR4_CheckSyncEnable',
     'External sync disabled: check sync counter 2 enable (bit 2 of 1055)'),

    ('LABEL_EF0E70', 'INTTR4_CheckMetroEnable',
     'Check metronome counter enable (bit 2 of 1056)'),

    ('LABEL_EF0E6B', 'INTTR4_SyncCounter2_NoWrap',
     'Sync counter 2 did not wrap: store incremented value'),

    ('LABEL_EF0E6F', 'INTTR4_SyncCounter2_Done',
     'Sync counter 2 processing complete: restore SR'),

    ('LABEL_EF0E8A', 'INTTR4_MetroCounter_Store',
     'Store incremented metronome tick counter'),

    ('LABEL_EF0E8F', 'INTTR4_CheckSeqEnable',
     'Check sequencer tick counter enable (bit 2 of 1054)'),

    ('LABEL_EF0EB3', 'INTTR4_SeqTick_CheckBeat',
     'Seq tick wrapped: check beat counter vs beats-per-bar'),

    ('LABEL_EF0EDF', 'INTTR4_CheckAltSeqEnable',
     'Check alt-sequencer counter enable (bit 2 of 1057)'),

    ('LABEL_EF0F04', 'INTTR4_MetroPhaseSync',
     'Metro enabled: synchronise seq/altseq phase flags'),

    ('LABEL_EF0F19', 'INTTR4_MetroSync_CheckAltSeq',
     'Check alt-seq needs phase sync from metronome'),

    ('LABEL_EF0F28', 'INTTR4_MetroSync_Done',
     'Metro phase sync done: jump to beat boundary check'),

    ('LABEL_EF0F2A', 'INTTR4_SeqAutoStart',
     'Seq running (bit 7 of 1054): check for auto-start trigger'),

    ('LABEL_EF0F7A', 'INTTR4_SeqAutoStart_Skip',
     'Auto-start conditions not met: skip MIDI dispatch'),

    ('LABEL_EF0F7C', 'INTTR4_SeqInit_SetEnable',
     'Seq not running: initialise enable flags (set bit 7 + bit 2)'),

    ('LABEL_EF0F81', 'INTTR4_MetroBeat_Check',
     'Check metronome beat boundary (bit 3 of 1056)'),

    ('LABEL_EF0FA0', 'INTTR4_MetroBeat_OnBeat',
     'Metronome on beat boundary: set flag and send MIDI if needed'),

    ('LABEL_EF0FC5', 'INTTR4_SeqBeat_Check',
     'Check sequencer beat boundary (bit 3 of 1054)'),

    ('LABEL_EF0FD0', 'INTTR4_AltSeqBeat_Check',
     'Check alt-sequencer beat boundary (bit 3 of 1057)'),

    ('LABEL_EF0FEB', 'INTTR4_MetroQuarter_Check',
     'Check metronome quarter-tick MIDI (bit 2 of 1056, tick & 3 == 0)'),

    ('LABEL_EF100E', 'INTTR4_SeqAccum_Update',
     'Update sequencer tempo accumulator (fractional tick tracking)'),

    ('LABEL_EF1028', 'INTTR4_SeqAccum_PositiveDelta',
     'Positive delta: add to sub-tick and tick accumulators'),

    ('LABEL_EF1044', 'INTTR4_SeqAccum_NoWrap',
     'Accumulator did not wrap past 0x60: store result'),

    ('LABEL_EF1048', 'INTTR4_SeqAccum_Done',
     'Seq accumulator update complete: restore SR'),

    ('LABEL_EF104B', 'INTTR4_SeqAccum_Reset',
     'Seq not running: clear all accumulators to zero'),

    ('LABEL_EF1061', 'INTTR4_AltSeqAccum_Update',
     'Update alt-sequencer tempo accumulator'),

    ('LABEL_EF108E', 'INTTR4_AltSeqSync_Check',
     'Check alt-seq sync trigger (bit 0 of 1073)'),

    ('LABEL_EF10B1', 'INTTR4_FadeDelay_Check',
     'Decrement fade delay counter if non-zero'),

    ('LABEL_EF10BC', 'INTTR4_SyncAccum_Update',
     'Update external sync tempo accumulator (mirror of seq accum logic)'),

    ('LABEL_EF10D6', 'INTTR4_SyncAccum_PositiveDelta',
     'Positive delta for sync accumulator'),

    ('LABEL_EF10F2', 'INTTR4_SyncAccum_NoWrap',
     'Sync accumulator did not wrap: store result'),

    ('LABEL_EF10F6', 'INTTR4_SyncAccum_Done',
     'Sync accumulator update complete: restore SR'),

    ('LABEL_EF10F9', 'INTTR4_SyncAccum_Reset',
     'Sync not running: clear sync accumulators to zero'),

    ('LABEL_EF110F', 'INTTR4_Return',
     'Restore registers and RETI'),

    # --- INTTR4 helper: TempoRingBuf_Write (single byte) ---
    ('LABEL_EF1113', 'TempoRingBuf_Write',
     'Write one byte to tempo ring buffer at XIY (0x01E753); dequeue if flag 0 of 1113 clear'),

    ('LABEL_EF1136', 'TempoRingBuf_Write_Dequeue',
     'Dequeue path: clear pending count and return'),

    ('LABEL_EF113F', 'TempoRingBuf_Write_Enqueue',
     'Enqueue path: write byte at write pointer and advance'),

    ('LABEL_EF1155', 'TempoRingBuf_Write_Return',
     'Return from TempoRingBuf_Write'),

    # --- INTTR4 helper: TempoRingBuf_WritePair (A + tick value) ---
    ('LABEL_EF1156', 'TempoRingBuf_WritePair',
     'Write command A + current tick (1051) as 2-byte pair to tempo ring buffer'),

    ('LABEL_EF1194', 'TempoRingBuf_WritePair_ClearPending',
     'Clear pending count after dequeue and return'),

    ('LABEL_EF119B', 'TempoRingBuf_WritePair_Enqueue',
     'Enqueue path: write A + tick as 2-byte pair and advance write pointer'),

    # --- INTTR4 sub-tick mode (external clock, bit 2 of 64848) ---
    ('LABEL_EF11C0', 'INTTR4_SubTick_Mode',
     'External clock mode: increment sub-tick counters by alignment step'),

    ('LABEL_EF11D6', 'INTTR4_SubTick_MetroInc',
     'Sub-tick mode: increment metronome counter if enabled'),

    ('LABEL_EF11EC', 'INTTR4_SubTick_SeqInc',
     'Sub-tick mode: increment sequencer counter if enabled'),

    ('LABEL_EF1202', 'INTTR4_SubTick_PhaseSync',
     'Sub-tick mode: synchronise metro phase flags (mirror of normal path)'),

    ('LABEL_EF1217', 'INTTR4_SubTick_PhaseSync_AltSeq',
     'Sub-tick mode: sync alt-seq phase flags and jump to accum update'),

    ('LABEL_EF1226', 'INTTR4_SubTick_ToAccum',
     'Sub-tick mode: jump to accumulator update path'),

    # --- Data tables after INTTR4 ---
    ('LABEL_EF122A', 'INTTR4_BytecodeSnippet',
     'Inline bytecode fragment (called externally, 11 bytes)'),

    ('LABEL_EF1235', 'Seq_InitFuncTable',
     'Table of 4 function pointers for sequencer init dispatch'),

    # ==================================================================
    # RhythmBuf_DispatchEvent area (EF1525-EF17F3) — Rhythm buffer
    # event dispatch, MIDI ring buffer scanning, timing snapshots
    # ==================================================================

    # --- RhythmBuf_DispatchEvent internal labels ---
    ('LABEL_EF1535', 'RhythmBuf_Dispatch_NonNoteOn',
     'Event is not note-on: call non-note handler'),

    ('LABEL_EF1539', 'RhythmBuf_Dispatch_UpdateReadPos',
     'Update ring buffer read position and accumulate byte count'),

    ('LABEL_EF1550', 'RhythmBuf_Dispatch_NoWrap',
     'Read position did not wrap: add delta directly'),

    # --- RhythmBuf MIDI event scanner (EF1556) ---
    ('LABEL_EF1556', 'RhythmBuf_ScanForNoteOn',
     'Scan rhythm ring buffer for next note-on event; returns CF=0 if note-on found'),

    ('LABEL_EF155C', 'RhythmBuf_Scan_SkipNonStatus',
     'Skip bytes without bit 7 set (data bytes) in scan loop'),

    ('LABEL_EF156D', 'RhythmBuf_Scan_FoundStatus',
     'Found status byte: save position, extract status nibble'),

    ('LABEL_EF1577', 'RhythmBuf_Scan_CheckNext',
     'Check next status byte for note-on priority decision'),

    ('LABEL_EF1596', 'RhythmBuf_Scan_Advance',
     'Advance scan pointer with wrap check'),

    ('LABEL_EF15A0', 'RhythmBuf_Scan_EndReached',
     'End of buffer reached: check if last status was note-on'),

    ('LABEL_EF15A5', 'RhythmBuf_Scan_ReturnNoteOn',
     'Return with CF=0: note-on event found at saved position'),

    ('LABEL_EF15AB', 'RhythmBuf_Scan_ReturnOther',
     'Return with CF=1: non-note-on event; clear sync flag'),

    ('LABEL_EF15B4', 'RhythmBuf_Scan_Return',
     'Return from ring buffer scan'),

    # --- Seq event buffer processor (EF15B5) ---
    ('LABEL_EF15B5', 'SeqEvt_ProcessBuffer',
     'Process sequencer event buffer at 0x01F271; dispatch note-on vs other'),

    ('LABEL_EF15BE', 'SeqEvt_ProcessBuffer_Main',
     'Main seq event processing loop entry'),

    ('LABEL_EF15C3', 'SeqEvt_ProcessLoop',
     'Loop: read/write pointers differ, dispatch next event'),

    ('LABEL_EF15D6', 'SeqEvt_Dispatch_NonNoteOn',
     'Event is not note-on: call alternative handler'),

    ('LABEL_EF15DA', 'SeqEvt_UpdateReadPos',
     'Update read position and accumulate consumed byte count'),

    ('LABEL_EF15F0', 'SeqEvt_UpdateReadPos_NoWrap',
     'Read position did not wrap: add delta directly'),

    ('LABEL_EF15F5', 'SeqEvt_ProcessDone',
     'Read == write: buffer empty, return'),

    # --- Seq event MIDI scanner (EF15F6) ---
    ('LABEL_EF15F6', 'SeqEvt_ScanForNoteOn',
     'Scan seq event buffer for note-on; returns CF=0 if found'),

    ('LABEL_EF15FC', 'SeqEvt_Scan_SkipData',
     'Skip data bytes (bit 7 clear) in scan loop'),

    ('LABEL_EF160D', 'SeqEvt_Scan_FoundStatus',
     'Found status byte: save position, extract nibble'),

    ('LABEL_EF1617', 'SeqEvt_Scan_CheckNext',
     'Check next status for note-on priority'),

    ('LABEL_EF1636', 'SeqEvt_Scan_Advance',
     'Advance scan with wrap at 0xFF boundary'),

    ('LABEL_EF1640', 'SeqEvt_Scan_EndReached',
     'End of buffer: check last status for note-on'),

    ('LABEL_EF1645', 'SeqEvt_Scan_ReturnNoteOn',
     'Return CF=0: note-on event found'),

    ('LABEL_EF164B', 'SeqEvt_Scan_ReturnOther',
     'Return CF=1: non-note-on event; clear sync flag'),

    ('LABEL_EF1654', 'SeqEvt_Scan_Return',
     'Return from seq event scan'),

    # --- Small helpers called from Seq_EventProcessingTick ---
    ('LABEL_EF1655', 'SeqEvt_CallTimingHelper',
     'Call timing helper at F43741 and return'),

    ('LABEL_EF165A', 'SeqEvt_ProcessTimedEvents',
     'Check timed-event flag (bit 5 of 10412): run timed dispatch if set'),

    ('LABEL_EF1674', 'SeqEvt_ProcessTimedEvents_Idle',
     'Timed event flag not set: call timing helper and return'),

    # --- Tempo ring buffer consumer (EF1679) ---
    ('LABEL_EF1679', 'TempoRingBuf_Consume',
     'Consume all pending bytes from tempo ring buffer (0x01E753)'),

    ('LABEL_EF1683', 'TempoRingBuf_Consume_Loop',
     'Loop: read and dispatch bytes until pending count exhausted'),

    ('LABEL_EF1695', 'TempoRingBuf_Consume_Done',
     'All consumed: clear pending count and flag, restore interrupts'),

    # --- Inline bytecode (EF16A4) ---
    ('LABEL_EF16A4', 'TempoRingBuf_BytecodeSnippet',
     'Inline bytecode fragment for tempo ring buffer processing (37 bytes)'),

    # --- Tempo ring buffer dequeue helper (EF16C7) ---
    ('LABEL_EF16C7', 'TempoRingBuf_DequeueOne',
     'Dequeue one byte from tempo ring buffer: read from read pointer, decrement count'),

    ('LABEL_EF16EA', 'TempoRingBuf_DequeueOne_Done',
     'Dequeue complete: restore registers and return'),

    # --- Event expiry checker (EF16EE) ---
    ('LABEL_EF16EE', 'SeqEvt_CheckExpiry',
     'Clear bit 7 of 1058; check/decrement expiry counter at 59836'),

    ('LABEL_EF1710', 'SeqEvt_CheckExpiry_Return',
     'Return from expiry check'),

    # --- Seq timing snapshot (EF1711) ---
    ('LABEL_EF1711', 'SeqTiming_Snapshot',
     'Snapshot seq accumulators (1120/1122) into timing state (1118/1117)'),

    ('LABEL_EF172F', 'SeqTiming_Snapshot_CheckFrac',
     'Check fractional accumulator vs limit'),

    ('LABEL_EF173A', 'SeqTiming_Snapshot_PostSnap',
     'Accumulators snapshotted: check for overflow handling'),

    ('LABEL_EF174E', 'SeqTiming_Snapshot_CheckFracOverflow',
     'Check fractional overflow and call handler if needed'),

    ('LABEL_EF1758', 'SeqTiming_Snapshot_Return',
     'Return from timing snapshot'),

    # --- Sync timing snapshot (EF1759) ---
    ('LABEL_EF1759', 'SyncTiming_Snapshot',
     'Snapshot sync accumulators (1136/1133) into timing state (1134/1132)'),

    ('LABEL_EF1777', 'SyncTiming_Snapshot_CheckFrac',
     'Check sync fractional accumulator vs limit'),

    ('LABEL_EF1782', 'SyncTiming_Snapshot_PostSnap',
     'Sync accumulators snapshotted: check for overflow'),

    ('LABEL_EF1796', 'SyncTiming_Snapshot_CheckFracOverflow',
     'Check sync fractional overflow and call handler'),

    ('LABEL_EF17A0', 'SyncTiming_Snapshot_Return',
     'Return from sync timing snapshot'),

    # --- Sequencer full init (EF17A1) ---
    ('LABEL_EF17A1', 'Seq_FullInit',
     'Full sequencer initialisation: reset all buffers, states, and subsystems'),

    # --- Stubs in init table ---
    ('LABEL_EF17F1', 'Seq_InitStub_Nop1',
     'Init table stub: immediate return (nop)'),

    ('LABEL_EF17F2', 'Seq_InitStub_Nop2',
     'Init table stub: immediate return (nop)'),

    ('LABEL_EF17F3', 'Seq_InitStub_Nop3',
     'Init table stub: immediate return (nop)'),

    # ==================================================================
    # INTT3_HANDLER (EF1965-EF1B9C) — Timer 3 interrupt handler
    # Implements a cooperative multi-task scheduler using linked lists
    # of task control blocks (TCBs) at 0x0487 (12 bytes each).
    # ==================================================================

    ('LABEL_EF1977', 'TaskSched_Init',
     'Initialise task scheduler: set stack, clear state, init TCB lists'),

    ('LABEL_EF1994', 'TaskSched_InitPriorityQueues',
     'Init 3 priority-level ready queues with sentinel pointers'),

    ('LABEL_EF19A8', 'TaskSched_InitTCBFields',
     'Init TCB fields: clear state/priority/counter for 5 task slots'),

    ('LABEL_EF19C6', 'TaskSched_InitTimerSlots',
     'Init timer wait slots with 0xFFFFFFFF (inactive sentinel)'),

    ('LABEL_EF19E6', 'TaskSched_InitExtQueues',
     'Init extended ready queues with sentinel pointers'),

    ('LABEL_EF1A07', 'TaskSched_InitExtQueues2',
     'Init second set of extended queues with sentinel pointers'),

    ('LABEL_EF1A1E', 'TaskSched_InitFreeList',
     'Build free-list of timer wait slots as doubly-linked list'),

    ('LABEL_EF1A38', 'TaskSched_LinkFreeSlots',
     'Link each free timer slot into the free list chain'),

    ('LABEL_EF1A5A', 'TaskSched_InitLockQueues',
     'Init lock wait queues (5 entries) with sentinel pointers'),

    ('LABEL_EF1A6C', 'TaskSched_InitMsgQueues',
     'Init message wait queues (5 entries) with sentinel pointers'),

    ('LABEL_EF1A86', 'TaskSched_PostInit',
     'Post-init: register idle task, configure Timer 3, enable scheduler'),

    ('LABEL_EF1AB7', 'TaskSched_AllIdle',
     'All tasks idle: enable interrupts and halt (infinite loop)'),

    ('LABEL_EF1ABE', 'TaskSched_HaltLoop',
     'Infinite halt loop: wait for interrupt to wake scheduler'),

    ('LABEL_EF1AC0', 'TaskSched_Dispatch',
     'Main dispatch: check timer expiries, scan priority queues, switch context'),

    ('LABEL_EF1AE9', 'TaskSched_ScanPriorityQueues',
     'Scan 3 priority levels for a ready task'),

    ('LABEL_EF1AF0', 'TaskSched_ScanQueue_Loop',
     'Per-queue: check if head != sentinel (task ready)'),

    ('LABEL_EF1AFE', 'TaskSched_FoundReadyTask',
     'Ready task found: set as current, restore its stack and resume'),

    ('LABEL_EF1B11', 'TaskSched_ReturnToDispatch',
     'Resume scheduler dispatch (restore all regs from stack, return)'),

    ('LABEL_EF1B1A', 'TaskSched_TimerTick',
     'Timer tick: increment tick count, check timer wait slots for expiry'),

    ('LABEL_EF1B30', 'TaskSched_CheckTimerSlot',
     'Check one timer slot: if countdown reached 0, fire callback'),

    ('LABEL_EF1B47', 'TaskSched_TimerSlot_Skip',
     'Timer slot inactive or not expired: advance to next slot'),

    ('LABEL_EF1B5E', 'TaskSched_TimerSlot_Fire',
     'Timer slot expired: reload period, push return addr, jump to callback'),

    ('LABEL_EF1B6F', 'INTT3_CheckNesting',
     'Timer 3 ISR entry: check nesting depth (1475), defer if > 1'),

    ('LABEL_EF1B83', 'INTT3_EnterScheduler',
     'Nesting depth == 1: enter scheduler, save full register set'),

    # ==================================================================
    # INTT3 context: Screen group / task management helpers
    # These are part of the cooperative scheduler infrastructure,
    # managing task TCBs through linked-list operations.
    # ==================================================================

    ('LABEL_EF1C46', 'TaskSched_GetCurrentGroup',
     'Get current screen group ID from active TCB; returns 0 if nested'),

    ('LABEL_EF1C5C', 'TaskSched_GetCurrentGroup_Nested',
     'Nested (tick count > 0): return 0'),

    ('LABEL_EF1C5F', 'TaskSched_YieldToQueue',
     'Yield current task: unlink from ready queue, relink to target queue'),

    ('LABEL_EF1CA8', 'TaskSched_YieldToQueue_NoBlock',
     'Non-blocking yield variant: unlink and relink without full context save'),

    ('LABEL_EF1CE7', 'TaskSched_YieldToQueue_NoBlock_Return',
     'Return from non-blocking yield (queue was empty, nothing to do)'),

    ('LABEL_EF1CEC', 'TaskSched_Resume',
     'Resume a suspended task: unlink from wait queue, relink to ready queue'),

    ('LABEL_EF1D1C', 'TaskSched_Resume_DecrementWait',
     'Task has wait counter > 0: decrement and return without resuming'),

    ('LABEL_EF1D24', 'TaskSched_WakeBySlotID',
     'Wake task by slot ID: find TCB, transition from state 3 to 4 (ready)'),

    ('LABEL_EF1D68', 'TaskSched_WakeBySlotID_Pending',
     'Task not in state 3 (waiting): increment pending wake counter'),

    ('LABEL_EF1DAB', 'TaskSched_WakeInline_Return',
     'Return from inline wake variant'),

    ('LABEL_EF1DB0', 'TaskSched_WakeInline_Pending',
     'Inline wake: task not waiting, increment pending counter'),

    ('LABEL_EF1DD4', 'TaskSched_SignalEvent',
     'Signal event to priority queue: unlink head, relink to ready queue'),

    ('LABEL_EF1E01', 'TaskSched_SignalEvent_Unlink',
     'Unlink task from event wait queue and relink to ready queue'),

    ('LABEL_EF1E3C', 'TaskSched_SignalEvent_NoBlock',
     'Non-blocking signal variant: unlink head of event queue, relink to ready'),

    ('LABEL_EF1E69', 'TaskSched_SignalEvent_NoBlock_Unlink',
     'Non-blocking: perform the actual unlink/relink of task from event queue'),

    ('LABEL_EF1EA7', 'TaskSched_WaitForEvent',
     'Wait for event: move current task to event wait queue, yield to scheduler'),

    ('LABEL_EF1EC4', 'TaskSched_WaitForEvent_Block',
     'Event not pending: unlink current task, link to event wait queue, yield'),

    # ==================================================================
    # Audio_Lock_Acquire area (EF1FF6-EF23E5) — lock/mutex primitives
    # and message-passing for inter-task communication
    # ==================================================================

    # --- Audio_Lock_Release internals ---
    ('LABEL_EF1F3F', 'AudioLock_Release_NoWaiter_Done',
     'No waiter in queue, counter incremented (or saturated): return to dispatch'),

    ('LABEL_EF1F42', 'AudioLock_Release_WakeWaiter',
     'Waiter found in lock queue: unlink, mark ready, relink to run queue'),

    ('LABEL_EF1FAA', 'AudioLock_Release_NB_Saturated',
     'Non-blocking release: counter already at max, skip increment'),

    ('LABEL_EF1FB0', 'AudioLock_Release_NB_WakeWaiter',
     'Non-blocking release: wake first waiter from lock queue'),

    # --- Audio_Lock_Acquire internals ---
    ('LABEL_EF200C', 'AudioLock_Acquire_Block',
     'Lock counter is 0: block current task on lock wait queue'),

    ('LABEL_EF2048', 'AudioLock_TryAcquire',
     'Try to acquire lock non-blocking: decrement counter or return failure'),

    ('LABEL_EF205E', 'AudioLock_TryAcquire_Fail',
     'Lock unavailable: return 0xFFFF'),

    ('LABEL_EF2061', 'AudioLock_TryAcquire_Return',
     'Return from TryAcquire'),

    ('LABEL_EF2063', 'AudioLock_GetCount',
     'Get lock counter value for lock index A; returns in HL'),

    # --- Message send/receive primitives (EF2070) ---
    ('LABEL_EF2070', 'TaskMsg_Send',
     'Send message XBC to channel A: if receiver waiting, wake it; else enqueue'),

    ('LABEL_EF20D9', 'TaskMsg_Send_QueueFull',
     'No free message slot: return 0xFFFF to indicate failure'),

    ('LABEL_EF20E1', 'TaskMsg_Send_WakeReceiver',
     'Receiver waiting: deliver message, unlink from wait queue, make ready'),

    ('LABEL_EF218C', 'TaskMsg_Send_NB_Return',
     'Return from non-blocking send variant'),

    ('LABEL_EF2194', 'TaskMsg_Send_NB_QueueFull',
     'Non-blocking send: queue full, return 0xFFFF'),

    ('LABEL_EF219B', 'TaskMsg_Send_NB_WakeReceiver',
     'Non-blocking send: wake waiting receiver with message'),

    # --- Message receive (EF21E1) ---
    ('LABEL_EF21E1', 'TaskMsg_Receive',
     'Receive message from channel A: dequeue if available, else block'),

    ('LABEL_EF223B', 'TaskMsg_Receive_Block',
     'No message available: block current task on message wait queue'),

    # --- Message receive non-blocking (EF2272) ---
    ('LABEL_EF2272', 'TaskMsg_TryReceive',
     'Try to receive message non-blocking: return message or 0'),

    ('LABEL_EF22C3', 'TaskMsg_TryReceive_Empty',
     'No message: return XHL=0'),

    ('LABEL_EF22C5', 'TaskMsg_TryReceive_Return',
     'Return from TryReceive'),

    # --- Task timer registration (EF22C9) ---
    ('LABEL_EF22C9', 'TaskTimer_Register',
     'Register periodic timer callback: set period and handler in timer slot'),

    # --- Task priority change (EF22F5) ---
    ('LABEL_EF22F5', 'TaskSched_ChangePriority',
     'Change task priority: unlink from current queue, relink to new priority queue'),

    ('LABEL_EF2349', 'TaskSched_ChangePriority_NotReady',
     'Task not in ready state: just update stored priority'),

    # --- Task priority change inline (EF234F) ---
    ('LABEL_EF234F', 'TaskSched_ChangePriority_Inline',
     'Inline variant of priority change (non-blocking, preserves more regs)'),

    ('LABEL_EF23A0', 'TaskSched_ChangePriority_Inline_NotReady',
     'Inline: task not ready, just store new priority'),

    ('LABEL_EF23A3', 'TaskSched_ChangePriority_Inline_Return',
     'Return from inline priority change'),

    # --- Data/helper after scheduler ---
    ('LABEL_EF23AA', 'TaskSched_TCBTemplate',
     'Task control block template data (inline bytes)'),

    ('LABEL_EF23DA', 'TaskSched_DelayTicks',
     'Delay current task by WA/2 ticks using tick counter at 1033'),

    ('LABEL_EF23E1', 'TaskSched_DelayTicks_SpinLoop',
     'Spin waiting for tick counter to reach target'),

    # ==================================================================
    # Stop_and_Clear_8bit_Timer_3 area (EF23E8-EF25AC)
    # Timer start/stop, plus sequencer ring buffer wrappers for various
    # buffer instances (SeqBuf at 0x01E549, TempoRingBuf at 0x01E753,
    # RhythmBuf at 0x01EF5D).
    # ==================================================================

    ('LABEL_EF23F0', 'SeqBuf_BytecodeSnippet',
     'Inline bytecode data (8 bytes) for SeqBuf operations'),

    # --- SeqBuf operations (buffer at 0x01E549) ---
    ('LABEL_EF23FA', 'SeqBuf_ReadByte',
     'Read one byte from sequencer buffer at 0x01E549'),

    ('LABEL_EF2407', 'SeqBuf_WriteByte',
     'Write one byte to sequencer buffer at 0x01E549'),

    ('LABEL_EF241D', 'SeqBuf_WriteBytes',
     'Write BC bytes from XIY to sequencer buffer at 0x01E549'),

    ('LABEL_EF242F', 'SeqBuf_WriteBytes_Loop',
     'Per-byte: read from XIY, write to ring buffer, advance, loop'),

    ('LABEL_EF243F', 'SeqBuf_InlineBytecode',
     'Inline bytecode for SeqBuf check/dispatch (19 bytes)'),

    ('LABEL_EF2451', 'SeqBuf_GetWritePos',
     'Get SeqBuf write position: load 16-bit from 0x01E547'),

    ('LABEL_EF2457', 'SeqBuf_Init',
     'Initialise sequencer buffer at 0x01E549 (512-entry ring)'),

    ('LABEL_EF2465', 'SeqBuf_SaveReadPos',
     'Save current SeqBuf read position (0x01E541 -> 0x01E53F)'),

    ('LABEL_EF2472', 'SeqBuf_ReadAlternate',
     'Read byte from SeqBuf alternate read pointer'),

    ('LABEL_EF2480', 'SeqBuf_ReadAlternate2',
     'Read byte from SeqBuf using secondary alternate pointer'),

    ('LABEL_EF249B', 'SeqBuf_SaveWritePos',
     'Save current SeqBuf write position (0x01E545 -> 0x01E543)'),

    # --- TempoRingBuf operations (buffer at 0x01E753) ---
    ('LABEL_EF24A8', 'TempoRingBuf_ReadByte',
     'Read one byte from tempo ring buffer at 0x01E753'),

    ('LABEL_EF24B5', 'TempoRingBuf_WriteByte_Ext',
     'Write one byte to tempo ring buffer (link-frame calling convention)'),

    ('LABEL_EF24CB', 'TempoRingBuf_WriteBytes',
     'Write BC bytes from XIY to tempo ring buffer at 0x01E753'),

    ('LABEL_EF24DD', 'TempoRingBuf_WriteBytes_Loop',
     'Per-byte write loop for tempo ring buffer'),

    ('LABEL_EF24ED', 'TempoRingBuf_CheckEmpty',
     'Check if tempo ring buffer is empty: returns 0xFFFF if not empty'),

    ('LABEL_EF24FF', 'TempoRingBuf_BytecodeSnippet2',
     'Inline bytecode for tempo ring buffer (6 bytes)'),

    ('LABEL_EF2505', 'TempoRingBuf_Init',
     'Initialise tempo ring buffer at 0x01E753 (2048-entry ring)'),

    ('LABEL_EF2513', 'TempoRingBuf_SaveReadPos',
     'Save tempo ring buffer read position'),

    ('LABEL_EF2520', 'TempoRingBuf_InlineBytecode2',
     'Inline bytecode for tempo ring buffer alt read (14 bytes)'),

    ('LABEL_EF252E', 'TempoRingBuf_ReadAlternate',
     'Read from tempo ring buffer alternate read pointer'),

    ('LABEL_EF253C', 'TempoRingBuf_SaveWritePos',
     'Save tempo ring buffer write position'),

    # --- RhythmBuf operations (buffer at 0x01EF5D) ---
    ('LABEL_EF2579', 'RhythmBuf_InlineBytecode',
     'Inline bytecode for rhythm buffer write variant (35 bytes)'),

    ('LABEL_EF25AC', 'RhythmBuf_CheckEmpty_Return',
     'Return from RhythmBuf_CheckEmpty'),

    ('LABEL_EF25AD', 'RhythmBuf_BytecodeSnippet',
     'Inline bytecode for rhythm buffer (6 bytes)'),

    ('LABEL_EF25CE', 'RhythmBuf_ReadAlternate',
     'Read from rhythm buffer alternate read pointer'),

    ('LABEL_EF25DC', 'RhythmBuf_InlineBytecode2',
     'Inline bytecode block: rhythm buffer save/read helpers (83 bytes)'),

    # --- AltEvtBuf operations (buffer at 0x01F167) ---
    ('LABEL_EF2627', 'AltEvtBuf_WriteBytes',
     'Write BC bytes from XIY to alt-event buffer at 0x01F167'),

    ('LABEL_EF2639', 'AltEvtBuf_WriteBytes_Loop',
     'Per-byte write loop for alt-event buffer'),

    ('LABEL_EF2649', 'AltEvtBuf_InlineBytecode',
     'Inline bytecode for alt-event buffer operations (24 bytes)'),

    ('LABEL_EF2661', 'AltEvtBuf_Init',
     'Initialise alt-event buffer at 0x01F167'),

    ('LABEL_EF266F', 'AltEvtBuf_Helpers',
     'Alt-event buffer save/read/write helper group'),

    # --- SeqEvtBuf operations (buffer at 0x01F271) ---
    ('LABEL_EF26BF', 'SeqEvtBuf_WriteByte',
     'Write one byte to seq-event buffer at 0x01F271'),

    ('LABEL_EF26D5', 'SeqEvtBuf_InlineBytecode',
     'Inline bytecode for seq-event buffer (44 bytes)'),

    ('LABEL_EF270F', 'SeqEvtBuf_Init',
     'Initialise seq-event buffer at 0x01F271'),

    ('LABEL_EF271D', 'SeqEvtBuf_SaveReadPos',
     'Save seq-event buffer read position'),

    ('LABEL_EF272A', 'SeqEvtBuf_ReadAlternate',
     'Read from seq-event buffer alternate read pointer'),

    ('LABEL_EF2738', 'SeqEvtBuf_ReadAlternate2',
     'Read from seq-event buffer secondary alternate pointer'),

    ('LABEL_EF2746', 'SeqEvtBuf_SaveReadPos2',
     'Save seq-event buffer secondary read position'),

    ('LABEL_EF2753', 'SeqEvtBuf_SaveReadPos3',
     'Save seq-event buffer tertiary read position'),

    ('LABEL_EF2760', 'SeqMain_ReadByte_1024',
     'Read byte from SeqMain buffer at 0x01F37B (1024-entry ring)'),

    # ==================================================================
    # SeqAlt1_ReadByte area (EF2810-EF2A25) — Sequencer Alt1 buffer
    # operations: read/write/init/check for buffer at 0x01F785
    # ==================================================================

    ('LABEL_EF281B', 'SeqAlt1_WriteByte',
     'Write one byte to SeqAlt1 buffer at 0x01F785'),

    ('LABEL_EF2831', 'SeqAlt1_WriteBytes',
     'Write BC bytes from XIY to SeqAlt1 buffer at 0x01F785'),

    ('LABEL_EF2843', 'SeqAlt1_WriteBytes_Loop',
     'Per-byte write loop for SeqAlt1 buffer'),

    ('LABEL_EF2853', 'SeqAlt1_CheckEmpty',
     'Check if SeqAlt1 buffer is empty'),

    ('LABEL_EF2864', 'SeqAlt1_CheckEmpty_Return',
     'Return from SeqAlt1_CheckEmpty'),

    ('LABEL_EF2865', 'SeqAlt1_GetTimingValue',
     'Get SeqAlt1 timing value: load 16-bit from 0x01F783'),

    ('LABEL_EF286B', 'SeqAlt1_Init',
     'Initialise SeqAlt1 buffer at 0x01F785'),

    ('LABEL_EF2879', 'SeqAlt1_SaveReadPos',
     'Save SeqAlt1 read position'),

    ('LABEL_EF2886', 'SeqAlt1_ReadAlternate',
     'Read from SeqAlt1 alternate read pointer'),

    ('LABEL_EF2894', 'SeqAlt1_ReadAlternate2',
     'Read from SeqAlt1 secondary alternate pointer'),

    ('LABEL_EF28A2', 'SeqAlt1_SaveReadPos2',
     'Save SeqAlt1 secondary read position'),

    ('LABEL_EF28AF', 'SeqAlt1_SaveReadPos3',
     'Save SeqAlt1 tertiary read position'),

    # --- SeqBuf2 operations (buffer at 0x01F88F) ---
    ('LABEL_EF28BC', 'SeqBuf2_ReadByte',
     'Read one byte from SeqBuf2 at 0x01F88F'),

    ('LABEL_EF28C9', 'SeqBuf2_WriteByte',
     'Write one byte to SeqBuf2 at 0x01F88F'),

    ('LABEL_EF28DF', 'SeqBuf2_WriteBytes',
     'Write BC bytes from XIY to SeqBuf2 at 0x01F88F'),

    ('LABEL_EF28F1', 'SeqBuf2_WriteBytes_Loop',
     'Per-byte write loop for SeqBuf2'),

    ('LABEL_EF2901', 'SeqBuf2_InlineBytecode',
     'Inline bytecode for SeqBuf2 operations (24 bytes)'),

    ('LABEL_EF2919', 'SeqBuf2_Init',
     'Initialise SeqBuf2 at 0x01F88F (512-entry ring)'),

    ('LABEL_EF2927', 'SeqBuf2_SaveReadPos',
     'Save SeqBuf2 read position'),

    ('LABEL_EF2934', 'SeqBuf2_ReadAlternate',
     'Read from SeqBuf2 alternate read pointer'),

    ('LABEL_EF2942', 'SeqBuf2_ReadAlternate2',
     'Read from SeqBuf2 secondary alternate pointer'),

    ('LABEL_EF2950', 'SeqBuf2_SaveReadPos2',
     'Save SeqBuf2 secondary read position'),

    ('LABEL_EF295D', 'SeqBuf2_SaveReadPos3',
     'Save SeqBuf2 tertiary read position'),

    # --- SeqBuf3 operations (buffer at 0x01FA99) ---
    ('LABEL_EF296A', 'SeqBuf3_ReadByte',
     'Read one byte from SeqBuf3 at 0x01FA99'),

    ('LABEL_EF2977', 'SeqBuf3_WriteByte',
     'Write one byte to SeqBuf3 at 0x01FA99'),

    ('LABEL_EF298D', 'SeqBuf3_WriteBytes',
     'Write BC bytes from XIY to SeqBuf3 at 0x01FA99'),

    ('LABEL_EF299F', 'SeqBuf3_WriteBytes_Loop',
     'Per-byte write loop for SeqBuf3'),

    ('LABEL_EF29AF', 'SeqBuf3_InlineBytecode',
     'Inline bytecode for SeqBuf3 operations (18 bytes)'),

    ('LABEL_EF29C1', 'SeqBuf3_GetTimingValue',
     'Get SeqBuf3 timing value from 0x01FA97'),

    ('LABEL_EF29C7', 'SeqBuf3_Init',
     'Initialise SeqBuf3 at 0x01FA99 (512-entry ring)'),

    ('LABEL_EF29D5', 'SeqBuf3_Helpers',
     'SeqBuf3 save/read/write helper group'),

    # --- SeqAlt2 read helper (EF2A18) ---
    ('LABEL_EF2A18', 'SeqAlt2_ReadByte_1024',
     'Read byte from SeqAlt2 buffer at 0x01FCA3 (1024-entry ring)'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content and old_label not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu/kn5000_v10_program.s')


if __name__ == '__main__':
    main()
