#!/usr/bin/env python3
"""gen_point_class_idproc_names.py -- the last borrowed-prefix property procedures, named by role (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  After gen_idproc_names.py, gen_name_table_idproc_names.py and gen_objlist_idproc_names.py, six NAKA property
  procedures in ui/ui_widget_defs.s still carried label families borrowed from unrelated code.  They are
  EdgeVariant_A/B/C, ShadowBox_A/B/C (ShadowBox_A even spans two routines) and FrameVariant_A, and each epilogue
  was named after the next routine (POINTWProc_Return, IDCursorProc_Return, ViewFlagProc_Return ...).  Read here:
    RectY2Proc    a rect's y2, edited as "height": SET stores y1 + height - 1; GET prints it with Itoa_Safe; MAKE_DUMP
                  appends "}"; GET_PROP_MEMBER appends the member name "height"
    POINTWProc    CHECK_PROP_STRING copies the string and rewrites it char by char ('U' -> 'V' + 'W'); every other
                  event goes to CommonIDProc
    PointXProc    member "x"; MAKE_DUMP opens with "{"
    PointYProc    member "y"; MAKE_DUMP closes with "}"
    ClassIDProc   class ids: builds the id list over registry slots 0x160..0x17F, then the same name search /
                  GET_NAME / "idc" dump as ApFuncIDProc
    ViewFlagProc  the FrameVariant shape of gen_idproc_names.py
  The map below is per routine.  For each routine and tree, the script asserts its event chain (each EVT_X goes to the
  label the map gives that role) and that every old label lies between the routine's label and the next routine.
  The rules go to scripts/renaming/rename_point_class_idprocs_<tree>.sed; --apply runs them over the tree.

RUN (repository root)
  python3 scripts/renaming/gen_point_class_idproc_names.py [--apply]   # then make all; make gate-all; symbols --regen
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
MAP = {
    "RectY2Proc": {"EdgeVariant_A_Return": "OnSetPropertyEx", "EdgeVariant_A_Execute": "OnGetPropertyEx",
                   "EdgeVariant_A_CalcHeight": "OnDumpPropertyEx", "EdgeVariant_A_CalcHeight2": "ForwardToCommon",
                   "EdgeVariant_A_CalcWidth": "OnMakeDump", "EdgeVariant_A_Setup": "OnGetPropMember",
                   "EdgeVariant_A_Done": "ReturnZero", "EdgeVariant_B_Setup": "ReturnResult",
                   "POINTWProc_Return": "Epilogue"},
    "POINTWProc": {"EdgeVariant_B_CalcWidth": "OnCheckPropString", "EdgeVariant_B_Return": "CheckProp_LoopHead",
                   "EdgeVariant_B_CalcHeight": "CheckProp_MapChar", "EdgeVariant_B_Done": "CheckProp_CopyChar",
                   "EdgeVariant_B_DoneAlt": "CheckProp_NextChar", "EdgeVariant_C_Setup": "Epilogue"},
    "PointXProc": {"EdgeVariant_C_Execute": "OnSetPropertyEx", "EdgeVariant_C_InnerFill": "OnGetOrDumpPropertyEx",
                   "EdgeVariant_C_CalcHeight": "OnMakeDump", "EdgeVariant_C_CalcWidth": "OnGetPropMember",
                   "EdgeVariant_C_CheckInner": "OnCheckPropString", "EdgeVariant_C_CalcHeight2": "ForwardToCommon",
                   "EdgeVariant_C_Done": "ReturnResult", "EdgeVariant_C_Return": "Epilogue"},
    "PointYProc": {"ShadowBox_A_Execute": "OnSetPropertyEx", "ShadowBox_A_InnerFill": "OnGetOrDumpPropertyEx",
                   "ShadowBox_A_CalcWidth": "OnMakeDump", "ShadowBox_A_Setup": "OnGetPropMember",
                   "ShadowBox_A_CheckInner": "OnCheckPropString", "ShadowBox_A_CalcHeight": "ForwardToCommon",
                   "ShadowBox_A_Done": "ReturnResult", "IDCursorProc_Return": "Epilogue"},
    "ClassIDProc": {"ShadowBox_A_Return": "BuildIdList", "ShadowBox_A_CheckAlt": "BuildIdList_SlotLoop",
                    "ShadowBox_A_DrawAlt": "BuildIdList_ObjLoop", "ShadowBox_A_DrawInner": "BuildIdList_NextSlot",
                    "ShadowBox_A_DrawEdge": "Dispatch", "ShadowBox_B_CalcHeight": "OnSetPropertyEx",
                    "ShadowBox_B_CalcWidth": "OnGetOrDumpPropertyEx", "ShadowBox_B_Prologue": "OnMakeDump",
                    "ShadowBox_B_Setup": "OnGetPropDataCountSp", "ShadowBox_B_CheckInner": "GetNameAndCopy",
                    "ShadowBox_B_InnerFill": "StrcpyReturnZero", "ShadowBox_B_Execute": "SetProp_CompareName",
                    "ShadowBox_C_Setup": "SetProp_NextIndex", "ShadowBox_C_CalcWidth": "SetProp_CheckFound",
                    "ShadowBox_C_CalcHeight": "SetProp_StoreId", "ShadowBox_C_Execute": "SetProp_ReturnResult",
                    "ShadowBox_C_Return": "ForwardToCommon", "ViewFlagProc_Return": "Epilogue"},
    "ViewFlagProc": {"FrameVariant_A_Setup": "OnGetOrDumpPropertyEx", "FrameVariant_A_CalcWidth": "ForwardToCommon",
                     "FrameVariant_A_CalcHeight": "OnSetPropertyEx", "FrameVariant_A_Execute": "ReturnResult",
                     "FrameVariant_A_Done": "Epilogue"},
}
DATA = {"EdgeVariant_A_Setup_Str_height": "RectY2Proc_MemberName", "EdgeVariant_A_CalcWidth_Str_RBrace":
        "RectY2Proc_DumpClose", "EdgeVariant_C_CalcWidth_Str_x": "PointXProc_MemberName",
        "EdgeVariant_C_CalcHeight_Str_LBrace": "PointXProc_DumpOpen", "ShadowBox_A_Setup_Str_y": "PointYProc_MemberName",
        "ShadowBox_A_CalcWidth_Str_RBrace": "PointYProc_DumpClose", "ShadowBox_B_Prologue_Str_idc": "ClassIDProc_DumpPrefix"}
EVENT_ROLE = {"EVT_SET_PROPERTY_EX": "OnSetPropertyEx", "EVT_GET_PROPERTY_EX": ("OnGetPropertyEx", "OnGetOrDumpPropertyEx"),
              "EVT_DUMP_PROPERTY_EX": ("OnDumpPropertyEx", "OnGetOrDumpPropertyEx"), "EVT_MAKE_DUMP": "OnMakeDump",
              "EVT_GET_PROP_MEMBER": "OnGetPropMember", "EVT_CHECK_PROP_STRING": "OnCheckPropString",
              "EVT_GET_PROP_DATA_COUNT_SP": "OnGetPropDataCountSp"}


def code(x):
    return re.sub(r'\s+', ' ', x.split(";")[0].strip())


def rules_for(tree):
    L = open(os.path.join(REPO, tree, "maincpu/ui/ui_widget_defs.s"), "rb").read().decode("latin-1").split("\n")
    rules = {}
    for proc, m in MAP.items():
        p0 = L.index(proc + ":")
        p1 = next(i for i in range(p0 + 1, len(L)) if re.match(r'^\w+Proc:', L[i]))
        where = {re.match(r'^(\w+):', L[i]).group(1): i for i in range(p0, p1) if re.match(r'^\w+:', L[i])}
        for old, role in m.items():
            assert old in where, (tree, proc, old)
            rules[old] = "%s_%s" % (proc, role)
        # every `cp <reg>, EVT_X / jr(l) z, T` inside the routine sends EVT_X to the label holding its role
        for i in range(p0, p1):
            mm = re.match(r'^cp (xiz|xbc), (EVT_\w+)$', code(L[i]))
            if not mm or mm.group(2) not in EVENT_ROLE:
                continue
            mz = re.match(r'^jrl? z, (\w+)$', code(L[i + 1]))
            if not mz:
                continue
            want = EVENT_ROLE[mm.group(2)]
            want = want if isinstance(want, tuple) else (want,)
            got = m.get(mz.group(1))
            assert got in want or (proc == "ClassIDProc" and got == "BuildIdList"), (tree, proc, mm.group(2), mz.group(1), got)
    for old, new in DATA.items():
        rules[old] = new
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
        return
    for tree, rules in plans.items():
        sed = os.path.join(REPO, "scripts/renaming/rename_point_class_idprocs_%s.sed" % tree)
        open(sed, "w").write("# rename_point_class_idprocs_%s.sed -- written by scripts/renaming/"
                             "gen_point_class_idproc_names.py\n" % tree +
                             "".join("s/\\b%s\\b/%s/g\n" % (a, rules[a]) for a in sorted(rules, key=len, reverse=True)))
        hit = [p for p in glob.glob(os.path.join(REPO, tree, "maincpu/**/*"), recursive=True)
               if p.endswith((".s", ".c", ".ld")) and
               any(re.search(r'\b%s\b' % a, open(p, "rb").read().decode("latin-1")) for a in rules)]
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  %s: sed applied to %d files" % (tree, len(hit)))


if __name__ == "__main__":
    main()
