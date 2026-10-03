#!/usr/bin/env python3
"""Keep prom_b's OldCopy_sub_XXXXXX labels in step with the live routine they copy.

QUESTION IT ANSWERS
  0xF6F000's banner (and FINDINGS-prom_b-f00c4d-orphan-cluster.md section 7) name an older build's copy
  of a routine OldCopy_<live name>.  When the live routine was still `sub_XXXXXX`, its copy became
  OldCopy_sub_XXXXXX -- and when the live routine is later named, the copy keeps the stale address
  spelling.  This lists every OldCopy_sub_XXXXXX whose `sub_XXXXXX` label is gone and proposes
  OldCopy_<the name now at 0xXXXXXX>.  REFUSED: an address with no label or several, and a
  thunk-slot `ret` (T_F4xxxx_Nop: a slot name, not a routine name).

RUN
  python3 notes/prom_b_oldcopy_follow.py          # the plan
  python3 notes/prom_b_oldcopy_follow.py --args   # 'old=new' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")


def names_at():
    L = B.split("\n")
    out = {}
    for i, l in enumerate(L):
        m = re.match(r'^([A-Za-z_][\w$]*):', l)
        if not m:
            continue
        for j in range(i, min(i + 4, len(L))):
            mm = re.search(r';\s*(F[0-9A-F]{5})\b', L[j])
            if mm and not L[j].lstrip().startswith(";"):
                out.setdefault(int(mm.group(1), 16), []).append(m.group(1))
                break
    return out


def plan():
    at = names_at()
    rows, refused = [], []
    for full, a, suf in re.findall(r'^(OldCopy_sub_(F[0-9A-F]{5})(\w*)):', B, re.M):
        if re.search(r'^sub_%s:' % a, B, re.M):
            continue
        ns = [n for n in at.get(int(a, 16), []) if not re.search(r'_(Skip|Join|Loop|Return)\d*$', n)]
        if len(ns) != 1:
            refused.append((full, "labels at 0x%s: %s" % (a, ns)))
            continue
        if re.match(r'^T_F4[0-9A-F]{4}_Nop', ns[0]):
            refused.append((full, "0x%s is the thunk-slot `ret` %s" % (a, ns[0])))
            continue
        rows.append((full, "OldCopy_" + ns[0] + suf))
    return rows, refused


def main():
    rows, refused = plan()
    for o, n in rows:
        print(("%s=%s" if "--args" in sys.argv else "%-28s -> %s") % (o, n))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
