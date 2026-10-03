#!/usr/bin/env python3
"""rename_wsa1_dl_drawers.py -- WSA1 `sub_<ADDR>` routines whose own code runs exactly one named display list become Draw_<List>.

QUESTION THIS ANSWERS / JOB IT DOES
  A WSA1 display list (`DL_<Name>`) is named from the text it puts on the screen
  (wsa1/notes/prom_b_dl_screens_round5.py).  A `sub_` routine that runs a display-list interpreter
  (`T_DisplayList*_Run*`) and whose code names exactly ONE such list draws that screen -- a bare
  `DL_F3BD07` is unnamed and does not count; `DL_MidiOutFilter_F190E9` is text-named (the suffix
  only makes a repeated caption unique) and does, so a routine that also names it is skipped; whatever else it does, that much
  is a fact read off its code.  It becomes `Draw_<List>` (the list's name without `DL_` and
  without an address suffix; a family
  base `DL_X_0` with a sibling `DL_X_1` gives `Draw_X`), unique with _2, ...

  "Its code" is what is REACHABLE from the entry through the source's symbolic control flow, not
  the lines up to the next label: ret / reti / retd and unconditional jumps end a path,
  conditional branches and djnz take both edges, calls fall through, an indirect jump ends the
  path, and a path stops at any other routine's label (anything but `.L*` and the routine's own
  `sub_<ADDR>_*` sublabels), entered by a jump or by falling through.  A first pass that took the
  lines up to the next routine label named 56 routines; 14 of those found their list only past a
  `ret`, where it may belong to an unlabelled neighbour -- this rule decides those by reachability.

  The routine's sublabels `sub_<ADDR>_Join` ... take the new prefix.  Renames go through
  scripts/renaming/rename_wsa1_dl_drawers.sed over wsa1/**/*.s and wsa1/**/*.ld -- prom_a/prom_a.ld
  defines prom_b routines prom_a calls PC-relatively (scripts/tools/link_prom_a_to_prom_b.py), so
  a prom_b rename must reach it.  Prose and generators under wsa1/notes and notes/promb-2026-09-25
  that quote the old names take the same sed (--notes); the lane worklists (JSON snapshots of
  2026-10-02) keep them.  No byte changes.

USAGE
  python3 scripts/renaming/rename_wsa1_dl_drawers.py [--apply] [--verbose]
"""
import argparse
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
ADDR = re.compile(r'^DL_[0-9A-F]{6}$')
LABEL = re.compile(r'^([.\w$]+):\s*(.*)$')
NOTES = ["wsa1/notes/*.py", "wsa1/notes/*.md", "notes/promb-2026-09-25/*.py", "notes/promb-2026-09-25/*.md"]
NEVER = {"f"}
ALWAYS = {"t"}


def instr(line):
    """(text without label/comment) of a source line."""
    c = line.split(";")[0]
    m = LABEL.match(c)
    if m:
        c = m.group(2)
    return c.strip()


def reach(L, labels, entry, name):
    """indices of the lines reachable from `entry` within routine `name` (see docstring)."""
    def own(lab):
        return lab.startswith(".L") or lab.startswith(name + "_")

    seen, todo = set(), [entry + 1]
    while todo:
        k = todo.pop()
        while 0 <= k < len(L) and k not in seen:
            m = LABEL.match(L[k].split(";")[0])
            if m and not own(m.group(1)):
                break
            seen.add(k)
            c = instr(L[k])
            if not c:
                k += 1
                continue
            mn, _, ops = c.partition(" ")
            mn = mn.strip().lower()
            ops = [o.strip() for o in ops.split(",")] if ops.strip() else []
            if mn in ("reti", "retd", "halt") or (mn == "ret" and not ops):
                break
            if mn in ("jp", "jr", "jrl", "djnz"):
                cc = ops[0].lower() if len(ops) == 2 and mn != "djnz" else None
                tgt = ops[-1] if ops else ""
                if cc in NEVER:
                    k += 1
                    continue
                if tgt in labels and own(tgt):
                    todo.append(labels[tgt])
                if mn == "djnz" or (cc is not None and cc not in ALWAYS):
                    k += 1
                    continue
                break
            k += 1
    return seen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(REPO, "wsa1", "**", "*.s"), recursive=True))
    taken, dlnames, ren = set(), set(), {}
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_][\w.$]*):', l)
            if m:
                taken.add(m.group(1))
                if m.group(1).startswith("DL_"):
                    dlnames.add(m.group(1))
    for f in ("wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"):
        L = open(os.path.join(REPO, f), "rb").read().decode("latin-1").split("\n")
        labels = {}
        for i, l in enumerate(L):
            m = LABEL.match(l.split(";")[0])
            if m:
                labels[m.group(1)] = i
        for i, l in enumerate(L):
            m = re.match(r'^(sub_[0-9A-F]{6}):', l)
            if not m:
                continue
            body = [instr(L[k]) for k in sorted(reach(L, labels, i, m.group(1)))]
            dls = {d for d in re.findall(r'\b(DL_[A-Za-z]\w*)\b', " ".join(body)) if not ADDR.search(d)}
            if len(dls) != 1 or not any(re.search(r'DisplayList\w*_Run', b) for b in body):
                continue
            base = re.sub(r'_[0-9A-F]{6}$', '', list(dls)[0][3:])
            fam = re.match(r'^(\w+)_0$', base)
            if fam and "DL_%s_1" % fam.group(1) in dlnames:
                base = fam.group(1)
            nm, k = "Draw_" + base, 1
            while nm in taken:
                k += 1
                nm = "Draw_%s_%d" % (base, k)
            taken.add(nm)
            ren[m.group(1)] = nm
            if a.verbose:
                print("  %s %s  (%d reachable lines)" % (m.group(1), nm, len(body)))
    print("%d routines%s" % (len(ren), "" if a.apply else " (dry run)"))
    if a.apply and ren:
        sed = os.path.join(REPO, "scripts", "renaming", "rename_wsa1_dl_drawers.sed")
        with open(sed, "w") as s:
            s.write("# generated by scripts/renaming/rename_wsa1_dl_drawers.py: routines that draw one named display list.\n")
            for old, new in sorted(ren.items()):
                s.write("s/\\b%s_/%s_/g\n" % (old, new))
                s.write("s/\\b%s\\b/%s/g\n" % (old, new))
        lds = sorted(glob.glob(os.path.join(REPO, "wsa1", "**", "*.ld"), recursive=True))
        notes = sorted(p for g in NOTES for p in glob.glob(os.path.join(REPO, g)))
        subprocess.run(["sed", "-i", "-f", sed] + files + lds + notes, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
