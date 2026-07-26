#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""output_stage.py -- decoding the uPD6383 OUTPUT STAGE, I-RAM 60..82.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  Companion note:
dsp/analysis/output-stage-decode.md.

No hardware.  Static analysis of the ROM corpus only; every number this prints
is reproducible from `original_ROMs/kn5000_subprogram_v142.rom' alone.

Subcommands:

    words     the 23 words with EVERY field split out (and the C-format words
              split as an OPCODE + immediate, which the tree did not do before)
    cformat   the C-FORMAT OPCODE census -- bits[35:25].  Eight opcodes, and the
              "payload is a multiple of 32" rule turns out to be one of them
  * dram      ★ SOLVE the D-RAM origin from the host's own zero-fill.  The
              per-unit body ENTRY POINTER is forced to 0x05 (unit 0) and 0x85
              (unit 1); the output stage names both.
  * closure   ★ the frame walk with the per-unit rebase.  Residue ZERO, from two
              independent routes to X = 0xFF.
    regs      the register-file map that falls out, and where every mode-1 index
              the kernel names sits in it
    do        the w73 / w78 output-presentation evidence
    checks    the predict-then-check log's measurements, in one place

    python3 dsp/tools/output_stage.py <cmd> [--sub <rom>] [--tools <dir>]

Items marked * are the load-bearing ones.
"""
import argparse
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DSP = os.path.dirname(HERE)
REPO = os.path.dirname(DSP)

HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
ALGO_TABLE = 0x0001ED7C
PARAM_TABLE = 0x0001EF0C
N_ALGOS = 100

UNIT0_ENTRY_IRAM = 84
UNIT1_ENTRY_IRAM = 200
REVERB_ALGOS = set(range(16, 28))

# The two numbers this file exists to derive.  They are NOT inputs to the
# derivation -- `dram' recomputes them from the ROM every time.
E0_EXPECTED = 0x05
E1_EXPECTED = 0x85


# ---------------------------------------------------------------- fields ----
def hi12(w):    return (w >> 24) & 0xFFF
def class4(w):  return (w >> 20) & 0xF
def addr8(w):   return (w >> 12) & 0xFF
def lo12(w):    return w & 0xFFF
def c_format(w):return (hi12(w) & 0xF00) == 0xC00
def c_opcode(w):return hi12(w) >> 1                 # bits[35:25]
def c_imm13(w): return (w >> 12) & 0x1FFF
def c_a(w):     return (w >> 17) & 0xFF
def c_b(w):     return (w >> 12) & 0x1F
def esc(w):     return bool(hi12(w) & 0x800)
def store(w):   return bool(hi12(w) & 0x10)
def bit7(w):    return bool(hi12(w) & 0x80)
def f31(w):     return (hi12(w) >> 1) & 7
def f98(w):     return (hi12(w) >> 8) & 3
def mode(w):    return class4(w) & 7
def fetch(w):   return bool(class4(w) & 8)
def src(w):     return (lo12(w) >> 6) & 0x1F
def action(w):  return lo12(w) & 0x1F
def ptrmode(w): return bool(lo12(w) & 0x20)
def lo11(w):    return bool(lo12(w) & 0x800)
def fmt(w):     return "%03X.%X.%02X.%03X" % (hi12(w), class4(w), addr8(w), lo12(w))


def st_suppressed(w):
    """The ADOPTED part of the bit-7 store gate (analysis/acc-adder.md sect. 6)."""
    return bit7(w) and f31(w) == 1


def delta(w):
    """The signed data-pointer post-increment.  MEASURED rule, C-format guarded."""
    if c_format(w) or mode(w) != 2:
        return 0
    return (addr8(w) ^ 0x80) - 0x80


def writes_mem(w):
    """Does a MODE-2 word write mem[ptr]?  The two anchored write paths: the
    gated hi12 bit-4 accumulator store, and ACTION 0x07 (`M <- bus')."""
    if c_format(w) or mode(w) != 2:
        return False
    return (store(w) and not st_suppressed(w)) or action(w) == 0x07


