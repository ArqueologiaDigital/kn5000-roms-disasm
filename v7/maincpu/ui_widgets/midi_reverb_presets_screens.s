
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
NakaInst_AcMidiPartGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x0, 0x16
; [nakarest] NakaInst_AcCtlMsgGridBoxProc  +0x16..+0x2a (0xe55e4e, 20 B)
; [nakarest] name string, entry 14 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcCtlMsgGridBoxProc".
NakaInst_AcCtlMsgGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x16, 0x14
; [nakarest] NakaInst_AcPmemOutRGridBoxProc  +0x2a..+0x40 (0xe55e62, 22 B)
; [nakarest] name string, entry 13 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcPmemOutRGridBoxProc".
NakaInst_AcPmemOutRGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2A, 0x16
; [nakarest] NakaInst_AcPmemOutLGridBoxProc  +0x40..+0x56 (0xe55e78, 22 B)
; [nakarest] name string, entry 12 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcPmemOutLGridBoxProc".
NakaInst_AcPmemOutLGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x40, 0x16
; [nakarest] NakaInst_AcPcgOutGridBoxProc  +0x56..+0x6a (0xe55e8e, 20 B)
; [nakarest] name string, entry 11 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcPcgOutGridBoxProc".
NakaInst_AcPcgOutGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x56, 0x14
; [nakarest] NakaInst_AcParaLoadOptGridBoxProc  +0x6a..+0x84 (0xe55ea2, 26 B)
; [nakarest] name string, entry 10 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcParaLoadOptGridBoxProc".
NakaInst_AcParaLoadOptGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x6A, 0x1A
; [nakarest] NakaInst_AcInOutGridBoxProc  +0x84..+0x98 (0xe55ebc, 20 B)
; [nakarest] name string, entry 9 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcInOutGridBoxProc".
NakaInst_AcInOutGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x84, 0x14
; [nakarest] NakaInst_AcVocalGridBoxProc  +0x98..+0xac (0xe55ed0, 20 B)
; [nakarest] name string, entry 8 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcVocalGridBoxProc".
NakaInst_AcVocalGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x98, 0x14
; [nakarest] NakaInst_AcFadeSetGridBoxProc  +0xac..+0xc2 (0xe55ee4, 22 B)
; [nakarest] name string, entry 7 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcFadeSetGridBoxProc".
NakaInst_AcFadeSetGridBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0xAC, 0x16
; [nakarest] NakaInst_AcLswFuncEditBoxProc  +0xc2..+0xd8 (0xe55efa, 22 B)
; [nakarest] name string, entry 6 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcLswFuncEditBoxProc".
NakaInst_AcLswFuncEditBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0xC2, 0x16
; [nakarest] NakaInst_AcLswFuncBoxProc  +0xd8..+0xea (0xe55f10, 18 B)
; [nakarest] name string, entry 5 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcLswFuncBoxProc".
NakaInst_AcLswFuncBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0xD8, 0x12
; [nakarest] NakaInst_AcGMOnOffBoxProc  +0xea..+0xfc (0xe55f22, 18 B)
; [nakarest] name string, entry 4 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcGMOnOffBoxProc".
NakaInst_AcGMOnOffBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0xEA, 0x12
; [nakarest] NakaInst_AcSendEditSwProc  +0xfc..+0x10e (0xe55f34, 18 B)
; [nakarest] name string, entry 3 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcSendEditSwProc".
NakaInst_AcSendEditSwProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0xFC, 0x12
; [nakarest] NakaInst_IvMpstPageControlProc  +0x10e..+0x124 (0xe55f46, 22 B)
; [nakarest] name string, entry 2 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "IvMpstPageControlProc".
NakaInst_IvMpstPageControlProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x10E, 0x16
; [nakarest] NakaInst_PsHarmOnOffBoxProc  +0x124..+0x138 (0xe55f5c, 20 B)
; [nakarest] name string, entry 1 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "PsHarmOnOffBoxProc".
NakaInst_PsHarmOnOffBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x124, 0x14
; [nakarest] NakaInst_AcVocalistListBoxProc  +0x138..+0x14e (0xe55f70, 22 B)
; [nakarest] name string, entry 0 of Function slot 0x403 (table 0xe55df2, 16 entries,
; [nakarest] InitializeEast) (names for Function slot 0x103): "AcVocalistListBoxProc".
NakaInst_AcVocalistListBoxProc:	.incbin "includes/generated/naka_midi_reverb.bin", 0x138, 0x16
; [nakarest] naka_midi_reverb+0x14e  +0x14e..+0x274 (0xe55f86, 294 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x9 (table 0xe59c5a, 4 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerMenu"): TtlScreen (42 B), AcTitleMenu (54 B) x3. 4
; [nakarest] texts the records point at (Viewable slot 0x9 (table 0xe59c5a, 4 entries,
; [nakarest] InitializeEast)): "REVERB & EQUALIZER PRESETS" (TtlScreen.title of element 0);
; [nakarest] "REVERB PRESETS" (AcTitleMenu.str of element 1); "EQUALIZER PRESETS"
; [nakarest] (AcTitleMenu.str of element 2); "REVERB + EQUALIZER PRESETS" (AcTitleMenu.str of
; [nakarest] element 3).
NakaWidget_ReverbEqualizerMenu:			.incbin "includes/generated/naka_midi_reverb.bin", 0x14E, 0x46
NakaWidget_ReverbEqualizerMenu_1_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0x194, 0x46
NakaWidget_ReverbEqualizerMenu_2_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1DA, 0x48
NakaWidget_ReverbEqualizerMenu_3_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0x222, 0x52
; [nakarest] naka_midi_reverb+0x274  +0x274..+0x324 (0xe560ac, 176 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0xf (table 0xe59c6e, 3 entries,
; [nakarest] InitializeEast) ("R12OctaveSetting"): TtlScreen (42 B), AcLswEditBox (58 B),
; [nakarest] AcIndexWideES (42 B). 2 texts the records point at (Viewable slot 0xf (table
; [nakarest] 0xe59c6e, 3 entries, InitializeEast)): "RIGHT1/RIGHT2 OCTAVE" (TtlScreen.title of
; [nakarest] element 0); "OCTAVE :" (AcLswEditBox.caption of element 1).
NakaWidget_R12OctaveSetting:			.incbin "includes/generated/naka_midi_reverb.bin", 0x274, 0x40
NakaWidget_R12OctaveSetting_1_AcLswEditBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2B4, 0x46
NakaWidget_R12OctaveSetting_2_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2FA, 0x2A
; [nakarest] naka_midi_reverb+0x324  +0x324..+0x5ce (0xe5615c, 682 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; [nakarest] InitializeEast) ("ReverbPreset"): TtlScreen (42 B), AcStrRadioBox (48 B) x10,
; [nakarest] IvCatchEvent (26 B). 11 texts the records point at (Viewable slot 0x18 (table
; [nakarest] 0xe59c7e, 12 entries, InitializeEast)): "REVERB PRESETS" (TtlScreen.title of
; [nakarest] element 0); "Huge Room" (AcStrRadioBox.str of element 1); "Box Room"
; [nakarest] (AcStrRadioBox.str of element 2); "Small Plate" (AcStrRadioBox.str of element 4);
; [nakarest] ....
NakaWidget_ReverbPreset:			.incbin "includes/generated/naka_midi_reverb.bin", 0x324, 0x3A
NakaWidget_ReverbPreset_1_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x35E, 0x3A
NakaWidget_ReverbPreset_2_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x398, 0x3A
NakaWidget_ReverbPreset_3_IvCatchEvent:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3D2, 0x1A
NakaWidget_ReverbPreset_4_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EC, 0x3C
NakaWidget_ReverbPreset_5_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x428, 0x3C
NakaWidget_ReverbPreset_6_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x464, 0x3C
NakaWidget_ReverbPreset_7_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4A0, 0x3E
NakaWidget_ReverbPreset_8_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4DE, 0x3C
NakaWidget_ReverbPreset_9_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x51A, 0x3C
NakaWidget_ReverbPreset_10_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x556, 0x3E
NakaWidget_ReverbPreset_11_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x594, 0x3A
; [nakarest] naka_midi_reverb+0x5ce  +0x5ce..+0x87e (0xe56406, 688 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; [nakarest] InitializeEast) ("EqualizerPreset"): TtlScreen (42 B), AcStrRadioBox (48 B) x9,
; [nakarest] IvCatchEvent (26 B), AcFuncToggle (44 B). 12 texts the records point at (Viewable
; [nakarest] slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast)): "EQUALIZER PRESETS"
; [nakarest] (TtlScreen.title of element 0); "Make Up" (AcStrRadioBox.str of element 1); "Middle
; [nakarest] Cut" (AcStrRadioBox.str of element 2); "Transistor Radio" (AcStrRadioBox.str of
; [nakarest] element 3); ....
NakaWidget_EqualizerPreset:			.incbin "includes/generated/naka_midi_reverb.bin", 0x5CE, 0x3C
NakaWidget_EqualizerPreset_1_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x60A, 0x38
NakaWidget_EqualizerPreset_2_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x642, 0x3C
NakaWidget_EqualizerPreset_3_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x67E, 0x42
NakaWidget_EqualizerPreset_4_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x6C0, 0x3E
NakaWidget_EqualizerPreset_5_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x6FE, 0x3C
NakaWidget_EqualizerPreset_6_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x73A, 0x3A
NakaWidget_EqualizerPreset_7_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x774, 0x3C
NakaWidget_EqualizerPreset_8_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x7B0, 0x3A
NakaWidget_EqualizerPreset_9_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x7EA, 0x3C
NakaWidget_EqualizerPreset_10_IvCatchEvent:	.incbin "includes/generated/naka_midi_reverb.bin", 0x826, 0x1A
NakaWidget_EqOnOffBox:				.incbin "includes/generated/naka_midi_reverb.bin", 0x840, 0x3E
; [nakarest] naka_midi_reverb+0x87e  +0x87e..+0xb32 (0xe566b6, 692 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; [nakarest] InitializeEast) ("ReverbEqualizerPreset"): TtlScreen (42 B), AcStrRadioBox (48 B)
; [nakarest] x9, AcFuncToggle (44 B), IvCatchEvent (26 B). 12 texts the records point at
; [nakarest] (Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast)): "REVERB +
; [nakarest] EQUALIZER PRESETS" (TtlScreen.title of element 0); "Warm & Wide" (AcStrRadioBox.str
; [nakarest] of element 1); "In Your Face" (AcStrRadioBox.str of element 2); "Oil Tank"
; [nakarest] (AcStrRadioBox.str of element 3); ....
NakaWidget_ReverbEqualizerPreset:			.incbin "includes/generated/naka_midi_reverb.bin", 0x87E, 0x46
NakaWidget_ReverbEqualizerPreset_1_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x8C4, 0x3C
NakaWidget_ReverbEqualizerPreset_2_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x900, 0x3E
NakaWidget_ReverbEqualizerPreset_3_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x93E, 0x3A
NakaWidget_ReverbEqualizerPreset_4_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x978, 0x3C
NakaWidget_ReverbEqualizerPreset_5_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x9B4, 0x3E
NakaWidget_ReverbEqualizerPreset_6_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x9F2, 0x3E
NakaWidget_ReverbEqualizerPreset_7_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0xA30, 0x38
NakaWidget_ReverbEqualizerPreset_8_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0xA68, 0x38
NakaWidget_ReverbEqualizerPreset_9_AcStrRadioBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0xAA0, 0x3A
NakaWidget_RevEqOnOffBox:				.incbin "includes/generated/naka_midi_reverb.bin", 0xADA, 0x3E
NakaWidget_ReverbEqualizerPreset_11_IvCatchEvent:	.incbin "includes/generated/naka_midi_reverb.bin", 0xB18, 0x1A
; [nakarest] naka_midi_reverb+0xb32  +0xb32..+0xf9c (0xe5696a, 1130 B)
; [nakarest] widget records, elements 0-19 of Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; [nakarest] InitializeEast) ("MidiMenu"): TtlScreen (42 B), AcWindowPage (36 B), IvPageControl
; [nakarest] (28 B) x2, IvExitMode (26 B), IvShowHide (26 B), Window (36 B) x2, AcTitleMenu (54
; [nakarest] B) x12. 13 texts the records point at (Viewable slot 0x50 (table 0xe59d1a, 20
; [nakarest] entries, InitializeEast)): "MIDI MENU" (TtlScreen.title of element 0); "PART
; [nakarest] SETTING" (AcTitleMenu.str of element 7); "CONTROL MESSAGES" (AcTitleMenu.str of
; [nakarest] element 8); "REALTIME MESSAGES" (AcTitleMenu.str of element 9); ....
NakaWidget_MidiMenu:			.incbin "includes/generated/naka_midi_reverb.bin", 0xB32, 0x34
NakaWidget_MdmenuPage:			.incbin "includes/generated/naka_midi_reverb.bin", 0xB66, 0x24
NakaWidget_MidiMenu_2_IvPageControl:	.incbin "includes/generated/naka_midi_reverb.bin", 0xB8A, 0x1C
NakaWidget_MidiMenu_3_IvPageControl:	.incbin "includes/generated/naka_midi_reverb.bin", 0xBA6, 0x1C
NakaWidget_MidiMenu_4_IvExitMode:	.incbin "includes/generated/naka_midi_reverb.bin", 0xBC2, 0x1A
NakaWidget_MidiMenu_5_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0xBDC, 0x1A
NakaWidget_MidiMenuPage1:		.incbin "includes/generated/naka_midi_reverb.bin", 0xBF6, 0x24
NakaWidget_MidiMenu_7_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xC1A, 0x44
NakaWidget_MidiMenu_8_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xC5E, 0x36
NakaHandler_CtrlMessages:		.incbin "includes/generated/naka_midi_reverb.bin", 0xC94, 0x12
NakaWidget_MidiMenu_9_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xCA6, 0x36
NakaHandler_RealtimeMessages:		.incbin "includes/generated/naka_midi_reverb.bin", 0xCDC, 0x12
NakaWidget_MidiMenu_10_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xCEE, 0x36
NakaHandler_CommonSetting:		.incbin "includes/generated/naka_midi_reverb.bin", 0xD24, 0x10
NakaWidget_MidiMenu_11_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xD34, 0x4C
NakaWidget_MidiMenu_12_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xD80, 0x44
NakaWidget_MidiMenu_13_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xDC4, 0x46
NakaWidget_MidiMenu_14_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xE0A, 0x44
NakaWidget_MidiMenu_15_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xE4E, 0x36
NakaHandler_ProgChangeMidiOut:		.incbin "includes/generated/naka_midi_reverb.bin", 0xE84, 0x16
NakaWidget_MidiMenu_16_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xE9A, 0x44
NakaWidget_MidiMenuPage2:		.incbin "includes/generated/naka_midi_reverb.bin", 0xEDE, 0x24
NakaWidget_MidiMenu_18_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xF02, 0x4A
NakaWidget_MidiMenu_19_AcTitleMenu:	.incbin "includes/generated/naka_midi_reverb.bin", 0xF4C, 0x50
; [nakarest] naka_midi_reverb+0xf9c  +0xf9c..+0x1136 (0xe56dd4, 410 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0x51 (table 0xe59d6e, 7 entries,
; [nakarest] InitializeEast) ("MidiPartSetting"): TtlScreen (42 B), AcMidiPartGridBox (78 B),
; [nakarest] AcIndexWideES (42 B) x4, IvShowHide (26 B). 3 texts the records point at (Viewable
; [nakarest] slot 0x51 (table 0xe59d6e, 7 entries, InitializeEast)): "PART SETTING"
; [nakarest] (TtlScreen.title of element 0); "|-|RIGHT1|RIGHT2|LEFT|PART4|PART5|PART6|PART7|PA"
; [nakarest] (AcMidiPartGridBox.fixedrow of element 1); " PART |CHANNEL|OCTAVE| LOCAL"
; [nakarest] (AcMidiPartGridBox.fixedcol of element 1).
NakaWidget_MidiPartSetting:			.incbin "includes/generated/naka_midi_reverb.bin", 0xF9C, 0x38
NakaWidget_MdPartSetGridBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0xFD4, 0xA0
NakaWidget_MidiPartSetting_2_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1074, 0x2A
NakaWidget_MidiPartSetting_3_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x109E, 0x2A
NakaWidget_MidiPartSetting_4_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x10C8, 0x2A
NakaWidget_MidiPartSetting_5_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x10F2, 0x2A
NakaWidget_MidiPartSetting_6_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x111C, 0x1A
; [nakarest] naka_midi_reverb+0x1136  +0x1136..+0x12f8 (0xe56f6e, 450 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x52 (table 0xe59d8e, 8 entries,
; [nakarest] InitializeEast) ("MidiControlMessage"): TtlScreen (42 B), PsPageBox (32 B),
; [nakarest] AcCtlMsgGridBox (78 B), AcIndexWideES (42 B) x2, Label (32 B) x2, IvShowHide (26
; [nakarest] B). 5 texts the records point at (Viewable slot 0x52 (table 0xe59d8e, 8 entries,
; [nakarest] InitializeEast)): "CONTROL MESSAGES" (TtlScreen.title of element 0);
; [nakarest] "PRG.CHANGE|BANK SELECT|PITCH BEND|VOLUME|EXPRESS" (AcCtlMsgGridBox.fixedrow of
; [nakarest] element 2); " | " (AcCtlMsgGridBox.fixedcol of element 2); "MESSAGE" (Label.str of
; [nakarest] element 4); ....
NakaWidget_MidiControlMessage:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1136, 0x3C
NakaWidget_MidiControlMessage_1_PsPageBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1172, 0x20
NakaWidget_CtlMsgGridBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1192, 0xA8
NakaWidget_MidiControlMessage_3_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x123A, 0x2A
NakaWidget_MidiControlMessage_4_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1264, 0x28
NakaWidget_MidiControlMessage_5_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x128C, 0x28
NakaWidget_MidiControlMessage_6_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x12B4, 0x2A
NakaWidget_MidiControlMessage_7_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x12DE, 0x1A
; [nakarest] naka_midi_reverb+0x12f8  +0x12f8..+0x1476 (0xe57130, 382 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0x53 (table 0xe59db2, 6 entries,
; [nakarest] InitializeEast) ("MidiRealtimeMessage"): TtlScreen (42 B), AcIndexWideES (42 B),
; [nakarest] AcLswFuncEditBox (68 B) x2, Label (32 B), IvShowHide (26 B). 8 texts the records
; [nakarest] point at (Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast)):
; [nakarest] "REALTIME MESSAGES" (TtlScreen.title of element 0); " OFF "
; [nakarest] (AcLswFuncEditBox.off_str of element 2); " ON " (AcLswFuncEditBox.on_str of element
; [nakarest] 2); "REALTIME COMMANDS :" (AcLswFuncEditBox.caption of element 2); ....
NakaWidget_MidiRealtimeMessage:			.incbin "includes/generated/naka_midi_reverb.bin", 0x12F8, 0x3C
NakaWidget_MidiRealtimeMessage_1_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1334, 0x2A
NakaWidget_RealtimeCommandBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x135E, 0x64
NakaWidget_ClockBox:				.incbin "includes/generated/naka_midi_reverb.bin", 0x13C2, 0x74
NakaWidget_MidiRealtimeMessage_4_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1436, 0x26
NakaWidget_MidiRealtimeMessage_5_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x145C, 0x1A
; [nakarest] naka_midi_reverb+0x1476  +0x1476..+0x1642 (0xe572ae, 460 B)
; [nakarest] widget records, elements 0-4 of Viewable slot 0x54 (table 0xe59dce, 5 entries,
; [nakarest] InitializeEast) ("MidiCommonSetting"): TtlScreen (42 B), AcGridBox (74 B),
; [nakarest] AcIndexWideES (42 B) x2, IvShowHide (26 B). 3 texts the records point at (Viewable
; [nakarest] slot 0x54 (table 0xe59dce, 5 entries, InitializeEast)): "COMMON SETTING"
; [nakarest] (TtlScreen.title of element 0); " NOTE ONLY :| PRG.CHANGE TO P.MEM :| R"
; [nakarest] (AcGridBox.fixedrow of element 1); " | " (AcGridBox.fixedcol of element 1).
NakaWidget_MidiCommonSetting:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1476, 0x3A
NakaWidget_ComSetGridBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x14B0, 0x124
NakaWidget_MidiCommonSetting_2_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x15D4, 0x2A
NakaWidget_MidiCommonSetting_3_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x15FE, 0x2A
NakaWidget_MidiCommonSetting_4_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1628, 0x1A
; [nakarest] naka_midi_reverb+0x1642  +0x1642..+0x1800 (0xe5747a, 446 B)
; [nakarest] widget records, elements 0-4 of Viewable slot 0x55 (table 0xe59de6, 5 entries,
; [nakarest] InitializeEast) ("MidiInOutSetting"): TtlScreen (42 B), AcInOutGridBox (74 B),
; [nakarest] AcIndexWideES (42 B) x2, IvShowHide (26 B). 3 texts the records point at (Viewable
; [nakarest] slot 0x55 (table 0xe59de6, 5 entries, InitializeEast)): "INPUT/OUTPUT SETTING"
; [nakarest] (TtlScreen.title of element 0); " RIGHT 1 INPUT :| AUTO PLAY CHORD INPUT"
; [nakarest] (AcInOutGridBox.fixedrow of element 1); " | " (AcInOutGridBox.fixedcol of element
; [nakarest] 1).
NakaWidget_MidiInOutSetting:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1642, 0x40
NakaWidget_InOutGridBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1682, 0x4A
NakaInst_InOutSettingGrid:			.incbin "includes/generated/naka_midi_reverb.bin", 0x16CC, 0xC6
NakaWidget_MidiInOutSetting_2_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1792, 0x2A
NakaWidget_MidiInOutSetting_3_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x17BC, 0x2A
NakaWidget_MidiInOutSetting_4_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x17E6, 0x1A
; [nakarest] naka_midi_reverb+0x1800  +0x1800..+0x1a28 (0xe57638, 552 B)
; [nakarest] widget records, elements 0-12 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): TtlScreen (42 B), AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x2, IvMpstPageControl (32 B) x2, IvShowHide (26 B), Window (36
; [nakarest] B), AcIndexWideES (42 B), AcFuncEditSw (44 B), Label (32 B), VwBox (28 B),
; [nakarest] AcListBox (48 B). 3 texts the records point at (Viewable slot 0x56 (table 0xe59dfe,
; [nakarest] 67 entries, InitializeEast)): "MIDI PRESETS" (TtlScreen.title of element 0);
; [nakarest] "VALUE" (Label.str of element 10); "Organ ~95|Organ Fixed Touch ~95|PX P"
; [nakarest] (AcListBox.list of element 12).
NakaWidget_MidiPresets:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1800, 0x38
NakaWidget_MdPresetPageBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1838, 0x24
NakaWidget_MidiPresets_2_IvPageControl:	.incbin "includes/generated/naka_midi_reverb.bin", 0x185C, 0x1C
NakaWidget_MidiPresets_3_IvPageControl:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1878, 0x1C
NakaWidget_MpstPageCtl1:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1894, 0x20
NakaWidget_MpstPageCtl2:		.incbin "includes/generated/naka_midi_reverb.bin", 0x18B4, 0x20
NakaWidget_MidiPresets_6_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x18D4, 0x1A
NakaWidget_MidiPresetSlaveWithout:	.incbin "includes/generated/naka_midi_reverb.bin", 0x18EE, 0x24
NakaWidget_MidiPresets_8_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1912, 0x2A
NakaWidget_MidiPresets_9_AcFuncEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x193C, 0x2C
NakaWidget_MidiPresets_10_Label:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1968, 0x26
NakaWidget_MidiPresets_11_VwBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x198E, 0x1C
NakaWidget_MpstSlaveWithoutList:	.incbin "includes/generated/naka_midi_reverb.bin", 0x19AA, 0x7E
; [nakarest] NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95  +0x1a28..+0x24b2 (0xe57860, 2698 B)
; [nakarest] Continues 1 text the records point at (Viewable slot 0x56 (table 0xe59dfe, 67
; [nakarest] entries, InitializeEast)): "Organ ~95|Organ Fixed Touch ~95|PX P" (AcListBox.list
; [nakarest] of element 12) (starts 0xe57812, 54 of its 132 bytes are here or later). widget
; [nakarest] records, elements 13-66 of Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; [nakarest] InitializeEast) ("MidiPresets"): AcFuncWideES (46 B) x8, Label (32 B) x18,
; [nakarest] VwUserBitmap (26 B) x4, Window (36 B) x5, VwBox (28 B) x3, AcListBox (48 B) x5,
; [nakarest] AcFuncEditSw (44 B) x5, AcIndexWideES (42 B) x5, AcFuncToggle (44 B). 25 texts the
; [nakarest] records point at (Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast)):
; [nakarest] "WITHOUT APC" (Label.str of element 14); "WITH APC" (Label.str of element 16);
; [nakarest] "KN5000" (Label.str of element 18); "Organ 1 ~95|Organ 2 ~95|Or" (AcListBox.list of
; [nakarest] element 21); ....
NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1A28, 0x36
NakaWidget_MidiPresets_13_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1A5E, 0x14
NakaInst_MidiPresetConfig:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1A72, 0x1A
NakaWidget_MidiPresets_14_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1A8C, 0x2C
NakaWidget_MidiPresets_15_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1AB8, 0x2E
NakaWidget_MidiPresets_16_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1AE6, 0x2A
NakaWidget_MidiPresets_17_VwUserBitmap:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1B10, 0x1A
NakaWidget_MidiPresets_18_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1B2A, 0x20
NakaInst_KN5000_MidiPresets:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1B4A, 0x8
NakaWidget_MidiPresetSlaveWith:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1B52, 0x24
NakaWidget_MidiPresets_20_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1B76, 0x1C
NakaWidget_MpstSlaveWithList:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1B92, 0x100
NakaWidget_MidiPresets_22_VwUserBitmap:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1C92, 0x1A
NakaWidget_MidiPresets_23_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1CAC, 0x28
NakaWidget_MidiPresets_24_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1CD4, 0x2C
NakaWidget_MidiPresets_25_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1D00, 0x2A
NakaWidget_MidiPresets_26_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1D2A, 0x2E
NakaWidget_MidiPresets_27_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1D58, 0x2A
NakaWidget_MidiPresets_28_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1D82, 0x2E
NakaWidget_MidiPresets_29_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1DB0, 0x2C
NakaWidget_MidiPresets_30_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1DDC, 0x26
NakaWidget_MidiPresetPage3:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1E02, 0x24
NakaWidget_MdPresetUserLoadList:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1E26, 0x30
NakaInst_UserSettingSelector:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1E56, 0x34
NakaWidget_MidiPresets_33_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1E8A, 0x2A
NakaWidget_MidiPresets_34_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1EB4, 0x2C
NakaWidget_MidiPresets_35_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1EE0, 0x26
NakaWidget_MidiPresetPage4:			.incbin "includes/generated/naka_midi_reverb.bin", 0x1F06, 0x24
NakaWidget_MdPresetUserWriteList:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1F2A, 0x64
NakaWidget_MidiPresets_38_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x1F8E, 0x2A
NakaWidget_MidiPresets_39_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1FB8, 0x2C
NakaWidget_MidiPresets_40_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x1FE4, 0x26
NakaWidget_MdpstSplitBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x200A, 0x2C
NakaHandler_SplitPointDialog:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2036, 0x32
NakaWidget_MidiPresets_42_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2068, 0x26
NakaWidget_MidiPresetMasterWithout:		.incbin "includes/generated/naka_midi_reverb.bin", 0x208E, 0x24
NakaWidget_MidiPresets_44_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x20B2, 0x1C
NakaWidget_MpstMasterWithoutList:		.incbin "includes/generated/naka_midi_reverb.bin", 0x20CE, 0x30
NakaInst_SndModVocalistExtSeq:			.incbin "includes/generated/naka_midi_reverb.bin", 0x20FE, 0x32
NakaWidget_MidiPresets_46_VwUserBitmap:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2130, 0x1A
NakaWidget_MidiPresets_47_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x214A, 0x20
NakaInst_KN5000_SysexBulkDump:			.incbin "includes/generated/naka_midi_reverb.bin", 0x216A, 0x8
NakaWidget_MidiPresets_48_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2172, 0x2A
NakaWidget_MidiPresets_49_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x219C, 0x2C
NakaWidget_MidiPresets_50_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x21C8, 0x2E
NakaWidget_MidiPresets_51_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x21F6, 0x20
NakaInst_WithAPC_Presets:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2216, 0xA
NakaWidget_MidiPresets_52_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2220, 0x2E
NakaWidget_MidiPresets_53_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x224E, 0x20
NakaInst_WithoutAPC_Presets:			.incbin "includes/generated/naka_midi_reverb.bin", 0x226E, 0xC
NakaWidget_MidiPresets_54_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x227A, 0x20
NakaInst_Value_SysexPresets:			.incbin "includes/generated/naka_midi_reverb.bin", 0x229A, 0x6
NakaWidget_MidiPresetMasterWith:		.incbin "includes/generated/naka_midi_reverb.bin", 0x22A0, 0x24
NakaWidget_MidiPresets_56_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x22C4, 0x1C
NakaWidget_MpstMasterWithList:			.incbin "includes/generated/naka_midi_reverb.bin", 0x22E0, 0x62
NakaWidget_MidiPresets_58_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2342, 0x2C
NakaWidget_MidiPresets_59_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x236E, 0x2A
NakaWidget_MidiPresets_60_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2398, 0x2E
NakaWidget_MidiPresets_61_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x23C6, 0x20
NakaInst_WithAPC_GM:				.incbin "includes/generated/naka_midi_reverb.bin", 0x23E6, 0xA
NakaWidget_MidiPresets_62_AcFuncWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x23F0, 0x2E
NakaWidget_MidiPresets_63_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x241E, 0x20
NakaInst_WithoutAPC_GM:				.incbin "includes/generated/naka_midi_reverb.bin", 0x243E, 0xC
NakaWidget_MidiPresets_64_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x244A, 0x20
NakaInst_Value_GM:				.incbin "includes/generated/naka_midi_reverb.bin", 0x246A, 0x6
NakaWidget_MidiPresets_65_VwUserBitmap:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2470, 0x1A
NakaWidget_MidiPresets_66_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x248A, 0x20
NakaInst_KN5000_GM:				.incbin "includes/generated/naka_midi_reverb.bin", 0x24AA, 0x8
; [nakarest] naka_midi_reverb+0x24b2  +0x24b2..+0x2b1a (0xe582ea, 1640 B)
; [nakarest] widget records, elements 0-27 of Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; [nakarest] InitializeEast) ("MidiExclusive"): TtlScreen (42 B), AcFuncEditSw (44 B), Label (32
; [nakarest] B) x7, AcListBox (48 B), AcIndexWideES (42 B), IvShowHide (26 B), Window (36 B) x2,
; [nakarest] VwBox (28 B) x2, AcRamEditBox (58 B) x10, AcRamBox (44 B) x2. 19 texts the records
; [nakarest] point at (Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast)): "SYSEX
; [nakarest] BULK DUMP" (TtlScreen.title of element 0); "SEND" (Label.str of element 2); "
; [nakarest] PERFORMANCE | CURRENT PANEL + PANEL MEMORY | CO" (AcListBox.list of element 3);
; [nakarest] "SYSTEM EXCLUSIVE" (Label.str of element 7); ....
NakaWidget_MidiExclusive:			.incbin "includes/generated/naka_midi_reverb.bin", 0x24B2, 0x3A
NakaWidget_MidiExclusive_1_AcFuncEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x24EC, 0x2C
NakaWidget_MidiExclusive_2_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2518, 0x26
NakaWidget_ExcListBox:				.incbin "includes/generated/naka_midi_reverb.bin", 0x253E, 0x30
NakaInst_BulkDumpCategorySelect:		.incbin "includes/generated/naka_midi_reverb.bin", 0x256E, 0x5E
NakaWidget_MidiExclusive_4_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x25CC, 0x2A
NakaWidget_MidiExclusive_5_IvShowHide:		.incbin "includes/generated/naka_midi_reverb.bin", 0x25F6, 0x1A
NakaWidget_ExcSendWindow:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2610, 0x24
NakaWidget_MidiExclusive_7_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2634, 0x32
NakaWidget_MidiExclusive_8_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2666, 0x28
NakaWidget_MidiExclusive_9_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x268E, 0x2E
NakaWidget_ExcSendShowBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x26BC, 0x1C
NakaWidget_ExcSendPmemBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x26D8, 0x50
NakaWidget_ExcSendSmemBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2728, 0x50
NakaWidget_ExcSendCmpBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2778, 0x50
NakaWidget_ExcSendSeqBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x27C8, 0x50
NakaWidget_ExcSendMspBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2818, 0x50
NakaWidget_ExcSendDotBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2868, 0x2C
NakaWidget_ExcRcvWindow:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2894, 0x24
NakaWidget_MidiExclusive_18_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x28B8, 0x32
NakaWidget_MidiExclusive_19_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x28EA, 0x20
NakaInst_Receiving_Sysex:			.incbin "includes/generated/naka_midi_reverb.bin", 0x290A, 0xA
NakaWidget_MidiExclusive_20_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2914, 0x2E
NakaWidget_ExcRcvShowBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2942, 0x1C
NakaWidget_ExcRcvPmemBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x295E, 0x50
NakaWidget_ExcRcvSmemBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x29AE, 0x50
NakaWidget_ExcRcvCmpBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x29FE, 0x50
NakaWidget_ExcRcvSeqBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2A4E, 0x50
NakaWidget_ExcRcvMspBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2A9E, 0x50
NakaWidget_ExcRcvDotBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2AEE, 0x2C
; [nakarest] naka_midi_reverb+0x2b1a  +0x2b1a..+0x2e62 (0xe58952, 840 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x58 (table 0xe59f82, 21 entries,
; [nakarest] InitializeEast) ("MidiGmMode"): TtlScreen (42 B), AcGMOnOffBox (54 B),
; [nakarest] AcIndexWideES (42 B), AcFuncEditSw (44 B) x5, IvShowHide (26 B), Window (36 B) x2,
; [nakarest] VwBox (28 B) x2, AcLanguageText (42 B) x6, IvExitWindow (22 B) x2. 2 texts the
; [nakarest] records point at (Viewable slot 0x58 (table 0xe59f82, 21 entries, InitializeEast)):
; [nakarest] "GENERAL MIDI" (TtlScreen.title of element 0); "GENERAL MIDI :"
; [nakarest] (AcGMOnOffBox.caption of element 1).
NakaWidget_MidiGmMode:				.incbin "includes/generated/naka_midi_reverb.bin", 0x2B1A, 0x38
NakaWidget_GMOnOffBox:				.incbin "includes/generated/naka_midi_reverb.bin", 0x2B52, 0x48
NakaWidget_MidiGmMode_2_AcIndexWideES:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2B9A, 0x2A
NakaWidget_MidiGmMode_3_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2BC4, 0x2C
NakaWidget_MidiGmMode_4_IvShowHide:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2BF0, 0x1A
NakaWidget_GMONSure:				.incbin "includes/generated/naka_midi_reverb.bin", 0x2C0A, 0x24
NakaWidget_MidiGmMode_6_VwBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2C2E, 0x1C
NakaWidget_MidiGmMode_7_AcLanguageText:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2C4A, 0x2A
NakaWidget_MidiGmMode_8_AcLanguageText:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2C74, 0x2A
NakaWidget_MidiGmMode_9_AcLanguageText:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2C9E, 0x2A
NakaWidget_MidiGmMode_10_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2CC8, 0x2C
NakaWidget_MidiGmMode_11_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2CF4, 0x2C
NakaWidget_MidiGmMode_12_IvExitWindow:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2D20, 0x16
NakaWidget_GMOFFSure:				.incbin "includes/generated/naka_midi_reverb.bin", 0x2D36, 0x24
NakaWidget_MidiGmMode_14_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2D5A, 0x2C
NakaWidget_MidiGmMode_15_AcFuncEditSw:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2D86, 0x2C
NakaWidget_MidiGmMode_16_IvExitWindow:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2DB2, 0x16
NakaWidget_MidiGmMode_17_VwBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2DC8, 0x1C
NakaWidget_MidiGmMode_18_AcLanguageText:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2DE4, 0x2A
NakaWidget_MidiGmMode_19_AcLanguageText:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2E0E, 0x2A
NakaWidget_MidiGmMode_20_AcLanguageText:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2E38, 0x2A
; [nakarest] naka_midi_reverb+0x2e62  +0x2e62..+0x2fca (0xe58c9a, 360 B)
; [nakarest] widget records, elements 0-3, 5 of Viewable slot 0x59 (table 0xe59fda, 6 entries,
; [nakarest] InitializeEast) ("MidiPcgOutput"): TtlScreen (42 B), AcPcgOutGridBox (74 B),
; [nakarest] AcIndexWideES (42 B) x2, IvShowHide (26 B). 3 texts the records point at (Viewable
; [nakarest] slot 0x59 (table 0xe59fda, 6 entries, InitializeEast)): "PROGRAM CHANGE MIDI OUT"
; [nakarest] (TtlScreen.title of element 0); " MIDI CHANNEL :| PROGRAM CHANGE :| BANK MSB"
; [nakarest] (AcPcgOutGridBox.fixedrow of element 1); " | " (AcPcgOutGridBox.fixedcol of element
; [nakarest] 1).
NakaWidget_MidiPcgOutput:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2E62, 0x42
NakaWidget_PcgOutGridBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2EA4, 0xB2
NakaWidget_MidiPcgOutput_2_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2F56, 0x2A
NakaWidget_MidiPcgOutput_3_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x2F80, 0x30
NakaWidget_MidiPcgOutput_5_IvShowHide:		.incbin "includes/generated/naka_midi_reverb.bin", 0x2FB0, 0x1A
; [nakarest] naka_midi_reverb+0x2fca  +0x2fca..+0x30d0 (0xe58e02, 262 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0x5a (table 0xe59ff6, 6 entries,
; [nakarest] InitializeEast) ("MidiComputerConnection"): TtlScreen (42 B), AcLswEditBox (58 B),
; [nakarest] AcIndexWideES (42 B), VwBox (28 B), Label (32 B), IvShowHide (26 B). 3 texts the
; [nakarest] records point at (Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast)):
; [nakarest] "COMPUTER CONNECTION" (TtlScreen.title of element 0); "MODE :"
; [nakarest] (AcLswEditBox.caption of element 1); "VALUE" (Label.str of element 4).
NakaWidget_MidiComputerConnection:			.incbin "includes/generated/naka_midi_reverb.bin", 0x2FCA, 0x3E
NakaWidget_MidiComputerConnection_1_AcLswEditBox:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3008, 0x42
NakaWidget_MidiComputerConnection_2_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x304A, 0x2A
NakaWidget_MidiComputerConnection_3_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3074, 0x1C
NakaWidget_MidiComputerConnection_4_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3090, 0x26
NakaWidget_MidiComputerConnection_5_IvShowHide:		.incbin "includes/generated/naka_midi_reverb.bin", 0x30B6, 0x1A
; [nakarest] naka_midi_reverb+0x30d0  +0x30d0..+0x33f2 (0xe58f08, 802 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0x5b (table 0xe5a012, 17 entries,
; [nakarest] InitializeEast) ("MidiPanelMemoryOutput"): TtlScreen (42 B), Label (32 B) x7,
; [nakarest] AcPmemOutLGridBox (74 B), AcPmemOutRGridBox (74 B), AcIndexEditSw (40 B) x6,
; [nakarest] IvShowHide (26 B). 12 texts the records point at (Viewable slot 0x5b (table
; [nakarest] 0xe5a012, 17 entries, InitializeEast)): "PANEL MEMORY OUTPUT" (TtlScreen.title of
; [nakarest] element 0); "P.MEM" (Label.str of element 1); "ON/OFF" (Label.str of element 2);
; [nakarest] "PART" (Label.str of element 3); ....
NakaWidget_MidiPanelMemoryOutput:			.incbin "includes/generated/naka_midi_reverb.bin", 0x30D0, 0x3E
NakaWidget_MidiPanelMemoryOutput_1_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x310E, 0x26
NakaWidget_MidiPanelMemoryOutput_2_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3134, 0x28
NakaWidget_MidiPanelMemoryOutput_3_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x315C, 0x26
NakaWidget_MidiPanelMemoryOutput_4_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3182, 0x20
NakaInst_ProgChangeLabel:				.incbin "includes/generated/naka_midi_reverb.bin", 0x31A2, 0x6
NakaWidget_MidiPanelMemoryOutput_5_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x31A8, 0x26
NakaWidget_MidiPanelMemoryOutput_6_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x31CE, 0x24
NakaWidget_MidiPanelMemoryOutput_7_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x31F2, 0x20
NakaInst_P_MEM_ON_OFF_PART:				.incbin "includes/generated/naka_midi_reverb.bin", 0x3212, 0x4
NakaWidget_PmemOutLeft:					.incbin "includes/generated/naka_midi_reverb.bin", 0x3216, 0x66
NakaWidget_PmemOutRight:				.incbin "includes/generated/naka_midi_reverb.bin", 0x327C, 0x6C
NakaWidget_MidiPanelMemoryOutput_10_AcIndexEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x32E8, 0x28
NakaWidget_MidiPanelMemoryOutput_11_AcIndexEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3310, 0x28
NakaWidget_MidiPanelMemoryOutput_12_AcIndexEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3338, 0x28
NakaWidget_MidiPanelMemoryOutput_13_AcIndexEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3360, 0x28
NakaWidget_MidiPanelMemoryOutput_14_AcIndexEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3388, 0x28
NakaWidget_MidiPanelMemoryOutput_15_AcIndexEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x33B0, 0x28
NakaWidget_MidiPanelMemoryOutput_16_IvShowHide:		.incbin "includes/generated/naka_midi_reverb.bin", 0x33D8, 0x1A
; [nakarest] naka_midi_reverb+0x33f2  +0x33f2..+0x3600 (0xe5922a, 526 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x5c (table 0xe5a05a, 8 entries,
; [nakarest] InitializeEast) ("MidiSetup"): TtlScreen (42 B), AcParaLoadOptGridBox (74 B), Label
; [nakarest] (32 B) x2, AcIndexWideES (42 B) x2, AcFuncEditSw (44 B), IvShowHide (26 B). 5 texts
; [nakarest] the records point at (Viewable slot 0x5c (table 0xe5a05a, 8 entries,
; [nakarest] InitializeEast)): "MIDI SETTINGS LOAD OPTION" (TtlScreen.title of element 0); "
; [nakarest] |-|From Registration file :|From Sequencer song" (AcParaLoadOptGridBox.fixedrow of
; [nakarest] element 1); " | " (AcParaLoadOptGridBox.fixedcol of element 1); "Load MIDI
; [nakarest] parameters?" (Label.str of element 2); ....
NakaWidget_MidiSetup:			.incbin "includes/generated/naka_midi_reverb.bin", 0x33F2, 0x44
NakaWidget_MdSetOptGridBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3436, 0xC0
NakaWidget_MidiSetup_2_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x34F6, 0x36
NakaWidget_MidiSetup_3_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x352C, 0x3A
NakaWidget_MidiSetup_4_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3566, 0x2A
NakaWidget_MidiSetup_5_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3590, 0x2A
NakaWidget_MidiSetup_6_AcFuncEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x35BA, 0x2C
NakaWidget_MidiSetup_7_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x35E6, 0x1A
; [nakarest] naka_midi_reverb+0x3600  +0x3600..+0x3b70 (0xe59438, 1392 B)
; [nakarest] widget records, elements 0-23 of Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; [nakarest] InitializeEast) ("EntertainerVocal"): TtlScreen (42 B), IvPageControl (28 B) x2,
; [nakarest] AcWindowPage (36 B), IvShowHide (26 B), Window (36 B) x2, Label (32 B) x7, VwBox
; [nakarest] (28 B), AcFuncEditSw (44 B) x2, AcVocalistListBox (48 B), AcIndexWideES (42 B) x4,
; [nakarest] PsHarmOnOffBox (44 B), AcVocalGridBox (74 B). 13 texts the records point at
; [nakarest] (Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast)): "VOCALIST
; [nakarest] WORKSTATION" (TtlScreen.title of element 0); "PRESET SETTINGS" (Label.str of
; [nakarest] element 6); "KN5000 ~95 VOCALIST WORKSTATION" (Label.str of element 8); " CHORD ~95
; [nakarest] CHORDAL PROGRAM | RIGHT1 ~95 CH" (AcVocalistListBox.list of element 10); ....
NakaWidget_EntertainerVocal:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3600, 0x40
NakaWidget_EntertainerVocal_1_IvPageControl:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3640, 0x1C
NakaWidget_EntertainerVocal_2_IvPageControl:	.incbin "includes/generated/naka_midi_reverb.bin", 0x365C, 0x1C
NakaWidget_VocalistPage:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3678, 0x24
NakaWidget_EntertainerVocal_4_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x369C, 0x1A
NakaWidget_VocalistPage1:			.incbin "includes/generated/naka_midi_reverb.bin", 0x36B6, 0x24
NakaWidget_EntertainerVocal_6_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x36DA, 0x20
NakaInst_PresetSettingsLabel:			.incbin "includes/generated/naka_midi_reverb.bin", 0x36FA, 0x10
NakaWidget_EntertainerVocal_7_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x370A, 0x1C
NakaWidget_EntertainerVocal_8_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3726, 0x40
NakaWidget_EntertainerVocal_9_AcFuncEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3766, 0x2C
NakaWidget_VocalistListBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3792, 0xFC
NakaWidget_EntertainerVocal_11_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x388E, 0x2A
NakaWidget_HarmOnOffBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x38B8, 0x5C
NakaWidget_VocalistPage2:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3914, 0x24
NakaWidget_VocalistPage2Box:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3938, 0xCA
NakaWidget_EntertainerVocal_15_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3A02, 0x20
NakaInst_ItemLabel_RevEqPreset:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3A22, 0x6
NakaWidget_EntertainerVocal_16_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3A28, 0x26
NakaWidget_EntertainerVocal_17_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3A4E, 0x26
NakaWidget_EntertainerVocal_18_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3A74, 0x2A
NakaWidget_EntertainerVocal_19_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3A9E, 0x28
NakaWidget_EntertainerVocal_20_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3AC6, 0x2A
NakaWidget_EntertainerVocal_21_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3AF0, 0x2A
NakaWidget_EntertainerVocal_22_AcFuncEditSw:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3B1A, 0x2C
NakaWidget_EntertainerVocal_23_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3B46, 0x2A
; [nakarest] naka_midi_reverb+0x3b70  +0x3b70..+0x3d46 (0xe599a8, 470 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0xd8 (table 0xe5a0e2, 8 entries,
; [nakarest] InitializeEast) ("EntertainerFade"): TtlScreen (42 B), AcFadeSetGridBox (74 B),
; [nakarest] Label (32 B) x2, AcIndexWideES (42 B) x2, IvIntEasySet (24 B), IvShowHide (26 B). 5
; [nakarest] texts the records point at (Viewable slot 0xd8 (table 0xe5a0e2, 8 entries,
; [nakarest] InitializeEast)): "FADE IN/OUT SETTING" (TtlScreen.title of element 0); " | Time :|
; [nakarest] | Time :| " (AcFadeSetGridBox.fixedrow of element 1); " | "
; [nakarest] (AcFadeSetGridBox.fixedcol of element 1); "FADE IN" (Label.str of element 2); ....
NakaWidget_EntertainerFade:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3B70, 0x3E
NakaWidget_FadeInOutGridBox:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3BAE, 0xC0
NakaWidget_EntertainerFade_2_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3C6E, 0x28
NakaWidget_EntertainerFade_3_Label:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3C96, 0x2A
NakaWidget_EntertainerFade_4_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3CC0, 0x2A
NakaWidget_EntertainerFade_5_AcIndexWideES:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3CEA, 0x2A
NakaWidget_EntertainerFade_6_IvIntEasySet:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3D14, 0x18
NakaWidget_EntertainerFade_7_IvShowHide:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3D2C, 0x1A
; [nakarest] naka_midi_reverb+0x3d46  +0x3d46..+0x3e22 (0xe59b7e, 220 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0xec (table 0xe5a106, 6 entries,
; [nakarest] InitializeEast) ("SplitSetting"): TtlScreen (42 B), VwBox (28 B) x2, AcLswBox (44
; [nakarest] B), IvIntEasySet (24 B), AcLanguageText (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xec (table 0xe5a106, 6 entries, InitializeEast)): "SPLIT POINT"
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_SplitSetting:			.incbin "includes/generated/naka_midi_reverb.bin", 0x3D46, 0x36
NakaWidget_SplitSetting_1_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3D7C, 0x1C
NakaWidget_SplitSetting_2_VwBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3D98, 0x1C
NakaWidget_SplitSetting_3_AcLswBox:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3DB4, 0x2C
NakaWidget_SplitSetting_4_IvIntEasySet:		.incbin "includes/generated/naka_midi_reverb.bin", 0x3DE0, 0x18
NakaWidget_SplitSetting_5_AcLanguageText:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3DF8, 0x2A
; [nakarest] naka_midi_reverb+0x3e22  +0x3e22..+0x3e36 (0xe59c5a, 20 B)
; [nakarest] the table itself: Viewable slot 0x9 (table 0xe59c5a, 4 entries, InitializeEast), 4
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_009:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E22, 0x14
; [nakarest] naka_midi_reverb+0x3e36  +0x3e36..+0x3e46 (0xe59c6e, 16 B)
; [nakarest] the table itself: Viewable slot 0xf (table 0xe59c6e, 3 entries, InitializeEast), 3
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_00F:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E36, 0x10
; [nakarest] naka_midi_reverb+0x3e46  +0x3e46..+0x3e7a (0xe59c7e, 52 B)
; [nakarest] the table itself: Viewable slot 0x18 (table 0xe59c7e, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
East_ViewableTable_018:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E46, 0x34
; [nakarest] naka_midi_reverb+0x3e7a  +0x3e7a..+0x3eae (0xe59cb2, 52 B)
; [nakarest] the table itself: Viewable slot 0x19 (table 0xe59cb2, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
East_ViewableTable_019:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E7A, 0x34
; [nakarest] naka_midi_reverb+0x3eae  +0x3eae..+0x3ee2 (0xe59ce6, 52 B)
; [nakarest] the table itself: Viewable slot 0x1a (table 0xe59ce6, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
East_ViewableTable_01A:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EAE, 0x34
; [nakarest] naka_midi_reverb+0x3ee2  +0x3ee2..+0x3f36 (0xe59d1a, 84 B)
; [nakarest] the table itself: Viewable slot 0x50 (table 0xe59d1a, 20 entries, InitializeEast),
; [nakarest] 20 entry pointers x 4 bytes.
East_ViewableTable_050:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EE2, 0x54
; [nakarest] naka_midi_reverb+0x3f36  +0x3f36..+0x3f56 (0xe59d6e, 32 B)
; [nakarest] the table itself: Viewable slot 0x51 (table 0xe59d6e, 7 entries, InitializeEast), 7
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_051:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F36, 0x20
; [nakarest] naka_midi_reverb+0x3f56  +0x3f56..+0x3f7a (0xe59d8e, 36 B)
; [nakarest] the table itself: Viewable slot 0x52 (table 0xe59d8e, 8 entries, InitializeEast), 8
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_052:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F56, 0x24
; [nakarest] naka_midi_reverb+0x3f7a  +0x3f7a..+0x3f96 (0xe59db2, 28 B)
; [nakarest] the table itself: Viewable slot 0x53 (table 0xe59db2, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_053:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F7A, 0x1C
; [nakarest] naka_midi_reverb+0x3f96  +0x3f96..+0x3fae (0xe59dce, 24 B)
; [nakarest] the table itself: Viewable slot 0x54 (table 0xe59dce, 5 entries, InitializeEast), 5
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_054:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F96, 0x18
; [nakarest] naka_midi_reverb+0x3fae  +0x3fae..+0x3fc6 (0xe59de6, 24 B)
; [nakarest] the table itself: Viewable slot 0x55 (table 0xe59de6, 5 entries, InitializeEast), 5
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_055:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3FAE, 0x18
; [nakarest] naka_midi_reverb+0x3fc6  +0x3fc6..+0x40d6 (0xe59dfe, 272 B)
; [nakarest] the table itself: Viewable slot 0x56 (table 0xe59dfe, 67 entries, InitializeEast),
; [nakarest] 67 entry pointers x 4 bytes.
East_ViewableTable_056:	.incbin "includes/generated/naka_midi_reverb.bin", 0x3FC6, 0x110
; [nakarest] naka_midi_reverb+0x40d6  +0x40d6..+0x414a (0xe59f0e, 116 B)
; [nakarest] the table itself: Viewable slot 0x57 (table 0xe59f0e, 28 entries, InitializeEast),
; [nakarest] 28 entry pointers x 4 bytes.
East_ViewableTable_057:	.incbin "includes/generated/naka_midi_reverb.bin", 0x40D6, 0x74
; [nakarest] naka_midi_reverb+0x414a  +0x414a..+0x41a2 (0xe59f82, 88 B)
; [nakarest] the table itself: Viewable slot 0x58 (table 0xe59f82, 21 entries, InitializeEast),
; [nakarest] 21 entry pointers x 4 bytes.
East_ViewableTable_058:	.incbin "includes/generated/naka_midi_reverb.bin", 0x414A, 0x58
; [nakarest] naka_midi_reverb+0x41a2  +0x41a2..+0x41be (0xe59fda, 28 B)
; [nakarest] the table itself: Viewable slot 0x59 (table 0xe59fda, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_059:	.incbin "includes/generated/naka_midi_reverb.bin", 0x41A2, 0x1C
; [nakarest] naka_midi_reverb+0x41be  +0x41be..+0x41da (0xe59ff6, 28 B)
; [nakarest] the table itself: Viewable slot 0x5a (table 0xe59ff6, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_05A:	.incbin "includes/generated/naka_midi_reverb.bin", 0x41BE, 0x1C
; [nakarest] naka_midi_reverb+0x41da  +0x41da..+0x4222 (0xe5a012, 72 B)
; [nakarest] the table itself: Viewable slot 0x5b (table 0xe5a012, 17 entries, InitializeEast),
; [nakarest] 17 entry pointers x 4 bytes.
East_ViewableTable_05B:	.incbin "includes/generated/naka_midi_reverb.bin", 0x41DA, 0x48
; [nakarest] naka_midi_reverb+0x4222  +0x4222..+0x4246 (0xe5a05a, 36 B)
; [nakarest] the table itself: Viewable slot 0x5c (table 0xe5a05a, 8 entries, InitializeEast), 8
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_05C:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4222, 0x24
; [nakarest] naka_midi_reverb+0x4246  +0x4246..+0x42aa (0xe5a07e, 100 B)
; [nakarest] the table itself: Viewable slot 0xd7 (table 0xe5a07e, 24 entries, InitializeEast),
; [nakarest] 24 entry pointers x 4 bytes.
East_ViewableTable_0D7:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4246, 0x64
; [nakarest] naka_midi_reverb+0x42aa  +0x42aa..+0x42ce (0xe5a0e2, 36 B)
; [nakarest] the table itself: Viewable slot 0xd8 (table 0xe5a0e2, 8 entries, InitializeEast), 8
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_0D8:	.incbin "includes/generated/naka_midi_reverb.bin", 0x42AA, 0x24
; [nakarest] naka_midi_reverb+0x42ce  +0x42ce..+0x42ea (0xe5a106, 28 B)
; [nakarest] the table itself: Viewable slot 0xec (table 0xe5a106, 6 entries, InitializeEast), 6
; [nakarest] entry pointers x 4 bytes.
East_ViewableTable_0EC:	.incbin "includes/generated/naka_midi_reverb.bin", 0x42CE, 0x1C
; [nakarest] naka_midi_reverb+0x42ea  +0x42ea..+0x4300 (0xe5a122, 22 B)
; [nakarest] the table itself: ResName slot 0x309 (table 0xe5a122, 4 entries, InitializeEast), 4
; [nakarest] entry pointers x 4 bytes.
East_ResNameTable_309:	.incbin "includes/generated/naka_midi_reverb.bin", 0x42EA, 0x16
; [nakarest] naka_midi_reverb+0x4300  +0x4300..+0x431a (0xe5a138, 26 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x309 (table 0xe5a122, 4 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x9): "", "", "", "ReverbEqualizerMenu".
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4300, 0x1A
; [nakarest] naka_midi_reverb+0x431a  +0x431a..+0x432c (0xe5a152, 18 B)
; [nakarest] the table itself: ResName slot 0x30f (table 0xe5a152, 3 entries, InitializeEast), 3
; [nakarest] entry pointers x 4 bytes.
East_ResNameTable_30F:	.incbin "includes/generated/naka_midi_reverb.bin", 0x431A, 0x12
; [nakarest] naka_midi_reverb+0x432c  +0x432c..+0x4342 (0xe5a164, 22 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x30f (table 0xe5a152, 3 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0xf): "", "", "R12OctaveSetting".
	.incbin "includes/generated/naka_midi_reverb.bin", 0x432C, 0x16
; [nakarest] naka_midi_reverb+0x4342  +0x4342..+0x4378 (0xe5a17a, 54 B)
; [nakarest] the table itself: ResName slot 0x318 (table 0xe5a17a, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
East_ResNameTable_318:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4342, 0x36
; [nakarest] naka_midi_reverb+0x4378  +0x4378..+0x439c (0xe5a1b0, 36 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x318 (table 0xe5a17a, 12 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x18): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4378, 0x24
; [nakarest] naka_midi_reverb+0x439c  +0x439c..+0x43d2 (0xe5a1d4, 54 B)
; [nakarest] the table itself: ResName slot 0x319 (table 0xe5a1d4, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
East_ResNameTable_319:	.incbin "includes/generated/naka_midi_reverb.bin", 0x439C, 0x36
; [nakarest] naka_midi_reverb+0x43d2  +0x43d2..+0x4402 (0xe5a20a, 48 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x319 (table 0xe5a1d4, 12 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x19): "EqOnOffBox", "", "", "", "", "",
; [nakarest] ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x43D2, 0x30
; [nakarest] naka_midi_reverb+0x4402  +0x4402..+0x4438 (0xe5a23a, 54 B)
; [nakarest] the table itself: ResName slot 0x31a (table 0xe5a23a, 12 entries, InitializeEast),
; [nakarest] 12 entry pointers x 4 bytes.
East_ResNameTable_31A:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4402, 0x36
; [nakarest] naka_midi_reverb+0x4438  +0x4438..+0x4470 (0xe5a270, 56 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x31a (table 0xe5a23a, 12 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x1a): "", "RevEqOnOffBox", "", "", "",
; [nakarest] "", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4438, 0x38
; [nakarest] naka_midi_reverb+0x4470  +0x4470..+0x44c6 (0xe5a2a8, 86 B)
; [nakarest] the table itself: ResName slot 0x350 (table 0xe5a2a8, 20 entries, InitializeEast),
; [nakarest] 20 entry pointers x 4 bytes.
East_ResNameTable_350:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4470, 0x56
; [nakarest] naka_midi_reverb+0x44c6  +0x44c6..+0x4518 (0xe5a2fe, 82 B)
; [nakarest] name strings, entries 0-19 of ResName slot 0x350 (table 0xe5a2a8, 20 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x50): "", "", "MidiMenuPage2", "", "",
; [nakarest] "", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x44C6, 0x52
; [nakarest] naka_midi_reverb+0x4518  +0x4518..+0x453a (0xe5a350, 34 B)
; [nakarest] the table itself: ResName slot 0x351 (table 0xe5a350, 7 entries, InitializeEast), 7
; [nakarest] entry pointers x 4 bytes.
East_ResNameTable_351:	.incbin "includes/generated/naka_midi_reverb.bin", 0x4518, 0x22
; [nakarest] naka_midi_reverb+0x453a  +0x453a..+0x4566 (0xe5a372, 44 B)
; [nakarest] name strings, entries 0-6 of ResName slot 0x351 (table 0xe5a350, 7 entries,
; [nakarest] InitializeEast) (names for Viewable slot 0x51): "", "", "", "", "",
; [nakarest] "MdPartSetGridBox", ....
	.incbin "includes/generated/naka_midi_reverb.bin", 0x453A, 0x2C
; External label offsets within the binary blob above.
