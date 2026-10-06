#!/usr/bin/env python3
r"""split_naka_pointer_arrays.py -- cut merged NAKA pointer arrays at the asm labels inside them (v10/v9/v7).

QUESTION ANSWERED
-----------------
The generic decoder (naka_struct_decode.py) declared runs of consecutive pointers as one placeholder array, so one
`uint32_t ptrs_5[422]` in naka_effects_seq.c holds some 30 registered Viewable tables back to back.  The asm
already labels them one by one: Kubo_ViewableTable_086 ... Kubo_ViewableTable_0AB, from the RegObjTabl calls
(gen_naka_regobj_table_names.py).  The C struct kept one anonymous array.
For every placeholder `uint32_t <name>[m]` member of a naka_*.c blob (v10), this script collects the column-0 asm
labels (`Label:`, not `.set` aliases) whose linked-ELF address falls inside the array at a 4-byte boundary.  It
cuts the array there.  Each piece is named after the label at its start; a piece with no label at its start keeps
the old name.  Every initializer (SELF(...), NAKA_ADDR(...), numbers) moves unchanged into its piece, so the bytes
and the symbols cannot change.  Arrays that something addresses with SELF(<name>[i]) are skipped.
v9 and v7 take v10's cuts where their C file has the same array at the same offset and size.

RUN (repository root, built tree)
    python3 scripts/converters/split_naka_pointer_arrays.py [--apply]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all;
    assert_c_comments_preserved.py --base HEAD
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


def labels_v10():
    """address -> asm column-0 label (the first non-generic one when several share an address)"""
    syms = collections.defaultdict(list)
    for line in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")],
                               capture_output=True, text=True).stdout.split("\n"):
        f = line.split()
        if len(f) == 3:
            syms[f[2]] = int(f[0], 16)
    col0 = set()
    for p in glob.glob(os.path.join(ROOT, "v10/maincpu/**/*.s"), recursive=True):
        for x in open(p, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_]\w*):', x)
            if m:
                col0.add(m.group(1))
    at = collections.defaultdict(list)
    for n, a in syms.items():
        if n in col0:
            at[a].append(n)
    return {a: sorted(ns, key=lambda n: (bool(SS.GENERIC.search(n)), n))[0] for a, ns in at.items()}


def plan():
    lab = labels_v10()
    out = collections.defaultdict(list)       # C file -> [(member, offset, size, [(cut offset, name)])]
    for c in sorted(glob.glob(os.path.join(ROOT, "v10/maincpu/ui_widgets/naka_*.c"))):
        t = open(c, encoding="latin-1").read()
        mb = re.search(r'#define BASE\s+0x([0-9A-Fa-f]+)', t)
        if not mb:
            continue
        base = int(mb.group(1), 16)
        try:
            cb = M.CBlob(c)
        except BaseException:
            continue
        selfsub = {k for k, subs in cb.self_targets().items() if any(subs)}
        taken = {x.name for x in cb.members}
        for x in cb.members:
            m = re.match(r'^\[(\d+)\]$', x.dims or "")
            if x.ctype != "uint32_t" or not m or int(m.group(1)) < 2 or not SS.placeholder_field(x.name) \
                    or x.name in selfsub:
                continue
            cuts = []
            for k in range(int(m.group(1))):
                a = base + x.offset + 4 * k
                if a in lab and lab[a] not in taken:
                    cuts.append((4 * k, lab[a]))
            if cuts:
                out[os.path.basename(c)].append((x.name, x.offset, x.size, cuts))
    return out


def split_items(expr):
    body = expr.strip()
    assert body.startswith("{") and body.endswith("}"), body[:40]
    items = [i.strip() for i in M.split_top_level(body[1:-1]) if i.strip()]
    return items


def apply_tree(tree, pl):
    total = 0
    for f, arrays in sorted(pl.items()):
        p = os.path.join(ROOT, tree, "maincpu/ui_widgets", f)
        blob = open(os.path.join(ROOT, tree, "maincpu/includes/generated", f[:-2] + ".bin"), "rb").read()
        cb = M.CBlob(p)
        n = 0
        for name, off, size, cuts in arrays:
            mb = cb.by_name.get(name)
            if mb is None:
                continue
            x = cb.members[mb]
            if (x.offset, x.size) != (off, size):
                print("  %s %s %s: layout differs from v10; skipped" % (tree, f, name))
                continue
            items = split_items(cb.entries[mb].expr)
            assert len(items) * 4 == size, (tree, f, name, len(items))
            bounds = sorted({0} | {c for c, _ in cuts})
            names = {c: nm for c, nm in cuts}
            new = []
            for i, b0 in enumerate(bounds):
                b1 = bounds[i + 1] if i + 1 < len(bounds) else size
                piece = items[b0 // 4:b1 // 4]
                nm = names.get(b0, name if b0 == 0 else "%s_%X" % (name, b0))
                body = "{\n" + "\n".join("        %s," % it for it in piece) + "\n    }"
                new.append(M.NewMember("uint32_t", nm, "[%d]" % len(piece), 4 * len(piece), body,
                                       ["    /* %s: %d pointers (cut from %s by split_naka_pointer_arrays.py) */"
                                        % (nm, len(piece), name)] if b0 in names else [], keeps=(name,)))
            try:
                cb.retype(off, off + size, new, blob)
            except SystemExit as e:
                print("  %s %s %s: not split (%s)" % (tree, f, name, str(e)[:80]))
                continue
            n += 1
            total += len([c for c in cuts])
        if n and APPLY:
            data = cb.render().encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
        if n:
            print("  %s %s: %d arrays split" % (tree, f, n))
    return total


def main():
    pl = plan()
    print("v10 plan: %d arrays, %d labelled pieces" % (sum(len(v) for v in pl.values()),
                                                       sum(len(c) for v in pl.values() for *_, c in v)))
    for tree in ("v10", "v9", "v7"):
        print("%s: %d labelled pieces" % (tree, apply_tree(tree, pl)))


if __name__ == "__main__":
    main()
