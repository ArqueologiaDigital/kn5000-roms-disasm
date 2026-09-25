#!/usr/bin/env python3
r"""WHICH SOURCE LINE EMITS WHICH ADDRESS -- for v10, v9 AND v7, one file set.

QUESTION ANSWERED
-----------------
`scripts/analysis/address_line_map.py` answers "which line emits address X"
for v10 only.  Lane `seui` works the same file set in v10, v9 and v7, so it
needs the same map for all three.  This reuses the census's own proven-inert
mirror (`data_range_census.census_image`: every byte-emitting line gets a
marker label, the mirror is linked with the real linker script, and the run
ABORTS unless the mirror still objcopies to the original dump) and writes the
spans that fall in the requested files.

OUTPUT: JSON list of [addr, end, rel, line0] (line0 is 0-based), sorted by addr.

RUN
    python3 scripts/lanes/seui/seui_amap.py --image v10 --out /tmp/claude-1000/lane-seui/amap_v10.json \
        [--files audio/sound_editor_ui.s,audio/semenu_routines.s]
"""
import argparse, json, os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--files", default="")
    a = ap.parse_args()
    img = [i for i in drc.IMAGES if i["key"] == a.image][0]
    want = set(f for f in a.files.split(",") if f)
    with tempfile.TemporaryDirectory(prefix="seui-amap-") as tmp:
        c = drc.census_image(img, tmp, verbose=False)
    if not c["inert"]:
        sys.exit("mirror is NOT byte-identical to the dump -- map refused")
    out = [[s[0], s[1], s[2], s[3]] for s in c["spans"] if not want or s[2] in want]
    json.dump(out, open(a.out, "w"))
    print("%s: %d spans written to %s (mirror inert)" % (a.image, len(out), a.out))


if __name__ == "__main__":
    main()
