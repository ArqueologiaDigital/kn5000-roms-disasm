#!/usr/bin/env python3
"""Name still-unnamed WSA1 routines that are exact copies of a named routine: <Name>_Copy.

QUESTION IT ANSWERS
  prom_a and prom_b hold the same routine more than once: within an image (MemCopyWords_Copy,
  LCD_ScreenRedraw_Begin_Copy are the tree's spelling) and across the two (prom_a's SongStore_SeekBlock
  is byte-for-byte prom_b's SongStore_SeekBlock_Copy).  This decodes every labelled routine of both images from the
  ROM bytes (kernel_structural_match's decoder), cuts it at its first `ret`, and compares the
  instruction TEXT with only the targets of jr / jrl / djnz masked -- so every register, RAM address,
  constant AND call / calr / jp target must agree (a save-registers wrapper of another function is
  not a copy; masking call targets would have said it was).  A still-unnamed routine identical to a named one is
  that routine's copy:
      <Name>_Copy (then _Copy2, ...), or OldCopy_<Name> inside 0xF6F000-0xF6FFFF, the older build's
      block the 0xF6F000 banner names.
  REFUSED: a group whose named members have different names (which name is the routine's is not
  said), a routine shorter than --minlen instructions (default 8: short bodies coincide), and the
  0xF00C4D module (notes/prom_b_f00c4d_oldcopy_names.py owns it).

RUN
  python3 notes/wsa1_exact_copy_names.py [--minlen N]          # the plan and the refusals
  python3 notes/wsa1_exact_copy_names.py --args [--minlen N]   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import kernel_structural_match as K  # noqa: E402

MINLEN = int(sys.argv[sys.argv.index("--minlen") + 1]) if "--minlen" in sys.argv else 8
BR = re.compile(r'^((?:jr|jrl|djnz)\b.*?)0x[0-9a-f]+\s*$')   # local branches only: a call / jp target must be EQUAL
FILES = {"wsa1:a": os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "wsa1:b": os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")}
SKIP = (0xF00C4D, 0xF01800)
OLD = (0xF6F000, 0xF70000)
LOCAL = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop)\d*$')


def labels(key):
    L = open(FILES[key], "rb").read().decode("latin-1").split("\n")
    out = {}
    for i, l in enumerate(L):
        m = re.match(r'^([A-Za-z_][\w$]*):', l)
        if not m or LOCAL.search(m.group(1)) or m.group(1).startswith("T_F4"):
            continue
        for j in range(i, min(i + 4, len(L))):
            mm = re.search(r';\s*(F[0-9A-F]{5})\b', L[j])
            if mm and not L[j].lstrip().startswith((".long", ".byte", ".short", ".ascii", ";", ".fill", ".incbin")):
                out.setdefault(int(mm.group(1), 16), m.group(1))
                break
    return out


def plan():
    lab, seq = {}, {}
    for key in FILES:
        lk = labels(key)
        dec = K.decode_starts(key, [K.off_of(key, a) for a in sorted(lk)], 512)
        for a, n in lk.items():
            s = dec.get(K.off_of(key, a))
            if not s:
                continue
            t = []
            for x in s.text[:300]:
                t.append(BR.sub(r'\1#', x))
                if x.startswith("ret") and not x.startswith("reti"):
                    break
            if len(t) >= MINLEN and t[-1].startswith("ret"):
                lab[(key, a)] = n
                seq[(key, a)] = tuple(t)
    grp = collections.defaultdict(list)
    for k, t in seq.items():
        grp[t].append(k)
    taken = set()
    for key in FILES:
        taken |= set(re.findall(r'[A-Za-z_][\w$]*', open(FILES[key], "rb").read().decode("latin-1")))
    rows, refused = [], []
    for t, ks in grp.items():
        subs = sorted(k for k in ks if re.match(r'^sub_F[0-9A-F]{5}$', lab[k]) and not SKIP[0] <= k[1] < SKIP[1])
        named = sorted({re.sub(r'^OldCopy_|_Copy\d*$', '', lab[k]) for k in ks if not re.match(r'^sub_F[0-9A-F]{5}$', lab[k])})
        named = [n for n in named if not re.match(r'^sub_F[0-9A-F]{5}$', n)]   # OldCopy_sub_X names nothing
        if not subs or not named:
            continue
        if len(named) != 1:
            refused.append((", ".join(lab[k] for k in subs), "identical to differently named %s" % ", ".join(named)))
            continue
        base = named[0]
        src = [k for k in ks if re.sub(r'^OldCopy_|_Copy\d*$', '', lab[k]) == base][0]
        for k in subs:
            if OLD[0] <= k[1] < OLD[1] and k[0] == "wsa1:b":
                new = "OldCopy_" + base
            else:
                new, n = base + "_Copy", 2
                while new in taken:
                    new, n = "%s_Copy%d" % (base, n), n + 1
            if new in taken:
                refused.append((lab[k], new + " is taken"))
                continue
            taken.add(new)
            rows.append((lab[k], new, "%s: an exact copy of %s (%s 0x%06X) -- all %d instructions equal, operands included,\\n"
                         "  but the targets of its jr / jrl / djnz (notes/wsa1_exact_copy_names.py)." % (
                             new, lab[src], "prom_a" if src[0] == "wsa1:a" else "prom_b", src[1], len(t))))
    return rows, refused


def main():
    rows, refused = plan()
    for o, n, h in rows:
        print(("%s=%s|%s" % (o, n, h)) if "--args" in sys.argv else "%-12s -> %s" % (o, n))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
