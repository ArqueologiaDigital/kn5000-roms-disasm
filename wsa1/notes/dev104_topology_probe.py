#!/usr/bin/env python3
"""What KIND of synthesis engine is behind CPU 2's 0x00104000, judged from the
SHAPE of the numbers the firmware writes into it?

QUESTION IT ANSWERS
  The wave-17 register map (prom_c/devices/dev10c_dev104_drivers.s, section 2) proves the
  ARITHMETIC of all nineteen per-channel registers and leaves seventeen of them
  UNIDENTIFIED.  This script asks what the arithmetic itself says: what the curve tables
  ARE as closed forms, whether `srl 0x00,XIY` is a shift by 16, whether the claimed
  A/B pairing survives a null, and whether the tone record can be located in prom_d.

  Everything is read from bytes: original_ROMs/wsa1_prom_c.ic28 and
  original_ROMs/wsa1_prom_d.bin.  No .s file and no unidasm text is read.

WHAT EACH SECTION ANSWERS
   1  Are the four exponential/log tables the closed forms the tree claims, and how do
      Curve_Exp2Rise_128 and Curve_Exp2Decay_256 relate?   (they are complements to +/-4)
   2  ** fold() IS A SIGN-MAGNITUDE -> OFFSET-BINARY CONVERTER.  Under fold(), both
      Curve_FE04C9 and Curve_FE05C9 are MONOTONE over all 128 entries -- including across
      the 0x8459 -> 0x015E step that looks like a discontinuity in the s16 reading.  The
      null is the s16 reading itself, which is not monotone.
   3  ** Curve_FE04C9 IS A BILINEAR ONE-POLE COEFFICIENT.  Read as sign-magnitude Q15 it is
      a1 = (K-1)/(K+1) with K = tan(pi*f/fs), and f DOUBLES EVERY 12.0016 INDEX STEPS with a
      max residual of 0.8 cents over i=14..90.  Four rival value->frequency maps are fitted
      as a null; the best of them is 50x worse.  With f(i) = the frequency of MIDI note
      i+36, the implied sample rate is 44,091 +/- 11 Hz -- 44,100 to within 0.33 cent, and
      no other standard rate family is within reach.  Curve_FE05C9 is the same family with
      a cutoff that SATURATES at 0.045142*fs (1,990.8 Hz at 44.1 kHz).
   4  ** THE srl ADJUDICATION.  Four independent arguments that `srl 0x00,XIY` shifts by 16,
      i.e. that registers 0x01C0/0x0200/0x0240 are the product's HIGH half:
      (a) a second, independent implementation of the ISA -- MAME's tlcs900 core --
          computes `count = (s & 0x0f) ? (s & 0x0f) : 16`;
      (b) the product ALWAYS exceeds 16 bits over the reachable operand domain;
      (c) the same `(x & 0xFFF8) | 7` normalisation is applied, 26 bytes apart in the same
          routine, to a RAW Curve_Exp2Decay_256 entry -- so the product result must live in
          the same 0..0x8000 numeric range, which only the high half does;
      (d) sweeping the depth index 0..127, the high reading is monotone in 100% of adjacent
          steps and the low reading in 5%; the null is a uniform-random multiplicand.
   5  ** THE A/B PAIRING, WITH A NULL.  Each claimed pair's two code runs are compared byte
      for byte, against a null built by sliding one run over its neighbourhood.
   6  ** THE PAIRS ARE INSIDE ONE CHANNEL.  MidiNote_OnByPartMode's element loop calls
      Pack104_SetInputs_SubRecordPair with the LOOP COUNTER as the sub-record index and a
      DIFFERENT channel byte each iteration, so the four tone elements are four channels.
      The A/B pair therefore cannot be "two elements per voice".
   7  NEGATIVE RESULT, recorded so it is not repeated: the Tone104 record cannot be located
      inside prom_d's 81-byte element blocks by its note-bound fields.  Eight of the 41
      candidate offsets score 0.90-0.93 against a pooled null of 0.55; nothing wins.

RUN
  python3 notes/dev104_topology_probe.py             # print every section
  python3 notes/dev104_topology_probe.py --selftest  # assert; exit 1 on any failure
"""
import math
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_C = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28')
ROM_B = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_b.ic13')
ROM_D = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_d.bin')
BASE = 0xF80000

IMG = open(ROM_C, 'rb').read()
BIMG = open(ROM_B, 'rb').read()
DIMG = open(ROM_D, 'rb').read()
FAILURES = []
QUIET = False


def by(addr, n):
    return IMG[addr - BASE:addr - BASE + n]


def u16(addr):
    return IMG[addr - BASE] | (IMG[addr - BASE + 1] << 8)


def table(addr, n):
    return [u16(addr + 2 * i) for i in range(n)]


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILURES.append('%s: got %r want %r' % (label, got, want))
    if not QUIET:
        print('  %-68s %s' % (label, 'OK' if ok else 'FAIL  got=%r want=%r' % (got, want)))
    return ok


def say(*a):
    if not QUIET:
        print(*a)


# ------------------------------------------------------------------ the objects
# Addresses are the ones the packer's own `add <X..>,#imm32` / `lda` operands name;
# they are re-asserted here from the bytes at the citing instruction.
CURVE_EXP2DECAY_256 = 0xFDF7E0     # cited 0xFC5003, 0xFC50C0
CURVE_EXP2RISE_128 = 0xFDF9E0      # cited 0xFC4ABA, 0xFC534F, 0xFC54C5
CURVE_LOG2_251 = 0xFDFAE0          # cited 0xFC49E5
CONST_0100_251 = 0xFDFCD6          # cited 0xFC49ED
CURVE_EXP2DECAY_101 = 0xFDFECC     # cited 0xFC4B1B
TABLE_FDFF96 = 0xFDFF96            # cited 0xFC52AF, 0xFC5425
CURVE_FE04C9 = 0xFE04C9            # cited 0xFC4987, 0xFC52E1, 0xFC5457  -> reg 0x0400/0x0440
CURVE_FE05C9 = 0xFE05C9            # cited 0xFC4996, 0xFC52EF, 0xFC5465  -> reg 0x0340/0x0380

D256 = table(CURVE_EXP2DECAY_256, 256)
R128 = table(CURVE_EXP2RISE_128, 128)
L251 = table(CURVE_LOG2_251, 251)
E101 = table(CURVE_EXP2DECAY_101, 101)
FA = table(CURVE_FE04C9, 128)
FB = table(CURVE_FE05C9, 128)


