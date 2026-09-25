#!/usr/bin/env python3
r"""annotate_v142_param_meta_refs.py -- per-object lines for the effect parameter metadata.

QUESTION THIS ANSWERS
    In subcpu_data_tables.s's per-effect parameter metadata block (0x0133CF-0x014738:
    RANGE arrays, DEFAULTS records, the COUNT table and two 100-entry pointer tables),
    which effect numbers point at each RANGE array / DEFAULTS record, how many 6-byte range
    records does each array hold, and does that agree with EFF_ParamCount_Table?

    The block header explains the layout once; the objects themselves said nothing about who
    uses them.  This script reads the two pointer tables AS WRITTEN in the source (they are
    symbolic `.long <label>` lines, so the byte gate pins every link), counts records, checks
    the count table, and writes ONE line directly above each label:

        ; Pointed to by EFF_ParamRanges_PtrTable (effects 1 6): 5 range records; ...

    Lines it wrote start with "; Pointed to by EFF_Param" and are regenerated on re-run.
    No reader of the pointer tables themselves is known (see the block header's RE-CHECKED
    note), so the line says "pointed to by", not "read by".

RUN
    python3 scripts/tools/annotate_v142_param_meta_refs.py           # dry: counts + check
    python3 scripts/tools/annotate_v142_param_meta_refs.py --apply
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "v142/subcpu/subcpu_data_tables.s")
PREFIX = "; Pointed to by EFF_Param"


def ranges(nums):
    nums = sorted(nums)
    out, i = [], 0
    while i < len(nums):
        j = i
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1:
            j += 1
        out.append(str(nums[i]) if i == j else "%d-%d" % (nums[i], nums[j]))
        i = j + 1
    return " ".join(out)


def table(lines, label, n):
    i = lines.index(label + ":")
    out = []
    for ln in lines[i + 1:]:
        m = re.match(r"^\s*\.long\s+(\w+)", ln)
        if m:
            out.append(m.group(1))
            if len(out) == n:
                return out
    sys.exit("table %s short" % label)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    lines = open(SRC, "rb").read().decode("latin-1").split("\n")
    rp = table(lines, "EFF_ParamRanges_PtrTable", 100)
    dp = table(lines, "EFF_ParamDefaults_PtrTable", 100)
    # count table
    i = lines.index("EFF_ParamCount_Table:")
    counts = []
    for ln in lines[i + 1:]:
        m = re.match(r"^\s*\.byte\s+(.*)$", ln.split(";")[0])
        if not m:
            break
        counts += [int(x.strip(), 0) for x in m.group(1).split(",")]
    counts = counts[:100]
    users_r, users_d = {}, {}
    for e, l in enumerate(rp):
        users_r.setdefault(l, []).append(e)
    for e, l in enumerate(dp):
        users_d.setdefault(l, []).append(e)
    # record counts of range arrays
    nrec = {}
    for lab in users_r:
        j = lines.index(lab + ":") + 1
        k = 0
        while j < len(lines) and re.match(r"^\s*\.byte\s", lines[j]):
            k += len([x for x in lines[j].split(";")[0].split(".byte", 1)[1].split(",") if x.strip()]) // 6
            j += 1
        nrec[lab] = k
    mism = [(e, counts[e], nrec[rp[e]]) for e in range(100)
            if rp[e] != "EffDefault_ParamRanges" and counts[e] != nrec[rp[e]]]
    out, changed = [], 0
    for ln in lines:
        m = re.match(r"^(\w+):\s*$", ln)
        if m and (m.group(1) in users_r or m.group(1) in users_d):
            lab = m.group(1)
            old = []
            while out and out[-1].startswith(PREFIX):
                old.insert(0, out.pop())
            if lab in users_r:
                us = users_r[lab]
                c = sorted({counts[e] for e in us})
                txt = ("%sRanges_PtrTable (effect%s %s): %d range record%s {s16 BE min, s16 BE max, "
                       "u16 BE selector}; EFF_ParamCount_Table says %s." %
                       (PREFIX, "s" if len(us) > 1 else "", ranges(us), nrec[lab], "" if nrec[lab] == 1 else "s",
                        "/".join(map(str, c))))
            else:
                us = users_d[lab]
                txt = ("%sDefaults_PtrTable (effect%s %s): 23-byte defaults record, one byte per range "
                       "record in order, final byte 99." % (PREFIX, "s" if len(us) > 1 else "", ranges(us)))
            new = [txt]
            changed += old != new
            out += new
        out.append(ln)
    print("range arrays: %d, defaults records: %d, lines changed: %d" %
          (len(users_r), len(users_d), changed))
    print("count-table mismatches (dedicated arrays only): %s" % (mism or "none"))
    if a.apply and changed:
        open(SRC, "wb").write("\n".join(out).encode("latin-1"))
        print("rewrote", os.path.relpath(SRC, ROOT))


if __name__ == "__main__":
    main()
