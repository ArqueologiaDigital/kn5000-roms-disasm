#!/usr/bin/env python3
"""Name the unnamed entries of a button table from the screen its already-named entries give.

QUESTION IT ANSWERS
  Many screens' button tables are only partly named.  For example, Dispatch_FF4049[8] is
  LcdKeyRow1_L0adSingleS0und_Page0, but slots 0-7 are sub_.  A table index is a panel button code (32-slot
  tables, read through PanelButton_CallTableEntry / PanelButton_Route) or a PanelCode_ToSlotAndFlags slot
  (23-slot tables).  Dispatch_FF4049's header gives the code map: [00]..[07] soft-key columns 1-8, [08]..[0C] the
  LCD-row buttons, [0F] EXIT, [10] PAGE, [1B] the number pad, [1E] COMPARE, [0D] the -1/+1 pair, [0E] nothing,
  [11]..[18] the already-held forms (round 11).  A 23-slot table keeps 0..16 and moves 0x1A-0x1F to 17-22.
  So when every named <Control>_<Screen> entry of a table sits at its own control's slot and its soft-key / LCD-row
  entries name ONE screen (EXIT and PAGE handlers are often shared by a screen's pages and do not vote),
  each unnamed entry at a control slot is <Control>_<Screen> too.
  REFUSED: a table whose named entries disagree with their slots or name two screens; slots 0x0D, 0x0E and
  0x11-0x19 (and their 23-slot images); an entry that sits in two slots or two tables -- except the pair {k, k+0x11}
  of one 32-slot table, round 11's press and already-held forms of the same key; a name already taken.
  A run of 64, 96, ... `.long` under one label is split into 32-slot tables, each judged on its own entries.

RUN
  python3 notes/prom_ab_button_table_siblings.py          # the plan and the refusals
  python3 notes/prom_ab_button_table_siblings.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEXT = {k: open(os.path.join(ROOT, k, "wsa1_%s.s" % k), "rb").read().decode("latin-1") for k in ("prom_a", "prom_b")}
CTRL32 = {**{k: "SoftKeyCol%d" % (k + 1) for k in range(8)}, **{8 + k: "LcdKeyRow%d" % (k + 1) for k in range(5)},
          0x0F: "ExitKey", 0x10: "PageKey", 0x1B: "NumberPadKey", 0x1E: "CompareKey"}
CTRL23 = {(k if k <= 0x10 else k - 9): c for k, c in CTRL32.items()}
NAMED = re.compile(r'^(SoftKeyCol\d|LcdKeyRow\d|ExitKey|PageKey|NumberPadKey|CompareKey)_(\w+)$')
UNNAMED = re.compile(r'^sub_F[0-9A-F]{5}$')


def tables():
    """[(image, label, [entries])] for every run of 23 or 32 `.long` entries directly under a label."""
    out = []
    for img, text in TEXT.items():
        L = text.split("\n")
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):\s*(;.*)?$', l)
            if not m:
                continue
            ents = []
            for ll in L[i + 1:i + 400]:
                mm = re.match(r'^\s*\.long\s+([A-Za-z_]\w*)\b', ll)
                if mm:
                    ents.append(mm.group(1))
                elif ll.strip() and not ll.lstrip().startswith(";"):
                    break
            if len(ents) in (23, 32):
                out.append((img, m.group(1), ents))
            elif len(ents) > 32 and len(ents) % 32 == 0:
                # several 32-slot tables back to back under one label (Dispatch_FF4049 and the pages after it):
                # each chunk gets its screen from its own named entries
                for c in range(len(ents) // 32):
                    out.append((img, "%s+%d" % (m.group(1), 128 * c), ents[32 * c:32 * c + 32]))
    return out


def plan():
    tabs = tables()
    where = collections.defaultdict(set)
    for img, lab, ents in tabs:
        for k, e in enumerate(ents):
            where[e].add((lab, k))
    rows, refused = [], []
    for img, lab, ents in tabs:
        cmap = CTRL32 if len(ents) == 32 else CTRL23
        screens, bad = set(), False
        for k, e in enumerate(ents):
            m = NAMED.match(e)
            if not m:
                continue
            if cmap.get(k) != m.group(1):
                if (len(ents) == 32 and 0x11 <= k <= 0x18 and m.group(1) == CTRL32.get(k - 0x11)):
                    pass                    # the already-held form of the same key: consistent
                else:
                    bad = True
            if m.group(1).startswith(("SoftKeyCol", "LcdKeyRow")):
                screens.add(m.group(2))     # EXIT / PAGE handlers are often shared by a screen's pages (X_Pages0_1)
        if not screens:
            continue
        if bad or len(screens) != 1:
            refused.append((lab, "named entries disagree with their slots or name %s" % sorted(screens)))
            continue
        scr = screens.pop()
        for k, e in enumerate(ents):
            if not UNNAMED.match(e) or k not in cmap:
                continue
            slots = where[e]
            if not (len(slots) == 1 or (len(ents) == 32 and slots == {(lab, k), (lab, k + 0x11)})):
                refused.append((e, "in %d slots/tables" % len(slots)))
                continue
            new = "%s_%s" % (cmap[k], scr)
            rows.append((e, new, "%s: %s[%d] -- the %s handler of %s; the table's other named entries sit at their own\\n"
                         "  controls' slots and name the same screen (notes/prom_ab_button_table_siblings.py)." % (new, lab, k, cmap[k], scr)))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', TEXT["prom_a"] + TEXT["prom_b"]))
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
