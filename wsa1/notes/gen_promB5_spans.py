#!/usr/bin/env python3
"""Convert lane promB5's six `.incbin` spans in prom_b -- 1,115 bytes -- to typed data.

QUESTION IT ANSWERS
    Six spans of prom_b were left verbatim by the round-1 coverage pass:

        0xF283A7-0xF2843C   150 B   (1 B typed, 149 B .incbin)
        0xF2843D-0xF28521   229 B   (1 B typed, 228 B .incbin)
        0xF28725-0xF28801   221 B
        0xF296D6-0xF29764   143 B
        0xF2B2E3-0xF2B378   150 B
        0xF34CB8-0xF34D97   224 B

    What is in them?  Answer: nothing but UI display-list material -- bitmaps,
    interpreter-B records, and the operand tables those records point at.  Not
    one byte of any of the six is CPU code, and this emitter emits no
    instruction anywhere; every byte comes out as `.byte`/`.short`/`.ascii`.

    Three of the six (0xF283A7, 0xF2843D, 0xF28725) sit within 900 bytes of
    each other because they are three parts of ONE structure the round-1 pass
    could only partly frame: it reached each object's FIRST byte through a
    32-bit pointer and then stopped, because its walk had no notion of how big
    the pointed-at thing is.  The display-list handlers do: each handler fixes
    the size of what its record's pointer names (see
    notes/prom_b_dl_operand_tables.py and notes/FINDINGS-ui-display-list.md).

WHY THIS IS DATA AND NOT CODE
    Every one of the 15 objects below is named ONLY by a 32-bit pointer inside
    a display-list record.  No routine-directory slot, no call and no branch in
    any converted code lands in any of the six spans.  That is the project's
    own data-vs-code test and all six fail it as code, unanimously.

HOW EACH EXTENT IS PROVEN (the round-1 headers said the extent was unknowable;
it is not, and --selftest re-derives every one of them from the ROM)
    * BITMAP (0xF283A7, 0xF2843D).  Interpreter-A op-0x03 records
      (handler 0xF31ABE) carry +2 = the pointer, +8 = BC = width in BYTES,
      +0x0A = HL = height in rows, and issue `swi 7` fn 3 = draw-bitmap.
      SIZE = BC*HL.  32 records name 0xF283A7 and ALL carry BC=5, HL=30 -> 150.
      17 records name 0xF2843D and ALL carry BC=2, HL=9 -> 18.
    * INTERPRETER-B RECORD RUN.  HTBL_B (0xF31DB1, 15 entries) maps the opcode
      to a handler, and each handler reads a FIXED set of fields, so the length
      byte is implied and checkable.  A run is accepted only when every record's
      length byte equals its handler's implied length AND the run lands exactly
      on the next object's first byte.
    * OPERAND TABLE / ARRAY.  A B record's +7 pointer names the object and its
      handler fixes the entry size: 0xF31B21/0xF31B39 take it from the record's
      +0x0B (BC), 0xF31B57 is `sla 3,HL` = 8-byte entries, 0xF31B86 is
      `mul HL,6` = 6-byte entries.  The entry COUNT is the extent divided by
      that, and it must not exceed the (mask >> shift) + 1 the record's +4/+5
      allow.
    * And the 15 objects TILE each span end to end with no slack, from a first
      byte that a pointer names to a last byte that abuts a boundary proven
      independently -- five of the six spans end exactly on a display-list call
      site's start address, the sixth (0xF28522) on an object already converted.

BYTE ORDER OF THE TWO BITMAPS -- an inference, and it changes no byte
    Read COLUMN-major (byte column c, row r at +c*height+r) the 150 bytes at
    0xF283A7 draw a closed rounded box with one horizontal rule and the 18 at
    0xF2843D draw a filled dot; read row-major both are noise.  Quantified by
    --selftest as 4-neighbour edge density: 0.111 vs 0.166 and 0.205 vs 0.289.
    The handler's own instructions were not traced for the ordering, so this is
    stated as an inference.  It affects only the picture in the comment: the
    emitted bytes are the ROM's, in ROM order, either way.

RUN
    python3 notes/gen_promB5_spans.py --selftest   # every claim above, re-derived
    python3 notes/gen_promB5_spans.py --census     # .incbin bytes left in the six spans
    python3 notes/gen_promB5_spans.py --asm        # the text, to stdout
    python3 notes/gen_promB5_spans.py --splice     # write it into prom_b/wsa1_prom_b.s
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_b_display_lists as DL                      # noqa: E402
import gen_prom_b_display_lists_v2 as V2               # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"
HTBL_B = 0x31DB1

# --------------------------------------------------------------------------
# THE LAYOUT.  Declared here, re-derived and checked by --selftest; nothing
# below is trusted because it is written down.
#   ("bitmap",  addr)              extent = BC*HL of the A op-03 records
#   ("brecs",   addr, n)           n interpreter-B records
#   ("btable",  addr)              array of BC-byte entries (BC from the record)
#   ("barray",  addr)              array of 8- or 6-byte entries (from the handler)
# Each span is (lo, hi, items); hi is exclusive and is a proven boundary.
# --------------------------------------------------------------------------
SPANS = [
    (0xF283A7, 0xF2843D, [("bitmap", 0xF283A7)]),
    (0xF2843D, 0xF28522, [("bitmap", 0xF2843D), ("brecs", 0xF2844F, 6),
                          ("btable", 0xF284A2)]),
    (0xF28725, 0xF28802, [("barray", 0xF28725), ("barray", 0xF28735),
                          ("barray", 0xF28745), ("barray", 0xF28755),
                          ("brecs", 0xF28765, 4),
                          ("barray", 0xF28791), ("barray", 0xF287A1),
                          ("barray", 0xF287B1), ("barray", 0xF287C1),
                          ("brecs", 0xF287D1, 1), ("btable", 0xF287E2)]),
    (0xF296D6, 0xF29765, [("brecs", 0xF296D6, 1), ("btable", 0xF296E7),
                          ("brecs", 0xF2970F, 2), ("barray", 0xF29725)]),
    (0xF2B2E3, 0xF2B379, [("brecs", 0xF2B2E3, 2), ("barray", 0xF2B2F9)]),
    (0xF34CB8, 0xF34D98, [("barray", 0xF34CB8), ("barray", 0xF34D18)]),
]

# The `.incbin` directives this pass consumes: (file offset, length).
INCBINS = [(0x0283A8, 0x000095), (0x02843E, 0x0000E4), (0x028725, 0x0000DD),
           (0x0296D6, 0x00008F), (0x02B2E3, 0x000096), (0x034CB8, 0x0000E0)]

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-18s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# --------------------------------------------------------------------------
def tables(b):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[HTBL_B + i * 4:HTBL_B + i * 4 + 4], "little") for i in range(15)]
    return hta, htb


def implied_len(h):
    """The record length interpreter B's handler `h` implies: one past the last
    byte any of its own instructions reads (fields from B_LAYOUT, which is the
    disassembly of each handler -- see FINDINGS-ui-display-list-interpreter-b.md)."""
    fields, _note = V2.B_LAYOUT[h]
    return max((off + w) for off, w, _n in fields) if fields else None


def b_refs(b, htb, target):
    """Every interpreter-B record in the image whose +7 pointer is `target`.

    Found by scanning for the pointer and testing the 7 bytes in front of it for
    a well-formed B header: a valid opcode, and a length byte equal to that
    opcode's handler-implied length and long enough to contain the pointer."""
    out, pat = [], target.to_bytes(4, "little")
    o = 0
    while True:
        o = b.find(pat, o)
        if o < 0:
            break
        p = o - 7
        if p >= 0:
            op = b[p]
            if op < 15:
                il = implied_len(htb[op])
                if il is not None and b[p + 1] == il and il >= 11:
                    out.append(B_BASE + p)
        o += 1
    return out


