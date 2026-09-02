#!/usr/bin/env python3
"""FALSIFICATION LANE -- can the "prom_d has ZERO bytes of assembly" claim, and
prom_c's "clean of data-as-code / code-as-data" verdict, be BROKEN?

WHAT QUESTION THIS ANSWERS
--------------------------
`scripts/analysis/kn5000_source_coverage.py` reports prom_d as 524,288 B of
typed data with **asm 0**, and prom_c as 207,546 B asm / 316,742 B typed, both
100% source; `notes/DEBT-INVENTORY-2026-09-02.md` records both as CLEAN.  The
failure mode that would make "asm 0" a LIE rather than a fact is the inverse of
this project's usual hazard: **code typed as DATA**.  A `.long` table that is
really a routine re-assembles to the same bytes, so the byte gate is blind to it
in that direction too -- and the push has already had a 68,934 B near-miss of
exactly that shape.

So this script does NOT re-run the coverage tool.  It attacks the claim:

  Q1  Is prom_d even CPU-fetchable?  (If it hung off a sound chip, "no code" is
      trivially true and there is nothing to test.)
  Q2  Does any ENTRY VECTOR point into it?
  Q3  Does any prom_c INSTRUCTION carry a literal in prom_d's window?
  Q4  Do prom_c's BYTES carry a pointer table into prom_d?  (Q3's stated limit
      in prom_d/prom_d.ld is that it is complete over instructions only.)
  Q5  Does the ASSEMBLER agree that prom_d's source contains no instruction?
  Q6  Do prom_d's BYTES BEHAVE like code?  -- the only test that can catch code
      that nobody framed, and the one with a real null.
  Q7  Is the "verified .fill filler" byte COUNT actually backed by the byte
      VALUES in the original dumps?

★ EVERY TEST CARRIES ITS NULL.  A criterion that cannot fail is not evidence.
  Q3 re-runs its scanner over two other windows and finds things there.
  Q4 compares prom_d's window against two windows with NO DEVICE in them.
  Q5's instrument is shown to return 76,647 rows for prom_c and 0 for prom_d.
  Q6 is calibrated on prom_c windows whose code/data status is GROUND TRUTH from
     Q5's map, and then Q6b SPIKES prom_d with real prom_c code and shows the
     test flags the spike -- i.e. the instrument can see the failure it reports
     the absence of.
  Q7 locates the `.fill` extents by REBUILDING with the fill values XORed 0xFF
     and diffing against the dump, so the extents are the assembler's and not a
     comment's.

⚠ WHICH DECODER IS ASKED.  Q6 -- the only test here that speaks about the ROM's
BYTES -- decodes with MAME's `unidasm`, the framing authority named in
original_ROMs/README-unidasm.md, and never asks the LLVM backend whether a byte
is an instruction.  That distinction is not pedantry: on 2026-09-02 this tree
retracted a conclusion built on a backend refusal (0x01/0x04/0x17/0x1a/0x1c have
no decode in tlcs900_backend and unidasm decodes all five as real instructions,
two of them control flow -- notes/DEBT-INVENTORY-2026-09-02.md).  `llvm-mc`
appears only in Q5 and Q7, and only against the SOURCE: Q5 counts how many
statements the assembler turned into instructions, Q7 rebuilds with the fill
values XORed.  Neither infers "data" from a refusal to decode.

USAGE
    python3 notes/prom_cd_falsification_2026_09_02.py            # all checks
    python3 notes/prom_cd_falsification_2026_09_02.py --quick    # skip Q6/Q7
    python3 notes/prom_cd_falsification_2026_09_02.py --verbose

Needs: MAME's unidasm at ~/compartilhado/mame/unidasm (the framing authority --
original_ROMs/README-unidasm.md), and the LLVM tlcs900 build the Makefile uses.
"""
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROMS = os.path.join(ROOT, "original_ROMs")
sys.path.insert(0, os.path.join(ROOT, "notes"))

HOME = os.path.expanduser("~")
UNIDASM = os.path.join(HOME, "compartilhado/mame/unidasm")
LLVM = os.path.join(HOME, "compartilhado/llvm-project/build/bin")
DRIVER = os.path.join(HOME, "compartilhado/kn7000_mame/src/mame/matsushita/wsa1.cpp")

PROM_C = os.path.join(ROMS, "wsa1_prom_c.ic28")
PROM_D = os.path.join(ROMS, "wsa1_prom_d.bin")
C_BASE = 0xF80000          # prom_c on CPU 2's bus
D_BASE = 0xF00000          # prom_d on CPU 2's bus (prom_d/prom_d.ld)

