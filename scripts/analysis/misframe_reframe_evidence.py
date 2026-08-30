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
import re
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



# ---------------------------------------------------------------- site 2
def site_accscreen_block(d, quiet=False):
    """0xF6A9D7..0xF6B206 -- AccScreen_UIDataBlock, 2096 bytes. The tree's own
    header already called it a screen data block; 1,779 of those bytes were
    nevertheless framed as CODE. Re-framed to .byte / .ascii."""
    START, SIZE = 0xF6A9D7, 2096
    PARTS = [698, 15, 120, 15, 6, 287, 955]
    if not quiet:
        print("\nSITE 2  0x%06X..0x%06X  AccScreen_UIDataBlock" % (START, START + SIZE))
    claim("the header's part list sums to the block size",
          sum(PARTS) == SIZE, "%d" % sum(PARTS), quiet)
    off = START
    bounds = []
    for n in PARTS:
        bounds.append(off)
        off += n
    claim("the parts tile the block with no gap and no overlap",
          off == START + SIZE, "0x%06X" % off, quiet)

    # The three descriptors that name the ASCII: pointer at +7, LE16 cell width
    # at +11, and the cells they land on.
    for desc, want_ptr, want_stride, ncells in ((0xF6AC91, 0xF6ACA0, 20, 6),
                                                (0xF6AD18, 0xF6AD27, 3, 2),
                                                (0xF6AD37, 0xF6AD9E, 2, 12),
                                                (0xF6AD46, 0xF6ADB6, 2, 11),
                                                (0xF6AD8F, 0xF6AE4C, 4, 3)):
        p, st = u32(d, desc + 7), u16(d, desc + 11)
        claim("descriptor 0x%06X: len byte 15, ptr 0x%08X, stride %d"
              % (desc, want_ptr, want_stride),
              cell(d, desc, 2) == b"\x02\x0f" and p == want_ptr and st == want_stride,
              "ptr=0x%08X stride=%d" % (p, st), quiet)
        claim("  its %d x %d cells are the ASCII at 0x%06X"
              % (ncells, want_stride, want_ptr),
              all(32 <= x < 127 or x in (0x88, 0x8C)
                  for x in cell(d, want_ptr, want_stride * ncells)),
              repr(cell(d, want_ptr, min(60, want_stride * ncells)).decode("latin-1")),
              quiet)

    claim("the 6 x 20 cells run from the first descriptor's pointer to the second",
          0xF6ACA0 + 20 * 6 == 0xF6AD18, quiet=quiet)
    claim("every one of the six 20-byte cells ends in '='",
          all(cell(d, 0xF6ACA0 + 20 * i, 20)[-1] == 0x3D for i in range(6)), quiet=quiet)
    claim("the 2 x 3 cells run from the second descriptor's pointer to the third",
          0xF6AD27 + 3 * 2 == 0xF6AD2D, quiet=quiet)

    # ** THE FALSIFICATION TEST for a DATA BLOCK is different in kind: pointers
    # INTO it are expected -- that is what a data block is for. What would
    # falsify it is a CONTROL TRANSFER in. So classify every use of every label
    # naming an address inside the block, by the opcode that uses it.
    #
    # ** IT FIRED. Two offsets, 0x804 and 0x829, are reached with `call`, and
    # both turned out to be real 7-byte subroutines inside what the tree's own
    # header called 955 bytes of "part names and ordering". They are framed as
    # CODE again; the claim below is now that these are the ONLY two.
    CODE_ISLANDS = {0x804, 0x829}
    XFER = ("call", "calr", "jp", "jr", "jrl", "djnz")
    byop = {}
    for dp, dn, fn in os.walk(os.path.join(ROOT, "v10/maincpu")):
        for f in sorted(fn):
            if not f.endswith(".s") or f == "positional_labels.s":
                continue
            for ln in open(os.path.join(dp, f), encoding="latin-1"):
                if "AccScreen_UIDataBlock" not in ln:
                    continue
                code = ln.split(";")[0].strip()
                if not code or code.startswith("AccScreen_UIDataBlock:"):
                    continue
                m = re.search(r"AccScreen_UIDataBlock_0x([0-9A-Fa-f]+)", code)
                off = int(m.group(1), 16) if m else 0
                byop.setdefault(code.split()[0], set()).add(off)
    xfer_offs = set().union(*[byop.get(o, set()) for o in XFER]) if byop else set()
    ld_offs = byop.get("ld", set())
    claim("the ONLY offsets reached by a control transfer are the two code "
          "islands", xfer_offs == CODE_ISLANDS,
          sorted(hex(x) for x in xfer_offs), quiet)
    claim("no `ld` takes the address of a code island",
          not (ld_offs & CODE_ISLANDS), sorted(hex(x) for x in ld_offs & CODE_ISLANDS),
          quiet)
    claim("both islands are `push xhl / ldb_d8 a,(imm16) / pop xhl / ret`",
          all(cell(d, a, 7)[:2] == b"\x3b\xc1" and cell(d, a, 7)[4:] == b"\x21\x5b\x0e"
              for a in (0xF6B1DB, 0xF6B200)),
          "0x%04X / 0x%04X" % (u16(d, 0xF6B1DD), u16(d, 0xF6B202)), quiet)

    # The 30 seven-byte section-name cells end exactly where the first island
    # begins, and the ordering table between the islands has exactly 30 entries.
    claim("30 x 7-byte name cells at 0xF6B109 end on the first island",
          0xF6B109 + 30 * 7 == 0xF6B1DB, quiet=quiet)
    order = cell(d, 0xF6B1E2, 0xF6B200 - 0xF6B1E2)
    claim("the table between the islands is a permutation of 0..29",
          len(order) == 30 and sorted(order) == list(range(30)),
          "%d entries" % len(order), quiet)
    return True


