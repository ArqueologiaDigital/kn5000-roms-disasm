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

## The honest wrinkle (grade this before drawing per-word conclusions)
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
