# prom_a's two UI screen blocks — 47,001 bytes, 22 pointer tables, and no device

Written 2026-08-25, wave 5 round 3. Spans `0xF92C62-0xF96017` (13,238 bytes) and
`0xF99021-0xFA1403` (33,763 bytes). Every number is re-derived from the ROM and
the source by `python3 notes/prom_a_uiblock_checks.py` (106 checks). The byte
gate proves the source rebuilds the ROM and is blind to all of it.

**These two spans answer no entry on the emulator's request list.** They were
taken because the frontier tool ranked them and because 47 KB inside an
`.incbin` keeps every tool in `notes/` blind to it. That is stated first rather
than last.

---

## 1. Why these two, and what the frontier did

`notes/prom_a_module_frontier.py` at the start of the round ranked 31 thunk runs
by contiguous unconverted extent. Five of the top twelve landed in
`0xF99021-0xFA1403` — `T_F41910-T_F419C4` (46 slots, 20,106 bytes, rank 1),
`T_F42670-T_F426BC` (20, rank 2), `T_F434C0-T_F434D4` (6, rank 6),
`T_F41640-T_F41768` (75, rank 9) and `T_F43400-T_F43420` (9, rank 12) — and two
more in `0xF92C62-0xF96017`: `T_F40144-T_F40174` (rank 17) and
`T_F400D0-T_F4013C` (rank 18).

After both spans landed, the run count is **31 → 22**: nine runs closed
outright, and rank 3 (`T_F41500-T_F415C8`) fell from 51 unconverted slots over
14,848 bytes to 22 over 8,280.

**The round's frontier delta, reconciled rather than remembered.**
`python3 notes/prom_a_round3_frontier_delta.py`:

```
                              slots targets     bytes
AFTER (live worktree)           224    219    226345
+ what round 3 retired          251    205     58233
= reconstructed round-2 end     475    424    284578
round-2 end, audit-verified     475    424    284578
```

All three reconcile exactly. The four ranges are `0xF80000-0xF826A9` (10
targets), `0xF827C8-0xF82CFF` (1), `0xF92C62-0xF96018` (62) and
`0xF99021-0xFA1404` (132) — 205 distinct targets, 251 slots, 58,233 bytes,
predicted and observed.

**Span boundaries are anchored by the directory, not by the decode.** Both
`0xF92C62` and `0xF99021` are prom_b directory targets, so the START of each
linear decode is pinned by something other than the decode itself — the caveat
`FINDINGS-prom_a-fcf000-module.md` §3 raises. Both ends are instruction
boundaries of a decode that runs past them.

`python3 notes/prom_a_linear_decode_check.py <span> --offenders` on each:

| span | db bytes | directory slots | off-boundary | call→non-boundary, in-span | phantom |
|---|---:|---:|---:|---:|---:|
| `0xF92C62-0xF96018` | 80 | 62 | 0 | **0** | **0** |
| `0xF99021-0xFA1404` | 94 | 132 | 0 | **0** | **0** |

> ⚠ Both spans still print `VERDICT: NOT self-consistent`, and will always: the
> tool decodes linearly and has no notion of a `.byte` directive, so any span
> containing a declared table fails it by construction. The residue is the
> declared tables. Quote the verdict with that account attached — the same
> correction round-2 audit F12 forced on the `0xFB2000` span.

The eight `call/calr` from **outside** either span that name a non-boundary
inside it are all from sites that are not converted instructions anywhere in the
tree — checked in §4 below, which examines all 91,912 converted instructions.

---

## 2. ★ 22 pointer tables that a linear decode would have claimed as code

This is the failure mode the byte gate cannot see and the decode check does not
catch either: **nothing calls into a pointer table**, so a table produces 0
offenders and is emitted as ~30 lines of plausible-looking instructions. There
were 2,952 bytes of them across the two spans.

`notes/prom_a_ptr_tables.py` finds them by shape — runs of ≥ 6 consecutive
`lo mid hi 00` words whose value is in `0xF00000-0xFFFFFF` or 0 — scanned at
every byte offset, because these tables are not 4-aligned.

**The null control is the point.** `--null` runs the same detector over
`0xFB2000-0xFB8000`, 24 KiB of prom_a that is already converted **code**: at
MIN=6 it finds 5 runs / 208 bytes = **0.85 %**. `--checks` adds a negative
control (172 bytes of known code — `Link_ServiceTask` and `Link_WaitBlockDone` —
yields 0 runs) and two positive ones (it re-finds `ModuleInitDirectory_F82641`
and `BlinkArgPtrs_F80754`, both established by other means in the same round).

### 2a. The thirteen whose count comes from a reader's own bound

All thirteen share one reader shape:

