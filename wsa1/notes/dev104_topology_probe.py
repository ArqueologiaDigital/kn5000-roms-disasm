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
ROM_D = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_d.bin')
BASE = 0xF80000

IMG = open(ROM_C, 'rb').read()
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


def sm15(x):
    """The same word as a SIGNED value: fold(x) - 0x8000, i.e. sign-magnitude."""
    return fold(x) - 0x8000


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
    say('    -> registers 0x01C0 / 0x0200 carry fold(that word) = b0 = (a1+1)/2 = K/(1+K),')
    say('       the MATCHING FEEDFORWARD coefficient, scaled by Rise[v] in [0,1).')
    # FE05C9: same family, saturating cutoff
    a_tail = sm15(FB[127])
    check('Curve_FE05C9 tail is exactly a1 = -3/4 (-24580/32768)', a_tail, -24580)
    fmax = bilinear_f(FB[127])
    say('    Curve_FE05C9 read the same way: a1 runs %.6f .. %.6f, so its cutoff RISES to a'
        % (sm15(FB[0]) / 32768.0, a_tail / 32768.0))
    say('    CEILING of %.6f*fs = %.1f Hz at 44.1 kHz, the deficit halving every 12 steps.'
        % (fmax, fmax * 44100))
    defic = [fmax - bilinear_f(FB[i]) for i in range(10, 100)]
    ratios = [defic[k] / defic[k + 12] for k in range(0, 50, 12)]
    say('    (fmax - f)(i) / (fmax - f)(i+12) at i=10,22,34,46: %s'
        % ' '.join('%.3f' % r for r in ratios))
    check('  those ratios are all within 6% of 2', all(1.88 < r < 2.12 for r in ratios), True)
    say('    ** EXACT CLOSED FORM FOR FE05C9 IS NOT ESTABLISHED.  What is measured is that it')
    say('       is the same one-pole family with an ABSOLUTE cutoff ceiling, where FE04C9\'s')
    say('       cutoff tracks the index without limit.')


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


SECTIONS = [sec1_closed_forms, sec2_fold_is_sign_magnitude, sec3_bilinear,
            sec4_srl, sec5_pairing_null, sec6_elements_are_channels,
            sec7_tone_record_not_located, sec8_two_gains_move_apart,
            sec9_three_sections, sec10_stage_b_image]


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
