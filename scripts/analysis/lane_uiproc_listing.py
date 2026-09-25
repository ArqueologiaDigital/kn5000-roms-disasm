#!/usr/bin/env python3
r"""WHAT ADDRESS AND WHAT ROM BYTES DOES EACH LINE OF A SOURCE FILE EMIT? (any KN5000 image)

QUESTION ANSWERED
-----------------
The sources carry no address comments, so "which bytes does line 8290 of
v10/maincpu/ui/ui_window_procs.s emit, and what does a second decoder make of
them?" has no grep answer.  This tool builds one for a line window of ONE file,
in any image the data census knows (v10 v9 v7 v142 ...), by reusing the census's
marker-label mirror (scripts/analysis/data_range_census.py: mirror_tree +
link_mirror + marker_addresses).  The mirror is proven INERT first: its linked
image must be byte-identical to the dump, otherwise the tool refuses.

It was written for lane `uiproc` (2026-09-25) to re-frame misframed code in
ui_window_procs.s / drawbar_panel_ui.s / ui_mode_handlers.s / ui_widget_defs.s
and to port the result between v10, v9 and v7.

RUN
    # address + bytes of every emitting line in a window
    python3 scripts/analysis/lane_uiproc_listing.py --image v10 \
        --file ui/ui_window_procs.s --lines 8259:8330
    # same, plus MAME unidasm's linear decode of the window's address span
    python3 scripts/analysis/lane_uiproc_listing.py --image v10 \
        --file ui/ui_window_procs.s --lines 8259:8330 --unidasm
    # unidasm only, for an absolute address range of the image
    python3 scripts/analysis/lane_uiproc_listing.py --image v7 --range 0xFAF73B:0xFB075B
    # where does a label live?
    python3 scripts/analysis/lane_uiproc_listing.py --image v10 --label ColorBlit2_LargeCodeBlock
    # save / load the (file,line)->address map (one link per image, ~20 s)
    python3 scripts/analysis/lane_uiproc_listing.py --image v10 --save-map /tmp/x.json

OUTPUT FORMAT (line mode)
    <lineno> <address> <hex bytes> | <source text>
Non-emitting lines (comments, labels alone) print with a blank address.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import data_range_census as drc  # noqa: E402

UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
if not os.path.exists(UNIDASM):
    UNIDASM = os.path.expanduser("~/compartilhado/mame/unidasm")


def image(key):
    for img in drc.IMAGES:
        if img["key"] == key:
            return img
    sys.exit("unknown image %r" % key)


def build(img):
    """-> (addr_of[(rel,lineno0)], rom bytes, elf symbols {name: addr})"""
    tmp = tempfile.mkdtemp(prefix="uiproc-map-")
    try:
        mdir = os.path.join(tmp, "mirror")
        marks = drc.mirror_tree(os.path.join(ROOT, img["mirror"]), mdir)
        elf = drc.link_mirror(mdir, img, tmp)
        raw = os.path.join(tmp, "img.bin")
        drc.sh([drc.OBJCOPY, "-O", "binary", elf, raw])
        got = open(raw, "rb").read()
        rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
        if "split" not in img and got[:len(rom)] != rom:
            sys.exit("REFUSED: mirror image is not byte-identical to %s" % img["rom"])
        ma = drc.marker_addresses(elf)
        amap = {}
        for n, (rel, li) in enumerate(marks):
            if n in ma:
                amap["%s:%d" % (rel, li)] = ma[n]
        syms = {}
        for line in drc.sh([drc.NM, "-n", elf]).split("\n"):
            p = line.split()
            if len(p) >= 3 and not p[2].startswith(drc.MARK):
                syms[p[2]] = int(p[0], 16)
        return amap, rom, syms
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def unidasm(rom, img, a, b):
    off = a - img["base"]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(rom[off:off + (b - a)])
        p = f.name
    try:
        r = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", hex(a)],
                           capture_output=True, text=True)
        return r.stdout
    finally:
        os.unlink(p)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file")
    ap.add_argument("--lines")
    ap.add_argument("--range")
    ap.add_argument("--label", action="append")
    ap.add_argument("--unidasm", action="store_true")
    ap.add_argument("--save-map")
    ap.add_argument("--load-map")
    a = ap.parse_args()
    img = image(a.image)
    if a.load_map:
        d = json.load(open(a.load_map))
        amap, syms = d["amap"], d["syms"]
        rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    else:
        amap, rom, syms = build(img)
    if a.save_map:
        json.dump({"amap": amap, "syms": syms}, open(a.save_map, "w"))
    for lab in a.label or []:
        print(lab, hex(syms[lab]) if lab in syms else "(not defined)")
    if a.file and a.lines:
        lo, hi = [int(x) for x in a.lines.split(":")]
        src = open(os.path.join(ROOT, img["mirror"], a.file), encoding="latin-1").read().split("\n")
        # address of each emitting line; its size = next emitting line's address - own
        emit = sorted((amap[k], int(k.rsplit(":", 1)[1])) for k in amap
                      if k.rsplit(":", 1)[0] == a.file)
        nxt = {}
        for i, (ad, li) in enumerate(emit):
            nxt[li] = emit[i + 1][0] if i + 1 < len(emit) else ad
        first = last = None
        for li in range(lo - 1, min(hi, len(src))):
            k = "%s:%d" % (a.file, li)
            if k in amap:
                ad = amap[k]
                n = nxt[li] - ad
                off = ad - img["base"]
                bs = rom[off:off + n] if n > 0 else b""
                hx = " ".join("%02x" % x for x in bs[:12]) + (" .." if n > 12 else "")
                print("%6d %06X %-38s| %s" % (li + 1, ad, hx, src[li]))
                if n > 0:
                    first = ad if first is None else first
                    last = ad + n
            else:
                print("%6d %6s %-38s| %s" % (li + 1, "", "", src[li]))
        if a.unidasm and first is not None:
            print("---- unidasm %06X-%06X" % (first, last))
            print(unidasm(rom, img, first, last))
    if a.range:
        s, e = [int(x, 16) for x in a.range.split(":")]
        print(unidasm(rom, img, s, e))


if __name__ == "__main__":
    main()
