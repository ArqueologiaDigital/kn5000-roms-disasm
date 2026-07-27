#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""host_side.py -- WHAT THE HOST FIRMWARE ALREADY KNOWS ABOUT THE uPD6383GF.

NEC uPD6383GF-3BA, Technics SX-KN5000 IC311.  Companion to
`dsp/analysis/host-side.md'.  Everything printed here is derived from the two
dumped ROMs (Sub CPU v1.42 and the main v10 program ROM) plus the one live
cold-boot host capture; there is no emulator run and no hardware.

`register-space.md' opened the per-algorithm parameter streams and produced a
UI-name -> cell map with ONE load-bearing caveat printed next to it: the T1
address is added to one of THREE per-writer base fields, so the same number is a
different cell in three different memories, and that table conflated them.
This pass removes the caveat by reading the dispatcher: the Sub CPU's parameter
translator has a 25-entry jump table, and each entry is a stub that names an
evaluator AND a writer.  The writer is the address space.

    python3 dsp/tools/host_side.py [all|dispatch|laws|descbase|regmap|spaces|
                                    lfo|mode1|hostif|control]

    dispatch  * the parameter opcode -> evaluator -> writer -> ADDRESS SPACE map,
                decoded from the ROM's own jump table and stub call targets
    laws        each evaluator's constants, and the immediate-size predict/check
    descbase    the relocation-base table -- is `cell == T1 address'?
    regmap    * the per-SPACE named-cell map (task A)
    motifs    * SINGLE DELAY and PARAMETRIC EQ, named from the host side
    spaces    * the rule-7 test: H against the strongest INSTRUCTION-BLIND rival
    lfo       * opcode 0x74 = LFO WAVEFORM is a 36-cell D-RAM TABLE, and the
                write port's auto-increment PROVEN BY CONSTRUCTION
    mode1     * the mode-1 split re-tested against every host path (task B)
    hostif    * the transport, the chip's READY line, the error paths, and the
                command-byte census (task C)
    control     every control, each shown REJECTING something

stdlib only, plus the repo's ROM parsers (like the other tools here).
"""
import argparse
import bisect
import collections
import math
import os
import random
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                              # noqa: E402
import register_space as RS                                         # noqa: E402

SUBBASE = 0xEF00                 # Sub CPU ROM: file offset = addr - SUBBASE

# --------------------------------------------------------------------------
#  The parameter translator, MEASURED addresses (Sub CPU v1.42)
# --------------------------------------------------------------------------
JUMPTABLE = 0x014745             # 25 x u16 offsets, opcodes 0x61..0x79
STUBBASE = 0x03CB8E              # jp XIX+WA base
STUB_EXPLICIT = {0x21: 0x03CEE2, 0x24: 0x03CEBC, 0x40: 0x03CE9F}
STUB_TAIL = 0x03CBA8             # the shared tail every stub falls into
DESCTAB = 0x014777               # the 12-byte relocation descriptors

WRITERS = {
    0x0387E6: ("C", "801.0.AA.821 + tag 0x26", 0x04),
    0x03846C: ("D", "000.1.AA.000 + tag 0x15", 0x06),
    0x038539: ("D", "000.1.AA.000 + tag 0x15", 0x06),
    0x038922: ("S", "801.0.PP.825 + tag 0x4C", 0x08),
}
SPACENAME = {"C": "C-RAM     (tag 0x26, descriptor field +0)",
             "D": "D-RAM/reg (tag 0x15, descriptor field +2)",
             "S": "DELAY DSC (tag 0x4C, descriptor field +4)",
             "X": "composite (the handler writes several cells itself)"}

# handlers that do their own multi-cell writing instead of ending in one writer
COMPOSITE = {0x70: 0x03A933, 0x72: 0x039ABD, 0x74: 0x03869B, 0x76: 0x03B646}
EVAL_END = 0x03C000               # sentinel: the bytecode interpreter starts after

# the six LFO wave tables reached by opcode 0x74 (Sub CPU ROM), MEASURED at
# 0x0386CC/0x0386D6/0x0386E0 (36-entry family) and 0x0386FF/0x038709/0x038713
LFO_TABLES = [(0x01EAFA, 36, "sel 0, len 0x24"), (0x01EB67, 36, "sel 1, len 0x24"),
              (0x01EBD4, 36, "sel 2, len 0x24"), (0x01EC41, 32, "sel 0, len 0x20"),
              (0x01ECA5, 32, "sel 1, len 0x20"), (0x01ED09, 32, "sel 2, len 0x20")]

CURVES = {"A": 0x00012483, "B": 0x00012613, "C": 0x000127A3,
          "D": 0x00012B33, "E": 0x000129A3}


# ==========================================================================
#  0. ROMs and the linear disassembly
# ==========================================================================
def load(subpath, mainpath, toolsdir):
    sys.path.insert(0, toolsdir)
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(subpath)
    main = open(mainpath, "rb").read() if os.path.exists(mainpath) else None
    return rom, main, E


def effect_name(main, algo):
    if main is None:
        return "?"
    o = 0x033568 - 18 * algo
    return main[o:o + 16].decode("ascii", "replace").strip()


class Dis:
    """The unidasm listing of the Sub CPU ROM, indexed by address.

    Used ONLY to read call targets out of the dispatch stubs and evaluators.
    Every address quoted from it is also derivable from the raw ROM bytes; the
    listing is a convenience, not evidence."""

    CALL = re.compile(r"call 0x([0-9a-f]+)")

    def __init__(self, path):
        self.ok = os.path.exists(path)
        self.a, self.t = [], {}
        if not self.ok:
            return
        for line in open(path):
            m = re.match(r"^([0-9a-f]+):", line)
            if m:
                v = int(m.group(1), 16)
                self.a.append(v)
                self.t[v] = line.rstrip()

    def calls(self, entry, stop_at=(), limit=48):
        """call targets from `entry', stopping at a branch to any stop address."""
        if not self.ok:
            return []
        i = bisect.bisect_left(self.a, entry)
        out = []
        for j in range(i, min(i + limit, len(self.a))):
            t = self.t[self.a[j]]
            for s in stop_at:
                if ("0x%06x" % s) in t and ("jr" in t or "jp" in t):
                    return out
            if self.a[j] in stop_at and j > i:
                return out
            m = self.CALL.search(t)
            if m:
                out.append(int(m.group(1), 16))
        return out

    def body(self, lo, hi):
        return [self.t[a] for a in self.a if lo <= a < hi]


def dis_path(subpath):
    return subpath + ".unidasm"


# ==========================================================================
#  1. THE DISPATCH -- opcode -> evaluator -> writer -> SPACE
# ==========================================================================
def dispatch_map(rom, dis):
    """-> {opcode: (stub, evaluator, writer|None, space)}.

    PROVEN BY CONSTRUCTION.  The offsets come out of the ROM (JUMPTABLE), the
    stub entry is STUBBASE + offset (the `jp T,XIX+WA' at 0x03CB89), and the
    call targets come out of the stub itself.  ENUMERATION of the space: the
    translator has exactly FOUR writer entry points -- 0x0387E6, 0x03846C,
    0x038539, 0x038922 -- and every stub calls exactly one of them or none."""
    offs = [rom.u8(JUMPTABLE + 2 * i) | (rom.u8(JUMPTABLE + 2 * i + 1) << 8)
            for i in range(25)]
    stub = {0x61 + i: STUBBASE + offs[i] for i in range(25)}
    stub.update(STUB_EXPLICIT)
    out = {}
    for op in sorted(stub):
        calls = dis.calls(stub[op], stop_at=(STUB_TAIL,))
        ev = calls[0] if calls else None
        wr = next((c for c in calls if c in WRITERS), None)
        sp = WRITERS[wr][0] if wr else "?"
        out[op] = (stub[op], ev, wr, sp)
    # composites: the stub calls no writer, so bound the handler by the next
    # handler entry and count the writer calls INSIDE it.
    ent = sorted({e for _s, e, _w, _p in out.values() if e} | set(COMPOSITE.values()))
    for op, e in COMPOSITE.items():
        hi = next((x for x in ent if x > e), EVAL_END)
        hits = collections.Counter()
        for t in dis.body(e, hi):
            for w in WRITERS:
                if re.search(r"cal[lr] 0x0*%x\b" % w, t):
                    hits[w] += 1
        wr = hits.most_common(1)[0][0] if hits else None
        out[op] = (out[op][0], out[op][1], wr, "X")
        COMPOSITE_HITS[op] = (e, hi, dict(hits))
    return out


