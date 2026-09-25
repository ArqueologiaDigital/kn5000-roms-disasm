#!/usr/bin/env python3
r"""hdae5000_switch_tables.py -- the compiled `switch` jump tables of the HD-AE5000.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
The Toshiba C compiler that built the HD-AE5000 program turns a dense `switch`
into this sequence (TLCS-900, shape seen at 52 sites):

    [sub  xwa, K]                 ; lowest case value (event codes 0x01E0003E..)
    cp   xwa, 0   / jr lt|c, dflt ; below range
    cp   xwa, M   / jr gt|ugt, dflt
    add  xwa, xwa                 ; *2
    add  xwa, TABLE               ; or: lda xix,(TABLE) + ld WA,(XIX+WA)
    ld   wa, (xwa)
    lda  xix, (BASE)              ; BASE = the byte after the jp
    jp   T, XIX+WA

TABLE holds M+1 u16 offsets from BASE, and it lives in the program's .rodata
at 0x2E1C82.., between the string literals of the same function -- where the
earlier passes typed it as text (`.asciz "%"`, `.asciz ")"`, `.asciz "x"` ...:
0x25, 0x29, 0x78 are the low bytes of offsets).  The case bodies are reached
ONLY through these tables, so until they are typed every case looks like
unreachable code (scripts/analysis/hdae5000_reachability.py).

With no argument the tool finds every such site, derives TABLE, BASE, the
entry count (M+1, from the bound compare) and the case values (K+i), and
ASSERTS: every target BASE+offset is the first byte of an instruction line of
the dispatching file; the table's bytes are emitted by whole source lines of
hdae5000_data_tables.s (no line straddles either end); no two tables overlap.
It prints one row per site.  With --apply it:
  * labels every case target <Owner>_Ev<code> (event switches, K >= 0x01000000)
    or <Owner>_Case<n>, renaming a local `.L` label already there and keeping a
    global one;
  * labels BASE (when no entry is 0, as <Owner>_SwitchBase);
  * replaces the table's lines with a header naming the reader, and
    `.short <case> - <BASE label>` rows, each commented with its case value(s);
  * makes the dispatch's TABLE and BASE operands symbolic.
Sites whose table operand is already symbolic (the two done earlier:
HDAE5000_LangText_CaseTable, HDAE5000_DoPrintf_ConvTable) are skipped, and the
two-level byte-map dispatch in hdae5000_ui_display.s near 0x28ED74 is reported,
not converted.

RUN (repo root, after a build of the hdae5000 image)
    python3 scripts/converters/hdae5000_switch_tables.py           # facts + asserts
    python3 scripts/converters/hdae5000_switch_tables.py --apply
--apply re-links through scripts/analysis/hdae5000_line_map.py, which refuses
unless the modified tree is byte-identical to the dump.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

B0 = 0x280000
LABEL = re.compile(r"^([.A-Za-z_][\w.$]*):")
STRUCT = re.compile(r"_(Skip|Join|Loop|Sub|Return|Epilogue|Entry|Exit|Done|Fail|Helper)\d*$")
DISPATCH = re.compile(r"^\s*jp_ind\s+8,\s*0x07,\s*0xF0,\s*0xE0\b", re.I)
NUM = r"(0x[0-9a-fA-F]+|\d+)"


def fail(m):
    sys.exit("REFUSED: " + m)


def num(s):
    return int(s, 16) if s.lower().startswith("0x") else int(s)


def body(t):
    m = LABEL.match(t)
    if m:
        t = t[m.end():]
    return t.split(";")[0].strip()


def find_sites(rows, rom):
    u16 = lambda a: int.from_bytes(rom[a - B0:a - B0 + 2], "little")
    starts = collections.defaultdict(set)      # (rel) -> instruction-start addresses
    labels_at = collections.defaultdict(list)  # addr -> [(rel, n, name)]
    for a, rel, n, t in rows:
        m = LABEL.match(t)
        if m:
            labels_at[a].append((rel, n, m.group(1)))
        if body(t) and not body(t).startswith("."):
            starts[rel].add(a)
    lab_addr = {}
    for a, rel, n, t in rows:
        m = LABEL.match(t)
        if m:
            lab_addr[m.group(1)] = a
    sites, skipped = [], []
    for k, (a, rel, n, t) in enumerate(rows):
        if not DISPATCH.match(body(t)):
            continue
        back = []
        j = k - 1
        while j >= 0 and len(back) < 16 and rows[j][1] == rel:
            b = body(rows[j][3])
            if b:
                back.append((rows[j][0], rows[j][2], b))
            j -= 1
        base_m = re.match(r"lda\s+xix,\s*\(" + NUM + r":24\)$", back[0][2])
        if not base_m:
            skipped.append((a, rel, n, "base operand not numeric (already symbolic?)"))
            continue
        base = num(base_m.group(1))
        tab = tab_line = None
        for ba, bn, b in back[1:]:
            m = re.match(r"(add\s+xwa,|lda\s+xix,\s*\(|ld\s+xix,)\s*" + NUM + r"(:24\))?$", b)
            if m and 0x2E0000 <= num(m.group(2)) < 0x300000:
                tab, tab_line = num(m.group(2)), (bn, b)
                break
        if tab is None:
            skipped.append((a, rel, n, "no numeric table operand"))
            continue
        # two-level (byte map) dispatch: an extz/sll between table load and base
        if any(re.match(r"(extz|sll)\b", b) for _, _, b in back[1:6]):
            skipped.append((a, rel, n, "two-level byte-map dispatch (table 0x%06X)" % tab))
            continue
        bound = sub = default = sub_text = None
        early = {}                       # address -> value, from `cp xwa,V / jr z,L` before the switch
        ib = None
        for i, (ba, bn, b) in enumerate(back):
            m = re.match(r"cp\s+x?wa,\s*" + NUM + r"(:i3)?$", b)
            mj = re.match(r"jrl?\s+(gt|ugt),\s*([.\w$]+)$", back[i - 1][2]) if i > 0 else None
            if m and mj:
                bound, default, ib = num(m.group(1)), lab_addr.get(mj.group(2)), i
                break
        if bound is None:
            fail("site 0x%06X %s:%d: no bound compare found" % (a, rel, n))
        j = ib + 1
        if (j + 1 < len(back) and re.match(r"jrl?\s+(lt|c|mi),", back[j][2])
                and re.match(r"cp\s+x?wa,\s*(0|0x0+)(:i3)?$", back[j + 1][2])):
            j += 2
        if j < len(back):
            m = (re.match(r"sub\s+x?wa,\s*" + NUM + r"$", back[j][2])
                 or re.match(r"dec\s+" + NUM + r",\s*x?wa$", back[j][2]))
            if m:
                sub, sub_text = num(m.group(1)), re.sub(r"\s+", " ", back[j][2]).replace(", ", ",")
                j += 1
        for i in range(j + 1, len(back)):
            m = re.match(r"cp\s+x?[bw][ca],\s*" + NUM + r"$", back[i][2])
            mj = re.match(r"jrl?\s+z,\s*([.\w$]+)$", back[i - 1][2])
            if m and mj and mj.group(1) in lab_addr:
                early.setdefault(lab_addr[mj.group(1)], num(m.group(1)))
        if base != a + 5:
            fail("site 0x%06X: base 0x%06X is not the byte after the jp" % (a, base))
        nent = bound + 1
        offs = [u16(tab + 2 * i) for i in range(nent)]
        targets = [base + o for o in offs]
        for tg in targets:
            if tg not in starts[rel]:
                fail("site 0x%06X: target 0x%06X is not an instruction start in %s" % (a, tg, rel))
        owner = None
        for jj in range(k, -1, -1):
            if rows[jj][1] != rel:
                break
            m = LABEL.match(rows[jj][3])
            if m and not m.group(1).startswith(".") and not STRUCT.search(m.group(1)):
                owner = m.group(1)
                break
        if owner is None:
            fail("site 0x%06X: no owner label" % a)
        sites.append(dict(addr=a, rel=rel, line=n, base=base, tab=tab, n=nent, sub=sub or 0,
                          offs=offs, targets=targets, owner=owner, tab_line=tab_line,
                          base_line=back[0][1], default=default, early=early,
                          sub_text=sub_text))
    # table extents: whole data lines, no overlap
    spans = sorted((s["tab"], s["tab"] + 2 * s["n"], s) for s in sites)
    for (a0, a1, s0), (b0, b1, s1) in zip(spans, spans[1:]):
        if b0 < a1:
            fail("tables 0x%06X and 0x%06X overlap" % (a0, b0))
    drows = [(a, n, t) for a, rel, n, t in rows if rel == "hdae5000_data_tables.s"]
    emit = [(a, n, t) for a, n, t in drows if body(t)]
    ends = {}
    for (a, n, t), nxt in zip(emit, emit[1:] + [(0x300000, 0, "")]):
        ends[n] = nxt[0]
    for a0, a1, s in spans:
        over = [(a, n, t) for a, n, t in emit if a < a1 and ends[n] > a0]
        if not over:
            fail("table 0x%06X: no source line emits it" % a0)
        first, last = over[0], over[-1]
        # labels strictly inside the table would move: refuse
        for a, n, t in drows:
            if LABEL.match(t) and a0 < a < a1:
                fail("table 0x%06X: label %s sits inside it" % (a0, LABEL.match(t).group(1)))
        s["span_lines"] = (first[1], last[1])
        s["prefix"] = rom[first[0] - B0:a0 - B0] if first[0] < a0 else b""
        s["suffix"] = rom[a1 - B0:ends[last[1]] - B0] if ends[last[1]] > a1 else b""
        s["prefix_at"], s["suffix_at"] = first[0], a1
    return sites, skipped, labels_at


def render(bs, at):
    """typed directives for a fragment of a line that a table boundary split"""
    out, i = [], 0
    while i < len(bs):
        j = i
        if bs[i] == 0:
            while j < len(bs) and bs[j] == 0:
                j += 1
            out.append("\t.zero %d\t\t\t\t; 0x%06X (split off by the table below/above)" % (j - i, at + i))
        elif 0x20 <= bs[i] < 0x7F and bs[i] not in (0x22, 0x5C):
            while j < len(bs) and 0x20 <= bs[j] < 0x7F and bs[j] not in (0x22, 0x5C):
                j += 1
            txt = bs[i:j].decode("ascii")
            if j < len(bs) and bs[j] == 0:
                out.append('\t.asciz "%s"\t\t\t; 0x%06X (split off by the table below/above)' % (txt, at + i))
                j += 1
            else:
                out.append('\t.ascii "%s"\t\t\t; 0x%06X (split off by the table below/above)' % (txt, at + i))
        else:
            while j < len(bs) and not (bs[j] == 0 or (0x20 <= bs[j] < 0x7F and bs[j] not in (0x22, 0x5C))):
                j += 1
            out.append("\t.byte %s\t\t\t; 0x%06X (split off by the table below/above)"
                       % (", ".join("0x%02x" % b for b in bs[i:j]), at + i))
        i = j
    return out


ADDR_LOCAL = re.compile(r"^\.L\w*?_[0-9a-fA-F]{4,6}$")


def names(sites, labels_at):
    """case label for every target: keep a global or a semantic local label already
    there; otherwise <Owner>_Default / _Ev<code> / _Case<n>."""
    per_owner = collections.Counter(s["owner"] for s in sites)
    seen_owner = collections.Counter()
    for s in sites:
        seen_owner[s["owner"]] += 1
        sfx = "" if per_owner[s["owner"]] == 1 else str(seen_owner[s["owner"]])
        s["tab_name"] = "%s_CaseTable%s" % (s["owner"], sfx)
        event = s["sub"] >= 0x01000000
        case_name, vals, rename = {}, collections.defaultdict(list), {}

        def fresh(tg, v, ev):
            if tg == s["default"]:
                return "%s_Default%s" % (s["owner"], sfx)
            return ("%s_Ev%08X" % (s["owner"], v) if ev
                    else "%s_Case%d%s" % (s["owner"], v, sfx and "_" + sfx))

        def choose(tg, v, ev):
            existing = [x[2] for x in labels_at.get(tg, []) if x[0] == s["rel"]]
            glob = [x for x in existing if not x.startswith(".") and not STRUCT.search(x)]
            if glob:
                return glob[0]
            sem = [x for x in existing if x.startswith(".") and not ADDR_LOCAL.match(x)]
            if sem:
                return sem[0]
            new = fresh(tg, v, ev)
            for x in existing:
                if ADDR_LOCAL.match(x) or STRUCT.search(x):
                    rename[x] = new
            return new

        for i, tg in enumerate(s["targets"]):
            v = s["sub"] + i
            vals[tg].append(v)
            if tg not in case_name:
                case_name[tg] = choose(tg, v, event)
        if s["base"] in case_name:
            s["base_name"] = case_name[s["base"]]
        elif s["base"] in s["early"]:
            v = s["early"][s["base"]]
            s["base_name"] = choose(s["base"], v, v >= 0x01000000)
        else:
            s["base_name"] = choose(s["base"], None, False) if False else None
            existing = [x[2] for x in labels_at.get(s["base"], []) if x[0] == s["rel"]]
            keep = [x for x in existing if not ADDR_LOCAL.match(x) and not STRUCT.search(x)]
            s["base_name"] = keep[0] if keep else "%s_SwitchBase%s" % (s["owner"], sfx)
            for x in existing:
                if x not in keep:
                    rename[x] = s["base_name"]
        s["case_name"], s["vals"], s["event"], s["rename"] = case_name, vals, event, rename
    return sites


def fmt_vals(vs, event):
    return ", ".join(("0x%08X" % v) if event else str(v) for v in vs)


def main(apply):
    rows, rom = hlm.build_map()
    sites, skipped, labels_at = find_sites(rows, rom)
    names(sites, labels_at)
    for s in sites:
        print("0x%06X %-22s %-40s table 0x%06X x%-3d base 0x%06X sub 0x%08X  %d targets"
              % (s["addr"], "%s:%d" % (s["rel"].replace("hdae5000_", ""), s["line"]), s["owner"],
                 s["tab"], s["n"], s["base"], s["sub"], len(set(s["targets"]))))
    if "-v" in sys.argv:
        for s in sites:
            print("  %s: default %s base %s early %s" % (s["tab_name"], s["case_name"].get(s["default"]),
                  s["base_name"], {hex(k): hex(v) for k, v in s["early"].items()}))
            print("     rename %s" % s["rename"])
    for a, rel, n, why in skipped:
        print("skipped 0x%06X %s:%d -- %s" % (a, rel, n, why))
    print("%d switch tables, %d bytes of table, %d distinct case targets"
          % (len(sites), sum(2 * s["n"] for s in sites), sum(len(set(s["targets"])) for s in sites)))
    if not apply:
        return
    files = {}
    for rel in {s["rel"] for s in sites} | {"hdae5000_data_tables.s"}:
        files[rel] = open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n")
    ins = collections.defaultdict(list)     # rel -> [(line_no, [texts])]
    renames = collections.defaultdict(dict)  # rel -> {old: new}
    code_at = collections.defaultdict(list)
    for a, rel, n, t in rows:
        code_at[(rel, a)].append((n, t))
    for s in sites:
        rel = s["rel"]
        L = files[rel]
        want = dict(s["case_name"])
        want[s["base"]] = s["base_name"]
        renames[rel].update(s["rename"])
        for tg, name in want.items():
            here = code_at[(rel, tg)]
            labs = [LABEL.match(t).group(1) for n, t in here if LABEL.match(t)]
            if name in labs or any(s["rename"].get(l) == name for l in labs):
                continue
            first = min(n for n, t in here if body(t))
            ins[rel].append((first, [name + ":"]))
        # operands
        n, b = s["tab_line"]
        L[n - 1] = re.sub(r"0x0*%x\b(:24)?" % s["tab"], lambda m: s["tab_name"] + (m.group(1) or ""),
                          L[n - 1], count=1, flags=re.I)
        if s["tab_name"] not in L[n - 1]:
            fail("could not rewrite table operand at %s:%d" % (rel, n))
        n = s["base_line"]
        L[n - 1] = re.sub(r"\(0x0*%x:24\)" % s["base"], "(%s:24)" % s["base_name"], L[n - 1], count=1, flags=re.I)
        if s["base_name"] not in L[n - 1]:
            fail("could not rewrite base operand at %s:%d" % (rel, n))
    # data tables: replace line ranges (bottom-up)
    D = files["hdae5000_data_tables.s"]
    for s in sorted(sites, key=lambda s: -s["tab"]):
        lo, hi = s["span_lines"]
        before_lbl, at_lbl, kept = [], [], []
        lab_addr = {n: a for a, rel, n, t in rows if rel == "hdae5000_data_tables.s"}
        for i in range(lo, hi + 1):
            ln = D[i - 1]
            m = LABEL.match(ln)
            if ln.strip().startswith(";") or re.match(r"\s*\.(set|equ)\b", ln):
                kept.append(ln)
            elif m:
                lab = ln if not body(ln) else m.group(1) + ":"
                (at_lbl if lab_addr.get(i) == s["tab"] else before_lbl).append(lab)
        pre = render(s["prefix"], s["prefix_at"]) if s["prefix"] else []
        suf = render(s["suffix"], s["suffix_at"]) if s["suffix"] else []
        hdr = [";",
               "; %s (0x%06X, %d x u16): the switch of %s" % (s["tab_name"], s["tab"], s["n"], s["owner"]),
               "; (dispatch at 0x%06X, %s:%d: %s%s, `add xwa,xwa`, `ld wa,(<table>+2i)`,"
               % (s["addr"], s["rel"], s["line"],
                  ("`%s`, " % s["sub_text"]) if s["sub_text"] else "",
                  "bound `cp xwa,%d`" % (s["n"] - 1)),
               "; `lda xix,(%s)`, `jp T,XIX+WA`).  Entry i is the offset from" % s["base_name"],
               "; %s of the case for %s %s+i; %d entries, pinned by the bound"
               % (s["base_name"], "event" if s["event"] else "value",
                  ("0x%08X" % s["sub"]) if s["event"] else str(s["sub"]), s["n"]),
               "; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.",
               ";"]
        new = kept + before_lbl + pre + at_lbl + hdr + [s["tab_name"] + ":"]
        for i, o in enumerate(s["offs"]):
            tg = s["targets"][i]
            new.append("\t.short\t%s - %s\t; %s%s" % (s["case_name"][tg], s["base_name"],
                                                        fmt_vals([s["sub"] + i], s["event"]),
                                                        " (default)" if tg == s["default"] else ""))
        D[lo - 1:hi] = new + suf
    for rel, items in ins.items():
        L = files[rel]
        for n, texts in sorted(items, reverse=True):
            L[n - 1:n - 1] = texts
    allren = {}
    for rel in renames:
        allren.update(renames[rel])
    for rel in hlm.FILES:
        if rel not in files:
            files[rel] = open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n")
    for rel, L in files.items():
        text = "\n".join(L)
        for old, new in allren.items():
            text = re.sub(r"(?<![\w.$])" + re.escape(old) + r"(?![\w.$])", new, text)
        open(os.path.join(hlm.HDAE, rel), "w", encoding="latin-1").write(text)
    hlm.build_map()
    print("applied; relinked mirror byte-identical; %d local labels renamed"
          % sum(len(v) for v in renames.values()))


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
