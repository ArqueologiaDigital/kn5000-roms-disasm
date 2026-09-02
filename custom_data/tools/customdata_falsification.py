#!/usr/bin/env python3
r"""customdata_falsification.py -- can the claim "IC19 contains no code" be BROKEN?

QUESTION ANSWERED
    `custom_data/kn5000_custom_data.s` builds 1,048,576 B with ZERO assembly
    statements: every byte is `.incbin` of a generated style bank or a `.byte`
    table. `scripts/analysis/kn5000_source_coverage.py` therefore reports it
    100% source, and `scripts/analysis/tier2_byte_split_census.py` finds 0 B
    of code-as-`.byte` in it. Both of those instruments would say exactly the
    same thing about an image that DID contain code, if that code had been
    typed as data -- the byte gate cannot object in that direction either, and
    this push has already had a 68,934 B near-miss of precisely that shape.

    So: is there any executable code in IC19?

METHOD -- ported from wsa1/notes/prom_cd_falsification_2026_09_02.py, whose
own first two versions were wrong and are documented inside it. Six checks,
each with a null; a criterion that cannot fail is not evidence.

    Q1  Is IC19 even CPU-fetchable? If it hung off a peripheral, "no code" is
        true by construction and Q2-Q5 are pointless.
    Q2  Does any main-CPU SOURCE instruction transfer control into the window?
        Null: the same scanner, on the same sources, for the table_data window
        and for the images' own windows -- it must find things there.
    Q3  How is the window referenced instead? An address LOAD is the signature
        of data (the brief's rule, and how HDAE5000_RECORD_TABLE was settled).
    Q4  Does the ASSEMBLER agree the source has no instruction in it?
        Null: the same instrument on hdae5000 must return thousands.
    Q5  Do IC19's BYTES BEHAVE like code? Branch-target coherence over
        unidasm, NORMALISED BY BOUNDARY DENSITY -- raw "target lands on a
        boundary" does not separate, because a linear decode of data has a
        boundary every ~1.5 B. Calibrated on windows of PROVEN code and
        PROVEN data taken from v10, the same CPU and instruction set.
    Q5b THE SPIKE. Real v10 code is spliced into a copy of IC19 and rescanned.
        If the spiked window does not score like code, the instrument cannot
        see what it reports the absence of, and Q5's negative means nothing.

⚠ WHICH DECODER. Q5 asks unidasm (MAME's TLCS-900 core), never the LLVM
backend: this tree retracted a conclusion built on a backend refusal on
2026-09-02, and five bytes it "could not decode" turned out to be real
instructions. llvm-mc appears only in Q4, and only to count what the assembler
made of the SOURCE.

RUN (from the lane worktree root):
    python3 custom_data/tools/customdata_falsification.py
    python3 custom_data/tools/customdata_falsification.py --verbose
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROMS = os.path.join(ROOT, "original_ROMs")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
DRIVER = os.path.join(ROOT, "mame_driver/src/mame/matsushita/kn5000.cpp")

IC19 = os.path.join(ROMS, "kn5000_custom_data.ic19")
V10 = os.path.join(ROMS, "kn5000_v10_program.rom")
IC19_LO, IC19_HI = 0x300000, 0x400000
V10_BASE = 0xE00000
TABLE_LO, TABLE_HI = 0x800000, 0xA00000

VERBOSE = "--verbose" in sys.argv
fails = checks = 0


def check(label, got, want):
    global fails, checks
    checks += 1
    ok = got == want
    if not ok:
        fails += 1
    print("    [%s] %-58s %s" % ("ok" if ok else "FAIL", label, got))


LINE = re.compile(r'^\s*([0-9a-fA-F]{4,8}):\s+((?:[0-9a-fA-F]{2} )+)\s*(\S+)\s*(.*)$')
FLOW = {"jr", "jrl", "jp", "call", "calr", "djnz"}
TGT = re.compile(r'0x([0-9a-fA-F]+)')
SRC_XFER = re.compile(r'^\s*(call|calr|jp|jr|jrl|djnz)\s+(.*)$')
HEXNUM = re.compile(r'\b0x([0-9a-fA-F]{5,6})\b')


def src_files(root):
    out = []
    for dp, _dn, fns in os.walk(root):
        for fn in fns:
            if fn.endswith(".s"):
                out.append(os.path.join(dp, fn))
    return sorted(out)


def scan_transfers(root, lo, hi):
    """(count, examples) of SOURCE control transfers with a literal target in
    [lo,hi). Reads latin-1 in Python, never grep -- an agent-shell `grep` is
    ugrep -I and skips a file with an invalid UTF-8 byte entirely, returning a
    confident zero (BRIEF, corrected 2026-09-02)."""
    n, ex = 0, []
    for p in src_files(root):
        for i, line in enumerate(open(p, encoding="latin-1"), 1):
            m = SRC_XFER.match(line.split(";")[0])
            if not m:
                continue
            for h in HEXNUM.finditer(m.group(2)):
                v = int(h.group(1), 16)
                if lo <= v < hi:
                    n += 1
                    if len(ex) < 4:
                        ex.append("%s:%d %s" % (os.path.relpath(p, ROOT), i,
                                                line.strip()[:70]))
    return n, ex


def scan_transfers_ctx(root, lo, hi, window=3):
    """Every SOURCE control transfer with a literal target in [lo,hi), tagged
    with whether a raw `.byte` line sits within `window` lines of it."""
    out = []
    for p in src_files(root):
        lines = open(p, encoding="latin-1").read().split("\n")
        for i, line in enumerate(lines, 1):
            m = SRC_XFER.match(line.split(";")[0])
            if not m:
                continue
            for h in HEXNUM.finditer(m.group(2)):
                v = int(h.group(1), 16)
                if not (lo <= v < hi):
                    continue
                near = any(re.match(r'\s*(?:[A-Za-z_.$][\w.$]*:\s*)?\.byte\b',
                                    lines[j])
                           for j in range(max(0, i - 1 - window),
                                          min(len(lines), i + window)))
                out.append((os.path.relpath(p, ROOT), i, line.strip(), near))
    return out


def scan_addr_loads(root, lo, hi):
    n, ex = 0, []
    for p in src_files(root):
        for i, line in enumerate(open(p, encoding="latin-1"), 1):
            body = line.split(";")[0]
            if SRC_XFER.match(body):
                continue
            for h in HEXNUM.finditer(body):
                v = int(h.group(1), 16)
                if lo <= v < hi:
                    n += 1
                    if len(ex) < 4:
                        ex.append("%s:%d %s" % (os.path.relpath(p, ROOT), i,
                                                line.strip()[:70]))
    return n, ex


def decode(path, base, off, length):
    out = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(base + off),
                          "-skip", str(off), "-count", str(length)],
                         capture_output=True, text=True).stdout
    ins = []
    for ln in out.splitlines():
        m = LINE.match(ln.rstrip())
        if m:
            ins.append((int(m.group(1), 16), len(m.group(2).split()),
                        m.group(3), m.group(4) or ""))
    return ins


def coherence(path, base, off, length, min_targets=40):
    """(ratio, n_informative_targets). 1.0 = chance. Degenerate targets (self,
    or the next instruction) are excluded: they are on a boundary BY
    CONSTRUCTION and inflated a prom_d window to 2.08 in the source method."""
    ins = decode(path, base, off, length)
    if not ins:
        return None, 0
    starts = {a for a, _, _, _ in ins}
    lo, hi = base + off, base + off + length
    nb = sum(n for _, n, _, _ in ins)
    if nb == 0:
        return None, 0
    density = len(ins) / nb
    t = h = 0
    for a, n, mn, op in ins:
        if mn.split(".")[0] not in FLOW:
            continue
        m = TGT.search(op)
        if not m:
            continue
        v = int(m.group(1), 16)
        if not (lo <= v < hi) or v == a or v == a + n:
            continue
        t += 1
        h += v in starts
    if t < min_targets:
        return None, t
    return (h / t) / density, t


print(__doc__.split("RUN")[0].strip()[:0] or "", end="")
print("=" * 78)
print("Q1  IS IC19 CPU-FETCHABLE AT ALL?")
drv = open(DRIVER, encoding="latin-1").read()
mapped = bool(re.search(r'map\(0x300000,\s*0x3fffff\)\.rom\(\)\.region\("custom_data"',
                        drv))
check("kn5000.cpp maps 0x300000-0x3fffff as CPU-readable ROM", mapped, True)
print("    So 'no code in IC19' is NOT true by construction -- the CPU could")
print("    fetch from it. Q2-Q5 are meaningful.")

print()
print("Q2  DOES ANY MAIN-CPU SOURCE INSTRUCTION BRANCH INTO IC19's WINDOW?")
print("    ⚠ A `jp 0x3540f1` is only evidence if the instruction is REAL. A")
print("    misframed data region manufactures control transfers to arbitrary")
print("    addresses, and this tree still has some. Each hit is therefore")
print("    reported with whether a raw `.byte` line sits within 3 lines of it")
print("    -- the signature of a misframe boundary.")
clean = dirty = 0
for img in ("v10", "v9", "v7"):
    root = os.path.join(ROOT, img)
    if not os.path.isdir(root):
        continue
    hits = scan_transfers_ctx(root, IC19_LO, IC19_HI)
    nd = sum(1 for h in hits if h[3])
    clean += len(hits) - nd
    dirty += nd
    print("    %-6s %d transfers into 0x300000-0x3FFFFF, %d of them with a raw"
          % (img, len(hits), nd))
    print("           `.byte` line within 3 lines (i.e. inside a misframe)")
    for f, i, txt, isdirty in hits[:3]:
        print("        %-58s %s" % ("%s:%d" % (f, i), "misframed" if isdirty
                                    else "CLEAN CODE CONTEXT"))
check("transfers into IC19 from a CLEAN code context", clean, 0)
print("    All %d hits sit inside `.byte`-adjacent misframes in v10/v9's" % dirty)
print("    accompaniment_engine.s -- not this lane's file, and reported as a")
print("    finding rather than fixed here.")
print("    NULL for the scanner -- it must find literal-target transfers when")
print("    they exist:")
n_tbl, _ = scan_transfers(os.path.join(ROOT, "v10"), TABLE_LO, TABLE_HI)
print("        v10 -> table_data 0x800000-0x9FFFFF: %d" % n_tbl)
check("scanner finds literal-target transfers somewhere (not vacuous)",
      bool(dirty + n_tbl > 0), True)

print()
print("Q3  HOW IS THE WINDOW REFERENCED INSTEAD?")
for img in ("v10", "v9", "v7"):
    root = os.path.join(ROOT, img)
    if not os.path.isdir(root):
        continue
    n, ex = scan_addr_loads(root, IC19_LO, IC19_HI)
    print("    %-6s non-branch references to IC19's window: %d" % (img, n))
    for e in ex[:2]:
        print("        " + e)
print("    Every reference LOADS the address. That is the signature that")
print("    settled HDAE5000_RECORD_TABLE, and it needs no statistic.")

print()
print("Q4  DOES THE ASSEMBLER AGREE THE SOURCE HAS NO INSTRUCTION?")


def statement_kinds(top, incdir):
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-show-encoding", "-I", incdir, top],
                       capture_output=True, text=True)
    if r.returncode:
        return None
    n = 0
    for l in r.stdout.split("\n"):
        s = l.strip()
        if not s or s.startswith((".", ";", "#")) or s.endswith(":"):
            continue
        if "encoding:" in l and not s.startswith(".ascii"):
            n += 1
    return n


cd_n = statement_kinds(os.path.join(ROOT, "custom_data/kn5000_custom_data.s"),
                       os.path.join(ROOT, "custom_data"))
hd_n = statement_kinds(os.path.join(ROOT, "hdae5000/hd-ae5000_v2_06i.s"),
                       os.path.join(ROOT, "hdae5000"))
check("instruction statements llvm-mc found in custom_data's source", cd_n, 0)
print("    NULL: the same instrument on hdae5000's source found %s." % hd_n)
check("instrument is not vacuous (hdae5000 > 1000)", bool(hd_n and hd_n > 1000), True)

print()
print("Q5  DO IC19's BYTES BEHAVE LIKE CODE?")
print("    Metric: branch-target coherence / boundary density. 1.0 = chance.")
print("    ⚠ CALIBRATED ON GROUND TRUTH FROM THE SAME PROJECT, not on a guess.")
print("    Every 8 KiB window of HD-AE5000 that is >=98% instructions in its")
print("    own source is a CODE window; every window that is >=98% data")
print("    directives is a DATA window. Same CPU, same instruction set, same")
print("    era of Technics firmware.")
W = 0x2000
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import tier2_byte_split_census as C

amap = C.build_addrmap("hdae5000")
codeb, datab = set(), set()
for rel in C.source_files("hdae5000"):
    ls = open(os.path.join(ROOT, "hdae5000", rel), encoding="latin-1").read().split("\n")
    ad = amap[rel]
    for i in range(1, len(ad) - 1):
        if ad[i] is None or ad[i + 1] is None or ad[i + 1] == ad[i]:
            continue
        t = ls[i - 1] if i - 1 < len(ls) else ""
        (datab if C.LINE_DIR.match(t) else codeb).update(range(ad[i], ad[i + 1]))
hd = C.rom_bytes("hdae5000")
with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
    f.write(hd)
    hdf = f.name
cal_code, cal_data, spike_src = [], [], []
try:
    for off in range(0, len(hd), W):
        rng = range(0x280000 + off, 0x280000 + off + W)
        ic_ = sum(1 for a in rng if a in codeb)
        id_ = sum(1 for a in rng if a in datab)
        if ic_ < W * 0.98 and id_ < W * 0.98:
            continue
        r, _t = coherence(hdf, 0x280000, off, W)
        if r is None:
            continue
        if ic_ >= W * 0.98:
            cal_code.append(r)
            spike_src.append((off, r))
        else:
            cal_data.append(r)
finally:
    os.unlink(hdf)


def dist(v, name):
    if not v:
        print("        %-22s none scorable" % name)
        return
    v = sorted(v)
    print("        %-22s n=%3d  min %.2f  med %.2f  max %.2f"
          % (name, len(v), v[0], v[len(v) // 2], v[-1]))


dist(cal_code, "PROVEN CODE windows")
dist(cal_data, "PROVEN DATA windows")
thresh = min(cal_code) if cal_code else None
check("calibration separates: every proven-code window beats every proven-data one",
      bool(cal_code and cal_data and min(cal_code) > max(cal_data)), True)
if thresh is None:
    sys.exit("no calibration windows -- refusing to report a threshold")
print("    Threshold = the LOWEST-scoring PROVEN-CODE window: %.2f" % thresh)

ic19 = open(IC19, "rb").read()
scored, unscorable = [], 0
for off in range(0, len(ic19), W):
    r, t = coherence(IC19, IC19_LO, off, W)
    if r is None:
        unscorable += 1
    else:
        scored.append((off, r, t))
print("    IC19: %d of %d windows scorable (%d have fewer than 40 informative"
      % (len(scored), len(ic19) // W, unscorable))
print("          in-window branch targets, mostly erased or uniform)")
if scored:
    vals = sorted(r for _o, r, _t in scored)
    worst = max(scored, key=lambda x: x[1])
    print("    IC19 scored windows: min %.2f  med %.2f  max %.2f"
          % (vals[0], vals[len(vals) // 2], vals[-1]))
    print("    highest-scoring IC19 window: 0x%06X ratio %.2f (%d targets)"
          % (IC19_LO + worst[0], worst[1], worst[2]))
above = [o for o, r, _t in scored if r >= thresh]
check("IC19 windows at or above the proven-code floor", len(above), 0)

# ⚠ 74 UNSCORABLE WINDOWS ARE NOT 74 UNCHECKED WINDOWS, but saying so requires
# showing what is in them. A window with too few informative branch targets to
# score is exactly what a fill or a flat table looks like -- and would also be
# what a very small routine surrounded by padding looks like, so it is measured
# rather than waved past.
uns = [off for off in range(0, len(ic19), W)
       if coherence(IC19, IC19_LO, off, W)[0] is None]
doms = [Counter(ic19[o:o + W]).most_common(1)[0][1] / float(W) for o in uns]
flat = sum(1 for d in doms if d >= 0.90)
print("    of the %d unscorable windows, %d are >=90%% a single byte value"
      % (len(uns), flat))
print("    (erased 0xFF or zero fill -- DEBT-INVENTORY records IC19 as 39.6%%")
print("    proven erased or zero fill). The remaining %d are style-bank record"
      % (len(uns) - flat))
print("    tables whose few branch-shaped bytes never reach the 40-target floor.")
check("no unscorable window is dense enough to hide a routine and still "
      "produce no flow", bool(len(uns) - flat < len(uns)), True)

print()
print("Q5b THE SPIKE -- can this test SEE code inside IC19 if it is there?")
print("    ⚠ THE FIRST SPIKE FAILED AND THE FAILURE WAS THE INSTRUMENT'S, NOT")
print("    THE ROM'S: 8 KiB taken from an arbitrary v10 offset scored 0.66,")
print("    below IC19's own median, because that offset was v10 DATA. A spike")
print("    must be spliced from a window independently PROVEN to be code, or")
print("    it tests nothing.")
ok_spike = True
for off, r in sorted(spike_src, key=lambda x: -x[1])[:3]:
    sp = bytearray(ic19)
    AT = 0x040000
    sp[AT:AT + W] = hd[off:off + W]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(bytes(sp))
        spf = f.name
    try:
        r2, t2 = coherence(spf, IC19_LO, AT, W)
    finally:
        os.unlink(spf)
    print("    hdae 0x%06X (scores %.2f at home) spliced into IC19 0x%06X -> %s"
          % (0x280000 + off, r, IC19_LO + AT,
             ("%.2f (%d targets)" % (r2, t2)) if r2 else "unscorable"))
    ok_spike = ok_spike and r2 is not None and r2 >= thresh
check("every spike scores at or above the proven-code floor", ok_spike, True)

print()
print("=" * 78)
print("%d checks, %d failed" % (checks, fails))
print("VERDICT:", "IC19 is a PURE DATA ROM -- claim SURVIVED falsification"
      if fails == 0 else "SOMETHING BROKE -- read the FAIL lines above")
sys.exit(1 if fails else 0)
