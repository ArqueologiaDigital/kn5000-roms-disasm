#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""closure_pointer.py -- the FRAME-CLOSURE constraint on the D-RAM operand pointer.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  Companion note:
dsp/analysis/closure-pointer.md.

WHAT IT DOES.  It reproduces, statically and without the emulator, the
per-slot D-RAM pointer walk that `upd6383_device::run_frame()' performs, and
then tests the FRAME-CLOSURE constraint against it:

    the two DI input latches sit at FIXED chip addresses (the serial receivers
    write them; no instruction does) and the microcode reads them at ptr+2 and
    ptr+5, so the pointer at PC-restart MUST be identical every frame.

MEASURED by the ADVANCE pass: it is not -- the residue is +121 on 1130880 of
1130880 complete frames, and the static walk independently predicts
-135 == +121 (mod 256).

Subcommands (all stdlib, no emulator):

    walk      the per-slot walk of one frame, with per-region residues
    anchors   the tests of the walk model that no payload can rescue
    solve     the payload search: for each of the five `lo12 = 0x820' words and
              each candidate field extraction, what value would the pointer
              anchors demand, and does any extraction supply it?
    cells     how many DISTINCT D-RAM cells each body touches under the walk,
              against the host's own zero-fill block length
    corpus    the 0x820 family and its neighbours across the whole ROM corpus
  * pools     which algorithms can occupy which unit, and is each pool's net
              displacement CONSTANT?  (X must not depend on the algorithm)
  * sites     ★ the ADMISSIBLE-SITE SET -- the real content of the closure
              constraint.  Excludes I-RAM 0..49, and with it all five 0x820 words
  * demand    what payload each admissible site would need under each ABSOLUTE
              anchor, against every candidate field extraction
  * variants  is the closure failure an artefact of the walk model?  (no row closes)
  * window    do the bodies land in the kernel's I/O window under a SHARED
              pointer?  (they do -- which is a conflict with K6 finding 5)
  * fields    exhaustive contiguous-bit-field search over the five 0x820 words

    python3 dsp/tools/closure_pointer.py <cmd> [--sub <rom>] [--tools <dir>]

