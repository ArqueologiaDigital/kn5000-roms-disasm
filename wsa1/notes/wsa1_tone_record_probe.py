#!/usr/bin/env python3
"""
QUESTION THIS ANSWERS
=====================
"Is the byte the tone-editor writes at element-block offset N really the
parameter the UI calls it?"  -- i.e. it supplies the one INDEPENDENT check
this project had for the element-block layout: take the 81-byte element
blocks out of prom_d's factory tone records and see whether a column that
CODE treats as a unit also behaves like the UI field it is supposed to be.

It answers, concretely:
  * where prom_d's melodic tone records are and how big they are;
  * what every one of the 81 element-block byte columns looks like across the
    factory set (range, distinct values, bit-7 usage);
  * whether element offsets +0x02/+0x03 name an entry of prom_d's 307-entry
    WAVE CATALOGUE -- the check that grades the whole layout.

RUN
===
    cd <tree>/wsa1
    python3 notes/wsa1_tone_record_probe.py --records   # the record chain
    python3 notes/wsa1_tone_record_probe.py --columns   # 81 column signatures
    python3 notes/wsa1_tone_record_probe.py --wave      # the +0x02/+0x03 join
    python3 notes/wsa1_tone_record_probe.py --wavesel   # the 43 wave-select columns
    python3 notes/wsa1_tone_record_probe.py --twins     # the MAIN/SUB null
    python3 notes/wsa1_tone_record_probe.py --selftest  # assertions, 0 = OK

WHAT IT READS
=============
original_ROMs/wsa1_prom_d.bin (the tone database), wsa1_prom_b.ic13 (the UI's
resonator-name table) and wsa1_prom_c.ic28 (the two instruction sites the
argument rests on).  No .s file.

THE THREE FACTS IT RESTS ON, each re-read from a ROM here
=========================================================
1. A melodic tone record is 217 + 124*N bytes: a 217-byte head, then N
   81-byte ELEMENT BLOCKS, then N 43-byte wave-select records.  81 and 217
   are `ld C,0x51` / `add XBC,0x000000d9` in ToneRec_GetElementBlock
   (0xFB4356..) and Part_GetElementBlock_Unpacked (0xFB42F8..).
2. The tone NAME is at record offset 0 and is 17 bytes: ToneQuery_ReplyToneName
   (0xFC0303) sets its loop bound to 0x11 at 0xFC0322 and copies
   (tone_record + i) for i = 0..16.  So a record BEGINS with its name, which
   is what lets this script find the records at all.
3a. The tone-editor's WAVE-SELECT-record parameter write arm sub_FBC958
   (0xFBC958, ToneMsg_Dispatch write arm 4) stores the message's value byte at
   `0x0087D2 + 0x21D + 43*((param >> 6) & 3) + (param & 0x3F)` and then
   dispatches a 43-entry computed goto guarded by `cp BC,0x002a`.  So for that
   arm THE PARAMETER NUMBER IS THE BYTE OFFSET 0..42 in the 43-byte record and
   the element index rides in bits 7:6.  This is the record the 0x00104000
   device is fed from -- it reads only its +0x0B and +0x0D..+0x2A.
3b. The tone-editor's element-parameter write arm sub_FBC39D (0xFBC39D) stores
   the message's value byte at `0x0087D2 + 0xD9 + 81*element + (param & 0x7F)`
   and then dispatches an 81-entry computed goto guarded by `cp BC,0x0050`.
   So THE PARAMETER NUMBER IS THE BYTE OFFSET, and offsets +0x02 and +0x03
   share one arm (0xFBC3FC reads element+0xDB and element+0xDC).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

HEAD = 217          # 0xD9
ELEM = 81           # 0x51
WSEL = 43           # 0x2B
SIZES = {HEAD + (ELEM + WSEL) * n: n for n in (1, 2, 3, 4)}
WAVE_TABLE = 0x46D6A    # prom_d file offset, 16 bytes per entry
RESO_TABLE = 0x03241    # prom_b file offset, 64 x 8 ASCII


def rom(name):
    with open(os.path.join(ROOT, "original_ROMs", name), "rb") as f:
        return f.read()


def name_candidates(d):
    """Every 16-byte window that is printable ASCII with >= 6 letters.

    A tone record starts with its 17-byte name (fact 2), so every record start
    is in here.  So is a lot of other text -- the chain step below is what
    removes it, and --records prints both counts so the filter is visible.
    """
    out, i = [], 0
    while i < len(d) - 16:
        w = d[i:i + 16]
        if all(0x20 <= c < 0x7F for c in w):
            if sum(1 for c in w if 65 <= c <= 90 or 97 <= c <= 122) >= 6:
                out.append((i, w.decode()))
                i += 16
                continue
        i += 1
    return out


def records(d):
    """Name candidates whose distance to the NEXT candidate is a legal record
    size.  Nothing else is assumed: the record size is read off the data."""
    cand = name_candidates(d)
    out = []
    for j in range(len(cand) - 1):
        o, n = cand[j]
        st = cand[j + 1][0] - o
        if st in SIZES:
            out.append((o, n.strip(), SIZES[st], st))
    return cand, out


def elements(d, recs):
    for o, n, N, _st in recs:
        for e in range(N):
            yield n, e, d[o + HEAD + ELEM * e:o + HEAD + ELEM * (e + 1)]


def wave_selects(d, recs):
    """(tone name, element index, the 43-byte wave-select record)."""
    for o, n, N, _st in recs:
        for e in range(N):
            b = o + HEAD + ELEM * N + WSEL * e
            yield n, e, d[b:b + WSEL]


def wsel_sets(d, recs):
    rows = [r for _n, _e, r in wave_selects(d, recs)]
    return rows, [set(r[k] for r in rows) for k in range(WSEL)]


# The MAIN half and the SUB half of the wave-select tail, as the firmware's own
# case groups in the 43-entry table cut it: offsets 21..30 and 31..42.  The map
# below pairs them; 33 and 36 are the two SUB-only parameters and have no
# MAIN counterpart, which is the asymmetry the naming argument turns on.
MAIN = [21, 22, 23, 24, 25, 26, 27, 28, 29, 30]
SUB = [31, 32, 34, 35, 37, 38, 39, 40, 41, 42]
SUB_ONLY = [33, 36]


def cmd_wavesel():
    d = rom("wsa1_prom_d.bin")
    _c, recs = records(d)
    rows, S = wsel_sets(d, recs)
    print("43 wave-select-record byte columns over %d factory records" % len(rows))
    print("param  n  bit7   min  max   values")
    for k in range(WSEL):
        v = [r[k] for r in rows]
        s = sorted(S[k])
        print("%5d %3d %5d %5d %4d   %s" %
              (k, len(s), sum(1 for x in v if x & 0x80), min(v), max(v),
               " ".join(str(x) for x in s[:16]) + (" ..." if len(s) > 16 else "")))


def cmd_twins():
    d = rom("wsa1_prom_d.bin")
    _c, recs = records(d)
    rows, S = wsel_sets(d, recs)

    def twin(i, j):
        return S[i] <= S[j] and len(S[j] - S[i]) <= 1

    allp = [(i, j) for i in range(WSEL) for j in range(WSEL) if i != j and twin(i, j)]
    hit = [(a, b) for a, b in zip(MAIN, SUB) if twin(a, b)]
    p = len(allp) / float(WSEL * (WSEL - 1))
    print("CLAIM: wave-select parameters 21..30 and 31..42 are TWO INSTANCES OF")
    print("       ONE PARAMETER SET (the firmware's own case groups), and the")
    print("       SUB instance carries two extra parameters, 33 and 36.")
    print()
    print("  the claimed MAIN -> SUB map scores %d of %d" % (len(hit), len(MAIN)))
    for a, b in zip(MAIN, SUB):
        print("    %2d -> %2d  %s   SUB adds %s, MAIN adds %s"
              % (a, b, "twin" if twin(a, b) else "NO  ",
                 sorted(S[b] - S[a]), sorted(S[a] - S[b])))
    print()
    print("NULL: 'set(i) is a subset of set(j) and set(j) has at most one extra")
    print("      value' holds for %d of the %d ORDERED column pairs in the same"
          % (len(allp), WSEL * (WSEL - 1)))
    print("      record, so p = %.4f for an arbitrary pair.  Ten independent" % p)
    print("      draws give p^10 = %.3g; %d or more of 10 is far rarer still."
          % (p ** 10, len(hit)))
    print("      The claimed map accounts for %d of the %d twins that exist."
          % (len(hit), len(allp)))
    print()
    print("SUB-ONLY parameters, for the asymmetry the naming rests on:")
    for k in SUB_ONLY:
        from collections import Counter
        c = Counter(r[k] for r in rows)
        print("  param %2d (+0x%02X): %s" % (k, k, dict(sorted(c.items()))))


def wave_table(d):
    """(b13, b14, b15, name) per 16-byte entry, until the name stops being
    printable.  The three trailing bytes are the catalogue's own key."""
    out, i = [], 0
    while True:
        e = d[WAVE_TABLE + 16 * i:WAVE_TABLE + 16 * i + 16]
        if len(e) < 16 or not all(0x20 <= c < 0x7F for c in e[:13]):
            break
        out.append((e[13], e[14], e[15], e[:13].decode().strip()))
        i += 1
    return out


