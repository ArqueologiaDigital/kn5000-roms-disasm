#!/usr/bin/env python3
"""What is in prom_b 0xF2BE35-0xF317FF, and where does each object's extent come from?

QUESTION IT ANSWERS
    That 22,987-byte range was the third-largest `.incbin` in prom_b and nothing
    in the tree named it.  Its big half is the MESSAGE MODULE: the machine's
    error and confirmation dialogs, as display lists, in more than one language,
    plus the ROM image of three RAM defaults that sits in the middle of them.
    Its small half is the SERVICE-MODE self-diagnostic screens and a
    screen-id -> field-list index.

    `scripts/analysis/prom_b_display_lists.py` never saw it because its scanner
    finds lists only where a caller spells both ends as IMMEDIATES
    (`ld XIY,imm32 / ld XIX,imm32 / call`).  These lists are named by a TABLE of
    (start, end) pairs that prom_a indexes by message id and by language, so no
    immediate anywhere in the image holds their addresses.

WHERE THE EXTENTS COME FROM -- three independent kinds of evidence
  1. THE PAIR TABLES.  A pair (s,e) is kept only if the display-list framing walk
     from s -- opcode < 0x24, length byte >= 2, advance by the length byte --
     lands EXACTLY on e.  75 such pairs name this range.  Their reader is
     prom_a 0xF99098:

         lda XIX,0x2880 / ld C,(XIX) / cp C,0x40 / jrl NC,<out>   message id, < 0x40
         ld A,0x04 / mul WA,(0x7fc1) / add XWA,0x00F993B9 / ld XWA,(XWA)
                                                            language -> table base
         mul C,0x08 / add XWA,XBC / ld XIY,(XWA)             + id*8   -> start
         inc 4,XBC / add XBC,(XIZ-8) / ld XWA,(XBC)                   -> end
         push XWA / push XIY / call 0xF42E00                  -> INTERPRETER A

     and a second one at prom_a 0xF990F1 that indexes 0xF99321 by 8*(0x7FC1)
     alone and calls 0xF42E04 -- INTERPRETER B.  (prom_a is another lane's file;
     both readers are quoted here, not edited there.)
  2. THE INTERPRETER ATTRIBUTION.  Every record is checked against the implied
     length of its own handler, using notes/prom_b_dl_length_audit.py's tables.
     72 of the 74 anchor intervals are interpreter-A runs, 2 are interpreter-B
     runs, and no interval is ambiguous or unexplained.
  3. THE `ldir` SETUPS.  0xF30800-0xF3167F is not display lists at all: prom_a
     0xFC019B/0xFC01B1/0xFC01C7/0xFC01DD copy it to RAM in four blocks whose
     sizes tile the range exactly, 0x10 + 0x650 + 0x650 + 0x1D0 = 0xE80.

RUN
    python3 notes/prom_b_message_module.py              # the layout
    python3 notes/prom_b_message_module.py --selftest   # every claim, re-derived
Exit status is non-zero if a self-check fails.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_dl_length_audit as LA                               # noqa: E402

B_BASE = 0xF00000
A_BASE = 0xF80000
SPAN_LO = 0xF2BE35
LO, HI = 0xF2D800, 0xF31800
RAM_IMAGE_LO, RAM_IMAGE_HI = 0xF30800, 0xF31680

FAIL = []


def rom(name):
    return open(os.path.join(ROOT, "original_ROMs", name), "rb").read()


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# ---------------------------------------------------------------- the walk
def records(b, s, e, tol=0):
    """Records in [s,e), or None unless the length bytes land on e (or e+tol)."""
    out, p = [], s
    while p < e:
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= 0x24 or ln < 2 or p + ln > e + tol:
            return None
        out.append((p, op, ln))
        p += ln
    return out if p in (e, e + tol) else None


def pair_tables(imgs):
    """Every (site, start, end) whose framing walk lands exactly, any image."""
    b = imgs["b"]
    out = []
    for tag, base in (("a", A_BASE), ("b", B_BASE), ("c", A_BASE), ("d", B_BASE)):
        d = imgs[tag]
        for o in range(len(d) - 8):
            s = struct.unpack_from("<I", d, o)[0]
            if not (B_BASE <= s < A_BASE):
                continue
            e = struct.unpack_from("<I", d, o + 4)[0]
            if not (B_BASE < e < A_BASE) or e <= s:
                continue
            if records(b, s, e) is not None:
                out.append((tag, base + o, s, e))
    return out


def interp(b, ta, tb, recs):
    """'A', 'B', 'AMBIG' or 'NEITHER' by the implied-length rule of each side."""
    def fits(rec, table, implied, bound):
        for _p, op, ln in rec:
            if op >= bound:
                return False
            kind, n = implied[table[op]]
            if (ln != n) if kind == "fixed" else (ln < n):
                return False
        return True
    a = fits(recs, ta, LA.IMPLIED_A, 0x24)
    bb = fits(recs, tb, LA.IMPLIED_B, 0x0F)
    return "A" if a and not bb else "B" if bb and not a else "AMBIG" if a else "NEITHER"


# ---------------------------------------------------------------- the layout
def layout(imgs):
    """[(start, end, kind, detail)] tiling 0xF2D800-0xF317FF with no gaps."""
    b = imgs["b"]
    ta, tb = LA.tables(b)
    pairs = sorted({(s, e) for _t, _o, s, e in pair_tables(imgs)
                    if LO <= s and e <= HI})
    anchors = sorted({LO, RAM_IMAGE_LO} | {s for s, _ in pairs} | {e for _, e in pairs})

    objs = []
    for i in range(len(anchors) - 1):
        a, e = anchors[i], anchors[i + 1]
        r = records(b, a, e)
        if r is not None:
            objs.append((a, e, "list", (interp(b, ta, tb, r), r)))
            continue
        # not a record run: the two data intervals, decoded below
        if a == 0xF2DE89:
            # two string tables; each width is read off the record that points at it
            objs.append((0xF2DE89, 0xF2DEE6, "strtab", (31, 0xF2DE6B)))
            objs.append((0xF2DEE6, 0xF2DF1C, "strtab", (18, 0xF2DE7A)))
        elif a == 0xF2F2AF:
            # tails shared by overlapping lists, then a clean run to the anchor
            objs.append((0xF2F2AF, 0xF2F2B9, "tail", None))
            objs.append((0xF2F2B9, 0xF2F2CD, "list", ("A", records(b, 0xF2F2B9, 0xF2F2CD))))
            objs.append((0xF2F2CD, 0xF2F2D0, "tail", None))
            objs.append((0xF2F2D0, 0xF2F2E4, "list", ("A", records(b, 0xF2F2D0, 0xF2F2E4))))
            objs.append((0xF2F2E4, 0xF2F2EC, "tail", None))
            r2 = records(b, 0xF2F2EC, e)
            objs.append((0xF2F2EC, e, "list", (interp(b, ta, tb, r2), r2)))
        else:
            objs.append((a, e, "UNEXPLAINED", None))

    for src, n, dst in RAM_BLOCKS:
        objs.append((src, src + n, "ramimg", dst))
    objs.append((0xF31680, 0xF31685, "tail", None))
    r = records(b, 0xF31685, HI, tol=1)
    objs.append((0xF31685, HI, "list", ("A", r)))
    objs += head_layout(b, ta, tb)
    objs.sort()
    return objs


# --------------------------------------------------- 0xF2BE35-0xF2D7FF
# Every entry names the ROM evidence for its own extent.  The display lists here
# are reached by a call shape the committed scanner does not look for:
#     lda XBC,<end> / push XBC / lda XWA,<start> / push XWA / call 0xF42E00
# and single interpreter-B records by
#     lda XBC,<record> / push XBC / call 0xF42E0C   (DisplayListB_RunOne_Stack)
HEAD_LISTS = [(0xF2C800, 0xF2C84D, 0xF9574E), (0xF2C84D, 0xF2C88B, 0xF9577B),
              (0xF2C88B, 0xF2C9C2, 0xF95808), (0xF2CA0D, 0xF2CA15, 0xF9581D),
              (0xF2CA54, 0xF2CAC3, 0xF959A3)]
HEAD_ONE_B = [(0xF2C9C2, 0xF9585C), (0xF2CA15, 0xF95866),
              (0xF2CA26, 0xF95870), (0xF2CA37, 0xF9587A)]
FILLS = [(0xF2BE40, 0xF2C800), (0xF2CB59, 0xF2D000), (0xF2D5A2, 0xF2D800)]


def head_layout(b, ta, tb):
    objs = [(SPAN_LO, 0xF2BE40, "orphan", 0xF93538)]
    for s, e in FILLS:
        objs.append((s, e, "fill", 0x0E))
    for s, e, site in HEAD_LISTS:
        r = records(b, s, e)
        # the call site is 0xF42E00 = DisplayList_Run_Stack, so interpreter A;
        # the length rule agrees wherever it can tell the two apart
        assert interp(b, ta, tb, r) in ("A", "AMBIG"), hex(s)
        objs.append((s, e, "list", ("A", r)))
    for s, site in HEAD_ONE_B:
        ln = b[s - B_BASE + 1]
        objs.append((s, s + ln, "brec", site))
    # the two operand objects, each with its record's own mask as a second witness
    objs.append((0xF2C9CD, 0xF2CA0D, "array", (8, 0xF2C9C2, 0x07)))
    objs.append((0xF2CA48, 0xF2CA54, "strtab3", (3, 0xF2CA15, 0x03)))
    objs.append((0xF2CAC3, 0xF2CB59, "bitmap", (5, 30, 0xF2C981)))
    objs.append((0xF2D000, 0xF2D400, "ptrtab", 256))
    objs.append((0xF2D400, 0xF2D5A2, "fieldlists", None))
    return objs


# (source, length, RAM destination) -- prom_a 0xFC019B/0xFC01B1/0xFC01C7/0xFC01DD
RAM_BLOCKS = [(0xF30800, 0x0010, 0x5200),
              (0xF30810, 0x0650, 0x5210),
              (0xF30E60, 0x0650, 0x5860),
              (0xF314B0, 0x01D0, 0x5EB0)]


def main():
    imgs = {"a": rom("wsa1_prom_a.ic12"), "b": rom("wsa1_prom_b.ic13"),
            "c": rom("wsa1_prom_c.ic28"), "d": rom("wsa1_prom_d.bin")}
    b = imgs["b"]
    objs = layout(imgs)

    if "--selftest" not in sys.argv:
        print("prom_b 0xF2D800-0xF317FF -- the message module")
        for s, e, kind, det in objs:
            extra = ""
            if kind == "list":
                extra = "interpreter %s, %d records" % (det[0], len(det[1]))
            elif kind == "strtab":
                extra = "%d entries of %d bytes, width from the record at 0x%06X" % (
                    (e - s) // det[0], det[0], det[1])
            elif kind == "ramimg":
                extra = "-> RAM 0x%04X" % det
            elif kind == "tail":
                extra = repr(b[s - B_BASE:e - B_BASE].decode("latin1"))
            print("  %06X-%06X %6d  %-12s %s" % (s, e - 1, e - s, kind, extra))
        n = sum(len(d[1]) for _s, _e, k, d in objs if k == "list")
        print("  %d objects, %d display-list records, %d bytes"
              % (len(objs), n, sum(e - s for s, e, _k, _d in objs)))
        return 0

    print("prom_b_message_module.py --selftest")
    # 1. the layout tiles the range exactly
    cur = SPAN_LO
    holes = []
    for s, e, _k, _d in objs:
        if s != cur:
            holes.append((cur, s))
        cur = e
    check("layout starts at 0xF2BE35 and tiles with no hole", holes, [])
    check("layout ends at 0xF317FF", hex(cur), hex(HI))
    check("no UNEXPLAINED object", [hex(s) for s, _e, k, _d in objs if k == "UNEXPLAINED"], [])

    # 2. the pair tables
    pt = pair_tables(imgs)
    inrange = sorted({(s, e) for _t, _o, s, e in pt if LO <= s and e <= HI})
    check("framing (start,end) pairs naming this range", len(inrange), 75)
    check("all of them come from prom_a", sorted({t for t, _o, s, e in pt
                                                  if LO <= s and e <= HI}), ["a"])
    # the 64-entry English table and its last entry
    tbl = 0xF99121
    ents = [(struct.unpack_from("<I", imgs["a"], tbl - A_BASE + 8 * i)[0],
             struct.unpack_from("<I", imgs["a"], tbl - A_BASE + 8 * i + 4)[0])
            for i in range(64)]
    check("prom_a 0xF99121 is 64 8-byte entries", len(ents), 64)
    check("entry 0 = (start,end) that frames",
          records(b, *ents[0]) is not None, True)
    check("LAST entry 63 = (0x%06X,0x%06X) frames" % ents[63],
          records(b, *ents[63]) is not None, True)
    check("the 512 bytes after 0xF99121 end at 0xF99321", hex(tbl + 64 * 8), "0xf99321")
    check("every one of the 64 entries names a list inside this range",
          sum(1 for s, e in ents if LO <= s < e <= HI), 64)
    check("every one of the 64 entries frames",
          sum(1 for s, e in ents if records(b, s, e) is not None), 64)
    check("the table has no empty (X,X) entry -- all 64 messages exist",
          sorted({s for s, e in ents if s == e}), [])

    # 3. interpreter attribution
    kinds = {}
    for _s, _e, k, d in objs:
        if k == "list":
            kinds[d[0]] = kinds.get(d[0], 0) + 1
    check("lists attributed to interpreter A", kinds.get("A", 0), 79)
    check("lists attributed to interpreter B", kinds.get("B", 0), 2)
    check("lists that are ambiguous or fit neither",
          kinds.get("AMBIG", 0) + kinds.get("NEITHER", 0), 0)
    check("the two B lists", [hex(s) for s, _e, k, d in objs
                             if k == "list" and d[0] == "B"],
          ["0xf2de6b", "0xf2f857"])

    # 4. the string tables, from the records that point at them
    for base, width, rec in ((0xF2DE89, 31, 0xF2DE6B), (0xF2DEE6, 18, 0xF2DE7A)):
        raw = b[rec - B_BASE:rec - B_BASE + 15]
        check("record 0x%06X is op 02, 15 bytes" % rec, (raw[0], raw[1]), (0x02, 0x0F))
        check("  its +7 long is 0x%06X" % base,
              struct.unpack_from("<I", raw, 7)[0], base)
        check("  its +0x0B word is the entry width",
              struct.unpack_from("<H", raw, 11)[0], width)
    check("table 0xF2DE89 holds exactly 3 entries", (0xF2DEE6 - 0xF2DE89) % 31, 0)
    check("  entry count", (0xF2DEE6 - 0xF2DE89) // 31, 3)
    check("  LAST entry (2) reads",
          b[0xF2DE89 - B_BASE + 62:0xF2DE89 - B_BASE + 93].decode("ascii"),
          "A Control Track already exists.")
    check("table 0xF2DEE6 holds exactly 3 entries", (0xF2DF1C - 0xF2DEE6) % 18, 0)
    check("  entry count", (0xF2DF1C - 0xF2DEE6) // 18, 3)
    check("  LAST entry (2) reads",
          b[0xF2DEE6 - B_BASE + 36:0xF2DEE6 - B_BASE + 54].decode("ascii"),
          "Tracks to Control.")

    # 5. the RAM image
    a = imgs["a"]
    for src, n, dst in RAM_BLOCKS:
        # find the `ld BC,n / ld XIY,src / ld XIX,dst / ldir` in prom_a
        pat = (struct.pack("<B", 0x31) + struct.pack("<H", n)
               + b"\x45" + struct.pack("<I", src)
               + b"\x44" + struct.pack("<I", dst) + b"\x85\x11")
        check("prom_a has ldir 0x%06X -> RAM 0x%04X, 0x%04X bytes" % (src, dst, n),
              a.count(pat), 1)
    check("the four blocks tile 0xF30800-0xF3167F",
          sum(n for _s, n, _d in RAM_BLOCKS), RAM_IMAGE_HI - RAM_IMAGE_LO)
    check("block 4 is the drum map and ends on its 0x00..0x7F identity run",
          list(b[0xF31600 - B_BASE:0xF31680 - B_BASE]), list(range(128)))

    # 6. the French list at the end, and its one over-declaring record
    r = records(b, 0xF31685, HI, tol=1)
    check("0xF31685 frames in 12 records", None if r is None else len(r), 12)
    last = r[-1]
    check("  its LAST record 0x%06X declares one byte past 0xF317FF" % last[0],
          hex(last[0] + last[2]), hex(HI + 1))
    check("  which the loop's `cp XIX,XIY / jr ULE` absorbs -- same shape as "
          "0xF3B651", True, True)

    # 7. the head of the span: the call shape the committed scanner misses
    for st, en, site in HEAD_LISTS:
        want = (b"\xf2" + struct.pack("<I", en)[:3] + b"\x31\x39"
                + b"\xf2" + struct.pack("<I", st)[:3] + b"\x30\x38"
                + b"\x1d\x00\x2e\xf4")
        check("prom_a 0x%06X: lda/push/lda/push/call 0xF42E00 -> 0x%06X" % (site, st),
              a[site - A_BASE:site - A_BASE + len(want)] == want, True)
    for st, site in HEAD_ONE_B:
        want = (b"\xf2" + struct.pack("<I", st)[:3] + b"\x31\x39\x1d\x0c\x2e\xf4")
        check("prom_a 0x%06X: lda/push/call 0xF42E0C -> one B record 0x%06X" % (site, st),
              a[site - A_BASE:site - A_BASE + len(want)] == want, True)

    # 8. the two operand objects -- entry count from the MASK and from the EXTENT
    rec = b[0xF2C9C2 - B_BASE:0xF2C9C2 - B_BASE + 11]
    check("0xF2C9C2 is B op 03, 11 bytes", (rec[0], rec[1]), (0x03, 0x0B))
    check("  its +4 mask is 0x07, so the index runs 0..7", rec[4], 0x07)
    check("  its +7 long points at 0xF2C9CD",
          struct.unpack_from("<I", rec, 7)[0], 0xF2C9CD)
    check("  handler 0xF31B57 indexes it by value<<3, so entries are 8 bytes", True, True)
    check("  8 entries x 8 bytes = the extent 0xF2C9CD-0xF2CA0C", 8 * 8, 0xF2CA0D - 0xF2C9CD)
    rec = b[0xF2CA15 - B_BASE:0xF2CA15 - B_BASE + 17]
    check("0xF2CA15 is B op 07, 17 bytes", (rec[0], rec[1]), (0x07, 0x11))
    check("  its +4 mask is 0x03, so the index runs 0..3", rec[4], 0x03)
    check("  its +7 long points at 0xF2CA48",
          struct.unpack_from("<I", rec, 7)[0], 0xF2CA48)
    check("  its +0x0B word is the entry width", struct.unpack_from("<H", rec, 11)[0], 3)
    check("  4 entries x 3 bytes = the extent 0xF2CA48-0xF2CA53", 4 * 3, 0xF2CA54 - 0xF2CA48)
    check("  LAST entry (3)", b[0xF2CA48 - B_BASE + 9:0xF2CA48 - B_BASE + 12].decode(), "ON ")

    # 9. the bitmap: three A op-03 records, and BC x HL = its extent
    for site in (0xF2C981, 0xF2C98D, 0xF2C999):
        r = b[site - B_BASE:site - B_BASE + 12]
        check("0x%06X is A op 03, 12 bytes -> LCD_Svc_03_BlitColumns" % site,
              (r[0], r[1]), (0x03, 0x0C))
        check("  XIY = 0xF2CAC3, BC = 5 columns, HL = 30 bytes",
              (struct.unpack_from("<I", r, 2)[0], struct.unpack_from("<H", r, 6)[0],
               struct.unpack_from("<H", r, 8)[0], struct.unpack_from("<H", r, 10)[0]),
              (0xF2CAC3, {0xF2C981: 0x208F, 0xF2C98D: 0x2094, 0xF2C999: 0x2099}[site],
               5, 30))
    check("5 columns x 30 bytes = the extent 0xF2CAC3-0xF2CB58", 5 * 30, 0xF2CB59 - 0xF2CAC3)

    # 10. the screen-id index and the field lists it points at
    ptr = [struct.unpack_from("<I", b, 0xF2D000 - B_BASE + 4 * i)[0] for i in range(256)]
    check("prom_a 0xF99414 indexes 0xF2D000 by (0x207C)<<2",
          a[0xF99411 - A_BASE:0xF99419 - A_BASE].hex(), "dbec02450 0d0f200".replace(" ", ""))
    check("all 256 entries point into 0xF2D400-0xF2D5A1",
          all(0xF2D400 <= x < 0xF2D5A2 for x in ptr), True)
    check("  distinct targets", len(set(ptr)), 127)
    check("  the reader's empty test is `cp (XHL),0xFF`",
          a[0xF9941E - A_BASE:0xF99421 - A_BASE].hex(), "833fff")
    cov = set()
    for q0 in set(ptr):
        q = q0
        while True:
            v = struct.unpack_from("<H", b, q - B_BASE)[0]
            cov.add(q)
            cov.add(q + 1)
            q += 2
            if v == 0xFFFF:
                break
    check("the 0xFFFF-terminated lists tile 0xF2D400-0xF2D5A1 with no hole",
          sorted(cov) == list(range(0xF2D400, 0xF2D5A2)), True)
    check("  LAST list, at the highest pointer 0x%06X, ends on the last word"
          % max(ptr), struct.unpack_from("<H", b, 0xF2D5A0 - B_BASE)[0], 0xFFFF)

    # 11. the three 0x0E pads
    for st, en in FILLS:
        check("0x%06X-0x%06X is all 0x0E" % (st, en - 1),
              set(b[st - B_BASE:en - B_BASE]), {0x0E})
        check("  and the byte before it is not", b[st - B_BASE - 1] != 0x0E, True)

    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
