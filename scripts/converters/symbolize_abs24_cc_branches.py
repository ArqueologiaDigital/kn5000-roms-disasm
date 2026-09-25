#!/usr/bin/env python3
r"""symbolize_abs24_cc_branches.py -- symbolise `jp/call cc, (N:24)` in hdae5000.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
scripts/converters/symbolize_numeric_branches.py converts numeric jr/jrl/calr
and plain call/jp operands, but its regex does not accept the 24-bit memory
spelling `jp z, (2708340:24)` / `call nz, (0x2974B5:24)` and it skips every
conditional absolute branch on purpose ("skip_conditional_abs").  In the
HD-AE5000 sources that left 384 numeric control transfers -- the
`F2 <addr24> Dx/Ex` encodings -- none of them counted by its report.  This
tool converts exactly that form, for the hdae5000 image only.

GUARDS (every one must pass, or the site stays numeric and is reported)
  G1 ENCODING  the ROM bytes at the site are F2 <target, 24-bit LE> <op> with
               op = 0xD0|cc (jp) or 0xE0|cc (call), i.e. the source line really
               is this instruction at this address, pointing where it says.
  G2 SECOND DECODER  MAME unidasm (original_ROMs/hd-ae5000_v2_06i.ic4.unidasm,
               a linear sweep) sees an instruction start at the site with the
               same mnemonic and the same absolute target.
  G3 TARGET    some hdae5000 source line begins EXACTLY at the target and
               that line is an instruction (not data) -- a branch into the
               middle of a line, or into data, is misframe evidence, not a
               label site.
LABELS
  An existing label at the target is reused (a global name beats a `.L` one).
  Otherwise a new one is made: for `jp cc` a file-local `.L<Parent>_<Role><k>`
  (Parent = the nearest global label above the target that is not a
  structural _Join/_Skip/_Loop/_Return/_Epilogue label, minus `HDAE5000_`;
  Role = Return if the target is ret/reti/retd, Loop if the branch goes
  backwards, else Skip), for `call cc` a global `<Parent>_Sub<k>`.  These are
  structural names; they replace a number.

RUN (from the repo root, after any build of the hdae5000 image)
    python3 scripts/converters/symbolize_abs24_cc_branches.py            # dry run
    python3 scripts/converters/symbolize_abs24_cc_branches.py --apply    # rewrite
The --apply run re-links the modified tree through
scripts/analysis/hdae5000_line_map.py, which refuses unless the mirror is
byte-identical to the dump; follow it with `make gate`.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

BASE = 0x280000
UNIDASM = os.path.join(ROOT, "original_ROMs", "hd-ae5000_v2_06i.ic4.unidasm")
SITE = re.compile(r'^(?P<pre>\s*(?:[A-Za-z_.$][\w.$]*:\s*)?)(?P<mn>jp|call)(?P<ws>\s+)'
                  r'(?:(?P<cc>[a-z/]+)\s*,\s*)?\(\s*(?P<num>0x[0-9a-fA-F]+|\d+)\s*:24\s*\)')
LABEL = re.compile(r'^\s*([A-Za-z_.$][\w.$]*):')
CC = {"f": 0, "lt": 1, "le": 2, "ule": 3, "ov": 4, "pe": 4, "mi": 5, "z": 6, "eq": 6,
      "c": 7, "ult": 7, "t": 8, "": 8, "ge": 9, "gt": 10, "ugt": 11, "nov": 12, "po": 12,
      "pl": 13, "nz": 14, "ne": 14, "nc": 15, "uge": 15}
# labels the branch symboliser planted inside routines: never a parent name
STRUCT = re.compile(r'_(Join|Skip|Loop|Return|Epilogue)\d*$')
UNI = re.compile(r'^([0-9a-f]+):\s+(?:[0-9a-f]{2}\s)+\s*(\S+)\s*(.*)$')


def unidasm():
    out = {}
    for ln in open(UNIDASM, encoding="latin-1"):
        m = UNI.match(ln)
        if m:
            out[int(m.group(1), 16)] = (m.group(2).lower(), m.group(3).strip())
    return out


def is_code(text):
    c = text.split(";", 1)[0].strip()
    while True:
        m = LABEL.match(c)
        if not m:
            break
        c = c[m.end():].strip()
    return bool(c) and not c.startswith(".")


def main(apply):
    rows, rom = hlm.build_map()
    uni = unidasm()
    lines = {rel: open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n")
             for rel in hlm.FILES}
    at = collections.defaultdict(list)
    for a, rel, n, t in rows:
        at[a].append((rel, n, t))
    # every label and its address; the nearest global label above any line
    labels_at = collections.defaultdict(list)
    for a, rel, n, t in rows:
        m = LABEL.match(t)
        if m:
            labels_at[a].append(m.group(1))
    defined = {nm for L in labels_at.values() for nm in L}
    stats, sites = collections.Counter(), []
    for a, rel, n, t in rows:
        m = SITE.match(t)
        if not m:
            continue
        stats["sites"] += 1
        tgt = int(m.group("num"), 0)
        cc = (m.group("cc") or "").lower()
        mn = m.group("mn")
        b = rom[a - BASE:a - BASE + 5]
        op = (0xD0 if mn == "jp" else 0xE0) | CC.get(cc.split("/")[0], 99)
        if len(b) < 5 or b[0] != 0xF2 or int.from_bytes(b[1:4], "little") != tgt or b[4] != op:
            stats["refuse_G1_encoding"] += 1
            continue
        u = uni.get(a)
        if not u or u[0] != mn or int(u[1].split(",")[-1], 16) != tgt:
            stats["refuse_G2_unidasm"] += 1
            continue
        tl = [x for x in at.get(tgt, []) if not LABEL.match(x[2]) or is_code(x[2])]
        code = [x for x in at.get(tgt, []) if is_code(x[2])]
        if not code:
            stats["refuse_G3_target_not_instruction_start"] += 1
            continue
        sites.append(dict(addr=a, rel=rel, n=n, mn=mn, cc=cc, tgt=tgt, m=m, code=code[0]))
    # choose labels
    new_labels = {}          # tgt -> (name, rel, line_no_of_first_code_line)
    counters = collections.Counter()
    for s in sorted(sites, key=lambda s: s["tgt"]):
        tgt = s["tgt"]
        ex = labels_at.get(tgt, [])
        if ex:
            ex.sort(key=lambda nm: (nm.startswith(".L"), nm))
            s["label"] = ex[0]
            stats["reuse_" + ("local" if ex[0].startswith(".L") else "global")] += 1
            continue
        if tgt in new_labels:
            s["label"] = new_labels[tgt][0]
            continue
        rel, n, t = s["code"]
        parent = None
        for k in range(n - 1, 0, -1):
            mm = LABEL.match(lines[rel][k - 1])
            if mm and not mm.group(1).startswith(".") and not mm.group(1).startswith("__") \
                    and not STRUCT.search(mm.group(1)):
                parent = mm.group(1)
                break
        parent = parent or "HDAE5000_" + rel.split(".")[0]
        c = t.split(";", 1)[0].strip().split()
        if s["mn"] == "call":
            role, stem = "Sub", parent
        else:
            role = "Return" if c and c[0] in ("ret", "reti", "retd") else \
                   ("Loop" if tgt < s["addr"] else "Skip")
            stem = ".L" + parent.replace("HDAE5000_", "", 1)
        while True:
            counters[(stem, role)] += 1
            name = "%s_%s%d" % (stem, role, counters[(stem, role)])
            if name not in defined:
                break
        defined.add(name)
        new_labels[tgt] = (name, rel, n)
        s["label"] = name
        stats["new_" + ("local" if name.startswith(".L") else "global")] += 1
    stats["converted"] = len(sites)
    for k in sorted(stats):
        print("  %-42s %5d" % (k, stats[k]))
    if not apply:
        return
    edits = collections.defaultdict(dict)     # rel -> {line_no: new_text}
    inserts = collections.defaultdict(list)   # rel -> [(line_no, label)]
    for s in sites:
        L = lines[s["rel"]]
        old = L[s["n"] - 1]
        m = SITE.match(old)
        assert m and int(m.group("num"), 0) == s["tgt"], (s["rel"], s["n"], old)
        L[s["n"] - 1] = old[:m.start("num")] + s["label"] + old[m.end("num"):]
    for tgt, (name, rel, n) in new_labels.items():
        inserts[rel].append((n, name))
    for rel, ins in inserts.items():
        for n, name in sorted(ins, reverse=True):
            lines[rel].insert(n - 1, name + ":")
    for rel in hlm.FILES:
        p = os.path.join(hlm.HDAE, rel)
        new = "\n".join(lines[rel])
        if new != open(p, encoding="latin-1").read():
            open(p, "w", encoding="latin-1").write(new)
    hlm.build_map()          # refuses unless the modified tree is byte-identical
    print("applied: %d operands, %d new labels; relinked mirror byte-identical"
          % (len(sites), len(new_labels)))


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
