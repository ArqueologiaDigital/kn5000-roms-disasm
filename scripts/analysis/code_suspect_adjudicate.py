#!/usr/bin/env python3
r"""IS A CONTROL TRANSFER INTO A DATA REGION REAL, OR A PHANTOM?

QUESTION THIS ANSWERS
---------------------
`notes/DATA-CENSUS-2026-09-02.md` §6 flags "code-suspect" data: a label heading
a DATA region is the operand of a `call`/`calr`/`jp`/`jr`/`jrl`/`djnz`
elsewhere in the tree.  `code_suspect_sites.py` enumerates those sites.  This
script GRADES each one, because a reference is not automatically real:
`notes/DEBT-INVENTORY-2026-09-02.md` records a lane proving that all 13
apparent control transfers into IC19 were phantoms manufactured by a misframe.

FOUR TESTS PER SITE
-------------------
1. REFERRER QUALITY -- `refrun` and `rd`.  `refrun` is how many CONSECUTIVE
   instruction lines the referring transfer sits inside.  The IC19 phantoms
   were transfers on an ISLAND of a few apparent instructions floating between
   `.byte` runs; a transfer in the middle of a fifty-instruction routine is not
   that shape.  `rd` (lines to the nearest byte-emitting directive) is reported
   too but is NOT a discriminator on its own -- in v7 almost every file is
   peppered with `.byte`, so a small `rd` is the norm, not a warning.

2. ADDRESS GUARD.  The label's address comes from the SYMBOL TABLE of the real
   linked image (`rebuilt_ROMs/*.llvm.elf`), not from a cached map, and the ROM
   bytes at that address are asserted equal to the bytes the source line itself
   states.  The lane brief records 13 conversions reverted because a stale
   address map pointed at different bytes than the source claimed; this is that
   guard.  A site failing it is REFUSED, not reported.

3. DECODE FROM AN ESTABLISHED ALIGNMENT.  A misaligned TLCS-900 decode
   RESYNCHRONISES within a few instructions, so "it decodes" proves nothing
   about where it started -- unless the start is not in question.  Here it is
   not: it is a branch target address forced by the ROM.  `ends_exact` says the
   decode consumes the region to its last byte.  HONEST LIMIT: `convert_block`
   is handed exactly the region's bytes and cannot overrun, so under `allclean`
   this column is SUBSUMED and adds nothing (measured: 0 regions are clean but
   not ends-exact).  It only catches a region that decodes for a while and then
   leaves an undecodable tail.  The independent endpoint evidence is test 1
   plus `v7_call_target_boundary_audit.py`, not this column.

4. ROUND-TRIP.  Every decoded instruction is re-assembled ALONE with llvm-mc
   `--show-encoding` and must reproduce its own bytes at its own position
   (`convert_code_bytes.convert_block`, the project's established method).
   `rt%` is the fraction of the region's bytes that survive that.

   NULL FOR TESTS 3+4, measured by `--randomctl`: uniformly random bytes at the
   same length distribution decode-and-round-trip fully clean **0.8%** of the
   time (1/120, lengths 8..256, seed 90902), and satisfy the endpoint test
   alone 24.2% -- which reproduces the architecture's known ~24% base rate from
   `scripts/analysis/blind_run_decode_census.py`.  So "clean" is strong and
   "ends exactly" alone is nearly free.

THE NULL FOR THE FLAG ITSELF -- AND WHY THE OBVIOUS ONE IS WORTHLESS
--------------------------------------------------------------------
The three pure-data images (`table_data`, `custom_data`, `prom_d`) score 0
hits, and that is ZERO BY CONSTRUCTION: they contain no instruction statements
at all, so no control transfer can exist to be counted.  That is exactly the
defect that got the "46x undecodable-leading-byte" finding retracted -- a
control rate pinned at zero by the structure of the test.  It is NOT quoted as
this flag's null.

The null used instead lives INSIDE the same three code-bearing images and is
certified by an authority independent of every decoder and every framing
judgement: regions emitted by `.incbin` of a `.bin` that the project's own
Makefile produces by compiling a `.c` file with `clang -target tlcs900`.  Those
bytes are data because a C compiler emitted them.

    labels heading a data run, v7+v9+v10        23,003   ctrl-targeted 484 (2.10%)
    NULL: C-compiled .incbin regions            11,179   ctrl-targeted   0 (0.00%)
    v7 literal .byte/.word runs                  7,035   ctrl-targeted 403 (5.73%)

ONE CONFOUND ON THAT ZERO, MEASURED NOT ASSUMED.  You cannot write a label
INSIDE an `.incbin`, so a transfer into the middle of a C-compiled blob could
only be spelled numerically and would escape a symbolic count.  `--null`
therefore also resolves every NUMERIC control transfer in the three images
against the C-compiled address ranges: 711 numeric transfers, 0 land inside one.

RUN
    python3 scripts/analysis/code_suspect_adjudicate.py --null
    python3 scripts/analysis/code_suspect_adjudicate.py v7
    python3 scripts/analysis/code_suspect_adjudicate.py v7 --min 32
    python3 scripts/analysis/code_suspect_adjudicate.py --randomctl 120 \
            --sizes 8,16,24,32,48,64,96,128,192,256

PREREQUISITE
    make rebuilt_ROMs/kn5000_v7_program.llvm.rom       # and v9 / v10
(the ELF beside it is what supplies the addresses)

TOOLCHAIN.  Decoding and round-tripping depend on the SHARED, MUTABLE llvm
build.  State the commit beside any number taken from a grade run:
    cd ~/compartilhado/llvm-project && git log -1 --format="%h"
This lane's figures were taken at tlcs900_backend@6f456a19f05b.
"""
import bisect
import json
import os
import random
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
import code_suspect_sites as C          # noqa: E402
import convert_code_bytes as CCB        # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")

