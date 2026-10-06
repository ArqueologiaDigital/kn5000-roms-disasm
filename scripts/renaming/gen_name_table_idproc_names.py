#!/usr/bin/env python3
"""gen_name_table_idproc_names.py -- FontIDProc, IconIDProc and BitmapIDProc labels named for what they do (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  Three NAKA property types keep their values as indexes into a name table: FontIDProc (the RAM table at 0x3EFAC,
  font names CHARA1 ...), IconIDProc (IconIDProc_PtrTable) and BitmapIDProc (BitmapIDProc_PtrTable).  Their labels
  were named SliderH_*, SliderV_* and DrawHelper_A_* (CalcThumb, DrawTrack, ClampThumb ...) by an earlier
  body-reading pass, and each routine's epilogue carried the NEXT routine's name: BitmapIDProc_Return is
  IconIDProc's `pop xiz / ret`, and ApFuncIDProc_Return is BitmapIDProc's.  All three have one shape, asserted here
  for each, in each tree:
      SET_PROPERTY_EX        DrawTrack: index = 0, result = -1, then the search loop:
                             ReturnAlt (loop head: table[i] == 0 ends it), DrawThumb (Strcmp(table[i], text)),
                             ReturnZero (`inc 1, xiz`), ReturnAlt2 (found: store i at the cursor),
                             ReturnAlt3 (return the result)
      GET / DUMP_PROPERTY_EX CalcRange: read the id at the cursor, push table[id]; CalcThumb pushes the buffer and
                             CalcThumb_Clamp / ClampThumb does Strcpy and returns 0
      MAKE_DUMP              Prologue: Strcpy(<prefix>) + Strcat(the name): "id", "idICON_", "id"
      GET_PROP_DATA_COUNT_SP Setup: return the u16 entry count
      anything else          Return / ReturnAlt4: forward to CommonIDProc
  The labels become <Proc>_OnSetPropertyEx, _SetProp_LoopHead, _SetProp_CompareName, _SetProp_NextIndex,
  _SetProp_StoreIndex, _SetProp_ReturnResult, _OnGetOrDumpPropertyEx, _CopyNameToBuffer, _StrcpyReturnZero,
  _OnMakeDump, _OnGetPropDataCountSp, _ForwardToCommon and _Epilogue.  The data they read become
  <Proc>_EntryCount (BitmapIDProc's was DrawHelper_A_Setup_Str_DQuote, but it is the word 0x0022, 34 bitmaps,
  not a string) and <Proc>_DumpPrefix.  The rules go to scripts/renaming/rename_name_table_idprocs_<tree>.sed;
  --apply runs it over the tree's .s/.c/.ld files.

RUN (repository root)
  python3 scripts/renaming/gen_name_table_idproc_names.py [--apply]   # then make all; make gate-all; symbols --regen
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
PROCS = {  # proc: (family prefix, forward label suffix, epilogue label, entry-count label, dump-prefix label)
    "FontIDProc": ("SliderH", "ReturnAlt4", "SliderH_ReturnAlt5", "SliderH_Setup_Data", "SliderH_Prologue_Str_id"),
    "IconIDProc": ("SliderV", "Return", "BitmapIDProc_Return", "SliderV_Setup_Data", "SliderV_Prologue_Str_idICON"),
    "BitmapIDProc": ("DrawHelper_A", "Return", "ApFuncIDProc_Return", "DrawHelper_A_Setup_Str_DQuote",
                     "DrawHelper_A_Prologue_Str_id"),
}
ROLE = {"DrawTrack": "OnSetPropertyEx", "ReturnAlt": "SetProp_LoopHead", "DrawThumb": "SetProp_CompareName",
        "ReturnZero": "SetProp_NextIndex", "ReturnAlt2": "SetProp_StoreIndex", "ReturnAlt3": "SetProp_ReturnResult",
        "CalcRange": "OnGetOrDumpPropertyEx", "CalcThumb": "CopyNameToBuffer", "CalcThumb_Clamp": "StrcpyReturnZero",
        "ClampThumb": "StrcpyReturnZero", "Prologue": "OnMakeDump", "Setup": "OnGetPropDataCountSp"}


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
    for proc, (X, fwd, epi, cnt, pfx) in PROCS.items():
        p0, head = body(L, proc)
        p1 = next(i for i in range(p0 + 1, len(L)) if re.match(r'^\w+IDProc:', L[i]))
        want = ["cp xbc, EVT_SET_PROPERTY_EX", "jrl z, %s_DrawTrack" % X, "cp xbc, EVT_GET_PROPERTY_EX",
                "jr z, %s_CalcRange" % X, "cp xbc, EVT_DUMP_PROPERTY_EX", "jr z, %s_CalcRange" % X,
                "cp xbc, EVT_MAKE_DUMP", "jr z, %s_Prologue" % X, "cp xbc, EVT_GET_PROP_DATA_COUNT_SP",
                "jr z, %s_Setup" % X, "cp xbc, EVT_GET_PROP_DATA_SP", "jrl nz, %s_%s" % (X, fwd)]
        assert head[3:15] == want, (tree, proc, head[3:15])
        checks = {"DrawTrack": lambda b: b[:3] == ["ld xwa, 0xffffffff", "ld (xsp + 4), xwa", "ld xiz, 0:i3"],
                  "DrawThumb": lambda b: "call Strcmp" in b,
                  "ReturnZero": lambda b: b == ["inc 1, xiz"],
                  "ReturnAlt": lambda b: "jr nz, %s_DrawThumb" % X in b,
                  "ReturnAlt2": lambda b: b == ["ld XWA, (xsp + 0x0108)", "calr IDCursorAdvance", "ld (xhl), xiz"],
                  "ReturnAlt3": lambda b: b[0] == "ld xhl, (xsp + 4)",
                  "CalcRange": lambda b: "calr IDCursorAdvance" in b,
                  "Prologue": lambda b: "call Strcat" in b and b[0].startswith("pushw %s@hi16" % pfx),
                  "Setup": lambda b: b[0] == "ld hl, (%s:24)" % cnt}
        for suf, ok in checks.items():
            _, b = body(L, "%s_%s" % (X, suf))
            assert ok(b), (tree, proc, suf, b)
        _, b = body(L, "%s_%s" % (X, fwd))
        assert b == ["ld XDE, (xsp + 0x0108)", "calr CommonIDProc"], (tree, proc, b)
        k, b = body(L, epi)
        assert b == ["pop xiz", "lda xsp, (xsp+264)", "ret"] and p0 < k < p1, (tree, proc, b)
        assert all(p0 < i < p1 for i, x in enumerate(L) if re.match(r'^%s_\w+:' % X, x)), (tree, proc, "outside")
        for i in range(p0, p1):
            m = re.match(r'^%s_(\w+):' % X, L[i])
            if m:
                suf = m.group(1)
                new = ROLE.get(suf) or {fwd: "ForwardToCommon"}.get(suf) or \
                    ("Epilogue" if "%s_%s" % (X, suf) == epi else None)
                assert new, (tree, proc, suf)
                rules["%s_%s" % (X, suf)] = "%s_%s" % (proc, new)
        rules[epi] = "%s_Epilogue" % proc
        rules[cnt] = "%s_EntryCount" % proc
        rules[pfx] = "%s_DumpPrefix" % proc
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
        sed = os.path.join(REPO, "scripts/renaming/rename_name_table_idprocs_%s.sed" % tree)
        open(sed, "w").write("# rename_name_table_idprocs_%s.sed -- written by scripts/renaming/"
                             "gen_name_table_idproc_names.py\n" % tree +
                             "".join("s/\\b%s\\b/%s/g\n" % (a, rules[a]) for a in sorted(rules, key=len, reverse=True)))
        hit = [p for p in glob.glob(os.path.join(REPO, tree, "maincpu/**/*"), recursive=True)
               if p.endswith((".s", ".c", ".ld")) and
               any(re.search(r'\b%s\b' % a, open(p, "rb").read().decode("latin-1")) for a in rules)]
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  %s: sed applied to %d files" % (tree, len(hit)))


if __name__ == "__main__":
    main()
