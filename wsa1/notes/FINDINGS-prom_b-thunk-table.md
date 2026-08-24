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

(No target in bank `0xF2` — that bank is display-list data, see
`FINDINGS-ui-display-list.md`.)

## The 26 pointer slots

They are not instructions; they are addresses. Counting how many thunk-shaped
slots follow each target answers what they point at, sharply:

* **23 of 26** are followed by **exactly six** thunk slots and then by something
  else — i.e. each names a 24-byte group of six thunks
* `0xF57C00` is followed by eight, `0xF53000` by three
* `0xFF75B6` by none: it is code (`jr T,+0x15`), not a table

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
| `T_F42C90` | 119 | `0xF5533C` | not identified |
| `T_F41ED4` | 109 | `0xF5B9B8` | not identified |
| `T_F42E0C` | 107 | `0xF3183D` | `DisplayListB_RunOne_Stack`. Converted. |
| `T_F42E04` | 104 | `0xF31814` | `DisplayListB_Run_Stack`. Converted. |
| `T_F42D88` | 98 | prom_a `0xF859AE` | `A` selects a 4-byte descriptor at `0x0338 + A*4` and a saturating byte counter at `0x035B + A`, under `ei 6`; an empty descriptor is self-referential. A kernel object operation — **which** one is not established. |
| `T_F42DC0` | 98 | prom_a `0xF859AB` | the same routine entered 3 bytes earlier, which first does `ld A,(XSP+4)` — the stack-argument form |
| `T_F42E24` | 85 | `0xF0E82B` | not identified |
| `T_F42E00` | 85 | `0xF31800` | `DisplayList_Run_Stack`. Converted. |

### One slot worth naming separately

`T_F400A4` = `jp 0xF8E9A5` is the target of prom_a's **SWI7 vector**
(`0xFFFF1C` = `0x00F400A4`). `0xF8E9A5` masks `A` with `0x3F`, scales by 4 and
indexes a 64-entry table at prom_a `0xF8E9C6`. That is the machine's system-call
interface; see `FINDINGS-ui-display-list.md`.

`T_F42C70` (`jp 0xF55018`) is never *called*, but its 4-byte address spelling
`70 2C F4 00` occurs 397 times in prom_a+prom_b, 222 of them in one dense run at
prom_a `0x216B4`. It is the **default entry that fills a large pointer table**.
What that table is has not been traced.

## What is NOT established

* Why the table is banked the way it is. Long runs share a target prefix and are
  separated by `ret` fill, which *looks* like one linker input file per run. Not
  asserted.
* What the three `0x00`-filled stretches meant to the tool that emitted them.
* What any individual routine does, beyond the handful named above.