def cmd_records():
    d = rom("wsa1_prom_d.bin")
    cand, recs = records(d)
    print("16-byte printable name candidates in prom_d : %d" % len(cand))
    print("of those, chained by a legal record size    : %d" % len(recs))
    from collections import Counter
    c = Counter(N for _o, _n, N, _s in recs)
    for n in sorted(c):
        print("   %d element(s)  size %4d  count %3d" % (n, HEAD + (ELEM + WSEL) * n, c[n]))
    print("total element blocks: %d" % sum(N for _o, _n, N, _s in recs))
    print()
    for o, n, N, st in recs[:12]:
        print("  0x%05X  %-18s N=%d size=%d" % (o, n, N, st))


def cmd_columns():
    d = rom("wsa1_prom_d.bin")
    _c, recs = records(d)
    cols = {k: [] for k in range(ELEM)}
    for _n, _e, eb in elements(d, recs):
        for k in range(ELEM):
            cols[k].append(eb[k])
    print("81 element-block byte columns over %d factory element blocks" % len(cols[0]))
    print("off   n  bit7   min  max   first values")
    for k in range(ELEM):
        v = cols[k]
        s = sorted(set(v))
        print("0x%02X %3d %5d %5d %4d   %s" %
              (k, len(s), sum(1 for x in v if x & 0x80), min(v), max(v),
               " ".join(str(x) for x in s[:14]) + (" ..." if len(s) > 14 else "")))


