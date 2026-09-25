
; MIDI/Reverb/Presets screen widgets (267 widgets, 17766 bytes)
; Source: maincpu/ui_widgets/naka_midi_reverb.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_midi_reverb
; How these pieces were identified
; (scripts/analysis/nakarest_objtab_map.py): every RegObjTabl
; registration in the v10, v9 and v7 sources (the macro, and v7's
; written-out form) was parsed, each registered table was read out of
; the original ROM dump, and every address those tables point at is an
; object START: a Viewable table points at NAKA widget records, a
; ResName table (slot = Viewable slot + 0x300) at the name string of
; each element, an ApFunction / Function / MainFunction table (slot
; 0x1xx) at procedures and its slot + 0x300 twin at their names. Each
; piece below starts at one such run of objects or at a label that
; already existed. A widget record begins with the Viewable fields (the
; firmware's own names): +0 class (class id), +4 super, +6 sub, +8 next,
; +10 prev (element indices of the same table, 0xffff = none -- parent,
; first child, next and previous sibling, checked against each other for
; every table: the Links result per table), +12 flag, +14 rect (x1, y1,
; x2, y2). Name strings are NUL-terminated and 0xff-padded to even
; length. Strings a record's `X` field (str, title, caption, name)
; points at are indexed too, so the bytes after a record are accounted
; for (in v10, 4 of the 3,340 records are followed by bytes nothing
; indexed starts at). The first word of a widget record is its CLASS ID
; 0x016S_KKKK: ClassProc (ui/ui_widget_defs.s) takes (id >> 16) & 0xfff
; as a registry slot -- the Class table that RegObjTable 0x1600004 put
; there -- and 0x18 * (id & 0xffff) into it. Each class definition gives
; the instance size (+8 allsize), and all 3,340 in-ROM widget records of
; v10 resolve to a class and are at least that far apart (THE CLASS
; SYSTEM, scripts/analysis/nakarest_objtab_map.py).
;
; Tables with objects in this file:
;
; Viewable slot 0x9: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe59c5a,
; 0x9 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x9. Element 0 is named "ReverbEqualizerMenu" in ResName slot
; 0x309. Links: all 4 records consistent.
;
; Viewable slot 0xf: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xe59c6e,
; 0xf in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0xf. Element 0 is named "R12OctaveSetting" in ResName slot 0x30f.
; Links: all 3 records consistent.
;
; Viewable slot 0x18: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe59c7e,
; 0x18 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x18. Element 0 is named "ReverbPreset" in ResName slot 0x318.
; Links: all 12 records consistent.
;
; Viewable slot 0x19: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe59cb2,
; 0x19 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x19. Element 0 is named "EqualizerPreset" in ResName slot 0x319.
; Links: all 12 records consistent.
;
; Viewable slot 0x1a: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe59ce6,
; 0x1a in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x1a. Element 0 is named "ReverbEqualizerPreset" in ResName slot
; 0x31a. Links: all 12 records consistent.
;
; Viewable slot 0x50: RegObjTabl 0x1600010, ViewableProc, 0x14,
; 0xe59d1a, 0x50 in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x50. Element 0 is named "MidiMenu" in ResName slot 0x350. Links:
; all 20 records consistent.
;
; Viewable slot 0x51: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xe59d6e,
; 0x51 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x51. Element 0 is named "MidiPartSetting" in ResName slot 0x351.
; Links: all 7 records consistent.
;
; Viewable slot 0x52: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe59d8e,
; 0x52 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x52. Element 0 is named "MidiControlMessage" in ResName slot
; 0x352. Links: all 8 records consistent.
;
; Viewable slot 0x53: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe59db2,
; 0x53 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x53. Element 0 is named "MidiRealtimeMessage" in ResName slot
; 0x353. Links: all 6 records consistent.
;
; Viewable slot 0x54: RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe59dce,
; 0x54 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 5, table} at 0x27ed2 +
; 14*0x54. Element 0 is named "MidiCommonSetting" in ResName slot 0x354.
; Links: all 5 records consistent.
;
; Viewable slot 0x55: RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe59de6,
; 0x55 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 5, table} at 0x27ed2 +
; 14*0x55. Element 0 is named "MidiInOutSetting" in ResName slot 0x355.
; Links: all 5 records consistent.
;
; Viewable slot 0x56: RegObjTabl 0x1600010, ViewableProc, 0x43,
; 0xe59dfe, 0x56 in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 67, table} at 0x27ed2 +
; 14*0x56. Element 0 is named "MidiPresets" in ResName slot 0x356.
; Links: all 67 records consistent.
;
; Viewable slot 0x57: RegObjTabl 0x1600010, ViewableProc, 0x1c,
; 0xe59f0e, 0x57 in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 28, table} at 0x27ed2 +
; 14*0x57. Element 0 is named "MidiExclusive" in ResName slot 0x357.
; Links: all 28 records consistent.
;
; Viewable slot 0x58: RegObjTabl 0x1600010, ViewableProc, 0x15,
; 0xe59f82, 0x58 in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 21, table} at 0x27ed2 +
; 14*0x58. Element 0 is named "MidiGmMode" in ResName slot 0x358. Links:
; all 21 records consistent.
;
; Viewable slot 0x59: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe59fda,
; 0x59 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x59. Element 0 is named "MidiPcgOutput" in ResName slot 0x359.
; Links: 3 of 6 records have a disagreeing link (elements 3-5); element
; 4 points outside the program ROM (RAM records).
;
; Viewable slot 0x5a: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe59ff6,
; 0x5a in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x5a. Element 0 is named "MidiComputerConnection" in ResName slot
; 0x35a. Links: all 6 records consistent.
;
; Viewable slot 0x5b: RegObjTabl 0x1600010, ViewableProc, 0x11,
; 0xe5a012, 0x5b in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x5b. Element 0 is named "MidiPanelMemoryOutput" in ResName slot
; 0x35b. Links: all 17 records consistent.
;
; Viewable slot 0x5c: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe5a05a,
; 0x5c in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x5c. Element 0 is named "MidiSetup" in ResName slot 0x35c. Links:
; all 8 records consistent.
;
; Viewable slot 0xd7: RegObjTabl 0x1600010, ViewableProc, 0x18,
; 0xe5a07e, 0xd7 in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 24, table} at 0x27ed2 +
; 14*0xd7. Element 0 is named "EntertainerVocal" in ResName slot 0x3d7.
; Links: all 24 records consistent.
;
; Viewable slot 0xd8: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe5a0e2,
; 0xd8 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0xd8. Element 0 is named "EntertainerFade" in ResName slot 0x3d8.
; Links: all 8 records consistent.
;
; Viewable slot 0xec: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe5a106,
; 0xec in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xec. Element 0 is named "SplitSetting" in ResName slot 0x3ec.
; Links: all 6 records consistent.
;
; ResName slot 0x309: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe5a122,
; 0x309 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x309.
;
; ResName slot 0x30f: RegObjTabl 0x160000f, ResNameProc, 0x3, 0xe5a152,
; 0x30f in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x30f.
;
; ResName slot 0x318: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe5a17a,
; 0x318 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x318.
;
; ResName slot 0x319: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe5a1d4,
; 0x319 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x319.
;
; ResName slot 0x31a: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe5a23a,
; 0x31a in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x31a.
;
; ResName slot 0x350: RegObjTabl 0x160000f, ResNameProc, 0x14, 0xe5a2a8,
; 0x350 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x350.
;
; ResName slot 0x351: RegObjTabl 0x160000f, ResNameProc, 0x7, 0xe5a350,
; 0x351 in InitializeEast (sequencer/seq_event_playback.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x351.
;
; Function slot 0x403: RegObjTabl 0x1600001, FunctionProc, 0x10,
; 0xe55df2, 0x403 in InitializeEast (sequencer/seq_event_playback.s),
; i.e. RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x403.
; -----------------------------------------------------------------------------

; [nakarest] NakaInst_AcMidiPartGridBoxProc  +0x0..+0x16 (0xe55e38, 22 B)
; [nakarest] name string, entry 15 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcMidiPartGridBoxProc".
NakaInst_AcMidiPartGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x0, 0x16
; [nakarest] NakaInst_AcCtlMsgGridBoxProc  +0x16..+0x2a (0xe55e4e, 20 B)
; [nakarest] name string, entry 14 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcCtlMsgGridBoxProc".
NakaInst_AcCtlMsgGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x16, 0x14
; [nakarest] NakaInst_AcPmemOutRGridBoxProc  +0x2a..+0x40 (0xe55e62, 22 B)
; [nakarest] name string, entry 13 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcPmemOutRGridBoxProc".
NakaInst_AcPmemOutRGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2A, 0x16
; [nakarest] NakaInst_AcPmemOutLGridBoxProc  +0x40..+0x56 (0xe55e78, 22 B)
; [nakarest] name string, entry 12 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcPmemOutLGridBoxProc".
NakaInst_AcPmemOutLGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x40, 0x16
; [nakarest] NakaInst_AcPcgOutGridBoxProc  +0x56..+0x6a (0xe55e8e, 20 B)
; [nakarest] name string, entry 11 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcPcgOutGridBoxProc".
NakaInst_AcPcgOutGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x56, 0x14
; [nakarest] NakaInst_AcParaLoadOptGridBoxProc  +0x6a..+0x84 (0xe55ea2, 26 B)
; [nakarest] name string, entry 10 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcParaLoadOptGridBoxProc".
NakaInst_AcParaLoadOptGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x6A, 0x1A
; [nakarest] NakaInst_AcInOutGridBoxProc  +0x84..+0x98 (0xe55ebc, 20 B)
; [nakarest] name string, entry 9 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcInOutGridBoxProc".
NakaInst_AcInOutGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x84, 0x14
; [nakarest] NakaInst_AcVocalGridBoxProc  +0x98..+0xac (0xe55ed0, 20 B)
; [nakarest] name string, entry 8 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcVocalGridBoxProc".
NakaInst_AcVocalGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x98, 0x14
; [nakarest] NakaInst_AcFadeSetGridBoxProc  +0xac..+0xc2 (0xe55ee4, 22 B)
; [nakarest] name string, entry 7 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcFadeSetGridBoxProc".
NakaInst_AcFadeSetGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xAC, 0x16
; [nakarest] NakaInst_AcLswFuncEditBoxProc  +0xc2..+0xd8 (0xe55efa, 22 B)
; [nakarest] name string, entry 6 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcLswFuncEditBoxProc".
NakaInst_AcLswFuncEditBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xC2, 0x16
; [nakarest] NakaInst_AcLswFuncBoxProc  +0xd8..+0xea (0xe55f10, 18 B)
; [nakarest] name string, entry 5 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcLswFuncBoxProc".
NakaInst_AcLswFuncBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xD8, 0x12
; [nakarest] NakaInst_AcGMOnOffBoxProc  +0xea..+0xfc (0xe55f22, 18 B)
; [nakarest] name string, entry 4 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcGMOnOffBoxProc".
NakaInst_AcGMOnOffBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xEA, 0x12
; [nakarest] NakaInst_AcSendEditSwProc  +0xfc..+0x10e (0xe55f34, 18 B)
; [nakarest] name string, entry 3 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcSendEditSwProc".
NakaInst_AcSendEditSwProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xFC, 0x12
; [nakarest] NakaInst_IvMpstPageControlProc  +0x10e..+0x124 (0xe55f46, 22 B)
; [nakarest] name string, entry 2 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "IvMpstPageControlProc".
NakaInst_IvMpstPageControlProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x10E, 0x16
; [nakarest] NakaInst_PsHarmOnOffBoxProc  +0x124..+0x138 (0xe55f5c, 20 B)
; [nakarest] name string, entry 1 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "PsHarmOnOffBoxProc".
NakaInst_PsHarmOnOffBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x124, 0x14
; [nakarest] NakaInst_AcVocalistListBoxProc  +0x138..+0x14e (0xe55f70, 22 B)
; [nakarest] name string, entry 0 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcVocalistListBoxProc".
NakaInst_AcVocalistListBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x138, 0x16
; [nakarest] naka_midi_reverb+0x14e  +0x14e..+0x274 (0xe55f86, 294 B)
; [nakarest] widget record, element 0 of Viewable slot 0x9 (table 0xe59c5a, 4 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerMenu"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast): "REVERB &
; [nakarest] EQUALIZER PRESETS" (TtlScreen.title of element 0). widget record, element 1 of
; [nakarest] Viewable slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast)
; [nakarest] ("ReverbEqualizerMenu"): AcTitleMenu (54 B). text the records point at, in Viewable
; [nakarest] slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast): "REVERB PRESETS"
; [nakarest] (AcTitleMenu.str of element 1). widget record, element 2 of Viewable slot 0x9
; [nakarest] (table 0xe59c5a, 4 entries, InitializeEast) ("ReverbEqualizerMenu"): AcTitleMenu
; [nakarest] (54 B). text the records point at, in Viewable slot 0x9 (table 0xe59c5a, 4 entries,
; [nakarest] InitializeEast): "EQUALIZER PRESETS" (AcTitleMenu.str of element 2). widget record,
; [nakarest] element 3 of Viewable slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast)
; [nakarest] ("ReverbEqualizerMenu"): AcTitleMenu (54 B). text the records point at, in Viewable
; [nakarest] slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast): "REVERB + EQUALIZER PRESETS"
; [nakarest] (AcTitleMenu.str of element 3).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x14E, 0x126
; [nakarest] naka_midi_reverb+0x274  +0x274..+0x324 (0xe560ac, 176 B)
; [nakarest] widget record, element 0 of Viewable slot 0xf (table 0xe59c6e, 3 entries,
; [nakarest] InitializeEast) ("R12OctaveSetting"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xf (table 0xe59c6e, 3 entries, InitializeEast): "RIGHT1/RIGHT2
; [nakarest] OCTAVE" (TtlScreen.title of element 0). widget record, element 1 of Viewable slot
; [nakarest] 0xf (table 0xe59c6e, 3 entries, InitializeEast) ("R12OctaveSetting"): AcLswEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0xf (table 0xe59c6e, 3 entries,
; [nakarest] InitializeEast): "OCTAVE :" (AcLswEditBox.caption of element 1). widget record,
; [nakarest] element 2 of Viewable slot 0xf (table 0xe59c6e, 3 entries, InitializeEast)
; [nakarest] ("R12OctaveSetting"): AcIndexWideES (42 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x274, 0xB0
; [nakarest] naka_midi_reverb+0x324  +0x324..+0x5ce (0xe5615c, 682 B)
; [nakarest] widget record, element 0 of Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; [nakarest] InitializeEast) ("ReverbPreset"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast): "REVERB PRESETS"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x18
; [nakarest] (table 0xe59c7e, 12 entries, InitializeEast) ("ReverbPreset"): AcStrRadioBox (48
; [nakarest] B). text the records point at, in Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; [nakarest] InitializeEast): "Huge Room" (AcStrRadioBox.str of element 1). widget record,
; [nakarest] element 2 of Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast)
; [nakarest] ("ReverbPreset"): AcStrRadioBox (48 B). text the records point at, in Viewable slot
; [nakarest] 0x18 (table 0xe59c7e, 12 entries, InitializeEast): "Box Room" (AcStrRadioBox.str of
; [nakarest] element 2). widget records, elements 3-4 of Viewable slot 0x18 (table 0xe59c7e, 12
; [nakarest] entries, InitializeEast) ("ReverbPreset"): IvCatchEvent (26 B), AcStrRadioBox (48
; [nakarest] B). text the records point at, in Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; [nakarest] InitializeEast): "Small Plate" (AcStrRadioBox.str of element 4). widget record,
; [nakarest] element 5 of Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast)
; [nakarest] ("ReverbPreset"): AcStrRadioBox (48 B). text the records point at, in Viewable slot
; [nakarest] 0x18 (table 0xe59c7e, 12 entries, InitializeEast): "Sports Hall" (AcStrRadioBox.str
; [nakarest] of element 5). widget record, element 6 of Viewable slot 0x18 (table 0xe59c7e, 12
; [nakarest] entries, InitializeEast) ("ReverbPreset"): AcStrRadioBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast):
; [nakarest] "Bright Hall" (AcStrRadioBox.str of element 6). widget record, element 7 of
; [nakarest] Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast) ("ReverbPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x18 (table
; [nakarest] 0xe59c7e, 12 entries, InitializeEast): "Dark Confines" (AcStrRadioBox.str of
; [nakarest] element 7). widget record, element 8 of Viewable slot 0x18 (table 0xe59c7e, 12
; [nakarest] entries, InitializeEast) ("ReverbPreset"): AcStrRadioBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast):
; [nakarest] "Reflection" (AcStrRadioBox.str of element 8). widget record, element 9 of Viewable
; [nakarest] slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast) ("ReverbPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x18 (table
; [nakarest] 0xe59c7e, 12 entries, InitializeEast): "High & Open" (AcStrRadioBox.str of element
; [nakarest] 9). widget record, element 10 of Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; [nakarest] InitializeEast) ("ReverbPreset"): AcStrRadioBox (48 B). text the records point at,
; [nakarest] in Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast): "Left To Right"
; [nakarest] (AcStrRadioBox.str of element 10). widget record, element 11 of Viewable slot 0x18
; [nakarest] (table 0xe59c7e, 12 entries, InitializeEast) ("ReverbPreset"): AcStrRadioBox (48
; [nakarest] B). text the records point at, in Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; [nakarest] InitializeEast): "Cavernous" (AcStrRadioBox.str of element 11).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x324, 0x2AA
; [nakarest] naka_midi_reverb+0x5ce  +0x5ce..+0x87e (0xe56406, 688 B)
; [nakarest] widget record, element 0 of Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; [nakarest] InitializeEast) ("EqualizerPreset"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast): "EQUALIZER
; [nakarest] PRESETS" (TtlScreen.title of element 0). widget record, element 1 of Viewable slot
; [nakarest] 0x19 (table 0xe59cb2, 12 entries, InitializeEast) ("EqualizerPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x19 (table
; [nakarest] 0xe59cb2, 12 entries, InitializeEast): "Make Up" (AcStrRadioBox.str of element 1).
; [nakarest] widget record, element 2 of Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; [nakarest] InitializeEast) ("EqualizerPreset"): AcStrRadioBox (48 B). text the records point
; [nakarest] at, in Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast): "Middle
; [nakarest] Cut" (AcStrRadioBox.str of element 2). widget record, element 3 of Viewable slot
; [nakarest] 0x19 (table 0xe59cb2, 12 entries, InitializeEast) ("EqualizerPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x19 (table
; [nakarest] 0xe59cb2, 12 entries, InitializeEast): "Transistor Radio" (AcStrRadioBox.str of
; [nakarest] element 3). widget record, element 4 of Viewable slot 0x19 (table 0xe59cb2, 12
; [nakarest] entries, InitializeEast) ("EqualizerPreset"): AcStrRadioBox (48 B). text the
; [nakarest] records point at, in Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; [nakarest] InitializeEast): "Treble Boost" (AcStrRadioBox.str of element 4). widget record,
; [nakarest] element 5 of Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast)
; [nakarest] ("EqualizerPreset"): AcStrRadioBox (48 B). text the records point at, in Viewable
; [nakarest] slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast): "Treble Cut"
; [nakarest] (AcStrRadioBox.str of element 5). widget record, element 6 of Viewable slot 0x19
; [nakarest] (table 0xe59cb2, 12 entries, InitializeEast) ("EqualizerPreset"): AcStrRadioBox (48
; [nakarest] B). text the records point at, in Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; [nakarest] InitializeEast): "No Hi Hat" (AcStrRadioBox.str of element 6). widget record,
; [nakarest] element 7 of Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast)
; [nakarest] ("EqualizerPreset"): AcStrRadioBox (48 B). text the records point at, in Viewable
; [nakarest] slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast): "Tubby Bass"
; [nakarest] (AcStrRadioBox.str of element 7). widget record, element 8 of Viewable slot 0x19
; [nakarest] (table 0xe59cb2, 12 entries, InitializeEast) ("EqualizerPreset"): AcStrRadioBox (48
; [nakarest] B). text the records point at, in Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; [nakarest] InitializeEast): "Bass Cut" (AcStrRadioBox.str of element 8). widget record,
; [nakarest] element 9 of Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast)
; [nakarest] ("EqualizerPreset"): AcStrRadioBox (48 B). text the records point at, in Viewable
; [nakarest] slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast): "Too Bright"
; [nakarest] (AcStrRadioBox.str of element 9). widget records, elements 10-11 of Viewable slot
; [nakarest] 0x19 (table 0xe59cb2, 12 entries, InitializeEast) ("EqualizerPreset"): IvCatchEvent
; [nakarest] (26 B), AcFuncToggle (44 B). text the records point at, in Viewable slot 0x19
; [nakarest] (table 0xe59cb2, 12 entries, InitializeEast): "EQ : OFF" (AcFuncToggle.stroff of
; [nakarest] element 11); "EQ : ON" (AcFuncToggle.stron of element 11).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x5CE, 0x2B0
; [nakarest] naka_midi_reverb+0x87e  +0x87e..+0xb32 (0xe566b6, 692 B)
; [nakarest] widget record, element 0 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast): "REVERB +
; [nakarest] EQUALIZER PRESETS" (TtlScreen.title of element 0). widget record, element 1 of
; [nakarest] Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast)
; [nakarest] ("ReverbEqualizerPreset"): AcStrRadioBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast): "Warm & Wide"
; [nakarest] (AcStrRadioBox.str of element 1). widget record, element 2 of Viewable slot 0x1a
; [nakarest] (table 0xe59ce6, 12 entries, InitializeEast) ("ReverbEqualizerPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x1a (table
; [nakarest] 0xe59ce6, 12 entries, InitializeEast): "In Your Face" (AcStrRadioBox.str of element
; [nakarest] 2). widget record, element 3 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): AcStrRadioBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast): "Oil
; [nakarest] Tank" (AcStrRadioBox.str of element 3). widget record, element 4 of Viewable slot
; [nakarest] 0x1a (table 0xe59ce6, 12 entries, InitializeEast) ("ReverbEqualizerPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x1a (table
; [nakarest] 0xe59ce6, 12 entries, InitializeEast): "Warm Plate" (AcStrRadioBox.str of element
; [nakarest] 4). widget record, element 5 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): AcStrRadioBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast):
; [nakarest] "Light & Shade" (AcStrRadioBox.str of element 5). widget record, element 6 of
; [nakarest] Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast)
; [nakarest] ("ReverbEqualizerPreset"): AcStrRadioBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast): "Warm & Fuzzy"
; [nakarest] (AcStrRadioBox.str of element 6). widget record, element 7 of Viewable slot 0x1a
; [nakarest] (table 0xe59ce6, 12 entries, InitializeEast) ("ReverbEqualizerPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x1a (table
; [nakarest] 0xe59ce6, 12 entries, InitializeEast): "Ice Box" (AcStrRadioBox.str of element 7).
; [nakarest] widget record, element 8 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): AcStrRadioBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast):
; [nakarest] "Stadium" (AcStrRadioBox.str of element 8). widget record, element 9 of Viewable
; [nakarest] slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast) ("ReverbEqualizerPreset"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x1a (table
; [nakarest] 0xe59ce6, 12 entries, InitializeEast): "Live Room" (AcStrRadioBox.str of element
; [nakarest] 9). widget record, element 10 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): AcFuncToggle (44 B). text the records
; [nakarest] point at, in Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast): "EQ :
; [nakarest] OFF" (AcFuncToggle.stroff of element 10); "EQ : ON" (AcFuncToggle.stron of element
; [nakarest] 10). widget record, element 11 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): IvCatchEvent (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x87E, 0x2B4
; [nakarest] naka_midi_reverb+0xb32  +0xb32..+0xf9c (0xe5696a, 1130 B)
; [nakarest] widget record, element 0 of Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast) ("MidiMenu"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast): "MIDI MENU"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-7 of Viewable slot 0x50
; [nakarest] (table 0xe59d1a, 20 entries, InitializeEast) ("MidiMenu"): AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x2, IvExitMode (26 B), IvShowHide (26 B), Window (36 B),
; [nakarest] AcTitleMenu (54 B). text the records point at, in Viewable slot 0x50 (table
; [nakarest] 0xe59d1a, 20 entries, InitializeEast): "PART SETTING" (AcTitleMenu.str of element
; [nakarest] 7). widget record, element 8 of Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast) ("MidiMenu"): AcTitleMenu (54 B). text the records point at, in
; [nakarest] Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast): "CONTROL MESSAGES"
; [nakarest] (AcTitleMenu.str of element 8). widget record, element 9 of Viewable slot 0x50
; [nakarest] (table 0xe59d1a, 20 entries, InitializeEast) ("MidiMenu"): AcTitleMenu (54 B). text
; [nakarest] the records point at, in Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast): "REALTIME MESSAGES" (AcTitleMenu.str of element 9). widget record,
; [nakarest] element 10 of Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast)
; [nakarest] ("MidiMenu"): AcTitleMenu (54 B). text the records point at, in Viewable slot 0x50
; [nakarest] (table 0xe59d1a, 20 entries, InitializeEast): "COMMON SETTING" (AcTitleMenu.str of
; [nakarest] element 10). widget record, element 11 of Viewable slot 0x50 (table 0xe59d1a, 20
; [nakarest] entries, InitializeEast) ("MidiMenu"): AcTitleMenu (54 B). text the records point
; [nakarest] at, in Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast):
; [nakarest] "INPUT/OUTPUT SETTING" (AcTitleMenu.str of element 11). widget record, element 12
; [nakarest] of Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast) ("MidiMenu"):
; [nakarest] AcTitleMenu (54 B). text the records point at, in Viewable slot 0x50 (table
; [nakarest] 0xe59d1a, 20 entries, InitializeEast): "MIDI PRESETS" (AcTitleMenu.str of element
; [nakarest] 12). widget record, element 13 of Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast) ("MidiMenu"): AcTitleMenu (54 B). text the records point at, in
; [nakarest] Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast): "SYSEX BULK DUMP"
; [nakarest] (AcTitleMenu.str of element 13). widget record, element 14 of Viewable slot 0x50
; [nakarest] (table 0xe59d1a, 20 entries, InitializeEast) ("MidiMenu"): AcTitleMenu (54 B). text
; [nakarest] the records point at, in Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast): "GENERAL MIDI" (AcTitleMenu.str of element 14). widget record,
; [nakarest] element 15 of Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast)
; [nakarest] ("MidiMenu"): AcTitleMenu (54 B). text the records point at, in Viewable slot 0x50
; [nakarest] (table 0xe59d1a, 20 entries, InitializeEast): "PROG.CHANGE MIDI OUT"
; [nakarest] (AcTitleMenu.str of element 15). widget record, element 16 of Viewable slot 0x50
; [nakarest] (table 0xe59d1a, 20 entries, InitializeEast) ("MidiMenu"): AcTitleMenu (54 B). text
; [nakarest] the records point at, in Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast): "P.MEM OUTPUT" (AcTitleMenu.str of element 16). widget records,
; [nakarest] elements 17-18 of Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast)
; [nakarest] ("MidiMenu"): Window (36 B), AcTitleMenu (54 B). text the records point at, in
; [nakarest] Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast): "COMPUTER
; [nakarest] CONNECTION" (AcTitleMenu.str of element 18). widget record, element 19 of Viewable
; [nakarest] slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast) ("MidiMenu"): AcTitleMenu
; [nakarest] (54 B). text the records point at, in Viewable slot 0x50 (table 0xe59d1a, 20
; [nakarest] entries, InitializeEast): "MIDI SETTINGS LOAD OPTION" (AcTitleMenu.str of element
; [nakarest] 19).
	.incbin "includes/generated/naka_midi_reverb.bin", 0xB32, 0x46A
