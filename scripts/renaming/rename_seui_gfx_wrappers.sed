# Lane seui 2026-09-25: the 17 ScreenData-interpreter wrappers in
# audio/sound_editor_ui.s were named SeMenu_NameEditor_* but never touch the
# name editor.  Evidence: scripts/lanes/seui/se_gfx_wrappers_probe.py.
# Longest names first; \b keeps _HandleInput from matching _HandleInput_Data.
s/\bSeMenu_NameEditor_HandleInput_Data\b/SeGfx_StaticOp00_FromBuf/g
s/\bSeMenu_NameEditor_HandleInput\b/SeGfx_DrawBoundRecord/g
s/\bSeMenu_NameEditor_SelectCharSet_Data\b/SeGfx_StaticOp15_FromBuf/g
s/\bSeMenu_NameEditor_SelectCharSet\b/SeGfx_StaticOp0E/g
s/\bSeMenu_NameEditor_MoveCursor_Data\b/SeGfx_StaticOp06_Text/g
s/\bSeMenu_NameEditor_MoveCursor\b/SeGfx_StaticOp05_FromBuf/g
s/\bSeMenu_NameEditor_ChangeCase_Data\b/SeGfx_StaticOp09_FromBuf/g
s/\bSeMenu_NameEditor_ChangeCase\b/SeGfx_StaticOp07_Text/g
s/\bSeMenu_NameEditor_Cancel_Data\b/SeGfx_BoundOp02/g
s/\bSeMenu_NameEditor_Cancel\b/SeGfx_BoundOp00/g
s/\bSeMenu_NameEditor_Redraw_Data\b/SeGfx_BoundOp06/g
s/\bSeMenu_NameEditor_Redraw\b/SeGfx_BoundOp03/g
s/\bSeMenu_NameEditor_InsertChar\b/SeGfx_StaticOp02_FromBuf/g
s/\bSeMenu_NameEditor_DeleteChar\b/SeGfx_StaticOp03_BlitAtCell/g
s/\bSeMenu_NameEditor_Complete\b/SeGfx_StaticOp1B_FromBuf/g
s/\bSeMenu_NameEditor_Setup\b/SeGfx_DrawStaticList/g
s/\bSeMenu_NameEditor_Draw\b/SeGfx_DrawBoundList/g
