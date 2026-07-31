# AUDIT — the DELAY-DRAM notes against the uPD6383 MAME device

**Date 2026-07-31. Offline, read-only.** No emulator, no rebuild, no source edit. The only file
written by this pass is this one.

**Files audited (mine):** `r3-delaydram.md`, `k4-cursor.md`, `dram-bounds.md`,
`dram-direction.md`, `dram-datapath.md`, `dram-matching.md`, `adjudication-round5.md`.
**Device audited:** `/home/fsanches/compartilhado/kn7000_mame/src/devices/cpu/upd6383/upd6383.cpp`
(mtime 2026-07-31 03:25), `upd6383.h`, `upd6383d.h`, `upd6383d.cpp`. All quotes below are from the
**current** source, re-read for this pass, not from any note's copy of it.

**Shipped default mask** `0xB910E446A39B440F` → bits ON:
`0 1 2 3 10 14 16 17 19 20 23 24 25 29 31 33 34 38 42 45 46 47 52 56 59 60 61 63`.
Bits **9** and **12** are OFF; both matter below.

**POPULATION WARNINGS (method rule 9), carried through every row:**
* Algorithms **79, 88, 89, 90, 91** are programs for **IC310/MN19413**, a different chip. Nothing
  here uses an "all 100 algorithms" statistic without saying so. The corpora used are: 91
  algorithms that ship descriptor cells, **83** with `#cells == #consumers` (829 cells), 38
  distinct body images.
* `dram-bounds`/`round5`/`dram-direction` all share that 83/829 population; `r3` uses 100
  algorithms / 870 cells for the *region* claim only.

**Grades used:** MEASURED (I measured it in this pass), FORCED (arithmetic leaves no alternative),
INFERRED, SPECULATIVE. Where I could not verify something I say so.

---

## 0. Headline

Three FORCED claims with operational content are **not in the device**, and all three sit on the
*same six lines of code* — the delay-DRAM address generator at `upd6383.cpp:1850-1882`. Two of them
have hard independent controls; the third has an arithmetic one.

| rank | claim | verdict | control |
|---|---|---|---|
| **1** | **the rotation sign**: `delay = READ_CELL − WRITE_CELL` (round5 §3) is arithmetically incompatible with the device's `addr = cell + G`, `G` counting **up** | **MISMATCH** | ★ **YES** — the host evaluator, PROVEN BY CONSTRUCTION; and the device's own disassembler string |
| **2** | **the map is per-BODY**: the k-th consumer *of a body* takes the k-th cell *of that body's own block* (round5 B, FORCED) — unit-0 blocks at `0x26`, unit-1 at `0x00` (r3 P5) | **ABSENT** | ★ **YES** — §189's own live bank readout, matched to the ROM in §4 below |
| **3** | **`C40.1.80.000` consumes a descriptor cell** (r3 §6.1, in every one of the 8 exact solutions) | **ABSENT** | ★ **YES** — arithmetic: 28 + 4 = 32 = *n*, verified from the .dsm in §3.3 |

A fourth, smaller one (K3/K4-FORCED, mask bit 12) is IMPLEMENTED-BUT-OFF.

**And a bonus that closes a flagged OPEN item:** §189/§190's "P16's ladder is not in the live bank,
0 of 6 either way" is **RESOLVED** — the live cold-boot unit-1 preset is **CONCERT REVERB 1
(algo 20)**, and its ROM ladder reproduces §189's measured chain **10 of 10, exactly, in order**
(§4). §189 was searching for ROOM REVERB 1's *`i+1`* ladder, which `dram-matching.md` A retracted
and round5 H/I superseded. This required no new instrument, only the corrected pairing.

---

## 1. The classification table

Only claims graded PROVEN BY CONSTRUCTION / FORCED **with operational content** (a field width, a
bit position, an address map, a direction rule, a memory extent, a cursor rule). Method-only and
unknown-only claims are skipped, as are CONSISTENT/INFERRED ones except where noted.

