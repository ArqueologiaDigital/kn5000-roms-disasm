#!/usr/bin/env python3
"""Label the sound editor's per-switch handlers by the LCD control that reaches them, and spell their tables.

QUESTION IT ANSWERS / WHAT IT DOES
  Each sound-editor title's SeXxxTitleFunc_SwitchHandlers table (kn5000_v*_program.s) is indexed by
  SeTitle_DecodeSwitch:
      index 0..7   switch 0..7 (or 17..24, bank bit 7 set)  -- the eight LCD COLUMNS: GetEditSwPoint puts
                   switches 0..7 at x = 20, 60 .. 300 on the bottom row; a column's two buttons share the
                   number, the second one adding bit 7 (the panel code posts xiz, then xiz | 0x80)
      index 8..12  switch 8..12 (0x88..0x8C bank)           -- the side ROWS 1..5: GetEditSwPoint puts
                   8..12 on the right edge (x = 319) and 0x88..0x8C on the left (x = 0), rows y = 0x2B..0xD3
      index 13..15 switch 13..15, index 16 switch 25        -- buttons not identified here
  Most entries were spelled `Owner+0xNN`, an unlabelled instruction start inside a reframed routine, and 14
  tables were still 72-byte slices of a compiled-C .incbin (one .long per slot replaces the slice).  For
  one maincpu tree this script places a label at each such target and spells every entry by its label:
      <Page>_OnColumn<n>  (n = index + 1),  <Page>_OnSideRow<n>  (n = index - 7),  <Page>_OnSwitch<n>
  <Page> is the title without `TitleFunc` (SeAmpEnv1).  A target several slots share is named by its first
  slot and carries a comment listing the others; a target that already has a label keeps it.
  The names say which control reaches the handler, not which parameter it edits.

RUN (repository root; build the census map of this exact tree first)
  python3 scripts/analysis/dispatch_table_census/build_maps.py
  python3 scripts/tools/name_semenu_switch_handlers.py v10 --dry-run
  python3 scripts/tools/name_semenu_switch_handlers.py v10          # then make all: byte-identical
"""
import collections
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
ARGS = sys.argv[1:]
sys.argv = sys.argv[:1]
import census  # noqa: E402

TREE_DIR = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu"}


def slot_name(page, k):
    if k <= 7:
        return "%s_OnColumn%d" % (page, k + 1)
    if k <= 12:
        return "%s_OnSideRow%d" % (page, k - 7)
    return "%s_OnSwitch%d" % (page, 25 if k == 16 else k)


def main():
    key = ARGS[0]
    dry = "--dry-run" in ARGS
    m = census.load(key)
    rows = m["rows"]
    prog = "kn5000_%s_program.s" % key
    in_use = set(m["byname"]) | {r[7] for r in rows if r[7]}
    planned = {}                # address -> (name, [slots])
    respell = []                # (row index, new text)
    incbin_tables = []          # (row index, lines) for tables still held as an .incbin slice
    for i, r in enumerate(rows):
        lab = r[7]
        if not (lab and re.match(r'^Se\w+TitleFunc_SwitchHandlers$', lab) and r[2] == prog):
            continue
        page = lab[:-len("TitleFunc_SwitchHandlers")]
        if r[5] == ".incbin":
            # the table is still a slice of a compiled-C .incbin: one .long per 4 bytes, labels as below
            words = [(r[0] + 4 * x, census.le(m, r[0] + 4 * x, 4)) for x in range((r[1] - r[0]) // 4)]
            assert (r[1] - r[0]) % 4 == 0, lab
            lines = []
            for k, (at, val) in enumerate(words):
                if val == 0:
                    lines.append("\t.long 0")
                    continue
                cls, _ = census.classify(key, val) if census.owner(key, val) else ("none", "")
                if cls == "nolabel":
                    if val not in planned:
                        nm = slot_name(page, k)
                        assert nm not in in_use, nm
                        in_use.add(nm)
                        planned[val] = [nm, [k]]
                    else:
                        planned[val][1].append(k)
                    lines.append(("@@", val))
                else:
                    rr = census.find(m, val)
                    lines.append("\t.long %s" % (rr[7] if rr and rr[0] == val and rr[7] else "0x%08x" % val))
            incbin_tables.append((i, lines))
            continue
        k = 0
        j = i
        while j < len(rows) and rows[j][2] == prog and rows[j][5] == ".long" and (j == i or not rows[j][7]):
            ops = census.operands(rows[j][6])
            if len(ops) != 1:
                break
            val = census.le(m, rows[j][0], 4)
            if val == 0:
                break
            cls, _ = census.classify(key, val) if census.owner(key, val) else ("none", "")
            if cls == "nolabel":
                if val not in planned:
                    nm = slot_name(page, k)
                    assert nm not in in_use, nm
                    in_use.add(nm)
                    planned[val] = [nm, [k]]
                else:
                    planned[val][1].append(k)
            respell.append((j, val))
            j += 1
            k += 1
    # spell every entry by its (existing or planned) label
    edits = collections.defaultdict(list)
    for j, val in respell:
        r = rows[j]
        lab = planned[val][0] if val in planned else None
        if lab is None:
            rr = census.find(m, val)
            lab = rr[7] if rr and rr[0] == val and rr[7] else None
        if lab is None:
            continue
        edits[r[2]].append((r[3], r[3], ["\t.long %s" % lab]))
    for i, lines in incbin_tables:
        r = rows[i]
        out = [x if isinstance(x, str) else "\t.long %s" % planned[x[1]][0] for x in lines]
        edits[r[2]].append((r[3], r[3], out))
    for val, (nm, slots) in planned.items():
        rr = census.find(m, val)
        note = "" if len(slots) == 1 else "\t; slots %s" % ", ".join(str(s) for s in slots)
        edits[rr[2]].append((rr[3], rr[3] - 1, [nm + ":" + note]))
    print("%s: %d handler labels placed, %d table entries spelled" % (key, len(planned),
          sum(len(v) for f, v in edits.items() if f == prog)))
    if dry:
        for val, (nm, slots) in sorted(planned.items())[:20]:
            print("  %06X %-34s slots %s" % (val, nm, slots))
        return
    root = os.path.join(REPO, TREE_DIR[key])
    for rel, ops in edits.items():
        p = os.path.join(root, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        floor = None
        for a, b, new in sorted(ops, key=lambda x: (-x[0], -(x[1] - x[0]))):
            assert floor is None or b < floor, (rel, a, b)
            if b >= a:
                lead = re.match(r'^([A-Za-z_.$][\w.$@]*:)', L[a])
                L[a:b + 1] = ([lead.group(1)] if lead else []) + new
            else:
                L[a:a] = new
            floor = a
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
