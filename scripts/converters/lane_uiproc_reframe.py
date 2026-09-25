#!/usr/bin/env python3
r"""RE-FRAME A LINE WINDOW OF A KN5000 SOURCE FILE AS CORRECTLY FRAMED INSTRUCTIONS.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
Parts of v10/v9 `ui_window_procs.s`, `drawbar_panel_ui.s`, ... were lifted by an
older decoder that lost instruction framing: a real 7-byte `cp (0x03044e),0`
(d2 4e 04 03 3f 00 00) sits in the tree as `.byte 0xd2 / popw iz / max / pop sr
/ push xsp / nop / nop`, and every "instruction" after it until the decode
happens to resync is a phantom.  The same code in v7 is a verbatim `.incbin`
romslice.  The byte gate is green over both, because the bytes are right; the
TEXT is wrong.

This tool re-spells a window of whole source lines from the ROM bytes they emit:

1. the window's address span comes from the census's inert marker mirror
   (scripts/analysis/data_range_census.py), the same machinery the branch
   symboliser uses;
2. the span is decoded LINEARLY BY MAME's unidasm, the independent decoder, and
   unidasm's instruction boundaries are the framing (the span must end exactly
   on an instruction boundary, or the tool refuses);
3. each instruction's bytes are spelled by this backend's own disassembler
   (`llvm-mc -disassemble`), accepted only if it consumes exactly the same
   number of bytes AND re-assembles to the same bytes; otherwise the bytes are
   emitted as `.byte` with unidasm's reading as a comment;
4. every operand that is a ROM address (branch targets, `call`/`jp`
   absolutes, `lda`/`ld` of an address in 0xE00000-0xFFFFFF) is replaced by the
   label defined at that address if one exists (preferring the window's own
   labels, then descriptive names); PC-relative targets inside the window get
   no new names here -- run symbolize_numeric_branches.py afterwards;
5. every existing label, comment and non-emitting directive in the window is
   carried over IN ORDER to the address it had (comments stay a subsequence ->
   assert_comments_preserved.py passes).  A label that lands INSIDE an
   instruction of the new framing is a misframe artefact: it is dropped only if
   nothing outside the window names it (checked over every .s of the image and
   refused otherwise);
6. absurd decodes (halt, swi, ldf, max/min/normal, incf/decf, undefined `db`,
   stray reti) are REPORTED; the tool refuses to apply unless --allow-absurd, so
   a data island inside the window is not silently re-typed as code.  Declare
   data islands with --data START:END (hex, absolute) and they are emitted as
   `.byte` (or `.long <label>` where a 32-bit word is a label's address).

--apply rewrites the file (latin-1 in / out) and then re-links the image through
a fresh inert mirror and requires byte-identity with the dump; on any mismatch
the file is restored.  Always follow with `make gate`.

RUN
    python3 scripts/converters/lane_uiproc_reframe.py --image v10 \
        --file ui/ui_window_procs.s --lines 8259:10053            # dry run
    ... --apply
    ... --out /tmp/x.s        # write the rendered window only, for review

Written for lane `uiproc`, 2026-09-25.
"""
import argparse
import concurrent.futures as cf
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc  # noqa: E402

LLVM_MC = drc.MC
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
CACHE = os.environ.get("UIPROC_CACHE", "/tmp/claude-1000/lane-uiproc/llvm_dis_cache.json")

LABEL_RE = re.compile(r'^\s*([A-Za-z_.$][\w.$@]*):')
ABSURD = re.compile(r'^(halt|swi|ldf|max|min|normal|incf|decf|db|reti)\b', re.I)
ROM_LO, ROM_HI = 0xE00000, 0x1000000


def image(key):
    for img in drc.IMAGES:
        if img["key"] == key:
            return img
    sys.exit("unknown image %r" % key)


