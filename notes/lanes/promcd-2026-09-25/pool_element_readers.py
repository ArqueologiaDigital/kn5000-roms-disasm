#!/usr/bin/env python3
r"""Which prom_c instructions read each element of the three literal pools?

QUESTION THIS ANSWERS
    After label_constant_pools.py named every element of fp_constant_pool_FCC81A,
    Float64_ConstantPool and DescriptorStrings by its content, and
    scripts/converters/symbolize_rom_operands.py rewrote the operands that load
    them, each element's readers can be listed from the sources: every operand
    `<element>` or `<element>+4` (a double's high half) in prom_c, with the
    address the line itself states and the routine it sits in, and every
    `.long <element>` (the PoolDir_Records string pointers).

    With --apply it writes that list as a one-to-three-line header above each
    element, and it CORRECTS Float64_ConstantPool's per-entry annotation
    `no loading site located` wherever a loading site now exists -- those 54
    lines were false (the pool's own banner already counted 54 loaded entries;
    the per-entry lines predate the symbolic operands).  Entries with no reader
    keep the annotation, which is still true of them.

RUN
    python3 notes/lanes/promcd-2026-09-25/pool_element_readers.py [--apply]
"""
import collections
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
PC = os.path.join(W, "prom_c")
TEM = os.path.join(PC, "data_tables", "touch_eq_mixer.s")
MATH = os.path.join(PC, "mathlib", "mathlib.s")
POOLS = {"fp_constant_pool_FCC81A": TEM, "Float64_ConstantPool": MATH, "DescriptorStrings": TEM}
LABEL = re.compile(r"^([A-Za-z_.$][\w.$@]*):")


def pool_members():
    """pool -> [element labels in order] (the pool label is element 0)."""
    out = {}
    for pool, path in POOLS.items():
        L = open(path, encoding="latin-1").read().split("\n")
        i = L.index(pool + ":")
        mem = [pool]
        for ln in L[i + 1:]:
            m = LABEL.match(ln)
            if m:
                nm = m.group(1)
                if (pool == "DescriptorStrings" and nm.startswith("DescStr_")) or \
                   (pool != "DescriptorStrings" and nm.startswith(("F64_", "F32_"))):
                    mem.append(nm)
                    continue
                break
        out[pool] = mem
    return out


def readers(names):
    rx = re.compile(r"(?<![\w.$])(%s)(\+4)?(?![\w.$])" % "|".join(re.escape(n) for n in sorted(names, key=len, reverse=True)))
    got = collections.defaultdict(list)
    for dp, _, fn in os.walk(PC):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            path = os.path.join(dp, f)
            L = open(path, encoding="latin-1").read().split("\n")
            routine = None
            for ln in L:
                m = LABEL.match(ln)
                if m and "__" not in m.group(1) and not m.group(1).startswith(".L"):
                    routine = m.group(1)
                code = ln.split(";")[0]
                code = LABEL.sub("", code.strip()) if LABEL.match(code.strip()) else code
                if not code.strip() or code.strip().startswith(".") and not code.strip().startswith(".long"):
                    continue
                for hm in rx.finditer(code):
                    addr = re.search(r";\s*([0-9A-F]{6})\b", ln)
                    kind = "long" if code.strip().startswith(".long") else "insn"
                    got[hm.group(1)].append((kind, routine, addr.group(1) if addr else None,
                                             bool(hm.group(2))))
    return got


def header(name, sites):
    ins = [s for s in sites if s[0] == "insn"]
    lng = [s for s in sites if s[0] == "long"]
    parts = []
    if ins:
        by = collections.OrderedDict()
        for _, r, a, hi in ins:
            by.setdefault(r, []).append("0x" + a if a else "?")
        parts.append("Read at %d site%s: %s." % (len(ins), "" if len(ins) == 1 else "s", "; ".join(
            "%s %s" % (r, ", ".join(v[:4]) + (" +%d more" % (len(v) - 4) if len(v) > 4 else ""))
            for r, v in by.items())))
    if lng:
        rs = collections.Counter(r for _, r, _, _ in lng)
        parts.append("Pointed at by %d .long word%s in %s." % (len(lng), "" if len(lng) == 1 else "s",
                                                               ", ".join("%s (x%d)" % kv for kv in rs.items())))
    body = " ".join(parts)
    return ["; " + x for x in textwrap.wrap(body, 90, break_long_words=False, break_on_hyphens=False)]


def main():
    mem = pool_members()
    allnames = [n for v in mem.values() for n in v]
    got = readers(allnames)
    n_read = {p: sum(1 for n in v if got.get(n)) for p, v in mem.items()}
    for p, v in mem.items():
        print("  %-26s %3d elements, %3d with a reader" % (p, len(v), n_read[p]))
    if "--apply" not in sys.argv:
        return
    for path in sorted(set(POOLS.values())):
        L = open(path, "rb").read().decode("latin-1").split("\n")
        if any("Read at " in x and x.startswith("; ") and "site" in x for x in L[:0]):
            pass
        res, fixed = [], 0
        names = {n for p, v in mem.items() if POOLS[p] == path for n in v}
        for j, ln in enumerate(L):
            m = LABEL.match(ln)
            if m and m.group(1) in names and got.get(m.group(1)) and m.group(1) not in POOLS:
                res.extend(header(m.group(1), got[m.group(1)]))
            res.append(ln)
        # Float64_ConstantPool: correct the per-entry annotation where a reader exists
        if path == MATH:
            out, cur = [], None
            for ln in res:
                m = LABEL.match(ln)
                if m:
                    cur = m.group(1)
                if ln.strip() == ";      no loading site located" and cur in names and cur not in POOLS and got.get(cur):
                    ln = ";      loading site(s) located -- see the header above (corrected 2026-09-25, lane promcd)"
                    fixed += 1
                out.append(ln)
            res = out
        open(path, "wb").write("\n".join(res).encode("latin-1"))
        print("  wrote %s (%d annotations corrected)" % (os.path.relpath(path, ROOT), fixed))


if __name__ == "__main__":
    main()
