# prom_a's boot block — 25 modules, five phases, a variant strap, and the screen
# that names prom_d

Written 2026-08-25, wave 5 round 3. Spans `0xF80000-0xF826A8` (9,897 bytes) and
`0xF827C8-0xF82CFE` (1,335 bytes), both converted in this round. Every number
below is re-derived from the ROM by `python3 notes/prom_a_boot_checks.py`
(90 checks). The byte gate proves the source rebuilds the ROM and is blind to
every sentence here.

---

## 1. ★★★ Emulation gap D — CLOSED, by a label the machine itself prints

Gap D asks for *"a byte-level tie between a specific prom_d structure and a
specific instruction"* (`notes/FINDINGS-memory-map.md` §5 says the same in as
many words: **"Still missing"**).

`VersionScreen_Show` (`0xF82A28`) is the routine the ROM-VERSION power-on chord
runs. It makes two remote reads over the inter-processor link, with the same
`(dst, count, src)` push order the remote-flash module uses:

| site | dst | count | src |
|---|---|---:|---|
| `0xF82A2F-0xF82A45` | RAM `0x2640` | 11 | remote `0x00FFFFF0` |
| `0xF82A56-0xF82A6C` | RAM `0x264C` | 11 | remote `0x00F7FFF0` |

It then draws a screen whose display list carries the ASCII labels **`ROM
VERSION`**, **`WSA-A:`**, **`WSA-C:`**, **`WSA-D:`** and `Software Group`, and
four 17-byte value records whose pointer pairs are:

| record | buffer | value pointer | y |
|---|---|---|---|
| `0xF82B6C` | `0x00002640` | `0x00FFFFF5` — prom_a's **own** tag + 5, read locally | `0x5E` |
| `0xF82B7D` | `0x00002640` | `0x00002645` — the `0xFFFFF0` buffer + 5 | `0x73` |
| `0xF82B8E` | `0x0000264C` | `0x00002651` — the `0xF7FFF0` buffer + 5 | `0x88` |
| `0xF82B9F` | `0x00002640` | `0x00FFFFF5` | `0x5E` |

and `0x5E`, `0x73`, `0x88` are the **same three y values** the `WSA-A:`,
`WSA-C:` and `WSA-D:` label records carry. So label and value are paired, in
order, by the ROM's own coordinates.

The last sixteen bytes of the four images in hand:

```
prom_a  file 0x7FFF0  77 73 61 61 5f 38 32 32 02 73 73 66 00 00 00 00   "wsaa_822\x02ssf"
prom_c  file 0x7FFF0  77 73 61 63 5f 32 33 30 02 73 73 66 00 00 00 00   "wsac_230\x02ssf"
prom_d  file 0x7FFF0  77 73 61 64 5f 35 34 2e 73 73 66 00 00 00 00 00   "wsad_54.ssf"
prom_b  file 0x7FFF0  1d 78 2a f4 1e 8f 00 0e 0e 0e 0e c8 33 07 66 19   (code — no tag)
```

`+5` is exactly the offset of the version digits in a `wsaX_NNN` tag. prom_b,
the one image with no tag, is also the one image the screen has no label for.

**And the tie is not just a string match — the firmware carries a special case
shaped for prom_d's tag and no other.** `0xF82A93` is
`9C 15 3F 73 66` = `cp (XIX+0x15),0x6673` with `XIX = 0x2640`, i.e. it tests
bytes +9/+10 of the **second** buffer for the ASCII `"sf"`:

* `wsad_54.ssf`[9:11] == `"sf"` — matches;
* `wsac_230\x02ss`[9:11] == `"ss"` — does not.

On a match, `0xF82A9A-0xF82AA3` shifts the version field right by one byte and
writes a space into the gap — the compensation an 11-character tag needs against
a 12-character one. A firmware that did not expect prom_d's exact tag could not
contain that branch. The same test is applied to the *first* buffer at
`0xF82A82`, and to prom_a's own tag locally at `0xF82AC7`
(`D2 FA FF FF 3F 73 66` = `cp (0xFFFFFA),0x6673`, and prom_a's `0xFFFFFA` is
indeed `"sf"`).

**What this establishes.** The image CPU 2 answers for remote
`0x00F7FFF0-0x00F7FFFF` ends in `wsad_54.ssf`, and the firmware displays it under
the label `WSA-D:`. prom_d's last sixteen bytes are exactly those bytes. So
**prom_d is the image at CPU 2 `0x00F00000-0x00F7FFFF`**, and the base follows
from the tag's file offset `0x7FFF0`.