def build_map(img, srcroot):
    tmp = tempfile.mkdtemp(prefix="uiproc-rf-")
    try:
        mdir = os.path.join(tmp, "mirror")
        marks = drc.mirror_tree(srcroot, mdir)
        elf = drc.link_mirror(mdir, img, tmp)
        raw = os.path.join(tmp, "img.bin")
        drc.sh([drc.OBJCOPY, "-O", "binary", elf, raw])
        got = open(raw, "rb").read()
        rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
        ok = got[:len(rom)] == rom
        ma = drc.marker_addresses(elf)
        amap = {}
        for n, (rel, li) in enumerate(marks):
            if n in ma:
                amap[(rel, li)] = ma[n]
        syms, absyms = {}, {}
        for line in drc.sh([drc.NM, "-n", elf]).split("\n"):
            p = line.split()
            if len(p) >= 3 and not p[2].startswith(drc.MARK):
                v = int(p[0], 16)
                if p[1] in ("t", "T"):
                    syms.setdefault(v, []).append(p[2])
                elif p[1] in ("a", "A") and ROM_LO <= v < ROM_HI:
                    # `.set X, Label + N` positional names come out absolute
                    absyms.setdefault(v, []).append(p[2])
        for v, ns in absyms.items():
            syms.setdefault(v, []).extend(ns)
        return amap, syms, rom, ok
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def unidasm_linear(rom, img, a, b):
    off = a - img["base"]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(rom[off:off + (b - a)])
        p = f.name
    try:
        out = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", "%x" % a],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(p)
    ins = []
    for line in out.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            ad = int(m.group(1), 16)
            n = len(m.group(2).split())
            ins.append((ad, n, m.group(3).strip()))
    return ins


_cache = None


def cache():
    global _cache
    if _cache is None:
        try:
            _cache = json.load(open(CACHE))
        except Exception:
            _cache = {}
    return _cache


def encode(text):
    """-> list of bytes llvm-mc encodes `text` to, or None."""
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "-show-encoding"],
                       input=text + "\n", capture_output=True, text=True)
    if r.returncode != 0 or "error" in r.stderr:
        return None
    enc = []
    for line in r.stdout.splitlines():
        m = re.search(r'encoding:\s*\[(.*?)\]', line)
        if m:
            enc += [int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))]
    return enc or None


def llvm_spell(bs):
    """Spell one instruction's bytes with this backend.  -> text or None."""
    key = bytes(bs).hex()
    c = cache()
    if key in c:
        return c[key]
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "-disassemble"],
                       input=" ".join("0x%02x" % x for x in bs) + "\n",
                       capture_output=True, text=True)
    lines = [l for l in r.stdout.splitlines()
             if l.strip() and not l.strip().startswith(".text")]
    res = None
    if r.returncode == 0 and "invalid" not in r.stderr and len(lines) == 1:
        t = lines[0].strip()
        if encode(t) == list(bs):
            res = t
    c[key] = res
    return res


def fmt(t):
    """Tab after the mnemonic, as the tree's formatting policy requires."""
    t = t.strip()
    p = t.split(None, 1)
    return "\t" + p[0] + ("\t" + p[1] if len(p) > 1 else "")


PRETTY = [
    # (regex on llvm's spelling, replacement) -- each accepted only if llvm-mc
    # encodes the replacement to the very same bytes
    (r'^lda_24\s+(\w+),\s*\((0x[0-9a-f]+|\d+)\)$', r'lda \1, (\2:24)'),
    (r'^ld[bwl]_da\s+(\w+),\s*\((0x[0-9a-f]+|\d+)\)$', r'ld \1, (\2:24)'),
    (r'^st[bwl]_da\s+\((0x[0-9a-f]+|\d+)\),\s*(\w+)$', r'ld (\1:24), \2'),
    (r'^cp([bw])_da\s+\((0x[0-9a-f]+|\d+)\),\s*(\S+)$', r'cp\1 (\2:24), \3'),
    (r'^(add|sub|and|or|xor|cp|adc|sbc)da(?:8|16|32)_24\s+(\w+),\s*\((0x[0-9a-f]+|\d+)\)$',
     r'\1 \2, (\3:24)'),
    (r'^(and|or|xor)mi8\s+(\(.*\)),\s*(\d+)$', lambda m: "%s %s, 0x%02x" % (m.group(1), m.group(2), int(m.group(3)))),
    (r'^incm8\s+(\d+),\s*(\(.*\))$', r'inc \1, \2'),
    (r'^decm8\s+(\d+),\s*(\(.*\))$', r'dec \1, \2'),
    (r'^incm\s+(\d+),\s*(\(.*\))$', r'incw \1, \2'),
    (r'^decm\s+(\d+),\s*(\(.*\))$', r'decw \1, \2'),
]


