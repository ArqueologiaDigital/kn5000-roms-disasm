#!/usr/bin/env python3
r"""Evidence probes behind the table_data evidence headers (lane tdata, 2026-09-25).

QUESTION THIS ANSWERS
    Every number and structural claim that lane tdata wrote into a
    table_data/*.s header, re-derived from the ROM dumps alone, so a reader can
    check it without trusting the prose.  One check per claim family; each
    prints PASS/FAIL and the figures it measured.  Exit status is non-zero if
    any check fails.

    It reads original_ROMs/* and committed image files -- never the rebuilt
    ROMs -- so it cannot be fooled by a stale build.  One exception: `demo`
    compares against the decompressed demo images, which are build products
    (make rebuild-demo-presets, or any table_data build, regenerates them from
    the committed .mid + .yaml; the build itself byte-checks them against the
    factory streams).

RUN
    python3 scripts/analysis/tdata_evidence_probes.py            # all checks
    python3 scripts/analysis/tdata_evidence_probes.py accessors  # one check
    python3 scripts/analysis/tdata_evidence_probes.py --list

CHECKS (the signal each one reads)
    sec07       ROM 0x82CDA2..+7200 == v10/maincpu/images/BitmapKN5000Logo.bin;
                byte 199 of each of the 36 200-byte rows is 0x20; 0xFF from
                0x82E9C2 to 0x82F000; the v7/v9/v10 program ROMs hold the same
                7,200 bytes at 0xE9367E.
    accessors   0x82F000..0x82F2E8 decodes as 17 routines of one fixed shape
                (ld xwa,(xsp+8) / cp 2 / cp 1 / or / lda base / ld size / ld
                count); every base is a directory target; size*count vs the
                directory extent; each entry address is searched as a 24- and a
                32-bit LE constant in every ROM we hold.
    sec10pad    byte +113 of each 114-byte slot of section 10 is 0x00.
    fdemo       walks the feature-demo file list from (0x880008) in 24-byte steps
                until +0x10 == 0 (FDemo_LinkedListSearch's loop) and applies
                DrawBitmapFile_Impl's header tests ("BM" at v10 0xEAADF2,
                biSize 40, 1 plane, <=8 bpp, <=256 colours, bfOffBits-54 <=
                1024) to each target; size field == bfSize.
    wallpaper   v10 table 0xEAAE62: 10-byte records {pixels, palette, 0}; both
                ROM wallpapers use only pixel values 0xE0-0xEF; their 1 KB
                trailers are 256 x {r,g,b,0} (byte +3 always 0).
    demo        the 19 SLIDE4K blocks behind DemoSongPreset_PointerTable: magic,
                big-endian size == len(decompressed .bin), "ZZZZ" image head,
                and the 16-char field at +0x100 the headers quote.
    helpdb      0x988000/0x988018 six-slot tables (slot 4 == slot 0); every
                live block starts "SLIDE8K\0" 00 90 00; each decompressed
                database is 200 pointers into a string pool at RAM 0x69B20.
    panelmem    80 records x 674 B at 0x99ECA0, each a 34-chunk (tag, length,
                payload) stream ending 0xFF 0xFF.
    sections    all 33 SectionDirectory_Table targets are byte-identical to
                v10/maincpu/images/*.bin bitmaps that the v7/v9/v10 program ROMs
                also carry; entries 0-5, 8-27 tile 0x800088.. with no gap, then 7;
                entry 1 = entry 0 with 0xF8 -> 0x0A; split pictures 13-24 differ
                from 12 only by 0xFF->0xFE / 0x00->0xFC; lists every other 24/32-bit
                constant hit on a target address (expected: coincidences only).
    stylerec    the 96-byte residue after StyleRec_PtrTable_Default (0x987FA0)
                equals ROM 0x98FF98..0x98FFF7, inside HelpDB_French.
"""
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OR = os.path.join(ROOT, "original_ROMs")


def rom(name):
    return open(os.path.join(OR, name), "rb").read()


TD = None
TD_BASE = 0x800000


def td(addr, n):
    return TD[addr - TD_BASE:addr - TD_BASE + n]


