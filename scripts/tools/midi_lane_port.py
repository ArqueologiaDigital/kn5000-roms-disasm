#!/usr/bin/env python3
r"""Port the SOURCE TEXT of an address range from one maincpu image to another.

QUESTION THIS ANSWERS / JOB IT DOES
-----------------------------------
CLAUDE.md policy 9 (multi-version sync): what one version's source has
established -- typed tables, correct framing, headers -- must reach the other
versions where the same bytes exist.  v9 and v10 share most of
`midi/midi_dispatch_handlers.s` at IDENTICAL addresses, but on 2026-09-25 v10
held 3,889 B of re-typed MIDI CC tables that v9 still spelled as
`jrl nc, 1793` / `swi 7` / `max` instructions.

This tool copies the lines that emit [start, end) in the SOURCE image over the
lines that emit [start+delta, end+delta) in the TARGET image, after asserting:

  * the ROM bytes of the two ranges are IDENTICAL (so the text is equally true
    of both);
  * both ranges begin and end on source-line boundaries in their own files;
  * the set of label DEFINITIONS in the target file is unchanged except for
    labels the source text brings with it that are not yet defined there
    (a label that would disappear is a refusal: something may reference it);

then rebuilds the target image and requires it byte-identical to its dump,
restoring the file otherwise.

RUN (repo root, after `make all`)
    python3 scripts/tools/midi_lane_port.py --from v10 --to v9 \
        --file midi/midi_dispatch_handlers.s --start 0xFD175E --end 0xFD268F [--delta 0] [--dry-run]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import midi_lane_rewrite as rw  # noqa: E402

LABEL_RE = re.compile(r"^([A-Za-z_.$][A-Za-z0-9_.$]*):")


def span_lines(lines, la, a, b):
    idx = [i for i, ad in enumerate(la) if ad is not None and a <= ad < b]
    emit = [i for i in idx if rw.drc.classify_line(lines[i], {})[0] in ("code", "data", "fill")]
    first, last = min(emit), max(emit)
    if la[first] != a:
        sys.exit("REFUSED: 0x%X is not a line start" % a)
    nxt = [ad for ad in la[last + 1:] if ad is not None]
    if not nxt or nxt[0] != b:
        sys.exit("REFUSED: 0x%X is not a line end" % b)
    # extend to trailing non-emitting lines that still belong before b? no:
    # keep exactly first..last (labels at b stay where they are)
    return first, last


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--from", dest="src", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--to", dest="dst", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--file", required=True)
    ap.add_argument("--start", required=True)
    ap.add_argument("--end", required=True)
    ap.add_argument("--delta", default="0", help="target address = source address + delta")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--leading-comments", action="store_true",
                    help="also carry the comment/blank lines directly above the first source line")
    a = ap.parse_args()
    s0, e0, d = int(a.start, 16), int(a.end, 16), int(a.delta, 0)
    la_s, rom_s = rw.line_addresses(a.src, [a.file])
    la_d, rom_d = rw.line_addresses(a.dst, [a.file])
    B = rw.BASE
    if rom_s[s0 - B:e0 - B] != rom_d[s0 + d - B:e0 + d - B]:
        sys.exit("REFUSED: ROM bytes differ between %s 0x%X.. and %s 0x%X.." % (a.src, s0, a.dst, s0 + d))
    ps = os.path.join(rw.ROOT, rw.image(a.src)["mirror"], a.file)
    pd = os.path.join(rw.ROOT, rw.image(a.dst)["mirror"], a.file)
    Ls = open(ps, "rb").read().decode("latin-1").split("\n")
    raw_d = open(pd, "rb").read()
    Ld = raw_d.decode("latin-1").split("\n")
    f1, l1 = span_lines(Ls, la_s[a.file], s0, e0)
    f2, l2 = span_lines(Ld, la_d[a.file], s0 + d, e0 + d)
    if a.leading_comments:
        while f1 > 0 and (Ls[f1 - 1].strip().startswith(";") or not Ls[f1 - 1].strip()):
            f1 -= 1
    new = Ld[:f2] + Ls[f1:l1 + 1] + Ld[l2 + 1:]
    before = {m.group(1) for m in map(LABEL_RE.match, Ld) if m}
    after = {m.group(1) for m in map(LABEL_RE.match, new) if m}
    lost = before - after
    if lost:
        sys.exit("REFUSED: label definitions would disappear from %s: %s" % (a.dst, sorted(lost)[:20]))
    print("%s %s lines %d..%d (%d) -> %s lines %d..%d (%d); new labels: %s" % (
        a.file, a.src, f1 + 1, l1 + 1, l1 - f1 + 1, a.dst, f2 + 1, l2 + 1, l2 - f2 + 1,
        sorted(after - before)))
    if a.dry_run:
        return
    open(pd, "wb").write("\n".join(new).encode("latin-1"))
    if not rw.verify(a.dst):
        open(pd, "wb").write(raw_d)
        sys.exit("REJECTED: %s no longer byte-identical; restored" % a.dst)
    print("VERIFIED: rebuilt %s is byte-identical to the dump" % a.dst)


if __name__ == "__main__":
    main()
