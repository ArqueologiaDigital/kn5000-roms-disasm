# SRC08 — "fix the SRC 0x08 clobber that rails PEQ's input cell"

**Offline, read-only audit of the standing task, 2026-07-31.**
Nothing was built or run. Every source claim is read from the **current working tree** of
`~/compartilhado/kn7000_mame/src/devices/cpu/upd6383/` (the file was being edited while this was
written — mtime moved twice mid-audit — so sites are cited by **function + anchor text**, never by
line number). Every runtime number is read from the newest log already in this repo,
`dsp/analysis/data/clean_vehicle_default.log.gz` (mask `0x110E446A39B440F`, clean vehicle,
2026-07-30 19:55), with the delta to today's default stated in §6.

---

## VERDICT, first

> **The write is real and unchanged. The TASK is void as named — on four independent grounds —
> and the patch it asks for must not be written: at 71 of 72 sites the store it would suppress is
> the LFO's publish.**
>
> **What is real is the VALUE, and it is not `iw45`'s doing.** The cell `iw45` overwrites is
> **already constant** when `iw45` arrives (`4 194 304`, min == max, both buckets) — the
> input-dependence was destroyed one word earlier, by the **fully-decoded** `iw35`. And the value
> `iw45` deposits is zero because the kernel accumulator is zero, traced word-by-word to
> **`§48 DELAY READ CONSUMED (SRC 0x0B): 22 773 120 times, 0 with a non-zero datum`.**
>
> This task is therefore **downstream of the current blocker** (`HANDOFF-NEXT` §1, the per-body
> descriptor map), not independent of it.

---

## 1. Is the clobber real in the current source? — the write is; the description is not

`upd6383_device::exec_alu()`, the bit-4 store block opening at

```cpp
    if ((hi & upd6383_disassembler::HI_ST)
            && !st_suppressed_live(word))               // ★ §109 bit 29
    {
        const u8 stmode = upd6383_disassembler::c_format(word)
                ? 2 : u8(upd6383_disassembler::class4(word) & 7);
        u8 stdest = m_dp;
        if (stmode == 1)
            stdest = u8(upd6383_disassembler::addr8(word) | (m_cur_unit1 ? 0x80 : 0x00));
        ...
            u64 &sacc = (m_speculative && (m_specmask & 0x4000) && m_cur_unit1)
                    ? m_accb : m_acc;
            store_mode(stmode, u8(stdest), u32(acc_to_datum(sacc)));   // §99
```

For `iw45` = `0010A0020C` = `010.A.00.20C` (`hi12 = 0x010` → `HI_ST`, no `HI_B7`, `f31 = 0`;
`class4 = 0xA` → `stmode = 2`; `lo12 = 0x20C` → `SRC 0x08`, `ACT 0x0C`):

* `st_suppressed_live()` is `(hi & HI_B7) && f31 == 1` shipped, `(hi & HI_B7) && f31 != 2` under
  mask bit 29 (**ON** in the default). `iw45` carries **no bit 7**, so it is `false` **under both
  rules** — ★ **no shipped or speculative gate in this build suppresses this store.** It fires,
  once per frame, unconditionally. **FORCED** (read at source).
* `stmode = 2` → `stdest = m_dp = 0x05`. **MEASURED** — `§104` prints `dp 05` at slot 45 and the
  `§96` writer census lists `cell 05 written by iw45 word 010A0020C`.
* The datum is **`acc_to_datum(m_acc)`** — the accumulator, converted `sext(acc,44) >> ACC_SHIFT`
  with saturation at ±`0x7FFFFF`.

### ★★ The decisive point: **no change to `SRC 0x08` can change what `iw45` writes**

`hi12` bit 4 is the store. It is read from `hi12`, and the stored datum is `m_acc`. `SRC 0x08`
selects `L`, and at this word `L` reaches exactly two places — the `ACT 0x0C` blanket capture
(`m_ta = L`) and the *next* word's `m_p` via the multiply at the bottom of `exec_alu()`. **`L`
never reaches D-RAM at `iw45`.** A `SRC 0x08` decode change is therefore *provably* incapable of
altering the write this task is named after. **FORCED.**

This was already on the record: **§111 §3, 2026-07-30** — *"§110's clobber observation stands;
only its attribution to an SRC-0x08 mis-decode falls."* The task title outlived its own
retraction by 93 sections.

### Which reading does the device implement today?

