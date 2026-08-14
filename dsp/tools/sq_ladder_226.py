#!/usr/bin/env python3
"""Fixed-point arithmetic of the kernel ladder, and its dependence on the
cursor base.  Everything here is computed FROM DISK -- the C-RAM dump in
data/I_s2_224.log.gz and the §S2 term census in the same log.  No run."""
import re, sys

ACC_SHIFT = 16
P_SHIFT   = 6
FS_DATUM  = 1 << 23                 # datum full scale
FS_ACC    = FS_DATUM << ACC_SHIFT   # 2**39 = 549 755 813 888

def sext24(v):  return v - (1 << 24) if v & 0x800000 else v

# --- the C-RAM image, transcribed from I_s2_224.log lines 2140-2151 ---------
CRAM = {}
rows = {
0x00:"000072 7FFFFF 0000F0 000000 0000F0 000000 2CCCCC 2CCCCC 000018 1364D9 1364D9 E00000 E00000 FFFF10 000000 FFFF10",
0x10:"000000 2CCCCC 2CCCCC 200000 000000 000000 000000 000000 000000 000000 000000 000000 000000 000000 000000 000000",
0x50:"008000 008400 008800 008C00 009000 009400 009800 009C00 00A000 00A400 00A800 00AC00 00B000 00B400 00B800 00BC00",
0x60:"00C000 00C400 00C800 00CC00 00D000 00D400 00D800 00DC00 00E000 00E400 00E800 00EC00 00F000 00F400 00F800 00FC00",
0x70:"000000 0004BE 00097C 000E3A 0012F8 0017B6 001C74 002132 0025F0 002AAE 002F6C 00342A 0038E8 003DA6 004264 004722",
0x80:"004BE0 00509E 00555C 005A1A 005ED8 006396 006854 006D12 0071D0 00768E 007B4C 007FFF 000000 000000 000000 000000",
0x90:"4D9364 400000 400000 3B9885 2DF3A0 C62251 400000 E8F713 600000 50A3D7 4F5C28 4CCCCC 400000 400000 23001E 35D1B6",
0xA0:"E27C3B 5D70A3 5C28F5 599999 4CCCCC 400000 23001E 35D1B6 E27C3B 2DD2F1 400000 3F1A9F 26C9B2 399999 399999 399999",
0xB0:"400000 291687 26C9B2 399999 399999 000000 000000 000000 000000 000000 000000 000000 000000 000000 000000 000000",
}
for base, s in rows.items():
    for i, t in enumerate(s.split()):
        CRAM[base + i] = int(t, 16)
def cram(a): return CRAM.get(a & 0xff, 0)

print("=== SELF-TEST against §S2's own printed terms (I_s2_224.log:2721-2723) ===")
def chk(n, got, want):
    print("   %-48s got %-14d want %-14d %s" % (n, got, want, "PASS" if got==want else "*** FAIL ***"))
    return got==want
ok = True
b9B, b9C, b9D = sext24(cram(0x9B)), sext24(cram(0x9C)), sext24(cram(0x9D))
ok &= chk("iw30 bus  = C-RAM[9B] << 16", b9B << ACC_SHIFT, 329853435904)
ok &= chk("iw30 P    = C-RAM[9B]^2 >> 6", (b9B*b9B) >> P_SHIFT, 395824060170)
ok &= chk("iw33 bus  = C-RAM[9D] << 16", b9D << ACC_SHIFT, 274877906944)
ok &= chk("iw33 P    = C-RAM[9C]^2 >> 6", (b9C*b9C) >> P_SHIFT, 274877906944)
ok &= chk("iw33 result carried+bus+P",
          ((b9B*b9B)>>P_SHIFT) + (b9D<<ACC_SHIFT) + ((b9C*b9C)>>P_SHIFT), 945579874058)
lfo = sext24(cram(0x00))
ok &= chk("iw89 acc  = C-RAM[00] << 16   (trace n=55)", lfo << ACC_SHIFT, 7471104)
ok &= chk("iw89 P    = C-RAM[00]^2 >> 6  (trace n=55)", (lfo*lfo) >> P_SHIFT, 203)
ok &= chk("iw90 acc  = iw89 + (L<<16) + P, L=1006784 (n=56)",
          (lfo << ACC_SHIFT) + (1006784 << ACC_SHIFT) + ((lfo*lfo) >> P_SHIFT), 65988067531)
print("   SELF-TEST: %s\n" % ("PASS" if ok else "FAIL"))
if not ok: sys.exit(1)

# ===========================================================================
print("=== ITEM 4.  IS >>6 THE RIGHT SHIFT FOR A SQUARE? ===")
print("  datum is Q0.23 (full scale 2^23); the accumulator holds datum << ACC_SHIFT=%d," % ACC_SHIFT)
print("  so accumulator full scale = 2^%d = %d." % (23+ACC_SHIFT, FS_ACC))
print("  coef x L is a Q46 product = a*b*2^46.  To land at a*b*2^%d the shift must be" % (23+ACC_SHIFT))
print("     P_SHIFT = 46 - (23 + ACC_SHIFT) = %d.   THE CODE USES %d." % (46-23-ACC_SHIFT, P_SHIFT))
print("  => every product in this device is EXACTLY 2x its Q-consistent value.\n")

