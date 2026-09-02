#!/usr/bin/env python3
r"""CONVERT THE v7 CONTROL-TRANSFER-TARGETED REGIONS THAT SURVIVED ADJUDICATION.

QUESTION THIS ANSWERS
---------------------
`scripts/analysis/code_suspect_adjudicate.py v7` grades every v7 data region
whose heading label is the target of a control transfer.  This driver converts
the ones that pass BOTH evidence gates, and refuses everything else:

  * the whole region decodes and every instruction round-trips byte-exact
    (`allclean`), random-byte null 0.8% at these lengths; and
  * the transfer that names it sits inside a run of at least `--minrefrun`
    consecutive instruction lines (default 8).  This is the phantom gate: the
    13 IC19 phantoms were transfers on an ISLAND of a few apparent instructions
    floating between `.byte` runs.

Conversion itself is delegated unmodified to
`convert_interrupted_region_v7.process()`, which pulls the bytes from the
ORIGINAL ROM at the region's address, walks the source lines summing emitted
widths until they equal the size EXACTLY (aborting on anything unexpected), and
rewrites only that line range.  Nothing here re-implements it.

  Every call passes `min_start_line` so the converter REFUSES when
  `rewind_to_true_start()` walks the span above this region's own label -- see
  that parameter's docstring for the one-byte near-miss that made it necessary.

  A region whose symbol-derived extent is SHORTER than the source data run it
  begins (a `.byte` run continuing past the next label) is SKIPPED, not
  partially converted: `process()` needs the line widths to sum to the size
  exactly, and a partial conversion would need the run split first.

RUN
    python3 scripts/converters/convert_code_suspect_v7.py            # dry run
    python3 scripts/converters/convert_code_suspect_v7.py --apply

AFTER APPLYING
    make rebuilt_ROMs/kn5000_v7_program.llvm.rom && \
      cmp rebuilt_ROMs/kn5000_v7_program.llvm.rom original_ROMs/kn5000_v7_program.rom
    make gate-all
    python3 scripts/analysis/v7_call_target_boundary_audit.py
A clean decode is not proof; the byte gate cannot object to a wrong
interpretation, which is why the boundary audit is run separately.

TOOLCHAIN.  tlcs900_backend@6f456a19f05b for this lane's run.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import convert_interrupted_region_v7 as CIR7   # noqa: E402
import code_suspect_sites as CSS              # noqa: E402


def data_line(rel, label_line):
    """The 1-based line of the region's FIRST byte-emitting directive.
    The adjudicator records the LABEL's line; find_span() wants a line inside
    the data run.  Recomputed here rather than carried, because a derived
    artefact that is cheap to regenerate should be regenerated."""
    p = os.path.join(ROOT, "v7", "maincpu", rel)
    L = open(p, encoding="latin-1").read().split("\n")
    fe = CSS.first_emitting(L, label_line - 1)
    return (fe[0] + 1) if fe and fe[1] == "data" else label_line


def main():
    apply = "--apply" in sys.argv
    minrun = int(sys.argv[sys.argv.index("--minrefrun") + 1]) \
        if "--minrefrun" in sys.argv else 8
    src = os.path.join(ROOT, "code_suspect_v7.json")
    if not os.path.exists(src):
        sys.exit("run scripts/analysis/code_suspect_adjudicate.py v7 first")
    recs = json.load(open(src))
    sel, skipped = [], []
    for r in recs:
        if not (r["allclean"] and r["ends_exact"]):
            continue
        if r["refrun"] < minrun:
            skipped.append((r["label"], "refrun=%d < %d" % (r["refrun"], minrun)))
            continue
        if r["size"] != r["declared"]:
            skipped.append((r["label"], "extent %d != source run %d"
                            % (r["size"], r["declared"])))
            continue
        sel.append(r)
    sel.sort(key=lambda r: (r["rel"], -r["line"]))   # bottom-up: line numbers
    print("selected %d regions, %d B (minrefrun=%d); skipped %d"
          % (len(sel), sum(r["size"] for r in sel), minrun, len(skipped)))
    for lbl, why in skipped:
        print("  SKIP %-40s %s" % (lbl, why))
    ok = fail = conv = 0
    for r in sel:
        rel = os.path.join("maincpu", r["rel"])
        try:
            actual, remaining = CIR7.process(
                rel, data_line(r["rel"], r["line"]), r["addr"], r["size"],
                apply=apply, auto_shrink=False, min_start_line=r["line"])
        except SystemExit as e:
            print("  ABORT %-38s %s" % (r["label"], e))
            fail += 1
            continue
        except Exception as e:                       # noqa: BLE001
            print("  ERROR %-38s %r" % (r["label"], e))
            fail += 1
            continue
        print("  %-38s %08X %5d B -> %d B converted, %d left as .byte"
              % (r["label"], r["addr"], r["size"], actual - remaining, remaining))
        ok += 1
        conv += actual - remaining
    print("%s: %d regions ok, %d failed, %d B"
          % ("APPLIED" if apply else "DRY RUN", ok, fail, conv))


if __name__ == "__main__":
    main()
