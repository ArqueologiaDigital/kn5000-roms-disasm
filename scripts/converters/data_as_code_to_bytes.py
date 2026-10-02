#!/usr/bin/env python3
"""data_as_code_to_bytes.py -- a table that only data points at, decoded as nonsense instructions, back to data.

QUESTION THIS ANSWERS / JOB IT DOES
  CLAUDE.md, Cross-Version policy 4 (No Faux-Instructions in Data): data bytes must not be
  written as TLCS-900 instructions.  Linear conversion did exactly that wherever a table sat
  between routines -- sequencer/accompaniment_engine.s:
      AccPart_VoiceParamOffsets_BaseA:      (reached only through `.long` pointer tables)
              nop / nop / jr le, 0 / ld h, (-xwa0) / normal / ld h, 5:opc / .byte ... / halt
  and symbolize_numeric_branches.py then refuses the fake branches ("R3 absurd block", 392 in
  v10).  For every column-0 label that
    * sits on a line the census calls code,
    * is used ONLY by data -- `.long` / `.short` / `addr24` entries -- never as the target of a
      call / jump / branch and never as an instruction operand (an operand can be a code
      pointer: `lda xix, (ExtData_ToneParam_AltBody_Code:24)` heads a table of `jr` vectors),
    * heads lines (up to the next label, at most 4 KB) whose first 8 instructions hold one that
      real code here never contains (normal, max, min, halt, swi, decf, incf, ldf),
  this re-spells those lines as `.byte` rows (16 per line) through scoop_reframe.py apply --
  whole-image byte check, labels and comments carried -- with one comment line saying why.
  The table's layout is NOT claimed: bytes are the honest form until a reader is analysed.

USAGE
  make all
  python3 scripts/converters/data_as_code_to_bytes.py --image v10 [--apply] [--report OUT.json]
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import scoop_reframe as SR                    # noqa: E402
import reframe_prefix_bytes as RP             # noqa: E402
import symbolize_numeric_branches as snb      # noqa: E402

COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')
IDENT = re.compile(r'(?<![\w.$])([A-Za-z_][\w.$]*)')
BRANCH = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*(call|calr|jp|jr|jrl|djnz)\b', re.I)
DATA = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*(\.long|\.4byte|\.short|\.2byte|addr24)\b', re.I)
# reti / ei / di are NOT markers here: interrupt handlers are reached only through the
# vector table (`.long`) and end in reti (INT0_HANDLER, Empty_Handler)
ABSURD = re.compile(r'^(normal|max|min|halt|swi|decf|incf|ldf)\b', re.I)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    files = RP.assembled(a.image)
    amap, _ = SR.linemap(a.image, files)
    macros = snb.drc.collect_macros(os.path.join(REPO, a.image, "maincpu"))
    texts = {rel: open(os.path.join(REPO, rel), "rb").read().decode("latin-1").split("\n") for rel in files}
    labels = {}                                         # name -> (rel, li)
    for rel, L in texts.items():
        for i, l in enumerate(L):
            m = COL0.match(l)
            if m:
                labels[m.group(1)] = (rel, i)
    uses = collections.defaultdict(collections.Counter)
    for rel, L in texts.items():
        for l in L:
            code = SR.strip_comment(l)[0]
            body = re.sub(r'^[A-Za-z_][\w.$]*:', '', code)
            if not body.strip():
                continue
            kind = "branch" if BRANCH.match(body) else "data" if DATA.match(body) else "operand"
            if body.strip().startswith((".set", ".equ")):
                kind = "alias"
            for m in IDENT.finditer(body):
                if m.group(1) in labels:
                    uses[m.group(1)][kind] += 1
    st, specs, rows = collections.Counter(), collections.defaultdict(list), []
    for name, (rel, li) in sorted(labels.items(), key=lambda kv: kv[1]):
        L, addrs = texts[rel], amap[rel]
        u = uses.get(name, collections.Counter())
        if not u or u["branch"] or u["alias"] or u["operand"] or not u["data"]:
            continue                    # an operand may be a code pointer (`lda xix, (X:24)` + jump)
        if snb.drc.classify_line(L[li], macros)[0] != "code" and not any(
                snb.drc.classify_line(L[j], macros)[0] == "code" for j in range(li + 1, min(li + 3, len(L)))
                if SR.strip_comment(L[j])[0].strip()):
            continue
        A = next((addrs[j] for j in range(li, len(L)) if addrs[j] is not None), None)
        j, absurd, n_ins = li + 1, [], 0
        while j < len(L):
            code = SR.strip_comment(L[j])[0].strip()
            if COL0.match(L[j]) or code.startswith((".include", ".org", ".balign", ".align", ".section")):
                break
            if code:
                n_ins += 1
                if ABSURD.match(code) and n_ins <= 8:
                    absurd.append(code.split()[0])
            j += 1
        B = next((addrs[k] for k in range(j, len(L)) if addrs[k] is not None), None)
        if A is None or B is None or not (0 < B - A <= 4096):
            st["no clean extent"] += 1
            continue
        if not absurd:
            st["decode looks like code: left"] += 1
            continue
        why = "data, not code: %s is reached only as data (%s), and its instruction decode held %s" % (
            name, ", ".join("%d %s" % (v, k) for k, v in sorted(u.items()) if v),
            ", ".join(sorted(set(absurd))))
        specs[rel].append(dict(file=rel, start="0x%X" % A, end="0x%X" % B,
                               segments=[dict(kind="byte", len=B - A)],
                               comments={"0x%X" % A: [why + " (scripts/converters/data_as_code_to_bytes.py)."]}))
        rows.append(dict(label=name, file=rel, start=hex(A), end=hex(B), uses=dict(u), absurd=sorted(set(absurd))))
        st["candidate"] += 1
    print("%s: %s" % (a.image, dict(st)))
    if a.apply:
        done = 0
        for rel, sp in sorted(specs.items()):
            for chunk in ([sp] if len(sp) > 1 else []) + [[x] for x in sp]:
                path = os.path.join(SR.SCRATCH, "d2b-%s.json" % os.getpid())
                json.dump(chunk, open(path, "w"))
                r = subprocess.run([sys.executable, os.path.join(REPO, "scripts", "converters", "scoop_reframe.py"),
                                    "apply", "--image", a.image, "--spec", path], capture_output=True, text=True)
                out = r.stdout + r.stderr
                if r.returncode == 0 and "REJECT" not in out and "refus" not in out.lower():
                    done += len(chunk)
                    if len(chunk) > 1:
                        break
                elif len(chunk) == 1:
                    st["refused by scoop_reframe"] += 1
        st["applied"] = done
        print("%s: %s" % (a.image, dict(st)))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
