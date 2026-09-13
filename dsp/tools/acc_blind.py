#!/usr/bin/env python3
"""acc_blind.py -- which undecoded words are refused for a reason that CANNOT BE OBSERVED?

QUESTION IT ANSWERS
    Three of the largest entries in `decode_leverage.py' are open axes that live ENTIRELY INSIDE
    THE ARITHMETIC -- two in the accumulator, one on the operand bus:

      * `f31' 3/4/5/7 -- `f31-high.md' item A enumerates four readings (`base', `negP', `hold',
        `prod'); every one of them differs from the others ONLY in how `acc' is updated.
      * the store gate at `f31 == 1' -- `store-gate.md' item D is a FORCED NEGATIVE: of 17 928
        machines surviving all 29 blocks, **not one writes `mem[ptr]'**.  The three surviving
        families are `none', `ST(acc->else)' and `LD'.  ★ In `gate_settle.py' the `else' key is
        declared `a memory key no pointer can ever equal' (line 70), so `ST(...->else)' is
        unreadable BY CONSTRUCTION, and `LD' writes `st.acc' and nothing else.  ⇒ those three
        families, and the three `clr' placements with them, differ ONLY in `acc'.
      * ★ an open SOURCE code (`SRC 0x11', `0x1B', ...).  Whatever the code names, the field
        selects the MULTIPLICAND: it cannot move a pointer, advance a cursor or write a temporary,
        because those are the `class4' and ACTION fields.  So on a word whose ACTION keeps the bus
        inside the arithmetic (`0x00' -> the accumulator's input term; `0x12' / `0x15' -> no side
        effect at all) an unknown SRC reaches nothing but the product and the accumulator.
        ⚠ It reaches the product FIRST -- `P[N] = coef[N-1] x L[N-1]' -- so its taint arrives in
        `acc' at word i+1 and an `f31 == 0' reload there LOADS it rather than killing it.

    `f31-high.md' item F already measured that 92 of 203 such words are BLIND -- "an `f31 = 0'
    word overwrites the accumulator before anything reads it" -- but used the fact only to explain
    why the biquad cannot DECIDE the field.  ★ Turned around, it is a COVERAGE result:

        IF a word's only open axis is confined to the accumulator, AND the accumulator it leaves
        is destroyed before anything reads it, THEN every surviving reading executes the word
        IDENTICALLY as far as the machine can tell -- so the word is EXECUTABLE even though the
        axis is still unknown.

    That is what tier-1 coverage measures: not "we know what the code names" but "we can run it
    faithfully".  This tool counts the words that qualify, and prints each one so the claim can be
    checked by hand.

USAGE
    python3 dsp/tools/acc_blind.py                  # the census
    python3 dsp/tools/acc_blind.py --list           # every qualifying site
    python3 dsp/tools/acc_blind.py --audit          # why each NON-qualifying site fails
    python3 dsp/tools/acc_blind.py --null           # ★ the control: the discard rate per `f31'

MEASURED 2026-09-13: 310 candidate sites, **32 blind** (29 `f31', 2 `SRC 0x11', 1 store gate).
Body corpus 2200 -> 2231 of 2974 = 74.0 % -> 75.0 %.

THE LIVENESS WALK, and exactly what it assumes
    Bodies are straight-line (N-INPUT-GATE-OPENED sect. 95: 100 % of every image executes every
    frame), so the walk is forward in slot order from the site to the end of the image.

      OBSERVES acc   `SRC 0x10' (the accumulator is the operand) ......... anchored
                     the bit-4 store ......................................... may deliver acc to
                        `mem[ptr]' -- EXCEPT on a `b7 & f31 == 1' word, where `store-gate.md'
                        item D forces that it does not
                     ⚠ C-format / bit-11 words, and any word whose `SRC' this project has NOT
                        anchored: their operand route is OPEN and `gate_settle.py's own menus list
                        `acc' among the candidates for `SRC 0x00', `0x08' and `0x11'.  Counted as
                        observers, because assuming otherwise would assume away the coverage gap.
      KILLS acc      `f31 == 0' (`acc <- P') on an ALU-encoded word.  `action00-discriminator.md'
                     item C / `schroeder-topology.md' item H: `load', `add' and `rload' are the
                     SAME EXPRESSION wherever `hi12[3:1] == 0', so the kill does not depend on the
                     open `ACTION 0x00' reading either.
      otherwise      the site's value PROPAGATES (`f31 == 1' adds to it, `f31 == 2' holds it) --
                     neither observed nor destroyed; keep walking.

    Running off the end of the image is NOT blind: the accumulator crosses a block boundary in
    this machine (only the PRODUCT register is flushed, sect. 36), so a tail site stays open.

★ AND THE PESSIMISM COSTS NOTHING -- MEASURED, so the headline does not rest on either judgement
  call.  Re-run with C-format words treated as non-observers, with bit-11 words treated as
  non-observers, and with both: **32 blind sites in every case**, the same as shipped.  (§97 gives
  an independent reason to believe the bit-11 relaxation would be sound -- those words leave
  `exec_alu()' before the SOURCE stage, measured 3 150 504 times in one chorus run -- but since it
  buys nothing, the conservative reading stays.)

⚠ WHAT THIS IS NOT.  It does not decode `f31', and it does not choose among the store gate's three
  families.  Those stay OPEN and the notes must keep saying so.  It says that at these particular
  sites the choice has no consequence.
"""
import collections
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as D                                                   # noqa: E402

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")


