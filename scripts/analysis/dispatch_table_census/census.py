#!/usr/bin/env python3
"""Stage 2: how many jump/call tables have NOT yet fed the disassembly, per image?

QUESTION IT ANSWERS
  "For every jump/call table in every image, does each entry that points into code
   land on an already-disassembled, LABELLED instruction, spelled symbolically?
   Which tables do not, and what blocks their targets?"

INPUT
  map_<key>.pkl from build_maps.py: the exact byte -> source-line map of each image,
  built by scripts/analysis/data_range_census.py's marked-mirror instrument (proven
  inert against the dump), plus the mirror ELF's symbol table.

TABLE DETECTORS (each a separate, stated rule)
  A  `.long`/`.4byte`/`.int` runs framed in the source: consecutive contiguous
     `.long` lines of one file, broken at any label definition.  A word is a
     POINTER if its value lies in an image of the same CPU address space:
       KN5000 main: maincpu(same version) / hdae5000 / table_data / custom_data
                    (table_data's own boot block also at +0x600000);
       KN5000 sub : v142 / subboot;  WSA1 CPU1: prom_a / prom_b;  WSA1 CPU2: prom_c.
     v142 only: an all-numeric run is constants (0x400.. collides with numbers).
  J  jump-vector runs framed as code: >= 4 consecutive contiguous equal-length
     unconditional `jp imm24` / `jp imm16` / `jrl T` / `jr T` lines; plus the prom_b
     routine directory 0xF40000-0xF44018 as ONE table (`jp` slots are jumps, its
     `.long` slots are pointers).
  O  16-bit offset tables: `.short/.word/.hword/.2byte` lines whose every operand
     is `Sym - Base`; the target is Sym's ELF value.
  D  16-bit offset tables found from the CODE that reads them, whatever their spelling
     (added 2026-10-06: offset tables inside compiled-C .incbins were invisible to O):
     every `jp t, (xR+rr)` whose preceding <= 10 instruction lines of the same file
     hold the base (`lda xR, (B:24)` / `lda xR, B` / `ld xR, B`; B may be `Sym + 0xN`), the table
     (`lda xQ, (T:24)` or `add xQQ, T` / `ld xQQ, T`, T != B) and an upper bound
     (`cp r, N` or `cp r, N:i3`, then `jr`/`jrl`/`ret` ugt/gt -> N+1 entries, uge/ge/nc -> N).  The N
     words at T are read from the dump; each target is B + the word, sign-extended.
     A two-level switch (a byte map read through `extz`, then the offset table)
     takes its bound from the map: the table has max(map[0..N-1]) + 1 entries.  An entry is
     spelled symbolically iff the source line holding it is `.short Sym - Base`.
     A table O already reports (same address) is not reported again; sites with no
     readable base, table or bound are counted as `unresolved` in the report.
  U  UNFRAMED runs in non-`.long` bytes (.incbin, .byte, code lines): anchor =
     >= 3 consecutive LE32 words (stride 4, any offset) each equal to a LABELLED
     instruction start, >= 3 distinct; grown both ways over words equal to ANY
     instruction start.  Null control: anchor test against "labelled start + 1".
     Also at STRIDE 8 (2026-10-06), outside the stride-4 runs: one code pointer per 8-byte record (the
     KN5000 control-panel action lists, found by hand first).
     Inside a compiled-C .incbin an entry counts as symbolic iff its value is named
     in that bin's generated <stem>_link.ld (NAKA_ADDR(Name) / extern).

TARGET CLASSES (looked up in the owning image's map)
  code      instruction line start with a label (ELF symbol, or a source label on/above
            the line -- `.L` locals included); `.byte` lines whose comment carries an
            instruction decode, and WSA1 `m_*` instruction macros, count as instructions
  nolabel   instruction line start, no label at all              ("hidden routine")
  midinsn   inside an instruction line                           ("hidden"/stale)
  incbin_raw / incbin_C / incbin_asset / databyte / text / dataother / fill

CODE-TABLE TEST (A, O; J, D and U are code tables by construction)
  >= 1 entry on an instruction start AND >= half of the pointer entries in
  CODEISH = {code, nolabel, midinsn, incbin_raw}.

BLOCKERS
  A pointer entry outside CODEISH is a data field of the record, not an entry point,
  and never blocks (J `jp` and U entries always count).  An entry blocks if it is
  spelled numerically ("numeric" when the target is labelled code: spelling only)
  or its target class is not `code`.  A table is USED iff nothing blocks.

RUN (from the repository root; `make dispatch-census` does the first and the --snapshot step)
  python3 scripts/analysis/dispatch_table_census/build_maps.py          # once per tree state (~2 min)
  python3 scripts/analysis/dispatch_table_census/census.py --report     # the per-image table
  python3 scripts/analysis/dispatch_table_census/census.py --top        # summary + top-10 framed tables per image
  python3 scripts/analysis/dispatch_table_census/census.py --list KEY   # every not-used framed table of one image
  python3 scripts/analysis/dispatch_table_census/census.py --unresolved KEY   # D sites it could not read, and why
  python3 scripts/analysis/dispatch_table_census/census.py --snapshot docs/coverage
        # writes dispatch-census-<date>-NN.txt (report + top) and .json (per-image summary, every not-used table);
        # NN numbers the day's snapshots, so a committed one is never overwritten
  python3 scripts/analysis/dispatch_table_census/census.py --compare docs/coverage/dispatch-census-<date>.json
        # exit 1 when an image's not-used tables, unused targets or not-used unframed runs ROSE

PROVENANCE
  Written 2026-10-05 by a measurement lane (scratch ~/compartilhado/tmp/jumptable-census-2026-10-05/, harvested to
  research-scratch) and promoted here as the instrument of CLAUDE.md "Code-Coverage Evidence Ledger".
"""
import bisect
import collections
import json
import os
import pickle
import re
import sys

