#!/usr/bin/env python3
"""Are v7 labels that nothing references DEAD, or are their referrers still `.byte`?

QUESTION ANSWERED
-----------------
The range converter refuses 29 ranges / 2,053 bytes because rewrite() will not
drop a label inside the span. A refusal audit found that 25 of those 29 are
blocked by labels NOTHING in v7/maincpu/*.s references, described them as
"transplant-pass artefacts", and suggested DELETING them.

That would have been destructive. `Audio_NullRet1` is referenced by EIGHT
`jr Audio_NullRet1` instructions -- in v9. It looks unreferenced in v7 only
because the code that jumps to it is still un-disassembled `.byte` data. The
label is a live entry point whose referrers have not been converted yet.

So "unreferenced" in a PARTIALLY converted tree does not mean dead. It means
unreferenced *so far*, and the more converting you do the fewer such labels
there are. Deleting them would remove the very targets the next round needs.

WHAT THIS MEASURES
    For every label defined in v7/maincpu/*.s and referenced nowhere in v7,
    ask whether the SAME NAME is referenced in v9 or v10 (which are further
    along in places, and are the same program at a different revision).

      LIVE ELSEWHERE  = referenced in v9/v10 -> a real target, DO NOT DELETE
      UNREFERENCED    = referenced nowhere in any tree -> candidate, still not
                        proof of deadness, because all three trees are partial

⚠ A name shared across revisions is not automatically the same routine: 153 v7
names are known to resolve to a different routine than their v10 namesake. This
script is therefore evidence about DELETION SAFETY only -- "something jumps to
this name somewhere" is enough to refuse a deletion, and that is all it claims.

Run:  python3 scripts/analysis/v7_unreferenced_labels_are_live.py
"""
import collections, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
LABEL = re.compile(r'^([A-Za-z_][\w]*):')


def scan(tree):
    """(labels defined, names mentioned anywhere that is not a definition)"""
    defined, used = set(), collections.Counter()
    for f in sorted((REPO / tree).rglob('*.s')):
        for line in f.read_bytes().decode('latin1').splitlines():
            m = LABEL.match(line)
            if m:
                defined.add(m.group(1))
                rest = line[m.end():]
            else:
                rest = line
            for w in re.findall(r'[A-Za-z_][\w]*', rest):
                used[w] += 1
    return defined, used


def main():
    d7, u7 = scan('v7/maincpu')
    _, u9 = scan('v9/maincpu')
    _, u10 = scan('v10/maincpu')
    unref = sorted(n for n in d7 if u7[n] == 0)
    live = [n for n in unref if u9[n] or u10[n]]
    dead = [n for n in unref if not (u9[n] or u10[n])]
    print(f"  v7 labels defined            : {len(d7):,}")
    print(f"  of those, referenced nowhere in v7 : {len(unref):,}")
    print(f"    ...but referenced in v9 or v10   : {len(live):,}  <- LIVE, do not delete")
    print(f"    ...referenced in no tree at all  : {len(dead):,}  <- candidates only")
    print("\n  sample of LIVE-elsewhere labels (v9/v10 reference count):")
    for n in sorted(live, key=lambda x: -(u9[x] + u10[x]))[:12]:
        print(f"    {n:44} v9={u9[n]:<4} v10={u10[n]}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
