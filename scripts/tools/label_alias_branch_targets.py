#!/usr/bin/env python3
"""label_alias_branch_targets.py -- positional aliases that name the start of a code line become labels.

QUESTION THIS ANSWERS / JOB IT DOES
  `.set SeMenu_Foo_0x1C, SeMenu_Foo + 28` used as `jr nz, SeMenu_Foo_0x1C` names a branch target
  by its distance from a label: it says nothing, and it silently goes wrong if a byte above it
  moves.  In v10 on 2026-10-02, 945 of the 1,266 positional aliases were branch targets at the
  start of a code line, and 68 more code addresses used as operands.  For each such alias
  (its address starts a CODE line, by the census marker mirror; every use is a branch or an
  operand) this places a real label in front of that line, named the way
  scripts/converters/symbolize_numeric_branches.py names the targets it creates --
  `<Parent>_<Role>[N]`: Parent the nearest non-structural code label above the target; Role
  from structure only: Helper (called, and it starts a routine of its own -- the code line
  before it is a ret/jump or a directive -- named `<first caller's routine>_Helper`), Return (the target is ret/reti/retd), Epilogue (only pops / frame drops
  until a ret), Sub (something calls it), Loop (a backward conditional branch reaches it),
  Join (an unconditional jump reaches it), Skip (only forward conditional branches), Code
  (only operands use it: an address loaded as a value) -- and retires the alias: its `.set`
  goes, every use (code and comments, the whole tree) takes the label.  Aliases of an address
  that already has a column-0 label retire into that label.  A label emits no byte: the
  branch displacements the assembler computes prove the placement, `make gate-all` the rest.

USAGE
  make all
  python3 scripts/tools/label_alias_branch_targets.py --tree v10 [--apply]
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
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import place_labels                           # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

SET = re.compile(r'^\s*\.(?:set|equ)\s+(\w+_0x[0-9A-Fa-f]+)\s*,\s*[A-Za-z_][\w.$]*\s*\+\s*(?:0x[0-9a-fA-F]+|\d+)\s*(?:;.*)?$')
BR = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*(jr|jrl|jp|call|calr|djnz)\s+(?:([a-z]+)\s*,\s*)?(?:[a-z]+\s*,\s*)?\(?([A-Za-z_][\w.$]*)', re.I)
COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')
RET = re.compile(r'^\s*(ret|reti|retd)\b', re.I)
TERM = re.compile(r'^(ret|reti|retd|halt)\b|^(jp|jr|jrl)\s+(t\s*,\s*)?[^,]+$', re.I)
POPS = re.compile(r'^\s*(pop\w*|inc\s+\d+\s*,\s*xsp|lda\s+xsp|ld\s+xsp|nop)\b', re.I)
CCS = {"f", "lt", "le", "ule", "ov", "mi", "z", "c", "ge", "gt", "ugt", "nov", "pl", "nz", "nc", "eq", "ne",
       "uge", "ult", "pe", "po"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src, _ = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)
    addr_of = {n: ad for ad, ns in syms.items() for n in ns}
    p = place_labels.Planner(a.tree)
    start_of = {(s[2], s[3]): s[0] for s in p.spans}
    files = sorted(glob.glob(os.path.join(p.srcroot, "**", "*.s"), recursive=True))
    rels = [os.path.relpath(f, p.srcroot) for f in files]
    col0 = set()
    aliases = {}
    for rel in rels:
        for l in p.lines(rel):
            m = COL0.match(l)
            if m:
                col0.add(m.group(1))
            m = SET.match(l)
            if m and m.group(1) in addr_of:
                aliases[m.group(1)] = addr_of[m.group(1)]
    pat = re.compile(r'(?<![\w.$])(%s)(?![\w$])' % "|".join(map(re.escape, sorted(aliases, key=len, reverse=True))))
    uses = collections.defaultdict(list)                # alias -> [(kind, cc, site addr)]
    callers = {}                                        # alias -> [(site addr, rel, li)] of calls

    def code_lines_back(L, li):
        for j in range(li - 1, -1, -1):
            c = L[j].split(";", 1)[0].strip()
            if c and not re.match(r'^[A-Za-z_][\w.$]*:$', c):
                yield j, re.sub(r'^[A-Za-z_][\w.$]*:\s*', '', c)

    def real_label_above(L, li):
        for j in range(li, -1, -1):
            m = COL0.match(L[j])
            if m and not fp.STRUCT.search(m.group(1)) and not m.group(1).startswith(("__", ".L")) and \
                    place_labels.snb.drc.classify_line(L[j], p.macros)[0] != "data":
                return m.group(1)
        return None
    for rel in rels:
        for li, l in enumerate(p.lines(rel)):
            if SET.match(l):
                continue
            code = l.split(";", 1)[0]
            for m in pat.finditer(code):
                b = BR.match(code)
                site = start_of.get((rel, li))
                if b and b.group(3) == m.group(1):
                    cc = (b.group(2) or "").lower()
                    uses[m.group(1)].append((b.group(1).lower(), cc if cc in CCS else "", site))
                    if b.group(1).lower() in ("call", "calr"):
                        callers.setdefault(m.group(1), []).append((site or 0, rel, li))
                elif re.match(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*\.', code):
                    uses[m.group(1)].append(("data", "", site))
                else:
                    uses[m.group(1)].append(("operand", "", site))
    st, by_addr = collections.Counter(), collections.defaultdict(list)
    for n, ad in aliases.items():
        u = uses.get(n)
        if not u or any(k == "data" for k, _, _ in u):
            st["unused or used by data: left"] += 1
            continue
        w = p.where(ad)
        if not w or w[0] != ad or place_labels.snb.drc.classify_line(p.lines(w[1])[w[2]], p.macros)[0] != "code":
            st["not the start of a code line: left"] += 1
            continue
        by_addr[ad].append(n)
    taken = set(addr_of)
    retire, new = {}, {}
    for ad, names in sorted(by_addr.items()):
        have = [x for x in syms.get(ad, []) if x in col0]
        if have:
            for n in names:
                retire[n] = fp.pick(have, col0)
            st["retired into an existing label"] += len(names)
            continue
        _, rel, li = p.where(ad)
        L = p.lines(rel)
        u = [x for n in names for x in uses[n]]
        tcode = L[li].split(";", 1)[0]
        prev = next(code_lines_back(L, li), (None, ""))[1]
        standalone = bool(TERM.match(prev)) or prev.startswith(".")
        called = sorted(c for n in names for c in callers.get(n, []))
        if called and standalone:
            role = "HELPER"
        elif RET.match(tcode):
            role = "Return"
        elif any(k in ("call", "calr") for k, _, _ in u):
            role = "Sub"
        elif any(k in ("jr", "jrl", "jp", "djnz") and (cc or k == "djnz") and s is not None and s > ad for k, cc, s in u):
            role = "Loop"
        elif all(k == "operand" for k, _, _ in u):
            role = "Code"
        else:
            role, j, seen = None, li, 0
            while j < len(L) and seen < 12:
                c = re.sub(r'^[A-Za-z_][\w.$]*:\s*', '', L[j].split(";", 1)[0].strip())
                if c:
                    seen += 1
                    if RET.match(c):
                        role = "Epilogue" if seen > 1 else "Return"
                        break
                    if not POPS.match(c):
                        break
                j += 1
            if role is None:
                role = "Join" if any(k in ("jr", "jrl", "jp") and not cc for k, cc, _ in u) else "Skip"
        if role == "HELPER":
            _, crel, cli = called[0]
            base = "%s_Helper" % (real_label_above(p.lines(crel), cli) or
                                  re.sub(r'\W', '_', os.path.splitext(os.path.basename(crel))[0]))
        else:
            parent = real_label_above(L, li)
            base = "%s_%s" % (parent or re.sub(r'\W', '_', os.path.splitext(os.path.basename(rel))[0]), role)
        nm, k = base, 1
        while nm in taken:
            k += 1
            nm = "%s%d" % (base, k)
        taken.add(nm)
        how = p.add(ad, nm)
        if how != "line-start":
            st["placement refused"] += 1
            continue
        new[ad] = nm
        for n in names:
            retire[n] = nm
        st["label placed: " + role] += 1
    st["aliases retired"] = len(retire)
    print("%s: %d positional aliases; %s%s" % (a.tree, len(aliases), dict(st), "" if a.apply else " (dry run)"))
    if a.apply and retire:
        p.apply()
        rp = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True))))
        for f in files + glob.glob(os.path.join(p.srcroot, "**", "*.c"), recursive=True) + \
                glob.glob(os.path.join(p.srcroot, "**", "*.ld"), recursive=True):
            t = open(f, "rb").read().decode("latin-1")
            L = [l for l in t.split("\n") if not (SET.match(l) and SET.match(l).group(1) in retire)]
            t2 = rp.sub(lambda q: retire[q.group(1)], "\n".join(L))
            if t2 != t:
                open(f, "wb").write(t2.encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
