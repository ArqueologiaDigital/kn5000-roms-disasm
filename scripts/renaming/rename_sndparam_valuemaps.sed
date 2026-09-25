# CharMap_* -> SndParam_ValueMap_* (the 128-byte maps are sound-parameter value maps
# read through SndParam_ValueMapGrid; see scripts/generators/gen_sndparam_valuemap_headers.py).
# Names are the grid position of first appearance: R<row>P<pair>, _Inv = odd column.
# CharMap_FullPermutation is renamed only at its definition and in the grid, because
# shared/positional_labels.s derives CharMap_FullPermutation_0xNN names from it;
# the generator adds `.set CharMap_FullPermutation, SndParam_ValueMap_R1P2_Inv`.
# Apply to: v{10,9,7}/maincpu/ui_widgets/widget_dispatch.s v{10,9,7}/maincpu/ui/charmap_dispatch_table.s
s/\bCharMap_ModeDispatchTable\b/SndParam_ValueMapGrid/g
s/\bCharMap_DefaultIdentity\b/SndParam_ValueMap_Identity/g
s/\bCharMap_Mode6Forward\b/SndParam_ValueMap_R1P0/g
s/\bCharMap_Mode7\b/SndParam_ValueMap_R1P0_Inv/g
s/\bCharMap_Mode1Forward\b/SndParam_ValueMap_R1P1/g
s/\bCharMap_Mode6Reverse\b/SndParam_ValueMap_R1P1_Inv/g
s/\bCharMap_Mode17\b/SndParam_ValueMap_R1P2/g
s/^CharMap_FullPermutation:/SndParam_ValueMap_R1P2_Inv:/
s/^\t\.long CharMap_FullPermutation$/\t.long SndParam_ValueMap_R1P2_Inv/
s/\bCharMap_Mode12\b/SndParam_ValueMap_R2P2/g
s/\bCharMap_Mode18\b/SndParam_ValueMap_R2P2_Inv/g
s/\bCharMap_Mode2Forward\b/SndParam_ValueMap_R3P0/g
s/\bCharMap_Mode2Reverse\b/SndParam_ValueMap_R3P0_Inv/g
s/\bCharMap_Mode13\b/SndParam_ValueMap_R3P2/g
s/\bCharMap_Mode19\b/SndParam_ValueMap_R3P2_Inv/g
s/\bCharMap_Mode3Forward\b/SndParam_ValueMap_R4P0/g
s/\bCharMap_Mode3Reverse\b/SndParam_ValueMap_R4P0_Inv/g
s/\bCharMap_Mode14\b/SndParam_ValueMap_R4P2/g
s/\bCharMap_Mode20\b/SndParam_ValueMap_R4P2_Inv/g
s/\bCharMap_Mode5Forward\b/SndParam_ValueMap_R5P0/g
s/\bCharMap_Mode5Reverse\b/SndParam_ValueMap_R5P0_Inv/g
s/\bCharMap_Mode9\b/SndParam_ValueMap_R5P1/g
s/\bCharMap_Mode11\b/SndParam_ValueMap_R5P1_Inv/g
s/\bCharMap_Mode16\b/SndParam_ValueMap_R5P2/g
s/\bCharMap_Mode22\b/SndParam_ValueMap_R5P2_Inv/g
s/\bCharMap_Mode4Forward\b/SndParam_ValueMap_R6P0/g
s/\bCharMap_Mode4Reverse\b/SndParam_ValueMap_R6P0_Inv/g
s/\bCharMap_Mode8\b/SndParam_ValueMap_R6P1/g
s/\bCharMap_Mode10\b/SndParam_ValueMap_R6P1_Inv/g
s/\bCharMap_Mode15\b/SndParam_ValueMap_R6P2/g
s/\bCharMap_Mode21\b/SndParam_ValueMap_R6P2_Inv/g
