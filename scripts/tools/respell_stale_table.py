#!/usr/bin/env python3
"""respell_stale_table.py -- a stale copy of a pointer table, whose header documents "every value is the live one +/- D", is written as `.long <live label> +/- D`.

QUESTION THIS ANSWERS / JOB IT DOES
  prom_a carries copies of pointer tables from another build (MessageScreenStale_*: "every value is
  the live one - 0x400"; ScreenButtonHandlers_StaleCopy: "words 27..58 = the second table, every value
  + 0xED").  Their values were left as numbers because they are not addresses of THIS image's code
  -- 0xF98D20 lands mid-instruction.  But the header's own finding says what each value IS: the live
  target shifted by D.  So an entry v becomes `.long L - D` (or `L + D`) when v + D (resp. v - D) is
  EXACTLY a label L of the linked ELF; an entry with no such label stays a number.  The expression
  assembles to the same bytes (make gate-all) and states the documented relation instead of a bare
  number.  --delta is what to ADD to a stale value to reach the live one (0x400 for MessageScreen,
  -0xED for the second screen-button table).

USAGE
  python3 scripts/tools/respell_stale_table.py --label MessageScreenStale_ArgHandlers --delta 0x400 [--apply]
  python3 scripts/tools/respell_stale_table.py --label ScreenButtonHandlers_StaleCopy --delta=-0xED \
      --first 27 --last 58 --all [--apply]   # word indices inside the table, the header's numbering
"""
import argparse
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
SRC = os.path.join(REPO, "wsa1/prom_a/wsa1_prom_a.s")
ELF = os.path.join(REPO, "wsa1/rebuilt_ROMs/wsa1_prom_a.llvm.elf")
LONG = re.compile(r'^(\s*\.long\s+)(\S+?)(\s*;\s*([0-9A-F]{6})\b.*)$')
ROM = os.path.join(REPO, "wsa1/original_ROMs/wsa1_prom_a.ic12")
BASE = 0xF80000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--label", required=True)
    ap.add_argument("--delta", required=True, type=lambda x: int(x, 0))
    ap.add_argument("--first", type=int, default=0)
    ap.add_argument("--last", type=int, default=1 << 30)
    ap.add_argument("--all", action="store_true",
                    help="respell symbolic entries too (an earlier pass may have labelled the stale "
                         "value as if it were this image's address); the value is read from the ROM")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rom = open(ROM, "rb").read()
    by = {}
    for l in subprocess.run([NM, "--defined-only", ELF], capture_output=True, text=True,
                            check=True).stdout.splitlines():
        v, t, n = l.split()
        if t in "tT" and not n.startswith(".L"):
            by.setdefault(int(v, 16), []).append(n)
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    start = next(i for i, l in enumerate(L) if l.startswith(a.label + ":"))
    word, done, left = 0, 0, 0
    for i in range(start + 1, len(L)):
        l = L[i]
        if re.match(r'^[A-Za-z_.][\w.$]*:', l):
            break
        if l.lstrip().startswith(";") or not l.strip():
            continue
        m = LONG.match(l)
        if not re.match(r'^\s*\.long\b', l):
            continue
        numeric = bool(m) and re.match(r'^0x[0-9a-fA-F]+$', m.group(2))
        if m and a.first <= word <= a.last and (numeric or a.all):
            at = int(m.group(4), 16) - BASE
            v = int.from_bytes(rom[at:at + 4], "little")
            names = by.get(v + a.delta)
            if names:
                nm = sorted(names, key=lambda x: (x.startswith("sub_") and "__" in x, len(x)))[0]
                if not numeric:
                    print("  [%d] %s -> %s" % (word, m.group(2), nm))
                expr = "%s - 0x%x" % (nm, a.delta) if a.delta > 0 else "%s + 0x%x" % (nm, -a.delta)
                L[i] = m.group(1) + expr + (m.group(3) or "")
                done += 1
            else:
                left += 1
        word += 1
    print("%s: %d entries respelled, %d numeric entries with no live label at value%+#x%s"
          % (a.label, done, left, a.delta, "" if a.apply else " (dry run)"))
    if a.apply:
        open(SRC, "wb").write("\n".join(L).encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
