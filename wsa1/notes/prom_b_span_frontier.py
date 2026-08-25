#!/usr/bin/env python3
"""Which `.incbin` SPAN of prom_b should be converted next?

QUESTION IT ANSWERS -- AND WHY notes/prom_b_module_frontier.py IS NOT ENOUGH
  That tool ranks whole THUNK RUNS by the contiguous unconverted extent of their
  targets, and it is the right tool when a module is entered through the 0xF40000
  routine directory.  It is blind to a module that is entered by DIRECT CALL: a
  45,054-byte span reached by 31 proven call sites and two thunk slots ranks
  THIRTEENTH there, below a run whose two slots name four bytes.

  So this ranks the `.incbin` SPANS THEMSELVES, by three numbers that are
  measured, not guessed:

    bytes    the span's size -- how much converting it can possibly be worth
    proven   how many DISTINCT addresses inside it are the target of a
             `call`/`calr`/`jp`/`jrl` that is ALREADY TRANSCRIBED in
             prom_a/wsa1_prom_a.s or prom_b/wsa1_prom_b.s.  This is the strongest
             evidence there is that a span holds CODE: the byte gate proves the
             file carrying the call site rebuilds the image.
    thunk    how many `jp` slots of the 0xF40000 directory land inside it.

  A span with a high `proven` is code somebody already reaches.  A span with
  proven == 0 and thunk == 0 may still be code, but nothing converted points at
  it, and it is the kind of span where round 5 measured a 13.9% false-code rate.

WHAT IS EXACT AND WHAT IS NOT
  EXACT: the span list (parsed from the .s's own `.incbin` directives, which the
  gate re-checks byte for byte), the thunk slot targets, and the proven-call-site
  set -- it is read out of the transcription's own `; ADDR  <text>` comments, so
  every hit is an instruction the gate has already proven.
  NOT A CALL COUNT: `proven` counts DISTINCT TARGET ADDRESSES, not call sites.

RUN
  python3 notes/prom_b_span_frontier.py            # ranked by bytes
  python3 notes/prom_b_span_frontier.py --by proven
  python3 notes/prom_b_span_frontier.py --n 30
  python3 notes/prom_b_span_frontier.py --selftest
Exit status is non-zero if a self-check fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_module_trace as MT                                   # noqa: E402

B_BASE = 0xF00000
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
FAIL = []


def spans():
    out = []
    for ln in open(SRC):
        m = re.search(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
                      ln)
        if m:
            o, n = int(m.group(1), 16), int(m.group(2), 16)
            out.append((B_BASE + o, B_BASE + o + n))
    return sorted(out)


def proven_targets():
    """Every branch target in prom_b's address space taken by an instruction
    already transcribed in prom_a or prom_b."""
    out = set()
    for img in ("a", "b"):
        src = os.path.join(ROOT, "prom_%s" % img, "wsa1_prom_%s.s" % img)
        for ln in open(src):
            if ";" not in ln:
                continue
            m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr|jp|jr|jrl)\s+"
                          r"(?:\w+,)?0x([0-9a-f]{6})", ln)
            if m:
                t = int(m.group(2), 16)
                if B_BASE <= t < 0xF80000:
                    out.add(t)
    return out


def survey():
    pt = proven_targets()
    rows = []
    for lo, hi in spans():
        pr = sorted(t for t in pt if lo <= t < hi)
        th = MT.thunk_entries(lo, hi)
        rows.append(dict(lo=lo, hi=hi, n=hi - lo, proven=pr, thunk=th))
    return rows


def selftest():
    rows = survey()
    tot = sum(r["n"] for r in rows)
    check("span byte total equals the .incbin total in the .s", tot,
          sum(int(m.group(2), 16) for m in re.finditer(
              r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
              open(SRC).read())))
    check("no span overlaps its neighbour",
          [1 for a, b in zip(rows, rows[1:]) if a["hi"] > b["lo"]], [])
    # LAST element: the highest-addressed span is surveyed, not dropped
    last = rows[-1]
    check("the LAST span (0x%06X-0x%06X) is in the survey" % (last["lo"],
                                                              last["hi"] - 1),
          last["lo"] < last["hi"], True)
    check("a proven target inside a span is really still `.incbin`",
          [1 for r in rows for t in r["proven"] if not (r["lo"] <= t < r["hi"])],
          [])
    print("\n%s (%d failed)" % ("SELFTEST PASS" if not FAIL else "SELFTEST FAIL",
                                len(FAIL)))
    return 1 if FAIL else 0


def check(name, got, want):
    ok = got == want
    if not ok:
        FAIL.append(name)
    print("  %-64s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                          % (got, want)))


def main():
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    rows = survey()
    key = argv[argv.index("--by") + 1] if "--by" in argv else "bytes"
    rows.sort(key=(lambda r: -len(r["proven"])) if key == "proven"
              else (lambda r: -r["n"]))
    n = int(argv[argv.index("--n") + 1]) if "--n" in argv else 12
    print("prom_b `.incbin` spans, %d of them, ranked by %s"
          % (len(rows), key))
    print("  span                     bytes  proven  thunk")
    for r in rows[:n]:
        print("  0x%06X-0x%06X  %8d  %6d  %5d"
              % (r["lo"], r["hi"] - 1, r["n"], len(r["proven"]), len(r["thunk"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
