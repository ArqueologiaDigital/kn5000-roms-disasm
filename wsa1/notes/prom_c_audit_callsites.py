#!/usr/bin/env python3
"""Does every address a "Called from:" line names actually START a call to that routine?

WHY THIS EXISTS
  This tree's own history includes "call sites cited one byte past the instruction, ~20 times,
  systematically".  The cause is easy to see once you know it: `notes/prom_c_xrefs.py` prints
  the address of the LITERAL it matched, and the instruction that owns the literal begins one
  or two bytes earlier.  Copying the tool's address into a header is therefore wrong by
  default, and the byte gate cannot see it.

  This re-checks every such claim mechanically:

    1. it parses `prom_c/wsa1_prom_c.s` for `; Called from:` blocks, collecting every
       0xXXXXXX address mentioned before the next `; Inputs:` / `; Evidence:` line;
    2. it takes the routine's own address from the `; ADDR` comment on the first instruction
       line after the label;
    3. it disassembles ONE instruction at each cited address and checks that it is a
       call/calr/jp/jrl whose target is that routine.

  Anything that is not is printed.  Some of what it prints is legitimate -- a header may cite
  the address of a *pointer table entry*, or the caller may reach the routine through a
  register -- so the output is a list to READ, not a pass/fail.  It is the tool for a
  self-audit before shipping a pass, and its value is that it cannot be fooled by prose.

RUN
  python3 notes/prom_c_audit_callsites.py
  python3 notes/prom_c_audit_callsites.py --quiet     # only the rows that did not check out
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
IMG = open(ROM, "rb").read()

ADDR = re.compile(r'0x([0-9A-Fa-f]{6})')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
INSTR_ADDR = re.compile(r';\s*([0-9A-F]{6})\s')


def dis1(addr):
    off = addr - BASE
    if not (0 <= off < len(IMG)):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(IMG[off:off + 12])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    first = p.stdout.splitlines()
    return first[0] if first else None


def main():
    quiet = "--quiet" in sys.argv
    lines = open(SRC).read().splitlines()
    pending, rows = [], []
    i = 0
    while i < len(lines):
        ln = lines[i]
        if "; Called from:" in ln:
            pending = []
            j = i
            while j < len(lines) and lines[j].startswith(";"):
                if j > i and re.match(r';\s*(Inputs|Outputs|Evidence|Unknown|Packet|Dispatch):',
                                      lines[j]):
                    break
                pending += [int(m, 16) for m in ADDR.findall(lines[j])]
                j += 1
            i = j
            continue
        m = LABEL.match(ln)
        if m and pending:
            # the routine's address is on the first instruction line after the label
            ra = None
            for k in range(i + 1, min(i + 4, len(lines))):
                mm = INSTR_ADDR.search(lines[k])
                if mm:
                    ra = int(mm.group(1), 16)
                    break
            if ra is not None:
                for a in pending:
                    if a == ra:
                        continue
                    rows.append((m.group(1), ra, a))
            pending = []
        i += 1

    bad = 0
    for name, ra, a in rows:
        txt = dis1(a) or "<undecodable>"
        body = txt.split(":", 1)[1] if ":" in txt else txt
        ok = re.search(r'\b(call|calr|jp|jrl|jr)\b', body) and ("%06x" % ra) in body.lower()
        if not ok:
            bad += 1
        if ok and quiet:
            continue
        print("%-38s -> 0x%06X  cited 0x%06X  %s   %s"
              % (name, ra, a, "OK " if ok else "?? ", txt.strip()))
    print("\n%d cited call site(s) checked, %d did not decode to a transfer to the routine"
          % (len(rows), bad))
    return 0


if __name__ == "__main__":
    sys.exit(main())
