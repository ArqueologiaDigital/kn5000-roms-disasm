#!/usr/bin/env python3
"""class2_solve.py -- WHICH accumulator transition does each open ACT code perform?

QUESTION IT ANSWERS
    The uPD6383's class-2 words carry the ACT codes that are still undecoded, and they are the
    bulk of what blocks full LLE (N-CLASS6-LOOKUP-BLOCKED-ON-INDEX §12: "the exact transfer is
    NOT established").  Guessing a semantic per word does not scale and has already produced
    several withdrawn readings.  This does it mechanically instead:

        for every executed row, test a fixed ALGEBRA of candidate accumulator transitions
        against the MEASURED acc[N], group the rows by (class, ACT, SRC, f31), and report the
        candidates that survive EVERY row of a group.

    A group with exactly one survivor is a decode.  A group with several survivors is not --
    and the tool says which rows would separate them, instead of letting a story fill the gap.

  ★ THE VACUITY GUARD, which is the point of the tool.
    When P == 0 the candidate "acc + P" is arithmetically identical to "hold", and a run over a
    starved datapath "confirms" both.  That is RULE 13 (a difference from silence is not a
    signal) in algebraic form, and it is how §10 and §8/§9 went wrong.  So every group reports
    DISCRIMINATING rows: rows where at least two of the surviving candidates disagree.  A group
    with zero discriminating rows is printed as VACUOUS and its survivors are NOT a decode, no
    matter how many rows agree.

USAGE
    python3 dsp/tools/class2_solve.py trace1.log [trace2.log ...] [--cls 2] [--lo 84] [--hi 400]
        [--all-classes] [--min-rows 4] [--show-unexplained] [--split-config] [--by-addr8]

    Traces are `error.log' from a run with -log and UPD6383_TRACE_FRAME set (see
    dsp/tools/pair_gate.sh / dlyseed_run.sh for the capture recipe).  Pass SEVERAL programs'
    traces at once: a semantic that only survives on one program is a coincidence of that
    program's data, and the per-group "programs" count is what exposes it.

  ⛔⛔ WHAT THIS TOOL IS **NOT** -- READ BEFORE QUOTING ANY ROW OF ITS OUTPUT.
    The `acc' column is the DEVICE's accumulator, produced by `upd6383.cpp'.  So a group that
    comes out UNIQUE states what MAME's implementation does, **not what the chip does**.  It is
    a specification extractor, not a decode: it turns several thousand lines of C++ into a
    fourteen-row table that can be diffed against the disassembler's documented semantics, the
    HLE, and the next capture.  A row of this table is evidence about the EMULATOR.

    That is still worth having, for three reasons:
      (1) it states the device's model in one place, so a reading that drifted from the code
          shows up as a mismatch instead of surviving in prose;
      (2) the VACUOUS rows name the (class, ACT, SRC, f31) combinations that **no capture in the
          corpus distinguishes** -- those are the ones a new experiment has to target, and they
          are invisible from the source;
      (3) the ⛔ rows say the device's own behaviour is not in the candidate algebra at all,
          which is how the combined `acc + P + (L << 16)' form was found.
    To make a statement about the CHIP you still need the oracle: run the same program through
    the HLE and compare what it computes, not what the device computed.

  ★ --split-config keys every group by the device arms the capture was taken with, so a ⛔ that is
    really "two different emulators pooled" resolves into one clean row per machine.  Use it the
    moment a group with many rows reports that no candidate explains them all.

READS, NOT ASSUMES
    acc, P, L, mem, accb, tA and tB all come from the trace columns.  The candidate algebra is
    written from the primitives already established (N-DLYSEED2 §1: one-slot accumulator,
    bus-add at <<16, load, hold) plus the obvious neighbours.  Nothing here consults the HLE.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dlyseed_confront import parse, fields, s24   # noqa: E402

BUS = 16                # datum scale on the internal bus (ACC_SHIFT)

#  ⚠ NO CLAMP BY DEFAULT, and that is a MEASURED correction, not a convenience.
#  The first version of this tool clamped every candidate to +-2^39 on the strength of §227's
#  saturation magnitude, and it reported 208 rows "no candidate explains".  They were not
#  unexplained: the traces carry accumulator values past 2.1e12 (~2^41) -- e.g. the EQ's
#  `mac.st tb' at iw94, acc -1 644 307 152 896 + P 544 882 360 320 = -1 099 424 792 576, exact --
#  and the clamp was destroying the match.  Whatever +-2^39 governs, it is NOT a ceiling on the
#  accumulator values this trace reports.  --sat N restores a clamp at +-2^N if a later
#  measurement wants one.
SAT = 0


def clamp(v):
    if not SAT:
        return v
    return max(-(1 << SAT), min((1 << SAT) - 1, v))


#  The candidate algebra.  Each entry is (name, f(prev, cur) -> value or None).
#  `prev' is the row before in EXECUTION order; `cur' is the row whose acc we are explaining.
CANDIDATES = [
    ("acc+P",        lambda p, c: p["acc"] + p["p"]),
    ("P",            lambda p, c: p["p"]),
    ("hold",         lambda p, c: p["acc"]),
    ("acc-P",        lambda p, c: p["acc"] - p["p"]),
    ("acc+L<<16",    lambda p, c: p["acc"] + (c["l"] << BUS)),
    ("acc-L<<16",    lambda p, c: p["acc"] - (c["l"] << BUS)),
    ("L<<16",        lambda p, c: c["l"] << BUS),
    ("acc+mem<<16",  lambda p, c: p["acc"] + (s24(c["mem"]) << BUS)),
    ("mem<<16",      lambda p, c: s24(c["mem"]) << BUS),
    ("acc*2",        lambda p, c: p["acc"] * 2),
    ("acc>>1",       lambda p, c: p["acc"] >> 1),
    #  the deeper post-sum scales UPD6383_C8SHIFT sweeps; without these a capture taken at
    #  C8SHIFT = 2 or 3 reports "no candidate explains" for a word the device is simply scaling.
    ("acc>>2",       lambda p, c: p["acc"] >> 2),
    ("acc>>3",       lambda p, c: p["acc"] >> 3),
    ("zero",         lambda p, c: 0),
    ("accb",         lambda p, c: p["accb"]),
    ("acc+accb",     lambda p, c: p["acc"] + p["accb"]),
    ("acc-accb",     lambda p, c: p["acc"] - p["accb"]),
    ("-acc",         lambda p, c: -p["acc"]),
    #  the two TEMP registers.  SRC 0x19 / 0x1A name tempA / tempB, and they carry the
    #  operand on the codes the first pass could not explain at all (456 rows over 24
    #  programs), so the algebra has to contain them or those groups can never close.
    ("tA<<16",       lambda p, c: s24(c["ta"]) << BUS),
    ("acc+tA<<16",   lambda p, c: p["acc"] + (s24(c["ta"]) << BUS)),
    ("acc-tA<<16",   lambda p, c: p["acc"] - (s24(c["ta"]) << BUS)),
    ("tB<<16",       lambda p, c: s24(c["tb"]) << BUS),
    ("acc+tB<<16",   lambda p, c: p["acc"] + (s24(c["tb"]) << BUS)),
    ("acc-tB<<16",   lambda p, c: p["acc"] - (s24(c["tb"]) << BUS)),
    #  the PREVIOUS row's temps -- the one-slot pipeline that the multiplier already shows
    ("tA[-1]<<16",   lambda p, c: s24(p["ta"]) << BUS),
    ("acc+tA[-1]<<16", lambda p, c: p["acc"] + (s24(p["ta"]) << BUS)),
    ("tB[-1]<<16",   lambda p, c: s24(p["tb"]) << BUS),
    ("acc+tB[-1]<<16", lambda p, c: p["acc"] + (s24(p["tb"]) << BUS)),
    #  the operand latch one slot late, and the half-scale forms the class-8 word suggests
    ("acc+L[-1]<<16", lambda p, c: p["acc"] + (p["l"] << BUS)),
    ("L[-1]<<16",    lambda p, c: p["l"] << BUS),
    ("acc+P>>1",     lambda p, c: p["acc"] + (p["p"] >> 1)),
    ("(acc+P)>>1",   lambda p, c: (p["acc"] + p["p"]) >> 1),
    #  ★ THE COMBINED FORM.  MEASURED on the chorus rows the first pass could not explain at
    #  all (iw90/122/124/127): the word RETIRES the pending product AND adds the bus datum in
    #  the same slot -- `acc + P[N-1] + (L[N] << 16)', exact to the unit on every one of them.
    #  dlyseed_confront.py's "bus-add" classification is this op with the product term dropped,
    #  which is why it read as exact only where P happened to be 0.
    ("acc+P+L<<16",  lambda p, c: p["acc"] + p["p"] + (c["l"] << BUS)),
    ("P+L<<16",      lambda p, c: p["p"] + (c["l"] << BUS)),
    ("acc+P-L<<16",  lambda p, c: p["acc"] + p["p"] - (c["l"] << BUS)),
    ("acc+P+tA<<16", lambda p, c: p["acc"] + p["p"] + (s24(c["ta"]) << BUS)),
    ("acc+P+mem<<16", lambda p, c: p["acc"] + p["p"] + (s24(c["mem"]) << BUS)),
]


#  ★ THE TEMP-REGISTER ALGEBRA (--target ta|tb).  Same machinery, different left-hand side:
#  which ACT codes WRITE tempA / tempB, and with what.  This matters because four separate
#  groups in the accumulator table are tied ONLY because tempA is zero in every capture
#  (N-DEVICE-ALGEBRA-EXTRACTED §6), and the reason it is zero is itself a decode question:
#  MEASURED on the chorus kernel, `iw38' captures the live audio datum into tempA (0x674DA9)
#  and `iw45' (clsA ACT0C SRC08 f31=0) overwrites it with ZERO nine words later, so the body
#  never sees it.  Explaining what ACT 0x0C writes is therefore the same question as unlocking
#  those four rows.  Values here are 24-bit datum scale, not accumulator scale.
TCANDIDATES = [
    ("hold",         lambda p, c, t: s24(p[t])),
    ("acc_datum",    lambda p, c, t: p["acc"] >> BUS),
    ("P_datum",      lambda p, c, t: p["p"] >> BUS),
    ("L",            lambda p, c, t: c["l"]),
    ("L[-1]",        lambda p, c, t: p["l"]),
    ("mem",          lambda p, c, t: s24(c["mem"])),
    ("mem[-1]",      lambda p, c, t: s24(p["mem"])),
    ("coef",         lambda p, c, t: s24(c["coef"])),
    ("coef[-1]",     lambda p, c, t: s24(p["coef"])),
    ("zero",         lambda p, c, t: 0),
    ("other_temp",   lambda p, c, t: s24(p["tb" if t == "ta" else "ta"])),
    ("accb_datum",   lambda p, c, t: p["accb"] >> BUS),
]


def key_of(r):
    _hi, f31, cls, _a8, src, act = fields(r)
    return (cls, act, src, f31)


#  ★ THE CONFIGURATION GUARD.  A capture taken with a device ARM set is a DIFFERENT MACHINE from
#  one taken without it, and pooling them makes a uniform op look contradictory.  MEASURED the
#  hard way: class 8 came out "no candidate explains every row" over 240 rows -- and the reason
#  was that 134 of them came from captures with UPD6383_C8SHIFT unset (where the word HOLDS the
#  accumulator) and 106 from captures with C8SHIFT = 1 (where it is `acc >> 1', exact).  Both
#  behaviours are real; they are just not the same machine.  The device logs every arm it read,
#  so the tool reads them back and reports how many configurations each group spans.
CFG = re.compile(r"upd6383:.*(UPD6383_[A-Z0-9]+) = ([0-9A-Fx]+)")


def config_of(path):
    arms = {}
    for ln in open(path, errors="replace"):
        m = CFG.search(ln)
        if m and m.group(2) not in ("0",):
            arms[m.group(1)] = m.group(2)
    return tuple(sorted(arms.items()))


def main():
    argv = sys.argv[1:]
    VALUED = {"--lo", "--hi", "--cls", "--min-rows", "--sat", "--target"}
    by_a8 = "--by-addr8" in argv       # ★ §12: addr8 in the group key
    split_cfg = "--split-config" in argv   # key groups by device configuration too   # flags that consume the next argument
    logs, skip = [], False
    for i, a in enumerate(argv):
        if skip:
            skip = False
            continue
        if a in VALUED:
            skip = True
        elif not a.startswith("--"):
            logs.append(a)
    def opt(name, default):
        return type(default)(argv[argv.index(name) + 1]) if name in argv else default
    lo = opt("--lo", 84)
    hi = opt("--hi", 400)
    want_cls = opt("--cls", 2)
    min_rows = opt("--min-rows", 4)
    all_classes = "--all-classes" in argv
    target = argv[argv.index("--target") + 1] if "--target" in argv else "acc"
    if target not in ("acc", "ta", "tb"):
        print("--target must be acc, ta or tb"); return 2
    global SAT
    SAT = opt("--sat", 0)
    show_unexp = "--show-unexplained" in argv
    if not logs:
        print(__doc__)
        return 2

    # group -> dict(rows=[], ok=set(names), disc=int, progs=set())
    groups = {}
    unexplained = []
    all_cfgs = {}
    for path in logs:
        rows = [r for r in parse(path) if r["u1"] == 0 and lo <= r["iw"] <= hi]
        tag = os.path.basename(path)
        cfg = config_of(path)
        all_cfgs.setdefault(cfg, []).append(tag)
        for i in range(1, len(rows)):
            prev, cur = rows[i - 1], rows[i]
            if rows[i]["n"] != rows[i - 1]["n"] + 1:
                continue                    # not adjacent in execution order
            _hi, _f31, cls, _a8, _src, _act = fields(cur)
            if not all_classes and cls != want_cls:
                continue
            vals = {}
            if target == "acc":
                for name, fn in CANDIDATES:
                    try:
                        vals[name] = clamp(fn(prev, cur))
                    except Exception:
                        pass
                measured = cur["acc"]
            else:
                for name, fn in TCANDIDATES:
                    try:
                        vals[name] = fn(prev, cur, target)
                    except Exception:
                        pass
                measured = s24(cur[target])
            ok = {n for n, v in vals.items() if v == measured}
            k = key_of(cur) + ((fields(cur)[3],) if by_a8 else ()) + ((cfg,) if split_cfg else ())
            g = groups.setdefault(k, dict(n=0, ok=None, disc=0, progs=set(), cfgs=set(),
                                          iws=set(), vals=[], rows=[]))
            g["n"] += 1
            g["progs"].add(tag)
            g["cfgs"].add(cfg)
            g["iws"].add(cur["iw"])
            g["ok"] = ok if g["ok"] is None else (g["ok"] & ok)
            g["vals"].append(vals)
            if not ok:
                unexplained.append((tag, cur["iw"], cur["word"], prev["acc"], prev["p"],
                                    cur["l"], cur["acc"]))
            if len(g["rows"]) < 4:
                g["rows"].append((tag, cur["iw"], cur["acc"]))

    #  ★ THE VACUITY GUARD, computed over the SURVIVORS only.  Counting rows where ANY two of
    #  the sixteen candidates differ is worthless -- almost every row does that.  What matters
    #  is whether a row separates the candidates that are still standing: if none does, the
    #  group's "winner" is an artefact of the algebra's redundancy (acc + tA<<16 is `hold' on
    #  every row where tA is 0), which is precisely the trap RULE 13 names.
    for g in groups.values():
        surv = g["ok"] or set()
        if not surv:
            g["disc"] = 0
        elif len(surv) == 1:
            #  one survivor: a row discriminates if the survivor's value differs from at least
            #  one other candidate there, i.e. the row actually excluded something.
            only = next(iter(surv))
            g["disc"] = sum(1 for vals in g["vals"]
                            if any(v != vals[only] for n, v in vals.items() if n != only))
        else:
            g["disc"] = sum(1 for vals in g["vals"]
                            if len({vals[n] for n in surv if n in vals}) > 1)

    print("class2_solve: %d log(s), iw %d..%d, class %s, target %s\n"
          % (len(logs), lo, hi, "ALL" if all_classes else want_cls, target))
    print("device configurations in this corpus: %d" % len(all_cfgs))
    for cfg, tags in sorted(all_cfgs.items(), key=lambda kv: -len(kv[1])):
        print("   %-3d capture(s)  %s" % (len(tags), ", ".join("%s=%s" % a for a in cfg) or "(no arms)"))
    if len(all_cfgs) > 1:
        print("   ⚠ MORE THAN ONE CONFIGURATION.  A group spanning several is comparing different")
        print("     machines; read its `cfgs' column before believing a ⛔.")
    print()
    print("%-22s %6s %5s %5s %5s %s" % ("cls/ACT/SRC/f31", "rows", "disc", "progs", "cfgs",
                                        "surviving candidates"))
    print("-" * 100)
    decoded = []
    for k in sorted(groups, key=lambda k: -groups[k]["n"]):
        g = groups[k]
        if g["n"] < min_rows:
            continue
        cls, act, src, f31 = k[:4]
        name = "cls%X ACT%02X SRC%02X f31=%d" % (cls, act, src, f31)
        j = 4
        if by_a8:
            name += " a8=%02X" % k[j]; j += 1
        if split_cfg:
            name += " @" + (",".join("%s=%s" % a for a in k[j]) or "bare")
        surv = sorted(g["ok"])
        note = ""
        if not surv:
            note = "   ⛔ NO CANDIDATE EXPLAINS EVERY ROW (the algebra is incomplete here)"
        elif g["disc"] == 0:
            note = "   ⚠ VACUOUS (no row separates the survivors)"
        elif len(surv) == 1:
            note = "   ★ UNIQUE"
            decoded.append((name, surv[0], g))
        print("%-22s %6d %5d %5d %5d %s%s" % (name, g["n"], g["disc"], len(g["progs"]),
                                               len(g["cfgs"]),
                                               ",".join(surv) if surv else "(none)", note))

    if decoded:
        print("\n★ UNIQUELY DETERMINED GROUPS (one candidate, at least one discriminating row):")
        for name, cand, g in decoded:
            print("   %-22s -> %-12s  %d rows, %d discriminating, %d program(s), iw %s"
                  % (name, cand, g["n"], g["disc"], len(g["progs"]),
                     ",".join(str(x) for x in sorted(g["iws"])[:8])))
        print("   ⚠ One program is NOT a decode.  Re-run with traces from several programs and")
        print("     only believe a group whose `progs' count is > 1.")
    else:
        print("\n(no group is uniquely determined at these settings)")

    if unexplained:
        print("\n⛔ %d row(s) no candidate explains -- the algebra is incomplete there."
              % len(unexplained))
        if show_unexp:
            print("   %-28s %4s %-12s %14s %12s %10s %14s"
                  % ("log", "iw", "word", "prev acc", "prev P", "L", "acc"))
            for t, iw, w, pa, pp, l, a in unexplained[:40]:
                print("   %-28s %4d %-12s %14d %12d %10d %14d" % (t[:28], iw, w, pa, pp, l, a))
    return 0


if __name__ == "__main__":
    sys.exit(main())
