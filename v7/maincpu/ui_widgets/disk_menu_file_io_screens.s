
; Disk Menu & File I/O screen widgets (382 widgets, 30944 bytes)
; Source: maincpu/ui_widgets/naka_disk_menu_file_io.c (C struct with named fields)
NakaInst_IvWaitWinCtlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin"

; External label offsets within the binary blob above.
	.equ NakaInst_IvIndexSwDelayProc, NakaInst_IvWaitWinCtlProc + 0x0012
	.equ NakaInst_AcRotStrBoxProc, NakaInst_IvWaitWinCtlProc + 0x0026
	.equ NakaInst_IvIndexSwCtrlProc, NakaInst_IvWaitWinCtlProc + 0x0036
	.equ NakaInst_ArrowProc, NakaInst_IvWaitWinCtlProc + 0x0048
	.equ NakaInst_VwScreenTitleProc, NakaInst_IvWaitWinCtlProc + 0x0052
	.equ NakaInst_IvOneShotTimerProc, NakaInst_IvWaitWinCtlProc + 0x0064
	.equ NakaInst_AcMonoIndexToggleProc, NakaInst_IvWaitWinCtlProc + 0x0078
	.equ NakaInst_AcFileSfxBoxProc, NakaInst_IvWaitWinCtlProc + 0x008e
	.equ NakaInst_AcParaStrBoxProc, NakaInst_IvWaitWinCtlProc + 0x00a0
	.equ NakaInst_AcTtlJgBoxProc, NakaInst_IvWaitWinCtlProc + 0x00b2
	.equ NakaInst_PsWindowToggleProc, NakaInst_IvWaitWinCtlProc + 0x00c2
	.equ NakaInst_PsFileNameBoxProc, NakaInst_IvWaitWinCtlProc + 0x00d6
	.equ Str_DISKNAME, NakaInst_IvWaitWinCtlProc + 0x09ae
	.equ Str_LOAD, NakaInst_IvWaitWinCtlProc + 0x1076
	.equ Str_COMP, NakaInst_IvWaitWinCtlProc + 0x126e
	.equ Str_CUSTOM, NakaInst_IvWaitWinCtlProc + 0x12de
	.equ Str_MIDI, NakaInst_IvWaitWinCtlProc + 0x1306
	.equ Str_RHYTHM_CUSTOM, NakaInst_IvWaitWinCtlProc + 0x13d6
	.equ Str_COMPOSER, NakaInst_IvWaitWinCtlProc + 0x1456
	.equ Str_LOAD_2952, NakaInst_IvWaitWinCtlProc + 0x1586
	.equ Str_SINGLE_LOAD, NakaInst_IvWaitWinCtlProc + 0x15d6
	.equ Str_PREV, NakaInst_IvWaitWinCtlProc + 0x1a5a
	.equ Str_DISK, NakaInst_IvWaitWinCtlProc + 0x1b42
	.equ Str_LOAD_AS, NakaInst_IvWaitWinCtlProc + 0x1b6e
	.equ Str_SOUND_MEMORY, NakaInst_IvWaitWinCtlProc + 0x278e
	.equ Str_SEQUENCER, NakaInst_IvWaitWinCtlProc + 0x27e6
	.equ Str_PERFORM, NakaInst_IvWaitWinCtlProc + 0x295e
	.equ Str_BACKUP, NakaInst_IvWaitWinCtlProc + 0x29ae
	.equ Str_PNL, NakaInst_IvWaitWinCtlProc + 0x29fe
	.equ Str_COMP_3F6A, NakaInst_IvWaitWinCtlProc + 0x2b9e
	.equ Str_CUSTOM_3FDA, NakaInst_IvWaitWinCtlProc + 0x2c0e
	.equ Str_MIDI_4002, NakaInst_IvWaitWinCtlProc + 0x2c36
	.equ Str_ALL_OFF, NakaInst_IvWaitWinCtlProc + 0x2cb6
	.equ Str_SAVE, NakaInst_IvWaitWinCtlProc + 0x2e06
	.equ Str_NEXT, NakaInst_IvWaitWinCtlProc + 0x2f8e
	.equ Str_OFF, NakaInst_IvWaitWinCtlProc + 0x2ff0
	.equ Str_SAVE_44A2, NakaInst_IvWaitWinCtlProc + 0x30d6
	.equ Str_PREV_471A, NakaInst_IvWaitWinCtlProc + 0x334e
	.equ Str_DISKINSERTOPTION, NakaInst_IvWaitWinCtlProc + 0x52ea
	.equ Str_FILETYPEPRIORITY, NakaInst_IvWaitWinCtlProc + 0x533a
	.equ NakaInst_WaitWinCtlSmf, NakaInst_IvWaitWinCtlProc + 0x6a34
