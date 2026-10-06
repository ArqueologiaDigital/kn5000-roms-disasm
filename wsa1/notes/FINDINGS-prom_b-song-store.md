# prom_b 0xF7A400-0xF7CFFF — the block-store ALLOCATOR, and the 132-entry command module above it

**Where:** `0xF7A400-0xF7A7EA` and `0xF7AA00-0xF7CE67` code and data;
`0xF7A7EB-0xF7A9FF` (533 B) and `0xF7CE68-0xF7CFFF` (408 B) `0x0E` padding.
**Status:** converted in `prom_b/wsa1_prom_b.s`. The gate
(`python3 scripts/analysis/assert_byte_identical.py`) re-checks every byte on
every build.
**Regenerate:** `python3 notes/gen_prom_b_songstore_module.py`
**Check the claims the gate cannot see:**
`python3 notes/gen_prom_b_songstore_module.py --checks` and
`python3 notes/prom_b_songstore_checks.py`

## Why this module

`notes/prom_b_module_frontier.py` (new, this round) joins the thunk table's run
decomposition (`prom_b_thunk_modules.py`) with the converted/unconverted split
(`prom_b_call_graph.py`) and ranks runs by **contiguous unconverted target
extent**, because a run whose targets straddle several `.incbin` spans is
fragmented work. Top of that list:

```
run                    slots   unc    extent    1span  spans   refs
T_F42ED0-T_F42F04    14    14     20977    20977      1      6   0xF67434-0xF6C625
T_F426E0-T_F42720    17    17     16244    16244      1     62   0xF5DAA2-0xF61A16
T_StepRecord_OnEnter-T_StepRecord_ButtonByTrackKind     3     3     14463    14463      1      4   0xF675CC-0xF6AE4B
T_DspEffect_SetSection-T_F42F6C    12    12     13084    13084      1     20   0xF0F018-0xF12334
T_BStore_AppendBytes_Join3_Veneer-T_F42ABC   132   132      8906     8906      1    172   0xF7AA00-0xF7CCCA
```

The first four are **sparse**: 1,498 / 955 / 4,821 / 1,090 bytes of extent per
entry point, i.e. most of what lies between their targets is named by nothing.
`T_BStore_AppendBytes_Join3_Veneer-T_F42ABC` is 67 bytes per entry point — the densest run in the image —
so converting it converts a module rather than a scatter. It also retires more
unconverted targets than any other run (132 of 502), has the highest summed
reference bound (172), and sits entirely in one `.incbin` span.

Directly below it in the same span is `T_F42880-T_F42894` (6 slots,
`0xF7A400-0xF7A613`), which `FINDINGS-prom_b-block-store.md` had already
singled out:

> **`T_BStore_AllocBlock_Veneer -> 0xF7A402` is the block allocator itself** — it is what
> `BStore_AllocChain` calls at `0xF63A18` for each block of a new chain. It is
> the natural next conversion.

Both runs were converted together, as one contiguous span `0xF7A400-0xF7CFFF`.

## Where the code/data split came from

`python3 notes/prom_b_module_trace.py 0xF7A400 0xF7D000` reaches **84.2%** of the
range as code by recursive descent from its own entry points, and reports 16 runs
it never reaches. Every one was then read:

| unreached run | what it is |
|---|---|
| `0xF7A7EB`, `0xF7CE68` | `0x0E` padding |
| `0xF7AF5A` (126 B) | a 32-bit mask table — see below |
| `0xF7C2FA` (17 B) | unexplained; nothing spells its address |
| `0xF7CD98` (8 B) | a step-size ladder |
| six 20/24-byte runs | pointer tables, reader 12 bytes in front |
| everything else | code reachable only through those tables' `call XHL` |

**The check that makes the split safe** — asserted on every emit, not once:
all **138** thunk targets in the range land on an instruction boundary of the
transcription. A data island mistaken for code resynchronises silently and the
only symptom is a known entry point falling off a boundary.

## What was found by checking, not by reading

### The dispatch tables are not all the same size, and the layout was wrong first

Six pointer tables sit in three identical pairs, each pair read by two sites that
share a variable. The first draft of the emitter gave all six **5** entries.
The assertion *"the word one entry past the table must not be an address in this
module"* failed on two of them: `0xF7C94C` and `0xF7C998` have **6**.

The entry count is now taken from each reader's own upper bound, twelve bytes in
front of its table, never from dividing the byte extent by 4:

| table | entries | bound site | selector |
|---|---:|---|---|
| `0xF7C6E6`, `0xF7C72F` | 5 | `cp L,4` @ `0xF7C6CD` / `0xF7C716` | `(0x0DF6)` |
| `0xF7C94C`, `0xF7C998` | **6** | `cp L,5` @ `0xF7C933` / `0xF7C97F` | `(0x0DED)` |
| `0xF7CB7C`, `0xF7CBCD` | 5 | `cp L,4` @ `0xF7CB63` / `0xF7CBB4` | `(0x0DE5)` |

