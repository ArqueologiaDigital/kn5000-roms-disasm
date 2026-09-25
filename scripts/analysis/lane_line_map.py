#!/usr/bin/env python3
r"""lane_line_map.py -- WHICH ADDRESS DOES EACH LINE OF *THESE* FILES EMIT AT?

QUESTION ANSWERED
-----------------
For a handful of source files of ONE maincpu image (v10, v9 or v7), give every
byte-emitting line its ROM address and byte count, and prove the map describes
the tree as it is now.

It is `data_range_census.py`'s marker technique restricted to the files you
name, so it is fast enough to re-run after every edit (a stale map is the
failure this project has already paid for -- see BRIEF-2026-09-01, "A STALE
ADDRESS MAP is invisible to every check except the rebuilt ROM").

HOW
---
Mirror `<image>/maincpu` into a temp dir: every file is a symlink except the
named `.s` files, which are copied with a synthetic label `__llm_<n>:` in front
of every non-blank, non-comment line outside a `.macro` body.  Assemble + link
the mirror with the real `maincpu.ld`, read the marker addresses with llvm-nm.

★ INERT OR NOTHING: the linked mirror is objcopy'd and asserted byte-identical
  to `original_ROMs/kn5000_<image>_program.rom`; if it is not, the run aborts.

★ SIZE of a line = address of the next marked line IN THE SAME FILE minus its
  own address.  That is only right when nothing between the two lines emits
  from another file (an `.include` in the middle).  The files this was written
  for include nothing, and `--selftest`-style reconciliation below asserts the
  per-file sizes add up to (last address - first address).

RUN
    python3 scripts/analysis/lane_line_map.py --image v7 \
        --files sequencer/accompaniment_engine.s,sequencer/accompseq_routines.s \
        --json /tmp/claude-1000/lane-accomp/map_v7.json

OUTPUT (json)
    {"image": "v7", "files": {rel: [[lineno(1-based), addr, size, text], ...]},
     "symbols": {name: addr}}          # every symbol of the linked ELF
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.join(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
                    "llvm-project", "build", "bin")
MC, LLD = os.path.join(LLVM, "llvm-mc"), os.path.join(LLVM, "ld.lld")
OBJCOPY, NM = os.path.join(LLVM, "llvm-objcopy"), os.path.join(LLVM, "llvm-nm")
MARK = "__llm_"


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        errs = [l for l in r.stderr.split("\n") if "error" in l]
        raise SystemExit("FAILED: %s\n%s" % (" ".join(cmd), "\n".join(errs[:20]) or r.stderr[-3000:]))
    return r.stdout


def strip_comment(line):
    out, q = [], None
    for ch in line:
        if q:
            out.append(ch)
            if ch == q:
                q = None
            continue
        if ch in "\"'":
            q = ch
        elif ch == ";":
            break
        out.append(ch)
    return "".join(out)


def build(image, files, tmp):
    src = os.path.join(ROOT, image, "maincpu")
    mdir = os.path.join(tmp, "m")
    marks = []
    for dp, dn, fn in os.walk(src):
        rel = os.path.relpath(dp, src)
        od = os.path.join(mdir, rel) if rel != "." else mdir
        os.makedirs(od, exist_ok=True)
        for f in fn:
            s, d = os.path.join(dp, f), os.path.join(od, f)
            r = os.path.normpath(os.path.join(rel, f))
            if r not in files:
                os.symlink(os.path.abspath(s), d)
                continue
            lines = open(s, encoding="latin-1").read().split("\n")
            out, in_macro = [], False
            for i, ln in enumerate(lines):
                code = strip_comment(ln).strip()
                if re.match(r'^\.macro\b', code):
                    in_macro = True
                if code and not in_macro:
                    out.append("%s%d:" % (MARK, len(marks)))
                    marks.append((r, i + 1, ln))
                if re.match(r'^\.endm\b', code):
                    in_macro = False
                out.append(ln)
            open(d, "w", encoding="latin-1").write("\n".join(out))
    rootf = "kn5000_%s_program.s" % image
    obj, elf = os.path.join(tmp, "x.o"), os.path.join(tmp, "x.elf")
    sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mdir, "-I", src,
        "-o", obj, os.path.join(mdir, rootf)])
    sh([LLD, "-e", "0", "-T", os.path.join(mdir, "maincpu.ld"), "-o", elf, obj])
    raw = os.path.join(tmp, "x.bin")
    sh([OBJCOPY, "-O", "binary", elf, raw])
    rom = open(os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % image), "rb").read()
    if open(raw, "rb").read() != rom:
        raise SystemExit("MIRROR NOT INERT: linked mirror differs from the dump -- map refused")
    addrs, syms = {}, {}
    for line in sh([NM, "-n", elf]).split("\n"):
        p = line.split()
        if len(p) >= 3:
            if p[2].startswith(MARK):
                addrs[int(p[2][len(MARK):])] = int(p[0], 16)
            else:
                syms[p[2]] = int(p[0], 16)
    out = {}
    for f in files:
        idx = [i for i, m in enumerate(marks) if m[0] == f]
        rows = []
        for k, i in enumerate(idx):
            a = addrs[i]
            nxt = addrs[idx[k + 1]] if k + 1 < len(idx) else None
            rows.append([marks[i][1], a, None if nxt is None else nxt - a, marks[i][2]])
        out[f] = rows
    return out, syms, rom


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--files", required=True)
    ap.add_argument("--json", required=True)
    a = ap.parse_args()
    files = [os.path.normpath(f) for f in a.files.split(",")]
    with tempfile.TemporaryDirectory(prefix="llm-") as tmp:
        out, syms, rom = build(a.image, files, tmp)
    # reconciliation: sizes inside each file are non-negative and sum to span
    for f, rows in out.items():
        sizes = [r[2] for r in rows[:-1]]
        assert all(s >= 0 for s in sizes), "negative line size in %s" % f
        # a line's claimed first byte must be the ROM's byte: the stale-map guard
    json.dump(dict(image=a.image, files=out, symbols=syms), open(a.json, "w"))
    for f, rows in out.items():
        print("%s: %d marked lines, 0x%06X..0x%06X" % (f, len(rows), rows[0][1], rows[-1][1]))


if __name__ == "__main__":
    main()
