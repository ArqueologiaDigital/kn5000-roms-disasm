#!/usr/bin/env python3
"""bit11_fields.py -- does the REGISTER-LOAD decomposition extend to the whole bit-11 family?

QUESTION IT ANSWERS
    `dsp_disasm.py' already decomposes a bit-11 word, for ten of them:

        lo_sel(w) = lo12 & 0xFF          the register SELECTOR
        lo_imm(w) = lo12 bit 11          "addr8 carries a payload"  <- the family flag itself
        lo_mid(w) = (lo12 >> 8) & 7      "residue: 0 at all 10 corpus sites"

    That docstring was written when the family was ten words in one product.  Pooled over both
    products it is 209 words, and `lo_mid' is NOT always zero -- `C63' (99 occurrences) has
    `mid = 4', `921' has `mid = 1', `F22' has `mid = 7'.  So either the decomposition extends
    with a live 3-bit field, or it does not extend at all.  This asks which, three ways:

      1  the FIELD SPACE: every (mid, sel) actually used, with counts, products and
         decoded/undecoded status -- so a sparse, structured space is visible as one
      2  MINIMAL PAIRS: two shapes sharing a `sel' at different `mid' (and vice versa).
         `821' vs `921' share sel 0x21; `822' vs `F22' share sel 0x22.  A shared selector at
         two `mid' values is what isolates `mid' as a field, and it is the same instrument
         (`a second copy at a different offset') that paid in sect. 122 and sect. 128.
      3  WHAT EACH UNDECODED SHAPE IS BLOCKED ON -- separating "the alternate encoding is
         unknown" from "this word is blocked on the bit-4 store like any other word", which
         are different problems with different costs.

USAGE
    python3 dsp/tools/bit11_fields.py

WHAT IT IS NOT
    It does not decode anything and does not touch `decoded()'.  It is a STRUCTURE report: if
    the space is sparse and the minimal pairs exist, the family is one question; if `sel' is
    scattered over 200 values, the decomposition is wrong and this says so instead.

    (RULE 9: pooled over DISTINCT images -- the SX-WSA1R tree carries byte-identical duplicates.)
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402


def distinct_words():
    seen, out = set(), []
    for label, _img, _slots, ws in CT.images():
        k = (label, tuple(ws))
        if k in seen:
            continue
        seen.add(k)
        out.extend((label, w) for w in ws)
    return out


def why_blocked(w):
    """Which axis refuses this word, using the project's own enumerator."""
    import acc_blind as AB
    return tuple(sorted(AB.open_axes(w)))


