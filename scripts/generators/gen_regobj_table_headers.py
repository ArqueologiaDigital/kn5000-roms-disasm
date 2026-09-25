#!/usr/bin/env python3
r"""Evidence headers for the object tables the Initialize* routines register.

QUESTION ANSWERED
    InitializeSuna / InitializeYoko / InitializeKubo / InitializeEast (and the
    other Initialize* routines) register NAKA object tables with the macros
    RegObjTable (count read from a u16 in memory) and RegObjTabl (immediate
    count):  `RegObjTabl <class>, <class proc>, <count>, <table>, <id>`.
    Many of those tables live in this lane's ui_widgets/naka_*.s and
    widget_dispatch.s files, typed but with no statement of who reads them.
    This script finds every registration whose table (or count word) lies in
    one of those files and writes, directly above the table's label, which
    routine registers it, the class and its proc, the entry count and the id.
    A table start with no label gets one: <Module>_<Class>Table_<id>
    (<Module> = the routine name without "Initialize").

    v10 and v9 spell the registrations with the macros, so they are parsed
    from the source.  v7 does not (it holds the same sequences as plain
    instructions): there a header is written only where the v10 label exists
    in v7 and v7's own code names the v7 address of that label as a 24-bit
    operand -- the header then cites v10's registration and the v7 site.

    Class procs: 0x1600004 ClassProc, 0x160000C ResEventProc, 0x160000D
    ResMethodProc, 0x1600002 ApFunctionProc, 0x1600001 FunctionProc,
    0x1600003 MainFunctionProc, 0x1600010 ViewableProc, 0x160000F ResNameProc
    (the procs the macros name, ELF-resolved).

RUN
    python3 scripts/generators/gen_regobj_table_headers.py --check     # list, change nothing
    python3 scripts/generators/gen_regobj_table_headers.py --apply v10 v9 v7
    python3 scripts/generators/gen_regobj_table_headers.py --v7-new [--apply v7]   # after a rebuild
    make gate
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000
TAG = "; Registered by "
FILES = ["ui_widgets/naka_property_descriptors.s", "ui_widgets/naka_direct_play_property_tables.s",
         "ui_widgets/naka_direct_play_dispatch.s", "ui_widgets/naka_effects_eq_dispatch.s",
         "ui_widgets/naka_screen_dispatch.s", "ui_widgets/naka_sound_technichord_dispatch.s",
         "ui_widgets/widget_dispatch.s"]
SHORT = {"ClassProc": "Class", "ResEventProc": "ResEvent", "ResMethodProc": "ResMethod",
         "ApFunctionProc": "ApFunction", "FunctionProc": "Function", "MainFunctionProc": "MainFunction",
         "ViewableProc": "Viewable", "ResNameProc": "ResName"}
MAC = re.compile(r"^\s*(RegObjTable|RegObjTabl)\s+(.+?)\s*$")
LAB = re.compile(r"^([A-Za-z_.$][\w.$]*):")


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def syms(v):
    out = subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    by_name, by_addr = {}, collections.defaultdict(list)
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3:
            by_name[p[2]] = int(p[0], 16)
            if p[1] == "t":
                by_addr[int(p[0], 16)].append(p[2])
    return by_name, by_addr


def num(x, names):
    x = x.strip()
    try:
        return int(x, 0)
    except ValueError:
        return names.get(x)


def registrations(v, names):
    regs = []
    for f in sorted(glob.glob(os.path.join(ROOT, v, "maincpu", "**", "*.s"), recursive=True)):
        rel = os.path.relpath(f, os.path.join(ROOT, v, "maincpu"))
        cur = None
        for n, ln in enumerate(open(f, encoding="latin-1"), 1):
            m = LAB.match(ln)
            if m:
                cur = m.group(1)
            m = MAC.match(ln.split(";")[0])
            if not m or not ln.startswith("\t"):
                continue
            args = [a.strip() for a in m.group(2).split(",")]
            if len(args) != 5:
                continue
            cls, proc, cnt, tab, rid = args
            procv = num(proc, names)
            regs.append(dict(macro=m.group(1), args=", ".join(args), cls=int(cls, 0), proc=proc, procv=procv,
                             cnt=cnt, cntv=num(cnt, names), tab=num(tab, names), id=int(rid, 0),
                             routine=cur, where="%s:%d" % (rel, n)))
    return regs


def line_map(v, rel):
    with tempfile.TemporaryDirectory() as td:
        out = os.path.join(td, "m.json")
        subprocess.run([sys.executable, os.path.join(ROOT, "scripts/analysis/file_line_addresses.py"),
                        "--image", v, "--file", rel, "--json", out], check=True, capture_output=True)
        return json.load(open(out))


def proc_name(r, by_addr):
    if r["proc"] in SHORT:
        return r["proc"]
    for n in by_addr.get(r["procv"], []):
        if n in SHORT:
            return n
    return r["proc"]


def plan(v, regs, names, by_addr, d):
    """-> {rel: [(addr, kind, reg, count)]} for targets inside the lane files"""
    maps = {rel: line_map(v, rel) for rel in FILES}
    spans = {rel: (min(e["addr"] for e in m), max(e["addr"] + len(e["bytes"]) // 2 for e in m))
             for rel, m in maps.items() if m}
    out = collections.defaultdict(list)
    for r in regs:
        pn = proc_name(r, by_addr)
        if r["macro"] == "RegObjTable":
            count = int.from_bytes(d[r["cntv"] - B:r["cntv"] - B + 2], "little")
        else:
            count = r["cntv"]
        for kind, a in (("table", r["tab"]), ("count", r["cntv"] if r["macro"] == "RegObjTable" else None)):
            if a is None:
                continue
            for rel, (lo, hi) in spans.items():
                if lo <= a < hi:
                    out[rel].append((a, kind, r, count, pn))
    return out, maps


def header(kind, r, count, pn, a):
    mod = r["routine"][len("Initialize"):] if r["routine"].startswith("Initialize") else r["routine"]
    if kind == "table":
        src = ("count word at 0x%06X" % r["cntv"]) if r["macro"] == "RegObjTable" else "immediate count"
        return ["%s%s (%s): `%s %s`" % (TAG, r["routine"], r["where"], r["macro"], r["args"]),
                "; = class 0x%X (%s), %d entries (%s), id 0x%X." % (r["cls"], pn, count, src, r["id"])], \
            "%s_%sTable_%X" % (mod, SHORT.get(pn, "Obj"), r["id"])
    return ["%s%s (%s): `%s %s`" % (TAG, r["routine"], r["where"], r["macro"], r["args"]),
            "; = u16 %d, the entry count of that class 0x%X (%s) table, read with `ldw_da`." % (
                count, r["cls"], pn)], "%s_%sCount_%X" % (mod, SHORT.get(pn, "Obj"), r["id"])


def edit_file(path, targets, lm, names, dry):
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    first = {}
    for e in lm:
        first.setdefault(e["addr"], e["line"])
    ins = collections.defaultdict(list)     # line index -> lines to insert before it
    report = []
    done_addr = set()
    for a, kind, r, count, pn in sorted(targets, key=lambda t: (t[0], t[1])):
        hdr, newlab = header(kind, r, count, pn, a)
        if a not in first:
            report.append((a, kind, None, hdr, False, r["where"]))
            continue
        ln = first[a]            # 1-based line of the byte-emitting line
        k = ln - 1
        labels = []
        j = k - 1
        while j >= 0 and (not lines[j].strip() or lines[j].lstrip().startswith(";") or LAB.match(lines[j])):
            if LAB.match(lines[j]) and not lines[j].startswith(("\t", " ")):
                code = lines[j].split(":", 1)[1].split(";")[0].strip()
                if code:
                    break
                labels.append(j)
            j -= 1
        # a label line that also carries the data (`Lab:\t.long ...`) is the line itself
        m = LAB.match(lines[k])
        if m:
            at = k
            lab = m.group(1)
        elif labels:
            at = min(labels)
            lab = LAB.match(lines[at]).group(1)
        else:
            at = k
            lab = None
        if any(l.startswith(TAG) for l in ins[at]) and (a, kind) in done_addr:
            continue
        # already headed (by an earlier run or a converter): leave it
        jj = at - 1
        while jj >= 0 and lines[jj].lstrip().startswith(";"):
            if lines[jj].startswith(TAG):
                break
            jj -= 1
        if jj >= 0 and lines[jj].startswith(TAG):
            continue
        done_addr.add((a, kind))
        if lab is None:
            if newlab in names:
                newlab += "_T"
            ins[at] += hdr + ["%s:" % newlab]
            names[newlab] = a
            report.append((a, kind, newlab, hdr, True, r["where"]))
        else:
            ins[at] += hdr
            report.append((a, kind, lab, hdr, False, r["where"]))
    if not dry:
        out = []
        for i, l in enumerate(lines):
            out.extend(ins.get(i, []))
            out.append(l)
        open(path, "wb").write("\n".join(out).encode("latin-1"))
    return report


def v7_apply(items, dry):
    """items: {rel: [(label, hdr)]} headed on EXISTING labels in v10."""
    names7, _ = syms("v7")
    d7 = rom("v7")
    for rel, its in sorted(items.items()):
        path = os.path.join(ROOT, "v7", "maincpu", rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        idx = {}
        for i, l in enumerate(lines):
            m = LAB.match(l)
            if m:
                idx.setdefault(m.group(1), i)
        ins = collections.defaultdict(list)
        n = 0
        for lab, hdr in its:
            if lab not in names7 or lab not in idx:
                continue
            a7 = names7[lab]
            pat, i, sites = a7.to_bytes(3, "little"), 0, []
            while True:
                i = d7.find(pat, i + 1)
                if i < 0:
                    break
                if B + i >= 0xEF0000:
                    sites.append(B + i)
            if not sites:
                continue
            ins[idx[lab]] += [hdr[0].replace(TAG, "; Registered in v10 by ", 1), hdr[1],
                              "; v7 names this label's address (0x%06X) as a 24-bit operand at %s." % (
                                  a7, ", ".join("0x%06X" % x for x in sites[:3]))]
            n += 1
        print(" v7 %s: %d labels headed" % (rel, n))
        if not dry and n:
            if any(l.startswith("; Registered in v10 by ") for l in lines):
                raise SystemExit("%s already has registration headers" % path)
            out = []
            for i, l in enumerate(lines):
                out.extend(ins.get(i, []))
                out.append(l)
            open(path, "wb").write("\n".join(out).encode("latin-1"))


def run(v, apply_it):
    names, by_addr = syms(v)
    d = rom(v)
    regs = registrations(v, names)
    targets, maps = plan(v, regs, names, by_addr, d)
    print("%s: %d registrations parsed, %d targets in lane files" % (
        v, len(regs), sum(len(t) for t in targets.values())))
    headed = collections.defaultdict(list)
    for rel, t in sorted(targets.items()):
        path = os.path.join(ROOT, v, "maincpu", rel)
        rep = edit_file(path, t, maps[rel], dict(names), not apply_it)
        print(" %s" % rel)
        for (a, kind, lab, hdr, new, where) in rep:
            print("  0x%06X %-5s %-40s %s" % (a, kind, (("NEW " if new else "") + lab) if lab else
                                             "(not a line start: skipped)", where))
            if lab and not new:
                headed[rel].append((lab, hdr))
    return headed


def v7_new_labels(apply_it):
    """Labels this script CREATED in v10 (<Module>_<Class>Table/Count_<id>) that v7 lacks:
    add them to v7 where a v7 line starts at the same address and v7 code names
    that address as a 24-bit operand (the v7 registration site)."""
    names10, _ = syms("v10")
    names7, _ = syms("v7")
    d7 = rom("v7")
    pat_lab = re.compile(r"^((?:Suna|Yoko|Kubo|East)_[A-Za-z]+(?:Table|Count)_[0-9A-F]+):\s*$")
    for rel in FILES:
        p10 = os.path.join(ROOT, "v10", "maincpu", rel)
        l10 = open(p10, "rb").read().decode("latin-1").split("\n")
        want = []
        for i, l in enumerate(l10):
            m = pat_lab.match(l)
            if m and m.group(1) not in names7:
                j = i - 1
                hdr = []
                while j >= 0 and l10[j].startswith(";"):
                    hdr.insert(0, l10[j])
                    j -= 1
                hdr = [h for h in hdr if h.startswith(TAG) or h.startswith("; = ")]
                want.append((m.group(1), names10[m.group(1)], hdr))
        if not want:
            continue
        lm = line_map("v7", rel)
        first = {}
        for e in lm:
            first.setdefault(e["addr"], e["line"])
        p7 = os.path.join(ROOT, "v7", "maincpu", rel)
        lines = open(p7, "rb").read().decode("latin-1").split("\n")
        ins = collections.defaultdict(list)
        for lab, a, hdr in want:
            pat, i, sites = a.to_bytes(3, "little"), 0, []
            while True:
                i = d7.find(pat, i + 1)
                if i < 0:
                    break
                if B + i >= 0xEF0000:
                    sites.append(B + i)
            if a not in first or not sites:
                print("  v7 %s: %s (0x%06X) not added -- %s" % (
                    rel, lab, a, "no line start" if a not in first else "no v7 operand"))
                continue
            k = first[a] - 1
            ins[k] += [hdr[0].replace(TAG, "; Registered in v10 by ", 1)] + hdr[1:] + [
                "; v7 names this address as a 24-bit operand at %s." % ", ".join("0x%06X" % x for x in sites[:3]),
                "%s:" % lab]
            print("  v7 %s: %s at 0x%06X" % (rel, lab, a))
        if apply_it and ins:
            out = []
            for i, l in enumerate(lines):
                out.extend(ins.get(i, []))
                out.append(l)
            open(p7, "wb").write("\n".join(out).encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", nargs="+")
    ap.add_argument("--v7-new", action="store_true",
                    help="only: add to v7 the labels this script created in v10 (see v7_new_labels)")
    a = ap.parse_args()
    if a.v7_new:
        v7_new_labels(bool(a.apply))
        return 0
    todo = a.apply or []
    h10 = run("v10", "v10" in todo)
    if "v9" in todo or not todo:
        run("v9", "v9" in todo)
    if "v7" in todo or not todo:
        v7_apply(h10, "v7" not in todo)
    return 0


if __name__ == "__main__":
    sys.exit(main())
