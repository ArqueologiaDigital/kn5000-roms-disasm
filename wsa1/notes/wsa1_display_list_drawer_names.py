#!/usr/bin/env python3
"""wsa1_display_list_drawer_names.py -- name an address-named display list after the one routine that draws it.

QUESTION IT ANSWERS
  prom_a / prom_b held 900 display lists named by address (DL_F0xxxx, DisplayList_FExxxx, ...) on 2026-10-06.  A
  list is drawn from its START operand -- XIY, or the last `lda x, (L:24) / push` before the runner call -- while
  XIX is only the END bound (the next list).  When exactly ONE routine loads a list as its start, and that
  routine has a real name, the list is "the display list <that routine> draws": a DERIVATIVE name, the same kind
  the thunk pass gives T_ slots after their targets.  This script lists those lists and spells the rename:
      <Drawer>_DL         when the drawer draws one such list
      <Drawer>_DL<k>      k = 1, 2, ... in source order, when it draws several
  Not named: lists drawn by several routines, by unnamed (sub_ / T_) routines, by routines whose own name is
  generic (_Helper7, _Data, ...), lists only ever used as an END bound, and `L + offset` references.
  Each renamed list carries `; drawn (start operand) by <Drawer> -- derivative name` as a comment on its LABEL
  line, not as a header line: a header above a label that sits inside a documented region splits the region,
  and data_range_census.py then grades the piece by the one-line header (it cost 43 bytes of KNOWN-A once).

RUN (from wsa1/)
  python3 notes/wsa1_display_list_drawer_names.py --list    # list, drawer, new name, and the counts
  python3 notes/wsa1_display_list_drawer_names.py --args    # 'old=new|header' items for wsa1_rename.py
"""
import collections
import re
import sys

G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop)\d*$')
BARE = re.compile(r'^(DL|DisplayList|DLB|DLTable|DLRec|DLGlyph)_[0-9A-F]{6}$')
UNNAMED = re.compile(r'^(sub|T)_F[0-9A-F]{5}$|^(DL|DisplayList|DLB|DLTable|DLRec|DLGlyph)_[0-9A-F]{6}$')
GENERIC = re.compile(r'_(Helper|Data|Code|Block|Branch|Stub|Part|Case|Entry|Sub|Thunk|Wrapper|Body|Chunk|Tail|Frag'
                     r'|Fragment)\d*(_\d+)*$|_[0-9A-F]{4,}$')


def analyse():
    txt = {i: open("%s/wsa1_%s.s" % (i, i), "rb").read().decode("latin-1").split("\n") for i in ("prom_a", "prom_b")}
    bare = {m.group(1) for L in txt.values() for l in L for m in [G.match(l)] if m and BARE.match(m.group(1))}
    start = collections.defaultdict(list)          # list -> [(drawer, order)]
    order = 0
    for L in txt.values():
        cur = None
        for k, l in enumerate(L):
            m = G.match(l)
            if m and not LOC.search(m.group(1)) and not l.startswith(".L"):
                cur = m.group(1)
            c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
            for mm in re.finditer(r'\b((?:DL|DisplayList|DLB|DLTable|DLRec|DLGlyph)_[0-9A-F]{6})\b(?!\s*\+)', c):
                nm = mm.group(1)
                if nm not in bare:
                    continue
                nxt = re.sub(r'\s+', ' ', L[k + 1].split(";")[0]).strip() if k + 1 < len(L) else ""
                if re.search(r'\bx?iy\b', c, re.I) or (re.match(r'lda x\w+, \(%s:24\)' % nm, c) and nxt.startswith("push ")):
                    order += 1
                    start[nm].append((cur, order))
    plan = {}
    per_drawer = collections.defaultdict(list)
    for nm, refs in start.items():
        drawers = {d for d, _ in refs}
        if len(drawers) != 1:
            continue
        d = drawers.pop()
        if not d or UNNAMED.match(d) or GENERIC.search(d):
            continue
        per_drawer[d].append((min(o for _, o in refs), nm))
    for d, items in per_drawer.items():
        items.sort()
        for k, (_, nm) in enumerate(items, 1):
            plan[nm] = (d, "%s_DL" % d if len(items) == 1 else "%s_DL%d" % (d, k))
    return bare, start, plan


def main():
    bare, start, plan = analyse()
    if "--args" in sys.argv:
        for old, (d, new) in sorted(plan.items()):
            print("%s=%s|; drawn (start operand) by %s -- derivative name (notes/wsa1_display_list_drawer_names.py)"
                  % (old, new, d))
    else:
        for old, (d, new) in sorted(plan.items()):
            print("%-20s %-40s %s" % (old, d, new))
        print("%d address-named lists; %d drawn by exactly one named routine and renamed; %d drawers"
              % (len(bare), len(plan), len({d for d, _ in plan.values()})))


if __name__ == "__main__":
    main()
