#!/usr/bin/env python3
r"""lane_line_map.py -- which address does each line of THESE source files emit at?

QUESTION ANSWERED
-----------------
"For every byte-emitting line of the files I name, in maincpu v7, v9 or v10,
what is its address and how many bytes does it emit?"  The KN5000 sources carry
no address comments, so this has no grep answer.  `address_line_map.py` answers
it for v10 only and for the whole tree; this is the same instrument, restricted
to a named file set (cheap to read back) and parameterised by version, written
for the `ext` lane of the 2026-09-25 semantic push to port v10's typed
`extensions/extension_data.s` to v9 and v7 line by line.

HOW (the same proof as address_line_map.py and data_range_census.py)
---
Mirror `<ver>/maincpu` into a temp dir, insert a synthetic label `__llm_<n>:`
in front of every non-blank, non-comment line of the named files that is not
inside a `.macro` body, assemble and LINK the mirror with the real `maincpu.ld`,
and read the marker addresses out of the ELF with `llvm-nm`.  Line i emits
[addr(marker i), addr(marker i+1)).  The last marked line of a file is sized
against the marker-free first label that follows the file's include site, so
the tool refuses to size it and reports size -1 instead of guessing.

★ THE MIRROR MUST BE INERT: the linked mirror is objcopy'd and asserted
  byte-identical to `original_ROMs/kn5000_<ver>_program.rom` before any
  address is reported.  A label emits no bytes, so a still-matching image
  proves the map describes this tree.

⚠ Build first (`make gate`): the mirror needs the generated `.bin` inputs
  under `<ver>/maincpu/includes/generated/` that the Makefile produces.

RUN
    python3 scripts/analysis/lane_line_map.py --ver v9 \
        --files extensions/extension_data.s,extensions/extension_init.s \
        --json /tmp/claude-1000/lane-ext/v9map.json
  JSON: {"<file>": [[line_no (1-based), addr, size, text], ...], ...}
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("LLVM_MC", os.path.join(LLVM, "llvm-mc"))
LLD = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
NM = os.path.join(LLVM, "llvm-nm")
MARK = "__llm_"


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit("FAILED: %s\n%s" % (" ".join(cmd), (r.stderr or r.stdout)[-3000:]))
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
        if ch == ";" and not q:
            break
        out.append(ch)
    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ver", required=True, choices=["v7", "v9", "v10"])
    ap.add_argument("--files", required=True, help="comma list, relative to <ver>/maincpu")
    ap.add_argument("--json", required=True)
    a = ap.parse_args()
    src = os.path.join(ROOT, a.ver, "maincpu")
    files = [f.strip() for f in a.files.split(",") if f.strip()]
    tmp = tempfile.mkdtemp(prefix="llm_")
    try:
        mir = os.path.join(tmp, "m")
        # copy .s files, symlink everything else
        for dp, dn, fn in os.walk(src):
            rel = os.path.relpath(dp, src)
            od = os.path.join(mir, rel) if rel != "." else mir
            os.makedirs(od, exist_ok=True)
            for f in fn:
                s = os.path.join(dp, f)
                d = os.path.join(od, f)
                if f.endswith(".s"):
                    shutil.copyfile(s, d)
                else:
                    os.symlink(s, d)
        marks = []   # (file, line_no, text)
        for f in files:
            p = os.path.join(mir, f)
            lines = open(p, encoding="latin-1").read().split("\n")
            out, inm = [], False
            for i, ln in enumerate(lines):
                c = strip_comment(ln).strip()
                if re.match(r'^\.macro\b', c):
                    inm = True
                # a line whose code is only `NAME = expr` / `.set` emits nothing
                # (an `.include` line IS marked: its size is the included file's bytes)
                emits = c and not inm and not re.match(
                    r'^([A-Za-z_.$][\w.$]*\s*=|\.(set|equ|equiv|macro|endm|globl|global|text|section)\b)', c)
                # a line that is only a label emits nothing either
                if emits and re.match(r'^[A-Za-z_.$][\w.$]*:\s*$', c):
                    emits = False
                if emits:
                    out.append("%s%d:" % (MARK, len(marks)))
                    marks.append((f, i + 1, ln))
                if re.match(r'^\.endm\b', c):
                    inm = False
                out.append(ln)
            open(p, "w", encoding="latin-1").write("\n".join(out))
        root_s = "kn5000_%s_program.s" % a.ver
        obj = os.path.join(tmp, "o.o")
        elf = os.path.join(tmp, "o.elf")
        binf = os.path.join(tmp, "o.bin")
        sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mir, "-o", obj, os.path.join(mir, root_s)])
        sh([LLD, "-T", os.path.join(mir, "maincpu.ld"), "-o", elf, obj])
        sh([OBJCOPY, "-O", "binary", elf, binf])
        rom = open(os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % a.ver), "rb").read()
        got = open(binf, "rb").read()
        if got != rom:
            n = sum(1 for x, y in zip(got, rom) if x != y) + abs(len(got) - len(rom))
            raise SystemExit("MIRROR NOT INERT: %d bytes differ from the dump -- no map reported" % n)
        addr = {}
        allsyms = []
        for ln in sh([NM, "--defined-only", elf]).split("\n"):
            parts = ln.split()
            if len(parts) != 3:
                continue
            v = int(parts[0], 16)
            if parts[2].startswith(MARK):
                addr[int(parts[2][len(MARK):])] = v
            allsyms.append(v)
        allsyms.sort()
        res = {}
        import bisect
        for n, (f, lno, text) in enumerate(marks):
            a0 = addr[n]
            if n + 1 < len(marks) and marks[n + 1][0] == f:
                size = addr[n + 1] - a0
            else:
                size = -1
            res.setdefault(f, []).append([lno, a0, size, text])
        json.dump(res, open(a.json, "w"))
        for f in res:
            print("%s: %d lines, 0x%06X..0x%06X" % (f, len(res[f]), res[f][0][1], res[f][-1][1]))
        print("mirror byte-identical to the %s dump: OK" % a.ver)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
