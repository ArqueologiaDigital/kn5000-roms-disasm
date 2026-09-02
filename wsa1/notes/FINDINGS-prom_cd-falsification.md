# prom_d's "ZERO bytes of assembly", attacked — 2026-09-02

A falsification lane. The job was to **break** two recorded claims, not to
reproduce them:

1. `scripts/analysis/kn5000_source_coverage.py`: **prom_d = 524,288 B typed
   data, `asm 0`**, 100% source, of which 193,767 B is verified `.fill`.
2. `notes/DEBT-INVENTORY-2026-09-02.md`: prom_c and prom_d **CLEAN** of both
   code-as-`.byte` and data-as-code, prom_c's cleanliness "survived
   falsification"; prom_c's filler total 129,216 B.

**Both survived.** Everything below is reproduced by one script:

    python3 notes/prom_cd_falsification_2026_09_02.py          # 55 checks, 0 failures
    python3 notes/prom_cd_falsification_2026_09_02.py --quick  # Q1-Q5 only, no builds

## Why the claim needed attacking at all

A 512 KiB ROM with no code in it is either a data ROM or a ROM whose code
nobody framed. The second is invisible to the byte gate — a `.long` table that
is really a routine re-assembles to the same bytes — and this push already had a
68,934 B near-miss of that shape (BRIEF-2026-09-01, addendum on run extents).

And prom_d is **not** off on a sound chip's private bus, which would have made
"no code" true by construction: `wsa1.cpp` maps it `.rom()` at
`0xf00000-0xf7ffff` in **CPU 2's program space**, the same space that CPU fetches
prom_c from, and the base is prom_c's own (`ld XBC,0x00F00000`, 0xFB051E). So
the question is real.

## What was tested, and what the null was

| | test | null / control | result |
|---|---|---|---|
| Q2 | do any of prom_c's 33 vectors land in prom_d? | the same 33 vectors against prom_c's own window | 0 vs 33 |
| Q3 | prom_c **instruction** literals in prom_d's window | same scanner over the 0xE80000 flash window and over prom_c's own | 1 (the base itself) vs many |
| Q4 | prom_c **bytes** — an LE32 pointer table into prom_d? *(closes the limit `prom_d/prom_d.ld` states: the round-5 search was complete over instructions only)* | two windows with **no device in them** (0xD00000, 0xE00000) and one that is prom_c itself | prom_d 741, nulls 901 / 675, prom_c 1977 — prom_d is at noise, prom_c is enriched |
| Q5 | does the **assembler** see an instruction in prom_d's source? `llvm-mc -g` emits a DWARF line row per instruction statement and none for a data directive | the same instrument on prom_c | prom_d **0 rows**, prom_c **76,647** |
| Q6 | do prom_d's **bytes behave like code**? | see below | no window flagged |
| Q7 | is the `.fill` byte COUNT backed by byte VALUES? | rebuild with every fill value XORed 0xFF and diff against the dump | exact |

Q5 is the only one that speaks to "asm 0" directly, and it is worth being clear
about what it is: an assembler-side census that never reads the `.s` text.
**It cannot see code that was framed as data.** Q6 is the test that can.

## Q6 — the code-likeness test, and its two calibrations

Metric: **branch-target coherence, normalised by boundary density.** Linear-decode
a window with MAME's `unidasm` (the framing authority, `original_ROMs/README-unidasm.md`),
then ask what fraction of in-window branch targets land on an instruction
boundary of that decode, divided by the boundary density — the rate you would
get by chance.

Two things had to be fixed before it was worth anything:

* **Raw "lands on a boundary" does not separate.** Data decodes at ~1.45
  bytes/instruction, so a random target hits a boundary ~69% of the time and a
  data region outscored a code region. Dividing by the density is what makes it
  a test.
* **Degenerate targets had to be excluded.** ⚠ prom_d **0x1F000 scored 2.08 and
  crossed the threshold** — and all 47 of its "coherent" targets were the same
  thing, `jr +2` into the following instruction, thrown up by one repeated byte
  pair in `ToneDB_MixerDefaultTable_*` (43-byte records). A branch to its own
  address or to the next instruction is on a boundary *by construction*. With
  self-loops and fall-throughs excluded that window has **zero** informative
  targets, which is the honest answer. This is the single most useful thing this
  lane learned: the first version of the metric produced a false positive on a
  named data table, and the fix is not a tuning knob, it is a correctness fix.

