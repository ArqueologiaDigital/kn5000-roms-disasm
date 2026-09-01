#!/usr/bin/env python3
"""prom_d_debt_probe.py -- territorial debt in prom_d's tone-database sources.

QUESTION ANSWERED
  Of prom_d's 524,288 bytes, how many are accounted for by the tone-database
  source files, split by directive class (.byte / .short / .long / .ascii /
  .fill)?  And: is an UNSTRUCTURED DUMP hiding inside what looks like
  per-record source?

  The second question is the point.  Byte totals alone cannot tell a genuine
  record table from a raw blob that happens to be spelled in .byte
  directives -- both "account for" their bytes.  So the probe also measures
  LABEL DENSITY: any label-to-label span longer than 512 bytes is reported,
  because real per-record data carries labels at record boundaries and a
  dump does not.  A large span is a lead, not a verdict.

  ⚠ It reports what the SOURCE says, not what the ROM says.  It is not a
  substitute for the byte-identity gate.

★ FIXED 2026-09-01 (PROMD lane).  The first committed version undercounted by
  exactly the .short total (40,010 B): its accumulator did
  `total[resolved_key] = total.get(d, 0) + n` -- the READ used the raw
  directive name `d` ("short") while the WRITE used the resolved bucket key
  ("other"), so each new .short line OVERWROTE total["other"] with just that
  line's n instead of adding to it. Only the last .short line's 2 bytes
  survived, which is why the old report showed "other: 2" and a 40,008-byte
  gap instead of 40,010 (the difference is two literal .other-class bytes
  that exist independent of the bug -- see the sizes table below). Rewritten
  to key a single dict by the ACTUAL directive name throughout, so there is
  only one name per bucket and no read/write mismatch is possible.

  ★ REPORTING RULE the fix makes newly visible: .fill (erased flash, all
  0xFF) is a REAL and CORRECT rendering of that region -- it is not debt --
  but it is not decoded CONTENT either. It is kept in its own row and is
  NEVER folded into a "bytes covered" figure, because 193,767 of prom_d's
  524,288 bytes (37%) are that one erased tail and a reader who adds it into
  "coverage" would be quoting padding as if it were understanding.

RUN
  python3 wsa1/notes/sound/prom_d_debt_probe.py

PROVENANCE
  Written by the PROMD lane of the 2026-09-01 full-disassembly push, and
  recovered from session scratch before it was lost. ROOT is derived from
  this file's location so it works from any checkout or worktree.
"""
import re, sys, os
from collections import defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "prom_d")

FILES = ["tone_database_directory.s", "tone_database_records.s", "tone_database_aux.s"]