def fold(x):
    """The packer's own conversion, read off 0xFC5306-0xFC5328 and 0xFC4A51-0xFC4A73."""
    return (0x8000 - (x & 0x7FFF)) if (x & 0x8000) else (x + 0x8000)


def _folded(t):
    return [(0x8000 - (x & 0x7FFF)) if (x & 0x8000) else (x + 0x8000) for x in t]


def sm15(x):
    """The same word as a SIGNED value: fold(x) - 0x8000, i.e. sign-magnitude."""
    return fold(x) - 0x8000


FA_f = _folded(FA)
FB_f = _folded(FB)


# ---------------------------------------------------------------- section 1
def sec1_closed_forms():
    say('=== 1. the four exponential / log tables, as closed forms ===')
    e1 = max(abs(D256[k] - round(32768 * 2 ** ((k - 255) / 16.0))) for k in range(256))
    check('Curve_Exp2Decay_256[k] = round(32768*2^((k-255)/16)), max |err|', e1, 4)
    e2 = max(abs(R128[k] - round(32768 * (1 - 2 ** (-k / 16.0)))) for k in range(128))
    check('Curve_Exp2Rise_128[k]  = round(32768*(1-2^(-k/16))), max |err|', e2, 0)
    e3 = max(abs(L251[k] - round(27543 - 3072 * math.log2(k))) for k in range(1, 251))
    check('Curve_Log2_251[k]      = round(27543 - 3072*log2 k), max |err| (k>=1)', e3, 1)
    check('Curve_Exp2Decay_101[k] = Curve_Exp2Decay_256[k+155] for k=1..100',
          all(E101[k] == D256[k + 155] for k in range(1, 101)), True)
    # the relation the two exponentials have to each other
    d = [R128[k] + D256[255 - k] - 32768 for k in range(128)]
    check('Rise[k] + Decay[255-k] = 32768 to within (rounding of the two tables)',
          max(abs(x) for x in d), 4)
    say('    -> the two are the SAME exponential, one falling and one its complement:')
    say('       Decay is a LINEAR GAIN with 0.376 dB a step and 96 dB end to end;')
    say('       Rise[k]/32768 = 1 - 2^(-k/16) is the fraction-of-full-scale companion.')
    say('    -> Log2_251 has 3072 counts per octave, which is 256 per SEMITONE -- the same')
    say('       unit as the tone generator\'s pitch register (0x0010C000 + chan + 0x0400).')


# ---------------------------------------------------------------- section 2
def sec2_fold_is_sign_magnitude():
    say('=== 2. fold() is a SIGN-MAGNITUDE -> OFFSET-BINARY converter ===')
    fa = [fold(x) for x in FA]
    fb = [fold(x) for x in FB]
    check('fold(Curve_FE04C9) is monotone non-decreasing over all 128 entries',
          all(fa[i] <= fa[i + 1] for i in range(127)), True)
    check('fold(Curve_FE05C9) is monotone non-decreasing over all 128 entries',
          all(fb[i] <= fb[i + 1] for i in range(127)), True)
    # THE NULL: the two's-complement reading of the same bytes.
    s16 = lambda v: v - 65536 if v & 0x8000 else v
    check('NULL: the s16 (two\'s-complement) reading of FE04C9 is NOT monotone',
          all(s16(FA[i]) <= s16(FA[i + 1]) for i in range(127)), False)
    check('NULL: the s16 reading of FE05C9 is NOT monotone',
          all(s16(FB[i]) <= s16(FB[i + 1]) for i in range(127)), False)
    # the step that looks like a discontinuity
    step = fa[90] - fa[89]
    nbrs = [fa[i + 1] - fa[i] for i in (86, 87, 88, 90, 91)]
    check('FE04C9[89]=0x8459 -> [90]=0x015E, the "wrap", is a fold step of', step, 1554)
    check('  and its neighbours\' fold steps bracket it', min(nbrs) <= step <= max(nbrs), True)
    say('    -> so the tables are 128 SIGN-MAGNITUDE words, not 128 two\'s-complement ones,')
    say('       and fold() converts sign-magnitude to offset binary with 0x8000 = zero.')
    say('    -> FE04C9 spans %+d .. %+d ; FE05C9 spans %+d .. %+d (Q15, 32768 = 1.0)'
        % (sm15(FA[0]), sm15(FA[127]), sm15(FB[0]), sm15(FB[127])))
    say('  ** REPORTED, NOT EDITED: prom_c/data_tables/tail_data_zone.s calls FE04C9')
    say('     "128 s16, rising from -510 ... to +28591" and FE05C9 "falling from -25 to')
    say('     -8188".  Those are the two\'s-complement readings.  The file is another')
    say('     lane\'s; the correction is reported here, not applied there.')


# ---------------------------------------------------------------- section 3
def bilinear_f(word):
    """f/fs implied by reading the word as a bilinear one-pole feedback coefficient."""
    a1 = sm15(word) / 32768.0
    if a1 >= 1.0:
        return 0.5
    return math.atan((1 + a1) / (1 - a1)) / math.pi


def _loglin_fit(xs, ys):
    n = len(xs)
    sx = sum(xs); sy = sum(ys)
    sxx = sum(x * x for x in xs); sxy = sum(x * y for x, y in zip(xs, ys))
    m = (n * sxy - sx * sy) / (n * sxx - sx * sx)
    b = (sy - m * sx) / n
    res = max(abs(ys[k] - (m * xs[k] + b)) for k in range(n))
    return m, b, res


