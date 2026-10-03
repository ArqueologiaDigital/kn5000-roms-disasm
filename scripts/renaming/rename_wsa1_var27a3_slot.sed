# WSA1 prom_a 0xFD6B4D / 0xFD6C34 / 0xFD6C94 (prom_b imports by .set).  (0x27A3) is a 1..4 selector, (0x27A4)
# a mask whose bits 0/2/4/6 enable selectors 1..4; their meaning is not established, so the names follow the
# C-half accessor convention of the neighbours (Var27A4_Set, Arr27A6_Get).  sub_FD6C94 is value << count.
s/\bsub_FD6B4D\b/Var27A3_GetValidSlot/g
s/\bsub_FD6C34\b/Var27A4_SlotEnabled/g
s/\bsub_FD6C94\b/U8_ShiftLeft/g
s/\bsub_FD6CBA\b/U8_ShiftRight/g
