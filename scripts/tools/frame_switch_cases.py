#!/usr/bin/env python3
"""Label the case targets of compiled `switch` statements and spell their offset tables symbolically.

QUESTION IT ANSWERS / WHAT IT DOES
  The dispatch census's detector D (scripts/analysis/dispatch_table_census/census.py) finds every
  `jp t, (xR+rr)` site with its base B, offset table T and case count N, and grades each target.  Most
  targets are instruction starts with no label, and most tables are plain numbers or slices of a
  compiled-C .incbin.  For one maincpu tree this script:
    1. names the switch's owner: a table already named <Owner>_CaseTable gives <Owner>; otherwise the
       routine holding the `jp` site -- walking up, the first label that something `call`s or a `.long`
       table holds, or that follows an unconditional ret/jp/jr and is not a continuation label
       (_Skip/_Join/_Loop/_Return/_Code/...);
    2. works out each case's value: table index k plus the bias the code subtracts before the bound
       check (`sub r, X` / `dec n, r`, r the index register or its low byte).  When X is an EVT_*
       constant the case is named by its event;
    3. places `<Routine>_Case<value>` or `<Routine>_On<Event>` at every target that has no label.  A
       target shared by several cases is named by its lowest case and carries a comment listing them.
       An owner's second and later switches (in source order) are <Owner>_Switch<n>_Case<value>.
       The out-of-range target keeps its existing label;
    4. respells the table as `.short <Target> - <Base>` lines.  This happens when every source line over
       its bytes is a plain-number `.short`/`.word`/`.byte` line inside the table, or an .incbin slice;
       a slice is split around the table.  A label on the first such line is kept.
  Nothing is guessed about what a case does.  The names say only "case V of routine R's switch", and
  they are meant to be renamed as each case is understood.

RUN (repository root; the census maps must be built from this exact tree first:
     `python3 scripts/analysis/dispatch_table_census/build_maps.py`)
  python3 scripts/tools/frame_switch_cases.py v10 --dry-run      # print the plan
  python3 scripts/tools/frame_switch_cases.py v10                # write; then `make all` must stay byte-identical
"""
import collections
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
ARGS = sys.argv[1:]
sys.argv = sys.argv[:1]
import census  # noqa: E402

TREE_DIR = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu"}
SUBSIDIARY = re.compile(r'(_(Skip|Join|Loop|Return|Epilogue|Default|Done|Next|Exit|Cont|Body|Tail|End|Code|Case'
                        r'|Store|Data|Helper|Stub|Wrap|Common|Fallthrough|Then|Else)\w*$)|^\.L')
LABEL_PREFIX = re.compile(r'^([A-Za-z_.$][\w.$@]*):')


def clean(text):
    c = text.split(";", 1)[0].strip()
    return re.sub(r'\s+', ' ', re.sub(r'^[A-Za-z_.$][\w.$@]*:\s*', '', c))


ENTRY = set()


def entries(key, rows):
    """Labels something enters as a routine: a `call`/`calr` operand, or a `.long` table entry."""
    for r in rows:
        c = clean(r[6])
        mm = re.match(r'^(?:call|calr)\s+(?:[a-z]+, ?)?\(?([A-Za-z_.$][\w.$@]*)', c, re.I)
        if mm:
            ENTRY.add(mm.group(1))
        elif r[4] == "data" and r[5] == ".long":
            ENTRY.update(x for x in census.operands(r[6]) if re.match(r'^[A-Za-z_]\w*$', x))


TERMINATOR = re.compile(r'^(ret|retd|reti|jp|jr|jrl)\b(?!\s+(?:t,|z,|nz,|c,|nc,|lt,|le,|gt,|ge,|ult,|ule,|ugt,|uge,|mi,|pl,|ov,|nov,|eq,|ne,|v,|nv,|pe,|po,|f,))', re.I)


def routine_of(key, rows, i):
    """The routine holding row i: walking up, the first label that something calls or a .long table
    holds, or that follows an unconditional ret/jp/jr and is not a continuation label."""
    rel = rows[i][2]
    j = i
    while j >= 0 and rows[j][2] == rel:
        lab = rows[j][7]
        if lab:
            if lab in ENTRY:
                return lab
            k = j - 1
            while k >= 0 and rows[k][2] == rel and not census.is_insn_row(key, rows[k]):
                k -= 1
            prev = clean(rows[k][6]) if k >= 0 and rows[k][2] == rel else ""
            if TERMINATOR.match(prev) and not SUBSIDIARY.search(lab):
                return lab
        j -= 1
    return None


