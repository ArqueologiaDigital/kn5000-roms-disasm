# MASTER-PLAN T1/T2 execution — per-program runtime regression + gated-word chase (2026-09-11)

Executes the master plan's achievable thread (T1 per-program regression, T2 chase input-gated
class-A words) on the live per-word traces (peq_gain TYPEIDX=N + TRACE_DETAIL, isolated iw≥84 unit-0).

## T1 — count-level regression (VALIDATED, from DSP-RUNTIME-COMPARE)
Isolated unit-0 program word count == static disasm image word count EXACTLY for all captured
programs (SINGLE DELAY 48, COMPRESSOR 40, OVERDRIVE 63, FLANGER 65); frame = kernel(82) + image +
reverb(133), exact. The disassembly's program sizes are cross-validated against live execution.

## T2 — chasing the class-A gap (live class-A count < static image class-A)
Per-program, comparing live-firing class-A words (trace `mul=Y`, image-relative iw−84) to the static
`mac`-mnemonic words in `prog*.dsm`:

| program | static 'mac' words | live-firing class-A | non-firing static 'mac' (w-index) | non-'mac' live class-A |
|---|---:|---:|---|---|
| FLANGER (prog04) | 10 | 16 | 12, 20, 35, 49, 58 | 8,16,19,24,31,34,39,46,50,54 |
| COMPRESSOR (prog36) | 3 | 8 | 9, 21, 30 | 3,6,10,11,24,27,31,32 |
| OVERDRIVE (prog33) | 15 | 18 | 21, 32, 52 | 7,10,25,38,41,56 |

The non-firing static `mac` words cluster on specific variants:
- **`mac.b (p),(p)+0`** — FLANGER w20/w35, COMPRESSOR w21 (byte/broadcast MAC with +0 increment);
- **`mac.st tb,(p)-1`** — OVERDRIVE w21 and w52 (identical words) — a MAC-and-store of tempB;
- **`mac.st acc,(p)+4`** — FLANGER w49; **`mac ta,(p)+1`** — FLANGER w12; `mac.b (p),(p)+N` — COMPRESSOR w9/w30, OVERDRIVE w32.

## T2 RESOLVED (2026-09-11, later) — the wrinkle was my WRONG criterion; clean result below
The wrinkle was my own: I used the `mac` MNEMONIC as the class-A predicate. It is not — the
disassembler's "class-A" = **class4==0xA** (raw word `(w>>20)&0xF`), which matches the prog headers
EXACTLY (FLANGER 18, OVERDRIVE 18, etc.); class4==0xA words render as `mac`(5)/`?word`(8)/`ld`(5), so
the mnemonic is a subset. The image load is confirmed **contiguous at I-RAM 84** (upload log:
kernel[0..82], program[84..], reverb[200..332]), so iw−84 = w-index is exact. Redoing T2 with
class4==0xA gives a CLEAN per-word non-firing set:

| program | static class4==0xA | live-firing | non-firing (w-index) | the non-firing word(s) |
|---|---:|---:|---|---|
| OVERDRIVE | 18 | 18 | **0** | — (all fire) |
| SINGLE DELAY | 18 | 18 | **0** | — (all fire) |
| FLANGER | 18 | 16 | **2** | w21 = w36 = `0094A00200` (SRC 0x08, ACT 0x00, f31=4) |
| COMPRESSOR | 10 | 8 | **2** | w4 = w25 = `0104A001D5` (SRC 0x07, ACT 0x15, bit4 store) |

**Finding (the T2 lead, now decoded to specific opcodes):** the class-A words that DON'T fire live are
specific, and repeat identically within a program:
- **FLANGER's** two are the **SRC 0x08 coefficient-squaring MAC** (§224 §S2sq: SRC 0x08 puts C-RAM[c]
  on the bus and the multiply reads C-RAM[c] again) with the **anomalous f31=4** accumulator code —
  a class-A word whose multiply is gated/skipped live.
- **COMPRESSOR's** two are a **SRC 0x07 (mem[ptr]) store MAC with ACT 0x15** — also gated live.
- OVERDRIVE and SINGLE DELAY have NO gated class-A (all 18 fire) — so the gating is program-specific,
  concentrated in the modulation (FLANGER) and dynamics (COMPRESSOR) families, exactly where the
  static decode flagged conditional behaviour.
This is a real per-word runtime decode: the input/state-conditional class-A ops are now named
(SRC 0x08 coef-square + f31=4; SRC 0x07/ACT 0x15 store), not just counted.

## (superseded) The earlier wrinkle write-up
The live class-A set and the static `mac` set **do not align 1:1** under the naive `w-index = iw−84`
mapping — each program has live class-A words that are NOT static `mac` words (right column) and vice
versa. So the "non-firing" list above is PROVISIONAL: it may reflect a real input/state gate OR a
mapping/classification mismatch, namely one of:
1. the image does not load at exactly I-RAM 84 with contiguous w-index (the load offset/order needs
   confirming — the COUNT matches, but the per-slot mapping may be permuted);
2. the disassembler's `mac` mnemonic and the runtime class4==0xA are not the same predicate
   (e.g., `mac.b` may carry a different class4, or a `mac.st` counts differently at runtime).

## Next step for T2 (resolve the wrinkle, then the gate)
Confirm the image load mapping: dump the I-RAM upload addresses live (the loader's target slots) and
compare to the w-index order, so iw↔w-index is exact; and reconcile the `mac`/`mac.b`/`mac.st`
mnemonics with the runtime class4 value. Only then is "word W does not fire live" a decoded gate
rather than a mapping artefact. The candidate gated variants (`mac.b …+0`, `mac.st tb`) are the ones
to watch once the mapping is pinned — they are the input/state-conditional ops the static analysis
marks lower-confidence.

## Status vs the master plan
T1 (count regression) = validated. T2 = executed to a concrete lead (the `mac.b`/`mac.st` non-firing
candidates) plus a mapping wrinkle that must be resolved before the per-word gate is decoded — a real,
honest advance, not a determination. T3 (family LFO/waveshaper probes) is the next achievable step,
and benefits from the same iw↔w-index mapping fix.
