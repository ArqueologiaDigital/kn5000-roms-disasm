#!/usr/bin/env python3
"""The code/data/fill LAYOUT of prom_a 0xFA5AEB-0xFAA000, derived from the ROM.

QUESTION IT ANSWERS
  "Which bytes of this 17,685-byte `.incbin` span are instructions, which are
   tables, and which are padding?"  Every byte of the span is assigned to
   exactly one segment, in address order, with no gaps and no overlaps.

  This is the prom_a twin of notes/prom_b_f65000_layout.py and it uses that
  file's method deliberately: CONTENT RULES FIRST, each one calibrated against a
  NULL CORPUS of instruction text the byte gate has already proven, those rules
  then acting as BARRIERS a recursive descent may not decode into.  A linear
  decode pins nothing (notes/prom_a_linear_decode_check.py records why).

WHY THIS SPAN
  notes/prom_a_module_frontier.py, re-run 2026-08-28, ranks it 2nd and 1st by
  its two measures at once -- three thunk runs point into it and nothing else:
      T_F43350-T_F43358   3 slots  0xFA835E, 0xFA8378, 0xFA60C2   extent 8,886
      T_F40744-T_F40760   8 slots  0xFA6018 .. 0xFA7E0C           extent 7,668
      T_F40714-T_F40734   3 of 9 unconverted  0xFA5B5F..0xFA5C54  extent   245
  `--frontier` re-derives that table from the ROM and from the .s.

WHAT THE SPAN TURNS OUT TO BE (run with no arguments for the byte-exact table)
  TWO modules, and the boundary between them is not the `.incbin` boundary:

    0xFA5AEB-0xFA5CB7   461 B  the TAIL of the MIDI module whose head at
        0xFA5400-0xFA5AEA is already converted.  0xFA5AEB is reached by the
        `calr` at 0xFA5A82 inside converted code (`MIDI_Fg_System`), and by
        nothing else -- no absolute `call`/`jp` anywhere in either image names
        it, which is why an absolute-site scanner sees this span as unreachable.
    0xFA5CB8-0xFA5CC5    14 B  ⚠ THE ONE HOLE.  Decodes, but the decode ends in
        a CONDITIONAL `jrl UGT,0xFAD5C5`, so it is not a routine tail and this
        file will not call it code.  Nothing reaches it.  Stated, not guessed.
    0xFA5CC6-0xFA5FFF   826 B  0x0E module padding.
    0xFA6000-0xFA6017    24 B  a six-slot ENTRY-THUNK TABLE, the same idiom as
        MIDI_EntryThunks at 0xFA5400: slot 0 is `1b ae 83 fa` (`jp 0xFA83AE`)
        and slots 1-5 are `0e 00 00 00`.  prom_b's directory names both module
        bases with a BARE pointer -- T_F40710 = 0x00FA5400, T_F40740 =
        0x00FA6000 -- and follows each with the run of live `jp` slots.
    0xFA6018-0xFA83BF          the second module: 8,079 bytes of code in ten
        segments, interleaved with eight of its own tables.
    0xFA83C0-0xFA9C77          its data zone.
    0xFA9C78-0xFA9FFF   904 B  padding, 506 bytes of 0x00 then 398 of 0x0E.

  What the second module IS, from its own tables (evidence in --selftest):
    * 0xFA83E8 is a 128-entry map MIDI CONTROLLER NUMBER -> internal index, and
      0xFA8FC8 is a 48-entry map internal index -> MIDI controller number.  They
      are inverses on all 23 of the first map's live entries (CC 0x40 -> 0,
      0 -> CC 0x40; ... CC 0x78 -> 41, 41 -> CC 0x78).  The second has TWO extra
      live entries, indices 16 and 17 -> CC 0x50 and 0x52, that the first leaves
      0xFF; that asymmetry is checked and reported, not smoothed over.
    * 0xFA7FFE is a 256-entry map whose live values are indices into the
      11-entry pointer table at 0xFA80FE, which points at the 11 twelve-byte
      records at 0xFA812A.  ⚠ Indices 8 and 9 are never selected by that map.
    * 0xFA84C8-0xFA8CC7 is 23 tables of exactly 32 records each -- 17 of stride
      3, 6 of stride 2 -- plus a 32-byte 0x00..0x1F index map.  32 is the count
      that recurs everywhere in this module.
    * 0xFA8FF8 is 800 FOUR-BYTE entries holding 16-bit RAM addresses (3,200 bytes,
      0xFA8FF8-0xFA9C78) = 25 blocks of 32 -- and ★ THE 25 BLOCKS ARE IDENTICAL.
      All 800 entries hold only 32 distinct values, 0x76AF..0x7EAF in 30 steps of
      0x40 and one of 0x80, and entry[i] == entry[i mod 32] for every i.  So THE
      ROW INDEX SELECTS NOTHING; whatever supplies a per-parameter offset, it is
      not this table, and the first draft's reading of it as "the RAM-address
      dispatch layer" of a 32-part parameter store does not follow.  The wave-7
      skeptic found this because check K tested the count, the block arithmetic,
      the first entry, the last entry and the terminator -- everything except the
      one property the READING depended on.  Now checked; see also open question 9.
      (The start is pinned too: the cycle does not continue below 0xFA8FF8, and
      the word at 0xFA9C78 is zero.)
    * 0xFA82DE is one more block of 32 at stride 0x40.  Together with the cycle
      above they tile a RAM array of 32 records of 0x40 bytes around
      0x7670-0x7EEF.
  So: a 32-part MIDI-controller / parameter store.  ⚠ That sentence is a
  READING; what is proven is the tables, their extents and the inverse pair --
  and it is WEAKER than the first draft made it sound, because the 0xFA8FF8
  table's 25 rows are the same row.  The "32 parts" is supported; the "dispatch
  layer" is not.

THE RULES, IN PRIORITY ORDER, AND THE NULL MEASURED FOR EACH
  Run `--null` for the live numbers; the corpus GROWS as rounds convert code, so
  quote it with `--rev REV` or quote the corpus size printed beside it.
  1. FILL    -- a maximal run of >= 16 bytes of 0x0E.  0x0E is `ret`, so short
     runs are ordinary inter-routine padding and stay inside a code segment.
  2. ZERO    -- a maximal run of >= 16 bytes of 0x00.  0x00 is `nop`; the same
     argument applies and the threshold is measured, not assumed.
  3. PTRTAB  -- >= 3 consecutive 4-byte LE words all inside 0x00F80000-0x01000000.
  4. RAMTAB  -- >= 4 consecutive 4-byte LE words in 0x0001-0xFFFF: 16-bit RAM
     addresses stored one per long word.
  5. IDENT   -- >= 12 bytes with byte[k] == byte[0]+k and no wrap past 0xFF.
  6. RECARR  -- a stride-2/3/4 RECORD ARRAY: >= 12 records where every column is
     arithmetic mod 256 with its own constant delta, and not every delta is 0.
     This is the rule the prom_b lane did not need; this span has 3,072 bytes of
     such arrays and nothing else frames them.  ⚠ Its false-positive count is
     the one to watch -- see --null.
  7. ASCII   -- >= 20 bytes in 0x20-0x7E.  (This span contains none; the rule is
     kept so the null table is comparable with prom_b's.)
  8. CODE    -- recursive descent that treats rules 1-7 as barriers.  Seeds: the
     thunk targets, every opcode-anchored `call`/`jp` site in prom_a+prom_b
     landing in range, every PC-relative `calr`/`jr`/`jrl` in the ALREADY-PROVEN
     prom_a instruction text landing in range, every in-range entry of every
     table rule 3 framed, and every 32-bit immediate a decoded instruction loads.
  Anything left over is DATA and the layout says only that.

RUN
  python3 notes/prom_a_fa5aeb_layout.py              # the LAYOUT table
  python3 notes/prom_a_fa5aeb_layout.py --tables     # every framed object + shape
  python3 notes/prom_a_fa5aeb_layout.py --code       # do the code segments decode?
  python3 notes/prom_a_fa5aeb_layout.py --null       # rule calibration
  python3 notes/prom_a_fa5aeb_layout.py --null --rev HEAD
  python3 notes/prom_a_fa5aeb_layout.py --stability  # does the layout move when
                                                     # a threshold moves?
  python3 notes/prom_a_fa5aeb_layout.py --selftest   # 108 checks, incl. the LAST
                                                     # entry of every table and
                                                     # the LAST segment
  python3 notes/prom_a_fa5aeb_layout.py --seeds      # where the descent starts
                                                     # and what each source is worth
  python3 notes/prom_a_fa5aeb_layout.py --residue    # what is left unexplained
  python3 notes/prom_a_fa5aeb_layout.py --barrier    # what the barrier removes
  python3 notes/prom_a_fa5aeb_layout.py --conflicts  # descent-vs-barrier overlap
  python3 notes/prom_a_fa5aeb_layout.py --frontier   # re-derive the ranking
  python3 notes/prom_a_fa5aeb_layout.py --python     # paste-ready LAYOUT literal

WHAT THIS FILE DOES NOT DO
  It does not emit assembly and it does not touch prom_a/wsa1_prom_a.s.  A later
  conversion round takes the LAYOUT, feeds each `code` segment to
  `prom_a/roundtrip.py LO HI --block` (which assembles and byte-compares before
  it prints, so it cannot break the gate) and each table to a `.byte`/`.long`
  emitter, then splices with `prom_a/insert_region.py`.  `--code` reports that
  all twelve code segments decode exactly and every one ends in `ret`, which is
  the property that makes that mechanical.
"""
import os
import collections
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import trace_code as TC                                            # noqa: E402

A_BASE = 0xF80000
B_BASE = 0xF00000
LO, HI = 0xFA5AEB, 0xFAA000
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")

PTR_LO, PTR_HI = 0x00F80000, 0x01000000
DIR_LO, DIR_HI = 0xF40000, 0xF44018        # prom_b's thunk directory
# Every threshold below is a MEASUREMENT.  `--null` prints the false-positive
# count of each one against proven instruction text, together with the
# thresholds that were REJECTED and why, and `--stability` shows that the
# layout of this span does not move anywhere inside the accepted band.
FILL_MIN = 32
ZERO_MIN = 16
PTR_MIN = 4
RAM_MIN = 8
IDENT_MIN = 12
REC_MIN = 32
REC_STRIDES = (2, 3, 4)
ASCII_MIN = 20
THUNK_MIN = 2
HOLEY_MIN = 24
RECBLOCK_MIN = 4

