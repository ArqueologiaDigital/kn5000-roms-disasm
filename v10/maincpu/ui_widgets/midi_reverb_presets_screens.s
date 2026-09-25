
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
; already existed. A widget record starts TT 00 6x 01 (TT = type byte);
; +4 parent, +6 first child, +8 next sibling, +10 previous sibling are
; element indices of the same table (0xffff = none), checked against
; each other for every table (the Links result per table). Name strings
; are NUL-terminated and 0xff-padded to even length. The first word of a
; widget record is its CLASS ID 0x016S_KKKK: ClassProc
; (ui/ui_widget_defs.s) takes (id >> 16) & 0xfff as a registry slot --
; the Class table that RegObjTable 0x1600004 put there -- and 0x18 * (id
; & 0xffff) into it. Each class definition gives the instance size (+8
; allsize), and all 3,340 in-ROM widget records of v10 resolve to a
; class and are at least that far apart (THE CLASS SYSTEM,
; scripts/analysis/nakarest_objtab_map.py).
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcMidiPartGridBoxProc
; NakaInst_AcMidiPartGridBoxProc  --  naka_midi_reverb +0x0..+0x16 (ROM 0xe55e38..0xe55e4e), 22 bytes
; Name strings of element 15 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcMidiPartGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcMidiPartGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x0, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcCtlMsgGridBoxProc
; NakaInst_AcCtlMsgGridBoxProc  --  naka_midi_reverb +0x16..+0x2a (ROM 0xe55e4e..0xe55e62), 20 bytes
; Name strings of element 14 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcCtlMsgGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcCtlMsgGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x16, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcPmemOutRGridBoxProc
; NakaInst_AcPmemOutRGridBoxProc  --  naka_midi_reverb +0x2a..+0x40 (ROM 0xe55e62..0xe55e78), 22 bytes
; Name strings of element 13 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcPmemOutRGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcPmemOutRGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2A, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcPmemOutLGridBoxProc
; NakaInst_AcPmemOutLGridBoxProc  --  naka_midi_reverb +0x40..+0x56 (ROM 0xe55e78..0xe55e8e), 22 bytes
; Name strings of element 12 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcPmemOutLGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcPmemOutLGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x40, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcPcgOutGridBoxProc
; NakaInst_AcPcgOutGridBoxProc  --  naka_midi_reverb +0x56..+0x6a (ROM 0xe55e8e..0xe55ea2), 20 bytes
; Name strings of element 11 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcPcgOutGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcPcgOutGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x56, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcParaLoadOptGridBoxProc
; NakaInst_AcParaLoadOptGridBoxProc  --  naka_midi_reverb +0x6a..+0x84 (ROM 0xe55ea2..0xe55ebc), 26 bytes
; Name strings of element 10 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcParaLoadOptGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcParaLoadOptGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x6A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcInOutGridBoxProc
; NakaInst_AcInOutGridBoxProc  --  naka_midi_reverb +0x84..+0x98 (ROM 0xe55ebc..0xe55ed0), 20 bytes
; Name strings of element 9 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcInOutGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcInOutGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x84, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcVocalGridBoxProc
; NakaInst_AcVocalGridBoxProc  --  naka_midi_reverb +0x98..+0xac (ROM 0xe55ed0..0xe55ee4), 20 bytes
; Name strings of element 8 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcVocalGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcVocalGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x98, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcFadeSetGridBoxProc
; NakaInst_AcFadeSetGridBoxProc  --  naka_midi_reverb +0xac..+0xc2 (ROM 0xe55ee4..0xe55efa), 22 bytes
; Name strings of element 7 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcFadeSetGridBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcFadeSetGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xAC, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcLswFuncEditBoxProc
; NakaInst_AcLswFuncEditBoxProc  --  naka_midi_reverb +0xc2..+0xd8 (ROM 0xe55efa..0xe55f10), 22 bytes
; Name strings of element 6 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcLswFuncEditBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcLswFuncEditBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xC2, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcLswFuncBoxProc
; NakaInst_AcLswFuncBoxProc  --  naka_midi_reverb +0xd8..+0xea (ROM 0xe55f10..0xe55f22), 18 bytes
; Name strings of element 5 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcLswFuncBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcLswFuncBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xD8, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcGMOnOffBoxProc
; NakaInst_AcGMOnOffBoxProc  --  naka_midi_reverb +0xea..+0xfc (ROM 0xe55f22..0xe55f34), 18 bytes
; Name strings of element 4 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcGMOnOffBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcGMOnOffBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xEA, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcSendEditSwProc
; NakaInst_AcSendEditSwProc  --  naka_midi_reverb +0xfc..+0x10e (ROM 0xe55f34..0xe55f46), 18 bytes
; Name strings of element 3 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcSendEditSwProc".
; -----------------------------------------------------------------------------
NakaInst_AcSendEditSwProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0xFC, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvMpstPageControlProc
; NakaInst_IvMpstPageControlProc  --  naka_midi_reverb +0x10e..+0x124 (ROM 0xe55f46..0xe55f5c), 22 bytes
; Name strings of element 2 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "IvMpstPageControlProc".
; -----------------------------------------------------------------------------
NakaInst_IvMpstPageControlProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x10E, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_PsHarmOnOffBoxProc
; NakaInst_PsHarmOnOffBoxProc  --  naka_midi_reverb +0x124..+0x138 (ROM 0xe55f5c..0xe55f70), 20 bytes
; Name strings of element 1 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "PsHarmOnOffBoxProc".
; -----------------------------------------------------------------------------
NakaInst_PsHarmOnOffBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x124, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcVocalistListBoxProc
; NakaInst_AcVocalistListBoxProc  --  naka_midi_reverb +0x138..+0x14e (ROM 0xe55f70..0xe55f86), 22 bytes
; Name strings of element 0 of Function slot 0x403 (table 0xe55df2, 16
; entries, InitializeEast), names for Function slot 0x103:
; "AcVocalistListBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcVocalistListBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x138, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x14e
; naka_midi_reverb+0x14e  --  naka_midi_reverb +0x14e..+0x274 (ROM 0xe55f86..0xe560ac), 294 bytes
; Widget records of elements 0-3 of Viewable slot 0x9 (table 0xe59c5a, 4
; entries, InitializeEast), element 0 "ReverbEqualizerMenu"; classes:
; TtlScreen (42 B, id 0x01600034), AcTitleMenu (54 B, id 0x0160001d) x3.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x14E, 0x126
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x274
; naka_midi_reverb+0x274  --  naka_midi_reverb +0x274..+0x324 (ROM 0xe560ac..0xe5615c), 176 bytes
; Widget records of elements 0-2 of Viewable slot 0xf (table 0xe59c6e, 3
; entries, InitializeEast), element 0 "R12OctaveSetting"; classes:
; TtlScreen (42 B, id 0x01600034), AcLswEditBox (58 B, id 0x0160001a),
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x274, 0xB0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x324
; naka_midi_reverb+0x324  --  naka_midi_reverb +0x324..+0x5ce (ROM 0xe5615c..0xe56406), 682 bytes
; Widget records of elements 0-11 of Viewable slot 0x18 (table 0xe59c7e,
; 12 entries, InitializeEast), element 0 "ReverbPreset"; classes:
; TtlScreen (42 B, id 0x01600034), AcStrRadioBox (48 B, id 0x01600051)
; x10, IvCatchEvent (26 B, id 0x01600052).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x324, 0x2AA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x5ce
; naka_midi_reverb+0x5ce  --  naka_midi_reverb +0x5ce..+0x87e (ROM 0xe56406..0xe566b6), 688 bytes
; Widget records of elements 0-11 of Viewable slot 0x19 (table 0xe59cb2,
; 12 entries, InitializeEast), element 0 "EqualizerPreset"; classes:
; TtlScreen (42 B, id 0x01600034), AcStrRadioBox (48 B, id 0x01600051)
; x9, IvCatchEvent (26 B, id 0x01600052), AcFuncToggle (44 B, id
; 0x01600044).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x5CE, 0x2B0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x87e
; naka_midi_reverb+0x87e  --  naka_midi_reverb +0x87e..+0xb32 (ROM 0xe566b6..0xe5696a), 692 bytes
; Widget records of elements 0-11 of Viewable slot 0x1a (table 0xe59ce6,
; 12 entries, InitializeEast), element 0 "ReverbEqualizerPreset";
; classes: TtlScreen (42 B, id 0x01600034), AcStrRadioBox (48 B, id
; 0x01600051) x9, AcFuncToggle (44 B, id 0x01600044), IvCatchEvent (26
; B, id 0x01600052).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x87E, 0x2B4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0xb32
; naka_midi_reverb+0xb32  --  naka_midi_reverb +0xb32..+0xf9c (ROM 0xe5696a..0xe56dd4), 1130 bytes
; Widget records of elements 0-19 of Viewable slot 0x50 (table 0xe59d1a,
; 20 entries, InitializeEast), element 0 "MidiMenu"; classes: TtlScreen
; (42 B, id 0x01600034), AcWindowPage (36 B, id 0x01600025),
; IvPageControl (28 B, id 0x01600028) x2, IvExitMode (26 B, id
; 0x01600048), IvShowHide (26 B, id 0x01600064), Window (36 B, id
; 0x01600035) x2, AcTitleMenu (54 B, id 0x0160001d) x12.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0xB32, 0x46A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0xf9c
; naka_midi_reverb+0xf9c  --  naka_midi_reverb +0xf9c..+0x1136 (ROM 0xe56dd4..0xe56f6e), 410 bytes
; Widget records of elements 0-6 of Viewable slot 0x51 (table 0xe59d6e,
; 7 entries, InitializeEast), element 0 "MidiPartSetting"; classes:
; TtlScreen (42 B, id 0x01600034), AcMidiPartGridBox (78 B, id
; 0x0163000f), AcIndexWideES (42 B, id 0x01600022) x4, IvShowHide (26 B,
; id 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0xF9C, 0x19A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x1136
; naka_midi_reverb+0x1136  --  naka_midi_reverb +0x1136..+0x12f8 (ROM 0xe56f6e..0xe57130), 450 bytes
; Widget records of elements 0-7 of Viewable slot 0x52 (table 0xe59d8e,
; 8 entries, InitializeEast), element 0 "MidiControlMessage"; classes:
; TtlScreen (42 B, id 0x01600034), PsPageBox (32 B, id 0x01600024),
; AcCtlMsgGridBox (78 B, id 0x0163000e), AcIndexWideES (42 B, id
; 0x01600022) x2, Label (32 B, id 0x0160002b) x2, IvShowHide (26 B, id
; 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1136, 0x1C2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x12f8
; naka_midi_reverb+0x12f8  --  naka_midi_reverb +0x12f8..+0x1476 (ROM 0xe57130..0xe572ae), 382 bytes
; Widget records of elements 0-5 of Viewable slot 0x53 (table 0xe59db2,
; 6 entries, InitializeEast), element 0 "MidiRealtimeMessage"; classes:
; TtlScreen (42 B, id 0x01600034), AcIndexWideES (42 B, id 0x01600022),
; AcLswFuncEditBox (68 B, id 0x01630005) x2, Label (32 B, id
; 0x0160002b), IvShowHide (26 B, id 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x12F8, 0x17E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x1476
; naka_midi_reverb+0x1476  --  naka_midi_reverb +0x1476..+0x1642 (ROM 0xe572ae..0xe5747a), 460 bytes
; Widget records of elements 0-4 of Viewable slot 0x54 (table 0xe59dce,
; 5 entries, InitializeEast), element 0 "MidiCommonSetting"; classes:
; TtlScreen (42 B, id 0x01600034), AcGridBox (74 B, id 0x01600056),
; AcIndexWideES (42 B, id 0x01600022) x2, IvShowHide (26 B, id
; 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1476, 0x1CC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x1642
; naka_midi_reverb+0x1642  --  naka_midi_reverb +0x1642..+0x1800 (ROM 0xe5747a..0xe57638), 446 bytes
; Widget records of elements 0-4 of Viewable slot 0x55 (table 0xe59de6,
; 5 entries, InitializeEast), element 0 "MidiInOutSetting"; classes:
; TtlScreen (42 B, id 0x01600034), AcInOutGridBox (74 B, id 0x01630009),
; AcIndexWideES (42 B, id 0x01600022) x2, IvShowHide (26 B, id
; 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1642, 0x1BE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x1800
; naka_midi_reverb+0x1800  --  naka_midi_reverb +0x1800..+0x1a28 (ROM 0xe57638..0xe57860), 552 bytes
; Widget records of elements 0-12 of Viewable slot 0x56 (table 0xe59dfe,
; 67 entries, InitializeEast), element 0 "MidiPresets"; classes:
; TtlScreen (42 B, id 0x01600034), AcWindowPage (36 B, id 0x01600025),
; IvPageControl (28 B, id 0x01600028) x2, IvMpstPageControl (32 B, id
; 0x01630002) x2, IvShowHide (26 B, id 0x01600064), Window (36 B, id
; 0x01600035), AcIndexWideES (42 B, id 0x01600022), AcFuncEditSw (44 B,
; id 0x01600020), Label (32 B, id 0x0160002b), VwBox (28 B, id
; 0x01600011), AcListBox (48 B, id 0x01600055).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1800, 0x228
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95
; NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95  --  naka_midi_reverb +0x1a28..+0x24b2 (ROM 0xe57860..0xe582ea), 2698 bytes
; No RegObjTabl-registered table points at the start of these 54 bytes
; (0xe57860..0xe57896); purpose not established by that route. Widget
; records of elements 13-66 of Viewable slot 0x56 (table 0xe59dfe, 67
; entries, InitializeEast), element 0 "MidiPresets"; classes:
; AcFuncWideES (46 B, id 0x01600023) x8, Label (32 B, id 0x0160002b)
; x18, VwUserBitmap (26 B, id 0x01600069) x4, Window (36 B, id
; 0x01600035) x5, VwBox (28 B, id 0x01600011) x3, AcListBox (48 B, id
; 0x01600055) x5, AcFuncEditSw (44 B, id 0x01600020) x5, AcIndexWideES
; (42 B, id 0x01600022) x5, AcFuncToggle (44 B, id 0x01600044).
; -----------------------------------------------------------------------------
NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95:
	.incbin "includes/generated/naka_midi_reverb.bin", 0x1A28, 0xA8A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x24b2
; naka_midi_reverb+0x24b2  --  naka_midi_reverb +0x24b2..+0x2b1a (ROM 0xe582ea..0xe58952), 1640 bytes
; Widget records of elements 0-27 of Viewable slot 0x57 (table 0xe59f0e,
; 28 entries, InitializeEast), element 0 "MidiExclusive"; classes:
; TtlScreen (42 B, id 0x01600034), AcFuncEditSw (44 B, id 0x01600020),
; Label (32 B, id 0x0160002b) x7, AcListBox (48 B, id 0x01600055),
; AcIndexWideES (42 B, id 0x01600022), IvShowHide (26 B, id 0x01600064),
; Window (36 B, id 0x01600035) x2, VwBox (28 B, id 0x01600011) x2,
; AcRamEditBox (58 B, id 0x0160001b) x10, AcRamBox (44 B, id 0x0160004f)
; x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x24B2, 0x668
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x2b1a
; naka_midi_reverb+0x2b1a  --  naka_midi_reverb +0x2b1a..+0x2e62 (ROM 0xe58952..0xe58c9a), 840 bytes
; Widget records of elements 0-20 of Viewable slot 0x58 (table 0xe59f82,
; 21 entries, InitializeEast), element 0 "MidiGmMode"; classes:
; TtlScreen (42 B, id 0x01600034), AcGMOnOffBox (54 B, id 0x01630004),
; AcIndexWideES (42 B, id 0x01600022), AcFuncEditSw (44 B, id
; 0x01600020) x5, IvShowHide (26 B, id 0x01600064), Window (36 B, id
; 0x01600035) x2, VwBox (28 B, id 0x01600011) x2, AcLanguageText (42 B,
; id 0x01600066) x6, IvExitWindow (22 B, id 0x0160005c) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2B1A, 0x348
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x2e62
; naka_midi_reverb+0x2e62  --  naka_midi_reverb +0x2e62..+0x2fca (ROM 0xe58c9a..0xe58e02), 360 bytes
; Widget records of elements 0-3, 5 of Viewable slot 0x59 (table
; 0xe59fda, 6 entries, InitializeEast), element 0 "MidiPcgOutput";
; classes: TtlScreen (42 B, id 0x01600034), AcPcgOutGridBox (74 B, id
; 0x0163000b), AcIndexWideES (42 B, id 0x01600022) x2, IvShowHide (26 B,
; id 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2E62, 0x168
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x2fca
; naka_midi_reverb+0x2fca  --  naka_midi_reverb +0x2fca..+0x30d0 (ROM 0xe58e02..0xe58f08), 262 bytes
; Widget records of elements 0-5 of Viewable slot 0x5a (table 0xe59ff6,
; 6 entries, InitializeEast), element 0 "MidiComputerConnection";
; classes: TtlScreen (42 B, id 0x01600034), AcLswEditBox (58 B, id
; 0x0160001a), AcIndexWideES (42 B, id 0x01600022), VwBox (28 B, id
; 0x01600011), Label (32 B, id 0x0160002b), IvShowHide (26 B, id
; 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x2FCA, 0x106
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x30d0
; naka_midi_reverb+0x30d0  --  naka_midi_reverb +0x30d0..+0x33f2 (ROM 0xe58f08..0xe5922a), 802 bytes
; Widget records of elements 0-16 of Viewable slot 0x5b (table 0xe5a012,
; 17 entries, InitializeEast), element 0 "MidiPanelMemoryOutput";
; classes: TtlScreen (42 B, id 0x01600034), Label (32 B, id 0x0160002b)
; x7, AcPmemOutLGridBox (74 B, id 0x0163000c), AcPmemOutRGridBox (74 B,
; id 0x0163000d), AcIndexEditSw (40 B, id 0x0160001f) x6, IvShowHide (26
; B, id 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x30D0, 0x322
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x33f2
; naka_midi_reverb+0x33f2  --  naka_midi_reverb +0x33f2..+0x3600 (ROM 0xe5922a..0xe59438), 526 bytes
; Widget records of elements 0-7 of Viewable slot 0x5c (table 0xe5a05a,
; 8 entries, InitializeEast), element 0 "MidiSetup"; classes: TtlScreen
; (42 B, id 0x01600034), AcParaLoadOptGridBox (74 B, id 0x0163000a),
; Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id 0x01600022)
; x2, AcFuncEditSw (44 B, id 0x01600020), IvShowHide (26 B, id
; 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x33F2, 0x20E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3600
; naka_midi_reverb+0x3600  --  naka_midi_reverb +0x3600..+0x3b70 (ROM 0xe59438..0xe599a8), 1392 bytes
; Widget records of elements 0-23 of Viewable slot 0xd7 (table 0xe5a07e,
; 24 entries, InitializeEast), element 0 "EntertainerVocal"; classes:
; TtlScreen (42 B, id 0x01600034), IvPageControl (28 B, id 0x01600028)
; x2, AcWindowPage (36 B, id 0x01600025), IvShowHide (26 B, id
; 0x01600064), Window (36 B, id 0x01600035) x2, Label (32 B, id
; 0x0160002b) x7, VwBox (28 B, id 0x01600011), AcFuncEditSw (44 B, id
; 0x01600020) x2, AcVocalistListBox (48 B, id 0x01630001), AcIndexWideES
; (42 B, id 0x01600022) x4, PsHarmOnOffBox (44 B, id 0x01630000),
; AcVocalGridBox (74 B, id 0x01630008).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3600, 0x570
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3b70
; naka_midi_reverb+0x3b70  --  naka_midi_reverb +0x3b70..+0x3d46 (ROM 0xe599a8..0xe59b7e), 470 bytes
; Widget records of elements 0-7 of Viewable slot 0xd8 (table 0xe5a0e2,
; 8 entries, InitializeEast), element 0 "EntertainerFade"; classes:
; TtlScreen (42 B, id 0x01600034), AcFadeSetGridBox (74 B, id
; 0x01630007), Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id
; 0x01600022) x2, IvIntEasySet (24 B, id 0x01600063), IvShowHide (26 B,
; id 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3B70, 0x1D6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3d46
; naka_midi_reverb+0x3d46  --  naka_midi_reverb +0x3d46..+0x3e22 (ROM 0xe59b7e..0xe59c5a), 220 bytes
; Widget records of elements 0-5 of Viewable slot 0xec (table 0xe5a106,
; 6 entries, InitializeEast), element 0 "SplitSetting"; classes:
; TtlScreen (42 B, id 0x01600034), VwBox (28 B, id 0x01600011) x2,
; AcLswBox (44 B, id 0x01600013), IvIntEasySet (24 B, id 0x01600063),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3D46, 0xDC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3e22
; naka_midi_reverb+0x3e22  --  naka_midi_reverb +0x3e22..+0x3e36 (ROM 0xe59c5a..0xe59c6e), 20 bytes
; The table itself: Viewable slot 0x9 (table 0xe59c5a, 4 entries,
; InitializeEast) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E22, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3e36
; naka_midi_reverb+0x3e36  --  naka_midi_reverb +0x3e36..+0x3e46 (ROM 0xe59c6e..0xe59c7e), 16 bytes
; The table itself: Viewable slot 0xf (table 0xe59c6e, 3 entries,
; InitializeEast) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E36, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3e46
; naka_midi_reverb+0x3e46  --  naka_midi_reverb +0x3e46..+0x3e7a (ROM 0xe59c7e..0xe59cb2), 52 bytes
; The table itself: Viewable slot 0x18 (table 0xe59c7e, 12 entries,
; InitializeEast) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E46, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3e7a
; naka_midi_reverb+0x3e7a  --  naka_midi_reverb +0x3e7a..+0x3eae (ROM 0xe59cb2..0xe59ce6), 52 bytes
; The table itself: Viewable slot 0x19 (table 0xe59cb2, 12 entries,
; InitializeEast) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3E7A, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3eae
; naka_midi_reverb+0x3eae  --  naka_midi_reverb +0x3eae..+0x3ee2 (ROM 0xe59ce6..0xe59d1a), 52 bytes
; The table itself: Viewable slot 0x1a (table 0xe59ce6, 12 entries,
; InitializeEast) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EAE, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3ee2
; naka_midi_reverb+0x3ee2  --  naka_midi_reverb +0x3ee2..+0x3f36 (ROM 0xe59d1a..0xe59d6e), 84 bytes
; The table itself: Viewable slot 0x50 (table 0xe59d1a, 20 entries,
; InitializeEast) -- 20 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3EE2, 0x54
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3f36
; naka_midi_reverb+0x3f36  --  naka_midi_reverb +0x3f36..+0x3f56 (ROM 0xe59d6e..0xe59d8e), 32 bytes
; The table itself: Viewable slot 0x51 (table 0xe59d6e, 7 entries,
; InitializeEast) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F36, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3f56
; naka_midi_reverb+0x3f56  --  naka_midi_reverb +0x3f56..+0x3f7a (ROM 0xe59d8e..0xe59db2), 36 bytes
; The table itself: Viewable slot 0x52 (table 0xe59d8e, 8 entries,
; InitializeEast) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F56, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3f7a
; naka_midi_reverb+0x3f7a  --  naka_midi_reverb +0x3f7a..+0x3f96 (ROM 0xe59db2..0xe59dce), 28 bytes
; The table itself: Viewable slot 0x53 (table 0xe59db2, 6 entries,
; InitializeEast) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F7A, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3f96
; naka_midi_reverb+0x3f96  --  naka_midi_reverb +0x3f96..+0x3fae (ROM 0xe59dce..0xe59de6), 24 bytes
; The table itself: Viewable slot 0x54 (table 0xe59dce, 5 entries,
; InitializeEast) -- 5 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3F96, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3fae
; naka_midi_reverb+0x3fae  --  naka_midi_reverb +0x3fae..+0x3fc6 (ROM 0xe59de6..0xe59dfe), 24 bytes
; The table itself: Viewable slot 0x55 (table 0xe59de6, 5 entries,
; InitializeEast) -- 5 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3FAE, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x3fc6
; naka_midi_reverb+0x3fc6  --  naka_midi_reverb +0x3fc6..+0x40d6 (ROM 0xe59dfe..0xe59f0e), 272 bytes
; The table itself: Viewable slot 0x56 (table 0xe59dfe, 67 entries,
; InitializeEast) -- 67 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x3FC6, 0x110
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x40d6
; naka_midi_reverb+0x40d6  --  naka_midi_reverb +0x40d6..+0x414a (ROM 0xe59f0e..0xe59f82), 116 bytes
; The table itself: Viewable slot 0x57 (table 0xe59f0e, 28 entries,
; InitializeEast) -- 28 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x40D6, 0x74
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x414a
; naka_midi_reverb+0x414a  --  naka_midi_reverb +0x414a..+0x41a2 (ROM 0xe59f82..0xe59fda), 88 bytes
; The table itself: Viewable slot 0x58 (table 0xe59f82, 21 entries,
; InitializeEast) -- 21 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x414A, 0x58
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x41a2
; naka_midi_reverb+0x41a2  --  naka_midi_reverb +0x41a2..+0x41be (ROM 0xe59fda..0xe59ff6), 28 bytes
; The table itself: Viewable slot 0x59 (table 0xe59fda, 6 entries,
; InitializeEast) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x41A2, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x41be
; naka_midi_reverb+0x41be  --  naka_midi_reverb +0x41be..+0x41da (ROM 0xe59ff6..0xe5a012), 28 bytes
; The table itself: Viewable slot 0x5a (table 0xe59ff6, 6 entries,
; InitializeEast) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x41BE, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x41da
; naka_midi_reverb+0x41da  --  naka_midi_reverb +0x41da..+0x4222 (ROM 0xe5a012..0xe5a05a), 72 bytes
; The table itself: Viewable slot 0x5b (table 0xe5a012, 17 entries,
; InitializeEast) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x41DA, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4222
; naka_midi_reverb+0x4222  --  naka_midi_reverb +0x4222..+0x4246 (ROM 0xe5a05a..0xe5a07e), 36 bytes
; The table itself: Viewable slot 0x5c (table 0xe5a05a, 8 entries,
; InitializeEast) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4222, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4246
; naka_midi_reverb+0x4246  --  naka_midi_reverb +0x4246..+0x42aa (ROM 0xe5a07e..0xe5a0e2), 100 bytes
; The table itself: Viewable slot 0xd7 (table 0xe5a07e, 24 entries,
; InitializeEast) -- 24 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4246, 0x64
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x42aa
; naka_midi_reverb+0x42aa  --  naka_midi_reverb +0x42aa..+0x42ce (ROM 0xe5a0e2..0xe5a106), 36 bytes
; The table itself: Viewable slot 0xd8 (table 0xe5a0e2, 8 entries,
; InitializeEast) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x42AA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x42ce
; naka_midi_reverb+0x42ce  --  naka_midi_reverb +0x42ce..+0x42ea (ROM 0xe5a106..0xe5a122), 28 bytes
; The table itself: Viewable slot 0xec (table 0xe5a106, 6 entries,
; InitializeEast) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x42CE, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x42ea
; naka_midi_reverb+0x42ea  --  naka_midi_reverb +0x42ea..+0x4300 (ROM 0xe5a122..0xe5a138), 22 bytes
; The table itself: ResName slot 0x309 (table 0xe5a122, 4 entries,
; InitializeEast) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x42EA, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4300
; naka_midi_reverb+0x4300  --  naka_midi_reverb +0x4300..+0x431a (ROM 0xe5a138..0xe5a152), 26 bytes
; Name strings of elements 0-3 of ResName slot 0x309 (table 0xe5a122, 4
; entries, InitializeEast), names for Viewable slot 0x9: "", "", "",
; "ReverbEqualizerMenu".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4300, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x431a
; naka_midi_reverb+0x431a  --  naka_midi_reverb +0x431a..+0x432c (ROM 0xe5a152..0xe5a164), 18 bytes
; The table itself: ResName slot 0x30f (table 0xe5a152, 3 entries,
; InitializeEast) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x431A, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x432c
; naka_midi_reverb+0x432c  --  naka_midi_reverb +0x432c..+0x4342 (ROM 0xe5a164..0xe5a17a), 22 bytes
; Name strings of elements 0-2 of ResName slot 0x30f (table 0xe5a152, 3
; entries, InitializeEast), names for Viewable slot 0xf: "", "",
; "R12OctaveSetting".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x432C, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4342
; naka_midi_reverb+0x4342  --  naka_midi_reverb +0x4342..+0x4378 (ROM 0xe5a17a..0xe5a1b0), 54 bytes
; The table itself: ResName slot 0x318 (table 0xe5a17a, 12 entries,
; InitializeEast) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4342, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4378
; naka_midi_reverb+0x4378  --  naka_midi_reverb +0x4378..+0x439c (ROM 0xe5a1b0..0xe5a1d4), 36 bytes
; Name strings of elements 0-11 of ResName slot 0x318 (table 0xe5a17a,
; 12 entries, InitializeEast), names for Viewable slot 0x18: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4378, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x439c
; naka_midi_reverb+0x439c  --  naka_midi_reverb +0x439c..+0x43d2 (ROM 0xe5a1d4..0xe5a20a), 54 bytes
; The table itself: ResName slot 0x319 (table 0xe5a1d4, 12 entries,
; InitializeEast) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x439C, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x43d2
; naka_midi_reverb+0x43d2  --  naka_midi_reverb +0x43d2..+0x4402 (ROM 0xe5a20a..0xe5a23a), 48 bytes
; Name strings of elements 0-11 of ResName slot 0x319 (table 0xe5a1d4,
; 12 entries, InitializeEast), names for Viewable slot 0x19:
; "EqOnOffBox", "", "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x43D2, 0x30
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4402
; naka_midi_reverb+0x4402  --  naka_midi_reverb +0x4402..+0x4438 (ROM 0xe5a23a..0xe5a270), 54 bytes
; The table itself: ResName slot 0x31a (table 0xe5a23a, 12 entries,
; InitializeEast) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4402, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4438
; naka_midi_reverb+0x4438  --  naka_midi_reverb +0x4438..+0x4470 (ROM 0xe5a270..0xe5a2a8), 56 bytes
; Name strings of elements 0-11 of ResName slot 0x31a (table 0xe5a23a,
; 12 entries, InitializeEast), names for Viewable slot 0x1a: "",
; "RevEqOnOffBox", "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4438, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4470
; naka_midi_reverb+0x4470  --  naka_midi_reverb +0x4470..+0x44c6 (ROM 0xe5a2a8..0xe5a2fe), 86 bytes
; The table itself: ResName slot 0x350 (table 0xe5a2a8, 20 entries,
; InitializeEast) -- 20 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4470, 0x56
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x44c6
; naka_midi_reverb+0x44c6  --  naka_midi_reverb +0x44c6..+0x4518 (ROM 0xe5a2fe..0xe5a350), 82 bytes
; Name strings of elements 0-19 of ResName slot 0x350 (table 0xe5a2a8,
; 20 entries, InitializeEast), names for Viewable slot 0x50: "", "",
; "MidiMenuPage2", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x44C6, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x4518
; naka_midi_reverb+0x4518  --  naka_midi_reverb +0x4518..+0x453a (ROM 0xe5a350..0xe5a372), 34 bytes
; The table itself: ResName slot 0x351 (table 0xe5a350, 7 entries,
; InitializeEast) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x4518, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_midi_reverb+0x453a
; naka_midi_reverb+0x453a  --  naka_midi_reverb +0x453a..+0x4566 (ROM 0xe5a372..0xe5a39e), 44 bytes
; Name strings of elements 0-6 of ResName slot 0x351 (table 0xe5a350, 7
; entries, InitializeEast), names for Viewable slot 0x51: "", "", "",
; "", "", "MdPartSetGridBox", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_midi_reverb.bin", 0x453A, 0x2C
; External label offsets within the binary blob above.
