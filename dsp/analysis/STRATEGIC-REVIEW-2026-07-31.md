# Independent strategic review — 2026-07-31

Twelve read-only agents in four stages (Measure / Assess / Challenge / Synthesize), with two
deliberately opposed lenses (stagnation vs plateau), each refuted by a separate agent.
All figures re-derived read-only against kn5000-roms-disasm@9b9fc7f and kn7000_mame@0d37100.
A 14-page PDF rendering is at ~/compartilhado/KN7000/KN5000-DSP-strategic-review-2026-07-31.pdf

---

39382 /tmp/claude-1000/-home-fsanches-compartilhado-KN7000/47fc5a6c-5951-4f11-8154-1286021c58c7/tasks/w8j2w9h32.output
Out of reach only by the *current vehicle*, not in principle:** `f31 = 4/5` — three routes are measured-closed, but `f31 = 4` fires **zero** times in the clean vehicle, so that closure is a property of what we load, not of the ROM.

**Mislabelled as closed, and the single largest recoverable block — `f98`.** `CORPUS-PATTERNS-SPECULATIVE.md:619` closes it because its 5 minimal pairs have "ZERO co-resident" instances — but co-resident there means *within one image*, and **the resident frame carries two images**. I checked pair 5 directly today: `0012A001D5` (f98 = 0) occurs only in **a08 GATED REVERB**, a *unit‑0* image; `0212A001D5` (f98 = 2) occurs in **a16 ROOM REVERB 1**, which `programs.tsv:14` records as *"the ONLY unit-1 image, shared by the 12 reverb presets algos 16–27"*. Both words are otherwise byte-identical and both pass `alu_decoded()`. **Selecting GATED REVERB into unit 0 while any reverb preset sits in unit 1 makes an `f98` minimal pair co-resident in a single frame.** One effect selection. 41.9 % of the corpus hangs on it.

Same shape, cheaper: `hi12` bit 5 already has a co-resident pair *inside one image* — `000.2.00.000` (×62 in 15 images) vs `020.2.00.000`, both live in **a15 ROCK ROTARY**, and `effect-selection-recipes.json` carries a ready recipe (`SoundDSP/RockRotary/Standard`). One program load decides whether a `nop` the disassembler prints 62 times is a `nop`.

**Bottom line:** 100 % in the D1 sense is not achievable and should be formally abandoned as a goal. The achievable target is D3 plus roughly 45–50 % on D1, and the difference between "we stalled at 38.5 %" and "we reached the honest ceiling" is currently **three unrun experiments and a relabelling pass**.

---

## 4. COMPLEMENTARY APPROACHES — ranked

### (a) Things the autonomous agents can do alone

1. **Finish the kernel‑A rail** (the current blocker, queue item 10). Bisected: drop `iw33`'s carried term alone, *then* consider `P_SHIFT = 7`. Falsifiers already written.
2. **Ship a 44 100 Hz DSP frame clock.** `kn5000_tonegen.cpp:78` allocates the stream at 48 000, `:741` hard-codes `SAMPLE_RATE = 48000.0`, and `:2163` calls `m_dsp1->run_frame()` from that stream — so the DSP frame clock is 48 000/s against Fs = 44 100 "proven four ways". **The repo already contains the confirming measurement without recognising it:** `LEDGER.md:537` records the emulated chorus LFO at *"0.652 Hz against the panel's 0.599"* as an unexplained residual. Arithmetic: `114 × 48000 / 2²³ = 0.65231`; `114 × 44100 / 2²³ = 0.59934`; ratio 1.0885 = 48000/44100 = 1.08844. The residual **is** the clock error, to four significant figures. Fixing it lands the LFO exactly on the ROM's design rate.
3. **The `f98` cross-unit A/B** (§3 above). The largest undecoded field on the chip, one effect selection away.
4. **`hi12` bit 5 via ROCK ROTARY**, and **trap-not-zero for the six unread SRC codes.** The shipped build injects **10 702 080** silent zeros per run (`0x01:1204800 0x05:1205760 0x06:1204800 0x0A:1203840 0x13:4705920 0x1C:1176960` — I summed them; the 14.7 M figure circulating in the review is 37 % high). Do **not** implement them — dead end 4 and standing rule 4 forbid implementing a consumer whose index is measured constant. Just make the zeros loud, so every past and future null is honest about which zeros are chip zeros.
5. **Generate the continuity artefacts.** A shipped-fix table derived from the source's own gate declarations; a linter that fails if `HANDOFF-NEXT.md` quotes a mask literal that is not `m_specmask`'s value (it currently says `0x46A39B440F` at `:965` against `upd6383.h:1015 = 0xb910e446a39b440f`, while the *same file* says the mask is EXHAUSTED at `:544`/`:665`); a rules-index completeness check; and **make `gen_ledger.py` sweep `kn7000_mame/notes/`** so repo-external negatives like the KN7000 correlation land in the dead-end tier.
6. **Briefs as pointer-carriers, not fact-carriers.** Six of ten read-only passes on 2026‑07‑31 recorded errors injected by their own brief; `SQUARING-MULTIPLY_findings.md:539-546` corrects **seven** framings in one table. Ban restated findings and line-number citations; require commit hash + author-time and let the agent re-read.

