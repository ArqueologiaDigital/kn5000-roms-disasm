#!/usr/bin/env python3
"""name_data_aliases.py -- a positional alias into DATA becomes a real label named after its reader.

QUESTION THIS ANSWERS / JOB IT DOES
  `.set NakaInst_NO_OPERATION_0x12, NakaInst_NO_OPERATION + 18` names a byte by its distance
  from whatever object happens to precede it -- often unrelated (a string before a widget
  table) -- and leaves the object boundary implicit.  The NAKA header convention names such
  data after the code that reads it (EffectBox_HandleInitEvent_Table, "read by
  EffectBox_HandleInitEvent").  For every positional alias (`<name>_0xHEX`) that CODE uses
  and whose address is DATA (the census marker mirror says which source line emits it):

    * the line already starts there with a label   -> the alias retires into that label;
    * the line starts there without one             -> the label is inserted in front of it;
    * the address is inside an `.incbin` slice       -> the slice is cut there;
    * inside a `.byte` / `.short` / `.long` list, on an element boundary -> the list is cut;
    * anything else (code, mid-element, macros)     -> reported, left alone.
  Placement is scripts/tools/place_labels.py's (also whole-file `.incbin`s, negative `.byte`
  items and one-string `.ascii` lines since 2026-10-03).
  The new label is `<Reader>_Str_<Text>` when the bytes there start a NUL-terminated ASCII
  string (split_blobs_at_far_pointers.c_string_at), else `<Reader>_Data`; Reader is the
  nearest non-structural label above the first code line that uses the alias.  The alias's
  `.set` goes and every use -- code and comments -- takes the label.  A label emits no byte:
  `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/name_data_aliases.py --tree v10 [--apply] [--report OUT]
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
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import split_blobs_at_far_pointers as sb      # noqa: E402
import symbolize_numeric_branches as snb      # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

SET = re.compile(r'^\s*\.set\s+(\w+_0x[0-9A-Fa-f]+)\s*,')
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')
INCBIN = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*)\.incbin\s+"(?P<f>[^"]+)"\s*,\s*(?P<o>0x[0-9a-fA-F]+|\d+)\s*,\s*(?P<n>0x[0-9a-fA-F]+|\d+)(?P<post>\s*(?:;.*)?)$')
LIST = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*)\.(?P<d>byte|short|hword|2byte|long|word|4byte)\s+(?P<items>[^;]*?)(?P<post>\s*(?:;.*)?)$')
SIZE = {"byte": 1, "short": 2, "hword": 2, "2byte": 2, "long": 4, "word": 4, "4byte": 4}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--names-from", help="another tree's --report: the same alias takes the same name")
    a = ap.parse_args()
    prefer = json.load(open(a.names_from))["retired"] if a.names_from else {}
    elf, tree, (lo, hi) = fp.IMAGES[a.tree]
    rom = open(os.path.join(REPO, sb.ROM[a.tree][0]), "rb").read()
    base = sb.ROM[a.tree][1]
    syms = fp.elf_symbols(elf)
    addr_of = {n: ad for ad, ns in syms.items() for n in ns}
    img = snb.image_by_key(a.tree)
    srcroot = os.path.join(REPO, img["mirror"])
    marks, addrs, spans, rom_ok, src, macros = snb.build_map(img, srcroot)
    if not rom_ok:
        sys.exit("marker mirror does not reproduce the dump: refusing")
    import bisect
    starts = [s[0] for s in spans]
    files = sorted(glob.glob(os.path.join(srcroot, "**", "*.s"), recursive=True))
    texts = {os.path.relpath(f, srcroot): open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    aliases = {}
    for rel, L in texts.items():
        for i, l in enumerate(L):
            m = SET.match(l)
            if m and m.group(1) in addr_of:
                aliases[m.group(1)] = (addr_of[m.group(1)], rel, i)
    taken = set(addr_of)
    for L in texts.values():
        for l in L:
            m = LABEL.match(l)
            if m:
                taken.add(m.group(1))
    # first code use of each alias, and its reader
    use = {}
    pat = re.compile(r'(?<![\w.$])(%s)(?![\w$])' % "|".join(map(re.escape, sorted(aliases, key=len, reverse=True))))
    for rel in sorted(texts):
        reader = None
        for i, l in enumerate(texts[rel]):
            m = LABEL.match(l)
            if m and not sb.STRUCTURAL.search(m.group(1)) and m.group(1) in addr_of \
                    and not m.group(1).startswith("__"):
                reader = m.group(1)
            code = l.split(";", 1)[0]
            if SET.match(l) or not code.strip():
                continue
            if snb.drc.classify_line(l, macros)[0] != "code":
                continue
            for mm in pat.finditer(code):
                n = mm.group(1)
                ent = (addr_of.get(reader, 1 << 30), reader)
                if reader and (n not in use or ent < use[n]):
                    use[n] = ent
    stats, rows = collections.Counter(), []
    sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
    import place_labels
    planner = place_labels.Planner(a.tree)
    retire = {}
    placed_at = {}
    for n, (v, arel, ai) in sorted(aliases.items(), key=lambda kv: kv[1][0]):
        if n not in use:
            stats["not-used-by-code"] += 1
            continue
        w = planner.where(v)
        if not w:
            continue
        sa, rel, li = w
        line = planner.lines(rel)[li]
        if snb.drc.classify_line(line, macros)[0] != "data":
            stats["code-target"] += 1
            continue
        if v in placed_at:
            retire[n] = placed_at[v]
            stats["same-place-as-another-alias"] += 1
            continue
        lab = LABEL.match(line)
        if v == sa and lab:
            retire[n] = lab.group(1)
            stats["retire-into-existing-label"] += 1
            rows.append({"alias": n, "result": "existing", "label": lab.group(1)})
            continue
        reader = use[n][1]
        s = sb.c_string_at(rom, base, v)
        good_str = s is not None and len(s) >= 2 and (v == sa or rom[v - base - 1] in (0, 0xff))
        stem = "%s_Str_%s" % (reader, sb.text_token(s)) if good_str else "%s_Data" % reader
        nm, kk = stem, 2
        if prefer.get(n) and prefer[n] not in taken:
            nm = prefer[n]
            stats["names-from-used"] += 1
        while nm in taken:
            nm, kk = "%s_%d" % (stem, kk), kk + 1
        how = planner.add(v, nm)
        if how in ("line-start", "incbin", "list", "ascii"):
            taken.add(nm)
            placed_at[v] = nm
            retire[n] = nm
            stats["new-label"] += 1
            rows.append({"alias": n, "result": "label", "label": nm, "kind": how, "at": "%s:%d" % (rel, li + 1)})
        else:
            stats["inside-a-line"] += 1
            rows.append({"alias": n, "result": "inside a line", "at": "%s:%d" % (rel, li + 1)})
    if a.apply and retire:
        planner.apply()
        texts = {rel: open(os.path.join(srcroot, rel), "rb").read().decode("latin-1").split("\n") for rel in texts}
        rp = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True))))
        for rel, L in texts.items():
            new = []
            for l in L:
                m = SET.match(l)
                if m and m.group(1) in retire:
                    continue
                new.append(rp.sub(lambda mm: retire[mm.group(1)], l) if rp.search(l) else l)
            texts[rel] = new
        for rel, L in texts.items():
            p = os.path.join(srcroot, rel)
            t = "\n".join(L)
            if t != open(p, "rb").read().decode("latin-1"):
                open(p, "wb").write(t.encode("latin-1"))
        for p in glob.glob(os.path.join(srcroot, "**", "*.c"), recursive=True) + \
                glob.glob(os.path.join(srcroot, "**", "*.h"), recursive=True):
            t = open(p, "rb").read().decode("latin-1")
            rpc = re.compile(r'(?<![\w$])(%s)(?![\w$])' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True))))
            t2 = rpc.sub(lambda mm: retire[mm.group(1)], t)        # C: `.member` designators too
            if t2 != t:
                open(p, "wb").write(t2.encode("latin-1"))
    print("%s: %s%s" % (a.tree, dict(stats), "" if a.apply else " (dry run)"))
    if a.report:
        json.dump({"rows": rows, "retired": retire}, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
