# Sound-parameter banks (technics-docs custom-data-flash.md, "Sound-Parameter User Banks"): the routines that check
# and write the Custom Data Flash banks at 0x3D3000 and the 0x50-byte block at 0x3D3400, and their ROM defaults,
# were ToneGen_Flash* / DSPCfg_Param_Case* by guess.  scripts/converters/sndparam_bank_retype.py types the data.
# OptionDefault_NN: the default of the field at +0xNN of the 0x50-byte block (copied to RAM 0x340E4 + ...).
s/\bToneGen_FlashVerify_Str_HK\b/SndParamBank_DefaultHeader/g
s/\bToneGen_FlashWriteAll_Data_2\b/SndParamBank_Default2/g
s/\bToneGen_FlashWriteAll_Data_3\b/SndParamBank_OptionDefault_00/g
s/\bToneGen_FlashWriteAll_Data_4\b/SndParamBank_OptionDefault_30/g
s/\bToneGen_FlashWriteAll_Data_5\b/SndParamBank_OptionDefault_10/g
s/\bToneGen_FlashWriteAll_Data_6\b/SndParamBank_OptionDefault_20/g
s/\bToneGen_FlashWriteAll_Data_7\b/SndParamBank_OptionDefault_40/g
s/\bToneGen_FlashWriteAll_Data\b/SndParamBank_Default1/g
s/\bToneGen_FlashVerifyLoop\b/SndParamBank_CheckFlash_Loop/g
s/\bToneGen_FlashVerify\b/SndParamBank_CheckFlash/g
s/\bToneGen_FlashWriteAll\b/SndParamBank_WriteFlashDefaults/g
s/\bToneGen_FlashWriteDone\b/SndParamBank_WriteFlashDefaults_Return/g
s/\bToneGen_FlashReadAndRestore\b/SndParamBank_RestoreOptionBlock/g
s/\bDSPCfg_Param_CaseA\b/SndParamBank_RestoreOptionBlock_Return/g
s/\bDSPCfg_Param_CaseB\b/SndParamBank_LoadOptionBlock/g
s/\bSndParam_AllocAndCopyPreset_Data\b/SndParam_PresetBanks/g
