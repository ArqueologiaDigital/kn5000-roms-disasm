# Sub-CPU v1.42, 2026-09-25 (lane subcpu).  Nothing here touches an interrupt mask:
#  - IntMask_SetBit3 / IntMask_ClearBit3 set / clear bit 3 of T8RUN (SFR 0x80) = timer 3's run bit
#    (done by hand in the same commit, with a header: Timer3_Start / Timer3_Stop);
#  - IntMask_Clear_Loop / _Body zero four words at 0x292E and four at 0x2936 at the end of the
#    routine that returns through AudioState_Init_Return.
s/\bIntMask_Clear_Loop\b/AudioState_Init_ClearWords_Loop/g
s/\bIntMask_Clear_Body\b/AudioState_Init_ClearWords_Body/g