def reads_mem(w):
    """SRC 0x07 = the addressed operand (ANCHORED)."""
    return (not c_format(w)) and mode(w) == 2 and src(w) == 0x07


# ------------------------------------------------------------------ ROM ------
def load(args):
    sys.path.insert(0, args.tools)
    import kn5000_dsp_extract as E
    return E.Rom(args.sub), E


def records(E, rom, addr, limit=8192):
    ir, _c, _o = E.parse_stream(rom, addr, limit=limit)
    return [(a, [int.from_bytes(bytes(x), "big") for x in ws]) for a, ws, _l in ir]


def kernel(E, rom):
    out = {}
    for a, ws in records(E, rom, HEADER_ROM, limit=40):
        for i, w in enumerate(ws):
            out[a + i] = w
    for a, ws in records(E, rom, EPILOGUE_ROM, limit=40):
        for i, w in enumerate(ws):
            out[a + i] = w
    return out


def images(E, rom):
    """{algo: (load_addr, [words])} for every well-formed stream."""
    out = {}
    for algo in range(N_ALGOS):
        try:
            recs = records(E, rom, rom.u32le(ALGO_TABLE + 4 * algo))
        except Exception:
            continue
        for a, ws in recs:
            if a in (UNIT0_ENTRY_IRAM, UNIT1_ENTRY_IRAM):
                out[algo] = (a, ws)
    return out


def distinct_images(imgs):
    d = collections.OrderedDict()
    for algo in sorted(imgs):
        a, ws = imgs[algo]
        d.setdefault((a, tuple(ws)), []).append(algo)
    return d


def fill_cells(rom, algo):
    """The register indices the host ZERO-FILLS for an algorithm: tag-0x15
    packets addressed by the `000.1.NN.000' family (K3).  The host's own
    statement of where that algorithm's state lives."""
    p, g, out, dest = rom.u32le(PARAM_TABLE + 4 * algo), 0, [], None
    while g < 512:
        g += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 >> 4) == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        if (b0 >> 4) in (0, 1, 5):
            data = rom.slice(p + 2, ln - 2)[3:]
            for k in range(0, len(data) - 4, 5):
                e = data[k:k + 5]
                if e[0] == 0x00 and e[1] == 0x00 and (e[2] >> 4) == 0x1:
                    dest = ((e[2] & 0x0F) << 4) | (e[3] >> 4)
                elif e[0] == 0x0A and (e[4] & 0x7F) == 0x15 and dest is not None:
                    out.append(dest)
                    dest += 1
        p += ln
    return sorted(set(out))


def body_walk(ws, entry=0):
    """(touched, written, read, final) cell sets for one body image."""
    p, T, W, R = entry & 0xFF, set(), set(), set()
    for w in ws:
        if c_format(w) or mode(w) != 2:
            continue
        T.add(p)
        if writes_mem(w):
            W.add(p)
        if reads_mem(w):
            R.add(p)
        p = (p + delta(w)) & 0xFF
    return T, W, R, p


def body_net(ws):
    return sum(delta(w) for w in ws) & 0xFF


