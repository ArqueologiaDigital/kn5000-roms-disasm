#!/usr/bin/env python3
"""prom_c ROUND 10 (wave-7) -- THE 68-BYTE VOICE RECORD, FIELD BY FIELD, and a
   measured refusal of the round's own brief.

QUESTION IT ANSWERS
    "prom_c's naming mechanisms are spent.  Rounds 7, 8 and 9 swept twins,
     dispatch arms, readers, ports and the whole framed column, and left 411
     sub_XXXXXX of which 359 sit in buckets S4 and S6 -- routines whose callers
     are themselves sub_XXXXXX, so no name can propagate in.  Is there an OBJECT,
     rather than a routine, that gives a block of them meaning at once?"

    Yes, and it is the object at the centre of the voice engine: the 68-byte
    record at RAM 0x003BCF.  Its GEOMETRY has been in the tree since wave 5
    (notes/FINDINGS-prom_c-voice-module.md sec 4: 64 records, stride 0x44, index
    == hardware channel).  Its CONTENTS have never been mapped.  --record68 maps
    them, and the map CLOSES: 33 fields tile all 68 bytes with no gap and no
    overlap, no offset carrying two different determinate widths.

★ WHY THE TILING IS THE RESULT AND NOT AN ORNAMENT
    The map is produced by a taint tracker, and a taint tracker is exactly the
    kind of instrument this project has been burned by: plausible, mechanical,
    and impossible to check by eye.  The tiling is the check.  A tracker that
    invents offsets produces OVERLAPS -- a 4-byte field starting inside a 2-byte
    one -- and a tracker that mis-reads widths produces GAPS.  33 fields landing
    edge to edge across 68 bytes, with every width agreeing across up to 67
    access sites, and the record's own constructor independently writing 12 of
    them at those same widths, is not something a wrong tracker produces.

⚠ WHAT THIS ROUND DID **NOT** DO, said first because the temptation was real.
    A field MAP is not a set of field NAMES.  Exactly one of the 33 fields has a
    decoded meaning and it is not this round's: +0x23 holds 0x1523 + 0x012C*part,
    the address of the part record, which round 9's selftest already asserts.
    The other 32 have an offset, a width, a direction and a site list, and no
    name.  Reading a musical role out of a displacement is how this tree acquired
    five prom_a labels built on a morpheme that occurs ZERO times in all four ROM
    images.  The offsets are the names.

WHAT THE INSTRUMENT SAYS, and what it cannot see
    prom_c content 833 -> 835, sub_XXXXXX 411 -> 409, LOWER 47.9%% -> 48.0%%,
    UPPER 76.4%% -> 76.5%% (notes/wave7_documentation_metrics.py).  framed ->
    content promotions: ZERO, and --refused10 says why rather than leaving it a
    miss.
    ⚠ THE `headers` AND `evidence` COLUMNS DID NOT MOVE, and that is correct.
    77 comment blocks gained genuinely new prose this round -- 71 derived
    `Voice record:` lines, 5 rewritten routine tails and one 47-line block
    comment -- but every block that gained it ALREADY had three comment lines and
    an Evidence line, and the instrument counts the PRESENCE of a header, not
    what it says.  Stated because the mirror of this (counting deleted blank
    lines as new headers) is a mistake this tree has already published.

WHAT THE ROUND SHIPPED
    * the field map, into prom_c/wsa1_prom_c.s as a generated block comment above
      the record's constructor (--emit68 prints it; --selftest asserts the source
      contains it verbatim, so comment and tracker cannot drift);
    * 2 renames with headers and Evidence lines, out of a 6-routine family this
      script's shape predicate selects mechanically (--restage);
    * 3 REFUSALS in that same family, with the arithmetic that forces them;
    * a derived `Voice record:` line in the header of every routine the tracker
      proves holds a record pointer -- the depth the brief asked for, on routines
      that already had a name;
    * a measured refusal of the brief's item 4 (--depth10).

★ THE BRIEF'S ITEM 4 IS FALSE ABOUT prom_c, AND --depth10 SHOWS WHY
    The brief says prom_c "has 809 content names but only 1,096 headers ... most
    named routines are a name and nothing else".  That is a fair reading of
    notes/wave7_documentation_metrics.py and it is wrong about the tree, for the
    reason round 8's --grader found and nobody acted on: 168 of prom_c's
    "content" labels are `<parent>__<word>` INTERIOR BRANCH TARGETS
    (EEPROM_WriteWord__cmd_bit, MAIN__bit3, RESET__clear_dram).  The instrument
    excludes `<parent>__<4-6 hex>` from the percentages on the stated ground that
    a jump destination inside a routine is not an object awaiting a name; a
    target spelled with a WORD is the same thing and is graded CONTENT.
    Take those out and prom_c has 667 real content objects (665 before this
    round's two renames), 533 of them with a header, and every single one of the
    134 without a header is either a row of the PresetBank table (127) or an
    interrupt trampoline (7) -- both classes sitting under a block comment that
    says more than a per-object header could.
    prom_c has NO routine that is a name and nothing else.  Writing those 134
    headers would move the instrument by 134 and the tree by nothing, and this
    tree has already published a "+35 headers" gain that was 35 deleted blank
    lines.  So they are refused, and the refusal is the deliverable.

⚠ LANE COLLISION, RECORDED BECAUSE IT COST WORK
    This round's brief assigned notes/prom_c_inventory_round8.py as this lane's
    script.  A SECOND wave-7 lane was appending its own ROUND 10 section (the
    prom_a unit-1 ATA back end) to that same file at the same time, and the two
    writes interleaved.  The shared file was restored to the other lane's state
    and this round's work moved here, to a uniquely-named file, which is what
    notes/WAVE7-BRIEFING.md's lane discipline says to do.  Nothing in
    prom_c_inventory_round8.py is this round's.

RUN
    python3 notes/prom_c_record68_round10.py             # every section
    python3 notes/prom_c_record68_round10.py --record68  # 1: the field map
    python3 notes/prom_c_record68_round10.py --restage   # 2: the walker family
    python3 notes/prom_c_record68_round10.py --depth10   # 3: the depth audit
    python3 notes/prom_c_record68_round10.py --claims10  # 4: every citation
    python3 notes/prom_c_record68_round10.py --refused10 # 5: the refusals
    python3 notes/prom_c_record68_round10.py --xtwin     # 6: the cross-image twin sweep
    python3 notes/prom_c_record68_round10.py --emit68    # the block comment
    python3 notes/prom_c_record68_round10.py --emitdepth # the per-routine lines
    python3 notes/prom_c_record68_round10.py --apply     # make every source edit
    python3 notes/prom_c_record68_round10.py --selftest  # all of it, exit 1 on a failure
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
BASE = 0xF80000

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDRC = re.compile(r';\s*([0-9A-F]{6})\s\s+(.*)$')
INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                    r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                    r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')

CHECKS = [0]
FAILS = []
_C = {}


def check(cond, msg):
    CHECKS[0] += 1
    print("  %s  %s" % ("ok  " if cond else "FAIL", msg))
    if not cond:
        FAILS.append(msg)
    return cond


def load():
    if not _C:
        src = open(SRC).read().split("\n")
        dis = {}
        for ln in src:
            m = ADDRC.search(ln)
            if m:
                dis[int(m.group(1), 16)] = m.group(2).strip()
        _C.update(src=src, dis=dis)
    return _C


def mnemonic(a):
    """The disassembly text at `a`, with any leading raw-byte run stripped."""
    return re.sub(r'^(?:[0-9a-f]{2}\s+)+', '', (load()["dis"].get(a) or "")).strip()


def source_labels():
    return set(m.group(1) for m in (LABEL.match(l) for l in load()["src"]) if m)


def header_block(name):
    src = load()["src"]
    i = next((k for k, l in enumerate(src) if l.startswith("; %s -- 0x" % name)), None)
    if i is None:
        return None
    j = i
    while j < len(src) and not src[j].startswith("%s:" % name):
        j += 1
    return "\n".join(src[i:j])


# ============================================== 1. THE 68-BYTE VOICE RECORD
RECORD_BASE = 0x3BCF        # RAM; `ld DE,0x3bcf` at 0xFADCCA and 20 other sites
RECORD_STRIDE = 0x44        # `ld C,0x44 / mul BC,H` at 0xFADCD9 / 0xFADCDB
RECORD_COUNT = 0x40         # `cp H,0x40` at 0xFADCD4, also the list terminator
EGREC_BASE = 0x4CCF         # the 27-byte envelope record array (round 6, sec 6)
CTOR = "VoiceRecords_InitFromAlloc"

_R32 = {"XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP"}
_R16 = {"WA", "BC", "DE", "HL", "IX", "IY", "IZ", "SP"}
_PAIR = {"WA": ("W", "A"), "BC": ("B", "C"), "DE": ("D", "E"), "HL": ("H", "L")}
_SZ = dict([(r, 4) for r in _R32] + [(r, 2) for r in _R16]
           + [(r, 1) for r in ("W", "A", "B", "C", "D", "E", "H", "L")])
_MEM = re.compile(r'\((X[A-Z]{2})(?:\+0x([0-9A-Fa-f]+))?\)')
_IDXMEM = re.compile(r'\((X[A-Z]{2})\+0x([0-9A-Fa-f]{4})\)')


def _fam(r):
    """The 32-bit family a register spelling belongs to.  Taint is tracked per
    FAMILY: a write to HL clobbers XHL's low half, so it must kill XHL too."""
    r = r.upper()
    if r in _R32:
        return r
    if r in _R16:
        return "X" + r
    for k, (hi, lo) in _PAIR.items():
        if r in (hi, lo):
            return "X" + k
    return None


