#!/usr/bin/env python3
"""dlyseed_confront.py -- confront a DLYSEED2-seeded LLE frame trace with the HLE oracles.

Reads the upd6383 TIME-ORDERED FRAME TRACE (error.log from a run with -log, rows
    upd6383:   n  iw u1  word dp mem acc accb P cur coef tA tB MUL L
 -- the format lle_trace_diff.py parses; mem/coef/tA/tB are 24-bit hex, acc/accb/P signed
decimals, L the operand latch as a signed decimal) captured with UPD6383_DLYSEED2 (which
seeds the external delay DRAM at the chip's own tap address with 0x4000 -> 0x400000 = 0.5 FS
on the bus), and asks the questions that decode a delay-family datapath:

  1. DOES THE SEEDED TAP DATUM REACH THE ALU?  Any body row (iw >= lo, unit 0) whose operand
     latch L == 4194304 (0x400000) -- or whose P equals coef*0x400000 >> 6 -- proves the
     external-DRAM read -> per-line latch -> publish -> multiply path carries the impulse.
     (v1 seeding of the D-RAM state block never reached L; N-DLYSEED-SINGLE-DELAY-TRACE.)
     Q1c then follows the datum ONE ROW ON: does the next word still see it (L), or has it
     been stored under the pointer (mem[dp])?  A datum that is neither is DEAD on the read
     word -- the CHORUS case (N-DLYSEED2-CHORUS-CONFRONT).
  2. DO THE MEASURED ARITHMETIC PRIMITIVES HOLD?  Q1b: the multiplier with its depth-1
     coefficient pipeline, P[N] = coef[N-1] x L[N] >> 6.  Q2b: the one-slot accumulator,
     acc[N] = acc[N-1] + P[N-1] (accumulate), acc[N] = P[N-1] (load), plus the device's two
     DIRECT-OPERAND forms seen on the modulation family: acc[N] = acc[N-1] + P[N-1] + L[N]<<16
     ("bus add": the LFO phase word 092.A, the sweep words 192.A.4x.000 and the anchored
     LFO-read 082.2.00.1C0 -- SPECULATIVE device forms, named here so they are not reported
     as unexplained) and P[N] = L[N] << 16 ("P <- bus", the ACT 0x0E reading).
  3. WHERE DOES THE SIGNAL DIE?  The last body row with |acc| or |P| non-zero.

LANDMARKS print the LFO phase-accumulate / wrap pair (the phase cell's per-frame delta must
equal the HLE LFOOracle increment, e.g. 114 for the chorus's 0.6 Hz) and the class-6 table
words (the device models the addressing but NOT the table).

The §200 DELAY AGE census lines are echoed with a ⚠: the census is CUMULATIVE SINCE BOOT and
spans every program that ran (the boot default, then the navigated effect), so its min..max
is NOT a clean per-program line depth -- see N-DLYSEED2-CHORUS-CONFRONT §5.

⚠ The `mem` column is m_dram[dp] (the D-RAM cell at the pointer), NOT the fetched delay
datum -- the fetch lands on L.  Do not read "mem" as the tap value.
⚠ The trace prints the 36-bit word as 10 hex digits with a LEADING 0 ("0092A00200"):
hi12 = word[1:4], class4 = word[4], addr8 = word[5:7], lo12 = word[7:10].

    python3 dsp/tools/dlyseed_confront.py error.log [--lo 84] [--hi 130] [--dump]
"""
import re
import sys

IMPULSE = 0x400000                          # 0x4000 << 8, the DLYSEED2 datum on the bus
ACC_SHIFT = 16                              # datum scale inside the 40-bit accumulator
ROW = re.compile(r"upd6383:\s+(\d+)\s+(\d+)\s+([01])\s+([0-9A-F]+)\s+([0-9A-F]{2})\s+([0-9A-F]{6})"
                 r"\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+([0-9A-F]{2})\s+([0-9A-F]{6})\s+([0-9A-F]{6})"
                 r"\s+([0-9A-F]{6})\s+([Y.])\s+(-?\d+)")
AGE = re.compile(r"§200 DELAY AGE dsc ([0-9A-F]+): hits (\d+) \| frames_since_written (\d+) \.\. (\d+)")


