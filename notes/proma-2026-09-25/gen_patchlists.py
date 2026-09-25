#!/usr/bin/env python3
r"""Frame prom_a 0xFB1A3E-0xFB1FFF: three AND/OR RAM patch lists, their one-entry
pointer tables, and the module's 0x0E pad -- by the three routines that apply them.

QUESTION THIS ANSWERS
    The block was `.byte` under three "register-poke record list" comments and
    the local label `.LFB1A06`.  Its readers are three routines of the module
    entered through T_F40840 (0xFB1800), each called with the byte (0x2744),
    which the entry has already bounded to 0 (`cp C,1 / jr nc` exits):

      .LFB1950 -> PatchList_ApplyRecordBytes2B   `ld C,4 / mul BC,(XIZ+8) /
      .LFB18DE -> PatchList_ApplyRecordField0C    add XBC,<table> / ld XBC,(XBC)`
      .LFB1879 -> PatchList_ApplyGlobals7F32      then a loop over records

      PatchList_Globals7F32   11 x (addr32, and8, or8):  (*addr &= and) |= or
                              loop count `ld H,0x0B`
      PatchList_RecordField0C 32 x (addr32, b4, b5):     *addr = (*addr & 0xF8)|b4;
                              *(addr+1) = b5            loop count `ld H,0x20`
      PatchList_RecordBytes2B 32 x (addr32, 12 x (and8, or8)), stride 0x1C:
                              for 12 bytes from addr: (*p &= and) |= or
                              loop counts `ld L,0x20`, `ld H,0x0C`
    Each is reached through a one-entry pointer table right after it (the
    `add XBC,<table>` operand); one entry, because the index can only be 0.
    The addresses in the second and third lists are +0x0C and +0x2B of the 32
    64-byte RAM records at 0x76A2 (RecordPtrs_RAM76A2's array, the same single
    0x80 step after record 7); the first list patches 0x7F32..0x7F3C.

    Checks: the three readers' table operands and loop counts are the bytes
    cited; the lists tile to their pointer tables, and each pointer names its
    list; the pad is all 0x0E; the whole tiles 0xFB1A3E..0xFB2000.

RUN
    python3 notes/proma-2026-09-25/gen_patchlists.py [--apply]
    make gate-wsa1
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
ROM = open(srcmap.ROM, "rb").read()
g = lambda a, n=1: ROM[a - B:a - B + n]  # noqa: E731
u32 = lambda a: int.from_bytes(g(a, 4), "little")  # noqa: E731


def find(pat):
    i = ROM.find(pat)
    assert i >= 0 and ROM.find(pat, i + 1) < 0, pat.hex()
    return B + i


def check():
    for tab, site in ((0xFB1A80, 0xFB1887), (0xFB1B44, 0xFB18EC), (0xFB1EC8, 0xFB195E)):
        assert find(bytes([0xE9, 0xC8]) + tab.to_bytes(4, "little")) == site   # add XBC,<tab>: one site
    assert g(0xFB1894, 2) == b"\x26\x0b" and g(0xFB18F9, 2) == b"\x26\x20"     # ld H,11 / ld H,32
    assert g(0xFB196E, 2) == b"\x27\x20" and g(0xFB198A, 2) == b"\x26\x0c"     # ld L,32 / ld H,12
    assert u32(0xFB1A80) == 0xFB1A3E and u32(0xFB1B44) == 0xFB1A84 and u32(0xFB1EC8) == 0xFB1B48
    assert 0xFB1A3E + 6 * 11 == 0xFB1A80 and 0xFB1A84 + 6 * 32 == 0xFB1B44 and 0xFB1B48 + 28 * 32 == 0xFB1EC8
    assert set(g(0xFB1ECC, 0xFB2000 - 0xFB1ECC)) == {0x0E}
    b = [u32(0xFB1A84 + 6 * k) for k in range(32)]
    c = [u32(0xFB1B48 + 28 * k) for k in range(32)]
    rec = [0x76A2 + 0x40 * k + (0x40 if k >= 8 else 0) for k in range(32)]
    assert b == [r + 0x0C for r in rec] and c == [r + 0x2B for r in rec]
    assert [u32(0xFB1A3E + 6 * k) for k in range(11)] == list(range(0x7F32, 0x7F3D))


def u8(x):
    return x.encode("utf-8").decode("latin-1")


def emit():
    O = """; ---------------------------------------------------------------------
; 0xFB1A3E-0xFB1ECB -- THREE AND/OR RAM PATCH LISTS, each followed by the
; one-entry pointer table its routine reads (notes/proma-2026-09-25/
; gen_patchlists.py re-derives every count and address below from the ROM)
;
; The module entered through T_F40840 (0xFB1800) calls each routine with the
; byte (0x2744), which it has already bounded to 0 (`cp C,1 / jr nc` leaves);
; each routine does `ld C,4 / mul BC,(XIZ+8) / add XBC,<table> / ld XBC,(XBC)`
; and walks the list that pointer names.  So one entry per table, from the
; bound.  The addresses in the second and third lists are +0x0C and +0x2B of
; the 32 64-byte RAM records at 0x76A2 (RecordPtrs_RAM76A2's array, with the
; same single 0x80 step after record 7); the first list patches 0x7F32-0x7F3C.
; What the patched fields MEAN is not claimed.
; ---------------------------------------------------------------------

