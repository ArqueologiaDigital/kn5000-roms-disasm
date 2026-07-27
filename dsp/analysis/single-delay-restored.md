# SINGLE DELAY restored — the third known-mathematics context runs, and the first thing it produced was a false positive I caught

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus and simulation only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **CONSISTENT** / **VOID** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THERE ARE THREE KNOWN-MATHEMATICS CONTEXTS, NOT TWO, AND THE THIRD WAS NEVER CHECKED.** [`three-codes.md`](three-codes.md) §1 concludes *"both instruments this chip has are blind"* to `ACT 0x0D`/`0x0E`/`0x1A`, having tested PARAMETRIC EQ and the LFO. [`action00-discriminator.md`](action00-discriminator.md) item D names **PARAMETRIC EQ, SINGLE DELAY and the LFO**. SINGLE DELAY carries **`ACT 0x0D` ×4 and `ACT 0x0E` ×4**. | **MEASURED** |
| **B** | ★★ **Its harness was voided in round 6 and never rebuilt.** [`adjudication-round6.md`](adjudication-round6.md) items A/B: the DRAM polarity was reversed against `dram_dir()`, and the `Line` read and wrote **one index**, so the delay came from port order rather than from the descriptor. [`adjudication-round7.md`](adjudication-round7.md) item E: *"the SINGLE DELAY leg is the void one."* **Both defects are still in `action00_discriminate.sd_run()` today.** | **MEASURED** |
| **C** | ★★★ **RESTORED, AND IT PRODUCES ITS KNOWN OUTPUT.** With a rotating-cursor DRAM the delay falls out of the descriptors: `write 31871 / read 31370 → 501` and `write 15935 / read 15435 → 500` — a **stereo ~11.3 ms delay**. An impulse comes back at **exactly 500 at `w46` and 501 at `w5`**. First time this program has ever produced its predicted output. | **MEASURED** |
| **D** | ⛔ **A POLARITY CONFLICT THAT DISSOLVED ON ENUMERATION — reported here because it was nearly published.** At the forced polarity, an exhaustive sweep over **261 entry states × 256 start pointers = 66 816** configurations delivered the input to a delay-DRAM write **zero** times, while the reversed polarity did so 1 024 times. That looked like a fourth witness against [`adjudication-round5.md`](adjudication-round5.md) item D. **It was an artefact of MY fixed ALU readings.** Enumerating `order × act00 × act0d × act0e` gives **7 680** delivering configurations at the forced polarity. **Round 5 item D stands, untouched.** | **MEASURED**; the conflict is **WITHDRAWN** |
| **E** | ⛔ **AND THE `ACT 0x0E` DISCRIMINATION IT THEN OFFERED IS VOID.** The sweep showed `act0e ∈ {tA←bus, tB←bus, tA←acc, tB←acc}` delivering 60 times each and **`mem←bus` never** — which would contradict [`three-codes.md`](three-codes.md) items B and C, whose two independent routes both give `0x0E = mem[ptr] ← bus`. **The calibration refutes the instrument, not the consensus.** | **VOID** |
| **F** | **`ACT 0x0D` is not discriminated either** — all five readings deliver **48** configurations each; only `None` fails. Consistent with item E of `three-codes.md` calling `0x0D` the hardest of the three. | **MEASURED** (a negative) |

---

## 1. The calibration that voided item E

`ACT 0x07` is **ANCHORED** as `mem[ptr] ← bus`. If the test can see the
memory-versus-register distinction at all, then re-pointing that *known* memory
writer somewhere else must change what it delivers.

```
   configuration                      configs delivering
   baseline (act0e = tA<-bus)                 32
   act0e = mem<-bus          TARGET            0

   dest07 = mem   KNOWN memory writer         32
   dest07 = tA                                32
   dest07 = tB                                32
   dest07 = acc                               32
```

★ **Moving the anchored memory writer off memory changes nothing — 32, four times
out of four.** The instrument is blind to memory-versus-register. Its rejection of
`act0e = mem←bus` therefore cannot be attributed to that distinction, and no
conclusion about `ACT 0x0E` may be drawn from it.

### 1.1 And the mechanism is visible

Tracing the frame directly, with entry cell `0x03` and `p0 = 0x08`:

```
   act0e = tA<-bus     ACT 0x0E at w045: pointer = 0x03, wrote []
                       DRAM write carrying signal: w46
   act0e = mem<-bus    ACT 0x0E at w045: pointer = 0x03, wrote [(0x03, 0)]
                       DRAM write carrying signal: NONE
```

**The `0x0E` word at `w045` sits on pointer `0x03` — the input cell — and under
`mem←bus` it writes a zero over it.** The zero is a property of *where this
harness injects the input*, not of what the opcode does.

## 2. Why this keeps happening, stated plainly

This is the **sixth** instrument in a week that could not measure what it was built
to measure, and the third caught *before* a conclusion was stated. All six share
one shape, already named in [`three-codes.md`](three-codes.md) §5.1: **each tested a
LEVEL or a PRESENCE when the claim was about an IDENTITY or a TREND.**

"Does the input reach a delay-DRAM write" is a **presence** test. The claim it was
being asked to support — *what does `ACT 0x0E` do* — is an **identity**. A presence
test cannot separate two opcodes that both let signal through by different routes,
and it fails any opcode whose side effect happens to overwrite the probe.

## 3. What survives, and it is not nothing

★ **SINGLE DELAY executes end to end and emits the delay its descriptors specify.**
That was not true this morning, and it has not been true at any point in this
project's history. The context is *live*; only this particular observable was
useless.

## 4. What the next pass needs

1. ★ **Score the echo's VALUE, not its existence.** SINGLE DELAY's mathematics is a
   comb: `y[n] = a·x[n] + b·x[n−D]`, `D ∈ {500, 501}`, and the two gains are in the
   C-RAM stream. Comparing the emitted amplitude against that reference is an
   **identity** test and is the instrument item E needed.
2. ⛔ **Do not re-run the presence test.** §1 shows it cannot see the distinction it
   was asked about; §1.1 shows what it actually responds to.
3. **Carry the calibration into the harness itself.** Every future SINGLE DELAY run
   should print the `dest07` row alongside its result, so an instrument that has
   lost its power announces it.
4. ⛔ **`sd_run()` in `action00_discriminate.py` still carries both round-6
   defects.** Nothing in this note changes that; `sd_rerun.py` is a separate tool
   and the old one's numbers remain void.
