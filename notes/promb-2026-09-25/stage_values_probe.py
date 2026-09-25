#!/usr/bin/env python3
r"""prom_b 0xF57453-0xF57572: who calls the five "stage values" routines, and what they feed.

QUESTION THIS ANSWERS
    wsa1/prom_b/wsa1_prom_b.s used to carry 0xF57453-0xF57571 as one `.byte`
    block, `Unclaimed_F57453`, "nothing in either image references any address
    inside them".  This probe re-derives, FROM THE ROM BYTES ALONE (not from the
    .s), the three facts the conversion rests on:

      1. every `calr` (opcode 0x1E, 16-bit displacement) in prom_b whose target is
         one of the five routine starts -- found by scanning every byte offset and
         then REQUIRING MAME unidasm to see a `calr` instruction start there, so a
         0x1E inside an operand does not count;
      2. what each routine WRITES: its `ld (nn),A` / `ld (nn),WA` destinations,
         plus the `ldirw` block copy (destination XIX, count BC words);
      3. what the display list its caller runs next READS: after the `calr`, the
         caller loads XIY (start) and XIX (end) and calls slot 0xF417F4
         (T_DisplayListB_Run); the list is walked record by record with the
         interpreter-B framing [op, total length], and each record's `+0x02` word is
         its source variable -- except an op-0x02 record whose +2 word is 0 and whose
         +7 pointer is a RAM address: that one reads the string AT the pointer.

    PASS means: exactly one caller per routine, and the set of cells each routine
    writes equals the set of source variables its caller's list reads.

    It also shows the NEGATIVE the old header recorded, so the correction is
    checkable: no 32-bit little-endian spelling of any address in the block
    occurs in prom_a or prom_b (true), while five `calr` reach it (the reason the
    32-bit census missed them).

RUN
    python3 notes/promb-2026-09-25/stage_values_probe.py            # report + verdict
    python3 notes/promb-2026-09-25/stage_values_probe.py --selftest # also a planted-failure check
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
A = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
UNI = os.path.join(os.path.expanduser("~/compartilhado"), "tools", "unidasm")
BASE = 0xF00000
LO, HI = 0xF57453, 0xF57573
ROUTINES = {
    0xF57453: "SeqPlayScreen_StageValues",
    0xF57498: "RealtimeRecordScreen_StageValues",
    0xF574DE: "CyclePlayScreen_StageValues",
    0xF5750C: "CyclePlayEditScreen_StageValues",
    0xF57537: "CycleRecordScreen_StageValues",
}
DLB_RUN_SLOT = 0xF417F4
LINE = re.compile(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s*(\S+)\s*(.*)$')


def unidasm(blob, base):
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(blob)
        f.flush()
        out = subprocess.run([UNI, f.name, "-arch", "tlcs900", "-basepc", hex(base)],
                             capture_output=True, text=True).stdout
    res = {}
    for ln in out.split("\n"):
        m = LINE.match(ln)
        if m:
            res[int(m.group(1), 16)] = (m.group(3).lower(), m.group(4).strip(),
                                        len(m.group(2).split()))
    return res


def s16(v):
    return v - 0x10000 if v & 0x8000 else v


def callers(rom, uni, target):
    out = []
    for i in range(len(rom) - 3):
        if rom[i] != 0x1E:
            continue
        site = BASE + i
        if site + 3 + s16(rom[i + 1] | rom[i + 2] << 8) == target:
            d = uni.get(site)
            if d and d[0] == "calr":
                out.append(site)
    return out


def writes(uni, start):
    """Store destinations of the routine at start, until its first ret."""
    cells, a = set(), start
    xix = None
    bc = None
    while True:
        mn, ops, n = uni[a]
        m = re.match(r'^\(0x([0-9a-f]+)\),(a|wa)$', ops.lower())
        if mn == "ld" and m:
            cells.add(int(m.group(1), 16))
        m = re.match(r'^xix,0x([0-9a-f]+)$', ops.lower())
        if mn == "ld" and m:
            xix = int(m.group(1), 16)
        m = re.match(r'^bc,0x([0-9a-f]+)$', ops.lower())
        if mn == "ld" and m:
            bc = int(m.group(1), 16)
        if mn == "ldirw":
            cells.add(xix)                # a block of 2*bc bytes starting at XIX
        if mn == "ret":
            return cells, a
        a += n


def dl_after(rom, uni, site):
    """The XIY/XIX pair loaded before the caller's `call T_DisplayListB_Run`."""
    a, xiy, xix = site + 3, None, None
    for _ in range(12):
        mn, ops, n = uni[a]
        o = ops.lower()
        if mn == "ld" and o.startswith("xiy,0x"):
            xiy = int(o[4:], 16)
        if mn == "ld" and o.startswith("xix,0x"):
            xix = int(o[4:], 16)
        if mn == "call" and int(o, 16) == DLB_RUN_SLOT:
            return xiy, xix
        a += n
    return None


