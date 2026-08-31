#!/usr/bin/env python3
"""Inside prom_a's 0xFE54B6-0xFE68F2 module, which routine calls which?

QUESTION IT ANSWERS
    Every "Called from:" line in a routine header of that module.  The module is
    reached from outside through exactly two published entry points and three
    interrupt thunks (notes/prom_a_xref.py establishes those, because they are
    spelled with the ABSOLUTE `1D`/`1B` forms); INSIDE the module every call is
    a PC-relative `calr`, which prom_a_xref.py cannot see at all.  Round 1 of
    this lane would otherwise have had to write those lines by eye, and the
    standing lesson of this tree is that hand-written call-site claims drift
    (see the "38 routines with no site found -- all 38 had callers" entry).

WHAT IS EXACT AND WHAT IS NOT
    EXACT: the instruction boundaries.  unidasm is the decode authority and the
    whole scanned range is either already converted in prom_a/wsa1_prom_a.s or
    was produced by prom_a/roundtrip.py, which re-assembles every instruction
    and byte-compares it before printing.  So this is an instruction-anchored
    scan, not a byte-window scan, and a count from it IS a call-site count --
    unlike notes/prom_a_xref.py, whose counts are upper bounds.
    ALSO EXACT: callers OUTSIDE 0xFE54B6-0xFE68F2 that live in already-converted
    assembly.  Those are read out of prom_a/wsa1_prom_a.s's own trailing byte
    comments -- `; FEXXXX  1e lo hi` is a `calr`, `1d lo mid hi` a `call`,
    `1b lo mid hi` a `jp` -- so they are instruction-anchored too, because the
    byte gate certifies that those bytes really are that instruction.
    NOT COVERED: callers that are still inside an `.incbin`.  For those, run
    `python3 notes/prom_a_xref.py <addr>`, whose counts are upper bounds.

ROUTINE NAMES
    Taken from prom_a/wsa1_prom_a.s itself: every global label (a line matching
    `^name:`) is paired with the address in the `; FEXXXX` comment of the next
    instruction line.  So once the module is converted this script needs no
    table of its own, and it cannot disagree with the source.  Until then,
    --extra-labels FILE supplies `ADDR NAME` pairs for ranges still `.incbin`
    (notes/gen_prom_a_fdc_module.py writes that file).

RUN
    python3 notes/prom_a_fdc_callgraph.py                # every routine
    python3 notes/prom_a_fdc_callgraph.py 0xFE5E84       # one routine's callers
    python3 notes/prom_a_fdc_callgraph.py --edges        # raw caller->callee list
Exit status is non-zero only if a self-check fails.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
BASE = 0xF80000
LO, HI = 0xFE54B6, 0xFE68F3          # the module, half-open
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
ADDR_RE = re.compile(r';\s*([0-9A-F]{6})\b')
CALLISH = re.compile(r'^\s*(calr|call|jp|jrl|jr)\b', re.I)
TARGET_RE = re.compile(r'0x([0-9a-f]{6})\b')


def source_labels():
    """global label -> address, read out of prom_a/wsa1_prom_a.s."""
    out, pending = {}, []
    for line in open(SRC):
        m = LABEL_RE.match(line)
        if m:
            pending.append(m.group(1))
            continue
        m = ADDR_RE.search(line)
        if m and pending:
            a = int(m.group(1), 16)
            for name in pending:
                out.setdefault(name, a)
            pending = []
    return {a: n for n, a in out.items()}


SRCBYTES_RE = re.compile(r';\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})\s*$')


def external_sites():
    """(site, target) for every call/jp in ALREADY-CONVERTED prom_a assembly.

    Read from the source's own byte comments, so it is instruction-anchored.
    """
    out = []
    for line in open(SRC):
        m = SRCBYTES_RE.search(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        b = [int(x, 16) for x in m.group(2).split()]
        if len(b) == 3 and b[0] == 0x1E:                     # calr d16
            d = b[1] | (b[2] << 8)
            d -= 0x10000 if d & 0x8000 else 0
            out.append((addr, (addr + 3 + d) & 0xFFFFFF))
        elif len(b) == 4 and b[0] in (0x1D, 0x1B):           # call nnn / jp nnn
            out.append((addr, b[1] | (b[2] << 8) | (b[3] << 16)))
    return out


def disassemble(lo, hi):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as t:
        blob = open(ROM, "rb").read()[lo - BASE:hi - BASE]
        t.write(blob)
        path = t.name
    try:
        txt = subprocess.run([UNIDASM, path, "-arch", "tlcs900",
                              "-basepc", "0x%X" % lo],
                             capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(path)
    rows = []
    for line in txt.splitlines():
        m = re.match(r'^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            rows.append((int(m.group(1), 16), m.group(3).strip()))
    return rows


def build(extra_labels=None):
    labels = source_labels()
    if extra_labels:
        labels.update(extra_labels)
    starts = sorted(a for a in labels if LO <= a < HI)
    rows = disassemble(LO, HI)

    def owner(addr):
        lo = None
        for s in starts:
            if s <= addr:
                lo = s
            else:
                break
        return lo

    edges = []
    for addr, text in rows:
        if not CALLISH.match(text):
            continue
        for t in TARGET_RE.findall(text):
            tgt = int(t, 16)
            if tgt in labels and LO <= tgt < HI and owner(addr) != tgt:
                edges.append((addr, owner(addr), tgt))
    ext = [(site, tgt) for site, tgt in external_sites()
           if LO <= tgt < HI and not (LO <= site < HI)]
    return labels, starts, edges, ext


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    extra = None
    for f in list(flags):
        if f.startswith("--extra-labels="):
            extra = {}
            for line in open(f.split("=", 1)[1]):
                line = line.split("#")[0].strip()
                if line:
                    a, n = line.split()
                    extra[int(a, 16)] = n
            flags.discard(f)
    labels, starts, edges, ext = build(extra)

    if "--edges" in flags:
        for site, src, tgt in edges:
            print("0x%06X  %-38s -> %s"
                  % (site, labels.get(src, "?"), labels[tgt]))
        for site, tgt in sorted(ext):
            print("0x%06X  %-38s -> %s" % (site, "(outside the module)",
                                           labels[tgt]))
    else:
        wanted = [int(a, 16) for a in args] or starts
        for s in wanted:
            callers = [(site, labels.get(src, "0x%06X" % (src or 0)))
                       for site, src, tgt in edges if tgt == s]
            names = sorted({n for _, n in callers})
            outside = sorted(site for site, tgt in ext if tgt == s)
            print("0x%06X %-40s <- %d in-module site(s): %s%s"
                  % (s, labels.get(s, "?"), len(callers),
                     ", ".join(names) if names else "(none)",
                     ("  | %d converted site(s) outside: %s"
                      % (len(outside), ", ".join("0x%06X" % a for a in outside)))
                     if outside else ""))

    fails = []
    if not (0xFE54B6 in labels and labels[0xFE54B6] == "Dev7B_ReadStatus"):
        fails.append("0xFE54B6 is not Dev7B_ReadStatus in the source")
    if len([e for e in edges if e[2] == 0xFE54B6]) < 5:
        fails.append("fewer than 5 in-module calls to Dev7B_ReadStatus")
    print("\nself-checks")
    print("  routine starts found in range                              %d" % len(starts))
    print("  in-module call/jump edges to a routine start               %d" % len(edges))
    print("  converted call sites outside the module reaching into it   %d" % len(ext))
    for f in fails:
        print("  FAIL: " + f)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
