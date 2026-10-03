# accompaniment_engine.s: the two tables of AccDraw_Secondary_Sub (v10/v9 0xF6A489 / 0xF6A512,
# v7 0xF6A085 / 0xF6A10E), decoded as code until 2026-10-03.
s/\bAccScreen_DataBlock_Data\b/AccDraw_SecondarySub_Handlers/g
s/\bAccScreen_DataBlock_Code3\b/AccDraw_IndexBitMask/g
