#!/usr/bin/env python3
r"""name_resname_strings.py -- name the NAKA C members that are a widget's resource-name string (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  The firmware registers each Viewable table (widget records) together with a ResName table at slot + 0x300
  (scripts/analysis/nakarest_objtab_map.py, from the RegObjTabl calls).  Element k of the ResName table points
  at the name string of element k of the Viewable table.  Most widgets have no name: their entry points at an
  empty string of their own ("" + 0xFF pad, 2 bytes).  In the C sources those strings were `str_N` members
  (semantic_score counts them as placeholders): 1,964 in v10.
  For every ResName entry whose string is the start of a placeholder C member, and which is the only entry
  pointing there, this script renames the member to ResName_<widget>.  <widget> is the label at that element's
  widget record with its NakaWidget_ prefix dropped (NakaWidget_KuboView00A_7_EffectBox ->
  ResName_KuboView00A_7_EffectBox).  It skips an element whose record has no label exactly at its address.  The
  declaration, the designated initializer and every SELF(<member>) in the same C file are renamed.
  The map comes from v10.  v9 and v7 get the same renames only where their C file has the same member at the
  same offset with the same size, and their own bytes there hold an empty string (asserted per member).

RUN (repository root; built tree, for the ELF the map reads)
  python3 scripts/converters/name_resname_strings.py [--apply]
  then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all;
  C comment gate (comments are not touched).
"""
import collections
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
import nakarest_objtab_map as OM   # noqa: E402
import nakarest_c_model as M       # noqa: E402
import semantic_score as SS        # noqa: E402
sys.argv = _a


def members(tree):
    """address (v10 BASE space of the C file) -> (C path, member); and per file {name: (offset, size)}"""
    mem, layout = {}, {}
    for c in sorted(glob.glob(os.path.join(ROOT, tree, "maincpu/ui_widgets/naka_*.c"))):
        t = open(c, encoding="latin-1").read()
        mb = re.search(r'#define BASE\s+0x([0-9A-Fa-f]+)', t)
        if not mb:
            continue
        try:
            cb = M.CBlob(c)
        except BaseException:
            continue
        base = int(mb.group(1), 16)
        layout[os.path.basename(c)] = {x.name: (x.offset, x.size) for x in cb.members}
        for x in cb.members:
            mem[base + x.offset] = (os.path.basename(c), x.name, x.size, x.offset)
    return mem, layout


def plan_v10():
    m = OM.Map("v10")
    view = {r["slot"]: r for r in m.regs if OM.CLASS.get(r["cls"]) == "Viewable"}
    users = collections.defaultdict(list)
    for r in m.regs:
        if OM.CLASS.get(r["cls"]) != "ResName":
            continue
        v = view.get(r["slot"] - 0x300)
        ents, vents = m.entries(r), (m.entries(v) if v else [])
        for k, a in enumerate(ents):
            users[a].append(vents[k] if k < len(vents) else None)
    mem, _ = members("v10")
    ren = collections.defaultdict(dict)        # file -> {old: (new, offset, size)}
    skipped = collections.Counter()
    for a, ws in sorted(users.items()):
        if a not in mem:
            continue
        f, old, size, off = mem[a]
        if not SS.placeholder_field(old):
            continue
        if len(ws) != 1 or ws[0] is None:
            skipped["shared or no record"] += 1
            continue
        if m.string_at(a) != "":
            skipped["non-empty text"] += 1
            continue
        la, lab = m.name_of(ws[0])
        if la != ws[0] or not lab:
            skipped["record has no label at its address"] += 1
            continue
        new = "ResName_" + (lab[len("NakaWidget_"):] if lab.startswith("NakaWidget_") else lab)
        ren[f][old] = (new, off, size)
    for f, d in ren.items():
        news = [v[0] for v in d.values()]
        assert len(news) == len(set(news)), (f, "duplicate new names")
    return ren, skipped


def segments(text):
    """Split C text into ("code" | "comment" | "string", text) pieces; only code is renamed."""
    out, i, n, start = [], 0, len(text), 0
    while i < n:
        c = text[i]
        if c == "/" and text.startswith("/*", i):
            j = text.index("*/", i + 2) + 2
        elif c == "/" and text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
        elif c in "\"'":
            j = i + 1
            while text[j] != c:
                j += 2 if text[j] == "\\" else 1
            j += 1
        else:
            i += 1
            continue
        out.append(("code", text[start:i]))
        out.append(("string" if c in "\"'" else "comment", text[i:j]))
        i = start = j
    out.append(("code", text[start:]))
    return out


def apply_tree(tree, ren):
    _, layout = members(tree)
    total = 0
    for f, d in sorted(ren.items()):
        p = os.path.join(ROOT, tree, "maincpu/ui_widgets", f)
        blob = open(os.path.join(ROOT, tree, "maincpu/includes/generated", f[:-2] + ".bin"), "rb").read()
        lay = layout.get(f, {})
        s = open(p, "rb").read().decode("latin-1")
        taken = set(re.findall(r'\b\w+\b', s))
        do = {}
        for old, (new, off, size) in d.items():
            if lay.get(old) != (off, size):
                continue
            assert blob[off] == 0, (tree, f, old)            # the empty string
            assert new not in taken, (tree, f, new)
            do[old] = new
        if not do:
            continue
        rx = re.compile(r'\b(%s)\b' % "|".join(map(re.escape, sorted(do, key=len, reverse=True))))
        new_s = "".join(rx.sub(lambda mm: do[mm.group(1)], seg) if kind == "code" else seg
                        for kind, seg in segments(s))
        total += len(do)
        print("  %s %s: %d members" % (tree, f, len(do)))
        if APPLY:
            data = new_s.encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
    return total


def main():
    ren, skipped = plan_v10()
    print("v10 map: %d members in %d files; skipped %s" % (sum(len(d) for d in ren.values()), len(ren),
                                                           dict(skipped)))
    for tree in ("v10", "v9", "v7"):
        print("%s: %d members renamed" % (tree, apply_tree(tree, ren)))


if __name__ == "__main__":
    main()
