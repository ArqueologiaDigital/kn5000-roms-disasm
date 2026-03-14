Hama_ModeInit_Table:
	.long NakaInst_Select_the_sound_for_each_part
	.long NakaInst_Select_the_sound_for_each_part
	.long NakaInst_Select_the_sound_for_each_part_E1EFB2
	.long NakaInst_Select_the_sound_for_each_part_E1EFD2
	.long NakaInst_Select_the_sound_for_each_part_E1EFF2
	.long NakaInst_Select_the_sound_for_each_part_E1F012
	.byte 0xf8, 0xe7, 0xf1, 0x00, 0xce, 0xe8
	.byte 0xf1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6c, 0xf0
	.byte 0xe1, 0x00
	.long LABEL_E1F064
	.long LABEL_E1F062
LABEL_E1F062:	aligned_string ""
LABEL_E1F064:	aligned_string "hamadeb"
LABEL_E1F06C:	aligned_string "HamaPage1Func"
LABEL_E1F07A:
	.long LABEL_E1F07E
LABEL_E1F07E:	aligned_string ""
	.byte 0x70, 0xe8, 0xf1, 0x00


	.byte 0x55, 0x00, 0x60, 0x01
	.byte 0x30, 0x00, 0x00, 0x00, 0xb2, 0xf0, 0xe1, 0x00
	.long LABEL_E1F0B0
	.long LABEL_E1F07A
	.zero 24
