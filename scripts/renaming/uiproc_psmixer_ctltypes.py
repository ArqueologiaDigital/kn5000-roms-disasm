#!/usr/bin/env python3
r"""Name the PsMixer control-type procedures and their drawing helpers (ui/drawbar_panel_ui.s).

QUESTION / JOB
--------------
PsMixerControlProc (ui/drawbar_panel_ui.s) keeps one 12-byte record per mixer
control at (0x03ea30) + index*12 (Util_SignExtendAndDouble computes the
address) and dispatches every control event through a table of 11 procedure
pointers indexed by the record's word +2 (the control TYPE):

    ld   wa, (xwa+2) / sla wa, 2          ; type * 4
    lda  xbc, (<Table>:24)                ; table in Naka data
    lda  xhl, (xbc+wa)                    ; (lda_dri XHL, 0x07, 0xe4, 0xe0)
    ld   xhl, (xhl) / call (xhl)          ; proc(XWA=window, XBC=event, XDE=param)

with XBC = 0x1c0000d / 0x1c0000e / 0x1c0000f (PsMixer_ControlHelper,
PsMixer_GridLoop, PsMixer_ControlCase4).  The table (v10 0xE9F11C, labelled
only by the positional name Bitmap_DigitD_0x11F0 in
ui_widgets/technichord_string_data.s) points at 11 routines of this file that
had no names -- 8 of them no label at all, 3 the symboliser's
`AudioCtrl_DataBlock_Helper6/7/8`.  This script reads the table from the ROM
(address from the linked image's symbol table, 11 entries, each checked to
land on a line of this file), labels entry i `PsMixer_CtlTypeProc<i>`, writes
a comment listing the table at the first `lda xbc, (<Table>:24)`, and renames
the five drawing helpers those procedures share, from what their code does:

  AudioCtrl_DataBlock          -> PsMixer_DrawFrameBoxWithDividers
      (kept as a second label: shared/positional_labels.s names it)
  AudioCtrl_DataBlock_Helper   -> PsMixer_DrawFrameBox
  AudioCtrl_DataBlock_Helper2  -> PsMixer_DrawCaptionFrame
  AudioCtrl_DataBlock_Helper3  -> PsMixer_CalcRowBandRect
  AudioCtrl_DataBlock_Helper4  -> PsMixer_CalcSwitchPointInFrame
  AudioCtrl_DataBlock_Helper5  -> PsMixer_CalcGridCellPoint

(each gets a header with the computation), through the generated sed script
scripts/renaming/rename_uiproc_psmixer_<image>.sed.  Addresses of every label
it adds are checked against the re-linked image.

RUN
    python3 scripts/renaming/uiproc_psmixer_ctltypes.py --image v10 [--apply]
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

REL = "ui/drawbar_panel_ui.s"
HELPERS = {
    "AudioCtrl_DataBlock": "PsMixer_DrawFrameBoxWithDividers",
    "AudioCtrl_DataBlock_Helper": "PsMixer_DrawFrameBox",
    "AudioCtrl_DataBlock_Helper2": "PsMixer_DrawCaptionFrame",
    "AudioCtrl_DataBlock_Helper3": "PsMixer_CalcRowBandRect",
    "AudioCtrl_DataBlock_Helper4": "PsMixer_CalcSwitchPointInFrame",
    "AudioCtrl_DataBlock_Helper5": "PsMixer_CalcGridCellPoint",
}
HDR = {
    "PsMixer_DrawFrameBoxWithDividers": """\
; -----------------------------------------------------------------------------
; PsMixer_DrawFrameBoxWithDividers(XWA = rect, BC = colour) -- the same box
; as PsMixer_DrawFrameBox, then seven vertical double lines (DrawLine colour
; 248 at x, colour 255 at x+1) at x = 45, 83, ... 273 (`addiw (xsp+12), 37`
; after the +1: a 38-pixel pitch), from y0+2 to y1-2 of the box: eight
; 38-pixel columns.
; Callers: the PsMixer_CtlTypeProc<i> routines below.
; -----------------------------------------------------------------------------""",
    "PsMixer_DrawFrameBox": """\
; -----------------------------------------------------------------------------
; PsMixer_DrawFrameBox(XWA = rect, BC = style/colour) -- GetFrameSPSize(52)
; gives the frame's text size; the rectangle is copied, its y0 moved down by
; that height - 2, and DrawDesignBox(rect, 193, BC) draws it.
; -----------------------------------------------------------------------------""",
    "PsMixer_DrawCaptionFrame": """\
