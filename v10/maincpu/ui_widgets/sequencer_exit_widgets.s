
; Sequencer Exit / Mode Widgets (14 widgets, 692 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_exit.c (C struct with named fields)
NakaData_SequencerExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0, 0x164
NakaInst_IvRealRecExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x164, 0x10
NakaInst_AcPanicEditSw:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x174, 0x12
NakaInst_IvAutoPunchExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x186, 0x12
NakaInst_IvPunchExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x198, 0xE
NakaInst_IvSdacc:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1A6, 0xA
NakaInst_IvSddsp:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1B0, 0xA
NakaInst_IvSdrev:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1BA, 0xA
NakaInst_IvPnlWrExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1C4, 0xE
NakaInst_HelpTtl:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1D2, 0xE
NakaInst_IvPlayExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1E0, 0xE
NakaInst_AcIndexWideToggle:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x1EE, 0x16
NakaInst_MsgToTtl:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x204, 0xC
NakaInst_EqOnOffFuncToggle:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x210, 0x14
NakaInst_NoteEditBox:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x224, 0x10
NakaInst_SngSel2:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x234, 0xA
NakaInst_SngSel:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x23E, 0xE
NakaInst_AcEntertainerGridBox:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x24C, 0x1A
NakaInst_AccIll:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x266, 0xE
NakaInst_SqedtVal3:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x274, 0xE
NakaInst_SqplyVal:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x282, 0x10
NakaInst_IvSongCopyExit:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x292, 0x12
NakaInst_SqedtFix:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2A4, 0xE
NakaInst_SqedtVal2_End:
	.incbin "includes/generated/naka_sequencer_exit.bin", 0x2B2, 0x2
; External label offsets within the binary blob above.