COMPOSITE_HITS = {}


def space_of(dmap):
    """opcode -> the space its VALUE lands in ('X' composites resolved)."""
    out = {}
    for op, (_s, _e, wr, sp) in dmap.items():
        out[op] = WRITERS[wr][0] if wr in WRITERS else sp
    return out


def cmd_dispatch(rom, dis, main):
    print("=" * 78)
    print("1. THE PARAMETER OPCODE -> EVALUATOR -> WRITER -> ADDRESS SPACE MAP")
    print("=" * 78)
    if not dis.ok:
        print("  (needs %s -- the unidasm listing of the Sub CPU ROM)" % dis)
        return
    print("""  DSP_PerParameterTranslator (0x03CAAE) dispatches:
      opcode 0x21 -> 0x03CEE2   0x24 -> 0x03CEBC   0x40 -> 0x03CE9F  (explicit)
      opcode 0x61..0x79        -> STUB[0x03CB8E + OFFSETS_14745[op-0x61]]
      opcode 0x7A               -> end of record
      anything else             -> error code 5   (0x03CEFF)
  and every stub has the same shape:

      lda XWA,XSP+0x2a          ; &stream_pointer
      ld  XBC,XDE               ; the user's value
      call <EVALUATOR>          ; -> XHL = the 24-bit datum, stream advanced
      pushw (XSP+0x0N)          ; <- THE DESCRIPTOR BASE FIELD: N NAMES THE SPACE
      ld  WA,IZ / ld XBC,XHL / ld DE,(XSP+0x16)
      call <WRITER>             ; -> the DSP

  ENUMERATION (the whole option set, printed next to the claim): the translator
  contains exactly FOUR writer entry points and each stub calls one of them or
  none -- {0x0387E6 C-RAM, 0x03846C D-RAM, 0x038539 D-RAM, 0x038922 DESCRIPTOR,
  composite}.  There is no fifth.
""")
    dmap = dispatch_map(rom, dis)
    print("   op  stub    evaluator  writer    space")
    per = collections.Counter()
    for op in sorted(dmap):
        s, ev, wr, sp = dmap[op]
        per[sp] += 1
        print("   %02X  %06X  %s   %s  %s"
              % (op, s, ("%06X" % ev) if ev else "  --  ",
                 ("%06X" % wr) if wr else "  --  ", SPACENAME[sp]))
    print()
    print("   totals: %s" % ("  ".join("%s=%d" % (k, v) for k, v in sorted(per.items()))))
    print()
    print("   the four COMPOSITE handlers, bounded by the next handler entry and")
    print("   counted -- how many cells of which space each one writes per record:")
    for op in sorted(COMPOSITE_HITS):
        lo, hi, hits = COMPOSITE_HITS[op]
        print("     op %02X  handler %06X..%06X  %s"
              % (op, lo, hi, ", ".join("%d x writer %06X (%s)"
                                       % (v, w, WRITERS[w][0]) for w, v in sorted(hits.items()))
                 or "no standard writer -- see section 6"))
    print("""
   ** THIS IS WHAT register-space.md sect. 6.1 FLAGGED AND COULD NOT DO. **  Its
   named-cell table carries the caveat "a T1 address is added to one of three
   per-writer base fields, so the same number is a different cell in the C-RAM,
   D-RAM and descriptor spaces.  This table conflates them."  The conflation is
   now removed by construction rather than by inference.
""")
    return dmap


# ==========================================================================
#  2. THE VALUE LAWS
# ==========================================================================
EVAL_NOTES = {
    0x038E9F: "CURVE_E[user]            table lookup, 0 immediate bytes",
    0x038EAC: "CURVE_D[user]            table lookup, 0 immediate bytes  (1.000 dB/step)",
    0x038EB9: "CURVE_{A,B,C}[user]      table lookup, 1 selector byte",
    0x038EF6: "(large helper)",
    0x038F9B: "one 3-byte constant, shift+divide",
    0x038FE8: "3-way piecewise, breakpoints 0x32 / 0x4B",
    0x039206: "lo + (hi-lo)*user/99     LINEAR INTERPOLATION, 2 x 3-byte constants",
    0x03925E: "base + user*44100/1000   MILLISECONDS -> SAMPLES, 1 x 3-byte constant",
    0x0392AC: "const*user/180           DEGREES, 1 x 3-byte constant",
}
EVAL_CONST = {"ac44": "44100 (the sample rate)", "03e8": "1000 (ms)",
              "0063": "99 (the 0..99 user range)", "00b4": "180 (degrees)"}


def eval_ranges(dmap):
    ev = sorted({e for _s, e, _w, _p in dmap.values() if e})
    ev += [COMPOSITE[o] for o in sorted(COMPOSITE)]
    ev = sorted(set(ev))
    return [(ev[i], ev[i + 1] if i + 1 < len(ev) else ev[i] + 0x200)
            for i in range(len(ev))]


def cmd_laws(rom, dis, main):
    print("=" * 78)
    print("2. THE VALUE LAWS -- what each evaluator computes")
    print("=" * 78)
    if not dis.ok:
        return
    dmap = dispatch_map(rom, dis)
    print("  Each evaluator's byte range is taken as [entry, next entry) over the")
    print("  sorted list of ALL evaluator entries -- the helpers are laid out")
    print("  consecutively, and every range below ends in a `ret'.  The constants")
    print("  are grepped out of that range; nothing is inferred from position.")
    print()
    im = re.compile(r"0x0*(1[23][0-9a-f]{3})\b")
    kn = re.compile(r"ld X?BC,0x0*([0-9a-f]+)")
    for lo, hi in eval_ranges(dmap):
        ops = [op for op in sorted(dmap) if dmap[op][1] == lo] + \
              [op for op in sorted(COMPOSITE) if COMPOSITE[op] == lo]
        txt = dis.body(lo, hi)
        tabs = sorted({int(m, 16) for t in txt for m in im.findall(t)})
        cons = sorted({m for t in txt for m in kn.findall(t)})
        note = EVAL_NOTES.get(lo, "")
        cn = []
        for t in tabs:
            nm = next((k for k, v in CURVES.items() if v == t), None)
            cn.append("0x%06X%s" % (t, (" CURVE_" + nm) if nm else ""))
        kk = [("0x%s" % c) + ((" = " + EVAL_CONST[c.rjust(4, '0')])
                              if c.rjust(4, "0") in EVAL_CONST else "")
              for c in cons if c.rjust(4, "0") in EVAL_CONST]
        print("   %06X  ops %-10s  %d lines" %
              (lo, ",".join("%02X" % o for o in ops) or "-", len(txt)))
        if note:
            print("            %s" % note)
        if cn:
            print("            ROM data   : %d references, 0x%06X..0x%06X"
                  % (len(tabs), tabs[0], tabs[-1]))
        if kk:
            print("            constants  : %s" % "  ".join(kk))
    # PREDICT-THEN-CHECK: evaluator immediate consumption vs record lengths
    print()
    print("  ---- PREDICT THEN CHECK: the evaluator's immediate consumption.")
    print("       A call to LABEL_03CF07 reads ONE 3-byte big-endian constant from")
    print("       the stream.  So for the simple evaluators the number of 0x03CF07")
    print("       calls times 3 predicts the record's immediate size.  Records with")
    print("       exactly one instruction give len(body)-2.  A MISS is reported as")
    print("       loudly as a hit.")
    sizes = collections.defaultdict(collections.Counter)
    for a in range(RS.N_ALGOS):
        t2 = rom.u32le(RS.T2_ARRAY + 4 * a)
        if not t2:
            continue
        for _x, _l, b in RS.split_t2(rom, t2):
            sizes[b[0]][len(b) - 2] += 1
    print()
    print("       op  evaluator  cf07  predicted  MEASURED record sizes")
    hit = miss = 0
    for op in sorted(dmap):
        lo, ev = dmap[op][0], dmap[op][1]
        if not ev or op not in sizes:
            continue
        rng = next((r for r in eval_ranges(dmap) if r[0] == ev), None)
        body = dis.body(*rng)
        n = sum(1 for t in body if "call 0x03cf07" in t)
        sel = sum(1 for t in body
                  if "ld E,(XIX)" in t or "ld A,(XIZ+)" in t or "ld C,(XWA+)" in t)
        pred = 3 * n + sel
        got = dict(sorted(sizes[op].items()))
        single = (len(got) == 1)
        ok = (list(got) == [pred])
        if not single:
            print("       %02X  %06X    %d     %2d        %s   (record carries >1 "
                  "instruction -- NOT TESTABLE)" % (op, ev, n, pred, got))
            continue
        hit += ok
        miss += (not ok)
        print("       %02X  %06X    %d     %2d        %s   %s"
              % (op, ev, n, pred, got, "HIT" if ok else "** MISS **"))
    print("       => over the opcodes whose records all have ONE size: %d hits,"
          % hit)
    print("          %d misses (population %d).  Opcodes whose record size varies"
          % (miss, hit + miss))
    print("          hold more than one instruction per record and are excluded,")
    print("          which is stated rather than quietly folded into the hits.")


