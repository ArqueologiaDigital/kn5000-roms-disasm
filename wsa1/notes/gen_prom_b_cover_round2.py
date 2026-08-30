#!/usr/bin/env python3
"""prom_b's 913 REACHABLE-AND-UNCONVERTED bytes, coverage round 2 -- and the
measurement that says NOT ONE OF THEM IS A CODE PATH.

QUESTION IT ANSWERS
    "notes/reachability.py says 913 bytes of prom_b are STRONG-reachable code
     still sitting in an `.incbin`, in 18 directives.  What is the assembly text
     for exactly those bytes -- and is the tool right that they are code?"

★★ THE ANSWER IS NO, FOR ALL 913, AND THE REASON IS STRUCTURAL.  This round
    therefore converts NOTHING, and the refutation is the deliverable.  Every
    number below is re-measured by --selftest; nothing here is asserted.

────────────────────────────────────────────────────────────────────────────────
THE THREE MEASUREMENTS, IN THE ORDER THAT SETTLES IT
────────────────────────────────────────────────────────────────────────────────
1. CLOSURE (--closure).  Of the 13,218 entry points prom_b's five seed classes
   name -- 1,910 routine-directory slots, 7,285 branches its converted code
   decodes, 1,919 32-bit immediates, 2,104 framed `.long` entries, 0 vectors --
   ★ NOT ONE lands inside an `.incbin`.  Zero, in every class, weak ones
   included.  So no entry point this machine's indirection tables name is
   unconverted, and the 913 cannot have arrived through a seed.

2. THE TRACE (--trace).  It arrives through `proven`.  reachability.py seeds its
   walk with EVERY addressed line of the .s, and 20,464 of prom_b's 78,022
   addressed lines are printed DATA rows -- `.byte`, `.ascii`, `.long`.  `walk()`
   decodes ROM BYTES, not the `.s` text, so it happily decodes a caption block as
   instructions and runs off the end of it into the next `.incbin`.  111 of
   prom_b's 124 `.incbin` directives are immediately preceded by a printed data
   row.  Tracing each of the 913 bytes back to the walk that marked it:

     13 of the 31 runs spill DIRECTLY out of a printed data row -- 0xF04F57 out
        of `.byte 0xD6  ; F04F56`, 0xF14FAC out of `.ascii "   ----------   "`,
        0xF396E7 out of the caption bytes `31PART 32`, 0xF0E6C7 out of a `.long`;
     18 of the 31 are branch targets MANUFACTURED INSIDE such a decode, and every
        one of those roots is a FONT GLYPH BITMAP the tree has already framed and
        LABELLED -- 0xF261C0 `[0x41] 'A'`, 0xF26250 `'D'`, 0xF26400 `'M'`,
        0xF26580 `'U'`, 0xF265B0 `'V'`, 0xF265E0 `'W'`, 0xF26640 `'Y'`, 0xF269A0
        `'k'`, 0xF26BB0 `'v'`, 0xF25162 `']'`, 0xF234A0, 0xF261C0.  The walk
        decodes a glyph as instructions, the glyph bytes decode as a branch, and
        that branch becomes a `strong` entry point.
     ★ 31 of 31.  Not one run has any other origin.

   ⚠⚠ THE `branch` GRADE DOES NOT SURVIVE THIS.  reachability.py grades SEEDS,
   and it is right that a directory slot is stronger than a `.long`.  But the
   walk queues every branch it decodes ANYWHERE, including out of bytes it is
   painting over data, and those queue entries inherit the strong pass by
   construction.  Strong provenance is not preserved by the walk.

3. THE SHAPE (--shape).  What the 913 bytes actually are, byte for byte:
     * 11 runs, 392 bytes, are 60-98% zero -- 0x00 fill inside the graphics
       region.  0xF29D22 is 88 bytes, 98% zero; a linear decode spells it 87
       `nop` then `swi 7`, and `swi` ENDS THE FLOW, so a rule that looked only at
       the decode would have called it code and emitted 88 instructions.  ★ THAT
       IS ROUND 1's ARTEFACT IN A NEW COSTUME, and the byte gate passes it
       exactly as it passed 0xFA1404.
     * 0xF284BE-0xF28521 is 100 bytes of pure ASCII: "1-08 1-09 1-10 ... 2-16".
     * the rest are fixed-stride record arrays and display-list coordinates.
   Not one run ends where a routine ends; the ones that look like they do are
   fill.

────────────────────────────────────────────────────────────────────────────────
SO WHAT WOULD CONVERTING THEM BUY?  MEASURED, NOT ARGUED (--treadmill)
────────────────────────────────────────────────────────────────────────────────
Splice all 913 in as `.byte` rows -- honest data, no fake instructions -- rebuild
the seed set, and re-walk:

    before   .incbin 40,932   reachable-and-unconverted 913
    after    .incbin 40,019   reachable-and-unconverted  50   (3 fresh runs)

The 50 bytes are new spill, out of the data rows this round would itself have
printed.  ★ THE METRIC IS NOT A FIXPOINT UNDER ITS OWN CONVERSION PROCESS: every
printed data row is a fresh false entry point, so converting spill manufactures
the next round's spill.  Round 1 printed 8,819 bytes of caption and coordinate
data; this round's 913 is what those rows produced.

────────────────────────────────────────────────────────────────────────────────
★ THE DECISION, AND IT IS THE CONSERVATIVE ONE
────────────────────────────────────────────────────────────────────────────────
--splice REFUSES.  Converting 913 bytes of fill and captions would move
notes/reachability.py's prom_b number from 913 to 50 while adding ZERO coverage
of any code path, and would spend 913 bytes of territory to do it -- the trade
the coverage brief exists to refuse, and the one the handoff's "converting data
LOWERS understanding" rule names outright.

The emitter is complete and verified behind `--splice --anyway`, spelling every
run as `.byte` with an ASCII gutter and the trace at the site, so a coordinator
who wants the number closed can have it with one command and no new judgement.
It cannot spell a run as code: shape() requires a code-provenance ENTRY -- a
routine-directory slot, a hardware vector, or a branch in converted code's own
text -- and no run has one.

★ WHAT THIS MEANS FOR THE GOAL.  Measured on ENTRY POINTS instead of on a linear
decode, prom_b's reachable-code coverage is CLOSED: every address the vector
table, the 1,910-slot routine directory, the framed pointer tables and the
converted code's own branches name is already disassembled.  ⚠ That is a lower
bound, not a proof of completeness -- an entry point still buried inside an
`.incbin` (a jump table nobody has framed, a computed address) is invisible to
every walk here, and finding one is a different question from this round's.

★★ AND THE CONTRAST WITH prom_a IS WHAT MAKES THIS CREDIBLE.
The same closure check, run on prom_a AS THIS ROUND STARTED (`git show
47d40941b750:prom_a/wsa1_prom_a.s` -- another lane is splicing the live file, so only the
committed state is quotable):

    prom_a  directory 1 seed in an `.incbin` (0xFDE70F), branch 5 (0xF96432,
            0xF9646A, 0xF9647F, 0xF96C65, 0xF96C8A), immediate 49, vector 0,
            pointer_table 0
    prom_b  0 in every class, out of 13,218

So prom_a's residue HAS real entry points and its lane is right to convert them;
the live file already shows those six gone.  ⚠ Measured on the live prom_a AFTER
that splice the answer is 0, which is how a check like this goes vacuous -- the
first version of this file quoted exactly that number and it meant nothing.

★ AND THE REASON THE TWO IMAGES DIFFER IS MEASURABLE, not temperamental:

              addressed lines   printed DATA rows   directives preceded by one
    prom_a       127,713          10,894  (8.5%)          1 of 28
    prom_b        78,022          20,464 (26.2%)        111 of 124

prom_b is where twelve waves of framing put the fonts, the caption blocks and the
coordinate arrays, and round 1 added 8,819 bytes more of them.  Every one of
those rows is a false entry point to a walk that decodes ROM bytes, and 111 of
them sit directly against an `.incbin`.  That is why the spill is a prom_b
problem and prom_a barely has it.  prom_c has no `.incbin` at all.

RUN
  python3 notes/gen_prom_b_cover_round2.py             # the verdict, with numbers
  python3 notes/gen_prom_b_cover_round2.py --closure   # ★ measurement 1, all images,
                                                      #   prom_a also at HEAD
  python3 notes/gen_prom_b_cover_round2.py --trace     # ★ measurement 2, per run
  python3 notes/gen_prom_b_cover_round2.py --shape     # ★ measurement 3, per run
  python3 notes/gen_prom_b_cover_round2.py --treadmill # ★ the hypothetical splice
  python3 notes/gen_prom_b_cover_round2.py --derive    # the walks only
  python3 notes/gen_prom_b_cover_round2.py --layout    # the run table
  python3 notes/gen_prom_b_cover_round2.py --emit      # what --anyway would write
  python3 notes/gen_prom_b_cover_round2.py --selftest  # every number quoted above
  python3 notes/gen_prom_b_cover_round2.py --splice    # refuses, and says why
"""
# ⚠ PINNED, not HEAD. A verifier caught this: the contrast
# baseline read `git show HEAD:prom_a/...`, and HEAD is a MOVING
# reference -- the moment the coordinator commits prom_a's splice at
# the barrier, HEAD becomes the spliced file and the contrast silently
# compares the tree against itself. Pinned to 47d40941b750.
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROMNAME = "wsa1_prom_b.ic13"
B_BASE = 0xF00000

