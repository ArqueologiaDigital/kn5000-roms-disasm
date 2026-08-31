#!/usr/bin/env python3
"""Does this fragment of assembly rebuild exactly the ROM bytes it claims to?

QUESTION IT ANSWERS
  The byte gate (`scripts/analysis/assert_byte_identical.py`) is whole-image: it says
  PASS or it says which ROM differs at which offset, and on a 6,000-line source that is
  a long way from the line that is wrong.  This assembles ONE fragment on its own and
  reports the first differing byte together with the source line that emitted it, which
  is what you actually need while transcribing.

  It is not a substitute for the gate.  It is the thing you run BEFORE the gate so the
  gate has nothing to find.

RUN
  python3 notes/prom_c_verify_fragment.py c 0xF9973D /tmp/blockA.pretty.s
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LLVM = os.environ.get("LLVM_BIN", "/home/fsanches/compartilhado/llvm-project/build/bin")
IMAGES = {"a": ("wsa1_prom_a.ic12", 0xF80000), "b": ("wsa1_prom_b.ic13", 0xF00000),
          "c": ("wsa1_prom_c.ic28", 0xF80000), "d": ("wsa1_prom_d.bin", 0x000000)}


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    img, addr, path = sys.argv[1], int(sys.argv[2], 0), sys.argv[3]
    name, base = IMAGES[img]
    rom = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
    text = open(path).read()

    d = tempfile.mkdtemp()
    s, o, b = (os.path.join(d, n) for n in ("t.s", "t.o", "t.bin"))
    open(s, "w").write("\t.include \"include/tmp95c061_sfr.inc\"\n\t.text\n" + text)
    p = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-filetype=obj", "-I", ROOT, "-o", o, s],
                       capture_output=True, text=True)
    if p.returncode:
        sys.stderr.write(p.stderr)
        print("ASSEMBLY FAILED")
        return 3
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", o, b], check=True)
    got = open(b, "rb").read()
    want = rom[addr - base:addr - base + len(got)]
    if len(got) != len(want):
        print("LENGTH: emitted %d, ROM window %d" % (len(got), len(want)))
    for i in range(min(len(got), len(want))):
        if got[i] != want[i]:
            print("MISMATCH at 0x%06X (fragment byte %d): emitted %02X, ROM %02X"
                  % (addr + i, i, got[i], want[i]))
            print("  emitted context:", got[max(0, i - 6):i + 6].hex(" "))
            print("  ROM     context:", want[max(0, i - 6):i + 6].hex(" "))
            return 1
    print("OK: %d bytes, 0x%06X-0x%06X, byte-identical to the ROM"
          % (len(got), addr, addr + len(got) - 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
