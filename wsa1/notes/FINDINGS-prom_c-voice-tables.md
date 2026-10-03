# prom_c's data tables, and what the KN5000 sub-CPU can and cannot tell us about them

Scope: `prom_c` (IC28, CPU 2's boot ROM and sound engine), addresses `0xFDD2AB-0xFDF7DF` and
`0xFCC53F-0xFCD0F6`. Everything here is reproducible from
`notes/gen_prom_c_tables.py` (`--verify` / `--zone2`) and `notes/prom_c_kn5000_xref.py`.

## What is established

**12,525 bytes of prom_c are data tables with known boundaries**, laid out in two zones:

| zone | range | bytes | objects | sibling-backed |
|---|---|---:|---:|---:|
| 1 | `0xFDD2AB-0xFDF7DF` | 9,525 | 43 | 36 byte-identical |
| 2 | `0xFCC53F-0xFCD0F6` | 3,000 | 15 | 5 byte-identical |

The boundaries do not rest on one argument. Three independent things agree:

1. **Byte identity at the sibling's stated sizes.** 41 of the 58 objects are byte-identical,
   over their whole length, to a named table in the KN5000 sub-CPU payload, at exactly the size
   `../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s` states.
2. **The chain closes.** Zone 1's 43 tables laid end to end from `0xFDD2AB` reach `0xFDF7DF`
   exactly, with no gap and no overlap, and 94 bytes of zero fill follow. Zone 2's 15 objects
   likewise close on `0xFCD0F6`. One wrong size anywhere would desynchronise every table after
   it and the identity checks would collapse. They do not.
3. **prom_c's own code.** 39 of zone 1's 43 start addresses, and 9 of zone 2's 15, occur in
   this image as a literal 32-bit address operand — `add XBC,0x00FDD3AB`, `ld BC,(0xFDE695)`,
   `add XWA,0x00FCCD71`. That is the WSA1 firmware agreeing with the boundary, with no reference
   to the sibling project at all.

### ⚠ What that does NOT establish

Byte identity establishes that the **data** is the same. It does not establish that the WSA1
routine reading a table does what the KN5000 routine of that name does. Only three readers have
actually been disassembled here (below); every other name in `prom_c/wsa1_prom_c.s` is carried
over on byte identity alone and its header says so.

## The four findings worth keeping

### 1. The key-bend curves are the KN5000's, narrowed from 16 bits to 8

`0xFDD3AB` and `0xFDD42B` are 128-byte signed curves. Each is, **entry for entry, all 128 of
them**, the low byte of one of the KN5000's 128-entry *s16* tables:

| WSA1 | KN5000 | match |
|---|---|---|
| `0xFDD3AB` | `Voice_KeyBend_Type41_Table` (`subcpu_data_tables.s:966`) | 128/128 |
| `0xFDD42B` | `Voice_KeyBend_Type42_Table` (`subcpu_data_tables.s:989`) | 128/128 |

That is not reachable by chance: the KN5000 curves span −50…+168, so their low bytes only form a
smooth sequence if the underlying curve really is the same one.

The **stride** and the **signedness** come from prom_c's own code at `0xFA8016`:

```
    ld BC,DE / sra 0x08,BC          ; index = pitch accumulator >> 8
    exts XBC / add XBC,0x00FDD3AB   ; curve 0
    ld A,(XBC) / exts WA            ; SIGNED byte
    add DE,WA                       ; into the pitch accumulator
  ...
    add XBC,0x00000080              ; +0x80 -> curve 1 at 0xFDD42B
    add XBC,0x00FDD3AB
```

so the tables are 0x80 apart and read signed. Two more 128-byte curves follow at `0xFDD4AB` and
`0xFDD52B` with **no KN5000 counterpart at all** — same flat-bottom shape, but a non-smooth body
that reads like measured per-key tuning rather than a generated curve.

⚠ **Stated as observed, not explained.** The KN5000 curve rises to +168; eight bits cannot hold
that and prom_c sign-extends, so the top of the WSA1 curve reads back as −88 where the KN5000
reads +168. Whether the WSA1 never indexes that far, or this is a narrowing bug, is NOT
ESTABLISHED — it needs the caller of `0xFA8016` traced.

### 2. The WSA1 has TWELVE DSP algorithm types where the KN5000 has fourteen

`DSP_AlgoDescriptor_Records` at `0xFDF4F1` is 468 bytes = 12 × 39. Nothing was assumed: the run
that is byte-identical to the sibling ends **78 bytes early**, 78 = 2 × 39, and the next table
starts exactly there. The sibling records that its own types 12 and 13 are all-zero
(`subcpu_data_tables.s:2084`) — those are the two that are gone.

The same arithmetic shows up as an **alignment step** earlier in the zone: between
`Voice_KeyShiftRamp_Steps` and `Voice_CC_VolumeCurve` the WSA1-to-KN5000 offset moves by exactly
0x80, because the KN5000's 128-byte `Voice_AltNoteMap_Curve` has no counterpart in the WSA1
image. The WSA1 inserts its own 128-byte objects in two other places (a 0…100 compression ramp
at `0xFDF0A3`, an exponential 0x00…0x80 curve at `0xFDF760`) and a 20-byte u16 bit-mask array at
`0xFDE695`.

### 3. The touch curves are re-tuned, the table SELF-DESCRIBES, and (2026-08-24) the CONSUMER is now converted

★ **Update.** When this section was written, the touch tables' record layout rested on the
first column's arithmetic progression and on the sibling project. The routine that reads
them, `ToneGen_VelocityFromTouch` at `0xF995DF`, is now converted in
`prom_c/wsa1_prom_c.s`, and it settles every open question in this section from prom_c's own
instructions:

```
v  = ToneGen_Velocity_Input_Curve[touch]      ; 0xFCC61A, 256 bytes, non-increasing 255..0
v -= 77                                       ; the u16 at 0xFCC5C5
v += (signed) NoteTrim[note]                  ; a RAM table at 0x0084DA
v  = ModeParams[mode].gain * v / 128          ; the u16 at 0xFCC5C7
v += ModeParams[mode].pivot
if note is a BLACK key:  v -= ModeParams[mode].trim
v += (0x00F32B - 0x50)                        ; the offset control
clamp 0..255
out = ToneGen_Velocity_Output_Curve[v]        ; 0xFCC71A, non-decreasing 1..127
```

* **Record size 3 and row count 10** — `ld A,3 / mul WA,(0x00F32A)` gives the stride, and the
  setter at `0xF99598` refuses any mode above 9 before storing it. 10 x 3 = 30 bytes, the
  size the zone-2 chain already gave the table. Three independent facts, one answer.
* **The third column really is a BLACK-KEY trim.** The note number is divided by 12, the
  remainder minus one indexes a ten-entry jump table at `0xF996C3`, and the entries that
  apply the trim are exactly indices 0, 2, 5, 7, 9 — pitch classes 1, 3, 6, 8, 10, i.e.
  C#, D#, F#, G#, A#. Classes 0 and 11 fall out through the bound check instead, so the two
  white keys at the ends of the run are excluded by a *different* mechanism from the eight in
  the middle and both have to agree. The note is offset by 0x24 = 36 = three octaves before
  the remainder is taken, which does not disturb the pitch class.
* **Two of `unexplained_FCC5BE`'s bytes are no longer unexplained**: `0xFCC5C5` = 77 is the
  pivot subtrahend and `0xFCC5C7` = 128 is the divisor (in the source since 2026-10-03:
  `ToneGen_VelocityFromTouch_Data` and `ToneGen_VelocityFromTouch_Divisor`, two `.short`s). 77 occurs at exactly one index of the
  input curve (144), so the pivot is a single point, and at it the output is
  `ModeParams[mode].pivot` regardless of gain — which is what the "output level at the pivot"
  column *means*.
* **The offset control is centred**, and the RAM image proves it: `0x00F32B` is read as
  `value - 0x50` and its boot value is exactly `0x50`
  (`notes/FINDINGS-prom_c-ram-image.md`). The touch mode's default is 6, inside the 0..9 the
  setter enforces.
* **The output is a 7-bit velocity**: the output curve spans 1..127 over all 256 entries and
  never reaches 0 or 128.

~~⚠ Still open: what fills the signed per-note table at `0x0084DA`~~ **CLOSED 2026-08-25** —
`NoteTrim_BuildFromCalibration` (0xF997FA, now converted) is the only writer, and it derives
all 61 entries from a checksummed 62-byte calibration block through a 51-byte signed curve at
ROM `0xFCC5C9`. See `notes/FINDINGS-prom_c-keyboard-and-touch.md`. Still open: the physical
unit of the touch argument — "travel time" is inferred from the input curve running downward,
not read off a register.

### 3a. The original observation, unchanged

`ToneGen_VelCurve_ModeParams` at `0xFCC5FC` is 10 records × 3 bytes
`{gain/128, output level at the pivot, black-key trim}`. Two things fix the shape without any
appeal to the sibling: the first column steps `0x00, 0x10, … 0x90`, so the record size and the
row count are readable off the data; and the address is referenced three times from
`0xF9962D / 0xF9966F / 0xF99698`.

The values differ from the KN5000's — the WSA1's pivot outputs are 208, 199, 190, 181, 171, 162,
153, 144, 134, 125 against the KN5000's 208, 199, 189, 180, 171, 161, 152, 143, 134, 130. Same
structure, different instrument.

### 4. Two mixer-gain curves, and the consumer proves their shape

`0xFCCB71` and `0xFCCD71` are each 128 × u32, strictly monotonic, and **both end exactly on
`0x7FFFFF00` = digital full scale**. The routine at `0xFA30B8` reads both, four instructions
apart, with `ld WA,0x0004 / muls XWA,index / add XWA,base / ld XWA,(XWA)` — proving the element
size — and applies `sra 0x0f` to one of them, which is exactly the `>> 15` the sibling documents
for its byte-identical copy of the narrow curve (`subcpu_data_tables.s:2926`). The wide curve at
`0xFCCB71` matches none of the KN5000's five u32 ladders (best 32/512 bytes) and is WSA1-only.

`DSP_EQ_FreqHz_Table` (`0xFCCA82`) decodes as little-endian f32 into exactly the ISO
third-octave series 40, 50, 63 … 12500, 16000 Hz, and `DSP_EQ_Q_Table` (`0xFCCAEE`) into
0.1…0.9 by 0.1, 1.0…4.0 by 0.5, then 5…20 by 1. A wrong base or a wrong element size turns both
into denormal garbage, so the decode is its own proof.

## What was deliberately left as `.incbin`, and why

* **`0xFCC81A-0xFCCA81`, 616 bytes.** ⚠ **CORRECTION 2026-08-25: its first four bytes are NOT
  a float.** `0xFCC81A` holds `f0 ff 00 00` = the 32-bit constant `0x0000FFF0`, and the only
  three references to `0xFCC81A` in the image are the same instruction — `add XBC,(0xFCC81A)`
  at 0xF998AA, 0xF99910 and 0xF99930 — adding it to an index of 0..7. It is the base of the
  key-state bitmap at work DRAM `0x0000FFF0-0x0000FFF7`
  (`notes/FINDINGS-prom_c-keyboard-and-touch.md`). The remaining 612 bytes still look like an
  IEEE-754 constant pool — doubles are visible by eye
  (`00 00 00 00 00 00 4C 40` is 56.0) — but the element boundaries are not established:
  decoding it as f64 from the best-looking alignment yields round numbers for only 7 of 76
  candidates, so the pool is not uniformly 8-byte strided. The KN5000's pool of the same kind
  (`subcpu_data_tables.s:2695`) does not match, so the sibling cannot supply the stride either.
  Guessing one would produce a table of nonsense that the byte gate would happily accept.
* ~~**`0xFCD0F7` onward, the length-prefixed packet pool.**~~ **CONVERTED 2026-08-25 — and the
  "desynchronisation" was an error in the walk, not a property of the data.** The first byte is
  not the high half of a 16-bit length: its top nibble is an OPCODE and only its low nibble
  belongs to the length. Read that way the walk never desynchronises, and the whole 65,972-byte
  region tiles into 297 byte-code streams, 6 data tables and 4 directory objects with no gap and
  no overlap. See `notes/FINDINGS-prom_c-p7-byte-stream-pool.md` and
  `notes/gen_prom_c_p7stream_pool.py --verify`.
  ⚠ The old paragraph is kept here, struck through, because "framing CONFIRMED for the first
  four records" was true and still misled: four records are exactly as many as a wrong framing
  can get right when the opcode of all four happens to be zero.
* **Three bytes at `0xFCCB6E`** (`00 01 00`). The address is referenced three times so it is a
  real object, but three bytes is too little to infer a shape from.

## Where zone 2 came from (2026-08-24)

The first 131 bytes of zone 2 — `Handler_PtrTable_FCC53F`, `unexplained_FCC55F`,
`Packet_PtrTable_FCC576` and the four leading zeros of `unexplained_FCC5BE` — are the TAIL OF
THE BOOT RAM IMAGE. `RESET` copies ROM `0xFCB4EA-0xFCC5C1` to RAM `0x00E2DF-0x00F3B6`
(`notes/FINDINGS-prom_c-ram-image.md`). That **explains** the "⚠ NOT ESTABLISHED: nothing in
prom_c references 0xFCC53F as a literal" flag in the zone-2 headers: nothing reads those
objects in place, because they are used from their RAM copies at `0x00F334`, `0x00F354`,
`0x00F36B` and `0x00F3B3` — two of which are demonstrably WRITTEN at runtime, which a ROM
table cannot be. The names have been left alone; the mechanism has been recorded.

## What the next pass needs

* Trace the caller of `0xFA8016` and find out how a voice selects among the four key-bend curves
  — that also settles the sign-extension question above.
* The descriptor-string pool at `0xFCCF71` (44 NUL-terminated strings over `{b,w,v,s,h,c,B}`
  paired with digit strings) is loaded in pairs by the record table at `0xFDBFE9`. Decoding one
  record by hand would name the whole structure. `b`/`w` as byte/word is the obvious reading;
  nothing yet proves it.
* ~~`0x00F2F3` is read as a 32-bit value on every serial interrupt. Finding what writes it
  would name it.~~ **DONE 2026-08-24**: it is incremented by `INTT1_HANDLER` and by nothing
  else — a timer-1 tick counter. See `notes/FINDINGS-prom_c-serial-midi.md`.
* ~~New, from the touch-path conversion: find what writes the signed per-note table at
  `0x0084DA`.~~ **DONE 2026-08-25.** `NoteTrim_BuildFromCalibration` at `0xF997FA`, called once
  from MAIN's boot chain, writes all 61 entries as
  `trim[n] = ToneGen_VelCurve_Trim51[clamp(cal[n] - 0x4B, 0, 50)]` — the 51-byte signed
  table this zone already names — and `cal[]` is a checksummed 62-byte block validated by the
  magic `0x5AA5`. The clamp's bound 0x32 gives 51 entries, confirming from the CODE the size
  the object chain gave from the DATA. Full derivation in `notes/FINDINGS-prom_c-keyboard-and-touch.md`.
* ~~`0xF997FA`, `0xF9997E`, `0xF98510`, `0xF98A75` and `0xF98CB9` are the unconverted routines
  `MAIN` calls every pass.~~ **PARTLY DONE 2026-08-25**: `0xF997FA` and `0xF9997E` are
  converted. `0xF9997E` is `Link_SendBlock` — it splits a buffer into 32-byte packets and
  hands each to `Link_SendChunk`, which builds the header byte
  `(channel << 5) | (len - 1)` by hand and moves the payload with micro-DMA channel 2. See
  `notes/FINDINGS-prom_c-link-transmit.md`. Still unconverted: `0xF98510`, `0xF98A75`,
  `0xF98CB9` (the last of which is what calls the key scanner, twice).
