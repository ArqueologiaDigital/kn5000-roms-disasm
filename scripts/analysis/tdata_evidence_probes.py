#!/usr/bin/env python3
r"""Evidence probes behind the table_data evidence headers (lane tdata, 2026-09-25).

QUESTION THIS ANSWERS
    Every number and structural claim that lane tdata wrote into a
    table_data/*.s header, re-derived from the ROM dumps alone, so a reader can
    check it without trusting the prose.  One check per claim family; each
    prints PASS/FAIL and the figures it measured.  Exit status is non-zero if
    any check fails.

    It reads only original_ROMs/* and committed image files -- never the
    rebuilt ROMs -- so it cannot be fooled by a stale build.

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


CHECKS = {"sec07": check_sec07, "accessors": check_accessors, "sec10pad": check_sec10pad}


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
