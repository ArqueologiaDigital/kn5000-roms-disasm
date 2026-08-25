#!/usr/bin/env python3
"""The code/data LAYOUT of prom_b 0xF0EA9F-0xF13D33.

⚠ The block is NOT named here.  The strings just above it are the DSP EFFECT
screen's and its three big tables have 128 entries each, which is also the number
of entries in the effect-name table at 0xF147AC -- but nothing decoded in the
block reads that table, so "the effect editor" would be a guess.  See
notes/FINDINGS-prom_b-f0ea9f-module.md sec.4.

QUESTION IT ANSWERS
  "Which bytes of this block are instructions, which are tables, and which are
   neither -- and WHY is each code byte code?"  The answer is computed here and
   FROZEN into notes/gen_prom_b_f0ea9f_module.py's LAYOUT, whose checks()
   re-derives it on every emit.  Nothing in the layout is typed by hand.

WHAT IS DIFFERENT FROM notes/prom_b_f65000_layout.py, WHICH THIS IMPORTS
  Five things, and every one of them exists because round 4's method, applied
  here unchanged, produced FALSE CODE the byte gate cannot see.
  1. PTRTAB's window is the WHOLE image, 0x00F00000-0x00F7FFFF, not
     0x00F60000-0x00F6FFFF.  NULL re-measured for the wider window: still ZERO.
  2. THE CONSUMER RULE (`consumer()`): a pointer table seeds the code walk only
     if the code that indexes it TRANSFERS to the entry.  Two of this module's
     three 128-entry tables are read with `ld H,(XWA)` instead.
  3. STRIDED (`strided()`): a table whose entries are an arithmetic progression
     is an ARRAY descriptor.  NULL: 0 of the image's 33 proven dispatch tables.
  4. BYTEMAP (`monotone_maps()`): an ascending byte table with 0xFF holes, which
     IDENT cannot see and which ASCII was calling a string.  NULL: 0.
  5. NO IMMEDIATE-SEEDING (`descend_no_immediates()`), and `accept()` requires
     the decode to END IN A FLOW END (`prom_b_f65000_layout.ends_in_flow_end`).

THE NULL CORPORA, AND WHY THERE ARE THREE
  * CONTENT rules (PTRTAB/RAMTAB/BITTAB/IDENT/ASCII/BYTEMAP): the corpus is
    proven CODE -- a content rule that fires inside proven instruction text is a
    false positive.  `--null-ptr`.
  * `accept()`, which promotes an unreached run TO code: proven code is the WRONG
    corpus and round 4 had no other.  The corpus here is proven DATA -- the 4,011
    display-list records of notes/FINDINGS-ui-display-list.md, whose framing is
    self-checking.  `--null-accept`.
  * STRIDED, which demotes a table: the corpus is proven DISPATCH TABLES.
    `--null-stride`.

RUN
  python3 notes/prom_b_f0ea9f_layout.py                 # the LAYOUT table
  python3 notes/prom_b_f0ea9f_layout.py --null-ptr      # content-rule null
  python3 notes/prom_b_f0ea9f_layout.py --null-accept   # accept() null, on DATA
  python3 notes/prom_b_f0ea9f_layout.py --null-stride   # STRIDED null, on tables
  python3 notes/prom_b_f0ea9f_layout.py --provenance    # WHY each segment is code
  python3 notes/prom_b_f0ea9f_layout.py --conflicts     # descent-vs-barrier
  python3 notes/prom_b_f0ea9f_layout.py --residue       # unsplit runs, with hex
  python3 notes/prom_b_f0ea9f_layout.py --python        # paste-ready LAYOUT
Exit status is non-zero if a --null run finds a false positive it must not.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_display_lists as DL                                  # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402
import trace_code as TC                                            # noqa: E402

LO, HI = 0xF0EA9F, 0xF13D34
PTR_LO, PTR_HI = 0x00F00000, 0x00F80000
L.PTR_LO, L.PTR_HI = PTR_LO, PTR_HI          # the widened window, module-wide
STRIDE_MIN = 4                               # entries needed to call it strided
STRIDE_BYTES = 8                             # smallest stride the rule will call
                                             # an array: measured, see null_stride


def strided(vals, minent=STRIDE_MIN):
    """Is this word list a constant-stride arithmetic progression?

    THE RULE THIS MODULE NEEDED AND THE 0xF65000 ONE DID NOT.  The table at
    0xF0EE6C is 29 consecutive words stepping by exactly 72, from 0x00F0EEE0 to
    0x00F0F6C0.  A handler table cannot look like that -- handlers are different
    lengths -- so a constant stride says ARRAY OF FIXED-SIZE RECORDS, and the
    first four targets are exactly that: 4 x 72 bytes of bitmap at
    0xF0EEE0-0xF0EFFF, which the descent decoded as `nop nop nop nop nop /
    normal / pop SR / reti` until this rule stopped it.

    Such a table is still emitted as `.long` -- it IS a table of words -- but its
    entries do NOT seed the code walk.

    NULL (`--null-stride`): over every PROVEN dispatch table in this image -- the
    31 tables of the 0xF65000 module and the two display-list handler tables --
    ZERO have a constant-stride run of %d entries or more.""" % STRIDE_MIN
    if len(vals) < minent:
        return False
    step = vals[1] - vals[0]
    if step < STRIDE_BYTES:                  # see the note on stride 1, below
        return False
    return all(vals[i + 1] - vals[i] == step for i in range(len(vals) - 1))


TRANSFER_RE = re.compile(r"^(call|jp)\s+(?:\w+,)?X(WA|BC|DE|HL|IX|IY|IZ)$")
DEREF_RE = re.compile(r"^ld\s+(?:[A-EHLWQ]|[A-E]?[WHL])\s*,\s*\(X(WA|BC|DE|HL|IX|IY)\)$")


def indexers(d, base):
    """Opcode-anchored instructions in prom_a+prom_b whose operand is `base`.

    Same backward decode the rest of this lane uses: a 32-bit LE spelling of the
    address, with the instruction that CONTAINS it recovered by decoding from
    1-4 bytes before it, so `add XWA,imm32` (two-byte opcode) and `ld XIX,imm32`
    (one) are both found at the right address."""
    tgt = base.to_bytes(4, "little")
    out = []
    for blob, bs in ((L.rom("a"), 0xF80000), (d, L.B_BASE)):
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            for back in (1, 2, 3, 4):
                dec = MT.decode_at(bs + i - back)
                if dec and dec[0] > back and ("%06x" % base) in dec[1]:
                    out.append((bs + i - back, dec[1]))
                    break
            i += 1
    return out


def consumer(d, base, depth=24):
    """Does the code that indexes this table TRANSFER to the entry, or READ it?

    THE RULE THAT MATTERS MOST IN THIS MODULE, and the one round 4 did not need.
    `table_entry_seeds()` treats every pointer table as a table of ENTRY POINTS.
    Two of this module's three 128-entry tables are not:

      0xF131E4  add XBC,imm / ld XBC,(XBC) / lda XIY,ret / push XIY / jp T,XBC
                -- a dispatch table.  Its entries ARE entry points.
      0xF12F24  add XWA,imm / ld XWA,(XWA) / add XWA,XBC / ld H,(XWA) / cp H,0xff
                -- a table of DATA pointers.  The firmware reads a BYTE through
                it and compares it with 0xFF.  Its targets are the 4-byte records
                at 0xF124EC-0xF12EE4 (`00 00 ff ff / 01 01 01 00 / 19 01 02 01`),
                and seeding the descent with them decoded 62 record runs as
                instructions -- one-byte "routines" whose single byte is 0x07.
      0xF13674  add XBC,imm / ld XBC,(XBC) / ... / ld A,(XBC)  -- data pointers.

    So: walk forward from each indexer, and take the FIRST of a register
    control-transfer (=> TRANSFER, entries seed the walk) or an 8/16-bit load
    through a register (=> DEREF, entries do NOT seed).  A table with no
    decodable indexer is UNKNOWN and does not seed either -- conservative on
    purpose, and every one of them is printed by --tables."""
    for q, _ in indexers(d, base):
        p, n = q, 0
        while n < depth:
            dec = MT.decode_at(p)
            if dec is None:
                break
            t = dec[1].strip()
            if TRANSFER_RE.match(t):
                return "TRANSFER"
            if DEREF_RE.match(t):
                return "DEREF"
            if TC.is_flow_end(t):
                break
            p += dec[0]
            n += 1
    return "UNKNOWN"


_cons = {}


def table_kind(d, a, e):
    """(kind, why) for the pointer table at [a,e): STRIDED / DEREF / TRANSFER /
    UNKNOWN.  Only TRANSFER contributes seeds."""
    if (a, e) not in _cons:
        vals = [L.w32(d, x) for x in range(a, e, 4)]
        _cons[(a, e)] = "STRIDED" if strided(vals) else consumer(d, a)
    return _cons[(a, e)]


def table_entry_seeds(d, lo, hi):
    """L.table_entry_seeds() restricted to tables the firmware TRANSFERS to."""
    out = set()
    for a, e in L.ptr_tables(d, lo, hi):
        if table_kind(d, a, e) != "TRANSFER":
            continue
        for x in range(a, e, 4):
            v = L.w32(d, x)
            if lo <= v < hi:
                out.add(v)
    return out


L.table_entry_seeds = table_entry_seeds      # the descent uses the filtered set


MONO_MIN, MONO_VALS = 16, 12


def monotone_maps(d, lo, hi, minlen=MONO_MIN, minval=MONO_VALS):
    """Maximal runs of a BYTE MAP: every byte is 0xFF, or strictly greater than
    the previous non-0xFF byte.

    The sixth content rule, and this module is why.  0xF13404-0xF135A1 is three
    of them -- `00 01 02 03 04 05 06 ff 07 08 09 0a ff ff ... ff 0b 0c 0d ...` --
    a map from one index to another with 0xFF meaning ABSENT, which is exactly
    what the consumer at 0xF10619 tests for (`ld H,(XWA) / cp H,0xff`).  L's
    IDENT rule needs +1 exactly and sees only the unbroken stretches, so the walk
    decoded the gaps between them as `nop / normal / push SR / pop SR / max /
    halt / ei 0xff / reti`.

    STRICTLY GREATER, not +1, and that is what the region needs: 0xF13464 is
    `00 01 02 03 04 05 06 08 09 0a 0b 20 21 ... 63` -- ascending with JUMPS.  The
    tail of it is 36 consecutive printable bytes, so the ASCII rule framed that
    tail as a STRING.  Six such runs in this block are index tables, not text,
    and this rule is painted over ASCII so that none of them gets a `Text_` name
    it has not earned.

    NULL: over the same proven-instruction-text corpus as the other content
    rules -- 3,887 runs, 73,081 bytes at the time of writing -- this fires ZERO
    times at (16 bytes, 12 values), and also at (20,14), (24,16) and (16,16).
    `--null-ptr` re-runs it.  A run is trimmed of trailing 0xFF so the rule
    cannot swallow padding it did not earn."""
    out, p = [], lo
    while p < hi:
        if d[p - L.B_BASE] == 0xFF:
            p += 1
            continue
        q, last, nv = p, None, 0
        while q < hi:
            v = d[q - L.B_BASE]
            if v == 0xFF:
                q += 1
                continue
            if last is None or v > last:
                last, nv, q = v, nv + 1, q + 1
            else:
                break
        e = q
        while e > p and d[e - 1 - L.B_BASE] == 0xFF:
            e -= 1
        if e - p >= minlen and nv >= minval:
            out.append((p, e))
            p = e
        else:
            p += 1
    return out


def barriers(d, lo, hi):
    """L.barriers() plus the SPARSEMAP rule."""
    b = L.barriers(d, lo, hi)
    for a, e in monotone_maps(d, lo, hi):
        b |= set(range(a, e))
    return b


def descend_no_immediates(d, lo, hi, seeds, block):
    """L.descend() WITHOUT the "follow every 32-bit immediate" seed source.

    Round 4 priced that source at +4,688 bytes in the 0xF65000 module and warned
    that "a stored address is as often a DATA address".  In THIS module it is
    not as often, it is always: with it on, `--provenance` grades eight code
    segments (266 bytes) as reachable ONLY through a loaded immediate, and all
    eight are data -- 0xF133E4, 0xF13464, 0xF13491, 0xF13511, 0xF1353E,
    0xF135BE, 0xF135F7 are fragments of the byte maps above, and
    0xF13874 is 218 bytes of `60 00 01 / 61 00 ff / 61 01 ff / 61 02 ff ...`,
    a three-byte-record table with an ascending field.  Eight for eight, so the
    source is off here and the loss is stated: nothing else in the block is
    reached only that way."""
    seen, work = set(), [s for s in seeds if s not in block]
    while work:
        p = work.pop()
        while lo <= p < hi and p not in seen and p not in block:
            dec = MT.decode_at(p)
            if dec is None:
                break
            n, txt = dec
            if any((p + i) in block for i in range(n)):
                break
            seen.update(range(p, p + n))
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen and t not in block:
                    work.append(t)
            if TC.is_flow_end(txt):
                break
            p += n
    return seen


def proven_call_sites(lo=None, hi=None):
    """Branch targets in [lo,hi) taken by instructions ALREADY PROVEN in the .s.

    The strongest seed there is.  Every instruction line of
    prom_a/wsa1_prom_a.s and prom_b/wsa1_prom_b.s carries its MAME text in a
    `; ADDR  <text>` comment and the byte gate proves the file rebuilds the
    image, so a `call`/`calr`/`jp`/`jrl` decoded there is a transfer the
    firmware really makes -- no byte-window scan, no upper bound.  It is what
    reaches this module's head: `calr 0xf0ea9f` at 0xF0EA97, inside the
    already-converted field-blink engine.

    ⚠ A SITE INSIDE [lo,hi) DOES NOT COUNT, and that is not cosmetic
    (found 2026-08-25, round 6).  While the block is still `.incbin` no site can
    be inside it, so this function returns the same set either way -- but AFTER
    the block is spliced in, its own thousands of internal `jr`/`jp` lines match
    the pattern too, and the function's answer for the 0xF6D002 block goes from
    76 to 1,119.  A generator that used the unfiltered set would then emit a
    DIFFERENT file from the one already in the `.s` -- it would not reproduce its
    own output -- and the grade "an already-converted call site ELSEWHERE in the
    image" would stop being true.  Excluding internal sites is what both the name
    and the round-5 measurement always meant."""
    lo = LO if lo is None else lo
    hi = HI if hi is None else hi
    out = set()
    for img in ("a", "b"):
        src = os.path.join(ROOT, "prom_%s" % img, "wsa1_prom_%s.s" % img)
        for ln in open(src):
            if ";" not in ln:
                continue
            m = re.search(r";\s*([0-9A-F]{6})\s+(call|calr|jp|jr|jrl)\s+"
                          r"(?:\w+,)?0x([0-9a-f]{6})", ln)
            if m:
                site, t = int(m.group(1), 16), int(m.group(3), 16)
                if lo <= t < hi and not (lo <= site < hi):
                    out.add(t)
    return out


def seeds(d, lo=None, hi=None):
    lo = LO if lo is None else lo
    hi = HI if hi is None else hi
    return (proven_call_sites(lo, hi)
            | set(t for _, t in MT.thunk_entries(lo, hi))
            | L.far_calls(d, lo, hi) | table_entry_seeds(d, lo, hi))


_orig_build = L.build


def build():
    """L.build() with this module's seed set, which adds the PROVEN call sites."""
    d = L.rom()
    block = barriers(d, LO, HI)
    seen = descend_no_immediates(d, LO, HI, sorted(seeds(d)), block)
    gaps = L.gaps_of(LO, HI, seen, block)
    ok, pend = L.accept(d, gaps, seen)
    kind = ["data"] * (HI - LO)
    for a in seen:
        if LO <= a < HI:
            kind[a - LO] = "code"
    for (a, e) in ok:
        for x in range(a, e):
            kind[x - LO] = "code"
    conflicts = []
    for rule, name in ((L.ascii_runs, "ascii"), (L.ident_runs, "ident"),
                       (monotone_maps, "bytemap"),
                       (L.ram_tables_ex, "ramtab"), (L.bit_tables, "bittab"),
                       (L.ptr_tables, "ptrtab"), (L.fill_runs, "fill")):
        for a, e in rule(d, LO, HI):
            for x in range(a, e):
                if kind[x - LO] == "code":
                    conflicts.append(x)
                kind[x - LO] = name
    segs, p = [], 0
    while p < HI - LO:
        q = p
        while q < HI - LO and kind[q] == kind[p]:
            q += 1
        segs.append((kind[p], LO + p, q - p))
        p = q
    return segs, conflicts, pend, ok, seen


