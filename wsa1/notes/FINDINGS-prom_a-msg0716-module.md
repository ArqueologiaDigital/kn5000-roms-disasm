# prom_a 0xFC0000 and 0xFC8000: two modules, one RAM record ladder

Round 3, 2026-08-25. Both modules were chosen by `notes/prom_a_call_graph.py
--modules`, which ranks prom_b directory modules by the total reference upper
bound of their slots. They were second and third; the first
(`T_F40F34-T_F40F50`, 125) was **not** taken and the reason is in "What was left"
below.

Everything quantified here is re-derived by two committed scripts:

```
python3 notes/prom_a_fc0000_module_check.py --selftest    # 128 checks, 3 controls
python3 notes/prom_a_fc8000_module_check.py --selftest    #  77 checks, 4 controls
```

Both print their own check count as their last line; that is the only figure to
quote from them. Both read the ROMs, not the listing.

---

## 1. 0xFC0000-0xFC2FFF — the 0x0716 message module

9,710 substantive bytes plus a 2,578-byte `0x0E` pad. It carries **165 of the
directory's prom_a slots and 164 distinct targets — more than any other 12 KiB
of the image.**

Its bounds are the ROM's: 44 bytes of `0x0E` before it, 2,578 after, and the
longest `0x0E` run strictly inside it is 11 bytes.

### The mechanism, in three interlocking parts

**An index dispatcher, twice.** 0xFC0990 and 0xFC09AF are byte-identical over 31
bytes (byte 32 differs, so 31 is maximal):

```
ld L,(0x20b8)      ; the index
cp L,A             ; A = the page's highest legal index
jr UGT, ret
and (0x070f),0xfd  ; clear bit 1 of the flag byte
ld XIX,0x00000716  ; the message staging buffer
xor H,H
sla 0x02,HL
ld XWA,(XIY+HL)    ; handler[index]
call T,XWA
```

72 callers have the full `ld XIY,base / ld A,limit / calr dispatcher` shape —
exactly the 64 + 8 `calr` sites the two dispatchers have.

**Ten handler tables that tile 0xFC09CE-0xFC0BD9 exactly.**

| base | highest index | entries | ends at | dispatcher |
|---|---|---|---|---|
| 0xFC09CE | 0x0D | 14 | 0xFC0A06 | 0xFC0990 |
| 0xFC0A06 | 0x1A | 27 | 0xFC0A72 | 0xFC0990 |
| 0xFC0A72 | 0x06 | 7 | 0xFC0A8E | 0xFC09AF |
| 0xFC0A8E | 0x0D | 14 | 0xFC0AC6 | 0xFC09AF |
| 0xFC0AC6 | 0x07 | 8 | 0xFC0AE6 | 0xFC09AF |
| 0xFC0AE6 | 0x02 | 3 | 0xFC0AF2 | 0xFC09AF |
| 0xFC0AF2 | 0x0E | 15 | 0xFC0B2E | 0xFC09AF |
| 0xFC0B2E | 0x04 | 5 | 0xFC0B42 | 0xFC09AF |
| 0xFC0B42 | 0x13 | 20 | 0xFC0B92 | 0xFC09AF |
| 0xFC0B92 | 0x11 | 18 | 0xFC0BDA | 0xFC09AF |

**The last-entry test.** 14+27+7+14+8+3+15+5+20+18 = 131, and
0xFC09CE + 131×4 = **0xFC0BDA, which is the value of entry 0** — the table ends
exactly where the first routine it points at begins. A 132nd entry would read
that routine's first four bytes. The count comes from ten independent `cp L,A`
bounds; nothing was counted by eye. The ten declarations are *parsed out of the
decode* by the check script, so an eleventh caller or a changed literal fails
instead of passing for ever.

Only **50** of the 131 entries are distinct: 0xFC0CE2 appears twenty times in a
row, 0xFC0E20 eighteen, 0xFC0E52 fourteen.

**Every handler posts to CPU 2.** Handlers build a short byte message at RAM
0x0716 and call one of two senders whose fifteen shared bytes differ at exactly
one offset — the pushed stream word, 0x00 at 0xFC1A1E and 0x01 at 0xFC1B09.
That word reaches prom_a 0xF8E0A7 (`sll c,0x05`) and becomes bits 5-7 of the
byte written to the link port at 0xF8E0AF/0xF8E0B7, so it selects one of eight
link streams. 0xFC1A1A is a four-byte `calr`-and-return trampoline onto the
first, and it is what the module actually calls — 30 times, against 1 direct
call on the callee.

