#!/usr/bin/env python3
"""Name the per-page ENTER routines of the four multi-page screens of prom_a's dispatch-matrix module.

QUESTION IT ANSWERS
  FINDINGS-prom_a-dispatch-matrix-and-drum-names.md section 1: four of the module's tables are "NOT a panel-control
  table".  Each is indexed by the page byte UI_ScreenPage (RAM 0x2229) alone, and its reader is a screen's ENTER
  method (PanelScreen_VtableTable_ViewB names it):
      PageDispatch_<Screen>:  cp (UI_ScreenPage),n / jr NC|UGT out / C = 4 * (UI_ScreenPage) / add XBC,<table> /
                              push <ret> / jp (XBC)
  So entry k is the ENTER work of page k of that screen: ScreenEnter_<Screen>_Page<k>, and the table
  ScreenEnterPages_<Screen>.  The screen is taken from the reader's own name (PageDispatch_<Screen>), which wave 8
  derived from the ViewB vtable.  REFUSED: an entry that is not sub_ (kept), one that sits in two slots or tables,
  a reader whose bound does not equal its table's entry count, and a name already taken.

RUN
  python3 notes/prom_a_page_enter_names.py          # the plan
  python3 notes/prom_a_page_enter_names.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
L = A.split("\n")
G = re.compile(r'^([A-Za-z_][\w$]*):')
IDX = {G.match(l).group(1): i for i, l in enumerate(L) if G.match(l)}
PAGE = r'(?:UI_ScreenPage|0x2229)'


def plan():
    rows, refused, where = [], [], collections.defaultdict(list)
    found = []
    for rd, i in IDX.items():
        m = re.match(r'^PageDispatch_(\w+)$', rd)
        if not m:
            continue
        body = "\n".join(L[i + 1:i + 12])
        b = re.search(r'm_cp_mi8 MB16, %s, (0x[0-9a-f]+)\s*;[^\n]*\n\s*jr (nc|ugt),' % PAGE, body)
        t = re.search(r'add XBC,(\w+)', body)
        if not b or not t or not re.search(r'm_mul MB16, %s, 3' % PAGE, body):
            refused.append((rd, "not the page-dispatch shape"))
            continue
        n = int(b.group(1), 16) + (1 if b.group(2) == "ugt" else 0)
        ents = []
        for l in L[IDX[t.group(1)] + 1:IDX[t.group(1)] + 20]:
            mm = re.match(r'^\s*\.long\s+(\w+)', l)
            if mm:
                ents.append(mm.group(1))
            elif l.strip() and not l.lstrip().startswith(";"):
                break
        if len(ents) != n:
            refused.append((rd, "bound %d but %d entries" % (n, len(ents))))
            continue
        found.append((m.group(1), rd, t.group(1), ents))
        for k, e in enumerate(ents):
            where[e].append((t.group(1), k))
    for scr, rd, tab, ents in found:
        if tab.startswith("Dispatch_"):
            rows.append((tab, "ScreenEnterPages_" + scr, "ScreenEnterPages_%s: %s's per-page ENTER table, indexed by UI_ScreenPage (0..%d)\\n"
                         "  (notes/prom_a_page_enter_names.py)." % (scr, rd, len(ents) - 1)))
        for k, e in enumerate(ents):
            if not re.match(r'^sub_F[0-9A-F]{5}$', e):
                continue
            if len(where[e]) > 1:
                refused.append((e, "in %d slots" % len(where[e])))
                continue
            new = "ScreenEnter_%s_Page%d" % (scr, k)
            rows.append((e, new, "%s: ScreenEnterPages_%s[%d] -- what %s, the ENTER method of the %s screen, runs\\n"
                         "  when UI_ScreenPage is %d (notes/prom_a_page_enter_names.py)." % (new, scr, k, rd, scr, k)))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    news = [n for _o, n, _h in rows]
    for o, n, h in rows:
        bad = news.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-16s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if not (news.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
