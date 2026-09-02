#!/usr/bin/env python3
"""prom_b_small_span_classify.py

QUESTION IT ANSWERS
-------------------
"Of the `.incbin` spans left in wsa1/prom_b/wsa1_prom_b.s, what are the SMALL
ones (<= 128 bytes), and what sits immediately before and after each of them in
the source?"

The lane hypothesis this tool exists to test: a 1-, 2- or 30-byte `.incbin`
wedged between two converted regions is rarely an undecoded mystery.  It is far
more often an ARTEFACT OF FRAMING of the conversion around it -- an alignment
pad, a literal the previous instruction run should have absorbed, a jump-table
entry, or the tail of a record whose head was converted.  So the tool reports,
per span: the last real source line before it, the first real source line after
it, the raw ROM bytes, and a mechanical classification built only from those.

USAGE
-----
    python3 scripts/analysis/prom_b_small_span_classify.py            # table
    python3 scripts/analysis/prom_b_small_span_classify.py --max 128  # size cut
    python3 scripts/analysis/prom_b_small_span_classify.py --detail   # + context
    python3 scripts/analysis/prom_b_small_span_classify.py --all      # no cut

Run from the wsa1/ directory.  Reads only the source and the ROM; writes
nothing.

CLASSIFICATION VOCABULARY (mechanical, from neighbours + bytes only)
--------------------------------------------------------------------
  FILL-<hh>       every byte of the span is 0x<hh>
  AFTER-TERM      the last instruction before the span is a flow terminator
                  (ret/reti/jp/jr unconditional) -- i.e. the span begins where a
                  routine ended: inter-routine slack, not a hole inside a run
  MID-RUN         the previous real line is a non-terminating instruction, so
                  the converted run was cut short *while still flowing* into
                  this span.  These are the framing suspects.
  AFTER-DATA      the previous real line is a data directive (.byte/.word/.long/
                  .ascii/.fill/.space/.zero) -- the span is adjacent to a typed
                  data object, so it is probably more of the same object
  AFTER-INCBIN    the previous real line is another .incbin (spans that touch)
  BOL             nothing converted precedes it in the file
The NEXT column is the same vocabulary applied forwards, plus:
  LABEL           the next real line is a label definition (a named routine or
                  object starts right after the span)
"""
import argparse
import os
import re
import sys

SRC = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"
INCBIN_RE = re.compile(r'^\s*\.incbin\s+"[^"]*"\s*,\s*(0x[0-9A-Fa-f]+)\s*,\s*(0x[0-9A-Fa-f]+)')
LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$]*):')
DATA_DIRECTIVES = (".byte", ".word", ".long", ".short", ".ascii", ".asciz",
                   ".fill", ".space", ".zero", ".quad", ".int")
# TLCS-900 unconditional flow terminators as this file spells them.
TERM_RE = re.compile(r'^\s*(ret|reti|retd|halt)\b|^\s*(jp|jr|jrl)\s+(?!\s*(nz|z|nc|c|pl|mi|ne|eq|ge|lt|gt|le|ov|nov|ult|ule|uge|ugt)\b)',
                     re.IGNORECASE)


def code_of(line):
    """Strip the trailing `; ...` comment and whitespace; '' if not a real line."""
    s = line.split(";", 1)[0].rstrip()
    return s if s.strip() else ""


def kind_of(codeline):
    if codeline is None:
        return "BOL"
    s = codeline.strip()
    if LABEL_RE.match(s):
        return "LABEL"
    if s.startswith(".incbin"):
        return "AFTER-INCBIN"
    low = s.lower()
    for d in DATA_DIRECTIVES:
        if low.startswith(d):
            return "AFTER-DATA"
    if low.startswith("."):
        return "DIRECTIVE"
    if TERM_RE.match(s):
        return "AFTER-TERM"
    return "MID-RUN"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--max", type=int, default=128,
                    help="largest span to report, in bytes (default 128)")
    ap.add_argument("--all", action="store_true", help="ignore --max")
    ap.add_argument("--detail", action="store_true",
                    help="print the neighbouring source lines verbatim")
    args = ap.parse_args()

    if not os.path.exists(SRC):
        sys.exit("run me from wsa1/ -- %s not found" % SRC)
    lines = open(SRC, encoding="latin-1").read().split("\n")
    rom = open(ROM, "rb").read()

    spans = []
    for i, line in enumerate(lines):
        m = INCBIN_RE.match(line)
        if not m:
            continue
        off, length = int(m.group(1), 16), int(m.group(2), 16)
        # nearest real source line before / after
        prev = nxt = None
        prev_i = nxt_i = None
        for j in range(i - 1, -1, -1):
            c = code_of(lines[j])
            if c:
                prev, prev_i = c, j
                break
        for j in range(i + 1, len(lines)):
            c = code_of(lines[j])
            if c:
                nxt, nxt_i = c, j
                break
        data = rom[off:off + length]
        spans.append(dict(line=i + 1, off=off, len=length, addr=0xF00000 + off,
                          prev=prev, nxt=nxt, prev_i=prev_i, nxt_i=nxt_i,
                          data=data))

    total_all = sum(s["len"] for s in spans)
    sel = spans if args.all else [s for s in spans if s["len"] <= args.max]
    print("prom_b .incbin spans: %d total, %d bytes" % (len(spans), total_all))
    print("selected (<= %s bytes): %d spans, %d bytes"
          % ("inf" if args.all else args.max, len(sel), sum(s["len"] for s in sel)))
    print()
    hdr = "%-6s %-9s %-5s %-13s %-13s %-11s %s" % (
        "LINE", "ROMADDR", "LEN", "PREV", "NEXT", "FILL?", "BYTES")
    print(hdr)
    print("-" * len(hdr))
    for s in sel:
        d = s["data"]
        fill = "FILL-%02X" % d[0] if len(set(d)) == 1 else ""
        pk, nk = kind_of(s["prev"]), kind_of(s["nxt"])
        if nk == "AFTER-TERM":
            nk = "TERM"
        if nk == "AFTER-DATA":
            nk = "DATA"
        if nk == "AFTER-INCBIN":
            nk = "INCBIN"
        b = " ".join("%02X" % x for x in d[:16]) + (" .." if len(d) > 16 else "")
        print("%-6d %-9s %-5d %-13s %-13s %-11s %s"
              % (s["line"], "%06X" % s["addr"], s["len"], pk, nk, fill, b))
        if args.detail:
            print("        prev L%s: %s" % (s["prev_i"] + 1 if s["prev_i"] else "?", s["prev"]))
            print("        next L%s: %s" % (s["nxt_i"] + 1 if s["nxt_i"] else "?", s["nxt"]))
            print()

    # summary tallies
    print()
    from collections import Counter
    cp = Counter(kind_of(s["prev"]) for s in sel)
    cn = Counter(kind_of(s["nxt"]) for s in sel)
    cf = Counter(("FILL-%02X" % s["data"][0]) if len(set(s["data"])) == 1 else "mixed"
                 for s in sel)
    print("PREV kinds:", dict(cp))
    print("NEXT kinds:", dict(cn))
    print("byte shape:", dict(cf))
    bytes_by_prev = Counter()
    for s in sel:
        bytes_by_prev[kind_of(s["prev"])] += s["len"]
    print("bytes by PREV kind:", dict(bytes_by_prev))


if __name__ == "__main__":
    main()
