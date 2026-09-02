#!/usr/bin/env python3
"""Question answered: what ROM address does each source line of a v10 maincpu
.s file assemble to?

The tree has no listing file, and `llvm-mc -g` attributes every line of every
.include'd file to the ROOT file, so its line table cannot be used to locate a
line inside an included source.  This probe answers the question directly and
without guessing: it copies the v10 tree to a scratch directory, inserts a
uniquely named (global-visible, non-`.L`) label immediately BEFORE every source line of the requested
files, assembles and links exactly as the Makefile does, and reads the label
addresses out of the ELF symbol table.

A label emits no bytes, so the probe is self-checking: the linked image must
still be byte-identical to original_ROMs/kn5000_v10_program.rom.  If it is not,
the map is rejected rather than reported.  Lines inside `.macro`/`.endm` bodies
are skipped (a label there would be emitted once per expansion).

Exact command (from the repo root):

    python3 scripts/analysis/v10_line_address_map.py \
        v10/maincpu/midi/midi_dispatch_handlers.s \
        v10/maincpu/display/scoop_display.s \
        --out /tmp/linemap.json

Output JSON: {"<relpath>": {"<line number>": <address>, ...}, ...}
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.environ.get("LLVM_BIN", os.path.expanduser("~/compartilhado/llvm-project/build/bin"))


def instrument(path, tag):
    """Insert `.Lprobe_<tag>_<lineno>:` before every line; return new text."""
    src = open(path, encoding="latin-1").read()
    out = []
    in_macro = False
    for i, line in enumerate(src.split("\n"), start=1):
        s = line.strip()
        if s.startswith(".macro"):
            in_macro = True
        if not in_macro and s and not s.startswith(";") and not s.startswith("#"):
            out.append("Zprobe_%s_%d:" % (tag, i))
        if s.startswith(".endm"):
            in_macro = False
        out.append(line)
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", help="paths relative to repo root")
    ap.add_argument("--out", required=True)
    ap.add_argument("--scratch", default=None)
    args = ap.parse_args()

    scratch = args.scratch or os.path.join(
        os.environ.get("TMPDIR", "/tmp"), "v10linemap")
    tree = os.path.join(scratch, "v10")
    if os.path.exists(tree):
        shutil.rmtree(tree)
    os.makedirs(scratch, exist_ok=True)
    shutil.copytree(os.path.join(ROOT, "v10"), tree, symlinks=True)

    tags = {}
    for idx, rel in enumerate(args.files):
        tags[rel] = "f%d" % idx
        dst = os.path.join(scratch, rel)
        open(dst, "w", encoding="latin-1").write(
            instrument(os.path.join(ROOT, rel), tags[rel]))

    obj = os.path.join(scratch, "probe.o")
    elf = os.path.join(scratch, "probe.elf")
    rom = os.path.join(scratch, "probe.rom")
    inc = os.path.join(tree, "maincpu")
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                    "-filetype=obj", "-I", inc, "-o", obj,
                    os.path.join(inc, "kn5000_v10_program.s")],
                   check=True, cwd=ROOT, stderr=subprocess.DEVNULL)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                    os.path.join(inc, "maincpu.ld"), "-o", elf, obj], check=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, rom],
                   check=True)

    ref = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    if open(rom, "rb").read() != ref:
        sys.exit("REJECTED: instrumented image is not byte-identical to the ROM")

    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), "--defined-only", elf],
                        check=True, capture_output=True, text=True).stdout
    rev = {v: k for k, v in tags.items()}
    maps = {rel: {} for rel in args.files}
    pat = re.compile(r"^([0-9a-fA-F]+)\s+\S+\s+Zprobe_(f\d+)_(\d+)$")
    for line in nm.split("\n"):
        m = pat.match(line.strip())
        if m:
            maps[rev[m.group(2)]][int(m.group(3))] = int(m.group(1), 16)
    json.dump(maps, open(args.out, "w"), indent=0)
    for rel in args.files:
        print("%-52s %6d lines mapped" % (rel, len(maps[rel])))


if __name__ == "__main__":
    main()