```
ld BC,(<selector>) / extz BC / extz XBC
cp BC,<n-1> / jrl UGT,<default>
sll 0x02,BC / add XBC,<base> / ld XBC,(XBC) / jp T,XBC
```

| table | entries | bound | selector | last-entry test |
|---|---:|---|---|---|
| `JumpTable_F99F96` | 32 | `cp BC,0x1F` @`0xF99F82` | — | base+128 = `0xF9A016` = min entry |
| `JumpTable_F9A2A7` | 32 | `cp BC,0x1F` @`0xF9A293` | — | base+128 = `0xF9A327` = min entry |
| `JumpTable_F9A3C7` | 6 | `cp BC,5` @`0xF9A3B6` | `(0x2720)` | base+24 = `0xF9A3DF` = min entry |
| `JumpTable_F9A78E` | 32 | `cp BC,0x1F` @`0xF9A77A` | — | base+128 = `0xF9A80E` = min entry |
| `JumpTable_F9AA89` | 32 | `cp BC,0x1F` @`0xF9AA75` | — | base+128 = `0xF9AB09` = min entry |
| `JumpTable_F9AB84` | 8 | `cp BC,7` @`0xF9AB72` | `(0x2720)` | base+32 = `0xF9ABA4` = min entry |
| `JumpTable_F9B098` | 32 | `cp BC,0x1F` @`0xF9B084` | — | base+128 = `0xF9B118` = min entry |
| `JumpTable_F9D966` | 8 | `cp BC,7` @`0xF9D954` | `(0x269A)` | base+32 = `0xF9D986` = min entry |
| `JumpTable_F9DBE6` | 8 | `cp BC,7` @`0xF9DBD4` | `(0x269A)` | base+32 = `0xF9DC06` = min entry |
| `JumpTable_F9EC58` | 7 | `cp BC,6` @`0xF9EC47` | `(0x26A5)` | base+28 = `0xF9EC74` = min entry |
| `JumpTable_FA08BF` | 6 | `cp BC,5` @`0xFA08AD` | `(0x26A7)&7` | base+24 = `0xFA08D7` = min entry |
| `JumpTable_FA09BD` | 6 | `cp BC,5` | — | base+24 = `0xFA09D5` = min entry |
| `JumpTable_FA0B13` | 6 | `cp BC,5` | — | base+24 = `0xFA0B2B` = min entry |

**The last-entry test in every row is the same and it is strong: `base + 4*n` is
the MINIMUM value any entry holds — the table abuts its own first arm.** One
entry more or fewer moves that boundary and breaks the abutment. Asserted for
all thirteen (`1d`) rather than for a sample.

★ **Detector and bound agree in all thirteen.** Neither alone would be evidence;
the agreement is.

### 2b. The five whose count comes from the CALLEE's bound

`DisplayListPtrs_F92C66`, `_F93557`, `_F93839`, `_F9408E` are each named by a
`ld XIX,<base> / call T_F41B08`, and `DisplayListPtrs_F99870` by two
`ld XIX,<base> / ld E,(0x2740) / call T_F41B0C`.

`T_F41B08` → prom_a `0xF8BDC5` and `T_F41B0C` → prom_a `0xF8BDF8` — both already
converted, and **both open with the same two instructions,
`cp HL,0x001F / jr ugt`**. `0x1F` is the last index either lets through, so the
tables they are handed have **32 entries**. `DisplayListPtrs_F99870` is 96 words
= three such tables end to end, two of whose bases have a located reader
(`0xF99870`, `0xF998F0`); the third, `0xF99970`, has none, and the header says so.

### 2c. The four with neither, stated as the weaker claim

* **`PtrTable_F99121`** — 169 words, 676 bytes. One reader, at
  `0xF990F9`/`0xF99108`, and it indexes from `0x00F99321` = **entry 128**,
  reading a consecutive **pair** and handing `(start, end)` to `T_F42E04`. What
  indexes entries 0–127 is not established. Both ends are pinned by something
  other than the run: `0xF99120` is a `ret`, and the four bytes at `0xF993C5`
  are `0x0E0E0E0E`, the start of a 58-byte RET pad. ★ And its last three
  entries — `0xF993B9`, `0xF993BD`, `0xF993C1` — all hold `0x00F99121`, the
  run's own base. A table whose tail points at its own head is not a chance
  alignment of code bytes.
* **`PtrTable_F93444`** — 7 words. Two readers name it, and the selected entry
  is dereferenced as a **byte array** base (`ld XIY,(XIY+HL)` then
  `ld A,(XIY+HL)`), not as a branch target. The index comes from a `div`, so
  there is no compile-time bound; the count is the detector's.
