
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
; Class slot 0x168: RegObjTable 0x1600004, ClassProc, 0xe27596,
; 0xe27180, 0x168 in InitializeKubo (sequencer/sequencer_ui.s) -- the
; count, 26, is the word at 0xe27596; RegisterObjectTable stores {class,
; proc, count, table} at 0x27ed2 + 14*0x168.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaData_SequencerExit
; NakaData_SequencerExit  --  naka_sequencer_exit +0x0..+0x14 (ROM 0xe272a4..0xe272b8), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xe272a4..0xe272b8); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaData_SequencerExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x14
; naka_sequencer_exit+0x14  --  naka_sequencer_exit +0x14..+0x164 (ROM 0xe272b8..0xe27408), 336 bytes
; Class definitions 13-25 of Class slot 0x168 (table 0xe27180, 26
; entries, InitializeKubo): EqOnOffFuncToggle, MsgToTtl,
; AcIndexWideToggle, IvPlayExit, HelpTtl, IvPnlWrExit, IvSdrev, IvSddsp,
; IvSdacc, IvPunchExit, .... 24 bytes each: +0 proc, +4 parent (class
; id), +8 allsize, +10 selfsize, +12 name, +16 propdata, +20 propname --
; the firmware's own field names, from the propname table of the root
; class "Class".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x14, 0x150
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvRealRecExit
; NakaInst_IvRealRecExit  --  naka_sequencer_exit +0x164..+0x166 (ROM 0xe27408..0xe2740a), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 25 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvRealRecExit): "".
; -----------------------------------------------------------------------------
NakaInst_IvRealRecExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x164, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x166
; naka_sequencer_exit+0x166  --  naka_sequencer_exit +0x166..+0x174 (ROM 0xe2740a..0xe27418), 14 bytes
; Class-name strings (the +12 name of classes 25 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvRealRecExit.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x166, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcPanicEditSw
; NakaInst_AcPanicEditSw  --  naka_sequencer_exit +0x174..+0x178 (ROM 0xe27418..0xe2741c), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 24 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (AcPanicEditSw): "fj".
; -----------------------------------------------------------------------------
NakaInst_AcPanicEditSw:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x174, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x178
; naka_sequencer_exit+0x178  --  naka_sequencer_exit +0x178..+0x186 (ROM 0xe2741c..0xe2742a), 14 bytes
; Class-name strings (the +12 name of classes 24 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): AcPanicEditSw.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x178, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvAutoPunchExit
; NakaInst_IvAutoPunchExit  --  naka_sequencer_exit +0x186..+0x188 (ROM 0xe2742a..0xe2742c), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 23 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvAutoPunchExit): "".
; -----------------------------------------------------------------------------
NakaInst_IvAutoPunchExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x186, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x188
; naka_sequencer_exit+0x188  --  naka_sequencer_exit +0x188..+0x198 (ROM 0xe2742c..0xe2743c), 16 bytes
; Class-name strings (the +12 name of classes 23 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvAutoPunchExit.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x188, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvPunchExit
; NakaInst_IvPunchExit  --  naka_sequencer_exit +0x198..+0x19a (ROM 0xe2743c..0xe2743e), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 22 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvPunchExit): "".
; -----------------------------------------------------------------------------
NakaInst_IvPunchExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x198, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x19a
; naka_sequencer_exit+0x19a  --  naka_sequencer_exit +0x19a..+0x1a6 (ROM 0xe2743e..0xe2744a), 12 bytes
; Class-name strings (the +12 name of classes 22 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvPunchExit.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x19A, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvSdacc
; NakaInst_IvSdacc  --  naka_sequencer_exit +0x1a6..+0x1a8 (ROM 0xe2744a..0xe2744c), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 21 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvSdacc): "".
; -----------------------------------------------------------------------------
NakaInst_IvSdacc:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1A6, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1a8
; naka_sequencer_exit+0x1a8  --  naka_sequencer_exit +0x1a8..+0x1b0 (ROM 0xe2744c..0xe27454), 8 bytes
; Class-name strings (the +12 name of classes 21 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvSdacc.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1A8, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvSddsp
; NakaInst_IvSddsp  --  naka_sequencer_exit +0x1b0..+0x1b2 (ROM 0xe27454..0xe27456), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 20 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvSddsp): "".
; -----------------------------------------------------------------------------
NakaInst_IvSddsp:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1B0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1b2
; naka_sequencer_exit+0x1b2  --  naka_sequencer_exit +0x1b2..+0x1ba (ROM 0xe27456..0xe2745e), 8 bytes
; Class-name strings (the +12 name of classes 20 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvSddsp.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1B2, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvSdrev
; NakaInst_IvSdrev  --  naka_sequencer_exit +0x1ba..+0x1bc (ROM 0xe2745e..0xe27460), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 19 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvSdrev): "".
; -----------------------------------------------------------------------------
NakaInst_IvSdrev:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1BA, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1bc
; naka_sequencer_exit+0x1bc  --  naka_sequencer_exit +0x1bc..+0x1c4 (ROM 0xe27460..0xe27468), 8 bytes
; Class-name strings (the +12 name of classes 19 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvSdrev.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1BC, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvPnlWrExit
; NakaInst_IvPnlWrExit  --  naka_sequencer_exit +0x1c4..+0x1c6 (ROM 0xe27468..0xe2746a), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 18 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvPnlWrExit): "".
; -----------------------------------------------------------------------------
NakaInst_IvPnlWrExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1C4, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1c6
; naka_sequencer_exit+0x1c6  --  naka_sequencer_exit +0x1c6..+0x1d2 (ROM 0xe2746a..0xe27476), 12 bytes
; Class-name strings (the +12 name of classes 18 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvPnlWrExit.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1C6, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_HelpTtl
; NakaInst_HelpTtl  --  naka_sequencer_exit +0x1d2..+0x1d8 (ROM 0xe27476..0xe2747c), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 17 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (HelpTtl): "^^cGj".
; -----------------------------------------------------------------------------
NakaInst_HelpTtl:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1D2, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1d8
; naka_sequencer_exit+0x1d8  --  naka_sequencer_exit +0x1d8..+0x1e0 (ROM 0xe2747c..0xe27484), 8 bytes
; Class-name strings (the +12 name of classes 17 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): HelpTtl.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1D8, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvPlayExit
; NakaInst_IvPlayExit  --  naka_sequencer_exit +0x1e0..+0x1e2 (ROM 0xe27484..0xe27486), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 16 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvPlayExit): "`".
; -----------------------------------------------------------------------------
NakaInst_IvPlayExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1E0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1e2
; naka_sequencer_exit+0x1e2  --  naka_sequencer_exit +0x1e2..+0x1ee (ROM 0xe27486..0xe27492), 12 bytes
; Class-name strings (the +12 name of classes 16 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvPlayExit.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1E2, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcIndexWideToggle
; NakaInst_AcIndexWideToggle  --  naka_sequencer_exit +0x1ee..+0x1f2 (ROM 0xe27492..0xe27496), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 15 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (AcIndexWideToggle): "AAj".
; -----------------------------------------------------------------------------
NakaInst_AcIndexWideToggle:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1EE, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x1f2
; naka_sequencer_exit+0x1f2  --  naka_sequencer_exit +0x1f2..+0x204 (ROM 0xe27496..0xe274a8), 18 bytes
; Class-name strings (the +12 name of classes 15 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): AcIndexWideToggle.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1F2, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MsgToTtl
; NakaInst_MsgToTtl  --  naka_sequencer_exit +0x204..+0x206 (ROM 0xe274a8..0xe274aa), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 14 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (MsgToTtl): "".
; -----------------------------------------------------------------------------
NakaInst_MsgToTtl:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x204, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x206
; naka_sequencer_exit+0x206  --  naka_sequencer_exit +0x206..+0x210 (ROM 0xe274aa..0xe274b4), 10 bytes
; Class-name strings (the +12 name of classes 14 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): MsgToTtl.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x206, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_EqOnOffFuncToggle
; NakaInst_EqOnOffFuncToggle  --  naka_sequencer_exit +0x210..+0x212 (ROM 0xe274b4..0xe274b6), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 13 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (EqOnOffFuncToggle): "".
; -----------------------------------------------------------------------------
NakaInst_EqOnOffFuncToggle:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x210, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x212
; naka_sequencer_exit+0x212  --  naka_sequencer_exit +0x212..+0x224 (ROM 0xe274b6..0xe274c8), 18 bytes
; Class-name strings (the +12 name of classes 13 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): EqOnOffFuncToggle.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x212, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_NoteEditBox
; NakaInst_NoteEditBox  --  naka_sequencer_exit +0x224..+0x228 (ROM 0xe274c8..0xe274cc), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 12 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (NoteEditBox): "jC".
; -----------------------------------------------------------------------------
NakaInst_NoteEditBox:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x224, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x228
; naka_sequencer_exit+0x228  --  naka_sequencer_exit +0x228..+0x234 (ROM 0xe274cc..0xe274d8), 12 bytes
; Class-name strings (the +12 name of classes 12 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): NoteEditBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x228, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_SngSel2
; NakaInst_SngSel2  --  naka_sequencer_exit +0x234..+0x236 (ROM 0xe274d8..0xe274da), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 11 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (SngSel2): "".
; -----------------------------------------------------------------------------
NakaInst_SngSel2:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x234, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x236
; naka_sequencer_exit+0x236  --  naka_sequencer_exit +0x236..+0x23e (ROM 0xe274da..0xe274e2), 8 bytes
; Class-name strings (the +12 name of classes 11 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): SngSel2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x236, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_SngSel
; NakaInst_SngSel  --  naka_sequencer_exit +0x23e..+0x244 (ROM 0xe274e2..0xe274e8), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 10 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (SngSel): "c^^jC".
; -----------------------------------------------------------------------------
NakaInst_SngSel:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x23E, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x244
; naka_sequencer_exit+0x244  --  naka_sequencer_exit +0x244..+0x24c (ROM 0xe274e8..0xe274f0), 8 bytes
; Class-name strings (the +12 name of classes 10 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): SngSel.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x244, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcEntertainerGridBox
; NakaInst_AcEntertainerGridBox  --  naka_sequencer_exit +0x24c..+0x250 (ROM 0xe274f0..0xe274f4), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 9 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (AcEntertainerGridBox): "XXj".
; -----------------------------------------------------------------------------
NakaInst_AcEntertainerGridBox:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x24C, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x250
; naka_sequencer_exit+0x250  --  naka_sequencer_exit +0x250..+0x266 (ROM 0xe274f4..0xe2750a), 22 bytes
; Class-name strings (the +12 name of classes 9 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): AcEntertainerGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x250, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AccIll
; NakaInst_AccIll  --  naka_sequencer_exit +0x266..+0x26c (ROM 0xe2750a..0xe27510), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 8 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (AccIll): "^^jC".
; -----------------------------------------------------------------------------
NakaInst_AccIll:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x266, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x26c
; naka_sequencer_exit+0x26c  --  naka_sequencer_exit +0x26c..+0x274 (ROM 0xe27510..0xe27518), 8 bytes
; Class-name strings (the +12 name of classes 8 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): AccIll.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x26C, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_SqedtVal3
; NakaInst_SqedtVal3  --  naka_sequencer_exit +0x274..+0x278 (ROM 0xe27518..0xe2751c), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 7 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (SqedtVal3): "^^j".
; -----------------------------------------------------------------------------
NakaInst_SqedtVal3:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x274, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x278
; naka_sequencer_exit+0x278  --  naka_sequencer_exit +0x278..+0x282 (ROM 0xe2751c..0xe27526), 10 bytes
; Class-name strings (the +12 name of classes 7 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): SqedtVal3.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x278, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_SqplyVal
; NakaInst_SqplyVal  --  naka_sequencer_exit +0x282..+0x288 (ROM 0xe27526..0xe2752c), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 6 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (SqplyVal): "^^jC".
; -----------------------------------------------------------------------------
NakaInst_SqplyVal:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x282, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x288
; naka_sequencer_exit+0x288  --  naka_sequencer_exit +0x288..+0x292 (ROM 0xe2752c..0xe27536), 10 bytes
; Class-name strings (the +12 name of classes 6 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): SqplyVal.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x288, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvSongCopyExit
; NakaInst_IvSongCopyExit  --  naka_sequencer_exit +0x292..+0x294 (ROM 0xe27536..0xe27538), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 5 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (IvSongCopyExit): "".
; -----------------------------------------------------------------------------
NakaInst_IvSongCopyExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x292, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x294
; naka_sequencer_exit+0x294  --  naka_sequencer_exit +0x294..+0x2a4 (ROM 0xe27538..0xe27548), 16 bytes
; Class-name strings (the +12 name of classes 5 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): IvSongCopyExit.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x294, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_SqedtFix
; NakaInst_SqedtFix  --  naka_sequencer_exit +0x2a4..+0x2a8 (ROM 0xe27548..0xe2754c), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 4 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (SqedtFix): "^^_".
; -----------------------------------------------------------------------------
NakaInst_SqedtFix:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2A4, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_exit+0x2a8
; naka_sequencer_exit+0x2a8  --  naka_sequencer_exit +0x2a8..+0x2b2 (ROM 0xe2754c..0xe27556), 10 bytes
; Class-name strings (the +12 name of classes 4 of Class slot 0x168
; (table 0xe27180, 26 entries, InitializeKubo)): SqedtFix.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2A8, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_SqedtVal2_End
; NakaInst_SqedtVal2_End  --  naka_sequencer_exit +0x2b2..+0x2b4 (ROM 0xe27556..0xe27558), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 3 of Class slot 0x168 (table 0xe27180, 26 entries,
; InitializeKubo) (SqedtVal2): "^^j".
; -----------------------------------------------------------------------------
NakaInst_SqedtVal2_End:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2B2, 0x2
; External label offsets within the binary blob above.
