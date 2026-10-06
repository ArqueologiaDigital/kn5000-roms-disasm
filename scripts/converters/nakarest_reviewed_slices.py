#!/usr/bin/env python3
r"""nakarest_reviewed_slices.py -- apply reviewed slice typings of the NAKA C blobs (v10/v9/v7).

QUESTION ANSWERED
-----------------
A `[nakarest] purpose not established` note sits above several hundred asm slices of the naka_*.bin blobs
(`Label: .incbin "includes/generated/<blob>.bin", off, size`).  Their C members are anonymous `field_XXXX`
words.  Each such slice was read from the code that READS it.  The readings are recorded, one JSON object
per slice, in analysis/nakarest-slices/reviewed-*.json, each with:
- its evidence: file:line, the instruction, and what it shows;
- a `check`: a Python expression over the slice's bytes `b` that asserts the property the reading rests on;
- the proposed type, name and header.
The readings were made by read-only triage passes and checked against the cited code before they were
recorded (analysis/nakarest-slices/README.md).

This script applies every reading with verdict "type", per tree:
  * finds the slice in the tree by its CURRENT label (each tree's own offset; v7's can differ), requires the same
    size as recorded, and evaluates `check` on the tree's own bytes -- a tree whose bytes fail is skipped;
  * retypes the C members covering it (nakarest_c_model.retype) as the recorded type with the tree's own values
    (a record with "false_pointers": true may drop NAKA_ADDR/SELF initializers its reading shows are not pointers):
    scalar arrays, `char` strings, or a packed struct typedef `<Name>_t` placed before the blob struct.  A range
    holding a symbolic initializer (a pointer) is refused, and so is a SELF() into the middle of an element;
  * replaces the `[nakarest]` note above the asm label with the recorded header and, when the reading splits the
    slice into pieces, cuts the `.incbin` line into one labelled line per piece;
  * renames the label across the tree (*.s, *.h, *.ld; *.c in code only, never inside a comment), recording the
    rules in scripts/renaming/rename_nakarest_reviewed_<tree>.sed;
  * keeps every comment of the replaced C members, leading and trailing, in order (C comment gate).

RUN (repository root, built tree)
    python3 scripts/converters/nakarest_reviewed_slices.py [--apply] [analysis/nakarest-slices/reviewed-X.json ...]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all;
          python3 scripts/analysis/assert_c_comments_preserved.py --base HEAD <changed .c files>
              --allow '/\* (\w+_Tail: the last bytes of the asm slice \w+|zero padding|\d+ pointers|a value, not a pointer:
              identical in v7/v9/v10) \*/'   (notes of absorbed _Tail members, of fill and pointer runs, and the
              per-value false-pointer note: each describes the old member, not the typed one);
          python3 scripts/analysis/l2_symbol_reference.py --regen && --check
"""
import bisect
import glob
import json
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402
from name_resname_strings import segments   # noqa: E402

APPLY = "--apply" in sys.argv
FILES = [a for a in sys.argv[1:] if a.endswith(".json")] or sorted(
    glob.glob(os.path.join(ROOT, "analysis/nakarest-slices/reviewed-*.json")))
INC = re.compile(r'^([A-Za-z_]\w*):(\s*)\.incbin\s+"includes/generated/(naka_\w+)\.bin",\s*(0x[0-9A-Fa-f]+|\d+),\s*(0x[0-9A-Fa-f]+|\d+)\s*(;.*)?$')
# a generated per-value note on a word the old decode had to keep numeric; once the range is typed the note
# describes nothing (comment gate: --allow, see RUN)
STALE_INIT_NOTES = {"/* a value, not a pointer: identical in v7/v9/v10 */"}
TAIL_NOTE = re.compile(r'^\s*/\* (\w+_Tail): the last bytes of the asm slice \w+ \*/\s*$')
FMT = {"uint8_t": "<B", "int8_t": "<b", "uint16_t": "<H", "int16_t": "<h", "uint32_t": "<I", "int32_t": "<i"}
PER_ROW = {1: 16, 2: 8, 4: 4}
SIZES = {"uint8_t": 1, "int8_t": 1, "char": 1, "uint16_t": 2, "int16_t": 2, "uint32_t": 4, "int32_t": 4}


