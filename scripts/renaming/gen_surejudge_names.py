#!/usr/bin/env python3
"""gen_surejudge_names.py -- SureJudgeFunc's "are you sure?" switch: named by the titles it serves (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  SureJudgeFunc (sequencer/sequencer_ui.s), on EVT_SW_IN: if the byte at RAM 0x0340EA is 0 it posts
  MainExeCall at once.  Otherwise it falls into a switch on the current title (GetTitleNow):
  TITLE_SQSNGCP and TITLE_SQSNGCLR are tested directly, and TITLE_SQTRKCLR + 0..14 index a 15-entry case table.
  Every case does `ld xwa, <view id>; ld xbc, EVT_SHOW; call SendEvent`.  The view element is that page's
  "SureDisp" widget: 0x900009 NakaWidget_SoclSureDisp, 0x9A0006 NakaWidget_TrkClrSureDisp,
  0xA20009 NakaWidget_McpSureDisp ... (nakarest_objtab_map.py).  So the switch shows the confirmation box of
  the edit page the user is on.  It was named Equalizer_CmdDispatch, with cases Equalizer_CmdCase0/1 and
  Equalizer_CmdDispatch_Case<title id in decimal>.
  This script checks that each table slot k targets the case named for title (TITLE_SQTRKCLR + k), or the shared
  return, and that the two direct tests are SQSNGCP -> Case1 and SQSNGCLR -> Case0.  Slot 14 (TITLE_SQSNGCPC)
  also targets Case1, the song-copy box.  It then writes
  scripts/renaming/rename_surejudge_<tree>.sed:
      Equalizer_CmdDispatch -> SureJudge_ShowSureDisp, its _CaseTable likewise,
      Equalizer_CmdCase0/1 and _Case<id> -> SureJudge_OnTitle<Name> (TITLE_SQTRKCLR -> TitleSqtrkclr, the spelling
      gen_title_switch_case_names.py uses),
      ParamCmd_SendAndReturnZero -> SureJudge_SendShowEvent, ParamCmd_ReturnZero -> SureJudge_ReturnZero,
      Equalizer_FormatValue (MainExeFunc's `ld xhl, 0; ret`) -> MainExeFunc_ReturnZero.
  --apply runs each sed over the tree's .s/.c/.ld files that hold an old name.

RUN (repository root)
  python3 scripts/renaming/gen_surejudge_names.py [--apply]     # then make all; make gate-all; symbols --regen
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv


def titles():
    t = {}
    for line in open(os.path.join(REPO, "v10/maincpu/shared/event_codes.s"), "rb").read().decode("latin-1").split("\n"):
        m = re.match(r'\.equ\s+(TITLE_\w+),\s*(0x[0-9a-fA-F]+)', line)
        if m:
            t[m.group(1)] = int(m.group(2), 16)
    return t


def spell(name):
    return "Title" + name[len("TITLE_"):].capitalize()


def main():
    T = titles()
    for tree in ("v10", "v9", "v7"):
        root = os.path.join(REPO, tree, "maincpu")
        seq = open(os.path.join(root, "sequencer/sequencer_ui.s"), "rb").read().decode("latin-1").split("\n")
        wd = open(os.path.join(root, "ui_widgets/widget_descriptors.s"), "rb").read().decode("latin-1").split("\n")
        k = seq.index("Equalizer_CmdDispatch:")
        body = [re.sub(r'\s+', ' ', x.split(";")[0].strip()) for x in seq[k + 1:k + 20] if x.split(";")[0].strip()]
        assert body[:10] == ["ld wa, 0:i3", "call SetDialEnable", "call GetTitleNow", "ld xwa, xhl",
                             "cp xhl, TITLE_SQSNGCP", "jr z, Equalizer_CmdCase1", "cp xhl, TITLE_SQSNGCLR",
                             "jr z, Equalizer_CmdCase0", "sub xwa, TITLE_SQTRKCLR", "cp xwa, 0x0"], (tree, body[:10])
        assert "cp xwa, 0xe" in body and "add xwa, Equalizer_CmdDispatch_CaseTable" in body, tree
        kc = wd.index("Equalizer_CmdDispatch_CaseTable:")
        slots = []
        for x in wd[kc + 1:]:
            m = re.match(r'^\s*\.short\s+(\w+) - Equalizer_CmdCase0\s*$', x)
            if not m:
                break
            slots.append(m.group(1))
        assert len(slots) == 15, (tree, len(slots))
        rules = {"Equalizer_CmdDispatch_CaseTable": "SureJudge_ShowSureDisp_CaseTable",
                 "Equalizer_CmdDispatch": "SureJudge_ShowSureDisp",
                 "Equalizer_CmdCase0": "SureJudge_On" + spell("TITLE_SQSNGCLR"),
                 "Equalizer_CmdCase1": "SureJudge_On" + spell("TITLE_SQSNGCP"),
                 "ParamCmd_SendAndReturnZero": "SureJudge_SendShowEvent",
                 "ParamCmd_ReturnZero": "SureJudge_ReturnZero",
                 "Equalizer_FormatValue": "MainExeFunc_ReturnZero"}
        inv = {v: n for n, v in T.items()}
        for i, tgt in enumerate(slots):
            if tgt == "ParamCmd_ReturnZero":
                continue
            title = inv[T["TITLE_SQTRKCLR"] + i]
            if tgt == "Equalizer_CmdCase1":           # slot 14, TITLE_SQSNGCPC, shares the song-copy box
                assert title == "TITLE_SQSNGCPC", (tree, i, title)
                continue
            m = re.match(r'^Equalizer_CmdDispatch_Case(\d+)$', tgt)
            assert m and int(m.group(1)) == T[title], (tree, i, tgt, title)
            assert slots.count(tgt) == 1, (tree, tgt)
            rules[tgt] = "SureJudge_On" + spell(title)
        defined = set()
        files = [p for p in glob.glob(os.path.join(root, "**", "*"), recursive=True) if p.endswith((".s", ".c", ".ld"))]
        texts = {p: open(p, "rb").read().decode("latin-1") for p in files}
        for s in texts.values():
            defined |= set(re.findall(r'^(\w+):', s, re.M))
        for new in rules.values():
            assert new not in defined, (tree, new)
        sed = os.path.join(REPO, "scripts/renaming/rename_surejudge_%s.sed" % tree)
        lines = ["# rename_surejudge_%s.sed -- written by scripts/renaming/gen_surejudge_names.py" % tree]
        lines += ["s/\\b%s\\b/%s/g" % (a, rules[a]) for a in sorted(rules, key=len, reverse=True)]
        print("%s: %d rules (%d title cases)" % (tree, len(rules), sum(1 for v in rules.values() if "OnTitle" in v)))
        if not APPLY:
            for a in sorted(rules):
                print("  %-40s -> %s" % (a, rules[a]))
            continue
        open(sed, "w").write("\n".join(lines) + "\n")
        hit = [p for p, s in texts.items() if any(re.search(r'\b%s\b' % a, s) for a in rules)]
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  sed applied to %d files" % len(hit))


if __name__ == "__main__":
    main()