MARK = "; === COVER-R2 0x%06X-0x%06X ==="
MARK_END = "; === END COVER-R2 0x%06X-0x%06X ==="
MARK_RE = re.compile(r'^; === COVER-R2 0x([0-9A-F]{6})-0x([0-9A-F]{6}) ===$')
MARK_END_RE = re.compile(r'^; === END COVER-R2 0x([0-9A-F]{6})-0x([0-9A-F]{6}) ===$')
INCBIN_RE = re.compile(r'^\t\.incbin "original_ROMs/(\S+?)", (0x[0-9A-Fa-f]+), '
                       r'(0x[0-9A-Fa-f]+)\s*$')
# prom_b's converted-line shape: `\t<llvm-mc text>\t; ADDR  <mame text>`.
B_LINE = re.compile(r'^\t(\S.*?)\t;\s*([0-9A-F]{6})\s\s(.*)$')
CONV_RE = re.compile(r'^\t(\S.*?)\t;\s*([0-9A-F]{6})\s\s')
# ★ A PRINTED DATA ROW.  This is the class reachability.py cannot tell from an
# instruction, because it seeds on the ADDRESS and decodes the ROM.
DATA_ROW = re.compile(r'^\t\.(byte|ascii|asciz|long|short|word|space|fill)\b')
R_FLOW = re.compile(r'^\s*(ret|reti|retd|jp\s|jr\s+0x|halt|swi)', re.I)

RECORD_PATH = os.path.join(ROOT, "notes", "prom_b_cover_round2_layout.json")
DERIVE_CACHE = os.path.join(ROOT, "notes", "prom_b_cover_round2_derived.json")

_cache = {}
FAIL = []


def rom():
    if "rom" not in _cache:
        _cache["rom"] = open(IMGB, "rb").read()
    return _cache["rom"]


def at(a, n=1):
    return rom()[a - B_BASE: a - B_BASE + n]


def record():
    if "rec" not in _cache:
        with open(RECORD_PATH) as f:
            raw = json.load(f)
        _cache["rec"] = [(s["lo"], s["hi"], [tuple(r) for r in s["runs"]]) for s in raw]
    return _cache["rec"]


def incbin_line(lo, hi):
    return '\t.incbin "original_ROMs/%s", 0x%06X, 0x%06X' % (ROMNAME, lo - B_BASE, hi - lo)


# ------------------------------------------------------- the frozen source view
def frozen_lines():
    """prom_b/wsa1_prom_b.s as it was BEFORE this file ever spliced: every
    `; === COVER-R2 ... ===` block collapsed to the single `.incbin` directive it
    replaced.

    ⚠ ROUND 1's BLOCKS ARE LEFT STANDING, which is the whole difference from
    notes/gen_prom_b_cover_round1.py's freeze.  That file collapses its own
    COVER-R1 blocks, so re-running it re-derives ROUND 1's answer and is blind to
    the state round 1 created -- the state this round is about.

    ⚠ AND THE BLOCKS NEST.  103 of prom_b's 124 remaining `.incbin` directives
    sit INSIDE a round-1 block; they are the gaps round 1 left between its own
    conversions.  So if this file ever does splice, most of its blocks land
    inside a COVER-R1 one, and re-running `gen_prom_b_cover_round1.py --splice`
    would delete them silently -- its no-overwrite check ignores everything
    between its own markers."""
    src = open(SRCB).read().split("\n")
    out, i = [], 0
    while i < len(src):
        m = MARK_RE.match(src[i])
        if not m:
            out.append(src[i])
            i += 1
            continue
        lo, hi = int(m.group(1), 16), int(m.group(2), 16)
        end = MARK_END % (lo, hi)
        j = i
        while j < len(src) and src[j] != end:
            j += 1
        if j >= len(src):
            raise SystemExit("unterminated COVER-R2 block at 0x%06X" % lo)
        out.append(incbin_line(lo, hi))
        i = j + 1
    return out


def _key():
    import hashlib
    h = hashlib.sha256()
    h.update("\n".join(frozen_lines()).encode())
    h.update(rom())
    return h.hexdigest()


def _blob():
    if "blob" not in _cache:
        b = {}
        if os.path.exists(DERIVE_CACHE):
            b = json.load(open(DERIVE_CACHE))
            if b.get("key") != _key():
                b = {}
        _cache["blob"] = b
    return _cache["blob"]


def _blob_put(field, value):
    b = _blob()
    b["key"] = _key()
    b[field] = value
    json.dump(b, open(DERIVE_CACHE, "w"))


def _ranges(sset):
    out = []
    for x in sorted(sset):
        if out and out[-1][1] == x:
            out[-1][1] = x + 1
        else:
            out.append([x, x + 1])
    return out


def _expand(rs):
    out = set()
    for a, b in rs:
        out.update(range(a, b))
    return out


