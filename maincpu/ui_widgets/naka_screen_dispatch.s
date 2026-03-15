; =============================================================================
; NAKA Screen Dispatch Tables (2.3K lines)
; =============================================================================
;
; Screen definition tables for SeqToComposer, SeqCopy,
; EasyComposer, ModeSelect, ExpandMode, and other screen
; layouts. Pointer tables for widget instantiation.
; =============================================================================

	xor	(xiz), wa
	.byte 0x03, 0x00, 0xba, 0xd8, 0x03, 0x00
	.long NakaLabel_PatternCopy_MemoryLabel
	.long NakaLabel_PatternCopy_PatMemLabel
	cps	iz, 0
	.byte 0x03, 0x00, 0x02, 0xd9, 0x03, 0x00
	.long NakaNode_PatternCopy_ProgressBar
	.byte 0x00, 0x00, 0x00, 0x00
Naka_SeqToComposer_Screens:
	.long NakaContainer_SeqToComposer_Root
	.long Naka0x3E_SeqToComposer_DrmBtn
	.long Naka0x3E_SeqToComposer_Ac3Btn
	.long Naka0x3E_SeqToComposer_Ac2Btn
	.long Naka0x29_SeqToComposer_Scrollbar
	.long Naka0x3E_SeqToComposer_SourceBtn
	.long Naka0x3E_SeqToComposer_DestBtn
	.long Naka0x3E_SeqToComposer_InfoBtn
	.long NakaLabel_SeqToComposer_FirstLast
	.long NakaLabel_SeqToComposer_MeasureLabel
	.long NakaValue_SeqToComposer_MeasVal1
	.long NakaValue_SeqToComposer_MeasVal2
	.long NakaValue_SeqToComposer_MeasVal3
	.long NakaValue_SeqToComposer_MeasVal4
	.long NakaLabel_SeqToComposer_TransLabel
	.long NakaLabel_SeqToComposer_TransPose
	.long NakaLabel_SeqToComposer_SequencerLabel
	.long NakaGroup_SeqToComposer_SeqGroup
	.long NakaValue_SeqToComposer_SeqValue
	.long NakaLabel_SeqToComposer_FirstLabel
	.long NakaLabel_SeqToComposer_MeasFirstLabel
	.long NakaLabel_SeqToComposer_LastLabel
	.long NakaLabel_SeqToComposer_MeasLastLabel
	.long NakaGroup_SeqToComposer_TransGroup
	ldb	h, 0xd9
	pop_sr
	nop
	.long NakaLabel_SeqToComposer_TrnLabel
	.long NakaLabel_SeqToComposer_MemLabel
	.long NakaLabel_SeqToComposer_ComposerMemory
	.byte 0x4a, 0xd9
	.byte 0x03, 0x00
	.long NakaNode_SeqToComposer_ControlField
	.long NakaNode_SeqToComposer_StyleField
	.byte 0x6e, 0xd9, 0x03, 0x00
Naka_SeqCopy_Screens:
	.long NakaNode_SeqToComposer_ProgressBar
	.long NakaNode_SeqToComposer_PartDisplay
	.long Naka0x1F_SeqToComposer_PartSel1
	.long Naka0x1F_SeqToComposer_PartSel2
	.long Naka0x64_SeqToComposer_TabContent
	.byte 0x00, 0x00, 0x00, 0x00


Naka_EasyComposer_Screens:
	.long NakaContainer_EasyComposer_Root
	.long Naka0x29_EasyComposer_Scrollbar
	.long Naka0x3D_EasyComposer_EditBtn
	.long Naka0x3E_EasyComposer_DestBtn
	.long Naka0x3E_EasyComposer_SourceBtn
	.long Naka0x3E_EasyComposer_InfoBtn
	.long NakaLabel_EasyComposer_CompMemLabel
	.long NakaLabel_EasyComposer_MemField
	.long Naka0x11_EasyComposer_ListFrame
	.long NakaNode_EasyComposer_StatusField
	.long NakaNode_EasyComposer_PartDisplay
	.long Naka0x22_EasyComposer_PartSel1
	.long Naka0x22_EasyComposer_PartSel2
	.long Naka0x1F_EasyComposer_PartSel3
	.zero 4


Naka_EasyComposer2_Screens:
	.long NakaContainer_BendRange_Root
	.long Naka0x22_BendRange_PartSelector
	.long Naka0x1A_BendRange_RangeControl
	.long NakaLabel_BendRange_ValueLabel
	.byte 0x00, 0x00, 0x00, 0x00


Naka_ModeSelect_Screens:
	.long NakaContainer_ModeSelect_Root
	.long NakaLabel_ModeSelect_IntroFillIns
	.long NakaLabel_ModeSelect_ForEachPattern
	.long NakaLabel_ModeSelect_BeCopied
	.long NakaLabel_ModeSelect_MemAssigned
	.long NakaLabel_ModeSelect_ToEachIntro
	.long NakaLabel_ModeSelect_FillInEnding
	.long NakaLabel_ModeSelect_SoYouCanCreate
	.long NakaLabel_ModeSelect_IntroFillEnding
	.long NakaNode_ModeSelect_NormalMode
	.long NakaNode_ModeSelect_ExpandMode
	.byte 0x00, 0x00, 0x00, 0x00


Naka_ExpandMode_Screens:
	.long NakaNode_CustomCopy_RootOuter
	.long NakaLabel_CustomCopy_FromLabel
	.long Naka0x11_CustomCopy_FromFrame
	.long NakaNode_CustomCopy_FromField
	.long NakaNode_CustomCopy_ToFieldTop
	.long NakaLabel_CustomCopy_ToLabel
	.long Naka0x11_CustomCopy_ToFrame
	.long Naka0x29_CustomCopy_Scrollbar
	.long Naka0x3F_CustomCopy_Selector1
	.long Naka0x3F_CustomCopy_Selector2
	.long Naka0x3F_CustomCopy_Selector3
	.long NakaNode_CustomCopy_DestField
	.long Naka0x3E_CustomCopy_InfoBtn
	.long NakaNode_CustomCopy_SrcPatternField
	.long NakaNode_CustomCopy_DstPatternField
	.long NakaNode_CustomCopy_MemoryField
	.long NakaNode_CustomCopy_ProgressBar
	.long Naka0x35_CustomCopy_SongBar
	.long Naka0x11_CustomCopy_PresetFrame
	.long NakaList_CustomCopy_PresetList
	.long NakaList_CustomCopy_GroupList
	.long NakaList_CustomCopy_RhythmList
	.long NakaNode_CustomCopy_RhythmStatus
	.long Naka0x3E_CustomCopy_ExecuteBtn
	.long Naka0x3E_CustomCopy_AbortBtn1
	.long Naka0x35_CustomCopy_DestSongBar
	.long Naka0x11_CustomCopy_DestFrame
	.long NakaList_CustomCopy_DestPresetList
	.long NakaList_CustomCopy_DestGroupList
	.long NakaList_CustomCopy_DestRhythmList
	.long NakaNode_CustomCopy_DestRhythmStatus
	.long Naka0x3E_CustomCopy_ExecuteBtn2
	.long Naka0x3E_CustomCopy_AbortBtn2
	.byte 0x00, 0x00, 0x00, 0x00


Naka_Accomp7_Screens:
	.long NakaContainer_CustomCopy_FinalRoot
	.long NakaNode_Accomp7_Widget01
	.long NakaNode_Accomp7_Widget02
	.long NakaNode_Accomp7_Widget03
	.long NakaNode_Accomp7_Widget04
	.long NakaNode_Accomp7_Widget05
	.long NakaNode_Accomp7_Widget06
	.long NakaNode_Accomp7_Widget07
	.long NakaNode_Accomp7_Widget08
	.long NakaNode_Accomp7_Widget09
	.long NakaNode_Accomp7_Widget10
	.long NakaNode_Accomp7_Widget11
	.long NakaNode_Accomp7_Widget12
	.long NakaNode_Accomp7_Widget13
	.long NakaNode_Accomp7_Widget14
	.long NakaNode_Accomp7_Widget15
	.long NakaNode_Accomp7_Widget16
	.long NakaNode_Accomp7_Widget17
	.long NakaNode_Accomp7_Widget18
	.long NakaNode_Accomp7_Widget19
	.long NakaNode_Accomp7_Widget20
	.long NakaNode_Accomp7_Widget21
	.long NakaNode_Accomp7_Widget22
	.long NakaNode_Accomp7_Widget23
	.long NakaNode_Accomp7_Widget24
	.long NakaNode_Accomp7_Widget25
	.long NakaNode_Accomp7_Widget26
	.byte 0x00, 0x00, 0x00, 0x00
	.long NakaNode_Accomp7_Widget27

Naka_Accomp8_Screens:
	.long NakaNode_Accomp8_Widget01
	.long NakaNode_Accomp8_Widget02
	.long NakaNode_Accomp8_Widget03
	.long NakaNode_Accomp8_Widget04
	.long NakaNode_Accomp8_Widget05
	.long NakaNode_Accomp8_Widget06
	.long NakaNode_Accomp8_Widget07
	.long NakaNode_Accomp8_Widget08
	.long NakaNode_Accomp8_Widget09
	.long NakaNode_Accomp8_Widget10
	.long NakaNode_Accomp8_Widget11
	.long NakaNode_Accomp8_Widget12
	.long NakaNode_Accomp8_Widget13
	.long NakaNode_Accomp8_Widget14
	.long NakaNode_Accomp8_Widget15
	.zero 4


Naka_Accomp9_Screens:
	.long NakaNode_Accomp9_Widget01
	.long NakaNode_Accomp9_Widget02
	.long NakaNode_Accomp9_Widget03
	.long NakaNode_Accomp9_Widget04
	.long NakaNode_Accomp9_Widget05
	.long NakaNode_Accomp9_Widget06
	.byte 0x00, 0x00, 0x00, 0x00


Naka_Accomp10_Screens:
	.long NakaNode_Accomp10_Widget01
	.long NakaNode_Accomp10_Widget02
	.long NakaNode_Accomp10_Widget03
	.long NakaNode_Accomp10_Widget04
	.zero 4


Naka_Accomp11_Screens:
	.long NakaNode_Accomp11_Widget01
	.long NakaNode_Accomp11_Widget02
	.long NakaNode_Accomp11_Widget03
	.long NakaNode_Accomp11_Widget04
	.long NakaNode_Accomp11_Widget05
	.long NakaNode_Accomp11_Widget06
	.long NakaNode_Accomp11_Widget07
	.long NakaNode_Accomp11_Widget08
	.long NakaNode_Accomp11_Widget09
	.zero 4


Naka_Accomp12_Screens:
	.long NakaNode_Accomp12_Widget01
	.long NakaNode_Accomp12_Widget02
	.long NakaNode_Accomp12_Widget03
	.long NakaNode_Accomp12_Widget04
	.long NakaNode_Accomp12_Widget05
	.long NakaNode_Accomp12_Widget06
	.long NakaNode_Accomp12_Widget07
	.long NakaNode_Accomp12_Widget08
	.byte 0x00, 0x00, 0x00, 0x00


Naka_Accomp13_Screens:
	.long NakaNode_Accomp13_Widget01
	.long NakaNode_Accomp13_Widget02
	.long NakaNode_Accomp13_Widget03
	.long NakaNode_Accomp13_Widget04
	.long NakaNode_Accomp13_Widget05
	.long NakaNode_Accomp13_Widget06
	.zero 4


Naka_Accomp14_Screens:
	.long NakaInst_StylCnvWaitScreen
	.long NakaEmpty_Accomp14_Slot1
	.long NakaEmpty_Accomp14_Slot2
	.long NakaEmpty_Accomp14_Slot3
NakaEmpty_Accomp14_Slot3:	aligned_string ""
NakaEmpty_Accomp14_Slot2:	aligned_string ""
NakaEmpty_Accomp14_Slot1:	aligned_string ""
NakaInst_StylCnvWaitScreen:	aligned_string "StylCnvWaitScreen"
Naka_StylCnvWait_Screens:
	.long NakaInst_StylCnvModlScreen
	.long NakaEmpty_StylCnvModl_Slot1
	.long NakaInst_StylCnvModlBox
	.long NakaEmpty_StylCnvWait_Slot5
	.long NakaEmpty_StylCnvWait_Slot2
	.long NakaEmpty_StylCnvWait_Slot3
	.long NakaEmpty_StylCnvWait_Slot4
	.long NakaInst_StylCnvVer
	.long NakaEmpty_StylCnvWait_Slot1
NakaEmpty_StylCnvWait_Slot1:	aligned_string ""
NakaInst_StylCnvVer:	aligned_string "StylCnvVer"
NakaEmpty_StylCnvWait_Slot4:	aligned_string ""
NakaEmpty_StylCnvWait_Slot3:	aligned_string ""
NakaEmpty_StylCnvWait_Slot2:	aligned_string ""
NakaEmpty_StylCnvWait_Slot5:	aligned_string ""
NakaInst_StylCnvModlBox:	aligned_string "StylCnvModlBox"
NakaEmpty_StylCnvModl_Slot1:	aligned_string ""
NakaInst_StylCnvModlScreen:	aligned_string "StylCnvModlScreen"
Naka_StylCnvVer_Screens:
	.long NakaInst_StylCnvCnvtScreen
	.long NakaEmpty_StylCnvCnvt_Slot1
	.long NakaInst_StylCnvCnvtBox
	.long NakaEmpty_StylCnvVer_Slot1
	.long NakaEmpty_StylCnvVer_Slot2
	.long NakaEmpty_StylCnvVer_Slot3
	.long NakaEmpty_StylCnvVer_Slot4
	.long NakaEmpty_StylCnvVer_Slot5
NakaEmpty_StylCnvVer_Slot5:	aligned_string ""
NakaEmpty_StylCnvVer_Slot4:	aligned_string ""
NakaEmpty_StylCnvVer_Slot3:	aligned_string ""
NakaEmpty_StylCnvVer_Slot2:	aligned_string ""
NakaEmpty_StylCnvVer_Slot1:	aligned_string ""
NakaInst_StylCnvCnvtBox:	aligned_string "StylCnvCnvtBox"
NakaEmpty_StylCnvCnvt_Slot1:	aligned_string ""
NakaInst_StylCnvCnvtScreen:	aligned_string "StylCnvCnvtScreen"
	.byte 0xea, 0xbb
	.byte 0xe1, 0x00
Naka_StylCnvCnvtBox_Screens:
	.long NakaEmpty_StylCnvCnvtBox_Slot1
	.long NakaEmpty_StylCnvCnvtBox_Slot2
	.long NakaEmpty_StylCnvCnvtBox_Slot3
	.long NakaEmpty_StylCnvCnvtBox_Slot4
NakaEmpty_StylCnvCnvtBox_Slot4:	aligned_string ""
NakaEmpty_StylCnvCnvtBox_Slot3:	aligned_string ""
NakaEmpty_StylCnvCnvtBox_Slot2:	aligned_string ""
NakaEmpty_StylCnvCnvtBox_Slot1:	aligned_string ""
NakaInst_StylCnvStorScreen:	aligned_string "StylCnvStorScreen"
	.long NakaInst_StylCnvTxtScreen
Naka_StylCnvStor_Screens:
	.long NakaEmpty_StylCnvStor_Slot1
	.long NakaEmpty_StylCnvStor_Slot2
	.long NakaEmpty_StylCnvStor_Slot3
	.long NakaEmpty_StylCnvStor_Slot4
