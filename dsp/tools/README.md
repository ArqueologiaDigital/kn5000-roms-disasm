# dsp/tools

Scripts behind the KN5000 effects-DSP (uPD6383 / IC311) analysis. One line each: the question it
answers, and how to run it. Run from the repo root.

⚠ Three of these were rescued on 2026-08-14 from `KN7000/tmp-dir/`, an untracked scratch directory,
where they were the only copies of themselves despite being the stated evidence for published
claims. They are listed first, with their status **as re-run on the day of the rescue**.

| script | question it answers | status |
|---|---|---|
| `sqcensus.py` | which class-A multiplies **square their own coefficient**? (coef port = C-RAM[cursor] *and* operand L = C-RAM[cursor], i.e. `SRC == 0x08`) | ✅ runs — `f31 of non-sq classA: {1: 523, 0: 202, 4: 16, 2: 21}`, `f98 of squarers: {0: 79, 2: 2}` |
| `sq_ladder_226.py` | the fixed-point arithmetic of the kernel ladder and its dependence on the cursor base, computed **from disk** (no emulator run) | ✅ runs — e.g. `C-RAM[0x00] = 000072 = 114` (CHORUS LFO increment) |
| `h0_verify_effectchipmap.py` | the **gate-H0 table**: UI effect name → slot → chip → image hash, with a self-test. Produced the "12 of 12 named effects are stubs" confirmation | ❌ **ROTTED — see below** |

## h0_verify_effectchipmap.py is currently broken

It parses `v10/maincpu/ui_widgets/naka_widget_descriptors.c` for a `.ptrs_0` array to recover the
widget-name ordering:

```python
ORDER = [int(x) for x in re.findall(r"SELF\(str_(\d+)\)",
         re.search(r"\.ptrs_0\s*=\s*\{(.*?)\}", src, re.S).group(1))]
```

That field **no longer exists** — the descriptor file's arrays now start at `.ptrs_1`
(`grep -c 'ptrs_0'` returns 0), so `re.search` returns `None` and the script dies with
`AttributeError` before producing anything.

**It has deliberately not been "fixed" by nudging the index**, because which array it reads decides
the whole name→slot mapping, and a silently wrong mapping would produce a plausible but wrong
gate-H0 table — worse than no table. Whoever repairs it must establish *from the descriptor
structure* which array is the widget-name pointer list, and re-run the script's own self-test.

**Consequence to state plainly: the gate-H0 table and the "12 of 12 effects are stubs" figure are
currently unreproducible.** The claim may well be right — it was measured once — but nothing on
disk can re-derive it today.

## §232 — the unanchored `SRC`/`ACTION` census

| script | question it answers | how to run it |
|---|---|---|
| `routing_census.py` | **Per unanchored `SRC`/`ACTION` code: its sites, its INDEX RANGE, its consumer.** A code whose index is constant at every site is **CLOSED** (dead end 4 / standing rule 4 forbid implementing a consumer whose index is measured constant). It also prices each code — how many corpus words would newly decode if that one code were anchored — which is the honest payoff of the routing guard §231 named as the bottleneck. | `python3 dsp/tools/routing_census.py` for the static half (corpus only, no build); `python3 dsp/tools/routing_census.py --log dsp/analysis/data/A_232.log.gz` for the verdict, which needs the device's `§232 ROUTING CENSUS` block |