_r = {}


def rom(which="a"):
    if which not in _r:
        _r[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _r[which]


def w32(d, a, base=A_BASE):
    return int.from_bytes(d[a - base:a - base + 4], "little")


# ---------------------------------------------------------------- content rules

def const_runs(d, lo, hi, val, n):
    out, p = [], lo
    while p < hi:
        if d[p - A_BASE] == val:
            q = p
            while q < hi and d[q - A_BASE] == val:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def fill_runs(d, lo, hi, n=None):
    # ⚠ the default is read at CALL time, not at def time, so --stability can
    # move it.  A default bound at def time made --stability a silent no-op.
    return const_runs(d, lo, hi, 0x0E, FILL_MIN if n is None else n)


def zero_runs(d, lo, hi, n=None):
    return const_runs(d, lo, hi, 0x00, ZERO_MIN if n is None else n)


def ptr_tables(d, lo, hi, minent=None):
    """Maximal chains of >= minent consecutive LE32 words inside prom_a.

    ★ A TABLE MAY NOT CONTAIN ITS OWN TARGET.  Without that clause the chain at
    0xFA80FE runs 13 entries instead of 11, because entries 11 and 12 are the
    first two fields of the RECORD ARRAY the table points at -- and those fields
    are themselves prom_a pointers, so the plain chain rule cannot see the seam.
    Entry [0] of the table is 0x00FA812A and 0xFA812A is inside the 13-entry
    reading, which is impossible for a table: it would point into itself.  So
    the chain is truncated at the smallest in-range entry value that lies
    strictly inside it.  This fires on exactly one table in the span and it
    moves the boundary by 8 bytes; --selftest pins both readings."""
    minent = PTR_MIN if minent is None else minent
    out, p = [], lo
    while p < hi - 3:
        k, q = 0, p
        while q <= hi - 4 and PTR_LO <= w32(d, q) < PTR_HI:
            k += 1
            q += 4
        if k >= minent:
            end = p + 4 * k
            inner = [w32(d, x) for x in range(p, end, 4)]
            cut = [v for v in inner if p < v < end]
            if cut:
                end = min(cut) - (min(cut) - p) % 4
                k = (end - p) // 4
            if k >= minent:
                out.append((p, end))
                p = end
                continue
        p += 1
    return out


def holey_maps(d, lo, hi, run_min=4, gap_max=12, total_min=None, frac_min=0.4):
    """0xFF-SENTINEL MAPS: 0xFF runs of >= run_min merged across gaps of <=
    gap_max, kept when the merged region is >= total_min bytes and >= frac_min
    of it is 0xFF.

    WHY.  This span holds four objects whose empty slots are 0xFF and whose live
    slots are one or two bytes: 191 bytes of solid 0xFF at 0xFA803F, a 128-byte
    byte map, a 96-byte word map and a 48-byte byte map.  No pointer, RAM,
    index or record rule sees any of them, and the descent -- which is seeded
    with every immediate a decoded instruction loads, and those bases ARE
    loaded -- walked straight into two of them and called 115 bytes of table
    `code`.  This is the barrier that stops it.
    ⚠ What it pins is the END, not the start: the merge begins at the first 0xFF
    run of run_min, so a map whose first entries are all live starts up to
    gap_max bytes late.  The starts come from named_bases() instead, and the
    layout says which evidence pinned which edge."""
    total_min = HOLEY_MIN if total_min is None else total_min
    runs = const_runs(d, lo, hi, 0xFF, run_min)
    out, i = [], 0
    while i < len(runs):
        a, e = runs[i]
        j = i + 1
        while j < len(runs) and runs[j][0] - e <= gap_max:
            e = runs[j][1]
            j += 1
        n = e - a
        ff = sum(1 for x in range(a, e) if d[x - A_BASE] == 0xFF)
        if n >= total_min and ff >= frac_min * n:
            out.append((a, e))
        i = j
    return out


def ram_tables(d, lo, hi, minent=None):
    """Maximal chains of >= minent consecutive LE32 words in 0x0001-0xFFFF."""
    minent = RAM_MIN if minent is None else minent
    out, p = [], lo
    while p < hi - 3:
        k, q = 0, p
        while q <= hi - 4 and 0 < w32(d, q) < 0x10000:
            k += 1
            q += 4
        if k >= minent:
            out.append((p, p + 4 * k))
            p = q
        else:
            p += 1
    return out


def ident_runs(d, lo, hi, n=None):
    """Maximal runs where byte[k] == byte[0]+k, WITHOUT wrapping past 0xFF.

    The no-wrap clause is inherited from notes/prom_b_f65000_layout.py, where a
    0xFF that is the last byte of a displacement extended an index map backwards
    into an instruction.  An index map counts up; it does not roll over."""
    n = IDENT_MIN if n is None else n
    out, p = [], lo
    while p < hi:
        q = p + 1
        while (q < hi and d[p - A_BASE] + (q - p) <= 0xFF
               and d[q - A_BASE] == d[p - A_BASE] + (q - p)):
            q += 1
        if q - p >= n:
            out.append((p, q))
            p = q
        else:
            p += 1
    return out


def _rec_extent(d, p, s, hi):
    """How many stride-s records starting at p have every column arithmetic?"""
    o = p - A_BASE
    if p + 2 * s > hi:
        return 0, None
    delta = tuple((d[o + s + j] - d[o + j]) & 0xFF for j in range(s))
    k = 2
    while p + (k + 1) * s <= hi:
        base = o + k * s
        if all(d[base + j] == (d[o + j] + k * delta[j]) & 0xFF for j in range(s)):
            k += 1
        else:
            break
    return k, delta


def record_arrays(d, lo, hi, minrec=None, strides=REC_STRIDES):
    """Maximal stride-s arrays whose every column is arithmetic mod 256.

    WHY THIS RULE EXISTS.  0xFA84C8-0xFA8CC7 is 2,048 bytes of tables that no
    rule prom_b needed can see: sixteen groups of 32 three-byte records
    `(0xB5, k, 0x7F)`, then stride-2 groups `(0xAD, k)`, `(k, 0x00)` and so on.
    They are not pointers, not RAM addresses, not an index map and not ASCII.
    A column that is constant or counts by a fixed step is what they have in
    common, and it is a property of the BYTES, so it can be calibrated.

    GUARDS.  A run whose deltas are ALL zero is rejected: that is a repeated
    constant, which is what padding and a table of one repeated pointer look
    like, and both are framed by higher-priority rules.  Smaller strides are
    tried first so a stride-2 array is not reported as a stride-4 one."""
    minrec = REC_MIN if minrec is None else minrec
    out, p = [], lo
    while p < hi:
        best = None
        for s in strides:
            k, delta = _rec_extent(d, p, s, hi)
            if k >= minrec and delta is not None and any(delta):
                if best is None or k * s > best[0]:
                    best = (k * s, s, k, delta)
        if best:
            out.append((p, p + best[0], best[1], best[2], best[3]))
            p += best[0]
        else:
            p += 1
    return out


def ascii_runs(d, lo, hi, n=None):
    n = ASCII_MIN if n is None else n
    out, p = [], lo
    while p < hi:
        if 32 <= d[p - A_BASE] < 127:
            q = p
            while q < hi and 32 <= d[q - A_BASE] < 127:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def directory_pointers(lo=LO, hi=HI):
    """Addresses in [lo,hi) that prom_b's thunk directory names as a BARE 32-bit
    pointer rather than as a `jp` slot.

    Evidence that the directory really does this: slot T_F40710 holds
    `00 54 fa 00` = 0x00FA5400, and 0xFA5400 is `MIDI_EntryThunks`, converted
    and headed in prom_a/wsa1_prom_a.s:42400.  T_F40740 holds `00 60 fa 00` =
    0x00FA6000 the same way.  The two live slot RUNS that follow each of those
    pointers (T_F40714-T_F40734 and T_F40744-T_F40760) are the two modules'
    published entry points, so the bare pointer is the MODULE BASE."""
    b = rom("b")
    out = set()
    for off in range(DIR_LO - B_BASE, DIR_HI - B_BASE, 4):
        v = int.from_bytes(b[off:off + 4], "little")
        if lo <= v < hi:
            out.add(v)
    return out


def thunk_tables(d, lo, hi, minslots=None):
    """Entry-thunk tables: >= minslots 4-byte slots at a DIRECTORY-NAMED base,
    every slot either `1b <addr24-in-prom_a>` (a live entry) or `0e 00 00 00`
    (a dead slot padded to the stride).

    This is the most specific rule here and it runs first.  Its positive control
    is `MIDI_EntryThunks` at 0xFA5400: already converted, already headed, six
    slots, one live.  ⚠ Its `--null` firing on that object is a TRUE positive
    counted honestly rather than excused -- see null()."""
    minslots = THUNK_MIN if minslots is None else minslots
    out = []
    for base in sorted(directory_pointers(lo, hi)):
        k = 0
        while base + 4 * (k + 1) <= hi:
            o = base + 4 * k - A_BASE
            sl = d[o:o + 4]
            if sl == b"\x0e\x00\x00\x00":
                k += 1
                continue
            if sl[0] == 0x1B:
                t = sl[1] | sl[2] << 8 | sl[3] << 16
                if PTR_LO <= t < PTR_HI:
                    k += 1
                    continue
            break
        if k >= minslots:
            out.append((base, base + 4 * k))
    return out


def pointer_framed_records(d, tables, lo, hi, minrec=None):
    """The RECORD BLOCK a pointer table frames with its own entries.

    When every in-range entry of a framed PTRTAB is an arithmetic progression of
    constant stride S, and the progression starts at the first byte after the
    table, the entries are not code labels -- they are the records of an array
    the table indexes, and the array is [first, last + S).

    This fires on exactly one object here and no content rule can see it:
    0xFA80FE's eleven entries are 0xFA812A, 0xFA8136 ... 0xFA81A2, stride 12,
    beginning at 0xFA812A which is the byte after the table.  Each record's
    first two fields are themselves prom_a pointers, so the descent -- seeded
    with every PTRTAB entry -- decoded 132 bytes of them as instructions before
    this rule existed.  The block's END is the strongest part: last + 12 =
    0xFA81AE, and 0xFA81AE is the target of `calr 0xfa81ae` at 0xFA83AA, i.e.
    the first byte after the array is an address the code branches to."""
    minrec = RECBLOCK_MIN if minrec is None else minrec
    out = []
    for a, e in tables:
        ent = [w32(d, x) for x in range(a, e, 4)]
        ent = [v for v in ent if lo <= v < hi]
        if len(ent) < minrec or ent[0] != e:
            continue
        st = ent[1] - ent[0]
        if st <= 0 or any(ent[i + 1] - ent[i] != st for i in range(len(ent) - 1)):
            continue
        if ent[-1] + st > hi:
            continue
        out.append((ent[0], ent[-1] + st))
    return out


RULES = [
    ("thunktab", lambda d, a, b: thunk_tables(d, a, b)),
    ("ptrtab", lambda d, a, b: ptr_tables(d, a, b)),
    ("ramtab", lambda d, a, b: ram_tables(d, a, b)),
    ("holey", lambda d, a, b: holey_maps(d, a, b)),
    ("ident", lambda d, a, b: ident_runs(d, a, b)),
    ("recarr", lambda d, a, b: [(x[0], x[1]) for x in record_arrays(d, a, b)]),
    ("ascii", lambda d, a, b: ascii_runs(d, a, b)),
    ("fill", lambda d, a, b: fill_runs(d, a, b)),
    ("zero", lambda d, a, b: zero_runs(d, a, b)),
]

_regions_cache = {}


def regions(d, lo=LO, hi=HI):
    """The content rules applied in priority order, as DISJOINT (kind,lo,hi).

    Each rule is run on the MAXIMAL UNCLAIMED SUBINTERVALS left by the rules
    above it, never on the whole span.  That is stronger than the `drop a run
    that overlaps` discipline of notes/prom_b_f65000_layout.ram_tables_ex():
    a rule can neither be truncated by a neighbour it does not know about nor
    silently lose a whole object because two bytes of it were already taken.
    The order below is the order of specificity, and it is load-bearing --
    ZERO must run after RAMTAB, because the last entry of the 800-entry RAM
    table at 0xFA8FF8 ends `00 00` and a zero run started two bytes early would
    otherwise straddle the table's end."""
    key = (lo, hi)
    if key in _regions_cache:
        return _regions_cache[key]
    free = [(lo, hi)]
    out = []
    for kind, fn in RULES:
        found = []
        for a, b in free:
            found += [(kind, x, y) for x, y in fn(d, a, b)]
        if kind == "ptrtab":
            tabs = [(x, y) for _, x, y in found]
            claimed = set()
            for _, x, y in out + found:
                claimed |= set(range(x, y))
            for x, y in pointer_framed_records(d, tabs, lo, hi):
                if not any(z in claimed for z in range(x, y)):
                    found.append(("recblock", x, y))
        out += found
        taken = set()
        for _, x, y in found:
            taken |= set(range(x, y))
        nf = []
        for a, b in free:
            p = a
            while p < b:
                if p in taken:
                    p += 1
                    continue
                q = p
                while q < b and q not in taken:
                    q += 1
                nf.append((p, q))
                p = q
        free = nf
    out.sort(key=lambda r: r[1])
    _regions_cache[key] = out
    return out


def barriers(d, lo=LO, hi=HI):
    b = set()
    for _, a, e in regions(d, lo, hi):
        b |= set(range(a, e))
    return b


# ------------------------------------------------------------------ decode side

_tab = None


def table():
    global _tab
    if _tab is None:
        _tab = TC.decode_table(IMGA, A_BASE)
    return _tab


def decode_at(addr, window=0x40):
    """(length, text) for the instruction AT addr, decoded from addr itself.

    The 32 phase-shifted sweeps merged by trace_code.decode_table resynchronise
    long before they reach any particular module, so an address no sweep landed
    on has no entry -- and the entry points this script exists to follow are
    exactly such addresses.  The fallback decodes a window that starts at addr,
    which by construction puts addr on a boundary."""
    tab = table()
    if addr in tab:
        return tab[addr]
    d = rom("a")
    o = addr - A_BASE
    if o < 0 or o >= len(d):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d[o:o + window])
        tmp = f.name
    try:
        out = subprocess.run([TC.UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    for ln in out.splitlines():
        m = TC.LINE.match(ln)
        if m and int(m.group(1), 16) == addr:
            tab[addr] = (len(m.group(2).split()), m.group(3).strip())
            return tab[addr]
    return None


# --------------------------------------------------------------------- the seeds

def thunk_entries(lo=LO, hi=HI):
    """(slot, target) for every `jp` slot of prom_b's 0xF40000 directory that
    lands in [lo,hi).  Slot layout: 0x1B followed by a 24-bit address."""
    b = rom("b")
    out = []
    for slot in range(0x40000, 0x44018, 4):
        if b[slot] == 0x1B:
            t = b[slot + 1] | b[slot + 2] << 8 | b[slot + 3] << 16
            if lo <= t < hi:
                out.append((B_BASE + slot, t))
    return out


def far_calls(lo=LO, hi=HI):
    """`call addr24` / `jp addr24` sites in prom_a+prom_b targeting [lo,hi).

    Opcode-anchored, scanned at EVERY byte offset, so this is an UPPER BOUND on
    the sites and is used only to SEED a descent that the barrier constrains."""
    out = set()
    for blob in (rom("a"), rom("b")):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if lo <= t < hi:
                    out.add(t)
    return out


LINE_RE = re.compile(r";\s*([0-9A-F]{6})\s\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})")


def proven_instructions(rev=None):
    """[(addr, bytes)] for every PROVEN INSTRUCTION line of prom_a/wsa1_prom_a.s.

    Every line the transcription emits carries a `; ADDR  <hex bytes>  <mame
    text>` comment and the byte gate proves the file rebuilds the ROM, so these
    are instructions beyond argument.  Directive lines (`.byte`, `.long`,
    `.fill`, `.ascii`) carry the same comment shape and are excluded by
    requiring the mnemonic not to start with a dot -- without that the corpus
    silently contains the data islands it is meant to be a null for."""
    out = []
    for l in source_text(rev).splitlines():
        body = l.split(";")[0]
        if not body.startswith("\t") or body.lstrip().startswith("."):
            continue
        m = LINE_RE.search(l)
        if not m:
            continue
        out.append((int(m.group(1), 16), bytes.fromhex(m.group(2).replace(" ", ""))))
    return out


def rel_targets(lo=LO, hi=HI, rev=None):
    """PC-relative branch targets, computed from the bytes of PROVEN prom_a
    instructions, that land in [lo,hi).

    The first byte fixes the form (dasm900.cpp's first-byte table):
        0x1E  d16    calr      length 3
        0x60-0x6F d8  jr cc    length 2
        0x70-0x7F d16 jrl cc   length 3
    and the target is (address of the NEXT instruction) + signed displacement.
    ⚠ Cited addresses are the address of the BRANCH INSTRUCTION, never one past
    it.  --selftest checks every such target in the whole image lands on a
    proven instruction boundary, which is what proves the three lengths."""
    out = {}
    for a, bs in proven_instructions(rev):
        t = _rel_target(a, bs)
        if t is not None and lo <= t < hi:
            out.setdefault(t, []).append(a)
    return out


def _rel_target(a, bs):
    if not bs:
        return None
    op = bs[0]
    if op == 0x1E and len(bs) >= 3:
        return a + 3 + int.from_bytes(bs[1:3], "little", signed=True)
    if 0x60 <= op <= 0x6F and len(bs) >= 2:
        return a + 2 + int.from_bytes(bs[1:2], "little", signed=True)
    if 0x70 <= op <= 0x7F and len(bs) >= 3:
        return a + 3 + int.from_bytes(bs[1:3], "little", signed=True)
    return None


LABEL_BR = re.compile(r"^\s*(?:jr|jrl|calr)\b[^;]*?\.L([0-9A-F]{6})")
EXPR_BR = re.compile(r"^\s*(?:jr|jrl|calr)\s+\(0x([0-9A-Fa-f]{6})\s*-")


def rel_decoder_audit(rev=None):
    """(checked, mismatches) for _rel_target() against the TREE'S OWN operands.

    Every relative branch in prom_a/wsa1_prom_a.s that names its destination as
    a `.LHHHHHH` label or as the expression `(0xHHHHHH - 0xNEXT)` states the
    target the byte gate has already accepted.  Recomputing it from the raw
    bytes and comparing is a direct audit of the three lengths this file assumes
    (0x1E -> 3, 0x60-0x6F -> 2, 0x70-0x7F -> 3).

    ⚠ THIS REPLACES A WEAKER CHECK THAT FAILED FOR THE WRONG REASON.  The first
    version asserted that every computed target lands on an annotated
    instruction address; it reported 142, then 71, failures -- and every one was
    a target inside a HAND-WRITTEN block of the .s that carries no `; ADDR`
    comments at all (RESET at 0xF826A9 is the clearest).  A check that a tool
    cannot pass for reasons unrelated to what it measures is not a check."""
    mism = []
    n = 0
    for l in source_text(rev).splitlines():
        body = l.split(";")[0]
        m = LABEL_BR.match(body) or EXPR_BR.match(body)
        if not m:
            continue
        m2 = LINE_RE.search(l)
        if not m2:
            continue
        a = int(m2.group(1), 16)
        bs = bytes.fromhex(m2.group(2).replace(" ", ""))
        t = _rel_target(a, bs)
        n += 1
        if t != int(m.group(1), 16):
            mism.append((a, bs.hex(" "), t, m.group(1)))
    return n, mism


def table_entry_seeds(d, lo=LO, hi=HI):
    """Every in-range target of every entry of every table the PTRTAB rule framed.

    A framed pointer table is a table of addresses the firmware transfers to, so
    its entries are entry points; a descent that ignores them misses whole
    handlers.  Here it is worth 1 seed set that no other source supplies -- see
    --seeds for the byte figure."""
    out = set()
    for kind, a, e in regions(d, lo, hi):
        if kind != "ptrtab":
            continue
        for x in range(a, e, 4):
            t = w32(d, x)
            if lo <= t < hi:
                out.add(t)
    return out


def thunktab_targets(d, lo=LO, hi=HI):
    """The in-range `jp` targets of every entry-thunk table the rule framed."""
    out = set()
    for kind, a, e in regions(d, lo, hi):
        if kind != "thunktab":
            continue
        for x in range(a, e, 4):
            if d[x - A_BASE] == 0x1B:
                t = (d[x + 1 - A_BASE] | d[x + 2 - A_BASE] << 8
                     | d[x + 3 - A_BASE] << 16)
                if lo <= t < hi:
                    out.add(t)
    return out


def all_seeds(d, lo=LO, hi=HI):
    return (set(t for _, t in thunk_entries(lo, hi)) | far_calls(lo, hi)
            | set(rel_targets(lo, hi)) | table_entry_seeds(d, lo, hi)
            | directory_pointers(lo, hi) | thunktab_targets(d, lo, hi))


# ------------------------------------------------------------------- the descent

OPERAND = re.compile(r"0x00([0-9a-f]{6})|\(0x([0-9a-f]{6})\)")


# value -> set of INSTRUCTION addresses that name it.  Exists because the wave-7
# skeptic found ~31 evidence citations that were all one byte past the instruction
# -- they pointed at the imm32 of the `ld XIX/XIY/XIZ,imm32` that does the load --
# and NO mode of this script printed the sites, so not one was reproducible.
# `p` below is the instruction address; `p + 1` is what the wrong citations used.
NAMED_SITES = {}


def descend(d, lo, hi, seeds, block, named=None):
    """Recursive descent that refuses to enter a barrier byte.

    `named`, if given, collects every in-range 24-bit address that a decoded
    instruction NAMES as an operand -- a table base is loaded, not branched to,
    so this is the only way a data object's START becomes visible."""
    seen, work = set(), [s for s in seeds if s not in block]
    while work:
        p = work.pop()
        while lo <= p < hi and p not in seen and p not in block:
            dec = decode_at(p)
            if dec is None:
                break
            n, txt = dec
            if any((p + i) in block for i in range(n)):
                break
            seen.update(range(p, p + n))
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen and t not in block:
                    work.append(t)
            for m in re.findall(r"0x00([0-9a-f]{6})", txt):
                v = int(m, 16)
                if named is not None and lo <= v < hi:
                    named.add(v)
                    NAMED_SITES.setdefault(v, set()).add(p)
                if lo <= v < hi and v not in seen and v not in block:
                    work.append(v)
            if TC.is_flow_end(txt):
                break
            p += n
    return seen


def gaps_of(lo, hi, seen, block):
    out, p = [], lo
    while p < hi:
        if p in seen or p in block:
            p += 1
            continue
        q = p
        while q < hi and q not in seen and q not in block:
            q += 1
        out.append((p, q))
        p = q
    return out


def decode_bounds(s, e):
    p, out = s, set()
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return None
        out.add(p)
        p += dec[0]
    return out if p == e else None


def selfconsistent(s, e, seen):
    p, bounds, ins = s, set(), []
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return False
        bounds.add(p)
        ins.append((p, dec[0], dec[1]))
        p += dec[0]
    if p != e:
        return False
    for a, n, txt in ins:
        if txt.strip().startswith("db"):
            return False
        if not re.match(r"^(jr|jrl|calr)\b", txt):
            continue
        for t in TC.branch_targets(txt):
            if t not in bounds and t not in seen:
                return False
    return True


def ends_in_flow_end(s, e):
    """Does a linear decode of [s,e) consume it exactly AND end in a flow end?

    Inherited from notes/prom_b_f0ea9f_layout.py --null-accept, which measured
    selfconsistent() alone accepting 13.9% of known-DATA chunks and 0.1% once
    the run is also required to end the way a real routine tail does."""
    p, last = s, None
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return False
        last = dec[1]
        p += dec[0]
    return p == e and last is not None and TC.is_flow_end(last)


def accept(gaps, seen):
    """Iterate selfconsistent() to a fixpoint over the WHOLE pending set.

    Per pass the candidate boundary set is `seen` plus the linear-decode
    boundaries of every run still pending, so two adjacent routines that branch
    into each other are accepted together rather than deadlocking.

    ⚠ TRAILING PAD.  A run is also tried with up to three trailing 0x00/0x0E
    bytes removed, because the assembler aligns the table that follows a routine
    and the routine's `ret` is then not the last byte of the gap.  Without this
    the 18-byte routine at 0xFA6068 (`call 0xF40004` x4, `ret`, one `nop`) and
    the 22-byte one at 0xFA750A both fail ends_in_flow_end() and come out as
    `.byte`.  The stripped bytes are returned separately and become `align`,
    never code."""
    d = rom("a")
    ok, pending, pads = {}, list(gaps), []
    for _ in range(20):
        cand = set(seen)
        for s, e in pending:
            bd = decode_bounds(s, e)
            if bd:
                cand |= bd
        grew, still = False, []
        for s, e in pending:
            hit = None
            for k in range(0, 4):
                t = e - k
                if t <= s:
                    break
                if any(c not in (0x00, 0x0E) for c in d[t - A_BASE:e - A_BASE]):
                    continue
                if selfconsistent(s, t, cand) and ends_in_flow_end(s, t):
                    hit = t
                    break
            if hit is None:
                still.append((s, e))
                continue
            if hit < e:
                pads.append((hit, e))
            ok[(s, hit)] = True
            p = s
            while p < hit:
                n = decode_at(p)[0]
                seen.update(range(p, min(p + n, hit)))
                p += n
            grew = True
        pending = still
        if not grew:
            break
    return ok, pending, pads


# ------------------------------------------------------------------- the layout

def extend_holey_left(d, regs, named, max_back=32):
    """Move a HOLEY region's START back to the operand-named base in front of it.

    holey_maps() pins the END of a sentinel map and can start up to gap_max
    bytes late.  A base a decoded instruction LOADS is the other half of the
    evidence, and the two agree on three objects here:
        0xFA83E8  loaded at 0xFA6268, holey core starts 0xFA83F4  (12 B back)
        0xFA8468  loaded at 0xFA6284, holey core starts 0xFA8478  (16 B back)
        0xFA8FC8  loaded at 0xFA7C25, holey core starts 0xFA8FDB  (19 B back)
    A base is used only when the bytes between it and the core are unclaimed
    and the distance is under max_back; nothing else moves a boundary here."""
    claimed = set()
    for _, x, y in regs:
        claimed |= set(range(x, y))
    out, moved = [], []
    for kind, x, y in regs:
        if kind == "holey":
            cands = [n for n in named if x - max_back <= n < x
                     and not any(z in claimed for z in range(n, x))]
            if cands:
                nx = min(cands)
                moved.append((nx, x))
                x = nx
        out.append((kind, x, y))
    out.sort(key=lambda r: r[1])
    return out, moved


def align_pads(d, regs, pend, pads, max_n=3):
    """Residue runs of at most max_n bytes, all 0x00 or 0x0E, that sit directly
    in front of a framed region: assembler alignment padding, not data."""
    starts = set(x for _, x, _ in regs)
    out, rest = list(pads), []
    for x, y in pend:
        if (y - x) <= max_n and y in starts and \
                all(c in (0x00, 0x0E) for c in d[x - A_BASE:y - A_BASE]):
            out.append((x, y))
        else:
            rest.append((x, y))
    return out, rest


def build(lo=LO, hi=HI, passes=3):
    """Content rules -> barrier -> descent -> accept, iterated.

    TWO PASSES ARE NEEDED and the reason is not cosmetic.  A data object's START
    is only visible as an operand of an instruction, and that instruction is
    only decoded once the descent has run -- but the descent must already have
    the barrier or it decodes the object.  So: pass 1 barriers on pure content
    and records what the code NAMES; pass 2 uses those names to move the
    sentinel maps' left edges and re-descends behind the corrected barrier.
    The loop stops when the segment list stops changing (it does, at pass 2)."""
    d = rom("a")
    prev, regs, named = None, None, set()
    for _ in range(passes):
        _regions_cache.clear()
        regs = regions(d, lo, hi)
        if named:
            regs, _ = extend_holey_left(d, regs, named)
        block = set()
        for _, x, y in regs:
            block |= set(range(x, y))
        named = set()
        NAMED_SITES.clear()
        seen = descend(d, lo, hi, sorted(all_seeds(d, lo, hi)), block, named)
        gaps = gaps_of(lo, hi, seen, block)
        ok, pend, pads = accept(gaps, seen)
        pads, pend = align_pads(d, regs, pend, pads)
        kind = ["data"] * (hi - lo)
        for x in seen:
            if lo <= x < hi:
                kind[x - lo] = "code"
        for (x, y) in ok:
            for z in range(x, y):
                kind[z - lo] = "code"
        for (x, y) in pads:
            for z in range(x, y):
                kind[z - lo] = "align"
        conflicts = []
        for k, x, y in regs:
            for z in range(x, y):
                if kind[z - lo] == "code":
                    conflicts.append(z)
                kind[z - lo] = k
        segs, q = [], 0
        while q < hi - lo:
            r = q
            while r < hi - lo and kind[r] == kind[q]:
                r += 1
            segs.append((kind[q], lo + q, r - q))
            q = r
        if segs == prev:
            break
        prev = segs
    return segs, conflicts, pend, ok, seen, regs, named


# ------------------------------------------------------------------- calibration

def source_text(rev=None):
    if rev is None:
        return open(SRC).read()
    return subprocess.run(["git", "show", "%s:prom_a/wsa1_prom_a.s" % rev],
                          cwd=ROOT, check=True, capture_output=True,
                          text=True).stdout


def proven_code_runs(rev=None):
    """Maximal ADDRESS RUNS of proven instruction text in prom_a/wsa1_prom_a.s.

    A run is broken by any non-instruction line and by any address that does not
    advance, so a run is a contiguous stretch of instructions with no directive
    inside it.  A content rule that fires inside one of these is a FALSE
    POSITIVE."""
    seq = []
    for l in source_text(rev).splitlines():
        body = l.split(";")[0]
        m = re.search(r";\s*([0-9A-F]{6})\s\s", l)
        ok = bool(m) and body.startswith("\t") and not body.lstrip().startswith(".")
        seq.append(int(m.group(1), 16) if ok else None)
    runs, cur = [], []
    for a in seq:
        if a is None or (cur and a <= cur[-1]):
            if len(cur) > 1:
                runs.append((cur[0], cur[-1]))
            cur = []
        if a is not None:
            cur.append(a)
    if len(cur) > 1:
        runs.append((cur[0], cur[-1]))
    return runs


def null(rev=None):
    d = rom("a")
    runs = proven_code_runs(rev)
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: every maximal run of PROVEN instruction text in")
    print("prom_a/wsa1_prom_a.s @ %s -- %d runs, %d bytes."
          % (rev or "WORKING TREE", len(runs), tot))
    print("A rule that fires inside one of these runs is a FALSE POSITIVE.")
    if rev is None:
        print("  ⚠ this corpus GROWS as rounds convert code; quote it with"
              " --rev REV, or quote the byte figure above beside the counts.")
    tests = [
        ("thunktab >= %d" % THUNK_MIN, lambda a, b: thunk_tables(d, a, b)),
        ("ptrtab   >= %d" % PTR_MIN, lambda a, b: ptr_tables(d, a, b)),
        ("ptrtab   >=  3 (rejected)", lambda a, b: ptr_tables(d, a, b, 3)),
        ("ptrtab   >=  2 (rejected)", lambda a, b: ptr_tables(d, a, b, 2)),
        ("ramtab   >= %d" % RAM_MIN, lambda a, b: ram_tables(d, a, b)),
        ("ramtab   >=  6 (rejected)", lambda a, b: ram_tables(d, a, b, 6)),
        ("ramtab   >=  4 (rejected)", lambda a, b: ram_tables(d, a, b, 4)),
        ("holey    >= %d" % HOLEY_MIN, lambda a, b: holey_maps(d, a, b)),
        ("holey    >= 32 (accepted band)",
         lambda a, b: holey_maps(d, a, b, total_min=32)),
        ("holey    >= 16 (rejected)",
         lambda a, b: holey_maps(d, a, b, total_min=16)),
        ("holey    run>=3 (rejected)",
         lambda a, b: holey_maps(d, a, b, run_min=3)),
        ("recblock >= %d" % RECBLOCK_MIN,
         lambda a, b: pointer_framed_records(
             d, ptr_tables(d, a, b), a, b)),
        ("recblock >=  3 (rejected)",
         lambda a, b: pointer_framed_records(
             d, ptr_tables(d, a, b), a, b, 3)),
        ("ident    >= %d" % IDENT_MIN, lambda a, b: ident_runs(d, a, b)),
        ("ident    >=  8 (rejected)", lambda a, b: ident_runs(d, a, b, 8)),
        ("recarr   >= %d" % REC_MIN,
         lambda a, b: [(x[0], x[1]) for x in record_arrays(d, a, b)]),
        ("recarr   >= 27 (accepted band)",
         lambda a, b: [(x[0], x[1]) for x in record_arrays(d, a, b, 27)]),
        ("recarr   >= 12 (accepted band)",
         lambda a, b: [(x[0], x[1]) for x in record_arrays(d, a, b, 12)]),
        ("recarr   >=  8 (accepted band)",
         lambda a, b: [(x[0], x[1]) for x in record_arrays(d, a, b, 8)]),
        ("recarr   >=  6 (rejected)",
         lambda a, b: [(x[0], x[1]) for x in record_arrays(d, a, b, 6)]),
        ("ascii    >= %d" % ASCII_MIN, lambda a, b: ascii_runs(d, a, b)),
        ("ascii    >= 10 (rejected)", lambda a, b: ascii_runs(d, a, b, 10)),
        ("fill     >= %d" % FILL_MIN, lambda a, b: fill_runs(d, a, b)),
        ("fill     >= 28 (accepted band)", lambda a, b: fill_runs(d, a, b, 28)),
        ("fill     >= 16 (rejected)", lambda a, b: fill_runs(d, a, b, 16)),
        ("fill     >=  8 (rejected)", lambda a, b: fill_runs(d, a, b, 8)),
        ("zero     >= %d" % ZERO_MIN, lambda a, b: zero_runs(d, a, b)),
        ("zero     >= 512 (does not help)", lambda a, b: zero_runs(d, a, b, 512)),
        ("zero     >=  8 (rejected)", lambda a, b: zero_runs(d, a, b, 8)),
    ]
    for name, f in tests:
        hits = []
        for s0, e0 in runs:
            hits += f(s0, e0)
        print("  %-32s false positives: %3d   %s"
              % (name, len(hits),
                 " ".join("0x%06X(%d)" % (a, b - a) for a, b in hits[:6])))
    print()
    print("READ THE COUNTS ABOVE, THEY ARE NOT ALL ZERO.  What each nonzero one is:")
    hits = []
    for s0, e0 in runs:
        hits += thunk_tables(d, s0, e0)
    base18 = sum(1 for a, e in hits
                 if d[a - A_BASE] == 0x1B
                 and (d[a + 1 - A_BASE] | d[a + 2 - A_BASE] << 8
                      | d[a + 3 - A_BASE] << 16) == a + 0x18)
    print("  thunktab  %d firings, and every one is a TRUE POSITIVE: an"
          % len(hits))
    print("            entry-thunk table at an address prom_b's directory names")
    print("            with a bare pointer, built from `jp addr24` and")
    print("            `0e 00 00 00` slots.  %d of the %d have slot 0 = `jp"
          % (base18, len(hits)))
    print("            base+0x18`, the module-entry idiom; two are already")
    print("            headed as such in the tree (LCD_EntryThunks 0xF8E800,")
    print("            MIDI_EntryThunks 0xFA5400) and %d of the 14 carry SOME"
          % len([a for a, _ in hits if a in labelled_addresses()]))
    print("            label at exactly the base address.  The kind")
    print("            this rule assigns is CODE -- a thunk slot converts to")
    print("            `jp`/`ret`/`nop` -- so a firing inside proven instruction")
    print("            text is not a misclassification, it is the rule working.")
    print("            ⚠ The count is reported rather than excused: if one of")
    print("            the %d were not a thunk table, this rule would be wrong."
          % len(hits))
    print("  holey     ZERO, at every threshold tried (16/24/32) and with the")
    print("            run floor at 3.  A stretch where 0xFF is 40%% of the bytes")
    print("            simply does not occur inside TLCS-900 instruction text.")
    print("  recblock  ZERO.  It cannot fire without a PTRTAB whose entries are")
    print("            an arithmetic progression starting at the byte after the")
    print("            table, which is a very narrow shape; in the whole corpus")
    print("            nothing has it.")
    print("  ptrtab    2 sites, both 5 consecutive prom_a pointers transcribed as")
    print("            instructions: 0xFA0487 (-> 0xFA049B,0xFA04B5,0xFA04C0,")
    print("            0xFA04C8,0xFA04E2) and 0xFE1551 (-> 0xFE1565,0xFE15E5,")
    print("            0xFE157D x3).  ⚠ Both look like jump tables the existing")
    print("            transcription decoded as code.  Not this lane's to fix;")
    print("            recorded as an open question.")
    print("  ramtab    8 sites, all one shape: a 1<<k bit-weight sequence read")
    print("            one byte off (0xF8A588, 0xF8A5AD, 0xF8A5CE, 0xF8A993,")
    print("            0xF8A9B8, 0xF8A9D9, 0xF8BE4C, 0xF8BE92).  prom_b's lane")
    print("            met the same shape and split it off into a BITTAB rule;")
    print("            that RELABELS the firings, it does not remove them, and")
    print("            no bit-weight table exists in this span, so no such rule")
    print("            was added here.  None of the 8 is in 0xFA5AEB-0xFAA000.")
    print("  ascii     5 sites, and they are a finding rather than noise: 96")
    print("            bytes of 0x20 at 0xF94ED8 and again at 0xF95008 are")
    print("            transcribed as 48 `ldb w,0x20` each, and 0xF94C79 is the")
    print("            string ' BY (c)masa,toshi --- '.  The ASCII rule fires")
    print("            ZERO times inside 0xFA5AEB-0xFAA000 (there is no run of")
    print("            8 printable bytes in the span at all), so it changes")
    print("            nothing here.")
    print("  zero      4 sites, and this rule CANNOT be calibrated to zero on")
    print("            this corpus at any threshold: 1,323 bytes at 0xFE7A86 and")
    print("            536 at 0xFF7A4D are module padding a previous round")
    print("            transcribed as `nop`, so they are inside `proven")
    print("            instruction text` by construction.  The corpus is")
    print("            contaminated, not the rule.  The other two are 19 bytes")
    print("            at 0xFE2FEC and 25 at 0xFE7055, same shape.  ⚠ The one")
    print("            firing in this span (0xFA9C78, 506 bytes, immediately")
    print("            before 398 bytes of 0x0E at a module end) is the LEAST")
    print("            well-founded segment in the layout and is called `pad`")
    print("            with that caveat stated.")


_LABELS = None


def labelled_addresses(rev=None):
    """prom_a addresses that carry a label line in the transcription.

    A label is a line `NAME:` immediately followed by a line whose address
    comment is ADDR; that is how every label in this file is written."""
    global _LABELS
    if _LABELS is not None and rev is None:
        return _LABELS
    out, pending = set(), False
    for l in source_text(rev).splitlines():
        if re.match(r"^[A-Za-z_.][A-Za-z0-9_.]*:\s*$", l):
            pending = True
            continue
        m = re.search(r";\s*([0-9A-F]{6})\s\s", l)
        if m and pending:
            out.add(int(m.group(1), 16))
        if l.strip():
            pending = False
    if rev is None:
        _LABELS = out
    return out


def stability():
    """Does the LAYOUT move when a threshold moves inside its accepted band?

    A threshold picked to make one corpus count come out zero is worth nothing
    if the answer it produces is sensitive to it.  This re-derives the whole
    segment list at every threshold in the band and reports whether the answer
    changed.  It is the control for `--null`."""
    global PTR_MIN, RAM_MIN, IDENT_MIN, REC_MIN, FILL_MIN, ZERO_MIN
    global HOLEY_MIN, RECBLOCK_MIN, THUNK_MIN
    base = None
    combos = ([("PTR_MIN", v) for v in (3, 4, 5)]
              + [("RAM_MIN", v) for v in (6, 8, 10)]
              + [("IDENT_MIN", v) for v in (10, 12, 16, 24)]
              + [("REC_MIN", v) for v in (8, 12, 16, 24, 27, 32)]
              + [("FILL_MIN", v) for v in (28, 32, 64, 128)]
              + [("ZERO_MIN", v) for v in (16, 32, 64, 128, 256)]
              + [("HOLEY_MIN", v) for v in (16, 24, 32, 48)]
              + [("RECBLOCK_MIN", v) for v in (3, 4, 6, 11)]
              + [("THUNK_MIN", v) for v in (2, 3, 6)])
    saved = dict(PTR_MIN=PTR_MIN, RAM_MIN=RAM_MIN, IDENT_MIN=IDENT_MIN,
                 REC_MIN=REC_MIN, FILL_MIN=FILL_MIN, ZERO_MIN=ZERO_MIN,
                 HOLEY_MIN=HOLEY_MIN, RECBLOCK_MIN=RECBLOCK_MIN,
                 THUNK_MIN=THUNK_MIN)
    d = rom("a")
    _regions_cache.clear()
    base = [(k, a, e) for k, a, e in regions(d)]
    print("baseline: %d content regions with the shipped thresholds" % len(base))
    for name, val in combos:
        for k, v in saved.items():
            globals()[k] = v
        globals()[name] = val
        _regions_cache.clear()
        got = [(k, a, e) for k, a, e in regions(d)]
        same = got == base
        print("  %-10s = %-4d  regions %3d  layout %s"
              % (name, val, len(got), "IDENTICAL" if same else "CHANGED"))
        if not same:
            only_b = [r for r in base if r not in got]
            only_g = [r for r in got if r not in base]
            for r in only_b[:4]:
                print("      lost  %-9s 0x%06X-0x%06X" % (r[0], r[1], r[2] - 1))
            for r in only_g[:4]:
                print("      gained %-8s 0x%06X-0x%06X" % (r[0], r[1], r[2] - 1))
    for k, v in saved.items():
        globals()[k] = v
    _regions_cache.clear()


# --------------------------------------------------------------------- selftest

FAIL = []
CHECKS = [0]


def check(msg, got, want):
    CHECKS[0] += 1
    ok = got == want
    print("  %-66s %-24s %s"
          % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def selftest():
    d = rom("a")
    segs, conflicts, pend, ok, seen, regs, named = build()
    tri = [(k, x, y) for k, x, y in regs]
    of = lambda k: sorted([(x, y) for kk, x, y in regs if kk == k])

    print("A. every byte of the span is in exactly one segment")
    check("first segment starts at LO", "0x%06X" % segs[0][1], "0x%06X" % LO)
    check("LAST segment ends at HI (exclusive)",
          "0x%06X" % (segs[-1][1] + segs[-1][2]), "0x%06X" % HI)
    check("segments contiguous: no gap, no overlap",
          all(segs[i][1] + segs[i][2] == segs[i + 1][1]
              for i in range(len(segs) - 1)), True)
    check("segment sizes sum to the span", sum(n for _, _, n in segs), HI - LO)
    check("no two adjacent segments share a kind",
          all(segs[i][0] != segs[i + 1][0] for i in range(len(segs) - 1)), True)
    check("descent bytes reclaimed by a content rule (structural)",
          len(conflicts), 0)
    check("residue runs left unexplained", len(pend), 1)
    check("residue bytes", sum(e - x for x, e in pend), 14)

    print("B. the LAST segment, checked as hard as the first")
    lk, la, ln = segs[-1]
    check("last segment kind", lk, "fill")
    check("last segment start", "0x%06X" % la, "0xFA9E72")
    check("last segment length", ln, 398)
    check("last segment is all 0x0E",
          sorted(set(d[la - A_BASE:la - A_BASE + ln])), [0x0E])
    check("the byte before it is 0x00 (the zero pad, not more fill)",
          "0x%02X" % d[la - 1 - A_BASE], "0x00")
    check("the byte AT HI starts the next module",
          "0x%02X" % d[HI - A_BASE], "0x1B")
    check("second-to-last segment", "%s 0x%06X %d"
          % (segs[-2][0], segs[-2][1], segs[-2][2]), "zero 0xFA9C78 506")
    check("first segment kind", segs[0][0], "code")
    check("first segment length", segs[0][2], 461)

    print("C. 0xFA5AEB is reached, and ONLY by a PC-relative call")
    rt = rel_targets()
    check("0xFA5AEB is a PC-relative target of proven prom_a code",
          ["0x%06X" % x for x in rt.get(LO, [])], ["0xFA5A82"])
    check("no absolute call/jp site in either image names it",
          LO in far_calls(), False)
    check("the citation is the BRANCH instruction, not one past it",
          d[0xFA5A82 - A_BASE:0xFA5A85 - A_BASE].hex(" "), "1e 66 00")
    check("and its displacement really resolves to 0xFA5AEB",
          "0x%06X" % _rel_target(0xFA5A82,
                                 d[0xFA5A82 - A_BASE:0xFA5A85 - A_BASE]),
          "0xFA5AEB")

    print("D. the relative-branch decoder, audited against the tree's operands")
    n_rel, mism = rel_decoder_audit()
    check("branches whose destination the .s states, recomputed from bytes",
          n_rel, 10037)
    check("mismatches", len(mism), 0)

    print("E. the module boundary and the entry-thunk table at 0xFA6000")
    check("the MIDI module's tail ends, then 826 bytes of 0x0E",
          "%s 0x%06X %d" % (segs[2][0], segs[2][1], segs[2][2]),
          "fill 0xFA5CC6 826")
    o = 0xFA6000 - A_BASE
    check("slot 0 bytes", d[o:o + 4].hex(" "), "1b ae 83 fa")
    check("slots 1-5", d[o + 4:o + 24].hex(" "),
          " ".join(["0e", "00", "00", "00"] * 5))
    check("slot 6 is NOT a slot, it is the first instruction",
          d[o + 24:o + 28].hex(" "), "1d bc 1d f4")
    check("the table is framed as 6 slots",
          ("thunktab", 0xFA6000, 0xFA6018) in tri, True)
    check("T_F40740 holds the bare pointer 0x00FA6000",
          "0x%08X" % w32(rom("b"), 0xF40740, B_BASE), "0x00FA6000")
    check("T_F40710 holds 0x00FA5400 = MIDI_EntryThunks, the same idiom",
          "0x%08X" % w32(rom("b"), 0xF40710, B_BASE), "0x00FA5400")
    check("0xFA6018 (= base+0x18) is T_F40744's target and is code",
          seg_kind(segs, 0xFA6018), "code")

    print("F. every published entry point lands in a code segment")
    for slot, t in sorted(thunk_entries(), key=lambda x: x[1]):
        check("T_%06X -> 0x%06X" % (slot, t), seg_kind(segs, t), "code")
    check("0xFA83AE, slot 0 of the 0xFA6000 table",
          seg_kind(segs, 0xFA83AE), "code")

    print("G. PTRTAB 0xFA8CC8 -- first entry, LAST entry, and the byte after")
    check("start/end", "0x%06X-0x%06X" % of("ptrtab")[-1], "0xFA8CC8-0xFA8FC8")
    check("entry count", (0xFA8FC8 - 0xFA8CC8) // 4, 192)
    check("FIRST entry", "0x%08X" % w32(d, 0xFA8CC8), "0x00FA712A")
    check("LAST entry", "0x%08X" % w32(d, 0xFA8FC4), "0x00FA7129")
    check("the word after it is not a prom_a pointer",
          PTR_LO <= w32(d, 0xFA8FC8) < PTR_HI, False)
    check("every entry is inside this span",
          all(LO <= w32(d, x) < HI for x in range(0xFA8CC8, 0xFA8FC8, 4)), True)

    print("H. PTRTAB 0xFA80FE -- the self-reference truncation, both readings")
    check("framed as 11 entries", ("ptrtab", 0xFA80FE, 0xFA812A) in tri, True)
    check("the naive chain would run to 13 entries",
          "0x%06X" % (0xFA80FE + 4 * 13), "0xFA8132")
    check("entry [0] = 0x00FA812A, which the 13-entry reading swallows",
          "0x%08X" % w32(d, 0xFA80FE), "0x00FA812A")
    check("entries 11 and 12 are the record's own two pointer fields",
          "%08X %08X" % (w32(d, 0xFA812A), w32(d, 0xFA812E)),
          "00FA820B 00FA771D")
    check("entry [10], the last", "0x%08X" % w32(d, 0xFA8126), "0x00FA81A2")
    check("the entries are an AP of stride 12",
          sorted(set(w32(d, x + 4) - w32(d, x)
                     for x in range(0xFA80FE, 0xFA8126, 4))), [12])

    print("I. RECBLOCK 0xFA812A -- 11 records of 12 bytes, and its END")
    check("framed", ("recblock", 0xFA812A, 0xFA81AE) in tri, True)
    check("record count", (0xFA81AE - 0xFA812A) // 12, 11)
    check("every record's fields 0 and 1 are prom_a pointers",
          all(PTR_LO <= w32(d, x) < PTR_HI and PTR_LO <= w32(d, x + 4) < PTR_HI
              for x in range(0xFA812A, 0xFA81AE, 12)), True)
    check("LAST record's fields", "%08X %08X %s"
          % (w32(d, 0xFA81A2), w32(d, 0xFA81A6),
             d[0xFA81AA - A_BASE:0xFA81AE - A_BASE].hex(" ")),
          "00FA8292 00FA778B b3 00 7f 7f")
    check("the byte AFTER the block is the target of `calr` at 0xFA83AA",
          "0x%06X" % _rel_target(0xFA83AA,
                                 d[0xFA83AA - A_BASE:0xFA83AD - A_BASE]),
          "0xFA81AE")

    print("J. RAMTAB 0xFA83C0 -- the entry count is fixed by a loop counter")
    check("framed as 10 entries", ("ramtab", 0xFA83C0, 0xFA83E8) in tri, True)
    check("FIRST entry", "0x%04X" % w32(d, 0xFA83C0), "0x19F0")
    check("LAST entry", "0x%04X" % w32(d, 0xFA83E4), "0x1A80")
    check("the routine at 0xFA83AE loads this table's base",
          d[0xFA83AE - A_BASE:0xFA83B3 - A_BASE].hex(" "), "44 c0 83 fa 00")
    check("and its loop counter `ld C,0x0a` is 10, the entry count",
          d[0xFA83B3 - A_BASE:0xFA83B5 - A_BASE].hex(" "), "23 0a")
    check("the word after the table is not a RAM address",
          0 < w32(d, 0xFA83E8) < 0x10000, False)

    print("K. RAMTAB 0xFA8FF8 and 0xFA82DE -- 800 and 32 entries")
    check("framed", ("ramtab", 0xFA8FF8, 0xFA9C78) in tri, True)
    check("entry count", (0xFA9C78 - 0xFA8FF8) // 4, 800)
    check("= 25 blocks of 32", 800 // 32, 25)
    check("FIRST entry", "0x%04X" % w32(d, 0xFA8FF8), "0x76AF")
    check("LAST entry", "0x%04X" % w32(d, 0xFA9C74), "0x7EAF")
    check("the word after it is zero, so the chain really ended",
          w32(d, 0xFA9C78), 0)
    # ⚠ Added after the wave-7 skeptic pointed out that check K verified the count,
    # the block arithmetic, the first entry, the last entry and the terminator --
    # and never the one property that matters for the READING: whether the 25 blocks
    # differ.  They do not.  The table is one 32-entry cycle repeated 25 times, so
    # THE ROW INDEX SELECTS NOTHING, and it cannot be the per-parameter dispatch
    # layer the first draft's verdict described.  See open question 9.
    _e = [w32(d, 0xFA8FF8 + 4 * i) for i in range(800)]
    _blocks = [tuple(_e[i * 32:(i + 1) * 32]) for i in range(25)]
    check("★ the 25 blocks are IDENTICAL -- the row index selects nothing",
          len(set(_blocks)), 1)
    check("★ so all 800 entries hold only 32 distinct values", len(set(_e)), 32)
    check("...and it is a strict cycle: entry[i] == entry[i mod 32], all 800",
          all(_e[i] == _e[i % 32] for i in range(800)), True)
    check("the cycle runs 0x76AF..0x7EAF in 30 steps of 0x40 and one of 0x80",
          sorted(collections.Counter(
              _e[i + 1] - _e[i] for i in range(31)).items()),
          [(0x40, 30), (0x80, 1)])
    check("nothing before 0xFA8FF8 continues the cycle (the start is pinned)",
          w32(d, 0xFA8FF8 - 4) == _e[31], False)

    print("K2. every naming site is an INSTRUCTION address, not an operand")
    # ⚠ The wave-7 skeptic found ~31 evidence citations one byte past the
    # instruction -- all of them the imm32 of an `ld XIX/XIY/XIZ,imm32`.  --sites
    # is the reproducible source for them now, and this check is what keeps it
    # honest: cited-1 being 0x44/0x45/0x46 is the SYMPTOM of the off-by-one, so
    # every site's own first byte must be the opcode instead.
    build()
    _bad = [(v, s) for v in NAMED_SITES for s in NAMED_SITES[v]
            if d[s - A_BASE] not in (0x44, 0x45, 0x46, 0xF0, 0xC0, 0xD0, 0xE0)]
    check("naming sites collected", sum(len(s) for s in NAMED_SITES.values()) > 0, True)
    check("★ sites whose first byte is NOT an opcode (the off-by-one signature)",
          len(_bad), 0)
    check("0xFA82DE framed as 32 entries",
          ("ramtab", 0xFA82DE, 0xFA835E) in tri, True)
    check("  its FIRST entry", "0x%04X" % w32(d, 0xFA82DE), "0x76D5")
    check("  its LAST entry", "0x%04X" % w32(d, 0xFA835A), "0x7ED5")
    st = [w32(d, x + 4) - w32(d, x) for x in range(0xFA82DE, 0xFA835A, 4)]
    check("  its steps: 0x40 everywhere except ONE 0x80",
          (st.count(0x40), st.count(0x80), len(st)), (30, 1, 31))
    check("  the 0x80 step is between entries 7 and 8", st.index(0x80), 7)

    print("L. the two 0xFF-sentinel maps are MUTUAL INVERSES")
    cc2ix = d[0xFA83E8 - A_BASE:0xFA8468 - A_BASE]
    ix2cc = d[0xFA8FC8 - A_BASE:0xFA8FF8 - A_BASE]
    check("map 1 length = 128 (one entry per MIDI controller number)",
          len(cc2ix), 128)
    check("map 2 length = 48", len(ix2cc), 48)
    live = [(i, c) for i, c in enumerate(ix2cc) if c != 0xFF]
    live1 = [(c, i) for c, i in enumerate(cc2ix) if i != 0xFF]
    check("live entries of map 2 (index -> CC)", len(live), 25)
    check("live entries of map 1 (CC -> index)", len(live1), 23)
    check("FIRST live of map 2: index %d <-> CC 0x%02X"
          % (live[0][0], live[0][1]), cc2ix[live[0][1]], live[0][0])
    check("LAST live of map 2:  index %d <-> CC 0x%02X"
          % (live[-1][0], live[-1][1]), cc2ix[live[-1][1]], live[-1][0])
    check("of map 2's 25 live entries, how many round-trip",
          sum(1 for i, c in live if cc2ix[c] == i), 23)
    check("the 2 that do not are indices 16 and 17",
          [i for i, c in live if cc2ix[c] != i], [16, 17])
    check("  and their CCs are 0x50 and 0x52, which map 1 leaves 0xFF",
          [(hex(c), hex(cc2ix[c])) for i, c in live if cc2ix[c] != i],
          [("0x50", "0xff"), ("0x52", "0xff")])
    check("EVERY live entry of map 1 round-trips CC -> index -> CC",
          all(ix2cc[i] == c for c, i in live1), True)
    check("so map 1 is exactly the inverse of map 2 minus those two",
          sorted(set(i for i, _ in live) - {16, 17}),
          sorted(i for _, i in live1))

    print("M. the record arrays, first group and LAST group")
    rec = of("recarr")
    check("recarr regions", len(rec), 23)
    check("FIRST group", "0x%06X-0x%06X" % rec[0], "0xFA84C8-0xFA8528")
    check("  its first record", d[0xFA84C8 - A_BASE:0xFA84CB - A_BASE].hex(" "),
          "b5 00 7f")
    check("  its LAST record", d[0xFA8525 - A_BASE:0xFA8528 - A_BASE].hex(" "),
          "b5 1f 7f")
    check("LAST group", "0x%06X-0x%06X" % rec[-1], "0xFA8C88-0xFA8CC8")
    check("  its first record", d[0xFA8C88 - A_BASE:0xFA8C8A - A_BASE].hex(" "),
          "00 00")
    check("  its LAST record", d[0xFA8CC6 - A_BASE:0xFA8CC8 - A_BASE].hex(" "),
          "1f 00")
    check("every group holds exactly 32 records",
          sorted(set(k for x, e, st, k, dl in record_arrays(d, LO, HI))), [32])
    check("IDENT 0xFA8C68 is 0x00..0x1F",
          list(d[0xFA8C68 - A_BASE:0xFA8C88 - A_BASE]), list(range(32)))

    print("N. the 256-entry map at 0xFA7FFE indexes the 11 records")
    m = d[0xFA7FFE - A_BASE:0xFA80FE - A_BASE]
    check("length", len(m), 256)
    check("its live values are indices into that table, max 10",
          sorted(set(v for v in m if v != 0xFF)),
          [0, 1, 2, 3, 4, 5, 6, 7, 10])
    check("the pointer table has 11 entries", (0xFA812A - 0xFA80FE) // 4, 11)
    check("⚠ entries 8 and 9 are never selected BY THIS MAP -- an open hole",
          sorted({8, 9} - set(m)), [8, 9])
    check("it has 9 live entries and 9 distinct values: a bijection",
          (sum(1 for v in m if v != 0xFF),
           len(set(v for v in m if v != 0xFF))), (9, 9))
    check("the live positions of that map",
          [hex(i) for i, v in enumerate(m) if v != 0xFF],
          ["0x1", "0x2", "0x4", "0xb", "0x10", "0x11", "0x12", "0x13", "0x40"])
    check("map 1's 23 live entries equal the HOLEY rule's live-byte count",
          sum(1 for c in cc2ix if c != 0xFF), 23)

    print("O. the boundaries have a SECOND, independent witness")
    loaded = [(k, x) for k, x, _ in regs if x in named]
    check("framed objects whose base a decoded instruction LOADS",
          len(loaded), 40)
    check("of 46 framed objects", len(regs), 46)
    check("the 6 without one are the padding, the thunk table and the recblock",
          sorted(set(k for k, x, _ in regs if x not in named)),
          ["fill", "ptrtab", "recblock", "thunktab", "zero"])
    check("  the thunk table's base is named by prom_b's directory instead",
          0xFA6000 in directory_pointers(), True)
    check("  the recblock's base is entry [0] of the table in front of it",
          "0x%08X" % w32(d, 0xFA80FE), "0x00FA812A")
    check("  and the one PTRTAB without one is 0xFA7520, whose base IS loaded",
          d[0xFA7514 - A_BASE:0xFA7519 - A_BASE].hex(" "), "45 20 75 fa 00")
    check("  (by `ld XIY,0x00FA7520` at 0xFA7514, inside an accept()ed run,",
          seg_kind(segs, 0xFA7514), "code")
    check("   and accept()ed runs do not feed the named set -- a known gap)",
          0xFA7520 in named, False)

    print("P. the kinds present")
    check("kinds", sorted(set(k for k, _, _ in segs)),
          ["align", "code", "data", "fill", "holey", "ident", "ptrtab",
           "ramtab", "recarr", "recblock", "thunktab", "zero"])
    print()
    print("%d checks, %d FAILED" % (CHECKS[0], len(FAIL)))
    for msg in FAIL:
        print("  FAILED: %s" % msg)
    return 1 if FAIL else 0


_INCBIN = None


def in_incbin(addr):
    """Is this prom_a address still inside an `.incbin` of the transcription?"""
    global _INCBIN
    if _INCBIN is None:
        _INCBIN = []
        for l in source_text().splitlines():
            m = re.search(r'\.incbin\s+"[^"]*wsa1_prom_a[^"]*",\s*(0x[0-9A-Fa-f]+),'
                          r'\s*(0x[0-9A-Fa-f]+)', l)
            if m:
                o = int(m.group(1), 16)
                n = int(m.group(2), 16)
                _INCBIN.append((A_BASE + o, A_BASE + o + n))
    return any(a <= addr < b for a, b in _INCBIN)


def seg_kind(segs, addr):
    for k, a, n in segs:
        if a <= addr < a + n:
            return k
    return None


# ------------------------------------------------------------------------- main

def frontier():
    """Re-derive the ranking that chose this span, from the ROM and the .s."""
    b = rom("b")
    slots = {}
    for s in range(0x40000, 0x44018, 4):
        if b[s] == 0x1B:
            slots[B_BASE + s] = b[s + 1] | b[s + 2] << 8 | b[s + 3] << 16
    runs, cur = [], []
    for s in sorted(slots):
        if cur and s == cur[-1] + 4:
            cur.append(s)
        else:
            if cur:
                runs.append(cur)
            cur = [s]
    if cur:
        runs.append(cur)
    rows = []
    for r in runs:
        unc = [slots[s] for s in r
               if A_BASE <= slots[s] < 0x1000000 and in_incbin(slots[s])]
        if not unc:
            continue
        rows.append((max(unc) - min(unc), len(unc), min(unc), max(unc), r[0], r[-1]))
    rows.sort(reverse=True)
    print("thunk runs with unconverted prom_a targets, by contiguous extent")
    for ext, n, mn, mx, s0, s1 in rows[:8]:
        mark = "  <== THIS SPAN" if LO <= mn < HI else ""
        print("  T_%06X-T_%06X  %2d unconverted  0x%06X-0x%06X  extent %6d%s"
              % (s0, s1, n, mn, mx, ext, mark))


def main():
    if "--null" in sys.argv:
        rev = None
        if "--rev" in sys.argv:
            rev = sys.argv[sys.argv.index("--rev") + 1]
        null(rev)
        return 0
    if "--sites" in sys.argv:
        # ★ Every in-span address the decoded code NAMES, with the INSTRUCTION
        # addresses that name it.  Cite from THIS, never from a hexdump offset: the
        # `ld XIX/XIY/XIZ,imm32` opcode is at p and its immediate at p+1, and a
        # citation of p+1 is the systematic off-by-one this project has now made
        # twice.  The check line under each address proves p is the instruction.
        build()
        d = rom("a")
        print("named address   named by (INSTRUCTION addresses)")
        bad = 0
        for v in sorted(NAMED_SITES):
            sites = sorted(NAMED_SITES[v])
            print("  0x%06X      %s" % (v, ", ".join("0x%06X" % s for s in sites)))
            for s in sites:
                op = d[s - A_BASE]
                if op not in (0x44, 0x45, 0x46, 0xF0, 0xC0, 0xD0, 0xE0):
                    bad += 1
        print("\n%d named addresses, %d naming sites; %d sites whose first byte is not"
              % (len(NAMED_SITES), sum(len(s) for s in NAMED_SITES.values()), bad))
        print("a recognised opcode (0 means every citation is at an instruction, not an operand)")
        return 0
    if "--frontier" in sys.argv:
        frontier()
        return 0
    if "--stability" in sys.argv:
        stability()
        return 0
    if "--tables" in sys.argv:
        segs, conflicts, pend, ok, seen, regs, named = build()
        img = rom("a")
        print("every framed object, in address order, with its shape")
        for k, x, y in regs:
            n = y - x
            extra = ""
            if k == "ptrtab":
                extra = "%d entries, [0]=0x%08X [-1]=0x%08X" % (
                    n // 4, w32(img, x), w32(img, y - 4))
            elif k == "ramtab":
                extra = "%d entries, [0]=0x%04X [-1]=0x%04X" % (
                    n // 4, w32(img, x), w32(img, y - 4))
            elif k == "recarr":
                r = [t for t in record_arrays(img, LO, HI) if t[0] == x]
                if r:
                    _, _, st, kk, dl = r[0]
                    extra = "stride %d x%d  first %s  last %s  deltas %s" % (
                        st, kk, img[x - A_BASE:x - A_BASE + st].hex(" "),
                        img[y - st - A_BASE:y - A_BASE].hex(" "), dl)
            elif k == "recblock":
                extra = "%d records of 12" % (n // 12)
            elif k in ("holey",):
                ff = sum(1 for z in range(x, y) if img[z - A_BASE] == 0xFF)
                extra = "%d of %d bytes are 0xFF; %d live entries" % (
                    ff, n, n - ff)
            elif k == "thunktab":
                extra = "%d slots, %d live" % (
                    n // 4, sum(1 for z in range(x, y, 4)
                                if img[z - A_BASE] == 0x1B))
            elif k == "ident":
                extra = "0x%02X..0x%02X" % (img[x - A_BASE], img[y - 1 - A_BASE])
            print("  %-9s 0x%06X-0x%06X %6d %s %s"
                  % (k, x, y - 1, n, "LOADED" if x in named else "      ",
                     extra))
        print("  %d framed objects, %d bytes"
              % (len(regs), sum(y - x for _, x, y in regs)))
        print("  LOADED = an instruction the descent decoded takes this exact")
        print("  address as an operand.  %d of %d objects are LOADED; that is"
              % (sum(1 for _, x, _ in regs if x in named), len(regs)))
        print("  boundary evidence INDEPENDENT of the content rule that framed")
        print("  the object, and the two agree everywhere.")
        return 0
    if "--code" in sys.argv:
        segs, conflicts, pend, ok, seen, regs, named = build()
        print("CODE segments: does a LINEAR decode consume each one exactly?")
        print("(a conversion lane emits one region per segment; a segment that")
        print(" does not decode exactly is one it cannot emit)")
        bad = 0
        tot = 0
        for k, a, n in segs:
            if k != "code":
                continue
            tot += n
            b = decode_bounds(a, a + n)
            last = None
            p2 = a
            while p2 < a + n:
                dec = decode_at(p2)
                if dec is None:
                    break
                last = dec[1]
                p2 += dec[0]
            good = b is not None
            if not good:
                bad += 1
            print("  0x%06X-0x%06X %6d  %-9s ends: %s"
                  % (a, a + n - 1, n, "EXACT" if good else "RAGGED",
                     (last or "?")[:34]))
        print("  %d code segments, %d bytes, %d that do not decode exactly"
              % (sum(1 for k, _, _ in segs if k == "code"), tot, bad))
        acc = sum(e - x for (x, e) in ok)
        print("  of the code bytes, %d came from the recursive descent and %d"
              % (tot - acc, acc))
        print("  from accept() -- a self-consistent run ending in a flow end")
        print("  that no walk reached.  %d runs were accepted." % len(ok))
        return 0
    if "--selftest" in sys.argv:
        return selftest()
    d = rom("a")
    if "--seeds" in sys.argv:
        th = set(t for _, t in thunk_entries())
        fc = far_calls()
        rt = set(rel_targets())
        te = table_entry_seeds(d)
        dp = directory_pointers()
        tt = thunktab_targets(d)
        block = barriers(d)
        print("seed sources for the descent (all in 0x%06X-0x%06X):" % (LO, HI))
        print("  thunk targets           %3d  %s"
              % (len(th), " ".join("0x%06X" % a for a in sorted(th))))
        print("  absolute call/jp sites  %3d  %s"
              % (len(fc), " ".join("0x%06X" % a for a in sorted(fc)[:8])))
        print("  PC-relative from the .s %3d  %s"
              % (len(rt), " ".join("0x%06X" % a for a in sorted(rt))))
        print("  PTRTAB entries          %3d  %s"
              % (len(te), " ".join("0x%06X" % a for a in sorted(te)[:8])))
        print("  directory bare pointers %3d  %s"
              % (len(dp), " ".join("0x%06X" % a for a in sorted(dp))))
        print("  thunk-table jp targets  %3d  %s"
              % (len(tt), " ".join("0x%06X" % a for a in sorted(tt))))
        u = th | fc | rt | te | dp | tt
        print("  union                   %3d  (%d inside a barrier, dropped)"
              % (len(u), len(u & block)))
        for name, extra in (("thunks only", th), ("+ absolute", th | fc),
                            ("+ PC-relative", th | fc | rt),
                            ("+ PTRTAB entries", th | fc | rt | te),
                            ("+ directory ptrs", th | fc | rt | te | dp | tt)):
            got = descend(d, LO, HI, sorted(extra), block)
            print("  descent %-18s %6d bytes" % (name, len(got)))
        return 0
    if "--barrier" in sys.argv:
        block = barriers(d)
        seeds = sorted(all_seeds(d))
        wb = descend(d, LO, HI, seeds, block)
        nb = descend(d, LO, HI, seeds, set())
        print("code walk WITH the barrier:    %6d bytes (%.1f%% of %d)"
              % (len(wb), 100.0 * len(wb) / (HI - LO), HI - LO))
        print("code walk WITHOUT the barrier: %6d bytes (%.1f%%)"
              % (len(nb), 100.0 * len(nb) / (HI - LO)))
        print("of those, %d bytes are inside an object a content rule framed --"
              % len(nb & block))
        print("that is what the barrier removes.")
        return 0
    segs, conflicts, pend, ok, seen, regs, named = build()
    if "--conflicts" in sys.argv:
        print("descent bytes reclaimed by a barrier rule: %d  (MUST be 0)"
              % len(conflicts))
        for a in conflicts[:80]:
            print("  0x%06X" % a)
        return 0
    if "--residue" in sys.argv:
        print("runs that are neither code, table nor padding: %d (%d bytes)"
              % (len(pend), sum(e - s for s, e in pend)))
        for s, e in pend:
            raw = d[s - A_BASE:e - A_BASE]
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "." for c in raw[i:i + 16])))
            print()
        return 0
    if "--python" in sys.argv:
        print("LAYOUT = [")
        for k, s, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, s, n))
        print("]")
        return 0
    tot = {}
    for k, s, n in segs:
        print("  %-6s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    print("  substantive %d of %d"
          % (sum(v for k, v in tot.items() if k not in ("fill", "zero")), HI - LO))
    print("  segments %d   accepted self-consistent runs %d   barrier conflicts %d"
          % (len(segs), len(ok), len(conflicts)))
    print("  residue %d runs, %d bytes (see --residue)"
          % (len(pend), sum(e - s for s, e in pend)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