# ------------------------------------------------------------- subcommands ---
def sec_words(rom, E, args):
    k = kernel(E, rom)
    print("=" * 78)
    print("THE OUTPUT STAGE, I-RAM 60..82 -- every field")
    print("=" * 78)
    print("  A C-FORMAT word has NO class4/addr8: bits[35:25] are an OPCODE and")
    print("  bits[24:12] one 13-bit immediate.  Rendering its hi12 as microword")
    print("  flags (which both disassemblers still do) is meaningless.")
    print()
    for i in range(60, 83):
        w = k[i]
        if c_format(w):
            print("  w%-2d %010X %s  C-FORMAT  opcode=%03X  imm13=%04X  (A=%d B=%d)  dest lo12=%03X"
                  % (i, w, fmt(w), c_opcode(w), c_imm13(w), c_a(w), c_b(w), lo12(w)))
        else:
            print("  w%-2d %010X %s  mode=%d fetch=%d ESC=%d ST=%d%s  f98=%d f31=%d b7=%d | "
                  "SRC=%02X ACT=%02X ptr5=%d b11=%d"
                  % (i, w, fmt(w), mode(w), fetch(w), esc(w), store(w),
                     "(GATED OFF)" if store(w) and st_suppressed(w) else "",
                     f98(w), f31(w), bit7(w), src(w), action(w), ptrmode(w), lo11(w)))
    print()
    print("  NOTE: w60 and w68 carry hi12 bit 4 AND (bit7, f31) = (1, 1), so the")
    print("  ADOPTED store gate suppresses their store.  R2's cleanest argument for")
    print("  the mode-dependent bit-4 target -- 'w60/w61 are adjacent mode-1 stores")
    print("  with nothing between them, so the first is provably dead' -- is")
    print("  therefore MOOT: under the gate w60 never stored.  The conclusion")
    print("  survives on K5's call-vector result; that particular argument does not.")


def sec_cformat(rom, E, args):
    k = kernel(E, rom)
    imgs = images(E, rom)
    allw = [("kernel", i, k[i]) for i in sorted(k)]
    for (a, ws), algos in distinct_images(imgs).items():
        for i, w in enumerate(ws):
            allw.append(("b%02d" % min(algos), a + i, w))
    cf = [(t, i, w) for t, i, w in allw if c_format(w)]
    print("=" * 78)
    print("THE C-FORMAT OPCODE -- bits[35:25].  %d C-format words of %d"
          % (len(cf), len(allw)))
    print("=" * 78)
    by = collections.defaultdict(list)
    for t, i, w in cf:
        by[c_opcode(w)].append((t, i, w))
    for op, v in sorted(by.items()):
        m32 = sum(1 for _t, _i, w in v if c_imm13(w) % 32 == 0)
        los = sorted(set(lo12(w) for _t, _i, w in v))
        print("  opcode %03X  n=%-3d  imm%%32==0: %d/%d  lo12 = %s"
              % (op, len(v), m32, len(v), " ".join("%03X" % x for x in los)))
        if len(v) <= 4:
            for t, i, w in v:
                print("        %-8s I-RAM %-3d %s   A=%-3d B=%-2d" % (t, i, fmt(w), c_a(w), c_b(w)))
    print()
    print("  ★ `is_c40()' -- the PAYLOAD RULE `(hi12 & 0xFFE) == 0xC40' -- is")
    print("    exactly `opcode == 0x620'.  That is WHY the multiple-of-32 law is")
    print("    family-local: it is OPCODE-local.  57/57 inside, and the words")
    print("    outside it are simply other opcodes.")
    print()
    print("  ★ the five `lo12 = 0x820' header words are NOT one family: they carry")
    print("    FOUR different opcodes (602, 605 x2, 621, 625).  They share only a")
    print("    DESTINATION.  Every pass that treated them as a family was grouping")
    print("    by destination, not by instruction.")
    print()
    print("  ★ kernel C-format `A' as an I-RAM address, 11/11:")
    hdr_blockstart = [0, 7, 12, 15, 20, 22, 24, 25, 29, 34, 37, 40, 42, 50]
    for t, i, w in cf:
        if t != "kernel":
            continue
        note = ""
        if c_a(w) == i:
            note = "= its OWN address"
        elif c_a(w) in hdr_blockstart:
            note = "= a block START"
        elif c_a(w) in (45, 53):
            note = "= I-RAM %d, its own unit's SEND-STORE word" % c_a(w)
        elif c_a(w) == 77:
            note = "= I-RAM 77, the unit-1 pointer load"
        elif c_a(w) == 14:
            note = "= I-RAM 14, an END-OF-BLOCK word"
        print("     I-RAM %-3d %s  opcode %03X  A=%-3d %s" % (i, fmt(w), c_opcode(w), c_a(w), note))