Companion note: dsp/analysis/closure-pointer.md.  Items marked * were added by
the CLOSURE pass; the others are from the ADVANCE pass and are unchanged apart
from the TEST B correction in `anchors' (it was labelled load-independent and
is not -- I-RAM 50..52 sits between the two body entries).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DSP = os.path.dirname(HERE)
REPO = os.path.dirname(DSP)

ALGO_TABLE = 0x0001ED7C
PARAM_TABLE = 0x0001EF0C
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
N_ALGOS = 100

# where run_frame() puts the two bodies (MEASURED over all 91 valid streams)
UNIT0_ENTRY = 84
UNIT1_ENTRY = 200
WAIT_WORD = 0xC00A47407

sys.path.insert(0, HERE)
import dsp_disasm as D                                          # noqa: E402


def load_rom(args):
    sys.path.insert(0, args.tools)
    import kn5000_dsp_extract as E
    return E.Rom(args.sub), E


def words_of(E, rom, addr, limit=8192):
    ir, _c, _o = E.parse_stream(rom, addr, limit=limit)
    return [(a, [int.from_bytes(bytes(w), "big") for w in ws]) for a, ws, _l in ir]


def build_iram(E, rom, unit0_algo, unit1_algo):
    """The 384-word I-RAM as the host leaves it: kernel + epilogue + two bodies."""
    iram = [0] * 384
    for a, ws in words_of(E, rom, HEADER_ROM, limit=40):
        for i, w in enumerate(ws):
            iram[a + i] = w
    for a, ws in words_of(E, rom, EPILOGUE_ROM, limit=40):
        for i, w in enumerate(ws):
            iram[a + i] = w
    loads = {}
    for algo in (unit0_algo, unit1_algo):
        if algo is None:
            continue
        for a, ws in words_of(E, rom, rom.u32le(ALGO_TABLE + 4 * algo)):
            loads[algo] = (a, len(ws))
            for i, w in enumerate(ws):
                iram[a + i] = w
    return iram, loads


# ---------------------------------------------------------------------------
#  the walk -- EXACTLY run_frame()'s control flow and addressing
# ---------------------------------------------------------------------------
def walk(iram, cap=384):
    """Return a list of slot records, one per executed word.

    Each record: (slot, pc, word, dp_before, delta, dp_after, cursor_before).
    Control flow: PC 0.., the unit-tagged CALL/RETURN sequencer (EDUCATED GUESS
    G-5 in the device), terminating on the wait word / the cap / I-RAM overrun.
    Addressing: ptr_postinc() on EVERY word (the ADVANCE pass's rule --
    execute what ADDRESSES, never what COMPUTES) and coeff_consumer().
    """
    out = []
    pc, sp, stack = 0, 0, [0, 0]
    dp, cur = 0, 0
    slot = 0
    end = "cap"
    while slot < cap:
        if pc >= len(iram):
            end = "overrun"
            break
        raw = iram[pc]
        if raw == WAIT_WORD:
            end = "wait"
            break
        tagged = (D.is_end(raw) and D.class4(raw) == 1
                  and D.addr8(raw) in (0x0E, 0x0F))
        word = raw & ~(D.HI_END << 24) if tagged else raw
        dp0, cur0 = dp, cur
        delta = 0
        if D.ptr_postinc(word):
            delta = D.addr8(word) - (256 if D.addr8(word) & 0x80 else 0)
            dp = (dp + delta) & 0xFF
        if D.coeff_consumer(word):
            cur = (cur + 1) & 0xFF
        out.append((slot, pc, raw, dp0, delta, dp, cur0))
        pc += 1
        slot += 1
        if tagged:
            if sp == 0:
                stack[sp] = pc
                sp += 1
                pc = UNIT0_ENTRY if D.addr8(raw) == 0x0E else UNIT1_ENTRY
            else:
                sp -= 1
                pc = stack[sp]
    return out, end


def s8(v):
    return v - 256 if v & 0x80 else v


def regions(rec):
    """Split the slot list into the named regions of the cold-boot frame."""
    reg, cur_name, start = [], None, 0
    for i, r in enumerate(rec):
        pc = r[1]
        if pc < 50:
            name = "header 0..49"
        elif pc < 60:
            name = "header 50..59"
        elif pc < 83:
            name = "epilogue 60..82"
        elif pc < UNIT1_ENTRY:
            name = "unit-0 body"
        else:
            name = "unit-1 body"
        if name != cur_name:
            if cur_name is not None:
                reg.append((cur_name, start, i - 1))
            cur_name, start = name, i
    if cur_name is not None:
        reg.append((cur_name, start, len(rec) - 1))
    return reg


# ---------------------------------------------------------------------------
#  candidate payload extractions for a C-format-ish word
# ---------------------------------------------------------------------------
def extractions(w):
    hi, cl, ad, lo = D.hi12(w), D.class4(w), D.addr8(w), D.lo12(w)
    imm13 = (w >> 12) & 0x1FFF
    return {
        "addr8":           ad,
        "imm13>>5 (K5 A)": (imm13 >> 5) & 0xFF,
        "imm13 & 0xFF":    imm13 & 0xFF,
        "imm13>>1":        (imm13 >> 1) & 0xFF,
        "imm13>>2":        (imm13 >> 2) & 0xFF,
        "imm13>>3":        (imm13 >> 3) & 0xFF,
        "imm13>>4":        (imm13 >> 4) & 0xFF,
        "imm13[12:5] low": (imm13 >> 5) & 0x1F,
        "imm13 & 0x1F (B)": imm13 & 0x1F,
        "class4:addr8>>4": ((cl << 4) | (ad >> 4)) & 0xFF,
        "hi12 & 0xFF":     hi & 0xFF,
        "(w>>16)&0xFF":    (w >> 16) & 0xFF,
        "(w>>13)&0xFF":    (w >> 13) & 0xFF,
        "(w>>11)&0xFF":    (w >> 11) & 0xFF,
        "(w>>17)&0xFF":    (w >> 17) & 0xFF,
        "(w>>18)&0xFF":    (w >> 18) & 0xFF,
        "(w>>19)&0xFF":    (w >> 19) & 0xFF,
        "(w>>20)&0xFF":    (w >> 20) & 0xFF,
    }


# ---------------------------------------------------------------------------
def cmd_walk(args, rom, E):
    iram, loads = build_iram(E, rom, args.unit0, args.unit1)
    rec, end = walk(iram)
    print(f"FRAME WALK -- unit0 algo {args.unit0} @ {loads.get(args.unit0)},"
          f" unit1 algo {args.unit1} @ {loads.get(args.unit1)}")
    print(f"  {len(rec)} slots, terminated on {end!r}")
    net = sum(r[4] for r in rec)
    print(f"  net D-RAM pointer displacement  {net}  ==  +{net & 0xFF} (mod 256)")
    print(f"  coefficient cursor advances     {rec[-1][6] + (1 if D.coeff_consumer(rec[-1][2]) else 0)}")
    print()
    print("  per region:")
    for name, a, b in regions(rec):
        d = sum(r[4] for r in rec[a:b + 1])
        print(f"    {name:<16} slots {a:3d}..{b:3d}  delta {d:+5d}"
              f"   dp {rec[a][3]:#04x} -> {rec[b][5]:#04x}")
    if args.verbose:
        print()
        print("  slot  iram   word        cls a8    dp    delta  ->  dp'   cur")
        for slot, pc, raw, dp0, dl, dp1, c0 in rec:
            print(f"  {slot:4d}  {pc:4d}  {raw:010X}  {D.class4(raw):2d} "
                  f"{D.addr8(raw):02X}  {dp0:#04x}  {dl:+5d}  -> {dp1:#04x}  {c0:3d}")


def cmd_anchors(args, rom, E):
    """The LOAD-INDEPENDENT tests: any single reload before I-RAM 42 cancels."""
    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    rec, end = walk(iram)
    idx = {}
    for i, r in enumerate(rec):
        idx.setdefault(r[1], i)          # first slot at each I-RAM address
    print("ANCHOR TESTS -- these use NO payload, so no pointer load can rescue them")
    print()

    def dp_at(iw):
        i = idx[iw]
        return rec[i][3]

    for iw in (0, 42, 45, 49, 50, 53, 59, 60, 79, 80, 81, 82):
        if iw in idx:
            print(f"  dp at I-RAM {iw:3d} (slot {idx[iw]:3d})  "
                  f"= X + {rec[idx[iw]][3]:4d}   word {rec[idx[iw]][2]:010X}")
    print()
    d45 = dp_at(45)
    d53 = dp_at(53)
    print("  ★ TEST A -- the state-block-base anchor (w45 / w53 share lo12 = 0x20C).")
    print("     w53 is class 9 = mode 1 = a REGISTER write at index 0xD0, and 0xD0 is")
    print("     the MEASURED unit-1 state-block base.  w45 is class A = mode 2 = a")
    print("     write at mem[ptr].  If they do the same job in the two addressing")
    print("     modes, dp at w45 must be the unit-0 base 0x50, so")
    print(f"        X  =  0x50 - {d45}  =  {(0x50 - d45) & 0xFF:#04x}")
    print()
    print("  ★ TEST B -- the two-body-entry difference test.")
    print("     CORRECTED by the CLOSURE pass: this is NOT load-independent -- the")
    print("     per-unit setup triple at I-RAM 50..52 sits BETWEEN the two entries,")
    print("     so a reload there rescues it.  What it does force is a DISJUNCTION:")
    print("     the difference is net(body0) + 2, which is ALGORITHM-DEPENDENT")
    print("     (8 distinct unit-0 nets, `pools'), while 0xD0-0x50 = 128 is fixed.")
    e0 = idx[49]
    e1 = idx[59]
    print(f"     dp at the unit-0 CALL (I-RAM 49) = X + {rec[e0][3]}"
          f"  -> body entry X + {rec[e0][5]}")
    print(f"     dp at the unit-1 CALL (I-RAM 59) = X + {rec[e1][3]}"
          f"  -> body entry X + {rec[e1][5]}")
    diff = (rec[e1][5] - rec[e0][5]) & 0xFF
    print(f"     difference = {diff} = {diff:#04x};  0xD0 - 0x50 = 0x80 = 128")
    print(f"     ==> {'equal' if diff == 0x80 else 'NOT equal'}: so EITHER a pointer"
          f" reload exists in I-RAM 50..58,")
    print("         OR the state bases 0x50/0xD0 are not mode-2 pointer addresses.")
    print()
    print("  ★ TEST C -- K6 finding 9: iw0 WRITES X+0 and the epilogue's w80/w81")
    print("     READ X+0 in the SAME frame; w79 WRITES X+1 and iw2 reads it in the")
    print("     NEXT frame.  Under the completed walk:")
    for iw in (0, 2, 79, 80, 81):
        if iw in idx:
            print(f"       I-RAM {iw:3d}: dp = X + {rec[idx[iw]][3]:4d}"
                  f"  (mod 256: X + {rec[idx[iw]][3] & 0xFF})")
    print()
    net = sum(r[4] for r in rec)
    print(f"  net = {net} == +{net & 0xFF} (mod 256);  frame ends on {end!r}")


