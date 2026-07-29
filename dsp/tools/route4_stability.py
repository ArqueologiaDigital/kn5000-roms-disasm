#!/usr/bin/env python3
"""ROUTE 4 -- BOUND THE REVERB PER-STAGE FEEDBACK GAIN FROM STABILITY AND FROM
THE LADDER'S STRUCTURE.   NEC uPD6383GF-3BA (IC311), 2026-07-29.  No hardware.

Every delay comes from the descriptor bank (`delayline.lines_of`) and every
gain from the C-RAM coefficient stream (`delayline.coefs_of` at the unit-1
base 0x90, `cram-unit-base.md` item A).  Nothing is fitted; no number here is
invented to make a loop stable.

RESULT, in one line: the per-stage feedback gain is NOT missing -- it is
C-RAM 0x98..0x9C (ladder 0) and 0xA1..0xA4 (ladder 1) of the unit-1 bank --
and STABILITY, applied for the first time, DECIDES `schroeder-topology.md'
sect.6.4's open write-source question against the 84/112 majority.

    python3 dsp/tools/route4_stability.py where      1  where the chip keeps it
    python3 dsp/tools/route4_stability.py struct     2  the structure, from ROM
    python3 dsp/tools/route4_stability.py t60        3  T60 per line
    python3 dsp/tools/route4_stability.py mason      4  Mason determinant
    python3 dsp/tools/route4_stability.py invert     5  the gain a T60 requires
    python3 dsp/tools/route4_stability.py decide     6  ** THE DISCRIMINATOR **
    python3 dsp/tools/route4_stability.py band       7  the forced gain band
    python3 dsp/tools/route4_stability.py poles      8  cascade poles, analytic
    python3 dsp/tools/route4_stability.py control    9  the NULLs -- can it fail?
    python3 dsp/tools/route4_stability.py all
"""
import sys, os, math, random

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import delayline as D

FS = 44100.0
REVERBS = list(range(16, 28))

# Index of each block's class-A coefficients inside the 33-entry cursor walk.
# The block layout is `reverb-topology-round7.md' sect.2's B A^5 B A^4 B C C;
# it is CROSS-CHECKED here, not assumed -- see `where'.
IDX = dict(head=(0, 1, 2), prologue=(3, 4, 5, 6, 7),
           ladder0=(8, 9, 10, 11, 12), blockB1=(13, 14, 15, 16),
           ladder1=(17, 18, 19, 20), blockB2=(21, 22, 23, 24),
           blockC1=(25, 26, 27, 28), blockC2=(29, 30, 31, 32))


def gains(a):
    p = D.program(a)
    c = [x for x in D.coefs_of(a, p.words) if x is not None]
    return [(v - 0x1000000 if v >= 0x800000 else v) / 2.0**23 for v in c], p.name


def delays(a):
    return {i: l.samples for i, l in enumerate(D.lines_of(a))}


def stage_gains(a, bmode='max'):
    """the eleven repetition gains g_1..g_11; BLOCK B's four collapsed."""
    g, nm = gains(a)
    if len(g) != 33:
        return None, nm
    out = []
    for r in range(1, 12):
        if 1 <= r <= 5:
            out.append(g[IDX['ladder0'][r - 1]])
        elif 7 <= r <= 10:
            out.append(g[IDX['ladder1'][r - 7]])
        else:
            q = [g[i] for i in (IDX['blockB1'] if r == 6 else IDX['blockB2'])]
            if bmode == 'max':
                out.append(max(q, key=abs))
            elif bmode == 'first':
                out.append(q[0])
            elif bmode == 'prod':
                p = 1.0
                for v in q:
                    p *= v
                out.append(p)
            else:
                out.append(1.0)
    return out, nm


def t60(Dsamp, G):
    G = abs(G)
    return float('inf') if (G <= 0 or G >= 1) else (Dsamp / FS) * 3.0 / math.log10(1.0 / G)


def gain_for_t60(Dsamp, T):
    return 10.0 ** (-3.0 * (Dsamp / FS) / T)


