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
	.long HamaStr_hamadeb
	.long HamaStr_Empty
HamaStr_Empty:	aligned_string ""
HamaStr_hamadeb:	aligned_string "hamadeb"
HamaStr_HamaPage1Func:	aligned_string "HamaPage1Func"
HamaList_Entry:
	.long HamaList_EntryStr_Empty
HamaList_EntryStr_Empty:	aligned_string ""
	.byte 0x70, 0xe8, 0xf1, 0x00


	.byte 0x55, 0x00, 0x60, 0x01
	.byte 0x30, 0x00, 0x00, 0x00, 0xb2, 0xf0, 0xe1, 0x00
	.long HamaList_HeaderStr_Empty
	.long HamaList_Entry
	.zero 24
HamaList_HeaderStr_Empty:	aligned_string ""
	aligned_string "HamaList"
	normal
	nop
	.byte 0xc6, 0xf0, 0xe1, 0x00, 0x00
	nop
	nop
	nop
	aligned_string "EV_INDEX_PUTS"
	normal
	nop
	cp	wa, iz
	.byte 0xe1, 0x00, 0x00, 0x00
	nop
	nop
	aligned_string "MT_CONTINUE"
	normal
	nop
	.byte 0x70, 0xe8, 0xf1
	nop
	or	iy, de
	.byte 0xf1, 0x00, 0xec, 0x25, 0xf5, 0x00, 0x34, 0xb4
	.byte 0xfd
	nop
	push xhl
	.byte 0xb4, 0xfd
	nop
	.byte 0x8e, 0xb4, 0xfd
	nop
	.byte 0x8f, 0xb4, 0xfd
	nop
	sbc	ix, (xwa)
	swi	5
	nop
	sbc	ix, (xbc)
	swi	5
	nop
	.byte 0x9e, 0xb4, 0xfd
	nop
	.byte 0x9f, 0xb4, 0xfd
	nop
	.byte 0x50, 0x78, 0xf4, 0x00
	pop xwa
	.byte 0x78, 0xf4, 0x00
	ldb	c, 121
	.byte 0xf4, 0x00, 0x43, 0x79, 0xf4, 0x00
	ldb	d, 188
	.byte 0xf6
	nop
	pushw sp
	.byte 0xbc, 0xf6, 0x00, 0x48, 0xbc, 0xf6, 0x00, 0x5a
	.byte 0xbc, 0xf6, 0x00, 0x9f
	max
	swi	7
	nop
	.byte 0xa0, 0x04
	swi	7
	nop
	.byte 0xe4, 0x04, 0xff
	nop
	.byte 0xe5, 0x04, 0xff
	nop
	.byte 0x66, 0xbc, 0xf6
	nop
	.byte 0x71, 0xbc, 0xf6
	nop
	sbc	(xde), d
	.byte 0xf6
	nop
	.byte 0x99, 0xbc, 0xf6
	nop
	sbc	xix, (xwa)
	swi	5
	nop
	sbc	xix, (xbc)
	swi	5
	nop
	sbc	xix, (xde)
	swi	5
	nop
	sbc	xix, (xhl)
	swi	5
	nop
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
	.long HamaStr_HamaListProc
	.long HamaStr_FDLoadSaveTest
	.long HamaStr_GetMediaType
	.long HamaStr_PreLswLoad
	.long HamaStr_PostLswLoad
	.long HamaStr_PreLswSave
	.long HamaStr_PostLswSave
	.long HamaStr_PrePmLoad
	.long HamaStr_PostPmLoad
	.long HamaStr_PrePmSave
	.long HamaStr_PostPmSave
	.long HamaStr_SeqLoadPre
	.long HamaStr_SeqLoadPost
	.long HamaStr_SeqSavePre
	.long HamaStr_SeqSavePost
	.long HamaStr_cmp_ld_mae
	.long HamaStr_cmp_ld_ato
	.long HamaStr_cmp_sv_mae
	.long HamaStr_cmp_sv_ato
	.long HamaStr_PreTmLoad
	.long HamaStr_PostTmLoad
	.long HamaStr_PreTmSave
	.long HamaStr_PostTmSave
	.long HamaStr_msp_ld_mae
	.long HamaStr_msp_ld_ato
	.long HamaStr_msp_sv_mae
	.long HamaStr_msp_sv_ato
	.long HamaStr_PreMidiLoad
	.long HamaStr_PostMidiLoad
	.long HamaStr_PreMidiSave
	.long HamaStr_PostMidiSave
	.long HamaStr_FlashWrite
	.long HamaStr_GetResouceInfo
	.long HamaStr_SetSepaOutMode
	.long HamaStr_format_FD
	.long HamaStr_GetDiskFreeSpace
	.long HamaStr_GetVolumeLabel
	.long HamaStr_findfirst
	.long HamaStr_findnext
	.long HamaStr_findclose
	.long HamaStr_fopen_ext
	.long HamaStr_fwrite_ext
	.long HamaStr_fread_ext
	.long HamaStr_fclose_ext
	.long HamaStr_rcm_ld_XAPR_j
	.long HamaStr_rcm_sv_XAPR_j
	.long HamaStr_rot_rdq_X
	.long HamaStr_set_flg_X
	.long HamaStr_wai_flg_X
	.long HamaStr_sig_sem_X
	.long HamaStr_preq_sem_X
	.long HamaStr_wai_sem_X
	.long HamaStr_ref_sem_X
	.long HamaStr_snd_msg_X
	.long HamaStr_rcv_msg_X
	.long HamaStr_prcv_msg_X
	.long HamaStr_get_tid_X
	.long HamaStr_pdly_tim_X
	.long HamaStr_PlayHalt
	.long HamaStr_PlayStandBy
	.long HamaStr_EditSwRefresh
	.long HamaStr_putc_mtx_bf_X
	.long HamaStr_putc_mrx_bf_X
	.long HamaStr_midi_out_en_X
	.long HamaStr_GetAdr_sqbtof
	.long HamaStr_GetAdr_sq_beadt
	.long HamaStr_GetAdr_sqsrtc
	.long HamaStr_GetAdr_rtmcfg
	.long HamaStr_LoadFileSMF
	.long HamaStr_sendCOMM
	.long HamaStr_AssswbWr
	.long HamaStr_AddswbWr
	.long HamaStr_SwbtWr
	.long HamaStr_assswb_op
	.long HamaStr_assswb_out
	.long HamaStr_SetGlobalError
	.long HamaStr_malloc_X
	.long HamaStr_free_X
	.long HamaStr_ChangePalette
	.long HamaStr_ChangeWall
	.long HamaStr_BitMapOut
	.long HamaStr_AllBOut
	.long HamaStr_SetWall_X
	.long HamaStr_ferror_ext
	.long HamaStr_ModeParam_Empty