NakaEmpty_StylCnvStor_Slot4:	aligned_string ""
NakaEmpty_StylCnvStor_Slot3:	aligned_string ""
NakaEmpty_StylCnvStor_Slot2:	aligned_string ""
NakaEmpty_StylCnvStor_Slot1:	aligned_string ""
NakaInst_StylCnvTxtScreen:	aligned_string "StylCnvTxtScreen"
Naka_StylCnvTxt_Screens:
	.long NakaInst_StylCnvSelScreen
	.long NakaEmpty_StylCnvSel_Slot1
	.long NakaInst_StylCnvSelBox
	.long NakaEmpty_StylCnvTxt_Slot1
	.long NakaEmpty_StylCnvTxt_Slot2
	.long NakaEmpty_StylCnvTxt_Slot3
	.long NakaEmpty_StylCnvTxt_Slot4
	.long NakaEmpty_StylCnvTxt_Slot5
	.long NakaEmpty_StylCnvTxt_Slot6
NakaEmpty_StylCnvTxt_Slot6:	aligned_string ""
NakaEmpty_StylCnvTxt_Slot5:	aligned_string ""
NakaEmpty_StylCnvTxt_Slot4:	aligned_string ""
NakaEmpty_StylCnvTxt_Slot3:	aligned_string ""
NakaEmpty_StylCnvTxt_Slot2:	aligned_string ""
NakaEmpty_StylCnvTxt_Slot1:	aligned_string ""
NakaInst_StylCnvSelBox:	aligned_string "StylCnvSelBox"
NakaEmpty_StylCnvSel_Slot1:	aligned_string ""
NakaInst_StylCnvSelScreen:	aligned_string "StylCnvSelScreen"
	.long NakaInst_StylCnvContScreen
Naka_StylCnvSelBox_Screens:
	.long NakaEmpty_StylCnvSelBox_Slot1
	.long NakaEmpty_StylCnvSelBox_Slot2
	.long NakaEmpty_StylCnvSelBox_Slot3
	.long NakaEmpty_StylCnvSelBox_Slot4
	.long NakaEmpty_StylCnvSelBox_Slot5
	.long NakaEmpty_StylCnvSelBox_Slot6
	.long NakaEmpty_StylCnvSelBox_Slot7
NakaEmpty_StylCnvSelBox_Slot7:	aligned_string ""
NakaEmpty_StylCnvSelBox_Slot6:	aligned_string ""
NakaEmpty_StylCnvSelBox_Slot5:	aligned_string ""
NakaEmpty_StylCnvSelBox_Slot4:	aligned_string ""
NakaEmpty_StylCnvSelBox_Slot3:	aligned_string ""
NakaEmpty_StylCnvSelBox_Slot2:	aligned_string ""
NakaEmpty_StylCnvSelBox_Slot1:	aligned_string ""
NakaInst_StylCnvContScreen:	aligned_string "StylCnvContScreen"
	.long NakaInst_CmpMenuScreen
Naka_StylCnvCont_Screens:
	.long NakaEmpty_StylCnvCont_Slot1
	.long NakaEmpty_StylCnvCont_Slot2
	.long NakaEmpty_StylCnvCont_Slot3
	.long NakaEmpty_StylCnvCont_Slot4
	.long NakaEmpty_StylCnvCont_Slot5
	.long NakaEmpty_StylCnvCont_Slot6
	.long NakaEmpty_StylCnvCont_Slot7
	.long NakaEmpty_StylCnvCont_Slot8
	.long NakaEmpty_StylCnvCont_Slot9
	.long NakaEmpty_StylCnvCont_Slot10
	.long NakaEmpty_StylCnvCont_Slot11
	.long NakaEmpty_StylCnvCont_Slot12
	.long NakaEmpty_StylCnvCont_Slot13
	.long NakaEmpty_StylCnvCont_Slot14
	.long NakaEmpty_StylCnvCont_Slot15
	.long NakaEmpty_StylCnvCont_Slot16
	.long NakaEmpty_StylCnvCont_Slot17
	.long NakaEmpty_StylCnvCont_Slot18
NakaEmpty_StylCnvCont_Slot18:	aligned_string ""
NakaEmpty_StylCnvCont_Slot17:	aligned_string ""
NakaEmpty_StylCnvCont_Slot16:	aligned_string ""
NakaEmpty_StylCnvCont_Slot15:	aligned_string ""
NakaEmpty_StylCnvCont_Slot14:	aligned_string ""
NakaEmpty_StylCnvCont_Slot13:	aligned_string ""
NakaEmpty_StylCnvCont_Slot12:	aligned_string ""
NakaEmpty_StylCnvCont_Slot11:	aligned_string ""
NakaEmpty_StylCnvCont_Slot10:	aligned_string ""
NakaEmpty_StylCnvCont_Slot9:	aligned_string ""
NakaEmpty_StylCnvCont_Slot8:	aligned_string ""
NakaEmpty_StylCnvCont_Slot7:	aligned_string ""
NakaEmpty_StylCnvCont_Slot6:	aligned_string ""
NakaEmpty_StylCnvCont_Slot5:	aligned_string ""
NakaEmpty_StylCnvCont_Slot4:	aligned_string ""
NakaEmpty_StylCnvCont_Slot3:	aligned_string ""
NakaEmpty_StylCnvCont_Slot2:	aligned_string ""
NakaEmpty_StylCnvCont_Slot1:	aligned_string ""
NakaInst_CmpMenuScreen:	aligned_string "CmpMenuScreen"
Naka_CmpMenu_Screens:
	.long NakaInst_CmpBkslScreen
	.long NakaEmpty_CmpMenu_Slot1
	.long NakaEmpty_CmpMenu_Slot2
	.long NakaEmpty_CmpMenu_Slot3
	.long NakaEmpty_CmpMenu_Slot4
	.long NakaEmpty_CmpMenu_Slot5
	.long NakaEmpty_CmpMenu_Slot6
	.long NakaEmpty_CmpMenu_Slot7
	.long NakaEmpty_CmpMenu_Slot8
	.long NakaEmpty_CmpMenu_Slot9
	.long NakaEmpty_CmpMenu_Slot10
	.long NakaEmpty_CmpMenu_Slot11
	.long NakaEmpty_CmpMenu_Slot12
NakaEmpty_CmpMenu_Slot12:	aligned_string ""
NakaEmpty_CmpMenu_Slot11:	aligned_string ""
NakaEmpty_CmpMenu_Slot10:	aligned_string ""
NakaEmpty_CmpMenu_Slot9:	aligned_string ""
NakaEmpty_CmpMenu_Slot8:	aligned_string ""
NakaEmpty_CmpMenu_Slot7:	aligned_string ""
NakaEmpty_CmpMenu_Slot6:	aligned_string ""
NakaEmpty_CmpMenu_Slot5:	aligned_string ""
NakaEmpty_CmpMenu_Slot4:	aligned_string ""
NakaEmpty_CmpMenu_Slot3:	aligned_string ""
NakaEmpty_CmpMenu_Slot2:	aligned_string ""
NakaEmpty_CmpMenu_Slot1:	aligned_string ""
NakaInst_CmpBkslScreen:	aligned_string "CmpBkslScreen"
	.long NakaInst_CmpBkslSScreen
Naka_CmpBookshelf_Screens:
	.long NakaEmpty_CmpBksl_Slot16
	.long NakaEmpty_CmpBksl_Slot17
	.long NakaEmpty_CmpBksl_Slot18
	.long NakaEmpty_CmpBksl_Slot4
	.long NakaEmpty_CmpBksl_Slot5
	.long NakaEmpty_CmpBksl_Slot6
	.long NakaEmpty_CmpBksl_Slot7
	.long NakaEmpty_CmpBksl_Slot8
	.long NakaEmpty_CmpBksl_Slot9
	.long NakaEmpty_CmpBksl_Slot10
	.long NakaEmpty_CmpBksl_Slot11
	.long NakaEmpty_CmpBksl_Slot12
	.long NakaEmpty_CmpBksl_Slot13
	.long NakaEmpty_CmpBksl_Slot14
	.long NakaEmpty_CmpBksl_Slot15
	.long NakaInst_CmpNameMenu
	.long NakaEmpty_CmpBksl_Slot3
	.long NakaInst_CmpClrSure
	.long NakaInst_CmpClrYesSw
	.long NakaInst_CmpClrNoSw
	.long NakaEmpty_CmpBksl_Slot1
	.long NakaEmpty_CmpBksl_Slot2
NakaEmpty_CmpBksl_Slot2:	aligned_string ""
NakaEmpty_CmpBksl_Slot1:	aligned_string ""
NakaInst_CmpClrNoSw:	aligned_string "CmpClrNoSw"
NakaInst_CmpClrYesSw:	aligned_string "CmpClrYesSw"
NakaInst_CmpClrSure:	aligned_string "CmpClrSure"
NakaEmpty_CmpBksl_Slot3:	aligned_string ""
NakaInst_CmpNameMenu:	aligned_string "CmpNameMenu"
NakaEmpty_CmpBksl_Slot15:	aligned_string ""
NakaEmpty_CmpBksl_Slot14:	aligned_string ""
NakaEmpty_CmpBksl_Slot13:	aligned_string ""
NakaEmpty_CmpBksl_Slot12:	aligned_string ""
NakaEmpty_CmpBksl_Slot11:	aligned_string ""
NakaEmpty_CmpBksl_Slot10:	aligned_string ""
NakaEmpty_CmpBksl_Slot9:	aligned_string ""
NakaEmpty_CmpBksl_Slot8:	aligned_string ""
NakaEmpty_CmpBksl_Slot7:	aligned_string ""
NakaEmpty_CmpBksl_Slot6:	aligned_string ""
NakaEmpty_CmpBksl_Slot5:	aligned_string ""
NakaEmpty_CmpBksl_Slot4:	aligned_string ""
NakaEmpty_CmpBksl_Slot18:	aligned_string ""
NakaEmpty_CmpBksl_Slot17:	aligned_string ""
NakaEmpty_CmpBksl_Slot16:	aligned_string ""
NakaInst_CmpBkslSScreen:	aligned_string "CmpBkslSScreen"
	.long NakaInst_CmpNamingScreen
Naka_CmpBookshelfSub_Screens:
	.long NakaEmpty_CmpBkslSub_Slot2
	.long NakaEmpty_CmpBkslSub_Slot3
	.long NakaInst_NameMemLabel
	.long NakaInst_NamingMem
	.long NakaEmpty_CmpBkslSub_Slot1
NakaEmpty_CmpBkslSub_Slot1:	aligned_string ""
NakaInst_NamingMem:	aligned_string "NamingMem"
NakaInst_NameMemLabel:	aligned_string "NameMemLabel"
NakaEmpty_CmpBkslSub_Slot3:	aligned_string ""
NakaEmpty_CmpBkslSub_Slot2:	aligned_string ""
NakaInst_CmpNamingScreen:	aligned_string "CmpNamingScreen"
Naka_NamingMem_Screens:
	.long NakaInst_CmpSetScreen
	.long NakaEmpty_CmpSet_Slot8
	.long NakaInst_CmSetPage
	.long NakaInst_CmSetP1Ctl
	.long NakaInst_CmSetP2Ctl
	.long NakaEmpty_CmpSet_Slot7
	.long NakaInst_CmSetPage1
	.long NakaInst_CmSetP1Grid
	.long NakaEmpty_CmpSet_Slot2
	.long NakaEmpty_CmpSet_Slot3
	.long NakaEmpty_CmpSet_Slot4
	.long NakaEmpty_CmpSet_Slot5
	.long NakaEmpty_CmpSet_Slot6
	.long NakaInst_CmSetPage2
	.long NakaInst_CmpSetGrid
	.long NakaInst_CmSetPartSw
	.long NakaInst_CmSetPanSw
	.long NakaInst_CmSetRLmtSw
	.long NakaEmpty_CmpSet_Slot1
NakaEmpty_CmpSet_Slot1:	aligned_string ""
NakaInst_CmSetRLmtSw:	aligned_string "CmSetRLmtSw"
NakaInst_CmSetPanSw:	aligned_string "CmSetPanSw"
NakaInst_CmSetPartSw:	aligned_string "CmSetPartSw"
NakaInst_CmpSetGrid:	aligned_string "CmpSetGrid"
NakaInst_CmSetPage2:	aligned_string "CmSetPage2"
NakaEmpty_CmpSet_Slot6:	aligned_string ""
NakaEmpty_CmpSet_Slot5:	aligned_string ""
NakaEmpty_CmpSet_Slot4:	aligned_string ""
NakaEmpty_CmpSet_Slot3:	aligned_string ""
NakaEmpty_CmpSet_Slot2:	aligned_string ""
NakaInst_CmSetP1Grid:	aligned_string "CmSetP1Grid"
NakaInst_CmSetPage1:	aligned_string "CmSetPage1"
NakaEmpty_CmpSet_Slot7:	aligned_string ""
NakaInst_CmSetP2Ctl:	aligned_string "CmSetP2Ctl"
NakaInst_CmSetP1Ctl:	aligned_string "CmSetP1Ctl"
NakaInst_CmSetPage:	aligned_string "CmSetPage"
NakaEmpty_CmpSet_Slot8:	aligned_string ""
NakaInst_CmpSetScreen:	aligned_string "CmpSetScreen"
Naka_CmSetP1Grid_Screens:
	.long NakaInst_CmpRealScreen
	.long NakaEmpty_CmpReal_Slot23
	.long NakaInst_CmpMem
	.long NakaEmpty_CmpReal_Slot2
	.long NakaEmpty_CmpReal_Slot3
	.long NakaEmpty_CmpReal_Slot4
	.long NakaEmpty_CmpReal_Slot5
	.long NakaEmpty_CmpReal_Slot6
	.long NakaEmpty_CmpReal_Slot7
	.long NakaEmpty_CmpReal_Slot8
	.long NakaEmpty_CmpReal_Slot9
	.long NakaEmpty_CmpReal_Slot10
	.long NakaEmpty_CmpReal_Slot11
	.long NakaEmpty_CmpReal_Slot12
	.long NakaEmpty_CmpReal_Slot13
	.long NakaEmpty_CmpReal_Slot14
	.long NakaEmpty_CmpReal_Slot15
	.long NakaEmpty_CmpReal_Slot16
	.long NakaEmpty_CmpReal_Slot17
	.long NakaEmpty_CmpReal_Slot18
	.long NakaEmpty_CmpReal_Slot19
	.long NakaEmpty_CmpReal_Slot20
	.long NakaEmpty_CmpReal_Slot21
	.long NakaEmpty_CmpReal_Slot22
	.long NakaInst_DrmRec
	.long NakaInst_Ac3Rec
	.long NakaInst_Ac2Rec
	.long NakaInst_Ac1Rec
	.long NakaInst_BasRec
	.long NakaInst_CmpQtz
	.long NakaInst_CmpMeas
	.long NakaEmpty_CmpReal_Slot1
NakaEmpty_CmpReal_Slot1:	aligned_string ""
NakaInst_CmpMeas:	aligned_string "CmpMeas"
NakaInst_CmpQtz:	aligned_string "CmpQtz"
NakaInst_BasRec:	aligned_string "BasRec"
NakaInst_Ac1Rec:	aligned_string "Ac1Rec"
NakaInst_Ac2Rec:	aligned_string "Ac2Rec"
NakaInst_Ac3Rec:	aligned_string "Ac3Rec"
NakaInst_DrmRec:	aligned_string "DrmRec"
NakaEmpty_CmpReal_Slot22:	aligned_string ""
NakaEmpty_CmpReal_Slot21:	aligned_string ""
NakaEmpty_CmpReal_Slot20:	aligned_string ""
NakaEmpty_CmpReal_Slot19:	aligned_string ""
NakaEmpty_CmpReal_Slot18:	aligned_string ""
NakaEmpty_CmpReal_Slot17:	aligned_string ""
NakaEmpty_CmpReal_Slot16:	aligned_string ""
NakaEmpty_CmpReal_Slot15:	aligned_string ""
NakaEmpty_CmpReal_Slot14:	aligned_string ""
NakaEmpty_CmpReal_Slot13:	aligned_string ""
NakaEmpty_CmpReal_Slot12:	aligned_string ""
NakaEmpty_CmpReal_Slot11:	aligned_string ""
NakaEmpty_CmpReal_Slot10:	aligned_string ""
NakaEmpty_CmpReal_Slot9:	aligned_string ""
NakaEmpty_CmpReal_Slot8:	aligned_string ""
NakaEmpty_CmpReal_Slot7:	aligned_string ""
NakaEmpty_CmpReal_Slot6:	aligned_string ""
NakaEmpty_CmpReal_Slot5:	aligned_string ""
NakaEmpty_CmpReal_Slot4:	aligned_string ""
NakaEmpty_CmpReal_Slot3:	aligned_string ""
NakaEmpty_CmpReal_Slot2:	aligned_string ""
NakaInst_CmpMem:	aligned_string "CmpMem"
NakaEmpty_CmpReal_Slot23:	aligned_string ""
NakaInst_CmpRealScreen:	aligned_string "CmpRealScreen"
	and	w, (xwa)
	.byte 0xe1, 0x00
	.long NakaEmpty_CmpReal_Slot24
