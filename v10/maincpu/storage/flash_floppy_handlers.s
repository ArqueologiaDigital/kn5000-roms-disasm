; =============================================================================
; Flash & Floppy Handlers
; =============================================================================
;
; Opens with the TAIL of the sound editor's ScreenData block (0xF158A7-0xF165EA in
; v10/v9; base SeScreenData at 0xF10C06, audio/sound_editor_ui.s; the lane seui record
; model): list-boundary tables and bound record lists that GraphicsRender_Start and the
; SeMenu code read.  The flash-memory sector write routines, floppy note-event loading
; and the FDC format UI follow it, from InitializeNaka on.
; =============================================================================

; list-boundary table, 12 x {u32 start, u32 end} of bound record lists; the code reads XIY = (T+8i), XIX = (T+8i+4)
; evidence: SeMenu_NameEdit_DataBlock1_Join2+0x19 (0xF100CB)
SeScreenData_ListBounds:
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D4C
	.long	SeMenu_PatchEdit_DataBlock_Records
	.long	SeScreenData_0x4D4C
	.long	SeMenu_PatchEdit_DataBlock_Records
	.long	SeScreenData_0x4DAD
	.long	SeScreenData_0x4DDA
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E2A
	.long	SeScreenData_0x4E54
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E68
	.long	SeScreenData_0x4E8B
	.long	SeScreenData_0x4E68
	.long	SeScreenData_0x4E8B
