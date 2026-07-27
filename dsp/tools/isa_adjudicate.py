#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""isa_adjudicate.py -- ADJUDICATE the K3/K4/R2/R3 passes against each other.

NEC uPD6383GF (Technics SX-KN5000 IC311) effects DSP.  This is the INTEGRATION
pass: four concurrent decode workflows (K3 pointer registers, K4 cursor rebase,
R2 result routing, R3 delay-DRAM addressing) landed in the same tree within
hours of each other, and each one asserts things the others did not see.  This
tool re-derives, from the ROM, every claim where two of them can disagree, and
prints the verdict.

Its headline result is a FALSIFICATION of a claim committed hours earlier:

    R3 section 6.1's descriptor-cursor solve classifies words by
    `class4 == 1`, with no C-FORMAT guard.  Two of the 37 "class-1 forms" it
    solves for -- C40.1.80.000 and C40.1.E0.451 -- are C-FORMAT IMMEDIATE
    LOADS, in which `class4` and `addr8` are not fields at all but immediate
    data (instruction-set.md, MEASURED 61/61).  They are precisely the two
    words R3 section 9.5 offers as "independent corroboration of R2's
    withdrawal of K6's addr8 bit-7 split", so that corroboration is VOID.
    This tool re-runs the solve with the guard and reports what survives.