NakaEmpty_CmpReal_Slot24:	aligned_string ""
NakaEmpty_CmpReal_Slot25:	aligned_string ""
Naka_CmpMem_Screens:
	.long NakaInst_CmpBalScreen
	.long NakaInst_CmpDrmVol
	.long NakaInst_CmpAc3Vol
	.long NakaInst_CmpAc2Vol
	.long NakaInst_CmpAc1Vol
	.long NakaInst_CmpBasVol
	.long NakaEmpty_CmpBal_Slot1
NakaEmpty_CmpBal_Slot1:	aligned_string ""
NakaInst_CmpBasVol:	aligned_string "CmpBasVol"
NakaInst_CmpAc1Vol:	aligned_string "CmpAc1Vol"
NakaInst_CmpAc2Vol:	aligned_string "CmpAc2Vol"
NakaInst_CmpAc3Vol:	aligned_string "CmpAc3Vol"
NakaInst_CmpDrmVol:	aligned_string "CmpDrmVol"
NakaInst_CmpBalScreen:	aligned_string "CmpBalScreen"
PtrTbl_CmpNcpScreenStrs:
	.long StrCmpNcpScreen
	.long StrCmpNcpFitmSw_Empty
	.long StrCmpNcpFitmSw
	.long StrCmpNcpTitmSw_Empty
	.long StrCmpNcpTitmSw
	.long StrCmpCpFPtn_EmptyD
	.long StrCmpCpFPtn_EmptyC
	.long StrCmpCpFPtn_EmptyB
	.long StrCmpCpFPtn_EmptyA
	.long StrCmpCpFPtn_Empty9
	.long StrCmpCpFPtn_Empty8
	.long StrCmpCpFPtn_Empty7
	.long StrCmpCpFPtn_Empty6
	.long StrCmpCpFPtn_Empty5
	.long StrCmpCpFPtn_Empty4
	.long StrCmpCpFPtn_Empty3
	.long StrCmpCpFPtn_Empty2
	.long StrCmpCpFPtn_Empty1
	.long StrCmpCpFPtn
	.long StrCmpCpTMem_Empty7
	.long StrCmpCpTMem_Empty6
	.long StrCmpCpTMem_Empty5
	.long StrCmpCpTMem_Empty4
	.long StrCmpCpTMem_Empty3
	.long StrCmpCpTMem_Empty2
	.long StrCmpCpTMem_Empty1
	.long StrCmpCpTMem
	.long StrCmpCpTPtn
	.long StrCmpCpFGrp_Empty2
	.long StrCmpCpFGrp_Empty1
	.long StrCmpCpFGrp
	.long StrCmpCpFVari
	.long StrCmpCpFVari_Empty2
	.long StrCmpCpFVari_Empty1
StrCmpCpFVari_Empty1:	aligned_string ""
StrCmpCpFVari_Empty2:	aligned_string ""
StrCmpCpFVari:		aligned_string "CmpCpFVari"
StrCmpCpFGrp:		aligned_string "CmpCpFGrp"
StrCmpCpFGrp_Empty1:	aligned_string ""
StrCmpCpFGrp_Empty2:	aligned_string ""
StrCmpCpTPtn:		aligned_string "CmpCpTPtn"
StrCmpCpTMem:		aligned_string "CmpCpTMem"
StrCmpCpTMem_Empty1:	aligned_string ""
StrCmpCpTMem_Empty2:	aligned_string ""
StrCmpCpTMem_Empty3:	aligned_string ""
StrCmpCpTMem_Empty4:	aligned_string ""
StrCmpCpTMem_Empty5:	aligned_string ""
StrCmpCpTMem_Empty6:	aligned_string ""
StrCmpCpTMem_Empty7:	aligned_string ""
StrCmpCpFPtn:		aligned_string "CmpCpFPtn"
StrCmpCpFPtn_Empty1:	aligned_string ""
StrCmpCpFPtn_Empty2:	aligned_string ""
StrCmpCpFPtn_Empty3:	aligned_string ""
StrCmpCpFPtn_Empty4:	aligned_string ""
StrCmpCpFPtn_Empty5:	aligned_string ""
StrCmpCpFPtn_Empty6:	aligned_string ""
StrCmpCpFPtn_Empty7:	aligned_string ""
StrCmpCpFPtn_Empty8:	aligned_string ""
StrCmpCpFPtn_Empty9:	aligned_string ""
StrCmpCpFPtn_EmptyA:	aligned_string ""
StrCmpCpFPtn_EmptyB:	aligned_string ""
StrCmpCpFPtn_EmptyC:	aligned_string ""
StrCmpCpFPtn_EmptyD:	aligned_string ""
StrCmpNcpTitmSw:	aligned_string "CmpNcpTitmSw"
StrCmpNcpTitmSw_Empty:	aligned_string ""
StrCmpNcpFitmSw:	aligned_string "CmpNcpFitmSw"
StrCmpNcpFitmSw_Empty:	aligned_string ""
StrCmpNcpScreen:	aligned_string "CmpNcpScreen"
PtrTbl_S2cScreenStrs:
	.long StrS2cScreen
	.long StrS2cTrans_Empty17
	.long StrS2cTrans_Empty16
	.long StrS2cTrans_Empty15
	.long StrS2cTrans_Empty14
	.long StrS2cTrans_Empty13
	.long StrS2cTrans_Empty12
	.long StrS2cTrans_Empty11
	.long StrS2cTrans_Empty10
	.long StrS2cTrans_EmptyF
	.long StrS2cTrans_EmptyE
	.long StrS2cTrans_EmptyD
	.long StrS2cTrans_EmptyC
	.long StrS2cTrans_EmptyB
	.long StrS2cTrans_EmptyA
	.long StrS2cTrans_Empty9
	.long StrS2cTrans_Empty8
	.long StrS2cTrans_Empty7
	.long StrS2cTrans_Empty6
	.long StrS2cTrans_Empty5
	.long StrS2cTrans_Empty4
	.long StrS2cTrans_Empty3
	.long StrS2cTrans_Empty2
	.long StrS2cTrans_Empty1
	.long StrS2cTrans
	.long StrS2cFmeas_Empty3
	.long StrS2cFmeas_Empty2
	.long StrS2cFmeas_Empty1
	.long StrS2cFmeas
	.long StrS2cSeqSongNo
	.long StrS2cMemNo
	.long StrS2cLmeas
	.long StrS2cLmeas_Empty
	.long StrS2cGrid
	.long StrS2cGrid_Empty4
	.long StrS2cGrid_Empty3
	.long StrS2cGrid_Empty2
	.long StrS2cGrid_Empty1
StrS2cGrid_Empty1:	aligned_string ""
StrS2cGrid_Empty2:	aligned_string ""
StrS2cGrid_Empty3:	aligned_string ""
StrS2cGrid_Empty4:	aligned_string ""
StrS2cGrid:		aligned_string "S2cGrid"
StrS2cLmeas_Empty:	aligned_string ""
StrS2cLmeas:		aligned_string "S2cLmeas"
StrS2cMemNo:		aligned_string "S2cMemNo"
StrS2cSeqSongNo:	aligned_string "S2cSeqSongNo"
StrS2cFmeas:		aligned_string "S2cFmeas"
StrS2cFmeas_Empty1:	aligned_string ""
StrS2cFmeas_Empty2:	aligned_string ""
StrS2cFmeas_Empty3:	aligned_string ""
StrS2cTrans:		aligned_string "S2cTrans"
StrS2cTrans_Empty1:	aligned_string ""
StrS2cTrans_Empty2:	aligned_string ""
StrS2cTrans_Empty3:	aligned_string ""
StrS2cTrans_Empty4:	aligned_string ""
StrS2cTrans_Empty5:	aligned_string ""
StrS2cTrans_Empty6:	aligned_string ""
StrS2cTrans_Empty7:	aligned_string ""
StrS2cTrans_Empty8:	aligned_string ""
StrS2cTrans_Empty9:	aligned_string ""
StrS2cTrans_EmptyA:	aligned_string ""
StrS2cTrans_EmptyB:	aligned_string ""
StrS2cTrans_EmptyC:	aligned_string ""
StrS2cTrans_EmptyD:	aligned_string ""
StrS2cTrans_EmptyE:	aligned_string ""
StrS2cTrans_EmptyF:	aligned_string ""
StrS2cTrans_Empty10:	aligned_string ""
StrS2cTrans_Empty11:	aligned_string ""
StrS2cTrans_Empty12:	aligned_string ""
StrS2cTrans_Empty13:	aligned_string ""
StrS2cTrans_Empty14:	aligned_string ""
StrS2cTrans_Empty15:	aligned_string ""
StrS2cTrans_Empty16:	aligned_string ""
StrS2cTrans_Empty17:	aligned_string ""
StrS2cScreen:		aligned_string "S2CScreen"
PtrTbl_EasyCompScreenStrs:
	.long StrCmpEasyScreen
	.long StrEsCmpMemNo_Empty8
	.long StrEsCmpMemNo_Empty7
	.long StrEsCmpMemNo_Empty6
	.long StrEsCmpMemNo_Empty5
	.long StrEsCmpMemNo_Empty4
	.long StrEsCmpMemNo_Empty3
	.long StrEsCmpMemNo_Empty2
	.long StrEsCmpMemNo_Empty1
	.long StrEsCmpMemNo
	.long StrEasyCmpGrid
	.long StrEasyCmpGrid_Empty4
	.long StrEasyCmpGrid_Empty3
	.long StrEasyCmpGrid_Empty2
	.long StrEasyCmpGrid_Empty1
StrEasyCmpGrid_Empty1:	aligned_string ""
StrEasyCmpGrid_Empty2:	aligned_string ""
StrEasyCmpGrid_Empty3:	aligned_string ""
StrEasyCmpGrid_Empty4:	aligned_string ""
StrEasyCmpGrid:		aligned_string "EasyCmpGrid"
StrEsCmpMemNo:		aligned_string "EsCmpMemNo"
StrEsCmpMemNo_Empty1:	aligned_string ""
StrEsCmpMemNo_Empty2:	aligned_string ""
StrEsCmpMemNo_Empty3:	aligned_string ""
StrEsCmpMemNo_Empty4:	aligned_string ""
StrEsCmpMemNo_Empty5:	aligned_string ""
StrEsCmpMemNo_Empty6:	aligned_string ""
StrEsCmpMemNo_Empty7:	aligned_string ""
StrEsCmpMemNo_Empty8:	aligned_string ""
StrCmpEasyScreen:	aligned_string "CmpEasyScreen"
PtrTbl_BendScreenStrs:
	.long StrCmpBendScreen
	.long StrCmpBendScreen_Empty4
	.long StrCmpBendScreen_Empty3
	.long StrCmpBendScreen_Empty2
	.long StrCmpBendScreen_Empty1
StrCmpBendScreen_Empty1:	aligned_string ""
StrCmpBendScreen_Empty2:	aligned_string ""
StrCmpBendScreen_Empty3:	aligned_string ""
StrCmpBendScreen_Empty4:	aligned_string ""
StrCmpBendScreen:		aligned_string "CmpBendScreen"
	.long StrCmpModeScreen
PtrTbl_ModeScreenStrs:
	.long StrCmpModeScreen_EmptyB
	.long StrCmpModeScreen_EmptyA
	.long StrCmpModeScreen_Empty9
	.long StrCmpModeScreen_Empty8
	.long StrCmpModeScreen_Empty7
	.long StrCmpModeScreen_Empty6
	.long StrCmpModeScreen_Empty5
	.long StrCmpModeScreen_Empty4
	.long StrCmpModeScreen_Empty3
	.long StrCmpModeScreen_Empty2
	.long StrCmpModeScreen_Empty1
StrCmpModeScreen_Empty1:	aligned_string ""
StrCmpModeScreen_Empty2:	aligned_string ""
StrCmpModeScreen_Empty3:	aligned_string ""
StrCmpModeScreen_Empty4:	aligned_string ""
StrCmpModeScreen_Empty5:	aligned_string ""
StrCmpModeScreen_Empty6:	aligned_string ""
StrCmpModeScreen_Empty7:	aligned_string ""
StrCmpModeScreen_Empty8:	aligned_string ""
StrCmpModeScreen_Empty9:	aligned_string ""
StrCmpModeScreen_EmptyA:	aligned_string ""
StrCmpModeScreen_EmptyB:	aligned_string ""
StrCmpModeScreen:		aligned_string "CmpModeScreen"
PtrTbl_CstmCpScreenStrs:
	.long StrCmpCstmCpScreen
	.long StrCmpCstmCpScreen_Empty2
	.long StrCmpCstmCpScreen_Empty1
	.long StrCstmCpFrmVal
	.long StrCstmCpFName
	.long StrCstmCpFName_Empty5
	.long StrCstmCpFName_Empty4
	.long StrCstmCpFName_Empty3
	.long StrCstmCpFName_Empty2
	.long StrCstmCpFName_Empty1
	.long StrCstmCpToSw
	.long StrCstmCpToVal
	.long StrCstmCpToVal_Empty
	.long StrCstmCpFChar
	.long StrCstmCpTChar
	.long StrCstmCpTName
	.long StrCstmCpTName_Empty
	.long StrCstmMemFulWin
	.long StrCstmMemFulWin_Empty4
	.long StrCstmMemFulWin_Empty3
	.long StrCstmMemFulWin_Empty2
	.long StrCstmMemFulWin_Empty1
	.long StrCtmMFulStr
	.long StrCtmMFulStr_Empty2
	.long StrCtmMFulStr_Empty1
	.long StrCstmFuncSelWin
	.long StrCstmFuncSelWin_Empty4
	.long StrCstmFuncSelWin_Empty3
	.long StrCstmFuncSelWin_Empty2
	.long StrCstmFuncSelWin_Empty1
	.long StrCtmSMemStr
	.long StrCtmSMemStr_Empty3
	.long StrCtmSMemStr_Empty2
	.long StrCtmSMemStr_Empty1