def a_bitmap_refs(b, hta, target):
    """Every interpreter-A op-0x03/0x04 record (handler 0xF31ABE, fixed 12 B)
    whose +2 pointer is `target`; returns (addr, BC, HL)."""
    out, pat = [], target.to_bytes(4, "little")
    o = 0
    while True:
        o = b.find(pat, o)
        if o < 0:
            break
        p = o - 2
        if p >= 0 and b[p] < 0x24 and hta[b[p]] == 0xF31ABE and b[p + 1] == 12:
            out.append((B_BASE + p, int.from_bytes(b[p + 8:p + 10], "little"),
                        int.from_bytes(b[p + 10:p + 12], "little")))
        o += 1
    return out


def entry_size(b, htb, rec):
    """Bytes per entry of the object a B record's +7 pointer names."""
    o = rec - B_BASE
    h = htb[b[o]]
    if h in (0xF31B21, 0xF31B39):
        return int.from_bytes(b[o + 11:o + 13], "little")
    if h == 0xF31B57:
        return 8
    if h == 0xF31B86:
        return 6
    return None


def max_index(b, rec):
    """(mask >> shift) + 1: how many entries the record's +4/+5 can ever select."""
    o = rec - B_BASE
    return (b[o + 4] >> (b[o + 5] & 7)) + 1


