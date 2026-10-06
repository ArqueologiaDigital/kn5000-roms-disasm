# Control-panel button changes -> action lists (scripts/converters/panel_button_actions_retype.py).  The dispatcher
# and its tables were Encoder_* / FileIO_* by guess; FileIO_BytecodeData is the 16-deep panel event queue's post.
s/\bFileIO_BytecodeData\b/PanelEvent_Post/g
s/\bEncoder_PrepareCallback_PtrTable_2\b/PanelButton_HelpModeActionLists/g
s/\bEncoder_PrepareCallback_PtrTable\b/PanelButton_ActionLists/g
s/\bEncoder_PrepareCallback\b/PanelButton_DispatchChange/g
s/\bEncoder_ResolveCallbackAddr\b/PanelButton_DispatchChange_Frame/g
s/\bFileIO_ProcessMaskAndShift\b/PanelButton_DispatchChange_Action/g
s/\bFileIO_AudioControlStart\b/PanelButton_DispatchChange_ShiftRight/g
s/\bFileIO_ShiftLeftLow\b/PanelButton_DispatchChange_ShiftNewLeft/g
s/\bFileIO_ShiftDone\b/PanelButton_DispatchChange_Shifted/g
s/\bFileIO_ShiftD\b/PanelButton_DispatchChange_ShiftNewRight/g
s/\bFileIO_CallbackHandler\b/PanelButton_DispatchChange_Call/g
s/\bFileIO_AdvancePointer\b/PanelButton_DispatchChange_Next/g
s/\bFileIO_MainLoop\b/PanelButton_DispatchChange_Loop/g
