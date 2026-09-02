#!/usr/bin/env python3
r"""IS 0xF15907-0xF1612F CODE, OR A [flags:u8][len:u8] RECORD STREAM?

QUESTION ANSWERED
-----------------
`v10/maincpu/storage/flash_floppy_handlers.s` lines 35..1077 are written as
TLCS-900 instructions -- `reti / pop xbc / .byte 0xf1 / nop`, `ldwio 97,0xff06`,
`push sr` -- 2,088 bytes of them.  The byte gate cannot tell whether that
reading is right: re-assembling a WRONG decode reproduces the same bytes.  This
script asks the question the gate cannot, and answers it from structure that
exists independently of any disassembler.

THE MODEL BEING TESTED
    A record is  [flags:u8][len:u8][payload len-2] ,
    i.e. byte 1 of a record is the DISTANCE TO THE NEXT RECORD.
    Interleaved with the record chains are arrays of 32-bit little-endian
    POINTERS back into the same region, and one table of 13-byte ASCII names.

FIVE INDEPENDENT CHECKS, each stated so it CAN fail
  1. REFERENCE KIND.  Every reference to the region's labels, tree-wide, loads
     its ADDRESS (`.long X` inside a table, `ld xix, X`).  ZERO call/jump sites.
     This is signal #1 from the lane brief for "this is data".
  2. CHAIN CLOSURE.  Six record chains, each starting at an address named by
     the region's own top-level pointer table, land EXACTLY on the start of the
     next pointer table -- an address derived from the CONTENTS of that table,
     never from the chain.  A seventh chain runs 140 records / 1,376 bytes
     without one invalid length byte.
  3. POINTER RESOLUTION.  Pointers inside those tables resolve to record STARTS
     predicted by check 2.
  4. EXTERNAL CORROBORATION -- the strongest one, because it uses a source this
     model was not built from.  `v10/maincpu/kn5000_v10_program.s` carries 12
     `.set NAME, 0xf160xx` absolute addresses (`DrumDetailEdit_Entry_01..09`,
     `Data_Dispatch_Entry*`) written by an earlier analyst from the CONSUMING
     code.  All 12 must land on a predicted record start.
  5. ASCII.  A 168-byte table of 13-character effect names ("CELESTE 1",
     "ORGAN TREMOLO", "SOLO EFFECT 1") sits inside the span.  Plain text cannot
     occur inside a real instruction stream.

THE NULL (mandatory -- a criterion that cannot fail is not a criterion)
  Check 4's null is the density of record starts in the span: if the model
  predicts S starts among N bytes, a pointer chosen at random hits one with
  probability S/N.  Reported, with the joint probability for all 12.
  Check 2's null is measured directly: the same chain-closure test is run from
  RANDOM starts inside PROVEN CODE (a long contiguous run of instructions the
  assembler itself emitted), asking how often a length chain from there lands
  exactly on a given endpoint.

RUN (from the repo root; needs only original_ROMs/, no build):
    python3 scripts/analysis/lane_v10storage_record_stream_evidence.py
"""
import os
import random
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
SRC = os.path.join(REPO, "v10", "maincpu")
BASE = 0xE00000

LO, HI = 0xF15907, 0xF1612F           # the span under test
TOP_TABLE, TOP_N = 0xF158A7, 24       # FlashWrite_BlockHandler_Table

# Record chains and the pointer tables they must land on.  The chain STARTS are
# taken from TOP_TABLE's contents; the ENDS are the next pointer-table address,
# also derived from TOP_TABLE.  Neither is derived from the length bytes.
SEGMENTS = [(0xF15907, 0xF1593A), (0xF15952, 0xF1598F), (0xF159B3, 0xF159E0),
            (0xF159F4, 0xF15A1C), (0xF15A30, 0xF15A5A), (0xF15A6E, 0xF15A91),
            (0xF15BA9, 0xF16109)]
