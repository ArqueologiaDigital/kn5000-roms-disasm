#!/usr/bin/env python3
"""The panel parameter-id namespace is a LAW, not a list -- and what that names.

QUESTION ANSWERED
-----------------
`README-lsw-nonpart-records.md` closes with a "Still unidentified" section, and
`README-lsw-leftover-records.md` records the parameter-descriptor table as "the general
tool this pass found" -- while scanning only ids `0x4000..0x4FFF`.  That window was
already known to have cost one wrong conclusion: the drawbar records `0x44/0x45/0x46`
were declared "not UI-editable" because no id was found for them, and their 48 ids turned
out to sit at `0x8200/0x8600/0x8A00`.

This probe redoes the census over the WHOLE id space and asserts what comes out.

WHAT IT FINDS
-------------
1.  **The part namespace law.**  For every one of the 25 per-part records, tag `T` in
    `0x00..0x18`, the parameter ids that name it live in exactly one namespace and it is

        namespace(T) = 0x8000 + 0x400 * T

    with no exception and no gap: `0x00`->`0x80xx`, `0x01`->`0x84xx`, ... `0x18`->`0xE0xx`.

    And the law is finer than that.  **Every part carries the same ten field constants** --

        id = 0x8000 + 0x400 * tag + k,   k in {07, 08, 0A, 20, 40, 5B, 5D, 5E, 80, 81}

    (parts 0x01, 0x02 and 0x03 have an eleventh, `k = 00`.)  A parameter id in that range
    therefore decodes on sight: `(id - 0x8000) >> 10` is the part tag and `id & 0x3FF` is
    which field of it.

2.  **The drawbar records are parts 0, 1 and 2 -- arithmetically.**

        tag 0x44 -> 0x8200 = namespace(0x00) + 0x200
        tag 0x45 -> 0x8600 = namespace(0x01) + 0x200
        tag 0x46 -> 0x8A00 = namespace(0x02) + 0x200

    16 ids each, 48 in all, and the three records' `(k, offset, mask)` triples are
    IDENTICAL -- nibble pairs at `+1..+6`, `+7` split `0x0F / 0x10 / 0x20`, a nibble at
    `+8`; `+0` and `+9` carry no parameter.

    `README-lsw-drawbar-records.md` identified them as the drawbar registration of
    RIGHT 1 / RIGHT 2 / LEFT, and assigned the three parts from the *count* of records
    ("the set of three WAS the clue -- three parts").  The namespace arithmetic says the
    same thing without counting anything: each record is a `+0x200` sub-namespace of a
    specific part's id block, and those parts are 0, 1 and 2.

3.  **Tag `0x9A` still has no parameter id -- now with the window stated as ALL of it.**
    The old claim was made inside `0x4000..0x4FFF`.  Over `0x0001..0xFFFF` it still holds,
    and the census is demonstrably not blind: its immediate neighbours in block 1 collect
    15 (`0x92`), 27 (`0x99`) and 29 (`0x98`) ids in the same run.

4.  **Tag `0x92` is a fully UI-editable 15-parameter record**, ids `0x4280..0x428E`, whose
    (offset, mask) pairs TILE all fourteen payload bytes with no gap and no overlap:
    `+0x00` and `+0x02..+0x0D` as whole bytes, `+0x01` split into a `0x80` flag and a
    `0x0F` value.  `README-lsw-nonpart-records.md` has it as "13 consecutive bytes read one
    at a time by `SendEpilogue_Data`", i.e. shape only.  It is now known to be a screen's
    worth of parameters; what the screen is, is still not known.

5.  The full list of schema tags that have **no** parameter id anywhere in the id space:
    `19 49 68 71 72 78 90 9A` and the whole `C0..D4 D7` companion family.

METHOD
------
A descriptor is `u32 param-id | u8 tag | u8 offset | u16 mask | ...`, 18 bytes per entry.
A candidate is kept only if

  * the id is in `0x0001..0xFFFF`,
  * `tag` is a schema tag and `offset` is inside that record's payload,
  * the mask is one contiguous run of bits in `0x01..0xFF`,
  * **there is another valid candidate exactly 0x12 bytes before or after it** -- i.e. it
    is part of a run, which is what a table looks like and what a lucky stretch of code
    does not, and
  * **the id occurs exactly once in the whole census** -- a parameter id names one field;
    an id that turns up at twenty addresses is a byte pattern, not an id.

Those last two rules are what make a full-window scan usable.  Without the run rule the
census picks up coincidences out of the code segment (`0x8D4E -> tag 0x68 +0 mask 0x40` at
`0xFB6C4B`, which would have "refuted" the tag-`0x68` finding on the strength of four
random bytes inside an instruction).  Without the uniqueness rule it picks up two data
tables that decode as descriptors by accident -- `0xF800 -> tag 0x00 +0 mask 0xF8` at
twenty addresses in `0xE86A..0xE8A0`, and `0x0031 -> tag 0x63 +0 mask 0x01` at thirteen
addresses in `0xEE50..0xEE58` -- and the part namespace law below acquires five spurious
exceptions.

The whole census is byte-identical on v7, v9 and v10, which the probe asserts.

USAGE
    python3 analysis/disk-format-probes/lsw_param_namespace_map.py
    python3 analysis/disk-format-probes/lsw_param_namespace_map.py --quiet
    python3 analysis/disk-format-probes/lsw_param_namespace_map.py --dump    # the census
"""
import os, struct, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROMDIR = os.path.join(HERE, '..', '..', 'original_ROMs')
LOAD = 0xE00000
REVS = ('v7', 'v9', 'v10')

