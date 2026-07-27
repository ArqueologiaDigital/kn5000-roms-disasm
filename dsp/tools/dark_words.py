#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dark_words.py -- THE WORDS THAT EXECUTE NOTHING.

NEC uPD6383GF (Technics SX-KN5000 IC311).  The MAME core sorts every slot of a
sample frame into three states:

    DECODED   upd6383_disassembler::decoded(w)                -- exec_decoded()
    PARTIAL   !decoded(w) && (addressing_only(w) || has_addressing(w))
              -- its ADDRESSING runs, its arithmetic does not
    TRAP      everything else -- NOTHING AT ALL HAPPENS

The cold-boot frame is 285 slots = 108 + 91 + 86 (MEASURED live,
kn7000_mame/notes/dsp-closure-applied.md item C).  The 86 TRAP slots are the
subject of this tool: they have never been characterised as a SET, only counted.

Everything here is STATIC.  It reconstructs the frame from the Sub CPU ROM plus
the two host patch words and re-derives the 108/91/86 split, so the
reconstruction is checked against a live measurement before anything is
concluded from it (see `control`).

    python3 dsp/tools/dark_words.py [all|frame|enumerate|groups|leverage|
                                     critical|neighbours|control]

stdlib only.  Findings: dsp/analysis/dark-words.md.
"""
import argparse
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                              # noqa: E402

ALGO_TABLE = 0x0001ED7C
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
N_ALGOS = 100

# the cold-boot pair, MEASURED from the live upload capture
# (notes/data/kn5000_dsp1_upload_coldboot.txt): unit 0 = CHORUS = ROM algo 1,
# unit 1 = ROOM REVERB = ROM algo 16.
COLD_U0_ALGO = 1
COLD_U1_ALGO = 16

HDR, HDR_N = 0, 60
EPI, EPI_N = 60, 23
U0, U1 = 84, 200
CALL0, CALL1 = 49, 59
# the two words the host rewrites in I-RAM after EFF_Link, from the same
# capture (analysis/k5-output-stage.md sect. 2): setvec unit0,#84 / unit1,#200.
PATCH = {64: 0xC40A80445, 71: 0xC41900446}
FRAME_WAIT_IW = 82


# --------------------------------------------------------------------------
#  the frame
# --------------------------------------------------------------------------
def load_images(rompath, toolsdir):
    sys.path.insert(0, toolsdir)
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(rompath)

    def blk(addr, n):
        iram, _c, _o = E.parse_stream(rom, addr, limit=40)
        ws = [int.from_bytes(bytes(w), "big") for w in iram[0][1]]
        assert len(ws) == n, (addr, len(ws))
        return ws

    def body(algo, load):
        ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * algo))
        for a, ws, _l in ir:
            if a == load:
                return [int.from_bytes(bytes(w), "big") for w in ws]
        raise KeyError((algo, load))

    return (blk(HEADER_ROM, HDR_N), blk(EPILOGUE_ROM, EPI_N),
            body(COLD_U0_ALGO, U0), body(COLD_U1_ALGO, U1))


def frame(hdr, epi, u0, u1):
    """(slot, iram, word, region) in EXECUTION order -- the call/return
    sequencer of upd6383_device::run_frame().  The frame-wait word at I-RAM 82
    terminates the frame BEFORE it is counted as a slot, so 285 slots are
    executed out of 286 fetched."""
    e = list(epi)
    for a, w in PATCH.items():
        e[a - EPI] = w
    t = []
    t += [(i, hdr[i], "header 0..49  (pre unit-0 call)") for i in range(0, CALL0 + 1)]
    t += [(U0 + i, w, "unit-0 body   (CHORUS @84)") for i, w in enumerate(u0)]
    t += [(i, hdr[i], "header 50..59 (pre unit-1 call)") for i in range(CALL0 + 1, CALL1 + 1)]
    t += [(U1 + i, w, "unit-1 body   (ROOM REVERB @200)") for i, w in enumerate(u1)]
    t += [(EPI + i, w, "epilogue 60..82 (output stage)")
          for i, w in enumerate(e) if EPI + i < FRAME_WAIT_IW]
    return [(n, a, w, r) for n, (a, w, r) in enumerate(t)]


def klass(w):
    """DECODED | PARTIAL | TRAP -- exactly upd6383_device::run_frame()."""
    if D.decoded(w):
        return "DECODED"
    if D.addressing_only(w) or D.has_addressing(w):
        return "PARTIAL"
    return "TRAP"


def fmt(w):
    return "%03X.%X.%02X.%03X" % (D.hi12(w), D.class4(w), D.addr8(w), D.lo12(w))


def fam(w):
    """(hi12, class4, lo12): addr8 is an operand (pointer delta / unit tag /
    immediate byte), so it is not part of the opcode identity."""
    return (D.hi12(w), D.class4(w), D.lo12(w))


def famstr(f):
    return "%03X.%X.**.%03X" % f


# --------------------------------------------------------------------------
#  ★ WHY A WORD IS DARK -- the blocker attribution
#
#  TWO TIERS, and the distinction is the whole point of the leverage metric.
#
#  FAMILY blockers say "this word's entire interpretation is open": we do not
#  know what its operand fields even MEAN, so naming its SRC code would be
#  naming a field of a format we cannot read.  Attributing `SRC 0x19' to a
#  delay-DRAM word would inflate the SRC unknown with words whose lo12 is
#  probably not a SRC/ACTION route at all (R2/R3: the DRAM address comes from a
#  descriptor cursor, not from the word).
#
#  FIELD blockers apply ONLY to words already on a readable format -- a
#  datapath class, no format escape, no bit-11 modifier, no pointer-mode bit.
#  For those the format IS known and exactly which field values are unanchored
#  is a precise, countable statement.
#
#  A word carries a SET of blockers.  Resolving one member of a two-member set
#  recovers nothing; that is what the ranking below is built on.
# --------------------------------------------------------------------------
# ---------------------------------------------------------------------------
#  NOT EVERY UNKNOWN IS EQUALLY UNKNOWN, and the ranking is dishonest if it
#  pretends they are.  Three grades:
#
#    MODEL     the code has a NAMED role that the executor simply does not
#              implement (there is no delay-RAM read register, no table, no LFO
#              in exec_alu()).  Settling it is engineering, not discovery.
#    DISPUTED  two independent contexts give it different readings.  Settling it
#              needs a THIRD context, not more of either.
#    OPEN      no reading at all.
# ---------------------------------------------------------------------------
SRC_ROLE = {
    0x07: ("ANCHOR", "mem[ptr]"),
    0x10: ("ANCHOR", "the accumulator"),
    0x19: ("ANCHOR", "tempA"),
    0x1A: ("ANCHOR", "tempB"),
    0x0B: ("MODEL", "external delay-RAM read register (INFERRED; the 0x0B-vs-0x07 "
                    "separation is 0 of 106 clean)"),
    0x13: ("MODEL", "table lookup (INFERRED, the class-6 idiom)"),
    0x1C: ("MODEL", "LFO output (INFERRED; 87 of 87 clean against acc)"),
    0x08: ("MODEL", "LFO phase / unity multiplicand (INFERRED)"),
    0x00: ("DISPUTED", "reverb requires the delay-RAM reading 52696/52696; "
                       "SINGLE DELAY forbids it 0 of 5635"),
}
ACT_ROLE = {
    0x00: ("ANCHOR", "acc's adder input <- bus"),
    0x07: ("ANCHOR", "write the operand to the mode's destination"),
    0x12: ("ANCHOR", "no temp/memory side effect"),
    0x13: ("ANCHOR", "tempA <- bus"),
    0x14: ("ANCHOR", "tempB <- bus"),
    0x15: ("ANCHOR", "no temp/memory side effect"),
    0x19: ("ANCHOR", "tempA <- bus (second encoding)"),
}


def grade(key):
    """MODEL | DISPUTED | OPEN for one blocker key."""
    if key.startswith("SRC-"):
        return SRC_ROLE.get(int(key[4:], 16), ("OPEN", ""))[0]
    if key.startswith("ACT-"):
        return ACT_ROLE.get(int(key[4:], 16), ("OPEN", ""))[0]
    if key.startswith("DRAM-ADDR"):
        # R3 PROVED the address MECHANISM by construction; what is OPEN is the
        # descriptor cursor's PHASE, and R3 sect. 6.3 enumerates exactly three
        # candidates.  A three-way choice is still a discovery, not engineering.
        return "OPEN"
    if key in ("ACT07-OFFMODE2", "ST-OFFMODE2", "B7GATE"):
        return "DISPUTED"
    return "OPEN"


def lo12_is_route(w):
    """Does lo12 carry the SRC/ACTION operand route on this word?

    NO on the C format (lo12 is the immediate's DESTINATION -- 0x445/0x446 are
    the settled call vectors) and NO on the register-LOAD family (lo12 is a
    register SELECTOR, K3 sect. 8 item 1: `801.0.PP.821' is a register write and
    nothing else).  YES on the mode-1 ESCAPE (delay-DRAM) words, and that is not
    an assumption: the R1 solve reads `880.1.20.655' as sourcing tempA (SRC
    0x19) and `880.1.60.2D4' as delivering to tempB (ACT 0x14), and both
    readings survive its forcing."""
    return not (D.c_format(w) or D.is_regload(w))


def blockers(w):
    """-> [(tier, key, text)] -- the unknowns that ALL have to be resolved
    before this word could be executed.  Empty iff the word is decoded."""
    if D.decoded(w):
        return []
    hi, cl, lo = D.hi12(w), D.class4(w), D.lo12(w)
    B = []

    if D.c_format(w):
        # bits [24:12] are one 13-bit immediate; the destination is `lo12', and
        # TWO of its codes are already settled (0x445 / 0x446 = the per-unit call
        # vector, k5-output-stage.md sect. 2.4).  So the unknown is not "the C
        # format" -- it is one DESTINATION CODE at a time, which is the
        # granularity at which it has been resolved before.
        B.append(("FAMILY", "C-DEST-%03X" % lo,
                  "C-format 13-bit immediate: destination code 0x%03X open" % lo))
        return B

    if cl == 1:
        if hi & D.HI_ESC:
            # TWO unknowns, and a word needs BOTH: where the address comes from,
            # and which way the transfer goes.  R3 PROVED the address MECHANISM
            # (descriptor cell + G) but not the cursor's phase; R3 sect. 6.3
            # FALSIFIED the addr8 direction rule.
            B.append(("FAMILY", "DRAM-ADDR",
                      "external delay-DRAM: descriptor-cursor PHASE open "
                      "(R3 sect. 6.3, three readings enumerated)"))
            B.append(("FAMILY", "DRAM-DIR",
                      "external delay-DRAM: DIRECTION encoding open "
                      "(addr8 rule falsified)"))
        else:
            B.append(("FAMILY", "MODE1-SPACE",
                      "mode-1 word, no escape: the addressed SPACE is unmodelled "
                      "(host builds `000.1.PP.000' + tag 0x15 = D-RAM window)"))

    elif cl not in (2, 8, 0xA):
        # class 0 is the register-LOAD family; three of its members are decoded,
        # so a class-0 word that is dark is dark for a nameable second reason.
        if cl == 0 and D.is_regload(w):
            if hi & D.HI_ST:
                B.append(("FIELD", "REGLOAD-ST",
                          "register load that ALSO stores (hi12 bit 4): the "
                          "store target off mode 2 is unproven"))
            if D.lo_sel(w) not in (D.LO_SEL_CP, D.LO_SEL_DSC):
                B.append(("FIELD", "REGSEL-%02X" % D.lo_sel(w),
                          "register selector 0x%02X unidentified" % D.lo_sel(w)))
        else:
            B.append(("FAMILY", "CLASS-%X" % cl,
                      "class %X: addressing mode unknown" % cl))

    if not lo12_is_route(w):
        if not B:
            B.append(("FIELD", "UNATTRIBUTED", "dark for no attributed reason -- BUG"))
        return B

    # ---- the FIELDS.  These are counted on TOP of any family blocker: a
    # delay-DRAM word still needs its SRC/ACTION to be executed, and the R1
    # solve reads exactly those fields on exactly those words. -------------
    if lo & 0x800:
        B.append(("FIELD", "LO11",
                  "lo12 bit 11 set on a datapath class -- modifier unmodelled"))
    if D.lo_ptrmode(w):
        B.append(("FIELD", "PTRMODE",
                  "lo12 bit 5 (pointer/cursor mode) set -- unmodelled"))
    if D.lo_src(w) not in D._ANCHORED_SRC:
        B.append(("FIELD", "SRC-%02X" % D.lo_src(w),
                  "SRC code 0x%02X unanchored" % D.lo_src(w)))
    if D.lo_act(w) not in D._ANCHORED_ACT:
        B.append(("FIELD", "ACT-%02X" % D.lo_act(w),
                  "ACTION code 0x%02X unanchored" % D.lo_act(w)))
    f = D.hi_f31(hi)
    if not (f in (D.HI_ACC_LOAD, D.HI_ACC_ADD) or (f == D.HI_ACC_HOLD and cl == 8)):
        B.append(("FIELD", "HI31-%d" % f,
                  "hi12[3:1] operation %d unproven%s"
                  % (f, " off class 8" if f == D.HI_ACC_HOLD else "")))
    if (hi & D.HI_ST) and (cl & 7) != 2:
        B.append(("FIELD", "ST-OFFMODE2",
                  "hi12 bit-4 store on a class whose store target is unproven"))
    if D.lo_act(w) == D.LO_ACT_ST_BUS and (cl & 7) != 2:
        B.append(("FIELD", "ACT07-OFFMODE2",
                  "ACTION 0x07 destination off mode 2 unproven"))
    if (hi & D.HI_ST) and (hi & D.HI_B7):
        g = D.hi_f31(hi)
        if not (g in (1, 2) and not (g == 1 and D.lo_act(w) != D.LO_ACT_ACC_BUS)):
            B.append(("FIELD", "B7GATE",
                      "bit-7 store gate: the three surviving gates disagree here"))
    if not B:
        B.append(("FIELD", "UNATTRIBUTED", "dark for no attributed reason -- BUG"))
    return B


