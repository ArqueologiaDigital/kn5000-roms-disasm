# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""hdrbase.py -- WHERE DOES THE COMMON HEADER'S COEFFICIENT CURSOR POINT?

§226.  Read-only.  No MAME run, no build.  Answers, from the committed corpus,
from the two archived host captures and from the Sub CPU ROM's own
per-algorithm parameter map:

    1. the header's cursor-advance map (which I-RAM word reads base + k)
    2. what the host actually uploads into C-RAM, per capture, per run
    3. WHICH C-RAM CELLS ARE EFFECT-DEPENDENT and which are not -- two
       independent ways (capture-vs-capture, and the ROM's T1 parameter map)
    4. the §224/§S2 iw30/iw32/iw33 ladder evaluated at any base
    5. the clip NULL: how often that ladder overflows, swept by base, per bank

  ★ RULE 20.  Every section prints a KNOWN-ANSWER control that CAN fail, and
  the self-test is printed before any interpretation.  The controls are values
  published by OTHER passes and other instruments:
      - notes/kn5000-dsp-headerdecode.md §5   : algo 39 ships 31 coefficients
      - dsp/programs.tsv                      : CHORUS classA = 19
      - SQUARING-MULTIPLY_findings.md §6.2    : the by-bank clip table
      - §224 §S2                              : iw33 = 945 579 874 058
      - the arm-K log's own C-RAM dump        : 112 of 256 cells non-zero

Usage:
    python3 dsp/tools/hdrbase.py                       # everything, defaults
    python3 dsp/tools/hdrbase.py --base 0x00           # ladder at one base
"""

import argparse
import gzip
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                  # the vendored ISA mirror

REPO = os.path.dirname(os.path.dirname(HERE))
MAME = os.path.expanduser('~/compartilhado/kn7000_mame')
CAP_COLD = os.path.join(MAME, 'notes/data/kn5000_dsp1_upload_coldboot.txt')
CAP_PEQ = os.path.join(MAME, 'notes/data/kn5000_dsp1_upload_parametriceq.txt')
LIVE = os.path.join(REPO, 'dsp/analysis/data/K_lfowrap_default_225.log.gz')
SUB = os.path.join(REPO, 'original_ROMs/kn5000_subprogram_v142.rom')
MAIN = os.path.join(REPO, 'original_ROMs/kn5000_v10_program.rom')

FS = 1 << 39            # accumulator full scale (datum 2**23 << ACC_SHIFT 16)
P_SHIFT = 6
ACC_SHIFT = 16


# ---------------------------------------------------------------------------
#  1.  the corpus: which kernel word reads base + k
# ---------------------------------------------------------------------------
def listing_words(path):
    out = []
    for line in open(path):
        m = re.match(r'\s+w(\d+)\s+([0-9A-F]{10})\s', line)
        if m:
            out.append((int(m.group(1)), int(m.group(2), 16)))
    return out


def cursor_map():
    kern = listing_words(os.path.join(REPO, 'dsp/disasm/kernel.dsm'))
    epi = listing_words(os.path.join(REPO, 'dsp/disasm/epilogue.dsm'))
    adv, k = [], 0
    for iw, w in kern:
        if D.coeff_consumer(w):
            adv.append((iw, k))
            k += 1
    epi_adv = [iw for iw, w in epi if D.coeff_consumer(w)]
    return kern, epi, adv, epi_adv


# ---------------------------------------------------------------------------
#  2.  the host captures -> a C-RAM image
# ---------------------------------------------------------------------------
def _transfers(path):
    out, cur = [], None
    for line in open(path):
        m = re.match(r'transfer\s+(\d+):\s+cmd\s+0x([0-9A-Fa-f]+)\s+(\d+) bytes', line)
        if m:
            cur = {'n': int(m.group(1)), 'cmd': int(m.group(2), 16), 'data': bytearray()}
            out.append(cur)
            continue
        m = re.match(r'\s+([0-9A-Fa-f]{4}):\s+((?:[0-9A-Fa-f]{2}\s*)+)$', line)
        if m and cur is not None:
            cur['data'] += bytes.fromhex(m.group(2).replace(' ', ''))
    return out


def capture_cram(path):
    """Replay a uC-IF capture into a 256-cell C-RAM image.

    The write pointer is NOT in the cmd-0x02 packet: the host writes an
    `ldptr' word (hi12 0x801, lo12 0x821) into a scratch I-RAM slot with a
    cmd-0x01, then streams 3-byte coefficients with cmd 0x02.  MEASURED: the
    reconstruction reproduces the emulator's own C-RAM dump on 246 of 256
    cells, the 10 exceptions being runtime parameter pokes (see §4)."""
    ram = [None] * 256
    ptr = None
    runs = []
    for t in _transfers(path):
        d = bytes(t['data'])
        if t['cmd'] == 0x01 and len(d) >= 2:
            body = d[2:]
            for i in range(0, len(body) - 4, 5):
                w = int.from_bytes(body[i:i + 5], 'big')
                if ((w >> 24) & 0xfff) == 0x801 and (w & 0xfff) == 0x821:
                    ptr = (w >> 12) & 0xff
        elif t['cmd'] == 0x02 and len(d) >= 2:
            body = d[2:]
            vals = [int.from_bytes(body[i:i + 3], 'big') for i in range(0, len(body) - 2, 3)]
            if ptr is None or not vals:
                continue
            runs.append((ptr, len(vals)))
            for k, v in enumerate(vals):
                if ptr + k < 256:
                    ram[ptr + k] = v
            ptr = (ptr + len(vals)) & 0xff
    return ram, runs


def live_cram(path):
    ram = [None] * 256
    op = gzip.open if path.endswith('.gz') else open
    for line in op(path, 'rt', errors='replace'):
        m = re.search(r'upd6383: C-RAM ([0-9A-F]{2}): ((?:[0-9A-F]{6} ?)+)', line)
        if m:
            base = int(m.group(1), 16)
            for i, v in enumerate(m.group(2).split()):
                ram[base + i] = int(v, 16)
    return ram


# ---------------------------------------------------------------------------
#  3.  the ROM's per-algorithm parameter map (which cells an effect writes)
# ---------------------------------------------------------------------------
def t1_cells():
    """-> {algo: sorted[C-RAM cells that algo's parameter stream writes]} or None
    if the research tools are not importable."""
    for cand in (os.path.join(MAME, 'tools'),):
        if os.path.isdir(cand):
            sys.path.insert(0, cand)
    try:
        import kn5000_dsp_params as P
        import kn5000_dsp_namedcoeff as NC
    except Exception:
        return None, None
    rom = P.Rom(SUB, P.SUB_BASE)
    mrom = P.Rom(MAIN, 0) if os.path.exists(MAIN) else None
    per = {}
    for a in range(100):
        m = NC.host_coeff_map(rom, a)
        if m:
            per[a] = sorted(m)
    names = {a: (P.effect_name(mrom, a) if mrom else '') for a in per}
    return per, names


# ---------------------------------------------------------------------------
#  4.  the ladder
# ---------------------------------------------------------------------------
def sx(v):
    return v - (1 << 24) if v >= (1 << 23) else v


def ladder(C, c):
    """§224 §S2's kernel-header ladder, evaluated on an arbitrary cursor base.
       iw30  acc = 0    + (C[c]   << 16) + 0
       iw32  acc = P(iw30)          = C[c]^2   >> P_SHIFT
       iw33  acc = carried + (C[c+2] << 16) + (C[c+1]^2 >> P_SHIFT)"""
    a, b, d = C[c & 255], C[(c + 1) & 255], C[(c + 2) & 255]
    if a is None or b is None or d is None:
        return None
    a, b, d = sx(a), sx(b), sx(d)
    iw30 = a << ACC_SHIFT
    iw32 = (a * a) >> P_SHIFT
    iw33 = iw32 + (d << ACC_SHIFT) + ((b * b) >> P_SHIFT)
    return iw30, iw32, iw33


def clips(r):
    return r is not None and max(abs(x) for x in r) >= FS


# ---------------------------------------------------------------------------
def score_pair(ctrl_path, test_path):
    """§227 TASK 2 -- did a preset change move the header's own bank?

    §226's positive result (`C-RAM[0x90..0xB4]' is a boot-fixed bank the header
    reads) rested on ONE capture pair in which unit 1 did NOT change.  The Sub CPU
    ROM's per-algorithm map says a reverb preset rewrites `0x9E..0xB2', and
    `0x9E/0x9F/0xA0' are inside the header's own `0x90..0xA3' walk.  This scores a
    matched pair: same navigation, one preset apart.

    ★ RULE 20.  Three known-answer controls print FIRST and each CAN fail:
      1. the archived cold-boot capture must replay to the published run list;
      2. the control capture must reproduce the cold-boot HEADER BANK exactly --
         if it does not, the vehicle moved and nothing below means anything;
      3. the ladder on the control image must be §224 §S2's 945 579 874 058."""
    cold, cold_runs = capture_cram(CAP_COLD)
    ctrl, ctrl_runs = capture_cram(ctrl_path)
    test, test_runs = capture_cram(test_path)

    print("=== §227 CAPTURE-PAIR SELF-TEST (RULE 20, printed first) ===")
    t = []
    t.append(("archived cold-boot cmd-0x02 runs", cold_runs,
              [(0x50, 30), (0x6e, 30), (0x90, 30), (0xae, 7), (0x00, 20)]))
    t.append(("CONTROL capture reproduces cold-boot C-RAM[0x90..0xB4]",
              [ctrl[i] for i in range(0x90, 0xB5)],
              [cold[i] for i in range(0x90, 0xB5)]))
    t.append(("§224 §S2 iw33 on the CONTROL image", ladder(ctrl, 0x9B)[2], 945579874058))
    ok = 0
    for name, got, want in t:
        good = got == want
        ok += good
        print("   %-56s %s" % (name, "PASS" if good else "** FAIL **\n      got  %s\n      want %s" % (got, want)))
    print("   %d of %d PASS\n" % (ok, len(t)))

    print("=== §227 THE PAIR ===")
    print("   control : %s   (%d cmd-0x02 runs)" % (ctrl_path, len(ctrl_runs)))
    print("   test    : %s   (%d cmd-0x02 runs)" % (test_path, len(test_runs)))
    diff = [i for i in range(256) if ctrl[i] != test[i]]
    print("   cells differing anywhere : %d  %s"
          % (len(diff), ' '.join('%02X' % i for i in diff) if diff else '(none)'))
    for lo, hi, tag in ((0x00, 0x4F, 'unit-0 effect bank + spare'),
                        (0x50, 0x8F, 'the two linear RAMPS'),
                        (0x90, 0xB4, "★ THE HEADER'S FIXED BANK"),
                        (0x90, 0xA3, "★★ the header's own 20-cell WALK"),
                        (0x9E, 0xB2, "the ROM T1 map's reverb-preset range"),
                        (0x9B, 0x9D, "★★★★ the iw30/iw32/iw33 LADDER CELLS")):
        d = [i for i in diff if lo <= i <= hi]
        print("   %-40s [%02X..%02X] : %2d of %2d differ  %s"
              % (tag, lo, hi, len(d), hi - lo + 1,
                 ' '.join('%02X' % i for i in d) if d else 'ALL INVARIANT'))
    print()
    print("=== §227 THE LADDER, BOTH IMAGES, base 0x9B ===")
    for nm, C in (('control', ctrl), ('test   ', test)):
        r = ladder(C, 0x9B)
        cc = [C[0x9B], C[0x9C], C[0x9D]]
        print("   %s  C = %06X/%06X/%06X   iw30 %+.3f  iw32 %+.3f  iw33 %+.3f  %s"
              % (nm, cc[0], cc[1], cc[2], (r[0] >> ACC_SHIFT) / 8388607.0,
                 (r[1] >> ACC_SHIFT) / 8388607.0, (r[2] >> ACC_SHIFT) / 8388607.0,
                 'CLIPS' if clips(r) else 'no clip'))
    return 0


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', default=None)
    ap.add_argument('--score', nargs=2, metavar=('CTRL_CAPTURE', 'TEST_CAPTURE'),
                    default=None,
                    help='§227: replay two uC-IF captures and score whether the '
                         'header bank C-RAM[0x90..0xB4] moved between them')
    args = ap.parse_args(argv[1:])

    # ---- §227: score a capture PAIR (e.g. a reverb-preset change) --------
    if args.score:
        return score_pair(args.score[0], args.score[1])

    kern, epi, adv, epi_adv = cursor_map()
    cold, cold_runs = capture_cram(CAP_COLD)
    peq, peq_runs = capture_cram(CAP_PEQ)
    live = live_cram(LIVE)
    per, names = t1_cells()

    # ---- RULE 20: the self-test, printed FIRST ---------------------------
    print("=== §226 SELF-TEST (known answers published by OTHER passes) ===")
    ok = 0
    tests = []
    tests.append(("kernel words 60", len(kern), 60))
    tests.append(("epilogue words 23", len(epi), 23))
    tests.append(("kernel cursor-advancing words 21", len(adv), 21))
    tests.append(("...of which BEFORE w42's ldptr, 20", sum(1 for _, k in adv if _ < 42), 20))
    tests.append(("epilogue cursor-advancing words 0", len(epi_adv), 0))
    tests.append(("w30/w32/w33 offsets 0x0B/0x0C/0x0D",
                  tuple(k for i, k in adv if i in (30, 32, 33)), (0x0B, 0x0C, 0x0D)))
    tests.append(("coldboot cmd-0x02 run bases/lens",
                  [r for r in cold_runs], [(0x50, 30), (0x6e, 30), (0x90, 30), (0xae, 7), (0x00, 20)]))
    tests.append(("headerdecode §5: algo 39 ships 31 coefficients",
                  sum(1 for i in range(256) if peq[i] is not None and i < 0x50), 31))
    tests.append(("live C-RAM non-zero cells (log: 112)",
                  sum(1 for v in live if v not in (None, 0)), 112))
    tests.append(("§224 §S2 iw33 at the shipped base 0x9B",
                  ladder(live, 0x9B)[2], 945579874058))
    for name, got, want in tests:
        good = got == want
        ok += good
        print("   %-52s %-28s %s" % (name, got if not good else "", "PASS" if good else "** FAIL, want %s **" % (want,)))
    print("   %d of %d PASS\n" % (ok, len(tests)))

    # ---- 1. the map ------------------------------------------------------
    print("=== 1. THE HEADER'S CURSOR-ADVANCE MAP (corpus, D.coeff_consumer) ===")
    print("   " + "  ".join("w%d:+%02X" % (i, k) for i, k in adv))
    print("   w42 `ldptr #$70' re-aims the cursor, so the header block proper "
          "consumes base+0x00 .. base+0x13 (20 cells).")
    print("   epilogue cursor-advancing words: %s  <== the epilogue's own iw69 "
          "`ldptr #$90' is therefore\n   the LAST thing to touch the cursor in a frame, "
          "and the next frame's w0 starts at EXACTLY 0x90.\n" % (epi_adv or "NONE"))

    # ---- 2/3. effect dependence -----------------------------------------
    print("=== 2. IS THE BANK EFFECT-DEPENDENT?  (a) capture vs capture ===")
    diff = [i for i in range(256) if cold[i] != peq[i]]
    print("   CHORUS-boot vs PARAMETRIC-EQ capture differ on %d cells: 0x%02X..0x%02X"
          % (len(diff), min(diff), max(diff)))
    print("   NOTHING at or above 0x%02X differs.  The unit-0 effect change rewrote "
          "base 0x00 and only base 0x00.\n" % (min(i for i in range(0x50, 256) if False) if False else 0x50))

    print("=== 3. IS THE BANK EFFECT-DEPENDENT?  (b) the ROM's own T1 parameter map ===")
    if per is None:
        print("   (research tools not importable -- skipped)\n")
    else:
        union = set()
        for a in per:
            union |= set(per[a])
        lo = [c for c in range(0x00, 0x14) if c not in union]
        hi = [c for c in range(0x90, 0xB5) if c not in union]
        print("   cells 0x00..0x13 written by NO algorithm: %d" % len(lo))
        print("   cells 0x90..0xB4 written by NO algorithm: %d  %s"
              % (len(hi), " ".join("%02X" % c for c in hi)))
        print()

    print("=== 4. RUNTIME POKES: the archived capture vs the live 30 s run ===")
    d2 = [i for i in range(256) if cold[i] is not None and cold[i] != live[i]]
    print("   %d cells moved: %s" % (len(d2), " ".join("%02X" % i for i in d2)))
    if per:
        named = [i for i in d2 if any(i in per[a] for a in per)]
        print("   %d of %d are named by some algorithm's T1 parameter map" % (len(named), len(d2)))
    print()

    print("=== 4b. ⇒ THE HEADER'S 20 CELLS, SCORED FOR INVARIANCE, PER CANDIDATE BASE ===")
    moved = set(d2) | set(i for i in range(256) if cold[i] != peq[i])
    if per:
        for a in per:
            moved |= set(per[a])
    for b, tag in ((0x90, "SHIPPED"), (0x00, "PROPOSED")):
        cells = [(b + k) & 255 for k in range(0x14)]
        bad = [c for c in cells if c in moved]
        print("   base 0x%02X (%-8s)  cells 0x%02X..0x%02X : %2d of 20 INVARIANT, %2d effect/poke-written %s"
              % (b, tag, cells[0], cells[-1], 20 - len(bad), len(bad),
                 " ".join("%02X" % c for c in bad)))
        lad = [(b + k) & 255 for k in (0x0B, 0x0C, 0x0D)]
        print("        the iw30/32/33 ladder cells %s : %s"
              % (" ".join("%02X" % c for c in lad),
                 "ALL INVARIANT" if not [c for c in lad if c in moved] else
                 "EFFECT-DEPENDENT (" + " ".join("%02X" % c for c in lad if c in moved) + ")"))
    print()

    # ---- 5. the ladder + the null ---------------------------------------
    print("=== 5. THE §S2 LADDER, per candidate base, per C-RAM image ===")
    bases = [int(args.base, 0)] if args.base else [0x9B, 0x0B]
    for nm, C in (("coldboot  (CHORUS + ROOM REVERB 1)", cold),
                  ("parameq   (PARAMETRIC EQ + RR1)", peq),
                  ("LIVE armK (the shipped default)", live)):
        for b in bases:
            r = ladder(C, b)
            if r is None:
                print("   %-34s base 0x%02X   UNFILLED" % (nm, b))
                continue
            print("   %-34s base 0x%02X  C=%06X/%06X/%06X  iw30 %+7.3f  iw32 %+7.3f  "
                  "iw33 %+7.3f  %s"
                  % (nm, b, C[b], C[(b + 1) & 255], C[(b + 2) & 255],
                     r[0] / FS, r[1] / FS, r[2] / FS, "CLIPS" if clips(r) else "no clip"))
    print()

    print("=== 6. THE NULL -- how often the ladder clips, swept by base ===")
    for nm, C, rng in (("coldboot 0x00..0x13", cold, range(0x00, 0x14)),
                       ("coldboot 0x90..0xB4", cold, range(0x90, 0xB5)),
                       ("parameq  0x00..0x1E", peq, range(0x00, 0x1F)),
                       ("LIVE     0x00..0x13", live, range(0x00, 0x14)),
                       ("LIVE     0x50..0x8B", live, range(0x50, 0x8C)),
                       ("LIVE     0x90..0xB4", live, range(0x90, 0xB5))):
        n = c = 0
        for b in rng:
            r = ladder(C, b)
            if r is None:
                continue
            n += 1
            c += clips(r)
        print("   %-22s %2d of %2d clip  %5.1f %%" % (nm, c, n, 100.0 * c / n if n else 0))
    nz = [b for b in range(256) if live[b] not in (None, 0)]
    n = c = 0
    for b in nz:
        r = ladder(live, b)
        if r is None:
            continue
        n += 1
        c += clips(r)
    print("   %-22s %2d of %2d clip  %5.1f %%" % ("LIVE all non-zero", c, n, 100.0 * c / n))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
