#!/usr/bin/env python3
"""Two specific claims in b1's report, checked against ROM bytes:
  (a) 3,407 of the 4,275 STRONG bytes are ONE span at 0xE1344E, and its bytes
      are a 4-byte pointer table (4e e9 e0 00, a0 e9 e0 00 ...).
  (b) the four `jp 0x?00ed` namers are at 0xED1BAB..0xED1BB7 and are themselves
      a misread pointer table.
"""
import os, sys
sys.path.insert(0, os.path.expanduser("~/compartilhado/kn5000-roms-disasm/notes"))
import reachability_kn5000 as R
data, base = R.rom_bytes(), R.TARGET["base"]
r = R.gather()

# (a)
ps = r["per_span_strong"]
spans = {s["i"]: s for s in r["spans"]}
top = sorted(ps.items(), key=lambda kv: -kv[1])[:3]
print("top .incbin spans by STRONG reachable bytes  (total STRONG = %d)" % sum(ps.values()))
for i, n in top:
    s = spans[i]
    print("  span %-5d 0x%06X-0x%06X  %6d STRONG B   %s:%d" % (i, s["lo"], s["hi"], n, s["src"], s["line"]))
lo = spans[top[0][0]]["lo"]
print("  bytes at 0x%06X: %s" % (lo, " ".join("%02x" % b for b in data[lo-base:lo-base+24])))
words = [int.from_bytes(data[lo-base+k:lo-base+k+4], "little") for k in range(0, 24, 4)]
print("  as LE 32-bit words: %s" % " ".join("0x%08X" % w for w in words))
print("  in-image (0xE00000..0xFFFFFF)? %s" % [base <= w < base+len(data) for w in words])

# (b)
print()
print("the namers")
for a in (0xED1BAB, 0xED1BAF, 0xED1BB3, 0xED1BB7):
    b = data[a-base:a-base+4]
    t = b[1] | b[2] << 8 | b[3] << 16
    print("  0x%06X: %s   opcode 0x%02X -> target 0x%06X" % (a, " ".join("%02x" % x for x in b), b[0], t))
print("  16 bytes at 0xED1BAB: %s" % " ".join("%02x" % x for x in data[0xED1BAB-base:0xED1BAB-base+16]))
