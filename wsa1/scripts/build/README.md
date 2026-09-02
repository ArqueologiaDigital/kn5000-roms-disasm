# `wsa1/scripts/build/` -- image files as the source of truth

## `wsa1_bitmaps.py`

**Question it answers:** *which WSA1R ROM ranges are pixel data, at what
dimensions, on whose authority -- and can the assembly be regenerated from a PNG
byte for byte?*

```
python3 scripts/build/wsa1_bitmaps.py census    # re-derive every op-03 record from the ROMs
python3 scripts/build/wsa1_bitmaps.py list      # the manifest, with each entry's evidence
python3 scripts/build/wsa1_bitmaps.py probe     # 4-neighbour edge density, column- vs row-major
python3 scripts/build/wsa1_bitmaps.py export    # ROM  -> PNG            (run once)
python3 scripts/build/wsa1_bitmaps.py verify    # PNG  -> bytes == ROM
python3 scripts/build/wsa1_bitmaps.py check     # PNG  -> assert the .s already says this
python3 scripts/build/wsa1_bitmaps.py rewrite   # PNG  -> patch the .s `.byte` values
```

`check` is the build-time one: it re-derives every `.byte` value of every listed
range from the committed PNG and asserts the assembly already holds exactly
those bytes.  Edit a PNG, run `rewrite`, and the assembly follows; the byte gate
(`make gate-wsa1`) then says whether the ROM still rebuilds.

**The signal being read, so the numbers keep their meaning:**

| what | where it comes from | what a pass means |
|---|---|---|
| `BC` = columns, `HL` = bytes down each column | the op-`0x03` display-list record's `+8` / `+0x0A` fields, or converted code that sets `ld BC` / `ld HL` literally before `ldb A,0x03 / swi 7` | the geometry is the firmware's, not this tree's |
| width = `BC * 8`, height = `HL`, pixel (x,y) = bit `7-x%8` of byte `(x//8)*HL + y` | `LCD_Svc_03_BlitColumns` (prom_a `0xF8EDB4`): `CSRDIR DOWN`, `HL` consecutive bytes per column, `inc 1,WA` between columns | the layout is column-major, always |
| the calibration | 0xFFCB00 read that way renders the word `Technics`; 0xFF8000 OR 0xFFA580 renders the `WSA` logotype | a wrong reading does not produce legible type |
| the null | the `03 0C` + plausible-fields test, run for 80 random two-byte opcode pairs over all four images: **0** plausible records, mean 0.00, max 0 | the record census has no measured false-positive floor |

PNG convention: 1-bit PNG, ink = **black** (0), background = white (255).

`census` and `check` both exit non-zero on drift and are safe to run in CI.
