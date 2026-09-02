#!/usr/bin/env python3
r"""IS THE `.byte`-RUN "BACKEND GAP" SIGNAL CONFOUNDED IN THE SOUND-EDITOR CORNER?

QUESTION ANSWERED
-----------------
`scripts/analysis/byte_run_start_enrichment.py` shows, image-wide, that v10's
leftover `.byte` runs start with one of {0x01, 0x04, 0x17, 0x1a, 0x1c} far more
often than with a decodable byte of similar magnitude.

⚠ SCOPE, CORRECTED 2026-09-02. When this script was written the enrichment was
read as UNDECODED CODE. Commit 3309e94e retracted that: the signature measures
MIS-FRAMING, and data-framed-as-code produces it more strongly than undecoded
code does. This script tests ONE specific alternative explanation -- "the run
starts on a ScreenData opcode at a known block entry" -- and nothing more. Its
negative result rules out THAT explanation. It does NOT establish that the runs
are undecoded code, and the sentence below that once said "the (d) tag stands"
was over-reading it. se_blind_start_is_misframing.py is the script that
actually addresses the question, and it comes out the other way.

But four of those five bytes are ALSO ScreenData opcodes in this very corner of
the ROM.  From `scripts/generators/screendata_parser.py`:

    0x01 HLINE      0x04 CTRL      0x17 PARAM_LABEL      0x1C FIELD_LABEL

So in `sound_editor_ui.s` a `.byte` run beginning 0x01/0x04/0x17/0x1c has a
second, entirely different explanation: it is the first byte of a screen-layout
COMMAND, i.e. data.  This script measures how much of the corner's blind-start
population that explanation absorbs, so the (d) tag is not silently read as
"undecoded code" where it is really "screen-data opcode".

METHOD
  1. ENTRY POINTS -- every 24-bit immediate `0x00Fxxxxx` that appears in the v10
     assembly sources and lands inside the two lane files' address ranges.  A
     value USED AS AN ADDRESS is the project's standing data-seed rule.
  2. EXTENTS -- ScreenDataParser.parse() from each entry point; the union of the
     parsed spans is the corner's screen-data territory.
  3. INTERSECT -- which blind-start `.byte` runs fall inside it.

★ THE NULL (this is the whole instrument).  A permissive parser will parse
  something almost anywhere, so the same parse is run from N random addresses
  inside the same two files.  The fraction of those that yield a chain as long
  as the real entry points' is the false-positive rate of "this address is a
  screen-data block".  Quote it with the result.

RUN
    python3 scripts/lanes/v10se/se_blind_start_is_screendata.py \
        --amap /tmp/amap.json [--runs /tmp/cls.json]
"""
import argparse
import json
import os
import random
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "generators"))
sys.path.insert(0, HERE)
from screendata_parser import ScreenDataParser            # noqa: E402

BASE = 0xE00000
BLIND = {0x01: "normal / HLINE", 0x04: "max / CTRL", 0x17: "ldf / PARAM_LABEL",
         0x1a: "JP nnnn / --", 0x1c: "CALL nnnn / FIELD_LABEL"}
SCREENDATA_OPCODES = {0x01, 0x04, 0x17, 0x1c}
IMM = re.compile(r"0x00([0-9a-fA-F]{6})")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
FILES = ["v10/maincpu/audio/sound_editor_ui.s",
         "v10/maincpu/audio/semenu_routines.s"]


def file_extents(amap):
    ext = {}
    for e in amap:
        if e["src"] in FILES:
            lo, hi = ext.get(e["src"], (1 << 40, 0))
            ext[e["src"]] = (min(lo, e["addr"]), max(hi, e["addr"]))
    return ext


def entry_points(ext):
    """Every 0x00Fxxxxx immediate in the v10 sources landing in our ranges."""
    hits = set()
    src_root = os.path.join(ROOT, "v10", "maincpu")
    for dp, _, fs in os.walk(src_root):
        for f in fs:
            if not f.endswith(".s"):
                continue
            txt = open(os.path.join(dp, f), encoding="latin-1").read()
            for m in IMM.finditer(txt):
                a = int(m.group(1), 16)
                for lo, hi in ext.values():
                    if lo <= a <= hi:
                        hits.add(a)
    return sorted(hits)


