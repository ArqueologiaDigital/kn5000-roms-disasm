# prom_b's BLOCK STORE — a chained 256-byte heap, its directory, and a banked workspace

**Where:** `0xF62C00-0xF64C0F` code and data, `0xF64C10-0xF64FFF` `0x0E` padding.
**Status:** converted in `prom_b/wsa1_prom_b.s`. The gate
(`python3 scripts/analysis/assert_byte_identical.py`) re-checks every byte of it
on every build.
**Regenerate the whole block:** `python3 notes/gen_prom_b_blockstore_module.py`.

## Why this module and not another

`notes/prom_b_call_graph.py` ranks every unconverted prom_b thunk target by an
opcode-anchored reference upper bound. The **top two in the entire image** are
both here:

```
T_F4279C   x43    0xF635C9      BStore_CursorAdvance
T_F427BC   x42    0xF63BAE      BStore_SeekBlock
```

and `notes/prom_b_thunk_modules.py --at 0xF4279C` shows they sit in one
uninterrupted run of 49 thunk slots, `T_F42770-T_F42830`, whose targets span
`0xF62C00-0xF64BB6`.

## The three objects it manages

### 1. A heap of 256-byte blocks

```
+0        flags; bit 7 set = allocated
+1..+2    PREVIOUS block number, 16-bit
+3..+4    NEXT block number, 16-bit; 0xFFFF terminates the chain
+5..+0xFF payload, 251 bytes
```

Every field is read off an instruction, not inferred:

| field | where |
|---|---|
| bit 7 = allocated | `bit 7,(XHL)` at `0xF62CDB`, `0xF635FF`, `0xF6391A` |
| +1..+2 previous | `ld (XHL+0x01),DE` at `0xF63A4B` |
| +3..+4 next | `ld WA,(XHL+0x03)` at `0xF635D5`; `ld (XHL+0x03),IX` at `0xF63A3A` |
| 0xFFFF terminates | `ld (XHL+0x03),0xFFFF` at `0xF63A46` |
| 251 payload bytes | `ld HL,0x0100 / sub HL,0x0005` at `0xF639B8`, and the cursor restarting at offset 5 (`ld IY,0x0005`, `0xF6360A`) |

The chain is therefore **doubly linked**, and `0xFFFF` is the same terminator the
directory uses for "empty".

**The heap base `(0x3604)` is `0x00617800`.** That is not read off this module —
this module only ever says `add XHL,(0x3604)`. It is forced by the **inverse**
arithmetic, which two *other* prom_b modules spell with a literal:

```
0xF5E2F0   ld XHL,(0x126E) / sub XHL,0x00617800 / srl 0x08,XHL / inc 1,HL
0xF61F1C   ld XHL,(0x0E1F) / ld (0x126E),XHL / sub XHL,0x00617800
           / sra 0x08,XHL / inc 1,HL
```

Both recover a **1-based** block number from `(0x126E)`; `BStore_SeekBlock`
computes `(0x126E) = (0x3604) + (n-1)*0x100` from a 1-based `n`. Composing
either with the seek returns `n` **iff** `(0x3604) = 0x00617800`.
`FINDINGS-memory-map.md` already listed `0x617800 + n*0x100` as "a 256-byte-record
array"; this identifies the array and its manager.

### 2. A directory of 3-byte entries at `0x00603500`

```
+0        flags; bit 7 set = entry in use
+1..+2    head block number, 16-bit; 0xFFFF = empty
```

Read off `BStore_OpenChain` (`0xF638BB`): `muls WA,0x0003` fixes the stride,
`bit 7,(XDE+IY)` the in-use flag, `inc 1,IY / ld WA,(XDE+IY) / cp WA,0xFFFF` the
head. The 32-bit immediate `0x00603500` occurs **67 times** in prom_a+prom_b
(counted by the generator), so the directory is shared, not private to this
module.

⚠ ~~**How many entries the directory has is NOT established.**~~ **ESTABLISHED
2026-08-25: 17.** `BStore_FreeList_Init` (prom_b `0xF7A428`, converted in
`FINDINGS-prom_b-song-store.md`) clears the array with
`ld XHL,0x00603500 / ld BC,0x0011 / ld (XHL),0x00 / ld (XHL+0x01),0xFFFF /
add XHL,0x00000003 / djnz BC` — 17 entries of 3 bytes, 51 bytes,
`0x603500-0x603532` — and `BStore_AppendBytes` (`0xF7A7A8`) indexes the same
array 1-based from `(0x1008)`. Re-read by
`python3 notes/prom_b_songstore_checks.py --arrays`.
⚠ That is the **initialised** extent. `(0x0C90)`, which bounds a loop over the
directory at `0xF62D3C`, is a separate runtime number and is still unknown; and
nothing says whether 17 is 16 + 1 of anything.

