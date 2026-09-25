#!/usr/bin/env python3
r"""WHICH ROM ADDRESS DOES EACH LINE OF ONE SOURCE FILE EMIT AT?  (v10 / v9 / v7)

QUESTION ANSWERED
    For one maincpu source file of one version, the address of the first byte
    every byte-emitting line produces.  scripts/analysis/address_line_map.py
    answers the same question for the whole v10 tree; this marks ONE file (so
    it is quick) and works for v9 and v7 too.

HOW
    Copies <v>/maincpu to a temp dir (symlinks for everything but the target
    file), inserts `__flmap_<n>:` before every byte-emitting line of the target
    file (not inside .macro bodies), assembles + links with the version's own
    kn5000_<v>_program.s and maincpu.ld, reads the markers back with llvm-nm.

INERTNESS GUARD (always run)
    The marked build is objcopied and compared with original_ROMs/
    kn5000_<v>_program.rom; any difference aborts.  A map of a perturbed tree
    is a map of nothing.  Each line also records the ROM bytes it covers
    (up to the next marker) so a consumer can assert "the bytes this line
    claims are the bytes the ROM holds".

RUN
    python3 scripts/analysis/file_line_addresses.py --image v10 --file ui_widgets/widget_dispatch.s --json out.json
    python3 scripts/analysis/file_line_addresses.py --image v7 --file ui/bitmap_out_routines.s --range 0xFB4000 0xFB4100
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
MARK = "__flmap_"
B = 0xE00000


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("FAILED: %s\n%s" % (" ".join(cmd), r.stderr[-3000:]))
    return r.stdout


def build(image, relfile):
    src = os.path.join(ROOT, image, "maincpu")
    tmp = tempfile.mkdtemp(prefix="flmap-%s-" % image)
    mir = os.path.join(tmp, "maincpu")
    for dp, dn, fn in os.walk(src):
        rel = os.path.relpath(dp, src)
        out = os.path.join(mir, rel) if rel != "." else mir
        os.makedirs(out, exist_ok=True)
        for f in fn:
            if os.path.relpath(os.path.join(dp, f), src) != relfile:
                os.symlink(os.path.join(dp, f), os.path.join(out, f))
    lines = open(os.path.join(src, relfile), encoding="latin-1").read().split("\n")
    out, marks, in_macro = [], [], False
    for i, ln in enumerate(lines):
        code = ln.split(";")[0].strip()
        if re.match(r'^\.macro\b', code):
            in_macro = True
        if code and not in_macro and not re.match(r'^[\w.$]+\s*(=|\.set\b)', code) \
                and not code.startswith((".set", ".equ", ".globl", ".global")):
            out.append("%s%d:" % (MARK, len(marks)))
            marks.append(i + 1)
        if re.match(r'^\.endm\b', code):
            in_macro = False
        out.append(ln)
    open(os.path.join(mir, relfile), "w", encoding="latin-1").write("\n".join(out))
    obj, elf, binf = (os.path.join(tmp, x) for x in ("m.o", "m.elf", "m.bin"))
    sh([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I", mir,
        "-o", obj, os.path.join(mir, "kn5000_%s_program.s" % image)])
    sh([os.path.join(LLVM, "ld.lld"), "-T", os.path.join(mir, "maincpu.ld"), "-o", elf, obj])
    sh([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, binf])
    rom = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % image), "rb").read()
    got = open(binf, "rb").read()
    if got != rom:
        sys.exit("INERTNESS GUARD FAILED: the marked build differs from the ROM")
    addr = {}
    for ln in sh([os.path.join(LLVM, "llvm-nm"), "-n", elf]).split("\n"):
        p = ln.split()
        if len(p) >= 3 and p[2].startswith(MARK):
            addr[int(p[2][len(MARK):])] = int(p[0], 16)
    shutil.rmtree(tmp)
    ent = []
    for k, line in enumerate(marks):
        if k in addr:
            ent.append({"line": line, "addr": addr[k], "text": lines[line - 1]})
    ent.sort(key=lambda e: (e["addr"], e["line"]))
    for j, e in enumerate(ent):
        nxt = next((f["addr"] for f in ent[j + 1:] if f["addr"] > e["addr"]), e["addr"])
        e["bytes"] = rom[e["addr"] - B:nxt - B].hex() if B <= e["addr"] < B + len(rom) else ""
    return ent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--file", required=True, help="path relative to <image>/maincpu")
    ap.add_argument("--json")
    ap.add_argument("--range", nargs=2)
    a = ap.parse_args()
    ent = build(a.image, a.file)
    if a.json:
        json.dump(ent, open(a.json, "w"))
        print("wrote %s (%d lines; marked build byte-identical to the ROM)" % (a.json, len(ent)))
    if a.range:
        lo, hi = int(a.range[0], 0), int(a.range[1], 0)
        for e in ent:
            if lo <= e["addr"] < hi:
                print("0x%06X  %5d  %s" % (e["addr"], e["line"], e["text"][:90]))


if __name__ == "__main__":
    main()
