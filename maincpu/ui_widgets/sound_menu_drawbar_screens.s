

	naka_header NAKA_TYPE_CONTAINER
	.byte 0x2a, 0x00
	.byte 0x00, 0x00, 0xd4, 0x10, 0xe8, 0x00, 0xd2, 0x10
	.byte 0xe8, 0x00, 0xaa, 0x0c, 0xe8, 0x00, 0x65, 0xb6
	.byte 0xf7, 0x00


	naka_header NAKA_TYPE_0x40
	.byte 0x36, 0x00
	.byte 0x00, 0x00, 0xc6, 0x10, 0xe8, 0x00, 0xc4, 0x10
	.byte 0xe8, 0x00, 0xb0, 0x0c, 0xe8, 0x00, 0x48, 0xde
	.byte 0xf7, 0x00


	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00, 0xb6, 0x10, 0xe8, 0x00, 0xb4, 0x10
	.byte 0xe8, 0x00, 0xb6, 0x0c, 0xe8, 0x00, 0x5e, 0x2a
	.byte 0xf8, 0x00


	naka_header NAKA_TYPE_0x26
	.byte 0x2c, 0x00
	.byte 0x04, 0x00, 0xa6, 0x10, 0xe8, 0x00, 0xa2, 0x10
	.byte 0xe8, 0x00, 0xbc, 0x0c, 0xe8, 0x00, 0x06, 0x2b
	.byte 0xf8, 0x00


	naka_header NAKA_TYPE_0x12
	.byte 0x28, 0x00
	.byte 0x04, 0x00, 0x94, 0x10, 0xe8, 0x00, 0x90, 0x10
	.byte 0xe8, 0x00, 0xd4, 0x0c, 0xe8, 0x00, 0x22, 0xf4
	.byte 0xf7, 0x00


	naka_header NAKA_TYPE_0x27
	.byte 0x16, 0x00
	.byte 0x00, 0x00, 0x88, 0x10, 0xe8, 0x00, 0x86, 0x10
	.byte 0xe8, 0x00, 0xf0, 0x0c, 0xe8, 0x00, 0x00, 0x00
	.zero 16
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff
	aligned_string "IvMPver"
	.byte 0x75, 0x65, 0x00, 0xff
	aligned_string "AcDrawbarName"
	.byte 0x41, 0x41, 0x00, 0xff
	aligned_string "AcDrawSetting"
	.byte 0x00, 0xff
	aligned_string "AcPleaseWait"
	.byte 0x00, 0xff
	aligned_string "AcSndEMenu"
	.byte 0x00, 0xff
	aligned_string "AcFdemoScreen"
	.byte 0x00, 0xff
	aligned_string "VwUserBitmapSp"
	aligned_string "XemA"
	aligned_string "AcPresentationBox"
	.byte 0x6a, 0x6e, 0x00, 0xff
	aligned_string "AcLswPartPan"
	.byte 0x00, 0xff
	aligned_string "AcDrawEditBox"
	.byte 0x00, 0xff
	aligned_string "IvDemofeature2"
	.byte 0x00, 0xff
	aligned_string "IvDemofeature1"
	.byte 0x00, 0xff
	aligned_string "AcPresentationControl"
	aligned_string "c^dem"
	aligned_string "PsVariBox"
	.byte 0x00, 0xff
	aligned_string "AcResetPage"
	.byte 0x00, 0xff
	aligned_string "IvDrawbarSndE"
	.byte 0x00, 0xff
	aligned_string "IvDrawbarNorm"
	.byte 0x00, 0xff
	aligned_string "IvDrawbar2"
	.byte 0x00, 0xff
	aligned_string "IvDrawbar1"
	.byte 0x00, 0xff
	aligned_string "IvDrawbar"
	.byte 0x41, 0x74, 0x00, 0xff
	aligned_string "IvPageOverWrite"
	.byte 0x00, 0xff
	aligned_string "IvSoftver"
	.byte 0x00, 0xff
	aligned_string "AcTrackMixer"
	.byte 0x00, 0xff
	aligned_string "AcPartMixer"
	.byte 0x00, 0xff
	aligned_string "PsMixerControl"
	.byte 0x00, 0xff
	aligned_string "AcWelcomScreen"
	.byte 0x00, 0xff
	aligned_string "IvSdscltyp2"
	.byte 0x00, 0xff
	aligned_string "IvSdtecd1"
	.byte 0x00, 0xff
	aligned_string "IvSdtecd"
	aligned_string "Xc^dmm"
	aligned_string "PsLabelBox"
	.byte 0x58, 0x58, 0x00, 0xff
	aligned_string "AcAccordionTab"
	.byte 0x00, 0xff
	aligned_string "IvAccordionX"
	.byte 0x00, 0xff
	aligned_string "IvAccordion"
	.byte 0x00, 0xff
	aligned_string "IvMesage"
	.byte 0x6a, 0x6a, 0x6e, 0x00
	aligned_string "AcVolPartEditBox"
	.byte 0x6a, 0x6e, 0x00, 0xff
	aligned_string "AcLswPartEditBox"
	.byte 0x00, 0xff
	aligned_string "IvSdpart"
	.byte 0x25, 0x00, 0x94, 0x13, 0xe8, 0x00