def null_ptr():
    """Do the content rules fire inside PROVEN INSTRUCTION TEXT?  They must not.

    Same corpus as prom_b_f65000_layout.py --null, but the PTRTAB window is the
    widened one this module needs.  Quote it with a revision: the corpus is
    derived from the current .s and grows every time a round converts code."""
    d = L.rom()
    runs = L.proven_code_runs()
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: %d runs, %d bytes of proven prom_b instruction text "
          "(WORKING TREE)." % (len(runs), tot))
    bad = 0
    for name, f in (("ptrtab >= 3, window 0x%06X-0x%06X" % (PTR_LO, PTR_HI - 1),
                     lambda a, b: L.ptr_tables(d, a, b)),
                    ("ramtab >= 4", lambda a, b: L.ram_tables_ex(d, a, b)),
                    ("bittab >= 8", lambda a, b: L.bit_tables(d, a, b)),
                    ("ident  >= 12", lambda a, b: L.ident_runs(d, a, b)),
                    ("ascii  >= 20", lambda a, b: L.ascii_runs(d, a, b)),
                    ("bytemap >= %d bytes / %d values" % (MONO_MIN, MONO_VALS),
                     lambda a, b: monotone_maps(d, a, b))):
        hits = []
        for s, e in runs:
            hits += f(s, e)
        bad += len(hits)
        print("  %-44s false positives: %2d   %s"
              % (name, len(hits),
                 " ".join("0x%06X(%d)" % (a, b - a) for a, b in hits[:4])))
    return bad


