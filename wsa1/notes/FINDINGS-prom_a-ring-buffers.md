# CPU 1's ring-buffer library, its fourteen rings, and the callback queue

**Established 2026-08-25**, converting prom_a `0xF830C6-0xF855FF`,
`0xF8BC00-0xF8BFFF`, `0xF8DA00-0xF8E47E` and `0xFE0000-0xFE54B5`.

Every number below is re-derived from the ROM by a committed script, named at
the point it is used. Nothing here is a hand count. The three that do most of
the work are

    python3 notes/prom_a_ringbuf_map.py          # the class, the 15 groups, 22 checks
    python3 notes/prom_a_call_graph.py --modules # why these modules and not others
    python3 notes/prom_a_byte_checks.py          # the headers' own numbers
    python3 notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree --by-block

---

## 0. How the targets were chosen, and what the choice cost

prom_a had no frontier tool. `notes/prom_b_call_graph.py` computes exactly the
ranking this round needed and then throws the prom_a half away — its rows loop
carries the line `if not (B_BASE <= tgt < A_BASE): continue   # prom_a target,
other lane`. So `notes/prom_a_call_graph.py` was written first, as the mirror of
it, sharing its method so the two numbers are comparable.

Its `--modules` view ranks runs of consecutive directory slots by total
reference upper bound. **Four modules were converted this round, and they are
ranks 1, 2, 3 and 5 — not "the top four"** (corrected 2026-08-25, round-2 audit
F10; the earlier wording claimed a clean sweep that did not happen). The rank-4
module, `T_F4078C-T_F40810` at x171 over 34 slots, was left standing and is the
target of the next round:

| rank | module | refs | slots | target span | what it turned out to be |
|---:|---|---:|---:|---|---|
| 1 | `T_F42E80-T_F42E88` | 329 | 3 | `0xF8DA00-0xF8DA83` | the callback queue, §4 |
| 2 | `T_F41CD0-T_F41EC4` | 245 | 126 | `0xF842DF-0xF84BBC` | the ring instance bank, §2 |
| 3 | `T_F42574-T_F42634` | 171 | 49 | `0xFE0391-0xFE1CE4` | inside the 21 KB span of §6 |
| 4 | `T_F4078C-T_F40810` | 171 | 34 | `0xFAA418-0xFAC786` | **not converted this round** |
| 5 | `T_F41AF0-T_F41B18` | 146 | 11 | `0xF8BC00-0xF8BDF8` | the ASCII numeric field, §5 |

⚠ **The reference counts are upper bounds.** The scan is opcode-anchored at
every byte offset, so some hits are bytes inside another instruction. They rank
slots; they are not call counts, and no number in this note treats them as one.

**Frontier before and after.** ⚠ Corrected 2026-08-25 (round-2 audit, F10):
`1218` and `1006` are **SLOTS**, which is what `prom_a_call_graph.py`'s "top N
of M" line counts, and this paragraph used to call them "targets". Several
slots publish the same address, so the two numbers differ. Measured by
`python3 notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree --by-block`,
which prints both:

| | slots | distinct targets | bytes still `.incbin` |
|---|---:|---:|---:|
| before | 1218 | 1165 | 509,402 |
| after | 1006 | 953 | 474,475 |

**212 slots and 212 distinct targets** retired — the two happen to agree here,
and the script's self-check is that every retired target lies inside a newly
converted range. Those bytes form **four maximal contiguous ranges** (130 + 14
+ 11 + 57 targets); the same 212 split by the *named* blocks below is
4 + 0 + 126 + 14 + 3 + 1 + 7 + 57, which is the grouping the section headings
use. Both splits are printed by the script; a report has to say which it means.

---

## 1. The CLASS at `0xF84000-0xF842DE`: five operations, five ring sizes

Twenty-five routines, and they are five operations emitted once per capacity.
`notes/prom_a_ringbuf_map.py` matches each against an exact byte template whose
only variable field is the wrap mask, and walks `0xF84000-0xF842DE` with no gap:

