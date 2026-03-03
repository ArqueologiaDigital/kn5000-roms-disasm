#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (sequencer init functions).

Covers two major function groups in the Sound Editor / Scoop initialization module:

  1. InitializeScoop region (F009DC-F028DE, ~147 labels)
     Scoop initialization: pitch bend/glide UI setup, screen drawing helpers,
     display object table registration, side panel / title bar / button label routines.

  2. UpdateSeMenuSelection region (F06170-F0FFC7, ~392 labels)
     Sound Editor menu: event dispatch, display element registration, part selection,
     parameter editing, filter/effect/controller configuration, popup dialogs,
     object table management, and value display helpers.

Each rename was verified by analysing the routine's code, register usage,
called functions, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source.
# ---------------------------------------------------------------------------

RENAMES = [

    # ==================================================================
    # 1. InitializeScoop region (lines ~59668-61778)
    #    Scoop initialization: pitch bend/glide effects UI, display
    #    setup, title bar, selection, side panel, button labels.
    # ==================================================================

    ('LABEL_F009DC', 'Scoop_SetupDisplayTables',
     'Setup display tables for scoop UI: call EF5CF9, then check/redraw'),

    ('LABEL_F009F9', 'Scoop_InitPartDisplay',
     'Initialize part display: read part count from mem[3424], setup panels'),

    ('LABEL_F00A21', 'Scoop_SelectModeTable_2Part',
     'Select 2-part mode table XIY variant'),

    ('LABEL_F00A37', 'Scoop_SelectModeTable_2Part_XIX',
     'Select 2-part mode table XIX variant, then call EF5CF9'),

    ('LABEL_F00A57', 'Scoop_SetPartIndexAndDisplay',
     'Set part index from mem[3424], configure display objects'),

    ('LABEL_F00A74', 'Scoop_Return',
     'Return from scoop setup'),

    ('LABEL_F00A75', 'Scoop_CheckPartStatus',
     'Check part status: read mem[3424], compare slot with 0x0C threshold'),

    ('LABEL_F00A91', 'Scoop_CheckPartStatus_End',
     'Epilogue for Scoop_CheckPartStatus'),

    ('LABEL_F00A94', 'Scoop_CallDisplayHelper',
     'Call display helper via EF5CF9 with XIY/XIX from F00AA3/F00AAB'),

    ('LABEL_F00AA3', 'Scoop_DisplayData_ButtonLayout',
     'Display data: button layout coordinates'),

    ('LABEL_F00AD3', 'Scoop_DrawGridLines',
     'Draw grid lines: call EF5CF9 with grid line data'),

    ('LABEL_F00AE6', 'Scoop_GridLineData',
     'Data: grid line coordinates for scoop display'),

    ('LABEL_F00B40', 'Scoop_DrawGridDividers',
     'Draw grid divider lines'),

    ('LABEL_F00B4F', 'Scoop_GridDividerData',
     'Data: grid divider coordinates'),

    ('LABEL_F00B6D', 'Scoop_DrawFrameLines',
     'Draw frame border lines'),

    ('LABEL_F00B7C', 'Scoop_FrameData',
     'Data: frame border coordinates and text labels'),

    ('LABEL_F00BED', 'Scoop_InitDisplayFull',
     'Full display init: draw frames, setup part tables, configure buttons'),

    ('LABEL_F00C49', 'Scoop_RedrawMainContent_End',
     'Return from Display_RedrawMainContent'),

    ('LABEL_F00C77', 'Scoop_FooterShowPartValue',
     'Footer: show part value from mem[3922]'),

    ('LABEL_F00C84', 'Scoop_FooterCallDisplay',
     'Footer: call EF5D0A display routine'),

    ('LABEL_F00C88', 'Scoop_RedrawFooter_End',
     'Return from Display_RedrawFooter'),

    ('LABEL_F00CBD', 'Scoop_TitleBar_ShowBPM_Part0',
     'Title bar: show BPM value for part 0 (value < 1000)'),

    ('LABEL_F00CCE', 'Scoop_TitleBar_Part1Check',
     'Title bar: check part 1 BPM value'),

    ('LABEL_F00CEE', 'Scoop_TitleBar_ShowBPM_Part1',
     'Title bar: show BPM value for part 1'),

    ('LABEL_F00CFF', 'Scoop_TitleBar_Part2Check',
     'Title bar: check part 2 BPM value'),

    ('LABEL_F00D1F', 'Scoop_TitleBar_ShowBPM_Part2',
     'Title bar: show BPM value for part 2'),

    ('LABEL_F00D30', 'Scoop_TitleBar_End',
     'Return from Display_RedrawTitleBar'),

    ('LABEL_F00D31', 'Scoop_TitleBar_SelectPartRange',
     'Select part range: max(mem[3667], mem[3668]), clamp to 4'),

    ('LABEL_F00D41', 'Scoop_TitleBar_ClampParts',
     'Clamp part count to 4, compute table offset'),

    ('LABEL_F00D47', 'Scoop_TitleBar_DisplayPartTable',
     'Display part table from E0BB90 + partCount * 0x2D'),

    ('LABEL_F00D59', 'Scoop_TitleBar_GetPartConfig',
     'Get part config: select part-specific display offset'),

    ('LABEL_F00D6C', 'Scoop_TitleBar_Part1Config',
     'Part 1 config: add 0x5A offset, check mem[3667]'),

    ('LABEL_F00D80', 'Scoop_TitleBar_Part2Config',
     'Part 2 config: add 0xB4 offset, check mem[3668]'),

    ('LABEL_F00D90', 'Scoop_TitleBar_ShowPartSlot',
     'Show part slot: multiply by 0x14, call EF5CE8'),

    ('LABEL_F00DA4', 'Scoop_TitleBar_GetPartConfig_End',
     'Return from GetPartConfig'),

    ('LABEL_F00DB0', 'Scoop_Selection_RedrawActive',
     'Redraw active selection region'),

    ('LABEL_F00DE3', 'Scoop_Selection_CheckMode1',
     'Selection: check mode == 1'),

    ('LABEL_F00DE7', 'Scoop_Selection_DrawMode1',
     'Selection: draw mode 1 (part name from mem[14095])'),

    ('LABEL_F00E0F', 'Scoop_Selection_DrawMode2',
     'Selection: draw mode 2 (show part value from mem[3922])'),

    ('LABEL_F00E34', 'Scoop_Selection_End',
     'Return from Display_RedrawSelection'),

    ('LABEL_F00E50', 'Scoop_SidePanel_DrawPartLoop',
     'Side panel: draw part loop (iterate parts 0-2)'),

    ('LABEL_F00E63', 'Scoop_SidePanel_DrawSlotPair',
     'Side panel: draw low/high nibble of slot pair'),

    ('LABEL_F00E96', 'Scoop_SidePanel_NextPart',
     'Side panel: advance to next part'),

    ('LABEL_F00EB2', 'Scoop_SidePanel_DrawValues',
     'Side panel: draw part values from mem[3666-3668]'),

    ('LABEL_F00EC5', 'Scoop_SidePanel_StoreAndDraw',
     'Side panel: store values to mem[4507-4509], call EF5D1F'),

    ('LABEL_F00EEB', 'Scoop_SidePanel_End',
     'Return from Display_RedrawSidePanel'),

    ('LABEL_F00EEC', 'Scoop_SidePanel_DrawOneSlot',
     'Draw one slot cell: setup 11D4 display object, call EF5D70'),

    ('LABEL_F00F97', 'Scoop_AltContent_ClearRegions',
     'Clear 3 content regions at 0x821, 0xF29, 0x1631'),

    ('LABEL_F00FAF', 'Scoop_AltContent_End',
     'Return from Display_RedrawAltContent'),

    ('LABEL_F00FB0', 'Scoop_AltContent_ClearOneRegion',
     'Clear one 32x10 region via EF5D81'),

    ('LABEL_F01046', 'Scoop_ButtonLabels_End',
     'Return from Display_RedrawButtonLabels'),

    ('LABEL_F01047', 'Scoop_ButtonLabels_CopySlotData',
     'Copy 8 slot data entries from E55 to 11B3'),

    ('LABEL_F01057', 'Scoop_ButtonLabels_CopyLoop',
     'Copy loop: read slot byte, store to display buffer'),

    ('LABEL_F01071', 'Scoop_ButtonLabels_DrawRow1',
     'Draw button label row 1'),

    ('LABEL_F01086', 'Scoop_ButtonLabels_DrawRow1_Alt',
     'Draw button label row 1 alternate path'),

    ('LABEL_F01099', 'Scoop_ButtonLabels_SetupPartButtons',
     'Setup part selection buttons'),

    ('LABEL_F010A9', 'Scoop_ButtonLabels_Part1',
     'Part 1 button label'),

    ('LABEL_F010BE', 'Scoop_ButtonLabels_Part2',
     'Part 2 button label'),

    ('LABEL_F010D3', 'Scoop_ButtonLabels_Part3',
     'Part 3 button label'),

    ('LABEL_F010E6', 'Scoop_ButtonLabels_DrawPitchLabels',
     'Draw pitch bend/glide button labels'),

    ('LABEL_F010F6', 'Scoop_ButtonLabels_DrawPitchLabel1',
     'Draw pitch label 1'),

    ('LABEL_F01109', 'Scoop_ButtonLabels_DrawAmpLabels',
     'Draw amplitude envelope button labels'),

    ('LABEL_F01119', 'Scoop_ButtonLabels_DrawAmpLabel1',
     'Draw amplitude label 1'),

    ('LABEL_F0112C', 'Scoop_ButtonLabels_DrawFilterLabels',
     'Draw filter button labels'),

    ('LABEL_F0113C', 'Scoop_ButtonLabels_DrawFilterLabel1',
     'Draw filter label 1'),

    ('LABEL_F0114F', 'Scoop_ButtonLabels_DrawCategory',
     'Draw one category of button labels via EF5D0A'),

    ('LABEL_F01158', 'Scoop_ButtonLabels_DrawCategoryData',
     'Data block for button label category display'),

    ('LABEL_F0117A', 'Scoop_EventHandler_PartSelect',
     'Event handler: part selection button pressed'),

    ('LABEL_F01184', 'Scoop_EventHandler_Part1',
     'Event handler: part 1 selected'),

    ('LABEL_F01190', 'Scoop_EventHandler_PartRedraw',
     'Redraw after part selection'),

    ('LABEL_F01195', 'Scoop_EventHandler_PartRedrawData',
     'Data for part selection redraw'),

    ('LABEL_F011AB', 'Scoop_EventHandler_ValueChange',
     'Event handler: parameter value changed'),

    ('LABEL_F011B1', 'Scoop_EventHandler_ValueChangeData',
     'Data for value change event'),

    ('LABEL_F011B8', 'Scoop_EventHandler_Setup',
     'Event handler: initial setup dispatch'),

    ('LABEL_F011CB', 'Scoop_EventHandler_SetupData',
     'Data for setup event handler'),

    ('LABEL_F011CC', 'Scoop_EventHandler_MenuSwitch',
     'Event handler: menu switch (mode change)'),

    ('LABEL_F011FD', 'Scoop_EventHandler_MenuSwitch_Mode1',
     'Menu switch: mode 1 handler'),

    ('LABEL_F01213', 'Scoop_EventHandler_MenuSwitch_Mode2',
     'Menu switch: mode 2 handler'),

    ('LABEL_F0122B', 'Scoop_EventHandler_MenuSwitch_End',
     'Return from menu switch handler'),

    ('LABEL_F0122C', 'Scoop_EventHandler_Scroll',
     'Event handler: scroll/navigate in scoop display'),

    ('LABEL_F0127E', 'Scoop_Scroll_ValidateRange',
     'Validate scroll range'),

    ('LABEL_F0128C', 'Scoop_Scroll_Boundary1',
     'Scroll boundary check 1'),

    ('LABEL_F0128E', 'Scoop_Scroll_Boundary2',
     'Scroll boundary check 2'),

    ('LABEL_F01291', 'Scoop_Scroll_Boundary3',
     'Scroll boundary check 3'),

    ('LABEL_F01294', 'Scoop_Scroll_Apply',
     'Apply scroll position and redraw'),

    ('LABEL_F012CB', 'Scoop_EventHandler_CategorySelect',
     'Event handler: category tab selected'),

    ('LABEL_F012FC', 'Scoop_CategorySelect_Pitch',
     'Category: pitch selected'),

    ('LABEL_F01312', 'Scoop_CategorySelect_Amplitude',
     'Category: amplitude selected'),

    ('LABEL_F01340', 'Scoop_CategorySelect_Filter',
     'Category: filter selected'),

    ('LABEL_F0136C', 'Scoop_CategorySelect_End',
     'End of category select dispatch'),

    ('LABEL_F0137E', 'Scoop_CategorySelect_UpdateDisplay',
     'Update display after category change'),

    ('LABEL_F013CD', 'Scoop_EventHandler_ButtonGrid',
     'Event handler: button grid interaction'),

    ('LABEL_F013FD', 'Scoop_ButtonGrid_CheckBounds',
     'Check button grid bounds'),

    ('LABEL_F01410', 'Scoop_ButtonGrid_ProcessCell',
     'Process selected grid cell'),

    ('LABEL_F0142A', 'Scoop_ButtonGrid_UpdateValue',
     'Update cell value and redraw'),

    ('LABEL_F01430', 'Scoop_ButtonGrid_End',
     'End of button grid handler'),

    ('LABEL_F0144F', 'Scoop_ButtonGrid_Data',
     'Data block for button grid'),

    ('LABEL_F01450', 'Scoop_EventHandler_SpecialMode',
     'Event handler: special mode (glide/portamento)'),

    ('LABEL_F0168E', 'Scoop_SpecialMode_Setup',
     'Special mode: initial setup'),

    ('LABEL_F016B3', 'Scoop_SpecialMode_CheckState',
     'Special mode: check current state'),

    ('LABEL_F016B7', 'Scoop_SpecialMode_Data',
     'Data for special mode display'),

    ('LABEL_F016E2', 'Scoop_SpecialMode_Toggle',
     'Toggle special mode on/off'),

    ('LABEL_F016ED', 'Scoop_SpecialMode_ToggleEnd',
     'End of toggle handler'),

    ('LABEL_F016EE', 'Scoop_SpecialMode_Draw',
     'Draw special mode indicator'),

    ('LABEL_F01719', 'Scoop_SpecialMode_DrawAlt',
     'Draw special mode alternate display'),

    ('LABEL_F01724', 'Scoop_SpecialMode_DrawEnd',
     'End of special mode draw'),

    ('LABEL_F01725', 'Scoop_SpecialMode_UpdateParams',
     'Update special mode parameters'),

    ('LABEL_F017BA', 'Scoop_SpecialMode_ParamCheckBound',
     'Check parameter bounds'),

    ('LABEL_F017C9', 'Scoop_SpecialMode_ParamApply',
     'Apply parameter change'),

    ('LABEL_F017CC', 'Scoop_SpecialMode_ParamEnd',
     'End of parameter update'),

    ('LABEL_F017CD', 'Scoop_SpecialMode_ValueEdit',
     'Value edit mode for special parameters'),

    ('LABEL_F0184E', 'Scoop_SpecialMode_ValueEditEnd',
     'End of value edit'),

    ('LABEL_F0184F', 'Scoop_SpecialMode_ValueSend',
     'Send edited value to hardware'),

    ('LABEL_F01882', 'Scoop_SpecialMode_ValueSend_Part1',
     'Send value: part 1 processing'),

    ('LABEL_F01895', 'Scoop_SpecialMode_ValueSend_Part2',
     'Send value: part 2 processing'),

    ('LABEL_F018A6', 'Scoop_SpecialMode_ValueSend_Part3',
     'Send value: part 3 processing'),

    ('LABEL_F018B1', 'Scoop_SpecialMode_ValueSend_End',
     'End of value send'),

    ('LABEL_F018C4', 'Scoop_SpecialMode_CurveUpdate',
     'Update pitch bend curve display'),

    ('LABEL_F018EC', 'Scoop_CurveUpdate_DrawSegment',
     'Draw one curve segment'),

    ('LABEL_F0191E', 'Scoop_CurveUpdate_NextSegment',
     'Advance to next curve segment'),

    ('LABEL_F01930', 'Scoop_CurveUpdate_SegmentEnd',
     'End of segment processing'),

    ('LABEL_F01956', 'Scoop_CurveUpdate_Finalize',
     'Finalize curve display'),

    ('LABEL_F01985', 'Scoop_CurveUpdate_End',
     'End of curve update'),

    ('LABEL_F019B6', 'Scoop_EnvelopeCalc',
     'Calculate pitch bend envelope parameters'),

    ('LABEL_F01A46', 'Scoop_EnvelopeCalc_Data',
     'Data tables for envelope calculation'),

    ('LABEL_F01DAB', 'Scoop_GlideParam_Setup',
     'Glide parameter setup routine'),

    ('LABEL_F01DE3', 'Scoop_GlideParam_Configure',
     'Configure glide parameters'),

    ('LABEL_F01E0A', 'Scoop_GlideParam_End',
     'End of glide parameter setup'),

    ('LABEL_F01E89', 'Scoop_GlideParam_Data',
     'Data for glide parameter configuration'),

    ('LABEL_F020D6', 'Scoop_Dispatch_Nop',
     'Return-only stub (NOP dispatch entry)'),

    ('LABEL_F020D7', 'Scoop_Dispatch_CallFAA98A',
     'Copy (XWA+2..8) to stack, call FAA98A with DE=0xFF'),

    ('LABEL_F02106', 'Scoop_Dispatch_CallFAB273',
     'Copy (XWA+2..8) to stack, call FAB273 with BC=0xF5'),

    ('LABEL_F0212C', 'Scoop_EventLoop_12Entry',
     'Event loop: 12-entry dispatch table (0xE0CC32 base)'),

    ('LABEL_F0214D', 'Scoop_EventLoop_12Entry_Process',
     'Process event code via dispatch table lookup'),

    ('LABEL_F0217D', 'Scoop_EventLoop_12Entry_End',
     'End of 12-entry event loop'),

    ('LABEL_F02184', 'Scoop_EnvProcessor_Data',
     'Data block: envelope processor parameters'),

    ('LABEL_F023CF', 'Scoop_EventLoop_36Entry',
     'Event loop: 36-entry dispatch table (0xE0CCF6 base, 4-byte stride)'),

    ('LABEL_F0244A', 'Scoop_EventLoop_36Entry_Branch1',
     '36-entry loop: branch for specific event type 1'),

    ('LABEL_F0245F', 'Scoop_EventLoop_36Entry_Branch2',
     '36-entry loop: branch for specific event type 2'),

    ('LABEL_F02472', 'Scoop_EventLoop_36Entry_Branch3',
     '36-entry loop: branch for specific event type 3'),

    ('LABEL_F02503', 'Scoop_EventLoop_36Entry_Data',
     'Data block for 36-entry event loop'),

    ('LABEL_F0288E', 'Scoop_EventLoop_12Entry_Alt',
     'Event loop: 12-entry dispatch (0xE0CD5A base, alternate)'),

    ('LABEL_F028A9', 'Scoop_EventLoop_12Entry_Alt_Process',
     'Alternate 12-entry loop: process event code'),

    ('LABEL_F028BD', 'Scoop_EventLoop_12Entry_Alt_Dispatch',
     'Alternate 12-entry loop: dispatch via table'),

    ('LABEL_F028DE', 'Scoop_EventLoop_12Entry_Alt_End',
     'End of alternate 12-entry event loop'),

    ('LABEL_F03D80', 'Scoop_SoundEditorData',
     'Data block: sound editor parameter tables'),

    # ==================================================================
    # 2. UpdateSeMenuSelection region (lines ~63167-70981)
    #    Sound Editor menu helpers and main update function.
    # ==================================================================

    # --- Event/notification dispatch helpers (F061xx) ---

    ('LABEL_F06170', 'SeMenu_SendEvent',
     'Send event: dispatch via F99490 (bc=0) or F994EA (bc!=0)'),

    ('LABEL_F06181', 'SeMenu_SendEvent_Indirect',
     'Send event via indirect call F994EA'),

    ('LABEL_F06185', 'SeMenu_SendEvent_StoreAndReturn',
     'Store event ID to mem[1688] and return'),

    ('LABEL_F0618F', 'SeMenu_LoadRawAddr',
     'Load address from mem offset 0x8D38 into (xwa)'),

    ('LABEL_F06194', 'SeMenu_TriggerNotification',
     'Trigger notification: store to mem[32578], set interrupt flag'),

    ('LABEL_F061A2', 'SeMenu_ClearNotification',
     'Clear notification: store to mem[58332], set bit 1'),

    ('LABEL_F061AB', 'SeMenu_StoreEventId',
     'Store event ID a to mem[1688]'),

    ('LABEL_F061B0', 'SeMenu_LoadObjectPtr_Data',
     'Data bytes for object pointer load'),

    ('LABEL_F061B5', 'SeMenu_LoadMasterPtr',
     'Load master display pointer from 0x008D3A into (xwa)'),

    ('LABEL_F061BD', 'SeMenu_FlushDisplayObj',
     'Flush display object: copy data to mem[1689] and send to SubCPU'),

    ('LABEL_F061C8', 'SeMenu_FlushDisplayObj_CopyLoop',
     'Copy loop: transfer bytes until buffer full'),

    ('LABEL_F061DA', 'SeMenu_RegisterElement_Extended',
     'Register display element (extended form with DE/C/A params)'),

    ('LABEL_F061ED', 'SeMenu_RegisterElement_ClearLoop',
     'Clear element buffer before setup'),

    # --- Display element registration family (F062xx-F064xx) ---

    ('LABEL_F06239', 'SeMenu_RegisterElement_Type1',
     'Register display element type 1 (push value, set slot/type/index)'),

    ('LABEL_F0624C', 'SeMenu_RegisterElement_Type1_ClearLoop',
     'Type 1 element: clear buffer loop'),

    ('LABEL_F062A0', 'SeMenu_RegisterElement_Type1_AltLoop',
     'Type 1 element: alternate buffer clear loop'),

    ('LABEL_F062D6', 'SeMenu_InitDisplayField',
     'Init display field: call F095AB, setup field object'),

    ('LABEL_F062EC', 'SeMenu_InitDisplayField_ClearLoop',
     'Display field: clear buffer loop'),

    ('LABEL_F06313', 'SeMenu_InitDisplayField_Branch1',
     'Display field: branch for non-zero check'),

    ('LABEL_F06316', 'SeMenu_InitDisplayField_Continue',
     'Display field: continue after branch'),

    ('LABEL_F0632F', 'SeMenu_InitDisplayField_Alt',
     'Init display field alternate variant'),

    ('LABEL_F06348', 'SeMenu_InitDisplayField_Alt_ClearLoop',
     'Alternate display field: clear loop'),

    ('LABEL_F0636F', 'SeMenu_InitDisplayField_Alt_Branch1',
     'Alternate display field: branch 1'),

    ('LABEL_F06372', 'SeMenu_InitDisplayField_Alt_Continue',
     'Alternate display field: continue'),

    ('LABEL_F0639B', 'SeMenu_RegisterValueDisplay',
     'Register value display element'),

    ('LABEL_F063AB', 'SeMenu_RegisterValueDisplay_ClearLoop',
     'Value display: clear loop'),

    ('LABEL_F063DF', 'SeMenu_RegisterElement_Type2',
     'Register display element type 2 (with parameter byte)'),

    ('LABEL_F063F2', 'SeMenu_RegisterElement_Type2_ClearLoop',
     'Type 2 element: clear loop'),

    ('LABEL_F06415', 'SeMenu_RegisterElement_Type2_SetMode',
     'Type 2 element: set display mode byte'),

    ('LABEL_F06420', 'SeMenu_RegisterElement_Type2_SetMode2',
     'Type 2 element: set mode byte variant 2'),

    ('LABEL_F06432', 'SeMenu_RegisterElement_Type2_Branch',
     'Type 2 element: conditional branch'),

    ('LABEL_F06435', 'SeMenu_RegisterElement_Type2_Finalize',
     'Type 2 element: finalize and flush'),

    ('LABEL_F06454', 'SeMenu_RegisterParamDisplay',
     'Register parameter value display element'),

    ('LABEL_F06461', 'SeMenu_RegisterParamDisplay_ClearLoop',
     'Parameter display: clear loop'),

    ('LABEL_F0648F', 'SeMenu_RegisterParamDisplay_Data',
     'Data block for parameter display'),

    # --- Object setup and display (F065xx-F067xx) ---

    ('LABEL_F06584', 'SeMenu_SetupDisplayObject',
     'Setup display object: clear buffer, configure type=0x88'),

    ('LABEL_F06592', 'SeMenu_SetupDisplayObject_ClearLoop',
     'Display object: clear buffer loop'),

    ('LABEL_F065C5', 'SeMenu_SetupDisplayObject_Data',
     'Data block for display object setup'),

    ('LABEL_F0661C', 'SeMenu_SetupDisplayObject_Alt1',
     'Setup display object alternate variant 1'),

    ('LABEL_F0662F', 'SeMenu_SetupDisplayObject_Alt1_ClearLoop',
     'Alt variant 1: clear loop'),

    ('LABEL_F06652', 'SeMenu_SetupDisplayObject_Alt2',
     'Setup display object alternate variant 2'),

    ('LABEL_F0665D', 'SeMenu_SetupDisplayObject_Alt2_ClearLoop',
     'Alt variant 2: clear loop'),

    ('LABEL_F0666F', 'SeMenu_SetupDisplayObject_Alt2_Branch',
     'Alt variant 2: conditional branch'),

    ('LABEL_F06672', 'SeMenu_SetupDisplayObject_Alt2_Continue',
     'Alt variant 2: continue after branch'),

    ('LABEL_F066A0', 'SeMenu_SetupDisplayObject_Alt3',
     'Setup display object alternate variant 3'),

    ('LABEL_F066D2', 'SeMenu_ClearDisplayBuffer',
     'Clear display buffer: init to type=0x88, cmd=0x0D'),

    ('LABEL_F066DC', 'SeMenu_ClearDisplayBuffer_Loop',
     'Display buffer: clear loop'),

    ('LABEL_F0670C', 'SeMenu_InitDisplayColumn',
     'Init display column with mode/type params'),

    ('LABEL_F06716', 'SeMenu_InitDisplayColumn_Loop',
     'Display column: init loop'),

    ('LABEL_F0673C', 'SeMenu_InitDisplayColumn_Data',
     'Data for display column initialization'),

    ('LABEL_F06784', 'SeMenu_SetDisplayValue',
     'Set display value at offset 0x20'),

    ('LABEL_F06791', 'SeMenu_SetDisplayValue_Loop',
     'Display value: setup loop'),

    ('LABEL_F067C3', 'SeMenu_SetDisplayValue_Data',
     'Data for display value setup'),

    # --- Track info and part setup (F068xx-F069xx) ---

    ('LABEL_F0683E', 'SeMenu_InitTrackInfo',
     'Init track info: read instrument data from FEE861'),

    ('LABEL_F0686E', 'SeMenu_InitTrackInfo_Part1',
     'Track info: part 1 storage (mem[63952])'),

    ('LABEL_F0687B', 'SeMenu_InitTrackInfo_Part2',
     'Track info: part 2 storage (mem[63978])'),

    ('LABEL_F06881', 'SeMenu_InitTrackInfo_Store',
     'Track info: store part value'),

    ('LABEL_F06898', 'SeMenu_SetObjectFlags',
     'Set display object flags based on type byte (A=type)'),

    ('LABEL_F06905', 'SeMenu_SetFlags_Type1',
     'Object flags: type 1 (a=1)'),

    ('LABEL_F06909', 'SeMenu_SetFlags_Type2',
     'Object flags: type 2 (a=1, alternate path)'),

    ('LABEL_F0690D', 'SeMenu_SetFlags_Type3',
     'Object flags: type 3 (OR 0x03 to flags)'),

    ('LABEL_F06911', 'SeMenu_SetFlags_Type4',
     'Object flags: type 4 (OR 0x03 + set bit 7 in DE)'),

    ('LABEL_F06916', 'SeMenu_SetFlags_Type0x1x',
     'Object flags: type 0x11-0x14 (a=2)'),

    ('LABEL_F06918', 'SeMenu_SetFlags_SetCarryAndStore',
     'Set carry flag and store to display buffer'),

    ('LABEL_F0691C', 'SeMenu_SetFlags_Type0x2x',
     'Object flags: type 0x21-0x24 (set bit 2 + bit 6 in DE)'),

    ('LABEL_F06921', 'SeMenu_SetFlags_Type0x3x',
     'Object flags: type 0x31-0x34 (a=2, alternate)'),

    ('LABEL_F06923', 'SeMenu_SetFlags_SetCarryAndStore_Alt',
     'Set carry, store, then set bit 7 in DE'),

    ('LABEL_F06926', 'SeMenu_SetFlags_SetBit7_DE',
     'Set bit 7 in display object extension byte'),

    ('LABEL_F06929', 'SeMenu_SetFlags_Type0x4x',
     'Object flags: type 0x41-0x44 (set bit 2 + OR 0xC0 in DE)'),

    ('LABEL_F0692F', 'SeMenu_SetupMenuDisplay',
     'Setup menu display with object entries and part selection'),

    ('LABEL_F0695A', 'SeMenu_SetupMenuDisplay_ValidatePart',
     'Menu display: validate part via F06A3A'),

    ('LABEL_F0695F', 'SeMenu_SetupMenuDisplay_ConfigObj',
     'Menu display: configure display objects'),

    ('LABEL_F0696D', 'SeMenu_SetupMenuDisplay_ClearLoop',
     'Menu display: clear object buffer loop'),

    ('LABEL_F06981', 'SeMenu_SetupMenuDisplay_Data',
     'Data for menu display setup'),

    ('LABEL_F06984', 'SeMenu_SetupMenuDisplay_Data2',
     'Additional data for menu display'),

    ('LABEL_F069A4', 'SeMenu_SetupMenuDisplay_Section2',
     'Menu display: section 2 setup'),

    ('LABEL_F069B7', 'SeMenu_SetupMenuDisplay_Section2_Loop',
     'Section 2: processing loop'),

    ('LABEL_F069C0', 'SeMenu_SetupMenuDisplay_Section2_End',
     'Section 2: end'),

    ('LABEL_F069E7', 'SeMenu_SetupMenuDisplay_Section3',
     'Menu display: section 3 setup'),

    ('LABEL_F06A12', 'SeMenu_SetupMenuDisplay_Section3_Loop',
     'Section 3: processing loop'),

    ('LABEL_F06A19', 'SeMenu_SetupMenuDisplay_Section3_End',
     'Section 3: end'),

    ('LABEL_F06A22', 'SeMenu_SetupMenuDisplay_Finalize',
     'Menu display: finalize and flush to display'),

    ('LABEL_F06A27', 'SeMenu_SetupMenuDisplay_Finalize_Data',
     'Data for menu display finalize'),

    # --- Part validation and selection (F06Axx-F06Bxx) ---

    ('LABEL_F06A3A', 'SeMenu_ValidatePartNumber',
     'Validate part number: clamp to range 1-4, fallback to first valid'),

    ('LABEL_F06A55', 'SeMenu_ValidatePartNumber_Default',
     'Default part: force part=1 when out of range'),

    ('LABEL_F06A60', 'SeMenu_ValidatePartNumber_CheckEnabled',
     'Check if selected part is enabled'),

    ('LABEL_F06A71', 'SeMenu_ValidatePartNumber_ScanLoop',
     'Scan parts 1-4 for first enabled one'),

    ('LABEL_F06A82', 'SeMenu_ValidatePartNumber_NextPart',
     'Advance to next part in scan'),

    ('LABEL_F06A8C', 'SeMenu_ValidatePartNumber_Store',
     'Store validated part number'),

    ('LABEL_F06A95', 'SeMenu_ValidatePartNumber_End',
     'Return from ValidatePartNumber'),

    ('LABEL_F06A9B', 'SeMenu_StorePartMask',
     'Store part mask byte A to mem[1630]'),

    ('LABEL_F06AA0', 'SeMenu_PartMask_Data',
     'Data block for part mask processing'),

    ('LABEL_F06B0B', 'SeMenu_IsPartEnabled',
     'Check if part A (1-4) is enabled: return HL!=0 if yes'),

    ('LABEL_F06B13', 'SeMenu_IsPartEnabled_OutOfRange',
     'Part out of range: return HL=0'),

    ('LABEL_F06B16', 'SeMenu_IsPartEnabled_CheckMask',
     'Check part enable mask bit'),

    ('LABEL_F06B2E', 'SeMenu_StorePartParam',
     'Store byte C to part parameter array[A] at mem[1632]'),

    ('LABEL_F06B3B', 'SeMenu_LoadPartParam',
     'Load from part parameter array[A] at mem[1632] into (BC)'),

    ('LABEL_F06B4A', 'SeMenu_BitShift_Stub',
     'Return from bit shift (single byte)'),

    ('LABEL_F06B4B', 'SeMenu_BitShiftMask',
     'Compute bit shift mask: L = A << BC times'),

    ('LABEL_F06B55', 'SeMenu_BitShiftMask_Loop',
     'Bit shift loop: L += L'),

    ('LABEL_F06B5E', 'SeMenu_BitShiftMask_End',
     'End of bit shift mask computation'),

    # --- Data transfer helpers (F06Dxx) ---

    ('LABEL_F06D71', 'SeMenu_TransferPartValues',
     'Transfer values between part arrays (DE=src, WA=idx, BC=count)'),

    ('LABEL_F06D79', 'SeMenu_TransferPartValues_Loop',
     'Transfer loop: copy bytes between arrays'),

    ('LABEL_F06D7D', 'SeMenu_TransferPartValues_InnerLoop',
     'Inner copy loop'),

    ('LABEL_F06D8F', 'SeMenu_TransferPartValues_Data',
     'Data for transfer operation'),

    ('LABEL_F06D92', 'SeMenu_TransferPartValues_Data2',
     'Additional data for transfer'),

    ('LABEL_F06D9D', 'SeMenu_TransferPartValues_AltEntry',
     'Alternate entry point for value transfer'),

    ('LABEL_F06DA6', 'SeMenu_TransferPartValues_AltLoop',
     'Alternate transfer loop'),

    ('LABEL_F06DB5', 'SeMenu_TransferPartValues_AltInner',
     'Alternate inner loop'),

    ('LABEL_F06DBA', 'SeMenu_TransferPartValues_AltData',
     'Data for alternate transfer'),

    ('LABEL_F06DC2', 'SeMenu_TransferPartValues_End',
     'End of transfer operation'),

    ('LABEL_F06DCA', 'SeMenu_TransferPartValues_End2',
     'Cleanup and return from transfer'),

    ('LABEL_F06DCE', 'SeMenu_TransferPartValues_EndData',
     'Final data for transfer cleanup'),

    # --- Object table management (F071xx) ---

    ('LABEL_F0716C', 'SeMenu_InitObjEntry',
     'Init object entry: call F06A3A, store part, shift left 4, increment'),

    ('LABEL_F07187', 'SeMenu_ReadObjData',
     'Read object data from mem offset 0x693 into (xwa)'),

    ('LABEL_F0718C', 'SeMenu_SetCurrentStep',
     'Set current menu step: store A to mem[1683]'),

    ('LABEL_F07191', 'SeMenu_ResetSubIndex',
     'Reset sub-index to 0: store 0 to mem[1684]'),

    ('LABEL_F07197', 'SeMenu_AdvanceSubIndex',
     'Advance sub-index: increment mem[1684], return old value in L'),

    ('LABEL_F071A2', 'SeMenu_ReadObjParam_Data',
     'Data for object param read'),

    ('LABEL_F071A7', 'SeMenu_ReadObjParam',
     'Read object parameter from mem offset 0x694 into (xwa)'),

    ('LABEL_F071AC', 'SeMenu_CheckObjEnabled',
     'Check if object is enabled: compare mem[134195] with A'),

    ('LABEL_F071B9', 'SeMenu_CheckObjValid',
     'Check if object is valid: compare mem[134197] with A'),

    ('LABEL_F071C6', 'SeMenu_FillEntryTable',
     'Fill entry table from 0x020C33 master list'),

    ('LABEL_F071DB', 'SeMenu_FillEntryTable_Loop',
     'Entry table fill loop: iterate entries'),

    ('LABEL_F071FC', 'SeMenu_FillObjTable',
     'Fill object table from 0x020C39 master list'),

    ('LABEL_F07208', 'SeMenu_FillObjTable_Loop',
     'Object table fill loop'),

    ('LABEL_F07213', 'SeMenu_SetupPartDisplay',
     'Setup part display: configure part A with BC columns, DE=0x0D offset'),

    ('LABEL_F07224', 'SeMenu_SetupPartDisplay_Loop',
     'Part display setup loop'),

    ('LABEL_F07237', 'SeMenu_SetupPartDisplay_Alt',
     'Part display setup alternate entry'),

    ('LABEL_F07248', 'SeMenu_SetupPartDisplay_AltLoop',
     'Alternate part display loop'),

    ('LABEL_F0725B', 'SeMenu_SetupPartDisplay_Mode2',
     'Part display: mode 2 configuration'),

    ('LABEL_F0726C', 'SeMenu_SetupPartDisplay_Mode2Loop',
     'Mode 2 configuration loop'),

    ('LABEL_F0727F', 'SeMenu_SetupPartDisplay_Mode3',
     'Part display: mode 3 configuration'),

    ('LABEL_F07290', 'SeMenu_SetupPartDisplay_Mode3Loop',
     'Mode 3 configuration loop'),

    ('LABEL_F072A3', 'SeMenu_SetupPartDisplay_End',
     'End of part display setup'),

    # --- Part edit helpers (F075xx) ---

    ('LABEL_F0758B', 'SeMenu_ApplyPartEdit',
     'Apply part edit: process parameter change for part A'),

    ('LABEL_F075B4', 'SeMenu_ApplyPartEdit_Store',
     'Part edit: store updated value'),

    ('LABEL_F075C6', 'SeMenu_ApplyPartEdit_Data',
     'Data for part edit apply'),

    ('LABEL_F075F3', 'SeMenu_ApplyPartEdit_Alt',
     'Part edit: alternate processing path'),

    ('LABEL_F07600', 'SeMenu_ApplyPartEdit_AltStore',
     'Part edit alternate: store value'),

    ('LABEL_F07608', 'SeMenu_ApplyPartEdit_End',
     'End of part edit'),

    ('LABEL_F0766C', 'SeMenu_ApplyPartEdit_Data2',
     'Additional data for part edit'),

    # --- Parameter processing (F092xx-F094xx) ---

    ('LABEL_F092F5', 'SeMenu_ProcessEffect',
     'Process effect parameter: fill object table, extract parts'),

    ('LABEL_F09329', 'SeMenu_ProcessEffect_StoreLoop',
     'Effect: store parameter values loop'),

    ('LABEL_F0934B', 'SeMenu_ProcessEffect_CompareLoop',
     'Effect: compare loop termination check'),

    ('LABEL_F09356', 'SeMenu_ProcessEffect_LoopEnd',
     'Effect: loop termination'),

    ('LABEL_F09359', 'SeMenu_ProcessEffect_AltPath',
     'Effect: alternate path (xsp+38 != 0)'),

    ('LABEL_F09377', 'SeMenu_ProcessEffect_AltStore',
     'Effect alternate: store parameters'),

    ('LABEL_F093A0', 'SeMenu_ProcessEffect_AltData',
     'Data for alternate effect processing'),

    ('LABEL_F093C2', 'SeMenu_ProcessEffect_AltData2',
     'Additional data for effect processing'),

    ('LABEL_F093CD', 'SeMenu_ProcessEffect_AltBranch',
     'Effect alternate: conditional branch'),

    ('LABEL_F093CF', 'SeMenu_ProcessEffect_AltEnd',
     'End of alternate effect processing'),

    ('LABEL_F093E5', 'SeMenu_ProcessEffect_Section2',
     'Effect processing: section 2'),

    ('LABEL_F09407', 'SeMenu_ProcessEffect_Section2_End',
     'End of section 2'),

    ('LABEL_F09412', 'SeMenu_ProcessEffect_Data3',
     'Data block 3 for effect processing'),

    ('LABEL_F09419', 'SeMenu_ApplyFilter',
     'Apply filter parameter: setup object, configure part columns'),

    ('LABEL_F0944C', 'SeMenu_ApplyFilter_AltPart',
     'Apply filter: alternate part configuration'),

    ('LABEL_F09464', 'SeMenu_ApplyFilter_SetupDisplay',
     'Apply filter: setup display with F07213'),

    ('LABEL_F09495', 'SeMenu_ApplySynthParam',
     'Apply synthesizer parameter: fill table, compute address'),

    ('LABEL_F094C0', 'SeMenu_ApplySynthParam_Alt',
     'Apply synth param: alternate with expanded offset'),

    ('LABEL_F09514', 'SeMenu_ApplySynthParam_Data',
     'Data for synth parameter application'),

    # --- Accessor functions (F095xx-F096xx) ---

    ('LABEL_F095A1', 'SeMenu_SetSelectedRow',
     'Set selected row: store A to mem[1711]'),

    ('LABEL_F095A6', 'SeMenu_SetSelectedRow_Data',
     'Data bytes for selected row'),

    ('LABEL_F095AB', 'SeMenu_LoadObjEntries',
     'Load object entries: read mem offset 0x6AE into (xwa)'),

    ('LABEL_F095B0', 'SeMenu_SetMode',
     'Set menu mode: store A to mem[1710]'),

    ('LABEL_F095B5', 'SeMenu_SetMode_Data',
     'Data bytes for menu mode'),

    ('LABEL_F095C9', 'SeMenu_LoadSoundBankCfg',
     'Load sound bank config: read mem offset 0x6B4 into (xwa)'),

    ('LABEL_F095CE', 'SeMenu_SetSoundBank',
     'Set sound bank: store A to mem[1716]'),

    ('LABEL_F095D3', 'SeMenu_LoadFilterType',
     'Load filter type: read mem offset 0x6B5 into (xwa)'),

    ('LABEL_F095D8', 'SeMenu_SetFilterParam1',
     'Set filter param 1: store A to mem[1717]'),

    ('LABEL_F095DD', 'SeMenu_LoadFilterParam2',
     'Load filter param 2: read mem offset 0x6B6 into (xwa)'),

    ('LABEL_F095E2', 'SeMenu_SetFilterMode',
     'Set filter mode: store A to mem[1718]'),

    ('LABEL_F095E7', 'SeMenu_SetFilterCoeff',
     'Set filter coefficient: store A to mem[1721]'),

    ('LABEL_F095EC', 'SeMenu_LoadEditParam',
     'Load edit parameter: read mem offset 0x6B9 into (xwa)'),

    ('LABEL_F095F1', 'SeMenu_SetupSoundBankPair',
     'Setup sound bank pair: read config, select parameters'),

    ('LABEL_F09627', 'SeMenu_SetupSoundBankPair_NonZero',
     'Sound bank pair: non-zero config path'),

    ('LABEL_F09673', 'SeMenu_SetupSoundBankPair_CheckValid',
     'Sound bank pair: check if slot is valid (not 0xFF)'),

    ('LABEL_F09689', 'SeMenu_SetupSoundBankPair_Invalid',
     'Sound bank pair: handle invalid (0xFF) slot'),

    ('LABEL_F09690', 'SeMenu_SetupSoundBankPair_Direct',
     'Sound bank pair: direct parameter passthrough'),

    ('LABEL_F0969B', 'SeMenu_SetupSoundBankPair_End',
     'End of sound bank pair setup'),

    ('LABEL_F096A0', 'SeMenu_ComputeParamTableAddr',
     'Compute parameter table address: (A-1)*10 + 0x205F3 + BC'),

    ('LABEL_F096B7', 'SeMenu_ComputeParamTableAddr_ScanLoop',
     'Param table: scan loop until DE >= BC'),

    ('LABEL_F096C2', 'SeMenu_ComputeParamTableAddr_Data',
     'Data for param table computation'),

    ('LABEL_F096E2', 'SeMenu_HandleMenuChange',
     'Handle menu change: read object data, dispatch by step'),

    ('LABEL_F09715', 'SeMenu_HandleMenuChange_NonZero',
     'Menu change: non-zero step (update existing entry)'),

    ('LABEL_F0974B', 'SeMenu_HandleMenuChange_Overflow',
     'Menu change: overflow (step too high, clear and send event)'),

    ('LABEL_F0975B', 'SeMenu_HandleMenuChange_End',
     'End of menu change handler'),

    ('LABEL_F0975F', 'SeMenu_HandleMenuChange_Data',
     'Data for menu change'),

    ('LABEL_F09769', 'SeMenu_LoadPatchStatus',
     'Load patch status: read mem offset 0x6B8 into (xwa)'),

    ('LABEL_F0976E', 'SeMenu_SetPatchBank',
     'Set patch bank: store A to mem[1720]'),

    ('LABEL_F09773', 'SeMenu_PatchBank_Data',
     'Data block for patch bank configuration'),

    # --- Menu state accessors (F098xx-F099xx) ---

    ('LABEL_F098BD', 'SeMenu_SetEditEnable',
     'Set edit enable: A=1 sets bit, A!=1 clears bit in mem[10407]'),

    ('LABEL_F098C6', 'SeMenu_SetEditEnable_Clear',
     'Clear edit enable bit'),

    ('LABEL_F098CB', 'SeMenu_OrPartConfig',
     'OR part config: merge A into mem[132594]'),

    ('LABEL_F098D1', 'SeMenu_OrPartConfig_Data',
     'Data for part config OR'),

    ('LABEL_F098E0', 'SeMenu_StoreParamByte',
     'Store byte C to param table[(A-1) + mem[1722]]'),

    ('LABEL_F098EF', 'SeMenu_LoadParamByte',
     'Load byte from param table[(A-1) + mem[1722]] into (BC)'),

    ('LABEL_F09900', 'SeMenu_SetConfirmState',
     'Set confirm state: store A to mem[1732]'),

    ('LABEL_F09905', 'SeMenu_LoadConfirmData',
     'Load confirm data: read mem offset 0x6C4 into (xwa)'),

    ('LABEL_F0990A', 'SeMenu_ReturnZero',
     'Return zero in L'),

    ('LABEL_F0990D', 'SeMenu_SetDisplayState',
     'Set display state: store A to mem[1733]'),

    ('LABEL_F09912', 'SeMenu_DisplayState_Data',
     'Data for display state'),

    ('LABEL_F09921', 'SeMenu_StoreEffectParam',
     'Store byte C to effect param array[A] at mem[1726]'),

    ('LABEL_F0992E', 'SeMenu_StoreEffectParam_Data',
     'Data for effect param store'),

    ('LABEL_F0993D', 'SeMenu_StoreEffectCoeff',
     'Store byte C to effect coefficient array[A] at mem[1729]'),

    ('LABEL_F0994A', 'SeMenu_StoreEffectCoeff_Data',
     'Data block: effect coefficient extended operations'),

    ('LABEL_F09A7D', 'SeMenu_RefreshPartDisplay',
     'Refresh display with 3 part values from mem[63926/63952/63978]'),

    ('LABEL_F09AC3', 'SeMenu_RefreshPartDisplay_Data',
     'Data block: extended part display refresh operations'),

    # --- UpdateSeMenuSelection and sub-functions (F0A1xx-F0A6xx) ---

    ('LABEL_F0A155', 'UpdSeSel_SkipMenuSetup',
     'Skip menu setup: proceed directly to confirm and refresh'),

    ('LABEL_F0A162', 'UpdSeSel_ProcessStep',
     'Process menu step: read object data, dispatch by step number'),

    ('LABEL_F0A18F', 'UpdSeSel_Step1_CheckEnabled',
     'Step 1: check if object 0x81 is enabled'),

    ('LABEL_F0A1AB', 'UpdSeSel_Step1_Disable',
     'Step 1: disable object 0x10 and set mode=0'),

    ('LABEL_F0A1B6', 'UpdSeSel_Step1_FillTable',
     'Step 1: fill entry table and check flags'),

    ('LABEL_F0A1D4', 'UpdSeSel_Step1_Flag40',
     'Step 1: flag=0x40 path (set mode=2, send event 0xEA)'),

    ('LABEL_F0A1F0', 'UpdSeSel_Step1_SetDisplayState',
     'Step 1: set display state and jump to end'),

    ('LABEL_F0A1F6', 'UpdSeSel_Step1_DefaultMode',
     'Step 1: default mode (set mode=0)'),

    ('LABEL_F0A1FE', 'UpdSeSel_Step1_SetStep',
     'Step 1: set current step from WA and continue'),

    ('LABEL_F0A202', 'UpdSeSel_UpdateEntries',
     'Update entries: store values, check step type'),

    ('LABEL_F0A214', 'UpdSeSel_UpdateEntries_CallSimple',
     'Update entries: call simple update handler'),

    ('LABEL_F0A217', 'UpdSeSel_ProcessStep_End',
     'Epilogue: restore stack and return from step processing'),

    ('LABEL_F0A21B', 'UpdSeSel_SimpleUpdate',
     'Simple update handler: process steps 2-10 sequentially'),

    ('LABEL_F0A241', 'UpdSeSel_SimpleUpdate_Step3',
     'Simple update: step 3 (fill table, store part, set value display)'),

    ('LABEL_F0A263', 'UpdSeSel_SimpleUpdate_Step4',
     'Simple update: step 4 (fill object, store 3 coefficients, transfer)'),

    ('LABEL_F0A2B0', 'UpdSeSel_SimpleUpdate_Step5',
     'Simple update: step 5 (fill table, store 3 effect params, set value)'),

    ('LABEL_F0A2E7', 'UpdSeSel_SimpleUpdate_SetStepAndJump',
     'Set step from WA and jump to end'),

    ('LABEL_F0A2EE', 'UpdSeSel_SimpleUpdate_Step6',
     'Simple update: step 6 (fill object, extract toggle bit, loop 1-4)'),

    ('LABEL_F0A30F', 'UpdSeSel_SimpleUpdate_Step6_RegLoop',
     'Step 6: register element loop for parts 1-4'),

    ('LABEL_F0A338', 'UpdSeSel_SimpleUpdate_Default',
     'Simple update: default step (read param, fill table, store value)'),

    ('LABEL_F0A375', 'UpdSeSel_SimpleUpdate_End',
     'Epilogue for simple update handler'),

    ('LABEL_F0A37C', 'UpdSeSel_DetailedUpdate',
     'Detailed update handler: process steps 2-10 with part validation'),

    ('LABEL_F0A3C3', 'UpdSeSel_DetailedUpdate_Step3_Store',
     'Step 3 detailed: store part values, set step 4'),

    ('LABEL_F0A3E3', 'UpdSeSel_DetailedUpdate_Step2',
     'Detailed update: step 2 (read confirm data, check state)'),

    ('LABEL_F0A406', 'UpdSeSel_DetailedUpdate_Step2_CheckActive',
     'Step 2: check if active (non-zero confirm data)'),

    ('LABEL_F0A420', 'UpdSeSel_DetailedUpdate_Step2_ReadPatch',
     'Step 2: read patch status'),

    ('LABEL_F0A444', 'UpdSeSel_DetailedUpdate_Step2_SetStep3',
     'Step 2: set step 3, check object 0x86 enabled'),

    ('LABEL_F0A460', 'UpdSeSel_DetailedUpdate_Step2_Disable',
     'Step 2: disable object 0x10 and set mode=0'),

    ('LABEL_F0A46C', 'UpdSeSel_DetailedUpdate_Step2_FillTable',
     'Step 2: fill table, check flag=0x10'),

    ('LABEL_F0A48E', 'UpdSeSel_DetailedUpdate_Step2_ClearPatch',
     'Step 2: clear patch bank, send event 0x20'),

    ('LABEL_F0A499', 'UpdSeSel_DetailedUpdate_SendEventAndEnd',
     'Send event via F06170 and jump to end'),

    ('LABEL_F0A4A0', 'UpdSeSel_DetailedUpdate_Step4',
     'Detailed update: step 4 (init track, register elements, loop parts)'),

    ('LABEL_F0A4BC', 'UpdSeSel_DetailedUpdate_Step4_RegLoop1',
     'Step 4: register element loop 1 (offset +5)'),

    ('LABEL_F0A4E4', 'UpdSeSel_DetailedUpdate_Step4_RegLoop2',
     'Step 4: register element loop 2 (offset +3)'),

    ('LABEL_F0A50C', 'UpdSeSel_DetailedUpdate_Step4_RegLoop3',
     'Step 4: register element loop 3 (offset +4)'),

    ('LABEL_F0A534', 'UpdSeSel_DetailedUpdate_Step4_RegLoop4',
     'Step 4: register element loop 4 (offset +0)'),

    ('LABEL_F0A576', 'UpdSeSel_DetailedUpdate_Step5',
     'Detailed update: step 5 (read param, fill table, store values, init fields)'),

    ('LABEL_F0A5F5', 'UpdSeSel_DetailedUpdate_Step6',
     'Detailed update: step 6 (apply filter, init column 0x20)'),

    ('LABEL_F0A60E', 'UpdSeSel_DetailedUpdate_Step7',
     'Detailed update: step 7 (apply filter, load edit param, register value)'),

    ('LABEL_F0A632', 'UpdSeSel_DetailedUpdate_Step8',
     'Detailed update: step 8 (apply synth, init column 0x20)'),

    ('LABEL_F0A64A', 'UpdSeSel_DetailedUpdate_Step9',
     'Detailed update: step 9 (process effect xwa=3, init column 0x20)'),

    ('LABEL_F0A662', 'UpdSeSel_DetailedUpdate_SetStepAndJump',
     'Set step from WA and jump to end'),

    ('LABEL_F0A668', 'UpdSeSel_DetailedUpdate_StepA',
     'Detailed update: step A (process effect xwa=2, show popup)'),

    ('LABEL_F0A69A', 'UpdSeSel_DetailedUpdate_SetDisplayState',
     'Set display state and fall through to end'),

    ('LABEL_F0A69E', 'UpdSeSel_DetailedUpdate_End',
     'Epilogue for detailed update handler'),

    ('LABEL_F0A6A5', 'UpdSeSel_ExtendedOps_Data',
     'Data block: extended operations for SE menu update (~1600 bytes)'),

    # --- Additional SE menu function (F0B3xx-F0B9xx) ---

    ('LABEL_F0B3DD', 'SeMenu_AltUpdate',
     'Alternate menu update: register elements for parts 1-4'),

    ('LABEL_F0B3F3', 'SeMenu_AltUpdate_RegLoop',
     'Alternate update: register element loop (3 calls per part)'),

    ('LABEL_F0B44F', 'SeMenu_AltUpdate_Step1',
     'Alternate update: step 1 (read param, fill table, store value)'),

    ('LABEL_F0B49A', 'SeMenu_AltUpdate_Step2',
     'Alternate update: step 2 (apply filter, check sub-index)'),

    ('LABEL_F0B4CB', 'SeMenu_AltUpdate_Step2_InitCol',
     'Step 2: init display column 0x22'),

    ('LABEL_F0B4D6', 'SeMenu_AltUpdate_SetStepAndJump',
     'Set step and jump to end'),

    ('LABEL_F0B4DC', 'SeMenu_AltUpdate_Step3Plus',
     'Alternate update: step 3+ (process effect, load params)'),

    ('LABEL_F0B54D', 'SeMenu_AltUpdate_End',
     'End of alternate menu update'),

    ('LABEL_F0B554', 'SeMenu_AltUpdate_Data',
     'Data block for alternate menu update'),

    ('LABEL_F0B7EE', 'SeMenu_ControllerUpdate',
     'Controller assignment update'),

    ('LABEL_F0B81F', 'SeMenu_ControllerUpdate_Step1',
     'Controller update: step 1'),

    ('LABEL_F0B83C', 'SeMenu_ControllerUpdate_Step2',
     'Controller update: step 2'),

    ('LABEL_F0B857', 'SeMenu_ControllerUpdate_Step3',
     'Controller update: step 3'),

    ('LABEL_F0B86C', 'SeMenu_ControllerUpdate_StoreValue',
     'Controller update: store and display value'),

    ('LABEL_F0B8BB', 'SeMenu_ControllerUpdate_End',
     'End of controller update'),

    ('LABEL_F0B8F0', 'SeMenu_ControllerData',
     'Data block for controller display'),

    ('LABEL_F0B8FD', 'SeMenu_ControllerData_Offset1',
     'Controller data offset 1'),

    ('LABEL_F0B902', 'SeMenu_ControllerData_Offset2',
     'Controller data offset 2'),

    ('LABEL_F0B908', 'SeMenu_ControllerData_Offset3',
     'Controller data offset 3'),

    ('LABEL_F0B90E', 'SeMenu_ControllerData_Offset4',
     'Controller data offset 4'),

    ('LABEL_F0B918', 'SeMenu_ControllerData_Offset5',
     'Controller data offset 5'),

    ('LABEL_F0B91A', 'SeMenu_ControllerData_Offset6',
     'Controller data offset 6'),

    ('LABEL_F0B93A', 'SeMenu_ControllerData_End',
     'End of controller data section'),

    ('LABEL_F0B941', 'SeMenu_CopyWriteUpdate',
     'Copy/Write update: manage sound patch copy and write operations'),

    ('LABEL_F0B966', 'SeMenu_CopyWriteUpdate_Step1',
     'Copy/Write: step 1 handler'),

    ('LABEL_F0B98D', 'SeMenu_CopyWriteUpdate_Step2',
     'Copy/Write: step 2 handler'),

    ('LABEL_F0B9AC', 'SeMenu_CopyWriteUpdate_Step3',
     'Copy/Write: step 3 handler'),

    ('LABEL_F0B9BD', 'SeMenu_CopyWriteUpdate_End',
     'End of copy/write update'),

    ('LABEL_F0B9C4', 'SeMenu_CopyWriteUpdate_Data',
     'Data block for copy/write operations'),

    # --- Display popup/dialog system (F0E9xx-F0EFxx) ---

    ('LABEL_F0E92F', 'SeMenu_PopupDialog_Init',
     'Initialize popup dialog system'),

    ('LABEL_F0E935', 'SeMenu_PopupDialog_CheckState',
     'Check dialog state'),

    ('LABEL_F0E94B', 'SeMenu_PopupDialog_Setup',
     'Setup popup dialog parameters'),

    ('LABEL_F0E953', 'SeMenu_PopupDialog_ShowTitle',
     'Show dialog title'),

    ('LABEL_F0E964', 'SeMenu_PopupDialog_ShowBody',
     'Show dialog body text'),

    ('LABEL_F0E96F', 'SeMenu_PopupDialog_ShowBody_Data',
     'Data for dialog body'),

    ('LABEL_F0E986', 'SeMenu_PopupDialog_HandleInput',
     'Handle dialog input events'),

    ('LABEL_F0E9A8', 'SeMenu_PopupDialog_HandleInput_Data',
     'Data for input handling'),

    ('LABEL_F0E9B3', 'SeMenu_PopupDialog_Confirm',
     'Dialog confirm action'),

    ('LABEL_F0E9C3', 'SeMenu_PopupDialog_Cancel',
     'Dialog cancel action'),

    ('LABEL_F0E9D1', 'SeMenu_PopupDialog_Close',
     'Close popup dialog'),

    ('LABEL_F0E9F1', 'SeMenu_PopupDialog_Close_Data',
     'Data for dialog close'),

    ('LABEL_F0EA1A', 'SeMenu_ValueEditor_Init',
     'Initialize value editor popup'),

    ('LABEL_F0EA31', 'SeMenu_ValueEditor_Setup',
     'Setup value editor with range and step'),

    ('LABEL_F0EA53', 'SeMenu_ValueEditor_Draw',
     'Draw value editor display'),

    ('LABEL_F0EA73', 'SeMenu_ValueEditor_HandleInput',
     'Handle value editor input'),

    ('LABEL_F0EA7B', 'SeMenu_ValueEditor_Increment',
     'Value editor: increment value'),

    ('LABEL_F0EA85', 'SeMenu_ValueEditor_Decrement',
     'Value editor: decrement value'),

    ('LABEL_F0EA9A', 'SeMenu_ValueEditor_ClampAndStore',
     'Clamp edited value to range and store'),

    ('LABEL_F0EAA5', 'SeMenu_ValueEditor_Redraw',
     'Redraw value editor after change'),

    ('LABEL_F0EAB5', 'SeMenu_ValueEditor_Complete',
     'Complete value editor: apply and close'),

    ('LABEL_F0EAC8', 'SeMenu_ValueEditor_Cancel',
     'Cancel value editor: restore original value'),

    ('LABEL_F0EACF', 'SeMenu_ValueEditor_Data1',
     'Value editor data 1'),

    ('LABEL_F0EAD4', 'SeMenu_ValueEditor_Data2',
     'Value editor data 2'),

    ('LABEL_F0EAD7', 'SeMenu_ValueEditor_Data3',
     'Value editor data 3'),

    ('LABEL_F0EADA', 'SeMenu_ValueEditor_Data4',
     'Value editor data 4'),

    ('LABEL_F0EAE4', 'SeMenu_ValueEditor_Data5',
     'Value editor data 5'),

    ('LABEL_F0EAFE', 'SeMenu_ListSelector_Init',
     'Initialize list selector popup'),

    ('LABEL_F0EB0A', 'SeMenu_ListSelector_Setup',
     'Setup list selector with items'),

    ('LABEL_F0EB26', 'SeMenu_ListSelector_Draw',
     'Draw list selector display'),

    ('LABEL_F0EB34', 'SeMenu_ListSelector_HandleInput',
     'Handle list selector input'),

    ('LABEL_F0EB5C', 'SeMenu_ListSelector_HandleInput_Data',
     'Data for list input handling'),

    ('LABEL_F0EB61', 'SeMenu_ListSelector_ScrollUp',
     'List selector: scroll up'),

    ('LABEL_F0EB65', 'SeMenu_ListSelector_ScrollDown',
     'List selector: scroll down'),

    ('LABEL_F0EB67', 'SeMenu_ListSelector_Select',
     'List selector: select current item'),

    ('LABEL_F0EB6F', 'SeMenu_ListSelector_Complete',
     'Complete list selection'),

    ('LABEL_F0EB7B', 'SeMenu_ListSelector_Cancel',
     'Cancel list selection'),

    ('LABEL_F0EBA8', 'SeMenu_ListSelector_Data',
     'Data for list selector'),

    ('LABEL_F0EBB4', 'SeMenu_ListSelector_Data2',
     'Additional list selector data'),

    ('LABEL_F0EBBB', 'SeMenu_ListSelector_Data3',
     'List selector data 3'),

    ('LABEL_F0EBDE', 'SeMenu_NameEditor_Init',
     'Initialize name/text editor'),

    ('LABEL_F0EC00', 'SeMenu_NameEditor_Setup',
     'Setup name editor buffer'),

    ('LABEL_F0EC0D', 'SeMenu_NameEditor_Draw',
     'Draw name editor display'),

    ('LABEL_F0EC1A', 'SeMenu_NameEditor_HandleInput',
     'Handle name editor input'),

    ('LABEL_F0EC23', 'SeMenu_NameEditor_HandleInput_Data',
     'Data for name editor input'),

    ('LABEL_F0EC35', 'SeMenu_NameEditor_InsertChar',
     'Name editor: insert character at cursor'),

    ('LABEL_F0EC47', 'SeMenu_NameEditor_DeleteChar',
     'Name editor: delete character at cursor'),

    ('LABEL_F0EC69', 'SeMenu_NameEditor_MoveCursor',
     'Name editor: move cursor left/right'),

    ('LABEL_F0EC7B', 'SeMenu_NameEditor_MoveCursor_Data',
     'Data for cursor movement'),

    ('LABEL_F0EC84', 'SeMenu_NameEditor_ChangeCase',
     'Name editor: toggle uppercase/lowercase'),

    ('LABEL_F0EC8D', 'SeMenu_NameEditor_ChangeCase_Data',
     'Data for case toggle'),

    ('LABEL_F0EC9F', 'SeMenu_NameEditor_SelectCharSet',
     'Name editor: select character set (alpha/num/special)'),

    ('LABEL_F0ECA8', 'SeMenu_NameEditor_SelectCharSet_Data',
     'Data for char set selection'),

    ('LABEL_F0ECBA', 'SeMenu_NameEditor_Complete',
     'Complete name editor: store name'),

    ('LABEL_F0ECCC', 'SeMenu_NameEditor_Cancel',
     'Cancel name editor'),

    ('LABEL_F0ECD5', 'SeMenu_NameEditor_Cancel_Data',
     'Data for name cancel'),

    ('LABEL_F0ECDE', 'SeMenu_NameEditor_Redraw',
     'Redraw name editor display'),

    ('LABEL_F0ECE7', 'SeMenu_NameEditor_Redraw_Data',
     'Data for name redraw'),

    ('LABEL_F0ECF0', 'SeMenu_NameEditor_End',
     'End of name editor'),

    ('LABEL_F0ED48', 'SeMenu_DisplayPartValue',
     'Display part value: push params, call display routine'),

    ('LABEL_F0ED7D', 'SeMenu_DisplayPartValue_Data',
     'Data: display format string for part values'),

    ('LABEL_F0EE6A', 'SeMenu_ShowPopupDialog',
     'Show popup dialog: create overlay and draw content'),

    ('LABEL_F0EE9B', 'SeMenu_ShowPopupDialog_Draw',
     'Popup dialog: draw content area'),

    ('LABEL_F0EF5B', 'SeMenu_ShowConfirmDialog',
     'Show confirm dialog: push params and create yes/no popup'),

    ('LABEL_F0EF8A', 'SeMenu_ShowConfirmDialog_Data',
     'Data for confirm dialog layout'),

    # --- Waveform/preset management (F0F4xx-F0F9xx) ---

    ('LABEL_F0F4DA', 'SeMenu_WaveformSelect_Init',
     'Initialize waveform selection mode'),

    ('LABEL_F0F4F2', 'SeMenu_WaveformSelect_End',
     'End of waveform select init'),

    ('LABEL_F0F4F3', 'SeMenu_WaveformSelect_Handler',
     'Waveform selection event handler'),

    ('LABEL_F0F4FE', 'SeMenu_WaveformSelect_Process',
     'Process waveform selection change'),

    ('LABEL_F0F507', 'SeMenu_WaveformSelect_Apply',
     'Apply selected waveform'),

    ('LABEL_F0F536', 'SeMenu_WaveformSelect_Data',
     'Data for waveform selection'),

    ('LABEL_F0F608', 'SeMenu_PresetManager_Init',
     'Initialize preset manager'),

    ('LABEL_F0F6D9', 'SeMenu_PresetManager_Load',
     'Preset manager: load preset'),

    ('LABEL_F0F6F4', 'SeMenu_PresetManager_End',
     'End of preset load'),

    ('LABEL_F0F6F5', 'SeMenu_PresetManager_Save',
     'Preset manager: save preset'),

    ('LABEL_F0F70E', 'SeMenu_PresetManager_SaveApply',
     'Save preset: apply to storage'),

    ('LABEL_F0F745', 'SeMenu_PresetManager_Data',
     'Data for preset manager'),

    ('LABEL_F0F939', 'SeMenu_PresetBrowser_Init',
     'Initialize preset browser'),

    ('LABEL_F0F96C', 'SeMenu_PresetBrowser_Navigate',
     'Preset browser: navigate entries'),

    ('LABEL_F0F981', 'SeMenu_PresetBrowser_Select',
     'Preset browser: select entry'),

    ('LABEL_F0F996', 'SeMenu_PresetBrowser_Data',
     'Data for preset browser'),

    # --- Compare/utility functions (F0FBxx-F0FFxx) ---

    ('LABEL_F0FB4E', 'SeMenu_CompareAndApply_Init',
     'Initialize compare-and-apply operation'),

    ('LABEL_F0FB6D', 'SeMenu_CompareAndApply_Check',
     'Compare: check source vs destination'),

    ('LABEL_F0FB7B', 'SeMenu_CompareAndApply_Match',
     'Compare: values match, skip apply'),

    ('LABEL_F0FBA4', 'SeMenu_CompareAndApply_Apply',
     'Compare: apply changed value'),

    ('LABEL_F0FBB8', 'SeMenu_CompareAndApply_End',
     'End of compare-and-apply'),

    ('LABEL_F0FBBD', 'SeMenu_CompareAndApply_Data',
     'Data for compare-and-apply'),

    ('LABEL_F0FBD6', 'SeMenu_CompareAndApply_Data2',
     'Additional compare data'),

    ('LABEL_F0FBDB', 'SeMenu_CompareAndApply_Data3',
     'Compare data 3'),

    ('LABEL_F0FBE0', 'SeMenu_CompareAndApply_Data4',
     'Compare data 4'),

    ('LABEL_F0FBF5', 'SeMenu_CompareAndApply_Data5',
     'Compare data 5'),

    ('LABEL_F0FBFF', 'SeMenu_CompareAndApply_Data6',
     'Compare data 6'),

    ('LABEL_F0FC56', 'SeMenu_Utility_CopyBlock',
     'Utility: copy block of data between memory regions'),

    ('LABEL_F0FD37', 'SeMenu_Utility_FillBlock',
     'Utility: fill memory block with value'),

    ('LABEL_F0FD92', 'SeMenu_Utility_CompareBlock',
     'Utility: compare two memory blocks'),

    ('LABEL_F0FDBD', 'SeMenu_Utility_CompareBlock_Loop',
     'Block compare loop'),

    ('LABEL_F0FDE2', 'SeMenu_Utility_CompareBlock_End',
     'End of block compare'),

    ('LABEL_F0FDF5', 'SeMenu_Utility_SearchByte',
     'Utility: search for byte value in block'),

    ('LABEL_F0FE09', 'SeMenu_Utility_SearchByte_End',
     'End of byte search'),

    ('LABEL_F0FE0E', 'SeMenu_Utility_FormatNumber',
     'Utility: format number for display (BCD conversion)'),

    ('LABEL_F0FE18', 'SeMenu_Utility_FormatNumber_Loop',
     'Number format: BCD conversion loop'),

    ('LABEL_F0FE2D', 'SeMenu_Utility_FormatNumber_End',
     'End of number formatting'),

    ('LABEL_F0FE4E', 'SeMenu_Utility_FormatNumber_Data',
     'Data for number formatting'),

    ('LABEL_F0FE53', 'SeMenu_Utility_FormatSigned',
     'Utility: format signed number for display'),

    ('LABEL_F0FE67', 'SeMenu_Utility_FormatSigned_Data',
     'Data for signed number format'),

    ('LABEL_F0FEB7', 'SeMenu_Utility_FormatPercent',
     'Utility: format percentage value for display'),

    ('LABEL_F0FF07', 'SeMenu_Utility_FormatPercent_Data',
     'Data for percentage format'),

    ('LABEL_F0FF57', 'SeMenu_Utility_FormatHex',
     'Utility: format hex value for display'),

    ('LABEL_F0FF99', 'SeMenu_Utility_FormatHex_Data',
     'Data for hex format'),

    ('LABEL_F0FFC7', 'SeMenu_Utility_End',
     'End of utility functions'),
]

# ---------------------------------------------------------------------------
# Main: perform renames using binary I/O for Latin-1 safety
# ---------------------------------------------------------------------------

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
        print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
