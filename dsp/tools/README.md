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

## `SRC 0x00` — the static half (BUILD-LANE-QUEUE item 0 as replaced by 232 sect. 7.2)

| script | question it answers | how to run it |
|---|---|---|
| `src00_corpus.py` | **How many `SRC 0x00` words does the corpus actually hold, in which programs, paired with which ACTIONs and classes?** The encoding census that has to come before any reading of the code (standing rule 13). It reproduces the 3057-word corpus total as a self-test, and it reconciles 232's `648`/`605` — which include **26 C-format words that have no `src` field at all** — down to the correct **622 non-C-format words, 580 paired with `ACTION 0x00`**. It also prints the `SRC 0x00` words of the two known-mathematics programs (PARAMETRIC EQ, SINGLE DELAY), which is what makes their harnesses live falsifiers here rather than notional. | `python3 dsp/tools/src00_corpus.py` |

⚠ Partial pass — see `dsp/analysis/SRC00-HANDOFF-2026-09-04.md` for what is done, what is not, and
what was ruled out. No MAME run was taken and no falsifier requiring one was checked.