def blocker_keys(w):
    return tuple(sorted(k for _t, k, _x in blockers(w)))


# --------------------------------------------------------------------------
#  reporting
# --------------------------------------------------------------------------
def cmd_frame(F):
    c = collections.Counter(klass(w) for _n, _a, w, _r in F)
    print("cold-boot frame: %d slots = %d DECODED + %d PARTIAL + %d TRAP"
          % (len(F), c["DECODED"], c["PARTIAL"], c["TRAP"]))
    print()
    print("  %-34s %5s %8s %8s %6s" % ("region", "slots", "DECODED", "PARTIAL", "TRAP"))
    for r in dict.fromkeys(r for _n, _a, _w, r in F):
        sub = [w for _n, _a, w, rr in F if rr == r]
        cc = collections.Counter(klass(w) for w in sub)
        print("  %-34s %5d %8d %8d %6d"
              % (r, len(sub), cc["DECODED"], cc["PARTIAL"], cc["TRAP"]))
    print()
    dark = [(n, a, w, r) for n, a, w, r in F if klass(w) == "TRAP"]
    print("  ★ STRUCTURE OF THE DARK SET (this is not a residue, it is a region):")
    print("     class4 of the %d dark slots : %s"
          % (len(dark),
             dict(sorted(collections.Counter(D.class4(w) for _n, _a, w, _r in dark).items()))))
    print("     ...of which C-format       : %d"
          % sum(1 for _n, _a, w, _r in dark if D.c_format(w)))
    print("     has_addressing() on a dark word: %d  (must be 0 by construction)"
          % sum(1 for _n, _a, w, _r in dark if D.has_addressing(w)))
    print("     PARTIAL slots by class4    : %s"
          % dict(sorted(collections.Counter(
              D.class4(w) for _n, _a, w, _r in F if klass(w) == "PARTIAL").items())))
    print("     DECODED slots by class4    : %s"
          % dict(sorted(collections.Counter(
              D.class4(w) for _n, _a, w, _r in F if klass(w) == "DECODED").items())))