### (b) Things needing Felipe or the real hardware — **the only channel with zero data after nine days**

There is no `.wav`, `.flac`, `.aif` or `.mp3` of the real KN5000 anywhere in the three repos. `TODO-FOR-FELIPE.md` §1 has asked for one since 2026‑07‑22T20:31 and has not been touched since. A measured T60 gives the **per-pass loop gain numerically** — the one number `§43`/`§49`/`§53` guessed wrong three times.

Two things must be settled by the agents *before* asking, or the capture is void:
- **Gate H0.** `kn5000-docs/effects-dsp.md` is 327 lines, last committed 2026‑07‑26, and carries no UI-name → algorithm-slot → **chip** → image-hash table. "ROOM" names both an IC311 effect and IC310's master reverb (slot 88); without the table a capture may measure the wrong chip. The raw material exists — 224 recipes in `effect-selection-recipes.json`.
- **Decide the capture point.** The standing rule says DO3 only, but roadmap risk 34 is right: `m_do[unit][…]` is written only at `upd6383.cpp:2475/2476` with `unit ∈ {0,1}`, so **`m_do[2]` is never written** and a DO3 capture has no emulated comparand. Either render DO3 through the HD‑AE5000 first, or accept DO1/DO2 vs the main mix with IC310 contamination documented.

### (c) Things needing external resources

- **X1 — the `M5M44260AJ-7S` datasheet.** Cost: minutes. `ROADMAP:405` records that *no search was ever run*. It settles the delay arena's real organisation and upgrades a load-bearing INFERRED fact to MEASURED. Cheapest external item in the project.
- **X3 — a Pioneer CDJ‑500 / CDJ‑500G firmware dump** (uPD6383GF = IC302 there). The **only** route to the six SRC hapaxes, the kernel-only classes 8/9/C/D and the bit‑11 drought — none reachable by any KN5000-internal method. Community-bound, latency in weeks. Dispatch and then ignore; it can never be on the critical path.
- **X4 — the datasheet.** Documented exhausted (`q="uPD6383"` returns 0 across Google Patents). The residual patent leads (`JPH05313889A`, surfaced by a loop-counter query) are worth one hour of network time and nothing more. **Do not** re-run the uPD6380 cross-decode — 24-bit vs 36-bit words, verified divergent.

---

## THE SIX NEXT ACTIONS, RANKED

