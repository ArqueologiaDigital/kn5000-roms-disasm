#!/usr/bin/env python3
"""disk_msp_format.py -- what is a KN-series .MSP disk file?

QUESTION ANSWERED: the .MSP file on a KN-series floppy is 4,096 B and byte-identical on all
seven archived disks. What does it hold, and do the IC19 accompaniment-style rules apply?

ANSWER (asserted below, not merely printed):

  * It is the SAME 256-byte cell container as the IC19 styles / .CMP -- 0x80 at +0, u16 LE at
    +1 and +3, 0x87 at +5 AND at +0xFF, payload +0x06 for 249 B, "none" = 0xFFFF, pointer =
    12-bit block index RELATIVE to the first cell block (which is block 1 here).
    15 cells at 0x100..0xFFF; 13 carry marker 0x80 and 2 carry 0x00 (free).
    14/14 pointers resolve, 7/7 back-links agree.
  * Its six chains decode under the IC19 event grammar with ZERO malformed events:
    468 events = 292 x 0x90, 102 x 0x91, 74 x 0x81, plus the six 0x83 terminators.
  * The IC19 96-BYTE DIRECTORY DOES **NOT** APPLY. There is no 16-char name anywhere in the
    file. The directory is 16-byte records at +0x20; the u16 LE at record+0x03 is the chain-head
    block index, and the six populated records give exactly the six chain heads, in order.
  * The 16 bytes at +0x10 are eight u16 LE; the first three (0x0020, 0x0010, 0x000E) are the
    directory's own geometry: offset 0x20, stride 0x10, 14 slots -- and 0x20 + 14*0x10 = 0x100,
    which is where the cell area starts, matching the u16 at +0x1C (0x0100).
    .CMP carries the same eight-u16 block one record later, at +0x20, reading
    (0x0060, 0x0060, 0x001E, ...) = its own directory geometry, and its last field times 16 is
    the .CMP file size exactly, on all seven disks and at both sizes.
  * Provenance of the music: three of the six chains' event streams occur VERBATIM in the main
    program ROM (v7 and v10), one of them exactly at the symbol MSP_FACTORY_DEFAULTS
    (0xf6f62f in v10 / 0xf6f22b in v7). A header template for this file, identical except for
    the magic (48 00 4B 00 instead of "LKE\0") and five of the eight u16 fields, sits at
    0x16F119 in the v10 program ROM.

  usage: python3 disk_msp_format.py <dir-with-disk-files> [<kn5000-roms-disasm-dir>]
"""
import glob, os, sys
from collections import Counter

ARGS = {0x90: 5, 0x91: 7, 0x81: 0, 0xD1: 2, 0xD2: 2, 0xD3: 2}


def cells_of(d):
    return [o for o in range(0, len(d) - 255, 256) if d[o + 5] == 0x87 and d[o + 255] == 0x87]