HERE = os.environ.get("DISPATCH_CENSUS_DIR") or os.path.join(os.environ.get("TMPDIR") or os.path.expanduser("~/compartilhado/tmp"),
                                                             "dispatch-table-census")   # build_maps.py's OUT
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
KEYS = ["v10", "v9", "v7", "v142", "subboot", "tabledata", "customdata", "hdae5000",
        "prom_a", "prom_b", "prom_c"]

BYTECMT = re.compile(r'^\s*(\S+:)?\s*\.byte\b[^;\n]*;\s*(?:MAME:|unidasm:|=\s*|[0-9A-F]{6}\s+[0-9a-f]{2}(?: [0-9a-f]{2})*\s{2,})?\s*(ld|lda|ldw|ldb|push|pop|call|calr|jp|jr|jrl|ret|reti|add|sub|and|or|xor|cp|inc|dec|bit|set|res|tset|ex|mul|div|sll|srl|sla|sra|rlc|rrc|rl|rr|ldir|lddr|ldi|ldd|swi|ei|nop|halt|link|unlk|djnz|scc|neg|cpl|extz|exts|mirr|paa|incf|decf|ldf|ldc|ldx)\b', re.I)
NUM = re.compile(r'^[-+]?\s*(0x[0-9a-fA-F]+|[0-9]+)$')
WSA1 = {"prom_a", "prom_b", "prom_c"}

MAPS = {}


def load(key):
    if key not in MAPS:
        m = pickle.load(open(os.path.join(HERE, "map_%s.pkl" % key), "rb"))
        rows = m["rows"]
        m["los"] = [r[0] for r in rows]
        m["lab"] = {a for (a, t, n) in m["syms"] if t in "tT"}
        m["byname"] = {}
        for (a, t, n) in m["syms"]:
            m["byname"].setdefault(n, a)
        lo = m["base"]
        m["range"] = (lo, lo + len(m["raw"]))
        # instruction-start set, for the U detector
        starts = set()
        for r in rows:
            if is_insn_row(key, r):
                starts.add(r[0])
        m["starts"] = starts
        m["lab"] |= {r[0] for r in rows if r[7] and is_insn_row(key, r)}
        MAPS[key] = m
    return MAPS[key]


def is_insn_row(key, r):
    kind, detail, text = r[4], r[5], r[6]
    if kind == "code":
        return True
    if key in WSA1 and detail.startswith("macro:m"):
        return True                 # WSA1 instruction macros that emit .byte
    if kind == "data" and detail == ".byte" and BYTECMT.match(text):
        return True                 # code held as .byte with its decode in the comment
    return False


def space(key):
    """[(image, delta)]: a target address A is looked up in image's map at A - delta.
    table_data's boot block runs at +0x600000 (BOOT_RESET_HANDLER = RESET_HANDLER +
    0x600000 in table_data/kn5000_table_data.s), so its own tables use that view."""
    if key in ("v10", "v9", "v7"):
        return [(key, 0), ("hdae5000", 0), ("tabledata", 0), ("customdata", 0)]
    if key == "tabledata":
        return [("tabledata", 0), ("tabledata", 0x600000), ("hdae5000", 0), ("customdata", 0)]
    if key in ("hdae5000", "customdata"):
        return [(key, 0)] + [(k, 0) for k in ("v10", "hdae5000", "tabledata", "customdata") if k != key]
    if key in ("v142", "subboot"):
        return [(key, 0), ("subboot" if key == "v142" else "v142", 0)]
    if key in ("prom_a", "prom_b"):
        return [(key, 0), ("prom_b" if key == "prom_a" else "prom_a", 0)]
    return [(key, 0)]


def owner(key, addr):
    """-> (image, address in that image's map) or None."""
    for k, d in space(key):
        lo, hi = load(k)["range"]
        if lo + d <= addr < hi + d:
            return k, addr - d
    return None


def find(m, addr):
    i = bisect.bisect_right(m["los"], addr) - 1
    if i < 0:
        return None
    r = m["rows"][i]
    return r if r[0] <= addr < r[1] else None


