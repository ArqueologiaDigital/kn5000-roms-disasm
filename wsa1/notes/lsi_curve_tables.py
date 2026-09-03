#!/usr/bin/env python3
"""The CURVE TABLES behind the 0x00104000 (IC3) per-channel registers: numbers, fits, units.

QUESTION IT ANSWERS
  The 0x00104000 register map (prom_c/devices/dev10c_dev104_drivers.s, wave 17) proves the
  ARITHMETIC of all nineteen per-channel registers and names the PHYSICAL QUANTITY of none
  of them.  Every one of those expressions runs through a named ROM table.  This script
  extracts each table from original_ROMs/wsa1_prom_c.ic28, fits it, prints the residual of
  the fit AND of a competing fit (the NULL), and states the unit the fit implies.

  ★ THE RESULT THAT MADE THE REST READABLE, and the one to check first:
    Curve_FE04C9 and Curve_FE05C9 are not two curves.  Passed through the firmware's own
    fold() they are two encodings of ONE quantity -- a FILTER CUTOFF FREQUENCY --
        F[k] = 65536 * g/(1+g)        G[k] = 8192 * (1 - 1/(128*g))
        g    = tan(pi * f_k / 44100)  f_k  = 440 * 2^((k-33)/12) Hz
    i.e. g is the bilinear (prewarped) cutoff of a ONE-POLE LOWPASS, F is that filter's
    ZDF/bilinear coefficient, and the index k is a SEMITONE: k = MIDI note - 36, to within
    0.4 cent, at the 44.1 kHz sample rate the schematic fixes.  The table saturates at
    k = 100 because theta(101) > pi/2 -- the next semitone is past NYQUIST.

RUN
  python3 notes/lsi_curve_tables.py --selftest   # every number quoted in the findings note
  python3 notes/lsi_curve_tables.py --fit        # the fits, with residuals and nulls
  python3 notes/lsi_curve_tables.py --summary    # the (table, fit, endpoints, unit, grade) table
  python3 notes/lsi_curve_tables.py --dump NAME  # the raw entries of one table

WHAT IS MEASURED AND WHAT IS INFERRED
  MEASURED: every entry, every closed form, every residual below.  The sample rate 44,100 Hz
  is NOT measured here -- it comes from notes/DRIVER-INSIGHT-wsa1-2026-09-02.md (IC4's
  crystal X4 = 33.8688 MHz = 768 * 44100) and notes/FINDINGS-prom_c-tail-data-zone.md (the
  f64 constant pool holds 44100, 1/44100, 1/220500, 1/441000).  Section FE04C9 below is the
  only place a Hz figure appears, and it says so.
  INFERRED: that the device at 0x00104000 is the acoustic-modelling LSI IC3.  Nothing here
  rests on that; the fits are fits whatever the chip is.
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
BASE = 0xF80000
FS = 44100.0                    # see the docstring: schematic + constant pool, NOT measured here


# ---------------------------------------------------------------- readers
def u8(a, n):
    return list(IMG[a - BASE:a - BASE + n])


def s8(a, n):
    return [v - 256 if v >= 128 else v for v in u8(a, n)]


def u16(a, n):
    return [IMG[a - BASE + 2 * i] | (IMG[a - BASE + 2 * i + 1] << 8) for i in range(n)]


def s16(a, n):
    return [v - 65536 if v >= 32768 else v for v in u16(a, n)]


def fold(x):
    """The firmware's own fold(), 0xFC5320 etc.  Maps the stored word to an unsigned 0..65535."""
    return (0x8000 - (x & 0x7FFF)) if (x & 0x8000) else (x + 0x8000)


# ---------------------------------------------------------------- the tables
TABLES = {
    "Curve_Exp2Decay_256":  (0xFDF7E0, 256, "u16"),
    "Curve_Exp2Rise_128":   (0xFDF9E0, 128, "u16"),
    "Curve_Log2_251":       (0xFDFAE0, 251, "u16"),
    "Const_0100_251":       (0xFDFCD6, 251, "u16"),
    "Curve_Exp2Decay_101":  (0xFDFECC, 101, "u16"),
    "Table_FDFF96":         (0xFDFF96, 256, "u8"),
    "LinCoef_FE0096":       (0xFE0096, 128, "s8"),
    "LinCoef_FE0116":       (0xFE0116, 128, "s8"),
    "LinCoef_FE0196":       (0xFE0196, 128, "s8"),
    "LinCoef_FE0216":       (0xFE0216, 128, "s8"),
    "Curve_FE04C9":         (0xFE04C9, 128, "u16"),
    "Curve_FE05C9":         (0xFE05C9, 128, "u16"),
    "ExpCurve_0_to_0x80":   (0xFDF760, 128, "u8"),
}


def get(name):
    addr, n, kind = TABLES[name]
    return {"u8": u8, "s8": s8, "u16": u16, "s16": s16}[kind](addr, n)


# ---------------------------------------------------------------- fit helpers
def linfit(xs, ys):
    n = len(xs)
    mx, my = sum(xs) / n, sum(ys) / n
    sxx = sum((x - mx) ** 2 for x in xs)
    b = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sxx
    a = my - b * mx
    res = [y - (a + b * x) for x, y in zip(xs, ys)]
    ss_res = sum(r * r for r in res)
    ss_tot = sum((y - my) ** 2 for y in ys)
    r2 = 1 - ss_res / ss_tot if ss_tot else float("nan")
    return a, b, max(abs(r) for r in res), r2


