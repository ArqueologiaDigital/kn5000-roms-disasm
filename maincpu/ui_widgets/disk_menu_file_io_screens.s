
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
	.equ LABEL_EA2442, NakaInst_IvWaitWinCtlProc + 0x1076
	.equ LABEL_EA263A, NakaInst_IvWaitWinCtlProc + 0x126E
	.equ LABEL_EA26AA, NakaInst_IvWaitWinCtlProc + 0x12DE
	.equ LABEL_EA26D2, NakaInst_IvWaitWinCtlProc + 0x1306
	.equ LABEL_EA27A2, NakaInst_IvWaitWinCtlProc + 0x13D6
	.equ LABEL_EA2822, NakaInst_IvWaitWinCtlProc + 0x1456
	.equ LABEL_EA2952, NakaInst_IvWaitWinCtlProc + 0x1586
	.equ LABEL_EA29A2, NakaInst_IvWaitWinCtlProc + 0x15D6
	.equ LABEL_EA2E26, NakaInst_IvWaitWinCtlProc + 0x1A5A
	.equ LABEL_EA2F0E, NakaInst_IvWaitWinCtlProc + 0x1B42
	.equ LABEL_EA2F3A, NakaInst_IvWaitWinCtlProc + 0x1B6E
	.equ LABEL_EA3B5A, NakaInst_IvWaitWinCtlProc + 0x278E
	.equ LABEL_EA3BB2, NakaInst_IvWaitWinCtlProc + 0x27E6
	.equ LABEL_EA3D2A, NakaInst_IvWaitWinCtlProc + 0x295E
	.equ LABEL_EA3D7A, NakaInst_IvWaitWinCtlProc + 0x29AE
	.equ LABEL_EA3DCA, NakaInst_IvWaitWinCtlProc + 0x29FE
	.equ LABEL_EA3F6A, NakaInst_IvWaitWinCtlProc + 0x2B9E
	.equ LABEL_EA3FDA, NakaInst_IvWaitWinCtlProc + 0x2C0E
	.equ LABEL_EA4002, NakaInst_IvWaitWinCtlProc + 0x2C36
	.equ LABEL_EA4082, NakaInst_IvWaitWinCtlProc + 0x2CB6
	.equ LABEL_EA41D2, NakaInst_IvWaitWinCtlProc + 0x2E06
	.equ LABEL_EA435A, NakaInst_IvWaitWinCtlProc + 0x2F8E
	.equ LABEL_EA43BC, NakaInst_IvWaitWinCtlProc + 0x2FF0
	.equ LABEL_EA44A2, NakaInst_IvWaitWinCtlProc + 0x30D6
	.equ LABEL_EA471A, NakaInst_IvWaitWinCtlProc + 0x334E
	.equ LABEL_EA66B6, NakaInst_IvWaitWinCtlProc + 0x52EA
	.equ LABEL_EA6706, NakaInst_IvWaitWinCtlProc + 0x533A
	.equ NakaInst_WaitWinCtlSmf, NakaInst_IvWaitWinCtlProc + 0x6A34
