# Wave 24 tool — lane `w24/e093-block`

One script, and the question it answers. It reads
`original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}`, and opens the `.s`
listings for exactly one thing — the set of instruction START ADDRESSES and their
canonical spellings, which the converters gate on a byte-identical round trip, so
that a byte-level census can say whether a hit lies in code or in a region this
tree frames as data. Run it from the `wsa1/` directory. Findings:
`notes/FINDINGS-l7a1429-e093-block.md`.

| script | the question it answers | command |
|---|---|---|
| `notes/w24_e093_coupling_solver.py` | *`FINDINGS-l7a1429-gate-and-keyscaling.md` §1.8 says the per-element block at RAM `0x00E093` has **no located reader** and grades it UNIDENTIFIED. Is that true, and if not, what is the block?* It finds the reader — `Pack104_SolveCoupledDetune`, handed the block's address **on the stack** — decodes every magic constant in it as a Q11 rendering of a named quantity, re-implements the routine bit-exactly on the ROM's own tables, and shows the result lands in `P[+0x12]`/`P[+0x14]`, which `Dev104_PackStagingStruct` adds to registers `chan+0x0040` and `chan+0x0080`. The block is the argument struct of a **coupled-resonator detune solver**. | `python3 notes/w24_e093_coupling_solver.py` · `--selftest` · `--census` · `--reach` |

**What a pass means.** Every structural claim is asserted twice where it matters:
by the CANONICAL SPELLING at an address (a fact about the bytes, since the listing
is a byte-identical round trip) and by an IMMEDIATE decoded straight out of the raw
ROM (a base displacement, a table address, a literal). `--selftest` currently
reports `FAILURES: 0`. `--census` prints every row of §7's byte-level census;
`--reach` runs §6b's 4000-draw reachability sweep (seed 7), which takes about a
minute.

**The nulls, printed inline.**

* **NULL 1 (§5)** — `INTERACTION GAIN` = 0 makes the damping factor exactly
  `0x0800` = 1.0, so the damped and undamped accumulators coincide, the arctangent
  difference is 0, the table index is 128 and `MathTable_Log2_256[128] = 0`. The
  correction is **exactly zero**, and the zero is built into the table.
* **NULL 2 (§5)** — equal tuning words make every octave difference 0, so every
  `omega = pi`, `sin(pi)` reads back as 50/2048, and the product of `N-1` such
  factors underflows the `>>11` truncation. This is why seven of the eight factory
  tones get nothing, and it is a property of their DATA, not of the routine.
* **POSITIVE CONTROL (§5)** — `Fantasia`'s own two elements, whose tunings differ
  by 7 and 10 semitones, return `-13.28` cents. Without it both nulls would be
  criteria that cannot fail.
* **THE STEP AND THE RANGE (§5)** — exhaustive over all 65536 arctangent inputs:
  the output index is confined to 66..189, so the correction is bounded to
  `+1146 / -675` cents and the `0xFFFF` log2 **sentinel at index 0 is
  unreachable**. One index step is 13.28 cents, so the correction can never be
  small.

**The denominator is stated at the rate (§6).** The eight tones that reach the
solver are counted over the **loose 256-tone / 459-record** population;
`dev104_topology_probe.py`'s strict 133-record filter drops every one of them, so
no rate here may be quoted through it. Six of the fourteen solver calls have inputs
the ROM does not determine — they run on element 3 of a three-element tone, whose
sub-record is not in any image — and those are reported as *not computed*, not as
zero.

**The negative that fell, and why.** §7 lists the forms searched before stating
anything: the address as a literal (a framing-independent byte scan for `93 e0`
over all four images, at every offset, 30 hits, all adjudicated), the address as a
**call argument** (three sites — the form the old census missed), a pointer stashed
and dereferenced later, micro-DMA, and the other CPU's address space. The wave-21
census was not wrong about what it looked for: **there are no reads of
`0x00E093`.** The reader never names the block; it is handed a pointer, and `lda`
takes an address rather than storing one.

No `.s` file is edited by this script.
