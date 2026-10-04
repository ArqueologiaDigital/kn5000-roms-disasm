# prom_b: the panel event being handled -- `PanelEvent_Flags` (0x28B0) and `PanelEvent_ButtonCode` (0x28B1) (2026-10-03)

The evidence is prom_b's `PanelCode_ToSlotAndFlags` (0xF55019), whose header (round 11,
`notes/prom_b_panel_names_round11.py --selftest`) already establishes what each flag bit says. This
note names the two bytes and re-checks every operand:

    python3 wsa1/notes/prom_ab_ram_operand_shapes.py 0x28b0 0x28b1 --sites

## The two bytes

`PanelCode_ToSlotAndFlags(code, flags)` runs once per panel event, at the far end of the panel
chain:

- It stores the 5-bit panel button code (the five bits `PanelButton_Route` masks out) into (0x28B1).
- It rebuilds (0x28B0) from zero:
  - bit 0 = the pair position, i.e. bit 7 of the code byte: which key of a two-key pair moved;
  - bit 1 = the code is in the 32-bit set at (0x208C), tested through `Bit32MaskTable`;
  - bit 2 = codes 0x11-0x19, the event the action handlers 0xF8AE68 / 0xF8AEDB rewrote with
    `add (XIX-1),0x11`;
  - bit 5 = number-pad code 0x1B with (0x2267) == 0x0F.

The slot it returns is the code folded down. The button handlers it dispatches to read the flags
back:

| use of (0x28B0) | count | where |
|---|---|---|
| bit 0 test: `and C/A/W,0x01` | 107 | 99 + 7 + 1: the LcdKeyRow / SoftKeyCol / *_Adjust* key handlers, PanelFlags_PairBitAsWord |
| `lda XIX,(0x28B0)` | 11 | handlers that then test and clear bit 0 through (XIX) |
| bit 2 test: `and C,0x04` | 10 | DspEffect_Step* and IndexedTable/IndexedParam helpers |
| `xor (0x28B0),C` / `xor (0x28B0),A` | 6 | IndexedParam_* and IndexedTable_*: XOR a descriptor byte into the flags |
| bits 3, 4, 5, 6, 7 tests | 3, 3, 1, 1, 1 | IndexedTable_GetByte_*, IndexedParam_* |
| `set 6` / `res 6` / `xor 0x01` | 1 / 1 / 1 | sub_FBD0EE, IndexedTable_GetByte_Join8, sub_FBF453_Nop |
| `ld H,(0x28B0)` (the test follows later) | 7 | T_F418C4_Nop, LcdKeyRow2_DspEffect, LcdKeyRow3_DspEffect, LcdKeyRow4_DspEffect |

The rows add up to the census total of 153.

(0x28B1) has 13 uses:

- 7 in `PanelCode_ToSlotAndFlags` itself: the store, `mul BC,(0x28B1)`, and the slot folding at
  0x11 / 0x19 / 0x1A / 0x1B;
- 4 `push (0x28B1)` in `SoftKeyCols2to7_CreatorSelectController` / `sub_F4C53A`;
- one `ld L,(0x28B1) / cp L,0x11` in prom_a.

⚠ **Not established:**

- **Bits 3, 4, 6 and 7.** `PanelCode_ToSlotAndFlags` always writes them 0. They come only from the
  descriptor bytes the `IndexedParam_*` helpers XOR in, so what they mean belongs to those
  descriptors.
- **Bit 2 in the DSP-effect steppers.** That the DspEffect_Step* routines test bit 2 means a
  rewritten code reaches them. What a rewritten code means for a step (direction or size) was not
  checked.