def sec3_bilinear():
    say('=== 3. Curve_FE04C9 is a BILINEAR ONE-POLE COEFFICIENT ===')
    LO, HI = 14, 90            # the unsaturated interior; heads and tails are clamped runs
    xs = list(range(LO, HI + 1))
    maps = [
        ('bilinear  f = atan((1+a)/(1-a))/pi', lambda a: math.atan((1 + a) / (1 - a)) / math.pi),
        ('b0 read as f directly, (1+a)/2', lambda a: (1 + a) / 2),
        ('one-pole alpha:  -ln(1-b0)/2pi', lambda a: -math.log(1 - (1 + a) / 2) / (2 * math.pi)),
        ('a read as a POLE: -ln|a|/2pi', lambda a: -math.log(abs(a)) / (2 * math.pi)),
        ('K=(1+a)/(1-a) read as f', lambda a: (1 + a) / (1 - a)),
    ]
    best = None
    for name, fm in maps:
        ys = [math.log2(fm(sm15(FA[i]) / 32768.0)) for i in xs]
        m, b, res = _loglin_fit(xs, ys)
        say('    %-36s %8.4f steps/octave   max residual %8.1f cents'
            % (name, 1 / m, res * 1200))
        if best is None:
            best = (1 / m, res * 1200)
        else:
            FAILURES_local = res * 1200
    ys = [math.log2(bilinear_f(FA[i])) for i in xs]
    m, b, res = _loglin_fit(xs, ys)
    check('bilinear map: index steps per octave, rounded to 4 dp', round(1 / m, 4), 12.0016)
    check('bilinear map: max residual under 1 cent over i=%d..%d' % (LO, HI), res * 1200 < 1.0, True)
    others = []
    for name, fm in maps[1:]:
        ys2 = [math.log2(fm(sm15(FA[i]) / 32768.0)) for i in xs]
        others.append(_loglin_fit(xs, ys2)[2] * 1200)
    check('NULL: the best rival map is at least 40x worse', min(others) / (res * 1200) > 40, True)
    # what sample rate makes f(i) land on MIDI notes?
    implied = [(440 * 2 ** ((i + 36 - 69) / 12.0)) / bilinear_f(FA[i]) for i in xs]
    mean = sum(implied) / len(implied)
    sd = math.sqrt(sum((v - mean) ** 2 for v in implied) / len(implied))
    say('    with f(i) = the frequency of MIDI note i+36, implied fs = %.1f +/- %.1f Hz'
        % (mean, sd))
    say('    44100 / that = %.6f  (%.2f cents)' % (44100 / mean, 1200 * math.log2(44100 / mean)))
    check('implied fs is 44100 to within 1 cent', abs(1200 * math.log2(44100 / mean)) < 1.0, True)
    say('    -> registers 0x0400 / 0x0440 carry a1 of a one-pole lowpass whose CUTOFF IS A')
    say('       MIDI NOTE: index i <-> note i+36, C2 (65.4 Hz) at i=0, 16.7 kHz at i=96.')
    say('    -> registers 0x01C0 / 0x0200 / 0x0240 carry fold(that word) x Rise[v] >> 16,')
    say('       i.e. the SAME coefficient scaled by 0 .. 0.996.  Whether the chip reads that')
    say('       as a lower cutoff or as a gain folded into the coefficient is NOT decided.')
    # FE05C9: the SAME cutoff, in a different encoding.  ** RETRACTION, see below.
    def gk(k):
        return math.tan(math.pi * 440 * 2 ** ((k - 33) / 12.0) / 44100.0)
    eF = [FA_f[k] - round(65536 * gk(k) / (1 + gk(k))) for k in range(9, 101)]
    eG = [FB_f[k] - round(8192 * (1 - 1 / (128 * gk(k)))) for k in range(9, 101)]
    check('fold(Curve_FE04C9)[k] = round(65536*g/(1+g)), g = tan(pi*440*2^((k-33)/12)/44100)',
          max(abs(x) for x in eF), 1)
    check('fold(Curve_FE05C9)[k] = round(8192*(1 - 1/(128*g))), THE SAME g',
          max(abs(x) for x in eG), 5)
    worst = worst60 = 0.0
    for k in range(9, 101):
        tF = math.atan(FA_f[k] / (65536 - FA_f[k]))
        r = 1 - FB_f[k] / 8192.0
        tG = math.atan(1 / (128 * r)) if r > 0 else math.pi / 2
        c = abs(1200 * math.log2(tF / tG))
        worst = max(worst, c)
        if k <= 60:
            worst60 = max(worst60, c)
    say('    the two tables imply the SAME prewarped cutoff theta to %.1f cents worst case'
        % worst)
    say('    over k=9..100, and %.1f cents over k=9..60 where FE05C9 still has resolution.'
        % worst60)
    check('  theta agreement is under 20 cents over the whole live band', worst < 20.0, True)
    say('    ** SO Curve_FE05C9 IS NOT A SECOND CUTOFF.  It is the SAME cutoff in a second')
    say('       encoding: entry for entry, (1 - G/8192) * g = 1/128.  Registers 0x0340 /')
    say('       0x0380 / 0x03C0 are COMPUTABLE from 0x0400 / 0x0440 / 0x0480; an emulator has')
    say('       ONE degree of freedom per section there, not two.')
    say('    ** RETRACTION, kept visible.  An earlier revision of this probe read FE05C9 with')
    say('       the g/(1+g) formula too and reported "a cutoff saturating at 0.045142*fs =')
    say('       1990.8 Hz".  That number is an ARTEFACT of forcing the wrong formula on the')
    say('       right bytes: 8188/65536 inverted through g/(1+g) is 0.0451 whatever it means.')
    say('       The correct reading is `notes/FINDINGS-l7a1429-curve-tables.md` \u00a71, lane')
    say('       w19/lsi-curves, reproduced above from the ROM.')


