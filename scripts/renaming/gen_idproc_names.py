#!/usr/bin/env python3
"""gen_idproc_names.py -- the NAKA property-type procedures' labels, named for what they handle (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  The <Type>IDProc routines (ui/ui_widget_defs.s) are the NAKA property types: they convert a property value to and
  from its text form for the dump / edit machinery.  Their event arms carried names borrowed from unrelated code by
  an earlier body-reading pass: FrameVariant_B_CalcHeight, FrameVariant_B_Setup ... in ColorIDProc, BorderIDProc,
  AlignmentIDProc ..., with nothing about frames, heights or widths in them.  Eleven of them share one shape
  (asserted line by line for each):
      cp xiz, EVT_SET_PROPERTY_EX / jr z, <X>_CalcHeight
      cp xiz, EVT_GET_PROPERTY_EX / jr z, <X>_Setup
      cp xiz, EVT_DUMP_PROPERTY_EX / jr nz, <X>_CalcWidth
    <X>_Setup:      IDCursorAdvance, store the id as the value      (GET_PROPERTY_EX, and DUMP by fall-through)
    <X>_CalcWidth:  calr CommonIDProc / jr <X>_Done                 (every other event, and after Setup)
    <X>_CalcHeight: calr CommonIDProc, then store the parsed value  (SET_PROPERTY_EX)
    <X>_Execute:    ld xhl, xiz (F: the saved result at (xsp + 4))   (return CommonIDProc's result)
    <X>_Done:       pop xiz / ret
  They become <Proc>_OnGetOrDumpPropertyEx, <Proc>_ForwardToCommon, <Proc>_OnSetPropertyEx, <Proc>_ReturnResult and
  <Proc>_Epilogue.  EditSwIDProc (family F) has the same five plus an EVT_MAKE_EDIT_SW_ID arm: CheckAlt ->
  EditSwIDProc_OnMakeEditSwId.  The arm's internal branch labels DrawAlt / Done / DoneAlt / DoneAlt2 become _Skip /
  _Join / _Join2 / _Join3 (control flow, nothing more is claimed), and Return becomes _Epilogue (its pop/ret).
  The labels are checked to lie between their procedure's label and the next one.  The rules go to
  scripts/renaming/rename_idproc_<tree>.sed, which --apply runs over the tree.

RUN (repository root)
  python3 scripts/renaming/gen_idproc_names.py [--apply]     # then make all; make gate-all; symbols --regen
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
FAMILY = {"B": "ColorIDProc", "C": "BorderIDProc", "D": "AlignmentIDProc", "E": "EditSwStyleIDProc",
          "F": "EditSwIDProc", "G": "LineModeIDProc", "H": "FrameIDProc", "I": "UserIDProc", "J": "PartIDProc",
          "K": "TrackIDProc", "L": "IntTimeIDProc"}
ROLE = {"Setup": "OnGetOrDumpPropertyEx", "CalcWidth": "ForwardToCommon", "CalcHeight": "OnSetPropertyEx",
        "Execute": "ReturnResult", "Done": "Epilogue"}
EXTRA_F = {"CheckAlt": "OnMakeEditSwId", "DrawAlt": "Skip", "Done": "Join", "DoneAlt": "Join2", "DoneAlt2": "Join3",
           "Return": "Epilogue"}


def code(x):
    return re.sub(r'\s+', ' ', x.split(";")[0].strip())


def body(L, start, label):
    k = L.index(label + ":", start)
    out = []
    for x in L[k + 1:]:
        if re.match(r'^[A-Za-z_]\w*:', x):
            break
        if code(x):
            out.append(code(x))
    return k, out


def rules_for(tree):
    L = open(os.path.join(REPO, tree, "maincpu/ui/ui_widget_defs.s"), "rb").read().decode("latin-1").split("\n")
    rules = {}
    for f, proc in FAMILY.items():
        X = "FrameVariant_" + f
        p0 = L.index(proc + ":")
        p1 = next(i for i in range(p0 + 1, len(L)) if re.match(r'^\w+IDProc:', L[i]))
        _, head = body(L, p0, proc)
        assert head[-6:] == ["cp xiz, EVT_SET_PROPERTY_EX", "jr z, %s_CalcHeight" % X, "cp xiz, EVT_GET_PROPERTY_EX",
                             "jr z, %s_Setup" % X, "cp xiz, EVT_DUMP_PROPERTY_EX", "jr nz, %s_CalcWidth" % X] \
            or f == "F", (tree, proc, head[-6:])
        if f == "F":
            assert head[-8:] == ["cp xiz, EVT_MAKE_EDIT_SW_ID", "jr z, %s_CheckAlt" % X, "cp xiz, EVT_SET_PROPERTY_EX",
                                 "jr z, %s_CalcHeight" % X, "cp xiz, EVT_GET_PROPERTY_EX", "jr z, %s_Setup" % X,
                                 "cp xiz, EVT_DUMP_PROPERTY_EX", "jr nz, %s_CalcWidth" % X], (tree, proc, head[-8:])
        k, b = body(L, p0, X + "_Setup")
        assert "calr IDCursorAdvance" in b, (tree, X, "Setup")
        _, b = body(L, p0, X + "_CalcWidth")
        assert "calr CommonIDProc" in b and b[-1].startswith("jr %s_" % X), (tree, X, b)
        _, b = body(L, p0, X + "_CalcHeight")
        assert "calr CommonIDProc" in b and "jr nz, %s_Execute" % X in b, (tree, X, b)
        _, b = body(L, p0, X + "_Execute")
        assert b[0] == ("ld xhl, (xsp + 4)" if f == "F" else "ld xhl, xiz"), (tree, X, b)
        names = dict(ROLE)
        if f == "F":
            names.update(EXTRA_F)
            names["Done"] = EXTRA_F["Done"]
        for i in range(p0, p1):
            m = re.match(r'^%s_(\w+):' % X, L[i])
            if m:
                assert m.group(1) in names, (tree, X, m.group(1))
                rules["%s_%s" % (X, m.group(1))] = "%s_%s" % (proc, names[m.group(1)])
        for i, x in enumerate(L):           # every label of the family lies inside its procedure
            m = re.match(r'^%s_\w+:' % X, x)
            if m:
                assert p0 < i < p1, (tree, X, i + 1)
    # F: Done is a join inside the MAKE_EDIT_SW_ID arm, Return is the epilogue -- check the epilogue claim
    return rules, L


def main():
    plans = {}
    for tree in ("v10", "v9", "v7"):
        rules, L = rules_for(tree)
        _, b = body(L, 0, "FrameVariant_F_Return")
        assert b[:2] == ["pop xiz", "lda xsp, (xsp + 12)"] and b[-1] == "ret", (tree, b)
        plans[tree] = rules
        print("%s: %d labels" % (tree, len(rules)))
    assert plans["v9"] == plans["v10"] and plans["v7"] == plans["v10"], "trees differ"
    if not APPLY:
        for a in sorted(plans["v10"]):
            print("  %-30s -> %s" % (a, plans["v10"][a]))
        return
    for tree, rules in plans.items():
        sed = os.path.join(REPO, "scripts/renaming/rename_idproc_%s.sed" % tree)
        open(sed, "w").write("# rename_idproc_%s.sed -- written by scripts/renaming/gen_idproc_names.py\n" % tree +
                             "".join("s/\\b%s\\b/%s/g\n" % (a, rules[a]) for a in sorted(rules, key=len, reverse=True)))
        hit = [p for p in glob.glob(os.path.join(REPO, tree, "maincpu/**/*"), recursive=True)
               if p.endswith((".s", ".c", ".ld")) and
               any(re.search(r'\b%s\b' % a, open(p, "rb").read().decode("latin-1")) for a in rules)]
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  %s: sed applied to %d files" % (tree, len(hit)))


if __name__ == "__main__":
    main()
