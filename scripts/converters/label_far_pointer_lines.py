#!/usr/bin/env python3
"""label_far_pointer_lines.py -- a far pointer that lands at the START of a data line gets a label there.

QUESTION THIS ANSWERS / JOB IT DOES
  After far_pointer_pipeline.sh, the far-pointer pushes and Reg* macro arguments still numeric
  point at bytes that are not in an `.incbin` slice -- mostly strings in `.include`d text
  (`GUI_FormatStrings`, `aligned_string "%s"` runs) and tables written as `.long`/`.byte`
  lines.  When the pointer is the first byte a DATA line emits (`aligned_string`, `.asciz`,
  `.ascii`, `.byte`, `.short`, `.long`, a data macro), that line gets a label, named as
  split_blobs_at_far_pointers.py names its pieces: a table a registration macro passes ->
  `<Module>_<Class>Table_<id>` / `..._<Class>Count_<id>`; a run of 32-bit own-ROM pointers ->
  `<Reader>_PtrTable`; a NUL-terminated ASCII string -> `<Reader>_Str_<Text>`; anything else is
  reported, not named.  A target inside a line, or on a code line, is reported.
  Line addresses come from symbolize_numeric_branches.build_map (the census marker mirror,
  which must reproduce the dump or the image is refused).  A label emits no byte: `make
  gate-all` proves the edit, and a follow-up symbolize_far_pointer_pushes.py run names the
  pushes and macro arguments.

USAGE
  make all && make wsa1
  python3 scripts/converters/label_far_pointer_lines.py --image v10 [--apply] [--report OUT]
  python3 scripts/converters/symbolize_far_pointer_pushes.py --image v10 --apply
  images: v10 v9 v7 hdae5000 prom_a
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
import symbolize_far_pointer_pushes as fp            # noqa: E402
import split_blobs_at_far_pointers as sb              # noqa: E402
import symbolize_numeric_branches as snb              # noqa: E402

REPO = fp.REPO
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=sorted(sb.ROM))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    elf, tree, (lo, hi) = fp.IMAGES[a.image]
    romfile, base = sb.ROM[a.image]
    rom = open(os.path.join(REPO, romfile), "rb").read()
    syms = fp.elf_symbols(elf)
    addr_of = {n: ad for ad, ns in syms.items() for n in ns}
    img = snb.image_by_key(a.image)
    srcroot = os.path.join(REPO, img["mirror"])
    marks, addrs, spans, rom_ok, src, macros = snb.build_map(img, srcroot)
    if not rom_ok:
        sys.exit("the marker mirror does not reproduce the dump: refusing")
    start_of = {s[0]: s for s in spans}
    own = os.path.relpath(os.path.join(REPO, tree), srcroot)
    files = sorted({s[2] for s in spans if own == "." or s[2].startswith(own + "/")})
    texts = {rel: open(os.path.join(srcroot, rel), "rb").read().decode("latin-1").split("\n")
             for rel in files}
    klass = {}
    for L in texts.values():
        for l in L:
            m = re.match(r'^\s*\.equ\s+NAKA_CLASS_(\w+)\s*,\s*(0x[0-9a-fA-F]+)', l)
            if m:
                klass[int(m.group(2), 16)] = m.group(1)
    taken = set(addr_of)
    for L in texts.values():
        for l in L:
            m = LABEL.match(l)
            if m:
                taken.add(m.group(1))

    # targets: (addr) -> [(reader addr, reader, role name or None)]
    targets = collections.defaultdict(list)
    for rel, L in texts.items():
        reader = None
        for i, l in enumerate(L):
            m = LABEL.match(l)
            if m and not sb.STRUCTURAL.search(m.group(1)) and m.group(1) in addr_of:
                reader = m.group(1)
            rd = reader or "?"
            if i + 1 < len(L):
                m1, m2 = fp.PUSH.match(l), fp.PUSH.match(L[i + 1])
                if m1 and m2:
                    h, lw = int(m1.group(2), 0), int(m2.group(2), 0)
                    v = (h << 16) | lw
                    if h <= 0xff and lo <= v <= hi and v not in syms:
                        targets[v].append((addr_of.get(rd, 1 << 30), rd, None))
            mm, found = fp.reg_macro_addresses(l)
            for k, v in found:
                if not (lo <= v <= hi and v not in syms):
                    continue
                role = fp.REG_ROLE[mm.group(2)].get(k)
                if role == "proc":
                    continue
                nm = None
                if role in ("table", "count"):
                    args = [x.strip() for x in mm.group(4).split(",")]
                    a0, ident = args[0], args[-1]
                    kind = a0[len("NAKA_CLASS_"):] if a0.startswith("NAKA_CLASS_") else \
                        klass.get(int(a0, 0)) if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', a0) else None
                    if kind and re.match(r'^(0x[0-9a-fA-F]+|\d+)$', ident):
                        pre = rd[len("Initialize"):] if rd.startswith("Initialize") and len(rd) > 10 else rd
                        nm = "%s_%s%s_%03X" % (pre, kind, "Table" if role == "table" else "Count",
                                               int(ident, 0))
                targets[v].append((addr_of.get(rd, 1 << 30), rd, nm))

    stats, rows, edits = collections.Counter(), [], {}
    for v in sorted(targets):
        ents = sorted(targets[v], key=lambda e: (e[2] is None, e[0]))
        rd, role_nm = ents[0][1], ents[0][2]
        row = {"value": hex(v), "reader": rd, "sites": len(ents)}
        sp = start_of.get(v)
        if not sp:
            stats["not-a-line-start"] += 1
            rows.append(dict(row, result="inside a line")); continue
        rel, li = sp[2], sp[3]
        if rel not in texts:
            stats["other-tree"] += 1
            continue
        line = texts[rel][li]
        bk, _ = snb.drc.classify_line(line, macros)
        if bk != "data":
            stats["not-a-data-line"] += 1
            rows.append(dict(row, result="%s:%d is %s" % (rel, li + 1, bk))); continue
        if LABEL.match(line):
            stats["line-already-labelled"] += 1
            continue
        npt = sb.ptr_table_at(rom, base, v, lo, hi)
        s = None if npt else sb.c_string_at(rom, base, v)
        if role_nm:
            stem = role_nm
        elif npt:
            stem = "%s_PtrTable" % rd
        elif s is not None and (v == base or rom[v - base - 1] in (0, 0xff)):
            stem = "%s_Str_%s" % (rd, sb.text_token(s))
        else:
            stats["not-named"] += 1
            rows.append(dict(row, result="%s:%d data, neither a string nor a table" % (rel, li + 1)))
            continue
        n, k = stem, 2
        while n in taken:
            n, k = "%s_%d" % (stem, k), k + 1
        taken.add(n)
        edits[(rel, li)] = n
        stats["labelled"] += 1
        rows.append(dict(row, result="label", name=n, at="%s:%d" % (rel, li + 1)))
    for (rel, li), n in edits.items():
        l = texts[rel][li]
        texts[rel][li] = "%s:\t%s" % (n, l.lstrip())
    # CLAUDE.md alignment rule: a run of consecutive `Label:<tabs>directive` lines that this
    # touched is re-aligned to one tab column (the next tab stop after its longest label)
    LDATA = re.compile(r'^([A-Za-z_][\w.$]*:)[ \t]+(\S.*)$')
    for rel in {r for r, _ in edits}:
        L = texts[rel]
        touched = {li for r, li in edits if r == rel}
        i = 0
        while i < len(L):
            if not LDATA.match(L[i]) or snb.drc.classify_line(L[i], macros)[0] != "data":
                i += 1
                continue
            j = i
            while j + 1 < len(L) and LDATA.match(L[j + 1]) and \
                    snb.drc.classify_line(L[j + 1], macros)[0] == "data":
                j += 1
            if any(i <= t <= j for t in touched) and j > i:
                parts = [LDATA.match(L[k]).groups() for k in range(i, j + 1)]
                col = (max(len(p[0]) for p in parts) // 8 + 1) * 8
                for k, (lab, rest) in zip(range(i, j + 1), parts):
                    L[k] = lab + "\t" * max(1, (col - len(lab) + 7) // 8) + rest
                stats["runs-aligned"] += 1
            i = j + 1
    if a.apply:
        for rel in {r for r, _ in edits}:
            open(os.path.join(srcroot, rel), "wb").write("\n".join(texts[rel]).encode("latin-1"))
    print("image %s: %s%s" % (a.image, dict(stats), "" if a.apply else " (dry run)"))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