def cmd_solve(args, rom, E):
    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    rec, _end = walk(iram)
    idx = {}
    for i, r in enumerate(rec):
        idx.setdefault(r[1], i)
    sites = [i for i in (15, 22, 29, 31, 40) if i in idx]
    print("PAYLOAD SEARCH -- what does each anchor DEMAND of a load at each site?")
    print()
    print("  A load at I-RAM S with payload V puts the pointer at I-RAM T at")
    print("     V + Delta(S+1 .. T-1)   [the load word itself is C-format: no post-inc]")
    print()
    targets = []
    if 45 in idx:
        targets.append(("dp@45 == 0x50 (unit-0 state base)", 45, 0x50))
    if 53 in idx:
        targets.append(("dp@53 == 0xD0 (unit-1 state base)", 53, 0xD0))
    for name, tgt, want in targets:
        print(f"  target: {name}")
        for s in sites:
            dsum = rec[idx[tgt]][3] - rec[idx[s]][5]
            need = (want - dsum) & 0xFF
            print(f"     load at I-RAM {s:3d}:  Delta({s}+1..{tgt}) = {dsum:+5d}"
                  f"   ==>  V must be {need:#04x} = {need:3d}")
        print()
    print("  the five words and every candidate field extraction:")
    print()
    allx = {}
    for s in sites:
        w = rec[idx[s]][2]
        allx[s] = extractions(w)
        print(f"     I-RAM {s:3d}  {w:010X}   "
              f"{D.hi12(w):03X}.{D.class4(w):X}.{D.addr8(w):02X}.{D.lo12(w):03X}"
              f"   imm13 = {(w >> 12) & 0x1FFF:5d} = {(w >> 12) & 0x1FFF:#06x}")
    print()
    names = sorted(allx[sites[0]].keys())
    print(f"     {'extraction':<20} " + "  ".join(f"w{s:<4d}" for s in sites))
    for n in names:
        print(f"     {n:<20} " + "  ".join(f"{allx[s][n]:#04x} " for s in sites))
    print()
    print("  ★ MATCHES (extraction value == the demanded V, for ANY site/target):")
    hits = 0
    for name, tgt, want in targets:
        for s in sites:
            dsum = rec[idx[tgt]][3] - rec[idx[s]][5]
            need = (want - dsum) & 0xFF
            for n in names:
                if allx[s][n] == need:
                    print(f"     HIT  site {s:3d}  target {name}  extraction {n!r}"
                          f"  = {need:#04x}")
                    hits += 1
    print(f"     total {hits} hit(s)")
    print()
    print("  ★ And the CLOSURE demand, for completeness: a load at S is the LAST")
    print("     one, so X = V + Delta(S+1..end).  That DEFINES X rather than")
    print("     constraining V -- printed to show the degeneracy explicitly:")
    for s in sites:
        tail = sum(r[4] for r in rec[idx[s]:])
        print(f"     load at I-RAM {s:3d}:  X = V + {tail:+5d}   (any V works)")