```cpp
    case 0x08:
        L = s32(util::sext(m_cram.read_dword(m_cursor) & 0xffffff, 24));
```

**`SRC 0x08` = `C-RAM[cursor]`, the COEFFICIENT.** `lfo-ramp.md`'s *unity* is **not** implemented
and is `LEDGER` **dead end #5**; it is not re-opened here. ⚠ Worth recording, because the
"live conflict" §109/§110 flagged is probably not one: the two readings are the **same arithmetic
factored differently**. The device's adder makes `SRC_TERM = bus` when `ACTION == 0x00`, so at the
LFO word `092.A.xx.200` the ramp comes out as `acc ← coef + P` with `L = coef`; `lfo-ramp.md`'s
two-step model gets the same `phase += coef` by putting unity on the *multiplicand* so that
`P = coef`. Both produce the ramp; they disagree only about which operand carries it.
**INFERRED (strong)** — offered as a reconciliation, not a change; nothing here should be built on
it without its own test.

---

## 2. Four independent reasons the named patch must not be written

| # | ground | grade |
|---|---|---|
| 1 | **`SRC 0x08` is not in the datapath that writes the cell** (§1 above). | **FORCED** (source) |
| 2 | **`iw45` IS the SEND.** `notes/dsp-k6-input-stage.md` finding 7, *"DESTINATION, over-determined 37×"*: the input stage hands the **accumulator** to the header's mix block, *"which deposits the per-unit send with `w45` (unit 0) / `w53` (unit 1) at exactly the cell the body reads first. `w45`'s cell IS the unit-0 entry pointer (FORCED: `addr8 = 0`, and w46..w49 do not move the pointer), and **38 of 38 body images make offset +0 their first D-RAM access; 34 of 38 READ it**."* Suppressing it deletes the only route from the kernel to unit 0's body. The register says the same in §3.12: *"the kernel's per-unit send stores (`iw45`, `iw53`) carry the bit-4 store — **modelled behaviour, not a bug**."* | **FORCED + MEASURED** (owning note) |
| 3 | **A `SRC 0x08` + bit-4 store suppression deletes the LFO.** Censused by `dsp/tools/src08_census.py` (new, read-only; it *asserts* the IC310 listings are absent rather than trusting it) over `dsp/disasm/*.dsm` (83 `SRC 0x08` words — the same 83 §110 counts, so the same population; the IC310/MN19413 programs 79/88/89/90/91 are **not** in this corpus, so no two-chip statistic): 72 carry bit 4, 71 of them in mode 2, and their `hi12` breakdown is `{092: 30, 094: 29, 09A: 9, 29A: 1, 412: 1, 010: 1}`. The `092`/`094` pair — **59 of 71** — is the LFO phase-accumulate + wrap idiom. The device already says so in `acc_to_datum()`: *"Of the 678 bit-4 store words, the family carrying BOTH the gate bit 7 AND f31 == 2 is 29 words, hi12 `{0x094: 29}`, SRC `{0x08: 29}` … **The wrap-word family IS the set of LFO publishers, exactly.**"* `010.A.00.20C` is a **singleton** `hi12` form in that family. | **MEASURED** (corpus, null population stated) |
| 4 | **"Rails" is a vehicle artefact.** The `0x7FFFFF` comes from `peq_rebase_bit38.log.gz` — the `peq_gain` **navigation** vehicle, which standing rule 2 restricts to *deltas only*. In the **clean** vehicle the same word deposits **0**. `0x7FFFFF` is `acc_to_datum` saturating (`791 624 113 196 >> 16 = 12 078 675 > 0x7FFFFF`), i.e. an accumulator-magnitude symptom of that vehicle's ~55 mid-run effect uploads, not a decode. | **MEASURED** (both logs) |

⇒ **Proposed `LEDGER` Tier-0b row** (I may not edit `LEDGER.md`; paste as-is):

> \| 19 \| Suppress / re-decode the **`SRC 0x08` store at `iw45`** ("the clobber that rails PEQ's
> input cell") \| ⛔ **VOID, four ways.** `SRC 0x08` is not in the write's datapath (the datum is
> `acc_to_datum(m_acc)`); K6 finding 7 FORCES `iw45` to be the unit-0 SEND; 59 of the 71 mode-2
> `SRC 0x08` bit-4 stores are the LFO publish idiom; and the "rail" is the `peq_gain` vehicle,
> not the chip. The cell is **already constant** when `iw45` arrives \| `data/SRC08_findings.md` \|