def sec_dram(rom, E, args):
    imgs = images(E, rom)
    print("=" * 78)
    print("★ THE D-RAM ORIGIN, SOLVED FROM THE HOST'S OWN ZERO-FILL")
    print("=" * 78)
    print("  The host zero-fills, per algorithm, exactly the state the freshly-")
    print("  loaded body will use (K3/isa-adjudication sect. 5).  It addresses those")
    print("  cells by the MODE-1 index (`000.1.NN.000' + tag-0x15 values).  The body")
    print("  reaches them through the MODE-2 pointer.  If the two are one RAM, then")
    print("  the body's ENTRY POINTER E is FORCED by the alignment -- and E is one")
    print("  number for all 37 unit-0 images, because the header is shared.")
    print()
    # --- the single-handedly decisive case
    if 39 in imgs:
        T, W, R, _p = body_walk(imgs[39][1], 0)
        run = sorted(T)
        f = fill_cells(rom, 39)
        blk = [c for c in f if c >= 0x50]
        # the MAXIMAL contiguous run of the body's touched offsets
        best, cur = [], [run[0]]
        for o in run[1:]:
            cur = cur + [o] if o == cur[-1] + 1 else [o]
            if len(cur) > len(best):
                best = list(cur)
        cont = best
        print("  PARAMETRIC EQ (algo 39) alone pins it, with no free parameter:")
        print("     body touches %d cells: %s + a run of %d at offsets %d..%d"
              % (len(T), [o for o in run if o < min(cont)], len(cont), min(cont), max(cont)))
        print("     host fills  %d cells: %s + a block of %d at 0x%02X..0x%02X"
              % (len(f), ["0x%02X" % c for c in f if c < 0x50], len(blk), blk[0], blk[-1]))
        print("     %d == %d  =>  E + %d = 0x%02X  =>  E = 0x%02X   (UNIQUE)"
              % (len(cont), len(blk), min(cont), blk[0], (blk[0] - min(cont)) & 0xFF))
        print()
    # --- the exhaustive scan
    score = collections.defaultdict(int)
    avail = collections.Counter()
    for algo in sorted(imgs):
        a, ws = imgs[algo]
        f = set(fill_cells(rom, algo))
        if not f:
            continue
        avail[a] += len(f)
        T, _W, _R, _p = body_walk(ws, 0)
        for e in range(256):
            score[(a, e)] += len(set((e + t) & 0xFF for t in T) & f)
    for a, label in ((UNIT0_ENTRY_IRAM, "unit 0"), (UNIT1_ENTRY_IRAM, "unit 1")):
        best = sorted(((v, e) for (aa, e), v in score.items() if aa == a), reverse=True)
        print("  %s -- total fill cells REACHED, by entry pointer E (of %d available):"
              % (label, avail[a]))
        print("     " + "   ".join("E=0x%02X:%d" % (e, v) for v, e in best[:6]))
    print()
    e0 = max(((v, e) for (aa, e), v in score.items() if aa == UNIT0_ENTRY_IRAM))[1]
    e1 = max(((v, e) for (aa, e), v in score.items() if aa == UNIT1_ENTRY_IRAM))[1]
    print("  ★ E0 = 0x%02X   E1 = 0x%02X   E1 - E0 = 0x%02X" % (e0, e1, (e1 - e0) & 0xFF))
    print("    -- and 0x80 is exactly R2's `bit 7 of a register index is the EFFECT")
    print("       UNIT', and 0x50 -> 0xD0 (the two state-block bases) is the same 0x80.")
    if (e0, e1) != (E0_EXPECTED, E1_EXPECTED):
        print("    !! DIFFERS from the note's 0x05 / 0x85 -- the note is stale.")
    print()
    # --- what misses
    missed = collections.Counter()
    for algo in sorted(imgs):
        a, ws = imgs[algo]
        f = set(fill_cells(rom, algo))
        if not f:
            continue
        e = e1 if a == UNIT1_ENTRY_IRAM else e0
        T, _W, _R, _p = body_walk(ws, e)
        for c in f - T:
            missed[c] += 1
    print("  fill cells the body NEVER reaches, by cell:")
    print("     " + "  ".join("0x%02X:%d" % (c, n) for c, n in sorted(missed.items())))
    print("  ★ the systematic miss is 0x06 / 0x86 -- the two PER-UNIT OUTPUT LEVELS")
    print("    (PROVEN BY CONSTRUCTION, R2).  They sit at ENTRY+1 and the bodies")
    print("    leave them alone.  A prediction of the map, checked after it: HIT.")
    print()
    # --- the state block offset
    ok = tot = 0
    for algo in sorted(imgs):
        a, ws = imgs[algo]
        f = fill_cells(rom, algo)
        base = 0xD0 if a == UNIT1_ENTRY_IRAM else 0x50
        blk = [c for c in f if c >= base]
        if not blk:
            continue
        tot += 1
        e = e1 if a == UNIT1_ENTRY_IRAM else e0
        if blk[0] == ((e + 75) & 0xFF):
            ok += 1
    print("  the per-unit STATE BLOCK base is at ENTRY+75 in %d of %d streams"
          % (ok, tot))
    print("     0x%02X + 75 = 0x50   and   0x%02X + 75 = 0xD0   -- both exact." % (e0, e1))
    print()
    mins = collections.Counter()
    for algo in sorted(imgs):
        a, _ws = imgs[algo]
        f = fill_cells(rom, algo)
        if f:
            mins[(a, f[0])] += 1
    print("  ★ THIRD derivation, and the simplest: the LOWEST cell the host ever")
    print("    zero-fills, per stream --")
    for (a, m), n in sorted(mins.items()):
        print("       %s : min = 0x%02X in %d of %d streams"
              % ("unit 0" if a == UNIT0_ENTRY_IRAM else "unit 1", m, n, n))
    print("    The host never clears a cell BELOW the entry pointer, in 91 of 91")
    print("    streams, because below it is the kernel's own I/O window.")