def dims_of(d):
    return [int(x, 0) for x in re.findall(r'\[([^\]]+)\]', d or "")]


def nelem(d):
    n = 1
    for k in dims_of(d):
        n *= k
    return n


_SORTED = {}
MAX_INTO = 64           # a ROM address this far past a label is spelled NAKA_ADDR(label) + offset
PTR = re.compile(r'@PTR\((0x[0-9A-F]{8})\)')
SYMFILE = {"v10": "symbols/maincpu_symbols_reference.txt", "v9": "symbols/maincpu_v9_symbols_reference.txt",
           "v7": "symbols/maincpu_v7_symbols_reference.txt"}
GENERIC = re.compile(r'_(Helper|Data|Code|Block|Branch|Stub|Part|Case|Entry|Sub|Thunk|Wrapper|Body|Chunk|Tail|Frag)\d*(_\d+)*$')


def scalar(ctype, v, radix):
    if ctype == "uint32_t" and 0xE00000 <= v < 0x1000000:
        return "@PTR(0x%08X)" % v           # a ROM address: resolved to SELF() / NAKA_ADDR() after the retype
    if radix == "dec" or ctype.startswith("int"):
        return "%d" % v
    w = {1: 2, 2: 4, 4: 8}[SIZES[ctype]]
    return "0x%0*X" % (w, v)


def values(ctype, b):
    n = len(b) // SIZES[ctype]
    return list(struct.unpack("<%d%s" % (n, FMT[ctype][1]), b))


def init_array(ctype, dims, b, radix, indent="        "):
    """initializer text of a scalar array of `dims` from bytes b."""
    if ctype == "char":
        if len(dims_of(dims)) != 1:
            raise SystemExit("char arrays must be 1-dimensional")
        lit = b[:-1] if b.endswith(b"\x00") else b
        return M.c_string(lit)
    vals = [scalar(ctype, v, radix) for v in values(ctype, b)]
    ds = dims_of(dims)
    if not ds:
        return vals[0]
    if len(ds) == 1:
        per = PER_ROW[SIZES[ctype]]
        rows = [indent + ", ".join(vals[i:i + per]) + "," for i in range(0, len(vals), per)]
        return "{\n" + "\n".join(rows) + "\n" + indent[:-4] + "}"
    inner = nelem("".join("[%d]" % d for d in ds[1:]))
    esz = inner * SIZES[ctype]
    rows = []
    for i in range(ds[0]):
        sub = b[i * esz:(i + 1) * esz]
        if len(ds) == 2:
            rows.append(indent + "{ " + ", ".join(scalar(ctype, v, radix) for v in values(ctype, sub)) + " },")
        else:
            rows.append(indent + init_array(ctype, "".join("[%d]" % d for d in ds[1:]), sub, radix, indent + "    ") + ",")
    return "{\n" + "\n".join(rows) + "\n" + indent[:-4] + "}"


def field_text(f, b):
    t = f["ctype"]
    if dims_of(f.get("dims")):
        if t == "char":
            return M.c_string(b[:-1] if b.endswith(b"\x00") else b)
        return "{ " + ", ".join(scalar(t, v, f.get("radix")) for v in values(t, b)) + " }"
    return scalar(t, values(t, b)[0], f.get("radix"))


def struct_size(fields):
    return sum(SIZES[f["ctype"]] * nelem(f.get("dims")) for f in fields)