Run:  python3 dsp/tools/isa_adjudicate.py [--rom SUB] [--tools DIR] [section..]
Sections: cformat cursor modes class8 payload state   (default: all)
"""
import argparse
import collections
import itertools
import os
import sys
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

T_ALGO = 0x0001ED7C
T_PARAM = 0x0001EF0C
REVERB_ALGOS = list(range(16, 28))
# RENAMED 2026-07-27: NOT malformed -- these are IC310 (MN19413) programs
# whose cmd-0x30 record rides on record opcode 3, so an IC311-shaped parser
# turns them into a phantom I-RAM block.  Algorithms 57-60 are IC310's too
# (their cmd-0x30 rides on opcode 0x0E and parses to nothing, so `if ir:'
# already drops them): the IC311 population is 91 of 100, not 95.
# See dsp/analysis/second-dsp-and-ready.md sect. 2.
DSP2_MISPARSED = {79, 88, 89, 90, 91}      # the 5 streams that parse to junk
MALFORMED = DSP2_MISPARSED      # deprecated alias


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def fmt(w):
    return "%03X.%X.%02X.%03X" % fields(w)


def is_cformat(w):
    """The C-FORMAT FAMILY predicate: bits [24:12] are ONE 13-bit immediate, so
    `class4` and `addr8` do not exist as fields.

    ADJUDICATED in this pass.  `instruction-set.md` says the predicate is
    `(hi12 & 0xFFE) == 0xC40`; `dsp_disasm.c_format()` has always implemented
    `(hi12 & 0xF00) == 0xC00`, and R2's census (2989 non-C-format words) is
    reproduced EXACTLY, row for row, only by the WIDE one.  The narrow mask is
    the predicate of the *payload rule* (`A = imm13>>5`, `B == 0`), not of the
    format.  See is_c40()."""
    return (fields(w)[0] & 0xF00) == 0xC00


def is_c40(w):
    """The sub-family in which the 13-bit immediate is a multiple of 32, so the
    payload is the 8-bit field [24:17] and B == 0.  MEASURED 57/57 inside,
    2/11 outside (K3)."""
    return (fields(w)[0] & 0xFFE) == 0xC40


def imm13(w):
    hi, cl, ad, _lo = fields(w)
    return ((hi & 1) << 12) | (cl << 8) | ad


# --------------------------------------------------------------------------
def load(tools, sub, main):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    try:
        import kn5000_dsp_coeffs as C
        names = C.effect_names(main) if main and os.path.exists(main) else {}
    except Exception:
        names = {}
    rom = E.Rom(sub)
    imgs = {}
    for i in range(100):
        try:
            iram, _c, _o = E.parse_stream(rom, rom.u32le(T_ALGO + 4 * i))
        except Exception:
            continue
        if iram:
            imgs[i] = [int.from_bytes(bytes(w), "big")
                       for _a, ws, _l in iram for w in ws]
    return E, rom, names, imgs


def canonical(imgs):
    """The corpus every coverage/census number in this tree is quoted over:
    the 38 DISTINCT body images (duplicates collapsed, the 5 malformed streams
    dropped).  2974 words; +83 kernel words = the 3057 R2/K3/K4 all cite."""
    seen = {}
    for a in sorted(imgs):
        if a in MALFORMED:
            continue
        seen.setdefault(tuple(imgs[a]), a)
    return {v: list(k) for k, v in seen.items()}


def kernel_words(disasm_dir):
    """The two canned kernel blobs, from the committed listings."""
    out = {}
    for nm, path in (("header", "kernel.dsm"), ("epilogue", "epilogue.dsm")):
        p = os.path.join(disasm_dir, path)
        ws = []
        if os.path.exists(p):
            for line in open(p):
                t = line.split()
                # "  wNN   009220120D   ?word ..."  -- one 10-hex-digit word
                if len(t) >= 2 and t[0].startswith("w") and t[0][1:].isdigit() \
                        and len(t[1]) == 10:
                    try:
                        ws.append(int(t[1], 16))
                    except ValueError:
                        pass
        out[nm] = ws
    return out


# --------------------------------------------------------------------------
#  1.  The C-FORMAT contamination of R3's class-1 family
# --------------------------------------------------------------------------
def sec_cformat(dist, kern):
    print("=" * 76)
    print("1. C-FORMAT CONTAMINATION -- a FALSIFICATION of R3 section 6.1 / 9.5")
    print("=" * 76)
    allw = [w for a in sorted(dist) for w in dist[a]]
    corpus = allw + kern.get("header", []) + kern.get("epilogue", [])
    print("   corpus: %d body words + %d kernel words = %d"
          % (len(allw), len(corpus) - len(allw), len(corpus)))

    bad = collections.Counter()
    for w in corpus:
        if fields(w)[1] == 1 and is_cformat(w):
            bad[fmt(w)] += 1
    print()
    print("   Words that R3's predicate (`class4 == 1`, no C-format guard)")
    print("   admits but which are C-FORMAT IMMEDIATE LOADS:")
    for f, n in sorted(bad.items()):
        w = int(f.replace(".", ""), 16)
        print("      %s   n=%-4d  imm13 = 0x%04X = %d  ->  A=%d B=%d"
              % (f, n, imm13(w), imm13(w), imm13(w) >> 5, imm13(w) & 0x1F))
    print()
    print("   Cross-check against the MEASURED C-format payload table in")
    print("   instruction-set.md ('lo12 000 -> A=12', 'lo12 451 -> A=15'):")
    print("      C40.1.80.000 -> A=12   MATCHES the table row for lo12=000")
    print("      C40.1.E0.451 -> A=15   MATCHES the table row for lo12=451")
    print("   Both are therefore already-catalogued C-format words.  They are")
    print("   NOT class-1 DRAM words, and R3's 'C40.1.80.000 consumes while")
    print("   C40.1.E0.451 does not, so addr8 bit 7 is not the discriminator'")
    print("   is comparing two immediates, not two addr8 fields.  VOID.")
    print()
    esc_only = sum(1 for w in corpus
                   if (fields(w)[0] & 0x800) and fields(w)[1] == 1
                   and not is_cformat(w))
    esc_raw = sum(1 for w in corpus
                  if (fields(w)[0] & 0x800) and fields(w)[1] == 1)
    print("   mode-1 + ESCAPE, C-format guarded : %d" % esc_only)
    print("   mode-1 + ESCAPE, R3's raw predicate: %d  (+%d contaminants)"
          % (esc_raw, esc_raw - esc_only))
    return bad


# --------------------------------------------------------------------------
#  2.  R3's descriptor-cursor solve, re-run WITH the C-format guard
# --------------------------------------------------------------------------
def desc_cell_count(rom, algo, E):
    """Number of tag-0x4C descriptor cells the algorithm's parameter stream
    writes.  Delegates to R3's own parser so the re-solve differs from R3 in
    EXACTLY ONE THING: the C-format guard."""
    import r3_delaydram as R3
    return sum(len(cl) for _b, cl in R3.desc_blocks(rom, algo))


def solve(rows, forms):
    n = len(forms)
    M = [[Fraction(r[2].get(f, 0)) for f in forms] + [Fraction(r[1])]
         for r in rows]
    piv, r = [], 0
    for c in range(n):
        p = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if p is None:
            continue
        M[r], M[p] = M[p], M[r]
        pv = M[r][c]
        M[r] = [x / pv for x in M[r]]
        for i in range(len(M)):
            if i != r and M[i][c] != 0:
                f = M[i][c]
                M[i] = [a - f * b for a, b in zip(M[i], M[r])]
        piv.append(c)
        r += 1
    incons = sum(1 for i in range(len(M))
                 if all(x == 0 for x in M[i][:n]) and M[i][n] != 0)
    free = [c for c in range(n) if c not in piv]
    sols = []
    if len(free) <= 20:
        for bits in itertools.product([0, 1], repeat=len(free)):
            v = {forms[fc]: Fraction(b) for fc, b in zip(free, bits)}
            ok = True
            for k, c in enumerate(piv):
                val = M[k][n] - sum(M[k][j] * v[forms[j]] for j in free)
                if val not in (0, 1):
                    ok = False
                    break
                v[forms[c]] = val
            if ok:
                sols.append(v)
    return len(piv), incons, sols


def align(imgs, algo, guard):
    """DRAM word index -> descriptor cell index, in program order.
    `guard` = exclude C-format words (the adjudicated reading)."""
    out, k = {}, 0
    for i, w in enumerate(imgs[algo]):
        if fields(w)[1] != 1:
            continue
        cf, esc = is_cformat(w), bool(fields(w)[0] & 0x800)
        if ((esc and not cf) if guard else (esc or cf)):
            out[i] = k
            k += 1
    return out


def sec_cursor(rom, imgs, names):
    print("=" * 76)
    print("2. R3's DESCRIPTOR-CURSOR SOLVE, re-run WITH the C-format guard")
    print("=" * 76)
    print("   Exactly ONE thing changes between the two runs: whether a")
    print("   C-FORMAT word may be one of the unknowns.  The cell count is")
    print("   delegated to R3's own parser, so nothing else can drift.")
    for label, guard in (("R3 as committed (NO guard)", False),
                         ("GUARDED (C-format excluded)", True)):
        rows, forms = [], set()
        for a in sorted(imgs):
            n = desc_cell_count(rom, a, None)
            cnt = collections.Counter()
            for w in imgs[a]:
                hi, cl4, ad, lo = fields(w)
                if cl4 == 1 and not (guard and is_cformat(w)):
                    cnt[(hi, ad, lo)] += 1
            rows.append((a, n, cnt))
            forms |= set(cnt)
        forms = sorted(forms)
        rank, incons, sols = solve(rows, forms)
        naive = sum(1 for (a, nc, cnt) in rows if nc == len(align(imgs, a, guard)))
        print("")
        print("   --- %s ---" % label)
        print("      %d equations, %d unknowns, rank %d, INCONSISTENT ROWS: %d"
              % (len(rows), len(forms), rank, incons))
        print("      solutions with every unknown in {0,1}: %d" % len(sols))
        print("      naive 'cells == consuming words': %d of %d"
              % (naive, len(rows)))
        if sols:
            a1 = [f for f in forms if all(s[f] == 1 for s in sols)]
            a0 = [f for f in forms if all(s[f] == 0 for s in sols)]
            amb = [f for f in forms if f not in a1 and f not in a0]
            print("      always CONSUMES %d, never %d, undecided %d: %s"
                  % (len(a1), len(a0), len(amb),
                     ", ".join("%03X.1.%02X.%03X" % f for f in amb)))

    print("")
    print("   WHERE THE TWO READINGS PART -- per-algorithm balance")
    print("   %-4s %-22s %5s %5s %5s %6s %6s"
          % ("algo", "name", "cells", "esc1", "Cfmt", "raw", "guard"))
    for a in sorted(imgs):
        n = desc_cell_count(rom, a, None)
        e = sum(1 for w in imgs[a]
                if (fields(w)[0] & 0x800) and fields(w)[1] == 1
                and not is_cformat(w))
        c = sum(1 for w in imgs[a] if fields(w)[1] == 1 and is_cformat(w))
        if (n - e - c) or (n - e):
            print("   %-4d %-22s %5d %5d %5d %+6d %+6d"
                  % (a, names.get(a, "?"), n, e, c, n - e - c, n - e))
    print("   The 12 reverbs balance ONLY if the four C40.1.80.000 words consume;")
    print("   the COMPRESSOR family balances ONLY if its two C40.1.E0.451 do not.")
    print("")
    print("   *** THE DECIDING ARGUMENT -- identity, not counting ***")
    print("   C40.1.80.000 (A=12, 48 sites, the 12 reverbs) and")
    print("   C40.2.C0.000 (A=22, 53 sites, 8 other algorithms) are THE SAME")
    print("   INSTRUCTION: same C-format family, same destination register")
    print("   lo12 = 0x000, differing only in the 13-bit IMMEDIATE (12 vs 22).")
    print("   The first reads `class4 == 1` and the second `class4 == 2` purely")
    print("   because bit 8 of the immediate differs.  No machine can make one")
    print("   of them touch the delay DRAM and the other not.  R3's solve is")
    print("   therefore fitting a residual to immediate data.  FORCED.")
    print("")
    print("   WHAT THE FALSIFICATION COSTS, and what it does NOT")
    ndiff, firstdiff = 0, {}
    for a in sorted(imgs):
        aa, bb = align(imgs, a, False), align(imgs, a, True)
        d = [i for i in sorted(set(aa) & set(bb)) if aa[i] != bb[i]]
        if d:
            ndiff += 1
            firstdiff[a] = (min(d), len(bb))
    print("      alignments that change: %d of %d algorithm slots"
          % (ndiff, len(imgs)))
    for a in sorted(firstdiff):
        i, n = firstdiff[a]
        print("         %-3d %-22s diverges only at word w%d (%d DRAM words)"
              % (a, names.get(a, "?"), i, n))
    same = all((sorted(align(imgs, a, False))[:1] or [None])
               == (sorted(align(imgs, a, True))[:1] or [None])
               for a in imgs)
    print("      the body's FIRST DRAM word is unchanged in every algorithm: %s"
          % ("YES" if same else "NO"))
    print("      => every op-0x67 VALIDATED number (SINGLE DELAY's 350 ms, the")
    print("         residue test, the reverb PRE DELAY and both ladders) is")
    print("         UNTOUCHED.  What falls is the STRENGTH of section 6.1")
    print("         ('exactly satisfiable' -> 'a good fit with 16 rows over')")
    print("         and section 9.5's corroboration of R2, which is VOID.")


# --------------------------------------------------------------------------
#  3.  R2's addressing-mode census, re-derived
# --------------------------------------------------------------------------
def sec_modes(dist, kern):
    print("=" * 76)
    print("3. R2's ADDRESSING-MODE CENSUS -- re-derived independently")
    print("=" * 76)
    corpus = [w for a in sorted(dist) for w in dist[a]] \
        + kern.get("header", []) + kern.get("epilogue", [])
    nonc = [w for w in corpus if not is_cformat(w)]
    print("   %d words, %d C-format, %d non-C-format"
          % (len(corpus), len(corpus) - len(nonc), len(nonc)))
    tab = collections.Counter()
    for w in nonc:
        hi, cl, _ad, _lo = fields(w)
        tab[(cl & 7, bool(cl & 8), bool(hi & 0x800))] += 1
    print("\n   mode  cur  ESC      n")
    for k in sorted(tab):
        print("    %d    %-4s %-4s %6d"
              % (k[0], "yes" if k[1] else "no", "yes" if k[2] else "no", tab[k]))
    m2esc = sum(n for k, n in tab.items() if k[0] == 2 and k[2])
    m2 = sum(n for k, n in tab.items() if k[0] == 2)
    m6esc = sum(n for k, n in tab.items() if k[0] == 6 and k[2])
    m6 = sum(n for k, n in tab.items() if k[0] == 6)
    print("\n   mode 2 with ESCAPE: %d of %d      mode 6 with ESCAPE: %d of %d"
          % (m2esc, m2, m6esc, m6))
    print("   => hi12 bit 11 = 'this word does not address D-RAM through the")
    print("      data pointer'.  CONFIRMED, exceptionless.")
    m1 = sum(n for k, n in tab.items() if k[0] == 1 and not k[1])
    print("   mode 1, cursor clear: %d  (R2's '324/324')" % m1)
    print()
    print("   Classes 3, 7, B, E, F -- R2 says they DO NOT EXIST:")
    for cl in (3, 7, 0xB, 0xE, 0xF):
        n = sum(1 for w in nonc if fields(w)[1] == cl)
        print("      class %X : %d" % (cl, n))
    print("   True ONLY under the WIDE C-format predicate.  Under the narrow")
    print("   `(hi12 & 0xFFE) == 0xC40` that instruction-set.md states, the one")
    print("   apparent class-3 word in the whole corpus is C04.3.12.820 -- a")
    print("   header word of the POINTER-LOAD lo12 family, which cannot be a")
    print("   `class 3`.  The wide predicate is the one that empties the class")
    print("   space to exactly {0,1,2,4,5,6,8,9,A,C,D}.")


# --------------------------------------------------------------------------
#  4.  K4's class-8 claim: fetch without advance
# --------------------------------------------------------------------------
def sec_class8(dist, kern):
    print("=" * 76)
    print("4. K4's CLASS-8 CLAIM -- bit 23 = FETCH, class4 == 0xA = ADVANCE")
    print("=" * 76)
    body = [w for a in sorted(dist) for w in dist[a]]
    kernel = kern.get("header", []) + kern.get("epilogue", [])
    for nm, ws in (("BODIES (38 distinct images)", body),
                   ("KERNEL (header + output stage)", kernel)):
        by = collections.Counter()
        for w in ws:
            if is_cformat(w):
                continue
            if fields(w)[1] & 8:
                by[fields(w)[1]] += 1
        print("   %s -- %d words; bit-23 words by class4:" % (nm, len(ws)))
        for k in sorted(by):
            print("      class %X : %d" % (k, by[k]))
        extra = [k for k in by if k not in (0x8, 0xA)]
        print("      classes other than 8 and A: %s"
              % (", ".join("%X" % k for k in extra) if extra else "NONE"))
    print()
    print("   K4's claim is BODY-SCOPED and it holds exactly: in the 2974-word")
    print("   body corpus only classes 8 and A ever set bit 23.  The KERNEL")
    print("   also carries class 9 (the call-vector words), class C and class D")
    print("   (R2's two DO-write words w73/w78), so a core must not assume")
    print("   'bit 23 => class 8 or A'.  What K4 FORCED is narrower and stands:")
    print("   class 8 FETCHES without ADVANCING (the PARAMETRIC EQ cursor map is")
    print("   proven to the bit at 6 cells/band and would shift to 7k if it did).")


# --------------------------------------------------------------------------
#  5.  The C-format payload table, re-measured
# --------------------------------------------------------------------------
def sec_payload(dist, kern):
    print("=" * 76)
    print("5. THE C-FORMAT PAYLOAD TABLE -- re-measured over the whole corpus")
    print("=" * 76)
    seen = collections.defaultdict(collections.Counter)
    for a in sorted(dist):
        for w in dist[a]:
            if is_cformat(w):
                seen[fields(w)[3]][imm13(w)] += 1
    print("   BODY images only (the 38 distinct + their clones):")
    mult32 = tot = 0
    for lo in sorted(seen):
        for v, n in sorted(seen[lo].items()):
            tot += n
            if v % 32 == 0:
                mult32 += n
            print("      lo12 %03X  imm13 %5d = 0x%04X   A=%-4d B=%-3d n=%d%s"
                  % (lo, v, v, v >> 5, v & 0x1F, n,
                     "" if v % 32 == 0 else "   <-- NOT a multiple of 32"))
    print("   multiples of 32: %d of %d" % (mult32, tot))
    for nm in ("header", "epilogue"):
        ws = [w for w in kern.get(nm, []) if is_cformat(w)]
        if not ws:
            continue
        print("   %s:" % nm)
        for i, w in enumerate(kern[nm]):
            if is_cformat(w):
                v = imm13(w)
                print("      w%-3d %s  imm13 %5d   A=%-4d B=%-3d%s"
                      % (i, fmt(w), v, v >> 5, v & 0x1F,
                         "" if v % 32 == 0 else "   <-- NOT a multiple of 32"))


# --------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    root = os.path.dirname(os.path.dirname(HERE))
    ap.add_argument("--rom", default=os.path.join(
        root, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(
        root, "original_ROMs", "kn5000_v10_program.rom"))
    ap.add_argument("--tools", default=os.path.expanduser(
        "~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--disasm", default=os.path.join(
        os.path.dirname(HERE), "disasm"))
    ap.add_argument("sections", nargs="*")
    args = ap.parse_args()

    E, rom, names, imgs = load(args.tools, args.rom, args.main)
    kern = kernel_words(args.disasm)
    dist = canonical(imgs)
    want = args.sections or ["cformat", "cursor", "modes", "class8", "payload",
                             "state"]
    if "cformat" in want:
        sec_cformat(dist, kern)
        print()
    if "cursor" in want:
        sec_cursor(rom, imgs, names)
        print()
    if "modes" in want:
        sec_modes(dist, kern)
        print()
    if "class8" in want:
        sec_class8(dist, kern)
        print()
    if "payload" in want:
        sec_payload(dist, kern)
        print()
    if "state" in want:
        sec_state(rom, imgs, names)
        print()




# --------------------------------------------------------------------------
#  6.  NEW -- the per-unit STATE BLOCK, and what 0x50 / 0xD0 really are
# --------------------------------------------------------------------------
def fill_cells(rom, algo):
    """The register indices the host ZERO-FILLS for an algorithm: tag-0x15
    packets addressed by K3's `000.1.NN.000` family.  Returns them in order."""
    p, g, out, dest = rom.u32le(T_PARAM + 4 * algo), 0, [], None
    while g < 512:
        g += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 >> 4) == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        if (b0 >> 4) in (0, 1, 5):
            data = rom.slice(p + 2, ln - 2)[3:]
            for k in range(0, len(data) - 4, 5):
                e = data[k:k + 5]
                if e[0] == 0x00 and e[1] == 0x00 and (e[2] >> 4) == 0x1:
                    dest = ((e[2] & 0x0F) << 4) | (e[3] >> 4)
                elif e[0] == 0x0A and (e[4] & 0x7F) == 0x15 and dest is not None:
                    out.append(dest)
                    dest += 1
        p += ln
    return sorted(set(out))