---

## 3. What IS real — and it is a different word

★ **The information is destroyed at `iw35`, not `iw45`.** Straight off the `§104` per-slot table
(clean vehicle; `mem` = the cell under the pointer **before** the slot; `*` = quiet ≠ loud):

```
  iw  word        dp   mem: quiet[..]              loud[..]
  11  0400201447  05     5084004..5084004        5084004..5084004     =    (pre-state; iw11's own
                                                                            ACT-07 bus L is
                                                                           -5012952..8388607 loud
                                                                            -- it deposits the audio)
  35  0012A001C0  05     5084004..5084004       -5012952..8388607     *    <- INPUT-DEPENDENT here
  36  0400A00000  05     4194304..4194304        4194304..4194304     =    <- constant AFTER iw35
  45  0010A0020C  05     4194304..4194304        4194304..4194304     =    <- ★ already constant
  46  080016000B  05           0..0                    0..0           =    <- what iw45 left
```

`iw35` = `012.A.00.1C0` is **fully decoded** (`alu_guard_fail` = 0: `SRC 0x07` and `ACT 0x00` both
anchored, class A, `f31 = 1`, mode 2, no bit 7). It reads the audio out of cell `0x05` onto the
bus, adds it to the accumulator, and its bit-4 store writes the **entry** accumulator
(`274 877 906 944 = 2³⁸`, i.e. `0x400000` after `>> 16`) back into the same cell. A legitimate
read-and-replace idiom — and it is what removes the input-dependence.

`iw45` then overwrites that constant with another constant. **It clobbers nothing that varies.**
§110 named the *last* writer; the writer that destroys the *information* is one word earlier.
**MEASURED**, and it is a correction to §110 §3.

### Why the send is zero — the chain, every link measured in the same log

```
  iw25  000.2.00.2D9   SRC 0x0B (delay-read reg, PLAIN GUESS) / ACT 0x19 capTA2 (ANCHORED)
                       L = 0..0        ->  tempA := 0
        ... iw25 is the LAST tempA writer before iw39 (verified by decoding all 60 kernel words:
            no ACT in {13,19} and none of the speculative tempA blanket {01,08,0C,11,16,0D,0E}
            occurs at iw26..iw38)
  iw39  410.A.FF.647   SRC 0x19 = tempA (ANCHORED), f31 = 0, class A -> the multiply runs
                       L = 0..0        ->  m_p := coef x 0 = 0
  iw41  400.A.00.21A   f31 = 0 = acc <- P
                       acc = 0..0      ->  the accumulator is dead from here to the CALL
  iw42..44             ldptr / selector words, exec_decoded(), do not touch acc
  iw45  010.A.00.20C   the SEND stores acc_to_datum(0) = 0 into cell 0x05
  iw49  400.1.0E.000   CALL unit-0 body -- which reads cell 0x05 first (K6 F7, 34/38 images)
```

and the root:

```
  §48 DELAY READ CONSUMED (SRC 0x0B): 22 773 120 times, 0 with a non-zero datum
```

**Zero non-zero data in 22.7 million delay reads.** `HANDOFF-NEXT` §1 / §200 already has the
producer side of that: *"read address == write address, so **the delay lines have ZERO
LENGTH**"*. ⇒ **The unit-0 send is structurally 0 for exactly as long as the delay line returns
0.** Nothing done at `iw45` can change that. **MEASURED**, end to end.

⚠ And per standing rule 6 this is **not** a refutation of `SRC 0x0B = the delay-read register`:
an inert reading is a hypothesis about a missing producer. Re-decoding `iw25`'s `SRC 0x0B` now
would be indistinguishable from fixing the delay, and is explicitly **not** proposed.

---

## 4. Patch specification

### 4.1 The named patch: ⛔ DO NOT WRITE IT

No file, no function, no gate. §2 gives four independent refutations, three of them from notes
that already own the words. Any patch that suppresses, redirects or re-sources the store at
`iw45` is refuted **before** it is written.

### 4.2 The one thing worth writing — and only if the loop wants empirical closure

The verdict in §3 is already decided by data in the repo, so this is **optional**. It buys one
thing: a **known-answer control on this note's own model of the store** (store-before-ALU, datum =
accumulator-on-entry). If the loop would rather not spend a run, skipping it costs nothing.

