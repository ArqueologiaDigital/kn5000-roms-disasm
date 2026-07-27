# ADJUDICATION ROUND 8 — the harness is SOUND, and that is the bad news

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311). No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams, the 38 body images, the
descriptor bank, the published tools and the live emulator only.

Round 7 was named after method rule 11 — *a harness is a hypothesis* — and
existed because five rounds of reverb searches had run against a delay line that
could not delay. **This pass audited the replacement first, as instructed, and
the replacement passes every test I could put to it.** That result is not
comfortable: it removes the explanation the round was built around and leaves
the obstruction exactly where TARGET 3 put it.

```
python3 dsp/tools/adjudicate8.py harness   # 1 *** AUDIT delayline.py (independent)
python3 dsp/tools/adjudicate8.py capture   # 2 *** the capture census, LAG ENUMERATED
python3 dsp/tools/adjudicate8.py denom     # 3 *** the 401/402 denominator
python3 dsp/tools/adjudicate8.py grot      # 4 the rotation vs the host's ms evaluator
python3 dsp/tools/adjudicate8.py collide   # 5 rule 10 -- the four passes
python3 dsp/tools/adjudicate8.py predict   # 6 predict-then-check
python3 dsp/tools/adjudicate8.py all       #   everything (~3 min)

python3 dsp/tools/delayline.py delay       # the six shipped self-tests, all re-run
python3 dsp/tools/delayline.py refs        # for this audit and ALL SIX PASS
python3 dsp/tools/delayline.py twins
python3 dsp/tools/delayline.py degen
python3 dsp/tools/delayline.py loopok
python3 dsp/tools/delayline.py repro
python3 dsp/verify.py                      # BYTE-MATCH OK
bash ~/compartilhado/kn7000_mame/tools/upd6383d_diff.sh   # MIRRORS AGREE 3057/3057
```

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE NEW HARNESS IS SOUND.** All six shipped self-tests re-run and pass, and three independent probes agree: the line delays by `ra − wa` and by nothing else at **both** access orders (D = 1, 3, 7, 23, 100, 10 of 10 exact); it says YES to a textbook comb (relerr 0.00e+00) and NO to that comb's `D+1` twin (relerr 7.65e−01); `grot=static` and `grot=asc` are shown BREAKING it. **Round-7 results are NOT a second generation of harness artefacts.** | **MEASURED** (§1) |
| **B** | ★★★ **AND THE REAL LINE SET IS REPRESENTABLE, WHICH ITS OWN SELF-TESTS NEVER ASKED.** Over the **324** lines of the **83** algorithms that ship descriptor cells: **324 of 324** have a positive delay; region size is 32768 in **83 of 83**; and **0 of 324** lines have `D == size`, so `grot=asc`/`desc` are **not** degenerate anywhere in the corpus (rule 4, run before scoring). | **MEASURED** (§1 D) |
| **C** | ★★★ **THE ROUND'S OWN PREMISE IS DEFLATED, AND TWO PASSES SAID SO INDEPENDENTLY.** The one-cell `Line` was a real defect but **not** what voided the published numbers. TARGET 2: on a genuine two-address line the published-polarity window scores **108 of 7776 — the same 108 machines, set-identical**. TARGET 3: on the ladder the two-address memory is **degenerate** with the one-cell `Line`, 0 disagreements in 7 of 8 cells. **It was a POLARITY artefact.** `adjudication-round6.md` §3.5's diagnosis is CORRECTED, now double-sourced. | **MEASURED**, two routes (§5) |
| **D** | ★★★ **THE ONLY SURVIVING TOPOLOGY POOL IS DEAD, AND THE ROUND HAS NO POSITIVE TOPOLOGY RESULT.** TARGET 1's `wtrail=2` pool at `rlag=0` is 6 machines, **all at `land=−1`**; TARGET 3's only non-zero cell, **102 of 400**, is also entirely at `rlag=0, land=−1`; and TARGET 4's reverb **tail** falsifies `land=−1` from a site with no solver in it. At `rlag=1` — the only regime the tail permits — the structural filter admits **41** machines (44 − 3) and the topology matcher admits **0 of 400** under all three drain conventions. **That empty intersection is the round's real result.** | **MEASURED** (§5) |
| **E** | ★★ **TARGET 2's `401 of 402 / 99.8 %` IS A REPLICATED DENOMINATOR (rule 9).** Those are **89** independent word positions, counted once per algorithm sharing a byte-identical image — a **4.79×** replication. De-duplicated: **74 of 89 = 83.1 %**, against a per-image base rate of **16.0 %** and a best-of-2000 ACTION-shuffled null of **42.7 %**. **The direction survives; the strength does not.** | **MEASURED** (§3) |
| **F** | ★★★ **AND TARGET 2's WINDOW WAS A HELD-FIXED PARAMETER (rule 2, inside the pass that names rule 10).** ACTION `0x13`'s tempA consumer sits at lag **EXACTLY 8** — one 8-word motif repetition — in **35 of 40** sites (base rate at lag 8: **135 of 2670 = 5.1 %**; best-of-2000 null **20.0 %**). A window of 4 cannot see it, which is why `0x13` scored 1 of 40 and looked like a refutation of its own shipped label. **Each capture has its own tight modal lag: `0x13` at 8, `0x19` at 1, `0x14` at 2.** Nobody had measured that. | **MEASURED** (§2) |
| **G** | ★★ **`LO_ACT_CAP_TA2` RESOLVED AS FAR AS IT CAN BE: DESTINATION MEASURED, SOURCE OPEN, KEEPS SHIPPING.** ACTION `0x19` is followed by a word sourcing tempA in **74 of 89** distinct-image sites. That establishes the **destination**. It says nothing whatever about `←bus` vs `←acc`, which no experiment in any round has addressed. Per the owner's 2026-07-27 decision it keeps shipping; **all three shipped comment sites are corrected** because they stated things now measured to be false. | **CONSISTENT**; applied as documentation (§6) |
| **H** | ★★ **AND "0x13 AND 0x19 ARE ONE OPERATION IN TWO ENCODINGS" — SHIPPED IN `upd6383.cpp` AS FACT — HAS NO POSITIVE EVIDENCE.** Their consumer lags are **disjoint** (8 vs 1) and **9 of 38** distinct images use **both**, so it is not a per-program assembler convention. **Not refuted** — one operation may be scheduled two ways — but it must not be asserted. | **OPEN**; the assertion **WITHDRAWN** from both mirrors (§2 D) |
| **I** | ★ **`grot = desc` moves from OPEN to CONSISTENT-AND-FAVOURED, not FORCED.** Under `desc` the realized delay equals the host-derived value for **324 of 324** lines; under `asc`, **0 of 324**. Two legs: the host's opcode `0x67` evaluator is the only helper in the ROM multiplying by 44100/1000 and its UI unit is `ms` in 38 of 38 sites; and `desc` makes the delay a function of measured quantities only, while `asc` makes every delay depend on the region `size`, which `Program.floor_size` **hardcodes**. **The load-bearing premise is an INFERENCE about the product, and it is named, not buried.** | **CONSISTENT** (§4) |
| **J** | ★ **NOTHING BEHAVIOURAL IS APPLIED, BECAUSE NOTHING IS FORCED.** All four passes reported an empty FORCED list for Apply and I confirm it. The device diff is **provably semantics-free**: every added and removed line is a comment except the `LO_ACT_CAP_TA2` enumerator, whose **value `0x19` is unchanged**. 0 of the 42 delay-DRAM slots move; **frames COMPLETED stays 0**. | **PROVEN BY CONSTRUCTION** (§6) |

