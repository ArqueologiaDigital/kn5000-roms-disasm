
; Sequencer Channel Containers + Drawbar/Mixer Data (13 widgets, 7936 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_channels.c (C struct with named fields)
NakaData_SeqChannels:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x0, 0x6A0
Naka_DrawbarOrgan_Screens:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x6A0, 0x108
SeqCh_FeatureDemoCallbackData:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x7A8, 0xE0
SeqCh_SystemHandlerData:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x888, 0x3C0
MixerPart_NamePtrTable:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xC48, 0x84
Naka_DrawbarControl_Table:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xCCC, 0x34
EmbeddedPtrTable_v9_naka_sequencer_channels_000D00:
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
	.long 0xFFFFFFFF
	.long 0xFFFF0009
MidiPart_ConfigNameTable:
	.long MidiParam_PanelCfgTable
	.long Midi_PartToChMappingTable
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
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF00, 0x48
Naka_DrawbarSlider_Resources:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF48, 0x390
Naka_DrawbarDisplay_Table1:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x12D8, 0x80
Naka_DrawbarDisplay_Table2:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1358, 0x1A8
EmbeddedPtrTable_v9_naka_sequencer_channels_001500:
	.long 0x2E8200EB
	.long 0xF0D200EB
	.long 0x00040003
	.long 0x00020000
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
	.long SeqChan_Map_4ch
	.long SeqChan_Map_6ch
	.long SeqChan_Map_8ch
	.long SeqChan_Map_10ch
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED029C
	.long 0x00ED0212
	.long 0x00ED0212
	.long 0x00ED0212
	.long NoteNameStr_Table_1
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1600, 0x478
Palette_8bit_RGBA_2_Data:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A78, 0x488

; External label offsets within the binary blob above.