; [nakarest] naka_midi_reverb+0xf9c  +0xf9c..+0x1136 (0xe56dd4, 410 B)
; [nakarest] widget record, element 0 of Viewable slot 0x51 (table 0xe59d6e, 7 entries,
; [nakarest] InitializeEast) ("MidiPartSetting"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x51 (table 0xe59d6e, 7 entries, InitializeEast): "PART SETTING"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x51
; [nakarest] (table 0xe59d6e, 7 entries, InitializeEast) ("MidiPartSetting"): AcMidiPartGridBox
; [nakarest] (78 B). text the records point at, in Viewable slot 0x51 (table 0xe59d6e, 7
; [nakarest] entries, InitializeEast): "|-|RIGHT1|RIGHT2|LEFT|PART4|PART5|PART6|PART7|PA"
; [nakarest] (AcMidiPartGridBox.fixedrow of element 1); " PART |CHANNEL|OCTAVE| LOCAL"
; [nakarest] (AcMidiPartGridBox.fixedcol of element 1). widget records, elements 2-6 of Viewable
; [nakarest] slot 0x51 (table 0xe59d6e, 7 entries, InitializeEast) ("MidiPartSetting"):
; [nakarest] AcIndexWideES (42 B) x4, IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0xF9C, 0x19A
; [nakarest] naka_midi_reverb+0x1136  +0x1136..+0x12f8 (0xe56f6e, 450 B)
; [nakarest] widget record, element 0 of Viewable slot 0x52 (table 0xe59d8e, 8 entries,
; [nakarest] InitializeEast) ("MidiControlMessage"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast): "CONTROL
; [nakarest] MESSAGES" (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable
; [nakarest] slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast) ("MidiControlMessage"):
; [nakarest] PsPageBox (32 B), AcCtlMsgGridBox (78 B). text the records point at, in Viewable
; [nakarest] slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast): "PRG.CHANGE|BANK
; [nakarest] SELECT|PITCH BEND|VOLUME|EXPRESS" (AcCtlMsgGridBox.fixedrow of element 2); " | "
; [nakarest] (AcCtlMsgGridBox.fixedcol of element 2). widget records, elements 3-4 of Viewable
; [nakarest] slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast) ("MidiControlMessage"):
; [nakarest] AcIndexWideES (42 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x52 (table 0xe59d8e, 8 entries, InitializeEast): "MESSAGE" (Label.str of element
; [nakarest] 4). widget record, element 5 of Viewable slot 0x52 (table 0xe59d8e, 8 entries,
; [nakarest] InitializeEast) ("MidiControlMessage"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast): "ON/OFF" (Label.str
; [nakarest] of element 5). widget records, elements 6-7 of Viewable slot 0x52 (table 0xe59d8e,
; [nakarest] 8 entries, InitializeEast) ("MidiControlMessage"): AcIndexWideES (42 B), IvShowHide
; [nakarest] (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1136, 0x1C2
; [nakarest] naka_midi_reverb+0x12f8  +0x12f8..+0x1476 (0xe57130, 382 B)
; [nakarest] widget record, element 0 of Viewable slot 0x53 (table 0xe59db2, 6 entries,
; [nakarest] InitializeEast) ("MidiRealtimeMessage"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast): "REALTIME
; [nakarest] MESSAGES" (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable
; [nakarest] slot 0x53 (table 0xe59db2, 6 entries, InitializeEast) ("MidiRealtimeMessage"):
; [nakarest] AcIndexWideES (42 B), AcLswFuncEditBox (68 B). text the records point at, in
; [nakarest] Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast): " OFF "
; [nakarest] (AcLswFuncEditBox.off_str of element 2); " ON " (AcLswFuncEditBox.on_str of element
; [nakarest] 2); "REALTIME COMMANDS :" (AcLswFuncEditBox.caption of element 2). widget record,
; [nakarest] element 3 of Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast)
; [nakarest] ("MidiRealtimeMessage"): AcLswFuncEditBox (68 B). text the records point at, in
; [nakarest] Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast): " INTERNAL "
; [nakarest] (AcLswFuncEditBox.off_str of element 3); " MIDI " (AcLswFuncEditBox.on_str of
; [nakarest] element 3); " CLOCK :" (AcLswFuncEditBox.caption of element 3). widget record,
; [nakarest] element 4 of Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast)
; [nakarest] ("MidiRealtimeMessage"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x53 (table 0xe59db2, 6 entries, InitializeEast): "VALUE" (Label.str of element 4).
; [nakarest] widget record, element 5 of Viewable slot 0x53 (table 0xe59db2, 6 entries,
; [nakarest] InitializeEast) ("MidiRealtimeMessage"): IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x12F8, 0x17E
; [nakarest] naka_midi_reverb+0x1476  +0x1476..+0x1642 (0xe572ae, 460 B)
; [nakarest] widget record, element 0 of Viewable slot 0x54 (table 0xe59dce, 5 entries,
; [nakarest] InitializeEast) ("MidiCommonSetting"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x54 (table 0xe59dce, 5 entries, InitializeEast): "COMMON SETTING"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x54
; [nakarest] (table 0xe59dce, 5 entries, InitializeEast) ("MidiCommonSetting"): AcGridBox (74
; [nakarest] B). text the records point at, in Viewable slot 0x54 (table 0xe59dce, 5 entries,
; [nakarest] InitializeEast): " NOTE ONLY :| PRG.CHANGE TO P.MEM :| R" (AcGridBox.fixedrow of
; [nakarest] element 1); " | " (AcGridBox.fixedcol of element 1). widget records, elements 2-4
; [nakarest] of Viewable slot 0x54 (table 0xe59dce, 5 entries, InitializeEast)
; [nakarest] ("MidiCommonSetting"): AcIndexWideES (42 B) x2, IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1476, 0x1CC
; [nakarest] naka_midi_reverb+0x1642  +0x1642..+0x1800 (0xe5747a, 446 B)
; [nakarest] widget record, element 0 of Viewable slot 0x55 (table 0xe59de6, 5 entries,
; [nakarest] InitializeEast) ("MidiInOutSetting"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x55 (table 0xe59de6, 5 entries, InitializeEast): "INPUT/OUTPUT
; [nakarest] SETTING" (TtlScreen.title of element 0). widget record, element 1 of Viewable slot
; [nakarest] 0x55 (table 0xe59de6, 5 entries, InitializeEast) ("MidiInOutSetting"):
; [nakarest] AcInOutGridBox (74 B). text the records point at, in Viewable slot 0x55 (table
; [nakarest] 0xe59de6, 5 entries, InitializeEast): " RIGHT 1 INPUT :| AUTO PLAY CHORD INPUT"
; [nakarest] (AcInOutGridBox.fixedrow of element 1); " | " (AcInOutGridBox.fixedcol of element
; [nakarest] 1). widget records, elements 2-4 of Viewable slot 0x55 (table 0xe59de6, 5 entries,
; [nakarest] InitializeEast) ("MidiInOutSetting"): AcIndexWideES (42 B) x2, IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1642, 0x1BE
; [nakarest] naka_midi_reverb+0x1800  +0x1800..+0x1a28 (0xe57638, 552 B)
; [nakarest] widget record, element 0 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "MIDI PRESETS"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-10 of Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"): AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x2, IvMpstPageControl (32 B) x2, IvShowHide (26 B), Window (36
; [nakarest] B), AcIndexWideES (42 B), AcFuncEditSw (44 B), Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "VALUE"
; [nakarest] (Label.str of element 10). widget records, elements 11-12 of Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"): VwBox (28 B),
; [nakarest] AcListBox (48 B). text the records point at, in Viewable slot 0x56 (table 0xe59dfe,
; [nakarest] 67 entries, InitializeEast): "Organ ~95|Organ Fixed Touch ~95|PX P" (AcListBox.list
; [nakarest] of element 12).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1800, 0x228
; [nakarest] NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95  +0x1a28..+0x24b2 (0xe57860, 2698 B)
; [nakarest] Continues text the records point at, in Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast): "Organ ~95|Organ Fixed Touch ~95|PX P" (AcListBox.list of
; [nakarest] element 12) (starts 0xe57812, 54 of its 132 bytes are here or later). widget
; [nakarest] records, elements 13-14 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcFuncWideES (46 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast): "WITHOUT APC" (Label.str of element 14). widget records, elements
; [nakarest] 15-16 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): AcFuncWideES (46 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "WITH APC"
; [nakarest] (Label.str of element 16). widget records, elements 17-18 of Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"): VwUserBitmap (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast): "KN5000" (Label.str of element 18). widget records,
; [nakarest] elements 19-21 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): Window (36 B), VwBox (28 B), AcListBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast):
; [nakarest] "Organ 1 ~95|Organ 2 ~95|Or" (AcListBox.list of element 21). widget records,
; [nakarest] elements 22-23 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): VwUserBitmap (26 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "KN5000"
; [nakarest] (Label.str of element 23). widget records, elements 24-27 of Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"): AcFuncEditSw (44 B),
; [nakarest] AcIndexWideES (42 B), AcFuncWideES (46 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "WITH APC"
; [nakarest] (Label.str of element 27). widget records, elements 28-29 of Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"): AcFuncWideES (46 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast): "WITHOUT APC" (Label.str of element 29). widget record,
; [nakarest] element 30 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): Label (32 B). text the records point at, in Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast): "VALUE" (Label.str of element 30).
; [nakarest] widget records, elements 31-32 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): Window (36 B), AcListBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "
; [nakarest] USER 1 SETTING | USER 2 SETTING | USER 3 SETTIN" (AcListBox.list of element 32).
; [nakarest] widget records, elements 33-35 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcIndexWideES (42 B), AcFuncEditSw (44 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast): "VALUE" (Label.str of element 35). widget records,
; [nakarest] elements 36-37 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): Window (36 B), AcListBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): " USER 1 SETTING |
; [nakarest] USER 2 SETTING | USER 3 SETTIN" (AcListBox.list of element 37). widget records,
; [nakarest] elements 38-40 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): AcIndexWideES (42 B), AcFuncEditSw (44 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast): "WRITE" (Label.str of element 40). widget record, element 41 of
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"):
; [nakarest] AcFuncToggle (44 B). text the records point at, in Viewable slot 0x56 (table
; [nakarest] 0xe59dfe, 67 entries, InitializeEast): "WITH SPLIT POINT ? : NO"
; [nakarest] (AcFuncToggle.stroff of element 41); "WITH SPLIT POINT ? : YES" (AcFuncToggle.stron
; [nakarest] of element 41). widget record, element 42 of Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast) ("MidiPresets"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "VALUE"
; [nakarest] (Label.str of element 42). widget records, elements 43-45 of Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"): Window (36 B), VwBox
; [nakarest] (28 B), AcListBox (48 B). text the records point at, in Viewable slot 0x56 (table
; [nakarest] 0xe59dfe, 67 entries, InitializeEast): "~95 Sound Module|~95 Vocalist|~95 Ext.
; [nakarest] Sequencer" (AcListBox.list of element 45). widget records, elements 46-47 of
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"):
; [nakarest] VwUserBitmap (26 B), Label (32 B). text the records point at, in Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast): "KN5000" (Label.str of element 47).
; [nakarest] widget records, elements 48-51 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcIndexWideES (42 B), AcFuncEditSw (44 B),
; [nakarest] AcFuncWideES (46 B), Label (32 B). text the records point at, in Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast): "WITH APC" (Label.str of element 51).
; [nakarest] widget records, elements 52-53 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcFuncWideES (46 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast): "WITHOUT APC" (Label.str of element 53). widget record, element 54
; [nakarest] of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast): "VALUE" (Label.str of element 54). widget records,
; [nakarest] elements 55-57 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): Window (36 B), VwBox (28 B), AcListBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "~95
; [nakarest] Sound Module|~95 Vocalist|~95 Ext. Sequencer" (AcListBox.list of element 57).
; [nakarest] widget records, elements 58-61 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcFuncEditSw (44 B), AcIndexWideES (42 B),
; [nakarest] AcFuncWideES (46 B), Label (32 B). text the records point at, in Viewable slot 0x56
; [nakarest] (table 0xe59dfe, 67 entries, InitializeEast): "WITH APC" (Label.str of element 61).
; [nakarest] widget records, elements 62-63 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcFuncWideES (46 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast): "WITHOUT APC" (Label.str of element 63). widget record, element 64
; [nakarest] of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast) ("MidiPresets"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast): "VALUE" (Label.str of element 64). widget records,
; [nakarest] elements 65-66 of Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)
; [nakarest] ("MidiPresets"): VwUserBitmap (26 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast): "KN5000"
; [nakarest] (Label.str of element 66).
NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1A28, 0xA8A
; [nakarest] naka_midi_reverb+0x24b2  +0x24b2..+0x2b1a (0xe582ea, 1640 B)
; [nakarest] widget record, element 0 of Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast) ("MidiExclusive"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast): "SYSEX BULK DUMP"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0x57
; [nakarest] (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"): AcFuncEditSw (44
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x57 (table 0xe59f0e,
; [nakarest] 28 entries, InitializeEast): "SEND" (Label.str of element 2). widget record,
; [nakarest] element 3 of Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast)
; [nakarest] ("MidiExclusive"): AcListBox (48 B). text the records point at, in Viewable slot
; [nakarest] 0x57 (table 0xe59f0e, 28 entries, InitializeEast): " PERFORMANCE | CURRENT PANEL +
; [nakarest] PANEL MEMORY | CO" (AcListBox.list of element 3). widget records, elements 4-7 of
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"):
; [nakarest] AcIndexWideES (42 B), IvShowHide (26 B), Window (36 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast): "SYSTEM EXCLUSIVE" (Label.str of element 7). widget record,
; [nakarest] element 8 of Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast)
; [nakarest] ("MidiExclusive"): Label (32 B). text the records point at, in Viewable slot 0x57
; [nakarest] (table 0xe59f0e, 28 entries, InitializeEast): "SENDING" (Label.str of element 8).
; [nakarest] widget record, element 9 of Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast) ("MidiExclusive"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast): "PLEASE WAIT!"
; [nakarest] (Label.str of element 9). widget records, elements 10-11 of Viewable slot 0x57
; [nakarest] (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"): VwBox (28 B),
; [nakarest] AcRamEditBox (58 B). text the records point at, in Viewable slot 0x57 (table
; [nakarest] 0xe59f0e, 28 entries, InitializeEast): "PANEL MEMORY :" (AcRamEditBox.caption of
; [nakarest] element 11). widget record, element 12 of Viewable slot 0x57 (table 0xe59f0e, 28
; [nakarest] entries, InitializeEast) ("MidiExclusive"): AcRamEditBox (58 B). text the records
; [nakarest] point at, in Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast):
; [nakarest] "SOUND MEMORY :" (AcRamEditBox.caption of element 12). widget record, element 13 of
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"):
; [nakarest] AcRamEditBox (58 B). text the records point at, in Viewable slot 0x57 (table
; [nakarest] 0xe59f0e, 28 entries, InitializeEast): "COMPOSER :" (AcRamEditBox.caption of
; [nakarest] element 13). widget record, element 14 of Viewable slot 0x57 (table 0xe59f0e, 28
; [nakarest] entries, InitializeEast) ("MidiExclusive"): AcRamEditBox (58 B). text the records
; [nakarest] point at, in Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast):
; [nakarest] "SEQUENCER :" (AcRamEditBox.caption of element 14). widget record, element 15 of
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"):
; [nakarest] AcRamEditBox (58 B). text the records point at, in Viewable slot 0x57 (table
; [nakarest] 0xe59f0e, 28 entries, InitializeEast): "MSP USER :" (AcRamEditBox.caption of
; [nakarest] element 15). widget records, elements 16-18 of Viewable slot 0x57 (table 0xe59f0e,
; [nakarest] 28 entries, InitializeEast) ("MidiExclusive"): AcRamBox (44 B), Window (36 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x57 (table 0xe59f0e, 28
; [nakarest] entries, InitializeEast): "SYSTEM EXCLUSIVE" (Label.str of element 18). widget
; [nakarest] record, element 19 of Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast) ("MidiExclusive"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast): "RECIEVING"
; [nakarest] (Label.str of element 19). widget record, element 20 of Viewable slot 0x57 (table
; [nakarest] 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast): "PLEASE WAIT!" (Label.str of element 20). widget records, elements
; [nakarest] 21-22 of Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast)
; [nakarest] ("MidiExclusive"): VwBox (28 B), AcRamEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast): "PANEL MEMORY :"
; [nakarest] (AcRamEditBox.caption of element 22). widget record, element 23 of Viewable slot
; [nakarest] 0x57 (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"): AcRamEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x57 (table 0xe59f0e, 28
; [nakarest] entries, InitializeEast): "SOUND MEMORY :" (AcRamEditBox.caption of element 23).
; [nakarest] widget record, element 24 of Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast) ("MidiExclusive"): AcRamEditBox (58 B). text the records point at,
; [nakarest] in Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast): "COMPOSER :"
; [nakarest] (AcRamEditBox.caption of element 24). widget record, element 25 of Viewable slot
; [nakarest] 0x57 (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"): AcRamEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x57 (table 0xe59f0e, 28
; [nakarest] entries, InitializeEast): "SEQUENCER :" (AcRamEditBox.caption of element 25).
; [nakarest] widget record, element 26 of Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast) ("MidiExclusive"): AcRamEditBox (58 B). text the records point at,
; [nakarest] in Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast): "MSP USER :"
; [nakarest] (AcRamEditBox.caption of element 26). widget record, element 27 of Viewable slot
; [nakarest] 0x57 (table 0xe59f0e, 28 entries, InitializeEast) ("MidiExclusive"): AcRamBox (44
; [nakarest] B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x24B2, 0x668
; [nakarest] naka_midi_reverb+0x2b1a  +0x2b1a..+0x2e62 (0xe58952, 840 B)
; [nakarest] widget record, element 0 of Viewable slot 0x58 (table 0xe59f82, 21 entries,
; [nakarest] InitializeEast) ("MidiGmMode"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x58 (table 0xe59f82, 21 entries, InitializeEast): "GENERAL MIDI"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x58
; [nakarest] (table 0xe59f82, 21 entries, InitializeEast) ("MidiGmMode"): AcGMOnOffBox (54 B).
; [nakarest] text the records point at, in Viewable slot 0x58 (table 0xe59f82, 21 entries,
; [nakarest] InitializeEast): "GENERAL MIDI :" (AcGMOnOffBox.caption of element 1). widget
; [nakarest] records, elements 2-20 of Viewable slot 0x58 (table 0xe59f82, 21 entries,
; [nakarest] InitializeEast) ("MidiGmMode"): AcIndexWideES (42 B), AcFuncEditSw (44 B) x5,
; [nakarest] IvShowHide (26 B), Window (36 B) x2, VwBox (28 B) x2, AcLanguageText (42 B) x6,
; [nakarest] IvExitWindow (22 B) x2.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2B1A, 0x348
; [nakarest] naka_midi_reverb+0x2e62  +0x2e62..+0x2fca (0xe58c9a, 360 B)
; [nakarest] widget record, element 0 of Viewable slot 0x59 (table 0xe59fda, 6 entries,
; [nakarest] InitializeEast) ("MidiPcgOutput"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x59 (table 0xe59fda, 6 entries, InitializeEast): "PROGRAM CHANGE
; [nakarest] MIDI OUT" (TtlScreen.title of element 0). widget record, element 1 of Viewable slot
; [nakarest] 0x59 (table 0xe59fda, 6 entries, InitializeEast) ("MidiPcgOutput"): AcPcgOutGridBox
; [nakarest] (74 B). text the records point at, in Viewable slot 0x59 (table 0xe59fda, 6
; [nakarest] entries, InitializeEast): " MIDI CHANNEL :| PROGRAM CHANGE :| BANK MSB"
; [nakarest] (AcPcgOutGridBox.fixedrow of element 1); " | " (AcPcgOutGridBox.fixedcol of element
; [nakarest] 1). widget records, elements 2-3, 5 of Viewable slot 0x59 (table 0xe59fda, 6
; [nakarest] entries, InitializeEast) ("MidiPcgOutput"): AcIndexWideES (42 B) x2, IvShowHide (26
; [nakarest] B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2E62, 0x168
; [nakarest] naka_midi_reverb+0x2fca  +0x2fca..+0x30d0 (0xe58e02, 262 B)
; [nakarest] widget record, element 0 of Viewable slot 0x5a (table 0xe59ff6, 6 entries,
; [nakarest] InitializeEast) ("MidiComputerConnection"): TtlScreen (42 B). text the records
; [nakarest] point at, in Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast):
; [nakarest] "COMPUTER CONNECTION" (TtlScreen.title of element 0). widget record, element 1 of
; [nakarest] Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast)
; [nakarest] ("MidiComputerConnection"): AcLswEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast): "MODE :"
; [nakarest] (AcLswEditBox.caption of element 1). widget records, elements 2-4 of Viewable slot
; [nakarest] 0x5a (table 0xe59ff6, 6 entries, InitializeEast) ("MidiComputerConnection"):
; [nakarest] AcIndexWideES (42 B), VwBox (28 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast): "VALUE" (Label.str
; [nakarest] of element 4). widget record, element 5 of Viewable slot 0x5a (table 0xe59ff6, 6
; [nakarest] entries, InitializeEast) ("MidiComputerConnection"): IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2FCA, 0x106
; [nakarest] naka_midi_reverb+0x30d0  +0x30d0..+0x33f2 (0xe58f08, 802 B)
; [nakarest] widget record, element 0 of Viewable slot 0x5b (table 0xe5a012, 17 entries,
; [nakarest] InitializeEast) ("MidiPanelMemoryOutput"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast): "PANEL
; [nakarest] MEMORY OUTPUT" (TtlScreen.title of element 0). widget record, element 1 of Viewable
; [nakarest] slot 0x5b (table 0xe5a012, 17 entries, InitializeEast) ("MidiPanelMemoryOutput"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x5b (table 0xe5a012, 17
; [nakarest] entries, InitializeEast): "P.MEM" (Label.str of element 1). widget record, element
; [nakarest] 2 of Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast)
; [nakarest] ("MidiPanelMemoryOutput"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x5b (table 0xe5a012, 17 entries, InitializeEast): "ON/OFF" (Label.str of
; [nakarest] element 2). widget record, element 3 of Viewable slot 0x5b (table 0xe5a012, 17
; [nakarest] entries, InitializeEast) ("MidiPanelMemoryOutput"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast):
; [nakarest] "PART" (Label.str of element 3). widget record, element 4 of Viewable slot 0x5b
; [nakarest] (table 0xe5a012, 17 entries, InitializeEast) ("MidiPanelMemoryOutput"): Label (32
; [nakarest] B). text the records point at, in Viewable slot 0x5b (table 0xe5a012, 17 entries,
; [nakarest] InitializeEast): "P.CNG" (Label.str of element 4). widget record, element 5 of
; [nakarest] Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast)
; [nakarest] ("MidiPanelMemoryOutput"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x5b (table 0xe5a012, 17 entries, InitializeEast): "BANK" (Label.str of
; [nakarest] element 5). widget record, element 6 of Viewable slot 0x5b (table 0xe5a012, 17
; [nakarest] entries, InitializeEast) ("MidiPanelMemoryOutput"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast): "VOL"
; [nakarest] (Label.str of element 6). widget record, element 7 of Viewable slot 0x5b (table
; [nakarest] 0xe5a012, 17 entries, InitializeEast) ("MidiPanelMemoryOutput"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x5b (table 0xe5a012, 17 entries,
; [nakarest] InitializeEast): "~95" (Label.str of element 7). widget record, element 8 of
; [nakarest] Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast)
; [nakarest] ("MidiPanelMemoryOutput"): AcPmemOutLGridBox (74 B). text the records point at, in
; [nakarest] Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast):
; [nakarest] "P.MEM:|ON/OFF:|-|PART:" (AcPmemOutLGridBox.fixedrow of element 8); " | "
; [nakarest] (AcPmemOutLGridBox.fixedcol of element 8). widget record, element 9 of Viewable
; [nakarest] slot 0x5b (table 0xe5a012, 17 entries, InitializeEast) ("MidiPanelMemoryOutput"):
; [nakarest] AcPmemOutRGridBox (74 B). text the records point at, in Viewable slot 0x5b (table
; [nakarest] 0xe5a012, 17 entries, InitializeEast): "PRG. CHANGE:|BANK:|VOLUME:"
; [nakarest] (AcPmemOutRGridBox.fixedrow of element 9); " | " (AcPmemOutRGridBox.fixedcol of
; [nakarest] element 9). widget records, elements 10-16 of Viewable slot 0x5b (table 0xe5a012,
; [nakarest] 17 entries, InitializeEast) ("MidiPanelMemoryOutput"): AcIndexEditSw (40 B) x6,
; [nakarest] IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x30D0, 0x322
; [nakarest] naka_midi_reverb+0x33f2  +0x33f2..+0x3600 (0xe5922a, 526 B)
; [nakarest] widget record, element 0 of Viewable slot 0x5c (table 0xe5a05a, 8 entries,
; [nakarest] InitializeEast) ("MidiSetup"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x5c (table 0xe5a05a, 8 entries, InitializeEast): "MIDI SETTINGS LOAD
; [nakarest] OPTION" (TtlScreen.title of element 0). widget record, element 1 of Viewable slot
; [nakarest] 0x5c (table 0xe5a05a, 8 entries, InitializeEast) ("MidiSetup"):
; [nakarest] AcParaLoadOptGridBox (74 B). text the records point at, in Viewable slot 0x5c
; [nakarest] (table 0xe5a05a, 8 entries, InitializeEast): " |-|From Registration file :|From
; [nakarest] Sequencer song" (AcParaLoadOptGridBox.fixedrow of element 1); " | "
; [nakarest] (AcParaLoadOptGridBox.fixedcol of element 1). widget record, element 2 of Viewable
; [nakarest] slot 0x5c (table 0xe5a05a, 8 entries, InitializeEast) ("MidiSetup"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0x5c (table 0xe5a05a, 8 entries,
; [nakarest] InitializeEast): "Load MIDI parameters?" (Label.str of element 2). widget record,
; [nakarest] element 3 of Viewable slot 0x5c (table 0xe5a05a, 8 entries, InitializeEast)
; [nakarest] ("MidiSetup"): Label (32 B). text the records point at, in Viewable slot 0x5c
; [nakarest] (table 0xe5a05a, 8 entries, InitializeEast): "Use these settings when:" (Label.str
; [nakarest] of element 3). widget records, elements 4-7 of Viewable slot 0x5c (table 0xe5a05a,
; [nakarest] 8 entries, InitializeEast) ("MidiSetup"): AcIndexWideES (42 B) x2, AcFuncEditSw (44
; [nakarest] B), IvShowHide (26 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x33F2, 0x20E
; [nakarest] naka_midi_reverb+0x3600  +0x3600..+0x3b70 (0xe59438, 1392 B)
; [nakarest] widget record, element 0 of Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast) ("EntertainerVocal"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast): "VOCALIST
; [nakarest] WORKSTATION" (TtlScreen.title of element 0). widget records, elements 1-6 of
; [nakarest] Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast)
; [nakarest] ("EntertainerVocal"): IvPageControl (28 B) x2, AcWindowPage (36 B), IvShowHide (26
; [nakarest] B), Window (36 B), Label (32 B). text the records point at, in Viewable slot 0xd7
; [nakarest] (table 0xe5a07e, 24 entries, InitializeEast): "PRESET SETTINGS" (Label.str of
; [nakarest] element 6). widget records, elements 7-8 of Viewable slot 0xd7 (table 0xe5a07e, 24
; [nakarest] entries, InitializeEast) ("EntertainerVocal"): VwBox (28 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast): "KN5000 ~95 VOCALIST WORKSTATION" (Label.str of element 8). widget
; [nakarest] records, elements 9-10 of Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast) ("EntertainerVocal"): AcFuncEditSw (44 B), AcVocalistListBox (48
; [nakarest] B). text the records point at, in Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast): " CHORD ~95 CHORDAL PROGRAM | RIGHT1 ~95 CH"
; [nakarest] (AcVocalistListBox.list of element 10). widget records, elements 11-12 of Viewable
; [nakarest] slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast) ("EntertainerVocal"):
; [nakarest] AcIndexWideES (42 B), PsHarmOnOffBox (44 B). text the records point at, in Viewable
; [nakarest] slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast): "HARMONY PART LOCAL: OFF"
; [nakarest] (PsHarmOnOffBox.stroff of element 12); "HARMONY PART LOCAL: ON"
; [nakarest] (PsHarmOnOffBox.stron of element 12). widget records, elements 13-14 of Viewable
; [nakarest] slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast) ("EntertainerVocal"): Window
; [nakarest] (36 B), AcVocalGridBox (74 B). text the records point at, in Viewable slot 0xd7
; [nakarest] (table 0xe5a07e, 24 entries, InitializeEast): " |-|MIDI CHANNEL|PROGRAM |HARMONY
; [nakarest] |KEY " (AcVocalGridBox.fixedrow of element 14); " | | " (AcVocalGridBox.fixedcol of
; [nakarest] element 14). widget record, element 15 of Viewable slot 0xd7 (table 0xe5a07e, 24
; [nakarest] entries, InitializeEast) ("EntertainerVocal"): Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast): "ITEM"
; [nakarest] (Label.str of element 15). widget record, element 16 of Viewable slot 0xd7 (table
; [nakarest] 0xe5a07e, 24 entries, InitializeEast) ("EntertainerVocal"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast): "VALUE" (Label.str of element 16). widget record, element 17 of
; [nakarest] Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast)
; [nakarest] ("EntertainerVocal"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xd7 (table 0xe5a07e, 24 entries, InitializeEast): "SEND" (Label.str of element
; [nakarest] 17). widget record, element 18 of Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast) ("EntertainerVocal"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast): "KEY SPLIT"
; [nakarest] (Label.str of element 18). widget record, element 19 of Viewable slot 0xd7 (table
; [nakarest] 0xe5a07e, 24 entries, InitializeEast) ("EntertainerVocal"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast): "IGNORE" (Label.str of element 19). widget records, elements 20-23
; [nakarest] of Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast)
; [nakarest] ("EntertainerVocal"): AcIndexWideES (42 B) x3, AcFuncEditSw (44 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3600, 0x570
; [nakarest] naka_midi_reverb+0x3b70  +0x3b70..+0x3d46 (0xe599a8, 470 B)
; [nakarest] widget record, element 0 of Viewable slot 0xd8 (table 0xe5a0e2, 8 entries,
; [nakarest] InitializeEast) ("EntertainerFade"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xd8 (table 0xe5a0e2, 8 entries, InitializeEast): "FADE IN/OUT
; [nakarest] SETTING" (TtlScreen.title of element 0). widget record, element 1 of Viewable slot
; [nakarest] 0xd8 (table 0xe5a0e2, 8 entries, InitializeEast) ("EntertainerFade"):
; [nakarest] AcFadeSetGridBox (74 B). text the records point at, in Viewable slot 0xd8 (table
; [nakarest] 0xe5a0e2, 8 entries, InitializeEast): " | Time :| | Time :| "
; [nakarest] (AcFadeSetGridBox.fixedrow of element 1); " | " (AcFadeSetGridBox.fixedcol of
; [nakarest] element 1). widget record, element 2 of Viewable slot 0xd8 (table 0xe5a0e2, 8
; [nakarest] entries, InitializeEast) ("EntertainerFade"): Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0xd8 (table 0xe5a0e2, 8 entries, InitializeEast): "FADE IN"
; [nakarest] (Label.str of element 2). widget record, element 3 of Viewable slot 0xd8 (table
; [nakarest] 0xe5a0e2, 8 entries, InitializeEast) ("EntertainerFade"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xd8 (table 0xe5a0e2, 8 entries,
; [nakarest] InitializeEast): "FADE OUT" (Label.str of element 3). widget records, elements 4-7
; [nakarest] of Viewable slot 0xd8 (table 0xe5a0e2, 8 entries, InitializeEast)
; [nakarest] ("EntertainerFade"): AcIndexWideES (42 B) x2, IvIntEasySet (24 B), IvShowHide (26
; [nakarest] B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3B70, 0x1D6
; [nakarest] naka_midi_reverb+0x3d46  +0x3d46..+0x3e22 (0xe59b7e, 220 B)
; [nakarest] widget record, element 0 of Viewable slot 0xec (table 0xe5a106, 6 entries,
; [nakarest] InitializeEast) ("SplitSetting"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xec (table 0xe5a106, 6 entries, InitializeEast): "SPLIT POINT"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-5 of Viewable slot 0xec
; [nakarest] (table 0xe5a106, 6 entries, InitializeEast) ("SplitSetting"): VwBox (28 B) x2,
; [nakarest] AcLswBox (44 B), IvIntEasySet (24 B), AcLanguageText (42 B).
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3D46, 0xDC
; [nakarest] naka_midi_reverb+0x3e22  +0x3e22..+0x3e36 (0xe59c5a, 20 B)
; [nakarest] the table itself: Viewable slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast), 4
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E22, 0x14
; [nakarest] naka_midi_reverb+0x3e36  +0x3e36..+0x3e46 (0xe59c6e, 16 B)
; [nakarest] the table itself: Viewable slot 0xf (table 0xe59c6e, 3 entries, InitializeEast), 3
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E36, 0x10
; [nakarest] naka_midi_reverb+0x3e46  +0x3e46..+0x3e7a (0xe59c7e, 52 B)
; [nakarest] the table itself: Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E46, 0x34
; [nakarest] naka_midi_reverb+0x3e7a  +0x3e7a..+0x3eae (0xe59cb2, 52 B)
; [nakarest] the table itself: Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E7A, 0x34
; [nakarest] naka_midi_reverb+0x3eae  +0x3eae..+0x3ee2 (0xe59ce6, 52 B)
; [nakarest] the table itself: Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EAE, 0x34
; [nakarest] naka_midi_reverb+0x3ee2  +0x3ee2..+0x3f36 (0xe59d1a, 84 B)
; [nakarest] the table itself: Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast),
; [nakarest] 20 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EE2, 0x54
; [nakarest] naka_midi_reverb+0x3f36  +0x3f36..+0x3f56 (0xe59d6e, 32 B)
; [nakarest] the table itself: Viewable slot 0x51 (table 0xe59d6e, 7 entries, InitializeEast), 7
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F36, 0x20
; [nakarest] naka_midi_reverb+0x3f56  +0x3f56..+0x3f7a (0xe59d8e, 36 B)
; [nakarest] the table itself: Viewable slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast), 8
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F56, 0x24
; [nakarest] naka_midi_reverb+0x3f7a  +0x3f7a..+0x3f96 (0xe59db2, 28 B)
; [nakarest] the table itself: Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F7A, 0x1C
; [nakarest] naka_midi_reverb+0x3f96  +0x3f96..+0x3fae (0xe59dce, 24 B)
; [nakarest] the table itself: Viewable slot 0x54 (table 0xe59dce, 5 entries, InitializeEast), 5
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F96, 0x18
; [nakarest] naka_midi_reverb+0x3fae  +0x3fae..+0x3fc6 (0xe59de6, 24 B)
; [nakarest] the table itself: Viewable slot 0x55 (table 0xe59de6, 5 entries, InitializeEast), 5
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3FAE, 0x18
; [nakarest] naka_midi_reverb+0x3fc6  +0x3fc6..+0x40d6 (0xe59dfe, 272 B)
; [nakarest] the table itself: Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast),
; [nakarest] 67 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3FC6, 0x110
; [nakarest] naka_midi_reverb+0x40d6  +0x40d6..+0x414a (0xe59f0e, 116 B)
; [nakarest] the table itself: Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast),
; [nakarest] 28 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x40D6, 0x74
; [nakarest] naka_midi_reverb+0x414a  +0x414a..+0x41a2 (0xe59f82, 88 B)
; [nakarest] the table itself: Viewable slot 0x58 (table 0xe59f82, 21 entries, InitializeEast),
; [nakarest] 21 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x414A, 0x58
; [nakarest] naka_midi_reverb+0x41a2  +0x41a2..+0x41be (0xe59fda, 28 B)
; [nakarest] the table itself: Viewable slot 0x59 (table 0xe59fda, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x41A2, 0x1C
; [nakarest] naka_midi_reverb+0x41be  +0x41be..+0x41da (0xe59ff6, 28 B)
; [nakarest] the table itself: Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x41BE, 0x1C
; [nakarest] naka_midi_reverb+0x41da  +0x41da..+0x4222 (0xe5a012, 72 B)
; [nakarest] the table itself: Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast),
; [nakarest] 17 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x41DA, 0x48
; [nakarest] naka_midi_reverb+0x4222  +0x4222..+0x4246 (0xe5a05a, 36 B)
; [nakarest] the table itself: Viewable slot 0x5c (table 0xe5a05a, 8 entries, InitializeEast), 8
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4222, 0x24
; [nakarest] naka_midi_reverb+0x4246  +0x4246..+0x42aa (0xe5a07e, 100 B)
; [nakarest] the table itself: Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast),
; [nakarest] 24 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4246, 0x64
; [nakarest] naka_midi_reverb+0x42aa  +0x42aa..+0x42ce (0xe5a0e2, 36 B)
; [nakarest] the table itself: Viewable slot 0xd8 (table 0xe5a0e2, 8 entries, InitializeEast), 8
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x42AA, 0x24
; [nakarest] naka_midi_reverb+0x42ce  +0x42ce..+0x42ea (0xe5a106, 28 B)
; [nakarest] the table itself: Viewable slot 0xec (table 0xe5a106, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x42CE, 0x1C
; [nakarest] naka_midi_reverb+0x42ea  +0x42ea..+0x4300 (0xe5a122, 22 B)
; [nakarest] the table itself: ResName slot 0x309 (table 0xe5a122, 4 entries, InitializeEast), 4
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x42EA, 0x16
; [nakarest] naka_midi_reverb+0x4300  +0x4300..+0x431a (0xe5a138, 26 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x309 (table 0xe5a122, 4 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x9): "", "", "", "ReverbEqualizerMenu".
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4300, 0x1A
; [nakarest] naka_midi_reverb+0x431a  +0x431a..+0x432c (0xe5a152, 18 B)
; [nakarest] the table itself: ResName slot 0x30f (table 0xe5a152, 3 entries, InitializeEast), 3
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x431A, 0x12
; [nakarest] naka_midi_reverb+0x432c  +0x432c..+0x4342 (0xe5a164, 22 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x30f (table 0xe5a152, 3 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0xf): "", "", "R12OctaveSetting".
	.incbin "includes/generated/naka_midi_reverb.bin", 0x432C, 0x16
; [nakarest] naka_midi_reverb+0x4342  +0x4342..+0x4378 (0xe5a17a, 54 B)
; [nakarest] the table itself: ResName slot 0x318 (table 0xe5a17a, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4342, 0x36
; [nakarest] naka_midi_reverb+0x4378  +0x4378..+0x439c (0xe5a1b0, 36 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x318 (table 0xe5a17a, 12 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x18): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4378, 0x24
; [nakarest] naka_midi_reverb+0x439c  +0x439c..+0x43d2 (0xe5a1d4, 54 B)
; [nakarest] the table itself: ResName slot 0x319 (table 0xe5a1d4, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x439C, 0x36
; [nakarest] naka_midi_reverb+0x43d2  +0x43d2..+0x4402 (0xe5a20a, 48 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x319 (table 0xe5a1d4, 12 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x19): "EqOnOffBox", "", "", "", "", "",
; [nakarest] ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x43D2, 0x30
; [nakarest] naka_midi_reverb+0x4402  +0x4402..+0x4438 (0xe5a23a, 54 B)
; [nakarest] the table itself: ResName slot 0x31a (table 0xe5a23a, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4402, 0x36
; [nakarest] naka_midi_reverb+0x4438  +0x4438..+0x4470 (0xe5a270, 56 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x31a (table 0xe5a23a, 12 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x1a): "", "RevEqOnOffBox", "", "", "",
; [nakarest] "", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4438, 0x38
; [nakarest] naka_midi_reverb+0x4470  +0x4470..+0x44c6 (0xe5a2a8, 86 B)
; [nakarest] the table itself: ResName slot 0x350 (table 0xe5a2a8, 20 entries, InitializeEast),
; [nakarest] 20 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4470, 0x56
; [nakarest] naka_midi_reverb+0x44c6  +0x44c6..+0x4518 (0xe5a2fe, 82 B)
; [nakarest] name strings, entries 0-19 of ResName slot 0x350 (table 0xe5a2a8, 20 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x50): "", "", "MidiMenuPage2", "", "",
; [nakarest] "", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x44C6, 0x52
; [nakarest] naka_midi_reverb+0x4518  +0x4518..+0x453a (0xe5a350, 34 B)
; [nakarest] the table itself: ResName slot 0x351 (table 0xe5a350, 7 entries, InitializeEast), 7
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4518, 0x22
; [nakarest] naka_midi_reverb+0x453a  +0x453a..+0x4566 (0xe5a372, 44 B)
; [nakarest] name strings, entries 0-6 of ResName slot 0x351 (table 0xe5a350, 7 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x51): "", "", "", "", "",
; [nakarest] "MdPartSetGridBox", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x453A, 0x2C
; External label offsets within the binary blob above.