| # | Action | Cost | Kill-condition |
|---|---|---|---|
| **1** | **Decide the kernel‑A rail** — queue item 10, `iw33`'s `f31 = 1` CARRY reading, **bisected** (carry first, `P_SHIFT` only after). Do not retarget the lane. | 1–2 build-lane passes. Falsifiers already written: `§41`, SINGLE DELAY's `+0.02149296`, `§S3`'s ladder, `§S1`'s 4.924 %, and PEQ + SINGLE DELAY must stay bit-identical. | `§S1`'s quiet rate does not move off 4.924 % and `§S2`'s `iw33` stays at 1.720 FS with a non-zero fired count ⇒ the carry reading is not the defect and the rail is elsewhere in the six sites. |
| **2** | **Ship the 44 100 Hz DSP frame clock**, preferably by decoupling `run_frame()` from the 48 kHz tonegen stream rather than moving the stream. | 1 build-lane pass + a KN5000 tone-generator audio regression (it touches shipping audio). | The LFO's measured wrap period does not land on 0.599 Hz after the change ⇒ the 0.652 residual has another cause and the arithmetic coincidence is exactly that. A tonegen pitch regression that cannot be absorbed ⇒ decouple instead of moving the stream. |
| **3** | **Run the `f98` cross-unit A/B**: select **GATED REVERB** into unit 0 with a reverb preset resident in unit 1, making `012.A.00.1D5` / `212.A.00.1D5` co-resident in one frame. Pre-compute the confound set **from disk before building**. | 1 read-only pass to pick the discriminator + 2 build-lane arms. | The corpus pre-computation shows the two images differ in too many other fields to isolate the pair ⇒ abort before the build, and `f98` stays closed with its reason correctly restated as "no clean discriminator", not "no co-resident pair". |
| **4** | **Felipe, physical — one 30-minute sitting.** ① Build gate H0 first (agents, ~1 read-only day) and publish the UI-name → slot → chip → image-hash table. ② Then: **(a)** select CONCERT REVERB 1 at factory depth, master/panel reverb at minimum, everything else silent — play **one short percussive note**, let it ring ≥6 s, and confirm the dry note is visible in the recording (mandatory positive control); **(b)** repeat identically with the DSP effect **OFF**, same gain, same session; **(c)** change **only** the effect name to **SLOW ATTACKER** and play the same note. Also **(d)** photograph the **X301 crystal** marking and the **IC311** marking, and **(e)** note the part number of the DRAM chip next to IC311. Line out preferred, 24-bit 44.1/48 kHz; a phone recording of (a)–(c) is better than nothing. Commit the files. | ~30 min of Felipe. Agents pre-register the predicted early reflections (254/870/978/366/1044 samples = 5.760/19.728/22.177/8.299/23.673 ms) and the T60 band **in git before he records**. | Take (b) is not audibly different from take (a) ⇒ the wrong chip or the wrong output was captured; re-do with the H0 table in hand. If IC310's master reverb cannot be turned down far enough to expose IC311's tail, the take is void — which is why (b) is mandatory. |
| **5** | **Generate the continuity artefacts and file the four missing dead ends** (KN7000 correlation NEGATIVE; the delay-length falsification; the frame-start seed refutation; the class‑6 lookup). Extend `gen_ledger.py` to sweep `kn7000_mame/notes/`. Define RULE 20 or delete it. | ~2–3 agent-hours, read-only, no lane, no runs. | The linter fires on legitimate historical quotations often enough to be disabled ⇒ scope it to `HANDOFF-NEXT.md` and `LEDGER.md` only, never the register. |
| **6** | **Bundle three cheap decode/instrument items into one lane pass**: `hi12` bit 5 via ROCK ROTARY; loud TRAP banners for the six unread SRC codes (10 702 080 silent zeros/run); and one unconditional `logerror` per program upload naming load address, word count and image hash, so "how many images have ever executed" stops being an inference. | 1 build-lane pass, ~10 lines each, rides on arms already being taken. | ROCK ROTARY measures `020.2.00.000` behaviourally identical to `000.2.00.000` on every channel ⇒ bit 5 is inert and the `nop` reading is **confirmed** — still a result, and the first field decision in five days. |

---

## WHAT I DROPPED, AND WHY

- **"The goal metric is manufactured in a `default:` branch."** Refuted. `do_presentation()` reads the **accumulator** (`upd6383.cpp:2385`, writes at `:2475/:2476`); `SRC 0x0A`'s `default:` return feeds the *bus*, which for `iw78` lands in D‑RAM cell `0x00`. `INSTRUMENT-AUDIT_findings.md` §10 item 7 had already cleared that instrument as SOUND.
- **"Retire §70/§211 as the goal metric."** It already is not one. `LEDGER.md:277`: *"Grade on `§S1`'s per-`iw` clip count, **never** on `§70`/`§211`."*
- **Seeding the coefficient cursor at frame start (`UPD6383_CURSEED`).** Refuted 26 minutes after the commit it was built on: the base *is* seeded by `iw69 ldptr #$90`, and the same ladder at base `0x0B` with PARAMETRIC EQ loaded reaches **2.733 FS** — 1.6× worse.
- **"Out-path decode, n/32" as a headline metric.** 26 of its 32 denominator slots are C-format or `class4 ∉ {2,8,A}` and can never score. A metric that reads 0/32 whether the project is healthy or dead is exactly the criterion-that-cannot-fail this project has caught thirteen times.
- **"Open the KN7000/SHARC engine as an oracle."** Already run 2026‑07‑22 and **NEGATIVE**. Only the meta-lesson survives, and it is action 5.
- **"Run a synthetic microcode positive control."** The device has already emitted non-zero DO — peak 1 543 433 in the PEQ vehicle, and §222's 826 040/826 040 full-scale frames. The disjunction it promised is not live.
- **"Every frame is discarded by the trap gate."** Stale source comment. The current log reads *"frames that TRAPPED 0 (0.00 %)"*.
- **The call-vector targeting complaint**, and **a second concurrent MAME lane** (the queue's standing constraints say "ONE run at a time", and §222's five-arm re-run was forced by a source change a run-only lane could not have made).
- **"Implement SRC 0x13 now."** Dead end 4: every index candidate is measured constant (`acc 0..0 | m_dp 12..12 | cursor 9..9`, 1 129 389 hits). Only the trap banner survives, in action 6.
- **A hard cap on register section length.** The series it rests on was relayed rather than computed, and it collides with the findings-file provenance fix. If you want it, A/B it against the correction rate; do not ship it on judgment.

**One-line answer to the question you asked:** the method is better than the field standard and the lane's current target is correct — but the project has stopped decoding while telling itself it is decoding, has left a 4 %-of-everything clock error and three one-selection experiments on the table, and has never once asked the instrument in your living room a question. Fix the rail, fix the clock, run the two co-residency experiments, and spend thirty minutes with a microphone.