Naka_EventDispatch_Table:
	.long NakaInst_EV_READPRESENTATION
	.long NakaInst_EV_READACTION
	.long NakaInst_EV_READSONG
	.long NakaInst_EV_ALLINITIAL
	.long NakaInst_EV_STARTSONG
	.long NakaInst_EV_ENDSONG
	.long NakaInst_EV_EXECPRESENTATION
	.long NakaInst_EV_TONEMODE
	.long NakaInst_EV_MPVERSION
	.byte 0x00, 0x00, 0x00, 0x00
NakaInst_EV_MPVERSION:	aligned_string "EV_MPVERSION"
NakaInst_EV_TONEMODE:	aligned_string "EV_TONEMODE"
NakaInst_EV_EXECPRESENTATION:	aligned_string "EV_EXECPRESENTATION"
NakaInst_EV_ENDSONG:	aligned_string "EV_ENDSONG"
NakaInst_EV_STARTSONG:	aligned_string "EV_STARTSONG"
NakaInst_EV_ALLINITIAL:	aligned_string "EV_ALLINITIAL"
NakaInst_EV_READSONG:	aligned_string "EV_READSONG"
NakaInst_EV_READACTION:	aligned_string "EV_READACTION"
NakaInst_EV_READPRESENTATION:	aligned_string "EV_READPRESENTATION"
	aligned_string "EV_ACCORDIONTAB"
	.byte 0x0a, 0x00
Naka_Event_Table3:
	.long NakaInst_MT_GetPart
	.long NakaInst_MT_GetLswDataNo
	.long NakaInst_MT_CheckPart
	.long NakaInst_MT_ReadPresentation
	.long NakaInst_MT_ReadAction
	.long NakaInst_MT_ReadSong
	.long NakaInst_MT_StartPresentation
	.long NakaInst_MT_ExecPresentation
	.long NakaInst_MT_RefreshParam
	.long NakaInst_MT_RequestMemoryDrawbar
	.long NakaInst_MT_SetMemoryDrawbar
	.long NakaInst_MT_ExistPresentation
	.long NakaInst_MT_InitPresentation
	.long NakaInst_MT_ExitPresentation
	.long NakaInst_MT_GetToneMode
	.byte 0x00, 0x00, 0x00, 0x00
