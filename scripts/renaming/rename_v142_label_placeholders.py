#!/usr/bin/env python3
r"""rename_v142_label_placeholders.py -- give the sub-CPU v1.42 `LABEL_XXXXXX` branch targets
structural names in the house style of scripts/converters/symbolize_numeric_branches.py.

QUESTION THIS ANSWERS
    kn5000_subprogram_v142.s still defines `LABEL_<address>` placeholders.  All of them are
    targets of jr/jrl/jp only (no call reaches them).  The project policy puts address-derived
    names last, so which structural name should each one get?

NAMING (structural facts only, the same rules the branch symboliser uses)
    * a `jr`/`jrl` on the line directly above that targets the label (a jump to the next
      instruction, used as a timing delay) -> `__jrt_nop_<ADDR>`, the name the file already
      uses for its 507 other such delays;
    * otherwise `<Parent>_<Role>`, where
        Role   = Return   if the target instruction is ret/retd/reti,
                 Loop     if a BACKWARD conditional branch reaches it (source address > target),
                 Epilogue if only pops / frame drops come before a ret,
                 Join     if some source is an unconditional jr/jrl/jp,
                 Skip     otherwise (only forward conditional branches reach it);
        Parent = the nearest label above that is not LABEL_*, __* or .L*, with a trailing
                 structural suffix (_Skip, _Join, _Loop, _Return, _Epilogue, _Entry, _Sub,
                 with an optional number) removed;
      and a number is appended when the name is already taken.
    The addresses used for "backward" come from scripts/analysis/v142_line_map.py (a fresh,
    byte-identity-guarded map of this tree).

RUN
    python3 scripts/renaming/rename_v142_label_placeholders.py           # dry: list
    python3 scripts/renaming/rename_v142_label_placeholders.py --apply   # then make gate
    python3 scripts/renaming/rename_v142_label_placeholders.py --map     # old=new, for the comment gate
"""
import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import v142_line_map as lm  # noqa: E402

F = "kn5000_subprogram_v142.s"
P = os.path.join(ROOT, "v142/subcpu", F)
LAB = re.compile(r"^([A-Za-z_.$][\w.$]*):")
BR = re.compile(r"^\s*(jr|jrl|jp|djnz)\s+(?:([a-z]+)\s*,\s*)?(?:[\w]+\s*,\s*)?(LABEL_[0-9A-F]{6})\s*$", re.I)
RET = re.compile(r"^\s*(ret|retd|reti)\b", re.I)
POP = re.compile(r"^\s*(pop|popw|inc\s+\d+\s*,\s*xsp|lda\s+xsp|popw_erp|\.byte\s+0x4)", re.I)
SUFFIX = re.compile(r"_(Skip|Join|Loop|Return|Epilogue|Entry|Sub)\d*$")
CC = {"t", ""}


def code(s):
    return s.split(";")[0].rstrip()


def build():
    L = open(P, "rb").read().decode("latin-1").split("\n")
    amap = lm.line_map()
    addr_of = {i: a for (f, i), a in amap.items() if f == F}
    defs = {}
    for i, ln in enumerate(L):
        m = LAB.match(ln)
        if m and m.group(1).startswith("LABEL_"):
            defs[m.group(1)] = i
    srcs = collections.defaultdict(list)
    for i, ln in enumerate(L):
        c = code(ln)
        for m in re.finditer(r"\b(LABEL_[0-9A-F]{6})\b", c):
            if LAB.match(c) and LAB.match(c).group(1) == m.group(1):
                continue
            mm = re.match(r"^\s*(\w+)\s+(.*)$", c)
            mn = mm.group(1).lower() if mm else ""
            ops = [o.strip().lower() for o in (mm.group(2).split(",") if mm else [])]
            cc = ops[0] if len(ops) == 2 else ""
            srcs[m.group(1)].append((i, mn, cc))
    taken = set()
    for ln in L:
        m = LAB.match(ln)
        if m:
            taken.add(m.group(1))
    plan = {}
    for name, di in sorted(defs.items(), key=lambda x: x[1]):
        # first emitting line at/after the label
        t = di
        while t < len(L) and t not in addr_of:
            t += 1
        tgt = addr_of.get(t)
        # previous non-blank, non-comment line
        p = di - 1
        while p >= 0 and (not L[p].strip() or L[p].lstrip().startswith(";")):
            p -= 1
        prevc = code(L[p]).strip().lower()
        if re.match(r"^(jr|jrl)\s+%s$" % name.lower(), prevc):
            plan[name] = "__jrt_nop_" + name[6:]
            continue
        ss = srcs.get(name, [])
        tc = code(L[t]).strip() if t < len(L) else ""
        if RET.match(tc):
            role = "Return"
        elif any(addr_of.get(i, -1) > tgt and cc not in CC for i, mn, cc in ss):
            role = "Loop"
        else:
            role = None
            j, seen = t, 0
            while j < len(L) and seen < 12:
                c = code(L[j]).strip()
                if c and not LAB.match(c):
                    seen += 1
                    if RET.match(c):
                        role = "Epilogue" if seen > 1 else "Return"
                        break
                    if not POP.match(c):
                        break
                j += 1
            if role is None:
                role = "Join" if any(mn in ("jr", "jrl", "jp") and cc in CC for i, mn, cc in ss) else "Skip"
        k = di - 1
        parent = None
        while k >= 0:
            m = LAB.match(L[k])
            if m and not m.group(1).startswith(("LABEL_", "__", ".L")):
                parent = SUFFIX.sub("", m.group(1))
                break
            k -= 1
        base = "%s_%s" % (parent, role)
        new, n = base, 1
        while new in taken:
            n += 1
            new = "%s%d" % (base, n)
        taken.add(new)
        plan[name] = new
    return L, plan


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--map", action="store_true")
    a = ap.parse_args()
    L, plan = build()
    if a.map:
        for o, n in plan.items():
            print("%s=%s" % (o, n))
        return
    kinds = collections.Counter(re.sub(r"^.*_(\w+?)\d*$", r"\1", n) if not n.startswith("__") else "__jrt_nop"
                                for n in plan.values())
    print("placeholders: %d  %s" % (len(plan), dict(kinds)))
    pat = re.compile(r"\b(LABEL_[0-9A-F]{6})\b")
    out = [pat.sub(lambda m: plan.get(m.group(1), m.group(1)), ln) for ln in L]
    if not a.apply:
        for o, n in list(plan.items())[:400]:
            print("  %s -> %s" % (o, n))
        return
    open(P, "wb").write("\n".join(out).encode("latin-1"))
    print("rewrote", F)


if __name__ == "__main__":
    main()
