#!/usr/bin/env python3
"""Attribute KN5000 code to individual .LSW panel FIELDS, and prove the (tag, offset)
addressing rule the firmware uses.

QUESTION ANSWERED
-----------------
"What does byte N of the record with tag T mean?"

Two independent sources of evidence, both scanned here:

1. ABSOLUTE ACCESSES.  Every `ldb_d8 / stb_d8 / anddi8 / stda16 / lda_d16 ...` whose
   operand falls in 0x00F9A0..0x00FFC0 is mapped, via the ROM schema (see
   lsw_panel_schema_from_rom.py), onto (tag, payload offset) and reported with the
   enclosing routine label.  A store inside `AccPlay_RestoreMuteStates` at payload
   offset 13 is what tells you offset 13 is the part's mute byte.

2. THE EVENT PROTOCOL.  `SwbtWr_QueuePostEvent` is called with
       e = record TAG        d = PAYLOAD OFFSET within that record
       a = value             w = bit mask
   e.g. `ldb e,0x48 / ldb d,0x8` sits beside `stda16 (0xFC62), xwa`, and 0xFC62 is
   exactly tag 0x48's payload+8.  Every such call site is decoded here.

PASS (the falsifiable form of the "e = tag, d = offset" claim):
wherever a literal (e,d) event site has an absolute access to 0x00F9A0..0x00FFC0 within
WINDOW source lines of it, that address must resolve to exactly that (tag, offset).
One disagreement breaks the rule.  Exits non-zero if any nearby access disagrees.

Sites whose neighbourhood still contains raw `.byte` blobs are SKIPPED and counted
separately: the converter has not decoded that stretch, so the operands there are not
evidence either way.

ONE KNOWN EXCEPTION, listed in KNOWN_EXCEPTIONS below and NOT swept under the carpet:
DrumVoice_Handler7 stores to 0xFDBA (tag 0x93 payload+4) and then posts (e=0x91, d=4).
So the event id is not *always* the storage tag -- at least once a write to one record
notifies a different one.  Recorded as a named exception rather than a tolerance, so a
NEW disagreement still fails the check.

The same queue also carries plain notifications whose (e,d) is not a panel field at all
(observed: e=0x90 d=0x10, e=0x17 d=0x1E -- both past the end of those records).  Those
are listed as "notification" and are not counted either way; they are why a blanket
"every (e,d) is in range" test would be the wrong test.

    python3 analysis/disk-format-probes/lsw_field_evidence.py            # v9 sources
    python3 analysis/disk-format-probes/lsw_field_evidence.py v7
    python3 analysis/disk-format-probes/lsw_field_evidence.py v9 --events-only
"""
import collections, os, re, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
ROM_PATH = os.path.join(REPO, 'original_ROMs', 'kn5000_v7_program.rom')
LOAD = 0xE00000
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))
LO, HI = 0xF9A0, 0xFFC0

RE_NUM = re.compile(r'\(\s*(0x[0-9a-fA-F]+|\d+)\s*\)')
RE_LBL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
RE_MN = re.compile(r'^\s*([a-z][a-z0-9_]*)')
RE_LDB = re.compile(r'^\s*ldb\s+([edaw])\s*,\s*(0x[0-9a-fA-F]+|\d+)\s*$')

# (event tag, event offset, routine) pairs that provably do NOT name the record they
# store into.  See the module docstring.
KNOWN_EXCEPTIONS = {(0x91, 4, 'DrumVoice_Handler7')}


def schema():
    rom = open(ROM_PATH, 'rb').read()
    recs = []
    for addr, count, base in TABLES:
        for i in range(count):
            o = addr - LOAD + 10 * i
            off, _ptr = struct.unpack_from('<II', rom, o)
            tag, ln = rom[o + 8], rom[o + 9]
            recs.append((base + off, tag, 0 if tag == 0xFF else ln))
    return recs


def locate(recs, a):
    for st, tag, ln in recs:
        if st <= a <= st + 1 + ln:
            return tag, a - st - 2   # negative = the tag/len header bytes
    return None


def kind(op):
    if op.startswith('lda'):
        return 'LEA'
    if op.startswith('st'):
        return 'W'
    if op.startswith(('ld', 'cp', 'bit')):
        return 'R'
    return 'RMW'


def sources(ver):
    root = os.path.join(REPO, ver)
    for dp, _dn, fn in os.walk(root):
        for f in sorted(fn):
            if f.endswith('.s'):
                yield os.path.join(dp, f)


