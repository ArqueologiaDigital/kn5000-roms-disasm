#!/usr/bin/env python3
r"""Spell the WSA1 `.byte` lines that the assembler CAN spell, byte-identically.

QUESTION IT ANSWERS
    `notes/sound/wsa1_unspellable_forms.py` says which certified sites already
    have a spelling and are nonetheless still carried as `.byte`.  This rewrites
    exactly those lines, and nothing else.

★★ THE BYTES ARE THE SPECIFICATION.  Every line it produces is handed back to
   llvm-mc and kept only if the encoding is byte-for-byte what the line came
   from.  `../../Makefile` + `scripts/analysis/assert_byte_identical.py` is the
   real certificate; this only changes how bytes are spelt.

⚠ WHY THIS EXISTS RATHER THAN
  `../../../scripts/converters/convert_unspellable_forms.py`.
   That tool converts EVERY `.byte` line whose bytes happen to decode, and its
   docstring says why that is safe there: "Nothing here CHOOSES what is code.
   Every line it touches is already a single decoded instruction that a previous
   round framed from the committed unidasm listing."  THAT PREMISE IS FALSE IN
   THIS TREE.  prom_a alone carries 5,143 `.byte` lines that are data tables,
   and 3 bytes of a font or a velocity row decode as readily as 3 bytes of code.
   Running it here would reframe data as instructions and the byte gate would
   stay green, because the bytes would be the same.  So the candidate set here
   comes from the census's four gates -- byte echo, ROM-at-address, unidasm
   framing, round-trip -- and from nowhere else.

⚠ IT ADDS THE RENDERING TO A GRADE-B COMMENT.  These mnemonics are raw encoding
   names (`ldb_erp a, 0xe3`); unidasm's `ld QW,A` is the readable form and the
   line loses its only human-readable description without it.  Nothing is ever
   removed from a comment.

⚠ WRITING TAKES `--apply`, AND THE BARE RUN IS A DRY RUN.  notes/probe_health.py
   records what a writer with no flag costs: scripts/analysis/gen_prom_d_asm.py
   writes by default, its first health run invoked it bare in all four trees, and
   it rewrote the very files whose layout was under test.  Nothing here should be
   one command-line typo away from that.

RUN:  python3 scripts/converters/convert_certified_forms.py            # dry run
      python3 scripts/converters/convert_certified_forms.py --apply
      python3 scripts/converters/convert_certified_forms.py --selftest
"""
import collections
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))            # .../wsa1
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import write_part                         # noqa: E402

_spec = importlib.util.spec_from_file_location(
    "census", os.path.join(ROOT, "notes", "sound", "wsa1_unspellable_forms.py"))
census = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(census)

# ⚠ THE `;` COLUMN IS NOT CONSTANT.  prom_a parks it at 54 for most of the
# image and at 47 from about 0xFE5F00 on, so a fixed column would re-align a
# whole region -- a diff full of whitespace noise around the two lines that
# actually changed.  Each rewritten line keeps ITS OWN comment column, taken
# from the line being replaced.


def candidates():
    """[(relpath, lineno, text, comment)] -- certified, spellable, still .byte.

    ⚠ PER SITE, NOT PER FORM.  census.spelling()'s second route types unidasm's
    rendering verbatim, and a form's siblings do not share a rendering: the four
    `srl (XIZ+N)` sites are +0x08, +0xfc, +0xf6 and +0x08.  Spelling them all
    from the exemplar would write the first site's displacement into all four --
    and three of them would then assemble to bytes that are not theirs, which
    apply()'s round-trip would catch, but only after the census had reported a
    form as converted when it was not.
    """
    out = []
    for img in census.IMAGES:
        for hits in census.census(img)[0].values():
            if not census.spelling(hits[0].bytes, hits[0].rendering)[1]:
                continue
            for h in hits:
                text, ok = census.spelling(h.bytes, h.rendering)
                if not ok:
                    continue
                echo = " ".join(f"{b:02x}" for b in h.bytes)
                out.append((h.path, h.line, text.replace("\t", " "),
                            f"{h.addr:06X}  {echo}   {h.rendering}"))
    return out


def render(old, text, comment):
    """The replacement line, in the comment column `old` already used."""
    col = old.index(";") if ";" in old else len(old)
    body = old[:col].replace("\t", "", 1).rstrip()
    lead = old[:len(old) - len(old.lstrip())]
    want = col - len(lead.expandtabs(1))          # chars of code before the `;`
    pad = " " * max(1, want - len(text))
    return f"{lead}{text}{pad}; {comment}" if body else f"{lead}{text}  ; {comment}"


