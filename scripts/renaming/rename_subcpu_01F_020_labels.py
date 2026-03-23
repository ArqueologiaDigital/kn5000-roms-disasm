#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for SubCPU routines (00F/014/01F/020 range).

Based on analysis of the 0x00F000-0x00F77F, 0x014777, 0x01F859-0x020D13 address
ranges in the SubCPU firmware.  This range covers:
  - Internal RAM data structures (serial buffers, lookup tables, config data)
  - DMA ring buffer transfers (serial port to/from maincpu)
  - Audio system initialization and main loop
  - Timer interrupt handlers (audio tick, counter watchdog)
  - RESET vector and hardware register configuration
  - Cooperative task scheduler (linked-list based, priority queues)
  - DSP channel initialization
  - Audio command dispatch handlers
  - Ring buffer control block initialisation
  - Inter-CPU latch-related opaque .byte blocks

Each rename was verified by analysing the routine's code, register usage, called
functions, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_subprogram_v142.s — it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source:
#
#   00F000-00F77F  Internal RAM: config data, serial buffer structs, lookup tables
#   014777         Zero-filled data block (tone generator config area)
#   01F859-01F88E  DMA ring buffer transfer (serial RX -> maincpu DRAM)
#   01F89A-01F8D2  Serial port #1 data transmit loop
#   01FAA6-01FB2F  Audio system init continuation + main loop
#   01FB41-01FBB8  Timer interrupt handler (audio tick counter)
#   01FBC1-01FBF8  Opaque .byte routines (prevbank / serial helpers)
#   01FC01-01FC6F  Memory block clear (DRAM + extension RAM)
#   01FC70-01FC92  Audio subsystem initialisation call chain
#   01FCFB         Opaque .byte block (DSP config / command sequences)
#   01FDC2-01FDC8  Task scheduler helper + INT16 handler
#   01FDDA-01FEDF  Task scheduler: create tasks, init task control blocks
#   01FEE7-01FF72  Task scheduler: resume, dispatch, context switch
#   01FF7B         Opaque .byte block (linked-list operations)
#   01FFD0-01FFE4  Timer interrupt: task-switch countdown handler
#   01FFFD         Task scheduler: spawn new task with priority
#   0200BD-0200C0  Task scheduler: get current task priority / yield
#   020109-020148  Task queue: dequeue head node and relink
#   02014D         Opaque .byte block (task queue operations)
#   020370-0203A3  Task scheduler: preemptive yield (push all, reschedule)
#   02040B-020411  Task queue: dequeue with interrupt guard (non-preemptive)
#   02044F-02046D  Task scheduler: preemptive wait (decrement semaphore)
#   0204BF-0204D1  Task semaphore: try-decrement / message-send operations
#   02053A-0205FC  Task message queue: send with priority enqueue
#   020642-02069C  Task message queue: receive (dequeue + reschedule)
#   0206D3-020726  Task message queue: try-receive (non-blocking)
#   02072A         Task: configure timer channel from descriptor
#   0207AA         Task: reassign task to new priority queue
#   020801-02080B  Task: reassign with interrupt guard
#   020849-02084D  Interrupt mask bit set/clear (I/O port 0x80, bit 3)
#   020851         Opaque .byte block (ring buffer control operations)
#   0208B8         RingBuf_Init_1K: init control block with 0x3FF limit
#   0208C6         Opaque .byte block (ring buffer read/write operations)
#   020966         RingBuf_Init_256: init control block with 0xFF limit
#   020974         Opaque .byte block (ring buffer operations variant B)
#   020A14         RingBuf_Init_512: init control block with 0x1FF limit
#   020A22         Audio buffer pointer load/store utilities
#   020A65         RingBuf_Reset_256: reset control block (0xFF limit)
#   020A7F         Opaque .byte block (ring buffer wrapped-read operations)
#   020AF4         RingBuf_Reset_512: reset control block (0x1FF limit)
#   020B0E         Opaque .byte block (ring buffer wrapped-read, 0x1FF)
#   020B83         RingBuf_Reset_1K: reset control block (0x3FF limit)
#   020B9D         Opaque .byte block (ring buffer wrapped-read, 0x3FF)
#   020D13         Opaque .byte block (inter-CPU latch protocol)
# ---------------------------------------------------------------------------