def _dest(t):
    """The registers this instruction WRITES, read off the MAME text.  `['*']`
    means "unknown effect" -- every extpfx form and anything unrecognised -- and
    kills the whole taint state rather than being assumed harmless."""
    p = t.split(None, 1)
    op = p[0]
    args = [a.strip() for a in p[1].split(",")] if len(p) > 1 else []
    if op in ("push", "pushw", "cp", "cps", "cpw", "cpb", "cpib", "cpiw", "bit",
              "ret", "reti", "retd", "jp", "jr", "jrl", "call", "calr", "nop",
              "ei", "di", "swi", "halt", "rcf", "scf", "ccf", "zcf", "link",
              "unlk", "ldf", "tset"):
        return []
    if op in ("pop", "popw"):
        return args[:1]
    if op in ("inc", "dec") and len(args) == 2:
        return args[1:2]
    if op in ("res", "set", "chg", "sll", "srl", "sla", "sra", "rlc", "rrc",
              "rl", "rr") and len(args) == 2:
        return args[1:2]
    if op in ("ld", "ldw", "ldb", "ldl", "lda", "lda_24", "add", "sub", "adc",
              "sbc", "and", "or", "xor", "mul", "muls", "mul8rr", "div", "divs",
              "extz", "exts", "neg", "cpl", "daa", "paa", "minc1", "minc2",
              "minc4", "mdec1", "mdec2", "mdec4", "ldar",
              "stw_da", "stb_da", "stl_da", "stib_da", "stiw_da"):
        return args[:1]
    return ["*"]


def _width_dir(t):
    """(width in bytes, direction) for the memory operand of `t`.  The width is
    read off the OTHER operand's register, the only place the size is stated;
    None when no operand names a register (an immediate store)."""
    p = t.split(None, 1)
    op = p[0]
    args = [a.strip() for a in p[1].split(",")] if len(p) > 1 else []
    d = "w" if (args and args[0].startswith("(")) else "r"
    if op in ("cp", "cps", "cpw", "cpb", "bit", "push", "pushw"):
        d = "r"
    if op in ("inc", "dec", "res", "set", "chg", "and", "or", "xor", "add",
              "sub", "sll", "srl"):
        d = "rw"
    w = None
    for a in args:
        if a in _SZ:
            w = _SZ[a]
    return (w, d)


def routines():
    """Every top-level object in prom_c with its instruction stream, in address
    order.  A `<parent>__<x>` interior label does NOT start a new object: a
    routine's extent is its ADDRESS EXTENT, which is exactly the distinction a
    wave-7 reviewer had to correct in a round-3 header that counted 17
    instructions for a 30-instruction routine."""
    if "rtn" in _C:
        return _C["rtn"]
    cur, out = None, collections.OrderedDict()
    for ln in load()["src"]:
        m = LABEL.match(ln)
        if m:
            if "__" not in m.group(1):
                cur = m.group(1)
                out.setdefault(cur, [])
            continue
        if cur is None:
            continue
        m = ADDRC.search(ln)
        if m:
            out[cur].append((int(m.group(1), 16), m.group(2).strip()))
    _C["rtn"] = out
    return out


