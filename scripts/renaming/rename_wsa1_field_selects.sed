# WSA1 prom_b: field-select routines -- each stores N into one screen's field cell and requests a redraw.
# The screen is the one whose named handlers read that cell (LcdKeyRow*_<Screen>_StageZero, Paint_<Screen>).
s/\bsub_F66246\b/Medley_SelectField1/g
s/\bsub_F66251\b/Medley_SelectField2/g
s/\bsub_F7ACC5\b/TrackMerge_SelectField1/g
s/\bsub_F7ACD0\b/TrackMerge_SelectField2/g
s/\bsub_F7ACDB\b/TrackMerge_SelectField3/g
s/\bsub_F7B01A\b/MeasureDelete_SelectField1/g
s/\bsub_F7B025\b/MeasureDelete_SelectField2/g
s/\bsub_F7B035\b/MeasureDelete_SelectField3/g
s/\bsub_F7B246\b/MeasureErase_SelectField1/g
s/\bsub_F7B251\b/MeasureErase_SelectField2/g
s/\bsub_F7B261\b/MeasureErase_SelectField3/g
s/\bsub_F7B271\b/MeasureErase_SelectField4/g
s/\bsub_F7C0BB\b/Quantize_SelectField1/g
s/\bsub_F7C0C6\b/Quantize_SelectField2/g
s/\bsub_F7C0D6\b/Quantize_SelectField3/g
s/\bsub_F7C0E6\b/Quantize_SelectField4/g
s/\bsub_F7C310\b/Quantize_SelectField5/g
s/\bsub_F7C31B\b/Quantize_SelectField6/g
s/\bsub_F7C672\b/Transp0se_SelectField1/g
s/\bsub_F7C682\b/Transp0se_SelectField2/g
s/\bsub_F7C692\b/Transp0se_SelectField3/g
s/\bsub_F7C6A2\b/Transp0se_SelectField4/g
s/\bsub_F7CB1E\b/AdvanceDelay_SelectField1/g
s/\bsub_F7CB29\b/AdvanceDelay_SelectField2/g
s/\bsub_F7CB34\b/AdvanceDelay_SelectField3/g
s/\bsub_F7CB3F\b/AdvanceDelay_SelectField4/g
# the OldCopy_ markers of renamed routines follow them
s/\bOldCopy_sub_F7AA00\b/OldCopy_BStore_AppendBytes_Join3_Veneer/g
s/\bOldCopy_sub_F7AA02\b/OldCopy_BStore_AppendBytes_Join4_Veneer/g
s/\bOldCopy_sub_F7ACC5\b/OldCopy_TrackMerge_SelectField1/g
s/\bOldCopy_sub_F7ACD0\b/OldCopy_TrackMerge_SelectField2/g
s/\bOldCopy_sub_F7ACDB\b/OldCopy_TrackMerge_SelectField3/g