# The panel schema: two ROM tables of 10-byte entries {u32 offset, u32 fieldlist, u8 tag,
# u8 payload length}, relative to the two TLV block bases.  Same addresses in all three
# revisions (they are data); the probe fails if a table stops decoding.
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))
ENTRY = 0x12          # bytes per parameter-descriptor entry

PARTS = list(range(0x00, 0x19))          # the 25 per-part records
DRAWBARS = {0x44: 0x00, 0x45: 0x01, 0x46: 0x02}

# The census, frozen.  {tag: (number of distinct ids, sorted namespace list)}
EXPECTED = {
    0x00: (11, [0x40, 0x80]),
    0x01: (11, [0x84]), 0x02: (11, [0x88]), 0x03: (12, [0x00, 0x8C]),
    0x04: (10, [0x90]), 0x05: (10, [0x94]), 0x06: (10, [0x98]), 0x07: (10, [0x9C]),
    0x08: (11, [0x00, 0xA0]), 0x09: (10, [0xA4]), 0x0A: (10, [0xA8]), 0x0B: (10, [0xAC]),
    0x0C: (12, [0x00, 0x02, 0xB0]), 0x0D: (11, [0x01, 0xB4]),
    0x0E: (10, [0xB8]), 0x0F: (10, [0xBC]),
    0x10: (10, [0xC0]), 0x11: (10, [0xC4]), 0x12: (10, [0xC8]), 0x13: (10, [0xCC]),
    0x14: (10, [0xD0]), 0x15: (10, [0xD4]), 0x16: (10, [0xD8]), 0x17: (10, [0xDC]),
    0x18: (10, [0xE0]),
    0x43: (3, [0x41]),
    0x44: (16, [0x82]), 0x45: (16, [0x86]), 0x46: (16, [0x8A]),
    0x47: (20, [0x2D]),
    0x48: (1, [0x42]),
    0x60: (3, [0x40]),
    0x61: (1, [0x49]), 0x63: (7, [0x00, 0x4B]), 0x64: (1, [0x4C]),
    0x65: (1, [0x4D]), 0x66: (1, [0x4E]),
    0x70: (6, [0x2A, 0x40, 0x41, 0x42]),
    0x80: (30, [0x21, 0x22, 0x50]),
    0x91: (2, [0x00]),
    0x92: (15, [0x42]),
    0x93: (2, [0x01]),
    0x98: (29, [0x03, 0x04, 0x29, 0x2C, 0x40, 0xE8]),
    0x99: (27, [0x28]),
}
# The part id blocks span 0x8000..0xE3FF (25 parts x 0x400).  Exactly three non-part tags
# have a namespace inside that span -- the drawbars.  Tag 0x98's stray 0xE8xx pair sits
# ABOVE it (0xE807/0xE808 at 0xEDE96C, 0xEDE97E) and so does not clash with the law.
PART_BLOCK = (0x8000, 0xE400)

NO_ID = [0x19, 0x49, 0x68, 0x71, 0x72, 0x78, 0x90, 0x9A,
         0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB,
         0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD7]

# The ten field constants every part record carries (parts 01/02/03 add k = 0x00).
PART_K = [0x07, 0x08, 0x0A, 0x20, 0x40, 0x5B, 0x5D, 0x5E, 0x80, 0x81]
PART_K_EXTRA = {0x01, 0x02, 0x03}