**⚠ What this REFUTES, and what it leaves open.**

* `notes/FINDINGS-memory-map.md` §5 is titled *"prom_d — strongly supported as
  the **0xE80000** flash image"*. That base cannot be right as stated: prom_a's
  tone-data reads use remote banks `0xE8`-`0xEC`, and prom_d's tag lives
  `0x80000` **above** `0xE80000`. Either prom_d is a different part from the
  tone flash, or the two windows are two halves of one larger part with prom_d
  as the upper half — this evidence does not choose between them, and neither
  reading is asserted here.
* §6's line *"CPU 2 … `0xF00000-0xF7FFFF` — nothing referenced"* is also now
  wrong: nothing in **prom_c** references it, but CPU 1 reads it over the link
  from `0xF82A5F`.
* The 44-entry offset header and 274-entry pointer directory gap D also asked
  about are still not indexed by any instruction. Nothing here changes
  `FINDINGS-prom_a-remote-flash.md` §4 on that point.

**Reproduce:** `python3 notes/prom_a_boot_checks.py` — section 7, eleven checks,
each sourced from a different place (the two `src` literals, the display-list
ASCII, the four records' pointers, the four images' tails, and the `+9 "sf"`
branch).

---

## 2. ★★ The machine boots by walking a 25-module directory, five times

`ModuleInitDirectory_F82641` is 26 LE32 words at `0xF82641-0xF826A8`: 25
addresses inside prom_b's directory `0xF40000-0xF44018`, then `0xFFFFFFFF`.
The walker is twelve instructions at `0xF82846-0xF8286F`:

```
        XHL = 0x00F82641
loop:   XIX = (XHL+)                  ; next directory entry
        if XIX == 0xFFFFFFFF: done
        XIX = (XIX)                   ; the module's PHASE VECTOR base
        if XIX == 0x0E0E0E0E: skip    ; four RET bytes = module absent
        XIX = XIX + WA                ; WA = the PHASE
        push XHL / push WA / call (XIX) / pop WA / pop XHL
```

Five entry points set `A` and fall into it: `0xF82832` (0x00), `0xF82836`
(0x04), `0xF8283A` (0x08), `0xF8283E` (0x0C), `0xF82842` (0x10). So the boot is
**five passes over the same 25 modules**, not one pass over 125 routines, and a
module publishes its five entry points as five consecutive 4-byte slots.

The first directory word is `0x00F40000`; `(0x00F40000)` is `0x00F82010`; and
`0xF82010` in this very block is six consecutive `jp` slots
(`0xF825D4, 0xF8262F, 0xF82628, 0xF8262F, 0xF8262F, 0xF8262F`). Six, not five —
the sixth is never reached by this walker and no other reader of it is known.

**Entry count 26** comes from the walker's own `cp XIX,0xFFFFFFFF`, and the run
holds exactly one `0xFFFFFFFF`. **Last-entry test:** `0xF82641 + 26*4 = 0xF826A9`,
which is where this `.incbin` ended and where the already-converted RESET tail
begins with `ld (0x6E),0x04`.

**Unknown:** what each phase *means*, and which module is which. The 25 are
recorded by address only; the phases are named `Phase0`..`Phase4` by their
offset and by nothing else.

Callers of the phase entry points found so far: `0xF827DD` (phase 0),
`0xF827FC` (phase 3), `0xF82630/34/38` (three one-line veneers for phases 0, 1
and 2), and `0xF82CB8` / `0xF82CCF` inside the backup-RAM checksum path.

---

## 3. ★★ The model-variant flag `(0x00C4)` comes from PORT B BIT 0

`Variant_SetFromPB0` (`0xF82882`) is five instructions:

```
F82882  21 01           ld A,0x01
F82884  f0 1f c8        bit 0,(PB)          ; PB = SFR 0x1F
F82887  6e 02           jr NZ,+2
F82889  21 02           ld A,0x02
F8288B  f0 c4 41        ld (0xC4),A
```

so `(0x00C4)` — the flag the emulator's model-variant survey went looking for,
and which gap C's adversarial re-check confirmed is *not* consulted anywhere in
the link block — is **1 when PB bit 0 reads HIGH and 2 when it reads LOW**, set
once, here, on the reset path.

That matters to the driver: MAME's unbound port read returns 0, so an emulated
machine takes the `(0xC4) == 2` branch of every test below without anyone having
decided that is the right variant.

