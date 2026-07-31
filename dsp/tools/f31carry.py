# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""f31carry.py -- DOES `f31 == 1' CARRY THE ACCUMULATOR?  And is `P_SHIFT = 7'
Q-consistent?

§227.  Read-only, from disk.  The §226 handover moved the blocker to the ALU
decode of the common header's `iw30 / iw32 / iw33` ladder and pre-registered ONE
untested reading:

    "iw33's f31 = 1 should NOT carry iw32's accumulator.  Drop the carried term
     => 1.000 FS; drop it AND apply the Q-consistent P_SHIFT = 7 => 0.750 FS."

This tool grades BOTH halves against the committed corpus, the two archived host
captures, the arm-K log and the core's own source, WITHOUT a build:

    1. what the three words actually are, field by field
    2. the f31 census -- what `f31 == 1' is, over 3057 words and 41 listings
    3. THE BLAST RADIUS: the PARAMETRIC EQ biquad, the one program this project
       has decoded to the bit and validated against its designer
    4. the ladder evaluated under every arm of the proposed bisection
    5. the fixed point: is 22 = P_SHIFT + ACC_SHIFT forced, and is a split move
       even observable?

  * RULE 20.  Every section's inputs are checked against answers published by
    OTHER passes and OTHER instruments, and the self-test is printed FIRST.

Usage:
    python3 dsp/tools/f31carry.py
"""

import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                  # the vendored ISA mirror
import hdrbase as H                                     # §226's capture replayer

REPO = os.path.dirname(os.path.dirname(HERE))
DISASM = os.path.join(REPO, 'dsp', 'disasm')
CORE = os.path.expanduser('~/compartilhado/kn7000_mame/src/devices/cpu/upd6383/upd6383.h')
WORD_RE = re.compile(r'\s*w(\d+)\s+([0-9A-F]{10})\b')

FSD = 8388607                   # datum full scale, 2**23 - 1
P_SHIFT = 6                     # the SHIPPED split
ACC_SHIFT = 22 - P_SHIFT


def words(path):
    out = []
    for line in open(path):
        m = WORD_RE.match(line)
        if m:
            out.append((int(m.group(1)), int(m.group(2), 16)))
    return out


def corpus():
    out = {}
    for p in sorted(glob.glob(os.path.join(DISASM, '*.dsm'))):
        n = os.path.basename(p)
        if n == 'index.dsm':
            continue
        out[n] = words(p)
    return out


def sx(v):
    return v - (1 << 24) if v & 0x800000 else v


# ---------------------------------------------------------------------------
#  the ladder, parameterised by the two things under test
# ---------------------------------------------------------------------------
def ladder(C, base, carry33=True, pshift=P_SHIFT, accshift=ACC_SHIFT):
    """The kernel header's iw30/iw32/iw33 ladder, on cursor base `base'.

    THE PIPELINE (upd6383.cpp exec_alu): `m_p' is formed at the BOTTOM of the
    word, so slot N's accumulator consumes slot N-1's product.  That is why
    iw32's P is C[base+0] squared and iw33's is C[base+1] squared.

        iw30  f31 5 -> ADD   SRC 0x08 ACT 0x00   acc = 0        + C[b+0]<<S + 0
        iw32  f31 0 -> LOAD  SRC 0x08 ACT 0x07   acc = 0        + 0         + C[b+0]^2>>p
        iw33  f31 1 -> ADD   SRC 0x08 ACT 0x00   acc = acc(iw32)+ C[b+2]<<S + C[b+1]^2>>p
        iw34  f31 0 -> LOAD  SRC 0x10 ACT 0x07   STORES the accumulator, then reloads

    Returns the three accumulators AND the datum iw34 stores."""
    a, b, d = C[base & 255], C[(base + 1) & 255], C[(base + 2) & 255]
    if a is None or b is None or d is None:
        return None
    a, b, d = sx(a), sx(b), sx(d)
    iw30 = a << accshift
    iw32 = (a * a) >> pshift
    iw33 = (iw32 if carry33 else 0) + (d << accshift) + ((b * b) >> pshift)
    return iw30, iw32, iw33, iw33 >> accshift


def fs(v, accshift=ACC_SHIFT):
    return (v >> accshift) / float(FSD)


def clipped(datum):
    return datum > FSD or datum < -FSD - 1


# ---------------------------------------------------------------------------
def main():
    ok = True
    checks = []

    def chk(name, got, want):
        nonlocal ok
        good = got == want
        ok = ok and good
        checks.append((name, good, got, want))
        return good

    kern = dict(words(os.path.join(DISASM, 'kernel.dsm')))
    peq = dict(words(os.path.join(DISASM, 'prog39_parametric_eq.dsm')))
    corp = corpus()
    ntot = sum(len(v) for v in corp.values())

    # ---- §0  RULE 20 ------------------------------------------------------
    chk('corpus listings (41 incl. index-less)', len(corp), 40)
    chk('corpus words 3057', ntot, 3057)
    chk('kernel w30 raw', '%010X' % kern[30], '009AA00200')
    chk('kernel w32 raw', '%010X' % kern[32], '0000AFF207')
    chk('kernel w33 raw', '%010X' % kern[33], '0412A00200')
    chk('kernel w34 raw', '%010X' % kern[34], '0000AFF407')
    chk('f31 of w30/w32/w33/w34',
        tuple(D.hi_f31(D.hi12(kern[i])) for i in (30, 32, 33, 34)), (5, 0, 1, 0))

    live = H.live_cram(H.LIVE)
    cold = H.capture_cram(H.CAP_COLD)[0]
    peqc = H.capture_cram(H.CAP_PEQ)[0]
    #  §227 TASK 2's two new captures, both screen-verified (notes/data/*_screen.png)
    CAP_ROOM = os.path.join(os.path.dirname(H.CAP_COLD), 'kn5000_dsp1_upload_roomreverb1.txt')
    CAP_CONC = os.path.join(os.path.dirname(H.CAP_COLD), 'kn5000_dsp1_upload_concertreverb1.txt')
    room = H.capture_cram(CAP_ROOM)[0] if os.path.exists(CAP_ROOM) else None
    conc = H.capture_cram(CAP_CONC)[0] if os.path.exists(CAP_CONC) else None
    L = ladder(live, 0x9B)
    # EXTERNAL 1 -- §224 §S2's own printed accumulator, another instrument entirely
    chk('EXT §224 §S2 iw33 @0x9B = 945 579 874 058', L[2], 945579874058)
    # EXTERNAL 2 -- §224 §S2's printed iw30 BUS term
    chk('EXT §224 §S2 iw30 bus = 329 853 435 904', L[0], 329853435904)
    # EXTERNAL 3 -- §224 §S2's printed iw32 P term
    chk('EXT §224 §S2 iw32 P   = 395 824 060 170', L[1], 395824060170)
    # EXTERNAL 4 -- §S1's own saturation census row for iw34
    chk('EXT §S1 iw34 pre-clamp datum = 14 428 403', L[3], 14428403)
    # EXTERNAL 5 -- §225 §S3's first non-zero datum in D-RAM cell 0x06
    chk('EXT §S3 store #1360 datum = 6 039 795', L[1] >> ACC_SHIFT, 6039795)
    # the source's own FORCED total, read out of the header rather than assumed
    src = open(CORE).read()
    chk('core: the FIXED POINT comment says the TOTAL 22 is FORCED',
        'a coefficient is scaled by 2^22 (Q1.22 -- MEASURED from' in src, True)
    chk('core: shipped default P_SHIFT 6 / ACC_SHIFT 16',
        ('int P_SHIFT   = 6;' in src) and ('int ACC_SHIFT = 16;' in src), True)
    # the biquad's five accumulating words, by NAME from the generated listing
    chk('PEQ w6..w10 all f31 == 1',
        tuple(D.hi_f31(D.hi12(peq[i])) for i in range(6, 11)), (1, 1, 1, 1, 1))
    # a control that CAN fail in the other direction: the ladder must NOT
    # reproduce §S2 at the refuted base
    chk('CONTROL ladder @0x0B != §S2 (must differ)', ladder(live, 0x0B)[2] != 945579874058, True)
    # EXTERNAL 6 -- §227 TASK 2: an INDEPENDENT 45 s panel run that lands on the
    # cold-boot reverb must reproduce the 2026-07-22 archived capture on all 256 cells
    if conc is not None:
        chk('EXT §227 CONCERT REVERB 1 capture == archived cold boot (256 cells)',
            all(conc[i] == cold[i] for i in range(256)), True)
    if room is not None:
        chk('EXT §227 ROOM REVERB 1 moves 23 cells, ALL inside 0x90..0xB4',
            (sum(1 for i in range(256) if room[i] != cold[i]),
             sum(1 for i in range(256) if room[i] != cold[i] and not (0x90 <= i <= 0xB4))),
            (23, 0))

    print('=== §227 SELF-TEST (known answers, 5 of them from OTHER instruments) ===')
    for name, good, got, want in checks:
        print('   %-56s %s' % (name, 'PASS' if good else 'FAIL  got=%r want=%r' % (got, want)))
    print('   %d of %d PASS' % (sum(1 for c in checks if c[1]), len(checks)))
    if not ok:
        print('   *** SELF-TEST FAILED -- nothing below is trustworthy ***')
    print()

    # ---- §1  the three words ---------------------------------------------
    print('=== 1. THE LADDER, FIELD BY FIELD (corpus) ===')
    print('   %-5s %-12s %-5s %-4s %-4s %-5s %-5s %-4s  %s'
          % ('iw', 'raw', 'f31', 'ST', 'END', 'SRC', 'ACT', 'cl', 'meaning'))
    mean = {30: 'ADD   bus C[b+0]         (f31 5 -> op 1)',
            32: 'LOAD  P = C[b+0]^2       (ACT 0x07 = store bus, no bus term)',
            33: 'ADD   carried + C[b+2] + C[b+1]^2',
            34: 'LOAD  SRC 0x10 = THE ACCUMULATOR -> ACT 0x07 stores it'}
    for i in (30, 32, 33, 34):
        w = kern[i]
        print('   %-5s %010X %-5d %-4s %-4s 0x%02X  0x%02X  %-4X  %s'
              % ('iw%d' % i, w, D.hi_f31(D.hi12(w)),
                 'Y' if D.hi12(w) & D.HI_ST else '.',
                 'Y' if D.hi12(w) & D.HI_END else '.',
                 D.lo_src(w), D.lo_act(w), D.class4(w), mean[i]))
    print('   ⇒ iw34 is the CONSUMER: SRC 0x10 puts the accumulator on the bus and ACT 0x07')
    print('     stores it.  That conversion is §S1\'s iw34 row -- the clip everyone quotes.')
    print()

    # ---- §2  the f31 census ----------------------------------------------
    print('=== 2. WHAT IS `f31 == 1\'?  THE CORPUS CENSUS ===')
    cen = collections.Counter()
    alu = collections.Counter()
    for name, ws in corp.items():
        for _, w in ws:
            if D.c_format(w):
                continue
            cen[D.hi_f31(D.hi12(w))] += 1
            if D.alu_decoded(w):
                alu[D.hi_f31(D.hi12(w))] += 1
    print('   f31 : corpus words (non-C-format) | of which ALU-DECODED | shipped op (mask bit 0 SET)')
    opname = {0: 'LOAD  acc <- P', 1: 'ADD   acc <- acc + P', 2: 'HOLD  acc unchanged, no P',
              3: 'op 3  (HOLD-like, OPEN)', 4: 'LOAD  (f31 & 3)', 5: 'ADD   (f31 & 3)',
              6: 'HOLD  (f31 & 3)', 7: 'op 3  (f31 & 3)'}
    for f in range(8):
        print('   %3d : %5d                     | %5d                | %s'
              % (f, cen[f], alu[f], opname[f]))
    add = cen[1] + cen[5]
    print('   ⇒ the ADD family (f31 1 and 5) is %d of %d non-C-format words, %.1f %%'
          % (add, sum(cen.values()), 100.0 * add / sum(cen.values())))
    print('   ⇒ there is NO OTHER accumulate: op 0 LOADs, op 2 HOLDs without a product,')
    print('     op 3 is given HOLD\'s behaviour.  Removing the carry from f31 == 1 removes')
    print('     MULTIPLY-ACCUMULATE FROM THE INSTRUCTION SET.')
    print()

    # ---- §3  the blast radius --------------------------------------------
    print('=== 3. BLAST RADIUS -- THE PARAMETRIC EQ BIQUAD (programs.tsv: confidence SOLVED) ===')
    ann = {5: 'P = b1*S0 ; latch A <- S0', 6: 'S0 <- x ; acc = P ; P = b0*x',
           7: 'acc += P ; P = b2*S1', 8: 'acc += P ; P = -a1*S2 ; latch B <- S2',
           9: 'acc += P ; P = -a2*S3', 10: 'acc += P ; S3 <- latch B',
           11: 'class-8 post-sum step', 12: 'S2 <- acc ; P = makeup*acc'}
    print('   %-5s %-12s %-4s %-5s %-5s  %s' % ('iw', 'raw', 'f31', 'SRC', 'ACT', 'listing annotation'))
    for i in range(5, 13):
        w = peq[i]
        print('   %-5s %010X %-4d 0x%02X  0x%02X   %s'
              % ('w%d' % i, w, D.hi_f31(D.hi12(w)), D.lo_src(w), D.lo_act(w), ann[i]))
    nmac = sum(1 for i in range(5, 13) if D.hi_f31(D.hi12(peq[i])) == 1)
    print('   ⇒ %d of the 8 biquad words are f31 == 1, and they are EXACTLY the words the'
          % nmac)
    print('     generated listing renders `acc += P\'.  Direct-Form-I needs five products')
    print('     summed:  y = b0*x + b1*x1 + b2*x2 - a1*y1 - a2*y2.')
    print('   ⇒ WITHOUT THE CARRY the accumulator at w11 holds ONLY the last product,')
    print('     so H(z) collapses to `makeup * (-a2) * z^-2\' -- a delayed gain, not an EQ.')
    b0 = peqc[0x01]
    a2 = peqc[0x04]
    print('     band 0 of the archived PEQ capture: b0 = C[0x01] = 0x%06X, -a2 = C[0x04] = 0x%06X'
          % (b0, a2))
    print('     the surviving term would be the -a2 one; every numerator tap is dropped.')
    print('   ⛔ prog39 is the ONE program validated against its DESIGNER (0.198 dB, upd6383.cpp')
    print('     :4736).  A decode that destroys it is refuted whatever it does to the header.')
    print()

    # ---- §4  the arms ------------------------------------------------------
    print('=== 4. THE PRE-REGISTERED BISECTION, EVALUATED ON EVERY C-RAM IMAGE ===')
    print('   arm 1 = "iw33 does not carry"     arm 2 = "P_SHIFT = 7"')
    print('   ⚠ P_SHIFT and ACC_SHIFT are TIED in the source (ACC_SHIFT = 22 - P_SHIFT), so')
    print('     "P_SHIFT = 7" has TWO possible meanings and they are NOT the same experiment.')
    print()
    arms = [
        ('SHIPPED            ', True,  6, 16),
        ('arm1 no-carry      ', False, 6, 16),
        ('arm2a P7 TIED  15  ', True,  7, 15),
        ('arm2b P7 UNTIED 16 ', True,  7, 16),
        ('arm1+2a            ', False, 7, 15),
        ('arm1+2b            ', False, 7, 16),
    ]
    images = [('LIVE armK', live), ('coldboot ', cold), ('parametEQ', peqc)]
    if conc is not None:
        images.append(('REVERB=CONCERT 1', conc))
    if room is not None:
        images.append(('REVERB=ROOM 1   ', room))
    for tag, cimg in images:
        print('   --- %s, base 0x9B ---' % tag)
        for nm, cy, ps, asf in arms:
            r = ladder(cimg, 0x9B, cy, ps, asf)
            print('     %s iw30 %+7.3f  iw32 %+7.3f  iw33 %+7.3f  stored datum %9d  %s'
                  % (nm, fs(r[0], asf), fs(r[1], asf), fs(r[2], asf), r[3],
                     'CLIPS' if clipped(r[3]) else 'in range'))
    print()
    print('   ★ THE BRIEF PREDICTED  arm1 -> 1.000 FS  and  arm1+P7 -> 0.750 FS.')
    r1 = ladder(live, 0x9B, False, 6, 16)
    print('     arm1 measured: stored datum = %d.  FS = %d.  EXCESS = %+d.'
          % (r1[3], FSD, r1[3] - FSD))
    print('     ⇒ "1.000 FS" is 2**23 = %d, which is FS + 1: THE ARM STILL CLIPS, every frame,'
          % (1 << 23))
    print('       in both buckets.  It converts a 1.720 x FS clip into a 1.0000001 x FS clip.')
    print()

    # ---- §5  the fixed point ----------------------------------------------
    print('=== 5. IS `P_SHIFT = 7\' Q-CONSISTENT?  THE SOURCE\'S OWN ANSWER ===')
    i = src.index('THE FIXED POINT')
    print('   upd6383.h, verbatim:')
    for line in src[i - 8:i + 780].splitlines()[:14]:
        print('     ' + line.strip())
    print()
    print('   ⇒ THE TOTAL 22 IS FORCED AND MEASURED: coefficients are **Q1.22**, data Q0.23.')
    print('     P as a datum is (coef * L) >> (P_SHIFT + ACC_SHIFT) = >> 22, WHICHEVER split.')
    print('     A Q0.23 coefficient would want 23; a Q1.22 one wants 22.  22 SHIPS.')
    print('     ⇒ "P_SHIFT = 7 is the Q-consistent value" is FALSE unless the tie is broken,')
    print('       and breaking it contradicts the MEASURED Q1.22 coefficient scale.')
    print()
    print('   The three ladder coefficients read as Q1.22 (value / 2**22):')
    for cell in (0x9B, 0x9C, 0x9D):
        v = sx(live[cell])
        print('     C[0x%02X] = 0x%06X = %+9d  ->  Q1.22 %+.6f   Q0.23 %+.6f'
              % (cell, live[cell], v, v / float(1 << 22), v / float(1 << 23)))
    print('   ⇒ 1.2 / 1.0 / 1.0 exactly, in Q1.22.  Round coefficients, not noise.')
    print()
    print('   Is a TIED split even observable?  P as a datum, both ways, on these operands:')
    for cell in (0x9B, 0x9C):
        v = sx(live[cell])
        p6 = ((v * v) >> 6) >> 16
        p7 = ((v * v) >> 7) >> 15
        print('     C[0x%02X]^2 : split 6/16 -> %d   split 7/15 -> %d   %s'
              % (cell, p6, p7, 'IDENTICAL' if p6 == p7 else 'DIFFER'))
    print('   ⇒ single-term identity is exact (floor division by 2**m then 2**n == by 2**(m+n)).')
    print('     A MULTI-TERM sum can differ by 1 LSB because each product truncates separately,')
    print('     so the arm is NOT provably bit-identical -- it was predicted to be UNMOVED at the')
    print('     FS scale, which is a falsifiable prediction, and §227 built and ran it:')
    print()
    print('=== 6. AND HERE IS WHAT THE BUILD MEASURED (§227, four arms, 30 s each) ===')
    print('   arm  env                   P/ACC TOT | §S1 quiet  §S1 loud | iw34 datum | m_rf[0x8D]  §41')
    print('   N    (none, SHIPPED)        6/16  22 | 4.924 %    4.920 %  | 14 428 403 | 0x009B26 ✔  ✔')
    print('   O    UPD6383_NOCARRY=1      6/16  22 | 0.379 %    0.379 %  |  8 388 608 | ABSENT   ✘  ✔')
    print('   P    UPD6383_PSHIFT=1       7/15  22 | 4.924 %    4.920 %  | 14 428 403 | 0x009B26 ✔  ✔')
    print('   Q    UPD6383_PSHIFT=2       7/16  23 | 2.273 %    2.141 %  |  9 311 353 | 0x004D93 ✘  ✔')
    print()
    print('   ★ arm P: the ENTIRE §S1 saturation-census block is BIT-IDENTICAL to arm N over')
    print('     269 279 999 conversions -- the only differing line is the header text')
    print('     "pre-clamp acc >> 16" vs ">> 15".  THE TIED MOVE IS A MEASURED NO-OP.')
    print('   ★ arm O: iw34 clips 706040/706040 quiet and 313960/313960 loud -- IDENTICAL to')
    print('     shipped.  Its 13x clip-rate "win" is 117 655 680 accumulate steps refusing to')
    print('     add, and §104 body-0 goes 100 % input-INDEPENDENT (first DIFFERS at -1 = never).')
    print('   ⚠⚠ §41 is UNMOVED in EVERY arm, including the one that halves every product.')
    print('      §41 DOES NOT GUARD P_SHIFT.  m_rf[0x8D] = 39 718 is the guard that fires.')
    print('   ⛔ §54 is quiet-in 826 040 -> 826 040 SILENT / 0 LOUD (peak 0) in all four arms,')
    print('      and §70/§211 are mean 0.0 span 0 in both buckets in all four.  NO AUDIO CLAIM.')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