def null_line(xs, ys, label):
    """⚠ THE NULL.  A straight line through the SAME points, so 'it fits an exponential'
    can be compared against something that is not an exponential."""
    a, b, mx, r2 = linfit(xs, ys)
    return f"    NULL  straight line in {label}: R^2 = {r2:.6f}, max|residual| = {mx:.4f}"


FAIL = []


def check(cond, msg):
    if not cond:
        FAIL.append(msg)
    return cond


# ---------------------------------------------------------------- per-table analyses
def fit_exp2decay_256(verbose):
    T = get("Curve_Exp2Decay_256")
    errs = [T[k] - round(32768 * 2 ** ((k - 255) / 16)) for k in range(256)]
    zero_upto = max(k for k in range(256) if T[k] == 0)
    check(max(abs(e) for e in errs) <= 4, "Exp2Decay_256 closed form")
    check(T[255] == 0x8000, "Exp2Decay_256 T[255]")
    check(zero_upto == 46, "Exp2Decay_256 zero run")
    if verbose:
        xs = [k for k in range(47, 256) if T[k] >= 1024]   # log2 null needs entries whose
        #                                                     quantisation is < 0.0014 in log2
        print("Curve_Exp2Decay_256   T[k] = round(32768 * 2^((k-255)/16))")
        print(f"    max|residual| = {max(abs(e) for e in errs)} counts over all 256 entries")
        print(f"    T[0..{zero_upto}] = 0 (below half a count); T[255] = 0x8000 = 1.0 in Q15")
        print( "    16 steps per doubling = 6.0206/16 = 0.3763 dB per step; 209 live steps = 78.6 dB")
        print(f"    (null band k = {xs[0]}..{xs[-1]}, where the 1-count quantisation is under 0.0014 in log2)")
        print(null_line(xs, [T[k] for k in xs], "linear T"))
        print(null_line(xs, [math.log2(T[k]) for k in xs], "log2 T") + "   <- the claimed law")
    return T


def fit_exp2rise_128(verbose):
    T = get("Curve_Exp2Rise_128")
    errs = [T[k] - round(32768 * (1 - 2 ** (-k / 16))) for k in range(128)]
    check(max(abs(e) for e in errs) == 0, "Exp2Rise_128 closed form exact")
    check(T[127] == 0x7F7A, "Exp2Rise_128 T[127]")
    if verbose:
        xs = list(range(1, 128))
        print("Curve_Exp2Rise_128    T[k] = 32768 * (1 - 2^(-k/16))")
        print(f"    max|residual| = {max(abs(e) for e in errs)} counts -- EXACT on all 128 entries")
        print( "    T[0] = 0, T[127] = 0x7F7A = 0.99586 in Q15 (-0.036 dB); the complement")
        print( "    2^(-k/16) is the same 0.3763 dB per step as Curve_Exp2Decay_256")
        print(null_line(xs, [T[k] for k in xs], "linear T"))
        print(null_line(xs, [math.log2(32768 - T[k]) for k in xs], "log2(32768-T)") + "   <- the claimed law")
    return T


def fit_log2_251(verbose):
    T = get("Curve_Log2_251")
    errs = [T[k] - round(27543 - 3072 * math.log2(k)) for k in range(1, 251)]
    check(T[0] == 0x6C00, "Log2_251 T[0]")
    check(max(abs(e) for e in errs) <= 1, "Log2_251 closed form")
    check(T[1] == 27543 and T[250] == round(27543 - 3072 * math.log2(250)), "Log2_251 endpoints")
    if verbose:
        xs = list(range(1, 251))
        print("Curve_Log2_251        T[0] = 0x6C00 = 27648 = 108.000 semitones;")
        print("                      T[k] = round(27543 - 3072*log2 k)   for k >= 1")
        print(f"    max|residual| = {max(abs(e) for e in errs)} counts over entries 1..250")
        print( "    3072 counts per halving = 12 * 256, so ONE COUNT IS 1/256 SEMITONE -- the")
        print( "    unit MathTable_Log2_256 uses and the unit the tone generator's pitch")
        print( "    register 0x0400 uses (FINDINGS-prom_c-dev10c-register-meanings.md s.2).")
        print(f"    T[1] = {T[1]} = {T[1]/256:.3f} st, T[250] = {T[250]} = {T[250]/256:.3f} st")
        print(f"    span = {T[1]-T[250]} counts = {(T[1]-T[250])/3072:.3f} octaves")
        print(null_line(xs, [T[k] for k in xs], "T vs k"))
        print(null_line([math.log2(k) for k in xs], [T[k] for k in xs], "T vs log2 k") + "   <- the claimed law")
    return T