---

## 4. ★★ The three power-on chords, both variants

Each test opens `cp (0x00C4),0x01` and then reads a different byte of the
panel's change-mask shadow (`0x2B20 + ((wire & 0x0F) | ((wire & 0x40) >> 2))`,
per the driver lane's gap E):

| chord | at | variant 1 | variant 2 |
|---|---|---|---|
| FACTORY CLEAR | `0xF828D9` | `(0x2B38) == 0x07` exactly | `(0x2B38) & 0x03 == 0x03` |
| ROM VERSION | `0xF8294C` | `(0x2B32) & 0x07 == 0x07` | `(0x2B30) & 0x70 == 0x70` |
| third chord | `0xF82A04` | `(0x2B3A) & 0xE0 == 0xE0` | `(0x2B33) & 0xE0 == 0xE0` |

> ⚠ The emulator's gap-O table lists the ROM-version variant-2 test as
> *"seg 0 bits 4-6 (`0xF8295F`)"*. The address is right; the byte is `(0x2B30)`
> and the mask is `0x70`. Recorded here from the ROM
> (`C1 30 2B 21 / CB CC 70 / CB CF 70`).

FACTORY CLEAR (`0xF828F4-0xF8293F`) then: zeroes `0x1FE0` words from `0x80`,
zeroes `0x20000` longs from `0x600000`, clears `(0x7FD2)`/`(0x7FD4)`, sets
`(0x7FC7) |= 0x18`, writes `0x5AA5` to `(0x7FCA)`, masks `(0x97)` and jumps to
`0xF826A9` — the RESET tail. That matches the driver lane's description of it
exactly, which is worth saying because it was written from the other side.

**And the whole path is gated on `cp (0x7FCA),0x5AA5` at `0xF828D1`** — the same
magic FACTORY CLEAR writes. So `0x5AA5` at `0x7FCA` is "the backup RAM has been
initialised", and a machine whose backup RAM does not hold it takes the other
arm.

---

## 5. ★ The expansion board identifies itself with the ASCII "WSA1 EXTBD"

`ExtBoard_Identify` (`0xF8288F`) reads **10 bytes from remote `0x00C00000`** into
RAM `0x2640` — `push 0x2640 / push 0x000A / push 0x00C00000 / call T_F40EF0`,
then `call T_F4123C` (`Link_WaitBlockDone`) — and compares them byte by byte
with `ExtBoardMagic_F828C7`, which is the ASCII `WSA1 EXTBD`. On a full match it
writes `0x5A` to `(0x00C5)`; otherwise `(0x00C5)` stays 0.

So `(0x00C5)` is the expansion-board-present flag and `0x00C00000` is the
board's window — the same base the two already-converted callers at `0xFC00AE`
and `0xFC0173` hand the packet builder.

The loop's own `ld C,0x0A` is where the count 10 comes from; the **last-entry
test** is that `0xF828C7 + 10 = 0xF828D1` is `cp (0x7FCA),0x5AA5`, which is a
`calr` target from `0xF827E5`. An 11-byte reading puts that call one byte inside
an instruction — it was the single offender
`notes/prom_a_linear_decode_check.py 0xF827C8 0xF82CFF --offenders` reported
before this block was declared.

---

## 6. ★ Gap C's caller count moves again: 21, not 15

This block adds **four** converted `call 0xF4123C` sites — `0xF828A8`,
`0xF82981`, `0xF82A45`, `0xF82A6C` — none of them a remote-flash read. The
sources they hand the packet builder are `0x00C00000` (the expansion board),
`0x00FFFFF0` twice and `0x00F7FFF0` (the two ROM tails).

The two UI blocks converted in the same round (§10) add two more — `0xF95322`
and `0xF9FAFC`, both immediately after `call 0xf40ef0`. So
`python3 notes/prom_a_converted_callers.py 0xF4123C` now lists **21** sites in
nine regions, and `--checks` is 16 for 16. Of the 22 candidates
`notes/prom_a_xref.py` reports, exactly **one** is still inside an `.incbin`:
`0xF98977`.

The sentence that survives is still the one from
`FINDINGS-prom_a-remote-flash.md` §4: the release path is on the **link block
transfer in general**, not on remote flash.

---

## 7. Five blink-argument tables, one idiom

`BlinkArgPtrs_F8024D` (5), `_F80754` (6), `_F80AAD` (7), `_F80E12` (7),
`_F81344` (3) — 28 LE32 entries in all, each an address in prom_b's display-list
region `0xF01800-0xF3E15B` or NULL. All five are read by the same shape:

```
bit 1,(0x2075) / jr Z,out          ; UI enabled?
cp (0x2267),0x0F / jr Z,out
xor XWA,XWA / ld A,(<var>) / sla 0x02,XWA
ld XIY,<table> / ld XIY,(XIY+WA)
push XIY / call T_F42E20           ; -> prom_b 0xF0E9CF Blink_Command
```

with `<var>` = `(0x0DE5)`, `(0x0DED)`, `(0x0DBC)`, `(0x0DDA)`, `(0x0C0F)` in that
order. `T_F42E20` is `Blink_Command`, which takes one pushed pointer
(`FINDINGS-prom_b-field-blink.md`).

**Entry counts** are read LE32 word by LE32 word until one is neither 0 nor an
address in `0xF00000-0xFFFFFF`. **Last-entry test:** in every one of the five the
first rejected word begins `1D 80 2E F4` (`call 0xF42E80`) or `F1 40 25 00`
(`ld (0x2540),0x00`) — exactly where a linear decode resynchronises on real code.
`_F81344` has a **second, independent** last-entry test: `0xF81344 + 3*4 =
0xF81350`, and `0xF81350` is a `call` target from three converted sites
(`0xF810E8`, `0xF811C2`, `0xF811FA`). A four-entry reading puts all three calls
two bytes inside an instruction — and that was the three-offender row
`prom_a_linear_decode_check.py` reported for `0xF80000-0xF826A9`.

Two of the five (`_F80AAD` and `_F80E12`) have interior NULLs, so "count until
the first null" would have got both wrong.

**Unknown:** what the five variables select between.

---

## 8. ★ The LED nibble table is a formula

`LedNibblePatterns_F829F4` is 16 bytes, and

```
entry[n] == 0x80 | (bitreverse4(n) << 3)      for all sixteen n
```

— bit 7 is a constant marker and `n`'s four bits are emitted in reverse order
into bits 6,5,4,3. `notes/prom_a_boot_checks.py` computes the formula rather than
storing the table, so a single changed byte fails it.

It is read twice, with `C = (0xFFFFF8) & 0x0F` and `C = (0x2648) & 0x0F` — the
ninth byte of prom_a's own tag and of the tag read from remote `0x00FFFFF0`, i.e.
each ROM's revision nibble — and the byte goes to `T_F40678` with `W = 0` and
`W = 1`, two LED wires. On variant 2 it is first `srl 0x04,A`, moving the pattern
into the low nibble.

For **emulation gap O** this does not name a lamp, but it does give the panel
lane the exact bit ORDER the firmware expects on a wire, and it says the ROM
version chord lights wires 0 and 1.

**Entry count 16** from the readers' own `and C,0x0F`. **Last-entry test:**
`0xF829F4 + 16 = 0xF82A04`, which is `cp (0x00C4),0x01`, the first instruction of
the third chord test and a `calr` target from `0xF82813`.

---

## 9. What is still `sub_XXXXXX`, and why

**123** `sub_XXXXXX` labels in `0xF80000-0xF826A8` are the same family: test
`(0x2075)` bit 1, push a prom_b display-list address, call a `T_F417xx`/`T_F42Exx`
interpreter entry. They are `sub_XXXXXX` because nothing in prom_a says WHICH
screen — the strings are in prom_b's display lists, and tying a veneer to a
screen needs the display-list side, not this one. `CharSet_F81768` ('_' + A-Z +
0-9, 37 bytes) has **no located reader at all**; it is declared data because a
linear decode eats it and the byte sequence is unambiguous, and that is stated in
its header.

`VersionScreen_Glyphs` (`0xF82BB0-0xF82C7F`, 208 bytes) is pinned at both ends by
instructions — `0xF82BB0` is the third draw call's `end` operand and `0xF82C80`
is a `calr` target from `0xF827D5` — and both `0x00F82BB0` and `0x00F82C00`
appear as LE32 pointers **inside** the display list. The content is not decoded
and is not claimed.


---

## 10. The rest of the round: two UI screen blocks

`0xF92C62-0xF96017` (13,238 bytes) and `0xF99021-0xFA1403` (33,763 bytes) were
converted in the same round for the frontier, not for a gap, and
`notes/FINDINGS-prom_a-ui-screen-blocks.md` is their note. They are named here
only because they contribute the last two `Link_WaitBlockDone` call sites above.