def classify(okey, addr):
    """-> (tcls, detail) for a target address owned by image okey."""
    m = load(okey)
    r = find(m, addr)
    if r is None:
        return "fill", "unmapped"
    lo, hi, rel, li, kind, detail, text, lab = r
    if is_insn_row(okey, r):
        sub = "as-.byte" if kind == "data" else detail
        if addr == lo:
            # a label is an ELF symbol OR a source label on/above this line --
            # assembler-local `.L` labels never reach the ELF but are labels.
            return ("code" if (addr in m["lab"] or lab) else "nolabel"), sub
        return "midinsn", sub
    if kind == "data":
        if detail == ".incbin":
            p = re.search(r'"([^"]+)"', text)
            p = p.group(1) if p else "?"
            if "generated/" in p:
                return "incbin_C", os.path.basename(p)
            if "images/" in p or p.endswith((".bmp", ".BMP")):
                return "incbin_asset", os.path.basename(p)
            return "incbin_raw", os.path.basename(p)
        if detail == ".byte":
            return "databyte", ""
        if detail in (".ascii", ".asciz", ".string") or "string" in detail or "text" in detail \
                or detail.startswith("macro:sd_"):
            return "text", detail
        return "dataother", detail
    if kind == "fill":
        return "fill", detail
    return "fill", "none:" + detail


CODEISH = {"code", "nolabel", "midinsn", "incbin_raw"}
INSN_START = {"code", "nolabel"}


def operands(text):
    c = text.split(";", 1)[0].strip()
    while True:
        mm = re.match(r'^[A-Za-z_.$][\w.$@]*:\s*', c)
        if not mm:
            break
        c = c[mm.end():]
    parts = c.split(None, 1)
    if len(parts) < 2:
        return []
    return [o.strip() for o in parts[1].split(",")]


def le(m, addr, n):
    o = addr - m["base"]
    return int.from_bytes(m["raw"][o:o + n], "little")


def label_of(m, rows, i):
    """the nearest source label at or above row i (same file)."""
    rel = rows[i][2]
    j = i
    while j >= 0 and rows[j][2] == rel:
        if rows[j][7]:
            return rows[j][7]
        j -= 1
    return None


def mk_entry(key, val, spelled_numeric, operand):
    o = owner(key, val)
    if o is None:
        return None
    ok_, addr = o
    tcls, sub = classify(ok_, addr)
    return dict(val=val, owner=ok_, tcls=tcls, sub=sub, num=bool(spelled_numeric), op=operand)


def blocker(t, e):
    """None if the entry does not block, else its reason."""
    if not e.get("jump") and e["tcls"] not in CODEISH:
        return None                      # a data pointer in a code table: not an entry point
    if e["tcls"] == "code":
        return "numeric" if e["num"] else None
    return e["tcls"] + ("/num" if e["num"] else "")


def detect_A(key):
    m = load(key)
    rows = m["rows"]
    tables = []
    cur = None
    for i, r in enumerate(rows):
        lo, hi, rel, li, kind, detail, text, lab = r
        isl = kind == "data" and detail in (".long", ".4byte", ".int")
        if key == "prom_b" and 0xF40000 <= lo < 0xF44018:
            isl = False                 # the routine directory is detector J's, as one table
        if isl and cur and rows[cur["last"]][1] == lo and rows[cur["last"]][2] == rel \
                and not lab:
            cur["rows"].append(i)
            cur["last"] = i
            continue
        if cur:
            tables.append(cur)
            cur = None
        if isl:
            cur = dict(rows=[i], last=i)
    if cur:
        tables.append(cur)
    out = []
    for t in tables:
        i0 = t["rows"][0]
        ents, nwords = [], 0
        for i in t["rows"]:
            lo, hi, rel, li, kind, detail, text, lab = rows[i]
            ops = operands(text)
            n = (hi - lo) // 4
            for k in range(n):
                nwords += 1
                val = le(m, lo + 4 * k, 4)
                op = ops[k] if len(ops) == n else "?"
                numeric = bool(NUM.match(op)) if op != "?" else True
                e = mk_entry(key, val, numeric, op)
                if e is None:
                    continue
                if numeric and key == "v142":
                    e["v142num"] = True     # kept only if the table also has a symbolic pointer
                e["at"] = lo + 4 * k
                ents.append(e)
        if any(e.get("v142num") for e in ents) and all(e.get("v142num") for e in ents):
            ents = []                       # v142: an all-numeric run is constants, not pointers
        name = label_of(m, rows, i0)
        out.append(dict(kind="A", addr=rows[i0][0], name=name, nwords=nwords,
                        file="%s:%d" % (rows[i0][2], rows[i0][3] + 1), ents=ents))
    return out


JUMPS = {0x1B: 4, 0x1A: 3, 0x78: 3, 0x68: 2}