# ---------------------------------------------------------------- site 3
def site_eed628_island(d, quiet=False):
    """0xEED628..0xEED657 -- a 48-byte code island in a zone that is otherwise
    .byte and .zero. Its record repeats, byte for byte, a shape the tree
    already spells as data 0x36 bytes earlier."""
    LO, HI = 0xEED628, 0xEED658
    if not quiet:
        print("\nSITE 3  0x%06X..0x%06X  code island inside a .byte/.zero zone" % (LO, HI))
    motif = bytes.fromhex("1e001e001e001e00000042000000")
    a, b = 0xEED60C, 0xEED642
    claim("the same 14-byte record shape appears at 0x%06X (already .byte) "
          "and 0x%06X (was code)" % (a, b),
          cell(d, a, len(motif)) == motif and cell(d, b, len(motif)) == motif,
          motif.hex(), quiet)
    claim("the tree framed the repeat as two `calr` to ONE address, from a "
          "constant", u16(d, b + 1) == u16(d, b + 5) == 0x1E00, quiet=quiet)
    claim("the 232 bytes after the island are zero (the tree's own `.zero 232`)",
          set(cell(d, HI, 232)) == {0}, quiet=quiet)
    hits = inbound_refs(d, LO, HI, allowed=set())
    claim("NOTHING outside points inside the island (falsification)",
          not hits, str(hits[:4]), quiet)
    return True


# ---------------------------------------------------------------- site 4
def site_f12ad0_chain(d, quiet=False):
    """0xF12AD0..0xF12B85 -- a record chain whose every boundary is confirmed
    both by a length field or a fixed cell grid AND by a pointer from outside."""
    if not quiet:
        print("\nSITE 4  0xF12AD0..0xF12B86  record chain into the .incbin")
    steps = [(0xF12AD0, 4, "the preceding record's LE32 pointer field"),
             (0xF12AD4, 41, "ASCII cells 25x1 + 2x4 + 2x4"),
             (0xF12AFD, 76, "19 LE32 pointers"),
             (0xF12B49, 10, "record, its own length byte"),
             (0xF12B53, 40, "five 8-byte cells"),
             (0xF12B7B, 11, "record, its own length byte")]
    a = steps[0][0]
    for start, n, why in steps:
        claim("0x%06X + %-3d (%s)" % (start, n, why), start == a,
              "-> 0x%06X" % (start + n), quiet)
        a = start + n
    claim("the chain ends EXACTLY on the existing .incbin at 0xF12B86",
          a == 0xF12B86, "0x%06X" % a, quiet)
    claim("the length bytes really are at +1 of their records",
          d[0xF12B49 - BASE + 1] == 10 and d[0xF12B7B - BASE + 1] == 11, quiet=quiet)
    claim("the last record's trailing LE32 is 0x00F12D0B, whose 0x00 high byte "
          "at 0xF12B85 the tree framed as a `nop`",
          u32(d, 0xF12B82) == 0x00F12D0B and d[0xF12B85 - BASE] == 0, quiet=quiet)
    claim("0xF12AD4 lands on ASCII and 0xF12AED (a referenced cell) on 'LOW '",
          cell(d, 0xF12AD4, 4) == b"ABCD" and cell(d, 0xF12AED, 4) == b"LOW ",
          quiet=quiet)
    # Only STRUCTURE STARTS may be referenced from outside.
    starts = {s for s, _, _ in steps} | {0xF12AED, 0xF12AF5}
    hits = [h for h in inbound_refs(d, 0xF12AD0, 0xF12B86, allowed=starts)
            if h[1] == 32]
    claim("no 32-bit pointer from outside lands anywhere but a structure start",
          not hits, str(hits[:4]), quiet)
    return True