LABEL_E1F0B0:	aligned_string ""
	aligned_string "HamaList"
	.byte 0x01, 0x00, 0xc6, 0xf0
	.byte 0xe1, 0x00, 0x00, 0x00, 0x00, 0x00
	aligned_string "EV_INDEX_PUTS"
	.byte 0x01, 0x00, 0xde, 0xf0
	.byte 0xe1, 0x00, 0x00, 0x00, 0x00, 0x00
	aligned_string "MT_CONTINUE"
	.byte 0x01, 0x00, 0x70, 0xe8, 0xf1, 0x00
	.byte 0xda, 0xe5, 0xf1, 0x00, 0xec, 0x25, 0xf5, 0x00
	.byte 0x34, 0xb4, 0xfd, 0x00, 0x3b, 0xb4, 0xfd, 0x00
	.byte 0x8e, 0xb4, 0xfd, 0x00, 0x8f, 0xb4, 0xfd, 0x00
	.byte 0x90, 0xb4, 0xfd, 0x00, 0x91, 0xb4, 0xfd, 0x00
	.byte 0x9e, 0xb4, 0xfd, 0x00, 0x9f, 0xb4, 0xfd, 0x00
	.byte 0x50, 0x78, 0xf4, 0x00, 0x58, 0x78, 0xf4, 0x00
	.byte 0x23, 0x79, 0xf4, 0x00, 0x43, 0x79, 0xf4, 0x00
	.byte 0x24, 0xbc, 0xf6, 0x00, 0x2f, 0xbc, 0xf6, 0x00
	.byte 0x48, 0xbc, 0xf6, 0x00, 0x5a, 0xbc, 0xf6, 0x00
	.byte 0x9f, 0x04, 0xff, 0x00, 0xa0, 0x04, 0xff, 0x00
	.byte 0xe4, 0x04, 0xff, 0x00, 0xe5, 0x04, 0xff, 0x00
	.byte 0x66, 0xbc, 0xf6, 0x00, 0x71, 0xbc, 0xf6, 0x00
	.byte 0x82, 0xbc, 0xf6, 0x00, 0x99, 0xbc, 0xf6, 0x00
	.byte 0xa0, 0xb4, 0xfd, 0x00, 0xa1, 0xb4, 0xfd, 0x00
	.byte 0xa2, 0xb4, 0xfd, 0x00, 0xa3, 0xb4, 0xfd, 0x00
	.long FlashWrite
	.long GetResouceInfo
	.byte 0x30, 0xeb, 0xf1, 0x00, 0x4f, 0x1e, 0xf5, 0x00
	.byte 0x51, 0x27, 0xf5, 0x00, 0xce, 0x27, 0xf5, 0x00
	.byte 0x8a, 0x29, 0xf5, 0x00, 0xe8, 0x2a, 0xf5, 0x00
	.byte 0xaa, 0x2a, 0xf5, 0x00, 0x24, 0xed, 0xf1, 0x00
	.byte 0x28, 0xed, 0xf1, 0x00, 0x2c, 0xed, 0xf1, 0x00
	.byte 0x30, 0xed, 0xf1, 0x00, 0x28, 0xeb, 0xf1, 0x00
	.byte 0x2c, 0xeb, 0xf1, 0x00, 0x38, 0xed, 0xf1, 0x00
	.byte 0x3c, 0xed, 0xf1, 0x00, 0x40, 0xed, 0xf1, 0x00
	.byte 0x44, 0xed, 0xf1, 0x00, 0x48, 0xed, 0xf1, 0x00
	.byte 0x4c, 0xed, 0xf1, 0x00, 0x50, 0xed, 0xf1, 0x00
	.byte 0x54, 0xed, 0xf1, 0x00, 0x58, 0xed, 0xf1, 0x00
	.byte 0x5c, 0xed, 0xf1, 0x00, 0x60, 0xed, 0xf1, 0x00
	.byte 0x64, 0xed, 0xf1, 0x00, 0x68, 0xed, 0xf1, 0x00
	.byte 0xa8, 0xed, 0xf1, 0x00, 0xbe, 0xed, 0xf1, 0x00
	.byte 0xca, 0xed, 0xf1, 0x00, 0xd4, 0xed, 0xf1, 0x00
	.byte 0xde, 0xed, 0xf1, 0x00, 0xe2, 0xed, 0xf1, 0x00
	.byte 0xe7, 0xed, 0xf1, 0x00, 0xec, 0xed, 0xf1, 0x00
	.byte 0xf1, 0xed, 0xf1, 0x00, 0x05, 0x80, 0xf8, 0x00
	.long sendCOMM
	.long AssswbWr
	.byte 0x24, 0xb2, 0xfd, 0x00, 0x55, 0xb2, 0xfd, 0x00
	.long assswb_op
	.long assswb_out
	.byte 0xf6, 0xed, 0xf1, 0x00, 0xfb, 0xed, 0xf1, 0x00
	.byte 0x03, 0xee, 0xf1, 0x00, 0xc7, 0xf2, 0xfa, 0x00
	.byte 0x0b, 0xf2, 0xfa, 0x00, 0x67, 0x3f, 0xfb, 0x00
	.byte 0xa9, 0x30, 0xfb, 0x00, 0x0b, 0xee, 0xf1, 0x00
	.byte 0x34, 0xed, 0xf1, 0x00, 0x00, 0x00, 0x00, 0x00
