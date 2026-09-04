#!/usr/bin/env python3
"""Is the ABSOLUTE SCALE of the L7A1429's `POSITION` register (chan+0x00C0) in the ROM?

QUESTION IT ANSWERS
  notes/HLE-GUIDE-l7a1429.md section 8.1 calls the constant that turns register
  chan+0x00C0 into a time "the single most valuable missing number".  This script asks
  whether the four ROM images contain it, and answers NO -- but it also shows that the
  register is a much more constrained object than the guide says, and it reduces the
  missing number from "an unknown scale in samples" to ONE DIMENSIONLESS CONSTANT.

  ★ THE THREE RESULTS TO CHECK FIRST
    1. `Curve_Position_Log2Period_251[k] = round(3072 * log2(500/k))` for EVERY one of
       k = 1..250, with residual ZERO -- strictly better than the published
       `round(27543 - 3072*log2 k)`, whose residual is 1.  So the table's constant is
       the integer 500, not the integer 27543.  And the editor draws the control as
       `p13/5`, so 500/k = 100/POSITION: the register carries log2(100/POSITION).
    2. `0x4280` is MIDI note **66 exactly**, not 66.5.  The pitch word is seeded
       `note*256 + 0x80` (0xFA7F3A-0xFA7F4B), so `0x4280 - pitch = 256*(66 - note)`, a
       whole number of semitones.  Note 66 is KEY 30 of the WSA1's own 61-key C2..C7
       compass -- its exact centre -- and the compass's bottom key is MIDI 36, the same
       36 that is the `MUTING` curve's index offset.
    3. Therefore, up to one dimensionless constant `g`,
           tap delay = g * (period of the sounding note) / POSITION     (FORMANT = MOVE)
           tap delay = g * (100 / POSITION) * P66 samples               (FORMANT = FIX)
       and `g` is NOWHERE IN THE IMAGE.  Section 7 states what was tested; section 8
       searches the images for it and computes the null; section 9 is the POSITIVE
       CONTROL that says the search would have found it if it were there.

  ⚠ A NEGATIVE.  The chip's scale is a property of the SILICON.  The firmware never
  reads this device back (2,642 writes, zero reads), so nothing in the image is
  obliged to know it, and nothing does.

RUN
  python3 notes/l7a1429_position_scale.py            # 9 sections, printed
  python3 notes/l7a1429_position_scale.py --selftest # FAILURES: 0
  python3 notes/l7a1429_position_scale.py --table    # the 251 entries and their ratios

WHAT IS MEASURED AND WHAT IS ASSUMED
  MEASURED: every byte, every instruction operand, every fit and every residual below,
  read from original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}.  No `.s` file is read.
  ASSUMED, and cited where used:
    * fs = 44100 Hz -- IC4's crystal is 33.8688 MHz = 768*44100
      (notes/DRIVER-INSIGHT-wsa1-2026-09-02.md).  NOT measured here.
    * the 40.6901 Hz staging refresh (notes/FINDINGS-l7a1429-write-sequencing.md s.5),
      used ONLY in section 9, and section 9 is a check ON it as much as with it.
    * that the played note's frequency is 440*2^((m-69)/12) -- the standard tuning the
      `MUTING` curve fit independently lands on to within 0.33 cent
      (notes/FINDINGS-l7a1429-curve-tables.md s.1).
"""
import math
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs")
AIMG = open(os.path.join(ROM, "wsa1_prom_a.ic12"), "rb").read()
BIMG = open(os.path.join(ROM, "wsa1_prom_b.ic13"), "rb").read()
CIMG = open(os.path.join(ROM, "wsa1_prom_c.ic28"), "rb").read()
DIMG = open(os.path.join(ROM, "wsa1_prom_d.bin"), "rb").read()
CBASE = 0xF80000                       # prom_a and prom_c both live at 0xF80000
FS = 44100.0                           # see the docstring -- NOT measured here
F_REFRESH = 28e6 / 2048 / 28 / 12      # 40.6901 Hz, the staging refresh (section 9 only)

QUIET = False
FAILURES = []


def say(*a):
    if not QUIET:
        print(*a)


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILURES.append("%s: got %r want %r" % (label, got, want))
    say("    [%s] %s = %r" % ("ok" if ok else "FAIL", label, got))
    return ok


def cbytes(addr, n):
    return list(CIMG[addr - CBASE:addr - CBASE + n])


def abytes(addr, n):
    return list(AIMG[addr - CBASE:addr - CBASE + n])


def cu16(addr, n):
    return [CIMG[addr - CBASE + 2 * i] | (CIMG[addr - CBASE + 2 * i + 1] << 8)
            for i in range(n)]


def hexs(bs):
    return ' '.join('%02x' % b for b in bs)


