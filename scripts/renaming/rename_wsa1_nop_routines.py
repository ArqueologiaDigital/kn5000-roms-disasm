#!/usr/bin/env python3
"""rename_wsa1_nop_routines.py -- WSA1 `sub_<ADDR>` entries that are a lone `ret` are named for what reaches them.

QUESTION THIS ANSWERS / JOB IT DOES
  692 WSA1 `sub_<ADDR>` labels (prom_a 445, prom_b 247 on 2026-10-03) head an entry whose FIRST
  instruction is `ret`: entered there, the routine does nothing.  Their headers still say
  "Unknown: what the routine is FOR".  The purpose IS known -- none -- and what matters is who
  reaches the empty entry.  Each becomes, by its first referrer of the first kind found:
    `<slot>_Nop`        a routine-directory thunk `T_F4001C: jp sub_X` jumps to it (prom_b's
                        directory, also for prom_a targets it names through `.set`);
    `<Table>_Nop<k>`    entry k of a `.long` table (Table = the column-0 label above it);
    `<Routine>_Nop`     a call / calr / jump reaches it (Routine = the nearest routine label
                        above that site: a `sub_` or a non-structural name);
  unreferenced ones keep their name.  Labels that continue after the `ret` (`sub_X_Join`) are
  separate entries and keep theirs.  The header's "Unknown: what the routine is for/FOR ..."
  paragraph is replaced by one saying the entry is a lone ret.  Renames go through
  scripts/renaming/rename_wsa1_nop_routines.sed over wsa1/**/*.s.  No byte changes:
  `make gate-all`.

USAGE
  python3 scripts/renaming/rename_wsa1_nop_routines.py [--apply]
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
SUB = re.compile(r'^(sub_[0-9A-F]{6}):')
COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')
PAT = re.compile(r'(?<![\w.$])(sub_[0-9A-F]{6})(?![\w$])')
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Entry|Tail|Code|Data|Sub|Case|Default|Nop)\d*$|^\.L|^loc_')
UNKNOWN = re.compile(r'^; Unknown: what the routine is (for|FOR)\b')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(REPO, "wsa1", "**", "*.s"), recursive=True))
    texts = {f: open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    taken, nops = set(), {}
    for f, L in texts.items():
        for i, l in enumerate(L):
            m = COL0.match(l)
            if m:
                taken.add(m.group(1))
            m = SUB.match(l)
            if m:
                j = i + 1
                while j < len(L) and not L[j].split(";")[0].strip():
                    j += 1
                if j < len(L) and L[j].split(";")[0].strip() == "ret":
                    nops[m.group(1)] = (f, i)
    refs = collections.defaultdict(list)                # name -> [(kind, owner)]
    for f, L in texts.items():
        table, k = None, 0
        routine = None
        for i, l in enumerate(L):
            m = COL0.match(l)
            if m:
                if SUB.match(l) or not STRUCT.search(m.group(1)):
                    routine = m.group(1)
                table, k = m.group(1), 0
            code = l.split(";", 1)[0]
            body = re.sub(r'^[A-Za-z_][\w.$]*:\s*', '', code).strip()
            for mm in PAT.finditer(code):
                n = mm.group(1)
                if n not in nops or code.startswith(n + ":"):
                    continue
                lab = COL0.match(l)
                if re.match(r'^jp\b', body, re.I) and lab and lab.group(1).startswith("T_"):
                    refs[n].append(("slot", lab.group(1)))
                elif body.startswith(".long"):
                    refs[n].append(("table", "%s_Nop%d" % (table, k)))
                elif re.match(r'^(call|calr|jp|jr|jrl)\b', body, re.I) and routine:
                    refs[n].append(("call", routine))
            if body.startswith(".long"):
                k += len([x for x in body[5:].split(",") if x.strip()])
    ren, st = {}, collections.Counter()
    for n in sorted(nops):
        r = refs.get(n, [])
        pick = next((x for kind in ("slot", "table", "call") for x in r if x[0] == kind), None)
        if not pick:
            st["unreferenced: kept"] += 1
            continue
        kind, owner = pick
        base = owner + "_Nop" if kind in ("slot", "call") else owner
        if owner in nops or owner == n:
            st["referrer is itself unnamed: kept"] += 1
            continue
        nm, c = base, 1
        while nm in taken:
            c += 1
            nm = "%s%d" % (base, c)
        taken.add(nm)
        ren[n] = nm
        st[kind] += 1
    print("%d lone-ret sub_ entries; %s%s" % (len(nops), dict(st), "" if a.apply else " (dry run)"))
    if a.apply and ren:
        hdr = 0
        for n, nm in ren.items():
            f, i = nops[n]
            L = texts[f]
            j = i - 1
            dashes = 0
            while j >= 0 and j > i - 40 and not UNKNOWN.match(L[j]):
                if L[j].startswith("; -----"):
                    dashes += 1                 # the closing rule right above the label is
                    if dashes == 2:             # the header's END; its start is the second
                        break
                j -= 1
            if j >= 0 and UNKNOWN.match(L[j]):
                e = j + 1
                while e < i and L[e].startswith(";          "):
                    e += 1
                L[j:e] = ["; Purpose: none -- the entry is a lone `ret`.  Named %s after what reaches it" % nm,
                          ";          (scripts/renaming/rename_wsa1_nop_routines.py, 2026-10-03)."]
                hdr += 1
        for f, L in texts.items():
            open(f, "wb").write("\n".join(L).encode("latin-1"))
        sed = os.path.join(REPO, "scripts", "renaming", "rename_wsa1_nop_routines.sed")
        with open(sed, "w") as s:
            s.write("# generated by scripts/renaming/rename_wsa1_nop_routines.py: lone-ret sub_ entries.\n")
            for old, new in sorted(ren.items()):
                s.write("s/\\b%s\\b/%s/g\n" % (old, new))
        subprocess.run(["sed", "-i", "-f", sed] + files, check=True)
        print("headers rewritten: %d" % hdr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
