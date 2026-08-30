#!/usr/bin/env python3
r"""EMIT ASSEMBLER DATA LINES FOR A ROM RANGE -- and prove they re-assemble to it.

QUESTION ANSWERED
-----------------
"This span is data. What exactly do I write in the .s file so that not one byte
moves?" Hand-typing `.byte` runs for 1,779 bytes is how a re-framing lane breaks
the byte gate. This does it mechanically and then CHECKS ITSELF: --selftest
assembles what it just printed with the real llvm-mc and compares the result to
the ROM slice, byte for byte.

MODES
    --bytes LO HI [PER]    `.byte` lines, PER (default 16) per line, |ascii| gutter
    --cells LO WIDTH N     N fixed-width cells; each printable one becomes a
                           `.ascii`, anything else falls back to `.byte`
    --longs LO N           N little-endian 32-bit words as `.long 0x........`
    --selftest             the invariant: EMIT -> ASSEMBLE -> COMPARE, over
                           several ranges chosen for their content (pure ASCII,
                           pure binary, quotes/backslashes, a cell table). It
                           pins no address and no count: it asserts that
                           whatever this tool emits assembles back to the ROM.

RUN
    python3 scripts/analysis/emit_rom_data_lines.py --bytes 0xF6A9D7 0xF6AC91
    python3 scripts/analysis/emit_rom_data_lines.py --cells 0xF6ACA0 20 6
    python3 scripts/analysis/emit_rom_data_lines.py --selftest
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")
BASE = 0xE00000


def rom():
    return open(ROM_PATH, "rb").read()


def sl(d, lo, hi):
    return d[lo - BASE:hi - BASE]


def gutter(b):
    return "".join(chr(x) if 32 <= x < 127 else "." for x in b)


def esc(b):
    out = []
    for x in b:
        c = chr(x)
        if c == "\\":
            out.append("\\\\")
        elif c == '"':
            out.append('\\"')
        else:
            out.append(c)
    return "".join(out)


def emit_bytes(b, per=16):
    lines = []
    for i in range(0, len(b), per):
        row = b[i:i + per]
        lines.append("\t.byte " + ", ".join("0x%02x" % x for x in row)
                     + "\t; |%s|" % gutter(row))
    return lines


def emit_longs(b, n):
    return ["\t.long 0x%08x" % int.from_bytes(b[4 * i:4 * i + 4], "little")
            for i in range(n)]


def emit_cells(b, width, n):
    lines = []
    for i in range(n):
        c = b[i * width:(i + 1) * width]
        if all(32 <= x < 127 for x in c):
            lines.append('\t.ascii "%s"' % esc(c))
        else:
            lines.append("\t.byte " + ", ".join("0x%02x" % x for x in c)
                         + "\t; |%s|" % gutter(c))
    return lines


def assemble(lines):
    """Assemble the emitted text and return the bytes it produces."""
    with tempfile.TemporaryDirectory() as t:
        s, o, b = (os.path.join(t, x) for x in ("t.s", "t.o", "t.bin"))
        open(s, "w", encoding="latin-1").write("\t.text\n" + "\n".join(lines) + "\n")
        for cmd in ([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                    [OBJCOPY, "-O", "binary", "--only-section=.text", o, b]):
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode != 0:
                sys.exit("assemble failed: %s\n%s" % (" ".join(cmd), r.stderr[-2000:]))
        return open(b, "rb").read()


def selftest():
    d = rom()
    ok = True

    def check(desc, cond, extra=""):
        nonlocal ok
        print("  %-64s %s %s" % (desc, "PASS" if cond else "FAIL", extra))
        ok = ok and cond

    # INVARIANT: whatever --bytes emits assembles back to the same ROM slice.
    # Ranges are chosen for their CONTENT, not for any result they pin down:
    # a binary record block, an ASCII table, and a window over the whole ROM's
    # most escape-hostile bytes.
    for lo, hi, why in ((0xF6A9D7, 0xF6AC91, "record block, binary"),
                        (0xF6ACA0, 0xF6AD18, "ASCII table"),
                        (0xF6AE4C, 0xF6B207, "part names, mixed")):
        want = sl(d, lo, hi)
        check("--bytes 0x%06X..0x%06X round-trips (%s)" % (lo, hi, why),
              assemble(emit_bytes(want)) == want, "%d B" % len(want))

    # INVARIANT: --longs round-trips. Pointer tables are the construct this
    # lane most often has to re-frame, and a wrong endianness would still be
    # the right LENGTH -- so only a round-trip catches it.
    want = sl(d, 0xF12AFD, 0xF12B49)
    check("--longs 0xF12AFD 19 round-trips",
          assemble(emit_longs(want, 19)) == want, "%d B" % len(want))

    # INVARIANT: --cells round-trips too, including a cell containing a quote
    # or a backslash if the ROM has one in range.
    want = sl(d, 0xF6ACA0, 0xF6AD18)
    check("--cells 0xF6ACA0 20 6 round-trips",
          assemble(emit_cells(want, 20, 6)) == want)

    # INVARIANT: the escaper survives EVERY byte value that can appear in a
    # printable cell -- built synthetically, so it does not depend on the ROM.
    syn = bytes(range(0x20, 0x7F))
    check("every printable byte 0x20..0x7E survives .ascii escaping",
          assemble(emit_cells(syn, len(syn), 1)) == syn)

    # INVARIANT: a cell with a non-printable byte must NOT be emitted as .ascii.
    mixed = b"AB\x8cD"
    check("a non-printable cell falls back to .byte",
          assemble(emit_cells(mixed, 4, 1)) == mixed
          and emit_cells(mixed, 4, 1)[0].lstrip().startswith(".byte"))

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if "--selftest" in a:
        sys.exit(selftest())
    d = rom()
    if a and a[0] == "--bytes":
        lo, hi = int(a[1], 0), int(a[2], 0)
        per = int(a[3], 0) if len(a) > 3 else 16
        print("\n".join(emit_bytes(sl(d, lo, hi), per)))
    elif a and a[0] == "--longs":
        lo, n = int(a[1], 0), int(a[2], 0)
        print("\n".join(emit_longs(sl(d, lo, lo + 4 * n), n)))
    elif a and a[0] == "--cells":
        lo, w, n = int(a[1], 0), int(a[2], 0), int(a[3], 0)
        print("\n".join(emit_cells(sl(d, lo, lo + w * n), w, n)))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