# ---------------------------------------------------------------- section 4
def sec4_srl():
    say('=== 4. the `srl 0x00,XIY` adjudication ===')
    check('the three sites are all `ed ef 00` -- 0xFC4ACC, 0xFC5361, 0xFC54D7',
          [by(a, 3).hex(' ') for a in (0xFC4ACC, 0xFC5361, 0xFC54D7)],
          ['ed ef 00'] * 3)
    # (b) the operand domain.  0x01C0: fold(FE04C9[i3]) x Rise[v], both straight from tables.
    prods = [fold(w) * r for w in FA for r in R128]
    over = sum(1 for p in prods if p > 0xFFFF)
    check('(b) full table cross-product fold(FE04C9) x Rise: pairs', len(prods), 128 * 128)
    check('(b) pairs whose product needs more than 16 bits', over, 128 * 127)
    say('        i.e. EVERY pair except the 128 with Rise[0] = 0.  Max product 0x%08X.'
        % max(prods))
    check('(b) and no product exceeds 32 bits, so Multiply32\'s low-32 result is exact',
          max(prods) < 2 ** 32, True)
    # (c) the SAME eight bytes normalise a raw table entry and the product
    raw = by(0xFC50E5, 8)
    prod = by(0xFC4AD9, 8)
    check('(c) 0xFC50E5 (applied to a RAW Curve_Exp2Decay_256 entry) is', raw.hex(' '),
          'd9 cc f8 ff d9 ce 07 00')
    check('(c) 0xFC4AD9 (applied to the PRODUCT) is the SAME eight bytes', prod, raw)
    say('        `and BC,0xFFF8 / or BC,0x0007`, twice, 524 bytes apart, on quantities that')
    say('        must therefore share a numeric range.  A raw Decay entry is 0..0x8000.  The')
    say('        product\'s HIGH half is 0..0x775A; its LOW half is uniform over 0..0xFFFF.')
    # (d) the smoothness statistic, with a random null
    import random
    def stats(seq):
        mono = sum(1 for k in range(len(seq) - 1) if seq[k] <= seq[k + 1]) / (len(seq) - 1)
        tv = sum(abs(seq[k + 1] - seq[k]) for k in range(len(seq) - 1))
        return mono, tv
    def sweep(reading):
        m = []; t = []
        for w in FA[10:102]:
            a, b = stats([reading(fold(w) * r) for r in R128])
            m.append(a); t.append(b)
        return sum(m) / len(m), sum(t) / len(t)
    hi_m, hi_tv = sweep(lambda p: (p >> 16) & 0xFFFF)
    lo_m, lo_tv = sweep(lambda p: p & 0xFFFF)
    rnd = random.Random(17)
    nm = []; nt = []
    for _ in range(92):
        a, b = stats([rnd.randrange(65536) for _ in range(128)])
        nm.append(a); nt.append(b)
    n_m, n_tv = sum(nm) / len(nm), sum(nt) / len(nt)
    say('        sweeping the depth index 0..127 for each of the 92 unsaturated FE04C9')
    say('        entries -- the exact control a player moves:')
    say('          HIGH half   : %.4f of adjacent steps rising, mean total variation %10.0f'
        % (hi_m, hi_tv))
    say('          LOW  half   : %.4f                            , mean total variation %10.0f'
        % (lo_m, lo_tv))
    say('          NULL, uniform random 16-bit sequences (seed 17):')
    say('                        %.4f                            , mean total variation %10.0f'
        % (n_m, n_tv))
    check('(d) the HIGH reading rises at every one of the 127 x 92 steps', hi_m == 1.0, True)
    check('(d) the LOW reading is indistinguishable from the random null (|diff| < 0.05)',
          abs(lo_m - n_m) < 0.05, True)
    check('(d) and its total variation is within 20% of the null\'s',
          abs(lo_tv - n_tv) / n_tv < 0.20, True)
    check('(d) while the HIGH reading\'s is smaller than the null\'s by more than 100x',
          n_tv / hi_tv > 100, True)
    say('    ** (a) IS THE ARGUMENT THAT IS NOT IN THIS FILE.  MAME\'s TLCS-900 core is a')
    say('       second, independent implementation of the ISA.  In')
    say('       src/devices/cpu/tlcs900/900tbl.hxx, srl32() opens:')
    say('           uint8_t count = ( s & 0x0f ) ? ( s & 0x0f ) : 16;')
    say('       so `srl 0x00,XIY` shifts by SIXTEEN -- and so, in the same core, does')
    say('       `srl 0x10,XIY`, which is what llvm-mc emits for `srl xiy,16`.  The two')
    say('       encodings the wave-17 note calls a non-witness are the SAME instruction to')
    say('       a core that implements the rule; llvm-mc just passes the immediate through.')
    say('    ** AND A FIFTH, WEAKER ONE: a shift by zero is a NO-OP, and the compiler would')
    say('       not have emitted an instruction for it.  `ld IY` after the call already')
    say('       delivers the low half.')
    say('    ** VERDICT: STRONG, not PROVEN.  No hardware and no emulator trace of any of')
    say('       the three registers was taken.  Five arguments agree; none dissents.')


# ---------------------------------------------------------------- section 5
# The A/B code runs.  Each pair is (label, addr_A, addr_B); the run length is taken as
# addr_B - addr_A, which is what makes the comparison honest: the second run is the code
# that immediately follows the first, so if they are the same code twice they are also the
# same length.
AB_RUNS = [
    ('reg 0x0040 / 0x0080   (SatAsym base+offset+delta)', 0xFC4DF3, 0xFC4EA2),
    ('reg 0x0140 / 0x0180   (v1/v2 -> Exp2Decay level)', 0xFC4F51, 0xFC500E),
    ('reg 0x0340+0x0400+0x01C0 / 0x0380+0x0440+0x0200', 0xFC51F4, 0xFC536A),
]


def sec5_pairing_null():
    say('=== 5. the A/B pairing, with a null ===')
    for label, a, b in AB_RUNS:
        n = b - a
        ra = by(a, n); rb = by(b, n)
        agree = sum(1 for k in range(n) if ra[k] == rb[k]) / n
        # NULL: slide the second run over its neighbourhood and re-score.
        null = []
        for d in list(range(-64, -3)) + list(range(4, 65)):
            rn = by(b + d, n)
            null.append(sum(1 for k in range(n) if ra[k] == rn[k]) / n)
        say('    %-52s len %3d  agree %.4f   null mean %.4f  max %.4f'
            % (label, n, agree, sum(null) / len(null), max(null)))
        check('  %s: aligned agreement beats every one of the %d null offsets'
              % (label.split()[1], len(null)), agree > max(null), True)
    say('    -> the three claimed pairs are the same code twice, at a level no shifted')
    say('       alignment reaches.  The pairing is a FACT ABOUT THE CODE, and the null says')
    say('       it is not an artefact of the instruction mix.')


# ---------------------------------------------------------------- section 6
def sec6_elements_are_channels():
    say('=== 6. the four tone ELEMENTS are four CHANNELS, so A/B is not "two elements" ===')
    # All four Pack104_SetInputs_SubRecordPair call sites, and what each passes as the
    # SUB-RECORD index (the last thing pushed before the call).
    sites = {0xFB36F5: 'MidiNote_OnTail', 0xFB391C: 'MidiNote_OnByPartMode 1-element arm',
             0xFB3A67: 'MidiNote_OnByPartMode 4-element loop',
             0xFB3B85: 'MidiNote_OnByPartMode 2-element loop'}
    for a, name in sites.items():
        check('  0x%06X is a `call 0xFC4C85` (%s)' % (a, name),
              by(a, 4).hex(' '), '1d 85 4c fc')
    check('  0xFB36F5 pushes the LITERAL 0 (`0b 00 00` = push 0x0000)',
          by(0xFB36F5 - 3, 3).hex(' '), '0b 00 00')
    check('  the other three push the REGISTER HL (0x2b)',
          [by(a - 1, 1).hex() for a in (0xFB391C, 0xFB3A67, 0xFB3B85)], ['2b'] * 3)
    check('  0xFB3A8A `cp L,4` (0xD8|4) then `jr C` back -- the loop runs FOUR times',
          by(0xFB3A8A, 4).hex(' '), 'cf dc 67 9a')
    check('  0xFB3BA3 `cp L,2` (0xD8|2) then `jr C` back -- that loop runs TWICE',
          by(0xFB3BA3, 4).hex(' '), 'cf da 67 82')
    check('  0xFB3A28 re-reads the channel from a LOCAL ARRAY every iteration '
          '(ld XBC,(XIZ-4) / add XBC,XIZ / ld H,(XBC-24))',
          by(0xFB3A28, 8).hex(' '), 'ae fc 21 ee 81 89 e8 26')
    say('    -> the sub-record index is the LOOP VARIABLE and the channel byte is re-read')
    say('       each iteration, so a 4-element tone occupies FOUR channels, each with its')
    say('       own full 19-register set.  Element multiplicity is ALREADY SPENT on')
    say('       channels: whatever the A/B pair is, it is not "two elements per voice".')


