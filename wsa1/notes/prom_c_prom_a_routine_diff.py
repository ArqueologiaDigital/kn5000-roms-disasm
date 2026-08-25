#!/usr/bin/env python3
"""Are these two routines the SAME routine compiled for the two CPUs, or just similar?

QUESTION IT ANSWERS
  prom_a (CPU 1) and prom_c (CPU 2) were built from one source tree, so the link
  driver exists twice -- but NOT byte-identically, because every port address, every
  handshake pin and every work-RAM address differs.  `prom_c_prom_a_shared_runs.py`
  measures BYTE identity and therefore reports "8 bytes" for a pair of routines that
  are in fact the same 40 instructions.  This aligns them INSTRUCTION BY INSTRUCTION
  and reports:

      * how many instruction slots line up 1:1,
      * which slots carry a different mnemonic (a real structural difference),
      * which slots carry the same mnemonic with a different operand (the substituted
        addresses -- printed in full, so a claim like "only the addresses differ" can
        be checked instead of trusted).

  ⚠ It compares unidasm's TEXT.  Two different instructions that render the same text
  would be called equal; nothing in this pass relies on that not happening, and the
  full operand lists are printed so it stays visible.

RUN
  python3 notes/prom_c_prom_a_routine_diff.py 0xF99A40 0xF8E0FE 0x83
  python3 notes/prom_c_prom_a_routine_diff.py 0xF99A40 0xF8E0FE 0x83 --quiet
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")


def dis(path, base, addr, n):
    data = open(path, "rb").read()
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[addr - base:addr - base + n])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    out = []
    for line in p.stdout.splitlines():
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    return out


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    ca, aa, n = (int(x, 0) for x in sys.argv[1:4])
    quiet = "--quiet" in sys.argv
    C = dis(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), 0xF80000, ca, n)
    A = dis(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000, aa, n)
    k = min(len(C), len(A))
    same = diffop = diffmn = 0
    rows = []
    for i in range(k):
        ct, at = C[i][2], A[i][2]
        cm, am = ct.split()[0] if ct else "", at.split()[0] if at else ""
        if ct == at:
            same += 1
        elif cm == am:
            diffop += 1
            rows.append(("OPERAND", C[i][0], ct, A[i][0], at))
        else:
            diffmn += 1
            rows.append(("MNEMONIC", C[i][0], ct, A[i][0], at))
    print("prom_c 0x%06X vs prom_a 0x%06X, %d bytes" % (ca, aa, n))
    print("  instruction slots compared: %d   (prom_c decoded %d, prom_a %d)"
          % (k, len(C), len(A)))
    print("  identical text:        %d" % same)
    print("  same mnemonic, different operand: %d" % diffop)
    print("  DIFFERENT MNEMONIC:    %d   <-- a structural difference" % diffmn)
    if not quiet:
        for kind, c1, t1, a1, t2 in rows:
            print("  %-8s  c 0x%06X  %-34s | a 0x%06X  %s" % (kind, c1, t1, a1, t2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
