#!/usr/bin/env python3
"""Is notes/prom_b_f4f000_layout.py trustworthy enough to convert prom_b
0xF4F000-0xF55000 on?  Wave 7 round 2, lane B2-VERIFY.

QUESTION IT ANSWERS
    Round 1's lane b2 died before it wrote a dossier.  It left
    notes/prom_b_f4f000_layout.py committed and NOTHING describing what that
    script concludes, and no skeptic ever attacked it.  This script is the
    attack.  It re-derives, from the ROM and from the two `.s` files, every
    load-bearing number the layout rests on, and every quantified claim its
    committed docstrings and its HOLES table make -- independently, without
    trusting the layout's own printout.

    It answers, in order:
      1. Does the layout TILE 0xF4F000-0xF55000 exactly?          `--tiling`
      2. Is the null calibration real, and how big is its REAL
         denominator (not its headline byte count)?               `--null`
      3. Do the layout's `code` segments really rebuild the ROM,
         on instruction boundaries, first byte to last?           `--roundtrip`
      4. Is the entry-point evidence real, cited at the
         INSTRUCTION address and not at its operand?              `--evidence`
      5. Do the frontier's and prom_b_dl_call_shapes.py's
         independent claims about this span agree with it?        `--cross`
      6. Does every quantified claim in the layout's docstrings
         and HOLES table reproduce?                               `--claims`
      7. Is the neighbouring span 0xF5553F-0xF57D1E the same
         module continuing?                                       `--neighbour`

WHAT IT FOUND (every number here is re-derived by a mode below; do not retype)
    THE LAYOUT IS SOUND.  It tiles 0xF4F000-0xF55000 exactly -- 43 segments,
    24,576 bytes, no gap, no overlap, first at 0xF4F000, last ending on 0xF55000
    (`--tiling`).  All seven `code` segments assemble back to the ROM AND tile
    their own extent on instruction boundaries from first byte to last, each
    ending in a flow end (`--roundtrip`).  The null corpus is genuine: 107,345
    bytes of proven prom_b instruction text in 5,433 runs, every run endpoint a
    real instruction line, and NOT ONE run intersects the span under test, so
    the calibration is not circular (`--null`).  Only 80 of the 5,376 code bytes
    (1.5%) are accept()-promoted; the rest is reached by descent from a thunk
    slot, a proven prom_a call or a display-list call site (`--evidence`).

    ELEVEN QUANTIFIED CLAIMS IN ITS OWN DOCSTRINGS DO NOT REPRODUCE
    (`--claims`), seven distinct defects.  None moves a segment boundary:
      1. `rom_tables.__doc__`'s calibration table says ">= 3 entries 114
         objects" and ">= 5 entries 16 objects, 13 inside"; the script's own
         `--null-romtab` prints 119, and 20/14.  Two of its four rows are wrong
         and the function one screen below refutes them.  The CONCLUSION
         survives: 7 IS the smallest threshold framing nothing inside the
         record array (>=6 leaves one).
      2. "1,420 bytes came out as `data` until this rule was added" is 1,424 --
         the three prom_a-pointing tables are 272 + 356 + 796.
      3. The header's "fifteen display lists" is 13 accepted (16 counting the
         three one-record gaps `--holes` deliberately leaves as data).  No mode
         of the layout prints 15.
      4. HOLES[0xF4FA7A]: "prom_a takes the address of NINE points inside it"
         is EIGHT.  The ninth, "the run's own start" 0xF4FA7A, is named by no
         instruction in either image.
      5. HOLES[0xF4FE38]: "THIRTY-ONE distinct addresses" is 29 -- by the
         layout's OWN proven_operands().
      6. "`--selftest` -- 40 checks, incl. the LAST" runs 66 checks.  (They
         all pass; the count is simply stale.)
      7. HOLES[0xF542A4] describes 44 of that segment's 45 bytes (nine zero
         words + eight descending bytes); the trailing 0x00 at 0xF542D0 is
         never mentioned, in a table whose contract is that every `data` byte
         is described.
      (the last two of the eleven are one defect counted twice: `refs()` and
       `proven_operands()` -- which collect the strongest evidence this span
       has, 134 reference lines, all in prom_a -- are NOT REACHABLE from the
       CLI.  main() dispatches no flag for either, so no committed mode prints
       them and no skeptic would ever see them.)
    Also loose, though `--claims` only prints it: the header's "three biggest
    objects are tables of PROM_A addresses" is false twice over.  The three
    biggest objects are the 4,692-byte link table, the 3,570-byte pad and the
    3,139-byte record array; and the biggest ROMTAB object (0xF51E8A, 225
    entries) points at prom_B, not prom_a.

    AND ONE STRUCTURAL GAP THE BYTE GATE CANNOT SEE.
    `LY.proven_call_sites()` returns the EMPTY SET for this span, because its
    regex reads the mnemonic out of the `; ADDR <text>` comment -- prom_b's
    convention -- and prom_a writes the raw BYTES there.  The layout knows (it
    says so in proven_operands.__doc__) but provenance() still grades on the
    blind function, so 0xF4F000 / 0xF4F017 / 0xF4F02E come out `CALL` (an
    opcode-anchored byte scan whose own null shows two false positives in this
    very span) when they are PROVEN: real `call` lines at prom_a 0xFBE85C,
    0xFBE7D4 and 0xFBBA9B, each with opcode 0x1D AT the cited address.  The
    grade UNDERSTATES the evidence.  Nothing is wrongly promoted.

    ONE THING A CONVERTING LANE MUST DECIDE.  accept() promotes
    0xF53001-0xF53019 to code, where it reads `ret / nop nop nop` x3 -- that is
    `0E 00 00 00` slot fill.  The already-converted module at 0xF55000 emits the
    IDENTICAL pattern as `.byte` under the header "Six 4-byte slots of
    `0E 00 00 00`".  Byte-identical either way; the tree should not say both.

VERDICT: SAFE TO CONVERT on this layout, unchanged.  Every correction above is
    to PROSE or to a grade label; no segment boundary moves.  Fix the six
    numbers and wire refs() into main() in the same commit that converts.

RUN
    python3 notes/prom_b_f4f000_verify.py                 # the verdict
    python3 notes/prom_b_f4f000_verify.py --tiling
    python3 notes/prom_b_f4f000_verify.py --null
    python3 notes/prom_b_f4f000_verify.py --roundtrip     # needs llvm-mc, ~40 s
    python3 notes/prom_b_f4f000_verify.py --evidence
    python3 notes/prom_b_f4f000_verify.py --cross
    python3 notes/prom_b_f4f000_verify.py --claims
    python3 notes/prom_b_f4f000_verify.py --neighbour
    python3 notes/prom_b_f4f000_verify.py --selftest      # 62 checks, incl. LAST
Exit status is non-zero if --selftest fails or if --claims finds a docstring
number that does not reproduce (it currently finds 11).  Building the layout
costs ~40 s and every mode that needs it pays that once.
"""
import collections
import importlib.util
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

