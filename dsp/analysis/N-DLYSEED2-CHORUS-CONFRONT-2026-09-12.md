# DLYSEED2: the CHORUS datapath confronted with the HLE oracle (2026-09-12)

Second seeded confrontation, first of the MODULATION family (prog01 CHORUS, unit 0, I-RAM
84..153, 70 words). Same instrument as `N-DLYSEED2-SINGLE-DELAY-CONFRONT-2026-09-12.md`:
`UPD6383_DLYSEED2` seeds the external delay DRAM at the chip's own tap address (16-bit 0x4000 →
0x400000 = 0.5 FS on the bus), the frame trace is read with `dsp/tools/dlyseed_confront.py`, and
the HLE chorus (`kn5000_tonegen.cpp` HLE CHORUS INSERT: `phase += inc; dA = base + depth·(½+½ sin);
dB = base + depth·(½+½ cos); wet = ½(read(dA)+read(dB)); mix = (1−w)·dry + w·wet`) plus
`lle_oracle.py: LFOOracle` are the oracle.

## Recipe (reproducible)
```
DISPLAY=:0 DHLE=0 DSPCFG=3 TYPEIDX=0 NOTEMODE=0 TGM=0 UPD6383_DLYSEED2=1 \
  UPD6383_TRACE_FRAME=1631700 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
  -autoboot_script dsp/tools/fx_ab.lua
python3 dsp/tools/dlyseed_confront.py error.log --lo 84 --hi 153 --dump
```
TYPEIDX 0 = CHORUS. ⚠ `fx_ab.lua` plays the note at t = 36.0 s and exits ~4 s later, so the trace
frame must sit inside that window: 1 631 700 = 37.0 s. (The delay recipe's 1 820 000 = 41.3 s is
AFTER the exit here — "blocks=0", nothing captured; this cost one run.)

## 1. LFO — the LLE's phase word carries exactly the HLE's increment (MEASURED, consistent)
Phase cell 0x07: `0x2ABB66` at w5 (`092.A.00.200`, phase+=) → `0x2ABBD8` at w7 (`094.A.00.200`,
wrap) = **+114 per frame**, with the increment itself on the bus at w5 (`L = 114 = C-RAM[0x00] =
0x72`) and the wrap constant `0x7FFFFF` on the bus at w7. HLE: `LFOOracle(0.6 Hz).inc =
round(0.6/44100·2²³) = 114`, and the HLE chorus derives its rate from the same cell
(`f = C-RAM[0x00]·44100/2²³ = 0.599 Hz`; A/B-measured 0.62 Hz, moves with the panel's LFO SPEED).
So bytecode constant ↔ HLE rate ↔ LLE phase delta close a three-way triangle. This is under the
device's §225 `LFOWRAP=1` (mod 2²³) reading; the rival clamp reading would pin the phase at
0x7FFFFF within 1.7 s and produce no chorus at all — the HLE's audible, panel-driven sweep is the
behavioural argument for wrap (already lfo-ramp.md §11). Not a new decode: a closed consistency
check, the first on the modulation family.

## 2. The arithmetic primitives hold; the "unexplained" rows are ONE device form (MEASURED)
* Multiplier `P[N] = coef[N−1] × L[N] >> 6`: **5/5** non-zero products exact (w10: 240 × 240 >> 6 =
  900; w5: 114 × 114 >> 6 = 203).
* Accumulator: 43 accumulate + 10 load (`acc == P[N−1]`) + **6 "bus-add"** + 10 boundary words +
  **0 unexplained**. The tool's first pass reported 5 UNEXPLAINED multiply rows; all of them (plus
  w6) are one form, `acc[N] = acc[N−1] + P[N−1] + (L[N] << 16)`, with the operand taken from the
  COEFFICIENT bus: w5 (092.A, SRC 0x08, L = 114), w10/w19 (`192.A.4x.000`, SRC 0x00, L = +240 =
  C-RAM[0x02]/[0x04]), w51/w60 (L = −240 = C-RAM[0x0D]/[0x0F]), and w6 (`082.2.00.1C0`, L =
  mem[N−1] = the phase). This is the device's SPECULATIVE §146/§148 "`coef` operand on f98=1
  coefficient-consuming SRC-0x00/0x08 words" + the ACT 0x00 bus-add — **measured as the device's
  behaviour, not the chip's.** `dlyseed_confront.py` now names it ("bus-add") instead of
  "unexplained", and names `P[N] = L[N] << 16` ("P←bus", the newest ACT 0x0E reading) which fires
  once here, on the LUT motif's w36 (`012.4.01.1CE`, P = mem[0x0E] << 16 = 39718 << 16).

