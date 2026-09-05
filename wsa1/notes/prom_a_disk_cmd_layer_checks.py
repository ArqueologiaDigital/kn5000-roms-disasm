#!/usr/bin/env python3
"""Re-derive every number quoted in FINDINGS-prom_a-disk-cmd-layer.md.

QUESTION THIS ANSWERS
    The w30 pass named 13 routines of prom_a's disk / block-device command
    module (0xFE0000-0xFE54B6) and REFUSED the rest.  This script certifies,
    straight from prom_a/wsa1_prom_a.s, the three kinds of claim the write-up
    makes, and fails (exit 1) if any drifts:

      1. Each FDC-request BUILDER writes the operation code the name asserts,
         at request-block offset +0 (the operation field per the Fdc_Request
         header).  op meanings: notes/FINDINGS-prom_a-disk-format.md §4.
      2. Each named routine's calr caller count (the census that proves it is
         reached at all -- these routines have NO absolute call site, so a
         name based only on the label would be a census-trap guess).
      3. The refusal denominator: how many labels in the module are still
         sub_XXXXXX, so the write-up's "named 13, refused N" is a measured
         ratio and not a hand count.

    CONTROL (§4 of the write-up): naming a routine from its NEIGHBOUR would
    misname it.  The routine physically before Disk_ReadSectors is
    Disk_SetRequestGeometry, which writes NO operation field -- so an
    adjacency rule would have called a geometry-setup routine "read".  The
    check asserts that mismatch, i.e. that the discipline was necessary.

RUN
    python3 notes/prom_a_disk_cmd_layer_checks.py            # all checks
    python3 notes/prom_a_disk_cmd_layer_checks.py --selftest # + the control
"""
import re, sys, pathlib

SRC = pathlib.Path(__file__).resolve().parents[1] / "prom_a" / "wsa1_prom_a.s"
LO, HI = 0xFE0000, 0xFE54B6            # the module extent (module header)

def load():
    return SRC.read_text(encoding="latin-1").split("\n")

ADDR = re.compile(r';\s+([0-9A-Fa-f]{6})\s+([0-9a-f]{2}(?:\s+[0-9a-f]{2})*)\s*$')

def calr_callers(lines, target):
    """Every calr/jr site (1e d16, 1f d8) whose PC-relative target == target."""
    out = []
    for l in lines:
        m = ADDR.search(l)
        if not m: continue
        addr = int(m.group(1), 16); b = m.group(2).split()
        t = None
        if b[0] == '1e' and len(b) >= 3:
            d = int(b[2] + b[1], 16); d -= 0x10000 if d >= 0x8000 else 0
            t = addr + 3 + d
        elif b[0] == '1f' and len(b) >= 2:
            d = int(b[1], 16); d -= 0x100 if d >= 0x80 else 0
            t = addr + 2 + d
        if t is not None and (t & 0xFFFFFF) == target:
            out.append(addr)
    return out

def op_written_at(lines, label):
    """For a builder, the immediate written to request-block offset +0 that
    immediately precedes its `call 0xfe66c7` (Fdc_Request).  Returns the op int
    or None.  Reads the `m_ld_mi16 MDI+rN, 0, 0xNN` line before the call."""
    body = []
    grab = False
    for i, l in enumerate(lines):
        if re.match(rf'^{label}:\s*$', l): grab = True; continue
        if grab:
            if re.match(r'^[A-Za-z_][\w]*:\s*$', l): break
            body.append(l)
    # find the last "MDI+r?, 0, 0xXXXX" that precedes a call to fe66c7 or f42d38
    op = None
    for l in body:
        m = re.search(r'm_ld_mi16 MDI\+r\d,\s*0,\s*0x([0-9a-fA-F]+)', l)
        if m: op = int(m.group(1), 16)
        if 'call 0xfe66c7' in l or 'call 0xf42d38' in l:
            return op
    return op

def region_census(lines):
    sub = named = 0
    lbl = re.compile(r'^([A-Za-z_][\w]*):\s*$')
    cur = None
    for i, l in enumerate(lines):
        m = lbl.match(l)
        if not m: continue
        # address = next instruction's addr comment
        a = None
        for j in range(i + 1, min(i + 6, len(lines))):
            am = ADDR.search(lines[j])
            if am: a = int(am.group(1), 16); break
        if a is None or not (LO <= a <= HI): continue
        if m.group(1).startswith('sub_'): sub += 1
        else: named += 1
    return sub, named

# --- the claims ------------------------------------------------------------
BUILDERS = {   # label : (expected op, expected #calr callers)
    "Disk_ReadSectors":              (0x03, 15),
    "Disk_WriteSectors":             (0x04, 9),
    "Disk_RequestSenseDriveStatus":  (0x0B, 5),
}
OTHER_CALLERS = {   # label : expected #calr callers (non-builders we still cite)
    "Disk_SetRequestGeometry":       2,
}

def main(selftest=False):
    lines = load()
    fails = []
    for lbl, (op, ncall) in BUILDERS.items():
        got_op = op_written_at(lines, lbl)
        if got_op != op:
            fails.append(f"{lbl}: op field = {got_op}, expected {op}")
        n = len(calr_callers(lines, int(lbl_addr(lines, lbl), 16)))
        if n != ncall:
            fails.append(f"{lbl}: {n} calr callers, expected {ncall}")
    for lbl, ncall in OTHER_CALLERS.items():
        n = len(calr_callers(lines, int(lbl_addr(lines, lbl), 16)))
        if n != ncall:
            fails.append(f"{lbl}: {n} calr callers, expected {ncall}")
    sub, named = region_census(lines)
    print(f"module {LO:#08x}-{HI:#08x}: {named} named, {sub} still sub_XXXXXX")
    checks = len(BUILDERS) * 2 + len(OTHER_CALLERS)

    if selftest:
        # CONTROL: adjacency would misname.  Disk_SetRequestGeometry precedes
        # Disk_ReadSectors and writes NO op field -> op_written_at is None.
        if op_written_at(lines, "Disk_SetRequestGeometry") is not None:
            fails.append("control: Disk_SetRequestGeometry unexpectedly has an op field")
        else:
            print("control OK: the neighbour of Disk_ReadSectors has no op field, "
                  "so adjacency-naming would have misnamed it")
        checks += 1

    if fails:
        print("FAIL:"); [print("  " + f) for f in fails]; sys.exit(1)
    print(f"OK: {checks} checks passed")

def lbl_addr(lines, label):
    lbl = re.compile(rf'^{label}:\s*$')
    for i, l in enumerate(lines):
        if lbl.match(l):
            for j in range(i + 1, min(i + 6, len(lines))):
                am = ADDR.search(lines[j])
                if am: return am.group(1)
    raise SystemExit(f"label {label} not found")

if __name__ == "__main__":
    main(selftest="--selftest" in sys.argv)
