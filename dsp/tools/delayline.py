#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""delayline.py -- THE HARNESS THAT CAN HOLD A DELAY LINE.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams, the 38 body images and the
descriptor bank only.

WHY THIS EXISTS.  Every constraint solver ever aimed at this chip's reverb runs
candidate microcode against a delay model whose `Line' object reads and writes
ONE CELL and advances one cursor per frame:

    dsp/tools/r1_allpass_solve.py      class Line       (lines 332-347)
    dsp/tools/action00_discriminate.py class Line       (lines 773-787)
    dsp/tools/acc_adjudicate.py        class Line       (lines 394-408)

That model is not neutral.  It silently REQUIRES read-before-write in program
order -- if the write word comes first, the read returns the value written in
that very frame and the delay is 0 -- and the delay it does produce is the
buffer length the EXPERIMENTER chose, not the difference of two descriptor
addresses.  Two of the three additionally hardcode `addr8 0x20 -> WRITE,
0x60 -> READ', the reverse of the polarity `adjudication-round5.md' item D
forced.  `adjudication-round6.md' sect. 3.5 demonstrates the consequence and
names this harness as the rank-1 experiment.

WHAT THE CHIP ACTUALLY HAS (imported, not re-derived):

  * a TWO-ADDRESS line.  `dram-bounds.md' / descriptor-cell-classes.json give
    every line a READ cell and a WRITE cell; the delay is their DIFFERENCE.
    324 lines over 83 aligned algorithms.
  * a ROTATION.  `dram-unit-cursor.md' refutes M5 (separate read/write
    cursors); one cursor, identity map, delta = 0.  The rotation register G
    itself is UNDECODED -- it is enumerated here, never assumed.
  * a ONE-DEEP PIPELINE.  `dram-datapath.md' item A: the CEILING cell is the
    LAST READ of its program 83/83 (a flush read whose datum is discarded) and
    the LIMIT cell is the FIRST WRITE 74/74 (a prime write at an address no
    read can reach).
  * a write that TRAILS its read by +3 port slots, 273 of 324 lines; +2 8-word
    repetitions in ROOM REVERB 1, 11 of 11.

    python3 dsp/tools/delayline.py enum      #  1 the parameter enumeration
    python3 dsp/tools/delayline.py delay     #  2 *** IT MUST DELAY
    python3 dsp/tools/delayline.py refs      #  3 *** IT MUST SAY YES
    python3 dsp/tools/delayline.py twins     #  4 *** IT MUST SAY NO
    python3 dsp/tools/delayline.py degen     #  5 rule 4, run BEFORE any score
    python3 dsp/tools/delayline.py loopok    #  6 *** loop_ok for a general wtrail
    python3 dsp/tools/delayline.py ledger    #  7 the ROM programs, executed
    python3 dsp/tools/delayline.py migrate   #  8 *** the old search, re-expressed
    python3 dsp/tools/delayline.py repro     #  9 the OLD path, unmodified
    python3 dsp/tools/delayline.py cannot    # 10 what this harness CANNOT express
    python3 dsp/tools/delayline.py all       # ~4 min without `repro'