```
family     0x80      0x100     0x200     0x400     0x1000
Get        0xF84000  0xF8401F  0xF8403E  0xF8405D  0xF8407C
Scan       0xF8409B  0xF840B7  0xF840D3  0xF840EF  0xF8410B
ScanToPut  0xF84127  0xF84143  0xF8415F  0xF8417B  0xF84197
Put        0xF841B3  0xF841D5  0xF841F7  0xF84219  0xF8423B
Init       0xF8425D  0xF84277  0xF84291  0xF842AB  0xF842C5
```

Every one of them takes the ring in `XHL` and nothing else. The five control
words sit **below** that pointer, at negative 8-bit displacements:

| offset | field | what establishes it |
|---|---|---|
| `-10` | scan cursor | the two scan families read `(XHL + (XHL-10))` and advance it |
| `-8` | read cursor | `Get` reads `(XHL + (XHL-8))`; every instance's IsEmpty compares `-8` against `-4` |
| `-6` | scan limit | `Scan` compares `-10` against it |
| `-4` | write cursor | `Put` stores at `(XHL + (XHL-4))` |
| `-2` | **free bytes remaining** | `Init` seeds it with capacity−1, `Put` refuses at 0 and decrements, `Get` increments, neither scan family touches it |
| `+0`.. | the data, `capacity` bytes | |

The free count being **free space**, not occupancy, is a check, not a reading:
`Init`'s seed equals the family's own `minc1_16` mask plus one, minus one, for
every one of the five capacities. That is also why one slot of every ring is
never used.

### ★ Ten of the twenty-five are dead

The instance bank uses only the `0x100`, `0x200` and `0x400` capacities. The ten
routines for `0x80` and `0x1000` have **no reference anywhere** in prom_a or
prom_b — not by absolute `call`/`jp`, not by any PC-relative `calr`/`jr`/`jrl`.
And **nothing outside the bank calls any class routine at all**. Both are checks
in `prom_a_ringbuf_map.py`; the reference scan behind them resolves all five
spellings over both images. This is what a library linked in whole looks like.

---

## 2. The INSTANCE BANK at `0xF842DF-0xF84C6B`: 15 groups of 11

Every group is the same eleven routines in the same order and is **exactly 163
bytes**; nine of the eleven are published and two are a bare `ret`.

```
 1 Get        6 ScanRewind   (ring-10) := (ring-8)
 2 Put        7 Scan
 3 PutBlock   8 ret
 4 IsEmpty    9 ScanToPut
 5 Init      10 ret
           11 GetCommit    (ring-8) := (ring-6)
```

15 groups × 9 published = 135, but the module owns 126 slots: the **fifteenth
group is unpublished**, and it is a byte-for-byte copy of the fourteenth,
addressing the same ring. Both facts are checks.

**A ring's capacity is established by agreement, not by assertion**: all nine
veneers of a group name the same object with `lda XHL,<ring>` and call a class
routine of the same capacity. A group whose veneers disagreed would be reported
as `MIXED` and would fail the check.

| ring | capacity | | ring | capacity |
|---|---|---|---|---|
| `0x60000C` | `0x400` | | `0x601646` | `0x200` |
| `0x60080A` | `0x200` | | `0x601850` | `0x100` (two groups) |
| `0x600A14` | `0x200` | | `0x60195A` | `0x200` |
| `0x600C1E` | `0x400` | | `0x601B64` | `0x100` |
| `0x601028` | `0x400` | | `0x601C6E` | `0x200` |
| `0x601432` | `0x100` | | `0x60480A` | `0x100` |
| `0x60153C` | `0x100` | | `0x608A0A` | `0x400` |

### ★ Eleven of the fourteen TILE one RAM region

Under the reading above — control block ten bytes below the pointer, data
`capacity` bytes at and above it — eleven of the rings tile
`0x600800-0x601E6E` **end to end, with no gap and no overlap**. Nothing forces a
linker to place them so; that they do is the strongest single piece of evidence
that the field layout is what the class says it is. It is the last check in
`prom_a_ringbuf_map.py`.

### What is NOT established

What any ring **carries**. The object addresses are RAM addresses and the
producers and consumers are outside the module. One ring is identified
independently — `0x600A14` is the 512-byte sequencer event buffer this tree
already documents at `SeqBuf_AppendMarker` — and its capacity from that side
(`minc1_16 hl,0x01ff`) agrees with the capacity the bank gives it.

