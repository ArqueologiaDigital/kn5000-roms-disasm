#!/usr/bin/env python3
r"""WHAT KIND OF DEBT IS EACH `.byte` IN THIS LANE'S SIX v10 DIRECTORIES?

QUESTION ANSWERED
-----------------
v10 reports 0 verbatim debt and 100.0% source by
`scripts/analysis/kn5000_source_coverage.py` -- an instrument that counts
`.incbin` and is BLIND to `.byte`.  But a raw `.byte` count is NOT automatically
debt either: a genuine byte-valued table is already correctly represented.  This
splits the `.byte` operands in

    v10/maincpu/{storage,ui,factory_test,file_io,boot,demo}

three ways:

  (a) CODE-DEBT      real instructions still spelled as `.byte`
  (b) SUSPECT        `.byte` embedded in a run of instructions that NOTHING
                     calls or jumps to -- so the surrounding "code" may itself
                     be data-as-code, and converting the `.byte` to an
                     instruction would DEEPEN the error while passing the gate
  (c) TYPED DATA     `.byte` flanked by data; already correctly represented,
                     or structured data that could be typed further

HOW EACH RUN IS JUDGED
  FLANKING    the emitting source line immediately before and after the run.
              Both instructions -> "code-flanked" (the island shape the tree's
              own v9_v10_undisassembled_census.py --islands already measures).
  ENCLOSURE   the nearest preceding label, and how the WHOLE v10 tree refers to
              it: BRANCHED (some call/calr/jp/jr/djnz names it), ADDR_ONLY
              (only .long/.set/ld -- signal #1 for data), or UNREFERENCED.
  CORROBORATION  how many DISTINCT already-named routines the enclosing block
              calls or jumps to.  ⚠ This criterion had to be added: ADDR_ONLY
              alone wrongly condemned `BitMapOut_ByteData_RenderB`, which is
              address-taken 9x from a handler table in ui_widgets/widget_
              dispatch.s and is perfectly real code reached by indirect
              dispatch.  A function-pointer table is the standing exception to
              the brief's "only its address is taken => it is data" rule, and
              the thing that separates the two cases is CONTENT: real code
              calls things that have names (Boot_CheckConfigFlag7, GetTitleNow,
              SndParam_LookupViaEncode); a fake decode of a data blob
              references nothing outside itself.  Same signal as
              scripts/analysis/v7_judged_call_corroboration.py.

⚠ THE CONTROL, AND WHY IT MATTERS MORE THAN THE NUMBERS
  "Code-flanked" on its own is NOT evidence of code, and this lane can measure
  exactly how badly it fails, on real data rather than a synthetic null.
  0xF15907-0xF1612F in storage/flash_floppy_handlers.s was PROVEN to be a
  [flags][len] record stream by scripts/analysis/lane_v10storage_record_stream_
  evidence.py (6/6 chain closures, 12/12 external addresses, 1.0% null) and
  was written as instructions until commit f27f033f.  Running the flanking
  test over that file AS IT STOOD BEFORE the conversion therefore measures the
  criterion's FALSE-POSITIVE RATE on ground-truth data.  `--control` does that,
  reading the pre-conversion file straight out of git.

RUN (from the repo root)
    python3 scripts/analysis/lane_v10storage_byte_split.py --control
    python3 scripts/analysis/lane_v10storage_byte_split.py
    python3 scripts/analysis/lane_v10storage_byte_split.py --detail storage
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(REPO, "v10", "maincpu")
DIRS = ["storage", "ui", "factory_test", "file_io", "boot", "demo"]

BYTE_RE = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$]*:\s*)?\.byte\s+(\S.*)$')
LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$]*):')
DATA_DIRS = ("byte", "word", "hword", "long", "dword", "ascii", "asciz",
             "zero", "fill", "space", "incbin", "short")
BRANCH_RE = re.compile(r'^\s*(call|calr|call_24|jp|jp_24|jr|jrl|djnz)\b')

# The pre-conversion control: file, git revision, and the line range that the
# record-stream evidence script proves is data.
CTRL_FILE = "v10/maincpu/storage/flash_floppy_handlers.s"
CTRL_REV = "f27f033f^"          # the commit that typed it; ^ = just before
CTRL_LINES = (35, 1077)         # 1-based, inclusive -- 0xF15907..0xF1612F


def n_operands(body):
    return len([x for x in body.split(";")[0].split(",") if x.strip()])


def line_kind(line):
    """'byte' | 'data' | 'instr' | None (emits nothing)."""
    s = line.split(";")[0]
    m = LABEL_RE.match(s)
    if m:
        s = s[m.end():]
    s = s.strip()
    if not s:
        return None
    if s.startswith("."):
        d = s[1:].split()[0].split(",")[0]
        if d == "byte":
            return "byte"
        return "data" if d in DATA_DIRS else None
    return "instr"


def runs_in(lines):
    """Maximal runs of consecutive `.byte`-emitting lines.
    Yields (first_idx, last_idx, nbytes, kind_before, kind_after)."""
    kinds = [line_kind(l) for l in lines]
    i = 0
    while i < len(lines):
        if kinds[i] != "byte":
            i += 1
            continue
        j = i
        nb = 0
        while j < len(lines) and kinds[j] in ("byte", None):
            if kinds[j] == "byte":
                nb += n_operands(BYTE_RE.match(lines[j]).group(1))
                last = j
            j += 1
        before = next((kinds[k] for k in range(i - 1, -1, -1) if kinds[k]), None)
        after = next((kinds[k] for k in range(last + 1, len(lines)) if kinds[k]),
                     None)
        yield i, last, nb, before, after
        i = last + 1


def tree_reference_kinds():
    """label -> 'BRANCHED' | 'ADDR_ONLY' | 'UNREFERENCED', over all of v10."""
    defined, branched, addr = set(), set(), set()
    files = []
    for dp, _, fns in os.walk(SRC):
        files += [os.path.join(dp, f) for f in fns if f.endswith(".s")]
    for p in files:
        for line in open(p, encoding="latin-1"):
            m = LABEL_RE.match(line)
            if m:
                defined.add(m.group(1))
    word = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\b')
    for p in files:
        for line in open(p, encoding="latin-1"):
            body = line.split(";")[0]
            if LABEL_RE.match(body) and not body.split(":", 1)[1].strip():
                continue
            names = {w for w in word.findall(body) if w in defined}
            m = LABEL_RE.match(body)
            if m:
                names.discard(m.group(1))
            if not names:
                continue
            (branched if BRANCH_RE.match(body) else addr).update(names)
    return {n: ("BRANCHED" if n in branched else
                "ADDR_ONLY" if n in addr else "UNREFERENCED") for n in defined}


CALLOP_RE = re.compile(r'^\s*(call|calr|call_24|jp|jp_24|jr|jrl|djnz\d*)\b\s*(.*)$')


def block_call_targets(lines, labels, idx, defined):
    """Distinct ALREADY-NAMED routines the labelled block containing source line
    `idx` calls or jumps to.  Empty set = the block references nothing outside
    itself, the signature of a fake decode."""
    starts = [k for k, _ in labels]
    import bisect
    b = bisect.bisect_right(starts, idx) - 1
    lo = starts[b] if b >= 0 else 0
    hi = starts[b + 1] if b + 1 < len(starts) else len(lines)
    own = {n for k, n in labels if lo <= k < hi}
    out = set()
    for l in lines[lo:hi]:
        m = CALLOP_RE.match(l.split(";")[0])
        if not m:
            continue
        for w in re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', m.group(2)):
            if w in defined and w not in own:
                out.add(w)
    return out


def classify(dirs, refkind, detail=None):
    tot = collections.Counter()
    per_dir = collections.defaultdict(collections.Counter)
    rows = []
    defined = set(refkind)
    for d in dirs:
        dp = os.path.join(SRC, d)
        for fn in sorted(os.listdir(dp)):
            if not fn.endswith(".s"):
                continue
            p = os.path.join(dp, fn)
            lines = open(p, encoding="latin-1").read().split("\n")
            labels = [(i, LABEL_RE.match(l).group(1))
                      for i, l in enumerate(lines) if LABEL_RE.match(l)]
            for i, last, nb, before, after in runs_in(lines):
                encl = next((n for k, n in reversed(labels) if k <= i), None)
                rk = refkind.get(encl, "UNREFERENCED")
                code_flanked = (before == "instr" and after == "instr")
                corr = block_call_targets(lines, labels, i, defined)
                if code_flanked and (rk == "BRANCHED" or corr):
                    cls = "a_code_debt"
                elif code_flanked:
                    cls = "b_suspect"
                else:
                    cls = "c_typed_data"
                tot[cls] += nb
                tot[cls + "_runs"] += 1
                per_dir[d][cls] += nb
                rows.append((d, fn, i + 1, nb, before, after, encl, rk, cls, len(corr)))
    return tot, per_dir, rows


def control():
    """False-positive rate of "code-flanked" on ground-truth data."""
    out = subprocess.run(["git", "show", f"{CTRL_REV}:{CTRL_FILE}"],
                         cwd=REPO, capture_output=True)
    lines = out.stdout.decode("latin-1").split("\n")
    lo, hi = CTRL_LINES
    seg = lines[lo - 1:hi]
    labels = [(i, LABEL_RE.match(l).group(1))
              for i, l in enumerate(seg) if LABEL_RE.match(l)]
    defined = set(tree_reference_kinds())
    fp_runs = fp_bytes = all_runs = all_bytes = 0
    rule_runs = rule_bytes = 0
    for i, last, nb, before, after in runs_in(seg):
        all_runs += 1
        all_bytes += nb
        if before == "instr" and after == "instr":
            fp_runs += 1
            fp_bytes += nb
            if block_call_targets(seg, labels, i, defined):
                rule_runs += 1
                rule_bytes += nb
    print("CONTROL -- 'code-flanked' tested on PROVEN data")
    print(f"  {CTRL_FILE} at {CTRL_REV}, lines {lo}..{hi} "
          f"(0xF15907-0xF1612F, proven a [flags][len] record stream)")
    print(f"  .byte runs in that span            : {all_runs} ({all_bytes} B)")
    print(f"  runs the criterion calls CODE      : {fp_runs} ({fp_bytes} B)")
    print(f"  FALSE-POSITIVE RATE of 'code-flanked' alone: "
          f"{fp_runs / all_runs:.1%} of runs, {fp_bytes / all_bytes:.1%} of bytes")
    print(f"  runs the FULL rule calls CODE      : {rule_runs} ({rule_bytes} B)")
    print(f"  FALSE-POSITIVE RATE of the full rule: "
          f"{rule_runs / all_runs:.1%} of runs, {rule_bytes / all_bytes:.1%} of bytes")
    # SENSITIVITY: the same corroboration term, on blocks that are
    # unambiguously code because something BRANCHES to them by name.
    refk = tree_reference_kinds()
    hit = tot_ = 0
    for d in DIRS:
        dp = os.path.join(SRC, d)
        for fn in sorted(os.listdir(dp)):
            if not fn.endswith(".s"):
                continue
            ls = open(os.path.join(dp, fn), encoding="latin-1").read().split("\n")
            labs = [(i, LABEL_RE.match(l).group(1))
                    for i, l in enumerate(ls) if LABEL_RE.match(l)]
            for i, last, nb, before, after in runs_in(ls):
                encl = next((n for k, n in reversed(labs) if k <= i), None)
                if refk.get(encl) != "BRANCHED":
                    continue
                tot_ += 1
                if block_call_targets(ls, labs, i, defined):
                    hit += 1
    print()
    print("SENSITIVITY -- the corroboration term alone, on blocks something")
    print("               BRANCHES to by name (unambiguously code)")
    print(f"  {hit}/{tot_} = {hit / tot_:.1%} of those runs are corroborated")
    print("  -> the term is not a criterion that cannot fail: it misses"
          f" {tot_ - hit} runs of real code,")
    print("     which is why BRANCHED is kept as a separate disjunct.")
    print()
    print("  -> 'code-flanked' ALONE is worthless as evidence of code: it fires")
    print("     on nearly all of a span this lane proved is a record stream.")
    print("     Adding the call-corroboration term is what makes it usable.")
    return fp_runs, all_runs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--control", action="store_true")
    ap.add_argument("--detail", metavar="DIR")
    a = ap.parse_args()
    if a.control:
        control()
        return 0
    refkind = tree_reference_kinds()
    dirs = [a.detail] if a.detail else DIRS
    tot, per_dir, rows = classify(dirs, refkind, a.detail)
    print("THREE-WAY SPLIT of .byte operands, v10/maincpu/{%s}" % ",".join(dirs))
    print()
    hdr = f"{'dir':<14}{'(a) code-debt':>15}{'(b) suspect':>14}{'(c) typed data':>16}"
    print(hdr)
    print("-" * len(hdr))
    for d in dirs:
        c = per_dir[d]
        print(f"{d:<14}{c['a_code_debt']:>15}{c['b_suspect']:>14}"
              f"{c['c_typed_data']:>16}")
    print("-" * len(hdr))
    print(f"{'TOTAL':<14}{tot['a_code_debt']:>15}{tot['b_suspect']:>14}"
          f"{tot['c_typed_data']:>16}")
    print(f"{'(runs)':<14}{tot['a_code_debt_runs']:>15}{tot['b_suspect_runs']:>14}"
          f"{tot['c_typed_data_runs']:>16}")
    print()
    print(f"grand total {sum(tot[k] for k in ('a_code_debt','b_suspect','c_typed_data'))}"
          f" .byte operands")
    if a.detail:
        print()
        for r in rows:
            print(f"  {r[1]}:{r[2]:<6} {r[3]:>5} B  {r[4]}/{r[5]:<6} "
                  f"{r[8]:<13} {r[7]:<12} corr={r[9]:<3} {r[6]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
