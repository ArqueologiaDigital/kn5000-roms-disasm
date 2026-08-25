#!/usr/bin/env python3
"""How many INSTRUCTIONS are in a converted prom_b block -- as against BYTES?

QUESTION IT ANSWERS
  The round-2 audit's finding F2: `prom_b/wsa1_prom_b.s` and
  notes/FINDINGS-prom_b-f0ea9f-module.md both said the 0xF0EA9F block held
  "13,357 decoded instructions".  13,357 is the byte total of its 21 CODE
  segments -- the number printed six lines away in the same banner, in a column
  headed `bytes`.  A TLCS-900 instruction averages a shade under three bytes, so
  the two numbers differ by roughly 2.9x and nothing in the tree computed the
  instruction one.  This does, from the ROM.

METHOD, AND WHY IT IS NOT A LINE COUNT
  Counting source lines does not work: an instruction llvm-mc cannot encode is
  emitted as `.byte 0xEE, 0x0C, 0xF8, 0xFF  ; F0EA9F  link XIZ,0xfff8`, which a
  `.byte`-versus-mnemonic split would score as data.  (That is why the audit's
  own hand count, 4,675, is a floor rather than the number.)

  Instead: take the block's FROZEN LAYOUT from its generator, walk every segment
  the layout calls `code` with the same decoder the layout itself used
  (notes/prom_b_module_trace.decode_at), and count the instructions.  Then CHECK
  the result against `prom_b/wsa1_prom_b.s`: every decoded instruction start must
  carry a `; ADDR` comment in the file and every `; ADDR` comment inside a code
  segment must be a decoded instruction start.  The two sets must be EQUAL, which
  catches a splice that dropped a line as well as a decoder that drifted.

RUN
    python3 notes/prom_b_instr_census.py                # every known block
    python3 notes/prom_b_instr_census.py --module f0ea9f
    python3 notes/prom_b_instr_census.py --range 0xF6D002 0xF78000
    python3 notes/prom_b_instr_census.py --last         # per block, its LAST
                                                        # code segment, in full
Exit status is non-zero if any cross-check fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_module_trace as MT                                   # noqa: E402

SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
FAIL = []

# name -> generator module that carries the frozen LAYOUT
MODULES = [
    ("f65000", "gen_prom_b_f65000_module"),
    ("f0ea9f", "gen_prom_b_f0ea9f_module"),
    ("f6d002", "gen_prom_b_f6d002_module"),
]


def layout_of(mod):
    m = __import__(mod)
    return m.LAYOUT, m.LO, m.HI


def src_addrs():
    """Every address that begins a `; ADDR  ...` comment on a line of the .s.

    One per emitted object line, instruction or datum, so intersecting it with a
    code segment gives exactly the lines that claim to be instructions there."""
    out = set()
    for ln in open(SRC):
        m = re.search(r";\s*([0-9A-F]{6})\s", ln)
        if m and not ln.lstrip().startswith(";"):
            out.add(int(m.group(1), 16))
    return out


def decode_segment(lo, n):
    """Instruction start addresses of the code segment [lo, lo+n)."""
    out, p = [], lo
    while p < lo + n:
        dec = MT.decode_at(p)
        if dec is None:
            FAIL.append("0x%06X does not decode" % p)
            break
        out.append(p)
        p += dec[0]
    if p != lo + n:
        FAIL.append("code segment 0x%06X+%d does not end on a boundary "
                    "(walk stopped at 0x%06X)" % (lo, n, p))
    return out


def census(layout, lo, hi, label, show_last=False):
    sa = src_addrs()
    starts, codebytes, segs = [], 0, []
    for kind, a, n in layout:
        if kind != "code":
            continue
        segs.append((a, n))
        codebytes += n
        starts += decode_segment(a, n)
    starts = set(starts)
    in_code = set()
    for a, n in segs:
        in_code |= set(x for x in sa if a <= x < a + n)
    missing = sorted(starts - in_code)
    extra = sorted(in_code - starts)
    print("%s  0x%06X-0x%06X" % (label, lo, hi - 1))
    print("  code segments      %6d" % len(segs))
    print("  code BYTES         %6d" % codebytes)
    print("  INSTRUCTIONS       %6d      (%.2f bytes/instruction)"
          % (len(starts), codebytes / float(len(starts) or 1)))
    print("  cross-check vs the .s: %d decoded starts with no source line, "
          "%d source lines that are not a start" % (len(missing), len(extra)))
    if missing or extra:
        FAIL.append("%s cross-check" % label)
        print("    missing:", " ".join("0x%06X" % x for x in missing[:8]))
        print("    extra:  ", " ".join("0x%06X" % x for x in extra[:8]))
    if show_last and segs:
        a, n = segs[-1]
        ls = decode_segment(a, n)
        print("  LAST code segment 0x%06X+%d: %d instructions, "
              "first 0x%06X last 0x%06X, last line in the .s: %s"
              % (a, n, len(ls), ls[0], ls[-1], "yes" if ls[-1] in sa else "NO"))
        if ls[-1] not in sa:
            FAIL.append("%s last instruction not in the .s" % label)
    return len(starts), codebytes


def main():
    argv = sys.argv[1:]
    if "--range" in argv:
        i = argv.index("--range")
        lo, hi = int(argv[i + 1], 16), int(argv[i + 2], 16)
        sys.path.insert(0, os.path.join(ROOT, "notes"))
        import prom_b_f0ea9f_layout as LY
        LY.LO, LY.HI = lo, hi
        segs = LY.build()[0]
        census([(k, a, n) for k, a, n in segs], lo, hi,
               "range", "--last" in argv)
    else:
        want = None
        if "--module" in argv:
            want = argv[argv.index("--module") + 1]
        for name, mod in MODULES:
            if want and name != want:
                continue
            try:
                lay, lo, hi = layout_of(mod)
            except ImportError:
                continue
            census(lay, lo, hi, name, "--last" in argv)
            print()
    if FAIL:
        print("FAIL (%d)" % len(FAIL))
        for f in FAIL:
            print("  -", f)
        return 1
    print("PASS: every code segment decodes end to end and matches the .s.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