**FALSIFIED / WITHDRAWN, restated so nobody re-quotes them:** `401 of 402` and
`99.8 %` as the ACTION-0x19 figure (replicated denominator — use **74 of 89**);
`land = −1` in every context, including TARGET 1's `rlag=0` pool and TARGET 3's
`102 of 400`; "the one-cell `Line` is what voided the published 108"; "0x13 and
0x19 are one operation in two encodings" **as an assertion**; and the sentence
"what re-derives it is a two-address delay line, which nothing in dsp/tools has
yet", which was shipped in **both** mirrors and is now false on **both** halves.

---

## 1. THE HARNESS AUDIT — done first, as instructed

`python3 dsp/tools/adjudicate8.py harness`

The brief said to verify four things independently. All four, plus one the
harness's own self-tests do not ask.

**(a) Does the delay line actually delay?** Probed through `DelayDRAM` /
`DramPort` directly — not through `delayline.py delay` — with a unique marker
per frame, at five delays and **both** access orders. Population 10 runs:

```
   D      order        observed delay   verdict
   1      read-first   [1]              ok        1      write-first  [1]   ok
   3      read-first   [3]              ok        3      write-first  [3]   ok
   7      read-first   [7]              ok        7      write-first  [7]   ok
   23     read-first   [23]             ok        23     write-first  [23]  ok
   100    read-first   [100]            ok        100    write-first  [100] ok
```