| # | claim (source) | note grade | device | verdict | independent control? |
|---|---|---|---|---|---|
| **A1** | payload `V = ((aa&0x7F)<<17)\|(bb<<9)\|(cc<<1)\|(dd>>7)` — r3 **P2**, k5 item 9, k3 §1.1 | PROVEN BY CONSTRUCTION | `upd6383.cpp:906` `v = (v<<1)&0xffffff` (bit 31 ON) + `:927-931` `if (m_poke[4]&0x80) v \|= 1;` (bit 63 ON) | **IMPLEMENTED** | n/a (already shipped, §188, bit-exact against the LFO sine) |
| **A2** | the descriptor bank is its **own space**, tag `0x4C` through pointer `…825` — r3 **P1** | PROVEN BY CONSTRUCTION | `:960-963` `case 0x4c: m_dscbank[m_dsc_wp] = u16(v & 0xffff);` and `:983` `if (lo == 0x825) { m_dsc_wp = ad; }` | **IMPLEMENTED** | n/a |
| **A3** | delay map `[0x0000,0x10000)`, max address 64 899, 16 bits suffice — r3 **P5**, MEASURED 870 cells | MEASURED | `m_dscbank` is `u16[256]` (`upd6383.h:931`); `addr … & 0xffff` (`:1882`) | **IMPLEMENTED** | §190 already re-checked this and killed the "24→16 truncation" suspicion; dead-end #17 |
| **A4** | `addr8` bit 6 is the delay-DRAM direction **field**, nothing else can carry it — `dram-direction` **B** (exhaustive, 36 bits, one survivor) | FORCED | `upd6383d.h:814` `dram_dir(w) = (addr8==0x20\|\|addr8==0x30) ? 'R' : (addr8==0x60) ? 'W' : 0` | **IMPLEMENTED** | n/a |
| **A5** | polarity: `0x20/0x30 = READ`, `0x60 = WRITE` — round5 **D**, two independent routes | FORCED | same line; and `upd6383d.cpp:432-455` carries the full provenance in the past tense ("the REVERSE of what this file used to print") | **IMPLEMENTED** | n/a |
| **A6** | scope: `C40.1.80.000` (addr8 `0x80`) is outside the validated set and keeps trapping — round5 §3 SCOPE | FORCED | `upd6383d.h:811` `is_dram` carries `&& !c_format(w)`; `dram_dir` returns 0 otherwise | **IMPLEMENTED** *(but see **C3** — it must still consume a cell)* | — |
| **A7** | only `class4 == 0xA` advances the coefficient cursor; `class4 == 8` fetches but must **not** advance — k4 item **I** | FORCED | `upd6383d.h:841` `coeff_consumer(w) = class4(w)==0xa && !c_format(w)`; `:869` `coeff_fetch(w) = (class4(w)&8) && !c_format(w)` — split, with K4 cited | **IMPLEMENTED** | n/a |
| **A8** | there **is** a per-unit coefficient-BASE register; base is `0x00` for a body at I-RAM 84 and `0x90` for one at 200; it follows the **unit**, not the program — k4 **A/B/C/D/E/H**, §6.3 | FORCED | `upd6383.cpp:4473-4477` `if (m_specmask & 0x4000000000ull) { m_cursor = unit1 ? 0x90 : 0x00; }` — **bit 38, ON** | **IMPLEMENTED** | n/a |
| **A9** | C-RAM is one flat 256-cell space; the resident table `0x50..0x8B` straddles `0x80`; a 1-bit bank on address bit 7 is impossible — k4 **E/F** | FORCED / FALSIFICATION | no bit-7 C-RAM banking anywhere; unit 1 is `0x90` (A8) | **IMPLEMENTED** (by absence of the refuted mechanism) | — |
| **A10** | class-1 **register file** is displaced `+0x80` per unit (428/428) — k4 **G** | MEASURED + PROVEN BY CONSTRUCTION | `upd6383.h:281` `DRAM_UNIT_STRIDE = 0x80; // FORCED: E1 - E0, = R2's unit bit` | **IMPLEMENTED** | — |
| **A11** | C-RAM `0x50..0x8B` holds 60 resident constants no algorithm rewrites; a core that replays only parameter streams reads zeros — k4 §6.4 item 4 | practical, from PROVEN | the emulated Sub CPU writes them for real: `:965-972` `case 0x26:` → `m_cram.write_dword(m_cram_wp, …)`, pointer from `801.0.NN.821` at `:984` | **IMPLEMENTED** (the real host runs; no preload needed) | — |
| **B1** | **do NOT model `801.0.NN.821` as writing the coefficient cursor** — k4 §6.2 (FORCED; K3 item F sharper) | FORCED | `upd6383.cpp:3656-3668` `if (m_speculative) if (!(m_specmask & 0x1000)) m_cursor = ad;` — bit 12 is **OFF**, so the seeding **is live**. The comment above it says so: *"⛔ STILL AGAINST K3, which proves 0x21 is NOT the implicit cursor."* | **IMPLEMENTED-BUT-OFF — mask bit 12** (set bit 12 to obey K3/K4) | partial: A8's CALL rebase runs *after* both in-body `ldptr`s (iw42 < CALL 49, iw50 < CALL 59), so the K3 violation is **masked for the two bodies** and survives only into the epilogue. Low impact, but it is a FORCED rule the shipped default breaks |
| **C1** | **the rotation sign.** round5 §3 deliverable: *"rotation sign s = −1: delay = read_descriptor − write_descriptor"*, and round5 §6's ladder has `write 0x03 = 32768 → read 0x00 = 33568 = 800` | FORCED (given the direction, which is FORCED twice) | `upd6383.cpp:1880` `const u32 addr = (cellv + u32(m_frames_run) + …) & 0xffff;` with `m_frames_run++` once per frame (`:4614`) | ★ **MISMATCH** | ★ **YES**, two of them — see §2 |
| **C2** | **the map is per-BODY**: *"the k-th class-1 FORMAT-ESCAPE consumer takes the k-th descriptor cell of its **body's** block"* — round5 **B** (three polarity-free oracles, perfect at exactly one of thirteen phases, permutation null 0/2000); the cursor is **reloaded per body** — `dram-matching` **H** (FORCED given D); unit-0 blocks start `0x26`, unit-1 blocks `0x00` — r3 **P5** MEASURED over 870 cells | FORCED | `upd6383.cpp:1852` `u32(m_dscbank[u8(m_dsc + m_delay_ix)])`, `:1876` `m_delay_ix++`, and the **only** reset is `:4569` `m_delay_ix = 0; // reset each frame`. `m_dsc` is written only by `ldptr.d` (`:3676`), which the kernel executes with payload `0x25` at **both** iw44 and iw52 | ★ **ABSENT** — the index is frame-global, never rebased at a body boundary, and never aimed at the body's own base | ★ **YES** — §189's live bank + §4 below; and the device's **own disassembler** prints the correct rule it does not implement (`upd6383d.cpp:461`) |
| **C3** | **`C40.1.80.000` consumes exactly one descriptor cell** — r3 **§6.1**: it is among the *"20 forms that consume exactly one cell in every solution"*, and the solve is *"96 equations, 37 unknowns, rank 26, INCONSISTENT ROWS: 0"*. round5 §7 counts **48** such cells; `dram-bounds` counts them inside its 829 | FORCED within the counting model (exhaustive rational elimination) | `upd6383d.h:811` `is_dram(w) = (hi12(w)&HI_ESC) && class4(w)==1 && !c_format(w)` — and `c_format(w) = (hi12(w)&0xf00)==0xc00`, so `C40.1.80.000` is excluded from `is_dram` and therefore never reaches `m_delay_ix++` | ★ **ABSENT** | ★ **YES** — pure arithmetic, verified in §3.3: ROOM REVERB 1 has 28 non-C-format consumers + 4 `C40.1.80.000` = **32 = n** |
| **D1** | the CEILING is a bound, one per algorithm, `32768` in unit 0 / `32767` in unit 1, 83/83 — `dram-bounds` **B**; and it is the **flush read** of a one-deep pipeline, last read 83/83 — `dram-datapath` **A** | FORCED / FORCED-in-enumeration | not modelled; the device performs a real port read at that address | **ABSENT**, **low impact** — the flush read's datum is meant to be discarded, and the device's per-line latch (`:1953` `line = cellv & 0x3f`) mostly keeps it out of the way | weak: the classification is in `descriptor-cell-classes.json`, but nothing downstream in the device consumes a cell *class* |
| **D2** | the LIMIT is a bound (an in-region write no read can reach), and it is the **prime write**, first write 74/74 — `dram-bounds` **C** + `dram-datapath` **A** | FORCED-in-model | not modelled; a real port write happens | **ABSENT**, **low impact** — by construction nothing reads it | as D1 |
| **D3** | `wtrail = 2` — the write of a line trails its read by two 8-word repetitions — `dram-datapath` **B** | FORCED given round5 B+D | the device's pipeline is **per-line, keyed on the descriptor value** (`:1942-1961`, §78), not on a slot offset; `m_land` (`upd6383.h:1148`) is dead while bit 20 is ON | **NOT-APPLICABLE as stated** — the device solves the same problem with a different mechanism; `wtrail` is not a parameter it has | — |
| **D4** | `land ∈ [1,4]`, *an interval, not a value* — `dram-datapath` **E** | FORCED in the printed model | `m_land = 4` default, but the §49 ring at `:1986-1992` is unreachable while `port_pipe` (bit 20) is ON | **NOT-APPLICABLE** while bit 20 is ON | — |
| **D5** | `addr8` bit 4 marks the head of an access chain, 37/38 — `dram-datapath` **G** | **CONSISTENT only** (`H4 = don't-care` not refuted) | not modelled | **ABSENT** — correctly, it is not FORCED | — see §3.4: I checked it as the reload trigger and it is **refuted** by the composites |
| **D6** | the reverbs' dead `T1[0x67]` reservation is off by one, so `0x19/0x1A/0x1C/0x1D` are READS — `dram-bounds` **M** | MEASURED blocks, **INFERRED** off-by-one, direction **CONSISTENT** | not modelled (those words still trap) | **ABSENT** — correctly, the note itself says NOT APPLIED | — |
| **E1** | the delay datum is stored 24→16 (top 16 bits) | the device's own comment says **UNVERIFIED** | `:1904` `wv = u16((u32(acc_to_datum(wacc)) >> 8) & 0xffff)`; `:1973` `datum = u32(m_delay.read_word(addr)) << 8` | **UNVERIFIABLE from my files** — no note of mine addresses the delay-DRAM *data* width. Left alone | — |