# ---- the objects this note is about -------------------------------------------------
POS_TABLE = 0xFDFAE0                   # Curve_Position_Log2Period_251, 251 u16
MOVE_RATE = 0xFE0296                   # the POSITION MOVEMENT phase step, 51 u8
PIVOT = 0x4280


def period_samples(midi):
    """The period of MIDI note `midi`, in samples at fs.  A440 equal temperament."""
    return FS / (440.0 * 2.0 ** ((midi - 69) / 12.0))


P66 = period_samples(66)               # 119.1910 samples; note 66 = F#4 = 369.9944 Hz


# ---------------------------------------------------------------- section 1
def sec1_the_table_constant_is_500():
    say('=== 1. the POSITION table is round(3072*log2(500/k)) -- residual ZERO ===')
    T = cu16(POS_TABLE, 251)
    check('T[0]', T[0], 27648)
    check('T[1]', T[1], 27543)
    check('T[250]', T[250], 3072)
    exact = [k for k in range(1, 251)
             if T[k] == round(3072 * math.log2(500.0 / k))]
    check('entries k=1..250 matching round(3072*log2(500/k)) EXACTLY', len(exact), 250)
    # the NULL: the published closed form, and two neighbouring integers for the 500
    pub = max(abs(T[k] - round(27543 - 3072 * math.log2(k))) for k in range(1, 251))
    say('    the published form round(27543 - 3072*log2 k) has max |residual| = %d'
        % pub)
    check('  ... i.e. the 500 form is strictly better', pub, 1)
    for n in (496, 498, 499, 501, 502, 504, 512):
        bad = sum(1 for k in range(1, 251)
                  if T[k] != round(3072 * math.log2(float(n) / k)))
        say('    NULL  N = %-3d  ->  %3d of 250 entries WRONG' % (n, bad))
    check('  N=499 already breaks it', sum(1 for k in range(1, 251)
          if T[k] != round(3072 * math.log2(499.0 / k))) > 0, True)
    say('    -> the table\'s design constant is the INTEGER 500, and 3072 counts is one')
    say('       octave (12 semitones x 256), so entry k is the log of the RATIO 500/k.')
    # the two endpoints are round in the REGISTER's own unit, not in any physical unit
    check('T[0] is exactly 9 octaves (a saturation constant, k=0 has no 500/k)',
          T[0], 9 * 3072)
    check('T[250] is exactly 1 octave (forced by the 500 law: 500/250 = 2)',
          T[250], 3072)
    say('    ★ BOTH endpoints are round in COUNTS, not in samples or Hz.  A designer')
    say('      with an absolute anchor to hit would have landed on one; this one did not.')
    # the reader, and the 0..250 clamp, from the operands
    check('the reader\'s base is 0xFDFAE0 (add XBC,0x00fdfae0 at 0xFC49E5)',
          hexs(cbytes(0xFC49E5, 6)), 'e9 c8 e0 fa fd 00')
    check('the index is clamped 0..250 (cp HL,0x00fa at 0xFC49CC)',
          hexs(cbytes(0xFC49CC, 4)), 'db cf fa 00')
    return T


# ---------------------------------------------------------------- section 2
def sec2_the_editor_divides_by_five():
    say('=== 2. the editor draws POSITION as p13/5, and its maximum is 250 = 50.0 ===')
    # ToneEditPage's dedicated POSITION editor at 0xFD44C7 (prom_a).  Two `div C,0x05`.
    check('div C,0x05 at 0xFD4564', hexs(abytes(0xFD4564, 3)), 'cb 0a 05')
    check('div C,0x05 at 0xFD456D', hexs(abytes(0xFD456D, 3)), 'cb 0a 05')
    check('add B,B at 0xFD4570 -- the remainder is DOUBLED for the decimal digit',
          hexs(abytes(0xFD4570, 2)), 'ca 82')
    # the two limit words written into the edit descriptor at +6 and +8
    lim = abytes(0xFD44D9, 16)
    check('the limit stores at 0xFD44D9', hexs(lim),
          'be f6 00 ff be f7 00 00 be f8 00 fa be f9 00 00')
    check('  descriptor +6 = 0x00FF (the byte range)', lim[3] | (lim[7] << 8), 0x00FF)
    check('  descriptor +8 = 0x00FA (the PARAMETER maximum)',
          lim[11] | (lim[15] << 8), 0x00FA)
    say('    the sibling editor for p14 (DEPTH) writes 0x007F into BOTH slots')
    check('  0xFD45DE..0xFD45E9 = 7f 00 7f 00', hexs(abytes(0xFD45DE, 12)),
          'bc 06 00 7f bc 07 00 00 bc 08 00 7f')
    say('    -> POSITION is displayed as  p13/5 . 2*(p13 mod 5),  i.e. 0.0 .. 50.0 in')
    say('       steps of 0.2, and the packer\'s own 0..250 clamp IS the control\'s range.')
    say('    ★★ SO THE TABLE READS  T = round(3072 * log2(100 / POSITION)).')
    say('       The 500 is 5 x 100: the 5 is the display divisor, the 100 is a PERCENT')
    say('       denominator.  The register carries log2(100/POSITION) + a pitch term.')
    for d in (0.2, 1.0, 2.0, 5.0, 10.0, 25.0, 50.0):
        k = int(round(d * 5))
        say('       POSITION %5.1f  ->  p13 = %3d  ->  ratio 100/POSITION = %8.3f  '
            '(table says %8.3f)' % (d, k, 100.0 / d, 2 ** (cu16(POS_TABLE, 251)[k] / 3072.0)))


