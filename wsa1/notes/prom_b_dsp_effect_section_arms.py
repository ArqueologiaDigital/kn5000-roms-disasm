#!/usr/bin/env python3
"""Name the DSP EFFECT screen's per-section switches and their arms by the sections each arm serves.

QUESTION IT ANSWERS
  Every key handler of the DSP EFFECT screen (ScreenEnterBody_DspEffect, ExitKey_DspEffect,
  SoftKeyCol1..8_DspEffect, LcdKeyRow1..5_DspEffect) starts
      ld BC,(DspEffect_Section) / cp BC,5 / jr UGT <out> / sll 2,BC / add XBC,<table> / ld XBC,(XBC) / jp (XBC)
  DspEffect_Section (RAM 0x2790) is the screen's selected section, 0..5.  What each value is, and the
  evidence, is notes/FINDINGS-prom_b-dsp-effect-parameters.md section 7: 0 = no block opened,
  1..3 = the parameters of effect block 0..2 (a cursor: DspEffect_MoveCursor / DspEffect_StepCursorValue),
  4 / 5 = the EQ bands of block 0 / block 2 (DspEffect_StepEqBandFc on bytes 17..20).
  So a table is <handler>_BySection, and an arm is named by the set of sections it serves:
      {0} Section0     {1,2,3} ParamSections     {4,5} EqSections     {k} Section<k>     else Sections<k...>
  An arm whose code is only the handler's epilogue (pops, `unlk`, `ret`) does nothing for its sections and is
  <handler>_Exit.  A sub_ arm is renamed; an arm that already has a name keeps it.
  REFUSED: a table whose reader is not a named handler, an arm that sits in two tables, a name already taken.

RUN
  python3 notes/prom_b_dsp_effect_section_arms.py          # the plan, with each table's section -> arm map
  python3 notes/prom_b_dsp_effect_section_arms.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
L = B.split("\n")
G = re.compile(r'^([A-Za-z_][\w$]*):')
IDX = {G.match(l).group(1): i for i, l in enumerate(L) if G.match(l)}
LOCAL = re.compile(r'_(Skip|Join|Loop|Resume|Nop\d*|Return|Epilogue)\d*$')
SECTION = re.compile(r'\((?:DspEffect_Section|10128|0x2790)(?::16)?\)')
SETNAME = {(0,): "Section0", (1, 2, 3): "ParamSections", (4, 5): "EqSections"}


def code(i):
    return re.sub(r'\s+', ' ', L[i].split(";")[0]).strip()


def reader_of(i):
    while i >= 0:
        m = G.match(L[i])
        if m and not LOCAL.search(m.group(1)):
            return m.group(1)
        i -= 1
    return None


def tables():
    out = []
    for i, l in enumerate(L):
        m = re.match(r'^\s*add\s+xbc, (\w+)\s*;', l)
        if not m or m.group(1) not in IDX:
            continue
        if not any(re.match(r'^ld bc, ', code(k)) and SECTION.search(L[k]) for k in range(i - 6, i)):
            continue
        ents = []
        for ll in L[IDX[m.group(1)] + 1:IDX[m.group(1)] + 12]:
            mm = re.match(r'^\s*\.long\s+(\w+)', ll)
            if mm:
                ents.append(mm.group(1))
            elif ll.strip() and not ll.startswith(";"):
                break
        out.append((reader_of(i), m.group(1), ents))
    return out


def is_exit(label):
    i = IDX[label] + 1
    while i < len(L):
        c = code(i)
        i += 1
        if not c:
            continue
        if re.match(r'^(pop|popw) \w+$', c) or c == "unlk XIZ":
            continue
        return c == "ret"
    return False


def plan():
    rows, refused, maps = [], [], []
    tabs = tables()
    where = collections.defaultdict(set)
    for _r, t, ents in tabs:
        for e in ents:
            where[e].add(t)
    for reader, tab, ents in tabs:
        if not reader or not re.match(r'^(ScreenEnterBody|ExitKey|SoftKeyCol\d|LcdKeyRow\d)_DspEffect$', reader):
            refused.append((tab, "reader %s is not a named DSP EFFECT handler" % reader))
            continue
        if tab.startswith("DispatchTable_"):
            rows.append((tab, reader + "_BySection", "%s_BySection: %s's switch on DspEffect_Section (0..5), one arm per section\\n"
                         "  (notes/prom_b_dsp_effect_section_arms.py)." % (reader, reader)))
        sets = collections.OrderedDict()
        for k, e in enumerate(ents):
            sets.setdefault(e, []).append(k)
        tm = []
        for e, ks in sets.items():
            new = "%s_%s" % (reader, "Exit" if is_exit(e) else SETNAME.get(tuple(ks), ("Section%d" % ks[0]) if len(ks) == 1 else "Sections" + "".join(map(str, ks))))
            tm.append("%s: %s" % (",".join(map(str, ks)), e if not e.startswith("sub_") else new.split("_")[-1]))
            if not re.match(r'^sub_F[0-9A-F]{5}$', e):
                continue
            if len(where[e]) > 1:
                refused.append((e, "in %d tables" % len(where[e])))
                continue
            what = "the handler's epilogue: section(s) %s do nothing on this key" % ",".join(map(str, ks)) if new.endswith("_Exit") \
                else "what it does when DspEffect_Section is %s" % " or ".join(map(str, ks))
            rows.append((e, new, "%s: an arm of %s_BySection -- %s\\n"
                         "  (notes/prom_b_dsp_effect_section_arms.py)." % (new, reader, what)))
        maps.append((reader, tab, tm))
    return rows, refused, maps


def main():
    rows, refused, maps = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    news = [n for _o, n, _h in rows]
    for o, n, h in rows:
        bad = news.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-22s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for r, t, tm in maps:
            print("%s via %s:  %s" % (r, t, "; ".join(tm)))
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if not (news.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