VERBOSE = "--verbose" in sys.argv
QUICK = "--quick" in sys.argv

fails = 0
checks = 0


def check(label, got, want):
    global fails, checks
    checks += 1
    ok = got == want
    if not ok:
        fails += 1
    if not ok or VERBOSE:
        print(f"    [{'ok' if ok else 'FAIL'}] {label}: {got!r}"
              + ("" if ok else f"  (expected {want!r})"))
    else:
        print(f"    [ok] {label}: {got!r}")


def note(text):
    print(f"    ... {text}")


c = open(PROM_C, "rb").read()
d = open(PROM_D, "rb").read()


# ---------------------------------------------------------------------------
print()
print("Q1  IS prom_d CPU-FETCHABLE AT ALL?")
print("    If it were a wave ROM on a sound chip's own bus, 'no code' would be")
print("    true by construction and Q2-Q6 would be pointless.  It is not.")
drv = open(DRIVER, encoding="utf-8", errors="replace").read()
m = re.search(r'map\(0xf00000, 0xf7ffff\)\.rom\(\)\.region\("prom_d", 0\)', drv)
check("wsa1.cpp maps prom_d into CPU 2's PROGRAM space as ROM", bool(m), True)
# and the base is not the driver's own reading -- it is prom_c's, from bytes.
check("prom_c 0xFB051E is `ld XBC,0x00F00000` (41 00 00 f0 00)",
      c[0xFB051E - C_BASE:0xFB051E - C_BASE + 5].hex(" "), "41 00 00 f0 00")
note("So prom_d sits in the SAME address space the CPU fetches prom_c from.")
note("The zero-assembly claim is therefore a real claim, not a tautology.")


# ---------------------------------------------------------------------------
print()
print("Q2  DOES ANY ENTRY VECTOR POINT INTO prom_d?")
vec = [struct.unpack_from("<I", c, 0x7FF00 + 4 * i)[0] for i in range(33)]
in_d = [v for v in vec if D_BASE <= v <= D_BASE + 0x7FFFF]
in_c = [v for v in vec if C_BASE <= v <= C_BASE + 0x7FFFF]
check("prom_c vectors (33, incl. RESET at 0xFFFF00) landing in prom_d", len(in_d), 0)
check("NULL -- the same 33 vectors landing in prom_c itself", len(in_c), 33)
check("RESET vector", hex(vec[0]), "0xfff000")
# prom_d's own tail is not a vector table either
words = [struct.unpack_from("<I", d, 0x7FF00 + 4 * i)[0] for i in range(64)]
check("words at prom_d 0x7FF00 that are 0xFFFFFFFF (erased, not vectors)",
      sum(1 for w in words if w == 0xFFFFFFFF), 60)
check("prom_d 0x7FFF0 is the build tag, not a vector",
      d[0x7FFF0:0x7FFFB].decode("latin-1"), "wsad_54.ssf")


# ---------------------------------------------------------------------------
print()
print("Q3  DOES ANY prom_c INSTRUCTION CARRY A LITERAL IN prom_d's WINDOW?")
print("    Over the CERTIFIED source, not a linear decode of the ROM: ranking a")
print("    linear decode of data is this project's documented failure mode.")
from asm_source import image_lines           # noqa: E402

lines = image_lines(ROOT, "prom_c/wsa1_prom_c.s")
HEX = re.compile(r'0x([0-9A-Fa-f]{4,8})')
LABEL = re.compile(r'^\s*[A-Za-z_.$][A-Za-z0-9_.$]*:')


def instruction_literals(lines):
    """Every numeric literal on a line the assembler turns into an INSTRUCTION."""
    out = []
    for ln in lines:
        body = ln.split(";")[0]
        if not body.strip():
            continue
        if LABEL.match(body):
            body = body.split(":", 1)[1]
        s = body.strip()
        if not s or s.startswith("."):       # directive => typed data, not code
            continue
        for h in HEX.finditer(s):
            out.append(int(h.group(1), 16))
    return out