def jump_target(m, r):
    lo, hi = r[0], r[1]
    op = m["raw"][lo - m["base"]]
    if op not in JUMPS or hi - lo != JUMPS[op]:
        return None
    if op == 0x1B:
        return le(m, lo + 1, 3)
    if op == 0x1A:
        return le(m, lo + 1, 2)
    if op == 0x78:
        d = le(m, lo + 1, 2)
        d = d - 0x10000 if d & 0x8000 else d
        return (hi + d) & 0xFFFFFF
    d = le(m, lo + 1, 1)
    d = d - 0x100 if d & 0x80 else d
    return (hi + d) & 0xFFFFFF


def detect_J(key):
    m = load(key)
    rows = m["rows"]
    out = []
    run = []

    def flush():
        if len(run) >= 4:
            ents = []
            for i in run:
                r = rows[i]
                t = jump_target(m, r)
                ops = operands(r[6])
                op = ops[0] if ops else "?"
                e = mk_entry(key, t, bool(NUM.match(op)), op)
                if e:
                    e["at"] = r[0]
                    e["jump"] = True
                    ents.append(e)
            out.append(dict(kind="J", addr=rows[run[0]][0], name=label_of(m, rows, run[0]),
                            nwords=len(run), file="%s:%d" % (rows[run[0]][2], rows[run[0]][3] + 1),
                            ents=ents))
    for i, r in enumerate(rows):
        if key == "prom_b" and 0xF40000 <= r[0] < 0xF44018:
            continue
        if r[4] == "code" and jump_target(m, r) is not None:
            prev = rows[run[-1]] if run else None
            if prev and prev[1] == r[0] and (prev[1] - prev[0]) == (r[1] - r[0]):
                run.append(i)
                continue
            flush()
            run[:] = [i]
        else:
            flush()
            run[:] = []
    flush()
    if key == "prom_b":                     # the routine directory, as one table
        ents, n = [], 0
        for i, r in enumerate(rows):
            if not (0xF40000 <= r[0] < 0xF44018):
                continue
            if r[4] == "code" and jump_target(m, r) is not None and m["raw"][r[0] - m["base"]] == 0x1B:
                n += 1
                ops = operands(r[6])
                op = ops[0] if ops else "?"
                e = mk_entry(key, jump_target(m, r), bool(NUM.match(op)), op)
                if e:
                    e["jump"] = True
            elif r[4] == "data" and r[5] == ".long":
                n += 1
                ops = operands(r[6])
                op = ops[0] if ops else "?"
                e = mk_entry(key, le(m, r[0], 4), bool(NUM.match(op)), op)
            else:
                continue
            if e:
                e["at"] = r[0]
                ents.append(e)
        out.append(dict(kind="J", addr=0xF40000, name="prom_b routine directory",
                        nwords=n, file="prom_b/wsa1_prom_b.s", ents=ents))
    return out


DIFF = re.compile(r'^([A-Za-z_.$][\w.$@]*)\s*-\s*([A-Za-z_.$][\w.$@]*)$')


def detect_O(key):
    m = load(key)
    rows = m["rows"]
    out, cur = [], None
    for i, r in enumerate(rows):
        lo, hi, rel, li, kind, detail, text, lab = r
        ops = operands(text) if kind == "data" and detail in (".short", ".word", ".hword", ".2byte") else []
        good = ops and all(DIFF.match(o) for o in ops)
        if good and cur and rows[cur[-1]][1] == lo and rows[cur[-1]][2] == rel and not lab:
            cur.append(i)
            continue
        if cur:
            out.append(cur)
            cur = None
        if good:
            cur = [i]
    if cur:
        out.append(cur)
    tables = []
    for t in out:
        ents, n = [], 0
        for i in t:
            for o in operands(rows[i][6]):
                n += 1
                a = DIFF.match(o).group(1)
                if a not in m["byname"]:
                    continue
                e = mk_entry(key, m["byname"][a], False, o)
                if e:
                    e["at"] = rows[i][0]
                    ents.append(e)
        tables.append(dict(kind="O", addr=rows[t[0]][0], name=label_of(m, rows, t[0]),
                           nwords=n, file="%s:%d" % (rows[t[0]][2], rows[t[0]][3] + 1), ents=ents))
    return tables


JPIDX = re.compile(r'^jp\s+t,\s*\((x[a-z]+)\s*\+\s*([a-z]+)\)$', re.I)
SYM = r'([A-Za-z_.$][\w.$@]*(?: \+ 0x[0-9a-fA-F]+)?|0x[0-9a-fA-F]+|\d+)'
UNRESOLVED = {}
UNRESOLVED_SITES = {}


def _val(m, tok):
    if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', tok):
        return int(tok, 0)
    mm = re.match(r'^(\S+) \+ (0x[0-9a-fA-F]+)$', tok)        # table_data's boot view: Sym + 0x600000
    if mm:
        v = m["byname"].get(mm.group(1))
        return None if v is None else v + int(mm.group(2), 16)
    return m["byname"].get(tok)