def _track(ins, argptr=False):
    """THE TAINT RULE, in full, because a field map is only as good as it.

    A 32-bit register is a RECORD POINTER when the code has just built it out of
    the array base and the stride:
        `ld <r8>,0x44` then `mul <rr>,<r8>` within two instructions -> rr = 0x44*index
        `ld <rr>,0x3bcf`                                            -> rr = base
        `add <rr>,<rr'>` with one of each, or `add <rr>,0x3bcf`      -> rr = &record
        `extz X<rr>`                                                -> X<rr> usable
    Taint propagates through `ld <rr>,<rr'>` and dies the instant anything writes
    the register's family.  Every displacement then seen on a tainted pointer,
    below the 0x44 stride, is a field of the record.

    With `argptr`, the routine's first argument slot (XIZ+0x08) is a record
    pointer too.  That is granted ONLY to a routine EVERY call site of which
    pushes a proven record pointer as the last push before the call -- the
    TLCS-900 C convention puts the last push in (XIZ+0x08) -- and it is
    recomputed to a fixed point, so a routine qualifying only through another
    that qualifies is included.

    ⚠ THE RULE UNDER-REPORTS AND CANNOT SAY BY HOW MUCH.  It is blind to a
    pointer that arrives in a register it cannot prove, is stashed in a stack
    slot, or is built by arithmetic it does not model: `ld (XHL+0x23),BC` at
    0xFB0CD6 really does write +0x23 and this tracker does not see it.  A
    field's direction column is what the tracker SAW, never what the image does.
    """
    idx, base, p16, p32 = set(), set(), set(), set()
    hits = collections.defaultdict(list)
    calls, lastpush, pend = [], None, -99
    for k, (a, t) in enumerate(ins):
        low = t.lower()
        for m in _MEM.finditer(t):
            if m.group(1) in p32:
                off = int(m.group(2), 16) if m.group(2) else 0
                if off < RECORD_STRIDE:
                    hits[off].append((a, t, _width_dir(t)))
        pi, pb, p1, p3 = set(idx), set(base), set(p16), set(p32)
        mp = re.match(r'push (x?[a-z]{2})$', low)
        if mp:
            f = _fam(mp.group(1))
            lastpush = (f, f in p16 or f in p32)
        elif low.startswith("push"):
            lastpush = (None, False)
        mc = re.match(r'(?:call|calr)\s+(?:[A-Z]+,)?0x([0-9a-f]+)$', low)
        if mc:
            calls.append((int(mc.group(1), 16), bool(lastpush and lastpush[1])))
            lastpush = None
        d = _dest(t)
        if "*" in d:
            idx.clear(); base.clear(); p16.clear(); p32.clear()
        else:
            for x in d:
                f = _fam(x.strip("()"))
                if f:
                    idx.discard(f); base.discard(f); p16.discard(f); p32.discard(f)
        if re.match(r'ld [a-z]+,0x44$', low):
            pend = k
        m = re.match(r'mul (x?[a-z]{2}),', low)
        if m and k - pend <= 2 and _fam(m.group(1)):
            idx.add(_fam(m.group(1)))
        m = re.match(r'ld (x?[a-z]{2}),0x3bcf$', low)
        if m and _fam(m.group(1)):
            base.add(_fam(m.group(1)))
        m = re.match(r'ld (x?[a-z]{2}),(x?[a-z]{2})$', low)
        if m:
            df, sf = _fam(m.group(1)), _fam(m.group(2))
            if df and sf:
                if sf in pi:
                    idx.add(df)
                if sf in pb:
                    base.add(df)
                if sf in p1:
                    p16.add(df)
                if sf in p3:
                    p32.add(df); p16.add(df)
        m = re.match(r'add (x?[a-z]{2}),(x?[a-z]{2})$', low)
        if m:
            df, sf = _fam(m.group(1)), _fam(m.group(2))
            if df and sf and ((df in pi and sf in pb) or (df in pb and sf in pi)):
                p16.add(df)
        m = re.match(r'add (x?[a-z]{2}),0x0*3bcf$', low)
        if m and _fam(m.group(1)) in pi:
            p16.add(_fam(m.group(1)))
        if argptr:
            m = re.match(r'ld (x?[a-z]{2}),\(xiz\+0x08\)$', low)
            if m and _fam(m.group(1)):
                p16.add(_fam(m.group(1)))
                if m.group(1).startswith("x"):
                    p32.add(_fam(m.group(1)))
        m = re.match(r'extz (x[a-z]{2})$', low)
        if m and _fam(m.group(1)) in p1:
            p32.add(_fam(m.group(1))); p16.add(_fam(m.group(1)))
        for m in _IDXMEM.finditer(t):
            if m.group(1) in pi:
                v = int(m.group(2), 16)
                if RECORD_BASE <= v < RECORD_BASE + RECORD_STRIDE:
                    hits[v - RECORD_BASE].append((a, t, _width_dir(t)))
    return hits, calls


def record68():
    """({routine: {offset: [(addr, text, (width, dir))]}}, argument-slot set)."""
    if "map" in _C:
        return _C["map"]
    R = routines()
    first = dict((ins[0][0], n) for n, ins in R.items() if ins)
    argset, per = set(), {}
    for _ in range(6):
        sites = collections.defaultdict(list)
        new = {}
        for n, ins in R.items():
            h, calls = _track(ins, argptr=(n in argset))
            if h:
                new[n] = h
            for tgt, ok in calls:
                if tgt in first:
                    sites[first[tgt]].append(ok)
        cand = set(k for k, v in sites.items() if v and all(v))
        done = cand == argset and new.keys() == per.keys()
        argset, per = cand, new
        if done:
            break
    _C["map"] = (per, argset)
    return _C["map"]


def record68_fields():
    """([(offset, width, sites, routines, dirs)], width conflicts, by-offset index)."""
    per, _a = record68()
    by = collections.defaultdict(list)
    for n, h in per.items():
        for o, v in h.items():
            for a, t, wd in v:
                by[o].append((n, a, t, wd))
    conflict, rows = [], []
    for o in sorted(by):
        ws = set(x[3][0] for x in by[o] if x[3][0])
        if len(ws) > 1:
            conflict.append((o, sorted(ws)))
        ds = collections.Counter(x[3][1] for x in by[o])
        rows.append((o, (max(ws) if ws else None), len(by[o]),
                     len(set(x[0] for x in by[o])), dict(ds)))
    return rows, conflict, by


def record68_tiling():
    rows, _c, _by = record68_fields()
    pos, gaps = 0, []
    for o, w, _s, _r, _d in rows:
        if o != pos:
            gaps.append((pos, o))
        pos = o + (w or 1)
    return (not gaps and pos == RECORD_STRIDE), gaps


def show_record68():
    per, argset = record68()
    rows, conflict, by = record68_fields()
    ok, gaps = record68_tiling()
    print("=== 1. THE 68-BYTE VOICE RECORD AT RAM 0x003BCF, FIELD BY FIELD ===\n")
    print("  THE ARRAY, from instruction operands and not from prose:")
    print("      base    0x%04X   `%s` at 0xFADCCA" % (RECORD_BASE, mnemonic(0xFADCCA)))
    print("      stride  0x%02X     `%s` / `%s` at 0xFADCD9 / 0xFADCDB"
          % (RECORD_STRIDE, mnemonic(0xFADCD9), mnemonic(0xFADCDB)))
    print("      count   0x%02X     `%s` at 0xFADCD4, also the walk's terminator"
          % (RECORD_COUNT, mnemonic(0xFADCD4)))
    print("      0x%04X + %d * 0x%02X = 0x%04X, EXACTLY the base of the 27-byte"
          % (RECORD_BASE, RECORD_COUNT, RECORD_STRIDE,
             RECORD_BASE + RECORD_COUNT * RECORD_STRIDE))
    print("      envelope record array round 6 established.  The arrays abut; the")
    print("      voice array has no slack at its top.\n")
    print("  THE MAP.  %d routines hold a pointer the rule PROVES is base +" % len(per))
    print("  0x44*index (%d of them only through their argument slot).  Every"
          % len(argset & set(per)))
    print("  displacement seen on one, below the stride, is a field:\n")
    print("      field   width  dir      sites  routines  ctor")
    ctor = set(o for o in by if any(x[0] == CTOR for x in by[o]))
    for o, w, ns, nr, ds in rows:
        print("      +0x%02X   %-6s %-8s %4d  %6d    %s"
              % (o, ("%d B" % w) if w else "?", "/".join(sorted(ds)), ns, nr,
                 "yes" if o in ctor else ""))
    print("\n  ★ THE %d FIELDS TILE ALL %d BYTES -- no gap, no overlap: %s"
          % (len(rows), RECORD_STRIDE, ok))
    if gaps:
        print("      gaps: %s" % (gaps,))
    print("      widths sum to %d = 0x%02X = the stride itself."
          % (sum(w for _o, w, _s, _r, _d in rows), RECORD_STRIDE))
    print("      %d offsets carry two different determinate widths." % len(conflict))
    print("      That is the map's OWN check.  A tracker inventing offsets produces")
    print("      overlaps and one mis-reading widths produces gaps; %d fields landing"
          % len(rows))
    print("      edge to edge, every width agreeing across up to %d sites, is not"
          % max(r[2] for r in rows))
    print("      something a wrong tracker produces.")
    print("\n  THE CONSTRUCTOR AGREES, independently.  %s writes" % CTOR)
    print("      %d of the %d fields -- %s --"
          % (len(ctor), len(rows), ", ".join("+0x%02X" % o for o in sorted(ctor))))
    print("      at the widths the map gives them.  A second reading of the same")
    print("      boundaries, by a routine that never walks the array at all.")
    print("\n  THE ONE FIELD WITH A MEANING, and it is not this round's:")
    print("      +0x23  the 16-bit ADDRESS of this voice's part record.")
    print("             `%s` (0xFB0C8A) then `%s` (0xFB0CD6):"
          % (mnemonic(0xFB0C8A), mnemonic(0xFB0CD6)))
    print("             0x1523 + 0x012C*part, asserted by round 9's own selftest.")
    print("      The other 32 fields have an offset, a width, a direction and a site")
    print("      list, and NO name.  --refused10 says why that is the answer.")


