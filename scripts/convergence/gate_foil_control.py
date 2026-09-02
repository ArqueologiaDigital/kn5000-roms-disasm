#!/usr/bin/env python3
"""
QUESTION ANSWERED
-----------------
"Can the ROM byte gate still SEE a wrong byte on a line THIS lane changed?"

A gate that was never shown to fail on the edit under test has certified
nothing (lane brief, "The gate is the only certification").  Every claim of
the shape *"the gate is green, therefore the conversion is correct"* rests on
this control, so the control belongs in the repo, not in a lane's scratch.

WHAT IT DOES
------------
Substitutes one line of one source, rebuilds the single image that line
belongs to, and asserts the byte gate goes RED -- then restores the line and
asserts it goes GREEN again.  It leaves the tree exactly as it found it, and
it refuses to touch a line that is not already one of the two texts it was
given, so it cannot silently perturb something else after a file has moved.

⚠ The perturbation must be SYNTHETIC, not a real defect.  A control built out
of a real bug dies the day the bug is fixed (lane brief: "a control that dies
when its bug is fixed is not a control").  Bumping an address by one is
arbitrary, is guaranteed to change the encoded bytes, and nothing in the tree
depends on the perturbed value.

EXACT COMMANDS (from the tree root)
-----------------------------------
This lane's control, which is also the default:

    python3 scripts/convergence/gate_foil_control.py

Any other line, for any other lane:

    python3 scripts/convergence/gate_foil_control.py \
        --file  subcpu/boot/kn5000_subcpu_boot.s \
        --line  1048 \
        --good  $'\tlda xwa, (0x120000:24)' \
        --foil  $'\tlda xwa, (0x120001:24)' \
        --image kn5000_subcpu_boot \
        --target rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom

Add `--make-var LLVM_MC=<path>` (repeatable) to pin the assembler -- the
shared build is re-linked in place by backend lanes, and a control taken with
a different binary than the gate proves nothing about that gate.

`--image` is the substring the gate's own verdict line is matched on;
`--target` is the make target that rebuilds just that image, so the control
costs one image instead of nine.

RESULT ON THIS LANE, 2026-09-02 (llvm-mc snapshot sha256 53c6621d5f6dd3c1)
-------------------------------------------------------------------------
    subcpu/boot/kn5000_subcpu_boot.s:1048, a line converted by the lda_24
    family:  lda xwa, (0x120000:24)  ->  lda xwa, (0x120001:24)

    foiled     kn5000_subcpu_boot   1 BYTES DIFFER   rc=1
    restored   kn5000_subcpu_boot   IDENTICAL        rc=0
    PASS: the gate can see a wrong byte on a converted line.
"""
import argparse
import os
import subprocess
import sys

# This lane's control, kept as the default so the committed evidence is one
# command away.  Any lane may point it somewhere else.
DEF_FILE = "subcpu/boot/kn5000_subcpu_boot.s"
DEF_LINE = 1048                                   # 1-based
DEF_GOOD = "\tlda xwa, (0x120000:24)"
DEF_FOIL = "\tlda xwa, (0x120001:24)"
DEF_TARGET = "rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom"
DEF_IMAGE = "kn5000_subcpu_boot"
GATE = "scripts/analysis/assert_byte_identical.py"


def set_line(path, lineno, text, allowed):
    """⚠ latin-1 in, latin-1 out.  These sources carry raw high bytes inside
    .ascii literals and a UTF-8 round trip silently replaces them."""
    lines = open(path, encoding="latin-1").read().split("\n")
    if lineno < 1 or lineno > len(lines):
        sys.exit("REFUSING: %s has no line %d" % (path, lineno))
    cur = lines[lineno - 1]
    if cur not in allowed:
        sys.exit("REFUSING: %s:%d is %r, not a line this control pins"
                 % (path, lineno, cur))
    lines[lineno - 1] = text
    with open(path, "w", encoding="latin-1") as f:
        f.write("\n".join(lines))


def gate_verdict(target, image, make_vars):
    subprocess.run(["make"] + list(make_vars) + [target],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    p = subprocess.run(["python3", GATE], capture_output=True, text=True)
    for ln in p.stdout.split("\n"):
        if image in ln:
            return ln.strip(), p.returncode
    return "(no verdict line for %s)" % image, p.returncode


def main():
    ap = argparse.ArgumentParser(
        description="prove the ROM byte gate can go red on one changed line")
    ap.add_argument("--file", default=DEF_FILE)
    ap.add_argument("--line", type=int, default=DEF_LINE,
                    help="1-based line number")
    ap.add_argument("--good", default=DEF_GOOD,
                    help="the line's correct text, restored at the end")
    ap.add_argument("--foil", default=DEF_FOIL,
                    help="the synthetic wrong text; must encode differently")
    ap.add_argument("--target", default=DEF_TARGET,
                    help="make target rebuilding just the affected image")
    ap.add_argument("--image", default=DEF_IMAGE,
                    help="substring identifying that image in the gate output")
    ap.add_argument("--make-var", action="append", default=[], metavar="V=X",
                    help="passed to make, e.g. LLVM_MC=/path/to/llvm-mc")
    args = ap.parse_args()

    if not os.path.exists(GATE):
        sys.exit("run me from the tree root (%s not found)" % GATE)
    if args.good == args.foil:
        sys.exit("REFUSING: --foil is identical to --good, so it can never "
                 "make the gate fail")
    allowed = (args.good, args.foil)

    try:
        set_line(args.file, args.line, args.foil, allowed)
        red, rc_red = gate_verdict(args.target, args.image, args.make_var)
        print("foiled   %-40s rc=%d" % (red, rc_red))
    finally:
        set_line(args.file, args.line, args.good, allowed)
    green, rc_green = gate_verdict(args.target, args.image, args.make_var)
    print("restored %-40s rc=%d" % (green, rc_green))

    ok = ("DIFFER" in red and rc_red != 0
          and "IDENTICAL" in green and rc_green == 0)
    print("\n%s: the gate %s see a wrong byte on a converted line."
          % ("PASS" if ok else "FAIL", "can" if ok else "does NOT"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
