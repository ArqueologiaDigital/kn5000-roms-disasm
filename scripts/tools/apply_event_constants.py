#!/usr/bin/env python3
"""apply_event_constants.py -- spell firmware event codes and class ids symbolically.

QUESTION THIS ANSWERS / WHY IT EXISTS
  On 2026-10-02 the v10 maincpu and HD-AE5000 sources used 702 distinct values in
  0x01000000..0x01FFFFFF as bare instruction operands, 8,837 times (`cp xbc, 0x1e10000`,
  `ld xbc, 0x1c00001`); only 26 had an `.equ` constant, and even those were mostly not used
  (2,299 occurrences of an already-named value were still numeric). CLAUDE.md "Event Code
  Freshness" wants EVT_* names. This tool takes a CATALOG (value -> name, meaning) and
    1. defines each missing constant in <tree>/shared/event_codes.s (one `.equ` per value,
       with the meaning as its comment), reusing an existing constant for a value that already
       has one (one name per value -- CLAUDE.md policy 5);
    2. replaces every instruction operand that IS that value (the whole operand, written in hex
       or decimal) with the name, in every .s file of the tree.
  It never touches: branch instructions, memory operands `(0x...)`, operands that are an
  expression (`0x1c00000 + 5`), comments, and -- unless --data -- data directives (.long etc.).
  A value outside 0x01000000..0x01FFFFFF is refused: the CPU's address space ends at 0xFFFFFF,
  so in that range a 32-bit operand cannot be an address, which is what makes the substitution
  safe; anything else in the catalog is a mistake.

CATALOG (JSON list): [{"value": "0x01C00001", "name": "EVT_MENU_OPEN", "meaning": "..."}]
  Entries with an empty name are skipped.

USAGE
  python3 scripts/tools/apply_event_constants.py CATALOG.json [--trees v10/maincpu,...]
         [--check] [--data] [--report OUT]
  Default trees: v10/maincpu v9/maincpu v7/maincpu hdae5000. Then: make gate-all (must be
  13/13 -- a symbol for the same value cannot move a byte).

EXIT STATUS: 0 ok, 1 refused (conflicts; nothing written), 2 usage.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
TREES = ["v10/maincpu", "v9/maincpu", "v7/maincpu", "hdae5000"]
EQU = re.compile(r"^\s*\.(?:equ|set)\s+([A-Za-z_][A-Za-z0-9_]*)\s*,\s*(0x[0-9a-fA-F]+|\d+)\b")
INSN = re.compile(r"^(\s*(?:[A-Za-z_.$][\w.$@]*:)?\s*)([a-z_][a-z0-9_]*)(\s+)([^;]*?)(\s*(?:;.*)?)$")
LIT = re.compile(r"^(?:0x[0-9a-fA-F]+|\d+)$")
BRANCH = {"jr", "jrl", "calr", "call", "jp", "djnz", "call_24", "jp_24"}
DATA = {".long", ".int", ".word", ".4byte"}
IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def read(p):
    return open(p, "rb").read().decode("latin-1")


def write(p, t):
    open(p, "wb").write(t.encode("latin-1"))


def split_operands(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return out


def substitute_line(line, by_value, data):
    m = INSN.match(line)
    if not m:
        return line, 0
    lead, mnem, sp, ops, tail = m.groups()
    if mnem in BRANCH:
        return line, 0
    parts = split_operands(ops)
    n = 0
    for i, op in enumerate(parts):
        core = op.strip()
        if LIT.match(core):
            v = int(core, 0)
            if v in by_value:
                parts[i] = op.replace(core, by_value[v])
                n += 1
    if not n:
        return line, 0
    return lead + mnem + sp + ",".join(parts) + tail, n


def substitute_data_line(line, by_value):
    m = re.match(r"^(\s*(?:[A-Za-z_.$][\w.$@]*:)?\s*)(\.\w+)(\s+)([^;]*?)(\s*(?:;.*)?)$", line)
    if not m or m.group(2) not in DATA:
        return line, 0
    lead, d, sp, ops, tail = m.groups()
    parts = split_operands(ops)
    n = 0
    for i, op in enumerate(parts):
        core = op.strip()
        if LIT.match(core) and int(core, 0) in by_value:
            parts[i] = op.replace(core, by_value[int(core, 0)])
            n += 1
    return (lead + d + sp + ",".join(parts) + tail, n) if n else (line, 0)


def main():
    ap = argparse.ArgumentParser(description="spell event codes / class ids symbolically")
    ap.add_argument("catalog")
    ap.add_argument("--trees", default=",".join(TREES))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--data", action="store_true", help="also substitute in .long/.word data")
    ap.add_argument("--report")
    a = ap.parse_args()
    cat = [e for e in json.load(open(a.catalog, encoding="utf-8")) if e.get("name")]
    errors, report = [], []
    for e in cat:
        v = int(e["value"], 0)
        if not 0x01000000 <= v < 0x02000000:
            errors.append("value %s outside 0x01000000..0x01FFFFFF" % e["value"])
        if not IDENT.match(e["name"]):
            errors.append("not an identifier: %r" % e["name"])
    names = [e["name"] for e in cat]
    vals = [int(e["value"], 0) for e in cat]
    for n in sorted({n for n in names if names.count(n) > 1}):
        errors.append("name %s given to two values" % n)
    for v in sorted({v for v in vals if vals.count(v) > 1}):
        errors.append("value 0x%08X given two names" % v)

    plans = {}
    for tree in a.trees.split(","):
        defs_path = os.path.join(REPO, tree, "shared", "event_codes.s")
        if not os.path.exists(defs_path):
            errors.append("%s has no shared/event_codes.s" % tree)
            continue
        files = sorted(glob.glob(os.path.join(REPO, tree, "**", "*.s"), recursive=True))
        val2name, name2val = {}, {}
        for f in files:
            for line in read(f).split("\n"):
                m = EQU.match(line)
                if m:
                    name2val.setdefault(m.group(1), int(m.group(2), 0))
                    if 0x01000000 <= int(m.group(2), 0) < 0x02000000:
                        val2name.setdefault(int(m.group(2), 0), m.group(1))
        tokens = set()
        for f in files:
            tokens.update(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", read(f)))
        by_value, new_defs = {}, []
        for e in cat:
            v, n = int(e["value"], 0), e["name"]
            if v in val2name:
                by_value[v] = val2name[v]
                if val2name[v] != n:
                    report.append("%s: 0x%08X keeps existing name %s (catalog said %s)" % (tree, v, val2name[v], n))
                continue
            if n in name2val or n in tokens:
                errors.append("%s: name %s already exists in the tree" % (tree, n))
                continue
            by_value[v] = n
            new_defs.append(".equ %s, 0x%x\t; %s" % (n, v, (e.get("meaning") or "").replace("\n", " ")[:110]))
        # also substitute values that already had a constant but were not in the catalog
        for v, n in val2name.items():
            by_value.setdefault(v, n)
        plans[tree] = (defs_path, files, by_value, new_defs)

    if errors:
        print("REFUSED -- nothing changed:", file=sys.stderr)
        for e in errors:
            print("  " + e, file=sys.stderr)
        return 1

    total = 0
    for tree, (defs_path, files, by_value, new_defs) in plans.items():
        count = 0
        for f in files:
            if f == defs_path:
                continue
            text = read(f)
            out, changed = [], 0
            for line in text.split("\n"):
                nl, n = substitute_line(line, by_value, a.data)
                if not n and a.data:
                    nl, n = substitute_data_line(line, by_value)
                out.append(nl)
                changed += n
            if changed:
                count += changed
                if not a.check:
                    write(f, "\n".join(out))
        if new_defs and not a.check:
            t = read(defs_path).rstrip("\n")
            t += ("\n\n; Named from the event-code catalog of 2026-10-02 "
                  "(notes/event-codes-2026-10-02/; evidence per value there)\n" + "\n".join(new_defs) + "\n")
            write(defs_path, t)
        report.append("%-12s %4d new constants, %5d operands substituted" % (tree, len(new_defs), count))
        total += count
    print("\n".join(r for r in report if not r.startswith(tuple(plans)) or "operands" in r))
    print("%s %d operand(s) across %d tree(s)%s" % ("would substitute" if a.check else "substituted",
                                                    total, len(plans), "" if a.check else "; now run make gate-all"))
    if a.report:
        open(a.report, "w", encoding="utf-8").write("\n".join(report) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
