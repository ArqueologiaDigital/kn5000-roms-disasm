# DLYSEED: the first seeded SINGLE DELAY LLE trace, confronted (2026-09-12)

Device work toward full LLE (Felipe's goal): confront the HLE delay oracle with a real LLE trace.
Added `UPD6383_DLYSEED` (`upd6383.cpp`, default-off, observation-only) — the single-delay analogue
of BIQSEED/REVSEED — and captured the first seeded SINGLE DELAY per-word frame trace.

## Recipe (reproducible; the multi-MB trace itself is regenerable, so only the recipe is committed)
Binary built `-DKN5000_ENABLE_DSP1=1` (ARCHOPTS). From `kn7000-emulator/`:
```
DISPLAY=:0 DHLE=0 DSPCFG=3 TYPEIDX=7 NOTEMODE=0 TGM=0 \
  UPD6383_DLYSEED=1 UPD6383_TRACE_FRAME=1820000 \
  ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window -nomax \
  -autoboot_script dsp/tools/fx_ab.lua
# trace -> error.log; strip '[:dsp1] ' and confront dsp/hle/lle_oracle_delay.py
```
DSPCFG=3 = LLE + speculative ISA (so prog09 executes end to end); TYPEIDX 7 navigates to SINGLE
DELAY; DLYSEED seeds the state block every frame; TRACE_FRAME arms the per-word trace after that
frame (frame rate = 44100 Hz, one frame per sample).

## What the trace shows (graded)
- **DLYSEED seeds the right cells — MEASURED.** The single-delay body reads `mem=0x400000` (the
  seeded impulse) at iw88 and iw91 (dp=0x50), confirming both the diagnostic and the MEASURED
  state-block location 0x50..0x53 (`CORPUS-PATTERNS-SPECULATIVE-2 §`, the unit-0 base 0x50 = E0+75).
- **Body entry at iw84+ — MEASURED** (matches prog09's "I-RAM load 84"); the input-stage kernel runs
  at iw0..11 first, as decoded.
- **accb = −549 755 813 888, constant across the whole frame — confirms the documented kernel-B
  constant** (`DSP-DATAPATH-DECODE-HANDOFF §4.1`): accb is frame-invariant, the root of the SRC 0x11
  dependency cycle. Seen here independently.
- **The delay datapath is STARVED — STRONG (the direct part is MEASURED; see the caveat).** At the
  external delay-DRAM READ (iw93, `088012064B`) the operand latch **L = 0** and P = 0, and every
  downstream damping/filter MAC (iw94..102, cursor 0x04..0x09) computes P = 0 with acc = 0 — the
  whole single-delay body runs on zero (MEASURED). The body's own `mac.ta2` (iw92) stores acc(=0)
  back over cell 0x50 mid-frame (MEASURED: mem at dp=0x50 is 0x400000 at iw88/91 and 0 from iw92 on).
  ⚠ **CAVEAT (corrected on reading the trace emitter, `upd6383.cpp:5933`):** the trace's `mem`
  column is `m_dram[dp]` — the D-RAM cell at the pointer — **not** the datum fetched from the
  external delay DRAM; the fetched datum lands on the operand latch `L` (§76). So "the line is
  empty" is INFERRED from L = 0 at the tap read plus the documented blocked input route (nothing has
  ever written the line), not read off a DRAM-fetch column. Graded STRONG, not a direct DRAM
  measurement. (An earlier draft of this note called it MEASURED — retracted here.)

## What this means for the LLE
1. It **reproduces the input-route starvation at the single-delay datapath**, from a new angle: not
   just "the reverb unit is starved" (§5.1) but the single delay's own filter/damping chain is dead
   because its **external delay line is empty**. The starvation is the same root (the blocked input
   route / accb cycle), now shown concretely on a unit-0 program.
2. It **localizes the correct seed point.** BIQSEED drove the biquad because the biquad's operands
   ARE D-RAM state cells (0x64..0x67). The single delay's signal is the **external-DRAM delay tap**,
   not the D-RAM state block — and the body zeroes 0x50 mid-frame anyway. So a static D-RAM seed
   (DLYSEED v1) cannot drive it. **DLYSEED v2 must seed the EXTERNAL delay DRAM at the tap address
   (descriptor 0x26 + base G)** so the tap read returns a known impulse; then the damping one-pole +
   feedback can be confronted against `lle_oracle_delay.py`. That is the next build-lane step.
3. The kernel-B-constant accb is confirmed live — reinforcing that `SRC 0x11` cannot be split by
   capture (the honest structural boundary, `N-HLE-AS-LLE-ORACLE-2026-09-12.md §4`).

## Honest grade
The seed-visibility, body-entry, accb-constant and "body computes on zero" observations are
MEASURED from the live trace. "The delay line is empty" is STRONG (inferred from L = 0 at the tap
read + the blocked route — the trace has no DRAM-fetch column, see the caveat above). The
interpretation (signal path is external-DRAM-based; seed the external DRAM next) is STRONG. No decode was changed; DLYSEED is a
pure observation diagnostic. The positive oracle confrontation (damping one-pole arithmetic) awaits
DLYSEED v2 seeding the external delay DRAM.