### The two data tables

**32 object records of 8 bytes at 0xFC0890**, asserted on all 32 including the
last: `+0 = 8n mod 256`, `+1 = 0x06`, `+2..3 = 0`, `+4..5 = 1 << (n mod 16)`,
`+6 = n`, `+7 = 0x0E`. Field +6 indexes the pointer table below. A 33rd record
would start at 0xFC0990, the dispatcher. The module forms record addresses with
`ld XIZ,imm32` at 32 sites, the lowest 0xFC0890 and the highest 0xFC0988, all
8-byte aligned, and **there is no `ld XIZ,imm32` in the module pointing anywhere
else at all.**

**32 RAM record pointers at 0xFC1162**, entry k = 0x76A2 + 0x40k — with one
exception: the step from entry 7 to entry 8 is 0x80, so **0x78A2 is skipped**.
0x78A2 is not unused: it is named directly, by absolute address, at six sites in
this module, more often than any other address in 0x7600-0x7EFF. Last-entry
test: entry 31 is 0x7EA2 and the four bytes a 33rd would occupy are 0x03020100,
the start of the 0x00..0x18 ramp that follows.

### What is *not* established

**Answered in part, 2026-10-04** (`notes/prom_a_msg0716_message_names.py`). The messages are
MIDI-shaped. The builders at 0xFC151B-0xFC19FF write status 0xB0, the part number the handler
stored in byte 1 (the object record's +6), a controller number, and the UI event's value. They are
named by controller: `Msg0716_PostCC07_Volume`, `_PostCC5B_Effect1Depth`, `_PostCC40_Sustain` and
so on (MIDI 1.0 numbers). Numbers 0x80 and above are not MIDI controllers and keep the number
(`Msg0716_PostCtrl80`). Status 0xD0 is Channel Pressure, and `F0 50 cmd` is a system-exclusive
message with Matsushita's manufacturer ID (`Msg0716_PostSysEx50_<cmd>`, command meaning open).
The three value tails are `Msg0716_PostValueMasked` / `_AsSwitch` / `_Clamped`. Handler-table
entries that only store the part and call one builder are `Msg0716_Part<builder>`. What selects a
handler, the index (0x20B8), is still not established.


**Program changes are deferred (2026-10-04).** An object record's +0..+3 is the address of the part's 8-byte RAM slot
0x0600 + 8n (+0 = 8n, +1 = 0x06), and +4..+5 is its bit.

- `Msg0716_PartSetProgramLow` / `_High` (table 0, entries 0 and 1) post nothing. They store UiEvent_Byte2 into the
  slot's +0 / +1, OR the part's bit into (0x0700) (parts 0..15) or (0x0702) (parts 16..31), and set (0x070F) bit 0.
- `Msg0716_FlushIfPending` (thunk `T_Msg0716_FlushIfPending`) sees that bit and runs `Msg0716_FlushPending`.
- `Msg0716_FlushPending` sends, for every marked part, `Msg0716_PartPostCC78_AllSoundOff` and then
  `Msg0716_PartPostProgramChange`. The second is `C0 <part> <slot +0..+1> 00`, a 16-bit program number.
- So a part whose program is edited is silenced and re-programmed once per pass, however many bytes changed.
- `Msg0716_PartSetVolume` keeps the part's volume in slot +6, which `Msg0716_RepostPart0Volume` re-sends for part 0.
- Table 3 is the scale-tuning page: entry 0 is `Msg0716_ScaleTuningPostTypeAndSemitones`, entries 2..13 are the
  twelve semitones (`Msg0716_ScaleTuningPostSemitone`). Evidence per routine: the rows of
  `notes/prom_ab_read_names_2026_10_04.py`.

What any handler does. The four strings — `Sound Name *****`, `Combi Name *****`,
`Combi Group Name`, `EXT Silent Group` — are the only words in the module and
**every one of them is a fallback**, loaded only when a pointer compares equal to
an all-ones sentinel or a bit is clear. They name the object, not the routine.
That is why the module's prefix is the address-derived `Msg0716_` and not
`ParamEdit_`, which is what the first draft used.

0x00C00000, which 0xFC0076 passes to the link layer and adds to two 16-bit
offsets at RAM 0x0874 and 0x087C, is **not** dereferenced anywhere in prom_a or
prom_b — zero hits over all twelve absolute-address spellings. So it is an
address in the other CPU's space, and on CPU 2 0x00C00000 is the expansion board
(`FINDINGS-memory-map.md` row F5). That the two are the same 0xC00000 is an
inference from where the argument goes, not something this module says.

---

## 2. 0xFC8000-0xFCEFFF — the RAM-0x3800 module

18,559 substantive bytes; the 10,113-byte `0x0E` run after it is `.fill` and is
not in that figure. 20 directory slots.

**It carries its own C-runtime initialiser, and that is what makes the module
readable.** 0xFC8020 is four linker-shaped blocks:

| guard | length | source | destination | kind |
|---|---|---|---|---|
| `ld XBC,0x00000b66` | 2,918 | 0xFCB3D3 | 0x003800 | `ldir` |
| `ld XBC,0x00000000` | 0 | — | 0x000000 | zero fill |
| `ld XBC,0x000000a0` | 160 | 0xFCBF39 | 0x602054 | `ldir` |
| `ld XBC,0x00000054` | 84 | — | 0x602000 | zero fill |

Each block is guarded by `and XBC,XBC / jr Z` **over the constant it just
loaded** — a hand-written loop does not test a constant it just loaded. So the
module's RAM (0x003800-0x004365 and 0x602000-0x6020F3) and its ROM data image
(0xFCB3D3-0xFCBFD8) are read off the immediates rather than guessed, and the two
images abut with no slack: 0xFCB3D3 + 0xB66 = 0xFCBF39 and 0xFCBF39 + 0xA0 =
0xFCBFD9.

0xFC807D is byte-identical to 0xFC8020 over **46** bytes and no further (byte 47
is 0x41 there and 0x0E here): the short copy reloads the 0x3800 image alone. It
is the one the directory publishes, as **T_F413D0**; the full initialiser is
published by no slot at all.

**⚠ A correction made before this shipped.** The first draft of that paragraph
said T_MidiInA_ProcessRing and called it "the module's highest reference count". T_MidiInA_ProcessRing is
the module's *first* slot and targets 0xFC80E2; T_F413D0 is the one that targets
0xFC807D, and its bound is 1. The 52 that `--modules` ranks by is the module
*total*; the busiest single slot is T_F413C8 at 11. The check script now pins
all three.

**Nine-entry inline jump table at 0xFC8DB2**, count from the reader's own
`cp BC,0x0008` and `sll 0x02,BC`, last-entry test from
0xFC8DB2 + 9×4 = 0xFC8DD6 = the value of entry 0.
`notes/prom_a_jumptables.py` finds it independently and agrees on all six
numbers; it is the only inline jump table in the module.

**A second copy of the record ladder, capped differently.** 0xFCBFEA holds 32
entries: 0..24 are the same 0x76A2 + 0x40k ladder with the same single 0x80 step
over 0x78A2, and 25..31 are all 0x76A2 — the first record again. So the two
tables are *not* copies: 0xFC1162 runs the ladder to 0x7EA2, this one stops at
0x7CE2 and pads. **The 32 records of 0x40 bytes at RAM 0x76A2 are shared between
the two modules**, and that is the only structural link between them that this
round established.

**What it talks to.** Every external call is through the directory, and all but
three targets are already converted, so they can be named:
`Ring60080A_Scan` ×5 and `_ScanRewind`, `Ring600A14_PutBlock`,
`Ring600C1E_Scan` ×3 and `_ScanRewind`, `Ring601028_Scan` ×3 and `_ScanRewind`,
`Ring601432_PutBlock` ×3, `Ring60153C_PutBlock` ×3, `Ring601850_Get` ×2,
`MIDI_PostSendWork` ×3, and the link block sender ×10. Seven distinct ring
objects, three scanned and three written by block — the shape of something that
parses one stream and emits into others. Which ring carries what is *not*
established: those are the ring objects' names, and they say which RAM object is
touched, not what travels through it.

**⚠ One byte is not accounted for.** 0xFCC06A is 0xEE — the XIZ prefix of the
32-bit register group — followed by 0x02, which that group does not define, so
`EE 02` is not an instruction unidasm can decode. It is the only undecodable
byte in the module outside the declared data. The listing resumes code at
0xFCC06B, from where the decode is clean to the pad and all four in-span `call`
targets are boundaries of it — **but 0xFCC06B is not pinned**: decodes begun at
0xFCC06C, 0xFCC06E and 0xFCC070 resynchronise and are equally clean. The gate is
indifferent (whatever is decoded is re-assembled); a reader should not take
0xFCC06B for a routine entry.

---

## 3. The frontier tool over-counts, and here is by how much

`notes/prom_a_call_graph.py`'s slot counts are honest about being *slot* counts
and about their reference numbers being upper bounds. This round measured two
further ways a slot is not a routine, both inside 0xFC0000-0xFC2FFF:

**34 of the 164 published targets are a bare `ret`.** Their first byte is 0x0E,
and the runs they sit in are shorter than the 32-byte floor at which
`gen_prom_a_block.py` emits `.fill`, so they survive as `ret` instructions in the
listing and do take labels. More than a fifth of the span's published entry
points do nothing.

**Five published targets are not instruction boundaries at all.** T_F41184,
T_F4118C, T_F41190, T_F41194 and T_F41198 are well-formed `jp 0xFC04xx`
instructions, but 0xFC0427, 0xFC043D, 0xFC0452, 0xFC0453 and 0xFC0454 all lie
*inside* the 16-byte dispatcher veneers at 0xFC0420-0xFC0460. prom_c is not an
alternative reading — its bytes at those addresses decode to unrelated
fragments. All five have a reference upper bound of zero and each is published by
exactly one slot. `gen_prom_a_block.py` refused to place a label at any of them
and printed all five on stderr; the other nine labels it dropped in this span
were `all_refs()` opcode coincidences, and none of those nine is a directory
slot.

**⚠ And "retired" means two different things.**
`notes/prom_a_frontier_delta.py` counts all 164 targets of the span retired,
these five included, because *retired* there means the bytes left an `.incbin` —
which they did. It does **not** mean a symbol exists. Anyone following T_F41184
across finds the byte only through the address column of the listing. This is the
span where the two senses diverge, and it is worth remembering the next time a
round report quotes a "targets retired" figure.

---

## What was left, and why

**`T_F40F34-T_F40F50` (8 slots, bound 125), prom_a's top-ranked module,
0xF86066-0xF86AE9.** It is inside a single 23 KiB `.incbin`, and its own extent
is 0xF86000-0xF8969A
with **no `0x0E` run of five bytes or more anywhere in it**, so the module has no
readable end short of 13,979 bytes, and a linear decode of it hits 408
undecodable bytes in twelve clusters — one spanning 1,020 bytes and one spanning
3,553. Carving those data regions honestly is a round's work on its own, and the
whole 13,979 bytes carry only 24 directory slots and 23 distinct targets, against the
165 and 164 in 0xFC0000. All four figures are section 10 of
`notes/prom_a_fc0000_module_check.py`, so this paragraph is a measurement and not
an excuse. It is
the obvious next target for a round that starts with the data carve rather than
ending with it.

**The 4,096-byte `0x0E` run at 0xFC7000-0xFC7FFF** is still `.incbin` on purpose.
Converting it would add 4,096 bytes to a filler column and nothing to a
substantive one.

---

## The round's numbers, and how to reproduce them

| | before round 3 | after | delta |
|---|---:|---:|---:|
| prom_a substantive | 61,239 | 89,508 | **+28,269** |
| prom_a filler (`.fill`) | 10,078 | 22,769 | +12,691 |
| prom_a `.incbin` bytes | 452,971 | 412,011 | −40,960 |
| prom_a directory slots still `.incbin` | 946 | 761 | **−185** |
| prom_a distinct targets still `.incbin` | 893 | 709 | **−184** |
| prom_a real `.incbin` directives | 15 | **17** | **+2** |

```
python3 scripts/analysis/source_coverage.py
python3 notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree
```

⚠ **The span count went UP, and that is the honest cost of these two targets.**
Both modules sit in the middle of a large `.incbin`, so each split one span into
two. The round-3 brief said large contiguous blocks "close `.incbin` spans
instead of fragmenting them"; these two did the opposite, and they were still the
right targets — 185 slots left the frontier — but the claim and the measurement
should not be confused.

Nothing in this document was measured from the listing. The listing was generated
from `notes/prom_a_block_headers.txt` by `notes/gen_prom_a_block.py`, which takes
every instruction from `prom_a/roundtrip.py` and therefore cannot break the byte
gate; the numbers come from the two check scripts, which read the ROMs.
