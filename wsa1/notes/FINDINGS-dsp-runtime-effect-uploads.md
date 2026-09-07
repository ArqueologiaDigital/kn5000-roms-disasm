# Runtime WSA1R DSP uploads are COEFFICIENT-driven, not I-RAM re-programmed

**Date 2026-09-07.** Measured in-emulator on a `WSA1R_ENABLE_DSP=1` build with the
three `upd6383` devices instantiated. Instrument: `kn7000_mame/tools/rigs/
wsa1_dsp_effect_sweep.lua` (committed). This answers "does selecting each effect at
runtime fill more of the DSPs' I-RAM and C-RAM, exercising more of the 918-word
corpus?" — and the answer is **C-RAM yes, I-RAM no**.

## How effects were driven (deterministic, real firmware)

Each unit's effect is byte +0 of a 26-byte CPU-2 unit block; CPU 1 delivers it over
link channel 1 into the "twin" inbox and `P7Units_ServiceTask` resolves+reloads on a
change flag (RE'd by workflow wf_6046d59e-9fc; addresses in `p7/p7_module.s`
:19016/:19429, `PoolDir_RecordForUnitProgram` 0xFDC551). The rig writes the twin
program byte (`0x7E7E`/`0x7E98`/`0x7EB2`, +0x1A·unit) and sets the change flag
(`0x7ECC`, bit `1<<(unit+1)`) — **the exact bytes CPU 1's link handler writes**
(Link_Ch1_WriteParamBlock subcmd 0x81/0x82/0x83), so the ensuing `P7Stream_Run`
upload is 100% real firmware. `live` (`0x856E`/`0x8588`/`0x85A2`) and the resolved
record (`0x8586`/`0x85A0`/`0x85BA`) confirm each change landed.

## What was measured

| DSP | unit | boot I-RAM | boot C-RAM | after sweeping the 55 real effects |
|---|---|---|---|---|
| IC30 | 2 | 63 words / 45 distinct | 0 cells | I-RAM **unchanged** (45 distinct); C-RAM **still 0** |
| IC6 | 0 | 0 | 79 cells / 37 distinct values | C-RAM **37→47 distinct / 79→91 cells**; I-RAM still 0 |
| IC5 | 1 | 0 | 54 cells / 19 distinct values | same shape as IC6 (coefficients grow; no I-RAM) |

- **Exhaustive**: sweeping unit2 across **all 128 programs** exercised **55 distinct
  resolved records** (0..55 minus the NO-OP record 53) and IC30's I-RAM stayed
  byte-identical every single time (distinct words 45→45).
- **I-RAM is invariant** across every trigger tried: per-unit effect change, group
  reload (`P7Units_ReloadForGroup`, toggling `0xF361`), a 3-unit combi, and clearing
  the per-unit preamble latch (`0xF354`+2·unit) before a reload. C-RAM *did* change
  under these (capture-live control), so the invariance is real, not a capture miss.

## The architecture this reveals (MEASURED)

- **IC30 is the PROGRAM DSP**: a resident I-RAM kernel (63 words / 45 distinct),
  loaded once at boot, with an empty C-RAM. It is not re-programmed by effect changes.
- **IC6 / IC5 are COEFFICIENT DSPs**: C-RAM-driven, no I-RAM program. Effect changes
  re-upload their C-RAM coefficients.
- So **runtime effect selection is coefficient-driven**: it swaps C-RAM values on
  IC6/IC5; it never re-programs any DSP's microcode.

## Consequence for the 918-word "corpus" (the important part)

The static pool has **70 opcode-3 (program) records → 5,777 words / 918 distinct**
(`dsp/analysis/wsa1_dsp_isa_crossval.py`). At runtime **only 45 distinct I-RAM words
are ever resident** (IC30's kernel), and **none of the tested triggers uploaded any of
the rest**.

**Measured-resident executable surface (a decode advance).**
`dsp/analysis/dsp_runtime_resident_vs_corpus.py` cross-checks the 45 runtime-resident
words against the static corpus: **45/45 are container-valid AND 45/45 are in the
918-word corpus** — the runtime kernel is a genuine subset, and exactly **45 of 918
(4.9%)** static words are proven-executed (baseline: `runtime-resident-iram-words.txt`).

⚠ **The other ~873 are NOT data** — an earlier revision of this note guessed they were
coefficient/data framed as opcode-3; `dsp/analysis/dsp_program_record_classify.py`
**refutes that**: all 70 records are **100% container-valid** and most decode well above
the ~22% field-shuffle null (many 40–70%). They are **genuine effect-body programs** —
the runtime kernel is record #69 (addr 0x0030, 45/45 words); ~60 distinct effect bodies
sit at I-RAM address 0x6E. So the 918-word corpus is real code; the runtime just did not
upload the per-effect bodies through the triggers tested here.

⚠ **This REFUTES the earlier note** (`FINDINGS-dsp-upload-deframed.md`, "Insights"):
"Only 63/384 of IC30's I-RAM is filled at boot — the rest loads when effects are
selected." Measured: the rest does **not** load on the twin-poke effect change, nor on
group/combi/preamble-clear reloads. Corrected there in the same commit.

⚠ **OPEN, and this is the crux (not "refuted"):** ~60 real effect-body programs exist in
ROM at I-RAM 0x6E but the tested triggers did not upload them. The boot block itself
spans 0x30..~0x6E, so the bodies overlap the kernel tail and a per-effect body upload
*would* be visible if it happened. Why it does not — whether the effect→record directory
maps every reachable effect's body to the resident kernel, whether the body is *staged*
(`P7Stream_StageAndSend`) but committed only on an event not triggered here (audio-active?
a separate commit?), or whether a body-uploading trigger simply has not been found — is
the open question. The goal of exercising more of the corpus at runtime is therefore
**open**, not refuted: the corpus is real; the upload trigger is unidentified.

## What was and wasn't achieved vs the stated goal

- ✅ **Per-effect DSP uploads captured at runtime**, not just boot: all 55 real
  effects, driven through the real firmware path, with the devices loaded live.
- ✅ **More C-RAM filled at runtime**: IC6 coefficient vocabulary 37→47 distinct
  values (IC5 likewise).
- ⏳ **More of the 918-word I-RAM corpus was NOT exercised by the tested triggers** —
  effect change, group/combi reload, preamble-clear all moved only C-RAM. Measured, but
  NOT proof the corpus can never be exercised: ~60 real effect-body programs demonstrably
  exist in ROM (classifier), so the missing piece is the trigger that commits a per-effect
  body to I-RAM. The goal is **open**, not refuted.

## Still open

- **The body-upload trigger (the crux).** ~60 container-valid effect-body programs sit at
  I-RAM 0x6E in the pool, but none uploaded on the tested triggers. Resolve whether the
  effect→PoolDir_Records directory maps every reachable effect's body pointer (field +4)
  to the resident kernel, or whether `P7Stream_StageAndSend` stages a body that a later
  event commits (trace `sub_FA3A3C` → `P7Unit_LoadProgramStreams` and what gates its DSP
  write). This is the path to actually exercising the corpus at runtime.
- Static executable-vs-data classification is DONE
  (`dsp/analysis/dsp_program_record_classify.py`): all 70 records are real programs, so
  the task is not "drop the data" but "find the trigger that loads the other 60+".
- IC30 unit2 effect changes resolve a record but touch neither its I-RAM nor C-RAM —
  what unit2's effect program actually controls (routing? a main/reverb path?) is
  uncharacterised.
