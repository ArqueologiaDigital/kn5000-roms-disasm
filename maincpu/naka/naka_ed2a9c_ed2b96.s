	naka_header NAKA_TYPE_CONTAINER
	.byte 0x2a, 0x00, 0x00, 0x00
	.long LABEL_ED2CF6
	.long LABEL_ED2CF4
	.long LABEL_ED20C6
	.long VariScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x44, 0x00, 0x22, 0x00
	.long LABEL_ED2CE8
	.long LABEL_ED2CDE
	.long LABEL_ED20CC
	.long RVariScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x44, 0x00, 0x22, 0x00
	.long LABEL_ED2CD2
	.long LABEL_ED2CC8
	.long LABEL_ED2138
	.long AcTransposeBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long LABEL_ED2CBA
	.long LABEL_ED2CB8
	.long LABEL_ED21A4
	.long AcChordBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long LABEL_ED2CAE
	.long LABEL_ED2CAC
	.long LABEL_ED21AA
	.long AcFreeSplitBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long LABEL_ED2C9E
	.long LABEL_ED2C9C
	.long LABEL_ED21B0
	.long AcBkNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long LABEL_ED2C94
	.long LABEL_ED2C92
	.long LABEL_ED21B6
	.long AcPmBkNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long LABEL_ED2C88
	.long LABEL_ED2C86
	.long LABEL_ED21BC
	.long PmBankScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x38, 0x00, 0x16, 0x00
	.long LABEL_ED2C78
	.long LABEL_ED2C70
	.long LABEL_ED21C2
	.long AcPmBkEditBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x3a, 0x00, 0x08, 0x00
	.long LABEL_ED2C62
	.long LABEL_ED2C5E
	.long LABEL_ED220C
	.long MsaModeScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x34, 0x00, 0x12, 0x00
	.long LABEL_ED2C50
	.long LABEL_ED2C4A
	.long LABEL_ED2226
	.long PmemModeBoxProc
	naka_header NAKA_TYPE_GROUP
	.byte 0x2c, 0x00, 0x12, 0x00
	.long LABEL_ED2C3E
	.long LABEL_ED2C38
	.long LABEL_ED226E
	.long IvWindowPageControlProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1a, 0x00, 0x04, 0x00
	.long LABEL_ED2C24
	.long LABEL_ED2C22
	.long LABEL_ED22B6
	.long IvPmemWindowPageCtlProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1a, 0x00, 0x04, 0x00
	.long LABEL_ED2C0E
	.long LABEL_ED2C0C
	.long LABEL_ED22C6
	.long IvMstStyleWindowPgCtlProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1a, 0x00, 0x04, 0x00
	.long LABEL_ED2BF6
	.long LABEL_ED2BF4
	.long LABEL_ED22D6
	.long AcTchSensGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long LABEL_ED2BE2
	.long LABEL_ED2BDE
	.long LABEL_ED22E6
	.long AcFSWAssGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long LABEL_ED2BCE
	.long LABEL_ED2BCA
	.long LABEL_ED2312
	.long AcPmExpFilterGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long LABEL_ED2BB4
	.long LABEL_ED2BB0
	.long LABEL_ED233E
	.long AcDispTimeSetGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long LABEL_ED2B9A
	.long LABEL_ED2B96
	.long LABEL_ED236A
	.long AcMstSugAlpGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x66, 0x00, 0x28, 0x00
	.long LABEL_ED2B82
	.long LABEL_ED2B76
	.long LABEL_ED2396
	.long AcMstStyleAlpGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x5e, 0x00, 0x20, 0x00
	.long LABEL_ED2B60
	.long LABEL_ED2B56
	.long LABEL_ED2438
	.long AcMstStyle1GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x56, 0x00, 0x18, 0x00
	.long LABEL_ED2B42
	.long LABEL_ED2B3A
	.long LABEL_ED24B4
	.long AcMstStyle1SubGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x56, 0x00, 0x18, 0x00
	.long LABEL_ED2B24
	.long LABEL_ED2B1C
	.long LABEL_ED2520
	.long AcMstStyle2GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x66, 0x00, 0x28, 0x00
	.long LABEL_ED2B08
	.long LABEL_ED2AFC
	.long LABEL_ED2596
	.long AcMstSong1GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x56, 0x00, 0x18, 0x00
	.long LABEL_ED2AEA
	.long LABEL_ED2AE2
	.long LABEL_ED265E
	.long AcMstSong2GridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x66, 0x00, 0x28, 0x00
	.long LABEL_ED2AD0
	.long LABEL_ED2AC4
	.long LABEL_ED26C8
	.long SineWaveScreenProc
	naka_header NAKA_TYPE_0x33
	.byte 0x34, 0x00, 0x12, 0x00
	.long LABEL_ED2AB4
	.long LABEL_ED2AAE
	.long LABEL_ED2788
	.long IvPageOverWrProc
	naka_header NAKA_TYPE_0x27
	.byte 0x1c, 0x00, 0x06, 0x00
	.long LABEL_ED2AA0
	.long LABEL_ED2A9C
	.long LABEL_ED27C8
	.zero 24
LABEL_ED2A9C:
	.byte 0x41, 0x74, 0x00, 0xff
LABEL_ED2AA0:	aligned_string "IvPageOverWr"
LABEL_ED2AAE:	.asciz "kc^nn"
LABEL_ED2AB4:	aligned_string "SineWaveScreen"
LABEL_ED2AC4:	aligned_string "XXjnnnnnnn"
LABEL_ED2AD0:	aligned_string "AcMstSong2GridBox"
LABEL_ED2AE2:	aligned_string "XXjnnn"
LABEL_ED2AEA:	aligned_string "AcMstSong1GridBox"
LABEL_ED2AFC:	aligned_string "XXjnnnnnnn"
LABEL_ED2B08:	aligned_string "AcMstStyle2GridBox"
LABEL_ED2B1C:	aligned_string "XXjnnn"
LABEL_ED2B24:	aligned_string "AcMstStyle1SubGridBox"
LABEL_ED2B3A:	aligned_string "XXjnnn"
LABEL_ED2B42:	aligned_string "AcMstStyle1GridBox"
LABEL_ED2B56:	aligned_string "XXjnnnnn"
LABEL_ED2B60:	aligned_string "AcMstStyleAlpGridBox"
LABEL_ED2B76:	aligned_string "XXjnnnnnnn"
LABEL_ED2B82:	aligned_string "AcMstSugAlpGridBox"
LABEL_ED2B96:
	.byte 0x58, 0x58