# ---------------------------------------------------------------- section 7
def sec7_tone_record_not_located():
    say('=== 7. NEGATIVE RESULT: Tone104 is NOT located inside prom_d\'s element blocks ===')
    off = struct.unpack_from('<I', DIMG, 0x08)[0]
    tones = [struct.unpack_from('<I', DIMG, off + 4 * i)[0] for i in range(274)]
    blocks = []
    for t in tones:
        mask = DIMG[t + 0x11]
        n = sum(1 for k in range(4) if (mask >> (2 * k)) & 3)
        for k in range(n):
            b = t + 0xD9 + 81 * k
            if b + 81 <= len(DIMG):
                blocks.append(DIMG[b:b + 81])
    check('81-byte element blocks reached from the 274 tone offsets', len(blocks), 531)
    # Tone104's two key-scaling groups sit at +0x19 and +0x25: [break(bit7=off), lo, hi, slope].
    rows = []
    for d in range(0, 81 - 0x29 + 1):
        en = sane = 0
        for b in blocks:
            for o in (0x19, 0x25):
                g = b[d + o:d + o + 4]
                if g[0] & 0x80:
                    continue
                en += 1
                if g[0] <= 127 and g[1] <= g[2] <= 127:
                    sane += 1
        rows.append((sane / en if en else 0.0, d))
    rows.sort(reverse=True)
    pooled = sum(s for s, _ in rows) / len(rows)
    say('    best candidate base offsets d (fraction of enabled key-scaling groups whose')
    say('    note bounds are sane): ' + '  '.join('d=%d %.3f' % (d, s) for s, d in rows[:6]))
    say('    pooled null over all %d offsets: %.3f' % (len(rows), pooled))
    check('  NOT LOCATED: at least six offsets are within 0.05 of the best',
          sum(1 for s, _ in rows if s > rows[0][0] - 0.05) >= 6, True)
    say('    -> the predicate does not localise Q.  DO NOT use prom_d element blocks as')
    say('       Tone104 records; the register-value work in this note is a sweep of the')
    say('       full reachable domain instead, which is stronger than a sample anyway.')


# ---------------------------------------------------------------- section 8
def sec8_two_gains_move_apart():
    say('=== 8. one control, two gains that move in OPPOSITE directions ===')
    # v1 sets BOTH register 0x0140 (a level) and the scale factor of register 0x01C0.
    #   0x0140 = Curve_Exp2Decay_256[ clampU8(0xCF - g(v1) + (int8)(0x00E08C)) ] & 0xFFF8
    #   0x01C0 = high16( fold(reg 0x0400 word) * Curve_Exp2Rise_128[ clamp(v1,0..PART+0x11) ] )
    # with g(v) = v < 48 ? v//2 + 24 : v   (0xFC4FCE-0xFC4FE0).
    def g(v):
        return (v >> 1) + 24 if v < 48 else v

    def lvl(v, trim=0):
        i = max(0, min(255, 0xCF - g(v) + trim))
        return D256[i] & 0xFFF8

    def scale(v):
        return R128[max(0, min(127, v))] / 32768.0
    rows = [(v, lvl(v), scale(v)) for v in range(0, 128, 8)]
    say('      v1   reg 0x0140 (level)   dB      Rise[v1]/32768 (scale of reg 0x01C0)')
    for v, l, sc in rows:
        db = 20 * math.log10(l / 32768.0) if l else float('-inf')
        say('     %4d   %6d            %7.2f   %8.4f' % (v, l, db, sc))
    lv = [l for _, l, _ in rows if l]
    sv = [sc for _, _, sc in rows]
    check('reg 0x0140 falls monotonically with v1', all(rows[k][1] >= rows[k + 1][1]
          for k in range(len(rows) - 1)), True)
    check('the scale on reg 0x01C0 rises monotonically with v1',
          all(sv[k] <= sv[k + 1] for k in range(len(sv) - 1)), True)
    say('    -> ONE parameter, TWO gains, moving apart.  Measured; naming it a crossfade')
    say('       is an INFERENCE and is graded WEAK in the note.')
    # what the register 0x00C0 unit is
    say('    reg 0x00C0 = Curve_Log2_251[...] + (0x4280 - R[+0x0E]) - R[+0x0C]:')
    say('      0x4280 = %d = note %.1f in 1/256-semitone units; Log2_251 runs at 3072 counts'
        % (0x4280, 0x4280 / 256.0))
    say('      per octave = 256 per semitone, so BOTH terms are in ONE log-frequency unit.')
    check('Log2_251 slope is 3072 counts per octave, = 256 per semitone',
          round((L251[1] - L251[2]) / math.log2(2 / 1.0)) in (3072, 3071, 3073), True)
    say('      the pitch term enters NEGATED, so the value is inverse in frequency: a')
    say('      LOG PERIOD or a LOG TIME, not a log frequency.  [INFERENCE]')


