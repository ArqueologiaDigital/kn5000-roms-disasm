# CPU 1's 0x60F0xx message module, its two duplicates, and the inline jump tables

**Established 2026-08-25**, converting prom_a `0xFAA000-0xFAD7FF` and
`0xFC5400-0xFC6FFF` (18,635 substantive bytes; the two `.fill` pads are counted
separately and headline nothing).

Every number below is re-derived from the ROM by a committed script, named where
it is used:

    python3 notes/prom_a_call_graph.py --modules      # why these modules
    python3 notes/prom_a_jumptables.py                # the inline jump tables
    python3 notes/prom_a_linear_decode_check.py LO HI # may a span be converted
    python3 notes/prom_a_byte_checks.py               # every count in the headers
    python3 notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree
    python3 notes/prom_a_audit_callsites.py           # every cited address

---

## 0. Target selection, and the one that was refused

`prom_a_call_graph.py --modules` at the start of the round:

| rank | module | refs | slots | target span | outcome |
|---:|---|---:|---:|---|---|
| 1 | `T_F4078C-T_F40810` | x171 | 34 | `0xFAA418-0xFAC786` | **converted** |
| 2 | `T_F40F34-T_F40F50` | x125 | 8 | `0xF86066-0xF86AE9` | left, §5 |
| 3 | `T_F40FC8-T_F41060` | x94 | 39 | `0xFC018D-0xFC25A8` | **refused**, §5 |
| 4 | `T_F411B4-T_F411EC` | x65 | 15 | `0xFC546A-0xFC5B25` | **converted** |
| 5 | `T_F413B4-T_F41400` | x52 | 20 | `0xFC807D-0xFCB2F0` | left, budget |

Converting rank 1 whole also retired `T_PartSettings_ResetToDefault-T_F43454` (x11, 6 slots) and
`T_F40774-T_F40784` (x7, 5 slots), which publish into the same span — the point
of converting a contiguous module rather than a list of routines.

**Frontier, measured** (`prom_a_frontier_delta.py`, which prints slots *and*
distinct targets because the round-1 report conflated them):

| | slots | distinct targets | bytes still `.incbin` |
|---|---:|---:|---:|
| start of this round | 1006 | 953 | 474,475 |
| end | 946 | 893 | 452,971 |

**60 slots and 60 targets retired**, 45 in `0xFAA000-0xFAD800` and 15 in
`0xFC5400-0xFC7000`; the script's self-check is that every retired target lies
inside a newly converted range. Four whole modules disappeared from the ranking
(34 + 15 + 6 + 5 = 60 slots), which is the arithmetic those two numbers have to
satisfy.

---

## 1. How a module's extent was established

Not by address arithmetic. Both spans are what lies **between two runs of `0x0E`
padding**, and the runs were found by scanning rather than assumed:

| run | bytes | what it bounds |
|---|---:|---|
| `0xFA9E72-0xFA9FFF` | 398 | start of the 0xFAA000 module |
| `0xFAD485-0xFAD800` incl. | 892 | its end. ★ the LAST of those `0x0E` bytes, `0xFAD800`, is itself directory slot `T_Evt2030_RunList` — a published routine that is one `ret`. This module's span therefore stops at `0xFAD800`, leaving that byte to the next one, and the `.fill` here is 890 (its first byte belongs to the data block before it) |
| `0xFC52F8-0xFC53FF` | 264 | start of the 0xFC5400 module |
| `0xFC6844-0xFC6FFF` | 1980 | its end |

All four are checked byte by byte in `prom_a_byte_checks.py`, together with the
fact that the byte before each run is *not* `0x0E`.

---

## 2. ★ INLINE JUMP TABLES — why a linear decode of these spans fails, and the fix

A linear disassembly of `0xFAA000-0xFAC8E6` reports **8 undecodable `db` bytes**
and three real callers landing mid-instruction. Every one is the same shape: a
computed dispatch whose LE32 target table is emitted **immediately after** the
`jp T,XBC` that reads it.

```
    sub BC,<first case> / cp BC,<n> / jrl UGT,<default>
    sll 0x02,BC / add XBC,<table> / ld XBC,(XBC) / jp T,XBC
  <table>:  n+1 LE32 targets
```

`notes/prom_a_jumptables.py` finds them from the ROM — it looks for the
`ld XBC,(XBC) / jp T,XBC` pair whose preceding `add XBC,imm32` names *the very
next byte* — and takes each **entry count from the reader's own `cp BC,n`**,
never by eye. **Thirteen in the whole image**, five inside this round's spans:

