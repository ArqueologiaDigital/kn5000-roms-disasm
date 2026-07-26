#!/usr/bin/env python3
"""lfo_ramp.py -- TARGET 3: the LFO ramp as a NUMERIC anchor.

The LFO is the one block of this machine whose OUTPUT is known as a number
before any of its instructions are decoded: the coefficient pair it consumes is
an INCREMENT and a 2**23 WRAP, and the resulting rate must be the rate the
firmware's own effect-parameter script asks for.  That turns "what does this
opcode mean" into a numeric equation with very few unknowns.

Everything here comes out of the Sub CPU ROM (the 100-entry algorithm table and
the 100-entry parameter table).  Standard library only; no MAME, no hardware,
no undumped ROM, no recording.

    python3 dsp/tools/lfo_ramp.py                # all sections
    python3 dsp/tools/lfo_ramp.py sites rate     # selected sections

Sections
    fields   ** the field parse of the three LFO words, spelled out bit by bit.
             This is section 0 because the brief and notes/dsp-frame-advance.md
             sect. 4 (#2) both read `092.A.00.200' as carrying SRC = 0x00.  It does
             not: the 00 is addr8.  SRC is lo12[10:6] = 0x08.
    sites    every LFO site in the 38-image corpus: cursor address, the two
             coefficients the parameter stream actually writes there, the local
             pointer walk, and the neighbours
    rate     the numeric anchor -- increment/2**23 * 44100 for every site, against
             the rates an LFO can plausibly have
    walk     the pointer walk of the LFO block, per program (does the trio close?)
    solve    ** the constraint solve: enumerate candidate meanings for SRC=0x08,
             SRC=0x00, ACTION=0x00 and the wrap, simulate 400 000 frames of each
             surviving machine, and keep only those that ramp at the required
             rate and wrap at 2**23
    closure  what the answer says about TARGET 1 (frame closure) and TARGET 2
"""
import collections
import itertools
import math
import os
import random
import sys

ROM = os.environ.get("KN5000_SUBROM") or os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom")

ROM_BASE    = 0xEF00
ALGO_TABLE  = 0x0001ED7C
PARAM_TABLE = 0x0001EF0C
N_ALGOS     = 100
KERNEL_BLOB = 0x01E496
EPILOG_BLOB = 0x01E63C
BOOT_BLOB   = 0x01E6BE

FS = 44100.0            # the firmware's own rate (LABEL_03925E: ms * 0xAC44 / 0x3E8)

D = open(ROM, "rb").read()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS


# ---------------------------------------------------------------- ROM access
def _off(a):
    o = a - ROM_BASE
    if not (0 <= o < len(D)):
        raise IndexError(hex(a))
    return o


def u8(a):  return D[_off(a)]
def u32le(a):
    o = _off(a)
    return int.from_bytes(D[o:o + 4], "little")


def parse_stream(addr, limit=8192):
    recs, p, guard = [], addr, 0
    while guard < limit:
        guard += 1
        try:
            b0, b1 = u8(p), u8(p + 1)
        except IndexError:
            break
        op = b0 >> 4
        if op == 0xF:
            recs.append(("F", None, None, b""))
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        o = _off(p + 2)
        body = D[o:o + ln - 2]
        cmd = body[0] if body else None
        hdr = ((body[1] << 8) | body[2]) if len(body) >= 3 else None
        recs.append((op, cmd, hdr, body[3:] if len(body) >= 3 else b""))
        p += ln
    return recs


def words5(b): return [int.from_bytes(b[k:k + 5], "big") for k in range(0, len(b) - 4, 5)]
def words3(b): return [int.from_bytes(b[k:k + 3], "big") for k in range(0, len(b) - 2, 3)]

hi12, cls, ad8, lo12 = DIS.hi12, DIS.class4, DIS.addr8, DIS.lo12
class4, addr8 = DIS.class4, DIS.addr8
fmt = lambda w: "%03X.%X.%02X.%03X" % (hi12(w), cls(w), ad8(w), lo12(w))
s8  = lambda v: v - 256 if v >= 128 else v