def main():
    ver = 'v9'
    for a in sys.argv[1:]:
        if not a.startswith('-'):
            ver = a
    events_only = '--events-only' in sys.argv
    recs = schema()
    tags = {t: ln for _s, t, ln in recs}

    acc = collections.defaultdict(list)
    events = []
    bad = []

    for path in sources(ver):
        rel = os.path.relpath(path, REPO)
        cur = '?'
        pend = {}
        for i, line in enumerate(open(path, errors='replace'), 1):
            m = RE_LBL.match(line)
            if m:
                cur = m.group(1)
            code = line.split(';')[0].rstrip()

            mb = RE_LDB.match(code)
            if mb:
                pend[mb.group(1)] = int(mb.group(2), 0)
            elif 'SwbtWr_QueuePostEvent' in code and 'call' in code:
                if 'e' in pend and 'd' in pend:
                    tag, off = pend['e'], pend['d']
                    good = tag in tags and 0 <= off < max(tags[tag], 1)
                    events.append((tag, off, pend.get('a'), pend.get('w'), cur, rel, i, good))
                pend = {}
            elif code.strip() and not RE_LDB.match(code) and 'ldb' not in code and 'call' in code:
                pend = {}

            m0 = RE_MN.match(code)
            if not m0:
                continue
            op = m0.group(1)
            for mn in RE_NUM.finditer(code):
                v = int(mn.group(1), 0)
                if LO <= v <= HI:
                    r = locate(recs, v)
                    if r:
                        acc[r].append((kind(op), op, cur, rel, i))
                    break

    if not events_only:
        print('######## absolute accesses in 0x%04X..0x%04X, by (tag, payload offset) ########' % (LO, HI))
        for (tag, off) in sorted(acc):
            L = acc[(tag, off)]
            ks = collections.Counter(x[0] for x in L)
            rs = collections.Counter(x[2] for x in L)
            label = 'HEADER' if off < 0 else '+%d' % off
            print('tag %02X %-8s %-28s %s' % (tag, label, dict(ks),
                                              ', '.join('%s%s' % (r, 'x%d' % c if c > 1 else '')
                                                        for r, c in rs.most_common(5))))
        print()

    print('######## SwbtWr_QueuePostEvent(e=tag, d=payload offset) call sites ########')
    for tag, off, a, w, rout, rel, i, good in sorted(events, key=lambda e: (e[0], e[1], e[5], e[6])):
        print('tag %02X  +%-3d  value=%-6s mask=%-6s %-38s %s:%d%s'
              % (tag, off,
                 ('0x%02X' % a) if a is not None else '(reg)',
                 ('0x%02X' % w) if w is not None else '(reg)',
                 rout, rel, i, '' if good else '   *** OUT OF RECORD ***'))
    print()

    # cross-check: an absolute access within WINDOW lines of an (e,d) event site must
    # resolve to the same (tag, offset).  Line locality, not routine locality: a long
    # routine legitimately touches several different fields.
    WINDOW = 12
    by_line = collections.defaultdict(list)
    unconverted = collections.defaultdict(set)
    for path in sources(ver):
        rel = os.path.relpath(path, REPO)
        for li, line in enumerate(open(path, errors='replace'), 1):
            if line.lstrip().startswith('.byte'):
                unconverted[rel].add(li)
    for (tag, off), L in acc.items():
        if off >= 0:
            for _k, _op, _rout, rel, i in L:
                by_line[rel].append((i, tag, off))
    checked = agree = skipped = 0
    skiplist = []
    known = []
    for tag, off, _a, _w, rout, rel, i, good in events:
        if not good:
            continue
        near = [(t, o) for (li, t, o) in by_line.get(rel, ()) if abs(li - i) <= WINDOW]
        if not near:
            continue
        if any(abs(li - i) <= WINDOW for li in unconverted.get(rel, ())):
            skipped += 1
            skiplist.append((tag, off, rout, rel, i))
            continue
        checked += 1
        if (tag, off) in near:
            agree += 1
        elif (tag, off, rout) in KNOWN_EXCEPTIONS:
            known.append((tag, off, rout, rel, i, near))
        else:
            bad.append((tag, off, rout, rel, i))

    notif = [e for e in events if not e[7]]
    print('%s: %d event sites decoded; %d land inside a schema record, %d are notifications'
          % (ver, len(events), len(events) - len(notif), len(notif)))
    for tag, off, _a, _w, rout, rel, i, _g in notif:
        print('   notification: e=0x%02X d=0x%02X  %s (%s:%d)' % (tag, off, rout, rel, i))
    print('cross-check: %d event sites have an absolute access within %d lines; %d agree on (tag, offset)'
          % (checked, WINDOW, agree))
    if known:
        print('%d known exception(s) -- event names a different record than the store:' % len(known))
        for t, o, rout, rel, i, near in known:
            print('   e=0x%02X d=0x%02X posted by %s (%s:%d), nearby access is %s'
                  % (t, o, rout, rel, i, ' '.join('tag %02X +%d' % n for n in sorted(set(near)))))
    if skiplist:
        print('%d site(s) skipped -- neighbourhood still holds raw .byte blobs:' % skipped)
        for t, o, rout, rel, i in skiplist:
            print('   e=0x%02X d=0x%02X  %s (%s:%d)' % (t, o, rout, rel, i))
    if bad:
        print('FAIL: event and absolute access disagree at:')
        for b in bad:
            print('  tag 0x%02X off %d in %s (%s:%d)' % b)
        return 1
    print('PASS: "e = tag, d = payload offset" holds at every site where it can be cross-checked.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
