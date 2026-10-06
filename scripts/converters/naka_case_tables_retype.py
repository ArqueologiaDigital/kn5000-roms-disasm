#!/usr/bin/env python3
r"""naka_case_tables_retype.py -- give the NAKA C blobs the switch case-offset tables the asm already spells (v10/v9/v7).

QUESTION ANSWERED
-----------------
Inside a NAKA blob, a compiled switch's case-offset table appears twice:
  - in the asm as `<Label>: .short <Case> - <Base>` lines, which replace the blob bytes there;
  - in the C struct as anonymous `uint16_t field_XXXX` words with the same numbers.
The C side is all placeholders (semantic_score counts them as such) although the asm names the table and its
reader.  For every asm label in a v10 file whose statements are only `.short A - B` lines (n of them), this script
takes the label's address from the linked v10 ELF.  When that address lies inside one of the naka_*.c blobs
(#define BASE .. + size), it checks that the C members covering [offset, offset + 2n) are all placeholders with
numeric values.  It then retypes that range as `uint16_t <Label>[n]` with the same numbers, under a comment saying
the asm spells the entries symbolically.  The bytes cannot change: same values, same width.  v9 and v7 get the
same retype only where their C file has the same members at the same offsets (the layout is shared).
A table that ends inside a member, or overlaps a named member, is skipped and listed.

RUN (repository root, built tree)
    python3 scripts/converters/naka_case_tables_retype.py [--apply]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all;
    assert_c_comments_preserved.py --base HEAD (with --allow '/\* (zero padding|\d+ pointers) \*/')
"""
import collections
import glob
import os
import re
import subprocess
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
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")


def tables_v10():
    """label -> number of `.short A - B` lines, for labels whose whole content is such lines."""
    out = {}
    for p in glob.glob(os.path.join(ROOT, "v10/maincpu/**/*.s"), recursive=True):
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for i, x in enumerate(L):
            m = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', x)
            if not m:
                continue
            rest = m.group(2).split(";")[0].strip()
            n, j = 0, i + 1
            if rest:
                if not re.match(r'^\.short\s+\w+\s*-\s*\w+$', rest):
                    continue
                n = 1
            while j < len(L):
                c = L[j].split(";")[0].strip()
                if re.match(r'^\.short\s+\w+\s*-\s*\w+$', c):
                    n += 1
                    j += 1
                    continue
                break
            if n:
                out[m.group(1)] = n
    return out


def main():
    syms = {}
    for line in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")],
                               capture_output=True, text=True).stdout.split("\n"):
        f = line.split()
        if len(f) == 3:
            syms[f[2]] = int(f[0], 16)
    tabs = tables_v10()
    blobs = {}
    for c in sorted(glob.glob(os.path.join(ROOT, "v10/maincpu/ui_widgets/naka_*.c"))):
        t = open(c, encoding="latin-1").read()
        mb = re.search(r'#define BASE\s+0x([0-9A-Fa-f]+)', t)
        b = os.path.join(ROOT, "v10/maincpu/includes/generated", os.path.basename(c)[:-2] + ".bin")
        if mb and os.path.exists(b):
            blobs[os.path.basename(c)] = (int(mb.group(1), 16), len(open(b, "rb").read()))
    plan = collections.defaultdict(list)          # C file -> [(offset, n, label)]
    for lab, n in sorted(tabs.items()):
        a = syms.get(lab)
        if a is None:
            continue
        for f, (base, size) in blobs.items():
            if base <= a < base + size:
                plan[f].append((a - base, n, lab))
    total = collections.Counter()
    for tree in ("v10", "v9", "v7"):
        for f, items in sorted(plan.items()):
            p = os.path.join(ROOT, tree, "maincpu/ui_widgets", f)
            bin_ = open(os.path.join(ROOT, tree, "maincpu/includes/generated", f[:-2] + ".bin"), "rb").read()
            try:
                cb = M.CBlob(p)
            except BaseException as e:
                print("  %s %s: not parsed (%s)" % (tree, f, str(e)[:60]))
                continue
            done = 0
            for off, n, lab in items:
                if lab in cb.by_name:
                    continue
                ov = [x for x in cb.members if x.offset < off + 2 * n and x.offset + x.size > off]
                # a covered member may be a placeholder, or a 1-letter `char x[2]` the generic decoder made out of
                # a case offset such as 0x0041 ("A"); anything else stops the table
                bad = [x.name for x in ov if not (SS.placeholder_field(x.name) or
                       (x.ctype == "char" and x.size <= 2 and re.match(r'^[A-Za-z]_str(_\d+)?$', x.name)))]
                if not ov or bad or any(M.SYMBOLIC_RE.search(cb.entries[cb.by_name[x.name]].expr) for x in ov):
                    print("  %s %s %s: covered member(s) %s named or symbolic; skipped" % (tree, f, lab, bad[:3]))
                    continue
                vals = [int.from_bytes(bin_[off + 2 * k:off + 2 * k + 2], "little") for k in range(n)]
                rows = ["        " + ", ".join("0x%04X" % v for v in vals[r:r + 8]) + "," for r in range(0, n, 8)]
                try:
                    cb.retype(off, off + 2 * n,
                              [M.NewMember("uint16_t", lab, "[%d]" % n, 2 * n, "{\n" + "\n".join(rows) + "\n    }",
                                       ["    /* %s: %d u16 case offsets of a compiled switch; the asm spells them"
                                        " `.short <Case> - <Base>` (scripts/converters/naka_case_tables_retype.py) */"
                                        % (lab, n)])], bin_)
                except SystemExit as e:
                    print("  %s %s %s: not retyped (%s)" % (tree, f, lab, str(e)[:80]))
                    continue
                done += 1
            if done:
                total[tree] += done
                if APPLY:
                    data = cb.render().encode("latin-1")
                    open(p + ".tmp", "wb").write(data)
                    os.replace(p + ".tmp", p)
        print("%s: %d case tables typed in C" % (tree, total[tree]))


if __name__ == "__main__":
    main()
