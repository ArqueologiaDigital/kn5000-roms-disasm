
; Sequencer Channel Containers + Drawbar/Mixer Data (13 widgets, 7936 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_channels.c (C struct with named fields)
; FDTest_ScreenView -- 1 x struct (TtlScreen view record, 42 B): the "FDD_TEST" screen (title "FD SAVE/LOAD TEST"), entry 0 of InitializeHama's Viewable table (slot 0xFC)
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3dcd4),
; so ViewableProc and the TtlScreen class proc use the RAM copy; first word = class id 0x1600034.
FDTest_ScreenView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x0, 0x2A
; FDTest_ResultCounters -- 1 x struct (3 x uint16_t): TOTAL / OK / NG counts of the FD save/load factory test
; RunTestCounters_Entry increments TOTAL before FDLoadSaveTest, then OK or NG on its result,
; and posts each count to its NAKA view (NAKA_VIEW_TOTAL / _OK / _NG) with EVT_PARA_DRAW.
FDTest_ResultCounters:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x2A, 0x6
; Xapr_PresentFlag -- 1 x struct (1 x uint8_t (+ pad byte)): 1 once an XAPR extension ROM has been found
; (RAM 0x3DD04, XAPR_PRESENT_FLAG); set and tested by the XAPR loader in factory_test/test_init.s.
Xapr_PresentFlag:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x30, 0x2
; Yoko_ViewWorkCells -- 1 x struct (165 cells): power-on values of the InitializeYoko view work cells
; SMF direct play, medley, track assign, song select, demo. Boot_InitWorkRAM copies them to RAM 0x3dd06..0x3dea2; each cell is the RAM
; target of a pointer-typed property of a view record registered by InitializeYoko and is read through it by the record's class proc
; (ScreenProc, WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit view id (0xFFFFFFFF = none);
; data/onoff/part/recplay/... (types m/n) = words; pcol/prow/crow = 32-bit heap pointers; AcRamEditBox/AcRamBox data = 32-bit values.
Yoko_ViewWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x32, 0x19C
; TrAs_OkSwitchView -- 1 x struct (VwEditSwBox view record, 44 B): the "TrAsOkSw" edit switch, entry 3 of InitializeYoko's Viewable table slot 0x8B
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3dea2),
; so ViewableProc and the VwEditSwBox class proc use the RAM copy; first word = class id 0x160003e.
TrAs_OkSwitchView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1CE, 0x2C
; TrAs_PartSelectSwitchView -- 1 x struct (AcIndexWideES view record, 42 B): the "TrAsPartSelSw" wide edit switch, entry 9 of slot 0x8B
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3dece),
; so ViewableProc and the AcIndexWideES class proc use the RAM copy; first word = class id 0x1600022.
TrAs_PartSelectSwitchView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1FA, 0x2A
; TrAsSureLang_MessagePtrTable -- 6 x uint32_t: the per-language string table TrAsSureLangCheck
; returns for EVT_GET_LANGUAGE_PTR (`lda xhl, (0x03def8:24)`), like the ROM *LangCheck_PtrTable[6]
; siblings; every entry is RAM 0x20CB4, the buffer the routine has just Sprintf_Locked the message into.
TrAsSureLang_MessagePtrTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x224, 0x18
; Kubo_FunctionTable -- 1 x uint32_t: the Function table InitializeKubo registers at slot 0x108 with
; count 0 (`RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, 0x3df10, 0x108`), so it has no entry to index.
Kubo_FunctionTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x23C, 0x4
; Kubo_FunctionNameTable -- 1 x uint32_t: the name table paired with Kubo_FunctionTable (slot 0x408,
; count 0); its one word points at the empty string Kubo_FunctionNameTable_408_EndName.
Kubo_FunctionNameTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x240, 0x4
; Kubo_ViewWorkCells -- 1 x struct (233 cells): power-on values of the InitializeKubo view work cells
; Reverb/DSP/EQ screens, sequencer menus, help windows. Boot_InitWorkRAM copies them to RAM 0x3df18..0x3e1b8; each
; cell is the RAM target of a pointer-typed property of a view record registered by InitializeKubo and is read through
; it by the record's class proc (ScreenProc, WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit
; view id (0xFFFFFFFF = none); onoff/page/part/recplay/... (types m/n) = words; pcol/prow/crow = 32-bit heap pointers.
Kubo_ViewWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x244, 0x2A0
; CycRec_ClearSwitchView -- 1 x struct (AcFuncEditSw view record, 44 B): the "CycRecClrSw" function edit switch, entry 19 of Kubo Viewable table slot 0x85
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e1b8),
; so ViewableProc and the AcFuncEditSw class proc use the RAM copy; first word = class id 0x1600020.
CycRec_ClearSwitchView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x4E4, 0x2C
; CycRec_ClearLabelView -- 1 x struct (Label view record, 32 B): the "CycRecClrStr" label ("CLEAR"), entry 20 of slot 0x85
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e1e4),
; so ViewableProc and the Label class proc use the RAM copy; first word = class id 0x160002b.
CycRec_ClearLabelView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x510, 0x20
; Kubo_VocWorkMenuView -- 1 x struct (AcTitleMenu view record, 54 B): the "VocWorkSw" title-menu item ("VOCALIST WORKSTATION"), entry 3 of slot 0xD6
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e204),
; so ViewableProc and the AcTitleMenu class proc use the RAM copy; first word = class id 0x160001d.
Kubo_VocWorkMenuView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x530, 0x36
; Kubo_FadeInOutMenuView -- 1 x struct (AcTitleMenu view record, 54 B): the "FadeInOutSw" title-menu item ("FADE IN/OUT SETTING"), entry 4 of slot 0xD6
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e23a),
; so ViewableProc and the AcTitleMenu class proc use the RAM copy; first word = class id 0x160001d.
Kubo_FadeInOutMenuView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x566, 0x36
; Kubo_MixerMenuView -- 1 x struct (AcTitleMenu view record, 54 B): the "MixerSw" title-menu item ("MIXER"), entry 5 of slot 0xD6
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e270),
; so ViewableProc and the AcTitleMenu class proc use the RAM copy; first word = class id 0x160001d.
Kubo_MixerMenuView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x59C, 0x36
; Kubo_DiskLoadMenuView -- 1 x struct (AcTitleMenu view record, 54 B): the "DiskLoadSw" title-menu item ("DISK LOAD"), entry 6 of slot 0xD6
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e2a6),
; so ViewableProc and the AcTitleMenu class proc use the RAM copy; first word = class id 0x160001d.
Kubo_DiskLoadMenuView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x5D2, 0x36
; SqedtFunc_CursorState -- 1 x struct (3 x uint8_t (each + pad)): the from-cursor and to-cursor of the sequencer edit
; value list (EVT_GET/SET_FROM_CUR, EVT_GET/SET_TO_CUR) and a 0/1 byte saying which of them SqedtVal2
; is editing (1 = to-cursor); SeqFormat_DispatchA compares the list index against the active one.
SqedtFunc_CursorState:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x608, 0x6
; FileOpen_SlotByte1Init -- 1 x struct (1 x uint8_t (+ pad), power-on 1): FileOpen_PopulateStruct copies it to byte +1
; of each new open-file slot (beside +0 = device index, +2 = 0x0D); SeqChan_ValidateAndDispatch
; returns 0 at once when it is 0.  No store to it was found.
FileOpen_SlotByte1Init:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x60E, 0x2
; FileIO_DriveAParamBlock -- 144 x uint8_t: the block the drive-A device descriptor points at (+26 =
; 0x0003E2E4); the file I/O code reaches it as handle->device->+26 and reads a word at +48 (sector
; offset added to the position), a byte at +58 (retry limit) and a long at +12.
FileIO_DriveAParamBlock:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x610, 0x90
; FileIO_DriveAFileOps -- 10 x uint32_t: code pointers, the file-level operation table of drive "A"
; (FileIO_DeviceTable +18); FileOpen calls entry 0 to open, the other file calls go through the copy
; at handle +14 with `ld xwa, (xwa + 4*k)` / `call (xwa)` (k = 1..9; SeqStep_FileCloseProcess uses k = 5).
FileIO_DriveAFileOps:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x6A0, 0x28
; FileIO_DriveABlockOps -- 8 x uint32_t: code pointers, the second operation table of drive "A"
; (FileIO_DeviceTable +14), copied to handle +10; the sector I/O paths call entries 4..7 through it
; (`ld xwa, (xwa + 10)` / `ld xwa, (xwa + 16..28)` / `call (xwa)`).
FileIO_DriveABlockOps:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x6C8, 0x20
; FileIO_DeviceTable -- 1 x struct (34 B, one device): the file-system device table FileOpen_MatchDevice walks
; (`lda xwa, (0x03e3bc:24)`, stride 0x22, FileIO_DeviceCount entries) comparing the path prefix with +22
; Name ("A"); +1 = mode bits the device allows, +2 = state byte FDC_StoreDiskType clears, +14/+18 =
; operation tables and +12 = word, all copied into each new handle, +26 = parameter block, +30 = the
; handle FileOpen_InitSlot allocated last.
FileIO_DeviceTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x6E8, 0x22
; FileIO_DeviceCount -- 1 x uint16_t: entries in FileIO_DeviceTable (1); bounds FileOpen_MatchDevice's
; search loop, and an index equal to it means "no such device" (error 7).
FileIO_DeviceCount:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x70A, 0x2
; SectorCache_AgeOverflowFlag -- 1 x struct (1 x uint8_t (+ pad)): SeqStep_FileIo sets it when the age word (+18) of
; a 538-byte sector-cache entry reaches bit 15; while it is set the next scan decrements every age.
SectorCache_AgeOverflowFlag:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x70C, 0x2
; FDC_DiskTypeState -- 1 x struct: DiskType (byte, set by FDC_StoreDiskType, read by FDC_ReadDiskType),
; DiskChanged (word, 1 after FDC_StoreDiskType) and AckedDiskType, the copy FDC_ClearDiskChangeStatus
; takes when it clears DiskChanged.
FDC_DiskTypeState:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x70E, 0x6
; DiskStream_State -- 1 x struct: the streaming reader SndTable_LookupA/D set up: SourceMode 0 = FileRead
; from a file opened "rb", 1 = raw sector commands; ByteLength = file size (handle +71) or sectors << 9;
; BufferPtr = RAM 0x22D72, the message block ScreenGroup2_Entry hands to TaskMsg_Send.
DiskStream_State:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x714, 0xA
; East_ReverbMidiMenuWorkCells -- 1 x struct (54 cells): power-on values of the InitializeEast view work cells
; Reverb/EQ presets, MIDI menu. Boot_InitWorkRAM copies them to RAM 0x3e3f2..0x3e46e; each cell is the RAM
; target of a pointer-typed property of a view record registered by InitializeEast and is read through it by
; the record's class proc (ScreenProc, WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit
; view id (0xFFFFFFFF = none); data/onoff/page/selected (types m/n) = words.
East_ReverbMidiMenuWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x71E, 0x7C
; East_MidiMenuPage2WorkCells -- 1 x struct (5 cells): power-on values of the InitializeEast view work cells
; MIDI menu page 2; ends with the low half of MidiPartSetting_Window. Boot_InitWorkRAM copies them to RAM 0x3e46e..0x3e47c; each cell
; is the RAM target of a pointer-typed property of a view record registered by InitializeEast and is read through it by the record's
; class proc (ScreenProc, WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit view id (0xFFFFFFFF = none);
; selected (types m/n) = words. A slice boundary cuts a 32-bit cell: the ...Lo / ...Hi word is its low / high half.
East_MidiMenuPage2WorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x79A, 0xE
; East_MidiSettingWorkCells -- 1 x struct (72 cells): power-on values of the InitializeEast view work cells
; MIDI part/control/realtime/common/in-out/exclusive settings; starts and ends inside a 32-bit cell. Boot_InitWorkRAM copies them to RAM 0x3e47c..0x3e55c; each cell
; is the RAM target of a pointer-typed property of a view record registered by InitializeEast and is read through it by the record's class proc (ScreenProc,
; WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit view id (0xFFFFFFFF = none); data/onoff/page/selcol/... (types m/n) = words; pcol/prow/crow
; = 32-bit heap pointers; AcRamEditBox/AcRamBox data = 32-bit values. A slice boundary cuts a 32-bit cell: the ...Lo / ...Hi word is its low / high half.
East_MidiSettingWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x7A8, 0xE0
; East_MidiSetupWorkCells -- 1 x struct (65 cells): power-on values of the InitializeEast view work cells
; Exclusive receive, GM mode, PCG/panel-memory output, entertainer, split; starts inside a 32-bit cell. Boot_InitWorkRAM copies them to RAM 0x3e55c..0x3e62c; each
; cell is the RAM target of a pointer-typed property of a view record registered by InitializeEast and is read through it by the record's class proc (ScreenProc,
; WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit view id (0xFFFFFFFF = none); data/onoff/page/selcol/... (types m/n) = words; pcol/prow/crow
; = 32-bit heap pointers; AcRamEditBox/AcRamBox data = 32-bit values. A slice boundary cuts a 32-bit cell: the ...Lo / ...Hi word is its low / high half.
East_MidiSetupWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x888, 0xD0
; East_SendSwitchView -- 1 x struct (AcSendEditSw view record, 52 B): the "SEND" edit switch (AcSendEditSw), entry 4 of InitializeEast's Viewable table slot 0x59
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3e62c),
; so ViewableProc and the AcSendEditSw class proc use the RAM copy; first word = class id 0x1630003.
East_SendSwitchView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x958, 0x34
; Murai_SoundMenuWorkCells -- 1 x struct (267 cells): power-on values of the InitializeMurai view work cells
; Sound menu, part settings, mixer, techni-chord, drawbar, accordion, messages. Boot_InitWorkRAM copies them to RAM 0x3e660..0x3e91c;
; each cell is the RAM target of a pointer-typed property of a view record registered by InitializeMurai and is read through it by the
; record's class proc (ScreenProc, WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child = 32-bit view id (0xFFFFFFFF =
; none); data/dialfocus/onoff/page/... (types m/n) = words; AcRamEditBox/AcRamBox data = 32-bit values.
Murai_SoundMenuWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x98C, 0x2BC
; LswLeftHold_OnOffStrPtrs -- 2 x uint32_t: string pointers "OFF" / "ON " that LswLeftHold copies out for
; EVT_GET_LSW_STRING (index (xde+4) checked 0..1, `sla bc, 2`, `ld xbc, (xde+bc)`, Strcpy).
LswLeftHold_OnOffStrPtrs:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xC48, 0x8
; IvSdpart_PartNameStrPtrs -- 30 x uint32_t: part-name strings (" RIGHT 1 " ... "  RHYTHM  ", blank) indexed
; by IvSdpart_PartRow; IvSdpart_ShowHide / _Refresh / scrolling send the selected one with EVT_PARA_DRAW
; to view 0x3000B.  Scrolling keeps the row in 0..23.
IvSdpart_PartNameStrPtrs:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xC50, 0x78
; IvSdpart_CurrentPage -- 1 x uint16_t: index into IvSdpart_PageViews of the page IvSdpart shows;
; 8 (power-on value) is the top page: IvSdpart_OK exits to the sound menu from it.
IvSdpart_CurrentPage:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xCC8, 0x2
; IvSdpart_PartRow -- 1 x uint16_t: the part row IvSdpart has selected; indexes IvSdpart_PartNameStrPtrs
; and IvSdpart_PartNumberByRow; rows >= 18 are not resynchronised from GetPartSelect.
IvSdpart_PartRow:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xCCA, 0x2
; [nakarest] Naka_DrawbarControl_Table  +0xccc..+0xd00 (0xeeed44, 52 B)
; [nakarest] purpose not established: layout of 52 B at 0xeeed44 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3e9a0..0x3e9d4 (its ld xde/xhl/xbc + ldir blocks); no literal RAM reference into
; [nakarest] that copy was found.
Naka_DrawbarControl_Table:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xCCC, 0x34
	.long NakaInst_PART_14
	.long NakaInst_PART_15
	.long NakaInst_PART_16
	.long NakaInst_ACCOMP1
	.long NakaInst_ACCOMP2
	.long NakaInst_ACCOMP3
	.long NakaInst_BASS_E9D8F2
	.long NakaInst_DRUM_E9D8E8
	.long NakaInst_CHORD
	.long NakaInst_R_BASS
	.long NakaInst_MSP_E9D8CA
	.long NakaInst_MSP
	.long NakaInst_CONTROL
	.long NakaInst_METRO
	.long 0x00000000
	.long 0xFFFFFFFF
	.long 0xFFFF0002
	.long 0x00000000
	.long 0xFFFFFFFF
	.long 0xFFFF0002
	.long 0x00000000