**What each half measures, and why neither alone is enough.** The *price* is a property of the
ROM and is computed from the 3057-word corpus by an **independent** mirror of
`upd6383d.h`'s `alu_guard_fail()` — deliberately not imported from `dsp_disasm`, so its seven
self-tests against §231's published breakdown (`DECODED 1178 / ROUTING 1139 / CLASS 546 /
OPERATION 106 / FORMAT 68 / GUARD 7 20`) can actually fail. The *index range* is a property of a
run and cannot be computed from the ROM at all: it comes from the device instrument
(`upd6383.h rc_record`, hooked at the single point where the operand `L` is final), which records
`m_dp`, `m_cursor`, `m_dsc` and the accumulator **per site, per `§54` bucket**.

⚠⚠ **The verdict is per SITE and rolled up — never pooled.** Four sites each holding a
*different* constant index pool into a range, and a pooled range is indistinguishable from a
varying one. `SRC 0x13` is the worked example: pooled it prints `dp 80..83 | cur 3..16` and reads
OPEN; per site it is `dp 80/81/82/83`, `cur 3/5/14/16`, every one degenerate in both buckets —
which is what §162 closed it on. (Standing rule 10.)

**Controls, printed before the finding.** Two-sided, in the device: the ANCHORED `SRC 0x07` and
`SRC 0x10` rows, whose indices are known to move — if they came out degenerate the census would
not be reading the pointers at all and every `CLOSED` would be void. External, in the tool: nine
checks against answers produced by four *other* instruments (§229's fabricated-zero sites, §231
item G's `SRC 0x0A@iw78 → store`, §224's `iw33 = 6 039 795` ladder value, §162's `acc 0..0` at the
class-6 word).

| `run_dsp_arm.sh` | **the §228/§229/§231/§232 vehicle, as a script**: the DSP research build (`CPPFLAGS=-DKN5000_ENABLE_DSP1=1`, which `build.sh` does **not** pass), an isolated `-cfg_directory` carrying `:DSPCFG value="3"`, an isolated NVRAM, `coldnotes2.lua`, `-seconds_to_run 30`, visible video, `timeout`-wrapped. It checks the three things that silently produce an empty census: compile errors behind a zero exit, a binary under 70 MB, and **a binary with no uPD6383 device in it at all** | `dsp/tools/run_dsp_arm.sh dsp/analysis/data/<arm>.log.gz` |

⚠⚠ **`KN5000_ENABLE_DSP1` defaults to 0.** With it 0 the device is not instantiated, `grep upd6383
error.log` returns nothing, and that is indistinguishable from "the instrument was never reached".
Until 2026-09-04 the vehicle lived only as prose in the register and the prose did not mention the
flag. It does now, and so does this script — which **fails loudly** rather than producing an empty
log.

## `SRC 0x00` — the corpus discrimination (BUILD-LANE-QUEUE item 0 as replaced by 232 sect. 7.2)

| script | question it answers | how to run it |
|---|---|---|
| `src00_corpus.py` | **How many `SRC 0x00` words does the corpus actually hold, in which programs, paired with which ACTIONs and classes?** The encoding census that has to come before any reading of the code (standing rule 13). It reproduces the 3057-word corpus total as a self-test, and it reconciles 232's `648`/`605` — which include **26 C-format words that have no `src` field at all** — down to the correct **622 non-C-format words, 580 paired with `ACTION 0x00`**. It also prints the `SRC 0x00` words of the two known-mathematics programs (PARAMETRIC EQ, SINGLE DELAY), which is what makes their harnesses live falsifiers here rather than notional. | `python3 dsp/tools/src00_corpus.py` |

| `gate_settle.py src00` | **Does PARAMETRIC EQ's 0.198 dB criterion separate the seven `SRC 0x00` readings?** 232 sect. 7.2 pre-registered it as a LIVE falsifier for this code, because a39 carries 8 `SRC 0x00` words. **It does not: the criterion executes 9 of a39's 105 words (its biquad section, `a39 w5..w13`, ×10) and NOT ONE of them carries the code** — the section prints an UNCONDITIONAL fired count of **0** and all seven readings score **0.198 dB**. ★ The two-sided control rewrites one executed word's SOURCE field `0x07 → 0x00` and re-scores: 6 of 6 non-`mem` readings then MOVE, over 4 distinct values, so the sweep is live and the blindness is the excerpt's. Signal read: `worst_db(M(...), banks, 512)` against the firmware's own bilinear designer; PASS = < 0.5 dB. | `python3 dsp/tools/gate_settle.py src00` |
| `sd_rerun.py src00` | **Does SINGLE DELAY's lag-1001 ROM product separate the seven `SRC 0x00` readings?** **It does, 1 of 7, and the survivor is the shipped `mem`.** a09 carries 9 `SRC 0x00` words and one of them is the HEAD WRITE `w46`, so the reading decides what enters the delay line at all. ⚠ Run naively the harness is CIRCULAR — `derive_p0()` places the head write's pointer on the driven cell, i.e. it injects the audio where `mem[ptr]` would read it. The command removes that by SWEEPING the injection cell over all 256 (p0 fixed at `0x08`; the walk is p0-invariant mod 256, so this covers every relative placement, `0x03` being the published one). Under the six rivals **no cell anywhere puts a non-zero datum into the delay line** — a statement that assumes nothing about where the output is read. Signal read: an impulse must return at the cascade lag **1001** carrying **45074**, the ROM's own `((c·c)>>23)·h>>23` product; PASS = bit-exact equality. Controls 4 of 4 (accept · refuse-on-absence · refuse-on-value with the echo present · relocation). | `python3 dsp/tools/sd_rerun.py src00` |
| `act0d0e_corpus.py` | **What does the ENCODING say about `ACT 0x0D` / `ACT 0x0E` before any harness runs (rule 13)?** Self-tests 11 of 11 against §232's `routing_census.py` (203/227 words, 79/53 encodings, 39/40 images, both SRC profiles). Measures the pairing motif — `0x0D` is immediately followed by `0x0E` at **157 of 202** sites (×9.87 over the 7.9 % base) and that `0x0E` half reads the accumulator 80 times — and a consumer census WITH ITS NULL: the known destinations of the anchored codes do not score distinctly (`acc`/`P` are read within 6 words after every code; `0x13`'s tempA scores 0 %), so the census has no power. **Verdict: the corpus cannot separate the seven readings of §133's selector**; it supplies the sites and the pair structure. Every count excludes C-format words. | `python3 dsp/tools/act0d0e_corpus.py` |
| `gate_settle.py act0d0e` | **Can PARAMETRIC EQ see `ACT 0x0D`/`0x0E`, and which of §133's seven-by-seven readings deliver the sample?** Two halves. (1) The published 0.198 dB EXCERPT (a39 `w5..w13`) does not contain the pair (`w0/w1/w53/w54`): unconditional fired count **0**, 49 pairs one value; a patched-excerpt control shows the sweep is live. (2) The ENTRY WINDOW (`w0..w13` and `w53..w67`) run with **acc = P = 0 at frame start and the sample in the D-RAM cell the entry reads** (`0x05` / `0x0F`) — instead of `peq_ir()`'s pre-load into acc and P, which is why three-codes.md item A found 144 machines identical. Signal read: the designer's biquad at < 0.5 dB on **both** banks, with bank 2 required NOT to filter `0x05`; plus a junk-pre-load control, the `f31hi` sweep for `w3`, and the pointer walk landing on §125's private ranges. **Result: the shipped pair `(acc<-bus, P<-bus)` is 1 of 49.** | `python3 dsp/tools/gate_settle.py act0d0e` (~10 min, 7 workers) |
| `sd_rerun.py act0d0e` | **Does SINGLE DELAY's lag-1001 ROM product reach `ACT 0x0D`/`0x0E`, and what does it say?** Reach test first: a09's four adjacent `0D->0E` pairs, the last immediately before the head write; fired **9208/9208** per 2302-frame pass; the old menu's tA/tB readings shown to be no-ops at every site. Then the 49 pairs at the published placement (**5 distinct outcomes**), the VALUE/reversed/relocation controls under the shipped pair, a path trace naming where the impulse goes, and the 256-cell injection sweep per pair. **Result: the criterion is live but its LAG is what the pair decides** — the shipped pair puts the same 45074 at lag 500 (line B's product is discarded at `w46`'s `acc <- P`); 37 of 49 pairs pass the pre-registered (1001, 45074) and the shipped pair is not one of them. Not a refutation of either reading; hardware question Q4. | `python3 dsp/tools/sd_rerun.py act0d0e` (~25 min, 7 workers) |
| `sd_rerun.py multitap` | **In a10 MULTI TAP DELAY — one write, four descriptor-fixed read lags (26685/20685/14685/8685), the pair at `w5/w6`, `w59/w60`, `w64/w65` — which taps does each of the 49 pairs present?** A consistency check in a delay context with no stage-order derivation. Declared model gaps: two ALT words run as no-ops; the second damping block takes the first's coefficients (a10's upload is 15 cells for 18 fetches); `C-RAM[0x06] = 0` is the fourth tap's real gain, so three taps are expected. Only tap PRESENCE and LAG are read. **Result (§234): it ran to completion and grades nothing — no pair reproduces the three taps (best 1 of 4 for 42 pairs, 0 of 4 for 7, the shipped pair among them), so rule 20's known-good case fails; a printed failed control, not evidence for or against any reading.** The seven at 0 of 4 are the seven the PEQ pre-load control lists. Archive `dsp/analysis/data/S_234_sd_multitap.log.gz`; re-run byte-identical. | `python3 dsp/tools/sd_rerun.py multitap` (~10 min, 7 workers) |
| `sd_rerun.py scan` | ⚠ The ORIGINAL presence test over the old six-reading menu. It crashed (`KeyError: 46`) from §230 until §234 and its menu never held the shipped reading; repaired and kept only so its numbers stay reproducible. **Not graded — use `act0d0e`.** | `python3 dsp/tools/sd_rerun.py scan` |

★ Both were run in 233; the discrimination is `1 of 7` and the device's shipped reading SURVIVES.
See `dsp/analysis/SPECULATIVE-APPLIED-REGISTER.md` §233. `SRC00-HANDOFF-2026-09-04.md` records the
partial pass that produced `src00_corpus.py`; its sect. 4 is now CONSUMED.