; -----------------------------------------------------------------------------
; PsMixer_DrawCaptionFrame(XWA = rect, XDE = caption string, BC = selected
; flag) -- DrawFrameSP(style 52, colour 242 if BC != 0 else 8) at the rect's
; origin, then DrawStringCentered(caption, colours 247/255, 3) centred
; (GetBoxCenter) in a box the size GetFrameSPSize(52) reports.
; -----------------------------------------------------------------------------""",
    "PsMixer_CalcRowBandRect": """\
; -----------------------------------------------------------------------------
; PsMixer_CalcRowBandRect(XWA = out rect, BC = control index) -- n = index
; mod 5 (`divs wa,5 / ld wa,qwa`); point = GetEditSwPoint(136 + n); out rect =
; x 8..311, y (point.y - 9 - n) .. (point.y + 31 - n), both y shifted by the
; word +4 of the control's 12-byte record at (0x03ea30) + index*12.
; -----------------------------------------------------------------------------""",
    "PsMixer_CalcSwitchPointInFrame": """\
; -----------------------------------------------------------------------------
; PsMixer_CalcSwitchPointInFrame(XWA = frame rect, XBC = out point, DE =
; param) -- n = param mod 8; y = centre of the frame rect (after the same
; GetFrameSPSize(52) caption offset as PsMixer_DrawFrameBox, GetBoxCenter);
; x = GetEditSwPoint(n).x - (2n - 8) - 2.
; -----------------------------------------------------------------------------""",
    "PsMixer_CalcGridCellPoint": """\