; bound record list (5 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF1593A
; evidence: pairs table 0xF158A7
SeScreenData_0x4D01:
; F15907..F1593A  [flags:u8][len:u8][payload] records
; F15907 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; F15911 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; F1591B flags=0x05 len=11
	.byte	0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbb, 0x0f, 0x02, 0x00
; F15926 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x14, 0x12, 0x02
; F15930 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x65, 0x06, 0xff, 0x00, 0x20, 0x6b, 0x14, 0x03
; table of 6 pointers to the records of the list at 0xF15907 (entry 0 repeated); entry 0 of the per-variant table at 0xF15AA1, drawn one record at a time by SeGfx_DrawIndexedBoundRecord (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF10146)
SeScreenData_0x4D34:
; F1593A..F15952  6 x u32 pointer
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D01
	.long	SeScreenData_0x4D01 + 0xa
	.long	SeScreenData_0x4D01 + 0x14
	.long	SeScreenData_0x4D01 + 0x1f
	.long	SeScreenData_0x4D01 + 0x29
; bound record list (6 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF1598F
; evidence: pairs table 0xF158A7
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1598F
SeScreenData_0x4D4C:
; F15952..F1598F  [flags:u8][len:u8][payload] records
; F15952 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1598F
SeScreenData_0x4D56:
; F1595C flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1598F
SeScreenData_0x4D60:
; F15966 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbc, 0x0f, 0x02
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1598F
SeScreenData_0x4D6A:
; F15970 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x14, 0x12, 0x02
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1598F
SeScreenData_0x4D74:
; F1597A flags=0x05 len=11
	.byte	0x05, 0x0b, 0x65, 0x06, 0xff, 0x00, 0x20, 0x6b, 0x14, 0x02, 0x00
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1598F
SeScreenData_0x4D7F:
; F15985 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x66, 0x06, 0xff, 0x00, 0x20, 0xc4, 0x16, 0x02
; table of 9 pointers, entry = A (0..8; entry 0 repeated): entries 1-6 -> the records
; SeScreenData_0x4D56.., entries 7/8 -> FlashRead_BlockData_Field7/_Field8.  The code loads it
; into XIY only on SeMenu_PatchEdit_DataBlock's `cp a, 7 / jr nc` path, and
; SeGfx_DrawIndexedBoundRecord draws entry WA (XIY = (XIY + 4*WA)) -- so the entries that reader
; uses are 7 and 8 (corrected 2026-10-02 from "table of 7", Wave 2 claims review)
; evidence: SeMenu_PatchEdit_DataBlock_Join+0x6 (0xF1017E)
; (name SeMenu_PatchEdit_DataBlock_Records kept: other files use it; the object is ScreenData, see above)
SeMenu_PatchEdit_DataBlock_Records:
	.long	SeScreenData_0x4D4C
	.long	SeScreenData_0x4D4C
	.long	SeScreenData_0x4D56
	.long	SeScreenData_0x4D60
	.long	SeScreenData_0x4D6A
	.long	SeScreenData_0x4D74
	.long	SeScreenData_0x4D7F
	.long	FlashRead_BlockData_Field7
	.long	FlashRead_BlockData_Field8
; bound record list (4 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF159E0
; evidence: pairs table 0xF158A7
SeScreenData_0x4DAD:
; F159B3..F159E0  [flags:u8][len:u8][payload] records
; F159B3 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; F159BD flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; F159C7 flags=0x02 len=15
	.byte	0x02, 0x0f, 0x63, 0x06, 0x0f, 0x00, 0x20
	.long	SeMenu_DrawLfoPartSwitches_Records + 0x10
	.byte	0x03, 0x00, 0xbb, 0x0f
; F159D6 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x13, 0x12, 0x03
; table of 5 pointers to the records of the list at 0xF159B3 (entry 0 repeated); entry 6 of the per-variant table at 0xF15AA1, drawn one record at a time by SeGfx_DrawIndexedBoundRecord (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF10146)
SeScreenData_0x4DDA:
; F159E0..F159F4  5 x u32 pointer
	.long	SeScreenData_0x4DAD
	.long	SeScreenData_0x4DAD
	.long	SeScreenData_0x4DAD + 0xa
	.long	SeScreenData_0x4DAD + 0x14
	.long	SeScreenData_0x4DAD + 0x23
; bound record list (4 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15A1C
; evidence: pairs table 0xF158A7
SeScreenData_0x4DEE:
; F159F4..F15A1C  [flags:u8][len:u8][payload] records
; F159F4 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; F159FE flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; F15A08 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbc, 0x0f, 0x02
; F15A12 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x14, 0x12, 0x02
; table of 5 pointers to the records of the list at 0xF159F4 (entry 0 repeated); entry 7 of the per-variant table at 0xF15AA1, drawn one record at a time by SeGfx_DrawIndexedBoundRecord (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF10146)
SeScreenData_0x4E16:
; F15A1C..F15A30  5 x u32 pointer
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4DEE
	.long	SeScreenData_0x4DEE + 0xa
	.long	SeScreenData_0x4DEE + 0x14
	.long	SeScreenData_0x4DEE + 0x1e
; bound record list (4 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15A5A
; evidence: pairs table 0xF158A7
SeScreenData_0x4E2A:
; F15A30..F15A5A  [flags:u8][len:u8][payload] records
; F15A30 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x20, 0x0c, 0x0b, 0x02
; F15A3A flags=0x05 len=11
	.byte	0x05, 0x0b, 0x62, 0x06, 0xff, 0x00, 0x20, 0x63, 0x0d, 0x02, 0x00
; F15A45 flags=0x05 len=11
	.byte	0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbb, 0x0f, 0x02, 0x00
; F15A50 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x64, 0x06, 0xff, 0x00, 0x20, 0x13, 0x12, 0x03
; table of 5 pointers to the records of the list at 0xF15A30 (entry 0 repeated); entry 8 of the per-variant table at 0xF15AA1, drawn one record at a time by SeGfx_DrawIndexedBoundRecord (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF10146)
SeScreenData_0x4E54:
; F15A5A..F15A6E  5 x u32 pointer
	.long	SeScreenData_0x4E2A
	.long	SeScreenData_0x4E2A
	.long	SeScreenData_0x4E2A + 0xa
	.long	SeScreenData_0x4E2A + 0x15
	.long	SeScreenData_0x4E2A + 0x20
; bound record list (3 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF15A91
; evidence: pairs table 0xF158A7
SeScreenData_0x4E68:
; F15A6E..F15A91  [flags:u8][len:u8][payload] records
; F15A6E flags=0x02 len=15
	.byte	0x02, 0x0f, 0x61, 0x06, 0x01, 0x00, 0x20
	.long	SeMenu_DrawPartSelector_Records3 + 0x53
	.byte	0x03, 0x00, 0x0b, 0x0b
; F15A7D flags=0x00 len=10
	.byte	0x00, 0x0a, 0x62, 0x06, 0xff, 0x00, 0x20, 0x64, 0x0d, 0x02
; F15A87 flags=0x00 len=10
	.byte	0x00, 0x0a, 0x63, 0x06, 0xff, 0x00, 0x20, 0xbb, 0x0f, 0x03
; table of 4 pointers to the records of the list at 0xF15A6E (entry 0 repeated); entry 10 of the per-variant table at 0xF15AA1, drawn one record at a time by SeGfx_DrawIndexedBoundRecord (XIY = (XIY + 4*WA))
; evidence: SeMenu_PatchEdit_DataBlock (0xF10146)
; (name SeScreenData_0x4E8B kept: other files use it; the object is ScreenData, see above)
SeScreenData_0x4E8B:
; F15A91..F15AA1  4 x u32 pointer
	.long	SeScreenData_0x4E68
	.long	SeScreenData_0x4E68
	.long	SeScreenData_0x4E68 + 0xf
	.long	SeScreenData_0x4E68 + 0x19
; 12 pointers to record-pointer tables, one per screen variant = the byte at RAM 0x670; entry -> SeGfx_DrawIndexedBoundRecord
; evidence: SeMenu_PatchEdit_DataBlock (0xF10146)
SeMenu_PatchEdit_DataBlock_Records2:
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15ACE-0xF15AFF (49 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=91% dist=8 near SeMenu_PatchEdit_DataBlock_Records2+45
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D34
	.long	SeScreenData_0x4D34
	.long	SeMenu_PatchEdit_DataBlock_Records
	.long	SeMenu_PatchEdit_DataBlock_Records
	.long	SeScreenData_0x4DDA
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E54
	.long	SeScreenData_0x4E16
	.long	SeScreenData_0x4E8B
	.long	SeScreenData_0x4E8B
; 12 list END pointers, one per screen variant = the byte at RAM 0x670, for the static list the code starts with `ld xiy, <start>`
; evidence: SeMenu_NameEdit_DataBlock1 (0xF10020)
SeMenu_NameEdit_DataBlock1_Records9:
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x96
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x96
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x96
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x96
	.long	SeMenu_NameEdit_DataBlock1_Records2
	.long	SeMenu_NameEdit_DataBlock1_Records2
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x78
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x78
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x78
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x78
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x5a
	.long	SeMenu_NameEdit_DataBlock1_Records + 0x5a
; fixed-width string table, 13 chars per entry, 168 B: the text choices of a bound op02/op07 record (its +7 pointer; +11 = chars per entry)
; evidence: bound op02 record 0xF164F7
SeScreenData_0x4EFB:
; F15B01..F15BA9  effect name table, 12 x 13 chars then 2 x 6
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
TuningSys_Param_01_Data:
	.ascii	"MONO  STEREO"
; static record list (37 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF15D26
; evidence: SeMenu_NameEdit_DataBlock2+0xA (0xF100DA)
SeMenu_NameEdit_DataBlock2_Records:
; F15BA9..F16109  [flags:u8][len:u8][payload] records
; F15BA9 flags=0x23 len=5
	.byte	0x23, 0x05, 0x62, 0x84, 0x00
; F15BAE flags=0x1c len=15
	.byte	0x1c, 0x0f, 0x7b, 0x00, 0x05, 0x00
	.ascii	"EASY EDIT"
; F15BBD flags=0x17 len=16
	.byte	0x17, 0x10, 0x06, 0x00, 0x07, 0x00
	.ascii	"SOUND EDIT"
; F15BCD flags=0x07 len=5
	.byte	0x07, 0x05, 0x50, 0x05, 0x10
; F15BD2 flags=0x06 len=9
	.byte	0x06, 0x09, 0xa2, 0x05
	.ascii	"WRITE"
; F15BDB flags=0x07 len=17
	.byte	0x07, 0x11, 0x8e, 0x0a
	.ascii	"0CTAVE SHIFT:"
; F15BEC flags=0x07 len=18
	.byte	0x07, 0x12, 0xa2, 0x0a
	.ascii	"BRILLIANCE   :"
; F15BFE flags=0x07 len=5
	.byte	0x07, 0x05, 0x68, 0x0b, 0x10
; F15C03 flags=0x07 len=5
	.byte	0x07, 0x05, 0x8f, 0x0b, 0x11
; F15C08 flags=0x07 len=17
	.byte	0x07, 0x11, 0xa6, 0x10
	.ascii	"ATTACK TIME :"
; F15C19 flags=0x07 len=18
	.byte	0x07, 0x12, 0xba, 0x10
	.ascii	"VIBRAT0 DEPTH:"
; F15C2B flags=0x07 len=5
	.byte	0x07, 0x05, 0x80, 0x11, 0x10
; F15C30 flags=0x07 len=5
	.byte	0x07, 0x05, 0xa7, 0x11, 0x11
; F15C35 flags=0x07 len=17
	.byte	0x07, 0x11, 0x0e, 0x17
	.ascii	"RELEASE TIME:"
; F15C46 flags=0x07 len=18
	.byte	0x07, 0x12, 0x22, 0x17
	.ascii	"VIBRAT0 SPEED:"
; F15C58 flags=0x07 len=5
	.byte	0x07, 0x05, 0x98, 0x17, 0x10
; F15C5D flags=0x07 len=5
	.byte	0x07, 0x05, 0xbf, 0x17, 0x11
; F15C62 flags=0x07 len=19
	.byte	0x07, 0x13, 0x36, 0x1c
	.ascii	"DIGITAL EFFECT:"
; F15C75 flags=0x07 len=18
	.byte	0x07, 0x12, 0x62, 0x1d
	.ascii	"VIBRAT0 DELAY:"
; F15C87 flags=0x07 len=5
	.byte	0x07, 0x05, 0xb0, 0x1d, 0x10
; F15C8C flags=0x07 len=5
	.byte	0x07, 0x05, 0xd7, 0x1d, 0x11
; F15C91 flags=0x07 len=5
	.byte	0x07, 0x05, 0xd1, 0x21, 0x8d
; F15C96 flags=0x06 len=9
	.byte	0x06, 0x09, 0x14
	.ascii	"#VALUE"
; F15C9F flags=0x07 len=5
	.byte	0x07, 0x05, 0x61, 0x23, 0x8e
; F15CA4 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44, 0x00, 0x10, 0x00
; F15CAE flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x1e, 0x00, 0x3d, 0x00, 0x33, 0x00
; F15CB8 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0d, 0x00, 0x20, 0x00, 0x3b, 0x00, 0x31, 0x00
; F15CC2 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0x39, 0x00, 0x34, 0x01, 0x59, 0x00
; F15CCC flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x3a, 0x00, 0x9c, 0x00, 0x59, 0x00
; F15CD6 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x61, 0x00, 0x9c, 0x00, 0x80, 0x00
; F15CE0 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0x61, 0x00, 0x34, 0x01, 0x80, 0x00
; F15CEA flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0x89, 0x00, 0x9c, 0x00, 0xa8, 0x00
; F15CF4 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0x89, 0x00, 0x34, 0x01, 0xa8, 0x00
; F15CFE flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0b, 0x00, 0xb2, 0x00, 0x9c, 0x00, 0xd1, 0x00
; F15D08 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xa3, 0x00, 0xb2, 0x00, 0x34, 0x01, 0xd1, 0x00
; F15D12 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x7d, 0x00, 0xda, 0x00, 0x9a, 0x00, 0xec, 0x00
; F15D1C flags=0x01 len=10
	.byte	0x01, 0x0a, 0x7d, 0x00, 0xe3, 0x00, 0x9a, 0x00, 0xe3, 0x00
; static record list (83 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF15FF2
; evidence: SeMenuTitle_DrawStaticScreen_Skip+0x2B (0xF0F56E)
SeScreenData_0x5120:
; F15D26 flags=0x1c len=14
	.byte	0x1c, 0x0e, 0x70, 0x00, 0x09, 0x00
	.ascii	"USER KIT"
; F15D34 flags=0x17 len=16
	.byte	0x17, 0x10, 0x06, 0x00, 0x07, 0x00
	.ascii	"SOUND EDIT"
; F15D44 flags=0x17 len=7
	.byte	0x17, 0x07, 0x36, 0x01, 0x1f, 0x00, 0x91
; F15D4B flags=0x07 len=5
	.byte	0x07, 0x05, 0x4c, 0x05, 0x8d
; F15D50 flags=0x07 len=5
	.byte	0x07, 0x05, 0x9f, 0x05, 0xa9
; F15D55 flags=0x1c len=7
	.byte	0x1c, 0x07, 0x5e, 0x00, 0x35, 0x00, 0x3a
; F15D5C flags=0x17 len=11
	.byte	0x17, 0x0b, 0x15, 0x01, 0x38, 0x00
	.ascii	"SOUND"
; F15D67 flags=0x17 len=7
	.byte	0x17, 0x07, 0x36, 0x01, 0x46, 0x00, 0x91
; F15D6E flags=0x07 len=5
	.byte	0x07, 0x05, 0x8c, 0x0b, 0x8e
; F15D73 flags=0x07 len=5
	.byte	0x07, 0x05, 0xb7, 0x0b, 0xa9
; F15D78 flags=0x17 len=17
	.byte	0x17, 0x11, 0x47, 0x00, 0x64, 0x00
	.ascii	"TONE SELECT"
; F15D89 flags=0x17 len=11
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15D8A-0xF15DA3 (25 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=60% dist=14 near SeScreenData_0x5120+100
	.byte	0x17, 0x0b, 0xa2, 0x00, 0x64, 0x00
	.ascii	"LEVEL"
; F15D94 flags=0x17 len=9
	.byte	0x17, 0x09, 0xc7, 0x00, 0x64, 0x00, 0x4b, 0x45, 0x59
; F15D9D flags=0x17 len=10
	.byte	0x17, 0x0a, 0xe1, 0x00, 0x64, 0x00
	.ascii	"TUNE"
; F15DA7 flags=0x17 len=9
	.byte	0x17, 0x09, 0x02, 0x01, 0x64, 0x00, 0x50, 0x41, 0x4e
; F15DB0 flags=0x17 len=9
	.byte	0x17, 0x09, 0x1d, 0x01, 0x64, 0x00, 0x52, 0x45, 0x56
; F15DB9 flags=0x06 len=5
	.byte	0x06, 0x05, 0xd0, 0x11, 0x10
; F15DBE flags=0x17 len=7
	.byte	0x17, 0x07, 0x44, 0x00, 0x76, 0x00, 0x2e
; F15DC5 flags=0x17 len=7
	.byte	0x17, 0x07, 0x43, 0x00, 0x7b, 0x00, 0x91
; F15DCC flags=0x17 len=7
	.byte	0x17, 0x07, 0x44, 0x00, 0x94, 0x00, 0x2e
; F15DD3 flags=0x06 len=5
	.byte	0x06, 0x05, 0xe8, 0x17, 0x10
; F15DD8 flags=0x17 len=7
	.byte	0x17, 0x07, 0x43, 0x00, 0x99, 0x00, 0x91
; F15DDF flags=0x06 len=15
	.byte	0x06, 0x0f, 0x3a, 0x1d
	.ascii	"NOTE SELECT"
; F15DEE flags=0x06 len=15
	.byte	0x06, 0x0f, 0x53, 0x1d
	.ascii	"DETAIL EDIT"
; F15DFD flags=0x06 len=5
	.byte	0x06, 0x05, 0xb0, 0x1d, 0x10
; F15E02 flags=0x06 len=5
	.byte	0x06, 0x05, 0xd7, 0x1d, 0x11
; F15E07 flags=0x17 len=12
	.byte	0x17, 0x0c, 0x00, 0x00, 0xd1, 0x00
	.ascii	"ON/OFF"
; F15E13 flags=0x17 len=11
	.byte	0x17, 0x0b, 0x2d, 0x00, 0xd1, 0x00
	.ascii	"GROUP"
; F15E1E flags=0x17 len=10
	.byte	0x17, 0x0a, 0x58, 0x00, 0xd1, 0x00
	.ascii	"TONE"
; F15E28 flags=0x17 len=11
	.byte	0x17, 0x0b, 0x7d, 0x00, 0xd1, 0x00
	.ascii	"LEVEL"
; F15E33 flags=0x17 len=9
	.byte	0x17, 0x09, 0xaa, 0x00, 0xd1, 0x00, 0x4b, 0x45, 0x59
; F15E3C flags=0x17 len=10
	.byte	0x17, 0x0a, 0xcf, 0x00, 0xd1, 0x00
	.ascii	"TUNE"
; F15E46 flags=0x17 len=9
	.byte	0x17, 0x09, 0xfa, 0x00, 0xd1, 0x00, 0x50, 0x41, 0x4e
; F15E4F flags=0x17 len=9
	.byte	0x17, 0x09, 0x23, 0x01, 0xd1, 0x00, 0x52, 0x45, 0x56
; F15E58 flags=0x06 len=5
	.byte	0x06, 0x05, 0x12, 0x22, 0x8d
; F15E5D flags=0x06 len=5
	.byte	0x06, 0x05, 0x17, 0x22, 0x8d
; F15E62 flags=0x06 len=5
	.byte	0x06, 0x05, 0x1c, 0x22, 0x8d
; F15E67 flags=0x06 len=5
	.byte	0x06, 0x05, 0x21, 0x22, 0x8d
; F15E6C flags=0x06 len=5
	.byte	0x06, 0x05, 0x26, 0x22, 0x8d
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15E71-0xF15E84 (19 B), unreached CODE-territory, was disassembled as 9 plausible-but-dead instruction lines; per=71% dist=9 near SeScreenData_0x5120+331
; F15E71 flags=0x06 len=5
	.byte	0x06, 0x05, 0x2b, 0x22, 0x8d
; F15E76 flags=0x06 len=5
	.byte	0x06, 0x05, 0x30, 0x22, 0x8d
; F15E7B flags=0x06 len=5
	.byte	0x06, 0x05, 0x35, 0x22, 0x8d
; F15E80 flags=0x06 len=5
	.byte	0x06, 0x05, 0xa2, 0x23, 0x8e
; F15E85 flags=0x06 len=5
	.byte	0x06, 0x05, 0xa7, 0x23, 0x8e
; F15E8A flags=0x06 len=5
	.byte	0x06, 0x05, 0xac, 0x23, 0x8e
; F15E8F flags=0x06 len=5
	.byte	0x06, 0x05, 0xb1, 0x23, 0x8e
; F15E94 flags=0x06 len=5
	.byte	0x06, 0x05, 0xb6, 0x23, 0x8e
; F15E99 flags=0x06 len=5
	.byte	0x06, 0x05, 0xbb, 0x23, 0x8e
; F15E9E flags=0x06 len=5
	.byte	0x06, 0x05, 0xc0, 0x23, 0x8e
; F15EA3 flags=0x06 len=5
	.byte	0x06, 0x05, 0xc5, 0x23, 0x8e
; F15EA8 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44, 0x00, 0x10, 0x00
; F15EB2 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x12, 0x01, 0x1e, 0x00, 0x35, 0x01, 0x31, 0x00
; F15EBC flags=0x09 len=10
	.byte	0x09, 0x0a, 0x14, 0x01, 0x20, 0x00, 0x33, 0x01, 0x2f, 0x00
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15EC9-0xF15EDD (20 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=60% dist=11 near SeScreenData_0x5120+419
; F15EC6 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x37, 0x00, 0x2e, 0x00, 0xfd, 0x00, 0x49, 0x00
; F15ED0 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x39, 0x00, 0x30, 0x00, 0xfb, 0x00, 0x47, 0x00
; F15EDA flags=0x09 len=10
	.byte	0x09, 0x0a, 0x12, 0x01, 0x45, 0x00, 0x35, 0x01, 0x58, 0x00
; F15EE4 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x14, 0x01, 0x47, 0x00, 0x33, 0x01, 0x56, 0x00
; F15EEE flags=0x22 len=10
	.byte	0x22, 0x0a, 0x0b, 0x00, 0x5e, 0x00, 0x35, 0x01, 0xaa, 0x00
; F15EF8 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0a, 0x00, 0xb5, 0x00, 0x6e, 0x00, 0xca, 0x00
; F15F02 flags=0x09 len=10
	.byte	0x09, 0x0a, 0x0c, 0x00, 0xb7, 0x00, 0x6c, 0x00, 0xc8, 0x00
; F15F0C flags=0x09 len=10
	.byte	0x09, 0x0a, 0xd2, 0x00, 0xb5, 0x00, 0x35, 0x01, 0xca, 0x00
; F15F16 flags=0x09 len=10
	.byte	0x09, 0x0a, 0xd4, 0x00, 0xb7, 0x00, 0x33, 0x01, 0xc8, 0x00
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15F25-0xF15F3C (23 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=10 near SeScreenData_0x5120+511
; F15F20 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x09, 0x00, 0xda, 0x00, 0x1e, 0x00, 0xee, 0x00
; F15F2A flags=0x22 len=10
	.byte	0x22, 0x0a, 0x31, 0x00, 0xda, 0x00, 0x46, 0x00, 0xee, 0x00
; F15F34 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x59, 0x00, 0xda, 0x00, 0x6e, 0x00, 0xee, 0x00
; F15F3E flags=0x22 len=10
	.byte	0x22, 0x0a, 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee, 0x00
; F15F48 flags=0x22 len=10
	.byte	0x22, 0x0a, 0xa9, 0x00, 0xda, 0x00, 0xbe, 0x00, 0xee, 0x00
; F15F52 flags=0x22 len=10
	.byte	0x22, 0x0a, 0xd1, 0x00, 0xda, 0x00, 0xe6, 0x00, 0xee, 0x00
; F15F5C flags=0x22 len=10
	.byte	0x22, 0x0a, 0xf9, 0x00, 0xda, 0x00, 0x0e, 0x01, 0xee, 0x00
; F15F66 flags=0x22 len=10
	.byte	0x22, 0x0a, 0x21, 0x01, 0xda, 0x00, 0x36, 0x01, 0xee, 0x00
; F15F70 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x6f, 0x00, 0x35, 0x01, 0x6f, 0x00
; F15F7A flags=0x01 len=10
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x8c, 0x00, 0x19, 0x01, 0x8c, 0x00
; F15F84 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x09, 0x00, 0xe4, 0x00, 0x1e, 0x00, 0xe4, 0x00
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF15F8F-0xF15FA0 (17 B), unreached CODE-territory, was disassembled as 6 plausible-but-dead instruction lines; per=71% dist=8 near SeScreenData_0x5120+617
; F15F8E flags=0x01 len=10
	.byte	0x01, 0x0a, 0x31, 0x00, 0xe4, 0x00, 0x46, 0x00, 0xe4, 0x00
; F15F98 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x59, 0x00, 0xe4, 0x00, 0x6e, 0x00, 0xe4, 0x00
; F15FA2 flags=0x01 len=10
	.byte	0x01, 0x0a, 0x81, 0x00, 0xe4, 0x00, 0x96, 0x00, 0xe4, 0x00
; F15FAC flags=0x01 len=10
	.byte	0x01, 0x0a, 0xa9, 0x00, 0xe4, 0x00, 0xbe, 0x00, 0xe4, 0x00
; F15FB6 flags=0x01 len=10
	.byte	0x01, 0x0a, 0xd1, 0x00, 0xe4, 0x00, 0xe6, 0x00, 0xe4, 0x00
; F15FC0 flags=0x01 len=10
	.byte	0x01, 0x0a, 0xf9, 0x00, 0xe4, 0x00, 0x0e, 0x01, 0xe4, 0x00
; F15FCA flags=0x01 len=10
	.byte	0x01, 0x0a, 0x21, 0x01, 0xe4, 0x00, 0x36, 0x01, 0xe4, 0x00
; F15FD4 flags=0x02 len=10
	.byte	0x02, 0x0a, 0x38, 0x00, 0x5e, 0x00, 0x38, 0x00, 0xaa, 0x00
; F15FDE flags=0x02 len=10
	.byte	0x02, 0x0a, 0x9d, 0x00, 0x5e, 0x00, 0x9d, 0x00, 0xaa, 0x00
; F15FE8 flags=0x02 len=10
	.byte	0x02, 0x0a, 0x19, 0x01, 0x5e, 0x00, 0x19, 0x01, 0xaa, 0x00
; static record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF16006
; evidence: SeMenuTitle_DrawStaticScreen_Skip+0x55 (0xF0F598), SeMenu_PresetManager_Init+0x75 (0xF0F67D)
SeScreenData_0x53EC:
; F15FF2 flags=0x1b len=10
	.byte	0x1b, 0x0a, 0x19, 0x01, 0x71, 0x00, 0x33, 0x01, 0xa8, 0x00
; F15FFC flags=0x05 len=10
	.byte	0x05, 0x0a, 0x19, 0x01, 0x71, 0x00, 0x33, 0x01, 0xa8, 0x00
; bound record list (16 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF160F1
; evidence: SeMenuTitle_DrawStaticScreen_Skip+0x3D (0xF0F580), SeMenu_PresetManager_Init+0x85 (0xF0F68D)
; single bound record (op 0x07, 17 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x5400:
; F16006 flags=0x07 len=17
	.byte	0x07, 0x11, 0x61, 0x06, 0x7f, 0x00, 0x1c
	.long	SeMenu_NameEditor_HighlightChar_Records2 + 0xc
	.byte	0x03, 0x00, 0x3d, 0x00, 0x35, 0x00
; F16017 flags=0x07 len=17
	.byte	0x07, 0x11, 0x00, 0x00, 0x00, 0x00, 0x1c
	.long	0x00020bf3
	.byte	0x0d, 0x00, 0x69, 0x00, 0x35, 0x00
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF1604A
; evidence: SeMenu_PresetManager_Init+0xA5 (0xF0F6AD)
; single bound record (op 0x07, 17 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x5422:
; F16028 flags=0x07 len=17
	.byte	0x07, 0x11, 0x6f, 0x06, 0x1f, 0x00, 0x17
	.long	SeScreenData_0x1F80 + 0x149
	.byte	0x02, 0x00, 0x3d, 0x00, 0x7a, 0x00
; F16039 flags=0x07 len=17
	.byte	0x07, 0x11, 0x00, 0x00, 0x00, 0x00, 0x17
	.long	0x00020c03
	.byte	0x0d, 0x00, 0x49, 0x00, 0x7a, 0x00
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x5444:
; F1604A flags=0x09 len=12
	.byte	0x09, 0x0c, 0x63, 0x06, 0x7f, 0x00, 0x17, 0xa5, 0x00, 0x7a, 0x00, 0x03
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x5450:
; F16056 flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x65, 0x06, 0xff, 0x00, 0x17, 0xc3, 0x00, 0x7a, 0x00, 0x02, 0x00
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x545D:
; F16063 flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x67, 0x06, 0xff, 0x00, 0x17, 0xe1, 0x00, 0x7a, 0x00, 0x02, 0x00
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF16092
; evidence: SeMenu_PresetManager_Init_Code_Skip+0x10 (0xF0F6C3)
; single bound record (op 0x07, 17 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x546A:
; F16070 flags=0x07 len=17
	.byte	0x07, 0x11, 0x70, 0x06, 0x1f, 0x00, 0x17
	.long	SeScreenData_0x1F80 + 0x149
	.byte	0x02, 0x00, 0x3d, 0x00, 0x98, 0x00
; F16081 flags=0x07 len=17
	.byte	0x07, 0x11, 0x00, 0x00, 0x00, 0x00, 0x17
	.long	0x00020c13
	.byte	0x0d, 0x00, 0x49, 0x00, 0x98, 0x00
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x548C:
; F16092 flags=0x09 len=12
	.byte	0x09, 0x0c, 0x64, 0x06, 0x7f, 0x00, 0x17, 0xa5, 0x00, 0x98, 0x00, 0x03
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x5498:
; F1609E flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x66, 0x06, 0xff, 0x00, 0x17, 0xc3, 0x00, 0x98, 0x00, 0x02, 0x00
; single bound record (op 0x0B, 13 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x54A5:
; F160AB flags=0x0b len=13
	.byte	0x0b, 0x0d, 0x68, 0x06, 0xff, 0x00, 0x17, 0xe1, 0x00, 0x98, 0x00, 0x02, 0x00
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x54B2:
; F160B8 flags=0x09 len=12
	.byte	0x09, 0x0c, 0x6b, 0x06, 0x7f, 0x00, 0x17, 0x1c, 0x01, 0x89, 0x00, 0x03
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF160E6
; evidence: SeMenu_PresetManager_Init+0x3B (0xF0F643)
SeMenu_PresetManager_Init_Records:
; F160C4 flags=0x07 len=17
	.byte	0x07, 0x11, 0x6c, 0x06, 0x03, 0x00, 0x17
	.long	SeScreenData_0x39BE + 0x94
	.byte	0x03, 0x00, 0x03, 0x01, 0x7a, 0x00
; F160D5 flags=0x07 len=17
	.byte	0x07, 0x11, 0x6c, 0x06, 0x0c, 0x02, 0x17
	.long	SeScreenData_0x39BE + 0x94
	.byte	0x03, 0x00, 0x03, 0x01, 0x98, 0x00
; single bound record (op 0x03, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeMenu_PresetManager_Init_Records2:
; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF160F0-0xF16106 (22 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=80% dist=11 near SeMenu_PresetManager_Init_Records2+10
; F160E6 flags=0x03 len=11
	.byte	0x03, 0x0b, 0x60, 0x06, 0x03, 0x00, 0x05
	.long	SeScreenData_0x5503
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x54EB:
; F160F1 flags=0x09 len=12
	.byte	0x09, 0x0c, 0x6d, 0x06, 0x7f, 0x00, 0x17, 0x09, 0x01, 0x7a, 0x00, 0x02
; single bound record (op 0x09, 12 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1612B
SeScreenData_0x54F7:
; F160FD flags=0x09 len=12
	.byte	0x09, 0x0c, 0x6e, 0x06, 0x7f, 0x00, 0x17, 0x09, 0x01, 0x98, 0x00, 0x02
; table of 3 boxes {u16 x1, y1, x2, y2}, indexed by the masked value of a bound op03/04/08 record (its +7 pointer)
; evidence: bound op03 record 0xF160E6
SeScreenData_0x5503:
; F16109..F1612F  the length byte at F16109 is 0, so the [flags][len] framing above does NOT continue here.
; HYPOTHESIS ONLY (it closes exactly on the u32 below, but is not otherwise corroborated):
; three 8-byte entries, then one len-10 record. Left as untyped .byte rather than guessed at.
; F16109
; F16111
; F16119
	.short	13, 113, 280, 138
	.short	13, 113, 280, 138
	.short	13, 141, 280, 168
; static record list (1 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF1612B
; evidence: SeMenu_PresetManager_Init+0x56 (0xF0F65E)
SeMenu_PresetManager_Init_Records3:
; F16121
	.byte	0x1b, 0x0a, 0x0d, 0x00, 0x71, 0x00, 0x18, 0x01, 0xa8, 0x00
; table of 17 pointers to bound records; the code loads it into XIY and SeGfx_DrawIndexedBoundRecord draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_WaveformSelect_Apply_Helper3+0x1E (0xF0F603), SeMenu_PresetManager_Init+0x61 (0xF0F669), SeMenu_PresetManager_Init_Code_Skip2+0xB (0xF0F6D4)
SeScreenData_0x5525:
; F1612B -- a u32 pointer to the record at F160E6; DrumDetailEdit_Menu_Table's label may be one entry late
	.byte	0xe6, 0x60, 0xf1, 0x00
DrumDetailEdit_Menu_Table:
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
; static record list (20 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF16239
; evidence: SeMenu_PresetManager_Load+0x17 (0xF0F6F0)
SeMenu_PresetManager_Load_Records:
; se_setup_editor_full: 266 B at 0xF1616F, compiled from audio/sound_editor_screens/se_setup_editor_full.c
	.incbin "includes/generated/se_setup_editor_full.bin", 0x0, 0xCA
; SeDrumKit_TouchCurvePageRecords: Sound-editor screen records (compiled se_setup_editor_full.c from offset 202): two
;   "TOUCH" "CURVE" captions (y 62 and 209), two vertical-bar and two down-arrow marks, then box/line records up to
;   SeScreenData_0x56CD -- drawn in drum-kit mode (0x6AE = 1) for SE screen code 0x2B; it also ends the DRUM DETAIL
;   EDIT menu list that starts at SeMenu_PresetManager_Load_Records. Basis: readers + bytes.
SeDrumKit_TouchCurvePageRecords:	.incbin "includes/generated/se_setup_editor_full.bin", 0xCA, 0x40
; static record list (17 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF162D3
; evidence: SeMenu_CompareAndApply_Check+0xA (0xF0FB77)
; F16279 -- remainder of the source line the descriptor ends inside
	.byte	0x22, 0x0a, 0x0b, 0x00, 0x38, 0x00, 0x9c, 0x00, 0x8a, 0x00
	.byte	0x22, 0x0a, 0x59, 0x00, 0xda, 0x00, 0x6e, 0x00, 0xee, 0x00
	.byte	0x22, 0x0a, 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee, 0x00
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x4a, 0x00, 0x9c, 0x00, 0x4a, 0x00
	.byte	0x01, 0x0a, 0x0b, 0x00, 0x6a, 0x00, 0x9c, 0x00, 0x6a, 0x00
	.byte	0x01, 0x0a, 0x59, 0x00, 0xe4, 0x00, 0x6e, 0x00, 0xe4, 0x00
	.byte	0x01, 0x0a, 0x81, 0x00, 0xe4, 0x00, 0x96, 0x00, 0xe4, 0x00
	.byte	0x02, 0x0a, 0x2e, 0x00, 0x38, 0x00, 0x2e, 0x00, 0x8a, 0x00
	.byte	0x05, 0x0a, 0x16, 0x01, 0x43, 0x00, 0x32, 0x01, 0x5c, 0x00
; static record list (23 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF163AA
; evidence: SeMenu_Utility_CopyBlock+0x4B (0xF0FCA1)
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
; bound record list (5 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF163E1
; evidence: SeMenu_CompareAndApply_Apply+0x10 (0xF0FBB4)
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163E1
SeScreenData_0x57A4:
; se_apply_confirm: 55 bytes (5 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_apply_confirm.c)
	.incbin "includes/generated/se_apply_confirm.bin"
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163E1
	.set	SeApplyConfirm_ParamR2Rec, SeScreenData_0x57A4 + 0xb	; se_apply_confirm.setup5_1 (id 0x0662, DRAM param R2): sound_editor_screens/se_apply_confirm.c
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163E1
	.set	SeApplyConfirm_FlaggedR1Rec, SeScreenData_0x57A4 + 0x16	; se_apply_confirm.setup5_2 (id 0x0663, flagged R1): sound_editor_screens/se_apply_confirm.c
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163E1
	.set	SeApplyConfirm_FlaggedR2Rec, SeScreenData_0x57A4 + 0x21	; se_apply_confirm.setup5_3 (id 0x0664, flagged R2): sound_editor_screens/se_apply_confirm.c
; single bound record (op 0x03, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF163E1
	.set	SeApplyConfirm_CursorRec, SeScreenData_0x57A4 + 0x2c	; se_apply_confirm.setup_0 (id 0x065d, cursor coords): sound_editor_screens/se_apply_confirm.c
; table of 5 pointers to bound records; the code loads it into XIY and SeGfx_DrawIndexedBoundRecord draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_DataBlock_01+0x6A (0xF10408)
SeScreenData_0x57DB:
	.long	SeApplyConfirm_CursorRec
	.long	SeScreenData_0x57A4
	.long	SeApplyConfirm_ParamR2Rec
	.long	SeApplyConfirm_FlaggedR1Rec
	.long	SeApplyConfirm_FlaggedR2Rec
; static record list (1 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF163FF
; evidence: SeMenu_DataBlock_01+0x4B (0xF103E9)
SeMenu_DataBlock_01_Records3:
	.byte	0x1b, 0x0a, 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x88, 0x00
; table of 3 boxes {u16 x1, y1, x2, y2}, indexed by the masked value of a bound op03/04/08 record (its +7 pointer)
; evidence: bound op03 record 0xF163D6
SeMenu_DataBlock_01_Records4:
	.short	13, 76, 154, 104
	.short	13, 76, 154, 104
	.short	13, 108, 154, 136
; bound record list (6 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF16459
; evidence: SeMenu_Utility_CopyBlock+0x7E (0xF0FCD4)
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeMenu_Utility_CopyBlock_Records2:
	.byte	0x02, 0x0f, 0x60, 0x06, 0x20, 0x05, 0x20
	.long	SeMenu_DrawPartSelector_Records3 + 0x53
	.byte	0x03, 0x00, 0x70, 0x1d
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeScreenData_0x5820:
	.byte	0x00, 0x0a, 0x61, 0x06, 0x7f, 0x00, 0x20, 0x61, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeScreenData_0x582A:
	.byte	0x00, 0x0a, 0x62, 0x06, 0x7f, 0x00, 0x20, 0x65, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeScreenData_0x5834:
	.byte	0x00, 0x0a, 0x63, 0x06, 0x7f, 0x00, 0x20, 0x6a, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeScreenData_0x583E:
	.byte	0x00, 0x0a, 0x64, 0x06, 0x7f, 0x00, 0x20, 0x6f, 0x22, 0x03
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeScreenData_0x5848:
	.byte	0x05, 0x0b, 0x67, 0x06, 0xff, 0x00, 0x20, 0x84, 0x22, 0x02, 0x00
; table of 8 pointers to bound records; the code loads it into XIY and SeGfx_DrawIndexedBoundRecord draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_DataBlock_03+0x1D (0xF1043A), SeMenu_DataBlock_03+0x32 (0xF1044F)
SeScreenData_0x5853:
	.long	SeMenu_Utility_CopyBlock_Records2
	.long	SeScreenData_0x5820
	.long	SeScreenData_0x582A
	.long	SeScreenData_0x5834
	.long	SeScreenData_0x583E
	.long	SeMenu_DrawEnvKeyOffFields_Records2
	.long	SeScreenData_0x587D
	.long	SeScreenData_0x5848
; bound record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF1648D
; evidence: SeMenu_DrawEnvKeyOffFields+0x19 (0xF0FCFA)
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeMenu_DrawEnvKeyOffFields_Records2:
	.byte	0x00, 0x0a, 0x65, 0x06, 0x7f, 0x00, 0x20, 0x74, 0x22, 0x03
; single bound record (op 0x00, 10 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF16459
SeScreenData_0x587D:
	.byte	0x00, 0x0a, 0x66, 0x06, 0x7f, 0x00, 0x20, 0x7a, 0x22, 0x03
; static record list (2 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF1649B
; evidence: SeMenu_DrawEnvKeyOffFields+0x3D (0xF0FD1E)
SeMenu_DrawEnvKeyOffFields_Records3:
	.byte	0x20, 0x07, 0x74, 0x22, 0x20, 0x2d, 0x2d
	.byte	0x20, 0x07, 0x7a, 0x22, 0x20, 0x2d, 0x2d
; bound record list (8 records {u8 op, u8 len, payload}), read by GraphicsRender_Start; ends 0xF164F7
; evidence: SeMenu_NameEdit_DataBlock2+0x18 (0xF100E8)
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x5895:
	.byte	0x05, 0x0b, 0x61, 0x06, 0xff, 0x00, 0x20, 0xb0, 0x0a, 0x02, 0x00
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58A0:
	.byte	0x02, 0x0f, 0x62, 0x06, 0x1f, 0x00, 0x20
	.long	SeMenu_NameEdit_SetupPath_Records2
	.byte	0x03, 0x00, 0xc8, 0x10
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58AF:
	.byte	0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0x30, 0x17, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58BA:
	.byte	0x05, 0x0b, 0x64, 0x06, 0xff, 0x00, 0x20, 0x70, 0x1d, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58C5:
	.byte	0x05, 0x0b, 0x69, 0x06, 0x0f, 0x00, 0x20, 0x9b, 0x0a, 0x02, 0x08
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58D0:
	.byte	0x05, 0x0b, 0x66, 0x06, 0xff, 0x00, 0x20, 0xb3, 0x10, 0x02, 0x00
; single bound record (op 0x05, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58DB:
	.byte	0x05, 0x0b, 0x67, 0x06, 0xff, 0x00, 0x20, 0x1b, 0x17, 0x02, 0x00
; single bound record (op 0x03, 11 B), read by GraphicsRender_Start
; evidence: recptrs table 0xF1652F
SeScreenData_0x58E6:
	.byte	0x03, 0x0b, 0x60, 0x06, 0x0f, 0x00, 0x05
	.long	SeScreenData_0x5951
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: SeMenu_NameEdit_HandleInput (0xF10141)
SeScreenData_0x58F1:
	.byte	0x02, 0x0f, 0x6a, 0x06, 0x0f, 0x00, 0x20
	.long	SeScreenData_0x4EFB
	.byte	0x0d, 0x00, 0x8e, 0x1e
; single bound record (op 0x02, 15 B), read by GraphicsRender_Start
; evidence: SeMenu_NameEdit_HandleInput (0xF10141)
SeMenu_NameEdit_CheckBit7_Records:
	.byte	0x02, 0x0f, 0x6a, 0x06, 0x80, 0x07, 0x20
	.long	SeScreenData_0x590F
	.byte	0x0d, 0x00, 0x8e, 0x1e
; fixed-width string table, 13 chars per entry, 26 B: the text choices of a bound op02/op07 record (its +7 pointer; +11 = chars per entry)
; evidence: bound op02 record 0xF16506
SeScreenData_0x590F:
	.ascii	"OFF          "
	.ascii	"OFF          "
; table of 10 pointers to bound records; the code loads it into XIY and SeGfx_DrawIndexedBoundRecord draws entry WA (XIY = (XIY + 4*WA))
; evidence: SeMenu_NameEdit_DefaultPath+0xB (0xF10121)
; (name EffectParam_Edit_Table kept: other files use it; the object is ScreenData, see above)
EffectParam_Edit_Table:
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
; evidence: bound op03 record 0xF164EC
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
; static record list (1 records {u8 op, u8 len, payload}), read by GraphicsRender_ProcessEntries; ends 0xF165A9
; evidence: SeMenu_NameEdit_SetupPath+0x10 (0xF10110)
SeMenu_NameEdit_SetupPath_Records:
; se_setup_sel4: 10 B at 0xF1659F, compiled from audio/sound_editor_screens/se_setup_sel4.c
	.incbin "includes/generated/se_setup_sel4.bin"
; fixed-width string table, 3 chars per entry, 66 B: the text choices of a bound op02/op07 record (its +7 pointer; +11 = chars per entry)
; evidence: bound op02 record 0xF164A6
SeMenu_NameEdit_SetupPath_Records2:
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
	lda xsp, (xsp - 14)

	RegObjTable NAKA_CLASS_Class, ClassProc, Naka_ClassCount_16B, ToneGen_ParamTable_0x53D, 0x16b
	RegObjTable NAKA_CLASS_ResEvent, ResEventProc, Naka_ResEventCount_1CB, ToneGen_ParamTable_0x557, 0x1cb
	RegObjTable NAKA_CLASS_ResMethod, ResMethodProc, Naka_ResMethodCount_1EB, ToneGen_ParamTable_0x55D, 0x1eb
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x12, Naka_ApFuncTable_12B, 0x12b
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x12, Naka_ApFuncNameTable_42B, 0x42b
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, ToneGen_ParamTable_0x563, 0x10b
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, ToneGen_ParamTable_0x567, 0x40b
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x0, Naka_MainFunctionTable_14B, 0x14b
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x0, Naka_MainFunctionTable_44B, 0x44b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1de, NAKA_UIObjectTable, 0xfd
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1de, Naka_ResNameTable_3FD, 0x3fd

	RegTitle 0xb, InitializeNaka_Str_TT_FDMSP, 0xfd, NAKA_APFUNC_DefaultFunction, NAKA_VIEW_ftdemo01
	lda xsp, (xsp + 14)
	ret

NAKA_InitDataBlock:
	ret
; FtLangText01: Naka ApFunction 0x12B0000, named by entry 0 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable (6 language pointers, English "Bass Port
;   Speaker"), else XHL = 0
FtLangText01:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText01_Skip
	lda	xhl, (NAKA_InitDataBlock_PtrTable:24)
	ret
FtLangText01_Skip:
	ld	xhl, 0:i3
	ret
; FtLangText01S: Naka ApFunction 0x12B0001, named by entry 1 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = FDemo_BassPortSpanishHeading_Texts (6 language pointers, only Spanish
;   filled: "Altavoz con port<0xF3>n para bajos"), else XHL = 0
FtLangText01S:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText01S_Skip2
	lda	xhl, (FDemo_BassPortSpanishHeading_Texts:24)
	ret
FtLangText01S_Skip2:
	ld	xhl, 0:i3
	ret
; FtLangText02: Naka ApFunction 0x12B0002, named by entry 2 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_3 (6 language pointers, English "The
;   KN5000's Special Woofer & Bass Port produce a Rich & Powerful sound!"), else XHL = 0
FtLangText02:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText02_Skip3
	lda	xhl, (NAKA_InitDataBlock_PtrTable_3:24)
	ret
FtLangText02_Skip3:
	ld	xhl, 0:i3
	ret
; FtLangText03: Naka ApFunction 0x12B0003, named by entry 3 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_4 (6 language pointers, English "Huge
;   Styles"), else XHL = 0
FtLangText03:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText03_Skip4
	lda	xhl, (NAKA_InitDataBlock_PtrTable_4:24)
	ret
FtLangText03_Skip4:
	ld	xhl, 0:i3
	ret
; FtLangText04: Naka ApFunction 0x12B0004, named by entry 4 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_5 (6 language pointers, English "Explore
;   1000 Musical Styles with the Music Stylist."), else XHL = 0
FtLangText04:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText04_Skip5
	lda	xhl, (NAKA_InitDataBlock_PtrTable_5:24)
	ret
FtLangText04_Skip5:
	ld	xhl, 0:i3
	ret
; FtLangText05: Naka ApFunction 0x12B0005, named by entry 5 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_6 (6 language pointers, English "Add to
;   your enjoyment with a wide range of Technics Software"), else XHL = 0
FtLangText05:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText05_Skip6
	lda	xhl, (NAKA_InitDataBlock_PtrTable_6:24)
	ret
FtLangText05_Skip6:
	ld	xhl, 0:i3
	ret
; FtLangText06: Naka ApFunction 0x12B0006, named by entry 6 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_7 (6 language pointers, English "And
;   convert software from almost any other manufacturer!"), else XHL = 0
FtLangText06:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText06_Skip7
	lda	xhl, (NAKA_InitDataBlock_PtrTable_7:24)
	ret
FtLangText06_Skip7:
	ld	xhl, 0:i3
	ret
; FtLangText07: Naka ApFunction 0x12B0007, named by entry 7 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_8 (6 language pointers, English "Store
;   your favorite software patterns in the Custom Rhythm Group .....permanently!"), else XHL = 0
FtLangText07:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText07_Skip8
	lda	xhl, (NAKA_InitDataBlock_PtrTable_8:24)
	ret
FtLangText07_Skip8:
	ld	xhl, 0:i3
	ret
; FtLangText08: Naka ApFunction 0x12B0008, named by entry 8 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_9 (6 language pointers, English "Accordion
;   Register"), else XHL = 0
FtLangText08:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText08_Skip9
	lda	xhl, (NAKA_InitDataBlock_PtrTable_9:24)
	ret
FtLangText08_Skip9:
	ld	xhl, 0:i3
	ret
; FtLangText09: Naka ApFunction 0x12B0009, named by entry 9 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_10 (6 language pointers, English "A World
;   of Accordion Sounds at your fingertips with the Accordion Register!"), else XHL = 0
FtLangText09:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText09_Skip10
	lda	xhl, (NAKA_InitDataBlock_PtrTable_10:24)
	ret
FtLangText09_Skip10:
	ld	xhl, 0:i3
	ret
; FtLangText10: Naka ApFunction 0x12B000A, named by entry 10 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_11 (6 language pointers, English "Digital
;   Drawbar"), else XHL = 0
FtLangText10:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText10_Skip11
	lda	xhl, (NAKA_InitDataBlock_PtrTable_11:24)
	ret
FtLangText10_Skip11:
	ld	xhl, 0:i3
	ret
; FtLangText11: Naka ApFunction 0x12B000B, named by entry 11 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = FtLangText11_Texts (6 language pointers, English "Classic Organ Sounds
;   with Jazz and Rock Drawbars!"), else XHL = 0
FtLangText11:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText11_Skip12
	lda	xhl, (FtLangText11_Texts:24)
	ret
FtLangText11_Skip12:
	ld	xhl, 0:i3
	ret
; FtLangText12: Naka ApFunction 0x12B000C, named by entry 12 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_13 (6 language pointers, English "Acoustic
;   Illusion"), else XHL = 0
FtLangText12:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText12_Skip13
	lda	xhl, (NAKA_InitDataBlock_PtrTable_13:24)
	ret
FtLangText12_Skip13:
	ld	xhl, 0:i3
	ret
; FtLangText13: Naka ApFunction 0x12B000D, named by entry 13 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_14 (6 language pointers, English "Acoustic
;   Illusion broadens your music to 3-Dimensions!"), else XHL = 0
FtLangText13:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText13_Skip14
	lda	xhl, (NAKA_InitDataBlock_PtrTable_14:24)
	ret
FtLangText13_Skip14:
	ld	xhl, 0:i3
	ret
; FtLangText14: Naka ApFunction 0x12B000E, named by entry 14 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_15 (6 language pointers, English "A host
;   of features to suit any style of performance!"), else XHL = 0
FtLangText14:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText14_Skip15
	lda	xhl, (NAKA_InitDataBlock_PtrTable_15:24)
	ret
FtLangText14_Skip15:
	ld	xhl, 0:i3
	ret
; FtLangText15: Naka ApFunction 0x12B000F, named by entry 15 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = NAKA_InitDataBlock_PtrTable_16 (6 language pointers, English "Huge
;   Styles"), else XHL = 0
FtLangText15:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText15_Skip16
	lda	xhl, (NAKA_InitDataBlock_PtrTable_16:24)
	ret
FtLangText15_Skip16:
	ld	xhl, 0:i3
	ret
; FtLangText16: Naka ApFunction 0x12B0010, named by entry 16 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = FtLangText16_LangStrings (6 language pointers, English "Huge Styles"),
;   else XHL = 0
FtLangText16:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText16_Skip17
	lda	xhl, (FtLangText16_LangStrings:24)
	ret
FtLangText16_Skip17:
	ld	xhl, 0:i3
	ret
; FtLangText17: Naka ApFunction 0x12B0011, named by entry 17 of the ApFunction name slot 0x42B: feature-demo caption
;   text; on EVT_GET_LANGUAGE_PTR returns XHL = FtLangText17_Texts (6 language pointers, English "Huge Styles"), else
;   XHL = 0
FtLangText17:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, FtLangText17_Skip18
	lda	xhl, (FtLangText17_Texts:24)
	ret
FtLangText17_Skip18:
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
	jrl	Flash_StoreBaseAndInitAccPatch_Join5

NoteEvent_LoadSoundGenParams:
	lda xsp, (xsp-364)
	push xiz
	ld xiy, AccPatch_SlotRecordTemplate
	lda xix, (xsp+272)
	ldw bc, 0x30
	ldirw
	ld xiy, NoteEvent_DefaultPatternSlot
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
	ld xiy, MSP_Default_VoiceParamSlot
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
	ld xiy, MSP_Default_ExtParamSlot
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
	ld (FLASH_SECTION_PTR_0:16), xwa
	ld xbc, xwa
	add xbc, 0x19800
	ld (FLASH_SECTION_PTR_1:16), xbc
	ld xbc, xwa
	add xbc, 0x30000
	ld (FLASH_SECTION_PTR_2:16), xbc
	ld xbc, xwa
	add xbc, 0x49800
	ld (FLASH_SECTION_PTR_3:16), xbc
	ld xbc, xwa
	add xbc, 0x60000
	ld (FLASH_SECTION_PTR_4:16), xbc
	ld xbc, xwa
	add xbc, 0x79800
	ld (FLASH_SECTION_PTR_5:16), xbc
	ld xbc, xwa
	add xbc, 0x90000
	ld (FLASH_SECTION_PTR_6:16), xbc
	ld xbc, xwa
	add xbc, 0xb0000
	ld (FLASH_SECTION_PTR_7:16), xbc
	lda xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld (RHYTHM_PATTERN_BUF_PTR:16), xwa
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
	jrl	nc, Flash_InitBytecodeBlock_Skip7
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
	ld	a, (xbc+wa)
	ld (xsp+6), a
	ld xwa, (3186:16)
	ld	(0x39ae:16), xwa
	ldib_erp 251, 0
Flash_InitBytecodeBlock_Loop:
	ld	c, (xsp+6)
	extz	bc
	ldto_berp a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (MSP_Default_ChannelMap:24)
	ld	(0x39ac), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, Flash_InitBytecodeBlock_Loop
	ld	xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x39ae:16), xwa
	ld	xwa, (3186:16)
	ld	(0x39b2:16), xwa
	res	0, (0x35b0:16)
	ldib_erp	251, 0
Flash_InitBytecodeBlock_Loop2:
	ld	e, (xsp+12)
	extz	de
	ldto_berp a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (MSP_Default_ChannelMap:24)
	ld	(0x39ac), (xde+wa)
	ld	a, (xsp+0x6)
	extz	wa
	add	bc, wa
	ld	(0x39ad), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (0x35b0:16)
	extz	wa
	bit	0, wa
	jr	z, Flash_InitBytecodeBlock_Skip3
	ld	(xsp+8), 1
	jr	Flash_InitBytecodeBlock_Join4
Flash_InitBytecodeBlock_Skip3:
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, Flash_InitBytecodeBlock_Loop2
Flash_InitBytecodeBlock_Join4:
	call	AccPatch_CountSlots_Wrapper
	cp	(xsp+0x8), 0
	jrl	nz, Flash_InitBytecodeBlock_Loop3
	lda_d16	xwa, (0x6d4)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip5
	cpw	(xwa+0x2), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip5
	calr	Flash_StoreBaseAndInitAccPatch
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
	lda	xwa, (1850:16)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip4
	cpw	(xwa+0x2), 0xffff
	jrl	z, Flash_InitBytecodeBlock_Entry
Flash_InitBytecodeBlock_Skip4:
	calr	Flash_WriteBackSlotTable
	jrl	Flash_InitBytecodeBlock_Entry
Flash_InitBytecodeBlock_Skip5:
	ld	a, (xsp+10)
	extz	wa
	calr	Flash_SlotUpdateOpsBlock
	ld	wa, hl
	ld	c, (xsp+10)
	extz	bc
	cp	wa, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Skip6
	ld	wa, bc
	calr	Flash_AssignSlotsToBlocks
	ld	a, (xsp+6)
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Sub
	calr	Flash_StoreBaseAndInitAccPatch
	ld	a, (xsp+4)
	extz	wa
	calr	NoteEventBuffer_Store
	ld	a, (xsp+10)
	extz	wa
	calr	Flash_WriteSlotOwnerMap
	calr	Flash_CopyBlocksToSlots
	call	TmFlash_CopyToExtMem
	jrl	Flash_InitBytecodeBlock_Entry
Flash_InitBytecodeBlock_Skip6:
	calr	Flash_InitBytecodeBlock_Helper4
	calr	Flash_InitBytecodeBlock_Helper5
	calr	Flash_InitBytecodeBlock_Helper6
	calr	Flash_InitBytecodeBlock_Helper7
	jrl	Flash_InitBytecodeBlock_Join2
Flash_InitBytecodeBlock_Loop3:
	ld	(xsp+2), 1
	jrl	Flash_InitBytecodeBlock_Join
Flash_InitBytecodeBlock_Skip7:
	calr	DualVoice_ScanAllColumns
	ld	a, (xsp+10)
	extz	wa
	calr	DualVoice_ScanAllColumnsAlt
	ld	xix, (3186:16)
	ld	xiy, (RHYTHM_PATTERN_BUF_PTR:16)
	ldw	bc, 0xb400
	ldirw
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld	a, (xbc+wa)
	ld (xsp+6), a
	ld xwa, (3186:16)
	ld	(0x39ae:16), xwa
	ldib_erp 251, 0
Flash_InitBytecodeBlock_Loop4:
	ld	c, (xsp+10)
	extz	bc
	ldto_berp a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (MSP_Default_ChannelMap:24)
	ld	(0x39ac), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, Flash_InitBytecodeBlock_Loop4
	ld	a, (xsp+12)
	extz	wa
	calr	PartGrid_ColumnDispatch
	ld	(0x39ae:16), xhl
	ld	xwa, (3186:16)
	ld	(0x39b2:16), xwa
	res	0, (0x35b0:16)
	ldib_erp	251, 0
Flash_InitBytecodeBlock_Loop5:
	ld	e, (xsp+6)
	extz	de
	ldto_berp a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (MSP_Default_ChannelMap:24)
	ld	(0x39ac), (xde+wa)
	ld	a, (xsp+0xa)
	extz	wa
	add	bc, wa
	ld	(0x39ad), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (0x35b0:16)
	extz	wa
	bit	0, wa
	jr	z, Flash_InitBytecodeBlock_Skip8
	ld	(xsp+8), 1
	ld	xwa, (0x39b2:16)
	ld	(0x39ae:16), xwa
	ldmm8	0x39ac, 0x39ad
	call	AccPatch_InitFromSlotIndex
	jr	Flash_InitBytecodeBlock_Join5
Flash_InitBytecodeBlock_Skip8:
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, Flash_InitBytecodeBlock_Loop5
Flash_InitBytecodeBlock_Join5:
	cp	(xsp+0x8), 0
	jrl	nz, Flash_InitBytecodeBlock_Loop3
	lda_d16	xwa, (0x6d4)
	cpw	(xwa), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip9
	cpw	(xwa+0x2), 0xffff
	jr	nz, Flash_InitBytecodeBlock_Skip9
	ld	xix, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	xiy, (3186:16)
	ldw	bc, 0xb400
	ldirw
Flash_InitBytecodeBlock_Entry:
	cp	(xsp+0x2), 2
	jr	nz, Flash_InitBytecodeBlock_Join
	ld	(0xc68), (xsp+0xc)
	ld	(0xc6a), (xsp+0xa)
	ld	(0xc6c), (xsp+0x6)
Flash_InitBytecodeBlock_Join:
	call	AccPatch_CountSlots_Wrapper
	ld	l, (xsp+2)
	pop qiz
	lda	xsp, (xsp+12)
	ret
Flash_InitBytecodeBlock_Skip9:
	ld	a, (xsp+10)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper10
	calr	Flash_InitBytecodeBlock_Helper11
Flash_InitBytecodeBlock_Join2:
	ld	(xsp+2), 2
	ld	(0xc68), (xsp+0xc)
	ld	(0xc6a), (xsp+0xa)
	ld	(0xc6c), (xsp+0x6)
	jr	Flash_InitBytecodeBlock_Entry
; CstmCpTtl_ResolvePendingCopy: Settles the custom-rhythm copy (FROM 0x39B6 -> TO 0x39B7) that Flash_InitBytecodeBlock
;   left pending with result 2 -- it saved FROM, TO and the group in 0x0C68 / 0x0C6A / 0x0C6C and the caller opened
;   the memory-full / function-select window: re-runs Flash_InitExtMemAddrs, then with A = 0 (EXECUTE) completes the
;   copy (Flash_InitBytecodeBlock_Helper8 for FROM < 10, Flash_InitBytecodeBlock_Helper9 otherwise, the same split
;   Flash_InitBytecodeBlock makes) and with any other A (ABORT passes 2) copies nothing; returns L = 0. Basis: callers
;   + body -- CstmCpTtl_RecMode2_OnWindowExecute calls it with WA = 0 ("carries out the pending copy"),
;   CstmCpTtl_RecMode2_OnCopyOrWindowAbort with WA = 2 while a window is open; both then hide the window and post
;   message 35.
CstmCpTtl_ResolvePendingCopy:
	dec	2, xsp
	ld	(xsp), a
	calr	Flash_InitExtMemAddrs
	ld	l, (3176:16)
	ld	c, (3178:16)
	ld	e, (3180:16)
	cp	(xsp), 2
	jr	z, CstmCpTtl_ResolvePendingCopy_Join3
	cp	(xsp), 0
	jr	nz, CstmCpTtl_ResolvePendingCopy_Join3
	ld	a, l
	extz	wa
	extz	bc
	extz	de
	cp	l, 10
	jr	nc, CstmCpTtl_ResolvePendingCopy_Skip
	calr	Flash_InitBytecodeBlock_Helper8
	jr	CstmCpTtl_ResolvePendingCopy_Join3
CstmCpTtl_ResolvePendingCopy_Skip:
	calr	Flash_InitBytecodeBlock_Helper9
CstmCpTtl_ResolvePendingCopy_Join3:
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
	jr	z, CstmCpTtl_ResolvePendingCopy_Skip2
	cp	(xsp), 0
	jr	nz, CstmCpTtl_ResolvePendingCopy_Skip2
	extz	wa
	extz	bc
	extz	de
	calr	Flash_InitBytecodeBlock_Helper9
CstmCpTtl_ResolvePendingCopy_Skip2:
	call	AccPatch_CountSlots_Wrapper
	ld	l, 0:opc
	inc	2, xsp
	ret
	jrl	InitializeNaka_Join

; PartGrid column dispatch (7-entry, table 0xe1611a)
PartGrid_ColumnDispatch:
	ld xhl, (RHYTHM_PATTERN_BUF_PTR:16)
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
	ld	xhl, (FLASH_SECTION_PTR_0:16)
	jr	PartGrid_ColumnDispatch_Return
; PartGrid_ColumnDispatch_FlashSection1: A = 10..29 selects section (A - 10) / 3 (three per section); A < 10 returns
;   RHYTHM_PATTERN_BUF_PTR, A >= 30 the buffer pointer at RAM 3186; what A numbers is not established.
PartGrid_ColumnDispatch_FlashSection1:
	ld	xhl, (FLASH_SECTION_PTR_1:16)
	jr	PartGrid_ColumnDispatch_Return
PartGrid_ColumnDispatch_FlashSection2:
	ld	xhl, (FLASH_SECTION_PTR_2:16)
	jr	PartGrid_ColumnDispatch_Return
PartGrid_ColumnDispatch_FlashSection3:
	ld	xhl, (FLASH_SECTION_PTR_3:16)
	jr	PartGrid_ColumnDispatch_Return
PartGrid_ColumnDispatch_FlashSection4:
	ld	xhl, (FLASH_SECTION_PTR_4:16)
	jr	PartGrid_ColumnDispatch_Return
PartGrid_ColumnDispatch_FlashSection5:
	ld	xhl, (FLASH_SECTION_PTR_5:16)
	jr	PartGrid_ColumnDispatch_Return
PartGrid_ColumnDispatch_FlashSection6:
	ld	xhl, (FLASH_SECTION_PTR_6:16)
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
	jr	c, PartGrid_OperationsBlock_Skip
	submi8	(xsp+0xc), 30
	jr	PartGrid_OperationsBlock_Join
PartGrid_OperationsBlock_Skip:
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
	ld	a, (xbc+wa)
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
	jr	z, Util_FrameSetup10_Skip
	cp	(xsp+8), 3
	jr	z, PartGrid_OperationsBlock_Skip2
	cp	(xsp+8), 2
	jr	z, PartGrid_OperationsBlock_Entry2
	cp	(xsp+8), 1
	jr	z, PartGrid_OperationsBlock_Entry
	cp	(xsp+8), 0
	jr	nz, PartGrid_OperationsBlock_Epilogue
	ld	(xbc+24), e
	ld	xwa, 25
	jr	PartGrid_OperationsBlock_Join2
PartGrid_OperationsBlock_Entry:
	ld	(xbc+32), e
	ld	xwa, 33
	jr	PartGrid_OperationsBlock_Join2
PartGrid_OperationsBlock_Entry2:
	ld	(xbc+40), e
	ld	xwa, 41
	jr	PartGrid_OperationsBlock_Join2
PartGrid_OperationsBlock_Skip2:
	ld	(xbc+48), e
	ld	xwa, 49
	jr	PartGrid_OperationsBlock_Join2
Util_FrameSetup10_Skip:
	ld	(xbc+56), e
	ld	xwa, 57
PartGrid_OperationsBlock_Join2:
	add	xbc, xwa
	ld	a, (xsp)
	ld	(xbc), a
PartGrid_OperationsBlock_Epilogue:
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
	lda xbc, (RhythmSlot_FlashSectionTable:24)
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
	ld xbc, (FLASH_SECTION_PTR_0:16); Case 0: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
; NoteEventBuffer_CopyToSlot_LoadSection1: Value 2: copy Custom Data Flash section 1 (FLASH_SECTION_PTR_1, 0x319800)
;   into the RAM work buffer at (3186); value N loads section N-1.
NoteEventBuffer_CopyToSlot_LoadSection1:
	ld xbc, (FLASH_SECTION_PTR_1:16); Case 1: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
NoteEventBuffer_CopyToSlot_LoadSection2:
	ld xbc, (FLASH_SECTION_PTR_2:16); Case 2: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
NoteEventBuffer_CopyToSlot_LoadSection3:
	ld xbc, (FLASH_SECTION_PTR_3:16); Case 3: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
NoteEventBuffer_CopyToSlot_LoadSection4:
	ld xbc, (FLASH_SECTION_PTR_4:16); Case 4: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
NoteEventBuffer_CopyToSlot_LoadSection5:
	ld xbc, (FLASH_SECTION_PTR_5:16); Case 5: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
NoteEventBuffer_CopyToSlot_LoadSection6:
	ld xbc, (FLASH_SECTION_PTR_6:16); Case 6: Load dest pointer (falls through)
NOTE_EVENT_COPY_COMMON:	; F1717D - Common handler
	ld	xiy, xbc	; XIY = destination pointer
	ld	xix, xwa	; XIX = source pointer
	ldw	bc, 0xb400	; BC = 0xb400 byte count
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
	ld xwa, (FLASH_SECTION_PTR_0:16)
	ld (xsp + 4), xwa
	jrl Flash_WriteSectorWithMirrorCopy
NOTE_EVENT_DISPATCH_2b:
	ld xwa, (FLASH_SECTION_PTR_1:16)
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
NoteEventBuffer_Store_WriteSection2:
	ld xwa, (FLASH_SECTION_PTR_2:16)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
NoteEventBuffer_Store_WriteSection3:
	ld xwa, (FLASH_SECTION_PTR_3:16)
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
NoteEventBuffer_Store_WriteSection4:
	ld xwa, (FLASH_SECTION_PTR_4:16)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
NoteEventBuffer_Store_WriteSection5:
	ld xwa, (FLASH_SECTION_PTR_5:16)
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
NoteEventBuffer_Store_WriteSection6:
	ld xwa, (FLASH_SECTION_PTR_6:16)
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
	ld xwa, (3186:16)
	ld (0x39ae:16), xwa
	jp AccPatch_InitSlotChain_Wrap
Flash_ExtendedOpsBlock:
	push	xiz
	extz	de
	lda	xix, (MSP_Default_ChannelMap:24)
	lda	xhl, (xix+de)
	ld e, 0:opc
	cp	a, 10
	jr	nc, Flash_ExtendedOpsBlock_Skip
	ld	c, (xhl)
	extz	wa
	ld	l, (xix+wa)
	ld ix, 0:i3
Flash_ExtendedOpsBlock_Loop:
	ld a, c
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (3186:16)
	lda	xiz, (xwa+iy)
	ld a, l
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xwa, (xwa+iy)
	ld	a, (xwa+160)
	ld (xiz+160), a
	inc 1, e
	inc 1, ix
	cp	e, 16
	jr	c, Flash_ExtendedOpsBlock_Loop
	jr	Flash_ExtendedOpsBlock_Epilogue
Flash_ExtendedOpsBlock_Skip:
	extz	bc
	ld	c, (xix+bc)
	ld l, (xhl)
	ld ix, 0:i3
Flash_ExtendedOpsBlock_Loop2:
	ld a, c
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xiz, (xwa+iy)
	ld a, l
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ld	xwa, (3186:16)
	lda	xwa, (xwa+iy)
	ld	a, (xwa+160)
	ld	(xiz+160), a
	inc	1, e
	inc	1, ix
	cp	e, 16
	jr	c, Flash_ExtendedOpsBlock_Loop2
Flash_ExtendedOpsBlock_Epilogue:
	pop	xiz
	ret
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xhl, (xbc+16)
	add	e, 32
	extz	de
	add	de, 16
	ld	xbc, (3186:16)
	lda	xbc, (xbc+de)
	cp a, 10
	jr nc, Flash_ExtendedOpsBlock_Skip2
	ld a, (xhl)
	ld (xbc), a
	ret
Flash_ExtendedOpsBlock_Skip2:
	ld a, (xbc)
	ld (xhl), a
	ret
; Flash_AssignSlotsToBlocks: For owner A, builds the slot assignment list at RAM 0x7A0 from the block list at RAM
;   0x6D4: the large block (entry 0) gets the first of the 4 large slots whose owner byte is 0 or A, each following
;   block the next such small slot (of 40); records are {block, 0x500 | slot} with bit 7 set for small slots. Basis:
;   callers + body -- Flash_InitBytecodeBlock runs it first on its write path (no shortfall), with A = its owner
;   argument (CstmCp's 0x39B7); Flash_WriteSlotOwnerMap and Flash_CopyBlocksToSlots consume the list.
Flash_AssignSlotsToBlocks:
	dec 2, xsp
	pushw iz
	ld	(xsp+2), a
	calr	SlotTable_ExtendedOpsBlock
	lda	xix, (1748:16)
	cpw	(xix), 0xffff
	jr	z, Flash_AssignSlotsToBlocks_Join
	ld	l, 0:opc
	ld	xbc, (FLASH_SECTION_PTR_7:16)
Flash_AssignSlotsToBlocks_Loop:
	ld	a, l
	extz	wa
	add	wa, 80
	ld	a, (xbc+wa)
	cp a, 0:i3
	jr z, Flash_AssignSlotsToBlocks_Skip
	cp	a, (xsp+0x2)
	jr	nz, Flash_AssignSlotsToBlocks_Skip2
Flash_AssignSlotsToBlocks_Skip:
	lda	xbc, (1952:16)
	ld	wa, (xix)
	ld	(xbc), wa
	extz	hl
	or	hl, 1280
	ld	(xbc+2), hl
	jr	Flash_AssignSlotsToBlocks_Join
Flash_AssignSlotsToBlocks_Skip2:
	inc	1, l
	cp	l, 4:i3
	jr	c, Flash_AssignSlotsToBlocks_Loop
Flash_AssignSlotsToBlocks_Join:
	ld	h, 0:opc
	ld	l, 0:opc
	ldib_erp 234, 0
Flash_AssignSlotsToBlocks_Loop2:
	ldto_berp a, 234
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xbc, (xix+wa)
	cpw	(xbc), 0xffff
	jr	z, Flash_AssignSlotsToBlocks_Epilogue
	cp	l, 40
	jr	nc, Flash_AssignSlotsToBlocks_Join2
Flash_AssignSlotsToBlocks_Loop3:
	ld	e, l
	extz	de
	add	de, 16
	ld	xwa, (FLASH_SECTION_PTR_7:16)
	ld	a, (xwa+de)
	cp a, 0:i3
	jr z, Flash_AssignSlotsToBlocks_Skip3
	cp	a, (xsp+0x2)
	jr	nz, Flash_AssignSlotsToBlocks_Skip4
Flash_AssignSlotsToBlocks_Skip3:
	ld	e, h
	extz	de
	sla	de, 2
	ld	iz, de
	inc	4, iz
	lda	xiy, (1952:16)
	ld	wa, (xbc)
	ld	(xiy+iz), wa
	inc	6, de
	ld	a, l
	set	7, a
	extz	wa
	or	wa, 1280
	ld	(xiy+de), wa
	inc	1, h
	inc	1, l
	jr	Flash_AssignSlotsToBlocks_Join2
Flash_AssignSlotsToBlocks_Skip4:
	inc	1, l
	cp	l, 40
	jr	c, Flash_AssignSlotsToBlocks_Loop3
Flash_AssignSlotsToBlocks_Join2:
	inc1b_erp 234
	cp_erpb 234, 50
	jr c, Flash_AssignSlotsToBlocks_Loop2
Flash_AssignSlotsToBlocks_Epilogue:
	popw iz
	inc	2, xsp
	ret
Flash_InitBytecodeBlock_Helper10:
	dec	6, xsp
	ld	(xsp+4), a
	calr	SlotTable_ExtendedOpsBlock
	lda	xwa, (1748:16)
	cpw	(xwa), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper10_Skip5
	lda	xbc, (1952:16)
	ld	wa, (xwa)
	ld	(xbc), wa
	ldw (xbc+2), 1536
Flash_InitBytecodeBlock_Helper10_Skip5:
	ld	a, (xsp+4)
	extz	wa
	calr	Flash_InitBytecodeBlock_Helper_Helper
	ld	(xsp+2), 0
	ld	(xsp), 0
Flash_InitBytecodeBlock_Helper10_Loop4:
	ld	a, (xsp)
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xbc, (1748:16)
	ld	bc, (xbc+wa)
	cp bc, 65535
	jrl	z, Flash_InitBytecodeBlock_Helper10_Epilogue2
	ld	l, 0:opc
Flash_StoreBaseAndInitAccPatch_Loop3:
	ld	h, 39:opc
	sub	h, l
	ld	a, h
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xix, (3074:16)
	lda	xde, (xix+wa)
	ld wa, (xde)
	ldfr_berp a, 226
	ld a, (xsp+2)
	extz	wa
	cp_erpb 226, 255
	jr nz, Flash_StoreBaseAndInitAccPatch_Skip3
	sla	wa, 2
	ld	iy, wa
	inc	4, iy
	lda	xix, (1952:16)
	ld	(xix+iy), bc
	ld	bc, wa
	inc	6, bc
	set	7, h
	ld	l, h
	extz	hl
	ld	(xix+bc), hl
	ldw (xde), 2
	jr	Flash_StoreBaseAndInitAccPatch_Join2
Flash_StoreBaseAndInitAccPatch_Skip3:
	inc	1, l
	cp	l, 40
	jr	c, Flash_StoreBaseAndInitAccPatch_Loop3
	ld	l, 0:opc
	ld	iy, wa
Flash_InitBytecodeBlock_Helper10_Loop5:
	ld	h, 39:opc
	sub	h, l
	ld	a, h
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xde, (xix+wa)
	ld wa, (xde)
	ldfr_berp a, 226
	cpib_erp 226, 1
	jr nz, Flash_StoreBaseAndInitAccPatch_Skip4
	ld	wa, iy
	sla	wa, 2
	ld	iy, wa
	inc	4, iy
	lda	xix, (1952:16)
	ld	(xix+iy), bc
	ld	bc, wa
	inc	6, bc
	set	7, h
	ld	l, h
	extz	hl
	ld	(xix+bc), hl
	ldw (xde), 2
Flash_StoreBaseAndInitAccPatch_Join2:
	incm8	1, (xsp+2)
	jr	Flash_InitBytecodeBlock_Helper10_Join2
Flash_StoreBaseAndInitAccPatch_Skip4:
	inc	1, l
	cp	l, 40
	jr	c, Flash_InitBytecodeBlock_Helper10_Loop5
Flash_InitBytecodeBlock_Helper10_Join2:
	incm8	1, (xsp)
	cp	(xsp), 50
	jrl	c, Flash_InitBytecodeBlock_Helper10_Loop4
Flash_InitBytecodeBlock_Helper10_Epilogue2:
	inc	6, xsp
	ret
Flash_StoreBaseAndInitAccPatch_Sub:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), a
	cpw	(0x7a0:16), 0xffff
	jr	z, Flash_StoreBaseAndInitAccPatch_Sub_Skip
	ldib_erp 249, 0
Flash_StoreBaseAndInitAccPatch_Sub_Loop:
	ld	a, (xsp+4)
	add	a, 30
	ldfr_berp a, 250
	ldto_berp a, 249
	ldfr_berp a, 251
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	ld	de, 0:i3
	calr	Util_FrameSetup10
	lda	xwa, (1952:16)
	cp	hl, (xwa)
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip5
	ld	hl, (xwa+2)
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	pushw	hl
	ld	de, 0:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Skip5:
	inc1b_erp 249
	cp_erpb 249, 10
	jr c, Flash_StoreBaseAndInitAccPatch_Sub_Loop
Flash_StoreBaseAndInitAccPatch_Sub_Skip:
	ldib_erp 248, 0
Flash_StoreBaseAndInitAccPatch_Loop4:
	ldto_berp c, 248
	extz	bc
	sla	bc, 2
	lda	xwa, (1956:16)
	cpw	(xwa+bc), 0xffff
	jrl	z, Flash_StoreBaseAndInitAccPatch_Sub_Epilogue
	ldib_erp 249, 0
Flash_StoreBaseAndInitAccPatch_Loop5:
	ld	a, (xsp+4)
	add	a, 30
	ldfr_berp a, 250
	ldto_berp a, 249
	ldfr_berp a, 251
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	ld	de, 1:i3
	calr	Util_FrameSetup10
	ldto_berp a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	cp	hl, (xbc+de)
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip2
	inc	6, wa
	ld	hl, (xbc+wa)
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	pushw	hl
	ld	de, 1:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip2:
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	ld	de, 2:i3
	calr	Util_FrameSetup10
	ldto_berp a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	cp	hl, (xbc+de)
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip3
	inc	6, wa
	ld	hl, (xbc+wa)
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	pushw	hl
	ld	de, 2:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip3:
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	ld	de, 3:i3
	calr	Util_FrameSetup10
	ldto_berp a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	cp	hl, (xbc+de)
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip4
	inc	6, wa
	ld	hl, (xbc+wa)
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	pushw	hl
	ld	de, 3:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip4:
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	ld	de, 4:i3
	calr	Util_FrameSetup10
	ldto_berp a, 248
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (1952:16)
	cp	hl, (xbc+de)
	jr	nz, Flash_StoreBaseAndInitAccPatch_Sub_Skip5
	inc	6, wa
	ld	hl, (xbc+wa)
	ldto_berp a, 250
	extz	wa
	ldto_berp c, 251
	extz	bc
	pushw	hl
	ld	de, 4:i3
	calr	PartGrid_OperationsBlock
Flash_StoreBaseAndInitAccPatch_Sub_Skip5:
	inc1b_erp 249
	cp_erpb 249, 10
	jrl c, Flash_StoreBaseAndInitAccPatch_Loop5
	inc1b_erp 248
	cp_erpb 248, 50
	jrl c, Flash_StoreBaseAndInitAccPatch_Loop4
Flash_StoreBaseAndInitAccPatch_Sub_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
; Flash_WriteSlotOwnerMap: Copies the 64 KB section-7 sector into its RAM image at (0x0C96), writes owner A into the
;   owner byte of every slot in the assignment list at RAM 0x7A0, clears A from the remaining slots after them, then
;   erases and rewrites the sector (Flash_EraseSectorAndWrite). Basis: callers + body -- Flash_InitBytecodeBlock calls
;   it on its write path after Flash_AssignSlotsToBlocks built the list, with the same owner A.
Flash_WriteSlotOwnerMap:
	ld	xix, (3222:16)
	ld	xiy, (FLASH_SECTION_PTR_7:16)
	ldw	bc, 0x8000
	ldirw
	lda	xhl, (1952:16)
	ld	bc, (xhl+2)
	cp	bc, 0xffff
	jr	z, Flash_WriteSlotOwnerMap_Skip7
	and	bc, 127
	ld	w, c
	ld	e, w
	extz	de
	add	de, 80
	ld	xbc, (3222:16)
	ld	(xbc+de), a
	cp w, 3:i3
	jr z, Flash_WriteSlotOwnerMap_Join3
	inc	1, w
	cp	w, 3:i3
	jr	ugt, Flash_WriteSlotOwnerMap_Join3
	ld	e, w
	extz	de
Flash_WriteSlotOwnerMap_Loop6:
	ld	ix, de
	add	ix, 80
	ld	xbc, (3222:16)
	lda	xbc, (xbc+ix)
	cp (xbc), a
	jr	nz, Flash_WriteSlotOwnerMap_Skip6
	ld	(xbc), 0
Flash_WriteSlotOwnerMap_Skip6:
	inc	1, w
	inc	1, de
	cp	w, 3:i3
	jr	ule, Flash_WriteSlotOwnerMap_Loop6
	jr	Flash_WriteSlotOwnerMap_Join3
Flash_WriteSlotOwnerMap_Skip7:
	ld	w, 0:opc
	ld	de, 0:i3
Flash_WriteSlotOwnerMap_Loop7:
	ld	ix, de
	add	ix, 80
	ld	xbc, (3222:16)
	lda	xbc, (xbc+ix)
	cp (xbc), a
	jr	nz, Flash_WriteSlotOwnerMap_Skip8
	ld	(xbc), 0
Flash_WriteSlotOwnerMap_Skip8:
	inc	1, w
	inc	1, de
	cp	w, 4:i3
	jr	c, Flash_WriteSlotOwnerMap_Loop7
Flash_WriteSlotOwnerMap_Join3:
	ld	w, 0:opc
	ldib_erp 226, 0
Flash_WriteSlotOwnerMap_Loop8:
	ldto_berp c, 226
	extz	bc
	sla	bc, 2
	inc	6, bc
	ld	bc, (xhl+bc)
	cp bc, 65535
	jr	z, Flash_WriteSlotOwnerMap_Skip9
	and	bc, 127
	ld	w, c
	ld	e, w
	extz	de
	add	de, 16
	ld	xbc, (3222:16)
	ld	(xbc+de), a
	inc 1, w
	inc1b_erp 226
	cp_erpb 226, 50
	jr c, Flash_WriteSlotOwnerMap_Loop8
Flash_WriteSlotOwnerMap_Skip9:
	cp	w, 40
	jr	z, Flash_WriteSlotOwnerMap_Skip11
	cp	w, 39
	jr	ugt, Flash_WriteSlotOwnerMap_Skip11
	ld	e, w
	extz	de
Flash_WriteSlotOwnerMap_Loop9:
	ld	hl, de
	add	hl, 16
	ld	xbc, (3222:16)
	lda	xbc, (xbc+hl)
	cp (xbc), a
	jr	nz, Flash_WriteSlotOwnerMap_Skip10
	ld	(xbc), 0
Flash_WriteSlotOwnerMap_Skip10:
	inc	1, w
	inc	1, de
	cp	w, 39
	jr	ule, Flash_WriteSlotOwnerMap_Loop9
Flash_WriteSlotOwnerMap_Skip11:
	ld	xbc, (3222:16)
	ld	xde, (FLASH_SECTION_PTR_7:16)
	ld	wa, 1:i3
	jp	Flash_EraseSectorAndWrite
; Flash_CopyBlocksToSlots: Copies every block in the assignment list at RAM 0x7A0 from the RAM work area at 0x1E0000
;   into its slot in the RAM image of the section-7 sector (large block 10,535 bytes, small blocks 470), then erases
;   and rewrites the sector. Basis: callers + body -- Flash_InitBytecodeBlock calls it right after
;   Flash_WriteSlotOwnerMap on its write path; Flash_GetSlotAddressAndSize supplies the source and destination addresses.
Flash_CopyBlocksToSlots:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xix, (3222:16)
	ld	xiy, (FLASH_SECTION_PTR_7:16)
	ldw	bc, 0x8000
	ldirw
	lda_d16	xwa, (0x7a0)
	cpw	(xwa), 0xffff
	jr	z, Flash_CopyBlocksToSlots_Skip12
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
	call	Flash_GetSlotAddressAndSize
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_CopyBlocksToSlots_Skip12
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 3:i3
	call	Flash_GetSlotAddressAndSize
	ld	xix, (xsp+12)
	sub	xix, 0x346800
	cp	hl, 0:i3
	jr	nz, Flash_CopyBlocksToSlots_Skip12
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_CopyBlocksToSlots_Skip12
	ld	xbc, 0:i3
Flash_CopyBlocksToSlots_Loop:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_CopyBlocksToSlots_Loop
Flash_CopyBlocksToSlots_Skip12:
	ld	(xsp+6), 0
Flash_CopyBlocksToSlots_Loop2:
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	ld	wa, bc
	inc	4, wa
	lda	xde, (1952:16)
	ld	wa, (xde+wa)
	cp wa, 65535
	jr	z, Flash_CopyBlocksToSlots_Skip13
	ld	w, 0:opc
	ld	l, a
	inc	6, bc
	ld	wa, (xde+bc)
	ld w, 0:opc
	ld	(xsp+4), a
	res	7, l
	resm	7, (xsp+0x4)
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 0:i3
	call	Flash_GetSlotAddressAndSize
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_CopyBlocksToSlots_Skip
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 1:i3
	call	Flash_GetSlotAddressAndSize
	ld	xix, (xsp+12)
	sub	xix, 0x346800
	cp	hl, 0:i3
	jr	nz, Flash_CopyBlocksToSlots_Skip
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_CopyBlocksToSlots_Skip
	ld	xbc, 0:i3
Flash_CopyBlocksToSlots_Loop3:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_CopyBlocksToSlots_Loop3
Flash_CopyBlocksToSlots_Skip:
	incm8	1, (xsp+0x6)
	cp	(xsp+0x6), 50
	jrl	c, Flash_CopyBlocksToSlots_Loop2
Flash_CopyBlocksToSlots_Skip13:
	ld	xbc, (3222:16)
	ld	xde, (FLASH_SECTION_PTR_7:16)
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
	call	Flash_GetSlotAddressAndSize
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
	call	Flash_GetSlotAddressAndSize
	ld	xix, (xsp+12)
	cp	hl, 0:i3
	jr	nz, Flash_StoreBaseAndInitAccPatch_Skip14
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip14
	ld	xbc, 0:i3
Flash_InitBytecodeBlock_Helper9_Helper_Loop4:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_InitBytecodeBlock_Helper9_Helper_Loop4
Flash_StoreBaseAndInitAccPatch_Skip14:
	ld	(xsp+6), 0
Flash_InitBytecodeBlock_Helper9_Helper_Loop5:
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	ld	wa, bc
	inc	4, wa
	lda	xde, (1952:16)
	ld	wa, (xde+wa)
	cp wa, 65535
	jr	z, Flash_InitBytecodeBlock_Helper9_Helper_Epilogue
	ld	w, 0:opc
	ld	l, a
	inc	6, bc
	ld	wa, (xde+bc)
	ld w, 0:opc
	ld	(xsp+4), a
	res	7, l
	resm	7, (xsp+0x4)
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 1:i3
	call	Flash_GetSlotAddressAndSize
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cp	hl, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Helper9_Helper_Skip2
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	ld	wa, 0:i3
	call	Flash_GetSlotAddressAndSize
	ld	xix, (xsp+12)
	cp	hl, 0:i3
	jr	nz, Flash_InitBytecodeBlock_Helper9_Helper_Skip2
	ld	hl, 0:i3
	cpw	(xsp+0x8), 0
	jr	ule, Flash_InitBytecodeBlock_Helper9_Helper_Skip2
	ld	xbc, 0:i3
Flash_InitBytecodeBlock_Helper9_Helper_Loop6:
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	cp	hl, (xsp+0x8)
	jr	c, Flash_InitBytecodeBlock_Helper9_Helper_Loop6
Flash_InitBytecodeBlock_Helper9_Helper_Skip2:
	incm8	1, (xsp+0x6)
	cp	(xsp+0x6), 50
	jrl	c, Flash_InitBytecodeBlock_Helper9_Helper_Loop5
Flash_InitBytecodeBlock_Helper9_Helper_Epilogue:
	pop	xiz
	lda	xsp, (xsp+0xc)
	ret
Flash_InitBytecodeBlock_Helper4:
	dec	8, xsp
	push	xiz
	ld	(xsp+10), c
	ld	iz, wa
	calr	SlotTable_ExtendedOpsBlock
	calr	Flash_InitBytecodeBlock_Helper4_Helper
	calr	Flash_InitBytecodeBlock_Helper4_Helper2
	ld	wa, iz
	and	wa, 0xff00
	jr	z, Flash_InitBytecodeBlock_Helper4_Skip
	ld	d, 0:opc
	ld	b, 0:opc
	ld	c, 0:opc
	ld	xhl, (FLASH_SECTION_PTR_7:16)
	ld	ix, 0:i3
Flash_StoreBaseAndInitAccPatch_Loop10:
	ld	wa, ix
	add	wa, 80
	ld	w, (xhl+wa)
	cp w, b
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
	lda	xhl, (xhl+wa)
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
	ld	xwa, (FLASH_SECTION_PTR_7:16)
	ld	w, (xwa+ix)
	cp w, 0:i3
	jr z, Flash_StoreBaseAndInitAccPatch_Skip16
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
	ld	(xiy+iz), wa
	inc	6, ix
	ld	a, c
	set	7, a
	extz	wa
	or	wa, 1280
	ld	(xiy+ix), wa
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
	cpw	(xix+iy), 0x0001
	jr	z, Flash_InitBytecodeBlock_Helper4_Skip4
	ld	iy, wa
	add	iy, 16
	ld	xwa, (FLASH_SECTION_PTR_7:16)
	ld	w, (xwa+iy)
	cp w, b
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
	ld qwa, iy
	inc 4, qwa
	lda xiz, (1952:16)
	ld wa, (xhl)
	ld	(xiz+qwa), wa
	inc	6, iy
	ld	l, d
	set	7, l
	extz	hl
	or	hl, 1280
	ld	(xiz+iy), hl
	ld	a, (xsp+6)
	extz	wa
	sla	wa, 2
	ld	iz, wa
	inc	4, iz
	lda	xiy, (2156:16)
	ld	(xiy+iz), hl
	ld	hl, wa
	inc	6, hl
	ld	a, b
	extz	wa
	ld	(xiy+hl), wa
	ld	a, d
	extz	wa
	add	wa, wa
	inc	2, wa
	ldw	(xix+wa), 0x0001
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
Flash_InitBytecodeBlock_Helper5:
	push	xiz
	lda	xbc, (0x3a4f:16)
	ld	xwa, xbc
	lda	xbc, (xbc+29)
Flash_InitBytecodeBlock_Helper5_Loop:
	ld (xwa+), 32
	cp xwa, xbc
	jr	c, Flash_InitBytecodeBlock_Helper5_Loop
	ldib_erp 251, 0
	lda	xwa, (2156:16)
	cpw	(xwa), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper5_Skip
	ld	wa, (xwa)
	ld	w, 0:opc
	ldfr_berp a, 249
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper
	ldfr_berp l, 248
	ldto_berp a, 249
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper2
	lda	xbc, (0x3a4f:16)
	ld	(xbc), 35
	ld	(xbc+1), l
	ldto_berp a, 248
	ld	(xbc+2), a
	ld	(xbc+3), 40
	ld	(xbc+4), 68
	ld	(xbc+5), 114
	ld	(xbc+6), 109
	ld	(xbc+7), 41
	ldi_erpb 251, 9
Flash_InitBytecodeBlock_Helper5_Skip:
	ldib_erp 250, 0
Flash_StoreBaseAndInitAccPatch_Loop12:
	ldto_berp a, 250
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	lda	xbc, (2156:16)
	cpw	(xbc+de), 0xffff
	jrl	z, Flash_StoreBaseAndInitAccPatch_Epilogue2
	inc	6, wa
	ld	wa, (xbc+wa)
	ldfr_berp a, 249
	ld bc, 0:i3
	cpib_erp 250, 0
	jr z, Flash_InitBytecodeBlock_Helper5_Skip2
	ldto_berp a, 249
	cp	a, l
	jr	z, Flash_InitBytecodeBlock_Helper5_Skip2
	ld	bc, 1:i3
Flash_InitBytecodeBlock_Helper5_Skip2:
	cpib_erp 250, 0
	scc z, wa
	or wa, bc
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip17
	ldto_berp a, 249
	sub a, 10
	extz wa
	calr Flash_StoreBaseAndInitAccPatch_Helper
	ldfr_berp l, 248
	ldto_berp a, 249
	sub a, 10
	extz wa
	calr Flash_StoreBaseAndInitAccPatch_Helper2
	ldto_berp a, 251
	extz	wa
	lda	xbc, (0x3a4f:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 35
	ldto_berp a, 251
	inc 1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	ldto_berp a, 251
	inc 2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldto_berp a, 248
	ld	(xde), a
	incb_erp 251, 4
	cp_erpb 251, 26
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip17
	decb_erp 251, 4
	ldto_berp a, 251
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp a, 251
	inc 1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp a, 251
	inc 2, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	jr	Flash_StoreBaseAndInitAccPatch_Epilogue2
Flash_StoreBaseAndInitAccPatch_Skip17:
	ldto_berp l, 249
	inc1b_erp 250
	cp_erpb 250, 50
	jrl c, Flash_StoreBaseAndInitAccPatch_Loop12
Flash_StoreBaseAndInitAccPatch_Epilogue2:
	pop	xiz
	ret
Flash_StoreBaseAndInitAccPatch_Helper:
	cp	a, 10
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip18
	add	a, 48
	ld	l, a
	jr	Flash_StoreBaseAndInitAccPatch_Return
Flash_StoreBaseAndInitAccPatch_Skip18:
	cp	a, 20
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip19
	add	a, 38
	ld	l, a
	jr	Flash_StoreBaseAndInitAccPatch_Return
Flash_StoreBaseAndInitAccPatch_Skip19:
	cp	a, 30
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip20
	add	a, 28
	ld	l, a
	jr	Flash_StoreBaseAndInitAccPatch_Return
Flash_StoreBaseAndInitAccPatch_Skip20:
	cp	a, 40
	jr	nc, Flash_StoreBaseAndInitAccPatch_Skip21
	add	a, 18
	ld	l, a
	jr	Flash_StoreBaseAndInitAccPatch_Return
Flash_StoreBaseAndInitAccPatch_Skip21:
	inc	8, a
	ld	l, a
Flash_StoreBaseAndInitAccPatch_Return:
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
	lda	xde, (0x3a4f:16)
	ld	xwa, xde
	lda	xbc, (xde+29)
Flash_StoreBaseAndInitAccPatch_Helper2_Loop:
	ld (xwa+), 32
	cp xwa, xbc
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
	ldi_erpb 248, 9
Flash_StoreBaseAndInitAccPatch_Helper2_Skip:
	ldib_erp 249, 0
Flash_StoreBaseAndInitAccPatch_Helper2_Loop2:
	ldto_berp a, 249
	extz	wa
	sla	wa, 2
	lda	xbc, (1958:16)
	ld	wa, (xbc+wa)
	cp wa, 65535
	jrl	z, Flash_StoreBaseAndInitAccPatch_Epilogue3
	res	7, a
	ldfr_berp a, 250
	ld bc, 0:i3
	cpib_erp 249, 0
	jr z, Flash_StoreBaseAndInitAccPatch_Skip25
	ldto_berp a, 250
	cp	a, e
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip25
	ld	bc, 1:i3
Flash_StoreBaseAndInitAccPatch_Skip25:
	cpib_erp 249, 0
	scc z, wa
	or wa, bc
	jr	z, Flash_StoreBaseAndInitAccPatch_Skip26
	ldto_berp a, 250
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper
	ldfr_berp l, 251
	ldto_berp a, 250
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Helper2
	ldto_berp a, 248
	extz	wa
	lda	xbc, (0x3a4f:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 35
	ldto_berp a, 248
	inc 1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	ldto_berp a, 248
	inc 2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldto_berp a, 251
	ld	(xde), a
	incb_erp 248, 4
	cp_erpb 248, 26
	jr	ule, Flash_StoreBaseAndInitAccPatch_Skip26
	decb_erp 248, 4
	ldto_berp a, 248
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp a, 248
	inc 1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	ldto_berp a, 248
	inc 2, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	jr	Flash_StoreBaseAndInitAccPatch_Epilogue3
Flash_StoreBaseAndInitAccPatch_Skip26:
	ldto_berp e, 250
	inc1b_erp 249
	cp_erpb 249, 50
	jrl c, Flash_StoreBaseAndInitAccPatch_Helper2_Loop2
Flash_StoreBaseAndInitAccPatch_Epilogue3:
	pop	xiz
	ret
Flash_InitBytecodeBlock_Helper6:
	calr	Flash_InitBytecodeBlock_Helper6_Helper
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
	ldib_erp 234, 0
	ldib_erp 226, 0
Flash_InitBytecodeBlock_Helper6_Loop:
	ldto_berp e, 226
	extz	de
	sla	de, 2
	ld	wa, de
	inc	4, wa
	lda	xbc, (xhl+wa)
	cpw	(xbc), 0xffff
	ret	z
	ldto_berp a, 234
	extz	wa
	add	wa, wa
	ld	iy, wa
	inc	6, iy
	lda	xix, (2360:16)
	inc	6, de
	ld	wa, (xhl+de)
	ld	(xix+iy), wa
	ld	de, (xbc)
	ldto_berp a, 234
	extz	wa
	sla	wa, 2
	ld	bc, wa
	add	bc, 106
	ld	(xix+bc), de
	add	wa, 108
	ldw	(xix+wa), 0x0000
	inc1b_erp 234
	inc1b_erp 226
	cp_erpb 226, 50
	jr c, Flash_InitBytecodeBlock_Helper6_Loop
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
	ld	(xde+ix), iy
	add	wa, 108
	ldw	(xde+wa), 0x0000
	inc	1, h
	inc	1, l
	cp	l, 50
	jr	c, Flash_InitBytecodeBlock_Helper7_Loop
	ret
Flash_StoreBaseAndInitAccPatch_Join5:
	ld	xix, (3222:16)
	ld	xiy, (FLASH_SECTION_PTR_7:16)
	ldw	bc, 0x8000
	ldirw
	ld	xix, (3222:16)
	ld	xiy, MSP_Default_Sequencer
	ldw	bc, 8
	ldirw
	ld	xwa, (3222:16)
	ld	xiy, MSP_Default_SeqReserved
	lda	xix, (xwa+16)
	ldw	bc, 32
	ldirw
	ld	xwa, (3222:16)
	ld	xiy, MSP_Default_SeqTail
	lda	xix, (xwa+80)
	ldw	bc, 8
	ldirw
	ld	xbc, (3222:16)
	ld	xde, (FLASH_SECTION_PTR_7:16)
	ld	wa, 1:i3
	jp	Flash_EraseSectorAndWrite
; Flash_CountFreeOrOwnedSlots: Counts the owner bytes in the section-7 sector (FLASH_SECTION_PTR_7) that are 0 or
;   equal C: A = 0 scans the 40 small-slot bytes at +0x10, otherwise the 4 large-slot bytes at +0x50; L = the count.
;   Basis: callers + body -- Flash_SlotUpdateOpsBlock compares it with the blocks listed at RAM 0x6D4 to report the
;   large- and small-slot shortfall that Flash_InitBytecodeBlock tests before writing.
Flash_CountFreeOrOwnedSlots:
	ld	l, 0:opc
	ld	xde, (FLASH_SECTION_PTR_7:16)
	ld	b, 0:opc
	cp	a, 0:i3
	jr	nz, Flash_CountFreeOrOwnedSlots_Skip4
	ld	wa, 0:i3
Flash_CountFreeOrOwnedSlots_Loop2:
	ld	ix, wa
	add	ix, 16
	ld	h, (xde+ix)
	cp	h, 0:i3
	jr	z, Flash_CountFreeOrOwnedSlots_Skip2
	cp	h, c
	jr	nz, Flash_CountFreeOrOwnedSlots_Skip3
Flash_CountFreeOrOwnedSlots_Skip2:
	inc	1, l
Flash_CountFreeOrOwnedSlots_Skip3:
	inc	1, b
	inc	1, wa
	cp	b, 40
	jr	c, Flash_CountFreeOrOwnedSlots_Loop2
	jr	Flash_CountFreeOrOwnedSlots_Return
Flash_CountFreeOrOwnedSlots_Skip4:
	ld	wa, 0:i3
Flash_CountFreeOrOwnedSlots_Loop3:
	ld	ix, wa
	add	ix, 80
	ld	h, (xde+ix)
	cp	h, 0:i3
	jr	z, Flash_CountFreeOrOwnedSlots_Skip5
	cp	h, c
	jr	nz, Flash_CountFreeOrOwnedSlots_Skip6
Flash_CountFreeOrOwnedSlots_Skip5:
	inc	1, l
Flash_CountFreeOrOwnedSlots_Skip6:
	inc	1, b
	inc	1, wa
	cp	b, 4:i3
	jr	c, Flash_CountFreeOrOwnedSlots_Loop3
Flash_CountFreeOrOwnedSlots_Return:
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
Flash_InitBytecodeBlock_Helper4_Helper:
	lda	xde, (2156:16)
	ldw (xde), 65535
	ldw (xde+2), 65535
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	lda xbc, (xbc+200)
SlotTable_ExtendedOpsBlock_Loop2:
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	cp	xwa, xbc
	jr	c, SlotTable_ExtendedOpsBlock_Loop2
	ret
Flash_InitBytecodeBlock_Helper6_Helper:
	lda	xix, (2360:16)
	ldw (xix), 65535
	ldw (xix+2), 65535
	ldw	(xix+0x4), 0xffff
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	ld	hl, 0:i3
	lda xbc, (xbc+200)
SlotTable_ExtendedOpsBlock_Loop3:
	ld iy, hl
	inc	6, iy
	ldw	(xix+iy), 0xffff
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	inc	2, hl
	cp	xwa, xbc
	jr	c, SlotTable_ExtendedOpsBlock_Loop3
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
SlotTable_ExtendedOpsBlock_Loop4:
	ld	iy, hl
	inc	6, iy
	ldw	(xix+iy), 0xffff
	ldw (xde+:4), 0xffff
	ldw (xwa+:4), 0xffff
	inc	2, hl
	cp	xwa, xbc
	jr	c, SlotTable_ExtendedOpsBlock_Loop4
	ret
Flash_SlotUpdateOpsBlock_Helper2:
	lda	xbc, (3074:16)
	ldw (xbc), 65535
	ld	l, 0:opc
	ld	wa, 0:i3
SlotTable_ExtendedOpsBlock_Loop5:
	ld	de, wa
	inc	2, de
	ldw	(xbc+de), 0xffff
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, SlotTable_ExtendedOpsBlock_Loop5
	ret
Flash_InitBytecodeBlock_Helper4_Helper2:
	lda	xbc, (2972:16)
	ldw (xbc), 65535
	ld	l, 0:opc
	ld	wa, 0:i3
SlotTable_ExtendedOpsBlock_Loop6:
	ld	de, wa
	inc	2, de
	ldw	(xbc+de), 0xffff
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, SlotTable_ExtendedOpsBlock_Loop6
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
	ld xiy, (FLASH_SECTION_PTR_7:16)
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
	ld xde, (FLASH_SECTION_PTR_7:16)
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
	calr	Flash_CountFreeOrOwnedSlots
	cp	l, 0:i3
	jr	nz, Flash_SlotUpdateOpsBlock_Skip
	ldw	(xsp), 1
Flash_SlotUpdateOpsBlock_Skip:
	cpw	(0x6d6:16), 0xffff
	jr	z, Flash_SlotUpdateOpsBlock_Skip3
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	calr	Flash_CountFreeOrOwnedSlots
	ld	e, 0:opc
	lda	xbc, (1748:16)
Flash_SlotUpdateOpsBlock_Loop:
	ld	a, e
	extz	wa
	add	wa, wa
	inc	2, wa
	cpw	(xbc+wa), 0xffff
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
	calr	Flash_SlotUpdateOpsBlock_Helper2
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
	calr	Flash_SlotUpdateOpsBlock_Helper3
	ld	a, (xsp)
	extz	wa
	calr	Flash_SlotUpdateOpsBlock_Helper3
	inc	4, xsp
	ret
Flash_SlotUpdateOpsBlock_Helper3:
	dec	2, xsp
	push	qiz
	ld	(xsp+2), a
	ldib_erp 251, 0
Flash_SlotUpdateOpsBlock_Loop2:
	ld	a, (xsp+2)
	extz	wa
	ldto_berp c, 251
	extz	bc
	ld	de, 0:i3
	calr	Util_FrameSetup10
	ldib_erp 250, 1
Flash_SlotUpdateOpsBlock_Loop3:
	ld	a, (xsp+2)
	extz	wa
	ldto_berp c, 251
	extz	bc
	ldto_berp e, 250
	extz	de
	calr	Util_FrameSetup10
	ld	h, 0:opc
	ld	a, l
	res	7, a
	cp	l, 128
	jr	c, Flash_SlotUpdateOpsBlock_Skip6
	extz	wa
	add	wa, wa
	inc	2, wa
	lda	xbc, (3074:16)
	ldw	(xbc+wa), 0x0001
Flash_SlotUpdateOpsBlock_Skip6:
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, Flash_SlotUpdateOpsBlock_Loop3
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, Flash_SlotUpdateOpsBlock_Loop2
	pop qiz
	inc	2, xsp
	ret
Flash_InitBytecodeBlock_Helper8:
	dec	8, xsp
	ld	(xsp+6), c
	extz	de
	ld	wa, de
	calr	Flash_StoreBaseAndInitAccPatch_Sub
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
	calr	Flash_WriteSlotOwnerMap
	calr	Flash_CopyBlocksToSlots
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
	ldw (xbc+2), 0
	ld	a, (xsp)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld	e, (xbc+wa)
	extz de
	ld	wa, de
	calr	Flash_StoreBaseAndInitAccPatch_Sub
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
	cpw	(xbc+de), 0xffff
	jr	z, Flash_InitBytecodeBlock_Helper8_Epilogue
	add	wa, wa
	inc	6, wa
	ld	wa, (xbc+wa)
	ld (xsp), a
	extz wa
	calr NoteEvent_Store
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
	ld	wa, (xwa+de)
	ld	(xbc+0x4), wa
	ldw	(xbc+0x6), 0
	ld	a, (xsp)
	extz	wa
	lda	xbc, (MSP_Default_GroupIndexPad:24)
	ld	e, (xbc+wa)
	extz de
	ld	wa, de
	calr	Flash_StoreBaseAndInitAccPatch_Sub
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
	ldib_erp 226, 0
Flash_WriteBackSlotTable_Loop:
	ldto_berp c, 226
	extz	bc
	sla	bc, 2
	ld	wa, bc
	add	wa, 106
	ld	wa, (xhl+wa)
	cp wa, 65535
	jr	z, Flash_WriteBackSlotTable_Skip2
	ld	ix, bc
	inc	4, ix
	lda	xde, (1952:16)
	ld	(xde+ix), wa
	ld	ix, bc
	inc	6, ix
	add	bc, 108
	ld	wa, (xhl+bc)
	ld	(xde+ix), wa
	inc1b_erp 226
	cp_erpb 226, 50
	jr c, Flash_WriteBackSlotTable_Loop
Flash_WriteBackSlotTable_Skip2:
	ld	a, (xsp)
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Sub
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
	calr	Flash_StoreBaseAndInitAccPatch_Sub
	ld	xix, (RHYTHM_PATTERN_BUF_PTR:16)
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
	ldib_erp 226, 0
Flash_WriteBackSlotTable_Loop2:
	ldto_berp c, 226
	extz	bc
	sla	bc, 2
	ld	wa, bc
	add	wa, 106
	ld	wa, (xhl+wa)
	cp wa, 65535
	jr	z, Flash_WriteBackSlotTable_Skip4
	ld	ix, bc
	inc	4, ix
	lda	xde, (1952:16)
	ld	(xde+ix), wa
	ld	ix, bc
	inc	6, ix
	add	bc, 108
	ld	wa, (xhl+bc)
	ld	(xde+ix), wa
	inc1b_erp 226
	cp_erpb 226, 50
	jr c, Flash_WriteBackSlotTable_Loop2
Flash_WriteBackSlotTable_Skip4:
	ld	a, (xsp)
	extz	wa
	calr	Flash_StoreBaseAndInitAccPatch_Sub
	ld	xix, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	xiy, (3186:16)
	ldw	bc, 0xb400
	ldirw
	inc	2, xsp
	ret
; FileIO_LoadRcmToFlash: Loads an .RCM file into the custom-data flash: checks the 1 KB header starts 'H',0,'K', then
;   for flash sections 0..6 resets the buffer at (0x0C72) (NoteEvent_LoadSoundGenParams), reads the length held in
;   header dword +68+4*i and stores it (NoteEventBuffer_Store i+1); finally reads 0xF400 bytes over the section-7
;   image, rewrites that sector and calls TmFlash_CopyToExtMem. HL = read result, 0xFF9A on a bad header. Basis:
;   callers + body -- FileIO_LoadRegion6_Simple (.RCM, extension index 6) calls it once the region signature matched.
FileIO_LoadRcmToFlash:
	lda xsp, (xsp-1024)
	pushw	iz
	calr	Flash_InitExtMemAddrs
	lda	xwa, (xsp+2)
	ld	xbc, 1024
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jrl	lt, FileIO_LoadRcmToFlash_Skip5
	lda	xwa, (xsp+2)
	cp	(xwa), 72
	jrl	nz, FileIO_LoadRcmToFlash_Skip6
	cp	(xwa+0x1), 0
	jrl	nz, FileIO_LoadRcmToFlash_Skip6
	cp	(xwa+0x2), 75
	jrl	nz, FileIO_LoadRcmToFlash_Skip6
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+70)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jrl	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 1:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+74)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jrl	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 2:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+78)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jrl	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 3:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+82)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jrl	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 4:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+86)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 5:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+90)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 6:i3
	calr	NoteEventBuffer_Store
	calr	NoteEvent_LoadSoundGenParams
	ld	xwa, (3186:16)
	ld	xbc, (xsp+94)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileIO_LoadRcmToFlash_Skip5
	ld	wa, 7:i3
	calr	NoteEventBuffer_Store
	ld	xix, (3222:16)
	ld	xiy, (FLASH_SECTION_PTR_7:16)
	ldw	bc, 0x8000
	ldirw
	ld	xwa, (3222:16)
	ld	xbc, 0xf400
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileIO_LoadRcmToFlash_Skip5
	ld	xbc, (3222:16)
	ld	xde, (FLASH_SECTION_PTR_7:16)
	ld	wa, 1:i3
	call	Flash_EraseSectorAndWrite
	call	TmFlash_CopyToExtMem
FileIO_LoadRcmToFlash_Skip5:
	ld	hl, iz
	jr	FileIO_LoadRcmToFlash_Epilogue
FileIO_LoadRcmToFlash_Skip6:
	ldw	hl, 0xff9a
FileIO_LoadRcmToFlash_Epilogue:
	popw	iz
	lda	xsp, (xsp+0x400)
	ret
; FileIO_SaveRcmFromFlash: Writes the custom-data flash as an .RCM file to the open handle: builds the 1 KB header
;   from the 'H',0,'K',0 template (MSP_Default_Accompaniment), fills dwords +68..+92 with the sizes of flash sections
;   0-6 ((+46/+47) * 16) and +28 with the total, fails with HL = 0xFF9B when FileIO_GetDiskFreeSpace is smaller, then
;   writes the header, sections 1-7 (NoteEventBuffer_CopyToSlot) and 0xF400 bytes of the section-7 image. HL = write
;   result. Basis: callers + body -- FileIO_SaveRegion6_Simple (region/extension 6) calls it once the file is open for
;   'wb'; it is the save twin of FileIO_LoadRcmToFlash, which reads the same header and section layout.
FileIO_SaveRcmFromFlash:
	lda xsp, (xsp-1036)
	push	xiz
	calr	Flash_InitExtMemAddrs
	ld	xiy, MSP_Default_Accompaniment
	lda	xix, (xsp+16)
	ldw	bc, 512
	ldirw
	ld	xbc, (FLASH_SECTION_PTR_0:16)
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
	ld	xde, (FLASH_SECTION_PTR_1:16)
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
	ld	xde, (FLASH_SECTION_PTR_2:16)
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
	ld	xde, (FLASH_SECTION_PTR_3:16)
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
	ld	xix, (FLASH_SECTION_PTR_4:16)
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
	ld	xix, (FLASH_SECTION_PTR_5:16)
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
	ld	xix, (FLASH_SECTION_PTR_6:16)
	ld	xhl, 0:i3
	ld	l, (xix+46)
	ld	a, (xix+47)
	ld	xix, 0:i3
	ldfr_berp a, 240
	sll xix, 8
	add xix, xhl
	ld	xhl, xix
	sll	xhl, 4
	ld	(xbc+92), xhl
	ld	xwa, (xsp+12)
	ld	xix, (xwa)
	add	xix, (xbc+0x40)
	ld	xwa, (xsp+0x8)
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
	jr	ge, FileIO_SaveRcmFromFlash_Skip7
	ldw	hl, 0xff9b
	jrl	FileIO_SaveRcmFromFlash_Join
FileIO_SaveRcmFromFlash_Skip7:
	lda	xwa, (xsp+16)
	ld	xbc, 1024
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cp	hl, 0:i3
	jrl	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jrl	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jrl	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jrl	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jrl	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jr	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jr	lt, FileIO_SaveRcmFromFlash_Skip8
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
	jr	lt, FileIO_SaveRcmFromFlash_Skip8
	ld	xwa, (FLASH_SECTION_PTR_7:16)
	ld	xbc, 0xf400
	call	FileIO_WriteByte_Impl
FileIO_SaveRcmFromFlash_Skip8:
	call	FileIO_ReturnError
FileIO_SaveRcmFromFlash_Join:
	pop	xiz
	lda	xsp, (xsp+0x40c)
	ret

; Floppy disk load and store note events via dispatch
FloppyDisk_LoadNoteEvents:
	lda xsp, (xsp-1032)
	pushw iz
	ld	(xsp+1026), xbc
	ld	(xsp+1030), xwa
	calr Flash_InitExtMemAddrs
	lda xwa, (xsp + 2)
	ld XIX, (xsp + 0x0406)
	ld xbc, 0x400
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lda xwa, (xsp + 2)
	cp (xwa), 0x48
	jrl nz, Floppy_SetHLFF9A_RetZero
	cp (xwa + 1), 0x0
	jrl nz, Floppy_SetHLFF9A_RetZero
	cp (xwa + 2), 0x4b
	jrl nz, Floppy_SetHLFF9A_RetZero
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 70)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 1:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 74)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 2:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 78)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 3:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 82)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 4:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 86)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jrl lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 5:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 90)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jr lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 6:i3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ld xwa, (3186:16)
	ld xbc, (xsp + 94)
	ld XIX, (xsp + 0x0406)
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jr lt, FloppyCtrl_LoadIzAndContinue
	ld wa, 7:i3
	calr NoteEventBuffer_Store
	ld xix, (3222:16)
	ld xiy, (FLASH_SECTION_PTR_7:16)
	ldw bc, 0x8000
	ldirw
	ld xwa, (3222:16)
	ld XIX, (xsp + 0x0406)
	ld xbc, 0xf400
	call (xix)
	ld XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cp iz, 0:i3
	jr lt, FloppyCtrl_LoadIzAndContinue
	ld xbc, (3222:16)
	ld xde, (FLASH_SECTION_PTR_7:16)
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
	ld xbc, (FLASH_SECTION_PTR_0:16)
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
	ld xde, (FLASH_SECTION_PTR_1:16)
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
	ld xde, (FLASH_SECTION_PTR_2:16)
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
	ld xde, (FLASH_SECTION_PTR_3:16)
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
	ld xix, (FLASH_SECTION_PTR_4:16)
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
	ld xix, (FLASH_SECTION_PTR_5:16)
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
	ld xix, (FLASH_SECTION_PTR_6:16)
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
	ld xwa, (FLASH_SECTION_PTR_7:16)
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
	lda	xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld	xde, xwa
	lda	xbc, (SEQ_SONG_SLOTS:24)
	sub	xbc, xde
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cp	iz, 0:i3
	jr	nz, ToneParam_ExtendedOpsBlock_Skip
	calr	AccPatch_ConvertLegacyStyleImage
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
; AccPatch_ConvertLegacyStyleImage: Checks the 3-byte header of the style image just read to (RHYTHM_PATTERN_BUF_PTR)
;   and brings older formats up to date: 'G',0,'K' or 'L','K','E' is relabelled 'H',0,'K' (the current header, cf.
;   AccPatch_EnsureStyleImageHeader) and kept; 'F',0,'K', 'F',' ','K', 'L','K','A' or 'L','K','B' is converted into
;   the current layout (AccPatch_ConvertLegacySectionLayout); anything else rebuilds the default image
;   (AccDemo_InitDone) and returns 0xFF9A; finally fixes up the 30 records (AccPatch_ResetSectionPartByte2Defaults).
;   Basis: callers + body -- ToneParam_ExtendedOpsBlock is the composer-data load path FileIO_LoadRegion3_ExtMem takes
;   when the file's region signature does not match (FileIO_CheckRegionSignature = 0): it reads the block between
;   cmp_ld_mae and cmp_ld_ato and calls this.
AccPatch_ConvertLegacyStyleImage:
	pushw	iz
	ld	iz, 0:i3
	calr	Flash_InitExtMemAddrs
	ld	xde, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	a, (xde)
	ldfr_berp	a, 238
	lda	xwa, (xde+1)
	ld	h, (xwa)
	lda	xbc, (xde+2)
	ld	l, (xbc)
	cp_erpb 238, 71
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip3
	cp h, 0:i3
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip3
	cp	l, 75
	jr	z, AccPatch_ConvertLegacyStyleImage_Skip4
AccPatch_ConvertLegacyStyleImage_Skip3:
	cp_erpb 238, 76
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip5
	cp h, 75
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip5
	cp	l, 69
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip5
AccPatch_ConvertLegacyStyleImage_Skip4:
	ld	(xde), 72
	ld	(xwa), 0
	ld	(xbc), 75
	cp	(xde+0x10), 0
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip11
	ld	wa, 0:i3
	jr	AccPatch_ConvertLegacyStyleImage_Join
AccPatch_ConvertLegacyStyleImage_Skip5:
	cp_erpb 238, 70
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip6
	cp h, 0:i3
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip6
	cp	l, 75
	jr	z, AccPatch_ConvertLegacyStyleImage_Skip9
AccPatch_ConvertLegacyStyleImage_Skip6:
	cp_erpb 238, 70
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip7
	cp h, 32
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip7
	cp	l, 75
	jr	z, AccPatch_ConvertLegacyStyleImage_Skip9
AccPatch_ConvertLegacyStyleImage_Skip7:
	cp_erpb 238, 76
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip8
	cp h, 75
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip8
	cp	l, 65
	jr	z, AccPatch_ConvertLegacyStyleImage_Skip9
AccPatch_ConvertLegacyStyleImage_Skip8:
	cp_erpb 238, 76
	jr nz, AccPatch_ConvertLegacyStyleImage_Skip10
	cp h, 75
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip10
	cp	l, 66
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip10
AccPatch_ConvertLegacyStyleImage_Skip9:
	calr	AccPatch_ConvertLegacySectionLayout
	ld	iz, hl
	ld	xwa, (3186:16)
	cp	(xwa+0x10), 0
	jr	nz, AccPatch_ConvertLegacyStyleImage_Skip11
	ld	wa, iz
AccPatch_ConvertLegacyStyleImage_Join:
	calr	AccPatch_LoadIntroFillEndingFromRhythm
	ld	iz, hl
	jr	AccPatch_ConvertLegacyStyleImage_Skip11
AccPatch_ConvertLegacyStyleImage_Skip10:
	call	AccDemo_InitDone
	ldw	iz, 0xff9a
AccPatch_ConvertLegacyStyleImage_Skip11:
	calr	AccPatch_ResetSectionPartByte2Defaults
	ld	hl, iz
	popw	iz
	ret
; AccPatch_ConvertLegacySectionLayout: Converts a style image in the older 20-section layout to the current 30-section
;   one: copies the image as read (RHYTHM_PATTERN_BUF_PTR) into the work buffer (word 0x0C72 = 0x69800) -- header byte
;   +16, the 20 section records at +0x60, the pattern data moved from +0x800 to +0x1400 -- then copies each old
;   section into its new place(s) in the live image (ToneParam_ExtendedOpsBlock_Helper3, 0x39AC old -> 0x39AD new):
;   variations 0-11 one to one, old 12-15 (intro, fill-in 1/2, ending) into both the A (12-17) and B (18-23) sets, old
;   16-19 into the C set (24-29), intros and endings into both 1 and 2; HL = 0xFF95 if a copy failed (that section is
;   re-initialised), else 0. Basis: callers + body -- AccPatch_ConvertLegacyStyleImage calls it for the headers
;   'F',0,'K' / 'F',' ','K' / 'L','K','A' / 'L','K','B' ("converted into the current layout"); the targets follow the
;   30 section names.
AccPatch_ConvertLegacySectionLayout:
	dec	6, xsp
	ldw	(xsp+0x4), 0
	ld	xhl, (RHYTHM_PATTERN_BUF_PTR:16)
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
	ld	(0x39ae:16), xwa
	ld	xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x39b2:16), xwa
	ld	xwa, 0:i3
	ld	(xsp), xwa
AccPatch_ConvertLegacySectionLayout_Loop:
	ld	xwa, (xsp)
	ld	(0x39ac:16), a
	ld	(0x39ad:16), a
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip12
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip12:
	ld	xwa, 1:i3
	add	(xsp), xwa
	ld	xwa, (xsp)
	cp	xwa, 11
	jr	ule, AccPatch_ConvertLegacySectionLayout_Loop
	ld	(0x39ac:16), 12
	ld	(0x39ad:16), 12
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip13
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip13:
	ld	(0x39ac:16), 13
	ld	(0x39ad:16), 14
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip14
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip14:
	ld	(0x39ac:16), 14
	ld	(0x39ad:16), 15
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip15
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip15:
	ld	(0x39ac:16), 15
	ld	(0x39ad:16), 16
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip16
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip16:
	ld	(0x39ac:16), 16
	ld	(0x39ad:16), 24
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip17
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip17:
	ld	(0x39ac:16), 17
	ld	(0x39ad:16), 26
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip18
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip18:
	ld	(0x39ac:16), 18
	ld	(0x39ad:16), 27
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip19
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip19:
	ld	(0x39ac:16), 19
	ld	(0x39ad:16), 28
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip20
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip20:
	ld	(0x39ac:16), 12
	ld	(0x39ad:16), 18
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip21
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip21:
	ld	(0x39ac:16), 13
	ld	(0x39ad:16), 20
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip22
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip22:
	ld	(0x39ac:16), 14
	ld	(0x39ad:16), 21
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip23
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip23:
	ld	(0x39ac:16), 15
	ld	(0x39ad:16), 22
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip24
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip24:
	ld	(0x39ac:16), 12
	ld	(0x39ad:16), 13
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip25
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip25:
	ld	(0x39ac:16), 15
	ld	(0x39ad:16), 17
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip26
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip26:
	ld	(0x39ac:16), 16
	ld	(0x39ad:16), 25
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip27
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip27:
	ld	(0x39ac:16), 19
	ld	(0x39ad:16), 29
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip28
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip28:
	ld	(0x39ac:16), 12
	ld	(0x39ad:16), 19
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip29
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip29:
	ld	(0x39ac:16), 15
	ld	(0x39ad:16), 23
	calr	ToneParam_ExtendedOpsBlock_Helper3
	cp	hl, 0:i3
	jr	z, AccPatch_ConvertLegacySectionLayout_Skip30
	ld	(xsp+4), hl
AccPatch_ConvertLegacySectionLayout_Skip30:
	ld	hl, (xsp+4)
	inc	6, xsp
	ret
ToneParam_ExtendedOpsBlock_Helper3:
	pushw	iz
	ld	iz, 0:i3
	res	0, (0x35b0:16)
	call	DualVoice_ParamLoadDone
	ld	a, (0x35b0:16)
	extz	wa
	bit	0, wa
	jr	z, ToneParam_ExtendedOpsBlock_Epilogue
	ld	xwa, (0x39b2:16)
	ld	(0x39ae:16), xwa
	ldmm8	0x39ac, 0x39ad
	call	AccPatch_InitFromSlotIndex
	ld	xwa, (3186:16)
	ld	(0x39ae:16), xwa
	ldw	iz, 0xff95
ToneParam_ExtendedOpsBlock_Epilogue:
	ld	hl, iz
	popw	iz
	ret
; AccPatch_ResetSectionPartByte2Defaults: Writes byte 2 of the four 8-byte accompaniment-part entries
;   (+32/+40/+48/+56) of all 30 section records of the style image at (RHYTHM_PATTERN_BUF_PTR) to 64, 12, 116, 64 --
;   the values the 'clear' section template AccPatch_DefaultSlotData holds there; what byte 2 means is not
;   established. Basis: callers + body -- AccPatch_ConvertLegacyStyleImage runs it last on every path (relabelled,
;   converted or rebuilt default image) when an older-format style image is loaded; the composer single-load path
;   (FileIO_ByteBlock_DemoProc1_Helper3) writes the same four values into sections taken from a file whose header is
;   not 'H',0,'K'.
AccPatch_ResetSectionPartByte2Defaults:
	ld	l, 0:opc
	ld	de, 0:i3
AccPatch_ResetSectionPartByte2Defaults_Loop:
	ld	wa, de
	add	wa, 96
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xbc, (xbc+wa)
	ld (xbc+34), 64
	ld bc, wa
	ld xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xwa, (xwa+bc)
	ld (xwa+42), 12
	ld	xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xwa, (xwa+bc)
	ld (xwa+50), 116
	ld xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	lda	xwa, (xwa+bc)
	ld (xwa+58), 64
	inc 1, l
	add de, 96
	cp	l, 30
	jr	c, AccPatch_ResetSectionPartByte2Defaults_Loop
	ret
; AccPatch_LoadIntroFillEndingFromRhythm: Rebuilds the intro 1/2, fill-in 1/2 and ending 1/2 sections of the A, B and
;   C groups (12-17, 18-23, 24-29) from the rhythm recorded in word +16 of the group's variation-1 section (sections
;   0, 4, 8: image bytes +0x70, +0x1F0, +0x370 into 0x34ED/0x34EE): for each it sets 0x34EF = part (4/5 intro, 10/11
;   fill-in, 6/7 ending) and 0x34D6 = target section and calls ToneParam_ExtendedOpsBlock_Helper4
;   (AccPat_DispatchNoteChange: a ROM rhythm below 0x80 via RhythmROM_PatternDispatcher, 0x80-0x9F a copy of that
;   section); saves and restores 0x34ED-0x34EF; returns the incoming status in HL, or 0xFF95 once a section fails.
;   Basis: callers + body -- AccPatch_ConvertLegacyStyleImage calls it after relabelling or converting an older-format
;   image whose header byte +16 is 0; the part/section pairs match the section-name order (12 a-intro 1, 14 a-fill in
;   1, 16 a-ending 1).
AccPatch_LoadIntroFillEndingFromRhythm:
	push	xiz
	ld	hl, wa
	ld	c, (0x34ed:16)
	ldfr_berp c, 251
	ld c, (13550:16)
	ldfr_berp c, 250
	ld	c, (0x34ef:16)
	ldfr_berp	c, 249
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x34ed), (xbc+0x70)
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x34ee), (xbc+0x71)
	ld	(0x34ef:16), 4
	ld	(0x34d6:16), 12
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 5
	ld	(0x34d6:16), 13
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 6
	ld	(0x34d6:16), 16
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 7
	ld	(0x34d6:16), 17
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 10
	ld	(0x34d6:16), 14
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 11
	ld	(0x34d6:16), 15
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x34ed), (xbc+0x1f0)
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x34ee), (xbc+0x1f1)
	ld	(0x34ef:16), 4
	ld	(0x34d6:16), 18
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 5
	ld	(0x34d6:16), 19
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 6
	ld	(0x34d6:16), 22
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 7
	ld	(0x34d6:16), 23
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 10
	ld	(0x34d6:16), 20
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 11
	ld	(0x34d6:16), 21
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x34ed), (xbc+0x370)
	ld	xbc, (RHYTHM_PATTERN_BUF_PTR:16)
	ld	(0x34ee), (xbc+0x371)
	ld	(0x34ef:16), 4
	ld	(0x34d6:16), 24
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 5
	ld	(0x34d6:16), 25
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 6
	ld	(0x34d6:16), 28
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 7
	ld	(0x34d6:16), 29
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 10
	ld	(0x34d6:16), 26
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ld	(0x34ef:16), 11
	ld	(0x34d6:16), 27
	ld	wa, hl
	calr	ToneParam_ExtendedOpsBlock_Helper4
	ldto_berp c, 251
	ld (13549:16), c
	ldto_berp c, 250
	ld (13550:16), c
	ldto_berp c, 249
	ld (13551:16), c
	pop xiz
	ret
ToneParam_ExtendedOpsBlock_Helper4:
	pushw	iz
	ld	iz, wa
	set	0, (0x34d1:16)
	call	AccPat_IndexToAddress_Sub
	ldb_d8	a, (0x35b0)
	extz	wa
	bit	0, wa
	jr	z, ToneParam_ExtendedOpsBlock_Epilogue2
	ldw	iz, 0xff95
ToneParam_ExtendedOpsBlock_Epilogue2:
	ld	hl, iz
	popw	iz
	ret

DualVoice_LoadAndScan:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xde
	ld (xsp + 12), c
	ld (xsp + 14), a
	ld (xsp + 4), 0x0
	ld (xsp + 10), 0x0
	calr Flash_InitExtMemAddrs
	ld (RHYTHM_PATTERN_BUF_PTR:16), xiz
	cp (xsp + 14), 0xa
	jrl nc, DualVoice_LoadDoneRetVal
	ld a, (xsp + 14)
	extz wa
	calr DualVoice_ScanAllColumns
	ld a, (xsp + 12)
	extz wa
	calr DualVoice_ScanAllColumnsAlt
	ld a, (xsp + 12)
	extz wa
	calr NoteEvent_Store
	ld (xsp + 6), l
	ld a, (xsp + 6)
	extz wa
	calr NoteEventBuffer_CopyToSlot
	call AccPatch_CountSlotsAlt
	ld a, (xsp + 12)
	extz wa
	lda xbc, (MSP_Default_GroupIndexPad:24)
	ld	a, (xbc+wa)
	ld (xsp + 8), a
	ld xwa, (3186:16)
	ld (0x39ae:16), xwa
	ldib_erp 0xfb, 0

DualVoice_AccPatchLoop:
	ld c, (xsp + 8)
	extz bc
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda xwa, (MSP_Default_ChannelMap:24)
	ld	(0x39ac:16), (xwa+de)
	call AccPatch_InitFromSlotIndex
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, DualVoice_AccPatchLoop
	ld xwa, (RHYTHM_PATTERN_BUF_PTR:16)
	ld (0x39ae:16), xwa
	ld xwa, (3186:16)
	ld (0x39b2:16), xwa
	res 0, (0x35b0:16)
	ldib_erp 0xfb, 0

DualVoice_ParamCompareLoop:
	ld e, (xsp + 14)
	extz de
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld bc, wa
	add wa, de
	lda xde, (MSP_Default_ChannelMap:24)
	ld	(0x39ac:16), (xde+wa)
	ld a, (xsp + 8)
	extz wa
	add bc, wa
	ld	(0x39ad:16), (xde+bc)
	call DualVoice_ParamLoadDone
	ld a, (0x35b0:16)
	extz wa
	bit 0, wa
	jr z, DualVoice_LoopCheckNext
	ld (xsp + 10), 0x1

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
; FileIO_LoadMspAltFormat: Loads an .MSP file whose header fails the native signature check: between msp_ld_mae and
;   msp_ld_ato reads it into 0x1E8800..0x1EC400, then FileHdr_ValidateSignature converts 'G',0,'K' / 'LKE' / 'MKB'
;   files to the native layout (moves +0x100.. up 512 bytes, zero-fills the gap, writes the native header); HL = read
;   result. Basis: callers + body -- FileIO_LoadRegion5_VRAM (.MSP, extension index 5) runs it when
;   FileIO_CheckRegionSignature(5) fails, in place of its plain read between the same hooks.
FileIO_LoadMspAltFormat:
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
	ld xwa, (MSP_SETTINGS:16)
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
	ld (MSP_SETTINGS:16), xwa
	ret

ToneData_SetupCopyPointers:
	ld xbc, (MSP_SETTINGS:16)
	lda xbc, (xbc+256)
	ld xwa, xbc
	lda xbc, (xbc+512)

ToneData_ZeroFillLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, ToneData_ZeroFillLoop

	lda xwa, (Composer_SettingsBlock:24)
	ld xbc, xwa
	ld xde, (MSP_SETTINGS:16)
	lda xhl, (xwa + 6)

ToneData_CopyBlock1_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock1_Loop
	lda xhl, (Composer_DefaultHeaderFields:24)
	ld xbc, xhl
	ld xwa, (MSP_SETTINGS:16)
	lda xde, (xwa + 16)
	lda xhl, (xhl + 16)

ToneData_CopyBlock2_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock2_Loop
	lda xhl, (MSP_Default_PartBankMap:24)
	ld xbc, xhl
	ld xwa, (MSP_SETTINGS:16)
	lda xde, (xwa+512)
	lda xhl, (xhl + 64)

ToneData_CopyBlock3_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock3_Loop
	lda xhl, (Composer_DefaultCompileBankNames:24)
	ld xbc, xhl
	ld xwa, (MSP_SETTINGS:16)
	lda xde, (xwa+576)
	lda xhl, (xhl + 64)

ToneData_CopyBlock4_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock4_Loop
	lda xhl, (Composer_DefaultUserBankNames:24)
	ld xbc, xhl
	ld xwa, (MSP_SETTINGS:16)
	lda xde, (xwa+640)
	lda xhl, (xhl + 64)

ToneData_CopyBlock5_Loop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, ToneData_CopyBlock5_Loop
	ld xwa, (MSP_SETTINGS:16)
	lda xbc, (xwa + 32)
	ld xde, 0:i3

ToneData_ScanRegionLoop:
	cp (xbc), 0x0
	jr nz, ToneData_AdvanceRegion
	lda xiy, (Composer_DefaultEmptyRecord:24)
	ld xhl, xiy
	ld xwa, (MSP_SETTINGS:16)
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
	lda xsp, (xsp - 14)

	RegObjTable NAKA_CLASS_Class, ClassProc, Suna_ClassCount_164, Suna_ClassTable_164, 0x164
	RegObjTable NAKA_CLASS_ResEvent, ResEventProc, Suna_ResEventCount_1C4, Suna_ResEventTable_1C4, 0x1c4
	RegObjTable NAKA_CLASS_ResMethod, ResMethodProc, Suna_ResMethodCount_1E4, NakaMethodTable_PtrsStart, 0x1e4
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x49, Composer_FunctionTable, 0x124
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x49, Composer_CallbackNameTable, 0x424
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x1, Suna_FunctionTable_104, 0x104
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x1, Suna_FunctionTable_404, 0x404
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x24, Suna_MainFunctionTable_144, 0x144
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x24, PtrTbl_FuncNameStrs, 0x444
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x3, Suna_ViewableTable_010, 0x10
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x3, Naka_Accomp14_Screens, 0x310
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, Suna_ViewableTable_011, 0x11
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, Naka_StylCnvWait_Screens, 0x311
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x7, Suna_ViewableTable_012, 0x12
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x7, Naka_StylCnvVer_Screens, 0x312
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, Suna_ViewableTable_013, 0x13
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, Suna_ResNameTable_313, 0x313
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, Suna_ViewableTable_014, 0x14
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, Suna_ResNameTable_314, 0x314
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, Suna_ViewableTable_015, 0x15
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, Naka_StylCnvTxt_Screens, 0x315
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x7, Suna_ViewableTable_016, 0x16
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x7, Suna_ResNameTable_316, 0x316
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x12, Suna_ViewableTable_0B0, 0xb0
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x12, Suna_ResNameTable_3B0, 0x3b0
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Suna_ViewableTable_0B1, 0xb1
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, Naka_CmpMenu_Screens, 0x3b1
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x16, Suna_ViewableTable_0B2, 0xb2
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x16, Suna_ResNameTable_3B2, 0x3b2
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x5, Suna_ViewableTable_0B3, 0xb3
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x5, Suna_ResNameTable_3B3, 0x3b3
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x12, Suna_ViewableTable_0B4, 0xb4
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x12, Naka_NamingMem_Screens, 0x3b4
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1f, Suna_ViewableTable_0B5, 0xb5
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1f, Naka_CmSetP1Grid_Screens, 0x3b5
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Suna_ViewableTable_0B6, 0xb6
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Suna_ResNameTable_3B6, 0x3b6
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, Suna_ViewableTable_0B7, 0xb7
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, Naka_CmpMem_Screens, 0x3b7
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x21, Suna_ViewableTable_0B8, 0xb8
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x21, PtrTbl_CmpNcpScreenStrs, 0x3b8
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x25, Naka_SeqToComposer_Screens, 0xb9
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x25, PtrTbl_S2cScreenStrs, 0x3b9
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xe, Naka_EasyComposer_Screens, 0xba
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xe, PtrTbl_EasyCompScreenStrs, 0x3ba
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, Naka_EasyComposer2_Screens, 0xbb
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, PtrTbl_BendScreenStrs, 0x3bb
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xb, Naka_ModeSelect_Screens, 0xbd
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xb, Suna_ResNameTable_3BD, 0x3bd
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x21, Naka_ExpandMode_Screens, 0xbe
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x21, PtrTbl_CstmCpScreenStrs, 0x3be
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1b, Naka_Accomp7_Screens, 0xc8
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1b, PtrTbl_MspBkslScreenStrs, 0x3c8
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, Suna_ViewableTable_C9, 0xc9
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, Suna_ResNameTable_3C9, 0x3c9
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, Naka_Accomp9_Screens, 0xca
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, PtrTbl_MspMenuScreenStrs, 0x3ca
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, Naka_Accomp10_Screens, 0xcb
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, Suna_ResNameTable_3CB, 0x3cb
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x9, Naka_Accomp11_Screens, 0xcc
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x9, PtrTbl_MspReGrpScreenStrs, 0x3cc
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, Naka_Accomp12_Screens, 0xdc
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, PtrTbl_SndArgrScreenStrs, 0x3dc
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, Naka_Accomp13_Screens, 0xed
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, PtrTbl_ApcSelScreenStrs, 0x3ed

	RegMode 0x4, InitializeSuna_Str_MD_CMP, 0xe, NAKA_MAINFUNC_CmpModeFunc, TITLE_CMMENU
	RegMode 0x4, InitializeSuna_Str_MD_MSP, 0xf, NAKA_APFUNC_DefaultFunction, TITLE_MSPMENU
	RegMode 0x4, InitializeSuna_Str_MD_MSP_REC, 0x10, NAKA_APFUNC_DefaultFunction, TITLE_MSPREC
	RegMode 0x4, InitializeSuna_Str_MD_SND_ARG, 0x11, NAKA_MAINFUNC_SndArgModeFunc, TITLE_SNDARG

	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVWAIT, 0x10, NAKA_MAINFUNC_StylCnvWaitTtlFunc, 0x100000
	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVMODL, 0x11, NAKA_MAINFUNC_StylCnvModlTtlFunc, 0x110000
	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVCNVT, 0x12, NAKA_MAINFUNC_StylCnvCnvtTtlFunc, 0x120000
	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVSTOR, 0x13, NAKA_MAINFUNC_StylCnvStorTtlFunc, 0x130000
	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVTXT, 0x14, NAKA_MAINFUNC_StylCnvTxtTtlFunc, 0x140000
	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVSEL, 0x15, NAKA_MAINFUNC_StylCnvSelTtlFunc, 0x150000
	RegTitle 0x4, InitializeSuna_Str_TT_STYLCNVCONT, 0x16, NAKA_MAINFUNC_StylCnvContTtlFunc, 0x160000
	RegTitle 0x4, InitializeSuna_Str_TT_CMMENU, 0xb0, NAKA_MAINFUNC_CmpMenuTtlFunc, 0xb00000
	RegTitle 0x4, InitializeSuna_Str_TT_CMBKSL, 0xb1, NAKA_MAINFUNC_CmpBkslTtlFunc, 0xb10000
	RegTitle 0x4, InitializeSuna_Str_TT_CMBKSL_S, 0xb2, NAKA_MAINFUNC_CmpBksl_STtlFunc, 0xb20000
	RegTitle 0x4, InitializeSuna_Str_TT_CMNAME, 0xb3, NAKA_APFUNC_DefaultFunction, 0xb30000
	RegTitle 0x4, InitializeSuna_Str_TT_CMSET, 0xb4, NAKA_MAINFUNC_CmpSetTtlFunc, 0xb40000
	RegTitle 0x4, InitializeSuna_Str_TT_CMREAL, 0xb5, NAKA_MAINFUNC_CmpRealTtlFunc, 0xb50000
	RegTitle 0x4, InitializeSuna_Str_TT_CMSTEP, 0xb6, NAKA_MAINFUNC_CmpStepTitleFunc, 0xb60000
	RegTitle 0x4, InitializeSuna_Str_TT_CMBAL, 0xb7, NAKA_APFUNC_DefaultFunction, 0xb70000
	RegTitle 0x4, InitializeSuna_Str_TT_CMPNCP, 0xb8, NAKA_MAINFUNC_CmpNcpTtlFunc, 0xb80000
	RegTitle 0x4, InitializeSuna_Str_TT_CMSEQCP, 0xb9, NAKA_MAINFUNC_S2cTtlFunc, 0xb90000
	RegTitle 0x4, InitializeSuna_Str_TT_CMEASY, 0xba, NAKA_MAINFUNC_CmEsyTtlFunc, 0xba0000
	RegTitle 0x4, InitializeSuna_Str_TT_CMBEND, 0xbb, NAKA_APFUNC_DefaultFunction, 0xbb0000
	RegTitle 0x4, InitializeSuna_Str_TT_CMMODE, 0xbd, NAKA_APFUNC_DefaultFunction, 0xbd0000
	RegTitle 0x4, InitializeSuna_Str_TT_CMCSTMCP, 0xbe, NAKA_MAINFUNC_CstmCpTtlFunc, 0xbe0000
	RegTitle 0x4, InitializeSuna_Str_TT_MSPBKSL, 0xc8, NAKA_MAINFUNC_MspBkslTtlFunc, 0xc80000
	RegTitle 0x4, InitializeSuna_Str_TT_MSPREC, 0xc9, NAKA_MAINFUNC_MspRecTtlFunc, 0xc90000
	RegTitle 0x4, InitializeSuna_Str_TT_MSPMENU, 0xca, NAKA_MAINFUNC_MspMenuTtlFunc, 0xca0000
	RegTitle 0x4, InitializeSuna_Str_TT_MSPNAME, 0xcb, NAKA_MAINFUNC_MspNameTtlFunc, 0xcb0000
	RegTitle 0x4, InitializeSuna_Str_TT_MSPGROUP, 0xcc, NAKA_APFUNC_DefaultFunction, 0xcc0000
	RegTitle 0x4, InitializeSuna_Str_TT_SNDARG, 0xdc, NAKA_MAINFUNC_SndArgTtlFunc, 0xdc0000
	RegTitle 0x4, InitializeSuna_Str_TT_APCSEL, 0xed, NAKA_APFUNC_DefaultFunction, NAKA_VIEW_ApcSelScreen

	lda xsp, (xsp + 14)
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
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr CmpBndRng_PopIzRet

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
	jrl z, AcCmpSetGridBoxProc_ForwardToApFunc
	ld xwa, (xsp + 16)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcCmpSetGridBoxProc_OnGetFixedRowStr
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, CmpSetP1_GridCheckDispatch
	cp xwa, EVT_SHOW
	jr z, CmpSetP1_DialGrid
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, AcCmpSetGridBoxProc_DefaultInherited
	cp xbc, 0x6
	jrl gt, AcCmpSetGridBoxProc_DefaultInherited
	add xbc, xbc
	add xbc, AcCmpSetGridBoxProc_CaseTable
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
AcCmpSetGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
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
	lda xbc, (CmpSetP1_DialGrid_Data:24)
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
AcCmpSetGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
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
	lda xbc, (CmpSetP1_SendAndApplyFunc_Data:24)
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
AcCmpSetGridBoxProc_OnGetFixedRowStr:
	ld xwa, xiz
	ld xiz, 0x42

; CmpSetP1 grid check case 2
CmpSetP1_GridCheck_Case2:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CmpSetP1_ReturnZeroJmp

; CmpSetP1 grid check case 3
; AcCmpSetGridBoxProc_ForwardToApFunc: EVT_REQUEST_GRID_DRAW, EVT_LSW_DATA and EVT_RAM_DATA are passed on to the
;   grid's ApFunction (instance +70).
AcCmpSetGridBoxProc_ForwardToApFunc:
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
AcCmpSetGridBoxProc_DefaultInherited:
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
	jrl z, CmpSetP1GridCheck_OnRequestGridDraw
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, Widget_PostEvtReturnZero
	cp xwa, 0x6
	jrl gt, Widget_PostEvtReturnZero
	add xwa, xwa
	add xwa, CmpSetP1GridCheck_CaseTable
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
CmpSetP1GridCheck_OnIndexswDown:	; cases 29360152, 29360154
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
CmpSetP1GridCheck_OnRequestGridDraw:
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
	lda xix, (CmpSetP1_GridCheck_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (UI_COMPONENT_DISPATCH:24)
	jp	t, (xix+wa)
; UI component dispatch table - handles cases 0-7 for grid/focus handling
; Offset table at 0xe1cef0 selects which handler to run based on WA value
UI_COMPONENT_DISPATCH:
	ld a, (0x34d7:16); Load byte from UI state
	inc	1, a	; Increment by 1
	extz	wa	; Zero-extend A to WA
	pushw	wa	; Push WA as parameter
	pushw	UI_COMPONENT_DISPATCH_Str_Fmtd@hi16	; Push parameter
	pushw	UI_COMPONENT_DISPATCH_Str_Fmtd@lo16	; Push parameter
	push xde
	call	Sprintf_Locked	; Call handler function
	lda	xsp, (xsp + 10)	; Clean up stack (10 bytes)
	jrl	WidgetHandler_PostEventAndReturnZero	; Jump to end
UI_COMPONENT_DISPATCH_CASE1:
	ld a, (0x34ce:16); Load byte from UI state
	srl	a, 7	; Shift right logical by 7
	extz	wa	; Zero-extend A to WA
	sla	wa, 2	; Shift left by 2 (multiply by 4)
	lda xbc, (0x03d9f6:24); Load table address
	ld	xwa, (xbc+wa)	; Load entry from table
	push	xwa	; Push parameter
	ld a, (0x34d8:16); Load byte from UI state
	extz	wa	; Zero-extend A to WA
	sla	wa, 2	; Shift left by 2 (multiply by 4)
	lda xbc, (0x03da0e:24); Load table address
	ld	xwa, (xbc+wa)	; Load entry from table
	push	xwa	; Push parameter
	pushw	UI_COMPONENT_DISPATCH_CASE1_Str_Fmts_Fmts@hi16	; Push parameter
	pushw	UI_COMPONENT_DISPATCH_CASE1_Str_Fmts_Fmts@lo16	; Push parameter
	push xde
	call	Sprintf_Locked	; Call handler function
	lda	xsp, (xsp + 16)	; Clean up stack (16 bytes)
	jr	WidgetHandler_PostEventAndReturnZero	; Jump to end
UI_COMPONENT_DISPATCH_CASE2:
	ld c, (0x34e9:16); Load byte from UI state
	ld	xwa, 0x3d9c6	; Load table address
	jr	UI_COMPONENT_DISPATCH_CASE2_COMMON	; Jump to common code
UI_COMPONENT_DISPATCH_CASE3:
	ld a, (0x34ea:16); Load byte from UI state
	srl	a, 4	; Shift right logical by 4
	and	a, 0x1	; Mask to get bit 4
	ld	c, a	; Copy to C
	ld	xwa, 0x3d9fe	; Load table address
UI_COMPONENT_DISPATCH_CASE2_COMMON:
	extz	bc	; Zero-extend C to BC
	sla	bc, 2	; Shift left by 2 (multiply by 4)
	ld	xwa, (xwa+bc)	; Load entry from table
	push	xwa	; Push parameter
	jr	UI_COMPONENT_DISPATCH_PUSH_CALL	; Jump to push and call
UI_COMPONENT_DISPATCH_CASE4:
	ld	wa, 6:i3	; Load 6
	jr	UI_COMPONENT_DISPATCH_CASE5_COMMON	; Jump to common code
UI_COMPONENT_DISPATCH_CASE5:
	ld	wa, 5:i3	; Load 5
UI_COMPONENT_DISPATCH_CASE5_COMMON:
	ld c, (0x34ea:16); Load byte from UI state
	and	a, 0xf	; Mask lower nibble
	jr	z, UI_COMPONENT_DISPATCH_CASE5_SKIP	; Skip shift if zero
	srla	c	; Shift A right by C
UI_COMPONENT_DISPATCH_CASE5_SKIP:
	and	c, 0x1	; Mask C to get bit 0
	extz	bc	; Zero-extend C to BC
	sla	bc, 2	; Shift left by 2 (multiply by 4)
	ld	xwa, (xhl+bc)	; Load entry from table
	push	xwa	; Push parameter
UI_COMPONENT_DISPATCH_PUSH_CALL:
	push xde
	call	Sprintf_Locked	; Call handler function
	inc	8, xsp	; Increment stack pointer

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
	add xwa, CmpSetGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (GridCheck_Handler0:24)
	jp	t, (xix+wa)

; =============================================================================
; GridCheck_Handler0 - Grid/Check widget handler for cases 0 and 2
; Called via jump table when event code is 0x1c00017 + (0 or 2)
; Queries UI object state and sends appropriate event (0x01e40008 or 0x01e4000a)
; =============================================================================
GridCheck_Handler0:
	call	GetFocusObject	; Get UI object
	ld	xwa, xhl	; Save result in XWA
	ld	xbc, EVT_GET_SELECTED_CEL	; Event code for query
	ld	xde, 0:i3	; Parameter = 0
	call	SendEvent	; Query object state
	ld	xde, xhl	; Result in XDE
	lda	xwa, (xsp + 14)	; Get local var pointer
	ld	xbc, xde	; Copy result to XBC
	srl	xbc, 16	; SRL 0, XBC (clear carry)
	ldiw_erp	0xe6, 0	; LD QBC, 0 (clear high bits)
	ld	(xwa), bc	; Store low word
	ld	(xwa + 2), de	; Store high word
	ld	wa, (xwa)	; Load state value
	exts	xde	; Sign extend DE
	cp	wa, 2:i3	; Check if state == 2
	jr z, GridCheck_Handler0_State2
	cp	wa, 1:i3	; Check if state == 1
	jrl	nz, GridCheck_ReturnZero	; If neither, exit
	ld	xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld	xbc, EVT_PAN_UP	; Event: grid check state 1 (case 0)
	jr GridCheck_SendEvent
GridCheck_Handler0_State2:
	ld	xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld	xbc, EVT_RLMT_UP	; Event: grid check state 2 (case 0)
	jr GridCheck_SendEvent

; =============================================================================
; GridCheck_Handler1 - Grid/Check widget handler for cases 1 and 3
; Called via jump table when event code is 0x1c00017 + (1 or 3)
; Queries UI object state and sends appropriate event (0x01e40009 or 0x01e4000b)
; =============================================================================
GridCheck_Handler1:
	call	GetFocusObject	; Get UI object
	ld	xwa, xhl	; Save result in XWA
	ld	xbc, EVT_GET_SELECTED_CEL	; Event code for query
	ld	xde, 0:i3	; Parameter = 0
	call	SendEvent	; Query object state
	ld	xde, xhl	; Result in XDE
	lda	xwa, (xsp + 14)	; Get local var pointer
	ld	xbc, xde	; Copy result to XBC
	srl	xbc, 16	; SRL 0, XBC (clear carry)
	ldiw_erp	0xe6, 0	; LD QBC, 0 (clear high bits)
	ld	(xwa), bc	; Store low word
	ld	(xwa + 2), de	; Store high word
	ld	wa, (xwa)	; Load state value
	exts	xde	; Sign extend DE
	cp	wa, 2:i3	; Check if state == 2
	jr z, GridCheck_Handler1_State2
	cp	wa, 1:i3	; Check if state == 1
	jr	nz, GridCheck_ReturnZero	; If neither, exit
	ld	xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld	xbc, EVT_PAN_DN	; Event: grid check state 1 (case 1)
	jr GridCheck_SendEvent
GridCheck_Handler1_State2:
	ld	xwa, NAKA_MAINFUNC_MainCmpSetFunc	; Widget ID
	ld	xbc, EVT_RLMT_DN	; Event: grid check state 2 (case 1)
	; Fall through to GridCheck_SendEvent

; =============================================================================
; GridCheck_SendEvent - Common epilogue for grid/check handlers
; Sends the event in XBC with widget ID in XWA
; =============================================================================
GridCheck_SendEvent:
	call	MainFuncCall	; Send event
	jr	GridCheck_ReturnZero	; Return to caller

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
	call Sprintf_Locked
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
	ld e, (0x34d6:16)
	extz de
	sla de, 2
	lda xhl, (RhythmTiming_OffsetTable:24)
	ld xix, 0x94860
	add	xix, (xhl+de)
	sll xbc, 3
	add xbc, 0x10
	add xbc, xix
	cp a, 0:i3
	jr nz, GridCheck_ClampParamAlt
	ld l, (xbc + 2)
	cp l, 0x7f
	ret ule
	ld l, 0x7f:opc
	jr GridCheck_ClampDone

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
	call SndParam_LookupReadOnly
	lda xbc, (xiz + 34)
	ld xwa, (xbc)
	cp hl, 0:i3
	jr nz, AcApcToggle_SetOne
	ldw (xwa), 0x0
	jr AcApcToggle_SendUpdate

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
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xsp + 8)
	ld xbc, (xwa)
	lda xwa, (xhl + 44)
	cp xbc, 0x28083
	jr z, AcApcToggle_Check83Match
	cp xbc, 0x28081
	jr nz, EventHandler_Return
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, EventHandler_Return
	ld xwa, 0x28081
	call SndParam_LookupReadOnly
	ld xwa, (xsp + 8)
	cpw (xwa + 4), 0x1
	jr nz, AcApcToggle_SendZero
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	jr AcApcToggle_SendEvent

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
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, AcS2cMem_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 50)
	ldfr_berp A, 0xf8
	extz iz
	ld xwa, 0x28080
	call SndParam_LookupReadOnly
	cp hl, iz
	jr z, AcS2cMem_ReturnZeroJmp
	ld xwa, 0x28080
	ld bc, iz
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
	ld xwa, xiz
	call InheritedProc
	ld a, (0x398f:16)
	extz wa
	sla wa, 2
	lda xbc, (S2cMemNoBox_HandleScroll_Data:24)
	ld	xwa, (xbc+wa)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

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
	ld XWA, (xsp + 0x0104)
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	call GetViewInstance
	ld xiz, xhl
	push_sd16w 0x8a, 0x39
	pushw PsS2cFmeas_HandleScroll_Str_Fmt3d@hi16
	pushw PsS2cFmeas_HandleScroll_Str_Fmt3d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xbc, (xiz + 22)
	lda xwa, (xiz + 32)
	cp (0x3a77:16), 0
	jr nz, PsS2cFmeas_SetActive
	ldw (xwa), 0x0
	ldw (xbc), 0xff
	jr PsS2cFmeas_SendUpdateEvents

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
	ld XWA, (xsp + 0x0104)
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	call GetViewInstance
	ld xiz, xhl
	push_sd16w 0x8c, 0x39
	pushw PsS2cLmeas_HandleScroll_Str_Fmt3d@hi16
	pushw PsS2cLmeas_HandleScroll_Str_Fmt3d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xbc, (xiz + 22)
	lda xwa, (xiz + 32)
	cp (0x3a77:16), 1
	jr nz, PsS2cLmeas_SetActive
	ldw (xwa), 0x0
	ldw (xbc), 0xff
	jr PsS2cLmeas_SendUpdateEvents

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
	ld xwa, xiz
	call InheritedProc
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	pushw wa
	pushw PsSeqSongNo_HandleScroll_Str_SONG_Fmt2d@hi16
	pushw PsSeqSongNo_HandleScroll_Str_SONG_Fmt2d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld xhl, 0:i3

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
	ld XWA, (xsp + 0x0104)
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x398e:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_TransposeStrs:24)
	ld	xwa, (xbc+wa)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cp (0x3a77:16), 2
	jr nz, SndArg_GridBnk_Case0
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr SndArg_GridBnk_Case1

; SndArgGridBnk case 0
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
	jrl z, S2cGridBoxProc_OnClrGridHanten
	cp xiz, EVT_REQUEST_GRID_DRAW
	jrl z, S2cGridBoxProc_ForwardToApFunc
	cp xiz, EVT_GET_FIXED_ROW_STR
	jrl z, S2cGridBoxProc_OnGetFixedRowStr
	cp xiz, EVT_GET_FIXED_COL_STR
	jrl z, S2cGridBoxProc_OnGetFixedColStr
	cp xiz, EVT_SHOW
	jr z, FdcFormat_DialGrid
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, S2cGridBoxProc_DefaultInherited
	cp xwa, 0x6
	jrl gt, S2cGridBoxProc_DefaultInherited
	add xwa, xwa
	add xwa, S2cGridBoxProc_CaseTable
	ld wa, (xwa)
	lda xix, (FdcFormat_DialGrid:24)
	jp	t, (xix+wa)

; FdcFormat dial grid dispatch (7-entry, table 0xe1d728)
FdcFormat_DialGrid:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 8), xhl
	cp (0x3a77:16), 3
	jrl nz, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
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
	ld xwa, (xsp + 16)
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
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl S2cGrid_SetDialEnable
S2cGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, S2cGrid_DialDownSendApply
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FdcFormat_ReturnZeroJmp

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
S2cGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
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
; S2cGridBoxProc_OnGetFixedColStr: S2cGridBoxProc's EVT_GET_FIXED_COL_STR case: Strcpy's the fixed-column string
;   (instance +0x3E). Basis: S2cGridBoxProc compare chain + body; it is not an FDC format routine.
S2cGridBoxProc_OnGetFixedColStr:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr S2cGrid_GetViewAndCopy

; FdcFormat grid check case 1
S2cGridBoxProc_OnGetFixedRowStr:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

S2cGrid_GetViewAndCopy:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check case 2
; S2cGridBoxProc_ForwardToApFunc: EVT_REQUEST_GRID_DRAW, EVT_LSW_DATA and EVT_RAM_DATA are passed on to the grid's
;   ApFunction (instance +70).
S2cGridBoxProc_ForwardToApFunc:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check case 3
S2cGridBoxProc_OnClrGridHanten:
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
S2cGridBoxProc_DefaultInherited:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc

; FdcFormat grid check case 5
FdcFormat_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