RENAMES = [
    # ------------------------------------------------------------------
    # 00F000  Internal RAM: firmware configuration data block
    # Located at org 0xF000 - 0x400 (RAM base).  Contains initial
    # configuration values, calibration data, and lookup tables used
    # by the audio engine at boot time.
    # ------------------------------------------------------------------
    ('LABEL_00F000', 'IRAM_FirmwareConfig',
     'Internal RAM firmware configuration data block at 0xF000'),

    # ------------------------------------------------------------------
    # 00F420  IEEE-754 floating-point constant block
    # Contains 8-byte double-precision constants used by the firmware's
    # math routines (log/exp/trig for DSP parameter computation).
    # ------------------------------------------------------------------
    ('LABEL_00F420', 'FPConst_MaxNorm',
     'IEEE-754 double: 0x7FEFFFFFFFFFFFFF (max normalised double)'),

    ('LABEL_00F428', 'FPConst_Zero',
     'IEEE-754 double: 0x0 (positive zero)'),

    ('LABEL_00F42C', 'FPConst_Ln2',
     'IEEE-754 double: ln(2) constant for log/exp math'),

    # ------------------------------------------------------------------
    # 00F434  Serial port #1 transmit buffer control structure
    # 22-byte struct: start, end, write_ptr, read_ptr, wrap_ptr, counter
    # Used by Serial1_DataTransmit_Loop and ring buffer routines.
    # ------------------------------------------------------------------
    ('LABEL_00F434', 'Serial1_TxBuf_Struct',
     'Serial port #1 transmit buffer control structure (start=0xA00, end=0xDFF, size=0x3FF)'),

    # ------------------------------------------------------------------
    # 00F44A  Serial port #1 receive buffer control structure
    # Same layout as TxBuf; base address 0xE16, size 0x1FF.
    # ------------------------------------------------------------------
    ('LABEL_00F44A', 'Serial1_RxBuf_Struct',
     'Serial port #1 receive buffer control structure (start=0xE16, end=0x1015, size=0x1FF)'),

    # ------------------------------------------------------------------
    # 00F52b  Voice channel pointer table
    # 20 entries of 4-byte pointers, indexed by channel number.
    # Used by ChanStruct_Init_Entry for initialising channel structs.
    # Values like 0x112D, 0x114B, 0x1187 are addresses in the channel
    # state table area.
    # ------------------------------------------------------------------
    ('LABEL_00F52b', 'Voice_ChannelPtrTable',
     'Voice channel pointer table (20 x 4-byte entries, used by channel struct init)'),

    # ------------------------------------------------------------------
    # 00F693  Pitch-bend dispatch jump table offsets
    # Short words used by PitchBend_Process as a dispatch table.
    # The first 14 bytes select sub-routines; bytes 14-19 are
    # group offset pairs for envelope rate indexing.
    # ------------------------------------------------------------------
    ('LABEL_00F693', 'PitchBend_DispatchTable',
     'Pitch-bend sub-routine dispatch table (10 short entries)'),

    ('LABEL_00F6A7', 'Voice_GroupOffsets_A',
     'Voice group offset table A (6 short entries for channel routing)'),

    ('LABEL_00F6B3', 'Voice_GroupOffsets_B',
     'Voice group offset table B (6 short entries)'),

    ('LABEL_00F6BF', 'Voice_GroupOffsets_C',
     'Voice group offset table C (6 short entries)'),

    # ------------------------------------------------------------------
    # 00F6CB  Voice bitmask and channel-type constants
    # Contains bit-position masks (0x01,0x04,0x10,0x40,0x02,...) used
    # for interrupt-mask computations, followed by zero padding and
    # MIDI-note-to-semitone mapping data.
    # ------------------------------------------------------------------
    ('LABEL_00F6CB', 'Voice_BitMask_ChannelType',
     'Voice bitmask constants and channel type data (masks + note mapping)'),

    # ------------------------------------------------------------------
    # 00F6F3  MIDI note-to-frequency semitone table
    # Maps MIDI note numbers to tone-generator frequency codes.
    # Two bytes per entry: high byte = octave, low byte = semitone.
    # ------------------------------------------------------------------
    ('LABEL_00F6F3', 'MIDI_NoteFreqTable',
     'MIDI note-to-frequency semitone lookup table (paired bytes)'),

    # ------------------------------------------------------------------
    # 00F703  Voice envelope rate table
    # Contains 16-bit offset/rate values for voice envelope computation.
    # Used by the EG envelope routines (EGEnv_Compute_A/B).
    # ------------------------------------------------------------------
    ('LABEL_00F703', 'Voice_EnvelopeRateTable',
     'Voice envelope rate/offset lookup table (short entries)'),

    # ------------------------------------------------------------------
    # 00F739  Voice polyphony configuration table
    # Contains voice polyphony limits and attack/sustain timing values.
    # ------------------------------------------------------------------
    ('LABEL_00F739', 'Voice_PolyphonyConfig',
     'Voice polyphony and attack/sustain timing configuration'),

    # ------------------------------------------------------------------
    # 00F74F  Voice parameter scaling table
    # Values used for scaling velocity, pan, and detune parameters
    # during voice assignment and note-on processing.
    # ------------------------------------------------------------------
    ('LABEL_00F74F', 'Voice_ParamScaleTable',
     'Voice parameter scaling table (velocity/pan/detune values)'),

    # ------------------------------------------------------------------
    # 00F77D-00F77F  Small constants (single bytes)
    # F77D: value 0x07 (bit mask or channel count)
    # F77E: value 0x00 (zero constant)
    # F77F: signed offset table for pitch/detune computation
    # ------------------------------------------------------------------
    ('LABEL_00F77D', 'Const_ChannelMax',
     'Constant: 0x07 (max channel index or bitmask)'),

    ('LABEL_00F77E', 'Const_Zero_Byte',
     'Constant: 0x00 (zero byte)'),

    ('LABEL_00F77F', 'PitchDetune_OffsetTable',
     'Signed pitch/detune offset table (16-bit values, positive and negative)'),

    # ------------------------------------------------------------------
    # 014777  Zero-filled data block (tone generator work area)
    # Large zero-filled region in the tone-generator address space.
    # Used as working storage for tone generator state.
    # ------------------------------------------------------------------
    ('LABEL_014777', 'ToneGen_WorkArea',
     'Zero-filled tone generator work area (initialised data block at 0x14777)'),

    # ------------------------------------------------------------------
    # 01F859-01F88E  DMA ring buffer transfer: serial RX -> maincpu
    # Reads bytes from ring buffer (base 0xE00) and copies them into
    # maincpu-accessible DRAM at address 1536 (0x600).  Up to 0x400
    # bytes per call.  If any data was read, calls 0x20C6B to notify
    # maincpu of the transfer.
    # ------------------------------------------------------------------
    ('LABEL_01F859', 'Audio_DMA_RingBuf_ReadLoop',
     'Loop: read byte from ring buffer, store to DRAM[1536+iz], until 0xFFFF or 0x400'),

    ('LABEL_01F87B', 'Audio_DMA_RingBuf_CheckSend',
     'Check if any bytes were read (iz != 0); if so, call maincpu transfer notify'),

    ('LABEL_01F88E', 'Audio_DMA_RingBuf_Done',
     'Restore iz and return from Audio_DMA_RingBuffer_To_Maincpu'),

    # ------------------------------------------------------------------
    # 01F89A-01F8D2  Serial port #1 data transmit loop
    # Processes queued serial bytes from stack.  For each byte:
    # if TX buffer flag (bit 2 of 4148) clear, sends via RX handler;
    # otherwise saves to ring buffer and enables TX interrupt.
    # Decrements counter at (xsp+4) each iteration.
    # ------------------------------------------------------------------
    ('LABEL_01F89A', 'Serial1_TX_LoopBody',
     'Per-byte: check TX flag, route to direct-send or ring-buffer path'),

    ('LABEL_01F8B2', 'Serial1_TX_ViaRingBuf',
     'TX flag set: save byte to ring buffer, enable TX interrupt'),

    ('LABEL_01F8C8', 'Serial1_TX_CheckNext',
     'Decrement counter; if non-zero, loop back to LoopBody'),

    ('LABEL_01F8D2', 'Serial1_TX_Done',
     'All bytes sent: return HL=0'),

    # ------------------------------------------------------------------
    # 01FAA6  Post-RESET continuation: set stack, init audio, enable IRQ
    # Called after memory-clear completes.  Sets up stack pointer,
    # calls LABEL_01FDDA (task scheduler init), configures timer
    # prescaler, initialises audio subsystem (LABEL_01FC70), then
    # enables interrupts and enters the audio main loop.
    # ------------------------------------------------------------------
    ('LABEL_01FAA6', 'PostReset_InitAudio',
     'Post-RESET: set stack to 0x04069A, init tasks, configure timer, start audio'),

    # ------------------------------------------------------------------
    # 01FAF0-01FB2F  Audio main loop body
    # Checks flags in state word 4158/4160 and dispatches to various
    # audio processing routines.  Bit 5 = process-final flag,
    # bit 1 = periodic re-init.  Counter at 61458 tracks ticks.
    # IZ counts down some delayed operation.
    # ------------------------------------------------------------------
    ('LABEL_01FAF0', 'AudioLoop_CheckWatchdog',
     'Check watchdog counter (4160 > 0x3E8 -> unmute via set bit 0 of I/O 0x38)'),

    ('LABEL_01FAFF', 'AudioLoop_CheckPeriodicReinit',
     'Check bit 1 of 4158; if set, call periodic audio re-init routines'),

    ('LABEL_01FB29', 'AudioLoop_DecrementDelay',
     'Decrement delay counter IZ if non-zero'),

    ('LABEL_01FB2F', 'AudioLoop_CallProcessors',
     'Call tone-gen processor, DSP updater, audio send, then loop'),

    # ------------------------------------------------------------------
    # 01FB41-01FBB8  Timer interrupt handler (INT_HANDLER_14)
    # Increments watchdog counter (4160), reads tick index from 61460,
    # dispatches through OFFSETS_F460 jump table to one of 6 variants:
    #   Audio_PlayNote_Variant_1/2/3, LABEL_01FB86, LABEL_01FB8E, LABEL_01FB97
    # Variants set status bits in carry flag / state word 4158.
    # ------------------------------------------------------------------
    ('LABEL_01FB41', 'Timer_AudioTick_Handler',
     'INT14 handler: increment watchdog, dispatch via jump table to audio-tick variant'),

    ('LABEL_01FB86', 'AudioTick_Variant_4',
     'Audio tick variant 4: set bit 4 of 4158, load A=0, jump to StoreTick'),

    ('LABEL_01FB8E', 'AudioTick_Variant_5',
     'Audio tick variant 5: load A=3, fall through to StoreTick'),

    ('LABEL_01FB90', 'AudioTick_StoreTick',
     'Store tick flag: SCF + STCFA to I/O 0x3E bit 0x10, jump to TickDone'),

    ('LABEL_01FB97', 'AudioTick_Variant_6',
     'Audio tick variant 6: set bit 2 of 4158, reset counter 61460, check overflow at 61462'),

    ('LABEL_01FBB8', 'AudioTick_Done',
     'Restore regs and RETI from timer interrupt handler'),

    # ------------------------------------------------------------------
    # 01FBC1  Opaque .byte routine (prevbank register operations)
    # Contains prevbank (D7) prefixed instructions and register
    # manipulation.  Ends with RET.  Likely a DSP or tone-gen helper.
    # ------------------------------------------------------------------
    ('LABEL_01FBC1', 'PrevBank_RegHelper',
     'Opaque .byte routine: prevbank register operations, ends with RET'),

    # ------------------------------------------------------------------
    # 01FBF8  Opaque .byte routine (serial/timer helper)
    # Short sequence: 8 bytes + RET.  Likely reads a timer or serial
    # register and returns a status value.
    # ------------------------------------------------------------------
    ('LABEL_01FBF8', 'Timer_StatusHelper',
     'Opaque .byte routine: timer/serial status read, 8 bytes + RET'),

    # ------------------------------------------------------------------
    # 01FC01-01FC6B  Memory block clear (two regions)
    # Region 1: 0x3EE76 bytes starting at address 0x3EE76 (DRAM),
    #   fill with 0x0000 using LDIRW93 bulk copy.
    # Region 2: 0x44CB bytes starting at address 0x600 (extension RAM),
    #   same fill pattern.
    # Both regions handle odd-length via bit-0 check of original count.
    # Ends by jumping to PostReset_InitAudio (LABEL_01FAA6).
    # ------------------------------------------------------------------
    ('LABEL_01FC01', 'MemClear_DRAM_And_ExtRAM',
     'Clear two memory regions: DRAM (0x3EE76 bytes) and ExtRAM (0x44CB bytes at 0x600)'),

    ('LABEL_01FC29', 'MemClear_DRAM_BulkLoop',
     'DRAM bulk-clear inner loop: LDIRW93 + DJNZ'),

    ('LABEL_01FC2E', 'MemClear_DRAM_OddByte',
     'DRAM clear: handle odd-length byte, then start ExtRAM clear'),

    ('LABEL_01FC36', 'MemClear_ExtRAM',
     'Clear ExtRAM region: 0x44CB bytes at address 0x600'),

    ('LABEL_01FC5E', 'MemClear_ExtRAM_BulkLoop',
     'ExtRAM bulk-clear inner loop: LDIRW93 + DJNZ'),

    ('LABEL_01FC63', 'MemClear_ExtRAM_OddByte',
     'ExtRAM clear: handle odd-length byte, then jump to PostReset_InitAudio'),

    ('LABEL_01FC6B', 'MemClear_ExtRAM_Finish',
     'Jump to PostReset_InitAudio after ExtRAM clear'),

    # ------------------------------------------------------------------
    # 01FC6F  Single-byte data constant
    # Value 0x0E.  Possibly a channel count or configuration byte.
    # ------------------------------------------------------------------
    ('LABEL_01FC6F', 'Const_0x0E',
     'Single-byte constant: 0x0E (channel count or config)'),

    # ------------------------------------------------------------------
    # 01FC70  Audio subsystem init call chain
    # Calls three ring-buffer init routines in sequence:
    #   LABEL_0208B8 (RingBuf_Init_1K), LABEL_020966 (RingBuf_Init_256),
    #   LABEL_020A14 (RingBuf_Init_512)
    # ------------------------------------------------------------------
    ('LABEL_01FC70', 'Audio_InitRingBuffers',
     'Init all three audio ring buffers: 1K + 256 + 512 byte variants'),

    # ------------------------------------------------------------------
    # 01FC8A-01FC92  Audio command handler: consume N bytes (40-5F range)
    # Reads byte count from (xsp+4), decrements in loop, discards bytes.
    # Returns HL=0.  Effectively a null/skip command handler.
    # ------------------------------------------------------------------
    ('LABEL_01FC8A', 'Sprintf_40_5F_SkipLoop',
     'Skip loop: decrement byte counter until zero'),

    ('LABEL_01FC92', 'Sprintf_40_5F_Done',
     'Return HL=0 after consuming all command bytes'),

    # ------------------------------------------------------------------
    # 01FCFB  Opaque .byte block (DSP configuration / command sequences)
    # Large block of encoded instructions.  Contains multiple
    # link32/unlk32 sequences, register saves, and calls to DSP
    # write routines.  Not disassembled to native mnemonics.
    # ------------------------------------------------------------------
    ('LABEL_01FCFB', 'DSP_ConfigBlock_Opaque',
     'Opaque .byte block: DSP configuration and command sequences'),

    # ------------------------------------------------------------------
    # 01FDC2  Task scheduler: dequeue and dispatch task (variant A)
    # Loads A=3 (priority level), jumps to LABEL_020109 (queue dequeue).
    # Called by LABEL_01FDC8 (INT16 handler).
    # ------------------------------------------------------------------
    ('LABEL_01FDC2', 'Task_DequeueDispatch_Prio3',
     'Dequeue task at priority 3: load A=3, jump to TaskQueue_Dequeue'),

    # ------------------------------------------------------------------
    # 01FDC8  INT_HANDLER_16: timer interrupt for task switch countdown
    # Increments two counters (4306 and 4165), calls Task_DequeueDispatch_Prio3,
    # then jumps to task-switch countdown handler (LABEL_01FFD0).
    # ------------------------------------------------------------------
    ('LABEL_01FDC8', 'INT16_TaskSwitch_Handler',
     'INT16 handler: increment counters, dequeue priority-3 task, enter task-switch countdown'),

    # ------------------------------------------------------------------
    # 01FDDA-01FE99  Task scheduler init: create task control blocks
    # Sets stack to 0x40B1E, initialises task state at 4166, sets up
    # counter via LDC_CR16.  Then initialises 3 task control blocks
    # (0x106C stride 4), 3 task descriptors (0x1048 stride 0xC),
    # 1 free-list node (0x10CA), copies 2 bytes to 0x1080, then
    # 2 more task groups at 0x1078 and 0x1082 with 4 entries each,
    # 4 free-list nodes at 0x10A6, and the free-list head at 0x10C6.
    # ------------------------------------------------------------------
    ('LABEL_01FDDA', 'TaskSched_Init',
     'Task scheduler init: set stack, create task control blocks, link free lists'),

    ('LABEL_01FDF7', 'TaskSched_Init_QueueHeaders',
     'Init 3 task-queue header nodes at 0x106C (stride 4)'),

    ('LABEL_01FE0B', 'TaskSched_Init_TaskDescriptors',
     'Init 3 task descriptors at 0x1048 (stride 0xC): set priority, clear state'),

    ('LABEL_01FE29', 'TaskSched_Init_FreeList_A',
     'Init 1 free-list node at 0x10CA with 0xFFFFFFFF sentinel'),

    ('LABEL_01FE48', 'TaskSched_Init_QueueGroup_B',
     'Init 2 queue header nodes at 0x1078 (stride 4), copy 4 bytes to 0x1092'),

    ('LABEL_01FE68', 'TaskSched_Init_QueueGroup_C',
     'Init 4 queue header nodes at 0x1082 (stride 4)'),

    ('LABEL_01FE7F', 'TaskSched_Init_FreeList_B',
     'Init 4 free-list nodes at 0x10A6 with 0xFFFFFFFF sentinel'),

    ('LABEL_01FE99', 'TaskSched_Init_LinkFreeNodes',
     'Link free-list nodes into doubly-linked circular list at head 0x10C6'),

    # ------------------------------------------------------------------
    # 01FEBB-01FEDF  Task scheduler init: more queue groups + data block
    # Inits 2 more queue headers at 0x1096, then 2 at 0x109E.
    # Then loads pointer to inline data block (LABEL_01FEDF) and
    # jumps to LABEL_01FEE7 for final configuration.
    # ------------------------------------------------------------------
    ('LABEL_01FEBB', 'TaskSched_Init_QueueGroup_D',
     'Init 2 queue header nodes at 0x1096 (stride 4)'),

    ('LABEL_01FECD', 'TaskSched_Init_QueueGroup_E',
     'Init 2 queue header nodes at 0x109E (stride 4), load config data ptr'),

    ('LABEL_01FEDF', 'TaskSched_Init_ConfigData',
     'Inline config data block (8 bytes): initial task descriptor values'),

    # ------------------------------------------------------------------
    # 01FEE7-01FF72  Task scheduler: configure and enter main dispatch
    # Calls LABEL_02072A (configure timer channel), LABEL_02084D (clear
    # interrupt mask bit), configures I/O registers, calls LABEL_020849
    # (set mask bit), spawns initial task via LABEL_01FFFD, enables
    # IRQ6, and jumps to the task dispatch loop (LABEL_01FF21).
    # ------------------------------------------------------------------
    ('LABEL_01FEE7', 'TaskSched_ConfigAndDispatch',
     'Configure timer, set I/O regs, spawn initial task, enter dispatch loop'),

    ('LABEL_01FF18', 'TaskSched_Halt',
     'Enable IRQ0, set prescaler to max (255), spin-loop (error/halt state)'),

    ('LABEL_01FF1F', 'TaskSched_HaltLoop',
     'Infinite spin loop: jr LABEL_01FF1F (scheduler halt)'),

    ('LABEL_01FF21', 'TaskSched_Dispatch',
     'Task dispatcher: check countdown, scan queues, select next task, context-switch'),

    ('LABEL_01FF4A', 'TaskSched_Dispatch_ScanQueues',
     'Scan 3 task queues at 0x106C: find first non-empty queue'),

    ('LABEL_01FF51', 'TaskSched_Dispatch_ScanLoop',
     'Per-queue: compare head with self-link; if different, task is ready'),

    ('LABEL_01FF5F', 'TaskSched_Dispatch_SwitchTo',
     'Switch to found task: save current, load new task SP, set prescaler'),

    ('LABEL_01FF72', 'TaskSched_ContextRestore',
     'Context restore: pop XIZ/XIY/XIX/XDE/XBC/XWA/XHL, pop SR, RET'),

    # ------------------------------------------------------------------
    # 01FF7B  Opaque .byte block (linked-list manipulation code)
    # Contains encoded instructions for doubly-linked list unlink/insert
    # operations.  Not yet disassembled to native mnemonics.
    # ------------------------------------------------------------------
    ('LABEL_01FF7B', 'TaskList_Operations_Opaque',
     'Opaque .byte block: doubly-linked list unlink/insert for task lists'),

    # ------------------------------------------------------------------
    # 01FFD0-01FFE4  Timer interrupt: task-switch countdown handler
    # Reads countdown word at 4306.  If > 1, decrements and returns
    # via RETI.  If == 1, clears to 0 and performs full context save
    # (push all regs, save SP), then jumps to TaskSched_Dispatch
    # to select the next task.
    # ------------------------------------------------------------------
    ('LABEL_01FFD0', 'TaskSwitch_Countdown',
     'Timer IRQ: decrement task-switch countdown at 4306; if expired, context-save and dispatch'),

    ('LABEL_01FFE4', 'TaskSwitch_Expired',
     'Countdown expired: clear 4306, enable IRQ0/6, push all regs, jump to dispatch'),

    # ------------------------------------------------------------------
    # 01FFFD  Task scheduler: spawn new task with priority
    # Creates a new task by computing a 0xC-stride task descriptor
    # index from A, verifying the slot is free (field+9 == 0),
    # setting up the task stack frame (XIY points to stack), writing
    # return address and priority fields, then linking the task node
    # into the appropriate priority queue.  Jumps to TaskSched_Dispatch.
    # ------------------------------------------------------------------
    ('LABEL_01FFFD', 'TaskSched_SpawnTask',
     'Spawn task: build stack frame from descriptor[A], link into priority queue, dispatch'),

    # ------------------------------------------------------------------
    # 0200BD-0200C0  Task scheduler helpers
    # 0200BD: return HL=0 (task priority query: no active task).
    # 0200C0: preemptive context-switch with full register save;
    # unlinks current task node from its queue, relinks it at the
    # tail of a different queue (priority change or yield).
    # ------------------------------------------------------------------
    ('LABEL_0200BD', 'TaskSched_ReturnZero',
     'Return HL=0 (no active task / null result)'),

    ('LABEL_0200C0', 'TaskSched_PreemptiveYield',
     'Preemptive yield: save all regs, unlink task from queue, relink at new priority, dispatch'),

    # ------------------------------------------------------------------
    # 020109-020148  Task queue: dequeue head node and relink
    # Dequeues the head node from the priority queue at 0x1068 + A*4.
    # Unlinks it from the doubly-linked list, relinks remaining nodes,
    # then relinks the dequeued node into a different queue (0x1068).
    # Used by Task_DequeueDispatch_Prio3 and callers in the audio engine.
    # ------------------------------------------------------------------
    ('LABEL_020109', 'TaskQueue_Dequeue',
     'Dequeue head node from queue[A]: unlink, relink into free queue, return'),

    ('LABEL_020148', 'TaskQueue_Dequeue_Return',
     'Restore regs and return from TaskQueue_Dequeue'),

    # ------------------------------------------------------------------
    # 02014D  Opaque .byte block (task queue operations)
    # Large block of encoded instructions containing multiple
    # link32/unlk32 sequences, task queue manipulations, and
    # doubly-linked list operations.
    # ------------------------------------------------------------------
    ('LABEL_02014D', 'TaskQueue_Operations_Opaque',
     'Opaque .byte block: task queue link/unlink operations'),

    # ------------------------------------------------------------------
    # 020370-0203A3  Task scheduler: preemptive yield (INT variant)
    # Full register save (push_sr, push all 7 XR regs), then attempts
    # to dequeue a task from queue at 0x107E + L*4.  If queue is empty,
    # increments a retry counter at 0x1091+L.  If non-empty, unlinks
    # the head task node, marks it with state=4, links it into the
    # run queue at 0x1068, then jumps to TaskSched_Dispatch.
    # ------------------------------------------------------------------
    ('LABEL_020370', 'TaskSched_PreemptiveYield_INT',
     'INT-safe preemptive yield: save all, dequeue from wait-queue, dispatch or retry'),

    ('LABEL_0203A0', 'TaskSched_PreemptiveYield_INT_Empty',
     'Wait-queue empty: increment retry counter, context-restore'),

    ('LABEL_0203A3', 'TaskSched_PreemptiveYield_INT_Dequeue',
     'Dequeue task from wait-queue: unlink, set state=4, relink to run-queue, dispatch'),

    # ------------------------------------------------------------------
    # 02040B-020411  Task queue: dequeue with interrupt guard (non-preemptive)
    # Same logic as the INT variant but uses push_sr/pop_sr around
    # the critical section instead of full context save.
    # Returns without context-switching.
    # ------------------------------------------------------------------
    ('LABEL_02040B', 'TaskQueue_Dequeue_Guard_Empty',
     'Non-preemptive dequeue: wait-queue empty, pop_sr and return'),

    ('LABEL_020411', 'TaskQueue_Dequeue_Guard_Dequeue',
     'Non-preemptive dequeue: unlink task, set state=4, relink to run-queue, pop_sr and return'),

    # ------------------------------------------------------------------
    # 02044F-02046D  Task scheduler: preemptive wait (decrement semaphore)
    # Full register save.  Reads semaphore at 0x1091+A.  If non-zero,
    # decrements and context-restores (TaskSched_ContextRestore).
    # If zero, unlinks current task from run-queue and links it into
    # wait-queue at 0x107E+E*4, sets state=3, then dispatches.
    # ------------------------------------------------------------------
    ('LABEL_02044F', 'TaskSched_Wait',
     'Preemptive wait: save all, check semaphore at 0x1091+A; if zero, block on wait-queue'),

    ('LABEL_02046D', 'TaskSched_Wait_Block',
     'Semaphore is zero: unlink from run-queue, link to wait-queue, set state=3, dispatch'),

    # ------------------------------------------------------------------
    # 0204BF-0204C4  Task semaphore: try-decrement
    # Reads semaphore; if non-zero, decrements and returns HL=0 (success).
    # If zero, returns HL=0xFFFF (would-block).  Protected by push_sr/pop_sr.
    # ------------------------------------------------------------------
    ('LABEL_0204BF', 'TaskSem_TryDec_WouldBlock',
     'Semaphore is zero: set HL=0xFFFF (would-block indicator)'),

    ('LABEL_0204C2', 'TaskSem_TryDec_Return',
     'Pop SR and return from try-decrement'),

    # ------------------------------------------------------------------
    # 0204C4  Opaque .byte block (semaphore/address computation)
    # Short sequence: address computation with mul and offset 0x1091.
    # ------------------------------------------------------------------
    ('LABEL_0204C4', 'TaskSem_AddrCalc_Opaque',
     'Opaque .byte block: semaphore address calculation helper'),

    # ------------------------------------------------------------------
    # 0204D1-020542  Task message queue: send (preemptive)
    # Full register save.  XIZ = message pointer.  Computes message-
    # queue header address at 0x1092 + A*4.  Checks if the queue has
    # a waiting receiver (head != self-link).  If so, delivers the
    # message directly: unlink receiver, store message to receiver's
    # XIZ field, set state=4, relink to run-queue.
    # If no receiver, checks the free-node pool (4294).  If a free
    # node exists, unlinks it, stores the message pointer at +4,
    # links it into the message queue, context-restores.
    # If pool is empty, returns HL=0xFFFF (queue full).
    # ------------------------------------------------------------------
    ('LABEL_0204D1', 'TaskMsgQ_Send',
     'Send message to queue[A]: deliver to waiting receiver or enqueue, preemptive'),

    ('LABEL_02053A', 'TaskMsgQ_Send_PoolEmpty',
     'Free-node pool empty: set HL=0xFFFF (queue full), context-restore'),

    ('LABEL_020542', 'TaskMsgQ_Send_DirectDeliver',
     'Waiting receiver found: unlink, store message, set state=4, relink, dispatch'),

    # ------------------------------------------------------------------
    # 0205ED-0205FC  Task message queue: send (non-preemptive variant)
    # Same logic as TaskMsgQ_Send but uses push_sr/pop_sr guard.
    # Returns without context-switching.
    # ------------------------------------------------------------------
    ('LABEL_0205ED', 'TaskMsgQ_Send_Guard_Return',
     'Non-preemptive send: pop_sr, restore regs, return'),

    ('LABEL_0205F5', 'TaskMsgQ_Send_Guard_PoolEmpty',
     'Non-preemptive send: pool empty, set HL=0xFFFF, return'),

    ('LABEL_0205FC', 'TaskMsgQ_Send_Guard_DirectDeliver',
     'Non-preemptive send: deliver to receiver, set state=4, relink, return'),

    # ------------------------------------------------------------------
    # 020642-02069C  Task message queue: receive (preemptive, blocking)
    # Full register save.  Computes queue address at 0x109A + A*4.
    # If queue has a message (head != self-link), dequeues it: unlink
    # message node, read message pointer from +4, write 0xFFFFFFFF to
    # +4 (consumed), relink node to free pool (0x10C6), store message
    # pointer to HL on caller's stack frame, context-restore.
    # If queue is empty, unlinks current task from run-queue and
    # enqueues it in the message-queue wait list (0x1092 + DE),
    # sets state=3, dispatches.
    # ------------------------------------------------------------------
    ('LABEL_020642', 'TaskMsgQ_Receive',
     'Receive message from queue[A]: dequeue or block on wait-queue, preemptive'),

    ('LABEL_02069C', 'TaskMsgQ_Receive_Empty',
     'Queue empty: unlink task from run-queue, enqueue in wait-list, set state=3, dispatch'),

    # ------------------------------------------------------------------
    # 0206D3-020726  Task message queue: try-receive (non-blocking)
    # Protected by push_sr/pop_sr.  Same dequeue logic as
    # TaskMsgQ_Receive but returns XHL=0 if queue is empty instead
    # of blocking.  Returns message pointer in XHL if found.
    # ------------------------------------------------------------------
    ('LABEL_0206D3', 'TaskMsgQ_TryReceive',
     'Non-blocking receive: dequeue message from queue[A], return XHL=msg or XHL=0'),

    ('LABEL_020724', 'TaskMsgQ_TryReceive_Empty',
     'Queue empty: set XHL=0, pop_sr and return'),

    ('LABEL_020726', 'TaskMsgQ_TryReceive_Return',
     'Pop SR, restore regs, return from TryReceive'),

    # ------------------------------------------------------------------
    # 02072A  Task: configure timer channel from descriptor
    # Reads channel number from descriptor (xix+256), computes timer
    # control block address at 0x10C2 + channel*8.  Writes initial
    # pointer and configuration to timer control block.
    # Enters TaskSched_Dispatch (does not return normally).
    # ------------------------------------------------------------------
    ('LABEL_02072A', 'Task_ConfigTimer',
     'Configure timer channel from descriptor at XIX: write to timer CB at 0x10C2+ch*8, dispatch'),

    # ------------------------------------------------------------------
    # 0207AA  Task: reassign to new priority queue
    # Updates the priority field (offset +8) of a task descriptor at
    # 0x103C + A*0xC.  If state is not 4 (running), just updates the
    # field.  If state == 4, also unlinks from current queue and
    # relinks into the new priority queue at 0x1068 + E*4.
    # ------------------------------------------------------------------
    ('LABEL_0207AA', 'Task_Reassign_NotRunning',
     'Task state != 4: just update priority field at +8, context-restore'),

    # ------------------------------------------------------------------
    # 020801-020804  Task: reassign with interrupt guard
    # Non-preemptive variant of task reassignment.
    # ------------------------------------------------------------------
    ('LABEL_020801', 'Task_Reassign_Guard_NotRunning',
     'Non-preemptive reassign: state != 4, update priority field, pop_sr and return'),

    ('LABEL_020804', 'Task_Reassign_Guard_Return',
     'Pop SR, restore regs, return from guarded reassign'),

    # ------------------------------------------------------------------
    # 02080B  Opaque .byte block (ring buffer access code)
    # Contains encoded instructions for ring buffer read/write
    # operations with address computation and boundary checks.
    # ------------------------------------------------------------------
    ('LABEL_02080B', 'RingBuf_Access_Opaque_A',
     'Opaque .byte block: ring buffer access code (address calc + boundary check)'),

    # ------------------------------------------------------------------
    # 020849-02084D  Interrupt mask bit set/clear
    # 020849: SET bit 3 of I/O port 0x80 (enable some interrupt source)
    # 02084D: RES bit 3 of I/O port 0x80 (disable some interrupt source)
    # ------------------------------------------------------------------
    ('LABEL_020849', 'IntMask_SetBit3',
     'SET bit 3 of I/O port 0x80 (enable interrupt source)'),

    ('LABEL_02084D', 'IntMask_ClearBit3',
     'RES bit 3 of I/O port 0x80 (disable interrupt source)'),

    # ------------------------------------------------------------------
    # 020851  Opaque .byte block (ring buffer control operations)
    # Contains encoded ring buffer read/write code with pointer
    # arithmetic and wrap-around logic.
    # ------------------------------------------------------------------
    ('LABEL_020851', 'RingBuf_Control_Opaque',
     'Opaque .byte block: ring buffer control operations with wrap-around'),

    # ------------------------------------------------------------------
    # 0208B8  Ring buffer init: 1K variant (0x3FF limit)
    # Saves IX/XDE, loads base address 0x040C2E, calls
    # RingBuf_Reset_1K (LABEL_020B83), restores and returns.
    # ------------------------------------------------------------------
    ('LABEL_0208B8', 'RingBuf_Init_1K',
     'Init 1K ring buffer: load base 0x040C2E, call RingBuf_Reset_1K'),

    # ------------------------------------------------------------------
    # 0208C6  Opaque .byte block (ring buffer read/write operations)
    # Contains encoded ring buffer manipulation with pointer updates
    # and overflow checks.
    # ------------------------------------------------------------------
    ('LABEL_0208C6', 'RingBuf_ReadWrite_Opaque_A',
     'Opaque .byte block: ring buffer read/write with pointer updates'),

    # ------------------------------------------------------------------
    # 020966  Ring buffer init: 256-byte variant (0xFF limit)
    # Saves IX/XDE, loads base address 0x041038, calls
    # RingBuf_Reset_256 (LABEL_020A65), restores and returns.
    # ------------------------------------------------------------------
    ('LABEL_020966', 'RingBuf_Init_256',
     'Init 256-byte ring buffer: load base 0x041038, call RingBuf_Reset_256'),

    # ------------------------------------------------------------------
    # 020974  Opaque .byte block (ring buffer operations variant B)
    # Same pattern as 0208C6 but for the 256-byte ring buffer variant.
    # ------------------------------------------------------------------
    ('LABEL_020974', 'RingBuf_ReadWrite_Opaque_B',
     'Opaque .byte block: ring buffer read/write variant B (256-byte)'),

    # ------------------------------------------------------------------
    # 020A14  Ring buffer init: 512-byte variant (0x1FF limit)
    # Saves IX/XDE, loads base address 0x041142, calls
    # RingBuf_Reset_512 (LABEL_020AF4), restores and returns.
    # ------------------------------------------------------------------
    ('LABEL_020A14', 'RingBuf_Init_512',
     'Init 512-byte ring buffer: load base 0x041142, call RingBuf_Reset_512'),

    # ------------------------------------------------------------------
    # 020A22  Audio buffer pointer load/store utilities
    # Five small routines that copy 16-bit pointer values between
    # adjacent fields in the audio buffer control block at 0x041138.
    # Definition-only label (no references); marks the utility block.
    # ------------------------------------------------------------------
    ('LABEL_020A22', 'AudioBuf_PtrUtils',
     'Audio buffer pointer load/store utility block (5 small routines at 0x041138)'),

    # ------------------------------------------------------------------
    # 020A65  Ring buffer reset: 256-byte (0xFF limit)
    # Zeroes 5 control fields at (XDE - 10)..(XDE - 2), then writes
    # 0xFF as the capacity limit at (XDE - 2).
    # ------------------------------------------------------------------
    ('LABEL_020A65', 'RingBuf_Reset_256',
     'Reset ring buffer control block: zero 5 fields, set limit=0xFF'),

    # ------------------------------------------------------------------
    # 020A7F  Opaque .byte block (ring buffer wrapped-read operations)
    # Contains encoded instructions for reading from ring buffer with
    # wrap-around boundary at 0xFF.
    # ------------------------------------------------------------------
    ('LABEL_020A7F', 'RingBuf_WrappedRead_Opaque_A',
     'Opaque .byte block: ring buffer wrapped-read operations (0xFF boundary)'),

    # ------------------------------------------------------------------
    # 020AF4  Ring buffer reset: 512-byte (0x1FF limit)
    # Same pattern as RingBuf_Reset_256 but writes 0x1FF as limit.
    # ------------------------------------------------------------------
    ('LABEL_020AF4', 'RingBuf_Reset_512',
     'Reset ring buffer control block: zero 5 fields, set limit=0x1FF'),

    # ------------------------------------------------------------------
    # 020B0E  Opaque .byte block (ring buffer wrapped-read, 0x1FF)
    # Same pattern as 020A7F but for 512-byte boundary.
    # ------------------------------------------------------------------
    ('LABEL_020B0E', 'RingBuf_WrappedRead_Opaque_B',
     'Opaque .byte block: ring buffer wrapped-read operations (0x1FF boundary)'),

    # ------------------------------------------------------------------
    # 020B83  Ring buffer reset: 1K (0x3FF limit)
    # Same pattern as RingBuf_Reset_256 but writes 0x3FF as limit.
    # ------------------------------------------------------------------
    ('LABEL_020B83', 'RingBuf_Reset_1K',
     'Reset ring buffer control block: zero 5 fields, set limit=0x3FF'),

    # ------------------------------------------------------------------
    # 020B9D  Opaque .byte block (ring buffer wrapped-read, 0x3FF)
    # Same pattern as 020A7F but for 1K boundary.
    # ------------------------------------------------------------------
    ('LABEL_020B9D', 'RingBuf_WrappedRead_Opaque_C',
     'Opaque .byte block: ring buffer wrapped-read operations (0x3FF boundary)'),

    # ------------------------------------------------------------------
    # 020D13  Opaque .byte block (inter-CPU latch protocol)
    # Contains encoded instructions for inter-CPU communication
    # via the latch registers at 0x120000.  Follows the named
    # InterCPU_Wait_MSTAT1_Set routine.
    # ------------------------------------------------------------------
    ('LABEL_020D13', 'InterCPU_LatchProtocol_Opaque',
     'Opaque .byte block: inter-CPU latch protocol operations'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

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
            print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    # Check maincpu for cross-references (none expected for these ranges,
    # but guard against surprises).
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label,
                                     maincpu_content)
            maincpu_renames += 1

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))
        print(f'  (also updated {maincpu_renames} cross-refs in maincpu)')

    print(f'\nRenamed {renamed} labels in subcpu ({maincpu_renames} cross-refs in maincpu)')


if __name__ == '__main__':
    main()
