# Wave 23 tool — lane `w23/reso-scale`

One script, and the two questions it answers. It reads
`original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}`, and opens the `.s`
listings for exactly one thing — the set of instruction START ADDRESSES and their
canonical spellings, which the converters gate on a byte-identical round trip, so
that a byte-level census can say whether a hit lies in code or in a region this
tree frames as data. Run it from the `wsa1/` directory. Findings:
`notes/FINDINGS-l7a1429-reso-scale.md`.

| script | the questions it answers | command |
|---|---|---|
| `notes/w23_reso_scale_and_group_chain.py` | **(1)** *What does the tone editor's `RESO SCALE` (bit 7 of wave-select bytes `+0x16`/`+0x20`) actually do to the L7A1429?* It finds the two instructions in the whole of prom_c that can see that bit, shows they select the delta term of registers `chan+0x0040` and `chan+0x0080`, and identifies every term of both arms at the instruction that writes it. **(2)** *How do the editor's `GROUP` bits (p11 bits 7:6) reach register `chan+0x0000` bits 6:4, which gate `chan+0x0300`?* It walks the eight hops from `ToneMsg_Dispatch`'s write arm 4 to the gate mask, asserting each. It also shows that the previously published route for `RESO SCALE` — "it reaches `R[+0x1A]`" — cannot be right, because all nine writers of that field clear bit 7 first. | `python3 notes/w23_reso_scale_and_group_chain.py` · `--selftest` · `--census` |

**What a pass means.** Every claim is asserted twice over where it matters: by the
CANONICAL SPELLING at an address (a fact about the bytes, since the listing is a
byte-identical round trip) and by an IMMEDIATE decoded straight out of the raw ROM
(a stride, a mask, a base address — no listing involved). `--selftest` currently
reports `FAILURES: 0`. `--census` prints every row of the two byte-level censuses
instead of just their counts.

**The four nulls, printed inline.**

* **NULL 1** — the MAIN and SUB readers are one piece of code written twice: two
  63-byte spans differing in **exactly one byte**, the displacement. Over all
  512 KB of prom_c there is exactly **one** other 63-byte window within four bytes
  of the first, and it is the second.
* **NULL 2 / NULL 3** — the addressing in the `GROUP` chain is a tiling, not a
  coincidence: `0xD9 + 4*81 == 0x21D`, `0x21D + 4*43 == 713`, `0x88 + 4*41 == 300`.
  A wrong stride closes none of them.
* **NULL 4** — is "test bit 7 of a wave-select byte" special? Over prom_c the shape
  `ld r,(Xrr+d8)` / `and r,0x80` occurs at 39 sites; restricted to the sites whose
  base is the wave-select record it lands on **eight** of the 43 bytes, and six of
  those eight are the six two-state controls the editor draws out of a wave-select
  bit 7 — six of six in both directions. None of the 35 value fields is read that
  way.

**The 122 census rows are partitioned mechanically**, not waved past: every hit is
classified as a store/read-modify-write or as a byte / word / long / unsized READ,
and every READ is checked for a bit-7 mask in its own spelling or in the next three
instructions. Twenty-four qualify; twenty are the two that test the bit and the
eighteen that clear it, three more take their base from the routine's own frame
pointer, and the last is a raw-byte `bit 7,(XIX+0x16)` on the 23-byte slot record.

**The negative, and the forms it searched.** Section 3 prints the list of forms
before it states any negative: a literal displacement, a base spilled to a frame
and reloaded, a base held across a call, a base advanced past the field, an
absolute store, a block move, an address minus an index, a pointer stored in
another table, and raw-byte `extpfx*` pseudo-instructions whose operands are not
modelled. The absolute form is **run**, not asserted: the eight staged byte
addresses are scanned for as LE16/LE24 literals over the whole image and the one
hit is adjudicated to a data table.

No `.s` file is edited by this lane, so neither source gate applies.