### 3. A 3 KiB workspace at `0x00603400`, banked to `0x00610000 + n*0xC00`

`BStore_Workspace_LoadFromBank` (`0xF64B3D`) and `BStore_Workspace_SaveToBank`
(`0xF64BE3`) are a matched pair: `ldir` of `0x0C00` bytes with `XIX` and `XIY`
swapped, the index computed as `sla 0x0B` + `sla 0x0A` of `(0x360A)`
(= n·0x800 + n·0x400 = n·0xC00), and `(0x360C)` shuttled through the workspace's
own `+0x1E` so a reload restores it.

**TLCS-900 `ldir` copies `(XIX)+ ← (XIY)+`** — `../mame/src/devices/cpu/tlcs900/900tbl.hxx:2483`
writes through `p1` and reads `p2`, and `:5437-5438` set `p1 = reg(op-1) = XIX`,
`p2 = reg(op) = XIY` for the `0x85` prefix. That is what decides which of the two
routines is the save and which the load, so it is cited rather than assumed.

Two things make this the interesting part:

* `0x603400-0x603FFF` is **exactly** the 3 KiB that `FINDINGS-memory-map.md`
  records as "work DRAM, **deliberately NOT cleared** and live" — the one hole in
  prom_a's two boot clear loops. This module is what the hole is for.
* prom_a bounds `(0x360A)`: `0xF8143F cp A,0` refuses to decrement below 0 and
  `0xF814D2 cp A,0x09` refuses to increment past 9. So **ten banks**, and
  `0x610000 + 10*0xC00 = 0x617800` — the heap base. Two independently derived
  constants abut with **no slack**.
  [Named 2026-10-03: `(0x360A)` is `BStore_CurrentBank`, `wsa1/include/wsa1_ram.inc`.]

⚠ That abutment is *consistency between two derivations*, not proof that the two
regions were laid out as one object. It would survive a coincidence of 12 bits.

**Named in the source (2026-10-03).** The module's variables are symbols in
`wsa1/include/wsa1_ram.inc`: `BStore_CursorBlockAddr` (0x126E), `BStore_CursorBlock` (0x345C),
`BStore_BlockLimit` (0x0CA4), `BStore_HeapBase` (0x3604), `BStore_BlockCount` (0x3608),
`BStore_AllocHeapBase` (0x12A2), `BStore_FreeHead` / `BStore_FreeCount` (0x6034B8 / 0x6034BA),
`BStore_DirEntry` (0x1008) and `BStore_ErrorCode` (0x0D4A) -- 1,541 operands in prom_a and prom_b
(`python3 scripts/tools/name_wsa1_ram_count.py`).  The `BStore` prefix keeps this note's caution:
it names the module, not what the module is FOR.

## The cursor

`((0x126E) = block address, IY = byte offset)`, with `(0x345C)` carrying the
block number. `BStore_CursorAdvance` is the only routine that moves it across a
block boundary: `inc 1,IY`, return while `IY <= 0xFF`, otherwise follow `+3`,
range-check against `(0x0CA4)`, check the new block's bit 7, restart at offset 5.

The pair (16-bit word at workspace `+0x7E`, byte at workspace `+0xA0`) is a
**saved** cursor. That is not a guess about two arrays: `BStore_SaveCursor`
(`0xF63924`) writes exactly that pair from a live block number and offset — into
the workspace *and* into the bank copy at `0x610000 + n*0xC00 + 0x7E / + 0xA0` —
and `BStore_ValidateSavedCursor` (`0xF62C7E`) reads the same pair back and
re-checks it.

## The payload is a tagged byte stream

Tag values compared against in this module, with comparison-site counts emitted
by the generator:

```
0x80 x1   0x81 x9   0x82 x11   0x84 x6   0x85 x2   0x86 x2   0x87 x2
```

`0x81` is *counted* (`BStore_CountMarkersForward`, `0xF62D8C`, increments `C` on
each one), `0x82` stops a forward walk with error 8, and `0x82`/`0x84` are what a
saved cursor must be pointing at. ⚠ **What the tags mean is not established.**

## Two pieces of dead code, found by converting it

