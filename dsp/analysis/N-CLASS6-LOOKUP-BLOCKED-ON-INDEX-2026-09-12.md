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

## 5. ★★ AND THE GATES UNBLOCK IT — the index now ARRIVES (MEASURED, same day)
§4 said the modulation family is blocked on getting the phase to the class-6 word, not on the
table. The capture it was read from predates this session's gate work, so the obvious question is
whether the three arms change it. Re-running the CHORUS (`TYPEIDX 0`, trace frames 1 631 700 /
1 631 701) with `UPD6383_LO12CAP=1`, `UPD6383_C8SHIFT=1` and
`UPD6383_SPEC=B9108446A39B440F` (`ACT 0x0E = mem[ptr] ← bus`) — no rebuild, environment only —
and reading **the device's own §162 census**, whose verdict string is not mine to write:

| | shipped readings | **all three gates open** |
|---|---|---|
| site `00006184CD` (`addr8=18`) | `acc 0 .. 0` **(CONSTANT -- phase is NOT here)** | `acc 0 .. 977 106` **(VARIES)** |
| site `0000620407` (`addr8=20`) | `acc 0 .. 0` **(CONSTANT -- phase is NOT here)** | `acc 0 .. 1 954 212` **(VARIES)** |

**The census flips its own verdict.** The accumulator at both class-6 sites now varies, so **the
index reaches the word**. The chorus body is live with it (24 of 70 rows differing between
consecutive frames). The two maxima are in exact 2:1 ratio (977 106 / 1 954 212), which is the
relationship two quadrature lookups of one phase would have — noted, not claimed.

⇒ **§4's "implementing the lookup today would be pointless" no longer holds.** With the gates open
the table is present *and* the index arrives, so the class-6 lookup becomes implementable and is
now the single missing step between the modulation family and a sweeping tap. That is the first
time in this project that item has been actionable.

⚠ What is NOT shown: that the index is *correct* (its scale and origin are `lfo-ramp.md §10`'s
`(coef × phase) >> 23` reading, unverified here), or that a lookup would make the tap sweep at the
right rate and depth. Those are the next measurements, and the HLE gives both targets — the chorus's
0.6 Hz rate and its ±240-sample sweep are already decoded and A/B-validated.

## 6. The lookup was IMPLEMENTED and RUN — it fires, and the criterion FAILS (MEASURED)
`UPD6383_C6LUT` (default off) performs the lookup: index = the accumulator as a datum modulo the
word's own `addr8` (0x18 = 24), table = `m_rf[0x1D + index]` (§160's window), result into `P` at
the multiply's scale. Chorus, same rig, arm off vs on in one command:

```
off  §157 TAPMOD PER SLOT: iw96:0..240(r240) iw105:0..240(r240) iw137:-1984..0(r1984)    iw146:-240..0(r240)
on   §157 TAPMOD PER SLOT: iw96:0..240(r240) iw105:0..240(r240) iw137:-4194544..0(r4194544) iw146:-240..0(r240)
      (FIRED 3 150 504 = twice per frame, the two class-6 sites)
```

**The pre-registered criterion is NOT met.** It required the census to stop reporting a constant
240 and start spanning a range at the LFO rate. The two sweep slots `iw96`/`iw105` are **still
`0..240`** — the depth is as constant as before — and the only slot that moved, `iw137`, did not
acquire a sweep: its excursion blew up to **4 194 544 ≈ 2²²**, i.e. roughly the raw table value
(the sine peaks near `0.95·2²³`) rather than a ±240 modulation.