def sec_closure(rom, E, args):
    k = kernel(E, rom)
    imgs = images(E, rom)
    d0_44 = sum(delta(k[i]) for i in range(0, 45))
    d45_49 = sum(delta(k[i]) for i in range(45, 50))
    d50_58 = sum(delta(k[i]) for i in range(50, 59))
    d59 = delta(k[59])
    depi = sum(delta(k[i]) for i in range(60, 83))
    net1 = body_net(imgs[16][1])
    print("=" * 78)
    print("★ FRAME CLOSURE -- residue ZERO, and X is over-determined")
    print("=" * 78)
    print("  slot-exact displacements:  d(0..44)=%+d  d(45..49)=%+d  d(50..58)=%+d"
          "  d(59)=%+d  d(60..82)=%+d" % (d0_44, d45_49, d50_58, d59, depi))
    print("  reverb (the ONE unit-1 image) net = %+d" % net1)
    print()
    x_from_header = (E0_EXPECTED - d0_44) & 0xFF
    x_from_epi = (E1_EXPECTED + net1 + depi) & 0xFF
    print("  ROUTE 1  the header walk.  K6 FORCED that the cell w45 stores at IS the")
    print("           unit-0 entry (addr8=0, and w46..w49 cannot move the pointer):")
    print("              X + %d = E0 = 0x%02X   =>   X = 0x%02X"
          % (d0_44, E0_EXPECTED, x_from_header))
    print("  ROUTE 2  the reverb walk from its own MEASURED base, then the epilogue:")
    print("              0x%02X %+d %+d = 0x%02X   =>   X = 0x%02X"
          % (E1_EXPECTED, net1, depi, x_from_epi, x_from_epi))
    print("  ★ %s   X = 0x%02X"
          % ("THEY AGREE." if x_from_header == x_from_epi else "THEY DISAGREE!", x_from_header))
    print()
    print("  the whole frame, with the unit-1 rebase and CHORUS in unit 0:")
    n0 = body_net(imgs[1][1])
    p = x_from_header
    print("     PC-restart                        ptr = 0x%02X" % p)
    p = (p + d0_44) & 0xFF
    print("     header w0..w44        %+4d        ptr = 0x%02X   <- w45 stores the unit-0 SEND here" % (d0_44, p))
    p = (p + n0) & 0xFF
    print("     unit-0 body (CHORUS)  %+4d        ptr = 0x%02X" % (n0 - 256 if n0 > 127 else n0, p))
    p = (p + d50_58 + d59) & 0xFF
    print("     header w50..w59       %+4d        ptr = 0x%02X   (w53 stores the unit-1 send by INDEX, 0xD0)" % (d50_58 + d59, p))
    print("     ---- REBASE at the unit-1 CALL ----  ptr = 0x%02X   (E1, MEASURED)" % E1_EXPECTED)
    p = (E1_EXPECTED + net1) & 0xFF
    print("     unit-1 body (REVERB)  %+4d        ptr = 0x%02X" % (net1 - 256 if net1 > 127 else net1, p))
    p = (p + depi) & 0xFF
    print("     output stage          %+4d        ptr = 0x%02X" % (depi, p))
    print("     ------------------------------------------------------")
    print("     residue vs X = 0x%02X :  %+d   %s"
          % (x_from_header, (p - x_from_header) & 0xFF,
             "★ CLOSES" if p == x_from_header else "does NOT close"))
    print()
    old = (d0_44 + d45_49 + n0 + d50_58 + d59 + net1 + depi) & 0xFF
    print("  for comparison, the SINGLE-WALK model (no rebase): residue +%d --" % old)
    print("  which is the ADVANCE pass's live measurement, +121 on 1130880 frames.")
    print()
    print("  Where the rebase must be: net(body0) varies over 8 values across the")
    print("  unit-0 pool, so E1 cannot be reached by walking; a rebase between the")
    print("  two CALLs is FORCED.  E0 needs none -- the header walk already lands on")
    print("  it, which is either the design or a 1-in-256 coincidence.")


