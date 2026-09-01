#!/usr/bin/env python3
"""Which of prom_a's non-`.incbin` `.byte`/`.long`/`.ascii` runs carry NO
comment at all -- candidates for the "raw dump wearing a directive" trap?

WHY THIS EXISTS
  source_coverage.py's own docstring already warns that a region emitted as
  `.byte 0x12, 0x34, ...` counts as "converted" while telling you nothing, and
  names a real precedent: a sibling project once shipped a "territorially
  complete" claim while 8,496 bytes of ACTUAL CODE sat in plain sight as an
  un-commented `.byte` dump. `.incbin` count is the wrong instrument for that
  failure mode by construction -- it has already left `.incbin` by the time
  the trap matters.

  This is the check that instrument cannot do: scan every `.byte`/`.long`/
  `.ascii` run that ISN'T `.incbin` and flag the ones with no meaningful
  comment on ANY line, so a human can go look at whether each is (a) already
  evidence-documented data with an honest "Unknown: ..." header above it, or
  (b) reachable code that was never actually disassembled.

METHOD
  A line is "meaningful" if its comment (everything after the first `;`)
  contains a run of 3+ letters -- catches names, "col N rows M", "-> LABEL",
  ASCII interpretations, etc., while a bare hex-byte echo or address alone
  does not.  Runs of >= RUN_MIN lines where NO line is meaningful are printed,
  largest first.

WHAT WAS FOUND, 2026-09-01/02 (prom_a, working tree of this lane)
  56 runs of >= 12 directive lines with zero per-line comments.  Every one
  sampled (all >= 30 lines, plus several smaller) sits directly under a
  block-header comment with a name, an Evidence: line citing a committed
  check script, and usually an explicit "Unknown: ..." disclaimer -- e.g.
  Data_FF17E2, RecordTables_FB82A0, DiskImage_HardDisk_BootSector (an x86
  FAT boot-sector template -- `eb 3c 90 20 45 4d 49 44 32 2e 30` decodes as
  a real 8086 jmp+nop+OEM-name, confirming the label), KitCategoryLegends,
  MixedTables_FC6626, PtrTable_F99121, PtrTables_F95C95, VersionScreen_Glyphs,
  Msg0716_ObjectRecords, MidiOut_ChangeIndexMap. None decodes as plausible
  TLCS-900 code and none lacks a boundary check. So: NOT the trap, this time
  -- prom_a's already-committed `.byte`/`.long` blocks are boundary-verified,
  evidence-documented data, not raw material standing in for un-analysis.

  ONE exception was found and left `.incbin` on purpose rather than "fixed"
  by typing it: 0xF8C930-0xF8DA00 (4,304 bytes) is 9 LE32 self-pointers
  (0xF8C930-0xF8C953) into an 18-word block of bitmap-looking constants
  (0xF8C954-0xF8C99B, e.g. 0x80408040) followed by 4,196 bytes of uniform
  0x0E. Typing the head as `.byte` with no reader found would be exactly
  the anti-pattern this script exists to catch -- a directive change with
  no new understanding -- so it was left alone; only the trailing uniform
  run is a `.fill` candidate a future round can take on its own.

RUN
  python3 notes/prom_a_bare_byte_debt_scan.py            # >= 12-line runs
  python3 notes/prom_a_bare_byte_debt_scan.py --min 30   # only the big ones
"""
import re
import sys
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402

DIR_RE = re.compile(r'^\t\.(byte|long|ascii|fill|incbin)\b')
WORD_RE = re.compile(r'[A-Za-z]{3,}')


def meaningful(line):
    if ';' not in line:
        return False
    return bool(WORD_RE.search(line.split(';', 1)[1]))


def bare_runs(lines, run_min):
    """[(kind, start_line_index, n_lines)] for runs of >= run_min directive
    lines of one kind (excluding .incbin) where NO line has a meaningful
    comment."""
    out = []
    cur = None
    for i, l in enumerate(lines):
        m = DIR_RE.match(l)
        if m and m.group(1) != "incbin":
            kind = m.group(1)
            mn = meaningful(l)
            if cur and cur[0] == kind and not mn and not cur[3]:
                cur[2] += 1
            elif cur:
                out.append(tuple(cur[:3]))
                cur = [kind, i, 1, mn]
            else:
                cur = [kind, i, 1, mn]
            if mn:
                cur[3] = True
        else:
            if cur:
                out.append(tuple(cur[:3]))
                cur = None
    if cur:
        out.append(tuple(cur[:3]))
    return [r for r in out if r[2] >= run_min]


def main():
    run_min = 12
    if "--min" in sys.argv:
        run_min = int(sys.argv[sys.argv.index("--min") + 1])
    lines = image_lines(ROOT, "prom_a/wsa1_prom_a.s")
    runs = bare_runs(lines, run_min)
    # a run only counts if EVERY line in it is bare, not just the run-starter;
    # re-filter precisely against the source lines to avoid the tracking bug
    # a hand-rolled state machine invites.
    real = []
    for kind, start, n in runs:
        block = lines[start:start + n]
        if all(DIR_RE.match(l) and DIR_RE.match(l).group(1) == kind
               and not meaningful(l) for l in block):
            real.append((kind, start, n))
    print("kind  n_lines  first_line_addr  sample")
    for kind, start, n in sorted(real, key=lambda r: -r[2]):
        addr = re.search(r';\s*([0-9A-Fa-f]{6})', lines[start])
        print("%-6s %4d  %-8s  %s" % (kind, n, addr.group(1) if addr else "?",
                                       lines[start][:70]))
    print("\n%d run(s) of >= %d directive lines with no per-line comment"
          % (len(real), run_min))


if __name__ == "__main__":
    main()