StrCtmSMemStr_Empty1:		aligned_string ""
StrCtmSMemStr_Empty2:		aligned_string ""
StrCtmSMemStr_Empty3:		aligned_string ""
StrCtmSMemStr:			aligned_string "CtmSMemStr"
StrCstmFuncSelWin_Empty1:	aligned_string ""
StrCstmFuncSelWin_Empty2:	aligned_string ""
StrCstmFuncSelWin_Empty3:	aligned_string ""
StrCstmFuncSelWin_Empty4:	aligned_string ""
StrCstmFuncSelWin:		aligned_string "CstmFuncSelWin"
StrCtmMFulStr_Empty1:		aligned_string ""
StrCtmMFulStr_Empty2:		aligned_string ""
StrCtmMFulStr:			aligned_string "CtmMFulStr"
StrCstmMemFulWin_Empty1:	aligned_string ""
StrCstmMemFulWin_Empty2:	aligned_string ""
StrCstmMemFulWin_Empty3:	aligned_string ""
StrCstmMemFulWin_Empty4:	aligned_string ""
StrCstmMemFulWin:		aligned_string "CstmMemFulWin"
StrCstmCpTName_Empty:		aligned_string ""
StrCstmCpTName:			aligned_string "CstmCpTName"
StrCstmCpTChar:			aligned_string "CstmCpTChar"
StrCstmCpFChar:			aligned_string "CstmCpFChar"
StrCstmCpToVal_Empty:		aligned_string ""
StrCstmCpToVal:			aligned_string "CstmCpToVal"
StrCstmCpToSw:			aligned_string "CstmCpToSw"
StrCstmCpFName_Empty1:		aligned_string ""
StrCstmCpFName_Empty2:		aligned_string ""
StrCstmCpFName_Empty3:		aligned_string ""
StrCstmCpFName_Empty4:		aligned_string ""
StrCstmCpFName_Empty5:		aligned_string ""
StrCstmCpFName:			aligned_string "CstmCpFName"
StrCstmCpFrmVal:		aligned_string "CstmCpFrmVal"
StrCmpCstmCpScreen_Empty1:	aligned_string ""
StrCmpCstmCpScreen_Empty2:	aligned_string ""
StrCmpCstmCpScreen:		aligned_string "CmpCstmCpScreen"
PtrTbl_MspBkslScreenStrs:
	.long StrMspBkslScreen
	.long StrMspBkslWin
	.long StrMspBnkP1Ctl
	.long StrMspBnkP2Ctl
	.long StrMspBnkP2Ctl_Empty2
	.long StrMspBnkP2Ctl_Empty1
	.long StrMspBkslP1Win
	.long StrEff1Bnk
	.long StrEff2Bnk
	.long StrComicBnk
	.long StrMovieBnk
	.long StrEnterBnk
	.long StrArpgioBnk
	.long StrRock1Bnk
	.long StrRock2Bnk
	.long StrDanceBnk
	.long StrFunkBnk
	.long StrMspBkslP2Win
	.long StrJazzBnk
	.long StrLatinBnk
	.long StrHitBnk
	.long StrUser1Bnk
	.long StrUser2Bnk
	.long StrCmpile1Bnk
	.long StrCmpile2Bnk
	.long StrCtrl1Bnk
	.long StrCtrl2Bnk
	.long StrCtrl2Bnk_Empty
StrCtrl2Bnk_Empty:	aligned_string ""
StrCtrl2Bnk:		aligned_string "Ctrl2Bnk"
StrCtrl1Bnk:		aligned_string "Ctrl1Bnk"
StrCmpile2Bnk:		aligned_string "Cmpile2Bnk"
StrCmpile1Bnk:		aligned_string "Cmpile1Bnk"
StrUser2Bnk:		aligned_string "User2Bnk"
StrUser1Bnk:		aligned_string "User1Bnk"
StrHitBnk:		aligned_string "HitBnk"
StrLatinBnk:		aligned_string "LatinBnk"
StrJazzBnk:		aligned_string "JazzBnk"
StrMspBkslP2Win:	aligned_string "MspBkslP2Win"
StrFunkBnk:		aligned_string "FunkBnk"
StrDanceBnk:		aligned_string "DanceBnk"
StrRock2Bnk:		aligned_string "Rock2Bnk"
StrRock1Bnk:		aligned_string "Rock1Bnk"
StrArpgioBnk:		aligned_string "ArpgioBnk"
StrEnterBnk:		aligned_string "EnterBnk"
StrMovieBnk:		aligned_string "MovieBnk"
StrComicBnk:		aligned_string "ComicBnk"
StrEff2Bnk:		aligned_string "Eff2Bnk"
StrEff1Bnk:		aligned_string "Eff1Bnk"
StrMspBkslP1Win:	.asciz "MspBkslP1Win"
	.byte 0xff
StrMspBnkP2Ctl_Empty1:	aligned_string ""
StrMspBnkP2Ctl_Empty2:	aligned_string ""
StrMspBnkP2Ctl:		aligned_string "MspBnkP2Ctl"
StrMspBnkP1Ctl:		aligned_string "MspBnkP1Ctl"
StrMspBkslWin:		aligned_string "MspBkslWin"
StrMspBkslScreen:	aligned_string "MspBkslScreen"
	.long StrMspRecScreen
PtrTbl_MspRecScreenStrs:
	.long StrMspRecBox1
	.long StrMspRecBox1_Empty
	.long StrMspBnkLbl
	.long StrRecPadNo
	.long StrRecBankName
	.long StrMspRecBox2
	.long StrMspRecBox2_Empty
	.long StrMspTempo
	.long StrMspMeas
	.long StrMspMem
	.long StrMspMem_Empty
	.long StrMspPadLbl
	.long StrMspPadLbl_Empty4
	.long StrMspPadLbl_Empty3
	.long StrMspPadLbl_Empty2
	.long StrMspPadLbl_Empty1
StrMspPadLbl_Empty1:	aligned_string ""
StrMspPadLbl_Empty2:	aligned_string ""
StrMspPadLbl_Empty3:	aligned_string ""
StrMspPadLbl_Empty4:	aligned_string ""
StrMspPadLbl:		aligned_string "MspPadLbl"
StrMspMem_Empty:	aligned_string ""
StrMspMem:		aligned_string "MspMem"
StrMspMeas:		aligned_string "MspMeas"
StrMspTempo:		aligned_string "MspTempo"
StrMspRecBox2_Empty:	aligned_string ""
StrMspRecBox2:		aligned_string "MspRecBox2"
StrRecBankName:		aligned_string "RecBankName"
StrRecPadNo:		aligned_string "RecPadNo"
StrMspBnkLbl:		aligned_string "MspBnkLbl"
StrMspRecBox1_Empty:	aligned_string ""
StrMspRecBox1:		aligned_string "MspRecBox1"
StrMspRecScreen:	aligned_string "MspRecScreen"
PtrTbl_MspMenuScreenStrs:
	.long StrMspMenuScreen
	.long StrMspMenuScreen_Empty6
	.long StrMspMenuScreen_Empty5
	.long StrMspMenuScreen_Empty4
	.long StrMspMenuScreen_Empty3
	.long StrMspMenuScreen_Empty2
	.long StrMspMenuScreen_Empty1
StrMspMenuScreen_Empty1:	aligned_string ""
StrMspMenuScreen_Empty2:	aligned_string ""
StrMspMenuScreen_Empty3:	aligned_string ""
StrMspMenuScreen_Empty4:	aligned_string ""
StrMspMenuScreen_Empty5:	aligned_string ""
StrMspMenuScreen_Empty6:	aligned_string ""
StrMspMenuScreen:		aligned_string "MspMenuScreen"
	and	xsp, xde
	.byte 0xe1, 0x00


PtrTbl_MspNamingScreenStrs:
	.long StrMspNamingScreen_Empty4
	.long StrMspNamingScreen_Empty3
	.long StrMspNamingScreen_Empty2
	.long StrMspNamingScreen_Empty1
StrMspNamingScreen_Empty1:	aligned_string ""
StrMspNamingScreen_Empty2:	aligned_string ""
StrMspNamingScreen_Empty3:	aligned_string ""
StrMspNamingScreen_Empty4:	aligned_string ""
StrMspNamingScreen:		aligned_string "MspNamingScreen"
PtrTbl_MspReGrpScreenStrs:
	.long StrMspReGrpScreen
	.long StrRGrpBnkSw
	.long StrRGrpBnkSw_Empty
	.long StrMspRGrpGrid
	.long StrMspRGrpGrid_Empty3
	.long StrMspRGrpGrid_Empty2
	.long StrMspRGrpGrid_Empty1
	.long StrRgpSetBnk
	.long StrRgpSetBnk_Empty2
	.long StrRgpSetBnk_Empty1
StrRgpSetBnk_Empty1:	aligned_string ""
StrRgpSetBnk_Empty2:	aligned_string ""
StrRgpSetBnk:		aligned_string "RgpSetBnk"
StrMspRGrpGrid_Empty1:	aligned_string ""
StrMspRGrpGrid_Empty2:	aligned_string ""
StrMspRGrpGrid_Empty3:	aligned_string ""
StrMspRGrpGrid:		aligned_string "MspRGrpGrid"
StrRGrpBnkSw_Empty:	aligned_string ""
StrRGrpBnkSw:		aligned_string "RGrpBnkSw"
StrMspReGrpScreen:	aligned_string "MspReGrpScreen"
PtrTbl_SndArgrScreenStrs:
	.long StrSndArgrScreen
	.long StrSndArgrScreen_Empty
	.long StrSndArgRhyName
	.long StrSndArgRhyName_Empty2
	.long StrSndArgRhyName_Empty1
	.long StrSndArgrGrid
	.long StrSndArgrGrid_Empty3
	.long StrSndArgrGrid_Empty2
	.long StrSndArgrGrid_Empty1
StrSndArgrGrid_Empty1:		aligned_string ""
StrSndArgrGrid_Empty2:		aligned_string ""
StrSndArgrGrid_Empty3:		aligned_string ""
StrSndArgrGrid:			aligned_string "SndArgrGrid"
StrSndArgRhyName_Empty1:	aligned_string ""
StrSndArgRhyName_Empty2:	aligned_string ""
StrSndArgRhyName:		aligned_string "SndArgRhyName"
StrSndArgrScreen_Empty:		aligned_string ""
StrSndArgrScreen:		aligned_string "SndArgrScreen"
PtrTbl_ApcSelScreenStrs:
	.long StrApcSelScreen
	.long StrApcSelScreen_Empty3
	.long StrApcSelScreen_Empty2
	.long StrApcSelScreen_Empty1
	.long StrApcMem
	.long StrApcOnBass
	.long StrApcOnBass_Empty
StrApcOnBass_Empty:	aligned_string ""
StrApcOnBass:

	aligned_string "ApcOnBass"
StrApcMem:	aligned_string "ApcMem"
StrApcSelScreen_Empty1:
	.byte 0x00, 0xff
StrApcSelScreen_Empty2:
	.byte 0x00, 0xff
StrApcSelScreen_Empty3:
	.byte 0x00, 0xff
StrApcSelScreen:	aligned_string "ApcSelScreen"
	aligned_string "MD_CMP"
	aligned_string "MD_MSP"
	aligned_string "MD_MSP_REC"
	aligned_string "MD_SND_ARG"
	aligned_string "TT_STYLCNVWAIT"
	aligned_string "TT_STYLCNVMODL"
	aligned_string "TT_STYLCNVCNVT"
	aligned_string "TT_STYLCNVSTOR"
	aligned_string "TT_STYLCNVTXT"
	aligned_string "TT_STYLCNVSEL"
	aligned_string "TT_STYLCNVCONT"
	aligned_string "TT_CMMENU"
	aligned_string "TT_CMBKSL"
	aligned_string "TT_CMBKSL_S"
	aligned_string "TT_CMNAME"
	aligned_string "TT_CMSET"
	aligned_string "TT_CMREAL"
	aligned_string "TT_CMSTEP"
	aligned_string "TT_CMBAL"
	aligned_string "TT_CMPNCP"
	aligned_string "TT_CMSEQCP"
	aligned_string "TT_CMEASY"
	aligned_string "TT_CMBEND"
	aligned_string "TT_CMMODE"
	aligned_string "TT_CMCSTMCP"
	aligned_string "TT_MSPBKSL"
	aligned_string "TT_MSPREC"
	aligned_string "TT_MSPMENU"
	aligned_string "TT_MSPNAME"
	aligned_string "TT_MSPGROUP"
	aligned_string "TT_SNDARG"
	aligned_string "TT_APCSEL"

	.long CmpModeFunc
	.long CmpSetTtlFunc
	.long CmpRealTtlFunc
	.long CmpBkslTtlFunc
	.long CmpBksl_STtlFunc
	.long CmpMenuTtlFunc
	.long CmpNcpTtlFunc
	.long CmEsyTtlFunc
	.long S2cTtlFunc
	.long CstmCpTtlFunc
	.long MiddleNameFunc
	.long MainCmpCpFunc
	.long MiddleCmpClrFunc
	.long MainCmpSetFunc
	.long MainS2cFunc
	.long MainMspRgpSetFunc
	.long MainMspBnkNameFunc
	.long MspBkslTtlFunc
	.long MspMenuTtlFunc
	.long MspNameTtlFunc
	.long MspRecModeFunc
	.long MspRecTtlFunc
	.long SndArgModeFunc
	.long SndArgTtlFunc
	.long MainEsCmpFunc
	.long CmpStepTitleFunc
	.long MainCstmNameFunc
	.long SndArgNmGet
	.long StylCnvWaitTtlFunc
	.long StylCnvTxtTtlFunc
	.long StylCnvModlTtlFunc
	.long StylCnvCnvtTtlFunc
	.long StylCnvSelTtlFunc
	.long StylCnvContTtlFunc
	.long StylCnvStorTtlFunc
	.long MainStylCnvFunc
	.long 0x0

PtrTbl_FuncNameStrs:
	.long StrCmpModeFunc
	.long StrCmpSetTtlFunc
	.long StrCmpRealTtlFunc
	.long StrCmpBkslTtlFunc
	.long StrCmpBksl_STtlFunc
	.long StrCmpMenuTtlFunc
	.long StrCmpNcpTtlFunc
	.long StrCmEsyTtlFunc
	.long StrS2cTtlFunc
	.long StrCstmCpTtlFunc
	.long StrMiddleNameFunc
	.long StrMainCmpCpFunc
	.long StrMiddleCmpClrFunc
	.long StrMainCmpSetFunc
	.long StrMainS2cFunc
	.long StrMainMspRgpSetFunc
	.long StrMainMspBnkNameFunc
	.long StrMspBkslTtlFunc
	.long StrMspMenuTtlFunc
	.long StrMspNameTtlFunc
	.long StrMspRecModeFunc
	.long StrMspRecTtlFunc
	.long StrSndArgModeFunc
	.long StrSndArgTtlFunc
	.long StrMainEsCmpFunc
	.long StrCmpStepTitleFunc
	.long StrMainCstmNameFunc
	.long StrSndArgNmGet
	.long StrStylCnvWaitTtlFunc
	.long StrStylCnvTxtTtlFunc
	.long StrStylCnvModlTtlFunc
	.long StrStylCnvCnvtTtlFunc
	.long StrStylCnvSelTtlFunc
	.long StrStylCnvContTtlFunc
	.long StrStylCnvStorTtlFunc
	.long StrMainStylCnvFunc
	.long StrFuncNames_Empty
StrFuncNames_Empty:	aligned_string ""
StrMainStylCnvFunc:

	aligned_string "MainStylCnvFunc"