The observed delay is the **unique** *d* satisfying `read[n] == wrote[n−d]` over
the settled tail — so this cannot pass by accident, and the old one-cell `Line`
cannot pass it at all (write-first gives delay 0, which is the defect round 6
found).

**(b) Can it be made to fail?** (rule 1 — a control that cannot fail is not
evidence, and neither is one that cannot pass.)

```
   grot=static (rotation frozen)      observed []     says NO
   grot=asc  (rotation reversed)      observed [57]   says NO
   g0 = 12345 (phase offset)          observed [7]    says YES -- DEGENERATE, and reported as such
```

**(c) YES to a known-good reference, NO to its twin.** comb `g=0.60 D=13`
against its own textbook reference: **ACCEPTED, relerr 0.00e+00**. The *same*
reference against the `D+1` twin: **REJECTED, relerr 7.65e−01**. Test signal 200
samples against a longest delay of 14 = **14.3 recirculations** — the brief's
"long enough to recirculate" requirement, stated numerically rather than assumed.

**(d) Does it reproduce the old published numbers through the old path?**
`delayline.py repro` = **PASS**, including the `5635`-not-`5145` correction it
documents.

**(e) THE QUESTION ITS OWN SELF-TESTS DO NOT ASK — can it represent the real
machine?** Population: **83** algorithms shipping descriptor cells, **324**
lines.

| quantity | value |
|---|---|
| lines with a POSITIVE delay under the default `grot=desc` | **324 of 324** |
| line labels | CONSISTENT 289, FORCED 33, OPEN 2 |
| region sizes | 32768 in **83 of 83** |
| lines with `D == size` (would make `asc ≡ desc`) | **0 of 324** |

**VERDICT: the harness is sound.** Its six self-tests reproduce TARGET 1's
published numbers exactly, including the `wtrail=2` pool split
(`rlag` 0/1/2 → **6 / 44 / 2**).

---

## 2. THE CAPTURE CENSUS — and the parameter TARGET 2 held fixed

`python3 dsp/tools/adjudicate8.py capture`

POPULATION (rule 9): **38 distinct body images, 2974 words.**

**(a) At TARGET 2's window of 4**, the successor matrix looks like a
refutation of the *other* shipped label:

| ACTION | n | → tempA (`SRC 0x19`) | → tempB (`SRC 0x1A`) |
|---|---|---|---|
| `0x13` | 40 | **1 / 40 = 2 %** | 1 / 40 = 2 % |
| `0x14` | 58 | 20 / 58 = 34 % | **58 / 58 = 100 %** |
| `0x19` | 89 | **74 / 89 = 83 %** | 17 / 89 = 19 % |
| `0x1A` | 19 | 16 / 19 = 84 % | 10 / 19 = 53 % |

`0x14` hits its own temp 58 of 58 and `0x13` hits tempA 1 of 40. **That reading
is wrong, and I nearly published it.**

**(b) ENUMERATE THE LAG.** The window was a parameter, not a measurement:

| pair | n | modal lag | at mode | distribution |
|---|---|---|---|---|
| `0x13` → tempA | 40 | **8** | **35 / 40** | `{3:1, 8:35, 9:4}` |
| `0x19` → tempA | 89 | **1** | 58 / 89 | `{1:58, 2:16, 5:6, 21:1, 36:1, 39:1}` |
| `0x14` → tempB | 58 | **2** | 39 / 58 | `{1:3, 2:39, 3:16}` |
| `0x1A` → tempA | 19 | 4 | 11 / 19 | `{1:4, 2:1, 4:11, 5:2}` |

**ACTION `0x13`'s tempA consumer sits one 8-word motif repetition later.** It is
a capture; the instrument was blind to it.

**(c) CONTROLS for the lag statistic** (it must be able to fail): base rate of a
tempA source at *exactly* lag 8 from an arbitrary position = **135 of 2670 =
5.1 %**; best-of-2000 ACTION-shuffled null = **20.0 %**; observed **87.5 %**.

**(d) AND THE "TWO ENCODINGS" CLAIM.** Images using `0x13`: **16 of 38**. Using
`0x19`: **20 of 38**. Using **both: 9** — `AUTO WAH+S.DELAY`, `NO OPERATION`,
`PEQ+COMPR+DIST`, `PEQ+COMPR+OVERDR`, `PEQ+COMPRESSOR`, `PEQ+DIST+DELAY`,
`PEQ+FLANGER`, `PEQ+OVERDR+DELAY`, `PEQ+S.DELAY`. Disjoint lags **and** joint
use. Unsupported, not refuted.