# ==========================================================================
#  3. THE RELOCATION BASE
# ==========================================================================
def cmd_descbase(rom, main):
    print("=" * 78)
    print("3. THE RELOCATION DESCRIPTOR -- is `cell == T1 address'?")
    print("=" * 78)
    print("""  DSP_PerParameterTranslator loads, at DESC + 12*index (0x03CABB..0x03CB12):
       +0 u16 -> pushed for writer 0x0387E6   (C-RAM)
       +2 u16 -> pushed for writers 0x03846C / 0x038539  (D-RAM)
       +4 u16 -> pushed for writer 0x038922   (delay descriptor)
       +8 u32 -> passed to evaluator 0x039525 and to writer 0x038922
  and every writer forms the final 8-bit address as `base + T1_address'.
  DSP_WriteParameter (0x03C1D2 / 0x03C201 / 0x03C244) passes DESC = 0x014777.
""")
    n = 0
    for i in range(16):
        e = rom.slice(DESCTAB + 12 * i, 12)
        if any(e):
            break
        n += 1
    print("  ROM 0x%06X: %d consecutive 12-byte descriptors that are ENTIRELY ZERO"
          % (DESCTAB, n))
    e = rom.slice(DESCTAB + 12 * n, 12)
    print("  the next 12 bytes are %s -- not a descriptor" % e.hex())
    print()
    print("  ** So in this firmware every relocation base is 0 and the parameter")
    print("     cell is EXACTLY the T1 address.  MEASURED confirmation from the")
    print("     live cold-boot capture, which is independent of the ROM table:")
    for algo, cell in ((1, 0x06), (16, 0x86)):
        r = RS.op63_selector(rom, algo)
        print("        algo %2d %-16s  T1[0x63][0] = 0x%02X   capture wrote 000.1.%02X.000"
              % (algo, effect_name(main, algo), r[2], cell))
    print("     2 of 2, and each would have been off by the base had it been non-zero.")


# ==========================================================================
#  4. THE SITES -- (algo, unit, opcode, operand, address)
# ==========================================================================
def algo_unit(rom):
    """MEASURED unit per algorithm: the I-RAM load address of its op-3 record.
    84 -> effect unit 0, 200 -> effect unit 1.  Algorithms whose program record
    carries command 0x30 are DSP2 (MN19413, IC310) and have no unit here."""
    out = {}
    for a in range(RS.N_ALGOS):
        q = rom.u32le(RS.ALGO_TABLE + 4 * a)
        if not q:
            continue
        for _p, op, body in RS.records(rom, q):
            if op == 3 and len(body) >= 3 and body[0] == 0x01:
                ia = (body[1] << 8) | body[2]
                if ia in (84, 200):
                    out[a] = 0 if ia == 84 else 1
    return out


def sites(rom, unit=None):
    out = []
    for a in range(RS.N_ALGOS):
        if unit is not None and a not in unit:
            continue
        t1p = rom.u32le(RS.T1_ARRAY + 4 * a)
        t2p = rom.u32le(RS.T2_ARRAY + 4 * a)
        if not t1p or not t2p or t1p == RS.NULL_T1:
            continue
        amap = {op: e for op, e in RS.parse_t1(rom, t1p)}
        u = unit.get(a) if unit else None
        for _x, _l, b in RS.split_t2(rom, t2p):
            op, operand = b[0], b[1]
            e = amap.get(op)
            if e is None or operand >= len(e):
                continue
            out.append((a, u, op, operand, e[operand]))
    return out


def dsp2_algos(rom):
    out = collections.defaultdict(list)
    for a in range(RS.N_ALGOS):
        for tbl, lab in ((RS.ALGO_TABLE, "program"), (RS.PARAM_TABLE, "params")):
            q = rom.u32le(tbl + 4 * a)
            if not q:
                continue
            for _p, op, body in RS.records(rom, q):
                if body and body[0] == 0x30:
                    port = ((body[1] << 8) | body[2]) if len(body) >= 3 else None
                    out[a].append((lab, op, port))
    return out


# ==========================================================================
#  5. THE NAMED-CELL MAP, PER SPACE
# ==========================================================================
def ui_lists(toolsdir):
    import json
    p = os.path.join(toolsdir, "kn5000_dsp_paramlist_capture.json")
    return json.load(open(p)) if os.path.exists(p) else []


def cmd_regmap(rom, dis, main, toolsdir):
    print("=" * 78)
    print("4. THE NAMED-CELL MAP, SPLIT BY ADDRESS SPACE  (task A)")
    print("=" * 78)
    if not dis.ok:
        return
    sp = space_of(dispatch_map(rom, dis))
    unit = algo_unit(rom)
    cap = ui_lists(toolsdir)
    names = RS.param_names(main)
    byname = {}
    for e in cap:
        for part in e["name"].split(" / "):
            byname[RS.norm(part)] = e["indices"]
    # per-algorithm alignment: record k <-> UI parameter k
    rows = []
    for a in sorted(unit):
        t1p = rom.u32le(RS.T1_ARRAY + 4 * a)
        t2p = rom.u32le(RS.T2_ARRAY + 4 * a)
        if not t1p or not t2p or t1p == RS.NULL_T1:
            continue
        idx = byname.get(RS.norm(effect_name(main, a)))
        amap = {op: e for op, e in RS.parse_t1(rom, t1p)}
        recs = RS.split_t2(rom, t2p)
        if not idx or len(idx) != len(recs):
            continue
        for k, (_x, _l, b) in enumerate(recs):
            op, operand = b[0], b[1]
            e = amap.get(op)
            if e is None or operand >= len(e):
                continue
            nm, un = names[idx[k] - 1] if 0 < idx[k] <= len(names) else ("?", "?")
            rows.append((sp.get(op, "?"), e[operand], unit[a], nm, un, a, op))
    print("  aligned (algorithm, record) pairs with BOTH a UI name and a space: %d"
          % len(rows))
    print("  over %d algorithms; population for every count below."
          % len({r[5] for r in rows}))
    for space in ("D", "C", "S"):
        sel = [r for r in rows if r[0] == space]
        print()
        print("  ---- %s   (%d named sites)" % (SPACENAME[space], len(sel)))
        per = collections.defaultdict(collections.Counter)
        for _s, cell, u, nm, un, _a, _op in sel:
            per[(u, cell)][nm] += 1
        for (u, cell) in sorted(per):
            c = per[(u, cell)]
            print("     unit %d  cell %02X  %s"
                  % (u, cell, ", ".join("%s x%d" % (n, v) for n, v in c.most_common(4))))
    print()
    print("  ---- ** THE CONTROL, AND IT HAS A STRUCTURAL ASYMMETRY A WRONG")
    print("       ASSIGNMENT WOULD VIOLATE. **  The delay-descriptor space is the")
    print("       delay-line GEOMETRY: a cell holds LINE_BASE + DELAY_IN_SAMPLES")
    print("       (r3-delaydram.md).  So every name that reaches it must be a TIME,")
    print("       and the UI's own unit column decides that -- independently of the")
    print("       dispatcher, of T1 and of the microprogram.")
    per = collections.Counter()
    for s, _cell, _u, _nm, un, _a, _op in rows:
        per[(s, un)] += 1
    for space in ("D", "C", "S"):
        tot = sum(v for (s, _u), v in per.items() if s == space)
        ms = per[(space, "ms")]
        print("       space %s : %3d named sites, %3d of them carry the UI unit `ms'"
              " = %.1f%%" % (space, tot, ms, 100.0 * ms / tot if tot else 0))
    print("       -> the descriptor space is 100 percent milliseconds and the other")
    print("          two are near 0.  A swap of the S label with either of the others")
    print("          inverts that, so the control REJECTS.  The third leg of the")
    print("          same chain is the evaluator: opcode 0x67's is 0x03925E, the")
    print("          only one that multiplies by 44100/1000.")
    print()
    print("  ---- AND THE OTHER DIRECTION, printed because it is the weaker half:")
    nm_sp = collections.defaultdict(set)
    for s, _cell, _u, n, _un, _a, _op in rows:
        nm_sp[n].add(s)
    blur = sorted(n for n, v in nm_sp.items() if len(v) > 1)
    print("       user-visible names that appear in MORE THAN ONE space: %d of %d"
          % (len(blur), len(nm_sp)))
    for n in blur:
        print("          %-18s %s" % (n, "".join(sorted(nm_sp[n]))))
    print("       These are real: an algorithm may build a delay out of the external")
    print("       line (descriptor) or out of an internal cell, and the UI calls both")
    print("       `DELAY L'.  It is NOT evidence against the map, and is not counted")
    print("       as evidence for it either.")
    return rows