def new_members(p, b):
    """NewMember list for one piece p (dict) over its bytes b."""
    name, ctype, dims = p["new_label"], p["ctype"], p.get("dims") or ""
    pre = ["    /* %s */" % p["cdoc"]] if p.get("cdoc") else []
    if ctype == "struct":
        fields = p["struct_fields"]
        esz = struct_size(fields)
        n = nelem(dims)
        if esz * n != len(b):
            raise SystemExit("%s: struct %d B x %d != %d" % (name, esz, n, len(b)))
        rows = []
        for i in range(n):
            e, o, parts = b[i * esz:(i + 1) * esz], 0, []
            for f in fields:
                k = SIZES[f["ctype"]] * nelem(f.get("dims"))
                parts.append(field_text(f, e[o:o + k]))
                o += k
            rows.append("        { " + ", ".join(parts) + " },")
        expr = ("{\n" + "\n".join(rows) + "\n    }") if dims_of(dims) else rows[0].strip().rstrip(",")
        return [M.NewMember(name + "_t", name, dims, len(b), expr, pre)]
    if SIZES[ctype] * nelem(dims) != len(b):
        raise SystemExit("%s: %s%s is %d B, slice %d B" % (name, ctype, dims, SIZES[ctype] * nelem(dims), len(b)))
    return [M.NewMember(ctype, name, dims, len(b), init_array(ctype, dims, b, p.get("radix")), pre)]


class KeepC(Exception):
    """verdict "name": the C stays as it is."""


_LD = {}


def LDSYMS(ld):
    """name -> value of a link script's `Name = 0x...;` lines."""
    if ld not in _LD:
        _LD[ld] = {m.group(1): int(m.group(2), 16) for m in re.finditer(r'^(\w+)\s*=\s*0x([0-9A-Fa-f]+);', 
                   open(ld, encoding="latin-1").read() if os.path.exists(ld) else "", re.M)}
    return _LD[ld]


def tree_symbols(tree):
    """address -> the name to use for a pointer to it (a non-local, non-generic name first)."""
    out = {}
    for ln in open(os.path.join(ROOT, SYMFILE[tree]), encoding="latin-1"):
        f = ln.split()
        if len(f) != 2 or ln.startswith("#"):
            continue
        a, n = int(f[1], 16), f[0]
        rank = (n.startswith("."), bool(GENERIC.search(n)), len(n))
        if a not in out or rank < out[a][0]:
            out[a] = (rank, n)
    return {a: n for a, (_, n) in out.items()}


