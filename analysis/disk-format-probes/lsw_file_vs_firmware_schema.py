#!/usr/bin/env python3
"""Diff a .LSW file's TLV tag stream against the KN5000 firmware's own panel schema.

QUESTION ANSWERED
-----------------
docs/kn-disk-file-formats.md proves the seven floppy .LSW files (22,528 B) were NOT
written by KN5000 firmware (which writes 3,648 B) and leaves the record meanings open.
This script asks: are they nevertheless THE SAME FORMAT?

The KN5000's live panel work area is itself a tag/length/value stream whose schema is a
ROM table -- see lsw_panel_schema_from_rom.py.  Its two blocks are:

    block 0  base 0x00F9A0  45 records + FF FF   (tags 78 00..16 19 44 45 46 47 43 48
                                                  90 60 61 63 64 65 66 68 70 72 92 71 99 80)
    block 1  base 0x00FD60  29 records + FF FF   (tags 17 18 98 91 93 C0..D4 D7 49 9A)

Compare that with the tag sequence of each block of a .LSW file.  Reported per block:
  - the file's tag sequence
  - the longest-common-subsequence alignment against the firmware sequence
  - which tags the file adds / drops, and which record LENGTHS changed

PASS = every block of the file aligns against one of the two firmware blocks with no
tag reordering (i.e. the file's tags are a subsequence-compatible edit of the firmware's,
never a permutation).  Exits non-zero if a block cannot be aligned that way.

    python3 analysis/disk-format-probes/lsw_file_vs_firmware_schema.py <file.LSW> [...]

Reference corpus: ~/compartilhado/KN7000/floppy-archive/*.zip -> */*.LSW (7 files).
"""
import os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(HERE, '..', '..', 'original_ROMs', 'kn5000_v7_program.rom')
LOAD = 0xE00000
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))
FILE_TLV_START = 0x20


def firmware_blocks():
    rom = open(ROM_PATH, 'rb').read()
    out = []
    for addr, count, _base in TABLES:
        blk = []
        for i in range(count):
            o = addr - LOAD + 10 * i
            tag, ln = rom[o + 8], rom[o + 9]
            if tag == 0xFF:
                break
            blk.append((tag, ln))
        out.append(blk)
    return out


def file_blocks(data, start=FILE_TLV_START, limit=26):
    # 26 blocks only: 0x0020..0x4E80 is TLV, the 0x4E80..0x5800 tail is not (see the doc).
    p, blocks, cur = start, [], []
    while p + 1 < len(data) and len(blocks) < limit:
        tag, ln = data[p], data[p + 1]
        if tag == 0xFF and ln == 0xFF:
            blocks.append((cur, p + 2))
            cur = []
            p += 2
            continue
        cur.append((tag, ln, data[p + 2:p + 2 + ln]))
        p += 2 + ln
    return blocks


def lcs(a, b):
    n, m = len(a), len(b)
    t = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n - 1, -1, -1):
        for j in range(m - 1, -1, -1):
            t[i][j] = t[i + 1][j + 1] + 1 if a[i] == b[j] else max(t[i + 1][j], t[i][j + 1])
    i = j = 0
    keep = []
    while i < n and j < m:
        if a[i] == b[j]:
            keep.append((i, j)); i += 1; j += 1
        elif t[i + 1][j] >= t[i][j + 1]:
            i += 1
        else:
            j += 1
    return keep


def report(path, fw):
    data = open(path, 'rb').read()
    blocks = file_blocks(data)
    print('=== %s  (%d bytes, %d TLV blocks) ===' % (os.path.basename(path), len(data), len(blocks)))
    ok = True
    for bi, (recs, end) in enumerate(blocks):
        ftags = [r[0] for r in recs]
        flens = {r[0]: r[1] for r in recs}
        # pick whichever firmware block shares more tags
        cand = max(range(len(fw)), key=lambda k: len(set(ftags) & {t for t, _ in fw[k]}))
        wtags = [t for t, _ in fw[cand]]
        wlens = dict(fw[cand])
        keep = lcs(ftags, wtags)
        shared = len(keep)
        added = [t for i, t in enumerate(ftags) if i not in {a for a, _ in keep}]
        dropped = [t for j, t in enumerate(wtags) if j not in {b for _, b in keep}]
        lendiff = ['%02X:%d->%d' % (t, wlens[t], flens[t]) for t in ftags
                   if t in wlens and wlens[t] != flens[t]]
        perm = shared < len(set(ftags) & set(wtags))
        if perm:
            ok = False
        print('  block %2d vs firmware block %d: %d/%d file tags aligned in order%s'
              % (bi, cand, shared, len(ftags), '   *** REORDERED ***' if perm else ''))
        print('      file tags : ' + ' '.join('%02X' % t for t in ftags))
        if added:
            print('      file adds : ' + ' '.join('%02X' % t for t in added))
        if dropped:
            print('      fw   only : ' + ' '.join('%02X' % t for t in dropped))
        if lendiff:
            print('      len fw->file: ' + ' '.join(lendiff))
    return ok


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    if not args:
        print(__doc__)
        return 2
    fw = firmware_blocks()
    print('firmware block 0: %d records   block 1: %d records' % (len(fw[0]), len(fw[1])))
    allok = True
    for p in args:
        allok &= report(p, fw)
    print('PASS: no block is a permutation of the firmware tag order.' if allok else
          'FAIL: at least one block reorders the firmware tag sequence.')
    return 0 if allok else 1


if __name__ == '__main__':
    sys.exit(main())