def directory():
    return [struct.unpack_from("<I", TD, 4 * i)[0] for i in range(34)]


OTHER_ROMS = {
    "v10": ("kn5000_v10_program.rom", 0xE00000),
    "v9": ("kn5000_v9_program.rom", 0xE00000),
    "v7": ("kn5000_v7_program.rom", 0xE00000),
    "v142": ("kn5000_subprogram_v142.rom", 0x000000),
    "ic19": ("kn5000_custom_data.ic19", 0x000000),
    "hdae": ("hd-ae5000_v2_06i.ic4", 0x000000),
    "tabledata": ("kn5000_table_data.rom", 0x800000),
}


# ------------------------------------------------------------------ checks
def check_sec07():
    ok = True
    logo = open(os.path.join(ROOT, "v10/maincpu/images/BitmapKN5000Logo.bin"), "rb").read()
    pix = td(0x82CDA2, 7200)
    ok &= pix == logo
    pads = {pix[200 * r + 199] for r in range(36)}
    ok &= pads == {0x20}
    tail = set(td(0x82CDA2 + 7200, 0x82F000 - (0x82CDA2 + 7200)))
    ok &= tail == {0xFF}
    prog = {}
    for k in ("v7", "v9", "v10"):
        f, base = OTHER_ROMS[k]
        prog[k] = rom(f)[0xE9367E - base:0xE9367E - base + 7200] == pix
    ok &= all(prog.values())
    print("  logo == BitmapKN5000Logo.bin: %s; row pad bytes %s; fill to 0x82F000 %s;"
          " program-ROM copies at 0xE9367E %s" % (pix == logo, sorted(pads), sorted(tail), prog))
    return ok


def decode_accessors():
    code = td(0x82F000, 0x2E9)
    pos, out = 0, []

    def ld_xhl(p):
        if code[p] == 0x43:
            return struct.unpack_from("<I", code, p + 1)[0], 5
        if code[p] == 0xEB and 0xA8 <= code[p + 1] <= 0xAF:
            return code[p + 1] - 0xA8, 2
        raise ValueError("ld xhl form at 0x%X" % (0x82F000 + p))

    while pos < len(code):
        s = pos
        assert code[pos:pos + 3] == b"\xaf\x08\x20"; pos += 3            # ld xwa,(xsp+8)
        assert code[pos:pos + 6] == b"\xe8\xcf\x02\x00\x00\x00"; pos += 6  # cp xwa,2
        assert code[pos] == 0x66; jc = pos + 2 + code[pos + 1]; pos += 2   # jr z
        assert code[pos:pos + 6] == b"\xe8\xcf\x01\x00\x00\x00"; pos += 6  # cp xwa,1
        assert code[pos] == 0x66; js = pos + 2 + code[pos + 1]; pos += 2
        assert code[pos:pos + 2] == b"\xe8\xe0"; pos += 2                  # or xwa,xwa
        assert code[pos] == 0x66; jb = pos + 2 + code[pos + 1]; pos += 2
        assert code[pos:pos + 3] == b"\xeb\xa8\x0e"; pos += 3              # ld xhl,0 ; ret
        assert pos == jb and code[pos] == 0xF2 and code[pos + 4] == 0x33  # lda xhl,(a24)
        base = int.from_bytes(code[pos + 1:pos + 4], "little"); pos += 5
        assert code[pos] == 0x0E; pos += 1
        assert pos == js
        size, n = ld_xhl(pos); pos += n
        assert code[pos] == 0x0E; pos += 1
        assert pos == jc
        count, n = ld_xhl(pos); pos += n
        assert code[pos] == 0x0E; pos += 1
        out.append((0x82F000 + s, base, size, count))
    assert pos == len(code)
    return out


