# Tables named after the wrong routine: their readers are the routines insert_labels.py named
# on 2026-10-02 (SoundEvt_ModeDispatch, Display_ModePopupDispatch), which had been reached
# only through positional aliases (Wave 2 claims review).
s/\bSoundEvt_LongPacketHandler_DispatchTbl\b/SoundEvt_ModeDispatch_Tbl/g
s/\bVoiceSlot_StatusRet_DispatchTbl\b/Display_ModePopupDispatch_Tbl/g
s/\bVoiceSlot_StatusRet_Tbl\b/Display_ModePopupIds/g
# v7 had the two SoundEvt tables' names SWAPPED relative to v10 (its _DispatchTbl2 is v10's
# _DispatchTbl and vice versa) and a second label, SoundEvt_ShortPacketHandler_Helper, on the
# mode-dispatch routine; both fixed for v7 by a one-off simultaneous rename in the same commit.