def _patch_reachability(lines=None):
    """Point notes/reachability.py at a given view of prom_b and NEUTRALISE its
    shared result cache.

    ⚠⚠ The cache's fingerprint is a SHA-1 of the three .s files plus
    reachability.py, and nothing else -- not the seed set, not source_lines.  A
    lane that patches either, as every experiment in this file does, would
    otherwise write its own answer into notes/.reachability-cache.json under a
    fingerprint that still validates, and the next reader would get it silently.
    Round 1 hit exactly that."""
    import reachability as R
    R._MEM.clear()
    R._cache_load = lambda: {}
    R._cache_store = lambda *_a, **_k: None
    if lines is not None:
        paths = dict((t, s) for t, s, _f, _b in R.IMAGES)
        R.source_lines = lambda tag, _l=lines: _l if tag == "prom_b" else \
            open(os.path.join(ROOT, paths[tag])).read().split("\n")
    return R


def _split(spans, seen, seen_s):
    """[(directive_lo, directive_hi, [(run_lo, run_hi, kind), ...])], where a run
    is a maximal reachable range OF UNIFORM PROVENANCE -- "code" where the STRONG
    walk reached it, "data" where only the full walk did.

    ⚠ The split is kept even though the weak class turns out to be EMPTY this
    time, because an empty class is a measurement that can change, not a property
    of the image."""
    out = []
    for lo, hi in spans:
        runs, x = [], lo
        while x < hi:
            if x in seen:
                k = "code" if x in seen_s else "data"
                y = x
                while y < hi and y in seen and (("code" if y in seen_s else "data") == k):
                    y += 1
                runs.append((x, y, k))
                x = y
            else:
                x += 1
        if runs:
            out.append((lo, hi, runs))
    return out


# --------------------------------------------------------- MEASUREMENT 1: seeds
def closure():
    """★ Does ANY entry point of ANY seed class land in an unconverted byte?

    This is the measurement that settles the round, and it needs no walk at all:
    it reads the seed sets straight out of reachability.py and asks where they
    point.  Run on all three images, because the answer changes what the prom_a
    lane should do and this file does not own prom_a."""
    # ⚠ NOT CACHED, deliberately.  It needs no walk -- it is set arithmetic over
    # the seed sets -- and prom_a is being spliced by another lane while this
    # runs, so a cached answer for it would go quietly stale.  closure_baseline()
    # is what makes the prom_a row quotable at all.
    import bisect
    R = _patch_reachability(frozen_lines())
    out = {}
    for tag, _s, _f, _b in R.IMAGES:
        cpu = R.CPU1 if tag in R.CPU1 else R.CPU2
        proven, spans = R.proven_and_incbin(tag)
        sd = R.seeds(tag, cpu)
        inspan = lambda x: any(lo <= x < hi for lo, hi in spans)      # noqa: E731
        cls = {}
        for k in ("vector", "directory", "branch", "immediate", "pointer_table"):
            s = sd.get(k, set())
            cls[k] = [len(s), sorted(x for x in s if inspan(x))]
        lines, ndata, ninstr, starts = R.source_lines(tag), 0, 0, {}
        for ln in lines:
            m = R.SRC_LINE.match(ln)
            if m:
                starts[int(m.group(2), 16)] = ln
                if DATA_ROW.match(ln):
                    ndata += 1
                else:
                    ninstr += 1
        addrs = sorted(starts)
        pre = 0
        for lo, _hi in spans:
            i = bisect.bisect_left(addrs, lo)
            if i and DATA_ROW.match(starts[addrs[i - 1]]):
                pre += 1
        out[tag] = {"classes": cls, "directives": len(spans), "data_rows": ndata,
                    "instr_rows": ninstr, "preceded_by_data": pre}
    return out


def closure_baseline():
    """★ THE SAME CHECK ON prom_a, AGAINST THE COMMITTED SOURCE.

    ⚠ WHY NOT THE LIVE FILE.  Another lane splices prom_a while this round runs,
    and a closure check on an image whose gaps have just been converted returns 0
    for a reason that has nothing to do with the question.  The first version of
    this file quoted the live figure -- "prom_a: 0 strong seeds in an `.incbin`
    either" -- and it was vacuous: the committed source says 1 routine-directory
    slot and 5 decoded branches DO land in one, so prom_a's residue is real code
    and its lane is right to convert it.  A check that cannot fail is not a pass.

    `git show` only; this function reads, it never touches the tree."""
    R = _patch_reachability()
    keep = R.source_lines
    src = subprocess.run(["git", "show", "47d40941b750:prom_a/wsa1_prom_a.s"],
                         capture_output=True, text=True, cwd=ROOT)
    if src.returncode != 0:
        R.source_lines = keep
        return None
    head = src.stdout.split("\n")
    paths = dict((t, x) for t, x, _f, _b in R.IMAGES)
    R.source_lines = lambda tag, _l=head: _l if tag == "prom_a" else \
        open(os.path.join(ROOT, paths[tag])).read().split("\n")
    proven, spans = R.proven_and_incbin("prom_a")
    sd = R.seeds("prom_a", R.CPU1)
    inspan = lambda x: any(lo <= x < hi for lo, hi in spans)          # noqa: E731
    cls = {}
    for k in ("vector", "directory", "branch", "immediate", "pointer_table"):
        s = sd.get(k, set())
        cls[k] = [len(s), sorted(x for x in s if inspan(x))]
    ndata = sum(1 for ln in head if R.SRC_LINE.match(ln) and DATA_ROW.match(ln))
    nall = sum(1 for ln in head if R.SRC_LINE.match(ln))
    R.source_lines = keep
    return {"classes": cls, "directives": len(spans), "data_rows": ndata,
            "instr_rows": nall - ndata}