def detect_D(key, skip_addrs):
    m = load(key)
    rows = m["rows"]
    code = [i for i, r in enumerate(rows) if is_insn_row(key, r)]
    tables, unresolved = [], 0
    sites = UNRESOLVED_SITES.setdefault(key, [])
    for ci, i in enumerate(code):
        r = rows[i]
        c = re.sub(r'\s+', ' ', r[6].split(";", 1)[0]).strip()
        c = re.sub(r'^[A-Za-z_.$][\w.$@]*:\s*', '', c)
        mj = JPIDX.match(c)
        if not mj:
            continue
        xr = mj.group(1).lower()
        back = [rows[j] for j in code[max(0, ci - 10):ci] if rows[j][2] == r[2]]
        texts = [re.sub(r'\s+', ' ', re.sub(r'^[A-Za-z_.$][\w.$@]*:\s*', '', b[6].split(";", 1)[0].strip())) for b in back]
        base = tab = bound = cmap = None
        tab_at = None
        for idx in range(len(texts) - 1, -1, -1):
            t = texts[idx]
            mb = re.match(r'^(?:lda|ld) %s, ?\(?%s(?::24)?\)?$' % (xr, SYM), t, re.I)
            if mb and base is None:
                base = mb.group(1)
                continue
            mt = re.match(r'^(?:lda (x[a-z]+), ?\(%s:24\)|lda (x[a-z]+), ?%s|add (x[a-z]+), ?%s|ld (x[a-z]+), ?%s)$'
                          % (SYM, SYM, SYM, SYM), t, re.I)
            if mt and base is not None and tab is None:
                tok = next(g for g in mt.groups()[1::2] if g)      # groups 2/4/6/8 hold T
                if tok != base and _val(m, tok) is not None and not re.match(r'^(0x[0-9a-fA-F]{1,2}|\d{1,3})$', tok):
                    tab, tab_at = tok, idx
            elif mt and tab is not None and cmap is None:
                tok = next(g for g in mt.groups()[1::2] if g)
                # a byte map read through `extz` before the offset table: the bound counts the map
                if tok not in (base, tab) and _val(m, tok) is not None and \
                        any(x.startswith("extz") for x in texts[idx + 1:tab_at]):
                    cmap = tok
        for k in range(len(texts) - 1):
            mc = re.match(r'^cp ([a-z]+), ?(0x[0-9a-fA-F]+|\d+)(?::i3)?$', texts[k], re.I)
            mjr = re.match(r'^(?:jrl? (ugt|gt|uge|ge|nc),|ret (ugt|gt|uge|ge|nc)$)', texts[k + 1], re.I) if mc else None
            if mjr:
                nn = int(mc.group(2), 0)
                bound = nn + 1 if (mjr.group(1) or mjr.group(2)).lower() in ("ugt", "gt") else nn
        B, T = (_val(m, base) if base else None), (_val(m, tab) if tab else None)
        where = "%s:%d" % (r[2], r[3] + 1)
        if T is not None and T in skip_addrs:
            continue                        # the O detector already reports this table
        if B is None or T is None or not bound or bound > 512:
            unresolved += 1
            sites.append((where, "base=%s table=%s bound=%s" % (base, tab, bound)))
            continue
        o = owner(key, T)
        if o is None or o[0] != key:
            unresolved += 1
            sites.append((where, "table %s outside the image" % tab))
            continue
        T = o[1]                            # the table's address in this image's own map
        if cmap is not None:                # two-level switch: the table has max(map) + 1 entries
            M = owner(key, _val(m, cmap))
            if M is None or M[0] != key:
                unresolved += 1
                sites.append((where, "case map %s outside the image" % cmap))
                continue
            bound = max(le(m, M[1] + k_, 1) for k_ in range(bound)) + 1
        ents = []
        for n_ in range(bound):
            at = T + 2 * n_
            w = le(m, at, 2)
            val = (B + (w - 0x10000 if w & 0x8000 else w)) & 0xFFFFFF   # the 16-bit index is sign-extended
            rr = find(m, at)
            sym = bool(rr and rr[4] == "data" and rr[5] in (".short", ".word", ".hword", ".2byte")
                       and all(DIFF.match(x) for x in operands(rr[6])))
            e = mk_entry(key, val, not sym, "%s+%d" % (tab, 2 * n_))
            if e:
                e["at"], e["jump"] = at, True
                ents.append(e)
        tables.append(dict(kind="D", addr=T, name=tab, nwords=bound,
                           file="%s:%d" % (r[2], r[3] + 1), ents=ents))
    UNRESOLVED[key] = unresolved
    return tables


TREES = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu",
         "hdae5000": "hdae5000", "tabledata": "table_data", "customdata": "custom_data",
         "v142": "v142/subcpu", "subboot": "subcpu/boot"}
_LD = {}


