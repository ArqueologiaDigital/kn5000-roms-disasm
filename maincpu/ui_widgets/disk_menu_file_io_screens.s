
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
	.equ NakaInst_AcFileSfxBoxProc, NakaInst_IvWaitWinCtlProc + 0x008E
	.equ NakaInst_AcParaStrBoxProc, NakaInst_IvWaitWinCtlProc + 0x00A0
	.equ NakaInst_AcTtlJgBoxProc, NakaInst_IvWaitWinCtlProc + 0x00B2
	.equ NakaInst_PsWindowToggleProc, NakaInst_IvWaitWinCtlProc + 0x00C2
	.equ NakaInst_PsFileNameBoxProc, NakaInst_IvWaitWinCtlProc + 0x00D6
	.equ LABEL_EA1D7A, NakaInst_IvWaitWinCtlProc + 0x09AE
	.equ Str_LOAD, NakaInst_IvWaitWinCtlProc + 0x1076
	.equ Str_COMP, NakaInst_IvWaitWinCtlProc + 0x126E
	.equ Str_CUSTOM, NakaInst_IvWaitWinCtlProc + 0x12DE
	.equ Str_MIDI, NakaInst_IvWaitWinCtlProc + 0x1306
	.equ Str_RHYTHM_CUSTOM, NakaInst_IvWaitWinCtlProc + 0x13D6
	.equ Str_COMPOSER, NakaInst_IvWaitWinCtlProc + 0x1456
	.equ Str_LOAD_2952, NakaInst_IvWaitWinCtlProc + 0x1586
	.equ Str_SINGLE_LOAD, NakaInst_IvWaitWinCtlProc + 0x15D6
	.equ Str_PREV, NakaInst_IvWaitWinCtlProc + 0x1A5A
	.equ Str_DISK, NakaInst_IvWaitWinCtlProc + 0x1B42
	.equ Str_LOAD_AS, NakaInst_IvWaitWinCtlProc + 0x1B6E
	.equ Str_SOUND_MEMORY, NakaInst_IvWaitWinCtlProc + 0x278E
	.equ Str_SEQUENCER, NakaInst_IvWaitWinCtlProc + 0x27E6
	.equ Str_PERFORM, NakaInst_IvWaitWinCtlProc + 0x295E
	.equ Str_BACKUP, NakaInst_IvWaitWinCtlProc + 0x29AE
	.equ LABEL_EA3DCA, NakaInst_IvWaitWinCtlProc + 0x29FE
	.equ Str_COMP_3F6A, NakaInst_IvWaitWinCtlProc + 0x2B9E
	.equ Str_CUSTOM_3FDA, NakaInst_IvWaitWinCtlProc + 0x2C0E
	.equ Str_MIDI_4002, NakaInst_IvWaitWinCtlProc + 0x2C36
	.equ Str_ALL_OFF, NakaInst_IvWaitWinCtlProc + 0x2CB6
	.equ Str_SAVE, NakaInst_IvWaitWinCtlProc + 0x2E06
	.equ Str_NEXT, NakaInst_IvWaitWinCtlProc + 0x2F8E
	.equ LABEL_EA43BC, NakaInst_IvWaitWinCtlProc + 0x2FF0
	.equ Str_SAVE_44A2, NakaInst_IvWaitWinCtlProc + 0x30D6
	.equ Str_PREV_471A, NakaInst_IvWaitWinCtlProc + 0x334E
	.equ LABEL_EA66B6, NakaInst_IvWaitWinCtlProc + 0x52EA
	.equ LABEL_EA6706, NakaInst_IvWaitWinCtlProc + 0x533A
	.equ NakaInst_WaitWinCtlSmf, NakaInst_IvWaitWinCtlProc + 0x6A34