**Ground truth for the controls is the assembler's, not a comment's**: prom_c
windows are labelled CODE or DATA by Q5's DWARF instruction map.

    prom_c CODE windows (8 KiB)   25 windows   2.42 .. 3.09
    prom_c DATA windows (8 KiB)   22 windows   0.81 .. 1.34
    threshold, from the controls alone                 1.88
    prom_d, all 38 scorable windows              0.29 .. 1.16   <- highest is 0x42000
    prom_c CODE windows (2 KiB)   87 windows   2.18 .. 3.12
    prom_c DATA windows (2 KiB)   85 windows   0.60 .. 1.43
    threshold at 2 KiB                                 1.80
    prom_d, 125 scorable 2 KiB windows           0.11 .. 1.49

prom_d's best window is **1.26 below the weakest prom_c code window**, with the
entire data-control population sitting in between.

**Q6c runs the test in the other direction** — the project's usual hazard, data
disassembled as code — using the certified DWARF framing as the boundary set.
All 26 scorable code-framed prom_c windows score 2.47..4.49. None lands in the
data band.

## Proving the instrument can see the failure it reports the absence of

Q6b splices 8 KiB of real prom_c code into prom_d at three offsets. Every one is
flagged (0.95/0.83/0.69 as dumped → 2.58 spiked).

Q6d shrinks the spike to find the reach:

    8192 B of code in an 8192 B window -> 2.58  FLAGGED
    4096 B                             -> 1.80  missed
    2048 B of code in a 2048 B window  -> 2.31  FLAGGED
    1024 B                             -> 1.62  missed

★ **The claim this lane is entitled to**, and no more: *a contiguous routine of
about 2 KiB or more, anywhere in prom_d, would have been flagged, and none was.*
A 512-byte routine buried in a tone table is below this instrument.

## What this lane did NOT close

⚠ Three 8 KiB windows — **prom_d 0x26000, 0x28000, 0x2A000** — have too few
informative branches in their linear decode to score at either grain. They lie
inside `ToneDB_EnvDescTable` (0x22D3B..0x2B2AB, 34,161 B of 112-byte
`CurveStepToElem` arrays). Q6f offers the weaker argument that their branch
counts (30, 31, 59 per 8 KiB) are below **any** prom_c code window's (min 71),
so they do not look like prom_c's code — but a branch-free straight-line routine
would evade that. Those 24 KiB are the one part of prom_d left less than fully
attacked.

## Q7 — the filler

The extents are the **assembler's**, recovered by rebuilding each image with
every `.fill` value XORed 0xFF and diffing against the dump, so a fill is
exactly where the bytes changed:

    prom_c  0x00020..0x001FF     480 B  0x00
            0x165C0..0x17FFF   6,720 B  0x0E
            0x621E6..0x7EFFF 118,298 B  0x0E
            0x7F0E5..0x7FEFF   3,611 B  0x0E
            0x7FF84..0x7FFEE     107 B  0x0E     total 129,216   <- claim exact
    prom_d  0x50B09..0x7FFEF 193,767 B  0xFF     total 193,767   <- claim exact

Each range is **one value end to end** in the original dump, the marker build
differs from the dump *only* inside these ranges, and each range lies inside
(never straddling) a maximal uniform run of the dump. ⚠ Two of them are proper
subsets of a longer natural run — prom_c's 480-byte zero pad sits inside a
482-byte run, and the 118,298-byte 0x0E run starts one byte after the `ret` that
ends the code at 0x621E5. That is correct, not an off-by-one. prom_d's fill is
the **only** uniform run ≥ 4096 B in the whole image.

## Verdicts

* **prom_d has zero bytes of assembly — SURVIVED.** It is CPU-addressable, and
  nothing points into it, no vector reaches it, the assembler emits no
  instruction from its source, and its bytes do not behave like code at any
  window down to 2 KiB. The residual is the 24 KiB above and routines shorter
  than ~2 KiB.
* **prom_c is clean in both directions — SURVIVED.** Independently re-derived,
  not taken from the record: every code-framed window scores in the code band,
  and the data/code control populations separate with no overlap.
* **The filler counts — SURVIVED, and are now backed by byte VALUES**, located
  by the assembler rather than by a comment.