LO, HI = 0xF4F000, 0xF55000
B_BASE, A_BASE = 0xF00000, 0xF80000
NEXT_SPAN = (0xF5553F, 0xF57D1E)
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")

ARGV = list(sys.argv)
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def _load(path, name):
    """Import a sibling tool.  argv is masked: several of them read sys.argv at
    import time and would eat this script's own flags."""
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


F = _load(os.path.join(ROOT, "notes", "prom_b_f4f000_layout.py"), "f4f000_layout")
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_f0ea9f_layout as LY                                  # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402
import prom_b_thunk_table as TT                                    # noqa: E402

_c = {}


def rom(img="b"):
    if img not in _c:
        name = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13"}[img]
        _c[img] = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
    return _c[img]


def w32(a, img="b"):
    d, base = rom(img), (B_BASE if img == "b" else A_BASE)
    o = a - base
    return d[o] | d[o + 1] << 8 | d[o + 2] << 16 | d[o + 3] << 24


def layout():
    if "segs" not in _c:
        _c["segs"] = F.build()
    return _c["segs"]


# ===================================================== 1. does it TILE?
def tiling():
    """The tiling arithmetic, done on the printed segment list, not on build()'s
    internal kind[] array (which tiles by construction and so cannot fail)."""
    segs = layout()[0]
    print("segments: %d" % len(segs))
    p, gaps, overlaps = LO, [], []
    for k, s, n in segs:
        if s > p:
            gaps.append((p, s))
        elif s < p:
            overlaps.append((s, p))
        p = s + n
    tot = sum(n for _k, _s, n in segs)
    print("  first segment          %-8s 0x%06X" % (segs[0][0], segs[0][1]))
    print("  last  segment          %-8s 0x%06X + %d = 0x%06X"
          % (segs[-1][0], segs[-1][1], segs[-1][2], segs[-1][1] + segs[-1][2]))
    print("  sum of lengths         %d   (span is %d)" % (tot, HI - LO))
    print("  gaps                   %d %s" % (len(gaps), gaps))
    print("  overlaps               %d %s" % (len(overlaps), overlaps))
    by = collections.Counter()
    for k, _s, n in segs:
        by[k] += n
    print("  bytes by kind          %s" % dict(sorted(by.items())))
    print("  they sum to            %d" % sum(by.values()))
    # the .incbin the span currently is, read from the .s
    src = open(image_path(ROOT, "prom_b/wsa1_prom_b.s")).read()
    want = '.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X' % (LO - B_BASE, HI - LO)
    print("  the .s still holds it as one .incbin: %s" % (want in src))
    ok = (not gaps and not overlaps and tot == HI - LO
          and segs[0][1] == LO and segs[-1][1] + segs[-1][2] == HI
          and sum(by.values()) == HI - LO and want in src)
    return 0 if ok else 1


