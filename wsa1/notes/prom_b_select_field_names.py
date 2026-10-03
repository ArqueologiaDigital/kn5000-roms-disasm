#!/usr/bin/env python3
"""Name the routines that only select field N of a sequencer-job screen: <Screen>_SelectFieldN.

QUESTION IT ANSWERS
  Each sequencer job screen keeps its cursor in one RAM byte that the tree already names
  <Screen>_Field (MeasureInsert_Field, MeasureC0py_Field, N0teChange_Field, ...; its readers are the
  screen's LcdKeyRow / SoftKeyCol handlers and its DrawFieldCursor).  A routine whose whole body is
      store the constant N into <Screen>_Field   (`ld (F:16), N`, or `ld a, N` + `ld (F:16), a`)
      [mirror A into DisplayListB_Stage+k]        (the display stage the paint reads)
      `or (UI_RequestBits), mask` ...             (request the redraw)
      ret
  does nothing but move that screen's cursor to field N, which is what the tree's existing
  MeasureDelete_SelectField1-3, MeasureErase_SelectField1-4, Quantize_SelectField1-4 and
  TrackMerge_SelectField1-3 already say about the identical bodies on their (numbered) cells.
  Renamed: every still-unnamed `sub_` of that shape.  REFUSED: a cell that is not a <Screen>_Field
  equate, a body with any other instruction, and a (screen, N) reached by two routines.

RUN
  python3 notes/prom_b_select_field_names.py          # the plan and the refusals
  python3 notes/prom_b_select_field_names.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")]


def bodies():
    for f in FILES:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        starts = [(i, m.group(1)) for i, l in enumerate(L) for m in [re.match(r'^([A-Za-z_][\w$]*):', l)] if m]
        for k, (i, name) in enumerate(starts):
            j = starts[k + 1][0] if k + 1 < len(starts) else len(L)
            body = [re.sub(r'\s+', ' ', l.split(";")[0].strip()) for l in L[i + 1:j]]
            yield name, [b for b in body if b]


def select_field(body):
    """(screen, N) when body is exactly a select-field routine, else None."""
    if not body or body[-1] != "ret":
        return None
    cell, n, a = None, None, None
    for b in body[:-1]:
        if re.match(r'^m_or_mi8 MB16, UI_RequestBits, 0x[0-9a-f]+$', b):
            continue
        if re.match(r'^ld \(DisplayListB_Stage\+\d+:16\), a$', b) and a is not None:
            continue
        m = re.match(r'^ld a, (\d+)(?::opc)?$', b)
        if m and a is None:
            a = int(m.group(1))
            continue
        m = re.match(r'^ld \((\w+)_Field:16\), (\d+|a)$', b)
        if m and cell is None:
            cell = m.group(1)
            n = a if m.group(2) == "a" else int(m.group(2))
            continue
        return None
    return (cell, n) if cell and n is not None else None


def plan():
    hits = collections.defaultdict(list)
    for name, body in bodies():
        sf = select_field(body)
        if sf and re.match(r'^sub_F[0-9A-F]{5}$', name):
            hits[sf].append(name)
    rows, refused = [], []
    for (scr, n), names in sorted(hits.items()):
        if len(names) != 1:
            refused.append((", ".join(names), "two routines select %s field %d" % (scr, n)))
            continue
        new = "%s_SelectField%d" % (scr, n)
        rows.append((names[0], new, "%s: moves the %s screen's cursor to field %d -- stores %d into %s_Field\\n"
                     "  and requests the redraw, nothing else (notes/prom_b_select_field_names.py)." % (new, scr, n, n, scr)))
    return rows, refused


def main():
    rows, refused = plan()
    text = "\n".join(open(f, "rb").read().decode("latin-1") for f in FILES)
    taken = set(re.findall(r'[A-Za-z_][\w$]*', text))
    for o, n, h in rows:
        if "--args" in sys.argv:
            if n not in taken:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-12s -> %s%s" % (o, n, "  NAME TAKEN" if n in taken else ""))
    if "--args" not in sys.argv:
        for t, why in refused:
            print("REFUSED %s: %s" % (t, why))
        print("rename %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
