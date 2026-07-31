# PREDICT §225 — committed BEFORE `build.sh` was run

NEC **uPD6383GF-3BA** (Technics SX-KN5000, **IC311**). Written 2026-07-31.

Three tasks, in the order their value falls:

1. **`T1` — RULE 21's BLAST RADIUS.** How much of `28/32/28` (and `2/1/2`, and `22/19/9`)
   is FREE-RUNNING rather than input-dependent? **Computable from the archived logs, no
   run.** Scored here *before* any build, from `data/*.log.gz` alone.
2. **`T2` — restate `W4` so it cannot fire on a ramp, then flip `UPD6383_LFOWRAP`.**
3. **`T3` — the cell-`0x06` LATCH-UP needs a BOOT-WINDOW instrument** whose arming is
   stated here and which distinguishes the RESET STATE from SETTLING **by construction**.

---

## 0. ★★★ `T1` — THE DISCRIMINATOR, AND WHY IT IS A PROOF AND NOT A HEURISTIC

`§224` established RULE 21: `§104`'s and `§86`'s `*` marker fires on
*quiet-range ≠ loud-range*, and a **free-running ramp sampled over two different frame
sets** trips it with no input in it whatever (cell `0x07`, the LFO phase, in every log this
project has taken). `28/32/28` is a count of exactly that marker. **So how much of it is
real?**

**THE DISCRIMINATOR IS FORCED BY THE INSTRUMENT'S OWN BUCKET PREDICATE** —
`upd6383.cpp:5589`, quoted as a predicate and not as a line:

```
        const bool nz = (m_in_val[0] != 0) || (m_in_val[1] != 0);
```

The quiet bucket is **not** "small input". It is the frames on which the input latch reads
**exactly zero on both channels** — the *same* value, on every one of the 706 040 quiet
frames `§104` profiles. Therefore:

* **`D-I` — quiet range DEGENERATE (`quiet_min == quiet_max`).**
  The slot holds **one** value whenever the input is exactly zero, and a different one when
  it is not. **Nothing free-running can do that**: a ramp, a counter or an LFO sampled over
  706 040 frames sweeps, and its quiet range cannot be a point.
  ⇒ **INPUT-DEPENDENT, PROOF-GRADE.**
* **`D-F` — quiet range NON-degenerate and the loud range CONTAINED in it.**
  The slot varies while the input is a literal constant ⇒ it carries state that evolves
  independently of the input, and the loud bucket reaches nothing the quiet bucket does not.
  ⇒ **FREE-RUNNING. The `*` is RULE 21 exactly.**
* **`D-X` — quiet range non-degenerate AND the loud range reaches outside it.**
  Free-running **plus** loud-only reach. Sub-split:
  `X-ramp` (extra reach ≤ 1 % of the quiet span — rule-21 endpoint jitter, counted with
  `D-F` as FREE), `X-sign` (quiet never negative, loud goes negative — **a ramp cannot
  change sign**, so this is evidence *for* input on top of a ramp), `X-reach` (extra reach
  > 1 %).
  `X-sign`/`X-reach` are reported as **UNDECIDED** — which is what RULE 21 says the marker
  is.

⚠ **`D-I` proves "the value differs between zero-input frames and non-zero-input frames".
It does NOT prove the value is audio.** `§221` already showed the epilogue's operands are
disjoint from the bodies; nothing here reopens that.

### 0.1 THE `T1` CONTROLS — RULE 20, FOUR OF THEM, EACH AGAINST AN ANSWER ALREADY ON RECORD

| # | known answer | source of record | must |
|---|---|---|---|
| **T1-C0** | the tallies themselves: `28/32/28`, `2/1/2`, `2/4/1`, `2/9/4`, `33/40/29`, `28/27/24`, `59/44/49`, `22/19/9` | `§215`/`§217`/`§220`–`§224`, `LEDGER` | an INDEPENDENT parser must reproduce **every one, digit for digit**, before it is used for anything new |
| **T1-C1** | cell `0x07` is the **LFO PHASE** and has no input in it | `§224` §4, `§109` | every `0x07` row must classify **FREE**, never `D-I` |
| **T1-C2** | **the experiment's own differential**: opening the send (`NOZ05`) is the *only* change between arm A and arm C | `§220` | the slots that are `*` in arm C but `=` in arm A cannot be free-running — a ramp is present in **both** arms. **The `D-I` count must equal the NEW count**, independently derived |
| **T1-C3** | the same, set-wise | `§220` | the SHARED slots (`*` in both arms) must be **exactly** the FREE-classified set |