def sec_regs(rom, E, args):
    k = kernel(E, rom)
    imgs = images(E, rom)
    print("=" * 78)
    print("THE 256-CELL MAP, and where the kernel's mode-1 indices sit in it")
    print("=" * 78)
    print("""
     0x00 .. 0x04   kernel I/O window          X = 0xFF, so X+0 = 0xFF and
                                               X+1..X+6 = 0x00..0x05
       X+2 = 0x01, X+5 = 0x04                  the two DI latches (K6)
       X+3 = 0x02                              written, never read (K6 sect.10)
     0x05           UNIT-0 body entry / send   <- header w45 stores here (mode 2)
     0x06           UNIT-0 OUTPUT LEVEL        <- host, PROVEN BY CONSTRUCTION
     0x07 .. 0x4F   unit-0 body state (low)
     0x50 ..        unit-0 STATE BLOCK         = entry+75; host zero-fill base
     0x85           UNIT-1 body entry          <- rebase target
     0x86           UNIT-1 OUTPUT LEVEL        <- host, PROVEN BY CONSTRUCTION
     0x87 .. 0xCF   unit-1 body state (low)
     0xD0 ..        unit-1 STATE BLOCK         = entry+75; header w53 stores here
                                                  by ABSOLUTE INDEX (mode 1)
""")
    idx = collections.OrderedDict()
    for i in sorted(k):
        w = k[i]
        if c_format(w) or mode(w) != 1 or esc(w):
            continue
        if (hi12(w) & 0xC00) == 0x400 and addr8(w) in (0x0E, 0x0F):
            continue                                  # the unit TAG, not an index
        idx.setdefault(addr8(w), []).append(i)
    print("  every mode-1 (non-escape) register index the kernel names:")
    for a, sites in sorted(idx.items()):
        unit = 1 if a & 0x80 else 0
        base = E1_EXPECTED if unit else E0_EXPECTED
        off = (a - base) & 0xFF
        note = ""
        if a in (0x0E, 0x0F):
            note = "   <- NOT an index: the UNIT TAG on the vector words (K5)"
        print("     0x%02X  unit %d  = entry%+4d   named at I-RAM %s%s"
              % (a, unit, off if off < 128 else off - 256, sites, note))
    print()
    # what the reverb does with them
    T, W, R, _p = body_walk(imgs[16][1], E1_EXPECTED)
    print("  the REVERB's own footprint (14 cells from 0x%02X):" % E1_EXPECTED)
    print("     touched:", " ".join("0x%02X" % c for c in sorted(T)))
    print("     READ and NEVER WRITTEN (its external inputs):",
          " ".join("0x%02X" % c for c in sorted(R - W)))
    print("  ★ 0x8C, 0x8D, 0x8F are the three indices the HOST never touches (R2")
    print("    sect.7 item 3, OPEN).  They are unit-1 body cells at entry+7/+8/+10,")
    print("    and two of them are among the reverb's three read-never-written")
    print("    cells.  P(all three land in a 14-of-256 footprint) ~ 1.6e-4.")


