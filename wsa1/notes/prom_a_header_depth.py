#!/usr/bin/env python3
"""Which prom_a routine headers are INCOMPLETE, field by field?

QUESTION IT ANSWERS
    The brief for every wave says each routine gets a header with
    Name / Called from / Inputs / Outputs / Evidence / Unknown.  The byte gate
    cannot see a header at all, and the round-1 audit of wave 5 (finding F5)
    caught a report claiming "53 with a full ... header" when 17 were full.
    This prints the truth for ANY label prefix, so a round can quote a number it
    measured instead of one it remembered.

WHAT COUNTS
    A "header block" is the comment run between a `; ------` rule and the next
    one, whose FIRST line is `; <Label> -- ...`.  A field is present iff a line
    of that block matches `;  <Field>:`.  Continuation lines are not counted, so
    a field mentioned only inside another field's prose does NOT count -- which
    is deliberate: the point of the five fields is that a reader can find each
    one without reading the whole block.

    NOT counted as routines: labels with no header block at all.  Use --orphans
    to list those instead; a plain `sub_XXXXXX` with a one-line comment is a
    stated gap, not a defect, and the wave reports say so.

RUN
    python3 notes/prom_a_header_depth.py                # every header
    python3 notes/prom_a_header_depth.py --prefix Fdc_  # one module
    python3 notes/prom_a_header_depth.py --missing      # only incomplete ones
    python3 notes/prom_a_header_depth.py --orphans      # labels with no header
Exit status is non-zero only if the .s cannot be read.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
FIELDS = ("Called from", "Inputs", "Outputs", "Evidence", "Unknown")
RULE = re.compile(r"^; -{10,}")


def blocks():
    src = open(SRC).read().split("\n")
    out, i = [], 0
    while i < len(src):
        if RULE.match(src[i]):
            j, body = i + 1, []
            while j < len(src) and src[j].startswith(";") and not RULE.match(src[j]):
                body.append(src[j])
                j += 1
            out.append((i + 1, body))
            i = j
        else:
            i += 1
    return out


def headers():
    rows = []
    for line_no, b in blocks():
        if not b:
            continue
        m = re.match(r"^; ([A-Za-z_][A-Za-z0-9_]*)\b", b[0])
        if not m:
            continue
        have = {m2.group(1) for m2 in
                (re.match(r"^;\s*(%s)\s*:" % "|".join(FIELDS), l) for l in b) if m2}
        rows.append((m.group(1), line_no, have))
    return rows


def main():
    prefix = ""
    if "--prefix" in sys.argv:
        prefix = sys.argv[sys.argv.index("--prefix") + 1]
    rows = [r for r in headers() if r[0].startswith(prefix)]
    if "--orphans" in sys.argv:
        named = {r[0] for r in headers()}
        seen = set()
        for line in open(SRC):
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
            if m and not m.group(1).startswith(".L") and m.group(1).startswith(prefix):
                if m.group(1) not in named:
                    seen.add(m.group(1))
        for n in sorted(seen):
            print("no header  " + n)
        print("\n%d label(s) with no header block" % len(seen))
        return
    full = 0
    for name, line_no, have in rows:
        missing = [f for f in FIELDS if f not in have]
        if not missing:
            full += 1
            if "--missing" in sys.argv:
                continue
        print("%-40s :%-6d %s" % (name, line_no,
                                  "FULL" if not missing else "missing " + ", ".join(missing)))
    print("\n%d header block(s) with prefix %r; %d carry all five fields, %d do not"
          % (len(rows), prefix, full, len(rows) - full))


main()