# ---------------------------------------------------------------- section 3
def sec3_the_pivot_is_note_66():
    say('=== 3. 0x4280 is MIDI note 66 EXACTLY -- and 66 is the middle key ===')
    check('ld IY,0x4280 at 0xFC4A18', hexs(cbytes(0xFC4A18, 3)), '35 80 42')
    check('sub IY,WA at 0xFC4A1B', hexs(cbytes(0xFC4A1B, 2)), 'd8 a5')
    # the pitch word's own seeding: note*256, masked, PLUS 0x80
    seed = cbytes(0xFA7F3A, 14)
    check('the pitch seed at 0xFA7F3A', hexs(seed),
          '8c 05 21 d8 12 d8 ee 08 d8 cc 00 7f d8 8b')
    check('  ... and add HL,0x0080 at 0xFA7F48', hexs(cbytes(0xFA7F48, 4)), 'db c8 80 00')
    say('    so  pitch(note m) = 256*m + 0x80  and')
    for m in (36, 60, 66, 96):
        say('       0x4280 - pitch(%3d) = %6d = 256 * (66 - %3d)   %s'
            % (m, PIVOT - (256 * m + 0x80), m,
               'EXACT' if PIVOT - (256 * m + 0x80) == 256 * (66 - m) else 'NOT EXACT'))
    check('the +0x80 cancels for every MIDI note, so the term is whole semitones',
          all(PIVOT - (256 * m + 0x80) == 256 * (66 - m) for m in range(128)), True)
    say('    ⚠ THIS CORRECTS notes/FINDINGS-l7a1429-curve-tables.md s.2, which reads the')
    say('      pivot as "note 66.5".  As an INTERVAL against the played note the pivot is')
    say('      note 66, because the pitch word carries the same half-step centre.')
    # the same literal in the tone generator's own key-follow stage
    check('ld BC,0x4280 at 0xFA80C7 (the TG key-follow pivot)',
          hexs(cbytes(0xFA80C7, 3)), '31 80 42')
    check('add WA,0x4280 at 0xFA80D7', hexs(cbytes(0xFA80D7, 4)), 'd8 c8 80 42')
    check('ld DE,0x4280 at 0xFA80DF (H == 7: fixed pitch)',
          hexs(cbytes(0xFA80DF, 3)), '32 80 42')
    # 66 is the middle key of the instrument's own 61-key compass
    check('add C,0x24 at 0xF995EC -- key number + 36 on the way out',
          hexs(cbytes(0xF995EC, 3)), 'cb c8 24')
    check('cp (XIZ-2),0x003D at 0xF99816 -- the per-note walk is 61 long',
          hexs(cbytes(0xF99816, 5)), '9e fe 3f 3d 00')
    check('cp (XIZ-2),0x003D at 0xF9983B, the second walk',
          hexs(cbytes(0xF9983B, 5)), '9e fe 3f 3d 00')
    say('    -> keys 0..60 are MIDI 36..96 = C2..C7.  The middle key is 30 = MIDI 66.')
    say('    ★★ SO THE PIVOT IS THE INSTRUMENT\'S OWN MIDDLE KEY, and it is CONSISTENT')
    say('       with the MUTING index\'s "MIDI note - 36": that offset is the compass\'s')
    say('       BOTTOM key, this pivot is its CENTRE.  Both count from the same C2.')
    say('       note 66 = F#4 = %.4f Hz, period %.4f samples at %.0f Hz.'
        % (440 * 2 ** ((66 - 69) / 12.0), P66, FS))
    check('MUTING index of the pivot note is 30, the same key number',
          66 - 36, 30)


