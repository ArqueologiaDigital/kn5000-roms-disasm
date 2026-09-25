#!/usr/bin/env python3
r"""Give every element of prom_c's three literal pools a label named by its content.

QUESTION THIS ANSWERS
    Code in prom_c loads constants out of three pools by ADDRESS: a double is
    two `ld Xrr,(addr)` of its halves (low at X, high at X+4), a descriptor
    string is a pointer in a PoolDir record.  With only the pool's head
    labelled, the symbolic form of such an operand is `Pool+440`, which says
    nothing.  With one label per element, named by what the element IS -- its
    own value or text, read from the bytes, nothing inferred -- the operand
    becomes `F64_44100` / `F64_44100+4` / `DescStr_bbbvb`.

      fp_constant_pool_FCC81A  prom_c/data_tables/touch_eq_mixer.s   76 f64 + 2 x 32-bit
      Float64_ConstantPool     prom_c/mathlib/mathlib.s              77 f64
      DescriptorStrings        prom_c/data_tables/touch_eq_mixer.s   44 strings

    The first element of each keeps the pool's own label (one name per
    address).  Every value in a name is RE-DECODED from the ROM bytes at that
    address and must equal the value the line's comment prints; a disagreement
    aborts.  Repeated values get a numeric suffix in address order.

RUN
    python3 notes/lanes/promcd-2026-09-25/label_constant_pools.py [--apply]
"""
import collections
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
TEM = os.path.join(W, "prom_c", "data_tables", "touch_eq_mixer.s")
MATH = os.path.join(W, "prom_c", "mathlib", "mathlib.s")


def rom(a, n):
    return C[a - 0xF80000:a - 0xF80000 + n]


def vname(s):
    s = s.strip()
    s = s.replace("e-", "em").replace("e+", "e").replace("-", "neg").replace(".", "p").replace("+", "")
    assert re.match(r"^[0-9A-Za-z]+$", s), s
    return s


def close(a, b):
    return a == b or abs(a - b) <= 1e-9 * max(abs(a), abs(b))


def plan():
    out = {}          # path -> {line_index: label}
    names = collections.Counter()

    def take(base):
        names[base] += 1
        return base if names[base] == 1 else "%s_%d" % (base, names[base])

    # --- fp_constant_pool_FCC81A and DescriptorStrings (touch_eq_mixer.s)
    L = open(TEM, encoding="latin-1").read().split("\n")
    i = L.index("fp_constant_pool_FCC81A:")
    first = True
    tem = {}
    for j in range(i + 1, len(L)):
        ln = L[j]
        if not ln.strip().startswith(".long"):
            break
        m = re.search(r";\s*0x([0-9A-F]{6})\s+(.*)$", ln)
        a, what = int(m.group(1), 16), m.group(2).strip()
        if what.startswith("f64 "):
            v = struct.unpack("<d", rom(a, 8))[0]
            assert close(v, float(what[4:])), (hex(a), v, what)
            nm = "F64_" + vname(what[4:])
        elif what.startswith("32-bit element: f32 "):
            v = struct.unpack("<f", rom(a, 4))[0]
            assert close(v, float(what[20:])) or abs(v - float(what[20:])) < 1e-7, (hex(a), v, what)
            nm = "F32_" + vname(what[20:])
        else:
            assert first, what
            nm = None
        if first:
            first = False
            continue
        tem[j] = take(nm)
    i = L.index("DescriptorStrings:")
    first = True
    for j in range(i + 1, len(L)):
        ln = L[j]
        if not ln.strip().startswith(".asciz"):
            break
        m = re.match(r'\s*\.asciz\s+"([^"]*)"\s*;\s*\[\s*\d+\]\s*0x([0-9A-F]{6})', ln)
        s, a = m.group(1), int(m.group(2), 16)
        assert rom(a, len(s) + 1) == s.encode() + b"\0", (hex(a), s)
        if first:
            first = False
            continue
        tem[j] = take("DescStr_" + s)
    out[TEM] = tem
    # --- Float64_ConstantPool (mathlib.s)
    L = open(MATH, encoding="latin-1").read().split("\n")
    i = L.index("Float64_ConstantPool:")
    first = True
    mth = {}
    for j in range(i + 1, len(L)):
        ln = L[j]
        if ln.strip().startswith(";"):
            continue
        if not ln.strip().startswith(".byte"):
            break
        m = re.search(r";\s*\[\s*\d+\]\s*0x([0-9A-F]{6})\s*=\s*(\S+)", ln)
        a, val = int(m.group(1), 16), m.group(2)
        v = struct.unpack("<d", rom(a, 8))[0]
        assert close(v, float(val)), (hex(a), v, val)
        if first:
            first = False
            continue
        mth[j] = take("F64_" + vname(val))
    out[MATH] = mth
    return out


def apply(out):
    for path, labs in out.items():
        raw = open(path, "rb").read().decode("latin-1").split("\n")
        assert not any(l in raw for l in ("%s:" % n for n in labs.values())), "already applied"
        res = []
        for j, ln in enumerate(raw):
            if j in labs:
                res.append("%s:" % labs[j])
            res.append(ln)
        open(path, "wb").write("\n".join(res).encode("latin-1"))
    print("applied: %d labels" % sum(len(v) for v in out.values()))


if __name__ == "__main__":
    out = plan()
    for p, labs in out.items():
        print("  %-48s %3d labels, e.g. %s" % (os.path.relpath(p, ROOT), len(labs),
                                             ", ".join(list(labs.values())[:4])))
    print("ALL VALUES RE-DECODED FROM THE ROM AND MATCH")
    if "--apply" in sys.argv:
        apply(out)
