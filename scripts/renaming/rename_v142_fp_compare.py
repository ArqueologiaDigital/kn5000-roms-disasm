#!/usr/bin/env python3
r"""rename_v142_fp_compare.py -- the sub-CPU FP library's compare predicates and their result tables.

QUESTION THIS ANSWERS / WHAT IT DOES
    ToneGen_Compare_Voice (0x03D2AC) and ToneGen_Compare_Voice_32 (0x03D306) are, by their own
    newer headers, "Nothing to do with voices: this is the FLOAT-COMPARE PREDICATE of the FP
    library" (11 of 12 callers in subcpu_fp_math.s) and its single-precision form.  Their three
    6-byte result rows at 0x03D978 / 0x03D97E / 0x03D984 sat under one label,
    ToneGen_Compare_Tables, which actually labels the 0xFF alignment byte at 0x03D977, so
    every reader wrote `lda xix, (0x03d978:24)`.  This script:
      * renames the two predicates and their arms into the library's libm-style names
        (FP_dcmp / FP_fcmp, like FP_ddiv, FP_dmul, FP_dtof already in the tree);
      * relabels 0x03D977 as a pad byte and gives the three rows their own labels
        (FP_CmpResult_Equal / _Less / _Greater), then rewrites the 14 numeric readers;
      * leaves the old banner lines that record the old reading as they are (HISTORICAL) and
        adds one line saying what was renamed.
    The byte gate certifies every rewritten operand.

RUN
    python3 scripts/renaming/rename_v142_fp_compare.py            # dry
    python3 scripts/renaming/rename_v142_fp_compare.py --apply    # then make gate
    python3 scripts/renaming/rename_v142_fp_compare.py --map      # old=new for the comment gate
"""
import argparse
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["v142/subcpu/kn5000_subprogram_v142.s", "v142/subcpu/subcpu_fp_math.s",
         "v142/subcpu/subcpu_data_tables.s"]
RENAMES = {
    "ToneGen_Compare_Voice_32": "FP_fcmp",
    "ToneGen_Compare_Voice": "FP_dcmp",
    "ToneGen_Compare_Diff": "FP_dcmp_HighDiffer",
    "ToneGen_Compare_Result": "FP_dcmp_NotEqual",
    "ToneGen_Compare_Sign": "FP_dcmp_Sign",
    "ToneGen_Cmp_Less": "FP_dcmp_Less",
    "ToneGen_Cmp_Greater": "FP_dcmp_Greater",
    "ToneGen_Cmp32_NotEqual": "FP_fcmp_NotEqual",
    "ToneGen_Cmp32_Sign": "FP_fcmp_Sign",
    "ToneGen_Cmp32_Greater": "FP_fcmp_Greater",
    "ToneGen_Compare_Tables": "FP_CmpResult_Pad",
    "ToneGen_Voice_Padding": "FP_dcmp_AlignPad",
}
HISTORICAL = [
    "; ToneGen_Compare_Voice - Compare two voice parameter blocks",
    "; ToneGen_Compare_Voice_32 - Compare two 32-bit voice parameters",
    "; ToneGen_Compare_Tables - Lookup tables for voice comparison results",
]
OPERANDS = {"(0x03d978:24)": "(FP_CmpResult_Equal:24)", "(0x03d97e:24)": "(FP_CmpResult_Less:24)",
            "(0x03d984:24)": "(FP_CmpResult_Greater:24)"}
PAT = re.compile(r"\b(" + "|".join(sorted(RENAMES, key=len, reverse=True)) + r")\b")
STAR = "★".encode("utf-8").decode("latin-1")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--map", action="store_true")
    a = ap.parse_args()
    if a.map:
        for o, n in RENAMES.items():
            print("%s=%s" % (o, n))
        return
    for f in FILES:
        p = os.path.join(ROOT, f)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        out, n = [], 0
        for ln in L:
            code, sep, com = ln.partition(";")
            if any(h in ln for h in HISTORICAL):
                out.append(ln)
                continue
            m = re.match(r"^(\w+):", code)
            if m and m.group(1) in RENAMES:
                out.append("; %s Renamed 2026-09-25 from %s (FP library compare; see the headers)." % (STAR, m.group(1)))
            c2 = PAT.sub(lambda mm: RENAMES[mm.group(1)], code)
            for o, nn in OPERANDS.items():
                c2 = c2.replace(o, nn)
            n += c2 != code
            out.append(c2 + sep + (PAT.sub(lambda mm: RENAMES[mm.group(1)], com) if sep else ""))
        txt = "\n".join(out)
        if f.endswith("subcpu_fp_math.s"):
            old = ("FP_CmpResult_Pad:\t; 03D977h\n\t.byte 0xff\t; Padding\n\t; Equal table (0x03D978)\n"
                   "\t.byte 0x01, 0x00, 0x01, 0x00, 0x01, 0x00\n\t; Less-than table (0x03D97E)\n"
                   "\t.byte 0x01, 0x01, 0x00, 0x00, 0x00, 0x01\n\t; Greater-than table (0x03D984)\n"
                   "\t.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x01\n")
            new = ("FP_CmpResult_Pad:\t; 03D977h\n\t.byte 0xff\t; Padding\n"
                   "; The three rows are indexed by the comparison-kind code 0..5 (DE in FP_dcmp / FP_fcmp,\n"
                   "; BC in FP_DP_CmpZero64 / FP_SP_CmpZero32), `ldb_sri` / `xor_srib_rm` = row[kind].\n"
                   "\t; Equal table (0x03D978)\n"
                   "FP_CmpResult_Equal:\n\t.byte 0x01, 0x00, 0x01, 0x00, 0x01, 0x00\n"
                   "\t; Less-than table (0x03D97E)\n"
                   "FP_CmpResult_Less:\n\t.byte 0x01, 0x01, 0x00, 0x00, 0x00, 0x01\n"
                   "\t; Greater-than table (0x03D984)\n"
                   "FP_CmpResult_Greater:\n\t.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x01\n")
            assert txt.count(old) == 1, "table block not found"
            txt = txt.replace(old, new)
        print("%s: %d code lines changed" % (f, n))
        if a.apply:
            open(p, "wb").write(txt.encode("latin-1"))


if __name__ == "__main__":
    main()