## 3. Word-level confirmation of the HLE's cell→role map (MEASURED)
The trace shows which C-RAM cell each word puts on the bus or into the multiplier: **0x00 = 114**
at the phase word (HLE rate); **0x02/0x04 = +240** at the two L-voice sweep words and **0x0D/0x0F
= −240** at the two R-voice sweep words (HLE `sweep = C-RAM[0x02] = 240 samples = 5.4 ms`);
**0x09/0x0A = 0x1364D9** (0.303 at Q22 = the HLE wet gain) consumed at w39/w42 after the LUT
motif; 0x06/0x07 = 0x2CCCCC at w25/w26; **0x08 = 0x18 = 24** at w28 (the §167 LUT-index scale
`(coef × phase) >> 23` with coef = 24); and **0x03/0x05/0x0E/0x10 = 0** at the four "gain
multiply" words that immediately follow each DRAM READ (w15/w24/w56/w65). With a zero coefficient
those four are inert in THIS program — consistent with a feedback tap the CHORUS sets to zero
(INFERRED; the flanger = chorus + feedback is the program to test it on).
★ **HLE refinement candidate (bytecode-backed):** the R-channel sweep coefficients are **−240**,
the L-channel's **+240** — the two channels sweep in ANTIPHASE, which the HLE (same `dA/dB` for
both channels) does not do. Whether −240 means "tap moves the other way" depends on the address
model's sign, so this is a candidate for an A/B (stereo cross-correlation of the wet), not a
change made here.

## 4. The seeded tap datum DIES on the READ word (MEASURED) — the HLE says where it must go
`dlyseed_confront.py` Q1/Q1c: the impulse is on the bus at all four READ words (w14/w23/w55/w64 =
`880.1.20.2C7`, SRC 0x0B: the READ word itself publishes the per-line latch, §74/§78), and on the
very next row it is **DEAD** — not on L (the next word reloads `L = mem[ptr] = 0`), not under the
pointer (`mem[0x50..0x53] = 0` throughout), not in the accumulator (`acc = P[N−1] = 900`: the
f31=0 LOAD takes the stale product 240×240>>6, exactly the "delay words WIPE the accumulator"
diagnosis of §82), and not in tempA (`tA = 000000`). **Contrast the single delay**, where the
oracle confrontation was positive: its datum-carrying word `880.1.60.2D9` has **ACT 0x19 =
CAP_TA2** — the trace shows `tA` become 0x400000 on that word and the next word (`0202AB8655`,
**SRC 0x19**) read it back onto L and multiply (P = 0x400000 × 0x400000 >> 6, exact). So in prog09
the datum travels **bus → tempA → next word**, and prog01's READ word has no such capture: ACT
**0x07**, which the disassembler itself names `LO_ACT_ST_BUS = mem[ptr] ← bus`, and whose mode-1
target on this class-1 word (`addr8 = 0x20`) §161 correctly BLOCKED because addr8 is the delay
DIRECTION field — leaving the datum with nowhere to go.