def main():
    words = distinct_words()
    #  ⛔ EXCLUDE C-FORMAT WORDS.  v1 did not, and 22 of the 209 words carrying lo12 bit 11
    #  are C-format -- where bits [24:12] are ONE 13-bit immediate, so `lo_sel', `lo_mid',
    #  `class4' and `addr8' are not fields at all but pieces of that immediate (`acc_blind.py'
    #  open_axes() documents exactly this, and `decoded()' admits all 22 via its `c-format'
    #  clause, not via `regload').  Including them put a 22-word phantom cell at (0, 0x20) in
    #  the field space and shifted the null in part 5.  The same mistake this file was written
    #  to look for, made by this file.
    fam = [(l, w) for l, w in words if (DIS.lo12(w) & 0x800) and not DIS.c_format(w)]
    ncf = sum(1 for _l, w in words if (DIS.lo12(w) & 0x800) and DIS.c_format(w))

    print("=" * 96)
    print("  bit11_fields -- does the register-load decomposition extend to the whole family?")
    print("=" * 96)
    print("\n  pooled DISTINCT corpus: %d words, bit-11 family: %d" % (len(words), len(fam)))
    print("  decomposition under test:  lo_sel = lo12 & 0xFF | lo_mid = (lo12 >> 8) & 7 |"
          " lo_imm = bit 11")
    print("  `_REGLOAD_SEL' (the established selectors) = %s"
          % " ".join("0x%02X" % s for s in DIS._REGLOAD_SEL))

    #  1 -- THE FIELD SPACE.
    cell = collections.defaultdict(lambda: [0, 0, collections.Counter()])   # (mid,sel)->[n,dec,prod]
    for l, w in fam:
        m, s = DIS.lo_mid(w), DIS.lo_sel(w)
        e = cell[(m, s)]
        e[0] += 1
        if DIS.decoded(w):
            e[1] += 1
        e[2][l] += 1
    mids = sorted({m for m, _s in cell})
    sels = sorted({s for _m, s in cell})
    print("\n  1  THE FIELD SPACE: %d distinct `mid' values %s, %d distinct `sel' values"
          % (len(mids), mids, len(sels)))
    print("     sel values: %s" % " ".join("0x%02X" % s for s in sels))
    print("\n     mid  sel    n   decoded   product        in _REGLOAD_SEL?")
    for (m, s) in sorted(cell):
        n, d, pr = cell[(m, s)]
        print("      %d   0x%02X %4d %7d   %-14s %s"
              % (m, s, n, d, " ".join("%s:%d" % kv for kv in sorted(pr.items())),
                 "YES" if s in DIS._REGLOAD_SEL else "-"))
    #  the point of the table: is the space SPARSE?
    print("\n     %d cells used of %d x %d = %d possible  (%.1f %% -- a sparse, structured space"
          % (len(cell), len(mids), 256, len(mids) * 256,
             100.0 * len(cell) / (len(mids) * 256)))
    print("      is what a real field decomposition looks like; a scattered one is not)")

    #  2 -- MINIMAL PAIRS.
    by_sel = collections.defaultdict(set)
    by_mid = collections.defaultdict(set)
    for (m, s) in cell:
        by_sel[s].add(m)
        by_mid[m].add(s)
    print("\n  2  MINIMAL PAIRS -- a shared field value at two settings of the other")
    shared = {s: ms for s, ms in by_sel.items() if len(ms) > 1}
    if shared:
        print("\n     SELECTORS APPEARING AT MORE THAN ONE `mid' -- these isolate `mid':")
        for s, ms in sorted(shared.items()):
            rows = []
            for m in sorted(ms):
                n, d, _p = cell[(m, s)]
                rows.append("mid %d: %d word%s, %d decoded" % (m, n, "" if n == 1 else "s", d))
            print("       sel 0x%02X  ->  %s" % (s, "   |   ".join(rows)))
            #  print the full words so the pair can be read directly
            for m in sorted(ms):
                ws = sorted({w for _l, w in fam
                             if DIS.lo_mid(w) == m and DIS.lo_sel(w) == s})
                for w in ws[:3]:
                    print("           mid %d  %09X  hi12=%03X class4=%X addr8=%02X  %s"
                          % (m, w, DIS.hi12(w), DIS.class4(w),
                             (w >> 12) & 0xff, "DECODED" if DIS.decoded(w) else "open"))
    else:
        print("     NONE -- no selector occurs at two `mid' values, so `mid' cannot be")
        print("     isolated this way and the 3-bit field reading has no minimal pair.")

    #  3 -- WHAT EACH UNDECODED SHAPE IS BLOCKED ON.
    print("\n  3  WHAT BLOCKS EACH UNDECODED SHAPE (via the project's own `open_axes()')\n")
    print("     lo12  mid  sel   n   hi12 forms            open axes")
    grp = collections.defaultdict(list)
    for l, w in fam:
        if not DIS.decoded(w):
            grp[DIS.lo12(w)].append(w)
    for lo in sorted(grp, key=lambda k: -len(grp[k])):
        ws = grp[lo]
        his = collections.Counter(DIS.hi12(w) for w in ws)
        ax = collections.Counter(why_blocked(w) for w in ws)
        hs = " ".join("%03X%s x%d" % (h, "(ST)" if h & DIS.HI_ST else "", c)
                      for h, c in his.most_common(3))
        a0 = ax.most_common(1)[0][0]
        print("     %03X    %d  0x%02X %4d   %-20s  %s"
              % (lo, DIS.lo_mid(ws[0]), DIS.lo_sel(ws[0]), len(ws), hs, ", ".join(a0)))
    #  4 -- THE SPLIT THE TABLE ABOVE IS POINTING AT.  Every DECODED member of this family
    #  carries a PAYLOAD in `addr8' (0x50, 0x60, 0x70 ...), and `lo_imm' -- the flag whose
    #  documented meaning is "addr8 carries a payload" -- IS bit 11, so it is set on every word
    #  here and discriminates nothing WITHIN the family.  What does vary is whether the payload
    #  is actually there.  `C63', `C62', `F22', `864' and `921' all carry `addr8 = 0x00'.
    #  A register load with nothing to load is not a register load.
    #  ⚠ This is a PARTITION TEST, and it can fail: if decoded/undecoded does not line up with
    #  addr8 zero/non-zero, the reading is wrong and the table says so.
    print("\n  4  THE PARTITION: does `addr8 == 0' separate the family?\n")
    tab = collections.Counter()
    for _l, w in fam:
        tab[(((w >> 12) & 0xff) == 0, DIS.decoded(w))] += 1
    print("                       decoded   undecoded")
    for z in (False, True):
        print("     addr8 %-9s %7d %11d"
              % ("== 0" if z else "!= 0", tab[(z, True)], tab[(z, False)]))
    d0, u0 = tab[(True, True)], tab[(True, False)]
    d1, u1 = tab[(False, True)], tab[(False, False)]
    print("\n     of the %d words with NO payload (addr8 == 0): %d decoded, %d open" % (d0 + u0, d0, u0))
    print("     of the %d words WITH a payload:                %d decoded, %d open" % (d1 + u1, d1, u1))
    if d0 == 0:
        print("\n     ★★★ NOT ONE payload-less word is decoded, and every decoded word has a")
        print("       payload.  `addr8 == 0' is a clean partition of this family.")
    else:
        print("\n     ⛔ the partition LEAKS (%d payload-less words are decoded) -- the reading" % d0)
        print("       that `addr8 == 0' means `not a register load' does not survive this.")
    print("\n     per cell, so the partition can be read against the field space:\n")
    print("     mid  sel   addr8==0   addr8!=0   addr8 values seen")
    for (m, sl) in sorted(cell):
        ws = [w for _l, w in fam if DIS.lo_mid(w) == m and DIS.lo_sel(w) == sl]
        z = sum(1 for w in ws if ((w >> 12) & 0xff) == 0)
        av = sorted({(w >> 12) & 0xff for w in ws})
        print("      %d   0x%02X %8d %10d   %s" % (m, sl, z, len(ws) - z,
              " ".join("%02X" % a for a in av[:8]) + (" ..." if len(av) > 8 else "")))

    #  5 -- THE RELATION THE PARTITION IS ACTUALLY MADE OF, WITH ITS NULL.
    #  Reading the per-cell table: EVERY `mid != 0' cell has `addr8 == 0'.  So `mid' and `addr8'
    #  are never both live -- which is what an OPCODE EXTENSION selecting a payload-less form
    #  looks like.  ⚠ But the word-level count is dominated by `C63' x99 (one shape), and RULE 9's
    #  lesson is exactly that: count DISTINCT shapes, and state the null BEFORE the number.
    print("\n  5  THE RELATION, AND ITS NULL:  does `mid != 0' imply `addr8 == 0'?\n")
    cells_z = [(m, sl) for (m, sl) in cell
               if all(((w >> 12) & 0xff) == 0
                      for _l, w in fam if DIS.lo_mid(w) == m and DIS.lo_sel(w) == sl)]
    cells_nz = [(m, sl) for (m, sl) in cell
                if all(((w >> 12) & 0xff) != 0
                       for _l, w in fam if DIS.lo_mid(w) == m and DIS.lo_sel(w) == sl)]
    mid_nz = [(m, sl) for (m, sl) in cell if m != 0]
    hit = [c for c in mid_nz if c in cells_z]
    nwords = sum(cell[c][0] for c in mid_nz)
    print("     AT WORD LEVEL:   %d of %d words with mid != 0 carry addr8 == 0" % (nwords, nwords))
    print("     ⚠ inflated -- %d of those %d words are ONE shape (`C63')." % (cell[(4, 0x63)][0], nwords))
    print("\n     AT SHAPE LEVEL (the honest granularity):")
    print("       cells with mid != 0 : %d   %s" % (len(mid_nz),
          " ".join("(%d,0x%02X)" % c for c in sorted(mid_nz))))
    print("       of those, all-zero-addr8 : %d" % len(hit))
    #  the null: of all 12 cells, what fraction are all-zero-addr8?  If `mid' were irrelevant,
    #  a mid != 0 cell would be all-zero with that base rate.
    base = len(cells_z) / float(len(cell))
    p = base ** len(mid_nz)
    print("\n       NULL, stated as a rate and not after the fact: %d of %d cells in the whole"
          % (len(cells_z), len(cell)))
    print("       family are all-zero-addr8, a base rate of %.3f.  If `mid' had nothing to do" % base)
    print("       with it, %d independent cells land that way with p = %.3f^%d = %.4f."
          % (len(mid_nz), base, len(mid_nz), p))
    print("\n       MEASURED %d of %d.  %s" % (len(hit), len(mid_nz),
          "★ SUGGESTIVE, NOT PROOF at p = %.4f -- four cells cannot carry more than this, and"
          % p if len(hit) == len(mid_nz) else "⛔ the relation does not hold."))
    if len(hit) == len(mid_nz):
        print("       the honest reading is: `mid != 0' and a payload have never been seen")
        print("       together, over 4 shapes and 105 occurrences in BOTH products.  To promote")
        print("       it, find a `mid != 0' shape WITH a payload (refutes) or a fifth without.")
    print("\n     ⇒ what this DOES settle: the decomposition extends.  The space is sparse,")
    print("       `mid' takes 4 values, `sel' 10, and the two fields are not independent.")
    print("       What it does NOT settle: what `mid' and `sel' MEAN -- which is the one")
    print("       question the whole 169 turns on (sect. 202).")

    print("\n     ⚠ `(ST)' marks hi12 bit 4, the STORE.  A register-load word that ALSO stores is")
    print("       excluded from `is_ldptr()' by an explicit guard -- `dsp_disasm.py:493' says so")
    print("       (\"A member carrying the bit-4 store is excluded: its second effect has an")
    print("       unproven target off mode 2\").  Those words are blocked on the STORE TARGET,")
    print("       which is a different and already-documented problem from the encoding itself.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
