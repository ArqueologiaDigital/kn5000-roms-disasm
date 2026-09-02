#!/usr/bin/env python3
"""convert_erased_fill.py -- type the sub-CPU boot ROM's erased flash as `.fill`

QUESTION ANSWERED: the 96 KiB at the bottom of IC30 (0xFE0000-0xFF7FFF) is
erased flash. It is currently written as 98,304 consecutive lines of
`.byte 0xff` -- 97% of the file, and 98,304 bytes that every debt instrument
in this tree counts as an undocumented `.byte` run (see
scripts/analysis/tier2_byte_split_census.py, which classifies it (b)
STRUCTURED DATA THAT SHOULD BE TYPED). Can it be replaced by one `.fill`
directive without changing a single byte of the built ROM?

WHY THIS IS NOT COSMETIC. A `.byte` line with no type is exactly as
un-decoded as an `.incbin` (notes/lanes/BRIEF-2026-09-01.md). Worse, this
particular run is an active trap: 0xFF is a legal TLCS-900 opcode, so a
linear decoder reads the whole 96 KiB as 98,758 `swi 7` instructions, and the
first version of the census tool duly reported it as 98,960 B of undiscovered
CODE. Typing it as a fill removes the run from the debt population AND from
the reach of that mistake.

WHAT IT REFUSES TO DO. Only the ONE maximal run of identical `.byte 0xff`
lines at the head of the file is touched, and only if it is exactly the
expected 98,304 lines of exactly that text. The three smaller uniform runs
the census also flags (95 B of 0x02, 32 B of 0x01, 20 B of 0x00, all at
0xFF812A-0xFF828F) are deliberately LEFT ALONE: they sit inside the
documented eight-object boot data region, where they are fields of named
velocity-curve and voice-image tables, not padding, and collapsing them would
fragment objects the source already explains.

RUN (from the lane worktree root):
    python3 subcpu/boot/tools/convert_erased_fill.py            # dry run
    python3 subcpu/boot/tools/convert_erased_fill.py --apply
    rm -f rebuilt_ROMs/kn5000_subcpu_boot.llvm.*
    make rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom
    cmp rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom original_ROMs/kn5000_subcpu_boot.ic30

The prerequisite is removed first so the cmp cannot certify a stale object.

⚠ AND THE CMP MUST BE ABLE TO FAIL. `--negative-control` assembles the same
source with the fill VALUE changed to 0xfe, in a temporary copy, and requires
the result to differ from the dump. Without that, "byte-identical" only says
the build ran. It fails at byte 1.

    python3 subcpu/boot/tools/convert_erased_fill.py --negative-control

⚠ latin-1 I/O throughout: these sources are latin-1 and a UTF-8 round trip
silently corrupts raw high bytes inside `.ascii` literals elsewhere in the
tree (BRIEF addendum 2026-09-02).
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(ROOT, "subcpu/boot/kn5000_subcpu_boot.s")
LINE = "\t.byte 0xff"
EXPECT = 98304          # bytes == lines, one byte each
COMMENT = "\t; Fill first 96KB with 0xFF"


def negative_control():
    """Assemble a copy with the fill value changed and require the built ROM to
    DIFFER from the dump. A compare that cannot fail certifies nothing."""
    import shutil
    import subprocess
    import tempfile
    llvm = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
    orig = open(os.path.join(ROOT, "original_ROMs/kn5000_subcpu_boot.ic30"), "rb").read()
    with tempfile.TemporaryDirectory(prefix="subboot_nc_") as tmp:
        d = os.path.join(tmp, "boot")
        shutil.copytree(os.path.join(ROOT, "subcpu/boot"), d)
        f = os.path.join(d, "kn5000_subcpu_boot.s")
        text = open(f, encoding="latin-1").read()
        if ".fill %d, 1, 0xff" % EXPECT not in text:
            sys.exit("source does not contain the expected .fill -- run --apply first")
        open(f, "w", encoding="latin-1").write(
            text.replace(".fill %d, 1, 0xff" % EXPECT, ".fill %d, 1, 0xfe" % EXPECT))
        o, e, r = (os.path.join(tmp, x) for x in ("t.o", "t.elf", "t.rom"))
        subprocess.run([os.path.join(llvm, "llvm-mc"), "-triple=tlcs900",
                        "-filetype=obj", "-I", d, "-o", o, f],
                       check=True, capture_output=True)
        subprocess.run([os.path.join(llvm, "ld.lld"), "-e", "0", "-T",
                        os.path.join(ROOT, "subcpu/boot/subcpu_boot.ld"),
                        "-o", e, o], check=True, capture_output=True)
        subprocess.run([os.path.join(llvm, "llvm-objcopy"), "-O", "binary", e, r],
                       check=True)
        built = open(r, "rb").read()
    if built == orig:
        print("NEGATIVE CONTROL FAILED -- the compare cannot see a changed fill "
              "value, so byte-identity proves nothing here")
        return 1
    first = next(i for i in range(min(len(built), len(orig))) if built[i] != orig[i])
    print("NEGATIVE CONTROL OK -- fill value 0xfe makes the build differ from the "
          "dump at byte %d" % (first + 1))
    return 0


def main():
    if "--negative-control" in sys.argv:
        return negative_control()
    apply_ = "--apply" in sys.argv
    text = open(SRC, encoding="latin-1").read()
    lines = text.split("\n")
    try:
        first = lines.index(LINE)
    except ValueError:
        sys.exit("no `%s` line found -- already converted?" % LINE)
    last = first
    while last + 1 < len(lines) and lines[last + 1] == LINE:
        last += 1
    n = last - first + 1
    print("maximal `%s` run: lines %d..%d = %d lines" % (LINE, first + 1, last + 1, n))
    if n != EXPECT:
        sys.exit("refusing: expected exactly %d lines, found %d. The region this "
                 "tool is allowed to touch is the 96 KiB erased head of IC30 and "
                 "nothing else." % (EXPECT, n))
    if lines[first - 1] != COMMENT:
        sys.exit("refusing: the line above the run is %r, not the expected "
                 "%r -- this is not the region this tool was written for."
                 % (lines[first - 1], COMMENT))
    repl = [
        "\t; Erased flash: 0xFE0000-0xFF7FFF, 98,304 B, every byte 0xFF.  Typed as a",
        "\t; fill rather than 98,304 `.byte 0xff` lines -- the bytes are identical, but",
        "\t; an untyped `.byte` run counts as un-decoded debt, and 0xFF decodes as a",
        "\t; legal `swi 7`, so a linear disassembler reads this region as 98,758",
        "\t; instructions.  Actual boot ROM content starts at 0xFF8000.",
        "\t.fill %d, 1, 0xff" % n,
    ]
    out = lines[:first] + repl + lines[last + 1:]
    print("would replace %d lines with %d" % (n, len(repl)))
    if not apply_:
        print("(dry run; pass --apply to write)")
        return 0
    open(SRC, "w", encoding="latin-1").write("\n".join(out))
    print("written: %s" % SRC)
    return 0


if __name__ == "__main__":
    sys.exit(main())