# ================================ 2. THE VOICE-LIST WALKER FAMILY
FAMILY_SHAPE = ["ld DE,0x3bcf", "ld XIX,(XIZ+0x08)", "inc 5,XIX", "ld H,(XIX)",
                "cp H,0x40", "ld C,0x44", "and BC,0x003c"]

RESTAGE_NAMED = [
    ("sub_FADFAD", "Voice_RestageRegs0100_0140_ForList", 0xFAE004, "calr 0xfacf3c",
     "Dev10C_SetChanReg_0100_0140",
     ["stages through Voice_StagePair_Reg0100_0140_AB (call at 0xFADFED) or",
      "_CD (0xFADFF4) and sends through Dev10C_SetChanReg_0100_0140 (0xFAE004).",
      "No other member of the family touches registers 0x0100/0x0140."]),
    ("sub_FADDC8", "Voice_RestageReg0080_ForList", 0xFADE1F, "call 0xfb7038",
     "Dev10C_SetChanReg_0080_ClrBit15",
     ["stages through sub_FAB79D (call at 0xFADE08) or sub_FAB7E0 (0xFADE0F) and",
      "sends through Dev10C_SetChanReg_0080_ClrBit15 (0xFADE1F).  No other member",
      "of the family touches register 0x0080."]),
]

RESTAGE_REFUSED = [
    ("sub_FADE2F", 0xFADE9B, "calr 0xfacea2", "Dev10C_SetChanReg_0840_0880"),
    ("sub_FAE013", 0xFAE092, "calr 0xfacf78", "Dev10C_SetChanReg_0840_0880_dup"),
    ("sub_FAE0A1", 0xFAE0F8, "calr 0xfacf78", "Dev10C_SetChanReg_0840_0880_dup"),
]


def restage_family():
    """Six routines share ONE shape, and the shape is a predicate over seven
    instruction texts, not an impression.  Each opens `ld DE,0x3bcf`, takes a
    voice-ID list in its first argument, skips five header bytes, walks it until
    a byte >= 0x40, multiplies by the 0x44 stride, switches on
    record[+0x01] & 0x3C, stages, and sends through ONE Dev10C_SetChanReg_*
    accessor.  They are "re-send register group X for every voice in this list"."""
    fam = []
    for n, ins in routines().items():
        txt = [t for _a, t in ins]
        if all(any(t.startswith(x) for t in txt) for x in FAMILY_SHAPE):
            fam.append(n)
    return fam


def show_restage():
    fam = restage_family()
    print("=== 2. THE VOICE-LIST WALKER FAMILY -- two named, three refused ===\n")
    print("  The seven-text predicate selects exactly these %d of prom_c's %d"
          % (len(fam), len(routines())))
    print("  top-level objects:\n")
    for n in fam:
        print("      %s" % n)
    print("\n  NAMED, from the register group each one sends.  That is an")
    print("  instruction operand, and the accessor's own name was established in")
    print("  round 2, so nothing here is a new claim about the hardware:\n")
    for old, new, a, t, acc, why in RESTAGE_NAMED:
        print("      %-12s -> %s" % (old, new))
        print("           0x%06X `%s` = %s" % (a, t, acc))
        for l in why:
            print("           %s" % l)
        print()
    print("  ⚠ REFUSED, and the arithmetic is the whole reason:\n")
    print("      THREE of the six end in the SAME register pair --")
    for n, a, t, acc in RESTAGE_REFUSED:
        print("        %-12s 0x%06X `%s` = %s" % (n, a, t, acc))
    print("      -- and `Dev10C_SetChanReg_0840_0880` and `..._dup` write the same")
    print("      two registers; the tree's own name for the second says so.  So")
    print("      `Voice_RestageRegs0840_0880_ForList` would be true of all three and")
    print("      identify none.  The only things separating them are the CLASS MASK")
    print("      each accepts out of record[+0x01] & 0x3C -- 0xFADE53, 0xFAE037 and")
    print("      0xFAE0C4 all read the same field; sub_FAE013 accepts classes 4, 0x20")
    print("      and 0x10, the other two only 0x10 -- and a flag byte pushed to the")
    print("      CD stager, 1 in sub_FADE2F and 0 in sub_FAE0A1.  Neither the class")
    print("      values nor the flag has an established meaning in this tree.  A name")
    print("      would claim a role the other two deny, so all three keep their")
    print("      addresses and this paragraph is in the source above each of them.")


# ==================================================== 3. THE DEPTH AUDIT
IRQ_TRAMPOLINES = ["IRQ_SWI1_REBOOT", "IRQ_UNUSED", "IRQ_NMI", "IRQ_INT0",
                   "IRQ_INTT1", "IRQ_INTTC2", "IRQ_INTTC3"]


def grade_counts():
    out = collections.Counter()
    for l in load()["src"]:
        m = LABEL.match(l)
        if not m:
            continue
        n = m.group(1)
        if INTERNAL.match(n):
            out["internal"] += 1
        elif UNNAMED.match(n):
            out["sub"] += 1
        elif FRAMED.match(n):
            out["framed"] += 1
        else:
            out["content"] += 1
    return out


def depth10():
    """Every prom_c label that is CONTENT by the instrument's own rule and is not
    an interior `__` target: does it carry a header (>= 3 comment lines, at most
    one blank line between block and label -- the instrument's definition) and an
    Evidence line?"""
    rows, run, blanks, ev = [], 0, 0, False
    for i, ln in enumerate(load()["src"]):
        if ln.startswith(";"):
            run += 1
            if "Evidence:" in ln:
                ev = True
            blanks = 0
            continue
        if ln.strip() == "" and run:
            blanks += 1
            if blanks > 1:
                run, ev = 0, False
            continue
        m = LABEL.match(ln)
        if m:
            n = m.group(1)
            if "__" not in n and not UNNAMED.match(n) and not FRAMED.match(n):
                rows.append((n, i + 1, run, ev))
        run, blanks, ev = 0, 0, False
    return rows