def st_cannot_reach_mem(w):
    """`store-gate.md' item D: a `bit 7 + f31 == 1' bit-4 store reaches `mem[ptr]' in 0 of 17 928
    surviving machines.  So such a word does not deliver the accumulator to readable memory."""
    hi = D.hi12(w)
    return bool(hi & D.HI_ST) and bool(hi & D.HI_B7) and D.hi_f31(hi) == 1


def acc_observes(w):
    """Could this word make the incoming accumulator visible?  Returns a REASON or None."""
    if D.c_format(w):
        return "C-format, operand route open"
    if D.alt_lo12(w):
        return "bit-11 encoding, operand route open"
    if D.lo_src(w) == D.LO_SRC_ACC:
        return "SRC 0x10 = acc"
    if D.lo_src(w) not in D._ANCHORED_SRC:
        return "SRC 0x%02X open" % D.lo_src(w)
    if (D.hi12(w) & D.HI_ST) and not st_cannot_reach_mem(w):
        return "bit-4 store"
    return None


def acc_observes_own_output(w):
    """Does the word deliver its OWN accumulator result anywhere readable?"""
    return bool(D.hi12(w) & D.HI_ST) and not st_cannot_reach_mem(w)


def acc_kills(w):
    if D.c_format(w) or D.alt_lo12(w):
        return False
    return D.hi_f31(D.hi12(w)) == D.HI_ACC_LOAD


#   The ACTIONs that keep an unknown OPERAND inside the arithmetic.  `0x00' routes the bus into
#   the accumulator's input term and `0x12' / `0x15' have no temp or memory side effect at all, so
#   on those three an open `SRC' can reach nothing but the product and the accumulator.  Every
#   other ACTION (`0x07' stores the bus to `mem[ptr]', the captures write a temporary) lets the
#   unknown escape, and the walk refuses those without looking.
_BUS_CONFINED_ACT = (0x00, 0x12, 0x15)