lits = instruction_literals(lines)
wins = {
    "prom_d  0xF00000-0xF7FFFF": (0xF00000, 0xF7FFFF),
    "flash   0xE80000-0xEFFFFF": (0xE80000, 0xEFFFFF),
    "prom_c  0xF80000-0xFFFFFF": (0xF80000, 0xFFFFFF),
}
counts = {k: sum(1 for v in lits if lo <= v <= hi) for k, (lo, hi) in wins.items()}
note(f"prom_c instruction literals scanned: {len(lits)}")
check("literals in prom_d's window", counts["prom_d  0xF00000-0xF7FFFF"], 1)
note("and that ONE is the base itself, 0x00F00000 at 0xFB051E (Q1).")
check("NULL -- the same scanner over the flash window finds some",
      counts["flash   0xE80000-0xEFFFFF"] > 5, True)
check("NULL -- and over prom_c's own window finds many",
      counts["prom_c  0xF80000-0xFFFFFF"] > 1000, True)
if VERBOSE:
    for k in wins:
        print(f"        {k}: {counts[k]}")


# ---------------------------------------------------------------------------
print()
print("Q4  DO prom_c's BYTES CARRY A POINTER TABLE INTO prom_d?")
print("    prom_d/prom_d.ld states Q3's limit outright: the search is complete")
print("    over prom_c's INSTRUCTIONS and not over its DATA.  This closes it.")


def le32_hits(buf, lo, hi):
    n = 0
    for i in range(len(buf) - 3):
        v = buf[i] | buf[i + 1] << 8 | buf[i + 2] << 16 | buf[i + 3] << 24
        if lo <= v <= hi:
            n += 1
    return n


ptr = {
    "prom_d  0xF00000 (512K, mapped)": le32_hits(c, 0xF00000, 0xF7FFFF),
    "NULL-A  0xD00000 (512K, NO DEVICE)": le32_hits(c, 0xD00000, 0xD7FFFF),
    "NULL-B  0xE00000 (512K, NO ROM)": le32_hits(c, 0xE00000, 0xE7FFFF),
    "POS     0xF80000 (512K, prom_c itself)": le32_hits(c, 0xF80000, 0xFFFFFF),
}
for k, v in ptr.items():
    note(f"{k}: {v} LE32 words, any alignment")
check("prom_c's own window is ENRICHED over the empty windows (the scanner works)",
      ptr["POS     0xF80000 (512K, prom_c itself)"] >
      2 * max(ptr["NULL-A  0xD00000 (512K, NO DEVICE)"],
              ptr["NULL-B  0xE00000 (512K, NO ROM)"]), True)
check("prom_d's window is NOT enriched -- it sits inside the empty-window band",
      ptr["prom_d  0xF00000 (512K, mapped)"] <=
      max(ptr["NULL-A  0xD00000 (512K, NO DEVICE)"],
          ptr["NULL-B  0xE00000 (512K, NO ROM)"]), True)
note("A jump table into prom_d would have to be a pile of such words.  There is")
note("no pile: the count is indistinguishable from address-space noise.")
note("⚠ THAT COMPARISON IS NOT PERFECTLY MATCHED -- the four windows need"
     " different high bytes and prom_c does not contain them equally often.")
note("So here is the sharp form of the same question: a jump table is not a")
note("SCATTER of pointers, it is a RUN of CONSECUTIVE aligned ones.")


def longest_ptr_run(buf, lo, hi, align=4):
    best, at = 0, None
    for phase in range(align):
        run = 0
        for i in range(phase, len(buf) - 3, align):
            v = buf[i] | buf[i+1] << 8 | buf[i+2] << 16 | buf[i+3] << 24
            if lo <= v <= hi:
                run += 1
                if run > best:
                    best, at = run, i - align * (run - 1)
            else:
                run = 0
    return best, at


runs = {}
for k, (lo, hi) in (("prom_d  0xF00000", (0xF00000, 0xF7FFFF)),
                    ("NULL-A  0xD00000", (0xD00000, 0xD7FFFF)),
                    ("NULL-B  0xE00000", (0xE00000, 0xE7FFFF)),
                    ("POS     0xF80000", (0xF80000, 0xFFFFFF))):
    n, at = longest_ptr_run(c, lo, hi)
    runs[k] = n
    note(f"{k}: longest run of consecutive 4-aligned pointers = {n}"
         + (f" (at file 0x{at:05X})" if at is not None else ""))
check("prom_c really does contain a pointer TABLE into itself",
      runs["POS     0xF80000"], 81)
check("into prom_d, the longest run is the same as into an empty window",
      runs["prom_d  0xF00000"] == runs["NULL-A  0xD00000"] ==
      runs["NULL-B  0xE00000"] == 2, True)


