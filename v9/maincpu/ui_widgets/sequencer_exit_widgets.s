
; Sequencer Exit / Mode Widgets (14 widgets, 692 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_exit.c (C struct with named fields)
NakaData_SequencerExit:
	.incbin "includes/generated/naka_sequencer_exit.bin"

; External label offsets within the binary blob above.
	.equ NakaInst_IvRealRecExit, NakaData_SequencerExit + 0x0164
	.equ NakaInst_AcPanicEditSw, NakaData_SequencerExit + 0x0174
	.equ NakaInst_IvAutoPunchExit, NakaData_SequencerExit + 0x0186
	.equ NakaInst_IvPunchExit, NakaData_SequencerExit + 0x0198
	.equ NakaInst_IvSdacc, NakaData_SequencerExit + 0x01a6
	.equ NakaInst_IvSddsp, NakaData_SequencerExit + 0x01b0
	.equ NakaInst_IvSdrev, NakaData_SequencerExit + 0x01ba
	.equ NakaInst_IvPnlWrExit, NakaData_SequencerExit + 0x01c4
	.equ NakaInst_HelpTtl, NakaData_SequencerExit + 0x01d2
	.equ NakaInst_IvPlayExit, NakaData_SequencerExit + 0x01e0
	.equ NakaInst_AcIndexWideToggle, NakaData_SequencerExit + 0x01ee
	.equ NakaInst_MsgToTtl, NakaData_SequencerExit + 0x0204
	.equ NakaInst_EqOnOffFuncToggle, NakaData_SequencerExit + 0x0210
	.equ NakaInst_NoteEditBox, NakaData_SequencerExit + 0x0224
	.equ NakaInst_SngSel2, NakaData_SequencerExit + 0x0234
	.equ NakaInst_SngSel, NakaData_SequencerExit + 0x023e
	.equ NakaInst_AcEntertainerGridBox, NakaData_SequencerExit + 0x024c
	.equ NakaInst_AccIll, NakaData_SequencerExit + 0x0266
	.equ NakaInst_SqedtVal3, NakaData_SequencerExit + 0x0274
	.equ NakaInst_SqplyVal, NakaData_SequencerExit + 0x0282
	.equ NakaInst_IvSongCopyExit, NakaData_SequencerExit + 0x0292
	.equ NakaInst_SqedtFix, NakaData_SequencerExit + 0x02a4
	.equ NakaInst_SqedtVal2_End, NakaData_SequencerExit + 0x02b2
