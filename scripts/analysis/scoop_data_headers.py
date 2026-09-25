#!/usr/bin/env python3
r"""scoop_data_headers.py -- draft evidence headers for every data object of a
source file, FROM ITS READERS.

QUESTION ANSWERED
-----------------
"What does each data object in this file represent, as far as the code that
reads it says?"  For every run of data lines the tool

  1. splits the run at every address some instruction loads (a table that the
     code enters at +0x20 is a second table),
  2. finds each reader (a source line naming an address in the object -- label,
     positional `.set`, absolute `.set` -- that is not the object's own label),
  3. reads the reader's instruction shape around that line:
       * `ld_rrl x, base, idx` + `call/jp (x)`     -> handler dispatch table
       * `lda_rr xiy, xiy, R` / `ld_rr* R, xiy, R` -> indexed table; the stride
         comes from the `sla R, k` / `muls` just before, the element size from
         the load width or the `ld bc, N` + `ldir` that follows
       * `ld bc, N` + `ldir` without an index     -> a fixed N-byte text/record
       * `call UIRender_TwoTableGeneral/SingleTable` after `ld xiy, obj`
                                                     -> a UIRender display list
  4. and drafts a label (when the object has none) and a header that cites the
     reader BY NAME AND ADDRESS and the arithmetic it uses.

It only DRAFTS: nothing is written.  The draft is a JSON spec for
scripts/converters/scoop_annotate.py, meant to be read and corrected by hand
before it is applied.  A header it cannot support with a reader says so
("no reader found by name or by 32-bit value").

RUN (repo root)
    python3 scripts/analysis/scoop_data_headers.py --image v10 \
        --file v10/maincpu/display/scoop_display.s --out DRAFT.json [--lo A --hi B]
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "converters"))
import scoop_reframe as R  # noqa: E402

R_DATA = {".byte", ".short", ".word", ".hword", ".2byte", ".long", ".4byte", ".int",
          ".ascii", ".asciz", ".string", ".incbin"}
STRUCT = re.compile(r'_(Skip|Join|Loop|Entry|Epilogue|Return|Helper|Sub|Code)\d*$|_0x[0-9A-Fa-f]+$')


def labels_code(L, k):
    """Does the label on line k label an INSTRUCTION (not data)?"""
    c = R.strip_comment(L[k])[0].strip()
    rest = c[R.LABEL_RE.match(c).end():].strip()
    if rest:
        return not rest.startswith(".")
    for j in range(k + 1, min(len(L), k + 12)):
        t = R.strip_comment(L[j])[0].strip()
        while R.LABEL_RE.match(t):
            t = t[R.LABEL_RE.match(t).end():].strip()
        if t:
            return not t.startswith(".")
    return False


def routine_of(L, i, n2a):
    """Nearest non-structural CODE label at or above line i -> (name, addr)."""
    for k in range(i, -1, -1):
        c = R.strip_comment(L[k])[0].strip()
        m = R.LABEL_RE.match(c)
        if m and not STRUCT.search(m.group(1)) and not m.group(1).startswith(".") \
                and labels_code(L, k):
            return m.group(1), n2a.get(m.group(1))
    return None, None


def text_name(blob):
    s = "".join(chr(c) if 0x20 < c < 0x7f and chr(c).isalnum() else " " for c in blob)
    words = [w.capitalize() for w in s.split() if w][:4]
    if not words:
        return None
    nm = "Str_" + "".join(words)
    if blob.rstrip().endswith(b"="):
        nm += "Eq"
    return nm[:40]


def analyse_site(L, i):
    """Instruction shape around a reader line -> dict of facts."""
    code = [R.strip_comment(x)[0].strip() for x in L[i:i + 10]]
    prev = [R.strip_comment(x)[0].strip() for x in L[max(0, i - 8):i]]
    f = {"line": code[0]}
    reg = None
    m = re.match(r'^(ld|lda)\s+(x\w+)\s*,', code[0])
    if m:
        reg = m.group(2).lower()
    f["reg"] = reg
    after = code[1:8]
    for x in after:
        xl = x.lower()
        if re.match(r'^(call|jp)\s+\(x', xl):
            f["dispatch"] = True
        if re.match(r'^ld_rrl\b', xl) or re.match(r'^ld_sril', xl):
            f["ptrload"] = True
        mm = re.match(r'^(ld_rr(b|w|l|8b)?|lda_rr|lda_dri|ld_rrb|ld_rrw)\b', xl)
        if mm:
            f["indexed"] = xl
        mm = re.match(r'^(ld|ldw)\s+bc\s*,\s*(0x[0-9a-f]+|\d+)', xl)
        if mm and "count" not in f:
            f["count"] = int(mm.group(2), 0)
        if xl.startswith(("ldir85", "ldirw", "ldir")) and "count" in f:
            f["copy"] = True
        if "uirender_twotablegeneral" in xl or "uirender_singletable" in xl:
            f["uirender"] = x.split()[-1]
        mm = re.match(r'^ld\s+(\w+)\s*,\s*\(x(iy|ix|hl|de|bc)\s*(\+\s*(\d+))?\)', xl)
        if mm:
            f.setdefault("reads", []).append(x)
    # stride evidence just before (index arithmetic)
    for x in prev[::-1] + after:
        xl = x.lower()
        mm = re.match(r'^sla\s+x?(hl|bc|wa|de|iy|iz)\s*,\s*(\d+)', xl)
        if mm and "stride" not in f:
            f["stride"] = 1 << int(mm.group(2))
            f["stride_insn"] = x
        mm = re.match(r'^muls8rr\s+a\s*,\s*\w+', xl)
        if mm and "stride" not in f:
            for y in prev[::-1] + after:
                m2 = re.match(r'^ld\s+a\s*,\s*(0x[0-9a-f]+|\d+)', y.lower())
                if m2:
                    f["stride"] = int(m2.group(1), 0)
                    f["stride_insn"] = x + " (A = %s)" % m2.group(1)
                    break
    idx = [x for x in prev if re.match(r'^ld\s+[lcaw]\s*,\s*\(', x.lower())]
    if idx:
        f["index_from"] = idx[-1]
    return f


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--lo")
    ap.add_argument("--hi")
    a = ap.parse_args()
    img, rel = a.image, a.file
    amap, elf = R.linemap(img, [rel])
    a2n, n2a = R.symbols(elf)
    addrs = amap[rel]
    ext = R.line_extents(addrs)
    lines = open(os.path.join(R.ROOT, rel), encoding="latin-1").read().split("\n")
    lo = int(a.lo, 16) if a.lo else 0
    hi = int(a.hi, 16) if a.hi else 1 << 32
    rb = R.rom(img)
    # data runs (instruction bytes written as `.byte ...\t; <insn>` are code)
    runs, cur = [], None
    for i, ln in enumerate(lines):
        ad, n = addrs[i], ext[i]
        if ad is None or not n:
            continue
        code, com = R.strip_comment(ln)
        c = code.strip()
        while R.LABEL_RE.match(c):
            c = c[R.LABEL_RE.match(c).end():].strip()
        isdata = c.split()[0].lower() in R_DATA if c else False
        isdata = isdata and not (
            c.startswith(".byte") and re.match(r';\s*[a-z]', com.strip() or "x") and "\t; " in ln)
        if isdata and lo <= ad < hi:
            if cur and cur[1] == ad:
                cur[1] = ad + n
            else:
                cur = [ad, ad + n, i]
                runs.append(cur)
        else:
            cur = None
    # all references in the image
    names_at = {}
    for nm, ad in n2a.items():
        names_at.setdefault(ad, []).append(nm)
    src = []
    for dp, _, fn in os.walk(os.path.join(R.ROOT, img, "maincpu")):
        for fnm in fn:
            if fnm.endswith(".s"):
                p = os.path.join(dp, fnm)
                src.append((os.path.relpath(p, R.ROOT), open(p, encoding="latin-1").read().split("\n")))
    allnames = {}
    for ad, ns in names_at.items():
        for nm in ns:
            if not nm.startswith(("Zsr_", "__drc_")):
                allnames[nm] = ad
    big = re.compile(r'(?<![\w.$])([A-Za-z_][\w.$]*)(?![\w.$])')
    refs = {}
    for relp, L in src:
        for i, ln in enumerate(L):
            code = R.strip_comment(ln)[0]
            cs = code.strip()
            if not cs or cs.startswith(".set"):
                continue
            body = cs
            while R.LABEL_RE.match(body):
                body = body[R.LABEL_RE.match(body).end():].strip()
            for m in big.finditer(body):
                nm = m.group(1)
                if nm in allnames:
                    refs.setdefault(allnames[nm], []).append((relp, i, nm))
    draft = []
    for (s, e, li) in runs:
        cuts = sorted({ad for ad in refs if s < ad < e})
        pieces = []
        p0 = s
        for c in cuts + [e]:
            pieces.append((p0, c))
            p0 = c
        for (ps, pe) in pieces:
            blob = rb[ps - R.BASE:pe - R.BASE]
            own = [nm for nm in names_at.get(ps, []) if not nm.startswith(("Zsr_", "__drc_"))]
            sites = []
            for (relp, i, nm) in refs.get(ps, []):
                L = dict(src)[relp]
                if relp == rel and i == next((k for k in range(li, len(lines)) if addrs[k] == ps and ext[k]), -1):
                    continue
                facts = analyse_site(L, i)
                rn, ra = routine_of(L, i, n2a)
                facts.update(file=relp, lineno=i + 1, name=nm, routine=rn, raddr=ra)
                sites.append(facts)
            printable = all(0x20 <= c < 0x7f or c in (0x88, 0x8b, 0x8c) or 0x13 <= c <= 0x1f for c in blob)
            ptrs = len(blob) % 4 == 0 and len(blob) >= 8 and all(
                0xE00000 <= int.from_bytes(blob[k:k + 4], "little") <= 0xFFFFFF for k in range(0, len(blob), 4))
            kind = "pointer table" if ptrs else ("LCD text" if printable else "byte data")
            if sites and any(x.get("dispatch") and x.get("ptrload") for x in sites):
                kind = "handler dispatch table"
            if sites and any(x.get("uirender") for x in sites):
                kind = "UIRender display list"
            label_there = [x for x in own if not re.search(r'_0x[0-9A-Fa-f]+$', x)]
            ent = {"file": rel, "addr": "0x%06X" % ps, "size": pe - ps, "kind": kind,
                   "names": own, "bytes": blob[:64].hex(" "), "text": blob[:64].decode("latin-1"),
                   "sites": sites}
            if not label_there:
                nm = text_name(blob) if kind == "LCD text" else None
                ent["label"] = nm or "TODO_Name_%06X" % ps
                ent["rename"] = {x: ent["label"] for x in own if re.search(r'_0x[0-9A-Fa-f]+$', x)}
            lines_c = []
            if sites:
                sx = sites[0]
                who = "%s (0x%06X)" % (sx["routine"], sx["raddr"]) if sx.get("raddr") else str(sx["routine"])
                lines_c.append("%s, %d B.  Read by %s: `%s`" % (kind.capitalize(), pe - ps, who, sx["line"]))
                if sx.get("stride"):
                    lines_c.append("indexed with stride %d (`%s`)%s" % (
                        sx["stride"], sx["stride_insn"],
                        (", index from `%s`" % sx["index_from"]) if sx.get("index_from") else ""))
                if sx.get("copy"):
                    lines_c.append("copies %d byte(s) per use (`ld bc, %d` + ldir) into the LCD text buffer"
                                   % (sx["count"], sx["count"]))
                if sx.get("uirender"):
                    lines_c.append("handed in XIY to %s" % sx["uirender"])
                if sx.get("dispatch") and sx.get("ptrload"):
                    lines_c.append("4-byte handler pointers, entry = index*4, called through `call (x)`")
                others = sorted({"%s:%d" % (x["file"].split("/")[-1], x["lineno"]) for x in sites[1:]})
                if others:
                    lines_c.append("also read at %s" % ", ".join(others[:8]))
            else:
                lines_c.append("%s, %d B.  No reader found by name (label, positional or absolute .set)."
                               % (kind.capitalize(), pe - ps))
            ent["comment"] = lines_c
            draft.append(ent)
    json.dump(draft, open(a.out, "w"), indent=1, ensure_ascii=False)
    print("%d objects drafted -> %s" % (len(draft), a.out))


if __name__ == "__main__":
    main()
