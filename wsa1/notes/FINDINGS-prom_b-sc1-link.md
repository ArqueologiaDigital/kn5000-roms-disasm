# Serial channel 1 is a whole subsystem in 4 KiB — and it owns three vectors

**Established 2026-08-25, round 1 of the prom_b lane.** Converted:
`prom_b/wsa1_prom_b.s`, `0xF5A800-0xF5B7FF` (4,096 bytes) and
`0xF57D1E-0xF57D4E` (49 bytes). Every number below is reproduced by

```
python3 notes/prom_b_sc1_census.py --selftest      # 44 checks, all of the below
python3 notes/prom_b_thunk_modules.py --selftest   # the thunk-table run
python3 notes/gen_prom_b_sc1_module.py             # the assembly itself
```

and the byte gate (`python3 scripts/analysis/assert_byte_identical.py`)
re-checks all 4,145 converted bytes on every build.

## What this closes

`FINDINGS-interrupt-vectors.md` listed four CPU-1 vectors as "in prom_b — not
this lane". **All four are now converted, and three of them are one device.**

| slot | vector | thunk | body | what it is |
|---|---|---|---|---|
| `0x34` | INT6 | `T_F40F0C` | `0xF5AC0A` | `INT6_SC1_PeerRequest` |
| `0x48` | INTT2 | `T_F40EE0` | `0xF57D45` | `INTT2_Reti` — one byte, `07` |
| `0x68` | INTRX1 | `T_F40F10` | `0xF5ACBB` | `INTRX1_SC1_Dispatch` |
| `0x6C` | INTTX1 | `T_F40F14` | `0xF5AC93` | `INTTX1_SC1_Dispatch` |

Every link of every chain was re-read from the images, not copied from the map.

## The module, and why its boundaries are not a guess

Three independent arguments give the same block, `0xF5A800-0xF5B44D` code plus
`0xF5B44E-0xF5B7FF` fill:

1. **Fill.** 2,982 bytes of `0x00` end at `0xF5A800`; 946 bytes of `0x0E`
   (`ret`, this image's fill convention) run to `0xF5B7FF`. 3,150 + 946 = 4,096:
   **the module is exactly one 4 KiB block.**
2. **The thunk table.** Slots `T_F40F00`-`T_F40F24` are one run bracketed by
   `0E 0E 0E 0E` fill on both sides, and all ten targets are inside the block.
   The first slot is a *pointer*, naming the six-`jp` vtable at `0xF5A800`.
3. **Peripheral ownership.** Over the twelve prefix-group address spellings,
   every real site in either of CPU 1's ROMs that names SC1BUF (13 of them) or
   SC1CR (17) is inside the block.

### A new, measured fact about the thunk table

`FINDINGS-prom_b-thunk-table.md` ended with "Long runs … *look* like one linker
input file per run. Not asserted." `notes/prom_b_thunk_modules.py` now measures
it, reusing the committed `scripts/analysis/prom_b_thunk_table.py` classifier so
the slot counts still reproduce 1,976 `jp` / 26 `ptr` / 2,100 fill:

* the table splits into **100 runs** of non-fill slots;
* **24 of the 26 pointer slots open their run** (the exceptions are `T_F40140`
  and `T_F4176C`);
* **60 of the 100 runs** have every target inside a single 4 KiB span.

⚠ That is a fact about addresses. It is *consistent* with one compilation unit
per run and does not establish it, so the word "module" is used below as a name
for the measured object, not as a conclusion about the toolchain.

## A census gap worth fixing everywhere

`notes/prom_a_addr_census.py` scans twelve address spellings —
`{0xC0,0xD0,0xE0,0xF0}` × `{8-, 16-, 24-bit absolute}`. The TLCS-900 has two
more **direct** forms, and `O_M8` appears at exactly those two entries of
`dasm900.cpp` and nowhere else:

```
opcode 0x08   ld (n8),#8      ../mame/src/devices/cpu/tlcs900/dasm900.cpp:1266
opcode 0x0A   ld (n8),#16     same line
```

Those are the forms firmware uses to **program** an SFR. The consequence is
sharp and is asserted by the selftest:

> The SC1 module contains **twelve BR1CR writes**, all `ld (0x57),#8`, and they
> are the only baud-rate programming in CPU 1's firmware.
> `python3 notes/prom_a_addr_census.py 0x57` reports **no BR1CR instruction
> anywhere in the machine.**

Same for INTE67 (18 writes) and INTES1 (20 writes): all `ld (n8),#8`, all
invisible to the twelve-spelling scan.

⚠ **The wider set costs something, and the script says so.** `08 nn` and `0A nn`
are common bytes inside data, and the convergence filter does not separate those
from instructions — running the fourteen-spelling scan over the whole image
turns up dozens of "hits" inside the display-list banks. So
`notes/prom_b_sc1_census.py` reports **two different kinds of number**: exact
counts inside the module, where the framing is known because the transcription
round-trips; and filtered counts outside it, which rule things out and never
prove anything. ⚠ A fifteenth form, `mnemonic_80[0x19]` = `ld (nn16),(mem)`
(`dasm900.cpp:107`), is scanned by neither script.

Two more residues of the twelve-spelling scan, both ruled out here: prom_a
`0xFF3A14`, `0xFF3A2D` and `0xFF3A71` decode as `cp (0x56),L` / `cp (0x57),L`
with 41-51/64 convergence, and all three are words of a 32-bit pointer table —
they read `0x00FF56C0`, `0x00FF57C0`, `0x00FF57C0`, and their neighbours are a
monotone list of `0xFF54xx-0xFF57xx` addresses. **A regular data table can fool
the convergence heuristic**, which is worth knowing beyond this case.

## How the link works

**Half duplex, driven entirely by interrupt LEVELS.** MAME's `int_reg_w`
(`tmp95c061.cpp:1275-1279`) preserves an INTE register's request flag when a 1
is written to bit 7 / bit 3 and clears it on a 0; `tlcs900_check_irqs`
(`:521-546`) takes the level from bits 6-4 and 2-0 and only ever dispatches
levels 1-6. So the four constants this driver writes mean:

```
INTE67 = 0x85   INT6 level 5                       INT6 armed
INTE67 = 0x8F   INT6 level 7                       INT6 off
INTES1 = 0x50   INTTX1 level 5, INTRX1 level 0     transmit
INTES1 = 0x05   INTTX1 level 0, INTRX1 level 5     receive
INTES1 = 0x55   both level 5                       both
INTES1 = 0xFF   both level 7                       both off
```

The driver flips between `0x50` and `0x05` at every turn of the conversation,
and arms INT6 only while it is idle — which is what makes **INT6 the peer's
request line**, not a data signal.

**The state machine.** `(0x2A80)` is used as a **byte offset**, not an index —
the dispatch is `L=(0x2A80); XHL = 0xF5AC67 + XHL; XHL=(XHL); jp XHL`, with no
shift, and the handlers step it with `inc 4,` / `dec 4,`. The table has **11
entries**, bounded by abutment: `0xF5AC67 + 0x2C` is `0xF5AC93`, the first byte
of `INTTX1_SC1_Dispatch`. States `0x00`, `0x1C` and `0x28` all point at the same
five-byte "this cannot happen" handler.

**The two vectors are one routine, twice.** `INTTX1_SC1_Dispatch` and
`INTRX1_SC1_Dispatch` are 40 bytes each and differ in **exactly one byte**, at
offset `0x1E` — the low half of a `calr` displacement (`0x7F` against `0x57`).
Both displacements resolve to the same target, `0xF5AA32`. So the two handlers
are behaviourally identical; the firmware carries two copies rather than
pointing both vectors at one. (This is the check the brief's "diff the bytes and
state the differing count" rule exists for: 1 of 40, and what the byte is.)

## The RAM, and why every extent is exact

```
0x2A80..0x2A93   20-byte state block (state, expected count, flags, P8CR and
                 P8FC shadows, retry counter, tick snapshot, rx indices)
0x2A94..0x2ADF   rx ring, 76 bytes   0x4C is the modulus of SC1_RxRing_Next
0x2AE0/0x2AE2    tx read / write index
0x2AE4..0x2B1F   tx ring, 60 bytes   0x3C is the modulus of SC1_TxRing_Next
0x2B20..0x2B3F   32 bytes: previous value per group index
0x2B40..0x2B9F   inbound queue: 10-byte descriptor + 86 bytes
0x2BA0..0x2BFF   outbound queue: same shape
```

Every boundary is an **abutment**, not a guess: `0x2A94 + 0x4C = 0x2AE0`,
`0x2AE4 + 0x3C = 0x2B20`, `0x2B20 + 0x20 = 0x2B40`, `0x2B40 + 0x5F + 1 = 0x2BA0`.
And the queue descriptor is self-checking: `SC1_ConfigurePort` writes
low = `0x0A`, high = `0x5F`, count = `0x56`, and `0x5F - 0x0A + 1 = 0x56`, so
`+8` is the **free** count and the indices are offsets from the descriptor base.

## Timing

`(0x80)` is the tick counter `INTT1_Tick` increments (prom_a's own header says
so). At the 488.28 Hz `FINDINGS-system-clock.md` derives for timer 1, the three
tick waits are **4.1 ms, 12.3 ms and 104.4 ms**, and the opening sequence waits
3 × 104 ms before touching the port. The five *spin* delays (2, 6, 10, 100, 500
iterations) are deliberately **not** converted to time: nothing in this tree
measures this loop's cycle count.

## The dead tail

`0xF5B34B-0xF5B44D`, 259 bytes, is unreachable through anything this tree can
see: thunk `T_F40F24` → `0xF5A84B` → `calr 0xF5B34A`, and `0xF5B34A` is a single
`0x0E`, a bare `ret`. `T_F40F24` itself has no caller in either image.

Two further facts, both asserted by the selftest:

* `0xF5B350-0xF5B365` is **byte-identical** to `0xF5B334-0xF5B349`, the live
  `SC1_Queue_Next` / `SC1_Queue_Prev` pair — 22 bytes, all 22 equal;
* **twenty** `calr` displacements in the tail resolve to **six** distinct
  addresses — `0xF5A9B2`, `0xF5AA9B`, `0xF5AAA7`, `0xF5AAB3`, `0xF5AB21`,
  `0xF5B07E` — and **not one of the six is an instruction boundary** of the live
  code. (`0xF5B07E` is one byte inside the instruction at `0xF5B07D`.) The list
  is enumerated, not typed, by section G of the selftest.

Three of those targets are `0x0C` apart — the exact spacing of the five
spin-delay routines — and exactly `0x75` above `SC1_Spin2`, `SC1_Spin6` and
`SC1_Spin10`.

⚠ **"A stale copy of an earlier build, never re-relocated" is the obvious
reading and it is NOT established**: `0x75` does not carry the other three
targets onto anything, so no single uniform shift explains them all. What is
established is the duplicate, the six bad targets, and the unreachability.

## What is NOT established, and what would settle it

* **What is at the other end.** No string, databook or schematic in these trees
  names it. Everything is named after the on-chip peripheral (`SC1_`) or
  positionally.
* **The seven command bytes** the module ever sends first — `0xDD`, `0xDE`,
  `0xDF`, `0xE0`, `0xE2`, `0xE3`, `0xEF` — and their arguments (`0xD2`, `0x1A`,
  `0x03`, `0x80`, `0x00`, `0x08`, `0x10`). Recorded as the literals the ROM
  sends, in ROM order.
* **Which pins.** SC1's signals are on port 8 on this part, and the module owns
  bits 3 and 5 of P8CR/P8FC and reads P8 bit 5 and PB bit 4 as inputs — but no
  databook here names the pins, so "P8.5 is the serial clock" is not asserted.
  (P8 is *not* exclusively this module's: prom_a `0xFA7DDF` clears bit 2.)
* **prom_a `0xF89800`**, reached through thunk `0xF405F0` — the module's only
  call out of itself, made twice inside the receive decoder, and its carry
  result decides whether a decoded byte is kept.
* **One hypothesis, stated as one.** `SC1_RxOp0_ThreeByte` emits, per message,
  the two received bytes plus `old XOR new` for a 32-entry previous-value table,
  i.e. a **change mask over 32 groups of 8 bits**; the link is half duplex with
  a peer request line and an outbound queue. That is the shape of a scanner with
  a small return channel. It is not evidence of *what* is scanned, and this note
  does not name it. What would settle it: a caller of `T_F40F08` in prom_a whose
  surroundings are identified, or `0xF89800`.

## Round 2 — three exit stubs are dead, and the dispatch has no bounds check

Added while closing round-1 audit finding **F16** (semantic labels resting only
on the module's section banner). Both facts fell out of measuring what reaches
each label, which is the thing an Evidence line has to say.

Reproduce all of it with `python3 notes/prom_b_sc1_states.py` (`--exits`,
`--tables`, `--dispatch`, `--branches ADDR ...`, `--writes`, `--selftest`).

### 1. Three of the six interrupt-exit stubs are unreachable

| stub | branches to it | 32-bit ptr | 24-bit ptr | preceded by |
|---|---:|---:|---:|---|
| `SC1_Irq_Exit_1` 0xF5AC58 | 1 | 0 | 0 | falls through from 0xF5AC53 |
| `SC1_Irq_Exit_1_Delayed` 0xF5AC5A | **0** | 0 | 0 | `reti` |
| `SC1_Irq_Exit_3` 0xF5ACA8 | 9 | 0 | 0 | `jp XHL` |
| `SC1_Irq_Exit_3_Delayed` 0xF5ACAC | **0** | 0 | 0 | `reti` |
| `SC1_Irq_Exit_3b` 0xF5ACD0 | 4 | 0 | 0 | `jp XHL` |
| `SC1_Irq_Exit_3b_Delayed` 0xF5ACD4 | **0** | 0 | 0 | `reti` |

The branch counts are read off each branch's **resolved** target as printed in
the verified transcription, so no displacement arithmetic of this script's own
enters the result. The pointer columns scan both of CPU 1's ROMs at **every**
byte offset, which can only over-count — so zero is a real zero. Each
`_Delayed` stub is preceded by a `reti`, so fall-through is out too.

That is three dead exit stubs in one module. Each would have cleared P5 bit 3,
spun, set it again, then popped and RETI'd.

⚠ **Not established:** why. This is the *second* dead region in the module —
`SC1_DeadTail` is the first — but nothing here connects them, and "left over
from an earlier build" remains a guess, exactly as it does for the tail.

This **corrects** the `INTTX1_SC1_Dispatch` header, which said each dispatcher
"is followed by two exit stubs that the state handlers jump back to". Only the
first of each pair is jumped to.

### 2. The `_Delayed` twins repeat the dispatchers' one-byte difference

`SC1_Irq_Exit_3` and `SC1_Irq_Exit_3b` are 4 bytes each and **0 of 4** differ.
The two `_Delayed` stubs are 15 bytes each and differ in **exactly 1** — offset
5, the low half of a `calr` displacement (0x7F vs 0x57) — and **both resolve to
0xF5AA32**, `SC1_Spin6`. That is the same relocation-only difference the census
already measures between `INTTX1_SC1_Dispatch` and `INTRX1_SC1_Dispatch`
(1 differing byte in 40, byte 30, both resolving to 0xF5AA32). Asserted by
`--selftest`, which fails if either count moves.

### 3. The state dispatch is UNCHECKED

`--dispatch` lists every instruction between the state load and the indirect
jump in both handlers:

```
push XWA / push XHL / push XIY / ld L,(0x2a80) / xor H,H / extz XHL
/ add XHL,0x00f5ac67 / ld XHL,(XHL) / jp T,XHL
```

No compare, no branch. A state byte above 0x28 indexes past `SC1_StateTable`
into the dispatcher's own code. The only guard the module has is that three of
the eleven slots — [0], [7] and [10] — point at `SC1_State_Unexpected`.

The state byte is written as an immediate at seven sites and only ever takes
**0x00, 0x04, 0x20**; every other value is reached by `inc 4,(0x2A80)` or
`dec 4,(0x2A80)`. ⚠ Do **not** read the eleven-value range that follows as
"all eleven states occur": the module contains **both** step directions, so the
closure over them is the whole range whatever the handlers do. `reachable()`
says so in its own docstring and the printout repeats it. Nothing in this tree
executes the firmware.

### 4. All three dispatch tables, mapped index → address → label

`--tables` reads every pointer out of the ROM and resolves it to the label this
`.s` puts at that address, so the mapping in the headers is read, not typed.

| table | extent | entries | distinct targets | upper bound abuts |
|---|---|---:|---:|---|
| `SC1_StateTable` | 0xF5AC67-0xF5AC92 | 11 | 9 | `INTTX1_SC1_Dispatch` |
| `SC1_RxOpTable` | 0xF5B0B5-0xF5B0D4 | 8 | 4 | `SC1_RxOp0_ThreeByte` |
| `SC1_TxOpTable` | 0xF5B299-0xF5B2A8 | 4 | 2 | `SC1_TxOp0_TwoByte` |

Every extent is **abutment**, nothing stronger. Last-entry tests, asserted by
`--selftest`: `SC1_StateTable` entry [10] is at 0xF5AC8F, holds 0x00F5AFD3 and
is state 0x28; entries [0], [7] and [10] are one target.

### 5. `SC1_TxFlush_Exit` is a shared epilogue, and its name understates it

Seven branches reach `ei 0x00 / ret` at 0xF5B05D. **Five** are
`SC1_TxFlush_Body`'s bail-outs; **two** — 0xF5AB89 and 0xF5AB90 — are inside
`SC1_WaitTxDrain`, which uses it as its own return path. The name is
positional (it sits at the end of `SC1_TxFlush_Body`), not a statement of
ownership, and the header now says so.

### 6. The two run encoders do NOT obviously agree

`SC1_RxOp6_Run` computes `(b & 0x0F) + 1` **items** and requires
`(b & 0x0F) + 3` **bytes** pending. `SC1_TxOp3_Run` emits the header byte plus
`(b & 0x0F) + 2` **bytes**. Different expressions over the same nibble, in
different units. ⚠ This tree has **not** reconciled them; do not assume the two
codecs are inverses of one another.

## Round 4 (2026-08-25) — the serial registers' actual contents

This answers items **E.1** and **E.2** of
`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`, which asked what immediate the
twelve BR1CR writes carry and whether SC1 is a UART at all. §"A census gap worth
fixing everywhere" above established the instruction FORM and explicitly did not
give the values; here they are, read off the proven transcription rather than off
a byte scan:

⚠ **CORRECTED 2026-08-25 (round-1 audit finding 1): this is a REPLICATION, not a
closure.** This section was written against the 13-entry version of the gaps file
(`kn7000_mame` commit `26aa1c6`, 09:20). The driver lane closed gap E the same
day in `1a96510` (12:09), before this was finished, and its §E sub-answers 1 and
2 give the *same* values from the *other* side of the machine: BR1CR `0x22`×4 /
`0x24`×5 / `0x28`×3, one prescaler tap, and `SC1MOD = 0x00` at `0xF5A8AF` =
I/O-interface mode. Two lanes reading different evidence — a transcription census
here, the driver's own SC1 model there — landed on bit-identical answers and
neither knew of the other. That is worth more than a duplicate "closed", and it
is the only honest headline for this section.

    python3 notes/prom_b_sc1_serial_regs.py
    python3 notes/prom_b_sc1_serial_regs.py --sites

| register | whole-byte writes | bit operations |
|---|---|---|
| SC1MOD (0x56) | **one**: `ld (0x56),0x00` at 0xF5A8AF | 7, all on bit 5 (`or 0x20` ×1, `and 0xDF` ×6) |
| BR1CR (0x57) | **twelve**: `0x22` ×4, `0x24` ×5, `0x28` ×3 | none |
| SC1CR (0x55) | one: `ld (0x55),0x01` at 0xF5A8B5 | 17, on bits 0 and 1 |
| SC1BUF (0x54) | — | — (11 `ld (0x54),A` stores, 2 `ld A,(0x54)` loads) |

### E.2 — SC1 is **NOT** a UART

`SCxMOD` on this part is
`| 7 TB8 | 6 CTSE | 5 RXE | 4 WU | 3 SM1 | 2 SM0 | 1 SC1 | 0 SC0 |`, with
SM = 0 I/O interface (clocked synchronous) / 1 seven-bit UART / 2 eight-bit UART
/ 3 nine-bit UART.

⚠ That layout is **not** taken from a datasheet nobody in this tree has. It is
pinned on this machine: `FINDINGS-system-clock.md` reads CPU 2's
`ldio SC0MOD,0x29` at 0xF991B3 as "8-bit UART, baud-rate generator", and that
reading is what makes MIDI come out at 31,250 baud with fc = 28 MHz — a figure
lever B of that note reaches independently of the UART. Under this layout 0x29
gives SM = 2 and SC = 1, exactly that. Under the competing layout (SM at bits
2-1, SC at bits 4-3) the same byte would configure an I/O-interface port and MIDI
would not work. The same field split is what
`kn7000_mame/src/devices/cpu/tlcs900/tmp94c241_serial.cpp` uses on the sibling
part (`mode = (m_serial_mode >> 2) & 3`).

So **SC1MOD = 0x00 ⇒ SM = 0: I/O INTERFACE MODE**, i.e. clocked synchronous with
a separate clock line — not an asynchronous UART. SC = 0 selects the
timer-output trigger rather than the baud-rate generator. RXE (bit 5) starts
clear, and the seven bit operations are receive-enable toggles: the module turns
its receiver **on at one site and off at six**, which is what half duplex looks
like from the software side and is consistent with the peer-request line INT6
this note already describes.

`SC1CR = 0x01` sets **IOC = 1, i.e. SCLK is an INPUT**: at reset the peer
supplies the clock. The 17 later bit operations move bit 0 (IOC) and bit 1
(SCLKS, clock edge) — the module switches between sourcing and receiving the
clock as the direction turns.

### E.1 — the twelve BR1CR immediates

`BRxCR` is `| 7 – | 6 ADDE | 5 CK1 | 4 CK0 | 3..0 divisor N |`. All twelve writes
carry ADDE = 0 and **the same prescaler tap, CK = 0b10**; only the divisor
changes:

| value | sites | N |
|---|---|---|
| 0x22 | 0xF5A8B2 0xF5AD92 0xF5ADF7 0xF5B386 | 2 |
| 0x24 | 0xF5ACEF 0xF5AD23 0xF5AD49 0xF5AD78 0xF5AEC9 | 4 |
| 0x28 | 0xF5ABD9 0xF5AE93 0xF5B030 | 8 |

So the link runs at **three rates in the ratio 4 : 2 : 1**, selected per
operation, off one prescaler tap.

⚠ **The absolute bit rate is still not established, and this note does not give
one.** It needs the divide ratio of tap 0b10 for this part. The only figure the
tree has is the *other* tap: `FINDINGS-system-clock.md` shows BR0CR with CK = 0b00
and N = 14 producing 31,250 baud at fc = 28 MHz with the UART's ×16
oversampling, which pins tap 00 = fc/4 and nothing else. MAME's own `tmp95c061`
prescaler cannot be used as the authority — `WSA1-EMULATION-DISASM-GAPS.md`
appendix item 2 records that its taps are 16× slow. What would settle it: a
TMP95C061 databook, or a measurement on the real machine.

`prom_b_sc1_serial_regs.py` asserts all four of the load-bearing facts (twelve
BR1CR writes; one tap across all twelve; SC1MOD written whole exactly once; that
value's SM field = 0) and exits non-zero if any fails, so a later change that
breaks one is visible.

