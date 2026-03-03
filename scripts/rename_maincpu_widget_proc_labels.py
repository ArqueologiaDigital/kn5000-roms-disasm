#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for NAKA widget procedures in maincpu.

Covers widget procedure functions in the F9D-FA8 address range:
  PsListBoxProc, AcListBoxProc, PsGridBoxProc, AcGridBoxProc,
  PsEditBoxProc, PsNumEditBoxProc, PsTblEditBoxProc, AcOnOffBoxProc,
  AcNumEditBoxProc, AcLswEditBoxProc, AcRamEditBoxProc, AcBitEditBoxProc,
  PsMenuBoxProc, AcTitleMenuProc, VwMenuBoxProc, PsEditSwBoxProc,
  PsToggleBoxProc, AcFuncToggleProc, AcIndexToggleProc, PsWideToggleProc,
  PsInvisibleBoxProc, IvPageControlProc, IvMainEditSwProc, IvExitProc,
  IvExitModeProc, IvExitScreenProc, IvExitWindowProc, IvFixWinProc,
  IvNamingProc, IvTrackSwitchProc, IvCatchEventProc,
  ViewableProc, ViewIDProc, ScreenIDProc, WindowIDProc

Each rename was determined by analyzing the dispatch tables, event code
comparisons, control flow, and widget field access patterns.

