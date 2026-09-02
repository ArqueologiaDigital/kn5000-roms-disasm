#!/usr/bin/env python3
r"""arm_block_evidence.py -- the two numbers the v142 conversions rest on.

QUESTION ANSWERED: the byte gate proves the converted arm blocks reproduce the
ROM, and proves exactly nothing about whether the linear instruction framing is
RIGHT -- a wrong interpretation re-assembles to the same bytes. Two claims were
made instead, and this script is the thing that produced their numbers.

  CLAIM 1  Every interior arm label and comment inside the converted blocks
           lands on an instruction boundary of the independent unidasm decode.
           A computed-jump arm entered mid-instruction would mean the framing
           is wrong at that point, and the labels were placed by hand long
           before this lane, so they are independent evidence.

  CLAIM 2  That check DISCRIMINATES. Run over the `.byte` runs of
           subcpu_data_tables.s -- known DATA, with interior labels of their
           own -- it fails on some of them. A check that passes on everything
           is not evidence.

  CLAIM 3  Branch-target coherence inside each block: every in-block branch
           target of the same decode lands on a boundary of it, well above the
           boundary density. Small target counts, reported RAW as counts and
           not only as a ratio.

⚠ Runs AFTER the conversion, from the ROM and the current source, so it stays
runnable. Addresses come from the verified probe map, decode from unidasm
(MAME's TLCS-900 core), never from a backend refusal.

RUN (from the lane worktree root):
    python3 v142/subcpu/tools/arm_block_evidence.py
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import tier2_byte_split_census as C          # noqa: E402

TAG = "v142"
BASE = 0x400
UNI = re.compile(r'^\s*([0-9a-fA-F]{4,8}):\s+((?:[0-9a-fA-F]{2} )+)\s*(\S+)\s*(.*)$')
FLOW = {"jr", "jrl", "jp", "call", "calr", "djnz"}
TGT = re.compile(r'0x([0-9a-fA-F]+)')

BLOCKS = [
    ("DSP_AlgoType_Dispatch2_TableData", 331),
    ("Algo_SubTable_JumpTable1",         135),
    ("Algo_SubTable_JumpTable2",          89),
    ("Algo_SubTable_JumpTable3",         111),
]


def decode(start, end):
    raw = C.rom_bytes(TAG)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(raw[start - BASE:end - BASE])
        t = f.name
    try:
        out = subprocess.run([C.UNIDASM, t, "-arch", "tlcs900", "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(t)
    ins = []
    for ln in out.splitlines():
        m = UNI.match(ln.rstrip())
        if m:
            ins.append((int(m.group(1), 16), len(m.group(2).split()),
                        m.group(3), m.group(4) or ""))
    return ins


def coherence(ins, lo, hi):
    if not ins:
        return None, 0, 0
    starts = {a for a, _, _, _ in ins}
    nb = sum(n for _, n, _, _ in ins)
    density = len(ins) / nb
    t = h = 0
    for a, n, mn, op in ins:
        if mn.split(".")[0] not in FLOW:
            continue
        m = TGT.search(op)
        if not m:
            continue
        v = int(m.group(1), 16)
        if not (lo <= v < hi) or v == a or v == a + n:
            continue
        t += 1
        h += v in starts
    return ((h / t) / density if t else None), t, h


def main():
    amap = C.build_addrmap(TAG)
    rel = "kn5000_subprogram_v142.s"
    lines = open(os.path.join(ROOT, "v142/subcpu", rel),
                 encoding="latin-1").read().split("\n")
    ad = amap[rel]
    labels = {}
    for i, txt in enumerate(lines, 1):
        m = C.LABEL_DEF.match(txt)
        if m and i < len(ad) and ad[i] is not None:
            labels.setdefault(m.group(1), (i, ad[i]))

    print("CLAIM 1+3 -- the four converted arm blocks")
    tot_marks = tot_ok = tot_t = tot_h = 0
    for name, size in BLOCKS:
        if name not in labels:
            print("   %-34s NOT FOUND in source" % name)
            continue
        li, st = labels[name]
        en = st + size
        ins = decode(st, en)
        bounds = {a for a, _, _, _ in ins} | {en}
        inner = [(ad[j], lines[j - 1].strip())
                 for j in range(li + 1, len(ad) - 1)
                 if ad[j] is not None and st < ad[j] < en
                 and (C.LABEL_DEF.match(lines[j - 1]) or
                      lines[j - 1].strip().startswith(";"))]
        seen, uniq = set(), []
        for a, t in inner:
            if a not in seen:
                seen.add(a)
                uniq.append((a, t))
        ok = sum(1 for a, _t in uniq if a in bounds)
        r, nt, nh = coherence(ins, st, en)
        tot_marks += len(uniq)
        tot_ok += ok
        tot_t += nt
        tot_h += nh
        print("   %-34s 0x%06X %4d B  %3d instr  interior marks %2d/%2d on a "
              "boundary  flow targets %d/%d on a boundary%s"
              % (name, st, size, len(ins), ok, len(uniq), nh, nt,
                 ("  ratio %.2f" % r) if r else ""))
    print("   TOTAL interior marks on a boundary: %d/%d" % (tot_ok, tot_marks))
    print("   TOTAL informative flow targets on a boundary: %d/%d "
          "(raw counts: small populations)" % (tot_h, tot_t))

    print()
    print("CLAIM 2 -- the SAME check over KNOWN DATA (subcpu_data_tables.s "
          ".byte runs)")
    runs, amap2, srcmap = C.collect(TAG)
    drel = "subcpu_data_tables.s"
    dl = open(os.path.join(ROOT, "v142/subcpu", drel),
              encoding="latin-1").read().split("\n")
    dad = amap2[drel]
    checked = allok = someoff = undec = 0
    for r in runs:
        if r[0] != drel:
            continue
        _rel, l0, l1, st, sz, _t = r
        marks = [dad[j] for j in range(l0, l1 + 1)
                 if dad[j] is not None and dad[j] > st
                 and (C.LABEL_DEF.match(dl[j - 1]) or dl[j - 1].strip().startswith(";"))]
        marks = sorted(set(m for m in marks if m < st + sz))
        if len(marks) < 2:
            continue
        checked += 1
        ins = decode(st, st + sz)
        if not ins or sum(n for _a, n, _m, _o in ins) != sz:
            undec += 1
            continue
        bounds = {a for a, _, _, _ in ins} | {st + sz}
        if all(m in bounds for m in marks):
            allok += 1
        else:
            someoff += 1
    print("   %d known-data runs with >= 2 interior marks; %d do not decode "
          "end to end at all" % (checked, undec))
    print("   of the %d that do: %d have every mark on a boundary, %d have at "
          "least one OFF a boundary" % (checked - undec, allok, someoff))
    print("   -> the check can fail, so passing it is evidence."
          if someoff else
          "   -> ⚠ the check never failed here; treat CLAIM 1 as weaker.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
