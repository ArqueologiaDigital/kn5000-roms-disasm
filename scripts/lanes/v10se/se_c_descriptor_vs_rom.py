#!/usr/bin/env python3
r"""DO THE UNINTEGRATED SE SCREEN C DESCRIPTORS ACTUALLY MATCH THE ROM?

QUESTION ANSWERED
-----------------
`v10/maincpu/audio/sound_editor_screens/` holds 23 C screen-descriptor files,
but the Makefile's SE_NAMES compiles only 9 of them.  Each file's header states
a BASE ADDRESS and a SIZE.  If a file's compiled bytes equal the ROM bytes at
its stated base, then that C struct is *already* a correct, typed, byte-exact
description of a region the assembly currently spells as `.byte` / mis-framed
instructions -- and integrating it is a strictly better representation than any
disassembly of the same bytes.

This tool compiles EVERY se_*.c with the project's own toolchain invocation
(identical to the Makefile's se_%.bin rule) and diffs the result against
`original_ROMs/kn5000_v10_program.rom` at the header's base address.

It is the CONTROL for the integration: a descriptor that does not match here
must not be integrated, and a descriptor that does match cannot be wrong about
those bytes (the byte gate then re-checks it end to end).

RUN
    python3 scripts/lanes/v10se/se_c_descriptor_vs_rom.py
    python3 scripts/lanes/v10se/se_c_descriptor_vs_rom.py --only se_setup_sel1
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__)))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
CLANG = os.path.join(LLVM, "clang")
LLD = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")

SEDIR = os.path.join(ROOT, "v10/maincpu/audio/sound_editor_screens")
LINKLD = os.path.join(SEDIR, "se_screens_link.ld")
INCDIR = os.path.join(ROOT, "v10/maincpu/style_ui")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000

def _integrated():
    """Names already `.incbin`'d by some v10 assembly file.

    Derived, not hardcoded: this lane wires several more into the build during
    its own run, and a stale constant would make the tool try to integrate them
    twice (dropping the comments carried over the first time).
    """
    got = set()
    root = os.path.join(ROOT, "v10", "maincpu")
    for dp, _, fs in os.walk(root):
        for f in fs:
            if not f.endswith(".s"):
                continue
            txt = open(os.path.join(dp, f), encoding="latin-1").read()
            for m in re.finditer(r'\.incbin\s+"includes/generated/(se_[\w]+)\.bin"',
                                 txt):
                got.add(m.group(1))
    return got


INTEGRATED = _integrated()


def header_base(path):
    txt = open(path, encoding="latin-1").read()
    m = re.search(r"Base address:\s*0x([0-9A-Fa-f]+)", txt)
    return int(m.group(1), 16) if m else None


def compile_bin(cpath, tmp):
    stem = os.path.basename(cpath)[:-2]
    o = os.path.join(tmp, stem + ".o")
    e = os.path.join(tmp, stem + ".elf")
    b = os.path.join(tmp, stem + ".bin")
    for cmd in (
        [CLANG, "-target", "tlcs900", "-ffreestanding", "-c", "-O2",
         "-I", INCDIR, "-o", o, cpath],
        [LLD, "-e", "0", "-T", LINKLD, "-o", e, o],
        [OBJCOPY, "-O", "binary", "-j", ".text", e, b],
    ):
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            return None, r.stderr.strip().split("\n")[-1]
    return open(b, "rb").read(), None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    args = ap.parse_args()

    rom = open(ROM, "rb").read()
    tmp = tempfile.mkdtemp(prefix="se-cdesc-")
    names = sorted(f[:-2] for f in os.listdir(SEDIR) if f.endswith(".c"))
    if args.only:
        names = [n for n in names if n == args.only]

    match_new = match_old = mismatch = failed = 0
    newbytes = 0
    print(f"{'descriptor':<30} {'base':>9} {'size':>5} {'in build':>8}  verdict")
    for n in names:
        c = os.path.join(SEDIR, n + ".c")
        base = header_base(c)
        blob, err = compile_bin(c, tmp)
        wired = "yes" if n in INTEGRATED else "NO"
        if blob is None:
            print(f"{n:<30} {base:>9X} {'?':>5} {wired:>8}  COMPILE FAIL: {err}")
            failed += 1
            continue
        off = base - BASE
        want = rom[off:off + len(blob)]
        if want == blob:
            v = "MATCH"
            if n in INTEGRATED:
                match_old += 1
            else:
                match_new += 1
                newbytes += len(blob)
        else:
            nd = sum(1 for a, b in zip(want, blob) if a != b)
            first = next((i for i, (a, b) in enumerate(zip(want, blob)) if a != b), None)
            v = f"MISMATCH ({nd}/{len(blob)} bytes, first at +0x{first:X})"
            mismatch += 1
        print(f"{n:<30} {base:>9X} {len(blob):>5} {wired:>8}  {v}")

    print()
    print(f"already integrated and matching : {match_old}")
    print(f"NOT integrated but matching     : {match_new}  ({newbytes} bytes available)")
    print(f"mismatching                     : {mismatch}")
    print(f"failed to compile               : {failed}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
