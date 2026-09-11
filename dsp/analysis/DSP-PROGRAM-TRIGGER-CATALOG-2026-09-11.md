# KN5000 effects-DSP — program trigger catalog and live-capture plan

**Date:** 2026-09-11
**Chip:** IC311, NEC uPD6383GF (unit-0 effects DSP + unit-1 reverb tank)
**Scope:** the 38 distinct effects-DSP program images plus the 12 named UI stubs; how to reach
each one from the control panel, what has actually been triggered and captured live, and an
ordered plan to run the rest and inspect their runtime behaviour.

**Sources merged in this document:**
- Program catalog — `dsp/programs.tsv` (40 lines) and `dsp/disasm/prog*.dsm` headers; stub set
  from project memory `kn5000-twelve-stub-effects` (disasm commits 89a24f6 / 85ecca2).
- Navigation / selection — notes `kn7000_mame/notes/kn5000-dsp-paramlist.md`; capture
  `kn7000_mame/tools/kn5000_dsp_paramlist_capture.json`; rigs
  `dsp/tools/peq_gain.lua`, `dsp/tools/reverb_select.lua`.
- Run status — `dsp/analysis/unblocking-and-discriminators.md`,
  `dsp/analysis/single-delay-restored.md`; live captures under `dsp/analysis/data/`;
  MAME rig `kn7000_mame/tools/rigs/kn5000_dsp_frame_trace.lua`.

**Two senses of "run" are kept strictly apart throughout:**
- **executes** — microcode runs to completion in the *Python speculative-machine simulator*
  (the harness of `unblocking-and-discriminators.md` / `single-delay-restored.md`). This is **not**
  MAME.
- **triggered + captured** — the effect was **selected on the panel via a MAME rig** on the
  `KN5000_ENABLE_DSP1` device core and a **live frame trace** was captured this project.

> HONEST BOTTOM LINE (from `execution_summary`): 36 of 38 images **execute** in the Python
> harness (with *enumerated, not decoded* blockers); 2 remain blocked. Only **3 of 38** have been
> **triggered + captured live in MAME**: CHORUS, PARAMETRIC EQ, ROOM REVERB 1.

---

## 1. Full program listing with trigger prerequisites

### 1.1 The generic reach sequence (control-panel button presses)

