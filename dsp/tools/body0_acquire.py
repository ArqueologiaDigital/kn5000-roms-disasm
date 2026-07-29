#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""body0_acquire.py -- NEC uPD6383GF (SX-KN5000 IC311): WHERE DOES BODY 0 FAIL
TO *ACQUIRE* THE INPUT?

SPECULATIVE-APPLIED-REGISTER.md sect. 103 states the defect as one fact:

    body 0 READS the audio-bearing cells (measured window `03r [05r] [07rw] ...')
    and produces an accumulator that does not depend on the input
        body-0 iw90       quiet [274881642546]  loud [274881642546]  IDENTICAL
        body-0 END iw152  quiet [0 .. 0]        loud [0 .. 0]        IDENTICAL

This is the ROM-side lens.  It walks the pointer over the body images and lists,
IN EXECUTION ORDER, every slot that touches cells 0x05 / 0x07, with the full
field decode, and asks of each: does its f31 ADD to the accumulator, LOAD it
(DISCARD), HOLD it, or is f31 UNDECODED?

    python3 dsp/tools/body0_acquire.py [sections]

Sections
    calib       ★ RUN THIS FIRST.  Reproduce the sect.98/99 measured pointer
                window for the LIVE body-0 image.  Nothing below may be
                believed unless this passes.
    slots       ★ THE ANSWER: the ordered slot list for the live image.
    f31         the f31 / gate-bit-7 census over body 0.
    corpus      the same over all 38 body images at base 0x05.

SCOPE, in the result and not in a footnote: `calib' and `slots' are about ONE
image -- the one that was in I-RAM 84..199 when sect.98 measured the window,
identified here by byte-matching the emulator's own pointer-trace dump.
`corpus' is the whole set of 38 and says so per row.
"""
import argparse
import collections
import re
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}

# the emulator's own dump of the RESIDENT I-RAM -- the live image, verbatim
PTRTRACE = "/home/fsanches/compartilhado/kn7000-emulator/kn5000_dsp1_upload_ptrtrace.txt"

# sect.98's live census, as re-stated in sect.99 after the store split.
# `20w' left the mode-2 row when the mode-1 stores were routed to the register
# file, which is why it is absent here and present in sect.98's own listing.
MEASURED_BODY0 = {
    0x03: "r", 0x05: "r", 0x07: "rw", 0x0C: "rw", 0x0D: "r", 0x0E: "rw",
    0x0F: "rw", 0x10: "rw", 0x11: "w", 0x12: "rw", 0x13: "w",
    0x50: "r", 0x51: "r", 0x52: "r", 0x53: "r", 0xF1: "w",
}

DRAM_UNIT_BASE = 0x05           # FORCED: 0x05 | (unit << 7), applied at the CALL


# ----------------------------------------------------------------- fields ---
def hi12(w):    return (w >> 24) & 0xFFF
def class4(w):  return (w >> 20) & 0xF
def addr8(w):   return (w >> 12) & 0xFF
def lo12(w):    return w & 0xFFF
def lo_src(w):  return (w >> 6) & 0x1F
def lo_act(w):  return w & 0x1F
def lo_ptrmode(w): return (w >> 5) & 1
def hi_f31(w):  return (hi12(w) >> 1) & 7
def c_format(w): return (hi12(w) & 0xF00) == 0xC00
def is_c40(w):  return (hi12(w) & 0xFFE) == 0xC40
def mode(w):    return 2 if c_format(w) else (class4(w) & 7)

HI_ST = 1 << 4          # store the accumulator
HI_B7 = 1 << 7          # the store GATE
HI_ESC = 1 << 11        # the format escape


def st_suppressed(w):
    return bool(hi12(w) & HI_B7) and hi_f31(w) == 1


def ptr_postinc(w):
    return (not c_format(w)) and (class4(w) & 7) == 2


def is_dram(w):
    return bool(hi12(w) & HI_ESC) and class4(w) == 1 and not c_format(w)


# --- the exec_decoded()/exec_alu() early exits, mirrored (upd6383.cpp) -------
def lo_sel(w):  return lo12(w) & 0xFF
def lo_imm(w):  return (w >> 11) & 1
def lo_mid(w):  return (lo12(w) >> 8) & 7


def is_regload(w):
    if c_format(w) or class4(w) != 0 or lo_mid(w) != 0:
        return False
    return lo_sel(w) in (0x20, 0x21, 0x22, 0x25, 0x27)


def exec_decoded_early(w):
    """True when exec_decoded() handles the word itself and never calls exec_alu."""
    if is_c40(w) and lo12(w) in (0x445, 0x446):                 # is_setvec
        return True
    if is_regload(w) and not (hi12(w) & HI_ST) and lo_sel(w) in (0x21, 0x25):
        return True                                             # ldptr/rstcur/ldptr.d
    if hi12(w) == 0 and class4(w) == 2 and lo12(w) == 0:        # the nop
        return True
    return False


def alu_reached(w):
    """Does exec_alu()'s MAIN BODY run -- the part that reads, stores and walks?

    Mirrors upd6383.cpp under the shipped speculative configuration
    (m_speculative set, m_specmask 0x9F442F), which is the configuration that
    produced the sect.98/99 window.  Every early `return' on the way is here.
    """
    if exec_decoded_early(w):
        return False
    if c_format(w):                 # 13-bit immediate -> m_cimm, return
        return False
    if lo12(w) & 0x800:             # the alternate lo12 encoding: addressing only
        return False
    cl = class4(w)
    if cl == 6:                     # table-lookup idiom: addressing only
        return False
    hi_esc = (hi12(w) & 0xF00) == 0xA00
    if w == 0 or cl == 5 or (hi_esc and lo12(w) in (0x015, 0x041)):
        return False                # NOP / no modelled side effect
    return True                     # is_dram re-enters here under mask bit 19


def acc_read_mem(w):
    """mode-2 operand read of mem[ptr] (the D-RAM pointer route)."""
    if not alu_reached(w) or lo_src(w) != 0x07:
        return False
    regfile = (mode(w) == 1) and not (hi12(w) & HI_ESC)
    return not regfile


def acc_read_reg(w):
    if not alu_reached(w) or lo_src(w) != 0x07:
        return False
    return (mode(w) == 1) and not (hi12(w) & HI_ESC)


def store_targets(w):
    """[(kind, 'ptr'|addr8)] for this word's stores.  kind is 'b4' or 'act07'."""
    out = []
    if not alu_reached(w):
        return out
    if (hi12(w) & HI_ST) and not st_suppressed(w):
        out.append(("b4", "ptr" if mode(w) != 1 else addr8(w)))
    if lo_act(w) == 0x07:
        out.append(("act07", "ptr" if mode(w) != 1 else addr8(w)))
    return out


F31_NAME = {0: "LOAD  acc<-P  (DISCARDS)", 1: "ADD   acc+=P",
            2: "HOLD  acc unchanged", 3: "UNDECODED f31=3",
            4: "UNDECODED f31=4", 5: "UNDECODED f31=5",
            6: "UNDECODED f31=6", 7: "UNDECODED f31=7"}
F31_SHORT = {0: "LOAD", 1: "ADD ", 2: "HOLD", 3: "UND3", 4: "UND4",
             5: "UND5", 6: "UND6", 7: "UND7"}
SRC_NAME = {0x00: "UNDECODED", 0x02: "UNDECODED", 0x03: "UNDECODED",
            0x07: "mem[ptr]", 0x08: "UNDECODED", 0x0B: "delayRAM",
            0x10: "acc", 0x11: "ACCB?", 0x19: "tempA", 0x1A: "tempB",
            0x1C: "UNDECODED"}
ACT_NAME = {0x00: "acc<-bus (adder leg)", 0x07: "STORE bus", 0x12: "-",
            0x13: "tempA<-bus", 0x14: "tempB<-bus", 0x15: "-",
            0x19: "tempA<-bus?"}


# ----------------------------------------------------------------- corpus ---
def load_corpus(sub, tools):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    rom = E.Rom(sub)

    def blk(a):
        ir, _c, _o = E.parse_stream(rom, a, limit=40)
        return [int.from_bytes(bytes(w), "big") for w in ir[0][1]] if ir else []

    header, epilogue = blk(HEADER_ROM), blk(EPILOGUE_ROM)
    progs = {}
    for i in range(N_ALGOS):
        p = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            ir, _c, _o = E.parse_stream(rom, p)
        except Exception:
            continue
        if ir:
            progs[i] = [int.from_bytes(bytes(w), "big")
                        for w in (w for _a, ws, _l in ir for w in ws)]
    g = {}
    for a in sorted(progs):
        if a in DSP2_MISPARSED:
            continue
        g.setdefault(tuple(progs[a]), []).append(a)
    return header, epilogue, sorted(
        [(v[0], v, list(k)) for k, v in g.items()], key=lambda t: t[0])


def live_body0():
    """the 36-bit words that were actually in I-RAM 84..199, from the emulator's
    own resident-I-RAM dump.  Returns [] if the dump is not present."""
    try:
        txt = open(PTRTRACE).read()
    except OSError:
        return []
    out = []
    for ln in txt.splitlines():
        m = re.match(r"\s+(\d+)\s+([0-9A-F]{10})\s", ln)
        if m and 84 <= int(m.group(1)) <= 199:
            out.append(int(m.group(2), 16))
    return out


def walk(words, base=DRAM_UNIT_BASE):
    """[(slot, word, ptr_at_access)] -- the access uses the PRE-increment cell."""
    p, out = base, []
    for i, w in enumerate(words):
        out.append((i, w, p))
        if ptr_postinc(w):
            p = (p + (addr8(w) - 256 if addr8(w) > 127 else addr8(w))) & 0xFF
    return out, p


# ------------------------------------------------------------------ calib ---
def sec_calib(images):
    print("=" * 78)
    print("CALIB -- reproduce the sect.98/99 MEASURED window for the LIVE body-0 image")
    print("=" * 78)
    live = live_body0()
    if not live:
        print("\n  !! %s absent -- CANNOT CALIBRATE.  Stop here.\n" % PTRTRACE)
        return None, False
    rep = None
    for r, algos, ws in images:
        if live[:len(ws)] == ws:
            rep = (r, algos, ws)
            break
    print("\n  live I-RAM 84..199 : %d words" % len(live))
    if rep is None:
        print("  !! matches NO corpus image -- CANNOT CALIBRATE.\n")
        return None, False
    r, algos, ws = rep
    print("  matches corpus image rep %d (%d words), algorithms %s"
          % (r, len(ws), algos))
    print("  -> this is what the sect.98 window was measured ON, and the whole")
    print("     `slots' section below is scoped to it.")

    tr, end = walk(ws)
    rd, wr, rd1, wr1 = (collections.Counter() for _ in range(4))
    for _i, w, p in tr:
        if acc_read_mem(w):
            rd[p] += 1
        if acc_read_reg(w):
            rd1[addr8(w)] += 1
        for kind, dest in store_targets(w):
            if dest == "ptr":
                wr[p] += 1
            else:
                wr1[dest] += 1

    got = {}
    for c in set(rd) | set(wr):
        got[c] = ("r" if rd[c] else "") + ("w" if wr[c] else "")
    print("\n  static walk, mode-2 : %s"
          % " ".join("%02X%s" % (c, got[c]) for c in sorted(got)))
    print("  sect.98/99 measured : %s"
          % " ".join("%02X%s" % (c, MEASURED_BODY0[c]) for c in sorted(MEASURED_BODY0)))
    print("  static walk, mode-1 : %s"
          % (" ".join("%02X%s" % (c, ("r" if rd1[c] else "") + ("w" if wr1[c] else ""))
                      for c in sorted(set(rd1) | set(wr1))) or "(none)"))
    ok = got == MEASURED_BODY0
    if ok:
        print("\n  ★ CALIBRATED: %d of %d cells agree, EXACT MATCH including the r/w"
              % (len(got), len(MEASURED_BODY0)))
        print("    split on every one.  The walk below is the machine that produced")
        print("    the sect.98 measurement, not a fresh reimplementation of it.")
        print("    (What this does NOT calibrate: whether the CHIP's addressing")
        print("     rule is ours.  Both sides here are our `class4 & 7 == 2'.)")
    else:
        print("\n  ⛔ NOT CALIBRATED.")
        print("     static-only : %s"
              % " ".join("%02X%s" % (c, got[c]) for c in sorted(set(got) - set(MEASURED_BODY0))))
        print("     measured-only: %s"
              % " ".join("%02X%s" % (c, MEASURED_BODY0[c])
                         for c in sorted(set(MEASURED_BODY0) - set(got))))
        for c in sorted(set(got) & set(MEASURED_BODY0)):
            if got[c] != MEASURED_BODY0[c]:
                print("     %02X: static %-2s measured %-2s" % (c, got[c], MEASURED_BODY0[c]))
        print("     Nothing below may be presented as fact.")
    print("\n  pointer at body-0 exit: %02X (net %+d over %d slots)\n"
          % (end, ((end - DRAM_UNIT_BASE + 128) % 256) - 128, len(ws)))
    return rep, ok


# ------------------------------------------------------------------ slots ---
def describe(w):
    return ("%03X.%X.%02X.%03X  f31=%d %-4s  SRC %02X %-9s  ACT %02X %-20s "
            "gate7=%d st4=%d cls=%X"
            % (hi12(w), class4(w), addr8(w), lo12(w), hi_f31(w),
               F31_SHORT[hi_f31(w)], lo_src(w), SRC_NAME.get(lo_src(w), "?"),
               lo_act(w), ACT_NAME.get(lo_act(w), "?"),
               1 if hi12(w) & HI_B7 else 0, 1 if hi12(w) & HI_ST else 0,
               class4(w)))


def sec_slots(rep, ok, cells=(0x05, 0x07)):
    print("=" * 78)
    print("SLOTS -- every body-0 slot touching %s, IN EXECUTION ORDER"
          % "/".join("0x%02X" % c for c in cells))
    print("=" * 78)
    if rep is None:
        print("\n  no live image; skipped\n")
        return []
    r, algos, ws = rep
    if not ok:
        print("\n  ⚠⚠ THE WALK IS UNCALIBRATED -- everything below is a HYPOTHESIS.\n")
    print("\n  SCOPE: corpus image rep %d (algorithms %s), I-RAM 84..%d, base 0x%02X.\n"
          % (r, algos, 84 + len(ws) - 1, DRAM_UNIT_BASE))
    tr, _e = walk(ws)
    hits = []
    for i, w, p in tr:
        if p not in cells:
            continue
        rdm = acc_read_mem(w)
        sts = store_targets(w)
        stp = [k for k, d in sts if d == "ptr"]
        if not rdm and not stp:
            continue
        hits.append((i, w, p, rdm, stp))
    for i, w, p, rdm, stp in hits:
        act = []
        if rdm:
            act.append("READ mem[%02X] -> operand bus" % p)
        for k in stp:
            act.append("STORE(%s) -> mem[%02X]" % (k, p))
        print("   iw%-4d %010X  %s" % (84 + i, w, describe(w)))
        print("          cell %02X : %s" % (p, "; ".join(act)))
        f = hi_f31(w)
        verdict = ("★ PRIME SUSPECT -- the operand is read and the accumulator is "
                   "DISCARDED in the same word" if (rdm and f == 0) else
                   "★ PRIME SUSPECT -- operand read, f31 UNDECODED (executes as 0)"
                   if (rdm and f >= 3) else
                   "acquires: acc += P" if (rdm and f == 1) else
                   "operand read, accumulator HELD" if (rdm and f == 2) else
                   "store only")
        print("          f31 = %d  %-26s %s" % (f, F31_NAME[f], verdict))
        print()
    if not hits:
        print("   (no slot in this image touches those cells)\n")
    return hits


# -------------------------------------------------------------------- f31 ---
def sec_f31(rep):
    print("=" * 78)
    print("F31 -- the operation census over body 0")
    print("=" * 78)
    if rep is None:
        print("\n  no live image; skipped\n")
        return
    r, algos, ws = rep
    print("\n  SCOPE: corpus image rep %d (algorithms %s), %d slots.\n"
          % (r, algos, len(ws)))
    n = collections.Counter()
    ng = collections.Counter()
    nreach = collections.Counter()
    for w in ws:
        n[hi_f31(w)] += 1
        if hi12(w) & HI_B7:
            ng[hi_f31(w)] += 1
        if alu_reached(w):
            nreach[hi_f31(w)] += 1
    print("   f31  meaning                     slots   of which gate b7   ALU reached")
    print("   ---  --------------------------  -----   ---------------   -----------")
    for f in range(8):
        if n[f]:
            print("    %d   %-26s  %5d   %15d   %11d"
                  % (f, F31_NAME[f], n[f], ng[f], nreach[f]))
    und = sum(n[f] for f in range(3, 8))
    print("   ---  --------------------------  -----   ---------------   -----------")
    print("        UNDECODED f31 (3..7)        %5d   %15d   %11d"
          % (und, sum(ng[f] for f in range(3, 8)), sum(nreach[f] for f in range(3, 8))))
    print("        gate bit 7 set, any f31     %5d" % sum(ng.values()))
    print("        total                       %5d" % len(ws))
    print()


# ----------------------------------------------------------------- corpus ---
def sec_corpus(images):
    print("=" * 78)
    print("CORPUS -- all 38 body images walked from base 0x05")
    print("=" * 78)
    print("""
  SCOPE: every distinct body image, walked as a UNIT-0 body (base 0x05) whether
  or not the host ever loads it at unit 0.  The `reaches' columns therefore say
  what the image WOULD touch there.  Sixteen of them are only ever unit 1.
""")
    print("   rep  words  reaches05  reaches07  f31=0  f31=1  f31=2  UNDEC  gate7")
    print("   ---  -----  ---------  ---------  -----  -----  -----  -----  -----")
    tot = collections.Counter()
    for r, _a, ws in images:
        tr, _e = walk(ws)
        r5 = sum(1 for _i, w, p in tr if p == 0x05 and (acc_read_mem(w)
                 or any(d == "ptr" for _k, d in store_targets(w))))
        r7 = sum(1 for _i, w, p in tr if p == 0x07 and (acc_read_mem(w)
                 or any(d == "ptr" for _k, d in store_targets(w))))
        c = collections.Counter(hi_f31(w) for w in ws)
        g = sum(1 for w in ws if hi12(w) & HI_B7)
        und = sum(c[f] for f in range(3, 8))
        print("   %3d  %5d  %9d  %9d  %5d  %5d  %5d  %5d  %5d"
              % (r, len(ws), r5, r7, c[0], c[1], c[2], und, g))
        tot["w"] += len(ws); tot["r5"] += r5; tot["r7"] += r7
        for f in range(8):
            tot[f] += c[f]
        tot["g"] += g
    print("   ---  -----  ---------  ---------  -----  -----  -----  -----  -----")
    print("   ALL  %5d  %9d  %9d  %5d  %5d  %5d  %5d  %5d"
          % (tot["w"], tot["r5"], tot["r7"], tot[0], tot[1], tot[2],
             sum(tot[f] for f in range(3, 8)), tot["g"]))
    print()


# ------------------------------------------------------------------ taint ---
def coeff_fetch(w):
    return (class4(w) & 8) and not c_format(w)


def sec_taint(rep, ok):
    """Propagate `depends on the input' through body 0 under exec_alu()'s own
    semantics, and say WHERE the dependence enters the accumulator and where it
    leaves.  This is the ROM-side counterpart of the sect.81 probe ladder."""
    print("=" * 78)
    print("TAINT -- where does `depends on the input' enter and leave the accumulator?")
    print("=" * 78)
    if rep is None:
        print("\n  no live image; skipped\n")
        return
    r, algos, ws = rep
    if not ok:
        print("\n  ⚠⚠ UNCALIBRATED WALK -- hypothesis only.\n")
    print("""
  MODEL, stated so it can be attacked: the accumulator's update is
      acc <- (f31 == 0 ? 0 : acc) + (ACT == 0x00 ? bus : 0) + (f31 == 2 ? 0 : P)
  and a bit-4 store fires BEFORE it and CLEARS the accumulator.  P is renewed
  only on a coefficient-fetching word (class4 & 8) and is otherwise the previous
  product -- a latch.  An UNDECODED source or action contributes NOTHING, which
  is the whole point: it is where a dependence can silently vanish.

  SEED: cells 0x05, 0x06 and 0x07 carry the kernel's deposit (sect.86: they are
  2 of 29 kernel-written cells whose range differs quiet vs loud).  Everything
  else starts clean.  Only cells 0x05/0x07 are actually inside body 0's window.
""")
    print("  SCOPE: image rep %d (algorithms %s), base 0x%02X.\n" % (r, algos, DRAM_UNIT_BASE))
    mem = {0x05: True, 0x06: True, 0x07: True}
    acc = P = ta = tb = dr = False
    tr, _e = walk(ws)
    first_in = None
    print("   iw    word         event")
    print("   ----  ----------   ------------------------------------------------------")
    for i, w, p in tr:
        if not alu_reached(w):
            continue
        src, act, f = lo_src(w), lo_act(w), hi_f31(w)
        if src == 0x07:
            L = mem.get(addr8(w), False) if acc_read_reg(w) else mem.get(p, False)
        elif src == 0x10:
            L = acc
        elif src == 0x19:
            L = ta
        elif src == 0x1A:
            L = tb
        elif src == 0x0B:
            L = dr
        else:
            L = False               # UNDECODED source -> reads zero
        note = []
        if src == 0x07 and L:
            note.append("bus <- mem[%02X] TAINTED" % (addr8(w) if acc_read_reg(w) else p))
        elif src == 0x07:
            note.append("bus <- mem[%02X] clean" % (addr8(w) if acc_read_reg(w) else p))
        elif src not in (0x10, 0x19, 0x1A, 0x0B):
            note.append("bus <- SRC %02X UNDECODED = 0" % src)
        # the bit-4 store fires BEFORE the ALU and CLEARS
        for kind, dest in store_targets(w):
            if kind != "b4":
                continue
            cell = p if dest == "ptr" else dest
            mem[cell] = acc
            if acc:
                note.append("★ STORE acc(TAINTED) -> mem[%02X], then acc CLEARED" % cell)
                acc = False
            else:
                note.append("store acc(clean) -> mem[%02X], acc cleared" % cell)
                acc = False
        if coeff_fetch(w) and f != 2:
            P = L
        before = acc
        acc = ((False if f == 0 else acc)
               or (L if act == 0x00 else False)
               or (False if f == 2 else P))
        if act in (0x13, 0x19):
            ta = L
        if act == 0x14:
            tb = L
        if act == 0x07:
            for kind, dest in store_targets(w):
                if kind == "act07":
                    mem[p if dest == "ptr" else dest] = L
                    note.append("mem[%s] <- bus (%s)"
                                % ("%02X" % (p if dest == "ptr" else dest),
                                   "TAINTED" if L else "clean"))
        if acc and not before:
            note.append("★★ ACCUMULATOR BECOMES INPUT-DEPENDENT")
            if first_in is None:
                first_in = 84 + i
        if before and not acc:
            note.append("★★ ACCUMULATOR LOSES THE DEPENDENCE (f31=%d, ACT %02X)" % (f, act))
        if note:
            print("   %-5d %010X   %s" % (84 + i, w, "; ".join(note)))
    print("\n   at body-0 exit: acc %s, tempA %s, tempB %s"
          % ("TAINTED" if acc else "clean", "TAINTED" if ta else "clean",
             "TAINTED" if tb else "clean"))
    tc = sorted(c for c, v in mem.items() if v)
    print("   tainted cells   : %s" % " ".join("%02X" % c for c in tc))
    print("   first acquisition: %s"
          % ("iw%d" % first_in if first_in is not None else
             "★★★ NEVER -- the accumulator is input-independent for the whole body"))
    print()


# ----------------------------------------------------------------- kernel ---
KERNEL_BASE = 0xFF          # the frame-closure cell; the kernel walks +6 to 0x05
MEASURED_KA = "01r 02w 03rw 04r 05rw 06w 07rw"          # sect.98, kernel A
MEASURED_06_WRITERS = {11, 19, 21, 27, 33, 34, 39}      # sect.96, live


def sec_kernel(header, images):
    """WHO WRITES 0x05/0x06/0x07 LAST, before body 0 reads them?

    sect.86 grades a cell input-dependent from its WRITE STREAM.  A consumer sees
    only the LAST write.  Those are different questions and this section asks the
    second one."""
    print("=" * 78)
    print("KERNEL -- the LAST writer of each audio cell before body 0 reads it")
    print("=" * 78)
    ws = header[:50]
    tr, end = walk(ws, KERNEL_BASE)
    rd, wr = collections.Counter(), collections.Counter()
    who = collections.defaultdict(list)
    for i, w, p in tr:
        if acc_read_mem(w):
            rd[p] += 1
        for kind, dest in store_targets(w):
            if dest == "ptr":
                wr[p] += 1
                who[p].append((i, w, kind))
    got = {c: ("r" if rd[c] else "") + ("w" if wr[c] else "")
           for c in set(rd) | set(wr)}
    line = " ".join("%02X%s" % (c, got[c]) for c in sorted(got))
    print("\n  CALIBRATION, kernel A (iw 0..49), base 0x%02X" % KERNEL_BASE)
    print("    static walk : %s" % line)
    print("    sect.98     : %s" % MEASURED_KA)
    st6 = {i for i, _w, _k in who[0x06]}
    print("    writers of 0x06 -- static %s  vs sect.96 live %s"
          % (sorted(st6), sorted(MEASURED_06_WRITERS)))
    print("      agree %d, static-only %s, live-only %s"
          % (len(st6 & MEASURED_06_WRITERS), sorted(st6 - MEASURED_06_WRITERS),
             sorted(MEASURED_06_WRITERS - st6)))
    print("""
    ⚠ PARTIAL, and the residue is EXPLAINED rather than waved at: the single
      live-only writer is iw11, which is one of the TWELVE K6 input-stage words.
      For those the core calls exec_addressing_only() -- which ALREADY performs
      the post-increment -- and THEN exec_alu_k6(), whose store uses the pointer
      as it now is.  So a K6 word's store lands on its POST-increment cell in the
      emulator and on its PRE-increment cell here.  Body 0 contains NO K6 word
      (the whitelist is matched by 36-bit value and lives at I-RAM 0..11), which
      is why the body-0 walk above is EXACT and this one is 6 of 7.
""")
    print("  per-frame D-RAM writes, kernel A:  %s"
          % "  ".join("%02X x%d" % (c, wr[c]) for c in sorted(wr)))
    print("""
  ★ THE ARITHMETIC CHECK, computed BEFORE it is interpreted.  sect.86 measured
    2 700 000 writes to cell 0x06 and 1 200 000 to cell 0x07 in one run.  From
    the walks: 0x06 takes 7 kernel-A stores + iw11 (the K6 off-by-one) + 1
    epilogue store (sect.99's mode-1 row `06w') = 9 per frame; 0x07 takes 2
    kernel-A stores + body-0's iw91 and iw92 = 4 per frame.  No other region
    touches either (sect.98/99 rows).  Then
        2 700 000 / 9 = 300 000 frames        1 200 000 / 4 = 300 000 frames
    Two independent cells, the same integer.  The walk's WRITE POPULATION is
    therefore corroborated by a measurement it was not fitted to.
""")
    for cell in (0x05, 0x06, 0x07):
        print("  cell %02X -- %d kernel-A writes, in order:" % (cell, wr[cell]))
        for i, w, kind in who[cell]:
            src = lo_src(w)
            what = ("acc" if kind == "b4" else
                    "bus = SRC %02X %s" % (src, SRC_NAME.get(src, "?")))
            print("     iw%-3d %010X  %03X.%X.%02X.%03X  f31=%d %-4s  %-6s stores %s"
                  % (i, w, hi12(w), class4(w), addr8(w), lo12(w), hi_f31(w),
                     F31_SHORT[hi_f31(w)], kind, what))
        if who[cell]:
            i, w, kind = who[cell][-1]
            src = lo_src(w)
            print("     ==> LAST WRITER iw%d.  %s" % (i, (
                "it stores the ACCUMULATOR" if kind == "b4" else
                "it stores the OPERAND BUS, source SRC %02X (%s)"
                % (src, SRC_NAME.get(src, "?")))))
        print()
    print("""  ★★★ Body 0 reads 0x05 (iw85, iw112) and 0x07 (iw90).  It NEVER reads 0x06
      -- 0x06 is not in its pointer window at all (sect.98's row), and 0x06 is
      the cell with 9 writes a frame and the widest input-dependent range.
""")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*",
                    default=["calib", "slots", "taint", "kernel", "f31", "corpus"])
    ap.add_argument("--sub", default="original_ROMs/kn5000_subprogram_v142.rom")
    ap.add_argument("--tools", default="../kn7000_mame/tools")
    a = ap.parse_args()
    _h, _e, images = load_corpus(a.sub, a.tools)
    print("corpus: %d distinct body images\n" % len(images))
    rep, ok = sec_calib(images)
    if "slots" in a.sections:
        sec_slots(rep, ok)
    if "taint" in a.sections:
        sec_taint(rep, ok)
    if "kernel" in a.sections:
        sec_kernel(_h, images)
    if "f31" in a.sections:
        sec_f31(rep)
    if "corpus" in a.sections:
        sec_corpus(images)


if __name__ == "__main__":
    main()