# ---------------------------------------------------------------------------
#  THE ADMISSIBLE-SITE COMPUTATION -- the real content of the closure constraint
# ---------------------------------------------------------------------------
#  A single ABSOLUTE reload at slot S makes closure automatic for ANY payload:
#      X = V + Delta(S+1 .. end).
#  So the closure equation does NOT determine V.  What it DOES determine is the
#  set of admissible SITES, because X is the address at which the two DI input
#  latches are read (ptr+2 / ptr+5, K6 finding 4) and the latches sit at FIXED
#  CHIP ADDRESSES -- so X cannot depend on which algorithm is loaded.
#
#      site in the shared kernel BEFORE the unit-0 call  ->  tail contains BOTH
#                                                            body nets
#      site between the two calls                        ->  tail contains the
#                                                            unit-1 body net
#      site after the unit-1 return (the epilogue)       ->  tail is kernel-only
#
#  ==> admissible iff every body net that the tail contains is CONSTANT over the
#      pool of algorithms that can occupy that unit.  That is a MEASUREMENT.
# ---------------------------------------------------------------------------
# RENAMED 2026-07-27: NOT malformed -- these are IC310 (MN19413) programs
# whose cmd-0x30 record rides on record opcode 3, so an IC311-shaped parser
# turns them into a phantom I-RAM block.  Algorithms 57-60 are IC310's too
# (their cmd-0x30 rides on opcode 0x0E and parses to nothing, so `if ir:'
# already drops them): the IC311 population is 91 of 100, not 95.
# See dsp/analysis/second-dsp-and-ready.md sect. 2.
DSP2_MISPARSED = {79, 88, 89, 90, 91}                 # dsp/verify.py
MALFORMED = DSP2_MISPARSED      # deprecated alias


def algo_images(E, rom):
    """{algo: (load_addr, [words])} for every well-formed algorithm stream."""
    out = {}
    for algo in range(N_ALGOS):
        if algo in MALFORMED:
            continue
        try:
            blocks = words_of(E, rom, rom.u32le(ALGO_TABLE + 4 * algo))
        except Exception:
            continue
        ws = [w for _a, b in blocks for w in b]
        if ws:
            out[algo] = (blocks[0][0], ws)
    return out


def body_net(ws):
    """Net D-RAM pointer displacement of a body image, and the same mod 256."""
    n = 0
    for w in ws:
        if D.ptr_postinc(w):
            n += s8(D.addr8(w))
    return n


def cmd_pools(args, rom, E):
    """Which algorithms can occupy which unit, and is each pool's net CONSTANT?"""
    imgs = algo_images(E, rom)
    pools = {}
    for algo, (load, ws) in sorted(imgs.items()):
        pools.setdefault(load, []).append((algo, ws))
    print("THE UNIT POOLS -- each algorithm stream hard-codes its own I-RAM load")
    print("address (PROVEN BY CONSTRUCTION: K5's bytecode rule), so the load")
    print("address IS the effect unit the algorithm can occupy.")
    print()
    for load in sorted(pools):
        rows = pools[load]
        nets = {}
        distinct = {}
        for algo, ws in rows:
            n = body_net(ws) & 0xFF
            nets.setdefault(n, []).append(algo)
            distinct.setdefault(tuple(ws), []).append(algo)
        unit = {UNIT0_ENTRY: "unit 0", UNIT1_ENTRY: "unit 1"}.get(load, "?")
        print(f"  load I-RAM {load:3d} ({unit}):  {len(rows)} algorithms,"
              f"  {len(distinct)} distinct images,  {len(nets)} distinct nets")
        for n in sorted(nets):
            a = nets[n]
            print(f"      net {n:+4d} (= {n - 256:+5d})  x{len(a):3d}   algos"
                  f" {a[:12]}{' ...' if len(a) > 12 else ''}")
        print(f"      ==> net is {'CONSTANT' if len(nets) == 1 else 'NOT CONSTANT'}"
              f" over this pool")
        print()


def cmd_sites(args, rom, E):
    """The admissible-site set: where CAN the frame-closing reload be?"""
    imgs = algo_images(E, rom)
    pools = {}
    for algo, (load, ws) in sorted(imgs.items()):
        pools.setdefault(load, []).append((algo, ws))
    n0 = sorted({body_net(ws) & 0xFF for _a, ws in pools.get(UNIT0_ENTRY, [])})
    n1 = sorted({body_net(ws) & 0xFF for _a, ws in pools.get(UNIT1_ENTRY, [])})

    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    rec, _end = walk(iram)
    # per-region delta of the SHARED kernel, slot-exact
    dk = {}
    for slot, pc, _raw, _d0, dl, _d1, _c in rec:
        if pc < 84:                       # a kernel/epilogue address
            dk[pc] = dl

    def ksum(lo, hi):
        return sum(dk.get(p, 0) for p in range(lo, hi + 1))

    print("ADMISSIBLE-SITE SET FOR THE FRAME-CLOSING D-RAM POINTER RELOAD")
    print()
    print(f"  unit-0 pool net (mod 256), distinct values: {n0}")
    print(f"  unit-1 pool net (mod 256), distinct values: {n1}")
    print()
    print("  shared-kernel per-region displacement (algorithm-independent):")
    print(f"      header  0..48 (before the unit-0 CALL at 49)  {ksum(0, 48):+4d}")
    print(f"      the unit-0 CALL word, I-RAM 49                {ksum(49, 49):+4d}")
    print(f"      header 50..58 (before the unit-1 CALL at 59)  {ksum(50, 58):+4d}")
    print(f"      the unit-1 CALL word, I-RAM 59                {ksum(59, 59):+4d}")
    print(f"      epilogue 60..81                               {ksum(60, 81):+4d}")
    print(f"      ------------------------------------------------")
    print(f"      kernel-only total                             {ksum(0, 81):+4d}")
    print()
    print("  For a reload at site S the tail is:")
    print()
    rowfmt = "      {:<26} {:<34} {}"
    print(rowfmt.format("site region", "tail Delta(S+1..end) contains",
                        "algorithm-independent?"))
    ok0 = len(n0) == 1
    ok1 = len(n1) == 1
    print(rowfmt.format("I-RAM  0..49 (pre-unit-0)", "BOTH body nets",
                        "YES" if (ok0 and ok1) else "NO"))
    print(rowfmt.format("I-RAM 50..59 (inter-body)", "the unit-1 body net",
                        "YES" if ok1 else "NO"))
    print(rowfmt.format("I-RAM 60..82 (epilogue)", "nothing but kernel words",
                        "YES (unconditionally)"))
    print()
    lo = 50 if (ok1 and not ok0) else (0 if (ok0 and ok1) else 60)
    print(f"  ==> ADMISSIBLE SITES: I-RAM >= {lo}")
    five = (15, 22, 29, 31, 40)
    print(f"  ==> the five `lo12 = 0x820' words are at I-RAM {five} --"
          f" {'ALL EXCLUDED' if max(five) < lo else 'not excluded'}")
    print()
    print("  the reload-site candidates that survive, with their tails:")
    for pc in sorted(dk):
        if pc < lo:
            continue
        w = iram[pc]
        if D.lo12(w) & 0xF00 != 0x800 and not D.c_format(w):
            continue
        tail = ksum(pc + 1, 81) + (
            (n1[0] if ok1 else 0) if pc < 59 else 0)
        print(f"      I-RAM {pc:3d}  {w:010X}  "
              f"{D.hi12(w):03X}.{D.class4(w):X}.{D.addr8(w):02X}.{D.lo12(w):03X}"
              f"   tail {tail:+4d}   ==>  X = V {tail:+d}"
              f"  ==>  V = X {-tail:+d}")