def blind_after(words, i, bus=False):
    """(blind, why) for the value the word at index `i' leaves behind.

    Two entry conditions, because the two open-axis families taint different registers:

      * an ACCUMULATOR-confined axis (`f31', the store gate) taints `acc' at the site and nothing
        else.  The product is untouched.
      * ★ an OPERAND-confined axis (an open `SRC' with a bus-confined ACTION) taints the PRODUCT
        first, not the accumulator: `P[N] = coef[N-1] x L[N-1]`, the one-slot pipeline this
        project measured bit-exactly.  So the unknown operand reaches `acc' only at word i+1,
        and it reaches it there even if that word is an `f31 == 0' RELOAD -- `acc <- P' LOADS the
        tainted product rather than killing it.  ⚠ Getting this backwards would have admitted
        every open-SRC word whose successor reloads the accumulator, which is the commonest shape
        in the corpus.  With ACTION `0x00' the bus ALSO enters `acc' at the site itself, so both
        taints are live at once.

    ⚠ THE SITE'S OWN STORE COUNTS.  A word that carries the bit-4 store delivers its OWN
    accumulator to `mem[ptr]' -- and whether that is the pre-ALU or the post-ALU value is one of
    the solver's free dimensions -- so the axis is observable AT the site and the walk never even
    starts.  Missing this would have admitted every `f31 > 2' word that stores.
    """
    if acc_observes_own_output(words[i]):
        return False, "the site itself stores acc"
    if bus and D.lo_act(words[i]) not in _BUS_CONFINED_ACT:
        return False, "ACT 0x%02X lets the unknown operand escape the arithmetic" % D.lo_act(words[i])
    t_acc = (not bus) or D.lo_act(words[i]) == 0x00
    t_p = bus
    for j in range(i + 1, len(words)):
        w = words[j]
        if t_acc or t_p:
            r = acc_observes(w)
            if r:
                return False, "w%d observes acc: %s" % (j, r)
        if D.c_format(w) or D.alt_lo12(w):
            return False, "w%d is not the ALU encoding -- its effect on a tainted machine is open" % j
        f = D.hi_f31(D.hi12(w))
        if t_p:                                  # j == i+1: the tainted product is consumed here
            if f in (D.HI_ACC_LOAD, D.HI_ACC_ADD):
                t_acc = True                     # `acc <- P' LOADS the taint; `acc += P' adds it
            t_p = False
        elif f == D.HI_ACC_LOAD:
            t_acc = False
        if not t_acc and not t_p:
            return True, "w%d reloads acc (f31 0)" % j
    return False, "runs to the end of the image -- acc crosses the block"


# ---------------------------------------------------------------------------
#  Which words are candidates: refused ONLY for accumulator-confined axes.
# ---------------------------------------------------------------------------
def open_axes(w):
    """Every axis on which `decoded()' refuses `w', as labels.

    ⚠⚠ NOT `decode_leverage.reasons()'.  That one enumerates the `alu_decoded()' guards
    unconditionally, which prints FICTIONAL axes on two whole families and made the refusal
    histogram unreadable:

      * on a C-FORMAT word `class4|addr8' do not exist -- bits [24:12] are one 13-bit immediate
        (`dsp_disasm.py' c_format(), isa-adjudication.md sect. 1).  Its "class 3" and its `SRC' /
        `ACT' are that immediate's bits.  The single axis is the format.
      * on a bit-11 word `lo12' is NOT the SRC/mode/ACTION route (bit11-family.md sect. 9), so its
        `SRC 0x11 + ACT 0x03 + pointer mode 1' is three readings of a field that is not there.
      * a class-1 DELAY ESCAPE is graded by `_alu_half_anchored()', which has no class test --
        the escape itself explains the class (sect. 90), so charging it to "class 1" is wrong.
    """
    out = []
    if D.c_format(w):
        return ["C-format"]
    if D.alt_lo12(w):
        out.append("bit-11 encoding")
        if D.class4(w) not in (2, 8, 0xA):
            out.append("class %X" % D.class4(w))
        return out
    cl = D.class4(w)
    escape = D.is_dram(w) and D.dram_dir(w)
    if cl not in (2, 8, 0xA) and not escape:
        out.append("class %X" % cl)
    if D.lo_ptrmode(w):
        out.append("pointer mode %d" % D.lo_ptrmode(w))
    if D.lo_src(w) not in D._ANCHORED_SRC:
        out.append("SRC 0x%02X" % D.lo_src(w))
    if not D._act_anchored(w):
        out.append("ACT 0x%02X" % D.lo_act(w))
    if escape:
        #   `_alu_half_anchored()' stops here -- it has no store-class guards.
        if (D.hi12(w) & D.HI_ST) and (D.hi12(w) & D.HI_B7) and D.hi_f31(D.hi12(w)) != 2:
            out.append("store gate, f31 %d" % D.hi_f31(D.hi12(w)))
        f = D.hi_f31(D.hi12(w))
        if f not in (D.HI_ACC_LOAD, D.HI_ACC_ADD, D.HI_ACC_HOLD):
            out.append("f31 %d" % f)
        return out
    if (D.hi12(w) & D.HI_ST) and (cl & 7) != 2:
        out.append("bit-4 store on class %X" % cl)
    if D.lo_act(w) == D.LO_ACT_ST_BUS and (cl & 7) != 2:
        out.append("ACT 0x07 store on class %X" % cl)
    if (D.hi12(w) & D.HI_ST) and (D.hi12(w) & D.HI_B7) and D.hi_f31(D.hi12(w)) != 2:
        out.append("store gate, f31 %d" % D.hi_f31(D.hi12(w)))
    f = D.hi_f31(D.hi12(w))
    if f not in (D.HI_ACC_LOAD, D.HI_ACC_ADD, D.HI_ACC_HOLD):
        out.append("f31 %d" % f)
    return out