---

## 2. ★ Rank 1 — the rotation sign. MISMATCH, with two controls.

### 2.1 The code

```cpp
// upd6383.cpp:1877-1882
//  ★★★ §153: + the modulation offset.  `m_frames_run' is the
//  circular-buffer rotation G (r3-delaydram.md §5.1); `m_tapmod' is the
//  swept-tap term the model has never had.
const u32 addr = (cellv + u32(m_frames_run)
        + ((m_speculative && (m_specmask & (1ull << 60)))
            ? u32(s32(m_tapmod)) : 0u)) & 0xffff;
```
`m_frames_run++` is at `:4614`, once per DSP frame = once per 44.1 kHz sample.

### 2.2 The arithmetic — FORCED

Let `G(n) = n` (the device: `G` counts **up**). A WRITE of descriptor `W` at frame `n` lands at
physical `W + n`; a READ of descriptor `R` at frame `m` fetches physical `R + m`.

```
   R + m  ==  W + n     ⟺     n = m + (R − W) = m + D
```

so the read at frame `m` would need a write from frame `m + D` — **in the future**. The most recent
real write to that word was `65536` frames earlier:

```
   effective delay  =  65536 − D  samples
```

For ROOM REVERB 1's 800-sample pre-delay that is **64 736 samples = 1.468 s** instead of 18.1 ms;
for its 83-sample first diffuser segment, 65 453 samples instead of 83. Every line in the machine.

The correct generator under round5 §3's `s = −1` is `addr = (cellv − m_frames_run) & 0xffff`
(equivalently, `G` is a **down**-counter). Then `R − m == W − n ⟺ n = m − D`, delay `= D`. ✓

### 2.3 Why it is there — a stale citation, exactly the failure mode the brief warns about

The comment cites **`r3-delaydram.md` §5.1**, whose sign argument is:

> *"a tap at distance D is simply the cell `W − D` … which is exactly the sign the reverb ladder
> shows (§7.3: the read cell of a stage sits **below** its write cell by the delay)"*

That rests on the `i+1` pairing and the old polarity (`0x60` = READ). **Both were retracted**:
`dram-matching.md` **A** replaced `i+1` with `i+3`, and round5 **D** reversed the polarity. Under
the shipped decode the read cell sits **above** its write cell (round5 §6: `write 0x03 = 32768 →
read 0x00 = 33568`). r3 §9 item 6 predicted this exact failure in advance —
*"the global rotation must be incrementing if addresses are `cell + G`. Get the sign wrong and the
reverb tail is silent, not merely wrong."* — and the polarity flip inverted the antecedent without
anybody re-reading the consequent. **The device adopted round5's direction and kept r3's rotation.**

### 2.4 ★ INDEPENDENT CONTROLS — two

1. **The host's own evaluator, PROVEN BY CONSTRUCTION** (`LABEL_03925E`, r3 P4 / `dram-matching` §1):
   `cell = round(user_ms × 44100/1000) + BASE24`. The knob moves the **READ** cell **upward**, away
   from a fixed `BASE24 − 2` write cell — so `delay = READ − WRITE` must **increase** with the knob.
   Under the shipped sign it **decreases** (`65536 − D`). Nothing in this control is fitted; it is
   the firmware's arithmetic.
2. **The device's own disassembler mirror**, `upd6383d.cpp:468-470`, already prints
   *"this end moves with the user's DELAY (ms) knob, and the delay is `READ_CELL − WRITE_CELL`"*.
   The two halves of the same device disagree.

### 2.5 The two-sided falsifier

Write a known marker at descriptor `W` on frame `n`; read descriptor `R = W + D` and record the
frame `m` at which the marker returns.
* **fix correct** ⇒ `m − n = D` (e.g. 800 for the pre-delay).
* **fix wrong / current code** ⇒ `m − n = 65536 − D`.
The two cannot both hold, and neither is "no result": the current code returns the marker, just
65 536 − D frames late. (Cheap variant that needs no new instrument: the device already logs
`§75 DLY R addr %04X … got %06X` at `:1974-1979` — arm it on both a write and a read of one line.)

⚠ **What this does NOT claim.** The *single global rotation* itself is r3 §5.1 **INFERRED**, not
forced (a per-line pointer fits the same numbers). What is FORCED is the **internal
inconsistency**: given the mechanism the device already chose and the polarity it already shipped,
`+G` produces `65536 − D` where every note says `D`.

---

## 3. ★ Rank 2 & 3 — the descriptor cursor

### 3.1 The code, in full

```cpp
// upd6383.cpp:1850-1852
const u32 cellv = (m_speculative && (m_specmask & 0x200))
        ? (m_cram.read_dword(m_cursor) & 0xffff)     // bit 9, OFF
        : u32(m_dscbank[u8(m_dsc + m_delay_ix)]);    // <-- the live path