def cmd_enumerate(F, md=False):
    dark = [(n, a, w, r) for n, a, w, r in F if klass(w) == "TRAP"]
    if md:
        print("| slot | I-RAM | word | fields | region | blockers |")
        print("|---:|---:|---|---|---|---|")
    else:
        print("%5s %5s  %-11s  %-18s %-34s %s"
              % ("slot", "I-RAM", "word", "fields", "region", "blockers"))
    for n, a, w, r in dark:
        ks = ",".join(blocker_keys(w))
        if md:
            print("| %d | %d | `%010X` | `%s` | %s | `%s` |"
                  % (n, a, w, fmt(w), r.split("(")[0].strip(), ks))
        else:
            print("%5d %5d  %010X  %-18s %-34s %s" % (n, a, w, fmt(w), r, ks))
    print()
    print("  %d dark slots, %d distinct words, %d distinct families"
          % (len(dark), len({w for _n, _a, w, _r in dark}),
             len({fam(w) for _n, _a, w, _r in dark})))


def cmd_groups(F):
    dark = [(n, a, w, r) for n, a, w, r in F if klass(w) == "TRAP"]
    print("=" * 78)
    print("DARK WORDS GROUPED BY BLOCKER SET  (a set = ALL of it must be resolved)")
    print("=" * 78)
    g = collections.defaultdict(list)
    for n, a, w, r in dark:
        g[blocker_keys(w)].append((n, a, w, r))
    rows = sorted(g.items(), key=lambda kv: (-len(kv[1]), kv[0]))
    print("  %-42s %5s %5s %5s  %s"
          % ("blocker set", "slots", "words", "unkn", "example"))
    for ks, items in rows:
        print("  %-42s %5d %5d %5d  %s"
              % (",".join(ks), len(items), len({w for _n, _a, w, _r in items}),
                 len(ks), fmt(items[0][2])))
    print()
    print("BY SINGLE BLOCKER (reach -- how many dark slots mention it at all):")
    reach = collections.Counter()
    for _n, _a, w, _r in dark:
        for k in blocker_keys(w):
            reach[k] += 1
    for k, v in reach.most_common():
        print("  %-24s reach %3d" % (k, v))


