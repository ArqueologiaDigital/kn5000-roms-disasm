#!/usr/bin/env python3
r"""THE SPANS LANE B4 RE-FRAMED FROM CODE TO DATA -- and the structure that proves it.

QUESTION ANSWERED
-----------------
`assert_byte_identical.py` proves the ROM was not CHANGED. It cannot prove it
was DISASSEMBLED CORRECTLY: `.byte 0x4f,0x4e,0x54,0x52` and `ld xhl,0x52544e4f`
emit the same four bytes. So when this lane moved bytes out of CODE territory
into `.long` / `.asciz`, the byte gate stayed green either way and something
else had to carry the burden of proof. This script is that something.

For every span re-framed it re-derives, FROM THE ROM, the structure that a
random byte string does not have -- a pointer that lands exactly on a cell, a
stride field equal to the measured width of the cells it points at, a table
whose last entry is the first byte past its own end -- and it runs the
FALSIFICATION TEST the lane brief demanded: an exhaustive scan for any 24- or
32-bit reference from OUTSIDE the span that lands strictly INSIDE it. A hit
there means the span was misdiagnosed and the re-frame must be undone.

** IT IS A GATE, NOT A REPORT. It exits non-zero if any claim stops holding.

RUN
    python3 scripts/analysis/misframe_reframe_evidence.py            # full case
    python3 scripts/analysis/misframe_reframe_evidence.py --quiet    # gate only
    python3 scripts/analysis/misframe_reframe_evidence.py --selftest # invariants

--selftest CHECKS INVARIANTS, NOT PINNED VALUES: it asserts that the reference
scanner can SEE a reference (by planting one in a scratch copy of the ROM and
requiring a hit) and that it does not fire on a span nothing points into. A
falsification test that cannot fail is not a test.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000

FAILURES = []


def rom():
    return open(ROM_PATH, "rb").read()


def u32(d, a):
    o = a - BASE
    return d[o] | d[o + 1] << 8 | d[o + 2] << 16 | d[o + 3] << 24


def u16(d, a):
    o = a - BASE
    return d[o] | d[o + 1] << 8


def cell(d, a, n):
    return d[a - BASE:a - BASE + n]


def show(d, a, n):
    b = cell(d, a, n)
    return "%s |%s|" % (" ".join("%02x" % x for x in b),
                        "".join(chr(x) if 32 <= x < 127 else "." for x in b))


def claim(desc, cond, extra="", quiet=False):
    if not cond:
        FAILURES.append(desc)
    if not quiet:
        print("    [%s] %-64s %s" % ("ok" if cond else "FAIL", desc, extra))
    return cond


def inbound_refs(d, lo, hi, allowed):
    """Every 24- and 32-bit LE word ANYWHERE in the ROM whose value lands in
    [lo,hi), reported unless its source is inside the span itself or its value
    is one of the structure starts we expect to be indexed.

    ** THIS IS THE FALSIFICATION TEST. A real branch or pointer aimed at the
    middle of a span means the span is not what we said it is."""
    hits = []
    n = len(d)
    for i in range(n - 3):
        src = BASE + i
        if lo <= src < hi:
            continue
        v32 = d[i] | d[i + 1] << 8 | d[i + 2] << 16 | d[i + 3] << 24
        v24 = v32 & 0xFFFFFF
        for v, w in ((v32, 32), (v24, 24)):
            if lo <= v < hi and v not in allowed:
                hits.append((src, w, v))
    return hits


# ---------------------------------------------------------------- site 1
def site_octave_table(d, quiet=False):
    """0xED1BA6..0xED1BEC -- SplitNoteStr_C, then an 11-entry LE32 pointer
    table, then eleven 2-byte octave-digit cells. Was framed as
    `ld xhl,0xeaff0020` + eleven `jp 0x??00ED`, i.e. the table read from
    0xED1BAB, one byte late."""
    T, NENT, CELLS, END = 0xED1BAA, 11, 0xED1BD6, 0xED1BEC
    if not quiet:
        print("\nSITE 1  0xED1BA6..0x%06X  octave-digit pointer table" % END)
    ptrs = [u32(d, T + 4 * i) for i in range(NENT)]
    claim("the string before the table is \"C \\0\" padded to even (43 20 00 ff)",
          cell(d, 0xED1BA6, 4) == b"C \x00\xff", show(d, 0xED1BA6, 4), quiet)
    claim("%d entries end exactly where the cells begin" % NENT,
          T + 4 * NENT == CELLS, "0x%06X" % (T + 4 * NENT), quiet)
    claim("the LAST entry is the first byte past the table's own end",
          ptrs[-1] == CELLS, "0x%08X" % ptrs[-1], quiet)
    claim("entries descend by exactly 2",
          all(ptrs[i] - ptrs[i + 1] == 2 for i in range(NENT - 1)),
          "0x%08X .. 0x%08X" % (ptrs[0], ptrs[-1]), quiet)
    claim("every entry lands inside the cell block",
          all(CELLS <= p < END for p in ptrs), quiet=quiet)
    ok = all(cell(d, p, 2)[1] == 0 and 0x30 <= cell(d, p, 2)[0] <= 0x39
             for p in ptrs)
    claim("every entry lands on a 2-byte NUL-terminated ASCII DIGIT", ok,
          "".join(chr(cell(d, p, 2)[0]) for p in ptrs), quiet)
    claim("the cells fill the block with no gap",
          min(ptrs) == CELLS and max(ptrs) + 2 == END, quiet=quiet)
    hits = inbound_refs(d, 0xED1BA6, END, allowed={0xED1BA6, T})
    claim("NOTHING outside points strictly inside the span (falsification)",
          not hits, str(hits[:4]), quiet)
    return not FAILURES


SITES = [site_octave_table]


def selftest():
    d = bytearray(rom())
    ok = True

    def check(desc, cond, extra=""):
        nonlocal ok
        print("  %-62s %s %s" % (desc, "PASS" if cond else "FAIL", extra))
        ok = ok and cond

    # INVARIANT: the scanner FIRES when a reference really exists. Plant a
    # 32-bit pointer at a scratch address aimed at the middle of a span and
    # require a hit. A falsification test that cannot fail is not a test.
    victim = 0xED1BB0                      # mid-entry inside site 1's table
    plant = 0x000010                       # ROM offset nothing else uses here
    save = bytes(d[plant:plant + 4])
    d[plant:plant + 4] = victim.to_bytes(4, "little")
    hits = inbound_refs(bytes(d), 0xED1BA6, 0xED1BEC, allowed={0xED1BA6, 0xED1BAA})
    check("scanner SEES a planted 32-bit reference into the span",
          any(v == victim for _, _, v in hits), "%d hit(s)" % len(hits))
    d[plant:plant + 4] = save
    hits = inbound_refs(bytes(d), 0xED1BA6, 0xED1BEC, allowed={0xED1BA6, 0xED1BAA})
    check("with the plant removed the same scan is clean", not hits, str(hits[:3]))

    # INVARIANT: `allowed` really suppresses, i.e. the two structure starts ARE
    # referenced from outside -- otherwise the exemption is hiding nothing and
    # the "clean" result above is vacuous.
    hits = inbound_refs(bytes(d), 0xED1BA6, 0xED1BEC, allowed=set())
    vals = sorted({v for _, _, v in hits})
    check("the exempted addresses are genuinely referenced from outside",
          vals == [0xED1BA6, 0xED1BAA], [hex(v) for v in vals])

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    quiet = "--quiet" in sys.argv
    d = rom()
    for s in SITES:
        s(d, quiet)
    print("\n%d structural claim(s) FAILED" % len(FAILURES))
    for f in FAILURES:
        print("   !!", f)
    sys.exit(1 if FAILURES else 0)


if __name__ == "__main__":
    main()
