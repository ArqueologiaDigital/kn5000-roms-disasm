#!/usr/bin/env python3
"""Find -- and with --apply remove -- prom_a `sub_<ADDR>` labels that nothing references and that code falls into.

QUESTION IT ANSWERS
  In this tree `sub_<ADDR>` is the house name of an unnamed ROUTINE.  scripts/renaming/rename_wsa1_branch_only_subs.py
  (2026-10-02) gave structural names to the ones reached only by branches.  It left the ones reached by NOTHING:
  about 140 labels in prom_a whose name occurs in no code line of any WSA1 source, and whose previous code line
  FALLS THROUGH into them.  They came from earlier passes' seeds -- a "reachable-run entry", an older build's call
  target (FINDINGS-prom_b-f00c4d-orphan-cluster.md N2: "an orphan label no prom_a line references -- very likely
  planted by an earlier pass"), an address-shaped immediate.  Each one splits a routine in two, so the text
  after it reads as an unnamed routine that does not exist, and it is counted as one.  Precedent: the declared
  removals "a stray mid-routine label, removed" in notes/prom_a_preservation_check.py (sub_FD27BA and others).

  A label is a candidate only when ALL of these hold, each one checked here:
    1. it is `sub_F<5 hex>` and no CODE line of prom_a, prom_b, prom_c or a *.ld names it (comments are text, not
       references);
    2. the previous code line falls through: not ret / reti / retd / an unconditional jp / jr / jrl, not a data
       directive, not a label;
    3. its address does not occur as a 24-bit little-endian value anywhere in the three ROM images (a pointer
       to it in data -- decoded or not -- would make it an entry);
    4. it is not the target of a prom_b thunk slot (`T_...: jp sub_...`) -- covered by 1, re-asserted.
  REMOVAL replaces the label line with a comment that says what was there and why it went, and keeps any
  comment that was on the label line.  The removal is declared in notes/prom_a_preservation_check.py as
  old -> the routine that now covers the address (the nearest routine label above), as the precedent does.

RUN
  python3 notes/prom_a_stray_label_removal.py           # the list, with the reason each one qualifies
  python3 notes/prom_a_stray_label_removal.py --apply   # remove them and declare the removals
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
ROMS = {"prom_a": ("wsa1_prom_a.ic12", 0xF80000), "prom_b": ("wsa1_prom_b.ic13", 0xF00000), "prom_c": ("wsa1_prom_c.ic28", 0xF80000)}
G = re.compile(r'^([A-Za-z_.][\w$.]*):')
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop|Arm|Case\d*)\d*$')
FALLS_NOT = re.compile(r'^(ret|reti|retd\b.*|jp (?:t, )?\(?\w+\)?|jr (?:t, )?\w+|jrl (?:t, )?\w+|jp \(x\w+\))$', re.I)


def code_tokens():
    seen = {}
    paths = [os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")]
    paths += glob.glob(os.path.join(ROOT, "prom_c", "**", "*.s"), recursive=True)
    paths += glob.glob(os.path.join(ROOT, "**", "*.ld"), recursive=True)
    for p in paths:
        for l in open(p, "rb").read().decode("latin-1").split("\n"):
            c = l.split(";")[0]
            c = re.sub(r'^\s*[A-Za-z_.][\w$.]*:', '', c)      # a definition is not a reference
            for w in re.findall(r'[A-Za-z_][\w$]*', c):
                seen[w] = seen.get(w, 0) + 1
    return seen


def rom_pointers():
    hits = set()
    for img, (f, base) in ROMS.items():
        b = open(os.path.join(ROOT, "original_ROMs", f), "rb").read()
        for i in range(len(b) - 2):
            if b[i + 2] in (0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF):
                hits.add(b[i] | b[i + 1] << 8 | b[i + 2] << 16)
    return hits


def plan():
    L = open(PA, "rb").read().decode("latin-1").split("\n")
    refs, ptrs = code_tokens(), rom_pointers()
    out, refused = [], []
    for i, l in enumerate(L):
        m = re.match(r'^(sub_F([0-9A-F]{5})):', l)
        if not m:
            continue
        name, addr = m.group(1), int("F" + m.group(2), 16)
        if refs.get(name):
            continue
        j = i - 1
        while j > 0 and (not L[j].split(";")[0].strip()):
            j -= 1
        prev = re.sub(r'\s+', ' ', L[j].split(";")[0]).strip()
        if G.match(prev) or prev.startswith("."):
            refused.append((name, "previous line is a label or directive: %s" % prev[:40]))
            continue
        if FALLS_NOT.match(prev):
            refused.append((name, "previous line does not fall through: %s" % prev[:40]))
            continue
        if addr in ptrs:
            refused.append((name, "0x%06X occurs as a 24-bit value in a ROM image" % addr))
            continue
        k = i - 1
        parent = None
        while k >= 0:
            mm = G.match(L[k])
            if mm and not mm.group(1).startswith(".") and not STRUCT.search(mm.group(1)):
                parent = mm.group(1)
                break
            k -= 1
        out.append((i, name, addr, parent, prev))
    # a candidate whose parent is itself a candidate maps to that candidate's parent
    cand = {n: p for _i, n, _a, p, _pv in out}
    fixed = []
    for i, n, a, p, pv in out:
        while p in cand:
            p = cand[p]
        fixed.append((i, n, a, p, pv))
    return L, fixed, refused


def apply(L, rows):
    rows = sorted(rows, reverse=True)
    for i, n, a, p, _pv in rows:
        tail = L[i].split(";", 1)[1].strip() if ";" in L[i] else ""
        L[i] = "; (%s removed 2026-10-04: no code names it and the line above falls through into it -- part of %s;\n" \
               ";  notes/prom_a_stray_label_removal.py)%s" % (n, p, ("  [was: " + tail + "]") if tail else "")
    data = "\n".join(L).encode("latin-1")             # encode before opening for write
    with open(PA + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(PA + ".tmp", PA)
    chk = os.path.join(ROOT, "notes", "prom_a_preservation_check.py")
    s = open(chk, "rb").read().decode("utf-8")
    anchor = "\n}\n\n\ndef _renames():"
    add = "".join('\n    "%s": "%s",   # 2026-10-04: a stray mid-routine label, removed (notes/prom_a_stray_label_removal.py)'
                  % (n, p) for _i, n, _a, p, _pv in sorted(rows))
    s = s.replace(anchor, add + anchor)
    data = s.encode("utf-8")
    with open(chk + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(chk + ".tmp", chk)


def main():
    L, rows, refused = plan()
    if "--apply" in sys.argv:
        apply(L, rows)
        print("removed %d" % len(rows))
        return
    for _i, n, a, p, pv in rows:
        print("%-12s in %-40s after: %s" % (n, p, pv[:40]))
    for n, why in refused:
        print("REFUSED %s: %s" % (n, why))
    print("remove %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
