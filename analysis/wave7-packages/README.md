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

Integrated so far: **package 0** (the IC303 +0x000 control register). The rest are pending. Each
one still needs, in order: apply, byte-match gate (`make clean-all && make all`, 9/9 at 100.00%),
read the gate output, then commit.

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