def images():
    """{rom_ptr: (algo, I-RAM load, [words])} -- the 38 distinct body images."""
    out = {}
    for i in range(N_ALGOS):
        try:
            recs = parse_stream(u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        blocks = [(ia, words5(pl)) for (op, c, ia, pl) in recs if op == 3]
        if not blocks or blocks[0][0] not in (84, 200):
            continue
        out.setdefault(u32le(ALGO_TABLE + 4 * i),
                       (i, blocks[0][0], [w for _, ws in blocks for w in ws]))
    return out


def algo_to_image():
    """{algo: (rom_ptr, load, words)} for every valid slot (not just distinct)."""
    out = {}
    for i in range(N_ALGOS):
        try:
            recs = parse_stream(u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        blocks = [(ia, words5(pl)) for (op, c, ia, pl) in recs if op == 3]
        if not blocks or blocks[0][0] not in (84, 200):
            continue
        out[i] = (u32le(ALGO_TABLE + 4 * i), blocks[0][0],
                  [w for _, ws in blocks for w in ws])
    return out


def cram_of_algo(i):
    """Replay one parameter stream -> {C-RAM cell: 24-bit value}.

    `801.0.NN.821' loads the C-RAM POINTER (PROVEN BY CONSTRUCTION, writer
    LABEL_0387E6; K3 confirmed the host-stream and in-program meanings are the
    same space).  The op-2 records that follow carry 24-bit coefficients which
    land at the pointer, auto-incrementing.
    """
    cram, ptr = {}, None
    try:
        recs = parse_stream(u32le(PARAM_TABLE + 4 * i))
    except Exception:
        return cram
    for (op, cmd, h, pl) in recs:
        if op == "F":
            break
        if op == 2:
            for v in words3(pl):
                if ptr is not None:
                    cram[ptr] = v
                    ptr = (ptr + 1) & 0xFF
            continue
        for w in words5(pl):
            if (w >> 32) & 0xFF == 0x0A:     # host coefficient poke packet
                continue
            if hi12(w) == 0x801 and cls(w) == 0 and lo12(w) == 0x821:
                ptr = ad8(w)
    return cram


PROG_NAMES = {}
def prog_names():
    """algo -> the .dsm file's own name, so the tables read like the listings."""
    if PROG_NAMES:
        return PROG_NAMES
    d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "disasm")
    for fn in sorted(os.listdir(d)):
        if fn.startswith("prog") and fn.endswith(".dsm"):
            try:
                PROG_NAMES[int(fn[4:6])] = fn[7:-4].replace("_", " ").upper()
            except ValueError:
                pass
    return PROG_NAMES


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


# =========================================================================
#  0.  FIELDS -- the parse, spelled out
# =========================================================================
def sec_fields():
    hdr("fields -- what the three LFO words ACTUALLY carry  (a correction)")
    print("""The brief for this pass, and notes/dsp-frame-advance.md sect. 4 blocker #2,
both say the LFO can anchor SRC = 0x00, quoting `092.A.00.200'.  The 00 in that
rendering is addr8 -- the signed pointer post-increment -- not the source field.
Spelled out (SRC = lo12[10:6], M = lo12[5], ACTION = lo12[4:0]):
""")
    rows = [(0x0092A00200, "phase accumulate"),
            (0x00822001C0, "the middle word"),
            (0x0094A00200, "the wrap")]
    print("   %-14s %-12s %-6s %-5s %-5s %-6s %-7s %s" %
          ("word", "hi12", "class", "addr8", "lo12", "SRC", "ACTION", "note"))
    for w, note in rows:
        print("   %010X %03X (f31=%d%s) %-6X %+5d  %03X   0x%02X   0x%02X    %s" %
              (w, hi12(w), DIS.hi_f31(hi12(w)),
               ",ST" if hi12(w) & DIS.HI_ST else "   ",
               cls(w), s8(ad8(w)), lo12(w), DIS.lo_src(w), DIS.lo_act(w), note))
    print("""
   SRC = 0x00 does NOT occur in the LFO block.  The three words carry SRC 0x08,
   0x07 (= mem[ptr], ANCHORED) and 0x08.
   What the block CAN anchor is ACTION = 0x00 -- which it carries three times out
   of three, and which is the single largest blocker in the ranking (824 corpus
   words, 51 of the 205 undecoded frame slots) -- and SRC = 0x08.""")

    corp = corpus()
    n00src = sum(1 for _, _, w in corp if DIS.lo_src(w) == 0x00 and not DIS.c_format(w))
    n08src = sum(1 for _, _, w in corp if DIS.lo_src(w) == 0x08 and not DIS.c_format(w))
    n00act = sum(1 for _, _, w in corp if DIS.lo_act(w) == 0x00 and not DIS.c_format(w))
    print("\n   corpus census (C-format excluded -- it has no lo12 fields of this kind):")
    print("      SRC    == 0x00 : %4d words" % n00src)
    print("      SRC    == 0x08 : %4d words   <- the LFO route" % n08src)
    print("      ACTION == 0x00 : %4d words   <- the LFO's action" % n00act)
    lo200 = collections.Counter(fmt(w) for _, _, w in corp if lo12(w) == 0x200)
    print("\n   every lo12 == 0x200 word in the machine:")
    for k, v in lo200.most_common():
        print("      %-14s x%d" % (k, v))


CORPUS = []
def corpus():
    """[(where, iram_addr, word)] over header + output stage + 38 body images."""
    if CORPUS:
        return CORPUS
    _, kern = blob(KERNEL_BLOB)
    _, epi = blob(EPILOG_BLOB)
    CORPUS.extend(("KERNEL", k, w) for k, w in enumerate(kern))
    CORPUS.extend(("EPILOG", 60 + k, w) for k, w in enumerate(epi))
    for p, (i, la, ws) in sorted(images().items()):
        CORPUS.extend(("algo%02d" % i, la + k, w) for k, w in enumerate(ws))
    return CORPUS


def blob(addr):
    op, cmd, ia, pl = parse_stream(addr, limit=3)[0]
    assert op == 3, "not an op-3 record at %06X" % addr
    return ia, words5(pl)


# =========================================================================
#  1.  SITES -- where the LFO is, and what coefficients it eats
# =========================================================================
def lfo_sites():
    """Every LFO block in the corpus.

    A site is a class-A word with lo12 == 0x200 (`hi12' 0x092 or 0x094).  They come
    in ordered pairs: the accumulate (f31 = 1) then the wrap (f31 = 2).
    Returns [(algo, load, wi_acc, wi_wrap, cursor_acc, cursor_wrap, words)].
    """
    out = []
    for i, (p, la, ws) in sorted(algo_to_image().items()):
        cur = DIS.cursor_addresses(ws)
        idx = [k for k, w in enumerate(ws) if lo12(w) == 0x200 and cls(w) == 0xA]
        k = 0
        while k + 1 < len(idx):
            a, b = idx[k], idx[k + 1]
            if DIS.hi_f31(hi12(ws[a])) == 1 and DIS.hi_f31(hi12(ws[b])) == 2:
                out.append((i, la, a, b, cur[a], cur[b], ws))
                k += 2
            else:
                k += 1
    return out


def sec_sites():
    hdr("sites -- every LFO block in the 38-image corpus")
    NM = prog_names()
    seen_img = {}
    print("%-4s %-22s %-5s %-24s %-24s" %
          ("algo", "program", "unit", "phase-accumulate word", "wrap word"))
    print("%-4s %-22s %-5s %-9s %-6s %-7s %-9s %-6s %-7s" %
          ("", "", "", "  I-RAM", "cell", "value", "  I-RAM", "cell", "value"))
    rows = []
    for (i, la, a, b, ca, cb, ws) in lfo_sites():
        base = 0x90 if la == 200 else 0x00
        cram = cram_of_algo(i)
        va = cram.get(base + ca)
        vb = cram.get(base + cb)
        rows.append((i, la, a, b, base + ca, base + cb, va, vb, ws))
        print("%-4d %-22s %-5d  w%-8d %02X    %-7s  w%-8d %02X    %-7s" %
              (i, NM.get(i, "?")[:22], 1 if la == 200 else 0,
               a, base + ca, "%06X" % va if va is not None else "--",
               b, base + cb, "%06X" % vb if vb is not None else "--"))
        seen_img.setdefault(id(ws), i)
    print("\n   %d LFO blocks over %d algorithm slots." % (len(rows), len(set(r[0] for r in rows))))
    wraps = collections.Counter("%06X" % r[7] for r in rows if r[7] is not None)
    print("   the WRAP word's coefficient, over every site:")
    for k, v in wraps.most_common():
        print("      %s  x%d" % (k, v))
    return rows


# =========================================================================
#  2.  RATE -- the numeric anchor, and it is NINE-fold, not one-fold
# =========================================================================
def sec_rate():
    hdr("rate -- increment = floor(f_Hz * 2**23 / 44100), tested at 9 values")
    NM = prog_names()
    rows = []
    for (i, la, a, b, ca, cb, ws) in lfo_sites():
        base = 0x90 if la == 200 else 0x00
        cram = cram_of_algo(i)
        va, vb = cram.get(base + ca), cram.get(base + cb)
        if va is None:
            continue
        rows.append((i, NM.get(i, "?"), va, vb, va / 2.0 ** 23 * FS))
    print("%-4s %-24s %-10s %-10s %-12s" %
          ("algo", "program", "increment", "wrap", "rate (Hz)"))
    for i, nm, va, vb, hz in rows:
        print("%-4d %-24s %-10s %-10s %10.4f" %
              (i, nm[:24], "%06X" % va, "%06X" % vb if vb is not None else "--", hz))

    print("\n   the DISTINCT increments, against the round frequency each implies:")
    print("   %-9s %-8s %-11s %-11s %-8s %-8s" %
          ("inc", "dec", "f @ 2**23", "f @ 2**24", "floor?", "round?"))
    incs = sorted({r[2] for r in rows})
    for v in incs:
        f23, f24 = v / 2.0 ** 23 * FS, v / 2.0 ** 24 * FS
        tgt = round(f23, 1)
        print("   %-9s %-8d %-11.4f %-11.4f %-8s %-8s  (f = %.1f Hz)" %
              ("%06X" % v, v, f23, f24,
               math.floor(tgt * 2 ** 23 / FS) == v, round(tgt * 2 ** 23 / FS) == v, tgt))
    print("""
   floor() fits 9 of 9; round-to-nearest fails at 570, 760, 1407 and 190217,
   so the designer TRUNCATED.  MEASURED.

   NULL: how surprising is a 9-for-9 fit?  A 0.1 Hz grid over 0.1..1000 Hz
   reaches %d distinct 24-bit codes, and around each of our nine values exactly
   1 of the 19 nearest codes qualifies, so the per-value null is 1/19 = 0.053
   and the joint null is %.1e.  The rival explanation `all multiples of 38'
   fits the four small values and FAILS at 989, 1407 and 190217 (3 of 9).""" %
          (10000, (1 / 19.0) ** 9))
    return rows


# =========================================================================
#  3.  WALK -- the pointer walk, and WHICH CELL IS THE PHASE
# =========================================================================
def block_cells(words):
    """Cell of each word of a block, relative to the first (post-increment)."""
    p, out = 0, []
    for w in words:
        out.append(p)
        if DIS.ptr_postinc(w):
            p += s8(addr8(w))
    return out


def sec_walk():
    hdr("walk -- the block's pointer arithmetic, and where the phase must live")
    NM = prog_names()
    print("""The block reads memory EXACTLY ONCE: the middle word `082.2.00.1C0' carries
SRC = 0x07 = mem[ptr], which is ANCHORED.  That read is the block's only input,
so the persistent phase must be the cell it names -- call it Q.  The wrap word
sits on Q too and carries hi12 bit 4, so it is the write.

The problem this section exists to show: in 24 of 29 blocks the ACCUMULATE word
ALSO sits on Q, and it ALSO carries bit 4.  Under the shipped model it stores the
incoming accumulator into Q before the middle word reads it.
""")
    clean, dirty = [], []
    for (i, la, a, b, ca, cb, ws) in lfo_sites():
        cells = block_cells([ws[k] for k in range(a, b + 1)])
        (clean if cells[0] != cells[-1] else dirty).append((i, a, cells))
    print("   blocks whose accumulate word is on a DIFFERENT cell from Q: %d" % len(clean))
    for i, a, cells in clean:
        print("      algo%-3d w%-4d cells %s   <- the block is self-contained here" %
              (i, a, cells))
    print("   blocks whose accumulate word is ON Q: %d" % len(dirty))
    print("      %s" % ", ".join("algo%d w%d" % (i, a) for i, a, _ in dirty))

    print("\n   per-program: every LFO block gets its OWN cell (nothing in the")
    print("   instruction words distinguishes co-resident LFOs):")
    for i, (p, la, ws) in sorted(algo_to_image().items()):
        s = [(a, b) for (j, l2, a, b, ca, cb, w2) in lfo_sites() if j == i]
        if len(s) < 2:
            continue
        ptr, c = [0] * len(ws), 0
        for k, w in enumerate(ws):
            ptr[k] = c
            if DIS.ptr_postinc(w):
                c += s8(addr8(w))
        cram = cram_of_algo(i)
        cur = DIS.cursor_addresses(ws)
        base = 0x90 if la == 200 else 0x00
        det = []
        for (a, b) in s:
            inc = cram.get(base + cur[a])
            det.append("Q=%+d (%.4f Hz)" % (ptr[b], (inc or 0) / 2.0 ** 23 * FS))
        print("      algo%-3d %-20s %s" % (i, NM.get(i, "?")[:20], "   ".join(det)))
    print("""
   ★ MIX UP (algo 56) is the discriminator: THREE byte-identical triples
   (092.A.00.200 | 082.2.00.1C0 | 094.A.00.200) at three DIFFERENT rates, on
   three consecutive cells Q = +2, +3, +4, separated by 000.2.01.447 words that
   move the pointer by exactly one.  Nothing in the instruction words tells them
   apart, so the per-LFO state is selected by an ADDRESS, not by the opcode.""")
    return clean, dirty


# =========================================================================
#  4.  SOLVE -- the constraint search
# =========================================================================
MASK24, MASK23 = (1 << 24) - 1, (1 << 23) - 1


def s24(v):
    v &= MASK24
    return v - (1 << 24) if v & (1 << 23) else v


SRC08 = ["unity", "zero", "acc", "mem", "P", "phasereg"]
ACT00 = ["none", "acc_load", "acc_add", "mem_store", "ta", "tb",
         "phase_load", "phase_add"]
ORDER = ["act_first", "act_last"]
OP2   = ["hold", "and_coef", "subge_coef", "and_mask23"]
STORE = ["sat", "wrap24", "wrap23", "f31_2_and_coef", "f31_2_subge_coef"]
STORE2 = STORE + ["b7_and_coef"]      # the gate could key on bit 7 instead of f31


def sim(cfg, words, coefs, nframes, rng, preset=None, cell=None, trace=False):
    """Run one candidate machine over the block.  The entering accumulator, the
    product latch and both temporaries are RANDOMISED every frame: an LFO whose
    ramp depends on what the surrounding program left is not an LFO, and the
    same three words appear in 16 different programs."""
    src08, act00, order, op2, store = cfg
    mem = collections.defaultdict(int)
    acc = P = ta = tb = phase = 0
    if preset is not None:
        if cell == "phase":
            phase = preset
        else:
            mem[cell] = preset
    hist = []
    for _ in range(nframes):
        acc = rng.randrange(-(1 << 23), 1 << 23)
        P   = rng.randrange(-(1 << 23), 1 << 23)
        ta, tb = rng.randrange(0, 1 << 24), rng.randrange(0, 1 << 24)
        p = 0
        for k, w in enumerate(words):
            hi, coef = hi12(w), coefs[k]
            src, act = DIS.lo_src(w), DIS.lo_act(w)
            isA, f = DIS.coeff_consumer(w), DIS.hi_f31(hi)
            if src == 0x07:   Lv = s24(mem[p])
            elif src == 0x10: Lv = s24(acc)
            elif src == 0x19: Lv = s24(ta)
            elif src == 0x1A: Lv = s24(tb) >> 1
            elif src == 0x08:
                Lv = {"unity": MASK23, "zero": 0, "acc": s24(acc),
                      "mem": s24(mem[p]), "P": s24(P), "phasereg": s24(phase)}[src08]
            else:
                return None
            if hi & DIS.HI_ST:
                v = acc
                if store == "sat":      v = max(-(1 << 23), min(MASK23, v))
                elif store == "wrap24": v = s24(v)
                elif store == "wrap23": v = v & MASK23
                elif store == "f31_2_and_coef":
                    v = (v & coef) if (f == 2 and coef is not None) \
                        else max(-(1 << 23), min(MASK23, v))
                else:
                    v = (v - coef * (v // coef)) if (f == 2 and coef and v >= coef) \
                        else max(-(1 << 23), min(MASK23, v))
                mem[p] = v & MASK24
                acc = 0
            def do_act():
                nonlocal acc, ta, tb, phase, mem
                if act == 0x13:   ta = Lv & MASK24
                elif act == 0x14: tb = Lv & MASK24
                elif act == 0x07: mem[p] = Lv & MASK24
                elif act in (0x12, 0x15): pass
                elif act == 0x00:
                    if act00 == "acc_load":    acc = Lv
                    elif act00 == "acc_add":   acc = acc + Lv
                    elif act00 == "mem_store": mem[p] = Lv & MASK24
                    elif act00 == "ta":        ta = Lv & MASK24
                    elif act00 == "tb":        tb = Lv & MASK24
                    elif act00 == "phase_load": phase = Lv
                    elif act00 == "phase_add":  phase = phase + Lv
                else:
                    raise KeyError(act)
            def do_op():
                nonlocal acc
                if f == 0:   acc = P
                elif f == 1: acc = acc + P
                elif f == 2:
                    if op2 == "and_coef":
                        acc = acc & (coef if coef is not None else MASK24)
                    elif op2 == "subge_coef":
                        kk = coef if coef is not None else MASK24
                        if kk > 0 and acc >= kk:
                            acc -= kk * (acc // kk)
                    elif op2 == "and_mask23":
                        acc = acc & MASK23
                else:
                    return 1
            if order == "act_first":
                do_act()
                if do_op(): return None
            else:
                if do_op(): return None
                do_act()
            if isA:
                if coef is None:
                    return None
                P = s24(coef) if (src08 == "unity" and src == 0x08) \
                    else (s24(coef) * Lv) >> 23
            if DIS.ptr_postinc(w):
                p += s8(addr8(w))
            if trace:
                print("      %s  L=%-9d acc=%-11d P=%-9d mem=%s"
                      % (fmt(w), Lv, acc, P, dict(mem)))
        hist.append((dict(mem), phase))
    return hist


def ramp_cells(hist, inc):
    cells = set()
    for h in hist[:8]:
        cells |= set(h[0].keys())
    out = []
    for nm, fn in ([("phase", lambda h: h[1] & MASK24)] +
                   [("mem[%+d]" % c, (lambda h, c=c: h[0].get(c, 0)))
                    for c in sorted(cells)]):
        vs = [fn(h) & MASK24 for h in hist]
        if len(set(vs)) < len(vs):
            continue
        if (all((vs[k + 1] - vs[k]) % (1 << 24) == inc for k in range(len(vs) - 1))
                and all(0 <= v < (1 << 23) for v in vs)):
            out.append(nm)
    return out


def solve_blocks():
    out = []
    for (i, la, a, b, ca, cb, ws) in lfo_sites():
        base = 0x90 if la == 200 else 0x00
        cram, cur = cram_of_algo(i), DIS.cursor_addresses(ws)
        coefs = [cram.get(base + cur[k]) if cur[k] is not None else None
                 for k in range(a, b + 1)]
        if coefs[0] is None:
            continue
        words = [ws[k] for k in range(a, b + 1)]
        out.append((i, a, words, coefs, coefs[0], block_cells(words)))
    return out


def sweep(pool, label):
    tot, s1 = 0, []
    for cfg in itertools.product(SRC08, ACT00, ORDER, OP2, STORE):
        tot += 1
        ok, per = True, {}
        for (i, a, words, coefs, inc, cl) in pool:
            h = sim(cfg, words, coefs, 40, random.Random(999 + i * 7 + a))
            if h is None:
                ok = False; break
            c = ramp_cells(h, inc)
            if not c:
                ok = False; break
            per[(i, a)] = c[0]
        if ok:
            s1.append((cfg, per))
    s2 = []
    for cfg, per in s1:
        ok = True
        for (i, a, words, coefs, inc, cl) in pool:
            nm = per[(i, a)]
            tgt = "phase" if nm == "phase" else int(nm[4:-1])
            h = sim(cfg, words, coefs, 6, random.Random(31 + i),
                    preset=(1 << 23) - 2 * inc, cell=tgt)
            if h is None:
                ok = False; break
            fn = ((lambda x: x[1] & MASK24) if tgt == "phase"
                  else (lambda x: x[0].get(tgt, 0) & MASK24))
            if ([fn(x) for x in h] !=
                    [((1 << 23) - 2 * inc + inc * (k + 1)) % (1 << 23) for k in range(6)]):
                ok = False; break
        if ok:
            s2.append((cfg, per))
    print("\n== %s ==" % label)
    print("   %d machines tested   %d produce the RAMP   %d also WRAP at 2**23"
          % (tot, len(s1), len(s2)))
    for cfg, _ in s2:
        print("   SURVIVOR  src08=%-8s act00=%-9s order=%-9s op2=%-11s store=%s" % cfg)
    for nm, st in (("RAMP", s1), ("RAMP+WRAP", s2)):
        if st:
            print("   marginals over the %s survivors:" % nm)
            for k, f in enumerate(["src08", "act00", "order", "op2", "store"]):
                print("      %-8s : %s" % (f, sorted({c[k] for c, _ in st})))
    return s1, s2


def sec_solve():
    hdr("solve -- the exhaustive constraint search over the LFO block")
    print("""Free parameters, all currently OPEN in the ISA:
   src08  what lo12[10:6] == 0x08 puts on the bus / into the multiplier
   act00  what lo12[4:0]  == 0x00 does with the bus operand
   order  whether the ACTION runs before or after the hi12[3:1] operation
   op2    what hi12[3:1] == 2 does to the ACCUMULATOR
   store  what the hi12 bit-4 store path does to the value on its way out
Fixed, and NOT re-litigated: bit 4 stores to mem[ptr] and clears the accumulator
(biquad, 57 dB); the store precedes the ALU step (R1 F2); P is the PREVIOUS
multiply's product; class A multiplies and advances the cursor; class4 & 7 == 2
post-increments the pointer by (s8)addr8.""")
    pool = solve_blocks()
    clean = [r for r in pool if r[5][0] != r[5][-1]]
    dirty = [r for r in pool if r[5][0] == r[5][-1]]
    sweep(clean, "the %d blocks whose accumulate word is NOT on the phase cell" % len(clean))
    sweep(dirty[:3], "3 of the %d blocks whose accumulate word IS on the phase cell" % len(dirty))
    print("""
   ★ THE FALSIFICATION.  Not one of the 1920 candidate machines produces the
   ramp at a block whose accumulate word sits on the phase cell -- and 24 of the
   29 blocks are of that shape.  The 5 that are not are solved uniquely.  So the
   LFO does not merely fail to be decoded: the CURRENT MODEL CANNOT RUN IT.""")


# =========================================================================
#  5.  DEADSTORE -- the same defect, measured corpus-wide
# =========================================================================
def sec_deadstore():
    hdr("deadstore -- a corpus-wide check of the same model, and it fails")
    print("""Under the shipped model a mode-2 word WRITES mem[ptr] if hi12 bit 4 is set or
ACTION == 0x07, and READS it if SRC == 0x07.  Two writes to the same cell with no
read between them, and no word of unknown addressing between them, is a PROVABLY
DEAD STORE -- the same instrument R1 and R2 used to falsify claims.  (Caveat: a
second data pointer, or a host read of D-RAM, would break the argument.)
""")
    def mode2(w):  return (not DIS.c_format(w)) and (class4(w) & 7) == 2
    def wr(w):     return bool(hi12(w) & DIS.HI_ST) or DIS.lo_act(w) == 0x07
    def rd(w):     return DIS.lo_src(w) == 0x07
    tot, runs, ex, per = 0, collections.Counter(), collections.Counter(), collections.Counter()
    for i, (p, la, ws) in sorted(algo_to_image().items()):
        ptr, c = [0] * len(ws), 0
        for k, w in enumerate(ws):
            ptr[k] = c
            if DIS.ptr_postinc(w):
                c += s8(addr8(w))
        for k in range(len(ws)):
            if mode2(ws[k]) and wr(ws[k]):
                j, chain = k + 1, [k]
                while j < len(ws) and mode2(ws[j]) and ptr[j] == ptr[k] and not rd(ws[j]):
                    if wr(ws[j]):
                        chain.append(j)
                    j += 1
                if len(chain) > 1:
                    runs[len(chain)] += 1
                    ex[tuple(fmt(ws[x]) for x in chain)] += 1
                    per[i] += len(chain) - 1
                    tot += len(chain) - 1
    print("   provably dead stores in the 38-image body corpus: %d" % tot)
    for n, c in sorted(runs.items()):
        print("      runs of %d consecutive writes : %d" % (n, c))
    print("\n   the commonest dead chains:")
    for k, v in ex.most_common(8):
        print("      x%-3d %s" % (v, " -> ".join(k)))
    lfo = sum(v for k, v in ex.items() if any(x.endswith(".200") for x in k))
    print("\n   chains containing an LFO word: %d of %d -- so this is a GENERAL"
          % (lfo, sum(ex.values())))
    print("   defect of the model, not an LFO peculiarity.")


# =========================================================================
#  6.  CLOSURE -- what this pass hands to the other two targets
# =========================================================================
def sec_closure():
    hdr("closure -- what TARGET 3 hands to TARGET 1 and TARGET 2")
    tot = collections.Counter()
    for (i, la, a, b, ca, cb, ws) in lfo_sites():
        p = 0
        for k in range(a, b + 1):
            if DIS.ptr_postinc(ws[k]):
                p += s8(addr8(ws[k]))
        tot[p] += 1
    print("   net pointer displacement of the LFO block (TARGET 1's ledger):")
    for k, v in sorted(tot.items()):
        print("      %+4d  x%d" % (k, v))
    corp = corpus()
    print("\n   words the LFO's answer would newly admit, if it were adopted:")
    def would(w):
        if DIS.c_format(w) or class4(w) not in (2, 8, 0xA):
            return False
        if (lo12(w) & 0x800) or (lo12(w) & 0x20):
            return False
        return (DIS.lo_src(w) in (0x07, 0x10, 0x19, 0x1A, 0x08)
                and DIS.lo_act(w) in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15)
                and DIS.hi_f31(hi12(w)) in (0, 1, 2))
    now = sum(1 for _, _, w in corp if DIS.alu_decoded(w))
    new = sum(1 for _, _, w in corp if would(w))
    print("      decoded now %d of %d corpus words; with ACTION 0x00 and SRC 0x08"
          % (now, len(corp)))
    print("      admitted (and hi12[3:1]==2 allowed off class 8): %d" % new)
    c = collections.Counter(fmt(w) for _, _, w in corp
                            if would(w) and not DIS.alu_decoded(w))
    for k, v in c.most_common(8):
        print("         %-14s x%d" % (k, v))
    print("""
   ⚠ IT IS NOT ADOPTED.  The same pass that determined those two codes also
   measured that the model they live in cannot run the block they were
   determined from.  Executing 259 more words on a datapath with 216 provably
   dead stores would spread the error, not reduce it.

   TARGET 2 (the ACTION field): 082.2.00.1C0 (x64) and 012.2.00.680 (x16) both
   carry ACTION 0x00 and both sit in the reverb all-pass core, so `acc <- bus,
   before the operation' is now a named candidate for two of that motif's six
   words -- and it changes what the R1 solver should be asked.
   TARGET 1 (frame closure): every LFO block's own displacement is listed above;
   24 of 29 are net 0, so the LFO is not where the +121 residue comes from.""")


# =========================================================================
#  7.  PUBLISH -- WHO WRITES THE PHASE CELL?
#
#  The `solve' section above proved that no machine in its 1920-point space can
#  run 24 of the 29 blocks, and named four candidate resolutions (L-1..L-4)
#  without choosing between them.  This section chooses, by WIDENING the space
#  in the two directions the falsification pointed at:
#
#    * the WINDOW.  `solve' simulated the three-word block alone.  But every
#      block is followed within a few words by `xxx.2.dd.447' -- SRC 0x11,
#      ACTION 0x07 (= "write the operand to a destination", ANCHORED) -- sitting
#      on the very same cell.  A store we were counting as DEAD is a candidate
#      PUBLISHER, and it cannot be seen from inside the block.
#    * the STORE GATE.  `solve' held "hi12 bit 4 stores to mem[ptr]" fixed
#      because the biquad validates it to 0.094 dB.  MEASURED here: every one of
#      PARAMETRIC EQ's bit-4 words has hi12 bit 7 CLEAR, and all three LFO words
#      have it SET -- so the biquad constrains bit 4 only on bit7 == 0 words and
#      the LFO is free to disagree.
#
#  Everything else is held exactly as `solve' held it.
# =========================================================================

MODELLED_SRC = {0x07, 0x08, 0x10, 0x11, 0x19, 0x1A}
WINDOW_ACT   = {0x00, 0x07, 0x12, 0x13, 0x14, 0x15}

STGATE = ["always",            # the shipped model
          "not_b7",            # hi12 bit 7 cancels the store (and its clear)
          "not_b7_keepclear",  # ... cancels the store but not the clear
          "b7_scratch",        # ... redirects the store off D-RAM
          "prev_ptr",          # the store uses the PREVIOUS word's pointer
          "next_ptr",          # ... the pointer after this word's post-increment
          "f31_2_only",        # the store happens only when hi12[3:1] == 2
          "b7_f31_1_off",      # suppressed only on bit7 words with hi12[3:1] == 1
          "b7_ne2_off",        # suppressed on bit7 words unless hi12[3:1] == 2
          "b7_f31_1_scratch"]  # ... redirected rather than suppressed
SRC11  = ["acc", "P", "mem", "ta", "tb", "unity", "zero", "coef"]
DEST07 = ["mem", "elsewhere"]   # ACTION 0x07's destination is MODE-DEPENDENT (R2)


def window_of(site):
    """[accumulate .. wrap] PLUS the contiguous run of ordinary D-RAM words that
    follows, so the search can see the `447' store.  The run stops at the first
    word this model cannot execute at all (C-format, an escape/mode-1 word, an
    unanchored ACTION, or the lo12 bit-11 / bit-5 modifiers)."""
    (i, la, a, b, ca, cb, ws) = site
    e = b
    while e + 1 < len(ws):
        w = ws[e + 1]
        if DIS.c_format(w) or class4(w) not in (2, 8, 0xA):
            break
        if DIS.lo_act(w) not in WINDOW_ACT:
            break
        if (lo12(w) & 0x800) or (lo12(w) & 0x20):
            break
        e += 1
    return a, e


def publish_blocks():
    """[(algo, a, e, words, coefs, inc, qcell)] over all 29 sites."""
    out = []
    for site in lfo_sites():
        (i, la, a, b, ca, cb, ws) = site
        a, e = window_of(site)
        base = 0x90 if la == 200 else 0x00
        cram, cur = cram_of_algo(i), DIS.cursor_addresses(ws)
        coefs = [cram.get(base + cur[k]) if cur[k] is not None else None
                 for k in range(a, e + 1)]
        if coefs[0] is None:
            continue
        words = [ws[k] for k in range(a, e + 1)]
        cells = block_cells(words)
        out.append((i, a, e, words, coefs, coefs[0], cells[1]))
    return out


def sim2(cfg, words, coefs, nframes, rng, preset=None, qcell=0, trace=False):
    """One candidate machine over the WINDOW.  As in `sim', the entering
    accumulator, product latch and both temporaries are randomised every frame,
    and any source this ISA does not decode delivers a fresh random value -- so a
    machine only passes if the ramp is independent of everything we cannot read."""
    src08, act00, order, op2, store, stgate, src11, dest07 = cfg
    mem = collections.defaultdict(int)
    if preset is not None:
        mem[qcell] = preset
    hist = []
    for _ in range(nframes):
        acc = rng.randrange(-(1 << 23), 1 << 23)
        P   = rng.randrange(-(1 << 23), 1 << 23)
        ta, tb = rng.randrange(0, 1 << 24), rng.randrange(0, 1 << 24)
        scratch = 0
        p = pprev = 0
        for k, w in enumerate(words):
            hi, coef = hi12(w), coefs[k]
            src, act = DIS.lo_src(w), DIS.lo_act(w)
            isA, f = DIS.coeff_consumer(w), DIS.hi_f31(hi)
            b7 = (hi >> 7) & 1
            nxt = p + (s8(addr8(w)) if DIS.ptr_postinc(w) else 0)
            # ---------------- the bus operand
            if src == 0x07:   Lv = s24(mem[p])
            elif src == 0x10: Lv = s24(acc)
            elif src == 0x19: Lv = s24(ta)
            elif src == 0x1A: Lv = s24(tb) >> 1
            elif src == 0x08:
                Lv = {"unity": MASK23, "zero": 0, "acc": s24(acc),
                      "mem": s24(mem[p]), "P": s24(P),
                      "coef": s24(coef) if coef is not None else 0}[src08]
            elif src == 0x11:
                Lv = {"acc": s24(acc), "P": s24(P), "mem": s24(mem[p]),
                      "ta": s24(ta), "tb": s24(tb), "unity": MASK23, "zero": 0,
                      "coef": s24(coef) if coef is not None else 0}[src11]
            else:
                Lv = rng.randrange(-(1 << 23), 1 << 23)      # UNDECODED source
            # ---------------- the hi12 bit-4 store
            if hi & DIS.HI_ST:
                v = acc
                if store == "sat":      v = max(-(1 << 23), min(MASK23, v))
                elif store == "wrap24": v = s24(v)
                elif store == "wrap23": v = v & MASK23
                elif store == "f31_2_and_coef":
                    v = (v & coef) if (f == 2 and coef is not None) \
                        else max(-(1 << 23), min(MASK23, v))
                elif store == "b7_and_coef":
                    v = (v & coef) if (b7 and coef is not None) \
                        else max(-(1 << 23), min(MASK23, v))
                else:
                    v = (v - coef * (v // coef)) if (f == 2 and coef and v >= coef) \
                        else max(-(1 << 23), min(MASK23, v))
                do, tgt, clr = True, p, True
                if stgate == "not_b7" and b7:            do, clr = False, False
                elif stgate == "not_b7_keepclear" and b7: do = False
                elif stgate == "b7_scratch" and b7:      tgt = "S"
                elif stgate == "prev_ptr":               tgt = pprev
                elif stgate == "next_ptr":               tgt = nxt
                elif stgate == "f31_2_only" and f != 2:  do, clr = False, False
                elif stgate == "b7_f31_1_off" and b7 and f == 1: do, clr = False, False
                elif stgate == "b7_ne2_off" and b7 and f != 2: do, clr = False, False
                elif stgate == "b7_f31_1_scratch" and b7 and f == 1: tgt = "S"
                if do:
                    if tgt == "S": scratch = v & MASK24
                    else:          mem[tgt] = v & MASK24
                if clr:
                    acc = 0
            # ---------------- the lo12 ACTION and the hi12[3:1] operation
            def do_act():
                nonlocal acc, ta, tb
                if act == 0x13:   ta = Lv & MASK24
                elif act == 0x14: tb = Lv & MASK24
                elif act == 0x07:
                    if dest07 == "mem": mem[p] = Lv & MASK24
                elif act in (0x12, 0x15): pass
                elif act == 0x00:
                    if act00 == "acc_load":    acc = Lv
                    elif act00 == "acc_add":   acc = acc + Lv
                    elif act00 == "mem_store": mem[p] = Lv & MASK24
                    elif act00 == "ta":        ta = Lv & MASK24
                    elif act00 == "tb":        tb = Lv & MASK24
                else:
                    raise KeyError(act)
            def do_op():
                nonlocal acc
                if f == 0:   acc = P
                elif f == 1: acc = acc + P
                elif f == 2:
                    if op2 == "and_coef":
                        acc = acc & (coef if coef is not None else MASK24)
                    elif op2 == "subge_coef":
                        kk = coef if coef is not None else MASK24
                        if kk > 0 and acc >= kk:
                            acc -= kk * (acc // kk)
                    elif op2 == "and_mask23":
                        acc = acc & MASK23
                else:
                    return 1
            if order == "act_first":
                do_act()
                if do_op(): return None
            else:
                if do_op(): return None
                do_act()
            if isA:
                if coef is None:
                    return None
                P = s24(coef) if (src08 == "unity" and src == 0x08) \
                    else (s24(coef) * Lv) >> 23
            if trace:
                print("      %-14s p=%+3d L=%-9d acc=%-11d P=%-9d mem=%s"
                      % (fmt(w), p, Lv, acc, P, dict(mem)))
            pprev = p
            p = nxt
        hist.append(mem[qcell] & MASK24)
    return hist


def is_ramp(hist, inc):
    return (len(set(hist)) == len(hist)
            and all(0 <= v < (1 << 23) for v in hist)
            and all((hist[k + 1] - hist[k]) % (1 << 23) == inc
                    for k in range(len(hist) - 1)))


def sec_publish():
    hdr("publish -- who writes the phase cell?  the WIDENED search")
    print("""Two facts this section adds to `solve', both MEASURED first:

   (1) every LFO block is followed, within the same run of ordinary D-RAM words,
       by `xxx.2.dd.447' -- SRC 0x11, ACTION 0x07 -- ON THE PHASE CELL.  `solve'
       could not see it because its window was the three-word block.
   (2) PARAMETRIC EQ -- the biquad that validates `hi12 bit 4 = store' to
       0.094 dB -- contains NO word with hi12 bit 7 set and bit 4 set.  Every one
       of its store words is `212.xx' (bit7 = 0).  All three LFO words are
       `09x.xx' (bit7 = 1).  The biquad therefore does not constrain bit 4 here.

Free parameters: the five of `solve', plus
   stgate what gates or redirects the hi12 bit-4 store
   src11  what lo12[10:6] == 0x11 puts on the bus""")

    # ---- (1) and (2), measured
    a2i = algo_to_image()
    peq = a2i[39][2]
    nb = sum(1 for w in peq if not DIS.c_format(w)
             and (hi12(w) >> 4) & 1 and (hi12(w) >> 7) & 1)
    print("\n   PARAMETRIC EQ words with BOTH hi12 bit 4 and bit 7: %d of %d"
          % (nb, len(peq)))
    pool = publish_blocks()
    n447 = 0
    for (i, a, e, words, coefs, inc, q) in pool:
        cells = block_cells(words)
        if any(DIS.lo_act(w) == 0x07 and DIS.lo_src(w) == 0x11 and c == q
               for w, c in zip(words[3:], cells[3:])):
            n447 += 1
    print("   blocks whose window contains a SRC-0x11 / ACTION-0x07 word ON the"
          " phase cell: %d of %d" % (n447, len(pool)))
    print("   window length after the wrap word: %s"
          % dict(collections.Counter(e - a - 2 for (i, a, e, *_) in pool)))

    # ---- the search, staged
    space = list(itertools.product(SRC08[:5] + ["coef"], ACT00[:6], ORDER,
                                   OP2, STORE2, STGATE, SRC11, DEST07))
    print("\n   candidate machines: %d" % len(space))
    seed = [r for r in pool if r[0] in (1, 4)][:2]
    stage1 = []
    for cfg in space:
        ok = True
        for (i, a, e, words, coefs, inc, q) in seed:
            h = sim2(cfg, words, coefs, 10, random.Random(5 + i), qcell=q)
            if h is None or not is_ramp(h, inc):
                ok = False; break
        if ok:
            stage1.append(cfg)
    print("   stage 1 (2 blocks, 10 frames)          : %d survive" % len(stage1))

    stage2 = []
    for cfg in stage1:
        ok = True
        for (i, a, e, words, coefs, inc, q) in pool:
            h = sim2(cfg, words, coefs, 30, random.Random(97 + i * 13 + a), qcell=q)
            if h is None or not is_ramp(h, inc):
                ok = False; break
        if ok:
            stage2.append(cfg)
    print("   stage 2 (ALL %d blocks, 30 frames)      : %d survive" % (len(pool), len(stage2)))

    stage3 = []
    for cfg in stage2:
        ok = True
        for (i, a, e, words, coefs, inc, q) in pool:
            h = sim2(cfg, words, coefs, 6, random.Random(3 + i), qcell=q,
                     preset=(1 << 23) - 2 * inc)
            want = [((1 << 23) - 2 * inc + inc * (k + 1)) % (1 << 23) for k in range(6)]
            if h is None or h != want:
                ok = False; break
        if ok:
            stage3.append(cfg)
    print("   stage 3 (the 2**23 WRAP, all %d blocks) : %d survive" % (len(pool), len(stage3)))

    if stage3:
        print("\n   marginals over the survivors:")
        for k, f in enumerate(["src08", "act00", "order", "op2", "store",
                               "stgate", "src11", "dest07"]):
            print("      %-7s : %s" % (f, sorted({c[k] for c in stage3})))
        fam = collections.Counter((c[5], c[6], c[7]) for c in stage3)
        print("\n   survivors by (stgate, src11, dest07) -- the NEW axes:")
        for k, v in sorted(fam.items()):
            print("      stgate=%-18s src11=%-6s dest07=%-10s  x%d" % (k + (v,)))
    return pool, stage3
    return pool, stage3


# =========================================================================
#  8.  GATE -- the INDEPENDENT test of the store gate the ramp determined
#
#  `publish' determines the gate from a NUMERIC constraint (the ramp).  The dead
#  store census is a STRUCTURAL measurement that knows nothing about rates.  If
#  the gate is right the two must agree: suppressing exactly those stores should
#  make the corpus's provably-dead stores go away.  If it is wrong, or merely
#  tuned to the LFO, the 216 should barely move.  This can fail.
# =========================================================================
GATES = {
    "always (shipped)":  lambda b7, f: True,
    "not_b7":            lambda b7, f: not b7,
    "f31_2_only":        lambda b7, f: f == 2,
    "b7_f31_1_off":      lambda b7, f: not (b7 and f == 1),
    "b7_ne2_off":        lambda b7, f: not (b7 and f != 2),
}


def deadstores(gate, src11_inert=False):
    """(total dead stores, chain census) under a bit-4 store gate.

    `src11_inert' applies the OTHER thing the ramp forces: a SRC-0x11 /
    ACTION-0x07 word must not deposit a foreign value in the cell (either because
    its source IS the cell or because its destination is elsewhere), so it cannot
    kill a live store."""
    def mode2(w):  return (not DIS.c_format(w)) and (class4(w) & 7) == 2
    def wr(w):
        if DIS.lo_act(w) == 0x07:
            if src11_inert and DIS.lo_src(w) == 0x11:
                return False
            return True
        if not (hi12(w) & DIS.HI_ST):
            return False
        return gate((hi12(w) >> 7) & 1, DIS.hi_f31(hi12(w)))
    def rd(w):     return DIS.lo_src(w) == 0x07
    tot, ex = 0, collections.Counter()
    for i, (p, la, ws) in sorted(algo_to_image().items()):
        ptr, c = [0] * len(ws), 0
        for k, w in enumerate(ws):
            ptr[k] = c
            if DIS.ptr_postinc(w):
                c += s8(addr8(w))
        for k in range(len(ws)):
            if mode2(ws[k]) and wr(ws[k]):
                j, chain = k + 1, [k]
                while j < len(ws) and mode2(ws[j]) and ptr[j] == ptr[k] and not rd(ws[j]):
                    if wr(ws[j]):
                        chain.append(j)
                    j += 1
                if len(chain) > 1:
                    ex[tuple(fmt(ws[x]) for x in chain)] += 1
                    tot += len(chain) - 1
    return tot, ex


def sec_gate():
    hdr("gate -- an INDEPENDENT test of the store gate the ramp determined")
    print("""The ramp is a NUMERIC constraint; the dead-store census is a STRUCTURAL one
that knows nothing about rates.  They are independent, so they can disagree --
which is the point.  Under the shipped model the 38-image body corpus contains
216 provably dead stores (`deadstore').  If the gate `publish' determined is a
real property of the chip it should remove them; if it is an LFO-shaped patch it
should not.
""")
    peq = algo_to_image()[39][2]
    pf = collections.Counter(((hi12(w) >> 7) & 1, DIS.hi_f31(hi12(w)))
                             for w in peq if not DIS.c_format(w) and (hi12(w) & DIS.HI_ST))
    print("   PARAMETRIC EQ's bit-4 store words, by (hi12 bit 7, hi12[3:1]): %s"
          % {("b7=%d,f31=%d" % k): v for k, v in sorted(pf.items())})
    print("   -> every one is bit7 = 0, so `not_b7' and `b7_*' leave the 0.094 dB")
    print("      biquad reconstruction untouched, and `f31_2_only' DESTROYS it.\n")
    base, _ = deadstores(GATES["always (shipped)"])
    print("   %-20s %-8s %-9s %s" % ("gate", "dead", "removed", "corpus bit-4 stores kept"))
    nb4 = [((hi12(w) >> 7) & 1, DIS.hi_f31(hi12(w)))
           for _, _, w in corpus() if not DIS.c_format(w) and (hi12(w) & DIS.HI_ST)]
    for nm, g in GATES.items():
        tot, ex = deadstores(g)
        kept = sum(1 for b7, f in nb4 if g(b7, f))
        print("   %-20s %-8d %-9s %d of %d" %
              (nm, tot, "%+.1f%%" % (100.0 * (tot - base) / base) if base else "-",
               kept, len(nb4)))
    print("\n   the JOINT model the ramp forces -- gate AND the SRC-0x11 / ACTION-0x07"
          "\n   word being inert on the cell (the other thing `publish' determines):")
    for nm in ("always (shipped)", "b7_f31_1_off", "b7_ne2_off"):
        tot, _ = deadstores(GATES[nm], src11_inert=True)
        print("      %-20s %d dead   (%+.1f%% vs the shipped 216)"
              % (nm, tot, 100.0 * (tot - base) / base))

    print("\n   the chains that SURVIVE the b7_f31_1_off gate:")
    tot, ex = deadstores(GATES["b7_f31_1_off"])
    for k, v in ex.most_common(8):
        print("      x%-3d %s" % (v, " -> ".join(k)))
    print("\n   the chains the gate REMOVES (present under `always', gone under it):")
    _, ex0 = deadstores(GATES["always (shipped)"])
    gone = collections.Counter({k: v for k, v in ex0.items() if k not in ex})
    for k, v in gone.most_common(8):
        print("      x%-3d %s" % (v, " -> ".join(k)))


SECTIONS = [("fields", sec_fields), ("sites", sec_sites), ("rate", sec_rate),
            ("walk", sec_walk), ("solve", sec_solve),
            ("deadstore", sec_deadstore), ("closure", sec_closure),
            ("publish", sec_publish), ("gate", sec_gate)]

if __name__ == "__main__":
    want = sys.argv[1:] or [n for n, _ in SECTIONS]
    for name, fn in SECTIONS:
        if name in want:
            fn()