def c_link_addrs(key, incpath):
    """Addresses named in the generated bin's <stem>_link.ld (empty if none)."""
    import glob
    stem = os.path.basename(incpath)[:-4]
    ck = (key, stem)
    if ck not in _LD:
        addrs = set()
        for ld in glob.glob(os.path.join(REPO, TREES.get(key, key), "**", stem + "_link.ld"),
                            recursive=True):
            for ln in open(ld, encoding="latin-1"):
                mm = re.match(r'\s*([A-Za-z_][\w.$]*)\s*=\s*0x([0-9A-Fa-f]+)\s*;', ln)
                if mm:
                    addrs.add(int(mm.group(2), 16))
        _LD[ck] = addrs
    return _LD[ck]


def detect_U(key, shift=0, minrun=3, mindistinct=3, stride=4, skip=None):
    """UNFRAMED runs of code pointers in bytes that are not a `.long` line.

    ANCHOR: >= minrun consecutive LE32 words (stride 4, any byte offset) each equal
    to a LABELLED instruction start of the same CPU space, with >= mindistinct
    distinct values (repeated u16-pair filler such as 0x00F000F0 is not a table).
    EXTENSION: the anchor is then grown both ways while the next word equals ANY
    instruction start (labelled or not), so a table's unlabelled targets are counted.
    NULL CONTROL: shift=1 runs the anchor test against "labelled start + 1".
    STRIDE 8 (added 2026-10-06): the same rule with the words 8 bytes apart finds one code pointer per
    8-byte record -- the KN5000 control-panel action lists (PanelButton_ActionListPool) were invisible
    at stride 4.  `skip` = byte ranges the stride-4 pass already reported, so no table counts twice."""
    m = load(key)
    rows = m["rows"]
    lab, anys = set(), set()
    for k, d in space(key):
        mm = load(k)
        lab |= {a + d + shift for a in mm["starts"] if a in mm["lab"]}
        anys |= {a + d for a in mm["starts"]}
    base, raw = m["base"], m["raw"]
    n = len(raw)
    elig = bytearray(n)
    for r in rows:
        if (r[4] == "data" and r[5] in (".long", ".4byte", ".int")) or r[4] == "fill":
            continue
        a0, b0 = max(r[0], base), min(r[1], base + n)
        if b0 > a0:
            elig[a0 - base:b0 - base] = b"\x01" * (b0 - a0)

    def w(o):
        return int.from_bytes(raw[o:o + 4], "little")

    def good(o, S):
        return 0 <= o and o + 4 <= n and elig[o] and elig[o + 3] and w(o) in S

    hits, covered, o = [], bytearray(n), 0
    for a0, b0 in (skip or ()):
        if b0 > a0:
            covered[max(a0 - base, 0):max(b0 - base, 0)] = b"\x01" * (max(b0 - base, 0) - max(a0 - base, 0))
    while o + 4 <= n:
        if covered[o]:
            o += 1
            continue
        j = o
        while good(j, lab) and not covered[j]:
            j += stride
        k = (j - o) // stride
        if k >= minrun and len({raw[x:x + 4] for x in range(o, j, stride)}) >= mindistinct:
            lo, hi = o, j
            if not shift:
                while good(lo - stride, anys) and not covered[lo - stride]:
                    lo -= stride
                while good(hi, anys) and not covered[hi]:
                    hi += stride
            covered[lo:hi] = b"\x01" * (hi - lo)
            hits.append((base + lo, (hi - lo) // stride))
            o = hi
            continue
        o += 1
    if shift:
        return hits
    tables = []
    for a, k in hits:
        r = find(m, a)
        ri = bisect.bisect_right(m["los"], a) - 1
        # ★ compiled C is a FRAME too: NAKA_ADDR(Name) / extern resolved by the
        # bin's generated <stem>_link.ld.  An entry counts as symbolic iff its value
        # is defined by name in that link script; raw bytes / numbers otherwise.
        ldaddrs = set()
        if r and r[5] == ".incbin" and "generated/" in r[6]:
            ldaddrs = c_link_addrs(key, re.search(r'"([^"]+)"', r[6]).group(1))
        ents = []
        for q in range(k):
            val = le(m, a + stride * q, 4)
            e = mk_entry(key, val, val not in ldaddrs, "C-ld" if val in ldaddrs else "raw")
            if e:
                e["at"] = a + stride * q
                e["jump"] = True            # every word is an instruction-start pointer
                ents.append(e)
        tables.append(dict(kind="U", addr=a, name=label_of(m, rows, ri) if r else None, stride=stride,
                           nwords=k, file="%s:%d (%s %s)" % (r[2], r[3] + 1, r[4], r[5]) if r else "?",
                           ents=ents, host=(r[4], r[5]) if r else None))
    return tables


def is_code_table(t):
    """J/U: by construction.  A/O: >= 1 entry on an instruction start AND at least
    half of the pointer entries land in code-ish territory (CODEISH)."""
    if t["kind"] in ("J", "D", "U"):
        return True
    n = len(t["ents"])
    st = sum(1 for e in t["ents"] if e["tcls"] in INSN_START)
    ci = sum(1 for e in t["ents"] if e["tcls"] in CODEISH)
    return st >= 1 and 2 * ci >= n


def blockers(t):
    c = collections.Counter()
    for e in t["ents"]:
        b = blocker(t, e)
        if b:
            c[b] += 1
    return c


def summarise(key, res):
    tabs = res[key]["tables"]
    used = [t for t in tabs if not blockers(t)]
    notu = [t for t in tabs if blockers(t)]
    newp, nump = set(), set()
    reasons = collections.Counter()
    for t in notu:
        for e in t["ents"]:
            b = blocker(t, e)
            if not b:
                continue
            reasons[b] += 1
            (nump if b == "numeric" else newp).add((e["owner"], e["val"]))
    return dict(n=len(tabs), used=len(used), notu=len(notu),
                newp_same={x for x in newp if x[0] == key},
                newp_other={x for x in newp if x[0] != key},
                nump=nump, reasons=reasons, notu_tables=notu)


def main():
    args = sys.argv[1:]
    res = {}
    for key in KEYS:
        o_tabs = detect_O(key)
        tabs = detect_A(key) + detect_J(key) + o_tabs + detect_D(key, {t["addr"] for t in o_tabs})
        tabs = [t for t in tabs if t["ents"] and is_code_table(t)]
        un = detect_U(key)
        spans = [(t["addr"], t["addr"] + 4 * t["nwords"]) for t in un]
        un += detect_U(key, stride=8, skip=spans)
        null = detect_U(key, shift=1) + detect_U(key, shift=1, stride=8, skip=spans)
        res[key] = dict(tables=tabs, unframed=un, null=len(null), d_unresolved=UNRESOLVED.get(key, 0))
    if "--json" in args:
        json.dump(res, open(args[args.index("--json") + 1], "w"), indent=0, default=str)
    if "--report" in args:
        report(res)
        return
    if "--snapshot" in args:
        snapshot(res, args[args.index("--snapshot") + 1])
        return
    if "--compare" in args:
        sys.exit(compare(res, args[args.index("--compare") + 1]))
    if "--unresolved" in args:
        key = args[args.index("--unresolved") + 1]
        for where, why in UNRESOLVED_SITES.get(key, []):
            print("%-60s %s" % (where, why))
        return
    if "--list" in args:
        key = args[args.index("--list") + 1]
        for t in res[key]["tables"]:
            b = blockers(t)
            if b:
                print("%s 0x%06X %-40s n=%d ptr=%d %s %s" % (t["kind"], t["addr"], t["name"],
                      t["nwords"], len(t["ents"]), dict(b), t["file"]))
                for e in t["ents"]:
                    bb = blocker(t, e)
                    if bb:
                        print("     @%06X -> %06X [%s] %-14s %-12s op=%s" % (
                            e["at"], e["val"], e["owner"], bb, e["sub"], e["op"]))
        return
    print("%-10s %6s %6s %6s | %7s %7s %7s | %6s %5s" % (
        "image", "tables", "used", "NOT", "newT", "newT-x", "numT", "U-runs", "null"))
    for key in KEYS:
        S = summarise(key, res)
        print("%-10s %6d %6d %6d | %7d %7d %7d | %6d %5d   %s" % (
            key, S["n"], S["used"], S["notu"], len(S["newp_same"]), len(S["newp_other"]),
            len(S["nump"]), len(res[key]["unframed"]), res[key]["null"],
            dict(S["reasons"])))
    if "--top" in args:
        top(res)


def top(res):
    if True:
        for key in KEYS:
            S = summarise(key, res)
            rows = []
            for t in S["notu_tables"]:
                b = blockers(t)
                tg = {e["val"] for e in t["ents"] if blocker(t, e)}
                rows.append((len(tg), t, b))
            rows.sort(key=lambda x: (-x[0], x[1]["addr"]))
            print("\n== %s: top not-used tables" % key)
            for n, t, b in rows[:10]:
                print("  %s 0x%06X %-44s entries=%-4d ptrs=%-4d unusedT=%-4d %s  %s" % (
                    t["kind"], t["addr"], t["name"], t["nwords"], len(t["ents"]), n,
                    dict(b), t["file"]))




def report(res):
    """The per-image answer: framed tables (A/J/O) and unframed runs (U) separately."""
    hdr = ("image", "framed", "used", "NOT", "newT", "newT(x)", "spellT", "U", "U-NOT", "U-newT", "null", "D-unres")
    print("%-10s %6s %5s %4s %6s %7s %6s | %3s %5s %6s %4s | %7s" % hdr)
    for key in KEYS:
        S = summarise(key, res)
        un = res[key]["unframed"]
        unot = [t for t in un if blockers(t)]
        unew = {(e["owner"], e["val"]) for t in unot for e in t["ents"]
                if blocker(t, e) and blocker(t, e) != "numeric"}
        print("%-10s %6d %5d %4d %6d %7d %6d | %3d %5d %6d %4d | %7d" % (
            key, S["n"], S["used"], S["notu"], len(S["newp_same"]), len(S["newp_other"]),
            len(S["nump"]), len(un), len(unot), len(unew), res[key]["null"], res[key].get("d_unresolved", 0)))
    print("D-unres: `jp t, (xR+rr)` dispatch sites whose base, table or bound the D detector could not read")
    print("\ndistinct new-entry-point targets by blocking class (framed tables, all owners):")
    for key in KEYS:
        S = summarise(key, res)
        by = collections.defaultdict(set)
        for t in S["notu_tables"]:
            for e in t["ents"]:
                b = blocker(t, e)
                if b and b != "numeric":
                    by[b.split("/")[0]].add((e["owner"], e["val"]))
        print("  %-10s %s" % (key, {k: len(v) for k, v in sorted(by.items())}))


def summary_json(res):
    """The per-image numbers and every not-used table, compact enough to commit and to diff."""
    out = {}
    for key in KEYS:
        S = summarise(key, res)
        un = res[key]["unframed"]
        unot = [t for t in un if blockers(t)]
        unew = {(e["owner"], e["val"]) for t in unot for e in t["ents"] if blocker(t, e) and blocker(t, e) != "numeric"}
        tabs = []
        for t in sorted(S["notu_tables"] + unot, key=lambda t: t["addr"]):
            tg = {e["val"] for e in t["ents"] if blocker(t, e)}
            tabs.append(dict(kind=t["kind"], addr="0x%06X" % t["addr"], name=t["name"], entries=t["nwords"],
                             pointers=len(t["ents"]), unused_targets=len(tg), blockers=dict(blockers(t))))
        out[key] = dict(framed=S["n"], used=S["used"], not_used=S["notu"], new_targets_same_image=len(S["newp_same"]),
                        new_targets_other_image=len(S["newp_other"]), spelling_only_targets=len(S["nump"]),
                        unframed_runs=len(un), unframed_not_used=len(unot), unframed_new_targets=len(unew),
                        null_control=res[key]["null"], d_unresolved_sites=res[key].get("d_unresolved", 0),
                        not_used_tables=tabs)
    return out


def snapshot_number(outdir, day):
    """The sequence number for today's snapshot: committed snapshots are never rewritten, so a later commit on the
    same day gets the next number; an uncommitted snapshot of today (a re-run before committing) is reused."""
    import glob
    import re
    import subprocess
    nums = sorted(int(m.group(1)) for f in glob.glob(os.path.join(outdir, "dispatch-census-%s-[0-9][0-9].json" % day))
                  for m in [re.search(r"-(\d\d)\.json$", f)] if m)
    if not nums:
        return 1
    last = os.path.join(outdir, "dispatch-census-%s-%02d.json" % (day, nums[-1]))
    tracked = subprocess.run(["git", "-C", REPO, "ls-files", "--error-unmatch", os.path.abspath(last)],
                             capture_output=True).returncode == 0
    return nums[-1] + 1 if tracked else nums[-1]


def snapshot(res, outdir):
    import contextlib
    import datetime
    import io
    import subprocess
    day = datetime.date.today().isoformat()
    head = subprocess.run(["git", "-C", REPO, "rev-parse", "--short=8", "HEAD"], capture_output=True, text=True).stdout.strip()
    dirty = bool(subprocess.run(["git", "-C", REPO, "status", "--porcelain", "--untracked-files=no"],
                                capture_output=True, text=True).stdout.strip())
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        print("dispatch-table census, %s, measured at %s%s" % (day, head, " (+ uncommitted changes)" if dirty else ""))
        print("tool: scripts/analysis/dispatch_table_census/ (rules in census.py's docstring)\n")
        report(res)
        print()
        top(res)
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, "dispatch-census-%s-%02d" % (day, snapshot_number(outdir, day)))
    open(base + ".txt", "w").write(buf.getvalue())
    json.dump(dict(date=day, head=head, dirty=dirty, images=summary_json(res)), open(base + ".json", "w"), indent=1)
    print("wrote %s.txt and %s.json" % (base, base))


def compare(res, old_path):
    old = json.load(open(old_path))["images"]
    new = summary_json(res)
    rose = 0
    for key in KEYS:
        o, n = old.get(key), new[key]
        if o is None:
            continue
        for f in ("not_used", "new_targets_same_image", "new_targets_other_image", "spelling_only_targets",
                  "unframed_not_used", "unframed_new_targets", "d_unresolved_sites"):
            if f not in o:
                continue
            if n[f] > o[f]:
                rose += 1
                print("ROSE  %-10s %-26s %d -> %d" % (key, f, o[f], n[f]))
            elif n[f] < o[f]:
                print("fell  %-10s %-26s %d -> %d" % (key, f, o[f], n[f]))
    print("compared with %s: %s" % (old_path, "%d figure(s) ROSE" % rose if rose else "nothing rose"))
    return 1 if rose else 0


if __name__ == "__main__":
    main()
