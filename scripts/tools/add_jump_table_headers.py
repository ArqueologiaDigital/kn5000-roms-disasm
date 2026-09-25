#!/usr/bin/env python3
r"""Put a reader-quoting header above small jump tables, in each image's own words.

QUESTION THIS ANSWERS
    A `.long` jump table sitting between two routines is flagged by the data
    census as embedded-in-code until it carries a header.  The honest header
    is the reader itself: this script finds, in THIS image's source, the
    instruction that loads the table's address and quotes the instructions
    from the routine label down to the indirect jump/call, so the header is
    exact per version (RAM addresses differ between v7 and v9/v10).

RUN
    python3 scripts/tools/add_jump_table_headers.py --image v10 --file audio/audio_control_engine.s \
        --table 'RegisterBit_Manipulate_Table:8:bits 0-2 of the index byte' [...] [--apply]
    TABLE:COUNT:INDEX-DESCRIPTION; COUNT is checked against the table's rows.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--table", action="append", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    L = open(path, "rb").read().decode("latin-1").split("\n")
    for spec in a.table:
        name, count, desc = spec.split(":", 2)
        count = int(count)
        ti = next(i for i, l in enumerate(L) if l.startswith(name + ":"))
        rows = 0
        for l in L[ti + 1:]:
            if re.match(r'^\s*\.long\s', l):
                rows += 1
            else:
                break
        if rows != count:
            sys.exit("%s: %d .long rows, expected %d" % (name, rows, count))
        li = next(i for i, l in enumerate(L)
                  if re.search(r'^\s*(ld|lda)\s+x\w\w,\s*\(?%s(:24\))?\s*$' % re.escape(name), l))
        # walk back to the routine label, forward to the indirect transfer
        s = li
        while s > 0 and not re.match(r'^[A-Za-z_.$][\w.$]*:', L[s]):
            s -= 1
        e = li
        while e < len(L) - 1 and not re.search(r'\b(jp|call)\s+\(x\w\w\)|jp_ind|call_ind', L[e]):
            e += 1
        routine = L[s].split(":")[0]
        code = [re.sub(r'\s+', " ", l.split(";")[0].strip()) for l in L[s + 1:e + 1]]
        code = [c for c in code if c and not re.match(r'^[A-Za-z_.$][\w.$]*:$', c)]
        hdr = ["; Jump table: %d x .long code pointer.  Reader %s:" % (count, routine)]
        line = ";  "
        for c in code:
            piece = " " + c + " /"
            if len(line) + len(piece) > 78:
                hdr.append(line.rstrip(" /"))
                line = ";  "
            line += piece
        hdr.append(line.rstrip(" /"))
        hdr.append("; Index: %s; %d entries." % (desc, count))
        if L[ti - 1].startswith("; Jump table:") or any(h in L[max(0, ti - 8):ti] for h in hdr[:1]):
            print(name, "already has a header")
            continue
        print("\n".join(hdr))
        L[ti:ti] = hdr
    if a.apply:
        open(path, "wb").write("\n".join(L).encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
