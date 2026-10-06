#!/usr/bin/env python3
r"""naka_text_slices_retype.py -- type labelled text slices of the NAKA C blobs as char arrays (v10/v9/v7).

QUESTION ANSWERED
-----------------
The asm side of each naka_*.bin labels its slices (`Str_DiskErr43_Spanish: .incbin "...", 0x14434, 0x7C`), and
the [nakarest] notes say which catalog record or reader shows the text.  The generic C decode left some of these
texts as runs of uint16_t field_* members, typically when the text holds bytes of the fonts' upper page
(0x93 / 0x94 quotes, accented letters).  For every labelled slice whose bytes are text this script retypes it
in the tree's C file as `char <Label>[size]` with a string literal of exactly those bytes.  Text here means
0x20-0x7E, 0x80-0xFF, NUL, tab, CR, LF, at least one NUL (every string is NUL-terminated), and at least
a third of the bytes letters.  Only slices whose C members
are all placeholders (semantic_score.placeholder_field) are touched, never one with a symbolic initializer.
The literal spells printable ASCII as itself and every other byte as a 3-digit octal escape.  A slice whose only
NUL is its last byte leaves that NUL to the array size (`char X[4] = "i99"`); otherwise every byte is spelled.
A label made only of kind words and indexes (IconName_i173, name_naka_members_from_asm_labels.informative) says no
more than str_N and is skipped.  Each tree uses its own bytes and labels.

RUN (repository root, built tree)
    python3 scripts/converters/naka_text_slices_retype.py [--apply]
    then (v7): scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; gate
C comment gate: the retype keeps every comment of the removed members.
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
import nakarest_c_model as M      # noqa: E402
_argv, sys.argv = sys.argv, sys.argv[:1]
import semantic_score as SS       # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "scripts/tools"))
from name_naka_members_from_asm_labels import informative   # noqa: E402
sys.argv = _argv

INC = re.compile(r'^([A-Za-z_]\w*):\s*\.incbin\s+"includes/generated/(naka_\w+)\.bin",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')
INC2 = re.compile(r'^\s*\.incbin\s+"includes/generated/(naka_\w+)\.bin",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')


def texty(b):
    if len(b) < 4 or b.count(0) == len(b) or 0 not in b:   # the firmware's strings are NUL-terminated
        return False
    ok = sum(1 for x in b if 0x20 <= x < 0x7f or x >= 0x80 or x in (0, 9, 10, 13))
    letters = sum(1 for x in b if 0x41 <= (x | 0x20) <= 0x7a)
    return ok == len(b) and letters >= len(b) // 3


def literal(b):
    if b.endswith(b"\0") and b.count(0) == 1:
        b = b[:-1]                      # the array's size supplies the terminator: char x[4] = "i99"
    out = []
    for i, x in enumerate(b):
        ch = chr(x)
        if x in (0x22, 0x5C) or x < 0x20 or x >= 0x7F or (ch == "?" and i + 1 < len(b) and b[i + 1] == 0x3F):
            out.append("\\%03o" % x)
        else:
            out.append(ch)
    s = "".join(out)
    # wrap long literals into adjacent string pieces of ~96 characters at escape boundaries
    pieces, cur = [], ""
    for tok in re.findall(r'\\[0-7]{3}|.', s):
        cur += tok
        if len(cur) >= 96:
            pieces.append(cur)
            cur = ""
    if cur or not pieces:
        pieces.append(cur)
    if len(pieces) == 1:
        return '"%s"' % pieces[0]
    return "\n        " + "\n        ".join('"%s"' % p for p in pieces)


def slices(tree):
    out = []
    for p in glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.s"), recursive=True):
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for i, line in enumerate(L):
            m = INC.match(line)
            if m:
                out.append((m.group(2), m.group(1), int(m.group(3), 16), int(m.group(4), 16)))
                continue
            m2 = INC2.match(line)
            if m2 and i > 0:
                ml = re.match(r'^([A-Za-z_]\w*):\s*$', L[i - 1])
                if ml:
                    out.append((m2.group(1), ml.group(1), int(m2.group(2), 16), int(m2.group(3), 16)))
    return out


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        by = collections.defaultdict(list)
        for s in slices(tree):
            by[s[0]].append(s)
        total = 0
        for blob, ss in sorted(by.items()):
            c = os.path.join(ROOT, tree, "maincpu", "ui_widgets", blob + ".c")
            if not os.path.exists(c):
                continue
            try:
                cb = M.CBlob(c)
            except BaseException as e:                       # a file the model cannot parse is left alone
                print("  %s %s: skipped (%s)" % (tree, blob, str(e)[:60]))
                continue
            b = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", blob + ".bin"), "rb").read()
            done = 0
            for _, lab, off, size in sorted(ss, key=lambda x: x[2]):
                bb = b[off:off + size]
                if not texty(bb) or lab in cb.by_name or not informative(lab):
                    continue
                ov = [mb for mb in cb.members if mb.offset < off + size and mb.offset + mb.size > off]
                if not ov or not all(SS.placeholder_field(mb.name) for mb in ov):
                    continue
                if any(M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr) for mb in ov):
                    continue
                new = [M.NewMember("char", lab, "[%d]" % size, size, literal(bb),
                                   ["    /* %s: text (the asm slice of the same name) */" % lab])]
                try:
                    cb.retype(off, off + size, new, b)
                except SystemExit as e:
                    print("  %s %s %s: not retyped (%s)" % (tree, blob, lab, str(e)[:70]))
                    continue
                done += 1
            if done:
                total += done
                print("%s %s: %d text slices typed" % (tree, blob, done))
                if apply:
                    data = cb.render().encode("latin-1")
                    open(c + ".tmp", "wb").write(data)
                    os.replace(c + ".tmp", c)
        print("%s: %d text slices" % (tree, total))


if __name__ == "__main__":
    main()
