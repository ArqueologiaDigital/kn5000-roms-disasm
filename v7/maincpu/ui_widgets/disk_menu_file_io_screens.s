
; Disk Menu & File I/O screen widgets (382 widgets, 30944 bytes)
; Source: maincpu/ui_widgets/naka_disk_menu_file_io.c (C struct with named fields)
NakaInst_IvWaitWinCtlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x0, 0x12
NakaInst_IvIndexSwDelayProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12, 0x14
NakaInst_AcRotStrBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x26, 0x10
NakaInst_IvIndexSwCtrlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36, 0x12
NakaInst_ArrowProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x48, 0xA
NakaInst_VwScreenTitleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52, 0x12
NakaInst_IvOneShotTimerProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64, 0x14
NakaInst_AcMonoIndexToggleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x78, 0x16
NakaInst_AcFileSfxBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x8E, 0x12
NakaInst_AcParaStrBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA0, 0x12
NakaInst_AcTtlJgBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB2, 0x10
NakaInst_PsWindowToggleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC2, 0x14
NakaInst_PsFileNameBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD6, 0x8D8
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x9AE, 0x6C8
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1076, 0x1F8
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x126E, 0x70
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12DE, 0x28
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1306, 0xD0
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x13D6, 0x80
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1456, 0x130
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1586, 0x50
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x15D6, 0x484
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A5A, 0xE8
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B42, 0x2C
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B6E, 0xC20
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x278E, 0x58
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x27E6, 0x178
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x295E, 0x50
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29AE, 0x50
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29FE, 0x1A0
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B9E, 0x70
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C0E, 0x28
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C36, 0x80
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2CB6, 0x150
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E06, 0x188
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F8E, 0x62
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2FF0, 0xE6
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x30D6, 0x278
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x334E, 0x1F9C
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52EA, 0x50
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x533A, 0xBC6
EmbeddedPtrTable_v7_naka_disk_menu_file_io_005F00:
	.long 0x00EA754A
	.long 0x00EA7548
	.long 0x00EA7546
	.long 0x00EA7544
	.long 0x00EA7542
	.long 0x00EA7540
	.long 0x00EA753E
	.long 0x00EA753C
	.long 0x00EA753A
	.long 0x00EA7538
	.long 0x00EA7536
	.long 0x00EA752A
	.long 0x00EA7528
	.long 0x00EA7518
	.long 0x00EA7516
	.long 0x00EA7514
	.long 0x00EA7512
	.long 0x00EA7510
	.long 0x00EA750E
	.long 0x00EA750C
	.long 0x00EA750A
	.long 0x00EA7508
	.long 0x00EA7506
	.long 0x00EA7504
	.long 0x00EA7502
	.long 0x00EA7500
	.long 0x00EA74FE
	.long 0x00EA74FC
	.long 0x00EA74FA
	.long 0x00EA74F8
	.long 0x00EA74F6
	.long 0x00EA74F4
	.long 0x00EA74F2
	.long 0x00EA74E0
	.long 0x00EA74D4
	.long 0x00EA74D2
	.long 0x00EA74D0
	.long 0x00EA74CE
	.long 0x00EA74CC
	.long 0x00EA74CA
	.long 0x00EA74C8
	.long 0x00EA74C6
	.long 0x00EA74C4
	.long 0x00EA74C2
	.long 0x00EA74C0
	.long 0x00EA74BE
	.long 0x00EA74BC
	.long 0x00EA74BA
	.long 0x00EA74B8
	.long 0x00EA74B6
	.long 0x00EA74B4
	.long 0x00EA74B2
	.long 0x00EA74B0
	.long 0x00EA74AE
	.long 0x00EA749C
	.long 0x00EA749A
	.long 0x00EA7498
	.long 0x00EA7496
	.long 0x00EA7484
	.long 0x00EA7482
	.long 0x00EA7480
	.long 0x00EA747E
	.long 0x00EA747C
	.long 0x00EA747A
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6000, 0x500
EmbeddedPtrTable_v7_naka_disk_menu_file_io_006500:
	.long 0x00EA7A8E
	.long 0x00EA7A8C
	.long 0x00EA7A8A
	.long 0x00EA7A7E
	.long 0x00EA7A7C
	.long 0x00EA7A7A
	.long 0x00EA7A78
	.long 0x00EA7A66
	.long 0x00EA7A64
	.long 0x00EA7A62
	.long 0x00EA7A60
	.long 0x00EA7A4E
	.long 0x00EA7A4C
	.long 0x00EA7A4A
	.long 0x00EA7A48
	.long 0x00EA7A46
	.long 0x00EA7A44
	.long 0x00EA7A32
	.long 0x00EA7A30
	.long 0x00EA7A2E
	.long 0x00EA7A2C
	.long 0x00EA7A2A
	.long 0x00EA7A28
	.long 0x00EA7A26
	.long 0x00EA7A24
	.long 0x00EA7A22
	.long 0x00EA7A20
	.long 0x00EA7A1E
	.long 0x00EA7A1C
	.long 0x00EA7A1A
	.long 0x00EA7A18
	.long 0x00EA7A16
	.long 0x00EA7A14
	.long 0x00EA7A12
	.long 0x00EA7A10
	.long 0x00EA7A0E
	.long 0x00EA7A0C
	.long 0x00EA7A0A
	.long 0x00EA7A08
	.long 0x00EA7A06
	.long 0x00EA79F4
	.long 0x00EA79F2
	.long 0x00EA79F0
	.long 0x00EA79EE
	.long 0x00EA79EC
	.long 0x00EA79EA
	.long 0x00EA79E8
	.long 0x00EA79E6
	.long 0x00EA79E4
	.long 0x00EA79E2
	.long 0x00EA79E0
	.long 0x00EA79DE
	.long 0x00EA79DC
	.long 0x00EA79DA
	.long 0x00EA79D8
	.long 0x00EA79D6
	.long 0x00EA79D4
	.long 0x00EA79D2
	.long 0x00EA79D0
	.long 0x00EA79CE
	.long 0x00EA79CC
	.long 0x00EA79CA
	.long 0x00EA79C8
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FC, 0x438
NakaInst_WaitWinCtlSmf:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6A34, 0xEAC

; External label offsets within the binary blob above.