IMG = {
    "v7":  dict(mirror="v7/maincpu",  base=0xE00000,
                elf="rebuilt_ROMs/kn5000_v7_program.llvm.elf",
                rom="original_ROMs/kn5000_v7_program.rom"),
    "v9":  dict(mirror="v9/maincpu",  base=0xE00000,
                elf="rebuilt_ROMs/kn5000_v9_program.llvm.elf",
                rom="original_ROMs/kn5000_v9_program.rom"),
    "v10": dict(mirror="v10/maincpu", base=0xE00000,
                elf="rebuilt_ROMs/kn5000_v10_program.llvm.elf",
                rom="original_ROMs/kn5000_v10_program.rom"),
}

BYTEISH = re.compile(r'^\s*\.(byte|word|short|long|hword|quad|ascii|asciz'
                     r'|string|space|zero|fill|incbin|2byte|4byte|8byte)\b', re.I)
NUMXFER = re.compile(r'^\s*(call|calr|jp|jr|jrl|djnz)\s+'
                     r'(?:[a-z]+\s*,\s*)?0x([0-9a-fA-F]+)\s*$')
GENINC = re.compile(r'\.incbin\s+"(includes/generated/[^"]+)"'
                    r'(?:\s*,\s*([0-9xa-fA-F]+)\s*,\s*([0-9xa-fA-F]+))?')


def symtab(key):
    elf = os.path.join(ROOT, IMG[key]["elf"])
    if not os.path.exists(elf):
        sys.exit("missing %s -- run `make %s`" % (elf, IMG[key]["elf"]))
    out = subprocess.run([NM, "--defined-only", elf],
                         capture_output=True, text=True).stdout
    s = {}
    lo, hi = IMG[key]["base"], IMG[key]["base"] + len(rom(key))
    for ln in out.split("\n"):
        p = ln.split()
        # Keep only symbols that OCCUPY ADDRESS SPACE.  llvm-nm type `a` is an
        # ABSOLUTE symbol -- the register/IO equates (`ADMOD1 = 0x128`, 1,153 of
        # them in v7) -- and mixing those into the sorted address list silently
        # TRUNCATES regions: an equate whose value happens to fall inside a
        # region is read as "the next label", so a 2,268 B region is graded as
        # 96 B.  Caught by three regions whose symbol-derived extent disagreed
        # with the source run they sit in.
        if len(p) >= 3 and p[1] in ("t", "T", "d", "D", "r", "R") \
                and lo <= int(p[0], 16) < hi:
            s.setdefault(p[2], int(p[0], 16))
    return s