```
  FILE      src/devices/cpu/upd6383/upd6383.cpp
  FUNCTION  upd6383_device::exec_alu(u64 word)
  SITE      the `else' arm of the bit-4 store block (anchor: the two lines
              u64 &sacc = (m_speculative && (m_specmask & 0x4000) && m_cur_unit1)
                      ? m_accb : m_acc;
            immediately preceding `store_mode(stmode, ...)')
  CONDITION if (m_ab_st45 && m_cur_word == 0x0010A0020Cull) { m_ab_st45_n++; }
            else { <the existing store_mode + kwatch + watch_store + store_probe, unchanged> }
            -- leave the `m_dwr[stdest]++' line and the §69 clear block OUTSIDE the gate, so the
               A/B isolates the STORE and nothing else.
  ENV GATE  UPD6383_AB_ST45   (the u64 spec mask is EXHAUSTED; this follows the
                               UPD6383_ROTSIGN / UPD6383_BODYIX / UPD6383_CFMTIX pattern,
                               parsed in device_start() beside them and echoed with logerror)
  FIRED     u64 m_ab_st45_n;  printed in dump_frame_report() next to the §203/§201 lines:
            "upd6383: ★ §205 iw45 SEND-store suppressed: FIRED %llu times"
  DEFAULT   OFF.  m_ab_st45 = false.
