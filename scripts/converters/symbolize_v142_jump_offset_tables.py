#!/usr/bin/env python3
r"""symbolize_v142_jump_offset_tables.py -- write the sub-CPU's computed-goto offset tables as
`.short Case - Base`, with a label at every case target.

QUESTION THIS ANSWERS
    subcpu_data_tables.s holds ~20 tables whose headers read "N u16 jump offsets, base 0xBASE"
    (each consumed by `lda xix,(TABLE:24) / ldw_sri / lda xix,(BASE:24) / jp_ind`), but their
    entries are bare numbers (`.short 0x0003, 0x001e, ...`), so no case target is named and the
    byte gate cannot tie an entry to the code it jumps to.  Which label does every entry reach?

WHAT --apply DOES (per table whose rows are all numeric `.short`)
    * target_k = BASE + entry_k.  Every target must be the first byte of a source line in
      kn5000_subprogram_v142.s (address map: scripts/analysis/v142_line_map.py, byte-identity
      guarded); otherwise the table is SKIPPED and reported.
    * the base gets a label if it has none: `<Routine>_CaseBase`, <Routine> = the nearest real
      label above it with a structural suffix removed;
    * a target with a label keeps it; one without gets `<Routine>_Case<k>` (k = the first index
      that reaches it; later indices reuse the label);
    * the rows become one `.short Target - Base\t; index k` line each (the header is kept).
    Then run scripts/converters/symbolize_v142_abs24_operands.py so the `lda xix,(BASE:24)`
    operands pick up the new base labels, and `make gate`.

RUN
    python3 scripts/converters/symbolize_v142_jump_offset_tables.py            # dry: per table
    python3 scripts/converters/symbolize_v142_jump_offset_tables.py --apply
"""
import argparse
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import v142_line_map as lm  # noqa: E402

TREE = os.path.join(ROOT, "v142/subcpu")
CODE, DATA = "kn5000_subprogram_v142.s", "subcpu_data_tables.s"
HDR = re.compile(r"^; --- 0x([0-9A-Fa-f]+)-0x([0-9A-Fa-f]+)\s+(\w+) -- (\d+) (?:x )?u16 jump offsets, base 0x([0-9A-Fa-f]+)")
LAB = re.compile(r"^([A-Za-z_][\w]*):")
SUFFIX = re.compile(r"_(Skip|Join|Loop|Return|Epilogue|Entry|Sub|Case\d+|CaseBase)\d*$")
rom = open(os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom"), "rb").read()


def R(a, n):
    return rom[a - 0xEF00:a - 0xEF00 + n]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    amap = lm.line_map()
    code_at, data_at = {}, {}
    for (f, i), ad in amap.items():
        (code_at if f == CODE else data_at if f == DATA else {}).setdefault(ad, i)
    C = open(os.path.join(TREE, CODE), "rb").read().decode("latin-1").split("\n")
    D = open(os.path.join(TREE, DATA), "rb").read().decode("latin-1").split("\n")
    # labels of the code file by address
    lab_at, taken = {}, set()
    for i, ln in enumerate(C):
        m = LAB.match(ln)
        if m:
            taken.add(m.group(1))
            k = i
            while k < len(C) and (CODE, k) not in amap:
                k += 1
            if (CODE, k) in amap:
                lab_at.setdefault(amap[(CODE, k)], m.group(1))
    for ln in D:
        m = LAB.match(ln)
        if m:
            taken.add(m.group(1))

    def routine_above(li):
        k = li
        while k >= 0:
            m = LAB.match(C[k])
            if m and not m.group(1).startswith(("__", ".L", "LABEL_")):
                return SUFFIX.sub("", m.group(1))
            k -= 1
        return "Code"

    def fresh(base):
        n, name = 1, base
        while name in taken:
            n += 1
            name = "%s%d" % (base, n)
        taken.add(name)
        return name

    inserts = {}          # code line index -> label
    data_edits = []       # (first row index, last row index + 1, new lines)
    for hi, ln in enumerate(D):
        m = HDR.match(ln)
        if not m:
            continue
        lo, end, name, n, base = int(m.group(1), 16), int(m.group(2), 16), m.group(3), int(m.group(4)), int(m.group(5), 16)
        li = D.index(name + ":", hi)
        rows, j = [], li + 1
        while j < len(D) and re.match(r"^\s*\.short\s", D[j]):
            rows.append(j)
            j += 1
        vals = []
        numeric = True
        for r in rows:
            body = D[r].split(";")[0].split(".short", 1)[1]
            for x in body.split(","):
                x = x.strip()
                if not re.match(r"^(0x[0-9a-fA-F]+|\d+)$", x):
                    numeric = False
                else:
                    vals.append(int(x, 0))
        if not numeric or not rows:
            print("  skip %-40s (entries not all numeric)" % name)
            continue
        assert len(vals) == n and struct.unpack("<%dH" % n, R(lo, 2 * n)) == tuple(vals), name
        bad = [k for k, v in enumerate(vals) if (base + v) not in code_at]
        if base not in code_at or bad:
            print("  SKIP %-40s base 0x%06X targets not on a line start: %s" % (name, base, bad[:6]))
            continue
        bli = code_at[base]
        blab = lab_at.get(base)
        if not blab:
            blab = fresh(routine_above(bli) + "_CaseBase")
            inserts[bli] = blab
            lab_at[base] = blab
        parent = SUFFIX.sub("", blab) if not blab.endswith("_CaseBase") else blab[:-len("_CaseBase")]
        first = {}
        out = []
        for k, v in enumerate(vals):
            t = base + v
            if t in first:
                tl = first[t]
            elif t in lab_at:
                tl = lab_at[t]
            else:
                tl = fresh("%s_Case%d" % (parent, k))
                inserts[code_at[t]] = tl
                lab_at[t] = tl
            first.setdefault(t, tl)
            out.append("\t.short %s - %s\t; index %d" % (tl, blab, k))
        data_edits.append((rows[0], rows[-1] + 1, out))
        print("  ok   %-40s %2d entries, base %s" % (name, n, blab))
    print("tables converted: %d; code labels to insert: %d" % (len(data_edits), len(inserts)))
    if not a.apply:
        return
    for s, e, out in sorted(data_edits, reverse=True):
        D[s:e] = out
    for li in sorted(inserts, reverse=True):
        C.insert(li, inserts[li] + ":")
    open(os.path.join(TREE, DATA), "wb").write("\n".join(D).encode("latin-1"))
    open(os.path.join(TREE, CODE), "wb").write("\n".join(C).encode("latin-1"))
    print("written; now symbolize_v142_abs24_operands.py --apply and make gate")


if __name__ == "__main__":
    main()