def apply(dry_run=False):
    cands = candidates()
    if not cands:
        return 0, []
    # ONE more round-trip over the whole set, together, before anything is
    # written: a line that fails here must not take its neighbours with it, so
    # assemble() returns None unless every line produced an encoding.
    got = conv_assemble([c[2] for c in cands])
    refused = []
    keep = []
    for c, enc in zip(cands, got):
        want = [int(x, 16) for x in c[3].split("  ")[1].split()]
        if enc == want:
            keep.append(c)
        else:
            refused.append((c[0], c[1], "assembles to "
                            + " ".join(f"{b:#04x}" for b in enc)))
    by_file = collections.defaultdict(list)
    for rel, line, text, comment in keep:
        by_file[rel].append((line, text, comment))
    for rel, edits in sorted(by_file.items()):
        path = os.path.join(ROOT, rel)
        lines = open(path, encoding="utf-8").read().split("\n")
        for line, text, comment in edits:
            assert lines[line - 1].lstrip().startswith(".byte"), \
                f"{rel}:{line} is not a .byte line: {lines[line - 1]!r}"
            lines[line - 1] = render(lines[line - 1], text, comment)
        if not dry_run:
            write_part(path, "\n".join(lines), root=ROOT)
    return len(keep), refused


def conv_assemble(texts):
    got = census.conv.assemble(texts)
    assert got is not None and len(got) == len(texts), \
        "a candidate line failed to assemble; nothing was written"
    return got


def selftest():
    """INVARIANTS.  Not a pinned count -- the candidate list is meant to empty."""
    bad = 0

    # 1. A rewritten line keeps the comment column of the line it replaces --
    #    in BOTH of prom_a's two column conventions, which is the whole point.
    for old, text, comment, want in (
            ("\t.byte 0xc7, 0xe3, 0x99" + " " * 31 + "; F831FF  c7 e3 99",
             "ldb_erp a, 0xe3", "F831FF  c7 e3 99   ld QW,A",
             "\tldb_erp a, 0xe3" + " " * 38 + "; F831FF  c7 e3 99   ld QW,A"),
            ("\t.byte 0xc7, 0xfb, 0x99" + " " * 24 + "; FE6254  c7 fb 99",
             "ldb_erp a, 0xfb", "FE6254  c7 fb 99   ld QIZH,A",
             "\tldb_erp a, 0xfb" + " " * 31 + "; FE6254  c7 fb 99   ld QIZH,A")):
        got = render(old, text, comment)
        if got != want:
            print(f"FAIL  render() moved the comment column:\n"
                  f"  got  {got!r}\n  want {want!r}")
            bad += 1
        if got.index(";") != old.index(";"):
            print("FAIL  render() did not preserve the `;` column")
            bad += 1

    # 2. EVERY candidate round-trips to its own ROM bytes.  This is the whole
    #    safety argument, so it is asserted rather than assumed.
    cands = candidates()
    if cands:
        for c, enc in zip(cands, conv_assemble([c[2] for c in cands])):
            want = [int(x, 16) for x in c[3].split("  ")[1].split()]
            if enc != want:
                print(f"FAIL  {c[0]}:{c[1]} `{c[2]}` assembles to "
                      + " ".join(f"{b:#04x}" for b in enc)
                      + " but the ROM has " + " ".join(f"{b:02x}" for b in want))
                bad += 1

    # 3. THE CANDIDATE SET COMES FROM THE CENSUS.  A regression that widened it
    #    to every decodable `.byte` line is the accident this file's docstring
    #    describes, so check the set is a subset of what the census certified.
    certified = {(h.path, h.line) for img in census.IMAGES
                 for v in census.census(img)[0].values() for h in v}
    stray = [(c[0], c[1]) for c in cands if (c[0], c[1]) not in certified]
    if stray:
        print(f"FAIL  {len(stray)} candidate(s) are not census-certified, "
              f"e.g. {stray[0]}")
        bad += 1

    print("selftest: " + ("OK" if bad == 0 else f"{bad} FAILURE(S)"))
    return 1 if bad else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    dry = "--apply" not in sys.argv
    n, refused = apply(dry_run=dry)
    print(f"{n} line(s) {'would be ' if dry else ''}converted"
          + ("  (dry run -- pass --apply to write)" if dry and n else ""))
    for rel, line, why in refused:
        print(f"  REFUSED {rel}:{line}  --  {why}")
    sys.exit(0)
