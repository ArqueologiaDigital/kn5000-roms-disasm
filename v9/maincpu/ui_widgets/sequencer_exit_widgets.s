
; Sequencer Exit / Mode Widgets (14 widgets, 692 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_exit.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_sequencer_exit
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
; Class slot 0x168: RegObjTable 0x1600004, ClassProc, 0xe27596,
; 0xe27180, 0x168 in InitializeKubo (sequencer/sequencer_ui.s) -- the
; count, 26, is the word at 0xe27596; RegisterObjectTable stores {class,
; proc, count, table} at 0x27ed2 + 14*0x168.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_SequencerExit  +0x0..+0x14 (0xe272a4, 20 B)
; [nakarest] bytes 4-23 of class definition 12 (NoteEditBox) of Class slot 0x168 (table 0xe27180, 26 entries, InitializeKubo): its parent, allsize, selfsize, name, propdata and propname; its proc word, bytes 0-3, ends the slice before.
NakaData_SequencerExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x0, 0x14
; [nakarest] naka_sequencer_exit+0x14  +0x14..+0x164 (0xe272b8, 336 B)
; [nakarest] class definition entries 13-25 of Class slot 0x168 (table 0xe27180, 26 entries,
; [nakarest] InitializeKubo) (24 bytes each: proc, parent, allsize, selfsize, name, propdata,
; [nakarest] propname): EqOnOffFuncToggle, MsgToTtl, AcIndexWideToggle, IvPlayExit, HelpTtl,
; [nakarest] IvPnlWrExit, IvSdrev, IvSddsp, IvSdacc, IvPunchExit, ....
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x14, 0x150
; [nakarest] NakaInst_IvRealRecExit  +0x164..+0x166 (0xe27408, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 25 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvRealRecExit "".
NakaInst_IvRealRecExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x164, 0x2
; [nakarest] naka_sequencer_exit+0x166  +0x166..+0x174 (0xe2740a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 25 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvRealRecExit.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x166, 0xE
; [nakarest] NakaInst_AcPanicEditSw  +0x174..+0x178 (0xe27418, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 24 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): AcPanicEditSw "fj".
NakaInst_AcPanicEditSw:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x174, 0x4
; [nakarest] naka_sequencer_exit+0x178  +0x178..+0x186 (0xe2741c, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 24 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): AcPanicEditSw.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x178, 0xE
; [nakarest] NakaInst_IvAutoPunchExit  +0x186..+0x188 (0xe2742a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 23 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvAutoPunchExit "".
NakaInst_IvAutoPunchExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x186, 0x2
; [nakarest] naka_sequencer_exit+0x188  +0x188..+0x198 (0xe2742c, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 23 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvAutoPunchExit.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x188, 0x10
; [nakarest] NakaInst_IvPunchExit  +0x198..+0x19a (0xe2743c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 22 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvPunchExit "".
NakaInst_IvPunchExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x198, 0x2
; [nakarest] naka_sequencer_exit+0x19a  +0x19a..+0x1a6 (0xe2743e, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 22 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvPunchExit.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x19A, 0xC
; [nakarest] NakaInst_IvSdacc  +0x1a6..+0x1a8 (0xe2744a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 21 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSdacc "".
NakaInst_IvSdacc:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1A6, 0x2
; [nakarest] naka_sequencer_exit+0x1a8  +0x1a8..+0x1b0 (0xe2744c, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 21 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSdacc.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1A8, 0x8
; [nakarest] NakaInst_IvSddsp  +0x1b0..+0x1b2 (0xe27454, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 20 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSddsp "".
NakaInst_IvSddsp:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1B0, 0x2
; [nakarest] naka_sequencer_exit+0x1b2  +0x1b2..+0x1ba (0xe27456, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 20 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSddsp.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1B2, 0x8
; [nakarest] NakaInst_IvSdrev  +0x1ba..+0x1bc (0xe2745e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 19 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSdrev "".
NakaInst_IvSdrev:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1BA, 0x2
; [nakarest] naka_sequencer_exit+0x1bc  +0x1bc..+0x1c4 (0xe27460, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 19 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSdrev.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1BC, 0x8
; [nakarest] NakaInst_IvPnlWrExit  +0x1c4..+0x1c6 (0xe27468, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 18 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvPnlWrExit "".
NakaInst_IvPnlWrExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1C4, 0x2
; [nakarest] naka_sequencer_exit+0x1c6  +0x1c6..+0x1d2 (0xe2746a, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 18 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvPnlWrExit.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1C6, 0xC
; [nakarest] NakaInst_HelpTtl  +0x1d2..+0x1d8 (0xe27476, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 17 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): HelpTtl "^^cGj".
NakaInst_HelpTtl:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1D2, 0x6
; [nakarest] naka_sequencer_exit+0x1d8  +0x1d8..+0x1e0 (0xe2747c, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 17 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): HelpTtl.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1D8, 0x8
; [nakarest] NakaInst_IvPlayExit  +0x1e0..+0x1e2 (0xe27484, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 16 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvPlayExit "`".
NakaInst_IvPlayExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1E0, 0x2
; [nakarest] naka_sequencer_exit+0x1e2  +0x1e2..+0x1ee (0xe27486, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 16 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvPlayExit.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1E2, 0xC
; [nakarest] NakaInst_AcIndexWideToggle  +0x1ee..+0x1f2 (0xe27492, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 15 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): AcIndexWideToggle "AAj".
NakaInst_AcIndexWideToggle:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1EE, 0x4
; [nakarest] naka_sequencer_exit+0x1f2  +0x1f2..+0x204 (0xe27496, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 15 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): AcIndexWideToggle.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1F2, 0x12
; [nakarest] NakaInst_MsgToTtl  +0x204..+0x206 (0xe274a8, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 14 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): MsgToTtl "".
NakaInst_MsgToTtl:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x204, 0x2
; [nakarest] naka_sequencer_exit+0x206  +0x206..+0x210 (0xe274aa, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 14 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): MsgToTtl.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x206, 0xA
; [nakarest] NakaInst_EqOnOffFuncToggle  +0x210..+0x212 (0xe274b4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 13 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): EqOnOffFuncToggle "".
NakaInst_EqOnOffFuncToggle:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x210, 0x2
; [nakarest] naka_sequencer_exit+0x212  +0x212..+0x224 (0xe274b6, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 13 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): EqOnOffFuncToggle.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x212, 0x12
; [nakarest] NakaInst_NoteEditBox  +0x224..+0x228 (0xe274c8, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 12 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): NoteEditBox "jC".
NakaInst_NoteEditBox:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x224, 0x4
; [nakarest] naka_sequencer_exit+0x228  +0x228..+0x234 (0xe274cc, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 12 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): NoteEditBox.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x228, 0xC
; [nakarest] NakaInst_SngSel2  +0x234..+0x236 (0xe274d8, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 11 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SngSel2 "".
NakaInst_SngSel2:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x234, 0x2
; [nakarest] naka_sequencer_exit+0x236  +0x236..+0x23e (0xe274da, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 11 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SngSel2.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x236, 0x8
; [nakarest] NakaInst_SngSel  +0x23e..+0x244 (0xe274e2, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 10 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SngSel "c^^jC".
NakaInst_SngSel:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x23E, 0x6
; [nakarest] naka_sequencer_exit+0x244  +0x244..+0x24c (0xe274e8, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 10 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SngSel.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x244, 0x8
; [nakarest] NakaInst_AcEntertainerGridBox  +0x24c..+0x250 (0xe274f0, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 9 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): AcEntertainerGridBox "XXj".
NakaInst_AcEntertainerGridBox:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x24C, 0x4
; [nakarest] naka_sequencer_exit+0x250  +0x250..+0x266 (0xe274f4, 22 B)
; [nakarest] class-name strings (the +12 name) of classes 9 of Class slot 0x168 (table 0xe27180,
; [nakarest] 26 entries, InitializeKubo): AcEntertainerGridBox.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x250, 0x16
; [nakarest] NakaInst_AccIll  +0x266..+0x26c (0xe2750a, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 8 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): AccIll "^^jC".
NakaInst_AccIll:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x266, 0x6
; [nakarest] naka_sequencer_exit+0x26c  +0x26c..+0x274 (0xe27510, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 8 of Class slot 0x168 (table 0xe27180,
; [nakarest] 26 entries, InitializeKubo): AccIll.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x26C, 0x8
; [nakarest] NakaInst_SqedtVal3  +0x274..+0x278 (0xe27518, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 7 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SqedtVal3 "^^j".
NakaInst_SqedtVal3:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x274, 0x4
; [nakarest] naka_sequencer_exit+0x278  +0x278..+0x282 (0xe2751c, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 7 of Class slot 0x168 (table 0xe27180,
; [nakarest] 26 entries, InitializeKubo): SqedtVal3.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x278, 0xA
; [nakarest] NakaInst_SqplyVal  +0x282..+0x288 (0xe27526, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 6 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SqplyVal "^^jC".
NakaInst_SqplyVal:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x282, 0x6
; [nakarest] naka_sequencer_exit+0x288  +0x288..+0x292 (0xe2752c, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 6 of Class slot 0x168 (table 0xe27180,
; [nakarest] 26 entries, InitializeKubo): SqplyVal.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x288, 0xA
; [nakarest] NakaInst_IvSongCopyExit  +0x292..+0x294 (0xe27536, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 5 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): IvSongCopyExit "".
NakaInst_IvSongCopyExit:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x292, 0x2
; [nakarest] naka_sequencer_exit+0x294  +0x294..+0x2a4 (0xe27538, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 5 of Class slot 0x168 (table 0xe27180,
; [nakarest] 26 entries, InitializeKubo): IvSongCopyExit.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x294, 0x10
; [nakarest] NakaInst_SqedtFix  +0x2a4..+0x2a8 (0xe27548, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 4 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SqedtFix "^^_".
NakaInst_SqedtFix:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2A4, 0x4
; [nakarest] naka_sequencer_exit+0x2a8  +0x2a8..+0x2b2 (0xe2754c, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 4 of Class slot 0x168 (table 0xe27180,
; [nakarest] 26 entries, InitializeKubo): SqedtFix.
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2A8, 0xA
; [nakarest] NakaInst_SqedtVal2_End  +0x2b2..+0x2b4 (0xe27556, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 3 of Class slot 0x168 (table
; [nakarest] 0xe27180, 26 entries, InitializeKubo): SqedtVal2 "^^j".
NakaInst_SqedtVal2_End:	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2B2, 0x2
; External label offsets within the binary blob above.