def cmd_leverage(F):
    """★ THE RANKING METRIC.  Slots recovered PER UNKNOWN RESOLVED, not raw
    frequency.  A blocker that appears on 30 slots but always beside a second
    blocker recovers NOTHING on its own; a blocker that is the sole obstruction
    on 9 slots recovers 9."""
    dark = [(n, a, w, r) for n, a, w, r in F if klass(w) == "TRAP"]
    sets = [blocker_keys(w) for _n, _a, w, _r in dark]

    print("=" * 78)
    print("RANK 1 -- SOLE-BLOCKER LEVERAGE (resolve U alone, count what unblocks)")
    print("=" * 78)
    sole = collections.Counter()
    for ks in sets:
        if len(ks) == 1:
            sole[ks[0]] += 1
    reach = collections.Counter(k for ks in sets for k in ks)
    print("  %-24s %6s %6s %8s" % ("unknown", "sole", "reach", "sole/1"))
    for k, v in sole.most_common():
        print("  %-24s %6d %6d %8.1f" % (k, v, reach[k], float(v)))
    for k in sorted(set(reach) - set(sole)):
        print("  %-24s %6d %6d %8.1f   (never sole)" % (k, 0, reach[k], 0.0))

    print()
    print("=" * 78)
    print("RANK 2 -- BEST BUNDLES: resolve a SET of k unknowns, slots/k")
    print("=" * 78)
    universe = sorted(set(reach))
    best = []
    # every blocker set that actually occurs is a candidate bundle, and so is
    # every union of two of them -- beyond that the marginal return collapses
    # because the sets are nearly disjoint (printed below).
    cands = {frozenset(s) for s in sets}
    cands |= {frozenset(a) | frozenset(b) for a in cands for b in cands}
    for c in cands:
        if not c or len(c) > 4:
            continue
        got = sum(1 for ks in sets if set(ks) <= c)
        best.append((got / float(len(c)), got, len(c), sorted(c)))
    best.sort(key=lambda t: (-t[0], -t[1], t[2]))
    print("  %8s %6s %5s  %s" % ("slots/unk", "slots", "unkn", "bundle"))
    seen = set()
    for lev, got, k, c in best:
        key = tuple(c)
        if key in seen:
            continue
        seen.add(key)
        print("  %8.2f %6d %5d  %s" % (lev, got, k, ",".join(c)))
        if len(seen) >= 18:
            break
    print()
    print("=" * 78)
    print("RANK 3 -- EFFORT-GRADED: slots per DISCOVERY (MODEL unknowns are")
    print("          engineering -- a named register the executor lacks -- so")
    print("          they are counted as work, not as things to find out)")
    print("=" * 78)
    best3 = []
    for c in cands:
        if not c or len(c) > 4:
            continue
        got = sum(1 for ks in sets if set(ks) <= c)
        disc = [k for k in c if grade(k) in ("OPEN", "DISPUTED")]
        model = [k for k in c if grade(k) == "MODEL"]
        d = max(1, len(disc))
        best3.append((got / float(d), got, len(disc), len(model), sorted(c)))
    best3.sort(key=lambda t: (-t[0], -t[1]))
    print("  %8s %6s %5s %6s  %s" % ("slots/dsc", "slots", "disc", "model", "bundle"))
    seen3 = set()
    for lev, got, nd, nm, c in best3:
        key = tuple(c)
        if key in seen3:
            continue
        seen3.add(key)
        print("  %8.2f %6d %5d %6d  %s" % (lev, got, nd, nm, ",".join(c)))
        if len(seen3) >= 10:
            break
    print()
    print("  (universe of dark-set unknowns: %d -- %d OPEN, %d DISPUTED, %d MODEL)"
          % (len(universe),
             sum(1 for k in universe if grade(k) == "OPEN"),
             sum(1 for k in universe if grade(k) == "DISPUTED"),
             sum(1 for k in universe if grade(k) == "MODEL")))
    print()
    print("  SENSITIVITY OF THE METRIC TO THE C-FORMAT GRANULARITY.  `C-DEST-xxx'")
    print("  keys the destination on lo12 alone.  hi12[7:0] also varies across")
    print("  those words and MIGHT be part of the destination; if it is, each")
    print("  key splits and the leverage falls:")
    cs = collections.Counter()
    for _n, _a, w, _r in dark:
        if D.c_format(w):
            cs[(D.hi12(w) & 0xFF, D.lo12(w))] += 1
    byLo = collections.Counter()
    for (h, lo), v in cs.items():
        byLo[lo] += v
    print("    keyed on lo12 only : %d unknowns, best %d slots"
          % (len(byLo), max(byLo.values())))
    print("    keyed on hi8+lo12  : %d unknowns, best %d slots"
          % (len(cs), max(cs.values())))
    for (h, lo), v in sorted(cs.items(), key=lambda kv: -kv[1]):
        print("      C%02X ... %03X   x%d" % (h, lo, v))


# --------------------------------------------------------------------------
#  ★ CRITICAL PATH -- which dark word actually ABORTS the frame, and which is
#  merely unexecuted.
#
#  Under the shipping `clean' predicate every trap AND every partial discards
#  the frame, so "which one aborts it" is trivially "all of them" and that
#  answer is worthless.  The useful question is the DATA-FLOW one:
#
#      does anything that DOES execute consume a value this word would have
#      produced -- and, at the end, does anything reach the output at all?
#
#  This is a taint walk over one frame, entered CLEAN (which is optimistic: the
#  real machine enters a frame with the previous frame's contamination), so the
#  contaminated counts below are LOWER BOUNDS.
# --------------------------------------------------------------------------
STATE = ("acc", "p", "ta", "tb", "mem")