# ---------------------------------------------------------- the derivation
def derive(force=False):
    """(directives-with-runs, totals) from notes/reachability.py over the FROZEN
    view, in two graded passes -- STRONG classes, then all of them -- each
    iterated to a fixpoint because transcribing a run makes its own branches
    visible and can reveal more.  Cached under a SHA-256 of (frozen source, ROM),
    so a cache hit is a proof the input has not moved."""
    if "derive" in _cache:
        return _cache["derive"]
    b = _blob()
    if not force and "derive" in b:
        out = (_split([tuple(x) for x in b["derive"]["spans"]],
                      _expand(b["derive"]["seen"]), _expand(b["derive"]["strong"])),
               b["derive"]["totals"])
        _cache["derive"] = out
        return out
    R = _patch_reachability(frozen_lines())
    base_seeds = R.seeds

    def fixpoint(keep_weak, tag, strong_seen=None):
        prev, rounds, first = None, 0, None
        extra_b, extra_i = set(), set()
        while True:
            rounds += 1

            def seeds(t, cpu, _kw=keep_weak, _b=extra_b, _i=extra_i):
                from collections import defaultdict
                sd = base_seeds(t, cpu)
                out = defaultdict(set)
                for k in R.STRONG:
                    out[k] = set(sd.get(k, set()))
                out["branch"] |= set(_b)
                if _kw:
                    for k in R.WEAK:
                        out[k] = set(sd.get(k, set()))
                    out["immediate"] |= set(_i)
                return out

            R.seeds = seeds
            R._MEM.clear()
            r = R.analyse("prom_b", R.CPU1)
            if first is None:
                first = r["reach_in_incbin"]
            if prev is not None and r["reach_in_incbin"] == prev:
                print("  %s pass: fixpoint after %d walk(s), %d bytes (first walk %d)"
                      % (tag, rounds, r["reach_in_incbin"], first), file=sys.stderr)
                r["first_walk"] = first
                return r
            prev = r["reach_in_incbin"]
            if rounds > 6:
                raise SystemExit("%s pass did not converge in 6 walks" % tag)
            # ⚠⚠ HARVEST ONLY FROM RUNS THE STRONG WALK REACHED.  Harvesting from
            # a weak run's garbage decode manufactures "reachable" text out of
            # noise -- which is, in miniature, the defect this whole file is about.
            nb, ni = set(), set()
            harvest = strong_seen if strong_seen is not None else r["seen"]
            for lo, hi in r["spans"]:
                x = lo
                while x < hi:
                    if x in r["seen"] and x in harvest:
                        y = x
                        while y < hi and y in r["seen"] and y in harvest:
                            y += 1
                        for ln in transcribe(x, y - x):
                            m = B_LINE.match(ln)
                            if not m:
                                continue
                            for mm in R.BRANCH.finditer(m.group(3)):
                                v = int(mm.group(1), 16)
                                if R.owner(v, R.CPU1):
                                    nb.add(v)
                            for mm in re.finditer(r'0x00([0-9A-Fa-f]{6})', m.group(3)):
                                v = int(mm.group(1), 16)
                                if R.owner(v, R.CPU1):
                                    ni.add(v)
                        x = y
                    else:
                        x += 1
            extra_b |= nb
            extra_i |= ni

    strong = fixpoint(False, "strong")
    allr = fixpoint(True, "all", strong["seen"])
    R.seeds = base_seeds
    R._MEM.clear()
    tool = R.analyse("prom_b", R.CPU1)          # the tool as it stands, for the record
    R._MEM.clear()
    spans = _split(allr["spans"], allr["seen"], strong["seen"])
    totals = {"incbin": allr["incbin"], "all": allr["reach_in_incbin"],
              "strong": strong["reach_in_incbin"],
              "strong_first_walk": strong["first_walk"],
              "tool": tool["reach_in_incbin"], "tool_strong": tool["reach_strong"],
              "seeds_tool": {k: v for k, v in tool["seeds"].items() if v}}
    _blob_put("derive", {"totals": totals, "spans": [list(x) for x in allr["spans"]],
                         "seen": _ranges(allr["seen"]), "strong": _ranges(strong["seen"])})
    _cache["derive"] = (spans, totals)
    return _cache["derive"]


def check_record():
    """Refuse to act if the derivation moved since the audit."""
    spans, totals = derive()
    rec = record()
    if len(spans) != len(rec):
        raise SystemExit("layout moved: derived %d directives, RECORD has %d"
                         % (len(spans), len(rec)))
    for (a, b, ra), (c, d, rb) in zip(spans, rec):
        if (a, b) != (c, d) or ra != rb:
            raise SystemExit("layout moved at 0x%06X: derived %r, RECORD %r"
                             % (a, (a, b, ra), (c, d, rb)))
    return spans, totals


# --------------------------------------------------------- MEASUREMENT 2: trace
def trace():
    """★ For every reachable-and-unconverted byte, WHICH WALK MARKED IT and what
    is that walk's root?

    reachability.py's walk is re-run here with parent tracking.  It is seeded
    exactly as the tool's STRONG pass is -- the strong seed classes plus `proven`,
    every addressed line of the .s -- and it queues branch targets out of decoded
    text exactly as the tool does, so the answer is the tool's, not a variant.

    The root is then looked up in the .s.  A root that is a printed `.byte`,
    `.ascii` or `.long` row is NOT an instruction: the walk is decoding data."""
    if "trace" in _blob():
        t = _blob()["trace"]
        return {(int(k.split(",")[0]), int(k.split(",")[1])): v for k, v in t.items()}
    R = _patch_reachability(frozen_lines())
    tag, cpu = "prom_b", R.CPU1
    proven, spans = R.proven_and_incbin(tag)
    sd = R.seeds(tag, cpu)
    strongseeds = set()
    for cls in R.STRONG:
        strongseeds |= sd.get(cls, set())
    seen, parent, queue, done = {}, {}, [], set()
    for a in sorted(strongseeds):
        parent[a] = ("seed", "a strong seed class names it")
        queue.append(a)
    for a in sorted(proven):
        parent.setdefault(a, ("proven", "an addressed line of prom_b/wsa1_prom_b.s"))
        queue.append(a)
    b, d = R.BASES[tag], R.ROMS[tag]
    while queue:
        a = queue.pop()
        if a in done:
            continue
        done.add(a)
        pc, guard = a, 0
        while guard < 4000:
            guard += 1
            if not (b <= pc < b + len(d)) or pc in seen:
                break
            rows = R._decode_window(tag, pc)
            if not rows:
                break
            stop = False
            for addr, ln, text in rows:
                if addr in seen or not (b <= addr < b + len(d)):
                    stop = True
                    break
                for i in range(ln):
                    seen.setdefault(addr + i, a)
                for m in R.BRANCH.finditer(text):
                    t = int(m.group(1), 16)
                    if R.owner(t, cpu):
                        parent.setdefault(t, ("branch-in-walk", "0x%06X, decoded during "
                                              "the walk rooted at 0x%06X" % (addr, a)))
                        queue.append(t)
                if R.FLOW_END.match(text):
                    stop = True
                    break
                pc = addr + ln
            if stop:
                break
    src = {}
    for ln in frozen_lines():
        m = R.SRC_LINE.match(ln)
        if m:
            src[int(m.group(2), 16)] = ln
    # follow each root back to the walk that first named it
    def root_of(a, depth=0):
        k, det = parent.get(a, ("?", "?"))
        if k == "branch-in-walk" and depth < 32:
            m = re.search(r'rooted at 0x([0-9A-F]{6})', det)
            if m:
                return root_of(int(m.group(1), 16), depth + 1)
        return a, k, det
    out = {}
    spans2, _t = derive()
    for _l, _h, runs in spans2:
        for a, bb, _k in runs:
            starts = {}
            for x in range(a, bb):
                s = seen.get(x)
                if s is not None:
                    starts[s] = starts.get(s, 0) + 1
            recs = []
            for s, n in sorted(starts.items()):
                k, det = parent.get(s, ("?", "?"))
                r0, rk, _rd = root_of(s)
                line = src.get(r0, "")
                recs.append({"start": s, "kind": k, "detail": det, "bytes": n,
                             "root": r0, "root_kind": rk, "root_line": line,
                             "root_is_data": bool(DATA_ROW.match(line))})
            out[(a, bb)] = recs
    _blob_put("trace", {"%d,%d" % k: v for k, v in out.items()})
    return out


# ------------------------------------------------------------- transcription
def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(start), hex(length),
                            "--quiet"], capture_output=True, text=True, cwd=ROOT)
        if p.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, p.stderr))
        _cache[key] = p.stdout.rstrip("\n").split("\n")
    return _cache[key]


# -------------------------------------------------------------- the evidence
def directory_slots(target):
    """Routine-directory slots (prom_b 0x40000..0x44018, each a `jp imm24`) whose
    target is `target`.  Re-read from the ROM, not typed in."""
    d, out = rom(), []
    for s in range(0x40000, 0x44018, 4):
        if d[s] == 0x1B and (d[s + 1] | d[s + 2] << 8 | d[s + 3] << 16) == target:
            out.append(B_BASE + s)
    return out