NakaInst_MT_GetToneMode:	aligned_string "MT_GetToneMode"
NakaInst_MT_ExitPresentation:	aligned_string "MT_ExitPresentation"
NakaInst_MT_InitPresentation:	aligned_string "MT_InitPresentation"
NakaInst_MT_ExistPresentation:	aligned_string "MT_ExistPresentation"
NakaInst_MT_SetMemoryDrawbar:	aligned_string "MT_SetMemoryDrawbar"
NakaInst_MT_RequestMemoryDrawbar:	aligned_string "MT_RequestMemoryDrawbar"
NakaInst_MT_RefreshParam:	aligned_string "MT_RefreshParam"
NakaInst_MT_ExecPresentation:	aligned_string "MT_ExecPresentation"
NakaInst_MT_StartPresentation:	aligned_string "MT_StartPresentation"
NakaInst_MT_ReadSong:	aligned_string "MT_ReadSong"
NakaInst_MT_ReadAction:	aligned_string "MT_ReadAction"
NakaInst_MT_ReadPresentation:	aligned_string "MT_ReadPresentation"
NakaInst_MT_CheckPart:	aligned_string "MT_CheckPart"
NakaInst_MT_GetLswDataNo:	aligned_string "MT_GetLswDataNo"
NakaInst_MT_GetPart:	aligned_string "MT_GetPart"
	.byte 0x0f, 0x00, 0x25, 0xb7, 0xf7, 0x00
	.byte 0x6f, 0xbb, 0xf7, 0x00, 0x9e, 0xc0, 0xf7, 0x00
	.byte 0x23, 0xdd, 0xf7, 0x00, 0x50, 0xe2, 0xf7, 0x00
	.byte 0x54, 0xe6, 0xf7, 0x00, 0xd6, 0xe6, 0xf7, 0x00
	.byte 0x2d, 0xeb, 0xf7, 0x00, 0xdb, 0xe7, 0xf7, 0x00
	.byte 0xa1, 0xe8, 0xf7, 0x00, 0xcf, 0xee, 0xf7, 0x00
	.byte 0xa6, 0xf4, 0xf7, 0x00, 0x5a, 0xfa, 0xf7, 0x00
	.byte 0x39, 0x07, 0xf8, 0x00, 0x7f, 0x07, 0xf8, 0x00
	.byte 0x28, 0xf3, 0xf7, 0x00, 0xde, 0x2d, 0xf8, 0x00
	.byte 0xc4, 0x24, 0xf8, 0x00, 0x4f, 0x33, 0xf8, 0x00
	.byte 0xe8, 0x37, 0xf8, 0x00, 0xe5, 0x39, 0xf8, 0x00
	.byte 0x51, 0x3b, 0xf8, 0x00, 0x6b, 0x08, 0xf8, 0x00
	.byte 0x7d, 0x3e, 0xf8, 0x00, 0x0b, 0x45, 0xf8, 0x00
	.byte 0xee, 0x41, 0xf8, 0x00, 0x2f, 0x42, 0xf8, 0x00
	.byte 0xed, 0x2e, 0xf8, 0x00, 0x0e, 0xc8, 0xf7, 0x00
	.byte 0xb4, 0x42, 0xf8, 0x00, 0xcc, 0x40, 0xf8, 0x00
	.byte 0x49, 0x41, 0xf8, 0x00, 0x65, 0xb6, 0xf7, 0x00
	.byte 0x48, 0xde, 0xf7, 0x00, 0x5e, 0x2a, 0xf8, 0x00
	.byte 0x06, 0x2b, 0xf8, 0x00, 0x22, 0xf4, 0xf7, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0xa2, 0x18, 0xe8, 0x00
Naka_Event_Table2:
	.long NakaInst_AcLswPartEditBoxProc
	.long NakaInst_AcVolPartEditBoxProc
	.long NakaInst_IvMesageProc
	.long NakaInst_IvAccordionProc
	.long NakaInst_IvAccordionXProc
	.long NakaInst_AcAccordionTabProc
	.long NakaInst_PsLabelBoxProc
	.long NakaInst_IvSdtecdProc
	.long NakaInst_IvSdtecd1Proc
	.long NakaInst_IvSdscltyp2Proc
	.long NakaInst_AcWelcomScreenProc
	.long NakaInst_PsMixerControlProc
	.long NakaInst_AcPartMixerProc
	.long NakaInst_AcTrackMixerProc
	.long NakaInst_IvSoftverProc
	.long NakaInst_IvPageOverWriteProc
	.long NakaInst_IvDrawbarProc
	.long NakaInst_IvDrawbar1Proc
	.long NakaInst_IvDrawbar2Proc
	.long NakaInst_IvDrawbarNormProc
	.long NakaInst_IvDrawbarSndEProc
	.long NakaInst_AcResetPageProc
	.long NakaInst_PsVariBoxProc
	.long NakaInst_AcPresentationControlProc
	.long NakaInst_IvDemofeature1Proc
	.long NakaInst_IvDemofeature2Proc
	.long NakaInst_AcDrawEditBoxProc
	.long NakaInst_AcLswPartPanProc
	.long NakaInst_AcPresentationBoxProc
	.long NakaInst_VwUserBitmapSpProc
	.long NakaInst_AcFdemoScreenProc
	.long NakaInst_AcSndEMenuProc
	.long NakaInst_AcPleaseWaitProc
	.long NakaInst_AcDrawSettingProc
	.long NakaInst_AcDrawbarNameProc
	.long NakaInst_IvMPverProc
	.long LABEL_E81624