| table | entries | first case | reader's `cp BC` | ends at |
|---|---:|---:|---|---|
| `0xFAB8B4` | 12 | 0 | `0x000B` | `0xFAB8E4` |
| `0xFABF4A` | 12 | 0xB2 | `0x000B` | `0xFABF7A` |
| `0xFAC326` | 13 | 0xB1 | `0x000C` | `0xFAC35A` |
| `0xFAC3BF` | 13 | 0xB1 | `0x000C` | `0xFAC3F3` |
| `0xFC59DB` | 10 | 0 | `0x0009` | `0xFC5A03` |

Eight more live at `0xF99F96`, `0xF9A2A7`, `0xF9A78E`, `0xF9AA89`, `0xF9B098`,
`0xFB6240`, `0xFB62F6`, `0xFC8DB2` — every one of them inside a span some future
round will want, and every one a place where a linear decode would print
invented instructions that the byte gate cannot see.

With the four declared as data, **each of the five remaining code sub-spans
passes `prom_a_linear_decode_check.py` on its own**, and the 45 directory slots
into the span all land on instruction boundaries. That split *is* the claim; it
is what to re-run if any boundary here is doubted.

---

## 3. ★★ TWO DUPLICATES that nothing names

### 3a. The veneer bank, 1000 bytes, ten differing

`0xFAA018-0xFAA3FF` and `0xFAA418-0xFAA7FF` are 1000 bytes that differ in
**exactly ten positions**.

* **Eight** are the low halves of four `call` operands, and every pair differs
  by **exactly 0x896**:

  | stale | target | live | target |
  |---|---|---|---|
  | `0xFAA029` | `0xFAADC2` | `0xFAA429` | `0xFAB658` |
  | `0xFAA046` | `0xFAAE41` | `0xFAA446` | `0xFAB6D7` |
  | `0xFAA06D` | `0xFAAEE3` | `0xFAA46D` | `0xFAB779` |
  | `0xFAA08A` | `0xFAAE92` | `0xFAA48A` | `0xFAB728` |

* **Two** are the middle bytes of two *internal* calls, and those differ by
  **0x400** — the distance between the copies. So the copy's self-references
  were relocated and its external ones were not.
* All four right-hand targets are **published directory slots** and all four
  start with a `push`. **Three of the four** left-hand targets are two bytes
  *inside* an instruction (`0xFAADC0 ld (0x60f080),0xba`,
  `0xFAAE3F ld (XIZ+0xf2),XIY`, `0xFAAE90 ld XBC,(XIZ+0xf2)`) — checked against a
  decode anchored on the published entry `0xFAAE2A`, not on a linear run.
* Four of the five `jp` slots in the stale block's own veneer table
  (`0xFAA42A`, `0xFAA482`, `0xFAA4B3`, `0xFAA4D7`) are likewise **not**
  instruction boundaries, while all five of the live block's are.
* **Nothing publishes or names the copy**: zero directory slots point into
  `0xFAA000-0xFAA417`, and of every absolute `call`/`jp` literal in prom_a +
  prom_b naming an address inside it there are exactly **two**, both sites
  inside the copy. The live block has **37**.

**Reading**: an earlier build of the veneer bank left in the ROM, carrying
pre-relocation addresses. ⚠ That is a reading. What is *established* is the
ten-byte diff, the constant 0x896, the three non-boundaries, the four dead `jp`
slots and the two-against-thirty-seven reference counts — all re-derived by
`prom_a_byte_checks.py`, checks named `stale veneer copy:`.

### 3b. A 154-byte data tail, duplicated

`0xFAD3EB-0xFAD484` is byte-identical to `0xFAD351-0xFAD3EA`, and the match is
**maximal in both directions** (the bytes either side differ). Nothing in either
image names `0xFAD3EB`, `0xFAD3EC`, `0xFAD424`, `0xFAD431` or `0xFAD465`, while
every other table in the module is named by at least one reader. Read as the
original's framing, the copy holds the last 14 entries of `PtrTable_FAD28A`, all
of `ByteTable_FAD38A`, all of `PtrTable_FAD397` and 32 more `0x0F` bytes.

Whether one mechanism produced 3a and 3b is **not** established.

---

## 4. The data structures, and how each entry count was pinned

The rule used throughout: an entry count must come from **the reader**, not from
where the bytes stop looking like a table. Where no reader could be found, the
block is `.byte` with no count claimed.