# ================================================ 2. is the NULL real?
def null():
    """Is the null corpus genuine PROVEN instruction text, is it big enough for
    the rules calibrated on it, and does it touch the span under test?"""
    runs = L.proven_code_runs()
    tot = sum(e - s for s, e in runs)
    print("null corpus = L.proven_code_runs(): %d runs, %d bytes" % (len(runs), tot))
    print("  address range 0x%06X..0x%06X" % (min(s for s, _ in runs),
                                              max(e for _, e in runs)))
    inside = [(s, e) for s, e in runs if s < HI and LO < e]
    print("  runs intersecting the span under test: %d  <- MUST be 0 (circularity)"
          % len(inside))
    # is it really instruction text?  every run endpoint must decode, and the
    # corpus is built from lines whose mnemonic is not a directive
    src = open(image_path(ROOT, "prom_b/wsa1_prom_b.s")).read().splitlines()
    seen = set()
    for ln in src:
        m = re.search(r";\s*([0-9A-F]{6})\s\s", ln)
        body = ln.split(";")[0]
        if m and body.startswith("\t") and not body.lstrip().startswith("."):
            seen.add(int(m.group(1), 16))
    print("  instruction lines in prom_b/wsa1_prom_b.s: %d" % len(seen))
    print("  FIRST run 0x%06X-0x%06X, both endpoints are instruction lines: %s"
          % (runs[0][0], runs[0][1], runs[0][0] in seen and runs[0][1] in seen))
    print("  LAST  run 0x%06X-0x%06X, both endpoints are instruction lines: %s"
          % (runs[-1][0], runs[-1][1], runs[-1][0] in seen and runs[-1][1] in seen))
    bad = [(s, e) for s, e in runs if s not in seen or e not in seen]
    print("  runs with an endpoint that is NOT an instruction line: %d" % len(bad))
    print()
    print("  ⚠ the headline byte count is the WRONG DENOMINATOR for a rule that")
    print("  needs N consecutive bytes: the corpus is 5,433 FRAGMENTS, median ~14 B.")
    print("  %-38s %6s %8s %9s" % ("rule (bytes it needs)", "runs", "bytes", "starts"))
    for n, lab in ((28, "romtab >= 7 entries (28 B)"),
                   (48, "link >= 8 records (48 B)"),
                   (20, "ascii >= 20 bytes"),
                   (16, "bytemap >= 16 bytes"),
                   (8, "interstitial window (>= 8 B)")):
        r = sum(1 for s, e in runs if e - s >= n)
        b = sum(e - s for s, e in runs if e - s >= n)
        o = sum(max(0, (e - s) - n + 1) for s, e in runs)
        print("  %-38s %6d %8d %9d" % (lab, r, b, o))
    print()
    print("  ⚠ L.proven_code_runs() returns (first START, last START), so each")
    print("  run is short by its own last instruction.  Harmless for a null (it")
    print("  shrinks the corpus) but the 107,345 is not a byte count of code.")
    return 0 if (not inside and not bad) else 1


# ============================== 3. do the `code` segments rebuild the ROM?
def code_segments():
    return [(s, n) for k, s, n in layout()[0] if k == "code"]


