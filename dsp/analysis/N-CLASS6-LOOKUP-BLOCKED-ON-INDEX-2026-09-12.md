# The class-6 waveform lookup: the TABLE is present, the INDEX is not (2026-09-12)

The modulation family's tap is static in the LLE — the chorus and flanger sweep nothing — and the
usual shorthand for why is "the class-6 table is not modelled". Read properly, that is only half
true, and the half that is false is the half that matters.

## 1. The device's class-6 handler performs NO lookup (READ)
`upd6383.cpp`'s `if (cl == 6)` block collects per-site census statistics (`m_c6_*`: which word,
what the accumulator/tempA/tempB/K held, the product's range) and then `return`s. There is **no
table read, no product, no accumulator effect**. So the shorthand is right that nothing is looked
up.

## 2. But the TABLE ITSELF is present, complete and verified (MEASURED, live)
From the same chorus capture the device prints:

```
§160 REGISTER FILE, LFO WAVETABLE WINDOW 0x1D..0x40 (36 of 36 non-zero):
  0C23C6 2B0A8F 470273 5E2382 6EDA3A 780304 78FE14 71BA50 62B674 4CF874 31FBA1 1396CD
  F3DC39 D4F570 B8FD8C A1DC7D 9125C5 87FCFB 8701EB 8E45AF 9D498B B3078B CE045E EC6932
  0C23C6 2B0A8F 470273 5E2382 6EDA3A 780304 78FE14 71BA50 62B674 4CF874 31FBA1 1396CD
```
That is a **24-entry sine** (the last 12 repeat the first 12), the one `§188` matched to
`0.95·2²³·sin(2πk/24 + 0.1)` **to 1 LSB**. It is uploaded by the host from dumped ROM and it is
sitting in the register file at run time, complete. **Nothing about this table is missing or
undumped** — which is the same conclusion the distortion investigation reached about its
waveshaper table, from the other direction.

## 3. What is actually missing is the INDEX — and the project measured that too
The device's own `§162` per-site census, in the same run:

```
§162 CLASS-6 SITE 00006184CD addr8=18 lo12=4CD : hits 1575252 | acc 0 .. 0
     (CONSTANT -- phase is NOT here) | m_dp 12..12 | cursor 9..9
§162 CLASS-6 SITE 0000620407 addr8=20 lo12=407 : hits 1575252 | acc 0 .. 0
     (CONSTANT -- phase is NOT here) | m_dp 12..12 | cursor 9..9
```

At both class-6 sites the accumulator is **constant zero across 1.58 M frames**, the pointer is
constant and the cursor is constant. The index a lookup would use is not in any of them.
`lfo-ramp.md §10` reads the idiom's arithmetic as `(coef × phase) >> 23` with `coef = 24` — which
`§160` corroborates (`addr8 = 0x18` = 24 = the entry count) — so the *form* of the index is known;
what is absent is the **phase** arriving at the word.

## 4. ⇒ The honest statement of the gap
**Implementing the class-6 lookup today would be pointless**: with the index constant at 0 every
lookup returns entry 0, a constant, and the tap would stay exactly as static as it is now. The
modulation family is blocked on **getting the phase to the class-6 word**, not on the table.

That is a routing question of the same family as the three stage-gates this session worked on
(`N-INPUT-GATE-OPENED`), and the LFO phase itself is known to be live and correct — the chorus's
phase cell advances by exactly the HLE's increment, 114 per frame, MEASURED
(`N-DLYSEED2-CHORUS-CONFRONT §1`). So the phase exists, the table exists, and the wire between
them is what is missing.

## Honest grade
§1 is READ from the device. §2 and §3 are MEASURED, from the device's own censuses in an archived
capture (`dsp/analysis/data/dlyseed2_chorus_2026-09-12.log.gz`). §4 is the deduction they force.
⚠ This note DECODES NOTHING — its value is that it removes a plausible-looking piece of work
("model the class-6 table") from the queue and replaces it with the real one ("find how the phase
reaches the class-6 word"), before anyone spends a build on the wrong half.