PTR_TABLES = [(0xF1593A, 6), (0xF1598F, 9), (0xF159E0, 5), (0xF15A1C, 5),
              (0xF15A5A, 5), (0xF15A91, 28)]
NAME_TABLE = (0xF15B01, 0xF15BA9)
TAIL = (0xF16109, 0xF1612F)           # framing NOT established -- see report

rom = open(ROM_PATH, "rb").read()


def u32(a):
    o = a - BASE
    return rom[o] | rom[o + 1] << 8 | rom[o + 2] << 16 | rom[o + 3] << 24


def chain(start, stop):
    """Record starts from `start`, following the length byte, until >= stop."""
    out, a = [], start
    while a < stop:
        n = rom[a - BASE + 1]
        if n < 2:
            return out, a, False
        out.append(a)
        a += n
    return out, a, a == stop


def check1_reference_kind():
    print("CHECK 1  reference kind of the span's labels")
    labels = ["FlashWrite_BlockHandler_Table", "FlashWrite_BlockData_Type0",
              "FlashWrite_BlockData_Type1", "FlashWrite_BlockData_Type2",
              "FlashWrite_BlockData_Type3", "FlashWrite_BlockData_Type4",
              "FlashWrite_BlockData_Type5", "FlashWrite_BlockData_Type6",
              "FlashWrite_BlockRef_Type3", "FlashWrite_BlockRef_Type4",
              "FlashWrite_BlockRef_Type5", "FlashWrite_BlockRef_Type6",
              "FlashRead_BlockHandler_Table", "FlashRead_BlockData_Field2",
              "FlashRead_BlockData_Field3", "FlashRead_BlockData_Field4",
              "FlashRead_BlockData_Field5", "FlashRead_BlockData_Field6"]
    branch = re.compile(r'^\s*(call|calr|jp|jr|jrl|djnz)\b')
    addr_taken = branch_taken = defined = 0
    for dp, _, fns in os.walk(SRC):
        for fn in fns:
            if not fn.endswith(".s"):
                continue
            for line in open(os.path.join(dp, fn), encoding="latin-1"):
                for lab in labels:
                    if not re.search(r'\b%s\b' % lab, line):
                        continue
                    if re.match(r'^%s:' % lab, line):
                        defined += 1
                    elif branch.match(line):
                        branch_taken += 1
                        print("    BRANCH:", line.rstrip()[:90])
                    else:
                        addr_taken += 1
    print(f"    {defined} definitions, {addr_taken} address-taken references, "
          f"{branch_taken} call/jump references")
    ok = branch_taken == 0 and addr_taken > 0
    print("    ->", "DATA signature (address-taken only)" if ok else "NOT conclusive")
    return ok


def check2_chain_closure():
    print("CHECK 2  record-length chains close exactly on the pointer tables")
    allok = True
    starts = set()
    for s, e in SEGMENTS:
        recs, landed, exact = chain(s, e)
        starts |= set(recs)
        print(f"    {s:06X} -> {landed:06X} after {len(recs):3d} records "
              f"(target {e:06X})  {'EXACT' if exact else '*** MISS ***'}")
        allok &= exact
    return allok, starts


def check3_pointer_resolution(starts):
    """Only IN-SPAN pointers are testable: the last table points mostly at
    F1532C..F15386, outside the span, where this model makes no prediction.
    Counting those as misses would understate the model; counting them as hits
    would be cheating.  They are reported separately and excluded."""
    print("CHECK 3  pointers inside those tables land on predicted record starts")
    tstarts = {a for a, _ in PTR_TABLES}
    hit = tot = out = 0
    for a, n in PTR_TABLES:
        vals = [u32(a + 4 * k) for k in range(n)]
        ins = [v for v in vals if LO <= v < HI]
        # A pointer resolves if it names a record start OR a pointer table:
        # the last table is a table OF TABLES (second level), so demanding a
        # record start there would be a category error, not a model failure.
        h = sum(1 for v in ins if v in starts or v in tstarts)
        hit += h
        tot += len(ins)
        out += n - len(ins)
        print(f"    table {a:06X} x{n:2d}: {h}/{len(ins)} in-span"
              f"{'' if n == len(ins) else f'  ({n - len(ins)} point outside the span, untestable)'}")
    print(f"    total {hit}/{tot} in-span, {out} out-of-span excluded")
    return hit, tot