⇒ the lookup's value **reaches the tap-modulation path but at the wrong place and the wrong
scale**. Read plainly: firing the lookup is necessary and is now demonstrated, but *this* index and
*this* destination are not the chip's. The candidates the failure points at, in order: the result
may belong somewhere other than `P` (the idiom's third word `012.4.01.1CE` is the untested half);
the index may need the `(coef × phase) >> 23` form rather than the accumulator-as-datum shortcut I
took; and the depth multiply that should scale the waveform to ±240 is evidently not downstream of
where the value lands.

⚠ Grade: MEASURED negative with a fired count and a like-for-like control in the same command. The
arm stays default-off. ★ This does not weaken §5 — the index *does* arrive, which is what §5
claimed — it shows that arrival is not sufficient and names what else the idiom needs.

## 7. The DESTINATION candidate was tested too — identical failure, so it is the SCALING
§6 named three candidates. The first was the destination, and it was the bytecode's own suggestion:
the chorus's sweep word `192.A.40.000` carries `SRC 0x00 = mem[ptr]`, so for its product to be
`depth × waveform = ±240` the waveform must be in a D-RAM cell it reads rather than in `P`.
`UPD6383_C6LUT=2` stores the looked-up value under the class-6 word's own pointer instead.

```
=1 (value -> P)        §157: iw96:0..240  iw105:0..240  iw137:-4194544..0  iw146:-240..0
=2 (value -> mem[ptr]) §157: iw96:0..240  iw105:0..240  iw137:-4194544..0  iw146:-240..0
```

**Identical.** The destination was not the defect either. Both arms inject a **full-scale** table
value into the chain and neither produces a ±240 sweep ⇒ **what is missing is the SCALING step
between the table and the tap, not the route.** That is a sharper statement of the gap than §6's
three-way list, and it is reached by eliminating one of the three rather than by assuming.

Remaining, in the order I would test them: the index FORM (`(coef × phase) >> 23` as
`lfo-ramp.md §10` reads it, rather than the accumulator-as-datum shortcut both arms used), and
where the DEPTH multiply sits relative to the lookup — the chorus's depth cell is C-RAM `0x02`
= 240 and its product with a unit-scale waveform is exactly the ±240 the census should show.

## 8. §148's coefficient substitution is what blocks the sweep — and turning it off BREAKS the LFO
§7 narrowed the gap to "the scaling between table and tap". Looking for where the scaling could be
lost led to an existing speculative reading rather than to my arm. The chorus's sweep word is
`192.A.40.000`, class A with `f98 = 1` — exactly the population **§148** captures, where the device
substitutes **`C-RAM[cursor]` for `SRC 0x00`** instead of `mem[ptr]`. That is why its operand has
measured **240** (the depth coefficient) all session and why it computed `240 × 240`: with the
coefficient occupying the operand slot, no waveform can reach it, whatever the lookup writes.

§148 is speculative (mask bit 59, set by default), so clearing it needs no rebuild. Same rig, two
masks differing only in that bit, with `C6LUT=2` in both:

```
§148 ON   §157: iw96:0..240(r240)      iw105:0..240(r240)      iw137:-686371..111743   iw146:-240..0
§148 OFF  §157: iw96:0..8388607        iw105:0..8388607        iw137:-509702..+509707  iw146:-1201385..+1201383
```

**The pre-registered criterion is met for the first time**: the two sweep slots stop reporting a
constant 240 and span a range, and `iw137`/`iw146` become **symmetric about zero** — the signature
of a bipolar modulation, where before they were one-sided. The class-6 rows also show real table
entries on the bus (`mem` = `D4F570`, `5E2382`, `71BA50`, `780304` — all wavetable values).

⚠⚠ **AND IT BREAKS SOMETHING THAT WAS MEASURED CORRECT.** The chorus's LFO phase cell advanced by
**exactly 114 per frame** under the shipped readings — the HLE's increment for its 0.6 Hz rate,
the three-way triangle of `N-DLYSEED2-CHORUS-CONFRONT §1`. Under these arms the delta across the
wrap pair is **≈ 3.13 M**, in BOTH masks. So the phase accumulator no longer runs at the rate the
bytecode, the HLE and the panel all agree on, and the excursions above are therefore not a correct
sweep either — they are a live datapath with a broken index.

⇒ **This configuration is not a net improvement.** It trades a quantity that was confirmed correct
against the HLE for liveness elsewhere, and a reading that does that is not yet the chip's. The
honest next question is not "which candidate scales the waveform" but **"why does the phase
accumulation break once the gates are open"** — because the phase was the single thing in the
modulation family that matched the HLE exactly, and it is the anchor any correct configuration
has to keep.

⚠ Grade: MEASURED both ways, like-for-like, environment-only (no rebuild). The criterion's success
and the regression are equally measured, and the regression is the more important of the two.

## 9. ★★ IN THE CONSISTENT CONFIGURATION THE TAP GOES BIPOLAR — and §148 stops being load-bearing
§19 of `N-INPUT-GATE-OPENED` produced a configuration where the body is live **and** the LFO phase
advances by exactly 114. Re-running the class-6 tests inside it changes the picture twice over.

**(a) With §148 ON (the shipped coefficient substitution):**
```
C6LUT=0/1/2  §157: iw96:0..240  iw105:0..240   ... and phase = 114 in all three
```
The lookup no longer damages the phase — but the sweep slots stay constant, because §148 makes the
sweep word read the **coefficient** (240) as its operand: `240 × 240`, constant by construction.
No lookup can change that; it is the operand route, not the table.

**(b) With §148 OFF, in the same consistent configuration:**
```
C6LUT=0  §157: iw96:0..8388607  iw105:0..8388607  iw137:-4..10            iw146:0..0        phase = 114
C6LUT=2  §157: iw96:0..8388607  iw105:0..8388607  iw137:-509702..+509707  iw146:-1201385..+1201383   phase = 114
```
Three things at once, none of which has held before: **the phase stays exactly 114**, the sweep
slots **stop being constant**, and with the lookup on two slots become **symmetric about zero** —
the signature of a bipolar sine modulation, where without it they are one-sided or dead.

**★ And the part that matters most for the decode:** §148 was adopted because it made the LFO
twins come out right. In this configuration **the phase is 114 with §148 ON *and* OFF** — so §148
is **no longer load-bearing for the thing it was introduced to fix**, while it *is* what prevents
the tap from ever sweeping. That is the same shape as the "store the whole accumulator" artefact
(`N-INPUT-GATE-OPENED §17`): a reading whose supporting evidence was collected in the starved
state, and which the live state no longer needs. ⇒ **§148's coefficient substitution is now a
candidate for removal**, on evidence, rather than a fixture.

⚠ What is still missing is only the **depth scale**: the excursions are full-scale
(`0..8 388 607`) where the chorus's decoded depth is ±240 samples, so the multiply that should
scale the waveform by C-RAM `0x02` = 240 is still not in the path. That is one step, and it is the
last one between this and a chorus whose tap sweeps at the HLE's rate and depth.

⚠ Grade: MEASURED, four runs, phase and census reported together each time. The §148 conclusion is
STRONG (its justification is measurably no longer needed, and its cost is measured) but it is a
statement about the DEVICE's readings, not yet a decode of the chip.

## Honest grade
§1 is READ from the device. §2 and §3 are MEASURED, from the device's own censuses in an archived
capture (`dsp/analysis/data/dlyseed2_chorus_2026-09-12.log.gz`). §4 is the deduction they force.
⚠ This note DECODES NOTHING — its value is that it removes a plausible-looking piece of work
("model the class-6 table") from the queue and replaces it with the real one ("find how the phase
reaches the class-6 word"), before anyone spends a build on the wrong half.
