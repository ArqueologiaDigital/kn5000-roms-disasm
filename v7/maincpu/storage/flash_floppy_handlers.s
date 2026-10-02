; =============================================================================
; Flash & Floppy Handlers
; =============================================================================
;
; Flash memory sector write routines, floppy disk note event
; loading, and FDC format UI. Bridges storage hardware to the
; file I/O subsystem.
; =============================================================================

; list-boundary table, 12 x {u32 start, u32 end} of bound record lists; the code reads XIY = (T+8i), XIX = (T+8i+4)
; evidence: SeMenu_NameEdit_DataBlock1_Join3+0x19 (0xF100A1)
; (name FlashWrite_BlockHandler_Table kept: other files use it; the object is ScreenData, see above)
FlashWrite_BlockHandler_Table:
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D4C
	.long	FlashRead_BlockHandler_Table
	.long	SeScreenData_0x4D4C
	.long	FlashRead_BlockHandler_Table
	.long	SeScreenData_0x4DAD
	.long	SeScreenData_0x4DDA
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E2A
	.long	SeScreenData_0x4E54
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E68
	.long	FlashWrite_BlockRef_Type6
	.long	SeScreenData_0x4E68
	.long	FlashWrite_BlockRef_Type6
; bound record list (5 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15910
; evidence: pairs table 0xF1587D
SeScreenData_0x4D01:
; [v10] F15907..F1593A  [flags:u8][len:u8][payload] records
; [v10] F15907 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; [v10] F15911 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; [v10] F1591B flags=0x05 len=11
	.byte	0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbb, 0x0f, 0x02, 0x00
; [v10] F15926 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x14, 0x12, 0x02
; [v10] F15930 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x65, 0x06, 0xff, 0x00, 0x20, 0x6b, 0x14, 0x03
; table of 6 pointers to the records of the list at 0xF158DD (entry 0 repeated); entry 0 of the per-variant table at 0xF15A77, drawn one record at a time by SeMenu_EqEdit_DrawInit_0x15 (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF1011C)
SeScreenData_0x4D34:
; [v10] F1593A..F15952  6 x u32 pointer
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D01 + 0xa
	.long	SeScreenData_0x4D01 + 0x14
	.long	SeScreenData_0x4D01 + 0x1f
	.long	SeScreenData_0x4D01 + 0x29
; bound record list (6 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15965
; evidence: pairs table 0xF1587D
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF15965
SeScreenData_0x4D4C:
; [v10] F15952..F1598F  [flags:u8][len:u8][payload] records
; [v10] F15952 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF15965
SeScreenData_0x4D56:
; [v10] F1595C flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF15965
SeScreenData_0x4D60:
; [v10] F15966 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbc, 0x0f, 0x02
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF15965
SeScreenData_0x4D6A:
; [v10] F15970 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x14, 0x12, 0x02
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF15965
SeScreenData_0x4D74:
; [v10] F1597A flags=0x05 len=11
	.byte	0x05, 0x0b, 0x65, 0x06, 0xff, 0x00, 0x20, 0x6b, 0x14, 0x02, 0x00
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF15965
SeScreenData_0x4D7F:
; [v10] F15985 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x66, 0x06, 0xff, 0x00, 0x20, 0xc4, 0x16, 0x02
; table of 9 pointers, entry = A (0..8; entry 0 repeated): entries 1-6 -> the records
; SeScreenData_0x4D56.., entries 7/8 -> FlashRead_BlockData_Field7/_Field8.  The code loads it
; into XIY only on SeMenu_PatchEdit_DataBlock's `cp a, 7 / jr nc` path, and
; SeMenu_EqEdit_DrawInit_0x15 draws entry WA (XIY = (XIY + 4*WA)) -- so the entries that reader
; uses are 7 and 8 (corrected 2026-10-02 from "table of 7", Wave 2 claims review)
; evidence: SeMenu_PatchEdit_DataBlock_Join+0x6 (0xF10154)
; (name FlashRead_BlockHandler_Table kept: other files use it; the object is ScreenData, see above)
FlashRead_BlockHandler_Table:
	.long	SeScreenData_0x4D4C
	.long	SeScreenData_0x4D4C
	.long	SeScreenData_0x4D56
	.long	SeScreenData_0x4D60
	.long	SeScreenData_0x4D6A
	.long	SeScreenData_0x4D74
	.long	SeScreenData_0x4D7F
	.long	FlashRead_BlockData_Field7
	.long	FlashRead_BlockData_Field8
; bound record list (4 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF159B6
; evidence: pairs table 0xF1587D
SeScreenData_0x4DAD:
; [v10] F159B3..F159E0  [flags:u8][len:u8][payload] records
; [v10] F159B3 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; [v10] F159BD flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; [v10] F159C7 flags=0x02 len=15
	.byte	0x02, 0x0f, 0x63, 0x06, 0x0f, 0x00, 0x20
	.long	TuningSystem_Handler_Table_0xDF + 0x10
	.byte	0x03, 0x00, 0xbb, 0x0f
; [v10] F159D6 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x13, 0x12, 0x03
; table of 5 pointers to the records of the list at 0xF15989 (entry 0 repeated); entry 6 of the per-variant table at 0xF15A77, drawn one record at a time by SeMenu_EqEdit_DrawInit_0x15 (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF1011C)
SeScreenData_0x4DDA:
; (was .incbin "includes/romslices/v7_transplant_FlashWrite_BlockRef_Type3.bin")
; [v10] F1593A..F15952  6 x u32 pointer
; [v10] F159E0..F159F4  5 x u32 pointer
	.long	SeScreenData_0x4DAD
	.long	SeScreenData_0x4DAD
	.long	SeScreenData_0x4DAD + 0xa
	.long	SeScreenData_0x4DAD + 0x14
	.long	SeScreenData_0x4DAD + 0x23
; bound record list (4 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF159F2
; evidence: pairs table 0xF1587D
SeScreenData_0x4DEE:
; [v10] F159F4..F15A1C  [flags:u8][len:u8][payload] records
; [v10] F159F4 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; [v10] F159FE flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; [v10] F15A08 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbc, 0x0f, 0x02
; [v10] F15A12 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x14, 0x12, 0x02
; table of 5 pointers to the records of the list at 0xF159CA (entry 0 repeated); entry 7 of the per-variant table at 0xF15A77, drawn one record at a time by SeMenu_EqEdit_DrawInit_0x15 (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF1011C)
SeScreenData_0x4E16:
; (was .incbin "includes/romslices/v7_transplant_FlashWrite_BlockRef_Type4.bin")
; [v10] F15A1C..F15A30  5 x u32 pointer
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4DEE + 0xa
	.long	SeScreenData_0x4DEE + 0x14
	.long	SeScreenData_0x4DEE + 0x1e
; bound record list (4 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15A30
; evidence: pairs table 0xF1587D
SeScreenData_0x4E2A:
; [v10] F15A30..F15A5A  [flags:u8][len:u8][payload] records
; [v10] F15A30 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; [v10] F15A3A flags=0x05 len=11
	.byte	0x05, 0x0b, 0x62, 0x06, 0xff, 0x00, 0x20, 0x63, 0x0d, 0x02, 0x00
; [v10] F15A45 flags=0x05 len=11
	.byte	0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbb, 0x0f, 0x02, 0x00
; [v10] F15A50 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x13, 0x12, 0x03
; table of 5 pointers to the records of the list at 0xF15A06 (entry 0 repeated); entry 8 of the per-variant table at 0xF15A77, drawn one record at a time by SeMenu_EqEdit_DrawInit_0x15 (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF1011C)
SeScreenData_0x4E54:
; [v10] F15A5A..F15A6E  5 x u32 pointer
	.long	SeScreenData_0x4E2A
	.long	SeScreenData_0x4E2A
	.long	SeScreenData_0x4E2A + 0xa
	.long	SeScreenData_0x4E2A + 0x15
	.long	SeScreenData_0x4E2A + 0x20
; bound record list (3 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15A67
; evidence: pairs table 0xF1587D
SeScreenData_0x4E68:
; [v10] F15A6E..F15A91  [flags:u8][len:u8][payload] records
; [v10] F15A6E flags=0x02 len=15
	.byte	0x02, 0x0f, 0x61, 0x06, 0x01, 0x00, 0x20
	.long	SeBitmap_EnvCurve5_0x4B0 + 0x53
	.byte	0x03, 0x00, 0x0b, 0x0b
; -> 0xF15A5D
; [v10] F15A7D flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; llvm-mc cannot spell this byte
; [v10] F15A87 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbb, 0x0f, 0x03
; table of 4 pointers to the records of the list at 0xF15A44 (entry 0 repeated); entry 10 of the per-variant table at 0xF15A77, drawn one record at a time by SeMenu_EqEdit_DrawInit_0x15 (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF1011C)
; (name FlashWrite_BlockRef_Type6 kept: other files use it; the object is ScreenData, see above)
FlashWrite_BlockRef_Type6:
; [v10] F15A91..F15AA1  4 x u32 pointer
	.long	SeScreenData_0x4E68
	.long	SeScreenData_0x4E68
	.long	SeScreenData_0x4E68 + 0xf
	.long	SeScreenData_0x4E68 + 0x19
; 12 pointers to record-pointer tables, one per screen variant = the byte at RAM 0x670; entry -> SeMenu_EqEdit_DrawInit_0x15
; evidence: SeMenu_PatchEdit_DataBlock (0xF1011C)
SeScreenData_0x4E9B:
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D34
	.long	FlashRead_BlockHandler_Table
	.long	FlashRead_BlockHandler_Table
	.long	SeScreenData_0x4DDA
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E54
	.long	SeScreenData_0x4E16
	.long	FlashWrite_BlockRef_Type6
	.long	FlashWrite_BlockRef_Type6
; 12 list END pointers, one per screen variant = the byte at RAM 0x670, for the static list the code starts with `ld xiy, <start>`
; evidence: SeMenu_NameEdit_DataBlock1 (0xF0FFF6)
SeScreenData_0x4ECB:
	.long	TuningSystem_Handler_Table_0x1E8B + 0x96
	.long	TuningSystem_Handler_Table_0x1E8B + 0x96
	.long	TuningSystem_Handler_Table_0x1E8B + 0x96
	.long	TuningSystem_Handler_Table_0x1E8B + 0x96
	.long	TuningSystem_Handler_Table_0x1F3F
	.long	TuningSystem_Handler_Table_0x1F3F
	.long	TuningSystem_Handler_Table_0x1E8B + 0x78
	.long	TuningSystem_Handler_Table_0x1E8B + 0x78
	.long	TuningSystem_Handler_Table_0x1E8B + 0x78
	.long	TuningSystem_Handler_Table_0x1E8B + 0x78
	.long	TuningSystem_Handler_Table_0x1E8B + 0x5a
	.long	TuningSystem_Handler_Table_0x1E8B + 0x5a
; fixed-width string table, 13 chars per entry, 168 B: the text choices of a bound op02/op07 record (its +7 pointer; +11 = chars per entry)
; evidence: bound op02 record 0xF164CD
SeScreenData_0x4EFB:
; [v10] F15B01..F15BA9  effect name table, 12 x 13 chars then 2 x 6
	.ascii	"CELESTE 1    "
	.ascii	"CELESTE 2    "
	.ascii	"CHORUS 1     "
	.ascii	"CHORUS 2     "
	.ascii	"ENSEMBLE 1   "
	.ascii	"ENSEMBLE 2   "
	.ascii	"TREMOLO      "
	.ascii	"ORGAN TREMOLO"
	.ascii	"SINGLE DELAY "
	.ascii	"REPEAT DELAY "
	.ascii	"SOLO EFFECT 1"
	.ascii	"SOLO EFFECT 2"
	.ascii	"MONO  STEREO"
; static record list (37 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF15CFC
; evidence: SeMenu_NameEdit_DataBlock2+0xA (0xF100B0)
SeScreenData_0x4FA3:
; [v10] F15BA9..F16109  [flags:u8][len:u8][payload] records
; [v10] F15BA9 flags=0x23 len=5
	.byte	0x23, 0x05, 0x62, 0x84, 0x00
; [v10] F15BAE flags=0x1c len=15
	.byte	0x1c, 0x0f, 0x7b, 0x00, 0x05, 0x00
	.ascii	"EASY EDIT"
; [v10] F15BBD flags=0x17 len=16
	.byte	0x17, 0x10, 0x06, 0x00, 0x07, 0x00
	.ascii	"SOUND EDIT"
; [v10] F15BCD flags=0x07 len=5
	.byte	0x07, 0x05, 0x50, 0x05, 0x10
; [v10] F15BD2 flags=0x06 len=9
	.byte	0x06, 0x09, 0xa2, 0x05
	.ascii	"WRITE"
; [v10] F15BDB flags=0x07 len=17
	.byte	0x07, 0x11, 0x8e, 0x0a
	.ascii	"0CTAVE SHIFT:"
; [v10] F15BEC flags=0x07 len=18
	.byte	0x07, 0x12, 0xa2, 0x0a
	.ascii	"BRILLIANCE   :"
; [v10] F15BFE flags=0x07 len=5
	.byte	0x07, 0x05, 0x68, 0x0b, 0x10
; [v10] F15C03 flags=0x07 len=5
	.byte	0x07, 0x05, 0x8f, 0x0b, 0x11
; [v10] F15C08 flags=0x07 len=17
	.byte	0x07, 0x11, 0xa6, 0x10
	.ascii	"ATTACK TIME :"
; [v10] F15C19 flags=0x07 len=18
	.byte	0x07, 0x12, 0xba, 0x10
	.ascii	"VIBRAT0 DEPTH:"
; [v10] F15C2B flags=0x07 len=5
	.byte	0x07, 0x05, 0x80, 0x11, 0x10
; [v10] F15C30 flags=0x07 len=5
	.byte	0x07, 0x05, 0xa7, 0x11, 0x11
; [v10] F15C35 flags=0x07 len=17
	.byte	0x07, 0x11, 0x0e, 0x17
	.ascii	"RELEASE TIME:"
; [v10] F15C46 flags=0x07 len=18
	.byte	0x07, 0x12, 0x22, 0x17
	.ascii	"VIBRAT0 SPEED:"
; [v10] F15C58 flags=0x07 len=5
	.byte	0x07, 0x05, 0x98, 0x17, 0x10
; [v10] F15C5D flags=0x07 len=5
	.byte	0x07, 0x05, 0xbf, 0x17, 0x11
; [v10] F15C62 flags=0x07 len=19
	.byte	0x07, 0x13, 0x36, 0x1c
	.ascii	"DIGITAL EFFECT:"
; [v10] F15C75 flags=0x07 len=18
	.byte	0x07, 0x12, 0x62, 0x1d
	.ascii	"VIBRAT0 DELAY:"
; [v10] F15C87 flags=0x07 len=5
	.byte	0x07, 0x05, 0xb0, 0x1d, 0x10
; [v10] F15C8C flags=0x07 len=5
	.byte	0x07, 0x05, 0xd7, 0x1d, 0x11
; [v10] F15C91 flags=0x07 len=5
	.byte	0x07, 0x05, 0xd1, 0x21, 0x8d
; [v10] F15C96 flags=0x06 len=9
	.byte	0x06, 0x09, 0x14
	.ascii	"#VALUE"
; [v10] F15C9F flags=0x07 len=5
	.byte	0x07, 0x05, 0x61, 0x23, 0x8e
; [v10] F15CA4 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44, 0x00, 0x10, 0x00
; [v10] F15CAE flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x1e, 0x00, 0x3d, 0x00, 0x33, 0x00
; [v10] F15CB8 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0d, 0x00, 0x20, 0x00, 0x3b, 0x00, 0x31, 0x00
; [v10] F15CC2 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0x39, 0x00, 0x34, 0x01, 0x59, 0x00
; [v10] F15CCC flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x3a, 0x00, 0x9c, 0x00, 0x59, 0x00
; [v10] F15CD6 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x61, 0x00, 0x9c, 0x00, 0x80, 0x00
; [v10] F15CE0 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0x61, 0x00, 0x34, 0x01, 0x80, 0x00
; [v10] F15CEA flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x89, 0x00, 0x9c, 0x00, 0xa8, 0x00
; [v10] F15CF4 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0x89, 0x00, 0x34, 0x01, 0xa8, 0x00
; [v10] F15CFE flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0xb2, 0x00, 0x9c, 0x00, 0xd1, 0x00
; [v10] F15D08 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0xb2, 0x00, 0x34, 0x01, 0xd1, 0x00
; [v10] F15D12 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x7d, 0x00, 0xda, 0x00, 0x9a, 0x00, 0xec, 0x00
; [v10] F15D1C flags=0x01 len=10
	.byte	0x01, 0x0a, 0x7d, 0x00, 0xe3, 0x00, 0x9a, 0x00, 0xe3, 0x00
; static record list (83 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF15FC8
; evidence: SeMenu_WaveformSelect_Data+0x38 (0xF0F544)
SeScreenData_0x5120:
; [v10] F15D26 flags=0x1c len=14
	.byte	0x1c, 0x0e, 0x70, 0x00, 0x09, 0x00
	.ascii	"USER KIT"
; [v10] F15D34 flags=0x17 len=16
	.byte	0x17, 0x10, 0x06, 0x00, 0x07, 0x00
	.ascii	"SOUND EDIT"
; [v10] F15D44 flags=0x17 len=7
	.byte	0x17, 0x07, 0x36, 0x01, 0x1f, 0x00, 0x91
; [v10] F15D4B flags=0x07 len=5
	.byte	0x07, 0x05, 0x4c, 0x05, 0x8d
; [v10] F15D50 flags=0x07 len=5
	.byte	0x07, 0x05, 0x9f, 0x05, 0xa9
; [v10] F15D55 flags=0x1c len=7
	.byte	0x1c, 0x07, 0x5e, 0x00, 0x35, 0x00, 0x3a
; [v10] F15D5C flags=0x17 len=11
	.byte	0x17, 0x0b, 0x15, 0x01, 0x38, 0x00
	.ascii	"SOUND"
; [v10] F15D67 flags=0x17 len=7
	.byte	0x17, 0x07, 0x36, 0x01, 0x46, 0x00, 0x91
; [v10] F15D6E flags=0x07 len=5
	.byte	0x07, 0x05, 0x8c, 0x0b, 0x8e
; [v10] F15D73 flags=0x07 len=5
	.byte	0x07, 0x05, 0xb7, 0x0b, 0xa9
; [v10] F15D78 flags=0x17 len=17
	.byte	0x17, 0x11, 0x47, 0x00, 0x64, 0x00
	.ascii	"TONE SELECT"
; [v10] F15D89 flags=0x17 len=11
; [v10] data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15D8A-0xF15DA3 (25 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=60% dist=14 near FlashWrite_BlockRef_Type6_0x295+100
	.byte	0x17, 0x0b, 0xa2, 0x00, 0x64, 0x00
	.ascii	"LEVEL"
; [v10] F15D94 flags=0x17 len=9
	.byte	0x17, 0x09, 0xc7, 0x00, 0x64, 0x00, 0x4b, 0x45, 0x59
; [v10] F15D9D flags=0x17 len=10
	.byte	0x17, 0x0a, 0xe1, 0x00, 0x64, 0x00
	.ascii	"TUNE"
; [v10] F15DA7 flags=0x17 len=9
	.byte	0x17, 0x09, 0x02, 0x01, 0x64, 0x00, 0x50, 0x41, 0x4e
; [v10] F15DB0 flags=0x17 len=9
	.byte	0x17, 0x09, 0x1d, 0x01, 0x64, 0x00, 0x52, 0x45, 0x56
; [v10] F15DB9 flags=0x06 len=5
	.byte	0x06, 0x05, 0xd0, 0x11, 0x10
; [v10] F15DBE flags=0x17 len=7
	.byte	0x17, 0x07, 0x44, 0x00, 0x76, 0x00, 0x2e
; [v10] F15DC5 flags=0x17 len=7
	.byte	0x17, 0x07, 0x43, 0x00, 0x7b, 0x00, 0x91
; [v10] F15DCC flags=0x17 len=7
	.byte	0x17, 0x07, 0x44, 0x00, 0x94, 0x00, 0x2e
; [v10] F15DD3 flags=0x06 len=5
	.byte	0x06, 0x05, 0xe8, 0x17, 0x10
; [v10] F15DD8 flags=0x17 len=7
	.byte	0x17, 0x07, 0x43, 0x00, 0x99, 0x00, 0x91
; [v10] F15DDF flags=0x06 len=15
	.byte	0x06, 0x0f, 0x3a, 0x1d
	.ascii	"NOTE SELECT"
; [v10] F15DEE flags=0x06 len=15
	.byte	0x06, 0x0f, 0x53, 0x1d
	.ascii	"DETAIL EDIT"
; [v10] F15DFD flags=0x06 len=5
	.byte	0x06, 0x05, 0xb0, 0x1d, 0x10
; [v10] F15E02 flags=0x06 len=5
	.byte	0x06, 0x05, 0xd7, 0x1d, 0x11
; [v10] F15E07 flags=0x17 len=12
	.byte	0x17, 0x0c, 0x00, 0x00, 0xd1, 0x00
	.ascii	"ON/OFF"
; [v10] F15E13 flags=0x17 len=11
	.byte	0x17, 0x0b, 0x2d, 0x00, 0xd1, 0x00
	.ascii	"GROUP"
; [v10] F15E1E flags=0x17 len=10
	.byte	0x17, 0x0a, 0x58, 0x00, 0xd1, 0x00
	.ascii	"TONE"
; [v10] F15E28 flags=0x17 len=11
	.byte	0x17, 0x0b, 0x7d, 0x00, 0xd1, 0x00
	.ascii	"LEVEL"
; [v10] F15E33 flags=0x17 len=9
	.byte	0x17, 0x09, 0xaa, 0x00, 0xd1, 0x00, 0x4b, 0x45, 0x59
; [v10] F15E3C flags=0x17 len=10
	.byte	0x17, 0x0a, 0xcf, 0x00, 0xd1, 0x00
	.ascii	"TUNE"
; [v10] F15E46 flags=0x17 len=9
	.byte	0x17, 0x09, 0xfa, 0x00, 0xd1, 0x00, 0x50, 0x41, 0x4e
; [v10] F15E4F flags=0x17 len=9
	.byte	0x17, 0x09, 0x23, 0x01, 0xd1, 0x00, 0x52, 0x45, 0x56
; [v10] F15E58 flags=0x06 len=5
	.byte	0x06, 0x05, 0x12, 0x22, 0x8d
; [v10] F15E5D flags=0x06 len=5
	.byte	0x06, 0x05, 0x17, 0x22, 0x8d
; [v10] F15E62 flags=0x06 len=5
	.byte	0x06, 0x05, 0x1c, 0x22, 0x8d
; [v10] F15E67 flags=0x06 len=5
	.byte	0x06, 0x05, 0x21, 0x22, 0x8d
; [v10] F15E6C flags=0x06 len=5
	.byte	0x06, 0x05, 0x26, 0x22, 0x8d
; [v10] data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15E71-0xF15E84 (19 B), unreached CODE-territory, was disassembled as 9 plausible-but-dead instruction lines; per=71% dist=9 near FlashWrite_BlockRef_Type6_0x295+331
; [v10] F15E71 flags=0x06 len=5
	.byte	0x06, 0x05, 0x2b, 0x22, 0x8d
; [v10] F15E76 flags=0x06 len=5
	.byte	0x06, 0x05, 0x30, 0x22, 0x8d
; [v10] F15E7B flags=0x06 len=5
	.byte	0x06, 0x05, 0x35, 0x22, 0x8d
; [v10] F15E80 flags=0x06 len=5
	.byte	0x06, 0x05, 0xa2, 0x23, 0x8e
; [v10] F15E85 flags=0x06 len=5
	.byte	0x06, 0x05, 0xa7, 0x23, 0x8e
; [v10] F15E8A flags=0x06 len=5
	.byte	0x06, 0x05, 0xac, 0x23, 0x8e
; [v10] F15E8F flags=0x06 len=5
	.byte	0x06, 0x05, 0xb1, 0x23, 0x8e
; [v10] F15E94 flags=0x06 len=5
	.byte	0x06, 0x05, 0xb6, 0x23, 0x8e
; [v10] F15E99 flags=0x06 len=5
	.byte	0x06, 0x05, 0xbb, 0x23, 0x8e
; [v10] F15E9E flags=0x06 len=5
	.byte	0x06, 0x05, 0xc0, 0x23, 0x8e
; [v10] F15EA3 flags=0x06 len=5
	.byte	0x06, 0x05, 0xc5, 0x23, 0x8e
; [v10] F15EA8 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44, 0x00, 0x10, 0x00
; [v10] F15EB2 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x12, 0x01, 0x1e, 0x00, 0x35, 0x01, 0x31, 0x00
; [v10] F15EBC flags=0x09 len=10
	.byte	0x09, 0x0a, 0x14, 0x01, 0x20, 0x00, 0x33, 0x01, 0x2f, 0x00
; [v10] data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15EC9-0xF15EDD (20 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=60% dist=11 near FlashWrite_BlockRef_Type6_0x295+419
; [v10] F15EC6 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x37, 0x00, 0x2e, 0x00, 0xfd, 0x00, 0x49, 0x00
; [v10] F15ED0 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x39, 0x00, 0x30, 0x00, 0xfb, 0x00, 0x47, 0x00
; [v10] F15EDA flags=0x09 len=10
	.byte	0x09, 0x0a, 0x12, 0x01, 0x45, 0x00, 0x35, 0x01, 0x58, 0x00
; [v10] F15EE4 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x14, 0x01, 0x47, 0x00, 0x33, 0x01, 0x56, 0x00
; [v10] F15EEE flags=0x22 len=10
	.byte	0x22, 0x0a, 0x0b, 0x00, 0x5e, 0x00, 0x35, 0x01, 0xaa, 0x00
; [v10] F15EF8 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0a, 0x00, 0xb5, 0x00, 0x6e, 0x00, 0xca, 0x00
; [v10] F15F02 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0c, 0x00, 0xb7, 0x00, 0x6c, 0x00, 0xc8, 0x00
; [v10] F15F0C flags=0x09 len=10
	.byte	0x09, 0x0a, 0xd2, 0x00, 0xb5, 0x00, 0x35, 0x01, 0xca, 0x00
; [v10] F15F16 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xd4, 0x00, 0xb7, 0x00, 0x33, 0x01, 0xc8, 0x00
; [v10] data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15F25-0xF15F3C (23 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=10 near FlashWrite_BlockRef_Type6_0x295+511
; [v10] F15F20 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x09, 0x00, 0xda, 0x00, 0x1e, 0x00, 0xee, 0x00
; [v10] F15F2A flags=0x22 len=10
	.byte	0x22, 0x0a, 0x31, 0x00, 0xda, 0x00, 0x46, 0x00, 0xee, 0x00
; [v10] F15F34 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x59, 0x00, 0xda, 0x00, 0x6e, 0x00, 0xee, 0x00
; [v10] F15F3E flags=0x22 len=10
	.byte	0x22, 0x0a, 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee, 0x00
; [v10] F15F48 flags=0x22 len=10
	.byte	0x22, 0x0a, 0xa9, 0x00, 0xda, 0x00, 0xbe, 0x00, 0xee, 0x00
; [v10] F15F52 flags=0x22 len=10
	.byte	0x22, 0x0a, 0xd1, 0x00, 0xda, 0x00, 0xe6, 0x00, 0xee, 0x00
; [v10] F15F5C flags=0x22 len=10
	.byte	0x22, 0x0a, 0xf9, 0x00, 0xda, 0x00, 0x0e, 0x01, 0xee, 0x00
; [v10] F15F66 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x21, 0x01, 0xda, 0x00, 0x36, 0x01, 0xee, 0x00
; [v10] F15F70 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x6f, 0x00, 0x35, 0x01, 0x6f, 0x00
; [v10] F15F7A flags=0x01 len=10
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x8c, 0x00, 0x19, 0x01, 0x8c, 0x00
; [v10] F15F84 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x09, 0x00, 0xe4, 0x00, 0x1e, 0x00, 0xe4, 0x00
; [v10] data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15F8F-0xF15FA0 (17 B), unreached CODE-territory, was disassembled as 6 plausible-but-dead instruction lines; per=71% dist=8 near FlashWrite_BlockRef_Type6_0x295+617
; [v10] F15F8E flags=0x01 len=10
	.byte	0x01, 0x0a, 0x31, 0x00, 0xe4, 0x00, 0x46, 0x00, 0xe4, 0x00
; [v10] F15F98 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x59, 0x00, 0xe4, 0x00, 0x6e, 0x00, 0xe4, 0x00
; [v10] F15FA2 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x81, 0x00, 0xe4, 0x00, 0x96, 0x00, 0xe4, 0x00
; [v10] F15FAC flags=0x01 len=10
	.byte	0x01, 0x0a, 0xa9, 0x00, 0xe4, 0x00, 0xbe, 0x00, 0xe4, 0x00
; [v10] F15FB6 flags=0x01 len=10
	.byte	0x01, 0x0a, 0xd1, 0x00, 0xe4, 0x00, 0xe6, 0x00, 0xe4, 0x00
; [v10] F15FC0 flags=0x01 len=10
	.byte	0x01, 0x0a, 0xf9, 0x00, 0xe4, 0x00, 0x0e, 0x01, 0xe4, 0x00
; [v10] F15FCA flags=0x01 len=10
	.byte	0x01, 0x0a, 0x21, 0x01, 0xe4, 0x00, 0x36, 0x01, 0xe4, 0x00
; [v10] F15FD4 flags=0x02 len=10
	.byte	0x02, 0x0a, 0x38, 0x00, 0x5e, 0x00, 0x38, 0x00, 0xaa, 0x00
; [v10] F15FDE flags=0x02 len=10
	.byte	0x02, 0x0a, 0x9d, 0x00, 0x5e, 0x00, 0x9d, 0x00, 0xaa, 0x00
; [v10] F15FE8 flags=0x02 len=10
	.byte	0x02, 0x0a, 0x19, 0x01, 0x5e, 0x00, 0x19, 0x01, 0xaa, 0x00
; static record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF15FDC
; evidence: SeMenu_WaveformSelect_Data+0x62 (0xF0F56E), SeMenu_PresetManager_Init+0x75 (0xF0F653)
SeScreenData_0x53EC:
; [v10] F15FF2 flags=0x1b len=10
	.byte	0x1b, 0x0a, 0x19, 0x01, 0x71, 0x00, 0x33, 0x01, 0xa8, 0x00
; [v10] F15FFC flags=0x05 len=10
	.byte	0x05, 0x0a, 0x19, 0x01, 0x71, 0x00, 0x33, 0x01, 0xa8, 0x00
; bound record list (16 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF160C7
; evidence: SeMenu_WaveformSelect_Data+0x4A (0xF0F556), SeMenu_PresetManager_Init+0x85 (0xF0F663)
; single bound record (op 0x07, 17 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x5400:
; [v10] F16006 flags=0x07 len=17
	.byte	0x07, 0x11, 0x61, 0x06, 0x7f, 0x00, 0x1c
	.long	TuningSystem_Handler_Table_0x71F + 0xc
	.byte	0x03, 0x00, 0x3d, 0x00, 0x35, 0x00
; [v10] F16017 flags=0x07 len=17
	.byte	0x07, 0x11, 0x00, 0x00, 0x00, 0x00, 0x1c
	.long	0x00020bf3
	.byte	0x0d, 0x00, 0x69, 0x00, 0x35, 0x00
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF16020
; evidence: SeMenu_PresetManager_Init+0xA5 (0xF0F683)
; single bound record (op 0x07, 17 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x5422:
; [v10] F16028 flags=0x07 len=17
	.byte	0x07, 0x11, 0x6f, 0x06, 0x1f, 0x00, 0x17
	.long	SeBitmap_EnvCurve5_0x1BB8 + 0x149
	.byte	0x02, 0x00, 0x3d, 0x00, 0x7a, 0x00
; [v10] F16039 flags=0x07 len=17
	.byte	0x07, 0x11, 0x00, 0x00, 0x00, 0x00, 0x17
	.long	0x00020c03
	.byte	0x0d, 0x00, 0x49, 0x00, 0x7a, 0x00
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x5444:
; [v10] F1604A flags=0x09 len=12
	.byte	0x09, 0x0c, 0x63, 0x06, 0x7f, 0x00, 0x17, 0xa5, 0x00, 0x7a, 0x00, 0x03
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x5450:
; [v10] F16056 flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x65, 0x06, 0xff, 0x00, 0x17, 0xc3, 0x00, 0x7a, 0x00, 0x02, 0x00
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x545D:
; [v10] F16063 flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x67, 0x06, 0xff, 0x00, 0x17, 0xe1, 0x00, 0x7a, 0x00, 0x02, 0x00
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF16068
; evidence: SeMenu_PresetManager_Init_Code_Skip+0x10 (0xF0F699)
; single bound record (op 0x07, 17 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x546A:
; [v10] F16070 flags=0x07 len=17
	.byte	0x07, 0x11, 0x70, 0x06, 0x1f, 0x00, 0x17
	.long	SeBitmap_EnvCurve5_0x1BB8 + 0x149
	.byte	0x02, 0x00, 0x3d, 0x00, 0x98, 0x00
; [v10] F16081 flags=0x07 len=17
	.byte	0x07, 0x11, 0x00, 0x00, 0x00, 0x00, 0x17
	.long	0x00020c13
	.byte	0x0d, 0x00, 0x49, 0x00, 0x98, 0x00
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x548C:
; [v10] F16092 flags=0x09 len=12
	.byte	0x09, 0x0c, 0x64, 0x06, 0x7f, 0x00, 0x17, 0xa5, 0x00, 0x98, 0x00, 0x03
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x5498:
; [v10] F1609E flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x66, 0x06, 0xff, 0x00, 0x17, 0xc3, 0x00, 0x98, 0x00, 0x02, 0x00
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x54A5:
; [v10] F160AB flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x68, 0x06, 0xff, 0x00, 0x17, 0xe1, 0x00, 0x98, 0x00, 0x02, 0x00
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x54B2:
; [v10] F160B8 flags=0x09 len=12
	.byte	0x09, 0x0c, 0x6b, 0x06, 0x7f, 0x00, 0x17, 0x1c, 0x01, 0x89, 0x00, 0x03
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF160BC
; evidence: SeMenu_PresetManager_Init+0x3B (0xF0F619)
SeScreenData_0x54BE:
; [v10] F160C4 flags=0x07 len=17
	.byte	0x07, 0x11, 0x6c, 0x06, 0x03, 0x00, 0x17
	.long	TuningSystem_Handler_Table_0x117D + 0x94
	.byte	0x03, 0x00, 0x03, 0x01, 0x7a, 0x00
; [v10] F160D5 flags=0x07 len=17
	.byte	0x07, 0x11, 0x6c, 0x06, 0x0c, 0x02, 0x17
	.long	TuningSystem_Handler_Table_0x117D + 0x94
	.byte	0x03, 0x00, 0x03, 0x01, 0x98, 0x00
; single bound record (op 0x03, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x54E0:
; [v10] data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF160F0-0xF16106 (22 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=80% dist=11 near FlashWrite_BlockRef_Type6_0x655+10
; [v10] F160E6 flags=0x03 len=11
	.byte	0x03, 0x0b, 0x60, 0x06, 0x03, 0x00, 0x05
	.long	SeScreenData_0x5503
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x54EB:
; [v10] F160F1 flags=0x09 len=12
	.byte	0x09, 0x0c, 0x6d, 0x06, 0x7f, 0x00, 0x17, 0x09, 0x01, 0x7a, 0x00, 0x02
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16101
SeScreenData_0x54F7:
; [v10] F160FD flags=0x09 len=12
	.byte	0x09, 0x0c, 0x6e, 0x06, 0x7f, 0x00, 0x17, 0x09, 0x01, 0x98, 0x00, 0x02
; table of 3 boxes {u16 x1, y1, x2, y2}, indexed by the masked value of a bound op03/04/08 record (its +7 pointer)
; evidence: bound op03 record 0xF160BC
SeScreenData_0x5503:
; [v10] F16109..F1612F  the length byte at F16109 is 0, so the [flags][len] framing above does NOT continue here.
; [v10] HYPOTHESIS ONLY (it closes exactly on the u32 below, but is not otherwise corroborated):
; [v10] three 8-byte entries, then one len-10 record. Left as untyped .byte rather than guessed at.
; [v10] F16109
; [v10] F16111
; [v10] F16119
	.short	13, 113, 280, 138
	.short	13, 113, 280, 138
	.short	13, 141, 280, 168
; static record list (1 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF16101
; evidence: SeMenu_PresetManager_Init+0x56 (0xF0F634)
SeScreenData_0x551B:
; [v10] F16121
	.byte	0x1b, 0x0a, 0x0d, 0x00, 0x71, 0x00, 0x18, 0x01, 0xa8, 0x00
; table of 17 pointers to bound records; the code loads it into XIY and SeMenu_EqEdit_DrawInit_0x15 draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_WaveformSelect_Data_0xAF+0x1E (0xF0F5D9), SeMenu_PresetManager_Init+0x61 (0xF0F63F), SeMenu_PresetManager_Init_Code_Skip2+0xB (0xF0F6AA)
SeScreenData_0x5525:
; [v10] F1612B -- a u32 pointer to the record at F160E6; DrumDetailEdit_Menu_Table's label may be one entry late
	.byte	0xbc, 0x60, 0xf1, 0x00
DrumDetailEdit_Menu_Table:
; (was .incbin "includes/romslices/v7_fix_drumdetailedit_menu_table.bin")
	.long	SeScreenData_0x5400
	.long	SeScreenData_0x5400
	.long	SeScreenData_0x5444
	.long	SeScreenData_0x548C
	.long	SeScreenData_0x5450
	.long	SeScreenData_0x5498
	.long	SeScreenData_0x545D
	.long	SeScreenData_0x54A5
	.long	SeScreenData_0x54B2
	.long	SeScreenData_0x54B2
	.long	SeScreenData_0x54B2
	.long	SeScreenData_0x54EB
	.long	SeScreenData_0x54EB
	.long	SeScreenData_0x54F7
	.long	SeScreenData_0x5422
	.long	SeScreenData_0x546A
; static record list (20 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF1620F
; evidence: SeMenu_PresetManager_Load+0x17 (0xF0F6C6)
SeScreenData_0x5569:
	.byte	0x23, 0x05, 0x10, 0x7f, 0x00
	.byte	0x23, 0x05, 0x63, 0xa3, 0x0a
	.byte	0x23, 0x05, 0x61, 0xc2, 0x0a
	.byte	0x23, 0x05, 0x21, 0xbb, 0x10
	.byte	0x23, 0x05, 0x5f, 0xda, 0x10
	.byte	0x1c, 0x16, 0x58, 0x00, 0x08, 0x00
	.ascii	"DRUM DETAIL EDIT"
	.byte	0x06, 0x08, 0x7c, 0x0b
	.ascii	"T0NE"
	.byte	0x06, 0x0c, 0x81, 0x0b
	.ascii	"DYNAMICS"
	.byte	0x06, 0x0d, 0x97, 0x0b
	.ascii	"AMPLITUDE"
	.byte	0x06, 0x05, 0xb8, 0x0b, 0x10
	.byte	0x06, 0x05, 0xdf, 0x0b, 0x11
	.byte	0x17, 0x19, 0x8e, 0x00, 0x65, 0x00
	.ascii	"TOTAL KIT PARAMETER"
	.byte	0x06, 0x05, 0xa8, 0x11, 0x10
	.byte	0x06, 0x05, 0xcf, 0x11, 0x11
	.byte	0x06, 0x0e, 0xbe, 0x11
	.ascii	"C0NTR0LLER"
	.byte	0x06, 0x0a, 0xd7, 0x11
	.ascii	"FILTER"
	.byte	0x06, 0x17, 0x15, 0x1e
	.ascii	"DRUM S0UND NAMING "
	.byte	0x11
	.byte	0x09, 0x0a, 0x0f, 0x00, 0x37, 0x00, 0x31, 0x01, 0x8f, 0x00
	.byte	0x09, 0x0a, 0xa3, 0x00, 0xba, 0x00, 0x35, 0x01, 0xcf, 0x00
	.byte	0x09, 0x0a, 0xa5, 0x00, 0xbc, 0x00, 0x33, 0x01, 0xcd, 0x00
; static record list (17 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF162A9
; evidence: SeMenu_CompareAndApply_Check+0xA (0xF0FB4D)
SeScreenData_0x5633:
	.byte	0x17, 0x0b, 0x3b, 0x00, 0x3e, 0x00
	.ascii	"TOUCH"
	.byte	0x17, 0x0b, 0x6b, 0x00, 0x3e, 0x00
	.ascii	"CURVE"
	.byte	0x17, 0x0b, 0x54, 0x00, 0xd1, 0x00
	.ascii	"TOUCH"
	.byte	0x17, 0x0b, 0x7d, 0x00, 0xd1, 0x00
	.ascii	"CURVE"
	.byte	0x06, 0x05, 0x1c, 0x22, 0x8d
	.byte	0x06, 0x05, 0x21, 0x22, 0x8d
	.byte	0x06, 0x05, 0xac, 0x23, 0x8e
	.byte	0x06, 0x05, 0xb1, 0x23, 0x8e
; [v10] F16279 -- remainder of the source line the descriptor ends inside
	.byte	0x22, 0x0a, 0x0b, 0x00, 0x38, 0x00, 0x9c, 0x00, 0x8a, 0x00
	.byte	0x22, 0x0a, 0x59, 0x00, 0xda, 0x00, 0x6e, 0x00, 0xee, 0x00
	.byte	0x22, 0x0a, 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee, 0x00
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x4a, 0x00, 0x9c, 0x00, 0x4a, 0x00
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x6a, 0x00, 0x9c, 0x00, 0x6a, 0x00
	.byte	0x01, 0x0a, 0x59, 0x00, 0xe4, 0x00, 0x6e, 0x00, 0xe4, 0x00
	.byte	0x01, 0x0a, 0x81, 0x00, 0xe4, 0x00, 0x96, 0x00, 0xe4, 0x00
	.byte	0x02, 0x0a, 0x2e, 0x00, 0x38, 0x00, 0x2e, 0x00, 0x8a, 0x00
	.byte	0x05, 0x0a, 0x16, 0x01, 0x43, 0x00, 0x32, 0x01, 0x5c, 0x00
; static record list (23 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF16380
; evidence: SeMenu_Utility_CopyBlock_Skip+0x18 (0xF0FC77)
SeScreenData_0x56CD:
	.byte	0x06, 0x13, 0x60, 0x1d, 0x10
	.ascii	"KEY OFF MODE :"
	.byte	0x17, 0x0b, 0x18, 0x01, 0xc2, 0x00
	.ascii	"TOUCH"
	.byte	0x17, 0x09, 0x09, 0x00, 0xcf, 0x00, 0x41, 0x54, 0x4b
	.byte	0x17, 0x0c, 0x27, 0x00, 0xcf, 0x00
	.ascii	"DECAY1"
	.byte	0x17, 0x0b, 0x51, 0x00, 0xcf, 0x00
	.ascii	"SUST1"
	.byte	0x17, 0x0c, 0x7b, 0x00, 0xcf, 0x00
	.ascii	"DECAY2"
	.byte	0x17, 0x0b, 0xa5, 0x00, 0xcf, 0x00
	.ascii	"SUST2"
	.byte	0x17, 0x0d, 0xcf, 0x00, 0xcf, 0x00
	.ascii	"RELEASE"
	.byte	0x17, 0x0c, 0x18, 0x01, 0xcf, 0x00
	.ascii	"ATTACK"
	.byte	0x07, 0x05, 0x1a, 0x24, 0x12
	.byte	0x07, 0x05, 0x1f, 0x24, 0x12
	.byte	0x07, 0x05, 0x24, 0x24, 0x12
	.byte	0x07, 0x05, 0x29, 0x24, 0x12
	.byte	0x07, 0x05, 0x2e, 0x24, 0x12
	.byte	0x07, 0x05, 0x34, 0x24, 0x12
	.byte	0x07, 0x05, 0x3e, 0x24, 0x12
	.byte	0x09, 0x0a, 0x03, 0x00, 0xcb, 0x00, 0xfd, 0x00, 0xe8, 0x00
	.byte	0x09, 0x0a, 0x14, 0x01, 0xcb, 0x00, 0x3f, 0x01, 0xe8, 0x00
	.byte	0x01, 0x0a, 0x03, 0x00, 0xd9, 0x00, 0xfd, 0x00, 0xd9, 0x00
	.byte	0x01, 0x0a, 0x14, 0x01, 0xd9, 0x00, 0x3f, 0x01, 0xd9, 0x00
	.byte	0x05, 0x0a, 0x16, 0x01, 0x27, 0x00, 0x32, 0x01, 0x34, 0x00
	.byte	0x05, 0x0a, 0x04, 0x00, 0xda, 0x00, 0xfc, 0x00, 0xe7, 0x00
	.byte	0x05, 0x0a, 0x15, 0x01, 0xda, 0x00, 0x3e, 0x01, 0xe7, 0x00
; bound record list (5 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF163B7
; evidence: SeMenu_CompareAndApply_Apply+0x10 (0xF0FB8A)
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163B7
SeScreenData_0x57A4:
	.byte	0x05, 0x0b, 0x61, 0x06, 0xff, 0x00, 0x20, 0x50, 0x0d, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163B7
SeScreenData_0x57AF:
	.byte	0x05, 0x0b, 0x62, 0x06, 0xff, 0x00, 0x20, 0x50, 0x12, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163B7
SeScreenData_0x57BA:
	.byte	0x05, 0x0b, 0x63, 0x06, 0xe0, 0x05, 0x20, 0x55, 0x0d, 0x02, 0x03
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163B7
SeScreenData_0x57C5:
	.byte	0x05, 0x0b, 0x64, 0x06, 0xe0, 0x05, 0x20, 0x55, 0x12, 0x02, 0x03
; single bound record (op 0x03, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163B7
SeScreenData_0x57D0:
	.byte	0x03, 0x0b, 0x5d, 0x06, 0x0f, 0x00, 0x05
	.long	SeScreenData_0x57F9
; table of 5 pointers to bound records; the code loads it into XIY and SeMenu_EqEdit_DrawInit_0x15 draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_DataBlock_01+0x6A (0xF103DE)
SeScreenData_0x57DB:
	.long	SeScreenData_0x57D0
	.long	SeScreenData_0x57A4
	.long	SeScreenData_0x57AF
	.long	SeScreenData_0x57BA
	.long	SeScreenData_0x57C5
; static record list (1 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF163D5
; evidence: SeMenu_DataBlock_01+0x4B (0xF103BF)
SeScreenData_0x57EF:
	.byte	0x1b, 0x0a, 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x88, 0x00
; table of 3 boxes {u16 x1, y1, x2, y2}, indexed by the masked value of a bound op03/04/08 record (its +7 pointer)
; evidence: bound op03 record 0xF163AC
SeScreenData_0x57F9:
	.short	13, 76, 154, 104
	.short	13, 76, 154, 104
	.short	13, 108, 154, 136
; bound record list (6 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF1642F
; evidence: SeMenu_Utility_CopyBlock_Skip2+0xA (0xF0FCAA)
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x5811:
	.byte	0x02, 0x0f, 0x60, 0x06, 0x20, 0x05, 0x20
	.long	SeBitmap_EnvCurve5_0x4B0 + 0x53
	.byte	0x03, 0x00, 0x70, 0x1d
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x5820:
	.byte	0x00, 0x0a, 0x61, 0x06, 0x7f, 0x00, 0x20, 0x61, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x582A:
	.byte	0x00, 0x0a, 0x62, 0x06, 0x7f, 0x00, 0x20, 0x65, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x5834:
	.byte	0x00, 0x0a, 0x63, 0x06, 0x7f, 0x00, 0x20, 0x6a, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x583E:
	.byte	0x00, 0x0a, 0x64, 0x06, 0x7f, 0x00, 0x20, 0x6f, 0x22, 0x03
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x5848:
	.byte	0x05, 0x0b, 0x67, 0x06, 0xff, 0x00, 0x20, 0x84, 0x22, 0x02, 0x00
; table of 8 pointers to bound records; the code loads it into XIY and SeMenu_EqEdit_DrawInit_0x15 draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_DataBlock_03+0x1D (0xF10410), SeMenu_DataBlock_03+0x32 (0xF10425)
SeScreenData_0x5853:
	.long	SeScreenData_0x5811
	.long	SeScreenData_0x5820
	.long	SeScreenData_0x582A
	.long	SeScreenData_0x5834
	.long	SeScreenData_0x583E
	.long	SeScreenData_0x5873
	.long	SeScreenData_0x587D
	.long	SeScreenData_0x5848
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF16463
; evidence: SeMenu_Utility_CopyBlock_Helper+0x19 (0xF0FCD0)
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x5873:
	.byte	0x00, 0x0a, 0x65, 0x06, 0x7f, 0x00, 0x20, 0x74, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1642F
SeScreenData_0x587D:
	.byte	0x00, 0x0a, 0x66, 0x06, 0x7f, 0x00, 0x20, 0x7a, 0x22, 0x03
; static record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF16471
; evidence: SeMenu_Utility_CopyBlock_Skip3+0xA (0xF0FCF4)
SeScreenData_0x5887:
	.byte	0x20, 0x07, 0x74, 0x22, 0x20, 0x2d, 0x2d
	.byte	0x20, 0x07, 0x7a, 0x22, 0x20, 0x2d, 0x2d
; bound record list (8 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF164CD
; evidence: SeMenu_NameEdit_DataBlock2+0x18 (0xF100BE)
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x5895:
	.byte	0x05, 0x0b, 0x61, 0x06, 0xff, 0x00, 0x20, 0xb0, 0x0a, 0x02, 0x00
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58A0:
	.byte	0x02, 0x0f, 0x62, 0x06, 0x1f, 0x00, 0x20
	.long	SeScreenData_0x59A3
	.byte	0x03, 0x00, 0xc8, 0x10
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58AF:
	.byte	0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0x30, 0x17, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58BA:
	.byte	0x05, 0x0b, 0x64, 0x06, 0xff, 0x00, 0x20, 0x70, 0x1d, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58C5:
	.byte	0x05, 0x0b, 0x69, 0x06, 0x0f, 0x00, 0x20, 0x9b, 0x0a, 0x02, 0x08
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58D0:
	.byte	0x05, 0x0b, 0x66, 0x06, 0xff, 0x00, 0x20, 0xb3, 0x10, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58DB:
	.byte	0x05, 0x0b, 0x67, 0x06, 0xff, 0x00, 0x20, 0x1b, 0x17, 0x02, 0x00
; single bound record (op 0x03, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16505
SeScreenData_0x58E6:
	.byte	0x03, 0x0b, 0x60, 0x06, 0x0f, 0x00, 0x05
	.long	SeScreenData_0x5951
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: SeMenu_NameEdit_HandleInput (0xF10117)
SeScreenData_0x58F1:
	.byte	0x02, 0x0f, 0x6a, 0x06, 0x0f, 0x00, 0x20
	.long	SeScreenData_0x4EFB
	.byte	0x0d, 0x00, 0x8e, 0x1e
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: SeMenu_NameEdit_HandleInput (0xF10117)
SeScreenData_0x5900:
	.byte	0x02, 0x0f, 0x6a, 0x06, 0x80, 0x07, 0x20
	.long	SeScreenData_0x590F
	.byte	0x0d, 0x00, 0x8e, 0x1e
; fixed-width string table, 13 chars per entry, 26 B: the text choices of a bound op02/op07 record (its +7 pointer; +11 = chars per entry)
; evidence: bound op02 record 0xF164DC
SeScreenData_0x590F:
	.ascii	"OFF          "
	.ascii	"OFF          "
; table of 10 pointers to bound records; the code loads it into XIY and SeMenu_EqEdit_DrawInit_0x15 draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_NameEdit_DefaultPath+0xB (0xF100F7)
; (name EffectParam_Edit_Table kept: other files use it; the object is ScreenData, see above)
EffectParam_Edit_Table:
; (was .incbin "includes/romslices/v7_fix_effectparam_edit_table.bin")
	.long	SeScreenData_0x58E6
	.long	SeScreenData_0x5895
	.long	SeScreenData_0x58A0
	.long	SeScreenData_0x58AF
	.long	SeScreenData_0x58BA
	.long	SeScreenData_0x58BA
	.long	SeScreenData_0x58D0
	.long	SeScreenData_0x58DB
	.long	SeScreenData_0x58DB
	.long	SeScreenData_0x58C5
; table of 9 boxes {u16 x1, y1, x2, y2}, indexed by the masked value of a bound op03/04/08 record (its +7 pointer)
; evidence: bound op03 record 0xF164C2
SeScreenData_0x5951:
	.short	12, 59, 155, 88
	.short	12, 59, 155, 88
	.short	12, 98, 155, 127
	.short	12, 138, 155, 167
	.short	12, 179, 155, 208
	.short	164, 58, 307, 88
	.short	164, 98, 307, 127
	.short	164, 138, 307, 167
	.short	164, 179, 307, 208
; static record list (1 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF1657F
; evidence: SeMenu_NameEdit_SetupPath+0x10 (0xF100E6)
SeScreenData_0x5999:
	.byte	0x1b, 0x0a, 0x0c, 0x00, 0x3b, 0x00, 0x33, 0x01, 0xd0, 0x00
; fixed-width string table, 3 chars per entry, 66 B: the text choices of a bound op02/op07 record (its +7 pointer; +11 = chars per entry)
; evidence: bound op02 record 0xF1647C
SeScreenData_0x59A3:
	.ascii	"OFF"
	.ascii	"-10"
	.ascii	"- 9"
	.ascii	"- 8"
	.ascii	"- 7"
	.ascii	"- 6"
	.ascii	"- 5"
	.ascii	"- 4"
	.ascii	"- 3"
	.ascii	"- 2"
	.ascii	"- 1"
	.ascii	"  0"
	.ascii	"+ 1"
	.ascii	"+ 2"
	.ascii	"+ 3"
	.ascii	"+ 4"
	.ascii	"+ 5"
	.ascii	"+ 6"
	.ascii	"+ 7"
	.ascii	"+ 8"
	.ascii	"+ 9"
	.ascii	"+10"
InitializeNaka:
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Class
	ld (XBC),XWA
	lda xwa, (ClassProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe0e95c:24)
	ld (XBC+0x08),WA
	lda xwa, (ToneGen_ParamTable_0x53D:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x016b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResEvent
	ld (XBC),XWA
	lda xwa, (ResEventProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe0e962:24)
	ld (XBC+0x08),WA
	lda xwa, (ToneGen_ParamTable_0x557:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01cb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResMethod
	ld (XBC),XWA
	lda xwa, (ResMethodProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe0e968:24)
	ld (XBC+0x08),WA
	lda xwa, (ToneGen_ParamTable_0x55D:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01eb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0012
	lda xwa, (ToneGen_ParamTable_0x3A7:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x012b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0012
	lda xwa, (ToneGen_ParamTable_0x3F3:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x042b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (ToneGen_ParamTable_0x563:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x010b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (ToneGen_ParamTable_0x567:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x040b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xe14824:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x014b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xe14828:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x044b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x01de
	lda xwa, (NAKA_UIObjectTable:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00fd
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x01de
	lda xwa, (0xe13bca:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03fd
	call RegisterObjectTable
	pushw 0x000b
	pushw InitializeNaka_Str_TT_FDMSP@hi16
	pushw InitializeNaka_Str_TT_FDMSP@lo16
	ld XWA,0x000000fd
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00fd0000
	call RegisterTitle
	lda xsp, (xsp + 0x0e)
	ret
NAKA_InitDataBlock:
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip
	lda	xhl, (NAKA_InitDataBlock_PtrTable:24)
	ret
InitializeNaka_Skip:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip2
	lda	xhl, (NAKA_InitDataBlock_PtrTable_2:24)
	ret
InitializeNaka_Skip2:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip3
	lda	xhl, (NAKA_InitDataBlock_PtrTable_3:24)
	ret
InitializeNaka_Skip3:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip4
	lda	xhl, (NAKA_InitDataBlock_PtrTable_4:24)
	ret
InitializeNaka_Skip4:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip5
	lda	xhl, (NAKA_InitDataBlock_PtrTable_5:24)
	ret
InitializeNaka_Skip5:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip6
	lda	xhl, (NAKA_InitDataBlock_PtrTable_6:24)
	ret
InitializeNaka_Skip6:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip7
	lda	xhl, (NAKA_InitDataBlock_PtrTable_7:24)
	ret
InitializeNaka_Skip7:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip8
	lda	xhl, (NAKA_InitDataBlock_PtrTable_8:24)
	ret
InitializeNaka_Skip8:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip9
	lda	xhl, (NAKA_InitDataBlock_PtrTable_9:24)
	ret
InitializeNaka_Skip9:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip10
	lda	xhl, (NAKA_InitDataBlock_PtrTable_10:24)
	ret
InitializeNaka_Skip10:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip11
	lda	xhl, (NAKA_InitDataBlock_PtrTable_11:24)
	ret
InitializeNaka_Skip11:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip12
	lda	xhl, (NAKA_InitDataBlock_PtrTable_12:24)
	ret
InitializeNaka_Skip12:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip13
	lda	xhl, (NAKA_InitDataBlock_PtrTable_13:24)
	ret
InitializeNaka_Skip13:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip14
	lda	xhl, (NAKA_InitDataBlock_PtrTable_14:24)
	ret
InitializeNaka_Skip14:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip15
	lda	xhl, (NAKA_InitDataBlock_PtrTable_15:24)
	ret
InitializeNaka_Skip15:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip16
	lda	xhl, (NAKA_InitDataBlock_PtrTable_16:24)
	ret
InitializeNaka_Skip16:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip17
	lda	xhl, (NAKA_InitDataBlock_PtrTable_17:24)
	ret
InitializeNaka_Skip17:
	ld	xhl, 0:i3
	ret
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, InitializeNaka_Skip18
	lda	xhl, (NAKA_InitDataBlock_PtrTable_18:24)
	ret
InitializeNaka_Skip18:
	ld	xhl, 0:i3
	ret
InitializeNaka_Join:
	calr	Flash_InitExtMemAddrs
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 1:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 2:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 3:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 4:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 5:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 6:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	wa, 7:i3
	calr	NoteEventBuffer_Store
	jrl	Flash_ExtendedOpsBlock_Code_Join

NoteEvent_LoadSoundGenParams:
	lda xsp, (xsp-364)
	push xiz
	ld xiy, NAKA_UIObjectTable_0x26D2
	lda xix, (xsp+272)
	ldw bc, 0x30
	ldirw
	ld xiy, NAKA_UIObjectTable_0x25D2
	lda xix, (xsp + 16)
	ldw bc, 0x80
	ldirw
	ld xix, (3186:16)
	ld xiy, MSP_Default_Signature1
	ldw bc, 0x30
	ldirw
	ld xwa, (3186:16)
	ld xiy, MSP_Default_VoiceEnable
	lda xix, (xwa+5056)
	ldw bc, 0x20
	ldirw
	ld xbc, (3186:16)
	ld xwa, 0xba0
	add xbc, xwa
	ld xwa, xbc
	lda xde, (xbc+128:16)

NoteEvent_CopyVoiceParamsLoop:
	ld xiy, MSP_Default_SoundReserved_0x30
	ld xix, xwa
	ldw bc, 0x10
	ldirw
	lda xwa, (xwa + 32)
	cp xwa, xde
	jr ule, NoteEvent_CopyVoiceParamsLoop
	ld xwa, (3186:16)
	lda xwa, (xwa+3136)
	ld xde, xwa
	lda xwa, (xwa+1760)
	ld (xsp + 12), xwa

NoteEvent_CopyExtParamsOuter:
	ld xwa, xde
	lda xhl, (xde+128:16)

NoteEvent_CopyExtParamsInner:
	ld xiy, MSP_Default_SoundReserved_0x50
	ld xix, xwa
	ldw bc, 0x10
	ldirw
	lda xwa, (xwa + 32)
	cp xwa, xhl
	jr ule, NoteEvent_CopyExtParamsInner
	lda xde, (xde+160:16)
	cp xde, (xsp + 12)
	jr ule, NoteEvent_CopyExtParamsOuter
	lda xwa, (xsp+272)
	ld (xsp + 4), xwa
	lda xbc, (xwa + 4)
	ld (xsp + 8), xbc
	lda xiz, (xwa + 6)
	lda xbc, (xwa + 8)
	ld (xsp + 12), xbc
	lda xhl, (xwa + 10)
	ld xwa, (3186:16)
	lda xwa, (xwa + 96)
	ld de, 4:i3

NoteEvent_WriteRegOffsets_Loop:
	ld ix, de
	add ix, 0xfffc
	ld xbc, (xsp + 4)
	ld (xbc), ix
	ld ix, de
	add ix, 0xfffd
	ld xbc, (xsp + 8)
	ld (xbc), ix
	ld bc, de
	add bc, 0xfffe
	ld (xiz), bc
	ld ix, de
	add ix, 0xffff
	ld xbc, (xsp + 12)
	ld (xbc), ix
	ld (xhl), de
	lda xiy, (xsp+272)
	ld xix, xwa
	ldw bc, 0x30
	ldirw
	inc 5, de
	lda xwa, (xwa + 96)
	cp de, 0x95
	jr ule, NoteEvent_WriteRegOffsets_Loop
	ld de, 0:i3
	ld xwa, 0x1400

NoteEvent_CopySlotData_Loop:
	cp de, 0x96
	jr c, NoteEvent_CopySlotData_Body
	ld (xsp + 16), 0x0

NoteEvent_CopySlotData_Body:
	ld xix, xwa
	add xix, (3186:16)
	lda xiy, (xsp + 16)
	ldw bc, 0x80
	ldirw
	inc 1, de
	add xwa, 0x100
	cp de, 0x153
	jr ule, NoteEvent_CopySlotData_Loop
	pop xiz
	lda xsp, (xsp+364)
	ret

Flash_InitExtMemAddrs:
	lda xwa, (0x300000:24)
	ld (3190:16), xwa
	ld xbc, xwa
	add xbc, 0x19800
	ld (3194:16), xbc
	ld xbc, xwa
	add xbc, 0x30000
	ld (3198:16), xbc
	ld xbc, xwa
	add xbc, 0x49800
	ld (3202:16), xbc
	ld xbc, xwa
	add xbc, 0x60000
	ld (3206:16), xbc
	ld xbc, xwa
	add xbc, 0x79800
	ld (3210:16), xbc
	ld xbc, xwa
	add xbc, 0x90000
	ld (3214:16), xbc
	ld xbc, xwa
	add xbc, 0xb0000
	ld (3218:16), xbc
	lda xwa, (0x094800:24)
	ld (3182:16), xwa
	lda xwa, (0x069800:24)
	ld (3186:16), xwa
	ld (3222:16), xwa
	ret
Flash_InitBytecodeBlock:
	lda	xsp, (xsp-12)
	push	qiz
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	(xsp+2), 0
	ld	(xsp+8), 0
	calr	Flash_InitExtMemAddrs
	ld	a, (xsp+12)
	extz	wa
	cp	(xsp+0xc), 10
	jrl	nc, Flash_InitBytecodeBlock_Skip5
	calr	DualVoice_ScanAllColumns
	ld	a, (xsp+10)
	extz	wa
	calr	DualVoice_ScanAllColumnsAlt
	ld	a, (xsp+10)
	extz	wa
	calr	NoteEvent_Store
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_CopyToSlot
	call	AccPatch_CountSlotsAlt
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld_rrb	a, xbc, wa
	ld	(xsp+6), a
	ld	xwa, (3186:16)
	ld	(14610:16), xwa
	ldib_erp	251, 0
Flash_InitBytecodeBlock_Loop:
	ld	c, (xsp+6)
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (MSP_Default_ChannelMap:24)
	ld	(0x3910), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, Flash_InitBytecodeBlock_Loop
	ld	xwa, (3182:16)
	ld	(14610:16), xwa
	ld	xwa, (3186:16)
	ld	(14614:16), xwa
	res	0, (0x3514:16)
	ldib_erp	251, 0
Flash_InitBytecodeBlock_Loop2:
	ld	e, (xsp+12)
	extz	de
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (MSP_Default_ChannelMap:24)
	ld	(0x3910), (xde+wa)
	ld	a, (xsp+6)
	extz	wa
	add	bc, wa
	ld	(0x3911), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, Flash_InitBytecodeBlock_Skip
	ld	(xsp+8), 1
	jr	Flash_InitBytecodeBlock_Join
Flash_InitBytecodeBlock_Skip:
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, Flash_InitBytecodeBlock_Loop2
Flash_InitBytecodeBlock_Join:
	call	AccPatch_CountSlots_Wrapper
	cp	(xsp+0x8), 0
	jrl	nz, Flash_InitBytecodeBlock_Loop3
	lda	xwa, (1748:16)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip3
	cpw	(xwa+0x2), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip3
	calr	Flash_StoreBaseAndInitAccPatch
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
	lda	xwa, (1850:16)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip2
	cpw	(xwa+0x2), 0xffff
	jrl	z, Flash_InitBytecodeBlock_Join5
Flash_InitBytecodeBlock_Skip2:
	calr	Flash_WriteBackSlotTable
	jrl	Flash_InitBytecodeBlock_Join5
Flash_InitBytecodeBlock_Skip3:
	ld	a, (xsp+10)
	extz	wa
	calr	Flash_SlotUpdateOpsBlock
	ld	wa, hl
	ld	c, (xsp+10)
	extz	bc
	cp	wa, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Skip4
	ld	wa, bc
	calr	Flash_InitBytecodeBlock_Helper
	ld	a, (xsp+6)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper3
	calr	Flash_StoreBaseAndInitAccPatch
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
	ld	a, (xsp+10)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper4
	calr	Flash_InitBytecodeBlock_Helper5
	call	TmFlash_CopyToExtMem
	jrl	Flash_InitBytecodeBlock_Join5
Flash_InitBytecodeBlock_Skip4:
	calr	Flash_InitBytecodeBlock_Helper8
	calr	Flash_InitBytecodeBlock_Helper10
	calr	Flash_InitBytecodeBlock_Helper12
	calr	Flash_InitBytecodeBlock_Helper7
	jrl	Flash_InitBytecodeBlock_Join3
Flash_InitBytecodeBlock_Loop3:
	ld	(xsp+2), 1
	jrl	Flash_InitBytecodeBlock_Join2
Flash_InitBytecodeBlock_Skip5:
	calr	DualVoice_ScanAllColumns
	ld	a, (xsp+10)
	extz	wa
	calr	DualVoice_ScanAllColumnsAlt
	ld	xix, (3186:16)
	ld	xiy, (3182:16)
	ldw	bc, 46080
	ldirw
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld_rrb	a, xbc, wa
	ld	(xsp+6), a
	ld	xwa, (3186:16)
	ld	(14610:16), xwa
	ldib_erp	251, 0
Flash_InitBytecodeBlock_Loop4:
	ld	c, (xsp+10)
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (MSP_Default_ChannelMap:24)
	ld	(0x3910), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, Flash_InitBytecodeBlock_Loop4
	ld	a, (xsp+12)
	extz	wa
	calr	PartGrid_ColumnDispatch
	ld	(14610:16), xhl
	ld	xwa, (3186:16)
	ld	(14614:16), xwa
	res	0, (0x3514:16)
	ldib_erp	251, 0
Flash_InitBytecodeBlock_Loop5:
	ld	e, (xsp+6)
	extz	de
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (MSP_Default_ChannelMap:24)
	ld	(0x3910), (xde+wa)
	ld	a, (xsp+10)
	extz	wa
	add	bc, wa
	ld	(0x3911), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, Flash_InitBytecodeBlock_Skip6
	ld	(xsp+8), 1
	ld	xwa, (14614:16)
	ld	(14610:16), xwa
	ldmm8	0x3910, 0x3911
	call	AccPatch_InitFromSlotIndex
	jr	Flash_InitBytecodeBlock_Entry
Flash_InitBytecodeBlock_Skip6:
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, Flash_InitBytecodeBlock_Loop5
Flash_InitBytecodeBlock_Entry:
	cp	(xsp+0x8), 0
	jrl	nz, Flash_InitBytecodeBlock_Loop3
	lda	xwa, (1748:16)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip7
	cpw	(xwa+0x2), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip7
	ld	xix, (3182:16)
	ld	xiy, (3186:16)
	ldw	bc, 46080
	ldirw
Flash_InitBytecodeBlock_Join5:
	cp	(xsp+0x2), 2
	jr	nz, Flash_InitBytecodeBlock_Join2
	ld	(0xc68), (xsp+0xc)
	ld	(0xc6a), (xsp+0xa)
	ld	(0xc6c), (xsp+0x6)
Flash_InitBytecodeBlock_Join2:
	call	AccPatch_CountSlots_Wrapper
	ld	l, (xsp+2)
	pop qiz
	lda	xsp, (xsp+12)
	ret
Flash_InitBytecodeBlock_Skip7:
	ld	a, (xsp+10)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper2
	calr	Flash_InitBytecodeBlock_Helper11
Flash_InitBytecodeBlock_Join3:
	ld	(xsp+2), 2
	ld	(0xc68), (xsp+0xc)
	ld	(0xc6a), (xsp+0xa)
	ld	(0xc6c), (xsp+0x6)
	jr	Flash_InitBytecodeBlock_Join5
CstmCpTtlFunc_Helper:
	dec	2, xsp
	ld	(xsp), a
	calr	Flash_InitExtMemAddrs
	ld	l, (3176:16)
	ld	c, (3178:16)
	ld	e, (3180:16)
	cp	(xsp), 2
	jr	z, Flash_InitBytecodeBlock_Join4
	cp	(xsp), 0
	jr	nz, Flash_InitBytecodeBlock_Join4
	ld	a, l
	extz	wa
	extz	bc
	extz	de
	cp	l, 10
	jr	nc, Flash_InitBytecodeBlock_Skip8
	calr	Flash_InitBytecodeBlock_Helper6
	jr	Flash_InitBytecodeBlock_Join4
Flash_InitBytecodeBlock_Skip8:
	calr	Flash_InitBytecodeBlock_Helper9
Flash_InitBytecodeBlock_Join4:
	ld	l, 0:opc
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	Flash_InitExtMemAddrs
	ld	a, (3176:16)
	ld	c, (3178:16)
	ld	e, (3180:16)
	cp	(xsp), 2
	jr	z, Flash_InitBytecodeBlock_Skip9
	cp	(xsp), 0
	jr	nz, Flash_InitBytecodeBlock_Skip9
	extz	wa
	extz	bc
	extz	de
	calr	Flash_InitBytecodeBlock_Helper9
Flash_InitBytecodeBlock_Skip9:
	call	AccPatch_CountSlots_Wrapper
	ld	l, 0:opc
	inc	2, xsp
	ret
	jrl	InitializeNaka_Join
PartGrid_ColumnDispatch:
	ld xhl, (3182:16)
	ld xbc, (3186:16)
	cp a, 0x1e
	jr nc, PartGrid_CopyHLtoBC
	cp a, 0xa
	ret c
	sub a, 0xa
	extz wa
	div a, 0x3
	extz wa
	cp wa, 0:i3
	jr mi, PartGrid_CopyHLtoBC
	cp wa, 6:i3
	jr gt, PartGrid_CopyHLtoBC
	add wa, wa
	lda xix, (MSP_Default_GroupOffsetA:24)
	ld	wa, (xix+wa)
	lda xix, (PartGrid_ColumnJumpTable:24)
	jp	t, (xix+wa)

PartGrid_ColumnJumpTable:
	ld	xhl, (3190:16)
	jr	PartGrid_ColumnDispatch_Return
	ld	xhl, (3194:16)
	jr	PartGrid_ColumnDispatch_Return
	ld	xhl, (3198:16)
	jr	PartGrid_ColumnDispatch_Return
	ld	xhl, (3202:16)
	jr	PartGrid_ColumnDispatch_Return
	ld	xhl, (3206:16)
	jr	PartGrid_ColumnDispatch_Return
	ld	xhl, (3210:16)
	jr	PartGrid_ColumnDispatch_Return
	ld	xhl, (3214:16)
	jr	t, PartGrid_ColumnDispatch_Return

PartGrid_CopyHLtoBC:
	ld xhl, xbc
PartGrid_ColumnDispatch_Return:
	ret

Util_FrameSetup10:
	lda xsp, (xsp - 10)
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr PartGrid_ColumnDispatch
	ld (xsp), xhl
	cp (xsp + 8), 0x1e
	jr c, FrameSetup_AdjustGE1E
	submi8 (xsp + 8), 0x1e
	jr FrameSetup_ComputeGridIndex

FrameSetup_AdjustGE1E:
	cp (xsp + 8), 0xa
	jr c, FrameSetup_ComputeGridIndex
	submi8 (xsp + 8), 0xa
	ld a, (xsp + 8)
	extz wa
	div a, 0x3
	ld (xsp + 8), w

FrameSetup_ComputeGridIndex:
	ld c, (xsp + 8)
	extz bc
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x3
	add wa, bc
	lda xbc, (MSP_Default_ChannelMap:24)
	ld	a, (xbc+wa)
	ld e, (xsp + 4)
	cp (xsp + 4), 0x4
	jr z, FrameSetup_SpecialCase4
	extz wa
	muls wa, 0x60
	ld bc, wa
	add bc, 0x60
	ld xwa, (xsp)
	exts xbc
	add xbc, xwa
	cp e, 3:i3
	jr z, FrameSetup_RowOffset3
	cp e, 2:i3
	jr z, FrameSetup_RowOffset2
	cp e, 1:i3
	jr z, FrameSetup_RowOffset1
	cp e, 0:i3
	jr nz, FrameSetup_PackResult
	ld l, (xbc + 24)
	ld xwa, 0x19
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset1:
	ld l, (xbc + 32)
	ld xwa, 0x21
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset2:
	ld l, (xbc + 40)
	ld xwa, 0x29
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset3:
	ld l, (xbc + 48)
	ld xwa, 0x31

PartGrid_ByteOffsetLoop:
	add xbc, xwa
	ld a, (xbc)
	jr FrameSetup_PackResult

FrameSetup_SpecialCase4:
	extz wa
	muls wa, 0x60
	ld bc, wa
	add bc, 0x60
	ld xwa, (xsp)
	lda	xwa, (xwa+bc)
	ld l, (xwa + 56)
	ld a, (xwa + 57)

FrameSetup_PackResult:
	ld c, l
	extz bc
	extz wa
	sll wa, 8
	or wa, bc
	ld hl, wa
	lda xsp, (xsp + 10)
	ret

PartGrid_OperationsBlock:
	lda	xsp, (xsp-14)
	ld	(xsp+8), e
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	a, (xsp+12)
	extz	wa
	calr	PartGrid_ColumnDispatch
	ld	(xsp+4), xhl
	cp	(xsp+12), 30
	jr	c, PartGrid_OperationsBlock_Skip2
	submi8	(xsp+0xc), 30
	jr	PartGrid_OperationsBlock_Join
PartGrid_OperationsBlock_Skip2:
	cp	(xsp+0xc), 10
	jr	c, PartGrid_OperationsBlock_Join
	submi8	(xsp+0xc), 10
	ld	a, (xsp+0xc)
	extz	wa
	div	a, 3
	ld	(xsp+12), w
PartGrid_OperationsBlock_Join:
	ld	c, (xsp+12)
	extz	bc
	ld	a, (xsp+10)
	extz	wa
	muls	wa, 3
	add	wa, bc
	lda	xbc, (MSP_Default_ChannelMap:24)
	ld_rrb	a, xbc, wa
	ld	(xsp+2), a
	ld	bc, (xsp+18)
	ld	de, bc
	ld	d, 0:opc
	srl	bc, 8
	ld	(xsp), c
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ld	xwa, (xsp+4)
	exts	xbc
	add	xbc, xwa
	cp	(xsp+8), 4
	jr	z, PartGrid_OperationsBlock_Skip
	cp	(xsp+8), 3
	jr	z, 48
	cp	(xsp+8), 2
	jr	z, 32
	cp	(xsp+8), 1
	jr	z, 16
	cp	(xsp+8), 0
	jr	nz, 54
	ld	(xbc+24), e
	ld	xwa, 25
	jr	38
	.byte 0xb9
	.asciz " E@!"
	nop
	nop
	jr	28
	.byte 0xb9
	.asciz "(E@)"
	nop
	nop
	jr	18
	ld	(xbc+48), e
	ld	xwa, 49
	jr	8
PartGrid_OperationsBlock_Skip:
	ld	(xbc+56), e
	ld	xwa, 57
	add	xbc, xwa
	ld	a, (xsp)
	ld	(xbc), a
	lda	xsp, (xsp+14)
	retd	2

; PartGrid column dispatch end
PartGrid_ColumnDispatch_End:
	ld wa, 0:i3
	jr PartGrid_ColumnDispatch_Default

; PartGrid column dispatch default case
PartGrid_ColumnDispatch_Default:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ldiw_erp 0xfa, 0

PartGrid_DefaultLoop_Outer:
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	add xbc, 0x60
	add xbc, (3186:16)
	ld wa, (xbc)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ldto_werp BC, 0xfa
	extz xbc
	ld xde, xbc
	add xde, xde
	add xde, xbc
	sll xde, 5
	add xde, 0x60
	add xde, (3186:16)
	ld (xde), wa
	ld iz, 2:i3

PartGrid_DefaultLoop_Inner:
	ld bc, iz
	extz xbc
	add xbc, xbc
	ldto_werp WA, 0xfa
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 5
	add xde, xbc
	add xde, (3186:16)
	ld wa, (xde + 96)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ld de, iz
	extz xde
	add xde, xde
	ldto_werp BC, 0xfa
	extz xbc
	ld xhl, xbc
	add xhl, xhl
	add xhl, xbc
	sll xhl, 5
	add xhl, xde
	add xhl, (3186:16)
	ld (xhl + 96), wa
	inc 1, iz
	cp iz, 5:i3
	jr ule, PartGrid_DefaultLoop_Inner
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x1d, 0x00
	jrl ule, PartGrid_DefaultLoop_Outer
	ldiw_erp 0xfa, 0

; NoteEventBuffer CopyToSlot dispatch (7-entry, table 0xe16128)
NoteEvent_CopyToSlot:
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 8
	add xwa, 0x1400
	add xwa, (3186:16)
	ld wa, (xwa + 1)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ldto_werp BC, 0xfa
	extz xbc
	sll xbc, 8
	add xbc, 0x1400
	ld xde, xbc
	add xde, (3186:16)
	ld (xde + 1), wa
	add xbc, (3186:16)
	ld wa, (xbc + 3)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ldto_werp BC, 0xfa
	extz xbc
	sll xbc, 8
	add xbc, 0x1400
	add xbc, (3186:16)
	ld (xbc + 3), wa
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x53, 0x01
	jr ule, NoteEvent_CopyToSlot
	pop xiz
	inc 2, xsp
	ret

Pack12BitValueWithBank:
	ld hl, wa
	cp hl, 0xffff
	ret z
	and hl, 0xfff
	extz bc
	sll bc, 12
	or hl, bc
	ret

; NoteEventBuffer Store dispatch (7-entry, table 0xe16136)
NoteEvent_Store:
	extz wa
	lda xbc, (MSP_Default_ChannelMap_0x1E:24)
	ld	l, (xbc+wa)
	ret

NoteEventBuffer_CopyToSlot:
	ld c, a
	ld xwa, (3186:16)
	extz bc
	dec 1, bc
	cp bc, 0:i3
	jr lt, NoteEvent_CopyCommon
	cp bc, 6:i3
	jr gt, NoteEvent_CopyCommon
	add bc, bc
	lda xix, (MSP_Default_GroupOffsetB:24)
	ld	bc, (xix+bc)
	lda xix, (NOTE_EVENT_DISPATCH_1:24)
	jp	t, (xix+bc)
; Note event buffer copy dispatch - 7 cases (BC 0-6)
; Selects destination buffer pointer based on case, then copies 46080 bytes
; Offset table at 0xe16128
NOTE_EVENT_DISPATCH_1:
	ld xbc, (3190:16); Case 0: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ld xbc, (3194:16); Case 1: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ld xbc, (3198:16); Case 2: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ld xbc, (3202:16); Case 3: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ld xbc, (3206:16); Case 4: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ld xbc, (3210:16); Case 5: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ld xbc, (3214:16); Case 6: Load dest pointer (falls through)
NOTE_EVENT_COPY_COMMON:	; F1717D - Common handler
	ld xiy, xbc	; XIY = destination pointer
	ld xix, xwa	; XIX = source pointer
	ldw bc, 0xb400	; BC = 0xb400 byte count
	ldirw	; Block copy words

; NoteEventBuffer copy common handler
NoteEvent_CopyCommon:
	jrl PartGrid_ColumnDispatch_End

NoteEventBuffer_Store:
	lda xsp, (xsp - 10)
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr PartGrid_ColumnDispatch_Default
	ld xwa, (3186:16)
	ld (xsp), xwa
	ld a, (xsp + 8)
	extz wa
	dec 1, wa
	cp wa, 0:i3
	jrl lt, NoteEvent_StoreCommon
	cp wa, 6:i3
	jrl gt, NoteEvent_StoreCommon
	add wa, wa
	lda xix, (MSP_Default_VarSize:24)
	ld	wa, (xix+wa)
	lda xix, (NOTE_EVENT_DISPATCH_2:24)
	jp	t, (xix+wa)
; Note event dispatch table 2
; 7 cases (WA 0-6), offset table at 0xe16136
NOTE_EVENT_DISPATCH_2:
	ld xwa, (3190:16)
	ld (xsp + 4), xwa
	jrl Flash_WriteSectorWithMirrorCopy
NOTE_EVENT_DISPATCH_2b:
	ld xwa, (3194:16)
	ld (xsp + 4), xwa

Flash_SectorWriteExecute:
	ld xwa, (xsp)
	lda xbc, (xwa+26624)
	ld xwa, (xsp + 4)
	lda xde, (xwa+26624)
	ld wa, 1:i3
	call Flash_EraseSectorAndWrite
	ld xiy, (xsp + 4)
	sub xiy, 0x9800
	ld xwa, (xsp)
	lda xde, (xwa+26624)
	ld xix, xde
	ldw bc, 0x8000
	ldirw
	ld xbc, (xsp)

Flash_CopyMirrorLoop:
	ld xhl, xbc
	add xhl, 0x10000
	ld A, (xbc+)
	ld (xhl), a
	cp xbc, xde
	jr c, Flash_CopyMirrorLoop
	ld xwa, (xsp)
	lda xbc, (xwa+26624)
	ld xde, (xsp + 4)
	sub xde, 0x9800
	ld wa, 1:i3
	jr Flash_EraseAndWriteFinal
	ld xwa, (3198:16)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
	ld xwa, (3202:16)
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
	ld xwa, (3206:16)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
	ld xwa, (3210:16)
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
	ld xwa, (3214:16)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy

; NoteEventBuffer store common handler
NoteEvent_StoreCommon:
	cp a, 0:i3
	jrl nz, Flash_SectorWriteExecute

Flash_WriteSectorWithMirrorCopy:
	ld wa, 1:i3
	ld xbc, (xsp)
	ld xde, (xsp + 4)
	call Flash_EraseSectorAndWrite
	ld xiy, (xsp + 4)
	add xiy, 0x10000
	ld xwa, (xsp)
	ld xix, xwa
	ldw bc, 0x8000
	ldirw
	ld xwa, (xsp)
	add xwa, 0x10000
	ld xbc, xwa
	lda xde, (xwa+26624)

Flash_CopyReverseMirrorLoop:
	ld xhl, xbc
	add xhl, 0xffff0000
	ld A, (xbc+)
	ld (xhl), a
	cp xbc, xde
	jr c, Flash_CopyReverseMirrorLoop
	ld xde, (xsp + 4)
	add xde, 0x10000
	ld wa, 1:i3
	ld xbc, (xsp)

Flash_EraseAndWriteFinal:
	call Flash_EraseSectorAndWrite
	lda xsp, (xsp + 10)
	ret

Flash_StoreBaseAndInitAccPatch:
	ld	xwa, (3186:16)
	ld	(14610:16), xwa
	jp	AccPatch_InitSlotChain_Wrap
Flash_ExtendedOpsBlock:
	push	xiz
	extz	de
	lda	xix, (MSP_Default_ChannelMap:24)
	lda_rr	xhl, xix, de
	ld	e, 0:opc
	cp	a, 10
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip
	ld	c, (xhl)
	extz	wa
	ld_rrb	l, xix, wa
	ld	ix, 0:i3
Flash_StoreBaseAndInitAccPatch_Loop:
	ld	a, c
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (3186:16)
	lda_rr	xiz, xwa, iy
	ld	a, l
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (3182:16)
	lda_rr	xwa, xwa, iy
	ld	a, (xwa+160)
	ld	(xiz+160), a
	inc	1, e
	inc	1, ix
	cp	e, 16
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop
	jr	Flash_StoreBaseAndInitAccPatch_Epilogue
Flash_StoreBaseAndInitAccPatch_Skip:
	extz	bc
	ld_rrb	c, xix, bc
	ld	l, (xhl)
	ld	ix, 0:i3
Flash_StoreBaseAndInitAccPatch_Loop2:
	ld	a, c
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (3182:16)
	lda_rr	xiz, xwa, iy
	ld	a, l
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (3186:16)
	lda_rr	xwa, xwa, iy
	ld	a, (xwa+160)
	ld	(xiz+160), a
	inc	1, e
	inc	1, ix
	cp	e, 16
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop2
Flash_StoreBaseAndInitAccPatch_Epilogue:
	pop	xiz
	ret
	ld	xbc, (3182:16)
	lda	xhl, (xbc+16)
	add	e, 32
	extz	de
	add	de, 16
	ld	xbc, (3186:16)
	lda_rr	xbc, xbc, de
	cp	a, 10
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip2
	ld	a, (xhl)
	ld	(xbc), a
	ret
Flash_StoreBaseAndInitAccPatch_Skip2:
	ld	a, (xbc)
	ld	(xhl), a
	ret
Flash_InitBytecodeBlock_Helper:
	dec 2,XSP
	pushw iz
	ld (XSP+0x02),A
	calr SlotTable_ExtendedOpsBlock
	lda xix, (0x06d4:16)
	cpw (XIX), 0xffff
	jr z, .Lc_f173a6
	ld L, 0x00:opc
	ld xbc, (0x0c92:16)
.Lc_f17377:
	ld A,L
	extz WA
	add WA,0x0050
	ld	a, (xbc+wa)
	cp a, 0:i3
	jr z, .Lc_f1738d
	cp A,(XSP+0x02)
	jr nz, .Lc_f173a0
.Lc_f1738d:
	lda xbc, (0x07a0:16)
	ld WA,(XIX)
	ld (XBC),WA
	extz HL
	or HL,0x0500
	ld (XBC+0x02),HL
	jr t, .Lc_f173a6
.Lc_f173a0:
	inc 1,L
	cp l, 4:i3
	jr c, .Lc_f17377
.Lc_f173a6:
	ld H, 0x00:opc
	ld L, 0x00:opc
	lds_erpb 0xea, 0
.Lc_f173ad:
	ld_erpb_rr a, 0xea
	extz WA
	add WA,WA
	inc 2,WA
	lda	xbc, (xix+wa)
	cpw (XBC), 0xffff
	jr z, .Lc_f1741e
	cp L,0x28
	jr nc, .Lc_f17415
.Lc_f173c6:
	ld E,L
	extz DE
	add DE,0x0010
	ld xwa, (0x0c92:16)
	ld	a, (xwa+de)
	cp a, 0:i3
	jr z, .Lc_f173e0
	cp A,(XSP+0x02)
	jr nz, .Lc_f1740e
.Lc_f173e0:
	ld E,H
	extz DE
	sla de, 2
	ld IZ,DE
	inc 4,IZ
	lda xiy, (0x07a0:16)
	ld WA,(XBC)
	ld	(xiy+iz), wa
	inc 6,DE
	ld A,L
	set 0x07,A
	extz WA
	or WA,0x0500
	ld	(xiy+de), wa
	inc 1,H
	inc 1,L
	jr t, .Lc_f17415
.Lc_f1740e:
	inc 1,L
	cp L,0x28
	jr c, .Lc_f173c6
.Lc_f17415:
	incb_erp 0xea, 1
	cp_erpb 0xea, 0x32
	jr c, .Lc_f173ad
.Lc_f1741e:
	popw iz
	inc 2,XSP
	ret
Flash_InitBytecodeBlock_Helper2:
	dec	6, xsp
	ld	(xsp+4), a
	calr	SlotTable_ExtendedOpsBlock
	lda	xwa, (1748:16)
	cpw	(xwa), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper_Skip5
	lda	xbc, (1952:16)
	ld	wa, (xwa)
	ld	(xbc), wa
	ldw	(xbc+2), 1536
Flash_InitBytecodeBlock_Helper_Skip5:
	ld	a, (xsp+4)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper_Helper
	ld	(xsp+2), 0
	ld	(xsp), 0
Flash_InitBytecodeBlock_Helper_Loop4:
	ld	a, (xsp)
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xbc, (1748:16)
	ld_rrw	bc, xbc, wa
	cp	bc, 65535
	jrl	z, Flash_InitBytecodeBlock_Helper_Epilogue2
	ld	l, 0:opc
Flash_StoreBaseAndInitAccPatch_Loop3:
	ld	h, 39:opc
	sub	h, l
	ld	a, h
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xix, (3074:16)
	lda_rr	xde, xix, wa
	ld	wa, (xde)
	ldfr_berp	a, 226
	ld	a, (xsp+2)
	extz	wa
	cp_erpb	226, 255
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip3
	sla	wa, 2
	ld	iy, wa
	inc	4, iy
	lda	xix, (1952:16)
	st_rrw	bc, xix, iy
	ld	bc, wa
	inc	6, bc
	set	7, h
	ld	l, h
	extz	hl
	st_rrw	hl, xix, bc
	ldw	(xde), 2
	jr	Flash_StoreBaseAndInitAccPatch_Join2
Flash_StoreBaseAndInitAccPatch_Skip3:
	inc	1, l
	cp	l, 40
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop3
	ld	l, 0:opc
	ld	iy, wa
Flash_InitBytecodeBlock_Helper_Loop5:
	ld	h, 39:opc
	sub	h, l
	ld	a, h
	extz	wa
	add	wa, wa
	inc	2, wa
	lda_rr	xde, xix, wa
	ld	wa, (xde)
	ldfr_berp	a, 226
	cpib_erp	226, 1
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip4
	ld	wa, iy
	sla	wa, 2
	ld	iy, wa
	inc	4, iy
	lda	xix, (1952:16)
	st_rrw	bc, xix, iy
	ld	bc, wa
	inc	6, bc
	set	7, h
	ld	l, h
	extz	hl
	st_rrw	hl, xix, bc
	ldw	(xde), 2
Flash_StoreBaseAndInitAccPatch_Join2:
	incm8	1, (xsp+2)
	jr	Flash_InitBytecodeBlock_Helper_Join2
Flash_StoreBaseAndInitAccPatch_Skip4:
	inc	1, l
	cp	l, 40
	jr	c, Flash_InitBytecodeBlock_Helper_Loop5
Flash_InitBytecodeBlock_Helper_Join2:
	incm8	1, (xsp)
	cp	(xsp), 50
	jrl	c, Flash_InitBytecodeBlock_Helper_Loop4
Flash_InitBytecodeBlock_Helper_Epilogue2:
	inc	6, xsp
	ret
Flash_InitBytecodeBlock_Helper3:
	dec 2,XSP
	push XIZ
	ld (XSP+0x04),A
	cpw (0x07a0:16), 0xffff
	jr z, .Lc_f1756b
	lds_erpb 0xf9, 0
.Lc_f17529:
	ld A,(XSP+0x04)
	add A,0x1e
	ldfr_berp a, 0xfa
	ld_erpb_rr a, 0xf9
	ldfr_berp a, 0xfb
	ld_erpb_rr a, 0xfa
	extz WA
	ld_erpb_rr c, 0xfb
	extz BC
	ld de, 0:i3
	calr Util_FrameSetup10
	lda xwa, (0x07a0:16)
	cp HL,(XWA)
	jr nz, .Lc_f17562
	ld HL,(XWA+0x02)
	ld_erpb_rr a, 0xfa
	extz WA
	ld_erpb_rr c, 0xfb
	extz BC
	pushw hl
	ld de, 0:i3
	calr PartGrid_OperationsBlock
.Lc_f17562:
	incb_erp 0xf9, 1
	cp_erpb 0xf9, 0x0a
	jr c, .Lc_f17529
.Lc_f1756b:
	lds_erpb 0xf8, 0
.Lc_f1756e:
	ld_erpb_rr c, 0xf8
	extz BC
	sla bc, 2
	lda xwa, (0x07a4:16)
	.byte	0xd3, 0x07, 0xe0, 0xe4, 0x3f, 0xff, 0xff
	jrl	z, Flash_StoreBaseAndInitAccPatch_Sub_Epilogue
	ldib_erp	249, 0
Flash_StoreBaseAndInitAccPatch_Loop5:
	ld	a, (xsp+4)
	add	a, 30
	ldfr_berp	a, 250
	ldto_berp	a, 249
	ldfr_berp	a, 251
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	ld	de, 1:i3
	calr	Util_FrameSetup10
	ldto_berp	a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	.byte	0xd3, 0x07, 0xe4, 0xe8, 0xf3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip2
	inc	6, wa
	ld_rrw	hl, xbc, wa
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	pushw	hl
	ld	de, 1:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip2:
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	ld	de, 2:i3
	calr	Util_FrameSetup10
	ldto_berp	a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	.byte	0xd3, 0x07, 0xe4, 0xe8, 0xf3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip3
	inc	6, wa
	ld_rrw	hl, xbc, wa
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	pushw	hl
	ld	de, 2:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip3:
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	ld	de, 3:i3
	calr	Util_FrameSetup10
	ldto_berp	a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	.byte	0xd3, 0x07, 0xe4, 0xe8, 0xf3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip4
	inc	6, wa
	ld_rrw	hl, xbc, wa
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	pushw	hl
	ld	de, 3:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip4:
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	ld	de, 4:i3
	calr	Util_FrameSetup10
	ldto_berp	a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	.byte	0xd3, 0x07, 0xe4, 0xe8, 0xf3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip5
	inc	6, wa
	ld_rrw	hl, xbc, wa
	ldto_berp	a, 250
	extz	wa
	ldto_berp	c, 251
	extz	bc
	pushw	hl
	ld	de, 4:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip5:
	inc1b_erp	249
	cp_erpb	249, 10
	jrl	c, Flash_StoreBaseAndInitAccPatch_Loop5
	inc1b_erp	248
	cp_erpb	248, 50
	jrl	c, .Lc_f1756e
Flash_StoreBaseAndInitAccPatch_Sub_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
Flash_InitBytecodeBlock_Helper4:
	ld	xix, (3222:16)
	ld	xiy, (3218:16)
	ldw	bc, 0x8000
	ldirw
	lda	xhl, (1952:16)
	ld	bc, (xhl+2)
	cp	bc, 0xffff
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip7
	and	bc, 127
	ld	w, c
	ld	e, w
	extz	de
	add	de, 80
	ld	xbc, (3222:16)
	st_rrb	a, xbc, de
	cp	w, 3:i3
	jr	z, Flash_StoreBaseAndInitAccPatch_Join3
	inc	1, w
	cp	w, 3:i3
	jr	ugt, Flash_StoreBaseAndInitAccPatch_Join3
	ld	e, w
	extz	de
Flash_StoreBaseAndInitAccPatch_Loop6:
	ld	ix, de
	add	ix, 80
	ld	xbc, (3222:16)
	lda_rr	xbc, xbc, ix
	cp	(xbc), a
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip6
	ld	(xbc), 0
Flash_StoreBaseAndInitAccPatch_Skip6:
	inc	1, w
	inc	1, de
	cp	w, 3:i3
	jr	ule, Flash_StoreBaseAndInitAccPatch_Loop6
	jr	Flash_StoreBaseAndInitAccPatch_Join3
Flash_StoreBaseAndInitAccPatch_Skip7:
	ld	w, 0:opc
	ld	de, 0:i3
Flash_StoreBaseAndInitAccPatch_Loop7:
	ld	ix, de
	add	ix, 80
	ld	xbc, (3222:16)
	lda_rr	xbc, xbc, ix
	cp	(xbc), a
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip8
	ld	(xbc), 0
Flash_StoreBaseAndInitAccPatch_Skip8:
	inc	1, w
	inc	1, de
	cp	w, 4:i3
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop7
Flash_StoreBaseAndInitAccPatch_Join3:
	ld	w, 0:opc
	ldib_erp	226, 0
Flash_StoreBaseAndInitAccPatch_Loop8:
	ldto_berp	c, 226
	extz	bc
	sla	bc, 2
	inc	6, bc
	ld_rrw	bc, xhl, bc
	cp	bc, 65535
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip9
	and	bc, 127
	ld	w, c
	ld	e, w
	extz	de
	add	de, 16
	ld	xbc, (3222:16)
	st_rrb	a, xbc, de
	inc	1, w
	inc1b_erp	226
	cp_erpb	226, 50
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop8
Flash_StoreBaseAndInitAccPatch_Skip9:
	cp	w, 40
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip11
	cp	w, 39
	jr	ugt, Flash_StoreBaseAndInitAccPatch_Skip11
	ld	e, w
	extz	de
Flash_StoreBaseAndInitAccPatch_Loop9:
	ld	hl, de
	add	hl, 16
	ld	xbc, (3222:16)
	lda_rr	xbc, xbc, hl
	cp	(xbc), a
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip10
	ld	(xbc), 0
Flash_StoreBaseAndInitAccPatch_Skip10:
	inc	1, w
	inc	1, de
	cp	w, 39
	jr	ule, Flash_StoreBaseAndInitAccPatch_Loop9
Flash_StoreBaseAndInitAccPatch_Skip11:
	ld	xbc, (3222:16)
	ld	xde, (3218:16)
	ld	wa, 1:i3
	jp	Flash_EraseSectorAndWrite
Flash_InitBytecodeBlock_Helper5:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xix, (3222:16)
	ld	xiy, (3218:16)
	ldw	bc, 0x8000
	ldirw
	lda_d16	xwa, (0x7a0)
	cpw	(xwa), 0xffff
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip12
	ld	hl, (xwa)
	ld	h, 0:opc
	ld	wa, (xwa+2)
	ld	w, 0:opc
	ld	(xsp+4), a
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 2:i3
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip12
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 3:i3
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	sub	xix, 0x346800
	cp	hl, 0:i3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip12
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip12
	ld	xbc, 0:i3
Flash_InitBytecodeBlock_Helper3_Loop:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_InitBytecodeBlock_Helper3_Loop
Flash_StoreBaseAndInitAccPatch_Skip12:
	ld	(xsp+6), 0
Flash_InitBytecodeBlock_Helper3_Loop2:
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	ld	wa, bc
	inc	4, wa
	lda	xde, (1952:16)
	ld_rrw	wa, xde, wa
	cp	wa, 65535
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip13
	ld	w, 0:opc
	ld	l, a
	inc	6, bc
	ld_rrw	wa, xde, bc
	ld	w, 0:opc
	ld	(xsp+4), a
	res	7, l
	resm	7, (xsp+0x4)
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 0:i3
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Helper3_Skip
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 1:i3
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	sub	xix, 0x346800
	cp	hl, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Helper3_Skip
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_InitBytecodeBlock_Helper3_Skip
	ld	xbc, 0:i3
Flash_InitBytecodeBlock_Helper3_Loop3:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_InitBytecodeBlock_Helper3_Loop3
Flash_InitBytecodeBlock_Helper3_Skip:
	incm8	1, (xsp+0x6)
	cp	(xsp+0x6), 50
	jrl	c, Flash_InitBytecodeBlock_Helper3_Loop2
Flash_StoreBaseAndInitAccPatch_Skip13:
	ld	xbc, (3222:16)
	ld	xde, (3218:16)
	ld	wa, 1:i3
	call	Flash_EraseSectorAndWrite
	pop	xiz
	lda	xsp, (xsp+12)
	ret
Flash_InitBytecodeBlock_Helper9_Helper:
	lda	xsp, (xsp-12)
	push	xiz
	lda	xwa, (1952:16)
	cpw	(xwa), 0xffff
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip14
	ld	hl, (xwa)
	ld	h, 0:opc
	ld	wa, (xwa+2)
	ld	w, 0:opc
	ld	(xsp+4), a
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 3:i3
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip14
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 2:i3
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	cp	hl, 0:i3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip14
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip14
	ld	xbc, 0:i3
Flash_InitBytecodeBlock_Helper3_Loop4:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_InitBytecodeBlock_Helper3_Loop4
Flash_StoreBaseAndInitAccPatch_Skip14:
	ld	(xsp+6), 0
Flash_InitBytecodeBlock_Helper3_Loop5:
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	ld	wa, bc
	inc	4, wa
	lda	xde, (1952:16)
	ld_rrw	wa, xde, wa
	cp	wa, 65535
	jr	z, Flash_InitBytecodeBlock_Helper3_Epilogue
	ld	w, 0:opc
	ld	l, a
	inc	6, bc
	ld_rrw	wa, xde, bc
	ld	w, 0:opc
	ld	(xsp+4), a
	res	7, l
	resm	7, (xsp+0x4)
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 1:i3
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Helper3_Skip2
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 0:i3
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	cp	hl, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Helper3_Skip2
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_InitBytecodeBlock_Helper3_Skip2
	ld	xbc, 0:i3
Flash_InitBytecodeBlock_Helper3_Loop6:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_InitBytecodeBlock_Helper3_Loop6
Flash_InitBytecodeBlock_Helper3_Skip2:
	incm8	1, (xsp+0x6)
	cp	(xsp+0x6), 50
	jrl	c, Flash_InitBytecodeBlock_Helper3_Loop5
Flash_InitBytecodeBlock_Helper3_Epilogue:
	pop	xiz
	lda	xsp, (xsp+0xc)
	ret
Flash_InitBytecodeBlock_Helper8:
	dec	8, xsp
	push	xiz
	ld	(xsp+10), c
	ld	iz, wa
	calr	SlotTable_ExtendedOpsBlock
	calr	Flash_InitBytecodeBlock_Helper9_Helper_Helper2
	calr	Flash_InitBytecodeBlock_Helper9_Helper_Helper3
	ld	wa, iz
	and	wa, 0xff00
	jr	z, Flash_InitBytecodeBlock_Helper4_Skip
	ld	d, 0:opc
	ld	b, 0:opc
	ld	c, 0:opc
	ld	xhl, (3218:16)
	ld	ix, 0:i3
Flash_StoreBaseAndInitAccPatch_Loop10:
	ld	wa, ix
	add	wa, 80
	ld_rrb	w, xhl, wa
	cp	w, b
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip15
	ld	b, w
	ld	d, c
Flash_StoreBaseAndInitAccPatch_Skip15:
	inc	1, c
	inc	1, ix
	cp	c, 4:i3
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop10
	lda	xhl, (1952:16)
	ld	wa, (1748:16)
	ld	(xhl), wa
	ld	a, d
	extz	wa
	or	wa, 1280
	ld	(xhl+2), wa
	lda	xde, (2156:16)
	ld	(xde), wa
	ld	c, b
	extz	bc
	ld	(xde+2), bc
Flash_InitBytecodeBlock_Helper4_Skip:
	ld	wa, iz
	and	wa, 255
	jrl	z, Flash_InitBytecodeBlock_Helper4_Epilogue
	ld	e, 0:opc
	ld	c, 0:opc
	ld	(xsp+6), 0
	ld	(xsp+8), 0
	ld	(xsp+4), 0
Flash_InitBytecodeBlock_Helper4_Loop:
	ld	a, (xsp+4)
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xhl, (1748:16)
	lda_rr	xhl, xhl, wa
	cpw	(xhl), 0xffff
	jrl	z, Flash_InitBytecodeBlock_Helper4_Epilogue
	cp	(xsp+0x8), 0
	jr	nz, Flash_InitBytecodeBlock_Helper4_Skip3
	cp	c, 40
	jr	nc, Flash_StoreBaseAndInitAccPatch_Join4
Flash_StoreBaseAndInitAccPatch_Loop11:
	ld	a, c
	extz	wa
	ld	ix, wa
	add	ix, 16
	ld	xwa, (3218:16)
	ld_rrb	w, xwa, ix
	cp	w, 0:i3
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip16
	cp	w, (xsp+0xa)
	jr	nz, Flash_InitBytecodeBlock_Helper4_Skip2
Flash_StoreBaseAndInitAccPatch_Skip16:
	ldfr_berp	e, 240
	extz	ix
	sla	ix, 2
	ld	iz, ix
	inc	4, iz
	lda	xiy, (1952:16)
	ld	wa, (xhl)
	st_rrw	wa, xiy, iz
	inc	6, ix
	ld	a, c
	set	7, a
	extz	wa
	or	wa, 1280
	st_rrw	wa, xiy, ix
	inc	1, e
	inc	1, c
	jr	Flash_StoreBaseAndInitAccPatch_Join4
Flash_InitBytecodeBlock_Helper4_Skip2:
	inc	1, c
	cp	c, 40
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop11
Flash_StoreBaseAndInitAccPatch_Join4:
	cp	c, 40
	jrl	nz, Flash_InitBytecodeBlock_Helper4_Join
	ld	(xsp+8), 1
	jrl	Flash_InitBytecodeBlock_Helper4_Join
Flash_InitBytecodeBlock_Helper4_Skip3:
	ld	d, 0:opc
	ld	b, 0:opc
	ld	c, 0:opc
Flash_InitBytecodeBlock_Helper4_Loop2:
	ld	a, c
	extz	wa
	ld	iy, wa
	add	iy, iy
	inc	2, iy
	lda	xix, (2972:16)
	.byte	0xd3, 0x07, 0xf0, 0xf4, 0x3f, 0x01, 0x00
	jr	z, Flash_InitBytecodeBlock_Helper4_Skip4
	ld	iy, wa
	add	iy, 16
	ld	xwa, (3218:16)
	ld_rrb	w, xwa, iy
	cp	w, b
	jr	ule, Flash_InitBytecodeBlock_Helper4_Skip4
	cp	w, (xsp+0xa)
	jr	z, Flash_InitBytecodeBlock_Helper4_Skip4
	ld	b, w
	ld	d, c
Flash_InitBytecodeBlock_Helper4_Skip4:
	inc	1, c
	ldfr_berp	e, 244
	extz	iy
	cp	c, 40
	jr	c, Flash_InitBytecodeBlock_Helper4_Loop2
	sla	iy, 2
	ld	qwa, iy
	inc	4, qwa
	lda	xiz, (1952:16)
	ld	wa, (xhl)
	ld	(xiz+qwa), wa
	inc	6, iy
	ld	l, d
	set	7, l
	extz	hl
	or	hl, 1280
	st_rrw	hl, xiz, iy
	ld	a, (xsp+6)
	extz	wa
	sla	wa, 2
	ld	iz, wa
	inc	4, iz
	lda	xiy, (2156:16)
	st_rrw	hl, xiy, iz
	ld	hl, wa
	inc	6, hl
	ld	a, b
	extz	wa
	st_rrw	wa, xiy, hl
	ld	a, d
	extz	wa
	add	wa, wa
	inc	2, wa
	.byte	0xf3, 0x07, 0xf0, 0xe0, 0x02, 0x01, 0x00
	incm8	1, (xsp+6)
	inc	1, e
Flash_InitBytecodeBlock_Helper4_Join:
	incm8	1, (xsp+4)
	cp	(xsp+0x4), 50
	jrl	c, Flash_InitBytecodeBlock_Helper4_Loop
Flash_InitBytecodeBlock_Helper4_Epilogue:
	pop	xiz
	inc	8, xsp
	ret
Flash_InitBytecodeBlock_Helper10:
	push	xiz
	lda	xbc, (0x39b3:16)
	ld	xwa, xbc
	lda	xbc, (xbc+29)
Flash_InitBytecodeBlock_Helper5_Loop:
	ld	(xwa+), 32
	cp	xwa, xbc
	jr	c, Flash_InitBytecodeBlock_Helper5_Loop
	ldib_erp	251, 0
	lda	xwa, (2156:16)
	cpw	(xwa), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper5_Skip
	ld	wa, (xwa)
	ld	w, 0:opc
	ldfr_berp	a, 249
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper9_Helper_Helper
	ldfr_berp	l, 248
	ldto_berp	a, 249
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper2
	lda	xbc, (0x39b3:16)
	ld	(xbc), 35
	ld	(xbc+1), l
	ldto_berp	a, 248
	ld	(xbc+2), a
	ld	(xbc+3), 40
	ld	(xbc+4), 68
	ld	(xbc+5), 114
	ld	(xbc+6), 109
	ld	(xbc+7), 41
	ldi_erpb	251, 9
Flash_InitBytecodeBlock_Helper5_Skip:
	ldib_erp	250, 0
Flash_StoreBaseAndInitAccPatch_Loop12:
	ldto_berp	a, 250
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (2156:16)
	.byte	0xd3, 0x07, 0xe4, 0xe8, 0x3f, 0xff, 0xff
	jrl	z, Flash_StoreBaseAndInitAccPatch_Epilogue2
	inc	6, wa
	ld_rrw	wa, xbc, wa
	ldfr_berp	a, 249
	ld	bc, 0:i3
	cpib_erp	250, 0
	jr	z, Flash_InitBytecodeBlock_Helper5_Skip2
	ldto_berp	a, 249
	cp	a, l
	jr	z, Flash_InitBytecodeBlock_Helper5_Skip2
	ld	bc, 1:i3
Flash_InitBytecodeBlock_Helper5_Skip2:
	cpib_erp	250, 0
	scc	z, wa
	or	wa, bc
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip17
	ldto_berp	a, 249
	sub	a, 10
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper9_Helper_Helper
	ldfr_berp	l, 248
	ldto_berp	a, 249
	sub	a, 10
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper2
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (0x39b3:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 35
	ldto_berp	a, 251
	inc	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	ldto_berp	a, 251
	inc	2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldto_berp	a, 248
	ld	(xde), a
	incb_erp	251, 4
	cp_erpb	251, 26
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip17
	decb_erp	251, 4
	ldto_berp	a, 251
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp	a, 251
	inc	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp	a, 251
	inc	2, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	jr	Flash_StoreBaseAndInitAccPatch_Epilogue2
Flash_StoreBaseAndInitAccPatch_Skip17:
	ldto_berp	l, 249
	inc1b_erp	250
	cp_erpb	250, 50
	jrl	c, Flash_StoreBaseAndInitAccPatch_Loop12
Flash_StoreBaseAndInitAccPatch_Epilogue2:
	pop	xiz
	ret
Flash_InitBytecodeBlock_Helper9_Helper_Helper:
	cp A,0x0a
	jr nc, .Lc_f17cbd
	add A,0x30
	ld L,A
	jr t, .Lc_f17ce5
.Lc_f17cbd:
	cp A,0x14
	jr nc, .Lc_f17cc9
	add A,0x26
	ld L,A
	jr t, .Lc_f17ce5
.Lc_f17cc9:
	cp A,0x1e
	jr nc, .Lc_f17cd5
	add A,0x1c
	ld L,A
	jr t, .Lc_f17ce5
.Lc_f17cd5:
	cp A,0x28
	jr nc, .Lc_f17ce1
	add A,0x12
	ld L,A
	jr t, .Lc_f17ce5
.Lc_f17ce1:
	inc 8,A
	ld L,A
.Lc_f17ce5:
	ret
Flash_StoreBaseAndInitAccPatch_Helper2:
	cp	a, 10
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip22
	ld	l, 48:opc
	jr	Flash_StoreBaseAndInitAccPatch_Return2
Flash_StoreBaseAndInitAccPatch_Skip22:
	cp	a, 20
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip23
	ld	l, 49:opc
	jr	Flash_StoreBaseAndInitAccPatch_Return2
Flash_StoreBaseAndInitAccPatch_Skip23:
	cp	a, 30
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip24
	ld	l, 50:opc
	jr	Flash_StoreBaseAndInitAccPatch_Return2
Flash_StoreBaseAndInitAccPatch_Skip24:
	ld	l, 52:opc
	cp	a, 40
	ret	nc
	ld	l, 51:opc
Flash_StoreBaseAndInitAccPatch_Return2:
	ret
Flash_InitBytecodeBlock_Helper11:
	push	xiz
	lda	xde, (0x39b3:16)
	ld	xwa, xde
	lda	xbc, (xde+29)
Flash_StoreBaseAndInitAccPatch_Helper2_Loop:
	ld	(xwa+), 32
	cp	xwa, xbc
	jr	c, Flash_StoreBaseAndInitAccPatch_Helper2_Loop
	ldib_erp	248, 0
	cpw	(0x7a2:16), 0xffff
	jr	z, Flash_StoreBaseAndInitAccPatch_Helper2_Skip
	ld	(xde), 85
	ld	(xde+1), 115
	ld	(xde+2), 101
	ld	(xde+3), 114
	ld	(xde+4), 68
	ld	(xde+5), 114
	ld	(xde+6), 117
	ld	(xde+7), 109
	ldi_erpb	248, 9
Flash_StoreBaseAndInitAccPatch_Helper2_Skip:
	ldib_erp	249, 0
Flash_StoreBaseAndInitAccPatch_Helper2_Loop2:
	ldto_berp	a, 249
	extz	wa
	sla	wa, 2
	lda	xbc, (1958:16)
	ld_rrw	wa, xbc, wa
	cp	wa, 65535
	jrl	z, Flash_StoreBaseAndInitAccPatch_Epilogue3
	res	7, a
	ldfr_berp	a, 250
	ld	bc, 0:i3
	cpib_erp	249, 0
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip25
	ldto_berp	a, 250
	cp	a, e
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip25
	ld	bc, 1:i3
Flash_StoreBaseAndInitAccPatch_Skip25:
	cpib_erp	249, 0
	scc	z, wa
	or	wa, bc
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip26
	ldto_berp	a, 250
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper9_Helper_Helper
	ldfr_berp	l, 251
	ldto_berp	a, 250
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper2
	ldto_berp	a, 248
	extz	wa
	lda	xbc, (0x39b3:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 35
	ldto_berp	a, 248
	inc	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	ldto_berp	a, 248
	inc	2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldto_berp	a, 251
	ld	(xde), a
	incb_erp	248, 4
	cp_erpb	248, 26
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip26
	decb_erp	248, 4
	ldto_berp	a, 248
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp	a, 248
	inc	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp	a, 248
	inc	2, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	jr	Flash_StoreBaseAndInitAccPatch_Epilogue3
Flash_StoreBaseAndInitAccPatch_Skip26:
	ldto_berp	e, 250
	inc1b_erp	249
	cp_erpb	249, 50
	jrl	c, Flash_StoreBaseAndInitAccPatch_Helper2_Loop2
Flash_StoreBaseAndInitAccPatch_Epilogue3:
	pop	xiz
	ret
Flash_InitBytecodeBlock_Helper12:
	calr	Flash_InitBytecodeBlock_Helper11_Helper
	lda	xhl, (2156:16)
	cpw	(xhl), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper6_Skip
	lda	xbc, (2360:16)
	ld	wa, (xhl+2)
	ld	(xbc), wa
	ld	wa, (xhl)
	ld	(xbc+2), wa
	ldw	(xbc+0x4), 0
Flash_InitBytecodeBlock_Helper6_Skip:
	ldib_erp	234, 0
	ldib_erp	226, 0
Flash_InitBytecodeBlock_Helper6_Loop:
	ldto_berp	e, 226
	extz	de
	sla	de, 2
	ld	wa, de
	inc	4, wa
	lda_rr	xbc, xhl, wa
	cpw	(xbc), 0xffff
	ret	z
	ldto_berp	a, 234
	extz	wa
	add	wa, wa
	ld	iy, wa
	inc	6, iy
	lda	xix, (2360:16)
	inc	6, de
	ld_rrw	wa, xhl, de
	st_rrw	wa, xix, iy
	ld	de, (xbc)
	ldto_berp	a, 234
	extz	wa
	sla	wa, 2
	ld	bc, wa
	add	bc, 106
	st_rrw	de, xix, bc
	add	wa, 108
	.byte	0xf3, 0x07, 0xf0, 0xe0, 0x02, 0x00, 0x00
	inc1b_erp	234
	inc1b_erp	226
	cp_erpb	226, 50
	jr	c, Flash_InitBytecodeBlock_Helper6_Loop
	ret
Flash_InitBytecodeBlock_Helper7:
	calr	Flash_InitBytecodeBlock_Helper7_Helper
	lda	xbc, (1748:16)
	cpw	(xbc), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper7_Skip
	lda	xde, (2666:16)
	ld	wa, (xbc)
	ld	(xde+2), wa
	ldw	(xde+0x4), 0
Flash_InitBytecodeBlock_Helper7_Skip:
	ld	h, 0:opc
	ld	l, 0:opc
Flash_InitBytecodeBlock_Helper7_Loop:
	ld	a, l
	extz	wa
	add	wa, wa
	inc	2, wa
	exts	xwa
	add	xwa, xbc
	cpw	(xwa), 0xffff
	ret	z
	ld	iy, (xwa)
	ld	a, h
	extz	wa
	sla	wa, 2
	ld	ix, wa
	add	ix, 106
	lda	xde, (2666:16)
	st_rrw	iy, xde, ix
	add	wa, 108
	.byte	0xf3, 0x07, 0xe8, 0xe0, 0x02, 0x00, 0x00
	inc	1, h
	inc	1, l
	cp	l, 50
	jr	c, Flash_InitBytecodeBlock_Helper7_Loop
	ret
Flash_ExtendedOpsBlock_Code_Join:
	ld xix, (0x0c96:16)
	ld xiy, (0x0c92:16)
	ldw BC, 0x8000
	ldirw
	ld xix, (0x0c96:16)
	ld XIY,MSP_Default_Sequencer
	ldw BC, 0x0008
	ldirw
	ld xwa, (0x0c96:16)
	ld XIY,MSP_Default_SeqReserved
	lda xix, (xwa + 0x10)
	ldw BC, 0x0020
	ldirw
	ld xwa, (0x0c96:16)
	ld XIY,MSP_Default_SeqReserved_0x40
	lda xix, (xwa + 0x50)
	ldw BC, 0x0008
	ldirw
	ld xbc, (0x0c96:16)
	ld xde, (0x0c92:16)
	ld wa, 1:i3
	jp Flash_EraseSectorAndWrite
Flash_SlotUpdateOpsBlock_Helper:
	ld L, 0x00:opc
	ld xde, (0x0c92:16)
	ld B, 0x00:opc
	cp a, 0:i3
	jr nz, .Lc_f17f68
	ld wa, 0:i3
.Lc_f17f48:
	ld IX,WA
	add IX,0x0010
	ld	h, (xde+ix)
	cp h, 0:i3
	jr z, .Lc_f17f5b
	cp H,C
	jr nz, .Lc_f17f5d
.Lc_f17f5b:
	inc 1,L
.Lc_f17f5d:
	inc 1,B
	inc 1,WA
	cp B,0x28
	jr c, .Lc_f17f48
	jr t, .Lc_f17f87
.Lc_f17f68:
	ld wa, 0:i3
.Lc_f17f6a:
	ld IX,WA
	add IX,0x0050
	ld	h, (xde+ix)
	cp h, 0:i3
	jr z, .Lc_f17f7d
	cp H,C
	jr nz, .Lc_f17f7f
.Lc_f17f7d:
	inc 1,L
.Lc_f17f7f:
	inc 1,B
	inc 1,WA
	cp b, 4:i3
	jr c, .Lc_f17f6a
.Lc_f17f87:
	ret
VoiceParam_ComputeOffset:
	ld e, a
	cp e, 0x28
	jr nc, VoiceParam_SubtractBase
	ld xhl, 0x10
	jr VoiceParam_AddOffset

VoiceParam_SubtractBase:
	sub e, 0x28
	ld xhl, 0x50

VoiceParam_AddOffset:
	extz de
	add hl, de
	ld xwa, (3222:16)
	ld	(xwa+hl), c
	ret

DualVoice_ScanAllColumns:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	calr SlotTable_InitBank1748
	ldib_erp 0xfb, 0

DualVoice_ScanColumnLoop:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 0:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0x700
	cp bc, 0x600
	jr z, DualVoice_StoreBankMatch
	cp bc, 0x500
	jr nz, DualVoice_ScanRow1

DualVoice_StoreBankMatch:
	ld (1748:16), wa

DualVoice_ScanRow1:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 1:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1748:24)
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 2:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1748:24)
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 3:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1748:24)
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 4:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1748:24)
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl c, DualVoice_ScanColumnLoop
	popw_erp 0xfa
	inc 2, xsp
	ret

DualVoice_ScanAllColumnsAlt:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	calr SlotTable_InitBank1850
	ldib_erp 0xfb, 0

DualVoice_ScanColumnLoopAlt:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 0:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0x700
	cp bc, 0x600
	jr z, DualVoice_StoreBankMatchAlt
	cp bc, 0x500
	jr nz, DualVoice_ScanRow1Alt

DualVoice_StoreBankMatchAlt:
	ld (1850:16), wa

DualVoice_ScanRow1Alt:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 1:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1850:24)
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 2:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1850:24)
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 3:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1850:24)
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 4:i3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call nc, (SlotTable_Insert1850:24)
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl c, DualVoice_ScanColumnLoopAlt
	popw_erp 0xfa
	inc 2, xsp
	ret

SlotTable_InitBank1748:
	lda xbc, (1748:16)
	ldw (xbc), 0xffff
	ld l, 0x0:opc
	ld wa, 0:i3

SlotTable_InitBank1748_Loop:
	ld de, wa
	inc 2, de
	ldw	(xbc+de), 0xffff
	inc 1, l
	inc 2, wa
	cp l, 0x32
	jr c, SlotTable_InitBank1748_Loop
	ret

SlotTable_InitBank1850:
	lda xbc, (1850:16)
	ldw (xbc), 0xffff
	ld l, 0x0:opc
	ld wa, 0:i3

SlotTable_InitBank1850_Loop:
	ld de, wa
	inc 2, de
	ldw	(xbc+de), 0xffff
	inc 1, l
	inc 2, wa
	cp l, 0x32
	jr c, SlotTable_InitBank1850_Loop
	ret

SlotTable_ExtendedOpsBlock:
	lda	xde, (1952:16)
	ldw (xde), 65535
	ldw (xde+2), 65535
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	lda xbc, (xbc+200)
SlotTable_ExtendedOpsBlock_Loop:
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	cp	xwa, xbc
	jr	c, SlotTable_ExtendedOpsBlock_Loop
	ret
Flash_InitBytecodeBlock_Helper9_Helper_Helper2:
	lda	xde, (2156:16)
	ldw (xde), 65535
	ldw (xde+2), 65535
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	lda xbc, (xbc+200)
Flash_InitBytecodeBlock_Helper9_Helper_Helper2_Loop:
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	cp	xwa, xbc
	jr	c, Flash_InitBytecodeBlock_Helper9_Helper_Helper2_Loop
	ret
Flash_InitBytecodeBlock_Helper11_Helper:
	lda	xix, (2360:16)
	ldw (xix), 65535
	ldw (xix+2), 65535
	ldw	(xix+0x4), 0xffff
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	ld	hl, 0:i3
	lda xbc, (xbc+200)
Flash_InitBytecodeBlock_Helper11_Helper_Loop:
	ld iy, hl
	inc	6, iy
	ldw	(xix+iy), 0xffff
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	inc	2, hl
	cp	xwa, xbc
	jr	c, Flash_InitBytecodeBlock_Helper11_Helper_Loop
	ret
Flash_InitBytecodeBlock_Helper7_Helper:
	lda	xix, (2666:16)
	ldw (xix), 65535
	ldw (xix+2), 65535
	ldw	(xix+0x4), 0xffff
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	ld	hl, 0:i3
	lda	xbc, (xbc+200)
Flash_InitBytecodeBlock_Helper7_Helper_Loop:
	ld	iy, hl
	inc	6, iy
	ldw	(xix+iy), 0xffff
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	inc	2, hl
	cp	xwa, xbc
	jr	c, Flash_InitBytecodeBlock_Helper7_Helper_Loop
	ret
Flash_InitBytecodeBlock_Helper_Helper_Helper:
	lda	xbc, (3074:16)
	ldw (xbc), 65535
	ld	l, 0:opc
	ld	wa, 0:i3
Flash_InitBytecodeBlock_Helper_Helper_Helper_Loop:
	ld	de, wa
	inc	2, de
	ldw	(xbc+de), 0xffff
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, Flash_InitBytecodeBlock_Helper_Helper_Helper_Loop
	ret
Flash_InitBytecodeBlock_Helper9_Helper_Helper3:
	lda	xbc, (2972:16)
	ldw (xbc), 65535
	ld	l, 0:opc
	ld	wa, 0:i3
Flash_InitBytecodeBlock_Helper9_Helper_Helper3_Loop:
	ld	de, wa
	inc	2, de
	ldw	(xbc+de), 0xffff
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, Flash_InitBytecodeBlock_Helper9_Helper_Helper3_Loop
	ret

SlotTable_Insert1748:
	ldib_erp 0xe2, 0
	lda xhl, (1748:16)

SlotTable_Insert1748_Loop:
	ldto_berp C, 0xe2
	extz bc
	add bc, bc
	inc 2, bc
	lda	xde, (xhl+bc)
	ld bc, (xde)
	cp bc, wa
	ret z
	cp bc, 0xffff
	jr nz, SlotTable_Insert1748_Next
	ld (xde), wa
	ret

SlotTable_Insert1748_Next:
	inc1b_erp 0xe2
	cp_erpb 0xe2, 0x32
	jr c, SlotTable_Insert1748_Loop
	ret

SlotTable_Insert1850:
	ldib_erp 0xe2, 0
	lda xhl, (1850:16)

SlotTable_Insert1850_Loop:
	ldto_berp C, 0xe2
	extz bc
	add bc, bc
	inc 2, bc
	lda	xde, (xhl+bc)
	ld bc, (xde)
	cp bc, wa
	ret z
	cp bc, 0xffff
	jr nz, SlotTable_Insert1850_Next
	ld (xde), wa
	ret

SlotTable_Insert1850_Next:
	inc1b_erp 0xe2
	cp_erpb 0xe2, 0x32
	jr c, SlotTable_Insert1850_Loop
	ret

Flash_WriteBackSlotTable:
	pushw_erp 0xfa
	ld xix, (3222:16)
	ld xiy, (3218:16)
	ldw bc, 0x8000
	ldirw
	lda xwa, (1850:16)
	cpw (xwa), 0xffff
	jr z, Flash_WriteBackSlot_StartLoop
	ld wa, (xwa)
	ld w, 0x0:opc
	add a, 0x28
	extz wa
	ld bc, 0:i3
	calr VoiceParam_ComputeOffset

Flash_WriteBackSlot_StartLoop:
	ldib_erp 0xfb, 0

Flash_WriteBackSlot_Loop:
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	inc 2, wa
	lda xbc, (1850:16)
	ld	wa, (xbc+wa)
	cp wa, 0xffff
	jr z, Flash_WriteBackSlot_Erase
	and wa, 0x7f
	extz wa
	ld bc, 0:i3
	calr VoiceParam_ComputeOffset
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x32
	jr c, Flash_WriteBackSlot_Loop

Flash_WriteBackSlot_Erase:
	ld xbc, (3222:16)
	ld xde, (3218:16)
	ld wa, 1:i3
	call Flash_EraseSectorAndWrite
	popw_erp 0xfa
	ret

Flash_SlotUpdateOpsBlock:
	dec	6, xsp
	ld	(xsp+4), a
	ldw	(xsp), 0
	ldw	(xsp+2), 0
	cpw	(0x6d4:16), 0xffff
	jr	z, Flash_SlotUpdateOpsBlock_Skip
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	calr	Flash_SlotUpdateOpsBlock_Helper
	cp	l, 0:i3
	jr	nz, Flash_SlotUpdateOpsBlock_Skip
	ldw	(xsp), 1
Flash_SlotUpdateOpsBlock_Skip:
	cpw	(0x6d6:16), 0xffff
	jr	z, Flash_SlotUpdateOpsBlock_Skip3
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	calr	Flash_SlotUpdateOpsBlock_Helper
	ld	e, 0:opc
	lda	xbc, (1748:16)
Flash_SlotUpdateOpsBlock_Loop:
	ld	a, e
	extz	wa
	add	wa, wa
	inc	2, wa
	.byte	0xd3, 0x07, 0xe4, 0xe0, 0x3f, 0xff, 0xff
	jr	z, Flash_SlotUpdateOpsBlock_Skip2
	inc	1, e
	cp	e, 50
	jr	c, Flash_SlotUpdateOpsBlock_Loop
Flash_SlotUpdateOpsBlock_Skip2:
	cp	l, e
	jr	nc, Flash_SlotUpdateOpsBlock_Skip3
	sub	l, e
	extz	hl
	ld	(xsp+2), hl
Flash_SlotUpdateOpsBlock_Skip3:
	ld	hl, (xsp)
	sll	hl, 8
	add	hl, (xsp+0x2)
	inc	6, xsp
	ret
Flash_InitBytecodeBlock_Helper_Helper:
	dec	4, xsp
	ld	(xsp+2), a
	calr	Flash_InitBytecodeBlock_Helper_Helper_Helper
	ld	a, 30:opc
	ld	(xsp), 31
	cp	(xsp+0x2), 0
	jr	nz, Flash_SlotUpdateOpsBlock_Skip4
	ld	a, 32:opc
Flash_SlotUpdateOpsBlock_Skip4:
	cp	(xsp+0x2), 1
	jr	nz, Flash_SlotUpdateOpsBlock_Skip5
	ld	(xsp), 32
Flash_SlotUpdateOpsBlock_Skip5:
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper_Helper_Helper2
	ld	a, (xsp)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper_Helper_Helper2
	inc	4, xsp
	ret
Flash_InitBytecodeBlock_Helper_Helper_Helper2:
	dec 2,XSP
	push QIZ
	ld (XSP+0x02),A
	lds_erpb 0xfb, 0
.Lc_f183ef:
	ld A,(XSP+0x02)
	extz WA
	ld_erpb_rr c, 0xfb
	extz BC
	ld de, 0:i3
	calr Util_FrameSetup10
	lds_erpb 0xfa, 1
.Lc_f18401:
	ld A,(XSP+0x02)
	extz WA
	ld_erpb_rr c, 0xfb
	extz BC
	ld_erpb_rr e, 0xfa
	extz DE
	calr Util_FrameSetup10
	ld H, 0x00:opc
	ld A,L
	res 0x07,A
	cp L,0x80
	jr c, .Lc_f18430
	extz WA
	add WA,WA
	inc 2,WA
	lda xbc, (0x0c02:16)
	ldw	(xbc+wa), 0x0001
.Lc_f18430:
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr ule, .Lc_f18401
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x0a
	jr c, .Lc_f183ef
	pop QIZ
	inc 2,XSP
	ret
Flash_InitBytecodeBlock_Helper6:
	dec	8, xsp
	ld	(xsp+6), c
	extz	de
	ld	wa, de
	calr	Flash_InitBytecodeBlock_Helper3
	calr	Flash_StoreBaseAndInitAccPatch
	ld	a, (xsp+6)
	extz	wa
	calr	NoteEvent_Store
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
	ld	a, (xsp+6)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper4
	calr	Flash_InitBytecodeBlock_Helper5
	call	TmFlash_CopyToExtMem
	lda	xwa, (2360:16)
	cpw	(xwa+0x2), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper8_Skip
	ld	wa, (xwa)
	ld	(xsp), a
	extz	wa
	calr	NoteEvent_Store
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_CopyToSlot
	calr	SlotTable_ExtendedOpsBlock
	lda	xbc, (1952:16)
	ld	wa, (2362:16)
	ld	(xbc), wa
	ldw	(xbc+2), 0
	ld	a, (xsp)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld_rrb	e, xbc, wa
	extz	de
	ld	wa, de
	calr	Flash_InitBytecodeBlock_Helper3
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
Flash_InitBytecodeBlock_Helper8_Skip:
	cpw	(0x9a2:16), 0xffff
	jrl	z, Flash_InitBytecodeBlock_Helper8_Epilogue
	ld	(xsp+2), 0
Flash_InitBytecodeBlock_Helper8_Loop:
	ld	a, (xsp+2)
	extz	wa
	ld	de, wa
	sla	de, 2
	add	de, 106
	lda	xbc, (2360:16)
	.byte	0xd3, 0x07, 0xe4, 0xe8, 0x3f, 0xff, 0xff
	jr	z, Flash_InitBytecodeBlock_Helper8_Epilogue
	add	wa, wa
	inc	6, wa
	ld_rrw	wa, xbc, wa
	ld	(xsp), a
	extz	wa
	calr	NoteEvent_Store
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_CopyToSlot
	calr	SlotTable_ExtendedOpsBlock
	lda	xbc, (1952:16)
	ld	e, (xsp+2)
	extz	de
	sla	de, 2
	lda	xwa, (2466:16)
	ld_rrw	wa, xwa, de
	ld	(xbc+0x4), wa
	ldw	(xbc+0x6), 0
	ld	a, (xsp)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld_rrb	e, xbc, wa
	extz	de
	ld	wa, de
	calr	Flash_InitBytecodeBlock_Helper3
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
	incm8	1, (xsp+2)
	cp	(xsp+0x2), 50
	jr	c, Flash_InitBytecodeBlock_Helper8_Loop
Flash_InitBytecodeBlock_Helper8_Epilogue:
	inc	8, xsp
	ret
	dec	4, xsp
	ld	(xsp), e
	ld	(xsp+2), c
	calr	SlotTable_ExtendedOpsBlock
	lda	xhl, (2666:16)
	ld	wa, (xhl+2)
	cp	wa, 0xffff
	jr	z, Flash_WriteBackSlotTable_Skip
	lda	xbc, (1952:16)
	ld	(xbc), wa
	ld	wa, (xhl+4)
	ld	(xbc+2), wa
Flash_WriteBackSlotTable_Skip:
	ldib_erp	226, 0
Flash_WriteBackSlotTable_Loop:
	ldto_berp	c, 226
	extz	bc
	sla	bc, 2
	ld	wa, bc
	add	wa, 106
	ld_rrw	wa, xhl, wa
	cp	wa, 65535
	jr	z, Flash_WriteBackSlotTable_Skip2
	ld	ix, bc
	inc	4, ix
	lda	xde, (1952:16)
	st_rrw	wa, xde, ix
	ld	ix, bc
	inc	6, ix
	add	bc, 108
	ld_rrw	wa, xhl, bc
	st_rrw	wa, xde, ix
	inc1b_erp	226
	cp_erpb	226, 50
	jr	c, Flash_WriteBackSlotTable_Loop
Flash_WriteBackSlotTable_Skip2:
	ld	a, (xsp)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper3
	calr	Flash_StoreBaseAndInitAccPatch
	ld	a, (xsp+2)
	extz	wa
	calr	NoteEvent_Store
	extz	hl
	ld	wa, hl
	calr	NoteEventBuffer_Store
	lda	xwa, (1850:16)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Helper8_Skip2
	cpw	(xwa+0x2), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper8_Epilogue2
Flash_InitBytecodeBlock_Helper8_Skip2:
	calr	Flash_WriteBackSlotTable
Flash_InitBytecodeBlock_Helper8_Epilogue2:
	inc	4, xsp
	ret
Flash_InitBytecodeBlock_Helper9:
	extz	de
	ld	wa, de
	calr	Flash_InitBytecodeBlock_Helper3
	ld	xix, (3182:16)
	ld	xiy, (3186:16)
	ldw	bc, 0xb400
	ldirw
	calr	Flash_InitBytecodeBlock_Helper9_Helper
	jp	TmFlash_BulkTransferToSubCPU
	dec	2, xsp
	ld	(xsp), e
	calr	SlotTable_ExtendedOpsBlock
	lda	xhl, (2666:16)
	ld	wa, (xhl+2)
	cp	wa, 0xffff
	jr	z, Flash_WriteBackSlotTable_Skip3
	lda	xbc, (1952:16)
	ld	(xbc), wa
	ld	wa, (xhl+4)
	ld	(xbc+2), wa
Flash_WriteBackSlotTable_Skip3:
	ldib_erp	226, 0
Flash_WriteBackSlotTable_Loop2:
	ldto_berp	c, 226
	extz	bc
	sla	bc, 2
	ld	wa, bc
	add	wa, 106
	ld_rrw	wa, xhl, wa
	cp	wa, 65535
	jr	z, Flash_WriteBackSlotTable_Skip4
	ld	ix, bc
	inc	4, ix
	lda	xde, (1952:16)
	st_rrw	wa, xde, ix
	ld	ix, bc
	inc	6, ix
	add	bc, 108
	ld_rrw	wa, xhl, bc
	st_rrw	wa, xde, ix
	inc1b_erp	226
	cp_erpb	226, 50
	jr	c, Flash_WriteBackSlotTable_Loop2
Flash_WriteBackSlotTable_Skip4:
	ld	a, (xsp)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper3
	ld	xix, (3182:16)
	ld	xiy, (3186:16)
	ldw	bc, 0xb400
	ldirw
	inc	2, xsp
	ret
	lda xsp, (xsp - 0x0400)
	pushw iz
	calr Flash_InitExtMemAddrs
	lda xwa, (xsp + 0x02)
	ld XBC,0x00000400
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, .Lc_f187bb
	lda xwa, (xsp + 0x02)
	cp (XWA),0x48
	jrl nz, .Lc_f187bf
	cp (XWA+0x01),0x00
	jrl nz, .Lc_f187bf
	cp (XWA+0x02),0x4b
	jrl nz, .Lc_f187bf
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x46)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, .Lc_f187bb
	ld wa, 1:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x4a)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, .Lc_f187bb
	ld wa, 2:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x4e)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, .Lc_f187bb
	ld wa, 3:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x52)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, .Lc_f187bb
	ld wa, 4:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x56)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jr lt, .Lc_f187bb
	ld wa, 5:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x5a)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jr lt, .Lc_f187bb
	ld wa, 6:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x5e)
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jr lt, .Lc_f187bb
	ld wa, 7:i3
	calr NoteEventBuffer_Store
	ld xix, (0x0c96:16)
	ld xiy, (0x0c92:16)
	ldw BC, 0x8000
	ldirw
	ld xwa, (0x0c96:16)
	ld XBC,0x0000f400
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld IZ,HL
	cp iz, 0:i3
	jr lt, .Lc_f187bb
	ld xbc, (0x0c96:16)
	ld xde, (0x0c92:16)
	ld wa, 1:i3
	call Flash_EraseSectorAndWrite
	call TmFlash_CopyToExtMem
.Lc_f187bb:
	ld HL,IZ
	jr t, .Lc_f187c2
.Lc_f187bf:
	ldw HL, 0xff9a
.Lc_f187c2:
	popw iz
	lda xsp, (xsp + 0x0400)
	ret
	lda	xsp, (xsp-1036)
	push	xiz
	calr	Flash_InitExtMemAddrs
	ld	xiy, MSP_Default_Signature3
	lda	xix, (xsp+16)
	ldw	bc, 512
	ldirw
	ld	xbc, (3190:16)
	ld	xhl, 0:i3
	ld	l, (xbc+46)
	ld	a, (xbc+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	lda	xbc, (xsp+16)
	lda	xwa, (xbc+68)
	ld	(xsp+12), xwa
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	xwa, (xsp+12)
	ld	(xwa), xix
	ld	xde, (3194:16)
	ld	xhl, 0:i3
	ld	l, (xde+46)
	ld	a, (xde+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	lda	xwa, (xbc+72)
	ld	(xsp+8), xwa
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	xwa, (xsp+8)
	ld	(xwa), xix
	ld	xde, (3198:16)
	ld	xhl, 0:i3
	ld	l, (xde+46)
	ld	a, (xde+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	lda	xwa, (xbc+76)
	ld	(xsp+4), xwa
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	xwa, (xsp+4)
	ld	(xwa), xix
	ld	xde, (3202:16)
	ld	xhl, 0:i3
	ld	l, (xde+46)
	ld	a, (xde+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	lda	xde, (xbc+80)
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	(xde), xix
	ld	xix, (3206:16)
	ld	xhl, 0:i3
	ld	l, (xix+46)
	ld	a, (xix+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	lda	xiy, (xbc+84)
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	(xiy), xix
	ld	xix, (3210:16)
	ld	xhl, 0:i3
	ld	l, (xix+46)
	ld	a, (xix+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	lda	xiz, (xbc+88)
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	(xiz), xix
	ld	xix, (3214:16)
	ld	xhl, 0:i3
	ld	l, (xix+46)
	ld	a, (xix+47)
	ld	xix, 0:i3
	ldfr_berp	a, 240
	sll	xix, 8
	add	xix, xhl
	ld	xhl, xix
	sll	xhl, 4
	ld	(xbc+92), xhl
	ld	xwa, (xsp+12)
	ld	xix, (xwa)
	add	xix, (xbc+0x40)
	ld	xwa, (xsp+8)
	ld	xwa, (xwa)
	add	xwa, xix
	ld	xix, (xsp+4)
	ld	xix, (xix)
	add	xix, xwa
	ld	xwa, (xde)
	add	xwa, xix
	ld	xde, (xiy)
	add	xde, xwa
	ld	xwa, (xiz)
	add	xwa, xde
	add	xhl, xwa
	ld	xwa, (xbc+96)
	add	xwa, xhl
	ld	(xbc+28), xwa
	ld	xiz, xwa
	call	FileIO_GetDiskFreeSpace
	cp	xhl, xiz
	jr	ge, Flash_SlotUpdateOpsBlock_Code_Skip
	ldw	hl, 65435
	jrl	Flash_SlotUpdateOpsBlock_Code_Epilogue
Flash_SlotUpdateOpsBlock_Code_Skip:
	lda	xwa, (xsp+16)
	ld	xbc, 1024
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jrl	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 1:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xwa, (3186:16)
	ld	xde, 0:i3
	ld	e, (xwa+46)
	ld	xbc, 0:i3
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jrl	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 2:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xwa, (3186:16)
	ld	xde, 0:i3
	ld	e, (xwa+46)
	ld	xbc, 0:i3
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jrl	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 3:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xwa, (3186:16)
	ld	xde, 0:i3
	ld	e, (xwa+46)
	ld	xbc, 0:i3
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jrl	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 4:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xwa, (3186:16)
	ld	xde, 0:i3
	ld	e, (xwa+46)
	ld	xbc, 0:i3
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jrl	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 5:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xhl, (3186:16)
	ld	xde, 0:i3
	ld	e, (xhl+46)
	ld	xbc, 0:i3
	ld	c, (xhl+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	ld	xwa, xhl
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jr	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 6:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xhl, (3186:16)
	ld	xde, 0:i3
	ld	e, (xhl+46)
	ld	xbc, 0:i3
	ld	c, (xhl+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	ld	xwa, xhl
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jr	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	wa, 7:i3
	calr	NoteEventBuffer_CopyToSlot
	ld	xhl, (3186:16)
	ld	xde, 0:i3
	ld	e, (xhl+46)
	ld	xbc, 0:i3
	ld	c, (xhl+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	ld	xwa, xhl
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jr	lt, Flash_SlotUpdateOpsBlock_Code_Skip2
	ld	xwa, (3218:16)
	ld	xbc, 62464
	call	FileIO_WriteByte_Impl
Flash_SlotUpdateOpsBlock_Code_Skip2:
	call	FileIO_ReturnError
Flash_SlotUpdateOpsBlock_Code_Epilogue:
	pop	xiz
	lda	xsp, (xsp+1036)
	ret
FloppyDisk_LoadNoteEvents:
	lda xsp, (xsp - 0x0408)
	pushw iz
	ld (XSP+0x0402),XBC
	ld (XSP+0x0406),XWA
	calr Flash_InitExtMemAddrs
	lda xwa, (xsp + 0x02)
	ld XIX,(XSP+0x0406)
	ld XBC,0x00000400
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lda xwa, (xsp + 0x02)
	cp (XWA),0x48
	jrl nz, Floppy_SetHLFF9A_RetZero
	cp (XWA+0x01),0x00
	jrl nz, Floppy_SetHLFF9A_RetZero
	cp (XWA+0x02),0x4b
	jrl nz, Floppy_SetHLFF9A_RetZero
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x46)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 1:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x4a)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 2:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x4e)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 3:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x52)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 4:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x56)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 5:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x5a)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jr lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 6:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (0x0c72:16)
	ld XBC,(XSP+0x5e)
	ld XIX,(XSP+0x0406)
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jr lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 7:i3
	calr NoteEventBuffer_Store
	ld xix, (0x0c96:16)
	ld xiy, (0x0c92:16)
	ldw BC, 0x8000
	ldirw
	ld xwa, (0x0c96:16)
	ld XIX,(XSP+0x0406)
	ld XBC,0x0000f400
	call (XIX)
	ld XHL,(XSP+0x0402)
	call (XHL)
	ld IZ,HL
	cp iz, 0:i3
	jr lt, FloppyCtrl_LoadIzAndContinue
	ld xbc, (0x0c96:16)
	ld xde, (0x0c92:16)
	ld wa, 1:i3
	call Flash_EraseSectorAndWrite
	call TmFlash_CopyToExtMem
FloppyCtrl_LoadIzAndContinue:
	ld hl, iz
	jr FloppyCtrl_PopIzStoreHL

Floppy_SetHLFF9A_RetZero:
	ldw hl, 0xff9a

FloppyCtrl_PopIzStoreHL:
	popw iz
	lda xsp, (xsp+1032)
	ret

; Floppy disk compute tone parameters and validate
FloppyDisk_ComputeToneParams:
	lda xsp, (xsp-1048)
	push xiz
	ld	(xsp+1040), xde
	ld	(xsp+1044), xbc
	ld	(xsp+1048), xwa
	calr Flash_InitExtMemAddrs
	ld xiy, MSP_Default_Signature3
	lda xix, (xsp + 16)
	ldw bc, 0x200
	ldirw
	ld xbc, (3190:16)
	ld xhl, 0:i3
	ld l, (xbc + 46)
	ld a, (xbc + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	lda xbc, (xsp + 16)
	lda xwa, (xbc + 68)
	ld (xsp + 12), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 12)
	ld (xwa), xix
	ld xde, (3194:16)
	ld xhl, 0:i3
	ld l, (xde + 46)
	ld a, (xde + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	lda xwa, (xbc + 72)
	ld (xsp + 8), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 8)
	ld (xwa), xix
	ld xde, (3198:16)
	ld xhl, 0:i3
	ld l, (xde + 46)
	ld a, (xde + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	lda xwa, (xbc + 76)
	ld (xsp + 4), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 4)
	ld (xwa), xix
	ld xde, (3202:16)
	ld xhl, 0:i3
	ld l, (xde + 46)
	ld a, (xde + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	lda xde, (xbc + 80)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xde), xix
	ld xix, (3206:16)
	ld xhl, 0:i3
	ld l, (xix + 46)
	ld a, (xix + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	lda xiy, (xbc + 84)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xiy), xix
	ld xix, (3210:16)
	ld xhl, 0:i3
	ld l, (xix + 46)
	ld a, (xix + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	lda xiz, (xbc + 88)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xiz), xix
	ld xix, (3214:16)
	ld xhl, 0:i3
	ld l, (xix + 46)
	ld a, (xix + 47)
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	sll xix, 8
	add xix, xhl
	ld xhl, xix
	sll xhl, 4
	ld (xbc + 92), xhl
	ld xwa, (xsp + 12)
	ld xix, (xwa)
	add xix, (xbc + 64)
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	add xwa, xix
	ld xix, (xsp + 4)
	ld xix, (xix)
	add xix, xwa
	ld xwa, (xde)
	add xwa, xix
	ld xde, (xiy)
	add xde, xwa
	ld xwa, (xiz)
	add xwa, xde
	add xhl, xwa
	ld xwa, (xbc + 96)
	add xwa, xhl
	ld (xbc + 28), xwa
	ld xiz, xwa
	ld XIX, (xsp + 0x0418)
	call (xix)
	cp xhl, xiz
	jr ge, FloppyDisk_CopyNoteBuffers
	ldw hl, 0xff9b
	jrl FloppyCtrl_PopIzStoreRet

; Floppy disk copy note buffers to slots and write tone data
FloppyDisk_CopyNoteBuffers:
	lda xwa, (xsp + 16)
	ld XIX, (xsp + 0x0414)
	ld xbc, 0x400
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jrl lt, FloppyCtrl_PopIzStoreRet
	ld wa, 1:i3
	calr NoteEventBuffer_CopyToSlot
	ld xwa, (3186:16)
	ld xde, 0:i3
	ld e, (xwa + 46)
	ld xbc, 0:i3
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jrl lt, FloppyCtrl_PopIzStoreRet
	ld wa, 2:i3
	calr NoteEventBuffer_CopyToSlot
	ld xwa, (3186:16)
	ld xde, 0:i3
	ld e, (xwa + 46)
	ld xbc, 0:i3
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jrl lt, FloppyCtrl_PopIzStoreRet
	ld wa, 3:i3
	calr NoteEventBuffer_CopyToSlot
	ld xwa, (3186:16)
	ld xde, 0:i3
	ld e, (xwa + 46)
	ld xbc, 0:i3
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jrl lt, FloppyCtrl_PopIzStoreRet
	ld wa, 4:i3
	calr NoteEventBuffer_CopyToSlot
	ld xwa, (3186:16)
	ld xde, 0:i3
	ld e, (xwa + 46)
	ld xbc, 0:i3
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jrl lt, FloppyCtrl_PopIzStoreRet
	ld wa, 5:i3
	calr NoteEventBuffer_CopyToSlot
	ld xhl, (3186:16)
	ld xde, 0:i3
	ld e, (xhl + 46)
	ld xbc, 0:i3
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jr lt, FloppyCtrl_PopIzStoreRet
	ld wa, 6:i3
	calr NoteEventBuffer_CopyToSlot
	ld xhl, (3186:16)
	ld xde, 0:i3
	ld e, (xhl + 46)
	ld xbc, 0:i3
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jr lt, FloppyCtrl_PopIzStoreRet
	ld wa, 7:i3
	calr NoteEventBuffer_CopyToSlot
	ld xhl, (3186:16)
	ld xde, 0:i3
	ld e, (xhl + 46)
	ld xbc, 0:i3
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)
	cp hl, 0:i3
	jr lt, FloppyCtrl_PopIzStoreRet
	ld xwa, (3218:16)
	ld XIX, (xsp + 0x0414)
	ld xbc, 0xf400
	call (xix)
	ld XIX, (xsp + 0x0410)
	call (xix)

FloppyCtrl_PopIzStoreRet:
	pop xiz
	lda xsp, (xsp+1048)
	ret

ToneParam_ExtendedOpsBlock:
	pushw	iz
	call	cmp_ld_mae
	lda	xwa, (0x94800:24)
	ld	xde, xwa
	lda	xbc, (0xab000:24)
	sub	xbc, xde
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jr	nz, ToneParam_ExtendedOpsBlock_Skip
	calr	ToneParam_ExtendedOpsBlock_Helper
	ld	iz, hl
ToneParam_ExtendedOpsBlock_Skip:
	ld	wa, iz
	cp	iz, 0xff95
	jr	nz, ToneParam_ExtendedOpsBlock_Skip2
	ld	wa, 0:i3
ToneParam_ExtendedOpsBlock_Skip2:
	call	cmp_ld_ato
	ld	hl, iz
	popw	iz
	ret
ToneParam_ExtendedOpsBlock_Helper:
	pushw	iz
	ld	iz, 0:i3
	calr	Flash_InitExtMemAddrs
	ld	xde, (3182:16)
	ld	a, (xde)
	ldfr_berp	a, 238
	lda	xwa, (xde+1)
	ld	h, (xwa)
	lda	xbc, (xde+2)
	ld	l, (xbc)
	cp_erpb	238, 71
	jr	nz, ToneParam_ExtendedOpsBlock_Skip3
	cp	h, 0:i3
	jr	nz, ToneParam_ExtendedOpsBlock_Skip3
	cp	l, 75
	jr	z, ToneParam_ExtendedOpsBlock_Skip4
ToneParam_ExtendedOpsBlock_Skip3:
	cp_erpb	238, 76
	jr	nz, ToneParam_ExtendedOpsBlock_Skip5
	cp	h, 75
	jr	nz, ToneParam_ExtendedOpsBlock_Skip5
	cp	l, 69
	jr	nz, ToneParam_ExtendedOpsBlock_Skip5
ToneParam_ExtendedOpsBlock_Skip4:
	ld	(xde), 72
	ld	(xwa), 0
	ld	(xbc), 75
	cp	(xde+0x10), 0
	jr	nz, ToneParam_ExtendedOpsBlock_Skip11
	ld	wa, 0:i3
	jr	ToneParam_ExtendedOpsBlock_Join
ToneParam_ExtendedOpsBlock_Skip5:
	cp_erpb	238, 70
	jr	nz, ToneParam_ExtendedOpsBlock_Skip6
	cp	h, 0:i3
	jr	nz, ToneParam_ExtendedOpsBlock_Skip6
	cp	l, 75
	jr	z, ToneParam_ExtendedOpsBlock_Skip9
ToneParam_ExtendedOpsBlock_Skip6:
	cp_erpb	238, 70
	jr	nz, ToneParam_ExtendedOpsBlock_Skip7
	cp	h, 32
	jr	nz, ToneParam_ExtendedOpsBlock_Skip7
	cp	l, 75
	jr	z, ToneParam_ExtendedOpsBlock_Skip9
ToneParam_ExtendedOpsBlock_Skip7:
	cp_erpb	238, 76
	jr	nz, ToneParam_ExtendedOpsBlock_Skip8
	cp	h, 75
	jr	nz, ToneParam_ExtendedOpsBlock_Skip8
	cp	l, 65
	jr	z, ToneParam_ExtendedOpsBlock_Skip9
ToneParam_ExtendedOpsBlock_Skip8:
	cp_erpb	238, 76
	jr	nz, ToneParam_ExtendedOpsBlock_Skip10
	cp	h, 75
	jr	nz, ToneParam_ExtendedOpsBlock_Skip10
	cp	l, 66
	jr	nz, ToneParam_ExtendedOpsBlock_Skip10
ToneParam_ExtendedOpsBlock_Skip9:
	calr	ToneParam_ExtendedOpsBlock_Helper2
	ld	iz, hl
	ld	xwa, (3186:16)
	cp	(xwa+0x10), 0
	jr	nz, ToneParam_ExtendedOpsBlock_Skip11
	ld	wa, iz
ToneParam_ExtendedOpsBlock_Join:
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2
	ld	iz, hl
	jr	ToneParam_ExtendedOpsBlock_Skip11
ToneParam_ExtendedOpsBlock_Skip10:
	call	AccDemo_InitDone
	ldw	iz, 0xff9a
ToneParam_ExtendedOpsBlock_Skip11:
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper
	ld	hl, iz
	popw	iz
	ret
ToneParam_ExtendedOpsBlock_Helper2:
	dec	6, xsp
	ldw	(xsp+0x4), 0
	ld	xhl, (3182:16)
	ld	xde, (3186:16)
	ld	a, (xhl+16)
	ld	(xde+16), a
	lda	xiy, (xhl+96)
	lda	xix, (xde+96)
	ldw	bc, 975
	ldirw
	ldi85
	lda	xiy, (xhl+0x800)
	lda	xix, (xde+0x1400)
	ldw	bc, 0x77ff
	ldirw
	ldi85
	call	cmp_ld_mae
	ld	xwa, (3186:16)
	ld	(0x3912:16), xwa
	ld	xwa, (3182:16)
	ld	(0x3916:16), xwa
	ld	xwa, 0:i3
	ld	(xsp), xwa
ToneParam_ExtendedOpsBlock_Loop:
	ld	xwa, (xsp)
	ld	(0x3910:16), a
	ld	(0x3911:16), a
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip12
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip12:
	ld	xwa, 1:i3
	add	(xsp), xwa
	ld	xwa, (xsp)
	cp	xwa, 11
	jr	ule, ToneParam_ExtendedOpsBlock_Loop
	ld	(0x3910:16), 12
	ld	(0x3911:16), 12
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip13
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip13:
	ld	(0x3910:16), 13
	ld	(0x3911:16), 14
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip14
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip14:
	ld	(0x3910:16), 14
	ld	(0x3911:16), 15
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip15
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip15:
	ld	(0x3910:16), 15
	ld	(0x3911:16), 16
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip16
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip16:
	ld	(0x3910:16), 16
	ld	(0x3911:16), 24
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip17
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip17:
	ld	(0x3910:16), 17
	ld	(0x3911:16), 26
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip18
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip18:
	ld	(0x3910:16), 18
	ld	(0x3911:16), 27
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip19
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip19:
	ld	(0x3910:16), 19
	ld	(0x3911:16), 28
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip20
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip20:
	ld	(0x3910:16), 12
	ld	(0x3911:16), 18
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip21
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip21:
	ld	(0x3910:16), 13
	ld	(0x3911:16), 20
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip22
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip22:
	ld	(0x3910:16), 14
	ld	(0x3911:16), 21
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip23
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip23:
	ld	(0x3910:16), 15
	ld	(0x3911:16), 22
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip24
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip24:
	ld	(0x3910:16), 12
	ld	(0x3911:16), 13
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip25
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip25:
	ld	(0x3910:16), 15
	ld	(0x3911:16), 17
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip26
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip26:
	ld	(0x3910:16), 16
	ld	(0x3911:16), 25
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip27
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip27:
	ld	(0x3910:16), 19
	ld	(0x3911:16), 29
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip28
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip28:
	ld	(0x3910:16), 12
	ld	(0x3911:16), 19
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip29
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip29:
	ld	(0x3910:16), 15
	ld	(0x3911:16), 23
	calr	ToneParam_ExtendedOpsBlock_Helper2_Helper
	cp	hl, 0:i3
	jr	z, ToneParam_ExtendedOpsBlock_Skip30
	ld	(xsp+4), hl
ToneParam_ExtendedOpsBlock_Skip30:
	ld	hl, (xsp+4)
	inc	6, xsp
	ret
ToneParam_ExtendedOpsBlock_Helper2_Helper:
	pushw iz
	ld iz, 0:i3
	res 0, (0x3514:16)
	call DualVoice_ParamLoadDone
	ld a, (0x3514:16)
	extz WA
	bit 0x00,WA
	jr z, .Lc_f19194
	ld xwa, (0x3916:16)
	ld (0x3912:16), xwa
	ldmm8 0x3910, 0x3911
	call AccPatch_InitFromSlotIndex
	ld xwa, (0x0c72:16)
	ld (0x3912:16), xwa
	ldw IZ, 0xff95
.Lc_f19194:
	ld HL,IZ
	popw iz
	ret
ToneParam_ExtendedOpsBlock_Helper_Helper:
	ld L, 0x00:opc
	ld de, 0:i3
.Lc_f1919c:
	ld WA,DE
	add WA,0x0060
	ld xbc, (0x0c6e:16)
	lda	xbc, (xbc+wa)
	ld (XBC+0x22),0x40
	ld BC,WA
	ld xwa, (0x0c6e:16)
	lda	xwa, (xwa+bc)
	ld (XWA+0x2a),0x0c
	ld xwa, (0x0c6e:16)
	lda	xwa, (xwa+bc)
	ld (XWA+0x32),0x74
	ld xwa, (0x0c6e:16)
	lda	xwa, (xwa+bc)
	ld (XWA+0x3a),0x40
	inc 1,L
	add DE,0x0060
	cp L,0x1e
	jr c, .Lc_f1919c
	ret
ToneParam_ExtendedOpsBlock_Helper_Helper2:
	push	xiz
	ld	hl, wa
	ld	c, (0x3451:16)
	ldfr_berp	c, 251
	ld	c, (0x3452:16)
	ldfr_berp	c, 250
	ld	c, (0x3453:16)
	ldfr_berp	c, 249
	ld	xbc, (0xc6e:16)
	ld	(0x3451), (xbc+0x70)
	ld	xbc, (0xc6e:16)
	ld	(0x3452), (xbc+0x71)
	ld	(0x3453:16), 4
	ld	(0x343a:16), 12
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 5
	ld	(0x343a:16), 13
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 6
	ld	(0x343a:16), 16
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 7
	ld	(0x343a:16), 17
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 10
	ld	(0x343a:16), 14
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 11
	ld	(0x343a:16), 15
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	xbc, (3182:16)
	ld	(0x3451), (xbc+0x1f0)
	ld	xbc, (0xc6e:16)
	ld	(0x3452), (xbc+0x1f1)
	ld	(0x3453:16), 4
	ld	(0x343a:16), 18
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 5
	ld	(0x343a:16), 19
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 6
	ld	(0x343a:16), 22
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 7
	ld	(0x343a:16), 23
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 10
	ld	(0x343a:16), 20
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 11
	ld	(0x343a:16), 21
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	xbc, (3182:16)
	ld	(0x3451), (xbc+0x370)
	ld	xbc, (0xc6e:16)
	ld	(0x3452), (xbc+0x371)
	ld	(0x3453:16), 4
	ld	(0x343a:16), 24
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 5
	ld	(0x343a:16), 25
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 6
	ld	(0x343a:16), 28
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 7
	ld	(0x343a:16), 29
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 10
	ld	(0x343a:16), 26
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ld	(0x3453:16), 11
	ld	(0x343a:16), 27
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper
	ldto_berp	c, 251
	ld	(0x3451:16), c
	ldto_berp	c, 250
	ld	(0x3452:16), c
	ldto_berp	c, 249
	ld	(0x3453:16), c
	pop	xiz
	ret
ToneParam_ExtendedOpsBlock_Helper_Helper2_Helper:
	pushw iz
	ld IZ,WA
	set 0, (0x3435:16)
	call AccPat_IndexToAddress_Sub
	ld a, (0x3514:16)
	extz WA
	bit 0x00,WA
	jr z, .Lc_f19378
	ldw IZ, 0xff95
.Lc_f19378:
	ld HL,IZ
	popw iz
	ret
DualVoice_LoadAndScan:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xde
	ld	(xsp+12), c
	ld	(xsp+14), a
	ld	(xsp+4), 0
	ld	(xsp+10), 0
	calr	Flash_InitExtMemAddrs
	ld	(3182:16), xiz
	cp	(xsp + 14), 0xa
	jrl	nc, DualVoice_LoadDoneRetVal
	ld	a, (xsp+14)
	extz	wa
	calr	DualVoice_ScanAllColumns
	ld	a, (xsp+12)
	extz	wa
	calr	DualVoice_ScanAllColumnsAlt
	ld	a, (xsp+12)
	extz	wa
	calr	NoteEvent_Store
	ld	(xsp+6), l
	ld	a, (xsp+6)
	extz	wa
	calr	NoteEventBuffer_CopyToSlot
	call	AccPatch_CountSlotsAlt
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld_rrb	a, xbc, wa
	ld	(xsp+8), a
	ld	xwa, (3186:16)
	ld	(14610:16), xwa
	ldib_erp	251, 0
DualVoice_AccPatchLoop:
	ld	c, (xsp+8)
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (MSP_Default_ChannelMap:24)
	ld	(0x3910:16), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, DualVoice_AccPatchLoop
	ld	xwa, (3182:16)
	ld	(14610:16), xwa
	ld	xwa, (3186:16)
	ld	(14614:16), xwa
	res	0, (0x3514:16)
	ldib_erp	251, 0
DualVoice_ParamCompareLoop:
	ld	e, (xsp+14)
	extz	de
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (MSP_Default_ChannelMap:24)
	ld	(0x3910:16), (xde+wa)
	ld	a, (xsp+8)
	extz	wa
	add	bc, wa
	ld	(0x3911:16), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, DualVoice_LoopCheckNext
	ld	(xsp+10), 1
DualVoice_SetLoadFlag:
	ld (xsp + 4), 0x1

DualVoice_LoadDoneRetVal:
	ld l, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 12)
	ret

DualVoice_LoopCheckNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, DualVoice_ParamCompareLoop
	cp (xsp + 10), 0x0
	jr nz, DualVoice_SetLoadFlag
	calr Flash_StoreBaseAndInitAccPatch
	ld a, (xsp + 6)
	extz wa
	calr NoteEventBuffer_Store
	lda xwa, (1850:16)
	cpw (xwa), 0xffff
	jr nz, DualVoice_WriteBackSlots
	cpw (xwa + 2), 0xffff
	jr z, DualVoice_LoadDoneRetVal

DualVoice_WriteBackSlots:
	calr Flash_WriteBackSlotTable
	jr DualVoice_LoadDoneRetVal
	pushw iz
	call msp_ld_mae
	lda xwa, (0x1e8800:24)
	ld xde, xwa
	lda xbc, (0x1ec400:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	calr FileHdr_ValidateSignature
	ld wa, iz
	call msp_ld_ato
	ld hl, iz
	popw iz
	ret

FileHdr_ValidateSignature:
	calr FileHdr_InitBasePointer
	ld xwa, (3226:16)
	ld l, (xwa)
	ld e, (xwa + 1)
	ld c, (xwa + 2)
	cp l, 0x47
	jr nz, FileHdr_CheckLKE
	cp e, 0:i3
	jr nz, FileHdr_CheckLKE
	cp c, 0x4b
	jr z, FileHdr_SignatureMatch

FileHdr_CheckLKE:
	cp l, 0x4c
	jr nz, FileHdr_CheckMKB
	cp e, 0x4b
	jr nz, FileHdr_CheckMKB
	cp c, 0x45
	jr z, FileHdr_SignatureMatch

FileHdr_CheckMKB:
	cp l, 0x4d
	ret nz
	cp e, 0x4b
	ret nz
	cp c, 0x42
	ret nz

FileHdr_SignatureMatch:
	lda xwa, (xwa+10239)
	ld xbc, xwa
	lda xde, (xwa-9983)

FileHdr_CopyDataLoop:
	ld a, (xbc)
	ld	(xbc+512), a
	dec 1, xbc
	cp xbc, xde
	jr nc, FileHdr_CopyDataLoop
	calr ToneData_SetupCopyPointers
	ret

FileHdr_InitBasePointer:
	lda xwa, (0x1e8800:24)
	ld (3226:16), xwa
	ret

ToneData_SetupCopyPointers:
	ld xbc, (3226:16)
	lda xbc, (xbc+256)
	ld xwa, xbc
	lda xbc, (xbc+512)

ToneData_ZeroFillLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, ToneData_ZeroFillLoop

	lda xwa, (Composer_SettingsBlock:24)
	ld xbc, xwa
	ld xde, (3226:16)
	lda xhl, (xwa + 6)

ToneData_CopyBlock1_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock1_Loop
	lda xhl, (Composer_SettingsBlock_0x60:24)
	ld xbc, xhl
	ld xwa, (3226:16)
	lda xde, (xwa + 16)
	lda xhl, (xhl + 16)

ToneData_CopyBlock2_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock2_Loop
	lda xhl, (MSP_Default_PartBankMap:24)
	ld xbc, xhl
	ld xwa, (3226:16)
	lda xde, (xwa+512)
	lda xhl, (xhl + 64)

ToneData_CopyBlock3_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock3_Loop
	lda xhl, (Composer_SettingsBlock_0x80:24)
	ld xbc, xhl
	ld xwa, (3226:16)
	lda xde, (xwa+576)
	lda xhl, (xhl + 64)

ToneData_CopyBlock4_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock4_Loop
	lda xhl, (Composer_SettingsBlock_0xC0:24)
	ld xbc, xhl
	ld xwa, (3226:16)
	lda xde, (xwa+640)
	lda xhl, (xhl + 64)

ToneData_CopyBlock5_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock5_Loop
	ld xwa, (3226:16)
	lda xbc, (xwa + 32)
	ld xde, 0:i3

ToneData_ScanRegionLoop:
	cp (xbc), 0x0
	jr nz, ToneData_AdvanceRegion
	lda xiy, (Composer_SettingsBlock_0x70:24)
	ld xhl, xiy
	ld xwa, (3226:16)
	lda xwa, (xwa + 32)
	ld xix, xde
	add xix, xwa
	lda xiy, (xiy + 16)

ToneData_CopyRegion_Inner:
	ld A, (xhl+)
	ld (xix+), a
	cp xhl, xiy
	jr c, ToneData_CopyRegion_Inner

ToneData_AdvanceRegion:
	add xde, 0x10
	lda xbc, (xbc + 16)
	cp xde, 0xc0
	jr c, ToneData_ScanRegionLoop
	ret

InitializeSuna:
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Class
	ld (XBC),XWA
	lda xwa, (ClassProc:24)
	ld (XBC+0x04),XWA
	ld wa, (Suna_ClassCount_164:24)
	ld (XBC+0x08),WA
	lda xwa, (Suna_ClassTable_164:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0164
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResEvent
	ld (XBC),XWA
	lda xwa, (ResEventProc:24)
	ld (XBC+0x04),XWA
	ld wa, (Suna_ResEventCount_1C4:24)
	ld (XBC+0x08),WA
	lda xwa, (Suna_ResEventTable_1C4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01c4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResMethod
	ld (XBC),XWA
	lda xwa, (ResMethodProc:24)
	ld (XBC+0x04),XWA
	ld wa, (Suna_ResMethodCount_1E4:24)
	ld (XBC+0x08),WA
	lda xwa, (NakaMethodTable_PtrsStart:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01e4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0049
	lda xwa, (Composer_FunctionTable:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0124
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0049
	lda xwa, (Composer_CallbackNameTable:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0424
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda xwa, (Suna_FunctionTable_104:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0104
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda xwa, (Suna_FunctionTable_404:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0404
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0024
	lda xwa, (Suna_MainFunctionTable_144:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0144
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0024
	lda xwa, (PtrTbl_FuncNameStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0444
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe1b4e2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0010
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (Naka_Accomp14_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0310
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe1b4f2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0011
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (Naka_StylCnvWait_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0311
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe1b516:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0012
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (Naka_StylCnvVer_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0312
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe1b536:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0013
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (Suna_ResNameTable_313:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0313
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe1b54a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0014
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (Suna_ResNameTable_314:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0314
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe1b55e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0015
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (Naka_StylCnvTxt_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0315
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe1b582:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0016
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (Suna_ResNameTable_316:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0316
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0012
	lda xwa, (0xe1b5a2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0012
	lda xwa, (Suna_ResNameTable_3B0:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe1b5ee:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (Naka_CmpMenu_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0016
	lda xwa, (0xe1b622:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0016
	lda xwa, (Suna_ResNameTable_3B2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (0xe1b67e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (Suna_ResNameTable_3B3:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0012
	lda xwa, (0xe1b696:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0012
	lda xwa, (Naka_NamingMem_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001f
	lda xwa, (0xe1b6e2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001f
	lda xwa, (Naka_CmSetP1Grid_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda xwa, (0xe1b762:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b6
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda xwa, (Suna_ResNameTable_3B6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b6
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe1b76a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (Naka_CmpMem_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0021
	lda xwa, (0xe1b786:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0021
	lda xwa, (PtrTbl_CmpNcpScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0025
	lda xwa, (Naka_SeqToComposer_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00b9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0025
	lda xwa, (PtrTbl_S2cScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03b9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000e
	lda xwa, (Naka_EasyComposer_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ba
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000e
	lda xwa, (PtrTbl_EasyCompScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ba
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (Naka_EasyComposer2_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00bb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (PtrTbl_BendScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03bb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000b
	lda xwa, (Naka_ModeSelect_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00bd
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000b
	lda xwa, (Suna_ResNameTable_3BD:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03bd
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0021
	lda xwa, (Naka_ExpandMode_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00be
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0021
	lda xwa, (PtrTbl_CstmCpScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03be
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001b
	lda xwa, (Naka_Accomp7_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001b
	lda xwa, (PtrTbl_MspBkslScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0010
	lda xwa, (Suna_ViewableTable_C9:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0010
	lda xwa, (Suna_ResNameTable_3C9:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (Naka_Accomp9_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ca
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (PtrTbl_MspMenuScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ca
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (Naka_Accomp10_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00cb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (Suna_ResNameTable_3CB:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03cb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0009
	lda xwa, (Naka_Accomp11_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00cc
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0009
	lda xwa, (PtrTbl_MspReGrpScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03cc
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (Naka_Accomp12_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00dc
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (PtrTbl_SndArgrScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03dc
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (Naka_Accomp13_Screens:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ed
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (PtrTbl_ApcSelScreenStrs:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ed
	call RegisterObjectTable
	pushw 0x0004
	pushw InitializeSuna_Str_MD_CMP@hi16
	pushw InitializeSuna_Str_MD_CMP@lo16
	ld XWA,0x0000000e
	ld XBC,NAKA_MAINFUNC_CmpModeFunc
	ld XDE,TITLE_CMMENU
	call RegisterMode
	pushw 0x0004
	pushw InitializeSuna_Str_MD_MSP@hi16
	pushw InitializeSuna_Str_MD_MSP@lo16
	ld XWA,0x0000000f
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,TITLE_MSPMENU
	call RegisterMode
	pushw 0x0004
	pushw InitializeSuna_Str_MD_MSP_REC@hi16
	pushw InitializeSuna_Str_MD_MSP_REC@lo16
	ld XWA,0x00000010
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,TITLE_MSPREC
	call RegisterMode
	pushw 0x0004
	pushw InitializeSuna_Str_MD_SND_ARG@hi16
	pushw InitializeSuna_Str_MD_SND_ARG@lo16
	ld XWA,0x00000011
	ld XBC,NAKA_MAINFUNC_SndArgModeFunc
	ld XDE,TITLE_SNDARG
	call RegisterMode
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVWAIT@hi16
	pushw InitializeSuna_Str_TT_STYLCNVWAIT@lo16
	ld XWA,0x00000010
	ld XBC,NAKA_MAINFUNC_StylCnvWaitTtlFunc
	ld XDE,0x00100000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVMODL@hi16
	pushw InitializeSuna_Str_TT_STYLCNVMODL@lo16
	ld XWA,0x00000011
	ld XBC,NAKA_MAINFUNC_StylCnvModlTtlFunc
	ld XDE,0x00110000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVCNVT@hi16
	pushw InitializeSuna_Str_TT_STYLCNVCNVT@lo16
	ld XWA,0x00000012
	ld XBC,NAKA_MAINFUNC_StylCnvCnvtTtlFunc
	ld XDE,0x00120000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVSTOR@hi16
	pushw InitializeSuna_Str_TT_STYLCNVSTOR@lo16
	ld XWA,0x00000013
	ld XBC,NAKA_MAINFUNC_StylCnvStorTtlFunc
	ld XDE,0x00130000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVTXT@hi16
	pushw InitializeSuna_Str_TT_STYLCNVTXT@lo16
	ld XWA,0x00000014
	ld XBC,NAKA_MAINFUNC_StylCnvTxtTtlFunc
	ld XDE,0x00140000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVSEL@hi16
	pushw InitializeSuna_Str_TT_STYLCNVSEL@lo16
	ld XWA,0x00000015
	ld XBC,NAKA_MAINFUNC_StylCnvSelTtlFunc
	ld XDE,0x00150000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_STYLCNVCONT@hi16
	pushw InitializeSuna_Str_TT_STYLCNVCONT@lo16
	ld XWA,0x00000016
	ld XBC,NAKA_MAINFUNC_StylCnvContTtlFunc
	ld XDE,0x00160000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMMENU@hi16
	pushw InitializeSuna_Str_TT_CMMENU@lo16
	ld XWA,0x000000b0
	ld XBC,NAKA_MAINFUNC_CmpMenuTtlFunc
	ld XDE,0x00b00000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMBKSL@hi16
	pushw InitializeSuna_Str_TT_CMBKSL@lo16
	ld XWA,0x000000b1
	ld XBC,NAKA_MAINFUNC_CmpBkslTtlFunc
	ld XDE,0x00b10000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMBKSL_S@hi16
	pushw InitializeSuna_Str_TT_CMBKSL_S@lo16
	ld XWA,0x000000b2
	ld XBC,NAKA_MAINFUNC_CmpBksl_STtlFunc
	ld XDE,0x00b20000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMNAME@hi16
	pushw InitializeSuna_Str_TT_CMNAME@lo16
	ld XWA,0x000000b3
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00b30000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMSET@hi16
	pushw InitializeSuna_Str_TT_CMSET@lo16
	ld XWA,0x000000b4
	ld XBC,NAKA_MAINFUNC_CmpSetTtlFunc
	ld XDE,0x00b40000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMREAL@hi16
	pushw InitializeSuna_Str_TT_CMREAL@lo16
	ld XWA,0x000000b5
	ld XBC,NAKA_MAINFUNC_CmpRealTtlFunc
	ld XDE,0x00b50000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMSTEP@hi16
	pushw InitializeSuna_Str_TT_CMSTEP@lo16
	ld XWA,0x000000b6
	ld XBC,NAKA_MAINFUNC_CmpStepTitleFunc
	ld XDE,0x00b60000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMBAL@hi16
	pushw InitializeSuna_Str_TT_CMBAL@lo16
	ld XWA,0x000000b7
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00b70000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMPNCP@hi16
	pushw InitializeSuna_Str_TT_CMPNCP@lo16
	ld XWA,0x000000b8
	ld XBC,NAKA_MAINFUNC_CmpNcpTtlFunc
	ld XDE,0x00b80000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMSEQCP@hi16
	pushw InitializeSuna_Str_TT_CMSEQCP@lo16
	ld XWA,0x000000b9
	ld XBC,NAKA_MAINFUNC_S2cTtlFunc
	ld XDE,0x00b90000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMEASY@hi16
	pushw InitializeSuna_Str_TT_CMEASY@lo16
	ld XWA,0x000000ba
	ld XBC,NAKA_MAINFUNC_CmEsyTtlFunc
	ld XDE,0x00ba0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMBEND@hi16
	pushw InitializeSuna_Str_TT_CMBEND@lo16
	ld XWA,0x000000bb
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00bb0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMMODE@hi16
	pushw InitializeSuna_Str_TT_CMMODE@lo16
	ld XWA,0x000000bd
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00bd0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_CMCSTMCP@hi16
	pushw InitializeSuna_Str_TT_CMCSTMCP@lo16
	ld XWA,0x000000be
	ld XBC,NAKA_MAINFUNC_CstmCpTtlFunc
	ld XDE,0x00be0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_MSPBKSL@hi16
	pushw InitializeSuna_Str_TT_MSPBKSL@lo16
	ld XWA,0x000000c8
	ld XBC,NAKA_MAINFUNC_MspBkslTtlFunc
	ld XDE,0x00c80000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_MSPREC@hi16
	pushw InitializeSuna_Str_TT_MSPREC@lo16
	ld XWA,0x000000c9
	ld XBC,NAKA_MAINFUNC_MspRecTtlFunc
	ld XDE,0x00c90000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_MSPMENU@hi16
	pushw InitializeSuna_Str_TT_MSPMENU@lo16
	ld XWA,0x000000ca
	ld XBC,NAKA_MAINFUNC_MspMenuTtlFunc
	ld XDE,0x00ca0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_MSPNAME@hi16
	pushw InitializeSuna_Str_TT_MSPNAME@lo16
	ld XWA,0x000000cb
	ld XBC,NAKA_MAINFUNC_MspNameTtlFunc
	ld XDE,0x00cb0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_MSPGROUP@hi16
	pushw InitializeSuna_Str_TT_MSPGROUP@lo16
	ld XWA,0x000000cc
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00cc0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_SNDARG@hi16
	pushw InitializeSuna_Str_TT_SNDARG@lo16
	ld XWA,0x000000dc
	ld XBC,NAKA_MAINFUNC_SndArgTtlFunc
	ld XDE,0x00dc0000
	call RegisterTitle
	pushw 0x0004
	pushw InitializeSuna_Str_TT_APCSEL@hi16
	pushw InitializeSuna_Str_TT_APCSEL@lo16
	ld XWA,0x000000ed
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00ed0000
	call RegisterTitle
	lda xsp, (xsp + 0x0e)
	ret
CmpBndRngFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_SMALL_STEP
	jr z, CmpBndRng_ReturnOne
	cp xbc, EVT_GET_LARGE_STEP
	jr z, CmpBndRng_ReturnOne
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, CmpBndRng_ReturnThree
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, CmpBndRng_ReturnSizeConst
	cp xbc, EVT_GET_LSW_STRING
	jr z, CmpBndRng_BoundCase
	ld xhl, 0:i3
	jr CmpBndRng_PopIzRet

CmpBndRng_BoundCase:
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cp bc, 0:i3
	jr lt, CmpBndRng_DefaultString
	cp bc, 0xc
	jr gt, CmpBndRng_DefaultString
	sla bc, 2
	lda xde, (0x03d992:24)
	ld	xbc, (xde+bc)
	push xbc
	jr CmpBndRng_CallStrcpy

CmpBndRng_DefaultString:
	pushw CmpBndRng_DefaultString_Str_ERR@hi16
	pushw CmpBndRng_DefaultString_Str_ERR@lo16

CmpBndRng_CallStrcpy:
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	CmpBndRng_PopIzRet
CmpBndRng_ReturnSizeConst:
	ld xhl, 0x28403
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnThree:
	ld xhl, 3:i3
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnOne:
	ld xhl, 1:i3

CmpBndRng_PopIzRet:
	pop xiz
	ret
CmpBndRng_End:

AcCmpMdBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_SET_SELECTED
	jrl z, CmpSetP1_TtlDispatch
	cp xbc, EVT_RAM_DATA
	jr z, AcCmpMdBox_HandleLswUpdate
	cp xbc, EVT_REPAINT
	jr z, AcCmpMdBox_InheritAndRefresh
	cp xbc, EVT_PAINT
	jr z, AcCmpMdBox_InheritAndRefresh
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl CmpSetP1_TtlDispatch_End

AcCmpMdBox_InheritAndRefresh:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x94810
	ld bc, 1:i3
	call MainRamGet
	jr GridBoxProc_Return

AcCmpMdBox_HandleLswUpdate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xix, (xsp + 4)
	ld xbc, (xix)
	lda xwa, (0x094810:24)
	lda xde, (xhl + 46)
	cp xwa, xbc
	jr nz, GridBoxProc_Return
	ld l, (xhl + 50)
	extz hl
	extz xhl
	ld xbc, (xde)
	cp xhl, (xix + 14)
	jr nz, AcCmpMdBox_SetValueZero
	ldw (xbc), 0x1
	jr AcCmpMdBox_SendChangeEvent

AcCmpMdBox_SetValueZero:
	ldw (xbc), 0x0

AcCmpMdBox_SendChangeEvent:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	jr GridBoxProc_Return

; CmpSetP1 title dispatch
CmpSetP1_TtlDispatch:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, GridBoxProc_Return
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 50)
	ld (0x094810:24), a

GridBoxProc_Return:
	ld xhl, 0:i3

; CmpSetP1 title dispatch end
CmpSetP1_TtlDispatch_End:
	pop xiz
	inc 4, xsp
	ret
; CmpSetP1 title dispatch default
CmpSetP1_TtlDispatch_Default:
AcCmpSetGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, CmpSetP1_GridCheck_Case3
	ld xwa, (xsp + 16)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, CmpSetP1_GridCheck_Case1
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, CmpSetP1_GridCheckDispatch
	cp xwa, EVT_SHOW
	jr z, CmpSetP1_DialGrid
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, CmpSetP1_GridCheck_Case4
	cp xbc, 0x6
	jrl gt, CmpSetP1_GridCheck_Case4
	add xbc, xbc
	add xbc, NoteStepDisplayData_0x5C
	ld bc, (xbc)
	lda xix, (CmpSetP1_DialGrid:24)
	jp	t, (xix+bc)

; CmpSetP1 dial grid dispatch (7-entry, table 0xe1ce3a)
CmpSetP1_DialGrid:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl CmpSetP1_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_SendAndApplyFunc
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (NoteStepDisplayData_0x38:24)
	ld	wa, (xbc+wa)
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl CmpSetP1_ReturnZeroJmp

CmpSetP1_SendAndApplyFunc:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, CmpSetP1_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl CmpSetP1_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_DialDownSendApply
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (NoteStepDisplayData_0x4A:24)
	ld	wa, (xbc+wa)
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl CmpSetP1_ReturnZeroJmp

CmpSetP1_DialDownSendApply:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3

CmpSetP1_SetDialEnable:
	call SetDialEnable
	jr CmpSetP1_ReturnZeroJmp

; CmpSetP1 grid check dispatch
CmpSetP1_GridCheckDispatch:
	ld xwa, xiz
	ld xiz, 0x3e
	jr CmpSetP1_GridCheck_Case2

; CmpSetP1 grid check case 1
CmpSetP1_GridCheck_Case1:
	ld xwa, xiz
	ld xiz, 0x42

; CmpSetP1 grid check case 2
CmpSetP1_GridCheck_Case2:
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	CmpSetP1_ReturnZeroJmp
CmpSetP1_GridCheck_Case3:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall

CmpSetP1_ReturnZeroJmp:
	ld xhl, 0:i3
	jr CmpSetP1_GridCheck_Case5

; CmpSetP1 grid check case 4
CmpSetP1_GridCheck_Case4:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; CmpSetP1 grid check case 5
CmpSetP1_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

CmpSetP1GridCheck:
	lda xsp, (xsp - 28)
	ld xwa, xbc
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, CmpSetP1_GridCheck_Return
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, Widget_PostEvtReturnZero
	cp xwa, 0x6
	jrl gt, Widget_PostEvtReturnZero
	add xwa, xwa
	add xwa, StrTimeSig_1_2_0x20
	ld wa, (xwa)
	lda xix, (CmpSetP1_GridCheck_EventEnc:24)
	jp	t, (xix+wa)

; CmpSetP1 grid check event encoding dispatch
CmpSetP1_GridCheck_EventEnc:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	cp	wa, 1:i3
	jrl	nz, Widget_PostEvtReturnZero
	exts	xde
	ld	xwa, NAKA_MAINFUNC_MainCmpSetFunc
	ld	xbc, EVT_CMP_SET_P1_UP
	jr	CmpSetP1GridCheck_Join
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	cp	wa, 1:i3
	jrl	nz, Widget_PostEvtReturnZero
	exts	xde
	ld	xwa, NAKA_MAINFUNC_MainCmpSetFunc
	ld	xbc, EVT_CMP_SET_P1_DN
CmpSetP1GridCheck_Join:
	call	MainFuncCall
	jrl	Widget_PostEvtReturnZero

; CmpSetP1 grid check return
CmpSetP1_GridCheck_Return:
	lda xbc, (xsp + 20)
	ld xwa, xde
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	ld wa, (xwa)
	lda xhl, (0x03da06:24)
	dec 1, wa
	cp wa, 0:i3
	jrl lt, WidgetHandler_PostEventAndReturnZero
	cp wa, 7:i3
	jrl gt, WidgetHandler_PostEventAndReturnZero
	add wa, wa
	lda xix, (StrTimeSig_1_2_0x10:24)
	ld	wa, (xix+wa)
	lda xix, (UI_COMPONENT_DISPATCH:24)
	jp	t, (xix+wa)
; UI component dispatch table - handles cases 0-7 for grid/focus handling
; Offset table at 0xe1cef0 selects which handler to run based on WA value
UI_COMPONENT_DISPATCH:
	ld	a, (13371:16)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	UI_COMPONENT_DISPATCH_Str_Fmtd@hi16
	pushw	UI_COMPONENT_DISPATCH_Str_Fmtd@lo16
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jrl	WidgetHandler_PostEventAndReturnZero
UI_COMPONENT_DISPATCH_CASE1:
	ld	a, (13362:16)
	srl	a, 7
	extz	wa
	sla	wa, 2
	lda	xbc, (252406:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	a, (13372:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (252430:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw	UI_COMPONENT_DISPATCH_CASE1_Str_Fmts_Fmts@hi16
	pushw	UI_COMPONENT_DISPATCH_CASE1_Str_Fmts_Fmts@lo16
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+16)
	jr	WidgetHandler_PostEventAndReturnZero	; -> 0xF1A845
UI_COMPONENT_DISPATCH_CASE2:
	ld	c, (13389:16)
	ld	xwa, 252358
	jr	UI_COMPONENT_DISPATCH_CASE2_COMMON
UI_COMPONENT_DISPATCH_CASE3:
	ld	a, (13390:16)
	srl	a, 4
	and	a, 1
	ld	c, a
	ld	xwa, 252414
UI_COMPONENT_DISPATCH_CASE2_COMMON:
	extz bc	; Zero-extend C to BC
	sla bc, 2	; Shift left by 2 (multiply by 4)
	ld	xwa, (xwa+bc)	; Load entry from table
	push xwa	; Push parameter
	jr UI_COMPONENT_DISPATCH_PUSH_CALL	; Jump to push and call
UI_COMPONENT_DISPATCH_CASE4:
	ld wa, 6:i3	; Load 6
	jr UI_COMPONENT_DISPATCH_CASE5_COMMON	; Jump to common code
UI_COMPONENT_DISPATCH_CASE5:
	ld wa, 5:i3	; Load 5
UI_COMPONENT_DISPATCH_CASE5_COMMON:
	ld	c, (0x344e:16)	; [v10] Load byte from UI state
	and	a, 0xf	; [v10] Mask lower nibble
	jr	z, UI_COMPONENT_DISPATCH_CASE5_SKIP	; [v10] Skip shift if zero
	srla	c	; [v10] Shift A right by C
UI_COMPONENT_DISPATCH_CASE5_SKIP:
	and c, 0x1	; Mask C to get bit 0
	extz bc	; Zero-extend C to BC
	sla bc, 2	; Shift left by 2 (multiply by 4)
	ld	xwa, (xhl+bc)	; Load entry from table
	push xwa	; Push parameter
UI_COMPONENT_DISPATCH_PUSH_CALL:
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	inc	8, xsp
WidgetHandler_PostEventAndReturnZero:
	cpw (xsp + 22), 0x4
	jr z, Widget_PostEvtReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW
	call SendEvent

Widget_PostEvtReturnZero:
	ld xhl, 0:i3
	lda xsp, (xsp + 28)
	ret

CmpSetGridCheck:
	lda xsp, (xsp - 18)
	push xiz
	ld xwa, xbc
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, CmpSet_GridCheck_Dispatch
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, GridCheck_ReturnZero
	cp xwa, 0x6
	jrl gt, GridCheck_ReturnZero
	add xwa, xwa
	add xwa, StrPanLeft64_0xA
	ld wa, (xwa)
	lda xix, (GridCheck_Handler0:24)
	jp	t, (xix+wa)

; =============================================================================
; GridCheck_Handler0 - Grid/Check widget handler for cases 0 and 2
; Called via jump table when event code is 0x1c00017 + (0 or 2)
; Queries UI object state and sends appropriate event (0x01e40008 or 0x01e4000a)
; =============================================================================
GridCheck_Handler0:
	call GetFocusObject	; Get UI object
	ld xwa, xhl	; Save result in XWA
	ld xbc, EVT_GET_SELECTED_CEL	; Event code for query
	ld xde, 0:i3	; Parameter = 0
	call SendEvent	; Query object state
	ld xde, xhl	; Result in XDE
	lda xwa, (xsp + 14)	; Get local var pointer
	ld xbc, xde	; Copy result to XBC
	srl xbc, 16	; SRL 0, XBC (clear carry)
	ldiw_erp 0xe6, 0	; LD QBC, 0 (clear high bits)
	ld (xwa), bc	; Store low word
	ld (xwa + 2), de	; Store high word
	ld wa, (xwa)	; Load state value
	exts xde	; Sign extend DE
	cp wa, 2:i3	; Check if state == 2
	jr z, GridCheck_Handler0_State2
	cp wa, 1:i3	; Check if state == 1
	jrl nz, GridCheck_ReturnZero	; If neither, exit
	ld xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld xbc, EVT_PAN_UP	; Event: grid check state 1 (case 0)
	jr GridCheck_SendEvent
GridCheck_Handler0_State2:
	ld xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld xbc, EVT_RLMT_UP	; Event: grid check state 2 (case 0)
	jr GridCheck_SendEvent

; =============================================================================
; GridCheck_Handler1 - Grid/Check widget handler for cases 1 and 3
; Called via jump table when event code is 0x1c00017 + (1 or 3)
; Queries UI object state and sends appropriate event (0x01e40009 or 0x01e4000b)
; =============================================================================
GridCheck_Handler1:
	call GetFocusObject	; Get UI object
	ld xwa, xhl	; Save result in XWA
	ld xbc, EVT_GET_SELECTED_CEL	; Event code for query
	ld xde, 0:i3	; Parameter = 0
	call SendEvent	; Query object state
	ld xde, xhl	; Result in XDE
	lda xwa, (xsp + 14)	; Get local var pointer
	ld xbc, xde	; Copy result to XBC
	srl xbc, 16	; SRL 0, XBC (clear carry)
	ldiw_erp 0xe6, 0	; LD QBC, 0 (clear high bits)
	ld (xwa), bc	; Store low word
	ld (xwa + 2), de	; Store high word
	ld wa, (xwa)	; Load state value
	exts xde	; Sign extend DE
	cp wa, 2:i3	; Check if state == 2
	jr z, GridCheck_Handler1_State2
	cp wa, 1:i3	; Check if state == 1
	jr nz, GridCheck_ReturnZero	; If neither, exit
	ld xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld xbc, EVT_PAN_DN	; Event: grid check state 1 (case 1)
	jr GridCheck_SendEvent
GridCheck_Handler1_State2:
	ld xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld xbc, EVT_RLMT_DN	; Event: grid check state 2 (case 1)
	; Fall through to GridCheck_SendEvent

; =============================================================================
; GridCheck_SendEvent - Common epilogue for grid/check handlers
; Sends the event in XBC with widget ID in XWA
; =============================================================================
GridCheck_SendEvent:
	call MainFuncCall	; Send event
	jr GridCheck_ReturnZero	; Return to caller

; CmpSet grid check dispatch (7-entry, table 0xe1d40e)
CmpSet_GridCheck_Dispatch:
	lda xbc, (xsp + 14)
	ld xwa, xde
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	ld de, (xbc)
	ld bc, (xwa)
	exts xbc
	cp de, 2:i3
	jr z, GridCheck_SetMode1
	cp de, 1:i3
	jr nz, GridCheck_GetFocusAndSend
	ld wa, 0:i3
	ld xiz, 0x3da4e
	jr GridCheck_LookupAndSend

GridCheck_SetMode1:
	ld wa, 1:i3
	ld xiz, 0x3d9c6

GridCheck_LookupAndSend:
	calr GridCheck_LookupSndParam

	extz hl

	sla hl, 2

	ld	xwa, (xiz+hl)

	push xwa

	lda xwa, (xsp + 8)

	push xwa

	call	Scoop_EventLoop_12Entry_Helper

	inc 8, xsp



GridCheck_GetFocusAndSend:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, EVT_GRID_DRAW
	call SendEvent

GridCheck_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 18)
	ret

GridCheck_LookupSndParam:
	ld	e, (0x343a:16)
	extz	de
	sla	de, 2
	lda	xhl, (RhythmTiming_OffsetTable:24)
	ld	xix, 0x94860
	add	xix, (xhl+de)
	sll	xbc, 3
	add	xbc, 0x10
	add	xbc, xix
	cp	a, 0:i3
	jr	nz, GridCheck_ClampParamAlt
	ld	l, (xbc + 2)
	cp	l, 0x7f
	ret	ule
	ld	l, 0x7f:opc
	jr	GridCheck_ClampDone
GridCheck_ClampParamAlt:
	ld l, (xbc + 5)
	cp l, 0xb
	ret ule
	ld l, 0xb:opc

GridCheck_ClampDone:
	ret

CmpSetPageFunc:
	cp xbc, EVT_REPAINT
	jr z, CmpSetPage_ReturnZero
	cp xbc, EVT_PAINT
	jr z, CmpSetPage_ReturnZero
	cp xbc, EVT_HIDE
	jr z, CmpSetPage_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, CmpSetPage_ReturnZero
	or xde, xde
	jr nz, CmpSetPage_ReturnZero
	ld xwa, 0xb40002
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xb4000e
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent

CmpSetPage_ReturnZero:
	ld xhl, 0:i3
	ret
AcApcToggle_End:

AcApcToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_LSW_DATA
	jrl z, AcApcToggle_HandleLswMsg
	cp xiz, EVT_SHOW
	jr z, AcApcToggle_HandleOpen
	cp xiz, EVT_SW_IN
	jr z, AcApcToggle_HandleClose
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr AcApcToggle_CallInherited

AcApcToggle_HandleClose:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, AcApcToggle_Fallthrough
	ld xwa, (xsp + 12)
	ld xbc, EVT_TOGGLE_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xbc + 40)
	ld xbc, EVT_SET_PARAM
	call ApFuncCall
	jrl EventHandler_Return

AcApcToggle_Fallthrough:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcApcToggle_CallInherited:
	call InheritedProc
	jrl AcApcToggle_PopReturn

AcApcToggle_HandleOpen:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xbc, (xiz + 44)
	cp xbc, 0x1
	jr z, AcApcToggle_SetParam83
	or xbc, xbc
	jr nz, AcApcToggle_ReadSndParam
	ld xwa, 0x28081
	jr AcApcToggle_ReadSndParam

AcApcToggle_SetParam83:
	ld xwa, 0x28083

AcApcToggle_ReadSndParam:
	call	AcApcToggleProc_Helper
	lda	xbc, (xiz+34)
	ld	xwa, (xbc)
	cp	hl, 0:i3
	jr	nz, AcApcToggle_SetOne
	ldw	(xwa), 0
	jr	AcApcToggle_SendUpdate
AcApcToggle_SetOne:
	ldw (xwa), 0x1

AcApcToggle_SendUpdate:
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	jrl AcApcToggle_SendEvent

AcApcToggle_HandleLswMsg:
	ld XWA,(XSP+0x0c)
	ld XBC,XIZ
	ld XDE,(XSP+0x08)
	call InheritedProc
	ld XWA,(XSP+0x0c)
	call GetViewInstance
	ld XWA,(XSP+0x08)
	ld XBC,(XWA)
	lda xwa, (xhl + 0x2c)
	cp XBC,0x00028083
	jr z, AcApcToggle_Check83Match
	cp XBC,0x00028081
	jr nz, EventHandler_Return
	ld XWA,(XWA)
	or XWA,XWA
	jr nz, EventHandler_Return
	ld XWA,0x00028081
	call AcApcToggleProc_Helper
	ld XWA,(XSP+0x08)
	cpw (XWA+0x04), 0x0001
	jr nz, AcApcToggle_SendZero
	ld XWA,(XSP+0x0c)
	ld XBC,EVT_PARA_DRAW
	ld xde, 1:i3
	jr t, AcApcToggle_SendEvent
AcApcToggle_SendZero:
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr AcApcToggle_SendEvent

AcApcToggle_Check83Match:
	ld xwa, (xwa)
	cp xwa, 0x1
	jr nz, EventHandler_Return
	ld xwa, (xsp + 8)
	cpw (xwa + 4), 0x1
	jr nz, AcApcToggle_Send83Zero
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	jr AcApcToggle_SendEvent

AcApcToggle_Send83Zero:
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

AcApcToggle_SendEvent:
	call SendEvent

EventHandler_Return:
	ld xhl, 0:i3

AcApcToggle_PopReturn:
	pop xiz
	lda xsp, (xsp + 12)
	ret

ApcOnOffFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, ApcOnOff_ReturnZero
	ld xwa, 0x28081
	ld bc, 1:i3
	ld de, 4:i3
	call MainLswPut

ApcOnOff_ReturnZero:
	ld xhl, 0:i3
	ret

ApcOnBasFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, ApcOnBas_ReturnZero
	ld xwa, 0x28083
	ld bc, 1:i3
	ld de, 4:i3
	call MainLswPut

ApcOnBas_ReturnZero:
	ld xhl, 0:i3
	ret
ApcOnBas_End:

AcApcMdBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_SET_SELECTED
	jrl z, AcApcMdBox_HandleTitleDisp
	cp xbc, EVT_LSW_DATA
	jr z, AcApcMdBox_HandleLswUpdate
	cp xbc, EVT_REPAINT
	jr z, AcApcMdBox_GetLswValue
	cp xbc, EVT_PAINT
	jr z, AcApcMdBox_GetLswValue
	cp xbc, EVT_HIDE
	jr z, AcApcMdBox_ResetFilter
	cp xbc, EVT_SHOW
	jrl nz, AcApcMdBox_DefaultInherited
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x28080
	call SetLswFilter
	ld wa, 0:i3
	jrl AcApcMdBox_SetDialEnable

AcApcMdBox_ResetFilter:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x28080
	call ResetLswFilter
	jrl AcS2cMem_ReturnZeroJmp

AcApcMdBox_GetLswValue:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x28080
	call MainLswGet
	jrl AcS2cMem_ReturnZeroJmp

AcApcMdBox_HandleLswUpdate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xiy, (xsp + 4)
	ld xwa, (xiy)
	cp xwa, 0x28080
	jr nz, AcS2cMem_ReturnZeroJmp
	ld a, (xhl + 50)
	ldfr_berp A, 0xf0
	extz ix
	lda xde, (xhl + 46)
	ld xbc, (xde)
	cp ix, (xiy + 4)
	jr nz, AcApcMdBox_SetValueZero
	ldw (xbc), 0x1
	jr AcApcMdBox_SendChangeEvent

AcApcMdBox_SetValueZero:
	ldw (xbc), 0x0

AcApcMdBox_SendChangeEvent:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	jr AcS2cMem_ReturnZeroJmp

AcApcMdBox_HandleTitleDisp:
	ld XWA,XIZ
	ld XDE,(XSP+0x04)
	call InheritedProc
	ld XWA,(XSP+0x04)
	cp XWA,0x00000001
	jr nz, AcS2cMem_ReturnZeroJmp
	ld XWA,XIZ
	call GetViewInstance
	ld A,(XHL+0x32)
	st_erpb_rr a, 0xf8
	extz IZ
	ld XWA,0x00028080
	call AcApcToggleProc_Helper
	cp HL,IZ
	jr z, AcS2cMem_ReturnZeroJmp
	ld XWA,0x00028080
	ld BC,IZ
	ld de, 4:i3
	call MainLswPut
	ld wa, 0:i3
AcApcMdBox_SetDialEnable:
	call SetDialEnable

AcS2cMem_ReturnZeroJmp:
	ld xhl, 0:i3
	jr AcApcMdBox_PopReturn

AcApcMdBox_DefaultInherited:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc

AcApcMdBox_PopReturn:
	pop xiz
	inc 4, xsp
	ret
AcApcMdBox_End:

AcS2cMemNoBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, S2cMemNoBox_HandleScroll
	cp xbc, EVT_PAINT
	jr z, S2cMemNoBox_HandleScroll
	cp xbc, EVT_HIDE
	jr z, S2cMemNoBox_HandleClose
	cp xbc, EVT_SHOW
	jr z, S2cMemNoBox_HandleOpen
	ld xwa, xiz
	call InheritedProc
	jr S2cMemNoBox_PopReturn

S2cMemNoBox_HandleOpen:
	ld xwa, xiz
	jr S2cMemNoBox_CallInherited

S2cMemNoBox_HandleClose:
	ld xwa, xiz

S2cMemNoBox_CallInherited:
	call InheritedProc
	jr S2cMemNoBox_ReturnZero

S2cMemNoBox_HandleScroll:
	ld	xwa, xiz
	call	InheritedProc
	ld	a, (14579:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (StrPanLeft64_0x18:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
S2cMemNoBox_ReturnZero:
	ld xhl, 0:i3

S2cMemNoBox_PopReturn:
	pop xiz
	lda xsp, (xsp+256)
	ret
S2cMemNoBox_End:

PsS2cFmeasBoxProc:
	lda xsp, (xsp-260)
	push xiz
	ld	(xsp+260), xwa
	cp xbc, EVT_REPAINT
	jr z, PsS2cFmeas_HandleScroll
	cp xbc, EVT_PAINT
	jr z, PsS2cFmeas_HandleScroll
	ld XWA, (xsp + 0x0104)
	call InheritedProc
	jr PsS2cFmeas_PopReturn
PsS2cFmeas_HandleScroll:
	ld	xwa, (xsp+260)
	call	InheritedProc
	ld	xwa, (xsp+260)
	call	GetViewInstance
	ld	xiz, xhl
	push_sd16w	0xee, 0x38
	pushw	PsS2cFmeas_HandleScroll_Str_Fmt3d@hi16
	pushw	PsS2cFmeas_HandleScroll_Str_Fmt3d@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xbc, (xiz+22)
	lda	xwa, (xiz+32)
	cp	(14811:16), 0
	jr	nz, PsS2cFmeas_SetActive
	ldw	(xwa), 0
	ldw	(xbc), 255
	jr	PsS2cFmeas_SendUpdateEvents
PsS2cFmeas_SetActive:
	ldw (xwa), 0xff
	ldw (xbc), 0xf5

PsS2cFmeas_SendUpdateEvents:
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld xhl, 0:i3

PsS2cFmeas_PopReturn:
	pop xiz
	lda xsp, (xsp+260)
	ret
PsS2cFmeas_End:

PsS2cLmeasBoxProc:
	lda xsp, (xsp-260)
	push xiz
	ld	(xsp+260), xwa
	cp xbc, EVT_REPAINT
	jr z, PsS2cLmeas_HandleScroll
	cp xbc, EVT_PAINT
	jr z, PsS2cLmeas_HandleScroll
	ld XWA, (xsp + 0x0104)
	call InheritedProc
	jr PsS2cLmeas_PopReturn
PsS2cLmeas_HandleScroll:
	ld	xwa, (xsp+260)
	call	InheritedProc
	ld	xwa, (xsp+260)
	call	GetViewInstance
	ld	xiz, xhl
	push_sd16w	0xf0, 0x38
	pushw	PsS2cLmeas_HandleScroll_Str_Fmt3d@hi16
	pushw	PsS2cLmeas_HandleScroll_Str_Fmt3d@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xbc, (xiz+22)
	lda	xwa, (xiz+32)
	cp	(14811:16), 1
	jr	nz, PsS2cLmeas_SetActive
	ldw	(xwa), 0
	ldw	(xbc), 255
	jr	PsS2cLmeas_SendUpdateEvents
PsS2cLmeas_SetActive:
	ldw (xwa), 0xff
	ldw (xbc), 0xf5

PsS2cLmeas_SendUpdateEvents:
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld xhl, 0:i3

PsS2cLmeas_PopReturn:
	pop xiz
	lda xsp, (xsp+260)
	ret
PsS2cLmeas_End:

PsSeqSongNoBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsSeqSongNo_HandleScroll
	cp xbc, EVT_PAINT
	jr z, PsSeqSongNo_HandleScroll
	ld xwa, xiz
	call InheritedProc
	jr PsSeqSongNo_PopReturn

PsSeqSongNo_HandleScroll:
	ld	xwa, xiz
	call	InheritedProc
	ld	a, (65507:24)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	PsSeqSongNo_HandleScroll_Str_SONG_Fmt2d@hi16
	pushw	PsSeqSongNo_HandleScroll_Str_SONG_Fmt2d@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	ld	xhl, 0:i3
PsSeqSongNo_PopReturn:
	pop xiz
	lda xsp, (xsp+256)
	ret
PsSeqSongNo_End:

PsS2cTransBoxProc:
	lda xsp, (xsp-260)
	push xiz
	ld	(xsp+260), xwa
	cp xbc, EVT_REPAINT
	jr z, PsS2cTrans_HandleScroll
	cp xbc, EVT_PAINT
	jr z, PsS2cTrans_HandleScroll
	ld XWA, (xsp + 0x0104)
	call InheritedProc
	jr SndArg_GridBnk_Case2
PsS2cTrans_HandleScroll:
	ld	xwa, (xsp+260)
	call	InheritedProc
	ld	xwa, (xsp+260)
	call	GetViewInstance
	ld	xiz, xhl
	ld	a, (14578:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (PtrTbl_TransposeStrs:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	inc	8, xsp
	lda	xwa, (xiz+22)
	lda	xbc, (xiz+32)
	cp	(14811:16), 2
	jr	nz, SndArg_GridBnk_Case0
	ldw	(xbc), 0
	ldw	(xwa), 255
	jr	SndArg_GridBnk_Case1
SndArg_GridBnk_Case0:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

; SndArgGridBnk case 1
SndArg_GridBnk_Case1:
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld xhl, 0:i3

; SndArgGridBnk case 2
SndArg_GridBnk_Case2:
	pop xiz
	lda xsp, (xsp+260)
	ret
; SndArgGridBnk case 3
SndArg_GridBnk_Case3:
S2cGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xbc
	ld (xsp + 16), xwa
	ld xwa, xiz
	cp xiz, EVT_CLR_GRID_HANTEN
	jrl z, FdcFormat_GridCheck_Case3
	cp xiz, EVT_REQUEST_GRID_DRAW
	jrl z, FdcFormat_GridCheck_Case2
	cp xiz, EVT_GET_FIXED_ROW_STR
	jrl z, FdcFormat_GridCheck_Case1
	cp xiz, EVT_GET_FIXED_COL_STR
	jrl z, FdcFormat_GridCheck
	cp xiz, EVT_SHOW
	jr z, FdcFormat_DialGrid
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, FdcFormat_GridCheck_Case4
	cp xwa, 0x6
	jrl gt, FdcFormat_GridCheck_Case4
	add xwa, xwa
	add xwa, StrTranspose_Minus25_0x4
	ld wa, (xwa)
	lda xix, (FdcFormat_DialGrid:24)
	jp	t, (xix+wa)
FdcFormat_DialGrid:
	ld	xwa, (xsp+16)
	ld	xbc, xiz
	ld	xde, (xsp+12)
	call	InheritedProc
	ld	xwa, (xsp+16)
	call	GetViewInstance
	ld	(xsp+8), xhl
	cp	(14811:16), 3
	jrl	nz, FdcFormat_ReturnZeroJmp
	ld	xwa, (xsp+16)
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+4), xhl
	ld	xwa, (xsp+8)
	ld	bc, (xwa+26)
	ld	xwa, (xsp+4)
	srl	xwa, 16
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+16)
	ld	xbc, EVT_INDEXSW_UP
	call	SetDialUp
	ld	xwa, (xsp+8)
	ld	bc, (xwa+26)
	ld	xwa, (xsp+4)
	srl	xwa, 16
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+16)
	ld	xbc, EVT_INDEXSW_DOWN
	call	SetDialDown
	ld	wa, 1:i3
	jrl	S2cGrid_SetDialEnable
	ld	xwa, (xsp+16)
	ld	xbc, xiz
	ld	xde, (xsp+12)
	call	InheritedProc
	ld	xwa, (xsp+16)
	ld	xbc, EVT_CHECK_INDEX
	ld	xde, (xsp+12)
	call	SendEvent
	or	xhl, xhl
	jr	z, S2cGrid_DialDownSendApply
	ld	xwa, (xsp+16)
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	dec	1, hl
	extz	xhl
	add	xhl, 4294901760
	ld	xwa, (xsp+16)
	ld	xbc, EVT_SELE_DRAW
	ld	xde, xhl
	call	SendEvent
	ld	xwa, (xsp+16)
	ld	xbc, EVT_INDEXSW_UP_AIC
	ld	xde, (xsp+12)
	call	SetAutoInc
	jrl	FdcFormat_ReturnZeroJmp
S2cGrid_DialDownSendApply:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl S2cGrid_SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, S2cGrid_DialUpSendApply
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FdcFormat_ReturnZeroJmp

S2cGrid_DialUpSendApply:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3

S2cGrid_SetDialEnable:
	call SetDialEnable
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check dispatch
FdcFormat_GridCheck:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr S2cGrid_GetViewAndCopy

; FdcFormat grid check case 1
FdcFormat_GridCheck_Case1:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

S2cGrid_GetViewAndCopy:
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	FdcFormat_ReturnZeroJmp
FdcFormat_GridCheck_Case2:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check case 3
FdcFormat_GridCheck_Case3:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 12), xhl
	ld xwa, (xsp + 16)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, (xsp + 12)
	call SendEvent

FdcFormat_ReturnZeroJmp:
	ld xhl, 0:i3
	jr FdcFormat_GridCheck_Case5

; FdcFormat grid check case 4
FdcFormat_GridCheck_Case4:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc

; FdcFormat grid check case 5
FdcFormat_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