def _site_index():
    """{target: [instruction address, ...]} over every branch and every 32-bit
    immediate prom_b's converted code decodes, read from the MAME text of the
    FROZEN view."""
    if "sites" not in _cache:
        import reachability as R
        idx, imm = {}, {}
        for ln in frozen_lines():
            m = B_LINE.match(ln)
            if not m:
                continue
            a, text = int(m.group(2), 16), m.group(3)
            for mm in R.BRANCH.finditer(text):
                idx.setdefault(int(mm.group(1), 16), []).append(a)
            for mm in re.finditer(r'0x00([0-9A-Fa-f]{6})', text):
                imm.setdefault(int(mm.group(1), 16), []).append(a)
        _cache["sites"] = (idx, imm)
    return _cache["sites"]


def word_sites(value):
    d, out, want = rom(), [], value.to_bytes(4, "little")
    i = d.find(want)
    while i != -1 and len(out) < 64:
        out.append(B_BASE + i)
        i = d.find(want, i + 1)
    return out


def measure(lo, hi, lines):
    blk = at(lo, hi - lo)
    unenc = 0
    for l in lines:
        if "[llvm-mc cannot encode this]" in l:
            m = re.match(r'\t\.byte ([^\t]*)\t', l)
            unenc += len(m.group(1).split(",")) if m else 0
    last = lines[-1].split(";", 1)[1].strip()[7:].strip() if lines else ""
    last = last.replace("[llvm-mc cannot encode this]", "").strip()
    return {"n": hi - lo, "instr": len(lines), "unenc": unenc,
            "unenc_frac": unenc / (hi - lo),
            "ascii": sum(1 for x in blk if 32 <= x < 127) / len(blk),
            "zero": sum(1 for x in blk if x == 0) / len(blk),
            "last": last, "ends_flow": bool(R_FLOW.match(last))}


# ------------------------------------------------------- MEASUREMENT 3: shape
MAX_UNENC = 0.25
MAX_ASCII = 0.60


def shape(lo, hi):
    """★ THE CODE/DATA DECISION, and PROVENANCE COMES FIRST.

    A run is spelled as instructions only if something NAMES its first byte as an
    entry point -- a routine-directory slot, a hardware vector, or a branch that
    appears in converted code's own decoded text.  Reaching it by decoding
    forward out of a printed `.byte` row is not that, however plausible the
    decode looks: 0xF29D22's 88 bytes are 98% zero and spell 87 `nop` then
    `swi 7`, which ends the flow and would pass any shape-only rule.

    The decode measurements are still taken and still printed, because a run that
    HAS an entry and still decodes like text would be the other error."""
    lines = transcribe(lo, hi - lo)
    m = measure(lo, hi, lines)
    m["slots"] = directory_slots(lo)
    m["branches"] = sorted(set(_site_index()[0].get(lo, [])))
    m["immediates"] = sorted(set(_site_index()[1].get(lo, [])))
    m["words"] = word_sites(lo)
    why = []
    if not m["slots"] and not m["branches"]:
        why.append("nothing names 0x%06X as an entry point -- no routine-directory "
                   "slot, no hardware vector, and no branch in converted code" % lo)
    if not m["ends_flow"]:
        why.append("the decode does not end on a flow-ending instruction (`%s`)" % m["last"])
    if m["unenc_frac"] >= MAX_UNENC:
        why.append("%.0f%% of the bytes are in spellings llvm-mc will not assemble"
                   % (100 * m["unenc_frac"]))
    if m["ascii"] >= MAX_ASCII:
        why.append("%.0f%% of the bytes are printable ASCII" % (100 * m["ascii"]))
    if m["zero"] >= 0.60:
        why.append("%.0f%% of the bytes are 0x00 -- this is fill" % (100 * m["zero"]))
    m["code"] = not why
    m["why_not"] = why
    return m


# ----------------------------------------------------- MEASUREMENT 4: treadmill
def treadmill():
    """★ If this round DID splice its 913 bytes in as `.byte` rows, what would the
    next round find?

    Builds the hypothetical source without writing it, rebuilds the seed set from
    it, and re-walks.  The answer is the argument against converting: the new
    data rows are new false entry points, so the spill moves rather than ends."""
    if "treadmill" in _blob():
        return _blob()["treadmill"]
    spans, _t = derive()
    byline = {}
    for lo, hi, runs in spans:
        out, pos = [], lo
        for a, b, _k in runs:
            if a > pos:
                out.append(incbin_line(pos, a))
            out.append("Data_%06X:" % a)
            out += byte_rows(a, b - a)
            pos = b
        if pos < hi:
            out.append(incbin_line(pos, hi))
        byline[incbin_line(lo, hi)] = out
    hyp = []
    for l in frozen_lines():
        hyp += byline.get(l, [l])
    R = _patch_reachability(hyp)
    r = R.analyse("prom_b", R.CPU1)
    R._MEM.clear()
    rows = []
    for lo, hi in sorted(r["spans"]):
        n = r["per_span_strong"].get((lo, hi), 0)
        if n:
            rows.append([lo, hi, hi - lo, n])
    out = {"incbin": r["incbin"], "strong": r["reach_strong"],
           "any": r["reach_in_incbin"], "rows": rows}
    _blob_put("treadmill", out)
    return out


# ------------------------------------------------------------------ emission
def wrap(prefix, text, width=78):
    import textwrap
    body = textwrap.wrap(text, width - len(prefix)) or [""]
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def block_comment(text, indent=";   "):
    import textwrap
    return [indent.rstrip() + " " + b if i else "; " + b
            for i, b in enumerate(textwrap.wrap(text, 76))]


def byte_rows(a, n, per=16):
    out = []
    for off in range(0, n, per):
        k = min(per, n - off)
        blk = at(a + off, k)
        txt = "".join(chr(x) if 32 <= x < 127 else "." for x in blk)
        out.append("\t.byte\t%s\t; %06X  |%s|"
                   % (", ".join("0x%02X" % x for x in blk), a + off, txt))
    return out


def data_block(lo, hi, m, tr):
    out = ["; " + "-" * 74,
           "; Data_%06X -- %d bytes, PRINTED AS DATA.  ⚠ notes/reachability.py "
           "calls this" % (lo, m["n"]),
           "; run reachable code.  It is not, and the trace below is why."]
    r = tr[0] if tr else None
    if r:
        out += wrap("; Reached by: ", "the walk rooted at 0x%06X, which is %s -- "
                    "reachability.py seeds on the ADDRESS of every line of the .s and "
                    "decodes ROM BYTES, so it reads that row as an instruction and "
                    "runs off the end of it into this directive.%s"
                    % (r["root"],
                       "a printed DATA row, `%s`" % r["root_line"].strip()[:60]
                       if r["root_is_data"] else "an instruction at 0x%06X" % r["root"],
                       "  The immediate step was %s." % r["detail"]
                       if r["kind"] != "proven" else ""))
    out += wrap("; Not an entry: ", "; and ".join(m["why_not"]) + ".")
    out += wrap("; Measured: ", "%.0f%% printable ASCII, %.0f%% 0x00; a linear decode "
                "runs %d instruction%s and ends `%s`, with %.0f%% of the bytes in "
                "spellings llvm-mc will not encode."
                % (100 * m["ascii"], 100 * m["zero"], m["instr"],
                   "" if m["instr"] == 1 else "s", m["last"], 100 * m["unenc_frac"]))
    out += ["; ⚠ The extent is the walk's, not the object's; the rest of this",
            ";   directive is unreachable and stays `.incbin`.  Why this is not",
            ";   spelled as code: notes/gen_prom_b_cover_round2.py.",
            "; " + "-" * 74, "Data_%06X:" % lo]
    return out + byte_rows(lo, hi - lo)