HamaStr_ModeParam_Empty:	aligned_string ""
HamaStr_ferror_ext:	aligned_string "ferror_ext"
HamaStr_SetWall_X:	aligned_string "SetWall_X"
HamaStr_AllBOut:	aligned_string "AllBOut"
HamaStr_BitMapOut:	aligned_string "BitMapOut"
HamaStr_ChangeWall:	aligned_string "ChangeWall"
HamaStr_ChangePalette:	aligned_string "ChangePalette"
HamaStr_free_X:	aligned_string "free_X"
HamaStr_malloc_X:	aligned_string "malloc_X"
HamaStr_SetGlobalError:	aligned_string "SetGlobalError"
HamaStr_assswb_out:	aligned_string "assswb_out"
HamaStr_assswb_op:	aligned_string "assswb_op"
HamaStr_SwbtWr:	aligned_string "SwbtWr"
HamaStr_AddswbWr:	aligned_string "AddswbWr"
HamaStr_AssswbWr:	aligned_string "AssswbWr"
HamaStr_sendCOMM:	aligned_string "sendCOMM"
HamaStr_LoadFileSMF:	aligned_string "LoadFileSMF"
HamaStr_GetAdr_rtmcfg:	aligned_string "GetAdr_rtmcfg"
HamaStr_GetAdr_sqsrtc:	aligned_string "GetAdr_sqsrtc"
HamaStr_GetAdr_sq_beadt:	aligned_string "GetAdr_sq_beadt"
HamaStr_GetAdr_sqbtof:	aligned_string "GetAdr_sqbtof"
HamaStr_midi_out_en_X:	aligned_string "midi_out_en_X"
HamaStr_putc_mrx_bf_X:	aligned_string "putc_mrx_bf_X"
HamaStr_putc_mtx_bf_X:	aligned_string "putc_mtx_bf_X"
HamaStr_EditSwRefresh:	aligned_string "EditSwRefresh"
HamaStr_PlayStandBy:	aligned_string "PlayStandBy"
HamaStr_PlayHalt:	aligned_string "PlayHalt"
HamaStr_pdly_tim_X:	aligned_string "pdly_tim_X"
HamaStr_get_tid_X:	aligned_string "get_tid_X"
HamaStr_prcv_msg_X:	aligned_string "prcv_msg_X"
HamaStr_rcv_msg_X:	aligned_string "rcv_msg_X"
HamaStr_snd_msg_X:	aligned_string "snd_msg_X"
HamaStr_ref_sem_X:	aligned_string "ref_sem_X"
HamaStr_wai_sem_X:	aligned_string "wai_sem_X"
HamaStr_preq_sem_X:	aligned_string "preq_sem_X"
HamaStr_sig_sem_X:	aligned_string "sig_sem_X"
HamaStr_wai_flg_X:	aligned_string "wai_flg_X"
HamaStr_set_flg_X:	aligned_string "set_flg_X"
HamaStr_rot_rdq_X:	aligned_string "rot_rdq_X"
HamaStr_rcm_sv_XAPR_j:	aligned_string "rcm_sv_XAPR_j"
HamaStr_rcm_ld_XAPR_j:	aligned_string "rcm_ld_XAPR_j"
HamaStr_fclose_ext:	aligned_string "fclose_ext"
HamaStr_fread_ext:	aligned_string "fread_ext"
HamaStr_fwrite_ext:	aligned_string "fwrite_ext"
HamaStr_fopen_ext:	aligned_string "fopen_ext"
HamaStr_findclose:	aligned_string "_findclose"
HamaStr_findnext:	aligned_string "_findnext"
HamaStr_findfirst:	aligned_string "_findfirst"
HamaStr_GetVolumeLabel:	aligned_string "GetVolumeLabel"
HamaStr_GetDiskFreeSpace:	aligned_string "GetDiskFreeSpace"
HamaStr_format_FD:	aligned_string "format_FD"
HamaStr_SetSepaOutMode:	aligned_string "SetSepaOutMode"
HamaStr_GetResouceInfo:	aligned_string "GetResouceInfo"
HamaStr_FlashWrite:	aligned_string "FlashWrite"
HamaStr_PostMidiSave:	aligned_string "PostMidiSave"
HamaStr_PreMidiSave:	aligned_string "PreMidiSave"
HamaStr_PostMidiLoad:	aligned_string "PostMidiLoad"
HamaStr_PreMidiLoad:	aligned_string "PreMidiLoad"
HamaStr_msp_sv_ato:	aligned_string "msp_sv_ato"
HamaStr_msp_sv_mae:	aligned_string "msp_sv_mae"
HamaStr_msp_ld_ato:	aligned_string "msp_ld_ato"
HamaStr_msp_ld_mae:	aligned_string "msp_ld_mae"
HamaStr_PostTmSave:	aligned_string "PostTmSave"
HamaStr_PreTmSave:	aligned_string "PreTmSave"
HamaStr_PostTmLoad:	aligned_string "PostTmLoad"
HamaStr_PreTmLoad:	aligned_string "PreTmLoad"
HamaStr_cmp_sv_ato:	aligned_string "cmp_sv_ato"
HamaStr_cmp_sv_mae:	aligned_string "cmp_sv_mae"
HamaStr_cmp_ld_ato:	aligned_string "cmp_ld_ato"
HamaStr_cmp_ld_mae:	aligned_string "cmp_ld_mae"
HamaStr_SeqSavePost:	aligned_string "SeqSavePost"
HamaStr_SeqSavePre:	aligned_string "SeqSavePre"
HamaStr_SeqLoadPost:	aligned_string "SeqLoadPost"
HamaStr_SeqLoadPre:	aligned_string "SeqLoadPre"
HamaStr_PostPmSave:	aligned_string "PostPmSave"
HamaStr_PrePmSave:	aligned_string "PrePmSave"
HamaStr_PostPmLoad:	aligned_string "PostPmLoad"
HamaStr_PrePmLoad:	aligned_string "PrePmLoad"
HamaStr_PostLswSave:	aligned_string "PostLswSave"
HamaStr_PreLswSave:	aligned_string "PreLswSave"
HamaStr_PostLswLoad:	aligned_string "PostLswLoad"
HamaStr_PreLswLoad:	aligned_string "PreLswLoad"
HamaStr_GetMediaType:	aligned_string "GetMediaType"
HamaStr_FDLoadSaveTest:	aligned_string "FDLoadSaveTest"
HamaStr_HamaListProc:	aligned_string "HamaListProc"
	aligned_string "FD SAVE/LOAD TEST"
