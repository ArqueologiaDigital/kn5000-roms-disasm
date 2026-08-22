#!/usr/bin/env python3
"""How many positional symbol names are actually a PROBLEM?

docs/IS-IT-DONE.md scored L2 partial on "3,627 positional names", counted by
l2_symbol_reference.py as any name ending in _0xHEX or a bare hex tail. That
count is right and the conclusion drawn from it was too harsh.

Most of them are SUB-LABELS of a semantically named parent:

    Display_BytecodeBlock_F_0x32D   an offset inside Display_BytecodeBlock_F

Naming an internal branch target by its offset within a named function is the
correct thing to do -- there is often no better name, and inventing one would be
worse. What actually signals missing knowledge is a positional name with NO
named parent.

MEASURED 2026-08-22 on symbols/maincpu_symbols_reference.txt:

    total symbols .................... 39,393
    positional names ................. 3,627
      sub-labels of a NAMED parent ... 3,285   (fine as they are)
      genuinely unattached ...........   342
        padding markers .............    145   (__pad*, correctly labelled)
        named + address suffix ......    ...   (NakaInst_ON_E12345 etc.)
        no meaning in the stem ......    ...   <- the only real gap

And the unattached ones are not shapeless either -- most are `Naka_Help_NNN_ADDR`
help-table entries, indexed by position because position is what identifies them.

Run:  python3 scripts/analysis/l2_positional_breakdown.py [--list]
Regenerate the symbol file first if the tree moved:
      python3 scripts/analysis/l2_symbol_reference.py --regen
"""
import os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SYMS = os.path.join(REPO, "symbols", "maincpu_symbols_reference.txt")
POSITIONAL = re.compile(r'_0x[0-9A-Fa-f]+$|_[0-9A-F]{4,}$')


def main():
    if not os.path.exists(SYMS):
        sys.exit(f"{SYMS} missing -- run l2_symbol_reference.py --regen first.")
    rows = []
    for line in open(SYMS):
        if line.startswith("#") or not line.strip():
            continue
        f = line.split()
        if len(f) == 2:
            rows.append(f[0])
    names = set(rows)
    positional = [n for n in rows if POSITIONAL.search(n)]
    sub, orphan = 0, []
    for n in positional:
        stem = POSITIONAL.sub("", n)
        if stem in names and not POSITIONAL.search(stem):
            sub += 1
        else:
            orphan.append(n)
    print(f"total symbols .................... {len(rows):,}")
    print(f"positional names ................. {len(positional):,}")
    print(f"  sub-labels of a NAMED parent ... {sub:,}   (fine as they are)")
    # Of the unattached ones, most still carry a MEANING in the stem -- the
    # trailing address only disambiguates repeated entries (`NakaInst_ON_E12345`,
    # `Str_AllOption_E3...`), or marks padding (`__pad*`). A name that says what
    # the thing is and where it lives is not a missing name.
    pad = [n for n in orphan if n.startswith("__pad")]
    meaningful = [n for n in orphan
                  if not n.startswith("__pad")
                  and len(re.sub(r'[^A-Za-z]', '', POSITIONAL.sub("", n))) >= 3]
    rest = [n for n in orphan if n not in pad and n not in meaningful]
    print(f"    padding markers ..............   {len(pad):,}")
    print(f"    named + address disambiguator .   {len(meaningful):,}")
    print(f"    no meaning in the stem .......    {len(rest):,}   <- the real gap")
    for n in rest[:10]:
        print(f"       {n}")
    if "--list" in sys.argv:
        for n in orphan:
            print("   ", n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
