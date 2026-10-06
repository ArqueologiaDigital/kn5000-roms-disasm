#!/usr/bin/env python3
r"""name_widget_value_cells.py -- name the work-RAM cells that UI edit boxes keep their values in (v10/v9/v7).

QUESTION ANSWERED
-----------------
naka_sequencer_channels.c is the work-RAM initial image: Boot_InitWorkRAM copies blob +0x0..+0x19EE to RAM 0x3DCD4
(copy 1; RAM = 0x3DCD4 + offset).  Many NAKA edit-box widgets (AcLswPartEditBox, AcRamEditBox, AcBitEditBox ...)
carry a `data` field (type character 'n') that is the RAM address of their value cell: SdpartMain's PAN box points
at 0x3E6AC, its REV. DEPTH box at 0x3E6B0, and so on.  In the C image those cells were zero `pad_N` runs or
`field_XXXX` words.
For every widget record in a v10 naka_*.c blob whose `.data` is a RAM address inside copy 1, this script names
the cell at that offset after the widget: <view>_<Caption>_Value, where <view> is the widget label's prefix
(SdpartMain_AcLswPartEditBox_2 -> SdpartMain) and <Caption> its caption text in CamelCase ("REV. DEPTH :" ->
RevDepth).  A widget without a usable caption gives <widget label>_Value.  A zero pad that holds cells is cut at
each cell address.  Each piece runs to the next cell or to the end of the pad, keeps its zero bytes, and is
declared `uint8_t <name>[n]`.  A remainder before the first cell keeps the pad's name.  A non-pad placeholder that
starts exactly at a cell is renamed.  Anything else (a cell inside a named member, or inside a non-pad member) is
listed and left.  The extent claims only "from this cell to the next", not the cell's size.
v9 and v7 take v10's plan where their C file has the same members at the same offsets.

RUN (repository root)
    python3 scripts/converters/name_widget_value_cells.py [--apply]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all;
    assert_c_comments_preserved.py --base HEAD --allow '/\* (zero padding|\d+ pointers) \*/'
"""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
APPLY = "--apply" in sys.argv
_a, sys.argv = sys.argv, sys.argv[:1]
import nakarest_c_model as M      # noqa: E402
import semantic_score as SS       # noqa: E402
sys.argv = _a
IMG0, IMGN = 0x3DCD4, 0x19EE
TARGET = "naka_sequencer_channels.c"


def camel(caption):
    words = re.findall(r'[A-Za-z0-9]+', caption or "")
    return "".join(w.capitalize() if not w.isdigit() else w for w in words)


def cells_v10():
    out = {}
    for c in sorted(glob.glob(os.path.join(ROOT, "v10/maincpu/ui_widgets/naka_*.c"))):
        t = open(c, encoding="latin-1").read()
        for m in re.finditer(r'\n    \.(\w+) = \{\s*\n((?:\s+\.\w+ = [^\n]*\n)+?)\s*\}', t):
            body = m.group(2)
            d = re.search(r'\.data = (0x[0-9A-Fa-f]+)', body)
            if not d:
                continue
            a = int(d.group(1), 16)
            if not IMG0 <= a < IMG0 + IMGN:
                continue
            cap = re.search(r'\.caption = SELF\((\w+)\)', body)
            text = None
            if cap:
                mm = re.search(r'\.%s = (?:ALIGNED_STRING\()?"((?:[^"\\]|\\.)*)"' % cap.group(1), t)
                text = mm.group(1) if mm else None
            lab = m.group(1)
            view = re.split(r'_(?:Ac|Iv|Ps|Vw)[A-Z]', lab)[0]
            cc = camel(text)
            name = ("%s_%s_Value" % (view, cc)) if cc and view != lab else "%s_Value" % lab
            assert a - IMG0 not in out, (hex(a), lab)
            out[a - IMG0] = name
    names = list(out.values())
    dup = {n for n in names if names.count(n) > 1}
    for off in [o for o, n in out.items() if n in dup]:      # two boxes with one caption on one view: disambiguate
        out[off] = out[off][:-len("_Value")] + "_%04X_Value" % off
    return out


def plan(cb, cells):
    """-> list of (member start, member end, [NewMember]) and a list of skipped cells"""
    ops, skipped = [], []
    by_member = {}
    for off, name in sorted(cells.items()):
        mb = next((x for x in cb.members if x.offset <= off < x.offset + x.size), None)
        if mb is None:
            skipped.append((off, name, "no member"))
            continue
        by_member.setdefault(mb.name, (mb, []))[1].append((off, name))
    for mname, (mb, lst) in sorted(by_member.items(), key=lambda kv: kv[1][0].offset):
        if not SS.placeholder_field(mb.name):
            skipped.extend((o, n, "inside named member %s" % mb.name) for o, n in lst)
            continue
        if re.match(r'^_?pad_\d+$', mb.name):
            pieces = []
            if lst[0][0] > mb.offset:
                pieces.append((mb.offset, lst[0][0], mb.name))
            for k, (o, n) in enumerate(lst):
                end = lst[k + 1][0] if k + 1 < len(lst) else mb.offset + mb.size
                pieces.append((o, end, n))
            ops.append((mb.offset, mb.offset + mb.size, pieces))
        elif lst == [(mb.offset, lst[0][1])] or (len(lst) == 1 and lst[0][0] == mb.offset):
            ops.append((mb.offset, mb.offset + mb.size, [("rename", mb.name, lst[0][1])]))
        else:
            skipped.extend((o, n, "inside non-pad member %s" % mb.name) for o, n in lst)
    return ops, skipped


def main():
    cells = cells_v10()
    print("v10: %d widget value cells in the RAM image" % len(cells))
    for tree in ("v10", "v9", "v7"):
        p = os.path.join(ROOT, tree, "maincpu/ui_widgets", TARGET)
        blob = open(os.path.join(ROOT, tree, "maincpu/includes/generated", TARGET[:-2] + ".bin"), "rb").read()
        cb = M.CBlob(p)
        ops, skipped = plan(cb, cells)
        done = 0
        renames = {}
        for start, end, pieces in ops:
            if pieces[0][0] == "rename":
                _, old, new = pieces[0]
                renames[old] = new
                done += 1
                continue
            new = []
            for a, b, n in pieces:
                assert not any(blob[a:b]), (tree, n, "non-zero")
                new.append(M.NewMember("uint8_t", n, "[%d]" % (b - a), b - a, "{ 0 }", []))
            cb.retype(start, end, new, blob)
            done += sum(1 for _, _, n in pieces if n.endswith("_Value"))
        text = cb.render()
        if renames:
            from name_resname_strings import segments
            rx = re.compile(r'\b(%s)\b' % "|".join(map(re.escape, renames)))
            text = "".join(rx.sub(lambda m: renames[m.group(1)], s) if k == "code" else s for k, s in segments(text))
        print("%s: %d cells named, %d left: %s" % (tree, done, len(skipped),
                                                    "; ".join("%s (%s)" % (n, why) for _, n, why in skipped)))
        if APPLY:
            data = text.encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