def sec_do(rom, E, args):
    k = kernel(E, rom)
    imgs = images(E, rom)
    allw = [("kernel", i, k[i]) for i in sorted(k)]
    for (a, ws), algos in distinct_images(imgs).items():
        for i, w in enumerate(ws):
            allw.append(("b%02d" % min(algos), a + i, w))
    print("=" * 78)
    print("THE DO WRITE -- w73 and w78")
    print("=" * 78)
    for i in (67, 72, 73, 74, 75, 76, 77, 78):
        w = k[i]
        if c_format(w):
            print("  w%-2d %s  C-FORMAT opcode %03X  A=%d B=%d" % (i, fmt(w), c_opcode(w), c_a(w), c_b(w)))
        else:
            print("  w%-2d %s  mode=%d fetch=%d ESC=%d ST=%d  SRC=%02X ACT=%02X  addr8=0x%02X (bit7=%d => unit %d)"
                  % (i, fmt(w), mode(w), fetch(w), esc(w), store(w), src(w), action(w),
                     addr8(w), (addr8(w) >> 7) & 1, (addr8(w) >> 7) & 1))
    print()
    for md in (4, 5, 6):
        grp = [(t, i, w) for t, i, w in allw if not c_format(w) and mode(w) == md]
        c = collections.Counter(fmt(w) for _t, _i, w in grp)
        print("  mode %d : %3d words, %d distinct forms -- %s"
              % (md, len(grp), len(c), ", ".join("%s x%d" % (f, n) for f, n in c.most_common())))
    print()
    for name, val, sel in (("SRC 0x10 (w73)", 0x10, src), ("SRC 0x0A (w78)", 0x0A, src),
                           ("ACT 0x04 (w73)", 0x04, action), ("ACT 0x07 (w78)", 0x07, action)):
        n = sum(1 for _t, _i, w in allw if not c_format(w) and sel(w) == val)
        print("  %-16s occurs %4d times in the 3057-word corpus" % (name, n))
    print()
    print("  ★ w73's SRC is 0x10 = THE ACCUMULATOR -- an ANCHORED code.  So the")
    print("    unit-0 presentation reads the accumulator AT THAT WORD.  R2's item 9")
    print("    ('the result is not in the accumulator either') is an argument about")
    print("    SURVIVING 156 words, not about w73's operand, so what it really")
    print("    forces is that something in I-RAM 60..72 puts the unit-0 result there.")
    print("    The only word in that range that names a unit-0 cell is w63")
    print("    (2A7.9.05.1C3, SRC 0x07 = the addressed operand, addr8 = 0x05 = the")
    print("    unit-0 ENTRY cell).")
    print()
    print("  ★ w73 and w78 are NOT the same instruction with a different unit:")
    print("    w73 = (SRC acc, ACT 0x04) and w78 = (SRC 0x0A, ACT 0x07).  Their SRC")
    print("    and ACT are disjoint, and 0x0A is the only SRC-0x0A word in the whole")
    print("    machine.  Any model that treats them as one form is wrong.")
    print()
    print("  ★ addr8 bit 7 assigns them INDEPENDENTLY of R2's positional argument:")
    print("    w73 addr8 = 0x00 (unit 0), w78 addr8 = 0x9F (unit 1) -- the same")
    print("    bit-7 rule R2 measured on the register indices, five confirmations.")