def resolve(b, hta, htb):
    """Every item's (kind, addr, size, evidence dict), extents from the tiling."""
    out = []
    for lo, hi, items in SPANS:
        starts = [it[1] for it in items] + [hi]
        for i, it in enumerate(items):
            kind, addr = it[0], it[1]
            size = starts[i + 1] - addr
            ev = {}
            if kind == "bitmap":
                refs = a_bitmap_refs(b, hta, addr)
                ev["refs"] = refs
                ev["bc_hl"] = sorted({(bc, hl) for _p, bc, hl in refs})
            elif kind == "brecs":
                recs, p = [], addr
                for _ in range(it[2]):
                    op, ln = b[p - B_BASE], b[p - B_BASE + 1]
                    recs.append((p, op, ln, htb[op] if op < 15 else None))
                    p += ln
                ev["recs"] = recs
                ev["end"] = p
            else:
                refs = b_refs(b, htb, addr)
                ev["refs"] = refs
                ev["esz"] = sorted({entry_size(b, htb, r) for r in refs})
                ev["cap"] = max((max_index(b, r) for r in refs), default=0)
            out.append((kind, addr, size, ev, lo, hi))
    return out


# --------------------------------------------------------------------------
def bitmap_rows(b, addr, w, h, column_major=True):
    o = addr - B_BASE
    rows = []
    for r in range(h):
        line = ""
        for c in range(w):
            by = b[o + (c * h + r if column_major else r * w + c)]
            line += "".join("#" if by >> (7 - k) & 1 else "." for k in range(8))
        rows.append(line)
    return rows