def taint_walk(F, taint_dark=True, taint_partial=True, dark_anchored_only=True):
    """-> (events, tainted_decoded, n_decoded)

    A dark word is SKIPPED, so everything it would have written is left stale.
    What it would have written is family-dependent and mostly OPEN -- except for
    one thing that is NOT open and that is the whole point of this walk: many
    dark words carry an ANCHORED ACTION code, and an anchored ACTION names its
    destination whatever the rest of the word means.  `880.1.60.2D4' is
    ACTION 0x14 = tempB <- bus, so skipping it leaves tempB stale, and tempB is
    read by DECODED words.  With `dark_anchored_only' False the dark word taints
    every register instead, which is the upper bound.

    Entered CLEAN, which is optimistic: the real machine enters a frame with the
    previous frame's contamination.  Every number below is a LOWER BOUND.
    """
    t = {k: False for k in STATE}
    events = []
    n_bad = 0
    n_decoded = 0
    first_bad = None
    for n, a, w, r in F:
        c = klass(w)
        if c == "TRAP":
            if not taint_dark:
                continue
            if dark_anchored_only:
                # ONLY where lo12 is a route: on a C-format word lo12 is the
                # immediate's DESTINATION and on a register-load word it is a
                # SELECTOR, so reading an ACTION out of either is a category
                # error -- the same one that made `C00.A.47.407' execute as a
                # class-A multiply for months.
                if not lo12_is_route(w):
                    continue
                act = D.lo_act(w)
                hit = []
                if act in (D.LO_ACT_CAP_TA, D.LO_ACT_CAP_TA2):
                    t["ta"] = True; hit.append("ta")
                if act == D.LO_ACT_CAP_TB:
                    t["tb"] = True; hit.append("tb")
                if act == D.LO_ACT_ST_BUS and (D.class4(w) & 7) == 2:
                    t["mem"] = True; hit.append("mem")
                if act == D.LO_ACT_ACC_BUS:
                    t["acc"] = True; hit.append("acc")
                if hit:
                    events.append((n, a, w, "DARK taints " + ",".join(hit)))
            else:
                for k in STATE:
                    t[k] = True
                events.append((n, a, w, "DARK taints ALL"))
            continue
        if c == "PARTIAL":
            if not taint_partial:
                continue
            # addressing executed, arithmetic not: acc / p / ta / tb are left
            # stale exactly where the real word would have written them.
            if D.class4(w) in (2, 8, 0xA):
                t["acc"] = True
                if D.class4(w) == 0xA:
                    t["p"] = True
                events.append((n, a, w, "PARTIAL taints acc"))
            continue
        n_decoded += 1
        # ---- a DECODED word: what does it READ? ---------------------------
        reads = set()
        if not D.c_format(w) and D.class4(w) in (2, 8, 0xA):
            src = D.lo_src(w)
            if src == D.LO_SRC_ACC:  reads.add("acc")
            if src == D.LO_SRC_TA:   reads.add("ta")
            if src == D.LO_SRC_TB:   reads.add("tb")
            if src == D.LO_SRC_MEM:  reads.add("mem")
            f = D.hi_f31(D.hi12(w))
            if D.lo_act(w) != D.LO_ACT_ACC_BUS and f != D.HI_ACC_LOAD:
                reads.add("acc")            # the adder's feedback input
            if f != D.HI_ACC_HOLD:
                reads.add("p")
        dirty = sorted(k for k in reads if t[k])
        if dirty:
            n_bad += 1
            if first_bad is None:
                first_bad = n
            events.append((n, a, w, "READS TAINTED %s" % ",".join(dirty)))
        # ---- and what does it WRITE (i.e. what does it HEAL)? --------------
        if not D.c_format(w) and D.class4(w) in (2, 8, 0xA):
            f = D.hi_f31(D.hi12(w))
            act = D.lo_act(w)
            clean_in = not dirty
            if D.hi12(w) & D.HI_ST and not D.st_suppressed(w):
                t["acc"] = False             # store-and-CLEAR: acc := 0
                t["mem"] = not clean_in
            if act == D.LO_ACT_ACC_BUS or f == D.HI_ACC_LOAD:
                t["acc"] = not clean_in      # the feedback input is bypassed
            if D.class4(w) == 0xA:
                t["p"] = not clean_in
            if act in (D.LO_ACT_CAP_TA, D.LO_ACT_CAP_TA2):
                t["ta"] = not clean_in
            if act == D.LO_ACT_CAP_TB:
                t["tb"] = not clean_in
            if act == D.LO_ACT_ST_BUS:
                t["mem"] = not clean_in
    return events, n_bad, n_decoded, first_bad


def cmd_critical(F):
    dark = [(n, a, w, r) for n, a, w, r in F if klass(w) == "TRAP"]
    print("=" * 78)
    print("CRITICAL PATH -- ABORTS THE FRAME vs MERELY UNEXECUTED")
    print("=" * 78)
    first = dark[0]
    print("  first dark slot        : %d (I-RAM %d, %s)" % (first[0], first[1], fmt(first[2])))
    firstany = next(n for n, _a, w, _r in F if klass(w) != "DECODED")
    print("  first non-DECODED slot : %d  -- a PARTIAL, so no dark word is ever"
          % firstany)
    print("                           the first thing that spoils the frame.")
    print()
    print("  Under the shipping `clean' test all 177 undecoded slots abort the")
    print("  frame equally, so `which one aborts it' does not discriminate.")
    print("  These three do.")
    print()
    print("-- (a) OUTPUT REACHABILITY -- the chip's only two exits ------------")
    epi = [(n, a, w) for n, a, w, r in F if r.startswith("epilogue")]
    NOTE = {73: "PRESENT unit 0 -> DO1 -> IC303.SDIA (SRC 0x10 = acc)",
            78: "PRESENT unit 1 -> DO2 -> IC303.SDIB (SRC 0x0A, ACT 0x07)",
            72: "unit-0 OUTPUT LEVEL register 0x06 -- immediately before w73",
            77: "unit-1 OUTPUT LEVEL register 0x86 -- immediately before w78",
            76: "C00 self-addressing word (A = 76 = its own I-RAM address)",
            74: "C-format companion, A = 77 = points at w77",
            63: "reads the unit-0 body ENTRY/SEND cell 0x05",
            70: "read/write pair with w63, register 0x85"}
    for n, a, w in epi:
        print("     I-RAM %2d slot %3d  %-13s %-8s %s"
              % (a, n, fmt(w), klass(w), NOTE.get(a, "")))
    print()
    print("     ★ BOTH presentations are PARTIAL; BOTH per-unit LEVEL words that")
    print("       immediately precede them are DARK.  So the two words that")
    print("       actually gate audio out of IC311 are dark, and they are 2 of 86.")
    print()
    print("-- (b) MARGINAL CONTAMINATION -- whose fault is the wrong arithmetic? -")
    for lbl, kw in (("neither", dict(taint_dark=False, taint_partial=False)),
                    ("dark only (anchored ACTION)", dict(taint_partial=False)),
                    ("dark only (upper bound)",
                     dict(taint_partial=False, dark_anchored_only=False)),
                    ("partial only", dict(taint_dark=False)),
                    ("both", dict())):
        _ev, bad, dec, fb = taint_walk(F, **kw)
        print("     %-28s : %3d of %d DECODED slots read tainted state; first at "
              "slot %s" % (lbl, bad, dec, "-" if fb is None else str(fb)))
    ev, _bad, _dec, _fb = taint_walk(F, taint_partial=False)
    print()
    print("     the dark words that taint on their own (anchored ACTION only):")
    seen = set()
    for n, a, w, why in ev:
        if why.startswith("DARK") and w not in seen:
            seen.add(w)
            print("       %s  %-13s %s" % (fmt(w), "ACT 0x%02X" % D.lo_act(w), why))
    print()
    print("-- (c) CROSS-FRAME: the delay line is written only by dark words ----")
    rd = [w for _n, _a, w, _r in dark if D.is_dram(w) and D.lo_src(w) == 0x0B]
    wr = [w for _n, _a, w, _r in dark if D.is_dram(w) and D.lo_src(w) != 0x0B]
    print("     delay-DRAM words in the frame: %d  (SRC 0x0B = %d, other = %d)"
          % (len(rd) + len(wr), len(rd), len(wr)))
    print("     ALL of them are dark, so the external delay DRAM is never read")
    print("     and never written.  A reverb whose line is never written cannot")
    print("     produce a tail even with a perfect interior -- this is the one")
    print("     failure the frame CANNOT recover from by decoding the ALU alone.")


