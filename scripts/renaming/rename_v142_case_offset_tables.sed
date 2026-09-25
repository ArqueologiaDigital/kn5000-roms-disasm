# Sub-CPU v1.42, 2026-09-25 (lane subcpu): computed-goto offset tables named after the dispatcher
# their header already cites ("Computed jump in <X>"), like the *_CaseOffsets tables carved the
# same day.  Const_Zero_Byte -> Voice_Part_Trim_Table_A is done by hand in the same commit (it also
# merges the table's split halves).
s/\bOFFSETS_F460\b/AudioTick_CaseOffsets/g
s/\bAlgoJumpTable1\b/DSP_AlgoType_Dispatch1_CaseOffsets/g
s/\bAlgoJumpTable2\b/DSP_AlgoType_Dispatch2_CaseOffsets/g
s/\bAlgoJumpTable3\b/DSP_AlgoType_Dispatch3_CaseOffsets/g
s/\bAlgoJumpTable4\b/Algo_SubTable_DispatchB_CaseOffsets/g
s/\bAlgoJumpTable5\b/Algo_SubTable_DispatchC_CaseOffsets/g
s/\bAlgoJumpTable6\b/Algo_SubTable_Bit15Dispatch_CaseOffsets/g
