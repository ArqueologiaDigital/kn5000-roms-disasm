#!/usr/bin/env python3
"""name_naka_members_from_asm_labels.py -- give a placeholder C blob member the name of the asm slice it is.

QUESTION IT ANSWERS / WHAT IT DOES
  A compiled-C blob (ui_widgets/naka_*.c -> includes/generated/naka_*.bin) enters the ROM through `.incbin`
  slices in the .s files, and many slices carry a reviewed label: `NameProc_Init_Str_name: .incbin
  "includes/generated/naka_disk_warning.bin", 0x1F20, 0x6`.  The C member holding exactly those bytes was
  often still named by the generator (str_N, field_XXXX, vSS_eK).  This script renames such a member to the
  label when
    - the member is a placeholder (semantic_score.placeholder_field) and the label is not;
    - the member starts at the slice's offset and has exactly its length (the same object, not a part);
    - the kinds agree: a str_N member takes only a string label (`_Str_` / `Str_` in it), a vSS_eK element
      only a NakaWidget_ label, any other placeholder any label but a NakaWidget_ one;
    - the label says more than kind words and indexes (IconName_i173 does not: it would only trade one
      positional name for another);
    - the label is not already a member name in that file.
  The rename covers the declaration, the designated initializer and every SELF(member) in the file (word-
  bounded).  Comments are not touched.  Only names change, so every blob must stay byte-identical.

RUN (repository root) -- v9 and v7 first, planned from v10's slices, then v10 itself:
  python3 scripts/tools/name_naka_members_from_asm_labels.py v9 --plan-tree v10 [--apply]
  python3 scripts/tools/name_naka_members_from_asm_labels.py v7 --plan-tree v10 [--apply]
  python3 scripts/tools/name_naka_members_from_asm_labels.py v10 [--apply]
"""
import collections
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import nakarest_c_model as M                     # noqa: E402
from semantic_score import placeholder_field     # noqa: E402

SLICE = re.compile(r'^([A-Za-z_]\w*):\s*\.incbin\s+"includes/generated/(\w+)\.bin",\s*(0x[0-9A-Fa-f]+|\d+),\s*'
                   r'(0x[0-9A-Fa-f]+|\d+)')
ELEMENT = re.compile(r'^v[0-9A-Fa-f]+_e\d+$')
STRING = re.compile(r'^str_\d+$')


KIND_WORDS = {"iconname", "iconbitmapname", "funcname", "nakawidget", "str", "data", "table", "ptrtable", "ptr",
              "ptrs", "bytes", "label"}
INDEX = re.compile(r'^(?:0x)?[A-Za-z]?(?:[0-9A-F]+|[0-9a-f]*[0-9][0-9a-f]*)$')


def informative(label):
    """A label made only of kind words and indexes (IconName_i173) says no more than str_N: skip it."""
    return any(t and not INDEX.match(t) and t.lower() not in KIND_WORDS for t in label.split("_"))


def kinds_agree(member, label):
    if STRING.match(member):
        return "_Str_" in label or label.startswith("Str_") or label.endswith("_Str")
    if ELEMENT.match(member):
        return label.startswith("NakaWidget_")
    return not label.startswith("NakaWidget_")


LABEL_ONLY = re.compile(r'^([A-Za-z_]\w*):\s*(;.*)?$')
INCBIN = re.compile(r'^\s+\.incbin\s+"includes/generated/(\w+)\.bin",\s*(0x[0-9A-Fa-f]+|\d+),\s*(0x[0-9A-Fa-f]+|\d+)')


def tree_slices(tree):
    """bin stem -> {offset: (label, length)}: `Label: .incbin ...` on one line, or a `Label:` line followed by
    the `.incbin` line (comment lines between them are skipped)."""
    slices = collections.defaultdict(dict)
    for p in glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*.s"), recursive=True):
        lines = open(p, "rb").read().decode("latin-1").split("\n")
        for i, line in enumerate(lines):
            m = SLICE.match(line)
            if m:
                slices[m.group(2)][int(m.group(3), 0)] = (m.group(1), int(m.group(4), 0))
                continue
            lm = LABEL_ONLY.match(line)
            if lm:
                j = i + 1
                while j < len(lines) and lines[j].lstrip().startswith(";"):
                    j += 1
                im = INCBIN.match(lines[j]) if j < len(lines) else None
                if im:
                    slices[im.group(1)][int(im.group(2), 0)] = (lm.group(1), int(im.group(3), 0))
    return slices


def main():
    tree = sys.argv[1]
    apply = "--apply" in sys.argv
    # the C sources are shared between trees: a file identical to the plan tree's takes the plan tree's renames,
    # so the trees' C stays identical; a file that differs is planned from its own tree's slices
    plan_tree = sys.argv[sys.argv.index("--plan-tree") + 1] if "--plan-tree" in sys.argv else tree
    own, ref = tree_slices(tree), tree_slices(plan_tree)
    total = 0
    for c in sorted(glob.glob(os.path.join(REPO, tree, "maincpu", "ui_widgets", "naka_*.c"))):
        stem = os.path.basename(c)[:-2]
        rc = os.path.join(REPO, plan_tree, "maincpu", "ui_widgets", stem + ".c")
        same = os.path.exists(rc) and open(rc, "rb").read() == open(c, "rb").read()
        slices = ref if same else own
        if stem not in slices:
            continue
        try:
            cb = M.CBlob(c)
        except (SystemExit, KeyError) as e:
            print("  %-32s skipped (%s)" % (stem, e))
            continue
        names = {mb.name for mb in cb.members}
        plan = {}
        for mb in cb.members:
            hit = slices[stem].get(mb.offset)
            if not hit or not placeholder_field(mb.name):
                continue
            label, length = hit
            if length == mb.size and not placeholder_field(label) and informative(label) and kinds_agree(mb.name, label) \
                    and label not in names and label not in plan.values():
                plan[mb.name] = label
        if not plan:
            continue
        total += len(plan)
        print("  %-32s %d" % (stem, len(plan)))
        if apply:
            text = open(c, "rb").read().decode("latin-1")
            # rename outside comments only: split into comment / code pieces
            parts = re.split(r'(/\*.*?\*/|//[^\n]*)', text, flags=re.S)
            pat = re.compile(r'\b(%s)\b' % "|".join(sorted(map(re.escape, plan), key=len, reverse=True)))
            for k in range(0, len(parts), 2):
                parts[k] = pat.sub(lambda m: plan[m.group(1)], parts[k])
            data = "".join(parts).encode("latin-1")
            open(c + ".tmp", "wb").write(data)
            os.replace(c + ".tmp", c)
    print("%s: %d members named after their asm slice" % (tree, total))


if __name__ == "__main__":
    main()
