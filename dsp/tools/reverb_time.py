#!/usr/bin/env python3
"""REVERB TIME -> feedback gain: the KN5000's own law, read out of the Sub CPU.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311), 2026-07-29.  No hardware.

The reverb ladder's decay gain was never a missing number: the firmware computes
it, and the ROM ships the answer twice -- once as a static C-RAM block and once
as the law that recomputes it whenever REVERB TIME moves.

    UI slot 0 of every reverb = "REVERB TIME (s)"   (paramlist.md, captured live)
      -> level-2 opcode 0x75, one 24-bit literal K24 per preset
      -> scaler  0x039D98  (5 piecewise ranges)     -> writer 0x0387E6 (tag 0x26)
      -> C-RAM cell 0x97   (T2[0x75] == [0x97], identical in all 12 reverbs)

    T(p)  = 0.02p+0.1 (p<=15) | 0.05(p-16)+0.45 (<=23) | 0.1(p-24)+0.9 (<=55)
          | 0.2(p-56)+4.2 (<=75) | p-67                      -- seconds
    K     = K24 / 2^23
    cell  = (int) ( 10^(-4.816 * K / T) / 2 * 2^23 )         -- Q0.23 as shipped
    g     = 2 * cell/2^23 = 10^(-4.816 * K / T)              -- the gain itself

Every constant above is an IEEE-754 literal at 0x012E07..0x012F03 in
kn5000_subprogram_v142.rom; the FP ABI is the one notes/kn5000-dsp-biquad-coeffs.md
section 2.1 decoded (0x03E290 dmul, 0x03E10E dadd, 0x03D3A4 ddiv, 0x03D3D4 fdiv,
0x03D533 pow, 0x03DCF2/0x03DD6C float<->double, 0x03E2C0 fmul, 0x03D44C f->int).

Run:  python3 dsp/tools/reverb_time.py [--rom SUB] [--main MAIN]
"""
import argparse, math, os, sys

A_CONST = 4.816          # 0x012E27/0x012E77/0x012EA3/0x012ECF/0x012EEB, all -4.816
FS = 44100.0
T_PARAM = 0x0001EF0C
T_LVL2_DEFAULTS = 0x0001F09C
T_LVL2_DESTS = 0x0001F22C
REVERBS = list(range(16, 28))


def T_of(p):
    if p <= 15: return 0.02 * p + 0.1
    if p <= 23: return 0.05 * (p - 16) + 0.45
    if p <= 55: return 0.1 * (p - 24) + 0.9
    if p <= 75: return 0.2 * (p - 56) + 4.2
    return float(p - 67)


def q23(v):
    return (v - (1 << 24)) / (1 << 23) if v & 0x800000 else v / (1 << 23)


def records(rom, ptr, limit=256):
    out, p, g = [], ptr, 0
    while g < limit:
        g += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 & 0xF0) == 0xF0: break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 3 or ln > 0x400: break
        out.append(bytes(rom.slice(p + 2, ln - 2)))
        p += ln
    return out


def k24_of(rom, algo):
    """slot 0 of a reverb is `75 <idx> b0 b1 b2 7A'.  Do NOT split on 0x7A --
    PLATE REVERB 2's literal 0x347AE1 contains one."""
    recs = records(rom, rom.u32le(T_LVL2_DEFAULTS + 4 * algo))
    if not recs or recs[0][0] != 0x75: return None
    pl = recs[0]
    return (pl[2] << 16) | (pl[3] << 8) | pl[4]