StrStylCnvStorTtlFunc:	aligned_string "StylCnvStorTtlFunc"
StrStylCnvContTtlFunc:	aligned_string "StylCnvContTtlFunc"
StrStylCnvSelTtlFunc:	aligned_string "StylCnvSelTtlFunc"
StrStylCnvCnvtTtlFunc:	aligned_string "StylCnvCnvtTtlFunc"
StrStylCnvModlTtlFunc:	aligned_string "StylCnvModlTtlFunc"
StrStylCnvTxtTtlFunc:	aligned_string "StylCnvTxtTtlFunc"
StrStylCnvWaitTtlFunc:	aligned_string "StylCnvWaitTtlFunc"
StrSndArgNmGet:		aligned_string "SndArgNmGet"
StrMainCstmNameFunc:	aligned_string "MainCstmNameFunc"
StrCmpStepTitleFunc:	aligned_string "CmpStepTitleFunc"
StrMainEsCmpFunc:	aligned_string "MainEsCmpFunc"
StrSndArgTtlFunc:	aligned_string "SndArgTtlFunc"
StrSndArgModeFunc:	aligned_string "SndArgModeFunc"
StrMspRecTtlFunc:	aligned_string "MspRecTtlFunc"
StrMspRecModeFunc:	aligned_string "MspRecModeFunc"
StrMspNameTtlFunc:	aligned_string "MspNameTtlFunc"
StrMspMenuTtlFunc:	aligned_string "MspMenuTtlFunc"
StrMspBkslTtlFunc:	aligned_string "MspBkslTtlFunc"
StrMainMspBnkNameFunc:	aligned_string "MainMspBnkNameFunc"
StrMainMspRgpSetFunc:	aligned_string "MainMspRgpSetFunc"
StrMainS2cFunc:		aligned_string "MainS2cFunc"
StrMainCmpSetFunc:	aligned_string "MainCmpSetFunc"
StrMiddleCmpClrFunc:	aligned_string "MiddleCmpClrFunc"
StrMainCmpCpFunc:	aligned_string "MainCmpCpFunc"
StrMiddleNameFunc:	aligned_string "MiddleNameFunc"
StrCstmCpTtlFunc:	aligned_string "CstmCpTtlFunc"
StrS2cTtlFunc:		aligned_string "S2cTtlFunc"
StrCmEsyTtlFunc:	aligned_string "CmEsyTtlFunc"
StrCmpNcpTtlFunc:	aligned_string "CmpNcpTtlFunc"
StrCmpMenuTtlFunc:	aligned_string "CmpMenuTtlFunc"
StrCmpBksl_STtlFunc:	aligned_string "CmpBksl_STtlFunc"
StrCmpBkslTtlFunc:	aligned_string "CmpBkslTtlFunc"
StrCmpRealTtlFunc:	aligned_string "CmpRealTtlFunc"
StrCmpSetTtlFunc:	aligned_string "CmpSetTtlFunc"
StrCmpModeFunc:		aligned_string "CmpModeFunc"

NoteStepDisplayData:
	ldb	w, 0x31
	.byte 0x32, 0x00, 0x20, 0x31, 0x31, 0x00, 0x20, 0x31
	.byte 0x30, 0x00, 0x20, 0x20, 0x39, 0x00, 0x20, 0x20
	.byte 0x38, 0x00, 0x20, 0x20, 0x37, 0x00, 0x20, 0x20
	.byte 0x36, 0x00, 0x20, 0x20, 0x35, 0x00, 0x20, 0x20
	.byte 0x34, 0x00, 0x20, 0x20, 0x33, 0x00, 0x20, 0x20
	.byte 0x32, 0x00, 0x20, 0x20, 0x31, 0x00, 0x20, 0x20
	.byte 0x30, 0x00, 0x45, 0x52, 0x52, 0x00, 0x01, 0x00
	.byte 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x03, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00
	.byte 0x01, 0x00, 0x01, 0x00, 0x03, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00
	.byte 0x01, 0x00, 0x6a, 0x00, 0x1c, 0x01, 0x6a, 0x00
	.byte 0x1c, 0x01, 0x0c, 0x02, 0xf5, 0x01, 0xf5, 0x01
NoteDataB_Natural:
	.byte 0x42, 0x20, 0x00, 0xff
NoteDataB_Flat:
	.byte 0x42, 0x62, 0x00, 0xff
NoteDataA_Natural:
	.byte 0x41, 0x20, 0x00, 0xff
NoteDataA_Flat:
	.byte 0x41, 0x62, 0x00, 0xff
NoteDataG_Natural:
	.byte 0x47, 0x20, 0x00, 0xff
NoteDataF_Sharp:
	.byte 0x46, 0x23, 0x00, 0xff
NoteDataF_Natural:
	.byte 0x46, 0x20, 0x00, 0xff
NoteDataE_Natural:
	.byte 0x45, 0x20, 0x00, 0xff
NoteDataE_Flat:
	.byte 0x45, 0x62, 0x00, 0xff
NoteDataD_Natural:
	.byte 0x44, 0x20, 0x00, 0xff
NoteDataD_Flat:
	.byte 0x44, 0x62, 0x00, 0xff
NoteDataC_Natural:
	.byte 0x43, 0x20, 0x00, 0xff
StrEnable:	aligned_string "ENABLE "
StrDisable:	aligned_string "DISABLE"
StrMinor:	aligned_string "MINOR"
StrMajor:	.asciz "MAJOR"
StrSeventh:	aligned_string "7th   "
StrNormal:	aligned_string "NORMAL"
StrTimeSig_4_8:
	.byte 0x34, 0x2f, 0x38, 0x00
StrTimeSig_3_8:
	.byte 0x33, 0x2f, 0x38, 0x00
StrTimeSig_2_8:
	.byte 0x32, 0x2f, 0x38, 0x00
StrTimeSig_1_8:
	.byte 0x31, 0x2f, 0x38, 0x00
StrTimeSig_8_4:
	.byte 0x38, 0x2f, 0x34, 0x00
StrTimeSig_7_4:
	.byte 0x37, 0x2f, 0x34, 0x00
StrTimeSig_6_4:
	.byte 0x36, 0x2f, 0x34, 0x00
StrTimeSig_5_4:
	.byte 0x35, 0x2f, 0x34, 0x00
StrTimeSig_4_4:
	.byte 0x34, 0x2f, 0x34, 0x00
StrTimeSig_3_4:
	.byte 0x33, 0x2f, 0x34, 0x00
StrTimeSig_2_4:
	.byte 0x32, 0x2f, 0x34, 0x00
StrTimeSig_1_4:
	.byte 0x31, 0x2f, 0x34, 0x00
StrTimeSig_4_2:
	.byte 0x34, 0x2f, 0x32, 0x00
StrTimeSig_3_2:
	.byte 0x33, 0x2f, 0x32, 0x00
StrTimeSig_2_2:
	.byte 0x32, 0x2f, 0x32, 0x00
StrTimeSig_1_2:
	ldw	bc, 12847
	nop
	ldb	e, 100
	nop
	swi	7
	aligned_string "%s (%s)"
	.byte 0x00, 0x00, 0x1a, 0x00, 0xa4, 0x00, 0xa4, 0x00
	.byte 0x55, 0x00, 0x60, 0x00, 0x7e, 0x00, 0x82, 0x00
	.byte 0x00, 0x00, 0x38, 0x00, 0x00, 0x00, 0x38, 0x00
	.byte 0x72, 0x01, 0x72, 0x01, 0x72, 0x01
StrPanRight63:	aligned_string "Right 63"
StrPanRight62:	aligned_string "Right 62"
StrPanRight61:	aligned_string "Right 61"
StrPanRight60:	aligned_string "Right 60"
StrPanRight59:	aligned_string "Right 59"
StrPanRight58:	aligned_string "Right 58"
StrPanRight57:	aligned_string "Right 57"
StrPanRight56:	aligned_string "Right 56"
StrPanRight55:	aligned_string "Right 55"
StrPanRight54:	aligned_string "Right 54"
StrPanRight53:	aligned_string "Right 53"
StrPanRight52:	aligned_string "Right 52"
StrPanRight51:	aligned_string "Right 51"
StrPanRight50:	aligned_string "Right 50"
StrPanRight49:	aligned_string "Right 49"
StrPanRight48:	aligned_string "Right 48"
StrPanRight47:	aligned_string "Right 47"
StrPanRight46:	aligned_string "Right 46"
StrPanRight45:	aligned_string "Right 45"
StrPanRight44:	aligned_string "Right 44"
StrPanRight43:	aligned_string "Right 43"
StrPanRight42:	aligned_string "Right 42"
StrPanRight41:	aligned_string "Right 41"
StrPanRight40:	aligned_string "Right 40"
StrPanRight39:	aligned_string "Right 39"
StrPanRight38:	aligned_string "Right 38"
StrPanRight37:	aligned_string "Right 37"
StrPanRight36:	aligned_string "Right 36"
StrPanRight35:	aligned_string "Right 35"
StrPanRight34:	aligned_string "Right 34"
StrPanRight33:	aligned_string "Right 33"
StrPanRight32:	aligned_string "Right 32"
StrPanRight31:	aligned_string "Right 31"
StrPanRight30:	aligned_string "Right 30"
StrPanRight29:	aligned_string "Right 29"
StrPanRight28:	aligned_string "Right 28"
StrPanRight27:	aligned_string "Right 27"
StrPanRight26:	aligned_string "Right 26"
StrPanRight25:	aligned_string "Right 25"
StrPanRight24:	aligned_string "Right 24"
StrPanRight23:	aligned_string "Right 23"
StrPanRight22:	aligned_string "Right 22"
StrPanRight21:	aligned_string "Right 21"
StrPanRight20:	aligned_string "Right 20"
StrPanRight19:	aligned_string "Right 19"
StrPanRight18:	aligned_string "Right 18"
StrPanRight17:	aligned_string "Right 17"
StrPanRight16:	aligned_string "Right 16"
StrPanRight15:	aligned_string "Right 15"
StrPanRight14:	aligned_string "Right 14"
StrPanRight13:	aligned_string "Right 13"
StrPanRight12:	aligned_string "Right 12"
StrPanRight11:	aligned_string "Right 11"
StrPanRight10:	aligned_string "Right 10"
StrPanRight09:	aligned_string "Right  9"
StrPanRight08:	aligned_string "Right  8"
StrPanRight07:	aligned_string "Right  7"
StrPanRight06:	aligned_string "Right  6"
StrPanRight05:	aligned_string "Right  5"
StrPanRight04:	aligned_string "Right  4"
StrPanRight03:	aligned_string "Right  3"
StrPanRight02:	aligned_string "Right  2"
StrPanRight01:	aligned_string "Right  1"
StrPanCenter:	aligned_string " CENTER "
StrPanLeft01:	aligned_string " Left  1"
StrPanLeft02:	aligned_string " Left  2"
StrPanLeft03:	aligned_string " Left  3"
StrPanLeft04:	aligned_string " Left  4"
StrPanLeft05:	aligned_string " Left  5"
StrPanLeft06:	aligned_string " Left  6"
StrPanLeft07:	aligned_string " Left  7"
StrPanLeft08:	aligned_string " Left  8"
StrPanLeft09:	aligned_string " Left  9"
StrPanLeft10:	aligned_string " Left 10"
StrPanLeft11:	aligned_string " Left 11"
StrPanLeft12:	aligned_string " Left 12"
StrPanLeft13:	aligned_string " Left 13"
StrPanLeft14:	aligned_string " Left 14"
StrPanLeft15:	aligned_string " Left 15"
StrPanLeft16:	aligned_string " Left 16"
StrPanLeft17:	aligned_string " Left 17"
StrPanLeft18:	aligned_string " Left 18"
StrPanLeft19:	aligned_string " Left 19"
StrPanLeft20:	aligned_string " Left 20"
StrPanLeft21:	aligned_string " Left 21"
StrPanLeft22:	aligned_string " Left 22"
StrPanLeft23:	aligned_string " Left 23"
StrPanLeft24:	aligned_string " Left 24"
StrPanLeft25:	aligned_string " Left 25"
StrPanLeft26:	aligned_string " Left 26"
StrPanLeft27:	aligned_string " Left 27"
StrPanLeft28:	aligned_string " Left 28"
StrPanLeft29:	aligned_string " Left 29"
StrPanLeft30:	aligned_string " Left 30"
StrPanLeft31:	aligned_string " Left 31"
StrPanLeft32:	aligned_string " Left 32"
StrPanLeft33:	aligned_string " Left 33"
StrPanLeft34:	aligned_string " Left 34"
StrPanLeft35:	aligned_string " Left 35"
StrPanLeft36:	aligned_string " Left 36"
StrPanLeft37:	aligned_string " Left 37"
StrPanLeft38:	aligned_string " Left 38"
StrPanLeft39:	aligned_string " Left 39"
StrPanLeft40:	aligned_string " Left 40"
StrPanLeft41:	aligned_string " Left 41"
StrPanLeft42:	aligned_string " Left 42"
StrPanLeft43:	aligned_string " Left 43"
StrPanLeft44:	aligned_string " Left 44"
StrPanLeft45:	aligned_string " Left 45"
StrPanLeft46:	aligned_string " Left 46"
StrPanLeft47:	aligned_string " Left 47"
StrPanLeft48:	aligned_string " Left 48"
StrPanLeft49:	aligned_string " Left 49"
StrPanLeft40b:	aligned_string " Left 40"
StrPanLeft51:	aligned_string " Left 51"
StrPanLeft52:	aligned_string " Left 52"
StrPanLeft53:	aligned_string " Left 53"
StrPanLeft54:	aligned_string " Left 54"
StrPanLeft55:	aligned_string " Left 55"
StrPanLeft56:	aligned_string " Left 56"
StrPanLeft57:	aligned_string " Left 57"
StrPanLeft58:	aligned_string " Left 58"
StrPanLeft59:	aligned_string " Left 59"
StrPanLeft60:	aligned_string " Left 60"
StrPanLeft61:	aligned_string " Left 61"
StrPanLeft62:	aligned_string " Left 62"
StrPanLeft63:	aligned_string " Left 63"
StrPanLeft64:	aligned_string " Left 64"
	.byte 0x00, 0x00
	.byte 0x48, 0x00, 0x00, 0x00, 0x48, 0x00, 0xf3, 0x00
	.byte 0xf3, 0x00, 0xf3, 0x00, 0x7c, 0xd5, 0xe1, 0x00
PtrTbl_StyleSectShortNames:
	.long StrStyleSect_A_Vari2
	.long StrStyleSect_A_Vari3
	.long StrStyleSect_A_Vari4
	.long StrStyleSect_B_Vari1
	.long StrStyleSect_B_Vari2
	.long StrStyleSect_B_Vari3
	.long StrStyleSect_B_Vari4
	.long StrStyleSect_C_Vari1
	.long StrStyleSect_C_Vari2
	.long StrStyleSect_C_Vari3
	.long StrStyleSect_C_Vari4
	.long StrStyleSect_A_Int1
	.long StrStyleSect_A_Int2
	.long StrStyleSect_A_Fill1
	.long StrStyleSect_A_Fill2
	.long StrStyleSect_A_End1
	.long StrStyleSect_A_End2
	.long StrStyleSect_B_Int1
	.long StrStyleSect_B_Int2
	.long StrStyleSect_B_Fill1
	.long StrStyleSect_B_Fill2
	.long StrStyleSect_B_End1
	.long StrStyleSect_B_End2
	.long StrStyleSect_C_Int1
	.long StrStyleSect_C_Int2
	.long StrStyleSect_C_Fill1
	.long StrStyleSect_C_Fill2
	.long StrStyleSect_C_End1
	.long StrStyleSect_C_End2
StrStyleSect_C_End2:	aligned_string "C-END2 "
StrStyleSect_C_End1:	aligned_string "C-END1 "
StrStyleSect_C_Fill2:	aligned_string "C-FILL2"
StrStyleSect_C_Fill1:	aligned_string "C-FILL1"
StrStyleSect_C_Int2:	aligned_string "C-INT2 "
StrStyleSect_C_Int1:	aligned_string "C-INT1 "
StrStyleSect_B_End2:	aligned_string "B-END2 "
StrStyleSect_B_End1:	aligned_string "B-END1 "
StrStyleSect_B_Fill2:	aligned_string "B-FILL2"
StrStyleSect_B_Fill1:	aligned_string "B-FILL1"
StrStyleSect_B_Int2:	aligned_string "B-INT2 "
StrStyleSect_B_Int1:	aligned_string "B-INT1 "
StrStyleSect_A_End2:	aligned_string "A-END2 "
StrStyleSect_A_End1:	aligned_string "A-END1 "
StrStyleSect_A_Fill2:	aligned_string "A-FILL2"
StrStyleSect_A_Fill1:	aligned_string "A-FILL1"
StrStyleSect_A_Int2:	aligned_string "A-INT2 "
StrStyleSect_A_Int1:	aligned_string "A-INT1 "
StrStyleSect_C_Vari4:	aligned_string "C-vari4"
StrStyleSect_C_Vari3:	aligned_string "C-vari3"
StrStyleSect_C_Vari2:	aligned_string "C-vari2"
StrStyleSect_C_Vari1:	aligned_string "C-vari1"
StrStyleSect_B_Vari4:	aligned_string "B-vari4"
StrStyleSect_B_Vari3:	aligned_string "B-vari3"
StrStyleSect_B_Vari2:	aligned_string "B-vari2"
StrStyleSect_B_Vari1:	aligned_string "B-vari1"
StrStyleSect_A_Vari4:	aligned_string "A-vari4"
StrStyleSect_A_Vari3:	aligned_string "A-vari3"
StrStyleSect_A_Vari2:	aligned_string "A-vari2"
StrStyleSect_A_Vari1:	aligned_string "A-vari1"
	.byte 0x25, 0x33, 0x64, 0x00
	.byte 0x25, 0x33, 0x64, 0x00
	aligned_string "(SONG:%2d)"
