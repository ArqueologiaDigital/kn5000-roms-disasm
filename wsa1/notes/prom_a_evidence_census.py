#!/usr/bin/env python3
"""Which prom_a labels carry a semantic NAME but no stated evidence for it?

QUESTION ANSWERED
-----------------
The byte gate is blind to names.  This tree's rule is that every semantic name
carries an `Evidence:` line in the header ABOVE it, citing what proves the name.
Round 1's audit (finding F16) counted 25 of 84 prom_a labels new since HEAD with
no such line -- but it counted the raw label list, which over-states the gap: a
routine's INTERNAL labels (`MIDI_RX_QueueFull2`, `LCD_Fill_NextRow`, ...) are
covered by the header of the routine they sit inside and were never meant to
carry one of their own.

This script separates the two cases, so the number in a report is a number about
headers and not about label syntax:

  HEADED    the label is introduced by its own `; ---- ... ; ----` header block
            (the block's first text line names it).  These MUST say Evidence.
  INTERNAL  the label sits inside the extent of an earlier headed label, with no
            header of its own.  Reported separately, never counted as a gap.

USAGE
-----
    python3 notes/prom_a_evidence_census.py            # summary + the gaps
    python3 notes/prom_a_evidence_census.py --all      # every headed label
    python3 notes/prom_a_evidence_census.py --internal # the internal labels too
    python3 notes/prom_a_evidence_census.py --selftest # asserts known-good cases

WHAT COUNTS AS A NAME.  `sub_XXXXXX`, `L_XXXXXX`, `loc_`, `__`-prefixed and the
all-caps structural labels (`VECTORS`, `BUILD_TAG`, `end`) are ADDRESS labels,
not claims, and are excluded.  Everything else asserts a meaning.

WHAT COUNTS AS EVIDENCE.  A line in the label's own header block matching
`Evidence` (case-insensitive).  ⚠ This is a keyword test, not a judgement: a
header that argues its case in prose without the word is reported as a gap, and
a header with the word and a bad argument passes.  Read the ones it prints.
"""
import re
import sys
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'notes'))
from asm_source import image_path  # noqa: E402  (the image, not the master)
# ⚠ prom_a `.include`s kernel/kernel.s and two shared maincpu routines; a
# census over the primary alone misses 4,148 lines of them.
SRC = image_path(ROOT, 'prom_a/wsa1_prom_a.s')

RULE = re.compile(r'^;\s*-{5,}\s*$')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDRESS_LABEL = re.compile(r'^(sub_[0-9A-Fa-f]{6}|L_[0-9A-Fa-f]{6}|loc_|__)')
STRUCTURAL = {'VECTORS', 'BUILD_TAG', 'end', 'START', 'RESET'}


def load(path=SRC):
    with open(path, encoding='utf-8') as fh:
        return fh.read().split('\n')


def is_semantic(name):
    if name in STRUCTURAL:
        return False
    if ADDRESS_LABEL.match(name):
        return False
    return True


def blocks(lines):
    """Return [(start,end)] line indices of every `; ----`-delimited block."""
    out = []
    open_at = None
    for i, ln in enumerate(lines):
        if RULE.match(ln):
            if open_at is None:
                open_at = i
            else:
                out.append((open_at, i))
                open_at = None
    return out


def census(lines):
    """-> (headed, internal).

    headed:   [(lineno, name, has_evidence, block_start, block_end)]
    internal: [(lineno, name, owning_headed_name)]
    """
    blks = blocks(lines)
    # index: block END line -> block
    end_index = {e: (s, e) for (s, e) in blks}
    headed, internal = [], []
    last_headed = None
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if not m:
            continue
        name = m.group(1)
        # walk back over blank lines to find a block terminator
        j = i - 1
        while j >= 0 and lines[j].strip() == '':
            j -= 1
        blk = end_index.get(j)
        if blk is not None:
            s, e = blk
            body = '\n'.join(lines[s:e + 1])
            names_it = name in '\n'.join(lines[s:min(s + 4, e)])
            if not names_it:
                # a block that does not name this label is a section banner,
                # not this label's header
                blk = None
        if not is_semantic(name):
            if blk is not None:
                last_headed = name
            continue
        if blk is not None:
            s, e = blk
            body = '\n'.join(lines[s:e + 1])
            headed.append((i + 1, name, 'evidence' in body.lower(), s + 1, e + 1))
            last_headed = name
        else:
            internal.append((i + 1, name, last_headed))
    return headed, internal


def main():
    lines = load()
    headed, internal = census(lines)
    gaps = [h for h in headed if not h[2]]
    argv = sys.argv[1:]

    if '--selftest' in argv:
        by_name = {h[1]: h for h in headed}
        ok = True
        # a label the tree documents properly
        for good in ('MIDI_RX_DataByte', 'MIDI_StatusDispatch_Table'):
            if good not in by_name:
                print('FAIL selftest: %s not seen as a headed label' % good); ok = False
            elif not by_name[good][2]:
                print('FAIL selftest: %s should have Evidence' % good); ok = False
        # a label that is internal to a routine, not a header of its own
        int_names = {n for (_, n, _) in internal}
        if 'MIDI_RX_QueueFull2' not in int_names:
            print('FAIL selftest: MIDI_RX_QueueFull2 should classify INTERNAL'); ok = False
        if 'MIDI_MessageLength_Table' in by_name:
            print('FAIL selftest: the retired name MIDI_MessageLength_Table is back'); ok = False
        print('selftest: %s' % ('PASS' if ok else 'FAIL'))
        return 0 if ok else 1

    print('prom_a labels')
    print('  semantic, headed  : %4d   (of which NO Evidence line: %d)'
          % (len(headed), len(gaps)))
    print('  semantic, internal: %4d   (covered by the enclosing header)'
          % len(internal))
    if '--all' in argv:
        for lineno, name, ev, s, e in headed:
            print('  %-5s :%-6d %s' % ('EV' if ev else 'GAP', lineno, name))
    elif gaps:
        print('\nheaded labels with no Evidence line:')
        for lineno, name, ev, s, e in gaps:
            print('  :%-6d %-42s header :%d-%d' % (lineno, name, s, e))
    if '--internal' in argv:
        print('\ninternal labels (no header of their own, by design):')
        for lineno, name, owner in internal:
            print('  :%-6d %-42s inside %s' % (lineno, name, owner))
    return 0


if __name__ == '__main__':
    sys.exit(main())
