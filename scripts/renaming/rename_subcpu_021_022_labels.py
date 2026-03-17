#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for SubCPU audio engine routines (021-022 range).

Based on analysis of the 0x021000-0x022FFF address range in the SubCPU audio engine.
This range covers ring-buffer management, voice/channel state tables, note scheduling,
oscillator parameter dispatch, and audio command processing helpers.

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
#   021000-0210CC  Ring-buffer offset checks and channel-quad decoder
#   0210CC-021185  Voice-state table swap (using DE/BC index pairs)
#   02129C-02134E  Voice-state table swap with range-limit guard
#   021364-0213CB  Voice-row pair fetch into XWA/XSP/XBC (two variants)
#   021463-02150D  Voice-slot update with note-source lookup
#   02150D-0215D6  Scan all slots: reassign note sources for one voice
#   0215DA-022198  Full state reset: clear all tables, re-init all slots
#   02219F-02228D  Per-tick voice update: DAC write + slot management
#   02229A-022309  Note-source chain walker (two variants)
#   022340-022582  Note-on dispatcher: allocate/move/evict voice slot
#   022587-022601  Voice release / envelope-off
#   022603-022683  Output-buffer flush helpers (two variants)
#   022691-02281F  Note-on packet handler with routing
#   022824-022863  4-level velocity quantiser (two variants)
#   02289D-0228D9  Instrument program/bank lookup
#   022912-02294B  Small bit-test predicates
#   02294E-0229EC  Pitch-bend value processor
#   0229EC-022A22  Pitch-bend clamp + align loop
#   022A32-022AE7  Slot parameter write (5 variants by struct stride)
#   022B02-022BA7  Audio value saturate / clamp helpers
#   022BB8-022BDB  Panning clamp with velocity scaling
#   022BF2-022C03  Signed clamp to [-0x78, +0x78]
#   022C06-022C8D  Portamento contribution calculation (two variants)
#   022CE8-022CF5  Portamento clamp to [0x18, 0x78]
#   022CF8-022D9E  Pitch-bend coefficient lookup (set A / set B)
#   022DA1-022DBA  Parameter initialise / signed clamp
#   022DBD          Note-state record clear
#   022DF7-022E26  Envelope depth cap
#   022E2A-022E9A  EG envelope compute (set A)
#   022EBA          EG envelope compute (simple, set A)
#   022F3C-022FAC  EG envelope compute (set B)
#   022FCC          EG envelope compute (simple, set B)
# ---------------------------------------------------------------------------

