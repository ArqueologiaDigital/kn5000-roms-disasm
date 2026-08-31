#!/usr/bin/env python3
"""llvm_roundtrip_force.py, with the --force list discovered automatically.

QUESTION IT ANSWERS
  "What does this range say, in a form the gate will accept, when llvm-mc
   DISASSEMBLES an instruction into a spelling its own ASSEMBLER then rejects?"

WHY IT EXISTS (written 2026-08-25 while converting the SC1 module)
  There are three separate failure modes when round-tripping TLCS-900 bytes, and
  the tree had tools for only two of them:

    1. assembles, but to different bytes      -> scripts/analysis/llvm_roundtrip.py
    2. assembles, but to a different WIDTH    -> notes/llvm_roundtrip_force.py
    3. DOES NOT ASSEMBLE AT ALL               -> this script

  Mode 3 makes llvm-mc exit with "error: invalid operand for instruction" and
  both earlier scripts stop with the raw compiler error, because there is no
  output to diff.  The shapes that do it in prom_b 0xF5A800-0xF5B44D are

      ld WA,(0x80)        (D0 80 20)   -> LLVM prints `ld_sd8b wa, 128`
      add IY,(0x2ae0)     (D1 e0 2a 85)-> LLVM prints `addda16 iy, (10976)`
      sub WA,(0x2a90)     (D1 90 2a a0)-> LLVM prints `subda16 wa, (10896)`

  i.e. 16-bit-operand instructions with an ABSOLUTE memory operand.  LLVM's
  TLCS-900 disassembler emits a mnemonic its parser does not accept.

HOW
  Run the forcing wrapper; if it dies with assembler errors, harvest the ROM
  addresses out of the trailing `; ADDR  <mame text>` comment that
  llvm_roundtrip.py puts on every line, add them to --force, and go again.
  Loop until it converges.  ⚠ Nothing here weakens the proof: the wrapper still
  assembles the whole candidate listing and compares it byte for byte with the
  ROM before printing, so a listing this script prints is guaranteed to rebuild
  the range it came from.

RUN
  python3 notes/llvm_roundtrip_autoforce.py b 0xF5A800 0x467
  python3 notes/llvm_roundtrip_autoforce.py b 0xF5A800 0x467 --quiet
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WRAPPER = os.path.join(ROOT, "notes", "llvm_roundtrip_force.py")


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    img, addr, ln = sys.argv[1], sys.argv[2], sys.argv[3]
    quiet = "--quiet" in sys.argv
    forced = set()
    for attempt in range(200):
        cmd = [sys.executable, WRAPPER, img, addr, ln]
        if forced:
            cmd += ["--force", ",".join("0x%06X" % a for a in sorted(forced))]
        p = subprocess.run(cmd, capture_output=True, text=True)
        if p.returncode == 0:
            if not quiet:
                sys.stderr.write(p.stderr)
            sys.stdout.write(p.stdout)
            return 0
        new = {int(m, 16) for m in re.findall(r";\s*([0-9A-F]{6})\s", p.stderr)}
        new -= forced
        if not new:
            sys.stderr.write(p.stderr)
            sys.stderr.write("  autoforce: no new offender found, giving up\n")
            return p.returncode
        forced |= new
    sys.stderr.write("  autoforce: too many rounds\n")
    return 4


if __name__ == "__main__":
    sys.exit(main())