# ---------------------------------------------------------------- section 4
def sec4_the_expression():
    say('=== 4. the value expression, re-read from the operands ===')
    # the FORMANT gate: p14 bit 7 SKIPS the pitch term
    check('the p14 bit-7 gate at 0xFC4A03', hexs(cbytes(0xFC4A03, 11)),
          'a9 01 20 88 0e 23 cb cc 80 6e 11')
    say('      0xFC4A03  ld XWA,(XBC+0x01)   R[+0x01] is Q, the 43-byte WaveSelRec')
    say('      0xFC4A06  ld C,(XWA+0x0e)     p14')
    say('      0xFC4A09  and C,0x80          FORMANT')
    say('      0xFC4A0C  jr NZ,0xFC4A1F      SET  -> the pitch term is NOT added (FIX)')
    # the third term: R[+0x0C], negated
    check('ld DE,(XBC+0x0c) / ld WA,DE / neg WA at 0xFC4E6D is the OTHER consumer',
          hexs(cbytes(0xFC4E6D, 8)), '99 0c 22 da 88 d8 07 d8')
    check('sub HL,WA at 0xFC4A29 (POSITION\'s own subtraction of R[+0x0C])',
          hexs(cbytes(0xFC4A29, 2)), 'd8 a3')
    # ** and R[+0x0C] is the ZONE TUNING WORD, the same word added to the TG pitch
    check('ld BC,(XIX+0x06) / ld (0x5a4f),BC at 0xFA748D', hexs(cbytes(0xFA748D, 7)),
          '9c 06 21 f1 4f 5a 51')
    check('ld BC,(XIX+0x06) / push BC at 0xFA7494 -- the SAME word, handed to 0xFC4D85',
          hexs(cbytes(0xFA7494, 4)), '9c 06 21 29')
    check('call 0xFC4D85 at 0xFA74A0 (Pack104_SetInputs_Rec0C_E08C)',
          hexs(cbytes(0xFA74A0, 4)), '1d 85 4d fc')
    check('ld (XBC+0x0c),WA at 0xFC4D93 -- the third argument lands in R[+0x0C]',
          hexs(cbytes(0xFC4D93, 3)), 'b9 0c 50')
    say('    ★★ R[+0x0C] IS THE KEY ZONE\'S TUNING WORD -- the same word latched into')
    say('       0x005A4F, which Voice_PitchAddZoneOffset ADDS to the pitch to make')
    say('       voice[+0x0A], the word the tone generator\'s pitch register is built from.')
    say('       So the third term is not a fourth unknown: it is part of the PITCH, and')
    say('           register chan+0x00C0 = T[k] + (0x4280 - voice[+0x0A])')
    say('       i.e. POSITION tracks the SOUNDING pitch, sample tuning included, at')
    say('       slope exactly -1.  Equivalently, up to the global (0x001503) and the')
    say('       part\'s +/-[+0x1D],   reg(0x00C0) + reg(0x0400) = 0x4280 + T[k].')
    # the clamps
    check('the underflow arms at 0xFC4A37: ld HL,0x0000 / ld HL,0x7f00',
          hexs(cbytes(0xFC4A37, 8)), '33 00 00 68 03 33 00 7f')
    say('    range [0x0000, 0x7F00] = [0, 127.000] in the 1/256-semitone unit.')