| table | entries | what pins the count |
|---|---:|---|
| `Dispatch_By_60F080` `0xFAC8EA` | 256 LE32 | `mul BC,(0x60f080)` — an **8-bit** memory operand, so the index cannot exceed 0xFF |
| `Dispatch_By_60F080__Tail` `0xFACCEA` | 64 LE32 | all identical to the default handler; unreachable by any index the reader can form |
| `Lookup32_By_Arg8` `0xFACDEA` | 256 LE32 | `mul BC,(XIZ+0x08)`, likewise 8-bit; ends exactly where `Bytes_00_to_1F` begins |
| `Bytes_00_to_1F` `0xFAD1EA` | 32 bytes | both ends pinned by *other* tables' readers |
| `BitMask32_Table` `0xFAD20A` | 32 LE32 | 128 bytes between two addresses each named as a 32-bit immediate |
| `PtrTable_FAD28A` | 64 LE32 | its END is named by `add XBC,0x00FAD38A` at two sites |
| `ByteTable_FAD38A` | 13 bytes | its END is named by `add XBC,0x00FAD397` |
| `PtrTable_FAD397` | 13 LE32 | its END is named by `add XBC,0x00FAD3CB` |
| `Bytes_0F_FAD3CB` | 32 bytes | ⚠ the run itself; no second reader |
| `Bytes_00_to_1F_FC64A5` | 32 bytes + one 0xFF | its END is named by eight readers |
| `BitMask32_Table_FC64C6` | 32 LE32 | between two independently named addresses |
| `NoteRouting_BuildByPanelMode` | 32 LE32 | its END is named by the reader at `0xFC5BE8` |
| `Bytes_00_to_1F_x3_FC65C6` | 3 × 32 bytes | the three runs, then a value that is not identity |
| `MixedTables_FAD28A`/`_FC6626` | — | **no reader found; no count claimed** |

`Dispatch_By_60F080` is the module's command dispatcher: the reader pushes
`0xFAB860` as a return address before `jp T,XBC`, so entries are *called*. Of its
256 entries, **168 are `0x00FAC845`, and the byte at `0xFAC845` is `0x0E`
(`ret`)** — a do-nothing default; the 24 real handlers all lie in
`0xFAB894-0xFABE0D`, inside this module.

★ **The 128-byte `1 << k` table exists twice**, at `0xFAD20A` and `0xFC64C6`,
byte-identical, each read only by sites inside its own module (eleven and eight
respectively). That is what a per-module literal pool looks like; nothing here
proves it, so the two are documented separately.

The eleven readers of `0xFAD20A` differ only in which 32-bit word of a flag block
at `0x60F280`, `0x60F284` … `0x60F2A8` they `or` the mask into.

---

## 5. What was refused, and why

`T_F40FC8-T_F41060` (x94 over 39 slots, `0xFC0000-0xFC25EC`) is the
**highest-ranked module still standing that this round could have taken, and it
was left on purpose**. Its linear decode reports 60 `db` bytes and — the reason
it was refused — **eight published directory slots that are not instruction
boundaries**: `0xFC0427`, `0xFC043D`, `0xFC0452`, `0xFC0453`, `0xFC0454`,
`0xFC2155`, `0xFC2213`, `0xFC2222`. Converting it without resolving those eight
means writing invented instruction boundaries into the file, and the byte gate
cannot see them.

What is already known about it, for whoever takes it next:

* `0xFC0890-0xFC0990` is a table of **32 eight-byte records**,
  `{LE32 RAM address 0x600 + 8k, LE16 mask 1 << (k & 15), byte k, 0x0E}` — the
  `db` bytes at `0xFC08CC`, `0xFC08E0`, `0xFC090D` … are all inside it;
* `0xFC0410-0xFC0470` is a bank of five-instruction veneers
  (`ld XIZ,<record> / ld XIY,<handler> / ld A,<n> / calr 0xFC0990 / ret`), and
  **five** of the eight off-boundary directory slots — `0xFC0427`, `0xFC043D`,
  `0xFC0452`, `0xFC0453`, `0xFC0454` — point *into* those instructions, which is
  the same signature as §3a's stale copy and the first hypothesis to test. The
  other **three** (`0xFC2155`, `0xFC2213`, `0xFC2222`) fall in the string region
  below;
* ASCII strings live at `0xFC2135`: `"Combi Group Name"` immediately
  followed by `"EXT Silent Group"`, two sixteen-character fields with no
  terminator between them — so the module holds UI labels as well as code.

`T_F40F34-T_F40F50` (x125, `0xF86066-0xF86AE9`) is left for a different reason:
`0xF86000-0xF8969B` is `prom_a_linear_decode_check.py`'s own **negative control**
— the span it fails on — so it is known-mixed and needs its data mapped first.

---

## 6. What is NOT established

**What the module is for.** It moves bytes between `0x60F000-0x60F1FF` RAM and
the prom_b directory. The command byte at `(0x60F080)` is written by code inside
the module and is not traced to a source. `Lookup32_By_Arg8`'s 78 distinct
values are 16-bit quantities in `0x7622-0x7F5A` that are **not** addresses in any
image of this machine, and `0xFFFFFFFF` reads as "absent" but nothing tests for
it. `PtrTable_FAD28A` points into prom_b's `0xF3Fxxx`, which is another lane's
image.

Routine labels in both spans are therefore `sub_XXXXXX` except where a header
states its evidence: `prom_a_evidence_census.py` reports **233 headed labels, 0
without an `Evidence` line**.