def cmd_demand(args, rom, E):
    """What payload does each admissible site DEMAND, under each absolute anchor?"""
    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    rec, _end = walk(iram)
    idx = {}
    for i, r in enumerate(rec):
        idx.setdefault(r[1], i)
    dk = {}
    for _slot, pc, _raw, _d0, dl, _d1, _c in rec:
        if pc < 84:
            dk[pc] = dl

    def ksum(lo, hi):
        return sum(dk.get(p, 0) for p in range(lo, hi + 1))

    imgs = algo_images(E, rom)
    n1 = sorted({body_net(ws) & 0xFF
                 for a, (load, ws) in imgs.items() if load == UNIT1_ENTRY})

    print("THE DEMANDED PAYLOAD -- closure alone does NOT pin V; an ABSOLUTE")
    print("anchor does.  Two are on the table, both conditional; both printed.")
    print()
    anchors = [
        ("A1  dp@I-RAM 45 == 0x50 (unit-0 state-block base, mode-1==mode-2 OPEN)",
         (0x50 - rec[idx[45]][3]) & 0xFF),
        ("A2  dp@I-RAM 53 == 0xD0 (unit-1 state-block base, same premise)",
         (0xD0 - rec[idx[53]][3]) & 0xFF),
    ]
    for name, x in anchors:
        print(f"  {name}")
        print(f"      ==> X = {x:#04x} = {x:3d}")
    print()
    for name, x in anchors:
        print(f"  under {name.split()[0]} (X = {x:#04x}):")
        for pc in sorted(dk):
            w = iram[pc]
            if not (D.lo12(w) & 0xF00 == 0x800 or D.c_format(w)):
                continue
            tail = ksum(pc + 1, 81) + ((n1[0] if len(n1) == 1 else 0)
                                       if 50 <= pc < 59 else 0)
            v = (x - tail) & 0xFF
            ex = extractions(w)
            hit = [k for k, val in ex.items() if val == v]
            print(f"      I-RAM {pc:3d}  {w:010X}  lo12={D.lo12(w):03X}"
                  f"  tail {tail:+4d}  ==> V must be {v:#04x} = {v:3d}"
                  f"   {'HIT: ' + ', '.join(hit) if hit else ''}")
        print()


# ---------------------------------------------------------------------------
#  IS THE FAILURE ROBUST TO THE WALK MODEL?  (it must be, or it proves nothing)
# ---------------------------------------------------------------------------
VARIANTS = {
    "V0 baseline: (not C-format) and class4&7 == 2":
        lambda w: D.ptr_postinc(w),
    "V1 class4 == 2 only (class A does NOT move the pointer)":
        lambda w: (not D.c_format(w)) and D.class4(w) == 2,
    "V2 C-format words post-increment too":
        lambda w: (D.class4(w) & 7) == 2,
    "V3 END-tagged words do NOT post-increment":
        lambda w: D.ptr_postinc(w) and not D.is_end(w),
    "V4 ESCAPE words do NOT post-increment":
        lambda w: D.ptr_postinc(w) and not (D.hi12(w) & 0x800),
    "V5 accumulator-store (hi12 bit 4) words do NOT post-increment":
        lambda w: D.ptr_postinc(w) and not (D.hi12(w) & 0x10),
    #   ★★★ N-INPUT-GATE-OPENED sect. 98.  `addr8' is NEVER ZERO on classes 4, 6 and 8 -- 53 of
    #   53, 53 of 53, 44 of 44 -- and the model reads it on none of them.  The null is
    #   exceptionless in the one class where both kinds coexist: every class-0 word with a
    #   non-zero `addr8' is a register load whose `addr8' is its PAYLOAD (8 of 8), and every
    #   class-0 word without that use carries zero (100 of 100).  So the field is load-bearing
    #   there.  One of the two live readings is that it is the SAME pointer delta classes 2 and A
    #   carry; these rows test exactly that, against the two criteria this tool already applies.
    "V7 class 4 post-increments too":
        lambda w: D.ptr_postinc(w) or ((not D.c_format(w)) and D.class4(w) == 4),
    "V8 class 6 post-increments too":
        lambda w: D.ptr_postinc(w) or ((not D.c_format(w)) and D.class4(w) == 6),
    "V9 class 8 post-increments too":
        lambda w: D.ptr_postinc(w) or ((not D.c_format(w)) and D.class4(w) == 8),
    "V10 classes 4, 6 and 8 ALL post-increment (the delta reading)":
        lambda w: D.ptr_postinc(w) or ((not D.c_format(w)) and D.class4(w) in (4, 6, 8)),
    #   ★★★ sect. 100: the CROSS-CORPUS twin says classes 4 and 6 carry the SAME delta class 2
    #   does.  This is that pair alone -- class 8 (a cursor fetch with a CONSTANT addr8) excluded.
    "V12 classes 4 and 6 post-increment, class 8 does NOT":
        lambda w: D.ptr_postinc(w) or ((not D.c_format(w)) and D.class4(w) in (4, 6)),
    "V11 everything but the register-file classes 0/1/9 moves":
        lambda w: (not D.c_format(w)) and D.class4(w) not in (0, 1, 9),
}