def hexaddr(m):
    v = int(m.group(1), 0)
    return "(0x%06x:%s)" % (v, m.group(2))


def prettify(t, bs):
    """A more readable spelling of llvm's text, if one encodes identically."""
    t = re.sub(r'\s+', ' ', t.strip())
    t = re.sub(r'\s*,\s*', ', ', t)
    for pat, rep in PRETTY:
        m = re.match(pat, t)
        if m:
            cand = re.sub(pat, rep, t) if not callable(rep) else rep(m)
            cand = re.sub(r'\((\d+):(24|16)\)', hexaddr, cand)
            if encode(cand) == list(bs):
                return cand
    # bitmask immediates of and/or/xor in hex
    m = re.match(r'^(and|or|xor)\s+(\w+),\s*(\d+)$', t)
    if m and int(m.group(3)) > 9:
        cand = "%s %s, 0x%x" % (m.group(1), m.group(2), int(m.group(3)))
        if encode(cand) == list(bs):
            return cand
    return t


def pick_label(names, prefer):
    for n in names:
        if n in prefer:
            return n
    good = [n for n in names if not n.startswith(".L") and not n.startswith("__")]
    return (good or names)[0]


def symbolise(text, ad, n, syms, prefer, window):
    """Replace ROM-address operands by labels.  Returns (text, [unresolved])."""
    mn = text.split(None, 1)[0]
    ops = text.split(None, 1)[1] if " " in text or "\t" in text else ""
    unresolved = []
    # PC-relative branches: llvm prints the displacement
    if mn in ("jr", "jrl", "calr"):
        m = re.match(r'^(?:([a-z]+)\s*,\s*)?(-?\d+)$', ops.strip())
        if m:
            d = int(m.group(2))
            # llvm prints jrl/calr displacements UNSIGNED 16-bit and jr signed
            # (or unsigned) 8-bit: sign-extend both before adding
            if mn == "jr" and d >= 0x80:
                d -= 0x100
            elif mn != "jr" and d >= 0x8000:
                d -= 0x10000
            tgt = (ad + n + d) & 0xFFFFFF
            if tgt in syms:
                lab = pick_label(syms[tgt], prefer)
                return "%s\t%s%s" % (mn, (m.group(1) + ", ") if m.group(1) else "", lab), []
            unresolved.append(tgt)
            return text, unresolved
    # absolute values: decimal numbers or hex in the ROM range
    def rep(m):
        v = int(m.group(0), 0)
        if ROM_LO <= v < ROM_HI:
            if v in syms:
                return pick_label(syms[v], prefer)
            unresolved.append(v)
            return "0x%06x" % v
        if v >= 0x10000:
            return ("0x%06x" % v) if v < 0x1000000 else ("0x%x" % v)
        return m.group(0)
    new = re.sub(r'(?<![\w.$:+-])(0x[0-9a-fA-F]+|\d{5,})(?![\w])', rep, ops)
    return (mn + "\t" + new) if ops else mn, unresolved


class Refused(Exception):
    pass


