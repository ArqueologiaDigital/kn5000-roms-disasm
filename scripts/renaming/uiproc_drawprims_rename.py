#!/usr/bin/env python3
r"""Split `ColorBlit2_LargeCodeBlock` (ui/ui_window_procs.s) into its real routines.

QUESTION / JOB
--------------
The 4,128-byte block at the end of ui/ui_window_procs.s (v10/v9 0xFAFB48, v7
0xFAF73B; identical layout in all three) was one coarse label with ~150
structural labels (`_Join15`, `_Loop6`, `_Skip20`, ...) inherited from three
unrelated names (`ColorBlit2_LargeCodeBlock_*`, `DrawText_LayoutAndRender_
Variant1_Helper*`, `Voice_FactoryPresetData_Code_Helper*`).  Read from the ROM
(see the headers this script writes) it is three drawing primitives, each in
the draw-task idiom of drawing_primitives.s (wrapper -> _DeferredPath ->
_Return -> _ParamBlock callback -> _Impl):

  +0x000  DrawMonoBitmap            1-bpp bitmap blit in fg/bg colours
  +0x385  DrawLineWithMode          line between two points, draw-mode aware
  +0xB6E  DrawDottedLineWithMode    the same with a 2-on/3-off pixel pattern

This script derives every new name from the label's OFFSET inside the block
(the three images link the block at different addresses but with identical
layout), writes the sed script `scripts/renaming/rename_uiproc_drawprims_<img>.sed`
(CLAUDE.md: renames go through a sed script) and applies it, then inserts the
three `_ParamBlock` labels (the callback entry points the wrappers queue; until
now reachable only as `ColorBlit2_LargeCodeBlock + 101/1008/3033` .set names in
shared/positional_labels.s) and the routine headers.

A label that another file names (graphics_text_vga.s, positional_labels.s,
the image's root .s that continues the dotted-line routine) is KEPT as a second
label on the same line position, with a comment naming the referencing file:
those files belong to other lanes and are not edited here.

Structural labels inside each _Impl are renumbered per routine
(`<Routine>_Impl_<Role><n>`, role kept from the symboliser's name), except the
draw-mode dispatch targets, which get semantic names.

RUN
    python3 scripts/renaming/uiproc_drawprims_rename.py --image v10 [--dry-run]
Then: make gate, assert_comments_preserved.py.
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import lane_uiproc_listing as L  # noqa: E402

REL = "ui/ui_window_procs.s"
# (offset, name) of every boundary the headers describe
FIXED = {
    0x000: "DrawMonoBitmap",
    0x032: "DrawMonoBitmap_DeferredPath",
    0x061: "DrawMonoBitmap_Return",
    0x065: "DrawMonoBitmap_ParamBlock",
    0x087: "DrawMonoBitmap_Impl",
    0x220: "DrawMonoBitmap_Impl_Mode1",
    0x2CE: "DrawMonoBitmap_Impl_Mode2",
    0x37A: "DrawMonoBitmap_Impl_Done",
    0x385: "DrawLineWithMode",
    0x3B7: "DrawLineWithMode_DeferredPath",
    0x3EC: "DrawLineWithMode_Return",
    0x3F0: "DrawLineWithMode_ParamBlock",
    0x412: "DrawLineWithMode_Impl",
    0x84C: "DrawLineWithMode_Impl_Mode1",
    0x9D3: "DrawLineWithMode_Impl_Mode2",
    0xB44: "DrawLineWithMode_Impl_Done",
    0xB6E: "DrawDottedLineWithMode",
    0xBA0: "DrawDottedLineWithMode_DeferredPath",
    0xBD5: "DrawDottedLineWithMode_Return",
    0xBD9: "DrawDottedLineWithMode_ParamBlock",
    0xBFB: "DrawDottedLineWithMode_Impl",
}
# the old positional .set names (shared/positional_labels.s) of the callbacks
POSITIONAL = {"ColorBlit2_LargeCodeBlock_0x65": 0x065,
              "ColorBlit2_LargeCodeBlock_0x3F0": 0x3F0,
              "ColorBlit2_LargeCodeBlock_0xBD9": 0xBD9}
IMPL_RANGES = [(0x087, 0x385, "DrawMonoBitmap_Impl"),
               (0x412, 0xB6E, "DrawLineWithMode_Impl"),
               (0xBFB, 0x10000, "DrawDottedLineWithMode_Impl")]
ROLE_RE = re.compile(r'_(Skip|Join|Loop|Epilogue|Entry|Helper|Return|Sub)\d*$')

HEADERS = {
    "DrawMonoBitmap": """\