def walk_var(iram, pred, cap=384, body_neutral=False):
    """walk() with a swappable post-increment predicate.

    body_neutral: the CALL/RETURN sequencer saves and restores the pointer, so a
    body's displacement never reaches the kernel (the `kernel-private pointer'
    hypothesis).  Implemented by rolling the pointer back on RETURN.
    """
    pc, sp, stack = 0, 0, [0, 0]
    dp, net = 0, 0
    saved = [0, 0]
    slot, end = 0, "cap"
    while slot < cap:
        if pc >= len(iram):
            end = "overrun"
            break
        raw = iram[pc]
        if raw == WAIT_WORD:
            end = "wait"
            break
        tagged = (D.is_end(raw) and D.class4(raw) == 1
                  and D.addr8(raw) in (0x0E, 0x0F))
        word = raw & ~(D.HI_END << 24) if tagged else raw
        if pred(word):
            d = s8(D.addr8(word))
            dp += d
            net += d
        pc += 1
        slot += 1
        if tagged:
            if sp == 0:
                saved[sp] = net
                stack[sp] = pc
                sp += 1
                pc = UNIT0_ENTRY if D.addr8(raw) == 0x0E else UNIT1_ENTRY
            else:
                sp -= 1
                if body_neutral:
                    net = saved[sp]
                pc = stack[sp]
    return net, slot, end


def cmd_variants(args, rom, E):
    """Does ANY plausible walk variant close the frame with no reload at all?"""
    imgs = algo_images(E, rom)
    print("IS THE CLOSURE FAILURE AN ARTEFACT OF THE WALK MODEL?")
    print()
    print("  Every row re-walks the SAME cold-boot frame with a different")
    print("  post-increment predicate, and re-measures the two things that")
    print("  matter: the frame residue (must be 0 mod 256) and whether each")
    print("  unit's pool of algorithms has a CONSTANT net (must be, or X is")
    print("  algorithm-dependent and the DI latches move).")
    print()
    print(f"  {'variant':<56} {'residue':>8}  {'u0 nets':>8} {'u1 nets':>8}  closes?")
    for name, pred in VARIANTS.items():
        iram, _ = build_iram(E, rom, args.unit0, args.unit1)
        net, _slots, _end = walk_var(iram, pred)
        n0, n1 = set(), set()
        for _a, (load, ws) in imgs.items():
            n = sum(s8(D.addr8(w)) for w in ws if pred(w)) & 0xFF
            (n0 if load == UNIT0_ENTRY else n1).add(n)
        print(f"  {name:<56} {net & 0xFF:+8d}  {len(n0):>8} {len(n1):>8}"
              f"   {'YES' if (net & 0xFF) == 0 else 'no'}")
    # and the structural variant: the sequencer saves/restores the pointer
    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    net, _s, _e = walk_var(iram, D.ptr_postinc, body_neutral=True)
    print(f"  {'V6 CALL/RETURN saves+restores the pointer (kernel-private)':<56}"
          f" {net & 0xFF:+8d}  {'n/a':>8} {'n/a':>8}   "
          f"{'YES' if (net & 0xFF) == 0 else 'no'}")
    print()
    print("  ==> if no row closes, a RE-ESTABLISHING MECHANISM is FORCED and the")
    print("      conclusion does not depend on which walk variant is right.")