def render_window(img, rom, amap, syms, lines, rel, lo0, hi0, datar, srcroot, ext_cache):
    """Render source lines lo0..hi0 (0-based, inclusive) of `rel` from the ROM.
    -> (rendered text lines, report dict).  Raises Refused."""
    emit = ext_cache.setdefault(("emit", rel), sorted(
        (ad, li) for (r, li), ad in amap.items() if r == rel))
    addr_of = {li: ad for ad, li in emit}
    nxt_after = {}
    for i, (ad, li) in enumerate(emit):
        nxt_after[li] = emit[i + 1][0] if i + 1 < len(emit) else None
    win = [li for li in range(lo0, hi0 + 1) if li in addr_of]
    if not win:
        raise Refused("no emitting line in window")
    A = addr_of[win[0]]
    B = nxt_after[win[-1]]
    if B is None:
        import bisect
        allad = ext_cache.setdefault("allad", sorted(amap.values()))
        B = allad[bisect.bisect_right(allad, addr_of[win[-1]])]
    for i in range(len(win) - 1):
        if nxt_after[win[i]] != addr_of[win[i + 1]]:
            raise Refused("window not contiguous at line %d" % (win[i] + 1))
    carry = []          # (addr, order, kind, text)
    labels_here = {}
    pend = []
    for li in range(lo0, hi0 + 1):
        t = lines[li]
        code = drc.strip_comment(t).strip()
        m = LABEL_RE.match(t)
        cm = t[len(drc.strip_comment(t)):].rstrip() if ";" in t else ""
        if li in addr_of:
            ad = addr_of[li]
            for p in pend:
                carry.append((ad,) + p)
                if p[1] == "label":
                    labels_here.setdefault(ad, []).append(p[2])
            pend = []
            if m:
                carry.append((ad, li, "label", m.group(1)))
                labels_here.setdefault(ad, []).append(m.group(1))
            if cm:
                carry.append((ad, li + 0.5, "tcomment", cm.strip()))
        else:
            if m:
                pend.append((li, "label", m.group(1)))
                rest = code[len(m.group(0).strip()):].strip()
                if rest:
                    pend.append((li + 0.25, "directive", "\t" + rest))
                if cm:
                    pend.append((li + 0.5, "comment", cm.strip()))
            elif code:
                pend.append((li, "directive", t.rstrip()))
            elif t.strip():
                pend.append((li, "comment", t.rstrip()))
            else:
                pend.append((li, "blank", ""))
    trailing = pend
    prefer = set(n for ns in labels_here.values() for n in ns)

    def in_data(x):
        return any(s <= x < e for s, e in datar)
    ins = []
    bounds = sorted(set([A, B] + [x for d in datar for x in d if A <= x <= B]))
    for s, e in zip(bounds, bounds[1:]):
        if in_data(s):
            ins.append((s, e - s, None, "data"))
            continue
        dec = unidasm_linear(rom, img, s, e)
        end = dec[-1][0] + dec[-1][1] if dec else s
        if end != e:
            raise Refused("unidasm framing of %06X-%06X ends at %06X, not on the "
                          "window/data boundary" % (s, e, end))
        for d in dec:
            ins.append(d + ("code",))
    code_ins = [(ad, n) for ad, n, u, k in ins if k == "code"]
    off = lambda x: x - img["base"]
    with cf.ThreadPoolExecutor(8) as ex:
        spelt = dict(zip(code_ins, ex.map(
            lambda t: llvm_spell(list(rom[off(t[0]):off(t[0]) + t[1]])), code_ins)))
    with cf.ThreadPoolExecutor(8) as ex:
        pretty = dict(zip(code_ins, ex.map(
            lambda t: prettify(spelt[t], rom[off(t[0]):off(t[0]) + t[1]]) if spelt[t] else None,
            code_ins)))
    boundaries = set(ad for ad, n, u, k in ins)
    rep = {"A": A, "B": B, "absurd": [], "byted": [], "mismatch": [], "unresolved": [],
           "stranded": [], "n": len(ins)}
    out_ins = {}
    for ad, n, u, k in ins:
        bs = rom[off(ad):off(ad) + n]
        if k == "data":
            rows = []
            for q in range(0, n, 8):
                rows.append("\t.byte\t" + ", ".join("0x%02x" % x for x in bs[q:q + 8]))
            out_ins[ad] = "\n".join(rows)
            continue
        if ABSURD.match(u):
            rep["absurd"].append((ad, u))
        t = spelt[(ad, n)]
        if t is None:
            rep["byted"].append((ad, u))
            out_ins[ad] = ("\t.byte\t" + ", ".join("0x%02x" % x for x in bs) +
                           "\t; " + re.sub(r',(?=\S)', ', ', u.lower()))
            continue
        um = u.split()[0].lower()
        lm = t.split()[0].lower()
        if not (lm.startswith(um[:2]) or um.startswith(lm[:2])):
            rep["mismatch"].append((ad, u, t))
        st, unres = symbolise(pretty[(ad, n)], ad, n, syms, prefer, (A, B))
        rep["unresolved"] += [(ad, x) for x in unres]
        body = fmt(st)
        if re.search(r'_(erp|dpi|dri|sri\w*|ind|spi|dsp|rr\w*)\b', st.split()[0]):
            body += "\t; " + re.sub(r',(?=\S)', ', ', u.lower())
        out_ins[ad] = body
    for ad, li, k, t in carry:
        # a label AT the window end (B) belongs to the next line, not inside ours
        if k == "label" and ad not in boundaries and ad != B:
            rep["stranded"].append((ad, t))
    if rep["stranded"]:
        names = set(t for ad, t in rep["stranded"])
        for dp, dn, fn in os.walk(srcroot):
            for f in fn:
                if not f.endswith(".s"):
                    continue
                pth = os.path.join(dp, f)
                r2 = os.path.relpath(pth, srcroot)
                src = ext_cache.get(("src", r2))
                if src is None:
                    src = open(pth, encoding="latin-1").read().split("\n")
                    ext_cache[("src", r2)] = src
                for i, l in enumerate(src):
                    if r2 == rel and lo0 <= i <= hi0:
                        continue
                    c = drc.strip_comment(l)
                    for nm in names:
                        if nm in c and re.search(r'(?<![\w.$])' + re.escape(nm) + r'(?![\w.$])', c):
                            rep.setdefault("ext", {}).setdefault(nm, []).append("%s:%d" % (r2, i + 1))
    out = []
    ci = sorted(carry, key=lambda x: (x[0], x[1]))
    j = 0
    for ad, n, u, k in ins:
        tcom = []
        while j < len(ci) and ci[j][0] < ad + n:
            cad, li, kk, t = ci[j]
            if cad > ad and kk == "label":
                pass    # stranded inside this instruction: dropped (reported)
            elif kk == "label":
                out.append(t + ":")
            elif kk == "tcomment":
                tcom.append(t)
            elif kk in ("comment", "directive"):
                out.append(t)
            elif kk == "blank":
                out.append("")
            j += 1
        body = out_ins[ad]
        if tcom:
            if body.find(";") < 0 and len(tcom) == 1:
                body = body + "\t" + tcom[0]
            else:
                for t in tcom:
                    out.append("\t" + t)
        out.append(body)
    while j < len(ci):
        cad, li, kk, t = ci[j]
        out.append(t + ":" if kk == "label" else t)
        j += 1
    for p in trailing:
        out.append(p[2] + ":" if p[1] == "label" else p[2])
    return out, rep


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True, help="path relative to the image mirror dir")
    ap.add_argument("--lines", action="append", default=[],
                    help="FROM:TO, 1-indexed inclusive; may repeat")
    ap.add_argument("--windows", help="JSON file: list of [FROM, TO] line pairs")
    ap.add_argument("--data", action="append", default=[], help="START:END hex, emitted as data")
    ap.add_argument("--allow-absurd", action="store_true")
    ap.add_argument("--skip-refused", action="store_true",
                    help="batch mode: leave a refused window untouched and continue")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--out")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    img = image(a.image)
    srcroot = os.path.join(ROOT, img["mirror"])
    path = os.path.join(srcroot, a.file)
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    wins = [tuple(int(x) for x in w.split(":")) for w in a.lines]
    if a.windows:
        wins += [tuple(w) for w in json.load(open(a.windows))]
    wins = sorted(set(wins))
    for (l1, h1), (l2, h2) in zip(wins, wins[1:]):
        if l2 <= h1:
            sys.exit("overlapping windows %d:%d and %d:%d" % (l1, h1, l2, h2))
    datar = [tuple(int(x, 16) for x in d.split(":")) for d in a.data]
    amap, syms, rom, ok = build_map(img, srcroot)
    if not ok:
        sys.exit("REFUSED: mirror of the current tree is not byte-identical to the dump")
    cache_ = {}
    results = []
    for lo, hi in wins:
        try:
            out, rep = render_window(img, rom, amap, syms, lines, a.file, lo - 1, hi - 1,
                                     datar, srcroot, cache_)
        except Refused as e:
            print("window %d:%d REFUSED: %s" % (lo, hi, e))
            if not a.skip_refused:
                sys.exit(1)
            continue
        blocked = [t for ad, t in rep["stranded"] if t in rep.get("ext", {})]
        why = []
        if rep["absurd"] and not a.allow_absurd:
            why.append("absurd decodes")
        if blocked:
            why.append("stranded labels referenced elsewhere: %s" % blocked)
        results.append((lo, hi, out, rep, why))
    json.dump(cache(), open(CACHE, "w"))
    tot = {"absurd": 0, "byted": 0, "unresolved": 0, "stranded": 0, "bytes": 0}
    for lo, hi, out, rep, why in results:
        for k in ("absurd", "byted", "unresolved", "stranded"):
            tot[k] += len(rep[k])
        tot["bytes"] += rep["B"] - rep["A"]
        if not a.quiet or why:
            print("window %s:%d-%d  %06X-%06X  %d B  %d insns  absurd=%d byte=%d unres=%d "
                  "stranded=%d mism=%d %s" % (a.file, lo, hi, rep["A"], rep["B"],
                                              rep["B"] - rep["A"], rep["n"], len(rep["absurd"]),
                                              len(rep["byted"]), len(rep["unresolved"]),
                                              len(rep["stranded"]), len(rep["mismatch"]),
                                              ("REFUSED: " + "; ".join(why)) if why else ""))
            if not a.quiet:
                for x in rep["absurd"][:20]:
                    print("   absurd %06X %s" % x)
                for x in rep["byted"][:20]:
                    print("   .byte  %06X %s" % x)
                for x in rep["mismatch"][:20]:
                    print("   mism   %06X unidasm=%s llvm=%s" % x)
                for x in rep["stranded"]:
                    print("   strand %06X %s ext=%s" % (x + (rep.get("ext", {}).get(x[1], []),)))
    print("TOTAL windows=%d bytes=%d absurd=%d byte-fallback=%d unresolved=%d stranded=%d" % (
        len(results), tot["bytes"], tot["absurd"], tot["byted"], tot["unresolved"], tot["stranded"]))
    if a.out:
        with open(a.out, "w", encoding="latin-1") as f:
            for lo, hi, out, rep, why in results:
                f.write("; ==== window %d:%d %06X-%06X %s\n" % (lo, hi, rep["A"], rep["B"],
                                                             "REFUSED" if why else ""))
                f.write("\n".join(out) + "\n")
    if a.apply:
        applied = [r for r in results if not r[4]]
        if len(applied) != len(results) and not a.skip_refused:
            sys.exit("REFUSED windows present; nothing applied (use --skip-refused)")
        new = list(lines)
        for lo, hi, out, rep, why in sorted(applied, key=lambda r: -r[0]):
            new[lo - 1:hi] = out
        open(path, "wb").write("\n".join(new).encode("latin-1"))
        amap2, syms2, rom2, ok2 = build_map(img, srcroot)
        if not ok2:
            open(path, "wb").write(raw)
            sys.exit("FAILED: re-linked image differs from the dump; file restored")
        print("APPLIED %d windows to %s; image byte-identical" % (len(applied), a.file))


if __name__ == "__main__":
    main()