PtrTbl_TransposeStrs:
	.long StrTranspose_Minus25
	.long StrTranspose_Minus24
	.long StrTranspose_Minus23
	.long StrTranspose_Minus22
	.long StrTranspose_Minus21
	.long StrTranspose_Minus20
	.long StrTranspose_Minus19
	.long StrTranspose_Minus18
	.long StrTranspose_Minus17
	.long StrTranspose_Minus16
	.long StrTranspose_Minus15
	.long StrTranspose_Minus14
	.long StrTranspose_Minus13
	.long StrTranspose_Minus12
	.long StrTranspose_Minus11
	.long StrTranspose_Minus10
	.long StrTranspose_Minus09
	.long StrTranspose_Minus08
	.long StrTranspose_Minus07
	.long StrTranspose_Minus06
	.long StrTranspose_Minus05
	.long StrTranspose_Minus04
	.long StrTranspose_Minus03
	.long StrTranspose_Minus02
	.long StrTranspose_Minus01
	.long StrTranspose_Zero
	.long StrTranspose_Plus01
	.long StrTranspose_Plus02
	.long StrTranspose_Plus03
	.long StrTranspose_Plus04
	.long StrTranspose_Plus05
	.long StrTranspose_Plus06
	.long StrTranspose_Plus07
	.long StrTranspose_Plus08
	.long StrTranspose_Plus09
	.long StrTranspose_Plus10
	.long StrTranspose_Plus11
	.long StrTranspose_Plus12
	.long StrTranspose_Plus13
	.long StrTranspose_Plus14
	.long StrTranspose_Plus15
	.long StrTranspose_Plus16
	.long StrTranspose_Plus17
	.long StrTranspose_Plus18
	.long StrTranspose_Plus19
	.long StrTranspose_Plus20
	.long StrTranspose_Plus21
	.long StrTranspose_Plus22
	.long StrTranspose_Plus23
	.long StrTranspose_Plus24
StrTranspose_Plus24:
	.byte 0x2b, 0x32, 0x34, 0x00
StrTranspose_Plus23:
	.byte 0x2b, 0x32, 0x33, 0x00
StrTranspose_Plus22:
	.byte 0x2b, 0x32, 0x32, 0x00
StrTranspose_Plus21:
	.byte 0x2b, 0x32, 0x31, 0x00
StrTranspose_Plus20:
	.byte 0x2b, 0x32, 0x30, 0x00
StrTranspose_Plus19:
	.byte 0x2b, 0x31, 0x39, 0x00
StrTranspose_Plus18:
	.byte 0x2b, 0x31, 0x38, 0x00
StrTranspose_Plus17:
	.byte 0x2b, 0x31, 0x37, 0x00
StrTranspose_Plus16:
	.byte 0x2b, 0x31, 0x36, 0x00
StrTranspose_Plus15:
	.byte 0x2b, 0x31, 0x35, 0x00
StrTranspose_Plus14:
	.byte 0x2b, 0x31, 0x34, 0x00
StrTranspose_Plus13:
	.byte 0x2b, 0x31, 0x33, 0x00
StrTranspose_Plus12:
	.byte 0x2b, 0x31, 0x32, 0x00
StrTranspose_Plus11:
	.byte 0x2b, 0x31, 0x31, 0x00
StrTranspose_Plus10:
	.byte 0x2b, 0x31, 0x30, 0x00
StrTranspose_Plus09:
	.byte 0x2b, 0x20, 0x39, 0x00
StrTranspose_Plus08:
	.byte 0x2b, 0x20, 0x38, 0x00
StrTranspose_Plus07:
	.byte 0x2b, 0x20, 0x37, 0x00
StrTranspose_Plus06:
	.byte 0x2b, 0x20, 0x36, 0x00
StrTranspose_Plus05:
	.byte 0x2b, 0x20, 0x35, 0x00
StrTranspose_Plus04:
	.byte 0x2b, 0x20, 0x34, 0x00
StrTranspose_Plus03:
	.byte 0x2b, 0x20, 0x33, 0x00
StrTranspose_Plus02:
	.byte 0x2b, 0x20, 0x32, 0x00
StrTranspose_Plus01:
	.byte 0x2b, 0x20, 0x31, 0x00
StrTranspose_Zero:
	.byte 0x20, 0x20, 0x30, 0x00
StrTranspose_Minus01:
	.byte 0x2d, 0x20, 0x31, 0x00
StrTranspose_Minus02:
	.byte 0x2d, 0x20, 0x32, 0x00
StrTranspose_Minus03:
	.byte 0x2d, 0x20, 0x33, 0x00
StrTranspose_Minus04:
	.byte 0x2d, 0x20, 0x34, 0x00
StrTranspose_Minus05:
	.byte 0x2d, 0x20, 0x35, 0x00
StrTranspose_Minus06:
	.byte 0x2d, 0x20, 0x36, 0x00
StrTranspose_Minus07:
	.byte 0x2d, 0x20, 0x37, 0x00
StrTranspose_Minus08:
	.byte 0x2d, 0x20, 0x38, 0x00
StrTranspose_Minus09:
	.byte 0x2d, 0x20, 0x39, 0x00
StrTranspose_Minus10:
	.byte 0x2d, 0x31, 0x30, 0x00
StrTranspose_Minus11:
	.byte 0x2d, 0x31, 0x31, 0x00
StrTranspose_Minus12:
	.byte 0x2d, 0x31, 0x32, 0x00
StrTranspose_Minus13:
	.byte 0x2d, 0x31, 0x33, 0x00
StrTranspose_Minus14:
	.byte 0x2d, 0x31, 0x34, 0x00
StrTranspose_Minus15:
	.byte 0x2d, 0x31, 0x35, 0x00
StrTranspose_Minus16:
	.byte 0x2d, 0x31, 0x36, 0x00
StrTranspose_Minus17:
	.byte 0x2d, 0x31, 0x37, 0x00
StrTranspose_Minus18:
	.byte 0x2d, 0x31, 0x38, 0x00
StrTranspose_Minus19:
	.byte 0x2d, 0x31, 0x39, 0x00
StrTranspose_Minus20:
	.byte 0x2d, 0x32, 0x30, 0x00
StrTranspose_Minus21:
	.byte 0x2d, 0x32, 0x31, 0x00
StrTranspose_Minus22:
	.byte 0x2d, 0x32, 0x32, 0x00
StrTranspose_Minus23:
	.byte 0x2d, 0x32, 0x33, 0x00
StrTranspose_Minus24:
	.byte 0x2d, 0x32, 0x34, 0x00
StrTranspose_Minus25:
	.byte 0x2d, 0x32, 0x35, 0x00
	.byte 0x76, 0x00, 0x26, 0x01, 0x76, 0x00, 0x26, 0x01
	.byte 0x3c, 0x02, 0x00, 0x02, 0x00, 0x02, 0x91, 0x39
	.byte 0x00, 0x00, 0x92, 0x39, 0x00, 0x00, 0x93, 0x39
	.byte 0x00, 0x00, 0x94, 0x39, 0x00, 0x00, 0x95, 0x39
	.byte 0x00, 0x00
StrBeat16:
	.byte 0x31, 0x36, 0x20, 0x00
StrBeat15:	.asciz "15 "
StrBeat14:
	.byte 0x31, 0x34, 0x20, 0x00
StrBeat13:	.asciz "13 "
StrBeat12:
	.byte 0x31, 0x32, 0x20, 0x00
StrBeat11:	.asciz "11 "
StrBeat10:
	.byte 0x31, 0x30, 0x20, 0x00
StrBeat09:	.asciz " 9 "
StrBeat08:
	.byte 0x20, 0x38, 0x20, 0x00
StrBeat07:	.asciz " 7 "
StrBeat06:
	.byte 0x20, 0x36, 0x20, 0x00
StrBeat05:	.asciz " 5 "
StrBeat04:
	.byte 0x20, 0x34, 0x20, 0x00
StrBeat03:	.asciz " 3 "
StrBeat02:
	.byte 0x20, 0x32, 0x20, 0x00
StrBeat01:	.asciz " 1 "
StrBeatOff:
	.byte 0x4f, 0x46, 0x46, 0x00, 0x00, 0x00
	.byte 0x38, 0x00, 0x00, 0x00, 0x38, 0x00, 0xce, 0x00
	.byte 0xce, 0x00, 0xce, 0x00, 0xa8, 0xd9, 0xe1, 0x00
PtrTbl_StylePatternLongNames:
	.long StrStylePatt_Vari2b
	.long StrStylePatt_Vari3b
	.long StrStylePatt_Vari4b
	.long StrStylePatt_Intro1b
	.long StrStylePatt_Intro2b
	.long StrStylePatt_Ending1b
	.long StrStylePatt_Ending2b
	.long StrStylePatt_V1FillIn1
	.long StrStylePatt_V1FillIn2
	.long StrStylePatt_V2FillIn1
	.long StrStylePatt_V2FillIn2
	.long StrStylePatt_V3FillIn1
	.long StrStylePatt_V3FillIn2
	.long StrStylePatt_V4FillIn1
	.long StrStylePatt_V4FillIn2
	.long StrStylePatt_Vari1
	.long StrStylePatt_Vari2
	.long StrStylePatt_Vari3
	.long StrStylePatt_Vari4
	.long StrStylePatt_Intro1
	.long StrStylePatt_Intro2
	.long StrStylePatt_FillIn1
	.long StrStylePatt_FillIn2
	.long StrStylePatt_Ending1
	.long StrStylePatt_Ending2
	.long StrStylePatt_All
StrStylePatt_All:	aligned_string "     ALL      "
StrStylePatt_Ending2:	aligned_string "   ENDING2    "
StrStylePatt_Ending1:	aligned_string "   ENDING1    "
StrStylePatt_FillIn2:	aligned_string "   FILL IN 2  "
StrStylePatt_FillIn1:	aligned_string "   FILL IN 1  "
StrStylePatt_Intro2:	aligned_string "    INTRO2    "
StrStylePatt_Intro1:	aligned_string "    INTRO1    "
StrStylePatt_Vari4:	aligned_string "    Vari4     "
StrStylePatt_Vari3:	aligned_string "    Vari3     "
StrStylePatt_Vari2:	aligned_string "    Vari2     "
StrStylePatt_Vari1:	aligned_string "    Vari1     "
StrStylePatt_V4FillIn2:	aligned_string "Vari4 FILL IN2"
StrStylePatt_V4FillIn1:	aligned_string "Vari4 FILL IN1"
StrStylePatt_V3FillIn2:	aligned_string "Vari3 FILL IN2"
StrStylePatt_V3FillIn1:	aligned_string "Vari3 FILL IN1"
StrStylePatt_V2FillIn2:	aligned_string "Vari2 FILL IN2"
StrStylePatt_V2FillIn1:	aligned_string "Vari2 FILL IN1"
StrStylePatt_V1FillIn2:	aligned_string "Vari1 FILL IN2"
StrStylePatt_V1FillIn1:	aligned_string "Vari1 FILL IN1"
StrStylePatt_Ending2b:	aligned_string "   ENDING2    "
StrStylePatt_Ending1b:	aligned_string "   ENDING1    "
StrStylePatt_Intro2b:	aligned_string "    INTRO2    "
StrStylePatt_Intro1b:	aligned_string "    INTRO1    "
StrStylePatt_Vari4b:	aligned_string "    Vari4     "
StrStylePatt_Vari3b:	aligned_string "    Vari3     "
StrStylePatt_Vari2b:	aligned_string "    Vari2     "
StrStylePatt_Vari1b:	aligned_string "    Vari1     "
PtrTbl_RhySlotLongNames:
	.long StrRhySlot_MemoryA
	.long StrRhySlot_MemoryB
	.long StrRhySlot_MemoryC
	.long StrRhySlot_AkiPlaceholderX
	.long StrRhySlot_AkiPlaceholder1
	.long StrRhySlot_AkiPlaceholder2
	.long StrRhySlot_AkiPlaceholder3
	.long StrRhySlot_AkiPlaceholder4
	.long StrRhySlot_AkiPlaceholder5
	.long StrRhySlot_AkiPlaceholder6
	.long StrRhySlot_Custom01
	.long StrRhySlot_Custom02
	.long StrRhySlot_Custom03
	.long StrRhySlot_Custom04
	.long StrRhySlot_Custom05
	.long StrRhySlot_Custom06
	.long StrRhySlot_Custom07
	.long StrRhySlot_Custom08
	.long StrRhySlot_Custom09
	.long StrRhySlot_Custom10
	.long StrRhySlot_Custom11
	.long StrRhySlot_Custom12
	.long StrRhySlot_Custom13
	.long StrRhySlot_Custom14
	.long StrRhySlot_Custom15
	.long StrRhySlot_Custom16
	.long StrRhySlot_Custom17
	.long StrRhySlot_Custom18
	.long StrRhySlot_Custom19
	.long StrRhySlot_Custom20
StrRhySlot_Custom20:		aligned_string "CUSTOM:20"
StrRhySlot_Custom19:		aligned_string "CUSTOM:19"
StrRhySlot_Custom18:		aligned_string "CUSTOM:18"
StrRhySlot_Custom17:		aligned_string "CUSTOM:17"
StrRhySlot_Custom16:		aligned_string "CUSTOM:16"
StrRhySlot_Custom15:		aligned_string "CUSTOM:15"
StrRhySlot_Custom14:		aligned_string "CUSTOM:14"
StrRhySlot_Custom13:		aligned_string "CUSTOM:13"
StrRhySlot_Custom12:		aligned_string "CUSTOM:12"
StrRhySlot_Custom11:		aligned_string "CUSTOM:11"
StrRhySlot_Custom10:		aligned_string "CUSTOM:10"
StrRhySlot_Custom09:		aligned_string "CUSTOM: 9"
StrRhySlot_Custom08:		aligned_string "CUSTOM: 8"
StrRhySlot_Custom07:		aligned_string "CUSTOM: 7"
StrRhySlot_Custom06:		aligned_string "CUSTOM: 6"
StrRhySlot_Custom05:		aligned_string "CUSTOM: 5"
StrRhySlot_Custom04:		aligned_string "CUSTOM: 4"
StrRhySlot_Custom03:		aligned_string "CUSTOM: 3"
StrRhySlot_Custom02:		aligned_string "CUSTOM: 2"
StrRhySlot_Custom01:		aligned_string "CUSTOM: 1"
StrRhySlot_AkiPlaceholder6:	aligned_string " aki     "
StrRhySlot_AkiPlaceholder5:	aligned_string " aki     "
StrRhySlot_AkiPlaceholder4:	aligned_string " aki     "
StrRhySlot_AkiPlaceholder3:	aligned_string " aki     "
StrRhySlot_AkiPlaceholder2:	aligned_string " aki     "
StrRhySlot_AkiPlaceholder1:	aligned_string " aki     "
StrRhySlot_AkiPlaceholderX:	aligned_string " aki     "
StrRhySlot_MemoryC:		aligned_string "MEMORY C "
StrRhySlot_MemoryB:		aligned_string "MEMORY B "
StrRhySlot_MemoryA:		aligned_string "MEMORY A "
	aligned_string "MEMORY"
	aligned_string "CUSTOM"
	popw iy
	ld	xiy, 1498566477
	nop
	swi	7
	ld	xhl, 1330926421
	popw iy
	nop
	swi	7
	nop
	or	bc, iy
	nop