# --------------------------------------------------------------------------
#  H-DIR -- a testable direction rule for the delay-DRAM family, offered
#  because the DRAM group is rank 1 and DIRECTION is one of its two unknowns.
# --------------------------------------------------------------------------
DIR_ESTABLISHED = [
    ((0x60, 0x2D4), "READ",  "R1 F1: read_slot enumerated over {0,4}; slot 0 in "
                             "36 of 36 surviving machines, the swap has ZERO"),
    ((0x20, 0x655), "WRITE", "R1 F1, same search, same forcing"),
    ((0x20, 0x2C7), "READ",  "R3 sect. 6.3: MULTI TAP DELAY's descriptor cells "
                             "0x26/0x28/0x29/0x2A align three tap READS here"),
    ((0x60, 0x000), "WRITE", "R3 sect. 6.3: the word landing on the line base "
                             "cell 0x2C = 0, i.e. the write pointer"),
]


def cmd_dirtest(corpus):
    print("=" * 78)
    print("H-DIR  --  `the delay-DRAM DIRECTION is the anchored-ish SRC field'")
    print("=" * 78)
    print("  H-DIR   : SRC == 0x0B (the delay-RAM read register) <=> the word is")
    print("            a delay-line READ.  Every other SRC is a WRITE source.")
    print("  H-ADDR8 : addr8 == 0x60 <=> READ.  (Already FALSIFIED by R3 6.3 --")
    print("            it is the null hypothesis this is measured against.)")
    print()
    print("  NON-CIRCULARITY: both established assignments were reached WITHOUT")
    print("  reading SRC.  R1 enumerated the read SLOT (r1_allpass_solve.py line")
    print("  250: `for read_slot in (0, 4)') and forced it numerically; R3 6.3")
    print("  aligned descriptor CELLS against program order.  Neither consults")
    print("  lo12[10:6].")
    print()
    print("  %-14s %-6s %-6s %-6s %s" % ("word", "SRC", "H-DIR", "addr8", "established"))
    hd = ha = 0
    for (ad, lo), truth, why in DIR_ESTABLISHED:
        src = (lo >> 6) & 0x1F
        p1 = "READ" if src == 0x0B else "WRITE"
        p2 = "READ" if ad == 0x60 else "WRITE"
        hd += p1 == truth
        ha += p2 == truth
        print("  880.1.%02X.%03X  %02X     %-6s %-6s %-6s  %s"
              % (ad, lo, src, p1 + ("+" if p1 == truth else "!"),
                 p2 + ("+" if p2 == truth else "!"), truth, why[:34]))
    print("  H-DIR %d/4   H-ADDR8 %d/4" % (hd, ha))
    print()
    print("  ★ THE CONTROL THAT SAYS NO: H-ADDR8 is scored on the same four rows")
    print("    and FAILS two of them.  A predicate that both rules pass on all")
    print("    four would prove nothing; this one separates them 4-2.")
    print()
    cnt = collections.Counter((D.addr8(w), D.lo12(w)) for w in corpus if D.is_dram(w))
    print("  corpus consequence -- the whole delay-DRAM family under H-DIR:")
    print("  %-14s %5s %-6s %-6s %s" % ("word", "n", "SRC", "H-DIR", "SRC role"))
    for (ad, lo), v in sorted(cnt.items(), key=lambda kv: -kv[1]):
        src = (lo >> 6) & 0x1F
        role = SRC_ROLE.get(src, ("OPEN", "no reading"))
        print("  880.1.%02X.%03X  %5d  %02X     %-6s %s: %s"
              % (ad, lo, v, src, "READ" if src == 0x0B else "WRITE",
                 role[0], role[1][:44]))
    tot = sum(cnt.values())
    reads = sum(v for (ad, lo), v in cnt.items() if ((lo >> 6) & 0x1F) == 0x0B)
    print("  => %d of %d corpus delay-DRAM words are READS under H-DIR (%.1f %%)"
          % (reads, tot, 100.0 * reads / tot))
    print()
    print("  ★ WHAT IT COSTS THE OTHER TARGETS.  Four of the WRITE-side words")
    print("    carry SRC 0x00, the DISPUTED code.  If SRC 0x00 turns out to be")
    print("    the delay-RAM reading the reverb demands, H-DIR reclassifies")
    print("    880.1.60.000 (26x) / .30.000 (12x) / .30.00B (11x) / .60.00B (3x)")
    print("    -- 52 corpus words -- from WRITE to READ, and R3 6.3's line-WRITE")
    print("    identification of 880.1.60.000 becomes UNTENABLE unless the word")
    print("    is a read-modify-write.  Enumerated, not chosen:")
    print("      (i)   SRC 0x00 = mem[ptr]      -> H-DIR and R3 6.3 agree")
    print("      (ii)  SRC 0x00 = delay-RAM     -> 880.1.60.000 must be R-M-W")
    print("      (iii) direction is NOT one bit -- some words do both")


def cmd_neighbours(F):
    """What the nearest DECODED words imply about each dark word."""
    dark_idx = [i for i, (_n, _a, w, _r) in enumerate(F) if klass(w) == "TRAP"]
    print("%5s %5s %-18s | %-28s | %s"
          % ("slot", "I-RAM", "dark word", "previous DECODED", "next DECODED"))
    for i in dark_idx:
        n, a, w, r = F[i]
        prev = next((F[j] for j in range(i - 1, -1, -1) if klass(F[j][2]) == "DECODED"), None)
        nxt = next((F[j] for j in range(i + 1, len(F)) if klass(F[j][2]) == "DECODED"), None)
        def s(x):
            return "-" if x is None else "%s %s(%+d)" % (
                fmt(x[2]), D.form_of(x[2]) or "?", x[0] - n)
        print("%5d %5d %-18s | %-28s | %s" % (n, a, fmt(w), s(prev), s(nxt)))