```

⚠ **Gate on the WORD, not on `src == 0x08`, and not on `m_cur_iw == 45`.** `0x0010A0020C` occurs
**exactly once in the whole corpus** (verified over `dsp/disasm/*.dsm`), whereas `src == 0x08`
would also suppress header `iw0`, `iw30`, `iw33` and the 59 LFO publish words (§2 ground 3).

---

## 5. The two-sided falsifier, with numbers pre-registered

**Vehicle:** clean — cold boot, notes after ≈19 s (`scratchpad/coldnotes2.lua`), no panel
navigation, default mask. **Never** the `peq_gain` vehicle for any absolute number (standing
rule 2); "PEQ's input cell" is a misnomer anyway — `iw45` is in the **shared kernel**, so it runs
for every effect and is fully gradeable on the cold-boot CHORUS/ROOM REVERB 1 pair.

### 5.1 THE NULL (state it before reading anything else)

Measured at `0x110E446A39B440F`, `clean_vehicle_default.log.gz`:

```
  §48   DELAY READ CONSUMED (SRC 0x0B): 22 773 120 times,  0 with a non-zero datum
  §104  iw25 L 0..0 = | iw39 L 0..0 = | iw41 acc 0..0 = | iw45 mem 4194304..4194304 =
        iw46 mem 0..0 =                 <- the cell the body reads first
  §104  SUMMARY body-0 iw84..199: first acc DIFFERS at 90, first mem at 89, first L at 90
  §61   unit0/DO1 1 155 840 exec, 0 non-zero, peak 0 | unit1/DO2 1 155 840 exec, 0 non-zero
  §70   ACCA at w73: quiet min 0 max 0 | loud min 0 max 0
  §54   SILENT, DC leak 0.00 %
```

### 5.2 For the §4.2 A/B — three outcomes, and one of them refutes THIS note

Fired-count: `iw45` runs once per frame. Per standing rule 5 the pre-registration is a
**relation**, not a literal — ⚠ and the frame-ish counters in this log do **not** agree with each
other (`§61` unit-0 exec 1 155 840, `§54` quiet+loud 1 092 000, `§104` windowed `iw45` executions
657 937 + 314 063 = 972 000), because they are counted over different windows. So:
`m_ab_st45_n` **must be ≥ the §104 windowed `iw45` count** and within **5 %** of `§61`'s unit-0
exec count. A fired-count that is not ≈1 per frame means the gate is aimed at the wrong thing and
the run is void.

| | prediction | reads as |
|---|---|---|
| **P1** | `§104 iw46 mem` goes `0..0` → **`4 194 304..4 194 304`**, min == max, both buckets; `§61`/`§70`/`§54` all **unchanged** | K6 finding 7 holds; `iw45` is the SEND, it destroys nothing, and the model in §1/§3 is confirmed |
| **P2** | `§104 iw46 mem` becomes **input-dependent** (quiet ≠ loud) | ⇒ `iw45` *is* destroying live audio and the "clobber" framing was right after all. This is the **only** result that resurrects the task |
| **P3** | `§104 iw46 mem` is **neither** `0` nor `4 194 304` — in particular if it stays `0..0` | ⇒ ⛔ **THIS NOTE IS REFUTED.** The store does not happen where §1 says, or the datum is not the accumulator-on-entry. Report it as a retraction of §1/§3, not as a delay finding |

P2 is what makes this a test rather than a demonstration: the cell measured `4 194 304` min == max
in the arm that matters, so P2 *can* fire and would overturn the verdict.

### 5.3 The criterion that will grade the REAL fix — pre-register it now

§201 (`38c2c3d`), §202 (`61f63a8`) and §203 (shipped default-ON in `e997e8d`) — per-body
descriptor index, rotation sign, C-format descriptor consumption — are exactly the readings that
give the delay line length, and all three are now **ON by default**. So the next delay run can be
scored at this word **for free** — but only if the criterion is fixed in advance. In order; each
is necessary, none is sufficient alone:

```
  C1  §48's second field leaves zero:  "X with a non-zero datum",  X > 0
  C2  §104 iw25 L stops being 0..0          (the delay datum reaches the bus)
  C3  §104 iw39 L stops being 0..0          (tempA carries it)
  C4  §104 iw41 acc stops being 0..0        (the accumulator carries it to the send)
  C5  ★ §104 iw46 mem stops being 0..0 AND quiet != loud
      -- the send becomes INPUT-DEPENDENT.  This is the one that matters; standing rule 4.
  C6  only THEN may §61 unit0/DO1 and §70 ACCA be quoted -- and §70 min != max first
      (standing rule 1: two "IC311 outputs audio" claims were retracted, one a DC).
```

**What REFUTES the chain in §3:** if **C1 fires and C5 does not** — the delay line comes alive and
cell `0x05` at `iw46` is still `0..0`, or still min == max — then the send is **not** fed by the
`iw25 → iw39 → iw41 → iw45` path and this note's causal chain is wrong. That refutes §3, not the
delay work. Conversely C1 failing says nothing about §3 at all.

---

## 6. Standing-rule compliance, and what is owed a re-measurement

* ★ **Rule 11 (a blocker is a measurement, and measurements expire).** The numbers above come from
  a build **four shipped gates back**: today's default `0xB910E446A39B440F` adds bits **59, 60, 61,
  63** over that run's `0x110E446A39B440F`, plus §196–§204 and three env readings now default-ON.
  Graded accordingly:
  * **FORCED, cannot have changed** — that the store fires unconditionally, that `stdest = m_dp`,
    that the datum is `acc_to_datum(m_acc)`, that `SRC 0x08` is not in that datapath, that
    `alu_guard_fail(0x0010A0020C) = 23` (both `lo12` halves unanchored, so the word executes only
    under `alu_decoded_speculative()`'s terminal `return true`). All re-read from the tree today.
  * **MEASURED at `0x110E446A39B440F`, owed a refresh** — the `0`, the `4 194 304`, and §48's
    zero. None of the four added bits touches the kernel path (bit 59 needs `f98 == 1`, absent
    from the kernel's `SRC 0x00` words; 60/61 are delay-word addressing; 63 is ±1 LSB on host
    payloads) — so the **structure** is safe, but the delay gates now default-ON can legitimately
    move §48, which is the whole point of §5.3.
* **The null was computed first** (§5.1), and P2/P3 give the A/B a way to fail.
* **No new mask bit** — the u64 is exhausted; §4.2 is an env var with a fired-count.
* **Population hygiene** — the 83/72/71 census excludes nothing it should not: programs 79/88/89/
  90/91 (IC310/MN19413) are absent from `dsp/disasm/`, so no two-chip statistic is quoted.

---

## 7. Answer

**Real or not: NOT — not as named.** The write exists and always did, but it is the unit-0 SEND,
`SRC 0x08` is provably not in its datapath, the cell it overwrites is already constant when it
arrives, and the "rail" belongs to the `peq_gain` vehicle. There is no patch to write at `iw45`.

**The single number that would settle it:**

> **`§48 DELAY READ CONSUMED (SRC 0x0B): … with a non-zero datum` — today `0`, out of
> 22 773 120.**
>
> While that second field is zero, the kernel's unit-0 send is zero no matter what is done at
> `iw45`. The frame it becomes non-zero, `§104 iw46 mem` must leave `0..0` **and** split
> quiet ≠ loud (C5) — and if it does not, the chain in §3 is wrong.