def parse(path):
    rows = []
    ages = []
    in_block = False
    for ln in open(path, errors="replace"):
        m = AGE.search(ln)
        if m:
            ages.append((m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4))))
        if "TIME-ORDERED FRAME TRACE" in ln:
            in_block = True; rows = []          # keep the LAST block in the file
            continue
        if not in_block:
            continue
        m = ROW.search(ln)
        if not m:
            continue
        n, iw, u1, word, dp, mem, acc, accb, p, cur, coef, ta, tb, mul, l = m.groups()
        rows.append(dict(n=int(n), iw=int(iw), u1=int(u1), word=word, dp=int(dp, 16),
                         mem=int(mem, 16), acc=int(acc), accb=int(accb), p=int(p),
                         cur=int(cur, 16), coef=int(coef, 16), mul=(mul == "Y"), l=int(l)))
    parse.ages = ages
    return rows


parse.ages = []


def s24(v):
    v &= 0xffffff
    return v - 0x1000000 if v & 0x800000 else v


def fields(r):
    """hi12, f31, class4, addr8, SRC, ACT of a trace row's word."""
    w = int(r["word"], 16)
    hi12 = (w >> 24) & 0xfff
    lo = w & 0xfff
    return hi12, (hi12 >> 1) & 7, (w >> 20) & 0xf, (w >> 12) & 0xff, (lo >> 6) & 0x1f, lo & 0x1f


