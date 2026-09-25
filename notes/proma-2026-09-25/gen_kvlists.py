#!/usr/bin/env python3
r"""Frame prom_a 0xFAF7A6-0xFB178F by its readers: two identity maps, two tables of
33 key/value record lists, and their zero pad.

QUESTION THIS ANSWERS
    This 8,170-byte stretch sat under the local label `.LFAF7A5` (the `ret` just
    before it), so the data census graded all of it as ONE name-only object.
    The generator that wrote it had marked sub-blocks with comments ("index
    map", "pointer table", "pointer blob + payload") and annotated the pointer
    entries `-> sub_FAF86C` as if they were routines.  They are not: every
    pointer lands on a list of 4-byte records that code COPIES and SEARCHES.

    Readers (all in this module, cited by instruction address):
      0xFAEBEC             sub_FAEBBC: L = RAM(0x603422 + (0x60F31C)),
                           XIY = KeyValueListPtrs_A[L]; copies LE16 words to RAM
                           0x60F330 until a word whose low byte is 0xFF
                           (`ld WA,(XIY+) / ld (XIX+),WA / cp A,0xFF`).
      0xFAF0DB             .LFAF0C1: the same with (0x60F31D) and
                           KeyValueListPtrs_B.
      0xFAF094-0xFAF0A9    sub_FAF055: walks the copy two words at a time and
                           compares the FIRST word with BC (from (0x60F30A), with
                           bit 7 of C/E/D set by bits 2/0/1 of (0x60F308)); on a
                           match `ld WA,(XIY+)` takes the SECOND word.  So a record
                           is (key LE16, value LE16), and 0xFF in a key's low byte
                           ends a list.
      0xFAED53 `ld XIY,0x00FAF7A6` then `ld W,(XIY+HL)`, and `ld XIX,0x00FAF7A6`
                           at 0xFAEF54, 0xFAF1A7, 0xFAF236, 0xFAF2CC, 0xFAF368
      0xFAF420, 0xFAF431, 0xFAF442, 0xFAF453  `ld XIY,0x00FAF7C7`

    CHECKS: both pointer tables hold 33 entries whose targets are distinct,
    ascending and contiguous (lists A are 116 bytes apart, lists B 96); every
    list is N records then an 8-byte run of 0xFF; the two identity maps are
    0..31; the zero pad is all 0x00 and ends where the 0x0E pad begins; the
    whole thing tiles 0xFAF7A6..0xFB1790.

RUN
    python3 notes/proma-2026-09-25/gen_kvlists.py [--apply]
    make gate-wsa1
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
ROM = open(srcmap.ROM, "rb").read()


def g(a, n=1):
    return ROM[a - B:a - B + n]


def u32(a):
    return int.from_bytes(g(a, 4), "little")


def lists(tab, end):
    """[(start, records, tail_bytes)]: records, then a run of 0xFF -- 8 bytes for
    every list but the last, whose run reaches `end` (16 bytes in both tables)."""
    ps = [u32(tab + 4 * k) for k in range(33)]
    out = []
    for k, p in enumerate(ps):
        n = 0
        while g(p + 4 * n)[0] != 0xFF:
            n += 1
        nxt = ps[k + 1] if k + 1 < len(ps) else end
        tail = nxt - (p + 4 * n)
        assert g(p + 4 * n, tail) == b"\xff" * tail, "list 0x%06X: tail not all 0xFF" % p
        assert tail == (8 if k + 1 < len(ps) else 16), (hex(p), tail)
        out.append((p, n, tail))
    return out


def check():
    le = lambda v: v.to_bytes(4, "little")  # noqa: E731
    assert g(0xFAED53, 5) == b"\x45" + le(0xFAF7A6)
    for a in (0xFAEF54, 0xFAF1A7, 0xFAF236, 0xFAF2CC, 0xFAF368):
        assert g(a, 5) == b"\x44" + le(0xFAF7A6), hex(a)
    for a in (0xFAF420, 0xFAF431, 0xFAF442, 0xFAF453):
        assert g(a, 5) == b"\x45" + le(0xFAF7C7), hex(a)
    assert g(0xFAEBEC, 5) == b"\x44" + le(0xFAF7E8) and g(0xFAF0DB, 5) == b"\x44" + le(0xFB0700)
    assert g(0xFAF094, 5) == b"\x45" + le(0x60F330) and g(0xFAF0A1, 2) == b"\xd9\xf0"
    assert list(g(0xFAF7A6, 32)) == list(range(32)) and list(g(0xFAF7C7, 32)) == list(range(32))
    assert g(0xFAF7C6) == b"\x00" and g(0xFAF7E7) == b"\x00"
    A, Bl = lists(0xFAF7E8, 0xFB0700), lists(0xFB0700, 0xFB1394)
    assert A[0][0] == 0xFAF7E8 + 4 * 33 and Bl[0][0] == 0xFB0700 + 4 * 33
    assert set(g(0xFB1394, 0xFB1790 - 0xFB1394)) == {0}
    assert set(g(0xFB1790, 0x70)) == {0x0E}
    return A, Bl


def u8(x):
    return x.encode("utf-8").decode("latin-1")


def emit(A, Bl):
    O = """; ---------------------------------------------------------------------
