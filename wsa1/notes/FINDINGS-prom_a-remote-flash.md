# prom_a 0xFB2000-0xFBFFFF — the remote-flash reader, and what it says about
# emulation gaps D and C

Written 2026-08-25, wave 5 round 2. Every number below is re-derived from the ROM
by `python3 notes/prom_a_fb2000_checks.py`; run it before quoting any of them.
The byte gate (`scripts/analysis/assert_byte_identical.py`) proves the source
rebuilds the ROM and is blind to every sentence in this file.

## 1. Why this span

`python3 notes/prom_a_module_frontier.py` — new this round, the prom_a twin of
`notes/prom_b_module_frontier.py` — ranks prom_a's thunk RUNS by how many bytes
of contiguous still-`.incbin` target range they publish. The run
`T_F408E4-T_SysExTx_SendBytes` came third (12 slots, 23,200 bytes, reference upper bound
10), and every one of its targets is in `0xFB2022-0xFB7AC2`.

That run is also where **emulation gap D** lives: the gaps file
(`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`) names `0xFB24D3` as "the
caller that names the flash (dest `0x60A000`, remote `0xE80000`)" and asks what
prom_a does with the bytes afterwards.

## 2. Four modules, delimited by the ROM's own padding

| module | code | pad | pad size | directory slots |
|---|---|---|---:|---:|
| `0xFB2000` | `0xFB2000-0xFB8CA5` | `0xFB8CA6-0xFB8FFF` | 858 | 12 |
| `0xFB9000` | `0xFB9000-0xFBA235` | `0xFBA236-0xFBABFF` | 2,506 | 9 |
| `0xFBAC00` | `0xFBAC00-0xFBB42D` | `0xFBB42E-0xFBB7FF` | 978 | 4 |
| `0xFBB800` | `0xFBB800-0xFBFFD3` | `0xFBFFD4-0xFBFFFF` | 44 | 81 |

Every pad is uniform `0x0E` (RET) checked byte by byte, the byte before each is
not `0x0E`, and each pad reaches the next `0x400`/`0x800` boundary. 106 directory
slots in total, naming 106 distinct targets.

⚠ **What pins each module START is not the same evidence in all four cases.**
`0xFB2000` opens with a block of `jp`/`ret` veneers and publishes `0xFB2022`;
`0xFBAC00` and `0xFBB800` are themselves directory targets; `0xFB9000` is
neither — it opens straight on a `push XIZ / ld XIZ,XSP` prologue and nothing
names it, so only the pad that ends the previous module pins it. That is the
weakest of the four and is recorded as such.

## 3. ★★ Emulation gap D — answered as far as the ROM can answer it

**The firmware never indexes the remote image. It STREAMS it**, in fixed 8 KiB
blocks, through one staging buffer at RAM `0x60A000`:

```
Remote_E80000_Read32Blocks   (0xFB24EC)
    XIX = 0x00E80000 ;  H = 0x1F
  loop:
    Link_RemoteRead(src = XIX, count = 0x2000, dst = 0x60A000)   ; T_F40EF0
    0xFB7649(0x60FCF8) ; 0xFB6FB2                                ; consume it
    Link_WaitBlockDone()                                          ; T_F4123C
    XIX += 0x2000 ; until --H == 0
  then ONE more block of the same shape (0xFB2556-0xFB2560)
```

31 iterations plus the block after the loop is **32 × 0x2000 = 0x40000**, so the
range read is remote **`0xE80000-0xEBFFFF`, 256 KiB — half the size of the
prom_d image**. (The loop's own back branch is `jr nz,-44` at `0xFB2554`,
targeting `0xFB252A`, so the buffer address is re-pushed every pass.)

⚠ **Which stack slot is which is not established by this module.** What is
established is the three literals and the order they are pushed in — `0x60A000`,
then `0x2000`, then `XIX`. Naming them dst/count/src comes from
`INTTC3_LinkDmaDone`'s decode of the `0xE1`/`0xE2` pair and from the gaps file's
own reading of `0xFB24D3`; `0xF8E0FE` itself is still `.incbin`. That is measured, not inferred; what the other half of prom_d is,
or whether some other path reaches it, is NOT established here.