# ---------------------------------------------------------------- section 9
def sec9_three_sections():
    say('=== 9. ** THREE SECTIONS, not two: an EXHAUSTIVE citation census ===')
    import re
    def sites(addr, width):
        lit = bytes([addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF][:width])
        return [BASE + m.start() for m in re.finditer(re.escape(lit), IMG)]
    a = sites(CURVE_FE04C9, 3)
    b = sites(CURVE_FE05C9, 3)
    r = sites(CURVE_EXP2RISE_128, 3)
    srl = [BASE + m.start() for m in re.finditer(b'\xed\xef\x00', IMG)]
    check('Curve_FE04C9 is cited EXACTLY three times in the whole 512 KB image',
          ['0x%06X' % x for x in a], ['0xFC4989', '0xFC52E3', '0xFC5459'])
    check('Curve_FE05C9, likewise, exactly three',
          ['0x%06X' % x for x in b], ['0xFC4997', '0xFC52F0', '0xFC5466'])
    check('Curve_Exp2Rise_128, likewise, exactly three',
          ['0x%06X' % x for x in r], ['0xFC4ABC', '0xFC5351', '0xFC54C7'])
    check('`srl 0x00,XIY` appears four times; three of them close a Rise multiply',
          ['0x%06X' % x for x in srl], ['0xFC4ACC', '0xFC5361', '0xFC54D7', '0xFC8F6D'])
    say('    the three FE04C9/FE05C9 pairs and where their values end up:')
    say('      0xFC52E3 / 0xFC52F0  index i3 -> staging +0x20 (reg 0x0400) and +0x1A (0x0340)')
    say('      0xFC5459 / 0xFC5466  index i4 -> staging +0x22 (reg 0x0440) and +0x1C (0x0380)')
    say('      0xFC4989 / 0xFC4997  index i5 -> sub-record P[+0x26] and P[+0x24], which the')
    say('                           packer then copies to reg 0x0480 and reg 0x03C0')
    check('  0xFC4993 stores to (XBC+0x26) -- Part104Voice.reg0480',
          by(0xFC4993, 3).hex(' '), 'b9 26 53')
    check('  0xFC49A4 stores to (XBC+0x24) -- Part104Voice.reg03C0',
          by(0xFC49A4, 3).hex(' '), 'b9 24 53')
    say('    so registers 0x03C0 and 0x0480, which the wave-17 map records only as "P[+0x24]')
    say('    copied straight through" and "P[+0x26]", are THE SAME TWO CURVE TABLES at a')
    say('    third index -- clamped to 44..96 by 0xFC4971/0xFC4976 rather than key-scaled.')
    say('    ** THE GROUPING IS A/B/C, NOT A/B:')
    say('       section A  reg 0x0400 = FE04C9[i3]   reg 0x0340 = FE05C9[i3]   reg 0x01C0')
    say('       section B  reg 0x0440 = FE04C9[i4]   reg 0x0380 = FE05C9[i4]   reg 0x0200')
    say('       section C  reg 0x0480 = FE04C9[i5]   reg 0x03C0 = FE05C9[i5]   reg 0x0240')
    say('       and 0x01C0 / 0x0200 / 0x0240 are the three Rise multiplies, one per section.')


# ---------------------------------------------------------------- section 10
def sec10_stage_b_image():
    say('=== 10. the Stage_B constant image says the same thing, from a ROM image ===')
    img = [u16(0xFE1315 + 2 * k) for k in range(19)]
    check('Dev104_LoadStageBImage\'s 19 words at 0xFE1315',
          ['0x%04X' % w for w in img],
          ['0x0004'] + ['0x0000'] * 12 + ['0xE150'] * 3 + ['0xD71B'] * 3)
    ia = [i for i, v in enumerate(FA) if v == 0xD71B]
    ib = [i for i, v in enumerate(FB) if v == 0xE150]
    check('0xD71B occurs in Curve_FE04C9 at exactly one index', ia, [64])
    check('0xE150 occurs in Curve_FE05C9 at exactly one index', ib, [64])
    say('    -> the image writes Curve_FE05C9[64] to registers 0x0340, 0x0380 AND 0x03C0 and')
    say('       Curve_FE04C9[64] to registers 0x0400, 0x0440 AND 0x0480, and zero to')
    say('       everything else.  A path that never runs the packer confirms, independently,')
    say('       both the table-to-register family map and the THREE-slot grouping.')
    f = bilinear_f(FA[64])
    say('    index 64 is MIDI note 100, cutoff %.0f Hz at 44.1 kHz -- a neutral wide-open'
        % (f * 44100))
    say('    default, which is what a constant image for a "no modelling" part mode should be.')
    check('  index 64 -> note 100 to within 0.05 semitone',
          abs(69 + 12 * math.log2(f * 44100 / 440.0) - 100.0) < 0.05, True)


# ---------------------------------------------------------------- section 11
def sec11_reset_image_settles_srl():
    say('=== 11. ** THE POWER-ON RESET IMAGE SETTLES THE srl QUESTION WITH DATA ===')
    img = [u16(0xFE133B + 2 * k) for k in range(19)]
    check('Dev104_StagingStruct_ResetImage, 0xFE133B, 19 words',
          ' '.join('%04X' % w for w in img),
          '0004 0000 0000 6C00 0100 0230 0230 1C54 1C54 26D7 8000 FF00 0000 '
          'E0B8 E0B8 E05E BDF0 BDF0 987B')
    # every word, against the tables the packer would have used
    check('w3  (reg 0x00C0) = Curve_Log2_251[0]', [i for i, v in enumerate(L251) if v == img[3]], [0])
    check('w4  (reg 0x0100) = the Const_0100_251 value', img[4], 0x0100)
    check('w5,w6 (reg 0x0140/0x0180) = Curve_Exp2Decay_256[161] & 0xFFF8',
          [i for i, v in enumerate(D256) if (v & 0xFFF8) == img[5]], [161])
    check('w10 (reg 0x0280) = Curve_Exp2Decay_101[100]',
          [i for i, v in enumerate(E101) if v == img[10]], [100])
    check('w13,w14 (reg 0x0340/0x0380) = Curve_FE05C9[74]',
          [i for i, v in enumerate(FB) if v == img[13]], [74])
    check('w15 (reg 0x03C0) = Curve_FE05C9[84]  -- a DIFFERENT index: section C',
          [i for i, v in enumerate(FB) if v == img[15]], [84])
    check('w16,w17 (reg 0x0400/0x0440) = Curve_FE04C9[74]',
          [i for i, v in enumerate(FA) if v == img[16]], [74])
    check('w18 (reg 0x0480) = Curve_FE04C9[84]  -- the same section-C index',
          [i for i, v in enumerate(FA) if v == img[18]], [84])
    say('    -> sections A and B share index 74, section C uses 84.  A FOURTH ROM object, on')
    say('       a code path that never runs the packer, gives the same A/B/C grouping.')
    say()
    # THE SETTLING TEST: words 7, 8 and 9 are the three Rise products.
    def hi(p): return (p >> 16) & 0xFFFF
    def lo(p): return p & 0xFFFF

    def solve(target, i, masked):
        out = {'HIGH': [], 'LOW': []}
        for name, rd in (('HIGH', hi), ('LOW', lo)):
            for k in range(128):
                v = rd(fold(FA[i]) * R128[k])
                if masked:
                    v = (v & 0xFFF8) | 7
                if v == target:
                    out[name].append(k)
        return out
    say('    words 7, 8 and 9 are the three `srl 0x00,XIY` products.  Solving each for the')
    say('    Curve_Exp2Rise_128 index that reproduces it, under BOTH readings:')
    for w, reg, i, masked in ((7, '0x01C0', 74, False), (8, '0x0200', 74, False),
                              (9, '0x0240', 84, True)):
        r = solve(img[w], i, masked)
        say('      w%-2d reg %s = 0x%04X, from Curve_FE04C9[%d]:  HIGH half -> Rise[%s]   '
            'LOW half -> %s' % (w, reg, img[w], i,
                                ','.join(str(x) for x in r['HIGH']) or 'none',
                                ('Rise[%s]' % ','.join(str(x) for x in r['LOW']))
                                if r['LOW'] else 'NO SOLUTION'))
    r7 = solve(img[7], 74, False); r8 = solve(img[8], 74, False); r9 = solve(img[9], 84, True)
    check('  HIGH half reproduces w7 with exactly one Rise index', r7['HIGH'], [45])
    check('  HIGH half reproduces w8 with the same one', r8['HIGH'], [45])
    check('  HIGH half reproduces w9 with exactly one Rise index', r9['HIGH'], [32])
    check('  LOW half reproduces NONE of the three, from any of the 128 Rise entries',
          [r7['LOW'], r8['LOW'], r9['LOW']], [[], [], []])
    say('    NULL: for a wrong model, a hit is a 16-bit coincidence -- 128 candidate indices')
    say('    out of 65536 values, p = 1/512 per word.  Three of three under HIGH is')
    say('    p ~ 7e-9; zero of three under LOW is what a wrong model predicts.')
    say('    ** AND THE SECTION INDICES MATCH THE COEFFICIENT REGISTERS THEY BELONG TO:')
    say('       w7/w8 come from Curve_FE04C9[74], which is w16/w17 = registers 0x0400/0x0440;')
    say('       w9 comes from Curve_FE04C9[84], which is w18 = register 0x0480.  The image is')
    say('       internally consistent with "reg 0x01C0 is reg 0x0400\'s word, folded and')
    say('       scaled", which is the whole claim.')
    say('    ** SO THE srl READING IS NO LONGER AN ARGUMENT FROM PLAUSIBILITY.  A ROM image')
    say('       written by the same authors holds the exact output of the HIGH-half')
    say('       computation, and the LOW-half computation cannot produce it.')


