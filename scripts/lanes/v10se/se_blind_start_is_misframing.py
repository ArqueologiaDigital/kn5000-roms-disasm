#!/usr/bin/env python3
r"""DOES A BLIND-START `.byte` RUN MEAN UNDECODED CODE, OR MIS-FRAMED DATA?

QUESTION ANSWERED
-----------------
`scripts/analysis/byte_run_start_enrichment.py` originally read a high
blind-start rate ({0x01,0x04,0x17,0x1a,0x1c} as a run's first byte) as
UNDECODED CODE.  Commit 3309e94e corrected that: it measures MIS-FRAMING, and
data-framed-as-code produces the signature more strongly than undecoded code
does, because a wrong instruction stream breaks at every byte the decoder
refuses and is chopped into short runs each STARTING with a refused byte.

That correction came from a before/after on `seq_event_playback.s`.  This lane
can test it a second, independent way, with a population that is proven data
by EXTERNAL evidence rather than by a conversion decision:

  The 16 spans this lane converted are certified DATA because a C struct,
  compiled with the project's own toolchain, emits exactly those ROM bytes
  (se_c_descriptor_vs_rom.py).  Nothing about that certificate depends on any
  decoder, any framing judgement, or on this lane being right.

So: were the `.byte` runs INSIDE those proven-data spans enriched in blind
starts, relative to the rest of the same file, BEFORE they were converted?

  * If YES, blind starts are produced by data wrongly spelled as code -- the
    corrected reading -- because these bytes are provably not code at all.
  * If NO, the enrichment in this file comes from somewhere else.

RECONSTRUCTING THE "BEFORE" STATE
  The pre-conversion source is in git and needs no scratch file:
      git show 7294d049^:v10/maincpu/audio/sound_editor_ui.s     (wave 1)
      git show 01b48a5f^:v10/maincpu/audio/sound_editor_ui.s     (wave 2)
  The address->line map for those trees is regenerated with the tree's own
  tool, from a worktree checked out at that commit:
      git worktree add /tmp/pre 7294d049^
      cd /tmp/pre && python3 scripts/analysis/address_line_map.py --dump /tmp/amap-pre.json
  The per-run table this script derives is committed next to it as
  `se_blind_start_is_misframing.json`, so the numbers survive the scratch dir.

RUN
    python3 scripts/lanes/v10se/se_blind_start_is_misframing.py \
        --amap /tmp/amap-pre.json --snapshot /tmp/pre_sound_editor_ui.s \
        --spans F1115E:206,... [--json out.json]
    python3 scripts/lanes/v10se/se_blind_start_is_misframing.py --replay \
        scripts/lanes/v10se/se_blind_start_is_misframing.json
"""
import argparse
import bisect
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
from se_byte_run_census import scan                      # noqa: E402

BASE = 0xE00000
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
TARGET = "v10/maincpu/audio/sound_editor_ui.s"
BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf",
         0x1a: "JP nnnn", 0x1c: "CALL nnnn"}
CONTROL_BYTES = {0x02, 0x03, 0x05, 0x16, 0x1b}


def rate(runs, keys):
    n = sum(1 for r in runs if r["first"] in keys)
    return n, len(runs), (100.0 * n / len(runs) if runs else 0.0)


def report(tab):
    inside, outside = tab["inside"], tab["outside"]

    def line(tag, runs):
        bn, tot, bp = rate(runs, BLIND)
        cn, _, cp = rate(runs, CONTROL_BYTES)
        # ⚠ 3309e94e: with a zero control count the ratio is infinite
        # regardless of the blind count. Print the RAW COUNTS and only show a
        # ratio when the control is out of single digits.
        ratio = ("%.1fx" % (bp / cp)) if cn >= 10 else "n/a (control=%d)" % cn
        print("  %-46s blind %4d/%-5d = %5.1f%%   control %3d = %4.1f%%   %s"
              % (tag, bn, tot, bp, cn, cp, ratio))

    print("BLIND-START RATE, PRE-CONVERSION `sound_editor_ui.s`")
    line("INSIDE spans later proven DATA by a C compile", inside)
    line("OUTSIDE those spans (rest of the same file)", outside)
    bi = rate(inside, BLIND)[2]
    bo = rate(outside, BLIND)[2]
    print()
    print("  enrichment of blind starts inside PROVEN DATA: %.2fx" % (bi / bo))
    print()
    print("  Those spans are certified data by an external byte-exact compile,")
    print("  so their blind starts CANNOT be undecoded code. Whatever produced")
    print("  them, it was not an instruction the assembler could not spell.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap")
    ap.add_argument("--snapshot")
    ap.add_argument("--spans")
    ap.add_argument("--json")
    ap.add_argument("--replay")
    args = ap.parse_args()

    if args.replay:
        report(json.load(open(args.replay)))
        return

    rom = open(ROM, "rb").read()
    ent = json.load(open(args.amap))
    addrs = [e["addr"] for e in ent]
    l2a = {}
    for e in ent:
        l2a.setdefault((e["src"], e["line"]), e["addr"])

    cov = set()
    for spec in args.spans.split(","):
        b, n = spec.split(":")
        cov.update(range(int(b, 16), int(b, 16) + int(n)))

    inside, outside = [], []
    for r in scan(args.snapshot):
        a = l2a.get((TARGET, r["start_line"]))
        if a is None:
            continue
        rec = dict(addr=a, nbytes=r["nbytes"], first=rom[a - BASE])
        (inside if a in cov else outside).append(rec)

    tab = dict(inside=inside, outside=outside)
    report(tab)
    if args.json:
        json.dump(tab, open(args.json, "w"))
        print("\nwrote %s" % args.json)


if __name__ == "__main__":
    main()