// :1876
m_delay_ix++;
// :4569  (frame end, next to m_frames_run++)
m_delay_ix = 0;         // ★ SPECULATIVE: descriptor cells are consumed in
                        //   program order, restarting every frame.
// upd6383.h:1195
u8   m_delay_ix = 0;    // ★ SPECULATIVE: which descriptor cell the next
                        //   delay-DRAM word consumes, reset each frame
// upd6383.cpp:3676  (the ONLY writer of m_dsc)
m_dsc = ad;
```

There is **no** other assignment to `m_delay_ix` in the 300 KB file (verified by exhaustive grep),
and **no** rebase of it at the unit CALL — unlike the coefficient cursor, which *is* rebased there
(`:4473-4477`, bit 38 ON). The device therefore has a **frame-global** index where the notes
FORCE a **per-body** one.

### 3.2 What that produces, traced word by word

`ldptr.d` (`lo12 == 0x825`) occurs in exactly three places in the whole 3 057-word machine
(MEASURED here from `dsp/disasm/*.dsm`, all 41 listings):

```
   kernel   iw44   801.0.25.825   payload 0x25
   kernel   iw52   801.0.25.825   payload 0x25
   epilogue iw62   801.0.26.825   payload 0x26      <- not recorded in r3 §6.3
```

and the class-1 FORMAT-ESCAPE consumers of the shared kernel are (MEASURED, same route):

```
   iw12  880.1.20.2D5     iw26  880.1.20.40B     iw40  C4A.1.C0.820 (C-format)
   iw46  800.1.60.00B     iw54  800.1.60.00B
```

Cold-boot frame, CHORUS in unit 0 (10 consumers) and a reverb in unit 1 (28 non-C-format
consumers), stepping the device's own expression `m_dscbank[u8(m_dsc + m_delay_ix)]`:

| what runs | `m_delay_ix` | device cell | **correct cell** (round5 B + r3 P5) |
|---|---|---|---|
| kernel iw12 | 0 | `0x26` | kernel's own, `0x20..0x25` slack (r3 §6.3 (iii)) |
| kernel iw26 | 1 | `0x27` | ditto |
| iw44 → `m_dsc = 0x25` | | | |
| kernel iw46 | 2 | `0x27` | (k4 item J: probably not a DRAM access at all — §3.5) |
| **unit-0 body**, 10 words | 3…12 | `0x28`…`0x31` | **`0x26`…`0x2F`** (CHORUS's block) |
| kernel iw54 | 13 | `0x32` | — |
| **unit-1 body**, 28 words | 14…41 | `0x33`…`0x4E` | **`0x00`…`0x1F`** (the reverb's block) |

The unit-0 body is off by **+2**; the unit-1 body is off by **+0x33** and lands **entirely outside
the descriptor bank the host wrote for it** — cells `0x3A..0x4E` are never written by any algorithm
(r3 P5: unit-0 blocks stop at `0x39`), so they read `0`, i.e. every reverb tap addresses the same
rotating word and **there is no delay line at all**.

★ **INDEPENDENT CONTROL — §189's own live readout.** §189 §2 reports the live bank holding
`26:0190` = **400** and `2B:0410` = **1040**. Those are CHORUS's cells `0x26` and `0x2B`, values
400 and 1040 — confirmed against the ROM in `descriptor-cell-classes.json` (algo 1:
`26:400 … 2B:1040`). So the **bank is filled correctly at the right indices**, and the defect is
purely in the *consumption* index. §190 adds two more: `03:8000` (32768, unit-1 base) and
`1E:7FFF` — cells `0x03` and `0x1E`, both inside `0x00..0x1F`.

### 3.3 ★ And the C-format words must consume — verified arithmetically

r3 §6.1's exhaustive rational solve puts `C40.1.80.000` among the **20 forms that consume exactly
one cell in every one of the 8 admissible `{0,1}` solutions**, and explicitly contrasts it with
`C40.1.E0.451`, which consumes nothing. `dram-bounds` and round5 both count 48 such cells inside
their 829.

Counted from the .dsm listings in this pass (MEASURED):

```
   program                     non-C is_dram   C-format cl1+esc   total    n
   prog16_room_reverb_1              28              4             32     32  ✔
   prog09_single_delay                6              0              6      6  ✔
   prog10_multi_tap_delay             7              0              7      7  ✔
   prog01_chorus                     10              0             10     10  ✔
```

and the reverb's consumer sequence in program order is

```
   R W R W R W R W R W R W R W R W R W R W R W R W R C C R C C R W
   cell 00 ....................................... 18 19 1A 1B 1C 1D 1E 1F
```

— the four `C` are exactly cells `0x19 0x1A 0x1C 0x1D`, which is precisely what round5 §6 prints
(*"0x19 0x1A 0x1C 0x1D are `C40.1.80.000` — OUT OF SCOPE, still trapping"*). **`28 + 4 = 32 = n`
only if the C-format words consume.** The device counts 28, so within a reverb body it also
misplaces the last three real accesses:

```
   consumer            device cell   correct cell
   the R after the 1st CC pair          0x19          0x1B      (the 540-sample early reflection)
   the R after the 2nd CC pair          0x1A          0x1E      (the flush read / CEILING)
   the final W                          0x1B          0x1F      (line 11's base)
```

⚠ **This is separable from `is_dram`'s scope, and both notes are right.** `is_dram`'s C-format
guard is correct — `isa-adjudication` and round5 §3's SCOPE both require those words to keep
trapping as *accesses*. What is missing is a **separate** consumption predicate: *"class4 == 1 with
`hi12` bit 11 set, **including** `C40.1.80.000`, advances the descriptor cursor; only the
non-C-format members perform a port access."*

★ Note that §55 of `SPECULATIVE-APPLIED-REGISTER.md` already measured the symptom —
*"834 accesses against 870 declared descriptor cells … a 36-cell shortfall over 91 programs"* —
and read it as **corroboration** of `is_dram`'s scope. It is that, but the same shortfall is a
**cursor misalignment**, and that half was never drawn.

### 3.4 The reload mechanism — one candidate checked and refuted here

r3 §6.3 option (iii) proposes *"the `0x30` sub-op reloading it at each body entry"*, and
`dram-datapath` **G** measures `addr8` bit 4 on the first DRAM word of **37 of 38** images. I
checked whether "reload on `addr8 == 0x30`" works: **it does not.** `dram-datapath` §1's own data
refutes it — the composites carry a *second* `0x30` at the sub-effect boundary:

```
   algo 64 S.DELAY+CHORUS    30 60 20 60 20 60 20 | 30 60 20 60 20 60 20 60
```

and algo 64's block is the **contiguous** `0x26..0x35`; a reload at the second `0x30` would restart
it at `0x26`. Six composites do this, plus the eight `30 30` two-cell blocks.

**What survives:** rebase at the **unit CALL/transfer**, exactly where the coefficient cursor is
already rebased (`:4473-4477`, bit 38) and exactly what r3 §6.3 (iii) calls *"the cursor reset by
the unit tag on the CALL word"*. Base `0x26` for unit 0, `0x00` for unit 1 (r3 P5, MEASURED over
870 cells; also `dram-matching` **I** for unit 0's `0x25` pre-increment). The unit-1 reload **value**
is round5's RANK-3 OPEN item (I-RAM 52 loads `0x25`, unit 1 needs `0x00`), so a first implementation
should take it from the CALL's unit tag and say so, not from `m_dsc`.

★ **A lead this pass turned up that is in none of my notes:** the epilogue's **iw62 =
`801.0.26.825`** — a third `ldptr.d`, payload **`0x26`**, which is exactly unit 0's block base. It
has the same shape as the C-RAM pointer's iw69 → `0x90` ("the epilogue, and therefore the next
frame's kernel"), which the device already reasons about at `:3649-3652`. **MEASURED** (the word
exists, once, at iw62); **SPECULATIVE** as a reload mechanism. r3 §6.3 enumerated only iw44 and
iw52 and did not have this word.

### 3.5 Flagged, not claimed: `800.1.60.00B` is executed as a delay WRITE

`is_dram` accepts `800.1.60.00B` (`hi12 = 0x800` has bit 11 set; not C-format), and `dram_dir`
calls `addr8 = 0x60` a **WRITE**. So the device performs **two spurious delay-DRAM writes per
frame**, at the kernel's iw46 and iw54, each storing the accumulator and each consuming a
descriptor cell.

k4 item **J** proposes those same two words as the **coefficient-base rebase** instruction —
*"exactly twice in the whole 3 057-word machine, once in each per-unit setup block, at the same
relative offset (+4), and nowhere else"* — but files it **CONSISTENT / OPEN**, and its own "against"
column says *"`hi12 = 0x800` differs from the DRAM family's `0x880` only in bit 7, so this may
simply be a DRAM housekeeping word. Nothing rules that out."* Neither r3's counting solve nor
round5's population contains it (both are body-scoped; this word is kernel-only). **OPEN, both
ways** — reported so a cursor fix does not silently assume one reading.

---

## 4. ★ BONUS — §189/§190's open discrepancy is CLOSED

The brief flags this as *"an OPEN discrepancy, not a defect"* and says not to re-derive it. I did
not: the resolution falls out of my own files' retraction, in one comparison.

§189 §3 searched the live descriptor bank for `255 / 869 / 979 / 366 / 1044 / 8905` and their
halves, found **0 of 6 either way**, and reported the live unit-1 chain's consecutive differences as

```
   569  707  1250  1674  480  512  870  678  900  840        (10 values)
```

§190 §3 added `live cell 0x02 = 41925`, `live cell 0x00 = 33255`, declined the "different
reverb-time setting" explanation on element counts (10 vs 5 vs 11), and left it SPECULATIVE.

**Two things were wrong with the target, and both are in my files.**

1. **The ladder searched for is doubly stale.** `255 869 979 366 1044` and `8905` are r3 §7.3's
   numbers under the `i+1` pairing. `dram-matching.md` **A** retracted that pairing
   (*"the op-0x67 anchor pairs cell `i` with cell `i+3`"*), round5 **H** re-derived the ladder from
   the FORCED roles, and round5 **I** says in as many words: *"THE BRIEF'S OWN `long head 8905` IS
   STALE (method rule 8) … an `i+1` artefact of the pairing Target 1 already retracted."* The
   halving (P16) is a **second, independent** correction on top of a pairing that no longer exists.
   Searching for `255/869/979/366/1044` in 2026-07-31 cannot succeed under any decode.
2. **§190 identified the *body image*, not the *preset*.** All twelve reverbs share one 133-word
   image byte for byte; §190's 16-word fingerprint therefore proves "a reverb", not "ROOM
   REVERB 1". The preset lives **entirely in the descriptors**.

Comparing the live chain against every reverb preset's ROM descriptors
(`descriptor-cell-classes.json`, algos 16–27), the abutting-ladder chain of **CONCERT REVERB 1
(algo 20)** is

```
   chain   32768  41590  41925  42494  43201  44451  46125  46605  47117  47987  48665  49565  50405
   diffs    8822    335    569    707   1250   1674    480    512    870    678    900    840
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                          the live chain, 10 of 10, in order, exact
```

and its cell `0x02` is **41925** — §190's live value, exactly. Cell `0x00` is canned `33268`;
live `33255 = 32770 + 485`, i.e. `BASE24 + round(11 ms × 44.1)` — the runtime evaluator having
re-written PRE DELAY at 11 ms through op `0x67`, which is the chain working, not failing.
§190's own `8670 = 41925 − 33255` is that same head with the runtime pre-delay
(canned it is `41590 − 32768 = 8822 = 200.00 ms`, `dram-matching` **B2**).

⇒ **MEASURED. The live cold-boot unit-1 preset is CONCERT REVERB 1 (algo 20).** Its descriptor
block reproduces the ROM bit-for-bit; the bank is being read correctly; the discrepancy was in the
target, not in the data. §190's near-misses (*"`480` coincides … `870` is one away from `869`"*)
were not coincidences — they are literal segments of this preset's ladder.

★ **A consequence worth carrying:** any impulse/excitation sizing for the *live* vehicle must use
CONCERT REVERB 1's numbers — ladder total `335+569+707+1250+1674+480+512+870+678+900+840 = 8815`
samples plus a `485`-sample pre-delay, longest single line `1674` — not ROOM REVERB 1's, and
emphatically not `4 × 8905 = 35 620`.

---

## 5. The P16 sweep — does any DEVICE CODE still use halved / `i+1` numbers?

**Answer: no.** Grepped `src/devices/cpu/upd6383/*.{cpp,h}` for `8905`, `4452`, `35620`, `4673`,
`127 435`, `435 489`, `255 869`, `869 979`, `979 366`, `366 1044`, `489 183`, `183 522` and the
corrected `83 172 356` — **zero hits in code or comments**. The device carries no delay-length
constants at all; it reads them from `m_dscbank`, which is filled by the real host through the
`×2 + LSB` decode (A1). So §188's fix was the only live site in the emulator, as §190 §4 concluded.

**One stale site in the MAME repo, documentation only, outside my write scope:**

```
   kn7000_mame/notes/dsp-adjudication-round4-applied.md:157
      "... 83 172 356 513 739 240 119 247 428 616 360, pre-delay 800, long head 8905."
   kn7000_mame/notes/dsp-adjudication-round4-applied.md:161
      "≥ 4 × 8905 = 35 620 samples, and ≥ 50 784 to recirculate the whole region."
```

Both were superseded by `dsp-adjudication-round5-applied.md:181-182` and
`dsp-adjudication-round6-applied.md:157`, which retract `8905` explicitly. Line 157 is
self-contradictory as it stands — it prints the **corrected** ladder and the **retracted** head in
one sentence. It is a note, not code, and it is in a repository this pass may not edit.

---

## 6. Ranked shortlist — what to implement next, each with its two-sided falsifier

Ranked by (confidence the note is right) × (size of the discrepancy) × (a control exists).

### **1. Flip the rotation sign.** `addr = (cellv − m_frames_run) & 0xffff`
* **Confidence:** high. round5 §3's polarity is FORCED by two independent routes; the sign then
  follows by arithmetic. The device's own disassembler already states the corrected relation.
* **Size:** every delay line in the machine, `D` → `65536 − D`. ROOM REVERB 1's 18.1 ms pre-delay
  becomes 1.468 s.
* **Control:** ★ **YES** — the host evaluator `cell = round(ms × 44.1) + BASE24`, PROVEN BY
  CONSTRUCTION, plus `upd6383d.cpp:468`.
* **Falsifier (two-sided):** marker round-trip on one line — `m − n = D` if right, `65536 − D` if
  wrong. Or: sweep `SINGLE DELAY`'s `DELAY L (ms)` and measure the port round-trip; it must grow
  with the knob. **If it does not grow either way, the rotation model itself (r3 §5.1, INFERRED) is
  wrong and a per-line pointer is indicated** — which is a third, distinguishable outcome, and that
  is what makes this a test rather than a coin flip.
* ⚠ Put it behind its own mask bit. `m_tapmod` (bit 60) is added to the same expression and its
  sign convention would flip with it.

### **2. Rebase the descriptor cursor per body, at the CALL.**
* **Confidence:** high. round5 **B** is FORCED by three polarity-free oracles simultaneously
  perfect at exactly one of thirteen phases (null 0/2000); `dram-matching` **H** forces the
  per-body reload; r3 **P5** measures the two block bases over 870 cells; and the device's own
  disassembler prints the rule.
* **Size:** the unit-1 body currently reads cells `0x33..0x4E`, of which `0x3A..0x4E` are never
  written by anything — the reverb has **no delay line at all**. Unit 0 is off by +2.
* **Control:** ★ **YES** — §189/§190's live bank readout (`26:0190`, `2B:0410`, `03:8000`,
  `1E:7FFF`) pins the bank contents to the right indices independently of this pass.
* **Falsifier (two-sided):** the device already censuses the first 8 distinct descriptor indices
  (`m_dly_dsc/m_dly_val/m_dly_dir`, `:1862-1874`). **Pre-register:** with the rebase, a unit-1 body
  must draw indices in `0x00..0x1F` with values ≥ 32768 (r3 P5's region test, MEASURED 870 cells);
  a unit-0 body must draw `0x26..0x39` with values < 32768. **Without** it, unit 1 draws ≥ `0x33`.
  If the rebase is applied and unit 1 *still* fails the region test, the reload value (round5 RANK 3
  OPEN) is wrong, not the reload.
* Implement as a sibling of the coefficient rebase at `:4473-4477`, with its own mask bit; the
  `addr8 == 0x30` trigger is **refuted** (§3.4).

### **3. Let `C40.1.80.000` advance the descriptor cursor without performing a port access.**
* **Confidence:** high-ish. FORCED *within* r3 §6.1's counting model (96 equations, rank 26, zero
  inconsistent rows, and this form consumes in all 8 solutions); independently required by
  `dram-bounds`' and round5's `#cells == #consumers` populations.
* **Size:** 4 cells per reverb body — misplaces the 540-sample early reflection, the flush read and
  line 11's base in every one of the twelve reverbs. Nothing outside the reverbs is affected
  (no other image carries the word).
* **Control:** ★ **YES**, arithmetic and re-derived here: `28 + 4 = 32 = n`, and the four `C`
  positions land exactly on round5 §6's `0x19 0x1A 0x1C 0x1D`.
* **Falsifier (two-sided):** count consumers per body against that body's `n`. Reverb must reach
  **32**, not 28; SINGLE DELAY must stay **6**, MULTI TAP **7**, CHORUS **10** (i.e. the change must
  move exactly the reverbs and nothing else). If adding the C-format words breaks a non-reverb
  count, the predicate is too wide.
* Requires a **new** predicate (`dram_consumer()`), not a widening of `is_dram()` — round5 §3's
  SCOPE and `isa-adjudication` both require those words to keep trapping as accesses.

### **4. Set mask bit 12** — stop `801.0.NN.821` from seeding the coefficient cursor.
* **Confidence:** high (k4 §6.2 FORCED; K3 item F sharper; the device's comment agrees).
* **Size:** small — bit 38's CALL rebase runs after both in-body `ldptr`s, so only the epilogue path
  is affected today. It is a correctness debt, not a live audio defect.
* **Control:** partial. k4 §3.2's falsification is order-independent, but the *observable*
  consequence is masked. Ship it with 1–3, not before, so a regression is attributable.
* **Falsifier:** with bit 12 set, the epilogue's coefficient cursor must be whatever the running
  count delivers, not `0x90`; `:3665`'s arithmetic (`kernel 0x90..0xA4 = 21` + `body 0xA5..0xB4 = 16`
  = 37 = the host's coefficient run count) is the pre-registered target.

### Not recommended yet
* **CEILING / LIMIT as non-addresses** (D1/D2). FORCED as a classification, but the device performs
  both accesses harmlessly and `dram-datapath` **A** re-attributes them to a *mechanism* (flush
  read / prime write) whose datum is discarded anyway. Revisit only after 1–3, when the per-line
  latch has correct descriptors to key on.
* **`wtrail`/`land`** (D3/D4). The device solves the pipeline by a per-line mechanism (§78) that
  has no `wtrail` parameter; `dram-datapath` **H2** explicitly says its own `wtrail = 2` arm was
  *"an absence of a search, not a rejection"*. Nothing to apply.

---

## 7. Method notes, so this audit can be checked

* Every device quote is from the files as they stand on 2026-07-31; I re-read them rather than
  trusting any note's copy. Where a device comment describes a former bug in the past tense
  (`upd6383d.cpp:432` *"the REVERSE of what this file used to print"*, `upd6383.cpp:2025-2040`
  *"⛔⛔ REFUTED 2026-07-28"*) I scored the **code**, not the comment.
* The consumer counts in §3.3 and the `ldptr.d` census in §3.2 were computed in this pass from
  `dsp/disasm/*.dsm` by decoding `hi12 / class4 / addr8 / lo12` with the device's own extractors
  (`upd6383d.h:39-73`). They are reproducible in ten lines of stdlib Python and are the only new
  measurements here.
* The §4 ladder comparison used `dsp/analysis/descriptor-cell-classes.json` (the export of
  `dram-bounds.md`'s own `bounds.py`), not a re-run of any tool.
* **What I could not verify:** anything requiring a run. Every falsifier above is stated as a
  pre-registration, and none of the ranked items is claimed to be *audibly* correct — the chip is
  still measured silent (`§70 ACCA min = max = 0`), so all four are decode fixes whose criterion is
  a counter, not a waveform.
* **Grades:** §2 arithmetic **FORCED**; §3.2/§3.3 traces **MEASURED**; §3.4's refutation of the
  `0x30` trigger **MEASURED** (from `dram-datapath` §1's own printed sequences); §3.5 **OPEN**;
  §4 **MEASURED**; §5 **MEASURED** (a grep, stated as a negative).