def check_accessors():
    ok = True
    rts = decode_accessors()
    d = directory()
    targets = sorted(set(d[:33]))
    ext = {t: (targets[i + 1] if i + 1 < len(targets) else 0xA00000) - t
           for i, t in enumerate(targets)}
    print("  %d routines decoded" % len(rts))
    ok &= len(rts) == 17
    for a, base, size, count in rts:
        ent = d.index(base) if base in d else None
        ok &= ent is not None
        note = ""
        if ent is not None and ent not in (6, 7, 28, 29, 30, 31, 32):
            note = "size*count %d vs extent %d" % (size * count, ext[base])
        print("   0x%06X entry %-4s base 0x%06X  %4d x %4d  %s" % (a, ent, base, size, count, note))
    roms = {k: (rom(f), b) for k, (f, b) in OTHER_ROMS.items()}
    hits = []
    for a, *_ in rts:
        for w in (3, 4):
            pat = a.to_bytes(w, "little")
            for k, (blob, b) in roms.items():
                for m in re.finditer(re.escape(pat), blob):
                    hits.append((k, w, "0x%06X" % a, "0x%06X" % (m.start() + b)))
    print("  constant hits (rom, width, entry, where): %s" % (hits or "none"))
    return ok


def check_sec10pad():
    b = 0x80AA48
    v = {td(b + 114 * r + 113, 1)[0] for r in range(25)}
    print("  byte +113 of the 25 slots: %s" % sorted(v))
    return v == {0}


def check_fdemo():
    """Walk the feature-demo file list exactly as FDemo_LinkedListSearch does
    and apply DrawBitmapFile_Impl's header tests to every target."""
    ok = True
    p10 = rom("kn5000_v10_program.rom")
    ok &= p10[0xEAADF2 - 0xE00000:0xEAADF2 - 0xE00000 + 2] == b"BM"
    ok &= p10[0xEAA160 - 0xE00000:0xEAA160 - 0xE00000 + 5] == b".BMP\0"
    meta = td(0x87FFF0, 28)
    f = struct.unpack_from("<4I", meta, 12)
    print("  metadata name %r fields +0x0C..+0x18 = %s" % (meta[:12], [hex(x) for x in f]))
    ok &= meta[:12] == b"hkst_55.ssf\0" and f[0] == 0
    a = struct.unpack("<I", td(0x880008, 4))[0]
    n = 0
    while True:
        name = td(a, 12)
        z, ptr, size = struct.unpack("<3I", td(a + 12, 12))
        if ptr == 0:
            print("  terminator record at 0x%06X" % a)
            break
        h = td(ptr, 54)
        bfsize, off = struct.unpack_from("<I", h, 2)[0], struct.unpack_from("<I", h, 10)[0]
        bisize, w, hh, planes, bpp = struct.unpack_from("<IiiHH", h, 14)
        clr = struct.unpack_from("<I", h, 46)[0]
        good = (h[:2] == b"BM" and bisize == 40 and planes == 1 and bpp <= 8 and clr <= 256
                and off - 54 <= 1024 and bfsize == size and z == 0)
        ok &= good
        print("  0x%06X %-12s -> 0x%06X %dx%d %dbpp size %d bfSize %d %s"
              % (a, name.split(b"\0")[0].decode(), ptr, w, hh, bpp, size, bfsize, "ok" if good else "BAD"))
        a += 24
        n += 1
    ok &= n == 6
    return ok


def check_wallpaper():
    ok = True
    p10 = rom("kn5000_v10_program.rom")
    o = 0xEAAE62 - 0xE00000
    recs = [struct.unpack_from("<IIH", p10, o + 10 * i) for i in range(5)]
    print("  records at 0xEAAE62: %s" % [(hex(a), hex(b), c) for a, b, c in recs])
    ok &= recs[0][:2] == (0x8ED000, 0x8FFC00) and recs[1][:2] == (0x900000, 0x912C00)
    for k, (pix_a, pal_a, _) in enumerate(recs[:2]):
        pix = td(pix_a, 76800)
        vals = sorted(set(pix))
        pal = td(pal_a, 1024)
        nz = [i for i in range(256) if pal[4 * i:4 * i + 4] != b"\0\0\0\0"]
        pad = {pal[4 * i + 3] for i in range(256)}
        print("  wallpaper %d: pixel values 0x%02X-0x%02X (%d distinct); palette non-zero"
              " entries %d (0x%02X..0x%02X), byte +3 values %s"
              % (k, vals[0], vals[-1], len(vals), len(nz), nz[0], nz[-1], sorted(pad)))
        ok &= vals[0] >= 0xE0 and vals[-1] <= 0xEF and pad == {0}
    return ok


