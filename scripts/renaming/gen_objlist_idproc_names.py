#!/usr/bin/env python3
"""gen_objlist_idproc_names.py -- ApFuncIDProc and MainFuncIDProc labels named for what they do (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  ApFuncIDProc and MainFuncIDProc are the NAKA property types whose values are ApFunction / MainFunction object
  ids.  Their labels were DrawHelper_B_* / _C_* and DrawHelper_D_* / _E_*, and each epilogue carried the next
  routine's name (MainFuncIDProc_Return is ApFuncIDProc's pop/ret, ViewIDProc_Return is MainFuncIDProc's).
  Both have one shape, asserted here per routine and tree:
    phase 1, for SET_PROPERTY_EX / GET_PROP_DATA_COUNT_SP / GET_PROP_DATA_SP: build a stack list of every object id
      (slot << 16 | index) for registry slots 0x120..0x13F (ApFunction) or 0x140..0x15F (MainFunction) with
      CountObject:  BuildIdList, _SlotLoop, _ObjLoop, _NextSlot;
    phase 2, the event chain (Dispatch): SET_PROPERTY_EX searches the list by name (OnSetPropertyEx,
      SetProp_CompareName with GET_NAME + Strcmp, SetProp_NextIndex, SetProp_CheckFound, SetProp_StoreId,
      SetProp_ReturnResult); GET / DUMP_PROPERTY_EX -> OnGetOrDumpPropertyEx, GetNameAndCopy (GET_NAME),
      StrcpyReturnZero; MAKE_DUMP -> OnMakeDump ("idf" + name); GET_PROP_DATA_COUNT_SP -> OnGetPropDataCountSp
      (the list length); anything else -> ForwardToCommon; then Epilogue.
  The family letters map to roles differently (B's CalcRange is D's Setup), so each family has its own table.
  The rules go to scripts/renaming/rename_objlist_idprocs_<tree>.sed; --apply runs it over the tree.

RUN (repository root)
  python3 scripts/renaming/gen_objlist_idproc_names.py [--apply]   # then make all; make gate-all; symbols --regen
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
PHASE2 = {"DrawTrack": "OnSetPropertyEx", "ReturnZero": "SetProp_CompareName", "ReturnAlt": "SetProp_NextIndex",
          "ReturnAlt2": "SetProp_CheckFound", "ReturnAlt3": "SetProp_StoreId", "ReturnAlt4": "SetProp_ReturnResult",
          "Setup": "OnGetOrDumpPropertyEx", "CalcRange": "GetNameAndCopy", "CalcThumb": "StrcpyReturnZero",
          "Return": "ForwardToCommon"}
PROCS = {  # proc: (phase-1 family, its role map, phase-2 family, epilogue label, first slot, last slot)
    "ApFuncIDProc": ("DrawHelper_B", {"CalcRange": "BuildIdList", "CalcThumb": "BuildIdList_SlotLoop",
                                      "DrawTrack": "BuildIdList_ObjLoop", "ReturnZero": "BuildIdList_NextSlot",
                                      "ReturnAlt": "Dispatch", "Finish": "OnGetPropDataCountSp",
                                      "FinishAlt": "OnMakeDump"},
                     "DrawHelper_C", "MainFuncIDProc_Return", 0x120, 0x13F),
    "MainFuncIDProc": ("DrawHelper_D", {"Setup": "BuildIdList", "CalcRange": "BuildIdList_SlotLoop",
                                        "DrawTrack": "BuildIdList_ObjLoop", "ReturnZero": "BuildIdList_NextSlot",
                                        "ReturnAlt": "Dispatch", "Finish": "OnGetPropDataCountSp",
                                        "FinishAlt": "OnMakeDump"},
                       "DrawHelper_E", "ViewIDProc_Return", 0x140, 0x15F),
}


def code(x):
    return re.sub(r'\s+', ' ', x.split(";")[0].strip())


def body(L, label):
    k = L.index(label + ":")
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
    for proc, (P1, roles1, P2, epi, s0, s1) in PROCS.items():
        p0, head = body(L, proc)
        p1 = next(i for i in range(p0 + 1, len(L)) if re.match(r'^\w+IDProc:', L[i]))
        inv1 = {v: k for k, v in roles1.items()}
        build, slot_loop, obj_loop, next_slot, disp = (inv1[r] for r in ("BuildIdList", "BuildIdList_SlotLoop",
                                                                         "BuildIdList_ObjLoop", "BuildIdList_NextSlot",
                                                                         "Dispatch"))
        assert head[-6:] == ["cp xiz, EVT_SET_PROPERTY_EX", "jr z, %s_%s" % (P1, build),
                             "cp xiz, EVT_GET_PROP_DATA_COUNT_SP", "jr z, %s_%s" % (P1, build),
                             "cp xiz, EVT_GET_PROP_DATA_SP", "jr nz, %s_%s" % (P1, disp)], (tree, proc, head[-6:])
        _, b = body(L, "%s_%s" % (P1, build))
        assert "ld xwa, 0x%x" % s0 in b, (tree, proc, b)
        _, b = body(L, "%s_%s" % (P1, slot_loop))
        assert "call CountObject" in b, (tree, proc, b)
        _, b = body(L, "%s_%s" % (P1, obj_loop))
        assert b[-1] == "jr c, %s_%s" % (P1, obj_loop), (tree, proc, b)
        _, b = body(L, "%s_%s" % (P1, next_slot))
        assert "cp xwa, 0x%x" % s1 in b and b[-1] == "jr ule, %s_%s" % (P1, slot_loop), (tree, proc, b)
        _, b = body(L, "%s_%s" % (P1, disp))
        assert b[:12] == ["cp xiz, EVT_SET_PROPERTY_EX", "jrl z, %s_DrawTrack" % P2, "cp xiz, EVT_GET_PROPERTY_EX",
                          "jr z, %s_Setup" % P2, "cp xiz, EVT_DUMP_PROPERTY_EX", "jr z, %s_Setup" % P2,
                          "cp xiz, EVT_MAKE_DUMP", "jr z, %s_%s" % (P1, inv1["OnMakeDump"]),
                          "cp xiz, EVT_GET_PROP_DATA_COUNT_SP", "jr z, %s_%s" % (P1, inv1["OnGetPropDataCountSp"]),
                          "cp xiz, EVT_GET_PROP_DATA_SP", "jrl nz, %s_Return" % P2], (tree, proc, b[:12])
        _, b = body(L, "%s_ReturnZero" % P2)
        assert "call Strcmp" in b and "ld xbc, EVT_GET_NAME" in b, (tree, proc, "CompareName")
        _, b = body(L, "%s_CalcRange" % P2)
        assert b[0] == "call %s" % ("ApFunctionProc" if proc == "ApFuncIDProc" else "MainFunctionProc"), (tree, proc, b)
        _, b = body(L, "%s_CalcThumb" % P2)
        assert b[0] == "call Strcpy", (tree, proc, b)
        _, b = body(L, "%s_Return" % P2)
        assert b[-1] == "calr CommonIDProc", (tree, proc, b)
        k, b = body(L, epi)
        assert b == ["pop xiz", "lda xsp, (xsp+4376)", "ret"] and p0 < k < p1, (tree, proc, b)
        for i in range(p0, p1):
            m = re.match(r'^(%s|%s)_(\w+):' % (P1, P2), L[i])
            if m:
                table = roles1 if m.group(1) == P1 else PHASE2
                assert m.group(2) in table, (tree, proc, m.group(0))
                rules["%s_%s" % (m.group(1), m.group(2))] = "%s_%s" % (proc, table[m.group(2)])
        for fam in (P1, P2):
            assert all(p0 < i < p1 for i, x in enumerate(L) if re.match(r'^%s_\w+:' % fam, x)), (tree, fam)
        rules[epi] = "%s_Epilogue" % proc
        rules["%s_FinishAlt_Str_idf" % P1] = "%s_DumpPrefix" % proc
    return rules


def main():
    plans = {t: rules_for(t) for t in ("v10", "v9", "v7")}
    assert plans["v9"] == plans["v10"] and plans["v7"] == plans["v10"], "trees differ"
    defined = set()
    for p in glob.glob(os.path.join(REPO, "v10/maincpu/**/*.s"), recursive=True):
        defined |= set(re.findall(r'^(\w+):', open(p, "rb").read().decode("latin-1"), re.M))
    clash = [n for n in plans["v10"].values() if n in defined]
    assert not clash, clash
    print("%d labels per tree" % len(plans["v10"]))
    if not APPLY:
        for a in sorted(plans["v10"]):
            print("  %-34s -> %s" % (a, plans["v10"][a]))
        return
    for tree, rules in plans.items():
        sed = os.path.join(REPO, "scripts/renaming/rename_objlist_idprocs_%s.sed" % tree)
        open(sed, "w").write("# rename_objlist_idprocs_%s.sed -- written by scripts/renaming/gen_objlist_idproc_names.py\n"
                             % tree + "".join("s/\\b%s\\b/%s/g\n" % (a, rules[a])
                                              for a in sorted(rules, key=len, reverse=True)))
        hit = [p for p in glob.glob(os.path.join(REPO, tree, "maincpu/**/*"), recursive=True)
               if p.endswith((".s", ".c", ".ld")) and
               any(re.search(r'\b%s\b' % a, open(p, "rb").read().decode("latin-1")) for a in rules)]
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  %s: sed applied to %d files" % (tree, len(hit)))


if __name__ == "__main__":
    main()
