#!/usr/bin/env python3
r"""UNDO FALSE SYMBOLS: event-target OBJECT HANDLES that a positional pass turned into ROM labels.

QUESTION / JOB
--------------
`SendEvent(XWA = target, XBC = event, XDE = param)` (ui/ui_widget_defs.s) does
not dereference XWA: unless it is 0xffffffff (current target) it takes
bits 16-27 of it as a CLASS index -- `srl xwa,16 / and xwa,0xfff`, times 14,
into the class table at RAM 0x027ed6 -- and calls that class's procedure with
the whole value.  XWA is an object HANDLE: class in the high word, instance in
the low word (0x5b0009, 0x1600004 ...).  Handles of classes 0xE0-0xFF fall in
the ROM's address range, and an earlier positional-label pass (commit
bb836bf7) rewrote them as symbols: `ld xwa, StringData_APCModeNames_0x160`
(= 0xF00001, class 0xF0 instance 1) before `ld xbc, 0x1c0000f / call
SendEvent`.  Those are false cross-references -- nothing is read at that
address -- and they send a reader to a string table that has nothing to do
with the code (lane scoop flagged the four APCModeNames ones).

This tool finds `ld xwa, <Symbol>` lines whose value lies in 0xE00000-0xFFFFFF
and which, within the next four lines, load an event code into XBC
(0x1cxxxxx / 0x1dxxxxx / 0x1exxxxx) and transfer to a routine whose name
contains SendEvent or PostEvent, and replaces the symbol by its numeric value
with a comment naming the class and instance.  The value is read from the
linked image, and the image is re-linked and compared after the edit.

RUN
    python3 scripts/converters/lane_uiproc_event_handles.py --image v10 --file ui/drawbar_panel_ui.s [--apply]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc  # noqa: E402
import lane_uiproc_listing as L  # noqa: E402

LD = re.compile(r'^(\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?ld\s+xwa\s*,\s*)([A-Za-z_][\w]*)(\s*)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    img = L.image(a.image)
    path = os.path.join(ROOT, img["mirror"], a.file)
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    amap, rom, syms = L.build(img)
    hits = []
    for i, l in enumerate(lines):
        code = drc.strip_comment(l)
        m = LD.match(code)
        if not m or m.group(2).lower().startswith("x"):
            continue
        v = syms.get(m.group(2))
        if v is None or not (0xE00000 <= v <= 0xFFFFFF):
            continue
        nxt = [drc.strip_comment(x).strip() for x in lines[i + 1:i + 5]]
        evt = any(re.match(r'^ld\s+xbc\s*,\s*0x1[cde][0-9a-f]{5}$', x) for x in nxt)
        call = any(re.match(r'^(call|jp|jr|jrl)\s+(\w+\s*,\s*)?\w*(SendEvent|PostEvent)\w*$', x)
                   for x in nxt)
        if evt and call:
            hits.append((i, m, v))
    for i, m, v in hits:
        print("  %6d  %-50s -> 0x%06x (class 0x%03x, instance %d)" % (
            i + 1, drc.strip_comment(lines[i]).strip(), v, (v >> 16) & 0xfff, v & 0xffff))
    print("%s %s: %d event-target handles written as ROM symbols" % (a.image, a.file, len(hits)))
    if not a.apply or not hits:
        return
    new = list(lines)
    ins = {}
    for i, m, v in hits:
        code = drc.strip_comment(lines[i])
        comment = lines[i][len(code):].strip()
        ins[i] = ("\t; object handle 0x%06x = class 0x%03x, instance %d (SendEvent indexes its "
                  "class table by bits 16-27; not an address -- was %s)"
                  % (v, (v >> 16) & 0xfff, v & 0xffff, m.group(2)))
        new[i] = m.group(1) + "0x%06x" % v + (("\t" + comment) if comment else "")
    out = []
    for i, l in enumerate(new):
        if i in ins:
            out.append(ins[i])
        out.append(l)
    open(path, "wb").write("\n".join(out).encode("latin-1"))
    try:
        L.build(img)
    except SystemExit:
        open(path, "wb").write(raw)
        raise
    print("APPLIED; image byte-identical")


if __name__ == "__main__":
    main()
