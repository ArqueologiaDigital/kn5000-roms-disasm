#!/usr/bin/env python3
"""POSITIVE CONTROL for lane b1's negative result "KN5000 has no routine directory".

b1's scan (notes/reachability_kn5000.py, S2) is lifted verbatim here and pointed at
the WSA1 images, where a 1,910-slot directory is KNOWN to exist. If the copied scan
finds it there, the KN5000 zero is a measurement; if it does not, the criterion
cannot fail and the negative is unpowered.
"""
import os, sys

def scan(data, base, end):
    """VERBATIM from reachability_kn5000.py S2 (lines 471-488)."""
    runs, cur = [], None
    for o in range(0, len(data) - 4, 4):
        t = data[o + 1] | data[o + 2] << 8 | data[o + 3] << 16
        if data[o] == 0x1B and base <= t < end:
            cur = [o, o] if cur is None else [cur[0], o]
        else:
            if cur is not None:
                runs.append(tuple(cur))
            cur = None
    if cur:
        runs.append(tuple(cur))
    ndir, slots, biggest = 0, set(), (0, None)
    for a, b in runs:
        n = (b - a) // 4 + 1
        if n < 8:
            continue
        ndir += 1
        if n > biggest[0]:
            biggest = (n, base + a)
        for o in range(a, b + 4, 4):
            slots.add(data[o + 1] | data[o + 2] << 8 | data[o + 3] << 16)
    return ndir, len(slots), biggest

W = os.path.expanduser("~/compartilhado/wsa1-roms-disasm/original_ROMs")
K = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")

# WSA1: prom_b is 0xF00000 low, prom_a 0xF80000 high, prom_c 0xF80000 subcpu.
# The maincpu is prom_b+prom_a contiguous 0xF00000-0xFFFFFF (HANDOFF "Address map").
pb = open(os.path.join(W, "wsa1_prom_b.ic13"), "rb").read()
pa = open(os.path.join(W, "wsa1_prom_a.ic12"), "rb").read()
pc = open(os.path.join(W, "wsa1_prom_c.ic28"), "rb").read()

print("POSITIVE CONTROLS -- the scan pointed where a directory is KNOWN to be")
for tag, data, base in (("wsa1 maincpu (prom_b+prom_a)", pb + pa, 0xF00000),
                        ("wsa1 prom_b alone", pb, 0xF00000),
                        ("wsa1 prom_c (subcpu)", pc, 0xF80000)):
    n, s, big = scan(data, base, base + len(data))
    print("  %-30s runs>=8 %4d   slot targets %5d   biggest %d slots at 0x%06X"
          % (tag, n, s, big[0], big[1] or 0))

print()
print("THE NEGATIVE -- same scan, KN5000 v10 maincpu")
kv = open(os.path.join(K, "original_ROMs/kn5000_v10_program.bin"), "rb").read() \
     if os.path.exists(os.path.join(K, "original_ROMs/kn5000_v10_program.bin")) else None
if kv is None:
    # find it the way b1's TARGET does
    sys.path.insert(0, os.path.join(K, "notes"))
    import reachability_kn5000 as R
    kv = R.rom_bytes()
n, s, big = scan(kv, 0xE00000, 0xE00000 + len(kv))
print("  %-30s runs>=8 %4d   slot targets %5d   biggest %d slots at 0x%06X"
      % ("kn5000 v10 maincpu", n, s, big[0], big[1] or 0))

print()
print("ELIGIBILITY -- how many 4-byte-aligned 0x1B-with-in-range-target slots exist AT ALL")
for tag, data, base in (("wsa1 maincpu", pb + pa, 0xF00000),
                        ("wsa1 prom_c", pc, 0xF80000)):
    c = sum(1 for o in range(0, len(data) - 4, 4)
            if data[o] == 0x1B and base <= (data[o+1] | data[o+2] << 8 | data[o+3] << 16) < base + len(data))
    print("  %-30s %d candidate slots" % (tag, c))
c = sum(1 for o in range(0, len(kv) - 4, 4)
        if kv[o] == 0x1B and 0xE00000 <= (kv[o+1] | kv[o+2] << 8 | kv[o+3] << 16) < 0xE00000 + len(kv))
print("  %-30s %d candidate slots" % ("kn5000 v10 maincpu", c))