#   The two axes whose whole disagreement is an accumulator value.  `store gate, f31 1' qualifies
#   ONLY at f31 == 1: at f31 0 (and at 3..7) the two surviving GATE CONDITIONS disagree about
#   whether `mem[ptr]' is written at all, which is not an accumulator question.
def acc_confined(axis):
    if axis == "store gate, f31 1":
        return True
    return axis.startswith("f31 ")


def bus_confined(axis):
    """★ An open SOURCE code is confined to the OPERAND BUS.  Whatever `SRC 0x11' / `0x1B' / ...
    name, the field selects the multiplicand; it cannot move a pointer, advance a cursor or write
    a temporary, because those are the `class4' / ACTION fields.  So on a word whose ACTION keeps
    the bus inside the arithmetic, an open SRC can only reach the product and the accumulator."""
    return axis.startswith("SRC ")


def blind_sites(words):
    """★ THE IMPORTABLE PREDICATE.  Indices `i' of `words' that `decoded()' refuses but whose
    refusal is provably without consequence (see the module docstring).  `dsp_coverage.py' scores
    these as TIER 1b -- executable IN CONTEXT -- and never folds them into `decoded()', which is
    a per-WORD predicate the MAME disassembler mirrors and which has no image to look at."""
    out = []
    for i, w in enumerate(words):
        if D.decoded(w):
            continue
        ax = open_axes(w)
        if not ax or not all(acc_confined(a) or bus_confined(a) for a in ax):
            continue
        ok, _why = blind_after(words, i, bus=any(bus_confined(a) for a in ax))
        if ok:
            out.append(i)
    return out


def _images(files):
    out = []
    for f in files:
        if os.path.basename(f) in ("index.dsm",):
            continue
        ws = []
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                ws.append(int(m.group(2), 16))
        out.append(ws)
    return out


