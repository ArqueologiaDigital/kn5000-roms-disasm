#!/usr/bin/env python3
"""prom_d_srirr_falsification.py -- attack prom_d's "zero instruction
encodings" claim at the ENCODING level, independent of the buggy decoder.

QUESTION ANSWERED
  prom_d's 100%-disassembled claim partly rests on "flattening the whole
  image through `llvm-mc -show-encoding` found ZERO instruction encodings".
  That was read as proof prom_d contains no code. It is not safe: the
  disassembler (llvm/lib/Target/TLCS900/Disassembler/TLCS900Disassembler.cpp)
  has whole blind families that ALWAYS return Fail regardless of what bytes
  are in front of them --

    * decodeSRIPrefix() explicitly refuses ModeType 2 and 3 ("not yet
      supported"), which is every register-indexed SriRR* form (st_rrb,
      ld_rr*, lda_rr, jp/call (rr), ...);
    * decodeERPPrefix() is a literal stub that always returns Fail.

  A decoder gap and a genuine absence of code produce the IDENTICAL symptom
  (nothing decodes), so "zero encodings" cannot distinguish them. This script
  does not trust the disassembler at all: it searches prom_d's raw bytes for
  the EXACT byte shapes the ENCODER (TLCS900MCCodeEmitter.cpp) is known to
  produce for the SriRR family, which is a positive, decoder-independent
  test. As a control, it runs the identical search over prom_a/b/c, which are
  confirmed CODE images, to prove the method actually finds real instances
  where they exist rather than just failing to fire everywhere.

  The ERP family (decodeERPPrefix) is NOT attacked the same way: its
  encoding is [prefix C7/D7/E7, bank_idx (ANY byte), subopc(+reg/+imm)], and
  bank_idx has no structural constraint an encoder-shape scan can use, so a
  byte-pattern search over it has no useful discriminating power in either
  direction. That is reported as an explicit LIMIT of this check, not a
  finding.

METHOD (SriRR family)
  Encoder-confirmed shape, both variants (TLCS900MCCodeEmitter.cpp,
  SriRRReg/SriRRUnary/SriRRImm/SriRRQReg use mode byte 0x07; SriRR8Reg uses
  mode byte 0x03):

      [prefix in {0xC3,0xD3,0xE3,0xF3}, mode in {0x07,0x03}, base, idx, tail]

  base/idx are always of the register-file-address form 0xE0 + n*4 (+0..3)
  for a bank register n in 0..7 -- i.e. one of
  {0xE0,0xE4,0xE8,0xEC,0xF0,0xF4,0xF8,0xFC} for the 16-bit index mode (0x07),
  or that set plus a +0/+1 byte-select for the 8-bit index mode (0x03).  A
  match requires ALL FOUR of prefix, mode, base-shape and idx-shape to align;
  a plain "prefix followed by mode byte" count is reported too, to show how
  much of the raw hit count that stronger constraint is removing.

RESULT, 2026-09-02 (PROMDVERIFY lane)
  prom_d (524,288 B, full image):    0 full 5-byte matches.
  prom_d, prefix+mode byte only (no base/idx check): 6 near-misses, and all
    six inspected by hand are table entries (small monotonically-increasing
    16/32-bit fields) whose "base"/"idx" bytes are plainly not register-file
    addresses -- e.g. 0x0468... "00 E5 00 0C C3 03 00 E5 00 00 C4 03 00 E6",
    where the byte after the mode byte is 0x00, not in the 0xE0+n*4 set.
  prom_a (524,288 B, confirmed CODE): 599 full matches.
  prom_b (524,288 B, confirmed CODE): 1,261 full matches.
  prom_c (524,288 B, confirmed CODE): 125 full matches.

  So the method is discriminating -- it fires 125-1,261 times on ROMs known
  to contain code and 0 times on prom_d -- and prom_d's "zero instruction
  encodings" finding SURVIVES this specific, previously-unconsidered attack.
  This is a stronger result than the original claim because it no longer
  depends on the very decoder that is known to have this blind spot.

  ⚠ This does NOT clear the ERP family (decodeERPPrefix) for prom_d or
  anywhere else -- see the LIMIT above. Nor does it prove no OTHER decoder
  gap exists; it tests the one gap this lane was pointed at.

RUN
  python3 wsa1/notes/sound/prom_d_srirr_falsification.py
  python3 wsa1/notes/sound/prom_d_srirr_falsification.py --selftest

PROVENANCE
  Written by the PROMDVERIFY falsification lane, 2026-09-02, against LLVM
  tlcs900_backend@ad8129f59880.
"""
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")