Every array-selectable effect is reached by the same measured sequence (from `peq_gain.lua` /
`reverb_select.lua`, all times relative to the boot-settle gate). "N" below is the target's
**TYPE index** (0-based index into the page's list).

1. **Boot settle:** do nothing until `mach.time >= 19.0s`.
2. **DSP present strap:** set every field of the `:DSPCFG` port `user_value = 3`. This is the MAME
   DSP-present strap (on real hardware = the DSP board being fitted), **not** a panel button.
3. **DSP EFFECT ON:** tap `CPR_SEG3` mask `0x04` (0.35s) on the HOME screen. (These HOME-screen
   toggles never open an editor.)
4. **Open SOUND menu:** tap `CPR_SEG10` mask `0x04` (page `0x01 -> 0x02`), wait ~1.5s.
5. **Open the editor page:**
   - DSP EFFECT page (`0x0B`): tap `CPL_SEG7` mask `0x02`, wait ~1.5s.
   - DIGITAL REVERB page (`0x0A`): tap `CPL_SEG8` mask `0x02`, wait ~1.5s.
6. **Saturate to index 0:** 40x tap `CPL_SEG10` mask `0x10` (TYPE DOWN, 0.08s each). The list does
   **not wrap** (saturates, Felipe-confirmed), so this lands deterministically on the first entry.
   Wait ~1.2s.
7. **Step to target:** N x tap `CPL_SEG10` mask `0x20` (TYPE UP, 0.10s each), wait ~1.5s.
8. **RULE-12 audio:** play C4/E4/G4 on the `:KEY2` port so the chip actually processes signal.

**Timing caveat (paramlist.md sect.1):** the LCD *lags* RAM near a TYPE change — the loader
updates `RAM[0x29AC]` a few frames before the LCD redraws. Wait ~1.0–1.5s after the last press
before snapshotting. `report()` reads type at `RAM[0x8D38]`, count at `RAM[0x29AA]`, name buffer at
DRAM `0x30AE5` (the name buffer is unreliable — the screenshot is authoritative for names).

**TYPEIDX → name mapping is firmly grounded:** `peq_gain.lua` defaults `TYPEIDX=15` with the
comment "UP to PARAMETRIC EQ", and PARAMETRIC EQ sits at index 15 in `effects_order`
(CHORUS = 0). So **TYPEIDX == 0-based index into `effects_order` after saturating TYPE DOWN.**

> **Discrepancy to flag:** the navigation notes describe the DSP EFFECT page as **38** selectable
> entries (index 0..37), but the rig headers (`type_select.lua`, `type_enum.lua`) speak of a
> **"36-entry list (0..35)"** / "~36–40 TYPE slots". This 36-vs-38 count is unresolved in the
> inputs. The table below uses the documented 38-entry `effects_order`; a per-run fingerprint of the
> uploaded program is still required to confirm the landing slot for distant targets.

### 1.2 Page map (which page hosts what)

| Page | Type hex | Opened from SOUND menu by | Hosts an array-selectable effect list? |
|---|---|---|---|
| SOUND MENU (gateway) | `0x01 -> 0x02` | `CPR_SEG10` mask `0x04` | No — gateway only |
| **DSP EFFECT** | `0x0B` | `CPL_SEG7` mask `0x02` (RIGHT-4) | **Yes** — 38 entries, `effects_order` |
| **DIGITAL REVERB** | `0x0A` | `CPL_SEG8` mask `0x02` (RIGHT-2) | **Yes** — 12 reverbs + 2 delays |
| EQUALIZER | `0x0C` | `CPL_SEG8` mask `0x01` (RIGHT-3) | No — fixed 8-slot master 4-band EQ (loader `0x4C10`) |
| ACOUSTIC ILLUSION | `0x0E` | `CPL_SEG7` mask `0x01` (RIGHT-5) | No — fixed 4-choice TYPE + level (loader `0x4E10`) |
| REVERB & EQ PRESETS | `0x09` | `CPL_SEG8` mask `0x04` (RIGHT-1) | No — preset selector only |

EQUALIZER (`0x0C`) and ACOUSTIC ILLUSION (`0x0E`) have TYPE fields but they are **fixed hard-coded
layouts**, not the `0x29AC` name array, so they host no array-selectable DSP program image. The
ACOUSTIC ILLUSION up/down button is **inferred** to be the same `CPL_SEG10 0x20/0x10` (untested).

### 1.3 DSP EFFECT page (type `0x0B`) — 38 selectable entries

Reach: sequence §1.1 with step 5 = `CPL_SEG7` 0x02, then TYPE UP **N = TYPEIDX** times.
"Image algo" is the distinct program image loaded (from the catalog); "run" columns are from RUN
STATUS. `exec` = executes-in-Python-harness; `live` = triggered+captured live in MAME.

| TYPEIDX | UI name (effects_order) | Image algo | Unit | Family | Decode | Stub? | exec | live |
|---:|---|---:|---:|---|---|---|---|---|
| 0 | CHORUS | 1 | 0 | modulation | high | no | yes | **YES** |
| 1 | MODULATED CHORUS | 2 | 0 | modulation | high | no | yes | no |
| 2 | ENHANCER | 3 | 0 | filter | medium | no | yes | no |
| 3 | FLANGER | 4 | 0 | modulation | medium | no | yes | no |
| 4 | PHASER | 5 | 0 | modulation | medium | no | yes | no |
| 5 | ENSEMBLE | 6 | 0 | modulation | medium | no | yes | no |
| 6 | GATED REVERB | 8 | 0 | reverb (unit-0) | medium | no | yes | no |
| 7 | SINGLE DELAY | 9 | 0 | delay | high | no | yes (native) | no |
| 8 | MULTI TAP DELAY | 10 | 0 | delay | high | no | **partial** (blocked w52, missing coef) | no |
| 9 | DISTORTION | 32 | 0 | distortion | high | no | yes | no |
| 10 | OVERDRIVE | 33 | 0 | distortion | high | no | yes | no |
| 11 | FUZZ | 34 | 0 | distortion | high | no | yes | no |
| 12 | EXCITER | 35 | 0 | exciter | high | no | yes | no |
| 13 | COMPRESSOR | 36 | 0 | dynamics | medium | no | yes | no |
| 14 | **SLOW ATTACKER** | 37 | 0 | stub | medium | **STUB** | yes (via NO-OP) | no |
| 15 | PARAMETRIC EQ | 39 | 0 | eq | **SOLVED** | no | yes | **YES** |
| 16 | AUTO PAN | 48 | 0 | am | high | no | yes | no |
| 17 | VIBRATO | 50 | 0 | modulation | high | no | yes | no |
| 18 | AUTO WAH | 52 | 0 | filter | medium | no | yes | no |
| 19 | **ROTARY SPEAKER** | 53 (→ shares algo 15 image) | 0 | rotary | high | no | yes | no |
| 20 | ROCK ROTARY | 15 | 0 | rotary | high | no | **partial** (blocked w42, ACT 0x1D) | no |
| 21 | RING MODULATOR | 54 | 0 | am | high | no | yes | no |
| 22 | MIX UP | 56 | 0 | modulation | medium | no | yes | no |
| 23 | S. DELAY+CHORUS | 64 | 0 | combi | high | no | yes | no |
| 24 | S. DELAY+S. DELAY | 65 | 0 | delay | high | no | yes | no |
| 25 | S. DELAY+FLANGER | 66 | 0 | combi | medium | no | yes | no |
| 26 | S. DELAY+VIBRATO | 67 | 0 | combi | high | no | yes | no |
| 27 | S. DELAY+PHASER | 68 | 0 | combi | medium | no | yes | no |
| 28 | AUTO WAH+S. DELAY | 70 | 0 | combi | medium | no | yes | no |
| 29 | PEQ+CHORUS | 71 | 0 | combi | high | no | yes | no |
| 30 | PEQ+S. DELAY | 72 | 0 | combi | high | no | yes (native) | no |
| 31 | PEQ+FLANGER | 73 | 0 | combi | high | no | yes | no |
| 32 | PEQ+VIBRATO | 74 | 0 | combi | high | no | yes | no |
| 33 | PEQ+COMPRESSOR | 75 | 0 | combi | high | no | yes | no |
| 34 | PEQ+COMPR+DIST | 96 | 0 | combi | high | no | yes | no |
| 35 | PEQ+COMPR+OVERDR | 97 | 0 | combi | high | no | yes | no |
| 36 | PEQ+DIST+DELAY | 98 | 0 | combi | high | no | yes | no |
| 37 | PEQ+OVERDR+DELAY | 99 | 0 | combi | high | no | yes | no |

Notes on this table:
- **ROTARY SPEAKER (TYPEIDX 19, algo 53)** is a selectable UI entry but is **not a distinct
  image**: it shares ROCK ROTARY's image (the catalog records algo 15's image is "shared with algo
  53"). Its coefficients differ; its microcode image is ROCK ROTARY's — which is one of the two
  still-blocked images in the harness.
- **SLOW ATTACKER (TYPEIDX 14, algo 37)** is a **stub**: byte-identical to the NO OPERATION image
  (algo 0). It *alone* among the stubs carries live parameter values (THRESHOLD / ATTACK RATE /
  RELEASE RATE / VOLUME / REV SEND) over the no-op program and is confirmed user-selectable.
  Predicted indistinguishable from "no effect" — **open hardware-test ask to Felipe.**
- UI entries that share one name-index list differ only in coefficients, not UI:
  FLANGER == PHASER; DISTORTION == OVERDRIVE == FUZZ; ROTARY SPEAKER == ROCK ROTARY;
  PEQ+COMPR+DIST == PEQ+COMPR+OVERDR; PEQ+DIST+DELAY == PEQ+OVERDR+DELAY.

### 1.4 DIGITAL REVERB page (type `0x0A`) — 12 reverbs + 2 delays

Reach: sequence §1.1 with step 5 = `CPL_SEG8` 0x02 (opens page `0x0A`), then TYPE UP N times.
**All 12 reverbs load the single unit-1 image ROOM REVERB 1 (algo 16, I-RAM load 200), decoded to
the bit;** they differ only in coefficients (algos 16–27 share the image). The two delays are the
REV-SEND-less variants of the unit-0 delays.

| TYPEIDX (grouping) | UI name (reverb_order) | Image algo | Unit | Decode | exec | live |
|---:|---|---:|---:|---|---|---|
| 0 | ROOM REVERB 1 | 16 | 1 | **SOLVED** | yes | **YES** |
| 1 | ROOM REVERB 2 | 17 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 2 | PLATE REVERB 1 | 18 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 3 | PLATE REVERB 2 | 19 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 4 | CONCERT REVERB 1 | 20 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 5 | CONCERT REVERB 2 | 21 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 6 | DARK REVERB 1 | 22 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 7 | DARK REVERB 2 | 23 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 8 | BRIGHT REVERB 1 | 24 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 9 | BRIGHT REVERB 2 | 25 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 10 | WAVE REVERB 1 | 26 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| 11 | WAVE REVERB 2 | 27 (→ algo 16 image) | 1 | SOLVED (shared) | yes | no |
| (in list) | SINGLE DELAY (reverb page) | 9 | 0 | high | yes (native) | no |
| (in list) | MULTI TAP DELAY (reverb page) | 10 | 0 | high | partial | no |

> **Reverb ordering is INFERRED, not fully enumerated.** All 12 reverbs share one identical
> name-index array `[34,35,36,37,2]`, so a content capture cannot distinguish their TYPE ordinal.
> The order above is the documented *grouping* from `kn5000_dsp_paramlist_capture.json`; the exact
> ordinal position of each reverb, and where SINGLE DELAY / MULTI TAP DELAY fall in the TYPE
> sequence, is not established by a saturate-down sweep in the provided files. Treat TYPEIDX for
> reverbs 1–11 as approximate. ROOM REVERB 1 = index 0 is the only one confirmed (captured live).
>
> **Verified nuance (`kn5000_dsp_paramlist_capture.json`, 46 entries):** that enumeration walk lists
> the reverbs as a CONTINUATION of the same TYPE list — ROOM REVERB 1/2 at index **38**, PLATE 1/2 at
> 39, CONCERT 1/2 at 40, DARK 1/2 at 41, … — i.e. the walk stepped TYPE UP past the 38 DSP-EFFECT
> entries straight into the reverbs, pairing them two-per-index. This is in tension with the
> paramlist notes, which reach the reverbs via a SEPARATE page (`0x0A`, `CPL_SEG8 0x02`). Resolve
> empirically: the authoritative route for a rig is the page open (`reverb_select.lua`, page `0x0A`);
> whether the reverbs are ALSO reachable by continuing TYPE UP on `0x0B` is an open question the
> saturate sweep will answer. The two-per-index pairing also means a content walk cannot separate
> "REVERB 1" from "REVERB 2" — only a coefficient capture per preset can.

### 1.5 Distinct images NOT on any array page, and the un-located stubs

| Name | Algo | Unit | Family | Decode | Stub? | Panel location |
|---|---:|---:|---|---|---|---|
| NO OPERATION | 0 | 0 | dynamics | medium | no | **Not a UI entry** — the shared 49-word base image behind 42 slots incl. the 12 stubs; never selected as itself |
| MODULATION DELAY | 11 | 0 | stub | medium | **STUB** | **Not in the provided nav list** (see below) |
| NOISE FLANGER | 38 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| CEL | 44 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| CELM | 45 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| PITCH SHIFTER | 49 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| PEDAL WAH | 51 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| HARS EFFECT | 55 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| STRING | 63 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| PEDAL WAH+DELAY | 69 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| DS_D | 80 | 0 | stub | medium | **STUB** | Not in the provided nav list |
| OVER_D | 81 | 0 | stub | medium | **STUB** | Not in the provided nav list |

> **Discrepancy to flag:** the catalog/memory records **12 named UI stubs** (algos
> 11/37/38/44/45/49/51/55/63/69/80/81), each shipping the NO OPERATION image byte-identical. But the
> navigation `effects_order` (the enumerated DSP EFFECT page list) contains **only SLOW ATTACKER**
> (algo 37, TYPEIDX 14) of these twelve. The other **11 stub names are documented in the catalog but
> are not located on any page by the provided navigation data** — their TYPE index / page is
> **unknown** from these inputs. They may be filtered out of the live UI, appear only when specific
> hardware is present, or be a name set not exposed by the `type_enum` walk that produced
> `effects_order`. This is unresolved and should not be papered over.

### 1.6 Summary counts (from the catalog)

- **38 distinct IC311 program images** (37 on unit-0 / I-RAM load 84; exactly 1 on unit-1 / I-RAM
  load 200 = ROOM REVERB 1, shared by all 12 reverb presets algos 16–27).
- Family counts over the 38: combi 14, modulation 7, delay 3, distortion 3, reverb 2, filter 2,
  dynamics 2, am 2, rotary 1, exciter 1, eq 1.
- Decode status over the 38: **SOLVED 2** (PARAMETRIC EQ algo 39 = the reference program; ROOM
  REVERB 1 algo 16 — both decoded to the bit, biquad datapath), high 24, medium 12.
- Beyond the 38: **12 named UI stubs**, each byte-identical to NO OPERATION and *not* present on the
  IC310 second DSP; excluded from the distinct-image count.

---

## 2. What we have run so far

### 2.1 Triggered + captured live in MAME — 3 of 38

These three were **selected via a MAME rig on the `KN5000_ENABLE_DSP1` device core and a live frame
trace captured this project**. This is the only tier that is a real hardware-emulation capture.

| Program | Algo | Page | How selected | Live captures (under `dsp/analysis/data/`) |
|---|---:|---|---|---|
| **CHORUS** | 1 | DSP EFFECT `0x0B` | **Cold-boot default**; `kn5000_dsp_frame_trace.lua` NAV=0 | `kn5000-dsp-live-frame-trace-2026-09-10.txt` — full **285-word frame** with a C4/E4/G4 melody note, **audio verified (WAV RMS 550)**; `lle_trace_diff.py` confirmed the accumulator op live; LFO ramp 114/frame also reproduced in the Python harness |
| **PARAMETRIC EQ** | 39 | DSP EFFECT `0x0B`, TYPEIDX=15 | `peq_gain.lua` / `peq_select.lua`; `frame_trace.lua` NAV=1 TYPEIDX=15 | `kn5000-dsp-eq-biquad-trace-{,SEED8,SEEDED}`, `eq-cram-{flat,fc,boost}`, `eq-xframe-A/B`, `eq-seedonce-*`, `eq-watch-0x66`, `eq-null-trajectory`. **Biquad exact; `m_dp` operand origin pinned live to host state block `0x64+4k`** |
| **ROOM REVERB 1** (a DIGITAL REVERB) | 16 | DIGITAL REVERB `0x0A` | `reverb_select.lua` (page `0x0A`) + `UPD6383_REVSEED`/`_ONCE` | `kn5000-dsp-reverb-frame-page0A-2026-09-11.txt`, `reverb-decay-F1..F4`, `reverb-seedonce-F0p1..3`, `revseed-frame` (impulse-decay) |

The rig that produces these is `kn7000_mame/tools/rigs/kn5000_dsp_frame_trace.lua`, dumping the
time-ordered per-word trace at `UPD6383_TRACE_FRAME`.

### 2.2 Merely executes (Python harness) — 36 of 38, with an enumerated-blocker caveat

Distinct from the above: the *microcode runs to completion* in the **Python speculative-machine
simulator** (not MAME) of `unblocking-and-discriminators.md` / `single-delay-restored.md`.

- Baseline: only **2–3 of 38** executed natively — the images that deliver input before unblocking:
  SINGLE DELAY (algo 9), PEQ+S.DELAY (algo 72), ROOM REVERB 1 (algo 16).
- Giving each execution blocker an **enumerated (not decoded) behaviour** lifts this to **36 of 38**
  run to completion; mean execution 12.7% → 98.0%.
- **The two that still do NOT complete:**
  - **MULTI TAP DELAY (algo 10)** — a *missing coefficient* at `w52` (the 83rd unaligned
    algorithm), not an opcode. Executes partway then stops.
  - **ROCK ROTARY (algo 15)** — one further *unmodelled action* `ACT 0x1D` at `w42`
    (`w42 = 02122BE41D`). Executes partway then stops. (This is also the image behind ROTARY
    SPEAKER, algo 53.)

> **Caveat (from `execution_summary`):** these readings are **scaffolding, not decodings**. The one
> independently-validated answer is SINGLE DELAY's — lag 1001, gain +0.02149296 to 0.001%
> (`single-delay-restored.md` §5.2), preserved unchanged at every unblocking step — and even that was
> validated in the Python harness (`sd_rerun.py`), **not** captured live in MAME.

### 2.3 LFO known-mathematics validation — simulation, not a live capture

ROM LFO ramp constants reproduced *in the Python simulation* cover ~11–12 further LFO-bearing
programs (e.g. FLANGER 38/frame, PHASER 76/frame, ENSEMBLE 114/frame, VIBRATO 760/frame, AUTO PAN
228/frame, MODULATED CHORUS [114,989]). Some rates are still **not reproduced** (RING MODULATOR
190217; MIX UP third rate 1407; the PEQ+modulation combi LFO rates). This is simulation evidence,
**not** a live MAME capture, and does not move a program into the "triggered + captured" tier.

---

## 3. Not yet triggered + captured (35 of 38 distinct images)

Everything except CHORUS, PARAMETRIC EQ and ROOM REVERB 1. The rigs can *in principle* reach every
unit-0 DSP-EFFECT slot (`type_select` / `type_enum` / `peq_select` / `frame_trace` NAV=1) and the
unit-1 reverb (`reverb_select`), but that capability has **not yet been exercised into committed
captures** for these. Grouped by page/family:

**DSP EFFECT page (`0x0B`) — unit-0, not captured:**
- *modulation* — MODULATED CHORUS (2), FLANGER (4), PHASER (5), ENSEMBLE (6), VIBRATO (50),
  MIX UP (56). [CHORUS already captured.]
- *filter* — ENHANCER (3), AUTO WAH (52).
- *delay* — SINGLE DELAY (9), MULTI TAP DELAY (10 — **still blocked in harness**),
  S. DELAY+S. DELAY (65).
- *distortion* — DISTORTION (32), OVERDRIVE (33), FUZZ (34).
- *exciter* — EXCITER (35).
- *dynamics* — COMPRESSOR (36). (NO OPERATION algo 0 is the base image, never selected as itself.)
- *am* — AUTO PAN (48), RING MODULATOR (54).
- *rotary* — ROCK ROTARY (15 — **still blocked in harness**), ROTARY SPEAKER (53, shares algo 15
  image).
- *reverb (unit-0)* — GATED REVERB (8) — distinct from the unit-1 tank.
- *combi* — S. DELAY+CHORUS (64), S. DELAY+FLANGER (66), S. DELAY+VIBRATO (67),
  S. DELAY+PHASER (68), AUTO WAH+S. DELAY (70), PEQ+CHORUS (71), PEQ+S. DELAY (72),
  PEQ+FLANGER (73), PEQ+VIBRATO (74), PEQ+COMPRESSOR (75), PEQ+COMPR+DIST (96),
  PEQ+COMPR+OVERDR (97), PEQ+DIST+DELAY (98), PEQ+OVERDR+DELAY (99).

**DIGITAL REVERB page (`0x0A`) — unit-1, not captured:**
- ROOM REVERB 2 … WAVE REVERB 2 (algos 17–27). **All share the already-captured ROOM REVERB 1
  image**, so a fresh capture per preset probes *coefficients*, not a new program image. Plus the
  two REV-SEND-less delays (SINGLE DELAY, MULTI TAP DELAY on the reverb page).

**Stubs — low value to capture (running them yields NO-OP):**
- SLOW ATTACKER (37, DSP EFFECT TYPEIDX 14) — the one stub known to be panel-selectable and to
  carry live params; worth ONE confirming capture + the open hardware ask to Felipe.
- MODULATION DELAY (11), NOISE FLANGER (38), CEL (44), CELM (45), PITCH SHIFTER (49),
  PEDAL WAH (51), HARS EFFECT (55), STRING (63), PEDAL WAH+DELAY (69), DS_D (80), OVER_D (81) —
  byte-identical to NO OPERATION; **panel location unknown from the provided nav data** (§1.5).
  Capturing them would reproduce the NO OPERATION frame; **skip except as a null control.**

---

## 4. Plan to run them all and inspect runtime behaviour

Ordered, concrete, and gated on the project's measurement discipline. Two SOLVED programs
(PARAMETRIC EQ, ROOM REVERB 1) and the cold-boot CHORUS are the calibration anchors: any generalised
rig must reproduce their existing captures byte-for-byte before it is trusted on a new slot.

### 4.a Generalise the rig so page + TYPEIDX are parameters

- **Unit-0 DSP EFFECT page:** consolidate on `kn5000_dsp_frame_trace.lua` **NAV=1** with `TYPEIDX`
  as the single knob (0 = CHORUS … 15 = PARAMETRIC EQ … 37 = PEQ+OVERDR+DELAY), driving the §1.1
  sequence. For distant targets prefer the `type_select.lua` strategy (saturate UP to end of list,
  then step DOWN `LAST-TYPEIDX` times) to halve press count and avoid dropped steps that
  `peq_select.lua` shows at long distances. **Every run must fingerprint the uploaded program**
  (verify the loaded image against `programs.tsv`) — do not trust the LCD name buffer at DRAM
  `0x30AE5`; the screenshot / uploaded-image fingerprint is authoritative.
- **Unit-1 reverb page:** use `reverb_select.lua` (page `0x0A`) with `TYPEIDX` selecting the preset.
  Because all 12 presets share the ROOM REVERB 1 image, treat these as **coefficient** captures, not
  new images; diff each preset's C-RAM against the ROOM REVERB 1 flat capture.
- **Out of scope for array capture:** EQUALIZER (`0x0C`, loader `0x4C10`) and ACOUSTIC ILLUSION
  (`0x0E`, loader `0x4E10`) are fixed layouts, not the `0x29AC` array — note them but do not try to
  drive them through the TYPE mechanism. The ACOUSTIC ILLUSION TYPE up/down key is only *inferred*
  to be `CPL_SEG10 0x20/0x10`; if ever needed, calibrate it the way `peq_cursor.lua` calibrates the
  PARAMETER cursor, one candidate per snapshot.
- **Un-located stubs:** first resolve the §1.5 discrepancy — run `type_enum.lua` end-to-end and
  record the *actual* full name list the live UI exposes, to find whether MODULATION DELAY / CEL /
  … appear at all and at which TYPEIDX. Do not assume a TYPE index for them.

### 4.b Per-program capture procedure (each non-stub image)

For each target on the DSP EFFECT / REVERB page, in TYPEIDX order:
1. Select it via the generalised rig (§4.a); **fingerprint the uploaded program** against
   `programs.tsv` before trusting the run.
2. Play the **RULE-12 `:KEY2` melody C4/E4/G4** so the chip processes real signal (a DSP test with
   no notes playing is not a test).
3. Capture a **live frame trace** at `UPD6383_TRACE_FRAME`, with the `-log` recipe used for the
   CHORUS/EQ captures; enable **`TRACE_DETAIL`** for per-word state where the datapath is the
   question.
4. Run the existing **per-family probes** (below) and the impulse tools for reverbs/delays
   (`UPD6383_REVSEED` / `_ONCE` as in `reverb_select.lua`).
5. Commit the capture under `dsp/analysis/data/` **in the same session** it is produced (global
   reproducibility rule), named by algo + date, alongside the exact rig invocation.

Suggested order: start with the two harness-blocked images (**MULTI TAP DELAY algo 10, ROCK ROTARY
algo 15**) — a live trace of the real chip past `w52`/`w42` would supply the missing coefficient and
resolve `ACT 0x1D` directly, converting "enumerated blocker" into a decode. Then the robust
discriminators (PEQ+COMPR+DIST algo 96; COMPRESSOR algo 36) whose harness signatures can be
cross-checked against a live frame. Then the remaining families.

### 4.c What runtime insight each family yields

- **modulation** (chorus/flanger/phaser/ensemble/vibrato/mix-up): the live frame exposes the **LFO
  cells** — per-frame ramp increment and phase. This directly checks the ROM-ramp constants that so
  far are only *simulated* (§2.3), and would settle the not-yet-reproduced rates (RING MODULATOR
  190217, MIX UP 1407, the PEQ+mod combi rates).
- **delay** (single/multi-tap/S.DELAY+*): the frame exposes the **external delay-DRAM tap
  addresses** and write pattern — SINGLE DELAY's known answer (lag 1001, gain +0.02149296) is the
  calibration; MULTI TAP DELAY's tap set is the missing-coefficient question at `w52`.
- **distortion** (distortion/overdrive/fuzz): the frame exposes the **waveshaper** LUT/curve and the
  post-tone biquad (OVERDRIVE's 4 kHz Butterworth) — a static, note-driven capture is enough.
- **combi** (14 images): expose **multi-unit scheduling** — how PEQ / compressor / delay / modulation
  sub-blocks are ordered within one 285-word frame; validates the biquad-then-effect chaining.
- **reverb** (unit-1 tank + unit-0 gated): the impulse tools give the **decay envelope / all-pass
  ladder** live; per-preset captures isolate coefficient-only differences across algos 16–27.
- **eq / dynamics / am / exciter / rotary**: the biquad (eq) and level-detector (dynamics) datapaths
  are the anchors already SOLVED/high; captures confirm operand routing on the real core.

### 4.d Stubs — skip or bound deliberately

- Take **one** SLOW ATTACKER (algo 37, TYPEIDX 14) capture to confirm it loads the NO OPERATION
  image with its live params, and **carry the open hardware-test ask to Felipe** (predicted
  indistinguishable from no effect).
- Take at most **one** NO OPERATION reference frame (via a stub or the base image) as the **null
  control** every other capture is diffed against.
- Do **not** spend captures on the other 11 stubs beyond locating them in the UI (§4.a): each would
  reproduce the NO OPERATION frame. Record explicitly that they were skipped and why.

### 4.e How this feeds the open decode questions

- **Input route / `m_dp` operand origin:** PARAMETRIC EQ pinned it live to host state block
  `0x64+4k`. Live frames of other families test whether that route generalises or is program-specific
  — the standing v140 nav blocker (`m_dp` needs parametric EQ) is downstream of this.
- **Biquad realization:** the 20+ biquad-carrying combi/PEQ images (algos 71–99) let a live capture
  confirm the Direct-Form-I bilinear biquad decoded in PARAMETRIC EQ is reused verbatim, and expose
  the OVERDRIVE tone biquad and the 4-section stack in PEQ+OVERDR+DELAY (algo 99).
- **Enumerated → decoded:** live traces of MULTI TAP DELAY and ROCK ROTARY are the direct route to
  replace the two enumerated blockers with real decodings.

### Discipline notes (non-negotiable)

- **`timeout`-wrap every scripted MAME launch**; keep ~2–3 emulators in parallel; `build.sh` exits 0
  even on compile failure — grep the log for `error:` and check the binary mtime/size > 70 MB.
- **Always visible video** (Felipe watches): display `:0` / `wayland-0`; never `-video none`.
  Use `-skip_gameinfo` on our build.sh binaries.
- **Honest grading:** compute the NULL (a no-stimulus window; a difference from silence is not a
  signal) and a CALIBRATION before interpreting any table; a criterion that cannot fail is not a
  pass. Fingerprint the uploaded program every run — the LCD name buffer is unreliable.
- **No fabricated results:** a program is "triggered + captured" only when a committed live MAME
  frame trace exists for it. "Executes" (Python harness) and "LFO reproduced in simulation" are
  reported as such and never conflated with a live capture.
- **Reproducibility:** commit each capture and the exact rig invocation that produced it in the same
  session, under `dsp/analysis/data/`, next to what it measures.
