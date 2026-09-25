#!/usr/bin/env python3
r"""What does each of prom_d's twelve 1024-entry index maps SELECT?

QUESTION THIS ANSWERS
    wsa1/prom_d/tone_database_aux.s carried, on all twelve 2,048-byte maps at
    directory slots +0x0C +0x10 +0x14 +0x24 +0x28 +0x2C +0x44 +0x48 +0x4C
    +0x58 +0x5C +0x60, the line "What the index SELECTS is not established",
    and on eight of them "Readers: NONE IN THE CENSUS".  Both are superseded:
    every map has a prom_c reader, and the index has one meaning for all of
    them.  This script proves it from the ROM bytes and (--apply) writes it
    into the twelve banners.

    THE INDEX.  A wave is named by a selector pair (sel_program,
    sel_bank_family): bytes +14/+15 of a wave-catalogue row, and bytes
    +0x02/+0x03 of a tone record's element block.  Every reader forms
        i = (sel_bank_family & 0x0F) * 128 + (sel_program & 0x7F)
    (`sll 0x07` then `+ program`, then `mul ...,2` for the LE16 entry) and
    picks the map by sel_bank_family bits 7:6.  8 banks x 128 = 1024.

    WHAT IT RETURNS, by map family:
      wave-select  +0x0C/+0x10/+0x14 -> a record number in the 43-byte arrays
                   +0x18/+0x1C/+0x20 (ToneDB_ResolveWaveSelectRecord, 0xFB82C3)
      envelope     +0x24/+0x28/+0x2C -> a descriptor number in the 14-byte
                   arrays +0x30/+0x34/+0x38 (ToneDB_ResolveEnvDescriptor, 0xFB45C0)
      name         +0x44/+0x48/+0x4C/+0x58/+0x5C/+0x60 -> a ROW of a 16-byte
                   wave catalogue (ToneQuery_ReplySourceName1/2_ViaIndexMap,
                   ToneDB_PercSourceIndexMapB_Lookup, ...)

TESTS, each with a control that can fail
    T1  every map's maximum is below the entry count of what it indexes.
    T2  INVERSE: for every row r of a catalogue, looking up its own bytes
        +14/+15 in the family's name map returns r.  307/307 (+0x50 via
        +0x44/+0x48), 314/314 (+0x64 via +0x58/+0x5C), 208/208 (+0x8C via
        +0x4C), 161/161 (+0x94 via +0x60).  Control: the same rows through
        any OTHER map.
    T3  DEFAULTS: a melodic element's selector, through +0x0C / +0x10, lands
        on an array record equal to that element's OWN wave-select record in
        all 43 bytes but +0x0B (the tail preset prom_c rewrites) for 213 of
        451 elements.  Controls: families swapped 0, record n+1 0, n-1 0.
    T4  every instruction byte cited in the banners, asserted.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_d_index_maps.py           # tests
    python3 notes/lanes/promcd-2026-09-25/prom_d_index_maps.py --apply   # + edit
    PASS = "ALL CHECKS HOLD".
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
D = open(os.path.join(W, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(W, "prom_d", "tone_database_aux.s")
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
S = u32


def cbytes(a, n):
    return C[a - 0xF80000:a - 0xF80000 + n]


def mp(slot):
    return [u16(S(slot) + 2 * i) for i in range(1024)]


def rows(slot, n):
    b = S(slot)
    return [D[b + 16 * i:b + 16 * i + 16] for i in range(n)]


def key(p, f):
    return (f & 0x0F) * 128 + (p & 0x7F)


# (slot, label, family text, target text, target count, reader text)
MAPS = [
    (0x0C, "ToneDB_ToneIndexMapA", "0x00 and 0xC0",
     "a record number in ToneDB_MixerDefaultTable (+0x18, 322 x 43)", 322,
     "ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3): 0xFB8369 `ld XWA,(XBC+0x0c)`,\n"
     "; then +0x18 at 0xFB836F and the stride word +0xEA (43) at 0xFB837A"),
    (0x10, "ToneDB_ToneIndexMapB", "0x80",
     "a record number in the same 43-byte array, through +0x1C (the +0x18 alias)", 322,
     "ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3): 0xFB83C6 `ld XWA,(XBC+0x10)`,\n"
     "; then +0x1C at 0xFB83CC and the stride word +0xEA (43) at 0xFB83D7"),
    (0x14, "ToneDB_PercSourceIndexMapA", "0x40",
     "a record number in ToneDB_PercMixerDefaultTable (+0x20, 208 x 43)", 208,
     "ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3): 0xFB8398 `ld XWA,(XBC+0x14)`,\n"
     "; then +0x20 at 0xFB839E and the stride word +0xF0 (43) at 0xFB83A9"),
    (0x24, "ToneDB_ToneIndexMapC", "0x00 and 0xC0",
     "a descriptor number in ToneDB_EnvDescTable (+0x30, 318 x 14)", 318,
     "ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0): 0xFB4668 `ld XWA,(XBC+0x24)`,\n"
     "; then +0x30 at 0xFB466E and the stride word +0xEC (14) at 0xFB4679"),
    (0x28, "ToneDB_ToneIndexMapD", "0x80",
     "a descriptor number in the same 14-byte array, through +0x34 (the +0x30 alias)", 318,
     "ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0): 0xFB46B3 `ld XWA,(XBC+0x28)`,\n"
     "; then +0x34 at 0xFB46B9 and the stride word +0xEC (14) at 0xFB46C4"),
    (0x2C, "ToneDB_DrumToneIndexMap", "0x40",
     "a descriptor number in ToneDB_EnvDescTable_Perc (+0x38, 161 x 14)", 161,
     "ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0): 0xFB468C `ld XWA,(XBC+0x2c)`,\n"
     "; then +0x38 at 0xFB4692 and the stride word +0xF2 (14) at 0xFB469D"),
    (0x44, "ToneDB_SourceIndexMapA", "0x00 and 0xC0",
     "a ROW of ToneDB_SourceNameList1 (+0x50, 307 x 16)", 307,
     "ToneQuery_ReplySourceName1_ViaIndexMap (prom_c 0xFC035E): 0xFC03FD and\n"
     "; 0xFC0450 `ld XWA,(XBC+0x44)`, the list +0x50 at 0xFC049C, row stride\n"
     "; `ld BC,0x0010` at 0xFC04C1; ToneQuery_ReplySourceName1_ByRow (0xFC067A)\n"
     "; takes entry 127 (0xFC06DE, `add XWA,0x000000fe` 0xFC06E4) as its fallback"),
    (0x48, "ToneDB_SourceIndexMapB", "0x80",
     "a ROW of ToneDB_SourceNameList1 (+0x50, 307 x 16)", 307,
     "ToneQuery_ReplySourceName1_ViaIndexMap (prom_c 0xFC035E): 0xFC0435\n"
     "; `ld XWA,(XBC+0x48)`, the list +0x50 at 0xFC049C"),
    (0x4C, "ToneDB_PercSourceIndexMapB", "0x40",
     "a ROW of ToneDB_PercSourceNameList1 (+0x8C, 208 x 16), or 0xFFFF", 208,
     "ToneDB_PercSourceIndexMapB_Lookup (prom_c 0xFC1555), decoded above; also\n"
     "; ToneQuery_ReplySourceName1_ViaIndexMap (0xFC035E) at 0xFC0419 -- which\n"
     "; names the row from +0x50, not +0x8C, on this arm too (0xFC049C is shared)"),
    (0x58, "ToneDB_SourceIndexMapC", "0x00 and 0xC0",
     "a ROW of ToneDB_SourceNameList2 (+0x64, 314 x 16)", 314,
     "ToneQuery_ReplySourceName2_ViaIndexMap (prom_c 0xFC04EC): 0xFC058B and\n"
     "; 0xFC05DE `ld XWA,(XBC+0x58)`, the list +0x64 at 0xFC062A"),
    (0x5C, "ToneDB_SourceIndexMapD", "0x80",
     "a ROW of ToneDB_SourceNameList2 (+0x64, 314 x 16)", 314,
     "ToneQuery_ReplySourceName2_ViaIndexMap (prom_c 0xFC04EC): 0xFC05C3\n"
     "; `ld XWA,(XBC+0x5c)`, the list +0x64 at 0xFC062A"),
    (0x60, "ToneDB_PercSourceIndexMapC", "0x40",
     "a ROW of ToneDB_PercSourceNameList2 (+0x94, 161 x 16)", 161,
     "ToneQuery_ReplyPercSourceName2AndIndex (prom_c 0xFC1845): 0xFC1904 and\n"
     "; 0xFC1977 `ld XWA,(XBC+0x60)`, the list +0x94 at 0xFC1924/0xFC199C;\n"
     "; ToneQuery_ReplySourceName2_ViaIndexMap (0xFC04EC) at 0xFC05A7"),
]

# ------------------------------------------------------------------ T4 bytes
CODE = [
    # (address, bytes, what) -- a9 dd 2r = ld Xr,(XBC+dd); d3 e5 dd 00 20 = ld WA,(XBC+dd16)
    (0xFB8369, "a9 0c 20", "+0x0C"), (0xFB836F, "a9 18 25", "+0x18"), (0xFB837A, "d3 e5 ea 00 20", "+0xEA"),
    (0xFB8398, "a9 14 20", "+0x14"), (0xFB839E, "a9 20 25", "+0x20"), (0xFB83A9, "d3 e5 f0 00 20", "+0xF0"),
    (0xFB83C6, "a9 10 20", "+0x10"), (0xFB83CC, "a9 1c 25", "+0x1C"), (0xFB83D7, "d3 e5 ea 00 20", "+0xEA"),
    (0xFB840F, "d9 ee 07", "sll 0x07,BC"), (0xFB8415, "d9 08 02 00", "mul BC,0x0002"),
    (0xFB4668, "a9 24 20", "+0x24"), (0xFB466E, "a9 30 25", "+0x30"), (0xFB4679, "d3 e5 ec 00 20", "+0xEC"),
    (0xFB468C, "a9 2c 20", "+0x2C"), (0xFB4692, "a9 38 25", "+0x38"), (0xFB469D, "d3 e5 f2 00 20", "+0xF2"),
    (0xFB46B3, "a9 28 20", "+0x28"), (0xFB46B9, "a9 34 25", "+0x34"), (0xFB46C4, "d3 e5 ec 00 20", "+0xEC"),
    (0xFB46DA, "d9 ee 07", "sll 0x07,BC"), (0xFB46DF, "d9 08 02 00", "mul BC,0x0002"),
    (0xFC03FD, "a9 44 20", "+0x44"), (0xFC0450, "a9 44 20", "+0x44"), (0xFC0419, "a9 4c 20", "+0x4C"),
    (0xFC0435, "a9 48 20", "+0x48"), (0xFC0484, "d9 ee 07", "sll 0x07,BC"), (0xFC048A, "d9 08 02 00", "mul BC,2"),
    (0xFC049C, "a9 50 25", "+0x50"), (0xFC04C1, "31 10 00", "ld BC,0x0010"),
    (0xFC06DE, "a9 44 20", "+0x44"), (0xFC06E4, "e8 c8 fe 00 00 00", "add XWA,0xfe"),
    (0xFC058B, "a9 58 20", "+0x58"), (0xFC05DE, "a9 58 20", "+0x58"), (0xFC05A7, "a9 60 20", "+0x60"),
    (0xFC05C3, "a9 5c 20", "+0x5C"), (0xFC062A, "a9 64 25", "+0x64"),
    (0xFC1589, "d9 cf ff ff", "cp BC,0xffff"), (0xFC163F, "31 10 00", "ld BC,0x0010"),
    (0xFC1904, "a9 60 20", "+0x60"), (0xFC1977, "a9 60 20", "+0x60"),
    (0xFC1924, "e3 e5 94 00 25", "+0x94"), (0xFC199C, "e3 e5 94 00 20", "+0x94"),
]


def check():
    bad = 0
    for a, enc, what in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        if cbytes(a, len(want)) != want:
            print("  BAD  prom_c 0x%06X  %s  want %s (%s)" % (a, cbytes(a, len(want)).hex(" "), enc, what))
            bad += 1
    print("  T4 %d/%d cited instruction encodings hold" % (len(CODE) - bad, len(CODE)))
    assert not bad
    stats = {}
    for slot, label, fam, tgt, cnt, _ in MAPS:
        m = mp(slot)
        vals = [v for v in m if v != 0xFFFF]
        stats[slot] = (max(vals), len(set(m)), m.count(0xFFFF))
        assert max(vals) < cnt, (label, max(vals), cnt)
    print("  T1 every map's maximum is below its target's entry count")
    # T2 inverse
    cats = {0x50: (307, {0x00: 0x44, 0xC0: 0x44, 0x80: 0x48}),
            0x64: (314, {0x00: 0x58, 0xC0: 0x58, 0x80: 0x5C}),
            0x8C: (208, {0x40: 0x4C}),
            0x94: (161, {0x40: 0x60})}
    inv = {}
    for cs, (n, fam) in cats.items():
        L = rows(cs, n)
        hits = {}
        for i, r in enumerate(L):
            ms = fam[r[15] & 0xC0]
            hits.setdefault(ms, [0, 0])
            hits[ms][1] += 1
            if mp(ms)[key(r[14], r[15])] == i:
                hits[ms][0] += 1
        # control: every row through every OTHER name map
        best = 0
        for other in (0x44, 0x48, 0x4C, 0x58, 0x5C, 0x60):
            if other in fam.values():
                continue
            best = max(best, sum(1 for i, r in enumerate(L) if mp(other)[key(r[14], r[15])] == i))
        for ms, (h, t) in hits.items():
            assert h == t, (hex(cs), hex(ms), h, t)
            inv[ms] = (cs, h, t, best, n)
        print("  T2 +0x%02X (%d rows) inverted exactly by %s; best other map %d/%d"
              % (cs, n, "/".join("+0x%02X" % m for m in sorted(set(fam.values()))), best, n))
        assert best < n // 2
    # T3 defaults
    PTR = [u32(0xB80 + 4 * i) for i in range(274)]

    def t3(fmap, shift=0):
        hit = tot = 0
        for p in PTR:
            if D[p + 0x10] in (0x80, 0x71):
                continue
            N = sum(1 for k in range(4) if (D[p + 0x11] >> (2 * k)) & 3)
            for k in range(N):
                e = p + 0xD9 + 81 * k
                w = p + 0xD9 + 81 * N + 43 * k
                n = mp(fmap(D[e + 3]))[key(D[e + 2], D[e + 3])] + shift
                a = S(0x18) + 43 * n
                tot += 1
                hit += all(D[a + i] == D[w + i] for i in range(43) if i != 11)
        return hit, tot
    real = t3(lambda f: 0x10 if f & 0xC0 == 0x80 else 0x0C)
    ctrl = [t3(lambda f: 0x0C if f & 0xC0 == 0x80 else 0x10),
            t3(lambda f: 0x10 if f & 0xC0 == 0x80 else 0x0C, 1),
            t3(lambda f: 0x10 if f & 0xC0 == 0x80 else 0x0C, -1)]
    print("  T3 element selector -> own wave-select record (bar +0x0B): %d/%d; controls %s"
          % (real[0], real[1], [c[0] for c in ctrl]))
    assert real[0] > 100 and all(c[0] == 0 for c in ctrl)
    return stats, inv, real


OLD_SELECTS = ("; \u26a0 What the index SELECTS is not established here; the value ranges are\n"
               "; recorded because they pin which catalogue or record array each map can\n"
               "; possibly address (see notes/FINDINGS-prom-d-tone-database.md).\n")
NEW_SELECTS = ("; \u2605 What the index SELECTS: see WHAT THE INDEX SELECTS at the end of this\n"
               "; banner (corrected 2026-09-25, lane promcd; this line used to leave it open).\n")
OLD_NONE = ("; \u26a0 Readers: NONE IN THE CENSUS.  notes/prom_d_documentation_round3.py\n"
            "; walks every load of prom_d's base (0x00F00000, RAM 0x00D7ED /\n"
            "; 0x00D7F1) in prom_c and every directory slot read through it -- 99\n"
            "; reads over 33 slots -- and directory slot +0x%02X is not among them.\n"
            "; The census is a LOWER BOUND: by its own rule it does not follow a\n"
            "; base parked in a frame slot.\n")
NEW_NONE = ("; Round 3's base-load census (notes/prom_d_documentation_round3.py, 99\n"
            "; reads over 33 slots) did not list directory slot +0x%02X: it does not\n"
            "; follow a base parked in a frame slot, and the readers below park it\n"
            "; there first.  (Corrected 2026-09-25, lane promcd: this paragraph used\n"
            "; to present that census as the absence of a reader.)\n")
OLD_TRANSPLANT = ("; So this region's NAME is still the KN5000 transplant and NOTHING in\n"
                  "; the WSA1 firmware confirms it.\n")
OLD_CHAIN = ("; The chain this reader belongs to has NOT been decoded end to end.\n"
             "; For the one that has -- slot +0x4C -- see its banner: the map value\n"
             "; turns out to be a ROW NUMBER in a catalogue.  Whether that reading\n"
             "; carries over to this map is NOT asserted here.\n")
NEW_CHAIN = ("; The chain is now decoded end to end and the +0x4C reading DOES carry\n"
             "; over: see WHAT THE INDEX SELECTS below (corrected 2026-09-25, lane\n"
             "; promcd).\n")
OLD_384 = "; and recorded as 'what the extra 384 entries are is NOT established',\n"
NEW_384 = "; and once recorded as 384 extra entries of this map,\n"


def paragraph(slot, label, fam, tgt, cnt, reader, stats, inv, t3):
    mx, dist, ff = stats[slot]
    out = [
        "; \u2605 WHAT THE INDEX SELECTS (lane promcd, 2026-09-25).",
        "; The index is a WAVE SELECTOR PAIR (sel_program, sel_bank_family) --",
        "; bytes +14/+15 of a wave-catalogue row, +0x02/+0x03 of a tone record's",
        "; element block -- as i = (sel_bank_family & 0x0F)*128 + (sel_program &",
        "; 0x7F): 8 banks x 128 = these 1024 LE16 entries.  This map is the one",
        "; the readers take when sel_bank_family bits 7:6 are %s." % fam,
        "; Value: %s." % tgt,
        "; Reader: " + reader + ".",
        "; Measured over all 1024 entries: max %d < %d, %d distinct%s."
        % (mx, cnt, dist, (", %d x 0xFFFF (the NO-ENTRY value, 16 in each bank)" % ff) if ff else ""),
    ]
    if slot in inv:
        cs, h, t, best, n = inv[slot]
        out += ["; \u2605 THE MAP IS THE CATALOGUE'S INVERSE: for each of the %d rows of" % t,
                "; +0x%02X whose byte +15 carries this family, looking up that row's own" % cs,
                "; +14/+15 here returns the row itself -- %d of %d.  Control: all %d rows" % (h, t, n),
                "; through each of the other name maps return themselves at most %d times." % best]
    if slot in (0x0C, 0x10):
        out += ["; \u2605 DEFAULTS: a melodic element's selector, through this map and its",
                "; sibling, lands on an array record equal to that element's OWN",
                "; wave-select record in all bytes but +0x0B (the tail preset prom_c",
                "; rewrites) for %d of %d elements; record n+1, n-1 or the swapped" % t3,
                "; family map score 0."]
    out += ["; Proof: python3 notes/lanes/promcd-2026-09-25/prom_d_index_maps.py"]
    return "\n".join(out) + "\n"


def apply(stats, inv, t3):
    src = open(SRC, "rb").read().decode("utf-8")
    if "WHAT THE INDEX SELECTS (lane promcd" in src:
        sys.exit("already applied")
    assert src.count(OLD_384) == 1
    src = src.replace(OLD_384, NEW_384)
    for slot, label, fam, tgt, cnt, reader in MAPS:
        head = "; %s -- directory slot +0x%02X\n" % (label, slot)
        a = src.index(head)
        z = src.index("\n%s:\n" % label, a)
        ban = src[a:z + 1]
        assert ban.count(OLD_SELECTS) == 1, label
        ban = ban.replace(OLD_SELECTS, NEW_SELECTS)
        on = OLD_NONE % slot
        if on in ban:
            ban = ban.replace(on, NEW_NONE % slot)
        ban = ban.replace(OLD_TRANSPLANT, "")
        ban = ban.replace(OLD_CHAIN, NEW_CHAIN)
        rule = "; " + "=" * 74 + "\n"
        assert ban.endswith(rule), label
        ban = ban[:-len(rule)] + ";\n" + paragraph(slot, label, fam, tgt, cnt, reader, stats, inv, t3) + rule
        src = src[:a] + ban + src[z + 1:]
    open(SRC, "wb").write(src.encode("utf-8"))
    print("applied: 12 banners")


if __name__ == "__main__":
    stats, inv, t3 = check()
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply(stats, inv, t3)