---

## 3. THE DENOMINATOR

`python3 dsp/tools/adjudicate8.py denom`

| denominator | count | rate |
|---|---|---|
| per-ALGORITHM (91 algorithms) | 411 of 426 | 96.5 % |
| **per-IMAGE (38 images)** | **74 of 89** | **83.1 %** |
| replication factor | | **4.79×** |
| base rate, per-image | 477 of 2974 | 16.0 % |
| null, per-image, best of 2000 | | 42.7 % |

The 133-word reverb image serves algos 16..27 **byte for byte**. Counting
per-algorithm counts one word position twelve times. `83.1 %` against `16.0 %`
is still a real signal — **ACTION `0x19` is a capture into tempA** — but `99.8 %`
must not be quoted.

---

## 4. THE ROTATION DIRECTION

`python3 dsp/tools/adjudicate8.py grot`

ENUMERATION (rule 3): `grot ∈ {desc, asc, static}` × writer form, where the
writer form is MEASURED as `base + samples` (`host-side.md` E1: opcode `0x67` is
the only opcode reaching the descriptor writer, its evaluator is the only helper
multiplying by 44100/1000, its UI unit is `ms` in 38 of 38 sites;
`target4.py shift`: 36 of 36 host-named taps land correctly, 37 live
reservations, 0 wrong).

| line | `desc` realizes | `asc` realizes |
|---|---|---|
| ROOM REVERB 1 pre-delay D=800 | 800 sm (**18.1 ms**) | 31968 sm (724.9 ms) |
| ROOM REVERB 2 pre-delay D=20 | 20 sm (**0.5 ms**) | 32748 sm (742.6 ms) |
| MULTI TAP DELAY D=6000 | 6000 sm (**136.1 ms**) | 26768 sm (607.0 ms) |
| CHORUS D=400 | 400 sm (**9.1 ms**) | 32368 sm (734.0 ms) |

Scored: lines whose realized delay equals the host-derived value —
**`desc` 324 of 324, `asc` 0 of 324.**

Second leg, needing no product argument: under `desc` the delay is a function of
**measured** quantities only (two descriptor cells); under `asc` every delay
depends on the region `size`, which `Program.floor_size` **hardcodes** to 32768.

**LABEL: CONSISTENT-AND-FAVOURED, not FORCED.** The load-bearing premise — *the
delay the host's `ms` parameter names is the delay the machine produces* — is an
inference about the product, not a measurement. `asc` is not refuted by any word
of microcode.

---

## 5. RULE 10 — the four passes against each other

`python3 dsp/tools/adjudicate8.py collide`

Five collisions; the tool prints all five in full. The two that change the
round's conclusions:

**COLLISION 1 — the premise.** Round 6 voided two ALU determinations and five
reverb searches because "the harness could not hold a delay line". TARGET 2 and
TARGET 3 independently show that was the wrong diagnosis (item **C** above).
The one-cell `Line` *is* broken — it cannot express SINGLE DELAY's
write-before-read — but the published `108` never depended on it.

**COLLISION 2 — the only surviving pool is dead.** TARGET 4's tail argument is
the pivot, so I re-derived it before letting it kill two other passes'
results. It holds, and it holds for a reason worth recording: the descriptor
values are **not** monotone in cell index (`0x1B` = 33308 **<** `0x1A` = 34393),
so BLOCKING's contiguous triple `{0x19,0x1A,0x1B}` **falls** while PIPELINED's
`{0x18,0x19,0x1A}` rises. The test therefore discriminates on a real stereo
split rather than on cell ordering — which was my P5 and my miss. Population 12
presets × 2 channels = 24 triples, 72 cells: PIPELINED **24/24** rising and
**72/72** in-buffer; BLOCKING **0/24** and **60/72**.

**Consequence, binding:** `land = −1` is refuted, so TARGET 1's `rlag=0` pool
(6 machines) and TARGET 3's `102 of 400` **both fall**. At `rlag=1` the
structural filter admits **41** and the topology matcher admits **0**.

**COLLISION 3 — the harness default.** TARGET 2 and TARGET 3 independently
refute `wdata="bus"`, which `delayline.py PARAMS` ships as the **default**. Any
ALU search that does not override it is a control that cannot fail. **Not
applied** — TARGET 3's resolution (a per-word decode, not a global switch) is
CONSISTENT, and rule 6 forbids shipping CONSISTENT.

