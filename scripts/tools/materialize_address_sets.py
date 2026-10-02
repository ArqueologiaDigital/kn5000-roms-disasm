#!/usr/bin/env python3
"""materialize_address_sets.py -- `.set NAME, 0xE.....` ROM addresses become labels where the bytes are.

QUESTION THIS ANSWERS / JOB IT DOES
  Each KN5000 maincpu top-level source ends with ~600 lines under "; Labels emitted as .set
  (exact addresses from ORG/name)": `.set BmpFile_i18_bmp, 0xeb2a16` -- names the ASL-to-LLVM
  conversion could not place, kept as NUMBERS.  A number does not move with the bytes, says
  nothing about where the object is in the source, and hides that the `.incbin` it lands in
  holds more than one object (CLAUDE.md, Binary Include Splitting).  Per constant:
    * a region constant (`*_BASE_ADDR`, `*_RomEnd`, 0xE00000 / 0xFFFFFF) stays a constant;
    * a column-0 label is already at that address  -> one of the two names goes (canonical-label
      policy): the label's, when it is structural (`_Helper4`, `_Join5`, `_Target2`, ...), the
      constant's is not, and code calls the address by the constant's name (`call FDC_INIT`) or
      the documentation site (../technics-docs/*.md) documents it under that name
      (reverse-engineering.md: FDC_DRIVE_DETECT, "6-check drive detection") --
      unless the constant names data and the line is code (NakaData_WidgetInit2 on a loop label).
      An unused, undocumented constant never wins: many are the ASL era's "forward references to helper
      routines in raw byte sections" (archive/asl/maincpu/fdc_routines.asm:1113), names given
      to bytes nobody had disassembled yet, and the structural name is the honest one;
      or when both are NakaWidget_* and every caption word of the record supports the
      constant's (scripts/tools/label_naka_records.py's test: NakaWidget_Perf2Flute over the
      firmware's "DemoSong8"); otherwise the constant's -- its uses take the label;
    * nothing uses it (code, data, C, link scripts) and the address is not a clean place for a
      label (inside an instruction, mid-element) -> deleted, reported;
    * otherwise the label is placed there (scripts/tools/place_labels.py: in front of the line,
      or by cutting the `.incbin` slice / list) and the `.set` line goes;
    * a used constant the placer cannot take (inside a string, an instruction) is written
      relative to the label of its line, `.set NakaStr_DataFile1of2, FILETYPE_SIG_TABLE_1 + 19`,
      or keeps its number when the line has no label (reported).
  Names are kept as they are: renaming is a separate, reviewed step.  Labels and symbol
  spellings emit no byte: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/materialize_address_sets.py --tree v10 [--apply] [--report OUT.json]
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels                           # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import nakarest_objtab_map as nom             # noqa: E402

DATAISH = re.compile(r'(^Naka(Data|Str|Desc|Inst)|Str|Data|Table|Bitmap|Bmp|Ptr)')
REGION = re.compile(r'(BASE|_ADDR$|_START$|_END$|RomEnd)')
STRUCTISH = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Entry|Tail|Next|Done|Exit|End|Code|'
                       r'Data|Block|Sub|Case|Default|Target)\d*$|_0x[0-9A-Fa-f]+$|^LABEL_|^sub_|^loc_')
ABSSET = re.compile(r'^\s*\.(?:set|equ)\s+([A-Za-z_]\w*)\s*,\s*(0x[0-9a-fA-F]+)\s*(?:;.*)?$')
COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    elf, tree, (lo, hi) = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)
    base = os.path.join(REPO, a.tree, "maincpu")
    srcs = sorted(glob.glob(os.path.join(base, "**", "*.s"), recursive=True))
    others = sorted(sum((glob.glob(os.path.join(base, "**", g), recursive=True) for g in ("*.c", "*.h", "*.ld")), []))
    text = {f: open(f, "rb").read().decode("latin-1") for f in srcs + others}
    col0 = set()
    sets = {}                                           # name -> (value, file)
    for f in srcs:
        for l in text[f].split("\n"):
            m = COL0.match(l)
            if m:
                col0.add(m.group(1))
            m = ABSSET.match(l)
            if m and lo <= int(m.group(2), 16) <= hi:
                sets[m.group(1)] = (int(m.group(2), 16), f)
    # uses: any mention outside its own .set line and outside comments (.s); any mention (.c/.h/.ld)
    uses = collections.Counter()
    if sets:
        pat = re.compile(r'(?<![\w.$])(%s)(?![\w$])' % "|".join(map(re.escape, sorted(sets, key=len, reverse=True))))
        for f, t in text.items():
            for l in t.split("\n"):
                if ABSSET.match(l):
                    continue
                code = l.split(";", 1)[0] if f.endswith(".s") else l
                for m in pat.finditer(code):
                    uses[m.group(1)] += 1
    planner = place_labels.Planner(a.tree)
    m = nom.Map(a.tree)
    documented = set()                                  # identifiers the documentation site quotes
    for p in glob.glob(os.path.join(REPO, "..", "technics-docs", "*.md")):
        documented |= set(re.findall(r'[A-Za-z_]\w+', open(p, encoding="latin-1").read()))
    stats, rows, retire, delete, relabel, rebase = collections.Counter(), [], {}, set(), {}, {}
    for n, (v, f) in sorted(sets.items(), key=lambda kv: kv[1][0]):
        if REGION.search(n) or v in (0xE00000, 0xFFFFFF):
            stats["region constant: kept"] += 1
            rows.append(dict(name=n, value=hex(v), result="kept (region constant)"))
            continue
        here = [x for x in syms.get(v, []) if x in col0]
        if here:
            lab = fp.pick(here, col0)
            caps = set()
            c = m.record_class(v) if lab.startswith("NakaWidget_") and n.startswith("NakaWidget_") else None
            if c:
                for off, fname, ch in m.class_fields(c):
                    if ch == "X" and m.inrom(m.u32(v + off)):
                        caps |= set(w.lower() for w in re.findall(r'[A-Za-z]{3,}', m.string_at(m.u32(v + off))))
            w = planner.where(v)
            is_code = bool(w) and place_labels.snb.drc.classify_line(planner.lines(w[1])[w[2]], planner.macros)[0] == "code"
            if (STRUCTISH.search(lab) and not STRUCTISH.search(n) and (uses[n] or n in documented)
                    and not (is_code and DATAISH.search(n))
                    and not lab.startswith("NakaWidget_")) or (caps and all(x[:3] in n.lower() for x in caps)):
                relabel[lab] = n
                delete.add(n)
                stats["the label there takes the constant's name"] += 1
                rows.append(dict(name=n, value=hex(v), result="label renamed", label=lab))
            else:
                retire[n] = lab
                stats["retired into the label there"] += 1
                rows.append(dict(name=n, value=hex(v), result="retired", into=lab))
            continue
        how = planner.add(v, n)
        if how in ("line-start", "incbin", "list"):
            delete.add(n)
            stats["label placed: " + how] += 1
            rows.append(dict(name=n, value=hex(v), result="placed", how=how))
        elif how == "duplicate":
            other = planner.names[v]
            retire[n] = other
            stats["same address as another constant"] += 1
            rows.append(dict(name=n, value=hex(v), result="retired", into=other))
        elif not uses[n]:
            delete.add(n)
            stats["unused, not placeable: deleted"] += 1
            rows.append(dict(name=n, value=hex(v), result="deleted (unused, %s)" % how))
        else:
            w = planner.where(v)
            at0 = [x for x in syms.get(w[0], []) if x in col0] if w else []
            if at0:
                rebase[n] = "%s + %d" % (fp.pick(at0, col0), v - w[0])
                stats["used, inside a line: rewritten label + offset"] += 1
                rows.append(dict(name=n, value=hex(v), result="rebased", expr=rebase[n]))
            else:
                stats["used, not placeable: kept"] += 1
                rows.append(dict(name=n, value=hex(v), result="kept (%s)" % how, uses=uses[n]))
    print("%s: %d absolute ROM-address constants; %s%s" % (a.tree, len(sets), dict(stats), "" if a.apply else " (dry run)"))
    if a.apply:
        planner.apply()
        gone = delete | set(retire)
        retire.update(relabel)
        rp = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True)))) if retire else None
        rpc = re.compile(r'(?<![\w$])(%s)(?![\w$])' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True)))) if retire else None
        if relabel:
            with open(os.path.join(REPO, "scripts", "renaming", "rename_address_set_labels_%s.sed" % a.tree), "w") as s:
                s.write("# generated by scripts/tools/materialize_address_sets.py: structural labels that take the\n"
                        "# name of the absolute .set constant code used for the same address.\n")
                for old, new in sorted(relabel.items(), key=lambda kv: -len(kv[0])):
                    s.write("s/\\b%s\\b/%s/g\n" % (old, new))
        for f in srcs + others:
            t = open(f, "rb").read().decode("latin-1")
            L = [l for l in t.split("\n") if not (ABSSET.match(l) and ABSSET.match(l).group(1) in gone)]
            L = [re.sub(r',\s*0x[0-9a-fA-F]+', ", " + rebase[ABSSET.match(l).group(1)], l, count=1)
                 if ABSSET.match(l) and ABSSET.match(l).group(1) in rebase else l for l in L]
            t2 = "\n".join(L)
            if rp:
                # in C a member is also spelled `.name` (designated initializer): no `.` exclusion
                t2 = (rp if f.endswith(".s") else rpc).sub(lambda q: retire[q.group(1)], t2)
            if t2 != t:
                open(f, "wb").write(t2.encode("latin-1"))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