⚠ **`T1-C2`/`T1-C3` are the sharp ones**: they use no criterion of mine at all. If the
classifier's `D-I` count disagrees with the arm-differential's NEW count, the classifier
is wrong and nothing else here may be quoted.

### 0.2 `T1`'s PRE-REGISTERED OUTCOMES — TWO-SIDED, AND I DO NOT KNOW WHICH

* **`T1-a` `28/32/28` SURVIVES** if `D-I` accounts for the large majority and the FREE
  remainder is confined to the cell-`0x07` rows. **Then say so and show the discriminator.**
* **`T1-b` `28/32/28` IS SUBSTANTIALLY FREE-RUNNING** if `D-I` is a small part of it.
  **Then say so PLAINLY AND PROMINENTLY** — it weakens (does not overturn) *"the rig
  delivers signal to the bodies"*, and I would rather know now than defend it later.
* ⚠ Whatever the answer, `2/4/1` — the shipped-default "null" that `W4` grades against —
  **must be classified too.** If the null is itself free-running, `W4` was grading noise
  against noise and the restatement below is FORCED rather than convenient.

---

## 1. `T2` — `W4` RESTATED. THE FORM, AND ITS FAILURE MODE, BEFORE THE RUN

⚠ **A gate rewritten until it passes is not a gate.** `W4′` is stated here with its
failure mode, and §2 shows it **demonstrably can fail on this exact instrument, column and
vehicle**.