NAKA event codes referenced:
  0x1C00001=Init, 0x1C00002=Close, 0x1C00007=OK, 0x1C0000B=Show,
  0x1C0000C=Hide, 0x1C0000D=Paint, 0x1C0000E=Select, 0x1C0000F=Confirm,
  0x1C00017=ScrollUp, 0x1C00018=ScrollDown, 0x1C00019=AutoIncUp,
  0x1C0001A=AutoIncDown, 0x1C0001B=Release, 0x1C0001C=Match,
  0x1C0001D=Assign, 0x1C0001E=PageChange, 0x1C0002C=Reset,
  0x1E0003A=GetText, 0x1E0003B=SetValue, 0x1E0003C=CanScroll,
  0x1E0003D=AddDelta, 0x1E0003E=GetUpStep, 0x1E0003F=GetDownStep,
  0x1E0004D=SetIndex, 0x1E0004F=GetBounds(x), 0x1E00050=CanScrollEvt,
  0x1E00052=GetBounds(y), 0x1E00053=HitTest, 0x1E00063=GetAddr,
  0x1E00064=GetBitMask, 0x1E00065=GetToggle, 0x1E0006B=GetValue,
  0x1E0006C=Toggle, 0x1E00090=GetCount, 0x1E0008A=GetColText,
  0x1E0008B=GetRowText, 0x1E0008C=PlayAudio, 0x1E0008D=CellSelect,
  0x1E0008E=GridScroll, 0x1E0008F=GetCellIndex, 0x1E0009C=Repaint,
  0x1E000B5=MatchClass,
  0x1E0000C=EnumOpen, 0x1E0000D=EnumFill, 0x1E0000E=EnumCount,
  0x1E00009=GetCurrent, 0x1E0000B=GetNext, 0x1E0000F=GetInstance,
  0x1E00014=CheckType, 0x1E00015=GetName, 0x1E00016=SetName,
  0x1E00024=Dispatch, 0x1E00028=GetInfoStr, 0x1E00036=GetParent,
  0x1E00037=GetOwner, 0x1E00038=GetChild, 0x1E00039=GetClass

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit
tool on kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
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
    # PsListBoxProc  (F9D7A0 - F9DBD9)
    # List box base procedure: handles Paint, Confirm, Select, Reset,
    # GetCount, SetIndex, GetText events for a scrollable list widget.
    # ==================================================================
    ('LABEL_F9D7BC', 'PsListBox_Confirm',
     'Handle 0x1C0000F Confirm: forward to VwBoxProc then build items'),

    ('LABEL_F9D7E5', 'PsListBox_Confirm_CopyText',
     'Confirm path when text data provided: Strcpy into buffer'),

    ('LABEL_F9D7F2', 'PsListBox_Confirm_Layout',
     'Calculate item heights and layout the list box client area'),

    ('LABEL_F9D840', 'PsListBox_Confirm_ItemLoop',
     'Outer loop: iterate through list items for rendering'),

    ('LABEL_F9D850', 'PsListBox_Confirm_ScanPipe',
     'Check for pipe 0x7C delimiter in text string'),

    ('LABEL_F9D85D', 'PsListBox_Confirm_AdvanceChar',
     'Advance character index past non-pipe character'),

    ('LABEL_F9D860', 'PsListBox_Confirm_ScanLoop',
     'Inner scan loop: walk string bytes until NUL or pipe'),

    ('LABEL_F9D86F', 'PsListBox_Confirm_DrawItem',
     'Draw one list item with center alignment and focus check'),

    ('LABEL_F9D8C9', 'PsListBox_Confirm_ItemUnfocused',
     'Item is not focused: push params without highlight flag'),

    ('LABEL_F9D8DF', 'PsListBox_Confirm_RenderText',
     'Call text renderer (0xFAD084) and advance box coordinates'),

    ('LABEL_F9D903', 'PsListBox_Select',
     'Handle 0x1C0000E Select: scroll to selected item and redraw'),

    ('LABEL_F9D99B', 'PsListBox_Select_ScanItems',
     'Scan items loop for Select: parse pipe-delimited text'),

    ('LABEL_F9D9AB', 'PsListBox_Select_CheckPipe',
     'Check byte for pipe delimiter during select scan'),

    ('LABEL_F9D9B8', 'PsListBox_Select_NextChar',
     'Advance to next character in select scan'),

    ('LABEL_F9D9BB', 'PsListBox_Select_ScanLoop',
     'Inner string scan loop for select'),

    ('LABEL_F9D9CA', 'PsListBox_Select_NextItem',
     'Increment item counter in select scan'),

    ('LABEL_F9D9CD', 'PsListBox_Select_CheckDone',
     'Check if all items scanned; draw selection frame if focused'),

    ('LABEL_F9DA1E', 'PsListBox_Select_UpdateCurrent',
     'Store new selection index and recalculate layout'),

    ('LABEL_F9DA97', 'PsListBox_SelectUpd_ScanItems',
     'Scan items loop after update: parse pipe-delimited text'),

    ('LABEL_F9DAA7', 'PsListBox_SelectUpd_CheckPipe',
     'Check byte for pipe delimiter during post-update scan'),

    ('LABEL_F9DAB4', 'PsListBox_SelectUpd_NextChar',
     'Advance to next character in post-update scan'),

    ('LABEL_F9DAB7', 'PsListBox_SelectUpd_ScanLoop',
     'Inner string scan loop for post-update'),

    ('LABEL_F9DAC6', 'PsListBox_SelectUpd_NextItem',
     'Increment item counter in post-update scan'),

    ('LABEL_F9DAC9', 'PsListBox_SelectUpd_CheckDone',
     'Check if done scanning; draw items with focus indicator'),

    ('LABEL_F9DB19', 'PsListBox_SelectUpd_DrawUnfocused',
     'Render item text without focus highlight'),

    ('LABEL_F9DB43', 'PsListBox_Reset',
     'Handle 0x1C0002C Reset: forward to VwBoxProc and report current index'),

    ('LABEL_F9DB6C', 'PsListBox_GetCount',
     'Handle 0x1E00090 GetCount: return number of items'),

    ('LABEL_F9DB7E', 'PsListBox_SetIndex',
     'Handle 0x1E0004D SetIndex: validate and set list selection index'),

    ('LABEL_F9DBB0', 'PsListBox_SendEvent',
     'Common tail: call 0xFA9660 to dispatch event then return'),

    ('LABEL_F9DBB6', 'PsListBox_GetText',
     'Handle 0x1E0003A GetText: copy list text to output buffer'),

    ('LABEL_F9DBC8', 'PsListBox_ReturnZero',
     'Return HL=0 (handled, no propagation)'),

    ('LABEL_F9DBCC', 'PsListBox_Default',
     'Default handler: forward unrecognized events to VwBoxProc'),

    ('LABEL_F9DBD9', 'PsListBox_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # AcListBoxProc  (F9DBE1 - F9DD80)
    # Active list box: wraps PsListBoxProc with scroll dial and auto-inc.
    # ==================================================================
    ('LABEL_F9DC5D', 'AcListBox_ScrollUpDown',
     'Handle ScrollUp/ScrollDown (0x1C00017/19): forward and set auto-inc dials'),

    ('LABEL_F9DCDD', 'AcListBox_ScrollDownInc',
     'Handle ScrollDown/AutoIncDown (0x1C00018/1A): dec index and set dials'),

    ('LABEL_F9DD59', 'AcListBox_EnableDials',
     'Call SetDialEnable after configuring scroll dials'),

    ('LABEL_F9DD5E', 'AcListBox_GetText',
     'Handle 0x1E0003A GetText: copy extended text (offset +42) to buffer'),

    ('LABEL_F9DD73', 'AcListBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9DD77', 'AcListBox_Default',
     'Default handler: forward to PsListBoxProc'),

    ('LABEL_F9DD80', 'AcListBox_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # PsGridBoxProc  (F9DDA4 - F9E94F)
    # Grid box base procedure: multi-column/row grid with cell selection,
    # column widths, pipe-delimited text parsing, and cell navigation.
    # ==================================================================
    ('LABEL_F9DE32', 'PsGridBox_Init',
     'Handle 0x1C00001 Init: allocate column/row/type arrays'),

    ('LABEL_F9DE87', 'PsGridBox_Close',
     'Handle 0x1C00002 Close: free column/row/type arrays'),

    ('LABEL_F9DEC1', 'PsGridBox_Close_FreeRows',
     'Free row widths array (offset +54)'),

    ('LABEL_F9DEDA', 'PsGridBox_Close_FreeRowAlt',
     'Free alternate row array (offset +54, second allocation)'),

    ('LABEL_F9DEF3', 'PsGridBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9DEF8', 'PsGridBox_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: parse text and lay out grid'),

    ('LABEL_F9DF27', 'PsGridBox_ShowHide_CountPipe',
     'Count pipe delimiters in column text'),

    ('LABEL_F9DF2F', 'PsGridBox_ShowHide_CountNext',
     'Advance character index while counting'),

    ('LABEL_F9DF32', 'PsGridBox_ShowHide_CountLoop',
     'Scan loop: count characters and pipe delimiters'),

    ('LABEL_F9DF94', 'PsGridBox_ShowHide_CalcWidths',
     'Calculate column widths by measuring text segments'),

    ('LABEL_F9DFA4', 'PsGridBox_ShowHide_ScanPipe',
     'Check for pipe delimiter while scanning column text'),

    ('LABEL_F9DFB1', 'PsGridBox_ShowHide_AdvChar',
     'Advance past non-pipe character'),

    ('LABEL_F9DFB4', 'PsGridBox_ShowHide_ScanLoop',
     'Inner scan loop for column width calculation'),

    ('LABEL_F9DFC3', 'PsGridBox_ShowHide_CalcWidth',
     'Compute proportional column width and store in array'),

    ('LABEL_F9E00A', 'PsGridBox_ShowHide_ParseRows',
     'Parse row text (0x1E0008B) and calculate row boundaries'),

    ('LABEL_F9E044', 'PsGridBox_ShowHide_RowScan',
     'Scan row text for pipe delimiters'),

    ('LABEL_F9E054', 'PsGridBox_ShowHide_RowPipe',
     'Check byte for pipe in row text scan'),

    ('LABEL_F9E061', 'PsGridBox_ShowHide_RowNext',
     'Advance past non-pipe character in row text'),

    ('LABEL_F9E064', 'PsGridBox_ShowHide_RowLoop',
     'Inner scan loop for row text parsing'),

    ('LABEL_F9E073', 'PsGridBox_ShowHide_ClassifyCell',
     'Classify cell type (dash=1, empty=0, normal=2) into type array'),

    ('LABEL_F9E099', 'PsGridBox_ShowHide_CellDash',
     'Cell starts with dash 0x2D: type = 1'),

    ('LABEL_F9E09D', 'PsGridBox_ShowHide_CellNormal',
     'Cell is normal text: type = 2'),

    ('LABEL_F9E09F', 'PsGridBox_ShowHide_StoreType',
     'Store cell type and calculate row height'),

    ('LABEL_F9E0CB', 'PsGridBox_ShowHide_DashRow',
     'Dash cell: store height directly (no multiply)'),

    ('LABEL_F9E0D3', 'PsGridBox_ShowHide_AccumHeight',
     'Accumulate total height and advance to next row'),

    ('LABEL_F9E0F7', 'PsGridBox_ShowHide_FinalRow',
     'Set final row type to separator (type=5) and compute boundaries'),

    ('LABEL_F9E134', 'PsGridBox_ShowHide_BoundLoop',
     'Loop: compute cumulative row boundaries from proportional heights'),

    ('LABEL_F9E16E', 'PsGridBox_ShowHide_Forward',
     'Forward Init/Show/Hide to VwBoxProc'),

    ('LABEL_F9E17D', 'PsGridBox_ShowHide_Tail',
     'Tail call to VwBoxProc then return zero'),

    ('LABEL_F9E183', 'PsGridBox_Paint',
     'Handle 0x1C0000D Paint: forward, then send Confirm+Select events'),

    ('LABEL_F9E1C8', 'PsGridBox_Confirm',
     'Handle 0x1C0000F Confirm: lay out columns and render cells'),

    ('LABEL_F9E231', 'PsGridBox_Confirm_ColScan',
     'Scan column text for pipe delimiters during Confirm'),

    ('LABEL_F9E241', 'PsGridBox_Confirm_ColPipe',
     'Check for pipe in column text during Confirm'),

    ('LABEL_F9E24E', 'PsGridBox_Confirm_ColNext',
     'Advance past non-pipe char in Confirm column scan'),

    ('LABEL_F9E251', 'PsGridBox_Confirm_ColLoop',
     'Inner scan loop for Confirm column parsing'),

    ('LABEL_F9E260', 'PsGridBox_Confirm_DrawCol',
     'Render one column cell using column widths array'),

    ('LABEL_F9E2D0', 'PsGridBox_Confirm_Rows',
     'Parse row text and render row cells during Confirm'),

    ('LABEL_F9E310', 'PsGridBox_Confirm_RowScan',
     'Scan row text for pipe delimiters during row rendering'),

    ('LABEL_F9E320', 'PsGridBox_Confirm_RowPipe',
     'Check byte for pipe in Confirm row scan'),

    ('LABEL_F9E32D', 'PsGridBox_Confirm_RowAdv',
     'Advance past non-pipe char in Confirm row scan'),

    ('LABEL_F9E330', 'PsGridBox_Confirm_RowLoop',
     'Inner scan loop for Confirm row parsing'),

    ('LABEL_F9E33F', 'PsGridBox_Confirm_DrawRow',
     'Render one row cell: normal text or dash separator'),

    ('LABEL_F9E3AF', 'PsGridBox_Confirm_DrawSep',
     'Draw dash separator row with centered line'),

    ('LABEL_F9E40B', 'PsGridBox_Confirm_RowDone',
     'Advance to next row in Confirm rendering loop'),

    ('LABEL_F9E41A', 'PsGridBox_Confirm_CellSelect',
     'Send CellSelect (0x1E0008D) events for normal cells'),

    ('LABEL_F9E42A', 'PsGridBox_Confirm_OuterLoop',
     'Outer row loop for cell selection events'),

    ('LABEL_F9E439', 'PsGridBox_Confirm_InnerLoop',
     'Inner column loop: check cell type and send CellSelect'),

    ('LABEL_F9E46A', 'PsGridBox_Confirm_InnerNext',
     'Advance to next column in cell selection loop'),

    ('LABEL_F9E478', 'PsGridBox_Confirm_OuterNext',
     'Advance to next row in cell selection outer loop'),

    ('LABEL_F9E489', 'PsGridBox_Select',
     'Handle 0x1C0000E Select: highlight selected cell in grid'),

    ('LABEL_F9E523', 'PsGridBox_Select_NoOld',
     'No previous selection: set marker to 0xFFFF'),

    ('LABEL_F9E528', 'PsGridBox_Select_Scroll',
     'Handle scrolling: adjust column boundaries after selection'),

    ('LABEL_F9E563', 'PsGridBox_Select_ScrollLoop',
     'Loop: scroll column boundaries and clear lines'),

    ('LABEL_F9E5A3', 'PsGridBox_Select_StoreSel',
     'Store new selection and send CellSelect events'),

    ('LABEL_F9E5D8', 'PsGridBox_Select_SendCurr',
     'Send CellSelect for current selection'),

    ('LABEL_F9E657', 'PsGridBox_Scroll',
     'Handle ScrollUp/Down/AutoInc: validate and scroll grid'),

    ('LABEL_F9E6E6', 'PsGridBox_Scroll_DefaultCol',
     'Fill in default column if 0xFFFF'),

    ('LABEL_F9E6F9', 'PsGridBox_Scroll_CalcBounds',
     'Calculate cell boundaries for scrolled position'),

    ('LABEL_F9E785', 'PsGridBox_Scroll_Unfocused',
     'Scrolled cell not focused: set highlight=0'),

    ('LABEL_F9E787', 'PsGridBox_Scroll_Render',
     'Render scrolled cell with focus/highlight state'),

    ('LABEL_F9E801', 'PsGridBox_Scroll_CopyStr',
     'Copy grid string via Strcpy (scrollbar label)'),

    ('LABEL_F9E838', 'PsGridBox_Scroll_DefaultRow',
     'Fill in default row from widget field if 0xFFFF'),

    ('LABEL_F9E852', 'PsGridBox_Scroll_CheckRowChange',
     'Check if row changed and send Select event'),

    ('LABEL_F9E872', 'PsGridBox_Scroll_CheckColChange',
     'Check if column changed and send CellSelect'),

    ('LABEL_F9E888', 'PsGridBox_Scroll_StoreCol',
     'Store new column selection if not 0xFFFF'),

    ('LABEL_F9E89B', 'PsGridBox_Scroll_SendOldCell',
     'Send CellSelect for old cell position'),

    ('LABEL_F9E8C4', 'PsGridBox_Scroll_SendNewCell',
     'Send CellSelect for new cell position'),

    ('LABEL_F9E8E6', 'PsGridBox_DispatchEvent',
     'Common dispatch: call 0xFA9660 then return zero'),

    ('LABEL_F9E93D', 'PsGridBox_Default',
     'Default handler: forward unrecognized events to VwBoxProc'),

    ('LABEL_F9E94F', 'PsGridBox_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcGridBoxProc  (F9E964 - F9EBBE)
    # Active grid box: wraps PsGridBoxProc with scroll dials, auto-inc,
    # and external child widget notification.
    # ==================================================================
    ('LABEL_F9E9B3', 'AcGridBox_Init',
     'Handle Init: forward to PsGridBoxProc, configure scroll dials'),

    ('LABEL_F9EA73', 'AcGridBox_ScrollUp_Alt',
     'ScrollUp alternative: notify external child widget (offset +70)'),

    ('LABEL_F9EB1E', 'AcGridBox_ScrollDown_Alt',
     'ScrollDown alternative: notify external child widget (offset +70)'),

    ('LABEL_F9EB70', 'AcGridBox_EnableDials',
     'Call SetDialEnable after configuring scroll dials'),

    ('LABEL_F9EB75', 'AcGridBox_GetColText',
     'Handle 0x1E0008A GetColText: copy text from offset +62'),

    ('LABEL_F9EB7F', 'AcGridBox_GetRowText',
     'Handle 0x1E0008B GetRowText: copy text from offset +66'),

    ('LABEL_F9EB87', 'AcGridBox_CopyText',
     'Common text copy: get widget data, Strcpy text to caller'),

    ('LABEL_F9EB9C', 'AcGridBox_CellSelect',
     'Handle 0x1E0008D CellSelect: forward to child widget (offset +70)'),

    ('LABEL_F9EBAF', 'AcGridBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9EBB3', 'AcGridBox_Default',
     'Default handler: forward to PsGridBoxProc'),

    ('LABEL_F9EBBE', 'AcGridBox_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # GridCheck  (F9EBC2 - F9EC3B)
    # Validates grid cell actions: plays audio and dispatches cell events.
    # ==================================================================
    ('LABEL_F9EBFC', 'GridCheck_JumpEnd',
     'End of jump table; fall through'),

    ('LABEL_F9EBFE', 'GridCheck_CellSelect',
     'Handle CellSelect: extract row/col, play audio, dispatch event'),

    ('LABEL_F9EC3B', 'GridCheck_Return',
     'Return from GridCheck'),

    # ==================================================================
    # PsEditBoxProc  (F9EC5B - F9F076)
    # Edit box base procedure: text editing with cursor, scrolling,
    # dial-based increment/decrement, and text formatting.
    # ==================================================================
    ('LABEL_F9ECF8', 'PsEditBox_SetIndex_CheckDial',
     'After SetIndex: check if single-item and configure dials'),

    ('LABEL_F9ED31', 'PsEditBox_Init',
     'Handle 0x1C00001 Init: forward to VwBoxProc, configure edit dials'),

    ('LABEL_F9ED81', 'PsEditBox_Init_EnableDials',
     'Call SetDialEnable to activate scroll dials'),

    ('LABEL_F9ED84', 'PsEditBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9ED89', 'PsEditBox_Paint',
     'Handle 0x1C0000D Paint: render edit box with cursor and text'),

    ('LABEL_F9EE44', 'PsEditBox_Select',
     'Handle 0x1C0000E Select: validate cursor pos and send SetIndex'),

    ('LABEL_F9EE69', 'PsEditBox_Confirm',
     'Handle 0x1C0000F Confirm: format and render edited text'),

    ('LABEL_F9EEEC', 'PsEditBox_Confirm_CopyText',
     'Confirm with text: Strcpy input text to display buffer'),

    ('LABEL_F9EEF9', 'PsEditBox_Confirm_Render',
     'Render confirmed text with font, style, and focus indicator'),

    ('LABEL_F9EF2D', 'PsEditBox_Confirm_SetFocus',
     'Set focus indicator flag based on edit state'),

    ('LABEL_F9EF37', 'PsEditBox_GetText',
     'Handle 0x1E0003A GetText: clear output buffer'),

    ('LABEL_F9EF42', 'PsEditBox_OK',
     'Handle 0x1C00007 OK: check edit mode and send Release/SetIndex'),

    ('LABEL_F9EF7E', 'PsEditBox_OK_Forward',
     'OK not in edit mode: forward to VwBoxProc'),

    ('LABEL_F9EF8D', 'PsEditBox_Release',
     'Handle 0x1C0001B Release: check edit state and send SetIndex'),

    ('LABEL_F9EFC8', 'PsEditBox_Dispatch',
     'Common dispatch: call 0xFA9660 then return zero'),

    ('LABEL_F9EFCF', 'PsEditBox_ScrollUp',
     'Handle 0x1C00017 ScrollUp: check CanScroll and set auto-inc'),

    ('LABEL_F9F007', 'PsEditBox_ScrollDown',
     'Handle 0x1C00018 ScrollDown: check CanScroll and set auto-inc'),

    ('LABEL_F9F03D', 'PsEditBox_SetAutoInc',
     'Tail: call SetAutoInc then return zero'),

    ('LABEL_F9F043', 'PsEditBox_CanScroll',
     'Handle 0x1E0003C CanScroll: return 1 if single-item edit in range'),

    ('LABEL_F9F067', 'PsEditBox_Default',
     'Default handler: forward unrecognized events to VwBoxProc'),

    ('LABEL_F9F073', 'PsEditBox_DefaultTail',
     'Tail call to VwBoxProc'),

    ('LABEL_F9F076', 'PsEditBox_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # PsNumEditBoxProc  (F9F080 - F9F109)
    # Numeric edit box: wraps PsEditBoxProc with number formatting.
    # ==================================================================
    ('LABEL_F9F0A3', 'PsNumEditBox_Confirm',
     'Handle Confirm: format number string and forward to PsEditBoxProc'),

    ('LABEL_F9F109', 'PsNumEditBox_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # PsTblEditBoxProc  (F9F10F - F9F169)
    # Table edit box: wraps PsEditBoxProc with table lookup via 0x1E0004C.
    # ==================================================================
    ('LABEL_F9F13E', 'PsTblEditBox_Confirm',
     'Handle Confirm: look up table entry and forward to PsEditBoxProc'),

    ('LABEL_F9F169', 'PsTblEditBox_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # PasTableCheck  (F9F16D - F9F18E)
    # Table check helper: handles 0x1E0004C by looking up string table.
    # ==================================================================
    ('LABEL_F9F18E', 'PasTableCheck_Return',
     'Return HL=0 (not handled or done)'),

    # ==================================================================
    # AcOnOffBoxProc  (F9F190 - F9F294)
    # On/Off toggle box: wraps PsEditBoxProc with binary toggle logic.
    # ==================================================================
    ('LABEL_F9F1E0', 'AcOnOff_GetText',
     'Handle GetText: look up On/Off string from table at 0xEAA29A'),

    ('LABEL_F9F207', 'AcOnOff_SetValue',
     'Handle SetValue: store new on/off value and send Confirm'),

    ('LABEL_F9F22D', 'AcOnOff_GetValue',
     'Handle GetValue: return current on/off value'),

    ('LABEL_F9F23C', 'AcOnOff_ScrollUp',
     'Handle ScrollUp: check CanScroll and send SetValue=1'),

    ('LABEL_F9F261', 'AcOnOff_ScrollDown',
     'Handle ScrollDown: check CanScroll and send SetValue=0'),

    ('LABEL_F9F284', 'AcOnOff_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_F9F288', 'AcOnOff_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9F28C', 'AcOnOff_Default',
     'Default handler: forward to PsEditBoxProc'),

    ('LABEL_F9F294', 'AcOnOff_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # AcNumEditBoxProc  (F9F296 - F9F4D6)
    # Active numeric edit box: handles GetText with number formatting,
    # SetValue with bounds checking, AddDelta, and scroll increment.
    # ==================================================================
    ('LABEL_F9F308', 'AcNumEdit_GetText',
     'Handle GetText: format number and send to audio subsystem'),

    ('LABEL_F9F36B', 'AcNumEdit_SetValue',
     'Handle SetValue: store value and send Confirm'),

    ('LABEL_F9F387', 'AcNumEdit_AddDelta',
     'Handle AddDelta: bounds-check and apply delta to current value'),

    ('LABEL_F9F3BF', 'AcNumEdit_AddDelta_Negative',
     'AddDelta with negative value: check lower bound'),

    ('LABEL_F9F3E0', 'AcNumEdit_GetValue',
     'Handle GetValue: return current numeric value'),

    ('LABEL_F9F3F1', 'AcNumEdit_AutoIncUp',
     'Handle AutoIncUp: check CanScroll, get up-step, send AddDelta'),

    ('LABEL_F9F427', 'AcNumEdit_ScrollUp',
     'Handle ScrollUp: check CanScroll, get down-step, send AddDelta'),

    ('LABEL_F9F45B', 'AcNumEdit_AutoIncDown',
     'Handle AutoIncDown: check CanScroll, negate up-step, send AddDelta'),

    ('LABEL_F9F491', 'AcNumEdit_ScrollDown',
     'Handle ScrollDown: check CanScroll, negate down-step, send AddDelta'),

    ('LABEL_F9F4C5', 'AcNumEdit_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_F9F4C9', 'AcNumEdit_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9F4CD', 'AcNumEdit_Default',
     'Default handler: forward to PsEditBoxProc'),

    ('LABEL_F9F4D6', 'AcNumEdit_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # AcLswEditBoxProc  (F9F4D8 - F9F827)
    # LSW (List Switch) edit box: wraps PsEditBoxProc with LSW list
    # operations (put, add, get, filter) via MainLsw* helpers.
    # ==================================================================
    ('LABEL_F9F599', 'AcLswEdit_SetValue',
     'Handle SetValue: get LSW address/size, call MainLswPut'),

    ('LABEL_F9F5D5', 'AcLswEdit_AddDelta',
     'Handle AddDelta: get LSW address/size, call MainLswAdd'),

    ('LABEL_F9F611', 'AcLswEdit_Init',
     'Handle Init: forward to PsEditBoxProc'),

    ('LABEL_F9F619', 'AcLswEdit_Close',
     'Handle Close: forward to PsEditBoxProc'),

    ('LABEL_F9F61F', 'AcLswEdit_ForwardEdit',
     'Common: call PsEditBoxProc then return'),

    ('LABEL_F9F625', 'AcLswEdit_ShowHide',
     'Handle Show/Hide: forward to PsEditBoxProc then call MainLswGet'),

    ('LABEL_F9F64F', 'AcLswEdit_Match',
     'Handle Match (0x1C0001C): compare LSW addr and apply matched value'),

    ('LABEL_F9F6A7', 'AcLswEdit_AutoIncUp',
     'Handle AutoIncUp: check CanScroll, get step, send AddDelta'),

    ('LABEL_F9F6EC', 'AcLswEdit_ScrollUp',
     'Handle ScrollUp: check CanScroll, get step, send AddDelta'),

    ('LABEL_F9F731', 'AcLswEdit_AutoIncDown',
     'Handle AutoIncDown: check CanScroll, negate step, send AddDelta'),

    ('LABEL_F9F77D', 'AcLswEdit_ScrollDown',
     'Handle ScrollDown: check CanScroll, negate step, send AddDelta'),

    ('LABEL_F9F7C7', 'AcLswEdit_ResetBtn',
     'Handle Reset button (0x1C00031): check CanScroll, get filter, send SetValue'),

    ('LABEL_F9F816', 'AcLswEdit_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_F9F81A', 'AcLswEdit_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9F81E', 'AcLswEdit_Default',
     'Default handler: forward to PsEditBoxProc'),

    ('LABEL_F9F827', 'AcLswEdit_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # LswEditCheck  (F9F82C - F9F888)
    # Check handler for LSW edit: returns step sizes and dispatches audio.
    # ==================================================================
    ('LABEL_F9F877', 'LswEditCheck_GetAddr',
     'Return LSW address (0x1F47)'),

    ('LABEL_F9F87E', 'LswEditCheck_StepOne',
     'Return step = 1'),

    ('LABEL_F9F882', 'LswEditCheck_StepFour',
     'Return step = 4'),

    ('LABEL_F9F886', 'LswEditCheck_NotHandled',
     'Return HL=0 (not handled)'),

    ('LABEL_F9F888', 'LswEditCheck_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # AcRamEditBoxProc  (F9FACA - F9FDD1)
    # RAM edit box: wraps PsEditBoxProc with RAM put/add/get operations.
    # ==================================================================
    ('LABEL_F9FB4F', 'AcRamEdit_SetValue',
     'Handle SetValue: prepare RAM data and call MainRamPut'),

    ('LABEL_F9FBBB', 'AcRamEdit_AddDelta',
     'Handle AddDelta: prepare RAM data and call MainRamAdd'),

    ('LABEL_F9FC27', 'AcRamEdit_ShowHide',
     'Handle Show/Hide: forward to PsEditBoxProc then call MainRamGet'),

    ('LABEL_F9FC63', 'AcRamEdit_Assign',
     'Handle Assign (0x1C0001D): compare addr and apply assigned value'),

    ('LABEL_F9FCB4', 'AcRamEdit_AutoIncUp',
     'Handle AutoIncUp: check CanScroll, get step, send AddDelta'),

    ('LABEL_F9FCF5', 'AcRamEdit_ScrollUp',
     'Handle ScrollUp: check CanScroll, get step, send AddDelta'),

    ('LABEL_F9FD36', 'AcRamEdit_AutoIncDown',
     'Handle AutoIncDown: check CanScroll, negate step, send AddDelta'),

    ('LABEL_F9FD7C', 'AcRamEdit_ScrollDown',
     'Handle ScrollDown: check CanScroll, negate step, send AddDelta'),

    ('LABEL_F9FDC0', 'AcRamEdit_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_F9FDC4', 'AcRamEdit_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_F9FDC8', 'AcRamEdit_Default',
     'Default handler: forward to PsEditBoxProc'),

    ('LABEL_F9FDD1', 'AcRamEdit_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # RamEditCheck  (F9FDD7 - F9FE43)
    # Check handler for RAM edit: returns step sizes and dispatches audio.
    # ==================================================================
    ('LABEL_F9FE0D', 'RamEditCheck_JumpStart',
     'Start of jump table dispatch targets'),

    ('LABEL_F9FE43', 'RamEditCheck_NotHandled',
     'Return HL=0 (not handled)'),

    # ==================================================================
    # AcBitEditBoxProc  (F9FE4B - FA012A)
    # Bit-field edit box: toggles individual bits via addr+mask.
    # ==================================================================
    ('LABEL_F9FFA7', 'AcBitEdit_SetValue',
     'Handle SetValue/SetBit: get addr+mask and call MainBitPut'),

    ('LABEL_F9FFE1', 'AcBitEdit_ShowHide',
     'Handle Show/Hide: forward to PsEditBoxProc then call MainBitGet'),

    ('LABEL_FA001D', 'AcBitEdit_Assign',
     'Handle Assign (0x1C00024): compare addr+mask and apply bit value'),

    ('LABEL_FA007D', 'AcBitEdit_ScrollUp',
     'Handle ScrollUp: check CanScroll, toggle bit, send SetValue'),

    ('LABEL_FA00C0', 'AcBitEdit_ScrollUp_SetOne',
     'ScrollUp toggle: send SetValue=1 (set bit)'),

    ('LABEL_FA00CC', 'AcBitEdit_ScrollDown',
     'Handle ScrollDown: check CanScroll, toggle bit, send SetValue'),

    ('LABEL_FA010F', 'AcBitEdit_ScrollDown_SetZero',
     'ScrollDown toggle: send SetValue=0 (clear bit)'),

    ('LABEL_FA0119', 'AcBitEdit_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_FA011D', 'AcBitEdit_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA0121', 'AcBitEdit_Default',
     'Default handler: forward to PsEditBoxProc'),

    ('LABEL_FA012A', 'AcBitEdit_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # BitEditCheck  (FA0130 - FA0185)
    # Check handler for bit edit: returns addr/mask and dispatches audio.
    # ==================================================================
    ('LABEL_FA0175', 'BitEditCheck_GetAddr',
     'Return bit address (0x0276CE)'),

    ('LABEL_FA017C', 'BitEditCheck_GetMask',
     'Return bit mask (0x8000)'),

    ('LABEL_FA0183', 'BitEditCheck_NotHandled',
     'Return HL=0 (not handled)'),

    ('LABEL_FA0185', 'BitEditCheck_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # PsMenuBoxProc  (FA018C - FA0321)
    # Menu box base procedure: handles Paint, Confirm, GetText, HitTest.
    # ==================================================================
    ('LABEL_FA0253', 'PsMenuBox_GetText',
     'Handle GetText: clear output buffer byte'),

    ('LABEL_FA025B', 'PsMenuBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA0260', 'PsMenuBox_Paint',
     'Handle Paint: forward to VwBoxProc, draw edit switch'),

    ('LABEL_FA0278', 'PsMenuBox_Confirm',
     'Handle Confirm: render menu item text with font and alignment'),

    ('LABEL_FA02B7', 'PsMenuBox_Confirm_CopyText',
     'Confirm with text: Strcpy from caller buffer'),

    ('LABEL_FA02C4', 'PsMenuBox_Confirm_Render',
     'Render menu text with font, icon, and style'),

    ('LABEL_FA02EF', 'PsMenuBox_HitTest',
     'Handle HitTest (0x1E00053): check visibility and match menu item'),

    ('LABEL_FA0321', 'PsMenuBox_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcTitleMenuProc  (FA0325 - FA0720)
    # Title menu: wraps PsMenuBoxProc with icon rendering, multi-line
    # layout, and OK-button dispatch for mode/screen/window selection.
    # ==================================================================
    ('LABEL_FA0367', 'AcTitleMenu_Paint',
     'Handle Paint: forward to PsMenuBoxProc then send Confirm'),

    ('LABEL_FA0382', 'AcTitleMenu_Confirm',
     'Handle Confirm: render title with icon, font, and two-part layout'),

    ('LABEL_FA03DD', 'AcTitleMenu_Confirm_NoIcon',
     'No icon present: use small margin (4)'),

    ('LABEL_FA03DF', 'AcTitleMenu_Confirm_SetLeft',
     'Set left margin based on icon presence'),

    ('LABEL_FA0406', 'AcTitleMenu_Confirm_NoIconRight',
     'No icon on right side: use small margin (4)'),

    ('LABEL_FA0408', 'AcTitleMenu_Confirm_SetRight',
     'Set right margin based on icon presence'),

    ('LABEL_FA0478', 'AcTitleMenu_Confirm_SingleLine',
     'Single-line title: center text vertically'),

    ('LABEL_FA04BC', 'AcTitleMenu_Confirm_MultiLine',
     'Multi-line title: split and render top/bottom halves'),

    ('LABEL_FA0503', 'AcTitleMenu_Confirm_MultiAdjust',
     'Adjust multi-line title split position'),

    ('LABEL_FA0515', 'AcTitleMenu_Confirm_RenderBottom',
     'Render bottom half of multi-line title at 3/4 position'),

    ('LABEL_FA05A6', 'AcTitleMenu_Confirm_RenderTop',
     'Render top text line and draw icon if present'),

    ('LABEL_FA05D3', 'AcTitleMenu_Confirm_IconNoOrient',
     'Icon without orientation: use position from offset +0'),

    ('LABEL_FA05D9', 'AcTitleMenu_Confirm_DrawIcon',
     'Calculate icon center, draw bounding box, and render icon'),

    ('LABEL_FA063C', 'AcTitleMenu_OK',
     'Handle OK (0x1C00007): dispatch to mode/screen/window Init'),

    ('LABEL_FA0693', 'AcTitleMenu_OK_CheckMode',
     'Check if target is mode type (0x1600040)'),

    ('LABEL_FA06BD', 'AcTitleMenu_OK_CheckScreen',
     'Check if target is screen type (0x1600041)'),

    ('LABEL_FA06E4', 'AcTitleMenu_OK_CheckWindow',
     'Check if target is window type (0x1600042)'),

    ('LABEL_FA0709', 'AcTitleMenu_OK_Dispatch',
     'Dispatch: call 0xFA9660 to send Init/Close event'),

    ('LABEL_FA070D', 'AcTitleMenu_OK_Done',
     'Return HL=0 after OK handling'),

    ('LABEL_FA0711', 'AcTitleMenu_OK_Default',
     'OK but no match: forward to PsMenuBoxProc'),

    ('LABEL_FA071D', 'AcTitleMenu_DefaultTail',
     'Tail call to PsMenuBoxProc'),

    ('LABEL_FA0720', 'AcTitleMenu_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # VwMenuBoxProc  (FA0726 - FA09C8)
    # View menu box: renders menu items for view-level display.
    # ==================================================================
    ('LABEL_FA0747', 'VwMenuBox_Paint',
     'Handle Paint: forward to PsMenuBoxProc then send Confirm'),

    ('LABEL_FA075C', 'VwMenuBox_Confirm',
     'Handle Confirm: render view menu item with icon and two-part text'),

    ('LABEL_FA07B7', 'VwMenuBox_Confirm_NoIcon',
     'No icon: use small margin (4)'),

    ('LABEL_FA07B9', 'VwMenuBox_Confirm_SetLeft',
     'Set left margin based on icon presence'),

    ('LABEL_FA07E0', 'VwMenuBox_Confirm_NoIconRight',
     'No icon on right: use small margin (4)'),

    ('LABEL_FA07E2', 'VwMenuBox_Confirm_SetRight',
     'Set right margin based on icon presence'),

    ('LABEL_FA0850', 'VwMenuBox_Confirm_SingleLine',
     'Single-line menu item: center text vertically'),

    ('LABEL_FA0894', 'VwMenuBox_Confirm_MultiLine',
     'Multi-line menu item: split and render halves'),

    ('LABEL_FA08D7', 'VwMenuBox_Confirm_MultiAdjust',
     'Adjust multi-line split position based on text width'),

    ('LABEL_FA08E9', 'VwMenuBox_Confirm_RenderBottom',
     'Render bottom half at 3/4 position'),

    ('LABEL_FA0933', 'VwMenuBox_Confirm_RenderTop',
     'Render top half and draw icon if present'),

    ('LABEL_FA0960', 'VwMenuBox_Confirm_IconNoOrient',
     'Icon without orientation: use offset +0 position'),

    ('LABEL_FA0966', 'VwMenuBox_Confirm_DrawIcon',
     'Center and render icon within menu item box'),

    ('LABEL_FA09C6', 'VwMenuBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA09C8', 'VwMenuBox_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # PsEditSwBoxProc  (FA09CF - FA0AEC)
    # Edit switch box: manages edit switch state, hit testing, repaint.
    # ==================================================================
    ('LABEL_FA0A0C', 'PsEditSwBox_GetText',
     'Handle GetText: clear output buffer'),

    ('LABEL_FA0A15', 'PsEditSwBox_Paint',
     'Handle Paint: forward to VwBoxProc, draw edit switch indicator'),

    ('LABEL_FA0A3F', 'PsEditSwBox_Confirm',
     'Handle Confirm: call internal render helper'),

    ('LABEL_FA0A4E', 'PsEditSwBox_HitTest',
     'Handle HitTest: check visibility and match switch ID'),

    ('LABEL_FA0A83', 'PsEditSwBox_Repaint',
     'Handle Repaint (0x1E0009C): forward to VwBoxProc, update display'),

    ('LABEL_FA0AA4', 'PsEditSwBox_Repaint_UpdateBounds',
     'Update edit switch bounds and redraw region'),

    ('LABEL_FA0ADB', 'PsEditSwBox_Repaint_ClampRight',
     'Clamp right boundary to 0x13F (319)'),

    ('LABEL_FA0AE0', 'PsEditSwBox_Repaint_Render',
     'Render updated edit switch region'),

    ('LABEL_FA0AEA', 'PsEditSwBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA0AEC', 'PsEditSwBox_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # PsToggleBoxProc  (FA1554 - FA17E3)
    # Toggle box base procedure: handles Confirm, SetValue, GetValue,
    # Toggle, HitTest, and Repaint for checkbox-style widgets.
    # ==================================================================
    ('LABEL_FA1601', 'PsToggleBox_Paint_SendConfirm',
     'After Paint: read toggle value and send Confirm event'),

    ('LABEL_FA1613', 'PsToggleBox_Confirm',
     'Handle Confirm: store value, calculate center, draw toggle state'),

    ('LABEL_FA163F', 'PsToggleBox_Confirm_Layout',
     'Get box bounds, calculate center point for toggle rendering'),

    ('LABEL_FA1672', 'PsToggleBox_Confirm_OnLarge',
     'Toggle ON with large style: color=0xC3'),

    ('LABEL_FA1678', 'PsToggleBox_Confirm_DrawOn',
     'Draw ON-state toggle: filled box and render ON text'),

    ('LABEL_FA1694', 'PsToggleBox_Confirm_DrawOff',
     'Toggle is OFF: draw empty box and render OFF text'),

    ('LABEL_FA16A1', 'PsToggleBox_Confirm_OffLarge',
     'Toggle OFF with large style: color=0xC1'),

    ('LABEL_FA16A6', 'PsToggleBox_Confirm_DrawOffBox',
     'Draw OFF-state toggle box'),

    ('LABEL_FA16C0', 'PsToggleBox_Confirm_RenderText',
     'Common: call text renderer with toggle label'),

    ('LABEL_FA16C7', 'PsToggleBox_HitTest',
     'Handle HitTest: check visibility and match toggle switch ID'),

    ('LABEL_FA1700', 'PsToggleBox_Toggle',
     'Handle Toggle (0x1E0006C): flip value and send Confirm'),

    ('LABEL_FA1722', 'PsToggleBox_Toggle_SetOn',
     'Value was 0: send Confirm with value=1 (set ON)'),

    ('LABEL_FA172C', 'PsToggleBox_Toggle_Dispatch',
     'Dispatch Toggle result via 0xFA9660'),

    ('LABEL_FA1735', 'PsToggleBox_SetValue',
     'Handle SetValue (0x1E0003B): set toggle and send Confirm'),

    ('LABEL_FA1752', 'PsToggleBox_SetValue_Dispatch',
     'Dispatch SetValue: call 0xFA9660'),

    ('LABEL_FA1758', 'PsToggleBox_GetValue',
     'Handle GetValue (0x1E0006B): return current toggle value'),

    ('LABEL_FA175F', 'PsToggleBox_GetValue_Read',
     'Read toggle value from widget data and return'),

    ('LABEL_FA1768', 'PsToggleBox_Repaint',
     'Handle Repaint (0x1E0009C): repaint toggle, check visibility'),

    ('LABEL_FA178D', 'PsToggleBox_Repaint_UpdateBounds',
     'Update toggle bounds and redraw region'),

    ('LABEL_FA17C6', 'PsToggleBox_Repaint_ClampRight',
     'Clamp right boundary to 0x13F (319)'),

    ('LABEL_FA17CB', 'PsToggleBox_Repaint_Render',
     'Render updated toggle region'),

    ('LABEL_FA17D5', 'PsToggleBox_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA17D9', 'PsToggleBox_Default',
     'Default handler: forward to 0xFA5995 (VwBoxProc)'),

    ('LABEL_FA17E3', 'PsToggleBox_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # AcFuncToggleProc  (FA17EF - FA1856)
    # Function toggle: wraps PsToggleBoxProc with OK-button callback.
    # ==================================================================
    ('LABEL_FA1809', 'AcFuncToggle_OK',
     'Handle OK: check HitTest, toggle value, send SetValue to parent'),

    ('LABEL_FA184B', 'AcFuncToggle_Default',
     'Default: forward to PsToggleBoxProc'),

    ('LABEL_FA1853', 'AcFuncToggle_DefaultTail',
     'Tail call to PsToggleBoxProc'),

    ('LABEL_FA1856', 'AcFuncToggle_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # AcIndexToggleProc  (FA185B - FA19C8)
    # Index toggle: manages toggle with index tracking and Release events.
    # ==================================================================
    ('LABEL_FA189D', 'AcIndexToggle_OK',
     'Handle OK: check HitTest, send Release for old, SetValue for new'),

    ('LABEL_FA18E1', 'AcIndexToggle_OK_SetValue',
     'Send SetValue=1 and compute cell index for event dispatch'),

    ('LABEL_FA1910', 'AcIndexToggle_OK_Default',
     'OK no hit: forward to PsToggleBoxProc'),

    ('LABEL_FA1918', 'AcIndexToggle_DefaultTail',
     'Tail call to PsToggleBoxProc'),

    ('LABEL_FA191E', 'AcIndexToggle_Release',
     'Handle Release: check index match and deselect toggle'),

    ('LABEL_FA194F', 'AcIndexToggle_Select',
     'Handle Select (0x1C0002A): check cell match and send Release/SetValue'),

    ('LABEL_FA199F', 'AcIndexToggle_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_FA19A3', 'AcIndexToggle_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA19A7', 'AcIndexToggle_GetIndex',
     'Handle GetIndex (0x1E00051): return current toggle index'),

    ('LABEL_FA19B5', 'AcIndexToggle_CanScrollEvt',
     'Handle CanScrollEvt: compare index and return match flag'),

    ('LABEL_FA19C8', 'AcIndexToggle_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # PsWideToggleProc  (FA19CD - FA1A9C)
    # Wide toggle: spans multiple edit switch positions.
    # ==================================================================
    ('LABEL_FA19EE', 'PsWideToggle_GetBounds',
     'Handle GetBounds (0x1E00052): calculate multi-position bounds'),

    ('LABEL_FA1A1E', 'PsWideToggle_GetBounds_CalcPts',
     'Calculate edit switch points for both positions'),

    ('LABEL_FA1A5C', 'PsWideToggle_ReturnZero',
     'Return HL=0'),

    ('LABEL_FA1A60', 'PsWideToggle_HitTest',
     'Handle HitTest: compare both switch ranges'),

    ('LABEL_FA1A7B', 'PsWideToggle_HitTest_SwapOrder',
     'Swap min/max for proper range comparison'),

    ('LABEL_FA1A80', 'PsWideToggle_HitTest_Check',
     'Check if value is within toggle range'),

    ('LABEL_FA1A9C', 'PsWideToggle_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # PsInvisibleBoxProc  (FA1ABF - FA1AC0)
    # Minimal invisible box: handles GetText/Confirm/Paint only.
    # ==================================================================
    ('LABEL_FA1ABD', 'PsInvisibleBox_GetText',
     'Handle GetText: clear output buffer'),

    ('LABEL_FA1AC0', 'PsInvisibleBox_ReturnZero',
     'Return HL=0 (handled)'),

    # ==================================================================
    # IvPageControlProc  (FA1AC5 - FA1B76)
    # Page control: handles page changes and forwards to child views.
    # ==================================================================
    ('LABEL_FA1AF5', 'IvPageControl_Paint',
     'Handle Paint: forward to PsInvisibleBoxProc, send Confirm'),

    ('LABEL_FA1B0C', 'IvPageControl_GetText',
     'Handle GetText: copy page name string'),

    ('LABEL_FA1B1E', 'IvPageControl_PageChange',
     'Handle PageChange (0x1C0001E): close old page, init new page'),

    ('LABEL_FA1B4E', 'IvPageControl_PageChange_Init',
     'Forward PageChange then send Init to new child page'),

    ('LABEL_FA1B70', 'IvPageControl_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_FA1B74', 'IvPageControl_ReturnZero',
     'Return HL=0'),

    ('LABEL_FA1B76', 'IvPageControl_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # IvMainEditSwProc  (FA1B7C - FA1C37)
    # Main edit switch: dispatches button events to child views.
    # ==================================================================
    ('LABEL_FA1BCB', 'IvMainEditSw_GetText',
     'Handle GetText: copy edit switch name string'),

    ('LABEL_FA1BDD', 'IvMainEditSw_BtnOK',
     'Handle Button OK (0x1C0002B): send OK to child view'),

    ('LABEL_FA1BF0', 'IvMainEditSw_BtnCancel',
     'Handle Button Cancel (0x1C00032): send Cancel to child view'),

    ('LABEL_FA1C03', 'IvMainEditSw_BtnDelete',
     'Handle Button Delete (0x1C00033): send Delete to child view'),

    ('LABEL_FA1C16', 'IvMainEditSw_BtnRecord',
     'Handle Button Record (0x1C00034): send Record to child view'),

    ('LABEL_FA1C27', 'IvMainEditSw_DispatchChild',
     'Common: dispatch button event to child view via 0xFA4A63'),

    ('LABEL_FA1C2B', 'IvMainEditSw_ReturnZero',
     'Return HL=0'),

    ('LABEL_FA1C2F', 'IvMainEditSw_Default',
     'Default handler: forward to PsInvisibleBoxProc'),

    ('LABEL_FA1C37', 'IvMainEditSw_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # IvExitProc  (FA1C3C - FA1C8C)
    # Exit button procedure: handles HitTest and Confirm.
    # ==================================================================
    ('LABEL_FA1C5D', 'IvExit_Paint',
     'Handle Paint: forward to PsInvisibleBoxProc, send Confirm'),

    ('LABEL_FA1C71', 'IvExit_GetText',
     'Handle GetText: copy exit button label'),

    ('LABEL_FA1C7E', 'IvExit_ReturnZero',
     'Return HL=0'),

    ('LABEL_FA1C82', 'IvExit_HitTest',
     'Handle HitTest: check exit button ID (0xF)'),

    ('LABEL_FA1C8C', 'IvExit_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # IvExitModeProc  (FA1C8E - FA1D40)
    # Exit mode: wraps IvExitProc with mode-level cleanup.
    # ==================================================================
    ('LABEL_FA1CBA', 'IvExitMode_GetText',
     'Handle GetText: copy exit mode label'),

    ('LABEL_FA1CCE', 'IvExitMode_OK',
     'Handle OK: check HitTest, close mode or start save workflow'),

    ('LABEL_FA1D12', 'IvExitMode_OK_SaveCheck',
     'Save check: invoke save workflow before exiting mode'),

    ('LABEL_FA1D34', 'IvExitMode_OK_Forward',
     'Forward to IvExitProc'),

    ('LABEL_FA1D3D', 'IvExitMode_DefaultTail',
     'Tail call to IvExitProc'),

    ('LABEL_FA1D40', 'IvExitMode_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # IvExitScreenProc  (FA1D43 - FA1DF4)
    # Exit screen: wraps IvExitProc with screen-level cleanup.
    # ==================================================================
    ('LABEL_FA1D71', 'IvExitScreen_GetText',
     'Handle GetText: copy exit screen label'),

    ('LABEL_FA1D85', 'IvExitScreen_OK',
     'Handle OK: check HitTest, close screen or start save workflow'),

    ('LABEL_FA1DC6', 'IvExitScreen_OK_SaveCheck',
     'Save check: invoke save workflow before exiting screen'),

    ('LABEL_FA1DE8', 'IvExitScreen_OK_Forward',
     'Forward to IvExitProc'),

    ('LABEL_FA1DF1', 'IvExitScreen_DefaultTail',
     'Tail call to IvExitProc'),

    ('LABEL_FA1DF4', 'IvExitScreen_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # IvExitWindowProc  (FA1DF7 - FA1EAA)
    # Exit window: wraps IvExitProc with window-level cleanup.
    # ==================================================================
    ('LABEL_FA1E1F', 'IvExitWindow_GetText',
     'Handle GetText: copy exit window label'),

    ('LABEL_FA1E33', 'IvExitWindow_OK',
     'Handle OK: check HitTest, close window or start save workflow'),

    ('LABEL_FA1E7D', 'IvExitWindow_OK_SaveCheck',
     'Save check: invoke save workflow before exiting window'),

    ('LABEL_FA1E9F', 'IvExitWindow_OK_Forward',
     'Forward to IvExitProc'),

    ('LABEL_FA1EA7', 'IvExitWindow_DefaultTail',
     'Tail call to IvExitProc'),

    ('LABEL_FA1EAA', 'IvExitWindow_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # IvFixWinProc  (FA1EAD - FA1F29)
    # Fixed window: handles Init events for fixed window types.
    # ==================================================================
    ('LABEL_FA1ED9', 'IvFixWin_Paint',
     'Handle Paint: forward to PsInvisibleBoxProc, send Confirm with string'),

    ('LABEL_FA1EF2', 'IvFixWin_Init',
     'Handle Init: forward, then dispatch Init to child for types 0/3/5'),

    ('LABEL_FA1F14', 'IvFixWin_Init_DispatchChild',
     'Send Init event to child view'),

    ('LABEL_FA1F23', 'IvFixWin_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_FA1F27', 'IvFixWin_ReturnZero',
     'Return HL=0'),

    ('LABEL_FA1F29', 'IvFixWin_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # IvNamingProc  (FA1F2C - FA1FC3)
    # Naming window: handles Init/Close for text naming dialogs.
    # ==================================================================
    ('LABEL_FA1F5D', 'IvNaming_Paint',
     'Handle Paint: forward to PsInvisibleBoxProc, send Confirm with string'),

    ('LABEL_FA1F77', 'IvNaming_Init',
     'Handle Init: forward, send SetCharLimit to naming engine, send Init'),

    ('LABEL_FA1FA3', 'IvNaming_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_FA1FA9', 'IvNaming_Close',
     'Handle Close: send Close to naming engine, forward to PsInvisibleBoxProc'),

    ('LABEL_FA1FC1', 'IvNaming_ReturnZero',
     'Return HL=0'),

    ('LABEL_FA1FC3', 'IvNaming_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # NamingCheck  (FA1FCE - FA2006)
    # Check handler for naming: returns string length and naming text.
    # ==================================================================
    ('LABEL_FA1FF9', 'NamingCheck_NotHandled',
     'Return HL=0 (not handled)'),

    ('LABEL_FA1FFD', 'NamingCheck_GetStrLen',
     'Handle GetStrLen: compute string length via LABEL_FF0FA0'),

    ('LABEL_FA2006', 'NamingCheck_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # IvTrackSwitchProc  (FA200A - FA2068)
    # Track switch: handles Init/Paint for track selection.
    # ==================================================================
    ('LABEL_FA2033', 'IvTrackSwitch_Paint',
     'Handle Paint: forward, send Confirm with track switch string'),

    ('LABEL_FA204C', 'IvTrackSwitch_Init',
     'Handle Init: forward, then dispatch Init event to track 0x20'),

    ('LABEL_FA2062', 'IvTrackSwitch_Dispatch',
     'Common dispatch: call 0xFA9660'),

    ('LABEL_FA2068', 'IvTrackSwitch_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # IvCatchEventProc  (FA206A - FA2109)
    # Catch-all event handler: routes events to registered callback table.
    # ==================================================================
    ('LABEL_FA2094', 'IvCatchEvent_Lookup',
     'Look up callback table entry for event target'),

    ('LABEL_FA20ED', 'IvCatchEvent_NoCallback',
     'No callback match: forward event to child view'),

    ('LABEL_FA20FD', 'IvCatchEvent_Forward',
     'Forward non-local event to PsInvisibleBoxProc'),

    ('LABEL_FA2109', 'IvCatchEvent_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # ViewableProc  (FA5A28 - FA5E37)
    # Viewable base class: routes events to owner/child hierarchy,
    # handles GetInstance, GetParent, GetOwner, GetChild, GetClass,
    # SetVisible, Dispatch, MatchClass, GetBounds, and painting.
    # ==================================================================
    ('LABEL_FA5AA3', 'Viewable_GetClassProc',
     'Handle GetClassProc (0x1E00000): look up class procedure from table'),

    ('LABEL_FA5ABE', 'Viewable_InitClose',
     'Handle Init/Close: dispatch to owner, then to child'),

    ('LABEL_FA5AD7', 'Viewable_InitClose_ToChild',
     'Dispatch Init/Close to child view'),

    ('LABEL_FA5B1D', 'Viewable_Show_DispatchChild',
     'Show: dispatch to child after visibility check'),

    ('LABEL_FA5B61', 'Viewable_Show_DispatchTail',
     'Common tail: dispatch event via 0xFA9660'),

    ('LABEL_FA5B65', 'Viewable_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA5B6A', 'Viewable_PostEvent',
     'Handle PostEvent (0x1C00037): compare target and dispatch'),

    ('LABEL_FA5B80', 'Viewable_PostEvent_ToOwner',
     'PostEvent not for self: dispatch to owner'),

    ('LABEL_FA5B9E', 'Viewable_PostEvent_ToChild',
     'PostEvent: try dispatching to child'),

    ('LABEL_FA5BBE', 'Viewable_GetName',
     'Handle GetName (0x1E00015): look up name from class table'),

    ('LABEL_FA5BC5', 'Viewable_SetName',
     'Handle SetName (0x1E00016): allocate buffer and copy name'),

    ('LABEL_FA5C0A', 'Viewable_SetName_Copy',
     'Copy name string into allocated buffer'),

    ('LABEL_FA5C25', 'Viewable_GetInstance',
     'Handle GetInstance (0x1E0000F): return view instance data'),

    ('LABEL_FA5C2D', 'Viewable_GetParent',
     'Handle GetParent (0x1E00036): return parent view'),

    ('LABEL_FA5C35', 'Viewable_GetOwner',
     'Handle GetOwner (0x1E00037): return owner view'),

    ('LABEL_FA5C3D', 'Viewable_GetChild',
     'Handle GetChild (0x1E00038): return first child view'),

    ('LABEL_FA5C45', 'Viewable_GetClass',
     'Handle GetClass (0x1E00039): return class identifier'),

    ('LABEL_FA5C4D', 'Viewable_SetVisible',
     'Handle SetVisible (0x1E0009C): set visibility flag'),

    ('LABEL_FA5C58', 'Viewable_Dispatch',
     'Handle Dispatch (0x1E00024): check type, dispatch to owner/child'),

    ('LABEL_FA5C88', 'Viewable_Dispatch_ToChild',
     'Dispatch not handled by owner: try child'),

    ('LABEL_FA5CAA', 'Viewable_MatchClass',
     'Handle MatchClass (0x1E000B5): compare class type'),

    ('LABEL_FA5CBA', 'Viewable_MatchClass_Found',
     'Class match found: return 1'),

    ('LABEL_FA5CBF', 'Viewable_MatchClass_ToOwner',
     'No match: try owner hierarchy'),

    ('LABEL_FA5CDD', 'Viewable_MatchClass_ToChild',
     'No match in owner: try child hierarchy'),

    ('LABEL_FA5CFF', 'Viewable_GetBoundsX',
     'Handle GetBounds(x) (0x1E0004F): calculate horizontal bounds'),

    ('LABEL_FA5D38', 'Viewable_GetBoundsX_Right',
     'GetBounds(x) for right-side position (0x13F)'),

    ('LABEL_FA5D5D', 'Viewable_GetBoundsY',
     'Handle GetBounds(y) (0x1E00052): calculate vertical bounds'),

    ('LABEL_FA5D94', 'Viewable_GetBoundsY_Right',
     'GetBounds(y) for right-side position (0x13F)'),

    ('LABEL_FA5DB3', 'Viewable_GetBoundsY_Bottom',
     'GetBounds(y) for bottom position (0xEF)'),

    ('LABEL_FA5DD6', 'Viewable_DefaultDispatch',
     'Default: check ObjectProc range, then dispatch to owner/child'),

    ('LABEL_FA5DFB', 'Viewable_Default_ToOwner',
     'Default dispatch: try owner first'),

    ('LABEL_FA5E18', 'Viewable_Default_ToChild',
     'Default dispatch: try child if owner didn\'t handle'),

    ('LABEL_FA5E37', 'Viewable_Return',
     'Epilogue: pop xiz, restore stack, return'),

    # ==================================================================
    # ViewIDProc  (FA8280 - FA8602)
    # View ID procedure: enumerates, selects, and navigates views.
    # ==================================================================
    ('LABEL_FA8327', 'ViewID_EnumFill',
     'Handle EnumFill/EnumOpen/EnumCount: build view ID list'),

    ('LABEL_FA832F', 'ViewID_EnumFill_OuterLoop',
     'Outer loop: iterate view class types (0-0xFF)'),

    ('LABEL_FA8343', 'ViewID_EnumFill_InnerLoop',
     'Inner loop: enumerate view instances within a class'),

    ('LABEL_FA8371', 'ViewID_EnumFill_InnerNext',
     'Advance inner instance counter'),

    ('LABEL_FA8381', 'ViewID_EnumFill_OuterNext',
     'Advance outer class counter'),

    ('LABEL_FA8391', 'ViewID_EventSwitch',
     'Event switch: dispatch by event code after enum'),

    ('LABEL_FA83ED', 'ViewID_Select_Lookup',
     'Select (EnumResult): look up and display selected view name'),

    ('LABEL_FA8421', 'ViewID_Select_NoName',
     'View has no name: look up parent class name instead'),

    ('LABEL_FA846E', 'ViewID_EnumCount',
     'Handle EnumCount: return count + 1'),

    ('LABEL_FA8476', 'ViewID_GetInfoStr',
     'Handle GetInfoStr (0x1E00028): format view info string'),

    ('LABEL_FA84A2', 'ViewID_GetCurrent',
     'Handle GetCurrent/GetNext: read current view, display name'),

    ('LABEL_FA8503', 'ViewID_GetCurrent_NoName',
     'Current view has no name: look up parent class name'),

    ('LABEL_FA8542', 'ViewID_GetCurrent_None',
     'No current view: display empty string'),

    ('LABEL_FA854F', 'ViewID_StrCpy',
     'Common tail: Strcpy formatted string'),

    ('LABEL_FA8555', 'ViewID_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA855A', 'ViewID_EnumOpen',
     'Handle EnumOpen: scan views to find matching name'),

    ('LABEL_FA857A', 'ViewID_EnumOpen_ScanLoop',
     'Scan loop: compare view names to find match'),

    ('LABEL_FA85C2', 'ViewID_EnumOpen_ScanNext',
     'Advance to next view in scan'),

    ('LABEL_FA85CF', 'ViewID_EnumOpen_NotFound',
     'View not found: check if result is meaningful'),

    ('LABEL_FA85D6', 'ViewID_EnumOpen_Store',
     'Store matched view ID into cursor'),

    ('LABEL_FA85EE', 'ViewID_EnumOpen_Return',
     'Return scan result'),

    ('LABEL_FA85F3', 'ViewID_Default',
     'Default: forward to LABEL_FA9304 (common ID proc)'),

    ('LABEL_FA8602', 'ViewID_Return',
     'Epilogue: pop xiz, restore frame, return'),

    ('LABEL_FA8609', 'ViewID_Epilogue',
     'Trailing label after ViewIDProc (boundary marker)'),

    # ==================================================================
    # ScreenIDProc  (FA8609 - FA8992)
    # Screen ID procedure: enumerates, selects, and navigates screens.
    # Structurally parallel to ViewIDProc but filters by screen type.
    # ==================================================================
    ('LABEL_FA8634', 'ScreenID_EnumFill',
     'Handle EnumFill/EnumOpen/EnumCount: build screen ID list'),

    ('LABEL_FA863C', 'ScreenID_EnumFill_OuterLoop',
     'Outer loop: iterate class types (0-0xFF)'),

    ('LABEL_FA8650', 'ScreenID_EnumFill_InnerLoop',
     'Inner loop: enumerate screen instances, filter by type 0x1600033'),

    ('LABEL_FA8699', 'ScreenID_EnumFill_InnerNext',
     'Advance inner instance counter'),

    ('LABEL_FA86A9', 'ScreenID_EnumFill_OuterNext',
     'Advance outer class counter'),

    ('LABEL_FA86B9', 'ScreenID_EventSwitch',
     'Event switch: dispatch by event code after enum'),

    ('LABEL_FA8715', 'ScreenID_Select_Lookup',
     'Select: look up and display selected screen name'),

    ('LABEL_FA8749', 'ScreenID_Select_NoName',
     'Screen has no name: look up parent class name'),

    ('LABEL_FA87A2', 'ScreenID_EnumCount',
     'Handle EnumCount: return count + 1'),

    ('LABEL_FA87AA', 'ScreenID_GetCurrent',
     'Handle GetCurrent/GetNext: read current screen, display name'),

    ('LABEL_FA87F6', 'ScreenID_GetCurrent_NoName',
     'Current screen has no name: look up parent class name'),

    ('LABEL_FA8834', 'ScreenID_GetCurrent_None',
     'No current screen: display empty string'),

    ('LABEL_FA8847', 'ScreenID_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA884C', 'ScreenID_EnumOpen',
     'Handle EnumOpen: scan screens to find matching name'),

    ('LABEL_FA886D', 'ScreenID_EnumOpen_ScanLoop',
     'Scan loop: compare screen names, display with class name'),

    ('LABEL_FA88A0', 'ScreenID_EnumOpen_ScanNoName',
     'Screen in scan has no name: look up parent class'),

    ('LABEL_FA88F0', 'ScreenID_EnumOpen_Compare',
     'Compare scanned name with target name'),

    ('LABEL_FA8921', 'ScreenID_EnumOpen_ScanNext',
     'Advance to next screen in scan'),

    ('LABEL_FA892F', 'ScreenID_EnumOpen_NotFound',
     'Screen not found: try matching empty-name marker'),

    ('LABEL_FA895F', 'ScreenID_EnumOpen_CheckEmpty',
     'Check if result is meaningful after scan'),

    ('LABEL_FA8966', 'ScreenID_EnumOpen_Store',
     'Store matched screen ID into cursor'),

    ('LABEL_FA897E', 'ScreenID_EnumOpen_Return',
     'Return scan result'),

    ('LABEL_FA8983', 'ScreenID_Default',
     'Default: forward to LABEL_FA9304 (common ID proc)'),

    ('LABEL_FA8992', 'ScreenID_Return',
     'Epilogue: pop xiz, restore frame, return'),

    ('LABEL_FA8999', 'ScreenID_Epilogue',
     'Trailing label after ScreenIDProc (boundary marker)'),

    # ==================================================================
    # WindowIDProc  (FA8999 - FA8D22)
    # Window ID procedure: enumerates, selects, and navigates windows.
    # Structurally parallel to ViewIDProc but filters by window type.
    # ==================================================================
    ('LABEL_FA89C4', 'WindowID_EnumFill',
     'Handle EnumFill/EnumOpen/EnumCount: build window ID list'),

    ('LABEL_FA89CC', 'WindowID_EnumFill_OuterLoop',
     'Outer loop: iterate class types (0-0xFF)'),

    ('LABEL_FA89E0', 'WindowID_EnumFill_InnerLoop',
     'Inner loop: enumerate window instances, filter by type 0x1600035'),

    ('LABEL_FA8A29', 'WindowID_EnumFill_InnerNext',
     'Advance inner instance counter'),

    ('LABEL_FA8A39', 'WindowID_EnumFill_OuterNext',
     'Advance outer class counter'),

    ('LABEL_FA8A49', 'WindowID_EventSwitch',
     'Event switch: dispatch by event code after enum'),

    ('LABEL_FA8AA5', 'WindowID_Select_Lookup',
     'Select: look up and display selected window name'),

    ('LABEL_FA8AD9', 'WindowID_Select_NoName',
     'Window has no name: look up parent class name'),

    ('LABEL_FA8B32', 'WindowID_EnumCount',
     'Handle EnumCount: return count + 1'),

    ('LABEL_FA8B3A', 'WindowID_GetCurrent',
     'Handle GetCurrent/GetNext: read current window, display name'),

    ('LABEL_FA8B86', 'WindowID_GetCurrent_NoName',
     'Current window has no name: look up parent class name'),

    ('LABEL_FA8BC4', 'WindowID_GetCurrent_None',
     'No current window: display empty string'),

    ('LABEL_FA8BD7', 'WindowID_ReturnZero',
     'Return HL=0 (handled)'),

    ('LABEL_FA8BDC', 'WindowID_EnumOpen',
     'Handle EnumOpen: scan windows to find matching name'),

    ('LABEL_FA8BFD', 'WindowID_EnumOpen_ScanLoop',
     'Scan loop: compare window names, display with class name'),

    ('LABEL_FA8C30', 'WindowID_EnumOpen_ScanNoName',
     'Window in scan has no name: look up parent class'),

    ('LABEL_FA8C80', 'WindowID_EnumOpen_Compare',
     'Compare scanned name with target name'),

    ('LABEL_FA8CB1', 'WindowID_EnumOpen_ScanNext',
     'Advance to next window in scan'),

    ('LABEL_FA8CBF', 'WindowID_EnumOpen_NotFound',
     'Window not found: try matching empty-name marker'),

    ('LABEL_FA8CEF', 'WindowID_EnumOpen_CheckEmpty',
     'Check if result is meaningful after scan'),

    ('LABEL_FA8CF6', 'WindowID_EnumOpen_Store',
     'Store matched window ID into cursor'),

    ('LABEL_FA8D0E', 'WindowID_EnumOpen_Return',
     'Return scan result'),

    ('LABEL_FA8D13', 'WindowID_Default',
     'Default: forward to LABEL_FA9304 (common ID proc)'),

    ('LABEL_FA8D22', 'WindowID_Return',
     'Epilogue: pop xiz, restore frame, return'),

    ('LABEL_FA8D29', 'WindowID_Epilogue',
     'Trailing label after WindowIDProc (boundary marker)'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

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

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