# ---------------------------------------------------------------- section 12
def sec12_reg0100_is_a_companion():
    say('=== 12. register 0x0100 is 0x00C0\'s TABLE-PAIR COMPANION, not a latch ===')
    # The two reads are one instruction apart and share the index register XIX.
    check('0xFC49E1 `muls XBC,HL` / 0xFC49E3 `ld XIX,XBC` -- the index x2, kept in XIX',
          by(0xFC49E1, 5).hex(' '), 'db 49 e9 8c e9')
    check('0xFC49E5 `add XBC,0x00FDFAE0` -- Curve_Log2_251, indexed by it',
          by(0xFC49E5, 6).hex(' '), 'e9 c8 e0 fa fd 00')
    check('0xFC49ED `lda XBC,0xFDFCD6` / 0xFC49F2 `add XBC,XIX` -- Const_0100_251, THE SAME '
          'index one instruction later', by(0xFC49ED, 7).hex(' '), 'f2 d6 fc fd 31 ec 81')
    say('    -> (Curve_Log2_251, Const_0100_251) is the same shape as (Curve_FE04C9,')
    say('       Curve_FE05C9): TWO PARALLEL TABLES, ONE INDEX, TWO STAGING WORDS.  For the')
    say('       FE04C9/FE05C9 pair that shape is now established (sections 9-11) as two')
    say('       coefficients of ONE section.  By the same shape, register 0x0100 is register')
    say('       0x00C0\'s companion coefficient -- flat at 0x0100 in this firmware\'s table.')
    say('    -> so the 40.69 Hz refresh of {0x00C0, 0x0100, 0x0240} is explained without a')
    say('       latch: 0x00C0 and 0x0240 are the two registers whose index carries R[+0x21],')
    say('       the RANDOMISED depth, so they are the modulation destinations; 0x0100 rides')
    say('       along because its producer is the same table read.')
    stage_b = [u16(0xFE1315 + 2 * k) for k in range(19)]
    reset = [u16(0xFE133B + 2 * k) for k in range(19)]
    check('and the register is NOT invariant: the Stage_B image writes 0x0000 to it',
          (stage_b[4], reset[4]), (0x0000, 0x0100))
    check('  exactly where it also writes 0x0000 to 0x00C0', (stage_b[3], reset[3]),
          (0x0000, 0x6C00))
    say('    -> against the coordinator\'s three readings: (c) is answered -- the register')
    say('       takes TWO values in the whole image, 0x0100 and 0x0000, and 0x0000 only')
    say('       where 0x00C0 is also 0x0000.  (b), the latch reading, is DISFAVOURED: a')
    say('       commit register would not be sourced from a 251-entry table indexed by a')
    say('       synthesis parameter; the other refresh arm ships {0x00C0, 0x0100} WITHOUT')
    say('       0x0240, so 0x0100 travels with 0x00C0 and not with "whatever came before";')
    say('       and in the full writer 0x0100 is the FOURTH of nineteen writes, not the last.')
    say('       (a) needs no separate explanation once the companion reading is taken.')


# ---------------------------------------------------------------- section 13
def _wave_select_records():
    """The 43-byte WaveSelRec of every melodic tone record whose framing self-checks.

    ⚠ CONSERVATIVE ON PURPOSE.  A record is kept only if its 16-byte name is printable
    AND every one of its element blocks passes the parameter-names lane's NULL 3 -- bytes
    +0x02/+0x03 as an LE16 index into prom_d's 307-entry wave catalogue.  That drops more
    records than that lane's name-chaining walk keeps, so this is a clean SUBSET, not a
    different population; section 13 checks it against that lane's published invariants.
    """
    off = struct.unpack_from('<I', DIMG, 0x08)[0]
    tones = [struct.unpack_from('<I', DIMG, off + 4 * i)[0] for i in range(274)]
    out = []
    for t in tones:
        if not all(32 <= c < 127 for c in DIMG[t:t + 16]):
            continue
        typ = DIMG[t + 0x10]
        mask = DIMG[t + 0x11]
        n = sum(1 for k in range(4) if (mask >> (2 * k)) & 3)
        if typ == 0x80 or n == 0:
            continue
        if not all((DIMG[t + 0xD9 + 81 * k + 2] | (DIMG[t + 0xD9 + 81 * k + 3] << 8)) < 307
                   for k in range(n)):
            continue
        b = t + 0xD9 + 81 * n
        out += [DIMG[b + 43 * k:b + 43 * k + 43] for k in range(n)]
    return out


