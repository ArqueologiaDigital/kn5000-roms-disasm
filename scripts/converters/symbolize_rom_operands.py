#!/usr/bin/env python3
r"""Replace NUMERIC ROM addresses in data pointers and instruction operands with labels.

QUESTION THIS ANSWERS / JOB IT DOES
-----------------------------------
scripts/converters/symbolize_numeric_branches.py made BRANCH operands symbolic.
The other half of CLAUDE.md's Symbolic Cross-Referencing policy is the DATA side:
a computed-goto table written as `.long 0x00FBC3EC`, a table base written as
`add xbc, 0xFBC5DC`, a string pointer loaded as `ld XIY,0x00fc1cc1`.  Each of
those is an address inside the same image, and each should name what it points
at.  This tool rewrites them, for one WSA1 image at a time.

    kind       example before                    after
    .long      .long 0x00FBC3EC                  .long sub_FBC39D__FBC3EC
    operand    add  xbc, 0xFBC5DC                add  xbc, sub_FBC39D_JumpTable
    mid        add  xiy, 0xFE1377                add  xiy, Table_FE1376+1

HOW (reuses symbolize_numeric_branches.build_map, the census's inert mirror)
  1. Every source line's address from the marker-label mirror, which is proven
     byte-identical to the dump before anything is trusted.
  2. Candidates, in the image's OWN files only (never wsa1/kernel/ or wsa1/dsp/,
     which two images share):
       * `.long` arguments that are hex literals in [image base, 0x1000000);
       * hex literals of at least six digits in the operands of ld / lda / add /
         cp / push (the forms an address takes here -- `and`/`or`/`xor`
         immediates are masks and are never touched).
  3. The target address v is classified against the EMITTING lines:
       line start, label there     -> that label (descriptive names preferred)
       line start of a DATA line   -> <nearest label above in that file>+off
       line start of a CODE line   -> a new label <routine>__<ADDR>, WSA1 house
                                      style, routine = nearest non-local label above
       inside a DATA line          -> <nearest label above>+off
       inside a CODE line          -> REFUSED (misframe evidence; reported)
       in a shared file / outside  -> REFUSED unless a label already sits there
  4. --apply rewrites latin-1 in, latin-1 out; --verify re-mirrors the modified
     tree and requires it byte-identical to the dump.  Because every rewritten
     token is an operand the assembler resolves, a label one byte off changes an
     emitted byte and the gate goes red.

RUN
    python3 scripts/converters/symbolize_rom_operands.py --image prom_c                 # dry run
    python3 scripts/converters/symbolize_rom_operands.py --image prom_c --apply --verify
    python3 scripts/converters/symbolize_rom_operands.py --image prom_c --report out.json
    --only prom_c/tone_db/tone_db_module.s,...   restrict the SITES (paths relative to wsa1/)
"""
import argparse
import bisect
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import symbolize_numeric_branches as SNB  # noqa: E402

drc = SNB.drc
SHARED = ("kernel/", "dsp/")
LONG_RE = re.compile(r'^(?P<pre>\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?\.long\s+)(?P<args>[^;]*?)(?P<post>\s*(?:;.*)?)$')
HEX_RE = re.compile(r'(?<![\w.$])0x([0-9A-Fa-f]{6,8})(?![\w])')
MNEM_OK = {"ld", "lda", "add", "cp", "push", "pushl", "ldl"}


def own(rel, img):
    return rel.startswith(SNB.own_prefix(img)) and not rel.startswith(SHARED)


