# prom_a 0xFDFEE2-0xFDFFDE: stale handler copies, paired with their live twins (2026-10-03)

The bytes after the live handler `ExitKey_SoundEditFilterLfo` (its `ret` is at 0xFDFEE1) decode as more handlers of
the same shape -- `link XIZ,0 / cp (XIZ+8),0 / jr / pushw ... / call ... / unlk / ret` -- but:

- nothing references them: no label, and no 24-bit value in prom_a, prom_b or prom_c equals one of
  their entries (0xFDFEF7, 0xFDFF1B, 0xFDFF33, 0xFDFF4B, 0xFDFF63, 0xFDFFA3, 0xFDFFC7; the values that
  do occur inside the span, 0xFDFEFE-0xFDFF96, are mid-handler);
- their `call` operands land inside instructions (0xFD61E9, 0xFD6FEE, 0xFD763E), or on labels that no
  live code calls (`sub_FD6B3E`, `sub_FD40B6`; and `sub_FD5486`, whose only live reference was a
  `jr nz` from inside its own routine).

They are copies from older builds, with the call targets those builds had.

## How each old address is paired with a live routine

    python3 wsa1/notes/prom_a_stale_twins.py 0xFDFEE2 0xFDFFDF

takes each handler that starts with a `link` at an instruction start, and finds every other place in
prom_a with the same bytes except the `call` operands -- a live twin. Output on 2026-10-03:

| stale handler | old targets | live twins | live targets | delta (live - old) |
|---|---|---|---|---|
| 0xFDFEF7 | 0xFD61E9, 0xFD763E | 0xFDFE56 | PanelScreen_PostRequest, SoundEditLfo_CycleLfoState | -0x15E, -0x15E |
| 0xFDFF1B | 0xFD763E | 0xFDFE7A | SoundEditLfo_CycleLfoState | -0x15E |
| 0xFDFF33 | 0xFD763E | 0xFDFE92 | SoundEditLfo_CycleLfoState | -0x15E |
| 0xFDFF4B | 0xFD763E | 0xFDFEAA | SoundEditLfo_CycleLfoState | -0x15E |
| 0xFDFF63 | 0xFD6B3E, 0xFD61E9 | ten, from 0xFD13A1 to 0xFDFEC2 | ToneMsg_SendP23FromArr2800, PanelScreen_PostRequest | -0x15E, -0x15E |
| 0xFDFFA3 | 0xFD5486, 0xFD40B6 | 0xFD1FD7 | Var27A3_ChangeSlot, PanelScreen_PostRequest | +0x2028, +0x1FD5 |
| 0xFDFFC7 | 0xFD40B6 | seven, from 0xFD1010 to 0xFD5C4B | PanelScreen_PostRequest | +0x1FD5 |

So there are two layers. Up to 0xFDFF82, every old target is 0x15E above the live one, and the
twins are the live handlers just above the block. From 0xFDFF83, the old targets are 0x1FD5 and
0x2028 below: an older layout still.

Three calls sit in handlers the script cannot examine, because they are cut off at the front.
Each of them uses an old address that a twin-paired call also uses, or (one case) the layer's delta:

- 0xFDFEE9 calls 0xFD61E9, the same old address as 0xFDFF07.
- 0xFDFEF0 calls 0xFD6FEE. That handler has no twin; 0x15E below it is the entry `Var27A2_ToggleWithP23`.
- 0xFDFF8C calls 0xFD5486 and 0xFDFF9B calls 0xFD40B6, the same old addresses as 0xFDFFB0 and
  0xFDFFBF.

## In the source

Each of these 14 calls is written as the live routine plus or minus the delta, e.g.
`call PanelScreen_PostRequest + 0x15e`, with the pairing on a comment line above it.

Two labels are dropped: `sub_FD6B3E` (inside a routine, after a `jr ugt`) and `sub_FD40B6` (between
two `pushw`s). `sub_FD5486` becomes the local `.LFD5486`. Same bytes: `make gate-all`.

Two calls are left as numbers: `call 0xfdbd28` (0xFDFFE1) and the `jr z` after it. They belong to
the 33-byte fragment at 0xFDFFDF, whose only witnesses are prom_b's orphan cluster (anomaly N2 in
FINDINGS-prom_b-f00c4d-orphan-cluster.md). That cluster calls the same 0xFDBD28 and has no live twin.

⚠ **Checked and negative.** No constant offset maps the orphan cluster's 34 call targets onto prom_a
instruction starts, even over the wider -0x3000..+0x3000 range
(`python3 wsa1/notes/prom_b_orphan_cluster_offset_scan.py`). The best is 25 of 34, at -0x85D and at
-0x2D33. N2 searched -2048..+2048, and the two moves found here (+0x1FD5 and +0x2028) fall outside
that window, so the wider range was worth trying. It did not change the answer.