def show_depth10():
    rows = depth10()
    g = grade_counts()
    hdr = [r for r in rows if r[2] >= 3]
    noh = [r for r in rows if r[2] < 3]
    preset = [r for r in noh if r[0].startswith("PresetBank")]
    irq = [r for r in noh if r[0] in IRQ_TRAMPOLINES]
    print("=== 3. prom_c's HEADER DEPTH -- the brief's premise, measured ===\n")
    print("  the instrument's prom_c `content` column                    %4d" % g["content"])
    print("  of which `<parent>__<word>` interior branch targets          %4d"
          % (g["content"] - len(rows)))
    print("  REAL content objects in prom_c                              %4d" % len(rows))
    print("     ...carrying a header (>= 3 comment lines)                %4d  (%.1f%%)"
          % (len(hdr), 100.0 * len(hdr) / len(rows)))
    print("     ...carrying an Evidence: line                            %4d  (%.1f%%)"
          % (len([r for r in rows if r[3]]),
             100.0 * len([r for r in rows if r[3]]) / len(rows)))
    print("     ...with NO header of their own                           %4d" % len(noh))
    print("          PresetBank_* rows of one table                      %4d" % len(preset))
    print("          interrupt trampolines                               %4d" % len(irq))
    print("          anything else                                       %4d"
          % (len(noh) - len(preset) - len(irq)))
    print("\n  ★ prom_c HAS NO ROUTINE THAT IS A NAME AND NOTHING ELSE.  The %d"
          % len(noh))
    print("  objects without a header are the two classes that should not have one:")
    print("     * the %d PresetBank_* records are ROWS OF ONE TABLE.  A block comment"
          % len(preset))
    print("       above PresetBank_Records gives the record layout, every chunk tag")
    print("       and its length, and each row already carries two comment lines with")
    print("       its index, its ROM address and its own 16-character name.  A third")
    print("       line per row would move the instrument by %d and say nothing."
          % len(preset))
    print("     * the %d interrupt trampolines are two- and three-instruction `jp`s"
          % len(irq))
    print("       under a block comment explaining the whole vector block, and five of")
    print("       the seven carry their OWN Evidence: line naming the vector slot that")
    print("       reaches them.  Same argument.")
    print("\n  ⚠ SO THIS IS A REFUSAL TO WRITE %d HEADERS, and it is the round's" % len(noh))
    print("  answer to the brief's item 4, not a failure to reach it.  A tree that has")
    print("  already published a `+35 headers` gain which was 35 DELETED BLANK LINES")
    print("  does not get to bank %d more by padding a generated table." % len(noh))


# ============================================ 4. EVERY CITATION THIS ROUND MAKES
CLAIMS10 = [
    (0xFADCCA, "ld DE,0x3bcf"), (0xFADCD4, "cp H,0x40"), (0xFADCD9, "ld C,0x44"),
    (0xFADCDB, "mul BC,H"), (0xFB0C8A, "ld BC,0x1523"), (0xFB0CD6, "ld (XHL+0x23),BC"),
    (0xFADFB4, "ld DE,0x3bcf"), (0xFADFED, "call 0xfa919b"), (0xFADFF4, "call 0xfa92a5"),
    (0xFAE004, "calr 0xfacf3c"), (0xFADDCF, "ld DE,0x3bcf"), (0xFADE08, "call 0xfab79d"),
    (0xFADE0F, "call 0xfab7e0"), (0xFADE1F, "call 0xfb7038"), (0xFADE53, "and BC,0x003c"),
    (0xFADE9B, "calr 0xfacea2"), (0xFAE037, "and BC,0x003c"), (0xFAE092, "calr 0xfacf78"),
    (0xFAE0C4, "and BC,0x003c"), (0xFB4036, "ld (XIX),A"), (0xFAE0F8, "calr 0xfacf78"),
    (0xFB401C, "ld (XIX+0x25),BC"),
]


def bad_claims10():
    return [(a, t, mnemonic(a)) for a, t in CLAIMS10
            if not mnemonic(a).lower().startswith(t.lower())]


def show_claims10():
    print("=== 4. EVERY ADDRESS ROUND 10 CITES, DECODED AT THE CITED ADDRESS ===\n")
    print("  Round 1 shipped ~31 citations one byte past the instruction and every")
    print("  one passed the byte gate.  This is the guard.\n")
    for a, t in CLAIMS10:
        got = mnemonic(a)
        print("      0x%06X  %-24s %s"
              % (a, t, "ok" if got.lower().startswith(t.lower()) else "MISMATCH: " + got))
    print("\n  %d citations, %d wrong." % (len(CLAIMS10), len(bad_claims10())))


REFUSALS10 = [
    ("32 of the voice record's 33 fields keep their offset", [
        "The map gives every field an offset, a width, a direction and up to 67",
        "access sites.  It gives exactly one of them a MEANING (+0x23, the part",
        "record's address -- and that was round 9's result, not this one).  Naming",
        "the other 32 would mean reading a musical role out of a displacement, the",
        "operation that produced five prom_a labels built on a morpheme occurring",
        "zero times in all four images.  The offsets ARE the names."]),
    ("the three 0x0840/0x0880 voice-list walkers", [
        "See --restage.  Three routines, one register pair, and the only",
        "discriminators are a class mask and a flag byte with no established",
        "meaning.  One name would fit all three and identify none."]),
    ("127 PresetBank rows and 7 interrupt trampolines get no header", [
        "See --depth10.  Both classes already sit under a block comment that says",
        "more than a per-object header could, and both would move the instrument",
        "without moving the tree."]),
    ("prom_c's framed column, again: ZERO promotions", [
        "Round 9 measured the promotable remainder at SEVEN labels and recorded a",
        "derived refusal for each; this round re-ran that partition and did not",
        "disturb it.  The three Dev10C_StageRegs_0800_0840_* still need the two",
        "staged words to have a meaning, Clamp_ToRange_LowByte_FBD88E's suffix",
        "records a byte diff that a promotion would deny, and unexplained_FCC5BE",
        "needs a split inside a generator this lane does not own.",
        "framed -> content this round = 0, by measurement and not by omission."]),
    ("no cross-image twin was borrowed, because there is none", [
        "--xtwin compares every prom_c sub_XXXXXX of >= 15 instructions against",
        "every content-named routine in prom_a, prom_b and prom_c by MNEMONIC",
        "SEQUENCE with operands dropped, so a routine relocated into another image",
        "still matches.  ONE hit in the whole tree, and it is inside prom_c.  The",
        "cross-image kernel-twin lever -- the tree's strongest borrowed-name",
        "mechanism -- is EMPTY for prom_c's remaining sub_XXXXXX."]),
    ("bucket S1's ten non-routines were NOT renamed", [
        "notes/prom_c_finish_round7.py --census puts ten objects in bucket S1: no",
        "literal reference of any spelling and reached by FALL-THROUGH, so they are",
        "not routines and the tree's `<parent>__<address>` spelling is correct for",
        "them.  Round 7 left the rename to a lane that is NOT also reporting the",
        "metric it would move, and this lane IS reporting it: the rename would take",
        "ten labels out of the sub_XXXXXX column and out of the denominator at the",
        "same time.  So it stays open, for the reason round 7 gave, and the census",
        "still partitions all 903 objects with no leftovers after this round."]),
]


def show_refused10():
    print("=== 5. ROUND 10's REFUSALS ===\n")
    for title, body in REFUSALS10:
        print("  %s" % title)
        for l in body:
            print("      %s" % l)
        print()


# ============================ 6. THE CROSS-IMAGE TWIN SWEEP, AND WHY IT IS EMPTY
# The tree's strongest borrowed-name mechanism is byte identity against a sibling
# (HANDOFF-RESUME-HERE.md: prom_a and prom_c run the same kernel, 36 pairs, 35
# structurally identical).  Round 7 swept twins INSIDE prom_c.  Nobody had swept
# prom_c's sub_XXXXXX against the CONTENT-named routines of the other images, and
# a lane that reports "no twin exists" without running the sweep is exactly the
# failure this tree lists twice ("no references" that had references).  So it runs.
#
# The comparison is by MNEMONIC SEQUENCE with operands dropped, not by bytes: a
# routine relocated into another image differs in every address operand while
# being the same code, and a raw byte diff calls that "8 bytes identical".  The
# mnemonics come from the MAME disassembly comment each source line already
# carries, so no subprocess and no second decoder is involved.
XT_IMAGES = [("prom_a", "wsa1_prom_a.s"), ("prom_b", "wsa1_prom_b.s"),
             ("prom_c", "wsa1_prom_c.s")]