Every reader has the same shape and the same lower bound `cp L,1 / jp C,<ret>`,
so **index 0 is never selected**. Entry 0 of all six tables is `0xF7C6FA`, which
is a bare `ret` — the `0x0E` padding byte doing duty as a do-nothing handler.

### `0xF7AF5A` is a 32-entry bit-mask table that is TWO BYTES SHORT

Three sites read it, all with the same four instructions
(`xor B,B / ld XIX,0x00F7AF5A / sla 0x02,C / ld XWA,(XIX+BC)`, at `0xF7AE9E`,
`0xF7AEED`, `0xF7AF3C`) and all apply the result to the 32-bit variable
`(0x360C)` — two clear a bit (`xor XWA,0xFFFFFFFF / and`), one sets it (`or`).

The 126 bytes are **byte-for-byte the ideal table `1<<k` for k = 0..31, LE32,
with two `0x00` bytes missing at byte offset 9** — inside entry 2. That equality
is asserted on every emit against a table the emitter constructs, so it cannot
drift. Consequences, as arithmetic on the bytes:

```
index 0  -> 0x00000001      index 1  -> 0x00000002      (both correct)
index 2  -> 0x00080004      (not 4)
index 3  -> 0x00100000      ... every later entry is the ideal one, shifted
index 31 -> starts at 0xF7AFD6, TWO BYTES PAST the island, so its top half is
            the first two bytes of the instruction at 0xF7AFD8
```

⚠ **What is NOT established: whether any live index exceeds 1.** The index is
`(0x0C70)-1`, `(0x0C71)-1`, `(0x0C72)-1`; the surrounding code splits the same
index across `(0x3010)` and `(0x3012)` with `cp A,0x10 / sub A,0x10`
(`0xF7AE78`, `0xF7AE81`), which is evidence that 0..31 is the intended range.
That is a fact about the design, not a measurement of a running machine. Reported
as a defect **in the data**, with the run-time consequence left open.

## What the module does

### 1. The allocator the block store does not contain (`0xF7A400-0xF7A7EA`)

It owns the free list: head in `(0x6034B8)`, count in `(0x6034BA)`, `0xFFFF` for
empty. The 256-byte record layout is exactly the one
`FINDINGS-prom_b-block-store.md` reads off `0xF63A3A`/`0xF63A46`/`0xF63A4B`.

| routine | what it does |
|---|---|
| `BStore_LatchHeapBase` `0xF7A41A` | `(0x12A2) = (0x3604)`, the allocator's own copy of the heap base |
| `BStore_FreeList_Init` `0xF7A428` | thread every one of the `(0x3608)` blocks onto the free list; clear five 17-entry arrays |
| `BStore_AllocBlock` `0xF7A4DB` | pop the head; `W = 0` ok, `W = 0xFF` empty |
| `BStore_FreeChain` `0xF7A539` | splice a whole chain back, `(0x6034BA) +=` the count |
| `BStore_SeekBlock_Alloc` `0xF7A5FF` | `(0x126E) = (0x12A2) + (IY-1)*0x100` |
| `BStore_AppendBytes` `0xF7A617` | append `C` bytes to directory entry `(0x1008)`'s chain |

`BStore_AllocBlock`'s `W = 0xFF` is exactly what `BStore_AllocChain` reads at
`0xF63A2F` and turns into error code 5 — the two halves of the heap manager meet
there.

`BStore_AppendBytes` allocates when the cursor would pass offset `0xFF`
(`add WA,BC / cp WA,0xff / jr UGT`, `0xF7A6B0`) and restarts the new block at
`sub WA,0x00fb` = `0x100 - 251`, i.e. offset 5 — the same 5-byte header
`BStore_AllocChain` computes as `ld HL,0x0100 / sub HL,0x0005` at `0xF639B8`.
On failure it writes status `(0x2880) = 0x0F` and message `(0x2070) = 0x40AB`.

**`BStore_SeekBlock_Alloc` is NOT `BStore_SeekBlock`.** The name is suffixed
because the two are different objects computing the same thing, and the diff is
printed rather than asserted by eye: 20 bytes against 18, **differing at 18 of
the first 20 offsets**. `0xF7A5FF` takes its block number in `IY` and adds
`(0x12A2)`; `0xF63BAE` takes `HL` and adds `(0x3604)`. Their tail —
`ld (0x126E),XHL / xor XHL,XHL / ret` — is 7 shared bytes.
(`python3 notes/prom_b_songstore_checks.py`)

### 2. Five 17-entry arrays — and this CORRECTS two earlier documents

`BStore_FreeList_Init` clears five arrays, each with its own `ld BC,0x0011`.
TLCS-900 `djnz r,d` decrements **then** tests
(`../mame/src/devices/cpu/tlcs900/900tbl.hxx:2061-2070`), so `BC = 17` runs the
body **17** times.

| base | count | stride | bytes | extent |
|---|---:|---:|---:|---|
| `0x00603500` | 17 | 3 | 51 | `0x603500-0x603532` — **the directory**: flags byte `0x00`, head word `0xFFFF` |
| `0x00003460` | 17 | 2 | 34 | `0x003460-0x003481` |
| `0x00003482` | 17 | 1 | 17 | `0x003482-0x003492` |
| `0x0060347E` | 17 | 2 | 34 | `0x60347E-0x60349F` — saved cursor **block numbers**, `0xFFFF` |
| `0x006034A0` | 17 | 1 | 17 | `0x6034A0-0x6034B0` — saved cursor **offsets**, `5` |

