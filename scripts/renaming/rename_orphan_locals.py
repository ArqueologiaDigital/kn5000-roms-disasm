#!/usr/bin/env python3
"""rename_orphan_locals.py -- local branch labels that still carry a renamed-away parent name follow the parent.

QUESTION IT ANSWERS
  Renames change a routine's label but not its local branch labels: after sub_F0001A became a named routine, its
  `sub_F0001A_Skip` / `_Join` / `_Return` stayed, so prom_b still reads like an address map inside named code.
  KN5000 has the same leftovers, e.g. MiddleFuncCall_DispatchData_Code_Helper_Skip inside SqTrAs_CursorNextTrack.
  A local is a label <P>_<Suffix><N> with Suffix one of Skip/Join/Loop/Return/Epilogue/Done/Next/Exit/Cont/End/
  Default/Resume/Nop.  The scripts/renaming/*.sed files record every rename.  This script renames a local only when
  all of these hold:
    - P is no longer a label in the tree, and either P was renamed away by one of those .sed files or P is
      positional (sub_/LABEL_/loc_ + 6 hex digits, or a _Helper name);
    - there is an enclosing routine: the nearest non-local label above it in the source (the Parent), and its
      name is not positional (no 6 hex digits; renaming sub_X_Skip to sub_X_Entry_Skip would gain nothing).
  The new name is <Parent>_<Suffix><N>, with N kept when it is free, else the next free number.  It is counted
  when following P's renames does not lead to Parent.  That is common: the conversion named locals after a wider
  function that later splits divided, so the dead prefix belonged to a neighbour.  The local still sits inside
  Parent, and its new name says so.
  KN5000 trees are rewritten here (every *.s of the tree, whole words).  WSA1 images are not: --args prints
  `old=new` lines for wsa1_rename.py, which declares the renames to the preservation checks.
  Labels move no bytes; the byte gate is the proof.

RUN (repository root)
  python3 scripts/renaming/rename_orphan_locals.py --tree v10 [--apply]
  python3 scripts/renaming/rename_orphan_locals.py --tree prom_b --args > args.txt
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LOC = re.compile(r'^(.*?)_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)(\d*)$')
DEF = re.compile(r'^([A-Za-z_][\w$]*):')
ADDR6 = re.compile(r'[0-9A-F]{6}')
POSN = re.compile(r'^(sub|LABEL|loc)_[0-9A-F]{6}$|_Helper\d*$')


def renames():
    m = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "scripts/renaming/*.sed"))):
        for x in open(f, encoding="latin-1"):
            r = re.match(r'^s/\\b([A-Za-z_]\w*)\\b/([A-Za-z_]\w*)/g', x)
            if r and r.group(1) != r.group(2):
                m.setdefault(r.group(1), set()).add(r.group(2))
    return m


def files(tree):
    if tree in ("prom_a", "prom_b"):
        return [os.path.join(ROOT, "wsa1", tree, "wsa1_%s.s" % tree)]
    return sorted(glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.s"), recursive=True))


def main():
    a = sys.argv[1:]
    tree = a[a.index("--tree") + 1]
    apply, args = "--apply" in a, "--args" in a
    R = renames()
    src = {p: open(p, "rb").read().decode("latin-1").split("\n") for p in files(tree)}
    defs = {m.group(1) for L in src.values() for x in L for m in [DEF.match(x)] if m}
    taken = set(defs)

    def chain(p, parent):
        seen, todo = set(), [p]
        while todo:
            q = todo.pop()
            if q in seen:
                continue
            seen.add(q)
            if q == parent:
                return True
            todo += list(R.get(q, ()))
        return False

    plan, odd = {}, []
    for p, L in src.items():
        parent = None
        for x in L:
            m = DEF.match(x)
            if not m:
                continue
            n = m.group(1)
            lm = LOC.match(n)
            if not lm:
                parent = n
                continue
            pre, suf, num = lm.groups()
            if pre in defs or not (pre in R or POSN.search(pre)) or not parent or ADDR6.search(parent):
                continue                                  # a positional parent would gain nothing
            if not chain(pre, parent):
                odd.append((n, parent))
            k = int(num) if num else 1
            new = "%s_%s%s" % (parent, suf, num)
            while new in taken:
                k += 1
                new = "%s_%s%d" % (parent, suf, k)
            taken.add(new)
            plan[n] = new
    if args:
        for o, n in plan.items():
            print("%s=%s" % (o, n))
        print("%s: %d locals to rename (%d of them where the old prefix's renames lead elsewhere)" % (
            tree, len(plan), len(odd)), file=sys.stderr)
        return
    print("%s: %d locals renamed after their enclosing routine (%d where the old prefix's renames lead elsewhere)" % (
        tree, len(plan), len(odd)))
    if not apply or not plan:
        return
    rx = re.compile(r'\b(%s)\b' % "|".join(sorted(map(re.escape, plan), key=len, reverse=True)))
    for p, L in src.items():
        t = "\n".join(L)
        t2 = rx.sub(lambda m: plan[m.group(1)], t)
        if t2 != t:
            data = t2.encode("latin-1")
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)
    with open(os.path.join(ROOT, "scripts/renaming/rename_orphan_locals_%s.sed" % tree), "w") as fh:
        fh.write("# written by scripts/renaming/rename_orphan_locals.py\n")
        fh.writelines("s/\\b%s\\b/%s/g\n" % (o, n) for o, n in plan.items())


if __name__ == "__main__":
    main()