# The three drawbar records' (k, offset, mask), which must be the same for all three.
DRAWBAR_FIELDS = [(0x21, 8, 0x0F), (0x80, 3, 0x0F), (0x81, 3, 0xF0), (0x82, 4, 0x0F),
                  (0x83, 4, 0xF0), (0x84, 5, 0x0F), (0x85, 5, 0xF0), (0x86, 6, 0x0F),
                  (0x87, 6, 0xF0), (0x88, 7, 0x0F), (0x93, 2, 0x0F), (0x94, 2, 0xF0),
                  (0xC0, 7, 0x10), (0xC1, 7, 0x20), (0xCB, 1, 0xF0), (0xCC, 1, 0x0F)]

# Tag 0x92's fifteen ids, as (id, offset, mask).
TAG92 = [(0x4280, 0x01, 0x80), (0x4281, 0x00, 0xFF), (0x4282, 0x01, 0x0F)] + \
        [(0x4283 + k, 0x02 + k, 0xFF) for k in range(12)]

FAILS = []
def check(cond, msg):
    if not cond:
        FAILS.append(msg)
    return cond


def load(rev):
    with open(os.path.join(ROMDIR, 'kn5000_%s_program.rom' % rev), 'rb') as f:
        return f.read()


def schema(d):
    """{tag: payload length} and [(tag, payload address, length)] from the two ROM tables."""
    lens, recs = {}, []
    for addr, count, base in TABLES:
        n = 0
        for i in range(count):
            o = addr - LOAD + 10 * i
            eoff, fptr, tag, ln = struct.unpack_from('<IIBB', d, o)
            if tag == 0xFF:
                break
            lens[tag] = ln
            recs.append((tag, base + eoff + 2, ln))
            n += 1
        if n == 0:
            return None, None
    return lens, recs


def contiguous(m):
    lo = (m & -m).bit_length() - 1
    return ((m >> lo) & ((m >> lo) + 1)) == 0


def census(d, lens):
    """{tag: [(id, offset, mask, address)]} over the WHOLE id space, run-of-2 rule."""
    def valid(i):
        if i < 0 or i + ENTRY > len(d):
            return None
        pid = struct.unpack_from('<I', d, i)[0]
        if pid == 0 or pid > 0xFFFF:
            return None
        tag, off = d[i + 4], d[i + 5]
        mask = struct.unpack_from('<H', d, i + 6)[0]
        if tag not in lens or off >= lens[tag]:
            return None
        if not (0 < mask <= 0xFF) or not contiguous(mask):
            return None
        return pid, tag, off, mask

    out = collections.defaultdict(list)
    for i in range(len(d) - ENTRY):
        v = valid(i)
        if not v:
            continue
        if not (valid(i - ENTRY) or valid(i + ENTRY)):
            continue
        pid, tag, off, mask = v
        out[tag].append((pid, off, mask, LOAD + i))
    # an id names one field: drop every id that turns up more than once
    seen = collections.Counter(h[0] for v in out.values() for h in v)
    return {tag: [h for h in v if seen[h[0]] == 1]
            for tag, v in out.items() if any(seen[h[0]] == 1 for h in v)}