* `0xF635D8` in `BStore_CursorAdvance`: `cp WA,0xFFFF / jr ULE`. `WA` is 16 bits,
  so the branch is always taken and the `ld (0x0D4A),0x08` at `0xF635DE` can
  never execute. Error 8 is still produced — by `0xF62DA0`.
* `0xF62CA5` in `BStore_ValidateSavedCursor`: `cp BC,0x00FF / jr ULE` after
  `xor BC,BC / ld C,(...)`. Same shape, same conclusion.

Both look like a C compiler comparing a zero-extended byte against `0xFF`.

## Three data islands, and how they were found

A **linear** decode of the module resynchronises after a data table and gives no
sign of it — except that it steps clean over `0xF63489`, which is the target of
thunk slot `T_F42790` and therefore must be an instruction. `notes/prom_b_module_trace.py`
does a recursive descent from the module's own entry points instead and reports
the runs no walk reaches:

| island | size | what reads it |
|---|---:|---|
| `0xF63441-0xF63488` | 72 | `BStore_ErrorToStatusByte` (`0xF6342C`), the **only** site in prom_a+prom_b that spells `0x00F63441`. Indexed by the error code `(0x0D4A)`; the byte goes to `(0x2880)`. Lays out as 6 rows of 12 with only four distinct non-`0xFF` values. Meaning **not** established. |
| `0xF63CC0-0xF63CDF` | 32 | `ld L,(0x00F63CC0+L)` at `0xF63C97` and `0xF64040`, in both cases with `L` fetched from the 16-byte array at `0x00603422` and the result tested against `0xFF`. The table is the identity map `0x00..0x1F` and contains **no** `0xFF`. |
| `0xF6415E-0xF6418D` | 48 | **nothing** — no site in prom_a or prom_b spells `0x00F6415E`. Extent by abutment only. Reads as two 24-byte rows. Structure **not** established. |

Every pattern claimed for these three is re-asserted by
`gen_prom_b_blockstore_module.py:assert_data_islands()` on every emit, because
the byte gate cannot see a comment.

## What this module is FOR — not established

The obvious reading is that a directory of chained byte streams with delimiter
tags, living in the one RAM region that survives a warm restart, is the
sequencer's song memory. What supports it is circumstantial and is recorded as
such: the cursor `(0x126E)` sits in the same 0x12xx page as `(0x12F6)` and
`(0x12FC)`, which interpreter-B display-list records draw on the screen whose
interpreter-A text reads `SEQUENCER PLAY`, `S0NG`, `CYCLE:`, `MEASURE = `,
`TIME SIG.= ` (`python3 notes/prom_b_var_screens.py --var 0x12F6`). Adjacency in
a RAM page is not evidence about a routine. The labels in the assembly therefore
say `BStore`, and every routine whose behaviour was not read off its own
instructions is `sub_XXXXXX`.

## What is still `.incbin` around it

`0xF5BAB8-0xF62BFF` and `0xF65000-0xF77FFF`.

`python3 notes/prom_b_call_graph.py` before this conversion listed **558**
unconverted prom_b thunk targets; after it, **509** — exactly the 49 slots of
this module's run, which is a self-check that the block covers the run and
nothing else. The new top of the list is

```
T_F409AC x29 0xF000B9   T_F4270C x25 0xF5EBD0   T_F40CC4 x24 0xF4E56F
T_F409E0 x24 0xF4542D   T_F41EE4 x23 0xF5B84C   T_F40C84 x21 0xF4D01D
T_F40C54 x18 0xF4D0DB   T_F42884 x17 0xF7A402   T_F42CA8 x15 0xF5553F
```

**`T_F42884 -> 0xF7A402` is the block allocator itself** — it is what
`BStore_AllocChain` calls at `0xF63A18` for each block of a new chain, and it
returns failure in `W`. It is the natural next conversion: it closes the one
routine this module depends on and does not contain.

✅ **DONE, 2026-08-25.** `0xF7A400-0xF7CFFF` is converted — the allocator
(`BStore_AllocBlock`, `BStore_FreeChain`, `BStore_FreeList_Init`,
`BStore_AppendBytes`) together with the 132-slot command module above it. See
`FINDINGS-prom_b-song-store.md`. Two claims elsewhere were corrected by it: the
directory's entry count (above) and the saved-cursor count in
`FINDINGS-memory-map.md` (16 → 17). It also carries the "what is this FOR"
question further: the ten banks are the ten SONGS, by the assignment chain
`ld A,(0x360a) / ld (0x0e02),A / inc 1,A / ld (0x12f6),A` at `0xF7AA35`.
The frontier fell 502 → 364, exactly the 138 slots the two runs own.
