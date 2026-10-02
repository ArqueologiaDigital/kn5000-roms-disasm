#!/usr/bin/env python3
"""rename_wsa1_branch_only_subs.py -- WSA1 `sub_<ADDR>` labels that are branch targets inside a routine get structural names.

QUESTION THIS ANSWERS / JOB IT DOES
  In the WSA1 trees `sub_<ADDR>` is the house name of an unnamed ROUTINE.  But 437 prom_b and 55
  prom_a `sub_` labels (2026-10-02) are reached ONLY by jumps / branches -- never called, never
  in a table -- and many sit in the middle of straight-line code: `jr nz, sub_F80CED` where
  sub_F80CED is the enclosing routine's `ret`.  Those are not routines; the trees already name
  such targets `<routine>_Return` (sub_F0003C_Return).  For each jump-only `sub_` label whose
  previous code line FALLS THROUGH into it (not a ret / unconditional jump / directive -- a
  target after a terminator may be a routine entered by a tail jump, and keeps its name), this
  renames it `<Parent>_<Role>[N]`: Parent the nearest label above that names a routine (a
  `sub_<ADDR>` or a non-structural name); Role from structure only, as
  scripts/converters/symbolize_numeric_branches.py: Return (the target is ret/reti/retd), Loop
  (a backward conditional branch reaches it), Join (an unconditional jump reaches it), Skip
  (only forward conditional branches).  Directions come from the census marker mirror.  The
  renames go through scripts/renaming/rename_wsa1_branch_only_subs_<image>.sed over wsa1/.
  Labels emit no byte: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/renaming/rename_wsa1_branch_only_subs.py --image prom_b [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels                           # noqa: E402

SUB = re.compile(r'^(sub_[0-9A-F]{6}):')
COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')
PAT = re.compile(r'(?<![\w.$])(sub_[0-9A-F]{6})(?![\w$])')
BR = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*(jp|jr|jrl|djnz|call|calr)\s+(?:([a-z]+)\s*,\s*)?(?:[a-z]+\s*,\s*)?(\S+)', re.I)
TERM = re.compile(r'^(ret|reti|retd|halt)\b|^(jp|jr|jrl)\s+(t\s*,\s*)?[^,]+$', re.I)
RET = re.compile(r'^(ret|reti|retd)\b', re.I)
STRUCTURAL = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Entry|Tail|Next|Done|Exit|End|Code|Data|Block|Sub|Case|Default)\d*$|^\.L|^loc_|^LABEL_')
CCS = {"f", "lt", "le", "ule", "ov", "mi", "z", "c", "ge", "gt", "ugt", "nov", "pl", "nz", "nc", "eq", "ne"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=("prom_a", "prom_b", "prom_c"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    p = place_labels.Planner(a.image)
    start_of = {(s[2], s[3]): s[0] for s in p.spans}
    own = a.image + "/"
    files = sorted(glob.glob(os.path.join(REPO, "wsa1", "**", "*.s"), recursive=True))
    rels = [os.path.relpath(f, os.path.join(REPO, "wsa1")) for f in files]
    taken, where = set(), {}
    for rel in rels:
        for i, l in enumerate(p.lines(rel)):
            m = COL0.match(l)
            if m:
                taken.add(m.group(1))
                if rel.startswith(own) and SUB.match(l):
                    where[m.group(1)] = (rel, i)
    uses = collections.defaultdict(list)
    for rel in rels:
        for i, l in enumerate(p.lines(rel)):
            code = l.split(";", 1)[0]
            for m in PAT.finditer(code):
                n = m.group(1)
                if n not in where or code.startswith(n + ":"):
                    continue
                b = BR.match(code)
                kind = "other"
                if b and b.group(3).strip("()") == n:
                    kind = b.group(1).lower()
                elif re.match(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*[a-z]', code):
                    kind = "operand"
                cc = (b.group(2) or "").lower() if b else ""
                uses[n].append((kind, cc if cc in CCS else "", start_of.get((rel, i))))
    st, ren = collections.Counter(), {}
    for n, (rel, i) in sorted(where.items(), key=lambda kv: kv[1]):
        u = uses.get(n, [])
        if not u or any(k not in ("jp", "jr", "jrl", "djnz") for k, _, _ in u):
            continue
        L = p.lines(rel)
        prev = None
        for j in range(i - 1, -1, -1):
            c = re.sub(r'^[A-Za-z_][\w.$]*:\s*', '', L[j].split(";", 1)[0].strip())
            if c:
                prev = c
                break
        if prev is None or prev.startswith(".") or TERM.match(prev):
            st["after a terminator / directive: kept"] += 1
            continue
        tgt = start_of.get((rel, i + 1)) or start_of.get((rel, i))
        body = next((re.sub(r'^[A-Za-z_][\w.$]*:\s*', '', L[j].split(";", 1)[0].strip()) for j in range(i, min(i + 4, len(L)))
                     if re.sub(r'^[A-Za-z_][\w.$]*:\s*', '', L[j].split(";", 1)[0].strip())), "")
        if RET.match(body):
            role = "Return"
        elif tgt is not None and any(cc and s is not None and s > tgt for _, cc, s in u):
            role = "Loop"
        elif any(k in ("jp", "jr", "jrl") and not cc for k, cc, _ in u):
            role = "Join"
        else:
            role = "Skip"
        parent = None
        for j in range(i - 1, -1, -1):
            m = COL0.match(L[j])
            if m and (SUB.match(L[j]) or not STRUCTURAL.search(m.group(1))) and m.group(1) not in ren:
                parent = m.group(1)
                break
        if not parent:
            st["no parent: kept"] += 1
            continue
        base = "%s_%s" % (parent, role)
        nm, k = base, 1
        while nm in taken:
            k += 1
            nm = "%s%d" % (base, k)
        taken.add(nm)
        ren[n] = nm
        st[role] += 1
    print("%s: %d sub_ labels; %s%s" % (a.image, len(where), dict(st), "" if a.apply else " (dry run)"))
    if a.apply and ren:
        sed = os.path.join(REPO, "scripts", "renaming", "rename_wsa1_branch_only_subs_%s.sed" % a.image)
        with open(sed, "w") as s:
            s.write("# generated by scripts/renaming/rename_wsa1_branch_only_subs.py: jump-only sub_<ADDR> labels\n"
                    "# inside a routine -> <routine>_<Return|Loop|Join|Skip>.\n")
            for old, new in sorted(ren.items(), key=lambda kv: -len(kv[0])):
                s.write("s/\\b%s\\b/%s/g\n" % (old, new))
        subprocess.run(["sed", "-i", "-f", sed] + files, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
