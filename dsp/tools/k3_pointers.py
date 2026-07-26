#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""k3_pointers.py -- NEC uPD6383GF (SX-KN5000 IC311): the POINTER-REGISTER FILE.

Roadmap item K3.  Every number quoted in dsp/analysis/k3-pointers.md comes out of
this script; it is stdlib-only apart from the ROM parser it borrows from the
research tree, and it re-runs from scratch:

    python3 dsp/tools/k3_pointers.py                     # all sections
    python3 dsp/tools/k3_pointers.py census host spaces  # pick sections

Sections
    census    where the register-load words are (kernel vs the 38 body images)
    builders  what the Sub CPU firmware constructs, byte by byte
    host      decode the uC-IF captures into a per-register memory map
    spaces    are the three host-reachable registers three distinct SPACES?
    boundary  do the in-program payloads land on structural boundaries of those maps?
    cfmt      is the disassembler's C-format predicate wider than its evidence?

Inputs
    --sub   original_ROMs/kn5000_subprogram_v142.rom
    --caps  <dir with kn5000_dsp1_upload_*.txt>   (kn7000_mame/notes/data)
    --tools <kn7000_mame/tools>                   (supplies kn5000_dsp_extract)
"""
import argparse
import collections
import os
import re
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496          # 60-word common header  -> I-RAM 0..59
EPILOGUE_ROM = 0x01E63C        # 23-word output stage   -> I-RAM 60..82
MALFORMED = {79, 88, 89, 90, 91}

HOST_WINDOW_WORD = 352         # I-RAM word address that is the 5-byte word port
HOST_WINDOW_DATA = 353         # ... and the raw 3-byte value port

# the three pointer-set word forms the firmware ever emits, and the coefficient
# packet TAG that follows each (PROVEN BY CONSTRUCTION, see section `builders')
FORM_TAG = {
    ("801", 0, 0x821): 0x26,
    ("801", 0, 0x825): 0x4C,
    ("000", 1, 0x000): 0x15,
}


# --------------------------------------------------------------------------
#  corpus
# --------------------------------------------------------------------------
def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def load_corpus(sub, tools):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    rom = E.Rom(sub)

    def blk(a):
        ir, _c, _o = E.parse_stream(rom, a, limit=40)
        return [int.from_bytes(bytes(w), "big") for w in ir[0][1]] if ir else []

    header, epilogue = blk(HEADER_ROM), blk(EPILOGUE_ROM)
    progs = {}
    for i in range(N_ALGOS):
        p = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            ir, _c, _o = E.parse_stream(rom, p)
        except Exception:
            continue
        if ir:
            progs[i] = [int.from_bytes(bytes(w), "big")
                        for w in (w for _a, ws, _l in ir for w in ws)]
    g = {}
    for a in sorted(progs):
        if a in MALFORMED:
            continue
        g.setdefault(tuple(progs[a]), []).append(a)
    images = sorted([(v[0], v, list(k)) for k, v in g.items()], key=lambda t: t[0])
    return header, epilogue, images


# --------------------------------------------------------------------------
#  section: census
# --------------------------------------------------------------------------
def sec_census(header, epilogue, images):
    print("=" * 74)
    print("CENSUS -- every register-load word in the 3057-word corpus")
    print("=" * 74)
    body = [(r, w) for r, _a, ws in images for w in ws]
    print("corpus: header %d + output stage %d + %d body images (%d words) = %d\n"
          % (len(header), len(epilogue), len(images), len(body),
             len(header) + len(epilogue) + len(body)))

    def show(name, words, base):
        for i, w in enumerate(words):
            hi, c, a, lo = fields(w)
            if (lo & 0x7E0) == 0x020 or (hi == 0x801):
                print("   %-10s w%-4d %010X   %03X.%X.%02X.%03X" %
                      (name, base + i, w, hi, c, a, lo))
    show("header", header, 0)
    show("outstage", epilogue, 60)
    print("   ---- the 38 body images ----")
    n = 0
    for r, _a, ws in images:
        for i, w in enumerate(ws):
            hi, c, a, lo = fields(w)
            if (lo & 0x7E0) == 0x020 or (hi == 0x801):
                print("   algo%-6d w%-4d %010X   %03X.%X.%02X.%03X" %
                      (r, i, w, hi, c, a, lo))
                n += 1
    print("   (%d body words)\n" % n)

    print("re-verification of `no effect body loads a pointer' under six predicates:")
    tests = [
        ("hi12 == 0x801 (the proven ptr-set opcode)",
         lambda h, c, a, l: h == 0x801),
        ("lo12 in {820,821,822,825,827}",
         lambda h, c, a, l: l in (0x820, 0x821, 0x822, 0x825, 0x827)),
        ("(lo12 & 0xFE0) == 0x820   -- the 0x82x block",
         lambda h, c, a, l: (l & 0xFE0) == 0x820),
        ("(lo12 & 0x7E0) == 0x020   -- 0x82x or 0x02x",
         lambda h, c, a, l: (l & 0x7E0) == 0x020),
        ("hi12 == 0x000 and class4 == 1  -- the host D-RAM ptr form",
         lambda h, c, a, l: h == 0x000 and c == 1),
        ("hi12 == 0x000 and class4 == 1 and lo12 == 0x000",
         lambda h, c, a, l: h == 0x000 and c == 1 and l == 0x000),
    ]
    for name, pred in tests:
        nb = sum(1 for _r, w in body if pred(*fields(w)))
        nh = sum(1 for w in header if pred(*fields(w)))
        ne = sum(1 for w in epilogue if pred(*fields(w)))
        print("   %-52s bodies %d/%d  hdr %d  out %d"
              % (name, nb, len(body), nh, ne))
    print()


# --------------------------------------------------------------------------
#  section: builders  (static facts read out of the ASL disassembly)
# --------------------------------------------------------------------------
BUILDERS = """
PROVEN BY CONSTRUCTION -- Sub CPU (TMP94C241F) routines that BUILD DSP words.
Read from archive/asl/subcpu/kn5000_subprogram_v142.asm.  Each pushes 5 bytes
through DSP_DispatchData, then a 5-byte coefficient packet `0A aa bb cc dd'.

  LABEL_0387E6  08 01 (P>>4)&0F  ((P&0F)<<4)|8  21   = 801.0.PP.821  tag 0x26
  LABEL_038922  08 01 (P>>4)&0F  ((P&0F)<<4)|8  25   = 801.0.PP.825  tag 0x4C
  LABEL_03846C  00 00 10|(P>>4)  ((P&0F)<<4)    00   = 000.1.PP.000  tag 0x15
  LABEL_038539  00 00 10|(P>>4)  ((P&0F)<<4)    00   = 000.1.PP.000  tag 0x15
  LABEL_038CF9  idem, but wrapped in its own uC-IF record:
                DSP_DispatchCommand 1 . 01 . 60 . <word> . <packet> . Command 3
                -- the `01 60' is the 16-bit I-RAM word address 0x0160 = 352, so
                the HOST WORD WINDOW is proven by construction, not inferred.

  LABEL_0388B3  -- coefficient packet ALONE, tag 0x26   (continue at the pointer)
  LABEL_038606  -- coefficient packet ALONE, tag 0x15   (continue at the pointer)
  (there is NO continuation writer for tag 0x4C)

  LABEL_038439  -- the `IZ == 1' arm of every builder: DSP_DispatchCommand 0x30
                   plus a 16-bit value.  IZ is the CHIP index and chip 1 is DSP2
                   (MN19413, IC310), whose protocol is completely different.  So
                   all five forms above are uPD6383-only.

Field consequences, read straight off the byte assembly:
  * `INC 8, WA' puts a literal 8 into the HIGH NIBBLE OF lo12 -- lo12 bit 11 is
    built as a separate flag on top of a low byte 0x21 / 0x25.  The in-program
    cursor reset `801.0.00.021' is the SAME low byte with that flag CLEAR.
  * addr8 is assembled as (P>>4) into byte2's low nibble and (P&0xF)<<4 into
    byte3's high nibble: the payload is exactly bits [19:12], 8 bits wide, and
    class4 (byte2's high nibble) is left 0 by the writer.
  * the packet is  V = ((aa&7F)<<17)|(bb<<9)|(cc<<1)|(dd>>7),  tag = dd & 0x7F.
"""


def sec_builders(*_a):
    print("=" * 74)
    print("BUILDERS -- what the firmware constructs")
    print("=" * 74)
    print(BUILDERS)


# --------------------------------------------------------------------------
#  section: host / spaces / boundary
# --------------------------------------------------------------------------
def parse_capture(path):
    xf, cur = [], None
    for line in open(path):
        m = re.match(r"transfer\s+(\d+):\s+cmd\s+0x([0-9A-Fa-f]+)\s+(\d+)\s+bytes", line)
        if m:
            cur = {"n": int(m.group(1)), "cmd": int(m.group(2), 16),
                   "data": bytearray()}
            xf.append(cur)
            continue
        m = re.match(r"\s+([0-9A-Fa-f]{4}):\s+((?:[0-9A-Fa-f]{2}\s*)+)$", line)
        if m and cur is not None:
            cur["data"] += bytes(int(b, 16) for b in m.group(2).split())
    return xf


def replay(path):
    """-> (cells, setaddr, stats).  cells[tag][addr] = last value written."""
    ptr, last = {}, None
    cells = collections.defaultdict(dict)
    setaddr = collections.defaultdict(list)
    stats = {"pkt_tag_eq_lastset": 0, "pkt_tag_ne_lastset": 0, "other": []}
    for x in parse_capture(path):
        d = x["data"]
        if x["cmd"] not in (0x01, 0x02) or len(d) < 2:
            continue
        a0 = (d[0] << 8) | d[1]
        body = d[2:]
        if a0 == HOST_WINDOW_WORD:
            for i in range(0, len(body) - 4, 5):
                b = body[i:i + 5]
                w = int.from_bytes(bytes(b), "big")
                hi, c, ad, lo = fields(w)
                if (hi & 0xE00) == 0xA00:                    # 0xA.. or 0xB.. packet
                    V = ((b[1] & 0x7F) << 17) | (b[2] << 9) | (b[3] << 1) | (b[4] >> 7)
                    tag = b[4] & 0x7F
                    if tag == last:
                        stats["pkt_tag_eq_lastset"] += 1
                    else:
                        stats["pkt_tag_ne_lastset"] += 1
                    p = ptr.get(tag)
                    if p is not None:
                        cells[tag][p] = V
                        ptr[tag] = (p + 1) & 0xFF
                    last = tag
                elif hi == 0x801 and c == 0 and (lo & 0xF00) == 0x800:
                    tag = FORM_TAG.get(("801", 0, lo))
                    ptr[tag] = ad
                    setaddr[tag].append(ad)
                    last = tag
                elif hi == 0x000 and c == 1 and lo == 0x000:
                    ptr[0x15] = ad
                    setaddr[0x15].append(ad)
                    last = 0x15
                else:
                    stats["other"].append(w)
        elif a0 == HOST_WINDOW_DATA:
            p = ptr.get(last)
            for i in range(0, len(body) - 2, 3):
                v = (body[i] << 16) | (body[i + 1] << 8) | body[i + 2]
                if p is not None:
                    cells[last][p] = v
                    p = (p + 1) & 0xFF
            if p is not None:
                ptr[last] = p
    return cells, setaddr, stats


def runs(keys):
    out, s, prev = [], None, None
    for k in sorted(keys):
        if prev is None or k != prev + 1:
            if s is not None:
                out.append((s, prev))
            s = k
        prev = k
    if s is not None:
        out.append((s, prev))
    return out


def boundaries(m):
    """Structural boundaries of a written map, defined MECHANICALLY:
    a block start, or the start of a >=6-long constant-delta run whose arriving
    delta differs.  No hand picking."""
    ks = set(m)
    B = set()
    for c in sorted(ks):
        if (c - 1) not in ks:
            B.add(c)
            continue
        fwd = [m[c + i + 1] - m[c + i] for i in range(6)
               if (c + i + 1) in ks and (c + i) in ks]
        if len(fwd) == 6 and len(set(fwd)) == 1 and (m[c] - m[c - 1]) != fwd[0]:
            B.add(c)
    return B


IN_PROGRAM = [
    ("hdr w42  unit-0", 0x821, 0x70),
    ("hdr w50  unit-1", 0x821, 0x50),
    ("out w69  epilogue", 0x821, 0x90),
    ("hdr w44  unit-0", 0x825, 0x25),
    ("hdr w52  unit-1", 0x825, 0x25),
    ("out w62  epilogue", 0x825, 0x26),
    ("hdr w43  unit-0", 0x827, 0x6C),
    ("hdr w51  unit-1", 0x827, 0x64),
    ("out w77  epilogue", 0x822, 0x86),
]


def sec_host(caps):
    print("=" * 74)
    print("HOST -- the uC-IF captures replayed into a per-register memory map")
    print("=" * 74)
    for name, path in caps:
        cells, setaddr, stats = replay(path)
        print("\n-- %s" % name)
        for tag in sorted(cells):
            r = runs(cells[tag])
            print("   tag %02X : %3d cells  %s" %
                  (tag, len(cells[tag]),
                   " ".join("%02X-%02X" % x if x[0] != x[1] else "%02X" % x[0]
                            for x in r)))
        print("   pointer-set words used by the host, by form:")
        for tag in sorted(setaddr):
            form = [k for k, v in FORM_TAG.items() if v == tag][0]
            print("      %s.%X.**.%03X (tag %02X) : %d sets, addresses %s"
                  % (form[0], form[1], form[2], tag, len(setaddr[tag]),
                     " ".join("%02X" % a for a in sorted(set(setaddr[tag])))))
        print("   packets whose TAG == the most recently SET register : %d" %
              stats["pkt_tag_eq_lastset"])
        print("   packets whose TAG != the most recently SET register : %d" %
              stats["pkt_tag_ne_lastset"])
        if stats["other"]:
            oc = collections.Counter("%03X.%X.%02X.%03X" % fields(w)
                                     for w in stats["other"])
            print("   host words matching NO known form: %d (%d distinct)"
                  % (len(stats["other"]), len(oc)))
            for k, v in sorted(oc.items())[:8]:
                print("      %s x%d" % (k, v))
    print()


def sec_spaces(caps):
    print("=" * 74)
    print("SPACES -- are the three tags three DISTINCT memory spaces?")
    print("=" * 74)
    print("A shared cell that ends the capture holding two DIFFERENT values")
    print("through two different tags cannot be one cell.\n")
    for name, path in caps:
        cells, _s, _st = replay(path)
        print("-- %s" % name)
        tags = sorted(cells)
        for i in range(len(tags)):
            for j in range(i + 1, len(tags)):
                A, B = tags[i], tags[j]
                shared = sorted(set(cells[A]) & set(cells[B]))
                diff = [a for a in shared if cells[A][a] != cells[B][a]]
                print("   tag %02X vs %02X : %3d shared cells, %3d hold DIFFERENT"
                      " final values" % (A, B, len(shared), len(diff)))
        print()


def sec_boundary(caps):
    print("=" * 74)
    print("BOUNDARY -- do the in-program payloads name these same spaces?")
    print("=" * 74)
    for name, path in caps:
        cells, _s, _st = replay(path)
        print("-- %s" % name)
        B = {t: boundaries(cells[t]) for t in cells}
        for t in sorted(B):
            print("   tag %02X boundary set (|B| = %d): %s"
                  % (t, len(B[t]), " ".join("%02X" % b for b in sorted(B[t]))))
        print("   %-20s %-6s %s" % ("word", "value", "  ".join(
            "tag%02X" % t for t in sorted(B))))
        for label, lo, p in IN_PROGRAM:
            row = []
            for t in sorted(B):
                if p in B[t]:
                    row.append("HIT  ")
                elif (p + 1) in B[t]:
                    row.append("hit-1")
                elif p in cells[t]:
                    row.append("in-blk")
                else:
                    row.append("  .  ")
            print("   %-20s %03X<-%02X %s" % (label, lo, p, "  ".join(row)))
        print()


# --------------------------------------------------------------------------
#  section: cfmt
# --------------------------------------------------------------------------
def sec_cfmt(header, epilogue, images):
    print("=" * 74)
    print("CFMT -- the C-format predicate vs the evidence for it")
    print("=" * 74)
    allw = ([("hdr", i, w) for i, w in enumerate(header)]
            + [("out", 60 + i, w) for i, w in enumerate(epilogue)]
            + [("algo%d" % r, i, w) for r, _a, ws in images for i, w in enumerate(ws)])
    grp = collections.defaultdict(list)
    for nm, i, w in allw:
        hi, c, a, lo = fields(w)
        if (hi & 0xF00) == 0xC00:
            grp[(hi & 0xFFE, lo)].append((nm, i, ((hi & 1) << 12) | (c << 8) | a))
    print("%-12s %-5s %-4s %-8s %s" % ("hi12&0xFFE", "lo12", "n", "mult-32", "imm13"))
    for (hi, lo), lst in sorted(grp.items()):
        imms = [x[2] for x in lst]
        m32 = sum(1 for v in imms if v % 32 == 0)
        print("  %03X        %03X   %-4d %d/%-6d %s"
              % (hi, lo, len(lst), m32, len(lst),
                 " ".join("%d(0x%03X)" % (v, v) for v in sorted(set(imms)))))
    inside = [x for (hi, lo), l in grp.items() if hi == 0xC40 for x in l]
    outside = [x for (hi, lo), l in grp.items() if hi != 0xC40 for x in l]
    print("\n  (hi12 & 0xFFE) == 0xC40 : %d/%d multiple of 32"
          % (sum(1 for x in inside if x[2] % 32 == 0), len(inside)))
    print("  the rest of hi12[11:8]==0xC : %d/%d multiple of 32"
          % (sum(1 for x in outside if x[2] % 32 == 0), len(outside)))
    print("  (+ the 4 host-written setvec values 84/42/200/50 makes K5's 61/61.)")
    print()


# --------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.dirname(os.path.dirname(here))
    ap.add_argument("--sub", default=os.path.join(
        repo, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--tools", default=os.path.expanduser(
        "~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--caps", default=os.path.expanduser(
        "~/compartilhado/kn7000_mame/notes/data"))
    ap.add_argument("sections", nargs="*",
                    default=["census", "builders", "host", "spaces",
                             "boundary", "cfmt"])
    args = ap.parse_args()
    caps = [(n, os.path.join(args.caps, "kn5000_dsp1_upload_%s.txt" % n))
            for n in ("coldboot", "parametriceq")]
    caps = [(n, p) for n, p in caps if os.path.exists(p)]
    need_rom = {"census", "builders", "cfmt"} & set(args.sections)
    header = epilogue = images = None
    if need_rom:
        header, epilogue, images = load_corpus(args.sub, args.tools)
    for s in args.sections:
        if s == "census":
            sec_census(header, epilogue, images)
        elif s == "builders":
            sec_builders()
        elif s == "host":
            sec_host(caps)
        elif s == "spaces":
            sec_spaces(caps)
        elif s == "boundary":
            sec_boundary(caps)
        elif s == "cfmt":
            sec_cfmt(header, epilogue, images)
        else:
            sys.exit("unknown section: %s" % s)


if __name__ == "__main__":
    main()
