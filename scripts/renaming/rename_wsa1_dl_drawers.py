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
  `sub_<ADDR>_*` sublabels), entered by a jump or by falling through.

  HISTORY: commit c0106cfa named 54 routines with two faults, corrected by the commit that brought
  this rule: it counted EVERY list operand as drawn (sub_F9315D became Draw_Drum, but DL_Drum is only
  the end bound of the list 0xF2BA16-0xF2BA20 it draws), and its first draft read the lines up to
  the next routine label instead of the reachable ones.

  A routine whose header records a reasoned refusal ("NOT NAMED because", "REFUSED to name" --
  wsa1/notes/prom_a_understanding_round7.py) is left alone: those reasons are about what a name
  would claim, and this rule cannot overturn them.  prom_b's generated headers above a renamed
  routine lose `The name IS the address.` and say what the name rests on (fix_headers()).

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
ADDR = re.compile(r'^[A-Za-z]+_[0-9A-F]{6}(__[0-9A-F]{6})?$')
LIST = re.compile(r'^(DL|DisplayList)_')
CALL = re.compile(r'^call\s+\w*DisplayList\w*_Run\w*$', re.I)
LOAD = r'^(?:ld|lda)\s+%s\s*,\s*\(?([A-Za-z_][\w.$]*)(?::24)?\)?$'
BACK = 8
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


def start_of(L, seen, k):
    """The START of the list the interpreter call at line k draws, or None if it does not resolve.
    Register form: XIY is the start, XIX the end (wsa1/notes/FINDINGS-ui-display-list.md), so the
    last `ld/lda xiy, SYM` above the call.  Stack form (`..._Stack`): the pushes go end first, start
    last (the 12-byte idiom `lda xbc,(END); push xbc; lda xwa,(START); push xwa`, as at 0xF9B30B;
    the one-pointer `RunOne_Stack` pushes only the start), so the register of the last `push` above
    the call, and the last load into that register above the push.  Only reachable lines, at most
    BACK of them, and a numeric operand or a branch in between gives None."""
    stack = "stack" in instr(L[k]).lower()
    want, j = (None if stack else "xiy"), k - 1
    while j >= 0 and k - j <= BACK and j in seen:
        c = instr(L[j])
        if c:
            if re.match(r'^(jp|jr|jrl|djnz|ret|call|calr)\b', c, re.I):
                return None
            if want is None:
                p = re.match(r'^push\s+(x[a-z]{2})$', c, re.I)
                if p:
                    want = p.group(1).lower()
            else:
                g = re.match(LOAD % want, c, re.I)
                if g:
                    return g.group(1)
                if re.match(r'^(?:ld|lda|pop|ex)\s+%s\b' % want, c, re.I):
                    return None
        j -= 1
    return None


def header(L, i):
    """The comment block directly above line i."""
    k, h = i - 1, []
    while k >= 0 and L[k].startswith(";"):
        h.append(L[k])
        k -= 1
    return "\n".join(reversed(h))


def fix_headers(path, drew):
    """Generated prom_b headers say `The name IS the address.` and `Unknown: what the routine is FOR.
    Left as sub_XXXXXX ...`; above a renamed routine both are false.  The first goes; the second
    becomes a statement of what the name rests on, and the purpose stays an open question."""
    L = open(path, "rb").read().decode("latin-1").split("\n")
    out, n = [], 0
    for i, l in enumerate(L):
        out.append(l)
    for i in range(len(out)):
        m = re.match(r'^(Draw_\w+):', out[i])
        if not m or m.group(1) not in drew:
            continue
        k = i - 1
        while k >= 0 and out[k] is not None and out[k].startswith(";"):
            if out[k].strip() == ";           The name IS the address.":
                out[k] = None
                n += 1
            elif out[k].startswith("; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,"):
                out[k] = ("; Name:    from the one text-named display list it STARTS, %s (the\n"
                          ";          interpreter's XIY or last-pushed operand); it claims that list, not\n"
                          ";          a screen or a purpose (scripts/renaming/rename_wsa1_dl_drawers.py).\n"
                          "; Unknown: what the routine is FOR." % drew[m.group(1)])
                if out[k + 1].strip() == ";          per this tree's rule that a stated gap beats a plausible guess.":
                    out[k + 1] = None
            k -= 1
    open(path, "wb").write("\n".join(x for x in out if x is not None).encode("latin-1"))
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(REPO, "wsa1", "**", "*.s"), recursive=True))
    taken, dlnames, ren, drew = set(), set(), {}, {}
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
            seen = reach(L, labels, i, m.group(1))
            calls = [k for k in sorted(seen) if CALL.match(instr(L[k]))]
            starts = [start_of(L, seen, k) for k in calls]
            if not starts or None in starts:
                continue
            if any(not LIST.match(d) for d in starts):
                if a.verbose:
                    print("  skip %s: non-list start %s" % (m.group(1), [d for d in starts if not LIST.match(d)]))
                continue
            dls = {d for d in starts if not ADDR.match(d)}
            if len(dls) != 1:
                continue
            if re.search(r'NOT NAMED because|REFUSED to name', header(L, i)):
                if a.verbose:
                    print("  skip %s: its header records a reasoned refusal to name it" % m.group(1))
                continue
            base = re.sub(r'_[0-9A-F]{6}$', '', LIST.sub('', list(dls)[0]))
            fam = re.match(r'^(\w+)_0$', base)
            if fam and "DL_%s_1" % fam.group(1) in dlnames:
                base = fam.group(1)
            nm, k = "Draw_" + base, 1
            while nm in taken:
                k += 1
                nm = "Draw_%s_%d" % (base, k)
            taken.add(nm)
            ren[m.group(1)] = nm
            drew[nm] = list(dls)[0]
            if a.verbose:
                print("  %s %s  starts %s" % (m.group(1), nm, " ".join(starts)))
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
        n = sum(fix_headers(os.path.join(REPO, f), drew) for f in ("wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"))
        print("%d generated headers corrected" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