The last two **abut exactly at 17**: `0x60347E + 17*2 = 0x6034A0`. At 16 they
would not. They are `0x22` apart, which is the displacement the append path uses
(`ld A,(XIX+0x22)` at `0xF7A6A5` with `XIX = 0x0060347E + IZ/2`), and
`0x003460`/`0x003482` are an internal-RAM twin pair with the same `0x22`.

Two corrections follow, both applied in this round:

* `FINDINGS-memory-map.md` said the workspace's `+0x7E`/`+0xA0` were **"16 saved
  cursors"**. They are **17**.
* `FINDINGS-prom_b-block-store.md` said *"⚠ How many entries the directory has is
  NOT established."* The initialiser writes **17** entries of 3 bytes, 51 bytes
  total, and `BStore_AppendBytes` indexes the same array 1-based from `(0x1008)`.
  ⚠ That is a measurement of the **initialised** extent. The runtime bound
  `(0x0C90)` at `0xF62D3C` is a separate number and is still unknown, and nothing
  here says whether 17 = 16 + 1 of anything.

### 3. The command module (`0xF7AA00-0xF7CE67`)

132 thunk slots, mostly small handlers that read a mode byte, edit one variable
and post a message. The idiom repeats: `cp (0x207E),0x01` gates on an edit mode,
`or (0x2075),n` / `and (0x2075),n` set and clear request bits, `(0x2070)` takes a
16-bit message code, `(0x2880)` a status byte and `(0x0D4A)` an error code — the
same two bytes the block store's error table feeds.

**⚠ What 122 of the 132 handlers DO is not established.** They are `sub_XXXXXX`
with a computed header that claims only the entry point. Naming them needs the
message codes in `(0x2070)` decoded, and nothing in this lane does that yet.

## The ten banks are the ten SONGS

`FINDINGS-prom_b-block-store.md` closed with *"What this module is FOR — not
established"*, and offered the sequencer reading as circumstantial. This module
carries it further, at `0xF7AA35`:

```
ld A,(0x360a) / ld (0x0e02),A / inc 1,A / ld (0x12f6),A
```

* `(0x360A)` is the bank selector `FINDINGS-prom_b-block-store.md` derives at
  `0xF64B3D` (the read itself is the `ld A,(0x360a)` at `0xF64B3F`), and prom_a
  bounds it to 0..9 — `ld A,(0x360a)` at `0xF8143B` then `cp A,0` at `0xF8143F`,
  and `ld A,(0x360a)` at `0xF814CE` then `cp A,0x09` at `0xF814D2`.  The load is
  named as well as the compare, because a `cp` on its own does not say what is
  being bounded;
* this module bounds `(0x0E02)` the same way — `cp A,0x0a` at `0xF7AA99` on the
  way up, `cp A,0x0a / ld A,0x09` at `0xF7AAC3` for the wrap;
* `(0x12F6)` is drawn by 23 interpreter-B display-list records whose
  interpreter-A neighbours read `SEQUENCER PLAY`, `S0NG`, `MEASURE = `,
  `TIME SIG.= `, `REALTIME RECORD`
  (`python3 notes/prom_b_var_screens.py --var 0x12F6`).

So the ten banked 3 KiB workspaces are ten songs, and the number on the screen is
the bank index plus one.

⚠ **The weak link is the display-list step**, and `prom_b_var_screens.py` says so
itself: `near:` is nearness in the CODE, evidence for a name and not a proof of
one. The assignment chain and the two matching bounds are the strong part.

**Reproduce the strong part:**

    python3 notes/prom_b_songstore_checks.py --banks     # 13 rows, all byte re-reads

⚠ When this section was first written, **nothing checked it** — the audit of
2026-08-24 (finding F9) verified the chain by hand because no script did. The
thirteen rows above are that script. They cover steps 1–3; the display-list step
is deliberately not among them, because nearness is not a byte fact and a check
that asserted it would be asserting the weak link as if it were strong.

## Frontier, before and after

`python3 notes/prom_b_call_graph.py` listed **502** unconverted prom_b thunk
targets before this conversion and **364** after — a fall of exactly **138**,
which is the number of distinct targets the two runs own (132 + 6, with no
duplicates). That equality is the check wave 3 used and it holds here.

`python3 scripts/analysis/source_coverage.py`: prom_b went from **71,475**
substantive bytes to **81,798** — **+10,323 substantive**, plus 941 bytes of
verified `0x0E` padding emitted as `.fill`.

## What is left next door

`0xF78029-0xF7A3FF` stays `.incbin`: it is the font/bitmap data of
`FINDINGS-fonts.md`, a different subject. The `0x0E` run `0xF7A3F0-0xF7A3FF`
that ends it is left inside that `.incbin`, so the converted module starts
exactly on its first entry point.