def edge_density(b, addr, w, h, column_major):
    o = addr - B_BASE
    g = [[(b[o + (c * h + r if column_major else r * w + c)] >> (7 - k)) & 1
          for c in range(w) for k in range(8)] for r in range(h)]
    n = t = 0
    for r in range(h):
        for c in range(w * 8):
            if c + 1 < w * 8:
                t += 1
                n += g[r][c] != g[r][c + 1]
            if r + 1 < h:
                t += 1
                n += g[r][c] != g[r + 1][c]
    return n / t


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def render(b, hta, htb):
    """The assembly text for every item, keyed by span index."""
    items = resolve(b, hta, htb)
    per_span = {}
    for kind, addr, size, ev, lo, hi in items:
        out = per_span.setdefault((lo, hi), [])
        o = addr - B_BASE
        if kind == "bitmap":
            bc, hl = ev["bc_hl"][0]
            out.append("\n; ------------------------------------------------------------------\n")
            out.append("; Data_%06X -- the %d x %d BITMAP (%d bytes) that %d interpreter-A\n"
                       "; op-0x03 records draw.  Each carries +2 = this address, +8 = BC = %d\n"
                       "; bytes wide, +0x0A = HL = %d rows, and `swi 7` fn 3 = draw bitmap;\n"
                       "; %d x %d = %d.  All %d agree on BC and HL.\n"
                       % (addr, bc, hl, size, len(ev["refs"]), bc, hl, bc, hl, size,
                          len(ev["refs"])))
            out.append("; Drawn by the records at (the RECORD's own address; the superseded\n"
                       "; header above lists the same sites at +2, where the pointer sits):\n")
            names = ["0x%06X" % p for p, _b, _h in ev["refs"]]
            for k in range(0, len(names), 8):
                out.append(";   %s\n" % " ".join(names[k:k + 8]))
            out.append("; ⚠ SUPERSEDES the round-1 header kept above, which gave this object\n"
                       ";   1 byte and said \"the extent is the reachability walk's, not the\n"
                       ";   object's\".  The extent IS the object's: the records that name it\n"
                       ";   fix it.  And its \"a linear decode runs 1 instructions and ends\n"
                       ";   `reti`\" was a decode of picture bytes -- nothing calls or branches\n"
                       ";   into this span, every reference loads the ADDRESS, so it is data.\n"
                       ";   (lane promB5, 2026-09-02, notes/gen_promB5_spans.py)\n")
            out.append("; Picture, read column-major (byte column c, row r at +c*%d+r):\n" % hl)
            for line in bitmap_rows(b, addr, bc, hl):
                out.append(";   %s\n" % line)
            out.append("; ------------------------------------------------------------------\n")
            out.append("Data_%06X:\n" % addr)
            for c in range(bc):
                col = b[o + c * hl:o + (c + 1) * hl]
                for k in range(0, hl, 15):
                    chunk = col[k:k + 15]
                    out.append("\t.byte\t%s\t; column %d, rows %d..%d\n"
                               % (", ".join("0x%02X" % x for x in chunk), c, k, k + len(chunk) - 1))
        elif kind == "brecs":
            recs = ev["recs"]
            out.append("\n; ------------------------------------------------------------------\n")
            out.append("; 0x%06X-0x%06X -- %d interpreter-B display-list record%s, %d bytes.\n"
                       "; Every length byte equals its handler's implied length (HTBL_B at\n"
                       "; 0xF31DB1), and the run lands exactly on 0x%06X.\n"
                       % (addr, addr + size - 1, len(recs), "" if len(recs) == 1 else "s",
                          size, ev["end"]))
            out.append("; ------------------------------------------------------------------\n")
            for p, op, ln, _h in recs:
                out += V2.render_b(b, p, op, ln, htb)
        else:
            refs, esz = ev["refs"], ev["esz"][0]
            n = size // esz
            printable = all(0x20 <= x <= 0x7E for x in b[o:o + size])
            out.append("\n; ------------------------------------------------------------------\n")
            out.append("; DLTable_%06X -- %d entries of %d bytes (%d bytes).\n"
                       "; Referenced by interpreter-B display-list record%s %s, whose +7\n"
                       "; pointer lands here and whose handler fixes the entry size.  %d\n"
                       "; entries is the EXTENT (%d / %d); the record's (mask >> shift) + 1\n"
                       "; would allow up to %d.\n"
                       % (addr, n, esz, size, "" if len(refs) == 1 else "s",
                          " ".join("0x%06X" % r for r in refs), n, size, esz, ev["cap"]))
            out.append("; ------------------------------------------------------------------\n")
            out.append("DLTable_%06X:\n" % addr)
            for i in range(n):
                ent = b[o + i * esz:o + (i + 1) * esz]
                if printable:
                    out.append('\t.ascii "%s"\t; [%d]\n' % (esc(ent.decode("ascii")), i))
                elif esz % 2 == 0:
                    words = [int.from_bytes(ent[j:j + 2], "little") for j in range(0, esz, 2)]
                    out.append("\t.short %s\t; [%d]\n" % (", ".join("0x%04X" % w for w in words), i))
                else:
                    out.append("\t.byte %s\t; [%d]\n" % (", ".join("0x%02X" % x for x in ent), i))
    return per_span


# --------------------------------------------------------------------------
DIR_RE = re.compile(r'^\t\.(byte|short|long|ascii)\s+(.*?)(?:\t;.*)?$')