**COLLISIONS 4 and 5** are this pass's own, §3 and §2.

---

## 6. WHAT WAS APPLIED

**Nothing behavioural. Nothing is FORCED.** All four passes reported an empty
FORCED list and I confirm it.

What *was* applied is documentation, because three shipped comment sites stated
as fact things now measured to be false:

| site | what it said | why it had to change |
|---|---|---|
| `dsp/tools/dsp_disasm.py` | "what re-derives it is a TWO-ADDRESS delay line … which nothing in dsp/tools has yet" | the line **exists** and **does not** re-derive it |
| `upd6383d.h` | same sentence, plus "that is round 6's rank-1 experiment" | idem; and the experiment was run |
| `upd6383.cpp` | "0x13 and 0x19 are ONE OPERATION IN TWO ENCODINGS"; the `0 of 5832` blamed on the memory model | unsupported (§2 D); and it was a **polarity** artefact |

**`LO_ACT_CAP_TA2` KEEPS SHIPPING** under the owner's 2026-07-27 decision:
destination measured (74 of 89), source OPEN, semantic never refuted, and
trapping it would still destroy the only executing frames a harness can be
validated against.

**The diff is provably semantics-free.** Every added and removed line in
`src/devices/cpu/upd6383/` is a comment except the `LO_ACT_CAP_TA2` enumerator
line, whose **value `0x19` is unchanged** — only its trailing comment differs.

### Before / after

Live, cold boot, fresh `nvram`, `-str 32 -nothrottle -log`, visible video,
`DSPCFG` On. Baseline = the round-6 committed table.

| | round 6 | this build |
|---|---|---|
| words executing **something** of 285 | 199 | **199** |
| words executing **FULLY** | 107 | **107** |
| words executing **addressing only** | 92 | **92** |
| words executing **nothing** | 86 | **86** |
| ★ **frames COMPLETED** | **0** | ★ **0** of 1 536 001 |
| frames that TRAPPED | 100.00 % | **100.00 %** |
| ★ **operand-pointer closure residue, last frame** | **+0** | ★ **+0** |
| residue min / max, entry pointer X | −1 / +116, `0xFF` 97.93 % | **identical** |
| input-stage audit | 0 MISMATCHED | **0 MISMATCHED** |
| **descriptor-cursor residue** | NOT TESTABLE | **still NOT TESTABLE** |
| distinct undecoded words / families | 443 / 133 | **443 / 133** |
| frame floor (216 w) tier 1 / tier 1+2 | 38.0 % / 60.6 % | **38.0 % / 60.6 %** |
| reverb image (algo 16), 133 w | 51.9 % / 75.9 % | **51.9 % / 75.9 %** |
| 38 distinct body images, 2974 w | 41.5 % / 52.6 % | **41.5 % / 52.6 %** |
| frame-floor tier-2 DET / MEAS / PARTIAL | 32 / 6 / 11 | **32 / 6 / 11** |

Frame counts differ by 348 frames (1 536 001 vs 1 536 349) because the scripted
run ends at a marginally different point; every structural invariant is identical.

**SAFETY.** `build.sh` log: **0 occurrences of `error:`**; binary
**74 405 928 bytes**, mtime fresh. `tools/publish-binary.sh` run.
`-validate kn5000` exits **0** with **0 bytes** of output.
`dsp/verify.py`: **BYTE-MATCH OK**. `tools/upd6383d_diff.sh`: **MIRRORS AGREE —
3057/3057 words render identically in C++ and Python**, text *and* the three
execution predicates. `porth_read().set_constant(0x01)` untouched.

### ⚠ THE AUDIO CHECK I RAN IS VACUOUS, AND I AM NOT COUNTING IT

The brief asks for `DSPCFG`-Off audio bit-identical to the published build. I
captured `DSPCFG` Off and On (`-wavwrite`, 4 608 003 samples each) and they are
byte-identical — **but both are SILENT: non-zero sample count 0, peak 0.**
Comparing two silent files is a control that cannot fail, so per rule 1 it earns
nothing and I report it as a null result rather than as evidence. The cause is
mine, not the driver's: the note-triggering scripts available in the tree target
KN7000 ports, and my KN5000 substitute did not register a key press either. The
safety evidence that *does* carry weight is the semantics-free diff, the
identical FRAME REPORT invariants, the 3057/3057 mirror agreement and the clean
validate.

