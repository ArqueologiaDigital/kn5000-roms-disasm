# prom_a 0xF89800 is the CONTINUOUS-CONTROL NORMALISER — emulation gap E.3, answered

**Established 2026-08-25** by converting prom_a `0xF89800-0xF89FFF` — 1,983
substantive bytes plus a 65-byte pad: a dispatcher, a 34-entry handler table,
ten handlers and **eight response-curve tables**.

`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap E asks three things. This
answers the third, which the note itself flags as the one that matters:

> What does prom_a `0xF89800` (reached through thunk `0xF405F0`) do with a
> received byte? Its carry result decides whether the byte is kept, and it is
> the module's only call out of itself.

and `notes/FINDINGS-prom_b-sc1-link.md` ends its open questions with *"What
would settle it: a caller of `T_F40F08` in prom_a whose surroundings are
identified, or `0xF89800`."*

Every number below is re-derived by **`python3 notes/prom_a_ctrl_checks.py`** —
125 named checks, all passing.

## What it does

One routine. It turns a **raw 8-bit reading of a continuous control** into a
**cooked value** through a per-channel response curve, remembers the cooked
value, and returns **carry set only when it changed**. That is why every caller
is `call T_F405F0` / `jr nc,skip`: the carry means *this control actually moved*.

```
W = channel selector          A = raw reading
index = ((W & 0xC0) >> 1) | ((W & 0x07) << 2)     ; bits 5-3 ignored
```

so bits 7-6 are a **group** and bits 2-0 a **channel**, and the index is a byte
offset into an LE32 table. Its maximum is `0x60 | 0x1C = 0x7C` — entry 31 — which
is what makes the table 32 reachable entries and why no bounds check is needed
or present. Two further entries at `0xF898A5` and `0xF898A9` lie beyond that and
are both the ignore handler.

Of the 32 reachable slots: **10 are live**, 1 is a bare `scf` ("always report
changed"), and **21** go to `Ctrl_ReportUnchanged`.

## The ten live slots

| slot | raw | curve | cooked | idle value when `(0xC4) == 2` |
|---|---|---|---|---|
| 0.0 | `0x24D0` | `0xF89BB4` | `0x2505` | `0x40` |
| 0.1 | `0x24D1` | `0xF89BB4` | `0x2506` | `0x40` |
| 0.2 | `0x24D2` | `0xF89EB4` | `0x24FF` | `0x00`, plus the `0x007F5A` calibration |
| 0.3 | `0x24D3` | `0xF89DB4` | `0x24F2` | `0x00`, and the raw byte is **inverted** first |
| 0.4 | `0x24D4` | `0xF89B34` | `0x2503` | — |
| 0.5 | `0x24D5` | `0xF89B34` | `0x2504` | — |
| 3.0 | `0x24E8` | `0xF89C34` | `0x24F5` | `0x00` |
| 3.1 | `0x24E9` | `0xF89CB4` | `0x24F4` | `0x80`, indexed by the **raw** byte |
| 3.2 | `0x24EA` | `0xF89B34` | `0x24F6` | `0x40` |
| 3.3 | `0x24EB` | `0xF89AB4` | `0x24F3` | — |

Every field in that table is parsed back out of the handler's own bytes by the
check script — the store, the compare, the `ld XIX,imm32` and the `ld A,#` of the
idle arm — so a changed literal fails instead of passing forever.

## Group 0 is the on-board analogue scan — proved by the call sites

`AnalogScan` (`0xF8DC00-0xF8DDE5`, converted in an earlier round) calls this slot
with `ldb w,#` immediately before and `jr nc` immediately after. There are
**eight** such sites and they pass `W = 0, 1, 2, 3, 4, 5, 4, 5`:

```
0xF8DC63 W=0   0xF8DC96 W=1   0xF8DCC9 W=2   0xF8DCFC W=3
0xF8DD54 W=4   0xF8DD69 W=5   0xF8DDC3 W=4   0xF8DDD8 W=5
```

Four of them come from `ADREG0`-`ADREG3`, two from `(0x600000)`/`(0x600001)`.
`notes/FINDINGS-prom_a-ring-buffers.md` already said "all six report through
directory slot `T_F405F0`"; this is the other end of that sentence, and it also
corrects the count: **eight sites, six channels**, because `0xF8DDBC-0xF8DDE5` is
**byte-identical** to `0xF8DD4D-0xF8DD76` — AnalogScan carries a duplicate scan
routine for channel 4 and another for channel 5. Recorded as measured (the two
21-byte runs compare equal); nothing here says why.

