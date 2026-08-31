#!/usr/bin/env python3
"""Do the NUMBERS in the 0xF65000 block's headers agree with the lines under them?

QUESTION IT ANSWERS
  The byte gate proves the listing rebuilds the ROM and is blind to every count
  in a comment.  This re-reads the emitted text and checks each header's own
  arithmetic against the `.long` / `.byte` / `.ascii` rows that follow it, plus
  each routine header's caller list against the `.s`'s own call sites.

  It exists because the first draft of notes/gen_prom_b_f65000_module.py wrote
  "3 distinct other targets" for a 4-entry table with 2 -- it subtracted the
  IMAGE-WIDE default thunk slot 0x00F42C70 when it meant the MODULE's own `ret`
  stub 0x00F675CB.  Gate-clean, and wrong in every one of the 25 dispatch-table
  headers it emitted.

WHAT IT CHECKS, per object
  DispatchTable  entry count, stub count, distinct-non-stub count, last entry
  RamPtrTable    entry count, first value, last value, the set of steps
  BitWeight      entry count, and entry k == 1 << k
  IndexMap       total byte count, and each sub-run's first/last value
  Text           byte count and the literal string
  sub_XXXXXX     every `T_xxxxxx` named in "Called from" really holds
                 `jp <this address>` in the thunk table, and every in-module
                 caller listed really has a call/calr/jp to it

  ⚠ It checks the emitted TEXT against the emitted ROWS and against the ROM.  It
  cannot tell you a name is right; it tells you a count is not invented.

RUN
  python3 notes/prom_b_f65000_header_audit.py                  # audit the .s
  python3 notes/prom_b_f65000_header_audit.py --file X.s
  python3 notes/prom_b_f65000_header_audit.py --last           # last object only
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
LO, HI = 0xF65000, 0xF6D002
STUB = 0x00F675CB
FAIL = []


def rom():
    return open(IMG, "rb").read()


def report(name, got, want):
    ok = got == want
    if not ok:
        FAIL.append((name, got, want))
    print("  %-64s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r" % (got, want)))
    return ok


def blocks(text):
    """[(label, header_lines, body_lines)] for every label in the block range."""
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", lines[i])
        if m:
            lab = m.group(1)
            a = re.search(r"_([0-9A-F]{6})$", lab)
            if a and LO <= int(a.group(1), 16) < HI:
                j = i - 1
                hdr = []
                while j >= 0 and lines[j].startswith(";"):
                    hdr.insert(0, lines[j])
                    j -= 1
                # STOP AT THE FIRST BLANK LINE.  The emitter puts one after
                # every data object; without this the collector runs on into the
                # code that follows and swallows its `.byte` demotion rows --
                # which is how the first draft of this audit reported
                # IndexMap_F6A455 as 35 bytes when the object is 32.
                k = i + 1
                body = []
                while k < len(lines) and lines[k].startswith("\t"):
                    body.append(lines[k])
                    k += 1
                out.append((lab, int(a.group(1), 16), hdr, body))
        i += 1
    return out


def main():
    path = SRC
    if "--file" in sys.argv:
        path = sys.argv[sys.argv.index("--file") + 1]
    text = open(path).read()
    bl = blocks(text)
    if "--last" in sys.argv:
        bl = bl[-1:]
    print("objects audited: %d  (from %s)" % (len(bl), path))
    d = rom()
    # thunk table, for the caller check
    th = {}
    for o in range(0x40000, 0x44018, 4):
        if d[o] == 0x1B:
            th.setdefault(d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16, []).append(B_BASE + o)
    ndisp = nram = nbit = nidx = ntxt = nsub = 0
    for lab, addr, hdr, body in bl:
        H = " ".join(x.lstrip("; ").rstrip() for x in hdr)
        H = re.sub(r"\s+", " ", H)
        if lab.startswith("DispatchTable_"):
            ndisp += 1
            vals = [int(m, 16) for m in re.findall(r"\.long\s+0x([0-9A-F]{8})", "\n".join(body))]
            m = re.search(r"(\d+) 32-bit pointers.*?(\d+) of the (\d+) entries are the module's own do-nothing stub 0x([0-9A-F]{6}).*?leaving (\d+) distinct other target", H)
            report("%s header parses" % lab, bool(m), True)
            if not m:
                continue
            n1, ns, n2, stub, nd = (int(m.group(1)), int(m.group(2)), int(m.group(3)),
                                    int(m.group(4), 16), int(m.group(5)))
            report("%s: entry count" % lab, (n1, n2), (len(vals), len(vals)))
            report("%s: stub is 0x%06X and it is `ret`" % (lab, stub),
                   (stub, d[stub - B_BASE]), (STUB, 0x0E))
            report("%s: stub count" % lab, ns, vals.count(STUB))
            report("%s: distinct non-stub targets" % lab, nd,
                   len(set(vals) - {STUB}))
            m2 = re.search(r"Entry (\d+), the last, is 0x([0-9A-F]{8})", H)
            report("%s: last entry" % lab, (int(m2.group(1)), int(m2.group(2), 16)),
                   (len(vals) - 1, vals[-1]))
            report("%s: rows match the ROM" % lab,
                   vals, [int.from_bytes(d[addr - B_BASE + 4 * i:addr - B_BASE + 4 * i + 4],
                                         "little") for i in range(len(vals))])
        elif lab.startswith("RamPtrTable_"):
            nram += 1
            vals = [int(m, 16) for m in re.findall(r"\.long\s+0x([0-9A-F]{8})", "\n".join(body))]
            m = re.search(r"(\d+) 32-bit words.*?First 0x([0-9A-F]+), last 0x([0-9A-F]+); the step between neighbours takes (\d+) distinct value", H)
            report("%s header parses" % lab, bool(m), True)
            if not m:
                continue
            report("%s: count/first/last" % lab,
                   (int(m.group(1)), int(m.group(2), 16), int(m.group(3), 16)),
                   (len(vals), vals[0], vals[-1]))
            steps = sorted(set(vals[i + 1] - vals[i] for i in range(len(vals) - 1)))
            report("%s: number of distinct steps" % lab, int(m.group(4)), len(steps))
            report("%s: every value below 0x10000" % lab,
                   [v for v in vals if not 0 < v < 0x10000], [])
        elif lab.startswith("BitWeight_"):
            nbit += 1
            vals = [int(m, 16) for m in re.findall(r"\.long\s+0x([0-9A-F]{8})", "\n".join(body))]
            m = re.search(r"(\d+) 32-bit words, entry k = 1 << k", H)
            report("%s header parses" % lab, bool(m), True)
            report("%s: count" % lab, int(m.group(1)), len(vals))
            report("%s: entry k == 1 << k" % lab,
                   [i for i, v in enumerate(vals) if v != 1 << i], [])
        elif lab.startswith("IndexMap_"):
            nidx += 1
            bs = []
            for r in re.findall(r"\.byte\s+([^\t;]+)", "\n".join(body)):
                bs += [int(x, 16) for x in re.findall(r"0x([0-9A-F]{2})", r)]
            m = re.search(r"(\d+) bytes?\. The run is maximal", H)
            report("%s header parses" % lab, bool(m), True)
            report("%s: byte count" % lab, int(m.group(1)), len(bs))
            subs = re.findall(r"(\d+) bytes at 0x([0-9A-F]{6}) counting 0x([0-9A-F]{2})\.\.0x([0-9A-F]{2})", H)
            tot, off = 0, 0
            for ln, a, v0, v1 in subs:
                ln, a, v0, v1 = int(ln), int(a, 16), int(v0, 16), int(v1, 16)
                report("%s: sub-run at 0x%06X is 0x%02X..0x%02X" % (lab, a, v0, v1),
                       bs[off:off + ln], list(range(v0, v1 + 1)))
                report("%s: sub-run at 0x%06X starts where it says" % (lab, a),
                       addr + off, a)
                off += ln
                tot += ln
            report("%s: sub-runs sum to the byte count" % lab, tot, len(bs))
            report("%s: rows match the ROM" % lab, bs,
                   list(d[addr - B_BASE:addr - B_BASE + len(bs)]))
        elif lab.startswith("Text_"):
            ntxt += 1
            m = re.search(r'\.ascii\s+"([^"]*)"', "\n".join(body))
            h = re.search(r"(\d+) ASCII bytes: '([^']*)'", H)
            report("%s header parses" % lab, bool(h) and bool(m), True)
            # ⚠ compare with runs of whitespace collapsed on BOTH sides: the
            # header is a wrapped comment, so the string's own runs of spaces do
            # not survive it intact.  The exact bytes are checked against the ROM
            # on the next line, which is where the real assertion lives.
            sq = lambda t: re.sub(r"\s+", " ", t)
            report("%s: byte count and text (whitespace-collapsed)" % lab,
                   (int(h.group(1)), sq(h.group(2))),
                   (len(m.group(1)), sq(m.group(1))))
            report("%s: text matches the ROM" % lab, m.group(1),
                   d[addr - B_BASE:addr - B_BASE + len(m.group(1))].decode("latin1"))
        elif lab.startswith("sub_"):
            nsub += 1
            slots = re.findall(r"T_([0-9A-F]{6}) \(x\d+\)", H.split("Touches:")[0])
            bad = [s for s in slots
                   if B_BASE + 0x40000 <= int(s, 16) < B_BASE + 0x44018 and
                   not (d[int(s, 16) - B_BASE] == 0x1B and
                        (d[int(s, 16) - B_BASE + 1] | d[int(s, 16) - B_BASE + 2] << 8
                         | d[int(s, 16) - B_BASE + 3] << 16) == addr)]
            if slots:
                report("%s: every T_ slot listed really jumps here" % lab, bad, [])
            ins = re.search(r"in-module: ((?:0x[0-9A-F]{6} ?)+)", H)
            if ins:
                sites = [int(x, 16) for x in re.findall(r"0x([0-9A-F]{6})", ins.group(1))]
                miss = []
                for st in sites:
                    seg = re.search(r"; %06X\s+(call|calr|jp)\s+(?:\w+,)?0x%06x"
                                    % (st, addr), text)
                    if not seg:
                        miss.append("0x%06X" % st)
                report("%s: every in-module caller listed really calls it" % lab, miss, [])
    print()
    print("  dispatch tables %d  ram tables %d  bit tables %d  index maps %d  "
          "strings %d  routines %d" % (ndisp, nram, nbit, nidx, ntxt, nsub))
    print("%s (%d failed)" % ("AUDIT PASS" if not FAIL else "AUDIT FAIL", len(FAIL)))
    return 0 if not FAIL else 1


if __name__ == "__main__":
    sys.exit(main())
