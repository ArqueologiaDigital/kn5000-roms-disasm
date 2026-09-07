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

### The mechanism, traced (2026-09-07) — the reload RUNS but writes no I-RAM

Follow-up RE + execution/write taps resolved most of the crux:

- **The I-RAM program body is PoolDir_Records field +12**, not +0/+4 (verified:
  `dsp/analysis/dsp_record_field_opcodes.py` — field +12 is opcode-3 for 48/56 effects;
  +0/+4/+8 are all opcode-0 coefficient streams). `sub_FA3A3C` emits it via
  `P7Stream_Run(field+12)` at `p7_module.s` 0xFA3B9C. So each effect *does* have a
  distinct body in ROM (48 of them).
- **The reload routines RUN on an effect change** (exec-taps,
  `notes/wsa1-probes/wsa1_effect_exec_taps.lua`): `P7Units_ServiceTask` wakes,
  `ResolveProgramsAndReload` runs, and `sub_FA3A3C` fires (+2 on a program change), with
  `P7Byte_SendCmd` emitting bytes. So it is NOT skipped.
- **Yet host_w writes ZERO DSP I-RAM** on the change (write-tap,
  `wsa1_effect_iram_writetap.lua`: 0 I-RAM writes on all three DSPs; C-RAM writes DO
  happen — IC6 +12). So the negative is now confirmed at the WRITE level, not just the
  non-zero count: runtime effect selection produces no I-RAM write at all.

### ✅ RESOLVED (raw-bus capture, 2026-09-07): the body is never on the bus — firmware-gated

The remaining question is now directly settled. A clean `LOG_DSPUP` capture (device iram
map temporarily widened to silence the per-sample unmapped-read flood; recipe in
`dsp/analysis/dsp_bus_program_scan.py`) around two effect changes shows:

- **The only cmd-0x01 PROGRAM upload on the entire bus is to 0x0030 on dest2 (IC30) — at
  boot** (bytes #1, #436). There is **no cmd-0x01 to 0x006E, ever**, and **no program
  upload of any kind after boot**.
- The effect changes produced **1923 (IC6) / 26 (IC5) post-boot bytes, all coefficient/
  descriptor framing** (0A value, 08 01 address, 00 00 D-RAM groups) — zero cmd-0x01
  program records.

⇒ **The firmware does NOT emit the per-effect I-RAM body to the DSP bus at runtime.**
`sub_FA3A3C`'s field+12 op3 `P7Stream_Run` is gated (the boot-loaded program is treated
as resident); effect changes stream only coefficients. This DIRECTLY confirms the
write-tap (0 I-RAM writes) at the bus level and **refutes the host_w-framing hypothesis**
(the body isn't on the bus in any framing — so no driver fix could load it). **The goal
of exercising more of the 918-word I-RAM corpus via effect selection is not achievable:
it is a firmware-architecture fact, not a driver limitation.** (Side note: the boot
program uploads to IC30 only; the ~48 field+12 effect bodies at I-RAM 0x6E in the pool
are never uploaded during SOUND-mode play.)

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

- ✅ **Why the reload writes no I-RAM — RESOLVED** (see the raw-bus section above): the
  firmware never puts the field+12 body on the bus at runtime; effect changes stream
  coefficients only. Not a driver bug — a firmware gate. So the goal is not reachable via
  effect selection, proven at the bus level.
- (Capture gotcha, for the record: a naive `VERBOSE|LOG_DSPUP` build floods error.log to
  >1 GB / 16 M lines from the `upd6383` device's per-sample read past its 384-word iram
  (`unmapped iram memory read from 7B7`) and never reaches the change frame; widen the
  device `iram_map` to the full 11-bit space (`map(0x000,0x7ff)`) for the capture build.
  That the device reads iram word 395 (>383) every sample is itself a device oddity worth
  a look, tangential to this finding.)
- **The only remaining runtime avenue** (unlikely to change the answer): whether some mode
  outside SOUND/COMBI play (a specific bank, a service/test mode) ever uploads the 0x6E
  bodies. Not observed in normal operation; low priority.
- Static executable-vs-data classification is DONE
  (`dsp/analysis/dsp_program_record_classify.py`): all 70 records are real programs, and
  the body is field +12 (`dsp_record_field_opcodes.py`); the task is "find why the field+12
  send produces no I-RAM write", not "drop the data".
- IC30 unit2 effect changes resolve a record but touch neither its I-RAM nor C-RAM —
  what unit2's effect program actually controls (routing? a main/reverb path?) is
  uncharacterised.