def dl_spans():
    """The proven display-list spans: 39,329 bytes of DATA whose framing is
    self-checking.  Each is a run of records; walk() returns the record starts
    and returns None if walking the length bytes does not land exactly on the
    call site's end address."""
    a, b = DL.load()
    out = {}
    for s, e in DL.spans(DL.call_sites(a, b)):
        r = DL.walk(b, s, e)
        if r is not None:
            out[(s, e)] = [x[0] if isinstance(x, tuple) else x for x in r]
    return out


def null_accept():
    """Does accept()'s rule promote proven DATA to code?  THE ROUND-4 RULE DOES.

    Each proven display-list span is chopped into record-ALIGNED chunks of at
    least N bytes -- record-aligned because a chunk that starts mid-record would
    be a strawman -- and each chunk is offered to the rule.  Every acceptance is
    a false positive: the bytes are records the interpreter executes as data."""
    d = L.rom()
    spans = dl_spans()
    print("NULL corpus: %d proven display-list spans, %d bytes of DATA "
          "(notes/FINDINGS-ui-display-list.md)."
          % (len(spans), sum(e - s for s, e in spans)))
    print("  chunk >=   round-4 rule            + the tail rule (this round)")
    worst = 0
    for target in (16, 24, 32, 48, 64):
        tot = fp1 = fp2 = 0
        for (s, e), starts in spans.items():
            i = 0
            while i < len(starts):
                j = i
                while j < len(starts) and (starts[j] - starts[i]) < target:
                    j += 1
                cs, ce = starts[i], (starts[j] if j < len(starts) else e)
                i = j
                if ce - cs < 4:
                    continue
                tot += 1
                good, _ = L.selfconsistent(d, cs, ce, set())
                if good:
                    fp1 += 1
                    if L.ends_in_flow_end(cs, ce):
                        fp2 += 1
        if target == 16:
            worst = fp2
        print("  %8d   %5d of %5d (%4.1f%%)      %5d of %5d (%4.1f%%)"
              % (target, fp1, tot, 100.0 * fp1 / tot, fp2, tot,
                 100.0 * fp2 / tot))
    print("  A rule whose false-positive rate on proven data is 13.9% is not a")
    print("  boundary argument.  With the tail rule it is 0.1% at 16 bytes and")
    print("  ZERO at 32 and above, which is what this module's accept() uses.")
    return worst


