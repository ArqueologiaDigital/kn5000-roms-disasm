# v142 sub-CPU per-effect parameter metadata (subcpu_data_tables.s, 0x0133CF-0x014738), 2026-09-25.
# Evidence: the MAIN-CPU v10 effect-name table, 18-byte records at file offset 0x033568 - 18*n
# (the same table the DSP-zone banners cite), read directly:
#   n=15 "  ROCK ROTARY   "   n=53 " ROTARY SPEAKER "
#   n=57 "    STANDARD    "   n=58 "   PERCUSSIVE   "  n=59 "   SYMPHONIC    "  n=60 "   DEEP SPACE   "
#   n=79 "      GEQ       "   n=88 "  ROOM          "  n=89 " KARAOKE        "
#   n=90 "BATH ROOM       "   n=91 "  STAGE         "
# The ranges/defaults labels for 15 and 53 had the two rotary names SWAPPED (their header says
# the assignment "follows the panel effect-list order", i.e. it was a guess); 57-60/79/88-91 were
# "unidentified" / "name unknown".  Swap done through placeholders so neither rule sees the other.
s/\bEff15_RotarySpeaker_/@@EFF15@@_/g
s/\bEff53_RockRotary_/@@EFF53@@_/g
s/@@EFF15@@_/Eff15_RockRotary_/g
s/@@EFF53@@_/Eff53_RotarySpeaker_/g
s/\bEff57_Param/Eff57_Standard_Param/g
s/\bEff58_Param/Eff58_Percussive_Param/g
s/\bEff59_Param/Eff59_Symphonic_Param/g
s/\bEff60_Param/Eff60_DeepSpace_Param/g
s/\bEff79_SecondDsp_Param/Eff79_Geq_Param/g
s/\bEff88_SecondDsp_Param/Eff88_Room_Param/g
s/\bEff89_SecondDsp_Param/Eff89_Karaoke_Param/g
s/\bEff90_SecondDsp_Param/Eff90_BathRoom_Param/g
s/\bEff91_SecondDsp_Param/Eff91_Stage_Param/g
