# The WSA1R corpus confirms the ISA but closes no OPEN routing code

**Date 2026-09-06.** Reproducer: `dsp/tools/xcorpus_routing_census.py` (self-test
`3057` PASS; read-only, stdlib only).

## The question

The routing guard holds 60.6% of the KN5000's undecoded words, and 97% of the
routing ceiling is in eight SRC/ACT codes. `SRC 0x00` and the `ACT 0x0D/0x0E`
pair are DECIDED (register tail §233/§234). The rest are OPEN:

| code | KN5000 decode-coverage gain |
|---|---|
| SRC 0x11 | +49 |
| ACT 0x0B | +19 |
| SRC 0x08 | +10 |
| ACT 0x08 | +9 |
| SRC 0x0B | +7 |

The strategic review (`STRATEGIC-REVIEW-2026-07-31.md`) said the only lever past
the KN5000's own ceiling is a foreign corpus of the same chip. This session's
cross-decode (`FINDINGS-dsp-isa-crossval.md`) supplied one — the WSA1R's three
uPD6383GF DSPs. The sharp question: does the WSA1R corpus **close** any OPEN
routing code by rule 4 (every site's operand a measured constant), or only
confirm the field structure?

## The answer: it confirms, it does not close (MEASURED)

Every OPEN code keeps the **same class4 / f31 signature across both firmwares** —
strong cross-validation that these are real fields of the shared ISA, not
KN5000 artifacts. But **none is rule-4 closable**: the `addr8` operand varies in
at least one corpus.

| code | KN5000 class4 / distinct addr8 | WSA1R class4 / distinct addr8 | closable |
|---|---|---|---|
| SRC 0x11 | 2/0/A · 30 | 10/2/0 · 39 | NO |
| ACT 0x0B | 1/2/A · 17 | 1/2 · 13 | NO |
| SRC 0x08 | A · 10 | A · 8 | NO |
| ACT 0x08 | A/2 · 28 | A/2 · 32 | NO |
| SRC 0x0B | 1/2 · **3** | 1/A/2 · **30** | NO |

## The sharpest result: SRC 0x0B would have been a false closure

In the KN5000 alone, `SRC 0x0B` carries **only three** `addr8` values
(`0x00, 0x20, 0x60`) — tight enough to tempt a rule-4 closure ("a source at one
of three constant bases"). **The WSA1R corpus has 30 distinct operands for the
same code.** The three-value pattern was an over-fit to the KN5000's forty
programs, not a property of the encoding. This is the cross-validation earning
its keep: a foreign corpus of the same silicon does not only *fail* to close a
code, it can *refute* a closure the home corpus would have licensed.

## What this means for "100% decode"

A richer corpus supplies **occurrences, not a consumer**. Giving one of these
codes a meaning needs a *discriminating execution context* — a run in which the
code's reading changes an observable — exactly as the KN5000's anchored codes
were decided (MAME device arms + the SINGLE DELAY / PARAMETRIC EQ harnesses).
The WSA1R corpus has no such instrument yet: there is no uPD6383 device fed the
WSA1R microcode.

So the honest state of the routing ceiling is:

- **`SRC 0x00`, `ACT 0x0D`/`0x0E`** — decided (the pair's *lag* is hardware Q4,
  unreachable without a real unit).
- **`SRC 0x11`, `ACT 0x0B`, `SRC 0x08`, `ACT 0x08`, `SRC 0x0B`** — structurally
  anchored in two corpora, but their *meaning* needs an execution instrument,
  not a static closure.

The remaining decode is blocked on **instrument, not method** — which is the
same conclusion the strategic review reached by a different road, now with a
second corpus behind it. The one lever that creates the missing instrument is a
**WSA1R DSP MAME device** reusing the existing `upd6383` core: it would both
implement the DSP into the emulator and give these codes their first
discriminating context. Building it (wiring the P7 upload path, the coefficient
and DRAM-descriptor streams into the core) is a multi-session task.