Hama_ModeParam_Table:
	.long LABEL_E1F774
	.long LABEL_E1F764
	.long LABEL_E1F756
	.long LABEL_E1F74A
	.long LABEL_E1F73E
	.long LABEL_E1F732
	.long LABEL_E1F726
	.long LABEL_E1F71C
	.long LABEL_E1F710
	.long LABEL_E1F706
	.long LABEL_E1F6FA
	.long LABEL_E1F6EE
	.long LABEL_E1F6E2
	.long LABEL_E1F6D6
	.long LABEL_E1F6CA
	.long LABEL_E1F6BE
	.long LABEL_E1F6B2
	.long LABEL_E1F6A6
	.long LABEL_E1F69A
	.long LABEL_E1F690
	.long LABEL_E1F684
	.long LABEL_E1F67A
	.long LABEL_E1F66E
	.long LABEL_E1F662
	.long LABEL_E1F656
	.long LABEL_E1F64A
	.long LABEL_E1F63E
	.long LABEL_E1F632
	.long LABEL_E1F624
	.long LABEL_E1F618
	.long LABEL_E1F60A
	.long LABEL_E1F5FE
	.long LABEL_E1F5EE
	.long LABEL_E1F5DE
	.long LABEL_E1F5D4
	.long LABEL_E1F5C2
	.long LABEL_E1F5B2
	.long LABEL_E1F5A6
	.long LABEL_E1F59C
	.long LABEL_E1F590
	.long LABEL_E1F586
	.long LABEL_E1F57A
	.long LABEL_E1F570
	.long LABEL_E1F564
	.long LABEL_E1F556
	.long LABEL_E1F548
	.long LABEL_E1F53E
	.long LABEL_E1F534
	.long LABEL_E1F52A
	.long LABEL_E1F520
	.long LABEL_E1F514
	.long LABEL_E1F50A
	.long LABEL_E1F500
	.long LABEL_E1F4F6
	.long LABEL_E1F4EC
	.long LABEL_E1F4E0
	.long LABEL_E1F4D6
	.long LABEL_E1F4CA
	.long LABEL_E1F4C0
	.long LABEL_E1F4B4
	.long LABEL_E1F4A6
	.long LABEL_E1F498
	.long LABEL_E1F48A
	.long LABEL_E1F47C
	.long LABEL_E1F46E
	.long LABEL_E1F45E
	.long LABEL_E1F450
	.long LABEL_E1F442
	.long LABEL_E1F436
	.long LABEL_E1F42C
	.long LABEL_E1F422
	.long LABEL_E1F418
	.long LABEL_E1F410
	.long LABEL_E1F406
	.long LABEL_E1F3FA
	.long LABEL_E1F3EA
	.long LABEL_E1F3E0
	.long LABEL_E1F3D8
	.long LABEL_E1F3CA
	.long LABEL_E1F3BE
	.long LABEL_E1F3B4
	.long LABEL_E1F3AC
	.long LABEL_E1F3A2
	.long LABEL_E1F396
	.long LABEL_E1F394