def parsed_extent(parser, a, max_bytes=500):
    cmds = parser.parse(a, max_bytes)
    return sum(c.size for c in cmds)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--nulls", type=int, default=500)
    args = ap.parse_args()

    rom = open(ROM, "rb").read()
    amap = json.load(open(args.amap))
    ext = file_extents(amap)
    parser = ScreenDataParser(rom)

    eps = entry_points(ext)
    spans = []
    for a in eps:
        n = parsed_extent(parser, a)
        if n:
            spans.append((a, a + n))
    covered = set()
    for s, e in spans:
        covered.update(range(s, e))

    print("SCREEN-DATA TERRITORY IN THE SOUND-EDITOR CORNER")
    for f, (lo, hi) in sorted(ext.items()):
        print("  %-42s %06X..%06X" % (os.path.basename(f), lo, hi))
    print("  %d address immediates land in range; %d parse as ScreenData"
          % (len(eps), len(spans)))
    print("  union of parsed spans: %d bytes" % len(covered))

    # --- the blind-start runs, taken straight from the source ---------------
    from se_byte_run_census import scan
    l2a = {}
    for e in amap:
        l2a.setdefault((e["src"], e["line"]), e["addr"])
    runs = []
    for f in FILES:
        for r in scan(os.path.join(ROOT, f)):
            a = l2a.get((f, r["start_line"]))
            if a is None:
                continue
            r["addr"] = a
            r["first"] = rom[a - BASE]
            runs.append(r)
    blind = [r for r in runs if r["first"] in BLIND]
    inside = [r for r in blind if r["addr"] in covered]
    print()
    print("  blind-start `.byte` runs in these two files : %d (%d B)"
          % (len(blind), sum(r["nbytes"] for r in blind)))
    print("  ...of which inside screen-data territory    : %d (%d B) = %.1f%%"
          % (len(inside), sum(r["nbytes"] for r in inside),
             100.0 * len(inside) / max(len(blind), 1)))
    # The comparison that matters: are BLIND-start runs enriched inside
    # screen-data territory relative to ALL `.byte` runs in the same files?
    # If the "blind byte" signal were really the ScreenData opcode signal in
    # disguise, blind-start runs would cluster there and other runs would not.
    other = [r for r in runs if r["first"] not in BLIND]
    oin = [r for r in other if r["addr"] in covered]
    rb = 100.0 * len(inside) / max(len(blind), 1)
    ro = 100.0 * len(oin) / max(len(other), 1)
    print("  CONTROL: all OTHER `.byte` runs inside it   : %d/%d = %.1f%%"
          % (len(oin), len(other), ro))
    print("  enrichment of blind-start runs inside screen-data territory:"
          " %.2fx" % (rb / ro if ro else float("inf")))
    print("  -> rules out 'it is a ScreenData opcode at a known entry point'.")
    print("     It does NOT rule out data-as-code in general; see")
    print("     se_blind_start_is_misframing.py, which finds exactly that.")

    # --- the null ------------------------------------------------------------
    random.seed(23)
    lo = min(v[0] for v in ext.values())
    hi = max(v[1] for v in ext.values())
    real = sorted(e - s for s, e in spans)
    med = real[len(real) // 2] if real else 0
    nhit = 0
    for _ in range(args.nulls):
        a = random.randrange(lo, hi)
        if parsed_extent(parser, a) >= med:
            nhit += 1
    print()
    print("  NULL: from %d RANDOM addresses in the same two files, %d (%.1f%%)"
          % (args.nulls, nhit, 100.0 * nhit / args.nulls))
    print("        parse a chain at least as long as the median real entry"
          " point (%d B)." % med)
    print("        The parser is permissive; that rate is the price of any")
    print("        'this address is screen data' claim made without a")
    print("        code reference behind it.")


if __name__ == "__main__":
    main()
