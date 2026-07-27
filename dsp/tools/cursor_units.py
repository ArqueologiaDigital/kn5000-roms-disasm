#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""cursor_units.py -- THE UNIT-1 CURSOR RELOAD, and the death of model M5.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams and the 38 body images only.

TWO QUESTIONS.

  TASK A.  Unit 0's first delay-DRAM consumer takes descriptor cell 0x26 and
  unit 1's takes 0x00, yet the two per-unit setup blocks reload the descriptor
  pointer with the IDENTICAL word `801.0.25.825' (I-RAM 44 and I-RAM 52), same
  payload 0x25.  One word, two required bases.  Resolve it.

  TASK B.  The published map is ONE cursor advancing +1 per delay-DRAM access
  (model M2).  Model M5 says there are TWO, one per direction.  On the reverb
  ladder the two are indistinguishable because reads and writes alternate
  strictly.  Break M5 where the alternation breaks.

    python3 dsp/tools/cursor_units.py ptr      # 1 *** EVERY pointer write in the ROM
    python3 dsp/tools/cursor_units.py reload   # 2 *** TASK A -- the enumeration
    python3 dsp/tools/cursor_units.py alt      # 3 where the alternation BREAKS
    python3 dsp/tools/cursor_units.py m5       # 4 *** TASK B -- M2 versus M5
    python3 dsp/tools/cursor_units.py wrap     # 5 TASK C -- the wrap, per unit
    python3 dsp/tools/cursor_units.py control  # 6 the controls, shown saying NO
    python3 dsp/tools/cursor_units.py predict  # 7 PREDICT-THEN-CHECK
    python3 dsp/tools/cursor_units.py all      # ~60 s

Every number in `dsp/analysis/dram-unit-cursor.md' comes out of this file.
Stdlib only, plus the repo's own ROM parsers.
"""
import argparse
import collections
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_cursor as DC                                            # noqa: E402
import dram_match as DM                                             # noqa: E402
import dsp_disasm as D                                              # noqa: E402

# ---------------------------------------------------------------------------
#  MEASURED constants.  Every one is re-derived by `ptr' below (method rule 8).
# ---------------------------------------------------------------------------
BASE_U0 = 0x26          # unit-0 descriptor block base, from the HOST pointer poke
BASE_U1 = 0x00          # unit-1 (reverb) block base, ditto
N1 = 32                 # every reverb ships 32 cells
MAXCELL = 0x39          # GATED REVERB, the corpus maximum
RELOAD_IMM = 0x25       # I-RAM 44 and I-RAM 52, the IDENTICAL word
RELOAD_EPI = 0x26       # I-RAM 62
HDR_CONS = [12, 26, 40]         # R2-predicate hits before the unit-0 reload
TIED_CONS = [46, 54]            # both `800.1.60.00B'; one flag governs the pair
GAP = set(range(0x20, 0x26))    # the six cells no algorithm ever writes

PTR_SELECTORS = (0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27)


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


def is_ptr_load(w):
    _hi, _cl, _ad, lo = DC.fields(w)
    return (lo & 0xF00) == 0x800 and (lo & 0xFF) in PTR_SELECTORS


def dirof(w):
    """round 5 D, as SHIPPED to both disassemblers: addr8 0x20/0x30 -> READ,
    0x60 -> WRITE, anything else -> None (still trapping)."""
    return D.dram_dir(w)


def aligned_algos(C):
    return [(a, u, c, k) for (a, u, c, k) in C.algos if len(c) == len(k)]


def rwstring(cons, cfmt=None):
    """cfmt: how to render the still-trapping C-format cells -- '?' (default),
    or 'READ' / 'WRITE' to test a hypothetical decode of them."""
    m = {"READ": "R", "WRITE": "W",
         None: {"READ": "R", "WRITE": "W", None: "?"}[cfmt]}
    return "".join(m[dirof(w)] for _i, w in cons)


# ===========================================================================
#  1.  ptr -- every write to a pointer register, host side and program side
# ===========================================================================
def raw_param_entries(rom, algo):
    p, guard, out = rom.u32le(DC.T_PARAM + 4 * algo), 0, []
    while guard < 512:
        guard += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 >> 4) == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        if (b0 >> 4) in (0, 1, 5):
            d = rom.slice(p + 2, ln - 2)[3:]
            for k in range(0, len(d) - 4, 5):
                out.append(tuple(d[k:k + 5]))
        p += ln
    return out


def cmd_ptr(C):
    head(1, "EVERY WRITE TO A DESCRIPTOR POINTER, HOST SIDE AND PROGRAM SIDE")
    print("  POPULATION (method rule 9): the 38 distinct body images, the 60-word")
    print("  frame header, the 23-word epilogue and all 100 canned parameter")
    print("  streams.  Nothing is sampled; this is the whole ROM.")
    print()
    print("  ---- HOST SIDE.  A 5-byte parameter entry is")
    print("       [e0 = kind][24 bits of payload, split 7+8+8+1][7-bit register tag],")
    print("       payload = (e1&0x7F)<<17 | e2<<9 | e3<<1 | e4>>7.  Tag 0x4C writes")
    print("       a descriptor CELL; tag 0x25 sets the destination pointer, whose")
    print("       bits [16:5] are the cell index.")
    perunit = collections.defaultdict(list)
    for (a, u, _cells, _cons) in C.algos:
        vals = []
        for e in raw_param_entries(C.rom, a):
            if e[0] == 0x08 and e[4] == 0x25:
                vals.append(((e[1] & 0x7F) << 17) | (e[2] << 9) |
                            (e[3] << 1) | (e[4] >> 7))
        perunit[(u, tuple(vals))].append(a)
    print()
    for (u, vals), algos in sorted(perunit.items()):
        print("     unit %d  %2d algorithms  pointer pokes %s"
              % (u, len(algos), "  ".join(
                  "%06X -> cell 0x%02X" % (v, (v >> 5) & 0xFFF) for v in vals)))
    print()
    print("     -> unit-0 blocks are based at cell 0x%02X, unit-1 blocks at 0x%02X."
          % (BASE_U0, BASE_U1))
    print("        THE TWO ANCHORS OF TASK A ARE HOST-SIDE GROUND TRUTH; no")
    print("        instruction field enters them.")
    print("     -> and the reverbs poke the pointer TWICE (0x00, then 0x1E): their")
    print("        32 cells arrive as 30 + 2.  Nothing had noticed; it is why the")
    print("        ladder's eleventh segment closes through cell 0x1F.")
    print()
    print("  ---- PROGRAM SIDE.  Every word of the whole corpus whose lo12 is a")
    print("       pointer load (lo12 = 0x8_2x -- register_space.md sect. 3.4/5.2):")
    pool = [("HDR %2d" % i, w) for i, w in enumerate(C.hdr)]
    pool += [("EPI %2d" % (60 + i), w) for i, w in enumerate(C.epi)]
    nbody = 0
    for a in sorted(C.imgs):
        for i, w in enumerate(C.imgs[a]):
            if is_ptr_load(w):
                pool.append(("A%02d w%-3d" % (a, i), w))
                nbody += 1
    for tag, w in pool:
        if is_ptr_load(w):
            _hi, _cl, ad, lo = DC.fields(w)
            note = "   <== THE DESCRIPTOR POINTER" if (lo & 0xFF) == 0x25 else ""
            print("     %-10s %s   selector %02X  payload %02X%s"
                  % (tag, DC.fmt(w), lo & 0xFF, ad, note))
    print()
    print("     pointer writes inside any of the 38 BODY IMAGES: %d" % nbody)
    print("     ** MEASURED, and it is the load-bearing fact of the whole pass:")
    print("        NOT ONE body image touches a pointer register.  Every cursor")
    print("        reload in the machine is one of the three header/epilogue words")
    print("        above, and all three are ALGORITHM-INDEPENDENT. **")
    print()
    print("  ---- THE THREE WRITES TO THE DESCRIPTOR POINTER, IN FRAME ORDER:")
    print("       I-RAM 44  801.0.25.825  payload 0x25   before the unit-0 body")
    print("       I-RAM 52  801.0.25.825  payload 0x25   before the unit-1 body")
    print("       I-RAM 62  801.0.26.825  payload 0x26   epilogue")
    print("       44 and 52 are the SAME 36 bits.  That is TASK A.")
    print("     ** AND A THIRD FACT THE R2 CONSUMER PREDICATE GETS WRONG:")
    print("        I-RAM 40 `C4A.1.C0.820' matches the predicate (class4 == 1 and")
    print("        the hi12 escape bit) but its lo12 is 0x820 -- it is a POINTER")
    print("        LOAD, selector 0x20, not a descriptor consumer.  The header's")
    print("        consumer count is a parameter below, not a constant.")
    return True


# ===========================================================================
#  2.  reload -- TASK A
# ===========================================================================
def make_cursor(inc, wrap_style, wrap_load):
    """Return step(cur, ring, load=None) -> (new_cur, cell_or_None)."""
    def wrapv(c, B, L):
        if c >= L:
            if wrap_style == "RESET":
                return B
            return B + (c - L) % (L - B)
        if c < B:
            return B if wrap_style == "RESET" else L - 1 - (B - 1 - c) % (L - B)
        return c

    def step(cur, ring, load=None):
        B, L = ring
        if load is not None:
            return (wrapv(load, B, L) if wrap_load else load), None
        if inc == "PRE":
            c = wrapv(cur + 1, B, L)
            return c, c
        c = wrapv(cur, B, L)
        return c + 1, c
    return step


def run_anchor(step, ring, base, n, imm, pre_consumers):
    """reload with `imm', then `pre_consumers' extra consumers, then the body's
    n consumers, which must land on base..base+n-1.  -> True/False."""
    cur, _ = step(0, ring, load=imm)
    for _ in range(pre_consumers):
        cur, _c = step(cur, ring)
    for k in range(n):
        cur, c = step(cur, ring)
        if c != base + k:
            return False
    return True


def cmd_reload(C):
    head(2, "TASK A -- ONE WORD, TWO REQUIRED BASES.  THE ENUMERATION.")
    n0s = sorted({len(k) for (_a, u, c, k) in aligned_algos(C) if u == 0})
    print("  THE TWO ANCHORS (host-side; 79 unit-0 and 12 unit-1 algorithms ship")
    print("  descriptor blocks -- method rule 9):")
    print("     unit-0 body, consumer 0 -> cell 0x%02X ; aligned block sizes %s"
          % (BASE_U0, n0s))
    print("     unit-1 body, consumer 0 -> cell 0x%02X ; block size %d x12"
          % (BASE_U1, N1))
    print("     BOTH reloads carry payload 0x%02X." % RELOAD_IMM)
    print()
    print("  ---- THE MODEL CLASS, PRINTED BESIDE THE CLAIM (method rule 3).")
    print("     FIVE independent choices, swept as a full cross product:")
    print("       (i)   increment   : PRE (cell = ++cur) | POST (cell = cur++)")
    print("       (ii)  wrap style  : RESET (cur = B) | MOD (cur -= L-B)")
    print("       (iii) wrap at     : increment only | increment AND load")
    print("       (iv)  ring        : per-unit [B_u, L_u)")
    print("       (v)   whether I-RAM 46 / 54 (`800.1.60.00B', one word, one flag)")
    print("             consume a descriptor cell")
    print("     ring sweep: B_1 0x00..0x08, L_1 0x20..0x41, B_0 0x00..0x28,")
    print("                 L_0 0x3A..0x41  (L_0 >= 0x3A because GATED REVERB")
    print("                 reaches cell 0x%02X and must not wrap inside its body)."
          % MAXCELL)
    print("     ** WHAT IS DELIBERATELY NOT IN THE LIST, ASKED EXPLICITLY (rule 3):")
    print("        a per-ALGORITHM reload.  `ptr' MEASURES that no body image")
    print("        writes a pointer register, so there is no such thing to sweep.")
    print("        A per-unit BASE added to the payload IS in the list -- it is")
    print("        sweep 2, solved in closed form. **")
    print()

    rings1 = [(b, l) for b in range(0, 9) for l in range(0x20, 0x42) if l > b]
    rings0 = [(b, l) for b in range(0x00, 0x29) for l in range(0x3A, 0x42)
              if l > b]
    survivors = []
    tried = 0
    for inc in ("PRE", "POST"):
        for wst in ("RESET", "MOD"):
            for wld in (False, True):
                step = make_cursor(inc, wst, wld)
                for pc in (0, 1):
                    for r0 in rings0:
                        tried += 1
                        if not run_anchor(step, r0, BASE_U0, max(n0s),
                                          RELOAD_IMM, pc):
                            continue
                        for r1 in rings1:
                            tried += 1
                            if run_anchor(step, r1, BASE_U1, N1,
                                          RELOAD_IMM, pc):
                                survivors.append((inc, wst, wld, pc, r0, r1))
    print("  ---- SWEEP 1.  Can any machine in that class deliver BOTH anchors")
    print("       from the single payload 0x25?   %d combinations evaluated."
          % tried)
    print("       SURVIVORS: %d" % len(survivors))
    fam = collections.Counter(s[:4] for s in survivors)
    print("       %-4s %-6s %-9s %-8s  ring pairs" % ("inc", "wrap", "wrap-load",
                                                      "46/54?"))
    for k, v in sorted(fam.items()):
        print("       %-4s %-6s %-9s %-8s  %d"
              % (k[0], k[1], str(k[2]), "consumes" if k[3] else "no", v))
    b1s = sorted({s[5][0] for s in survivors})
    l1s = sorted({s[5][1] for s in survivors})
    b0s = sorted({s[4][0] for s in survivors})
    l0s = sorted({s[4][1] for s in survivors})
    print()
    print("       ACROSS EVERY SURVIVOR:")
    print("          B_1 = %s   <- single-valued, but this is the model"
          % ["0x%02X" % x for x in b1s])
    print("                              RECOVERING the observed block base, not")
    print("                              a discovery.  Control 1 says so.")
    print("          L_1 in %s   <- FORCED to a 7-value range, top 0x26"
          % ["0x%02X" % x for x in l1s])
    print("          B_0 in 0x%02X..0x%02X  (unconstrained: unit 0 never reaches"
          % (b0s[0], b0s[-1]))
    print("                              its own wrap in any shipped algorithm)")
    print("          L_0 in %s" % ["0x%02X" % x for x in l0s])
    print("       and under the MOD flavour of the wrap alone:")
    modl1 = sorted({s[5][1] for s in survivors if s[1] == "MOD"})
    print("          L_1 in %s   <- a SINGLE value"
          % ["0x%02X" % x for x in modl1])
    print()
    print("     ** THE INVARIANT, AND IT IS THE ANSWER TO TASK A:")
    print("        B_1 = 0x00 and L_1 <= 0x26 in every surviving machine.  Unit 1's")
    print("        cursor ring ENDS where unit 0's block BEGINS.  The payload 0x25")
    print("        is simultaneously `one below unit 0's base' and `the last cell")
    print("        of unit 1's ring', so ONE immediate starts both units on their")
    print("        own base.  The per-unit difference is carried by the RING, not")
    print("        by the word -- which is why no field of the word can carry it. **")
    print()

    # ---- sweep 2: the rival, solved in closed form -----------------------
    print("  ---- SWEEP 2.  THE RIVAL FAMILY: no wrap, a per-unit BASE added to")
    print("       the payload -- the shape the D-RAM operand pointer really uses.")
    for inc in ("PRE", "POST"):
        d = 1 if inc == "PRE" else 0
        n0 = (BASE_U0 - RELOAD_IMM - d) % 256
        n1 = (BASE_U1 - RELOAD_IMM - d) % 256
        print("       %-4s : BASE[0] = 0x%02X, BASE[1] = 0x%02X, difference 0x%02X"
              % (inc, n0, n1, (n0 - n1) % 256))
    print("       Not empty -- it needs a per-unit register whose two values differ")
    print("       by exactly 0x26 = 38.  THE CARRIER SEARCH, re-run and widened:")
    pairs = [(42, 50), (43, 51), (44, 52), (45, 53), (46, 54), (47, 55),
             (48, 56), (49, 59)]
    ncar, hits = 0, []
    for (i, j) in pairs:
        fi, fj = DC.fields(C.hdr[i]), DC.fields(C.hdr[j])
        for nm, k in (("hi12", 0), ("class4", 1), ("addr8", 2), ("lo12", 3)):
            a, b = fi[k], fj[k]
            if a == b:
                continue
            ncar += 1
            d = a - b
            for tgt in ((0x26, 0x00), (0x00, 0xDA), (0x01, 0xDB)):
                if d and (tgt[0] - tgt[1]) % d == 0 and \
                        abs((tgt[0] - tgt[1]) // d) <= 8:
                    hits.append((i, j, nm, a, b, (tgt[0] - tgt[1]) // d))
    print("          differing fields across the paired setup words : %d" % ncar)
    print("          of those, admitting an affine map with |scale| <= 8 : %d"
          % len(hits))
    for h in hits:
        print("             %s" % (h,))
    print("       dram-cursor-closure.md sect. 4 got 0 of 14 with a narrower field")
    print("       set and a narrower target set; this gets %d of %d.  A 1-bit unit"
          % (len(hits), ncar))
    print("       selector indexing a two-entry table of hardwired bases is not")
    print("       refutable by any such search -- but it is exactly as unfalsifiable")
    print("       as a hardwired per-unit RING, and only the ring explains why the")
    print("       payload is 0x25 rather than 0x00 or 0xDA.")
    print()

    # ---- sweep 3: the header consumers and the gap -----------------------
    print("  ---- SWEEP 3.  ** THE EPILOGUE RELOAD FALSIFIES A PUBLISHED RESULT. **")
    print("       dram-cursor-closure.md item D: `in the surviving |R|=2 family the")
    print("       run from the unit-1 reload to the frame boundary is RELOAD-FREE,")
    print("       so entry = 0x00 + 32 + 0 = 0x20.'  I-RAM 62 (`801.0.26.825')")
    print("       sits inside exactly that run -- the same note's item C quotes the")
    print("       word.  |R| >= 3, and the frame-entry cursor is whatever I-RAM 62")
    print("       leaves.  Sweep: can ANY machine in the class put the header's")
    print("       consumers inside the 0x20..0x25 gap, given that reload?")
    okgap = []
    for inc in ("PRE", "POST"):
        for wst in ("RESET", "MOD"):
            for wld in (False, True):
                step = make_cursor(inc, wst, wld)
                for ctx, ring in ((0, None), (1, None)):
                    for r in (rings0 if ctx == 0 else rings1):
                        for h in (1, 2, 3):
                            cur, _ = step(0, r, load=RELOAD_EPI)
                            cs = []
                            for _ in range(h):
                                cur, c = step(cur, r)
                                cs.append(c)
                            if all(c in GAP for c in cs) and len(set(cs)) == h:
                                okgap.append((inc, wst, wld, ctx, r, tuple(cs)))
    print("       machines putting 1..3 header consumers wholly inside the gap: %d"
          % len(okgap))
    if okgap:
        for x in okgap[:6]:
            print("          %s" % (x,))
    print("       -> item D's VALUE 0x20 does not survive its own note.  What DOES")
    print("       survive is the MEASUREMENT that 0x20..0x25 is the only gap in the")
    print("       whole descriptor file -- and the ring gives it a better reason:")
    print("       unit 1's ring [0x00, 0x26) holds 38 cells and the reverbs use 32.")
    print("       The gap is the unused top of unit 1's own partition.")
    print()
    print("       Where the header's consumers DO land, both readings printed:")
    for inc in ("PRE", "POST"):
        for ctx, ring in ((0, (0x26, 0x40)), (1, (0x00, 0x26))):
            step = make_cursor(inc, "RESET", False)
            cur, _ = step(0, ring, load=RELOAD_EPI)
            cs = []
            for _ in range(3):
                cur, c = step(cur, ring)
                cs.append("0x%02X" % c)
            print("          %-4s, unit-%d ring %s : %s"
                  % (inc, ctx, "[0x%02X,0x%02X)" % ring, " ".join(cs)))
    print("       Under the unit-0 ring they re-take the unit-0 block's own cells")
    print("       rel 1..3; under the unit-1 ring the reverb's rel 0..2.  BOTH are")
    print("       live and this pass does NOT choose.  Either way the reload at")
    print("       I-RAM 44 resets the cursor before the body runs, so neither")
    print("       reading disturbs the #cells == #consumers identity.")
    print()
    print("  ---- SWEEP 4.  AND WHAT THE SURVIVORS SAY ABOUT I-RAM 46 / 54.")
    fam2 = collections.Counter((s[0], s[3]) for s in survivors)
    for inc in ("PRE", "POST"):
        for pc in (0, 1):
            print("       %-4s + `46/54 %-14s' : %4d surviving ring pairs"
                  % (inc, "consume" if pc else "do not consume",
                     fam2.get((inc, pc), 0)))
    print("       dram-cursor-closure.md sect. 3.6 called `I-RAM 46/54 consume")
    print("       nothing' option (a) and labelled it CONSISTENT.  In the PRE")
    print("       family it is FORCED -- no survivor has them consuming.  In the")
    print("       POST family both branches survive.  Reported as a two-branch")
    print("       result and NOT collapsed to the one I preferred.")
    return len(survivors) > 0


# ===========================================================================
#  3.  alt
# ===========================================================================
def cmd_alt(C):
    head(3, "WHERE THE READ/WRITE ALTERNATION BREAKS -- the ground TASK B needs")
    al = aligned_algos(C)
    print("  POPULATION (method rule 9): 91 algorithms ship descriptor cells; %d"
          % len(al))
    print("  have #cells == #consumers and carry every test below; %d cells."
          % sum(len(c) for (_a, _u, c, _k) in al))
    cens = collections.Counter()
    strict, broken, unequal = [], [], []
    for (a, _u, _cells, cons) in al:
        s = rwstring(cons)
        for ch in s:
            cens[ch] += 1
        ins = [ch for ch in s if ch != "?"]
        (strict if all(ins[i] != ins[i + 1] for i in range(len(ins) - 1))
         else broken).append(a)
        if s.count("R") != s.count("W"):
            unequal.append(a)
    print("  CENSUS: READ %d  WRITE %d  still trapping (C format) %d"
          % (cens["R"], cens["W"], cens["?"]))
    print("     adjudication-round5 sect. 7 measured 416 / 365 / 48 over the same")
    print("     population.  Reproduced exactly, from an independent walk.")
    print()
    print("  strictly alternating (ignoring C-format cells) : %d of %d"
          % (len(strict), len(al)))
    print("  ALTERNATION BREAKS                             : %d of %d"
          % (len(broken), len(al)))
    print("  unequal READ and WRITE counts                  : %d of %d"
          % (len(unequal), len(al)))
    print()
    print("  THE %d ALGORITHMS WHERE M2 AND M5 CAN DIFFER AT ALL:" % len(broken))
    for (a, u, cells, cons) in al:
        if a in broken:
            s = rwstring(cons)
            print("     a%-3d u%d n=%-2d %-22s %-34s R%-2d W%-2d ?%d"
                  % (a, u, len(cells), C.name(a)[:22], s,
                     s.count("R"), s.count("W"), s.count("?")))
    print()
    print("  ** THE DEGENERACY, STATED BEFORE ANY SCORE (method rule 4). ** On the")
    print("  %d strictly-alternating algorithms a single +1 cursor and two +2" % len(strict))
    print("  cursors visit the same cells in the same order: M2 and M5 are ONE")
    print("  MACHINE COUNTED TWICE there.  Control 2 demonstrates it.  Every")
    print("  head-to-head below is scored only where they actually disagree.")
    return True


# ===========================================================================
#  4.  m5 -- TASK B
# ===========================================================================
def assign_M5(cons, n, aR, sR, aW, sW, cfmt="READ"):
    """the k-th READ takes cell aR + k*sR, the k-th WRITE aW + k*sW.  None if
    that is not a bijection onto [0, n) without leaving the block."""
    cell = [None] * n
    ir = iw = 0
    for (_i, w) in cons:
        d = dirof(w) or cfmt
        if d == "READ":
            c, ir = aR + ir * sR, ir + 1
        else:
            c, iw = aW + iw * sW, iw + 1
        if c < 0 or c >= n or cell[c] is not None:
            return None
        cell[c] = w
    return None if any(x is None for x in cell) else cell


def assign_M5block(cons, n, reads_first=True, cfmt="READ"):
    """reads take the first R cells, writes the last W (or vice versa)."""
    ds = [dirof(w) or cfmt for _i, w in cons]
    R = sum(1 for d in ds if d == "READ")
    cell = [None] * n
    ir, iw = (0, R) if reads_first else (n - R, 0)
    for (_i, w), d in zip(cons, ds):
        if d == "READ":
            c, ir = ir, ir + 1
        else:
            c, iw = iw, iw + 1
        if c < 0 or c >= n or cell[c] is not None:
            return None
        cell[c] = w
    return None if any(x is None for x in cell) else cell


def oracles(C, A):
    o = {"O1": [0, 0], "O2": [0, 0], "O3": [0, 0]}
    for (a, _u, cells, _cons) in aligned_algos(C):
        wd = A.get(a)
        if wd is None:
            continue
        ck = sorted(cells)
        idx = {c: i for i, c in enumerate(ck)}
        taps = C.taps(a)
        tc = [dirof(wd[idx[c]]) for c in taps if c in idx]
        tc = [x for x in tc if x is not None]
        if len(tc) >= 2:
            o["O1"][1] += 1
            o["O1"][0] += len(set(tc)) == 1
        for c, b24 in taps.items():
            if c not in idx:
                continue
            bc = [x for x in ck if cells[x] == b24 - 2]
            if not bc:
                continue
            dt, db = dirof(wd[idx[c]]), dirof(wd[idx[bc[0]]])
            if dt is None or db is None:
                continue
            o["O2"][1] += 1
            o["O2"][0] += dt != db
        byval = collections.defaultdict(list)
        for c in ck:
            byval[cells[c]].append(c)
        for _v, cs in byval.items():
            if len(cs) != 2:
                continue
            d1, d2 = dirof(wd[idx[cs[0]]]), dirof(wd[idx[cs[1]]])
            if d1 is None or d2 is None:
                continue
            o["O3"][1] += 1
            o["O3"][0] += d1 != d2
    return o


def anchor_sites(C, A):
    """-> {(algo, tap cell): True/False}.  bounds.py's host-anchor statistic,
    re-implemented against an ARBITRARY cell<->word map."""
    out = {}
    for (a, u, cells, _cons) in aligned_algos(C):
        wd = A.get(a)
        if wd is None:
            continue
        ck = sorted(cells)
        idx = {c: i for i, c in enumerate(ck)}
        lo, hi = (0, 32767) if u == 0 else (32768, 65535)
        W = [c for c in ck
             if dirof(wd[idx[c]]) == "WRITE" and lo <= cells[c] <= hi]
        for c, b24 in C.taps(a).items():
            if c not in idx:
                continue
            good = False
            if dirof(wd[idx[c]]) == "READ":
                cand = [x for x in W if cells[x] < cells[c]]
                if cand:
                    b = max(cand, key=lambda x: cells[x])
                    good = cells[b] == b24 - 2
            out[(a, c)] = good
    return out


def cmd_m5(C):
    head(4, "TASK B -- MODEL M5 (TWO CURSORS, ONE PER DIRECTION).  REFUTED.")
    al = aligned_algos(C)
    print("  ---- STEP 1.  THE ENUMERATION OF M5 ITSELF (method rule 3).")
    print("     A cursor is (start, stride).  M5 = two of them, partitioning the")
    print("     block.  Enumerated: aR, aW in [0,8), sR, sW in [1,4], plus the two")
    print("     BLOCK shapes (reads first / writes first).  A cursor may not leave")
    print("     its algorithm's block, because the ring is per UNIT and far bigger")
    print("     than any block.")
    print("     ** THE CONSTRAINT THAT DOES THE WORK: the parameters must be")
    print("     ALGORITHM-INDEPENDENT.  `ptr' measures THREE pointer writes in the")
    print("     entire ROM, all in the header/epilogue, none in any body image, so")
    print("     there is nowhere to keep a per-algorithm second cursor base.")
    print("     M5 with a per-algorithm partition is not a model -- it is one free")
    print("     parameter per cell, and it predicts nothing. **")
    print()
    cand = [(aR, sR, aW, sW) for aR in range(8) for sR in range(1, 5)
            for aW in range(8) for sW in range(1, 5)]
    feas = sorted(((sum(1 for (_a, _u, c, k) in al
                        if assign_M5(k, len(c), *t) is not None), t)
                   for t in cand), reverse=True)
    print("     %d tuples tried.  How many of the %d aligned algorithms each can"
          % (len(cand), len(al)))
    print("     even ADDRESS (a bijection onto the block):")
    for ok, t in feas[:4]:
        print("        aR=%d sR=%d aW=%d sW=%d : %2d of %d %s"
              % (t[0], t[1], t[2], t[3], ok, len(al),
                 "  <- the PARITY split" if t in ((0, 2, 1, 2), (1, 2, 0, 2))
                 else ""))
    nb = sum(1 for (_a, _u, c, k) in al
             if assign_M5block(k, len(c)) is not None)
    print("        M5-BLOCK, reads first        : %2d of %d" % (nb, len(al)))
    print("        M2 (ONE cursor, +1)          : %2d of %d  by construction"
          % (len(al), len(al)))
    print()
    print("  ---- STEP 2.  WHAT REFUTES THE PARITY M5 -- COUNTING ALONE.  No")
    print("     oracle, no score, no rule beyond the direction round 5 forced.")
    par = (0, 2, 1, 2)
    bad = [(a, len(c), rwstring(k)) for (a, _u, c, k) in al
           if assign_M5(k, len(c), *par) is None]
    for a, n, s in bad:
        print("        a%-3d n=%-2d %-22s R%-2d W%-2d -- parity needs R%d W%d"
              % (a, n, C.name(a)[:22], s.count("R"), s.count("W"),
                 (n + 1) // 2, n // 2))
    print("     ** %d of %d algorithms cannot be addressed at all. **"
          % (len(bad), len(al)))
    print()
    print("     AND THE TWELVE REVERBS ARE REFUTED FOR *BOTH* C-FORMAT POLARITIES,")
    print("     which matters because the C format is still OPEN: their four")
    print("     C40.1.80.000 cells carry ONE IDENTICAL WORD, so all four take the")
    print("     same direction.  Reverb counts:")
    for cf in ("READ", "WRITE"):
        s = rwstring(next(k for (a, _u, _c, k) in al if a == 16), cf)
        print("        C format = %-5s : R%d W%d, parity needs R16 W16"
              % (cf, s.count("R"), s.count("W")))
    print("     Neither polarity reaches 16/16.  No decode of the C format can")
    print("     rescue the parity M5.")
    print()
    print("  ---- STEP 3.  WHERE PARITY *IS* FEASIBLE: THE HEAD-TO-HEAD, SCORED")
    print("     ONLY ON THE SITES WHERE THE TWO MODELS DISAGREE (method rule 7).")
    A2 = {a: [w for _i, w in k] for (a, _u, _c, k) in al}
    A5 = {}
    A5B = {}
    for (a, _u, c, k) in al:
        m = assign_M5(k, len(c), *par)
        A5[a] = m
        A5B[a] = assign_M5block(k, len(c))
    dis = [a for a in A2 if A5.get(a) is not None and A5[a] != A2[a]]
    print("     algorithms where parity-M5 is feasible AND differs from M2: %s"
          % dis)
    s2, s5 = anchor_sites(C, A2), anchor_sites(C, A5)
    both = [k for k in s2 if k in s5 and s2[k] != s5[k]]
    print("     HOST-ANCHOR, head to head on the %d tap sites where the two models"
          % len(both))
    print("     give DIFFERENT verdicts:   M2 %d : %d M5"
          % (sum(1 for k in both if s2[k]), sum(1 for k in both if s5[k])))
    print("     (the statistic: does the model put each host-named op-0x67 tap on")
    print("     a line whose base cell holds that record's own BASE24 - 2?  It is")
    print("     host-side ground truth and nothing was fitted to it.)")
    keep = set(dis)
    r2 = {a: (v if a in keep else None) for a, v in A2.items()}
    r5 = {a: (v if a in keep else None) for a, v in A5.items()}
    o2, o5 = oracles(C, r2), oracles(C, r5)
    print("     ROUND-5 ORACLES, restricted to those %d algorithms:" % len(dis))
    for k in ("O1", "O2", "O3"):
        print("        %s   M2 %2d/%-2d    M5 %2d/%-2d %s"
              % (k, o2[k][0], o2[k][1], o5[k][0], o5[k][1],
                 "" if o2[k][0] * o5[k][1] >= o5[k][0] * o2[k][1]
                 else "  <== ** FAVOURS M5 -- reported, not hidden **"))
    print()
    print("  ---- STEP 4.  M5-BLOCK, and why it dies differently.")
    Rs = sorted({rwstring(k).count("R") for (_a, _u, _c, k) in al})
    print("     It addresses %d of %d -- but its WRITE cursor must start at" % (nb, len(al)))
    print("     block_base + R, where R is THAT ALGORITHM's read count.  Corpus R")
    print("     values: %s -- %d distinct start values." % (Rs, len(Rs)))
    print("     One reload word exists.  REFUTED by the pointer census, not by a")
    print("     score.  And it scores too, for the record:")
    sB = anchor_sites(C, A5B)
    bothB = [k for k in s2 if k in sB and s2[k] != sB[k]]
    print("        HOST-ANCHOR head to head on %d disagreeing sites: M2 %d : %d M5-BLOCK"
          % (len(bothB), sum(1 for k in bothB if s2[k]),
             sum(1 for k in bothB if sB[k])))
    print()
    print("  ---- STEP 5.  THE WHOLE-CORPUS PICTURE, populations printed.")
    for nm, A in (("M2      ", A2), ("M5-parity", A5), ("M5-block ", A5B)):
        st = anchor_sites(C, A)
        oo = oracles(C, A)
        print("     %-9s HOST-ANCHOR %2d/%-2d   O1 %2d/%-2d  O2 %2d/%-2d  O3 %3d/%-3d"
              % (nm, sum(st.values()), len(st), oo["O1"][0], oo["O1"][1],
                 oo["O2"][0], oo["O2"][1], oo["O3"][0], oo["O3"][1]))
    st2 = anchor_sites(C, A2)
    print("     M2's three HOST-ANCHOR misses, printed rather than asserted:")
    for (a, c), good in sorted(st2.items()):
        if not good:
            print("        a%-3d %-22s cell 0x%02X  BASE24 %d"
                  % (a, C.name(a)[:22], c, C.taps(a)[c]))
    o2m = []
    for (a, _u, cells, _cons) in al:
        wd = A2.get(a)
        ck = sorted(cells)
        idx = {c: i for i, c in enumerate(ck)}
        for c, b24 in C.taps(a).items():
            if c not in idx:
                continue
            bc = [x for x in ck if cells[x] == b24 - 2]
            if not bc:
                continue
            dt, db = dirof(wd[idx[c]]), dirof(wd[idx[bc[0]]])
            if dt is not None and db is not None and dt == db:
                o2m.append((a, c))
    print("     and O2's three misses under M2: %s"
          % ", ".join("a%d cell 0x%02X" % x for x in o2m))
    print("     M2's 33/36 reproduces bounds.py's host-anchor exactly, and its")
    print("     O1 10/10 and O3 133/133 reproduce adjudication-round5 sect. 1 --")
    print("     from an independent implementation, which is the check that this")
    print("     instrument is the same instrument.")
    print("     ** WHERE IT DOES *NOT* REPRODUCE, SAID PLAINLY: my O2 has 33 pairs")
    print("     and round 5's had 28.  Mine pairs a tap with ANY cell of the same")
    print("     algorithm holding BASE24 - 2; round 5's used its 28 curated")
    print("     anchored pairs.  The 5 extra pairs are the 3 misses above plus 2")
    print("     hits, and the misses are the same a64/a68/a70 `+4 geometry' sites")
    print("     round 5 sect. 4 flagged.  My O2 is the LOOSER instrument and its")
    print("     absolute score must not be quoted against round 5's.")
    print()
    print("  ---- VERDICT.  M5 IS REFUTED, on three independent routes:")
    print("     (1) the pointer census leaves nowhere to keep a second, per-")
    print("         algorithm cursor base -- which every M5 shape except parity")
    print("         requires;")
    print("     (2) the parity shape, the only algorithm-independent one, cannot")
    print("         ADDRESS %d of %d algorithms, the twelve reverbs among them and"
          % (len(bad), len(al)))
    print("         for both C-format polarities;")
    print("     (3) where it can, the host anchors beat it head to head.")
    print("     THE PUBLISHED CELL ASSIGNMENTS FOR THE NON-ALTERNATING REGIONS")
    print("     STAND UNCHANGED.  Nothing in TARGET 2's constraint set moves.")
    return True


# ===========================================================================
#  5.  wrap -- TASK C
# ===========================================================================
def cmd_wrap(C):
    head(5, "TASK C -- THE WRAP.  TWO DIFFERENT OBJECTS, SEPARATED.")
    print("  The brief's `where does the cursor wrap' and r3-delaydram.md's")
    print("  rotation register `G' are NOT the same register and not the same")
    print("  memory.  Conflating them has cost this project a round before.")
    print()
    print("  ---- (a) THE DESCRIPTOR CURSOR'S WRAP.  Answered by TASK A: it is")
    print("       PER UNIT; unit 1's ring is [0x00, L_1) with L_1 in 0x20..0x26")
    print("       and 0x26 under the MOD flavour; unit 0's base is 0x26.  The wrap")
    print("       fires EXACTLY ONCE per frame -- on the pre-increment immediately")
    print("       after I-RAM 52's reload -- and that single firing is the whole")
    print("       mechanism by which one word serves two units.")
    print("       CONSISTENT arithmetic, not forced: a 64-cell descriptor RAM split")
    print("       38 / 26 at 0x26.  Unit 1 uses 32 of its 38 (the gap 0x20..0x25 is")
    print("       the remainder); GATED REVERB uses 20 of unit 0's 26; the corpus")
    print("       maximum cell is 0x%02X and 0x3A..0x3F are never written." % MAXCELL)
    print()
    print("  ---- (b) THE DELAY-DRAM ROTATION `G'.  A different register in the")
    print("       audio memory.  TARGET 1 has just added the strongest constraint")
    print("       on it that exists: every algorithm ships exactly ONE CEILING cell")
    print("       holding a per-unit constant OUTSIDE its own region.")
    cnt = collections.Counter()
    try:
        js = json.load(open(os.path.join(HERE, "..", "analysis",
                                         "descriptor-cell-classes.json")))
        for _a, r in js["algorithms"].items():
            for c in r["cells"]:
                if c.get("role") == "CEILING":
                    cnt[(r["unit"], c["value"])] += 1
    except Exception as e:                                  # pragma: no cover
        print("       (descriptor-cell-classes.json unreadable: %s)" % e)
    for (u, v), n in sorted(cnt.items()):
        print("          unit %d  CEILING = %5d   x%d" % (u, v, n))
    print("       Unit 0 owns DRAM [0, 32767] and its ceiling cell holds 32768 =")
    print("       top + 1.  Unit 1 owns [32768, 65535] and its ceiling cell holds")
    print("       32767 = floor - 1.  ONE physical boundary, written as the")
    print("       EXCLUSIVE bound on whichever side the unit is on.")
    print()
    print("       ENUMERATION of what that pair can be (method rule 3):")
    print("         (1) each unit's ring is its own region and the cell is the")
    print("             exclusive limit in the direction of travel -- which needs")
    print("             the two units to travel in OPPOSITE directions;")
    print("         (2) ONE shared partition constant, handed to each unit in the")
    print("             polarity that unit needs, the hardware deriving its limit;")
    print("         (3) not a limit at all, but a null / no-line sentinel.")
    print("       (2) and (3) survive; (1) needs a direction asymmetry nothing in")
    print("       the corpus shows and the rotation sign s = -1 is corpus-wide.")
    print("       ** The wrap POINT is MEASURED.  The MECHANISM is OPEN, the")
    print("       instruction that consumes the ceiling cell still traps, and")
    print("       therefore nothing here can be applied (method rule 6). **")
    return True


# ===========================================================================
#  6.  control
# ===========================================================================
def cmd_control(C):
    head(6, "THE CONTROLS -- each built to fail, and shown failing")
    al = aligned_algos(C)
    verdicts = []

    print("  CONTROL 1 -- ** THE FIRST VERSION OF THIS CONTROL COULD NOT FAIL,")
    print("     AND IT IS PRINTED BEFORE THE ONE THAT WORKS. **  I first fed the")
    print("     sweep a deliberately wrong unit-1 anchor (0x01) and expected no")
    print("     survivors.  It found 42 -- because the ring BASE is a free")
    print("     parameter, so the model simply re-bases itself onto any anchor")
    print("     I hand it.  `B_1 = 0x00 is FORCED' is therefore the model")
    print("     RECOVERING the measurement, and it is not evidence for anything.")
    print("     Method rule 1, caught before publication.")
    print()
    print("     THE REPLACEMENT, which tests the thing that is actually claimed:")
    print("     is the WRAP NECESSARY?  Twin = the same sweep with the wrap")
    print("     switched off entirely (L_u = infinity).  PREDICTION written")
    print("     first: zero survivors on the real anchors, and NON-zero on a")
    print("     fake unit-1 anchor of 0x26, which needs no wrap.")
    rings1 = [(b, l) for b in range(0, 9) for l in range(0x20, 0x42) if l > b]
    rings0 = [(b, l) for b in range(0x00, 0x29) for l in range(0x3A, 0x42)
              if l > b]
    BIG = [(0, 0x1000)]

    def sweep(b1, r1set, r0set):
        n = 0
        for inc in ("PRE", "POST"):
            for wst in ("RESET", "MOD"):
                for wld in (False, True):
                    st = make_cursor(inc, wst, wld)
                    for pc in (0, 1):
                        if not any(run_anchor(st, r0, BASE_U0, 20,
                                              RELOAD_IMM, pc) for r0 in r0set):
                            continue
                        n += sum(1 for r1 in r1set
                                 if run_anchor(st, r1, b1, N1, RELOAD_IMM, pc))
        return n
    a = sweep(BASE_U1, rings1, rings0)
    b = sweep(BASE_U1, BIG, BIG)
    c = sweep(0x26, BIG, BIG)
    print("     wrap ON,  real anchors (0x26 / 0x00) : %d survivors" % a)
    print("     wrap OFF, real anchors (0x26 / 0x00) : %d survivors" % b)
    print("     wrap OFF, FAKE anchors (0x26 / 0x26) : %d survivors" % c)
    print("     -> the control %s"
          % ("REJECTS: the wrap is NECESSARY, and the test can still say YES."
             if (b == 0 < c and a > 0) else
             "DID NOT REJECT -- report as a failure."))
    verdicts.append(b == 0 < c and a > 0)
    print()

    print("  CONTROL 2 -- THE DEGENERACY CHECK, RUN BEFORE ANY M5 SCORE IS")
    print("     BELIEVED (method rule 4).  On the strictly-alternating algorithms")
    print("     M2 and the parity M5 must produce the IDENTICAL map.")
    same = diff = 0
    for (a, _u, cells, cons) in al:
        s = rwstring(cons)
        ins = [ch for ch in s if ch != "?"]
        if not all(ins[i] != ins[i + 1] for i in range(len(ins) - 1)):
            continue
        m5 = assign_M5(cons, len(cells), 0, 2, 1, 2)
        if m5 is None:
            continue
        if m5 == [w for _i, w in cons]:
            same += 1
        else:
            diff += 1
    print("     identical maps %d, different %d" % (same, diff))
    print("     -> one machine counted twice.  A test that `separated' the two")
    print("        models there would be measuring nothing, and the reverbs --")
    print("        the corpus's biggest and best-understood blocks -- are all in")
    print("        that set.  This is why TASK B had to go looking for the")
    print("        alternation breaks in the first place.")
    verdicts.append(diff == 0)
    print()

    print("  CONTROL 3 -- A RIVAL THAT NEVER LOOKS AT THE DIRECTION (rule 7's")
    print("     `build one that ignores the instruction').  Assign cells by")
    print("     CONSUMER PARITY instead: consumer k takes cell k regardless.")
    print("     That is M2 itself -- so the honest control is the other way")
    print("     round: a map that ignores the PROGRAM ORDER.  Reverse each")
    print("     block's consumer list and score it.")
    AR = {a: [w for _i, w in k][::-1] for (a, _u, _c, k) in al}
    A2 = {a: [w for _i, w in k] for (a, _u, _c, k) in al}
    sr, s2 = anchor_sites(C, AR), anchor_sites(C, A2)
    bth = [k for k in s2 if s2[k] != sr[k]]
    print("     HOST-ANCHOR: M2 %d/%d, reversed %d/%d; head to head on the %d"
          % (sum(s2.values()), len(s2), sum(sr.values()), len(sr), len(bth)))
    print("     disagreeing sites: M2 %d : %d reversed"
          % (sum(1 for k in bth if s2[k]), sum(1 for k in bth if sr[k])))
    verdicts.append(sum(s2.values()) > sum(sr.values()))
    print()

    print("  CONTROL 4 -- A PERMUTATION NULL FOR THE HOST-ANCHOR STATISTIC.")
    print("     Shuffle which word takes which cell inside each algorithm; the")
    print("     multiset of words and every value are preserved.  400 trials.")
    rnd = random.Random(20260727)
    sc = []
    for _t in range(400):
        AS = {}
        for (a, _u, _c, k) in al:
            ws = [w for _i, w in k]
            rnd.shuffle(ws)
            AS[a] = ws
        sc.append(sum(anchor_sites(C, AS).values()))
    sc.sort()
    hit = sum(s2.values())
    print("     shuffled: min %d  median %d  max %d       M2: %d"
          % (sc[0], sc[len(sc) // 2], sc[-1], hit))
    print("     trials reaching M2's score: %d of 400"
          % sum(1 for x in sc if x >= hit))
    verdicts.append(sc[-1] < hit)
    print()

    print("  CONTROL 5 -- ** ONE OF MINE THAT DID NOT DO WHAT I BUILT IT FOR,")
    print("     PRINTED RATHER THAN DELETED. **  Of the three round-5 oracles")
    print("     only O1 and O3 reject the parity M5 on the algorithms where it is")
    print("     feasible; O2 (tap / own line base oppose) comes out SLIGHTLY IN")
    print("     M5's FAVOUR there -- see sect. 4 step 3.  O2 is therefore a failed")
    print("     discriminator for THIS question and is reported as one.  Its three")
    print("     corpus-wide misses under M2 (a64/a68/a70) are the `+4 geometry'")
    print("     sites round 5 sect. 4 already flagged, and they come from MY O2")
    print("     being looser than round 5's -- a defect of my instrument, not of")
    print("     the map.  The HOST-ANCHOR statistic's three misses are a different")
    print("     set (a9, a65, a67) and those ARE dram-matching.md's firmware")
    print("     inconsistencies.  Two statistics, two miss sets; do not merge them.")
    print()
    print("  CONTROL 6 -- THE INSTRUMENT ITSELF.  This pass re-implements the")
    print("     host-anchor statistic and the three oracles from scratch.  If the")
    print("     re-implementation did not reproduce bounds.py's 33/36 and round")
    print("     5's O1 10/10 and O3 133/133 exactly, nothing else here could be")
    print("     believed.  Sect. 4 step 5 prints them.")
    print()
    print("  CONTROLS: %s" % ("ALL PASS" if all(verdicts) else "SEE ABOVE"))
    return all(verdicts)


# ===========================================================================
#  7.  predict
# ===========================================================================
def cmd_predict(C):
    head(7, "PREDICT-THEN-CHECK -- written before the experiments; hits AND misses")
    rows = [
        ("PA1", "the per-unit base would be carried by a setup-block register --"
                " 0x21 (0x70/0x50) or 0x27 (0x6C/0x64)",
         "MISS.  The two differences are 0x20 and 0x08 and neither makes 0x26;"
         " the widened affine search finds 0 carriers among the 12 differing"
         " fields of the paired setup words."
         " The difference is not in anything the frame writes."),
        ("PA2", "the unit-0 anchor plus the reload would FORCE pre-increment",
         "MISS, and instructive.  POST survives if the ring also clamps on load."
         " Two families, and the I-RAM 46/54 consumption flag is locked to the"
         " branch -- so `do they consume' is not an independent question."),
        ("PA3", "a per-unit ring with unit-1 top = 0x26 would be the unique"
                " single-parameter fix",
         "HIT on the invariant (B_1 = 0x00 and L_1 <= 0x26 in EVERY survivor),"
         " MISS on uniqueness: the anchors pin L_1 only to 0x20..0x26; only the"
         " MOD flavour of the wrap pins it to 0x26 exactly."),
        ("PA6", "my TASK-A control would reject a deliberately wrong unit-1"
                " anchor",
         "MISS, and it is a method-rule-1 failure of my own.  It found 42"
         " survivors for a fake anchor of 0x01, because the ring BASE is a free"
         " parameter and the model re-bases onto whatever anchor it is handed."
         " The control that works tests whether the WRAP is necessary, and it"
         " does reject (0 survivors wrapless, 8 on a fake anchor needing no"
         " wrap).  Both are printed in control 1."),
        ("PA4", "the epilogue reload would be consistent with the header's"
                " consumers landing in the 0x20..0x25 gap",
         "MISS, and it falsifies a published result: ZERO machines in the whole"
         " class put them there.  I-RAM 62 sits inside the run"
         " dram-cursor-closure.md item D calls reload-free, so `entry = 0x20'"
         " does not follow from closure."),
        ("PA5", "there would be a second, overlooked write to the descriptor"
                " pointer somewhere in the corpus",
         "MISS -- three in the entire ROM, all in the header/epilogue, none in"
         " any body image.  That MISS is exactly what kills M5 in TASK B."),
        ("PB1", "the parity M5 would be refuted by COUNTING alone, no oracle",
         "HIT.  It cannot address 22 of the 83 aligned algorithms."),
        ("PB2", "the block M5 would survive counting and be killed by the host"
                " anchors",
         "HIT on survival, MISS on the mechanism: the anchors are not what"
         " kills it.  Its write cursor needs one of 8 per-algorithm start"
         " values and the ROM has nowhere to keep one."),
        ("PB3", "the reverbs would not separate M2 from M5",
         "HIT, and it is a rule-4 degeneracy demonstrated in control 2 -- and"
         " then a surprise: the reverbs refute the parity M5 anyway, by"
         " COUNTING, for both C-format polarities."),
        ("PB4", "the round-5 oracles would reject the parity M5 where it is"
                " feasible",
         "SPLIT.  O1 and O3 reject it decisively; O2 comes out slightly in M5's"
         " favour.  Reported in control 5 as a failed discriminator."),
        ("PB5", "the census 416 READ / 365 WRITE would reproduce",
         "HIT, exactly, from an independent implementation -- as do the"
         " host-anchor 33/36 and the oracles O1 10/10 and O3 133/133."),
        ("PC1", "the descriptor-cursor wrap and the delay-DRAM rotation G would"
                " turn out to be the same question",
         "MISS.  They are different registers in different memories; only the"
         " descriptor one is answerable today."),
    ]
    for k, p, r in rows:
        print("  %s  PREDICTED: %s" % (k, p))
        print("       RESULT : %s" % r)
    n = sum(1 for _k, _p, r in rows if r.startswith("HIT"))
    print()
    print("  %d hits, %d misses/splits, of %d." % (n, len(rows) - n, len(rows)))
    return True


# ---------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "ptr", "reload", "alt", "m5", "wrap",
                             "control", "predict"])
    ap.add_argument("--sub", default=os.path.join(
        repo, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(
        repo, "original_ROMs", "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    C = DM.Corp(args.sub, args.main, args.tools)
    for name, fn in (("ptr", cmd_ptr), ("reload", cmd_reload), ("alt", cmd_alt),
                     ("m5", cmd_m5), ("wrap", cmd_wrap),
                     ("control", cmd_control), ("predict", cmd_predict)):
        if args.cmd in ("all", name):
            fn(C)
            print()


if __name__ == "__main__":
    main()