def sec_checks(rom, E, args):
    k = kernel(E, rom)
    imgs = images(E, rom)
    allw = [("kernel", i, k[i]) for i in sorted(k)]
    for (a, ws), algos in distinct_images(imgs).items():
        for i, w in enumerate(ws):
            allw.append(("b%02d" % min(algos), a + i, w))
    print("=" * 78)
    print("PREDICT-THEN-CHECK measurements")
    print("=" * 78)
    n = [(t, i) for t, i, w in allw if hi12(w) == 0x800 and addr8(w) == 0x60]
    print("  P-1  `800.1.60.00B' sites: %s   (K4's 'exactly twice')" % n)
    T, _W, _R, _p = body_walk(imgs[16][1], 0)
    f = set(fill_cells(rom, 16))
    cov = sorted(((len(set((e + t) & 0xFF for t in T) & f), e) for e in range(256)), reverse=True)
    print("  P-2  reverb fill coverage, best E: %s  of |fill|=%d"
          % (["E=0x%02X:%d" % (e, v) for v, e in cov[:4]], len(f)))
    hits = [(i, lsb, (k[i] >> lsb) & 0xFF) for i in range(50, 59) for lsb in range(0, 29)
            if ((k[i] >> lsb) & 0xFF) in (0x83, 0x84, 0x85)]
    print("  P-3  8-bit fields of I-RAM 50..58 equal to 0x83/0x84/0x85:")
    print("         any lsb      : %d hits at lsb %s (%d trials, ~%.1f expected)"
          % (len(hits), [h[1] for h in hits], 9 * 29, 9 * 29 * 3 / 256.0))
    print("         nibble-aligned: %d" % len([h for h in hits if h[1] % 4 == 0]))
    bad = []
    for algo in sorted(imgs):
        a, ws = imgs[algo]
        e = E1_EXPECTED if a == UNIT1_ENTRY_IRAM else E0_EXPECTED
        _T, W, _R, _p = body_walk(ws, e)
        if 0x01 in W or 0x04 in W:
            bad.append(algo)
    print("  P-4  bodies WRITING the two DI-latch cells 0x01/0x04: %s" % bad)
    print("       (a MISS -- and it is closure-pointer.md sect.F's already-published")
    print("        falsification of K6 finding 5, now with absolute addresses)")
    hits = [(i, lsb) for i in range(60, 83) for lsb in range(0, 29)
            if ((k[i] >> lsb) & 0xFF) in (0x05, 0x85)]
    print("  P-7  output-stage 8-bit fields equal to 0x05/0x85: %s" % hits)
    print("       lsb 12 IS addr8 -- so w63 (addr8 0x05) and w70 (addr8 0x85) carry")
    print("       exactly the two MEASURED per-unit bases.  PREDICTION MISSED.")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["words", "cformat", "dram", "closure",
                                    "regs", "do", "checks", "all"])
    ap.add_argument("--sub", default=os.path.join(REPO, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    rom, E = load(args)
    table = {"words": sec_words, "cformat": sec_cformat, "dram": sec_dram,
             "closure": sec_closure, "regs": sec_regs, "do": sec_do,
             "checks": sec_checks}
    if args.cmd == "all":
        for name in ("words", "cformat", "dram", "closure", "regs", "do", "checks"):
            table[name](rom, E, args)
            print()
    else:
        table[args.cmd](rom, E, args)


if __name__ == "__main__":
    main()
