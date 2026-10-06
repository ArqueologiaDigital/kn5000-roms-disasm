
; Sequencer Channel Containers + Drawbar/Mixer Data (13 widgets, 7936 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_channels.c (C struct with named fields)
; [nakarest] NakaData_SeqChannels  +0x0..+0x6a0 (0xeee078, 1696 B)
; [nakarest] purpose not established: layout of 1696 B at 0xeee078 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3dcd4..0x3e374 (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] LoadAndRunXapr_Entry (factory_test/test_init.s: `ld (253188:24), 1`),
; [nakarest] LoadXaprInit_Entry (factory_test/test_init.s: `ld (253188:24), 1`),
; [nakarest] TrAsSureLangCheck (sequencer/sequencer_ui.s: `lda xhl, (253688:24)`).
NakaData_SeqChannels:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x0, 0x6A0
; [nakarest] Naka_DrawbarOrgan_Screens  +0x6a0..+0x7a8 (0xeee718, 264 B)
; [nakarest] purpose not established: layout of 264 B at 0xeee718 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3e374..0x3e47c (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] FDC_ClearDiskChangeStatus (sequencer/smf_event_processor.s: `ld (0x3e3e2:24), a`),
; [nakarest] FileOpen_DeviceFound (sequencer/smf_event_processor.s: `cp wa, (0x3e3de:24)`),
; [nakarest] FileOpen_DeviceSearchLoop (sequencer/smf_event_processor.s: `cp wa, (254942:24)`),
; [nakarest] FileOpen_MatchDevice (sequencer/smf_event_processor.s: `lda xwa, (254908:24)`), 2
; [nakarest] more.
Naka_DrawbarOrgan_Screens:		.incbin "includes/generated/naka_sequencer_channels.bin", 0x6A0, 0xFA
Pad_AfterNaka_DrawbarOrgan_Screens:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x79A, 0xE
; [nakarest] SeqCh_FeatureDemoCallbackData  +0x7a8..+0x888 (0xeee820, 224 B)
; [nakarest] purpose not established: layout of 224 B at 0xeee820 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3e47c..0x3e55c (its ld xde/xhl/xbc + ldir blocks); no literal RAM reference into
; [nakarest] that copy was found.
SeqCh_FeatureDemoCallbackData:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x7A8, 0xE0
; [nakarest] SeqCh_SystemHandlerData  +0x888..+0xc48 (0xeee900, 960 B)
; [nakarest] purpose not established: layout of 960 B at 0xeee900 not derived; readers below
; [nakarest] Readers: 2 data words in HDAE5000_Init_BytecodeBlock (at 0xef4b1d, 0xef4b1a); 1
; [nakarest] data word in SLIDE_Decompress_4K_FillRing (at 0xef3fc7), which is read by
; [nakarest] SLIDE_Decompress_4K_FillRing (boot/system_handlers.s: `jr c,
; [nakarest] SLIDE_Decompress_4K_FillRing`); 1 data word in SLIDE_Decompress_8K_FillRing (at
; [nakarest] 0xef40e5), which is read by SLIDE_Decompress_8K_FillRing (boot/system_handlers.s:
; [nakarest] `jr c, SLIDE_Decompress_8K_FillRing`); work-RAM image: Boot_InitWorkRAM copies
; [nakarest] these bytes to RAM 0x3e55c..0x3e91c (its ld xde/xhl/xbc + ldir blocks), where they
; [nakarest] are read by NakaMenuItem_AcousticIllusion
; [nakarest] (ui_widgets/naka_sound_technichord_dispatch.s: `.long 0x3e67e`),
; [nakarest] NakaMenuItem_KeyScaling (ui_widgets/naka_sound_technichord_dispatch.s: `.long
; [nakarest] 0x3e674`), NakaMenuItem_Mixer (ui_widgets/naka_sound_technichord_dispatch.s: `.long
; [nakarest] 0x3e670`), NakaMenuItem_PartSetting (ui_widgets/naka_sound_technichord_dispatch.s:
; [nakarest] `.long 0x3e66e`), 4 more.
SeqCh_SystemHandlerData:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x888, 0x3C0
; [nakarest] MixerPart_NamePtrTable  +0xc48..+0xccc (0xeeecc0, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xeeecc0 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3e91c..0x3e9a0 (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] AcLswPartEdit_Match (ui/drawbar_panel_ui.s: `ld de, (256414:24)`),
; [nakarest] AcLswPartEdit_ShowHide (ui/drawbar_panel_ui.s: `ld de, (256414:24)`),
; [nakarest] AcLswPartPan_Match (ui/drawbar_panel_ui.s: `ld de, (256414:24)`),
; [nakarest] AcLswPartPan_ShowHide (ui/drawbar_panel_ui.s: `ld de, (256414:24)`), 4 more.
MixerPart_NamePtrTable:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xC48, 0x84
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
	.long MidiParam_PanelCfgTable
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
; [nakarest] AccDraw_Secondary_Helper10 (sequencer/accompaniment_engine.s: `ld (257960:24), 2`),
; [nakarest] AccDraw_Secondary_Helper18 (sequencer/accompaniment_engine.s: `ld (257960:24), 0`),
; [nakarest] AccDraw_Secondary_Return2 (sequencer/accompaniment_engine.s: `ld (257960:24), 0`),
; [nakarest] AccDraw_Secondary_Return3 (sequencer/accompaniment_engine.s: `ld (257960:24), 0`),
; [nakarest] 42 more.
Naka_DrawbarSlider_Resources:	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF48, 0x390
; [nakarest] Naka_DrawbarDisplay_Table1  +0x12d8..+0x1358 (0xeef350, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xeef350 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3efac..0x3f02c (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] FontIDProc (ui/ui_widget_defs.s: `ld xbc, 0x3efac`), FontIDProc_OnGetOrDumpPropertyEx
; [nakarest] (ui/ui_widget_defs.s: `ld xbc, 0x3efac`), FontIDProc_SetProp_LoopHead (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, 0x3efac`).
Naka_DrawbarDisplay_Table1:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x12D8, 0x80
; [nakarest] Naka_DrawbarDisplay_Table2  +0x1358..+0x1510 (0xeef3d0, 440 B)
; [nakarest] purpose not established: layout of 440 B at 0xeef3d0 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x3f02c..0x3f1e4 (its ld xde/xhl/xbc + ldir blocks); no literal RAM reference into
; [nakarest] that copy was found.
Naka_DrawbarDisplay_Table2:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1358, 0x1B8
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
	.long SeqChan_Map_2ch
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
; [nakarest] naka_sequencer_channels+0x1600  +0x1600..+0x1a78 (0xeef678, 1144 B)
; [nakarest] purpose not established: layout of 1144 B at 0xeef678 not derived; readers below
; [nakarest] Readers: 1 data word in Boot_InitWorkRAM_ROMCopy2_Start (at 0xef0bae), which is
; [nakarest] read by Boot_InitWorkRAM_ROMCopy1_Start (boot/system_handlers.s: `jr z,
; [nakarest] Boot_InitWorkRAM_ROMCopy2_Start`); work-RAM image: Boot_InitWorkRAM copies these
; [nakarest] bytes to RAM 0x3f2d4..0x3f6c2 (its ld xde/xhl/xbc + ldir blocks), where they are
; [nakarest] read by MainChordPre_AppendChordSuffix (kn5000_v7_program.s: `lda xbc,
; [nakarest] (258808:24)`); work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x0e2c2..0x0e34c (its ld xde/xhl/xbc + ldir blocks), where they are read by
; [nakarest] AccDraw_Secondary_Return7 (sequencer/accompaniment_engine.s: `ld (58134:16), 181`),
; [nakarest] AccPlayback_ProcessTempoAdvance (sequencer/accompaniment_engine.s: `ld (0xe31a:16),
; [nakarest] 0x10`), AccPlayback_ReadEvt_OverflowOK (sequencer/accompaniment_engine.s: `ld
; [nakarest] (58138:16), 16`), AccStyle_SC0ByteSelect (sequencer/accompaniment_engine.s: `ld
; [nakarest] (0xe318:16), 0x10`), 60 more.
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1600, 0x3EE
Boot_InitWorkRAM_ROMCopy2_Start_Data:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x19EE, 0x8A
; [nakarest] Palette_8bit_RGBA_2_Data  +0x1a78..+0x1ed6 (0xeefaf0, 1118 B)
; [nakarest] purpose not established: layout of 1118 B at 0xeefaf0 not derived; readers below
; [nakarest] Readers: work-RAM image: Boot_InitWorkRAM copies these bytes to RAM
; [nakarest] 0x0e34c..0x0e7aa (its ld xde/xhl/xbc + ldir blocks); no literal RAM reference into
; [nakarest] that copy was found.
Palette_8bit_RGBA_2_Data:	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A78, 0x45E

; External label offsets within the binary blob above.