; [nakarest] naka_sequencer_channels+0xd54  +0xd54..+0xd5c (0xeeedcc, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeeedcc not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3ea28..0x3ea30 (its ld xde/xhl/xbc + ldir blocks); no literal RAM reference into
; [nakarest] that copy was found.
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xD54, 0x8
MidiPart_ConfigNameTable:
	.long PsMixer_BootDefaultRows
	.long PsMixer_DefaultGridPartRows
	.long PartName6_Right1
	.long PartName6_Right2
	.long PartName6_Left
	.long PartName6_Part4
	.long PartName6_Part5
	.long PartName6_Part6
	.long PartName6_Part7
	.long PartName6_Part8
	.long PartName6_Part9
	.long PartName6_Part10
	.long PartName6_Part11
	.long PartName6_Part12
	.long PartName6_Part13
	.long PartName6_Part14
	.long PartName6_Part15
	.long PartName6_Part16
	.long PartName6_Chord
	.long PartName6_RBass
	.long PartName6_Acomp1
	.long PartName6_Acomp2
	.long PartName6_Acomp3
	.long PartName6_Bass
	.long PartName6_Drums
	.long PartName6_Msp
	.long PartName6_Metro
	.long PartName6_Mic
	.long PartName6_Apc
	.long PartName6_Ctrl
	.long PartName6_Rhythm
	.long PartName6_Blank
	.long PartName4_Right1
	.long PartName4_Right2
	.long PartName4_Left
	.long PartName4_Part4
	.long PartName4_Part5
	.long PartName4_Part6
	.long PartName4_Part7
	.long PartName4_Part8
	.long PartName4_Part9
	.long PartName4_Part10
	.long PartName4_Part11
	.long PartName4_Part12
	.long PartName4_Part13
	.long PartName4_Part14
	.long PartName4_Part15
	.long PartName4_Part16
	.long PartName4_Chord
	.long PartName4_RBass
	.long PartName4_Acomp1
	.long PartName4_Acomp2
	.long PartName4_Acomp3
	.long PartName4_Bass
	.long PartName4_Drums
	.long PartName4_Msp
	.long PartName4_Metro
	.long PartName4_Mic
	.long PartName4_Apc
	.long PartName4_Ctrl
	.long PartName4_Rhythm
	.long PartName6_TableEnd
	.long TrackName6_Tr1
	.long TrackName6_Tr2
	.long TrackName6_Tr3
	.long TrackName6_Tr4
	.long TrackName6_Tr5
	.long TrackName6_Tr6
	.long TrackName6_Tr7
	.long TrackName6_Tr8
	.long TrackName6_Tr9
	.long TrackName6_Tr10
	.long TrackName6_Tr11
	.long TrackName6_Tr12
	.long TrackName6_Tr13
	.long TrackName6_Tr14
	.long TrackName6_Tr15
	.long TrackName6_Tr16
	.long AccompName6_Drums
	.long AccompName6_Acomp3
	.long AccompName6_Acomp2
	.long AccompName6_Acomp1
	.long AccompName6_Bass
	.long AccompName6_Msp
	.long AccompName6_RBass
	.long AccompName6_Chord
	.long TrackName4_Tr1
	.long TrackName4_Tr2
	.long TrackName4_Tr3
	.long TrackName4_Tr4
	.long TrackName4_Tr5
	.long TrackName4_Tr6
	.long TrackName4_Tr7
	.long TrackName4_Tr8
	.long TrackName4_Tr9
	.long TrackName4_Tr10
	.long TrackName4_Tr11
	.long TrackName4_Tr12
	.long TrackName4_Tr13
	.long TrackName4_Tr14
	.long TrackName4_Tr15
	.long TrackName4_Tr16
	.long TrackName6_Unassigned_08
	.long TrackName6_Unassigned_07
	.long TrackName6_Unassigned_06
; [nakarest] naka_sequencer_channels+0xf00  +0xf00..+0xf48 (0xeeef78, 72 B)
; [nakarest] purpose not established: layout of 72 B at 0xeeef78 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3ebd4..0x3ec1c (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] TrackMixer_Init (ui/drawbar_panel_ui.s: `ld xwa, 0x3ebe8`),
; [nakarest] TrackMixer_UpdateHandler (ui/drawbar_panel_ui.s: `ld xhl, 0x3ebe8`).
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF00, 0x48
; [nakarest] Naka_DrawbarSlider_Resources  +0xf48..+0x12d8 (0xeeefc0, 912 B)
; [nakarest] purpose not established: layout of 912 B at 0xeeefc0 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3ec1c..0x3efac (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] DrawRect (kn5000_v9_program.s: `ld a,
; [nakarest] (257960:24)`), GroupBox_HandleCursorNav (ui/ui_control_panel.s: `cpw (0x3ef50:24),
; [nakarest] 0`), DrawRect_Return (kn5000_v9_program.s: `ld (257962:24),
; [nakarest] c`), DrawRect_Deferred (kn5000_v9_program.s: `ld c,
; [nakarest] (257960:24)`), 1 more.
Naka_DrawbarSlider_Resources:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF48, 0x390
; FontIDProc_FontNameTable -- 32 x uint32_t: name pointers of the font ids (CHARA1, CHARA2, ... CHARA5W, then
; "" and 21 NULLs); FontIDProc maps id -> name for EVT_GET_PROP_DATA_SP / EVT_GET_PROPERTY_EX (`sll xwa, 2`)
; and name -> id for EVT_SET_PROPERTY_EX by Strcmp until the first NULL; FontIDProc_EntryCount = 10.
FontIDProc_FontNameTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x12D8, 0x80
; Font_FileNamePtrTable -- 32 x uint32_t: file-name pointers "chara1.fnt" ... "chara5w.fnt", "" and 21 NULLs,
; entry for entry parallel to FontIDProc_FontNameTable (CHARA1 <-> chara1.fnt).  No reader of its RAM
; copy (0x3F02C) was found in v10 maincpu, so its use is not established.
Font_FileNamePtrTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1358, 0x80
; Root_DebugNamingWorkCells -- 1 x struct (74 cells): power-on values of the InitializeRoot view work cells
; Panel simulator, debug window, naming, memo, track switch, check windows. Boot_InitWorkRAM copies them to RAM
; 0x3f0ac..0x3f160; each cell is the RAM target of a pointer-typed property of a view record registered by InitializeRoot and
; is read through it by the record's class proc (ScreenProc, WindowProc, PsTrackSwitchProc ...). Cells: window/parent/child =
; 32-bit view id (0xFFFFFFFF = none); cursor/onoff/page/part/... (types m/n) = words; pcol/prow/crow = 32-bit heap pointers.
Root_DebugNamingWorkCells:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x13D8, 0xB4
; Root_NamingUpperCaseToggleView -- 1 x struct (AcIndexToggle view record, 44 B): the "NamingABC" index toggle ("ABC"), entry 23 of InitializeRoot's slot 0x0
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3f160),
; so ViewableProc and the AcIndexToggle class proc use the RAM copy; first word = class id 0x160004e.
Root_NamingUpperCaseToggleView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x148C, 0x2C
; Root_NamingLowerCaseToggleView -- 1 x struct (AcIndexToggle view record, 44 B): the "Namingabc" index toggle ("abc"), entry 24 of slot 0x0
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3f18c),
; so ViewableProc and the AcIndexToggle class proc use the RAM copy; first word = class id 0x160004e.
Root_NamingLowerCaseToggleView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x14B8, 0x2C
; Root_NamingSymbolToggleView -- 1 x struct (AcIndexToggle view record, 44 B): the "NamingSymbol" index toggle ("!#$"), entry 25 of slot 0x0
; A Viewable-table entry holds this record's RAM address (Boot_InitWorkRAM copies it to 0x3f1b8),
; so ViewableProc and the AcIndexToggle class proc use the RAM copy; first word = class id 0x160004e.
Root_NamingSymbolToggleView:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x14E4, 0x2C
; [nakarest] Naka_DrawbarReg_Table: despite the name, entries 0-11 are the WALLPAPER PALETTE
; [nakarest] table: pointers to NakaColor_Palette2, 1, 6, 5, 4, 3, 10, 9, 8, 7, Blank, Blank
; [nakarest] (debug_naming_panel_sim.s).  This blob lies wholly inside the work-RAM initial
; [nakarest] image (ROM 0xeed8c8 onward, WorkRamInit_Image) that Boot_InitWorkRAM
; [nakarest] copies with ldir, so the table lives at RAM 0x3f1e4, where GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s: `ld xde, 0x3f1e4`) indexes it (`sll 2`) and returns
; [nakarest] entry [colour] of the palette; ChangeWallPalette_Impl sets DAC entries 0xe0..0xef
; [nakarest] from it.  Entries 12 on (SeqChan_Map_*) are not part of that table.
Naka_DrawbarReg_Table:
	.long NakaColor_Palette2
	.long NakaColor_Palette1
	.long NakaColor_Palette6
	.long NakaColor_Palette5
	.long NakaColor_Palette4
	.long NakaColor_Palette3
	.long NakaColor_Palette10
	.long NakaColor_Palette9
	.long NakaColor_Palette8
	.long NakaColor_Palette7
	.long NakaColor_PaletteBlank
	.long NakaColor_PaletteBlank
	.long EditSw_PageMap2
	.long EditSw_PageMap4
	.long VariScreen_EditSwLayout6
	.long VariScreen_EditSwLayout8
	.long EditSw_SplitMap10
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_B
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long SeqChanContainer_ChordTypeRef_A
	.long NoteNameStr_Table_1
