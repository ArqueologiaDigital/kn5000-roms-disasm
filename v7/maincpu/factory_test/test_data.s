; Factory Test UI Configuration Data
; Factory diagnostics (codename "HAMA"): mode initialization table,
; debug page function names, RTOS command strings, and test list widgets

Hama_ModeInit_Table:
	.long NakaInst_Select_the_sound_for_each_part
	.long NakaInst_Select_the_sound_for_each_part
	.long NakaInst_SelectSoundForPart_A
	.long NakaInst_SelectSoundForPart_B
	.long NakaInst_SelectSoundForPart_C
	.long NakaInst_SelectSoundForPart_D
	.byte 0xce, 0xe7, 0xf1, 0x00, 0xa4, 0xe8
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
	.byte 0x46, 0xe8, 0xf1, 0x00


	.byte 0x55, 0x00, 0x60, 0x01
	.byte 0x30, 0x00, 0x00, 0x00, 0xb2, 0xf0, 0xe1, 0x00
	.long HamaList_HeaderStr_Empty
	.long HamaList_Entry
	.zero 24
HamaList_HeaderStr_Empty:
	.byte 0x00, 0xff, 0x48, 0x61, 0x6d, 0x61, 0x4c, 0x69
	.byte 0x73, 0x74, 0x00, 0xff, 0x01, 0x00, 0xc6, 0xf0
	.byte 0xe1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45, 0x56
	.byte 0x5f, 0x49, 0x4e, 0x44, 0x45, 0x58, 0x5f, 0x50
	.byte 0x55, 0x54, 0x53, 0x00, 0x01, 0x00, 0xde, 0xf0
	.byte 0xe1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4d, 0x54
	.byte 0x5f, 0x43, 0x4f, 0x4e, 0x54, 0x49, 0x4e, 0x55
	.byte 0x45, 0x00, 0x01, 0x00, 0x46, 0xe8, 0xf1, 0x00
	.byte 0xb0, 0xe5, 0xf1, 0x00, 0xe8, 0x21, 0xf5, 0x00
	.byte 0x63, 0xac, 0xfd, 0x00, 0x6a, 0xac, 0xfd, 0x00
	.byte 0xbd, 0xac, 0xfd, 0x00, 0xbe, 0xac, 0xfd, 0x00
	.byte 0xbf, 0xac, 0xfd, 0x00, 0xc0, 0xac, 0xfd, 0x00
	.byte 0xcd, 0xac, 0xfd, 0x00, 0xce, 0xac, 0xfd, 0x00
	.byte 0x42, 0x78, 0xf4, 0x00, 0x4a, 0x78, 0xf4, 0x00
	.byte 0x15, 0x79, 0xf4, 0x00, 0x35, 0x79, 0xf4, 0x00
	.byte 0x20, 0xb8, 0xf6, 0x00, 0x2b, 0xb8, 0xf6, 0x00
	.byte 0x44, 0xb8, 0xf6, 0x00, 0x56, 0xb8, 0xf6, 0x00
	.byte 0xc2, 0xfc, 0xfe, 0x00, 0xc3, 0xfc, 0xfe, 0x00
	.byte 0x07, 0xfd, 0xfe, 0x00, 0x08, 0xfd, 0xfe, 0x00
	.byte 0x62, 0xb8, 0xf6, 0x00, 0x6d, 0xb8, 0xf6, 0x00
	.byte 0x7e, 0xb8, 0xf6, 0x00, 0x95, 0xb8, 0xf6, 0x00
	.byte 0xcf, 0xac, 0xfd, 0x00, 0xd0, 0xac, 0xfd, 0x00
	.byte 0xd1, 0xac, 0xfd, 0x00, 0xd2, 0xac, 0xfd, 0x00
	.byte 0x12, 0x3c, 0xef, 0x00, 0x06, 0xea, 0xf1, 0x00
	.byte 0x06, 0xeb, 0xf1, 0x00, 0x4b, 0x1a, 0xf5, 0x00
	.byte 0x4d, 0x23, 0xf5, 0x00, 0xca, 0x23, 0xf5, 0x00
	.byte 0x86, 0x25, 0xf5, 0x00, 0xe4, 0x26, 0xf5, 0x00
	.byte 0xa6, 0x26, 0xf5, 0x00, 0xfa, 0xec, 0xf1, 0x00
	.byte 0xfe, 0xec, 0xf1, 0x00, 0x02, 0xed, 0xf1, 0x00
	.byte 0x06, 0xed, 0xf1, 0x00, 0xfe, 0xea, 0xf1, 0x00
	.byte 0x02, 0xeb, 0xf1, 0x00, 0x0e, 0xed, 0xf1, 0x00
	.byte 0x12, 0xed, 0xf1, 0x00, 0x16, 0xed, 0xf1, 0x00
	.byte 0x1a, 0xed, 0xf1, 0x00, 0x1e, 0xed, 0xf1, 0x00
	.byte 0x22, 0xed, 0xf1, 0x00, 0x26, 0xed, 0xf1, 0x00
	.byte 0x2a, 0xed, 0xf1, 0x00, 0x2e, 0xed, 0xf1, 0x00
	.byte 0x32, 0xed, 0xf1, 0x00, 0x36, 0xed, 0xf1, 0x00
	.byte 0x3a, 0xed, 0xf1, 0x00, 0x3e, 0xed, 0xf1, 0x00
	.byte 0x7e, 0xed, 0xf1, 0x00, 0x94, 0xed, 0xf1, 0x00
	.byte 0xa0, 0xed, 0xf1, 0x00, 0xaa, 0xed, 0xf1, 0x00
	.byte 0xb4, 0xed, 0xf1, 0x00, 0xb8, 0xed, 0xf1, 0x00
	.byte 0xbd, 0xed, 0xf1, 0x00, 0xc2, 0xed, 0xf1, 0x00
	.byte 0xc7, 0xed, 0xf1, 0x00, 0xf8, 0x7b, 0xf8, 0x00
	.byte 0xca, 0x32, 0xef, 0x00, 0x22, 0xaa, 0xfd, 0x00
	.byte 0x53, 0xaa, 0xfd, 0x00, 0x84, 0xaa, 0xfd, 0x00
	.byte 0xae, 0x14, 0xef, 0x00, 0xc9, 0x14, 0xef, 0x00
	.byte 0xcc, 0xed, 0xf1, 0x00, 0xd1, 0xed, 0xf1, 0x00
	.byte 0xd9, 0xed, 0xf1, 0x00, 0xba, 0xee, 0xfa, 0x00
	.byte 0xfe, 0xed, 0xfa, 0x00, 0x5a, 0x3b, 0xfb, 0x00
	.byte 0x9c, 0x2c, 0xfb, 0x00, 0xe1, 0xed, 0xf1, 0x00
	.byte 0x0a, 0xed, 0xf1, 0x00, 0x00, 0x00, 0x00, 0x00
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
