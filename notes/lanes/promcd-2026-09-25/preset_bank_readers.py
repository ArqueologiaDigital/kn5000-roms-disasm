#!/usr/bin/env python3
r"""Who reads prom_c's preset bank (0xF80000-0xF965BF), and what is each record?

QUESTION THIS ANSWERS
    wsa1/prom_c/data_tables/preset_bank.s said, until 2026-09-25, that "NO
    INSTRUCTION THAT READS THIS REGION HAS BEEN FOUND" and that "NOT ONE FIELD
    MEANING is established".  Both are false.  The region is read by CPU 1
    (prom_a) over the inter-processor link, by five routines whose constants
    ARE the region's geometry, and it is the factory COMBINATION memory in the
    exact format the SysEx reference (wsa1/docs/system-exclusive-reference/
    sec-blocks.tex, "Inside the COMBINATION block") and
    wsa1/notes/sysex-probes/sysex_combination_layout.py already decode.

    This script ASSERTS every instruction byte that claim rests on, against
    wsa1/original_ROMs, and (with --apply) writes the evidence into the source:
    one READERS/FIELDS paragraph in the banner and, above each of the 129
    records, the bank and memory number the readers address it by.

WHY THE EARLIER SEARCH MISSED IT
    It searched all four images for a 32-bit pointer into the region and then
    discarded prom_a's hits as "ambiguous by construction" (prom_a is ALSO
    mapped at 0xF80000, in CPU 1's own space).  The readers are exactly those
    prom_a hits: they build a CPU-2 address and hand it to the 0xE2 remote
    read, so the address never names CPU 1's own ROM.

SIGNAL READ
    original_ROMs/wsa1_prom_a.ic12 @0xF80000, wsa1_prom_b.ic13 @0xF00000,
    wsa1_prom_c.ic28 @0xF80000.  Every (address, bytes) pair below is an
    instruction encoding; a mismatch aborts.

RUN
    python3 notes/lanes/promcd-2026-09-25/preset_bank_readers.py            # check, print
    python3 notes/lanes/promcd-2026-09-25/preset_bank_readers.py --apply    # + edit the .s
    PASS = "ALL ASSERTIONS HOLD".  --apply refuses to run twice.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
ROM = {k: open(os.path.join(W, "original_ROMs", f), "rb").read()
       for k, f in (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"),
                    ("c", "wsa1_prom_c.ic28"))}
BASE = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
SRC = os.path.join(W, "prom_c", "data_tables", "preset_bank.s")


def at(img, addr, n):
    o = addr - BASE[img]
    return ROM[img][o:o + n]


def h(s):
    return bytes.fromhex(s.replace(" ", ""))


# (image, address, encoding, what the instruction is, why it matters)
CHECKS = [
    # the transport: prom_b directory slot -> prom_a Link_SendCommandE2
    ("b", 0xF40EF0, "1b fe e0 f8", "jp 0xF8E0FE", "T_Link_SendCommandE2 -> Link_SendCommandE2 (0xE2 remote read)"),
    ("b", 0xF4123C, "1b 6d e6 f8", "jp 0xF8E66D", "T_Link_WaitBlockDone -> Link_WaitBlockDone"),
    ("a", 0xF8E0FE, "ee 0c 00 00", "link XIZ,0", "Link_SendCommandE2 entry"),
    # sub_F9F984: combination pointer, 0xF80300 + 0x1600*H + 0x2C0*L
    ("a", 0xF9F9BC, "d9 08 c0 02", "mul BC,0x02c0", "sub_F9F984: memory stride 704"),
    ("a", 0xF9F9C6, "d8 08 00 16", "mul WA,0x1600", "sub_F9F984: bank stride 5632 = 8 x 704"),
    ("a", 0xF9F9CC, "e8 c8 00 03 f8 00", "add XWA,0x00f80300", "sub_F9F984 mode 0, bank <= 10"),
    ("a", 0xF9F9DF, "e9 c8 00 f5 f8 00", "add XBC,0x00f8f500", "sub_F9F984 mode 0, bank 11 = 0xF80300 + 11*0x1600"),
    ("a", 0xF9FA08, "e9 c8 00 0b f9 00", "add XBC,0x00f90b00", "sub_F9F984 mode 0, bank >= 12 = 0xF80300 + 12*0x1600"),
    ("a", 0xF9FA35, "e8 c8 00 03 ec 00", "add XWA,0x00ec0300", "sub_F9F984 mode 8: CPU 2 flash, the user bank"),
    # sub_F9F910: bank-name pointer, 0xF80200 + 0x10*H
    ("a", 0xF9F92F, "23 10", "ld C,0x10", "sub_F9F910: name stride 16"),
    ("a", 0xF9F931, "ce 43", "mul8rr C,H", "sub_F9F910: indexed by the bank H alone"),
    ("a", 0xF9F935, "e9 c8 00 02 f8 00", "add XBC,0x00f80200", "sub_F9F910 mode 0: the bank-name table"),
    # sub_F9FAE9: the (src, len, dst) remote-read veneer both of those feed
    ("a", 0xF9FAF8, "1d f0 0e f4", "call 0xF40EF0", "sub_F9FAE9 -> T_Link_SendCommandE2"),
    ("a", 0xF9FAFC, "1d 3c 12 f4", "call 0xF4123C", "sub_F9FAE9 -> T_Link_WaitBlockDone"),
    # sub_F98927: one combination by linear index -> CPU 1 RAM 0x7620
    ("a", 0xF98955, "41 00 03 f8 00", "ld XBC,0x00f80300", "sub_F98927 mode 0 / 0x10"),
    ("a", 0xF98962, "d8 08 c0 02", "mul WA,0x02c0", "sub_F98927: index * 704"),
    ("a", 0xF9896A, "f1 20 76 31", "lda XBC,(0x7620)", "sub_F98927: CPU 1 destination"),
    ("a", 0xF9896F, "0b c0 02", "pushw 0x02c0", "sub_F98927: length 704"),
    ("a", 0xF98973, "1d f0 0e f4", "call 0xF40EF0", "sub_F98927 -> T_Link_SendCommandE2"),
    # sub_FAABB3: combination 0 itself -> CPU 1 RAM 0x7300
    ("a", 0xFAABE9, "f1 00 73 31", "lda XBC,(0x7300)", "sub_FAABB3: CPU 1 destination"),
    ("a", 0xFAABEE, "0b c0 02", "pushw 0x02c0", "sub_FAABB3: length 704"),
    ("a", 0xFAABF1, "40 00 03 f8 00", "ld XWA,0x00f80300", "sub_FAABB3: combination 0"),
    ("a", 0xFAABF7, "1d f0 0e f4", "call 0xF40EF0", "sub_FAABB3 -> T_Link_SendCommandE2"),
    # sub_FC1C77: the 16-byte NAME at +2 of a combination -> 0x810
    ("a", 0xFC1C86, "44 00 03 f8 00", "ld XIX,0x00f80300", "sub_FC1C77, W < 8: the preset bank"),
    ("a", 0xFC1CA0, "d8 08 c0 02", "mul WA,0x02c0", "sub_FC1C77: index * 704"),
    ("a", 0xFC1CA6, "ec c8 02 00 00 00", "add XIX,0x00000002", "sub_FC1C77: +2 = the name, past tag 0x78 and length 0x10"),
    ("a", 0xFC1CB2, "0b 10 00", "pushw 0x10", "sub_FC1C77: length 16"),
    ("a", 0xFC1CB6, "1d f0 0e f4", "call 0xF40EF0", "sub_FC1C77 -> T_Link_SendCommandE2"),
    # the region itself
    # sub_FC2155 / sub_FC21D0: the block base itself, + 0x200 + 0x10*bank -> a bank name
    ("a", 0xFC2173, "45 00 00 f8 00", "ld XIY,0x00f80000", "sub_FC2155, W < 8: the block base"),
    ("a", 0xFC2197, "ed 8c", "ld XIX,XIY", "sub_FC2155 hands the base to sub_FC21D0"),
    ("a", 0xFC21D0, "ec c8 00 02 00 00", "add XIX,0x00000200", "sub_FC21D0: + 0x200 = the bank names"),
    ("a", 0xFC21D8, "d8 08 10 00", "mul WA,0x0010", "sub_FC21D0: bank * 16"),
    ("a", 0xFC21E4, "0b 10 00", "pushw 0x10", "sub_FC21D0: length 16"),
    ("a", 0xFC21E8, "1d f0 0e f4", "call 0xF40EF0", "sub_FC21D0 -> T_Link_SendCommandE2"),
    ("c", 0xF80000, "5a 5a 5a 5a 00 00 57 53 41 31 20 20 01 00 00 02",
     'ASCII "ZZZZ", 0, "WSA1  ", id 1, 0x0200', "the same 16 bytes the SysEx reference prints for block COMBINATION 1 (ADR 50 00 00)"),
    ("c", 0xF80200, b"FUSION COMBO1   ".hex(), '"FUSION COMBO1   "', "bank name 0"),
    ("c", 0xF80300, "78 10", "tag 0x78, length 16", "combination 0 opens with its name record"),
]

COMB, BANK, NAMES, DATA = 0x2C0, 0x1600, 0xF80200, 0xF80300


def walk(o):
    out = []
    while ROM["c"][o] != 0xFF:
        t, l = ROM["c"][o], ROM["c"][o + 1]
        out.append((t, l))
        o += 2 + l
    return out, o


def check():
    bad = 0
    for img, addr, enc, ins, why in CHECKS:
        got = at(img, addr, len(h(enc)))
        ok = got == h(enc)
        bad += not ok
        print("  %s prom_%s 0x%06X  %-28s %-38s %s" % ("ok " if ok else "BAD", img, addr,
                                                        got.hex(" "), ins, why))
    assert BANK == 8 * COMB, "the bank stride is not eight combinations"
    for folded, hh in ((0xF8F500, 11), (0xF90B00, 12)):
        assert folded == DATA + hh * BANK, "0x%06X is not 0xF80300 + %d*0x1600" % (folded, hh)
    shape = None
    recs = []
    for i in range(129):
        o = DATA - BASE["c"] + i * COMB
        s, end = walk(o)
        assert end - o == COMB - 2 and ROM["c"][end:end + 2] == b"\xFF\xFF", i
        shape = shape or s
        assert s == shape, "record %d desynchronised" % i
        recs.append(ROM["c"][o + 2:o + 18].decode("latin-1"))
    banks = [at("c", NAMES + 16 * k, 16).decode("latin-1") for k in range(16)]
    assert not bad, "%d instruction assertion(s) failed" % bad
    return banks, recs


BANNER_ANCHOR = b"; \xe2\x98\x85 ONE FIELD IS PROVEN, and it is what makes the eight paired blocks an indexed\n"
BANNER = """\
; ⚠⚠ RETRACTED 2026-09-25 (lane promcd) -- THE FIRST TWO BULLETS ABOVE ARE FALSE (the
;   third, the directory-entry ambiguity, still stands).  They are kept verbatim so the
;   record of what was believed survives; do not quote them.
;
; ★ READERS.  CPU 1 reads this region over the inter-processor link.  The pointer search
;   above discarded prom_a's hits as ambiguous; the readers ARE those hits.  Six prom_a
;   routines build an address in CPU 2's space from this region's own constants and hand
;   it to Link_SendCommandE2 (prom_a 0xF8E0FE, via prom_b thunk 0xF40EF0), the 0xE2
;   REMOTE READ whose frame is (remote address, length, local buffer):
;     sub_F9F984 (0xF9F984)  mode 0: 0xF80300 + 0x1600*bank + 0x2C0*memory, bank 0..15,
;                            memory 0..7 (mode 8: CPU 2 flash 0xEC0300, the USER bank;
;                            mode 0x10: a RAM working copy at 0xC00300)
;     sub_F9F910 (0xF9F910)  mode 0: 0xF80200 + 0x10*bank -- PresetBank_CategoryNames,
;                            indexed by the bank alone: 16 names for 16 banks of 8
;     sub_F98927 (0xF98927)  0xF80300 + 0x2C0*index, 0x2C0 bytes -> CPU 1 RAM 0x7620
;     sub_FAABB3 (0xFAABB3)  0xF80300 itself (combination 0), 0x2C0 bytes -> CPU 1 RAM 0x7300
;     sub_FC1C77 (0xFC1C77)  0xF80300 + 0x2C0*index + 2, 16 bytes -> 0x810: the NAME alone
;     sub_FC21D0 (0xFC21D0)  base 0xF80000 (loaded by sub_FC2155) + 0x200 + 0x10*bank,
;                            16 bytes -> 0x810: one bank name
;   So the record stride 0x2C0 = 704 and the bank stride 0x1600 = 8 x 704 are the
;   READERS' constants, not only the data's; sub_F9F984's three branches (0xF80300,
;   0xF8F500, 0xF90B00) are one linear array, 0xF8F500 = 0xF80300 + 11*0x1600 exactly.
;
; ★ WHAT IT IS.  The factory COMBINATION memory: 16 banks x 8 combinations, the same
;   format as the SysEx COMBINATION bulk-dump category (ADR 50 00 00), whose first block's
;   16-byte signature 5A 5A 5A 5A 00 00 57 53 41 31 20 20 01 00 00 02 is this region's
;   first 16 bytes, and whose 0x300-byte header block is 0xF80000-0xF802FF.  The user
;   bank (mode 8) has the same shape, names 0x100 below the data at 0xEC0200.
;   Each tag is the instrument's own parameter-record number (the same number that
;   addresses the record in a parameter message), so the chunk table above reads:
;     0x78 COMBINATION NAME   0x60 EFFECT COMMON   0x61 EFFECT block 1   0x62 EFFECT block 2
;     0x63 REVERB block       0x00+k / 0x20+k  PART k+1, individual blocks A / B
;     0x92 KEY SCALING / SCALE TUNING              0x79 PART COMMON (real time)
;   Field-level names (PROGRAM CHANGE & BANK at A+0x00, VOLUME at A+0x03, PANPOT at
;   A+0x08, KEY LAYER LOW/HIGH at B+0x07/+0x08 ...) and the range checks that pin them
;   over all 129 presets: `python3 wsa1/notes/sysex-probes/sysex_combination_layout.py
;   --fields`.  Corroboration from CPU 1's use: 0xFAAB86-0xFAABA6 takes the first payload
;   byte of each effect record out of the copy at 0x7620 (0x7642 / 0x7662 / 0x7682 =
;   0x7620 + 0x22 / 0x42 / 0x62) and passes it with the record number 0x61 / 0x62 / 0x63
;   to prom_b 0xF42F58 -- the effect TYPE, where the reference puts it.
;   The ONE FIELD below is thereby named: payload +0x0D of an A block (tags 0x00..0x07)
;   is BASIC CHANNEL in bits 0-4, LOCAL CONTROL bit 5, MIDI OUT SETTING bit 6, MIDI IN
;   SETTING bit 7 (--fields).  Its low nibble equals the tag because each factory part k
;   is on basic channel k; the high nibble 0xC / 0xE is LOCAL CONTROL off / on, which
;   supersedes the [INFERENCE] "in-use flag" below.
;   Every instruction byte above is asserted by
;   `python3 notes/lanes/promcd-2026-09-25/preset_bank_readers.py`; the reference is
;   wsa1/docs/system-exclusive-reference/sec-blocks.tex, "Inside the COMBINATION block".
;
"""


def apply(banks, recs):
    raw = open(SRC, "rb").read()
    if b"RETRACTED 2026-09-25 (lane promcd)" in raw:
        sys.exit("already applied")
    assert raw.count(BANNER_ANCHOR) == 1, "banner anchor not unique"
    raw = raw.replace(BANNER_ANCHOR, BANNER.encode("utf-8") + BANNER_ANCHOR)
    fh = b"; filed as DATA, not under a subsystem that would claim to read it.\n"
    assert raw.count(fh) == 1
    raw = raw.replace(fh, fh + ("; \u26a0 RETRACTED 2026-09-25: a consumer HAS been located -- CPU 1 reads it over the\n"
                                "; link; see READERS in the banner below.\n").encode("utf-8"))
    hd = b"PresetBank_Header:\n"
    assert raw.count(hd) == 1
    raw = raw.replace(hd, (
        "; The COMBINATION block header.  Its first 16 bytes equal the signature the SysEx\n"
        "; reference prints for bulk-dump block COMBINATION 1 (ADR 50 00 00), read from a\n"
        "; real instrument's dump (wsa1/docs/system-exclusive-reference/tbl-signatures.tex).\n"
        "; Its fields are not read as fields: sub_FC2155 (0xFC2155) loads 0xF80000 as the\n"
        "; block base and sub_FC21D0 adds the constant 0x200, and the combination readers\n"
        "; carry 0x300 and 0x2C0 as constants too -- the same values directory entries 1 and\n"
        "; 2 and the stride word below hold.\n").encode("utf-8") + hd)
    # the category-name table
    cat = b"PresetBank_CategoryNames:\n"
    assert raw.count(cat) == 1
    raw = raw.replace(cat, (
        "; Bank names, 16 bytes each, one per bank of eight combinations.  Read by prom_a\n"
        "; sub_F9F910 (0xF9F910) as 0xF80200 + 0x10*bank and by sub_FC21D0 (0xFC21D0) as\n"
        "; 0xF80000 + 0x200 + 0x10*bank, remote-read over the link (see READERS above).\n").encode("utf-8") + cat)
    lines = raw.split(b"\n")
    out, n = [], 0
    for ln in lines:
        out.append(ln)
        if ln.startswith(b"; record ") and b" -- 0xF" in ln:
            i = int(ln.split()[2])
            addr = DATA + i * COMB
            assert ("0x%06X" % addr).encode() in ln, ln
            assert recs[i].encode("latin-1") in ln, (i, recs[i], ln)
            if i < 128:
                hh, ll = divmod(i, 8)
                assert addr == DATA + BANK * hh + COMB * ll
                out.append(("; preset combination: bank %d '%s', memory %d.  Read by prom_a"
                            " sub_F9F984 as 0xF80300 + 0x1600*%d + 0x2C0*%d"
                            % (hh, banks[hh].strip(), ll, hh, ll)).encode("latin-1"))
                out.append(("; and by sub_F98927 as index %d; remote-read to CPU 1 (READERS"
                            " above)." % i).encode("latin-1"))
            else:
                out.append(b"; No bank name and outside sub_F9F984's 16 x 8 (bank 16 would"
                           b" be 0xF80300 + 0x1600*16,")
                out.append(b"; this record's address); sub_F98927 and sub_FC1C77 index"
                           b" linearly and reach it as index 128.")
                out.append(b"; No caller passing 128 has been pinned.  The only record whose"
                           b" eight A blocks all set")
                out.append(b"; LOCAL CONTROL (payload +0x0D bit 5, see WHAT IT IS above).")
            n += 1
    assert n == 129, n
    open(SRC, "wb").write(b"\n".join(out))
    print("applied: banner paragraph, category-name header, %d record headers" % n)


if __name__ == "__main__":
    banks, recs = check()
    print("  16 banks x 8 = 128 combinations + index 128 (%r); bank 0 = %r"
          % (recs[128].strip(), banks[0].strip()))
    print("ALL ASSERTIONS HOLD")
    if "--apply" in sys.argv:
        apply(banks, recs)