def dl_reads(rom, lo, hi):
    """Interpreter-B walk: [op, total length]; +2 = source variable."""
    reads, a, recs = set(), lo, 0
    while a < hi:
        op, ln = rom[a - BASE], rom[a - BASE + 1]
        if ln < 2:
            raise SystemExit("bad record at 0x%06X" % a)
        var = rom[a - BASE + 2] | rom[a - BASE + 3] << 8
        if op == 0x02 and var == 0:
            ptr = int.from_bytes(rom[a - BASE + 7:a - BASE + 11], "little")
            if ptr < 0x10000:
                reads.add(ptr)
        else:
            reads.add(var)
        a += ln
        recs += 1
    if a != hi:
        raise SystemExit("walk overran 0x%06X by %d" % (hi, a - hi))
    return reads, recs


def main():
    rom = open(B, "rb").read()
    arom = open(A, "rb").read()
    uni = unidasm(rom, BASE)
    ok = True
    # the negative the old header recorded
    n32 = 0
    for img in (rom, arom):
        for v in range(LO, HI):
            n32 += img.count(v.to_bytes(4, "little"))
    print("32-bit LE spellings of 0x%06X-0x%06X in prom_a+prom_b: %d  (the old header's census)"
          % (LO, HI - 1, n32))
    for start, name in sorted(ROUTINES.items()):
        cs = callers(rom, uni, start)
        w, end = writes(uni, start)
        print("\n%s  0x%06X-0x%06X  callers(calr): %s" % (name, start, end,
                                                       " ".join("0x%06X" % c for c in cs) or "NONE"))
        if len(cs) != 1:
            ok = False
            print("  FAIL: expected exactly one caller")
            continue
        pair = dl_after(rom, uni, cs[0])
        if not pair:
            ok = False
            print("  FAIL: caller does not run T_DisplayListB_Run next")
            continue
        r, nrec = dl_reads(rom, pair[0], pair[1])
        same = w == r
        ok &= same
        print("  writes %s" % " ".join("0x%04X" % x for x in sorted(w)))
        print("  list 0x%06X-0x%06X (%d records) reads %s" % (pair[0], pair[1], nrec,
                                                           " ".join("0x%04X" % x for x in sorted(r))))
        print("  %s  (%d cells)" % ("MATCH" if same else "MISMATCH", len(w)))
    print("\nVERDICT:", "PASS" if ok else "FAIL")
    if "--selftest" in sys.argv:
        # planted failure: pretend a routine wrote one extra cell -- the check must see it
        w, _ = writes(uni, 0xF574DE)
        pair = dl_after(rom, uni, callers(rom, uni, 0xF574DE)[0])
        r, _ = dl_reads(rom, *pair)
        planted = (w | {0x1234}) != r
        print("SELFTEST planted extra write is detected:", "PASS" if planted else "FAIL")
        ok &= planted
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
