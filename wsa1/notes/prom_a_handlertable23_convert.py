#!/usr/bin/env python3
"""Turn prom_a's sixteen `.byte` HandlerTable23_* tables into `.long` tables, and name the handlers they hide.

QUESTION IT ANSWERS
  The SYSTEM-menu module (0xFA0000-0xFA2xxx) keeps its screens' button tables as raw bytes.  Each header says
  "Coverage only: this round reproduces the bytes ... it does not interpret the payload" (notes/prom_a_fa1404_
  identify.py proved the object type and the 92-byte extent).  The payload is 23 little-endian 32-bit addresses.
  Every table is read by exactly one named screen BUTTON method, Screen_<X>_Button, through
      call T_PanelCode_ToSlotAndFlags / mul A,4 / add XWA,<table> / ld XBC,(XWA) / jp (XBC)
  so slot k is the 23-slot control k (notes/prom_ab_slot23_button_names.py):
      0-7 SoftKeyCol1-8   8-12 LcdKeyRow1-5   15 ExitKey   16 PageKey   18 NumberPadKey   21 CompareKey
  The value 0x00F42C70 is prom_b's T_TableDefault_Ret (a thunk onto a bare `ret`), every other value is prom_a
  code -- most of it with NO label, so those handlers are routines nothing can name.  This plans:
    * a label <Control>_<Screen> at each prom_a target that sits in one mapped slot of one table, or
      SoftKeyCols<a>_<b> / SoftKeyCols<a>to<b>_<Screen> when one handler fills a run of soft keys of one table;
    * the table rewritten as 23 `.long` lines, naming each target (label, or the number where the target is
      refused a name -- which is still more than a byte row says).
  REFUSED (left numeric): a target in two tables, in mixed controls, in an unmapped slot, not the start of a code
  line, or whose name is taken.  A target that already has a label keeps it.

RUN
  python3 notes/prom_a_handlertable23_convert.py           # the plan
  python3 notes/prom_a_handlertable23_convert.py --apply   # place the labels and rewrite the sixteen tables
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
PB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop)\d*$')
CONTROL = {**{k: "SoftKeyCol%d" % (k + 1) for k in range(8)}, **{8 + k: "LcdKeyRow%d" % (k + 1) for k in range(5)},
           15: "ExitKey", 16: "PageKey", 18: "NumberPadKey", 21: "CompareKey"}
STUB, STUB_NAME = 0x00F42C70, "T_TableDefault_Ret"


def load():
    return open(PA, "rb").read().decode("latin-1").split("\n")


def index(L):
    at, label_at = {}, {}
    pend = []
    for i, l in enumerate(L):
        m = G.match(l)
        if m or re.match(r'^\.L[\w$]*:\s*$', l):
            if m:
                pend.append(m.group(1))
            continue
        mm = re.search(r';\s*([0-9A-F]{6})\b', l)
        code = l.split(";")[0].strip()
        if mm and code:
            a = int(mm.group(1), 16)
            at.setdefault(a, i)
            if pend:
                label_at.setdefault(a, pend[0])
            pend = []
    return at, label_at


def tables(L):
    out = []
    for i, l in enumerate(L):
        m = re.match(r'^(HandlerTable23_\w+):\s*$', l)
        if not m:
            continue
        bs, rows = [], []
        for k in range(i + 1, i + 12):
            mm = re.match(r'^\s*\.byte\s+([^;]+)', L[k])
            if not mm:
                break
            bs += [int(v, 0) for v in mm.group(1).split(",")]
            rows.append(k)
        if len(bs) != 92:
            continue
        vals = [bs[k] | bs[k + 1] << 8 | bs[k + 2] << 16 | bs[k + 3] << 24 for k in range(0, 92, 4)]
        base = int(re.search(r';\s*([0-9A-F]{6})', L[rows[0]]).group(1), 16)
        reader = None
        for j, x in enumerate(L):
            if re.search(r'\badd\s+XWA,%s\b' % m.group(1), x.split(";")[0]):
                k = j
                while not (G.match(L[k]) and not LOC.search(G.match(L[k]).group(1))):
                    k -= 1
                if "ToSlotAndFlags" in "\n".join(L[j - 6:j]):
                    reader = L[k].split(":")[0]
        out.append((m.group(1), base, rows, vals, reader))
    return out


# Screen 0x64's BUTTON method reads one of TWO tables: `cp (Variant_Flag),1 / jr nz` picks HandlerTable23_FA1CAB for
# variant 1 and HandlerTable23_FA1D10 otherwise.  Its header (notes/prom_a_system_menu_screens.py) gives the menu text:
# OVERALL TOUCH SENSITIVITY on variant 1 (SX-WSA1), TEST on variant 2 (SX-WSA1R).  So the two tables are two screens.
TABLE_SCREEN = {"HandlerTable23_FA1CAB": "OverallTouchSensitivity", "HandlerTable23_FA1D10": "SystemTest"}


def screen_of(r, t=None):
    if t in TABLE_SCREEN:
        return TABLE_SCREEN[t]
    m = re.match(r'^Screen_(\w+)_Button$', r or "")
    return m.group(1) if m else None


def plan(L):
    at, label_at = index(L)
    tabs = tables(L)
    where = collections.defaultdict(list)
    for t, _b, _r, vals, _rd in tabs:
        for k, v in enumerate(vals):
            if v != STUB:
                where[v].append((t, k))
    place, refused = {}, []
    for t, _b, _r, vals, rd in tabs:
        scr = screen_of(rd, t)
        for k, v in enumerate(vals):
            if v == STUB or v in label_at or v in place:
                continue
            slots = where[v]
            if not scr:
                refused.append((v, "%s: no Screen_<X>_Button reader" % t))
                continue
            if {tt for tt, _ in slots} != {t}:
                # the two variant tables of ONE screen sharing a handler at the same control slot: it is that
                # screen's handler on both models, named after the screen object (the reader), not a variant
                same = {kk for _tt, kk in slots}
                if {tt for tt, _ in slots} <= set(TABLE_SCREEN) and len(same) == 1 and same <= set(CONTROL):
                    place[v] = ("%s_%s" % (CONTROL[same.pop()], screen_of(rd)), t, [kk for _tt, kk in slots], rd)
                    continue
                refused.append((v, "in %d tables" % len({tt for tt, _ in slots})))
                continue
            ks = sorted(kk for _, kk in slots)
            if len(ks) == 1:
                if ks[0] not in CONTROL:
                    refused.append((v, "%s[%d] is not a mapped slot" % (t, ks[0])))
                    continue
                ctrl = CONTROL[ks[0]]
            elif all(kk < 8 for kk in ks) and ks == list(range(ks[0], ks[-1] + 1)):
                cols = [kk + 1 for kk in ks]
                ctrl = "SoftKeyCols%d_%d" % tuple(cols) if len(cols) == 2 else "SoftKeyCols%dto%d" % (cols[0], cols[-1])
            else:
                refused.append((v, "%s slots %s are not one control or one run of soft keys" % (t, ks)))
                continue
            if v not in at or not (0xF80000 <= v <= 0xFFFFFF):
                refused.append((v, "not the start of a prom_a code line"))
                continue
            place[v] = ("%s_%s" % (ctrl, scr), t, ks, rd)
    return tabs, place, refused, at, label_at


def apply(L, tabs, place, at, label_at):
    taken = set(re.findall(r'[A-Za-z_][\w$]*', "\n".join(L) + open(PB, "rb").read().decode("latin-1")))
    names = collections.Counter(n for n, _t, _k, _r in place.values())
    place = {v: p for v, p in place.items() if names[p[0]] == 1 and p[0] not in taken}
    name_of = dict(label_at)
    for v, (n, *_rest) in place.items():
        name_of[v] = n
    # 1. the tables (bottom-up so line numbers above stay valid), 2. the labels
    edits = []
    for t, base, rows, vals, rd in tabs:
        new = []
        for k, v in enumerate(vals):
            if v == STUB:
                op = STUB_NAME
            elif v in name_of:
                op = name_of[v]
            else:
                op = "0x%08X" % v
            new.append("\t.long %-40s ; %06X  [%2d]%s" % (op, base + 4 * k, k, ("  " + CONTROL[k]) if k in CONTROL else ""))
        edits.append((rows[0], rows[-1], new))
    for v, (n, t, ks, rd) in place.items():
        i = at[v]
        j = i
        while j > 0 and re.match(r'^\.L[\w$]*:\s*$', L[j - 1]):
            j -= 1
        hdr = ["; %s: %s slot%s %s, the 23-slot button table %s indexes through T_PanelCode_ToSlotAndFlags"
               % (n, t, "s" if len(ks) > 1 else "", ",".join(map(str, ks)), rd),
               ";   (notes/prom_a_handlertable23_convert.py)."]
        edits.append((j, j - 1, hdr + [n + ":"]))
    for lo, hi, new in sorted(edits, key=lambda e: e[0], reverse=True):
        L[lo:hi + 1] = new
    data = "\n".join(L).encode("latin-1")
    with open(PA + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(PA + ".tmp", PA)
    return len(place)


def main():
    L = load()
    tabs, place, refused, at, label_at = plan(L)
    if "--apply" in sys.argv:
        print("placed %d labels, rewrote %d tables" % (apply(L, tabs, place, at, label_at), len(tabs)))
        return
    for v, (n, t, ks, rd) in sorted(place.items()):
        print("0x%06X -> %-44s %s %s" % (v, n, t, ks))
    for v, why in refused:
        print("REFUSED 0x%06X: %s" % (v, why))
    print("tables %d, place %d, refused %d" % (len(tabs), len(place), len(refused)))


if __name__ == "__main__":
    main()