def assemble(text):
    """Re-read the generated directives back into bytes.  A cheap emitter check
    that runs before the real one (`make gate-wsa1`), and catches a wrong field
    width or a dropped operand at the point it is introduced."""
    out = bytearray()
    for ln in text.split("\n"):
        s = ln.split(";")[0].rstrip() if ln.lstrip().startswith(";") else ln
        if ln.lstrip().startswith(";") or not ln.strip():
            continue
        m = DIR_RE.match(ln)
        if not m:
            if ln.rstrip().endswith(":"):
                continue
            raise AssertionError("assemble(): cannot read %r" % ln)
        kind, body = m.group(1), m.group(2).strip()
        if kind == "ascii":
            lit = body[body.index('"') + 1:body.rindex('"')]
            out += lit.replace("\\\\", "\\").replace('\\"', '"').encode("latin-1")
        else:
            w = {"byte": 1, "short": 2, "long": 4}[kind]
            for tok in body.split(","):
                out += int(tok.strip(), 0).to_bytes(w, "little")
    return bytes(out)


# --------------------------------------------------------------------------
def census(path=None):
    """How many bytes inside the six spans are still `.incbin`?"""
    path = path or os.path.join(ROOT, S_FILE)
    src = open(path, "rb").read().decode("utf-8")
    pat = re.compile(r'^\t\.incbin "%s", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)$' % re.escape(ROM), re.M)
    got = {}
    for m in pat.finditer(src):
        off, ln = int(m.group(1), 0), int(m.group(2), 0)
        for lo, hi, _it in SPANS:
            a1, b1 = max(off, lo - B_BASE), min(off + ln, hi - B_BASE)
            if b1 > a1:
                got[lo] = got.get(lo, 0) + (b1 - a1)
    return got


