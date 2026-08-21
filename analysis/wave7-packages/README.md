# Wave 7 annotation packages -- PENDING INPUT, NOT APPLIED CONTENT

⚠ **Nothing in this directory is part of the disassembly.** These are *proposed* header comments
awaiting integration. The authority for what the disassembly says is always the `.s` files
themselves. A claim that appears here and not in a `.s` file has not been accepted.

## Why these are committed

They existed only in session scratch, which is not storage. Eleven packages of annotation work --
each one a ROM/source investigation that cost real time -- would have been lost to a reboot. They
are committed so the integration can be resumed, or audited, by anyone.

## What the files are

| file | contents |
|---|---|
| `packages-and-critiques.json` | All 12 packages and their 12 critiques, **aligned by array position**. This is the input to the whole integration. |
| `pkgN_fixed.json` | Package N after vetting: an edit list of `{file, anchor, replacement}` ready for `apply_package.py`. |

The pairing in `packages-and-critiques.json` matters and is easy to get wrong -- see
`../wave7-probes/README.md`, "Integrating a package". The workflow journal lists results in
completion order, so reading packages and critiques from there pairs each package with a review
of some *other* package, silently and plausibly.

## Status

**ALL 12 PACKAGES INTEGRATED, 2026-08-21.** Every one applied cleanly and passed the byte-match
gate at 9/9 / 100.00% before its commit. The `pkgN_fixed.json` files record what was actually
applied after vetting -- not what was originally proposed.

Two anchors went stale *during* integration, because an earlier package rewrote the text a later
one was anchored to. `apply_package.py` caught both and wrote nothing:

- package 2 edit[3] -- package 1 had replaced the sentence it attached to. Re-anchored to the
  surviving line, keeping the new content.
- package 11 edit[16] -- package 6 had already made the same correction, and made it better (it
  also flagged the stale line numbers). Dropped as redundant. Two independent agents converging
  on one fix is corroboration, not waste.

That is the whole reason the applier checks anchors instead of trusting them: with seven packages
touching one 46,000-line file, staleness is the normal case, not the exception.

## What vetting changed

The packages are not trustworthy as written, and neither are the critiques. Both have been caught
in false claims by checking against the ROM:

- Package 0 asserted "every F000 the chip receives is this literal". Its critique correctly named a
  second producer, a ROM template whose word 0 is 0xF000. The critique was right.
- Package 0 also said "all ten call sites"; there are twelve.
- Every critique's "the anchor is truncated / this edit would delete code" finding checked so far
  has been an ARTIFACT of the critique prompt slicing anchors at 300 and replacements at 1500
  characters. Judge truncation from the package JSON, never from the critique.
- Package 4's vetting found two errors that BOTH the package and its critique missed, including an
  attribution of 1,153 register equates to a macro-only include file that defines none of them.

So the fixed lists here are third-generation: written, critiqued, then checked against the ROM.
They are still proposals.
