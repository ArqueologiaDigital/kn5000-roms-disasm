#!/usr/bin/env python3
"""Name the entries of the 23-slot button tables that screens dispatch through PanelCode_ToSlotAndFlags.

QUESTION IT ANSWERS
  A family of screen BUTTON methods (Screen_*_Button in prom_a, the COMBINATION EDIT bodies, ScreenButtonBody_DspEffect,
  ScreenButton_CreatorSelectController, DrawbarScreen_Dispatch) does
      call T_PanelCode_ToSlotAndFlags(code, flags) / mul A,4 / add XWA,<table> / ld XBC,(XWA) / jp (XBC)
  PanelCode_ToSlotAndFlags (prom_b; its header and notes/prom_b_panel_names_round11.py remap()) turns the 5-bit panel
  button code into a SLOT: codes 0x00-0x10 are their own slot, the rewritten 0x11-0x19 fold onto 0-8 (flag bit 2), and
  0x1A-0x1F become slots 17-22.  So slot k of a 23-entry table is
      0-7   SoftKeyCol1-8       8-12  LcdKeyRow1-5       15  ExitKey       16  PageKey       18  NumberPadKey (code 0x1B)
  (round 11's CONTROL map; the number pad is code 0x1B, whose slot is 0x1B - 9).  An entry is named <Control>_<Screen>,
  the screen taken from the reader's own label (Screen_<X>_Button, ScreenButton_<X>, ScreenButtonBody_<X>).
  REFUSED: slots 13 (-1/+1, round 11 REFUSE_SLOT[0x0D]), 14 (no producer) and the 0x1A/0x1C-0x1F slots; an entry
  that is already named, a bare `ret`, one that sits in two slots or two tables; a reader with no screen name.

RUN
  python3 notes/prom_ab_slot23_button_names.py          # the plan and the refusals
  python3 notes/prom_ab_slot23_button_names.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prom_a_screen_key_actions as KA

CONTROL = {**{k: "SoftKeyCol%d" % (k + 1) for k in range(8)}, **{8 + k: "LcdKeyRow%d" % (k + 1) for k in range(5)},
           15: "ExitKey", 16: "PageKey", 0x1B - 9: "NumberPadKey"}
LOCAL = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume)\d*$')
UNNAMED = re.compile(r'^sub_F[0-9A-F]{5}$')


def screen_of(reader):
    for rx in (r'^Screen_(\w+)_Button$', r'^ScreenButtonBody_(\w+)$', r'^ScreenButton_(\w+)$'):
        m = re.match(rx, reader or "")
        if m:
            return m.group(1)
    return None


def tables():
    out = []
    for text in (KA.A, KA.B):
        L = text.split("\n")
        cur = None
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if m and not LOCAL.search(m.group(1)):
                cur = m.group(1)
            if re.search(r'call\s+T_PanelCode_ToSlotAndFlags', l.split(";")[0]):
                for k in range(i + 1, i + 8):
                    mm = re.search(r'\badd\s+x\w+,\s*(\w+)', L[k].split(";")[0], re.I)
                    if mm:
                        out.append((cur, mm.group(1)))
                        break
    return out


def entries(tbl):
    for text in (KA.A, KA.B):
        L = text.split("\n")
        j = next((x for x, ll in enumerate(L) if ll.startswith(tbl + ":")), None)
        if j is None:
            continue
        out = []
        for ll in L[j + 1:j + 40]:
            mm = re.match(r'^\s*(?:[A-Za-z_]\w*:)?\s*\.long\s+(\w+)', ll)
            if mm:
                out.append(mm.group(1))
                if len(out) == 23:
                    break
            elif ll.strip() and not ll.lstrip().startswith(";"):
                break
        return out
    return []


def bare_ret(name):
    for text in (KA.A, KA.B):
        m = re.search(r'^%s:[^\n]*\n((?:\s*;[^\n]*\n)*)\s*([^\n;]+)' % re.escape(name), text, re.M)
        if m:
            return m.group(2).strip() == "ret"
    return False


def plan():
    rows, refused = [], []
    where = collections.defaultdict(set)
    tabs = []
    for reader, tbl in tables():
        ents = entries(tbl)
        tabs.append((reader, tbl, ents))
        for k, e in enumerate(ents):
            where[e].add((tbl, k))
    seen = set()
    for reader, tbl, ents in tabs:
        scr = screen_of(reader)
        for k, e in enumerate(ents):
            if not UNNAMED.match(e) or (tbl, k, e) in seen:
                continue
            seen.add((tbl, k, e))
            if scr is None:
                refused.append((e, "reader %s has no screen name" % reader))
                continue
            if k not in CONTROL:
                refused.append((e, "slot %d of %s is not a named control" % (k, tbl)))
                continue
            if len(where[e]) > 1:
                refused.append((e, "in %d slots/tables" % len(where[e])))
                continue
            if bare_ret(e):
                refused.append((e, "a bare ret"))
                continue
            new = "%s_%s" % (CONTROL[k], scr)
            rows.append((e, new, "%s: slot %d of %s, the 23-slot button table %s dispatches through\\n"
                         "  T_PanelCode_ToSlotAndFlags -- the %s handler (notes/prom_ab_slot23_button_names.py)." % (new, k, tbl, reader, CONTROL[k])))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', KA.A + KA.B))
    names = [n for _o, n, _h in rows]
    for o, n, h in rows:
        bad = names.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-12s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if not (names.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
