#!/usr/bin/env python3
"""Which SED1330 command bytes does this firmware actually write?

QUESTION IT ANSWERS: "every byte written to the LCD controller's COMMAND port
0x790001 -- what are they, and where?"

WHY IT EXISTS.  notes/FINDINGS-display-controller.md identified the controller
from a census of command bytes, but that census only saw the 24-bit direct form
`ld (0x790001),n`.  The driver reaches the port far more often through a BASE
REGISTER (`ld XIZ,0x00790000` once, then `ld (XIZ+0x01),n` repeatedly), and
those writes were invisible to it -- CSRDIR DOWN (0x4F) is written five times
and was missing from the table.  This script covers both forms.

METHOD, and its limits:
  1. Find every `ld XIX/XIY/XIZ/XBC, 0x00790000` (opcodes 0x44/0x45/0x46/0x41
     followed by 00 00 79 00).  Because a 32-bit immediate load of this exact
     value is a five-byte pattern with three fixed bytes, false positives are
     possible; each one is CONFIRMED by disassembling from it -- unidasm has to
     agree that the instruction at that offset is that load.
  2. Disassemble forward from each confirmed load with unidasm, which
     self-synchronises from a known instruction boundary, until `ret`/`reti`
     or a byte budget runs out, and collect every `ld (Rn+0x01),0xNN` (the
     command port) and `ld (Rn),0xNN` (the data port) for that same register.
  3. Separately find the 24-bit direct form `F2 01 00 79 00 <imm>` and confirm
     each hit the same way.

⚠ WHAT IT DOES NOT DO: it does not follow a base register across a call, and it
stops at the first return, so a command written after a `ret` inside the same
routine, or through a register loaded elsewhere, is not counted.  The output is
therefore a LOWER BOUND on the sites, not a proof of completeness.

    python3 notes/lcd_command_census.py            # the table
    python3 notes/lcd_command_census.py --sites    # every site, by byte
"""
import os
import re
import subprocess
import sys
import tempfile
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
IMGS = [("prom_a", os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
        ("prom_b", os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000)]
REGOPC = {0x41: "XBC", 0x44: "XIX", 0x45: "XIY", 0x46: "XIZ"}
# MAME sed1330.cpp:23-39
SED1330 = {0x40: "SYSTEM SET", 0x42: "MWRITE", 0x43: "MREAD", 0x44: "SCROLL",
           0x46: "CSRW", 0x47: "CSRR", 0x4C: "CSRDIR RIGHT", 0x4D: "CSRDIR LEFT",
           0x4E: "CSRDIR UP", 0x4F: "CSRDIR DOWN", 0x53: "SLEEP IN",
           0x58: "DISP OFF", 0x59: "DISP ON", 0x5A: "HDOT SCR", 0x5B: "OVLAY",
           0x5C: "CGRAM ADR", 0x5D: "CSRFORM"}
LINE = re.compile(r"^([0-9a-f]{6}): ((?:[0-9a-f]{2} )+)\s*(.*)$")


def dis(data, base, off, n):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[off:off + n])
        path = f.name
    try:
        out = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc",
                              hex(base + off)], capture_output=True, text=True).stdout
    finally:
        os.unlink(path)
    rows = []
    for ln in out.splitlines():
        m = LINE.match(ln)
        if m:
            rows.append((int(m.group(1), 16), m.group(2).strip(), m.group(3).strip()))
    return rows


def main():
    hits = collections.defaultdict(list)     # command byte -> sites
    for name, path, base in IMGS:
        d = open(path, "rb").read()
        starts = []
        for i in range(len(d) - 5):
            if d[i] in REGOPC and d[i + 1:i + 5] == b"\x00\x00\x79\x00":
                starts.append((i, REGOPC[d[i]]))
        for off, reg in starts:
            rows = dis(d, base, off, 400)
            if not rows or ("0x00790000" not in rows[0][2]):
                continue                      # not really that instruction
            want_cmd = "ld (%s+0x01)," % reg
            want_dat = "ld (%s)," % reg
            for addr, by, txt in rows[1:]:
                if txt.startswith("ret") or txt.startswith("reti"):
                    break
                for want, is_cmd in ((want_cmd, True), (want_dat, False)):
                    if txt.startswith(want) and txt[len(want):].startswith("0x"):
                        val = int(txt[len(want):], 16)
                        if is_cmd:
                            hits[val].append("%s 0x%06X (%s+1)" % (name, addr, reg))
        # the 24-bit direct form
        i = 0
        pat = b"\xF2\x01\x00\x79\x00"
        while True:
            i = d.find(pat, i)
            if i < 0:
                break
            rows = dis(d, base, i, 8)
            if rows and rows[0][2].startswith("ld (0x790001),"):
                hits[d[i + 5]].append("%s 0x%06X (direct)" % (name, base + i))
            i += 1
    print("command bytes written to 0x790001:")
    unknown = []
    for v in sorted(hits):
        nm = SED1330.get(v)
        if nm is None:
            unknown.append(v)
        print("  0x%02X  %-14s %d site(s)" % (v, nm or "*** NOT A SED1330 COMMAND ***",
                                              len(hits[v])))
        if "--sites" in sys.argv:
            for s in hits[v]:
                print("          " + s)
    print("\n%d distinct bytes, %d sites, %d outside MAME's SED1330 table%s"
          % (len(hits), sum(len(v) for v in hits.values()), len(unknown),
             (": " + ", ".join("0x%02X" % u for u in unknown)) if unknown else ""))


if __name__ == "__main__":
    main()
