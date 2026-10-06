# prom_b's thunk table — the routine directory of CPU 1's 1 MiB image

**Where:** `0xF40000-0xF44017` (file `0x40000-0x44017`), 16,408 bytes.
**Status:** converted to assembly in `prom_b/wsa1_prom_b.s`. The gate
(`python3 scripts/analysis/assert_byte_identical.py`) re-checks every byte of it
on every build.
**Reproduce every number below:** `python3 scripts/analysis/prom_b_thunk_table.py --census`

## What it is

4,102 four-byte slots. Each slot is exactly one of three things, decided by
bytes alone:

| slot bytes | meaning | count |
|---|---|---:|
| `1B lo mid hi` | `jp nnn` — a thunk naming a routine entry point | 1,976 |
| `lo mid hi 00` | a 24-bit address in a 32-bit little-endian slot | 26 |
| `0E` / `00` fill | unused slot; `0E` is the one-byte `ret` | 2,100 |

`0x0E = RET` is cited, not assumed:
`mame/src/devices/cpu/tlcs900/dasm900.cpp:1267` puts `M_RET` at opcode `0x0E`.
`0x1B = JP nnn` and `0x1D = CALL nnn` were confirmed by round-tripping ROM bytes
through `llvm-mc -triple=tlcs900 -disassemble`.

## Why it is the most useful 16 KB in the image

Callers do not call routines, they call **slots**. Every `call nnn` in prom_a or
prom_b whose operand lands in `0xF40000-0xF44017` is a call through this
directory, and there are thousands. So this table is the index of "what routines
exist" in an image that is otherwise 1 MiB of undifferentiated bytes.

The 1,976 `jp` slots name **1,910 distinct routine entry points**:

* 1,255 slots (1,200 distinct) land in prom_a, `0xF80000-0xFFFFFF`
* 721 slots (710 distinct) land in prom_b itself

Spread over the 1 MiB image, by 64 KB bank:

```
0xF0:47  0xF1:21  0xF3:34  0xF4:160 0xF5:87  0xF6:130 0xF7:242 0xF8:259
0xF9:253 0xFA:119 0xFB:107 0xFC:201 0xFD:178 0xFE:91  0xFF:47
```

(No target in bank `0xF2`. ⚠ This used to add "that bank is display-list data";
corrected 2026-08-24 — the census measures thunk TARGETS, and bank `0xF2` also
holds **six of the ten character generators** the SWI7 text services load as
data by an immediate address, which no thunk census can see. See
`FINDINGS-ui-display-list.md` and `FINDINGS-fonts.md`.)

## The 26 pointer slots

They are not instructions; they are addresses. Counting how many thunk-shaped
slots follow each target answers what they point at, sharply:

* **23 of 26** are followed by **exactly six** thunk slots and then by something
  else — i.e. each names a 24-byte group of six thunks
* `0xF57C00` is followed by eight, `0xF53000` by three
* `0xFF75B6` by none: it is code (`jr T,+0x15`), not a table
  * ⚠ **Corrected 2026-10-06:** it is a table after all -- module 18's boot phase vector
    (`ModuleInitDirectory_F82641[18]` reaches it through this slot). Its six 4-byte slots are short
    code, `jr` / `ret` for phase 0 and `nop / nop / ret` after it, not `jp`, so the thunk-shape count saw
    none. prom_a now labels it `DiskScreens_PhaseVector` (`notes/prom_a_module18_phase_vector.py`).

Four point into prom_b (`0xF44000`, `0xF53000`, `0xF57C00`, `0xF5A800`), the
other 22 into prom_a.

⚠ **What reads these pointers has not been traced.** "A per-object vtable" is
the obvious guess for a six-thunk group and is *not* asserted here.

## The busiest slots

Ranking is by an **opcode-anchored upper bound**: prom_a and prom_b are scanned
at every byte offset for `1D lo mid hi` (call) and `1B lo mid hi` (jp) whose
operand is a 4-aligned address inside the table. Because the scan is not at
instruction boundaries, some hits are bytes inside another instruction or inside
data. The numbers rank slots; they are not exact call counts.