**What the HLE requires:** the tap datum must reach the wet words (and, in the flanger, the
feedback tap): `wet = read(dA)`. In prog01 the only words that can carry it forward from w14 are
the four state cells the READs sit on (**dp = 0x50..0x53**, otherwise never written non-zero in
the frame) or a capture register. ⇒ **STRONG inference (HLE + the delay's measured route):** on
the delay READ escape word, `ACT 0x07` stores the BUS under the **POINTER** — `mem[dp] ← datum`,
the mode-2 target the 0x07 rule already uses on C-format words — so that the following word's
`L = mem[N−1]` is the tap. §161 refuted the addr8 target, not the code; this is the remaining
candidate and it is the one the HLE's signal flow needs. **Falsifiable device arm** (env-gated,
default off, like DLYSEED2): `mem[0x50..0x53]` must read 0x400000 on the rows after each READ and
w15/w24/w56/w65 must show `L = 0x400000`. Their products stay 0 in the CHORUS (zero coefficient,
§3), so the discriminating program is the **FLANGER** (feedback ≠ 0 → non-zero P on those words)
— that is the next run. §82's REFUTED mask bit 21 ("bus into acc on every delay word") is a
different, broader claim (it was refuted by the reverb drain at kernel iw47, not by this route).

## 5. The tap does NOT sweep in the LLE (MEASURED) and the §200 census is not a depth instrument
The device's own §157 census for this run: `TAPMOD PER SLOT iw96: 0..240, iw105: 0..240, iw137:
−240..0, iw146: −240..0` — the modulation term at the four `44C` words spans the depth, but the
frame trace shows WHY: at w12 `acc = 15729946 = 240<<16 + 406`, i.e. **the constant depth**, the
LFO waveform never entering (the sweep words square the depth, §2). The 0 end of each range is the
pre-load state. So the LLE chorus reads a STATIC tap at +240/−240 — **no sweep** — while the HLE
needs `depth × waveform(phase)`. In the bytecode that product can only be the sweep word's
multiply with the LUT motif's output (w30..w37; cell 0x0E = 39718 in this frame) as its OPERAND —
the §148 `coef` operand (which makes w10 compute 240×240) is what starves it. Grade: **STRONG**
inference on the operand's IDENTITY (the waveform), OPEN on its route (w10 runs before the motif
in program order, so it must be the previous frame's value via a D-RAM cell; the device's pointer
at w10 is 0x50, which reads 0).

★ **Census cross-check → retraction in the delay note.** The §200 DELAY AGE census in this log
reports the chorus's descriptors 0x27/0x28 as `0..4401` / `0..1440` frames — far wider than a
±240-sample sweep — because the census is CUMULATIVE SINCE BOOT (3.15 M hits ≈ the whole 71 s run,
the boot default's reads on the same descriptor indices pooled in). The same pooling, plus the
STALE speculative `m_tapmod` offset (mask bit 60; prog09 has no `44C` word), is why the single
delay's dsc 0x26 max reads 27748 in four runs and 17711 in one with IDENTICAL hit counts. The delay
note's §5 "line depth matches the descriptor" is therefore RETRACTED there; the tool now prints the
census with that warning.

## Honest grade
§1 MEASURED (consistency, no new decode). §2 MEASURED (the primitives generalize to a third
program; the bus-add form is the device's, named not proven). §3 MEASURED at word level (the HLE's
cell→role map is what the chip puts on its bus), with one INFERRED role (zero feedback tap) and one
bytecode-backed HLE refinement candidate (antiphase R sweep). §4 MEASURED death of the datum +
a STRONG, falsifiable HLE→LLE inference with a named device arm and the program (FLANGER) that
discriminates it. §5 MEASURED static tap + a STRONG inference on the sweep operand + a retraction
propagated to the delay note. No decode was changed; DLYSEED2 remains observation-only.

## 6. Net result toward full LLE
The modulation family's arithmetic core is the same chip: multiplier and one-slot accumulator
bit-exact (third program), LFO phase increment exact against the HLE. The HLE now localizes the
LLE chorus's two failures to two specific words — the READ word's **ACT 0x07 target** (wet path)
and the sweep word's **SRC 0x00 operand** (the LUT output, not the coefficient) — both concrete,
env-gateable arms with stated predictions, the first testable next on the FLANGER.