So the gap-D question — "does any instruction index prom_d's 44-entry offset
header at file `0x000000`, or its 274-entry pointer directory at `0x000B80`?" —
gets a **NO with a reason**: on this path nothing indexes the remote image at
all, because the whole image passes through one 8 KiB window. A driver that maps
prom_d at `0xE80000` on CPU 2 would satisfy this reader for the first 256 KiB
without any directory being consulted on CPU 1's side.

Both link entries resolve into prom_a's already-converted link block:

| prom_b slot | target | what it is |
|---|---|---|
| `T_F40EF0` | `0xF8E0FE` | the remote-read packet builder (gap D names it) |
| `T_F4123C` | `0xF8E66D` | `Link_WaitBlockDone` |

⚠ **What the blocks CONTAIN is still not established.** The two routines that
consume each block, `0xFB7649` and `0xFB6FB2`, are converted by this round and
are still `sub_`.

⚠ The single-block sibling at **`0xFB248A`** passes **count = 0x0000**. It
carries a full header in the source but **no label**: nothing in prom_a or
prom_b names that address (`notes/prom_a_fb2000_checks.py` re-runs that searched
negative), and `notes/gen_prom_a_block.py` places a label only where a site names
one. A zero-length read, a `0x10000` wrap and a "position only"
probe all fit the byte; nothing here chooses between them.

## 4. Emulation gap C — the callers of the release path

> ⚠ **RETRACTED AND REPLACED 2026-08-25, round-2 audit F1.** This section used to
> say *"**This module is where it is called from**: `0xFB24D7` and `0xFB256E` …
> and nowhere else in converted prom_a"*, and drew from it that *"a machine that
> never runs a remote-flash read never reaches that release"*. Both sentences are
> false. The header of `Link_WaitBlockDone` itself already pointed at the tool
> that refutes them (`notes/prom_a_xref.py`, 22 candidate sites); nobody ran it.

Gap C asks why CPU 1 never releases the link's receiver-busy line, and its
adversarial re-check narrowed the question to: *"why does the code never reach a
wait whose expiry would release the line within ~5 s?"*, naming the two deadline
loops at `0xF8E23C` and `0xF8E671`.

`Link_WaitBlockDone` (`0xF8E66D`) is the second of those, and it is published as
prom_b slot `T_F4123C`. `notes/prom_a_converted_callers.py 0xF4123C` — exact for
converted code, because the source rebuilds the ROM byte-identically — finds
**fifteen** call sites, in five separate regions:

| site | preceding call | what it hands the builder |
|---|---|---|
| `0xFAABFB` | `call 0xf40ef0` | src `0x00F80300` — **prom_a's own ROM**, not flash |
| `0xFB24D7` | `call 0xf40ef0` | src `0x00E80000`, count `0x0000` |
| `0xFB256E` | `call SysExXfer_SetPart_SoundBlock` | builder two calls back at `0xFB2560`, src `XIX` |
| `0xFB26D2` | `call 0xf40ef0` | src `0x00EC0000`, count `0x0300` |
| `0xFB2769` | `call SysExXfer_SetPart_CombinationBlock` | builder two calls back at `0xFB275B`, src `XIX` |
| `0xFB6FD1` | `calr SysExTx_AppendContHeaderIfCont` | **no builder anywhere on the path** |
| `0xFC00BE` | `call 0xf40ef0` | src `0x00C00000`, count `0x34` |
| `0xFC0188` | `call 0xf40ef0` | src `0x00C00000 + (0x0878)` |
| `0xFC1C62` | `call CombiName_RequestRead` | builder at `0xFC1CB6`; src `0x00F80300`, `0x00EC0300` or `(0x08E4)+0x300` |
| `0xFC20DF` | `call SoundGroupName_RequestRead` | builder at `0xFC212A` |
| `0xFC219D` | `call CombiGroupName_RequestRead` | builder at `0xFC21E8` |
| `0xFE29EB` | `call 0xf40ef0` | src `0x00E80000`, count `0x2C00` |
| `0xFE2A73` | `call 0xf40ef0` | src `0x00EC0000`, count `0x2C00` |
| `0xFE2B86` | `call 0xf40ef0` | src `XBC`, count `0x2C00` |
| `0xFE2BC6` | `call 0xf40ef0` | src `XBC = XIX` |