def analyse(img, only=None):
    srcroot = os.path.join(ROOT, img["mirror"])
    marks, addrs, spans, rom_ok, src, macros = SNB.build_map(img, srcroot)
    assert rom_ok, "the mirror is not inert -- refusing"
    base, size = img["base"], img["size"]
    starts = [s[0] for s in spans]
    line_addr = {}
    labels_at = collections.defaultdict(list)
    for i, (rel, li) in enumerate(marks):
        if i not in addrs:
            continue
        a = addrs[i]
        line_addr[(rel, li)] = a
        for nm in SNB.labels_on(src.text(rel, li)):
            if not nm.startswith(drc.MARK):
                labels_at[a].append((nm, rel, li))

    def best_label(a):
        c = labels_at.get(a, [])
        if not c:
            return None
        return sorted(c, key=lambda x: (SNB.label_rank(x[0]), x[0]))[0][0]

    def span_of(v):
        k = bisect.bisect_right(starts, v) - 1
        if k < 0 or not (spans[k][0] <= v < spans[k][1]):
            return None
        return spans[k]

    def label_above(rel, li, local_ok=True):
        """Nearest label defined at or above line li of rel -> (name, addr)."""
        L = src.lines(rel)
        for j in range(li, -1, -1):
            for nm in reversed(SNB.labels_on(L[j])):
                if nm.startswith(drc.MARK):
                    continue
                if not local_ok and (nm.startswith(".L") or "__" in nm):
                    continue
                a = line_addr.get((rel, j))
                if a is not None:
                    return nm, a
        return None, None

    code_at = set()
    for (a, e, rel, li) in spans:
        if drc.classify_line(src.text(rel, li), macros)[0] == "code":
            code_at.add(a)

    def labels_code(a):
        """Does the label at address a sit on code?"""
        return a in code_at

    sites, plans, report = [], {}, collections.defaultdict(list)
    stats = collections.Counter()
    rels = sorted({rel for rel, _ in marks if own(rel, img)})
    for rel in rels:
        if only and rel not in only:
            continue
        for li, text in enumerate(src.lines(rel)):
            bk, _ = drc.classify_line(text, macros)
            code = drc.strip_comment(text)
            toks = []
            m = LONG_RE.match(text)
            if bk == "data" and m:
                args = m.group("args")
                for hm in HEX_RE.finditer(args):
                    toks.append((m.start("args") + hm.start(), m.start("args") + hm.end(),
                                 int(hm.group(1), 16), ".long"))
            elif bk == "code":
                body = SNB.code_of(text)
                mn = body.split()[0].lower() if body.split() else ""
                if mn in MNEM_OK:
                    for hm in HEX_RE.finditer(code):
                        toks.append((hm.start(), hm.end(), int(hm.group(1), 16), mn))
            for (s0, s1, v, kind) in toks:
                if not (base <= v < 0x1000000):
                    continue
                stats["candidates"] += 1
                sp = span_of(v)
                if sp is None:
                    stats["refused-outside"] += 1
                    report["outside"].append("%s:%d 0x%06X" % (rel, li + 1, v))
                    continue
                t_rel, t_li = sp[2], sp[3]
                t_bk, _ = drc.classify_line(src.text(t_rel, t_li), macros)
                lab = best_label(v)
                if lab:
                    name, why = lab, "label"
                elif sp[0] == v and t_bk == "code":
                    if not own(t_rel, img):
                        stats["refused-shared"] += 1
                        report["shared"].append("%s:%d 0x%06X" % (rel, li + 1, v))
                        continue
                    parent, _ = label_above(t_rel, t_li, local_ok=False)
                    name = "%s__%06X" % (parent or "L", v)
                    plans.setdefault(v, dict(rel=t_rel, li=t_li, name=name))
                    why = "new-code-label"
                elif t_bk == "data":
                    pl, pa = label_above(t_rel, t_li)
                    if pl is None or (not own(t_rel, img) and pa != v):
                        stats["refused-nolabel"] += 1
                        continue
                    if pa != v and sp[0] == v and labels_code(pa) and own(t_rel, img):
                        # a data object glued to the code above it, with no label of
                        # its own: give it one rather than naming it code+offset
                        parent, _ = label_above(t_rel, t_li, local_ok=False)
                        is_long = src.text(t_rel, t_li).strip().startswith(".long")
                        name = "%s_%s_%06X" % (parent or "L", "JumpTable" if is_long else "Data", v)
                        plans.setdefault(v, dict(rel=t_rel, li=t_li, name=name))
                        why = "new-data-label"
                    else:
                        name = pl if pa == v else "%s+%d" % (pl, v - pa)
                        why = "data-offset" if pa != v else "label"
                else:
                    stats["refused-midcode"] += 1
                    report["mid-code"].append("%s:%d 0x%06X -> %s:%d" % (rel, li + 1, v, t_rel, t_li + 1))
                    continue
                stats["converted-" + why] += 1
                stats["kind-" + kind] += 1
                sites.append(dict(rel=rel, li=li, s0=s0, s1=s1, v=v, name=name))
    # uniqueness of new names
    taken = set()
    for rel in {r for r, _ in marks}:
        for ln in src.lines(rel):
            taken.update(SNB.labels_on(ln))
    for v, p in plans.items():
        assert p["name"] not in taken, "label clash: " + p["name"]
        taken.add(p["name"])
    return dict(img=img, srcroot=srcroot, src=src, sites=sites, plans=plans,
                stats=stats, report=report)


def apply(res):
    src = res["src"]
    edits = collections.defaultdict(lambda: collections.defaultdict(list))
    for s in res["sites"]:
        edits[s["rel"]][s["li"]].append(s)
    inserts = collections.defaultdict(lambda: collections.defaultdict(list))
    for v, p in res["plans"].items():
        inserts[p["rel"]][p["li"]].append(p["name"])
    files = set(edits) | set(inserts)
    for rel in sorted(files):
        path = os.path.join(res["srcroot"], rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        assert lines == src.lines(rel), "source changed under us: " + rel
        out = []
        for li, ln in enumerate(lines):
            for nm in inserts[rel].get(li, []):
                out.append("%s:" % nm)
            for s in sorted(edits[rel].get(li, []), key=lambda s: -s["s0"]):
                ln = ln[:s["s0"]] + s["name"] + ln[s["s1"]:]
            out.append(ln)
        open(path, "wb").write("\n".join(out).encode("latin-1"))
    return len(res["sites"]), len(res["plans"]), len(files)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--only")
    a = ap.parse_args()
    img = SNB.image_by_key(a.image)
    assert img["mirror"] == "wsa1", "WSA1 images only (the only ones this was checked on)"
    res = analyse(img, set(a.only.split(",")) if a.only else None)
    print("image %s" % img["key"])
    for k in sorted(res["stats"]):
        print("  %-28s %7d" % (k, res["stats"][k]))
    print("  %-28s %7d" % ("NEW LABELS", len(res["plans"])))
    if a.report:
        json.dump(dict(stats=res["stats"], report=res["report"],
                       new=sorted(("0x%06X" % v, p["name"], "%s:%d" % (p["rel"], p["li"] + 1))
                                  for v, p in res["plans"].items()),
                       sites=[("%s:%d" % (x["rel"], x["li"] + 1), "0x%06X" % x["v"], x["name"])
                              for x in res["sites"]]),
                  open(a.report, "w"), indent=1)
        print("wrote", a.report)
    if a.apply:
        n, nl, nf = apply(res)
        print("APPLIED: %d operands rewritten, %d labels inserted, %d files" % (n, nl, nf))
        if a.verify:
            ok = SNB.verify(img)
            print("VERIFY (re-mirrored modified tree == dump):", "PASS" if ok else "FAIL")
            if not ok:
                sys.exit(1)


if __name__ == "__main__":
    main()