XT_MIN = 15                  # instructions; below this a sequence match is noise


def _seqs(path):
    cur, out = None, collections.OrderedDict()
    for ln in open(os.path.join(ROOT, path)):
        ln = ln.rstrip("\n")
        m = LABEL.match(ln)
        if m:
            if "__" not in m.group(1):
                cur = m.group(1)
                out.setdefault(cur, [])
            continue
        if cur is None or ln.lstrip().startswith(";"):
            continue
        code = ln.split(";")[0].strip()
        if not code or code.startswith("."):
            continue
        d = ADDRC.search(ln)
        t = (d.group(2).strip().split() if d else code.split())
        out[cur].append(t[0] if t else "?")
    return out


def xtwins(minlen=XT_MIN):
    """Every prom_c sub_XXXXXX whose mnemonic sequence is IDENTICAL to that of a
    content-named routine anywhere in prom_a, prom_b or prom_c."""
    if "xt" in _C:
        return _C["xt"]
    idx = collections.defaultdict(list)
    nc = 0
    for tag, f in XT_IMAGES:
        for n, sq in _seqs(os.path.join(tag, f)).items():
            if UNNAMED.match(n) or FRAMED.match(n) or "__" in n or len(sq) < minlen:
                continue
            nc += 1
            idx[tuple(sq)].append((tag, n))
    hits = []
    for n, sq in _seqs(os.path.join("prom_c", "wsa1_prom_c.s")).items():
        if not UNNAMED.match(n) or len(sq) < minlen:
            continue
        t = tuple(sq)
        if t in idx:
            hits.append((len(sq), n, idx[t]))
    hits.sort(reverse=True)
    _C["xt"] = (hits, nc)
    return _C["xt"]


def show_xtwins():
    hits, nc = xtwins()
    print("=== 6. THE CROSS-IMAGE TWIN SWEEP -- run, and empty ===\n")
    print("  %d content-named routines of >= %d instructions across prom_a, prom_b"
          % (nc, XT_MIN))
    print("  and prom_c were indexed by mnemonic sequence, operands dropped, and")
    print("  every prom_c sub_XXXXXX of that size was looked up in the index.\n")
    if not hits:
        print("      NO HIT AT ALL -- %d prom_c sub_XXXXXX of that size, zero matches."
              % len([n for n, sq in _seqs(os.path.join("prom_c", "wsa1_prom_c.s")).items()
                     if UNNAMED.match(n) and len(sq) >= XT_MIN]))
    for L, n, m in hits:
        print("      %-12s %3d instructions  ==  %s"
              % (n, L, ", ".join("%s %s" % x for x in m)))
    print("\n  ★ ZERO, AND THE ZERO IS THIS ROUND'S OWN DOING.  Before --restage ran,")
    print("  the sweep had exactly ONE hit in the whole tree: sub_FADFAD, whose 46")
    print("  mnemonics are identical to Voice_RestagePitchReg0400_ForList's.  That")
    print("  routine is now Voice_RestageRegs0100_0140_ForList, named from the")
    print("  register group it sends rather than from the twin, because the twin")
    print("  differs in exactly the three call targets that decide WHICH registers")
    print("  it re-sends -- borrowing the name would have claimed the wrong ones.")
    print("  The one-hit state is still checkable: --selftest asserts the renamed")
    print("  routine's mnemonic sequence still equals the older routine's.\n")
    print("  So the cross-image kernel-twin lever -- the tree's strongest")
    print("  borrowed-name mechanism -- is EMPTY for prom_c's remaining sub_XXXXXX.")
    print("  That measured negative is why this round went looking for an OBJECT")
    print("  instead of another routine-shaped mechanism.")
    print("\n  ⚠ The sweep compares TEXT.  Two different instructions that render the")
    print("  same mnemonic would be called equal; nothing here depends on that not")
    print("  happening, since the result is a negative and a false MATCH could only")
    print("  make it less empty.")


# ==================== THE BLOCK COMMENT, GENERATED AND THEN CHECKED IN THE SOURCE
def record68_comment():
    """The map, as the comment that goes above the record's constructor.  It is
    GENERATED here and --selftest asserts the source contains it VERBATIM, so the
    two cannot drift: change the tracker and the check fails until the source is
    regenerated with --emit68."""
    rows, _c, by = record68_fields()
    per, _argset = record68()
    ctor = set(o for o in by if any(x[0] == CTOR for x in by[o]))
    L = []
    a = L.append
    a("; ==============================================================================")
    a("; ★ ROUND 10 -- THE 68-BYTE VOICE RECORD AT RAM 0x003BCF, FIELD BY FIELD")
    a("; ==============================================================================")
    a("; GENERATED by `python3 notes/prom_c_record68_round10.py --emit68`, which")
    a("; re-derives every row below from this source on every run; --selftest asserts")
    a("; the text is present verbatim, so the comment cannot drift from the tracker.")
    a(";")
    a("; THE ARRAY (wave 5, FINDINGS-prom_c-voice-module.md sec 4; re-derived here):")
    a(";     base   0x%04X  `ld DE,0x3bcf`             0xFADCCA" % RECORD_BASE)
    a(";     stride   0x%02X  `ld C,0x44` / `mul BC,H`   0xFADCD9 / 0xFADCDB"
      % RECORD_STRIDE)
    a(";     count    0x%02X  `cp H,0x40`                0xFADCD4, also the list terminator"
      % RECORD_COUNT)
    a(";     0x%04X + %d * 0x%02X = 0x%04X -- EXACTLY the base of the 27-byte envelope"
      % (RECORD_BASE, RECORD_COUNT, RECORD_STRIDE, EGREC_BASE))
    a(";     record array (notes/prom_c_understanding_round6.py sec 6).  They abut.")
    a(";")
    a("; THE FIELDS.  %d routines hold a pointer this round's rule proves is base +"
      % len(per))
    a("; 0x44*index; every displacement seen on one, below the stride, is a field.")
    a("; `w` is the width, read off the other operand's register -- the only place the")
    a("; size is stated.  `dir` is what the tracker SAW.  `ctor` marks the fields")
    a("; %s writes." % CTOR)
    a(";")
    a(";     field   w   dir     sites  rtns  ctor")
    for o, w, ns, nr, ds in rows:
        a(";     +0x%02X   %d   %-6s  %4d  %4d  %s"
          % (o, w, "/".join(sorted(ds)), ns, nr, "yes" if o in ctor else ""))
    a(";")
    a("; ★ THE %d FIELDS TILE ALL %d BYTES -- no gap, no overlap, widths summing to the"
      % (len(rows), RECORD_STRIDE))
    a("; stride, and no offset carrying two different determinate widths.  That is the")
    a("; map's own check: a tracker inventing offsets produces overlaps and one")
    a("; mis-reading widths produces gaps.  %s writes the %d fields marked"
      % (CTOR, len(ctor)))
    a("; `ctor` at those same widths, without ever walking the array -- an independent")
    a("; second reading of the same boundaries.")
    a(";")
    a("; MEANING: exactly ONE field has one.  +0x23 holds 0x1523 + 0x012C*part, the")
    a("; address of this voice's part record (`ld BC,0x1523` 0xFB0C8A,")
    a("; `ld (XHL+0x23),BC` 0xFB0CD6), which round 9's selftest already asserts.  The")
    a("; other 32 fields have an offset, a width, a direction and a site list and NO")
    a("; name, deliberately: reading a musical role out of a displacement is how this")
    a("; tree acquired five labels built on a morpheme that occurs zero times in all")
    a("; four ROM images.")
    a(";")
    a("; ⚠ THE TRACKER UNDER-REPORTS AND CANNOT SAY BY HOW MUCH.  It is blind to a")
    a("; record pointer that arrives in a register it cannot prove, is stashed in a")
    a("; stack slot, or is built by arithmetic it does not model -- `ld (XHL+0x23),BC`")
    a("; at 0xFB0CD6 really does write +0x23 and this tracker does not see it.  So a")
    a("; field's `dir` column is what the tracker SAW, never what the image does, and")
    a("; `no writer found` is a searched negative of THIS rule and of nothing else.")
    a("; ==============================================================================")
    return "\n".join(L)