def span_block(lo, hi, runs):
    tr = trace()
    shp = dict((a, shape(a, b)) for a, b, _k in runs)
    if any(shp[a]["code"] for a, _b, _k in runs):
        raise SystemExit("a run at 0x%06X now claims code provenance; re-audit before "
                         "emitting -- this file only knows how to print data" % lo)
    n = sum(b - a for a, b, _k in runs)
    out = [MARK % (lo, hi)]
    out += block_comment(
        "0x%06X-0x%06X, coverage round 2: %d of this directive's %d bytes are what "
        "notes/reachability.py counts as reachable-and-unconverted, in %d run%s.  "
        "NONE of them is named by a routine-directory slot, a hardware vector or a "
        "branch in converted code; every one is reached by decoding a printed DATA "
        "row as an instruction and running off its end.  They are printed as bytes, "
        "never as instructions.  Regenerate: python3 "
        "notes/gen_prom_b_cover_round2.py --splice --anyway"
        % (lo, hi - 1, n, hi - lo, len(runs), "" if len(runs) == 1 else "s"))
    pos = lo
    for a, b, _kind in runs:
        if a > pos:
            out += ["", incbin_line(pos, a)]
        out += [""] + data_block(a, b, shp[a], tr.get((a, b), []))
        pos = b
    if pos < hi:
        out += ["", incbin_line(pos, hi)]
    out += ["", MARK_END % (lo, hi)]
    return out


def emit():
    spans, _t = check_record()
    out = []
    for lo, hi, runs in spans:
        out += span_block(lo, hi, runs) + [""]
    return out


def verify(spans):
    """The emitted segments tile each `.incbin` directive exactly, and every byte
    printed matches the ROM.  (No run is spelled as code, so there is nothing to
    re-assemble; shape() refuses to let one through.)"""
    for lo, hi, runs in spans:
        pos = lo
        for a, b, _k in runs:
            if a < pos or b > hi or b <= a:
                return False, "run 0x%06X-0x%06X does not fit its directive" % (a, b)
            if shape(a, b)["code"]:
                return False, "run 0x%06X claims code provenance" % a
            got = bytearray()
            for row in byte_rows(a, b - a):
                got += bytes(int(x, 16) for x in
                             re.match(r'\t\.byte\t([^\t]*)\t', row).group(1).split(", "))
            if bytes(got) != at(a, b - a):
                return False, "0x%06X does not print back to the ROM" % a
            pos = b
    return True, ("%d directives, %d runs, %d bytes printed byte-exact"
                  % (len(spans), sum(len(r) for _l, _h, r in spans),
                     sum(b - a for _l, _h, r in spans for a, b, _k in r)))


# ------------------------------------------------------------------- splice
def outside_lines(lines):
    """Every line NOT inside one of this round's own blocks, in order.  ⚠ This is
    the no-overwrite evidence and it is deliberately EVERY line -- comment,
    header, label, instruction, blank -- so a destroyed banner is caught as
    loudly as a destroyed instruction."""
    out, inside = [], False
    for l in lines:
        if MARK_RE.match(l):
            inside = True
        elif MARK_END_RE.match(l):
            inside = False
        elif not inside:
            out.append(l)
    return out


def converted_only(lines):
    return [l for l in outside_lines(lines) if CONV_RE.match(l)]


REFUSAL = """\
REFUSING TO SPLICE, and this is the round's result, not a failure.

  All 913 bytes are reached by decoding a printed DATA row as an instruction.
  Not one of prom_b's 13,218 seeds -- 1,910 routine-directory slots, 7,285
  decoded branches, 1,919 immediates, 2,104 framed `.long` entries -- lands in
  an `.incbin`.  11 of the 31 runs, 392 bytes, are 60-98% 0x00 fill; one is 100
  bytes of ASCII captions ("1-08 1-09 ... 2-16"); the rest are fixed-stride
  record arrays and display-list coordinates.  18 of the 31 are named only by a
  branch the walk decoded out of a FONT GLYPH BITMAP.

  Converting them would move notes/reachability.py's prom_b figure from 913 to
  50 (measured, --treadmill) while adding ZERO coverage of any code path, and
  the 50 would be fresh spill out of the data rows this round had just printed.

  Read the header of this file, then:
      python3 notes/gen_prom_b_cover_round2.py --closure --trace --shape
  If a coordinator still wants the figure closed, the emitter is complete and
  verified:
      python3 notes/gen_prom_b_cover_round2.py --splice --anyway
  It prints every run as `.byte` with the trace at the site.  It cannot spell
  one as code."""


def splice():
    if "--anyway" not in sys.argv:
        print(REFUSAL)
        return 1
    spans, _t = check_record()
    ok, msg = verify(spans)
    if not ok:
        raise SystemExit("refusing to splice: " + msg)
    byspan = dict((lo, (hi, span_block(lo, hi, runs))) for lo, hi, runs in spans)
    drop = set(incbin_line(lo, hi) for lo, hi, _r in spans)
    src = open(SRCB).read().split("\n")
    before, before_conv = outside_lines(src), converted_only(src)
    out, i, done = [], 0, set()
    while i < len(src):
        m = MARK_RE.match(src[i])
        if m:                                   # re-splice: replace the old block
            lo, hi = int(m.group(1), 16), int(m.group(2), 16)
            if lo not in byspan or byspan[lo][0] != hi:
                raise SystemExit("a COVER-R2 block at 0x%06X-0x%06X is not in the "
                                 "current layout; the derivation moved" % (lo, hi))
            end = MARK_END % (lo, hi)
            j = i
            while j < len(src) and src[j] != end:
                j += 1
            out += byspan[lo][1]
            done.add(lo)
            i = j + 1
            continue
        m = INCBIN_RE.match(src[i])
        if m and m.group(1) == ROMNAME:
            lo = B_BASE + int(m.group(2), 16)
            if lo in byspan and byspan[lo][0] - lo == int(m.group(3), 16):
                out += byspan[lo][1]
                done.add(lo)
                i += 1
                continue
        out.append(src[i])
        i += 1
    missing = sorted(set(byspan) - done)
    if missing:
        raise SystemExit("could not place %d directive(s): %s"
                         % (len(missing), " ".join("0x%06X" % x for x in missing)))
    after, after_conv = outside_lines(out), converted_only(out)
    expect = [l for l in before if l not in drop]
    if after != expect:
        n = next((k for k in range(min(len(after), len(expect)))
                  if after[k] != expect[k]), min(len(after), len(expect)))
        raise SystemExit("REFUSING TO SPLICE: the text outside this round's blocks "
                         "changed (%d expected, %d after); first difference at index "
                         "%d:\n  expected %r\n  got      %r"
                         % (len(expect), len(after), n,
                            expect[n] if n < len(expect) else None,
                            after[n] if n < len(after) else None))
    if after_conv != before_conv:
        raise SystemExit("REFUSING TO SPLICE: an already-converted line changed")
    open(SRCB, "w").write("\n".join(out))
    print("spliced %d directives; %s" % (len(done), msg))
    print("lines outside this round's blocks, before / after: %d / %d -- IDENTICAL "
          "except the %d `.incbin` directives replaced, which is the no-overwrite proof."
          % (len(before), len(after), len(drop)))
    print("already-converted lines outside this round's blocks: %d / %d, identical."
          % (len(before_conv), len(after_conv)))
    return 0


