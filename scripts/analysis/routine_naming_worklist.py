#!/usr/bin/env python3
"""routine_naming_worklist.py -- which address-named routines (`sub_XXXXXX`) in a source file
can be named next, and what does each one touch?

QUESTION THIS ANSWERS
  A naming lane needs, per placeholder routine: where it is, how big, who calls it, what it
  calls, which RAM / I/O addresses and which named data it touches, and whatever header already
  says about it. It also needs an ORDER: a routine whose callees all have semantic names is far
  easier to name than one that only calls other placeholders, so naming proceeds in ROUNDS from
  the leaves up, each round seeing the names the previous one settled.

  This script builds that worklist from the source text alone (no build), for any file whose
  instruction lines carry the `; ADDRESS  bytes` comment the wsa1 sources use, and also for
  files without it (addresses are then left empty).

WHAT IT REPORTS (JSON, one record per placeholder routine)
  name, file, addr, lines (instruction count), callers / callees (labels, placeholders
  included), referenced_by (labels whose data -- `.long sub_X` tables -- or operands name it),
  data_refs (non-placeholder labels used as operands), mem_refs (numeric absolute addresses in
  operands, incl. the m_*_mi8/16 macros' address argument), header (the comment block above the
  label, first 600 chars), ready (true when every callee already has a semantic name), and
  slice (the partition index from --slices N, contiguous by address, balanced by routine count).

USAGE
  python3 scripts/analysis/routine_naming_worklist.py FILE.s [--placeholder REGEX]
        [--slices N] [--out OUT.json] [--summary]
  Default placeholder regex: ^(sub|Sub|SUB|loc|LABEL|Label|Unknown|Unk)_[0-9A-Fa-f]{4,8}$
"""
import argparse
import json
import re
import sys

LABEL = re.compile(r"^([A-Za-z_$][A-Za-z0-9_.$@]*):")
ADDRCMT = re.compile(r";\s*([0-9A-Fa-f]{6})\s{2}\S")
BRANCH = re.compile(r"^\s*(?:[A-Za-z_.$][\w.$@]*:)?\s*(call|calr|jp|jr|jrl|djnz)\s+(?:[a-z]+\s*,\s*)?([^;\s,]+)\s*(?:;|$)")
TOKEN = re.compile(r"(?<![\w.$@])([A-Za-z_$][A-Za-z0-9_.$@]*)(?![\w.$@(])")
NUM = re.compile(r"(?<![\w.$])0x([0-9a-fA-F]{3,8})\b")
REGS = set("""a b c d e h l w qa qw qb qc qd qe qh ql wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz
xsp qwa qbc qde qhl qix qiy qiz sr f pc z nz c nc ov nov mi pl eq ne lt le gt ge ult ule ugt uge t f
pe po nv v m p ra3 rw3 rwa3 rbc3 rde3 rhl3 xwa3 xbc3 xde3 xhl3 mb16 mb24 md16 md24 mw16 mw24""".split())