# ------------------------------------------------------------------ machines
def sim(dd, gg, gap, N, alpha=1.0, family='nested', sign=1.0):
    """Literal ring-buffer execution.  `nested' = the line stores the
    multiplicand u = w + t_prev (sect.6.4 row 1, 84 of 112 survivors);
    `cascade' = the line stores t_k one repetition late (row 2, 28 of 112)."""
    R = 11
    if family == 'nested':
        need = {k for r in range(1, R + 1) for k in (r - 1, r - 1 + gap)}
        buf = {k: [0.0] * max(1, dd[k]) for k in need if k in dd}
    else:
        buf = {k: [0.0] * max(1, dd[k]) for k in range(1, R + 1) if k in dd}
    out = []
    for n in range(N):
        t = 1.0 if n == 0 else 0.0
        if family == 'nested':
            for r in range(1, R + 1):
                kr, kw = r - 1 + gap, r - 1
                u = (buf[kr][n % len(buf[kr])] if kr in buf else 0.0) + t
                if kw in buf:
                    buf[kw][n % len(buf[kw])] = u
                t = sign * gg[r - 1] * alpha * u
        else:
            for k in range(1, R + 1):
                t = sign * gg[k - 1] * alpha * (t + (buf[k][n % len(buf[k])] if k in buf else 0.0))
                if k in buf:
                    buf[k][n % len(buf[k])] = t
        if not math.isfinite(t) or abs(t) > 1e100:
            return None
        out.append(t)
    return out


