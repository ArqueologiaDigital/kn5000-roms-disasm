#!/usr/bin/env python3
"""Name the range arms of prom_b's six ParamRangeArms_* tables by the range they clamp to.

QUESTION IT ANSWERS
  ClampParamValueById_From541 / _From408 index six ParamRangeArms_* tables by a parameter id and `jp` to the arm.
  The tables' header: "Each arm is one or two `push imm16` instructions -- that parameter's MINIMUM and MAXIMUM
  -- and a jump to a shared tail that pushes the mask and the shift and calls ClampFieldToRange".
  ClampFieldToRange's header gives the order the words sit on the stack: (XIZ+8) value, (XIZ+0x0A) mask,
  (XIZ+0x0C) shift, (XIZ+0x0E) maximum, (XIZ+0x10) minimum -- so the pushes run minimum, maximum, shift, mask,
  value, and the clamp is SIGNED.  Each arm is therefore fully described by (minimum, maximum, mask), and that is
  what it is named: ClampArm<base>_<min>To<max>_Mask<hex>, a negative bound spelled M<n> (0xFFC4 -> M60) and <base>
  the id base of the reader whose tables reach it (ClampParamValueById_From541 or _From408: the two readers have
  parallel copies of the same arms).
  The four words are read by following the arm from its label through the source: every `pushw imm` is pushed,
  a `jr`/`jrl` to a label continues there, labels in between are passed, and the walk stops at the value's
  `pushw bc`.  An arm that pushes anything else, or does not reach the value push, is REFUSED.  The two arms that
  push nothing and return (the index-out-of-range exits) are ClampParamValueById_Unchanged / _Unchanged2.

RUN
  python3 notes/prom_b_param_range_arm_names.py          # the plan and the refusals
  python3 notes/prom_b_param_range_arm_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
L = B.split("\n")
IDX = {m.group(1): i for i, l in enumerate(L) for m in [re.match(r'^([A-Za-z_][\w$]*):', l)] if m}
TABLES = [n for n in IDX if n.startswith("ParamRangeArms_")]


def table_entries(t):
    out = []
    for l in L[IDX[t] + 1:IDX[t] + 220]:
        m = re.match(r'^\s*\.long\s+(\w+)', l)
        if m:
            out.append(m.group(1))
        elif l.strip() and not l.startswith(";"):
            break
    return out


def walk(label):
    """The words pushed from `label` to the value push, or None."""
    i, pushes, hops = IDX[label] + 1, [], 0
    while i < len(L) and hops < 6:
        code = re.sub(r'\s+', ' ', L[i].split(";")[0]).strip()
        i += 1
        if not code or re.match(r'^[A-Za-z_][\w$]*:', code):
            continue
        m = re.match(r'^pushw (\d+)$', code)
        if m:
            pushes.append(int(m.group(1)))
            continue
        m = re.match(r'^jrl? (\w+)$', code)
        if m and m.group(1) in IDX:
            i, hops = IDX[m.group(1)] + 1, hops + 1
            continue
        if code == "pushw bc":
            return pushes
        if code in ("ld c, h", "ld c, d", "exts bc") and pushes:
            continue                         # the tail loads the value into BC before pushing it
        if code in ("ld a, h", "ld a, d") and not pushes:
            return []
        return None
    return None


def signed(v):
    return v - 0x10000 if v >= 0x8000 else v


def spell(v):
    v = signed(v)
    return "M%d" % -v if v < 0 else "%d" % v


def plan():
    arms, fam = [], {}
    # the readers' own headers name their tables: ClampParamValueById_From541 indexes F370A7 / F3719C / F37312,
    # ClampParamValueById_From408 F3760E / F37705 / F3782E (the second reader's 217+ code follows an arm, so a
    # label walk would credit it to that arm)
    FAMILY = {"F370A7": "541", "F3719C": "541", "F37312": "541", "F3760E": "408", "F37705": "408", "F3782E": "408"}
    for t in sorted(TABLES):
        for e in table_entries(t):
            if re.match(r'^sub_F[0-9A-F]{5}$', e) and e not in arms:
                arms.append(e)
                fam[e] = FAMILY.get(t[-6:], "?")
    rows, refused, ret_n = [], [], 0
    for a in arms:
        p = walk(a)
        if p == []:
            ret_n += 1
            new = "ClampParamValueById_Unchanged" + ("" if ret_n == 1 else str(ret_n))
            rows.append((a, new, "%s: the out-of-range exit of a ParamRangeArms table -- returns the value unclamped\\n"
                         "  (notes/prom_b_param_range_arm_names.py)." % new))
            continue
        if p is None or len(p) != 4:
            refused.append((a, "pushes %r" % (p,)))
            continue
        mn, mx, sh, mask = p
        # the two readers' arm sets are byte-for-byte parallel copies; the reader's id base tells them apart
        new = "ClampArm%s_%sTo%s_Mask%X" % (fam[a], spell(mn), spell(mx), mask) + ("_Shift%d" % sh if sh else "")
        rows.append((a, new, "%s: a ParamRangeArms arm -- ClampFieldToRange(value, mask 0x%X, shift %d, max %d, min %d), a signed\\n"
                     "  clamp of the masked field to %d..%d (notes/prom_b_param_range_arm_names.py)." % (new, mask, sh, signed(mx), signed(mn), signed(mn), signed(mx))))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    names = [n for _o, n, _h in rows]
    for o, n, h in rows:
        dup = names.count(n) > 1
        if "--args" in sys.argv:
            if not dup and n not in taken:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-12s -> %s%s" % (o, n, "  DUPLICATE" if dup else "  TAKEN" if n in taken else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if names.count(n) == 1 and n not in taken), len(refused)))


if __name__ == "__main__":
    main()
