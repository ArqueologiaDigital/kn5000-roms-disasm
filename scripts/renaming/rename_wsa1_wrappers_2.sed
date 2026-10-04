# WSA1 naming step (session 53b889a2, wsa1_rename.py)
s/\bsub_FE0046\b/SeqFile_Save_SaveRegs/g
s/\bsub_FE0053\b/SeqFile_Load_SaveRegs/g
s/\bsub_FE0266\b/BStore_GetAnyBankPassword_SaveRegs/g
s/\bsub_FE0273\b/BStore_GetDiskBankPassword_SaveRegs/g
s/\bsub_FE1CD0\b/DiskSave_IsSelectedFileNew_Call/g
s/\bsub_FE1CDC\b/DiskSaveFile_SaveOrConfirmOverwrite_Call/g
s/\bsub_FE1CE0\b/DiskSaveFile_CheckPasswordThenSave_Call/g
