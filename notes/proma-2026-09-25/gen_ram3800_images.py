#!/usr/bin/env python3
r"""Frame prom_a's two RAM data images (0xFCB3D3 -> RAM 0x3800, 0xFCBF39 -> RAM 0x602054).

QUESTION THIS ANSWERS
    The RAM-0x3800 module's C-runtime initialiser (Ram3800_InitAll, 0xFC8020)
    copies 2,918 bytes to RAM 0x003800 and 160 bytes to RAM 0x602054.  Their
    headers said "Unknown: everything about its contents" / "Unknown: its
    contents" and "nothing in this module indexes it with a stride this listing
    can read".  The module DOES index them, with strides that are literals in
    its code, and the images' own bytes are self-describing (link fields that
    point at their own record).  This script derives the layout, CHECKS it
    against the image bytes, and with --apply writes it as typed data:

      RAM 0x3800  32 x u8   = 24     budget per slot         FC9FFE `add XIY,0x3800` + `cp C,0 / jrl le`,
                                                             FCA0CE `decm8 1,(XBC)` (+5 more sites)
      RAM 0x3820   3 x u8   = 16     budget per queue        FC9CB3, FC9D49 `add XBC,0x3820`
      RAM 0x3823   3 x 13-B queue heads, self-linked         FC8F7C `ldw DE,0x3823 / add DE,13*k`
      RAM 0x384A  33 x 13-B pool nodes, ONE ring             (+9 prev, +0x0B next: FC8FA7/FC8FC6
                                                              `ld HL,(X+0x0B)` walk to the head)
      RAM 0x39F7  32 x 15-B list heads, self-linked          FC8E93 `ldw WA,0x39F7 / add WA,15*i`
      RAM 0x3BD7 129 x 15-B pool nodes, ONE ring             (+0x0B prev, +0x0D next: FC9FEC
                                                              `ld WA,(XBC+0x0D)`)
      RAM 0x602054 32 x u32 = 1<<k   slot bit masks          FC8F57/FC9C66 `mul C,H` (C=4) + `add XBC,0x602054`
      RAM 0x6020D4 32 x u8  = 0x80   per-slot state byte     FCA6E5/FCA6FE/FCA715

    CHECKS (all must hold or nothing is written): every head's two link words
    equal its own RAM address; each pool is exactly one ring through all its
    nodes (prev/next agree, every node visited once); every payload byte is 0;
    the arrays hold the stated constants; the pieces tile each image exactly.

RUN
    python3 notes/proma-2026-09-25/gen_ram3800_images.py           # checks + layout
    python3 notes/proma-2026-09-25/gen_ram3800_images.py --apply   # rewrite wsa1_prom_a.s
    make gate-wsa1
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

ROM = open(srcmap.ROM, "rb").read()
B = srcmap.BASE
IMG1, LEN1, RAM1 = 0xFCB3D3, 0xB66, 0x3800
IMG2, LEN2, RAM2 = 0xFCBF39, 0xA0, 0x602054


def img1(ram, n=1):
    o = IMG1 - B + (ram - RAM1)
    return ROM[o:o + n]


def w16(ram):
    x = img1(ram, 2)
    return x[0] | x[1] << 8


def check():
    assert img1(0x3800, 32) == bytes([24]) * 32
    assert img1(0x3820, 3) == bytes([16]) * 3
    for base, n_head, n_pool, size, prev, nxt in ((0x3823, 3, 33, 13, 9, 11),
                                                 (0x39F7, 32, 129, 15, 11, 13)):
        heads = [base + size * k for k in range(n_head)]
        pool = [base + size * (n_head + k) for k in range(n_pool)]
        for h in heads:
            assert w16(h + prev) == h and w16(h + nxt) == h, "head 0x%04X not self-linked" % h
            assert img1(h, prev) == bytes(prev)
        seen, p = [], pool[0]
        for _ in range(n_pool):
            seen.append(p)
            q = w16(p + nxt)
            assert w16(q + prev) == p, "ring prev/next disagree at 0x%04X" % p
            assert img1(p, prev) == bytes(prev), "payload of 0x%04X not zero" % p
            p = q
        assert p == pool[0] and sorted(seen) == pool, "pool at 0x%04X is not one ring" % pool[0]
    assert 0x39F7 + 15 * 161 == RAM1 + LEN1
    assert 0x3823 + 13 * 36 == 0x39F7
    o = IMG2 - B
    for k in range(32):
        assert int.from_bytes(ROM[o + 4 * k:o + 4 * k + 4], "little") == 1 << k
    assert ROM[o + 128:o + 160] == bytes([0x80]) * 32


def u8(x):
    return x.encode("utf-8").decode("latin-1")


H1 = """; ---------------------------------------------------------------------
; Ram3800_DataImage -- 2,918 bytes copied verbatim to RAM 0x003800
;
; Evidence: `ld XBC,0x00000b66 / lda XIY,0xfcb3d3 / lda XIX,0x003800 / ldir`, at
; 0xFC8020 and again at 0xFC807D.  0xB66 = 2918, and 0xFCB3D3 + 0xB66 =
; 0xFCBF39, which is where the NEXT image starts -- the two abut with no slack,
; and that is this table's last-entry test.  Exactly two sites in prom_a and
; prom_b form the address 0xFCB3D3, and both are those `lda XIY`s.
;
; ★ ITS LAYOUT, established 2026-09-25 (lane proma).  This header used to say
; the block had "NO field structure claimed: nothing in this module indexes it
; with a stride the listing can read".  The module does, with literal strides,
; and the bytes confirm each one by pointing at themselves:
;
;   RAM 0x3800  32 x u8, all 24    a per-SLOT budget.  0xFC9FFE `add XIY,
;               0x00003800 / ld C,(XIY) / cp c,0 / jrl le` skips when it is
;               <= 0; 0xFCA0CE `decm8 0x01,(xbc)` spends one; five more `add
;               XBC,0x00003800` in sub_FC9F8B/sub_FCA276/sub_FCA475.
;   RAM 0x3820   3 x u8, all 16    the same per QUEUE (0xFC9CB3, 0xFC9D49).
;   RAM 0x3823   3 x 13-byte QUEUE HEADS.  0xFC8F7C `ldw DE,0x3823 / add
;               DE,13*k`.  Node layout: +0..+8 payload (+2 a key byte and
;               +5 a long, 0xFC8FB3/0xFC8FBF), +9 PREV, +0x0B NEXT, both u16.
;               A head's links point at ITSELF: three empty circular lists.
;   RAM 0x384A  33 x 13-byte POOL nodes, linked into ONE ring.
;   RAM 0x39F7  32 x 15-byte LIST HEADS (one per slot), self-linked.  0xFC8E93
;               `ldw WA,0x39F7 / add WA,15*i` (i = (XIZ+8), 0xFF = none);
;               +0x0B PREV, +0x0D NEXT (0xFC9FEC `ld WA,(XBC+0x0d)`).
;   RAM 0x3BD7 129 x 15-byte POOL nodes, linked into ONE ring.
; Counts: 32 and 3 are the self-linked heads (a head is the record whose
; links name itself); 33 and 129 are the ring lengths; 32+3+36*13+161*15 =
; 2,918, the copy length.  notes/proma-2026-09-25/gen_ram3800_images.py checks
; every link, the rings and the constants against the ROM.
; ⚠ NOT claimed: what a slot, a queue or a node's payload MEANS, or where the
; two pools' free-list heads live (no immediate in either image names 0x384A
; or 0x3BD7; the heads must be runtime pointers).
; ---------------------------------------------------------------------"""

H2 = """; ---------------------------------------------------------------------
; Ram602054_DataImage -- 160 bytes copied verbatim to RAM 0x00602054
;
; Evidence: `ld XBC,0x000000a0 / lda XIY,0xfcbf39 / lda XIX,0x602054 / ldir` at
; 0xFC805C.  0xA0 = 160, and 0xFCBF39 + 0xA0 = 0xFCBFD9 -- the last-entry test
; again: the byte at 0xFCBFD9 is 0xFF and begins the sentinel run below, and the
; last 25 bytes of THIS image are 0x80, so the boundary is visible in the bytes
; as well as in the length.  One site forms 0xFCBF39, that `lda XIY`.
;
; ★ ITS LAYOUT, established 2026-09-25 (lane proma; this header used to leave
; its contents open):
;   RAM 0x602054  32 x u32 = 1 << k, a SLOT BIT MASK per slot index.
;                 0xFC8F57 and 0xFC9C66: `ld C,4 / mul C,H / add XBC,
;                 0x00602054 / ld XBC,(XBC)`, the first then OR-ing it into a
;                 32-bit set at (XIZ-4).
;   RAM 0x6020D4  32 x u8 = 0x80, a per-slot state byte: 0xFCA6E5 reads it
;                 (`cp L,0xFF`), 0xFCA6FE writes it, 0xFCA715 reads it again.
; 32 slots, the same count as the 32 list heads in Ram3800_DataImage.
; ⚠ What the state byte's values mean is not claimed.
; ---------------------------------------------------------------------"""


def emit():
    O = H1.split("\n") + ["Ram3800_DataImage:"]
    O.append("\t.byte %s  ; FCB3D3  RAM 0x3800..0x380F" % ", ".join(["24"] * 16))
    O.append("\t.byte %s  ; FCB3E3  RAM 0x3810..0x381F" % ", ".join(["24"] * 16))
    O += ["", "; Ram3800_Img_QueueBudget -- RAM 0x3820, 3 x u8 = 16: the per-queue budget",
          "; read at 0xFC9CB3 / 0xFC9D49 (`add XBC,0x00003820`); see Ram3800_DataImage.",
          "Ram3800_Img_QueueBudget:",
          "\t.byte 16, 16, 16%s; FCB3F3  RAM 0x3820..0x3822" % (" " * 20)]

    def nodes(label, hdr, ram0, n, size, prev):
        out = ["", *hdr, "%s:" % label]
        for k in range(n):
            r = ram0 + size * k
            rom = IMG1 + (r - RAM1)
            out.append("\t.byte %s%s; %06X  RAM 0x%04X payload" % (
                ", ".join(["0"] * prev), " " * 3, rom, r))
            out.append("\t.short 0x%04X, 0x%04X%s; %06X  prev, next" % (
                w16(r + prev), w16(r + prev + 2), " " * 20, rom + prev))
        return out

    O += nodes("Ram3800_Img_QueueHeads",
               ["; Ram3800_Img_QueueHeads -- RAM 0x3823, three 13-byte queue heads, each",
                "; linked to itself (empty); read via 0xFC8F7C `ldw DE,0x3823 / add DE,13*k`."],
               0x3823, 3, 13, 9)
    O += nodes("Ram3800_Img_QueuePool",
               ["; Ram3800_Img_QueuePool -- RAM 0x384A, 33 13-byte nodes linked into one ring",
                "; (prev at +9, next at +0x0B), the pool the three queues draw from."],
               0x384A, 33, 13, 9)
    O += nodes("Ram3800_Img_ListHeads",
               ["; Ram3800_Img_ListHeads -- RAM 0x39F7, thirty-two 15-byte list heads, one per",
                "; slot, each linked to itself; read via 0xFC8E93 `ldw WA,0x39F7 / add WA,15*i`."],
               0x39F7, 32, 15, 11)
    O += nodes("Ram3800_Img_ListPool",
               ["; Ram3800_Img_ListPool -- RAM 0x3BD7, 129 15-byte nodes linked into one ring",
                "; (prev at +0x0B, next at +0x0D), the pool the 32 slot lists draw from."],
               0x3BD7, 129, 15, 11)
    O += [""] + H2.split("\n") + ["Ram602054_DataImage:"]
    for k in range(32):
        O.append("\t.long 0x%08x%s; %06X  RAM 0x%06X  1 << %d" % (1 << k, " " * 26, IMG2 + 4 * k,
                                                                  RAM2 + 4 * k, k))
    O += ["", "; Ram602054_Img_SlotState -- RAM 0x6020D4, 32 x u8 = 0x80, the per-slot state",
          "; byte read at 0xFCA6E5/0xFCA715 and written at 0xFCA6FE; see above.",
          "Ram602054_Img_SlotState:"]
    O.append("\t.byte %s  ; FCBFB9  RAM 0x6020D4..0x6020E3" % ", ".join(["0x80"] * 16))
    O.append("\t.byte %s  ; FCBFC9  RAM 0x6020E4..0x6020F3" % ", ".join(["0x80"] * 16))
    O.append("")
    return O


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    check()
    print("RAM 0x3800 image: 32+3 budgets, 3 heads + 33-node ring (13 B), 32 heads + 129-node ring "
          "(15 B), tiles 2,918 B; RAM 0x602054 image: 32 x (1<<k), 32 x 0x80 -- all checks pass")
    if not a.apply:
        return
    m = srcmap.load()
    L = m.lines
    h = next(i for i, l in enumerate(L) if l.startswith("; Ram3800_DataImage -- 2,918 bytes copied verbatim"))
    assert L[h - 1].startswith("; -----")
    e = next(i for i in range(h, len(L)) if L[i].startswith("; Ram3800_Sentinels -- 17 bytes"))
    assert L[e - 1].startswith("; -----")
    fix_old = [
        ";   * what the 2,918-byte image at 0x003800 contains.  It is emitted as `.byte`",
        ";     with no field structure claimed, because nothing in this module indexes it",
        ";     with a stride this listing can read.",
    ]
    fix_new = [
        ";   * ~~what the 2,918-byte image at 0x003800 contains~~ -- ESTABLISHED",
        ";     2026-09-25: the module indexes it with literal strides of 13 and 15, and",
        ";     the layout (budgets, queue/list heads, node pools) is in its own header,",
        ";     Ram3800_DataImage below.  The 160-byte image at 0x602054 likewise.",
    ]
    fi = next(i for i, l in enumerate(L) if l == fix_old[0])
    assert L[fi:fi + 3] == fix_old
    new = L[:fi] + [u8(x) for x in fix_new] + L[fi + 3:h - 1] + [u8(x) for x in emit()] + L[e - 1:]
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(new))
    print("applied: %d lines -> %d" % (e - h + 1, len(emit())))


if __name__ == "__main__":
    main()