WIDTH = {"byte": 1, "hword": 2, "short": 2, "word": 4, "long": 4, "dword": 8, "quad": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')

DIRECTIVE_RE = re.compile(r'^\s*\.(\w+)\s*(.*)$')
LABEL_RE = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')


def ascii_len(operand):
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        body = m.group(1)
        total += len(ESCAPE.sub("X", body))
    return total


def count_items(rest):
    # split top-level commas; no directive in this image nests a comma inside
    # an operand (no macro args, no parenthesised expressions), so a plain
    # split is exact here -- unlike a general assembler-source counter.
    return len([x for x in rest.split(",") if x.strip() != ""])


def measure():
    # keyed by the ACTUAL directive name -- one name, one bucket, so a read
    # and a write of the same entry can never disagree on its key.
    sizes = defaultdict(int)
    counts = defaultdict(int)
    unknown_directives = set()
    pos = 0
    label_positions = []  # (pos, label, file, lineno)

    for fn in FILES:
        path = os.path.join(ROOT, fn)
        with open(path) as f:
            for lineno, line in enumerate(f, 1):
                s = line.split(";", 1)[0].rstrip("\n")
                stripped = s.strip()
                if not stripped:
                    continue
                lm = LABEL_RE.match(stripped)
                if lm:
                    label_positions.append((pos, lm.group(1), fn, lineno))
                    continue
                m = DIRECTIVE_RE.match(stripped)
                if not m:
                    continue
                d, rest = m.group(1), m.group(2).strip()
                if d in WIDTH:
                    n = WIDTH[d] * count_items(rest)
                    sizes[d] += n
                    counts[d] += 1
                    pos += n
                elif d in ("ascii", "asciz"):
                    n = ascii_len(rest) + (1 if d == "asciz" else 0)
                    sizes[d] += n
                    counts[d] += 1
                    pos += n
                elif d == "fill":
                    parts = [p.strip() for p in rest.split(",")]
                    n = int(parts[0], 0)
                    if len(parts) >= 2:
                        n *= int(parts[1], 0)
                    sizes[d] += n
                    counts[d] += 1
                    pos += n
                elif d in ("include", "text"):
                    continue
                else:
                    unknown_directives.add(d)

    return sizes, counts, unknown_directives, pos, label_positions


def main():
    sizes, counts, unknown_directives, pos, label_positions = measure()

    IMAGE_SIZE = 524288
    total_accounted = sum(sizes.values())

    print("=== prom_d territorial debt probe ===")
    print(f"files measured: {', '.join(FILES)}")
    print()
    print("bytes by directive class (each row is its own class -- never summed")
    print("into one 'covered' number without saying which classes are in it):")
    for d in sorted(sizes, key=lambda k: -sizes[k]):
        note = "  <- erased flash, NOT decoded content" if d == "fill" else ""
        print(f"  {d:8s} {sizes[d]:>10,} B  ({counts[d]:>6,} directives){note}")
    print(f"  {'TOTAL':8s} {total_accounted:>10,} B")
    print()
    decoded = total_accounted - sizes.get("fill", 0)
    print(f"decoded content (TOTAL minus .fill): {decoded:,} B "
          f"({100*decoded/IMAGE_SIZE:.1f}% of the 524,288-byte image)")
    print(f"erased tail (.fill, all 0xFF):        {sizes.get('fill', 0):,} B "
          f"({100*sizes.get('fill', 0)/IMAGE_SIZE:.1f}% of the image)")
    print()
    print("unknown directives:", unknown_directives or "(none)")
    print()
    diff = IMAGE_SIZE - total_accounted
    if diff == 0:
        print(f"expected image size: {IMAGE_SIZE:,} -- ACCOUNTED FOR EXACTLY.")
        print("These three files ARE the whole image: no byte is unexplained")
        print("and no byte is double-counted.")
    else:
        print(f"expected image size: {IMAGE_SIZE:,}")
        print(f"difference: {diff:,} bytes UNEXPLAINED by {', '.join(FILES)}.")
        print("This means these three files are NOT the whole image, or this")
        print("probe's directive list is incomplete -- state which, do not")
        print("leave the gap silent.")
    print()

    # label density / gap analysis: any run of raw data with no label
    # boundary longer than a threshold is a LEAD that an unstructured dump
    # may be hiding inside what looks like per-record source -- not a verdict.
    label_positions.append((pos, "<EOF>", "-", 0))
    THRESH = 512
    big_gaps = []
    max_gap = 0
    max_gap_info = None
    for i in range(1, len(label_positions)):
        p0, l0, f0, ln0 = label_positions[i - 1]
        p1, _, _, _ = label_positions[i]
        gap = p1 - p0
        if gap > max_gap:
            max_gap = gap
            max_gap_info = (l0, f0, ln0, gap)
        if gap > THRESH:
            big_gaps.append((l0, f0, ln0, gap))

    print(f"labels found: {len(label_positions) - 1}")
    print(f"largest single label-to-label span: {max_gap} bytes, after label {max_gap_info}")
    print(f"spans > {THRESH} bytes: {len(big_gaps)}")
    for g in big_gaps:
        tag = "  <- the erased tail (.fill), not a candidate dump" if g[0] == "erased_tail" else ""
        print("   ", g, tag)


def selftest():
    sizes, counts, unknown, pos, labels = measure()
    assert not unknown, f"unhandled directives: {unknown}"
    assert sum(sizes.values()) == 524288, (
        f"probe must account for prom_d's whole 524,288 bytes exactly; "
        f"got {sum(sizes.values())}")
    # the bug this rewrite fixes: a .short-only accumulation must not vanish
    assert sizes["short"] == 40010, f"expected .short total 40010, got {sizes['short']}"
    assert counts["short"] == 5669, f"expected 5669 .short directives, got {counts['short']}"
    assert sizes["fill"] == 193767, "the erased tail must be exactly 193,767 B"
    print("selftest OK: 524,288 B accounted for exactly, 0 unknown directives, "
          f"{len(labels)} labels.")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        main()
