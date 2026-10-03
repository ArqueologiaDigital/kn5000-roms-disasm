# prom_a: the per-controller part masks and the sequencer-event shadows (2026-10-03)

From round-1 pack prom_a-s08 (read and applied 2026-10-03), re-checked against the code.

## 1. The part masks

`ParamMsg_ComputePartMasks` saves the eleven 32-bit masks at 0x60F280 to 0x60F2AC, clears them, and ORs
`BitMask32_Table[part]` into a controller's mask for every part whose second-half record has that
controller's receive bit set.  Each `ParamMsg_ResyncParts_<ctl>` then XORs the two to find the parts that
lost or gained the controller and re-sends it; the MidiIn_CtrlRec_* routines read the current mask.

| current | previous | controller (parameter message) |
|---|---|---|
| 0x60F280 `ParamMsg_PartMask_PitchBend` | 0x60F2AC `ParamMsg_PartMaskPrev_PitchBend` | B1 |
| 0x60F284 `ParamMsg_PartMask_Modulation` | 0x60F2B0 `ParamMsg_PartMaskPrev_Modulation` | B2 CC01 |
| 0x60F288 `ParamMsg_PartMask_Modulation2` | 0x60F2B4 `ParamMsg_PartMaskPrev_Modulation2` | BC CC02 |
| 0x60F28C `ParamMsg_PartMask_ChannelPressure` | 0x60F2B8 `ParamMsg_PartMaskPrev_ChannelPressure` | B4 |
| 0x60F290 `ParamMsg_PartMask_CtrlPedal` | 0x60F2BC `ParamMsg_PartMaskPrev_CtrlPedal` | BD CC04 |
| 0x60F294 `ParamMsg_PartMask_Hold` | 0x60F2C0 `ParamMsg_PartMaskPrev_Hold` | B5 CC40 |
| 0x60F298 `ParamMsg_PartMask_RTCreatX` | 0x60F2C4 `ParamMsg_PartMaskPrev_RTCreatX` | B8 CC10 |
| 0x60F29C `ParamMsg_PartMask_RTCreatY` | 0x60F2C8 `ParamMsg_PartMaskPrev_RTCreatY` | B9 CC11 |
| 0x60F2A0 `ParamMsg_PartMask_RTCtrlX` | 0x60F2CC `ParamMsg_PartMaskPrev_RTCtrlX` | BA CC12 |
| 0x60F2A4 `ParamMsg_PartMask_RTCtrlY` | 0x60F2D0 `ParamMsg_PartMaskPrev_RTCtrlY` | BB CC13 |
| 0x60F2A8 `ParamMsg_PartMask_Expression` | 0x60F2D4 `ParamMsg_PartMaskPrev_Expression` | B3 CC0B |

## 2. The sequencer-event shadows

`SeqEvt_FlushShadows` sweeps five 17-entry arrays (one entry per event slot): an entry with bit 7 set
holds a value a played-back sequencer event left for that slot; the sweep clears bit 7 and posts it.

The arrays are named `SeqEvt_<X>Shadow`, because the routines that fill them already carry
`SeqEvt_Shadow<X>`.  The first spelling tried reused the routine names; the assembler accepted
the duplicate silently and the jump table at 0xFAF16C took the RAM addresses (36 bytes off).
`scripts/tools/name_wsa1_ram.py` now refuses a name the sources already define.

| address | name | holds |
|---|---|---|
| 0x60F630 | `SeqEvt_PressureShadow` | channel pressure, flushed as 0xB4; bit 7 = pending (SeqEvt_ShadowChanPressure / _PostChanPressure) |
| 0x60F5B0 | `SeqEvt_ModulationShadow` | modulation, flushed as 0xB2; bit 7 = pending (SeqEvt_ShadowModulation / _PostModulation) |
| 0x60F5D0 | `SeqEvt_PitchBendShadow` | pitch bend, 16-bit per slot, flushed as 0xB1; bit 7 = pending (SeqEvt_ShadowPitchBend / _PostPitchBend) |
| 0x60F590 | `SeqEvt_ExpressionShadow` | expression, flushed as 0xB3; bit 7 = pending (SeqEvt_ShadowExpression) |
| 0x60F610 | `SeqEvt_VolumeShadow` | part volume, flushed as {part,3}; bit 7 = pending (SeqEvt_ShadowPartVolume / _PostPartVolume) |
