#!/usr/bin/env python3
"""place_labels.py -- put named labels at ROM addresses of a tree, wherever the source line allows.

JOB IT DOES (a library; scripts/tools/label_naka_records.py is its first user)
  Given {address: name}, find for each address the source line that emits it (the census
  marker mirror, symbolize_numeric_branches.build_map, refused unless it reproduces the dump)
  and:
    * the line starts exactly there            -> `NAME:` goes on its own line in front of it;
    * the address is inside an `.incbin` slice -> the slice is cut there, the new piece takes
      `NAME:` (same-line form, the house style for slices);
    * inside a `.byte`/`.short`/`.long` list, on an element boundary, every element a plain
      number or symbol -> the list is cut there likewise;
    * anything else (inside an instruction, mid-element, inside a macro) -> reported, left.
  A label emits no byte: the caller runs `make gate-all`.

  plan(tree)            -> Planner;  Planner.add(addr, name) -> "line-start" | "incbin" | "list" |
                           "inside a line" | "duplicate";  Planner.apply() writes the files
                           (latin-1 in, latin-1 out).
"""
import bisect
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import symbolize_numeric_branches as snb      # noqa: E402

LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')
INCBIN = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*)\.incbin\s+"(?P<f>[^"]+)"\s*,\s*(?P<o>0x[0-9a-fA-F]+|\d+)\s*,\s*(?P<n>0x[0-9a-fA-F]+|\d+)(?P<post>\s*(?:;.*)?)$')
LIST = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*)\.(?P<d>byte|short|hword|2byte|long|word|4byte)\s+(?P<items>[^;]*?)(?P<post>\s*(?:;.*)?)$')
SIZE = {"byte": 1, "short": 2, "hword": 2, "2byte": 2, "long": 4, "word": 4, "4byte": 4}
ITEM = re.compile(r'^(0x[0-9a-fA-F]+|\d+|[A-Za-z_][\w.$]*)$')
LABINC = re.compile(r'^([A-Za-z_][\w.$]*):[ \t]*(\.incbin\s.*)$')


class Planner:
    def __init__(self, tree):
        self.img = snb.image_by_key(tree)
        self.srcroot = os.path.join(REPO, self.img["mirror"])
        marks, addrs, self.spans, rom_ok, self.src, self.macros = snb.build_map(self.img, self.srcroot)
        if not rom_ok:
            sys.exit("%s: marker mirror does not reproduce the dump: refusing" % tree)
        self.starts = [s[0] for s in self.spans]
        self.texts = {}
        self.plan = {}                         # (rel, li) -> [(kind, offset, name)]
        self.names = {}

    def lines(self, rel):
        if rel not in self.texts:
            self.texts[rel] = open(os.path.join(self.srcroot, rel), "rb").read().decode("latin-1").split("\n")
        return self.texts[rel]

    def where(self, addr):
        k = bisect.bisect_right(self.starts, addr) - 1
        if k < 0:
            return None
        sa, se, rel, li = self.spans[k]
        return (sa, rel, li) if addr < se else None

    def add(self, addr, name):
        w = self.where(addr)
        if not w:
            return "inside a line"
        sa, rel, li = w
        line = self.lines(rel)[li]
        off = addr - sa
        kind = None
        if off == 0:
            kind = ("insert", 0)
        else:
            mi, ml = INCBIN.match(line), LIST.match(line)
            if mi and 0 < off < int(mi.group("n"), 0):
                kind = ("incbin", off)
            elif ml:
                sz = SIZE[ml.group("d")]
                items = [x.strip() for x in ml.group("items").split(",")]
                if off % sz == 0 and 0 < off // sz < len(items) and all(ITEM.match(x) for x in items):
                    kind = ("list", off // sz)
        if not kind:
            return "inside a line"
        items = self.plan.setdefault((rel, li), [])
        if any(x[0] == kind[0] and x[1] == kind[1] for x in items):
            return "duplicate"
        items.append((kind[0], kind[1], name))
        self.names[addr] = name
        return {"insert": "line-start", "incbin": "incbin", "list": "list"}[kind[0]]

    def apply(self):
        for (rel, li), items in sorted(self.plan.items(), key=lambda kv: (kv[0][0], -kv[0][1])):
            L = self.lines(rel)
            line = L[li]
            ins = [x for x in items if x[0] == "insert"]
            cuts = sorted([x for x in items if x[0] != "insert"], key=lambda x: x[1])
            out = [line]
            if cuts and cuts[0][0] == "incbin":
                mi = INCBIN.match(line)
                o0, n0 = int(mi.group("o"), 0), int(mi.group("n"), 0)
                b = [0] + [c[1] for c in cuts] + [n0]
                out = ['%s.incbin "%s", 0x%X, 0x%X%s' % (mi.group("pre") if j == 0 else "%s:\t" % cuts[j - 1][2],
                                                         mi.group("f"), o0 + b[j], b[j + 1] - b[j],
                                                         mi.group("post") if j == 0 else "")
                       for j in range(len(b) - 1)]
            elif cuts:
                ml = LIST.match(line)
                its = [x.strip() for x in ml.group("items").split(",")]
                b = [0] + [c[1] for c in cuts] + [len(its)]
                out = ["%s.%s\t%s%s" % (ml.group("pre") if j == 0 else "%s:\t" % cuts[j - 1][2], ml.group("d"),
                                         ", ".join(its[b[j]:b[j + 1]]), ml.group("post") if j == 0 else "")
                       for j in range(len(b) - 1)]
            for x in ins:
                if re.match(r'^\s+\.incbin\s', out[0]):
                    out[0] = "%s:\t%s" % (x[2], out[0].strip())      # same-line form for slices
                else:
                    out[0:0] = ["%s:" % x[2]]
            L[li:li + 1] = out
        self.plan = {}
        self.write()

    def align(self, L):
        """CLAUDE.md Label+Include alignment: a run of consecutive `Label: .incbin` lines that
        holds a label placed here is tab-aligned to the tab stop after its longest label."""
        new = set(self.names.values())
        i = 0
        while i < len(L):
            j = i
            while j < len(L) and LABINC.match(L[j]):
                j += 1
            if j > i and any(LABINC.match(L[k]).group(1) in new for k in range(i, j)):
                col = (max(len(LABINC.match(L[k]).group(1)) + 1 for k in range(i, j)) // 8 + 1) * 8
                for k in range(i, j):
                    mm = LABINC.match(L[k])
                    w = len(mm.group(1)) + 1
                    L[k] = "%s:%s%s" % (mm.group(1), "\t" * ((col - w + 7) // 8), mm.group(2))
            i = max(j, i + 1)

    def write(self):
        for rel, L in self.texts.items():
            self.align(L)
            p = os.path.join(self.srcroot, rel)
            t = "\n".join(L)
            if t != open(p, "rb").read().decode("latin-1"):
                open(p, "wb").write(t.encode("latin-1"))