**What survives.** Fourteen of the fifteen wait *after a link packet has been
queued through `T_F40EF0`* — nine with the builder as the immediately preceding
call, two with it two calls back in the same basic block, three one call deeper
inside a helper. So the ~1 s deadline that ends in `set 1,(0x13)` is on the
**link block-transfer path in general**.

**What is refuted.** It is not the remote-flash path specifically: four of the
eight literal source bases the checks pin are not flash at all — `0x00F80300` is
prom_a's own ROM and `0x00C00000` is the device window. A machine that never
reads remote flash still reaches this release, through `0xFAABFB`, `0xFC00BE`,
`0xFC0188` or `0xFC1C62`. The reachability argument that gap C was given is gone;
the gap is **open again**, and the observation the driver lane needs is that the
release only ever runs *after a transfer was queued*, so an emulator whose
transfer never completes and whose deadline never expires will hold the line low
regardless of which caller ran.

**Corrected 2026-10-04.** `0x00F80300` is not prom_a's own ROM. It is an address in CPU 2's space, sent in a
link packet: CPU 2's ROM (prom_c, at CPU-2 0xF80000) holds the preset combinations there
(`PromC_PresetBank_Records`; `prom_c/data_tables/preset_bank.s`, READERS). The table row for 0xFAABFB above
makes the same mistake. The sites at 0xF98955, 0xFAABF1 and 0xFC1C86 were spelled `.LF80300`, a prom_a
label with the same number, and now read `PromC_PresetBank_Records`.

> ⚠ **The count moved again on 2026-08-25**, in the same round, when the boot
> block and the two UI screen blocks were converted: **21** call sites, not 15.
> The six new ones are `0xF828A8`, `0xF82981`, `0xF82A45`, `0xF82A6C`,
> `0xF95322` and `0xF9FAFC`, and their sources are `0x00C00000` (the expansion
> board), `0x00FFFFF0` (prom_c's tag, twice) and `0x00F7FFF0` (prom_d's tag) —
> none of them flash. That strengthens the paragraph above rather than changing
> it. `notes/prom_a_converted_callers.py --checks` is the live figure; the table
> above is the 15 that were known when it was written. Only ONE of
> `notes/prom_a_xref.py`'s 22 candidates is still `.incbin`: `0xF98977`.

**What is unknown.** `0xFB6FD1` is the odd one out: it reaches the wait after
`call SysExSession_RepaintProgressIfChanged_Nop` — which is a bare `ret` at `0xFB7E9A`, i.e. a stub — and
`calr SysExTx_AppendContHeaderIfCont`, whose body (`0xFB7025-0xFB703F`) only calls `SysExTx_AppendAndSendOnF7`, a
RAM ring-buffer writer. Nothing on that path touches `0xF40EF0`. What transfer
this site believes is in flight is not established. `INTTC3_LinkDmaDone`'s three
`set` sites remain the other release candidates.

Reproduce: `python3 notes/prom_a_converted_callers.py --checks` (16 checks; C3/C4
are spelled out on the LAST site, `0xFE2BC6`).

## 5. Seven inline jump tables, every entry count from the ROM's own bound

| table | entries | bound instruction | last-entry test |
|---|---:|---|---|
| `0xFB2081` | 6 | `cps bc,0x05 / jr ugt` at `0xFB2070` | base + 24 = `0xFB2099` = entry 0 |
| `0xFB3517` | 7 | `dec 1,WA / cps wa,0x06` at `0xFB3504` | base + 28 = `0xFB3533` = entry 0 |
| `0xFB42D1` | 7 | `dec 1,WA / cps wa,0x06` at `0xFB42BE` | base + 28 = `0xFB42ED` = entry 0 |
| `0xFB6240` | 16 | `cp BC,0x000F` at `0xFB622C` | base + 64 = `0xFB6280` = entry 0 |
| `0xFB62F6` | 16 | `cp BC,0x000F` at `0xFB62E2` | base + 64 = `0xFB6336` = entry 0 |
| `0xFBD25F` | 6 | `cps wa,0x05` at `0xFBD24D` | base + 24 = `0xFBD277` = entry 0 |
| `0xFBD320` | 6 | `cps wa,0x05` at `0xFBD30E` | base + 24 = `0xFBD338` = entry 0 |