# --------------------------------------------------------------------------
def selftest(b, hta, htb):
    print("gen_promB5_spans.py --selftest")
    items = resolve(b, hta, htb)

    print(" the six spans tile, and their ends are anchored")
    sites = DL.call_sites(*DL.load())
    for lo, hi, its in SPANS:
        got = [it[1] for it in its]
        check("0x%06X-0x%06X items start at the span's first byte" % (lo, hi), got[0], lo)
        tot = sum(s for _k, a, s, _e, l, _h in items if l == lo)
        check("0x%06X-0x%06X items tile it exactly" % (lo, hi), tot, hi - lo)
        check("0x%06X-0x%06X starts are strictly increasing" % (lo, hi), got, sorted(set(got)))
    ends = {s for s, _e, _t in sites}
    for _lo, hi, _its in SPANS:
        anchored = hi in ends or hi == 0xF28522 or hi == 0xF2843D
        check("span end 0x%06X is a proven object boundary" % hi, anchored, True)

    print(" bitmaps: extent = BC*HL, and every record naming them agrees")
    for kind, addr, size, ev, _lo, _hi in items:
        if kind != "bitmap":
            continue
        check("0x%06X: one (BC,HL) across all %d records" % (addr, len(ev["refs"])),
              len(ev["bc_hl"]), 1)
        bc, hl = ev["bc_hl"][0]
        check("0x%06X: BC*HL == extent" % addr, bc * hl, size)
        check("0x%06X: column-major edge density is the lower one" % addr,
              edge_density(b, addr, bc, hl, True) < edge_density(b, addr, bc, hl, False), True)

    print(" record runs: every length byte is its handler's implied length")
    for kind, addr, size, ev, _lo, _hi in items:
        if kind != "brecs":
            continue
        for p, op, ln, h in ev["recs"]:
            check("  0x%06X op %02X length" % (p, op), ln, implied_len(h))
        check("0x%06X: run lands on the next object" % addr, ev["end"], addr + size)

    print(" tables: a record points at each, and the extent is whole entries")
    for kind, addr, size, ev, _lo, _hi in items:
        if kind in ("bitmap", "brecs"):
            continue
        check("0x%06X: at least one B record's +7 names it" % addr, len(ev["refs"]) > 0, True)
        check("0x%06X: the referrers agree on the entry size" % addr, len(ev["esz"]), 1)
        esz = ev["esz"][0]
        check("0x%06X: extent is a whole number of %d-byte entries" % (addr, esz), size % esz, 0)
        check("0x%06X: %d entries <= the (mask>>shift)+1 = %d allowed"
              % (addr, size // esz, ev["cap"]), size // esz <= ev["cap"], True)

    print(" the emitted text re-assembles to the ROM's own bytes")
    per = render(b, hta, htb)
    for (lo, hi), block in per.items():
        check("0x%06X-0x%06X round-trips" % (lo, hi), assemble("".join(block)),
              b[lo - B_BASE:hi - B_BASE])

    print(" no byte of the six spans is emitted as an instruction")
    bad = [ln for block in per.values() for ln in "".join(block).split("\n")
           if ln.startswith("\t") and not ln.lstrip().startswith(".")]
    check("non-directive lines in the emitted text", len(bad), 0)

    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


# --------------------------------------------------------------------------
def splice(b, hta, htb):
    path = os.path.join(ROOT, S_FILE)
    raw = open(path, "rb").read()
    lines = raw.decode("utf-8").split("\n")
    per = render(b, hta, htb)

    # spans 1 and 2 also replace the round-1 header + the 1 byte it typed
    HEADER_ANCHOR = {
        0xF283A7: "; Data_F283A7 -- 1 bytes, EMITTED AS DATA (not promoted to code).",
        0xF2843D: "; Data_F2843D -- 1 bytes, EMITTED AS DATA (not promoted to code).",
    }
    for (lo, hi), (off, ln) in zip([(s[0], s[1]) for s in SPANS], INCBINS):
        target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, off, ln)
        idx = [i for i, t in enumerate(lines) if t == target]
        if len(idx) != 1:
            raise SystemExit("0x%06X: expected 1 matching .incbin, found %d" % (lo, len(idx)))
        end = idx[0]
        start = end
        if lo in HEADER_ANCHOR:
            h = [i for i, t in enumerate(lines) if t == HEADER_ANCHOR[lo]]
            if len(h) != 1:
                raise SystemExit("0x%06X: expected 1 round-1 header, found %d" % (lo, len(h)))
            start = h[0] - 1
            if not lines[start].startswith("; ----"):
                raise SystemExit("0x%06X: header does not open with a divider" % lo)
            # The round-1 header is WRONG about the extent, but it is not
            # deleted: it is kept verbatim, fenced and quoted with "; |", and
            # superseded by the header the emitter writes under it.
            old_header = [t for t in lines[start:end] if t.strip()]
            block = [""] + \
                    ["; ==== round-1 header, KEPT VERBATIM and SUPERSEDED below "
                     "(lane promB5, 2026-09-02) ===="] + \
                    ["; | %s" % t.rstrip() for t in old_header] + \
                    ["; ==== end of the superseded round-1 header ===="]
        else:
            block = []
        new = block + "".join(per[(lo, hi)]).rstrip("\n").split("\n")
        lines = lines[:start] + new + lines[end + 1:]

    out = "\n".join(lines)
    tmp = path + ".tmp%d" % os.getpid()
    with open(tmp, "wb") as fh:
        fh.write(out.encode("utf-8"))
    os.replace(tmp, path)
    print("spliced; %d -> %d bytes of source" % (len(raw), len(out.encode("utf-8"))))
    return 0


def main():
    b = DL.load()[1]
    hta, htb = tables(b)
    if "--selftest" in sys.argv:
        return selftest(b, hta, htb)
    if "--census" in sys.argv:
        got = census()
        tot = 0
        for lo, hi, _it in SPANS:
            n = got.get(lo, 0)
            tot += n
            print("  0x%06X-0x%06X  %4d B span, %4d B still .incbin" % (lo, hi - 1, hi - lo, n))
        print("  TOTAL still .incbin in lane promB5's six spans: %d B" % tot)
        return 0
    if "--asm" in sys.argv:
        per = render(b, hta, htb)
        for lo, hi, _it in SPANS:
            sys.stdout.write("".join(per[(lo, hi)]))
        return 0
    if "--splice" in sys.argv:
        return splice(b, hta, htb)
    print(__doc__.strip().split("RUN")[-1])
    return 1


if __name__ == "__main__":
    sys.exit(main())