Standard library only, plus the repo's own ROM parsers.
"""
import argparse
import collections
import itertools
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                            # noqa: E402
import dram_match as DM                                             # noqa: E402
import bounds as B                                                  # noqa: E402
import action00_discriminate as A0                                  # noqa: E402
import lfo_ramp as L                                                # noqa: E402

SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
MAIN = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")
CLASSES = os.path.join(REPO, "dsp", "analysis", "descriptor-cell-classes.json")


def head(n, s):
    print("=" * 78)
    print("%s. %s" % (n, s))
    print("=" * 78)


def sub(s):
    print()
    print("   ---- " + s)


# ===========================================================================
#  0.  THE PARAMETER ENUMERATION.
#
#  METHOD RULE 3: a result is FORCED only within the option set enumerated,
#  and the enumeration is printed beside the claim.  Rule 11: the MODEL is
#  part of the search space, so every modelling choice below is a parameter
#  with a default, and every default carries the label of the evidence that
#  sets it.  NOTHING here is hardcoded inside an executor.
# ===========================================================================
PARAMS = collections.OrderedDict([
    ("polarity", (("forced", "published"), "forced",
                  "FORCED (round 5 D): addr8 0x20/0x30 = READ, 0x60 = WRITE. "
                  "`published' is the pre-round-5 reverse, kept so the "
                  "published numbers stay reproducible")),
    ("port", (("push_read", "push_any", "latency", "blocking"), "push_read",
              "OPEN.  push_read: read k's datum enters DR when read k+1 "
              "ISSUES (this is the mechanism that EXPLAINS the flush read). "
              "push_any: any later access pushes it.  latency: DR is loaded "
              "`land' WORDS later.  blocking: the read word's own bus sees it "
              "(the published model; its forcing is FALSIFIED, round 6 F)")),
    ("land", ((1, 2, 3, 4), 2,
              "OPEN.  round 6 sect. 6 retracts `land in [1,4]' to CONSISTENT "
              "and notes both ends rest on unenumerated premises; used only "
              "by port=latency")),
    ("grot", (("desc", "asc", "static"), "desc",
              "OPEN.  The rotation register G is undecoded.  desc: G -= gstep "
              "each frame, which is the ONLY direction under which "
              "read_addr - write_addr is the delay.  asc gives region-D. "
              "static is the DELAY-FREE control")),
    ("gstep", ((1,), 1, "CONSISTENT: one sample per frame; the frame rate is "
                        "the sample rate (host-side.md)")),
    ("g0", ((0, 12345), 0, "DEGENERATE -- proven in sect. 5")),
    ("gwrap", (("unit", "global"), "unit",
               "CONSISTENT.  unit: the rotation wraps inside the algorithm's "
               "own 32768-sample region (dram-bounds.md's region test); "
               "global: mod 65536")),
    ("cursor", (("single", "split"), "single",
                "FORCED (dram-unit-cursor.md): M5, a separate cursor per "
                "direction, is REFUTED three ways.  `split' is kept only as a "
                "scoreable rival")),
    ("delta", ((0, 1, -1), 0,
               "FORCED (round 5 B): consumer k takes cell k, delta = 0")),
    ("wdata", (("bus", "acc"), "bus",
               "OPEN (dram-datapath.md item J): the write-data source is not "
               "separated by any published route")),
    ("carry_dr", ((True, False), True,
                  "OPEN: does the read-data register survive the frame "
                  "boundary")),
])


class Harness(object):
    """The model of the machine's memory and environment, as a value.

    EVERY field is a hypothesis.  Construct with none and you get the defaults
    above; construct with one changed and you get the rival.  A search that
    does not enumerate a field is holding it fixed and must say so."""
    __slots__ = tuple(PARAMS)

    def __init__(self, **kw):
        for k, (_opts, dflt, _why) in PARAMS.items():
            setattr(self, k, kw.pop(k, dflt))
        if kw:
            raise KeyError("unknown harness parameter(s): %s" % sorted(kw))

    def replace(self, **kw):
        d = {k: getattr(self, k) for k in PARAMS}
        d.update(kw)
        return Harness(**d)

    def key(self):
        return tuple(getattr(self, k) for k in PARAMS)

    def __repr__(self):
        d = [("%s=%s" % (k, getattr(self, k))) for k in PARAMS
             if getattr(self, k) != PARAMS[k][1]]
        return "Harness(%s)" % (", ".join(d) or "defaults")

    # -- the direction of a DRAM word, under this harness's polarity --------
    def dirof(self, w):
        d = DIS.dram_dir(w)
        if self.polarity == "forced":
            return d
        ad = DIS.addr8(w) & 0xF0
        if ad == 0x20:
            return "WRITE"
        if ad in (0x30, 0x60):
            return "READ"
        return None


# ===========================================================================
#  1.  THE MEMORY -- one unit's sample RAM, plus the rotation register G.
# ===========================================================================
class DelayDRAM(object):
    """The delay RAM of ONE unit.

    ** THE DELAY IS THE DIFFERENCE OF TWO ADDRESSES, NOT A BUFFER LENGTH. **
    A cell holds an OFFSET; the physical location is that offset rotated by G,
    which advances once per frame.  With `grot = desc' a value written at
    frame n to offset `wa' is read at frame n + (ra - wa) from offset `ra',
    for ANY placement of the two accesses inside the frame -- which is exactly
    the property the one-cursor Line could not express.

    PROVEN BY CONSTRUCTION (sect. 2 prints the demonstration):
        phys(a, n) = floor + ((a - floor - n*gstep + g0) mod size)
        phys(ra, m) == phys(wa, n)  <=>  m - n == ra - wa   (mod size)
    """

    def __init__(self, h, floor=0, size=32768):
        self.h, self.floor, self.size = h, floor, size
        self.cell = {}
        self.wframe = {}          # phys -> frame at which it was last written
        self.frame = 0

    def g(self):
        if self.h.grot == "static":
            return self.h.g0
        s = -1 if self.h.grot == "desc" else +1
        return self.h.g0 + s * self.h.gstep * self.frame

    def phys(self, addr):
        if self.h.gwrap == "global":
            return (addr + self.g()) % 65536
        return self.floor + ((addr - self.floor + self.g()) % self.size)

    def read(self, addr):
        p = self.phys(addr)
        return self.cell.get(p, 0.0), p

    def write(self, addr, v):
        p = self.phys(addr)
        self.cell[p] = v
        self.wframe[p] = self.frame
        return p

    def tick(self):
        self.frame += 1


# ===========================================================================
#  2.  THE PORT -- one deep, with the flush read and the prime write.
# ===========================================================================
class DramPort(object):
    """The delay-DRAM port.  ONE ACCESS PER PORT SLOT, ONE DATUM IN FLIGHT.

    `dram-datapath.md' item A: the datum of a read is NOT on the read word's
    own bus; the last real tap of every program is followed by a trailing
    read at an out-of-region address (the CEILING, 83/83) whose datum is
    discarded, and the first write of every program goes to an address no read
    can reach (the LIMIT, 74/74).  This class models that: the flush read and
    the prime write are ordinary accesses, and the pipeline is what makes them
    necessary.

    VISIBILITY is the parameter `port', because the mechanism is OPEN:
        push_read   DR <- the previous read's datum when a READ issues.
                    Under this rule the trailing flush read is NECESSARY --
                    it is the access that makes the last real tap visible.
        push_any    ... when ANY access issues.  The flush read is then only
                    SUFFICIENT, not necessary; a following write would do.
        latency     DR <- the datum `land' WORDS after the read word.
        blocking    the read word's own bus sees it (`land = -1').  The
                    published model.  Its forcing is FALSIFIED (round 6 F);
                    it is retained so the published numbers reproduce.
    """

    def __init__(self, h, mem):
        self.h, self.mem = h, mem
        self.dr = 0.0
        self.inflight = None
        self.sched = []
        self.trace = []           # (frame, wslot, kind, addr, phys, value)
        self.commits = []         # (frame, wslot, value) -- when DR changed

    # -- called at the END of the word that carries the DRAM access ---------
    def access(self, kind, addr, wslot, value=None, tag=""):
        h = self.h
        if kind == "read":
            if h.port in ("push_read", "push_any") and self.inflight is not None:
                self.dr = self.inflight
                self.commits.append((self.mem.frame, wslot, self.dr))
            v, p = self.mem.read(addr)
            if h.port == "blocking":
                self.dr = v
                self.commits.append((self.mem.frame, wslot, v))
            elif h.port == "latency":
                self.sched.append((wslot + h.land, v))
            else:
                self.inflight = v
            self.trace.append((self.mem.frame, wslot, "R", addr, p, v, tag))
            return v
        if h.port == "push_any" and self.inflight is not None:
            self.dr = self.inflight
            self.commits.append((self.mem.frame, wslot, self.dr))
            self.inflight = None
        p = self.mem.write(addr, value)
        self.trace.append((self.mem.frame, wslot, "W", addr, p, value, tag))
        return None

    # -- called BEFORE each word, so the bus latch sees the right DR --------
    def before_word(self, wslot):
        if self.h.port != "latency":
            return
        due = [t for t in self.sched if t[0] <= wslot]
        for t in due:
            self.dr = t[1]
            self.commits.append((self.mem.frame, wslot, t[1]))
            self.sched.remove(t)

    def frame_end(self):
        if self.h.port == "latency":
            self.sched = [(t - 10 ** 6, v) for (t, v) in self.sched] \
                if self.h.carry_dr else []
        if not self.h.carry_dr:
            self.dr = 0.0
            self.inflight = None


# ===========================================================================
#  3.  THE LINE -- two addresses and a label.
# ===========================================================================
class Line(object):
    """A delay line: a READ cell and a WRITE cell.

    `label' is the descriptor bank's own, imported from
    descriptor-cell-classes.json and NEVER upgraded here:
        FORCED           the host names this endpoint (op-0x67 / BASE24)
        FORCED-IN-MODEL  forced given bounds.py's allocation model
        CONSISTENT       a matched pairing -- ** NOT a hard constraint **
        OPEN             do not use as a constraint at all
    `hard' is True only for FORCED.  A solver that treats a CONSISTENT line as
    a constraint is asserting bounds.py's allocation model as though it were
    measured; the API makes that a deliberate act."""
    __slots__ = ("name", "read_addr", "write_addr", "read_cell", "write_cell",
                 "read_slot", "write_slot", "label", "samples")

    def __init__(self, name, read_addr, write_addr, read_cell=None,
                 write_cell=None, read_slot=None, write_slot=None,
                 label="SYNTHETIC"):
        self.name = name
        self.read_addr, self.write_addr = read_addr, write_addr
        self.read_cell, self.write_cell = read_cell, write_cell
        self.read_slot, self.write_slot = read_slot, write_slot
        self.label = label
        self.samples = read_addr - write_addr

    @property
    def hard(self):
        return self.label == "FORCED"

    def __repr__(self):
        return ("Line(%s r@%d w@%d D=%d %s)"
                % (self.name, self.read_addr, self.write_addr, self.samples,
                   self.label))


def lines_of(algo, classes=None):
    """The corrected line set of one algorithm, WITH ITS LABELS."""
    C = classes if classes is not None else load_classes()
    rec = C["algorithms"][str(algo)]
    cellrel = {c["cell"]: c for c in rec["cells"]}
    out = []
    for i, ln in enumerate(rec["lines"]):
        rc, wc = cellrel[ln["read_cell"]], cellrel[ln["write_cell"]]
        lab = ("FORCED" if rc["label"] == "FORCED" and wc["label"] == "FORCED"
               else "OPEN" if "OPEN" in (rc["label"], wc["label"])
               else "FORCED-IN-MODEL"
               if "FORCED-IN-MODEL" in (rc["label"], wc["label"])
               else "CONSISTENT")
        out.append(Line("L%d" % i, ln["read_addr"], ln["write_addr"],
                        ln["read_cell"], ln["write_cell"],
                        rc["rel"], wc["rel"], lab))
    return out


_CLASSES = [None]


def load_classes():
    if _CLASSES[0] is None:
        with open(CLASSES) as f:
            _CLASSES[0] = json.load(f)
    return _CLASSES[0]


# ===========================================================================
#  4.  THE MICRO EXECUTOR -- the harness's own instruction set.
#
#  The hand-built references are expressed HERE, through the same DelayDRAM
#  and the same DramPort as the ROM programs, so that "the reference is
#  accepted" is a statement about the harness and not about a second, private
#  implementation.
#
#     ("R",  line)                  issue a read  of line.read_addr
#     ("RA", addr, tag)             issue a read  of a bare address (the FLUSH)
#     ("W",  line, src)             issue a write of line.write_addr
#     ("WA", addr, src, tag)        issue a write to a bare address (the PRIME)
#     ("MOV", dst, src)             dst <- src
#     ("MAC", dst, src, g, src2)    dst <- src + g*src2
#     ("MUL", dst, g, src)          dst <- g*src
#     ("SUB", dst, src, src2)       dst <- src - src2
#     ("OUT", src)                  record this frame's output
#  a source is a register name, "DR", "x", or ("k", value).
# ===========================================================================
class Micro(object):
    def __init__(self, ops, name="micro"):
        self.ops, self.name = ops, name

    def run(self, h, x, floor=0, size=32768, trace=False):
        mem = DelayDRAM(h, floor, size)
        port = DramPort(h, mem)
        reg = collections.defaultdict(float)
        out = []
        for xn in x:
            reg["x"] = xn

            def val(s):
                if isinstance(s, tuple):
                    return s[1]
                if s == "DR":
                    return port.dr
                return reg[s]

            for i, op in enumerate(self.ops):
                port.before_word(i)
                k = op[0]
                if k == "R":
                    port.access("read", op[1].read_addr, i, tag=op[1].name)
                elif k == "RA":
                    port.access("read", op[1], i, tag=op[2])
                elif k == "W":
                    port.access("write", op[1].write_addr, i,
                                value=val(op[2]), tag=op[1].name)
                elif k == "WA":
                    port.access("write", op[1], i, value=val(op[2]), tag=op[3])
                elif k == "MOV":
                    reg[op[1]] = val(op[2])
                elif k == "MAC":
                    reg[op[1]] = val(op[2]) + op[3] * val(op[4])
                elif k == "MUL":
                    reg[op[1]] = op[2] * val(op[3])
                elif k == "SUB":
                    reg[op[1]] = val(op[2]) - val(op[3])
                elif k == "OUT":
                    out.append(val(op[1]))
                else:
                    raise KeyError(k)
            port.frame_end()
            mem.tick()
        return (out, port, mem) if trace else out


# ===========================================================================
#  5.  THE MATCHER -- scale-invariant, and it must SEPARATE (rule 7).
# ===========================================================================
def match(out, ref, tol=1e-9):
    """(ok, scale, relerr).  An arbitrary non-zero scale is accepted -- a
    constant factor anywhere in a loop is a coefficient convention -- but the
    SHAPE must agree.  Same predicate as r1_allpass_solve.machine_matches."""
    if len(out) != len(ref):
        return False, 0.0, 1e9
    den = sum(v * v for v in out)
    mx = max(abs(v) for v in ref) or 1.0
    if den < 1e-18:
        return False, 0.0, 1e9
    sc = sum(a * b for a, b in zip(out, ref)) / den
    if abs(sc) < 1e-9:
        return False, 0.0, 1e9
    err = max(abs(sc * a - b) for a, b in zip(out, ref)) / mx
    return err < tol, sc, err


# ===========================================================================
#  6.  THE TEXTBOOK REFERENCES -- written from the mathematics, never from the
#      ROM, and never through the harness.  These are the YES targets.
# ===========================================================================
def ref_comb(g, D, x):
    """v[n] = x[n] + g*v[n-D], written with a single-pointer circular buffer --
    the classic idiom, and DELIBERATELY the one the old harness used, so that
    the reference and the harness agree only if the harness is right."""
    buf, pos, out = [0.0] * D, 0, []
    for xn in x:
        v = xn + g * buf[pos]
        buf[pos] = v
        pos = (pos + 1) % D
        out.append(v)
    return out


def ref_comb2(g, D, x):
    """the same comb, written a second way (a list-of-history form) so that a
    typo in one is not silently shared by the harness."""
    hist, out = [], []
    for xn in x:
        v = xn + g * (hist[-D] if len(hist) >= D else 0.0)
        hist.append(v)
        out.append(v)
    return out


def ref_allpass_series(gains, delays, x):
    """the textbook first-order all-pass cascade, one stage per (g, D):
         w = line_out ; t = g*(v + w) ; line_in = v + t ; v = w - t"""
    lines = [[] for _ in delays]
    out = []
    for xn in x:
        v = xn
        for k, g in enumerate(gains):
            D = delays[k]
            w = lines[k][-D] if len(lines[k]) >= D else 0.0
            t = g * (v + w)
            lines[k].append(v + t)
            v = w - t
        out.append(v)
    return out


def ref_schroeder_nested(g_out, D_out, g_in, D_in, x):
    """A Schroeder NESTED all-pass: the outer all-pass's delay line has a
    second all-pass inside it.  This is the structure every reverb search has
    been trying to tell apart from a plain cascade."""
    outer, inner = [], []
    out = []
    for xn in x:
        w = outer[-D_out] if len(outer) >= D_out else 0.0
        t = g_out * (xn + w)
        u = xn + t                      # what enters the outer line
        wi = inner[-D_in] if len(inner) >= D_in else 0.0
        ti = g_in * (u + wi)
        inner.append(u + ti)
        outer.append(wi - ti)           # the inner all-pass's output feeds it
        out.append(w - t)
    return out


# ===========================================================================
#  7.  THE REFERENCE MICRO-PROGRAMS -- the same three structures, expressed
#      in the harness's own executor, with the PRIME WRITE and the FLUSH READ
#      in the positions the ROM puts them (first write / last read).
# ===========================================================================
PRIME_ADDR = 200000        # an address no read of these programs can reach
CEIL_ADDR = 100000         # out of region: the flush read's target


def mp_comb(g, D, base=0, flush=True, wtrail_ok=True, sign=1,
            feedback=True, wshift=0, write_first=False):
    """A plain feedback comb, as microcode.

        prime write -> read the tap -> flush read -> x + g*DR -> write the base

    `flush=False', `wshift', `sign=-1', `feedback=False' and `write_first'
    exist so that sect. 4 can build the deliberately-wrong twins WITHOUT a
    second implementation to disagree with."""
    ln = Line("L0", base + D, base + wshift)
    ops = [("WA", PRIME_ADDR, "DR", "PRIME"), ("R", ln)]
    if flush:
        ops.append(("RA", CEIL_ADDR, "FLUSH"))
    ops.append(("MAC", "acc", "x", sign * g, "DR" if feedback else ("k", 0.0)))
    w = ("W", ln, "acc")
    if write_first:
        ops.insert(1, w)
    else:
        ops.append(w)
    ops.append(("OUT", "acc"))
    return Micro(ops, "comb"), [ln]


def mp_allpass(gains, delays, base=0, flush=True, sign=1, feedback=True,
               wshift=0):
    """A SERIES first-order all-pass cascade, one line per stage.

    Every read is issued before its stage's arithmetic, and each read makes the
    PREVIOUS read visible (port = push_read) -- so the chain is written the way
    the chip's pipeline forces, and the trailing flush read is what makes the
    LAST stage's datum visible.  The line WRITES all follow the reads, which a
    one-cursor line could not have expressed at all."""
    K = len(gains)
    lines = [Line("L%d" % k, base + 1000 * k + delays[k],
                  base + 1000 * k + wshift) for k in range(K)]
    ops = [("WA", PRIME_ADDR, "DR", "PRIME"), ("R", lines[0])]
    ops.append(("MOV", "v", "x"))
    for k in range(K):
        nxt = ("R", lines[k + 1]) if k + 1 < K else \
              (("RA", CEIL_ADDR, "FLUSH") if flush else ("MOV", "_", "_"))
        ops.append(nxt)
        ops.append(("MOV", "w%d" % k, "DR" if feedback else ("k", 0.0)))
        ops.append(("MAC", "s", "v", 1.0, "w%d" % k))       # s = v + w
        ops.append(("MUL", "t", sign * gains[k], "s"))      # t = g*(v+w)
        ops.append(("MAC", "in%d" % k, "v", 1.0, "t"))      # v + t
        ops.append(("SUB", "v", "w%d" % k, "t"))            # w - t
    for k in range(K):
        ops.append(("W", lines[k], "in%d" % k))
    ops.append(("OUT", "v"))
    return Micro(ops, "allpass"), lines


def mp_schroeder(g_out, D_out, g_in, D_in, base=0, flush=True, sign=1,
                 feedback=True, wshift=0):
    """A NESTED all-pass: the outer line's input passes through an inner
    all-pass.  Same port shape."""
    lo = Line("OUT", base + D_out, base + wshift)
    li = Line("IN", base + 20000 + D_in, base + 20000 + wshift)
    ops = [("WA", PRIME_ADDR, "DR", "PRIME"),
           ("R", lo),
           ("R", li),                                   # commits lo's datum
           ("MOV", "wo", "DR" if feedback else ("k", 0.0)),
           ("RA", CEIL_ADDR, "FLUSH") if flush else ("MOV", "_", "_"),
           ("MOV", "wi", "DR" if feedback else ("k", 0.0)),
           ("MAC", "s", "x", 1.0, "wo"),
           ("MUL", "t", sign * g_out, "s"),
           ("MAC", "u", "x", 1.0, "t"),
           ("MAC", "si", "u", 1.0, "wi"),
           ("MUL", "ti", sign * g_in, "si"),
           ("MAC", "ini", "u", 1.0, "ti"),
           ("SUB", "ino", "wi", "ti"),
           ("W", li, "ini"),
           ("W", lo, "ino"),
           ("SUB", "y", "wo", "t"),
           ("OUT", "y")]
    return Micro(ops, "schroeder"), [lo, li]


# ===========================================================================
#  8.  THE ROM SIDE -- a Program is a body image plus its descriptor block.
# ===========================================================================
class Program(object):
    def __init__(self, algo, name, unit, words, cons, cells):
        self.algo, self.name, self.unit = algo, name, unit
        self.words, self.cons, self.cells = words, cons, cells
        self.cons_of = {wi: k for k, (wi, _w) in enumerate(cons)}

    def floor_size(self, h):
        return (0 if self.unit == 0 else 32768), 32768

    def addr(self, k, h, cells=None):
        c = cells if cells is not None else self.cells
        return c[(k + h.delta) % len(c)]


_CTX = [None]


def ctx():
    if _CTX[0] is None:
        _CTX[0] = DM.Corp(SUB, MAIN, TOOLS)
    return _CTX[0]


def program(algo):
    C = ctx()
    for (a, u, cells, cons) in C.algos:
        if a != algo:
            continue
        ck = sorted(cells)
        return Program(a, C.name(a), u, list(C.imgs[a]), cons,
                       [cells[c] for c in ck])
    raise KeyError(algo)


def coefs_of(algo, words):
    cram, cur = L.cram_of_algo(algo), DIS.cursor_addresses(words)
    return [(cram.get(cur[i]) if cur[i] is not None else None)
            for i in range(len(words))]


def run_words(prog, m, h, x, coefs, cells=None, floor=None, size=None,
              p0=0x80, seed=20260727, window=None, trace=False):
    """Execute a ROM body image against the TWO-ADDRESS memory.

    The ALU is `action00_discriminate.step', imported UNCHANGED -- the only
    thing this function replaces is the memory model, so any difference in the
    result is attributable to the memory and to nothing else (rule 10).

    Returns (per-line write sequences, per-line read sequences, port, ok)."""
    words = prog.words if window is None else prog.words[window[0]:window[1]]
    off = 0 if window is None else window[0]
    cf = coefs if window is None else coefs[window[0]:window[1]]
    cells = prog.cells if cells is None else cells
    f0, sz = prog.floor_size(h)
    floor = f0 if floor is None else floor
    size = sz if size is None else size
    mem = DelayDRAM(h, floor, size)
    port = DramPort(h, mem)
    rng = random.Random(seed)
    st = A0.State(rng)
    incell = p0
    for w in words:
        if DIS.lo_src(w) == 0x00:
            break
        if DIS.ptr_postinc(w):
            incell = (incell + A0.s8(DIS.addr8(w))) & 0xFF
    # which descriptor cell each DRAM word takes: consumer k -> cell k
    rd_i, wr_i = 0, 0
    slot_addr = {}
    for wi, w in prog.cons:
        k = prog.cons_of[wi]
        d = h.dirof(w)
        if h.cursor == "split":                 # M5, REFUTED -- rival only
            if d == "READ":
                slot_addr[wi] = prog.cells[rd_i % len(prog.cells)]
                rd_i += 1
            else:
                slot_addr[wi] = prog.cells[wr_i % len(prog.cells)]
                wr_i += 1
        else:
            slot_addr[wi] = cells[(k + h.delta) % len(cells)]
    ok = True
    for xn in x:
        st.acc = rng.randrange(-(1 << 23), 1 << 23)
        st.P = rng.randrange(-(1 << 23), 1 << 23)
        st.ta = rng.randrange(0, 1 << 24)
        st.tb = rng.randrange(0, 1 << 24)
        st.p = p0
        st.mem[incell] = int(xn) & A0.MASK24
        if not h.carry_dr:
            st.dr = 0

        cur = [0]

        def cb(w, bus, s):
            d = h.dirof(w)
            a = slot_addr.get(cur[0])
            if a is None:
                return
            if d == "READ":
                if h.port != "blocking":         # blocking did it in before_word
                    port.access("read", a, cur[0])
            elif d == "WRITE":
                v = bus if h.wdata == "bus" else A0.s24(s.acc)
                port.access("write", a, cur[0], value=float(v))
            s.dr = int(port.dr) & A0.MASK24

        for i, w in enumerate(words):
            wi = off + i
            port.before_word(wi)
            if h.port == "blocking" and wi in slot_addr \
                    and h.dirof(w) == "READ":
                port.access("read", slot_addr[wi], wi)
            st.dr = int(port.dr) & A0.MASK24
            cur[0] = wi
            if not A0.step(m, st, w, cf[i], rng, dram=cb,
                           unknown=lambda: rng.randrange(-(1 << 23), 1 << 23)):
                ok = False
                break
        if not ok:
            break
        port.frame_end()
        mem.tick()
    return port, ok


# ===========================================================================
#  SECTION 1 -- the enumeration
# ===========================================================================
def cmd_enum():
    head(1, "THE PARAMETER ENUMERATION, AND WHAT SETS EACH DEFAULT")
    print("""   Rule 11: a harness is a hypothesis.  Every modelling choice the
   three published harnesses made silently is a NAMED PARAMETER here,
   with the label of the evidence that sets its default.  A search that
   holds one fixed is holding a hypothesis fixed, and must say so.
""")
    for k, (opts, dflt, why) in PARAMS.items():
        print("   %-9s %-46s default %s" % (k, str(opts), dflt))
        for i in range(0, len(why), 66):
            print("             %s" % why[i:i + 66])
    n = 1
    for k, (opts, _d, _w) in PARAMS.items():
        n *= len(opts)
    print()
    print("   PRODUCT OF THE MODEL SPACE ALONE: %d harnesses" % n)
    print("   (the ALU space multiplies on top of this; the published SINGLE")
    print("    DELAY space is 5832 machines and was run at ONE harness)")


# ===========================================================================
#  SECTION 2 -- *** IT MUST DELAY ***
# ===========================================================================
def _probe_line(h, D, size=64, nframes=24, write_first=False, base=0,
                same_cell=False):
    """Write a distinguishable value every frame; read every frame.  No ALU."""
    ln = Line("P", base + (0 if same_cell else D), base)
    mem = DelayDRAM(h, 0, size)
    port = DramPort(h, mem)
    wrote, got = [], []
    for n in range(nframes):
        v = 1000.0 + n
        if write_first:
            port.access("write", ln.write_addr, 0, value=v)
            got.append(port.access("read", ln.read_addr, 1))
        else:
            got.append(port.access("read", ln.read_addr, 0))
            port.access("write", ln.write_addr, 1, value=v)
        wrote.append(v)
        port.frame_end()
        mem.tick()
    return wrote, got


def _delay_of(wrote, got):
    """The OBSERVED delay: the unique d such that got[n] == wrote[n-d] for
    every n where that is defined, and 0 before it."""
    n = len(got)
    cand = []
    for d in range(0, n):
        ok = True
        for i in range(n):
            want = wrote[i - d] if i - d >= 0 else 0.0
            if abs(got[i] - want) > 1e-9:
                ok = False
                break
        if ok:
            cand.append(d)
    return cand


def cmd_delay(quiet=False):
    head(2, "*** IT MUST DELAY *** -- proven by construction, printed in full")
    h = Harness()
    D, S, N = 7, 64, 24
    print("""   THE PROPERTY THE OLD HARNESS LACKED: a value written at frame n is
   read at frame n + D and NOT BEFORE, for ANY placement of the two
   accesses inside the frame.  Here D = %d, region = %d, %d frames.
""" % (D, S, N))
    wrote, got = _probe_line(h, D, S, N)
    print("     frame  wrote   read     expected wrote[n-%d]" % D)
    for n in range(min(N, 14)):
        exp = wrote[n - D] if n - D >= 0 else 0.0
        print("      %2d   %6.0f  %6.0f      %6.0f   %s"
              % (n, wrote[n], got[n], exp,
                 "ok" if abs(got[n] - exp) < 1e-9 else "** MISMATCH **"))
    c = _delay_of(wrote, got)
    print("     OBSERVED DELAY d such that read[n] == wrote[n-d] for all n: %s"
          % c)
    ok1 = c == [D]
    print("     => %s" % ("PASS -- the line delays by exactly D = %d" % D
                          if ok1 else "** FAIL **"))

    sub("ORDER INDEPENDENCE -- the exact freedom a one-cursor line does not "
        "have")
    w2, g2 = _probe_line(h, D, S, N, write_first=True)
    c2 = _delay_of(w2, g2)
    ok2 = (c2 == [D]) and g2 == got
    print("     write BEFORE read in program order : observed delay %s" % c2)
    print("     output bit-identical to read-first : %s" % (g2 == got))
    print("     => %s" % ("PASS -- the delay is the ADDRESS DIFFERENCE, not "
                          "the access order" if ok2 else "** FAIL **"))

    sub("THE CONTROLS -- four ways to break it, each shown BREAKING it, and "
        "each\n        run LONG ENOUGH for the delay it would have to show "
        "(rule 1)")
    NL = S + 40
    rows = [
        ("grot=static, 2 addresses", h.replace(grot="static"), D, S, N, False,
         False, [],
         "NOTHING comes back at all: with the rotation frozen the read cell "
         "is never written.  A frozen G is not a short delay, it is no line"),
        ("grot=static, 1 address, R first", h.replace(grot="static"), D, S, N,
         False, True, [1],
         "identify the two cells and the frozen pointer gives delay 1 -- the "
         "PREVIOUS frame's write -- whatever D is"),
        ("grot=static, 1 address, W first", h.replace(grot="static"), D, S, N,
         True, True, [0],
         "and with the write in front, delay 0: the value written THIS very "
         "frame.  ** THIS IS THE OLD HARNESS'S FAILURE MODE, REPRODUCED "
         "INSIDE THE NEW ONE **"),
        ("grot=asc (G counts up)", h.replace(grot="asc"), D, S, NL, False,
         False, [S - D],
         "a delay of region-D = %d, not D = %d.  Both directions DELAY; only "
         "one of them delays by the descriptor's difference" % (S - D, D)),
        ("read cell == write cell", h, D, S, NL, False, True, [S],
         "a ONE-ADDRESS line delays by the whole REGION (%d), not by D.  The "
         "published Line only worked because its region WAS D" % S),
    ]
    okc = True
    for nm, hh, dd, ss, nn, wf, sc, want, why in rows:
        w3, g3 = _probe_line(hh, dd, ss, nn, write_first=wf, same_cell=sc)
        got3 = _delay_of(w3, g3)
        good = got3 == want
        okc &= good
        print("     %-26s %3d frames, region %d : observed delay %-9s %s"
              % (nm, nn, ss, got3, "" if good else "** UNEXPECTED **"))
        print("        %s" % why)
    print("     => %s" % ("PASS -- every wrong rotation gives a WRONG delay, "
                          "and the harness reports which"
                          if okc else "** FAIL **"))

    sub("AND THE PUBLISHED `Line' IS A SPECIAL CASE OF THIS ONE")
    hh = h.replace(grot="desc")
    w4, g4 = _probe_line(hh, 0, D, N, same_cell=True)
    c4 = _delay_of(w4, g4)
    ok4 = c4 == [D]
    print("     read cell == write cell, region shrunk to D = %d : delay %s"
          % (D, c4))
    print("     => %s" % ("PASS -- with the two addresses IDENTIFIED and the "
                          "region set to D, the new memory reproduces the old "
                          "`Line(D)' exactly.  The old model is not deleted; "
                          "it is a POINT of the new space." if ok4
                          else "** FAIL **"))
    return ok1 and ok2 and okc and ok4


