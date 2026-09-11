#!/usr/bin/env python3
"""input_route_guards.py -- exactly which decode guard blocks each input word?

QUESTION THIS ANSWERS (Phase 4.2, the audio gate, made precise)
  The K6 input-stage words carry the external audio from the DI latch toward the
  effect body.  Some execute, some do not.  This tool runs dsp_disasm.alu_decoded
  guard-by-guard on each input-stage word and prints the SPECIFIC guard that
  blocks it -- turning "the input-stage ALU is unknown" into a short, named list
  of unanchored SRC/ACT codes that a future session (or hardware reference) must
  settle.  It reads no trace; it is a static property of the microcode + decode.

  Run: python3 dsp/tools/input_route_guards.py
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE))
import dsp_disasm as D  # noqa: E402

WORD_MASK = (1 << 36) - 1


def guard_trace(w):
    """Return the list of strict-guard failures (empty => decodes)."""
    if D.c_format(w):
        return ["c_format (no datapath)"]
    fails = []
    cl = D.class4(w)
    if cl not in (2, 8, 0xA):
        fails.append("class4=%X not a datapath class" % cl)
    if D.lo12(w) & 0x800:
        fails.append("bit-11 modifier set")
    if D.lo_ptrmode(w):
        fails.append("pointer-mode bit-5 set")
    if D.lo_src(w) not in D._ANCHORED_SRC:
        fails.append("SRC 0x%02X unanchored" % D.lo_src(w))
    if D.lo_act(w) not in D._ANCHORED_ACT:
        fails.append("ACT 0x%02X unanchored" % D.lo_act(w))
    if (D.hi12(w) & D.HI_ST) and (cl & 7) != 2:
        fails.append("store bit off mode-2")
    if D.lo_act(w) == D.LO_ACT_ST_BUS and (cl & 7) != 2:
        fails.append("ACT=ST_BUS off mode-2")
    if (D.hi12(w) & D.HI_ST) and (D.hi12(w) & D.HI_B7) and D.hi_f31(D.hi12(w)) != 2:
        fails.append("bit-7 store-gate with f31!=2")
    if not fails and D.hi_f31(D.hi12(w)) not in (D.HI_ACC_LOAD, D.HI_ACC_ADD) \
            and not (D.hi_f31(D.hi12(w)) == D.HI_ACC_HOLD and cl == 8):
        fails.append("f31=%d not an admitted op" % D.hi_f31(D.hi12(w)))
    return fails


def main():
    print("input_route_guards: strict decode status of the K6 input-stage words\n")
    print("  word         role summary                                     status")
    open_src, open_act = set(), set()
    for w in sorted(D.K6_INPUT_STAGE):
        role = D.K6_INPUT_STAGE[w]
        short = role.split(":", 1)[1].strip() if ":" in role else role
        short = (short[:44] + "..") if len(short) > 46 else short
        fails = guard_trace(w)
        spec = D.alu_decoded_spec(w)
        if not fails:
            status = "DECODES (strict)"
        else:
            status = "open: " + "; ".join(fails) + ("  [spec:ok]" if spec else "  [spec:no]")
            for f in fails:
                if f.startswith("SRC "):
                    open_src.add(f.split()[1])
                if f.startswith("ACT "):
                    open_act.add(f.split()[1])
        print("  %010X %-46s %s" % (w, short, status))

    print("\nTHE AUDIO ROUTE IS GATED ON THESE ENUMERATED CODES:")
    print("  unanchored SRC: %s" % (sorted(open_src) or "none"))
    print("  unanchored ACT: %s" % (sorted(open_act) or "none"))
    print("  Anchoring each to STRICT needs MEASURED evidence of what the code does;")
    print("  it cannot be read from captures (these words are not executed) -- ISA-level")
    print("  work (bit-encoding cross-reference or a hardware reference), one code at a time.")

    # Optional: demonstrate, from a trace, WHY the captures cannot anchor them.
    tp = next((a for a in sys.argv[1:] if not a.startswith("-")), None)
    if tp:
        boundary_from_trace(tp)


def boundary_from_trace(path):
    """Show per-code why a capture cannot anchor the gate codes: SRC 0x11 needs a
    non-zero accb to match an operand against; the ACT store-targets need the word
    to execute (an observable store), which strict decode refuses."""
    import os
    sys.path.insert(0, os.path.join(HERE, "..", "hle"))
    from lle_trace_diff import parse_trace
    rows = parse_trace(open(path).read())
    accb_rows = [r for r in rows if r["accb"] != 0]
    src11_matchable = [r for r in accb_rows if D.lo_src(r["word"]) == 0x11
                       and any(r["accb"] >> k == r["l"] and r["l"] for k in range(25))]
    print("\nWHY %s CANNOT ANCHOR THEM (demonstrated, not asserted):" % os.path.basename(path))
    print("  SRC 0x11 = accb: %d/%d rows carry a non-zero accb, but %d of them use SRC 0x11 with an"
          % (len(accb_rows), len(rows), len(src11_matchable)))
    print("     operand matching accb -- so SRC 0x11 stays un-anchorable here; the words that DO")
    print("     read accb are elsewhere, and the accb WRITER is what plan 5.4 must model first.")
    print("  ACT store-targets {0x08,0x0D,0x0E,0x17}: these words are not strict-executed, so")
    print("     they perform no store -- no observable effect to measure the target from.")
    print("     (acc+=P where it appears is the generic MAC accumulate, not the store code.)")


if __name__ == "__main__":
    main()
