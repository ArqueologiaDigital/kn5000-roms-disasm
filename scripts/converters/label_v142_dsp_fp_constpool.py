#!/usr/bin/env python3
r"""label_v142_dsp_fp_constpool.py -- one label per constant of the DSP floating-point pool.

QUESTION THIS ANSWERS
    subcpu_data_tables.s 0x012CD3-0x0131CE is the floating-point constant pool of the DSP
    coefficient routines (127 x f32 + 98 x f64).  Its header said the code "cannot reference
    these symbolically" because `lda_24` takes only numeric addresses; so every reader wrote
    `lda xNN, (0x012cdb:24)`.  That is no longer true -- `lda r,(Label:24)` assembles to the
    same bytes (hundreds of such operands in this file pass the byte gate) -- so which routine
    reads which constant, and what should each constant be called?

WHAT --apply DOES
    * every reading operand `(DSP_FP_ConstPool+N:24)` / `(0x012cdb:24)` / the pool head becomes
      `(FPConst_<Reader>_<value>:24)`, where <Reader> is the routine the `lda` sits in (nearest
      real label above, structural suffix _Skip/_Join/_Loop/... removed) and <value> is the
      constant spelled compactly (44100, 0p4270422, 1p4247586em4 ...); a number is appended
      when one routine reads the same value twice;
    * each constant line gets that label and a trailing `; f32|f64 <value>, read by <Reader>
      (operand at 0x......)` (an existing comment such as `; 2^23` is kept in front);
    * the DSP_FP_ConstPool label itself is removed (the pool header stays), because the first
      constant now has its own name and an address carries one label;
    * the header's "cannot reference these symbolically" sentence is corrected (★ CORRECTED).
    Constants no operand reads (none expected -- the header says the references tile the pool)
    would keep no label and are reported.

GUARDS
    Offsets are computed from the directive sizes (.float 4, .double 8) and must add up to
    the pool span; every site's operand value must equal a constant's start; the byte gate
    then proves each symbolic operand resolves to the same address.

RUN
    python3 scripts/converters/label_v142_dsp_fp_constpool.py            # dry
    python3 scripts/converters/label_v142_dsp_fp_constpool.py --apply    # then make gate
"""
import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import v142_line_map as lm  # noqa: E402

TREE = os.path.join(ROOT, "v142/subcpu")
CODE, DATA = "kn5000_subprogram_v142.s", "subcpu_data_tables.s"
POOL, POOL_LO, POOL_HI = "DSP_FP_ConstPool", 0x012CD3, 0x0131CF
LAB = re.compile(r"^([A-Za-z_.$][\w.$]*):")
SUFFIX = re.compile(r"_(Skip|Join|Loop|Return|Epilogue|Entry|Sub|Case\d+|Arm\w*)\d*$")
OPER = re.compile(r"\((DSP_FP_ConstPool(?:\+(\d+))?|0x[0-9a-fA-F]+|\d+)(:24)\)")


