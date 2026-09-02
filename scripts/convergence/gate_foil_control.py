#!/usr/bin/env python3
"""
QUESTION ANSWERED
-----------------
"Can the ROM byte gate still SEE a wrong byte on a line this lane rewrote?"

A gate that was never shown to fail on the edit under test has certified
nothing (lane brief, "The gate is the only certification").  This script is
that demonstration, made repeatable: it perturbs ONE converted line in the
smallest KN5000 image, rebuilds that image, and asserts the gate goes RED --
then restores the line and asserts it goes GREEN again.

⚠ The control must be a PURE, SYNTHETIC perturbation, not a real defect.  The
address is bumped by one so the encoded byte string must change; nothing in
the tree depends on the perturbed value.

RESULT, 2026-09-02, on the line converted by the lda_24 family:

    subcpu/boot/kn5000_subcpu_boot.s:1048
        lda xwa, (0x120000:24)   ->   lda xwa, (0x120001:24)
    kn5000_subcpu_boot   1 BYTES DIFFER      FAIL: 1 target(s) differ.
    restored             IDENTICAL           PASS

EXACT COMMAND (from the tree root):

    python3 scripts/convergence/gate_foil_control.py

It leaves the tree exactly as it found it.  It refuses to run if the target
line is not the expected text, so it cannot silently perturb something else
after the file has moved.
"""
import os
import subprocess
import sys

FILE = "subcpu/boot/kn5000_subcpu_boot.s"
LINENO = 1048                       # 1-based
GOOD = "\tlda xwa, (0x120000:24)"
FOIL = "\tlda xwa, (0x120001:24)"
TARGET = "rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom"
IMAGE = "kn5000_subcpu_boot"


def set_line(text):
    src = open(FILE, encoding="latin-1").read()
    lines = src.split("\n")
    cur = lines[LINENO - 1]
    if cur not in (GOOD, FOIL):
        sys.exit("REFUSING: %s:%d is %r, not the line this control pins"
                 % (FILE, LINENO, cur))
    lines[LINENO - 1] = text
    with open(FILE, "w", encoding="latin-1") as f:
        f.write("\n".join(lines))


def gate_verdict():
    subprocess.run(["make", TARGET], stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)
    p = subprocess.run(["python3", "scripts/analysis/assert_byte_identical.py"],
                       capture_output=True, text=True)
    for ln in p.stdout.split("\n"):
        if IMAGE in ln:
            return ln.strip(), p.returncode
    return "(no verdict line for %s)" % IMAGE, p.returncode


def main():
    if not os.path.exists(FILE):
        sys.exit("run me from the tree root")
    try:
        set_line(FOIL)
        red, rc_red = gate_verdict()
        print("foiled   %-40s rc=%d" % (red, rc_red))
    finally:
        set_line(GOOD)
    green, rc_green = gate_verdict()
    print("restored %-40s rc=%d" % (green, rc_green))

    ok = ("DIFFER" in red) and rc_red != 0 and ("IDENTICAL" in green) \
        and rc_green == 0
    print("\n%s: the gate %s see a wrong byte on a converted line."
          % ("PASS" if ok else "FAIL", "can" if ok else "does NOT"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