Also not established: who writes the scan limit at `-6`. Nothing in the module
does except `Init`, which zeroes it. So the transaction reading of the
rewind/commit pair — rewind the scan to the read cursor, look ahead without
consuming, then commit up to the limit — is a **reading of two assignments**,
not a fact.

---

## 3. `0xF830C6-0xF83215`: three routines, and a one-byte difference worth knowing

* **`SeqBuf_AppendEvent`** (`0xF830C6`) appends the caller's byte and then the
  tick at `(0x93)` to the ring at `0x600A14`. **Nothing in prom_a or prom_b
  names it** — a searched negative, re-derived by the reference scan in
  `prom_a_ringbuf_map.py`, covering absolute and PC-relative forms; and
  `0xF830C5` is a `ret`, so it is not reached by fall-through either.

* ★ **RETRACTED 2026-08-25 (round-2 audit, F1): `0xFA570C` is NOT "a near-twin
  differing by ONE BYTE".** This bullet said it was. Measured over the 90-byte
  extent: **75 positional bytes differ**, and the common prefix is **four**
  bytes — `f0 aa c8` plus the opcode byte of the `jr NZ`, whose displacement
  already differs. `SeqBuf_AppendEvent` is 28 instructions (`0xF830C6-0xF8311F`,
  90 bytes); `0xFA570C` is 27 (`0xFA570C-0xFA5762`, 87 bytes). They are two
  independently written routines sharing an algorithm and a buffer. Differences,
  instruction by instruction:

  | | `0xF830C6` | `0xFA570C` |
  |---|---|---|
  | base register | `XIY` throughout | `XIX` throughout |
  | critical section | `push XIY` … `pop XIY` | `push SR` / `ei 0x06` … `pop SR` |
  | free-count update | `decw 1,(XIY+0xfe)` **twice** | `decw 2,(XIX+0xfe)` once |
  | write-cursor store | `ld (0x600a10),HL` (absolute) | `ld (XIX+0xfc),HL` (indexed, same cell) |
  | trace path | `extz XHL`, `XHL`-relative, `ld A,(0x93)` **twice** (second load dead) | `ld XIX,0x000000ae`, `XIX`-relative, `ld A,(0x93)` once |

  **What survives, and is now pinned by `notes/prom_a_byte_checks.py` (checks
  named `SeqBuf twins:`)**: both append two bytes to the *same* 512-byte ring at
  `0x600A14`; both net-decrement the free count by 2; and their guards read
  **different cells of that ring's control block** — `0xF830CB` reads
  `0x600A12`, the free-space count the class's own `Put` tests, and `0xFA5711`
  reads `0x600A0C`, the **read cursor** (§1's field table). A guard on the read
  cursor is not a bounds test on free space; whether that is a defect is not
  established, and nothing in the ROM says.

* **`Dev7F_WriteSlot8`** (`0xF83197`) is the driver for the `0x7F0000`
  address/data register pair. `notes/FINDINGS-memory-map.md` already described
  that device as "8 writes per slot, slot = `(n<<5) | 0x10`" from a byte census
  taken while this routine was still `.incbin`, and cited these very
  instructions; converting it confirms the census rather than adding to it. Its
  four entry stubs are directory slots `T_F40004`, `T_F40008`, `T_F4000C`,
  `T_F40010`, and the body is named by five `calr` sites and nothing else.

* **`sub_F831B3`** keeps an address label deliberately. Its four
  `ld XHL,XSP / add XHL,8|6|4|2` sources overlap each other and reach **above**
  the four words it pushed, so read literally the first of them runs into its own
  return address. That is what the bytes say; whether it is a defect is not
  established, and no claim either way belongs in a name.

---

## 4. ★ The CALLBACK QUEUE at `0xF8DA00`, and kernel task 2

The highest-ranked module in prom_a: 131 bytes, three directory slots, 329
references. It is the ring layout of §1 with **four-byte elements**, coded
inline: the same `-2` free count, `-4` write index, `-8` read index, the same
capacity−1 seed, and `minc4_16 ..,0x01fc` — a modular increment **by four** over
`0x200` bytes, so 128 entries. The two scan cursors are simply unused.

And if its control block is ten bytes like the class's, it begins at `0x60040C`,
which is exactly where ring `0x60000C`'s `0x400` bytes of data end. A check.

**`Task2_CallbackDispatcher` is not called — it is a task entry point.** The
chain is exact and every link is a check in `prom_a_byte_checks.py`:

* `EntryPoint_Records[2]` at `0xF85E96` holds PC = `0x00F42E88`;
* prom_b `0xF42E88` is `jp 0xF8DA00`;
* that is the directory slot with **zero** references — nothing calls it,
  the scheduler dispatches it;
* its record gives it stack `0x0060E980` and priority 3.

The body waits on semaphore 1, takes one element, and — when the queue was not
empty — `call T,XIY`, an **indirect call through the value the queue returned**.
A queue whose elements are called is a queue of function pointers.

`CallbackQueue_ResetAndRestartTask2` (`0xF8DA83`, 141 references) does the whole
lifecycle through kernel slots this tree already identified: init the queue, take
semaphores 4 and 2 (the two that `FINDINGS-prom_a-kernel-lifecycle.md` §5.2
shows starting at 1 — the binary ones), stop task 2 through `0xF85E5E`, release
both, **drain semaphore 1 with `Kernel_SemaTryWait` until it answers 0xFFFF**,
and `Kernel_StartTask(2)`. Each of the five slot identities is a check.

### What is NOT established

★ **`CallbackQueue_Post` does not signal semaphore 1**, and nothing else in the
module does. Whatever wakes the task is outside it, and this round did not find
it. Until it does, "one signal per callback" is **not** established — only that
the task consumes one signal per iteration.

---

## 5. Two smaller modules, and one data table

* **`0xF8BC00-0xF8BF21`, the ASCII numeric field.** Parse (`x100`, `x10`, `x1`,
  each arm guarded by `cp C,0x30` / `cp C,0x39`), sign (`0x2B` = `'+'`), bias,
  clear (one 32-bit store of `0x2020202B` — `'+'` and three spaces), and a
  formatter that writes three cells at `0x2661` with a flag byte at `0x2665`.
  ⚠ What the field is FOR is not established.

* **`SignedNibbleDelta_Table`, `0xF8BDA5`, 32 bytes, emitted as `.byte` and
  never decoded.** `0x00..0x0F` then `0x00, 0xFF..0xF1`: a 4-bit magnitude plus
  a sign bit mapped to a signed delta. The index cannot exceed 31 — it is built
  as `(W & 0x0F) | ((W & 0x80) >> 3)` — and `0xF8BDA5 + 32 = 0xF8BDC5` is a
  **published directory entry**, so both ends are pinned by something other than
  the table. Last-entry test: entry 31 is `0xF1` = −15, entry 30 is `0xF2`.
  A linear disassembly walks straight into this table; that is what produced the
  six `db` bytes at `0xF8BDBF-0xF8BDC4` in the first survey of the module, and it
  would have printed six invented instructions.

* **`0xF8DC00-0xF8DDE5`, the analogue control scan.** Six channels in one pass:
  four from the TMP95C061's own `ADREG0`-`ADREG3` (the SFR names come from
  `include/tmp95c061_sfr.inc`), read as words and shifted right eight, and two
  from `(0x600000)` and `(0x600001)`, which the module's own initialiser parks
  at `0x80`. One deadband filter, thresholds 2 and 6, per-channel state pair at
  `0x28E0 + 2n`. All six report through directory slot `T_F405F0`. Each channel's
  ADREG index, state pair and channel number is a separate check, so a changed
  literal fails instead of passing forever. ⚠ What the six controls **are** is
  not established.