# ---------------------------------------------------------------------------
print()
print("Q5  DOES THE ASSEMBLER AGREE prom_d's SOURCE HAS NO INSTRUCTION?")
print("    llvm-mc -g emits a DWARF line row per INSTRUCTION statement and none")
print("    for a data directive, so the row count is an assembler-side census")
print("    that does not read the .s text at all.")
tmp = tempfile.mkdtemp(prefix="promd_falsify_")


def dwarf_rows(image):
    obj = os.path.join(tmp, f"{image}_g.o")
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                    "-filetype=obj", "-g", "-I", ".", "-I", image,
                    "-o", obj, f"{image}/wsa1_{image}.s"],
                   cwd=ROOT, capture_output=True, text=True, check=True)
    out = subprocess.run([os.path.join(LLVM, "llvm-dwarfdump"), "--debug-line", obj],
                         capture_output=True, text=True).stdout
    rows, end = set(), None
    for ln in out.splitlines():
        m = re.match(r"^0x([0-9a-f]{16})\s+\d+", ln)
        if m:
            a = int(m.group(1), 16)
            if "end_sequence" in ln:
                end = a
            else:
                rows.add(a)
    return sorted(rows), end


d_rows, d_end = dwarf_rows("prom_d")
c_rows, c_end = dwarf_rows("prom_c")
check("prom_d instruction statements", len(d_rows), 0)
check("NULL -- prom_c instruction statements (the instrument is not dead)",
      len(c_rows), 76647)
# ⚠ the line-table address axis omits the bytes before the FIRST instruction,
# so it is offset by exactly that; recover the shift from the section size.
shift = 0x80000 - c_end
check("prom_c's first instruction is at file 0x18000 (= 0xF98000)", hex(shift), "0x18000")
check("and the bytes there are `link XIZ,0xfff8` (ee 0c f8 ff)",
      c[0x18000:0x18004].hex(" "), "ee 0c f8 ff")
C_STARTS = sorted(a + shift for a in c_rows)
deltas = Counter(C_STARTS[i + 1] - C_STARTS[i] for i in range(len(C_STARTS) - 1))
check("consecutive-start deltas of 1..7 bytes (i.e. real instruction lengths)",
      sum(v for k, v in deltas.items() if 1 <= k <= 7) > 0.99 * (len(C_STARTS) - 1), True)
note("⚠ WHAT Q5 DOES NOT SHOW: that the BYTES are not code.  It shows only that")
note("nobody wrote an instruction in prom_d's source.  Q6 is the one that can")
note("catch code that was framed as data.")


# ---------------------------------------------------------------------------
LINE = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(\S+)(?:\s+(.*))?$")
TGT = re.compile(r"0x([0-9a-f]{4,8})")
FLOW = {"jr", "jrl", "jp", "call", "calr", "djnz"}


def decode(path, base, off, length):
    out = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(base),
                          "-skip", str(off), "-count", str(length)],
                         capture_output=True, text=True).stdout
    ins = []
    for ln in out.splitlines():
        m = LINE.match(ln.rstrip())
        if m:
            ins.append((int(m.group(1), 16), len(m.group(2).split()),
                        m.group(3), m.group(4) or ""))
    return ins


def flow_enrichment(path, base, off, length, min_targets=60):
    """How much likelier is a branch target to be an instruction BOUNDARY than
    chance?  1.0 = chance.  Real code lands on its own boundaries; a linear
    decode of data lands on them only as often as boundaries are dense.

    ⚠ DEGENERATE TARGETS ARE EXCLUDED -- a branch to its own address or to the
    instruction that follows it is on a boundary BY CONSTRUCTION and carries no
    information.  This is not a cosmetic filter.  Without it prom_d 0x1F000
    scored 2.08 and crossed the threshold, and all 47 of its "coherent" targets
    were the same thing: `jr +2` into the next instruction, thrown up 47 times
    by one repeated byte pair in a table of 43-byte mixer records.  With the
    filter that window has ZERO informative targets, which is the honest answer.

    Returns (ratio, n_targets) or (None, n) when there is too little flow.
    """
    ins = decode(path, base + off, off, length)
    if not ins:
        return None, 0
    starts = {a for a, _, _, _ in ins}
    lo, hi = base + off, base + off + length
    nbytes = sum(n for _, n, _, _ in ins)
    density = len(ins) / nbytes                      # P(hit a boundary by chance)
    tgts = hits = 0
    for a, n, mn, op in ins:
        if mn.split(".")[0] not in FLOW:
            continue
        m = TGT.search(op)
        if not m:
            continue
        t = int(m.group(1), 16)
        if not (lo <= t < hi):
            continue
        if t == a or t == a + n:          # self-loop / fall-through: no information
            continue
        tgts += 1
        hits += t in starts
    if tgts < min_targets:
        return None, tgts
    return (hits / tgts) / density, tgts


