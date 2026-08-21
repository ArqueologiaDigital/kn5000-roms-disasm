#!/usr/bin/env python3
"""What are the 24 slot blocks inside a .LSW file?

QUESTION ANSWERED: they are 24 instances of ONE fixed TLV schema -- 37 records,
692 payload bytes -- and the schema is byte-identical across all seven disks.
Block 0 carries the SAME tag sequence with LARGER payloads, so it reads as an
extended form of what the 24 slots hold in compact form.

    block 0      37 records, tags 0x00..0x16 + 0x19 at 30 B each  (extended)
    block 1      30 records, a DIFFERENT tag set that opens 0x17 0x18 ...
    blocks 2..25 37 records, tags 0x00..0x16 + 0x19 at 22 B each  (the 24 slots)

The tag space is partitioned, which is itself evidence the split is deliberate:
tags 0x17 and 0x18 appear ONLY in block 1, and never in the 24 slots, whose
sequential run stops at 0x16 and resumes at 0x19.

The slot schema, in file order:

    00..16,19  22 B each   24 records      (the bulk of a slot)
    44 45 46 48  10 B each                 60  12 B
    90            5 B                      61  30 B
    70            5 B                      63  30 B
    72 92        14 B each                 71   4 B      80  10 B

Of the 37 records, the SAME 17 vary between slots on every disk, and the other
20 are constant -- so the schema has a stable "identity" part and a stable
"payload" part. 20 of the 24 slots hold distinct content; the rest repeat.

⚠ This describes the seven floppies in KN7000/floppy-archive. Those files were
NOT written by KN5000 firmware, which emits 3,648 bytes and not 22,528 (see
docs/kn-disk-file-formats.md). The schema is real and exactly measured; whose
schema it is remains open.

Run:  python3 lsw_slot_schema.py <dir>...           (dirs holding extracted disks)
      python3 lsw_slot_schema.py <dir> --map        (adds the byte-variance map)
Exits non-zero if any disk departs from the schema.

The 24 22-byte records fall into TWO layouts, by variance mask:

    tags 00..0F   ...cc..cccccccc..c....     trailing bytes carry constants
    tags 10..16,19  XX.XX..Xcccc.X........   last nine bytes always zero

Tags 04..0E and 16 are byte-identical across all 24 slots; 00, 01, 02, 10, 11
and 12 carry the most variation. Byte 0 of those spans 0..119 across slots,
which is consistent with a 0..127 program number -- [INFERENCE], not shown.

⚠ REJECTED by measurement: byte 13 of the 10..16,19 records spans 192..207,
which looks exactly like MIDI Program Change status 0xC0|channel. Dumping it
per slot kills that reading -- it is 0xC0 in nearly every slot for every one of
those records, so it is not a per-record channel. An attractive range is not a
field identification.

Tag MEANINGS cannot be settled from these files alone. Settling them needs the
firmware of whatever WROTE them (not the KN5000, see the docs) or an A/B against
real hardware: change one panel setting, re-save, diff the slot.
"""
import glob, os, sys, collections

TLV_END = 0x4E80
N_BLOCKS, N_SLOTS, N_RECORDS, PAYLOAD = 26, 24, 37, 692


def parse(d):
    pos, blocks, cur = 0x20, [], []
    while pos < TLV_END:
        if d[pos] == 0xFF and d[pos + 1] == 0xFF:
            blocks.append(cur); cur = []; pos += 2; continue
        tag, ln = d[pos], d[pos + 1]
        cur.append((tag, ln, d[pos + 2:pos + 2 + ln]))
        pos += 2 + ln
    if cur:
        blocks.append(cur)
    return blocks


def check(path):
    b = parse(open(path, "rb").read())
    name = os.path.basename(path)
    if len(b) != N_BLOCKS:
        print(f"  {name}: FAIL -- {len(b)} blocks, expected {N_BLOCKS}"); return None
    slots = b[2:2 + N_SLOTS]
    sig = tuple((t, l) for t, l, _ in slots[0])
    shared = sum(1 for s in slots if tuple((t, l) for t, l, _ in s) == sig)
    total = sum(l for _, l in sig)
    payloads = [b"".join(p for _, _, p in s) for s in slots]
    varying = [i for i in range(len(sig)) if len({s[i][2] for s in slots}) > 1]
    ok = (shared == N_SLOTS and len(sig) == N_RECORDS and total == PAYLOAD)
    print(f"  {name:16} {shared}/{N_SLOTS} slots share one schema of {len(sig)} records "
          f"({total} B); {len(set(payloads))} distinct; {len(varying)} records vary  "
          f"{'OK' if ok else 'FAIL'}")
    return (sig, tuple(varying)) if ok else None


def variance_map(path):
    """Which BYTE POSITIONS inside each 22-byte record differ between slots?

    Legend: X varies across slots, c constant non-zero, . constant zero.
    """
    b = parse(open(path, "rb").read())
    slots = b[2:2 + N_SLOTS]
    print(f"\n  byte-position variance, 22-byte records of {os.path.basename(path)}:")
    for ri in range(24):
        tag = slots[0][ri][0]
        cols = [{s[ri][2][k] for s in slots} for k in range(22)]
        mask = "".join("X" if len(c) > 1 else ("." if next(iter(c)) == 0 else "c")
                       for c in cols)
        print(f"    tag {tag:02X}  {mask}")


def main():
    files = []
    for d in (sys.argv[1:] or ["."]):
        files += sorted(glob.glob(os.path.join(d, "**", "*.LSW"), recursive=True))
    if not files:
        sys.exit("no .LSW files given")
    results = [check(f) for f in files]
    if "--map" in sys.argv:
        variance_map(files[0])
    if any(r is None for r in results):
        print("FAIL"); return 1
    schemas = {r[0] for r in results}
    varysets = {r[1] for r in results}
    print(f"\ndistinct schemas across {len(files)} disks: {len(schemas)}")
    print(f"distinct varying-record sets:              {len(varysets)}")
    ok = len(schemas) == 1 and len(varysets) == 1
    print("PASS" if ok else "FAIL -- the schema is not universal")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