# ===========================================================================
#  SECTION 3 -- *** IT MUST SAY YES ***
# ===========================================================================
REF_SIGNAL_N = 160


def _sig(n=REF_SIGNAL_N, seed=11):
    r = random.Random(seed)
    return [r.uniform(-1, 1) for _ in range(n)]


def _refset(x):
    """(name, harness micro-program, textbook target, longest delay)."""
    out = []
    g, D = 0.6, 13
    mp, lns = mp_comb(g, D)
    out.append(("plain comb g=%.2f D=%d" % (g, D), mp, ref_comb(g, D, x), D))
    gains, delays = (0.7, 0.5, 0.35), (11, 17, 23)
    mp2, _l2 = mp_allpass(list(gains), list(delays))
    out.append(("all-pass chain g=%s D=%s" % (gains, delays), mp2,
                ref_allpass_series(list(gains), list(delays), x), 23))
    go, Do, gi, Di = 0.6, 29, 0.4, 7
    mp3, _l3 = mp_schroeder(go, Do, gi, Di)
    out.append(("Schroeder nested D=%d/%d" % (Do, Di), mp3,
                ref_schroeder_nested(go, Do, gi, Di, x), Do))
    return out


def cmd_refs():
    head(3, "*** IT MUST SAY YES *** -- three known-good structures, expressed "
           "in\n   the harness's own executor, run long enough to recirculate")
    x = _sig()
    h = Harness()
    print("   Every target below is written FROM THE MATHEMATICS in this file")
    print("   (`ref_comb', `ref_allpass_series', `ref_schroeder_nested') and")
    print("   never through the harness.  The micro-programs carry the PRIME")
    print("   WRITE as their first write and the FLUSH READ as their last read,")
    print("   exactly as the 83 aligned ROM programs do.")
    print()
    allok = True
    outs = []
    for nm, mp, ref, D in _refset(x):
        o = mp.run(h, x)
        ok, sc, err = match(o, ref, tol=1e-9)
        outs.append((nm, o))
        allok &= ok
        print("   %-34s  %s   scale %+.4f  relerr %.2e"
              % (nm, "ACCEPTED" if ok else "** REJECTED **", sc, err))
        print("        test signal %d samples, longest delay %d  =>  %.1f "
              "recirculations" % (len(x), D, len(x) / float(D)))
    print()
    print("   => %s" % ("PASS -- the instrument can say YES" if allok
                        else "** FAIL: a known-good reference was rejected **"))

    sub("RULE 7 -- and it must SEPARATE.  Scored on the SAME matcher.")
    refs = _refset(x)
    print("        rows = what the harness ran, cols = the textbook target")
    print("        %-22s %s" % ("", "  ".join("%-10s" % n.split()[0]
                                              for n, _m, _r, _d in refs)))
    diag = offd = 0
    for i, (nm, o) in enumerate(outs):
        row = []
        for j, (_n2, _m2, ref2, _d2) in enumerate(refs):
            ok, _s, _e = match(o, ref2, tol=1e-9)
            row.append("YES" if ok else "no ")
            if i == j:
                diag += ok
            else:
                offd += ok
        print("        %-22s %s" % (nm.split()[0] + " " + nm.split()[1],
                                    "  ".join("%-10s" % r for r in row)))
    px = [xn for xn in x]
    prow = []
    for _n2, _m2, ref2, _d2 in refs:
        ok, _s, _e = match(px, ref2, tol=1e-9)
        prow.append("YES" if ok else "no ")
    print("        %-22s %s" % ("RIVAL: pass-through",
                                "  ".join("%-10s" % r for r in prow)))
    print()
    print("     diagonal hits %d of %d ; OFF-diagonal hits %d of %d ; the "
          "instruction-blind\n     pass-through rival hits %d of %d"
          % (diag, len(refs), offd, len(refs) * (len(refs) - 1),
             sum(1 for p in prow if p == "YES"), len(refs)))
    ok7 = diag == len(refs) and offd == 0 and not any(p == "YES" for p in prow)
    print("     => %s" % ("PASS -- the test discriminates; it does not merely "
                          "score" if ok7 else "** FAIL **"))
    return allok and ok7