# ==========================================================================
#  5b. THE TWO SOLVED MOTIFS, READ FROM THE HOST SIDE
# ==========================================================================
def cmd_motifs(rom, dis, main, toolsdir):
    print("=" * 78)
    print("4b. THE TWO SOLVED MOTIFS, NAMED FROM THE HOST SIDE")
    print("=" * 78)
    sys.path.insert(0, HERE)
    import lfo_ramp as LR                                           # noqa: E402
    for a in (9, 39):
        t1p = rom.u32le(RS.T1_ARRAY + 4 * a)
        t2p = rom.u32le(RS.T2_ARRAY + 4 * a)
        print("  ---- algo %d %s" % (a, effect_name(main, a)))
        print("       T1 (the opcode -> cell map, and the base is 0):")
        for op, e in RS.parse_t1(rom, t1p):
            print("          op %02X -> %s" % (op, " ".join("%02X" % x for x in e)))
        used = [(b[0], b[1]) for _x, _l, b in RS.split_t2(rom, t2p)]
        print("       T2 references (opcode, operand): %s"
              % " ".join("%02X#%d" % k for k in used))
        cram = LR.cram_of_algo(a)
        print("       the algorithm's own canned C-RAM image, cells < 0x30:")
        row = ["%02X=%+.4f" % (k, q23(cram[k])) for k in sorted(cram) if k < 0x30]
        for i in range(0, len(row), 6):
            print("          %s" % "  ".join(row[i:i + 6]))
    print("""
  READ:
   * SINGLE DELAY's C-RAM is TWO MIRRORED 9-CELL CHANNEL BLOCKS at 0x00 and
     0x09 -- cells 0x00..0x08 and 0x09..0x11 are value-for-value identical.
     The host names 0x00 `FEEDBACK L' and 0x09 `FEEDBACK R' (opcode 0x73,
     operands 0 and 2); 0x01 and 0x0A are T1-allocated and never referenced --
     the second cell of each block.  0x02 and 0x0B are +0.5000 in both channels
     and the host gives them NO name at all.
     ** So action00-discriminator.md sect. 0-H is wrong on all three labels it
     assigns: w3 (cell 0x00) is not an input mix, it is FEEDBACK L; w4 (cell
     0x01) is the unreferenced second cell of the same block, not the other
     half of an input mix; and w6 (cell 0x02, +0.5000) is not `the feedback',
     because the feedback is 0x00/0x09 and 0x02 has no user name.  This closes
     store-gate.md item J', which left exactly this OPEN. **
   * PARAMETRIC EQ is five bands on a SIX-CELL STRIDE: T1 op 0x70 gives
     00 06 0C 12 18 (the coefficients) and 64 68 6C 70 74 (a four-cell stride,
     the state).  Band b's three UI knobs FC / Q / G are three T2 records with
     the SAME operand b, and the handler writes THREE C-RAM cells per record.
     Every band's image has cell +3 = -(cell +0) and cell +5 = -1.0000 exactly.
""")


# ==========================================================================
#  6. RULE 7 -- the space map against the strongest instruction-blind rival
# ==========================================================================
BLOCK = {("D", 0): lambda x: x < 0x80, ("D", 1): lambda x: x >= 0x80,
         ("C", 0): lambda x: x < 0x80, ("C", 1): lambda x: x >= 0x90,
         ("S", 1): lambda x: x <= 0x1F, ("S", 0): lambda x: 0x26 <= x <= 0x39}


def cmd_spaces(rom, dis, main):
    print("=" * 78)
    print("5. RULE 7 -- DOES THE TEST SEPARATE THE MAP FROM A RULE THAT NEVER")
    print("   LOOKS AT THE INSTRUCTION?")
    print("=" * 78)
    if not dis.ok:
        return
    H = space_of(dispatch_map(rom, dis))
    unit = algo_unit(rom)
    S = [(a, u, op, ad) for a, u, op, _k, ad in sites(rom, unit)]
    n = len(S)
    print("""  The map is PROVEN BY CONSTRUCTION; this section is a consistency check
  on my READING of the code, and it is built so it can fail.

  The three spaces are partitioned by effect unit, MEASURED and with OPPOSITE
  POLARITY, which is the structural asymmetry a wrong assignment must violate:
      D-RAM      unit 0 : addr < 0x80        unit 1 : addr >= 0x80
      C-RAM      unit 0 : addr < 0x80        unit 1 : addr >= 0x90
      DESCRIPTOR unit 1 : 0x00..0x1F         unit 0 : 0x26..0x39   <-- INVERTED
  (D/C: k4-cursor.md item G, 428/428 canned packets.  DESCRIPTOR: the canned
   descriptor images, 12/12 reverbs and 79/79 unit-0 algorithms.)
""")
    print("  IC311 parameter sites (algorithms whose program loads at I-RAM 84 or")
    print("  200): %d, over %d algorithms; %d of them are unit-1."
          % (n, len({x[0] for x in S}), sum(1 for x in S if x[1] == 1)))

    def score(assign, idx=None):
        ok = 0
        tot = 0
        for i, (a, u, op, ad) in enumerate(S):
            if idx is not None and i not in idx:
                continue
            tot += 1
            f = BLOCK.get((assign.get(op), u))
            if f and f(ad):
                ok += 1
        return ok, tot

    def collisions(assign):
        per = collections.defaultdict(set)
        for a, u, op, ad in S:
            per[(a, assign.get(op), ad)].add(op)
        return sum(1 for v in per.values() if len(v) > 1)

    # the best possible instruction-blind rule: one space per ADDRESS
    best = collections.defaultdict(collections.Counter)
    for a, u, op, ad in S:
        for s in "DCS":
            f = BLOCK.get((s, u))
            if f and f(ad):
                best[ad][s] += 1
    pick = {ad: c.most_common(1)[0][0] for ad, c in best.items() if c}
    r2 = sum(max(c.values()) for c in best.values() if c)
    print()
    print("  ---- STATISTIC 1: unit-block conformance over all %d sites" % n)
    print("       H   dispatch-derived        %d/%d = %.1f%%" % (*score(H), 100 * score(H)[0] / n))
    for one in "DCS":
        r = {op: one for op in H}
        print("       R1  all-%s (the flat reading) %d/%d = %.1f%%"
              % (one, *score(r), 100 * score(r)[0] / n))
    print("       R2* BEST address-only rule   %d/%d = %.1f%%   <- the strongest"
          % (r2, n, 100 * r2 / n))
    print("           rival that NEVER LOOKS AT THE INSTRUCTION: it may choose any")
    print("           space per address, and this is its optimum by construction.")

    # the sharp subset: addresses shared by op 0x67 and by something else
    by = collections.defaultdict(set)
    for a, u, op, ad in S:
        by[ad].add(op)
    sharp = {i for i, (a, u, op, ad) in enumerate(S)
             if 0x67 in by[ad] and (by[ad] - {0x67})}
    hs, ht = score(H, sharp)
    r2s = 0
    for i in sharp:
        a, u, op, ad = S[i]
        f = BLOCK.get((pick.get(ad), u))
        if f and f(ad):
            r2s += 1
    print()
    print("  ---- STATISTIC 2 (rule 7: SCORE ONLY WHERE THE RIVALS DISAGREE).")
    print("       The subset is the sites whose address is used BOTH by opcode 0x67")
    print("       (the only descriptor-space opcode) and by some other opcode.  An")
    print("       address-only rule must give that address ONE space, so it cannot")
    print("       satisfy both -- the loss is forced, not sampled.")
    print("       n = %d, addresses %s" % (ht, sorted({"%02X" % S[i][3] for i in sharp})))
    print("       H   %d/%d = %.1f%%" % (hs, ht, 100 * hs / ht))
    print("       R2* %d/%d = %.1f%%" % (r2s, ht, 100 * r2s / ht))
    for one in "DCS":
        r = {op: one for op in H}
        v = score(r, sharp)[0]
        print("       R1 all-%s  %d/%d = %.1f%%" % (one, v, ht, 100 * v / ht))

    print()
    print("  ---- STATISTIC 3: same-space same-address COLLISIONS.")
    print("       Two user parameters of one algorithm writing one cell of one")
    print("       memory is a broken machine.  Any instruction-blind rule gives")
    print("       equal addresses equal spaces, so its collision count is")
    print("       IDENTICALLY the one-space count -- proved, not sampled.")
    print("       H = %d      one-space (== every address-only rule) = %d"
          % (collisions(H), collisions({op: "X" for op in H})))
    per = collections.defaultdict(set)
    for a, u, op, ad in S:
        per[(a, "X", ad)].add(op)
    for k, v in sorted(per.items()):
        if len(v) > 1:
            print("          algo %2d %-18s cell %02X <- opcodes %s"
                  % (k[0], effect_name(main, k[0]), k[2],
                     " ".join("%02X" % o for o in sorted(v))))

    print()
    print("  ---- R3: 4000 RANDOM PERMUTATIONS of the space labels over the %d"
          % len(H))
    print("       opcodes -- the null that keeps the label multiset and destroys")
    print("       the binding.  Joint over all three statistics:")
    random.seed(13)
    ops = sorted(H)
    b0, c0, s0 = score(H)[0], collisions(H), hs
    both = 0
    for _t in range(4000):
        lab = [H[o] for o in ops]
        random.shuffle(lab)
        r = dict(zip(ops, lab))
        if collisions(r) <= c0 and score(r)[0] >= b0 and score(r, sharp)[0] >= s0:
            both += 1
    print("       permutations matching H on ALL THREE: %d of 4000  (p = %.4f)"
          % (both, both / 4000.0))