def check4_external(starts):
    print("CHECK 4  external `.set` addresses (written from the CONSUMING code)")
    top = os.path.join(SRC, "kn5000_v10_program.s")
    ext = []
    for line in open(top, encoding="latin-1"):
        m = re.match(r'\s*\.set\s+(\w+),\s*(0x[0-9a-fA-F]+)\s*$', line)
        if m and LO <= int(m.group(2), 16) < HI:
            ext.append((m.group(1), int(m.group(2), 16)))
    hit = [n for n, a in ext if a in starts]
    for n, a in ext:
        print(f"    {a:06X} {n:<28s} {'HIT' if a in starts else 'MISS'}")
    print(f"    {len(hit)}/{len(ext)} land on a predicted record start")
    return len(hit), len(ext)


def check5_ascii():
    print("CHECK 5  ASCII name table inside the span")
    a, b = NAME_TABLE
    txt = rom[a - BASE:b - BASE].decode("latin-1")
    printable = sum(1 for c in txt if 0x20 <= ord(c) < 0x7F)
    print(f"    {a:06X}..{b:06X} ({b - a} B): {printable}/{b - a} printable")
    for k in range(0, 156, 13):
        print(f"      {a + k:06X}  {txt[k:k + 13]!r}")
    print(f"      {a + 156:06X}  {txt[156:162]!r}  {txt[162:168]!r}")
    return printable == b - a


def nulls(starts, ext_hit, ext_tot):
    print("NULL")
    n = HI - LO
    dens = len(starts) / n
    print(f"    record-start density in the span: {len(starts)}/{n} = {dens:.4f}")
    print(f"    P(all {ext_tot} external addresses hit by chance) = "
          f"{dens ** ext_tot:.3e}")

    # Null for check 2: run the same closure test from random starts inside a
    # long, contiguous run of PROVEN code (bytes the assembler itself emitted as
    # instructions).  Use a fixed, uncontroversial code window: the routine at
    # UIState_KeyScan_Dispatch, which unidasm and the source agree on.
    random.seed(20260902)
    code_lo, code_hi = 0xF98697, 0xF98757
    trials = exact = 0
    for _ in range(20000):
        s = random.randrange(code_lo, code_hi - 8)
        # match the mean span length of the six real chains
        span = 0x33
        _, landed, ok = chain(s, s + span)
        trials += 1
        exact += 1 if ok else 0
    print(f"    chain-closure from random starts in PROVEN CODE: "
          f"{exact}/{trials} = {exact / trials:.3f} land exactly")
    print("    (the six real chains land exactly 6/6)")


def main():
    print(f"span under test: {LO:06X}..{HI:06X} ({HI - LO} B), "
          f"v10/maincpu/storage/flash_floppy_handlers.s")
    print()
    c1 = check1_reference_kind()
    print()
    c2, starts = check2_chain_closure()
    print()
    h3, t3 = check3_pointer_resolution(starts)
    print()
    h4, t4 = check4_external(starts)
    print()
    c5 = check5_ascii()
    print()
    nulls(starts, h4, t4)
    print()
    print(f"TAIL {TAIL[0]:06X}..{TAIL[1]:06X} ({TAIL[1] - TAIL[0]} B): the "
          f"length byte is 0 at {TAIL[0]:06X}; framing NOT established, "
          f"emitted as .byte with that reason stated in the source.")
    print()
    verdict = c1 and c2 and c5 and h4 == t4
    print("VERDICT:", "DATA -- a [flags][len] record stream, not code"
          if verdict else "NOT ESTABLISHED")
    return 0 if verdict else 1


if __name__ == "__main__":
    sys.exit(main())