; PatchList_Globals7F32 -- 11 x (address32, and8, or8): (*addr & and) | or.
; Applied by PatchList_ApplyGlobals7F32 (`ld H,0x0B` at 0xFB1894: 11 records,
; stride 6).
PatchList_Globals7F32:""".split("\n")
    for k in range(11):
        a = 0xFB1A3E + 6 * k
        r = g(a, 6)
        O.append("\t.long 0x%08x%s; %06X  RAM 0x%04X" % (u32(a), " " * 30, a, u32(a)))
        O.append("\t.byte 0x%02x, 0x%02x%s; %06X  and, or" % (r[4], r[5], " " * 34, a + 4))
    O += ["", "; PatchList_Globals7F32_Ptr -- the one-entry table PatchList_ApplyGlobals7F32 indexes",
          "; with `add XBC,0x00FB1A80` at 0xFB1887; see the block header for the bound.",
          "PatchList_Globals7F32_Ptr:",
          "\t.long PatchList_Globals7F32%s; FB1A80" % (" " * 17),
          "", "; PatchList_RecordField0C -- 32 x (address32, b4, b5): *addr = (*addr & 0xF8) | b4,",
          "; then *(addr+1) = b5.  Applied by PatchList_ApplyRecordField0C (`ld H,0x20`",
          "; at 0xFB18F9).",
          "; Every address is +0x0C of RAM record k (0x76A2 + 0x40*k, +0x40 past k = 7) and",
          "; b5 = k.",
          "PatchList_RecordField0C:"]
    for k in range(32):
        a = 0xFB1A84 + 6 * k
        r = g(a, 6)
        O.append("\t.long 0x%08x%s; %06X  record %2d +0x0C" % (u32(a), " " * 30, a, k))
        O.append("\t.byte 0x%02x, 0x%02x%s; %06X  b4, b5" % (r[4], r[5], " " * 34, a + 4))
    O += ["", "; PatchList_RecordField0C_Ptr -- one entry, read with `add XBC,0x00FB1B44` at 0xFB18EC.",
          ";          See the block header for why there is one.",
          "PatchList_RecordField0C_Ptr:",
          "\t.long PatchList_RecordField0C%s; FB1B44" % (" " * 15),
          "", "; PatchList_RecordBytes2B -- 32 x (address32, then 12 x (and8, or8)), 28 bytes",
          "; each: for the 12 bytes from the address, (*p & and) | or.  Applied by",
          "; PatchList_ApplyRecordBytes2B (`ld L,0x20` at 0xFB196E entries, `ld H,0x0C` at",
          "; 0xFB198A pairs, stride 0x1C).  Every address is +0x2B of RAM record k.",
          "PatchList_RecordBytes2B:"]
    for k in range(32):
        a = 0xFB1B48 + 28 * k
        pr = g(a + 4, 24)
        O.append("\t.long 0x%08x%s; %06X  record %2d +0x2B" % (u32(a), " " * 30, a, k))
        O.append("\t.byte %s  ; %06X  and, or x 6" % (", ".join("0x%02x" % x for x in pr[:12]), a + 4))
        O.append("\t.byte %s  ; %06X  and, or x 6" % (", ".join("0x%02x" % x for x in pr[12:]), a + 16))
    O += ["", "; PatchList_RecordBytes2B_Ptr -- one entry, read with `add XBC,0x00FB1EC8` at 0xFB195E.",
          ";          See the block header for why there is one.",
          "PatchList_RecordBytes2B_Ptr:",
          "\t.long PatchList_RecordBytes2B%s; FB1EC8" % (" " * 15),
          "", "; 0xFB1ECC-0xFB1FFF -- 308 bytes of 0x0E (RET), module padding (checked by",
          "; gen_patchlists.py, not sampled).",
          "\t.fill 308, 1, 0x0E%s; FB1ECC" % (" " * 33)]
    return O


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    check()
    print("three readers, three one-entry tables, lists 11/32/32, record addresses, pad: OK")
    if not a.apply:
        return
    L = open(srcmap.SRC, encoding="latin-1").read().split("\n")
    s = L.index("; --- 0xFB1A3E-0xFB1A84  register-poke record list (70 bytes) ---")
    e = L.index("; --- 0xFB1ECC-0xFB2000  0x0E pad (308 bytes) ---") + 1
    while L[e].startswith("\t.byte 0x0e"):          # the pad's own rows end the block
        e += 1
    new = L[:s] + [u8(x) for x in emit()] + L[e:]
    txt = "\n".join(new)
    for old, lab in ((".LFB1879", "PatchList_ApplyGlobals7F32"), (".LFB18DE", "PatchList_ApplyRecordField0C"),
                     (".LFB1950", "PatchList_ApplyRecordBytes2B")):
        import re
        txt = re.sub(r"(?<![\w.$])" + re.escape(old) + r"(?![\w.$])", lab, txt)
    for old, lab in (("add XBC,0x00fb1a80", "add XBC,PatchList_Globals7F32_Ptr"),
                     ("add XBC,0x00fb1b44", "add XBC,PatchList_RecordField0C_Ptr"),
                     ("add XBC,0x00fb1ec8", "add XBC,PatchList_RecordBytes2B_Ptr")):
        assert txt.count("\t" + old) == 1, old
        txt = txt.replace("\t" + old, "\t" + lab)
    open(srcmap.SRC, "w", encoding="latin-1").write(txt)
    print("applied")


if __name__ == "__main__":
    main()