def cmd_wave():
    d = rom("wsa1_prom_d.bin")
    _c, recs = records(d)
    tab = wave_table(d)
    key = {}
    for b13, b14, b15, nm in tab:
        key.setdefault((b14, b15), nm)
    hit = miss = 0
    shown = 0
    for n, e, eb in elements(d, recs):
        k = (eb[2], eb[3])
        if k in key:
            hit += 1
            if shown < 24:
                print("  %-18s element %d   +0x02,+0x03 = %3d,%3d  ->  %s"
                      % (n, e, eb[2], eb[3], key[k]))
                shown += 1
        else:
            miss += 1
    print()
    print("wave catalogue entries at prom_d 0x%05X, 16-byte stride : %d" % (WAVE_TABLE, len(tab)))
    print("distinct (b14,b15) keys                                  : %d" % len(key))
    print("element blocks whose (+0x02,+0x03) IS such a key          : %d" % hit)
    print("element blocks whose (+0x02,+0x03) is NOT                 : %d" % miss)
    print()
    print("NULL: the key space is 256 x 256 = 65536 pairs and the catalogue")
    print("      covers %d of them, so a byte pair drawn at random lands in it" % len(key))
    print("      with probability %.5f.  Getting %d of %d is (%.5f)^%d, which"
          % (len(key) / 65536.0, hit, hit + miss, len(key) / 65536.0, hit))
    print("      underflows every float this machine has.  The expected number")
    print("      of hits under the null is %.1f." % ((hit + miss) * len(key) / 65536.0))