def bias_of(texts):
    for t in reversed(texts):
        mm = re.match(r'^sub (?:x?(?:wa|bc|de|hl|ix|iy|iz)|a|c|e|l), ?([A-Za-z_]\w*|0x[0-9a-fA-F]+|\d+)$', t, re.I)
        if mm:
            return mm.group(1)
        mm = re.match(r'^dec (\d+), ?(?:x?(?:wa|bc|de|hl|ix|iy|iz)|a|c|e|l)$', t, re.I)
        if mm:
            return mm.group(1)
    return None


def label_at(m, rows, addr, planned):
    if addr in planned:
        return planned[addr][0]
    r = census.find(m, addr)
    if r and r[0] == addr and r[7]:
        return r[7]
    names = sorted(n for (a, t, n) in m["syms"] if a == addr and t in "tT" and not n.startswith(".L"))
    return names[0] if names else None


def main():
    key = ARGS[0]
    dry = "--dry-run" in ARGS
    root = os.path.join(REPO, TREE_DIR[key])
    m = census.load(key)
    rows = m["rows"]
    D = census.detect_D(key, {t["addr"] for t in census.detect_O(key)})
    entries(key, rows)
    evt = {}
    for (a, t, n) in m["syms"]:
        if n.startswith("EVT_"):
            evt.setdefault(a, n)
    in_use = set(m["byname"]) | {r[7] for r in rows if r[7]}
    planned = {}                                # target address -> (name, cases, routine)
    sites = []
    nswitch = collections.Counter()
    for t in sorted(D, key=lambda t: t["file"]):
        rel, line = t["file"].rsplit(":", 1)
        ji = next(i for i, r in enumerate(rows) if r[2] == rel and r[3] + 1 == int(line))
        R = routine_of(key, rows, ji)
        if t["name"].endswith("_CaseTable"):
            R = t["name"][:-len("_CaseTable")]   # named for its switch's owner when it was framed
        if not R and t["name"] and t["name"].endswith("_Data"):
            R = t["name"][:-len("_Data")]        # a [nakarest] table named after its reader: <Reader>_Data
        if not R:
            continue
        nswitch[R] += 1
        P = R if nswitch[R] == 1 else "%s_Switch%d" % (R, nswitch[R])
        crow = [i for i in range(max(0, ji - 40), ji) if census.is_insn_row(key, rows[i]) and rows[i][2] == rel][-10:]
        texts = [clean(rows[i][6]) for i in crow]
        btok = bias_of(texts)
        bval = None
        if btok is not None:
            bval = int(btok, 0) if re.match(r'^(0x|\d)', btok) else m["byname"].get(btok)
        default = None
        for x in texts:
            mm = re.match(r'^jrl? (?:ugt|gt|uge|ge|nc|lt|mi|c), ?([A-Za-z_.$][\w.$@]*)$', x, re.I)
            if mm and mm.group(1) in m["byname"]:
                default = m["byname"][mm.group(1)]
        base = next((mm.group(1) for x in reversed(texts)
                     for mm in [re.match(r'^(?:lda|ld) x[a-z]+, ?\(?([A-Za-z_.$][\w.$@]*)(?::24)?\)?$', x, re.I)] if mm), None)
        cases = collections.defaultdict(list)
        for k, e in enumerate(t["ents"]):
            cases[e["val"]].append(k)
        for val, ks in sorted(cases.items(), key=lambda x: min(x[1])):
            e = next(x for x in t["ents"] if x["val"] == val)
            if e["tcls"] != "nolabel" or e["owner"] != key or val == default or val in planned:
                continue
            k0 = min(ks)
            if btok and btok.startswith("EVT_") and bval is not None and (bval + k0) in evt:
                nm = "%s_On%s" % (P, "".join(w.capitalize() for w in evt[bval + k0][4:].split("_")))
            else:
                nm = "%s_Case%d" % (P, (bval or 0) + k0)
            base_nm, n_ = nm, 2
            while nm in in_use:
                nm, n_ = "%s_%d" % (base_nm, n_), n_ + 1
            in_use.add(nm)
            vals = [((bval or 0) + k) for k in ks]
            planned[val] = (nm, vals, R)
        sites.append((t, base, bval, btok))

    # ---- table respelling plans
    edits = collections.defaultdict(list)      # rel -> [(first_line, last_line, new_lines)]
    respelled, skipped = 0, collections.Counter()
    for t, base, bval, btok in sites:
        if not base or base not in m["byname"]:
            skipped["base not a plain label"] += 1
            continue
        T, N = t["addr"], t["nwords"]
        lo_, hi_ = T, T + 2 * N
        cover = [r for r in rows if r[1] > lo_ and r[0] < hi_]
        cover.sort(key=lambda r: r[0])
        if not cover or cover[0][0] > lo_ or cover[-1][1] < hi_ or any(a[1] != b[0] for a, b in zip(cover, cover[1:])):
            skipped["bytes not contiguous in the map"] += 1
            continue
        names = []
        for e in t["ents"]:
            nm = label_at(m, rows, e["val"], planned)
            names.append(nm)
        if any(n is None for n in names) or len({r[2] for r in cover}) != 1:
            skipped["a target without a label" if any(n is None for n in names) else "table spans files"] += 1
            continue
        rel = cover[0][2]
        ok, out_lines, first, last = True, [], cover[0][3], cover[-1][3]
        if len({r[3] for r in cover}) != len(cover):
            skipped["several rows on one source line"] += 1
            continue
        shorts = ["\t.short\t%s - %s" % (n, base) for n in names]
        for idx, r in enumerate(cover):
            lo, hi, _, li, kind, detail, text, lab = r
            mm = LABEL_PREFIX.match(text.strip())
            labline = [mm.group(1) + ":"] if mm else []
            if kind == "data" and detail == ".incbin":
                mi = re.search(r'\.incbin\s+"([^"]+)"(?:\s*,\s*(0x[0-9a-fA-F]+|\d+)\s*,\s*(0x[0-9a-fA-F]+|\d+))?', text)
                if not mi:
                    ok = False
                    break
                path, off = mi.group(1), int(mi.group(2), 0) if mi.group(2) else 0
                part = labline[:]
                if lo < lo_:
                    part.append('\t.incbin "%s", 0x%x, 0x%x' % (path, off, lo_ - lo))
                if idx == 0 or not any(x.startswith("\t.short\t") for x in out_lines):
                    part += shorts
                if hi > hi_:
                    part.append('\t.incbin "%s", 0x%x, 0x%x' % (path, off + (hi_ - lo), hi - hi_))
                out_lines += part
            elif kind == "data" and detail in (".short", ".word", ".hword", ".2byte", ".byte") and lo >= lo_ and hi <= hi_:
                if not all(census.NUM.match(x) for x in census.operands(text)):
                    ok = False
                    break
                out_lines += labline
                if not any(x.startswith("\t.short\t") for x in out_lines):
                    out_lines += shorts
            else:
                ok = False
                break
        if not ok:
            skipped["table bytes are not plain numbers or an .incbin slice"] += 1
            continue
        edits[rel].append((first, last, out_lines))
        respelled += 1

    # ---- label insertions
    for val, (nm, vals, R) in planned.items():
        r = census.find(m, val)
        note = "\t; cases %s" % ", ".join(str(v) for v in vals) if len(vals) > 1 else ""
        edits[r[2]].append((r[3], r[3] - 1, [nm + ":" + note]))

    print("%s: %d D tables; %d case labels placed; %d tables respelled; not respelled: %s"
          % (key, len(D), len(planned), respelled, dict(skipped)))
    if dry:
        return
    for rel, ops in edits.items():
        p = os.path.join(root, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        spans = sorted(ops, key=lambda x: (-x[0], -(x[1] - x[0])))     # bottom-up; a replace before an insert at its line
        floor = None
        for a, b, new in spans:
            assert floor is None or b < floor, (rel, a, b)           # no two edits overlap
            L[a:b + 1] = new
            floor = a
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
