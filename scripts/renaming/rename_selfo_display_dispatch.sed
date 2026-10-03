# The display dispatchers SeAmpLfo1TitleFunc_DisplayData / SeFilLfo1TitleFunc_DisplayData jump to (load a
# GUI_DisplayStructData table, call entry BC).  v10/v9 had them as numbered local labels of
# Scoop_SoundEditorData; v7 reached them through positional aliases.
s/\bScoop_SoundEditorData_Join52\b/SeAmpLfo1_DisplayDispatch/g
s/\bScoop_SoundEditorData_Join62\b/SeFilLfo1_DisplayDispatch/g