⚠ **What the six controls physically are is still not established.** The idle
values are suggestive — `0x40` for two of them, `0x00` for two more — and
suggestive is not evidence.

## Group 3 is four more controls of the same kind

Slots 3.0-3.3 have their own raw bank (`0x24E8-0x24EB`), their own cooked slots
and their own curves. **Who sends them is not established here.** What *is*
established: prom_b's SC1 receive decoder calls this same routine, twice, at
`0xF5B14C` and `0xF5B1D6`, with `W` taken from a **received byte**.

So the cross-note lead gap E flags —

> ★ One cross-note lead nobody has followed: the six analogue controls report
> through directory slot `T_F405F0` — **the same slot** the SC1 receive decoder
> calls out through. If it is one slot, the analogue controls and the SC1 peer
> are the same board.

— resolves to: **it is one slot, and the two sources share the entire normalising
path**: one dispatcher, one table of curves, one bank of cooked values, one
"did it move" convention. That is a strong statement about what the SC1 peer
*carries* — continuous controllers, normalised exactly like the on-board pots —
and it is **not** a statement that the two are on one board, because the ROM
keeps them in different groups and the group comes from a byte this note has not
decoded. `FINDINGS-prom_b-sc1-link.md`'s "shape of a scanner with a small return
channel" now has a second, independent piece: the scanner also carries at least
four continuous controls.

## The eight curves

They tile `0xF89AB4-0xF89FBE` with no gap:

| base | entries | indexed by | used by | note |
|---|---|---|---|---|
| `0xF89AB4` | 128 | `raw >> 1` | 3.3 | the identity map 0..127 |
| `0xF89B34` | 128 | `raw >> 1` | 0.4, 0.5, 3.2 | a compressed curve |
| `0xF89BB4` | 128 | `raw >> 1` | 0.0, 0.1 | the same curve, 40 bytes off by ±1 |
| `0xF89C34` | 128 | `raw >> 1` | 3.0 | **byte-identical** to `0xF89AB4` |
| `0xF89CB4` | 256 | the raw byte | 3.1 | 0..255 |
| `0xF89DB4` | 128 | `raw >> 1` | 0.3 | 0..127 |
| `0xF89E34` | 128 | — | **nothing** | see below |
| `0xF89EB4` | 256 | the raw byte | 0.2 | 0..255 |
| `0xF89FB4` | 11 | `(0x7F5F)` | 0.2 | the calibration span table |

* ⚠ **`0xF89E34` has no reference.** Censusing the little-endian immediate
  `0x00F89E34` over prom_a **and** prom_b finds zero sites, while the same census
  finds every other table here at exactly the instruction that uses it. It is a
  well-formed monotone 0..127 curve that nothing loads.
* `0xF89BB4` is `0xF89B34` with 40 of its 128 bytes changed by exactly **±1** —
  21 higher and 19 lower, all between indices 37 and 89, the other 88 equal. Two
  roundings of one curve, not two curves.
* ⚠ Both share a single **non-monotone** entry at index 20: `0x2C`, between
  neighbours `0x21` and `0x24`. Recorded as read; nothing here calls it a defect.
* ⚠ The span table's **11 entries** is the number of bytes before the module's
  `0x0E` pad, **not** a bound the ROM checks — the use site does not range-check
  `(0x7F5F)`.

## Slot 0.2 is the one calibrated channel

It reads a record at `0x007F5A`: `(+6)` is subtracted from the curve output with
a floor, and `(+5)` indexes the span table. The arithmetic, verbatim:

```
v = curve[raw]                        ; 0xF89EB4, 0..255
if v < (0x7F60) : v = (0x7F60)        ; floor
v = ((v - (0x7F60)) * 0x100 / 0xEC)   ; normalise against a fixed span
v = v * span[(0x7F5F)] / 0x14         ; scale by the calibrated span
if v > 0x7F : v = 0x7F                ; clamp to seven bits
```

The seven-bit clamp is the only place in the module where a value is forced into
a MIDI-shaped range. ⚠ What writes `0x007F5A` is not established here.

## What is NOT established

* what any of the ten controls physically is;
* what mode `(0xC4) == 2` is — six of the ten handlers take an idle-value arm
  under it and return carry clear;
* which group the SC1 decoder's bytes select;
* who reads the ten cooked values (`0x24F2`-`0x2506`);
* what writes the calibration record at `0x007F5A`.