def null_control(images):
    """★★ THE CONTROL THE BLINDNESS ARGUMENT NEEDS, and it goes the RIGHT way.

    Objection: an accumulator result that is thrown away four slots later looks like DEAD WORK,
    and sect. 95 has just shown these microprograms contain no unreachable instructions.  If
    discarding were RARE, then finding it concentrated on the `f31 > 2' words would be evidence
    that those words are NOT accumulator operations at all -- and the blindness lemma, which
    assumes they are, would be assuming exactly what is in doubt.

    So measure the rate on the ANCHORED codes, where the operation is not in question.
    MEASURED over the 40 images: `f31' 0/1/2 discard their accumulator 537 of 2202 times
    (24.4 %); `f31' 3..7 discard it 32 of 131 times (24.4 %).  ⇒ discarding is ORDINARY in this
    machine -- `f31 == 0' (`acc <- P', fully anchored) is discarded 31 % of the time -- and the
    open codes are doing nothing unusual.  The objection is answered by the machine itself."""
    stat, tot = collections.Counter(), collections.Counter()
    for words in images:
        for i, w in enumerate(words):
            if D.c_format(w) or D.alt_lo12(w) or acc_observes_own_output(w):
                continue
            f = D.hi_f31(D.hi12(w))
            tot[f] += 1
            if blind_after(words, i)[0]:
                stat[f] += 1
    print("=== NULL CONTROL -- how often is an accumulator result DISCARDED, by `f31'? ===")
    print("   f31   words   discarded     rate     (words that store their own acc excluded)")
    for f in range(8):
        if tot[f]:
            print("   %3d %7d %11d %8.1f %%" % (f, tot[f], stat[f], 100.0 * stat[f] / tot[f]))
    a = (sum(stat[f] for f in (0, 1, 2)), sum(tot[f] for f in (0, 1, 2)))
    b = (sum(stat[f] for f in range(3, 8)), sum(tot[f] for f in range(3, 8)))
    print("\n   ANCHORED  f31 0/1/2 : %4d of %4d  %5.1f %%" % (a[0], a[1], 100.0 * a[0] / a[1]))
    print("   OPEN      f31 3..7  : %4d of %4d  %5.1f %%" % (b[0], b[1], 100.0 * b[0] / b[1]))
    print("   ⇒ the same rate.  Discarding an accumulator is ORDINARY here, so it carries no")
    print("     information about what the open codes mean -- which is what the lemma needs.")


def main():
    files = [a for a in sys.argv[1:] if not a.startswith("--")] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    listing, audit = "--list" in sys.argv, "--audit" in sys.argv
    tot = blind = 0
    byaxis = collections.Counter()
    fails = collections.Counter()
    rows = []
    for f in files:
        if os.path.basename(f) in ("index.dsm",):
            continue
        words, slots = [], []
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                slots.append(int(m.group(1)))
                words.append(int(m.group(2), 16))
        for i, w in enumerate(words):
            if D.decoded(w):
                continue
            ax = open_axes(w)
            if not ax or not all(acc_confined(a) or bus_confined(a) for a in ax):
                continue
            tot += 1
            ok, why = blind_after(words, i, bus=any(bus_confined(a) for a in ax))
            if ok:
                blind += 1
                for a in ax:
                    byaxis[a] += 1
            else:
                fails[why.split(": ", 1)[1] if ": " in why else "tail"] += 1
            rows.append((os.path.basename(f), slots[i], w, ok, why, ax))

    if "--null" in sys.argv:
        return null_control(_images(files))
    print("=== ACCUMULATOR-BLIND WORDS -- refused only on an axis confined to `acc' ===")
    print("   candidate sites (every open axis is accumulator- or bus-confined): %4d" % tot)
    print("   ★ of those, BLIND -- the accumulator is destroyed unread  : %4d" % blind)
    print("     still observable (the axis matters there)               : %4d" % (tot - blind))
    if byaxis:
        print("\n   the blind ones, by the axis that was refusing them:")
        for a, n in byaxis.most_common():
            print("      %-22s %4d" % (a, n))
    if fails:
        print("\n   the NON-blind ones, by what first observes the accumulator:")
        for a, n in fails.most_common():
            print("      %-34s %4d" % (a, n))
    if listing or audit:
        print("\n%-34s %5s %-11s %-6s %s" % ("image", "slot", "word", "blind", "why"))
        for fn, s, w, ok, why, ax in rows:
            if audit and ok:
                continue
            print("%-34s %5d %010X %-6s %s   [%s]"
                  % (fn, s, w, "BLIND" if ok else "-", why, ", ".join(ax)))
    print("\n⇒ %d words execute IDENTICALLY under every surviving reading of the axis that refuses"
          % blind)
    print("  them.  The axis stays OPEN; what is settled is that it has no consequence there.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
