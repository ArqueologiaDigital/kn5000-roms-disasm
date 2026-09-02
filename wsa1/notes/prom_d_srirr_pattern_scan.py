#!/usr/bin/env python3
"""prom_d_srirr_pattern_scan.py -- is prom_d's "no code" really no code?

QUESTION ANSWERED
  prom_d's 100% claim rests on flattening the image through llvm-mc and
  finding ZERO instruction encodings, read as confirming its DATA-ONLY
  status. But a DECODER GAP and a genuine absence of code produce the
  SAME symptom -- nothing decodes. This scans the raw image for byte
  patterns matching the SriRR family, which the disassembler cannot
  decode at all (decodeSRIPrefix ModeType==3, mode byte 0x07 or 0x03,
  "not yet supported" -> Fail) even though the ASSEMBLER encodes it.

  A hit is NOT proof of code. The 5-byte shape can occur by chance in
  data, and this image is 37% erased flash plus large typed tables. A hit
  means "llvm-mc's silence here is not evidence" and the region needs a
  real look. NO hits, across the whole image, is the stronger result: it
  would mean the decoder gap cannot explain prom_d's zero encodings, and
  the DATA-ONLY reading survives a real attempt to break it.

RUN
  python3 wsa1/notes/prom_d_srirr_pattern_scan.py

⚠ Compute the NULL before believing a hit count: run the same scan over a
  region known to be pure erased flash and over one known to be a typed
  table, and report those rates beside the finding. A pattern count with
  no control is not evidence in this tree.
"""
"""Scan wsa1_prom_d.bin for byte patterns matching the SriRR family the
TLCS900 disassembler cannot decode (decodeSRIPrefix ModeType==3 / mode byte
0x07 or 0x03, "not yet supported" -> Fail).

Encoder-confirmed shape (TLCS900MCCodeEmitter.cpp SriRRReg/SriRRUnary/SriRRImm/
SriRRQReg -- mode byte 0x07; SriRR8Reg -- mode byte 0x03):

    [prefix in {0xC3,0xD3,0xE3,0xF3}, mode in {0x07,0x03}, base, idx, subopc+reg]

where base/idx bytes are of the form 0xE0 + n*4 (+0..3) for n in 0..7, i.e.
base in {0xE0,0xE4,0xE8,0xEC,0xF0,0xF4,0xF8,0xFC} (mode 0x07, 16-bit index) or
base in that set / idx with the 8-bit low/high adjustment (mode 0x03).
"""
import sys

PATH = sys.argv[1] if len(sys.argv) > 1 else "wsa1/original_ROMs/wsa1_prom_d.bin"
data = open(PATH, "rb").read()

PREFIXES = {0xC3, 0xD3, 0xE3, 0xF3}
MODES = {0x07, 0x03}
BASESET = {0xE0, 0xE4, 0xE8, 0xEC, 0xF0, 0xF4, 0xF8, 0xFC}

hits = []
n = len(data)
for i in range(n - 4):
    if data[i] in PREFIXES and data[i+1] in MODES:
        base = data[i+2]
        idx = data[i+3]
        # base must always be exactly one of the 8 canonical register slots
        if base not in BASESET:
            continue
        # idx: mode 0x07 -> exact BASESET; mode 0x03 -> BASESET +0..3 (byte addressing)
        if data[i+1] == 0x07:
            idx_ok = idx in BASESET
        else:
            idx_ok = (idx - 0xE0) % 4 in (0,1) and 0xE0 <= idx <= 0xFF and ((idx-0xE0)//4) <= 7
        if not idx_ok:
            continue
        hits.append(i)

print(f"scanned {n} bytes, found {len(hits)} candidate SriRR-family sites")
for i in hits[:100]:
    window = data[max(0,i-2):i+8]
    print(f"  0x{i:06X}: " + " ".join(f"{b:02X}" for b in window))
if len(hits) > 100:
    print(f"  ... and {len(hits)-100} more")