def parse(path, placeholder, routines=None, order=None):
    """Add `path`'s routines to `routines`/`order`. A column-0 label that extends the current
    routine's name with `_suffix` (structural sub-labels such as sub_F0001A_Join) belongs to
    that routine, not to a new one."""
    text = open(path, "rb").read().decode("latin-1").split("\n")
    routines = {} if routines is None else routines
    order = [] if order is None else order
    cur = None
    pending_comment = []
    for line in text:
        m = LABEL.match(line)
        if m and cur is not None and m.group(1).startswith(cur["name"] + "_"):
            pending_comment = []
            continue
        if m and not m.group(1).startswith(".L"):
            name = m.group(1)
            cur = {"name": name, "file": path, "addr": "", "lines": 0, "callees": set(), "data_refs": set(),
                   "mem_refs": set(), "header": "\n".join(pending_comment)[:600],
                   "is_placeholder": bool(placeholder.match(name))}
            routines[name] = cur
            order.append(name)
            pending_comment = []
            continue
        s = line.strip()
        if s.startswith(";"):
            pending_comment.append(s)
            continue
        if not s:
            continue
        pending_comment = []
        if cur is None:
            continue
        if s.startswith("."):          # data directive: its symbol operands are references too
            parts = s.split(";", 1)[0].split(None, 1)
            for tok in TOKEN.findall(parts[1] if len(parts) > 1 else ""):
                if not tok.startswith(".L"):
                    cur["data_refs"].add(tok)
            continue
        cur["lines"] += 1
        a = ADDRCMT.search(line)
        if a and not cur["addr"]:
            cur["addr"] = a.group(1).upper()
        code = line.split(";", 1)[0]
        b = BRANCH.match(code)
        if b and not b.group(2).startswith(".L"):
            tgt = b.group(2)
            if not tgt.startswith(cur["name"] + "_"):    # a branch to its own sub-label is internal
                cur["callees"].add(re.sub(r"_(Join|Loop|Return\d*|Skip\d*|Epilogue|Tail|Next|Done|Exit|End)$", "", tgt))
        else:
            for t in TOKEN.findall(code.split(None, 1)[1] if len(code.split(None, 1)) > 1 else ""):
                if t.lower() not in REGS and not t.startswith(".L"):
                    cur["data_refs"].add(t)
        for n in NUM.findall(code):
            v = int(n, 16)
            if v >= 0x100:
                cur["mem_refs"].add("0x%06x" % v)
    return routines, order


def main():
    ap = argparse.ArgumentParser(description="placeholder-routine naming worklist")
    ap.add_argument("file", help="the file whose placeholders to list")
    ap.add_argument("--also", nargs="*", default=[], help="other files to search for callers")
    ap.add_argument("--placeholder", default=r"^(sub|Sub|SUB|loc|LABEL|Label|Unknown|Unk)_[0-9A-Fa-f]{4,8}$")
    ap.add_argument("--slices", type=int, default=1)
    ap.add_argument("--out")
    ap.add_argument("--summary", action="store_true")
    a = ap.parse_args()
    ph = re.compile(a.placeholder)
    routines, order = parse(a.file, ph)
    mine = set(order)
    for other in a.also:
        if other != a.file:
            parse(other, ph, routines, [])
    callers, referrers = {}, {}
    for r in routines.values():
        for c in r["callees"]:
            callers.setdefault(c, set()).add(r["name"])
        for d in r["data_refs"]:
            referrers.setdefault(d, set()).add(r["name"])
    work = []
    for name in order:
        r = routines[name]
        if not r["is_placeholder"] or name not in mine:
            continue
        callees = sorted(r["callees"])
        ready = all(not ph.match(c) and not re.match(r"^0x|^\d", c) for c in callees)
        work.append({"name": name, "file": r["file"], "addr": r["addr"], "lines": r["lines"],
                     "callers": sorted(callers.get(name, ())), "callees": callees,
                     "referenced_by": sorted(referrers.get(name, set()) - callers.get(name, set()))[:20],
                     "data_refs": sorted(r["data_refs"] - set(callees))[:40],
                     "mem_refs": sorted(r["mem_refs"])[:40], "header": r["header"], "ready": ready})
    n = max(1, a.slices)
    per = -(-len(work) // n) if work else 0
    for i, w in enumerate(work):
        w["slice"] = i // per if per else 0
    if a.out:
        json.dump(work, open(a.out, "w"), indent=1)
    if a.summary or not a.out:
        nready = sum(w["ready"] for w in work)
        hdr = sum(bool(w["header"]) for w in work)
        uncalled = sum(not w["callers"] and not w["referenced_by"] for w in work)
        print("%s: %d placeholder routines (%d with a header, %d ready = all callees named, "
              "%d with no caller or reference in the scanned files)" % (a.file, len(work), hdr, nready, uncalled))
        for s in range(n):
            ws = [w for w in work if w["slice"] == s]
            if ws:
                print("  slice %d: %d routines %s..%s, %d ready" % (
                    s, len(ws), ws[0]["addr"], ws[-1]["addr"], sum(w["ready"] for w in ws)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