* **`PtrTables_F95C95`** — 493 bytes holding **three** tables and one stray byte:
  32 entries at `0xF95C95` (bounded by `cp (XIZ+0x08),0x001F` at `0xF95896`),
  32 at `0xF95D15` (named at `0xF95A07`), one `0x00` at `0xF95D95`, then 59 at
  `0xF95D96` with no located reader. Emitted as `.byte`, not `.long`, **and
  that is the claim**: 493 is not a whole number of 32-bit words and the third
  table is offset by one byte from the second, so a `.long` rendering would have
  to invent an alignment the ROM does not have. Last-element test: the word at
  `0xF95E82` is `0x0E0E0E0E`.
* **`DisplayListPtrs_F99870`**'s third block, as above.

---

## 3. ★ The 0xF99021 block touches no device

Counting operands in the converted text of `0xF99021-0xFA1403`: the only address
anywhere in `0x600000-0x7FFFFF` is `0x60A000`, the RAM staging buffer. Asserted
(§3 of the checks) rather than eyeballed.

What it does instead is draw: `T_F42C78` ×61, `T_F42E04` ×43, `T_F42E00` ×43,
`T_F42E0C` ×38, `T_F42E84` ×32, `T_F42E08` ×28, `T_F42DC0` ×26, `T_F42E80` ×25.
`T_F42E00` → prom_b `0xF31800` and `T_F42E04` → `0xF31814` are the two
display-list draw entries of `FINDINGS-ui-display-list.md`.

So the block is UI screen code, its tables hold prom_b display-list addresses,
and **naming a routine here needs the display-list side, not this one**. Every
routine is `sub_XXXXXX`.

---

## 4. ★ A global cross-reference check, with a negative control

Section 4 of `prom_a_uiblock_checks.py` decodes the **bytes** on every
address-commented line in `prom_a/wsa1_prom_a.s` — 91,912 converted instructions
— and for every `call` (`0x1D`), `jp` (`0x1B`) and `calr` (`0x1E`) whose target
lands inside either new span, requires the target to be a converted instruction
or inside a declared table. **0 violations.**

A criterion that cannot fail is not a pass, so `4c` takes a real converted
address inside span A, adds 1, and requires the same comparison to reject it.

This is what settles the eight `call/calr` from outside the spans that
`prom_a_linear_decode_check.py` lists as unverifiable: every one of their sites
is inside an `.incbin` or is not an instruction, so none of them is a converted
instruction pointing at a non-boundary.

---

## 5. Two by-products for other lanes

* **Emulation gap C's caller count.** `0xF95322` (span B) and `0xF9FAFC`
  (span A) are two more converted `call 0xF4123C` sites, both immediately after
  `call 0xf40ef0`. Combined with the boot block's four, the count is now **21**,
  and only `0xF98977` of `prom_a_xref.py`'s 22 candidates is still `.incbin`.
  See `FINDINGS-prom_a-remote-flash.md` §4.
* **Emulation gap L's routine is now readable.** `T_F40144` → `0xF95137`, the
  service CHECKING DEVICE routine, is inside span B and converted. Its first
  three instructions are `ld C,(0x0D) / and C,0x10 / srl 0x04,C` — SFR `0x0D` is
  P5 — and `CheckingDevice_FlashLedNibble` opens `ld E,0x04` and drives P5 bit 3 with
  `stcf 0x03,(0x0D)` around a `ld HL,0x4000` delay. That is exactly what the
  service manual and the driver lane describe, now in the tree rather than
  inferred from it.
  ⚠ It does **not** answer gap L's open half. The reset path calls `T_F40144`
  unconditionally at `0xF827D1` and `0xF95137` gates only on P5 bit 4; no panel
  shadow byte is read anywhere before it. The manual's "hold `2` and power on"
  procedure is not a boot-time chord that this conversion can see.
* **Two more gap-O data.** `TestMode_SelectFromPowerOnKeys_Variant2` (span B, `0xF953D2`) reads panel shadow
  byte `(0x2B31)` and dispatches on `0x02`, `0x04`, `0x08`, `0x10` — four
  single bits of one segment, each with its own arm. `SineWaveCheck_ServiceSwitches` (span B,
  `0xF954AF`) reads `(0x2B33)`, masks it with `0x0F`, and dispatches on `0x01`,
  `0x02`, `0x04`, `0x08` with a fifth default arm.
  ★ **Exactly eight** references to `0x2B00-0x2BFF` exist in the whole of
  prom_a, and after this round all eight are converted: `0x2B38` twice and
  `0x2B32`, `0x2B30`, `0x2B3A`, `0x2B33` once each (the three power-on chords'
  variant pairs, §4 of the boot note), plus these two. `(0x2B33)` is therefore
  read from BOTH a power-on chord and a runtime dispatcher, which is a hint the
  panel lane can use: whatever segment it is carries both a service chord and a
  live four-way control. Asserted as a count in `prom_a_uiblock_checks.py`.
