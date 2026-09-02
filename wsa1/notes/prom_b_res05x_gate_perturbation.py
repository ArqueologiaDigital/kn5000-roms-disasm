#!/usr/bin/env python3
"""prom_b_res05x_gate_perturbation.py -- can `make gate-wsa1` actually SEE the
bytes lane res05x converted?

QUESTION THIS ANSWERS
----------------------
A green gate certifies nothing if the objects it compares were built from a
stale prerequisite, or if the edited lines are not in the build at all.  This
tree has been burned by exactly that.  So, once per span: change ONE byte of
the converted source, rebuild, and require the gate to go RED at that byte's
file offset -- then restore and require it to go green again.

Five spans, five perturbations, one per span, each in a different directive
kind (.ascii, .long, .short scalar, .short row, .byte row) so the answer is
not "one line happened to be live".

WHAT PASS MEANS
    for every case: the gate's exit status is non-zero AND its report names the
    perturbed byte's FILE OFFSET (cpu address minus 0xF00000 -- the gate speaks
    in offsets, and reading its message as a cpu address is how this check
    first reported a false 'does not name it').

RUN, from the wsa1/ directory:
    python3 notes/prom_b_res05x_gate_perturbation.py
Costs five incremental rebuilds of the four WSA1R images.
"""
import os
import subprocess
import sys

SRC = "prom_b/wsa1_prom_b.s"
BASE = 0xF00000

# (span, exact source text, replacement differing in ONE byte, cpu address)
CASES = [
    ("F03F81",
     '\t.short 0x007A\n\t.short 0x0005\n\t.ascii "AMPLITUDE"',
     '\t.short 0x007A\n\t.short 0x0005\n\t.ascii "BMPLITUDE"', 0xF03F82),
    ("F04D14",
     '\t.long 0x00F04D1F\t; +0x07 -> XIY: string table',
     '\t.long 0x00F04D2F\t; +0x07 -> XIY: string table', 0xF04D17),
    ("F0540B",
     '\t.short 0x0A32\t; +0x0D -> IX',
     '\t.short 0x0A33\t; +0x0D -> IX', 0xF05414),
    ("F05792",
     '\t.short 0x000E, 0x006D, 0x0100, 0x0089\t; [2]',
     '\t.short 0x000F, 0x006D, 0x0100, 0x0089\t; [2]', 0xF057A8),
    ("F05CEC",
     '\t.byte\t0x80, 0x60, 0x30, 0x50, 0x88, 0x0F, 0x08, 0x08, 0x10, 0x10, 0x60, 0x80',
     '\t.byte\t0x81, 0x60, 0x30, 0x50, 0x88, 0x0F, 0x08, 0x08, 0x10, 0x10, 0x60, 0x80',
     0xF05CEC),
]


def gate():
    r = subprocess.run(["make", "-C", "..", "gate-wsa1"], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def write(text):
    # encode first, then replace: writing through a latin-1 text handle
    # truncates the file to zero if any character will not fit.
    tmp = SRC + ".perturb.tmp"
    with open(tmp, "wb") as f:
        f.write(text.encode("latin-1"))
    os.replace(tmp, SRC)


def main():
    orig = open(SRC, encoding="latin-1").read()
    rc = 0
    try:
        for span, old, new, addr in CASES:
            n = orig.count(old)
            assert n == 1, "%s: anchor occurs %d times, need exactly 1" % (span, n)
            write(orig.replace(old, new))
            status, txt = gate()
            off = addr - BASE
            named = ("0x%X" % off).lower() in txt.lower()
            ok = status != 0 and named
            print("%s  one byte changed at 0x%06X (file offset 0x%X): gate %s, %s"
                  % (span, addr, off,
                     "RED" if status else "GREEN -- THE GATE IS BLIND HERE",
                     "and names that offset" if named else "but does NOT name it"))
            for line in txt.splitlines():
                if "DIFFERS" in line or "FAIL" in line:
                    print("      | " + line.strip())
            rc |= 0 if ok else 1
    finally:
        write(orig)
    status, txt = gate()
    print("restored: gate %s" % ("GREEN" if status == 0 else "RED -- RESTORE FAILED"))
    rc |= 0 if status == 0 else 1
    print("\nPASS: the gate sees every converted span." if rc == 0
          else "\nFAIL: see above.")
    return rc


if __name__ == "__main__":
    sys.exit(main())
