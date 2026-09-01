#!/usr/bin/env python3
"""What is the 4,304-byte span at prom_a 0xF8C930, and does the header comment
above SelfPtrTable_F8C930 in wsa1_prom_a.s describe it accurately?

QUESTION IT ANSWERS
  Wave 1 (commit c94f57ca) investigated this span and deliberately left the
  whole 4,304 bytes as `.incbin` rather than respell it as `.byte` with
  nothing gained.  This script re-derives its structure from the ROM bytes
  directly -- an LE32 self-pointer table, an 18-long block of unclaimed
  constants, and a uniform 0x0E pad -- so the `.long`/`.fill` split committed
  in wsa1_prom_a.s can cite a checked claim instead of a hand count.

RUN
  python3 notes/prom_a_c930_selfptr_check.py
"""
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()

BASE = 0xF80000
LO = 0x00C930          # file offset == 0xF8C930
PTR_COUNT = 9
PTR_BYTES = PTR_COUNT * 4          # 36
BLOCK_LONGS = 18
BLOCK_BYTES = BLOCK_LONGS * 4      # 72
HEAD_BYTES = PTR_BYTES + BLOCK_BYTES  # 108
HI = 0x00DA00           # file offset == 0xF8DA00 (Task2_CallbackDispatcher)


def u32(off):
    return struct.unpack_from("<I", ROM, off)[0]


def main():
    ok = True

    # 1. The nine pointers.
    ptrs = [u32(LO + 4 * i) for i in range(PTR_COUNT)]
    for i, p in enumerate(ptrs):
        want = BASE + LO + PTR_BYTES + 8 * i
        if p != want:
            print(f"FAIL: pointer[{i}] = 0x{p:08X}, expected 0x{want:08X}")
            ok = False
    print(f"pointer table: {PTR_COUNT} entries, each 8 bytes apart, "
          f"0x{ptrs[0]:08X} .. 0x{ptrs[-1]:08X}"
          + (" -- all self-referential (each lands inside this same span)"
             if ok else ""))

    # 2. Each pointer really addresses the START of a distinct 8-byte pair
    #    inside the 18-long block that follows the table (no overlap, no gap).
    block_off = LO + PTR_BYTES
    for i, p in enumerate(ptrs):
        slot = p - BASE
        if slot != block_off + 8 * i:
            print(f"FAIL: pointer[{i}] does not land on slot {i} of the block")
            ok = False

    # 3. The 18-long block: report the byte alphabet actually used.
    block = ROM[block_off:block_off + BLOCK_BYTES]
    alphabet = sorted(set(block))
    print(f"18-long block (0x{BASE+block_off:06X}-0x{BASE+block_off+BLOCK_BYTES-1:06X}): "
          f"byte alphabet = {[hex(b) for b in alphabet]}")
    if not set(alphabet) <= {0x00, 0x40, 0x80}:
        print("NOTE: alphabet is wider than {0x00, 0x40, 0x80} -- update the header")
        ok = False
    words = [u32(block_off + 4 * k) for k in range(BLOCK_LONGS)]
    print("18 words:", ", ".join("0x%08x" % w for w in words))

    # 4. Head length and the uniform-fill tail, checked byte by byte (not
    #    sampled) -- this is the load-bearing claim for the `.fill` line.
    head_end = LO + HEAD_BYTES
    tail = ROM[head_end:HI]
    tail_len = HI - head_end
    uniform = set(tail) == {0x0E}
    print(f"head: 0x{BASE+LO:06X}-0x{BASE+head_end-1:06X} ({HEAD_BYTES} bytes)")
    print(f"tail: 0x{BASE+head_end:06X}-0x{BASE+HI-1:06X} ({tail_len} bytes), "
          f"uniform 0x0E = {uniform}")
    if not uniform:
        print(f"FAIL: tail is not uniform 0x0E -- byte set = "
              f"{sorted(hex(b) for b in set(tail))}")
        ok = False
    if tail_len != 4196:
        print(f"FAIL: expected tail length 4196, got {tail_len}")
        ok = False

    total = HI - LO
    print(f"\nspan 0x{BASE+LO:06X}-0x{BASE+HI-1:06X}: {total} bytes total "
          f"= {HEAD_BYTES} head (typed .long, meaning NOT established) "
          f"+ {tail_len} tail (verified uniform 0x0E .fill)")
    print("RESULT:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