def rom(key):
    return open(os.path.join(ROOT, IMG[key]["rom"]), "rb").read()


def stated_bytes(line):
    """The literal byte values a `.byte` line states, or None."""
    c = C.strip_comment(line)
    m = re.match(r'^\s*(?:[A-Za-z_.$][\w.$@]*:)?\s*\.byte\s+(.*)$', c, re.I)
    if not m:
        return None
    vals = []
    for t in m.group(1).split(","):
        t = t.strip()
        if not re.fullmatch(r'0x[0-9a-fA-F]{1,2}|\d{1,3}', t):
            return None
        vals.append(int(t, 0))
    return vals


def _stmt(L, k):
    """The statement text on line k with any leading label removed, '' if the
    line carries no statement."""
    c = C.strip_comment(L[k]).strip()
    m = C.LABEL_RE.match(c)
    if m:
        c = c[m.end():].strip()
    return c


def ref_runlen(L, li):
    """How many CONSECUTIVE instruction lines the referring line sits inside.
    This is the phantom discriminator.  `ref_distance` alone is not one: in v7
    nearly every file is peppered with `.byte`, so "a byte run is 4 lines away"
    is the norm rather than a warning.  The IC19 phantoms were transfers on an
    ISLAND of a few apparent instructions floating between byte runs; a
    transfer sitting in the middle of a fifty-instruction routine is not that
    shape.  Blank, comment-only and label-only lines do not break the run;
    only a byte-emitting directive does."""
    lo = hi = li
    while lo > 0:
        c = _stmt(L, lo - 1)
        if c and BYTEISH.match(" " + c):
            break
        lo -= 1
    while hi + 1 < len(L):
        c = _stmt(L, hi + 1)
        if c and BYTEISH.match(" " + c):
            break
        hi += 1
    return sum(1 for k in range(lo, hi + 1) if _stmt(L, k))


def ref_distance(L, li):
    """Lines from the referring line to the nearest byte-emitting directive.
    Reported for continuity with the IC19 adjudication; see ref_runlen for why
    it is weak on its own."""
    for d in range(0, 60):
        for k in (li - d, li + d):
            if 0 <= k < len(L) and BYTEISH.match(C.strip_comment(L[k])):
                return d
    return None


def grade(key, minsize=0):
    info = IMG[key]
    files, labels, refs = C.scan(info["mirror"])
    syms, R, base = symtab(key), rom(key), info["base"]
    addrs = sorted(set(syms.values()))
    out, refused = [], []
    for name, places in labels.items():
        if name not in refs or name not in syms:
            continue
        for (rel, li) in places:
            L = files[rel]
            fe = C.first_emitting(L, li)
            if not fe or fe[1] != "data":
                continue
            nb, endline = C.run_extent(L, fe[0])
            if nb < minsize:
                continue
            a = syms[name]
            # ---- test 2: the address guard, against the source's own claim
            sb = stated_bytes(L[fe[0]])
            if sb is not None:
                if list(R[a - base:a - base + len(sb)]) != sb:
                    refused.append((name, rel, li + 1, "ADDRESS GUARD FAILED"))
                    continue
            i = bisect.bisect_right(addrs, a)
            end = addrs[i] if i < len(addrs) else a + nb
            if nb:
                end = min(end, a + nb)
            n = end - a
            if n <= 0 or n > 65536:
                continue
            blob = R[a - base:a - base + n]
            # ---- tests 3+4
            res = CCB.convert_block(list(blob), base_pc=a)
            ok = sum(nbb for (m, _o, nbb) in res if m is not None)
            ends_exact = bool(res and res[-1][0] is not None
                              and res[-1][1] + res[-1][2] == n)
            allclean = all(m is not None for (m, _o, _n) in res)
            # ---- test 1
            rq, rr = [], []
            for (rrel, rli, rtxt) in refs[name]:
                rq.append(ref_distance(files[rrel], rli))
                rr.append(ref_runlen(files[rrel], rli))
            out.append(dict(label=name, rel=rel, line=li + 1, addr=a, size=n,
                            declared=nb, rt=ok, rtpct=100.0 * ok / n,
                            allclean=allclean, ends_exact=ends_exact,
                            nrefs=len(refs[name]),
                            refdist=min([x for x in rq if x is not None], default=None),
                            refrun=max(rr) if rr else 0,
                            refs=[(a1, b1 + 1, c1.strip()[:90])
                                  for (a1, b1, c1) in refs[name][:4]]))
    return out, refused