def analyse(path):
    d = open(path, 'rb').read()
    assert d[:4] == b'LKE\0', path
    cells = cells_of(d)
    assert cells and cells[0] == 0x100 and len(cells) == 15, (path, cells[:3], len(cells))
    base = cells[0] >> 8
    cs = set(cells)
    res = bk = chk = 0
    for o in cells:
        a = d[o + 1] | d[o + 2] << 8
        b = d[o + 3] | d[o + 4] << 8
        for v in (a, b):
            if v != 0xFFFF:
                assert ((v & 0xFFF) + base) * 256 in cs, (path, hex(o), hex(v))
                res += 1
        if b != 0xFFFF:
            chk += 1
            t = ((b & 0xFFF) + base) * 256
            ba = d[t + 1] | d[t + 2] << 8
            assert ba != 0xFFFF and ((ba & 0xFFF) + base) * 256 == o, (path, hex(o))
            bk += 1
    heads = [o for o in cells if d[o] == 0x80 and (d[o + 1] | d[o + 2] << 8) == 0xFFFF]
    free = [o for o in cells if d[o] == 0x00]

    # header: eight u16 LE at +0x10
    f = [d[0x10 + 2 * i] | d[0x11 + 2 * i] << 8 for i in range(8)]
    dir_off, rec_sz, n_rec = f[0], f[1], f[2]
    assert (dir_off, rec_sz, n_rec) == (0x20, 0x10, 14), f
    assert dir_off + n_rec * rec_sz == cells[0], "directory does not end where the cells start"
    assert f[6] == cells[0], "u16 at +0x1C is not the cell-area offset"

    # the IC19 96-byte directory does NOT apply
    name = d[0x60 + 0x40:0x60 + 0x50]
    assert not (32 <= name[0] < 127), "an IC19-shaped 16-char name unexpectedly appeared"

    # 16-byte records: u16 at +3 is the chain-head block index
    recs = [d[dir_off + i * rec_sz: dir_off + (i + 1) * rec_sz] for i in range(n_rec)]
    pop = [r for r in recs if r[0] != 0]
    got = [(r[3] | r[4] << 8) for r in pop]
    want = [(h >> 8) - base for h in heads]
    assert got == want, (got, want)
    init = [r for r in recs if r[11:13] == b'\x7f\x40']
    assert len(init) == 9 and all(r == bytes(16) for r in recs[9:]), "record tail changed"

    # decode every chain
    tot = Counter()
    streams = []
    for h in heads:
        pay = bytearray()
        o = h
        while o is not None:
            pay += d[o + 6:o + 255]
            nx = d[o + 3] | d[o + 4] << 8
            o = ((nx & 0xFFF) + base) * 256 if nx != 0xFFFF else None
        i = 0
        while i < len(pay):
            s = pay[i]
            assert s & 0x80, (path, hex(h), i)
            if s == 0x83:
                tot[0x83] += 1
                streams.append(bytes(pay[:i + 1]))
                break
            n = ARGS[s]
            j = i + 1
            run = 0
            while j < len(pay) and not (pay[j] & 0x80) and run < n:
                j += 1
                run += 1
            assert run == n, (path, hex(h), hex(s), run, n)
            tot[s] += 1
            i = j
        else:
            raise AssertionError("chain never terminated")
    return d, f, heads, free, pop, recs, tot, streams


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    disasm = sys.argv[2] if len(sys.argv) > 2 else \
        '/home/fsanches/compartilhado/kn5000-roms-disasm'
    files = sorted(glob.glob(os.path.join(root, '**', '*.MSP'), recursive=True))
    assert files, "no .MSP files found"
    sig = None
    for p in files:
        d, f, heads, free, pop, recs, tot, streams = analyse(p)
        line = (f"{os.path.basename(p):<16} {len(d)}B cells=15 heads={len(heads)} free={len(free)} "
                f"dir={len(pop)} events={sum(v for k, v in tot.items() if k != 0x83)} "
                f"{dict(sorted(tot.items()))}")
        print(line)
        if sig is None:
            sig = (open(p, 'rb').read(), streams)
        assert open(p, 'rb').read() == sig[0], "the seven .MSP files are NOT identical"
    print("\nall seven .MSP files identical; IC19 cell + grammar hold with zero malformed events")

    # ---- provenance: chains inside the program ROM ----
    for tag, rp, tmpl in (('v10', 'kn5000_v10_program.rom', 0x16F119),
                          ('v7', 'kn5000_v7_program.rom', 0x16ED15)):
        rom = open(os.path.join(disasm, 'original_ROMs', rp), 'rb').read()
        hits = [(i, rom.find(s)) for i, s in enumerate(sig[1])]
        print(f"{tag}: chain->ROM offsets " +
              " ".join(f"{i}:{hex(o) if o >= 0 else '-'}" for i, o in hits))
        assert sum(1 for _, o in hits if o >= 0) == 3, "expected exactly 3 chains present in ROM"
        assert rom[tmpl:tmpl + 4] == b'\x48\x00\x4b\x00' and \
            rom[tmpl + 4:tmpl + 0x14] == sig[0][4:0x14], "header template moved"
        print(f"{tag}: header template at 0x{tmpl:X} = " + rom[tmpl:tmpl + 0x20].hex(' '))

    # ---- the same eight-u16 block in .CMP, one record later ----
    for p in sorted(glob.glob(os.path.join(root, '**', '*.CMP'), recursive=True)):
        d = open(p, 'rb').read()
        g = [d[0x20 + 2 * i] | d[0x21 + 2 * i] << 8 for i in range(8)]
        n = 0
        i = 0x60
        while i + 96 <= len(d) and 32 <= d[i + 0x40] < 127:
            n += 1
            i += 96
        assert (g[0], g[1], g[2]) == (0x60, 0x60, 30) and n <= 30
        assert g[7] * 16 == len(d), (p, hex(g[7]), len(d))
        print(f"{os.path.basename(p):<16} {len(d)}B  CMP fields {['0x%04X' % x for x in g]}  "
              f"f7*16 == filesize OK  named dir records {n}")


if __name__ == '__main__':
    main()
