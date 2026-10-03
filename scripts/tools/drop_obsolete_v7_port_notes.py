#!/usr/bin/env python3
"""drop_obsolete_v7_port_notes.py -- remove the v7 port's carried comments that are no longer true.

QUESTION THIS ANSWERS / JOB IT DOES
  port_v10_span_to_v7.py re-emits every comment of the pre-port v7 span files at the address it
  annotated, under `; (pre-port v7 note about the bytes at 0xADDR:)`.  Most of those comments
  described the raw-byte transcription the port replaced, and they are now false:
    "v10 does not spell this byte either"                 -- both trees spell it natively now
    "differs from v10 here and llvm-objdump cannot read it" / "llvm-mc cannot spell this byte"
    "<old spelling> (v7 patched)" / "(v7 addr)" / "(v7 displacement)"  -- the old spelling of the
                                                            instruction the next line now is
    "-> 0xADDR"                                            -- a branch target the operand names
  This removes each such comment together with its lead-in line, so a lead-in never dangles.
  Every other carried note stays -- "v7 NAME DISPLACED", the 0xFF-filler and romslice
  explanations, the block banners.  OBSOLETE_MARKS is shared with the port tool, which no longer
  carries these.  Comments only: `make gate-all` proves no byte moved.

USAGE
  python3 scripts/tools/drop_obsolete_v7_port_notes.py [--apply]
"""
import argparse
import collections
import glob
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LEAD = re.compile(r'^\s*; \(pre-port v7 note about the bytes at 0x[0-9A-F]+:\)\s*$')
OBSOLETE_MARKS = ("v10 does not spell this byte either",
                  "differs from v10 here and llvm-objdump cannot read it",
                  "llvm-mc cannot spell this byte",
                  "(v7 patched)", "(v7 addr)", "(v7 displacement)")
TARGET = re.compile(r'^\s*; -> 0x[0-9A-Fa-f]{6}\s*$')


def obsolete(line):
    return any(m in line for m in OBSOLETE_MARKS) or bool(TARGET.match(line))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    kinds, kept = collections.Counter(), 0
    for p in sorted(glob.glob(os.path.join(REPO, "v7/maincpu/**/*.s"), recursive=True)):
        L = open(p, "rb").read().decode("latin-1").split("\n")
        out, i, n = [], 0, 0
        while i < len(L):
            if LEAD.match(L[i]):
                j = i + 1
                body = []
                while j < len(L) and L[j].lstrip().startswith(";") and not LEAD.match(L[j]):
                    body.append(L[j])
                    j += 1
                if body and all(obsolete(x) for x in body):
                    for x in body:
                        kinds[next((m for m in OBSOLETE_MARKS if m in x), "-> 0xADDR")] += 1
                    n += 1
                    i = j
                    continue
                kept += 1
            out.append(L[i])
            i += 1
        if n:
            print("%-55s %4d notes dropped" % (os.path.relpath(p, REPO), n))
            if a.apply:
                data = "\n".join(out).encode("latin-1")
                with open(p + ".tmp", "wb") as fh:
                    fh.write(data)
                os.replace(p + ".tmp", p)
    print("dropped by kind: %s; notes kept: %d%s" % (dict(kinds), kept, "" if a.apply else " (dry run)"))


if __name__ == "__main__":
    main()
