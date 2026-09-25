# rename_accomp_screen_head.sed -- lane accomp, 2026-09-25.
# The three routines at AccScreen_UIDataBlock +0x00/+0x11/+0x1A (v9/v10
# 0xF6A9D7/0xF6A9E8/0xF6A9F1) had structural names from the branch symboliser.
#   +0x11: ld c,7 / ld a,12 / call Display_DeferOrUpdateScreen / ret
#   +0x1A: W = index of the lowest set bit of ((0x379b) & 31) (0 if none),
#          stored to (0x39b8) -- the id of accomp_display_full's first widget.
# Run on v10/ and v9/ maincpu/sequencer/accompaniment_engine.s only (every
# reference is in that file; checked with `command grep -rn`).
s/\bAccDraw_Secondary_Helper13\b/AccScreen_RefreshScreen/g
s/\bAccDraw_Secondary_Helper14\b/AccScreen_SelectorToWidgetIndex/g
# the symboliser's internal labels of the +0x1A routine
s/\bAccDraw_Secondary_Helper14_Join\b/AccScreen_SelectorToWidgetIndex_Loop/g
s/\bAccDraw_Secondary_Helper14_Skip\b/AccScreen_SelectorToWidgetIndex_Store/g