; 0xFAF7A6-0xFB178F -- two identity maps and two tables of 33 KEY/VALUE record
; lists, framed by their readers (notes/proma-2026-09-25/gen_kvlists.py)
;
; This stretch sat under the local label `.LFAF7A5`, the `ret` before it, and its
; pointer entries were annotated `-> sub_FAF86C` as if they named routines.  They
; name record LISTS that code copies and searches:
;   sub_FAEBBC (0xFAEBEC): L = RAM(0x603422 + (0x60F31C)); XIY =
;     KeyValueListPtrs_A[L]; copies LE16 words to RAM 0x60F330 until a word
;     whose low byte is 0xFF.  .LFAF0C1 does the same with (0x60F31D) and
;     KeyValueListPtrs_B (0xFAF0DB).
;   sub_FAF055 (0xFAF094-0xFAF0A9) walks the copy two words at a time,
;     compares the FIRST word with BC (from (0x60F30A), bit 7 of C/E/D set from
;     bits 2/0/1 of (0x60F308)) and on a match takes the SECOND.
; So a record is (key LE16, value LE16), and a list ends with a record whose
; key's low byte is 0xFF -- 8 bytes of 0xFF (16 after the 33rd).  33 lists:
; 32 of equal length (27 records in A, 22 in B) and a short 33rd (1 and 0).
; ⚠ What a key or a value denotes is not claimed: the keys pair a byte from
; 0xA0-0xBF or 0x00-0x23 with the list's own index 0..31, and the values
; look like (mask 0x01/0x3F/0x7F/0xFF, count) pairs -- a description of the
; bytes, not a decode.
; ---------------------------------------------------------------------

; IdentityMap32_FAF7A6 -- 32 bytes, 0x00..0x1F.
; Read by: 0xFAED53 `ld XIY,0x00FAF7A6 / ld W,(XIY+HL)`, indexed by a slot
;          number read from RAM 0x603422, and `ld XIX,0x00FAF7A6` at 0xFAEF54,
;          0xFAF1A7, 0xFAF236, 0xFAF2CC and 0xFAF368.  Every entry is its own
;          index (an identity translation in this build).
IdentityMap32_FAF7A6:""".split("\n")
    O.append("\t.byte %s  ; FAF7A6" % ", ".join("0x%02x" % x for x in range(16)))
    O.append("\t.byte %s  ; FAF7B6" % ", ".join("0x%02x" % x for x in range(16, 32)))
    O.append("\t.byte 0x00%s; FAF7C6  one byte between the two maps" % (" " * 36))
    O += ["", "; IdentityMap32_FAF7C7 -- 32 bytes, 0x00..0x1F, the same content.",
          "; Read by: `ld XIY,0x00FAF7C7` at 0xFAF420 (sub_FAF420, with XBC = 0x20),",
          ";          0xFAF431, 0xFAF442 and 0xFAF453 -- the four arms of the jump table",
          ";          at 0xFAF410.",
          "IdentityMap32_FAF7C7:"]
    O.append("\t.byte %s  ; FAF7C7" % ", ".join("0x%02x" % x for x in range(16)))
    O.append("\t.byte %s  ; FAF7D7" % ", ".join("0x%02x" % x for x in range(16, 32)))
    O.append("\t.byte 0x00%s; FAF7E7  one byte of alignment slack" % (" " * 36))

    def table(name, tab, ls, reader, tag):
        out = ["", "; %s -- 33 pointers to the key/value record lists below." % name,
               "; Read by: %s; index L = RAM(0x603422 + the slot byte)." % reader,
               "; COUNT 33 is the extent to the first list, and every target is a list start.",
               "%s:" % name]
        for k, (p, n, t) in enumerate(ls):
            out.append("\t.long %-38s; %06X  [%2d]" % ("KeyValueList_%s%02d" % (tag, k), tab + 4 * k, k))
        for k, (p, n, t) in enumerate(ls):
            out += ["", "; KeyValueList_%s%02d -- %d (key, value) records + the 0xFF terminator;" % (tag, k, n),
                    ";          %s[%d]." % (name, k),
                    "KeyValueList_%s%02d:" % (tag, k)]
            for r in range(0, n, 4):
                recs = [(int.from_bytes(g(p + 4 * j, 2), "little"), int.from_bytes(g(p + 4 * j + 2, 2), "little"))
                        for j in range(r, min(n, r + 4))]
                out.append("\t.short %s  ; %06X" % (", ".join("0x%04x, 0x%04x" % kv for kv in recs), p + 4 * r))
            for q in range(0, t, 8):
                out.append("\t.short 0xffff, 0xffff, 0xffff, 0xffff%s; %06X  %s" % (
                    " " * 12, p + 4 * n + q, "terminator" if q == 0 else "0xFF fill to the next object"))
        return out

    O += table("KeyValueListPtrs_A", 0xFAF7E8, A, "sub_FAEBBC at 0xFAEBEC `ld XIX,0x00FAF7E8`", "A")
    O += table("KeyValueListPtrs_B", 0xFB0700, Bl, ".LFAF0C1 at 0xFAF0DB `ld XIX,0x00FB0700`", "B")
    O += ["", "; 0xFB1394-0xFB178F -- 1,020 bytes of 0x00 after the last list, up to the",
          "; module's 0x0E pad; checked all-zero by gen_kvlists.py.  No reader is known.",
          "\t.fill 1020, 1, 0x00%s; FB1394" % (" " * 32)]
    return O


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    A, Bl = check()
    print("identity maps, 33+33 lists (A: %d x %d records + %d; B: %d x %d + %d), zero pad, tiling: OK"
          % (32, A[0][1], A[-1][1], 32, Bl[0][1], Bl[-1][1]))
    if not a.apply:
        return
    L = open(srcmap.SRC, encoding="latin-1").read().split("\n")
    s = L.index("; --- 0xFAF7A6-0xFAF7C6  index map (32 bytes) ---")
    e = L.index("; --- 0xFB1790-0xFB1800  0x0E pad (112 bytes) ---")
    new = L[:s] + [u8(x) for x in emit(A, Bl)] + L[e:]
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(new))
    print("applied: %d lines -> %d" % (e - s, len(emit(A, Bl))))


if __name__ == "__main__":
    main()