def bank_of(rom, algo):
    """The whole parameter stream: 5-byte poke packets AND type-2 bulk records.
    The reverb coefficient bank arrives ONLY as type-2 bulk (raw 24-bit words)
    aimed by a poke-port `801.0.NN.821'.  Poke payloads are 2*raw3 + tagbit
    (r3-delaydram.md P2); type-2 words are raw."""
    p, guard = rom.u32le(T_PARAM + 4 * algo), 0
    cram, desc, dram = {}, {}, {}
    ptr, space = None, None
    while guard < 512:
        guard += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 >> 4) == 0xF: break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF: break
        op, body = b0 >> 4, rom.slice(p + 2, ln - 2)
        if op in (0, 1, 5):
            data = body[3:]
            for k in range(0, len(data) - 4, 5):
                e = data[k:k + 5]
                if e[0] == 0x08 and e[1] == 0x01 and e[4] in (0x21, 0x25):
                    ptr = (e[2] << 4) | (e[3] >> 4)
                    space = 'CRAM' if e[4] == 0x21 else 'DESC'
                elif e[0] == 0x00 and e[1] == 0x00 and e[4] == 0x00:
                    ptr, space = (e[2] << 4) | (e[3] >> 4), 'DRAM'
                elif e[0] == 0x0A:
                    v = ((e[1] & 0x7F) << 17) | (e[2] << 9) | (e[3] << 1) | (e[4] >> 7)
                    sp = {0x26: 'CRAM', 0x4C: 'DESC', 0x15: 'DRAM'}.get(e[4] & 0x7F)
                    d = {'CRAM': cram, 'DESC': desc, 'DRAM': dram}.get(sp)
                    if d is not None and ptr is not None:
                        d[ptr] = v; ptr += 1
        elif op == 2:
            data = body[3:]
            for k in range(0, len(data) - 2, 3):
                v = (data[k] << 16) | (data[k + 1] << 8) | data[k + 2]
                d = {'CRAM': cram, 'DESC': desc, 'DRAM': dram}.get(space)
                if d is not None and ptr is not None:
                    d[ptr] = v; ptr += 1
        p += ln
    return cram, desc, dram


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default=os.path.expanduser(
        "~/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.expanduser(
        "~/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v10_program.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    a = ap.parse_args()
    sys.path.insert(0, a.tools)
    import kn5000_dsp_extract as E, kn5000_dsp_coeffs as C
    rom = E.Rom(a.rom)
    names = C.effect_names(a.main) if os.path.exists(a.main) else {}
    VAL = [T_of(p) for p in range(110)]

    print("=" * 78)
    print("THE REVERB-TIME VALUE LIST the five ranges of scaler 0x039D98 spell out")
    print("=" * 78)
    for lo, hi, f in ((0, 16, "%.2f"), (16, 24, "%.2f"), (24, 56, "%.1f"),
                      (56, 76, "%.1f"), (76, 86, "%.0f")):
        print("   p=%-3d..%-3d : %s" % (lo, hi - 1, " ".join(f % v for v in VAL[lo:hi])))
    print("   -- 0.1 s .. >= 16 s, step 0.02 / 0.05 / 0.1 / 0.2 / 1.0.  The four")
    print("      range breaks ARE the four step changes.")
    print()
    print("=" * 78)
    print("THE DEFAULT DECAY GAIN, and the reverb time it decodes to")
    print("=" * 78)
    print("   %-18s %-8s %-6s %-10s %-7s %-8s %-6s %-6s"
          % ("preset", "K", "cell", "coef Q0.23", "g=2c", "T solved", "listT", "err%"))
    bad = 0
    for al in REVERBS:
        cram, _d, _r = bank_of(rom, al)
        cell = 0x98 if al == 25 else 0x97   # algo 25's bank is 38 cells, shifted +1
        K24 = k24_of(rom, al); K = K24 / 2 ** 23
        c = q23(cram[cell]); g = 2 * c
        T = -A_CONST * K / math.log10(g)
        nv = min(VAL, key=lambda v: abs(v - T))
        err = 100 * abs(T - nv) / nv
        bad += err > 2.0
        print("   %-18s %-8.4f 0x%02X%s 0x%06X   %-7.4f %-8.4f %-6.2f %-6.2f"
              % (names.get(al, "?"), K, cell, "*" if al == 25 else " ",
                 cram[cell], g, T, nv, err))
    print()
    print("   FALSIFIER: every solved T must land on the discrete list above.")
    print("   %d of 12 miss by more than 2 %%." % bad)
    print()
    print("=" * 78)
    print("THE LADDER, per preset: descriptor lags and the whole coefficient bank")
    print("=" * 78)
    for al in REVERBS:
        cram, desc, _r = bank_of(rom, al)
        pairs = [(desc[0x04 + 2 * i], desc[0x05 + 2 * i]) for i in range(10)]
        lags = [r - w for r, w in pairs]
        sh = 1 if al == 25 else 0
        print("   %-18s pre-delay %5d   ladderA %s   ladderB %s"
              % (names.get(al, "?"), desc[0x00] - desc[0x03],
                 " ".join("%5d" % x for x in lags[0::2]),
                 " ".join("%5d" % x for x in lags[1::2])))
        print("   %-18s allpass A %s | B %s | decay %.4f | damp %.4f"
              % ("", " ".join("%+.3f" % q23(cram[c]) for c in range(0x99 + sh, 0x9E + sh)),
                 " ".join("%+.3f" % q23(cram[c]) for c in range(0xA1 + sh, 0xA6 + sh)),
                 2 * q23(cram[0x97 + sh]), q23(cram[0x9E + sh])))
    print()
    print("=" * 78)
    print("CONTROL -- the comb identity T60 = -3D/(Fs log10 g) does NOT recover D")
    print("=" * 78)
    print("   %-18s %-10s %-9s %-9s %s" % ("preset", "D=A*Fs*K/3", "ladderA", "ladderB", "verdict"))
    for al in REVERBS:
        _c, desc, _r = bank_of(rom, al)
        lags = [desc[0x04 + 2 * i] - desc[0x05 + 2 * i] for i in range(10)]
        K = k24_of(rom, al) / 2 ** 23
        D = A_CONST * FS * K / 3
        sa, sb = sum(lags[0::2]), sum(lags[1::2])
        print("   %-18s %-10.1f %-9d %-9d %s" % (names.get(al, "?"), D, sa, sb,
              "ratio %.3f / %.3f" % (D / sa, D / sb)))
    print("   DARK 1, DARK 2 and BRIGHT 1 carry the SAME K over ladders that differ")
    print("   by 25 %%, so K is NOT this preset's loop length.  The comb route fails;")
    print("   K is a per-preset calibration constant and the firmware's law stands.")


if __name__ == "__main__":
    main()