# --------------------------------------------------------------------------
#  ★ CONTROLS.  Each must be DEMONSTRATED capable of saying NO.
# --------------------------------------------------------------------------
def cmd_control(F, live=(108, 91, 86)):
    ok = True
    print("=" * 78)
    print("CONTROLS -- each shown REJECTING something, not merely passing")
    print("=" * 78)

    # C1 -- the static reconstruction against the LIVE measurement.
    c = collections.Counter(klass(w) for _n, _a, w, _r in F)
    got = (c["DECODED"], c["PARTIAL"], c["TRAP"])
    print("C1  static frame vs live MEASURED %s: got %s -- %s"
          % (live, got, "PASS" if got == live else "FAIL"))
    ok &= got == live
    # ...and it CAN fail: feed it the wrong unit-0 body and watch it move.
    print("    proof it can say NO: rebuild the frame with unit-0 = algo 0")
    return ok


def cmd_control2(rompath, tools, live):
    """The negative half of C1 -- a DIFFERENT frame must NOT reproduce the live
    split.  Without this, C1 is a control that cannot fail."""
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(rompath)
    hdr, epi, u0, u1 = load_images(rompath, tools)
    outs = []
    for algo in (0, 2, 3):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * algo))
            alt = None
            for a, ws, _l in ir:
                if a == U0:
                    alt = [int.from_bytes(bytes(w), "big") for w in ws]
            if alt is None:
                continue
        except Exception:
            continue
        Fa = frame(hdr, epi, alt, u1)
        c = collections.Counter(klass(w) for _n, _a, w, _r in Fa)
        got = (c["DECODED"], c["PARTIAL"], c["TRAP"])
        outs.append((algo, len(Fa), got))
    for algo, n, got in outs:
        print("      unit-0 = algo %-2d : %3d slots, %s  %s"
              % (algo, n, got, "DIFFERS (good)" if got != live else "MATCHES (BAD)"))
    return all(got != live for _a, _n, got in outs)


def cmd_control3(F):
    """C2 -- the blocker attribution must be TOTAL and EXCLUSIVE, and must be
    able to reject.  Plant three words whose classification is known."""
    print()
    print("C2  blocker attribution: every dark word gets >=1 blocker, no decoded")
    print("    word gets any.")
    bad = [w for _n, _a, w, _r in F if klass(w) == "TRAP" and not blockers(w)]
    bad2 = [w for _n, _a, w, _r in F if klass(w) == "DECODED" and blockers(w)]
    unattr = [w for _n, _a, w, _r in F if "UNATTRIBUTED" in blocker_keys(w)]
    print("    dark-with-no-blocker %d, decoded-with-blocker %d, UNATTRIBUTED %d -- %s"
          % (len(bad), len(bad2), len(unattr),
             "PASS" if not (bad or bad2 or unattr) else "FAIL"))
    print("    proof it can say NO -- planted probes, each with a KNOWN answer:")
    probes = [
        (0x202A001D5, "DECODED", "-",
         "the canonical class-A mac: decoded, therefore blocker-free"),
        (0x202A001D0, "PARTIAL", "ACT-10",
         "SAME word with ACTION 0x10: it has a blocker and is STILL NOT DARK "
         "(class A advances the cursor).  Blockers != dark; this is the "
         "distinction the whole tool rests on"),
        (0x08801602D4, "TRAP", "DRAM-ADDR,DRAM-DIR,SRC-0B",
         "the real delay-DRAM read"),
        (0x0C40A80445, "DECODED", "-",
         "setvec: a C-format word that IS decoded"),
        (0x0C40A80444, "TRAP", "C-DEST-444",
         "the SAME C-format word one destination code away: dark on the "
         "destination alone, and NOT on a SRC/ACTION it does not have"),
    ]
    good = True
    for w, kexp, bexp, why in probes:
        k = klass(w)
        b = ",".join(blocker_keys(w)) or "-"
        hit = (k == kexp and b == bexp)
        good &= hit
        print("      %010X %-14s %-8s %-26s %s" % (w, fmt(w), k, b,
                                                   "OK" if hit else "MISMATCH"))
        print("        expect %-8s %-26s  %s" % (kexp, bexp, why))
    print("    probes: %s" % ("ALL AS EXPECTED" if good else "FAILURE"))
    return not (bad or bad2 or unattr) and good


def cmd_control4(F):
    """C3 -- the leverage metric must RANK DIFFERENTLY from raw frequency,
    otherwise it is not a metric, it is a relabelling."""
    dark = [w for _n, _a, w, _r in F if klass(w) == "TRAP"]
    sets = [blocker_keys(w) for w in dark]
    reach = collections.Counter(k for ks in sets for k in ks)
    sole = collections.Counter(ks[0] for ks in sets if len(ks) == 1)
    by_reach = [k for k, _v in reach.most_common()]
    by_sole = [k for k, _v in sole.most_common()] + \
              sorted(set(reach) - set(sole))
    print()
    print("C3  leverage vs raw frequency: the two orders must DIFFER")
    print("    by reach : %s" % ", ".join(by_reach[:6]))
    print("    by sole  : %s" % ", ".join(by_sole[:6]))
    diff = by_reach[:6] != by_sole[:6]
    disagree = [k for k in reach if reach[k] and not sole.get(k)]
    print("    orders differ: %s;  %d unknowns have reach>0 but sole==0 "
          "(frequency would rank them, leverage does not)"
          % (diff, len(disagree)))
    return diff


