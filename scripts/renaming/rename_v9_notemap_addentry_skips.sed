# v9 audio/note_voice_mapping.s: NoteMap_AddEntry's Skip labels ran one behind v10's (and v7's) at the same
# addresses (v9 Skip = v10 Skip2 ... v9 Skip8 = v10 Skip9), because v9's first Skip site was still bytes.
# Descending order, so each line is renamed once.
s/\bNoteMap_AddEntry_Skip8\b/NoteMap_AddEntry_Skip9/g
s/\bNoteMap_AddEntry_Skip7\b/NoteMap_AddEntry_Skip8/g
s/\bNoteMap_AddEntry_Skip6\b/NoteMap_AddEntry_Skip7/g
s/\bNoteMap_AddEntry_Skip5\b/NoteMap_AddEntry_Skip6/g
s/\bNoteMap_AddEntry_Skip4\b/NoteMap_AddEntry_Skip5/g
s/\bNoteMap_AddEntry_Skip3\b/NoteMap_AddEntry_Skip4/g
s/\bNoteMap_AddEntry_Skip2\b/NoteMap_AddEntry_Skip3/g
s/\bNoteMap_AddEntry_Skip\b/NoteMap_AddEntry_Skip2/g
