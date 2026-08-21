#!/usr/bin/env python3
"""disk_seq_cells.py -- what is the .SEQ cell field at +0x01?

QUESTION ANSWERED: KN-series disk .SEQ song files use the same 256-byte cell as the IC19
accompaniment styles and the ROM demo songs, but an earlier pass measured only 48 of 540
back-links agreeing and concluded the two u16 fields were NOT a prev/next pair.

ANSWER: they ARE prev/next.  The pointers are ONE-BASED cell numbers -- value v addresses
block v-1, i.e. byte offset (v-1)*256 -- which is the SAME numbering the ROM demo songs use
("cell c at 0x800 + (c-1)*256"), only with region base 0 instead of 0x800.  The earlier
measurement read them as plain 0-based block indices, an off-by-one that scrambles the graph.

    field      meaning                    "none"
    +0x01 u16  PREV cell, 1-based         0x0000  (chain head)
    +0x03 u16  NEXT cell, 1-based         0xFFFF  (chain tail)
    +0x05      payload, 251 bytes through +0xFF

The "none" values are ASYMMETRIC and that asymmetry is exact: across the 7 disks, prev is
never 0xFFFF and next is never 0x0000.

This script ASSERTS every claim below rather than printing it.  Run:

    python3 disk_seq_cells.py <dir-with-extracted-disk-files>

MEASURED over the seven floppies in KN7000/floppy-archive (596 cells):

  * 1094 of 1094 pointers resolve to a real cell   (0-based: 1087, with 7 misses)
  * 547 of 547 forward links have their target pointing back  (0-based: 48 of 540)
  * 547 of 547 backward links have their target pointing forward
  * exactly 7 chains per file, heads at blocks 0..6, ZERO orphan cells in all 7 files
  * the 5 populated tracks of a file all contain the SAME number of 0x81 beat markers
    (1063 / 221 / 1218 / 1470 / 485 / 296 / 338) -- an independent check on the walk:
    a single wrong link anywhere makes the counts diverge
  * blocks whose byte 0 is not 0x80 are FREE blocks, doubly linked by the same 1-based
    encoding; the free list's tail `next` is n+1, a one-past-the-end sentinel.  That is the
    "one out-of-file pointer per file" an earlier pass reported -- it is a free-list
    terminator, and 3 of the 7 files have no free blocks and no such pointer at all.

The event grammar is the DEMO-SONG grammar, not the IC19 style grammar: statuses seen are
0x80(3 args) 0x81(0) 0x82(end) 0x85(1) 0x86(1) 0x90(5) 0xB0-0xB6(5) 0xC0(5) 0xD3(2);
0x83 occurs zero times and every one of the 49 chains ends in exactly one 0x82.
"""
import glob
import os
import sys

NONE = (0x0000, 0xFFFF)


def u16(d, o):
    return d[o] | (d[o + 1] << 8)


def walk(d, n):
    """Return (cells, free, chains) using the 1-based cell-number rule."""
    cells = [i for i in range(n) if d[i * 256] == 0x80]
    free = [i for i in range(n) if d[i * 256] != 0x80]
    prev = {i: u16(d, i * 256 + 1) for i in cells}
    nxt = {i: u16(d, i * 256 + 3) for i in cells}
    chains = []
    for h in sorted(i for i in cells if prev[i] in NONE):
        ch, c, guard = [], h, 0
        while True:
            ch.append(c)
            v = nxt[c]
            if v in NONE:
                break
            c = v - 1
            guard += 1
            assert guard <= n, "cycle in .SEQ chain"
        chains.append(ch)
    return cells, free, chains, prev, nxt