def slug(txt):
    v = float(txt.replace("f", ""))
    if v == int(v) and abs(v) < 1e10:
        s = str(int(abs(v)))
    else:
        s = ("%.8g" % abs(v)).replace(".", "p").replace("e-0", "em").replace("e-", "em") \
            .replace("e+0", "e").replace("e+", "e")
    return ("Neg" if v < 0 else "") + s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    amap = lm.line_map()
    D = open(os.path.join(TREE, DATA), "rb").read().decode("latin-1").split("\n")
    C = open(os.path.join(TREE, CODE), "rb").read().decode("latin-1").split("\n")
    pi = D.index(POOL + ":")
    # constants: (line index, address, kind, value text)
    consts, ad, j = [], POOL_LO, pi + 1
    while ad < POOL_HI:
        m = re.match(r"^\s*\.(float|double)\s+([^\s;]+)", D[j])
        if not m:
            sys.exit("unexpected line in pool: %r" % D[j])
        assert amap[(DATA, j)] == ad, (hex(ad), D[j])
        consts.append((j, ad, m.group(1), m.group(2)))
        ad += 4 if m.group(1) == "float" else 8
        j += 1
    assert ad == POOL_HI, hex(ad)
    by_addr = {c[1]: c for c in consts}
    # reading sites
    sites = []
    for i, ln in enumerate(C):
        code = ln.split(";")[0]
        for m in OPER.finditer(code):
            if m.group(1).startswith(POOL):
                v = POOL_LO + int(m.group(2) or 0)
            else:
                v = int(m.group(1), 0)
            if not (POOL_LO <= v < POOL_HI):
                continue
            if v not in by_addr:
                sys.exit("site %d reads 0x%06X, not a constant start" % (i + 1, v))
            k = i
            while k >= 0:
                mm = LAB.match(C[k])
                if mm and not mm.group(1).startswith(("__", ".L")):
                    break
                k -= 1
            reader = SUFFIX.sub("", mm.group(1))
            sites.append((i, m.group(0), v, reader, amap[(CODE, i)]))
    names, used = {}, collections.Counter()
    for i, text, v, reader, sa in sites:
        if v in names:
            continue
        j, _, kind, val = by_addr[v]
        base = "FPConst_%s_%s" % (reader, slug(val))
        used[base] += 1
        names[v] = (base if used[base] == 1 else "%s_%d" % (base, used[base]), reader, sa, kind, val)
    unread = [c for c in consts if c[1] not in names]
    print("constants %d (f32 %d, f64 %d); reading sites %d; distinct constants read %d; unread %d" % (
        len(consts), sum(c[2] == "float" for c in consts), sum(c[2] == "double" for c in consts),
        len(sites), len(names), len(unread)))
    for c in unread:
        print("  UNREAD 0x%06X .%s %s" % (c[1], c[2], c[3]))
    if not a.apply:
        for v in sorted(names)[:12]:
            print("  0x%06X %s" % (v, names[v][0]))
        return
    for i, text, v, reader, sa in sites:
        C[i] = C[i].replace(text, "(%s:24)" % names[v][0], 1)
    for j, ad, kind, val in consts:
        if ad not in names:
            continue
        nm, reader, sa, _, _ = names[ad]
        code, sep, com = D[j].partition(";")
        extra = (com.strip() + "; ") if sep else ""
        D[j] = "%s:\t.%s %s\t; %s%s %s, read by %s (operand at 0x%06X)" % (
            nm, kind, val, extra, "f32" if kind == "float" else "f64", val, reader, sa)
    D[pi] = None
    txt = "\n".join(x for x in D if x is not None)
    old = "; FP_DP_* = f64); the reference stride tiles the pool with no gap.\n"
    new = old + ("; \u2605 CORRECTED 2026-09-25: the code CAN reference them symbolically -- `lda r,(Label:24)`\n"
                 "; assembles to the same bytes -- so\n"
                 "; each constant now carries its own label, FPConst_<reading routine>_<value>, and its\n"
                 "; reader reads it by name (scripts/converters/label_v142_dsp_fp_constpool.py).  The pool\n"
                 "; label DSP_FP_ConstPool is gone: an address carries one name, and the first constant has\n"
                 "; its own.  Measured by that script: 127 x f32 + 96 x f64 = 1,276 bytes tile\n"
                 "; 0x012CD3-0x0131CE exactly, read by 223 sites, one per constant (so \"98 x f64\" above is 2 high).\n")\
        .encode("utf-8").decode("latin-1")
    assert txt.count(old) == 1
    txt = txt.replace(old, new)
    open(os.path.join(TREE, DATA), "wb").write(txt.encode("latin-1"))
    open(os.path.join(TREE, CODE), "wb").write("\n".join(C).encode("latin-1"))
    print("written")


if __name__ == "__main__":
    main()
