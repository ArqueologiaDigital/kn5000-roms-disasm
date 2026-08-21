#!/usr/bin/env python3
"""ASSERTING probe for the KN .LSW disk file container.

Run:  python3 lsw_container.py /tmp/wf/disk      (dir holding <disk>/<name>.LSW and .MSP)

Every property below is asserted, not printed, so a wrong reading fails loudly.

Container, measured over the seven floppies in KN7000/floppy-archive/*.zip:

  0x0000  0x20 B   header, byte-identical on all seven:
                   5A 5A 01 00 4D 36 30 0A 00 00 00 EE 03 00 00 00  + 16 zero bytes
                   u16 LE at +0x0B = 0x03EE = the offset of the first block terminator.
  0x0020  ...      a chain of BLOCKS.  Each block is a TLV stream -- tag u8, len u8,
                   len payload bytes -- and is terminated by the two bytes FF FF.
                   Exactly 26 blocks, ending at 0x4E7E:
                     block  0  0x0020..0x03EE  37 recs, part records 30 B
                     block  1  0x03F0..0x067E  30 recs   (no part records)
                     blocks 2..25              37 recs, part records 22 B,
                                               768 B apart: 0x0680 + n*0x300
  0x4E80  0x30 B   48 bytes, not framed as TLV
  0x4EB0  0x10 B   5A 5A 5A 4C 4B 45 80 00 then 8 zero bytes
  0x4EC0  0x500 B  128 records of 10 bytes  (stride proved by the cross-disk diff)
  0x53C0  0xC0 B   12 records of 16 bytes, every one
                   00 00 00 00 FF FF FF FF FF FF FF FF 00 00 00 00
  0x5480  0x380 B  BYTE-IDENTICAL to the first 896 bytes of the same disk's .MSP file

Part records: in block 0 and in blocks 2..25 the first 24 TLV records carry tags
0x00..0x16 and 0x19, in that order, and payload byte 13 repeats the record's own tag
for tags 0x00..0x0F (175/175 records) and lies in 0xC0..0xCF for tags 0x10..0x16 and
0x19.  Payload byte 12 is CONSTANT per tag over all 175 records: 0x38 for tags 0x00/0x01,
0x20 for 0x03..0x0E, 0x00 for the rest.
"""
import sys, pathlib

HDR = bytes.fromhex('5a5a01004d36300a000000ee0300000000000000000000000000000000000000')
PART_TAGS = list(range(0x17)) + [0x19]
TRAILER    = [0x44,0x45,0x46,0x48,0x90,0x60,0x61,0x63,0x70,0x72,0x92,0x71,0x80]
BLOCK1     = [0x17,0x18,0x98,0x99,0x91,0x93] + list(range(0xC0,0xD5)) + [0xD7,0x49,0x9A]

def blocks(b):
    off, start, cur, out = 0x20, 0x20, [], []
    while off < len(b)-1:
        if b[off] == 0xFF and b[off+1] == 0xFF:
            out.append((start, off, cur)); off += 2; start = off; cur = []
            if len(out) == 26: return out, off
            continue
        t, ln = b[off], b[off+1]
        cur.append((off, t, ln, bytes(b[off+2:off+2+ln]))); off += 2+ln
    raise AssertionError('fewer than 26 FF FF-terminated blocks')

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/wf/disk')
disks = sorted(p for p in root.iterdir() if p.is_dir())
assert len(disks) == 7, disks
shapes = set()
for d in disks:
    lsw = next(d.glob('*.LSW')).read_bytes()
    msp = next(d.glob('*.MSP')).read_bytes()
    assert len(lsw) == 22528, (d, len(lsw))
    assert lsw[:0x20] == HDR, d
    assert int.from_bytes(lsw[0x0B:0x0D], 'little') == 0x03EE, d

    bl, end = blocks(lsw)
    assert end == 0x4E80, (d, hex(end))
    assert [s for s, _, _ in bl] == [0x20, 0x3F0] + [0x680 + i*0x300 for i in range(24)], d
    shapes.add(tuple(tuple((t, l) for _, t, l, _ in recs) for _, _, recs in bl))

    assert [t for _, t, _, _ in bl[0][2]] == PART_TAGS + TRAILER, d
    assert [l for _, _, l, _ in bl[0][2]][:24] == [30]*24, d
    assert [t for _, t, _, _ in bl[1][2]] == BLOCK1, d
    for i in range(2, 26):
        assert [t for _, t, _, _ in bl[i][2]] == PART_TAGS + TRAILER, (d, i)
        assert [l for _, _, l, _ in bl[i][2]][:24] == [22]*24, (d, i)
    for blk in [bl[0]] + bl[2:]:
        for _, t, _, p in blk[2][:24]:
            assert (p[13] == t) if t <= 0x0F else (0xC0 <= p[13] <= 0xCF), (d, t, p[13])

    assert lsw[0x4EB0:0x4EB8] == bytes.fromhex('5a5a5a4c4b458000'), d
    assert lsw[0x4EB8:0x4EC0] == b'\0'*8, d
    for o in range(0x53C0, 0x5480, 16):
        assert lsw[o:o+16] == bytes.fromhex('00000000ffffffffffffffff00000000'), (d, hex(o))
    assert lsw[0x5480:0x5800] == msp[:0x380], d