| slot | x | target | what it is |
|---|---:|---|---|
| `T_F417F0` | 392 | `0xF31A09` | **`DisplayList_Run`** — the UI engine. Converted. |
| `T_F417F4` | 269 | `0xF31AF0` | `DisplayListB_Run`, the second interpreter. Converted. |
| `T_F42E84` | 188 | prom_a `0xF8DA16` | enqueue one 32-bit word on the ring buffer at `0x600416` (write index `+0xFC`, free count `+0xFE`, `minc4 0x01FC` wrap ⇒ 128 slots, returns `0xFFFF` when fewer than 5 free, runs under `ei 6`) |
| `T_F42E80` | 141 | prom_a `0xF8DA83` | a fixed sequence of six calls through other slots with `A` = 4/2. Not identified. |
| `T_F42C90` | 119 | `0xF5533C` | **`IndexedTable_GetByte`** — byte *m* of pointer *n* of the table whose base is the 32-bit word at `0x60F018`. Converted. |
| `T_F41ED4` | 109 | `0xF5B9B8` | **`Dispatch_Code80`** — indexes a 48-entry table of routine pointers with a 16-bit selector ≥ 0x80. Converted. |
| `T_F42E0C` | 107 | `0xF3183D` | `DisplayListB_RunOne_Stack`. Converted. |
| `T_F42E04` | 104 | `0xF31814` | `DisplayListB_Run_Stack`. Converted. |
| `T_F42D88` | 98 | prom_a `0xF859AE` | `A` selects a 4-byte descriptor at `0x0338 + A*4` and a saturating byte counter at `0x035B + A`, under `ei 6`; an empty descriptor is self-referential. A kernel object operation — **which** one is not established. |
| `T_F42DC0` | 98 | prom_a `0xF859AB` | the same routine entered 3 bytes earlier, which first does `ld A,(XSP+4)` — the stack-argument form |
| `T_F42E24` | 85 | `0xF0E82B` | not identified |
| `T_EditValue_StepBitField` | 77 | `0xF550A6` | reads a bit-field through an 8-byte descriptor and range-checks it. Converted. |
| `T_F431B4` | 57 | `0xF7D006` | the third slot of an eight-entry `jrl` long-branch veneer table at `0xF7D000`, into prom_a `0xF81C15`. Not converted. |
| `T_F431B0` | 53 | `0xF7D000` | the first slot of that same veneer table, into prom_a `0xF81ACB` |
| `T_F42C8C` | 45 | `0xF55321` | **`IndexedTable_GetPtr`** — pointer *n* of the `0x60F018` table. Converted. |
| `T_F41ED0` | 39 | `0xF5B8B6` | **`Dispatch_Code80_Bracketed`** — the same 48-entry dispatch, with the call bracketed by `swi 7` functions `0x0C`/`0x10`. Converted. |
| `T_F42E00` | 85 | `0xF31800` | `DisplayList_Run_Stack`. Converted. |

### One slot worth naming separately

`T_F400A4` = `jp 0xF8E9A5` is the target of prom_a's **SWI7 vector**
(`0xFFFF1C` = `0x00F400A4`). `0xF8E9A5` masks `A` with `0x3F`, scales by 4 and
indexes a 64-entry table at prom_a `0xF8E9C6`. That is the machine's system-call
interface; see `FINDINGS-ui-display-list.md`.

`T_TableDefault_Ret` (`jp 0xF55018`) is never *called*, but its 4-byte address spelling
`70 2C F4 00` occurs **397 times** in prom_a+prom_b — 222 in prom_a, 175 in
prom_b. It is a **default entry that fills pointer tables**.

⚠ **CORRECTED 2026-08-25.** This sentence used to read "222 of them in one dense
run at prom_a `0x216B4`". That joined two different measurements by hand: **222
is prom_a's total**, and `0x216B4` is merely prom_a's *first* occurrence. The
occurrences are scattered, not one run.
`python3 notes/prom_b_default_slot_census.py` measures both quantities apart:

```
prom_a  222 occurrences, file 0x216B4..0x21E45
   longest stride-4 run: 10 entries, starting at file 0x21DED
   run starting at the first occurrence (0x216B4): 6 entries
prom_b  175 occurrences, file 0x131E4..0x542A0
   longest stride-4 run: 17 entries, starting at file 0x1B331
```

So it fills **many** table stretches, the longest of them 10 slots in prom_a and
17 in prom_b — never 222. The neighbourhood is genuinely a table of 32-bit ROM
pointers (`0x216A4` reads `0x00F9C3A5, 0x00F9C40D, 0x00F9C40D, 0x00F9C4BD` and
then six defaults), but ⚠ these tables are **not 4-aligned in the image**: only
67 of prom_a's 222 occurrences and 15 of prom_b's 175 sit at a 4-aligned offset.
Which tables these are has not been traced — but **what the entry does now is**:
prom_b `0xF55018` is a single byte `0x0E`, a bare `ret`. The default is a no-op,
and it sits at the tail of a run of `0E 00 00 00` four-byte slots
(`0xF55000-0xF55018`) that uses the same fill convention as this table.
Converted, with a header, in `prom_b/wsa1_prom_b.s`.

The same `0xF5BF17` idiom appears inside the two 48-entry dispatch tables:
a bare `ret` fills 6 of the first table's slots and 7 of the second's
(`python3 notes/prom_b_dispatch_tables.py`).

## What is NOT established

* Why the table is banked the way it is. Long runs share a target prefix and are
  separated by `ret` fill, which *looks* like one linker input file per run. Not
  asserted.
* What the three `0x00`-filled stretches meant to the tool that emitted them.
* What any individual routine does, beyond the handful named above.

---

## ⚠ THE `T_<address>` CONVENTION IS NO LONGER UNIVERSAL (wave 7 round 6)

This document describes every directory slot as `T_<address>`. **277 of the 2,002 slots now carry
`T_<TargetName>` instead** — `T_F42E0C` is `T_DisplayListB_RunOne_Stack`. Each renamed line keeps
`; F42E0C (was T_F42E0C)` in its comment, so a grep for the old spelling or for the slot address
still finds it, and prom_a's 206 cross-references were rewritten to `NewName (T_OldName)` for the
same reason: the slot NUMBER is what the directory is indexed by and must not disappear.

★ **A slot is a POINTER, so the rename is DERIVATIVE** — it repeats on the pointer a name another
lane earned on the target. It makes the directory readable; it is not 277 new facts.

★★ **And the census that came with it is the more useful result: 1,672 of the 2,002 slots (83.5 %)
point at something nobody has named.**

| where the slot points | count |
|---|---:|
| a `sub_XXXXXX` routine | 1,438 |
| an address the `.s` disassembles but never labelled | **115** |
| into a span still `.incbin` | 119 |
| a named target (these are the 277 renamed) | 277 |
| alias pairs and other refusals | 53 |

So the directory is not 2,002 pieces of missing documentation — it is a faithful **index of 1,672
pieces of missing documentation that live elsewhere**. The **115** are the actionable ones: entry
points the machine's own directory says exist, sitting in already-converted code with no label at
all. `python3 notes/prom_b_thunks_round6.py --unnamed` lists them.

Three relaxations were measured and **rejected**, and `--rejected` re-measures all three so a later
round does not re-invent them:

* take the name from a `sub_XXXXXX` target (+1,435 slots) — rejected: it would launder an unnamed
  routine into a named-looking pointer, and the stripped form re-grades framed anyway, so the
  number it buys is exactly the remaining-work number.
* take it from a **framed** target (+9) — rejected: changes 0 of 9 grades, pure churn.
* suffix the six alias pairs (12 slots) — rejected: it would have to invent which of two slots
  sharing one target address is primary.
