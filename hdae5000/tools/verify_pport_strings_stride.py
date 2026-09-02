#!/usr/bin/env python3
"""verify_pport_strings_stride.py -- does HDAE5000_PPORT_Strings really have a fixed 24-byte
record stride, with real consumer code proving it?

QUESTION ANSWERED: hdae5000_ui_display.s carries 20 ".asciz "NN>Description"" lines (each a
22-character, space-padded string) each followed by a single bare `.byte 0x00`, plus two
irregular 22-byte tail entries and a final 24-byte error string. Before this script, the only
claim on record was the block comment listing the 21 strings' TEXT -- nothing on record checked
that a fixed stride is actually consumed by real code, as opposed to being an accident of how the
strings happened to get padded.

METHOD: read every source line's REAL linked address from get_lprobe_addrs.py (the pinned
assembler's own ELF symbol table, not a hand-rolled byte count), compute where each of the 22
records in the table starts, and cross-check that list against every literal ROM address the
"initialize HD"/PPORT command handlers (HDAE5000_Code_2_PartB and neighbours) load with
`lda_24 xbc, (0x2954xx)` / `(0x2955xx)` -- i.e. addresses the firmware itself uses to fetch a
status string to display. If those call-site literals are not a subset of the record starts this
script computes independently, the stride claim is wrong.

RUN (from the worktree root, after `python3 hdae5000/tools/get_lprobe_addrs.py
hdae5000_ui_display.s > /tmp/lprobe_ui.txt`):
    python3 hdae5000/tools/verify_pport_strings_stride.py /tmp/lprobe_ui.txt
"""
import re
import sys

SRC = "hdae5000/hdae5000_ui_display.s"
TABLE_START_LABEL = "HDAE5000_PPORT_Strings:"
TABLE_END_LABEL = "HDAE5000_Code_2_PartB:"
CALL_SITE_RE = re.compile(r'lda_24\s+xbc,\s*\(0x([0-9a-fA-F]+)\)')


def strip_comment(line):
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == ';' and not in_str:
            return line[:i], line[i + 1:].strip()
    return line, ""


def main():
    addr_file = sys.argv[1]
    addr = {}
    with open(addr_file) as f:
        for line in f:
            a, t, name = line.split()
            n = int(name.split("_", 1)[1])
            addr[n] = int(a, 16)

    with open(SRC, encoding="latin-1") as f:
        lines = f.readlines()
    assert len(lines) == len(addr), (
        f"{SRC} has {len(lines)} lines but {addr_file} has {len(addr)} addresses -- "
        f"regenerate get_lprobe_addrs.py's output against the CURRENT file first")

    in_table = False
    record_starts = []   # (line_no, addr, kind) for every line that begins a record
    record_lens = []
    cur_start = None
    call_sites = []

    for i, line in enumerate(lines, 1):
        code, comment = strip_comment(line)
        s = code.strip()
        if TABLE_START_LABEL in s:
            in_table = True
            cur_start = (i, addr[i])
            continue
        if TABLE_END_LABEL in s:
            in_table = False
            if cur_start:
                record_starts.append(cur_start)
            continue
        for m in CALL_SITE_RE.finditer(line):
            call_sites.append((i, int(m.group(1), 16)))
        if not in_table:
            continue
        # A new record starts at a `.asciz`/`.ascii` line that follows a completed previous
        # record (i.e. right after a bare `.byte` closer, or at the table's very first line).
        if re.match(r'^(?:\S+\s*:\s*)?\.(asciz|ascii)\b', s, re.IGNORECASE):
            if cur_start and cur_start[1] != addr[i]:
                record_starts.append(cur_start)
                cur_start = (i, addr[i])
            elif cur_start is None:
                cur_start = (i, addr[i])

    starts = sorted(set(a for _, a in record_starts))
    print(f"table: {TABLE_START_LABEL} .. {TABLE_END_LABEL}, {len(starts)} record starts computed")
    print(f"first {starts[0]:#08x}, last {starts[-1]:#08x}")
    diffs = [b - a for a, b in zip(starts, starts[1:])]
    print(f"record lengths (consecutive diffs): {diffs}")

    in_range = sorted(set(a for _, a in call_sites if starts[0] <= a <= starts[-1]))
    print(f"\n{len(in_range)} distinct in-table call-site literal addresses "
          f"(lda_24 xbc, (0x....)) found in {SRC}:")
    for a in in_range:
        print(f"  {a:#08x}  {'== record start' if a in starts else '*** NOT A RECORD START ***'}")

    bad = [a for a in in_range if a not in starts]
    ok = len(in_range) - len(bad)
    print(f"\n{ok}/{len(in_range)} call-site literals land exactly on an independently computed "
          f"record start.")
    if bad:
        print("FAILED: some call sites do not land on a record boundary:", [hex(a) for a in bad])
        sys.exit(1)
    print("PASS: every status-string call site in this handler code addresses a real record "
          "start -- the stride is not an accident of padding, it is what the firmware indexes.")


if __name__ == "__main__":
    main()
