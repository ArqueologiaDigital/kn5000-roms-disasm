#!/usr/bin/env python3
"""When a label sits MID-INSTRUCTION, is the decode wrong or is the label spurious?

QUESTION ANSWERED
-----------------
convert_reachable_ranges.rewrite() silently declines 29 ranges / 2,053 bytes
because a label inside the range does not land on a decoded instruction
boundary. Its comment gives the real reason, which is not "the label is in the
way":

    A label that is not an instruction boundary also means the decode disagrees
    with the existing framing, which is reason enough to leave the range alone.

So one of two things is true for each conflict, and they need opposite fixes:

  (a) THE DECODE IS WRONG -- the range is mis-framed and must not be converted.
  (b) THE LABEL IS SPURIOUS -- an artefact of an automated naming pass, sitting
      at an address that is not an instruction start. Then the decode is right
      and the label should go.

⚠ Telling them apart CANNOT be done with the byte-match gate: both readings
reproduce the ROM byte-for-byte, and deleting a label changes no bytes either
(spec anti-patterns 12 and 13).

WHAT THIS MEASURES, per conflicting label:
    refs_v7 / refs_v9 / refs_v10 -- is anything jumping to this name?
    A label that SOMETHING references is a real entry point and its address is
    evidence about framing: prefer (a), refuse the range.
    A label referenced NOWHERE in any tree, whose name looks auto-generated
    (`_Data`, `_Block`, `_Table` suffix on top of a neighbouring name), is a
    candidate for (b) -- but see the warning below.

⚠ NOT A LICENCE TO DELETE. v7_unreferenced_labels_are_live.py showed 8,203 of
9,975 apparently-unreferenced v7 labels ARE referenced in v9/v10, because their
callers are still `.byte`. This script only SEPARATES the cases and counts them;
acting on class (b) needs the surrounding code converted first, so that
"referenced by nothing" stops being a statement about progress.

Run:  python3 scripts/analysis/v7_label_vs_decode_conflicts.py
"""
import collections, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
LABEL = re.compile(r'^([A-Za-z_][\w]*):')
SUFFIX = re.compile(r'_(Data|Block|Table|Tail|Cont|Part\d*|[A-Z])$')


def mentions(tree):
    c = collections.Counter()
    for f in sorted((REPO / tree).rglob('*.s')):
        for line in f.read_bytes().decode('latin1').splitlines():
            m = LABEL.match(line)
            rest = line[m.end():] if m else line
            for w in re.findall(r'[A-Za-z_][\w]*', rest):
                c[w] += 1
    return c


def main():
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "cr", REPO / "scripts/converters/convert_reachable_ranges.py")
    cr = importlib.util.module_from_spec(spec)
    saved, sys.argv = sys.argv, ["cr"]
    try:
        spec.loader.exec_module(cr)
    finally:
        sys.argv = saved

    u7, u9, u10 = mentions('v7/maincpu'), mentions('v9/maincpu'), mentions('v10/maincpu')

    # Labels defined in v7 whose name carries an auto-generated-looking suffix
    # AND whose base name also exists -- the `X` / `X_Data` pattern.
    defined = set()
    for f in sorted((REPO / 'v7/maincpu').rglob('*.s')):
        for line in f.read_bytes().decode('latin1').splitlines():
            m = LABEL.match(line)
            if m:
                defined.add(m.group(1))

    paired = [n for n in sorted(defined)
              if SUFFIX.search(n) and SUFFIX.sub('', n) in defined]
    dead_paired = [n for n in paired if not (u7[n] or u9[n] or u10[n])]

    print(f"  v7 labels defined                          : {len(defined):,}")
    print(f"  ...with an auto-looking suffix whose BASE also exists : {len(paired):,}")
    print(f"  ...of those, referenced in NO tree at all             : {len(dead_paired):,}")
    print("\n  The `X` / `X_Data` pattern, unreferenced everywhere (first 15):")
    for n in dead_paired[:15]:
        base = SUFFIX.sub('', n)
        print(f"    {n:44} base {base} refs v7={u7[base]} v9={u9[base]} v10={u10[base]}")
    print("\n  ⚠ These are CANDIDATES for a spurious-label reading, not proof.")
    print("     A base name with live references (see above) means the PAIR sits in real")
    print("     code, so the suffix label is the suspicious half -- but the surrounding")
    print("     bytes must be converted before 'referenced by nothing' means anything.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