def cmd_cformat(F, corpus):
    """The C-format immediate, and the control that had to be withdrawn."""
    print("=" * 78)
    print("THE C-FORMAT IMMEDIATE  --  imm13 = A*32 + B")
    print("=" * 78)
    print("  ★ A CONTROL THAT CANNOT FAIL, WITHDRAWN.  `if A is an I-RAM address")
    print("    then A < 384' -- imm13 is 13 bits, so A is 8 bits and CANNOT reach")
    print("    384 whatever the truth is.  It would have passed unconditionally.")
    print("    The replacement is scored against the I-RAM range actually in")
    print("    use, and it CAN fail: an 8-bit A expresses 0..255, so any of the")
    print("    68 could have named a body word in 84..255.  None does.")
    print()
    cf = [w for w in corpus if D.c_format(w)]
    A = [D.c_imm13(w) >> 5 for w in cf]
    print("  %d ROM C-format words: A spans %d..%d ; A >= 84 (a body address): %d"
          % (len(cf), min(A), max(A), sum(1 for x in A if x >= 84)))
    print("  imm13 spans %d..%d" % (min(D.c_imm13(w) for w in cf),
                                    max(D.c_imm13(w) for w in cf)))
    print("  A histogram: %s" % dict(sorted(collections.Counter(A).items())))
    print()
    print("  the two words with A >= 84 are HOST-WRITTEN, not in the ROM:")
    for w in (0xC40A80445, 0xC41900446):
        print("    %010X %-14s A=%3d B=%2d   setvec (A = the body entry address)"
              % (w, fmt(w), D.c_imm13(w) >> 5, D.c_imm13(w) & 0x1F))
    print()
    print("  hi12 == 0xC00 is SELF-ADDRESSING, 2 of 2 in the machine:")
    for w in corpus:
        if D.c_format(w) and (D.hi12(w) & 0xFFF) == 0xC00:
            print("    %-14s A = %d" % (fmt(w), D.c_imm13(w) >> 5))
    print()
    print("  the dark C-format words of the frame, by destination code:")
    for n, a, w, r in F:
        if klass(w) == "TRAP" and D.c_format(w):
            print("    slot %3d I-RAM %3d  %-14s dest %03X  imm13 %5d  A %3d B %2d"
                  % (n, a, fmt(w), D.lo12(w), D.c_imm13(w),
                     D.c_imm13(w) >> 5, D.c_imm13(w) & 0x1F))


def load_corpus(rompath, toolsdir):
    """every word the machine can run: 38 distinct body images + the kernel."""
    sys.path.insert(0, toolsdir)
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(rompath)
    MALFORMED = {79, 88, 89, 90, 91}
    imgs = {}
    for i in range(N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        if ir and i not in MALFORMED:
            imgs[i] = tuple(int.from_bytes(bytes(w), "big")
                            for _a, ws, _l in ir for w in ws)
    seen = {}
    for a in sorted(imgs):
        seen.setdefault(imgs[a], a)
    hdr, epi, _u0, _u1 = load_images(rompath, toolsdir)
    return [w for k in seen for w in k] + hdr + epi


def cmd_robust(rompath, toolsdir):
    """Is the dark set a property of the COLD-BOOT PAIR or of the machine?
    Re-walk the frame with every unit-0 body the ROM has."""
    sys.path.insert(0, toolsdir)
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(rompath)
    hdr, epi, _u0, u1 = load_images(rompath, toolsdir)
    print("=" * 78)
    print("ROBUSTNESS -- the dark set over every unit-0 body in the ROM")
    print("=" * 78)
    print("  %-6s %6s %8s %8s %6s   %s"
          % ("algo", "slots", "DECODED", "PARTIAL", "TRAP", "dark blockers by reach"))
    rows = []
    seenb = set()
    for algo in range(N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * algo))
        except Exception:
            continue
        alt = None
        for a, ws, _l in ir:
            if a == U0:
                alt = [int.from_bytes(bytes(w), "big") for w in ws]
        if alt is None:
            continue
        key = tuple(alt)
        if key in seenb:
            continue
        seenb.add(key)
        Fa = frame(hdr, epi, alt, u1)
        c = collections.Counter(klass(w) for _n, _a, w, _r in Fa)
        dk = [w for _n, _a, w, _r in Fa if klass(w) == "TRAP"]
        reach = collections.Counter(k for w in dk for k in blocker_keys(w))
        rows.append((algo, len(Fa), c["DECODED"], c["PARTIAL"], c["TRAP"],
                     reach.most_common(3)))
    for algo, n, d, p, t, top in rows:
        print("  %-6d %6d %8d %8d %6d   %s"
              % (algo, n, d, p, t,
                 " ".join("%s:%d" % kv for kv in top)))
    tr = [t for _a, _n, _d, _p, t, _x in rows]
    print()
    print("  %d distinct unit-0 bodies; TRAP count spans %d..%d, mean %.1f"
          % (len(rows), min(tr), max(tr), sum(tr) / float(len(tr))))
    print("  dark fraction spans %.1f%%..%.1f%%"
          % (100.0 * min(t / float(n) for _a, n, _d, _p, t, _x in rows),
             100.0 * max(t / float(n) for _a, n, _d, _p, t, _x in rows)))


# --------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "frame", "enumerate", "groups", "leverage",
                             "critical", "neighbours", "dirtest", "robust",
                             "cformat", "control"])
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--md", action="store_true")
    args = ap.parse_args()
    if not os.path.isdir(args.tools):
        sys.exit("ERROR: need the ROM parser -- pass --tools <kn7000_mame/tools>")

    hdr, epi, u0, u1 = load_images(args.sub, args.tools)
    F = frame(hdr, epi, u0, u1)

    if args.cmd in ("all", "frame"):
        cmd_frame(F)
        print()
    if args.cmd in ("all", "enumerate"):
        cmd_enumerate(F, args.md)
        print()
    if args.cmd in ("all", "groups"):
        cmd_groups(F)
        print()
    if args.cmd in ("all", "leverage"):
        cmd_leverage(F)
        print()
    if args.cmd in ("all", "critical"):
        cmd_critical(F)
        print()
    if args.cmd in ("all", "cformat"):
        cmd_cformat(F, load_corpus(args.sub, args.tools))
        print()
    if args.cmd in ("all", "dirtest"):
        cmd_dirtest(load_corpus(args.sub, args.tools))
        print()
    if args.cmd in ("all", "robust"):
        cmd_robust(args.sub, args.tools)
        print()
    if args.cmd == "neighbours":
        cmd_neighbours(F)
    if args.cmd in ("all", "control"):
        a = cmd_control(F)
        b = cmd_control2(args.sub, args.tools, (108, 91, 86))
        c = cmd_control3(F)
        d = cmd_control4(F)
        print()
        print("CONTROLS: %s" % ("ALL PASS" if (a and b and c and d) else "FAILURE"))


if __name__ == "__main__":
    main()
