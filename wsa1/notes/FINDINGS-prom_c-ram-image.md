# CPU 2 boots with a 4,312-byte RAM image, so its variables have known defaults

Scope: `prom_c` (IC28, CPU 2).  Everything here is reproducible from
`notes/prom_c_ram_image.py`, which re-reads the copy's three parameters out of the
instruction bytes and refuses to print anything if they are not what it expects.

## The claim

`RESET` calls `0xF989EF`, and that routine block-copies **4,312 bytes** from ROM
`0xFCB4EA-0xFCC5C1` to RAM `0x00E2DF-0x00F3B6`.  Every CPU-2 variable in that window —
which is most of the ones this tree has been arguing about — therefore has a
**power-on value that can be read straight out of the ROM**.

```
$ python3 notes/prom_c_ram_image.py
  0xF989EF  f2 ea b4 fc 35  OK    lda XIY,0xFCB4EA   (source)
  0xF989F4  f2 df e2 00 34  OK    lda XIX,0x00E2DF   (destination)
  0xF989F9  41 d8 10 00 00  OK    ld  XBC,0x000010D8 (count -> BC)
  0xF989FE  85 11           OK    ldir               ((XIY+) -> (XIX+))
```

**Direction and count, cited.**  MAME's `op_80` sets the LDIR *destination* pointer from
`opcode - 1` and the *source* from the opcode, so the `0x85` prefix means destination
`XIX`, source `XIY` (`mame/src/devices/cpu/tlcs900/900tbl.hxx:5435-5437`, and `op_LDIR`
at `:2495`, which counts down `BC`).  `ld XBC,0x000010D8` puts 0x10D8 in BC.

## ⚠ It corrects a comment that was already in the tree

`prom_c/wsa1_prom_c.s` described this call as *"copies a 0xD8-byte table from 0xFCB4EA to
0x00E2DF"*.  The count is **0x10D8, not 0xD8** — 4,312 bytes, not 216.  The listing has
been corrected in the same pass.  The same pass also corrected the neighbouring
`call 0xF99125`, which the RESET listing called *"a counted delay (loops to 0x40)"* and
which is really 64 write pairs into the device port at `0x108000`.

## What the defaults settle

| RAM | from ROM | boot value | why it matters |
|---|---|---|---|
| `0x00F32B` | `0xFCC536` | **0x50** | `ToneGen_VelocityFromTouch` reads this control as `value - 0x50`.  Its default being exactly 0x50 means the default contributes **zero**, which is what a centred control does and what a wrong reading of the subtraction would not produce.  This is independent corroboration of the touch formula, from data rather than from code. |
| `0x00F32A` | `0xFCC535` | 6 | the touch curve mode.  `ToneGen_SetVelCurveMode` rejects anything above 9; the default is inside that range, as it must be. |
| `0x00E2E4` | `0xFCB4EF` | 1 | the countdown that guards `sub_F9915C`.  Starting at **1** is why that routine's body runs exactly **once per power-up** — it decrements to zero on the first pass and every later call early-outs. |
| `0x00E2E3` | `0xFCB4EE` | 0 | the six-phase scheduler starts at phase 0. |
| `0x00F2F3` | `0xFCC4FE` | 0 | the INTT1 tick counter starts at zero, so `sub_F9915C`'s `>= 250` guard really is "250 ticks after reset" and not "250 ticks after something else". |
| `0x00F2F1` | `0xFCC4FC` | 100 | the main loop's countdown at `0xF98C40`. |
| `0x00F2F7` | `0xFCC502` | 0xFF | the INTES0 shadow.  `Serial0_Init` computes `(shadow & 0x88) | 0x55` from it, so the first value written to INTES0 is 0xDD. |

## ⚠ The copy's tail runs into the data zone, and that is not a mistake

The source ends at `0xFCC5C1`.  Zone 2 of the data tables starts at `0xFCC53F`, so the
last **131** bytes of the copy are the objects `prom_c/wsa1_prom_c.s` calls
`Handler_PtrTable_FCC53F`, `unexplained_FCC55F`, `Packet_PtrTable_FCC576` and the first
four bytes of `unexplained_FCC5BE`.  Their RAM copies land at `0x00F334`, `0x00F354`,
`0x00F36B` and `0x00F3B3`.

This **explains** something the zone-2 header flagged and could not account for: it says
*"nothing in prom_c references 0xFCC53F as a literal"* and treats that as a weakness in
the boundary.  Nothing references it because nothing reads it in place — it is used from
its RAM copy.

And the copy is not incidental overrun, because two of those RAM addresses are **written**
at runtime, which a ROM table cannot be:

```
0xFA561C  f2 54 f3 00 02 00 00   ld (0x00F354),0x0000
0xFA2DD4  f2 b3 f3 00 43         ld (0x00F3B3),C
```

So `Packet_PtrTable_FCC576` is a pointer table that is **relocated to RAM at boot and
patchable afterwards**, not a constant ROM table.  Its entries stay valid across the copy
because they hold ROM addresses (`0x00FCD119` and friends), which copying does not
disturb.

⚠ **Not resolved:** whether the four objects were meant as one initialiser blob or whether
the boundary between "RAM image" and "read-only tables" simply falls in the middle of
zone 2.  Nothing here decides that, and the zone-2 names have been left alone.

## What this does NOT establish

* Nothing about `0x000080-0x00E2DE` or `0x00F3B7-0x01007F`.  The copy does not reach
  them; `RESET` zeroes `0x000080` upward first, so those are zero unless written.
  In particular `0x007ED1` (the scheduler's work byte) and `0x0084DA` (the per-note touch
  trim table) are **outside** the image and get their contents from somewhere else.
* That any given variable still holds its default when first read.  The defaults are a
  starting point, not an invariant.

## Reproduce

```
python3 notes/prom_c_ram_image.py                    # the copy + the table above
python3 notes/prom_c_ram_image.py 0x00F334 0x00F36B  # any address you like, ADDR[:width]
```