# ------------------------------------------------------------- the survey
def _shape_ok(d, a):
    """The descriptor test, minus the `02 0f` head: an in-ROM LE32 at +7, a
    plausible cell width at +11, and two FULL cells of display text at the
    target. Used both by the survey and by its null."""
    n = len(d)
    if a + 15 > BASE + n:
        return False
    p, st = u32(d, a + 7), u16(d, a + 11)
    if not (BASE <= p < BASE + n) or not (1 <= st <= 64):
        return False
    c = cell(d, p, st * 2)
    return len(c) == st * 2 and all(32 <= x < 127 or x in (0x88, 0x8C) for x in c)


def descriptor_survey(d, quiet=False):
    """** IS THE DESCRIPTOR SHAPE A ROM-WIDE CONSTRUCT, OR SIX COINCIDENCES?

    Shape: a 15-byte record `02 0f`, five payload bytes, an LE32 pointer at +7,
    an LE16 cell width at +11. Scanned over the whole image and kept when the
    pointer lands on two FULL cells of display text."""
    hits = []
    for i in range(len(d) - 15):
        if d[i] != 0x02 or d[i + 1] != 0x0F:
            continue
        a = BASE + i
        if _shape_ok(d, a):
            hits.append((a, u32(d, a + 7), u16(d, a + 11)))
    tables = {(p, st) for _, p, st in hits}
    if not quiet:
        print("\nDESCRIPTOR SHAPE SURVEY")
        print("    %d records match the shape and land on display text,"
              " naming %d distinct (pointer, width) tables"
              % (len(hits), len(tables)))
        seen = set()
        for a, p, st in hits:
            if (p, st) in seen:
                continue
            seen.add((p, st))
            txt = cell(d, p, min(48, st * 4)).decode("latin-1")
            print("      0x%06X -> 0x%08X  w=%-3d %r" % (a, p, st, txt))
    return hits


SITES = [site_octave_table, site_accscreen_block, site_eed628_island,
         site_f12ad0_chain]


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

    # INVARIANT + NULL. "208 of 261 `02 0f` windows carry a pointer whose
    # target is display text of exactly the declared cell width" means nothing
    # until you know how often an ARBITRARY window does. So measure the null on
    # a deterministic random sample of offsets and require the real positions to
    # beat it by a wide margin. No count is pinned; the COMPARISON is the test.
    import random
    dd = bytes(d)
    raw = [i for i in range(len(dd) - 15) if dd[i] == 0x02 and dd[i + 1] == 0x0F]
    kept = len(descriptor_survey(dd, quiet=True))
    rate = kept / len(raw)
    rng = random.Random(20260830)
    sample = [rng.randrange(len(dd) - 15) for _ in range(200000)]
    null = sum(1 for i in sample if _shape_ok(dd, BASE + i)) / len(sample)
    check("the descriptor shape beats its null by >20x",
          rate > 20 * max(null, 1e-6),
          "%.3f at `02 0f` vs %.5f at random offsets (%d of %d)"
          % (rate, null, kept, len(raw)))

    # INVARIANT: every descriptor the 2026-08-30 findings named is in the sieve.
    named = {0xF6AC91, 0xF6AD18, 0xF6AD37, 0xF6AD46, 0xF6AD8F, 0xF12B86}
    got = {a for a, _, _ in descriptor_survey(bytes(d), quiet=True)}
    check("all six NAMED descriptors match the shape",
          named <= got, str(sorted(hex(x) for x in named - got)))

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    quiet = "--quiet" in sys.argv
    d = rom()
    for s in SITES:
        s(d, quiet)
    if "--survey" in sys.argv:
        descriptor_survey(d, quiet)
    print("\n%d structural claim(s) FAILED" % len(FAILURES))
    for f in FAILURES:
        print("   !!", f)
    sys.exit(1 if FAILURES else 0)


if __name__ == "__main__":
    main()