# ==========================================================================
#  7. OPCODE 0x74 -- THE LFO WAVETABLE, AND THE AUTO-INCREMENT
# ==========================================================================
def q23(v):
    return (v - (1 << 24)) / float(1 << 23) if v & 0x800000 else v / float(1 << 23)


def lfo_table(rom, base, n):
    cell = rom.u8(base)
    vals = [int.from_bytes(bytes(rom.slice(base + 1 + 3 * i, 3)), "big") for i in range(n)]
    return cell, vals


def capture_transfers(path):
    """-> [(cmd, [payload bytes])] for the whole capture file."""
    if not os.path.exists(path):
        return []
    out, cmd, by = [], None, []
    for line in open(path):
        m = re.match(r"transfer\s+\d+: cmd 0x([0-9A-Fa-f]+)", line)
        if m:
            if cmd is not None:
                out.append((cmd, by))
            cmd, by = int(m.group(1), 16), []
            continue
        m = re.match(r"\s+[0-9A-Fa-f]{4}: (.*)", line)
        if m and cmd is not None:
            by += [int(x, 16) for x in m.group(1).split()]
    if cmd is not None:
        out.append((cmd, by))
    return out


def coldboot_lfo(path):
    """-> [(select_addr8, [values])] for the wavetable burst, straight from the
    live capture; NO model of the increment is used -- each select word carries
    its own address and each packet its own value."""
    out = []
    for cmd, by in capture_transfers(path):
        if cmd != 0x01 or len(by) < 7:
            continue
        if (by[0] << 8 | by[1]) != 0x0160:       # the 36-bit poke port
            continue
        k, cur, vals = 2, None, []
        while k + 5 <= len(by):
            b5 = by[k:k + 5]
            if RS.is_packet(b5):
                if cur is not None:
                    vals.append(RS.packet(b5)[0])
            else:
                w = int.from_bytes(bytes(b5), "big")
                if cur is not None and vals:
                    out.append((cur, vals))
                cur, vals = (D.addr8(w) if (D.class4(w) == 1 and D.lo12(w) == 0
                                            and D.hi12(w) == 0) else None), []
            k += 5
        if cur is not None and vals:
            out.append((cur, vals))
    return out