def cmd_window(args, rom, E):
    """Do the bodies WRITE INTO the kernel's I/O window under a SHARED pointer?

    K6 finding 4 (MEASURED+FORCED): X+2 and X+5 are read and never written -- they
    are the two audio input latches.  K6 finding 5 measured `0 of 38 body images
    touch X+0..X+6' using each body's OWN relative offsets.  Under the completed
    walk the pointer is SHARED across the CALL boundary, so a body's cells land at
    (entry + offset) mod 256 and CAN collide.  If they do, the shared-pointer model
    is what is wrong -- not a missing load.
    """
    imgs = algo_images(E, rom)
    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    rec, _end = walk(iram)
    dk = {}
    for _slot, pc, _raw, _d0, dl, _d1, _c in rec:
        if pc < 84:
            dk[pc] = dl

    def ksum(lo, hi):
        return sum(dk.get(p, 0) for p in range(lo, hi + 1))

    entry0 = ksum(0, 49)                       # pointer at unit-0 body entry, rel X
    print("DOES A BODY LAND IN THE KERNEL'S I/O WINDOW?  (shared-pointer test)")
    print()
    print(f"  unit-0 body entry = X {entry0:+d};  unit-1 body entry ="
          f" X {entry0:+d} + net(body0) + {ksum(50, 59):+d}")
    print("  kernel I/O window = X+0 .. X+6;  the two INPUT LATCHES = X+2, X+5")
    print()
    hit_win, hit_latch, tot = 0, 0, 0
    per = []
    for algo, (load, ws) in sorted(imgs.items()):
        if load != UNIT0_ENTRY:
            continue
        p = entry0
        cells = set()
        for w in ws:
            if D.ptr_postinc(w):
                cells.add(p & 0xFF)
                p += s8(D.addr8(w))
        tot += 1
        win = sorted(c for c in cells if c <= 6)
        latch = [c for c in win if c in (2, 5)]
        if win:
            hit_win += 1
        if latch:
            hit_latch += 1
        per.append((algo, len(cells), win, latch))
    print(f"  UNIT-0 POOL, {tot} algorithms:")
    print(f"     images whose walk enters X+0..X+6 : {hit_win} of {tot}")
    print(f"     images that touch an INPUT LATCH  : {hit_latch} of {tot}")
    shown = 0
    for algo, n, win, latch in per:
        if win and shown < 14:
            print(f"       algo {algo:3d}  {n:3d} cells   window hits {win}"
                  f"   {'LATCH ' + str(latch) if latch else ''}")
            shown += 1
    # unit 1: entry depends on which unit-0 body ran
    u1 = [(a, ws) for a, (load, ws) in sorted(imgs.items()) if load == UNIT1_ENTRY]
    u0nets = sorted({sum(s8(D.addr8(w)) for w in ws if D.ptr_postinc(w))
                     for a, (load, ws) in imgs.items() if load == UNIT0_ENTRY})
    print()
    print(f"  UNIT-1 POOL ({len(u1)} algorithms, 1 distinct image), evaluated at every")
    print(f"  possible entry (one per distinct unit-0 net, {len(u0nets)} of them):")
    for n0 in u0nets:
        p0 = (entry0 + n0 + ksum(50, 59))
        _a, ws = u1[0]
        p = p0
        cells = set()
        for w in ws:
            if D.ptr_postinc(w):
                cells.add(p & 0xFF)
                p += s8(D.addr8(w))
        win = sorted(c for c in cells if c <= 6)
        latch = [c for c in win if c in (2, 5)]
        print(f"     unit-0 net {n0:+5d} -> unit-1 entry X{p0 - 0:+5d}"
              f"  ({len(cells)} cells)  window hits {win}"
              f"   {'LATCH ' + str(latch) if latch else ''}")


def cmd_fields(args, rom, E):
    """EXHAUSTIVE contiguous-bit-field search over the five `lo12 = 0x820' words.

    The closure constraint excludes them as the frame-closing D-RAM pointer load
    (see `sites'), so it cannot solve their payload.  What CAN be done cheaply is
    to enumerate every contiguous field of the 36-bit word and score the five
    values it yields against the structural predicates the header offers.  Every
    predicate has a stated NULL so a hit can be priced.
    """
    iram, _ = build_iram(E, rom, args.unit0, args.unit1)
    sites = [15, 22, 29, 31, 40]
    ws = [iram[s] for s in sites]
    # header block structure: an END-OF-BLOCK word ends its block
    ends = [i for i in range(60) if D.is_end(iram[i])]
    starts = [0] + [e + 1 for e in ends if e + 1 < 60]
    print("THE FIVE `lo12 = 0x820' WORDS -- exhaustive contiguous-field search")
    print()
    for s, w in zip(sites, ws):
        print(f"   I-RAM {s:3d}  {w:010X}   "
              f"{D.hi12(w):03X}.{D.class4(w):X}.{D.addr8(w):02X}.{D.lo12(w):03X}")
    print()
    print(f"   header END-OF-BLOCK words : {ends}")
    print(f"   header BLOCK STARTS       : {starts}")
    print()

    def own_block_end(site):
        for e in ends:
            if e >= site:
                return e
        return None

    preds = {
        "all five < 60 (an I-RAM address inside the header)":
            (lambda v: all(x < 60 for x in v), (60 / 256) ** 5),
        "all five are END+1":
            (lambda v: all(x in [e + 1 for e in ends] for x in v),
             (len(ends) / 256) ** 5),
        "all five are a BLOCK START":
            (lambda v: all(x in starts for x in v), (len(starts) / 256) ** 5),
        "all five are their OWN block's end":
            (lambda v: all(x == own_block_end(s) for s, x in zip(sites, v)), None),
        "all five are their OWN block's end + 1":
            (lambda v: all(x == own_block_end(s) + 1 for s, x in zip(sites, v)), None),
        "all five are a multiple of 32 (K5's C40-family rule)":
            (lambda v: all(x % 32 == 0 for x in v), (1 / 32) ** 5),
        "all five DISTINCT and > 0":
            (lambda v: len(set(v)) == 5 and min(v) > 0, None),
    }
    results = {k: [] for k in preds}
    seen = {}
    for lsb in range(0, 33):
        for width in range(4, 14):
            if lsb + width > 36:
                continue
            mask = (1 << width) - 1
            v = tuple((w >> lsb) & mask for w in ws)
            key = v
            name = f"bits[{lsb + width - 1}:{lsb}]"
            if key in seen:
                continue
            seen[key] = name
            for pname, (fn, _null) in preds.items():
                if fn(list(v)):
                    results[pname].append((name, v))
    for pname, (fn, null) in preds.items():
        hits = results[pname]
        nul = f"  (null per field ~ {null:.2e})" if null else ""
        print(f"   {pname}{nul}")
        if not hits:
            print("       -- no contiguous field satisfies it --")
        for name, v in hits[:10]:
            print(f"       {name:<14} {list(v)}")
        if len(hits) > 10:
            print(f"       ... and {len(hits) - 10} more")
        print()
    print("   for the record, the fields the two published readings use:")
    for name, lsb, width in (("addr8  bits[19:12]", 12, 8),
                             ("imm13  bits[24:12]", 12, 13),
                             ("K5 'A' bits[24:17]", 17, 8),
                             ("K5 'B' bits[16:12]", 12, 5)):
        print(f"       {name:<20} {[(w >> lsb) & ((1 << width) - 1) for w in ws]}")


