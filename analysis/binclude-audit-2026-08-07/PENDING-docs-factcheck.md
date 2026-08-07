# PENDING — docs fact-check, behaviour & overclaiming pass

**Status: NOT DONE.** The documentation refresh of 2026-08-07 published with only
*one* of its two adversarial fact-checkers. Run this pass independently and apply
whatever it finds.

## What did run

The **address/structure** checker completed and its 58 verdicts were applied
before publishing: every claim naming a ROM address, size, count, offset, stride
or record layout was re-verified against the sources and the original ROM bytes.

## What did not

The **behaviour, provenance and overclaiming** checker stalled mid-stream twice
(17:44 and 18:26) — both times *after* finishing its investigation (60 tool
calls) and immediately before emitting its structured verdicts. Its reasoning was
in thinking blocks and is unrecoverable; nothing of it survives. The published
pages therefore carry **no independent check on**:

- claims about what code *does* (as opposed to where it lives),
- what is genuinely source-built vs merely labelled,
- **overclaiming**: a region called "documented" that is really a labelled binary
  slice; "fully disassembled" where data was only carved into tables;
  verification described as covering more than `compare_roms.py` checks; anything
  presented as settled that `PLAN.md` still lists as pending.

## Inputs, preserved

`docs-factcheck-inputs.json` — all **292 claims** from the seven writer packages,
each with the evidence its author cited, grouped by package and page. This is the
complete input; the pass can run standalone without re-running the writers.

## The prompt to re-run

> For every claim that asserts what CODE DOES, what a format means, what is
> source-built, or what the project's status is: verify against the actual
> routine / Makefile rule / build output. Then hunt for OVERCLAIMING across the
> published pages — read the pages themselves in `../kn5000-docs/`, not just the
> claims: a region called "documented" that is really a labelled binary slice;
> "fully disassembled" where data was merely carved into tables; verification
> described as covering more than `compare_roms.py` actually checks; anything
> presented as settled that `PLAN.md` still lists as pending. Also confirm each
> page states the remaining work honestly. Return a verdict per claim
> (CONFIRMED / REFUTED / UNVERIFIABLE) with the exact correction text for
> anything refuted.

Note the difference from the original run: the pages are now **published**, so
read them in place rather than from a scratch directory.

## Advice for the re-run

Both stalls happened at the same point — a single large structured return after a
long investigation. Split the work: run it in **two or three agents by package
group**, each returning a smaller verdict set, rather than one agent carrying all
292 claims to the end.
