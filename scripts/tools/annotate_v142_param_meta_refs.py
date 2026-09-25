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

    ★ 2026-09-25: a SECOND line per object ("; Main-CPU twin ...", also regenerated) names
    the byte-identical copy of the object in the main-CPU program ROM and the main-CPU
    routines that read that copy.  The twin addresses are COMPUTED here from the object's
    offset in the block (range arrays: same offset from 0xEE4FC6; defaults record k: 0xEE5A40
    + 24*k) and PROVEN by scripts/analysis/v142_param_meta_maincpu_twin.py, which compares
    the ROM bytes and checks the readers' operands.  The defaults line no longer says "one
    byte per range record in order": byte 0 of every dedicated record is the effect number
    (59 of 59), which is what the main-CPU reader indexes its descriptor table with.

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
TWIN = "; Main-CPU twin "
S_RANGES, S_DEFAULTS, M_RANGES, M_DEFAULTS = 0x0133CF, 0x013E49, 0xEE4FC6, 0xEE5A40


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
    # sub-CPU address of every label in the block, by counting .byte items from its start
    addr, ad, j = {}, S_RANGES, lines.index("EffDefault_ParamRanges:")
    while not lines[j].startswith("EFF_ParamCount_Table:"):
        m = re.match(r"^(\w+):\s*$", lines[j])
        if m:
            addr[m.group(1)] = ad
        m = re.match(r"^\s*\.byte\s+(.*)$", lines[j].split(";")[0])
        if m:
            ad += len([x for x in m.group(1).split(",") if x.strip()])
        j += 1
    assert addr["EffDefault_ParamDefaults"] == S_DEFAULTS and ad == 0x0143AD, (hex(ad),)
    mism = [(e, counts[e], nrec[rp[e]]) for e in range(100)
            if rp[e] != "EffDefault_ParamRanges" and counts[e] != nrec[rp[e]]]
    out, changed = [], 0
    for ln in lines:
        m = re.match(r"^(\w+):\s*$", ln)
        if m and (m.group(1) in users_r or m.group(1) in users_d):
            lab = m.group(1)
            old = []
            while out and (out[-1].startswith(PREFIX) or out[-1].startswith(TWIN)):
                old.insert(0, out.pop())
            if lab in users_r:
                us = users_r[lab]
                c = sorted({counts[e] for e in us})
                txt = ("%sRanges_PtrTable (effect%s %s): %d range record%s {s16 BE min, s16 BE max, "
                       "u16 BE selector}; EFF_ParamCount_Table says %s." %
                       (PREFIX, "s" if len(us) > 1 else "", ranges(us), nrec[lab], "" if nrec[lab] == 1 else "s",
                        "/".join(map(str, c))))
                twin = ("%sat 0x%06X (byte-identical, same offset in the block); its records are decoded there by "
                        "DSPCfg_ExtractPairFromStruct (0xFDC3C9), called from DSPCfg_LookupAndExtract (0xFDC41D) and "
                        "DSPCfg_ClampAndExtract (0xFDC803): record n at +6n; +0 and +2 read as s16 BE, +4 as a byte, +5 sign-extended." %
                        (TWIN, M_RANGES + addr[lab] - S_RANGES))
            else:
                us = users_d[lab]
                k = (addr[lab] - S_DEFAULTS) // 23
                txt = ("%sDefaults_PtrTable (effect%s %s): 23-byte defaults record #%d: byte 0 = effect "
                       "number, packed parameter values from byte 1, final byte 99." %
                       (PREFIX, "s" if len(us) > 1 else "", ranges(us), k))
                twin = ("%sat 0x%06X (same 23 bytes + one 0xFF pad; 24-byte stride there): DSPCfg_WriteAllSlots_Direct "
                        "(0xFDCB40) walks parameters 0..count-1 of it through DSPCfg_ReadViaTableLookup (0xFDC364)." %
                        (TWIN, M_DEFAULTS + 24 * k))
            new = [txt, twin]
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
