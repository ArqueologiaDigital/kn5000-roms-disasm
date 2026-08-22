#!/usr/bin/env python3
"""How often does each mnemonic appear in the v7 code the disassembly already has?

QUESTION ANSWERED. `convert_reachable_ranges.py` refuses a decode containing
`swi`, `normal`, `max`, `halt`, `ldio`, `ldwio` or a `retd` with a frame over
0xff, on the grounds that those are what ROM TABLE BYTES decode to rather than
what this firmware contains. That is a claim about frequency, and a claim about
frequency has to be measured or it is taste.

This counts every instruction line committed under `v7/maincpu/*.s` at a given
revision (HEAD by default) and prints the census, so the screen can be checked --
and so a mnemonic that turns out to be common can be taken back out of it.

    python3 scripts/analysis/v7_mnemonic_census.py                # rarest 40
    python3 scripts/analysis/v7_mnemonic_census.py swi normal max # named ones
    python3 scripts/analysis/v7_mnemonic_census.py --rev HEAD~1 swi

⚠ Frequency alone does NOT settle it, and the census is why. `swi` occurs 3,804
times, `halt` 391 and `ldio` 396 -- these are not rare, so "rare mnemonic" is the
wrong rule. What made the screen work was reading the SIX ranges it fires on:
five are demonstrably data (a frequency table decoded as `nop / swi 7 / max /
ldwio / normal / halt`, a character map decoded as `rcf / incf / retd 0x1009`)
and the sixth is real code whose `ei 0x06` is why `ei` is NOT in the set.

MEASURED at HEAD 2026-08-22: 210,320 instruction lines, 410 distinct mnemonics;
swi 3,804 · halt 391 · ldio 396 · ldwio 165 · retd 152 · normal 5 · max 1.
"""
import collections
import re
import subprocess
import sys

DIRECTIVE = re.compile(r'^\s*\.')
LABEL = re.compile(r'^[A-Za-z_.][\w.]*:')


def census(rev):
    files = subprocess.run(["git", "ls-files", "v7/maincpu"],
                           capture_output=True, text=True).stdout.split()
    c = collections.Counter()
    for f in files:
        if not f.endswith(".s"):
            continue
        blob = subprocess.run(["git", "show", f"{rev}:{f}"],
                              capture_output=True).stdout.decode("latin-1")
        for ln in blob.split("\n"):
            if ln[:1] not in (" ", "\t"):
                continue                      # a label or a column-0 construct
            s = ln.split(";")[0].strip()
            if not s or DIRECTIVE.match(ln) or LABEL.match(ln) or s.endswith(":"):
                continue
            c[s.split()[0].lower()] += 1
    return c


def main():
    argv = sys.argv[1:]
    rev = "HEAD"
    if "--rev" in argv:
        i = argv.index("--rev")
        rev = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    c = census(rev)
    print(f"{sum(c.values()):,} instruction lines at {rev}, "
          f"{len(c)} distinct mnemonics")
    for m in argv:
        print(f"  {m:12} {c.get(m, 0):>7}")
    if not argv:
        print("\nrarest 40:")
        for m, n in sorted(c.items(), key=lambda kv: (kv[1], kv[0]))[:40]:
            print(f"  {m:14} {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