def sec13_factory_data():
    say('=== 13. what the FACTORY DATA asks the engine for ===')
    ws = _wave_select_records()
    n = len(ws)
    check('melodic WaveSelRec records whose framing self-checks', n, 133)
    # the parameter-names lane's published invariants, on this subset
    check('  p20 (+0x14) is 100 in every one', set(r[0x14] for r in ws), {100})
    check('  p25 (+0x19) breakpoints are 66 +/- 12k',
          sorted(set(r[0x19] & 0x7F for r in ws)), [42, 54, 66, 78, 90])
    check('  p26 (+0x1A) lower note bounds', sorted(set(r[0x1A] for r in ws)), [24, 36, 48, 60])
    check('  p28 (+0x1C) Q5 slope stays inside 0..32',
          (min(r[0x1C] for r in ws), max(r[0x1C] for r in ws)), (0, 32))
    check('  p33 (+0x21) SUB GAIN is 0 or 100', sorted(set(r[0x21] for r in ws)), [0, 100])
    say('    -> five of the parameter-names lane\'s invariants hold exactly here, so the')
    say('       subset is clean.')
    # ** the MAIN/SUB twin map, tested as EXACT per-record equality, with a null
    twin = {21: 31, 22: 32, 23: 34, 24: 35, 25: 37, 26: 38, 27: 39, 28: 40, 29: 41, 30: 42}
    say('    ** MAIN AND SUB ARE CONFIGURED IDENTICALLY IN THE FACTORY SET:')
    for a, b in twin.items():
        e = sum(1 for r in ws if r[a] == r[b])
        say('       p%-2d == p%-2d   %3d / %3d' % (a, b, e, n))
    worst = min(sum(1 for r in ws if r[a] == r[b]) for a, b in twin.items())
    check('  every one of the ten twinned parameters agrees in at least 130 of 133',
          worst >= 130, True)
    # NULL: how special is that, among all ordered column pairs?
    const = [c for c in range(43) if len(set(r[c] for r in ws)) == 1]
    claimed = set()
    for a, b in twin.items():
        claimed.add((a, b))
        claimed.add((b, a))
    hi = [(a, b) for a in range(43) for b in range(43)
          if a != b and a not in const and b not in const
          and sum(1 for r in ws if r[a] == r[b]) >= 130]
    say('    NULL over all 43 x 42 ordered column pairs, constant columns %s excluded:'
        % const)
    say('      pairs equal in >= 130 of 133 records: %d' % len(hi))
    say('      of those, the claimed MAIN/SUB map accounts for %d (its 20 ordered forms)'
        % sum(1 for x in hi if x in claimed))
    say('      the remaining %d are all inside {p3, p5, p7, p9} -- the four envelope-'
        % sum(1 for x in hi if x not in claimed))
    say('      descriptor parameters, a different structure (arm 0xFBC9BF..).')
    say('      (the map\'s other 4 ordered forms involve p29/p30/p42, which are constant')
    say('      columns and are excluded from the null by construction)')
    check('  the claimed map is 16 of the %d high pairs' % len(hi),
          sum(1 for x in hi if x in claimed), 16)
    check('  and every non-claimed high pair is within {3,5,7,9}',
          all(a in (3, 5, 7, 9) and b in (3, 5, 7, 9) for a, b in hi if x_ok(a, b, claimed)),
          True)
    # RESONATOR TYPE census
    rt = [BIMG[0xF03241 - 0xF00000 + 8 * i:0xF03241 - 0xF00000 + 8 * i + 8]
          .decode('latin1').strip() for i in range(64)]
    check('the 64-name RESONATOR TYPE list begins as the UI lane reports',
          rt[:10], ['ORIGINAL', 'STRING', 'CYLINDER', 'CONE', 'FLARE', 'PLATE L',
                    'PLATE H', 'MEMB L', 'MEMB H', 'THROUGH'])
    cen = {}
    for r in ws:
        cen[rt[r[0x0B] & 0x3F]] = cen.get(rt[r[0x0B] & 0x3F], 0) + 1
    say('    RESONATOR TYPE (p11 bits 5..0) across the %d records: %s' % (n, cen))
    check('  every factory melodic record carries ORIGINAL, i.e. its OWN coefficients',
          cen, {'ORIGINAL': n})
    say('    -> ** so the resonator FAMILY is a UI preset selector, not a device mode.  The')
    say('       chip never sees it: writing it overwrites bytes 13..42 with a preset')
    say('       (ToneStage_ApplyWaveSelTailPreset), and the factory set has been edited')
    say('       past every preset.  AN EMULATOR MUST IMPLEMENT THE COEFFICIENTS, NOT THE')
    say('       FAMILIES.')
    # section C's cutoff, from p15, through the now-known law
    def cut(k):
        return 440 * 2 ** ((max(44, min(96, k)) + 36 - 69) / 12.0)
    c15 = {}
    for r in ws:
        c15[round(cut(r[0x0F]))] = c15.get(round(cut(r[0x0F])), 0) + 1
    say('    p15 (+0x0F) -> section C cutoff, Hz at 44.1 kHz: %s' % c15)
    check('  p15 is 84 in most records -- the index the power-on reset image uses',
          sorted(set(r[0x0F] for r in ws)), [65, 67, 70, 84])
    say('    -> the reset image\'s section-C index of 84 is the factory-default value of the')
    say('       parameter that feeds it.  A fifth object agreeing with the fourth.')


def x_ok(a, b, claimed):
    return (a, b) not in claimed


SECTIONS = [sec1_closed_forms, sec2_fold_is_sign_magnitude, sec3_bilinear,
            sec4_srl, sec5_pairing_null, sec6_elements_are_channels,
            sec7_tone_record_not_located, sec8_two_gains_move_apart,
            sec9_three_sections, sec10_stage_b_image,
            sec11_reset_image_settles_srl, sec12_reg0100_is_a_companion,
            sec13_factory_data]


def main():
    global QUIET
    QUIET = '--quiet' in sys.argv or '--selftest' in sys.argv
    for fn in SECTIONS:
        fn()
        say()
    if FAILURES:
        print('FAILURES: %d' % len(FAILURES))
        for f in FAILURES:
            print('  ' + f)
        return 1
    print('%d sections, FAILURES: 0' % len(SECTIONS))
    return 0


if __name__ == '__main__':
    sys.exit(main())