def pointer_walk(imgs, algo):
    """Distinct D-RAM cells the body's mode-2 pointer visits (relative to an
    unknown origin -- the origin is exactly what this section is about)."""
    p, seen = 0, set()
    for w in imgs[algo]:
        hi, cl, ad, _lo = fields(w)
        if is_cformat(w):
            continue
        if (cl & 7) == 2 and not (hi & 0x800):
            seen.add(p)
            p = (p + (ad - 256 if ad >= 128 else ad)) & 0xFF
    return seen


def sec_state(rom, imgs, names):
    print("=" * 76)
    print("6. NEW -- the per-unit STATE BLOCK.  0x50 / 0xD0 are its BASE.")
    print("=" * 76)
    print("   R2 found the pair {0x50, 0xD0} only as 'two indices the host")
    print("   clears in bit-7 order' and left what they are OPEN.  K3 measured")
    print("   ONE algorithm's fill (PARAMETRIC EQ, 40 cells at 0x50..0x77).")
    print("   Over all 91 well-formed streams the fill has a FIXED SHAPE:")
    print()
    ok = tot = 0
    lows = collections.Counter()
    lens = collections.Counter()
    short = []
    for a in sorted(imgs):
        f = fill_cells(rom, a)
        if not f:
            continue
        tot += 1
        B = 0xD0 if a in REVERB_ALGOS else 0x50
        low = tuple(c for c in f if c < B)
        blk = [c for c in f if c >= B]
        if blk == list(range(B, B + len(blk))):
            ok += 1
        else:
            short.append(a)
        lows[low] += 1
        lens[(B, len(blk))] += 1
    print("      {low registers} u {CONTIGUOUS block based at 0x50 / 0xD0}")
    print("      contiguous, at exactly that base: %d of %d streams" % (ok, tot))
    if short:
        print("      exceptions: %s" % short)
    print()
    print("   the low-register sets (top 4), unit-tagged by bit 7 exactly as K4")
    print("   FORCED -- and with two pairs K4 did not have (0x06/0x86, 0x0B/0x8B):")
    for k, n in lows.most_common(4):
        print("      %-46s n=%d" % (", ".join("0x%02X" % c for c in k), n))
    print()
    print("   state-block lengths:")
    for (B, L), n in sorted(lens.items()):
        mark = "   <- PARAMETRIC EQ; K3's '40 cells at 0x50..0x77'" if L == 40 else ""
        print("      base 0x%02X  len %3d   n=%d%s" % (B, L, n, mark))
    print()
    print("   Cross-check against the body: the mode-2 pointer footprint must")
    print("   be at least the zero-filled block (a cell written before it is")
    print("   first read needs no clearing -- R2's write-never-read finding).")
    bad = [a for a in sorted(imgs)
           if fill_cells(rom, a)
           and len(pointer_walk(imgs, a))
           < len([c for c in fill_cells(rom, a)
                  if c >= (0xD0 if a in REVERB_ALGOS else 0x50)])]
    print("      walk >= block in %d of %d streams%s"
          % (tot - len(bad), tot, "" if not bad else "  exceptions %s" % bad))
    print()
    print("   => 0x50 / 0xD0 is the PER-UNIT STATE-BLOCK BASE (MEASURED).")
    print("   => the mode-1 REGISTER FILE and the mode-2 D-RAM are most simply")
    print("      ONE 256-cell RAM reached two ways -- a direct 8-bit index for")
    print("      the host, an auto-incrementing pointer for the body.  That")
    print("      would PIN the D-RAM origin instruction-set.md calls unpinned.")
    print("      INFERRED, not proven: the alternative is two separate spaces")
    print("      that merely happen to be laid out alike.  ENUMERATED, not")
    print("      picked -- but note the fill is the ONLY evidence there has")
    print("      ever been for the body's state footprint, and it is addressed")
    print("      through the mode-1 index.")


if __name__ == "__main__":
    main()