> **`W4′` (restated).** Grade body 0's `§104` tally on **`D-I` markers only** — markers
> whose QUIET range is degenerate. By §0 this **cannot fire on a ramp**, which is precisely
> what RULE 21 demands.
>
> **PRE-REGISTERED VALUES:** arm I (shipped default) body-0 `D-I` = **`0/0/0`**.
> **`UPD6383_LFOWRAP=1` must also be `0/0/0`.**
>
> **`W4′` FAILS IF** any body-0 slot acquires a degenerate-quiet `*` — i.e. a slot constant
> across all 706 040 zero-input frames and different on loud frames. Then the `D-I` count
> rises above 0 and the flip does not ship.
>
> **`W4′-b` (the directional limb).** Every FREE-classified body-0 marker in the
> `LFOWRAP` arm must sit at pointer cell **`0x07`** (the LFO phase) or **`0x10`** (`§120`'s
> modulation cell, the phase's published copy). **`W4′-b` FAILS if a marker appears at any
> OTHER cell** — the reading predicts the wrap change touches those two cells and nothing
> else.
>
> **`W4′-c` (the kernel limb).** Kernel A's `D-I` count must NOT move
> (`27/21/18` in both arms). **FAILS if the wrap change leaks input-dependence into the
> kernel**, which would mean it is doing more than the reading says.

**THE OTHER GATES ARE `§224`'s, UNCHANGED, and are re-scored from `§224`'s own two arms**
(`I_s2_224.log.gz` / `J_lfowrap_224.log.gz` — same build, same vehicle, so re-running them
would produce the same log): `W0` fired 1 176 960 / one slot; `W1` −706 040 quiet /
−313 960 loud exactly; `W2` `§119 iw94 mem[dp10]` `8388607 ×8` → `1006898 … 1007696`;
`W3` `§41 = 0x400000/0x178D0B`, `m_rf[0x8D] = 0x009B26`, `§54` `826 040/826 040` SILENT,
`§70`/`§211` mean 0.0 span 0 both buckets, `§S1 iw39` loud min `1 991 044`.

### 1.1 THE FLIP ITSELF STILL NEEDS A RUN, AND ITS CONTROL IS A KNOWN ANSWER

Flipping the default is a source change, so it is graded by **run**, not by re-reading a log:

* **`K1`** arm **K** = the new shipped default, **no env at all**. Its whole `upd6383:`
  report must `diff` against `§224`'s **arm J** (`UPD6383_LFOWRAP=1`) with **not one
  measured value moved** — the only permitted differences are the reworded announcement,
  the `§S3` block that §3 adds, and counts that are counts. **`K1` FAILS on any moved
  measured value**: arm K and arm J are the same computation reached two ways.
* **`K2`** arm **L** = `UPD6383_LFOWRAP=0`, the explicit-OFF two-sided control. Its report
  must `diff` against `§224`'s **arm I** the same way. **`K2` FAILS if the env var no
  longer reverts the behaviour** — a default flip that cannot be turned off is not a
  bisectable arm.
* **`K3`** `dsp/verify.py` **BYTE-MATCH OK**.

⚠ **Nothing ships below `W0 ∧ W1 ∧ W2 ∧ W3 ∧ W4′ ∧ W4′-b ∧ W4′-c ∧ K1 ∧ K2 ∧ K3`.**
A NULL is a fine outcome and §217–§224 all correctly declined.

---

## 2. `T3` — `§S3`, THE BOOT-WINDOW INSTRUMENT. ITS ARMING, AND HOW IT BEATS RULE 16

**THE BLOCKER (`§224` §2/§7.2):** `§S2` shows `iw13`/`iw14` taking `mem[0x06]` onto the
`ACT 0x00` bus **at unity** (`bus 549 755 748 352 = 0x7FFFFF << 16`, `busSRC 00`) while
`iw19` stores the clamped accumulator back into `0x06`. `iw13`'s other two terms sum to
`0.870 × FS`, **below** the rail ⇒ the rail is a **stable second state**. `§176` on the
shipped build: `06:8388607(0..8388607/chg1100)` — **min 0**, so the cell was **not** always
railed, and only **1100** changes over 1 440 001 frames.
**Find what first drives `0x06` past the threshold.**

**THE THRESHOLD, derived and pre-registered:** with `iw13`'s two coefficient terms fixed at
`2 × 239 225 266 218 = 478 450 532 436`, full scale (`8 388 607 << 16 = 549 755 748 352`)
is reached once the bus term exceeds `71 305 215 916`, i.e. once
**`m_dram[0x06] > 1 088 031 = 0.129 703 × FS`**.

⚠⚠ **THE TENSION, STATED BEFORE IT IS RESOLVED.** `§S1`, `§S2` and `§104` all arm at frame
420 000 and cannot see the transition. But **RULE 16 exists because a boot-time sample
measures the RESET STATE** — `§46`'s descriptor claim was exactly that error, and
`§193`/`§204`'s *"a histogram over boot measures boot"* is its twin. **A boot-window
instrument that merely samples earlier repeats it.**

### 2.1 ★★★ HOW `§S3` DISTINGUISHES RESET STATE FROM SETTLING **BY CONSTRUCTION**

`§S3` does **not** sample a time window and interpret it. It records **stores**, and it
splits them by a property **of the datum itself**, not by a threshold I chose:

* **`EPOCH-0` — the pre-store value of cell `0x06` at the FIRST store to it in the entire
  run.** That value is, *by construction*, the state of the cell **before any instruction
  ever wrote it**: it is the RESET / host-initialised state, and it is printed on its own
  line with the frame it was seen at **and the count of prior writes, which must be 0**, so
  the claim is checkable rather than asserted.
* **Every LATER entry's `pre` value is, by construction, the result of a previous
  instruction** — that is SETTLING, and it cannot be anything else.

**THE VERDICT IS THE RELATION BETWEEN THE TWO, printed UNCONDITIONALLY, three ways:**

| verdict | condition | meaning |
|---|---|---|
| **`RESET-STATE`** | `EPOCH-0 pre ≥ 1 088 031` | the cell was already latched before any word ran. **There is no transition to find and the §225 question is VOID** — RULE 16 caught in the act, by the instrument, not by a later reader |
| **`SETTLING`** | `EPOCH-0 pre < 1 088 031` and some store crosses it | **that store IS the entry**, and its frame / `iw` / `pre` / `val` are printed |
| **`NO CROSSING`** | neither | a **stated** negative with its window printed — not a silent zero (RULE 20) |

**ARMING, STATED AS THE BRIEF REQUIRES: `§S3` HAS NO FRAME GATE AT ALL.** It arms on the
device's **first D-RAM store to cell `0x06`**, whenever that is, and its ladder (below) is
**unbounded in time**, so a crossing at frame 800 000 is caught as surely as one at frame 3.
The only bound is the 96-entry trajectory buffer, and it has **its own overflow counter**
(the audit's finding: `store_probe()` truncates at 4 with none).

### 2.2 WHAT `§S3` PRINTS

1. **`EPOCH-0`** — frame, `iw`, site, pre-store value, prior-write count.
2. **`TRAJECTORY`** — the first **96** stores: frame, `iw`, site, `pre`, `val`.
3. **`LADDER`** — for each of `1`, `0.01`, `0.05`, `0.129 703`, `0.50`, `0.99`, `1.00 × FS`:
   the first store to reach it, with frame / `iw` / `pre` / `val`. **Unbounded in time.**
4. **`APPROACH`** — a 16-entry ring of the stores immediately **before** the first crossing,
   frozen at the crossing. Gives the run-up whenever the crossing happens.
5. **`TOTAL`** — the unbounded store count and a per-`iw` breakdown **with an overflow flag**.
6. **`VERDICT`** — one of the three above, unconditional.

`§S3` is **READ-ONLY and ALWAYS ON**: it changes no decode, no route and no value.

### 2.3 THE `T3` CONTROLS — RULE 20 AGAIN, AND THE FIRST ONE IS EXTERNAL

| # | known answer | source of record | must |
|---|---|---|---|
| **`S3-C1`** | mask bit 26 (`§106`) counts the **identical predicate** (`mode != 1 && dest == 0x06`) at the **identical hook** (`store_mode()`) and `§220` measured it firing **5 881 351** times | `§220` arm B, `data/B_mirror06_220.log.gz` | `§S3`'s unbounded TOTAL must be **5 881 351**. ⚠ **This is a different instrument, a different pass and a different arm counting the same thing — if it disagrees, `§S3` IS WRONG and nothing else in `T3` may be quoted.** |
| **`S3-C2`** | the writers of `0x06` are `iw19 iw21 iw27 iw33 iw39` (mode 2), and **not** `iw72` (mode 1 ⇒ `§99` routes it to `m_rf`) | `§106`'s own note, `§96` | `§S3`'s per-`iw` breakdown must name **exactly that set**, 5 slots, `1 176 270` each |
| **`S3-C3`** | `§176`: `06:8388607(0..8388607/chg1100)` — **min 0** | `I_s2_224.log.gz` | `§S3`'s `EPOCH-0 pre` must be consistent with a cell whose census minimum is `0` |
| **`S3-C4`** | the host's `+0.5 = 0x400000` cold-boot level poke lands in **`m_rf[0x06]`**, not `m_dram[0x06]`, because default mask **bit 23 is SET** (`0xb910e446a39b440f`) | `§97`, `§41`, and `UNWRITTEN-CELLS_findings.md` §2.2 (`m_rf[0x06] = 4 194 304`) | `§S3` must show **no host write** among the `0x06` D-RAM stores. ⚠ **If it does, the whole `T3` reading changes**: the entry would be the host's own level write and not a settling transient at all |

### 2.4 `T3`'s PRE-REGISTERED OUTCOMES — I DO NOT KNOW WHICH, AND ALL THREE ARE RESULTS

* **`T3-a` `SETTLING`, entered over many stores** — a slow climb; the entry is named and the
  loop's forward gain from a small cell is measurable from the trajectory.
* **`T3-b` `SETTLING`, entered on the FIRST or SECOND store** — then `0` is **not** a fixed
  point at all, the loop's forward gain from an empty cell already exceeds the threshold,
  and ⇒ ★ **`§224`'s "BISTABLE" framing is RETIRED**: there is exactly ONE stable state and
  the rail is not a latch-up but an unavoidable attractor.
* **`T3-c` `RESET-STATE`** — the cell is railed before any word runs. Then the question as
  posed is void and the next question is *who put it there*, with `S3-C4` deciding whether
  it was the host.

⚠ **`T3` ships an INSTRUMENT and a MEASUREMENT. It ships no behavioural change**, and no
`0x06` fix may be proposed in §225 on the strength of one run.

---

## 3. VEHICLE — UNCHANGED FROM §217–§224

`coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated `-cfg_directory` carrying
`:DSPCFG value="3"`, `-log`, triad C4/E4/G4, `-seconds_to_run 30`, visible video (never
`-video none`), `timeout`-wrapped, **one run at a time**. `build.sh` exits 0 on compile
failure — grep `error:` **and** check the binary's mtime/size; `tools/publish-binary.sh`
after the rebuild.

**Two arms, one build:**

| arm | env |
|---|---|
| **K** | *(none)* — **the NEW shipped default, `LFOWRAP` ON** |
| **L** | `UPD6383_LFOWRAP=0` — the explicit-OFF two-sided control |

**Expected frame accounting, both arms:** `1 440 001` frames, `313 960` loud,
`§104` `nq/nl = 706040/313960`, `§54` `quiet-in 826 040`.

---

## 4. WHAT MAY SHIP, AND WHAT MAY NOT

**MAY:** `§S3` (read-only, always on); the `UPD6383_LFOWRAP` **default flip**, and only if
every gate in §1 passes; the `T1` classifier written up in the register with its controls.

**MAY NOT:** any change to `ACC_SHIFT`, `P_SHIFT`, `m_bx_sel0d`, mask bit 23, mask bit 26,
any store's datum, or any decode on the shipped path; any `0x06` "fix"; any new rig.
⛔ **Not `ACT 0x00`'s bus term as a general attenuation** (refuted for `iw34`, §224).
⛔ **Not `§S2sq`'s cursor question** — it is real, two-sided and deliberately deferred.

**Never ship a default flip on a moved number, a model argument, or a gate rewritten until
it passed.**