IMAGES = [
    ("prom_d", os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin")),
    ("prom_a", os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")),
    ("prom_b", os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")),
    ("prom_c", os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")),
]

PREFIXES = {0xC3, 0xD3, 0xE3, 0xF3}
MODES = {0x07, 0x03}
BASESET = {0xE0, 0xE4, 0xE8, 0xEC, 0xF0, 0xF4, 0xF8, 0xFC}


def find_srirr_hits(data):
    """Full 5-byte encoder-shape matches: prefix, mode, base, idx all align."""
    hits = []
    n = len(data)
    for i in range(n - 4):
        if data[i] not in PREFIXES or data[i + 1] not in MODES:
            continue
        base, idx = data[i + 2], data[i + 3]
        if base not in BASESET:
            continue
        if data[i + 1] == 0x07:
            idx_ok = idx in BASESET
        else:  # 0x03: 8-bit index, +0/+1 byte-select allowed
            idx_ok = 0xE0 <= idx <= 0xFF and (idx - 0xE0) % 4 in (0, 1)
        if idx_ok:
            hits.append(i)
    return hits


def count_near_misses(data):
    """prefix immediately followed by a qualifying mode byte, base/idx unchecked."""
    return sum(
        1
        for i in range(len(data) - 1)
        if data[i] in PREFIXES and data[i + 1] in MODES
    )


def verify_erased_tail(data):
    """Re-derive the single largest 0xFF run and what follows it, independent
    of prom_d_debt_probe.py -- a second, from-scratch measurement of the same
    claim ("one run at 0x050B09-0x07FFF0, 16 bytes of content follow")."""
    n = len(data)
    best_start = best_len = 0
    i = 0
    while i < n:
        if data[i] == 0xFF:
            j = i
            while j < n and data[j] == 0xFF:
                j += 1
            if j - i > best_len:
                best_len, best_start = j - i, i
            i = j
        else:
            i += 1
    tail = data[best_start + best_len:]
    return best_start, best_len, tail


def main():
    print("=== prom_d SriRR-family encoder-shape scan (decoder-independent) ===\n")
    results = {}
    for name, path in IMAGES:
        data = open(path, "rb").read()
        hits = find_srirr_hits(data)
        near = count_near_misses(data)
        results[name] = (len(data), len(hits), near)
        print(f"{name:8s} {len(data):>8,} B  full-match hits: {len(hits):>5,}"
              f"   (prefix+mode near-misses: {near:>5,})")

    print()
    d_hits = results["prom_d"][1]
    code_hits = [results[n][1] for n in ("prom_a", "prom_b", "prom_c")]
    if d_hits == 0 and all(h > 0 for h in code_hits):
        print("VERDICT: prom_d = 0 hits, all three confirmed-code images > 0 "
              "hits (125-1,261).")
        print("The scan is discriminating and prom_d's 'zero instruction "
              "encodings' for the")
        print("SriRR family SURVIVES this attack. ERP family is NOT covered "
              "-- see docstring.")
    else:
        print("VERDICT: UNEXPECTED -- prom_d has SriRR-shaped bytes, or a "
              "control image does not.")
        print("This would be evidence AGAINST prom_d's 100% claim. Investigate "
              "before reporting either way.")

    print()
    print("=== erased-tail re-verification (independent of prom_d_debt_probe.py) ===")
    d_data = open(IMAGES[0][1], "rb").read()
    start, length, tail = verify_erased_tail(d_data)
    print(f"largest 0xFF run: file 0x{start:06X}, length {length:,} B, "
          f"ends at 0x{start+length:06X}")
    print(f"bytes immediately after it ({len(tail)} B): {tail!r}")


def selftest():
    """Regression pins for the numbers in the RESULT section above. Any of
    these going red means the claim they support needs re-checking, not the
    test relaxing."""
    data = {name: open(path, "rb").read() for name, path in IMAGES}
    assert len(find_srirr_hits(data["prom_d"])) == 0, "prom_d must have 0 SriRR hits"
    assert len(find_srirr_hits(data["prom_a"])) == 599
    assert len(find_srirr_hits(data["prom_b"])) == 1261
    assert len(find_srirr_hits(data["prom_c"])) == 125
    assert count_near_misses(data["prom_d"]) == 6

    start, length, tail = verify_erased_tail(data["prom_d"])
    assert (start, length) == (0x050B09, 193767), (start, length)
    assert tail == b"wsad_54.ssf" + b"\x00" * 5, tail
    print("selftest OK: prom_d 0/599/1261/125 SriRR hits (prom_d/a/b/c), "
          "6 near-misses, erased tail confirmed at 0x050B09 len 193767 "
          "followed by 'wsad_54.ssf' + 5 NUL.")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        main()