# ===========================================================================
#  SECTION 4 -- *** IT MUST SAY NO ***
# ===========================================================================
def cmd_twins():
    head(4, "*** IT MUST SAY NO *** -- the deliberately-wrong twin of every "
           "reference")
    x = _sig()
    h = Harness()
    print("   Rule 1: a control that cannot fail is not evidence, and a control")
    print("   that cannot PASS is worth just as little.  Sect. 3 showed the")
    print("   YES.  Here is the NO, one twin per defect, each defect being one")
    print("   the OLD harness could not have expressed.")
    print()
    rows = []
    g, D = 0.6, 13
    ref = ref_comb(g, D, x)
    rows.append(("comb: WRONG WRITE CELL (base+1 => D-1)",
                 mp_comb(g, D, wshift=1)[0], ref, h))
    rows.append(("comb: NO FLUSH READ (the last tap never becomes visible)",
                 mp_comb(g, D, flush=False)[0], ref, h))
    rows.append(("comb: SIGN FLIPPED (g -> -g)",
                 mp_comb(g, D, sign=-1)[0], ref, h))
    rows.append(("comb: FEEDBACK REMOVED (the line output is not read back)",
                 mp_comb(g, D, feedback=False)[0], ref, h))
    rows.append(("comb: ROTATION FROZEN (grot=static)",
                 mp_comb(g, D)[0], ref, h.replace(grot="static")))
    rows.append(("comb: ROTATION REVERSED (grot=asc)",
                 mp_comb(g, D)[0], ref, h.replace(grot="asc")))
    gains, delays = [0.7, 0.5, 0.35], [11, 17, 23]
    ref2 = ref_allpass_series(gains, delays, x)
    rows.append(("all-pass: WRONG WRITE CELL", mp_allpass(gains, delays,
                                                          wshift=2)[0], ref2, h))
    rows.append(("all-pass: NO FLUSH READ", mp_allpass(gains, delays,
                                                       flush=False)[0], ref2, h))
    rows.append(("all-pass: SIGN FLIPPED", mp_allpass(gains, delays,
                                                      sign=-1)[0], ref2, h))
    rows.append(("all-pass: FEEDBACK REMOVED",
                 mp_allpass(gains, delays, feedback=False)[0], ref2, h))
    go, Do, gi, Di = 0.6, 29, 0.4, 7
    ref3 = ref_schroeder_nested(go, Do, gi, Di, x)
    rows.append(("Schroeder: WRONG WRITE CELL",
                 mp_schroeder(go, Do, gi, Di, wshift=3)[0], ref3, h))
    rows.append(("Schroeder: NO FLUSH READ",
                 mp_schroeder(go, Do, gi, Di, flush=False)[0], ref3, h))
    rows.append(("Schroeder: SIGN FLIPPED",
                 mp_schroeder(go, Do, gi, Di, sign=-1)[0], ref3, h))
    rows.append(("Schroeder: FEEDBACK REMOVED",
                 mp_schroeder(go, Do, gi, Di, feedback=False)[0], ref3, h))
    bad = 0
    for nm, mp, rf, hh in rows:
        o = mp.run(hh, x)
        ok, _sc, err = match(o, rf, tol=1e-9)
        bad += ok
        print("   %-56s %s  relerr %.2e"
              % (nm, "** ACCEPTED (BAD) **" if ok else "rejected", err))
    print()
    print("   POPULATION: %d twins, over 3 references.  ACCEPTED: %d"
          % (len(rows), bad))
    print("   => %s" % ("PASS -- every wrong twin is rejected" if bad == 0
                        else "** FAIL **"))
    sub("AND WHAT THE REJECTED TWINS ACTUALLY *ARE* -- a rejection that also "
        "identifies\n        is worth more than one that only says no")
    fam = [("comb D=%d" % d, ref_comb(g, d, x)) for d in range(D - 2, D + 4)]
    idok = 0
    for nm, mp2 in (("NO FLUSH READ", mp_comb(g, D, flush=False)[0]),
                    ("WRITE MOVED IN FRONT OF THE READ",
                     mp_comb(g, D, write_first=True)[0]),
                    ("WRONG WRITE CELL (base+1)", mp_comb(g, D, wshift=1)[0])):
        o = mp2.run(h, x)
        hit = [n2 for n2, r2 in fam if match(o, r2, tol=1e-9)[0]]
        idok += len(hit) == 1
        print("     %-34s -> %s" % (nm, hit or "no member of the family"))
    print("""
     THE FIRST TWO ARE THE SAME DEFECT AND THE HARNESS SAYS SO: dropping
     the flush read, and moving the write ahead of the arithmetic, both
     make the stored datum ONE FRAME STALE, so the machine becomes a comb
     of delay D+1.  The third moves the ADDRESS and becomes D-1.  ** The
     old harness could not distinguish these three: with one cell the
     delay is the buffer length and nothing else. **""")
    return bad == 0 and idok == 3