; =============================================================================
; DrawMonoBitmap - draw a 1-bpp bitmap into OFFSCREEN_BUFFER_1 in fg/bg colours
;
; Input:
;   XWA = pointer to a rectangle: word[0]=x0, word[2]=y0, word[4]=x1, word[6]=y1
;   XBC = pointer to the bitmap: one byte per (8-pixel column group, row),
;         MSB = leftmost pixel; for each group x = 0, 8, 16 .. < x1-x0 the
;         rows y = 0 .. < y1-y0 are consumed in order (column-major strips)
;   DE  = foreground colour (used where a bit is 1)
; The background colour (bit 0) is the word at 0x03efa2 (stored by
; DirmdEmulator_Dispatch_Code_Helper in display/graphics_text_vga.s).
; Colour 0xf5 means "copy the pixel from the buffer whose address is at
; 0x030452" instead of writing a fixed colour (the same convention as DrawLine).
;
; Same draw-task idiom as DrawLine / DrawBox (ui/drawing_primitives.s): the
; draw mode byte at 0x03efa8 is latched into 0x03efaa; if the caller is not the
; draw task (IS_XSP_INSIDE_4K_REGION_AT_1C032 returns 0) the call is queued as a
; 20-byte DrawQueue_Alloc record {+0 DrawMonoBitmap_ParamBlock, +4 rect (4
; words), +12 bitmap pointer, +16 colour, +18 draw mode} and executed later by
; DisplayCmd_DequeueAndExecute; nothing is drawn while the word at 0x03044e is 0.
;
; DrawMonoBitmap_Impl dispatches on the latched draw mode (0x03efaa):
;   0  pixel = (pixel & 0x60) | (colour & 0x9f)   -- bits 5-6 of the buffer
;      pixel are preserved, the rest is the colour
;   1  bit 5 of the pixel := its bit 7 XOR the bitmap bit   (_Impl_Mode1)
;   2  bit 6 likewise                                       (_Impl_Mode2)
;   other  nothing is drawn
; and always finishes with SetChangeRect(rect).
; Derived from the ROM code below ({img} 0x{a0:06X}); caller:
; display/graphics_text_vga.s (the character-cell renderer that divides a cell
; index by 40 and multiplies by 8 to build the rectangle).
; =============================================================================
""",
    "DrawLineWithMode": """\
; =============================================================================
; DrawLineWithMode - draw a line between two points, honouring the draw mode
;
; Input:
;   XWA = pointer to point A: word[0]=x, word[2]=y
;   XBC = pointer to point B: word[0]=x, word[2]=y
;   DE  = colour (0xf5 = copy the pixel from the buffer at (0x030452))
;
; Wrapper / deferred path as in DrawMonoBitmap, with a 16-byte queue record
; {+0 DrawLineWithMode_ParamBlock, +4 point A, +8 point B, +12 colour,
; +14 draw mode}.
;
; DrawLineWithMode_Impl returns at once unless IsPointOnScreen accepts both
; points and at least one delta is non-zero.  It walks the longer axis one
; pixel at a time and the other in 16.16 fixed point: the slope comes from
; Math_DivideSigned32 on the delta shifted left 16 (`sla 0` = 16), rounded by
; adding 0x8000.  Pixel writes follow the latched draw mode (0x03efaa): 0 writes
; the colour into bits 0-4,7 keeping bits 5-6 (as DrawMonoBitmap); 1 sets or
; clears bit 5 (_Impl_Mode1) and 2 bit 6 (_Impl_Mode2) according to the pixel's
; bit 7 -- the axis-aligned paths and the general path use OPPOSITE polarity
; (set-if-bit7 vs clear-if-bit7), as the ROM has it; other modes draw nothing.
; It ends with SetChangeRect over the rectangle spanned by the two points
; (_Impl_Done).  DrawLine's wrapper (ui/drawing_primitives.s) does not latch the
; draw mode byte; this one does.
; Derived from the ROM code below ({img} 0x{a1:06X}).  Callers:
; display/graphics_text_vga.s (as DrawText_LayoutAndRender_Variant1_Helper) and,
; directly into _Impl, the image's root .s (as
; Voice_FactoryPresetData_Code_Helper).
; =============================================================================
""",
    "DrawDottedLineWithMode": """\
