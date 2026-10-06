#!/usr/bin/env python3
"""label_timesig_procs.py -- label the unlabelled targets of TimeSig_ProcTable (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  TimeSig_CallProc (WA = index 0..23, `cp de, 23 / ret ugt`) calls TimeSig_ProcTable[index], 24 u32 code pointers
  (ui_widgets/widget_descriptors.s; typed in naka_widget_descriptors.c).  Six targets had no label, and the asm
  table and the C array spelled them as numbers.  Read from their code (v10 addresses):
    0xF6657C  a bare `ret`, 12 of the 24 slots                        -> TimeSig_ProcNop
    0xF6654F  `extz wa; jrl Tempo_AdjustQuantize` (slot 21)            -> Tempo_AdjustQuantize_WideArg
    0xF66554  `extz wa; jrl Tempo_AdjustEffect` (slot 23)              -> Tempo_AdjustEffect_WideArg
    0xF663E5  Tempo_DisplayParamCommon(display param 0x84, 4), then edits RAM 0x3990 (slot 11) -> Tempo_EditParam84
    0xF6645C  Tempo_DisplayParamCommon(0x92, 18), then edits RAM 0x398A (slot 18)              -> Tempo_EditParam92
    0xF664D1  Tempo_DisplayParamCommon(0x93, 19), then edits RAM 0x398C (slot 19)              -> Tempo_EditParam93
  The last three names give the display parameter id that Tempo_DisplayParamCommon receives; what each
  parameter is has not been established.
  Per tree, the targets are found by slot position in the tree's own table.  A label line goes before each
  target's instruction (census map), and the asm `.long` words are spelled with the name.  In the C words
  (v10 literals in every tree) NAKA_ADDR is used, with an extern and the tree's
  naka_widget_descriptors_link.ld symbol (that tree's address).  Then regenerate_v7_c_divergence.py --apply
  BEFORE make; make all; gate.

RUN (repository root; built tree; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_timesig_procs.py [--apply]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

NAMES = {0xF6657C: "TimeSig_ProcNop", 0xF6654F: "Tempo_AdjustQuantize_WideArg",
         0xF66554: "Tempo_AdjustEffect_WideArg", 0xF663E5: "Tempo_EditParam84",
         0xF6645C: "Tempo_EditParam92", 0xF664D1: "Tempo_EditParam93"}


def main():
    m10 = census.load("v10")
    t10 = m10["byname"]["TimeSig_ProcTable"]
    ref = [census.le(m10, t10 + 4 * k, 4) for k in range(24)]
    for tree in ("v10", "v9", "v7"):
        m = census.load(tree)
        t = m["byname"]["TimeSig_ProcTable"]
        words = [census.le(m, t + 4 * k, 4) for k in range(24)]
        addr = {}
        for w, r in zip(words, ref):
            if r in NAMES:
                assert addr.setdefault(NAMES[r], w) == w, (tree, NAMES[r])
        edits = {}
        for nm, a in addr.items():
            r = census.find(m, a)
            assert r and r[0] == a and census.is_insn_row(tree, r) and not r[7], (tree, nm, hex(a), r and r[:8])
            edits.setdefault(r[2], []).append((r[3], nm + ":"))
        for k in range(24):
            r = census.find(m, t + 4 * k)
            if r[0] == t + 4 * k and r[5] == ".long" and re.match(r'^\s*\.long\s+0x[0-9a-fA-F]+\s*$', r[6]):
                nm = next((n for n, a in addr.items() if a == words[k]), None)
                if nm:
                    edits.setdefault(r[2], []).append((r[3], "\t.long\t" + nm))
        print(tree, ", ".join("%s 0x%06X" % (n, a) for n, a in sorted(addr.items(), key=lambda x: x[1])))
        if not APPLY:
            continue
        for rel, ops in edits.items():
            p = os.path.join(REPO, tree, "maincpu", rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for li, op in sorted(ops, key=lambda x: (-x[0], x[1].endswith(":"))):
                if op.endswith(":"):
                    L[li:li] = [op]
                else:
                    L[li] = op
            data = "\n".join(L).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
        c = os.path.join(REPO, tree, "maincpu/ui_widgets/naka_widget_descriptors.c")
        s = open(c, "rb").read().decode("latin-1")
        for v10a, nm in NAMES.items():
            lit = "0x%08X," % v10a
            assert s.count(lit) >= 1, (tree, lit)
            s = s.replace(lit, "NAKA_ADDR(%s)," % nm)
        L = s.split("\n")
        i = next(k for k, x in enumerate(L) if x.startswith("extern const char "))
        j = i
        while L[j].startswith("extern const char "):
            j += 1
        L[i:j] = sorted(set(L[i:j]) | {"extern const char %s;" % nm for nm in NAMES.values()},
                        key=lambda x: x.split()[-1])
        data = "\n".join(L).encode("latin-1")
        open(c + ".tmp", "wb").write(data)
        os.replace(c + ".tmp", c)
        ld = os.path.join(REPO, tree, "maincpu/ui_widgets/naka_widget_descriptors_link.ld")
        txt = open(ld, "rb").read().decode("latin-1").rstrip("\n") + "\n"
        txt += "".join("%s = 0x%08X;\n" % (nm, a) for nm, a in sorted(addr.items()) if ("\n%s = " % nm) not in txt)
        data = txt.encode("latin-1")
        open(ld + ".tmp", "wb").write(data)
        os.replace(ld + ".tmp", ld)


if __name__ == "__main__":
    main()
