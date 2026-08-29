"""REVIEW PROBE (disposable): recompute the borrowed/sibling byte claims.

  * IndexedTable_GetPtr: "prom_a 0xFB77D8..0xFB77F2 == prom_b 0xF55321..0xF5533B,
    the same 27 bytes with 0 differing"  (the ONLY borrowed name in this lane)
  * Queue2C00_AppendRegs: "77 bytes against this routine's 34"
"""
A = open("/home/fsanches/compartilhado/wsa1-roms-disasm/rebuilt_ROMs/wsa1_prom_a.llvm.rom", "rb").read()
Bm = open("/home/fsanches/compartilhado/wsa1-roms-disasm/rebuilt_ROMs/wsa1_prom_b.llvm.rom", "rb").read()
a = lambda x: A[x - 0xF80000]
b = lambda x: Bm[x - 0xF00000]

n = 27
sa = bytes(a(0xFB77D8 + i) for i in range(n))
sb = bytes(b(0xF55321 + i) for i in range(n))
diff = sum(1 for i in range(n) if sa[i] != sb[i])
print("IndexedTable_GetPtr: length %d, differing %d  -> claim (27, 0) %s"
      % (n, diff, "HOLDS" if (n, diff) == (27, 0) else "*** FAILS ***"))
print("  last byte of each: 0x%02X / 0x%02X (a `ret` is 0x0E: %s)"
      % (sa[-1], sb[-1], sa[-1] == sb[-1] == 0x0E))
# do they extend further?
print("  byte 27 of each (would the run continue?): 0x%02X / 0x%02X  equal=%s"
      % (a(0xFB77D8 + 27), b(0xF55321 + 27), a(0xFB77D8 + 27) == b(0xF55321 + 27)))

def rlen(fn, start, limit=200):
    """bytes from start up to and including the first 0x0E (`ret`)."""
    for i in range(limit):
        if fn(start + i) == 0x0E:
            return i + 1
    return None

print("\nQueue2C00: prom_a 0xF86A81 -> %s bytes; prom_b 0xF55231 -> %s bytes"
      "   (claim 34 / 77)" % (rlen(a, 0xF86A81), rlen(b, 0xF55231)))