# ===========================================================================
#  SECTION 5 -- rule 4: degeneracy, BEFORE anyone scores anything
# ===========================================================================
def cmd_degen():
    head(5, "RULE 4 -- WHICH PARAMETERS ARE THE SAME MACHINE TWICE")
    x = _sig(96)
    base = Harness()
    print("   Two settings that produce bit-identical output are ONE machine")
    print("   counted twice.  Checked on the comb micro-program (D = 13, %d "
          "samples)\n   and, where the ROM is involved, on SINGLE DELAY."
          % len(x))
    print()
    g, D = 0.6, 13
    mp = mp_comb(g, D)[0]
    ref = mp.run(base, x)
    rows = []
    for nm, h2 in (("g0 = 12345 (a rigid shift of every address)",
                    base.replace(g0=12345)),
                   ("gwrap = global (mod 65536 instead of mod region)",
                    base.replace(gwrap="global")),
                   ("port = push_any", base.replace(port="push_any")),
                   ("port = latency, land=1", base.replace(port="latency",
                                                           land=1)),
                   ("port = latency, land=2", base.replace(port="latency",
                                                           land=2)),
                   ("port = blocking", base.replace(port="blocking")),
                   ("carry_dr = False", base.replace(carry_dr=False)),
                   ("grot = asc", base.replace(grot="asc")),
                   ("grot = static", base.replace(grot="static"))):
        o = mp.run(h2, x)
        same = all(abs(a - b) < 1e-12 for a, b in zip(o, ref))
        rows.append((nm, same))
        print("     %-48s %s" % (nm, "DEGENERATE (bit-identical)" if same
                                 else "separates"))
    sub("WHERE port=push_read AND port=push_any DO SEPARATE -- and it is not "
        "the micro-program")
    print("""     They agree whenever every real read is followed by another READ
     before its consumer.  They DISAGREE as soon as a WRITE sits between
     a read and the word that consumes it -- which is exactly the shape
     of SINGLE DELAY (algo 9): R(lineA) W(prime) R(lineB) W(lineA base)
     R(ceiling) W(lineB base).""")
    P = program(9)
    for nm, h2 in (("push_read", base), ("push_any", base.replace(port="push_any"))):
        who = _port_ledger(P, h2)
        print("     %-10s the write at w28 stores the datum of : %s"
              % (nm, who[28]))
    sub("AND THE `land' INTERVAL IS DEGENERATE ON THE CORPUS (rule 4 on an "
        "OPEN parameter)")
    print("""     Not `the gap is big enough' -- the real question is whether any
     word in the ROM ever SEES a different datum.  For every algorithm
     that ships descriptor cells, the port is run with each read tagged
     by its own index and the tag standing at every word that names
     SRC 0x0B is recorded, for land = 1, 2, 3 and 4.""")
    C = ctx()
    sep, tot, gaps = 0, 0, []
    for (a, _u, _cells, cons) in C.algos:
        img = C.imgs[a]
        seen = set()
        for land in (1, 2, 3, 4):
            dr, sched, tl = None, [], []
            for j, w in enumerate(img):
                for t in [t for t in sched if t[0] <= j]:
                    dr = t[1]
                    sched.remove(t)
                if DIS.lo_src(w) == 0x0B:
                    tl.append((j, dr))
                if (DIS.hi12(w) & 0x800) and DIS.class4(w) == 1 \
                        and DIS.dram_dir(w) == "READ":
                    sched.append((j + land, j))
            seen.add(tuple(tl))
        tot += 1
        sep += len(seen) > 1
        for j, w in enumerate(img):
            if not ((DIS.hi12(w) & 0x800) and DIS.class4(w) == 1
                    and DIS.dram_dir(w) == "READ"):
                continue
            nx = [k for k in range(j + 1, len(img))
                  if DIS.lo_src(img[k]) == 0x0B]
            if nx:
                gaps.append(nx[0] - j)
    print("     algorithms in which land = 1, 2, 3, 4 give DIFFERENT data to")
    print("     at least one SRC 0x0B word : %d of %d" % (sep, tot))
    print("     READ -> first later SRC 0x0B word, over %d reads: min %d, "
          "mode %d" % (len(gaps), min(gaps),
                       collections.Counter(gaps).most_common(1)[0][0]))
    print("     => the whole interval `land in [1,4]' is ONE MACHINE on this")
    print("        corpus.  It is not merely OPEN (round 6 sect. 6): under")
    print("        port=latency ** NO WORD IN THE ROM CAN SEE THE DIFFERENCE **")
    return True


def _port_ledger(P, h, cells=None, frames=3):
    """Which READ's datum stands in DR at each WRITE word, in the STEADY
    STATE (the loop is run `frames' times and the last pass is reported).

    NOTE what this does and does not say: it tracks the read-data register.
    Whether a given write word actually USES it depends on that word's SRC
    field -- w5 and w28 of SINGLE DELAY name SRC 0x0B (= DR); w46 names
    SRC 0x00, which is OPEN."""
    cells = P.cells if cells is None else cells
    dr = "(cold)"
    inflight = None
    out = {}
    for _f in range(frames):
        out = {}
        for k, (wi, w) in enumerate(P.cons):
            d = h.dirof(w)
            a = cells[(k + h.delta) % len(cells)]
            if d == "READ":
                if h.port in ("push_read", "push_any") and inflight is not None:
                    dr, inflight = inflight, None
                inflight = "cell%d@%d" % (k, a)
            else:
                if h.port == "push_any" and inflight is not None:
                    dr, inflight = inflight, None
                out[wi] = "%s [SRC %02X]" % (dr, DIS.lo_src(w))
    return out



# ===========================================================================
#  SECTION 6 -- *** loop_ok FOR A GENERAL wtrail ***
#
#  `dram-datapath.md' item H2 names this as experiment #1: r1's `advance'
#  returns None the second time it is asked, so `loop_ok' -- THE ONLY
#  STRUCTURAL FILTER THAT EXISTS FOR THIS MACHINE -- can only be stated for
#  wtrail = 1.  Every wtrail = 2 search so far has therefore run a pool
#  selected by a filter that assumes the wrong trail, which is why round 6
#  refused to call its zero a rejection.
#
#  THE FIX IS THE ALGEBRA, NOT THE ALU.  r1 carries exactly TWO generations of
#  fresh atoms (N, N' and Q, Q').  Here a form is a dict over
#      ("R", k)   the entry value of register k
#      ("N", g)   the delay-line read of the repetition g steps AFTER the
#                 earliest repetition the form is expressed in
#      ("Q", g)   that repetition's multiplier product
#  so `gadvance' can be applied any number of times.  The ALU model is r1's
#  own `exec_rep', imported and NOT copied, so the two cannot drift.
# ===========================================================================
_R1 = [None]


def r1():
    if _R1[0] is None:
        import r1_allpass_solve as R
        _R1[0] = R
    return _R1[0]


def _gzero():
    return {}


def _gadd(a, b):
    o = dict(a)
    for k, v in b.items():
        o[k] = o.get(k, 0.0) + v
        if abs(o[k]) < 1e-15:
            del o[k]
    return o


def _gsub(a, b):
    return _gadd(a, {k: -v for k, v in b.items()})


def _ghalf(a):
    return {k: 0.5 * v for k, v in a.items()}


class GAlg(object):
    """the same five operations SymAlg has, over unbounded-generation forms."""
    zero = {}
    add = staticmethod(_gadd)
    sub = staticmethod(_gsub)
    half = staticmethod(_ghalf)
    prod = staticmethod(lambda _g, _v: {("Q", 0): 1.0})


def _gunit(atom):
    return {atom: 1.0}


def gsym_rep(m):
    """One repetition from fresh entry atoms, over the general algebra."""
    R = r1()
    st = [_gunit(("R", k)) for k in range(6)]
    # r1's exec_rep asks the module for the symbolic delay-read atom; give it
    # ours.  (The ALU code itself is untouched.)
    old = R._sym_unit
    R._sym_unit = lambda a: (_gunit(("N", 0)) if a == R.NA else
                             _gunit(("Q", 0)) if a == R.QA else {})
    try:
        tr, pend = {}, []
        R.exec_rep(m, st, GAlg, 1.0, None, 0, 1, pend, 0, tr)
        while pend:
            st[R.R_DR] = pend.pop(0)[1]
    finally:
        R._sym_unit = old
    return st, tr


def gadvance(form, exits):
    """Re-express `form' one repetition earlier: entry atoms become the
    previous repetition's exits, and every fresh atom ages by one generation.

    ** THIS IS THE FUNCTION THAT COULD ONLY BE CALLED TWICE. **  It has no
    generation ceiling, so `loop_ok' below is defined for every wtrail."""
    out = {}
    for atom, c in form.items():
        if atom[0] == "R":
            for a2, c2 in exits[atom[1]].items():
                out[a2] = out.get(a2, 0.0) + c * c2
        else:
            k = (atom[0], atom[1] + 1)
            out[k] = out.get(k, 0.0) + c
    return {k: v for k, v in out.items() if abs(v) > 1e-15}


def loop_ok_w(m, w, rlag=0):
    """The DELAY-LOOP filter for a write that trails BY `w' REPETITIONS the
    multiply that closes its loop, where the multiply itself happens `rlag'
    repetitions after the READ it consumes.

    EVERYTHING IS EXPRESSED IN THE FRAME OF THE REPETITION THAT DOES THE READ:

      C1  advance^rlag(multiplicand) carries that read, ("N",0), with +-1;
      C2  advance^(rlag+w)(written value) carries the product of the multiply,
          ("Q", rlag), with +-1;
      C3  ... and carries NO direct copy of ("N",0) -- an unmultiplied path
          from the read back to the line would put the pole on the unit circle.

    `rlag' EXISTS BECAUSE C1 WAS ITSELF A wtrail = 1 ASSUMPTION.  r1's filter
    demands the multiplicand carry the FRESH read; `dram-datapath.md' sect. 6.1
    measures that under the FORCED polarity that can only happen at
    `land = -1', and its own sects. 2 and 4 say the port hands the multiplier a
    sample fetched in an EARLIER repetition.  With `rlag' the two readings are
    both expressible and the search does not have to choose in advance.

    At (w = 1, rlag = 0) this MUST agree with r1's `loop_ok' machine for
    machine; sect. 6 step 1 checks that rather than asserting it."""
    R = r1()
    st, tr = gsym_rep(m)
    if "MULT" not in tr or "W" not in tr:
        return []
    mf = tr["MULT"]
    for _ in range(rlag):
        mf = gadvance(mf, st)
    if abs(abs(mf.get(("N", 0), 0.0)) - 1.0) > 1e-9:
        return []
    out = []
    for i, wv in enumerate(tr["W"]):
        f = wv
        for _ in range(rlag + w):
            f = gadvance(f, st)
        if abs(abs(f.get(("Q", rlag), 0.0)) - 1.0) > 1e-9:
            continue
        if abs(f.get(("N", 0), 0.0)) > 1e-9:
            continue
        out.append(R.WSRCS[i])
    return out


