#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (bitmap/demo functions).

Covers three function groups in the main CPU program ROM:
  1. BitmapDredt0d (F35E04-F36FE1) — Bitmap display/drum-edit functions: MIDI
     note editing with tempo ring buffer processing, scroll/gate/velocity control,
     position tracking, chord editing, and note allocation management.
  2. FDemoText (F846FD-F86142) — Feature demo text display: MIDI voice probing,
     demo control panel message parsing, voice parameter sending, text layout
     and rendering with XML-like tag processing.
  3. BitMapOut (FB3F8C-FB5583) — Bitmap output/rendering: VGA palette loading,
     pixel blitting to VRAM, voice preset snapshot/restore to/from ROM backup,
     voice structure field copying, and change-detection delta encoding.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Naming conventions:
#   - FunctionPrefix_ActionDescription format
#   - Be specific about what each branch/label does
#   - Groups follow natural function boundaries visible in the source
# ---------------------------------------------------------------------------

RENAMES = [
    # ==================================================================
    # BitmapDredt0d (F35E04-F36FE1) — Bitmap Drum-Edit Display Functions
    # Handles note editing for the drum/bitmap editor screen including
    # MIDI event dispatch, scroll position, gate/velocity, chord editing.
    # ==================================================================

    # --- Dispatch entry return values (F35E04-F35E10) ---
    ('LABEL_F35E04', 'BitmapDredt0d_ReturnDataPtr',
     'Return ROM pointer for event 0x1E000A1'),

    ('LABEL_F35E0A', 'BitmapDredt0d_ReturnSizeA8',
     'Return size 0xA8 for event 0x1E000A2'),

    ('LABEL_F35E10', 'BitmapDredt0d_ReturnSize77',
     'Return size 0x77 for event 0x1E000A3'),

    # --- Stream position advance (F35E16-F35E29) ---
    ('LABEL_F35E16', 'BmDrEdit_AdvanceStreamPos',
     'Advance stream position byte at 0x0210a6, wrap to next page'),

    ('LABEL_F35E29', 'BmDrEdit_AdvanceStreamWrap',
     'Wrap stream position: compute new page/offset from ROM table at 0x0B0000'),

    # --- Forward scan: read notes from tempo data (F35E60-F35F87) ---
    ('LABEL_F35E60', 'BmDrEdit_ScanForwardInit',
     'Init forward scan: save state, load params, setup note counters'),

    ('LABEL_F35EB8', 'BmDrEdit_ScanForwardLoop',
     'Forward scan loop: read next byte from ROM stream'),

    ('LABEL_F35EF0', 'BmDrEdit_ScanForward_CheckNote',
     'Check if byte is a note-on (0x9x) in forward scan'),

    ('LABEL_F35F56', 'BmDrEdit_ScanForward_NextByte',
     'Advance to next stream byte and check for end-of-data marker'),

    ('LABEL_F35F87', 'BmDrEdit_ScanForward_Done',
     'Forward scan complete: restore iz and return'),

    # --- Backward scan: read notes from tempo data (F35F89-F360BA) ---
    ('LABEL_F35F89', 'BmDrEdit_ScanBackwardInit',
     'Init backward scan: save state, load params, setup counters'),

    ('LABEL_F35FD9', 'BmDrEdit_ScanBackwardLoop',
     'Backward scan loop: read next byte from ROM stream'),

    ('LABEL_F36010', 'BmDrEdit_ScanBackward_CheckNote',
     'Check if byte is a note-on (0x9x) and compare positions'),

    ('LABEL_F3602C', 'BmDrEdit_ScanBackward_ReadNoteParams',
     'Read note parameters from backward scan stream'),

    ('LABEL_F36089', 'BmDrEdit_ScanBackward_NextByte',
     'Advance to next byte and check for end in backward scan'),

    ('LABEL_F360BA', 'BmDrEdit_ScanBackward_Done',
     'Backward scan complete: restore iz and return'),

    # --- Note rendering dispatch (F360BC-F360D5) ---
    ('LABEL_F360BC', 'BmDrEdit_RenderNoteBlock',
     'Render a note block: setup, check display mode, dispatch to horizontal/vertical'),

    ('LABEL_F360D2', 'BmDrEdit_RenderNoteBlock_Vertical',
     'Dispatch to vertical-mode note rendering'),

    ('LABEL_F360D5', 'BmDrEdit_RenderNoteBlock_StoreCoords',
     'Store rendered note coordinates and call drawing routine'),

    # --- Note position calculation (F360F3-F361BD) ---
    ('LABEL_F360F3', 'BmDrEdit_CalcNotePosition',
     'Calculate note display position from stream offset and page'),

    ('LABEL_F36138', 'BmDrEdit_CalcNotePos_VerticalMode',
     'Calculate vertical-mode note display offset'),

    ('LABEL_F36142', 'BmDrEdit_CalcNotePos_ReadFields',
     'Read stream fields for position calculation'),

    ('LABEL_F361BD', 'BmDrEdit_CalcNotePos_ClampSize',
     'Clamp note size to available display area'),

    # --- Horizontal note rendering (F361C1-F361FE) ---
    ('LABEL_F361C1', 'BmDrEdit_RenderHorizontal',
     'Render note in horizontal display mode with X position from table'),

    ('LABEL_F361FE', 'BmDrEdit_RenderVertical',
     'Render note in vertical display mode with Y position from table'),

    # --- Secondary note block rendering (F3623B-F362C1) ---
    ('LABEL_F3623B', 'BmDrEdit_RenderSecondaryBlock',
     'Render secondary note block with different coordinates'),

    ('LABEL_F3625F', 'BmDrEdit_RenderSecondary_Vertical',
     'Dispatch to vertical secondary rendering'),

    ('LABEL_F36262', 'BmDrEdit_RenderSecondary_StoreCoords',
     'Store secondary block coordinates and call drawing'),

    ('LABEL_F36282', 'BmDrEdit_RenderSecondaryHoriz',
     'Render secondary block horizontal mode'),

    ('LABEL_F362C1', 'BmDrEdit_RenderSecondaryVert',
     'Render secondary block vertical mode'),

    # --- Secondary position calculation (F36306-F36373) ---
    ('LABEL_F36306', 'BmDrEdit_CalcSecondaryPosition',
     'Calculate secondary note display position'),

    ('LABEL_F36347', 'BmDrEdit_CalcSecondaryPos_Vert',
     'Calculate secondary vertical position offset'),

    ('LABEL_F36353', 'BmDrEdit_CalcSecondaryPos_ClampSize',
     'Clamp secondary note size and compute remaining display area'),

    ('LABEL_F36373', 'BmDrEdit_InitDisplayParams',
     'Initialize display parameters: resolution, grid, velocity defaults'),

    # --- Tempo animation timer (F3639C-F363AC) ---
    ('LABEL_F3639C', 'BmDrEdit_TempoAnimTimer',
     'Decrement tempo animation timer, trigger update at zero'),

    ('LABEL_F363AC', 'BmDrEdit_TempoAnimTimer_Reset',
     'Reset animation timer and dispatch to tempo sub-handlers'),

    # --- Tempo ring buffer processing (F363C3-F3645B) ---
    ('LABEL_F363C3', 'BmDrEdit_CheckTempoData',
     'Check if tempo ring buffer has data and sequencer is active'),

    ('LABEL_F363D9', 'BmDrEdit_CheckTempoData_ReadyToProcess',
     'Sequencer active: check for pending MIDI data to process'),

    ('LABEL_F363EF', 'BmDrEdit_ProcessTempoEvent',
     'Read and process one event from tempo ring buffer'),

    ('LABEL_F36424', 'BmDrEdit_ProcessTempoEvent_NoteOff',
     'Handle note-off: find matching note, clear allocation slot'),

    ('LABEL_F3644E', 'BmDrEdit_ClearNoteAndRefresh',
     'Clear active note flag and refresh display'),

    ('LABEL_F36455', 'BmDrEdit_ClearSlotAndRedraw',
     'Clear note allocation slot and trigger display redraw'),

    ('LABEL_F3645B', 'BmDrEdit_TempoEventLoop',
     'Check for more tempo events to process'),

    # --- Delay timer handlers (F36464-F364C9) ---
    ('LABEL_F36464', 'BmDrEdit_DecrementDelayA',
     'Decrement primary delay timer (display feedback)'),

    ('LABEL_F36479', 'BmDrEdit_DelayAExpired',
     'Primary delay expired: dispatch based on action code'),

    ('LABEL_F364A5', 'BmDrEdit_DecrementDelayB',
     'Decrement secondary delay timer'),

    ('LABEL_F364BA', 'BmDrEdit_DelayBExpired',
     'Secondary delay expired: reset and jump to handler'),

    ('LABEL_F364C9', 'BmDrEdit_DelayReturn',
     'Return from delay processing'),

    # --- Note allocation management (F364CA-F36510) ---
    ('LABEL_F364CA', 'BmDrEdit_AllocateNoteSlot',
     'Allocate note-on in available slot (1 or 8 channels)'),

    ('LABEL_F364D5', 'BmDrEdit_AllocateNote_Search',
     'Search for free note allocation slot'),

    ('LABEL_F364DF', 'BmDrEdit_AllocateNote_Loop',
     'Loop through note slots looking for empty one'),

    ('LABEL_F36510', 'BmDrEdit_AllocateNote_NextSlot',
     'Try next slot if current is occupied'),

    # --- Display refresh (F36517-F36555) ---
    ('LABEL_F36517', 'BmDrEdit_RefreshDisplayState',
     'Clear edit flag, send display command, set note-changed flag'),

    ('LABEL_F36527', 'BmDrEdit_CheckNoteType',
     'Check note type classification (drum vs melodic)'),

    ('LABEL_F36540', 'BmDrEdit_CheckNoteType_IsDrum',
     'Note is drum type: return 0xFFFF'),

    ('LABEL_F36544', 'BmDrEdit_CheckNoteType_NotDrum',
     'Note is not drum type: return 0'),

    ('LABEL_F36547', 'BmDrEdit_SaveSequencerState',
     'Save current sequencer mode and control state'),

    ('LABEL_F36552', 'BmDrEdit_SaveSeqState_SetMode95',
     'Set sequencer mode 0x95 (non-drum)'),

    ('LABEL_F36555', 'BmDrEdit_SaveSeqState_Apply',
     'Apply sequencer state and store settings'),

    # --- Scroll position: check busy (F3656A-F365B6) ---
    ('LABEL_F3656A', 'BmDrEdit_CheckScrollBusy',
     'Check if scroll animation is active (return busy if so)'),

    ('LABEL_F3657B', 'BmDrEdit_ScrollRight',
     'Scroll right: increment position, update display if within range'),

    ('LABEL_F3658E', 'BmDrEdit_ScrollRight_Done',
     'Scroll right complete: return success'),

    ('LABEL_F36591', 'BmDrEdit_CheckScrollBusyAlt',
     'Check scroll busy for left scroll direction'),

    ('LABEL_F365A2', 'BmDrEdit_ScrollLeft',
     'Scroll left: decrement position, update display'),

    ('LABEL_F365B3', 'BmDrEdit_ScrollLeft_Done',
     'Scroll left complete: return success'),

    ('LABEL_F365B6', 'BmDrEdit_ScrollReset',
     'Reset scroll state: clear offsets, set animation timer'),

    # --- Note pitch scroll (F365D6-F3668C) ---
    ('LABEL_F365D6', 'BmDrEdit_PitchScrollUp_Check',
     'Check if pitch scroll up is allowed (not busy)'),

    ('LABEL_F365E3', 'BmDrEdit_PitchScrollUp',
     'Scroll pitch up: increment note offset, update display'),

    ('LABEL_F36600', 'BmDrEdit_PitchScrollDown_Check',
     'Check if pitch scroll down is allowed'),

    ('LABEL_F3660D', 'BmDrEdit_PitchScrollDown',
     'Scroll pitch down: decrement note offset, update display'),

    # --- Velocity scroll (F36629-F3668C) ---
    ('LABEL_F36629', 'BmDrEdit_VelocityUp_Check',
     'Check if velocity up is allowed and note is active'),

    ('LABEL_F36636', 'BmDrEdit_VelocityUp_Dispatch',
     'Dispatch velocity up based on drum/melodic mode'),

    ('LABEL_F36644', 'BmDrEdit_VelocityDown_Check',
     'Check if velocity down is allowed'),

    ('LABEL_F36651', 'BmDrEdit_VelocityDown_Dispatch',
     'Dispatch velocity down based on drum/melodic mode'),

    ('LABEL_F3665F', 'BmDrEdit_IncrementVelocity',
     'Increment velocity value and send command'),

    ('LABEL_F3668C', 'BmDrEdit_DecrementVelocity',
     'Decrement velocity value and send command'),

    # --- Gate time and velocity control (F366B8-F36722) ---
    ('LABEL_F366B8', 'BmDrEdit_GateOrVelocityUp',
     'Gate/velocity up: check active note then dispatch'),

    ('LABEL_F366CE', 'BmDrEdit_GateOrVelocityDown',
     'Gate/velocity down: check active note then dispatch'),

    ('LABEL_F366E4', 'BmDrEdit_IncrementGateTime',
     'Increment gate time value and send gate command'),

    ('LABEL_F366FA', 'BmDrEdit_DecrementGateTime',
     'Decrement gate time value and send gate command'),

    ('LABEL_F3670F', 'BmDrEdit_IncrementVelocityValue',
     'Increment velocity register and send velocity command'),

    ('LABEL_F36722', 'BmDrEdit_DecrementVelocityValue',
     'Decrement velocity register and send velocity command'),

    # --- Duration scroll (F36734-F367E0) ---
    ('LABEL_F36734', 'BmDrEdit_DurationUp_Check',
     'Check if duration up is allowed (not scroll-busy)'),

    ('LABEL_F36741', 'BmDrEdit_DurationUp_Dispatch',
     'Dispatch to duration increment'),

    ('LABEL_F36743', 'BmDrEdit_DurationDown_Check',
     'Check if duration down is allowed'),

    ('LABEL_F36750', 'BmDrEdit_DurationDown_Dispatch',
     'Dispatch to duration decrement'),

    ('LABEL_F36752', 'BmDrEdit_IncrementDuration',
     'Increment duration: note active path or global path'),

    ('LABEL_F3677D', 'BmDrEdit_IncrementDuration_Global',
     'Increment global duration (no active note)'),

    ('LABEL_F36791', 'BmDrEdit_DecrementDuration',
     'Decrement duration: note active path or global path'),

    ('LABEL_F367A7', 'BmDrEdit_DecrementDuration_Clamp',
     'Clamp duration to minimum value of 1'),

    ('LABEL_F367B1', 'BmDrEdit_DecrementDuration_Update',
     'Update display after duration change'),

    ('LABEL_F367C6', 'BmDrEdit_DecrementDuration_Global',
     'Decrement global duration (no active note)'),

    ('LABEL_F367D6', 'BmDrEdit_DecrementDuration_GlobalClamp',
     'Clamp global duration to minimum'),

    ('LABEL_F367E0', 'BmDrEdit_DecrementDuration_Send',
     'Send duration scroll command after decrement'),

    # --- Mode scroll (F367E4-F3681E) ---
    ('LABEL_F367E4', 'BmDrEdit_ModeScrollUp',
     'Mode scroll up: increment mode value, send command'),

    ('LABEL_F367FE', 'BmDrEdit_ModeScrollDown',
     'Mode scroll down: decrement or wrap mode value'),

    ('LABEL_F36814', 'BmDrEdit_ModeScrollDown_Clamp',
     'Clamp mode scroll to minimum value'),

    ('LABEL_F3681E', 'BmDrEdit_ModeScrollDown_Send',
     'Send mode scroll command after decrement'),

    # --- Display feedback timer (F36822-F3682D) ---
    ('LABEL_F36822', 'BmDrEdit_SetFeedbackTimer',
     'Set display feedback timer (mode 133, action 1)'),

    ('LABEL_F3682D', 'BmDrEdit_SaveEditState',
     'Save current edit state (position, note, song indices)'),

    # --- Restore state and position tracking (F36846-F368C0) ---
    ('LABEL_F36846', 'BmDrEdit_RestoreEditState',
     'Restore saved edit state (position, note, song indices)'),

    ('LABEL_F3685F', 'BmDrEdit_ClearAndScanToEnd',
     'Clear track flag and scan forward to find data end'),

    ('LABEL_F36864', 'BmDrEdit_ScanToEnd_Loop',
     'Scan loop: walk through events to find end of track'),

    ('LABEL_F36874', 'BmDrEdit_ScanToEnd_CheckNextSong',
     'Check next song in sequence during end-scan'),

    ('LABEL_F36886', 'BmDrEdit_ScanToEnd_AdvanceSong',
     'Advance to next song and set large beat value'),

    ('LABEL_F36890', 'BmDrEdit_ScanToEnd_CheckEndMark',
     'Check for end-of-track marker during scan'),

    # --- Alternate state loading (F3689A-F368C0) ---
    ('LABEL_F3689A', 'BmDrEdit_LoadAlternateState',
     'Load alternate note/position state from saved area'),

    ('LABEL_F368B7', 'BmDrEdit_LoadAlternateAndCountNotes',
     'Load alternate state and begin counting notes'),

    ('LABEL_F368C0', 'BmDrEdit_CountNotesLoop',
     'Count notes loop: read events until note count reached'),

    ('LABEL_F368E7', 'BmDrEdit_CountNotesLoop_Retry',
     'Non-0x81 result: call helper and retry note count loop'),

    # --- Channel active check (F368ED-F3691F) ---
    ('LABEL_F368ED', 'BmDrEdit_CheckChannelActive',
     'Check if any channel has active note event (0x10)'),

    ('LABEL_F368F3', 'BmDrEdit_CheckChannelActive_Loop',
     'Loop through 16 channels checking for active notes'),

    ('LABEL_F3690B', 'BmDrEdit_CheckChannelActive_TestBit',
     'Test specific channel bit in active-channel mask'),

    ('LABEL_F36918', 'BmDrEdit_CheckChannelActive_Next',
     'Advance to next channel in active check'),

    ('LABEL_F3691F', 'BmDrEdit_CheckChannelActive_None',
     'No active channels found: clear flag'),

    # --- Channel selection with keyboard display (F36925-F36992) ---
    ('LABEL_F36925', 'BmDrEdit_SelectActiveChannel',
     'Find and select the first active channel for display'),

    ('LABEL_F3692F', 'BmDrEdit_SelectChannel_Loop',
     'Loop through channels searching for one with note 0x10'),

    ('LABEL_F36949', 'BmDrEdit_SelectChannel_TestBit',
     'Test channel bit mask against active-channel status'),

    ('LABEL_F3697F', 'BmDrEdit_SelectChannel_NextCh',
     'Advance to next channel in selection scan'),

    ('LABEL_F36988', 'BmDrEdit_SelectChannel_NotFound',
     'No matching channel found: clear selection flags'),

    ('LABEL_F36992', 'BmDrEdit_SelectChannel_Done',
     'Channel selection complete: pop state and return'),

    # --- Display position alignment (F36996-F369E6) ---
    ('LABEL_F36996', 'BmDrEdit_AlignDisplayGrid',
     'Align display position to nearest grid boundary'),

    ('LABEL_F369A4', 'BmDrEdit_AlignGrid_AccumLoop',
     'Accumulate grid steps until past current position'),

    ('LABEL_F369AA', 'BmDrEdit_AlignGrid_Store',
     'Store aligned display position'),

    # --- Velocity comparison scan (F369AF-F369E4) ---
    ('LABEL_F369AF', 'BmDrEdit_CompareVelocity',
     'Compare velocity at current position with stored value'),

    ('LABEL_F369E2', 'BmDrEdit_CompareVelocity_Equal',
     'Velocity matches: return 0'),

    ('LABEL_F369E4', 'BmDrEdit_CompareVelocity_Return',
     'Velocity compare return point'),

    # --- Song index save/restore (F369E6-F36A45) ---
    ('LABEL_F369E6', 'BmDrEdit_SaveSongPosition',
     'Save current song/beat position to indexed array'),

    ('LABEL_F36A0B', 'BmDrEdit_ReadEventAtPosition',
     'Read event byte at current position and store'),

    ('LABEL_F36A30', 'BmDrEdit_CheckNoteAtPosition',
     'Check if current event is a note-on, compare velocity'),

    # --- Track walk: count notes forward (F36A45-F36ABC) ---
    ('LABEL_F36A45', 'BmDrEdit_WalkTrackForward',
     'Walk track forward, counting notes and checking boundaries'),

    ('LABEL_F36A7E', 'BmDrEdit_WalkTrack_ProcessEvent',
     'Process one event during forward track walk'),

    ('LABEL_F36A90', 'BmDrEdit_WalkTrack_EndOfTrack',
     'End-of-track found: set end flag'),

    ('LABEL_F36A9A', 'BmDrEdit_WalkTrack_CheckNoteCount',
     'Check if note count has exceeded total'),

    ('LABEL_F36AB7', 'BmDrEdit_WalkTrack_CountExceeded',
     'Note count exceeded: set overflow flag'),

    ('LABEL_F36ABC', 'BmDrEdit_WalkTrack_CheckNoteOn',
     'Check for note-on events in forward walk, loop if not'),

    # --- Coordinate setup (F36ACE-F36AFD) ---
    ('LABEL_F36ACE', 'BmDrEdit_SetupCoordinates',
     'Setup display coordinates from position/beat data'),

    ('LABEL_F36AFD', 'BmDrEdit_SetupAndWalkToNote',
     'Setup coordinates then walk to first note at position'),

    # --- Note data extraction (F36B8C-F36BFC) ---
    ('LABEL_F36B8C', 'BmDrEdit_SetupAndWalkDone',
     'Coordinate setup and walk complete: restore state'),

    ('LABEL_F36B92', 'BmDrEdit_SaveAndFindNote',
     'Save edit state and find first note event'),

    ('LABEL_F36B95', 'BmDrEdit_FindNote_Loop',
     'Search loop for first note event from current position'),

    ('LABEL_F36BC4', 'BmDrEdit_FindNote_EndOfTrack',
     'End of track found during note search'),

    ('LABEL_F36BC7', 'BmDrEdit_FindNote_SkipNonNote',
     'Skip non-note events and continue search'),

    # --- Slot management (F36BCD-F36C4E) ---
    ('LABEL_F36BCD', 'BmDrEdit_ClearAllSlots',
     'Clear all note allocation slots in the slot array'),

    ('LABEL_F36BD6', 'BmDrEdit_ClearSlots_Loop',
     'Clear slots loop: zero each 3-byte entry'),

    ('LABEL_F36BE0', 'BmDrEdit_CheckAndSelectChannel',
     'Check channel activity then select matching channel'),

    ('LABEL_F36BE6', 'BmDrEdit_FindNoteInSlots',
     'Find a specific note number in the allocation slots'),

    ('LABEL_F36BF2', 'BmDrEdit_FindNote_SetupLoop',
     'Setup loop variables for note slot search'),

    ('LABEL_F36BFC', 'BmDrEdit_FindNote_SlotLoop',
     'Search each slot for matching note number'),

    ('LABEL_F36C2A', 'BmDrEdit_FindNote_NextSlot',
     'Note not found in this slot, try next'),

    ('LABEL_F36C30', 'BmDrEdit_FindNote_NotFound',
     'Note not found in any slot: return 0xFF'),

    ('LABEL_F36C33', 'BmDrEdit_FindNote_Return',
     'Return from note slot search'),

    ('LABEL_F36C35', 'BmDrEdit_ClearAllSlotsAlt',
     'Clear alternate set of note allocation slots'),

    ('LABEL_F36C3E', 'BmDrEdit_ClearSlotsAlt_Loop',
     'Clear alternate slots loop'),

    ('LABEL_F36C48', 'BmDrEdit_CheckSlotsAvailable',
     'Check if any note slot is available (all 8 checked)'),

    ('LABEL_F36C4E', 'BmDrEdit_CheckSlots_Loop',
     'Loop through slots checking availability'),

    ('LABEL_F36C60', 'BmDrEdit_CheckSlots_Next',
     'Advance to next slot in availability check'),

    # --- Position calculation helper (F36C6B-F36C93) ---
    ('LABEL_F36C6B', 'BmDrEdit_CalcBeatFromGridPos',
     'Calculate beat number from aligned grid display position'),

    ('LABEL_F36C93', 'BmDrEdit_ByteData_NoteCoordTable',
     'Byte data block: note coordinate transformation table'),

    # --- Chord display scroll (F36D04-F36D59) ---
    ('LABEL_F36D04', 'BmDrEdit_ChordScrollUp_Check',
     'Check if chord scroll up is allowed'),

    ('LABEL_F36D11', 'BmDrEdit_ChordScrollUp',
     'Scroll chord display up: increment chord index'),

    ('LABEL_F36D2F', 'BmDrEdit_ChordScrollDown_Check',
     'Check if chord scroll down is allowed'),

    ('LABEL_F36D3C', 'BmDrEdit_ChordScrollDown',
     'Scroll chord display down: decrement chord index'),

    ('LABEL_F36D59', 'BmDrEdit_NullReturn',
     'Null return (ret only)'),

    # --- Pitch wrap-around handling (F36D5A-F36D9B) ---
    ('LABEL_F36D5A', 'BmDrEdit_PitchWrapToEnd',
     'Wrap pitch scroll past start: move to end of current page'),

    ('LABEL_F36D73', 'BmDrEdit_PitchWrapPrevPage',
     'Wrap to previous page: decrement page, set offset to max'),

    ('LABEL_F36D8D', 'BmDrEdit_PitchWrap_UpdateDisplay',
     'Update display after pitch wrap'),

    ('LABEL_F36D9B', 'BmDrEdit_PitchWrap_CheckEnd',
     'Check if at track end: trigger page navigation'),

    # --- Duration position calculation (F36DB1-F36E02) ---
    ('LABEL_F36DB1', 'BmDrEdit_CalcDurationPosition',
     'Save state, find note-on, extract duration from stream'),

    ('LABEL_F36E02', 'BmDrEdit_UpdateGateDisplay',
     'Save state, find note, update gate time display'),

    # --- Velocity display update (F36E2F-F36E85) ---
    ('LABEL_F36E2F', 'BmDrEdit_UpdateVelocityDisplay',
     'Save state, find note, update velocity display value'),

    ('LABEL_F36E58', 'BmDrEdit_InsertNoteEvent',
     'Insert a new note event: clear slot, setup params, redraw'),

    ('LABEL_F36E7B', 'BmDrEdit_SendWidgetCmd',
     'Send widget command for drum mode display (if drum mode)'),

    ('LABEL_F36E85', 'BmDrEdit_NavigatePrevPage',
     'Navigate to previous page: save state, load, redraw all'),

    # --- Display refresh and redraw (F36EC1-F36EF2) ---
    ('LABEL_F36EC1', 'BmDrEdit_RefreshAfterInsert',
     'Refresh display after note insert: align grid, update counters'),

    ('LABEL_F36ED7', 'BmDrEdit_RefreshAfterInsert_CheckFull',
     'Check if display is full after refresh'),

    ('LABEL_F36EF2', 'BmDrEdit_SetupScrollRegion',
     'Setup scroll region coordinates from display mode'),

    ('LABEL_F36F0A', 'BmDrEdit_SetupScrollRegion_MelodicMode',
     'Setup melodic-mode scroll region from chord table'),

    # --- Display data blocks (F36F30-F36F5B) ---
    ('LABEL_F36F30', 'BmDrEdit_ByteData_ScrollParams',
     'Byte data block: scroll parameter table'),

    ('LABEL_F36F5B', 'BmDrEdit_InitDrumMode',
     'Init drum mode: allocate buffer, set drum-specific params'),

    ('LABEL_F36F8B', 'BmDrEdit_InitMelodicMode',
     'Init melodic mode: set melodic-specific grid and note count'),

    # --- Main initialization (F36FA7-F36FE1) ---
    ('LABEL_F36FA7', 'BmDrEdit_InitCommon',
     'Common init: validate mode, check song change, start display'),

    ('LABEL_F36FB6', 'BmDrEdit_InitCommon_CheckSongActive',
     'Check if sequencer song is active for initial display'),

    ('LABEL_F36FE1', 'BmDrEdit_InitCommon_SetupDisplay',
     'Setup initial display state: enable flags, store params'),

    # ==================================================================
    # FDemoText (F846FD-F86142) — Feature Demo Text Display
    # Handles demo mode text rendering, voice probing, MIDI parameter
    # sending, and XML-like text markup processing for the demo screen.
    # ==================================================================

    # --- Entry dispatch (F846FD-F84710) ---
    ('LABEL_F846FD', 'FDemoText_ReturnNull',
     'Event not 0x1E0009F: return NULL'),

    ('LABEL_F84700', 'FDemoText_LookupTableEntry',
     'Lookup function table entry by index (wa*4 + base)'),

    ('LABEL_F84710', 'FDemoText_ByteData_VoiceProbeA',
     'Byte data block: voice probe parameter sequence A'),

    ('LABEL_F84756', 'FDemoText_ByteData_VoiceProbeB',
     'Byte data block: voice probe parameter sequence B'),

    ('LABEL_F8476E', 'FDemoText_ByteData_VoiceProbeC',
     'Byte data block: voice probe parameter sequence C'),

    # --- Voice flag processing (F847DF-F84870) ---
    ('LABEL_F847DF', 'FDemoText_ProcessVoiceFlags',
     'Process voice change flags and detect new voice activation'),

    ('LABEL_F847FB', 'FDemoText_ProcessVoiceFlags_ReadState',
     'Read voice state and begin flag processing'),

    ('LABEL_F8482B', 'FDemoText_ProcessVoiceFlags_CheckBits',
     'Check voice flag bits and dispatch processing'),

    ('LABEL_F84843', 'FDemoText_ProbeVoice_Loop',
     'Probe voice status loop: check each voice channel'),

    ('LABEL_F84868', 'FDemoText_ProbeVoice_SetActive',
     'Voice probe found active: set active-voice flag'),

    ('LABEL_F84870', 'FDemoText_ProbeVoice_ClearActive',
     'Voice probe found inactive: clear active-voice flag'),

    # --- Voice channel processing (F84878-F848D0) ---
    ('LABEL_F84878', 'FDemoText_ProcessChannels',
     'Process each voice channel with flag comparison'),

    ('LABEL_F8487B', 'FDemoText_ProcessChannels_Loop',
     'Channel processing loop: compare old/new state'),

    ('LABEL_F848B2', 'FDemoText_ProcessChannel_Activate',
     'Channel newly activated: call activation handler'),

    ('LABEL_F848BC', 'FDemoText_ProcessChannel_CheckNoFlag',
     'Channel has no old flag: check new probe result'),

    ('LABEL_F848CD', 'FDemoText_ProcessChannel_Deactivate',
     'Channel deactivated: call deactivation handler'),

    ('LABEL_F848D0', 'FDemoText_ProcessChannel_CheckMask',
     'Check additional channel mask and call update if needed'),

    # --- Output channel processing (F848F4-F84977) ---
    ('LABEL_F848F4', 'FDemoText_ProcessOutputChannels',
     'Process output channels with display flag updates'),

    ('LABEL_F84923', 'FDemoText_ProcessOutput_CheckFlags',
     'Check output channel flags for display update'),

    ('LABEL_F84951', 'FDemoText_ProcessOutput_AltUpdate',
     'Output channel alternative display update path'),

    ('LABEL_F8495D', 'FDemoText_ProcessOutput_NextCh',
     'Advance to next output channel'),

    ('LABEL_F84965', 'FDemoText_ProcessOutput_ClearAll',
     'Clear all output channel flags and global mask'),

    ('LABEL_F84977', 'FDemoText_ProcessVoiceFlags_Return',
     'Return from voice flag processing'),

    # --- Voice activation/deactivation (F8497B-F849D5) ---
    ('LABEL_F8497B', 'FDemoText_ActivateVoice',
     'Activate voice: send MIDI command and update display table'),

    ('LABEL_F84994', 'FDemoText_ActivateVoice_Done',
     'Voice activation complete'),

    ('LABEL_F84997', 'FDemoText_DeactivateVoice',
     'Deactivate voice: clear flag from active mask'),

    ('LABEL_F849AC', 'FDemoText_ActivateVoiceAlt',
     'Activate voice via alternate path: probe, update, set flag'),

    ('LABEL_F849D4', 'FDemoText_DeactivateVoice_RetOnly',
     'Null deactivation (just return)'),

    ('LABEL_F849D5', 'FDemoText_UpdateVoiceDisplay',
     'Update voice display state: lookup table, set timer'),

    # --- Voice display update (F84A1B-F84A3B) ---
    ('LABEL_F84A1B', 'FDemoText_UpdateVoiceDisplay_CheckSend',
     'Check if voice change notification should be sent'),

    ('LABEL_F84A37', 'FDemoText_UpdateVoiceDisplay_Done',
     'Voice display update complete'),

    ('LABEL_F84A3B', 'FDemoText_SyncVoicePreset',
     'Synchronize voice preset to display table entries'),

    # --- Voice preset synchronization (F84A57-F84AC4) ---
    ('LABEL_F84A57', 'FDemoText_SyncPreset_ActiveLoop',
     'Sync active presets loop (has active flag bits)'),

    ('LABEL_F84A7D', 'FDemoText_SyncPreset_CallUpdate',
     'Call voice preset update handler'),

    ('LABEL_F84A80', 'FDemoText_SyncPreset_NextActive',
     'Advance to next active preset in sync loop'),

    ('LABEL_F84A8A', 'FDemoText_SyncPreset_DirectCopy',
     'Direct copy path: no active flags, copy from stored'),

    ('LABEL_F84A96', 'FDemoText_SyncPreset_DirectLoop',
     'Direct preset sync loop'),

    ('LABEL_F84AA6', 'FDemoText_SyncPreset_Compare',
     'Compare synced preset with stored value, send if changed'),

    ('LABEL_F84AC4', 'FDemoText_SyncPreset_Return',
     'Preset sync complete: restore state and return'),

    # --- Voice channel update (F84ACA-F84B2C) ---
    ('LABEL_F84ACA', 'FDemoText_UpdateChannelVoice',
     'Update single channel voice: lookup, probe, set value'),

    ('LABEL_F84AF9', 'FDemoText_UpdateChannel_Active',
     'Channel voice is active: set start value 0x50'),

    ('LABEL_F84B24', 'FDemoText_UpdateChannel_SendCmd',
     'Send command for channel voice update'),

    ('LABEL_F84B28', 'FDemoText_UpdateChannel_Done',
     'Channel voice update complete'),

    ('LABEL_F84B2C', 'FDemoText_CheckAndSetTimer',
     'Check channel state and set display timer if needed'),

    # --- Control panel message parsing (F84B6F-F84BF9) ---
    ('LABEL_F84B6F', 'FDemoText_ParseControlMessage',
     'Parse incoming control panel MIDI message for demo display'),

    ('LABEL_F84BCD', 'FDemoText_ParseCtrl_Type82',
     'Handle control message type 0x82'),

    ('LABEL_F84BF5', 'FDemoText_ParseCtrl_BuildWorkspace',
     'Build workspace item from parsed control message'),

    ('LABEL_F84BF9', 'FDemoText_ParseCtrl_SecondHalf',
     'Parse second half of control message'),

    # --- Control message continuation (F84B6F cont'd) ---
    ('LABEL_F84B6B', 'FDemoText_CheckTimer_Done',
     'Timer check complete: restore state and return'),

    # --- sendCOMM message builders (F84C3B-F84C61) ---
    ('LABEL_F84C3B', 'FDemoText_ParseCtrl_FormatC3',
     'Format control byte 0xC3 message (toggle type)'),

    ('LABEL_F84C5C', 'FDemoText_ParseCtrl_Finalize',
     'Finalize parsed control message and send'),

    ('LABEL_F84C61', 'FDemoText_SendResetMessage',
     'Send 4-part reset MIDI message via sendCOMM'),

    # --- Voice parameter sending (F84CBF-F84D88) ---
    ('LABEL_F84CBF', 'FDemoText_SendVoiceParams',
     'Send all voice parameters via MIDI: notes, levels, pan'),

    ('LABEL_F84D18', 'FDemoText_SendParams_NoteLoop',
     'Send note parameter loop (bytes 0x0B through 0x0C)'),

    ('LABEL_F84D55', 'FDemoText_SendParams_LevelLoop',
     'Send level parameter loop (bytes 4 through 8)'),

    ('LABEL_F84D88', 'FDemoText_SendVoiceParams_Return',
     'Voice parameter sending complete'),

    # --- Extended voice parameter sending (F84D8F-F84EB9) ---
    ('LABEL_F84D8F', 'FDemoText_SendExtVoiceParams',
     'Send extended voice parameters with pre-processing'),

    ('LABEL_F84DD6', 'FDemoText_SendExtParams_NoteLoop',
     'Extended send: note parameter loop'),

    ('LABEL_F84E00', 'FDemoText_SendExtParams_LevelLoop',
     'Extended send: level parameter loop'),

    ('LABEL_F84E3A', 'FDemoText_UpdatePartialVoice',
     'Update partial voice parameters from table'),

    ('LABEL_F84E70', 'FDemoText_UpdatePartial_NoteLoop',
     'Partial update: note byte send loop'),

    ('LABEL_F84EB4', 'FDemoText_UpdatePartial_Done',
     'Partial voice update complete'),

    ('LABEL_F84EB9', 'FDemoText_SendExtParamsAlt',
     'Alternate extended voice parameter send'),

    ('LABEL_F84EE4', 'FDemoText_SendExtAlt_NoteLoop',
     'Alternate send: note parameter loop'),

    # --- Voice probe helper (F84F2A-F84FA6) ---
    ('LABEL_F84F2A', 'FDemoText_ProbeVoiceType',
     'Probe voice type: build descriptor and call check routine'),

    ('LABEL_F84F56', 'FDemoText_ByteData_ProbeHelper',
     'Byte data block: voice probe helper sequence'),

    ('LABEL_F84F82', 'FDemoText_CheckVoiceState',
     'Check voice active state: probe type then return status code'),

    ('LABEL_F84FA1', 'FDemoText_CheckVoice_Inactive',
     'Voice is inactive: return 0'),

    ('LABEL_F84FA3', 'FDemoText_CheckVoice_Return',
     'Return from voice state check'),

    ('LABEL_F84FA6', 'FDemoText_CheckVoice_TypeF',
     'Voice type is F (special): return 2'),

    ('LABEL_F84FAA', 'FDemoText_CheckVoice_MaskedActive',
     'Check voice against masked active bits'),

    ('LABEL_F84FBF', 'FDemoText_CheckVoice_Active',
     'Voice confirmed active: return 1'),

    # --- MIDI channel scan (F84FC3-F850E4) ---
    ('LABEL_F84FC3', 'FDemoText_ScanMIDIChannels',
     'Scan MIDI channels for voice activity detection'),

    ('LABEL_F85014', 'FDemoText_ScanMIDI_WaitLoop',
     'Wait for MIDI response with timeout counter'),

    ('LABEL_F85026', 'FDemoText_ScanMIDI_ReadResponse',
     'Read MIDI scan response data'),

    ('LABEL_F8502E', 'FDemoText_ScanMIDI_ProcessChannel',
     'Process one MIDI channel scan result'),

    ('LABEL_F8503A', 'FDemoText_ScanMIDI_AdvanceTimeout',
     'Increment timeout counter for MIDI scan'),

    ('LABEL_F85040', 'FDemoText_ScanMIDI_ReadBytes',
     'Read MIDI response byte sequence'),

    ('LABEL_F85047', 'FDemoText_ScanMIDI_StoreResponseByte',
     'Store one response byte at indexed position'),

    ('LABEL_F85054', 'FDemoText_ScanMIDI_ByteLoop',
     'Loop until 6 response bytes collected'),

    ('LABEL_F85060', 'FDemoText_ScanMIDI_CheckStatus',
     'Check status byte 0x80 and adjust descriptor'),

    ('LABEL_F8506E', 'FDemoText_ScanMIDI_ExtendResponse',
     'Continue reading extended response up to 16 bytes'),

    ('LABEL_F85081', 'FDemoText_ScanMIDI_ExtendLoop',
     'Extended response collection loop'),

    ('LABEL_F85094', 'FDemoText_ScanMIDI_ValidateResponse',
     'Validate MIDI scan response: check size, mode, marker'),

    ('LABEL_F850B8', 'FDemoText_ScanMIDI_LookupActive',
     'Lookup active channel from response data'),

    ('LABEL_F850C7', 'FDemoText_ScanMIDI_NoMatch',
     'Response did not match: check for more data'),

    ('LABEL_F850CD', 'FDemoText_ScanMIDI_ReadNextFrame',
     'Read next MIDI frame and check for valid start'),

    ('LABEL_F850D6', 'FDemoText_ScanMIDI_CheckTimeout',
     'Check if scan has timed out'),

    ('LABEL_F850E4', 'FDemoText_ScanMIDI_UpdateFlags',
     'Update active/inactive flags based on scan results'),

    ('LABEL_F85100', 'FDemoText_ScanMIDI_SetActive',
     'Set channel as active in scan results'),

    ('LABEL_F85105', 'FDemoText_ScanMIDI_ClearActive',
     'Clear channel from active mask'),

    ('LABEL_F8510E', 'FDemoText_ScanMIDI_NextChannel',
     'Advance to next channel in scan'),

    # --- Stub returns (F8511D-F8511F) ---
    ('LABEL_F8511D', 'FDemoText_StubReturn_A',
     'Stub return A'),

    ('LABEL_F8511E', 'FDemoText_StubReturn_B',
     'Stub return B'),

    ('LABEL_F8511F', 'FDemoText_StubReturn_C',
     'Stub return C'),

    # --- Full voice rescan (F85120-F85186) ---
    ('LABEL_F85120', 'FDemoText_RescanAllVoices',
     'Rescan all voice channels: probe each and update flags'),

    ('LABEL_F85129', 'FDemoText_Rescan_Loop',
     'Voice rescan loop: probe and set/clear active flags'),

    ('LABEL_F8514E', 'FDemoText_Rescan_SetFlag',
     'Set active flag for voice in rescan'),

    ('LABEL_F85156', 'FDemoText_Rescan_NextVoice',
     'Advance to next voice in rescan'),

    ('LABEL_F85161', 'FDemoText_Rescan_SendUpdates',
     'Send parameter updates for active voices after rescan'),

    # --- UI notification (F85186-F851DE) ---
    ('LABEL_F85186', 'FDemoText_NotifyUIChange',
     'Notify UI of voice/preset change via command dispatch'),

    ('LABEL_F851B7', 'FDemoText_NotifyUI_Loop',
     'UI notification loop: send update for each voice slot'),

    ('LABEL_F851DC', 'FDemoText_NotifyUI_Done',
     'UI notification complete'),

    ('LABEL_F851DE', 'FDemoText_RefreshFullDisplay',
     'Force full display refresh: rescan voices, process widgets'),

    ('LABEL_F851FC', 'FDemoText_ByteData_DisplayRefresh',
     'Byte data block: display refresh parameter sequences'),

    # --- Text/XML tag processing (F8541D-F8562F) ---
    ('LABEL_F8541D', 'FDemoText_ProcessTextMarkup',
     'Process XML-like text markup: parse tags, render text segments'),

    ('LABEL_F8543A', 'FDemoText_ProcessMarkup_CheckTagOpen',
     'Check for opening tag (0x3C = "<")'),

    ('LABEL_F8544B', 'FDemoText_ProcessMarkup_LookupTag',
     'Lookup tag name in tag handler table'),

    ('LABEL_F8549D', 'FDemoText_ProcessMarkup_ScanTagEnd',
     'Scan for end of tag name (null or ">")'),

    ('LABEL_F854A1', 'FDemoText_ProcessMarkup_ScanLoop',
     'Tag name scan loop'),

    ('LABEL_F854AC', 'FDemoText_ProcessMarkup_AllocCopy',
     'Allocate buffer and copy tag content'),

    ('LABEL_F854F3', 'FDemoText_ProcessMarkup_ParseAttrs',
     'Parse tag attributes: split on spaces, handle quotes'),

    ('LABEL_F85535', 'FDemoText_ProcessMarkup_NullTermAttr',
     'Null-terminate attribute at > boundary'),

    ('LABEL_F85538', 'FDemoText_ProcessMarkup_ToggleQuote',
     'Toggle quote state for attribute parsing'),

    ('LABEL_F85540', 'FDemoText_ProcessMarkup_NextChar',
     'Advance to next character in attribute parsing'),

    ('LABEL_F8554A', 'FDemoText_ProcessMarkup_CallHandler',
     'Call tag handler function with parsed attributes'),

    ('LABEL_F85562', 'FDemoText_ProcessMarkup_SkipToEnd',
     'Skip to end of tag or end of string'),

    ('LABEL_F85576', 'FDemoText_ProcessMarkup_ScanClose',
     'Scan for closing ">" in unrecognized tag'),

    ('LABEL_F85585', 'FDemoText_ProcessMarkup_AfterHandler',
     'After tag handler: find end of content'),

    ('LABEL_F8558B', 'FDemoText_ProcessMarkup_FindNull',
     'Find null terminator after handler execution'),

    ('LABEL_F85595', 'FDemoText_ProcessMarkup_NextTag',
     'Advance to next tag in handler table'),

    ('LABEL_F85598', 'FDemoText_ProcessMarkup_TagTableLoop',
     'Loop through tag handler table entries'),

    ('LABEL_F855BA', 'FDemoText_ProcessMarkup_NoHandler',
     'No handler found: scan past unrecognized tag'),

    ('LABEL_F855C7', 'FDemoText_ProcessMarkup_PlainText',
     'Process plain text segment (no < tag prefix)'),

    ('LABEL_F855D3', 'FDemoText_ProcessMarkup_ScanPlainEnd',
     'Scan for end of plain text (until < or null)'),

    ('LABEL_F855DC', 'FDemoText_ProcessMarkup_CheckOpenTag',
     'Check for opening < in plain text scan'),

    ('LABEL_F855E8', 'FDemoText_ProcessMarkup_CopyAndRender',
     'Copy plain text to buffer and render it'),

    ('LABEL_F8562D', 'FDemoText_ProcessMarkup_Done',
     'Text markup processing complete: set return pointer'),

    ('LABEL_F8562F', 'FDemoText_ProcessMarkup_Return',
     'Pop state and return from markup processor'),

    # --- Text dispatch (F85634-F8571B) ---
    ('LABEL_F85634', 'FDemoText_ByteData_TextRenderer',
     'Byte data block: text rendering parameter sequences'),

    ('LABEL_F8571B', 'FDemoText_TextDispatch',
     'Text rendering dispatch: select handler by type code'),

    ('LABEL_F85726', 'FDemoText_TextDispatch_Return',
     'Return from text dispatch'),

    ('LABEL_F85729', 'FDemoText_ByteData_LayoutEngine',
     'Byte data block: text layout engine sequences'),

    # --- Coordinate helpers (F85E50-F85EC6) ---
    ('LABEL_F85E50', 'FDemoText_ScaleDownCoords',
     'Scale down coordinates: divide X by 8, Y by 4'),

    ('LABEL_F85E67', 'FDemoText_ScaleUpCoords',
     'Scale up coordinates: multiply X by 8, Y by 4 plus 3'),

    ('LABEL_F85E7A', 'FDemoText_CalcTextExtent',
     'Calculate text extent: measure width from character grid'),

    ('LABEL_F85EB0', 'FDemoText_CalcExtent_ScanLoop',
     'Scan character grid cells for text extent measurement'),

    ('LABEL_F85EC6', 'FDemoText_CalcExtent_Done',
     'Text extent calculation complete'),

    # --- Cursor positioning (F85ECA-F85F8C) ---
    ('LABEL_F85ECA', 'FDemoText_UpdateCursorPosition',
     'Update text cursor position based on current content'),

    ('LABEL_F85F3C', 'FDemoText_FindCursor_SearchLeft',
     'Search left from cursor for nearest non-empty cell'),

    ('LABEL_F85F4E', 'FDemoText_FindCursor_LeftDone',
     'Left search complete: check if position found'),

    ('LABEL_F85F5A', 'FDemoText_FindCursor_SearchRight',
     'Search right from cursor for nearest non-empty cell'),

    ('LABEL_F85F6A', 'FDemoText_FindCursor_RightNext',
     'Advance right cursor search'),

    ('LABEL_F85F72', 'FDemoText_FindCursor_StoreResult',
     'Store found cursor position and update layout'),

    ('LABEL_F85F86', 'FDemoText_FindCursor_NotFound',
     'No valid cursor position found'),

    ('LABEL_F85F88', 'FDemoText_FindCursor_Return',
     'Return from cursor position search'),

    ('LABEL_F85F8C', 'FDemoText_RenderTextLine',
     'Render a complete text line with word wrapping'),

    # --- Text line layout (F85FED-F86133) ---
    ('LABEL_F85FED', 'FDemoText_Layout_Setup',
     'Setup text layout parameters and measure string'),

    ('LABEL_F86076', 'FDemoText_Layout_NoWrap',
     'Text fits without wrapping: set no-wrap flag'),

    ('LABEL_F8607B', 'FDemoText_Layout_ProcessLine',
     'Process line layout: find break point and alignment'),

    ('LABEL_F860D3', 'FDemoText_Layout_AlignRight',
     'Right-align text: adjust X position'),

    ('LABEL_F860DD', 'FDemoText_Layout_DrawText',
     'Draw text with calculated alignment and position'),

    ('LABEL_F86112', 'FDemoText_Layout_UpdatePosition',
     'Update cursor position after drawing text'),

    ('LABEL_F86133', 'FDemoText_Layout_FreeBuffer',
     'Free allocated text buffer and return'),

    ('LABEL_F86142', 'FDemoText_ByteData_LayoutB',
     'Byte data block: additional text layout sequences'),

    # ==================================================================
    # BitMapOut (FB3F8C-FB5583) — Bitmap Output / Voice Preset Rendering
    # Handles VGA palette loading, pixel blitting to VRAM, and voice
    # preset snapshot/restore using ROM backup data, plus change
    # detection delta encoding for efficient display updates.
    # ==================================================================

    # --- VGA palette loading (FB3F8C-FB4011) ---
    ('LABEL_FB3F8C', 'BitMapOut_PaletteLoadLoop',
     'VGA palette loading loop: set R/G/B from color table'),

    ('LABEL_FB3FF0', 'BitMapOut_PixelBlitLoop',
     'Pixel blit loop: copy paired pixels to VRAM at 0x1A0000'),

    ('LABEL_FB4011', 'BitMapOut_BlitComplete',
     'Bitmap output complete: pop xiz, clean stack, return'),

    # --- Byte data blocks (FB4016-FB422A) ---
    ('LABEL_FB4016', 'BitMapOut_ByteData_RenderA',
     'Byte data block: bitmap render sequence A'),

    ('LABEL_FB40B7', 'BitMapOut_ByteData_RenderB',
     'Byte data block: bitmap render sequence B'),

    ('LABEL_FB4163', 'BitMapOut_ByteData_RenderC',
     'Byte data block: bitmap render sequence C (short)'),

    ('LABEL_FB4168', 'BitMapOut_ByteData_RenderD',
     'Byte data block: bitmap render sequence D'),

    ('LABEL_FB422A', 'BitMapOut_ByteData_RenderE',
     'Byte data block: bitmap render sequence E'),

    # --- Disk check and preset apply (FB4277-FB42D4) ---
    ('LABEL_FB4277', 'BitMapOut_CheckDiskAndApply',
     'Check disk status, dispatch preset apply or exit'),

    ('LABEL_FB4291', 'BitMapOut_ByteData_DiskCheck',
     'Byte data block: disk check sequence'),

    ('LABEL_FB4296', 'BitMapOut_StorePresetValue',
     'Store preset value byte'),

    ('LABEL_FB429B', 'BitMapOut_SetDefaultTimer',
     'Set default display timer (64 ticks)'),

    ('LABEL_FB42A1', 'BitMapOut_DecrementTimer',
     'Decrement display timer and trigger transition on zero'),

    ('LABEL_FB42D4', 'BitMapOut_ByteData_TransitionSeq',
     'Byte data block: display transition sequences'),

    # --- Voice preset multi-pixel copy (FB436C-FB45A9) ---
    ('LABEL_FB436C', 'BitMapOut_ByteData_PresetCopy',
     'Byte data block: voice preset pixel copy parameters'),

    ('LABEL_FB43D5', 'BitMapOut_CopyVoicePreset9',
     'Copy 9-field voice preset from ROM to display structures'),

    ('LABEL_FB43E5', 'BitMapOut_CopyPreset9_Clamp50',
     'Clamp preset index to 0x50 maximum'),

    ('LABEL_FB43EB', 'BitMapOut_CopyPreset9_Execute',
     'Execute 9-field preset copy from lookup table'),

    ('LABEL_FB4510', 'BitMapOut_CopyPreset9_StoreLoop',
     'Store variable-length preset data in loop'),

    ('LABEL_FB4520', 'BitMapOut_CopyPreset9_CheckEnd',
     'Check if all preset bytes copied'),

    ('LABEL_FB45A9', 'BitMapOut_CopyPreset9_Done',
     'Voice preset copy complete: restore and return'),

    # --- ROM backup snapshot/restore (FB45AE-FB4650) ---
    ('LABEL_FB45AE', 'BitMapOut_SnapshotFromROM',
     'Snapshot voice state from ROM backup to display'),

    ('LABEL_FB45BF', 'BitMapOut_Snapshot_Clamp50',
     'Clamp snapshot index to 0x50 maximum'),

    ('LABEL_FB45C5', 'BitMapOut_Snapshot_Execute',
     'Execute ROM snapshot: load preset, check for special type'),

    ('LABEL_FB4614', 'BitMapOut_Snapshot_RestorePartial',
     'Partial restore from ROM backup (non-writable type)'),

    ('LABEL_FB4619', 'BitMapOut_Snapshot_RestoreFull',
     'Full restore from ROM backup'),

    ('LABEL_FB461C', 'BitMapOut_Snapshot_PostProcess',
     'Post-snapshot: update display flags, check rendering mode'),

    ('LABEL_FB463A', 'BitMapOut_Snapshot_CheckActive',
     'Check if voice is actively rendering'),

    ('LABEL_FB4650', 'BitMapOut_Snapshot_SetFlags',
     'Set display mode flags after snapshot'),

    # --- Multi-field voice restore (FB4661-FB48A8) ---
    ('LABEL_FB4661', 'BitMapOut_RestoreVoiceFields',
     'Restore all voice fields from ROM backup to workspace'),

    ('LABEL_FB48A8', 'BitMapOut_RestoreFields_PostCheck',
     'Post-restore: check source type and update display'),

    # --- Full voice restore from backup (FB48C2-FB494D) ---
    ('LABEL_FB48C2', 'BitMapOut_RestoreFullVoice',
     'Full voice restore: copy all voice structure fields from ROM'),

    ('LABEL_FB48EC', 'BitMapOut_RestoreFull_FieldLoop',
     'Field copy loop: iterate through voice structure fields'),

    ('LABEL_FB4903', 'BitMapOut_RestoreFull_CopyField',
     'Copy one field from ROM backup to workspace'),

    ('LABEL_FB492B', 'BitMapOut_RestoreFull_CheckType0D',
     'Check for field type 0x0D (special handling)'),

    ('LABEL_FB4935', 'BitMapOut_RestoreFull_SkipField',
     'Skip field (already handled or type match)'),

    ('LABEL_FB493B', 'BitMapOut_RestoreFull_DefaultCopy',
     'Default field copy: byte-by-byte from ROM'),

    ('LABEL_FB4941', 'BitMapOut_RestoreFull_NextField',
     'Advance to next field in voice structure'),

    ('LABEL_FB4947', 'BitMapOut_RestoreFull_FieldDone',
     'One field group done: advance position counters'),

    ('LABEL_FB494D', 'BitMapOut_RestoreFull_CheckEnd',
     'Check if all voice structure fields have been copied'),

    # --- Extended structure copy (FB4A0F-FB4A83) ---
    ('LABEL_FB4A0F', 'BitMapOut_CopyPresetTable_Loop',
     'Copy voice preset table entries from ROM backup'),

    ('LABEL_FB4A27', 'BitMapOut_CopyPresetTable_Check',
     'Check if more table entries need copying'),

    ('LABEL_FB4A3D', 'BitMapOut_CopyExtTable_Loop',
     'Copy extended voice table entries from ROM backup'),

    ('LABEL_FB4A59', 'BitMapOut_CopyExtTable_Check',
     'Check extended table copy bounds'),

    ('LABEL_FB4A67', 'BitMapOut_CopyAuxTable_Loop',
     'Copy auxiliary voice table entries from ROM backup'),

    ('LABEL_FB4A83', 'BitMapOut_CopyAuxTable_Check',
     'Check auxiliary table copy bounds'),

    # --- Partial restore helper (FB4CCA-FB4D50) ---
    ('LABEL_FB4CCA', 'BitMapOut_PartialRestore',
     'Partial voice restore: rebuild from ROM then patch specific fields'),

    ('LABEL_FB4D50', 'BitMapOut_CopyROMToWorkspace',
     'Copy voice ROM data (0x3C0 bytes) to workspace at 0xF9A0'),

    # --- Selective field restore (FB4D71-FB4E0F) ---
    ('LABEL_FB4D71', 'BitMapOut_SelectiveFieldRestore',
     'Selectively restore changed fields based on dirty flags'),

    ('LABEL_FB4E0F', 'BitMapOut_SelectRestore_CheckBit1',
     'Check dirty bit 1: restore additional control fields'),

    ('LABEL_FB4E3D', 'BitMapOut_SelectRestore_CheckBit2',
     'Check dirty bit 2: restore status/mode fields'),

    ('LABEL_FB4E74', 'BitMapOut_SelectRestore_CheckBit3',
     'Check dirty bit 3: restore single value field'),

    ('LABEL_FB4E92', 'BitMapOut_SelectRestore_CheckBit4',
     'Check dirty bit 4: restore 2-field control block'),

    ('LABEL_FB4ED6', 'BitMapOut_SelectRestore_CheckVolBit',
     'Check volume dirty bit: copy voice preset table from ROM'),

    ('LABEL_FB4EF4', 'BitMapOut_SelectRestore_VolCopyLoop',
     'Volume preset table copy loop'),

    ('LABEL_FB4F03', 'BitMapOut_SelectRestore_CheckEffBit',
     'Check effect dirty bit: copy effect parameter table'),

    ('LABEL_FB4F1C', 'BitMapOut_SelectRestore_EffCopyLoop',
     'Effect parameter table copy loop'),

    # --- Voice channel structure restore (FB4F2B-FB532A) ---
    ('LABEL_FB4F2B', 'BitMapOut_RestoreVoiceChannels',
     'Restore all 18 voice channel structures from ROM'),

    ('LABEL_FB5306', 'BitMapOut_RestoreChannels_ByteLoop',
     'Copy individual bytes in voice channel structure'),

    ('LABEL_FB5318', 'BitMapOut_RestoreChannels_CheckEnd',
     'Check if all voice channel bytes have been copied'),

    ('LABEL_FB532A', 'BitMapOut_RestoreChannels_CheckParts',
     'Check if voice part structures need restoring'),

    ('LABEL_FB5339', 'BitMapOut_RestoreParts_OuterLoop',
     'Outer loop: iterate through 12 voice parts'),

    ('LABEL_FB533B', 'BitMapOut_RestoreParts_InnerLoop',
     'Inner loop: copy bytes within one voice part'),

    ('LABEL_FB5393', 'BitMapOut_RestoreParts_CopyByte',
     'Copy single byte from ROM to voice part structure'),

    ('LABEL_FB53A7', 'BitMapOut_RestoreParts_CheckPartEnd',
     'Check if current voice part copy is complete'),

    # --- Additional structure restore (FB53C7-FB5583) ---
    ('LABEL_FB53C7', 'BitMapOut_RestoreExtra_CheckBit6',
     'Check dirty bit 6: restore auxiliary structure'),

    ('LABEL_FB53E0', 'BitMapOut_RestoreExtra_AuxLoop',
     'Auxiliary structure byte copy loop'),

    ('LABEL_FB53EF', 'BitMapOut_RestoreExtra_CheckConfigBit',
     'Check configuration dirty bit: restore config block'),

    ('LABEL_FB5408', 'BitMapOut_RestoreExtra_ConfigLoop',
     'Configuration block byte copy loop'),

    ('LABEL_FB5417', 'BitMapOut_RestoreExtra_CheckDataBit',
     'Check data dirty bit: restore data fields and table'),

    ('LABEL_FB544B', 'BitMapOut_RestoreExtra_DataTableLoop',
     'Data table byte copy loop'),

    ('LABEL_FB545A', 'BitMapOut_RestoreExtra_CheckMiscBit',
     'Check misc dirty bit: restore misc value fields'),

    ('LABEL_FB5495', 'BitMapOut_RestoreExtra_CheckFlagBits',
     'Check secondary flag byte dirty bits'),

    ('LABEL_FB54B9', 'BitMapOut_RestoreExtra_CheckPanBit',
     'Check pan dirty bit: restore pan value'),

    ('LABEL_FB54D7', 'BitMapOut_RestoreExtra_CheckCtrlBit',
     'Check control dirty bit: restore control register'),

    ('LABEL_FB54F0', 'BitMapOut_RestoreExtra_CtrlCopyLoop',
     'Control register block copy loop'),

    ('LABEL_FB54FF', 'BitMapOut_RestoreExtra_CheckLevelBit',
     'Check level dirty bit: restore level and table data'),

    ('LABEL_FB5532', 'BitMapOut_RestoreExtra_LevelTableLoop',
     'Level table byte copy loop'),

    ('LABEL_FB5541', 'BitMapOut_RestoreExtra_CheckExpBit',
     'Check expression dirty bit: restore expression data'),

    ('LABEL_FB5574', 'BitMapOut_RestoreExtra_ExpTableLoop',
     'Expression table byte copy loop'),

    ('LABEL_FB5583', 'BitMapOut_RestoreExtra_Done',
     'Selective field restore complete: pop state and return'),

    # --- Display save/sync helper (FB5588) ---
    ('LABEL_FB5588', 'BitMapOut_SaveDisplayToROM',
     'Save current display workspace back to ROM area'),

    # --- Change detection and delta encoding (FB559F-FB578C) ---
    ('LABEL_FB559F', 'BitMapOut_DetectChanges',
     'Detect voice changes: compare workspace with ROM backup'),

    ('LABEL_FB55E7', 'BitMapOut_DetectChanges_CheckMode',
     'Check display mode for change detection bypass'),

    ('LABEL_FB55F5', 'BitMapOut_DetectChanges_UseShortList',
     'Use short change list (rapid refresh mode)'),

    ('LABEL_FB5606', 'BitMapOut_DetectChanges_FullScan',
     'Full scan: check all fields for changes'),

    ('LABEL_FB561E', 'BitMapOut_DeltaEncode_Init',
     'Initialize delta encoding scan loop'),

    ('LABEL_FB5623', 'BitMapOut_DeltaEncode_ReadEntry',
     'Read next entry from change table'),

    ('LABEL_FB564B', 'BitMapOut_DeltaEncode_ScanLoop',
     'Delta scan inner loop: compare each byte with ROM'),

    ('LABEL_FB568F', 'BitMapOut_DeltaEncode_BufferFull',
     'Change buffer full: switch to short list mode'),

    ('LABEL_FB56AE', 'BitMapOut_DeltaEncode_SlowTimeout',
     'Slow-mode timeout: force display refresh'),

    ('LABEL_FB56C5', 'BitMapOut_DeltaEncode_EncodeChange',
     'Encode one change: dispatch by type code'),

    ('LABEL_FB56E1', 'BitMapOut_DeltaEncode_Type48',
     'Encode type 0x48 change (voice parameter)'),

    ('LABEL_FB56F3', 'BitMapOut_DeltaEncode_Type90',
     'Encode type 0x90 change (control value)'),

    ('LABEL_FB5705', 'BitMapOut_DeltaEncode_GenericByte',
     'Encode generic byte change (store old/new/XOR)'),

    ('LABEL_FB5754', 'BitMapOut_DeltaEncode_NextByte',
     'Advance to next byte in delta encoding'),

    ('LABEL_FB575D', 'BitMapOut_DeltaEncode_NextEntry',
     'Advance to next change table entry'),

    ('LABEL_FB575F', 'BitMapOut_DeltaEncode_CheckBounds',
     'Check if delta scan has reached end of workspace'),

    ('LABEL_FB5788', 'BitMapOut_DeltaEncode_StoreShortLen',
     'Store short change list length'),

    ('LABEL_FB578C', 'BitMapOut_DeltaEncode_Return',
     'Delta encoding complete: pop state and return'),

    # --- IO port change dispatch (FB5791-FB5965) ---
    ('LABEL_FB5791', 'BitMapOut_DispatchIOChanges',
     'Dispatch I/O port register changes to hardware'),

    ('LABEL_FB57C8', 'BitMapOut_ApplyIOChange_Port0',
     'Apply I/O register change for port 0'),

    ('LABEL_FB582D', 'BitMapOut_ApplyIOChange_Port1',
     'Apply I/O register change for port 1'),

    ('LABEL_FB5892', 'BitMapOut_ApplyIOChange_Port2',
     'Apply I/O register change for port 2'),

    ('LABEL_FB58F7', 'BitMapOut_ApplyIOChange_Port3',
     'Apply I/O register change for port 3'),

    ('LABEL_FB592E', 'BitMapOut_ApplyIOChange_Port4',
     'Apply I/O register change for port 4'),

    ('LABEL_FB5965', 'BitMapOut_ApplyIOChange_Port5',
     'Apply I/O register change for port 5'),

    ('LABEL_FB599C', 'BitMapOut_DeltaEncode_TypeDefault',
     'Delta encode: default byte-level change handler'),

    ('LABEL_FB5A01', 'BitMapOut_DeltaEncode_TypeDefaultB',
     'Delta encode: default type B byte change handler'),

    ('LABEL_FB5A80', 'BitMapOut_DeltaEncode_TypeDefaultC',
     'Delta encode: default type C byte change handler'),

    ('LABEL_FB5AE4', 'BitMapOut_DeltaEncode_HelperCheckEnd',
     'Delta encode helper: check for end of data region'),

    ('LABEL_FB5AEB', 'BitMapOut_DeltaEncode_HelperReturn',
     'Delta encode helper: return point'),

    ('LABEL_FB5AF5', 'BitMapOut_DeltaEncode_Type48Handler',
     'Type 0x48 delta handler: voice parameter change'),

    ('LABEL_FB5B61', 'BitMapOut_DeltaEncode_Type48PartB',
     'Type 0x48 handler: second part'),

    ('LABEL_FB5B7A', 'BitMapOut_DeltaEncode_Type48Scan',
     'Type 0x48 handler: scan changed fields'),

    ('LABEL_FB5BA5', 'BitMapOut_DeltaEncode_Type48Loop',
     'Type 0x48 handler: field comparison loop'),

    ('LABEL_FB5C2E', 'BitMapOut_DeltaEncode_Type48End',
     'Type 0x48 handler: end of field scan'),

    ('LABEL_FB5C95', 'BitMapOut_DeltaEncode_Type48Epilog',
     'Type 0x48 handler: cleanup and return'),

    ('LABEL_FB5C9C', 'BitMapOut_DeltaEncode_Type48Return',
     'Type 0x48 handler: final return'),

    ('LABEL_FB5CA3', 'BitMapOut_DeltaEncode_Type90Handler',
     'Type 0x90 delta handler: control value change'),

    ('LABEL_FB5D01', 'BitMapOut_DeltaEncode_Type90PartB',
     'Type 0x90 handler: second part'),

    ('LABEL_FB5D74', 'BitMapOut_DeltaEncode_Type90Loop',
     'Type 0x90 handler: value comparison loop'),

    ('LABEL_FB5DE1', 'BitMapOut_DeltaEncode_Type90Epilog',
     'Type 0x90 handler: cleanup'),

    ('LABEL_FB5DE7', 'BitMapOut_DeltaEncode_Type90Return',
     'Type 0x90 handler: return'),

    ('LABEL_FB5DEC', 'BitMapOut_DeltaEncode_Type90Final',
     'Type 0x90 handler: final cleanup'),

    # --- Display refresh helpers (FB5E56-FB603E) ---
    ('LABEL_FB5E56', 'BitMapOut_RefreshDisplay_CheckDirty',
     'Check if display needs refresh based on dirty flags'),

    ('LABEL_FB5E61', 'BitMapOut_RefreshDisplay_ClearDirty',
     'Clear display dirty flags'),

    ('LABEL_FB5EA2', 'BitMapOut_RefreshDisplay_UpdateRegs',
     'Update display registers from workspace'),

    ('LABEL_FB5F00', 'BitMapOut_RefreshDisplay_Commit',
     'Commit display changes to hardware'),

    ('LABEL_FB5F24', 'BitMapOut_CalcDisplayMetrics',
     'Calculate display metrics from current voice state'),

    ('LABEL_FB5F80', 'BitMapOut_CalcMetrics_ComputeGrid',
     'Compute display grid metrics'),

    ('LABEL_FB5F91', 'BitMapOut_CalcMetrics_Done',
     'Display metrics calculation complete'),

    ('LABEL_FB5F93', 'BitMapOut_PrepareRenderState',
     'Prepare render state for display update'),

    ('LABEL_FB5FFA', 'BitMapOut_PrepareRender_SetParams',
     'Set rendering parameters'),

    ('LABEL_FB6017', 'BitMapOut_PrepareRender_CheckBit0',
     'Check render state bit 0'),

    ('LABEL_FB6019', 'BitMapOut_PrepareRender_CheckBit1',
     'Check render state bit 1'),

    ('LABEL_FB601E', 'BitMapOut_PrepareRender_CheckBit2',
     'Check render state bit 2'),

    ('LABEL_FB6023', 'BitMapOut_GetRenderMode',
     'Get current render mode flag'),

    ('LABEL_FB6028', 'BitMapOut_GetRenderMode_CheckBit3',
     'Check render mode bit 3'),

    ('LABEL_FB6031', 'BitMapOut_GetRenderMode_Return',
     'Return render mode result'),

    ('LABEL_FB603E', 'BitMapOut_ByteData_RenderState',
     'Byte data block: render state lookup table'),

    # --- Display update dispatch (FB60FC-FB632E) ---
    ('LABEL_FB60FC', 'BitMapOut_ByteData_DisplayUpdate',
     'Byte data block: display update parameter sequences'),

    ('LABEL_FB6172', 'BitMapOut_UpdateDisplayWidget',
     'Update display widget from voice data changes'),

    ('LABEL_FB6184', 'BitMapOut_UpdateWidget_CheckType',
     'Check widget type for appropriate update handler'),

    ('LABEL_FB61AB', 'BitMapOut_UpdateWidget_TypeA',
     'Widget type A: text-based display update'),

    ('LABEL_FB61B9', 'BitMapOut_UpdateWidget_TypeB',
     'Widget type B: graphical display update'),

    ('LABEL_FB61ED', 'BitMapOut_UpdateWidget_PostDraw',
     'Post-draw widget processing'),

    ('LABEL_FB6210', 'BitMapOut_UpdateWidget_Finalize',
     'Finalize widget update and flush'),

    ('LABEL_FB622B', 'BitMapOut_UpdateWidget_Done',
     'Widget update complete'),

    ('LABEL_FB632E', 'BitMapOut_ByteData_WidgetTable',
     'Byte data block: widget parameter table'),

    ('LABEL_FB6346', 'BitMapOut_ApplyWidgetPatch',
     'Apply incremental widget patch from delta data'),

    ('LABEL_FB6349', 'BitMapOut_ApplyPatch_SkipHeader',
     'Skip patch header bytes'),

    ('LABEL_FB635E', 'BitMapOut_ApplyPatch_Execute',
     'Execute widget patch operation'),

    ('LABEL_FB6367', 'BitMapOut_ApplyPatch_Loop',
     'Patch application loop'),

    ('LABEL_FB6382', 'BitMapOut_ApplyPatch_Store',
     'Store patched value to widget memory'),

    ('LABEL_FB6395', 'BitMapOut_ApplyPatch_Done',
     'Widget patch application complete'),

    ('LABEL_FB6397', 'BitMapOut_ApplyPatch_Return',
     'Return from widget patch'),

    ('LABEL_FB63DC', 'BitMapOut_ByteData_PatchTable',
     'Byte data block: widget patch parameter table'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        if refs == 0:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        renamed += 1
        print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
