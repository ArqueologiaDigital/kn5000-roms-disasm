#!/usr/bin/env python3
"""Place prom_a labels at the targets of prom_b's 23-slot button tables that still point into prom_a by NUMBER.

QUESTION IT ANSWERS
  prom_b holds button tables for prom_a's COMBINATION screens (PtrTable_F1AEB5 ... PtrTable_F1B34D).  Their entries
  are `.long 0x00FBxxxx` with no label at the target, because nothing ever named those prom_a entry points, so
  the targets are unnamed routines that the sub_ count cannot even see.  Each table's own header says which
  prom_a instruction reads it ("base and width from prom_a 0x..."); that instruction sits in a named screen
  BUTTON method -- Screen_<X>_Button, ScreenButton_<X>, ScreenButtonBody_<X> -- that first calls
  T_PanelCode_ToSlotAndFlags, so the index is the 23-slot control slot (notes/prom_ab_slot23_button_names.py):
      0-7 SoftKeyCol1-8   8-12 LcdKeyRow1-5   15 ExitKey   16 PageKey   18 NumberPadKey   21 CompareKey
  Entry k of such a table is therefore <Control>_<Screen>, and the label is PLACED in prom_a at the target
  (scratch wsa1_place.py), after which scripts/converters/symbolize_wsa1_rom_addresses.py rewrites the prom_b
  `.long` to the name.
  A handler that fills several SOFT-KEY slots of one table is SoftKeyCols<a>_<b> (two keys) or SoftKeyCols<a>to<b>
  (a run of keys) _<Screen>.
  REFUSED: a slot outside the map; a target that occurs in two tables, or in two slots that are not all soft keys; a target with a label already
  (the symbolizer handles it); a target that is not the start of a code line in prom_a; a taken name; a reader
  that is not a named screen button method or does not call T_PanelCode_ToSlotAndFlags.

RUN
  python3 notes/prom_ab_promb_slot23_targets.py          # the plan
  python3 notes/prom_ab_promb_slot23_targets.py --args   # 'ADDR=Name|header' for wsa1_place.py
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1").split("\n")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1").split("\n")
G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop)\d*$')
CONTROL = {**{k: "SoftKeyCol%d" % (k + 1) for k in range(8)}, **{8 + k: "LcdKeyRow%d" % (k + 1) for k in range(5)},
           15: "ExitKey", 16: "PageKey", 18: "NumberPadKey", 21: "CompareKey"}


def prom_a_lines():
    at, labelled = {}, set()
    pend = []
    for i, l in enumerate(A):
        m = G.match(l)
        if m:
            pend.append(m.group(1))
            continue
        mm = re.search(r';\s*([0-9A-F]{6})\s', l)
        if mm and l.split(";")[0].strip() and not l.split(";")[0].strip().startswith(".L"):
            a = int(mm.group(1), 16)
            at.setdefault(a, i)
            if pend:
                labelled.add(a)
            pend = []
    return at, labelled


def screen_of(name):
    for rx in (r'^Screen_(\w+)_Button$', r'^ScreenButtonBody_(\w+)$', r'^ScreenButton_(\w+)$'):
        m = re.match(rx, name or "")
        if m:
            return m.group(1)
    return None


def plan():
    at, labelled = prom_a_lines()
    tables, hdr = [], None
    for i, l in enumerate(B):
        m = re.search(r'base and width from prom_a 0x([0-9A-F]{6})', l)
        if m:
            hdr = int(m.group(1), 16)
        mm = G.match(l)
        if mm and hdr is not None:
            ents = []
            for x in B[i + 1:i + 30]:
                e = re.match(r'^\s*\.long\s+(\S+)', x)
                if e:
                    ents.append(e.group(1))
                    if len(ents) == 23:
                        break
                elif x.strip() and not x.startswith(";"):
                    break
            tables.append((mm.group(1), hdr, ents))
            hdr = None
    where = collections.defaultdict(list)
    for t, _h, ents in tables:
        for k, e in enumerate(ents):
            where[e.lower()].append((t, k))
    rows, refused = [], []
    for t, h, ents in tables:
        if h not in at:
            continue
        j = at[h]
        while j > 0 and not (G.match(A[j]) and not LOC.search(G.match(A[j]).group(1))):
            j -= 1
        reader = A[j].split(":")[0]
        scr = screen_of(reader)
        if not any(e.lower().startswith("0x00f") for e in ents):
            continue
        if not scr or "ToSlotAndFlags" not in "\n".join(A[at[h] - 12:at[h]]) or len(ents) != 23:
            refused.append((t, "reader %s is not a 23-slot screen button method" % reader))
            continue
        for k, e in enumerate(ents):
            m = re.match(r'^0x00(F[89A-F][0-9A-F]{4})$', e, re.I)
            if not m:
                continue
            a = int(m.group(1), 16)
            if k not in CONTROL:
                refused.append(("0x%06X" % a, "%s[%d] is not a mapped control slot" % (t, k)))
                continue
            slots = where[e.lower()]
            if len(slots) > 1:
                ks = sorted(kk for tt, kk in slots)
                # one handler on several SOFT KEYS of the same table: SoftKeyCols<a>_<b> for two, <a>to<b> for a run
                # (the spelling of SoftKeyCols3_4_L0adSingleS0und_Page0 / SoftKeyCols2to7_CreatorSelectController)
                if {tt for tt, kk in slots} == {t} and all(kk < 8 for kk in ks):
                    if k != ks[0]:
                        continue
                    cols = [kk + 1 for kk in ks]
                    if len(cols) == 2:
                        ctrl = "SoftKeyCols%d_%d" % tuple(cols)
                    elif cols == list(range(cols[0], cols[-1] + 1)):
                        ctrl = "SoftKeyCols%dto%d" % (cols[0], cols[-1])
                    else:
                        refused.append(("0x%06X" % a, "soft keys %s are not a run" % cols))
                        continue
                    if a in labelled or a not in at:
                        refused.append(("0x%06X" % a, "labelled already, or not a code line start"))
                        continue
                    new = "%s_%s" % (ctrl, scr)
                    rows.append((a, new, "%s: %s slots %s, the 23-slot button table %s reads through T_PanelCode_ToSlotAndFlags --\\n"
                                 "  one handler for soft keys %s of %s (notes/prom_ab_promb_slot23_targets.py)." % (
                                     new, t, ks, reader, ", ".join(map(str, cols)), scr)))
                    continue
                refused.append(("0x%06X" % a, "in %d slots/tables" % len(slots)))
                continue
            if a in labelled:
                refused.append(("0x%06X" % a, "already labelled -- the symbolizer's job"))
                continue
            if a not in at:
                refused.append(("0x%06X" % a, "not the start of a prom_a code line"))
                continue
            new = "%s_%s" % (CONTROL[k], scr)
            rows.append((a, new, "%s: %s[%d], the 23-slot button table %s reads through T_PanelCode_ToSlotAndFlags -- the\\n"
                         "  %s handler of %s (notes/prom_ab_promb_slot23_targets.py)." % (new, t, k, reader, CONTROL[k], scr)))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', "\n".join(A + B)))
    news = [n for _a, n, _h in rows]
    for a, n, h in rows:
        bad = news.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%06X=%s|%s" % (a, n, h))
        else:
            print("0x%06X -> %s%s" % (a, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("place %d, refused %d" % (sum(1 for _a, n, _h in rows if not (news.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
