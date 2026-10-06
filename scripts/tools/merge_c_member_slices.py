#!/usr/bin/env python3
"""merge_c_member_slices.py -- one .incbin per typed C object, where the asm had cut it into misnamed pieces.

QUESTION IT ANSWERS / WHAT IT DOES
  The asm side of a naka_*.bin is a list of `.incbin "includes/generated/<blob>.bin", off, size` slices.  Older
  passes split some typed C objects into pieces, often to give a false pointer a label:
  Bitmap_MIDIConnections_2 (one 296 x 108 bitmap in naka_widget_tables_2.c) was 21 slices with names like
  NakaData_Tables2Pad3 and Bitmap_MIDIConnections_Header; Bitmap_Dredt0d was 18 with NakaData_UserMemoryConfig,
  NakaData_StyleBitmapPad ... inside a bitmap.  For every Bitmap_* C member of a NAKA blob (a bitmap has no
  sub-objects; the labelled pieces of a string table do, so those stay) this script looks for a run of consecutive
  .incbin lines of that blob, with no other line between them, that covers the member exactly
  and starts at it.  It merges them into the run's first line (label and trailing comment kept) when no label
  of a later piece is referenced anywhere in the tree (asm, C, link scripts).  The bytes cannot change.

RUN (repository root)
  python3 scripts/tools/merge_c_member_slices.py [--apply]       # then make all; gate
"""
import collections
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/converters"))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis"))
import nakarest_c_model as M      # noqa: E402
_a, sys.argv = sys.argv, sys.argv[:1]
import semantic_score as SS       # noqa: E402
sys.argv = _a
APPLY = "--apply" in sys.argv
INC = re.compile(r'^(?:([A-Za-z_]\w*):)?(\s*)\.incbin\s+"includes/generated/(naka_\w+)\.bin",\s*(0x[0-9A-Fa-f]+),\s*'
                 r'(0x[0-9A-Fa-f]+)(.*)$')


def main():
    for tree in ("v10", "v9", "v7"):
        root = os.path.join(REPO, tree, "maincpu")
        files = {}
        for p in glob.glob(os.path.join(root, "**", "*.s"), recursive=True) + \
                glob.glob(os.path.join(root, "**", "*.c"), recursive=True) + \
                glob.glob(os.path.join(root, "**", "*.ld"), recursive=True):
            files[p] = open(p, "rb").read().decode("latin-1").split("\n")
        refcount = collections.Counter()
        for p, L in files.items():
            for line in L:
                code = line.split(";", 1)[0] if p.endswith(".s") else re.sub(r'/\*.*?\*/|//.*', '', line)
                if p.endswith(".s"):
                    code = re.sub(r'^[A-Za-z_]\w*:', '', code)
                for t in re.findall(r'[A-Za-z_]\w*', code):
                    refcount[t] += 1
        pieces = collections.defaultdict(dict)        # blob -> {off: (path, line index)}
        for p, L in files.items():
            if p.endswith(".s"):
                for i, line in enumerate(L):
                    m = INC.match(line)
                    if m:
                        pieces[m.group(3)][int(m.group(4), 16)] = (p, i)
        edits = collections.defaultdict(list)
        merged = 0
        for blob in sorted(pieces):
            c = os.path.join(root, "ui_widgets", blob + ".c")
            if not os.path.exists(c):
                continue
            try:
                cb = M.CBlob(c)
            except BaseException:
                continue
            for mb in cb.members:
                if mb.size < 64 or not mb.name.startswith("Bitmap_") or mb.offset not in pieces[blob]:
                    continue                      # a bitmap has no sub-objects; a string table's pieces do
                p, i = pieces[blob][mb.offset]
                L = files[p]
                end, j, labels = mb.offset, i, []
                ok = False
                while j < len(L):
                    m = INC.match(L[j])
                    if not m or m.group(3) != blob or int(m.group(4), 16) != end:
                        break
                    if j > i and m.group(1):
                        labels.append(m.group(1))
                    end += int(m.group(5), 16)
                    j += 1
                    if end == mb.offset + mb.size:
                        ok = True
                        break
                    if end > mb.offset + mb.size:
                        break
                if not ok or j - i < 2:
                    continue
                if any(refcount[x] for x in labels):
                    print("  %s %s %s: kept (a piece's label is referenced)" % (tree, blob, mb.name))
                    continue
                m0 = INC.match(L[i])
                first = '%s%s.incbin "includes/generated/%s.bin", 0x%X, 0x%X%s' % (
                    (m0.group(1) + ":") if m0.group(1) else "", m0.group(2), blob, mb.offset, mb.size, m0.group(6))
                edits[p].append((i, j, first))
                merged += 1
                print("%s %s %-36s %d pieces -> 1 (dropped labels: %s)" % (tree, blob, mb.name, j - i,
                                                                          ", ".join(labels) or "-"))
        print("%s: %d C objects merged into one slice" % (tree, merged))
        if not APPLY:
            continue
        for p, ops in edits.items():
            L = files[p]
            for i, j, first in sorted(ops, reverse=True):
                L[i:j] = [first]
            data = "\n".join(L).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