def check_demo():
    ok = True
    tab = [struct.unpack("<I", td(0x9C4000 + 4 * i, 4))[0] for i in range(20)]
    ok &= tab[18] == 0x8E0000 and tab[19] == 0
    for n in range(19):
        a = tab[n]
        hdr = td(a, 11)
        size = int.from_bytes(hdr[8:11], "big")
        fn = os.path.join(ROOT, "table_data/includes/demo_presets/demo_preset_%02d.bin" % n)
        if not os.path.exists(fn):
            print("  %s missing -- run `make rebuild-demo-presets` first" % fn)
            return False
        img = open(fn, "rb").read()
        good = hdr[:8] == b"SLIDE4K\0" and size == len(img) and img[:4] == b"ZZZZ"
        ok &= good
        print("  slot %2d 0x%06X size %6d title %-18r %s"
              % (n, a, size, img[0x100:0x110].decode("latin-1"), "ok" if good else "BAD"))
    return ok


def check_helpdb():
    ok = True
    intro = [struct.unpack("<I", td(0x988000 + 4 * i, 4))[0] for i in range(6)]
    dbs = [struct.unpack("<I", td(0x988018 + 4 * i, 4))[0] for i in range(6)]
    ok &= intro[4] == intro[0] and dbs[4] == dbs[0]
    print("  intro table %s" % [hex(x) for x in intro])
    print("  db table    %s" % [hex(x) for x in dbs])
    for l in ("english", "german", "french", "spanish", "indonesian"):
        b = open(os.path.join(ROOT, "table_data/includes/help_databases/help_db_%s.bin" % l), "rb").read()
        p = [struct.unpack_from("<I", b, 4 * i)[0] for i in range(200)]
        good = len(b) == 0x9000 and all(0x69B20 <= v < 0x69800 + 0x9000 and b[v - 0x69800 - 1] == 0
                                        for v in p if v != 0x69B20)
        ok &= good
        print("  %-12s %d B, 200 pointers into the pool at 0x69B20: %s" % (l, len(b), good))
    for a in dbs[:4] + dbs[5:]:
        ok &= td(a, 11) == b"SLIDE8K\0\x00\x90\x00"
    return ok


def check_panelmem():
    ok = True
    names = td(0x99EC00, 160)
    print("  bank names: %s" % [names[16 * i:16 * i + 16].decode() for i in range(10)])
    for i in range(80):
        r = td(0x99ECA0 + 674 * i, 674)
        good = r[:2] == bytes([0x78, 18]) and r[-2:] == b"\xff\xff"
        # walk the chunk stream: (tag, len, payload) until tag 0xff
        p, n = 0, 0
        while r[p] != 0xFF:
            p += 2 + r[p + 1]
            n += 1
        good &= p == 672 and n == 34
        ok &= good
        if not good:
            print("  record %d BAD (end %d, %d chunks)" % (i, p, n))
    print("  80 records x 674 B at 0x99ECA0: each a 34-chunk (tag,len,payload) stream"
          " ending 0xFF 0xFF: %s" % ok)
    return ok


def check_stylerec():
    r = td(0x987FA0, 96)
    dup = td(0x98FF98, 96)
    first = TD.find(r)
    second = TD.find(r, first + 1)
    print("  Default-page residue == ROM 0x98FF98..+96 (HelpDB_French +0x%X): %s;"
          " occurrences at 0x%06X, 0x%06X" % (0x98FF98 - 0x98F0DA, r == dup,
                                             first + TD_BASE, second + TD_BASE))
    return r == dup and 0x98F0DA <= 0x98FF98 < 0x992A0C


SECTION_IMAGES = {
    0: "BitmapAccger16", 1: "BitmapAccita16", 2: "BitmapSomeArrows",
    3: "BitmapDrawbarNumberedSlider_1", 4: "BitmapDrawbarNumberedSlider_2",
    5: "BitmapDrawbarNumberedSlider_3", 6: "BitmapTechnicsLogo", 7: "BitmapKN5000Logo",
    8: "BitmapFadeInPicture", 9: "BitmapFadeInText", 10: "BitmapFadeOutPicture",
    11: "BitmapFadeOutText", 25: "BitmapMIDIConnections_1", 26: "BitmapMIDIConnections_2",
    27: "BitmapMIDIConnections_3", 28: "BitmapBmphk", 29: "BitmapNtedt0k",
    30: "BitmapNtedt0d", 31: "BitmapDredt0k", 32: "BitmapDredt0d",
}
for _i, _k in enumerate(["no_split", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]):
    SECTION_IMAGES[12 + _i] = "BitmapSplitPoint_" + _k