def fit_const_251(verbose):
    T = get("Const_0100_251")
    check(all(v == 0x0100 for v in T), "Const_0100_251 all 0x0100")
    if verbose:
        print("Const_0100_251        0x0100 in ALL 251 entries -- distinct values:",
              sorted(set(T)))
        print( "    ⚠ A CONSTANT ON THIS FIRMWARE, not a property of the silicon.  Read with")
        print( "    the SAME clamped 0..250 index as Curve_Log2_251, one instruction later")
        print( "    (0xFC49ED), so an emulator can hard-wire register 0x0100 + chan = 0x0100")
        print( "    for every write this path makes and compute nothing.")
        print( "    0x0100 = 256 = exactly ONE SEMITONE in Curve_Log2_251's unit, and 1.0 in Q8.")
    return T


def fit_exp2decay_101(verbose):
    T = get("Curve_Exp2Decay_101")
    B = get("Curve_Exp2Decay_256")
    check(T[0] == 0, "Exp2Decay_101 T[0]")
    check(all(T[k] == B[k + 155] for k in range(1, 101)), "Exp2Decay_101 is Exp2Decay_256[k+155]")
    errs = [T[k] - round(32768 * 2 ** ((k - 100) / 16)) for k in range(1, 101)]
    check(max(abs(e) for e in errs) <= 4, "Exp2Decay_101 closed form")
    if verbose:
        print("Curve_Exp2Decay_101   T[0] = 0; T[k] = Curve_Exp2Decay_256[k+155]")
        print("                           = round(32768 * 2^((k-100)/16))   for k = 1..100")
        print(f"    max|residual| = {max(abs(e) for e in errs)} counts; T[100] = 0x{T[100]:04X}, T[1] = {T[1]}")
        print(f"    Q15 gain from {T[1]/32768:.5f} ({20*math.log10(T[1]/32768):.2f} dB) to 1.0,")
        print( "    0.3763 dB per step, PLUS a hard zero at index 0.")
        print( "    ★ The index is clamped 0..100 (0xFC4B04, 0xFC6ECA): a 0..100 UI PERCENTAGE")
        print( "    with an explicit OFF position, given a 37 dB logarithmic taper.")
        xs = list(range(1, 101))
        print(null_line(xs, [T[k] for k in xs], "linear T"))
        print(null_line(xs, [math.log2(T[k]) for k in xs], "log2 T") + "   <- the claimed law")
    return T


def fit_expcurve_0x80(verbose):
    T = get("ExpCurve_0_to_0x80")
    model = [0] + [max(1, round(128 * 2 ** ((k - 127) / 16))) for k in range(1, 128)]
    errs = [T[k] - model[k] for k in range(128)]
    check(T[0] == 0 and T[127] == 0x80, "ExpCurve endpoints")
    check(max(abs(e) for e in errs) <= 1, "ExpCurve closed form")
    check(T[111] == 0x40 and T[95] == 0x20 and T[79] == 0x10, "ExpCurve halves every 16")
    if verbose:
        print("ExpCurve_0_to_0x80    T[0] = 0; T[k] = max(1, round(128 * 2^((k-127)/16)))")
        print(f"    max|residual| = {max(abs(e) for e in errs)} counts over all 128 entries")
        print( "    T[127]=0x80, T[111]=0x40, T[95]=0x20, T[79]=0x10 -- HALVES EVERY 16 STEPS,")
        print( "    the same 0.3763 dB per step as the two other exp2 tables.  Floors at 1 for")
        print( "    k <= 24 and is 0 only at k = 0.  Live span 0x80 -> 1 = 42.1 dB.")
        print( "    The packer writes (b << 8) | b -- ONE BYTE IN BOTH HALVES of register 0x0300.")
        xs = [k for k in range(25, 128) if T[k] >= 32]
        print(f"    (null band k = {xs[0]}..{xs[-1]}; below that the 8-bit table quantises to 1 count)")
        print(null_line(xs, [T[k] for k in xs], "linear T"))
        print(null_line(xs, [math.log2(T[k]) for k in xs], "log2 T") + "   <- the claimed law")
    return T


