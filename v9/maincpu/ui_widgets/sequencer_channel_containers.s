
; Sequencer Channel Containers + Drawbar/Mixer Data (13 widgets, 7936 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_channels.c (C struct with named fields)
; [nakarest] NakaData_SeqChannels  +0x0..+0x6a0 (0xeee078, 1696 B)
; [nakarest] purpose not established: 1696 bytes at 0xeee078 that no registered NAKA table points into
NakaData_SeqChannels:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x0, 0x6A0
; [nakarest] Naka_DrawbarOrgan_Screens  +0x6a0..+0x7a8 (0xeee718, 264 B)
; [nakarest] purpose not established: 264 bytes at 0xeee718 that no registered NAKA table points into
Naka_DrawbarOrgan_Screens:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x6A0, 0x108
; [nakarest] SeqCh_FeatureDemoCallbackData  +0x7a8..+0x888 (0xeee820, 224 B)
; [nakarest] purpose not established: 224 bytes at 0xeee820 that no registered NAKA table points into
SeqCh_FeatureDemoCallbackData:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x7A8, 0xE0
; [nakarest] SeqCh_SystemHandlerData  +0x888..+0xc48 (0xeee900, 960 B)
; [nakarest] purpose not established: 960 bytes at 0xeee900 that no registered NAKA table points into
SeqCh_SystemHandlerData:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x888, 0x3C0
; [nakarest] MixerPart_NamePtrTable  +0xc48..+0xccc (0xeeecc0, 132 B)
; [nakarest] purpose not established: 132 bytes at 0xeeecc0 that no registered NAKA table points into
MixerPart_NamePtrTable:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xC48, 0x84
; [nakarest] Naka_DrawbarControl_Table  +0xccc..+0xd00 (0xeeed44, 52 B)
; [nakarest] purpose not established: 52 bytes at 0xeeed44 that no registered NAKA table points into
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
; [nakarest] naka_sequencer_channels+0xd54  +0xd54..+0xd5c (0xeeedcc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xeeedcc that no registered NAKA table points into
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xD54, 0x8
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
; [nakarest] naka_sequencer_channels+0xf00  +0xf00..+0xf48 (0xeeef78, 72 B)
; [nakarest] purpose not established: 72 bytes at 0xeeef78 that no registered NAKA table points into
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF00, 0x48
; [nakarest] Naka_DrawbarSlider_Resources  +0xf48..+0x12d8 (0xeeefc0, 912 B)
; [nakarest] purpose not established: 912 bytes at 0xeeefc0 that no registered NAKA table points into
Naka_DrawbarSlider_Resources:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF48, 0x390
; [nakarest] Naka_DrawbarDisplay_Table1  +0x12d8..+0x1358 (0xeef350, 128 B)
; [nakarest] purpose not established: 128 bytes at 0xeef350 that no registered NAKA table points into
Naka_DrawbarDisplay_Table1:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x12D8, 0x80
; [nakarest] Naka_DrawbarDisplay_Table2  +0x1358..+0x1510 (0xeef3d0, 440 B)
; [nakarest] purpose not established: 440 bytes at 0xeef3d0 that no registered NAKA table points into
Naka_DrawbarDisplay_Table2:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1358, 0x1B8
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
; [nakarest] naka_sequencer_channels+0x1600  +0x1600..+0x1a78 (0xeef678, 1144 B)
; [nakarest] purpose not established: 1144 bytes at 0xeef678 that no registered NAKA table points into
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1600, 0x478
; [nakarest] Palette_8bit_RGBA_2_Data  +0x1a78..+0x1f00 (0xeefaf0, 1160 B)
; [nakarest] purpose not established: 1160 bytes at 0xeefaf0 that no registered NAKA table points into
Palette_8bit_RGBA_2_Data:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A78, 0x488

; External label offsets within the binary blob above.
