#!/usr/bin/env python3
r"""seqeng_line_map.py -- which ROM address does each line of ONE maincpu source emit?

QUESTION ANSWERED
-----------------
"Line L of v9/maincpu/sequencer/seq_event_playback.s -- what address does its
first byte land at, and how many bytes does it emit?"  The maincpu sources
carry no address comments, and scripts/analysis/address_line_map.py answers
this for v10 only.  Lane `seqeng` (2026-09-25) needs it for v10, v9 AND v7,
for the five sequencer files it owns, to re-frame misframed code and to port
typed data from v10 into v9/v7.

HOW (same instrument as address_line_map.py / data_range_census.py)
---
Mirror the image's source dir into a temp dir (symlinks for every file except
the requested ones), insert a synthetic label `__slm_<n>:` in front of every
byte-emitting line of the requested files, assemble + link the mirror with
the real maincpu.ld, read the marker addresses from the ELF.

★ THE MIRROR IS PROVEN INERT: the linked mirror is objcopy'd and compared to
  the original dump; any difference aborts.  So the map describes THIS tree.

RUN
    python3 scripts/analysis/seqeng_line_map.py v9 sequencer/seq_event_playback.s
    python3 scripts/analysis/seqeng_line_map.py v7 sequencer/sequencer_engine.s --json out.json
    python3 scripts/analysis/seqeng_line_map.py v10 sequencer/sequencer_engine.s --addr 0xF3F80D

  Import: `line_map(image, [relfile, ...])` -> {relfile: [(line, addr, size), ...]}
  (line is 1-based; size is the byte count up to the next marked line, which
  is the line's own emission because unmarked lines emit nothing).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("LLVM_MC", os.path.join(LLVM, "llvm-mc"))
LLD = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
NM = os.path.join(LLVM, "llvm-nm")
MARK = "__slm_"

IMAGES = {
    k: dict(src="%s/maincpu" % k, root="kn5000_%s_program.s" % k, ld="maincpu.ld",
            rom="original_ROMs/kn5000_%s_program.rom" % k, base=0xE00000)
    for k in ("v10", "v9", "v7")
}


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
            out.append(ch)
            continue
        if ch == ";":
            break
        out.append(ch)
    return "".join(out)


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit("FAILED: %s\n%s" % (" ".join(cmd), r.stderr[-3000:]))
    return r.stdout


def line_map(image, relfiles):
    img = IMAGES[image]
    srcroot = os.path.join(ROOT, img["src"])
    want = set(relfiles)
    marks = []
    with tempfile.TemporaryDirectory(prefix="slm-") as tmp:
        mirror = os.path.join(tmp, "m")
        for dp, dn, fn in os.walk(srcroot):
            rel = os.path.relpath(dp, srcroot)
            outdir = os.path.join(mirror, rel) if rel != "." else mirror
            os.makedirs(outdir, exist_ok=True)
            for f in fn:
                s = os.path.join(dp, f)
                d = os.path.join(outdir, f)
                r = os.path.normpath(os.path.join(rel, f))
                if r not in want:
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
                        marks.append((r, i + 1))
                    if re.match(r'^\.endm\b', code):
                        in_macro = False
                    out.append(ln)
                open(d, "w", encoding="latin-1").write("\n".join(out))
        obj, elf, rom = (os.path.join(tmp, x) for x in ("a.o", "a.elf", "a.rom"))
        sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mirror, "-I", srcroot,
            "-o", obj, os.path.join(mirror, img["root"])])
        sh([LLD, "-T", os.path.join(mirror, img["ld"]), "-o", elf, obj])
        sh([OBJCOPY, "-O", "binary", elf, rom])
        if open(rom, "rb").read() != open(os.path.join(ROOT, img["rom"]), "rb").read():
            raise SystemExit("MIRROR NOT INERT for %s: linked mirror differs from dump" % image)
        addrs = {}
        for line in sh([NM, "-n", elf]).split("\n"):
            p = line.split()
            if len(p) >= 3 and p[2].startswith(MARK):
                addrs[int(p[2][len(MARK):])] = int(p[0], 16)
    res = {r: [] for r in relfiles}
    n = len(marks)
    for i, (r, ln) in enumerate(marks):
        a = addrs[i]
        nxt = addrs[i + 1] if i + 1 < n and marks[i + 1][0] == r else None
        res[r].append([ln, a, (nxt - a) if nxt is not None else None])
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", choices=sorted(IMAGES))
    ap.add_argument("files", nargs="+")
    ap.add_argument("--json")
    ap.add_argument("--addr", help="print the line(s) covering this address")
    a = ap.parse_args()
    m = line_map(a.image, a.files)
    if a.json:
        json.dump(m, open(a.json, "w"))
    if a.addr:
        x = int(a.addr, 0)
        for r, rows in m.items():
            for ln, ad, sz in rows:
                if sz and ad <= x < ad + sz:
                    print("%s:%d 0x%06X +%d" % (r, ln, ad, sz))
    if not a.json and not a.addr:
        for r, rows in m.items():
            print(r, len(rows), "lines", "0x%06X" % rows[0][1], "-", "0x%06X" % rows[-1][1])


if __name__ == "__main__":
    main()