### ⚠ AND THERE IS NOTHING TO LISTEN TO (brief item 6)

The instruction was: *if the delay line executes at last, stop counting slots and
listen.* **It does not execute.** 0 of 1 536 001 frames complete, all 42
delay-DRAM slots still trap, and the 86 TRAP words of 285 are unchanged. The DSP
contributes no audio; the output is the dry tone generator. Re-deriving a ladder
and sizing an impulse test would be describing a machine that never ran, so I
did not do it.

---

## 7. PREDICT-THEN-CHECK — 8 registered, 2 hits, 5 misses, 1 partial

`python3 dsp/tools/adjudicate8.py predict`

- **P1 — the harness will be defective, because every harness here has been.
  ★ MISS, and the most useful miss of the pass.** All six self-tests reproduce
  and three independent probes agree. The brief invited this finding and the
  measurement refused it.
- **P2 — the real line set will contain lines the harness cannot represent.
  MISS.** 324 of 324 positive; 0 of 324 degenerate.
- **P3 — `0x13`'s near-zero tempA rate refutes its shipped label. ★ MISS, and I
  nearly published it.** Zero only inside a window of 4; the consumer is at lag
  exactly 8 in 35 of 40. **I built the same class of instrument TARGET 2 did and
  it failed the same way, one lag further out.** Ninth control-without-power
  caught on this chip, and the first one caught by the pass that built it.
- **P4 — TARGET 2's 401/402 will hold at the de-duplicated denominator.
  HIT as a suspicion, MISS as a number.** 74/89.
- **P5 — TARGET 4's tail argument will have a hidden monotonicity artefact.
  MISS, and the check is what makes the argument stand.** The values are not
  monotone in cell index, so BLOCKING's contiguous triple falls.
- **P6 — `grot` will be decidable from the host anchor. PARTIAL.** Decidable
  only modulo one product inference; labelled CONSISTENT, not FORCED.
- **P7 — something will be FORCED and applicable to the device. MISS.** Zero
  behavioural changes. The only applicable finding is that three shipped
  comments were wrong.
- **P8 — the empty `rlag=1` intersection will prove to be an artefact of one of
  the two filters. OPEN — not checked.** Recorded so it is not mistaken for a
  result. It is the rank-1 question.

---

## 8. WHAT THE OTHER AGENTS NEED, RANKED

1. ★★★ **WHY DOES A PIPELINED READ (`rlag ≥ 1`) ADMIT NO TOPOLOGY AT ALL?**
   This is the whole obstruction and it is now double-locked: the tail forces
   `rlag ≥ 1` with no solver in the argument, and the topology matcher returns
   **0 of 400** there. Both filters cannot be right. **Rule 10 says find the
   parameter one of them holds fixed** — TARGET 3 §7.2b names three candidates,
   and `wdata` (item 3) is a fourth that neither filter enumerated.
2. ★★★ **DECODE ACTION `0x0D` (370 words) and `0x0E` (376) — 746 of 5894,
   12.7 %.** They are what close SINGLE DELAY's loops. Until they decode, every
   forced-polarity ALU cell is `-- NONE --`: an absence of a search, not a zero.
   Highest slot leverage on the table. **The host firmware does not name them**,
   so this is a pure-corpus job.
3. ★★ **`wdata` must be enumerated in every future ALU search, and tested as a
   PER-WORD decode.** `delayline.py`'s default is `bus`, which two passes refute;
   the default should change or every caller must override it. TARGET 3 §8.1c
   gives the discriminator. **The host firmware does not name it.**
4. ★★ **Fix the reverbs' cursor→C-RAM map** — the twelve 133-word reverbs
   resolve **0 of 33** coefficient words, so only GATED REVERB can be executed
   today. TARGET 2 called this the cheapest single unblock and I agree.
   **The host firmware DOES name these** (op-0x66 ER.LEVEL is already anchored
   to C-RAM `0xA9..0xB0` by TARGET 4), which is why it is cheap.
5. ★ **BLOCK B** — ten words, four class-A multiplies, one delay line, sitting
   *inside* the ladder, never executed by any search.
6. ★ **Do not re-derive the reverb references from `schroeder-topology.md`**:
   they were matched on the one-cell line.
7. **Use the per-image denominator (38 / 2974), not the per-algorithm one
   (91 / 5894), for any corpus frequency statistic**, and **enumerate the
   consumer lag** rather than fixing a window. Both of this pass's own new
   results came from those two moves.