def cmd_cells(args, rom, E):
    """How many DISTINCT D-RAM cells does each body touch under the walk?"""
    print("BODY WALK vs the host's own zero-fill block length")
    print()
    print("  A body's D-RAM state is what the host zero-fills before loading it")
    print("  (isa-adjudication.md sect. 5: a CONTIGUOUS block based at 0x50 / 0xD0,")
    print("  87 of 91 streams; length 3 in all twelve reverbs).  If the modelled")
    print("  pointer walk of a body visits far more distinct cells than that, the")
    print("  walk model -- not a missing pointer load -- is what is wrong.")
    print()
    print(f"  {'algo':>4}  {'words':>5}  {'load':>4}  {'net':>6}  {'span':>5}"
          f"  {'distinct':>8}  {'min':>5} {'max':>5}")
    rows = []
    for algo in range(N_ALGOS):
        try:
            blocks = words_of(E, rom, rom.u32le(ALGO_TABLE + 4 * algo))
        except Exception:
            continue
        ws = [w for _a, b in blocks for w in b]
        if not ws:
            continue
        load = blocks[0][0]
        p, lo, hi, seen = 0, 0, 0, set()
        for w in ws:
            if D.ptr_postinc(w):
                seen.add(p)
                p += s8(D.addr8(w))
                lo, hi = min(lo, p), max(hi, p)
        rows.append((algo, len(ws), load, p, hi - lo, len(seen), lo, hi))
    for r in rows:
        print(f"  {r[0]:>4}  {r[1]:>5}  {r[2]:>4}  {r[3]:>+6}  {r[4]:>5}"
              f"  {r[5]:>8}  {r[6]:>+5} {r[7]:>+5}")
    print()
    nets = [r[3] for r in rows]
    print(f"  bodies with net == 0: {sum(1 for n in nets if n == 0)} of {len(nets)}")
    print(f"  net range: {min(nets)} .. {max(nets)}")


def cmd_corpus(args, rom, E):
    """Every `lo12 = 0x820' word (and the 0x82x block) across the whole corpus."""
    streams = [("header", HEADER_ROM), ("epilogue", EPILOGUE_ROM)]
    imgs = {}
    for name, addr in streams:
        for a, ws in words_of(E, rom, addr, limit=40):
            imgs[name] = (a, ws)
    algos = {}
    for algo in range(N_ALGOS):
        try:
            blocks = words_of(E, rom, rom.u32le(ALGO_TABLE + 4 * algo))
        except Exception:
            continue
        ws = [w for _a, b in blocks for w in b]
        if ws:
            algos[algo] = (blocks[0][0], ws)
    print("THE 0x82x SELECTOR BLOCK ACROSS THE CORPUS")
    print()
    for name, (a, ws) in imgs.items():
        for i, w in enumerate(ws):
            lo = D.lo12(w)
            if (lo & 0xFF0) == 0x820 or lo in (0x021, 0x839):
                print(f"  {name:<9} w{a + i:<3d} {w:010X}  "
                      f"{D.hi12(w):03X}.{D.class4(w):X}.{D.addr8(w):02X}.{lo:03X}"
                      f"   c_format={D.c_format(w)} is_c40={D.is_c40(w)}"
                      f"   imm13={(w >> 12) & 0x1FFF}")
    hits = {}
    for algo, (a, ws) in algos.items():
        for i, w in enumerate(ws):
            lo = D.lo12(w)
            if (lo & 0xFF0) == 0x820 or lo in (0x021, 0x839):
                hits.setdefault(w, []).append((algo, a + i))
    print()
    print(f"  body occurrences of the whole 0x_2x block: {sum(len(v) for v in hits.values())}")
    for w, sites in sorted(hits.items()):
        print(f"    {w:010X}  {len(sites)} site(s): {sites[:6]}")
    print()
    print("  every C-FORMAT word in the kernel (hi12[11:8] == 0xC):")
    for name, (a, ws) in imgs.items():
        for i, w in enumerate(ws):
            if D.c_format(w):
                imm = (w >> 12) & 0x1FFF
                print(f"    {name:<9} w{a + i:<3d} {w:010X}  lo12={D.lo12(w):03X}"
                      f"  imm13={imm:5d}={imm:#06x}  mult32={'Y' if imm % 32 == 0 else 'n'}"
                      f"  is_c40={'Y' if D.is_c40(w) else 'n'}")


CMDS = {"walk": cmd_walk, "anchors": cmd_anchors, "solve": cmd_solve,
        "cells": cmd_cells, "corpus": cmd_corpus, "pools": cmd_pools,
        "sites": cmd_sites, "demand": cmd_demand,
        "variants": cmd_variants, "window": cmd_window,
        "fields": cmd_fields}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=sorted(CMDS))
    ap.add_argument("--sub", default=os.path.join(REPO, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--unit0", type=int, default=1, help="algo loaded at I-RAM 84")
    ap.add_argument("--unit1", type=int, default=16, help="algo loaded at I-RAM 200")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()
    rom, E = load_rom(args)
    CMDS[args.cmd](args, rom, E)


if __name__ == "__main__":
    main()