def designator(cb, off):
    """SELF() designator of blob offset `off`: a member start or an array element start, else None."""
    k = cb.index_at(off)
    mb = cb.members[k]
    rel = off - mb.offset
    if rel == 0:
        return mb.name
    ds = dims_of(mb.dims)
    esz = mb.size // nelem(mb.dims)
    field = ""
    if rel % esz and mb.ctype in STRUCT_FIELDS:     # a field of one element of a struct written by this script
        fo = rel % esz
        hit = [(n, o, k_, d) for n, o, k_, d in STRUCT_FIELDS[mb.ctype] if o <= fo < o + k_]
        if not hit:
            return None
        n, o, k_, d = hit[0]
        if fo != o:
            fe = k_ // nelem(d) if d else k_
            if not d or (fo - o) % fe:
                return None
            field = ".%s[%d]" % (n, (fo - o) // fe)
        else:
            field = "." + n
        rel -= fo
    elif rel % esz:
        return None
    if not ds:
        return mb.name + field
    idx, q = [], rel // esz
    for d in reversed(ds):
        idx.append(q % d)
        q //= d
    idx.reverse()
    while len(idx) > 1 and idx[-1] == 0 and not field:
        idx.pop()
    return mb.name + "".join("[%d]" % i for i in idx) + field


def resolve_pointers(cb, syms, externs, numeric, prefer=None):
    """@PTR(v) markers in the initializers -> SELF(member) inside the blob, NAKA_ADDR(label) for a labelled
    ROM address (recorded in `externs`), else the plain number (recorded in `numeric`)."""
    base = cb.base()

    def res(m):
        v = int(m.group(1), 16)
        if base <= v < base + cb.size:
            d = designator(cb, v - base)
            if d:
                return "SELF(%s)" % d
            mb = cb.members[cb.index_at(v - base)]           # inside a member, off its element grid
            return "(SELF(%s) + %d)" % (mb.name, v - base - mb.offset)
        elif v in (prefer or {}) or v in syms:
            n = (prefer or {}).get(v) or syms[v]
            externs[n] = v
            return "NAKA_ADDR(%s)" % n
        else:                   # inside a labelled object: the nearest label at most MAX_INTO bytes below it
            if id(syms) not in _SORTED:
                _SORTED[id(syms)] = sorted(syms)
            ks = _SORTED[id(syms)]
            i = bisect.bisect_right(ks, v) - 1
            if i >= 0 and v - ks[i] <= MAX_INTO:
                n = syms[ks[i]]
                externs[n] = ks[i]
                return "(NAKA_ADDR(%s) + %d)" % (n, v - ks[i])
        numeric.append(v)
        return m.group(1)
    for e in cb.entries:
        if "@PTR(" in e.expr:
            e.expr = PTR.sub(res, e.expr)


def add_externs(text, ld, externs):
    """`extern const char X;` lines in the C text and `X = 0x...;` lines in its link script, for new NAKA_ADDR names."""
    L = text.split("\n")
    have = {x.split()[-1].rstrip(";") for x in L if x.startswith("extern const char ")}
    new = sorted(n for n in externs if n not in have)
    if new:
        k = max((i for i, x in enumerate(L) if x.startswith("extern const char ")), default=None)
        if k is None:
            k = next(i for i, x in enumerate(L) if x.startswith("#define BASE")) - 1
        L[k + 1:k + 1] = ["extern const char %s;" % n for n in new]
    ldt = open(ld, encoding="latin-1").read() if os.path.exists(ld) else ""
    add = "".join("%s = 0x%08X;\n" % (n, externs[n]) for n in sorted(externs)
                  if not re.search(r'^%s\s*=' % re.escape(n), ldt, re.M))
    return "\n".join(L), (ldt.rstrip("\n") + "\n" + add) if add else None


STRUCT_FIELDS = {}      # "<Name>_t" -> [(field, offset, size, dims)] of the typedefs this script writes


def register_struct(p):
    o, out = 0, []
    for f in p["struct_fields"]:
        k = SIZES[f["ctype"]] * nelem(f.get("dims"))
        out.append((f["name"], o, k, f.get("dims") or ""))
        o += k
    STRUCT_FIELDS[p["new_label"] + "_t"] = out


def typedef_text(p):
    lines = ["/* %s's element (scripts/converters/nakarest_reviewed_slices.py). */" % p["new_label"],
             "typedef struct __attribute__((packed)) {"]
    for f in p["struct_fields"]:
        lines.append("    %s %s%s;" % (f["ctype"], f["name"], f.get("dims") or ""))
    lines.append("} %s_t;" % p["new_label"])
    return "\n".join(lines) + "\n\n"


def pieces(r):
    if r.get("pieces"):
        return r["pieces"]
    p = {k: r[k] for k in r if k in ("new_label", "ctype", "dims", "struct_fields", "cdoc", "header", "check", "radix",
                                     "check_on")}
    p.update(off_in_slice=0, size=r["size"])
    return [p]


def find_slice(tree, rel, label):
    p = os.path.join(ROOT, tree, "maincpu", rel)
    L = open(p, "rb").read().decode("latin-1").split("\n")
    for i, x in enumerate(L):
        m = INC.match(x)
        if m and m.group(1) == label:
            return p, L, i, m.group(3), int(m.group(4), 0), int(m.group(5), 0)
    return p, L, None, None, None, None


def main():
    recs = []
    for f in FILES:
        recs += [r for r in json.load(open(f)) if r.get("verdict") in ("type", "name")]
    for r in recs:
        for p in pieces(r):
            if p.get("ctype") == "struct":
                register_struct(p)
    names = [p["new_label"] for r in recs for p in pieces(r)]
    dup = {n for n in names if names.count(n) > 1}
    assert not dup, ("new label used twice", sorted(dup))
    total = 0
    for tree in ("v10", "v9", "v7"):
        tdir = os.path.join(ROOT, tree, "maincpu")
        alltext = "\n".join(open(q, "rb").read().decode("latin-1") for q in
                            glob.glob(os.path.join(tdir, "**", "*.s"), recursive=True))
        defined = set(re.findall(r'^([A-Za-z_]\w*):', alltext, re.M))
        renames, done, skipped = [], 0, []
        cbs, asm = {}, {}
        syms = tree_symbols(tree)
        lds = {}
        numeric_all = []
        kept_init_comments = []
        for r in recs:
            ps = pieces(r)
            path, L, k, blob, off, size = find_slice(tree, r["asm"], r["label"])
            if k is None:
                skipped.append((r["label"], "label not found"))
                continue
            if ps[0]["header"] and ps[0]["header"][0] in L[max(0, k - 12):k]:
                skipped.append((r["label"], "already applied (its header is above the label)"))
                continue
            if size != r["size"]:
                skipped.append((r["label"], "size %d != %d" % (size, r["size"])))
                continue
            assert not any(p["new_label"] == r["label"] for p in ps[1:]), ("a later piece keeps the old label", r["label"])
            assert sum(p["size"] for p in ps) == size and [p["off_in_slice"] for p in ps] == \
                [sum(q["size"] for q in ps[:i]) for i in range(len(ps))], r["label"]
            raw = open(os.path.join(tdir, "includes/generated", blob + ".bin"), "rb").read()
            bad = None
            for p in ps:
                b = raw[off + p["off_in_slice"]:off + p["off_in_slice"] + p["size"]]
                if p.get("check_on") == "slice":            # a check written with slice offsets
                    b = raw[off:off + size]
                try:
                    ok = not p.get("check") or eval(p["check"], {"struct": struct, "b": b})
                except Exception as e:
                    ok = False
                    bad = "check error for %s: %s" % (p["new_label"], e)
                if not ok and not bad:
                    bad = "check failed for %s" % p["new_label"]
                n = p["new_label"]
                if n != r["label"] and n in defined:
                    bad = "%s already defined" % n
            if bad:
                skipped.append((r["label"], bad))
                continue
            c = os.path.join(tdir, "ui_widgets", blob + ".c")
            if r.get("verdict") == "name":          # the C is already typed: header and name only
                if c not in cbs:
                    cbs[c] = [open(c, "rb").read().decode("latin-1"), None]
                if re.search(r'\b%s\b' % re.escape(ps[0]["new_label"]), cbs[c][0]) and ps[0]["new_label"] != r["label"]:
                    skipped.append((r["label"], "C name taken"))
                    continue
                ps = [dict(p, header=p["header"]) for p in ps]
            if c not in cbs:
                cbs[c] = [open(c, "rb").read().decode("latin-1"), None]
            # C: typedefs first (they must precede the blob struct), then the retype on a fresh parse
            text = cbs[c][0]
            if r.get("verdict") == "name":
                ps_c = []
            else:
                ps_c = ps
            for p in ps_c:
                if p["ctype"] == "struct" and ("} %s_t;" % p["new_label"]) not in text:
                    kk = text.index("typedef struct __attribute__((packed)) {\n", text.index("#define BASE"))
                    text = text[:kk] + typedef_text(p) + text[kk:]
            M.register_local_types(text)
            open(c + ".probe", "wb").write(text.encode("latin-1"))
            try:
                if not ps_c:
                    raise KeepC()
                cb = M.CBlob(c + ".probe")
                # a member the reading lists as a false pointer that straddles the slice boundary: retype it alone
                # as plain bytes first, so the slice can be cut there (its bytes are fill or data, not an address)
                fp_names = {d.get("member") for d in r.get("false_pointer_detail", []) if isinstance(d, dict)}
                if r.get("false_pointers") and fp_names:
                    for x in list(cb.members):
                        if x.name in fp_names and (x.offset < off < x.offset + x.size or
                                                   x.offset < off + size < x.offset + x.size):
                            cb.retype(x.offset, x.offset + x.size,
                                      [M.bytes_member(x.name, raw[x.offset:x.offset + x.size])], raw, false_pointers=[x.name])
                inside = {x.name for x in cb.members if off <= x.offset < off + size}
                if any(p["new_label"] in cb.by_name and p["new_label"] not in inside for p in ps):
                    raise SystemExit("C member name taken")
                sym = [x.name for x in cb.members if off <= x.offset < off + size
                       and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[x.name]].expr)]
                # a range holding pointers may be retyped only if every pointer comes out symbolic again; the
                # old NAKA_ADDR names are preferred for their addresses
                old_syms = sum(len(re.findall(r'NAKA_ADDR\(|SELF\(', cb.entries[cb.by_name[x]].expr)) for x in sym)
                prefer = {}
                byname = {n: a for a, n in syms.items()}
                for x in sym:
                    for n in re.findall(r'NAKA_ADDR\((\w+)\)', cb.entries[cb.by_name[x]].expr):
                        a = byname.get(n) or LDSYMS(c[:-2] + "_link.ld").get(n)
                        if a is not None:
                            prefer[a] = n
                nm = []
                for p in ps:
                    b = raw[off + p["off_in_slice"]:off + p["off_in_slice"] + p["size"]]
                    nm += new_members(p, b)
                # every comment of the members being replaced, in order: their leading lines and their trailing
                # `/* ... */` (retype keeps the first, split_word and retype drop the second; the C comment gate
                # wants both, in order)
                ordered = []
                init_comments = []      # comments inside the replaced initializers' expressions, in order
                for x, e in zip(cb.members, cb.entries):
                    if x.offset >= off and x.offset < off + size:
                        for cm in re.findall(r'/\*.*?\*/', e.expr, re.S):
                            if cm not in STALE_INIT_NOTES:
                                init_comments.append(cm)
                for x in cb.members:
                    if x.offset < off + size and x.offset + x.size > off:
                        if x.offset >= off:
                            ordered += x.pre
                        t = re.search(r'/\*.*?\*/|//.*', x.tail)
                        if t:
                            ordered.append("    " + t.group(0))
                cb.retype(off, off + size, nm, raw, false_pointers=sym)
                if r.get("false_pointers"):     # the reading says the old pointers were not pointers (its evidence)
                    sym, old_syms = [], 0
                first = cb.members[cb.by_name[nm[0].name]]
                first.pre = ordered + list(nm[0].pre_lines)
                if init_comments:
                    fe = cb.entries[cb.by_name[nm[0].name]]
                    fe.pre = fe.pre.rstrip(" ") + "\n    ".join(init_comments) + "\n    "
                    kept_init_comments.extend(init_comments)
                externs, numeric = {}, []
                resolve_pointers(cb, syms, externs, numeric, prefer)
                if sym:
                    new_syms = sum(len(re.findall(r'NAKA_ADDR\(|SELF\(', cb.entries[cb.by_name[x.name]].expr)) for x in nm)
                    if numeric or new_syms < old_syms:
                        raise SystemExit("pointers not all symbolic again (%d before, %d after, %d numeric)"
                                         % (old_syms, new_syms, len(numeric)))
                numeric_all += [(r["label"], v) for v in numeric]
                # a generated `<X>_Tail: the last bytes of the asm slice <Y>` note whose member the retype absorbed
                # describes nothing any more (comment gate: --allow TAIL_NOTE)
                text = "\n".join(x for x in cb.render().split("\n")
                                 if not (TAIL_NOTE.match(x) and TAIL_NOTE.match(x).group(1) not in cb.by_name))
                if externs:
                    ld = c[:-2] + "_link.ld"
                    text, ldt = add_externs(text, ld, dict(lds.get(ld, {}), **externs))
                    lds.setdefault(ld, {}).update(externs)
                cbs[c][0] = text
            except KeepC:
                pass
            except SystemExit as e:
                skipped.append((r["label"], "C: %s" % e))
                continue
            finally:
                os.remove(c + ".probe")
            # asm: header(s) and piece lines
            if path not in asm:
                asm[path] = L
            L = asm[path]
            k = next(i for i, x in enumerate(L) if INC.match(x) and INC.match(x).group(1) == r["label"])
            j = k
            while L[j - 1].startswith("; [nakarest]"):
                j -= 1
            new = []
            for p in ps:
                new += p["header"]
                o = off + p["off_in_slice"]
                new.append('%s:\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X' % (
                    r["label"] if p is ps[0] else p["new_label"], blob, o, p["size"]))
            L[j:k + 1] = new
            if ps[0]["new_label"] != r["label"]:
                renames.append((r["label"], ps[0]["new_label"]))
            done += 1
        print("%s: %d slices typed, %d renames, %d skipped; NAKA_ADDR externs %d; ROM-range numbers left numeric %d"
              % (tree, done, len(renames), len(skipped), sum(len(v) for v in lds.values()), len(numeric_all)))
        if kept_init_comments:
            print("    initializer comments carried over: %d" % len(kept_init_comments))
        for lab, v in numeric_all:
            print("    numeric %-44s 0x%06X" % (lab, v))
        for s in skipped:
            print("    skip %-48s %s" % s)
        total += done
        if not APPLY:
            continue
        for c, (text, _) in cbs.items():
            data = text.encode("latin-1")
            open(c + ".tmp", "wb").write(data)
            os.replace(c + ".tmp", c)
        for ld, ex in lds.items():
            ldt = open(ld, encoding="latin-1").read()
            add = "".join("%s = 0x%08X;\n" % (n, ex[n]) for n in sorted(ex) if not re.search(r'^%s\s*=' % re.escape(n), ldt, re.M))
            if add:
                data = (ldt.rstrip("\n") + "\n" + add).encode("latin-1")
                open(ld + ".tmp", "wb").write(data)
                os.replace(ld + ".tmp", ld)
        for p, L in asm.items():
            data = "\n".join(L).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
        if renames:
            sed = os.path.join(ROOT, "scripts/renaming/rename_nakarest_reviewed_%s.sed" % tree)
            old = open(sed).read() if os.path.exists(sed) else \
                "# rename_nakarest_reviewed_%s.sed -- written by scripts/converters/nakarest_reviewed_slices.py\n" % tree
            add = "".join("s/\\b%s\\b/%s/g\n" % rr for rr in renames if ("s/\\b%s\\b/" % rr[0]) not in old)
            open(sed, "w").write(old + add)
            hit = subprocess.run(["grep", "-rlwE", "|".join(o for o, _ in renames), tdir, "--include=*.s", "--include=*.c",
                                  "--include=*.h", "--include=*.ld"], capture_output=True, text=True).stdout.split()
            rx = re.compile(r'\b(%s)\b' % "|".join(re.escape(o) for o, _ in renames))
            rmap = dict(renames)
            for q in hit:
                t = open(q, "rb").read().decode("latin-1")
                if q.endswith(".c"):        # C: code only; a comment keeps the name it was written with (comment gate)
                    t = "".join(rx.sub(lambda m: rmap[m.group(1)], seg) if k == "code" else seg for k, seg in segments(t))
                else:
                    t = rx.sub(lambda m: rmap[m.group(1)], t)
                data = t.encode("latin-1")
                open(q + ".tmp", "wb").write(data)
                os.replace(q + ".tmp", q)
    print("total %d" % total)


if __name__ == "__main__":
    main()
