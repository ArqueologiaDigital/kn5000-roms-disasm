# LEDGER — every hypothesis, its mask bit, and its verdict

**Read this file before starting any DSP work. It exists because ten passes on this project were
lost to re-asking a question the notes had already answered, or re-trying an approach a previous
section had already refuted.** A 6000-line register does not prevent that; an index read *first*
does.

Tiers, cheapest first — stop as soon as you have what you need:

| tier | what | where |
|---|---|---|
| **0** | the current blocker + **the dead ends** | this page, below |
| **1** | the mask-bit register — every bit, its state, its § | generated, below |
| **2** | the section index — 59 sections, one line each | generated, below |
| **3** | the sections themselves | `SPECULATIVE-APPLIED-REGISTER.md` |

⚠ Tiers 1 and 2 are **generated** by `tools/gen_ledger.py` from the C++ source and the register's
own headings, so they cannot drift. Tier 0 is hand-written. **Re-run the generator after any
section or mask-bit change**; do not hand-edit `LEDGER.md`.

---

## TIER 0a — THE CURRENT BLOCKER  (§165, 2026-07-30)

> **The LFO phase RAMPS in D-RAM cell `0x07` and does not REACH the class-6 word.
> The defect is ROUTING over a handful of words, not generation.**

Established by run `runs164/A_control`, mask `0x3910E446A39B440F`, cold-boot CHORUS,
1 392 430 frames — **cite the run, not the section** (see rule 10):

```
  §164  07: 0..8388598  chg 1128429 / 1392430 frames     full Q0.23 sweep
  §162  at the class-6 word:  acc 0..0 | m_dp 12..12 | cursor 9..9
```