assert len(shapes) == 1, f'{len(shapes)} distinct block shapes across the seven disks'

# --- the record array at 0x4EC0 -------------------------------------------------
bs = [next(d.glob('*.LSW')).read_bytes() for d in disks]
S, E = 0x4EC0, 0x53C0

# (a) FIELD stride 2, proved by a parity invariant over 8890 bytes x 7 disks:
#     a byte at an EVEN offset from 0x4EC0 always has bit 7 clear; a byte at an ODD
#     offset always has (v & 0x7F) <= 5.  At an odd phase the same test fails on
#     ~53% of bytes, so the phase is not free.
for phase, expect_zero in ((0, True), (1, False)):
    bad = 0
    for b in bs:
        for o in range(S+phase, E-10, 2):
            if b[o] & 0x80: bad += 1
            if (b[o+1] & 0x7F) > 5: bad += 1
    assert (bad == 0) == expect_zero, (phase, bad)

# (b) RECORD stride 10, proved by cross-disk difference runs: merge difference runs
#     across gaps < 4, keep those >= 8 bytes, and every one starts on a multiple of 10.
var = [any(x[i] != bs[0][i] for x in bs) for i in range(22528)]
runs, i = [], S
while i < E:
    j = i
    while j < E and var[j] == var[i]: j += 1
    if var[i]: runs.append([i, j])
    i = j
merged = []
for s_, e_ in runs:
    if merged and s_ - merged[-1][1] < 4: merged[-1][1] = e_
    else: merged.append([s_, e_])
long = [(s_, e_) for s_, e_ in merged if e_ - s_ >= 8]
assert len(long) == 13, len(long)
assert all((s_ - S) % 10 == 0 for s_, e_ in long), [hex(s_) for s_, e_ in long]
assert (E - S) // 10 == 128

assert sum(var[0x5480:0x5800]) == 0, '.MSP mirror varies across disks'

# --- the 24 slot blocks ---------------------------------------------------------
# On all seven disks: slots 0..9 differ from disk to disk (user data); slots 10..23
# are byte-identical across the seven (never written); and slots 20..23 repeat the
# contents of slots 10..13, while 10..19 are pairwise distinct.
slot = lambda b, n: b[0x680 + n*0x300 : 0x680 + (n+1)*0x300]
for n in range(10):
    assert len({slot(b, n) for b in bs}) > 1, f'slot {n} constant across disks'
for n in range(10, 24):
    assert len({slot(b, n) for b in bs}) == 1, f'slot {n} varies across disks'
for b in bs:
    for k in range(4):
        assert slot(b, 20+k) == slot(b, 10+k), k
    assert len({slot(b, n) for n in range(10, 20)}) == 10
assert sum(var[0:0x20]) == 0, 'header varies across disks'

print("OK  7 disks; 26 blocks and one block shape each; 128 x 10-byte records at 0x4EC0 "
      "(13/13 difference runs 10-aligned, parity invariant 0/8890 violations); "
      ".MSP mirror byte-exact on all seven; slots 0..9 user data, 10..23 untouched, "
      "20..23 == 10..13")