; [nakarest] naka_sequencer_channels+0x1600  +0x1600..+0x19ee (0xeef678, 1006 B)
; [nakarest] purpose not established: layout of 1006 B at 0xeef678 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3f2d4..0x3f6c2 (its ld xde/xhl/xbc + ldir blocks); no literal RAM reference into
; [nakarest] that copy was found.
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1600, 0x3EE
; WorkRamInit_Image2 -- 1 x struct: start of the second work-RAM image (Boot_InitWorkRAM copies 0x95B bytes from
; here to RAM 0xE35E).  Its first cells are the inter-CPU E1 DMA watchdog: the poll counts ticks while
; control register 0x40 stays unchanged and, after 10, aborts the transfer and counts it (+0); the wait
; with a 250-tick timeout counts its aborts at +6.  +8..+11 are not referenced.
WorkRamInit_Image2:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x19EE, 0xC
; DrawBitmap_BitMasks -- 8 x uint8_t: 0x80, 0x40 ... 0x01; DrawBitmap_BitLoop indexes it with the bit
; number (QHL) to pick one pixel of a 1-bpp image byte.
DrawBitmap_BitMasks:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x19FA, 0x8
; BmDrEdit_TempoAnimTick -- 1 x struct (1 x uint8_t (+ pad)): BmDrEdit_TempoAnimTimer counts it up to 0x1E, then resets
; it and runs the tempo/delay checks.
BmDrEdit_TempoAnimTick:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A02, 0x2
; SeqBuf_EventTemplateD1 -- 4 x uint8_t: D1 7F 00 nn, a sequencer-buffer event; the note-off path patches
; +3 with the part number - 1 and passes it with BC = 4 to SeqBuf_WriteMidiEvent.
SeqBuf_EventTemplateD1:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A04, 0x4
; SeqBuf_EventTemplateD2 -- 1 x struct (5 x uint8_t (+ pad)): D2 7F 00 40 nn; patched at +4 with the part number - 1 and
; written with BC = 5 by SeqBuf_WriteMidiEvent right after SeqBuf_EventTemplateD1.
SeqBuf_EventTemplateD2:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A08, 0x6
; SeqBuf_EventTemplateB0 -- 1 x struct (7 x uint8_t (+ pad)): B0 7F kk 04 00 08 nn; +2 from PartDetect_LookupAndApply_Table
; [part], +6 = part number - 1, written with BC = 7 (skipped for parts 0x0C, 0x0D, 0x0F, 0x10).
SeqBuf_EventTemplateB0:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A0E, 0x8
; SeqPlay_StartInitActive -- 1 x struct (1 x uint8_t (+ pad)): set by SeqInitStart_SetActiveFlag; SeqPlay_ResetStartState
; clears it and, when it was 1, also clears bit 2 of the transport byte 0x28A7.
SeqPlay_StartInitActive:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A16, 0x2
; SeqAcc_ReInitGuard -- 1 x struct (1 x uint8_t (+ pad)): 1 around SeqAcc_InitPlaybackState; while it is 1
; Seq_SyncPositionAndOutputMIDITiming clears it and returns without output.
SeqAcc_ReInitGuard:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A18, 0x2
; SeqBuffer_MoveEntryMarker -- 1 x struct (1 x uint8_t (+ pad)): SeqBuffer_MoveEntryToHead stores 0xFF here when called
; with A = 0xFF.  No read of it was found.
SeqBuffer_MoveEntryMarker:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A1A, 0x2
; EffEdit_ParamWrittenFlag -- 1 x struct (1 x uint8_t (+ pad)): the effect editor sets it when a parameter change
; (0x0A / 0x0E / 0xD6) goes to the DSP and clears it after a DSP config block.  No read was found.
EffEdit_ParamWrittenFlag:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A1C, 0x2
; PlySngSel_TimerPending -- 1 x struct (1 x uint8_t (+ pad)): 1 after the song-select screen starts its AP timer
; (SetApTimer); the timer event and IvPlayExit clear it, and IvPlayExit posts EVT_CHANGE_MODE only when 0.
PlySngSel_TimerPending:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A1E, 0x2
; PartCtrl_EventQueue -- 10 x struct {uint16 code; uint8 c; uint8 e}: PartCtrl_AppendToEventQueue stores
; WA, C and E at entry [PartCtrl_EventQueueCount] (`sll ix, 2`) while the count is < 10.  The scan
; passes codes 0x10 / 0x40; no reader of the entries was found.
PartCtrl_EventQueue:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A20, 0x28
; PartCtrl_EventQueueCount -- 1 x uint16_t: number of PartCtrl_EventQueue entries; the append refuses
; a new one at 10.
PartCtrl_EventQueueCount:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A48, 0x2
; AccBankData_Kn3000Signature -- 16 x char "KN3000 SOUND RAM" (no NUL): AccBankData compares 16 bytes of the
; loaded bank at +0x16C00 with it before copying 0x72A6 bytes to the battery SRAM at 0x1E0000.
AccBankData_Kn3000Signature:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A4A, 0x10
; StylCnv_TechnicsTag -- 8 x char "TECHNICS" (no NUL): StylCnvModl_OK_Select compares 8 bytes of each
; directory entry (+1) with it and records a match in 0x48AC.
StylCnv_TechnicsTag:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A5A, 0x8
; StylCnv_DefaultVersionName -- 8 x char " V1.0   ": StylCnvModl_CopyDefaultName Strcpy-s it as a default
; entry name; it has no NUL of its own, the zero low byte of FDC_InitSequenceCount ends it.
StylCnv_DefaultVersionName:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A62, 0x8
; FDC_InitSequenceCount -- 1 x uint16_t: incremented at the end of the FDC initialisation command sequence
; (specify / recalibrate / seek commands with SOME_DELAY) in storage/fdc_routines.s.
FDC_InitSequenceCount:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A6A, 0x2
; Dirmd_PostRequests -- 1 x struct: after each event DirmdEmulator acts on Requests (bit 1 part change, bit 7
; mode change, bit 6 SoundCtrl command, all with Arg; bit 4 refresh), RedrawMode bit 4 (timer reset) and
; DisplayRequests bit 3 (UI_PostEvent_0x6E), then clears them; DisplayParamA/B (0xFF = none) carry the
; values Tempo_DisplayParamCommon sets with bits 0 and 3.  RedrawMode is 16 during EVT_PARA_DRAW.
Dirmd_PostRequests:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A6C, 0xC
; Vga_InitPalette -- 256 x struct {red, green, blue, unused}: the palette the VGA init loop writes to the DAC
; (port 0x3C9) for colours 0..255, each 8-bit component reduced to the DAC's range (>> 4, rounded up when
; bit 3 is set); entries 0..9 and 246..255 resemble the Windows system palette (black, 0x80 primaries ... white).
Vga_InitPalette:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A78, 0x400
; NoteMap_LinkArray32 -- 35 x struct {prev, next}: a circular doubly linked list of 32 slots with head node 32
; (+65 = head.next, the first slot) plus two empty list heads 33, 34; NoteMap_SwapVoiceLinks /
; NoteMap_LinkVoiceSlots / LinkVoiceSlots_Block address node n at base + 2n.
NoteMap_LinkArray32:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1E78, 0x46
; NoteMap_LinkArray128 -- 33 x struct {prev, next}: nodes 0..32 of a 129-node circular list (128 slots,
; head node 128 whose next byte NoteMap_AllocNewVoiceEntry reads at RAM 0xE92F); the remaining nodes lie
; past the end of this blob, in the rest of work-RAM image 2.
NoteMap_LinkArray128:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1EBE, 0x42

; External label offsets within the binary blob above.