def fit_lincoefs(verbose):
    A = get("LinCoef_FE0096")
    B = get("LinCoef_FE0116")
    C = get("LinCoef_FE0196")
    D = get("LinCoef_FE0216")
    check(all(A[k] == 2 * k - 128 for k in range(128)), "LinCoef_FE0096 = 2k-128")
    check(all(B[k] == (k * 65) // 128 - 32 for k in range(128)), "LinCoef_FE0116 = 65k/128-32")
    check(all(C[k] == k // 2 - 64 for k in range(127)) and C[127] == 0, "LinCoef_FE0196 = k/2-64, T[127]=0")
    check(C == D, "LinCoef_FE0216 == LinCoef_FE0196")
    if verbose:
        print("The four Q5 key-scaling ramps (32 = 1.0).  Reader idiom, four sites:")
        print("    A = depth (signed); if A < 0: key' = 0x7F - key, A = -A;  result = (T[key'] * A) >> 5")
        print(f"  LinCoef_FE0096  T[k] = 2k - 128      exact, {A[0]}..{A[127]}  = {A[0]/32:+.3f}..{A[127]/32:+.3f} in Q5")
        print( "                  slope 2/32 = 1/16 index unit per key.  -> R[+0x12], the")
        print( "                  Curve_Log2_251 index (0..250), so its unit is that index's.")
        print(f"  LinCoef_FE0116  T[k] = 65k//128 - 32 exact, {B[0]}..{B[127]} = {B[0]/32:+.3f}..{B[127]/32:+.3f} in Q5")
        print( "                  slope 65/128/32 = 1/63.0 per key, BIPOLAR; the single zero is")
        print( "                  at k = 64 (T[63] = -1, T[64] = 0, T[65] = +1).  -> v1/v2, the")
        print( "                  exp2 index, so one unit of it is 0.3763 dB.")
        print(f"  LinCoef_FE0196  T[k] = k//2 - 64 for k < 127, T[127] = 0.  {C[0]}..{C[126]}, then 0")
        print(f"                  = {C[0]/32:+.3f}..{C[126]/32:+.3f} in Q5; slope 1/64 per key, UNIPOLAR")
        print( "                  (0 at the top of the keyboard).  -> i3/i4, THE CUTOFF INDEX,")
        print( "                  which is in SEMITONES -- so a depth byte of 64 is exactly")
        print( "                  1 semitone of cutoff per semitone of key = 100% KEY FOLLOW,")
        print( "                  and the signed byte's +/-127 range is +/-198%.")
        print( "  LinCoef_FE0216  BYTE-IDENTICAL to LinCoef_FE0196, all 128.  Two copies, one curve.")
        print( "    ⚠ NULL: these are not 'approximately linear'.  Each is EXACT against its")
        print( "    integer law on every entry, and FE0196's single exception at k = 127 is")
        print( "    what a sampled check would have missed.")
    return A, B, C, D


def fit_table_fdff96(verbose):
    T = get("Table_FDFF96")
    check(min(T) == 0x22 and max(T) == 0x3C, "Table_FDFF96 range")
    if verbose:
        lo, hi = min(T), max(T)
        print(f"Table_FDFF96          256 u8, values {lo} (0x{lo:02X}) .. {hi} (0x{hi:02X}), {len(set(T))} distinct")
        print( "    Indexed by the key-zone byte at (0x00E08C); used as the LOWER clamp on the")
        print( "    cutoff index i3/i4 (0xFC52D2, 0xFC5439).")
        print(f"    ★ In the FE04C9 unit that is a MINIMUM CUTOFF of {note_hz(lo):.0f} Hz .. {note_hz(hi):.0f} Hz")
        print( "      per key zone -- a floor that keeps the filter above the zone's own band.")
    return T


def note_hz(k):
    """The cutoff frequency FE04C9's index k stands for, at 44.1 kHz.  k = MIDI note - 36."""
    return 440.0 * 2 ** ((k - 33) / 12.0)


def theta(k):
    return math.pi * note_hz(k) / FS


def fit_fe04c9_fe05c9(verbose):
    Traw = get("Curve_FE04C9")
    Uraw = get("Curve_FE05C9")
    F = [fold(v) for v in Traw]
    G = [fold(v) for v in Uraw]
    check(all(F[i] <= F[i + 1] for i in range(127)), "fold(FE04C9) monotone")
    check(all(G[i] <= G[i + 1] for i in range(127)), "fold(FE05C9) monotone")
    # the live band: below 9 both tables are floored, from 100 up both are saturated
    band = range(9, 101)
    eF = [F[k] - round(65536 * math.tan(theta(k)) / (1 + math.tan(theta(k)))) for k in band]
    eG = [G[k] - round(8192 * (1 - 1 / (128 * math.tan(theta(k))))) for k in band]
    check(max(abs(e) for e in eF) <= 1, "FE04C9 tan model")
    check(max(abs(e) for e in eG) <= 5, "FE05C9 tan model")
    check(all(F[k] == F[100] for k in range(100, 128)), "FE04C9 saturates from k=100")
    check(all(G[k] == G[100] for k in range(100, 128)), "FE05C9 saturates from k=100")
    check(theta(100) < math.pi / 2 < theta(101), "k=101 is past Nyquist")
    # the rigid tie between the two tables: each one implies a theta; compare them in CENTS,
    # because G's own quantisation (1/8192 on a residue that falls to 4 counts) is what limits
    # the comparison at the top and a raw relative error would read that as disagreement.
    tie = []
    for k in band:
        tF = math.atan(F[k] / (65536 - F[k]))
        r = 1 - G[k] / 8192
        tG = math.atan(1 / (128 * r))
        tie.append((k, 1200 * math.log2(tG / tF), 1200 * math.log2(1 + (1 / 8192) / r)))
    worst = max(abs(c) for _, c, _ in tie)
    check(worst < 18.0, "FE04C9 and FE05C9 imply the same theta (cents)")
    # ⚠ the NULL for 'the index is a semitone': fit the slope instead of assuming it
    xs = list(band)
    ys = [math.log2(math.atan(F[k] / (65536 - F[k]))) for k in xs]
    a, b, mres, r2 = linfit(xs, ys)
    check(abs(1 / b - 12.0) < 0.05, "12 index steps per octave")
    if verbose:
        print("Curve_FE04C9 / Curve_FE05C9  -- ★★ ONE QUANTITY, TWO ENCODINGS")
        print( "  Both are read with ONE index (i3, then i4) one instruction apart, and both are")
        print( "  stored in the encoding the firmware's own fold() inverts:")
        print( "      fold(x) = (x & 0x8000) ? 0x8000-(x & 0x7FFF) : x + 0x8000")
        print( "  fold() makes BOTH monotone -- that is what identifies the encoding, and it is")
        print( "  the same fold() the packer applies at 0xFC5361 on the way to register 0x01C0.")
        print()
        print(f"  F = fold(FE04C9): {F[0]} .. {F[100]}, saturated from k = 100 (28 entries)")
        print(f"  G = fold(FE05C9): {G[0]} .. {G[100]}, saturated from k = 100 (28 entries)")
        print()
        print( "  THE FIT, over the live band k = 9..100:")
        print( "      g    = tan(pi * f_k / 44100),   f_k = 440 * 2^((k-33)/12) Hz")
        print( "      F[k] = round(65536 * g/(1+g))            max|residual| = %d counts" % max(abs(e) for e in eF))
        print( "      G[k] = round(8192 * (1 - 1/(128*g)))     max|residual| = %d counts" % max(abs(e) for e in eG))
        print( "  -- and NOTHING was fitted to get f_k: the sample rate is the schematic's")
        print( "  33.8688 MHz / 768 and the note offset came out as an integer (below).")
        print()
        print( "  ⚠ THE NULL, and it is the whole argument.  Fit the slope instead of assuming it:")
        print(f"      log2(atan(F/(65536-F))) against k:  slope = 1/{1/b:.4f} per step, R^2 = {r2:.7f},")
        print(f"      max|residual| = {mres:.6f} in log2 = {mres*1200:.2f} cents.")
        print(f"      1/{1/b:.4f} is 12 steps per octave to {abs(1/b-12)/12*100:.2f}%.  A straight line in F itself:")
        print(null_line(xs, [F[k] for k in xs], "linear F"))
        print(null_line(xs, [math.log2(F[k]) for k in xs], "log2 F"))
        print( "      -- a plain exponential in F is NOT the law; the tan prewarp is (a plain")
        print( "      exponential would not saturate, and F's log slope drifts 12.1 -> 15.7 -> 11.2).")
        print()
        f0 = FS * math.atan(F[9] / (65536 - F[9])) / math.pi   # implied cutoff at k=9, from the ROM alone
        # recover the note offset from the ROM alone, with the slope forced to 1/12
        t0 = sum(math.atan(F[k] / (65536 - F[k])) / 2 ** (k / 12) for k in xs) / len(xs)
        midi0 = 69 + 12 * math.log2((FS * t0 / math.pi) / 440.0)
        print( "  ★ THE UNIT, recovered rather than assumed.  Force the slope to exactly 1/12 and")
        print( "    solve for the index-0 frequency from the ROM's own entries:")
        print(f"      f(k=0) = {FS*t0/math.pi:.4f} Hz  =  MIDI note {midi0:.4f}")
        print(f"    -- {abs(midi0-round(midi0))*100:.2f} cents from note {round(midi0)} exactly, against a fit scatter of")
        print(f"    {mres*1200:.2f} cents.  So THE INDEX IS A SEMITONE AND k = MIDI NOTE - 36.")
        print( "    ⚠ Landing within 1 cent of a note by luck is a 2% coincidence; what makes")
        print( "    this more than that is that fs was fixed independently, by the crystal.")
        print()
        print(f"  ★ THE CEILING IS NYQUIST.  theta(100) = {theta(100):.5f} rad < pi/2 = {math.pi/2:.5f}")
        print(f"    < theta(101) = {theta(101):.5f}.  The table saturates at exactly the last")
        print( "    index whose prewarp tan() is still finite and positive.  A table of a tan()")
        print( "    that stops one step before its pole is a bilinear filter coefficient; that")
        print( "    is the strongest single argument here and it needs no external constant.")
        print()
        print( "  ★ THE TWO REGISTERS ARE NOT INDEPENDENT.  Invert each table for its own theta")
        print( "    -- atan(F/(65536-F)) against atan(1/(128*(1-G/8192))) -- and over the whole")
        near = max(abs(c) for k, c, _ in tie if k <= 60)
        print(f"    live band k = 9..100 the two agree to {worst:.1f} CENTS worst case, and to")
        print(f"    {near:.1f} cents over k = 9..60 where G still has resolution to spare.  G is a")
        print( "    RESIDUE (1 - G/8192) that falls to four counts at the top, so its own")
        print(f"    quantisation alone allows {max(q for k, _, q in tie if k >= 90):.0f} cents there; the disagreement is under it.")
        print( "    Equivalently (1 - G/8192) * g = 1/128 entry for entry.  An emulator has ONE")
        print( "    parameter here, not two: given register 0x0400 it can compute 0x0340, and")
        print( "    the pair carries no state the cutoff does not already carry.")
        print()
        print( "  RANGE, in the unit above (k = 9 is where the floor ends, k = 100 the ceiling):")
        for k in (9, 34, 44, 60, 96, 100):
            print(f"      k = {k:3d}  ->  f = {note_hz(k):9.1f} Hz  (MIDI {k+36:3d})   F = {F[k]:5d}  G = {G[k]:5d}")
        print( "    ★ SANITY vs MUSIC: the reachable band the readers clamp to -- 44..96 at")
        print( "    0xFC4971/0xFC4976, and Table_FDFF96(34..60)..PART[+0x12] at 0xFC52D2 -- is")
        print(f"    {note_hz(44):.0f} Hz to {note_hz(96):.0f} Hz.  That is a filter cutoff range, not a pitch")
        print( "    range, and it is the range a lowpass on a musical voice needs.")
    return F, G


SITES = {
    0xFC49CC: ("db cf fa 00", "cp HL,0x00fa      -- Curve_Log2_251 index upper clamp, 250"),
    0xFC49D7: ("db d8",       "cp HL,0           -- and its lower clamp"),
    0xFC49E5: ("e9 c8 e0 fa fd 00", "add XBC,0x00FDFAE0  -- Curve_Log2_251"),
    0xFC49ED: ("f2 d6 fc fd 31", "lda XBC,0xFDFCD6    -- Const_0100_251, SAME index"),
    0xFC4A18: ("35 80 42",   "ld IY,0x4280      -- note 66 + the half-step centre 0x80"),
    0xFC4A1B: ("d8 a5",      "sub IY,WA         -- 0x4280 MINUS the key-followed pitch"),
    0xFC4A1D: ("dd 83",      "add HL,IY         -- ...added to the table value"),
    0xFC4A29: ("d8 a3",      "sub HL,WA         -- minus the key-zone word R[+0x0C]"),
    0xFC4A37: ("33 00 00",   "ld HL,0x0000      -- underflow -> the register's FLOOR"),
    0xFC4A3C: ("33 00 7f",   "ld HL,0x7f00      -- wrapped negative -> the register's CEILING"),
    0xFC4971: ("33 60 00",   "ld HL,0x0060      -- cutoff-index upper clamp, 96"),
    0xFC4976: ("db cf 2c 00","cp HL,0x002c      -- cutoff-index lower clamp, 44"),
    0xFC4987: ("e9 c8 c9 04 fe 00", "add XBC,0x00FE04C9  -- Curve_FE04C9"),
    0xFC4996: ("f2 c9 05 fe 31", "lda XBC,0xFE05C9    -- Curve_FE05C9, SAME index"),
    0xFC52AF: ("e9 c8 96 ff fd 00", "add XBC,0x00FDFF96  -- Table_FDFF96, the per-zone floor"),
}


def check_sites(verbose):
    """Re-read from the ROM the instructions the unit arguments above lean on, so that
    'the register's ceiling is 0x7F00' and 'the pitch term is SUBTRACTED' are bytes here
    and not a citation of another file."""
    if verbose:
        print("★ THE INSTRUCTIONS THE UNITS REST ON, re-read from the image")
    for addr, (hexs, what) in sorted(SITES.items()):
        want = bytes(int(b, 16) for b in hexs.split())
        got = IMG[addr - BASE:addr - BASE + len(want)]
        check(got == want, f"site 0x{addr:06X} {what}")
        if verbose:
            print(f"    0x{addr:06X}  {hexs:<22s} {what}")
    if verbose:
        print("  ★ So register 0x00C0's range is [0x0000, 0x7F00] = [0, 127.000] in the")
        print("    1/256-semitone unit Curve_Log2_251's slope fixes -- the SAME 0..127 window")
        print("    the tone generator's pitch register uses -- and the pitch enters it")
        print("    NEGATED, pivoting on 0x4280 = note 66.5.  A log-domain quantity that falls")
        print("    one octave when the note rises one octave is a PERIOD or a TIME, not a")
        print("    frequency.  Grade STRONG; the absolute scale is UNIDENTIFIED, because")
        print("    nothing in the image says what value of this register is what time.")


def sanity_vs_music(verbose):
    """⚠ THE PLACE A FIT IMPLIES SOMETHING ABSURD, reported rather than smoothed over."""
    D = get("Curve_Exp2Decay_256")
    R = get("Curve_Exp2Rise_128")
    # If T/32768 were a PER-SAMPLE feedback pole a, the time constant is -1/ln(a) samples.
    a2 = D[254] / 32768.0                         # the largest pole below 1.0 the table holds
    tau = -1.0 / math.log(a2) / FS                # seconds at 44.1 kHz
    a_1ms = math.exp(-1.0 / (0.001 * FS))         # the pole a 1 ms time constant needs
    check(a2 < a_1ms, "Exp2Decay_256 cannot express a 1 ms per-sample pole")
    F, _ = None, None
    if verbose:
        print("★ WHERE THE ARITHMETIC IMPLIES SOMETHING MUSICALLY ABSURD")
        print( "  Curve_Exp2Decay_256 / Curve_Exp2Rise_128 CANNOT BE PER-SAMPLE FILTER POLES.")
        print(f"    The table's two largest entries are 0x{D[255]:04X} (= 1.0) and 0x{D[254]:04X}")
        print(f"    (= {a2:.6f}); there is NOTHING in between.  As a per-sample pole,")
        print(f"    {a2:.6f} is a time constant of {tau*1000:.3f} ms at {FS:.0f} Hz, and even a 1 ms")
        print(f"    time constant would need {a_1ms:.6f} -- unrepresentable.  An envelope or a")
        print( "    string decay wants 0.1 s to 10 s, i.e. a pole within ~100 counts of 0x8000.")
        print( "    So these are GAINS/DEPTHS, or coefficients applied at a CONTROL rate of a")
        print( "    few hundred Hz, not per-sample poles.  ⚠ The ROM states no control rate;")
        print( "    at fs/128 = 345 Hz the same entry would be 67 ms, which is musical.  That")
        print( "    is a hypothesis with a number attached, not a finding.")
        print()
        print( "  Curve_Exp2Rise_128 AS A CUTOFF SCALER IS musical.  Register 0x01C0 is")
        print( "  register 0x0400's word (a cutoff coefficient) times Curve_Exp2Rise_128[v1]/2:")
        print( "    v1     scale = 1-2^(-v1/16)    cutoff shift")
        for v1 in (1, 4, 8, 16, 32, 64, 127):
            sc = R[v1] / 32768.0
            print(f"    {v1:3d}    {sc:18.5f}    {math.log2(sc):+7.2f} octaves")
        print( "  -- 0 to -4.6 octaves below the 0x0400 cutoff, which is the range a filter")
        print( "  envelope floor covers.  [INFERENCE] and it is labelled as one.")
        print()
        print( "  ★ AND ONE ARITHMETIC COINCIDENCE WORTH RECORDING, conditional on data this")
        print( "  ROM does not fix.  Register 0x0140 is Curve_Exp2Decay_256[0xCF - g(v1) + b],")
        print( "  b = (int8)(0x00E08C), and register 0x01C0 carries Curve_Exp2Rise_128[v1].")
        print( "  For b = 0x30 = 48 and v1 >= 48 those are 32768*2^(-v1/16) and")
        print( "  32768*(1 - 2^(-v1/16)) -- an EXACT (a, 1-a) pair, i.e. a first-order lag")
        print( "  toward the 0x0400 target.  ⚠ Nothing here fixes b; the key-zone byte that")
        print( "  supplies it lives in prom_d, and Table_FDFF96's own values at that index run")
        print( "  0x22..0x3C, which brackets 0x30.  Recorded as a coincidence with a condition.")
    return D, R


# ---------------------------------------------------------------- summary
SUMMARY = [
 # name, entries, fit, endpoints, unit inferred, grade
 ("Curve_Log2_251", 251, "T[0]=27648; T[k]=round(27543-3072*log2 k)",
  "27648 -> 3072", "1/256 SEMITONE (3072/octave); log-domain", "PROVEN fit / STRONG unit"),
 ("Const_0100_251", 251, "T[k] = 0x0100",
  "0x0100 -> 0x0100", "dimensionless; 1.0 in Q8 = 1 semitone in the line above",
  "PROVEN (this firmware only)"),
 ("Curve_Exp2Decay_256", 256, "T[k]=round(32768*2^((k-255)/16))",
  "0 (k<=46) -> 0x8000", "Q15 GAIN; 0.3763 dB/step, 78.6 dB live span", "PROVEN fit / UNIDENTIFIED role"),
 ("Curve_Exp2Rise_128", 128, "T[k]=32768*(1-2^(-k/16)) exact",
  "0 -> 0x7F7A", "Q15 DEPTH/mix (1 - the same 0.3763 dB/step ramp)", "PROVEN fit / UNIDENTIFIED role"),
 ("Curve_Exp2Decay_101", 101, "T[0]=0; T[k]=round(32768*2^((k-100)/16))",
  "0 / 450 -> 0x8000", "Q15 GAIN over a 0..100 UI PERCENT, 37.3 dB + OFF", "PROVEN fit / STRONG unit"),
 ("ExpCurve_0_to_0x80", 128, "T[0]=0; T[k]=max(1,round(128*2^((k-127)/16)))",
  "0 -> 0x80", "8-bit GAIN over a 0..127 UI value, 42.1 dB, duplicated into both register halves",
  "PROVEN fit / STRONG unit"),
 ("Curve_FE04C9 (folded)", 128, "F=round(65536*g/(1+g)), g=tan(pi*f/44100), f=440*2^((k-33)/12)",
  "510 -> 61359", "ONE-POLE LOWPASS COEFFICIENT; index = SEMITONE = MIDI note - 36",
  "PROVEN fit / STRONG unit"),
 ("Curve_FE05C9 (folded)", 128, "G=round(8192*(1-1/(128*g))), same g",
  "25 -> 8188", "Q13 companion of the SAME cutoff: (1-G/8192)*g = 1/128 exactly",
  "PROVEN fit / UNIDENTIFIED role"),
 ("Table_FDFF96", 256, "no closed form; 27 distinct values 0x22..0x3C",
  "0x22 -> 0x3C", "MINIMUM CUTOFF per key zone: 466 Hz .. 2094 Hz", "PROVEN range / STRONG unit"),
 ("LinCoef_FE0096", 128, "T[k]=2k-128 exact",
  "-128 -> +126", "Q5 key ramp +/-4.0; 1/16 of a Curve_Log2_251 index step per key",
  "PROVEN fit / STRONG unit"),
 ("LinCoef_FE0116", 128, "T[k]=65k//128-32 exact",
  "-32 -> +32", "Q5 key ramp +/-1.0, bipolar; 1/63 of a 0.3763 dB step per key",
  "PROVEN fit / STRONG unit"),
 ("LinCoef_FE0196", 128, "T[k]=k//2-64, T[127]=0",
  "-64 -> -1, then 0", "Q5 key ramp -2.0..0; depth 64 = 100% CUTOFF KEY FOLLOW",
  "PROVEN fit / STRONG unit"),
 ("LinCoef_FE0216", 128, "byte-identical to LinCoef_FE0196", "same", "same", "PROVEN"),
]

REGISTERS = [
 ("0x00C0", "Curve_Log2_251 + (0x4280 - pitch) - zone, clamped 0x0000/0x7F00",
  "a LOG-DOMAIN TIME, 1/256 semitone per count, tracking pitch with slope -1", "STRONG"),
 ("0x0100", "Const_0100_251[same index]", "the constant 0x0100 on this firmware", "PROVEN"),
 ("0x0140", "Curve_Exp2Decay_256[i1] & 0xFFF8", "a Q15 gain, 13 bits used", "PROVEN / role UNIDENTIFIED"),
 ("0x0180", "Curve_Exp2Decay_256[i2] & 0xFFF8", "as 0x0140, the B generator", "PROVEN / role UNIDENTIFIED"),
 ("0x01C0", "high16(fold(reg 0x0400's word) * Curve_Exp2Rise_128[v1])",
  "the SAME cutoff coefficient as 0x0400, scaled 0..0.996", "STRONG"),
 ("0x0200", "the same with v2 and reg 0x0440's word", "as 0x01C0, the B generator", "STRONG"),
 ("0x0240", "(high16(fold(P[+0x26]) * Curve_Exp2Rise_128[..]) & 0xFFF8) | 7",
  "a scaled parameter word; low 3 bits are a separate field, written 7", "PROVEN / role UNIDENTIFIED"),
 ("0x0280", "Curve_Exp2Decay_101[clamp(.., 0..100)]", "a Q15 gain from a 0..100 percent control", "STRONG"),
 ("0x0300", "b = ExpCurve_0_to_0x80[Q[+0x13]]; (b<<8)|b",
  "an 8-bit gain from a 0..127 control, in BOTH halves", "STRONG"),
 ("0x0340", "Curve_FE05C9[i3]", "the Q13 companion of 0x0400's cutoff", "STRONG (tied), role UNIDENTIFIED"),
 ("0x0380", "Curve_FE05C9[i4]", "as 0x0340, the B generator", "STRONG (tied), role UNIDENTIFIED"),
 ("0x0400", "Curve_FE04C9[i3]", "a ONE-POLE LOWPASS CUTOFF COEFFICIENT, index in semitones", "STRONG"),
 ("0x0440", "Curve_FE04C9[i4]", "as 0x0400, the B generator", "STRONG"),
]


def main():
    args = sys.argv[1:]
    if args and args[0] == "--dump":
        name = args[1]
        T = get(name)
        addr, n, kind = TABLES[name]
        for k in range(0, n, 8):
            print(f"{addr+k*(2 if kind.endswith('16') else 1):06X} [{k:3d}] " +
                  " ".join(f"{v:6d}" for v in T[k:k + 8]))
        return 0
    verbose = not args or args[0] == "--fit"
    if args and args[0] == "--summary":
        w = (24, 5, 62, 22, 62, 30)
        hdr = ("table", "n", "fit", "endpoints", "unit inferred", "grade")
        print(" | ".join(h.ljust(x) for h, x in zip(hdr, w)))
        print("-+-".join("-" * x for x in w))
        for row in SUMMARY:
            print(" | ".join(str(c).ljust(x) for c, x in zip(row, w)))
        print()
        print("REGISTERS OF 0x00104000 THIS PUTS A QUANTITY ON")
        for r, expr, unit, grade in REGISTERS:
            print(f"  chan+{r}  {unit}")
            print(f"            from: {expr}")
            print(f"            grade: {grade}")
        return 0
    if verbose:
        print("=" * 78)
        print("The 0x00104000 curve tables, from original_ROMs/wsa1_prom_c.ic28")
        print("=" * 78)
    fit_exp2decay_256(verbose)
    if verbose: print()
    fit_exp2rise_128(verbose)
    if verbose: print()
    fit_log2_251(verbose)
    if verbose: print()
    fit_const_251(verbose)
    if verbose: print()
    fit_exp2decay_101(verbose)
    if verbose: print()
    fit_expcurve_0x80(verbose)
    if verbose: print()
    fit_lincoefs(verbose)
    if verbose: print()
    fit_table_fdff96(verbose)
    if verbose: print()
    fit_fe04c9_fe05c9(verbose)
    if verbose: print()
    check_sites(verbose)
    if verbose: print()
    sanity_vs_music(verbose)
    if args and args[0] == "--selftest":
        print(f"FAILURES: {len(FAIL)}")
        for f in FAIL:
            print("  FAIL:", f)
        return 1 if FAIL else 0
    if FAIL:
        print("\n⚠ CHECKS FAILED:", FAIL)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