def check_sections():
    """Every directory entry == a v10/maincpu/images bitmap, which the program
    ROMs also carry; the in-half entries tile 0x800088..0x82E9C1; recolouring
    facts quoted in preset_banks.s; no 24/32-bit constant reference to any
    target outside the directory and the accessor routines."""
    ok = True
    d = directory()
    progs = {k: rom(OTHER_ROMS[k][0]) for k in ("v7", "v9", "v10")}
    img = {}
    for n in range(33):
        f = os.path.join(ROOT, "v10/maincpu/images/%s.bin" % SECTION_IMAGES[n])
        b = open(f, "rb").read()
        img[n] = b
        same = td(d[n], len(b)) == b
        where = {k: progs[k].find(b) for k in progs}
        good = same and all(v >= 0 for v in where.values())
        ok &= good
        print("  entry %2d 0x%06X %-30s %6d B  == file %s  program copies %s"
              % (n, d[n], SECTION_IMAGES[n], len(b), same,
                 {k: "0x%06X" % (v + 0xE00000) for k, v in where.items()}))
    a = 0x800088
    for n in [0, 1, 2, 3, 4, 5, 8, 9, 10, 11] + list(range(12, 28)) + [7]:
        ok &= d[n] == a
        a += len(img[n])
    print("  in-half entries tile 0x800088..0x%06X with no gap: %s" % (a - 1, a == 0x82E9C2))
    ok &= a == 0x82E9C2
    g, i = img[0], img[1]
    diff = [(x, y) for x, y in zip(g, i) if x != y]
    rec = set(diff) == {(0xF8, 0x0A)}
    print("  entry 1 vs 0: %d differing pixels, all 0xF8 -> 0x0A: %s (entry 0 has %d 0xF8 pixels)"
          % (len(diff), rec, g.count(0xF8)))
    ok &= rec
    base = img[12]
    kinds = set()
    for n in range(13, 25):
        kinds |= {(x, y) for x, y in zip(base, img[n]) if x != y}
    print("  split-point pictures 13-24 differ from 12 only as %s" % sorted(kinds))
    ok &= kinds <= {(0xFF, 0xFE), (0x00, 0xFC)}
    roms = {k: (rom(f), b) for k, (f, b) in OTHER_ROMS.items()}
    hits = []
    for n in range(33):
        for w in (3, 4):
            pat = d[n].to_bytes(w, "little")
            for k, (blob, b) in roms.items():
                for m in re.finditer(re.escape(pat), blob):
                    loc = m.start() + b
                    if k == "tabledata" and (loc < 0x800088 or 0x82F000 <= loc < 0x82F2E9):
                        continue          # the directory itself / the accessor routines
                    hits.append("%s:w%d:0x%06X@0x%06X" % (k, w, d[n], loc))
    print("  other constant hits: %s" % (hits or "none"))
    return ok


CHECKS = {"sec07": check_sec07, "accessors": check_accessors, "sec10pad": check_sec10pad,
          "fdemo": check_fdemo, "wallpaper": check_wallpaper, "demo": check_demo,
          "helpdb": check_helpdb, "panelmem": check_panelmem,
          "stylerec": check_stylerec, "sections": check_sections}


def main():
    global TD
    args = sys.argv[1:]
    if "--list" in args:
        print("\n".join(CHECKS))
        return 0
    TD = rom("kn5000_table_data.rom")
    names = args or list(CHECKS)
    bad = 0
    for n in names:
        print("[%s]" % n)
        r = CHECKS[n]()
        print("  -> %s" % ("PASS" if r else "FAIL"))
        bad += not r
    print("ALL PASS" if not bad else "%d FAILED" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