def proven_dispatch_tables():
    """Every dispatch table this tree has already PROVEN, as word lists.

    Two sources, both self-checking rather than asserted:
      * the 31 tables of notes/gen_prom_b_f65000_module.py's LAYOUT, whose
        entries are addresses the firmware transfers to (63.7% of them are one
        `ret` stub, which is what a handler table with holes looks like);
      * the two display-list handler tables at 0xF31D21 (36 entries, the exact
        bound the interpreter checks) and 0xF31DB1 (16), read from the ROM."""
    import gen_prom_b_f65000_module as G
    d = L.rom()
    out = []
    for kind, s, n in G.LAYOUT:
        if kind == "ptrtab":
            out.append(("f65000 0x%06X" % s,
                        [L.w32(d, s + 4 * i) for i in range(n // 4)]))
    for base, n in ((0xF31D21, 36), (0xF31DB1, 16)):
        out.append(("DL handler table 0x%06X" % base,
                    [L.w32(d, base + 4 * i) for i in range(n)]))
    return out


def null_stride():
    """Does the STRIDED rule ever fire on a PROVEN dispatch table?  It must not."""
    tabs = proven_dispatch_tables()
    print("NULL corpus: %d proven dispatch tables, %d entries."
          % (len(tabs), sum(len(v) for _, v in tabs)))
    bad = 0
    for name, vals in tabs:
        if strided(vals):
            bad += 1
            print("  FALSE POSITIVE %s: %s ..."
                  % (name, " ".join("0x%06X" % x for x in vals[:4])))
    print("  whole proven dispatch tables the rule calls STRIDED: %d" % bad)
    win = []
    for name, vals in tabs:
        for i in range(0, len(vals) - STRIDE_MIN + 1):
            if len(set(vals[i + 1 + k] - vals[i + k] for k in range(STRIDE_MIN - 1))) == 1 \
                    and vals[i + 1] - vals[i] > 0:
                win.append((name, i, vals[i + 1] - vals[i]))
                break
    print("  \u26a0 and WHY the rule is whole-table and has a minimum stride of "
          "%d: %d proven table(s) contain a constant-stride WINDOW of %d entries "
          "-- %s.  A run of one-byte handlers steps by 1; an array of records "
          "does not." % (STRIDE_BYTES, len(win), STRIDE_MIN,
                         "; ".join("%s at [%d], stride %d" % w for w in win)))
    print("  and the table this rule exists for, 0xF0EE6C: %s"
          % ("STRIDED" if strided([L.w32(L.rom(), 0xF0EE6C + 4 * i)
                                   for i in range(29)]) else "not strided"))
    return bad


def provenance():
    """WHY is each code segment's first byte code?  Graded, strongest first.

    A recursive descent is only as good as its seeds, and two of the four seed
    sources are addresses the firmware STORES rather than transfers to.  This
    grades every code segment by the strongest reason its entry point has:

      PROVEN     an instruction ALREADY IN THE .s calls or jumps to it
      THUNK      a `jp` slot of the 0xF40000 routine directory names it
      CALL       an opcode-anchored `call`/`jp addr24` in prom_a or prom_b
      BRANCH     a branch decoded inside this module targets it
      FALL       the previous code segment runs into it (no data between)
      TABLE      only an entry of a table the firmware TRANSFERS to points at it
      IMMED      only a 32-bit immediate an instruction LOADS points at it
                 (this module does not use that source at all -- see
                 descend_no_immediates(); the grade can only appear if it is
                 switched back on)
      ACCEPT     nothing points at it; it decodes cleanly and ends in a flow end

    IMMED, TABLE and ACCEPT are the weak grades and every one of them is listed
    so it can be looked at by hand.  This is the only tool in this lane that
    reports WHY, rather than THAT, a byte is code."""
    import re
    d = L.rom()
    segs, conflicts, pend, ok, seen = build()
    block = L.barriers(d, LO, HI)
    proven = proven_call_sites()
    thunk = set(t for _, t in MT.thunk_entries(LO, HI))
    far = L.far_calls(d, LO, HI)
    tab = table_entry_seeds(d, LO, HI)
    branch, immed = set(), set()
    for a in sorted(seen):
        dec = MT.decode_at(a)
        if dec is None or a + dec[0] - 1 not in seen:
            continue
        n, txt = dec
        for t in TC.branch_targets(txt):
            branch.add(t)
        for m in re.findall(r"0x00([0-9a-f]{6})", txt):
            immed.add(int(m, 16))
    accepted = set(s for s, _ in ok)
    grades, rows = {}, []
    prev_end, prev_kind = None, None
    for kind, s, n in segs:
        if kind != "code":
            prev_kind, prev_end = kind, s + n
            continue
        g = ("PROVEN" if s in proven else
             "THUNK" if s in thunk else "CALL" if s in far else
             "BRANCH" if s in branch else
             "FALL" if prev_kind == "code" and prev_end == s else
             "IMMED" if s in immed else "TABLE" if s in tab else
             "ACCEPT" if s in accepted else "NONE")
        grades[g] = grades.get(g, 0) + 1
        rows.append((g, s, n))
        prev_kind, prev_end = kind, s + n
    order = ["PROVEN", "THUNK", "CALL", "BRANCH", "FALL", "TABLE", "ACCEPT",
             "IMMED", "NONE"]
    print("code segments by the STRONGEST reason their entry point is code:")
    for g in order:
        if g in grades:
            b = sum(n for gg, _, n in rows if gg == g)
            print("  %-7s %3d segments  %6d bytes" % (g, grades[g], b))
    print("\nthe weak grades, every one (look at these by hand):")
    for g in ("TABLE", "ACCEPT", "IMMED", "NONE"):
        for gg, s, n in rows:
            if gg == g:
                print("  %-7s 0x%06X  %5d bytes" % (g, s, n))
    return sum(1 for g, _, _ in rows if g == "NONE")


def main():
    if "--all" in sys.argv:                 # one process, every report
        segs, conflicts, pend, ok, seen = build()
        print("LAYOUT = [")
        for k, a, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, a, n))
        print("]")
        tot = {}
        for k, a, n in segs:
            tot[k] = tot.get(k, 0) + n
        print("# ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("# segments %d  accepted %d  conflicts %d  pending %d"
              % (len(segs), len(ok), len(conflicts), len(pend)))
        print("# TABLES")
        d = L.rom()
        for a, e in L.ptr_tables(d, LO, HI):
            print("#   0x%06X %4d entries  %s"
                  % (a, (e - a) // 4, table_kind(d, a, e)))
        print("# PROVENANCE")
        provenance()
        return 0
    if "--provenance" in sys.argv:
        return 1 if provenance() else 0
    if "--null-stride" in sys.argv:
        return 1 if null_stride() else 0
    if "--null-ptr" in sys.argv:
        return 1 if null_ptr() else 0
    if "--null-accept" in sys.argv:
        n = null_accept()
        return 1 if n > 1 else 0
    segs, conflicts, pend, ok, seen = build()
    d = L.rom()
    if "--conflicts" in sys.argv:
        print("descent bytes reclaimed by a barrier rule: %d  (MUST be 0)"
              % len(conflicts))
        for a in conflicts[:80]:
            print("  0x%06X" % a)
        return 1 if conflicts else 0
    if "--residue" in sys.argv:
        print("runs that are neither code, table nor string: %d (%d bytes)"
              % (len(pend), sum(e - s for s, e in pend)))
        for s, e in pend:
            raw = d[s - L.B_BASE:e - L.B_BASE]
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "."
                                 for c in raw[i:i + 16])))
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
          % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
    print("  segments %d   accepted runs %d   barrier conflicts %d   pending %d"
          % (len(segs), len(ok), len(conflicts), len(pend)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