; -----------------------------------------------------------------------------
; PsMixer_CalcGridCellPoint(XWA = frame rect, XBC = out point, DE = param) --
; n = param mod 8; inside the frame (caption offset as PsMixer_DrawFrameBox)
; cell width = width/4, cell height = height/8, and
; x = x0 + (2*(n div 4) + 1) * width/4 + 2, y = y0 + (2*(n mod 4) + 1) *
; height/8 + 2: the centre of cell n of a 2-column x 4-row grid.
; -----------------------------------------------------------------------------""",
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    img = L.image(a.image)
    srcroot = os.path.join(ROOT, img["mirror"])
    path = os.path.join(srcroot, REL)
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    amap, rom, syms = L.build(img)
    inv = {}
    for k, v in syms.items():
        inv.setdefault(v, []).append(k)
    # the table symbol: first `lda xbc, (T:24)` after the PsMixer_ControlHelper label
    st = next(i for i, l in enumerate(lines) if l.startswith("PsMixer_ControlHelper:"))
    tab = None
    for l in lines[st:st + 20]:
        m = re.match(r'^\s*lda\s+xbc\s*,\s*\(\s*([A-Za-z_]\w*)\s*:24\s*\)', drc.strip_comment(l))
        if m:
            tab = m.group(1)
            break
    t = syms[tab]
    line_at = {}
    for k, ad in amap.items():
        rel, li = k.rsplit(":", 1)
        li = int(li)
        if rel == REL and not re.match(r'^[A-Za-z_]\w*:', lines[li]):
            line_at[ad] = min(li, line_at.get(ad, 1 << 30))
    entries = []
    for i in range(11):
        o = t - img["base"] + 4 * i
        v = int.from_bytes(rom[o:o + 4], "little")
        if v not in line_at:
            sys.exit("entry %d -> %06X is not a line of %s: refusing" % (i, v, REL))
        entries.append(v)
    ren = dict(HELPERS)
    ins = {}
    planned = {}
    for i, v in enumerate(entries):
        nm = "PsMixer_CtlTypeProc%d" % i
        planned[nm] = v
        old = [n for n in inv.get(v, []) if re.match(r'^AudioCtrl_DataBlock_Helper\d+$', n)]
        if old:
            ren[old[0]] = nm
        elif not any(n.startswith("PsMixer_CtlTypeProc") for n in inv.get(v, [])):
            ins.setdefault(line_at[v], []).append(nm + ":")
        print("  entry %2d -> %06X  %s  (was %s)" % (i, v, nm, inv.get(v, ["no label"])))
    for o, n in HELPERS.items():
        if o in syms:
            planned[n] = syms[o]
    # structural labels `AudioCtrl_DataBlock_<Role><n>` -> `<Routine>_<Role><k>`,
    # Routine = the nearest named entry at or below the label's address
    starts = sorted(planned.items(), key=lambda t: t[1])
    # names another file of this image uses must survive
    other = []
    for dp, dn, fn in os.walk(srcroot):
        for f in fn:
            pth = os.path.join(dp, f)
            if f.endswith(".s") and os.path.relpath(pth, srcroot) != REL:
                other.append("\n".join(drc.strip_comment(x) for x in
                                       open(pth, encoding="latin-1").read().split("\n")))
    other = "\n".join(other)

    def used_elsewhere(n):
        return n in other and re.search(r'(?<![\w.$])' + re.escape(n) + r'(?![\w.$])', other)
    counters = {}
    for n0, v0 in sorted(((n, v) for n, v in syms.items()
                          if n.startswith("AudioCtrl_DataBlock_") and n not in HELPERS
                          and n not in ren and re.search(
                              r'_(Skip|Join|Loop|Epilogue|Entry|Return|Sub)\d*$', n)),
                         key=lambda t: t[1]):
        owner = [nm for nm, st in starts if st <= v0]
        if not owner or v0 >= syms["IvDrawbarProc"] or used_elsewhere(n0):
            continue
        rt = owner[-1]
        role = re.search(r'_(Skip|Join|Loop|Epilogue|Entry|Return|Sub)\d*$', n0).group(1)
        counters[(rt, role)] = counters.get((rt, role), 0) + 1
        k = counters[(rt, role)]
        ren[n0] = "%s_%s%s" % (rt, role, k if k > 1 else "")
    sed = ["# generated by scripts/renaming/uiproc_psmixer_ctltypes.py --image %s" % a.image]
    for o, n in sorted(ren.items(), key=lambda x: -len(x[0])):
        sed.append("s/\\b%s\\b/%s/g" % (o, n))
    if not a.apply:
        print("\n".join(sed))
        return
    open(os.path.join(ROOT, "scripts", "renaming", "rename_uiproc_psmixer_%s.sed" % a.image),
         "w").write("\n".join(sed) + "\n")
    doc = ["; PsMixer control-type procedure table %s (%s 0x%06X, 11 x 32-bit, read from"
           % (tab, a.image, t),
           ";   the ROM by scripts/renaming/uiproc_psmixer_ctltypes.py), indexed by word +2"
           " of the control's record:"]
    doc += [";   %2d -> PsMixer_CtlTypeProc%d" % (i, i) for i in range(11)]
    tab_line = next(i for i in range(st, st + 20)
                    if re.match(r'^\s*lda\s+xbc\s*,\s*\(\s*%s\s*:24' % re.escape(tab), lines[i]))
    ins.setdefault(tab_line, [])
    ins[tab_line] = doc + ins[tab_line]
    out = []
    for i, l in enumerate(lines):
        m = re.match(r'^([A-Za-z_]\w*):(.*)$', l)
        pre = []
        if m and m.group(1) == "AudioCtrl_DataBlock":
            # ONE block for all six helpers: six separate blocks interleaved with
            # v7's runs of identical "; v10 does not spell..." comments make
            # assert_comments_preserved.py's difflib alignment report false losses
            sep = "; " + "-" * 77
            pre.append("")
            pre.append(sep)
            pre.append("; PsMixer drawing helpers (the next ~0x2a0 bytes), shared by the")
            pre.append("; PsMixer_CtlTypeProc<i> control procedures further down:")
            for nm in ("PsMixer_DrawFrameBoxWithDividers", "PsMixer_DrawFrameBox",
                       "PsMixer_DrawCaptionFrame", "PsMixer_CalcRowBandRect",
                       "PsMixer_CalcSwitchPointInFrame", "PsMixer_CalcGridCellPoint"):
                body = [x for x in HDR[nm].split("\n") if not x.startswith("; ---")]
                pre.append(";")
                pre += body
            pre.append(sep)
        if m and m.group(1) == "AudioCtrl_DataBlock":
            pre.append("; AudioCtrl_DataBlock: previous name of this label, kept only because it"
                       " is still referenced by shared/positional_labels.s (owned by another lane)")
            pre.append("AudioCtrl_DataBlock:")
        out += pre + ins.get(i, [])
        code = drc.strip_comment(l)
        com = l[len(code):]
        for o, n in sorted(ren.items(), key=lambda x: -len(x[0])):
            if o in code:
                code = re.sub(r'(?<![\w.$])' + re.escape(o) + r'(?![\w.$])', n, code)
        out.append(code + com)
    open(path, "wb").write("\n".join(out).encode("latin-1"))
    try:
        amap2, rom2, syms2 = L.build(img)
    except (SystemExit, RuntimeError):
        open(path, "wb").write(raw)
        raise
    bad = [(n, v, syms2.get(n)) for n, v in planned.items() if syms2.get(n) != v]
    if bad or syms2.get("AudioCtrl_DataBlock") != syms.get("AudioCtrl_DataBlock"):
        open(path, "wb").write(raw)
        sys.exit("REFUSED: label addresses moved: %s" % bad)
    print("APPLIED: image byte-identical; all %d names at their addresses" % len(planned))


if __name__ == "__main__":
    main()