---

## 6. `0xFE0000-0xFE54B5`: 21,686 bytes converted and NOT named

⚠ **This is where most of the round's coverage came from, and almost none of its
understanding.** 323 of its labels are `sub_XXXXXX`. It was converted because it
is the largest run in prom_a that decodes cleanly end to end, and because 21 KB
inside an `.incbin` is invisible to every tool in `notes/`.

`notes/prom_a_linear_decode_check.py` is the new artefact behind that decision.
It answers "is a linear disassembly of this span self-consistent?" with three
tests: no undecodable bytes; the end is an instruction boundary of a decode run
**past** it; and every directory entry pointing into the span lands on an
instruction boundary, with no in-span `call`/`calr` reaching an address that is
not one. The converted span passes all three;
`0xF86000-0xF8969B`, which really does carry data tables and is still `.incbin`
for that reason, **fails all three** and is the script's negative control.

### ★ Two corrections the control forced, in this same round

1. **The end test as first written could not fail.** It cut the file at the end
   address and checked that the decode finished there — which it always does,
   because unidasm cannot run off the bytes it is given. It now decodes past the
   end and asks whether the end is a boundary. A criterion that cannot fail is
   not a pass, and this one had already been written into a header before the
   control was run.
2. **These tests do not pin the START.** Re-running all three one byte late, at
   `0xFE0001`, **passes** — a TLCS-900 decode resynchronises within a couple of
   instructions and then agrees with everything downstream. What pins `0xFE0000`
   is the `jp` veneer block at `0xFE0000-0xFE0017`, not the decode. The selftest
   prints that case explicitly so nobody rediscovers it as a surprise.

