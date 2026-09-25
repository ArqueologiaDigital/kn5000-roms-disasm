#!/usr/bin/env python3
r"""POINT THE SOUND EDITOR'S CODE AT THE SCREEN-DATA BLOCK BY ITS NEW NAMES.

QUESTION ANSWERED
-----------------
After se_screendata_render.py every object in [SeScreenData, SeScreenData_End)
has a label that says what it is.  The code that uses those objects still
names them numerically (`ld xiy, 0x00f1115e`) or through positional aliases
of the OLD, wrong base names (`SeBitmap_EnvCurve5_0x46B` is a record list, not
part of a bitmap; `TuningSystem_Handler_Table_0x1A15` is not a handler).
This rewrites those operands, in lane seui's own files only, to the label the
block now defines at the same address.

RULES
  * only operands (never comments); only values that land EXACTLY on a label
    defined inside the block by lane seui (SeScreenData_0xNNNN, SeBitmap_*,
    or a kept label such as TuningSys_Param_01);
  * a positional alias is replaced only if its value (from the linked ELF)
    equals that label's value -- so the bytes cannot move;
  * a value with no label of its own (a list's exclusive END that is not
    itself an object start) is written `<nearest preceding label> + N`;
  * the positional `.set` definitions themselves live in
    shared/positional_labels.s (lane sys) and are not touched; they become
    unreferenced by these files.
  The byte gate certifies the result (a wrong substitution moves bytes).

RUN
    make rebuilt_ROMs/kn5000_v10_program.llvm.elf
    python3 scripts/lanes/seui/se_screendata_symbolize_refs.py --image v10 [--apply]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
import se_screendata_model as sm          # noqa: E402

FILES = ["audio/sound_editor_ui.s", "audio/semenu_routines.s",
         "audio/sndparam_routines.s", "audio/sound_editor_routines.s"]
KEPT = ("SeMenu_CompareScreen_DataTable", "TuningSys_Param_01",
        "SeBitmap_EnvCurve1", "SeBitmap_EnvCurve2", "SeBitmap_EnvCurve3",
        "SeBitmap_EnvCurve4", "SeBitmap_EnvCurve5")
TOK = re.compile(r"\b(0x00f1[0-9a-fA-F]{4}|[A-Za-z_][\w]*)\b")


def split_comment(t):
    q = False
    for i, c in enumerate(t):
        if c == '"':
            q = not q
        elif c == ";" and not q:
            return t[:i], t[i:]
    return t, ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    s = sm.symbols(a.image)
    lo, hi = s["SeScreenData"], s["SeScreenData_End"]
    # the canonical name at each block address
    canon = {}
    for n, v in s.items():
        if not (lo <= v < hi):
            continue
        good = (n.startswith("SeScreenData_0x") or n in KEPT or
                (n.startswith("SeBitmap_") and not re.search(r"_0x[0-9A-F]+$", n)))
        if good:
            # a specific name beats the block's own bracket label
            if v not in canon or canon[v] == "SeScreenData" or canon[v].startswith("SeScreenData_0x") and not n.startswith("SeScreenData"):
                canon[v] = n
    canon.setdefault(lo, "SeScreenData")
    total = {}
    for rel in FILES:
        p = os.path.join(ROOT, a.image, "maincpu", rel)
        if not os.path.exists(p):
            continue
        L = open(p, encoding="latin-1").read().split("\n")
        n = 0
        for i, ln in enumerate(L):
            code, com = split_comment(ln)
            if code.lstrip().startswith((".set", ".equ")):
                continue

            def sub(m):
                nonlocal n
                t = m.group(1)
                if t.lower().startswith("0x00f1"):
                    v = int(t, 16)
                elif t in s and (re.search(r"_0x[0-9A-F]+$", t) or t.startswith("TuningSys_Param_")) \
                        and t not in canon.values():
                    v = s[t]
                else:
                    return t
                if v in canon and canon[v] != t:
                    n += 1
                    return canon[v]
                if lo < v <= hi and v not in canon:
                    # a list END that is no object's start: name it from the
                    # nearest labelled object before it
                    p = max(k for k in canon if k < v)
                    n += 1
                    return "%s + %d" % (canon[p], v - p)
                return t
            new = TOK.sub(sub, code)
            # never rewrite a label definition
            if re.match(r"^\s*[A-Za-z_][\w]*:", code) and new.split(":")[0] != code.split(":")[0]:
                continue
            L[i] = new + com
        total[rel] = n
        if a.apply and n:
            open(p, "wb").write("\n".join(L).encode("latin-1"))
    print("%s: %s" % (a.image, ", ".join("%s %d" % (k, v) for k, v in total.items())))


if __name__ == "__main__":
    main()
