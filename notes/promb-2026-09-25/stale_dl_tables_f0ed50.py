#!/usr/bin/env python3
r"""prom_b 0xF0ED50-0xF0EFFF is a remnant of an OLDER BUILD of the display-list interpreter's data.

QUESTION THIS ANSWERS
    Four objects sit between the field-blink engine's last `ret` (0xF0ED4F) and
    the 4 KB boundary 0xF0F000: `PtrTable_F0ED50` (39 words), `Data_F0EDEC`
    (128 bytes), `ArrayDescriptor_F0EE6C` (29 words, stride 72) and `Data_F0EEE0`
    (287 bytes).  Their headers said nothing reads them and "what indexes it, and
    what the entries mean" / "everything about it except its bytes" was unknown.

    They are the display-list interpreter's data block -- the tail of its two
    handler tables, the value-glyph quantiser, the value-glyph pointer table and
    the first four 24x24 value glyphs -- as an EARLIER BUILD laid them out, 0x23001
    bytes lower than this build's live copy at 0xF31D51-0xF31FE0:

      0xF0ED50  39 words  = DisplayList_HandlerTable[12..35] +
                            DisplayListB_HandlerTable[0..14] (live 0xF31D51),
                            each word = the live entry - 0x23000, or - 0x23001
                            for the five whose live target is 0xF31C56 or later
                            (so the old build was one byte shorter somewhere in
                            0xF31C14-0xF31C55 of this one)
      0xF0EDEC  128 bytes = ValueGlyph_Quantiser (0xF31DED), byte for byte
      0xF0EE6C  29 words  = ValueGlyph_Table (0xF31E6D) - 0x23001, word for word:
                            0xF0EEE0 + 72 k
      0xF0EEE0  288 bytes = ValueGlyph_Bitmaps[0..3] (0xF31EE1), byte for byte
                            -- the first FOUR of 29 glyphs; the old glyph 4 would
                            start at 0xF0F000, where this build's bytes differ

    Every one of the four is at its live twin's address - 0x23001, and the run
    ends exactly on the 4 KB boundary 0xF0F000.  In THIS build the old handler
    addresses land in the field-blink engine: 0xF0EA3A is inside
    Blink_Command_Table, others inside instructions -- no working dispatcher
    could use the table.  Nothing in prom_a or prom_b names any of the four
    addresses (32-bit or 24-bit), so the block is dead.  The natural reading is
    that the image was built over an older one and this 688-byte stretch, which
    the new build left unused, kept the old contents; the checks below prove the
    correspondence, not the build history.

    It also corrects a misframe: `RamPtrTable_F0EFFF` ("6 words below 0x10000,
    RAM 0x0E00") started ONE BYTE EARLY.  0xF0EFFF is glyph 3's last byte; the
    aligned words at 0xF0F000-0xF0F017 read 0x0000000E six times, and the
    1-byte `Data_F0F017` was the last byte of the sixth.

    And it removes the seven `<routine>_Arm` labels that
    symbolize_wsa1_rom_addresses.py --arms created only because these two stale
    tables named those addresses (each is named by nothing else).

RUN
    python3 notes/promb-2026-09-25/stale_dl_tables_f0ed50.py            # checks
    python3 notes/promb-2026-09-25/stale_dl_tables_f0ed50.py --apply    # write the source
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE = 0xF00000
DELTA = 0x23001
LIVE_A, LIVE_B = 0xF31D21, 0xF31DB1           # DisplayList_HandlerTable, DisplayListB_HandlerTable
OLD_TAB, OLD_Q, OLD_GT, OLD_G = 0xF0ED50, 0xF0EDEC, 0xF0EE6C, 0xF0EEE0
LIVE_Q, LIVE_GT, LIVE_G = 0xF31DED, 0xF31E6D, 0xF31EE1
ARMS = ["sub_F0EA9F_Arm", "sub_F0EA9F_Arm2", "sub_F0EA9F_Arm3", "sub_F0F105_Arm",
        "sub_F0F315_Arm", "sub_F0F59F_Arm", "sub_F0F676_Arm"]
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    ba = open(ROMA, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    u = lambda a: int.from_bytes(at(a, 4), "little")
    old = [u(OLD_TAB + 4 * k) for k in range(39)]
    live = [u(OLD_TAB + DELTA + 4 * k) for k in range(39)]
    check("0xF0ED50 + 0x23001 = 0xF31D51 = DisplayList_HandlerTable[12] (0xF31D21 + 48)",
          OLD_TAB + DELTA == LIVE_A + 48)
    check("  ... and 0xF31D51 + 24 words = 0xF31DB1 = DisplayListB_HandlerTable[0]",
          LIVE_A + 48 + 24 * 4 == LIVE_B)
    d = [lv - ol for ol, lv in zip(old, live)]
    check("all 39 old words = the live entry - 0x23000 or - 0x23001",
          set(d) <= {0x23000, 0x23001})
    check("  - 0x23001 exactly where the live target is >= 0xF31C56 (%d of them), - 0x23000 "
          "where it is <= 0xF31C14" % d.count(0x23001),
          all((lv >= 0xF31C56) == (x == 0x23001) for lv, x in zip(live, d)) and
          not any(0xF31C14 < lv < 0xF31C56 for lv in live))
    check("0xF0EDEC: 128 bytes identical to ValueGlyph_Quantiser (0xF31DED = 0xF0EDEC + 0x23001)",
          at(OLD_Q, 128) == at(LIVE_Q, 128) and OLD_Q + DELTA == LIVE_Q)
    check("0xF0EE6C: 29 words = ValueGlyph_Table (0xF31E6D) - 0x23001 each, i.e. 0xF0EEE0 + 72 k",
          all(u(OLD_GT + 4 * k) == u(LIVE_GT + 4 * k) - DELTA == OLD_G + 72 * k
              for k in range(29)) and OLD_GT + DELTA == LIVE_GT)
    n = 0
    while at(OLD_G + n, 1) == at(LIVE_G + n, 1):
        n += 1
    check("0xF0EEE0: the first %d bytes = ValueGlyph_Bitmaps (0xF31EE1), i.e. glyphs 0-3 exactly, "
          "and the match stops at 0xF0F000" % n, n == 288 and OLD_G + n == 0xF0F000)
    check("0xF0F000 is 4 KB aligned; the block 0xF0ED50-0xF0EFFF is 688 bytes",
          0xF0F000 % 0x1000 == 0 and 0xF0F000 - OLD_TAB == 688)
    check("0xF0ED4F is `ret` (0x0E), sub_F0EC4A's end -- the old A table's first 12 words "
          "(0xF0ED20-0xF0ED4F) are this build's code", at(0xF0ED4F, 1) == b"\x0e")
    hits = []
    for t in (OLD_TAB, OLD_Q, OLD_GT, OLD_G, 0xF0F000):
        for img, r, base in (("prom_b", b, BASE), ("prom_a", ba, 0xF80000)):
            for w in (t.to_bytes(4, "little"), t.to_bytes(3, "little")):
                i = r.find(w)
                while i >= 0:
                    if not (img == "prom_b" and OLD_TAB <= base + i < 0xF0F000):
                        hits.append((t, img, base + i, len(w)))
                    i = r.find(w, i + 1)
    # the one 24-bit hit is `ld BC,0xf000` at 0xF44AB1 (bytes 31 00 f0 / f0 ...)
    real = [h for h in hits if not (h[0] == 0xF0F000 and h[3] == 3)]
    check("no 32-bit or 24-bit LE occurrence of 0xF0ED50/0xF0EDEC/0xF0EE6C/0xF0EEE0 outside the "
          "block itself (0xF0F000's 3-byte hits are `ld BC,0xf000` and the like)", not real)
    check("0xF0F000-0xF0F017: six LE words 0x0000000E; 0xF0EFFF (glyph 3's last byte) is 0x00",
          all(u(0xF0F000 + 4 * k) == 0x0E for k in range(6)) and at(0xF0EFFF, 1) == b"\x00")
    check("0xF0F018 is a routine-directory target (`jp 0xF0F018` = 1b 18 f0 f0 in 0xF40000-0xF44017)",
          b"\x1b\x18\xf0\xf0" in b[0x40000:0x44018])
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    # this build's reading of the old handler addresses
    starts = {}
    for i, t in enumerate(L):
        m = re.search(r';\s*([0-9A-F]{6})\s', t)
        if m and re.match(r'^\t[a-z]', t) and not t.startswith("\t."):
            starts[int(m.group(1), 16)] = i
    tg = sorted(set(old))
    inside = [x for x in tg if x not in starts]
    check("of the %d distinct old handler addresses, %d are not instruction starts in this build "
          "(0xF0EA3A is Blink_Command_Table + 0x26)" % (len(tg), len(inside)),
          0xF0EA3A in inside and len(inside) >= 1)
    # live table names, from the source
    def table_names(label, n):
        i = [k for k, t in enumerate(L) if t.startswith(label + ":")][0]
        out = []
        for t in L[i + 1:i + 1 + n]:
            m = re.match(r'^\t\.long ([A-Za-z_]\w*)\t; opcode 0x([0-9A-F]{2})$', t)
            out.append((m.group(1), int(m.group(2), 16)))
        return out
    names = table_names("DisplayList_HandlerTable", 36)[12:] + table_names("DisplayListB_HandlerTable", 15)
    check("39 live table names read from the source", len(names) == 39)
    for a in ARMS:
        refs = len(re.findall(r'\b%s\b' % a, txt))
        check("%s: defined once, named only by the two stale tables (%d references)" % (a, refs - 1),
              refs - 1 == sum(1 for t in L if re.match(r'^\t\.long\t%s\t; F0E[DE]' % a, t)))
    return dict(old=old, live=live, d=d, names=names, inside=inside, tg=tg)


BANNER = r"""; ==========================================================================
; 0xF0ED50-0xF0EFFF -- AN OLDER BUILD'S DISPLAY-LIST DATA, LEFT IN PLACE
;   The four objects below are the display-list interpreter's data block as
;   an EARLIER BUILD placed it, 0x23001 bytes below this build's live copy:
;     0xF0ED50  39 words  = DisplayList_HandlerTable[12..35] and
;                           DisplayListB_HandlerTable[0..14] (live 0xF31D51),
;                           each the live entry - 0x23000 (34) or - 0x23001 (5:
;                           the live targets 0xF31C56 and up)
;     0xF0EDEC  128 bytes = ValueGlyph_Quantiser (0xF31DED), byte for byte
;     0xF0EE6C  29 words  = ValueGlyph_Table (0xF31E6D) - 0x23001, word for word
;     0xF0EEE0  288 bytes = ValueGlyph_Bitmaps glyphs 0-3 (0xF31EE1), byte for
;                           byte; the old glyph 4 would begin at 0xF0F000
;   The stretch runs from the blink engine's last `ret` (0xF0ED4F; the old
;   A table's first 12 words would have been 0xF0ED20-0xF0ED4F) to the 4 KB
;   boundary 0xF0F000, where this build's bytes resume.  In this build %d of
;   the %d distinct old handler addresses are not instruction starts --
;   0xF0EA3A is inside Blink_Command_Table -- so no working dispatcher can use
;   the table, and nothing in prom_a or prom_b names any of the four addresses
;   (32-bit or 24-bit).  The table entries are therefore spelled as what they
;   are, `<live handler> - 0x23000`, not as labels of the code that happens to
;   sit at those addresses now.  The reading that the image was built over an
;   older one, and that this unused stretch kept the old bytes, is the natural
;   one; what the checks prove is the correspondence.
;   python3 notes/promb-2026-09-25/stale_dl_tables_f0ed50.py checks every
;   number here.
; =========================================================================="""

TABLE_ANSWER = [
    "; ⚠ ANSWERED 2026-09-25: nothing in this build indexes it, and each entry is",
    ";   the address an OLDER BUILD gave one display-list handler -- see the",
    ";   banner above.  Spelled `<live handler> - 0x2300N` below.",
]
Q_ANSWER = [
    "; ⚠ ANSWERED 2026-09-25 (the \"nothing but its bytes\" verdict that stood",
    ";   here): it is ValueGlyph_Quantiser (0xF31DED) byte for byte, in the older",
    ";   build's position -- see the banner above.",
]
GT_ANSWER = [
    "; ⚠ ANSWERED 2026-09-25: nothing in this build indexes it; it is",
    ";   ValueGlyph_Table (0xF31E6D) with every entry - 0x23001, i.e. the older",
    ";   build's pointers to ITS 29 glyphs.  Only glyphs 0-3 survive (next",
    ";   object); entries 4-28 name 0xF0F000 onwards, which this build filled",
    ";   with other bytes -- spelled `OldBuild_ValueGlyph_Bitmaps + 72 k` below.",
]
G_ANSWER = [
    "; ⚠ ANSWERED 2026-09-25 (the \"nothing but its bytes\" verdict that stood",
    ";   here): ValueGlyph_Bitmaps glyphs 0-3 (0xF31EE1), byte for byte, four",
    ";   24 x 24 dials stored column-major (3 columns x 24 bytes) as swi 7",
    ";   service 3 blits them.  ⚠ CORRECTED: 288 bytes, not 287 -- its last byte,",
    ";   0xF0EFFF, had been taken as the first byte of a word table.",
]
F0F000 = r"""; --------------------------------------------------------------------------
; Data_F0F000 -- 0xF0F000-0xF0F017, 24 bytes: six little-endian words of
;   0x0000000E, just before sub_F0F018 (a routine-directory target).  This is
;   where this build's bytes resume after the older build's data above.
;   Nothing in prom_a or prom_b names 0xF0F000 (the older build's glyph
;   table does, as its glyph 4); purpose not established.
; ⚠ REPLACES `RamPtrTable_F0EFFF` ("6 words below 0x10000 ... RAM 0x0E00" at
;   0xF0EFFF) and the 1-byte `Data_F0F017`: that framing started one byte
;   early -- 0xF0EFFF is glyph 3's last byte -- so every word it read was
;   the true word shifted by 8 bits, and its last byte fell outside it.
;   notes/promb-2026-09-25/stale_dl_tables_f0ed50.py.
; --------------------------------------------------------------------------
Data_F0F000:
	.long	0x0000000E	; F0F000  [0]
	.long	0x0000000E	; F0F004  [1]
	.long	0x0000000E	; F0F008  [2]
	.long	0x0000000E	; F0F00C  [3]
	.long	0x0000000E	; F0F010  [4]
	.long	0x0000000E	; F0F014  [5]"""


def u8(s):
    return s.encode("utf-8").decode("latin-1")


def apply(d):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")

    def find(prefix):
        r = [k for k, t in enumerate(L) if t.startswith(prefix)]
        assert len(r) == 1, (prefix, r)
        return r[0]

    # 1. the misframed word table + the 1-byte object -> Data_F0F000
    s = find("; RamPtrTable_F0EFFF -- ")
    while L[s - 1].startswith(";"):
        s -= 1
    e = find("Data_F0F017:") + 1
    assert L[e].startswith("\t.byte\t0x00\t; F0F017")
    L = L[:s] + [u8(x) for x in F0F000.split("\n")] + L[e + 1:]
    # 2. glyphs: the answer, the 288th byte
    g = find("Data_F0EEE0:")
    k = g - 1
    while not L[k].startswith("; Unknown: everything about it except its bytes."):
        k -= 1
    L[k:k + 1] = [u8(x) for x in G_ANSWER]
    g = find("Data_F0EEE0:")
    last = g + 1
    while L[last + 1].startswith("\t.byte"):
        last += 1
    assert L[last].endswith("; F0EFF0  [272..286]"), L[last]
    L.insert(last + 1, "\t.byte\t0x00\t; F0EFFF  [287]")
    # 3. glyph table: the answer, entries
    t = find("ArrayDescriptor_F0EE6C:")
    k = t - 1
    while not L[k].startswith("; Unknown: what indexes it, and what the entries mean."):
        k -= 1
    L[k:k + 1] = [u8(x) for x in GT_ANSWER]
    t = find("ArrayDescriptor_F0EE6C:")
    for j in range(29):
        m = re.match(r'^\t\.long\t\S+(?: \+ 0x[0-9A-F]+)?\t(; F0E[EF][0-9A-F]{2}  \[%d\] -> .*)$' % j,
                     L[t + 1 + j])
        assert m, L[t + 1 + j]
        L[t + 1 + j] = "\t.long\tOldBuild_ValueGlyph_Bitmaps%s\t%s" % (
            "" if j == 0 else " + 0x%X" % (72 * j), m.group(1))
    # 4. quantiser: the answer
    q = find("Data_F0EDEC:")
    k = q - 1
    while not L[k].startswith("; Unknown: everything about it except its bytes."):
        k -= 1
    L[k:k + 1] = [u8(x) for x in Q_ANSWER]
    # 5. handler table: the answer, the entries, the banner
    p = find("PtrTable_F0ED50:")
    k = p - 1
    while not L[k].startswith("; Unknown: what indexes it, and what the entries mean."):
        k -= 1
    L[k:k + 1] = [u8(x) for x in TABLE_ANSWER]
    k = p - 1
    while not L[k].startswith("; Why UNKNOWN: "):
        k -= 1
    L[k] = L[k].replace("; Why UNKNOWN: ", "; Why UNKNOWN to that tool: ")
    p = find("PtrTable_F0ED50:")
    for j in range(39):
        m = re.match(r'^\t\.long\t\S+(?: \+ 0x[0-9A-F]+)?\t(; F0E[DE][0-9A-F]{2}  \[%d\] -> .*)$' % j,
                     L[p + 1 + j])
        assert m, L[p + 1 + j]
        L[p + 1 + j] = "\t.long\t%s - 0x%X\t%s" % (d["names"][j][0], d["d"][j], m.group(1))
    h = p - 1
    while L[h - 1].startswith(";"):
        h -= 1
    L[h:h] = [u8(x) for x in (BANNER % (len(d["inside"]), len(d["tg"]))).split("\n")]
    txt = "\n".join(L)
    # 6. the seven labels only the stale tables named
    for a in ARMS:
        txt, n = re.subn(r'^%s:\n' % a, "", txt, flags=re.M)
        assert n == 1, a
        assert not re.search(r'\b%s\b' % a, txt), a
    for old, new in (("sub_F0F105_Arm_Skip", "sub_F0F105_Skip"),
                     ("sub_F0F676_Arm_Skip", "sub_F0F676_Skip")):
        assert not re.search(r'\b%s\d*\b' % new, txt), new
        txt = re.sub(r'\b%s(\d*)\b' % old, lambda m: new + m.group(1), txt)
    # 7. the names
    for old, new in (("PtrTable_F0ED50", "OldBuild_DLHandlerTables_Tail"),
                     ("Data_F0EDEC", "OldBuild_ValueGlyph_Quantiser"),
                     ("ArrayDescriptor_F0EE6C", "OldBuild_ValueGlyph_Table"),
                     ("Data_F0EEE0", "OldBuild_ValueGlyph_Bitmaps")):
        txt = re.sub(r'\b%s\b' % old, new, txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC)


def main():
    d = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