def depth_lines():
    """{routine: the one derived line its header gains}.  Nothing here is a claim
    about what the routine is FOR; it is the list of record fields the tracker
    proves the routine touches, which is the same kind of statement as the
    `Calls:` and `Outputs:` lines the generated headers already carry."""
    per, argset = record68()
    out = {}
    for n, h in sorted(per.items()):
        blk = header_block(n)
        if blk is None or "; Evidence:" not in blk:
            continue                      # no generated header to extend; --apply says so
        fs = []
        for o in sorted(h):
            ds = sorted(set(w[2][1] for w in h[o]))
            fs.append("+0x%02X(%s)" % (o, "".join(sorted(set("".join(ds))))))
        how = "through its (XIZ+0x08) argument" if n in argset else "built in place"
        out[n] = ("; Voice record: touches voice_record[%s] -- pointer %s.  "
                  "Field map above %s." % (", ".join(fs), how, CTOR))
    return out


# ============================================================ THE APPLY MODE
# Every edit this round made to prom_c/wsa1_prom_c.s is made HERE, so it can be
# re-derived rather than trusted.  Comments only -- not one instruction byte
# changes, and scripts/analysis/assert_byte_identical.py is the proof.
NEW_TAIL = {
    "Voice_RestageRegs0100_0140_ForList": [
        "; What it is:  re-sends device registers 0x0100/0x0140 for every voice in the",
        ";          list its first argument points at.  Walks voice_record[] at the",
        ";          0x44 stride, switches on record[+0x01] & 0x3C, stages through",
        ";          Voice_StagePair_Reg0100_0140_AB or _CD and pushes the pair with",
        ";          Dev10C_SetChanReg_0100_0140.",
        "; Evidence: `calr 0xfacf3c` at 0xFAE004 IS Dev10C_SetChanReg_0100_0140, and the",
        ";          two stagers are `call 0xfa919b` (0xFADFED) and `call 0xfa92a5`",
        ";          (0xFADFF4).  Six routines in prom_c share this shape",
        ";          (notes/prom_c_record68_round10.py --restage) and no other one",
        ";          touches registers 0x0100/0x0140.",
        "; Unknown:  what the four class values 4/8/0x10/0x20 of record[+0x01] & 0x3C",
        ";          SELECT.  The name claims the register group and nothing else.",
    ],
    "Voice_RestageReg0080_ForList": [
        "; What it is:  re-sends device register 0x0080 for every voice in the list its",
        ";          first argument points at.  Same walk as the rest of the family;",
        ";          stages through sub_FAB79D or sub_FAB7E0 and pushes with",
        ";          Dev10C_SetChanReg_0080_ClrBit15.",
        "; Evidence: `call 0xfb7038` at 0xFADE1F IS Dev10C_SetChanReg_0080_ClrBit15, and",
        ";          the two stagers are `call 0xfab79d` (0xFADE08) and `call 0xfab7e0`",
        ";          (0xFADE0F).  No other member of the six-routine family",
        ";          (notes/prom_c_record68_round10.py --restage) touches register 0x0080.",
        "; Unknown:  what the two stagers do -- they are still sub_XXXXXX -- and what",
        ";          the class values select.  The name claims the register and no more.",
    ],
}
REFUSAL_TAIL = [
    "; REFUSED (round 10): this is one of the six voice-list walkers",
    ";          notes/prom_c_record68_round10.py --restage selects, and THREE of the six",
    ";          end in the SAME register pair 0x0840/0x0880 --",
    ";          sub_FADE2F through Dev10C_SetChanReg_0840_0880 (`calr 0xfacea2`,",
    ";          0xFADE9B), sub_FAE013 and sub_FAE0A1 through ..._dup (`calr 0xfacf78`,",
    ";          0xFAE092 and 0xFAE0F8), and the tree's own name for the second says it",
    ";          writes the same two registers.  So `Voice_RestageRegs0840_0880_ForList`",
    ";          would be true of all three and identify none.  The only discriminators",
    ";          are the class mask each accepts out of record[+0x01] & 0x3C (0xFADE53,",
    ";          0xFAE037, 0xFAE0C4) and a flag byte pushed to the CD stager, and",
    ";          neither has an established meaning in this tree.  So it keeps its",
    ";          address, and this is the reason rather than a shrug.",
]
OLD_TAIL = ("; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a "
            "field,\n;          so the name is an address.")


def apply():
    src = open(SRC).read()
    n_ren = n_tail = n_line = 0
    # 1. the two renames, every spelling, interior labels included
    for old, new, _a, _t, _acc, _why in RESTAGE_NAMED:
        if old in src:
            src = src.replace(old, new)
            n_ren += 1
    # 2. the rewritten tails
    for name, tail in NEW_TAIL.items():
        i = src.index("\n; %s -- 0x" % name)
        j = src.index("\n%s:\n" % name, i)
        blk = src[i:j]
        if "\n".join(tail) in blk:
            continue
        assert OLD_TAIL in blk, name
        src = src[:i] + blk.replace(OLD_TAIL, "\n".join(tail)) + src[j:]
        n_tail += 1
    for name, _a, _t, _acc in RESTAGE_REFUSED:
        i = src.index("\n; %s -- 0x" % name)
        j = src.index("\n%s:\n" % name, i)
        blk = src[i:j]
        if "REFUSED (round 10)" not in blk:
            assert OLD_TAIL in blk, name
            src = src[:i] + blk.replace(OLD_TAIL, "\n".join(REFUSAL_TAIL)) + src[j:]
            n_tail += 1
    open(SRC, "w").write(src)
    _C.clear()
    # 3. the field-map block comment, above the record's constructor
    src = open(SRC).read()
    cm = record68_comment()
    if cm not in src:
        anchor = "; %s -- 0x" % CTOR
        i = src.index("\n" + anchor) + 1
        src = src[:i] + cm + "\n" + src[i:]
        open(SRC, "w").write(src)
    _C.clear()
    # 4. the derived per-routine line, before each header's Evidence line.
    #    depth_lines() is recomputed ONCE here, AFTER the renames, so the keys are
    #    the names the source now carries.
    src = open(SRC).read()
    for name, line in sorted(depth_lines().items()):
        i = src.index("\n; %s -- 0x" % name)
        j = src.index("\n%s:\n" % name, i)
        blk = src[i:j]
        if line in blk:          # ⚠ per BLOCK, not per file: two routines that touch
            continue             # the same fields produce the same line, and a
                                 # file-wide test silently skipped 22 of them once.
        k = blk.index("\n; Evidence:")
        src = src[:i] + blk[:k] + "\n" + line + blk[k:] + src[j:]
        n_line += 1
    open(SRC, "w").write(src)
    _C.clear()
    print("applied: %d renames, %d rewritten header tails, %d derived record lines"
          % (n_ren, n_tail, n_line))