def randomctl(nsamples, sizes, seed=90902):
    """NULL for tests 3+4: the same lengths, uniformly random bytes.  The
    architecture's measured base rate for a clean blind decode is ~24%
    (scripts/analysis/blind_run_decode_census.py); this re-measures it for the
    length distribution actually being graded and adds the round-trip
    requirement, which that census does not have."""
    rnd = random.Random(seed)
    clean = exact = 0
    for _ in range(nsamples):
        n = rnd.choice(sizes)
        blob = bytes(rnd.randrange(256) for _ in range(n))
        res = CCB.convert_block(list(blob), base_pc=0xE10000)
        if all(m is not None for (m, _o, _n) in res):
            clean += 1
        if res and res[-1][0] is not None and res[-1][1] + res[-1][2] == n:
            exact += 1
    return clean, exact, nsamples


def cc_ranges(key, syms):
    """Address ranges emitted by `.incbin includes/generated/*.bin`, anchored
    at the preceding label's linked address."""
    info = IMG[key]
    root = os.path.join(ROOT, info["mirror"])
    out = []
    for dp, _, fn in os.walk(root):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            L = open(os.path.join(dp, f), encoding="latin-1").read().split("\n")
            lastlab = None
            for ln in L:
                c = C.strip_comment(ln).strip()
                m = C.LABEL_RE.match(c)
                if m:
                    lastlab = m.group(1)
                    c = c[m.end():].strip()
                g = GENINC.search(c)
                if g and lastlab in syms:
                    p = os.path.join(root, g.group(1))
                    if g.group(3):
                        n = int(g.group(3), 0)
                    elif os.path.isfile(p):
                        n = os.path.getsize(p)
                    else:
                        continue
                    a = syms[lastlab]
                    out.append((a, a + n))
                    lastlab = None
    return out


