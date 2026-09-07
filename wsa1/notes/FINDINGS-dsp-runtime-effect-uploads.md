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
(`dsp/analysis/wsa1_dsp_isa_crossval.py`). But at runtime **only 45 distinct I-RAM
words are ever resident** (IC30's kernel), and **no effect selection uploads any of
the rest**. This is strong new evidence that the static "program corpus" is dominated
by content that is **never executed as microcode** at runtime — consistent with the
low static decode rate (WSA1R 34.48%, near the field-shuffle null 22.43%): much of it
is data/coefficient bytecode framed as opcode-3, not executable instructions. The 45
runtime-resident words are the ones with a genuine execution context.

⚠ **This REFUTES the earlier note** (`FINDINGS-dsp-upload-deframed.md`, "Insights"):
"Only 63/384 of IC30's I-RAM is filled at boot — the rest loads when effects are
selected." Measured: the rest does **not** load on effect selection (nor on group/
combi/preamble-clear reloads). Corrected there in the same commit.

## What was and wasn't achieved vs the stated goal

- ✅ **Per-effect DSP uploads captured at runtime**, not just boot: all 55 real
  effects, driven through the real firmware path, with the devices loaded live.
- ✅ **More C-RAM filled at runtime**: IC6 coefficient vocabulary 37→47 distinct
  values (IC5 likewise).
- ❌ **More of the 918-word I-RAM corpus is NOT exercised** by effect selection — the
  hardware does not re-program the DSPs per effect. This is a measured property of the
  instrument, not a rig limitation.

## Still open

- WHERE (if anywhere) the other 69 opcode-3 pool records are consumed — a different
  product variant, a mode not reachable in SOUND/COMBI play, or genuinely dead/data.
  A static pass classifying each opcode-3 record as executable-microcode vs
  coefficient-data (using the runtime 45-word kernel as ground truth) is the next step
  and would sharpen the real ISA decode surface.
- IC30 unit2 effect changes resolve a record but touch neither its I-RAM nor C-RAM —
  what unit2's effect program actually controls (routing? a main/reverb path?) is
  uncharacterised.
