# accompaniment_engine.s: AccAutoPlay_ModeAvail_Process reads byte [(0xFD02) & 3] here; it is data,
# not code (v10/v9 0xF5AACD, v7 0xF5A6C9).
s/\bAccAutoPlay_ModeAvail_Extended_Code\b/AccAutoPlay_ModeAvail_Values/g