RENAMES = [
    # ------------------------------------------------------------------
    # 021000-0210CB  Ring-buffer offset threshold checker
    # Context: follows RingBuf_SetOffsetHi/Lo.  Reads the lo-byte offset
    # at mem[10214] and the hi-word at mem[10215], then clears (res 7)
    # active-flag bits in a voice-node pointed to by XWA+3/+4/+5
    # depending on which threshold bucket the offset falls in.
    # ------------------------------------------------------------------
    ('LABEL_02103B', 'RingBuf_CheckOffset_ClearFlags',
     'Check ring-buffer offset thresholds and clear active-flag bits in voice node'),

    ('LABEL_021054', 'RingBuf_CheckOffset_Level1',
     'Offset in [32,48): clear flags for node+4 and node+5'),

    ('LABEL_021063', 'RingBuf_CheckOffset_LoZero',
     'Lo-byte is 0: check hi-word against upper thresholds (80/64)'),

    ('LABEL_021075', 'RingBuf_CheckOffset_LoZero_Level1',
     'Hi-word in [64,80): clear flags for node+4 and node+5'),

    # ------------------------------------------------------------------
    # 021084-0210A1  2-bit quadrant decoder: A -> L (0/4/8/0)
    # Classifies a value into one of 4 quadrants and writes L.
    # Called by voice-slot update routines to select which pair of rows
    # to operate on.
    # ------------------------------------------------------------------
    ('LABEL_021084', 'Quad_Decode_A_To_L',
     'Decode A into quadrant index: <0x40->L=0, <0x80->L=4, <0xC0->L=8, else->L=0'),

    ('LABEL_02108D', 'Quad_Decode_Quarter2',
     'A in [0x40,0x80): set L=4, fall to return'),

    ('LABEL_021096', 'Quad_Decode_Quarter3',
     'A in [0x80,0xC0): set L=8, fall to return'),

    ('LABEL_02109F', 'Quad_Decode_Quarter4',
     'A >= 0xC0: set L=0, fall to return'),

    ('LABEL_0210A1', 'Quad_Decode_Return',
     'Common return for Quad_Decode_A_To_L'),

    # ------------------------------------------------------------------
    # 0210A2-0210CB  2-bit slot-pair decoder: C[1:0] -> L
    # Reads C bits 1:0 and adjusts A to produce a slot-within-row index
    # in L.  Used to translate a (row, slot) pair into a table-column
    # index when writing voice state.
    # ------------------------------------------------------------------
    ('LABEL_0210A2', 'SlotPair_Decode_C_To_L',
     'Decode C bits 1:0 and A into slot-column index L; C=0->nz guard'),

    ('LABEL_0210B5', 'SlotPair_Decode_Case1',
     'C=1: L = A & 0x3F'),

    ('LABEL_0210BC', 'SlotPair_Decode_Case2',
     'C=2: L = (A - 0x40) & 0x7F'),

    ('LABEL_0210C6', 'SlotPair_Decode_Case3',
     'C=3: L = A & 0x7F'),

    ('LABEL_0210CB', 'SlotPair_Decode_Return',
     'Common return for SlotPair_Decode_C_To_L'),

    # ------------------------------------------------------------------
    # 0210CC-021184  Voice-state swap using DE/BC table index pair
    # Reads source slot (A) and destination slot (C) from a 0xC-stride
    # table at mem[9446], swaps BW words between them, then writes the
    # new slot index into the next row of the same table.
    # ------------------------------------------------------------------
    ('LABEL_0210CC', 'VoiceState_SwapSlot_DE_BC',
     'Swap voice-state slot using DE/BC as source/dest indices into 0xC-stride table'),

    # ------------------------------------------------------------------
    # 021185-02129B  Voice-state swap using HL/IY table index pair
    # Identical logic to VoiceState_SwapSlot_DE_BC but uses HL/IY as
    # the register pair (different callers pass the indices that way).
    # ------------------------------------------------------------------
    ('LABEL_021185', 'VoiceState_SwapSlot_HL_IY',
     'Swap voice-state slot using HL/IY as source/dest indices into 0xC-stride table'),

    # ------------------------------------------------------------------
    # 02129C-021363  Voice-state swap with range-limit guard
    # Reads an existing slot index from a 0x5-stride table at mem[8486],
    # guards against >= 0xC0 (inactive marker), then calls one of the
    # two swap helpers above.  Saves/restores E and C on the stack.
    # ------------------------------------------------------------------
    ('LABEL_02129C', 'VoiceState_SwapSlot_Guarded',
     'Swap voice slot (0x5-stride table) with 0xC0 inactive guard; calls DE/BC or HL/IY swap'),

    ('LABEL_021306', 'VoiceState_SwapSlot_Guarded_MarkInactive',
     'Mark source slot as inactive (0xFF) before finishing guarded swap'),

    ('LABEL_02130A', 'VoiceState_SwapSlot_Guarded_WriteDst',
     'Write destination slot record in 0x5-stride table and return'),

    ('LABEL_021337', 'VoiceState_SwapSlot_Guarded_UseHL_IY',
     'Use HL/IY swap variant when destination slot is in lower range'),

    ('LABEL_02134E', 'VoiceState_SwapSlot_Guarded_Return',
     'Restore voice-node pointer and return from guarded swap'),

    # ------------------------------------------------------------------
    # 021364-0213CA  Voice-row pair fetch A (XWA/XSP variant)
    # Given slot index A, reads two rows from the 0x5-stride table pair
    # at mem[8486]/[8487] and returns their addresses in XWA and XSP.
    # ------------------------------------------------------------------
    ('LABEL_021364', 'VoiceRow_FetchPair_WA_SP',
     'Fetch voice-row address pair (hi->XWA, lo->XSP) from 0x5-stride tables at 8486/8487'),

    # ------------------------------------------------------------------
    # 0213CB-021462  Voice-row pair fetch B (XDE/XWA variant)
    # Similar to VoiceRow_FetchPair_WA_SP but delivers results in
    # XDE/XWA, and fetches additional rows for C.
    # ------------------------------------------------------------------
    ('LABEL_0213CB', 'VoiceRow_FetchPair_DE_WA',
     'Fetch voice-row address pair (hi->XDE, lo->XWA) from 0x5-stride tables at 8486/8487'),

    # ------------------------------------------------------------------
    # 021463-02150C  Voice-slot update with note-source lookup
    # Looks up a note-source record in a 0x1B-stride table at mem[7757]
    # for the given (voice, slot) pair.  Compares current source vs the
    # existing record and promotes the winning source.  Calls the row-
    # fetch helpers to update adjacent table entries.
    # ------------------------------------------------------------------
    ('LABEL_021463', 'VoiceSlot_UpdateNoteSource',
     'Update voice-slot note-source: compare, promote winner, call row-fetch helpers'),

    ('LABEL_0214AC', 'VoiceSlot_UpdateNoteSource_MarkInactive',
     'Mark note-source slot as inactive (0xFF) in note-source table'),

    ('LABEL_0214B6', 'VoiceSlot_UpdateNoteSource_WriteCurrent',
     'Write current note-source to 0x1B-stride table, select row-pair variant'),

    ('LABEL_0214E6', 'VoiceSlot_UpdateNoteSource_UseDE_WA',
     'Select DE/WA row-pair fetch variant for current note-source'),

    ('LABEL_0214FD', 'VoiceSlot_UpdateNoteSource_Return',
     'Store updated slot indices to XIZ and return'),

    # ------------------------------------------------------------------
    # 02150D-0215D5  Scan all slots for one voice: reassign note sources
    # Iterates over all 4 slots (0..3) for a given voice index.  For
    # each active slot, checks the current note-source match and
    # optionally calls VoiceSlot_UpdateNoteSource.  Uses a BERP counter
    # at 0xFB as the loop iterator.
    # ------------------------------------------------------------------
    ('LABEL_02150D', 'Voice_ScanSlots_ReassignSources',
     'Scan 4 voice slots; for each active slot reassign note source via UpdateNoteSource'),

    ('LABEL_021530', 'Voice_ScanSlots_LoopBody',
     'Per-slot body: check active flag, match source, call UpdateNoteSource if needed'),

    ('LABEL_02158A', 'Voice_ScanSlots_PromoteSource',
     'Promote matched source to primary slot and call UpdateNoteSource'),

    ('LABEL_0215A8', 'Voice_ScanSlots_MarkSlotInactive',
     'Mark current slot inactive (0xFF) in table after source mismatch'),

    ('LABEL_0215CD', 'Voice_ScanSlots_LoopNext',
     'Increment BERP 0xFB counter and loop back to ScanSlots_LoopBody'),

    ('LABEL_0215D6', 'Voice_ScanSlots_Return',
     'Restore frame and return from Voice_ScanSlots_ReassignSources'),

    # ------------------------------------------------------------------
    # 0215DA-022197  Full voice-state reset
    # Three-phase reset:
    #   Phase 1 (0215DA-021661): iterate all 0x40 note-source slots,
    #     zero out each slot's 4-column row in the 0xC-stride table.
    #   Phase 2 (021661-0216D9): iterate all 0xC0 voice slots,
    #     init entries in the 0x5-stride tables at 8486-8490.
    #   Phase 3 (0216DA-021749): iterate 0x1B note-source entries,
    #     clear all row records; then iterate 0xC0 voice slots calling
    #     VoiceSlot_UpdateNoteSource to initialise each one.
    # Followed by: initialise all 0x40 voice-node structs, then activate
    # them, then zero the 4 interrupt-mask table pairs.
    # ------------------------------------------------------------------
    ('LABEL_0215DA', 'VoiceState_FullReset',
     'Full voice/slot/note-source state reset: clear all tables and re-init all structs'),

    ('LABEL_0215E4', 'VoiceState_FullReset_Phase1_SlotLoop',
     'Phase 1 outer loop: iterate 0x40 note-source indices'),

    ('LABEL_0215EA', 'VoiceState_FullReset_Phase1_ColLoop',
     'Phase 1 inner loop: zero 4 columns of 0xC-stride row for one note-source'),

    ('LABEL_021658', 'VoiceState_FullReset_Phase1_Next',
     'Increment Phase 1 outer counter and loop'),

    ('LABEL_021661', 'VoiceState_FullReset_Phase2',
     'Phase 2: iterate 0xC0 voice slots, init 0x5-stride table entries'),

    ('LABEL_02166A', 'VoiceState_FullReset_Phase2_Body',
     'Phase 2 per-slot: copy initial pointers and write 0xFF terminator'),

    ('LABEL_0216DA', 'VoiceState_FullReset_Phase3',
     'Phase 3: clear 0x1B note-source records then re-init all voice slots'),

    ('LABEL_0216E3', 'VoiceState_FullReset_Phase3_ClearLoop',
     'Phase 3 outer loop: iterate 0x1B note-source records'),

    ('LABEL_0216EA', 'VoiceState_FullReset_Phase3_ClearInner',
     'Phase 3 inner loop: write 0xFF to each column of one note-source row'),

    ('LABEL_021711', 'VoiceState_FullReset_Phase3_ClearNext',
     'Increment Phase 3 clear-loop counter and loop'),

    ('LABEL_02171A', 'VoiceState_FullReset_Phase3_InitSlots',
     'Phase 3 slot init: iterate 0xC0 voice slots calling VoiceSlot_UpdateNoteSource'),

    ('LABEL_021723', 'VoiceState_FullReset_Phase3_InitBody',
     'Phase 3 per-slot: call Quad_Decode then VoiceSlot_UpdateNoteSource'),

    ('LABEL_02174A', 'VoiceState_FullReset_Phase3_Return',
     'Pop XIZ and return from Phase 3 slot-init loop'),

    # ------------------------------------------------------------------
    # 02174C-02177D  Note-source row selector
    # Given a 2-bit mode in WA, selects one of three possible pointer
    # rows from the note-source table at mem[8459].  Returns the
    # selected pointer in L.
    # ------------------------------------------------------------------
    ('LABEL_02174C', 'NoteSource_SelectRow',
     'Select note-source table row by 2-bit mode in WA: 0->*bc, 1->*(bc+4), 2/3->*(bc+8)'),

    ('LABEL_021768', 'NoteSource_SelectRow_Case1',
     'Mode=1: return *(bc+4)'),

    ('LABEL_02176D', 'NoteSource_SelectRow_Case2',
     'Mode=2: return *(bc+8) if < 0xC0, else fallback to *(bc+4)'),

    ('LABEL_02177A', 'NoteSource_SelectRow_Case3',
     'Mode=3: return *(bc+8)'),

    ('LABEL_02177D', 'NoteSource_SelectRow_Return',
     'Common return for NoteSource_SelectRow'),

    # ------------------------------------------------------------------
    # 02177E-021975  Voice-slot assign: find matching or free slot
    # Given a packed (flags/voice/note/inst) descriptor, searches the
    # 0x5-stride voice-slot table for a matching entry or a free slot.
    # Calls SlotPair_Decode and VoiceState_SwapSlot_Guarded to update
    # the state; packs result into HL (high byte = flags, low = col).
    # ------------------------------------------------------------------
    ('LABEL_02177E', 'VoiceSlot_Assign',
     'Find or create voice slot matching (voice, note, inst); return packed result in HL'),

    ('LABEL_02179C', 'VoiceSlot_Assign_NoMatch',
     'No match or flags mismatch: return HL with 0xFF low byte'),

    ('LABEL_0217AD', 'VoiceSlot_Assign_Search',
     'Search note-source table for matching (note, inst) entry'),

    ('LABEL_021846', 'VoiceSlot_Assign_FallbackFB',
     'No direct match found: try BERP-0xFB slot via NoteSource_SelectRow'),

    ('LABEL_0218A8', 'VoiceSlot_Assign_FallbackFB_Inactive',
     'BERP-0xFB slot inactive (>=0xC0): return L=0xFF'),

    ('LABEL_0218AD', 'VoiceSlot_Assign_TryNoteSourceTable',
     'Try direct lookup in 0x1B-stride note-source table'),

    ('LABEL_021908', 'VoiceSlot_Assign_FallbackFA',
     'Note-source table inactive: try BERP-0xFA via NoteSource_SelectRow'),

    ('LABEL_021964', 'VoiceSlot_Assign_FA_Inactive',
     'BERP-0xFA slot inactive (>=0xC0): return L=0xFF'),

    ('LABEL_021966', 'VoiceSlot_Assign_PackResult',
     'Pack L (column) into HL with flags byte from stack'),

    ('LABEL_021976', 'VoiceSlot_Assign_Return',
     'Restore BERP 0xFA, unwind frame, return from VoiceSlot_Assign'),

    # ------------------------------------------------------------------
    # 02197C  .byte data block (not a routine)
    # Contains opaque encoded bytes between VoiceSlot_Assign and the
    # next function.  No rename needed, but included for completeness.
    # (Skipped — only LABEL_ entries that map to code are renamed.)
    # ------------------------------------------------------------------

    # ------------------------------------------------------------------
    # 021A8E-021B2E  Build note-output list for a voice
    # Iterates 0x1B note-source slots for a given voice/mask pair and
    # builds a packed output list at mem[10217] (DRAM), terminated by
    # 0xFFFF.  Packs (col, flags) words via SlotPair_Decode_C_To_L.
    # ------------------------------------------------------------------
    ('LABEL_021A8E', 'Voice_BuildOutputList',
     'Build packed note-output list for voice/mask; write to output area at mem[10217]'),

    ('LABEL_021AC0', 'Voice_BuildOutputList_Loop',
     'Per-slot loop: check mask, decode column, pack and write to output list'),

    ('LABEL_021B24', 'Voice_BuildOutputList_Next',
     'Increment slot counter and loop'),

    ('LABEL_021B2D', 'Voice_BuildOutputList_Return',
     'Write 0xFFFF terminator, restore output pointer, return'),

    # ------------------------------------------------------------------
    # 021BF5-021C57  Advance slot iterator for one voice
    # Given a voice index in A, iterates over the 0x30-stride range of
    # slots that belong to that voice, skipping inactive ones (flag byte
    # at offset +4 > 0x40 and source byte at offset +3 == 0x1A).
    # ------------------------------------------------------------------
    ('LABEL_021BF5', 'Voice_AdvanceSlotIterator',
     'Advance the active-slot iterator for one voice, skipping inactive slots'),

    ('LABEL_021C0B', 'Voice_AdvanceSlotIterator_Loop',
     'Per-slot check: skip if activity/source bytes indicate inactive'),

    ('LABEL_021C50', 'Voice_AdvanceSlotIterator_Next',
     'Increment IZ and loop back to iterator body'),

    ('LABEL_021C57', 'Voice_AdvanceSlotIterator_Return',
     'Restore IZ and return from slot iterator'),

    # ------------------------------------------------------------------
    # 021C5B  Doubly-linked list unlink: remove node, self-link
    # Given node pointer in XWA, reads prev/next pointers at +0/+4,
    # cross-links them, then self-links XWA so it points to itself.
    # ------------------------------------------------------------------
    ('LABEL_021C5B', 'DList_Unlink_SelfLink',
     'Unlink node from doubly-linked list (offsets +0/+4) and self-link it'),

    # ------------------------------------------------------------------
    # 021C6B  Doubly-linked list insert after XBC
    # Inserts XWA after XBC in the list using prev/next at offsets +0/+4.
    # ------------------------------------------------------------------
    ('LABEL_021C6B', 'DList_InsertAfter_Offsets0',
     'Insert XWA after XBC in doubly-linked list (offsets +0/+4)'),

    # ------------------------------------------------------------------
    # 021C83-021D19  Voice-node linked-list update (priority list, +29/+33 links)
    # Manages a priority-ordered doubly-linked list of voice nodes
    # accessed via offsets +29 (next ptr) and +33 (priority index).
    # Determines whether to self-link (head case) or insert after XBC.
    # ------------------------------------------------------------------
    ('LABEL_021C83', 'VoiceNode_PriorityList_Update',
     'Update voice-node priority list (+29/+33 offsets): unlink or insert node at correct position'),

    ('LABEL_021CBC', 'VoiceNode_PriorityList_SelfLink',
     'Node is head of priority list: self-link it'),

    ('LABEL_021CCE', 'VoiceNode_PriorityList_InsertOrLink',
     'Determine insert point in priority list and call DList helper'),

    ('LABEL_021D01', 'VoiceNode_PriorityList_Insert',
     'Non-empty list: insert XWA after XBC using DList_InsertAfter_Offsets0'),

    ('LABEL_021D1A', 'VoiceNode_PriorityList_Return',
     'Store updated prev-ptr and priority index, restore frame, return'),

    # ------------------------------------------------------------------
    # 021D2A  Doubly-linked list unlink: remove node (offsets +8/+12)
    # Same as DList_Unlink_SelfLink but uses offsets +8/+12 for the
    # second list head embedded in the same node structure.
    # ------------------------------------------------------------------
    ('LABEL_021D2A', 'DList_Unlink_SelfLink_Offsets8',
     'Unlink node from doubly-linked list (offsets +8/+12) and self-link it'),

    # ------------------------------------------------------------------
    # 021D3D  Doubly-linked list insert after XBC (offsets +8/+12)
    # ------------------------------------------------------------------
    ('LABEL_021D3D', 'DList_InsertAfter_Offsets8',
     'Insert XWA after XBC in doubly-linked list (offsets +8/+12)'),

    # ------------------------------------------------------------------
    # 021D59-021DF1  Voice-node linked-list update (secondary list, +24/+28)
    # Identical structure to VoiceNode_PriorityList_Update but manages a
    # different embedded list accessed via offsets +24 (next) and +28.
    # ------------------------------------------------------------------
    ('LABEL_021D59', 'VoiceNode_SecondList_Update',
     'Update voice-node secondary list (+24/+28 offsets): unlink or insert'),

    ('LABEL_021D94', 'VoiceNode_SecondList_SelfLink',
     'Node is head of secondary list: self-link it'),

    ('LABEL_021DA6', 'VoiceNode_SecondList_InsertOrLink',
     'Determine insert point in secondary list and call DList helper'),

    ('LABEL_021DD9', 'VoiceNode_SecondList_Insert',
     'Non-empty secondary list: insert XWA after XBC'),

    ('LABEL_021DF2', 'VoiceNode_SecondList_Return',
     'Store updated secondary-list ptr and index, restore frame, return'),

    # ------------------------------------------------------------------
    # 021E02  Voice-node: unlink from tertiary list (offsets +16/+20)
    # ------------------------------------------------------------------
    ('LABEL_021E02', 'DList_Unlink_SelfLink_Offsets16',
     'Unlink node from voice-node tertiary list (offsets +16/+20) and self-link'),

    # ------------------------------------------------------------------
    # 021E15  Voice-node: insert in tertiary list after XBC (offsets +16/+20)
    # ------------------------------------------------------------------
    ('LABEL_021E15', 'DList_InsertAfter_Offsets16',
     'Insert XWA after XBC in voice-node tertiary list (offsets +16/+20)'),

    # ------------------------------------------------------------------
    # 021E31-021E80  Voice-node activate
    # Clears bit 0 of flag byte at +34, decrements the priority counter
    # if non-zero, then calls all three list-update helpers to insert
    # this node at the correct positions in all three embedded lists.
    # Sets active flag at +34, clears decay counter at +37.
    # ------------------------------------------------------------------
    ('LABEL_021E31', 'VoiceNode_Activate',
     'Activate voice node: decrement priority, insert into all 3 lists, set active flag'),

    ('LABEL_021E48', 'VoiceNode_Activate_InsertLists',
     'Insert voice node into priority, secondary, and tertiary lists then set flags'),

    ('LABEL_021E81', 'VoiceNode_Activate_Return',
     'Restore XIZ and return from VoiceNode_Activate'),

    # ------------------------------------------------------------------
    # 021E83  Voice-node: begin release (bit 1 of flag byte)
    # Sets the release flag (bit 1) at +34, clears bit 0, then calls
    # VoiceNode_PriorityList_Update to reposition the node.
    # ------------------------------------------------------------------
    ('LABEL_021E83', 'VoiceNode_BeginRelease',
     'Begin voice-node release: set bit 1 of flag at +34, reposition in priority list'),

    # ------------------------------------------------------------------
    # 021EA1  Voice-node: check envelope/decay thresholds and advance state
    # Tests bit 7 (muted), compares decay counter at +37 to 0x80,
    # conditionally calls BeginRelease or advances to decay state.
    # ------------------------------------------------------------------
    ('LABEL_021EA1', 'VoiceNode_UpdateEnvState',
     'Check mute/decay thresholds on voice node and call BeginRelease or advance decay state'),

    # ------------------------------------------------------------------
    # 021ECB-021FA8  Tone-generator command emit loop
    # Emits a sequence of paired address+data writes to the tone
    # generator at 0x100000 (DAC interface) for a given voice.
    # Iterates two phases: first 0x40 entries at address offset 0x840,
    # then 0x40 entries at 0x800, then 0x40 at 0xC0/0x00.
    # ------------------------------------------------------------------
    ('LABEL_021ECB', 'ToneGen_EmitCommandLoop',
     'Emit tone-generator command sequence for voice: three phases of 0x40 pairs to 0x100000'),

    ('LABEL_021EDB', 'ToneGen_EmitCommandLoop_FindStart',
     'Find first empty command slot (word == 0x0000) among 4 entries'),

    ('LABEL_021EF8', 'ToneGen_EmitCommandLoop_PhaseA',
     'Phase A: emit 0x40 address+data pairs at TG base + 0x840'),

    ('LABEL_021F08', 'ToneGen_EmitCommandLoop_PhaseA_Body',
     'Phase A per-entry: write address (slot+0x840) then data (0xA200) to TG'),

    ('LABEL_021F26', 'ToneGen_EmitCommandLoop_PhaseA_Nop',
     'Phase A post-write NOPs (timing delay)'),

    ('LABEL_021F47', 'ToneGen_EmitCommandLoop_PhaseA_Nop2',
     'Phase A second post-write NOPs; increment and loop'),

    ('LABEL_021F53', 'ToneGen_EmitCommandLoop_PhaseB',
     'Phase B: emit 0x40 address+data pairs at TG base + 0x800'),

    ('LABEL_021F63', 'ToneGen_EmitCommandLoop_PhaseB_Body',
     'Phase B per-entry: write address (slot+0xC0 then slot) with data 0x0000/0x7E00'),

    ('LABEL_021F80', 'ToneGen_EmitCommandLoop_PhaseB_Nop',
     'Phase B post-write NOPs (timing delay)'),

    ('LABEL_021F9D', 'ToneGen_EmitCommandLoop_PhaseB_Nop2',
     'Phase B second post-write NOPs; increment and loop'),

    ('LABEL_021FA9', 'ToneGen_EmitCommandLoop_PhaseC',
     'Phase C: emit 0x12 entries using a command table lookup per voice'),

    # ------------------------------------------------------------------
    # 021FA9-022197  Command table init + channel struct init
    # Phase C continues: for each of 0x12 entries, looks up a command
    # record at mem[4397] (0x1E-stride) and zeroes 7 sub-fields.
    # Then 0x1B channel records at mem[4937] (0xC-stride) are zeroed.
    # Then 0x40 voice-node structs at mem[5261] (0x27-stride) are
    # initialised; finally, VoiceState_FullReset is called.
    # ------------------------------------------------------------------
    ('LABEL_021FB4', 'CmdTable_InitEntry_Loop',
     'Iterate 0x12 command-table entries: write voice ptr and zero 7 sub-fields'),

    ('LABEL_021FDF', 'CmdTable_InitEntry_AltPtr',
     'Alternate entry: use secondary pointer base 0xF519 for command record'),

    ('LABEL_022002', 'CmdTable_InitEntry_ZeroFields',
     'Zero command-table entry header byte, then zero 7 long sub-fields'),

    ('LABEL_02201B', 'CmdTable_InitEntry_ZeroLoop',
     'Inner loop: zero 7 XWA-sized sub-fields in one command-table entry'),

    ('LABEL_022045', 'CmdTable_InitEntry_Next',
     'Increment command-table index and loop back to CmdTable_InitEntry_Loop'),

    ('LABEL_02204F', 'ChanStruct_Init_Loop',
     'Iterate 0x1B channel structs at mem[4937] (0xC-stride): zero each one'),

    ('LABEL_02205A', 'ChanStruct_Init_Entry',
     'Init one channel struct: write pointer from 0xF52B/0xF597 then zero 2 sub-fields'),

    ('LABEL_022088', 'ChanStruct_Init_Entry_AltPtr',
     'Alternate channel struct init: use secondary base 0xF597'),

    ('LABEL_0220AE', 'ChanStruct_Init_ZeroSub',
     'Zero 2 long sub-fields in one channel struct'),

    ('LABEL_0220B4', 'ChanStruct_Init_ZeroLoop',
     'Inner loop: zero 2 sub-fields'),

    ('LABEL_0220DE', 'ChanStruct_Init_Next',
     'Increment channel-struct index and loop'),

    ('LABEL_0220E8', 'VoiceNode_Init_Loop',
     'Iterate 0x40 voice-node structs: write stride-ptr, init all fields and list ptrs'),

    ('LABEL_0220F2', 'VoiceNode_Init_Body',
     'Init one voice-node: set stride ptr, self-link all 3 lists, clear flags and counters'),

    ('LABEL_022142', 'VoiceNode_Activate_All',
     'Activate all 0x40 voice-node structs by calling VoiceNode_Activate on each'),

    ('LABEL_022150', 'VoiceNode_Activate_All_Loop',
     'Per-node: call VoiceNode_Activate, advance XIZ to next node'),

    ('LABEL_022161', 'IntMask_Clear_Loop',
     'Zero the 4 interrupt-mask table pairs at mem[10542]/[10550]'),

    ('LABEL_02216B', 'IntMask_Clear_Body',
     'Write 0x0000 to both interrupt-mask words for one channel'),

    ('LABEL_022198', 'AudioState_Init_Return',
     'Call VoiceState_FullReset and return from full audio-state init'),

    # ------------------------------------------------------------------
    # 02219F-02228C  Per-tick voice update (main audio tick handler)
    # Called every audio tick.  Increments a 2-bit voice counter at
    # mem[4392], writes a DAC sample, reads the interrupt-mask table,
    # XORs with the shadow, ANDs the delta, updates the shadow, then
    # iterates all active slots via linked-list traversal calling
    # VoiceNode_Activate/UpdateEnvState.  Terminates with AdvanceSlot.
    # ------------------------------------------------------------------
    ('LABEL_02219F', 'AudioTick_UpdateVoice',
     'Audio tick: advance voice counter, write DAC, process interrupt-mask delta, update all active slots'),

    ('LABEL_02222A', 'AudioTick_UpdateVoice_SlotLoop',
     'Per-slot: if mask bit set and slot active, call VoiceNode_Activate and ScanSlots'),

    ('LABEL_02224F', 'AudioTick_UpdateVoice_DecayCheck',
     'Slot inactive or mask clear: read decay sample and update decay counter + state'),

    ('LABEL_02227F', 'AudioTick_UpdateVoice_Next',
     'Advance slot pointer via XIZ linked list and loop'),

    ('LABEL_02228D', 'AudioTick_UpdateVoice_Return',
     'Call Voice_AdvanceSlotIterator for current voice then return'),

    # ------------------------------------------------------------------
    # 02229A-022308  Note-source chain walker, variant A
    # Checks if the global note-source pointer at mem[4933] is null.
    # If null, looks up the head of the chain from the command-table
    # at mem[4397] and walks the chain (bit 7 => secondary list,
    # else primary list) until a matching entry or 0xFF terminator.
    # Returns XHL = matched node pointer (or 0 if not found).
    # ------------------------------------------------------------------
    ('LABEL_02229A', 'NoteChain_FindNode_A',
     'Find note-chain node matching XBC: walk primary or secondary list from mem[4933]/[4397]'),

    ('LABEL_0222A7', 'NoteChain_FindNode_A_Walk',
     'Walk note-chain: dispatch to secondary-list or primary-list walker based on bit 7'),

    ('LABEL_0222BA', 'NoteChain_FindNode_A_Secondary',
     'Secondary-list walker: check bit 7 of node, load from secondary list'),

    ('LABEL_0222E2', 'NoteChain_FindNode_A_Primary',
     'Primary-list walker: load node from primary list'),

    ('LABEL_0222FF', 'NoteChain_FindNode_A_Advance',
     'Advance to next node in chain and loop'),

    ('LABEL_022306', 'NoteChain_FindNode_NotFound',
     'End of chain (0xFF terminator): return XHL = 0'),

    # ------------------------------------------------------------------
    # 022309-022340  Note-source chain walker, variant B
    # Variant B starts from a fixed base pointer 0xF603 instead of
    # the command-table pointer used by variant A.
    # ------------------------------------------------------------------
    ('LABEL_022309', 'NoteChain_FindNode_B',
     'Variant B note-chain walker: walk primary list starting at fixed base 0xF603'),

    ('LABEL_022319', 'NoteChain_FindNode_B_Walk',
     'Walk note-chain from fixed base: load from primary list until match or 0xFF'),

    ('LABEL_022336', 'NoteChain_FindNode_B_Advance',
     'Advance to next node in chain B and loop'),

    ('LABEL_02233D', 'NoteChain_FindNode_B_NotFound',
     'End of chain B (0xFF terminator): return XHL = 0'),

    # ------------------------------------------------------------------
    # 022340-022581  Note-on dispatcher: allocate or move voice slot
    # Main note-on handler.  Receives a packed note descriptor in XWA.
    # Extracts note/inst/voice fields, iterates 4 channel slots,
    # calls NoteChain_FindNode_A to find an existing node or allocates
    # a new one, then calls PriorityList and SecondList updates.
    # Handles "active" (bit 7) and "retrigger" (bit 6) flags.
    # ------------------------------------------------------------------
    ('LABEL_022340', 'NoteOn_Dispatch',
     'Note-on dispatcher: iterate 4 channel slots, allocate or promote voice node'),

    ('LABEL_022355', 'NoteOn_Dispatch_SlotLoop',
     'Per-slot: check active-bit flag, call chain walker, match or allocate node'),

    ('LABEL_022390', 'NoteOn_Dispatch_ProcessSlot',
     'Process one slot: call NoteChain_FindNode_A and decide action based on result'),

    ('LABEL_0223F0', 'NoteOn_Dispatch_ActivateNode',
     'Found node: decrement priority, set note fields, check retrigger bit'),

    ('LABEL_02242F', 'NoteOn_Dispatch_RetriggerActive',
     'Retrigger with active note: OR interrupt-mask for current slot'),

    ('LABEL_022444', 'NoteOn_Dispatch_Retrigger',
     'Retrigger without active note: AND interrupt-mask to clear then set via OR'),

    ('LABEL_022457', 'NoteOn_Dispatch_RetriggerMask',
     'Compute retrigger interrupt mask: clear old bit, set new bit'),

    ('LABEL_02247F', 'NoteOn_Dispatch_RetriggerOrMask',
     'OR the retrigger bit into interrupt-mask table'),

    ('LABEL_022492', 'NoteOn_Dispatch_UpdateLists',
     'Update priority list, secondary list, and tertiary list for activated node'),

    ('LABEL_0224BF', 'NoteOn_Dispatch_SetGlobalHead',
     'Node is new global head: store to mem[4393] and self-link tertiary'),

    ('LABEL_0224C8', 'NoteOn_Dispatch_AdvancePriority',
     'Increment priority counter if room; call SecondList walker for next node'),

    ('LABEL_0224DC', 'NoteOn_Dispatch_WalkNext',
     'Walk to next node in secondary list and update its priority list'),

    ('LABEL_022505', 'NoteOn_Dispatch_WriteSlot',
     'Write note-source index back to slot column and advance to next slot'),

    ('LABEL_022525', 'NoteOn_Dispatch_SlotNoNode',
     'No node found for slot: write 0xFF inactive marker to slot'),

    ('LABEL_02253B', 'NoteOn_Dispatch_SlotInactive',
     'Slot not active (bit 7 clear): write 0xFF inactive marker'),

    ('LABEL_02254F', 'NoteOn_Dispatch_SlotNext',
     'Increment slot counter and loop back to SlotLoop'),

    ('LABEL_02255B', 'NoteOn_Dispatch_AllInactive',
     'All 4 slots inactive: write 0xFF to each and return'),

    ('LABEL_022565', 'NoteOn_Dispatch_AllInactive_Loop',
     'Loop: write 0xFF inactive marker to each of 4 slot columns'),

    ('LABEL_022582', 'NoteOn_Dispatch_Return',
     'Restore frame and return from NoteOn_Dispatch'),

    # ------------------------------------------------------------------
    # 022587-022600  Voice release: clear active flag and update priority
    # Given a slot index in A (C copy), clears bit 7 of its 0x27-stride
    # struct entry, computes the interrupt-mask clear word, ANDs it into
    # the mask table, then calls VoiceNode_UpdateEnvState.
    # ------------------------------------------------------------------
    ('LABEL_022587', 'VoiceSlot_Release',
     'Release voice slot A: clear active flag, AND interrupt-mask, call UpdateEnvState'),

    ('LABEL_0225A8', 'VoiceSlot_Release_ApplyMask',
     'Compute complement mask for interrupt-mask table and AND it in'),

    # ------------------------------------------------------------------
    # 0225D3-022600  Voice note-off: update secondary list and env state
    # Checks if A < 0x40 (valid range), then calls SecondList_Update and
    # VoiceNode_UpdateEnvState; optionally unlinks from tertiary list.
    # ------------------------------------------------------------------
    ('LABEL_0225D3', 'VoiceSlot_NoteOff',
     'Note-off for voice slot A: update secondary list and call UpdateEnvState'),

    ('LABEL_022601', 'VoiceSlot_NoteOff_Return',
     'Pop XIZ and return from VoiceSlot_NoteOff'),

    # ------------------------------------------------------------------
    # 022603-022627  Output-buffer flush, variant A (retd 0x2)
    # Iterates a circular list of voice nodes starting at XBC.  For each
    # active node, writes its column index to the output word pointed to
    # by *(XWA).  Terminates by writing 0xFF.  Called via retd 0x2.
    # ------------------------------------------------------------------
    ('LABEL_022603', 'OutputBuf_Flush_A',
     'Flush active voice-node columns into output buffer A; write 0xFF terminator (retd 0x2)'),

    ('LABEL_02260B', 'OutputBuf_Flush_A_Loop',
     'Per-node: if flag set or note-field matches E, emit column index and advance ptr'),

    ('LABEL_022616', 'OutputBuf_Flush_A_Emit',
     'Emit column index from node+36 into output word and increment pointer'),

    ('LABEL_022621', 'OutputBuf_Flush_A_Next',
     'Advance to next node in list and loop'),

    ('LABEL_022628', 'OutputBuf_Flush_A_Done',
     'Write 0xFF terminator at output pointer and return (retd 0x2)'),

    # ------------------------------------------------------------------
    # 022630-022684  Output-buffer flush, variant B (retd 0x2)
    # Larger variant of OutputBuf_Flush_A.  Also walks a linked list but
    # additionally calls VoiceNode_SecondList_Update and UpdateEnvState
    # for each node it emits, and follows the tertiary-list links to
    # emit all siblings.
    # ------------------------------------------------------------------
    ('LABEL_022630', 'OutputBuf_Flush_B',
     'Flush active voice-node columns into output buffer B with secondary-list updates'),

    ('LABEL_02263C', 'OutputBuf_Flush_B_Loop',
     'Per-node: check flag or note-field match, then emit and update'),

    ('LABEL_022647', 'OutputBuf_Flush_B_Emit',
     'Emit column index, update secondary list, call UpdateEnvState, follow tertiary links'),

    ('LABEL_02267C', 'OutputBuf_Flush_B_Next',
     'Advance to next node in list and loop'),

    ('LABEL_022683', 'OutputBuf_Flush_B_Done',
     'Write 0xFF terminator and return (retd 0x2)'),

    # ------------------------------------------------------------------
    # 022691-02281E  Note-on packet handler with channel routing
    # Receives a 6-byte note-on packet in XWA.  Extracts note, voice,
    # and channel fields.  Depending on the routing bits in byte+3:
    #   - All channels (byte+3[12:8] != 0): iterate all 0x40 nodes,
    #     emit active ones to output buffer via OutputBuf_Flush_A/B.
    #   - Specific channel (byte+3[12:8] == 0): look up the channel's
    #     list head and dispatch through OutputBuf_Flush_A/B depending
    #     on various routing flags (bits 7, 6, bit 7 of byte+1, etc.).
    # ------------------------------------------------------------------
    ('LABEL_022691', 'NoteOn_RoutePacket',
     'Route note-on packet: extract channel, decide broadcast or targeted flush'),

    ('LABEL_0226C3', 'NoteOn_RoutePacket_BroadcastLoop',
     'Broadcast: iterate all 0x40 voice nodes, emit active ones to output buffer'),

    ('LABEL_0226D5', 'NoteOn_RoutePacket_BroadcastNext',
     'Advance to next voice node and loop in broadcast'),

    ('LABEL_0226DF', 'NoteOn_RoutePacket_BroadcastDone',
     'Write 0xFF terminator and jump to return'),

    ('LABEL_0226E8', 'NoteOn_RoutePacket_Targeted',
     'Targeted routing: look up channel list head, check sub-channel flags'),

    ('LABEL_022739', 'NoteOn_RoutePacket_Targeted_Loop',
     'Targeted loop: walk primary channel list calling OutputBuf_Flush_B'),

    ('LABEL_022761', 'NoteOn_RoutePacket_Targeted_Done',
     'Write 0xFF terminator after targeted primary-list flush'),

    ('LABEL_02276A', 'NoteOn_RoutePacket_Targeted_NoteZero',
     'Note field is zero: flush primary list once via OutputBuf_Flush_B'),

    ('LABEL_022785', 'NoteOn_RoutePacket_Targeted_SecondaryOnly',
     'Bit 6 set: flush secondary list only via OutputBuf_Flush_A'),

    ('LABEL_0227A3', 'NoteOn_RoutePacket_Targeted_BothLists_BitB',
     'Bit 7 of byte+3 set: flush both primary and secondary lists'),

    ('LABEL_0227DD', 'NoteOn_RoutePacket_Targeted_PrimaryOnly_BitA',
     'Bit 7 of byte+1 set: flush primary list only'),

    ('LABEL_0227FF', 'NoteOn_RoutePacket_Targeted_SecondaryOnly_B',
     'Default: flush secondary list only'),

    ('LABEL_022819', 'NoteOn_RoutePacket_InvalidChannel',
     'Channel index >= 0x1A: write 0xFF and skip to return'),

    ('LABEL_02281F', 'NoteOn_RoutePacket_Return',
     'Restore frame and return from NoteOn_RoutePacket'),

    # ------------------------------------------------------------------
    # 022824-022843  4-level velocity quantiser, variant A (4 thresholds)
    # Given a 7-bit value in A (bit 7 cleared), compares against 3
    # threshold bytes at XBC+0/+1/+2.  Returns L = 0..3 (level index).
    # ------------------------------------------------------------------
    ('LABEL_022824', 'VelocityQuantise_A',
     'Quantise 7-bit velocity A against 3 thresholds at XBC: return level 0..3 in L'),

    ('LABEL_022839', 'VelocityQuantise_A_Level2',
     'Level 2: value <= threshold 2, return L=2'),

    ('LABEL_02283D', 'VelocityQuantise_A_Level1',
     'Level 1: value <= threshold 1, return L=1'),

    ('LABEL_022841', 'VelocityQuantise_A_Level0',
     'Level 0: value <= threshold 0, return L=0'),

    ('LABEL_022843', 'VelocityQuantise_A_Return',
     'Common return for VelocityQuantise_A'),

    # ------------------------------------------------------------------
    # 022844-022863  4-level velocity quantiser, variant B
    # Identical structure to VelocityQuantise_A; used by a different
    # caller that passes a different threshold table base in XBC.
    # ------------------------------------------------------------------
    ('LABEL_022844', 'VelocityQuantise_B',
     'Quantise 7-bit velocity A against 3 thresholds at XBC: return level 0..3 in L (variant B)'),

    ('LABEL_022859', 'VelocityQuantise_B_Level2',
     'Level 2 (variant B)'),

    ('LABEL_02285D', 'VelocityQuantise_B_Level1',
     'Level 1 (variant B)'),

    ('LABEL_022861', 'VelocityQuantise_B_Level0',
     'Level 0 (variant B)'),

    ('LABEL_022863', 'VelocityQuantise_B_Return',
     'Common return for VelocityQuantise_B'),

    # ------------------------------------------------------------------
    # 02289D  Instrument program lookup (hi nibble of byte+42)
    # Given instrument index in A, reads the program nibble from a
    # 0x11F-stride table and uses it to look up a pointer in the
    # instrument-table at 0x011ACF.  Returns the pointer in XBC.
    # ------------------------------------------------------------------
    ('LABEL_02289D', 'Instrument_LookupProgram_HiNibble',
     'Look up instrument program (hi nibble of byte+42 in 0x11F table) -> XBC pointer'),

    # ------------------------------------------------------------------
    # 0228D9  Instrument bank lookup (lo nibble of byte+42)
    # Same structure as Instrument_LookupProgram_HiNibble but uses the
    # low nibble (bits 3:0) of byte+42 as the program selector.
    # ------------------------------------------------------------------
    ('LABEL_0228D9', 'Instrument_LookupProgram_LoNibble',
     'Look up instrument bank (lo nibble of byte+42 in 0x11F table) -> XBC pointer'),

    # ------------------------------------------------------------------
    # 022912-02291A  Bit 0 test: return 1 or 0 in L
    # ------------------------------------------------------------------
    ('LABEL_022912', 'BitTest_Bit0_L',
     'Test bit 0 of A; return L=1 if set, L=0 if clear'),

    ('LABEL_02291A', 'BitTest_Bit0_L_Clear',
     'Bit 0 clear: return L=0'),

    # ------------------------------------------------------------------
    # 02291D-02292D  2-bit mode test: bit1 inverts bit0 sense
    # If bit 1 set, return L=0; if bit 1 clear and bit 0 set, L=1; else L=0.
    # ------------------------------------------------------------------
    ('LABEL_02291D', 'BitTest_Mode2_L',
     'Test bit 1 of A: if set return L=0; else test bit 0, return L=1 or L=0'),

    ('LABEL_022925', 'BitTest_Mode2_L_Bit1Clear',
     'Bit 1 clear: test bit 0, return L=1 if set'),

    ('LABEL_02292D', 'BitTest_Mode2_L_AllClear',
     'Both bits clear: return L=0'),

    # ------------------------------------------------------------------
    # 022930-022938  Bit 0 test variant (duplicate): return 1 or 0 in L
    # ------------------------------------------------------------------
    ('LABEL_022930', 'BitTest_Bit0_L_v2',
     'Test bit 0 of A; return L=1 if set, L=0 if clear (variant 2)'),

    ('LABEL_022938', 'BitTest_Bit0_L_v2_Clear',
     'Bit 0 clear (variant 2): return L=0'),

    # ------------------------------------------------------------------
    # 02293B-02294B  2-bit mode test variant (duplicate)
    # ------------------------------------------------------------------
    ('LABEL_02293B', 'BitTest_Mode2_L_v2',
     'Test bit 1 of A: if set return L=0; else bit 0 -> L=1/0 (variant 2)'),

    ('LABEL_022943', 'BitTest_Mode2_L_v2_Bit1Clear',
     'Bit 1 clear (variant 2): test bit 0, return L=1 if set'),

    ('LABEL_02294B', 'BitTest_Mode2_L_v2_AllClear',
     'Both bits clear (variant 2): return L=0'),

    # ------------------------------------------------------------------
    # 02294E-022A22  Pitch-bend processor
    # 02294E: reads HWREG 0x041343, tests bit 1; if set returns 0 in HL.
    #   Otherwise subtracts 0x10 from A, range-checks 0..9, dispatches
    #   through a small jump table at 0xF693 (LABEL_022982 is the table).
    #   Returns a scaled pitch-bend value in HL.
    # 022986: fallback via 0x011ACF instrument table lookup with lo nibble.
    # 0229B1-022A22: clamp and align loop for bend values (signed 16-bit).
    # ------------------------------------------------------------------
    ('LABEL_02294E', 'PitchBend_Process',
     'Process pitch-bend byte A: range check, dispatch table, return scaled value in HL'),

    ('LABEL_02295C', 'PitchBend_Process_Dispatch',
     'Subtract 0x10 from A, check range 0..9, dispatch through jump table at 0xF693'),

    ('LABEL_022982', 'PitchBend_Process_JumpTable',
     'Pitch-bend dispatch jump table (4 bytes)'),

    ('LABEL_022986', 'PitchBend_Process_Fallback',
     'Fallback: look up pitch-bend coefficient from 0x011ACF table via lo nibble of C'),

    ('LABEL_02299C', 'PitchBend_Process_Return',
     'Return from PitchBend_Process'),

    # ------------------------------------------------------------------
    # 0229B1-022A22  Pitch-bend value clamp + signed compare
    # Clamps a signed 16-bit HL value relative to a "target centre"
    # (C << 8 + 0x80) vs bounds in C and E.  Returns HL saturated.
    # ------------------------------------------------------------------
    ('LABEL_02299D', 'PitchBend_Saturate',
     'Saturate signed 16-bit HL: clamp to [0xC000, 0x7FFF], then compare to bounds'),

    ('LABEL_0229AE', 'PitchBend_Saturate_Clamp7FFF',
     'Clamp HL to 0x7FFF (positive overflow)'),

    ('LABEL_0229B1', 'PitchBend_Saturate_CompareLo',
     'Compare HL to lo bound (C<<8+0x80); if below lo, return adjusted lo'),

    ('LABEL_0229CF', 'PitchBend_Saturate_CompareHi',
     'Compare HL to hi bound (E<<8+0x80); if above hi, return adjusted hi'),

    ('LABEL_0229EB', 'PitchBend_Saturate_Return',
     'Return from PitchBend_Saturate'),

    # ------------------------------------------------------------------
    # 0229EC-022A22  Pitch-bend align loop
    # Steps HL by ±0xC00 until it falls within [lo_bound, hi_bound].
    # ------------------------------------------------------------------
    ('LABEL_0229EC', 'PitchBend_AlignLoop_Init',
     'Init pitch-bend align loop: set HL = WA'),

    ('LABEL_0229F0', 'PitchBend_AlignLoop_CheckWrapped',
     'Check if HL > 0xC000 (negative overflow), adjust by +0xC00 or -0xC00'),

    ('LABEL_0229FC', 'PitchBend_AlignLoop_SubStep',
     'Subtract 0xC00 step in pitch-bend align loop'),

    ('LABEL_022A00', 'PitchBend_AlignLoop_CheckSign',
     'Check sign of adjusted HL; if negative loop back, else proceed to lo-bound check'),

    ('LABEL_022A09', 'PitchBend_AlignLoop_AddStep',
     'Add 0xC00 step in pitch-bend align loop'),

    ('LABEL_022A0D', 'PitchBend_AlignLoop_LoCheck',
     'Check HL against lo bound (C<<8+0x80): step up if below'),

    ('LABEL_022A1E', 'PitchBend_AlignLoop_SubFinal',
     'Subtract 0xC00 in final hi-bound adjustment'),

    ('LABEL_022A22', 'PitchBend_AlignLoop_HiCheck',
     'Check HL against hi bound (E<<8+0x80): step down if above, then return'),

    # ------------------------------------------------------------------
    # 022A32  Channel bit-field extract
    # Extracts bits 14:8 (7-bit field) from a packed word in BC and
    # returns the result in L via a table lookup.
    # ------------------------------------------------------------------
    ('LABEL_022A32', 'ChanBitField_ExtractHi7',
     'Extract bits [14:8] of BC (AND 0x7F00, SRA 8), table-lookup -> L'),

    # ------------------------------------------------------------------
    # 022A3F-022AE7  Slot parameter write helpers (5 variants by stride)
    # Each variant receives a slot index in DE, computes an offset into
    # a parameter struct using a different element count (stride), writes
    # a table address and data word into the struct, then stores the
    # data pointer at mem[10558].  Stride values: 0xF, 0xC, 0xD, 0xA, 0x6.
    # ------------------------------------------------------------------
    ('LABEL_022A3F', 'SlotParam_Write_Stride0F',
     'Write slot parameter record: stride 0xF, set OR-mask 0x7000 at slot+1, store data ptr'),

    ('LABEL_022A61', 'SlotParam_Write_Stride0C',
     'Write slot parameter record: stride 0xC, set OR-mask 0x5000 at slot+1, store data ptr'),

    ('LABEL_022A83', 'SlotParam_Write_Stride0D',
     'Write slot parameter record: stride 0xD, set OR-mask 0x3000 at slot+1, zero data'),

    ('LABEL_022AA4', 'SlotParam_Write_Stride0A',
     'Write slot parameter record: stride 0xA, set OR-mask 0x1000 at slot+1, zero data'),

    ('LABEL_022AC5', 'SlotParam_Write_Stride06',
     'Write slot parameter record: stride 0x6, set OR-mask 0x4000 at slot+1, store data ptr+4'),

    ('LABEL_022AE7', 'SlotParam_Write_Stride04_SLA',
     'Write slot parameter record: stride *4 (SLA 2), no OR-mask, zero data'),

    # ------------------------------------------------------------------
    # 022B02-022B16  Signed 16-bit saturate (WA)
    # Clamps WA to [0xC000, 0x7FFF]; returns in HL.
    # ------------------------------------------------------------------
    ('LABEL_022B02', 'SaturateS16_WA',
     'Saturate WA: if < 0xC000 return 0x7FFF, if > 0x7FFF return 0; else return WA in HL'),

    ('LABEL_022B13', 'SaturateS16_WA_Clamp7FFF',
     'Clamp WA to 0x7FFF'),

    ('LABEL_022B16', 'SaturateS16_WA_Return',
     'Return saturated value in HL'),

    # ------------------------------------------------------------------
    # 022B19-022B27  Signed clamp WA to [DE, BC]
    # If WA > BC clamp to BC; if WA < DE clamp to DE; else keep WA.
    # Returns result in HL.
    # ------------------------------------------------------------------
    ('LABEL_022B19', 'ClampS16_WA_To_DEBC',
     'Clamp WA to range [DE, BC]; return result in HL'),

    ('LABEL_022B21', 'ClampS16_WA_To_DEBC_CheckLo',
     'Check lo bound DE: if WA < DE clamp to DE'),

    ('LABEL_022B27', 'ClampS16_WA_To_DEBC_Return',
     'Return clamped value in HL'),

    # ------------------------------------------------------------------
    # 022B2A-022B52  Pitch-bend scale: sign-extend, table-multiply, shift
    # Resolves a signed pitch-bend byte (C, bit 7 cleared) to a
    # 16-bit scaled value via a table at 0xFEE4/0xFF64.  If A is
    # negative, negates and uses the negative-pitch row.
    # Uses extpfx2 (hardware multiply helper).
    # ------------------------------------------------------------------
    ('LABEL_022B2A', 'PitchBend_Scale',
     'Scale signed pitch-bend A via sign-resolve and table multiply; return scaled HL'),

    ('LABEL_022B43', 'PitchBend_Scale_Multiply',
     'Look up pitch scale factor in table 0xFF64, multiply via extpfx2, shift result'),

    # ------------------------------------------------------------------
    # 022B68-022BA7  Detune/pan value helpers
    # 022B68: signed clamp to [-0x32, +0x32]; look up in table 0x0119C8;
    #   negate if original was negative.
    # 022B8D: positive arm of same clamp.
    # 022BA7: unsigned clamp to [0, 0x32]; look up table 0x0119C8.
    # ------------------------------------------------------------------
    ('LABEL_022B68', 'Detune_ScaleSymmetric',
     'Clamp WA to [-0x32, +0x32], look up table 0x0119C8, negate if originally negative'),

    ('LABEL_022B79', 'Detune_ScaleSymmetric_NegArm',
     'Negative arm: clamp |WA| to 0x32, table lookup, negate result'),

    ('LABEL_022B8D', 'Detune_ScaleSymmetric_PosArm',
     'Positive arm: clamp WA to 0x32, look up table 0x0119C8'),

    ('LABEL_022B96', 'Detune_ScaleSymmetric_PosClamp',
     'Positive clamp: cap at 0x32'),

    ('LABEL_022BA4', 'Detune_ScaleSymmetric_Return',
     'Return scaled detune value in HL'),

    ('LABEL_022BA7', 'Detune_ScaleUnsigned',
     'Clamp WA to [0, 0x32] and look up table 0x0119C8; return in HL (unsigned variant)'),

    # ------------------------------------------------------------------
    # 022BB8-022BDB  Panning value with velocity scaling (retd 0x4)
    # Extracts the 7-bit pan from byte (word & 0x7F00) >> 8.  Compares
    # against the hi/lo bounds from the stack.  Then multiplies the
    # difference by a Q5 velocity factor (E, from stack+4) using extpfx2
    # and returns the scaled pan in HL.
    # ------------------------------------------------------------------
    ('LABEL_022BB8', 'Pan_ScaleWithVelocity',
     'Extract 7-bit pan, clamp to [lo, hi] from stack, scale by velocity (retd 0x4)'),

    ('LABEL_022BCF', 'Pan_ScaleWithVelocity_ClampLo',
     'Pan is below hi bound: check lo bound and use E if below'),

    ('LABEL_022BDB', 'Pan_ScaleWithVelocity_Multiply',
     'Multiply (pan - centre) by velocity Q5 factor; shift right 5 and return'),

    # ------------------------------------------------------------------
    # 022BF2-022C03  Signed clamp to [0, 0x78]
    # Clamps WA to 0x78 from above and to 0 from below (via cps check).
    # ------------------------------------------------------------------
    ('LABEL_022BF2', 'ClampS8_0_to_78',
     'Clamp WA to [0, 0x78]: cap at 0x78, floor at 0; return in HL'),

    ('LABEL_022BFD', 'ClampS8_0_to_78_CheckLo',
     'Check lo bound: if WA >= 0 keep, else clamp to 0'),

    ('LABEL_022C03', 'ClampS8_0_to_78_Return',
     'Return clamped value in HL'),

    # ------------------------------------------------------------------
    # 022C06-022C8D  Portamento contribution calculation, variant A
    # Reads portamento rate and depth from the voice-node instrument
    # data via XIZ (offset +23, +54, +57-59).  Multiplies by a Q5
    # factor from table 0x11519.  Adds a fixed 0x18 baseline.
    # Clamps result via ClampS8_0_to_78 and returns (retd 0x2).
    # ------------------------------------------------------------------
    ('LABEL_022C06', 'Portamento_CalcContrib_A',
     'Calculate portamento contribution (variant A): rate*depth product + 0x18, clamped to [0,0x78]'),

    ('LABEL_022C48', 'Portamento_CalcContrib_A_DepthScale',
     'Compute depth-scaled portamento: clamp DE to [min,max] from instrument then scale'),

    ('LABEL_022C6A', 'Portamento_CalcContrib_A_ClampHi',
     'Clamp portamento value to hi bound from instrument'),

    ('LABEL_022C7A', 'Portamento_CalcContrib_A_Multiply',
     'Multiply clamped portamento depth by Q5 factor, add to BC, return (retd 0x2)'),

    ('LABEL_022C8D', 'Portamento_CalcContrib_A_AddBaseline',
     'Add 0x18 baseline and clamp final portamento value'),

    # ------------------------------------------------------------------
    # 022C99-022CDF  Portamento contribution calculation, variant B
    # Uses offsets +15/+16 in the instrument record instead of +54/+57.
    # Otherwise identical structure to variant A.
    # ------------------------------------------------------------------
    ('LABEL_022C99', 'Portamento_CalcContrib_B',
     'Calculate portamento contribution (variant B): offsets +15/+16 in instrument record'),

    ('LABEL_022CDF', 'Portamento_CalcContrib_B_AddBaseline',
     'Add 0x18 baseline and clamp (variant B)'),

    # ------------------------------------------------------------------
    # 022CE8-022CF5  Portamento clamp: add 0x18 then clamp to [0x18, 0x78]
    # ------------------------------------------------------------------
    ('LABEL_022CE8', 'Portamento_ClampAdd18',
     'Add 0x18 to WA and clamp result to maximum 0x78; return in HL'),

    ('LABEL_022CF5', 'Portamento_ClampAdd18_Return',
     'Return from Portamento_ClampAdd18'),

    # ------------------------------------------------------------------
    # 022CF8-022D9E  Pitch-bend coefficient lookup (two ROM sets)
    # Given a packed pitch-bend control byte in A:
    #   Bit 7 set  -> look up from ROM set B (table at 0x011A26)
    #   Bit 7 clear -> look up from ROM set A (table at 0x0119FC)
    # Both sets use a 3-byte stride for a 4-nibble index from bits 3:0.
    # Returns a packed (hi-byte coefficient | pitch-centre) in HL,
    # and writes an extended pitch value to mem[10560].
    # ------------------------------------------------------------------
    ('LABEL_022CF8', 'PitchBend_LookupCoeff',
     'Look up pitch-bend coefficient from ROM set A or B (bit 7 of A selects set)'),

    ('LABEL_022D53', 'PitchBend_LookupCoeff_SetA',
     'ROM set A path: look up coeff from 0x0119FC (3-byte stride), write to mem[10560]'),

    ('LABEL_022D9E', 'PitchBend_LookupCoeff_Return',
     'Combine coefficient and pitch-centre into HL and return'),

    # ------------------------------------------------------------------
    # 022DA1  Note-state record initialise
    # Writes default values 0x017F and 0x7F7F to the note-state struct
    # at XWA+66 and XWA+68.
    # ------------------------------------------------------------------
    ('LABEL_022DA1', 'NoteState_InitDefaults',
     'Write default values 0x017F / 0x7F7F to note-state record at XWA+66/+68'),

    # ------------------------------------------------------------------
    # 022DAC-022DBA  Signed clamp WA to [DE, BC] (short variant, no HL)
    # Simpler variant of ClampS16_WA_To_DEBC that writes to HL.
    # ------------------------------------------------------------------
    ('LABEL_022DAC', 'ClampS16_WA_Short',
     'Clamp WA to [DE, BC]; return result in HL (short variant without intermediate)'),

    ('LABEL_022DB4', 'ClampS16_WA_Short_CheckLo',
     'Check lo bound DE: if WA < DE use DE'),

    ('LABEL_022DBA', 'ClampS16_WA_Short_Return',
     'Return clamped value in HL'),

    # ------------------------------------------------------------------
    # 022DBD  Note-state record clear
    # Given (voice, note-source) pair (A, C), computes address in a
    # 0x9 x 0x1B sub-table at 0x04424E and zeroes 7 fields.
    # ------------------------------------------------------------------
    ('LABEL_022DBD', 'NoteState_ClearRecord',
     'Clear note-state sub-table record for (voice, note-source) pair at 0x04424E'),

    # ------------------------------------------------------------------
    # 022DF7-022E26  Envelope depth cap
    # Computes how much of the voice-delta budget the primary depth
    # consumes by calling LABEL_03D8CA twice (log/exp math), then caps
    # XHL at the available budget.
    # ------------------------------------------------------------------
    ('LABEL_022DF7', 'EnvDepth_Cap',
     'Compute and cap envelope depth: two LABEL_03D8CA calls, clamp XHL to budget'),

    ('LABEL_022E26', 'EnvDepth_Cap_Return',
     'Return from EnvDepth_Cap'),

    # ------------------------------------------------------------------
    # 022E2A-022E99  EG envelope compute, set A
    # Given a note-source index, looks up the EG envelope struct in
    # a 0x1B-stride table at 0x04424E.  Reads the waveform index (byte+1)
    # from a lookup table at 0x010A64 to get a pointer, then calls
    # LABEL_03D8CA for EG math.  Optionally subtracts an offset depth
    # via EnvDepth_Cap (bytes +5/+6).  Normalises by right-shifting 7
    # bits.  Looks up the output-format bits and ORs them into HL.
    # ------------------------------------------------------------------
    ('LABEL_022E2A', 'EGEnv_Compute_A',
     'Compute EG envelope output for set A: waveform lookup, EG math, optional depth subtract'),

    ('LABEL_022E8A', 'EGEnv_Compute_A_Normalise',
     'Normalise EG result: shift right 7, clamp to 0x1FFF'),

    ('LABEL_022E9A', 'EGEnv_Compute_A_FormatBits',
     'Apply output-format bits from struct byte 0 bits[1:0] and return HL'),

    # ------------------------------------------------------------------
    # 022EBA  EG envelope compute (simple, set A)
    # Simpler variant: uses a fixed waveform table at 0x010964, no
    # depth subtract step.  Returns a 14-bit value in XHL (shifted 7).
    # ------------------------------------------------------------------
    ('LABEL_022EBA', 'EGEnv_Compute_A_Simple',
     'Compute EG envelope (simple, set A): single LABEL_03D8CA call, shift 7, clamp to 0x3FFF'),

    # ------------------------------------------------------------------
    # 022F3C-022FAB  EG envelope compute, set B
    # Identical structure to EGEnv_Compute_A but uses a different
    # EG struct table at 0x044257 and waveform lookup at 0x010B64.
    # ------------------------------------------------------------------
    ('LABEL_022F3C', 'EGEnv_Compute_B',
     'Compute EG envelope output for set B: waveform lookup at 0x010B64, EG math'),

    ('LABEL_022F9C', 'EGEnv_Compute_B_Normalise',
     'Normalise EG result (set B): shift right 7, clamp to 0x1FFF'),

    ('LABEL_022FAC', 'EGEnv_Compute_B_FormatBits',
     'Apply output-format bits (set B) and return HL'),

    # ------------------------------------------------------------------
    # 022FCC  EG envelope compute (simple, set B)
    # Simple variant for set B using table at 0x044257 / 0x010964.
    # ------------------------------------------------------------------
    ('LABEL_022FCC', 'EGEnv_Compute_B_Simple',
     'Compute EG envelope (simple, set B): single LABEL_03D8CA call, shift 7, clamp to 0x3FFF'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    # Check maincpu for cross-references (none expected for 021/022 range,
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