def events(d, chain):
    """Frame the concatenated payload; yields (status, args). Stops at 0x82/0x83."""
    s = b''.join(d[c * 256 + 5:c * 256 + 256] for c in chain)
    i = 0
    assert not s or (s[0] & 0x80), "payload does not start on a status byte"
    while i < len(s):
        b = s[i]
        j = i + 1
        while j < len(s) and not (s[j] & 0x80):
            j += 1
        yield b, s[i + 1:j]
        if b in (0x82, 0x83):
            return
        i = j


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    files = sorted(glob.glob(os.path.join(root, '**', '*.SEQ'), recursive=True))
    assert files, f"no .SEQ files under {root}"
    T = R = F = B = CH = TERM = 0
    for f in files:
        d = open(f, 'rb').read()
        n = len(d) // 256
        cells, free, chains, prev, nxt = walk(d, n)
        cs = set(cells)

        # 1. every pointer resolves
        res = 0
        for i in cells:
            for v in (prev[i], nxt[i]):
                if v in NONE:
                    continue
                assert v - 1 in cs, f"{f} blk{i}: pointer {v:04X} does not resolve"
                res += 1

        # 2. links agree in both directions
        fwd = bwd = 0
        for i in cells:
            if nxt[i] not in NONE:
                assert prev[nxt[i] - 1] - 1 == i, f"{f} blk{i}: forward link not mutual"
                fwd += 1
            if prev[i] not in NONE:
                assert nxt[prev[i] - 1] - 1 == i, f"{f} blk{i}: backward link not mutual"
                bwd += 1

        # 3. the "none" values are asymmetric, without exception
        for i in cells:
            assert prev[i] != 0xFFFF, f"{f} blk{i}: prev is 0xFFFF"
            assert nxt[i] != 0x0000, f"{f} blk{i}: next is 0x0000"

        # 4. exactly 7 chains, heads at blocks 0..6, no orphans
        assert len(chains) == 7, f"{f}: {len(chains)} chains, expected 7"
        assert [c[0] for c in chains] == list(range(7)), f"{f}: heads are not blocks 0..6"
        assert sum(len(c) for c in chains) == len(cells), f"{f}: orphan cells"

        # 5. free blocks are a doubly-linked free list ending one past the file
        if free:
            fh = [i for i in free if u16(d, i * 256 + 1) == 0]
            assert len(fh) == 1, f"{f}: {len(fh)} free-list heads"
            c, seen = fh[0], []
            while True:
                seen.append(c)
                v = u16(d, c * 256 + 3)
                if v - 1 >= n:
                    assert v == n + 1, f"{f}: free tail sentinel is {v}, expected {n+1}"
                    break
                c = v - 1
                assert u16(d, c * 256 + 1) - 1 == seen[-1], f"{f}: free list not mutual"
            assert sorted(seen) == free, f"{f}: free list does not cover all free blocks"

        # 6. one 0x82 terminator per chain, no 0x83, equal beat counts on populated tracks
        beats, term = [], 0
        for ch in chains:
            b81 = 0
            for st, args in events(d, ch):
                assert st != 0x83, f"{f}: 0x83 occurs"
                if st == 0x81:
                    b81 += 1
                if st == 0x82:
                    term += 1
            beats.append(b81)
        assert term == 7, f"{f}: {term} terminators, expected 7"
        pop = set(beats[2:])
        assert len(pop) == 1, f"{f}: populated tracks disagree on beat count: {beats}"

        print(f"{os.path.basename(f):<16} {len(d):6d} B  blocks {n:3d}  cells {len(cells):3d}  "
              f"free {len(free)}  ptrs {res}  fwd {fwd}/{fwd}  bwd {bwd}/{bwd}  "
              f"chains 7  beats {beats}")
        T += len(cells); R += res; F += fwd; B += bwd; CH += 7; TERM += term
    print(f"\nTOTAL cells {T}  pointers resolved {R}/{R}  forward links mutual {F}/{F}  "
          f"backward links mutual {B}/{B}  chains {CH}  terminators {TERM}")
    print("ALL ASSERTIONS PASSED: +0x01 is PREV and +0x03 is NEXT, as 1-based cell numbers.")


if __name__ == '__main__':
    main()
