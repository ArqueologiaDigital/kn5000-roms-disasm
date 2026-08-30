#!/usr/bin/env python3
r"""Are the 13 STRONG-with-evidence runs in the v10 maincpu CODE? No. Here is why.

QUESTION ANSWERED
-----------------
`notes/reachability_kn5000.py --targets` ends with a work list: every run of
reachable-but-unconverted bytes that (a) the STRONG-seeded walk reached and
(b) something POSITIVELY names the start of. On 2026-08-30 that list is
13 runs / 176 bytes, and the lane brief asked for each to be either CONVERTED to
source or REFUSED IN WRITING.

ALL 13 ARE REFUSED. This script is the evidence behind
notes/FINDINGS-reachability-strong-ev-refusals-2026-08-30.md. It prints, for
every run, the bytes, the ASCII, the instruction that named it, THAT
instruction's own bytes, and the structural reading that settles it.

★ IT IS ALSO A GATE. It asserts the tool's work list is EXACTLY the 13 runs
  adjudicated below, and that every structural claim the note makes -- each
  pointer landing on ASCII, each stride matching, each fill run -- still holds.
  If a later edit moves any of them, this exits non-zero and the note must be
  re-adjudicated rather than silently going stale.

WHY A REFUSAL NEEDS EVIDENCE AT ALL
-----------------------------------
Framing data as code still passes the byte gate. `.byte 0x4f,0x4e,0x54,0x52` and
`ld xhl,0x52544e4f` emit the same four bytes, so `assert_byte_identical.py` sees
nothing. The byte gate proves the ROM was not CHANGED; it does not prove it was
DISASSEMBLED CORRECTLY. So every refusal below cites a structure that a random
byte string does not have: a pointer that lands exactly on a string, a stride
field that equals the measured width of the cells it points at, a documented
record header, a measured fill run.

THE HEADLINE, WHICH IS BIGGER THAN 176 BYTES
--------------------------------------------
Every one of the 13 runs is named by an instruction THE TREE HAS ALREADY FRAMED
OVER DATA. Two demonstrations, both re-derived here:

  * 0xED1BAA is an 11-entry table of 32-bit pointers, descending by 2, naming
    the eleven 2-byte strings "0","0","0","1".."8" that sit immediately after
    it. The tree frames it ONE BYTE LATE, from 0xED1BAB, which turns each entry
    into `jp 0x??00ED` -- and the ?? steps 0xE8, 0xE6, 0xE4, 0xE2, 0xE0, 0xDE
    ... because it is reading the LOW byte of the NEXT pointer as the jump's
    high byte. Five of those land inside the ROM; four are runs 1-4.
    An arithmetic progression of entry points exactly 0x020000 apart is not a
    jump table. It is a pointer table read at the wrong phase.

  * 0xF6ACA0 is a 6 x 20-byte ASCII table, "CONTROL PITCH BEND =" ...
    "CONTROL AFTER TOUCH=", which the tree frames as `ld xhl,0x52544e4f` and
    friends. The 15-byte `.incbin` immediately before it is the DESCRIPTOR that
    names the table: pointer 0x00F6ACA0, stride 0x0014 = 20. Runs 10-13 are
    those descriptors and the gaps between them.

DID REFUSING EVERYTHING LEAVE REAL CODE ON THE TABLE?
----------------------------------------------------
`--survey` answers that. It lists the largest runs of the WEAK-seeded (`any`)
walk whose start also has evidence -- the 67,247-byte column the tool warns
against converting -- with the first 40 bytes of each. Run it and read the ASCII:
style names, bitmap filenames, widget names, decimal-number strings, pointer
tables and zero fill. Nothing in the top of that list is a routine either.

RUN
    python3 scripts/analysis/reachability_refusal_evidence.py
    python3 scripts/analysis/reachability_refusal_evidence.py --quiet   # gate only
    python3 scripts/analysis/reachability_refusal_evidence.py --survey 25
                                       # ★ the weak column, 25 largest runs

Exit 0 = the work list and every structural claim still hold. Exit 1 = one moved.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import reachability_kn5000 as R          # noqa: E402

BASE = R.TARGET["base"]

# --------------------------------------------------------------------------
# THE ADJUDICATION. (lo, hi, verdict, what the bytes actually are)
# Every entry is REFUSE. Converting any of them would frame data as code.
# --------------------------------------------------------------------------
REFUSALS = [
    (0xE200ED, 0xE2013F,
     "REFUSE: a 16-bit coordinate table running into printf format strings",
     "0xE200E0-0xE200F2 is 16-bit values; 0xE200F2 begins the C format strings "
     "\"%2d : %s\", \"FILE%02d:%s\", \"%03d:%s\", \"%02d:%s\". Named by the "
     "0xED1BAA pointer table read one byte late."),

    (0xE400ED, 0xE400EE,
     "REFUSE: one byte of 0xff fill",
     "inside a solid 0xff run whose extent is MEASURED in the FILL EXTENTS "
     "section below. Named by the 0xED1BAA pointer table read one byte late."),

    (0xE600ED, 0xE600FE,
     "REFUSE: the tail of a 0x00 fill run plus the first bitmap byte",
     "the 0x00 run is measured below; 0xE600FD begins the bitmap rows "
     "fe fe fe fe 00 fc fc fc fc 00 ... Named by the 0xED1BAA pointer table "
     "read one byte late."),

    (0xE800ED, 0xE800EF,
     "REFUSE: a 16-bit table running into ASCII",
     "0xE800F6 is \" LEFT  \\0RIGHT 2\\0RIGHT 1\\0\". Named by the 0xED1BAA "
     "pointer table read one byte late."),

    (0xED3C96, 0xED3C9B,
     "REFUSE: a naka widget record header",
     "34 00 = entry length word, 60 01 = widget type 0x0160 (text widget) -- "
     "the format control_menu_screens.s DOCUMENTS IN ITS OWN HEADER COMMENT, "
     "and which ErrorDialog_CautionHeader in that file already writes out by "
     "hand as `.byte 0x2b, 0x00 ; Entry length: 43 bytes`. The record's "
     "pointer at 0xED3CB8 holds 0x00ED3CC0 and lands exactly on its inline "
     "string \"CONTROL MENU\"."),

    (0xED40A7, 0xED40C6,
     "REFUSE: a widget record with an inline string, plus the next header",
     "0xED40B0 holds the pointer 0x00ED40B8, landing exactly on the inline "
     "\"INITIAL\\0\" at 0xED40B8; 0xED40C0 is the next record header, "
     "33 00 60 01 ff ff."),

    (0xED5465, 0xED5466,
     "REFUSE: one byte of a 0xffff flags field",
     "the record header at 0xED545E is 48 00 60 01 00 00 ff ff and 0xED5465 is "
     "the second byte of that ff ff. The preceding record's pointer at "
     "0xED5442 holds 0x00ED544E and lands exactly on \"STYLE EXPLORER\\0\"."),

    (0xEEF445, 0xEEF451,
     "REFUSE: 0x00 fill inside a mask bitmap",
     "the 0x00 run containing it is measured below; 0xEEF450 onward alternates "
     "ff ff ff ff / 00 00 00 00, i.e. 32-bit mask rows. Named by two `calr` "
     "the tree framed over the repeated 16-bit constant 1e 00 1e 00 1e 00 "
     "1e 00 at 0xEED642."),

    (0xF12B86, 0xF12B8A,
     "REFUSE: the head of a string-table descriptor, same shape again",
     "0xF12B86 has the identical layout to the four accompaniment_engine "
     "descriptors: tag at +6, 32-bit pointer 0x00F12CCF at +7, stride 0x0002 "
     "at +11 -- and 0xF12CCF is the stride-2 table \"A:\" \"B:\" \"C:\" ... "
     "\"Z:\". The run also sits immediately after a second pointer, "
     "0x00F12D0B at 0xF12B82, and the `nop` that names it IS THAT POINTER'S "
     "0x00 HIGH BYTE at 0xF12B85."),

    (0xF6AC91, 0xF6AC95,
     "REFUSE: the head of a string-table descriptor",
     "the descriptor at 0xF6AC91 carries pointer 0x00F6ACA0 and stride "
     "0x0014 = 20; 0xF6ACA0 is six 20-byte cells, \"CONTROL PITCH BEND =\" "
     "through \"CONTROL AFTER TOUCH=\"."),

    (0xF6AC9F, 0xF6ACA0,
     "REFUSE: the last byte before that ASCII table",
     "one byte, 0x1b, the descriptor's trailing field; 0xF6ACA0 is ASCII, and "
     "the tree already frames it as `ld xhl,0x52544e4f` = \"ONTR\"."),

    (0xF6AD18, 0xF6AD1C,
     "REFUSE: the head of a second string-table descriptor",
     "pointer 0x00F6AD27, stride 0x0003; 0xF6AD27 is \"OFF\" \" ON\", two "
     "3-byte cells, then the NUL at 0xF6AD2D. The instruction that names this "
     "run sits at 0xF6AD17 and the tree's next one, `ld xiz,1313808454` at "
     "0xF6AD28, IS THE ASCII \"F ON\"."),

    (0xF6AD2D, 0xF6AD39,
     "REFUSE: that table's NUL plus the next descriptor",
     "0xF6AD2D is the NUL ending \" ON\"; 0xF6AD37 is the next descriptor, "
     "pointer 0x00F6AD9E stride 0x0002, and 0xF6AD9E is the stride-2 note-name "
     "table \" C\" \"C#\" \" D\" \"D#\" ... \" B\"."),
]

# --------------------------------------------------------------------------
# The structural claims, each CHECKED at run time so the note cannot go stale.
# --------------------------------------------------------------------------
PTR_TABLE = (0xED1BAA, 11)      # -> eleven 2-byte NUL-terminated digit strings

# (descriptor addr, ptr offset, stride offset, first cell expected there)
DESCRIPTORS = [
    (0xF6AC91,  7, 11, b"CONTROL PITCH BEND ="),
    (0xF6AD18,  7, 11, b"OFF"),
    (0xF6AD37,  7, 11, b" C"),
    (0xF6AD46,  7, 11, b"-2"),
    (0xF6AD8F,  7, 11, None),   # pointer lands on ASCII; cell width not settled
    (0xF12B86,  7, 11, b"A:"),  # sound_editor_ui, SAME shape as the four above
]

# (record header addr, pointer field addr, string it must land on)
WIDGET_RECORDS = [
    (0xED3C96, 0xED3CB8, b"CONTROL MENU"),
    (0xED40C0, 0xED40F8, b"INITIAL"),
    (0xED545E, 0xED5442, b"STYLE EXPLORER"),
]

# (address inside the fill, the fill byte)
FILLS = [(0xE400ED, 0xFF), (0xE600ED, 0x00), (0xEEF445, 0x00)]


def h(bs):
    return " ".join("%02x" % c for c in bs)


def asc(bs):
    return "".join(chr(c) if 32 <= c < 127 else "." for c in bs)


def rd(d, addr, n):
    return d[addr - BASE:addr - BASE + n]


def u32(d, addr):
    return int.from_bytes(rd(d, addr, 4), "little")


def u16(d, addr):
    return int.from_bytes(rd(d, addr, 2), "little")


def cstr(d, addr, limit=32):
    o = addr - BASE
    end = d.find(b"\0", o, o + limit)
    return d[o:end if end >= 0 else o + limit]


def fill_run(d, addr, byte):
    lo = hi = addr - BASE
    while lo > 0 and d[lo - 1] == byte:
        lo -= 1
    while hi < len(d) and d[hi] == byte:
        hi += 1
    return BASE + lo, BASE + hi


def wrap(s, n):
    out, cur = [], ""
    for w in s.split():
        if len(cur) + len(w) + 1 > n:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        out.append(cur)
    return out


def survey(d, r, n=15):
    """The largest ANY+EV runs, so a reader can check that refusing the STRONG
    column did not leave real routines unconverted in the weak one."""
    sd = {k: set(v) for k, v in r["seed_lists"].items()}
    seen = set(r["seen_any"])
    rows = []
    for s in r["spans"]:
        for a, b in R.runs_of(seen, s["lo"], s["hi"]):
            ev = R.start_evidence(a, sd, R.EV_ANY)
            if ev:
                rows.append((b - a, a, b, ev, s["src"]))
    rows.sort(reverse=True)
    print("ANY-seed runs whose START has evidence: %d runs, %s bytes"
          % (len(rows), format(sum(x[0] for x in rows), ",")))
    print("largest %d, with the first 40 bytes of each:" % n)
    for ln, a, b, ev, src in rows[:n]:
        blob = rd(d, a, 40)
        pr = 100.0 * sum(1 for c in blob if 32 <= c < 127) / max(1, len(blob))
        print("  0x%06X-0x%06X %6d B  %-13s printable %3.0f%%  %s"
              % (a, b, ln, ev, pr, os.path.basename(src)))
        print("      %s" % h(blob[:24]))
        print("      %s" % asc(blob))
    print("★ read the ASCII column. This is where a lane that ignored the")
    print("  evidence test would start painting pointer tables as instructions.")


def main():
    quiet = "--quiet" in sys.argv
    d = R.rom_bytes()
    r = R.gather()
    work = sorted(r["work"])
    fails = []

    if "--survey" in sys.argv:
        n = 15
        i = sys.argv.index("--survey")
        if i + 1 < len(sys.argv) and sys.argv[i + 1].isdigit():
            n = int(sys.argv[i + 1])
        survey(d, r, n)
        return 0

    def claim(desc, cond, extra=""):
        if not cond:
            fails.append(desc + ("  " + extra if extra else ""))
        if not quiet:
            print("    %s %s%s" % ("ok  " if cond else "FAIL", desc,
                                   ("   " + extra) if extra else ""))

    if not quiet:
        print(__doc__.split("RUN\n")[0].rstrip())
        print("\n" + "=" * 78)
        print("REACHABILITY, v10 maincpu 0x%06X" % BASE)
        print("  STRONG seeds, evidence ignored   %9s bytes"
              % format(r["reach_strong_in_incbin"], ","))
        print("  STRONG seeds AND start evidence  %9s bytes  in %d runs"
              % (format(r["reach_strong_ev_in_incbin"], ","), len(work)))
        print("  any seed                         %9s bytes"
              % format(r["reach_any_in_incbin"], ","))
        print("  CONVERTED by this adjudication   0 bytes")
        print("  REFUSED  by this adjudication    %s bytes  (%d of %d runs)"
              % (format(sum(b - a for a, b, *_ in REFUSALS), ","),
                 len(REFUSALS), len(work)))

        print("\n" + "=" * 78)
        print("STRUCTURE 1 -- the pointer table at 0x%06X, and the tree's framing"
              % PTR_TABLE[0])
        print("  the tree reads it from 0x%06X, ONE BYTE LATE." % (PTR_TABLE[0] + 1))
    for i in range(PTR_TABLE[1]):
        ad = PTR_TABLE[0] + 4 * i
        v = u32(d, ad)
        cell = cstr(d, v, 4) if BASE <= v < BASE + len(d) else b""
        shifted = int.from_bytes(rd(d, ad + 2, 3), "little")
        if not quiet:
            print("    [%2d] 0x%06X  %s -> 0x%08X  cell %-5s %-5r | "
                  "misframed as jp 0x%06X"
                  % (i, ad, h(rd(d, ad, 4)), v, h(cell),
                     cell.decode("latin-1"), shifted))
    if not quiet:
        print("  the claims:")
    vals = [u32(d, PTR_TABLE[0] + 4 * i) for i in range(PTR_TABLE[1])]
    claim("every entry is a valid ROM address",
          all(BASE <= v < BASE + len(d) for v in vals))
    claim("the entries descend by exactly 2",
          all(vals[i] - vals[i + 1] == 2 for i in range(len(vals) - 1)))
    claim("the LAST entry points at the byte right after the table",
          vals[-1] == PTR_TABLE[0] + 4 * PTR_TABLE[1],
          "0x%06X vs 0x%06X" % (vals[-1], PTR_TABLE[0] + 4 * PTR_TABLE[1]))
    cells = [cstr(d, v, 4) for v in vals]
    claim("every entry lands on a 1-char NUL-terminated digit string",
          all(len(c) == 1 and c.isdigit() for c in cells),
          "".join(c.decode("latin-1") for c in cells))
    mis = [int.from_bytes(rd(d, PTR_TABLE[0] + 4 * i + 2, 3), "little")
           for i in range(PTR_TABLE[1])]
    claim("the MISFRAMED jp targets descend by exactly 0x020000",
          all(mis[i] - mis[i + 1] == 0x020000 for i in range(len(mis) - 2)),
          "0x%06X, 0x%06X, 0x%06X ..." % tuple(mis[:3]))

    if not quiet:
        print("\n" + "=" * 78)
        print("STRUCTURE 2 -- string-table descriptors: pointer + stride")
        print("  shape: .. .. .. .. .. .. 06 | ptr(4) | stride(2) | .. ..")
    for ad, po, so, first in DESCRIPTORS:
        ptr = u32(d, ad + po)
        stride = u16(d, ad + so)
        cs = []
        if BASE <= ptr < BASE + len(d) and 0 < stride <= 32:
            for k in range(8):
                c = rd(d, ptr + k * stride, stride)
                if not all(32 <= x < 127 or x == 0x8C for x in c):
                    break
                cs.append(c)
        if not quiet:
            print("    0x%06X  %s" % (ad, h(rd(d, ad, 15))))
            print("              ptr 0x%08X  stride %-3d  %d printable cells: %s"
                  % (ptr, stride, len(cs),
                     "  ".join("%r" % c.decode("latin-1") for c in cs[:6])))
        claim("0x%06X: pointer 0x%08X is a ROM address" % (ad, ptr),
              BASE <= ptr < BASE + len(d))
        claim("0x%06X: it lands on >= 2 printable cells of its own stride" % ad,
              len(cs) >= 2, "%d cells of %d bytes" % (len(cs), stride))
        if first is not None:
            claim("0x%06X: first cell is %r" % (ad, first.decode()),
                  cs and cs[0] == first, "got %r" % (cs[0] if cs else b""))
    if not quiet:
        print("  ★ a 32-bit field that lands exactly on ASCII, followed by a")
        print("    16-bit field that equals that ASCII's cell width, is a data")
        print("    descriptor. No instruction encoding produces that by accident.")

        print("\n" + "=" * 78)
        print("STRUCTURE 3 -- naka widget records: header + inline-string pointer")
        print("  control_menu_screens.s documents this format in its own header")
        print("  comment: entry length word, then widget type 0x0160 = text.")
    for hdr, pf, want in WIDGET_RECORDS:
        ty = u16(d, hdr + 2)
        ptr = u32(d, pf)
        got = cstr(d, ptr, 24) if BASE <= ptr < BASE + len(d) else b""
        if not quiet:
            print("    header 0x%06X %s  len %3d type 0x%04X | ptr 0x%06X -> "
                  "0x%08X %r"
                  % (hdr, h(rd(d, hdr, 6)), u16(d, hdr), ty, pf, ptr,
                     got.decode("latin-1")))
        claim("0x%06X: widget type field is 0x0160 (text widget)" % hdr,
              ty == 0x0160, "0x%04X" % ty)
        claim("0x%06X: its pointer lands exactly on %r" % (hdr, want.decode()),
              got == want, "got %r" % got.decode("latin-1"))

    if not quiet:
        print("\n" + "=" * 78)
        print("FILL EXTENTS -- measured, not asserted")
    for ad, byte in FILLS:
        lo, hi = fill_run(d, ad, byte)
        if not quiet:
            print("    0x%06X is inside a solid 0x%02X run 0x%06X-0x%06X, %s bytes"
                  % (ad, byte, lo, hi, format(hi - lo, ",")))
        claim("0x%06X: the 0x%02X fill run is at least 64 bytes" % (ad, byte),
              hi - lo >= 64, "%d bytes" % (hi - lo))

    if not quiet:
        print("\n" + "=" * 78)
        print("THE 13 RUNS, ONE BY ONE")
        for (lo, hi, verdict, why), (a0, b0, ev, _i, src, line, namer) in \
                zip(REFUSALS, work):
            if (lo, hi) != (a0, b0):
                continue
            blob = rd(d, lo, hi - lo)
            print("\n  0x%06X-0x%06X  %4d B   named by: %s   %s:%d"
                  % (lo, hi, hi - lo, ev, src, line))
            print("     bytes  %s%s" % (h(blob[:32]), " ..." if len(blob) > 32 else ""))
            print("     ascii  %s" % asc(blob[:64]))
            if namer:
                print("     namer  0x%06X  %-28s  its own bytes: %s"
                      % (namer[0], namer[1], h(rd(d, namer[0], 6))))
            print("     %s" % verdict)
            for chunk in wrap(why, 68):
                print("       %s" % chunk)

    got = [(x[0], x[1]) for x in work]
    want = [(x[0], x[1]) for x in REFUSALS]
    if got != want:
        fails.append("the tool's work list no longer matches the adjudication")
        if not quiet:
            print("\n  tool : %s" % ", ".join("0x%06X-0x%06X" % x for x in got))
            print("  note : %s" % ", ".join("0x%06X-0x%06X" % x for x in want))

    if not quiet:
        print("\n" + "=" * 78)
    print("GATE: work list %s the adjudication (%d runs, %s bytes); "
          "%d structural claim(s) failed"
          % ("MATCHES" if got == want else "DOES NOT MATCH", len(work),
             format(sum(b - a for a, b, *_ in work), ","), len(fails)))
    for f in fails:
        print("  FAIL: %s" % f)
    if fails:
        print("  ★ the refusal note is now stale. Re-adjudicate before trusting it.")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