The last-entry test is the same one in every row and it is not a tautology: the
table's own size, computed from a bound the reader enforces, has to land exactly
on the address the table's first entry points at. `0xFB6240`'s sixteen targets
run `0xFB6280..0xFB62CB` stepping by exactly 5 bytes.

## 6. ★ The record tables at 0xFB82A0 — and how they were found

Linearly disassembled, `0xFB82A0-0xFB8CA5` looks like plausible code and
round-trips byte-exactly. **The byte gate cannot see the difference.** What saw
it was `notes/prom_a_linear_decode_check.py 0xFB2000 0xFB8CA6 --offenders`
(the `--offenders` listing is new this round): two instructions inside the
module, at `0xFB846A` and `0xFB8770`, "call" addresses that are not instruction
boundaries — and both of those bytes are inside the table. The check is one that
can fail, and did.

> ⚠ **The whole-span verdict, which round 2 did not state (audit F12).**
> `notes/prom_a_linear_decode_check.py 0xFB2000 0xFC0000 --offenders` prints
> `VERDICT: NOT self-consistent` — 72 undecodable `db` bytes and the 2 calls into
> non-boundaries above. It still does, and it always will: the tool decodes
> linearly and has no notion of a `.byte` directive, so any span containing a
> declared table fails it by construction. What makes the residue harmless is
> that **all 74 addresses lie inside data this source declares** — checks L1–L5
> of `notes/prom_a_fb2000_checks.py` intersect the tool's own residue with the
> directive extents of `wsa1_prom_a.s` and assert the intersection is total. Cite
> the verdict together with that account; the round-2 report cited the tool for
> the discovery and left a reader thinking the span passes.

Framing, all of it re-derived:

* `0xFB82A0` two bytes `FB 00` that fit no record;
* `0xFB82A2` **332 six-byte records `[u16][u32]`**, tiling exactly to `0xFB8A69`
  (332 × 6 = 1,992). Every `u32` is an address inside this module; the run stops
  where the first `u32` leaves the module, and that is also where a byte ramp
  begins;
* `0xFB8A6A` a byte ramp `00 01 01 02 03 03 04 05 …` and then values in the
  ASCII range that are not text;
* `0xFB8AAD` onward, records that each hold three module pointers —
  `0x00FB3C6F`/`0x00FB3C70`, `0x00FB3533`/`0x00FB3534` and `0x00FB3949` —
  among small fields. ⚠ The stride is **not** established: the triples recur
  about every 0x21 bytes but not exactly.

Emitted as `.byte` — this tree's honest default — because only the first array's
framing is established. ⚠ Do not promote it to `.long`/`.short` without a reader
that names each array's base and bound.

## 7. ★ The SMF layer

`0xFBA169` carries the ASCII **`MThd`** and **`MTrk`**, the two chunk magics of a
Standard MIDI File, so the `0xFB9000` module is an SMF reader or writer. Nothing
here says which, and no note in this tree has claimed either. The 205-byte block
is written out field by field in its own header; the parts tile it exactly
(8+2+1+16+1+16+64+16+1+16+64 = 205) and the second half is **not** a copy of the
first.

## 8. What is NOT established

* What any of the four modules is FOR, beyond the two flash readers and the SMF
  magics. Most labels are `sub_XXXXXX`, which is an address, not a claim.
* Who calls the two flash readers. `notes/prom_a_xref.py` finds no absolute
  reference to `0xFB248A` or `0xFB24EC`; `Remote_E80000_Read32Blocks` is reached
  by `calr` from `0xFB2483`, inside the same module, and what reaches THAT is
  still `.incbin`. Recorded as a searched negative with the search named.
* Whether the 256 KiB read is a load, a verify or a save. The three UI calls
  around it draw 12-byte display lists from prom_b `0xF4FF10`, `0xF4FF1C` and
  `0xF4FF28`, which are display-list records and not text.
