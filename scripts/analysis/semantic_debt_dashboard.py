#!/usr/bin/env python3
"""semantic_debt_dashboard.py -- how much semantic debt that the byte gate and the data census
cannot see is left in each source tree, at a git revision?

QUESTION THIS ANSWERS
  The goal is a *fully semantic* disassembly. `data_range_census.py` grades bytes
  (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER) but cannot see several kinds of debt that live in
  the TEXT of the sources. This script counts them per tree, reading git blobs (never the work
  tree or the build), so it is safe to run while a build is in progress and can be run at any
  past revision to draw a trend.

COLUMNS (each is a count of source lines or tokens; lower is better)
  numbr    branch/call operands that are numbers, not labels (`jr z, 17`, `call 0xe12345`).
           Same regex as technics-docs tools/branch_operand_counts.py.
  addrlbl  label DEFINITIONS whose name is an address placeholder: `LABEL_E04FB9:`,
           `sub_E04FB9:`, `loc_...`, `Unknown_...`, `Unk_...`, `Data_E04FB9:`, `Label_...`,
           i.e. a name that says "I am at this address" rather than what the thing is.
           Positional sub-labels of a named parent (`Foo_0x32D`, `Foo_Loop`) are NOT counted.
  bytecmt  `.byte` lines whose comment carries an instruction reading (`; ld a, (xwa)`,
           `; MAME: ...`) -- code still held as bytes. An upper bound: some are data annotated
           with a decode on purpose.
  field    `field_XXXX` / `unk_XXXX` / `pad_XXXX` member names in C sources (*.c, *.h):
           structures that compile byte-exact but whose members have no meaning yet.
  todo     comment markers that admit a gap: TODO, FIXME, "unknown", "purpose unknown", "???".

USAGE
  python3 scripts/analysis/semantic_debt_dashboard.py [REV] [--trees v10,v9,...] [--csv]
  REV defaults to HEAD. Example trend: run at 3958235e (before Wave 2), 5fc8d5bd (after).
"""
import argparse
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."

TREES = {
    "v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu",
    "v142": "v142/subcpu", "subboot": "subcpu/boot", "tabledata": "table_data",
    "customdata": "custom_data", "hdae5000": "hdae5000",
    "prom_a": "wsa1/prom_a", "prom_b": "wsa1/prom_b", "prom_c": "wsa1/prom_c",
    "prom_d": "wsa1/prom_d",
}

NUMBR = re.compile(rb'^\s*(\S+:)?\s*(jr|jrl|calr|call|jp|djnz)\s+([a-z]+,\s*)?(-?[0-9]+|0x[0-9a-fA-F]+)\s*(;.*)?$', re.M)
ADDRLBL = re.compile(rb'^(?:LABEL|Label|label|sub|SUB|loc|LOC|Unknown|UNKNOWN|Unk|UNK|unk|Data|DATA|data|byte|word|off|Sub|Loc)_(?:0x)?[0-9A-Fa-f]{4,8}:', re.M)
BYTECMT = re.compile(rb'^\s*(\S+:)?\s*\.byte\b[^;\n]*;\s*(?:MAME:|unidasm:|=\s*)?\s*(ld|lda|ldw|ldb|push|pop|call|calr|jp|jr|jrl|ret|reti|add|sub|and|or|xor|cp|inc|dec|bit|set|res|tset|ex|mul|div|sll|srl|sla|sra|rlc|rrc|rl|rr|ldir|lddr|ldi|ldd|swi|ei|nop|halt|link|unlk|djnz|scc|neg|cpl|extz|exts|mirr|paa|incf|decf|ldf|ldc|ldx)\b', re.M | re.I)
FIELD = re.compile(rb'\b(?:field|unk|unknown|pad)_(?:0x)?[0-9A-Fa-f]{2,6}\b')
TODO = re.compile(rb'(?:;|//|/\*|#).*?(?:\bTODO\b|\bFIXME\b|\bunknown\b|\bpurpose unknown\b|\?\?\?)', re.I)

SRC_EXT = (".s", ".S", ".inc")
C_EXT = (".c", ".h")


def blobs(rev, path):
    """Yield (name, bytes) for every source file under `path` at `rev`, via one cat-file process."""
    names = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "--name-only", rev, "--", path],
                           capture_output=True, text=True, check=True).stdout.split("\n")
    names = [n for n in names if n.endswith(SRC_EXT + C_EXT)]
    if not names:
        return
    p = subprocess.Popen(["git", "-C", REPO, "cat-file", "--batch"], stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE)
    for n in names:
        p.stdin.write(("%s:%s\n" % (rev, n)).encode())
        p.stdin.flush()
        hdr = p.stdout.readline().split()
        size = int(hdr[2])
        data = p.stdout.read(size)
        p.stdout.read(1)
        yield n, data
    p.stdin.close()
    p.wait()


def measure(rev, path):
    c = dict(numbr=0, addrlbl=0, bytecmt=0, field=0, todo=0, files=0)
    for name, data in blobs(rev, path):
        c["files"] += 1
        if name.endswith(C_EXT):
            c["field"] += len(set(FIELD.findall(data))) if False else len(FIELD.findall(data))
            c["todo"] += len(TODO.findall(data))
            continue
        c["numbr"] += len(NUMBR.findall(data))
        c["addrlbl"] += len(ADDRLBL.findall(data))
        c["bytecmt"] += len(BYTECMT.findall(data))
        c["todo"] += len(TODO.findall(data))
    return c


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("rev", nargs="?", default="HEAD")
    ap.add_argument("--trees", default=",".join(TREES))
    ap.add_argument("--csv", action="store_true")
    a = ap.parse_args()
    short = subprocess.run(["git", "-C", REPO, "rev-parse", "--short", a.rev],
                           capture_output=True, text=True, check=True).stdout.strip()
    cols = ["files", "numbr", "addrlbl", "bytecmt", "field", "todo"]
    tot = dict.fromkeys(cols, 0)
    rows = []
    for t in a.trees.split(","):
        c = measure(a.rev, TREES[t])
        rows.append((t, c))
        for k in cols:
            tot[k] += c[k]
    if a.csv:
        print("rev,tree," + ",".join(cols))
        for t, c in rows + [("TOTAL", tot)]:
            print("%s,%s,%s" % (short, t, ",".join(str(c[k]) for k in cols)))
        return
    print("semantic debt at %s (lower is better; see the docstring for each column)" % short)
    print("%-11s" % "tree" + "".join("%9s" % k for k in cols))
    for t, c in rows + [("TOTAL", tot)]:
        print("%-11s" % t + "".join("%9d" % c[k] for k in cols))


if __name__ == "__main__":
    sys.exit(main())