def roundtrip():
    """Assemble every `code` segment and prove it tiles on instruction
    boundaries from its FIRST byte to its LAST.

    notes/llvm_roundtrip_autoforce.py assembles its candidate listing and
    byte-compares it with the ROM before printing, so exit 0 already means the
    segment rebuilds.  What that does NOT say is that the listing covers the
    segment exactly, so this re-walks the emitted addresses against
    MT.decode_at() lengths and checks the last instruction ends on the segment
    end -- the failure a byte-identical listing can still hide."""
    bad = 0
    for s, n in code_segments():
        out = subprocess.run([sys.executable, AUTOFORCE, "b", hex(s), hex(n), "--quiet"],
                             capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            print("  0x%06X %5d  ASSEMBLY FAILED" % (s, n))
            bad += 1
            continue
        addrs, texts = [], []
        for ln in out.stdout.splitlines():
            m = re.search(r";\s*([0-9A-F]{6})\s\s(.*)", ln)
            if m:
                addrs.append(int(m.group(1), 16))
                texts.append(m.group(2).strip())
        tile = addrs[0] == s
        for a, b in zip(addrs, addrs[1:]):
            dec = MT.decode_at(a)
            if dec is None or a + dec[0] != b:
                tile = False
        last = MT.decode_at(addrs[-1])
        end_ok = last is not None and addrs[-1] + last[0] == s + n
        flow = texts[-1].split()[0] in ("ret", "reti", "jp", "jr", "jrl", "swi")
        print("  0x%06X-0x%06X %5d B  %4d insns  tiles %-5s ends-at-end %-5s  "
              "last `%s`%s" % (s, s + n - 1, n, len(addrs), tile, end_ok,
                               texts[-1], "" if flow else "   (not a flow end)"))
        if not (tile and end_ok):
            bad += 1
    print("  segments that do not tile their own extent: %d" % bad)
    return bad


# ================================= 4. is the ENTRY-POINT evidence real?
CALLERS = {
    # target -> (image, site, the opcode byte that must be AT the site)
    0xF4F000: ("a", 0xFBE85C, 0x1D),
    0xF4F017: ("a", 0xFBE7D4, 0x1D),
    0xF4F02E: ("a", 0xFBBA9B, 0x1D),
}


def evidence():
    """Every code segment's entry point, and what really names it.

    ⚠ THE CITATION RULE.  A call site is cited at the address of its OPCODE.
    The signature of this project's recurring bug is a citation whose byte is an
    operand, so each site below is checked by reading the opcode byte AT the
    cited address."""
    d = layout()
    segs, _c2, _p, ok, seen, lists, idiom, ptrvals = d
    dsrc = rom()
    print("prom_a instructions that call INTO the span (proven: they are lines")
    print("of prom_a/wsa1_prom_a.s, which the byte gate rebuilds):")
    src = open(image_path(ROOT, "prom_a/wsa1_prom_a.s")).read().splitlines()
    got = {}
    for ln in src:
        m = re.search(r";\s*([0-9A-F]{6})\s\s", ln)
        if not m:
            continue
        mm = re.match(r"\s*(call|jp)\s+0x([0-9a-f]{6})\s*$", ln.split(";")[0])
        if not mm:
            continue
        t = int(mm.group(2), 16)
        if LO <= t < HI:
            got.setdefault(t, []).append(int(m.group(1), 16))
    for t in sorted(got):
        for site in got[t]:
            op = rom("a")[site - A_BASE]
            print("  0x%06X <- prom_a 0x%06X  opcode AT the cited address 0x%02X %s"
                  % (t, site, op, "(call/jp)" if op in (0x1B, 0x1D) else "⚠ NOT 1B/1D"))
    print("  distinct targets %d, sites %d"
          % (len(got), sum(len(v) for v in got.values())))
    print()
    print("⚠ LY.proven_call_sites(LO,HI) -- the layout's TOP evidence grade -- "
          "returns %d" % len(LY.proven_call_sites(LO, HI)))
    print("  It matches the mnemonic inside the `; ADDR <text>` comment, which is")
    print("  prom_b's convention; prom_a writes the raw BYTES there.  So the")
    print("  strongest evidence this span has is invisible to the grader, and")
    print("  provenance() falls back to CALL (an opcode-anchored byte scan).")
    print()
    print("code segments, their layout grade, and what actually names them:")
    thunk = F.thunk_targets(LO, HI)
    far = F.far_calls_ex(dsrc, LO, HI, ptrvals)
    site = F.dl_sites_in(lists)
    idi = set(a for a, _t, _k in idiom)
    accepted = set(s for s, _e in ok)   # ok is a dict keyed by (start, end)
    for s, n in code_segments():
        why = []
        if s in got:
            why.append("PROVEN prom_a call x%d" % len(got[s]))
        if s in thunk:
            why.append("thunk slot")
        if s in far:
            why.append("far_calls byte scan")
        if s in site:
            why.append("display-list call site")
        if s in idi:
            why.append("jp-over-stub idiom")
        if s in accepted:
            why.append("accept()")
        print("  0x%06X %5d B   %s" % (s, n, ", ".join(why) or "⚠ NOTHING"))
    print()
    allfc = sorted(L.far_calls(dsrc, LO, HI))
    junk = [t for t in allfc
            if [k for k, a, nn in segs if a <= t < a + nn][0] in ("fill", "link")]
    print("far_calls is an UPPER BOUND and this span shows it: %d of its %d "
          "in-span targets" % (len(junk), len(allfc)))
    print("  are 0x0E/pad bytes read as an address --")
    for t in junk:
        kind = [k for k, a, nn in segs if a <= t < a + nn][0]
        print("    0x%06X lands in a `%s` segment (the barrier blocks it)" % (t, kind))
    print("  plus %d removed by far_calls_ex as display-list DATA pointers: %s"
          % (len([t for t in L.far_calls(dsrc, LO, HI) if t in ptrvals]),
             sorted("0x%06X" % t for t in L.far_calls(dsrc, LO, HI) if t in ptrvals)))
    print()
    print("accept()-promoted runs (nothing points at them): %d, %d bytes of %d code"
          % (len(ok), sum(e - s for s, e in ok), sum(n for _s, n in code_segments())))
    for a, e in sorted(ok):
        print("    0x%06X-0x%06X  %d B" % (a, e - 1, e - a))
    print("  ⚠ 0xF53001-0xF53019 is `0E 00 00 00` slot fill decoded as")
    print("  `ret / nop nop nop`.  Byte-exact, but the already-converted module")
    print("  at 0xF55000 emits the SAME pattern as `.byte` (see the block header")
    print("  at prom_b/wsa1_prom_b.s: \"Six 4-byte slots of `0E 00 00 00`\").")
    print("  A converting lane should say which it is, in a comment.")
    return 0


# =============================== 5. do the INDEPENDENT tools agree?
def cross():
    """The frontier table's thunk run, and prom_b_dl_call_shapes.py's display
    lists, re-derived here and compared with the layout."""
    b = rom()
    print("THE THUNK RUN T_F42E40-T_F42E6C, read straight out of the ROM:")
    slots = []
    for slot in range(0x42E40, 0x42E70, 4):
        k, v = TT.classify(b, slot)
        slots.append((B_BASE + slot, k, v))
    for a, k, v in slots:
        print("    T_%06X  %-4s 0x%06X   %s" % (a, k, v, b[a - B_BASE:a - B_BASE + 4].hex(" ")))
    tg = [v for _a, _k, v in slots]
    print("  slots %d   distinct targets %d   extent %d   all in span %s"
          % (len(slots), len(set(tg)), max(tg) - min(tg),
             all(LO <= v < HI for v in tg)))
    print("  FIRST target 0x%06X   LAST target 0x%06X" % (tg[0], tg[-1]))
    kindof = {}
    for k, s, n in layout()[0]:
        for x in range(s, s + n):
            kindof[x] = k
    print("  every target lands in a `code` segment: %s"
          % all(kindof[v] == "code" for v in tg))
    print("  ⚠ the run has 12 SLOTS and 11 DISTINCT targets (T_F42E58 and")
    print("  T_F42E5C both name 0xF5301A).  wave7_frontier_table.py says 12.")
    r = subprocess.run([sys.executable,
                        os.path.join(ROOT, "notes", "prom_b_module_frontier.py")],
                       capture_output=True, text=True, cwd=ROOT)
    for ln in r.stdout.splitlines():
        if "T_F42E40" in ln or ln.strip().startswith("run "):
            print("  frontier: %s" % ln.strip())
        if ln.startswith("prom_b thunk RUNS"):
            print("  frontier: %s" % ln.strip())
    print("  (it is prom_b's TOP-ranked run by contiguous unconverted extent)")
    print()
    print("DISPLAY LISTS -- notes/prom_b_dl_call_shapes.py --new, in this span:")
    out = subprocess.run([sys.executable,
                          os.path.join(ROOT, "notes", "prom_b_dl_call_shapes.py"),
                          "--new"], capture_output=True, text=True, cwd=ROOT)
    named = []
    for ln in out.stdout.splitlines():
        m = re.match(r"\s+([0-9A-F]{6})-([0-9A-F]{6})\s+(\d+)\s*$", ln)
        if m:
            s, e = int(m.group(1), 16), int(m.group(2), 16)
            if LO <= s < HI:
                named.append((s, e + 1))
    for s, e in named:
        print("    0x%06X-0x%06X  %4d B" % (s, e - 1, e - s))
    lists = layout()[5]
    merged = F.dl_ranges(lists)
    print("  the layout's merged `dl` ranges:")
    for s, e in merged:
        print("    0x%06X-0x%06X  %4d B" % (s, e - 1, e - s))
    cov = set()
    for s, e in merged:
        cov |= set(range(s, e))
    missing = [(s, e) for s, e in named if not set(range(s, e)) <= cov]
    print("  every call-site-named list is covered by a `dl` segment: %s"
          % (not missing))
    extra = sorted(cov - set(x for s, e in named for x in range(s, e)))
    if extra:
        print("  bytes the layout types `dl` that no call site names: %d, "
              "0x%06X-0x%06X" % (len(extra), extra[0], extra[-1]))
        print("    -> the INTERSTITIAL 0xF54416-0xF544AC, %d strict records, "
              "landing exactly on the proven list at 0x%06X"
              % (lists[0xF54416][4], lists[0xF54416][0]))
    return 0 if not missing else 1


# ================================= 6. do the PROSE numbers reproduce?
def claims():
    """Every quantified claim in prom_b_f4f000_layout.py's docstrings and HOLES
    table, recomputed from the ROM and the two `.s` files."""
    d = rom()
    bad = 0

    def claim(what, got, said):
        nonlocal bad
        ok = got == said
        if not ok:
            bad += 1
        print("  %-56s got %-10s doc says %-10s %s"
              % (what, got, said, "OK" if ok else "*** WRONG ***"))

    print("ROMTAB's own calibration table (rom_tables.__doc__):")
    for m, said_obj, said_in in ((3, 114, 109), (5, 16, 13), (6, 7, 1), (7, 6, 0)):
        objs = F.rom_tables(d, LO, HI, m)
        inrec = [x for x in objs if 0xF511E9 <= x[0] < 0xF51E20]
        claim(">= %d entries: objects" % m, len(objs), said_obj)
        claim(">= %d entries: inside the record array" % m, len(inrec), said_in)
    print("  the CONCLUSION -- 7 is the smallest threshold framing 0 inside --")
    seven = min(m for m in range(3, 16)
                if not [x for x in F.rom_tables(d, LO, HI, m)
                        if 0xF511E9 <= x[0] < 0xF51E20])
    claim("smallest threshold with 0 inside the record array", seven, 7)

    print("\nwhat the ROMTAB rule actually gained (docstring: '1,420 bytes'):")
    covpt = set()
    for a, e in L.ptr_tables(d, LO, HI):
        covpt |= set(range(a, e))
    gain = sum(1 for a, e in F.rom_tables(d, LO, HI) for x in range(a, e)
               if x not in covpt)
    claim("romtab bytes L.ptr_tables cannot see", gain, 1420)
    print("    (they are the three prom_a-pointing tables: 68+89+199 entries")
    print("     = 272+356+796 = 1424 bytes)")

    print("\nheader docstring: 'three biggest objects are tables of PROM_A "
          "addresses'")
    segs = layout()[0]
    big = sorted(segs, key=lambda x: -x[2])[:3]
    print("    the three biggest segments are actually %s"
          % [(k, "0x%06X" % s, n) for k, s, n in big])
    rt = F.rom_tables(d, LO, HI)
    ent = [(a, (e - a) // 4, sum(1 for x in range(a, e, 4) if w32(x) >= A_BASE))
           for a, e in rt]
    print("    romtab objects (addr, entries, of which point at prom_a):")
    for a, n, na in ent:
        print("      0x%06X %4d %4d" % (a, n, na))
    bigrt = max(ent, key=lambda x: x[1])
    print("    -> the LARGEST romtab object 0x%06X (%d entries) points at "
          "prom_B, so the" % (bigrt[0], bigrt[1]))
    print("       three prom_a-pointing tables are not 'the three largest'.")

    print("\nheader docstring: 'fifteen display lists'")
    lists = layout()[5]
    claim("display lists (accepted; +3 one-record gaps = 16)", len(lists), 15)

    print("\nHOLES prose, recomputed:")
    P = F.proven_operands()
    claim("HOLES[0xF4FA7A]: points prom_a names inside it",
          len([a for a in P if 0xF4FA7A <= a < 0xF4FA9B]), 9)
    claim("HOLES[0xF4FE38]: distinct addresses named inside it",
          len([a for a in P if 0xF4FE38 <= a < 0xF4FF61]), 31)
    claim("HOLES[0xF51E2C]: 0xF51E58 named this many times",
          len(P.get(0xF51E58, [])), 6)
    claim("HOLES[0xF51E2C]: 0xF51E34 named this many times",
          len(P.get(0xF51E34, [])), 3)
    heads = [a for a in range(0xF511DD, 0xF51E20)
             if w32(a) in (0x00FB4D61, 0x00FB4D62)]
    st = collections.Counter(y - x for x, y in zip(heads, heads[1:]))
    claim("HOLES[0xF511DD]: record heads", len(heads), 109)
    claim("HOLES[0xF511DD]: first head", "0x%06X" % heads[0], "0xF51209")
    claim("HOLES[0xF511DD]: LAST head", "0x%06X" % heads[-1], "0xF51E08")
    claim("HOLES[0xF511DD]: head-to-head strides", dict(sorted(st.items())),
          {28: 98, 30: 2, 32: 7, 43: 1})
    seg = [n for k, s, n in segs if s == 0xF542A4][0]
    zero = sum(1 for x in range(0xF542A4, 0xF542A4 + 36) if d[x - B_BASE] == 0)
    claim("HOLES[0xF542A4]: segment length (prose describes 36+8 = 44)", seg, 44)
    print("    ... 36 leading zero bytes: %s" % (zero == 36))
    print("    the unmentioned byte is 0x%06X = 0x%02X"
          % (0xF542A4 + 44, d[0xF542A4 + 44 - B_BASE]))

    print("\nproven_operands.__doc__: 'all 134 proven references ... are in PROM_A'")
    claim("reference LINES into the span", sum(len(v) for v in P.values()), 134)
    claim("images they come from", sorted(set(i for v in P.values()
                                              for i, _s, _t in v)), ["a"])
    claim("distinct addresses named", len(P), 81)

    print("\nthe LINK table, re-walked from the ROM:")
    a = 0xF4FF61
    p, n, ptrs = a, 0, []
    while p + 6 <= 0xF511B5:
        v = w32(p + 2)
        if v:
            ptrs.append(v)
        p += 6
        n += 1
    claim("records", n, 782)
    claim("non-null pointers", len(ptrs), 779)
    claim("all land on a 6-byte boundary of the table itself",
          sorted(set((v - a) % 6 for v in ptrs)), [0])
    claim("all land INSIDE the table", all(a <= v < p for v in ptrs), True)
    claim("FIRST record's pointer", "0x%06X" % w32(a + 2), "0xF4FF61")
    claim("LAST  record's pointer", "0x%06X" % w32(p - 4), "0xF4FF61")
    alt = 0xF4FF63
    ap = [w32(q) for q in range(alt, 0xF511B5 - 5, 6) if w32(q)]
    claim("the OTHER framing's pointers are NOT record-aligned",
          sorted(set((v - alt) % 6 for v in ap)) != [0], True)

    print("\nthe layout's own advertised check count:")
    r = subprocess.run([sys.executable,
                        os.path.join(ROOT, "notes", "prom_b_f4f000_layout.py"),
                        "--selftest"], capture_output=True, text=True, cwd=ROOT)
    n = len([l for l in r.stdout.splitlines()
             if re.search(r"(OK|FAIL want .*)\s*$", l)])
    claim("--selftest checks (docstring says '40 checks')", n, 40)
    print("    (they all PASS: %s)" % r.stdout.strip().splitlines()[-1])

    print("\nreachability of the strongest-evidence functions:")
    body = open(os.path.join(ROOT, "notes", "prom_b_f4f000_layout.py")).read()
    main = body[body.index("def main("):]
    claim("main() dispatches a flag for refs()", "refs()" in main, True)
    claim("main() dispatches a flag for proven_operands()",
          "proven_operands" in main, True)
    print("\nclaims that do NOT reproduce: %d" % bad)
    return bad


# ================================ 7. is the NEXT span the same module?
def neighbour():
    """Is 0xF5553F-0xF57D1E the same module continuing past 0xF55000?"""
    b = rom()
    d = layout()[0]
    print("the span's LAST segment: %-6s 0x%06X-0x%06X, %d bytes, pure 0x%02X: %s"
          % (d[-1][0], d[-1][1], d[-1][1] + d[-1][2] - 1, d[-1][2], 0x0E,
             set(b[d[-1][1] - B_BASE:d[-1][1] + d[-1][2] - B_BASE]) == {0x0E}))
    print("0xF55000 onward is ALREADY CONVERTED; its block header in the .s says:")
    src = open(image_path(ROOT, "prom_b/wsa1_prom_b.s")).read().splitlines()
    i = next(j for j, l in enumerate(src) if "0xF55000-0xF5535A" in l)
    for l in src[i:i + 12]:
        print("    %s" % l.rstrip())
    print()
    print("WHICH THUNK RUN SERVES WHICH BLOCK -- this is the answer:")
    for lo, hi, lab in ((0x42E40, 0x42E70, "T_F42E40-T_F42E6C"),
                        (0x42C70, 0x42CAC, "T_F42C70-T_F42CA8"),
                        (0x40D90, 0x40E1C, "T_F40D90-T_F40E18")):
        tg = []
        for slot in range(lo, hi, 4):
            k, v = TT.classify(b, slot)
            tg.append(v)
        n_span = sum(1 for v in tg if LO <= v < HI)
        n_conv = sum(1 for v in tg if 0xF55000 <= v < NEXT_SPAN[0])
        n_next = sum(1 for v in tg if NEXT_SPAN[0] <= v < NEXT_SPAN[1])
        print("  %-20s %2d slots  0x%06X..0x%06X   in THIS span %2d | in the "
              "converted 0xF55000 block %2d | in 0xF5553F+ %2d"
              % (lab, len(tg), min(tg), max(tg), n_span, n_conv, n_next))
    print()
    print("  T_F42C70-T_F42CA8 STRADDLES the boundary: T_F42CA8 -> 0x%06X, the"
          % 0xF5553F)
    print("  first byte of the NEXT .incbin, while TWELVE of its slots are")
    print("  already-converted code at 0xF55018-0xF551E7.  So 0xF5553F is the")
    print("  0xF55000 module CONTINUING, not this span's module continuing.")
    print()
    print("  This span's code reaches the 0xF55000 module only through the")
    print("  thunk table.  Out-of-span operands in the seven `code` segments:")
    out = collections.Counter()
    for s, n in code_segments():
        r = subprocess.run([sys.executable, AUTOFORCE, "b", hex(s), hex(n), "--quiet"],
                           capture_output=True, text=True, cwd=ROOT)
        for ln in r.stdout.splitlines():
            m = re.search(r";\s*([0-9A-F]{6})\s\s(.*)", ln)
            if not m:
                continue
            for h in re.findall(r"0x0*([0-9a-f]{5,6})\b", m.group(2)):
                v = int(h, 16)
                if 0xF00000 <= v < 0x1000000 and not (LO <= v < HI):
                    out[v] += 1
    for v, n in sorted(out.items()):
        k, t = TT.classify(b, v - B_BASE) if 0xF40000 <= v < 0xF44018 else ("", 0)
        print("    0x%06X x%-3d %s" % (v, n, ("thunk slot -> 0x%06X" % t) if k else ""))
    inthunk = all(0xF40000 <= v < 0xF44018 for v in out)
    print("  every one of them is a thunk-table slot: %s" % inthunk)
    return 0 if inthunk else 1


# ============================================================ selftest
def selftest():
    print("prom_b_f4f000_verify.py --selftest")
    b = rom()
    segs, _conf, _pend, ok, _seen, lists, idiom, ptrvals = layout()

    # --- 1. tiling, done by hand ---
    p, gaps, over = LO, 0, 0
    for _k, s, n in segs:
        if s > p:
            gaps += 1
        elif s < p:
            over += 1
        p = s + n
    check("segments: gaps", gaps, 0)
    check("segments: overlaps", over, 0)
    check("FIRST segment starts at LO", "0x%06X" % segs[0][1], "0x%06X" % LO)
    check("LAST segment ends at HI", "0x%06X" % (segs[-1][1] + segs[-1][2]),
          "0x%06X" % HI)
    check("sum of segment lengths", sum(n for _k, _s, n in segs), HI - LO)
    by = collections.Counter()
    for k, _s, n in segs:
        by[k] += n
    check("bytes by kind sum to the span", sum(by.values()), HI - LO)
    check("substantive (non-fill) bytes", sum(v for k, v in by.items() if k != "fill"),
          19673)
    src = open(image_path(ROOT, "prom_b/wsa1_prom_b.s")).read()
    check("the span is still ONE .incbin in the .s",
          '.incbin "original_ROMs/wsa1_prom_b.ic13", 0x04F000, 0x006000' in src, True)

    # --- 2. the null ---
    runs = L.proven_code_runs()
    check("null corpus runs", len(runs), 5433)
    check("null corpus bytes", sum(e - s for s, e in runs), 107345)
    check("null corpus runs intersecting the span (circularity)",
          len([1 for s, e in runs if s < HI and LO < e]), 0)
    check("null corpus start positions a 48-byte rule can even use",
          sum(max(0, (e - s) - 47) for s, e in runs), 17590)
    check("null corpus start positions a 28-byte rule can even use",
          sum(max(0, (e - s) - 27) for s, e in runs), 32006)

    # --- 3. the code segments ---
    cs = code_segments()
    check("code segments", len(cs), 7)
    check("FIRST code segment", "0x%06X %d" % cs[0], "0xF4F000 627")
    check("LAST  code segment", "0x%06X %d" % cs[-1], "0xF53899 2479")
    check("code bytes", sum(n for _s, n in cs), 5376)
    check("accept()-promoted runs", len(ok), 7)
    check("accept()-promoted bytes", sum(e - s for s, e in ok), 80)
    okl = sorted(ok)           # L.accept returns a DICT keyed by (start, end)
    check("FIRST accept() run", "0x%06X-0x%06X" % (okl[0][0], okl[0][1] - 1),
          "0xF53001-0xF53019")
    check("LAST  accept() run", "0x%06X-0x%06X" % (okl[-1][0], okl[-1][1] - 1),
          "0xF541FE-0xF541FE")

    # --- 4. the evidence ---
    for t, (img, site, op) in sorted(CALLERS.items()):
        check("prom_a 0x%06X really holds opcode 0x%02X (cited at the "
              "INSTRUCTION)" % (site, op), "0x%02X" % rom(img)[site - A_BASE],
              "0x%02X" % op)
        check("  ... and its operand is 0x%06X" % t,
              "0x%06X" % (rom(img)[site - A_BASE + 1]
                          | rom(img)[site - A_BASE + 2] << 8
                          | rom(img)[site - A_BASE + 3] << 16), "0x%06X" % t)
    check("LY.proven_call_sites() for this span (blind to prom_a)",
          len(LY.proven_call_sites(LO, HI)), 0)
    body = open(os.path.join(ROOT, "notes", "prom_b_f4f000_layout.py")).read()
    check("layout main() dispatches refs()", "refs()" in body[body.index("def main("):],
          False)

    # --- 5. the thunk run ---
    slots = []
    for slot in range(0x42E40, 0x42E70, 4):
        k, v = TT.classify(b, slot)
        slots.append((B_BASE + slot, k, v))
    check("T_F42E40-T_F42E6C slots", len(slots), 12)
    check("  ... distinct targets", len(set(v for _a, _k, v in slots)), 11)
    check("  FIRST slot", "T_%06X %s 0x%06X" % slots[0], "T_F42E40 ptr 0xF53000")
    check("  LAST  slot", "T_%06X %s 0x%06X" % slots[-1], "T_F42E6C jp 0xF54210")
    check("  extent (frontier table says 4624)",
          max(v for _a, _k, v in slots) - min(v for _a, _k, v in slots), 4624)
    kindof = {}
    for k, s, n in segs:
        for x in range(s, s + n):
            kindof[x] = k
    check("  every target lands in a `code` segment",
          sorted(set(kindof[v] for _a, _k, v in slots)), ["code"])

    # --- 6. the display lists ---
    merged = F.dl_ranges(lists)
    check("merged `dl` ranges", len(merged), 4)
    check("FIRST `dl` range", "0x%06X-0x%06X" % (merged[0][0], merged[0][1] - 1),
          "0xF542ED-0xF542F8")
    check("LAST  `dl` range", "0x%06X-0x%06X" % (merged[-1][0], merged[-1][1] - 1),
          "0xF54705-0xF5470F")
    check("accepted lists", len(lists), 13)
    check("  ... of which interstitial",
          sorted("0x%06X" % s for s, v in lists.items() if v[2] == 0), ["0xF54416"])
    check("the interstitial's record count", lists[0xF54416][4], 17)

    # --- 7. the prose numbers that do NOT reproduce ---
    d = rom()
    check("ROMTAB >=3 objects (docstring says 114)",
          len(F.rom_tables(d, LO, HI, 3)), 119)
    check("ROMTAB >=5 objects (docstring says 16)",
          len(F.rom_tables(d, LO, HI, 5)), 20)
    check("ROMTAB >=5 inside the record array (docstring says 13)",
          len([x for x in F.rom_tables(d, LO, HI, 5)
               if 0xF511E9 <= x[0] < 0xF51E20]), 14)
    check("ROMTAB >=7 inside the record array (the conclusion, and it holds)",
          len([x for x in F.rom_tables(d, LO, HI, 7)
               if 0xF511E9 <= x[0] < 0xF51E20]), 0)
    covpt = set()
    for a, e in L.ptr_tables(d, LO, HI):
        covpt |= set(range(a, e))
    check("romtab's real gain in bytes (docstring says 1,420)",
          sum(1 for a, e in F.rom_tables(d, LO, HI) for x in range(a, e)
              if x not in covpt), 1424)
    P = F.proven_operands()
    check("HOLES[0xF4FA7A] points named (prose says nine)",
          len([a for a in P if 0xF4FA7A <= a < 0xF4FA9B]), 8)
    check("  ... and 0xF4FA7A itself is named", 0xF4FA7A in P, False)
    check("HOLES[0xF4FE38] distinct addresses (prose says THIRTY-ONE)",
          len([a for a in P if 0xF4FE38 <= a < 0xF4FF61]), 29)
    check("HOLES[0xF542A4] segment length (prose accounts for 44)",
          [n for k, s, n in segs if s == 0xF542A4][0], 45)
    check("proven_operands reference lines (docstring says 134)",
          sum(len(v) for v in P.values()), 134)
    check("  ... all from prom_a",
          sorted(set(i for v in P.values() for i, _s, _t in v)), ["a"])
    heads = [a for a in range(0xF511DD, 0xF51E20)
             if w32(a) in (0x00FB4D61, 0x00FB4D62)]
    check("HOLES[0xF511DD] heads", len(heads), 109)
    check("  ... LAST head", "0x%06X" % heads[-1], "0xF51E08")
    check("  ... strides",
          dict(sorted(collections.Counter(y - x for x, y in
                                          zip(heads, heads[1:])).items())),
          {28: 98, 30: 2, 32: 7, 43: 1})
    check("display lists (header docstring says fifteen)", len(lists), 13)
    check("  ... + the three 1-record gaps --holes leaves as data",
          len(lists) + 3, 16)

    # --- 8. the neighbour ---
    tg = []
    for slot in range(0x42C70, 0x42CAC, 4):
        _k, v = TT.classify(b, slot)
        tg.append(v)
    check("T_F42C70-T_F42CA8 slots", len(tg), 15)
    check("  ... targets in the ALREADY-CONVERTED 0xF55000 block",
          sum(1 for v in tg if 0xF55000 <= v < NEXT_SPAN[0]), 12)
    check("  ... targets in the NEXT .incbin 0xF5553F-0xF57D1E",
          sum(1 for v in tg if NEXT_SPAN[0] <= v < NEXT_SPAN[1]), 3)
    check("  ... targets in THIS span",
          sum(1 for v in tg if LO <= v < HI), 0)
    check("  LAST slot names the next .incbin's FIRST byte",
          "0x%06X" % tg[-1], "0x%06X" % NEXT_SPAN[0])

    print("FAILURES: %d" % len(FAIL))
    for m in FAIL:
        print("  FAILED: %s" % m)
    return 1 if FAIL else 0


def verdict():
    print(__doc__.split("VERDICT:")[1].split("RUN")[0].strip())
    return 0


def main():
    for flag, fn in (("--selftest", selftest), ("--tiling", tiling),
                     ("--null", null), ("--roundtrip", roundtrip),
                     ("--evidence", evidence), ("--cross", cross),
                     ("--claims", claims), ("--neighbour", neighbour)):
        if flag in ARGV:
            return 1 if fn() else 0
    return verdict()


if __name__ == "__main__":
    sys.exit(main())