# ---------------------------------------------------------------- section 5
def _wave_select_records():
    """The 43-byte WaveSelRec of every melodic tone record whose framing self-checks.

    Byte-for-byte the same conservative filter as notes/dev104_topology_probe.py's
    section 13, so the population (133 records) is the one the guide already quotes.
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


def sec5_factory_data():
    say('=== 5. what the FACTORY tones actually ask for ===')
    ws = _wave_select_records()
    check('melodic WaveSelRec records whose framing self-checks', len(ws), 133)
    cen = {}
    for r in ws:
        cen[r[0x0D]] = cen.get(r[0x0D], 0) + 1
    say('    p13 (POSITION) census, raw : %s' % sorted(cen.items()))
    say('    p13 as the editor draws it : %s'
        % sorted(set('%.1f' % (r[0x0D] / 5.0) for r in ws)))
    check('  the modal value is p13 = 125 = POSITION 25.0, the exact middle of 0.0..50.0',
          max(cen, key=cen.get), 125)
    check('  and it is the value in 118 of 133', cen[125], 118)
    check('  no factory record exceeds the control\'s own maximum',
          max(cen), 250)
    fix = sum(1 for r in ws if r[0x0E] & 0x80)
    say('    FORMANT (p14 bit 7) = FIX in %d of %d records' % (fix, len(ws)))
    check('  FIX count', fix, 103)
    say('    ⚠ SO IN 103 OF 133 FACTORY MELODIC RECORDS THE PITCH TERM IS SKIPPED and the')
    say('      register is a CONSTANT -- a fixed time, i.e. a FORMANT, exactly as the')
    say('      caption says.  The "slope against key is exactly -1" that the guide calls')
    say('      its strongest discriminator is the MINORITY mode in the factory set.  It')
    say('      is still exactly -1 when it is on; it is just not what most tones use.')
    return ws


# ---------------------------------------------------------------- section 6
def sec6_the_reduction():
    say('=== 6. the reduction: ONE dimensionless unknown, not a scale in samples ===')
    T = cu16(POS_TABLE, 251)
    say('    Let the chip\'s rule be   delay(v) = C * 2^(v/3072) samples,  C unknown.')
    say('    Sections 1-4 give, with D = POSITION (0.0..50.0) and m the sounding note:')
    say('        2^(v/3072) = (100/D) * 2^((66 - m)/12)          FORMANT = MOVE')
    say('        2^(v/3072) = (100/D)                            FORMANT = FIX')
    say('    and 2^((66-m)/12) = P(m)/P66, so')
    say('        delay = (100*C/P66) * P(m)/D          == g * P(m) / D      (MOVE)')
    say('        delay = (100*C/P66) * P66 / D         == g * P66  / D      (FIX)')
    say('    with the SINGLE dimensionless constant   g = 100*C/P66 = %.6f * C' %
        (100.0 / P66))
    say('    ★ g = 1 is the physically canonical value: the tap then sits at exactly')
    say('      1/POSITION of the resonator, i.e. POSITION is the reciprocal of the tap')
    say('      fraction -- the harmonic the comb notch lands on.  POSITION 2.0 = the')
    say('      midpoint, POSITION 50.0 = 2% from the end.  ⚠ NOTHING IN THE ROM SAYS g=1.')
    # the direction is forced, and that kills the "POSITION is a percentage" reading
    say('    ⚠ AND THE DIRECTION IS FORCED.  v FALLS as the note rises, so the chip\'s')
    say('      exponent must be +v/3072 for the delay to track the period.  The delay is')
    say('      therefore proportional to 1/POSITION, NOT to POSITION.  A reading of')
    say('      POSITION as "per cent of the string" is arithmetically excluded.')
    # worked numbers at the factory default
    say('    at the factory default POSITION 25.0 (p13 = 125):')
    check('  T[125]', T[125], round(3072 * math.log2(4.0)))
    for m in (36, 60, 66, 84, 96):
        raw = T[125] + 256 * (66 - m)
        v = 0 if raw < 0 else (0x7F00 if raw > 0x7F00 else raw)
        say('       note %3d: v = %6d%s,  delay = g * %8.4f samples = g * P(%d)/25'
            % (m, v, '  (CLAMPED, raw %d)' % raw if v != raw else '            ',
               period_samples(m) / 25.0 if v == raw else (P66 / 100.0) * 2 ** (v / 3072.0),
               m) if v == raw else
            '       note %3d: v = %6d  (CLAMPED, raw %d),  delay = g * %8.4f samples'
            ' -- NOT g * P(%d)/25' % (m, v, raw, (P66 / 100.0) * 2 ** (v / 3072.0), m))
    check('  the top of the 61-key compass CLAMPS at this POSITION and this pivot',
          T[125] + 256 * (66 - 96) < 0, True)
    say('    ⚠ note that at POSITION 25.0 the register underflows above note 90, so the')
    say('      floor 0x0000 is REACHED in normal play.  Whatever the chip does at 0 is')
    say('      audible, and nothing in the ROM says what that is.')
    say('       FORMANT=FIX at POSITION 25.0: v = %d, delay = g * %.4f samples,'
        % (T[125], 4.0 * (P66 / 100.0)))
    say('         i.e. a fixed resonance at %.1f / g Hz.' % (FS / (4.0 * (P66 / 100.0))))


# ---------------------------------------------------------------- section 7
def sec7_roundness_and_its_null():
    say('=== 7. is any candidate unit ROUND?  the test, pre-registered, and its null ===')
    say('    TOLERANCE, STATED BEFORE LOOKING: a log-domain quantity counts as landing')
    say('    on a target if it is within +/-5 cents (+/-0.289%).  That is the order of')
    say('    the agreements the curve lane reports (0.33 cent, 0.8 cent), so anything')
    say('    looser would not be a claim about design intent.')
    say('    NULL for one test: under a uniform prior on log2(x) mod 1, the chance of')
    say('    landing within 5 cents of ANY power of two is 2*5/1200 = 0.833 per cent,')
    say('    i.e. 1 in 120.')
    say('')
    # the whole family, in one line: g and C differ by a fixed factor
    ratio = 100.0 / P66
    say('    g = %.8f * C, and log2(%.8f) = %.6f.' % (ratio, ratio, math.log2(ratio)))
    frac = math.log2(ratio) - round(math.log2(ratio))
    say('    Its distance to the nearest integer is %.6f octave = %.1f cents.'
        % (abs(frac), abs(frac) * 1200))
    check('  ... which is FAR outside the 5-cent tolerance',
          abs(frac) * 1200 > 5.0, True)
    say('    ★★ THAT IS THE WHOLE RESULT OF THIS SECTION.  C (the delay at v=0, in')
    say('       samples) and g (the tap fraction\'s reciprocal scale) cannot BOTH be')
    say('       round: they are %.1f cents apart from any power-of-two alignment.  The'
        % (abs(frac) * 1200))
    say('       ROM\'s exponential zero-point sits at no privileged place on either grid.')
    say('    ⚠ AND ONE SOFT SPOT, WHICH DOES NOT RESCUE ANYTHING.  g is defined against')
    say('    P66, so it inherits the tone generator\'s own unresolved half-step centre: if')
    say('    the TG reads its pitch register as note = v/256 rather than (v-128)/256, every')
    say('    g above moves by 2^(1/24) = 50 cents.  50 cents is not 303.9 cents, so the')
    say('    conclusion stands either way -- but a future g must say which convention it is in.')
    say('')
    say('    THE CANDIDATE UNITS TRIED, AND WHAT EACH IMPLIES  (count them: this is the')
    say('    multiple-comparisons budget)')
    cands = [
        ('U1  delay(v=0) = 1 sample at 44100 Hz', 1.0),
        ('U2  delay(v=0) = 1/2 sample', 0.5),
        ('U3  delay(v=0) = 1/4 sample', 0.25),
        ('U4  delay(v=0) = 2 samples', 2.0),
        ('U5  delay(v=0) = 4 samples', 4.0),
        ('U6  delay(v=0) = 8 samples', 8.0),
        ('U7  delay(v=0) = 16 samples', 16.0),
        ('U8  delay(0x7F00) = 1024 samples (ceiling = a DRAM depth)',
         1024.0 / 2 ** (0x7F00 / 3072.0)),
        ('U9  delay(0x7F00) = 2048 samples', 2048.0 / 2 ** (0x7F00 / 3072.0)),
        ('U10 delay(0x7F00) = 4096 samples', 4096.0 / 2 ** (0x7F00 / 3072.0)),
        ('U11 delay(0x7F00) = 65536 samples', 65536.0 / 2 ** (0x7F00 / 3072.0)),
        ('U12 g = 1 (the tap is 1/POSITION of the resonator)', P66 / 100.0),
    ]
    hits_C = hits_g = 0
    for name, C in cands:
        g = ratio * C
        dC = abs(math.log2(C) - round(math.log2(C))) * 1200
        dg = abs(math.log2(g) - round(math.log2(g))) * 1200
        hits_C += dC <= 5.0
        hits_g += dg <= 5.0
        say('      %-56s C = %10.5f (%6.1f c)   g = %9.5f (%6.1f c)'
            % (name, C, dC, g, dg))
    say('    tried %d candidate units.  %d put C on a power of two, %d put g on one,'
        % (len(cands), hits_C, hits_g))
    say('    and ZERO put both there -- which is not a finding, it is arithmetic: the')
    say('    two grids are %.1f cents out of phase, so no unit can hit both.'
        % (abs(frac) * 1200))
    check('  no candidate unit lands C and g on a power of two together',
          sum(1 for name, C in cands
              if abs(math.log2(C) - round(math.log2(C))) * 1200 <= 5.0
              and abs(math.log2(ratio * C) - round(math.log2(ratio * C))) * 1200 <= 5.0),
          0)
    say('')
    say('    ⚠ "A WHOLE NUMBER OF SAMPLES" IS NOT A TEST.  With a 0.289 per cent window,')
    say('    every value above about 173 samples is within tolerance of some integer, and')
    say('    below it the hit rate is still 0.578 per cent times x.  The target must be a power')
    say('    of two, a named buffer size, or a sub-multiple of fs to discriminate at all.')
    say('')
    say('    A SOFT, EXPLICITLY NON-DETERMINING BOUND.  In FORMANT = FIX the register is')
    say('    a fixed delay, so it is a fixed resonance:  f = fs*D/(100*C) = %.1f*D/C Hz.'
        % (FS / 100.0))
    for C in (1.0, P66 / 100.0, 4.0, 8.0, 16.0):
        say('       C = %8.5f  ->  the factory default POSITION 25.0 resonates at %8.1f Hz'
            % (C, FS * 25.0 / (100.0 * C)))
    say('    A body formant between 500 Hz and 3 kHz would need C between %.1f and %.1f.'
        % (FS * 25.0 / (100.0 * 3000.0), FS * 25.0 / (100.0 * 500.0)))
    say('    ⚠ THAT IS A PLAUSIBILITY BAND, NOT A MEASUREMENT, and it does not contain')
    say('      g = 1.  It is recorded so the next pass knows the two readings disagree.')


# ---------------------------------------------------------------- section 8
def sec8_search_the_images():
    say('=== 8. searching all four images for the constant, and the null for the search ===')
    imgs = [('prom_a', AIMG), ('prom_b', BIMG), ('prom_c', CIMG), ('prom_d', DIMG)]
    wanted = {
        'C for g=1   (P66/100)': P66 / 100.0,
        'C for tap=P/k (P66/500)': P66 / 500.0,
        'P66, the pivot period': P66,
        '500/P66': 500.0 / P66,
        '100/P66': 100.0 / P66,
        'f(note 66) Hz': 440 * 2 ** ((66 - 69) / 12.0),
        'fs/100': FS / 100.0,
    }

    def scan(targets, tol=0.005):
        n = 0
        found = []
        for nm, img in imgs:
            for width, fmt in ((8, '<d'), (4, '<f')):
                for off in range(0, len(img) - width + 1):
                    v = struct.unpack_from(fmt, img, off)[0]
                    if v != v or v == 0.0 or not (1e-6 < abs(v) < 1e9):
                        continue
                    for tn, tv in targets.items():
                        if abs(v / tv - 1.0) < tol:
                            n += 1
                            found.append((nm, off, width, v, tn))
        return n, found

    n, found = scan(wanted)
    per_real = {}
    for nm, off, width, v, tn in found:
        per_real[tn] = per_real.get(tn, 0) + 1
    say('    unaligned f32/f64 scan of all four images, +/-0.5%%, %d targets: %d hits'
        % (len(wanted), n))
    for tn in wanted:
        say('      %-26s %3d hits' % (tn, per_real.get(tn, 0)))
    for nm, off, width, v, tn in found[:8]:
        say('        e.g. %-7s +0x%06X %s %-22r ~ %s'
            % (nm, off, 'f64' if width == 8 else 'f32', v, tn))
    say('      ... %d hits in all' % len(found))
    # THE NULL: the SAME scan with decoys of the SAME magnitude but no meaning --
    # each real target multiplied by 2^u, u uniform in (0.15, 0.85), so a decoy sits
    # in the same decade and the counts are directly comparable.
    import random
    rnd = random.Random(20260904)
    decoys = {}
    for i, (tn, tv) in enumerate(sorted(wanted.items())):
        for j in range(10):
            decoys['%s#%d' % (tn, j)] = tv * 2.0 ** rnd.uniform(0.15, 0.85)
    dn, dfound = scan(decoys)
    per_dec = {}
    for nm, off, width, v, tn in dfound:
        per_dec[tn] = per_dec.get(tn, 0) + 1
    counts = sorted(per_dec.get(k, 0) for k in decoys)
    med = counts[len(counts) // 2]
    say('    NULL: the same scan with %d MEANINGLESS decoys, each a real target times'
        % len(decoys))
    say('    2^u (u in 0.15..0.85) so it sits in the same decade:')
    say('      decoy hits per target: min %d, median %d, mean %.1f, max %d'
        % (counts[0], med, dn / float(len(decoys)), counts[-1]))
    say('      real  hits per target: min %d, median %d, mean %.1f, max %d'
        % (min(per_real.get(k, 0) for k in wanted),
           sorted(per_real.get(k, 0) for k in wanted)[len(wanted) // 2],
           n / float(len(wanted)),
           max(per_real.get(k, 0) for k in wanted)))
    check('  the real targets are NOT enriched over same-magnitude decoys',
          n / float(len(wanted)) <= max(1.0, dn / float(len(decoys))), True)
    say('    -> an unaligned byte scan of 2 MB finds any 0.5 per cent-wide value at this')
    say('       rate whatever the value is.')
    # prom_c's f64 constant pool is the one place a real physical constant would live
    pool = [(nm, off) for nm, off, width, v, tn in found
            if nm == 'prom_c' and width == 8
            and 0xFCB27E - CBASE <= off < 0xFCB4E6 - CBASE and off % 8 == 0]
    check('  hits at an 8-ALIGNED offset inside prom_c\'s 77-entry Float64_ConstantPool'
          ' (0xFCB27E-0xFCB4E5)', len(pool), 0)
    say('       That pool is the one place in the image a real physical constant lives')
    say('       (notes/FINDINGS-prom_c-f64-pool.md); it holds none of these.  There is')
    say('       no evidence here.')
    # and the immediates of the POSITION chain itself, exhaustively
    say('    AND THE CHAIN ITSELF.  Every 16-bit immediate in the routine that builds')
    say('    the register, 0xFC49AD..0xFC4AEC, is one of:')
    imm = set()
    body = cbytes(0xFC49AD, 0xFC4AEC - 0xFC49AD + 1)
    for i in range(len(body) - 1):
        imm.add(body[i] | (body[i + 1] << 8))
    known = {0x00FA: 'the 0..250 clamp', 0x0002: 'the u16 table stride',
             0x4280: 'the pivot, note 66', 0x7F00: 'the register ceiling',
             0x0000: 'the register floor', 0x8000: 'fold()\'s offset',
             0x007F: 'the 0..127 Rise clamp', 0xFFF8: 'the low-3-bit field mask',
             0x0007: 'the low-3-bit field value'}
    for k in sorted(known):
        say('        0x%04X  %s' % (k, known[k]))
    check('  all nine are present as byte pairs in the routine',
          all(k in imm for k in known), True)
    say('    Not one of them is a time, a rate or a sample count.  The ONLY numeric')
    say('    constant the chain contributes is the table\'s 500, and section 1 shows')
    say('    that is a RATIO denominator (100 per cent, times the display\'s 5).')


# ---------------------------------------------------------------- section 9
def sec9_positive_control():
    say('=== 9. THE POSITIVE CONTROL: this parameter group DOES carry an absolute unit ===')
    say('    A negative is worth nothing unless the instrument could have seen a positive.')
    say('    The POSITION MOVEMENT SPEED table is the control.')
    b = list(CIMG[MOVE_RATE - CBASE:MOVE_RATE - CBASE + 51])
    check('the 51 bytes at 0xFE0296', (b[0], b[1], b[25], b[50]), (0, 1, 64, 126))
    check('  monotone non-decreasing', all(b[i] <= b[i + 1] for i in range(50)), True)
    check('  it is 51 entries: 0xFE0296 + 51 = 0xFE02C9, the 512-byte waveform',
          MOVE_RATE + 51 == 0xFE02C9, True)
    check('  the index is p18 & 0x7F clamped 0..50 (ld HL,0x0032 at 0xFC6252)',
          hexs(cbytes(0xFC6252, 3)), '33 32 00')
    check('  read as a BYTE (add XBC,0x00fe0296 / ld A,(XBC) at 0xFC626E)',
          hexs(cbytes(0xFC626E, 7)), 'e9 c8 96 02 fe 00 81')
    check('  the phase is masked &0x01FF at 0xFC7C7A',
          hexs(cbytes(0xFC7C7A, 4)), 'db cc ff 01')
    check('  and indexes the 512-byte waveform at 0xFE02C9 (0xFC7C91)',
          hexs(cbytes(0xFC7C91, 6)), 'e8 c8 c9 02 fe 00')
    say('    The reader clamps its index to 0..50 and the phase accumulator is masked')
    say('    &0x01FF, so the entry is a step over a 512-point cycle advanced once per')
    say('    staging refresh.  At the measured %.4f Hz refresh that is:' % F_REFRESH)
    rates = [x * F_REFRESH / 512.0 for x in b]
    for i in (0, 1, 5, 10, 25, 40, 50):
        say('       SPEED %2d  ->  step %3d  ->  %7.4f Hz' % (i, b[i], rates[i]))
    check('  the floor is exactly 0 Hz', b[0], 0)
    say('    the ceiling is %.4f Hz -- %.2f%% from a round 10 Hz.'
        % (rates[50], abs(rates[50] / 10.0 - 1) * 100))
    check('  the ceiling is within 0.5% of 10 Hz', abs(rates[50] / 10.0 - 1) < 0.005, True)
    say('    NULL: the nearest integer Hz is 1 apart and the tolerance is +/-0.05 Hz, so')
    say('    a value landing this close to an integer by chance has p = 0.1; landing on')
    say('    10 specifically, with the floor exactly 0 and the curve monotone, is much')
    say('    less likely than that.  And the step is 2 counts = 0.159 Hz near the top, so')
    say('    126 is the CLOSEST REPRESENTABLE value to 10 Hz (10 Hz needs 125.83).')
    say('    ★★ SO: a 0..50 control in this very parameter group maps to 0..10 Hz, in')
    say('       REAL TIME, recoverable from the ROM to 0.14%.  The method finds an')
    say('       absolute unit when the firmware has one.  It does not find one for')
    say('       POSITION because the firmware does not have one.')
    say('    ★ and this is a second, independent argument FOR the 40.69 Hz refresh: no')
    say('      other plausible tick makes this table land on a round span.')


def sec_table_dump():
    T = cu16(POS_TABLE, 251)
    print('  k   POSITION   T[k]    2^(T/3072)   100/POSITION')
    for k in range(251):
        d = k / 5.0
        print('%4d  %7.1f  %6d  %11.4f  %13s'
              % (k, d, T[k], 2 ** (T[k] / 3072.0),
                 '%.4f' % (100.0 / d) if d else '(saturation)'))


SECTIONS = [sec1_the_table_constant_is_500, sec2_the_editor_divides_by_five,
            sec3_the_pivot_is_note_66, sec4_the_expression, sec5_factory_data,
            sec6_the_reduction, sec7_roundness_and_its_null, sec8_search_the_images,
            sec9_positive_control]


def main():
    global QUIET
    if '--table' in sys.argv:
        sec_table_dump()
        return 0
    QUIET = '--selftest' in sys.argv
    for fn in SECTIONS:
        fn()
        say()
    if FAILURES:
        print('FAILURES: %d' % len(FAILURES))
        for f in FAILURES:
            print('  ' + f)
        return 1
    print('FAILURES: 0')
    return 0


if __name__ == '__main__':
    sys.exit(main())