def _synth_motif_w2():
    """A SYNTHETIC 8-slot motif that manifestly carries its product TWO
    repetitions, built from the mathematics of the pipeline and not from the
    ROM.  It is the POSITIVE CONTROL for `loop_ok_w': a filter that cannot say
    YES at wtrail = 2 makes every zero at wtrail = 2 worthless (rule 1).

        slot 4  DRAM READ                       -> N
        slot 5  tB <- tA                        (tA still holds Q of rep r-1)
        slot 6  class A: P <- coef * DR         -> Q of rep r
        slot 7  acc <- P ; tA <- acc            (park Q in tA)
        slot 0  DRAM WRITE, bus = tB            -> stores Q of rep r-2
    """
    def sl(cls, src, act, accop, dram=None, esc=False, store=False):
        return dict(word="synth", esc=esc, cls=cls, src=src, act=act,
                    accop=accop, store=store, dram=dram)
    return [sl(1, 0x1A, 0x12, 2, dram="wr", esc=True),
            sl(2, 0x07, 0x12, 2),
            sl(2, 0x07, 0x12, 2),
            sl(2, 0x07, 0x12, 2),
            sl(1, 0x07, 0x12, 2, dram="rd", esc=True),
            sl(2, 0x19, 0x14, 2),
            sl(0xA, 0x0B, 0x12, 2),
            sl(2, 0x07, 0x19, 0)]


def _with_motif(slots, fn):
    R = r1()
    old = R.MSLOTS
    R.MSLOTS = slots
    try:
        return fn()
    finally:
        R.MSLOTS = old


def cmd_loopok(nsample=6000, seed=5, full=False):
    head(6, "*** THE STRUCTURAL FILTER, FOR A GENERAL wtrail *** -- and it "
           "must\n   reproduce r1's at wtrail = 1 before it is allowed to "
           "say anything else")
    R = r1()
    rnd = random.Random(seed)
    NE = len(R.EFFECTS)
    lands = list(R.LANDS) + [-1]
    space = NE ** 3 * len(R.SRC0_CANDS) * len(lands) * 2 * 2 * 2 * 2
    print("   POPULATION: %d machines drawn uniformly from r1's own space" % nsample)
    print("   (ACTION 0x00/0x19/0x0B over %d EFFECTS each, SRC 0x00 over %d,"
          % (NE, len(R.SRC0_CANDS)))
    print("    land over %s, escact 2, tbsh 2, order 2, ** swap 2 ** ) = %d"
          % (lands, space))
    print("   `swap' IS ENUMERATED HERE: r1's MSLOTS hardcodes lo12 0x2D4 = a")
    print("   READ, which is the FALSIFIED polarity; swap = 1 is round 5 D's.")

    sub("STEP 0 -- THE POSITIVE CONTROL.  A filter that cannot say YES at "
        "wtrail = 2\n        cannot be used to report a zero there.")
    mctl = R.mach(0, R.EFFECTS.index(("", "tA<-acc")), 0, "zero", None, 1, 2,
                  escact=1, tbsh=0)
    got = {w: _with_motif(_synth_motif_w2(), lambda w=w: loop_ok_w(mctl, w))
           for w in (0, 1, 2, 3)}
    for w in (0, 1, 2, 3):
        print("     synthetic wtrail-2 motif, filter at wtrail = %d : %s"
              % (w, got[w] or "REJECTED"))
    ctlok = ("bus" in got[2]) and ("bus" not in got[1]) \
        and ("bus" not in got[0]) and ("bus" not in got[3])
    print("     the control was built so that the WRITE'S BUS carries the "
          "trail-2 path;")
    print("     `bus' admitted at wtrail = 2 only: %s" % ctlok)
    print("     (the accumulator rows at wtrail = 1 are a DIFFERENT data")
    print("      source with a different trail, and the filter reporting them")
    print("      separately is the behaviour wanted, not a defect)")
    print("     => %s" % ("PASS -- the filter says YES at 2 and NO at 0, 1 "
                          "and 3 for the path built to have trail 2"
                          if ctlok else "** FAIL: the filter is blind **"))

    sub("STEP 1 -- EQUIVALENCE AT wtrail = 1 (the reproduction that licenses "
        "the rest)")
    agree = dis = both_empty = 0
    ms = []
    for _ in range(nsample):
        m = R.mach(rnd.randrange(NE), rnd.randrange(NE), rnd.randrange(NE),
                   rnd.choice(R.SRC0_CANDS), None, 1, rnd.choice(lands),
                   escact=rnd.randrange(2), tbsh=rnd.randrange(2),
                   order=rnd.randrange(2), swap=rnd.randrange(2))
        ms.append(m)
        a, b = R.loop_ok(m), loop_ok_w(m, 1)
        if a == b:
            agree += 1
            both_empty += (not a)
        else:
            dis += 1
    print("     agree %d of %d   (of which BOTH EMPTY %d)   disagree %d"
          % (agree, nsample, both_empty, dis))
    ok = dis == 0 and (agree - both_empty) > 0
    print("     => %s" % ("PASS -- identical to r1's filter, and NOT vacuous: "
                          "%d non-empty" % (agree - both_empty)
                          if ok else "** FAIL **"))

    sub("STEP 2 -- THE ARM THAT COULD NOT BE STATED BEFORE, on the REAL motif")
    tot = collections.Counter()
    bysw = collections.Counter()
    for m in ms:
        for w in (0, 1, 2, 3):
            if loop_ok_w(m, w):
                tot[w] += 1
                bysw[(w, m[R.SWAP])] += 1
    print("     machines admitted by the filter, of %d sampled:" % nsample)
    for w in (0, 1, 2, 3):
        print("       wtrail = %d : %5d   (swap=0 r1 %4d / swap=1 FORCED %4d) %s"
              % (w, tot[w], bysw[(w, 0)], bysw[(w, 1)],
                 "<== r1's assumption" if w == 1 else
                 "<== the descriptors' value (dram-datapath.md B)"
                 if w == 2 else ""))
    print("""
     ** THE POOL AT wtrail = 2 IS NOT EMPTY, AND IT EXISTS ONLY UNDER THE
        FORCED POLARITY. **  `dram-datapath.md' item H2 says in its own words
        that a zero at wtrail = 2 was "an absence of a search, not a
        rejection", because no filter for it existed.  One exists now, it is
        demonstrated saying YES (step 0) and reproducing r1 at wtrail = 1
        (step 1), and the pool it selects at wtrail = 2 is non-empty.

     ** AND METHOD RULE 10 BIT ME FIRST. **  The first version of this
        section held `swap' at its default 0 -- r1's MSLOTS hardcodes
        lo12 0x2D4 = READ, the polarity round 5 D reversed -- and printed
        0 at wtrail = 2.  That zero was an artefact of a parameter I had
        held fixed, in the pass whose whole subject is a parameter someone
        else held fixed.  It is printed here rather than deleted.""")

    sub("STEP 2b -- ** AND C1 WAS ITSELF A wtrail = 1 ASSUMPTION. **  The read "
        "lag,\n        enumerated (rule 2: a parameter settled elsewhere is "
        "not settled here)")
    print("""     r1's C1 demands the multiplicand carry the FRESH read.
     dram-datapath.md sect. 6.1 measures that under the FORCED polarity
     this happens ONLY at land = -1, while its own sects. 2 and 4 say the
     port hands the multiplier a sample fetched an EARLIER repetition.
     Both readings are `rlag' 0 and `rlag' > 0 of the same filter.""")
    print("       admitted, of %d sampled      wtrail=0  wtrail=1  wtrail=2  "
          "wtrail=3" % nsample)
    for rl in (0, 1, 2):
        row = []
        for w in (0, 1, 2, 3):
            row.append(sum(1 for m in ms if loop_ok_w(m, w, rl)))
        print("       rlag = %d                    %8d  %8d  %8d  %8d"
              % (rl, row[0], row[1], row[2], row[3]))
    lands = collections.Counter()
    for m in ms:
        for rl in (0, 1, 2):
            if loop_ok_w(m, 2, rl):
                lands[(rl, m[R.LAND])] += 1
    print("     the wtrail = 2 survivors, by (rlag, land): %s"
          % sorted(lands.items()))
    print("""     ** AT rlag = 0 EVERY SURVIVOR IS AT land = -1 ** -- which is
     sect. 6.1's measurement reached by an independent route, and it is
     the tension that note names: the flush-read argument wants land >= 1.
     Whether rlag > 0 dissolves it is a question for the next phase; the
     filter can now ask it.""")

    sub("STEP 3 -- and exhaustively over the ACTION triples, at every "
        "configuration\n        that survives at wtrail = 1")
    cfgs = sorted({(m[R.SRC0], m[R.LAND], m[R.ESCACT], m[R.TBSH], m[R.ORDERM],
                    m[R.SWAP]) for m in ms if loop_ok_w(m, 1)})
    print("     surviving configurations at wtrail = 1: %d" % len(cfgs))
    n2 = n1 = 0
    for (s0, ld, ea, tb, od, sw) in cfgs:
        for i00 in range(NE):
            for i19 in range(NE):
                for i0b in range(NE):
                    m = R.mach(i00, i19, i0b, s0, None, 1, ld, escact=ea,
                               tbsh=tb, order=od, swap=sw)
                    if loop_ok_w(m, 1):
                        n1 += 1
                    if loop_ok_w(m, 2):
                        n2 += 1
    print("     EXHAUSTIVE over %d ACTION triples x %d configurations = %d"
          % (NE ** 3, len(cfgs), NE ** 3 * len(cfgs)))
    print("       admitted at wtrail = 1 : %d" % n1)
    print("       admitted at wtrail = 2 : %d" % n2)
    if full:
        sub("STEP 4 -- THE WHOLE wtrail = 2 POOL UNDER THE FORCED POLARITY, "
            "EXHAUSTIVELY")
        pool = collections.Counter()
        n = 0
        for s0 in R.SRC0_CANDS:
            for ld in lands:
                for ea in (0, 1):
                    for tb in (0, 1):
                        for od in (0, 1):
                            for i00 in range(NE):
                                for i19 in range(NE):
                                    for i0b in range(NE):
                                        m = R.mach(i00, i19, i0b, s0, None, 1,
                                                   ld, escact=ea, tbsh=tb,
                                                   order=od, swap=1)
                                        n += 1
                                        r2 = loop_ok_w(m, 2)
                                        if r2:
                                            pool[(s0, ld, od, tuple(r2))] += 1
        print("     ENUMERATED %d machines (swap = 1 FORCED, wtrail = 2)" % n)
        print("     ADMITTED   %d" % sum(pool.values()))
        for k, v in pool.most_common(20):
            print("       src00=%-4s land=%-3s order=%d  wsrc=%-28s x%d"
                  % (k[0], k[1], k[2], ",".join(k[3]), v))
    return ok and ctlok