---

## 7. Toolchain: the register-indexed operand is no longer `.byte`

`notes/prom_a-tooling.md` listed three TLCS-900 shapes that `llvm-mc` cannot
spell and that both lanes therefore emitted as raw `.byte`. **The
register-indexed `(rr+r)` operand is not one of them any more.** The macro
prelude in `prom_a/wsa1_prom_a.s` grew the `MXB`/`MXW`/`MXL`/`MXD` prefixes, the
`ra_*` and `rb_*` register-address constants and eleven `mx_*` / `mx8_*`
operation macros, all cited to `dasm900.cpp:1543-1584` and `:1349-1405`; and
`prom_a/roundtrip.py` grew four recognisers for them.

**44 existing `.byte` lines in `prom_a/wsa1_prom_a.s` became named macro calls**
in one pass, and the same pass fixed two trailing comments that still said
"llvm-mc has no spelling". The shift-by-a-register forms and the
register-direct `s_allreg8` operand (`ld A,IZL`) are still `.byte`.

Also added, because the 0xFE0000 module needed them: `m_div`, `m_divs`,
`m_pushw`, `m_popw`, `mx_lda32`, `mx_jp_cc`, and — a real bug — the
`mul`/`muls` recogniser accepted only MAME's `s_mulreg16` spelling of the
destination and silently `.byte`d the ten `muls XWA,(XSP+0x08)`-shaped
instructions, whose destination prints from `s_reg32` instead. That module's
`.byte` count went from 49 to 13.

---

## 8. What this round left, and why

* **`0xF86000-0xF8969A` (13,986 bytes) and `0xF8A000-0xF8BBB3` (7,092).** They
  hold data tables, and `prom_a_linear_decode_check.py` fails on both:
  **408** and **139** undecodable bytes respectively, and the first also has 2
  directory entries and 4 real in-span call sites landing off a boundary.
  Converting them needs the tables located first, not a linear pass.
* **`0xF8C000-0xF8C99B` (2,460 bytes).** Only **17** undecodable bytes — but the
  same script reports **6 of its 16 directory entries off an instruction
  boundary**, which is the sharper signal: the module embeds argument tables the
  code points at with `ld XIY,0x00F8Cxxx`. The interpreter at `0xF8C16D` is
  already legible — 7-byte records of `key, 32-bit pointer, 16-bit mask`,
  terminated by `key == 0xFF`, applied as `or (ptr),mask` — so the next round can
  enumerate the tables from the pointers and emit them as data, the way
  `SignedNibbleDelta_Table` is emitted here.
* **The top of the remaining frontier**, from `prom_a_call_graph.py --modules`:
  `T_F4078C-T_F40810` (171 references, 34 slots, `0xFAA418-0xFAC786`),
  `T_F40F34-T_F40F50` (125, 8, `0xF86066-0xF86AE9` — inside the data-bearing
  span above), `T_F40FC8-T_F41060` (94, 39, `0xFC018D-0xFC25A8`).
* **Naming `0xFE0000-0xFE54B5`.** 323 `sub_XXXXXX` labels are 323 open questions,
  and the module makes only one `swi 7` call in 21,686 bytes, so it is not the
  display-service client layer this tree might have assumed.