def rate(ir, blk=2205, skip=6):
    """per-sample envelope ratio rho, log-linear fit of block RMS."""
    if not ir:
        return None
    r = [math.sqrt(sum(v * v for v in ir[b * blk:(b + 1) * blk]) / blk)
         for b in range(len(ir) // blk)]
    pts = [(b, math.log(v)) for b, v in enumerate(r) if b >= skip and v > 0]
    if len(pts) < 6:
        return None
    n = len(pts)
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    den = sum((p[0] - mx) ** 2 for p in pts)
    if den == 0:
        return None
    return math.exp((sum((p[0] - mx) * (p[1] - my) for p in pts) / den) / blk)


def t60_of(rho):
    if rho is None:
        return None
    return float('inf') if rho >= 1.0 else 3.0 / math.log10(1.0 / rho) / FS


def verdict(dd, gg, family, gap=2, alpha=1.0, N=None):
    ir = sim(dd, gg, gap, N or int(2 * FS), alpha, family)
    if ir is None:
        return None, "UNSTABLE (overflow)"
    rho = rate(ir)
    if rho is None:
        return None, "no envelope"
    if rho >= 1.0:
        return float('inf'), "UNSTABLE rho=%.7f" % rho
    T = t60_of(rho)
    return T, "T60 = %.3f s" % T


# ------------------------------------------------------------------ sections
def sec_where():
    print("=" * 78)
    print("1.  WHERE THE CHIP KEEPS THE PER-STAGE GAIN  -- MEASURED")
    print("=" * 78)
    print("""
C-RAM, unit-1 coefficient bank, base 0x90.  The cursor advances +1 per class-A
word from that base, so the cell each stage reads is arithmetic.  All 33
class-A words of every reverb resolve; 0 of 33 resolve at base 0x00.
""")
    for a in REVERBS:
        g, nm = gains(a)
        if len(g) != 33:
            print("  algo %2d %-18s LAYOUT DIFFERS (%d cells)" % (a, nm, len(g)))
            continue
        print("  algo %2d %-18s ladder0(0x98..0x9C) %s | ladder1(0xA1..0xA4) %s" % (
            a, nm, " ".join("%+.4f" % g[i] for i in IDX['ladder0']),
            " ".join("%+.4f" % g[i] for i in IDX['ladder1'])))
    print("""
  STRUCTURAL SELF-CHECK, not a fit: the interlude BLOCK B (cursor 0x9D..0xA0)
  and the tail BLOCK B (0xA5..0xA8) must carry the SAME four coefficients if
  the block decomposition and the cursor base are both right.""")
    for a in REVERBS:
        g, nm = gains(a)
        if len(g) != 33:
            continue
        b1 = [g[i] for i in IDX['blockB1']]
        b2 = [g[i] for i in IDX['blockB2']]
        print("   algo %2d %-18s B1 == B2 : %-5s  %s" % (
            a, nm, b1 == b2, " ".join("%+.4f" % v for v in b1)))


def sec_struct():
    print("\n" + "=" * 78)
    print("2.  THE STRUCTURE, FROM THE ROM")
    print("=" * 78)
    print("""
 11 recirculating delay lines L1..L11, laid CONTIGUOUSLY in the external DRAM
 (every line's read address is the next line's write address), plus ONE buffer
 at the unit base carrying SIX or SEVEN taps -- the pre-delay / early
 reflections, read by the head, by the tail BLOCK B and by both BLOCK Cs.
 Repetition r writes L(r-1) and reads L(r+1).
""")
    for a in REVERBS:
        dd = delays(a)
        p = D.program(a)
        base = 32768
        er = sorted({p.cells[k] - base for k, (wi, w) in enumerate(p.cons)
                     if not ((w >> 12) & 0x40) and base - 2 <= p.cells[k] < base + 8192})
        rec = [dd[k] for k in range(1, 12)]
        print("  algo %2d %-18s ladder %s  span %5d = %6.1f ms" % (
            a, p.name, " ".join("%4d" % v for v in rec), sum(rec), 1000 * sum(rec) / FS))
        print("      %-18s   ER/pre taps %s" % ("", er))


def sec_t60():
    print("\n" + "=" * 78)
    print("3.  T60 PER LINE FROM THE ROM'S OWN GAINS -- both loop readings")
    print("=" * 78)
    print("""
 READING 1 (one multiply in the loop, schroeder-topology.md sect.6.3 algebra):
     loop gain of the line read at repetition r  =  g_r
 READING 2 (two multiplies -- the CORRECTED polarity ledger of round 7 puts
     line k's read at rep k-1 and its write at rep k+1):  gain = g_(k-1)*g_k
""")
    print("  %-20s %-30s %-30s" % ("preset", "READING 1 worst line", "READING 2 worst line"))
    for a in REVERBS:
        dd, (g, nm) = delays(a), gains(a)
        if len(g) != 33:
            continue
        gg, _ = stage_gains(a)
        r1 = [(r + 1, dd[r + 1], gg[r - 1], t60(dd[r + 1], gg[r - 1]))
              for r in list(range(1, 6)) + list(range(7, 11))]
        r2 = [(k, dd[k], gg[k - 2] * gg[k - 1], t60(dd[k], gg[k - 2] * gg[k - 1]))
              for k in range(2, 12)]
        b1, b2 = max(r1, key=lambda t: t[3]), max(r2, key=lambda t: t[3])
        print("  algo %2d %-16s %6.3f s (L%-2d D=%4d g=%.3f)  %6.3f s (L%-2d D=%4d g=%.3f)" % (
            a, nm, b1[3], b1[0], b1[1], b1[2], b2[3], b2[0], b2[1], b2[2]))


def delta1(G):
    p2, p1 = 1.0, 1.0
    for L in G:
        p2, p1 = p1, p1 - L * p2
    return p1


def sec_mason():
    print("\n" + "=" * 78)
    print("4.  MASON DETERMINANT OF THE NESTED CHAIN -- exact, delays drop out")
    print("=" * 78)
    print("""
 Edges u(k+1) --z^-Dk--> u(k) and u(k) --g_k--> u(k+1).  The only SIMPLE cycles
 are the 2-cycles L_k = G_k z^-Dk, overlapping in a chain, so

     P_0 = P_1 = 1 ,   P_j = P_(j-1) - L_(j-1) * P_(j-2)

 At z = 1 every z^-D is 1, so Delta(1) depends ONLY on the gains.  Delta -> 1
 as |z| -> inf, so Delta(1) < 0 puts a real pole outside the unit circle.
 Hand check, independent of the recursion: three nested stages, open end,
   u2[n](1 - g2 z^-D2 - g1 z^-D1) = g1 x  =>  Delta(1) = 1 - g1 - g2.
 The ROM's own first two ladder gains give 1 - 0.75 - 0.63 = -0.38.
""")
    print("  %-20s %8s %12s" % ("preset", "sum|g|", "Delta(1)"))
    for a in REVERBS:
        gg, nm = stage_gains(a)
        if gg is None:
            continue
        G = [gg[r - 1] for r in list(range(1, 6)) + list(range(7, 11))]
        print("  algo %2d %-16s %8.3f %12.4f  %s" % (
            a, nm, sum(abs(x) for x in G), delta1(G),
            "REAL POLE OUTSIDE |z|=1" if delta1(G) < 0 else ""))


def sec_invert():
    print("\n" + "=" * 78)
    print("5.  THE INVERSION -- what loop gain a T60 of 0.5..4 s REQUIRES")
    print("=" * 78)
    print("\n  |G| = 10^(-3 D / (Fs T)) for a single recirculating loop of delay D.\n")
    print("  %-20s %6s %8s %8s %8s %8s  %8s" % (
        "preset", "Dmax", "g@0.5s", "g@1s", "g@2s", "g@4s", "ROM gmax"))
    for a in REVERBS:
        dd = delays(a)
        gg, nm = stage_gains(a)
        if gg is None:
            continue
        Dm = max(dd[k] for k in range(1, 12))
        print("  algo %2d %-16s %6d %8.4f %8.4f %8.4f %8.4f  %8.4f" % (
            a, nm, Dm, gain_for_t60(Dm, .5), gain_for_t60(Dm, 1),
            gain_for_t60(Dm, 2), gain_for_t60(Dm, 4), max(abs(x) for x in gg)))


def sec_decide():
    print("\n" + "=" * 78)
    print("6.  ** STABILITY SEPARATES SECT.6.4's TWO WRITE-SOURCE FAMILIES **")
    print("=" * 78)
    print("""
 schroeder-topology.md sect.6.4 left the write source CONSISTENT-not-forced:
   bus / acc_before / acc_after  (84 of 112) -> the line stores the
        multiplicand u = w + t_prev            = the NESTED chain
   mem[ptr]                      (28 of 112) -> the line stores t_k one
        repetition late                        = a SERIES CASCADE of combs
 No published search ever applied STABILITY.  Applied here at the ROM's own
 gains and delays, 2 s impulse, dominant-pole rate from a log-RMS fit:
""")
    print("  %-20s %-24s %-24s" % ("preset", "NESTED (84/112)", "CASCADE (28/112)"))
    for a in REVERBS:
        dd = delays(a)
        gg, nm = stage_gains(a)
        if gg is None:
            continue
        _, sa = verdict(dd, gg, 'nested')
        _, sb = verdict(dd, gg, 'cascade')
        print("  algo %2d %-16s %-24s %-24s" % (a, nm, sa, sb))
    print("\n  gap = 1 (schroeder sect.6.3 indexing), so the verdict does not rest")
    print("  on the round-7 descriptor gap:")
    for a in REVERBS:
        dd = delays(a)
        gg, nm = stage_gains(a)
        _, s = verdict(dd, gg, 'nested', gap=1)
        print("  algo %2d %-16s nested gap=1: %s" % (a, nm, s))
    print("\n  SIGN CONTROL -- t = -g*u, the one free choice that could rescue")
    print("  the nested family by making every cycle gain negative:")
    for a in (16, 20, 26):
        dd = delays(a)
        gg, nm = stage_gains(a)
        ir = sim(dd, gg, 2, int(2 * FS), 1.0, 'nested', sign=-1.0)
        rho = rate(ir) if ir else None
        print("  algo %2d %-16s nested sign=-1: %s" % (
            a, nm, "UNSTABLE (overflow)" if ir is None else
            ("UNSTABLE rho=%.7f" % rho if rho and rho >= 1 else "T60 = %.3f s" % t60_of(rho))))
    print("\n  BLOCK-B COLLAPSE SENSITIVITY (its four multiplies are not resolved):")
    for bm in ('max', 'first', 'prod', 'unity'):
        dd = delays(16)
        gg, _ = stage_gains(16, bm)
        _, sa = verdict(dd, gg, 'nested')
        _, sb = verdict(dd, gg, 'cascade')
        print("      B=%-6s nested %-24s cascade %s" % (bm, sa, sb))


def _edge(dd, gg, family, gap=2, N=None):
    N = N or int(2 * FS)
    lo, hi = 0.0, 3.0
    for _ in range(16):
        m = .5 * (lo + hi)
        T, _s = verdict(dd, gg, family, gap, m, N)
        if T is not None and T < 60:
            lo = m
        else:
            hi = m
    return lo


def sec_band():
    print("\n" + "=" * 78)
    print("7.  THE GAIN BAND THE STRUCTURE FORCES")
    print("=" * 78)
    print("\n  alpha = uniform scale on every stage gain.  alpha = 1.0 is the ROM.\n")
    N = int(2 * FS)
    print("  %-20s %-28s %-28s" % ("", "NESTED", "CASCADE"))
    print("  %-20s %9s %9s %9s %9s %9s %9s" % (
        "preset", "a_stable", "a@.5s", "a@4s", "a_stable", "a@.5s", "a@4s"))
    for a in (16, 20, 26):
        dd = delays(a)
        gg, nm = stage_gains(a)
        row = []
        for fam in ('nested', 'cascade'):
            e = _edge(dd, gg, fam)
            band = []
            for target in (0.5, 4.0):
                lo, hi = 0.0, e
                for _ in range(16):
                    m = .5 * (lo + hi)
                    T, _s = verdict(dd, gg, fam, 2, m, N)
                    if T is not None and T < target:
                        lo = m
                    else:
                        hi = m
                band.append(.5 * (lo + hi))
            row += [e] + band
        print("  algo %2d %-16s %9.4f %9.4f %9.4f %9.4f %9.4f %9.4f" % (
            a, nm, row[0], row[1], row[2], row[3], row[4], row[5]))
        gmax = max(abs(x) for x in gg)
        print("      implied largest stage gain: NESTED %.4f..%.4f  CASCADE %.4f..%.4f"
              "   (ROM loads %.4f)" % (row[1] * gmax, row[2] * gmax,
                                       row[4] * gmax, row[5] * gmax, gmax))


def sec_poles():
    print("\n" + "=" * 78)
    print("8.  CASCADE POLES, ANALYTIC -- no simulation, no ALU model")
    print("=" * 78)
    print("""
 In the cascade family each line is an independent feedback comb with pole
 radius |g_k|^(1/D_k); the cascade decays at the slowest of them.
""")
    for a in REVERBS:
        dd = delays(a)
        gg, nm = stage_gains(a)
        if gg is None:
            continue
        T = [(k, t60(dd[k], gg[k - 1])) for k in range(1, 12)]
        best = max(T, key=lambda t: t[1])
        print("  algo %2d %-16s T60 = %.3f s  (L%d D=%d g=%.3f)   per line: %s" % (
            a, nm, best[1], best[0], dd[best[0]], gg[best[0] - 1],
            " ".join("%.2f" % t for _, t in T)))


def sec_control():
    print("\n" + "=" * 78)
    print("9.  THE NULLS -- can this instrument fail?")
    print("=" * 78)
    dd, N = delays(16), int(2 * FS)
    gg, _ = stage_gains(16)
    print("\n  (a) the answer MUST move with alpha (ROOM REVERB 1, nested, gap=2):")
    for al in (0.25, 0.5, 0.75, 1.0, 1.5, 2.0):
        T, s = verdict(dd, gg, 'nested', 2, al, N)
        print("      alpha=%.2f  %s" % (al, s))
    print("\n  (b) and for the cascade family, which must ALSO be able to blow up:")
    for al in (0.5, 1.0, 1.3, 1.4, 2.0):
        T, s = verdict(dd, gg, 'cascade', 2, al, N)
        print("      alpha=%.2f  %s" % (al, s))
    print("\n  (c) NULL for the near-zero Mason determinant: is |Delta(1)| small")
    print("      because the ROM chose it, or because 9 stages at g~0.5 always are?")
    g16, _ = gains(16)
    rom = [g16[i] for i in IDX['ladder0']] + [g16[i] for i in IDX['ladder1']]
    random.seed(20260729)
    hits = neg = 0
    mags = []
    for _ in range(100000):
        r = [random.uniform(0.3, 0.8) for _ in range(9)]
        d = delta1(r)
        mags.append(abs(d))
        hits += abs(d) <= 0.13
        neg += d < 0
    mags.sort()
    print("      ROM: sum|g|=%.3f  Delta(1)=%+.4f" % (sum(abs(v) for v in rom), delta1(rom)))
    print("      100000 random 9-stage sets, g ~ U(0.30,0.80):")
    print("        P(|Delta(1)|<=0.13) = %.4f   median |Delta(1)| = %.4f   P(Delta(1)<0) = %.4f"
          % (hits / 1e5, mags[len(mags) // 2], neg / 1e5))
    print("      => the ROM's near-zero determinant is NOT distinctive.  It is")
    print("         reported so nobody reads design intent into it.")
    print("\n  (d) GLOBAL x2 DELAY UNCERTAINTY (r1-allpass-motif.md sect.3: 17 vs 18")
    print("      delay address bits is OPEN).  Every T60 scales linearly:")
    for mult in (0.5, 1.0, 2.0):
        d2 = {k: max(1, int(v * mult)) for k, v in dd.items()}
        _, s = verdict(d2, gg, 'cascade', 2, 1.0, N)
        print("      delays x%.1f  cascade %s" % (mult, s))


SECTIONS = [("where", sec_where), ("struct", sec_struct), ("t60", sec_t60),
            ("mason", sec_mason), ("invert", sec_invert), ("decide", sec_decide),
            ("band", sec_band), ("poles", sec_poles), ("control", sec_control)]

if __name__ == '__main__':
    want = sys.argv[1] if len(sys.argv) > 1 else 'all'
    for nm, fn in SECTIONS:
        if want in ('all', nm):
            fn()