# ---------------------------------------------------------------------- main
def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    if verbose:
        print(("  ok    " if ok else "  FAIL  ") + desc)
    return ok


def print_closure():
    cl = closure()
    base = closure_baseline()
    if base:
        print("prom_a AT HEAD (the committed source; another lane is splicing the live")
        print("  one, so only this state is quotable): %d directives, %d addressed lines, "
              "%d printed DATA rows" % (base["directives"],
                                        base["data_rows"] + base["instr_rows"],
                                        base["data_rows"]))
        for k in ("vector", "directory", "branch", "immediate", "pointer_table"):
            n, bad = base["classes"][k]
            print("    %-14s %5d seeds, %4d land in an `.incbin` %s"
                  % (k, n, len(bad), " ".join("0x%06X" % x for x in bad[:8])))
        print("  ★ prom_a's residue HAS strong entry points; prom_b's has none.\n")
    for tag in ("prom_a", "prom_b", "prom_c"):
        e = cl[tag]
        print("%s : %d `.incbin` directive(s); %d addressed lines, of which %d are "
              "printed DATA rows" % (tag, e["directives"],
                                     e["data_rows"] + e["instr_rows"], e["data_rows"]))
        for k in ("vector", "directory", "branch", "immediate", "pointer_table"):
            n, bad = e["classes"][k]
            print("    %-14s %5d seeds, %4d land in an `.incbin` %s"
                  % (k, n, len(bad), " ".join("0x%06X" % x for x in bad[:8])))
        print("    %d of %d directives are immediately preceded by a printed DATA row"
              % (e["preceded_by_data"], e["directives"]))
    print("\n⚠ the prom_a rows above read the LIVE file, which another lane is")
    print("  splicing; quote the HEAD block at the top, not these.")


def print_trace():
    tr = trace()
    spans, _t = derive()
    ndata = nbranch = 0
    for _l, _h, runs in spans:
        for a, b, _k in runs:
            recs = tr.get((a, b), [])
            r = recs[0] if recs else None
            print("0x%06X-0x%06X %4d B" % (a, b - 1, b - a))
            for x in recs:
                print("    walk root 0x%06X [%s] marks %d B  %s"
                      % (x["root"], x["root_kind"], x["bytes"],
                         "DATA ROW: " + x["root_line"].strip()[:80] if x["root_is_data"]
                         else "instruction: " + x["root_line"].strip()[:80]))
            if r:
                (ndata, nbranch) = (ndata + 1, nbranch) if r["kind"] == "proven" \
                    else (ndata, nbranch + 1)
    print("\n%d runs spill straight out of a printed data row; %d are branch targets "
          "manufactured inside such a decode." % (ndata, nbranch))
    bad = [(a, b) for _l, _h, rr in spans for a, b, _k in rr
           if any(not x["root_is_data"] for x in tr.get((a, b), []))]
    print("runs whose walk root is NOT a printed data row: %d" % len(bad))


def print_shape():
    spans, _t = derive()
    print("%-19s %5s %5s %6s %6s %6s %5s %-5s %s"
          % ("run", "bytes", "instr", "unenc", "ascii", "zero", "entry", "spell", "ends"))
    for _l, _h, runs in spans:
        for a, b, _k in runs:
            m = shape(a, b)
            print("0x%06X-0x%06X %5d %5d %5.0f%% %5.0f%% %5.0f%% %5d %-5s %s"
                  % (a, b - 1, m["n"], m["instr"], 100 * m["unenc_frac"],
                     100 * m["ascii"], 100 * m["zero"],
                     len(m["slots"]) + len(m["branches"]),
                     "code" if m["code"] else "DATA", m["last"]))


def selftest():
    del FAIL[:]
    spans, T = derive("--force-derive" in sys.argv)
    rec = record()
    nruns = sum(len(r) for _l, _h, r in spans)
    c("the derivation still matches the RECORD, directive for directive and run "
      "for run", [(a, b, r) for a, b, r in spans], [(a, b, r) for a, b, r in rec])
    c("18 directives, 31 runs, 913 bytes", (len(spans), nruns, T["all"]), (18, 31, 913))
    c("★ the weak class is EMPTY: round 1 converted every byte a pointer names",
      T["all"] - T["strong"], 0)
    c("notes/reachability.py, unmodified, agrees on the STRONG figure",
      T["tool_strong"], T["strong"])
    # MEASUREMENT 1
    cl = closure()
    b = cl["prom_b"]
    c("★ CLOSURE: not one prom_b seed of ANY class lands in an `.incbin`",
      sorted((k, len(v[1])) for k, v in b["classes"].items()),
      [("branch", 0), ("directory", 0), ("immediate", 0), ("pointer_table", 0),
       ("vector", 0)])
    c("...and that is 13,218 seeds", sum(v[0] for v in b["classes"].values()), 13218)
    c("prom_b's `proven` set is 78,022 lines, 20,464 of them printed DATA rows",
      (b["data_rows"] + b["instr_rows"], b["data_rows"]), (78022, 20464))
    c("111 of prom_b's 124 directives are immediately preceded by a data row",
      (b["preceded_by_data"], b["directives"]), (111, 124))
    # ⚠ prom_a is measured AT HEAD, not live: another lane is splicing it, and the
    # live answer is 0 for a reason that has nothing to do with the question.
    base = closure_baseline()
    c("★ THE CONTRAST: at HEAD, prom_a DOES have strong seeds in an `.incbin` -- "
      "1 directory slot and 5 decoded branches -- so the method finds real entry "
      "points when they exist",
      [len(base["classes"][k][1]) for k in ("vector", "directory", "branch",
                                            "pointer_table", "immediate")],
      [0, 1, 5, 0, 49])
    c("...and they are 0xFDE70F and 0xF96432/0xF9646A/0xF9647F/0xF96C65/0xF96C8A",
      (["0x%06X" % x for x in base["classes"]["directory"][1]],
       ["0x%06X" % x for x in base["classes"]["branch"][1]]),
      (["0xFDE70F"], ["0xF96432", "0xF9646A", "0xF9647F", "0xF96C65", "0xF96C8A"]))
    c("prom_a keeps 8.5% of its addressed lines as printed DATA rows where prom_b "
      "keeps 26.2%, which is why the spill is a prom_b problem",
      (base["data_rows"], base["data_rows"] + base["instr_rows"]), (10894, 127713))
    c("prom_c has no `.incbin` at all", cl["prom_c"]["directives"], 0)
    # MEASUREMENT 2
    tr = trace()
    c("★ THE TRACE: every one of the 31 runs is rooted in a printed DATA row",
      sorted("0x%06X" % k[0] for k, v in tr.items()
             if any(not x["root_is_data"] for x in v)), [])
    c("...and 13 of them spill DIRECTLY out of one, the other 18 through a branch "
      "manufactured inside such a decode",
      sorted(len([1 for k, v in tr.items() if v and v[0]["kind"] == x])
             for x in ("branch-in-walk", "proven")), [13, 18])
    r = tr[(0xF04F57, 0xF04F72)][0]
    c("0xF04F57's walk root is the `.byte 0xD6` row at 0xF04F56",
      (r["root"], r["root_is_data"], r["root_line"].strip()),
      (0xF04F56, True, ".byte\t0xD6\t; F04F56  |.|"))
    r = tr[(0xF29D22, 0xF29D7A)][0]
    c("0xF29D22's root is a FONT GLYPH row -- the walk decodes bitmaps as branches",
      (r["kind"], r["root_is_data"], "0x%06X" % r["root"],
       "'D'" in r["root_line"]),
      ("branch-in-walk", True, "0xF26250", True))
    # MEASUREMENT 3
    c("★ NOT ONE run passes the shape rule; every one states its reasons",
      [(a, b) for _l, _h, r in spans for a, b, _k in r if shape(a, b)["code"]], [])
    fill = [(a, b) for _l, _h, r in spans for a, b, _k in r if shape(a, b)["zero"] >= 0.60]
    c("11 runs, 392 bytes, are >=60% 0x00 fill",
      (len(fill), sum(b - a for a, b in fill)), (11, 392))
    c("0xF29D22 is 88 bytes, 98% zero, and a linear decode ends `swi 7` -- a "
      "flow-ender, so a shape-only rule would have spelled it as 88 instructions",
      (shape(0xF29D22, 0xF29D7A)["instr"], shape(0xF29D22, 0xF29D7A)["ends_flow"]),
      (88, True))
    c("0xF284BE-0xF28521 is 100 bytes of pure ASCII",
      (shape(0xF284BE, 0xF28522)["ascii"], at(0xF284BE, 8)), (1.0, b"1-081-09"))
    # MEASUREMENT 4
    tm = treadmill()
    c("★ THE TREADMILL: a hypothetical splice leaves 50 fresh reachable bytes",
      (tm["strong"], len(tm["rows"])), (50, 3))
    c("...and drops `.incbin` by exactly the 913 bytes converted",
      T["incbin"] - tm["incbin"], 913)
    # the freeze
    pre = frozen_lines()
    c("freeze(): every directive this round would replace is one `.incbin` line in "
      "the frozen view",
      [lo for lo, hi, _r in rec if incbin_line(lo, hi) not in pre], [])
    c("freeze(): the frozen view carries none of this file's own markers",
      [l for l in pre if MARK_RE.match(l) or MARK_END_RE.match(l)], [])
    c("freeze(): ...but it DOES keep round 1's conversions, which is the whole "
      "difference from round 1's freeze",
      sum(1 for l in pre if l.startswith("; === COVER-R1 ")) > 90, True)
    # emission, if a coordinator ever asks for it
    have = set()
    for ln in pre:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
        if m:
            have.add(m.group(1))
    want = set("Data_%06X" % a for _l, _h, r in spans for a, _b, _k in r)
    c("no label --anyway would emit collides with one already in the .s",
      sorted(have & want), [])
    ok, msg = verify(spans)
    c("the runs tile their directives and every printed byte matches the ROM",
      (ok, msg.split(",")[0]), (True, "%d directives" % len(spans)))
    print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAILED", len(FAIL)))
    for f in FAIL:
        print("   ! " + f)
    return 0 if not FAIL else 1