def null():
    print("NULL FOR THE CONTROL-TRANSFER FLAG")
    print("  Population: labels heading a DATA run, in the three code-bearing")
    print("  maincpu images.  A label whose run is a `.incbin` of a .bin the")
    print("  Makefile compiles from C is DATA on an authority independent of")
    print("  every decoder and every framing judgement in this tree.\n")
    print("  %-5s %-42s %7s %8s %7s" % ("img", "population", "labels", "targeted", "rate"))
    tot = {}
    for key in ("v7", "v9", "v10"):
        files, labels, refs = C.scan(IMG[key]["mirror"])
        cnt = {"all": [0, 0], "cc": [0, 0], "slice": [0, 0], "lit": [0, 0]}
        for name, places in labels.items():
            for (rel, li) in places:
                fe = C.first_emitting(files[rel], li)
                if not fe or fe[1] != "data":
                    continue
                t = 1 if name in refs else 0
                cnt["all"][0] += 1
                cnt["all"][1] += t
                txt = fe[2]
                k = ("cc" if (".incbin" in txt and "includes/generated" in txt)
                     else "slice" if ".incbin" in txt else "lit")
                cnt[k][0] += 1
                cnt[k][1] += t
        for k, lbl in (("all", "all labels heading a data run"),
                       ("cc", "NULL: C-compiled .incbin (generated/)"),
                       ("slice", "raw ROM-slice .incbin"),
                       ("lit", "literal .byte/.word/... run")):
            a, b = cnt[k]
            print("  %-5s %-42s %7d %8d %6.2f%%" %
                  (key, lbl, a, b, 100.0 * b / max(1, a)))
            p = tot.setdefault(k, [0, 0])
            p[0] += a
            p[1] += b
        print()
    print("  %-5s %-42s %7s %8s %7s" % ("", "COMBINED", "labels", "targeted", "rate"))
    for k, lbl in (("all", "all labels heading a data run"),
                   ("cc", "NULL: C-compiled .incbin (generated/)"),
                   ("slice", "raw ROM-slice .incbin"),
                   ("lit", "literal .byte/.word/... run")):
        a, b = tot[k]
        print("  %-5s %-42s %7d %8d %6.2f%%" % ("", lbl, a, b, 100.0 * b / max(1, a)))

    print("\n  CONFOUND CHECK -- numeric control transfers into C-compiled ranges.")
    print("  A label cannot be written inside an `.incbin`, so a real transfer")
    print("  into one could only be spelled numerically.  If any exist, the")
    print("  0.00% above is understated.  Resolved against the linked image:")
    for key in ("v7", "v9", "v10"):
        syms = symtab(key)
        ranges = cc_ranges(key, syms)
        n_num = n_in = 0
        root = os.path.join(ROOT, IMG[key]["mirror"])
        for dp, _, fn in os.walk(root):
            for f in sorted(fn):
                if not f.endswith(".s"):
                    continue
                for ln in open(os.path.join(dp, f), encoding="latin-1"):
                    m = NUMXFER.match(C.strip_comment(ln))
                    if not m:
                        continue
                    n_num += 1
                    t = int(m.group(2), 16)
                    if any(lo <= t < hi for (lo, hi) in ranges):
                        n_in += 1
        print("  %-5s numeric control transfers %4d   landing inside a "
              "C-compiled region: %d" % (key, n_num, n_in))


def main():
    a = sys.argv[1:]
    if "--null" in a:
        null()
        return
    if "--randomctl" in a:
        n = int(a[a.index("--randomctl") + 1])
        sizes = [int(x) for x in a[a.index("--sizes") + 1].split(",")] \
            if "--sizes" in a else [8, 16, 32, 64, 128, 256]
        c, e, N = randomctl(n, sizes)
        print("RANDOM-BYTE NULL for the decode tests, n=%d, lengths %s" % (N, sizes))
        print("  fully clean decode + round-trip  %d/%d = %.1f%%" % (c, N, 100.0 * c / N))
        print("  ends exactly on the end          %d/%d = %.1f%%" % (e, N, 100.0 * e / N))
        return
    keys = [x for x in a if x in IMG] or ["v7", "v9", "v10"]
    minsize = int(a[a.index("--min") + 1]) if "--min" in a else 0
    for key in keys:
        out, refused = grade(key, minsize=minsize)
        out.sort(key=lambda r: (-r["allclean"], -r["size"]))
        print("\n=== %s : %d control-transfer-targeted data regions (>=%d B), "
              "%d B" % (key, len(out), minsize, sum(r["size"] for r in out)))
        if refused:
            print("  %d REFUSED by the address guard: %s" % (len(refused), refused[:4]))
        print("  %-36s %8s %6s %6s %5s %5s %4s %6s" %
              ("label", "addr", "bytes", "rt%", "clean", "ends", "rd", "refrun"))
        for r in out:
            print("  %-36s %08X %6d %5.1f%% %5s %5s %4s %6d" %
                  (r["label"][:36], r["addr"], r["size"], r["rtpct"],
                   "yes" if r["allclean"] else "no",
                   "yes" if r["ends_exact"] else "NO",
                   "-" if r["refdist"] is None else r["refdist"], r["refrun"]))
        A = [r for r in out if r["allclean"] and r["ends_exact"]]
        print("  SUMMARY  clean+ends-exact: %d regions, %d B  |  "
              "not clean: %d regions, %d B" %
              (len(A), sum(r["size"] for r in A), len(out) - len(A),
               sum(r["size"] for r in out) - sum(r["size"] for r in A)))
        p = os.path.join(ROOT, "code_suspect_%s.json" % key)
        json.dump(out, open(p, "w"), indent=1)
        print("  wrote %s" % p)


if __name__ == "__main__":
    main()