def selftest():
    print("=== SELFTEST (round 10) ===\n")
    bad = bad_claims10()
    check(not bad, "all %d citations decode AT the cited address" % len(CLAIMS10))
    la, lt = CLAIMS10[-1]
    check(mnemonic(la).lower().startswith(lt.lower()),
          "...tested on the LAST citation too (0x%06X wants %r)" % (la, lt))

    check(mnemonic(0xFADCCA) == "ld DE,0x3bcf",
          "the base 0x3BCF is an operand at 0xFADCCA")
    check(mnemonic(0xFADCD9) == "ld C,0x44" and mnemonic(0xFADCDB) == "mul BC,H",
          "the stride 0x44 is an operand at 0xFADCD9, multiplied at 0xFADCDB")
    check(mnemonic(0xFADCD4) == "cp H,0x40", "the count 0x40 is an operand at 0xFADCD4")
    check(RECORD_BASE + RECORD_COUNT * RECORD_STRIDE == EGREC_BASE,
          "0x3BCF + 64*68 = 0x4CCF, the base of the 27-byte envelope record array")

    rows, conflict, by = record68_fields()
    per, argset = record68()
    check(not conflict, "no field offset carries two different determinate widths")
    ok, gaps = record68_tiling()
    check(ok, "the %d fields tile 0x00..0x43 with no gap and no overlap" % len(rows))
    check(sum(w for _o, w, _s, _r, _d in rows) == RECORD_STRIDE,
          "...and their widths sum to 68, the stride itself")
    check(rows[0][0] == 0 and rows[0][1] == 1, "the FIRST field is +0x00, one byte")
    check(rows[-1][0] == 0x43 and rows[-1][1] == 1,
          "the LAST field is +0x43, one byte, ending exactly at the stride")
    check(len(per) >= 60, "the rule proves a record pointer in %d routines" % len(per))
    check(sorted(per["sub_FAE013"]) == [0x01, 0x05, 0x13],
          "sub_FAE013's fields are +0x01, +0x05, +0x13 -- as its listing reads")
    check(sorted(per["sub_FAE0A1"]) == [0x01],
          "sub_FAE0A1, the LAST walker by address, touches only +0x01")
    ctor = sorted(o for o in by if any(x[0] == CTOR for x in by[o]))
    check(len(ctor) == 12, "%s writes 12 of the %d fields" % (CTOR, len(rows)))
    check(ctor[-1] == 0x25, "...the highest of them being +0x25")
    check(mnemonic(0xFB401C) == "ld (XIX+0x25),BC",
          "...a 16-bit store, the width the map gives +0x25")

    src = open(SRC).read()
    check(record68_comment() in src,
          "the generated field map is present in prom_c/wsa1_prom_c.s VERBATIM")

    fam = restage_family()
    check(len(fam) == 6, "the seven-text shape predicate selects exactly 6 routines")
    check("Voice_RestagePitchReg0400_ForList" in fam,
          "...one already named, which is what calibrates the shape")
    lab = source_labels()
    for _old, new, a, t, _acc, _why in RESTAGE_NAMED:
        check(new in lab, "%s is defined in the source" % new)
        blk = header_block(new)
        check(blk is not None and "Evidence:" in blk,
              "...and its header carries an Evidence: line")
        check(mnemonic(a).lower().startswith(t.lower()),
              "...and the accessor it is named for is at 0x%06X" % a)
    for old, _new, _a, _t, _acc, _why in RESTAGE_NAMED:
        check(old not in src, "the old name %s is gone from the source" % old)
    accs = [t for _n, _a, t, _acc in RESTAGE_REFUSED]
    check(len(set(accs)) < len(accs),
          "the refusal's premise: the three refused walkers do NOT have three "
          "distinct accessors")
    for n, _a, _t, _acc in RESTAGE_REFUSED:
        check(n in lab, "%s keeps its address, as the refusal says" % n)
        blk = header_block(n)
        check(blk is not None and "REFUSED" in blk,
              "...and its header states the refusal where a reader hits it")

    rows2 = depth10()
    g = grade_counts()
    check(g["content"] - len(rows2) == 168,
          "168 of prom_c's `content` labels are `<parent>__<word>` interior targets")
    noh = [r for r in rows2 if r[2] < 3]
    preset = [r for r in noh if r[0].startswith("PresetBank")]
    irq = [r for r in noh if r[0] in IRQ_TRAMPOLINES]
    check(len(noh) == len(preset) + len(irq),
          "every real content object without a header is a PresetBank row or a "
          "trampoline")
    check(len(irq) == len(IRQ_TRAMPOLINES) and irq[-1][0] == "IRQ_INTTC3",
          "...the trampolines are the 7 named ones, LAST of them IRQ_INTTC3")
    check(len(rows2) and sum(1 for r in rows2 if r[2] >= 3) * 100 // len(rows2) >= 79,
          "at least 79% of prom_c's real content objects carry a header")

    hits, nc = xtwins()
    check(not hits,
          "the cross-image mnemonic-sequence sweep has NO hit left in the tree")
    check(nc >= 700, "...indexed against %d content-named routines of >= %d "
                     "instructions in prom_a, prom_b and prom_c" % (nc, XT_MIN))
    sq = _seqs(os.path.join("prom_c", "wsa1_prom_c.s"))
    check(sq.get("Voice_RestageRegs0100_0140_ForList")
          == sq.get("Voice_RestagePitchReg0400_ForList"),
          "the one hit the sweep DID have is still there: the renamed routine's 46 "
          "mnemonics equal Voice_RestagePitchReg0400_ForList's")
    check(len(sq.get("Voice_RestageRegs0100_0140_ForList") or []) == 46,
          "...and there are 46 of them")

    dl = depth_lines()
    missing = [n for n, l in dl.items() if l not in (header_block(n) or "")]
    check(not missing,
          "every one of the %d derived `Voice record:` lines is in the source"
          % len(dl))
    lastn = sorted(dl)[-1]
    check(dl[lastn] in (header_block(lastn) or ""),
          "...tested on the LAST routine by name too (%s)" % lastn)
    print("\n%d checks, %d failures" % (CHECKS[0], len(FAILS)))
    return 1 if FAILS else 0


def main():
    args = sys.argv[1:]
    if "--selftest" in args:
        sys.exit(selftest())
    if "--emit68" in args:
        print(record68_comment())
        return
    if "--apply" in args:
        apply()
        return
    if "--emitdepth" in args:
        for n, l in sorted(depth_lines().items()):
            print("%-42s %s" % (n, l))
        return
    run_all = not args
    if run_all or "--record68" in args:
        show_record68()
        print()
    if run_all or "--restage" in args:
        show_restage()
        print()
    if run_all or "--depth10" in args:
        show_depth10()
        print()
    if run_all or "--claims10" in args:
        show_claims10()
        print()
    if run_all or "--refused10" in args:
        show_refused10()
        print()
    if run_all or "--xtwin" in args:
        show_xtwins()


if __name__ == "__main__":
    main()