def fs(x): return x / FS_ACC
p30 = (b9B*b9B) >> P_SHIFT
p33 = (b9C*b9C) >> P_SHIFT
print("  the ladder as shipped:")
for nm, c, bus, p in [("iw30", 0, b9B<<ACC_SHIFT, 0),
                      ("iw32", 0, 0, p30),
                      ("iw33", p30, b9D<<ACC_SHIFT, p33)]:
    print("    %s  carried %14d  bus %14d  P %14d  = %14d  %.3f FS"
          % (nm, c, bus, p, c+bus+p, fs(c+bus+p)))
h30, h33 = p30 >> 1, p33 >> 1
print("    with P_SHIFT = 7 (Q-consistent): iw33 = %d + %d + %d = %d  %.3f FS  <= STILL CLIPS"
      % (h30, b9D<<ACC_SHIFT, h33, h30+(b9D<<ACC_SHIFT)+h33, fs(h30+(b9D<<ACC_SHIFT)+h33)))
print("    (independently reproduces §224 §7.5's '1.110 x FS'.)\n")

# ===========================================================================
print("=== ITEM 5.  THE LADDER IS A FUNCTION OF THE CURSOR BASE ===")
print("  iw30/32/33 consume C-RAM[c], [c+1], [c+2] where c is the cursor at iw30.")
print("  Shipped: c = 0x9B, inherited from the PREVIOUS frame's unit-1 CALL rebase")
print("  (upd6383.cpp:5867  m_cursor = unit1 ? 0x90 : 0x00, mask bit 38, default SET).")
print("  kernel.dsm annotates the same three words C-RAM[0x0B]/[0x0C]/[0x0D].\n")
print("   base  C[c]    C[c+1]  C[c+2]   iw30 FS   iw32 FS   iw33 FS    clips?")
for c in (0x9B, 0x0B):
    a, b, d = sext24(cram(c)), sext24(cram(c+1)), sext24(cram(c+2))
    v30 = a << ACC_SHIFT
    v32 = (a*a) >> P_SHIFT
    v33 = v32 + (d << ACC_SHIFT) + ((b*b) >> P_SHIFT)
    print("   0x%02X  %06X  %06X  %06X   %+8.3f  %+8.3f  %+8.3f    %s"
          % (c, cram(c), cram(c+1), cram(c+2), fs(v30), fs(v32), fs(v33),
             "YES" if abs(v33) > FS_ACC else "no"))

print("\n  NULL: sweep every base 0x00..0xFF that has any non-zero coefficient.")
clip, nz = [], []
for c in range(0x100):
    a, b, d = sext24(cram(c)), sext24(cram(c+1)), sext24(cram(c+2))
    if a == 0 and b == 0 and d == 0: continue
    nz.append(c)
    v33 = ((a*a) >> P_SHIFT) + (d << ACC_SHIFT) + ((b*b) >> P_SHIFT)
    if abs(v33) > FS_ACC: clip.append(c)
print("   bases with any non-zero coefficient  : %d" % len(nz))
print("   ...of which the ladder CLIPS at iw33 : %d  (%.1f %%)  <-- THE NULL"
      % (len(clip), 100*len(clip)/len(nz)))
print("   clipping bases: %s" % " ".join("%02X" % c for c in clip))

# ===========================================================================
print("\n=== ITEM 3.  IS THE C-RAM BANK MIS-SCALED?  THE ROUND-DECIMAL TEST ===")
def roundness(scale, cells):
    hits = 0
    for a in cells:
        v = sext24(cram(a))
        if v == 0: continue
        x = v / (1 << 23) * scale
        if abs(x) <= 1.0 and abs(x*100 - round(x*100)) < 2e-4:
            hits += 1
    return hits
bank = list(range(0x90, 0xB5))
tot = sum(1 for a in bank if sext24(cram(a)) != 0)
for name, sc in (("x0.5 (if the host decode were 2x too big)", 0.5),
                 ("AS SHIPPED (Q23, raw cmd-0x02 bytes)   ", 1.0),
                 ("x2   (if the host decode were 2x small) ", 2.0)):
    print("   %-42s round-2dp cells: %2d of %d" % (name, roundness(sc, bank), tot))
print("   the bank, as Q23 decimals:")
ln = ["%02X=%+.6f" % (a, sext24(cram(a))/(1<<23)) for a in bank]
for i in range(0, len(ln), 6):
    print("     " + "  ".join(ln[i:i+6]))
print("\n   ANCHORS IN THE SAME MEMORY, SAME cmd-0x02 PATH, SAME (no) SCALING:")
print("     C-RAM[0x00] = %06X = %d  (CHORUS LFO increment; lfo_ramp.py derives 114 from ROM)"
      % (cram(0x00), cram(0x00)))
print("     C-RAM[0x01] = %06X = %d  (= 2^23-1, the wrap constant)" % (cram(0x01), cram(0x01)))
