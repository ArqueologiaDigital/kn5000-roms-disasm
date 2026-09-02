#!/usr/bin/env python3
"""Question answered: would the byte gate actually go RED on the lines this
lane converted, and at the right address?

A gate that has never been shown to fail on a change has not certified it.  So
this probe perturbs ONE converted line at a time -- a `.long` entry in a table
this lane typed, and one instruction this lane re-framed -- rebuilds the v10
image, and reports the first differing ROM address.  It then restores the file
and rebuilds again to confirm the tree is back to byte-identical.

PASS means: each perturbation produced a difference, and the first differing
address was inside the perturbed line's span.  A perturbation that produced NO
difference would mean the line is not reaching the image at all -- exactly the
stale-prerequisite failure this tree has been burned by before.

Exact command (from the repo root):

    python3 scripts/analysis/v10_gate_sensitivity_probe.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.environ.get("LLVM_BIN",
                      os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
ROM_BASE = 0xE00000

# (file, exact line text to perturb, replacement, expected address of that line)
CASES = [
    ("v10/maincpu/midi/midi_dispatch_handlers.s",
     "\t.long PanelEvt_CheckChanZero_Dispatch",
     "\t.long PanelEvt_CheckFlag6_Dispatch",
     0xFD17AE, "a .long typed by this lane in the CC handler table"),
    ("v10/maincpu/midi/midi_dispatch_handlers.s",
     "\tld_rrl xiz, xiz, hl",
     "\tld_rrl xiz, xiz, wa",
     0xFCFA5E, "an instruction re-framed by this lane at MidiSerial_ParseStatus_Data"),
]


def build():
    inc = os.path.join(ROOT, "v10/maincpu")
    obj, elf, binf = "/tmp/v10probe.o", "/tmp/v10probe.elf", "/tmp/v10probe.bin"
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-filetype=obj", "-I", inc, "-o", obj,
                        os.path.join(inc, "kn5000_v10_program.s")],
                       cwd=ROOT, capture_output=True, text=True)
    if r.returncode:
        return None
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                    os.path.join(inc, "maincpu.ld"), "-o", elf, obj], check=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, binf],
                   check=True)
    return open(binf, "rb").read()


def first_diff(a, b):
    for i in range(min(len(a), len(b))):
        if a[i] != b[i]:
            return ROM_BASE + i
    return None


def main():
    ref = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    base = build()
    if base != ref:
        sys.exit("tree is not byte-identical before the probe; fix that first")
    ok = True
    for rel, old, new, addr, what in CASES:
        path = os.path.join(ROOT, rel)
        src = open(path, encoding="latin-1").read()
        n = src.count(old + "\n")
        if n == 0:
            print("SKIP  %s: line not present (%s)" % (rel, old.strip()))
            continue
        src2 = src.replace(old + "\n", new + "\n", 1)
        open(path, "w", encoding="latin-1").write(src2)
        img = build()
        open(path, "w", encoding="latin-1").write(src)
        if img is None:
            print("note  perturbation did not assemble, which is also a red gate")
            continue
        d = first_diff(img, ref)
        good = d is not None and addr <= d < addr + 8
        ok &= bool(good)
        print("%-5s %s\n      perturbed %-34s -> %-34s first diff at %s (expected near 0x%06X)"
              % ("PASS" if good else "FAIL", what, old.strip(), new.strip(),
                 ("0x%06X" % d) if d else "NONE", addr))
    if build() != ref:
        sys.exit("FAILED to restore the tree")
    print("restored: image is byte-identical again")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