def cmd_selftest():
    fails = []
    d = rom("wsa1_prom_d.bin")
    b = rom("wsa1_prom_b.ic13")
    c = rom("wsa1_prom_c.ic28")

    def cat(a):
        return a - 0xF80000

    # -- fact 1: the two size constants, read as instruction bytes ----------
    #    0xFB42F8 `ld C,0x51`, 0xFB42FF `add XBC,0x000000d9`
    if c[cat(0xFB42F8):cat(0xFB42F8) + 2] != bytes([0x23, 0x51]):
        fails.append("0xFB42F8 is not `ld C,0x51` (the 81-byte element stride)")
    if c[cat(0xFB42FF):cat(0xFB42FF) + 6] != bytes([0xE9, 0xC8, 0xD9, 0x00, 0x00, 0x00]):
        fails.append("0xFB42FF is not `add XBC,0x000000d9` (the 217-byte head)")
    # -- fact 2: the name length, 0xFC0322 `ld (XIZ+0xfa),0x0011` -----------
    if c[cat(0xFC0322):cat(0xFC0322) + 5] != bytes([0xBE, 0xFA, 0x02, 0x11, 0x00]):
        fails.append("0xFC0322 is not `ld (XIZ+0xfa),0x0011` (the 17-byte name)")
    # -- fact 3: the write arm --------------------------------------------
    if c[cat(0xFBC3A3):cat(0xFBC3A3) + 2] != bytes([0x23, 0x51]):
        fails.append("0xFBC3A3 is not `ld C,0x51`")
    if c[cat(0xFBC5C8):cat(0xFBC5C8) + 4] != bytes([0xD9, 0xCF, 0x50, 0x00]):
        fails.append("0xFBC5C8 is not `cp BC,0x0050` (81 parameters)")
    # the two operand loads of the +0x02/+0x03 arm: element+0xDC, element+0xDB
    if c[cat(0xFBC405):cat(0xFBC405) + 6] != bytes([0xE9, 0xC8, 0xDC, 0x00, 0x00, 0x00]):
        fails.append("0xFBC405 is not `add XBC,0x000000dc` (element +0x03)")
    if c[cat(0xFBC416):cat(0xFBC416) + 6] != bytes([0xE9, 0xC8, 0xDB, 0x00, 0x00, 0x00]):
        fails.append("0xFBC416 is not `add XBC,0x000000db` (element +0x02)")

    # -- the record chain and the wave join --------------------------------
    _cand, recs = records(d)
    nblocks = sum(N for _o, _n, N, _s in recs)
    if len(recs) < 200:
        fails.append("fewer than 200 chained tone records (%d)" % len(recs))
    tab = wave_table(d)
    if len(tab) != 307:
        fails.append("wave catalogue is %d entries, expected 307" % len(tab))
    key = set((t[1], t[2]) for t in tab)
    miss = sum(1 for _n, _e, eb in elements(d, recs) if (eb[2], eb[3]) not in key)
    if miss:
        fails.append("%d of %d element blocks miss the wave catalogue" % (miss, nblocks))
    # a named spot check that does not depend on the aggregate
    byname = {}
    for n, e, eb in elements(d, recs):
        byname[(n, e)] = eb
    for tone, elem, want in (("E.Piano 1", 0, "E.Piano 1"),
                             ("Suitcase E.P.", 0, "Suitcase E.P."),
                             ("Bell Piano", 1, "Bell Piano"),
                             ("Marimba", 0, "Marimba")):
        eb = byname.get((tone, elem))
        if eb is None:
            fails.append("tone %r element %d not found" % (tone, elem))
            continue
        got = {(t[1], t[2]): t[3] for t in tab}.get((eb[2], eb[3]))
        if got != want:
            fails.append("tone %r element %d names wave %r, expected %r"
                         % (tone, elem, got, want))
    # -- fact 3a: the wave-select write arm --------------------------------
    for addr, want, what in (
            (0xFBC96C, bytes([0xC8, 0xCC, 0xC0]), "`and W,0xc0` (the element bits)"),
            (0xFBC972, bytes([0xC8, 0xEF, 0x06]), "`srl 0x06,W`"),
            (0xFBC97A, bytes([0xCB, 0x08, 0x2B]), "`mul C,0x2b` (43-byte record)"),
            (0xFBC97F, bytes([0xE9, 0xC8, 0x1D, 0x02, 0x00, 0x00]),
             "`add XBC,0x0000021d` (the wave-select array)"),
            (0xFBC994, bytes([0xC9, 0xCC, 0x3F]), "`and A,0x3f` (the offset)"),
            (0xFBC9A3, bytes([0xB1, 0x41]), "`ld (XBC),A` (store the value byte)"),
            (0xFBCA49, bytes([0xD9, 0xCF, 0x2A, 0x00]),
             "`cp BC,0x002a` (43 parameters)")):
        if c[cat(addr):cat(addr) + len(want)] != want:
            fails.append("0x%06X is not %s" % (addr, what))
    # the 43 computed-goto entries must all point inside the routine
    ents = [int.from_bytes(c[cat(0xFBCA5D) + 4 * i:cat(0xFBCA5D) + 4 * i + 4], "little")
            for i in range(43)]
    if not all(0xFBC9BC <= v <= 0xFBCA41 for v in ents):
        fails.append("the 43 computed-goto entries are not all inside 0xFBC9BC-0xFBCA41")
    # the three case GROUPS the naming argument uses: 12..20, 21..30, 31..42
    for lo, hi in ((12, 20), (21, 30), (31, 42)):
        if len(set(ents[lo:hi + 1])) != 1:
            fails.append("parameters %d..%d are not one case group" % (lo, hi))
    if len(set(ents[k] for k in (12, 21, 31))) != 3:
        fails.append("the three case groups do not have three distinct arms")

    # -- the MAIN/SUB twin structure ---------------------------------------
    _rows, S = wsel_sets(d, recs)

    def twin(i, j):
        return S[i] <= S[j] and len(S[j] - S[i]) <= 1
    scored = sum(1 for a, b in zip(MAIN, SUB) if twin(a, b))
    if scored < 8:
        fails.append("the MAIN->SUB map scores only %d of 10" % scored)

    # -- the resonator name table -----------------------------------------
    rt = b[RESO_TABLE:RESO_TABLE + 64 * 8]
    if rt[:8] != b"ORIGINAL" or rt[63 * 8:64 * 8] != b"SPECIAL2":
        fails.append("prom_b resonator name table 0xF03241 is not ORIGINAL..SPECIAL2")

    print("wsa1_tone_record_probe.py --selftest")
    print("  chained tone records: %d   element blocks: %d   wave catalogue: %d"
          % (len(recs), nblocks, len(tab)))
    print("  FAILURES: %d" % len(fails))
    for f in fails:
        print("    " + f)
    return 1 if fails else 0


if __name__ == "__main__":
    if "--wavesel" in sys.argv:
        cmd_wavesel()
    elif "--twins" in sys.argv:
        cmd_twins()
    elif "--records" in sys.argv:
        cmd_records()
    elif "--columns" in sys.argv:
        cmd_columns()
    elif "--wave" in sys.argv:
        cmd_wave()
    elif "--selftest" in sys.argv:
        sys.exit(cmd_selftest())
    else:
        print(__doc__)
