#!/usr/bin/env python3
r"""Carry the trailing comments of re-framed `.byte` lines onto the new instructions.

QUESTION ANSWERED
    A re-framing pass (scripts/analysis/v10_reframe_code_runs.py and its
    wrappers) replaces `.byte` lines with instructions and keeps comment-only
    lines, but drops the comment that TRAILS a replaced `.byte` line -- which in
    v7 often says what the bytes do ("CP_Flags_B.0 = 1", "disable CPanel serial
    clk", the v10 spelling of a patched instruction).  For every such comment
    this script finds the address of the old `.byte` line (old line map), the
    new source line that starts at that same address (new line map), and
    appends the comment there verbatim.  A comment whose address is not the
    start of a new line is attached to the line that contains the address,
    prefixed "(at +N)" with N the byte offset -- and reported.

    Comments listed in --drop (exact text after the first ';') are not carried;
    use it only for notes the re-frame itself proves false, e.g. "llvm-mc cannot
    spell this byte" on bytes that now assemble.

RUN
    python3 scripts/analysis/v10_line_address_map.py --image v7 FILES --out old.json   # before
    ... re-frame ...
    python3 scripts/analysis/v10_line_address_map.py --image v7 FILES --out new.json   # after
    python3 scripts/tools/carry_trailing_comments.py --base HEAD --old old.json --new new.json \
        [--drop "llvm-mc cannot spell this byte"] FILES
    make gate      # comments change no byte; the gate proves nothing else moved
"""
import argparse
import bisect
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def split_comment(line):
    """-> (code, comment) with the comment starting at the first ';' outside quotes."""
    q = False
    for i, ch in enumerate(line):
        if ch == '"':
            q = not q
        elif ch == ";" and not q:
            return line[:i], line[i:]
    return line, ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("--old", required=True)
    ap.add_argument("--new", required=True)
    ap.add_argument("--drop", action="append", default=[])
    ap.add_argument("files", nargs="+")
    a = ap.parse_args()
    old_map, new_map = json.load(open(a.old)), json.load(open(a.new))
    drop = {d.strip() for d in a.drop}
    total = moved = dropped = inexact = 0
    for rel in a.files:
        old = subprocess.run(["git", "show", "%s:%s" % (a.base, rel)], cwd=ROOT, capture_output=True,
                             check=True).stdout.decode("latin-1").split("\n")
        path = os.path.join(ROOT, rel)
        new = open(path, "rb").read().decode("latin-1").split("\n")
        olm = {int(k): v for k, v in old_map[rel].items()}
        nlm = {int(k): v for k, v in new_map[rel].items()}
        new_comments = {split_comment(l)[1].strip() for l in new if split_comment(l)[1]}
        # new instruction/data lines by address
        starts = {}
        for ln in sorted(nlm):
            t = new[ln - 1].strip()
            if t and not t.startswith(";") and not t.endswith(":") and not t.startswith(".set"):
                starts.setdefault(nlm[ln], ln)
        addrs = sorted(starts)
        adds = {}
        for ln, text in enumerate(old, 1):
            code, com = split_comment(text)
            if not com or not code.strip().startswith(".byte"):
                continue
            c = com.strip()
            if c in new_comments:
                continue
            total += 1
            body = c[1:].strip()
            if body in drop:
                dropped += 1
                continue
            addr = olm.get(ln)
            if addr is None:
                print("  %s:%d no old address for: %s" % (rel, ln, c))
                continue
            if addr in starts:
                adds.setdefault(starts[addr], []).append(c)
            else:
                k = bisect.bisect_right(addrs, addr) - 1
                if k < 0:
                    print("  %s:%d no new line at or before 0x%06X: %s" % (rel, ln, addr, c))
                    continue
                adds.setdefault(starts[addrs[k]], []).append("; (at +%d) %s" % (addr - addrs[k], c[1:].strip()))
                inexact += 1
                print("  %s: comment of old line %d lands %d bytes into new line %d"
                      % (rel, ln, addr - addrs[k], starts[addrs[k]]))
        for nl, cs in adds.items():
            code, com = split_comment(new[nl - 1])
            new[nl - 1] = new[nl - 1].rstrip() + "\t" + "  ".join(cs)
            moved += len(cs)
        open(path, "wb").write("\n".join(new).encode("latin-1"))
    print("trailing comments of replaced .byte lines: %d; carried %d (%d not at an instruction start),"
          " dropped as listed %d" % (total, moved, inexact, dropped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