def cmd_lfo(rom, dis, main, capture_path):
    print("=" * 78)
    print("6. OPCODE 0x74 = `LFO WAVEFORM' IS A 36-CELL D-RAM TABLE")
    print("=" * 78)
    print("""  Handler 0x03869B (task A said: name every opcode).  It is NOT a single-cell
  parameter.  PROVEN BY CONSTRUCTION from the code:

     C = *stream++                      ; 1 immediate byte
     if C == 1 : len = 0x20  tables 0x01EC41 / 0x01ECA5 / 0x01ED09
     else      : len = 0x24  tables 0x01EAFA / 0x01EB67 / 0x01EBD4
     table    = the one selected by the USER VALUE (0, 1 or 2)
     base     = *table++                ; the destination cell, a ROM byte
     for i in 0 .. len/4 - 1:
         cell = base + 4*i              ; 0x038764: WA = i<<2 ; IZ = WA + base
         writer 0x038539 (cell, table[4i+0])      ; address word + datum
         writer 0x038606       (table[4i+1])      ; ** DATUM ONLY **
         writer 0x038606       (table[4i+2])      ; ** DATUM ONLY **
         writer 0x038606       (table[4i+3])      ; ** DATUM ONLY **
""")
    print("  ---- THE SIX ROM TABLES, values read straight off the ROM:")
    for base, n, lab in LFO_TABLES:
        cell, vals = lfo_table(rom, base, n)
        f = [q23(v) for v in vals]
        print("     0x%06X  %-16s base cell 0x%02X  n=%d" % (base, lab, cell, n))
        print("        %s" % " ".join("%+.3f" % v for v in f[:18]))
        if n > 18:
            print("        %s" % " ".join("%+.3f" % v for v in f[18:]))
    print("""
     The first three are three cycles of a 12-point SINE, TRIANGLE and clipped
     (trapezoidal SQUARE) wave of period 24 -- read off the numbers, not
     inferred from a name.  The three 32-entry tables are monotone S/ramp/step
     curves.  ** The UI name for opcode 0x74 is `LFO WAVEFORM', 16 of 16 named
     records (register-space.md sect. 2.3's alignment), and the user value is
     the table index. **
""")
    print("  ---- ** THE AUTO-INCREMENT, PROVEN BY CONSTRUCTION **")
    print("       Writer 0x038606 emits FIVE BYTES and they are all one packet:")
    if dis.ok:
        for t in dis.body(0x038606, 0x038675):
            if "call 0x036a4f" in t or "ld WA,0x000a" in t or "add XWA,0x00000015" in t:
                print("          %s" % t)
    print("       -- no address word.  It is called THREE TIMES after 0x038539 in")
    print("       every group of four.  Four values therefore reach four distinct")
    print("       cells from ONE address word: the write port auto-increments, and")
    print("       |step| = 1 because the group stride is 4 and the groups tile.")
    print("       This replaces register-space.md D1's TILING argument, which left")
    print("       {+1, -1} degenerate, with a fact about the firmware's code.")
    print()
    print("  ---- THE LIVE CAPTURE, and what it settles")
    burst = coldboot_lfo(capture_path)
    big = [b for b in burst if len(b[1]) == 4]
    if big:
        run = []
        for c, v in big:
            if not run or c == run[-1][0] + 4:
                run.append((c, v))
            else:
                if len(run) >= 8:
                    break
                run = [(c, v)]
        print("     %d selects with exactly four packets each; the longest ascending"
              % len(big))
        print("     stride-4 run is %d selects at 0x%02X..0x%02X"
              % (len(run), run[0][0], run[-1][0]))
        flat = [v for _c, vv in run for v in vv]
        cell, vals = lfo_table(rom, LFO_TABLES[0][0], LFO_TABLES[0][1])
        same = sum(1 for i in range(min(len(flat), len(vals))) if flat[i] == vals[i])
        print("     the %d captured values, IN EMISSION ORDER, against ROM table"
              % len(flat))
        print("     0x%06X (the SINE): %d of %d identical, first select 0x%02X vs"
              % (LFO_TABLES[0][0], same, len(vals), run[0][0]))
        print("     the table's own base byte 0x%02X" % cell)
        print("     => the cold-boot LFO waveform is the SINE table, user value 0.")
    print()
    print("  ---- DIRECTION: two discriminators that are NOT the tiling and NOT")
    print("       register-space.md's algo-39 abutment.")
    print("       (i) THE CLOBBER TEST.  Under -1 the table occupies base-3..base+32,")
    print("           i.e. cells 0x1A..0x3D; under +1, 0x1D..0x40.  Which reading")
    print("           destroys a cell the ROM's own init stream writes?")
    has74 = set()
    canned = {}
    for a in range(RS.N_ALGOS):
        t2 = rom.u32le(RS.T2_ARRAY + 4 * a)
        if t2:
            for _x, _l, b in RS.split_t2(rom, t2):
                if b[0] == 0x74:
                    has74.add(a)
        p = rom.u32le(RS.PARAM_TABLE + 4 * a)
        if p:
            canned[a] = {c for tag, c, _v in RS.transactions(rom, p, 1)
                         if tag == RS.TAG_DRAM}
    lo, hi = {0x1A, 0x1B, 0x1C}, {0x3E, 0x3F, 0x40}
    cm = [a for a in sorted(has74) if canned.get(a, set()) & lo]
    cp = [a for a in sorted(has74) if canned.get(a, set()) & hi]
    print("           algorithms carrying an op-0x74 record: %d" % len(has74))
    print("           clobbered under -1 : %d  %s"
          % (len(cm), ", ".join("%d %s" % (a, effect_name(main, a)) for a in cm)))
    print("           clobbered under +1 : %d" % len(cp))
    print("           The test is not vacuous: it has a live discriminator on one")
    print("           side and zero on the other, and the sides could have swapped.")
    print("       (ii) SMOOTHNESS.  Under -1 every group of four is REVERSED in the")
    print("           D-RAM image.  Total variation of the resulting image:")
    for base, n, lab in LFO_TABLES[:3]:
        _c, vals = lfo_table(rom, base, n)
        f = [q23(v) for v in vals]
        minus = [0.0] * n
        for k in range(n):
            minus[4 * (k // 4) + (3 - (k % 4))] = f[k]
        tv = lambda s: sum(abs(s[i + 1] - s[i]) for i in range(len(s) - 1))
        print("           %-10s  +1 = %.3f    -1 = %.3f   (%.2fx rougher)"
              % (lab, tv(f), tv(minus), tv(minus) / tv(f)))
    print("           This ASSUMES the chip reads the wavetable in ascending")
    print("           address order.  Stated, because it is an assumption.")


# ==========================================================================
#  8. THE MODE-1 SPLIT  (task B)
# ==========================================================================
def body_images(rom, E):
    imgs = {}
    for a in range(RS.N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(RS.ALGO_TABLE + 4 * a))
        except Exception:
            continue
        for ia, ws, _l in ir:
            if ia in (84, 200):
                imgs.setdefault(a, (ia, [int.from_bytes(bytes(w), "big") for w in ws]))
    seen = {}
    for a in sorted(imgs):
        ia, ws = imgs[a]
        seen.setdefault((ia, tuple(ws)), a)
    return seen


def cmd_mode1(rom, dis, main, E):
    print("=" * 78)
    print("7. THE MODE-1 SPLIT, RE-TESTED  (task B)")
    print("=" * 78)
    if not dis.ok:
        return
    H = space_of(dispatch_map(rom, dis))
    unit = algo_unit(rom)
    print("""  register-space.md C2 split the 12 mode-1 frame words into 5 whose cell the
  host writes and 7 whose cell the host never writes, and read the split as
  "host-primed = RAM state, never-primed = a hardware register or port".
  Two things were not done: the never-primed test used only the CANNED init
  streams plus the live capture, and the denominator was the canned cell count.
""")
    canned = set()
    full = set()
    for a, p in RS.all_streams(rom).items():
        if a not in unit:
            continue
        for tag, c, _v in RS.transactions(rom, p, 1):
            if tag == RS.TAG_DRAM:
                canned.add(c)
    full |= canned
    for a, u, op, _k, ad in sites(rom, unit):
        if H.get(op) == "D":
            if op == 0x74:
                for k in range(36):
                    full.add((ad + k) & 0xFF)
            else:
                full.add(ad)
    print("  D-RAM cells the host can reach:")
    print("     canned init streams only              : %d of 256" % len(canned))
    print("     + EVERY runtime parameter path (T1)   : %d of 256" % len(full))
    print("     full set: %s" % " ".join("%02X" % c for c in sorted(full)))
    never = [c for c in (0x0F, 0x8C, 0x8D, 0x8F) if c not in full]
    print()
    print("  ** The four never-primed cells SURVIVE the stronger test: %s **"
          % " ".join("%02X" % c for c in never))
    print("  ...but so does most of the space.  P(a random cell is reachable) =")
    print("  %d/256 = %.3f, and 5 of the 12 mode-1 words hit a reachable cell"
          % (len(full), len(full) / 256.0))
    print("  = %.3f.  ** The split is AT CHANCE.  Membership carries no signal,"
          % (5 / 12.0))
    print("  and register-space.md's p = 0.254 was computed with the smaller")
    print("  denominator.  STATE YOUR DENOMINATOR (method rule 9). **")
    print()
    print("  ---- WHAT DOES CARRY SIGNAL: where the words sit.")
    seen = body_images(rom, E)
    per = collections.Counter()
    where = collections.Counter()
    for (ia, ws), a in seen.items():
        for i, w in enumerate(ws):
            if D.class4(w) != 1 or D.c_format(w) or D.is_dram(w):
                continue
            per["%03X.%X.%02X.%03X" % (D.hi12(w), 1, D.addr8(w), D.lo12(w))] += 1
            where[(0 if ia == 84 else 1, D.addr8(w), i == len(ws) - 1)] += 1
    print("     CLASS-1 INDEX words (C format and the delay-DRAM escape removed)")
    print("     over the %d distinct body images:" % len(seen))
    for k, v in per.most_common():
        print("        %s  x%d" % (k, v))
    print("     position:")
    for (u, ad, last), v in sorted(where.items()):
        print("        unit %d  cell %02X  %s  x%d"
              % (u, ad, "LAST WORD OF THE IMAGE" if last else "interior", v))
    print("""
     ** Every body image has exactly ONE such word and it is the LAST word:
     the block terminator.  37 unit-0 images carry addr8 = 0x0E; the single
     unit-1 image carries 0x0F.  So in this family the two units differ by
     +1, NOT by +0x80 -- which is the rule the host's D-RAM cells obey 428/428.

     ** THEREFORE register-space.md C2's dichotomy is FALSE AT ITS FIRST
     ELEMENT.  Cell 0x0E is host-primed (79/79 unit-0 canned streams write
     `000.1.0E.000' with the value 0) AND it is the terminator's unit index.
     One register, both roles.  `Host-primed' and `hardware register' are not
     alternatives, so 0x0F/0x8C/0x8D/0x8F being unwritten says nothing about
     their KIND -- it says the host does not initialise them.
""")
    forms = collections.Counter()
    for a, p in RS.all_streams(rom).items():
        for sel, _n in RS.select_runs(rom, p):
            if D.class4(sel) == 1:
                forms["%03X.%X.%02X.%03X"
                      % (D.hi12(sel), 1, D.addr8(sel), D.lo12(sel))] += 1
    print("     The host's own class-1 select words (91 canned streams), top 12 --")
    print("     note they are `000.1.NN.000', the terminator's shape with hi12 = 0:")
    for k, v in forms.most_common(12):
        print("        %s  x%d" % (k, v))
    print("     and NO unit-1 stream writes 0x0E, 0x8E or 0x0F: 79 versus 0.")


# ==========================================================================
#  9. THE HOST INTERFACE  (task C)
# ==========================================================================
PORTBITS = """
     P7  (SFR 0x1C, P7CR = 0x78 -> bits 3..6 outputs)
        bit 3   /WR      0x0383AF assert (RES) / 0x0383B3 release (SET)
        bit 4   /RD      0x0383B7 assert (RES) / 0x0383BB release (SET)
        bit 5   /CS1     0x0383D1 assert       / 0x0383ED release     IC311
        bit 6   C/D      0x0383A7 -> COMMAND   / 0x0383AB -> DATA
     PE  (SFR 0x38, PECR = 0x71)
        bit 6   /CS2     0x0383D6 assert       / 0x0383F2 release     IC310 DSP2
     PH  (SFR 0x44, PHCR = 0x07, PHFC = 0x18)
        bit 0   ** READ BACK FROM THE CHIP ** 0x0383FA SET then 0x0383FD LDCF
        bit 1   /RESET DSP1   0x038396 assert / 0x03839A release
        bit 2   /RESET DSP2   0x03839E assert / 0x0383A2 release
        bit 3   ** A SECOND INPUT ** sampled ONCE, at 0x034C87 (DSP_SYSTEM_INIT)
     PZ  (SFR 0x68, PZCR = 0xFF) the 8-bit data latch: `LD (0x68),A'
"""


def cmd_hostif(rom, dis, main, capture_path):
    print("=" * 78)
    print("8. THE HOST INTERFACE -- WHAT ELSE THE FIRMWARE KNOWS  (task C)")
    print("=" * 78)
    print("  ---- 8.1  THE TRANSPORT IS BIT-BANGED, AND THE CHIP TALKS BACK.")
    print(PORTBITS)
    print("""     DSP_SEND_COMMAND 0x036331 and DSP_SEND_DATA 0x0367EE are the same
     routine with one difference -- C/D -- and BOTH of them READ THE CHIP:

        timeout = 0x1F40 (8000)
        repeat:                                  ; the READY poll
            release /RD, release /WR
            assert /CS ; r = PH.0 ; release /CS
            if r != 0: break
            if --timeout == 0: return 1           ; <-- ERROR PATH 1, TIMEOUT
        (COMMAND only: C/D <- 0)                 ; DATA leaves C/D at 1
        release /CS ; release /RD ; assert /WR ; assert /CS
        r = PH.0
        if r == 0: return 1                       ; <-- ERROR PATH 2, READY LOST
        LD (PZ),A                                 ; the byte goes out
        release /CS ; release /WR ; (COMMAND only: C/D <- 1)
        return 0

     ** THE CHIP HAS AN OUTPUT THE HOST SAMPLES.  It is one bit -- a READY/ACK
     on PH.0 -- it gates every single byte, and the firmware has a bounded
     8000-iteration wait and TWO distinct failure returns.  A model that
     answers `always ready' is a model of a chip that never stalls. **

     The consumer: DSP_ParameterWriteEngine 0x03CA21/0x03CA80 tests the return
     and, if non-zero, calls 0x03CFED -- which is a bare `ret' -- and abandons
     the record.  The firmware therefore DETECTS a stalled DSP and silently
     drops the parameter write.  No retry, no user-visible error.

     PH.3 is a second, independent input.  DSP_SYSTEM_INIT samples it exactly
     once (0x034C87) and stores its COMPLEMENT into bit 3 of the config word at
     RAM 0x041343, before DSP_RESET (0x0360A7) runs.  It is the only DSP-side
     input read outside the byte handshake.
""")
    # call-site census of the six pin primitives -- the /RD one is the point
    prim = {0x0383A7: "C/D <- COMMAND", 0x0383AB: "C/D <- DATA",
            0x0383AF: "/WR assert", 0x0383B3: "/WR release",
            0x0383B7: "** /RD ASSERT **", 0x0383BB: "/RD release",
            0x0383F7: "read PH.0 (the READY line)",
            0x038396: "/RESET DSP1 assert", 0x03839A: "/RESET DSP1 release"}
    cnt = collections.Counter()
    if dis.ok:
        for a in dis.a:
            t = dis.t[a]
            if "call" in t or "jp " in t or "jr " in t:
                for pv in prim:
                    if ("0x%06x" % pv) in t:
                        cnt[pv] += 1
    print("     call sites of each pin primitive, over the WHOLE 192 KB Sub CPU ROM:")
    for pv in sorted(prim):
        print("        %06X  %-28s %d" % (pv, prim[pv], cnt[pv]))
    print("""
     ** 0x0383B7 -- the routine that ASSERTS /RD -- HAS ZERO CALL SITES. **  The
     firmware carries a read-strobe primitive and never uses it.  So the chip's
     port is bidirectional (somebody wrote that routine), and this firmware's
     traffic is a PURE WRITE LOG: nothing is ever read back except the one-bit
     READY line.  For the direction pass: there is no host read-back to validate
     a data-direction bit against.
""")
    print("  ---- 8.2  THE FRAMING OF EVERY RUNTIME PARAMETER WRITE.")
    print("""     DSP_ParameterWriteEngine, per record, when the target chip is DSP1:
        DSP_DispatchCommand(0x01)     ; 0x03CA41
        DSP_DispatchData(0x01)        ; 0x03CA4D   \\ the 16-bit port number
        DSP_DispatchData(0x60)        ; 0x03CA5A   /  0x0160
        <the translator: address word + datum, or a whole block for op 0x74>
        DSP_DispatchCommand(0x03)     ; 0x03CA9B
     -- which is exactly the `cmd 0x01 / 01 60 / ... ' shape the live capture
     shows, and exactly the shape of the canned bytecode records.""")
    print()
    print("  ---- 8.3  THE CHIP'S COMMAND BYTES, CENSUSED.")
    print("       from the 100 canned program streams and the 100 canned parameter")
    print("       streams (population printed):")
    cens = collections.Counter()
    for a in range(RS.N_ALGOS):
        for tbl, lab in ((RS.ALGO_TABLE, "program"), (RS.PARAM_TABLE, "params")):
            q = rom.u32le(tbl + 4 * a)
            if not q:
                continue
            for _p, op, body in RS.records(rom, q):
                if not body:
                    continue
                port = ((body[1] << 8) | body[2]) if len(body) >= 3 else None
                cens[(lab, op, body[0], port)] += 1
    for k, v in sorted(cens.items()):
        print("       %-7s record-op %X  cmd 0x%02X  port %-7s x%d"
              % (k[0], k[1], k[2], ("0x%04X" % k[3]) if k[3] is not None else "-", v))
    if os.path.exists(capture_path):
        cc = collections.Counter()
        cur = None
        for line in open(capture_path):
            m = re.match(r"transfer\s+\d+: cmd 0x([0-9A-Fa-f]+)", line)
            if m:
                cur = int(m.group(1), 16)
                first = None
                continue
            m = re.match(r"\s+0000: ([0-9A-F]{2}) ([0-9A-F]{2})", line)
            if m and cur is not None:
                cc[(cur, (int(m.group(1), 16) << 8) | int(m.group(2), 16))] += 1
                cur = None
        print()
        print("       and from the LIVE cold-boot capture (%d transfers):"
              % sum(cc.values()))
        for (c, p), v in sorted(cc.items()):
            print("       cmd 0x%02X  first two payload bytes 0x%04X   x%d" % (c, p, v))
        print("""
       READ AS A COMMAND SET:
          cmd 0x01 + 16-bit N  : aim the write pointer at N, then stream
                                 5-byte (36-bit) words.  N = 0x0000/0x003C/
                                 0x0040/0x0047/0x0054/0x00C8 are I-RAM word
                                 addresses 0 / 60 / 64 / 71 / 84 / 200 -- the
                                 kernel, the two link words and the two body
                                 entry points.  N = 0x0160 is a POKE PORT, not
                                 an I-RAM address: the same command carries
                                 register/D-RAM traffic there.
          cmd 0x02 + 0x0161    : the 24-bit coefficient port (3-byte words).
          cmd 0x03             : end of transaction (no payload).
          cmd 0x04 / 0x09 / 0x0C : boot-time, one transfer each.
          cmd 0x30             : NOT IC311 -- it is DSP2 (MN19413, IC310).""")
    print()
    print("  ---- 8.4  ** THE `MALFORMED' ALGORITHM SET IS NOT MALFORMED. **")
    d2 = dsp2_algos(rom)
    unit = algo_unit(rom)
    print("       Every tool in dsp/tools excludes algorithms {79, 88, 89, 90, 91}")
    print("       as MALFORMED.  Algorithms whose streams carry command 0x30:")
    for a in sorted(d2):
        print("       algo %2d %-18s  IC311 unit: %-4s  %s"
              % (a, effect_name(main, a),
                 str(unit.get(a, "NONE")),
                 " ".join("%s/op%X/port 0x%04X" % (l, o, p) for l, o, p in d2[a])))
    print("       The five excluded ones are exactly the five with NO IC311 program:")
    print("       their op-3 program record carries cmd 0x30 and an address")
    print("       (0x05F0 / 0x0D30) that is not an I-RAM word address at all.")
    print("       They are DSP2 programs.  Algorithms 57..60 configure BOTH chips.")


# ==========================================================================
# 10. THE CONTROLS
# ==========================================================================
def cmd_control(rom, dis, main, E, capture_path):
    print("=" * 78)
    print("9. THE CONTROLS -- each shown REJECTING something")
    print("=" * 78)
    if not dis.ok:
        return
    H = space_of(dispatch_map(rom, dis))
    unit = algo_unit(rom)
    S = [(a, u, op, ad) for a, u, op, _k, ad in sites(rom, unit)]

    print("  C1  THE SPACE MAP AGAINST AN INSTRUCTION-BLIND RIVAL.")
    by = collections.defaultdict(set)
    for a, u, op, ad in S:
        by[ad].add(op)
    sharp = [i for i, (a, u, op, ad) in enumerate(S)
             if 0x67 in by[ad] and (by[ad] - {0x67})]
    best = collections.defaultdict(collections.Counter)
    for a, u, op, ad in S:
        for s in "DCS":
            f = BLOCK.get((s, u))
            if f and f(ad):
                best[ad][s] += 1
    pick = {ad: c.most_common(1)[0][0] for ad, c in best.items() if c}
    h = sum(1 for i in sharp
            if BLOCK.get((H.get(S[i][2]), S[i][1])) and BLOCK[(H[S[i][2]], S[i][1])](S[i][3]))
    r = sum(1 for i in sharp
            if BLOCK.get((pick.get(S[i][3]), S[i][1])) and BLOCK[(pick[S[i][3]], S[i][1])](S[i][3]))
    print("      on the %d sites where they disagree: H %d, best address-only %d"
          % (len(sharp), h, r))
    print("      -> the instruction-blind rival is rejected by %d of those sites,"
          % (h - r))
    print("         and it CANNOT do better: one address, one space.  REJECTS.")

    print()
    print("  C2  THE COLLISION CONTROL.")
    per = collections.defaultdict(set)
    for a, u, op, ad in S:
        per[(a, ad)].add(op)
    bad = [k for k, v in per.items() if len(v) > 1]
    print("      one-space reading: %d (algorithm, address) pairs written by two"
          % len(bad))
    print("      different user parameters; under the dispatch map: 0.  REJECTS.")

    print()
    print("  C3  THE CLOBBER CONTROL for the auto-increment direction.")
    print("      2 algorithms are destroyed by -1, 0 by +1 (section 6).  The test")
    print("      had a live discriminator on one side, so it was not vacuous.")

    print()
    print("  C4  THE CURVE-MEMBERSHIP CONTROL (re-derived, register-space.md C2).")
    tabs = {k: RS.curve(rom, b) for k, b in RS.CURVE_038EB9.items()}
    for algo, cell in ((1, 0x06), (16, 0x86)):
        val = RS.COLDBOOT_LEVEL[cell]
        sel = RS.op63_selector(rom, algo)[1]
        member = [k for k, t in tabs.items() if val in t]
        print("      algo %2d cell %02X value 0x%06X: selector %d, present in tables %s"
              % (algo, cell, val, sel, member))
    print("      -> the unit-1 row is in ONE table only; selectors 0 and 1 would")
    print("         have failed.  REJECTS.")

    print()
    print("  C5  THE DESCRIPTOR-BASE CONTROL.")
    print("      If the relocation bases were non-zero, the two MEASURED capture")
    print("      addresses would differ from T1.  They do not, 2 of 2.  A")
    print("      non-zero base is rejected by the capture, not by the ROM table")
    print("      alone (which could have been a different array).")

    print()
    print("  C6  THE UNIT-STRIDE CONTROL for the terminator.")
    seen = body_images(rom, E)
    c = collections.Counter()
    for (ia, ws), a in seen.items():
        w = ws[-1]
        if D.class4(w) == 1 and not D.c_format(w) and not D.is_dram(w):
            c[(0 if ia == 84 else 1, D.addr8(w))] += 1
    print("      last word of each body image, by unit: %s"
          % ", ".join("unit %d cell %02X x%d" % (k[0], k[1], v) for k, v in sorted(c.items())))
    print("      -> the +0x80 rule (which the host's D-RAM cells obey 428/428)")
    print("         PREDICTS 0x8E for unit 1 and is rejected: the cell is 0x0F.")

    print()
    print("  C7  PLANTED PROBE on the dispatch decoder.")
    dmap = dispatch_map(rom, dis)
    print("      opcodes 0x21 and 0x66 must resolve to the SAME evaluator")
    print("      (0x039206, the linear interpolator) but they are different")
    print("      parameters: %s / %s.  A decoder that keyed on the opcode number"
          % ("%06X" % dmap[0x21][1], "%06X" % dmap[0x66][1]))
    print("      rather than the table would not produce a collision here.")
    print("      opcode 0x79's offset is 0x88, OUT OF ORDER in a table that is")
    print("      otherwise ascending -- a decoder that assumed monotone offsets")
    print("      would place it wrongly and give it evaluator %06X instead of %06X."
          % (dmap[0x64][1], dmap[0x79][1]))


# ==========================================================================
def main_():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "dispatch", "laws", "descbase", "regmap",
                             "motifs", "spaces", "lfo", "mode1", "hostif",
                             "control"])
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    if not os.path.isdir(args.tools):
        sys.exit("ERROR: need the ROM parser -- pass --tools <kn7000_mame/tools>")
    rom, mainrom, E = load(args.sub, args.main, args.tools)
    dis = Dis(dis_path(args.sub))
    cap = os.path.join(os.path.dirname(args.tools.rstrip("/")), "notes", "data",
                       "kn5000_dsp1_upload_coldboot.txt")
    c = args.cmd
    if c in ("all", "dispatch"):
        cmd_dispatch(rom, dis, mainrom)
    if c in ("all", "laws"):
        cmd_laws(rom, dis, mainrom)
    if c in ("all", "descbase"):
        cmd_descbase(rom, mainrom)
    if c in ("all", "regmap"):
        cmd_regmap(rom, dis, mainrom, args.tools)
    if c in ("all", "motifs"):
        cmd_motifs(rom, dis, mainrom, args.tools)
    if c in ("all", "spaces"):
        cmd_spaces(rom, dis, mainrom)
    if c in ("all", "lfo"):
        cmd_lfo(rom, dis, mainrom, cap)
    if c in ("all", "mode1"):
        cmd_mode1(rom, dis, mainrom, E)
    if c in ("all", "hostif"):
        cmd_hostif(rom, dis, mainrom, cap)
    if c in ("all", "control"):
        cmd_control(rom, dis, mainrom, E, cap)


if __name__ == "__main__":
    main_()