def run(rev, verbose):
    d = load(rev)
    t = 'T[%s]' % rev
    lens, recs = schema(d)
    if not check(lens is not None and len(lens) >= 70,
                 '%s T0: the panel schema tables did not decode' % t):
        return None
    c = census(d, lens)

    # T1 -- the census, whole
    got = {tag: (len({h[0] for h in v}), sorted({h[0] >> 8 for h in v}))
           for tag, v in c.items()}
    check(got == EXPECTED, '%s T1: census differs from the frozen one\n    only in: %s'
          % (t, [(hex(k), got.get(k), EXPECTED.get(k))
                 for k in set(got) | set(EXPECTED) if got.get(k) != EXPECTED.get(k)]))

    # T2 -- the part namespace law
    def inblock(tag):
        return sorted({n for n in got.get(tag, (0, []))[1]
                       if PART_BLOCK[0] <= n << 8 < PART_BLOCK[1]})
    for T in PARTS:
        want = (0x8000 + 0x400 * T) >> 8
        check(inblock(T) == [want],
              '%s T2: part tag %#04x has part-block namespaces %s, expected [%#04x]'
              % (t, T, ['%#04x' % n for n in inblock(T)], want))
    highs = [(0x8000 + 0x400 * T) >> 8 for T in PARTS]
    check(len(set(highs)) == len(highs), '%s T2: the namespace law collides with itself' % t)
    # and NOTHING else lives in the part block except the three drawbar records
    intruders = sorted(tag for tag in got if tag not in PARTS and inblock(tag))
    check(intruders == sorted(DRAWBARS),
          '%s T2: tags %s hold a namespace inside the part id block, expected only the '
          'three drawbar records' % (t, ['%#04x' % x for x in intruders]))
    # T2b -- and every part carries the SAME field constants
    for T in PARTS:
        base = 0x8000 + 0x400 * T
        ks = {p - base for p, _, _, _ in c[T] if (p & 0xFC00) == base}
        check(set(PART_K) <= ks, '%s T2b: part %#04x is missing field constants %s'
              % (t, T, ['%#04x' % x for x in sorted(set(PART_K) - ks)]))
        extra = ks - set(PART_K)
        check(extra == ({0x00} if T in PART_K_EXTRA else set()),
              '%s T2b: part %#04x carries unexpected field constants %s'
              % (t, T, ['%#04x' % x for x in sorted(extra)]))

    # T3 -- the drawbars sit at part-namespace + 0x200
    for tag, part in DRAWBARS.items():
        ns = got.get(tag, (0, []))[1]
        want = (0x8000 + 0x400 * part + 0x200) >> 8
        check(ns == [want], '%s T3: drawbar tag %#04x namespace %s, expected [%#04x] '
              '(= part %#04x + 0x200)' % (t, tag, ['%#04x' % n for n in ns], want, part))
        check(got[tag][0] == 16, '%s T3: drawbar tag %#04x has %d ids, expected 16'
              % (t, tag, got[tag][0]))
    check(sum(got[x][0] for x in DRAWBARS) == 48,
          '%s T3: the three drawbar records carry %d ids, expected 48'
          % (t, sum(got[x][0] for x in DRAWBARS)))
    # T3b -- and the three carry the SAME fields, at the same offsets and masks
    for tag, part in DRAWBARS.items():
        base = 0x8000 + 0x400 * part + 0x200
        fields = sorted({(p - base, o, mk) for p, o, mk, _ in c[tag]})
        check(fields == sorted(DRAWBAR_FIELDS),
              '%s T3b: drawbar tag %#04x fields %s != the common set'
              % (t, tag, [('%#04x' % a, b, '%#04x' % mk) for a, b, mk in fields]))

    # T4 -- the tags with no id at all, and the proof that the census can see
    check(sorted(set(lens) - set(c)) == NO_ID,
          '%s T4: the no-id set is %s, expected %s'
          % (t, ['%02X' % x for x in sorted(set(lens) - set(c))],
             ['%02X' % x for x in NO_ID]))
    for neighbour, n in ((0x92, 15), (0x99, 27), (0x98, 29)):
        check(got.get(neighbour, (0,))[0] == n,
              '%s T4: the positive control for tag 0x9A is gone -- tag %#04x collects %s '
              'ids, expected %d' % (t, neighbour, got.get(neighbour, (0,))[0], n))

    # T5 -- tag 0x92's fifteen ids tile its fourteen payload bytes exactly
    ids92 = sorted({(p, o, m) for p, o, m, _ in c[0x92]})
    check(ids92 == sorted(TAG92), '%s T5: tag 0x92 ids %s != %s'
          % (t, [(hex(a), hex(b), hex(cc)) for a, b, cc in ids92],
             [(hex(a), hex(b), hex(cc)) for a, b, cc in sorted(TAG92)]))
    cover = collections.defaultdict(int)
    for _, o, m in ids92:
        check(cover[o] & m == 0, '%s T5: tag 0x92 fields overlap at +%#x' % (t, o))
        cover[o] |= m
    check(sorted(cover) == list(range(0, lens[0x92])),
          '%s T5: tag 0x92 ids cover offsets %s, its payload is %d bytes'
          % (t, sorted(cover), lens[0x92]))
    check(cover[0x01] == 0x8F, '%s T5: +1 is covered %#x, expected 0x8f (0x80 | 0x0f)'
          % (t, cover[0x01]))

    if verbose:
        print('  [%s] %d schema tags, %d with parameter ids, %d without'
              % (rev, len(lens), len(c), len(lens) - len(c)))
        print('       part namespace law 0x8000 + 0x400*T holds for all %d parts; drawbars '
              'at +0x200 of parts 0/1/2' % len(PARTS))
    return got


def main(argv):
    quiet = '--quiet' in argv
    dump = '--dump' in argv
    last = None
    for rev in REVS:
        got = run(rev, not quiet)
        if last is not None:
            check(got == last, 'census differs between revisions')
        last = got
    if dump and last:
        for tag in sorted(last):
            n, ns = last[tag]
            print('tag %02X : %3d ids   namespaces %s' % (tag, n, ['%02X' % x for x in ns]))
        print('no parameter id at all: %s' % ' '.join('%02X' % x for x in NO_ID))
    if FAILS:
        print('FAIL (%d)' % len(FAILS))
        for m in FAILS:
            print('  ' + m)
        return 1
    print('PASS')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