def dump(body):
    print(" iw  word        hi12 f31 cls a8 SRC ACT  dp  mem            acc          P  cur coef   MUL L")
    for r in body:
        hi12, f31, cls, a8, src, act = fields(r)
        print("%3d  %s  %03X  %d   %X  %02X  %02X  %02X  %02X %06X %14d %10d  %02X %06X  %s %d" % (
            r["iw"], r["word"], hi12, f31, cls, a8, src, act, r["dp"], r["mem"], r["acc"], r["p"],
            r["cur"], r["coef"], "Y" if r["mul"] else ".", r["l"]))
    print()


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo = int(sys.argv[sys.argv.index("--lo") + 1]) if "--lo" in sys.argv else 84
    hi = int(sys.argv[sys.argv.index("--hi") + 1]) if "--hi" in sys.argv else 130
    if not args:
        print(__doc__); return 2
    pshift = int(sys.argv[sys.argv.index("--pshift") + 1]) if "--pshift" in sys.argv else 6
    rows = parse(args[0])
    body = [r for r in rows if r["u1"] == 0 and lo <= r["iw"] <= hi]
    if not body:
        print("no unit-0 body rows in iw %d..%d (is the trace armed after navigation?)" % (lo, hi))
        return 1
    print("%d body rows (unit 0, iw %d..%d)\n" % (len(body), lo, hi))
    if "--dump" in sys.argv:
        dump(body)

    # Q1: does the seeded impulse reach the operand latch / a product?
    hits = [r for r in body if abs(r["l"]) == IMPULSE]
    phits = [r for r in body if r["mul"] and r["coef"] and
             r["p"] == (s24(r["coef"]) * IMPULSE) >> pshift]
    print("Q1  impulse on the operand latch L (== +-0x400000): %d row(s)" % len(hits))
    for r in hits[:8]:
        print("     n=%3d iw=%3d word=%s dp=%02X L=%d P=%d acc=%d" % (r["n"], r["iw"], r["word"], r["dp"], r["l"], r["p"], r["acc"]))
    print("    products equal to coef*0x400000>>6 (impulse multiplied): %d row(s)" % len(phits))
    for r in phits[:8]:
        print("     n=%3d iw=%3d coef=%06X P=%d" % (r["n"], r["iw"], r["coef"], r["p"]))
    if not hits and not phits:
        print("    -> the impulse did NOT reach the ALU: the tap read is not being published/consumed"
              " (or DLYSEED2 was not active on this frame).")

    # Q1c: the FATE of the datum one row on.  L[N+1] still the impulse?  mem[dp] holding it?
    # acc taken it (acc == +-IMPULSE << ACC_SHIFT, the direct-load scale)?  None = dead.
    if hits:
        print("Q1c fate of the datum on the row AFTER each impulse row:")
        idx = {id(r): i for i, r in enumerate(body)}
        for r in hits[:8]:
            i = idx[id(r)]
            if i + 1 >= len(body):
                continue
            nx = body[i + 1]
            fate = []
            if abs(nx["l"]) == IMPULSE: fate.append("still on L")
            if abs(s24(nx["mem"])) == IMPULSE or abs(s24(r["mem"])) == IMPULSE: fate.append("in mem[dp]")
            if abs(nx["acc"]) == IMPULSE << ACC_SHIFT or abs(r["acc"]) == IMPULSE << ACC_SHIFT:
                fate.append("loaded into acc")
            if nx["mul"] and nx["p"] and nx["p"] == (s24(r["coef"]) * nx["l"]) >> pshift and abs(nx["l"]) == IMPULSE:
                fate.append("multiplied")
            print("     iw=%3d -> iw=%3d word=%s dp=%02X mem=%06X acc=%d L=%d : %s"
                  % (r["iw"], nx["iw"], nx["word"], nx["dp"], nx["mem"], nx["acc"], nx["l"],
                     ", ".join(fate) if fate else "DEAD (not on L, not under the pointer, not in acc)"))

    # Q1b: the MEASURED multiplier has a coefficient pipeline of depth 1 (handoff §1):
    #      P[N] = (coef[N-1] x L[N]) >> 6.  Test it with the PREVIOUS row's coef.
    ok_c = bad_c = 0
    for i in range(1, len(body)):
        if body[i]["mul"] and body[i]["p"]:
            pred = (s24(body[i - 1]["coef"]) * body[i]["l"]) >> pshift
            if body[i]["p"] == pred: ok_c += 1
            else: bad_c += 1
    print("Q1b multiplier P[N]==coef[N-1]*L[N]>>%d (coef latched one word early): %d exact, %d mismatch"
          % (pshift, ok_c, bad_c))
    pbus = [body[i] for i in range(len(body)) if body[i]["p"] and body[i]["p"] == body[i]["l"] << ACC_SHIFT]
    if pbus:
        print("    P <- bus rows (P[N] == L[N] << %d, the ACT 0x0E `P<-bus' reading): %d  [iw %s]"
              % (ACC_SHIFT, len(pbus), " ".join(str(r["iw"]) for r in pbus[:8])))

    # Q2b: the MEASURED accumulator is a ONE-SLOT pipeline (handoff §1): acc[N] = acc[N-1] + P[N-1]
    #      (f31=1), or acc[N] = P[N-1] at a section-start load (f31=0), saturating at +-2^39.
    #      The device's DIRECT-OPERAND form adds the operand at datum scale on top:
    #      acc[N] = acc[N-1] + P[N-1] + (L[N] << 16)  (SPECULATIVE device form; measured on the
    #      chorus's 092.A / 192.A.4x.000 / 082.2.00.1C0 words with L from the coefficient bus).
    #      Classify every consecutive pair; the residue should sit ONLY on class-2 / DRAM / mixing
    #      boundary words (the open codes), never on a multiply row.
    SAT = {549755748352, 549755813888, -549755813888, -549755748352}
    acc_ok = acc_ld = acc_bus = acc_sat = acc_c2 = acc_bad = 0
    busrows, unexplained = [], []
    for i in range(1, len(body)):
        r, p = body[i], body[i - 1]
        if r["acc"] == p["acc"] + p["p"]: acc_ok += 1
        elif r["acc"] == p["p"]: acc_ld += 1
        elif r["l"] and r["acc"] == p["acc"] + p["p"] + (r["l"] << ACC_SHIFT):
            acc_bus += 1; busrows.append((r, p))
        elif r["acc"] in SAT or p["acc"] in SAT: acc_sat += 1
        elif not r["mul"]: acc_c2 += 1
        else: acc_bad += 1; unexplained.append((r, p))
    print("Q2b one-slot accumulator acc[N]==acc[N-1]+P[N-1]: %d accumulate, %d load (acc==P[N-1]),"
          " %d bus-add (+L[N]<<%d), %d saturated, %d class-2/DRAM/mixing boundary, %d UNEXPLAINED multiply rows"
          % (acc_ok, acc_ld, acc_bus, ACC_SHIFT, acc_sat, acc_c2, acc_bad))
    for r, p in busrows[:10]:
        hi12, f31, cls, a8, src, act = fields(r)
        lsrc = "coef[N-1]" if r["l"] == s24(p["coef"]) else ("mem[N-1]" if r["l"] == s24(p["mem"]) else "?")
        print("     bus-add iw=%3d %03X.%X.%02X SRC=%02X f31=%d  L=%d (=%s)  acc=%d" % (
            r["iw"], hi12, cls, a8, src, f31, r["l"], lsrc, r["acc"]))
    for r, p in unexplained[:10]:
        print("     ?? iw=%3d word=%s dp=%02X acc=%d  prev: acc=%d P=%d  (this P=%d L=%d coef=%06X)"
              % (r["iw"], r["word"], r["dp"], r["acc"], p["acc"], p["p"], r["p"], r["l"], r["coef"]))

    # Q2: running sum across consecutive multiply rows (naive same-slot control)
    ok = bad = loads = 0
    prev = None
    for r in body:
        if r["mul"]:
            if prev is not None and r["acc"] == prev["acc"] + r["p"]:
                ok += 1
            elif r["acc"] == r["p"]:
                loads += 1
            elif prev is not None:
                bad += 1
        prev = r
    print("\nQ2  running-sum on multiply rows: acc==prev+P %d, load (acc==P) %d, neither %d" % (ok, loads, bad))
    nz_p = sum(1 for r in body if r["mul"] and r["p"])
    if nz_p == 0:
        print("    ⚠ VACUOUS: every product P is 0 on this frame (starved datapath), so acc==prev+0 holds"
              " trivially -- this does NOT confirm the '+=' op. Re-run with a seeded tap (DLYSEED2).")
    else:
        print("    %d multiply rows carry a non-zero product -> the running-sum test is meaningful." % nz_p)

    # Landmarks (any program): the LFO phase-accumulate / wrap pair (hi12 092.A / 094.A -- the
    # phase cell is mem[dp]; the wrap constant is 0x7FFFFF) and class-6 table lookups (class4 == 6,
    # addr8 = table selector; the device models the ADDRESSING but NOT the table, so L/P here show
    # the device's gap, not a lookup). Printed so the tool serves the modulation family too.
    lfo = [r for r in body if r["word"][1:4] in ("092", "094") and r["word"][4] == "A"]
    c6 = [r for r in body if r["word"][4] == "6"]
    if lfo or c6:
        print("\nLANDMARKS")
        for r in lfo:
            print("  LFO  %s iw=%3d dp=%02X mem(phase cell)=%06X acc=%d L=%d" % (
                "phase+=" if r["word"][1:4] == "092" else "wrap  ", r["iw"], r["dp"], r["mem"], r["acc"], r["l"]))
        acc_w = [r for r in lfo if r["word"][1:4] == "092"]
        wrap_w = [r for r in lfo if r["word"][1:4] == "094"]
        if acc_w and wrap_w and acc_w[0]["dp"] == wrap_w[0]["dp"]:
            d = (wrap_w[0]["mem"] - acc_w[0]["mem"]) & 0x7fffff
            print("  LFO  phase cell 0x%02X delta across the pair = %d (compare the HLE LFOOracle increment"
                  " round(rate/44100*2^23); the phase word's L=%d is the increment on the bus)"
                  % (acc_w[0]["dp"], d, acc_w[0]["l"]))
        for r in c6:
            print("  C6   table sel 0x%s iw=%3d dp=%02X mem=%06X acc=%d P=%d L=%d  (table NOT modelled in the device)" % (
                r["word"][5:7], r["iw"], r["dp"], r["mem"], r["acc"], r["p"], r["l"]))

    # Q3: where the signal dies
    live = [r for r in body if r["acc"] or r["p"] or r["l"]]
    if live:
        last = live[-1]
        print("\nQ3  last body row with a non-zero acc/P/L: n=%d iw=%d acc=%d P=%d L=%d" %
              (last["n"], last["iw"], last["acc"], last["p"], last["l"]))
    else:
        print("\nQ3  every body row is zero -- the datapath is starved on this frame.")

    if parse.ages:
        print("\n§200 DELAY AGE census in this log (⚠ CUMULATIVE SINCE BOOT, spans every program that ran;"
              " a 0..N range is NOT a clean per-program line depth):")
        for dsc, hits_, a, b in parse.ages:
            if b or hits_ > 100000:
                print("     dsc %s: hits %d | frames_since_written %d .. %d (%.2f .. %.2f ms)"
                      % (dsc, hits_, a, b, a / 44.1, b / 44.1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
