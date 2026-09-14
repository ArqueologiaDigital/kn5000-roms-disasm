#!/usr/bin/env python3
"""op72_live.py -- read the C-RAM map out of a KN5000 uC-IF capture, and compare across settings.

Companion to `op72_live.sh'; see that file for why this exists (N-INPUT-GATE-OPENED sect. 170: the
`op 0x72' cells store a hard-coded DEFAULT, so sect. 153's gain law has no stored output in the ROM
to check against, and the only remaining route is to MOVE the parameter and capture what the
evaluator writes).

    python3 dsp/tools/op72_live.py <dir> <NVALUE> [<NVALUE> ...]

The replay is `lfo_ramp.cram_of_algo''s, pointed at a capture instead of the ROM: a
`801.0.NN.821' word sets the C-RAM pointer and the `cmd 0x02' records that follow carry 24-bit
coefficients which land there, auto-incrementing.  PROVEN BY CONSTRUCTION for the writer
(LABEL_0387E6); K3 confirmed the host-stream and in-program meanings are the same space.

⚠ READ THE DIFF FIRST.  If no cell moves between two NVALUE settings the navigation never reached
an editable parameter, and nothing else here means anything -- sect. 97 and sect. 100 each paid a
run for that lesson.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402

XFER = re.compile(r"^transfer\s+\d+:\s+cmd 0x([0-9A-Fa-f]{2})\s+(\d+) bytes")
HEX = re.compile(r"^\s*[0-9A-Fa-f]{4}:((?:\s+[0-9A-Fa-f]{2})+)\s*$")

#  op 0x72's operands in the two carriers (host_coeff_map, corroborated at indices (0,0)/(1,0)).
OP72 = {0x04, 0x0D, 0x0A, 0x19}


def transfers(path):
    """[(cmd, payload bytes)] from one kn5000_dsp1_upload.txt."""
    out, cur, cmd = [], None, None
    for ln in open(path, errors="replace"):
        m = XFER.match(ln)
        if m:
            if cur is not None:
                out.append((cmd, bytes(cur)))
            cmd, cur = int(m.group(1), 16), []
            continue
        h = HEX.match(ln)
        if h and cur is not None:
            cur.extend(int(x, 16) for x in h.group(1).split())
    if cur is not None:
        out.append((cmd, bytes(cur)))
    return out


def cram_of_capture(path):
    """{C-RAM cell: 24-bit value} -- the replay lfo_ramp.cram_of_algo does, on a capture."""
    #  ⚠ EVERY cmd 0x01 / 0x02 payload opens with a 2-BYTE WORD ADDRESS -- the capture's own
    #  header says so ("Command 0x01 payloads are a 16-bit word address + N*5 bytes") and the
    #  transfers confirm it (7 = 2 + 5, 92 = 2 + 30*3).  Reading from offset 0 instead of 2
    #  misaligns every group: the first version of this file found ZERO C-RAM cells and ZERO
    #  pointer loads, which looked exactly like "nothing moved".  The instrument, not the machine.
    cram, ptr = {}, None
    for cmd, pl in transfers(path):
        if cmd == 0x02:
            for k in range(2, len(pl) - 2, 3):
                if ptr is not None:
                    cram[ptr] = (pl[k] << 16) | (pl[k + 1] << 8) | pl[k + 2]
                    ptr = (ptr + 1) & 0xFF
        elif cmd == 0x01:
            for k in range(2, len(pl) - 4, 5):
                w = int.from_bytes(pl[k:k + 5], "big")
                if DIS.hi12(w) == 0x801 and DIS.class4(w) == 0 and DIS.lo12(w) == 0x821:
                    ptr = DIS.addr8(w)
    return cram


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    d, vals = sys.argv[1], sys.argv[2:]
    maps = {}
    for v in vals:
        p = os.path.join(d, "v%s.upload.txt" % v)
        if os.path.exists(p):
            maps[v] = cram_of_capture(p)
    print("=" * 92)
    print("  op72_live -- C-RAM across parameter settings  (%s)" % d)
    print("=" * 92)
    if not maps:
        print("\n  NO CAPTURES.  The runs did not produce kn5000_dsp1_upload.txt.")
        return 1
    for v in vals:
        if v in maps:
            print("\n  NVALUE %-4s : %d C-RAM cells" % (v, len(maps[v])))

    base = vals[0]
    if base not in maps:
        return 1
    print("\n  ★ CELLS THAT MOVE relative to NVALUE %s:\n" % base)
    moved = 0
    for v in vals[1:]:
        if v not in maps:
            continue
        diff = sorted(c for c in set(maps[base]) | set(maps[v])
                      if maps[base].get(c) != maps[v].get(c))
        moved += len(diff)
        print("     NVALUE %-4s : %d cells move   %s"
              % (v, len(diff),
                 " ".join("%02X:%06X->%06X" % (c, maps[base].get(c, 0), maps[v].get(c, 0))
                          for c in diff[:8]) or "(none)"))
        for c in diff:
            if c in OP72:
                print("        ★★★ op 0x72 CELL %02X MOVED: %06X -> %06X"
                      % (c, maps[base].get(c, 0), maps[v].get(c, 0)))
    if not moved:
        print("     ⛔ NOTHING MOVED.  The navigation did not reach an editable parameter --")
        print("        so this run says nothing about the law.  Check NPARAM/TYPEIDX before")
        print("        reading any other column (the sect. 97 / sect. 100 lesson).")
    print("\n  op 0x72 cells in each capture:")
    for v in vals:
        if v in maps:
            print("     NVALUE %-4s : %s" % (v, " ".join(
                "%02X=%06X" % (c, maps[v][c]) for c in sorted(OP72) if c in maps[v]) or "none present"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
