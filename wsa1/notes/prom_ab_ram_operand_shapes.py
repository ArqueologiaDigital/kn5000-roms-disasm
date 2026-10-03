#!/usr/bin/env python3
"""prom_ab_ram_operand_shapes.py -- every instruction that touches a WSA1 RAM address, grouped by shape.

QUESTION THIS ANSWERS
  For each address given, which instruction shapes use it and how often, and in which routines?
  Examples: `ld (@:16), 0x70` x2, `m_bit 0x00, md16, @` x30; `@` is the address.  This is the census a
  wsa1/notes/FINDINGS-* RAM table rests on.  An address is matched in all three spellings: hex
  (prom_a), decimal (prom_b), and the symbol after naming.  The output is therefore the same before
  and after name_wsa1_ram.py --apply, except that the symbol is printed in place of the number.
  After a load of the byte (`ld c,(A)`), the next instruction is appended when it is a mask or a
  compare, since that is what says which bit is read.

USAGE
  python3 wsa1/notes/prom_ab_ram_operand_shapes.py 0x2073 0x2092 [--names NAME,NAME] [--sites]
  --names   the symbols the addresses have (or will have), in the same order
  --sites   also print the routine of every use
"""
import argparse
import collections
import os
import re
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
FILES = ["wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"]
LAB = re.compile(r'^([A-Za-z_][\w$]*):')


def norm(s):
    """lower case, one space, decimal immediates as hex; `:16` / `:i3` size suffixes kept"""
    s = re.sub(r'\s*,\s*', ', ', re.sub(r'\s+', ' ', s)).lower()
    return re.sub(r'(?<![:\w])(\d+)\b', lambda x: "0x%02x" % int(x.group(1)), s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("addr", nargs="+")
    ap.add_argument("--names", default="")
    ap.add_argument("--sites", action="store_true")
    a = ap.parse_args()
    names = a.names.split(",") if a.names else []
    for k, s in enumerate(a.addr):
        v = int(s, 0)
        spell = ["0x%x" % v, "0x%04x" % v, str(v)] + ([names[k]] if k < len(names) else [])
        pat = re.compile(r'(?<![\w.])(?:%s)(?![\w])' % "|".join(re.escape(x) for x in spell), re.I)
        shapes, where = collections.Counter(), collections.defaultdict(list)
        for f in FILES:
            L = [l.split(";")[0].rstrip() for l in open(os.path.join(REPO, f), "rb").read().decode("latin-1").split("\n")]
            cur = "?"
            for i, l in enumerate(L):
                m = LAB.match(l)
                if m:
                    cur = m.group(1)
                s2 = l.strip()
                if not s2 or not pat.search(s2) or LAB.match(s2):
                    continue
                shape = norm(pat.sub("@", s2))
                if re.match(r'ld [a-z]+, \(@(:16)?\)$', shape) and i + 1 < len(L):
                    n = norm(L[i + 1].strip())
                    if re.match(r'(and|cp|bit|or)\b', n):
                        shape += "  / " + n
                shapes[shape] += 1
                where[shape].append("%s:%s" % (f[5:11], cur))
        print("== 0x%04X%s  %d uses" % (v, " " + names[k] if k < len(names) else "", sum(shapes.values())))
        for sh, c in shapes.most_common():
            print("  %4d  %s" % (c, sh))
            if a.sites:
                print("        " + ", ".join(sorted(set(where[sh])))[:300])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