def verdict():
    spans, T = derive()
    nruns = sum(len(r) for _l, _h, r in spans)
    print("prom_b coverage round 2 -- THE VERDICT\n")
    print("  still `.incbin`                              %6d bytes" % T["incbin"])
    print("  reachability.py calls reachable-and-unconverted  %4d bytes, %d runs in "
          "%d directives" % (T["all"], nruns, len(spans)))
    print("    of which STRONG                            %6d" % T["strong"])
    print("    of which pointer-only (weak)               %6d" % (T["all"] - T["strong"]))
    print()
    b = closure()["prom_b"]
    print("  1. CLOSURE   %d seeds across five classes; %d land in an `.incbin`."
          % (sum(v[0] for v in b["classes"].values()),
             sum(len(v[1]) for v in b["classes"].values())))
    tr = trace()
    print("  2. TRACE     %d of %d runs are rooted in a printed DATA row; %d are not."
          % (sum(1 for v in tr.values() if v and all(x["root_is_data"] for x in v)),
             nruns, sum(1 for v in tr.values() if any(not x["root_is_data"] for x in v))))
    nc = sum(1 for _l, _h, r in spans for a, bb, _k in r if shape(a, bb)["code"])
    print("  3. SHAPE     %d of %d runs pass the code rule." % (nc, nruns))
    tm = treadmill()
    print("  4. TREADMILL converting all %d would leave %d fresh reachable bytes."
          % (T["all"], tm["strong"]))
    print("\n  ★ prom_b's reachable-code coverage is CLOSED.  This round converts")
    print("    nothing; the refutation is the deliverable.  See the file header,")
    print("    and `--splice` for what to do if you disagree.")
    return 0


def main():
    if "--derive" in sys.argv:
        spans, T = derive("--force-derive" in sys.argv)
        print("directives %d   incbin %d" % (len(spans), T["incbin"]))
        print("  reachable-and-unconverted, all seeds       : %d" % T["all"])
        print("    of which STRONG (vector/directory/branch): %d" % T["strong"])
        print("    of which `.long`/immediate only (data)   : %d" % (T["all"] - T["strong"]))
        print("  first STRONG walk, before the fixpoint     : %d" % T["strong_first_walk"])
        print("  notes/reachability.py as it stands: STRONG %d, any %d"
              % (T["tool_strong"], T["tool"]))
        if "--write-record" in sys.argv:
            json.dump([{"lo": a, "hi": b, "runs": [list(x) for x in r]}
                       for a, b, r in spans], open(RECORD_PATH, "w"), indent=1)
            print("RECORD written to " + os.path.relpath(RECORD_PATH, ROOT))
        return 0
    if "--layout" in sys.argv:
        spans, _t = derive()
        for lo, hi, runs in spans:
            print("  directive 0x%06X-0x%06X  %6d B" % (lo, hi - 1, hi - lo))
            for a, b, k in runs:
                print("      %-4s 0x%06X-0x%06X  %6d" % (k, a, b - 1, b - a))
        return 0
    rc = 0
    if "--closure" in sys.argv:
        print_closure()
        rc = 1
    if "--trace" in sys.argv:
        print_trace()
        rc = 1
    if "--shape" in sys.argv:
        print_shape()
        rc = 1
    if "--treadmill" in sys.argv:
        tm = treadmill()
        spans, T = derive()
        print("before   .incbin %6d   reachable-and-unconverted %4d"
              % (T["incbin"], T["all"]))
        print("after    .incbin %6d   reachable-and-unconverted %4d"
              % (tm["incbin"], tm["strong"]))
        for lo, hi, size, n in tm["rows"]:
            print("    0x%06X-0x%06X %6d B  STRONG %5d" % (lo, hi - 1, size, n))
        rc = 1
    if rc:
        return 0
    if "--emit" in sys.argv:
        spans, _t = check_record()
        ok, msg = verify(spans)
        if not ok:
            raise SystemExit("refusing to emit: " + msg)
        print("\n".join(emit()))
        return 0
    if "--selftest" in sys.argv or "--checks" in sys.argv:
        return selftest()
    if "--splice" in sys.argv:
        return splice()
    return verdict()


if __name__ == "__main__":
    sys.exit(main())