; =============================================================================
; DrawDottedLineWithMode - DrawLineWithMode with a dotted pattern
;
; Same inputs, queue record layout (+0 DrawDottedLineWithMode_ParamBlock) and
; algorithm as DrawLineWithMode, plus a pattern counter at (xsp+0x18) of the
; _Impl frame: per pixel step, counter 0 and 1 draw and increment, 2 and 3 skip
; and increment, and at 4 the counter is reset to 0 WITHOUT drawing or
; incrementing -- two pixels on, three off.  The draw-mode test is made per
; pixel inside the loop.
; The routine continues past the end of this file into the image's root .s
; (kn5000_{img}_program.s), which branches back into it.
; Derived from the ROM code below ({img} 0x{a2:06X}).  Caller:
; display/graphics_text_vga.s (as DrawText_LayoutAndRender_Variant1_Helper2).
; =============================================================================
""",
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    img = L.image(a.image)
    srcroot = os.path.join(ROOT, img["mirror"])
    path = os.path.join(srcroot, REL)
    amap, rom, syms = L.build(img)
    base = syms["ColorBlit2_LargeCodeBlock"]
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("ColorBlit2_LargeCodeBlock:"))
    labs = []                                   # (offset, name, line)
    for i in range(start, len(lines)):
        m = re.match(r'^([A-Za-z_][\w]*):', lines[i])
        if m:
            labs.append((amap["%s:%d" % (REL, i)] - base, m.group(1), i))
    # external references (other files of this image)
    names = set(n for o, n, i in labs)
    ext = {}
    for dp, dn, fn in os.walk(srcroot):
        for f in fn:
            p = os.path.join(dp, f)
            if not f.endswith(".s") or os.path.relpath(p, srcroot) == REL:
                continue
            t = open(p, encoding="latin-1").read()
            for n in names:
                if n in t and re.search(r'(?<![\w.$])' + re.escape(n) + r'(?![\w.$])', t):
                    ext.setdefault(n, []).append(os.path.relpath(p, srcroot))
    # new names
    new = {}
    counters = {}
    for off, n, i in sorted(labs):
        if off in FIXED and FIXED[off] not in new.values():
            new[n] = FIXED[off]
            continue
        rng = next((r for r in IMPL_RANGES if r[0] <= off < r[1]), None)
        if rng is None:
            sys.exit("label %s at +0x%X is outside every routine range" % (n, off))
        m = ROLE_RE.search(n)
        role = m.group(1) if m else "Label"
        k = (rng[2], role)
        counters[k] = counters.get(k, 0) + 1
        new[n] = "%s_%s%s" % (rng[2], role, counters[k] if counters[k] > 1 else "")
    assert len(set(new.values())) == len(new), "name collision"
    sed = ["# generated by scripts/renaming/uiproc_drawprims_rename.py --image %s" % a.image]
    for old, nn in sorted(new.items(), key=lambda t: -len(t[0])):
        if old != nn:
            sed.append("s/\\b%s\\b/%s/g" % (old, nn))
    for old, off in POSITIONAL.items():
        sed.append("s/\\b%s\\b/%s/g" % (old, FIXED[off]))
    sedpath = os.path.join(ROOT, "scripts", "renaming", "rename_uiproc_drawprims_%s.sed" % a.image)
    for off, n, i in labs:
        print("  +0x%03X %-50s -> %s%s" % (off, n, new[n],
                                          ("   [kept: %s]" % ", ".join(ext[n])) if n in ext else ""))
    if a.dry_run:
        print("\n".join(sed))
        return
    open(sedpath, "w").write("\n".join(sed) + "\n")
    # apply the sed rules to the block (only: the file's earlier routines are
    # untouched, and no rule name occurs there -- asserted)
    body = "\n".join(lines[start:])
    head = "\n".join(lines[:start])
    for old, nn in list(new.items()) + [(o, FIXED[f]) for o, f in POSITIONAL.items()]:
        assert not re.search(r'(?<![\w.$])' + re.escape(old) + r'(?![\w.$])', head), old
    for rule in sed[1:]:
        m = re.match(r's/\\b(.*)\\b/(.*)/g', rule)
        body = re.sub(r'\b%s\b' % re.escape(m.group(1)), m.group(2), body)
    out = body.split("\n")
    # label lines for the three param blocks, inserted before the line that
    # emits the byte at that offset
    addr_line = {}
    for i in range(start, len(lines)):
        k = "%s:%d" % (REL, i)
        if k in amap and not re.match(r'^[A-Za-z_][\w]*:', lines[i]):
            addr_line.setdefault(amap[k] - base, i - start)
    inserts = {}
    missing = []
    for off in sorted(FIXED):
        if FIXED[off] in [new[n] for o, n, i in labs]:
            continue
        # no label at this boundary yet (v7: nothing in this file branches to
        # the B/C wrappers, their callers use numeric calr): insert one
        inserts.setdefault(addr_line[off], []).append(FIXED[off] + ":")
        missing.append((off, FIXED[off]))
    # headers + kept old names before each routine entry, and old names kept
    # for other files before interior labels
    for off, n, i in labs:
        li = i - start
        pre = []
        nn = new[n]
        if nn in HEADERS:
            pre.append("")
            hdr = HEADERS[nn].replace("{img}", a.image)
            for k, o in (("{a0:06X}", 0x000), ("{a1:06X}", 0x385), ("{a2:06X}", 0xB6E)):
                hdr = hdr.replace(k, "%06X" % (base + o))
            if a.image == "v7":
                # v7's other files call these wrappers by NUMERIC calr (the
                # block was a verbatim romslice until 2026-09-25), and the old
                # helper names belong to other routines there
                hdr = hdr.replace(
                    "display/graphics_text_vga.s (as DrawText_LayoutAndRender_Variant1_Helper) and,\n"
                    "; directly into _Impl, the image's root .s (as\n"
                    "; Voice_FactoryPresetData_Code_Helper).",
                    "display/graphics_text_vga.s and, directly into _Impl, the image's root .s\n"
                    "; (both by numeric `calr` in v7: their files are another lane's).")
                hdr = hdr.replace("_program.s), which branches back into it.", "_program.s).")
                hdr = hdr.replace(
                    "display/graphics_text_vga.s (as DrawText_LayoutAndRender_Variant1_Helper2).",
                    "display/graphics_text_vga.s (by numeric `calr` in v7).")
            pre += hdr.rstrip("\n").split("\n")
        if n in ext and n != nn:
            pre.append("; %s: previous name of this label, kept only because it is "
                       "still referenced by %s (owned by another lane)"
                       % (n, " and ".join(sorted(set(ext[n])))))
            pre.append(n + ":")
        if pre:
            inserts.setdefault(li, [])
            inserts[li] = pre + inserts[li]
    for off, nn in missing:
        if nn in HEADERS:
            hdr = HEADERS[nn].replace("{img}", a.image)
            for k, o in (("{a0:06X}", 0x000), ("{a1:06X}", 0x385), ("{a2:06X}", 0xB6E)):
                hdr = hdr.replace(k, "%06X" % (base + o))
            if a.image == "v7":
                hdr = hdr.replace("_program.s), which branches back into it.", "_program.s).")
                hdr = hdr.replace(
                    "display/graphics_text_vga.s (as DrawText_LayoutAndRender_Variant1_Helper) and,\n"
                    "; directly into _Impl, the image's root .s (as\n"
                    "; Voice_FactoryPresetData_Code_Helper).",
                    "display/graphics_text_vga.s and, directly into _Impl, the image's root .s\n"
                    "; (both by numeric `calr` in v7: their files are another lane's).")
                hdr = hdr.replace(
                    "display/graphics_text_vga.s (as DrawText_LayoutAndRender_Variant1_Helper2).",
                    "display/graphics_text_vga.s (by numeric `calr` in v7).")
            li = addr_line[off]
            inserts[li] = [""] + hdr.rstrip("\n").split("\n") + inserts[li]
    res = []
    for li, l in enumerate(out):
        res += inserts.get(li, [])
        res.append(l)
    newtext = head + "\n" + "\n".join(res)
    open(path, "wb").write(newtext.encode("latin-1"))
    print("wrote %s and %s" % (os.path.relpath(sedpath, ROOT), os.path.relpath(path, ROOT)))
    amap2, rom2, syms2 = L.build(img)       # refuses unless byte-identical
    print("image %s byte-identical after the rename" % a.image)


if __name__ == "__main__":
    main()