LABEL_E1F394:	aligned_string ""
LABEL_E1F396:	aligned_string "ferror_ext"
LABEL_E1F3A2:	aligned_string "SetWall_X"
LABEL_E1F3AC:	aligned_string "AllBOut"
LABEL_E1F3B4:	aligned_string "BitMapOut"
LABEL_E1F3BE:	aligned_string "ChangeWall"
LABEL_E1F3CA:	aligned_string "ChangePalette"
LABEL_E1F3D8:	aligned_string "free_X"
LABEL_E1F3E0:	aligned_string "malloc_X"
LABEL_E1F3EA:	aligned_string "SetGlobalError"
LABEL_E1F3FA:	aligned_string "assswb_out"
LABEL_E1F406:	aligned_string "assswb_op"
LABEL_E1F410:	aligned_string "SwbtWr"
LABEL_E1F418:	aligned_string "AddswbWr"
LABEL_E1F422:	aligned_string "AssswbWr"
LABEL_E1F42C:	aligned_string "sendCOMM"
LABEL_E1F436:	aligned_string "LoadFileSMF"
LABEL_E1F442:	aligned_string "GetAdr_rtmcfg"
LABEL_E1F450:	aligned_string "GetAdr_sqsrtc"
LABEL_E1F45E:	aligned_string "GetAdr_sq_beadt"
LABEL_E1F46E:	aligned_string "GetAdr_sqbtof"
LABEL_E1F47C:	aligned_string "midi_out_en_X"
LABEL_E1F48A:	aligned_string "putc_mrx_bf_X"
LABEL_E1F498:	aligned_string "putc_mtx_bf_X"
LABEL_E1F4A6:	aligned_string "EditSwRefresh"
LABEL_E1F4B4:	aligned_string "PlayStandBy"
LABEL_E1F4C0:	aligned_string "PlayHalt"
LABEL_E1F4CA:	aligned_string "pdly_tim_X"
LABEL_E1F4D6:	aligned_string "get_tid_X"
LABEL_E1F4E0:	aligned_string "prcv_msg_X"
LABEL_E1F4EC:	aligned_string "rcv_msg_X"
LABEL_E1F4F6:	aligned_string "snd_msg_X"
LABEL_E1F500:	aligned_string "ref_sem_X"
LABEL_E1F50A:	aligned_string "wai_sem_X"
LABEL_E1F514:	aligned_string "preq_sem_X"
LABEL_E1F520:	aligned_string "sig_sem_X"
LABEL_E1F52A:	aligned_string "wai_flg_X"
LABEL_E1F534:	aligned_string "set_flg_X"
LABEL_E1F53E:	aligned_string "rot_rdq_X"
LABEL_E1F548:	aligned_string "rcm_sv_XAPR_j"
LABEL_E1F556:	aligned_string "rcm_ld_XAPR_j"
LABEL_E1F564:	aligned_string "fclose_ext"
LABEL_E1F570:	aligned_string "fread_ext"
LABEL_E1F57A:	aligned_string "fwrite_ext"
LABEL_E1F586:	aligned_string "fopen_ext"
LABEL_E1F590:	aligned_string "_findclose"
LABEL_E1F59C:	aligned_string "_findnext"
LABEL_E1F5A6:	aligned_string "_findfirst"
LABEL_E1F5B2:	aligned_string "GetVolumeLabel"
LABEL_E1F5C2:	aligned_string "GetDiskFreeSpace"
LABEL_E1F5D4:	aligned_string "format_FD"
LABEL_E1F5DE:	aligned_string "SetSepaOutMode"
LABEL_E1F5EE:	aligned_string "GetResouceInfo"
LABEL_E1F5FE:	aligned_string "FlashWrite"
LABEL_E1F60A:	aligned_string "PostMidiSave"
LABEL_E1F618:	aligned_string "PreMidiSave"
LABEL_E1F624:	aligned_string "PostMidiLoad"
LABEL_E1F632:	aligned_string "PreMidiLoad"
LABEL_E1F63E:	aligned_string "msp_sv_ato"
LABEL_E1F64A:	aligned_string "msp_sv_mae"
LABEL_E1F656:	aligned_string "msp_ld_ato"
LABEL_E1F662:	aligned_string "msp_ld_mae"
LABEL_E1F66E:	aligned_string "PostTmSave"
LABEL_E1F67A:	aligned_string "PreTmSave"
LABEL_E1F684:	aligned_string "PostTmLoad"
LABEL_E1F690:	aligned_string "PreTmLoad"
LABEL_E1F69A:	aligned_string "cmp_sv_ato"
LABEL_E1F6A6:	aligned_string "cmp_sv_mae"
LABEL_E1F6B2:	aligned_string "cmp_ld_ato"
LABEL_E1F6BE:	aligned_string "cmp_ld_mae"
LABEL_E1F6CA:	aligned_string "SeqSavePost"
LABEL_E1F6D6:	aligned_string "SeqSavePre"
LABEL_E1F6E2:	aligned_string "SeqLoadPost"
LABEL_E1F6EE:	aligned_string "SeqLoadPre"
LABEL_E1F6FA:	aligned_string "PostPmSave"
LABEL_E1F706:	aligned_string "PrePmSave"
LABEL_E1F710:	aligned_string "PostPmLoad"
LABEL_E1F71C:	aligned_string "PrePmLoad"
LABEL_E1F726:	aligned_string "PostLswSave"
LABEL_E1F732:	aligned_string "PreLswSave"
LABEL_E1F73E:	aligned_string "PostLswLoad"
LABEL_E1F74A:	aligned_string "PreLswLoad"
LABEL_E1F756:	aligned_string "GetMediaType"
LABEL_E1F764:	aligned_string "FDLoadSaveTest"
LABEL_E1F774:	aligned_string "HamaListProc"
	aligned_string "FD SAVE/LOAD TEST"
