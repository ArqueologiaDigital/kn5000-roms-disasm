#!/usr/bin/env python3
r"""Re-frame v7 `.byte` code runs whose framing is confirmed by the same routine in v10.

QUESTION ANSWERED
    v7 holds many routines as `.byte` rows (and romslice `.incbin`s are not
    touched here) that v10 holds as instructions.  scripts/analysis/
    v10_reframe_code_runs.py (run through reframe_code_runs_to_region_end.py)
    can re-spell such runs, but it refuses any span in which a byte 0x01 or
    0x04 sits inside an operand, because the backend cannot decode `normal`
    (0x01) and `max` (0x04): a linear sweep could swallow one of them and still
    re-converge.  In v7 that refusal hits almost every routine, since 0x01 and
    0x04 are common immediates.

    This wrapper replaces that heuristic with an independent check.  A v7 label
    region [label, next label) is re-framed only if
      1. the same label exists in the v10 build, and
      2. the linear sweep of the v7 bytes and the linear sweep of the v10 bytes
         from that label give the SAME instruction sequence over the whole
         region: equal lengths and equal text once every number is masked
         (absolute addresses and branch displacements may differ between the
         versions; opcodes, registers and addressing modes may not).
      3. every byte of the v10 span is CODE in the v10 source (instruction
         statements, per data_range_census.py's v10 regions) -- a sweep of
         v10 bytes that v10 itself holds as `.byte` data proves nothing.
    v10's framing there is the tree's own code, so a v7 sweep that reproduces
    it instruction for instruction is framed the same way; a hidden
    `normal`/`max` in v7 would have to be matched by the same swallow in v10's
    code.  Every other refusal of the base tool stays
    (undecodable bytes, strings, lost symbols, texts that do not re-encode to
    the ROM bytes, moved label definitions), and `make gate` is the final check.

RUN
    python3 scripts/analysis/data_range_census.py --images v10 --json /tmp/c10.json
    python3 scripts/analysis/v10_line_address_map.py --image v7 FILES --out /tmp/lm.json
    V10_CENSUS=/tmp/c10.json KN5000_IMAGE=v7 \
      python3 scripts/analysis/reframe_v7_runs_crosscheck_v10.py \
        --linemap /tmp/lm.json --report FILES          # or --apply, then make gate
"""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
if os.environ.get("KN5000_IMAGE") != "v7":
    raise SystemExit("run with KN5000_IMAGE=v7")
import reframe_code_runs_to_region_end  # noqa: E402,F401  (region-end anchors)
import v10_reframe as R  # noqa: E402
import v10_reframe_code_runs as base  # noqa: E402

B = 0xE00000
NUM = re.compile(r"-?\b(0x[0-9a-fA-F]+|\d+)\b")
ROM10 = open(os.path.join(R.ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()


def syms(image):
    out = subprocess.run([os.path.join(R.LLVM, "llvm-nm"), "--defined-only",
                          os.path.join(R.ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % image)],
                         capture_output=True, text=True, check=True).stdout
    by_addr, by_name = {}, {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            a = int(p[0], 16)
            by_addr.setdefault(a, []).append(p[2])
            by_name[p[2]] = a
    return by_addr, by_name


S7, _ = syms("v7")
_, N10 = syms("v10")
STATS = {"confirmed": 0, "confirmed_b": 0, "no_v10_label": 0, "mismatch": 0, "v10_not_code": 0}


def v10_code_intervals():
    import json
    path = os.environ.get("V10_CENSUS")
    if not path:
        raise SystemExit("set V10_CENSUS to a data_range_census.py --images v10 --json file")
    regs = json.load(open(path))["regions"]
    return sorted((r["addr"], r["addr"] + r["size"]) for r in regs
                  if r["image"] == "v10" and r["bucket"] == "code")


CODE10 = v10_code_intervals()


def v10_all_code(lo, hi):
    import bisect
    starts = [x[0] for x in CODE10]
    a = lo
    while a < hi:
        k = bisect.bisect_right(starts, a) - 1
        if k < 0 or not (CODE10[k][0] <= a < CODE10[k][1]):
            return False
        a = CODE10[k][1]
    return True


def mask(t):
    return NUM.sub("#", t.split(";")[0].strip())


_sweep = base.sweep


def sweep_checked(rom, a, b):
    bounds, texts, bad = _sweep(rom, a, b)
    names = [n for n in S7.get(a, []) if not re.search(r"_0x[0-9A-Fa-f]+$", n)]
    a10 = next((N10[n] for n in names if n in N10), None)
    if a10 is None:
        STATS["no_v10_label"] += 1
        return bounds, texts, set(bounds)          # refuse: nothing to compare with
    seq7 = [texts[x] for x in sorted(texts)]
    segs10 = R.disassemble(ROM10[a10 - B:a10 - B + (b - a)])
    ok = len(segs10) == len(seq7) and all(
        n7 == n10 and mask(t7) == mask(t10) for (n7, t7), (n10, t10) in zip(seq7, segs10))
    if not ok:
        STATS["mismatch"] += 1
        return bounds, texts, set(bounds)
    if not v10_all_code(a10, a10 + (b - a)):
        STATS["v10_not_code"] += 1
        return bounds, texts, set(bounds)
    STATS["confirmed"] += 1
    STATS["confirmed_b"] += b - a
    return bounds, texts, bad


base.sweep = sweep_checked
base.BLIND = set()        # replaced by the v10 cross-check above

# The base tool writes an absolute operand that equals a label address as the
# label, then assembles each text IN ISOLATION to compare with the ROM bytes --
# where the label is undefined, so every span with such an operand failed the
# round trip.  Encode the numeric form instead (the label stands for exactly
# that value at link time); the emitted text keeps the label.
_encode_map = base.encode_map
_NAME2ADDR = {}
for _a, _ns in S7.items():
    for _n in _ns:
        _NAME2ADDR.setdefault(_n, _a)
# the base tool substitutes names from R.elf_symbols() (all symbol types, e.g.
# the absolute OFFSCREEN_BUFFER_1): map those back too
for _a, _n in R.elf_symbols().items():
    _NAME2ADDR.setdefault(_n, _a)
_TOK = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\b")


def encode_map_numeric(texts):
    num = {t: _TOK.sub(lambda m: str(_NAME2ADDR[m.group(1)]) if m.group(1) in _NAME2ADDR
                       and not re.fullmatch(r"x?[a-z]{1,3}", m.group(1)) else m.group(1), t)
           for t in texts}
    emap, bad = _encode_map(sorted(set(num.values())))
    out, badt = {}, set()
    for t, n in num.items():
        if n in bad or n not in emap:
            badt.add(t)
        else:
            out[t] = emap[n]
    return out, badt


base.encode_map = encode_map_numeric

if __name__ == "__main__":
    try:
        base.main()
    finally:
        print("v10 cross-check: %(confirmed)d regions (%(confirmed_b)d B) confirmed, "
              "%(mismatch)d refused on mismatch, %(v10_not_code)d refused as not code in v10, "
              "%(no_v10_label)d without a v10 label" % STATS)
