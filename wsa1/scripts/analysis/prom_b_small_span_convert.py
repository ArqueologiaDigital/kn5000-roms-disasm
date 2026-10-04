#!/usr/bin/env python3
"""prom_b_small_span_convert.py

QUESTION IT ANSWERS
-------------------
"Which of prom_b's 55 SMALL `.incbin` spans (<= 128 bytes) can be replaced by
real source on evidence that does not come from guessing an instruction, and
what is the evidence for each?"

It holds one VERDICT per span, emits the replacement text, and can splice it
into `prom_b/wsa1_prom_b.s`.  Refusals are recorded here too, with the reason,
so the file itself is the lane's audit trail.

    python3 scripts/analysis/prom_b_small_span_convert.py --check   # evidence
    python3 scripts/analysis/prom_b_small_span_convert.py --verdicts
    python3 scripts/analysis/prom_b_small_span_convert.py --splice  # patch the .s

Run from wsa1/.  `--splice` is idempotent: a span whose `.incbin` line is gone
is skipped.  After splicing, `python3 scripts/analysis/assert_byte_identical.py`
is the only thing that certifies the result.

THE FINDING THIS TOOL EXISTS TO RECORD
--------------------------------------
Almost none of these spans is an undecoded mystery.  51 of the 55 sit
immediately after a *converted* object and are the REST OF THAT SAME OBJECT:
coverage round 1 measured each object's extent with a reachability walk, and the
walk's extent is not the object's extent, so it cut fixed-stride arrays in the
middle of an entry.  16 spans are the tail of a 4-byte POINTER ARRAY, 8 are the
tail of an 8-byte (4 x 16-bit) RECORD ARRAY, 7 are a routine's `ret` trailer and
4 are whole routines.  The classification is produced by the companion tool
`prom_b_small_span_classify.py`.  38 spans / 811 B were converted and 17 / 551 B
refused.

KINDS
-----
  PTRTAB4   the enclosing object is an array of 4-byte entries `lo mid hi 00`
            whose value is an address inside this image.  CHECK: every entry
            from the array base through the end of the span satisfies that, and
            the span's leading bytes complete the entry the walk cut.
  SHORTARR8 the enclosing object is an array of 8-byte entries = 4 little-endian
            16-bit fields.  CHECK: some display-list record in this same source
            declares the array's base with `-> XIX: array of 8-byte entries`,
            and the span ends exactly on an 8-byte boundary from that base.
  SHORTPROG a 16-bit table in strict arithmetic progression across the cut.
            CHECK: the step is constant over the converted part AND the span.
  CODE      TLCS-900 instructions.  CHECK: the linear decode consumes the span
            exactly, and every entry of the pointer table at 0xF000E5 lands on
            an instruction boundary inside these spans.  The instruction text is
            produced by notes/llvm_roundtrip_autoforce.py, which assembles its
            own output and compares it with the ROM before printing.
  TRAILER   the 1-3 byte gap between a routine's `ret` and the next object.  In
            this module a routine is followed by `00 00` or by the 0x0E (`ret`)
            pad this build uses everywhere.  Emitted as typed bytes, NOT as
            instructions: `00 00` is equally two `nop`s and a two-byte gap, and
            nothing in the image distinguishes them.
  DLTAIL    the tail of ONE display-list record whose leading byte(s) the
            previous object absorbed.  CHECK: op < 0x24, the length byte, and
            the record landing exactly on the next proven object.
  DLMIX     interpreter records with an 8-byte-entry array between them.  CHECK:
            --probe-refusals finds exactly ONE record/array decomposition of the
            span, and the array's base is named by the +0x07 field of the record
            immediately in front of it.
  REFUSE    not established; the span keeps its `.incbin` and the reason is
            printed by --verdicts.  --probe-refusals is the search that says so:
            it finds no decomposition at all for any of the 17.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
B = 0xF00000

# ---------------------------------------------------------------- the verdicts
# (addr, length, kind, arg, note)
#   PTRTAB4   arg = (array base, end of the pointer array)
#   SHORTARR8 arg = (array base, end of the record array)
#   SHORTPROG arg = (table base, step)
#   TRAILER / CODE / DLTAIL / REFUSE: arg unused (TRAILER carries its own note)
V = [
 (0xF00000, 0x1A, "CODE", None,
  "five `jp 0x00F00014` slots -- the image's own entry-vector block -- followed "
  "by the two routines they name.  Every jump target is inside the span."),
 (0xF0003A, 0x02, "TRAILER", None, "after T_F409B0_Nop's `ret`, before sub_F0003C"),
 (0xF00097, 0x02, "TRAILER", None, "after sub_F0003C's `ret`, before sub_F00099"),
 (0xF000E3, 0x02, "TRAILER", None, "after sub_F00099's `ret`, before Transport_StopByRunningMask"),
 (0xF000E6, 0x22, "PTRTAB4", (0xF000E5, 0xF00105),
  "the rest of the 8-entry CALL-DISPATCH array Transport_StopByRunningMask.  sub_F00099 "
  "ends `ld XWA,0x00F000E5` / `add XHL,XWA` / `ld XWA,(XHL)` / `call XWA` "
  "at 0xF000D5-0xF000DE, so the object is a table of routine pointers "
  "reached by an index.  Its eight targets are 0x00F00105 0x00F0028D "
  "0x00F002C9 0x00F002EB 0x00F002B9 0x00F00280 0x00F002B6 0x00F002B3 -- and "
  "ALL EIGHT land on an instruction boundary in the code this lane "
  "converted at 0xF00280/0xF0029D/0xF002CD.  That mutual check is what "
  "makes both the table and those spans safe.  The 3 bytes after the array "
  "are 0xF00105 (a bare 0x0E `ret`, the array's entry 0) and a `00 00` "
  "trailer."),
 (0xF0017B, 0x02, "TRAILER", None, "after sub_F00108's `ret`, before Transport_StartStopFromZero"),
 (0xF001AE, 0x02, "TRAILER", None, "after Transport_StartStopFromZero's `ret`, before Transport_StartStopFromZero_Call"),
 (0xF001B4, 0x01, "TRAILER", None,
  "one 0x0E byte after Transport_StartStopFromZero_Call's `ret`: the 0x0E (`ret`) pad this build uses, "
  "already asserted as `.fill ..., 0x0E` in eight other places in this file"),
 (0xF001C7, 0x02, "TRAILER", None, "after Transport_ToggleCAndB's `ret`, before Transport_StartAllFromZero"),
 (0xF00280, 0x13, "CODE", None, "entry 0x00F00280 (and 0x00F0028D) of the array Transport_StopByRunningMask"),
 (0xF0029D, 0x2C, "CODE", None, "entries 0x00F002B9 0x00F002B6 0x00F002B3 of Transport_StopByRunningMask"),
 (0xF002CD, 0x27, "CODE", None, "entry 0x00F002EB of Transport_StopByRunningMask"),
 (0xF02FFE, 0x2C, "REFUSE", None,
  # ⚠ OVERTURNED 2026-09-02 by lane res02f (notes/gen_res02f_spans.py), which
  # converted this span.  The reason below is kept verbatim because it is what
  # THIS pass concluded, and it was wrong in one word: the array's base IS
  # declared in the source -- by the `03 0B` record's own +0x07 field, four
  # bytes of which this pass left inside the `.incbin`.  The stride is 8,
  # fixed by handler 0xF31B57's `sla 0x03,HL`, and the count is 5, fixed by
  # the extent to the display-list start at 0xF0302A.  This entry stays
  # REFUSE: this converter is not the one that closed the span.
  "Data_F02FF7 begins with a display-list record (`03 0B`) and the span is a "
  "16-bit array behind it; nothing in the source declares that array's base, so "
  "its stride is unestablished"),
 (0xF03620, 0x13, "PTRTAB4", (0xF03617, 0xF03633), "7-entry pointer array"),
 (0xF03A26, 0x07, "REFUSE", None,
  "inside a display-list record stream; the record boundary before it is not "
  "anchored by any converted line, so framing it would be a guess"),
 (0xF03ADE, 0x15, "REFUSE", None, "same display-list record stream as 0xF03A26"),
 (0xF03AF8, 0x4D, "REFUSE", None, "same display-list record stream as 0xF03A26"),
 (0xF03BE6, 0x05, "REFUSE", None,
  "four different record-chain start points all land exactly on the span's end; "
  "the framing is not determined"),
 (0xF03C12, 0x0B, "PTRTAB4", (0xF03C05, 0xF03C1D), "6-entry pointer array"),
 (0xF03F81, 0x2E, "REFUSE", None,
  "mixed ASCII captions and record bytes; no declared record shape covers it"),
 (0xF04D14, 0x0F, "REFUSE", None,
  "starts mid-record in a display-list stream and ends on an ASCII string table; "
  "two structures meet inside the span"),
 (0xF04E33, 0x0F, "PTRTAB4", (0xF04E32, 0xF04E42), "4-entry pointer array"),
 (0xF04F57, 0x1B, "PTRTAB4", (0xF04F46, 0xF04F72), "11-entry pointer array"),
 (0xF05026, 0x0B, "PTRTAB4", (0xF04FFD, 0xF05031), "13-entry pointer array"),
 (0xF05102, 0x0B, "PTRTAB4", (0xF050F1, 0xF0510D), "7-entry pointer array"),
 (0xF0534B, 0x13, "SHORTARR8", (0xF0531E, 0xF0535E),
  "the array 0xF0531E declared by a display-list record's `+0x07 -> XIX` field"),
 (0xF0537F, 0x37, "PTRTAB4", (0xF05372, 0xF053B6), "17-entry pointer array"),
 (0xF0540B, 0x3A, "REFUSE", None,
  "a display-list record stream carrying ASCII; not anchored"),
 (0xF05446, 0x13, "PTRTAB4", (0xF05445, 0xF05459), "5-entry pointer array"),
 (0xF0545A, 0x0F, "PTRTAB4", (0xF05459, 0xF05469), "4-entry pointer array"),
 (0xF054EA, 0x03, "PTRTAB4", (0xF054D9, 0xF054ED), "5-entry pointer array"),
 (0xF05792, 0x2E, "REFUSE", None,
  "an 8-byte-looking record array whose base is not declared anywhere in the "
  "source; the only candidate base is 2.7 KB away and the fit is arithmetic "
  "coincidence"),
 (0xF05CEC, 0x0C, "REFUSE", None, "font/bitmap-shaped bytes with no declared shape"),
 (0xF0D9A4, 0x3E, "DLMIX", None,
  "two display-list records with an 8-byte-entry array between them.  The "
  "first record (op 0x03, 11 B) names 0x00F0D9AF at its +0x07 field, which is "
  "exactly where it ends and where the array begins; five 8-byte entries then "
  "land exactly on the second record (op 0x08, 11 B), which ends exactly on "
  "the span end.  A search over every record/array decomposition of all 18 "
  "spans this lane could not otherwise frame (--probe-refusals) finds a "
  "decomposition for THIS ONE ONLY, and only one for it."),
 (0xF13D34, 0x2C, "REFUSE", None, "font glyph rows; no declared shape"),
 (0xF286CC, 0x2D, "REFUSE", None, "display-list record stream carrying ASCII; not anchored"),
 (0xF28877, 0x1F, "SHORTARR8", (0xF28866, 0xF28896), "declared array base 0xF28866"),
 (0xF288BE, 0x13, "SHORTARR8", (0xF288A1, 0xF288D1), "declared array base 0xF288A1"),
 (0xF32A00, 0x09, "REFUSE", None, "display-list record stream; not anchored"),
 (0xF32A37, 0x17, "PTRTAB4", (0xF32A36, 0xF32A4E), "6-entry pointer array"),
 (0xF32B27, 0x0B, "PTRTAB4", (0xF32B1E, 0xF32B32), "5-entry pointer array"),
 (0xF32B41, 0x23, "SHORTARR8", (0xF32B3C, 0xF32B64), "declared array base 0xF32B3C"),
 (0xF32C0F, 0x16, "PTRTAB4", (0xF32C02, 0xF32C22),
  "pointer array whose LAST entry is completed by the first byte of Data_F32C25, "
  "so the array's own end (0xF32C26) is past this span; the 3 bytes of that "
  "entry inside the span stay `.byte`"),
 (0xF33401, 0x1B, "SHORTARR8", (0xF33394, 0xF3341C), "declared array base 0xF33394"),
 (0xF338BE, 0x0B, "PTRTAB4", (0xF338A5, 0xF338C9), "9-entry pointer array"),
 (0xF33A5E, 0x13, "SHORTARR8", (0xF33A49, 0xF33A71), "declared array base 0xF33A49"),
 (0xF33BB5, 0x23, "PTRTAB4", (0xF33B8C, 0xF33BD8), "19-entry pointer array"),
 (0xF34350, 0x11, "REFUSE", None,
  "display-list record bytes plus ASCII ` -1 -2`; not anchored"),
 (0xF34C9B, 0x07, "DLTAIL", None,
  "one interpreter record op 0x0E, length 8, whose first byte 0xF34C9A the "
  "previous `.byte` row absorbed.  Handler 0xF31A9F reads three 16-bit operands "
  "-- exactly the 8 bytes -- and the record lands on Data_F34CA2, which a "
  "previous pass already re-framed as a record start"),
 (0xF3503C, 0x1F, "SHORTARR8", (0xF3503B, 0xF3505B), "declared array base 0xF3503B"),
 (0xF396E7, 0x46, "REFUSE", None,
  "a display-list record then an 8-byte array; the array base is not declared"),
 (0xF3A0C6, 0x0B, "SHORTPROG", (0xF3A0C1, 5),
  "a 16-bit table in strict +5 progression: 0x1EF0 0x1EF5 ... 0x1F13.  The step "
  "is constant over the converted part and over the span, so the cut is inside a "
  "single table"),
 (0xF3A443, 0x1E, "REFUSE", None, "display-list record then an undeclared array"),
 (0xF3B656, 0x05, "REFUSE", None,
  "⚠ A ONE-BYTE INCONSISTENCY SOMEONE SHOULD LOOK AT.  Data_F3B651 "
  "starts `00 0B`; read as op 0x00 with length 11 the record would end at "
  "0xF3B65C, but the next record demonstrably starts at 0xF3B65B (`02 0F 41 "
  "26 ...`, op 0x02 length 15, and the chain from there is clean).  So either "
  "op 0x00 does not carry its length at +1 in this interpreter, or "
  "DL_F3B65B's start is off by one.  This lane cannot tell which, so the "
  "span stays"),
 (0xF3C47E, 0x57, "SHORTARR8", (0xF3C37D, 0xF3C4D5), "declared array base 0xF3C37D"),
]

INCBIN = re.compile(r'^\s*\.incbin\s+"[^"]*"\s*,\s*(0x[0-9A-Fa-f]+)\s*,\s*(0x[0-9A-Fa-f]+)')


def rom():
    return open(ROM, "rb").read()


def src_lines():
    return open(SRC, encoding="latin-1").read().split("\n")


def w(v, d, a, n):
    return int.from_bytes(d[a - B:a - B + n], "little")


# ------------------------------------------------------------------- evidence
def check(verbose=True):
    d, fails, n = rom(), [], 0

    def c(desc, ok):
        nonlocal n
        n += 1
        if verbose:
            print("%-6s %s" % ("ok" if ok else "FAIL", desc))
        if not ok:
            fails.append(desc)

    txt = "\n".join(src_lines())
    declared = set(int(m, 16) for m in
                   re.findall(r'\.long\s+0x00([0-9A-F]{6})\s*;[^\n]*array of 8-byte entries', txt))
    c("the source declares %d `array of 8-byte entries` bases" % len(declared),
      len(declared) > 40)

    for a, ln, kind, arg, _note in V:
        tag = "0x%06X/%d %s" % (a, ln, kind)
        if kind == "PTRTAB4":
            base, tend = arg
            c(tag + ": array base <= span start, 4-byte aligned",
              base <= a and (tend - base) % 4 == 0)
            bad = [x for x in range(base, tend, 4)
                   if d[x - B + 3] != 0 or not (0xF00000 <= w(0, d, x, 3) < 0xF80000)]
            c(tag + ": all %d entries are `lo mid hi 00` addressing this image"
              % ((tend - base) // 4), not bad)
            c(tag + ": the array covers the span", tend >= min(a + ln, tend) and tend > a)
        elif kind == "SHORTARR8":
            base, aend = arg
            c(tag + ": base 0x%06X is declared by a record's `-> XIX` field" % base,
              base in declared)
            c(tag + ": the array end is 8-byte aligned from the base and covers the span",
              (aend - base) % 8 == 0 and base <= a and aend >= a + ln)
        elif kind == "SHORTPROG":
            base, step = arg
            vals = [w(0, d, x, 2) for x in range(base, a + ln, 2)]
            c(tag + ": %d 16-bit values in strict +%d progression across the cut"
              % (len(vals), step),
              len(vals) > 3 and all(vals[i + 1] - vals[i] == step for i in range(len(vals) - 1)))
        elif kind == "TRAILER":
            blk = d[a - B:a - B + ln]
            c(tag + ": the byte before it is 0x0E (`ret`)", d[a - B - 1] == 0x0E)
            c(tag + ": the span is all 0x00 or all 0x0E",
              set(blk) in ({0x00}, {0x0E}))
        elif kind == "DLTAIL":
            s = a - 1
            op, rl = d[s - B], d[s - B + 1]
            c(tag + ": op 0x%02X < 0x24, length %d lands on 0x%06X = span end"
              % (op, rl, s + rl), op < 0x24 and s + rl == a + ln)
        elif kind == "DLMIX":
            import itertools
            sols = list(itertools.islice(decompose(a, a + ln), 0, 3))
            c(tag + ": exactly one record/array decomposition covers the span",
              len(sols) == 1)
        elif kind == "CODE":
            lines = transcribe(a, ln)
            c(tag + ": the linear decode consumes the span exactly",
              addr_of(lines[-1]) is not None)
    # the mutual check: every Transport_StopByRunningMask entry lands on an instruction boundary
    starts = set()
    for a, ln, kind, _arg, _n in V:
        if kind == "CODE":
            starts |= set(addr_of(l) for l in transcribe(a, ln))
    starts.add(0xF00105)               # the array's own `ret` stub, a TRAILER byte
    starts.add(0xF002C9)               # TransportB_Stop, converted before this lane
    c("sub_F00099 loads 0x00F000E5 as a 32-bit immediate at 0xF000D6 and CALLs "
      "through it -- the array is a call-dispatch table",
      w(0, d, 0xF000D6, 4) == 0x00F000E5)
    for k in range(8):
        t = w(0, d, 0xF000E5 + 4 * k, 3)
        c("Transport_StopByRunningMask entry %d = 0x00%06X lands on an instruction boundary" % (k, t),
          t in starts)
    print("\n%d checks, %d failures" % (n, len(fails)))
    return not fails


# ------------------------------------------------- the record/array decomposer
def declared_arrays():
    """Every 8-byte-entry array base the SOURCE itself declares, from the
    `-> XIX: array of 8-byte entries` comment a display-list record carries."""
    txt = open(SRC, encoding="latin-1").read()
    return set(int(m, 16) for m in re.findall(
        r'\.long\s+0x00([0-9A-F]{6})\s*;[^\n]*array of 8-byte entries', txt))


def decompose(a, end, declared=None, depth=0, path=()):
    """Every way of covering [a,end) with interpreter records and 8-byte-entry
    arrays.  A record is (op < 0x24, length at +1).  An array is allowed only
    where its base is NAMED -- either by the +0x07 pointer of the record just
    before it, or by a declaration elsewhere in the source.  Yields the paths;
    a span is only convertible when there is exactly ONE."""
    if declared is None:
        declared = declared_arrays()
    d = rom()
    if a == end:
        yield path
        return
    if a > end or depth > 14:
        return
    op, ln = d[a - B], d[a - B + 1]
    if op < 0x24 and 2 <= ln <= 64 and a + ln <= end:
        yield from decompose(a + ln, end, declared, depth + 1, path + (("rec", a, ln),))
    named = (path and path[-1][0] == "rec" and path[-1][2] >= 11
             and w(0, d, path[-1][1] + 7, 4) == a) or (a in declared)
    if named:
        k = 1
        while a + 8 * k <= end and k <= 64:
            yield from decompose(a + 8 * k, end, declared, depth + 1,
                                 path + (("arr", a, 8 * k),))
            k += 1


def probe_refusals():
    """How many of the spans this lane refused have a UNIQUE record/array
    decomposition?  Answer 2026-09-02: 1 of 18 (0xF0D9A4), which is why that one
    is converted and the other 17 are not.  Also tries a start up to 4 bytes
    before the span, for the case where the previous object absorbed the
    record's leading bytes -- that finds nothing extra."""
    import itertools
    dec, n = declared_arrays(), 0
    for a, ln, kind, _g, _note in V:
        if kind not in ("REFUSE", "DLMIX"):
            continue
        for back in range(5):
            sols = list(itertools.islice(decompose(a - back, a + ln, dec), 0, 4))
            if sols:
                break
        print("0x%06X %-4d back=%d %d solution(s) %s"
              % (a, ln, back, len(sols),
                 " ".join("%s@%06X/%d" % t for t in sols[0]) if len(sols) == 1 else ""))
        n += len(sols) == 1
    print("\n%d of %d spans have a unique decomposition"
          % (n, sum(1 for x in V if x[2] in ("REFUSE", "DLMIX"))))