if not QUICK:
    print()
    print("Q6  DO prom_d's BYTES BEHAVE LIKE CODE?")
    print("    Metric: branch-target coherence, NORMALISED BY BOUNDARY DENSITY.")
    print("    Raw 'target lands on a boundary' does NOT separate -- data decodes")
    print("    to ~1.45 B/instruction, so a random target hits a boundary ~69% of")
    print("    the time.  Dividing by the density is what makes the test honest.")
    W = 0x2000

    def controls(win, min_t):
        """The two control populations, at window size `win`.  GROUND TRUTH for
        which prom_c window is code and which is data comes from Q5's assembler
        map, not from a comment in the source."""
        cc, cd = [], []
        for off in range(0, 0x80000, win):
            n = sum(1 for a in C_STARTS if off <= a < off + win)
            r, t = flow_enrichment(PROM_C, C_BASE, off, win, min_t)
            if r is None:
                continue
            if n >= 0.30 * win:
                cc.append((off, r, t))
            elif n == 0:
                cd.append((off, r, t))
        return cc, cd

    ctrl_code, ctrl_data = controls(W, 60)
    code_r = [r for _, r, _ in ctrl_code]
    data_r = [r for _, r, _ in ctrl_data]
    note(f"prom_c CODE windows (>=0.30 instruction starts/byte): {len(ctrl_code)}"
         f"  enrichment min {min(code_r):.2f} median {sorted(code_r)[len(code_r)//2]:.2f}"
         f" max {max(code_r):.2f}")
    note(f"prom_c DATA windows (ZERO instruction starts):        {len(ctrl_data)}"
         f"  enrichment min {min(data_r):.2f} median {sorted(data_r)[len(data_r)//2]:.2f}"
         f" max {max(data_r):.2f}")
    check("the two control populations SEPARATE (min code > max data)",
          min(code_r) > max(data_r), True)
    THRESH = (min(code_r) + max(data_r)) / 2
    note(f"decision threshold, set by the controls alone: {THRESH:.2f}")

    d_win, d_unscored = [], []
    for off in range(0, 0x50B09, W):           # everything before the erased tail
        r, t = flow_enrichment(PROM_D, D_BASE, off, min(W, 0x50B09 - off))
        if r is None:
            d_unscored.append((off, t))
        else:
            d_win.append((off, r, t))
    note(f"⚠ COVERAGE: {len(d_win)} of {len(d_win)+len(d_unscored)} windows had"
         f" enough informative targets to score.  Unscored:"
         f" {[(hex(o), t) for o, t in d_unscored]}")
    note("An unscored window is not a pass -- it is a window this test cannot")
    note("speak about.  Q6e rescans the image at 2 KiB, and the unscored set")
    note("there is listed too.")
    dr = [r for _, r, _ in d_win]
    note(f"prom_d windows scored: {len(d_win)}"
         f"  enrichment min {min(dr):.2f} median {sorted(dr)[len(dr)//2]:.2f}"
         f" max {max(dr):.2f}")
    over = [(hex(o), round(r, 2)) for o, r, _ in d_win if r >= THRESH]
    check("prom_d windows scoring at or above the threshold", over, [])
    top = sorted(d_win, key=lambda x: -x[1])[:3]
    for o, r, t in top:
        note(f"prom_d's most code-like window: 0x{o:05X} at {r:.2f} ({t} targets)")
    check("even prom_d's BEST window is below the weakest prom_c CODE window",
          max(dr) < min(code_r), True)
    note(f"margin: {min(code_r) - max(dr):.2f} of enrichment, with the whole data")
    note("control population sitting between them.  No prom_d window is close.")

    print()
    print("Q6c THE OTHER DIRECTION -- is what prom_c FRAMES AS CODE really code?")
    print("     Q6 attacks 'code typed as data'.  This attacks the project's usual")
    print("     hazard, 'data disassembled as code', and it uses the CERTIFIED")
    print("     framing (Q5's DWARF starts) as the boundary set rather than a")
    print("     linear sweep.  A data table framed as instructions would score in")
    print("     the DATA band above, because its branch targets are arbitrary.")
    framed = []
    for off in range(0, 0x80000, W):
        win = [a for a in C_STARTS if off <= a < off + W]
        if len(win) < 100:
            continue
        S = set(win)
        ins = decode(PROM_C, C_BASE + win[0], win[0], off + W - win[0])
        ins = [x for x in ins if x[0] - C_BASE in S]      # certified framing only
        if not ins:
            continue
        density = len(S) / W
        lo, hi = C_BASE + off, C_BASE + off + W
        tgts = hits = 0
        for a, n, mn, op in ins:
            if mn.split(".")[0] not in FLOW:
                continue
            m = TGT.search(op)
            if not m:
                continue
            t = int(m.group(1), 16)
            if not (lo <= t < hi):
                continue
            if t == a or t == a + n:
                continue
            tgts += 1
            hits += (t - C_BASE) in S
        if tgts >= 60:
            framed.append((off, (hits / tgts) / density, tgts))
    fr = [r for _, r, _ in framed]
    note(f"prom_c windows framed as code and scorable: {len(framed)}"
         f"  enrichment min {min(fr):.2f} median {sorted(fr)[len(fr)//2]:.2f}"
         f" max {max(fr):.2f}")
    worst = sorted(framed, key=lambda x: x[1])[:3]
    for o, r, t in worst:
        note(f"weakest: 0x{o:05X} at {r:.2f} ({t} targets)")
    check("every code-framed prom_c window scores in the CODE band, none in DATA's",
          [hex(o) for o, r, _ in framed if r <= max(data_r)], [])

    print()
    print("Q6b THE SPIKE -- can this test SEE code inside prom_d if it is there?")
    print("     A criterion that cannot fail is not a pass.  Splice a real prom_c")
    print("     routine into prom_d and re-score the window it landed in.")
    spike_src = 0x18000                        # prom_c's first code, from Q5
    caught = 0
    for spike_at in (0x08000, 0x20000, 0x40000):
        buf = bytearray(d)
        buf[spike_at:spike_at + W] = c[spike_src:spike_src + W]
        p = os.path.join(tmp, "spiked.bin")
        open(p, "wb").write(buf)
        r, t = flow_enrichment(p, D_BASE, spike_at, W)
        base_r = dict((o, rr) for o, rr, _ in d_win)[spike_at]
        note(f"prom_d 0x{spike_at:05X}: as dumped {base_r:.2f}"
             f"  -> with 8 KiB of prom_c code spliced in {r:.2f}")
        caught += r >= THRESH
    check("every spiked window is flagged (the instrument can see the failure)",
          caught, 3)

    print()
    print("Q6d HOW SMALL A ROUTINE WOULD THIS TEST STILL SEE?")
    print("     The honest statement of the instrument's reach.  Shrink the spike")
    print("     until the window stops crossing the threshold.")
    MIN_T = {0x2000: 60, 0x800: 25}
    floors = {}
    for win in (0x2000, 0x800):
        floor = None
        for n in (win, win // 2, win // 4, win // 8):
            buf = bytearray(d)
            buf[0x20000:0x20000 + n] = c[spike_src:spike_src + n]
            p_ = os.path.join(tmp, "spiked.bin")
            open(p_, "wb").write(buf)
            r, t = flow_enrichment(p_, D_BASE, 0x20000, win, MIN_T[win])
            note(f"{n:5d} B of real code in a {win} B window -> {r:.2f}"
                 f"  {'FLAGGED' if r >= THRESH else 'missed'}")
            if r >= THRESH:
                floor = n
        floors[win] = floor
    check("smallest spike flagged in an 8 KiB window", floors[0x2000], 0x2000)
    check("smallest spike flagged in a 2 KiB window", floors[0x800], 0x800)
    note("★ THE HONEST REACH: the test needs the window to be MOSTLY code, so the")
    note("smallest routine it can catch is about one window.  Q6e therefore")
    note("rescans at 2 KiB, and the claim this lane is entitled to is: a")
    note("CONTIGUOUS routine of ~2 KiB or more, anywhere in prom_d, would have")
    note("been flagged, and none was.  A shorter one would not be -- a 512-byte")
    note("routine buried in a tone table is BELOW this instrument.")

    print()
    print("Q6e AND AT A FINER GRAIN -- rescan prom_d in 2 KiB windows")
    cc2, cd2 = controls(0x800, 25)
    c2 = [r for _, r, _ in cc2]
    d2 = [r for _, r, _ in cd2]
    note(f"prom_c CODE windows at 2 KiB: {len(cc2)}  min {min(c2):.2f}"
         f" median {sorted(c2)[len(c2)//2]:.2f} max {max(c2):.2f}")
    note(f"prom_c DATA windows at 2 KiB: {len(cd2)}  min {min(d2):.2f}"
         f" median {sorted(d2)[len(d2)//2]:.2f} max {max(d2):.2f}")
    check("the controls still separate at this window size", min(c2) > max(d2), True)
    T2 = (min(c2) + max(d2)) / 2
    note(f"threshold at 2 KiB, from these controls alone: {T2:.2f}")
    fine = []
    for off in range(0, 0x50B09, 0x800):
        r, t = flow_enrichment(PROM_D, D_BASE, off, min(0x800, 0x50B09 - off), 25)
        if r is not None:
            fine.append((off, r, t))
    frr = [r for _, r, _ in fine]
    unscored2 = [hex(o) for o in range(0, 0x50B09, 0x800)
                 if o not in {x[0] for x in fine}]

    note(f"prom_d windows scorable at 2 KiB (>=25 informative targets): {len(fine)}"
         f" of {(0x50B09 + 0x7FF)//0x800}"
         f"  min {min(frr):.2f} median {sorted(frr)[len(frr)//2]:.2f} max {max(frr):.2f}")
    check("2 KiB windows of prom_d at or above the 2 KiB threshold",
          [(hex(o), round(r, 2)) for o, r, _ in fine if r >= T2], [])
    note(f"⚠ {len(unscored2)} of {(0x50B09 + 0x7FF)//0x800} 2 KiB windows were"
         f" unscorable.  Most sit inside an 8 KiB window Q6 DID score, but three")
    note("8 KiB windows were unscorable too, and those 24 KiB are not covered by")
    note("the enrichment test at any grain.  So they get their own argument.")
    scored8 = {o for o, _, _ in d_win}
    orphan = sorted({int(u, 16) - (int(u, 16) % W) for u in unscored2} - scored8)
    check("prom_d bytes no enrichment score speaks for",
          [hex(o) for o in orphan], ["0x26000", "0x28000", "0x2a000"])

    print()
    print("Q6f THE THREE WINDOWS THE ENRICHMENT TEST CANNOT SCORE")
    print("     They are unscorable because their linear decode contains almost")
    print("     no informative branches -- and THAT is itself a discriminator:")
    print("     code is dense in branches, a table of curve points is not.")
    print("     (0x22D3B..0x2B2AB is ToneDB_EnvDescTable, 34,161 B of 112-byte")
    print("      CurveStepToElem arrays -- see prom_d/tone_database_aux.s.)")
    dens_code = sorted(t for _, _, t in ctrl_code)
    dens_data = sorted(t for _, _, t in ctrl_data)
    note(f"informative targets per 8 KiB -- prom_c CODE windows: min {dens_code[0]}"
         f" median {dens_code[len(dens_code)//2]} max {dens_code[-1]}")
    note(f"informative targets per 8 KiB -- prom_c DATA windows: min {dens_data[0]}"
         f" median {dens_data[len(dens_data)//2]} max {dens_data[-1]}")
    orphan_t = dict(d_unscored)
    for o in orphan:
        note(f"prom_d 0x{o:05X}: {orphan_t[o]} informative targets")
    check("each orphan window has fewer branches than ANY prom_c code window",
          all(orphan_t[o] < dens_code[0] for o in orphan), True)
    note("⚠ STATED AS A LIMIT, NOT A PROOF: this says those 24 KiB do not look")
    note("like the code in prom_c.  It is weaker than the enrichment test, and a")
    note("branch-free straight-line routine would evade it.  That is the one")
    note("region of prom_d this lane leaves less than fully attacked.")


# ---------------------------------------------------------------------------
if not QUICK:
    print()
    print("Q7  IS THE '.fill filler' BYTE COUNT BACKED BY THE BYTE VALUES?")
    print("     A byte COUNT standing in for byte VALUES has been a defect in")
    print("     this tree before.  The extents below are the ASSEMBLER'S: each")
    print("     image is rebuilt with every `.fill` value XORed 0xFF and diffed")
    print("     against the dump, so a fill is exactly where the bytes changed.")
    work = os.path.join(tmp, "mk")
    os.makedirs(work)
    for part in ("prom_c", "prom_d", "include", "kernel", "dsp", "maincpu"):
        src = os.path.join(ROOT, part)
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(work, part))
    FILL = re.compile(r"^(\s*\.fill\s+)(0x[0-9A-Fa-f]+|\d+)(\s*,\s*)(1)(\s*,\s*)"
                      r"(0x[0-9A-Fa-f]+|\d+)(.*)$")
    patched = 0
    for dirpath, _, names in os.walk(work):
        for nm in names:
            if not nm.endswith(".s"):
                continue
            p = os.path.join(dirpath, nm)
            src = open(p, encoding="latin-1").read().split("\n")     # ⚠ latin-1
            hit = False
            for i, ln in enumerate(src):
                m = FILL.match(ln)
                if m:
                    v = int(m.group(6), 0)
                    src[i] = (m.group(1) + m.group(2) + m.group(3) + m.group(4)
                              + m.group(5) + hex(v ^ 0xFF) + m.group(7))
                    hit = True
                    patched += 1
            if hit:
                open(p, "w", encoding="latin-1").write("\n".join(src))
    check("`.fill <n>,1,<v>` directives found across prom_c + prom_d", patched, 6)

    extents = {}
    for img, orig in (("prom_c", c), ("prom_d", d)):
        o = os.path.join(tmp, f"{img}.o")
        e = os.path.join(tmp, f"{img}.elf")
        b = os.path.join(tmp, f"{img}.rom")
        subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-filetype=obj", "-I", ".", "-I", img, "-o", o,
                        f"{img}/wsa1_{img}.s"], cwd=work, capture_output=True, check=True)
        subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                        f"{img}/{img}.ld", "-o", e, o], cwd=work,
                       capture_output=True, check=True)
        subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b],
                       capture_output=True, check=True)
        mk = open(b, "rb").read()
        check(f"{img}: marker build is the same size as the dump", len(mk), len(orig))
        diff = [i for i in range(len(orig)) if orig[i] != mk[i]]
        runs, s, prev = [], diff[0], diff[0]
        for i in diff[1:]:
            if i != prev + 1:
                runs.append((s, prev))
                s = i
            prev = i
        runs.append((s, prev))
        extents[img] = runs
        for a, b_ in runs:
            vals = set(orig[a:b_ + 1])
            note(f"{img} .fill 0x{a:05X}..0x{b_:05X}  {b_-a+1} B  value(s) "
                 f"{sorted(hex(v) for v in vals)}")
            check(f"{img} 0x{a:05X}: the dump is ONE value end to end", len(vals), 1)
            check(f"{img} 0x{a:05X}: and the marker is its XOR 0xFF everywhere",
                  all(orig[i] ^ mk[i] == 0xFF for i in range(a, b_ + 1)), True)
        check(f"{img}: every byte that changed is inside a `.fill`",
              sum(b_ - a + 1 for a, b_ in runs), len(diff))
        # ⚠ a `.fill` may be a SUBSET of a longer natural run -- prom_c's 480-byte
        # zero pad sits inside a 482-byte run, and the 118,298-byte 0x0E run starts
        # one byte after the `ret` that ends the code.  Contained, never straddling.
        for a, b_ in runs:
            lo = a
            while lo > 0 and orig[lo - 1] == orig[a]:
                lo -= 1
            hi = b_
            while hi + 1 < len(orig) and orig[hi + 1] == orig[a]:
                hi += 1
            check(f"{img} 0x{a:05X}: lies inside the dump's maximal run "
                  f"0x{lo:05X}..0x{hi:05X}", (lo <= a and b_ <= hi), True)

    check("prom_c filler total (claimed 129,216)",
          sum(b_ - a + 1 for a, b_ in extents["prom_c"]), 129216)
    check("prom_d filler total (claimed 193,767)",
          sum(b_ - a + 1 for a, b_ in extents["prom_d"]), 193767)
    check("prom_d's filler is ONE run, 0xFF, and the tail of the image",
          [(hex(a), hex(b_), hex(d[a])) for a, b_ in extents["prom_d"]],
          [("0x50b09", "0x7ffef", "0xff")])
    # and it really is the only big uniform run in prom_d
    big, i = [], 0
    while i < len(d):
        j = i
        while j + 1 < len(d) and d[j + 1] == d[i]:
            j += 1
        if j - i + 1 >= 0x1000:
            big.append((i, j - i + 1, d[i]))
        i = j + 1
    check("uniform runs >= 4096 B anywhere in prom_d", big, [(0x50B09, 0x2F4E7, 0xFF)])

shutil.rmtree(tmp, ignore_errors=True)
print()
print(f"CHECKS: {checks}    FAILURES: {fails}")
sys.exit(1 if fails else 0)