The phase changes 1 128 429 times against the class-6 word's 1 129 389 executions — ratio
**0.99915**, so it advances once per body execution. That identifies it as the LFO beyond doubt.
Rate puts the increment at **114** (0.652 Hz against the panel's 0.599), not §108's measured 57.

⛔ **§163's blocker — "kernel `iw32` pins the phase at `0x400000`" — is DEAD.** It was inherited
from §108, written several shipped gates earlier, and never re-measured. §108's whole kernel-`iw32`
/ `DRAM_UNIT_BASE` analysis is aimed at a symptom this build no longer has.

Everything downstream is built and waiting:
* **§161** — the wavetable is intact: `m_rf[0x1D..0x40]`, 36 cells,
  `0.9500000 × 2^23 × sin(2πk/24 + 0.100000 rad)` to within 2 LSB, period exactly **24**.
* **§162** — the class-6 lookup is four lines *once the index varies*, and not before.

**Next:** trace `0x07` → the class-6 word. The path runs through `082.2.00.1C0` (`SRC 0x07` =
`mem[ptr]` → acc) and the class-6 word's own `SRC 0x13`, which has **no reading anywhere** and
silently returns 0 (`upd6383.cpp` SRC evaluator default). `SRC 0x13` is the table read port
(§162) — that is the most likely single missing link.

---

## TIER 0b — ⛔ DEAD ENDS. DO NOT RETRY ANY OF THESE.

Each cost at least one full pass. The refutation is worth more than the hypothesis was.

⚠ #1 and #2 were aimed at §163's *"kernel `iw32` pins the phase"* blocker, which §165 then
measured out of existence. They stay listed: the refutations are still sound, and the ideas are
the ones a reader would reach for again.

| # | the idea | why it is dead | where |
|---|---|---|---|
| 1 | Fix the phase clobber by changing **`DRAM_UNIT_BASE`** | **FORCED**: kernel A's walk begins where the previous frame *closed*, so base and window are coupled and `iw32` follows the cell wherever it moves. Bit 27 ran it — gate fires, `dp` `0x07`→`0x08`, **every value bit-identical** | §108 §5 |
| 2 | Decode `040.0.**.C63` / `012.4.01.1CE` as the missing phase producers | Both **already modelled**: `SRC 0x11/ACT 0x03` = `tempB ← ACCB`, `SRC 0x07/ACT 0x0E` = `P ← mem[ptr]`. Their presence in the roadmap's *"no reading of any kind"* list is a **corpus statistic, not a statement about the emulator** | §163 |
| 3 | `addr8` on the class-6 word = the **table extent** | The `0x28` sites are fed by scale `0x000010` = 16; `0x000028` does not occur in the coefficient corpus at all. The `24`/`0x18` agreement was coincidence | `lfo-ramp.md` P-16 |
| 4 | Implement the class-6 lookup **now** | Every index candidate is constant (`acc 0..0 \| m_dp 12..12 \| cursor 9..9`, 1 129 389 hits). A frozen lookup returns one entry forever, and that reads as *refuting the sine* against the "226 not 240" test | §162 |
| 5 | `SRC 0x08` = **unity** | The rival reading saturates the accumulator on the LFO's very first word. `SRC 0x08 = the COEFFICIENT` reproduces the ROM ramp constant exactly (`mem[0x04]` 1000→1228, step +228 = `0x0000E4`) in 11 of 19 corpus constants | `upd6383.cpp:2124` |
| 6 | The brief's anchors **`SRC 0x1C` = "LFO out"**, **`SRC 0x08` = "LFO phase"** | Neither is anchored anywhere in this repository, the MAME device, or its disassembler. A *word*-level landmark was read as a *field*-level one | `lfo-ramp.md` §11 |
| 7 | `st_gate = always` | 0 survivors of 276 480 | `lfo-ramp.md` P-9 |
| 8 | Remap the three internal writes onto **output ports 0/1** | Reverted: the resulting wet was rms 1.0 — a ±1 LSB constant present *even in silence* | `upd6383.cpp:2011` |
| 10 | **Bit 54** (latch to `m_k`) and **bit 54 + bit 4** (§40 reads it) to route the phase | §136's *"the pair has never been evaluated together"* is discharged: bit 54 alone is **bit-identical to control in every cell**; the pair produces `§70 ACCA min = max = 176 471 605 248`, the exact DC §137 retracted | §165 §4 |
| 13 | `C63` writes the index register `m_tb` via `SRC 0x11 / ACT 0x03` (**§166 §3**) | ⛔ **REFUTED §181.** `lo12 = 0xC63` has bit 11 set, and `upd6383d.h:609` routes those words to *addressing only, no ALU effect*. It never writes `m_tb`. §166's 53/53 bijection is a measurement and stands | §181 |
| 14 | `SRC 0x11`'s reading explains `m_tb` being frozen | ⛔ Three experiments (§168, §181 arm D, the whole `SRC 0x11` line) tested **the source of a write that never happens** | §181 |
| 11 | `ACT 0x15` is a no-op, so the LFO index multiply never issues (**§169 §2**) | ⛔ **RETRACTED §174.** The multiply's gate is `coeff_consumer(w) = class4==0xA && !c_format(w)` — the ACTION field is not in it. `lfo-ramp.md` §10 said so in the paragraph §169 quoted. Takes §171 §4 and §173 §3 with it | §174 |
| 12 | "one cause — the frozen cell is just the dead multiply", displacing §168 | ⛔ Premise gone with #11. §168's addressing diagnosis is **confirmed** instead: 7 of 12 multiply sites have `L` identically zero while `coef` is live | §174 |
| 9 | "the delay tap **sweeps** ±240" / "each voice ramps 0→depth, a **sawtooth**" | Both retracted. The first pooled voices of opposite sign; the second censused across the boot transient. The settled modulation value is **CONSTANT** | §155, §157 → §158 |

---

## TIER 0c — STANDING RULES, each earned by a retraction

1. **Before reporting any non-zero output, read `§70 ACCA` and compare min against max.** Two
   "IC311 outputs audio" claims have been retracted; one was a DC. *(§137)*
2. **Report absolute audio statistics from a CLEAN vehicle** — `scratchpad/coldnotes2.lua`, cold
   boot, notes after ~19 s. The `peq_gain` vehicle *creates* a unit-1 rail through ~55 mid-run
   effect uploads; use it for **deltas only**. *(§148)*
3. **Check the owning note first — for EVERY component of a claim, not just the one you doubt.**
   Ten occurrences. §163 is the sharpest: the note was checked for the *table* and skipped for the
   *phase*, and the answer had been sitting in §108 for days.
4. **Before implementing a consumer, measure that its inputs VARY.** A datapath whose every input
   is constant cannot be validated by its output. *(§162, fourth occurrence)*
5. **An absolute event count is not a falsifier across runs** — cold-boot frame totals vary
   (1 128 480 vs 1 156 269). Pre-register the *relation between two counters*, never the literal.
   *(§161)*
6. **A reading that measures INERT is a hypothesis about a MISSING CONSUMER, not a refutation.**
   *(§156, third occurrence)*
7. **Enumerate mask bits programmatically — match the bit, not the spelling.** `grep 0x40000\b`
   missed `0x40000u` and double-booked bit 18, confounding a whole run. *(§129)*
8. **A criterion that cannot fail is not a test**, and **compute the NULL before interpreting a
   table, not after**.
9. **When the fix you reach for is an ANCHOR VALUE, stop.** Every anchor here is pinned by closure
   arithmetic; the defects are per-word **decodes**. *(§108 §5, named as a standing bias)*
10. **When a measurement surprises you, the first hypothesis is that it answered a DIFFERENT
    QUESTION than the one you asked. Move the instrument one step toward what you care about
    before theorising.** Four in one day: `m_p` read at the consumer not the producer (§169);
    36 M firings **pooled across sites** instead of keyed (§174); a census printing only the cells
    that *changed*, so "static and non-zero" and "static and **zero**" were indistinguishable
    (§176); and a table capped below the case of interest (§176 F3). Each was invisible until the
    previous was fixed. *(Part 109)*
11. **A blocker is a MEASUREMENT, and measurements expire.** Before building a task on a symptom
    reported in an earlier section, re-run it on the current build — several gates ship between
    passes. **Cite the run, not the section.** *(§165: the headline blocker had been fixed by
    other work and nobody re-measured it)*