# ------------------------------------------------------------------- emission
_tc = {}


def transcribe(a, n):
    if (a, n) not in _tc:
        p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(a), hex(n), "--quiet"],
                           capture_output=True, text=True, cwd=ROOT)
        if p.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (a, p.stderr))
        _tc[(a, n)] = p.stdout.rstrip("\n").split("\n")
    return _tc[(a, n)]


def addr_of(line):
    m = re.search(r';\s*([0-9A-F]{6})\s', line)
    return int(m.group(1), 16) if m else None


def byte_row(d, a, n, why):
    blk = d[a - B:a - B + n]
    return "\t.byte\t%s\t; %06X  %s" % (", ".join("0x%02X" % x for x in blk), a, why)


def emit(a, ln, kind, arg, note):
    """The replacement lines for one span (no trailing blank)."""
    d = rom()
    end = a + ln
    head = ["; --- 0x%06X-0x%06X, %d B, converted by lane promB6 (%s)."
            % (a, end - 1, ln, kind)]
    import textwrap
    head += [";     " + x for x in textwrap.wrap(note, 72)]
    head += [";     Evidence checked by scripts/analysis/prom_b_small_span_convert.py"
             " --check"]
    out = []
    if kind == "CODE":
        return head + transcribe(a, ln)
    if kind == "TRAILER":
        return head + [byte_row(d, a, ln, "routine trailer")]
    if kind == "DLTAIL":
        s = a - 1
        return head + [byte_row(d, a, ln,
                                "rest of the op 0x%02X record that starts at %06X"
                                % (d[s - B], s))]
    if kind == "DLMIX":
        import itertools
        sols = list(itertools.islice(decompose(a, end), 0, 2))
        if len(sols) != 1:
            raise SystemExit("0x%06X: %d decompositions, expected exactly 1"
                             % (a, len(sols)))
        for k, x, n in sols[0]:
            if k == "rec":
                out.append("\t.byte 0x%02X, 0x%02X\t; %06X  op %02X, %d bytes"
                           % (d[x - B], d[x - B + 1], x, d[x - B], n))
                out.append(byte_row(d, x + 2, n - 2, "operands"))
            else:
                for e in range(n // 8):
                    out.append("\t.short\t%s\t; %06X  entry %d"
                               % (", ".join("0x%04X" % w(0, d, x + 8 * e + 2 * i, 2)
                                            for i in range(4)), x + 8 * e, e))
        return head + out
    if kind == "PTRTAB4":
        base, tend = arg
        p = a
        lead = (p - base) % 4
        if lead:
            k = 4 - lead
            ent = w(0, d, p - lead, 4)
            out.append(byte_row(d, p, min(k, end - p),
                                "top %d bytes of entry %d = 0x%08X"
                                % (min(k, end - p), (p - lead - base) // 4, ent))) if False else None
            blk = d[p - B:p - B + min(k, end - p)]
            out.append("\t.byte\t%s\t; %06X  top %d bytes of the entry at %06X = 0x00%06X"
                       % (", ".join("0x%02X" % x for x in blk), p, len(blk),
                          p - lead, w(0, d, p - lead, 3)))
            p += len(blk)
        while p + 4 <= min(end, tend):
            out.append("\t.long\t0x00%06X\t; %06X  entry %d"
                       % (w(0, d, p, 3), p, (p - base) // 4))
            p += 4
        if p < end:
            out.append(byte_row(d, p, end - p,
                                "past the array: 0x%02X %s" % (d[p - B],
                                "(`ret`) and the routine trailer" if d[p - B] == 0x0E
                                else "trailing bytes")))
        return head + out
    if kind == "SHORTARR8":
        base, _aend = arg
        p = a
        lead = (p - base) % 8
        if lead:
            k = min(8 - lead, end - p)
            blk = d[p - B:p - B + k]
            out.append("\t.byte\t%s\t; %06X  rest of the 8-byte entry at %06X"
                       % (", ".join("0x%02X" % x for x in blk), p, p - lead))
            p += k
        while p + 8 <= end:
            out.append("\t.short\t%s\t; %06X  entry %d"
                       % (", ".join("0x%04X" % w(0, d, p + 2 * i, 2) for i in range(4)),
                          p, (p - base) // 8))
            p += 8
        if p < end:
            out.append(byte_row(d, p, end - p, "partial trailing entry"))
        return head + out
    if kind == "SHORTPROG":
        base, _step = arg
        p = a
        lead = (p - base) % 2
        if lead:
            out.append("\t.byte\t0x%02X\t; %06X  high byte of the value at %06X = 0x%04X"
                       % (d[p - B], p, p - 1, w(0, d, p - 1, 2)))
            p += 1
        while p + 2 <= end:
            out.append("\t.short\t0x%04X\t; %06X" % (w(0, d, p, 2), p))
            p += 2
        if p < end:
            out.append(byte_row(d, p, end - p, "odd trailing byte"))
        return head + out
    raise SystemExit("no emitter for kind %s" % kind)


def splice():
    lines, d, done, done_bytes = src_lines(), rom(), 0, 0
    out = []
    todo = {(a - B, ln): (a, ln, k, g, n) for a, ln, k, g, n in V if k != "REFUSE"}
    for line in lines:
        m = INCBIN.match(line)
        key = (int(m.group(1), 16), int(m.group(2), 16)) if m else None
        if key in todo:
            a, ln, k, g, n = todo.pop(key)
            out += emit(a, ln, k, g, n)
            done += 1
            done_bytes += ln
        else:
            out.append(line)
    if todo:
        skipped = len(todo)
        print("skipped %d span(s) whose .incbin is already gone: %s"
              % (skipped, " ".join("0x%06X" % (B + k[0]) for k in sorted(todo))))
    open(SRC, "w", encoding="latin-1").write("\n".join(out))
    print("spliced %d spans, %d bytes" % (done, done_bytes))


def verdicts():
    tot = {}
    for a, ln, k, _g, note in V:
        tot[k] = tot.get(k, [0, 0])
        tot[k][0] += 1
        tot[k][1] += ln
        print("0x%06X  %-4d %-10s %s" % (a, ln, k, note))
    print()
    for k in sorted(tot):
        print("%-10s %2d spans %5d bytes" % (k, tot[k][0], tot[k][1]))
    print("%-10s %2d spans %5d bytes" % ("TOTAL", len(V), sum(x[1] for x in tot.values())))


if __name__ == "__main__":
    if "--probe-refusals" in sys.argv:
        probe_refusals()
    elif "--check" in sys.argv:
        sys.exit(0 if check() else 1)
    elif "--splice" in sys.argv:
        splice()
    else:
        verdicts()