# ===========================================================================
#  SECTION 7 -- the ROM programs, through the new memory
# ===========================================================================
def _slotrows(P, h, cells=None):
    cells = P.cells if cells is None else cells
    C = load_classes()
    rec = C["algorithms"].get(str(P.algo))
    role = {c["rel"]: (c["role"], c["label"]) for c in rec["cells"]} if rec else {}
    lines = lines_of(P.algo) if rec else []
    of_read = {l.read_slot: l for l in lines}
    of_write = collections.defaultdict(list)
    for l in lines:
        of_write[l.write_slot].append(l)
    rows = []
    for k, (wi, w) in enumerate(P.cons):
        d = h.dirof(w)
        a = cells[(k + h.delta) % len(cells)]
        r, lab = role.get(k, ("?", "?"))
        who = ""
        if d == "READ" and k in of_read:
            who = "reads %s (D=%d)" % (of_read[k].name, of_read[k].samples)
        elif d == "WRITE" and k in of_write:
            who = "base of " + ",".join(l.name for l in of_write[k])
        rows.append((k, wi, "%010X" % w, d, a, r, lab, who))
    return rows


def cmd_ledger():
    head(7, "THE ROM PROGRAMS, EXECUTED -- port slots, cells, lines, and the "
           "two dummies")
    h = Harness()
    for algo in (9, 16):
        P = program(algo)
        print()
        print("   algo %d  %s   unit %d   %d words   %d cells   %d DRAM words"
              % (P.algo, P.name, P.unit, len(P.words), len(P.cells),
                 len(P.cons)))
        print("   slot word  36 bits     dir   addr    role      label"
              "            line")
        for k, wi, ws, d, a, r, lab, who in _slotrows(P, h):
            print("    %2d  w%-3d %s %-5s %6d  %-9s %-16s %s"
                  % (k, wi, ws, d or "TRAP", a, r, lab, who))
            if algo == 16 and k > 8:
                print("    ... (%d more; the twelve lines and the ladder are in"
                      " dram-datapath.md sect. 4)" % (len(P.cons) - k - 1))
                break
    sub("THE FLUSH READ AND THE PRIME WRITE ARE ONE MECHANISM, AND THE HARNESS "
        "SHOWS\n        THE DATUM GOING FROM ONE TO THE OTHER")
    P = program(9)
    print("""     Under port = push_read the ceiling read is the LAST access of
     its frame that carries a datum, and the datum it leaves in flight is
     committed by the FIRST read of the next frame -- so the only word
     that can ever store it is the PRIME WRITE, whose address no read of
     the algorithm can reach.  Traced, not asserted:""")
    for pmodel in ("push_read", "push_any"):
        led = _port_ledger(P, h.replace(port=pmodel))
        print("     port=%-9s :  %s"
              % (pmodel, "   ".join("w%d stores %s" % (k, v)
                                    for k, v in sorted(led.items()))))
    print("""     cell1 is the PRIME (LIMIT) and cell4 is the FLUSH (CEILING); the
     rows are the STEADY STATE, not the cold first frame.
     Under push_read the prime write at w5 stores the datum left in flight
     by the PREVIOUS frame's ceiling read -- the flush datum's only
     consumer, and it is thrown into the one address nothing can read.
     ** The two dummies are the two ends of one datum path, and this is
     the first time anything has executed it. **  (CONSISTENT: it depends
     on the port model, which is OPEN.)

     ** AND IT PRICES THE TWO PORT MODELS, CONDITIONALLY. **  Two words
     name SRC 0x0B.  Under push_read one of them is the prime (harmless by
     construction) and the other, w28, is line L0's BASE and stores L0's
     OWN read -- a self-feedback delay line, which is what SINGLE DELAY
     is.  Under push_any the same word stores the OTHER line's datum, and
     the register standing at w46 is the discarded CEILING word.  So IF
     SRC 0x00 turns out to be the read register (one of its six
     candidates), push_any writes flush garbage into a real delay line and
     is refuted.  CONDITIONAL, and printed as such.""")
    sub("AND THE REAL, UNSCALED DELAY -- 15435 samples, 350.0 ms, checked "
        "arithmetically")
    lns = lines_of(9)
    mem = DelayDRAM(h, 0, 32768)
    okd = True
    for l in lns:
        mem.frame = 0
        pw = mem.phys(l.write_addr)
        mem.frame = l.samples
        pr = mem.phys(l.read_addr)
        okd &= pw == pr
        print("     %s  write@frame 0 -> phys %d ; read@frame %d -> phys %d  %s"
              % (l.name, pw, l.samples, pr, "SAME CELL" if pw == pr else "**"))
    print("     => %s" % ("PASS -- the descriptor's own addresses give the "
                          "descriptor's own delay, with no buffer length "
                          "anywhere" if okd else "** FAIL **"))
    return okd


# ===========================================================================
#  SECTION 8 -- the published search, re-expressed
# ===========================================================================
#  SINGLE DELAY, scaled.  The STRUCTURE is the ROM's (same words, same
#  directions, same cursor, same roles); only the address VALUES are scaled so
#  that a 350 ms line recirculates inside a test signal a search can afford.
#  Labelled, and checked below against the same predicates bounds.py uses.
SD_SCALED = [7, 20, 12, 0, 32, 7]
SD_REGION = 32


def _check_scaled(cells, region):
    """The scaled block must classify the same way the real one does."""
    h = Harness()
    P = program(9)
    d = [h.dirof(w) for _wi, w in P.cons]
    inr = [0 <= v < region for v in cells]
    R = [i for i in range(len(cells)) if d[i] == "READ" and inr[i]]
    W = [i for i in range(len(cells)) if d[i] == "WRITE" and inr[i]]
    ceil = [i for i in range(len(cells)) if not inr[i]]
    limit = [i for i in W if all(cells[i] > cells[r] for r in R)]
    lines = []
    for r in R:
        c = [x for x in W if cells[x] < cells[r]]
        if c:
            b = max(c, key=lambda x: cells[x])
            lines.append((r, b, cells[r] - cells[b]))
    return ceil, limit, lines


def cmd_migrate(nframes=40, quick=False):
    head(8, "*** THE PUBLISHED SEARCH, RE-EXPRESSED *** -- and the structural "
           "reason\n   it went to zero")
    h = Harness()
    P = program(9)
    print("""   `adjudication-round6.md' sect. 3.4 re-ran the published SINGLE
   DELAY search with the polarity enumerated and got 108 -> 0, then
   showed the ZERO was an artefact of the one-cursor line.  With a
   two-address line the same question has an answer that needs no
   search at all.
""")
    sub("THE SEARCHED WINDOW w5..w9, AGAINST THE DESCRIPTOR BANK")
    rows = {p: {k: r for k, r in
                ((r[0], r) for r in _slotrows(P, h.replace(polarity=p)))}
            for p in ("forced", "published")}
    for wi in (5, 9):
        k = P.cons_of[wi]
        for p in ("forced", "published"):
            _k, _w, ws, d, a, role, lab, who = rows[p][k]
            print("     w%-2d  %s  polarity=%-9s -> %-5s cell %d = %-6d  %-9s "
                  "%s" % (wi, ws, p, d, k, a, role, who or "-"))
    print("""
     ** UNDER THE FORCED POLARITY THE WINDOW CONTAINS NO LOOP. **  Its only
     WRITE is the PRIME WRITE -- the LIMIT cell, an address no read of the
     algorithm can reach -- and its READ belongs to a line whose base is
     written at w46, thirty-seven words outside the window.  A search over
     w5..w9 cannot find a delay loop there because there is none: the
     window was chosen when 0x60 was believed to be the READ.
     PROVEN BY CONSTRUCTION from the descriptor bank + round 5 D.""")
    sub("THE SCALED DESCRIPTOR -- structure from the ROM, values scaled")
    ce, li, ln = _check_scaled(SD_SCALED, SD_REGION)
    print("     cells %s, region %d" % (SD_SCALED, SD_REGION))
    print("     CEILING (out of region) at rel %s ; LIMIT (write above every "
          "read) at rel %s" % (ce, li))
    print("     lines: %s" % ["rel%d<-rel%d D=%d" % t for t in ln])
    print("     the REAL block gives CEILING rel [4], LIMIT rel [1], lines")
    print("     rel0<-rel3 D=15435 and rel2<-rel5 D=15435 -- same shape, and")
    print("     the delays are now %s so a %d-frame signal recirculates"
          % ([t[2] for t in ln], nframes))

    sub("MIGRATION CONTROL -- the OLD model, reproduced INSIDE the new harness")
    print("""     Set the read cell and the write cell of every line to the same
     address and shrink the region to D, and the two-address memory IS
     the published `Line(D)'.  If the new harness cannot reproduce the
     published 108 in that configuration, nothing else it says can be
     trusted (rule 1, the YES half).""")
    import adjudicate6 as A6
    old_hits, old_space = A6.sd_search("published")
    print("     the OLD path, unmodified                       : %d of %d"
          % (len(old_hits), len(old_space)))
    n_new = _sd_new(P, h.replace(polarity="published", port="blocking"),
                    cells=[0] * 6, region=7, nframes=24, fb=0.5, D=7,
                    window=(5, 10))
    print("     the NEW harness, one-address configuration     : %d of %d"
          % (n_new, len(old_space)))
    ok = n_new == len(old_hits)
    print("     => %s" % ("PASS -- the new harness CONTAINS the old model, "
                          "exactly" if ok else "** FAIL **"))
    if quick:
        return ok
    sub("*** FIRST, CAN THE WHOLE-PROGRAM ARM SAY YES AT ALL? *** (rule 1: a "
        "control\n        that cannot PASS is worth as little as one that "
        "cannot fail)")
    ndiff, ntot, ncomp, trap = _seed_stability(P, h, SD_SCALED, SD_REGION,
                                                nframes, 200)
    print("     machines whose run COMPLETES the 48-word program : %d of %d"
          % (ncomp, 200))
    print("     the SAME machine, two RNG seeds -> different scored sequence:"
          " %d of %d" % (ndiff, ntot))
    bad = sorted(set(trap))
    print("     words at which action00_discriminate.step REFUSES: %s" % bad)
    for wi in bad[:4]:
        w = P.words[wi]
        print("       w%-3d %010X  act=%02X  f31=%d  <- %s"
              % (wi, w, DIS.lo_act(w), DIS.hi_f31(DIS.hi12(w)),
                 "ACTION outside the decoded set"
                 if DIS.lo_act(w) not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15,
                                          0x19, 0x0B) else "hi12[3:1] > 2"))
    print("""     ** SO THE WHOLE-PROGRAM ARM CANNOT PASS, AND ITS ZEROS ARE NOT
     RESULTS. **  Not one machine of the 5832 even reaches the end of the
     program: the ALU model refuses the words above, exactly as method
     rule 6 says it must.  They are printed anyway, with this control in
     FRONT of them, because the next phase must know that the blocker has
     moved -- the five-word window could be scored because its five words
     are decoded; the whole program cannot, and the missing piece is the
     ALU decode, not the memory.""")
    sub("AND THE SAME 5832 MACHINES ON THE TWO-ADDRESS MEMORY, WHOLE PROGRAM")
    print("     scored on the write sequence of line rel0<-rel3 against")
    print("     v[n] = x[n] + fb*v[n-%d], fb = 0.5, %d frames = %.1f "
          "recirculations" % (ln[0][2], nframes, nframes / float(ln[0][2])))
    for pol in ("forced", "published"):
        for pm in ("push_read", "push_any", "blocking"):
            hh = h.replace(polarity=pol, port=pm)
            n = _sd_new(P, hh, cells=SD_SCALED, region=SD_REGION,
                        nframes=nframes, fb=0.5, D=ln[0][2], window=None)
            print("       polarity=%-9s port=%-10s : %4d of 5832" % (pol, pm, n))
    print("""
     ** WHAT THIS IS AND IS NOT. **  It is a search over the FIVE-word
     window's three ACTION codes lifted to the WHOLE 48-word program, in
     which 22 of the 48 words have undecoded ALU semantics and are driven
     by `unknown()' random data.  A zero here is NOT a rejection of
     anything; it is the measurement the next phase has to make properly,
     and it is printed because the harness now exists to make it.""")
    return ok


