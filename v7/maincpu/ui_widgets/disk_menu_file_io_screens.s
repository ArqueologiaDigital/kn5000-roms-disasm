
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
Str_DISKNAME:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x9AE, 0x6C8
Str_LOAD:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1076, 0x1F8
Str_COMP:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x126E, 0x70
Str_CUSTOM:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12DE, 0x28
Str_MIDI:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1306, 0xD0
Str_RHYTHM_CUSTOM:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x13D6, 0x80
Str_COMPOSER:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1456, 0x130
Str_LOAD_2952:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1586, 0x50
Str_SINGLE_LOAD:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x15D6, 0x484
Str_PREV:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A5A, 0xE8
Str_DISK:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B42, 0x2C
Str_LOAD_AS:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B6E, 0xC20
Str_SOUND_MEMORY:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x278E, 0x58
Str_SEQUENCER:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x27E6, 0x178
Str_PERFORM:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x295E, 0x50
Str_BACKUP:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29AE, 0x50
Str_PNL:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29FE, 0x1A0
Str_COMP_3F6A:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B9E, 0x70
Str_CUSTOM_3FDA:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C0E, 0x28
Str_MIDI_4002:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C36, 0x80
Str_ALL_OFF:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2CB6, 0x150
Str_SAVE:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E06, 0x188
Str_NEXT:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F8E, 0x62
Str_OFF:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2FF0, 0xE6
Str_SAVE_44A2:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x30D6, 0x278
Str_PREV_471A:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x334E, 0x1F9C
Str_DISKINSERTOPTION:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52EA, 0x50
Str_FILETYPEPRIORITY:
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
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6000, 0xA34
NakaInst_WaitWinCtlSmf:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6A34, 0xEAC

; External label offsets within the binary blob above.