LABEL_E81624:	aligned_string ""
NakaInst_IvMPverProc:	aligned_string "IvMPverProc"
NakaInst_AcDrawbarNameProc:	aligned_string "AcDrawbarNameProc"
NakaInst_AcDrawSettingProc:	aligned_string "AcDrawSettingProc"
NakaInst_AcPleaseWaitProc:	aligned_string "AcPleaseWaitProc"
NakaInst_AcSndEMenuProc:	aligned_string "AcSndEMenuProc"
NakaInst_AcFdemoScreenProc:	aligned_string "AcFdemoScreenProc"
NakaInst_VwUserBitmapSpProc:	aligned_string "VwUserBitmapSpProc"
NakaInst_AcPresentationBoxProc:	aligned_string "AcPresentationBoxProc"
NakaInst_AcLswPartPanProc:	aligned_string "AcLswPartPanProc"
NakaInst_AcDrawEditBoxProc:	aligned_string "AcDrawEditBoxProc"
NakaInst_IvDemofeature2Proc:	aligned_string "IvDemofeature2Proc"
NakaInst_IvDemofeature1Proc:	aligned_string "IvDemofeature1Proc"
NakaInst_AcPresentationControlProc:	aligned_string "AcPresentationControlProc"
NakaInst_PsVariBoxProc:	aligned_string "PsVariBoxProc"
NakaInst_AcResetPageProc:	aligned_string "AcResetPageProc"
NakaInst_IvDrawbarSndEProc:	aligned_string "IvDrawbarSndEProc"
NakaInst_IvDrawbarNormProc:	aligned_string "IvDrawbarNormProc"
NakaInst_IvDrawbar2Proc:	aligned_string "IvDrawbar2Proc"
NakaInst_IvDrawbar1Proc:	aligned_string "IvDrawbar1Proc"
NakaInst_IvDrawbarProc:	aligned_string "IvDrawbarProc"
NakaInst_IvPageOverWriteProc:	aligned_string "IvPageOverWriteProc"
NakaInst_IvSoftverProc:	aligned_string "IvSoftverProc"
NakaInst_AcTrackMixerProc:	aligned_string "AcTrackMixerProc"
NakaInst_AcPartMixerProc:	aligned_string "AcPartMixerProc"
NakaInst_PsMixerControlProc:	aligned_string "PsMixerControlProc"
NakaInst_AcWelcomScreenProc:	aligned_string "AcWelcomScreenProc"
NakaInst_IvSdscltyp2Proc:	aligned_string "IvSdscltyp2Proc"
NakaInst_IvSdtecd1Proc:	aligned_string "IvSdtecd1Proc"
NakaInst_IvSdtecdProc:	aligned_string "IvSdtecdProc"
NakaInst_PsLabelBoxProc:	aligned_string "PsLabelBoxProc"
NakaInst_AcAccordionTabProc:	aligned_string "AcAccordionTabProc"
NakaInst_IvAccordionXProc:	aligned_string "IvAccordionXProc"
NakaInst_IvAccordionProc:	aligned_string "IvAccordionProc"
NakaInst_IvMesageProc:	aligned_string "IvMesageProc"
NakaInst_AcVolPartEditBoxProc:	aligned_string "AcVolPartEditBoxProc"
NakaInst_AcLswPartEditBoxProc:	aligned_string "AcLswPartEditBoxProc"
NakaInst_IvSdpartProc:	aligned_string "IvSdpartProc"

LABEL_E818B0:
	naka_header NAKA_TYPE_CONTAINER
	.byte 0xff, 0xff, 0x01, 0x00
	.byte 0xff, 0xff, 0xff, 0xff, 0x0a, 0x00, 0x00, 0x00
	.byte 0x00, 0x00
	.long Naka_PresentationRootState
	.byte 0xf8, 0x00
	.byte 0x02, 0x00, 0x00, 0x00
	.byte 0xa0, 0x01, 0x60, 0xe6
	.byte 0x03, 0x00
	.long NakaDesc_SOUND_MENU
	.long 0x15

NakaDesc_SOUND_MENU:	aligned_string "SOUND MENU"

LABEL_E818E6:	; This is a yellow "PAGE 1/2" button
	naka_header NAKA_TYPE_0x25
	.byte 0x00, 0x00