PtrTbl_StyleSectShortNames2:
	.long StrStyleSect2_A_Vari2
	.long StrStyleSect2_A_Vari3
	.long StrStyleSect2_A_Vari4
	.long StrStyleSect2_B_Vari1
	.long StrStyleSect2_B_Vari2
	.long StrStyleSect2_B_Vari3
	.long StrStyleSect2_B_Vari4
	.long StrStyleSect2_C_Vari1
	.long StrStyleSect2_C_Vari2
	.long StrStyleSect2_C_Vari3
	.long StrStyleSect2_C_Vari4
	.long StrStyleSect2_A_Int1
	.long StrStyleSect2_A_Int2
	.long StrStyleSect2_A_Fill1
	.long StrStyleSect2_A_Fill2
	.long StrStyleSect2_A_End1
	.long StrStyleSect2_A_End2
	.long StrStyleSect2_B_Int1
	.long StrStyleSect2_B_Int2
	.long StrStyleSect2_B_Fill1
	.long StrStyleSect2_B_Fill2
	.long StrStyleSect2_B_End1
	.long StrStyleSect2_B_End2
	.long StrStyleSect2_C_Int1
	.long StrStyleSect2_C_Int2
	.long StrStyleSect2_C_Fill1
	.long StrStyleSect2_C_Fill2
	.long StrStyleSect2_C_End1
	.long StrStyleSect2_C_End2
	.long StrStyleSect2_A_All
	.long StrStyleSect2_B_All
	.long StrStyleSect2_C_All
StrStyleSect2_C_All:	aligned_string "C-ALL  "
StrStyleSect2_B_All:	aligned_string "B-ALL  "
StrStyleSect2_A_All:	aligned_string "A-ALL  "
StrStyleSect2_C_End2:	aligned_string "C-END2 "
StrStyleSect2_C_End1:	aligned_string "C-END1 "
StrStyleSect2_C_Fill2:	aligned_string "C-FILL2"
StrStyleSect2_C_Fill1:	aligned_string "C-FILL1"
StrStyleSect2_C_Int2:	aligned_string "C-INT2 "
StrStyleSect2_C_Int1:	aligned_string "C-INT1 "
StrStyleSect2_B_End2:	aligned_string "B-END2 "
StrStyleSect2_B_End1:	aligned_string "B-END1 "
StrStyleSect2_B_Fill2:	aligned_string "B-FILL2"
StrStyleSect2_B_Fill1:	aligned_string "B-FILL1"
StrStyleSect2_B_Int2:	aligned_string "B-INT2 "
StrStyleSect2_B_Int1:	aligned_string "B-INT1 "
StrStyleSect2_A_End2:	aligned_string "A-END2 "
StrStyleSect2_A_End1:	aligned_string "A-END1 "
StrStyleSect2_A_Fill2:	aligned_string "A-FILL2"
StrStyleSect2_A_Fill1:	aligned_string "A-FILL1"
StrStyleSect2_A_Int2:	aligned_string "A-INT2 "
StrStyleSect2_A_Int1:	aligned_string "A-INT1 "
StrStyleSect2_C_Vari4:	aligned_string "C-vari4"
StrStyleSect2_C_Vari3:	aligned_string "C-vari3"
StrStyleSect2_C_Vari2:	aligned_string "C-vari2"
StrStyleSect2_C_Vari1:	aligned_string "C-vari1"
StrStyleSect2_B_Vari4:	aligned_string "B-vari4"
StrStyleSect2_B_Vari3:	aligned_string "B-vari3"
StrStyleSect2_B_Vari2:	aligned_string "B-vari2"
StrStyleSect2_B_Vari1:	aligned_string "B-vari1"
StrStyleSect2_A_Vari4:	aligned_string "A-vari4"
StrStyleSect2_A_Vari3:	aligned_string "A-vari3"
StrStyleSect2_A_Vari2:	aligned_string "A-vari2"
StrStyleSect2_A_Vari1:	aligned_string "A-vari1"
	.long StrTrackBlank
	.long StrTrackRec
	.long StrTrackMute
StrTrackMute:	aligned_string "MUTE"
StrTrackRec:	aligned_string "REC "
StrTrackBlank:	aligned_string "    "
PtrTbl_NotePositionStrs:
	.long StrNotePos_Off
	.long StrNotePos_AdFlatB8
	.long StrNotePos_AdNatural
	.long StrNotePos_AcFlatB8
	.long StrNotePos_AcNatural
	.long StrNotePos_FlatAltB8
	.long StrNotePos_FlatAlt
	.long StrNotePos_Natural
StrNotePos_Natural:
	ldb	w, 0x7e
	.byte 0x61, 0x61, 0x20, 0x00
	aligned_string " ~ab "
	aligned_string " ~ab~b8"
	aligned_string " ~ac "
StrNotePos_AcFlatB8:	aligned_string " ~ac~b8"
StrNotePos_AdNatural:	aligned_string " ~ad "
StrNotePos_AdFlatB8:	aligned_string " ~ad~b8"
StrNotePos_Off:
	.byte 0x4f, 0x46
	.byte 0x46, 0x00, 0x25, 0x64, 0x00, 0xff, 0x25, 0x32
	.byte 0x64, 0x00, 0x25, 0x33, 0x64, 0x00
PtrTbl_StyleVarGroupCodes:
	.long StyleVarGrp_AEnd2b
	.long StyleVarGrp_AEnd1
	.long StyleVarGrp_AVari1
	.long StyleVarGrp_AVari2
	.long StyleVarGrp_BEnd1c
	.long StyleVarGrp_BVari1
	.long StyleVarGrp_BVari2
	.long StyleVarGrp_BVari3
	.long StyleVarGrp_BEnd1b
	.long StyleVarGrp_CVari1
	.long StyleVarGrp_CVari2
	.long StyleVarGrp_CVari3
	.long StyleVarGrp_AVari3
	.long StyleVarGrp_AFill1
	.long StyleVarGrp_AFill2
	.long StyleVarGrp_AInt1
	.long StyleVarGrp_AInt2
	.long StyleVarGrp_AVari4
	.long StyleVarGrp_BVari4
	.long StyleVarGrp_BFill1
	.long StyleVarGrp_BFill2
	.long StyleVarGrp_BInt1
	.long StyleVarGrp_BInt2
	.long StyleVarGrp_BEnd1
	.long StyleVarGrp_CVari4
	.long StyleVarGrp_CFill1
	.long StyleVarGrp_CFill2
	.long StyleVarGrp_CInt1
	.long StyleVarGrp_CInt2
	.long StyleVarGrp_CEnd1
	.long StyleVarGrp_AEnd2
	.long StyleVarGrp_BEnd2
	.long StyleVarGrp_CEnd2
StyleVarGrp_CEnd2:
	.byte 0x43, 0x00
StyleVarGrp_BEnd2:
	.byte 0x42, 0x00
StyleVarGrp_AEnd2:
	.byte 0x41, 0x00
StyleVarGrp_CEnd1:
	.byte 0x43, 0x00
StyleVarGrp_CInt2:
	.byte 0x43, 0x00
StyleVarGrp_CInt1:
	.byte 0x43, 0x00
StyleVarGrp_CFill2:
	.byte 0x43, 0x00
StyleVarGrp_CFill1:
	.byte 0x43, 0x00
StyleVarGrp_CVari4:
	.byte 0x43, 0x00
StyleVarGrp_BEnd1:
	.byte 0x42, 0x00
StyleVarGrp_BInt2:
	.byte 0x42, 0x00
StyleVarGrp_BInt1:
	.byte 0x42, 0x00
StyleVarGrp_BFill2:
	.byte 0x42, 0x00
StyleVarGrp_BFill1:
	.byte 0x42, 0x00
StyleVarGrp_BVari4:
	.byte 0x42, 0x00
StyleVarGrp_AVari4:
	.byte 0x41, 0x00
StyleVarGrp_AInt2:
	.byte 0x41, 0x00
StyleVarGrp_AInt1:
	.byte 0x41, 0x00
StyleVarGrp_AFill2:
	.byte 0x41, 0x00
StyleVarGrp_AFill1:
	.byte 0x41, 0x00
StyleVarGrp_AVari3:
	.byte 0x41, 0x00
StyleVarGrp_CVari3:
	.byte 0x43, 0x00
StyleVarGrp_CVari2:
	.byte 0x43, 0x00
StyleVarGrp_CVari1:
	.byte 0x43, 0x00
StyleVarGrp_BEnd1b:
	.byte 0x43, 0x00
StyleVarGrp_BVari3:
	.byte 0x42, 0x00
StyleVarGrp_BVari2:
	.byte 0x42, 0x00
StyleVarGrp_BVari1:
	.byte 0x42, 0x00
StyleVarGrp_BEnd1c:
	.byte 0x42, 0x00
StyleVarGrp_AVari2:
	.byte 0x41, 0x00
StyleVarGrp_AVari1:
	.byte 0x41, 0x00
StyleVarGrp_AEnd1:
	.byte 0x41, 0x00
StyleVarGrp_AEnd2b:
	.byte 0x41, 0x00, 0x6a, 0x00, 0x0e, 0x01
	.byte 0x6a, 0x00, 0x0e, 0x01, 0xf0, 0x01, 0xd9, 0x01
	.byte 0xd9, 0x01
StrGenre_Waltz:		aligned_string "     Waltz      "
StrGenre_RockBallad:	aligned_string "  Rock Ballad   "
StrGenre_Country:	aligned_string "    Country     "
StrGenre_Latin:		aligned_string "     Latin      "
StrGenre_Swing:		aligned_string "     Swing      "
StrGenre_MarchPolka:	aligned_string "  March/Polka   "
StrGenre_JazzFusion:	aligned_string "  Jazz Fusion   "
StrGenre_DancePop:	aligned_string "   Dance Pop    "
StrGenre_16Beat:	aligned_string "    16 Beat     "
StrGenre_8Beat:		aligned_string "     8 Beat     "
	.byte 0x4f, 0x46
	.byte 0x46, 0x00, 0x25, 0x33, 0x64, 0x00, 0x00, 0x00
	.byte 0x48, 0x00, 0x00, 0x00, 0x48, 0x00, 0x18, 0x01
	.byte 0x18, 0x01, 0x18, 0x01, 0x52, 0xdf, 0xe1, 0x00
	.long StrBankShort_User2
	.long StrBankShort_Compile1
	.long StrBankShort_Compile2
StrBankShort_Compile2:	aligned_string "COMPILE2"
StrBankShort_Compile1:	aligned_string "COMPILE1"
StrBankShort_User2:	aligned_string "User2   "
StrBankShort_User1:	aligned_string "User1   "
	.byte 0x1c, 0x00, 0x1c, 0x00
	.byte 0x69, 0x00, 0x69, 0x00, 0x69, 0x00, 0x20, 0x00
	.byte 0x69, 0x00, 0x24, 0x00, 0x1c, 0x00, 0x00, 0x00
PtrTbl_MspCompileBankLabels:
	.long StrMspUserBank1Label
	.long StrMspUserBank2Label
	.long StrMspCmpBank1Label
	.long StrMspCmpBank2Label
StrMspCmpBank2Label:	aligned_string "MSP COMPILE Bank2:"
StrMspCmpBank1Label:	aligned_string "MSP COMPILE Bank1:"
StrMspUserBank2Label:	aligned_string "MSP User Bank 2:  "
StrMspUserBank1Label:	aligned_string "MSP User Bank 1:  "
PtrTbl_MusicStyleBankNames:
	.long StrMsBankLong_Effect1
	.long StrMsBankLong_Effect2
	.long StrMsBankLong_Comical
	.long StrMsBankLong_Movie
	.long StrMsBankLong_Entertainer
	.long StrMsBankLong_Arpeggio
	.long StrMsBankLong_Rock1
	.long StrMsBankLong_Rock2
	.long StrMsBankLong_Dance
	.long StrMsBankLong_Funk
	.long StrMsBankLong_Jazz
	.long StrMsBankLong_Latin
	.long StrMsBankLong_HitCrescendo
	.long StrMsBankLong_UserBank1
	.long StrMsBankLong_UserBank2
	.long StrMsBankLong_CompileBank1
	.long StrMsBankLong_CompileBank2
	.long StrMsBankLong_CtrlPreset1
	.long StrMsBankLong_CtrlPreset2
StrMsBankLong_CtrlPreset2:	aligned_string " Control Preset2"
StrMsBankLong_CtrlPreset1:	aligned_string " Control Preset1"
StrMsBankLong_CompileBank2:	aligned_string " Compile bank 2 "
StrMsBankLong_CompileBank1:	aligned_string " Compile bank 1 "
StrMsBankLong_UserBank2:	aligned_string "  User Bank 2   "
StrMsBankLong_UserBank1:	aligned_string "  User Bank 1   "
StrMsBankLong_HitCrescendo:	aligned_string "Hit & Crescendo "
StrMsBankLong_Latin:		aligned_string "     Latin      "
StrMsBankLong_Jazz:		aligned_string "      Jazz      "
StrMsBankLong_Funk:		aligned_string "      Funk      "
StrMsBankLong_Dance:		aligned_string "     Dance      "
StrMsBankLong_Rock2:		aligned_string "     Rock 2     "
StrMsBankLong_Rock1:		aligned_string "     Rock 1     "
StrMsBankLong_Arpeggio:		aligned_string "    Arpeggio    "
StrMsBankLong_Entertainer:	aligned_string "  Entertainer   "
StrMsBankLong_Movie:		aligned_string "     Movie      "
StrMsBankLong_Comical:		aligned_string "    Comical     "
StrMsBankLong_Effect2:		aligned_string "    Effect 2    "
StrMsBankLong_Effect1:		aligned_string "    Effect 1    "
PtrTbl_MusicStyleBankNames2:
	.long StrMsBankLong2_Effect1
	.long StrMsBankLong2_Effect2
	.long StrMsBankLong2_Comical
	.long StrMsBankLong2_Movie
	.long StrMsBankLong2_Entertainer
	.long StrMsBankLong2_Arpeggio
	.long StrMsBankLong2_Rock1
	.long StrMsBankLong2_Rock2
	.long StrMsBankLong2_Dance
	.long StrMsBankLong2_Funk
	.long StrMsBankLong2_Jazz
	.long StrMsBankLong2_Latin
	.long StrMsBankLong2_HitCrescendo
	.long StrMsBankLong2_User1
	.long StrMsBankLong2_User2
StrMsBankLong2_User2:		aligned_string "User 2          "
StrMsBankLong2_User1:		aligned_string "User 1          "
StrMsBankLong2_HitCrescendo:	aligned_string "Hit & Crescendo "
StrMsBankLong2_Latin:		aligned_string "     Latin      "
StrMsBankLong2_Jazz:		aligned_string "      Jazz      "
StrMsBankLong2_Funk:		aligned_string "      Funk      "
StrMsBankLong2_Dance:		aligned_string "     Dance      "
StrMsBankLong2_Rock2:		aligned_string "     Rock 2     "
StrMsBankLong2_Rock1:		aligned_string "     Rock 1     "
StrMsBankLong2_Arpeggio:	aligned_string "    Arpeggio    "
StrMsBankLong2_Entertainer:	aligned_string "  Entertainer   "
StrMsBankLong2_Movie:		aligned_string "     Movie      "
StrMsBankLong2_Comical:		aligned_string "    Comical     "
StrMsBankLong2_Effect2:		aligned_string "    Effect 2    "
StrMsBankLong2_Effect1:		aligned_string "    Effect 1    "
	.byte 0x50, 0x41, 0x44, 0x25
	.byte 0x64, 0x00, 0x00, 0x00, 0x48, 0x00, 0x00, 0x00
	.byte 0x48, 0x00, 0x41, 0x01, 0x41, 0x01, 0x41, 0x01
	.long StrCompileBank1
	.long StrCompileBank2
