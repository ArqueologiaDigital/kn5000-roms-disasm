
; Sequencer Channel Containers + Drawbar/Mixer Data (13 widgets, 7936 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_channels.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaData_SeqChannels
; NakaData_SeqChannels  --  naka_sequencer_channels +0x0..+0x6a0 (ROM 0xeee078..0xeee718), 1696 bytes
; No RegObjTabl-registered table points at the start of these 1696 bytes
; (0xeee078..0xeee718); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaData_SeqChannels:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x0, 0x6A0
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_DrawbarOrgan_Screens
; Naka_DrawbarOrgan_Screens  --  naka_sequencer_channels +0x6a0..+0x7a8 (ROM 0xeee718..0xeee820), 264 bytes
; No RegObjTabl-registered table points at the start of these 264 bytes
; (0xeee718..0xeee820); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_DrawbarOrgan_Screens:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x6A0, 0x108
; -----------------------------------------------------------------------------
; [nakarest_retype] SeqCh_FeatureDemoCallbackData
; SeqCh_FeatureDemoCallbackData  --  naka_sequencer_channels +0x7a8..+0x888 (ROM 0xeee820..0xeee900), 224 bytes
; No RegObjTabl-registered table points at the start of these 224 bytes
; (0xeee820..0xeee900); purpose not established by that route.
; -----------------------------------------------------------------------------
SeqCh_FeatureDemoCallbackData:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x7A8, 0xE0
; -----------------------------------------------------------------------------
; [nakarest_retype] SeqCh_SystemHandlerData
; SeqCh_SystemHandlerData  --  naka_sequencer_channels +0x888..+0xc48 (ROM 0xeee900..0xeeecc0), 960 bytes
; No RegObjTabl-registered table points at the start of these 960 bytes
; (0xeee900..0xeeecc0); purpose not established by that route.
; -----------------------------------------------------------------------------
SeqCh_SystemHandlerData:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x888, 0x3C0
; -----------------------------------------------------------------------------
; [nakarest_retype] MixerPart_NamePtrTable
; MixerPart_NamePtrTable  --  naka_sequencer_channels +0xc48..+0xccc (ROM 0xeeecc0..0xeeed44), 132 bytes
; No RegObjTabl-registered table points at the start of these 132 bytes
; (0xeeecc0..0xeeed44); purpose not established by that route.
; -----------------------------------------------------------------------------
MixerPart_NamePtrTable:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xC48, 0x84
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_DrawbarControl_Table
; Naka_DrawbarControl_Table  --  naka_sequencer_channels +0xccc..+0xd00 (ROM 0xeeed44..0xeeed78), 52 bytes
; No RegObjTabl-registered table points at the start of these 52 bytes
; (0xeeed44..0xeeed78); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_DrawbarControl_Table:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xCCC, 0x34
EmbeddedPtrTable_v10_naka_sequencer_channels_000D00:
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
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_channels+0xd54
; naka_sequencer_channels+0xd54  --  naka_sequencer_channels +0xd54..+0xd5c (ROM 0xeeedcc..0xeeedd4), 8 bytes
; No RegObjTabl-registered table points at the start of these 8 bytes
; (0xeeedcc..0xeeedd4); purpose not established by that route.
; -----------------------------------------------------------------------------
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
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_channels+0xf00
; naka_sequencer_channels+0xf00  --  naka_sequencer_channels +0xf00..+0xf48 (ROM 0xeeef78..0xeeefc0), 72 bytes
; No RegObjTabl-registered table points at the start of these 72 bytes
; (0xeeef78..0xeeefc0); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF00, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_DrawbarSlider_Resources
; Naka_DrawbarSlider_Resources  --  naka_sequencer_channels +0xf48..+0x12d8 (ROM 0xeeefc0..0xeef350), 912 bytes
; No RegObjTabl-registered table points at the start of these 912 bytes
; (0xeeefc0..0xeef350); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_DrawbarSlider_Resources:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0xF48, 0x390
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_DrawbarDisplay_Table1
; Naka_DrawbarDisplay_Table1  --  naka_sequencer_channels +0x12d8..+0x1358 (ROM 0xeef350..0xeef3d0), 128 bytes
; No RegObjTabl-registered table points at the start of these 128 bytes
; (0xeef350..0xeef3d0); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_DrawbarDisplay_Table1:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x12D8, 0x80
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_DrawbarDisplay_Table2
; Naka_DrawbarDisplay_Table2  --  naka_sequencer_channels +0x1358..+0x1510 (ROM 0xeef3d0..0xeef588), 440 bytes
; No RegObjTabl-registered table points at the start of these 440 bytes
; (0xeef3d0..0xeef588); purpose not established by that route.
; -----------------------------------------------------------------------------
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
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sequencer_channels+0x1600
; naka_sequencer_channels+0x1600  --  naka_sequencer_channels +0x1600..+0x1a78 (ROM 0xeef678..0xeefaf0), 1144 bytes
; No RegObjTabl-registered table points at the start of these 1144 bytes
; (0xeef678..0xeefaf0); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1600, 0x478
; -----------------------------------------------------------------------------
; [nakarest_retype] Palette_8bit_RGBA_2_Data
; Palette_8bit_RGBA_2_Data  --  naka_sequencer_channels +0x1a78..+0x1f00 (ROM 0xeefaf0..0xeeff78), 1160 bytes
; No RegObjTabl-registered table points at the start of these 1160 bytes
; (0xeefaf0..0xeeff78); purpose not established by that route.
; -----------------------------------------------------------------------------
Palette_8bit_RGBA_2_Data:
	.incbin "includes/generated/naka_sequencer_channels.bin", 0x1A78, 0x488

; External label offsets within the binary blob above.