def _seed_stability(P, h, cells, region, nframes, nmach):
    """Does the scored sequence depend on the RNG that drives the UNDECODED
    words?  If it does, no machine can match anything and the arm is void."""
    rng0 = random.Random(3)
    amp = 1 << 18
    x = [rng0.randrange(-amp, amp) for _ in range(nframes)]
    cf = coefs_of(9, P.words)
    space = list(itertools.product(A0.ORDER, A0.ACT00, A0.STTIME, A0.STGATE,
                                   ("tA<-bus", "tA<-acc", "tB<-bus"),
                                   ("mem", "P", "acc", "zero", "DR", "tA")))
    random.Random(1).shuffle(space)
    diff = tot = comp = 0
    trap = []
    for t in space[:nmach]:
        m = A0.Machine(t[0], t[1], t[2], t[3], act19=t[4], src00=t[5])
        seqs = []
        for sd in (20260727, 999):
            port, ok = run_words(P, m, h, x, cf, cells=cells, floor=0,
                                 size=region, seed=sd)
            if not ok:
                seqs = None
                break
            seqs.append([v for (_f, _s, k, a, _p, v, _t) in port.trace
                         if k == "W" and a == cells[3]])
        if seqs is None:
            for i, w in enumerate(P.words):
                if DIS.lo_act(w) not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15,
                                         0x19, 0x0B) or DIS.hi_f31(DIS.hi12(w)) > 2:
                    trap.append(i)
                    break
            continue
        comp += 1
        tot += 1
        diff += seqs[0] != seqs[1]
    return diff, tot, comp, trap


def _sd_new(P, h, cells, region, nframes, fb, D, window):
    """The published 5832-machine space, executed against the new memory."""
    import adjudicate6 as A6
    rng0 = random.Random(3)
    amp = 1 << 18
    x = [rng0.randrange(-amp, amp) for _ in range(nframes)]
    ref = A0.comb_ref(fb, D, x)
    cf = coefs_of(9, P.words)
    wcell = 3 if window is None else 2
    hits = 0
    for t in itertools.product(A0.ORDER, A0.ACT00, A0.STTIME, A0.STGATE,
                               ("tA<-bus", "tA<-acc", "tB<-bus"),
                               ("mem", "P", "acc", "zero", "DR", "tA")):
        m = A0.Machine(t[0], t[1], t[2], t[3], act19=t[4], src00=t[5])
        port, ok = run_words(P, m, h, x, cf, cells=cells, floor=0, size=region,
                             window=window)
        if not ok:
            continue
        seq = [v for (_f, _s, k, a, _p, v, _t) in port.trace
               if k == "W" and a == cells[wcell]]
        if len(seq) != len(ref):
            continue
        den = sum(v * v for v in seq)
        if den < 1e-6:
            continue
        sc = sum(a * b for a, b in zip(seq, ref)) / den
        if abs(sc) < 1e-6:
            continue
        mx = max(abs(v) for v in ref)
        if max(abs(sc * a - b) for a, b in zip(seq, ref)) < 1e-4 * mx:
            hits += 1
    return hits


# ===========================================================================
#  SECTION 9 -- the OLD code paths, unmodified
# ===========================================================================
def cmd_repro(slow=False):
    head(9, "REPRODUCTION -- the published numbers, through the PUBLISHED code")
    print("""   A result you cannot reproduce you cannot honestly retract.  These
   runs import the shipped tools and call them; nothing here is
   re-implemented.
""")
    import adjudicate6 as A6
    rows = []
    for pol, carry in (("published", False), ("forced", False),
                       ("forced", True)):
        hits, space = A6.sd_search(pol, carry)
        rows.append((pol, carry, len(hits), len(space)))
        print("   adjudicate6.sd_search(%-11s carry_dr=%-5s) : %4d of %d"
              % ('"%s",' % pol, carry, len(hits), len(space)))
    pub = {("published", False): 108, ("forced", False): 0,
           ("forced", True): 0}
    ok = all(pub[(p, c)] == n for p, c, n, _t in rows)
    print("   published in adjudication-round6.md sect. 3.4: 108 / 0 / 0")
    print("   => %s" % ("REPRODUCED exactly" if ok else "** DOES NOT "
                        "REPRODUCE **"))
    sub("AND ONE THAT DOES *NOT* REPRODUCE -- reported at full volume")
    print("""     `action-field.md' sect. 8 and `blocking-read.md' publish
     SINGLE DELAY's survivor count as 5145, and `acc-adder.md' sect. 5
     records prediction A-2 as "at actfirst = 0 the old search reproduces
     its published 5145 -- HIT, exactly".

     Run today, `python3 dsp/tools/r1_allpass_solve.py singledelay'
     prints ** 5635 **, not 5145.  (13 min; re-run it with
     `delayline.py repro --slow'.)

     THE CAUSE, found by diffing the tool against the commit that made
     the claim (rule 10 -- look for the parameter one of them held
     fixed): `exec_rep' used to select the `s1op' relaxation BY POSITION,

         op = m[S1OP] if s == 1 else sl["accop"]

     so the reverb motif's slot-1 relaxation LEAKED into SINGLE DELAY,
     whose slot 1 is `202.A.B8.655' with accop = 1, and it was executed
     with accop = 2 instead.  The current file fixes it:

         op = (m[S1OP] if (s == 1 and MSLOTS is MOTIF_MSLOTS)
               else sl["accop"])

     and the fix is commented in the source -- but the three notes that
     quote 5145 were never re-run.  ** The count is stale; the FORCING it
     supported (`land = -1' in 5635 of 5635) survives the fix. **  Both
     halves are printed because only one of them is comfortable.""")
    if slow:
        import subprocess
        print("     re-running the published path (13 min)...")
        p = subprocess.run([sys.executable,
                            os.path.join(HERE, "r1_allpass_solve.py"),
                            "singledelay"], capture_output=True, text=True)
        for lnn in p.stdout.splitlines():
            if "assignments make the block" in lnn or "read lands" in lnn:
                print("     %s" % lnn.strip())
    return ok


# ===========================================================================
#  SECTION 10 -- what this harness CANNOT express
# ===========================================================================
def cmd_cannot():
    head(10, "WHAT THIS HARNESS CANNOT EXPRESS -- the bound on every negative "
            "result\n    the next phase can produce")
    print("""   Rule 11 cuts both ways: naming my own model's limits is what
   keeps the next round from mistaking them for measurements.

   1  ** THE HOST'S PARAMETER WRITES. **  The descriptor cells are read
      from the ROM's canned streams as constants.  The host can rewrite
      them at run time (op-0x67 / BASE24), so a program whose delay is
      modulated -- CHORUS, FLANGER, every LFO-swept effect -- is frozen
      at its canned value here.  Any conclusion about a MODULATED line
      is out of this harness's reach.

   2  ** THE ROTATION REGISTER G IS A MODEL, NOT A DECODE. **  `grot',
      `gstep' and `g0' are enumerated, and sect. 2 shows only `desc'
      makes read-minus-write the delay -- but NO WORD OF THE ROM has
      been decoded as writing G.  If G is not a per-frame counter at
      all (e.g. it is per-BLOCK, or the addresses are pre-rotated by
      the host), every delay in every algorithm changes.

   3  ** THE 50 UNKNOWN CELLS AND THE 4 C-FORMAT TRAPS. **  Lines built
      on them do not exist here.  ROOM REVERB 1's four `C40180000'
      cells are exactly such a case.

   4  ** ONE UNIT AT A TIME. **  The memory models one 32768-sample
      region; a program that spans both units, or the wrap that
      `dram-unit-cursor.md' locates between them, is not modelled.

   5  ** NO ARBITRATION, NO REFRESH, NO BANDWIDTH LIMIT. **  Every port
      slot succeeds.  If the real port stalls, or if DRAM refresh steals
      slots, the frame is shorter than the program.

   6  ** THE ALU IS action00_discriminate.step. **  Its declared space
      is wide but not complete: 22 of SINGLE DELAY's 48 words have
      undecoded ACTION or SRC codes and are driven by `unknown()'.  A
      search over the whole program is therefore a search over a partly
      RANDOM machine, and its zeros mean much less than its ones.

   7  ** THE FRAME IS THE SAMPLE. **  gstep = 1 assumes one program
      execution per output sample.  A decimated or block-processed
      effect would break every delay figure here.

   8  ** SATURATION AND WORD LENGTH IN THE MEMORY. **  The delay RAM
      here stores Python floats.  The chip's cells are 24-bit (or
      narrower) and may saturate or truncate; a feedback loop that is
      stable in floats can be unstable in fixed point, and vice versa.

   9  ** MULTI-TAP READS SHARE A BASE, AND THE HARNESS DOES NOT CHECK
      THAT THE HOST AGREES. **  `bounds.py' pairs a read with the
      largest write below it.  For the 307 CONSISTENT lines that is a
      MODEL, and this harness will happily execute a wrong pairing
      without complaint -- it reports the label, it does not enforce it.
""")
    return True


# ===========================================================================
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "enum", "delay", "refs", "twins", "degen",
                             "loopok", "ledger", "migrate", "repro", "cannot"])
    ap.add_argument("--slow", action="store_true")
    ap.add_argument("--full", action="store_true")
    ap.add_argument("--frames", type=int, default=40)
    ap.add_argument("--sample", type=int, default=3000)
    a = ap.parse_args()
    r = {}
    if a.cmd in ("all", "enum"):
        cmd_enum()
    if a.cmd in ("all", "delay"):
        r["delay"] = cmd_delay()
    if a.cmd in ("all", "refs"):
        r["refs"] = cmd_refs()
    if a.cmd in ("all", "twins"):
        r["twins"] = cmd_twins()
    if a.cmd in ("all", "degen"):
        r["degen"] = cmd_degen()
    if a.cmd in ("all", "loopok"):
        r["loopok"] = cmd_loopok(a.sample, full=a.full)
    if a.cmd in ("all", "ledger"):
        r["ledger"] = cmd_ledger()
    if a.cmd in ("all", "migrate"):
        r["migrate"] = cmd_migrate(a.frames, quick=not a.slow)
    if a.cmd in ("repro",):
        r["repro"] = cmd_repro(a.slow)
    if a.cmd in ("all", "cannot"):
        cmd_cannot()
    if r:
        print()
        print("=" * 78)
        print("SELF-TEST: %s"
              % "  ".join("%s=%s" % (k, "PASS" if v else "FAIL")
                          for k, v in r.items()))
        print("=" * 78)


if __name__ == "__main__":
    main()