StrCompileBank2:	aligned_string "COMPILE BANK:2"
StrCompileBank1:	aligned_string "COMPILE BANK:1"
	aligned_string "MEASURE = %d"
	aligned_string "MEMORY = %2d"
	ldb	e, 100
	nop
	swi	7
	.long StrInstantStart
	.long StrSyncToRhythm
StrSyncToRhythm:	aligned_string "SYNC TO RHYTHM   "
StrInstantStart:	aligned_string "INSTANT START    "
	.byte 0x23, 0x00, 0x23, 0x00
	.byte 0x4c, 0x00, 0x4c, 0x00, 0x4c, 0x00, 0x32, 0x00
	.byte 0x4c, 0x00, 0x36, 0x00, 0x32, 0x00, 0x00, 0x00
	.byte 0x01, 0x02, 0x04, 0x08, 0x10, 0xff, 0x6e, 0x00
	.byte 0x4c, 0x01, 0x6e, 0x00, 0x4c, 0x01, 0x93, 0x03
	.byte 0x56, 0x02, 0x6e, 0x03, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00
	.long Presentation_RootEntry
	.zero 4

SLOT_NAME_PTRS:	; Pointer table for rhythm slot names
	.long SLOT_NAME_MEMORY_A
	.long SLOT_NAME_MEMORY_B
	.long SLOT_NAME_MEMORY_C
	.long SLOT_NAME_CUSTOM_01
	.long SLOT_NAME_CUSTOM_02
	.long SLOT_NAME_CUSTOM_03
	.long SLOT_NAME_CUSTOM_04
	.long SLOT_NAME_CUSTOM_05
	.long SLOT_NAME_CUSTOM_06
	.long SLOT_NAME_CUSTOM_07
	.long SLOT_NAME_CUSTOM_08
	.long SLOT_NAME_CUSTOM_09
	.long SLOT_NAME_CUSTOM_10
	.long SLOT_NAME_CUSTOM_11
	.long SLOT_NAME_CUSTOM_12
	.long SLOT_NAME_CUSTOM_13
	.long SLOT_NAME_CUSTOM_14
	.long SLOT_NAME_CUSTOM_15
	.long SLOT_NAME_CUSTOM_16
	.long SLOT_NAME_CUSTOM_17
	.long SLOT_NAME_CUSTOM_18
	.long SLOT_NAME_CUSTOM_19
	.long SLOT_NAME_CUSTOM_20

SLOT_NAME_CUSTOM_20:	aligned_string "CUSTOM 20"
SLOT_NAME_CUSTOM_19:	aligned_string "CUSTOM 19"
SLOT_NAME_CUSTOM_18:	aligned_string "CUSTOM 18"
SLOT_NAME_CUSTOM_17:	aligned_string "CUSTOM 17"
SLOT_NAME_CUSTOM_16:	aligned_string "CUSTOM 16"
SLOT_NAME_CUSTOM_15:	aligned_string "CUSTOM 15"
SLOT_NAME_CUSTOM_14:	aligned_string "CUSTOM 14"
SLOT_NAME_CUSTOM_13:	aligned_string "CUSTOM 13"
SLOT_NAME_CUSTOM_12:	aligned_string "CUSTOM 12"
SLOT_NAME_CUSTOM_11:	aligned_string "CUSTOM 11"
SLOT_NAME_CUSTOM_10:	aligned_string "CUSTOM 10"
SLOT_NAME_CUSTOM_09:	aligned_string "CUSTOM 9 "
SLOT_NAME_CUSTOM_08:	aligned_string "CUSTOM 8 "
SLOT_NAME_CUSTOM_07:	aligned_string "CUSTOM 7 "
SLOT_NAME_CUSTOM_06:	aligned_string "CUSTOM 6 "
SLOT_NAME_CUSTOM_05:	aligned_string "CUSTOM 5 "
SLOT_NAME_CUSTOM_04:	aligned_string "CUSTOM 4 "
SLOT_NAME_CUSTOM_03:	aligned_string "CUSTOM 3 "
SLOT_NAME_CUSTOM_02:	aligned_string "CUSTOM 2 "
SLOT_NAME_CUSTOM_01:	aligned_string "CUSTOM 1 "
SLOT_NAME_MEMORY_C:	aligned_string "MEMORY C "
SLOT_NAME_MEMORY_B:	aligned_string "MEMORY B "
SLOT_NAME_MEMORY_A:	aligned_string "MEMORY A "

MsgBox_AttentionHeader:
	; Control codes/header
	.byte 0x1c, 0x00, 0x1c, 0x00, 0x2d, 0x00, 0x2d, 0x00, 0x2d, 0x00, 0x20, 0x00
	.byte 0x2d, 0x00, 0x27, 0x00, 0x1c, 0x00, 0x00, 0x00
	; Localization: Attention (6 languages)
MSG_ATTENTION_EN:	aligned_string "ATTENTION!"	; English (12 bytes)
MSG_ATTENTION_DE:	.asciz "ACHTUNG !"	; German (10 bytes)
MSG_ATTENTION_FR:	aligned_string "ATTENTION!"	; French (12 bytes)
MSG_ATTENTION_ES:
	.byte 0xa1
	.ascii "ATENCI"
	.byte 0xd3, 0x4e, 0x21, 0x00, 0xff	; Spanish (12 bytes)
MSG_ATTENTION_EN2:	aligned_string "ATTENTION!"	; Duplicate (12 bytes)
MSG_ATTENTION_ID:	.asciz "Perhatian !"	; Indonesian (12 bytes)
	; Pointer table at 0xE1E516
	.long MSG_ATTENTION_EN
	.long MSG_ATTENTION_DE
	.long MSG_ATTENTION_FR
	.long MSG_ATTENTION_ES
	.long MSG_ATTENTION_EN2
	.long MSG_ATTENTION_ID


	; Localization: AreYouSure (6 languages)
MSG_ARE_YOU_SURE_EN:	.asciz "Are You Sure?"	; English (14 bytes)
MSG_ARE_YOU_SURE_DE:	.asciz "Sind Sie sicher ?"	; German (18 bytes)
MSG_ARE_YOU_SURE_FR:
	.ascii "Etes vous s"
	.byte 0xfb, 0x72, 0x3f, 0x00, 0xff	; French (16 bytes)
MSG_ARE_YOU_SURE_ES:
	.byte 0xbf, 0x45, 0x73, 0x74, 0xe1
	.asciz " seguro?"	; Spanish (14 bytes)
MSG_ARE_YOU_SURE_EN2:	.asciz "Are You Sure?"	; Duplicate (14 bytes)
MSG_ARE_YOU_SURE_ID:	.asciz "Apakah yakin akan dihapus ?"	; Indonesian (28 bytes)
	; Pointer table at 0xE1E596
	.long MSG_ARE_YOU_SURE_EN
	.long MSG_ARE_YOU_SURE_DE
	.long MSG_ARE_YOU_SURE_FR
	.long MSG_ARE_YOU_SURE_ES
	.long MSG_ARE_YOU_SURE_EN2
	.long MSG_ARE_YOU_SURE_ID


	; Localization: CustomSoundWillBeCopied (6 languages)
MSG_CUSTOM_SOUND_COPY_EN:
	.asciz "The Custom sound memories included with this pattern will be copied into the Sound Group memories. Some of the Sound Group memories will be replaced by them. OK?"	; English (162 bytes)
MSG_CUSTOM_SOUND_COPY_DE:
	aligned_string "Die Custom Sounds, die in diesem Pattern enthalten sind, werden in den Sound Memory Speicher kopiert. Dadurch werden einige Sounds überschrieben. OK ?"	; German (152 bytes)
MSG_CUSTOM_SOUND_COPY_FR:
	.asciz "Les mémoires de sonorités éditées incluses dans ce Pattern seront copiées dans les mémoires de groupes de sonorités. Certaines des mémoires de groupe de sonorités seront remplacées. OK?"	; French (186 bytes)
MSG_CUSTOM_SOUND_COPY_ES:
	.asciz "Las memorias de sonido personalizado de este esquema musical serán copiadas a las memorias de los grupos de sonido.Algunas memorias de los grupos de sonido serán reemplazadas. ¿Está de acuerdo?"	; Spanish (194 bytes)
MSG_CUSTOM_SOUND_COPY_EN2:	.asciz "The Custom sound memories included with this pattern will be copied into the Sound Group memories. Some of the Sound Group memories will be replaced by them. OK?"	; Duplicate (162 bytes)
MSG_CUSTOM_SOUND_COPY_ID:	.asciz "Custom Sound Memory termasuk dengan Pattern yang akan digandakan kedalam SOUND GROUP MEMORIES. Beberapa Sound Group Memory dikembalikan. OK ?"	; Indonesian (142 bytes)
	; Pointer table at 0xE1E994
	.long MSG_CUSTOM_SOUND_COPY_EN
	.long MSG_CUSTOM_SOUND_COPY_DE
	.long MSG_CUSTOM_SOUND_COPY_FR
	.long MSG_CUSTOM_SOUND_COPY_ES
	.long MSG_CUSTOM_SOUND_COPY_EN2
	.long MSG_CUSTOM_SOUND_COPY_ID


	; Localization: SoundGroupAffected (6 languages)
MSG_SOUND_GROUP_AFFECTED_EN:	aligned_string "Sound Group memories affected:"	; English (32 bytes)
MSG_SOUND_GROUP_AFFECTED_DE:	aligned_string "Betroffene Sounds:"	; German (20 bytes)
MSG_SOUND_GROUP_AFFECTED_FR:
	aligned_string "Les mémoires de groupe de sonorités repérées :"	; French (48 bytes)
MSG_SOUND_GROUP_AFFECTED_ES:	.asciz "Las memorias de los grupos de sonido afectadas son:"	; Spanish (52 bytes)
MSG_SOUND_GROUP_AFFECTED_EN2:	aligned_string "Sound Group memories affected:"	; Duplicate (32 bytes)
MSG_SOUND_GROUP_AFFECTED_ID:	aligned_string "Sound Group memory sudah bekerja :"	; Indonesian (36 bytes)
	; Pointer table at 0xE1EA88
	.long MSG_SOUND_GROUP_AFFECTED_EN
	.long MSG_SOUND_GROUP_AFFECTED_DE
	.long MSG_SOUND_GROUP_AFFECTED_FR
	.long MSG_SOUND_GROUP_AFFECTED_ES
	.long MSG_SOUND_GROUP_AFFECTED_EN2
	.long MSG_SOUND_GROUP_AFFECTED_ID


	; Localization: CustomSoundMemoryFull (6 languages)
MSG_CUSTOM_SOUND_FULL_EN:
	.asciz "The Custom sound memory is full.Some sounds which are used by current Custom Rhythms will be deleted. OK?"	; English (106 bytes)
MSG_CUSTOM_SOUND_FULL_DE:
	.asciz "Der Custom Sound Speicher ist voll.inige Klänge, die von Custom Rhythmen benötigt werden, werden gelöscht. OK ?"	; German (112 bytes)
MSG_CUSTOM_SOUND_FULL_FR:
	.asciz "La mémoire de sonorités éditées est saturée.Certaines sonorités utilisées par Custom Rhythms seront effacées. OK?"	; French (114 bytes)
MSG_CUSTOM_SOUND_FULL_ES:
	.asciz "La memoria de sonido personalizado está llena.Algunos sonidos utilizados por los ritmos personalizados actuales serán borrados. ¿Está de acuerdo?"	; Spanish (146 bytes)
MSG_CUSTOM_SOUND_FULL_EN2:	.asciz "The Custom sound memory is full.Some sounds which are used by current Custom Rhythms will be deleted. OK?"	; Duplicate (106 bytes)
MSG_CUSTOM_SOUND_FULL_ID:	.asciz "Custom Sound memory sudah penuh.Beberapa suara (Sounds) yang digunakan dengan Custom Rhythms sekarang akan dihapus. Benar ?"	; Indonesian (124 bytes)
	; Pointer table at 0xE1ED64
	.long MSG_CUSTOM_SOUND_FULL_EN
	.long MSG_CUSTOM_SOUND_FULL_DE
	.long MSG_CUSTOM_SOUND_FULL_FR
	.long MSG_CUSTOM_SOUND_FULL_ES
	.long MSG_CUSTOM_SOUND_FULL_EN2
	.long MSG_CUSTOM_SOUND_FULL_ID


	; Localization: CustomRhythmsAffected (6 languages)
MSG_CUSTOM_RHYTHMS_AFFECTED_EN:	aligned_string "Custom Rhythms affected:"	; English (26 bytes)
MSG_CUSTOM_RHYTHMS_AFFECTED_DE:	.asciz "Betroffene Custom Rhythmen:"	; German (28 bytes)
MSG_CUSTOM_RHYTHMS_AFFECTED_FR:
	.ascii "Custom Rhythms rep"
	.byte 0xe9, 0x72, 0xe9, 0x73, 0x3a, 0x00	; French (24 bytes)
MSG_CUSTOM_RHYTHMS_AFFECTED_ES:		aligned_string "Los ritmos personalizados afectados son:"	; Spanish (42 bytes)
MSG_CUSTOM_RHYTHMS_AFFECTED_EN2:	aligned_string "Custom Rhythms affected:"	; Duplicate (26 bytes)
MSG_CUSTOM_RHYTHMS_AFFECTED_ID:		.asciz "Custom Rhythm sudah bekerja :"	; Indonesian (30 bytes)
	; Pointer table at 0xE1EE2C
	.long MSG_CUSTOM_RHYTHMS_AFFECTED_EN
	.long MSG_CUSTOM_RHYTHMS_AFFECTED_DE
	.long MSG_CUSTOM_RHYTHMS_AFFECTED_FR
	.long MSG_CUSTOM_RHYTHMS_AFFECTED_ES
	.long MSG_CUSTOM_RHYTHMS_AFFECTED_EN2
	.long MSG_CUSTOM_RHYTHMS_AFFECTED_ID


	; Localization: InsertStyleConvertDisk (6 languages)
MSG_INSERT_STYLE_CONVERT_EN:	.asciz "Please Insert the Style Convert Disk!"	; English (38 bytes)
MSG_INSERT_STYLE_CONVERT_DE:	.asciz "Bitte legen Sie die Style Convert Diskette in das Laufwerk ein."	; German (64 bytes)
MSG_INSERT_STYLE_CONVERT_FR:	.asciz "Please Insert the Style Convert Disk!"	; French (38 bytes)
MSG_INSERT_STYLE_CONVERT_ES:	.asciz "Please Insert the Style Convert Disk!"	; Spanish (38 bytes)
MSG_INSERT_STYLE_CONVERT_EN2:	.asciz "Please Insert the Style Convert Disk!"	; Duplicate (38 bytes)
MSG_INSERT_STYLE_CONVERT_ID:	.asciz "Please Insert the Style Convert Disk!"	; Indonesian (38 bytes)
	; Pointer table at 0xE1EF42
	.long MSG_INSERT_STYLE_CONVERT_EN
	.long MSG_INSERT_STYLE_CONVERT_DE
	.long MSG_INSERT_STYLE_CONVERT_FR
	.long MSG_INSERT_STYLE_CONVERT_ES
	.long MSG_INSERT_STYLE_CONVERT_EN2
	.long MSG_INSERT_STYLE_CONVERT_ID
NakaInst_Select_the_sound_for_each_part:


	aligned_string "Select the sound for each part."
	.byte 0x57, 0xe4
	aligned_string "hlen Sie einen Klang für jede gewünschte Klanggruppe"
NakaInst_Select_the_sound_for_each_part_E1EFB2:	aligned_string "Select the sound for each part."
NakaInst_Select_the_sound_for_each_part_E1EFD2:	aligned_string "Select the sound for each part."
NakaInst_Select_the_sound_for_each_part_E1EFF2:	aligned_string "Select the sound for each part."
NakaInst_Select_the_sound_for_each_part_E1F012:	aligned_string "Select the sound for each part."
