#!/usr/bin/env python3
"""RE-AUDIT of prom_b 0xF17559-0xF1B3FF after wave 7 round 1's lane b1 was REFUTED.

QUESTION IT ANSWERS
  Round 1 produced `notes/prom_b_f17559_layout.py` (which stands) and a dossier
  (which does not).  The skeptic found the dossier claimed THREE ambiguous
  segments where the script prints SIX, and that six of its quantities reproduce
  as different numbers.  This script answers, entirely from the ROM:

    1. Which interpreter runs each of the six AMBIG segments, and WHAT PINS IT?
    2. Of the four segments whose KIND the dossier and the script disagree on,
       which is right -- and is either right?
    3. What is every mis-stated count actually?
    4. Is the span safe to convert, and with what layout?

WHAT IS NEW HERE, AND WHY THE OLD SCRIPT COULD NOT SEE IT
  `prom_b_f17559_layout.py` labels a run AMBIG when its records satisfy BOTH
  interpreters' implied-length tables.  That happens because 28 of this span's
  call sites reach the interpreter through `jp (XIX)` rather than a literal
  `call`, so the layout has no thunk to read the interpreter off.

  ⚠ THE OBVIOUS FIX IS THE WRONG ONE.  "The record lengths fit B exactly and A
  only vacuously, so it is B" MISCLASSIFIES 23 of the 4,097 records whose
  interpreter is known from a literal call site -- and six of those 23 are
  `op 07 len 17`, which is exactly the shape of two of the AMBIG runs here.
  `--calibrate` prints that null.  So this script does not use the length rule
  to break a tie; it resolves the register instead:

    XIX RESOLUTION  --  walk backwards through the PROVEN prom_a instruction text
    from the `jp (XIX)` to the nearest write to XIX.  In every case here it is
    the routine's own prologue, `lda XIX,0x00F42E00` (interpreter A's stack-pair
    thunk) or `lda XIX,0x00F42E04` (interpreter B's).  Calibration: of the 39
    `jp (XIX)` display-list sites in prom_a this resolves, 36 also have a
    DECISIVE length rule, and the two agree 36 of 36, disagree 0 (`--xix`).
    One of the 39 -- 0xF18C69-0xF18CD5 -- is independently named by a literal
    `call T_F42E00` at prom_a 0xFBCCE7, and the resolver agrees with it too.

    THE STRIDE LOOP  --  prom_a 0xFBF79C computes a record stride by SUBTRACTING
    two in-span addresses (`lda XWA,0xF1A037 / lda XIX,0xF1A048 / sub XIX,XWA`)
    and then runs eight records through `call 0xF42E0C`
    (DisplayListB_RunOne_Stack).  The layout mistook the subtrahend for an object
    boundary.  Exactly ONE such loop exists in prom_a (`--ambig` censuses it).

    IDENTITY  --  the eight bytes at 0xF17C00 are byte-identical to the ONE-record
    interpreter-A display list at 0xF18CD5, which prom_a 0xFBD235 runs with a
    literal `call 0xF42E00`.  The pattern occurs exactly twice in prom_b.

RESULT (all of it printed by this script)
  Six segments were AMBIG.  FOUR are resolved, to interpreter B, by a mechanism:
      0xF1814E-0xF181D5   B   prom_a 0xFBE2EC `lda XIX,0xF42E04`, jp at 0xFBE32A
      0xF181D6-0xF1825D   B   the same routine, jp at 0xFBE34E
      0xF1A037-0xF1A047 +  B  ONE record_array, 8 x 17 bytes, run one record
      0xF1A048-0xF1A0BE       at a time by T_F42E0C; 0xF1A048 is the STRIDE
                              OPERAND, not an object boundary -- the split is an
                              artefact of treating it as one
  ONE has its interpreter and its kind fixed by identity but is UNREACHED:
      0xF17C00-0xF17C07   A   byte-identical to 0xF18CD5; NOTHING executes it
  ONE remains genuinely unresolved as to execution:
      0xF1A14D-0xF1A157   B by format; the ONLY reference to it in prom_a/b/c is
                              as the END address of the run at 0xF1A137, i.e. one
                              past the last byte the interpreter reads

  THE HONEST SCORE, on the two axes that are NOT the same question:

    WHICH INTERPRETER   5 of 6 resolved by a mechanism: TWO (0xF1814E,
                        0xF181D6) by the caller's own XIX; TWO (0xF1A037,
                        0xF1A048 -- one object) by the stride loop's literal
                        `call 0xF42E0C`; ONE (0xF17C00) by byte-identity with a
                        list that a literal `call 0xF42E00` names.  The sixth,
                        0xF1A14D, is NOT resolved by a mechanism: it is
                        interpreter B by record FORMAT and by its two siblings,
                        and the format rule has a MEASURED 0.56% error rate, all
                        of it in the direction of calling an A record B.

    IS IT EVER RUN      4 of 6.  `--null-frame` in the layout script flags four
                        runs, 155 bytes, with no call site at all.  This audit
                        gives two of them one (0xF1A037-0xF1A0BE, 136 bytes),
                        leaving 19 bytes -- 0xF17C00 (8) and 0xF1A14D (11),
                        0.12% of the span -- reached by NOTHING the census sees.

  ⚠ "Unreached" is a statement about the CENSUS, not about the machine: the four
  call shapes the census knows are listed in `notes/prom_b_dl_call_shapes.py`,
  and this span alone needed a fifth (the stride loop) to be found by hand.

RUN
  python3 notes/prom_b_f17559_reaudit.py             # everything
  python3 notes/prom_b_f17559_reaudit.py --ambig     # the six, one section each
  python3 notes/prom_b_f17559_reaudit.py --kinds     # the four kind disagreements
  python3 notes/prom_b_f17559_reaudit.py --counts    # every mis-stated count
  python3 notes/prom_b_f17559_reaudit.py --calibrate # the two nulls
  python3 notes/prom_b_f17559_reaudit.py --xix       # every jp (XIX) site resolved
  python3 notes/prom_b_f17559_reaudit.py --verdict   # convert or not, and how
  python3 notes/prom_b_f17559_reaudit.py --selftest  # 81 checks, first AND last
Exit status is non-zero if a self-check fails.
"""
import collections
import contextlib
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_f17559_layout as L                                   # noqa: E402
import prom_b_dl_length_audit as LA                                # noqa: E402
import prom_b_display_lists as DL                                  # noqa: E402

LO, HI = L.LO, L.HI
A_BASE, B_BASE = 0xF80000, 0xF00000
RUN_A, RUN_B = 0xF42E00, 0xF42E04          # (start,end) pair on the stack
ONE_A, ONE_B = 0xF42E08, 0xF42E0C          # one record on the stack

# the six segments prom_b_f17559_layout.py labels AMBIG, in address order
AMBIG = [0xF17C00, 0xF1814E, 0xF181D6, 0xF1A037, 0xF1A048, 0xF1A14D]

FAIL = []
_c = {}


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# --------------------------------------------------------------- the images
def rom(which):
    return L.rom(which)


def by(a, n=1, which="b"):
    return rom(which)[a - (B_BASE if which == "b" else A_BASE):
                      a - (B_BASE if which == "b" else A_BASE) + n]


def w32(a):
    return int.from_bytes(by(a, 4), "little")


def w16(a):
    return int.from_bytes(by(a, 2), "little")


def segs():
    if "segs" not in _c:
        _c["segs"] = L.build()
    return _c["segs"]


def tabs():
    if "t" not in _c:
        _c["t"] = LA.tables(rom("b"))
    return _c["t"]


# ------------------------------------------------------- the framing walk
def frames(s, e):
    """The records of [s,e) if the walk lands exactly on e, else None.  Works on
    prom_b and on prom_a (prom_a holds display lists too, and they are half the
    calibration corpus)."""
    for img, base in ((rom("b"), B_BASE), (rom("a"), A_BASE)):
        if base <= s < e <= base + len(img):
            out, p = [], s
            while p < e:
                op, ln = img[p - base], img[p - base + 1]
                if op >= 0x24 or ln < 2 or p + ln > e:
                    return None
                out.append((p, op, ln))
                p += ln
            return out if p == e and out else None
    return None


def fit(op, ln, which):
    """EXACT / VAC / NO -- how a record's length byte fits one interpreter.

    EXACT means the handler's implied length is a FIXED number and the record
    declares exactly it.  VAC means the handler is a text handler or a bare
    `ret`, whose rule is only a MINIMUM, so the fit says almost nothing."""
    ta, tb = tabs()
    tbl, imp, bound = (ta, LA.IMPLIED_A, 0x24) if which == "A" \
        else (tb, LA.IMPLIED_B, 0x0F)
    if op >= bound:
        return "NO"
    h = tbl[op]
    if h not in imp:
        return "?"
    kind, n = imp[h]
    if kind == "fixed":
        return "EXACT" if ln == n else "NO"
    return "VAC" if ln >= n else "NO"


def length_rule(recs):
    """The interpreter the record lengths alone allow: A, B, AMBIG or NONE."""
    a = all(fit(op, ln, "A") != "NO" for _p, op, ln in recs)
    b = all(fit(op, ln, "B") != "NO" for _p, op, ln in recs)
    return "A" if a and not b else "B" if b and not a else "AMBIG" if a else "NONE"


# --------------------------------------------------- XIX resolution in prom_a
def _body(t):
    return t.split("  |  ")[0]


_W_XIX = re.compile(r"^(?:lda(?:_\w+)?|ldw?b?(?:_\w+)?|pop|add|sub|and|or|xor|"
                    r"inc|dec|mul|div|ex|extz|exts|neg|cpl|rlc|rrc|sll|srl|sla|"
                    r"sra|min|max|ld)\s+x?ix\b", re.I)
_LDA_XIX = re.compile(r"^lda(?:_\w+)?\s+xix,\s*\(0x([0-9a-f]{4,6})\)", re.I)
_RET = re.compile(r"^(ret|reti|retd)\b", re.I)
_JP_XIX = re.compile(r"^jp\s+\(xix\)", re.I)
_IMM = re.compile(r"^(?:lda(?:_\w+)?|ldw?)\s+(x[a-z]{2}),\s*\(0x([0-9a-f]{4,8})\)",
                  re.I)
_PUSH = re.compile(r"^push\s+(x[a-z]{2})", re.I)
_CALL = re.compile(r"^call\s+0x([0-9a-f]{6})", re.I)
_SUB = re.compile(r"^sub\s+(x[a-z]{2}),\s*(x[a-z]{2})", re.I)
_INC = re.compile(r"^inc\s+(\d+),\s*([a-z]{1,3})\b", re.I)


def _resolve_xix(ins, i):
    """(value, address of the instruction that set it) for XIX at ins[i].

    Backwards to the FIRST write to XIX.  A `ret` stops the scan, because past it
    we are in another routine and the answer would be someone else's.  The
    routines here all set XIX in their own prologue, so the scan never leaves."""
    for j in range(i - 1, max(-1, i - 400), -1):
        t = _body(ins[j][1])
        m = _LDA_XIX.match(t)
        if m:
            return int(m.group(1), 16), ins[j][0]
        if _W_XIX.match(t) or _RET.match(t):
            return None, ins[j][0]
    return None, None


def xix_sites():
    """[(jp address, start, end, thunk, address of the `lda XIX`, records,
        length-rule verdict)] for every prom_a `jp (XIX)` that reaches a
    display-list stack-pair thunk."""
    if "xix" in _c:
        return _c["xix"]
    ins = L.instructions("a")
    out = []
    for i, (addr, txt) in enumerate(ins):
        if not _JP_XIX.match(_body(txt)):
            continue
        v, src = _resolve_xix(ins, i)
        if v not in (RUN_A, RUN_B):
            continue
        vals = []
        for j in range(max(0, i - 10), i):
            m = _IMM.match(_body(ins[j][1]))
            if m and j + 1 < len(ins):
                p = _PUSH.match(_body(ins[j + 1][1]))
                if p and p.group(1).lower() == m.group(1).lower():
                    vals.append(int(m.group(2), 16))
        best = None
        for x in vals:
            for y in vals:
                if y < x and frames(y, x):
                    best = (y, x)            # the last such pair before the jp
        if best is None:
            out.append((addr, None, None, v, src, [], "NOPAIR"))
            continue
        r = frames(*best)
        out.append((addr, best[0], best[1], v, src, r, length_rule(r)))
    _c["xix"] = out
    return out


def xix_jp_total():
    ins = L.instructions("a")
    return sum(1 for _a, t in ins if _JP_XIX.match(_body(t)))


def table_consumers():
    """{pointer-table base: (add address, thunk, call address)} -- for every
    `add XBC,<base> / ld XBC,(XBC) / push XBC / call T_F42E08|T_F42E0C` in the
    PROVEN prom_a text.  This is what turns "these bytes look like an array of
    records" into "the firmware fetches entry k of this table and runs ONE
    record": the thunk is read off, not assumed."""
    if "tc" in _c:
        return _c["tc"]
    ins = L.instructions("a")
    out = {}
    for i, (addr, txt) in enumerate(ins):
        m = re.search(r"add\s+x[a-z]{2},\s*0x00([0-9a-f]{6})", _body(txt), re.I)
        if not m:
            continue
        base = int(m.group(1), 16)
        if not (LO <= base < HI):
            continue
        for j in range(i + 1, min(len(ins), i + 8)):
            c = _CALL.match(_body(ins[j][1]))
            if c and int(c.group(1), 16) in (ONE_A, ONE_B):
                out.setdefault(base, (addr, int(c.group(1), 16), ins[j][0]))
                break
    _c["tc"] = out
    return out


def stride_loops():
    """[(sub address, base, second, stride, count, count source, thunk, call addr)]
    -- every place prom_a computes a display-list record stride by SUBTRACTING
    two in-span addresses and then runs records one at a time.

    ⚠ SCOPE, so the count below is not read as more than it is: this matches ONE
    shape -- `lda Ra,<x> ... lda Rb,<y> / sub Rb,Ra`, both immediates inside
    prom_b's display-list area, within six instructions, followed within thirty
    by a `call T_F42E08|T_F42E0C`.  A stride arrived at any other way (a
    constant, a table lookup, a shift) is INVISIBLE to it.  "Exactly one" means
    exactly one of THIS shape."""
    if "sl" in _c:
        return _c["sl"]
    ins = L.instructions("a")
    out = []
    for i, (addr, txt) in enumerate(ins):
        m = _SUB.match(_body(txt))
        if not m:
            continue
        dst, src = m.group(1).lower(), m.group(2).lower()
        vals = {}
        for j in range(max(0, i - 6), i):
            mm = re.match(r"^lda(?:_\w+)?\s+(x[a-z]{2}),\s*\(0x([0-9a-f]{6})\)",
                          _body(ins[j][1]), re.I)
            if mm:
                vals[mm.group(1).lower()] = int(mm.group(2), 16)
        if dst not in vals or src not in vals:
            continue
        v1, v2 = vals[dst], vals[src]
        if not (B_BASE <= v1 < 0xF40000 and B_BASE <= v2 < 0xF40000):
            continue
        thunk = call = None
        for j in range(i, min(len(ins), i + 30)):
            c = _CALL.match(_body(ins[j][1]))
            if c and int(c.group(1), 16) in (ONE_A, ONE_B):
                thunk, call = int(c.group(1), 16), ins[j][0]
                break
        cnt = cntsrc = None
        for j in range(max(0, i - 20), i):
            mi = _INC.match(_body(ins[j][1]))
            if mi:
                cnt, cntsrc = int(mi.group(1)) + 1, ins[j][0]
        out.append((addr, v2, v1, v1 - v2, cnt, cntsrc, thunk, call))
    _c["sl"] = out
    return out


# ------------------------------------------------------- reference censuses
def refs24(target):
    """[(image, INSTRUCTION address, preceding byte)] for every 24-bit
    little-endian occurrence of `target`.

    ⚠ TWO traps, both of which this project has paid for:
    (a) The 32-bit search the first draft used finds NOTHING here, because
        `lda XBC,0x00F1814E` encodes the address in 24 bits.  A negative from the
        wrong instrument is not a negative.
    (b) The address reported is the OPCODE's, not the operand's.  `lda_24` is
        `F2 lo mid hi reg`, so the operand sits at opcode+1; citing the operand
        is the systematic off-by-one that round 1's lane a2 committed 31 times.
        Rows whose preceding byte is 0xF2 are instructions and are reported at
        opcode address; the rest are data words and are reported where they lie."""
    w = target.to_bytes(3, "little")
    out = []
    for k, base in (("a", A_BASE), ("b", B_BASE), ("c", A_BASE)):
        d = rom(k)
        i = -1
        while True:
            i = d.find(w, i + 1)
            if i < 0:
                break
            pre = d[i - 1] if i else 0
            out.append((k, base + i - (1 if pre == 0xF2 else 0), pre))
    return out


def ptrs32(target):
    """[(image, address)] for every 32-bit little-endian word equal to target."""
    w = target.to_bytes(4, "little")
    out = []
    for k, base in (("a", A_BASE), ("b", B_BASE), ("c", A_BASE)):
        d = rom(k)
        i = -1
        while True:
            i = d.find(w, i + 1)
            if i < 0:
                break
            out.append((k, base + i))
    return out


def seg_of(addr):
    for k, a, n, w in segs():
        if a <= addr < a + n:
            return k, a, n, w
    return None


# =========================================================== 1. the six AMBIG
def ambig():
    print("=" * 78)
    print("THE SIX AMBIG SEGMENTS -- there are SIX, not three (the dossier's")
    print("FATAL error).  What follows is what pins each one.")
    print("=" * 78)
    lay = {a: (k, n, w) for k, a, n, w in segs()}
    print("\nthe layout's own labels, verbatim:")
    for a in AMBIG:
        k, n, w = lay[a]
        print("  0x%06X %-13s %4d  %s" % (a, k, n, w))

    print("\n--- 0xF1814E-0xF181D5 and 0xF181D6-0xF1825D : INTERPRETER B ---")
    for site in xix_sites():
        if site[1] in (0xF1814E, 0xF181D6):
            print("  prom_a 0x%06X  jp (XIX)  runs 0x%06X-0x%06X, %d records"
                  % (site[0], site[1], site[2], len(site[5])))
            print("      XIX was set at prom_a 0x%06X to 0x%06X = %s"
                  % (site[4], site[3], "T_F42E00 (interpreter A)"
                     if site[3] == RUN_A else "T_F42E04 (interpreter B)"))
            print("      length rule alone says: %s   <- which is why it was AMBIG"
                  % site[6])
    print("  corroboration, from the record fields rather than the caller:")
    for p in (0xF1814E, 0xF181D6):
        r = frames(p, p + 136)
        ptr = w32(p + 7)
        print("      0x%06X: %d records, all op %02X len %d; +7 = 0x%06X, "
              "+0x0B width %d" % (p, len(r), r[0][1], r[0][2], ptr, w16(p + 0x0B)))
        s = seg_of(ptr)
        print("               the +7 target is the layout's %s at 0x%06X (%s)"
              % (s[0], s[1], s[3][:46]))

    print("\n--- 0xF1A037-0xF1A047 + 0xF1A048-0xF1A0BE : ONE ARRAY, INTERPRETER B ---")
    print("  the split is an ARTEFACT: 0xF1A048 is a stride operand, not a boundary.")
    sl = stride_loops()
    print("  stride loops in the whole of prom_a: %d" % len(sl))
    for addr, base, second, stride, cnt, cntsrc, thunk, call in sl:
        print("      prom_a 0x%06X  sub -> stride = 0x%06X - 0x%06X = %d"
              % (addr, second, base, stride))
        print("      count %d, from `inc %d,D` at prom_a 0x%06X"
              % (cnt, cnt - 1, cntsrc))
        print("      each record run by `call 0x%06X` at prom_a 0x%06X = %s"
              % (thunk, call, "T_F42E0C DisplayListB_RunOne_Stack (interpreter B)"
                 if thunk == ONE_B else "T_F42E08 (interpreter A)"))
        print("      base + count x stride = 0x%06X + %d x %d = 0x%06X"
              % (base, cnt, stride, base + cnt * stride))
        nxt = seg_of(base + cnt * stride)
        print("      and 0x%06X is exactly the next segment: %s 0x%06X (%s)"
              % (base + cnt * stride, nxt[0], nxt[1], nxt[3][:46]))
        r = frames(base, base + cnt * stride)
        print("      the %d records: all op %02X len %d; +0x0F steps %s"
              % (len(r), r[0][1], r[0][2],
                 " ".join("%02X" % w16(p + 0x0F) for p, _o, _l in r)))

    print("\n--- 0xF17C00-0xF17C07 : INTERPRETER A BY IDENTITY, BUT UNREACHED ---")
    pat = by(0xF17C00, 8)
    hits = []
    i = -1
    while True:
        i = rom("b").find(pat, i + 1)
        if i < 0:
            break
        hits.append(B_BASE + i)
    print("  bytes: %s" % " ".join("%02X" % x for x in pat))
    print("  occurrences of that exact 8-byte string in prom_b: %d at %s"
          % (len(hits), " ".join("0x%06X" % h for h in hits)))
    twin = [h for h in hits if h != 0xF17C00][0]
    s = seg_of(twin)
    print("  the twin 0x%06X is the layout's %s: %s" % (twin, s[0], s[3]))
    for st, en, t, prom, ia in L.dl_sites():
        if st == twin:
            print("      named by prom_%s 0x%06X with a LITERAL call to T_%06X"
                  % (prom, ia, t))
    print("  so its opcode (0x%02X), length (%d) and interpreter (A) are settled by"
          % (pat[0], pat[1]))
    print("  a proven object, not by the length rule.  What is NOT settled:")
    r24 = [h for h in refs24(0xF17C00) if h[2] == 0xF2]
    print("      `lda Rr,0xF17C00` instructions in prom_a/b/c: %d" % len(r24))
    p32 = ptrs32(0xF17C00)
    print("      32-bit words equal to 0x00F17C00: %d, at %s"
          % (len(p32), " ".join("prom_%s 0x%06X" % h for h in p32)))
    tbl = 0xF17A6C
    idx = (p32[0][1] - tbl) // 4
    print("      0x%06X is entry [%d] of the pointer table at 0x%06X, which the"
          % (p32[0][1], idx, tbl))
    print("      layout calls UNREFERENCED: 32-bit words equal to 0x00F17A6C = %d,"
          % len(ptrs32(tbl)))
    print("      `lda Rr,0xF17A6C` instructions = %d"
          % len([h for h in refs24(tbl) if h[2] == 0xF2]))
    print("      and that table is the rebased pointer table of a 24x24 value-glyph")
    print("      module whose bitmap copy stops after 4 of 29 glyphs, so entry [4]")
    print("      is a DANGLING pointer -- 0 of the 8 bytes at 0x%06X match the live"
          % 0xF17C00)
    live = 0xF32001
    print("      module's 5th glyph at 0x%06X (%d of 8 bytes equal)"
          % (live, sum(1 for i in range(8) if by(0xF17C00 + i, 1) == by(live + i, 1))))

    print("\n--- 0xF1A14D-0xF1A157 : WELL-FORMED, INTERPRETER B BY FORMAT, UNREACHED ---")
    r = frames(0xF1A14D, 0xF1A158)
    print("  1 record, op %02X len %d; fit under A = %s, under B = %s"
          % (r[0][1], r[0][2], fit(r[0][1], r[0][2], "A"), fit(r[0][1], r[0][2], "B")))
    print("  ⚠ that asymmetry is NOT proof -- see --calibrate.")
    hits = [h for h in refs24(0xF1A14D) if h[2] == 0xF2]
    print("  `lda Rr,0xF1A14D` instructions in prom_a/b/c: %d" % len(hits))
    for _k, a, _p in hits:
        for st, en, t, prom, ia in L.dl_sites():
            if en == 0xF1A14D:
                print("      prom_a 0x%06X -- and it is the END address of the run "
                      "0x%06X-0x%06X" % (a, st, en))
                print("      (an end address is ONE PAST the last byte the "
                      "interpreter reads)")
    fam = (0xF1A137, 0xF1A14D, 0xF1A163)
    print("  the three op-08 records of this neighbourhood, byte by byte:")
    for p in fam:
        run = [(st, en, t, ia) for st, en, t, prom, ia in L.dl_sites() if st == p]
        print("      0x%06X  %s   %s" % (p, " ".join("%02X" % x for x in by(p, 11)),
              "run by T_%06X from prom_a 0x%06X" % (run[0][2], run[0][3])
              if run and run[0][2] else "NO CALL SITE STARTS HERE"))
    diff = [i for i in range(11)
            if len({by(p + i, 1)[0] for p in fam}) > 1]
    print("      they differ in %d of 11 bytes, at offsets %s -- the variable "
          "address," % (len(diff), diff))
    print("      the mask and the table pointer, and nothing else")
    print("  its +7 pointer 0x%06X is ALSO the +7 pointer of the record at "
          "0xF1A158," % w32(0xF1A14D + 7))
    print("  which prom_a 0xFBF795 does run (`call 0x%06X`), so the table it names"
          % ONE_B)
    print("  is pinned WITHOUT this record.  Nothing here is circular; nothing here")
    print("  proves the machine ever draws it.")

    print("\n--- WHAT IS LEFT UNREACHED, IN BYTES ---")
    nf = {0xF17C00: 8, 0xF1A037: 17, 0xF1A048: 119, 0xF1A14D: 11}
    print("  the layout's --null-frame flags %d runs with no call site: %d bytes"
          % (len(nf), sum(nf.values())))
    got = {0xF1A037: 17, 0xF1A048: 119}
    print("  this audit reaches %d of them (%d bytes): the stride-loop array"
          % (len(got), sum(got.values())))
    left = {k: v for k, v in nf.items() if k not in got}
    print("  still reached by nothing: %s = %d bytes, %.2f%% of the span"
          % (" + ".join("0x%06X (%d)" % kv for kv in sorted(left.items())),
             sum(left.values()), 100.0 * sum(left.values()) / (HI - LO)))


# ================================================== 2. the kind disagreements
def kinds():
    print("=" * 78)
    print("THE FOUR KIND DISAGREEMENTS, ADJUDICATED AGAINST THE ROM")
    print("=" * 78)
    lay = {a: (k, n, w) for k, a, n, w in segs()}

    print("\n1) 0xF17C59-0xF17C8B   prose: bitmap   script: index_map")
    k, n, w = lay[0xF17C59]
    rec = 0xF1AAA9
    print("   script says: %s -- %s" % (k, w))
    print("   the record that names it, at 0x%06X: %s"
          % (rec, " ".join("%02X" % x for x in by(rec, 12))))
    print("   op %02X len %d, interpreter A: +2 long = 0x%06X, +6 IX = 0x%04X, "
          % (by(rec, 1)[0], by(rec + 1, 1)[0], w32(rec + 2), w16(rec + 6)))
    print("   +8 BC = %d, +0x0A HL = %d.  BC x HL = %d = the extent (%d)."
          % (w16(rec + 8), w16(rec + 10), w16(rec + 8) * w16(rec + 10), n))
    print("   swi-7 function 3 is `draw bitmap: BC = width in BYTES, HL = rows`")
    print("   (FINDINGS-ui-display-list.md).  3 bytes x 8 = 24 pixels wide, 17 rows.")
    print("   VERDICT: the PROSE is right.  It is a 24x17 monochrome bitmap;")
    print("            `index_map` is wrong -- nothing indexes it.")
    print("   the bitmap, rendered from the ROM:")
    for r in range(n // 3):
        row = by(0xF17C59 + 3 * r, 3)
        print("      %s" % "".join("#" if (c >> (7 - bit)) & 1 else "."
                                   for c in row for bit in range(8)))

    print("\n2) 0xF18066-0xF1814D   prose: display_list   script: record_array")
    print("3) 0xF185FD-0xF1881C   prose: display_list   script: record_array")
    print("   The test is whether ANYTHING walks them as a contiguous list.")
    for lo, hi in ((0xF18066, 0xF1814E), (0xF185FD, 0xF1881D)):
        n = sum(1 for st, en, t, p, ia in L.dl_sites()
                if en is not None and st < hi and en > lo)
        print("   0x%06X-0x%06X: display-list (start,end) call sites overlapping it: %d"
              % (lo, hi - 1, n))
    print("   Instead each record is fetched from a POINTER TABLE and run alone:")
    for base, src in ((0xF1B06B, 0xFBE69D), (0xF1B08B, None),
                      (0xF1B04B, 0xFBE61B), (0xF1B10B, 0xFBEB94),
                      (0xF1B0AB, 0xFBE7AE), (0xF1B12B, 0xFBEC0A)):
        e = [w32(base + 4 * i) for i in range(8)]
        d = {e[i + 1] - e[i] for i in range(7)}
        print("      0x%06X -> %s .. %s  8 entries, stride %s%s"
              % (base, "0x%06X" % e[0], "0x%06X" % e[-1], d,
                 "  (base from prom_a 0x%06X)" % src if src else ""))
    tc = table_consumers()
    print("   and each of those tables is CONSUMED by a one-record call, read off")
    print("   the proven prom_a text rather than assumed:")
    for base in (0xF1B06B, 0xF1B08B, 0xF1B04B, 0xF1B10B, 0xF1B0AB, 0xF1B12B):
        if base in tc:
            add, thunk, call = tc[base]
            print("      0x%06X : `add XBC,0x%06X` at prom_a 0x%06X, then `call "
                  "T_%06X` at 0x%06X" % (base, base, add, thunk, call))
        else:
            print("      0x%06X : NOT reached by the `add`+call scanner -- read by"
                  % base)
            print("                 hand instead: prom_a 0x%s"
                  % ("FBE61B `add XBC,0x00F1B04B`, then the unconditional "
                     "`jrl` at\n                 0xFBE625 to 0xFBE6B9 "
                     "`call 0xF42E0C` (bytes 1D 0C 2E F4)"
                     if base == 0xF1B04B else
                     "FBE6AA `lda XBC,0x00F1B08B` + `add XBC,(XIZ+..)`,\n"
                     "                 then the same 0xFBE6B9 `call 0xF42E0C`"))
    print("   VERDICT: the SCRIPT is right -- `record_array`, not `display_list`.")
    print("   ⚠ BUT the script's evidence line for 0xF185FD names ONE pointer table")
    print("     where FOUR are needed.  32 records = four arrays of eight:")
    for base in (0xF1B04B, 0xF1B10B, 0xF1B0AB, 0xF1B12B):
        e = [w32(base + 4 * i) for i in range(8)]
        print("      0x%06X-0x%06X  8 x 17 bytes, from the table at 0x%06X"
              % (e[0], e[-1] + 17 - 1, base))
    print("     so 0xF185FD-0xF1881C must be SPLIT at 0xF18685, 0xF1870D, 0xF18795.")

    print("\n4) 0xF1A62F-0xF1A7AE   prose: ascii   script: index_map")
    k, n, w = lay[0xF1A62F]
    rec = 0xF1A53F
    print("   the record that names it, at 0x%06X: %s"
          % (rec, " ".join("%02X" % x for x in by(rec, 15))))
    print("   interpreter B op %02X: +2 var 0x%04X, +4 mask 0x%02X, +5 shift %d,"
          % (by(rec, 1)[0], w16(rec + 2), by(rec + 4, 1)[0], by(rec + 5, 1)[0]))
    print("   +6 swi-7 function 0x%02X, +7 table 0x%06X, +0x0B width %d"
          % (by(rec + 6, 1)[0], w32(rec + 7), w16(rec + 0x0B)))
    print("   function 0x06 is `draw characters: XIY = character table, HL = index,")
    print("   BC = count` -- so the object is a CHARACTER TABLE that is DRAWN,")
    print("   not an index anything is looked up in.  mask 0x%02X = %d indices;"
          % (by(rec + 4, 1)[0], by(rec + 4, 1)[0] + 1))
    print("   %d x %d = %d = the extent (%d).  Two numbers, same answer."
          % (by(rec + 4, 1)[0] + 1, w16(rec + 0x0B),
             (by(rec + 4, 1)[0] + 1) * w16(rec + 0x0B), n))
    pure = sum(1 for i in range(128)
               if all(32 <= c < 127 for c in by(0xF1A62F + 3 * i, 3)))
    high = sum(1 for i in range(128)
               if any(c >= 0x80 for c in by(0xF1A62F + 3 * i, 3)))
    print("   entries that are pure printable ASCII: %d of 128; entries containing"
          % pure)
    print("   a byte >= 0x80: %d of 128.  So `ascii` is wrong on %d entries."
          % (high, high))
    print("   VERDICT: NEITHER label is right.  It is a 128-entry MIDI NOTE-NAME")
    print("            table, 3 characters per entry, indexed by note number:")
    gl = {0x88: "b", 0x8C: "#", 0xB0: "-1", 0xBC: "-2"}
    for i in range(0, 128, 12):
        cells = []
        for j in range(min(12, 128 - i)):
            e = by(0xF1A62F + 3 * (i + j), 3)
            cells.append("".join(gl.get(c, chr(c) if 32 <= c < 127 else "?")
                                 for c in e))
        print("      [%3d] %s" % (i, " ".join("%-4s" % c for c in cells)))
    print("   0x88 = the flat glyph, 0x8C = the sharp glyph, 0xB0 and 0xBC are the")
    print("   composite octave cells `-1` and `-2` (they take one cell so the")
    print("   accidental fits).  Note 0 = C-2, note 127 = G8: the standard MIDI")
    print("   note-name table.  ⚠ the glyph MEANINGS are read off this ordering,")
    print("   not off the font -- what the font draws at 0x88/0x8C is not checked")
    print("   here.")


# ============================================================= 3. the counts
def counts():
    print("=" * 78)
    print("EVERY COUNT THE DOSSIER GOT WRONG, RE-DERIVED")
    print("=" * 78)
    S = segs()
    kind = collections.Counter()
    byt = collections.Counter()
    for k, a, n, w in S:
        kind[k] += 1
        byt[k] += n
    print("\nsegments by kind (the layout tiles %d of %d bytes):"
          % (sum(byt.values()), HI - LO))
    for k in sorted(kind):
        print("   %-14s %4d segments %6d bytes" % (k, kind[k], byt[k]))
    print("   dossier said `70 record segments (484 bytes)` -> %d segments, %d bytes"
          % (kind["record"], byt["record"]))
    print("   dossier said `24 pointer tables (1,756 bytes)` -> %d tables, %d bytes"
          % (kind["pointer_table"], byt["pointer_table"]))

    runs = [(a, n) for k, a, n, _w in S if k in ("display_list", "record_array")]
    tot = sum(len(frames(a, a + n) or []) for a, n in runs)
    print("\nrecord runs and arrays in the span: %d, holding %d records"
          % (len(runs), tot))
    print("   dossier said `231 record-runs/arrays ... (7,900 + 776 bytes)`;")
    print("   the byte totals are right (%d + %d) and the object count is not."
          % (byt["display_list"], byt["record_array"]))
    for lo, hi, quoted in ((0xF18A1D, 0xF19238, 231), (0xF19ABF, 0xF1A18D, 231),
                           (0xF17C8C, 0xF18066, 133)):
        nseg = nrec = 0
        for k, a, n, _w in S:
            if lo <= a < hi and k in ("display_list", "record_array"):
                nseg += 1
                nrec += len(frames(a, a + n) or [])
        print("   0x%06X-0x%06X  dossier %3d  ->  %d segments, %d records"
              % (lo, hi - 1, quoted, nseg, nrec))

    print("\nthe 0xF19481-0xF19744 group -- dossier said `seven 2-record lists`:")
    g = [(k, a, n) for k, a, n, _w in S if 0xF19481 <= a < 0xF19745]
    dl = [(a, n) for k, a, n in g if k == "display_list"]
    im = [(a, n) for k, a, n in g if k != "display_list"]
    print("   %d display_list runs, each of %s records; %d tables of %s entries"
          % (len(dl), {len(frames(a, a + n) or []) for a, n in dl}, len(im),
             [n // 8 for a, n in im]))

    print("\nthe 0xF17C00-0xF17C58 group -- dossier said `5 one-record lists`:")
    for k, a, n, _w in S:
        if 0xF17C00 <= a < 0xF17C59:
            print("   0x%06X %3d bytes  %d records"
                  % (a, n, len(frames(a, a + n) or [])))

    sites = L.dl_sites()
    print("\ndisplay-list call sites naming this span: %d -- dossier said `121 call"
          % len(sites))
    print("   sites in prom_a`; it is %d in prom_a and %d in prom_b (0x%06X)."
          % (sum(1 for s in sites if s[3] == "a"),
             sum(1 for s in sites if s[3] == "b"),
             [s[4] for s in sites if s[3] == "b"][0]))
    print("   of the %d, %d name a literal `call T_F42Exx` and %d reach the"
          % (len(sites), sum(1 for s in sites if s[2]),
             sum(1 for s in sites if not s[2])))
    print("   interpreter through `jp (XIX)`.")

    print("\nthe --null-frame corpus -- dossier said `248,097 aligned chunks`:")
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        L.null_frame()
    for line in buf.getvalue().splitlines():
        if "chunks offered" in line or "accepted as a record run" in line \
                or "corpus objects" in line:
            print("  %s" % line.strip())
    print("   (248,097 is printed by no mode; it survives only in a stale docstring)")

    print("\nthe call-shape runs -- dossier said the briefing claims `THIRTY-SIX of")
    print("   those 41 runs are inside this span`:")
    brief = os.path.join(ROOT, "notes", "WAVE7-BRIEFING.md")
    txt = open(brief).read().lower() if os.path.exists(brief) else ""
    print("   occurrences of 'thirty' in WAVE7-BRIEFING.md: %d" % txt.count("thirty"))
    print("   occurrences of 'call shape'/'shapes' in it:   %d" % txt.count("shape"))
    buf = io.StringIO()
    sh = os.path.join(ROOT, "notes", "prom_b_dl_call_shapes.py")
    import subprocess
    out = subprocess.run([sys.executable, sh, "--new"], capture_output=True,
                         text=True, cwd=ROOT).stdout
    head = out.splitlines()[0]
    inspan = [l for l in out.splitlines()[1:]
              if l.strip() and LO <= int(l.split()[0].split("-")[0], 16) < HI]
    print("   %s" % head)
    print("   of those, starting inside 0x%06X-0x%06X: %d runs, %d bytes"
          % (LO, HI, len(inspan), sum(int(l.split()[-1]) for l in inspan)))

    print("\nthe `.incbin` header in prom_b/wsa1_prom_b.s -- `a 24-entry array of")
    print("   pointers spaced 0x48` at 0xF17A6C:")
    ent = []
    i = 0
    while True:
        v = w32(0xF17A6C + 4 * i)
        if not (B_BASE <= v < 0xF40000):
            break
        ent.append(v)
        i += 1
    d = {ent[i + 1] - ent[i] for i in range(len(ent) - 1)}
    print("   %d entries, stride %s, first target 0x%06X, table ends 0x%06X"
          % (len(ent), d, ent[0], 0xF17A6C + 4 * len(ent)))
    print("   the STRIDE is right (0x48 = 72); the COUNT is %d, not 24." % len(ent))

    print("\nData_F0EEE0 in prom_b/wsa1_prom_b.s -- the block header sizes it 287:")
    n = 0
    while by(0xF0EEE0 + n, 1) == by(0xF31EE1 + n, 1):
        n += 1
    print("   it matches the live glyph module at 0xF31EE1 for %d bytes = %d whole"
          % (n, n // 72))
    print("   72-byte glyphs + %d, so the block is ONE byte short of four glyphs."
          % (n % 72))


# ========================================================= 4. the two nulls
def calibrate():
    print("=" * 78)
    print("THE TWO NULLS -- what each instrument gets WRONG when the answer is known")
    print("=" * 78)
    a, b = DL.load()
    sites = DL.call_sites(a, b)
    own, _ok, _bad = LA.per_site(b, sites)
    rows = []
    for p, (which, op, ln) in own.items():
        k = ("A" if which == {DL.RUN_A} else "B" if which == {DL.RUN_B} else "both")
        rows.append((p, op, ln, k))
    rows.sort()
    print("\n1) THE LENGTH RULE, on %d records whose interpreter is known from a"
          % len(rows))
    print("   literal `call T_F417F0 / T_F417F4` call site.")
    print("   rule: EXACT under one interpreter and not EXACT under the other wins.")
    tally = collections.Counter()
    wrong = []
    for p, op, ln, k in rows:
        fa, fb = fit(op, ln, "A"), fit(op, ln, "B")
        if fa == "EXACT" and fb != "EXACT":
            v = "A"
        elif fb == "EXACT" and fa != "EXACT":
            v = "B"
        elif fa in ("EXACT", "VAC") and fb in ("EXACT", "VAC"):
            v = "AMBIG"
        else:
            v = "A" if fa != "NO" else "B" if fb != "NO" else "NONE"
        tally[(k, v)] += 1
        if v in "AB" and v != k:
            wrong.append((p, op, ln, fa, fb, k, v))
    for kk in sorted(tally):
        print("      truth %-4s rule says %-5s  %5d" % (kk[0], kk[1], tally[kk]))
    print("   MISCLASSIFIED: %d of %d (%.2f%%)"
          % (len(wrong), len(rows), 100.0 * len(wrong) / len(rows)))
    c = collections.Counter((w[1], w[2]) for w in wrong)
    for (op, ln), n in sorted(c.items()):
        print("      op %02X len %2d  x%d   (truth A, but EXACT under B)"
              % (op, ln, n))
    print("   ⚠ `op 07 len 17` is among them, and `op 07 len 17` is exactly the")
    print("     shape of 0xF1814E and 0xF181D6.")
    print("   ⚠ AND READ THE DIRECTION: all %d errors are the same way round -- an"
          % len(wrong))
    print("     interpreter-A record read as B (truth A -> rule B: %d; truth B ->"
          % tally[("A", "B")])
    print("     rule A: %d).  So this rule is BIASED TOWARD B, and B is what it"
          % tally[("B", "A")])
    print("     would have said about 0xF1814E and 0xF181D6.  It would have been")
    print("     RIGHT BY LUCK, on the one record shape where it is measurably")
    print("     unreliable.  That is why the verdict rests on prom_a 0xFBE2EC and")
    print("     not on this.")
    print("   first and last misclassified record: 0x%06X and 0x%06X"
          % (wrong[0][0], wrong[-1][0]))

    print("\n2) XIX RESOLUTION, on every prom_a `jp (XIX)` that reaches a")
    print("   display-list stack-pair thunk.")
    X = xix_sites()
    dec = [x for x in X if x[6] in ("A", "B")]
    agree = [x for x in dec if x[6] == ("A" if x[3] == RUN_A else "B")]
    print("   prom_a `jp (XIX)` instructions in total:        %d" % xix_jp_total())
    print("   of them, XIX resolves to T_F42E00 / T_F42E04:  %d" % len(X))
    print("   of THOSE, the length rule is decisive on:       %d" % len(dec))
    print("   agree: %d      DISAGREE: %d" % (len(agree), len(dec) - len(agree)))
    print("   the %d where the length rule is AMBIG are the ones only this"
          % sum(1 for x in X if x[6] == "AMBIG"))
    print("   instrument can call: %s"
          % " ".join("0x%06X" % x[1] for x in X if x[6] == "AMBIG"))
    ground = [x for x in X
              if any(st == x[1] and en == x[2] and t
                     for st, en, t, _p, _a in L.dl_sites())]
    print("   independently, %d of the %d runs are ALSO named by a literal `call`"
          % (len(ground), len(X)))
    for x in ground:
        lit = [(t, ia) for st, en, t, _p, ia in L.dl_sites()
               if st == x[1] and en == x[2] and t]
        print("      jp at prom_a 0x%06X : 0x%06X-0x%06X  XIX->T_%06X ; the same "
              "run has a" % (x[0], x[1], x[2], x[3]))
        print("        literal `call T_%06X` at prom_a 0x%06X -- the two agree"
              % (lit[0][0], lit[0][1]))


def xix():
    print("=" * 78)
    print("EVERY prom_a `jp (XIX)` DISPLAY-LIST SITE, RESOLVED")
    print("=" * 78)
    for addr, s, e, v, src, r, lr in xix_sites():
        tag = ""
        if lr in ("A", "B") and lr != ("A" if v == RUN_A else "B"):
            tag = "  <-- DISAGREE"
        print("  prom_a 0x%06X  0x%06X-0x%06X %3d recs  XIX=T_%06X (%s) set at "
              "0x%06X  lengthrule=%-6s%s"
              % (addr, s or 0, e or 0, len(r), v, "A" if v == RUN_A else "B",
                 src or 0, lr, tag))


# ============================================================= 5. the verdict
def verdict():
    print("=" * 78)
    print("VERDICT")
    print("=" * 78)
    print("""
SAFE TO CONVERT: yes, with the EIGHT corrections below applied to
notes/prom_b_f17559_layout.py first (C1-C6 answer the skeptic, C7-C8 are new).

The TILING is not in dispute and was re-run for this audit:
`python3 notes/prom_b_f17559_layout.py` exits 0 having assigned 16,039 of 16,039
bytes across 297 segments with 28 bytes unassigned (two runs, `--residue`), and
`--selftest` prints FAILURES: 0.  Every extent the skeptic re-measured matched.
What was wrong was the LABELLING -- and labels are exactly what a conversion
writes into the .s file, where the byte gate is blind to them forever.

  C1  0xF1A037-0xF1A0BE is ONE `record_array`, 8 records x 17 bytes,
      interpreter B, each run by T_F42E0C from the loop at prom_a 0xFBF79C.
      DELETE the boundary at 0xF1A048: it is the loop's stride operand
      (`lda XIX,0xF1A048 / sub XIX,XWA`), not an object.
  C2  0xF1814E-0xF181D5 and 0xF181D6-0xF1825D are interpreter B, pinned by
      `lda XIX,0x00F42E04` at prom_a 0xFBE2EC.  Not AMBIG.
  C3  0xF17C00-0xF17C07 is an interpreter-A op-0E record, byte-identical to the
      proven one-record list at 0xF18CD5 -- but NOTHING executes it.  Emit it
      with `UNREACHED` in the header, or as `.byte` with the gap stated.  Do NOT
      write `interpreter AMBIG; both ends are E0 references`: its low end is an
      E6 CONTENT boundary (the end of the 4-glyph copy), not an E0 reference.
  C4  0xF1A14D-0xF1A157 is a well-formed interpreter-B op-08 record and NOTHING
      executes it either -- its only reference is as the END address of the run
      at 0xF1A137.  Same treatment as C3.  This is the one the wave brief asked
      to be left honestly unresolved, and it is.
  C5  0xF17C59-0xF17C8B is a BITMAP, 24 px x 17 rows, sized by BC x HL of the
      op-03 record at 0xF1AAA9.  `index_map` is wrong.
  C6  0xF1A62F-0xF1A7AE is a 128-entry x 3-character MIDI NOTE-NAME table drawn
      by swi-7 function 6.  Neither `ascii` (53 of 128 entries carry a byte
      >= 0x80) nor `index_map` (nothing indexes it; it is drawn) is right.

Two more that the skeptic did not raise and that also reach the .s file:
  C7  0xF185FD-0xF1881C is FOUR arrays of eight 17-byte records, not one array
      of 32: the pointer tables are 0xF1B04B, 0xF1B10B, 0xF1B0AB, 0xF1B12B.
      Split at 0xF18685, 0xF1870D, 0xF18795.
  C8  the `.incbin` block header already in prom_b/wsa1_prom_b.s says 0xF17A6C
      holds `a 24-entry array of pointers spaced 0x48`.  It holds 29.  That
      header is committed text and this lane is read-only on the .s.

WHAT MUST NOT BE CLAIMED
  * that 0xF17C00 or 0xF1A14D is drawn by the machine.  Neither is reached by
    any of the four call shapes the census knows, and "unreached" is a statement
    about the census.
  * that the length rule resolved anything.  It misclassifies 23 of 4,097
    known records, including six of the exact shape of C2's runs.
  * a record count for this span that is not 711, or a run count that is not
    121 -- both printed by --counts.
""")


# ============================================================== 6. self-tests
def selftest():
    print("prom_b_f17559_reaudit.py --selftest")
    S = segs()
    lay = {a: (k, n, w) for k, a, n, w in S}

    amb = sorted(a for k, a, n, w in S if "AMBIG" in w)
    check("the layout still labels exactly six segments AMBIG", len(amb), 6)
    check("  and they are the six this script adjudicates", amb, AMBIG)
    check("  FIRST of them frames as 1 record",
          len(frames(0xF17C00, 0xF17C08)), 1)
    check("  LAST of them frames as 1 record",
          len(frames(0xF1A14D, 0xF1A158)), 1)

    X = xix_sites()
    check("prom_a `jp (XIX)` instructions", xix_jp_total(), 253)
    check("  of them, XIX resolves to a display-list pair thunk", len(X), 39)
    dec = [x for x in X if x[6] in ("A", "B")]
    ag = [x for x in dec if x[6] == ("A" if x[3] == RUN_A else "B")]
    check("  length rule decisive on", len(dec), 36)
    check("  XIX resolution vs length rule: agree", len(ag), 36)
    check("  XIX resolution vs length rule: DISAGREE", len(dec) - len(ag), 0)
    first, last = min(X, key=lambda x: x[0]), max(X, key=lambda x: x[0])
    check("  FIRST resolved site 0x%06X" % first[0],
          (hex(first[1]), hex(first[3])), ("0xfa3230", "0xf42e04"))
    check("  LAST resolved site 0x%06X" % last[0],
          (hex(last[1]), hex(last[3])), ("0xf18be8", "0xf42e00"))
    for want in (0xF1814E, 0xF181D6):
        s = [x for x in X if x[1] == want][0]
        check("  0x%06X resolves to T_F42E04 via prom_a 0x%06X" % (want, s[4]),
              (s[3], s[4], s[6]), (RUN_B, 0xFBE2EC, "AMBIG"))
    g = [x for x in X
         if any(st == x[1] and en == x[2] and t for st, en, t, _p, _a in L.dl_sites())]
    check("  runs named BOTH by jp (XIX) and by a literal call", len(g), 2)
    check("    and the two instruments agree on all of them",
          all(x[3] == [t for st, en, t, _p, _a in L.dl_sites()
                       if st == x[1] and en == x[2] and t][0] for x in g), True)

    sl = stride_loops()
    check("stride loops in prom_a", len(sl), 1)
    a0, base, second, stride, cnt, cntsrc, thunk, call = sl[0]
    check("  base / second / stride", (hex(base), hex(second), stride),
          ("0xf1a037", "0xf1a048", 17))
    check("  count and its source", (cnt, hex(cntsrc)), (8, "0xfbf7c3"))
    check("  thunk and call site", (hex(thunk), hex(call)), ("0xf42e0c", "0xfbf7ea"))
    check("  base + 8 x 17 lands on the next segment",
          hex(base + cnt * stride), "0xf1a0bf")
    recs = frames(base, base + cnt * stride)
    check("  the array holds 8 records", len(recs), 8)
    check("  FIRST record op/len", (recs[0][1], recs[0][2]), (7, 17))
    check("  LAST record op/len/address",
          (recs[-1][1], recs[-1][2], hex(recs[-1][0])), (7, 17, "0xf1a0ae"))
    check("  LAST record ends exactly on the boundary",
          hex(recs[-1][0] + recs[-1][2]), "0xf1a0bf")
    nxt = [s for s in L.dl_sites() if s[0] == 0xF1A0BF and s[2]]
    check("  and 0xF1A0BF starts a run with a literal call to T_F42E04",
          nxt[0][2] if nxt else None, RUN_B)
    r48 = [h for h in refs24(0xF1A048) if h[2] == 0xF2]
    check("  0xF1A048 is named exactly ONCE in prom_a/b/c", len(r48), 1)
    check("    and that once is the stride loop's own subtrahend load",
          hex(r48[0][1]), "0xfbf7d1")
    r37 = [h for h in refs24(0xF1A037) if h[2] == 0xF2]
    check("  0xF1A037 is named 3 times: the run END, and the loop's two loads",
          [hex(h[1]) for h in r37], ["0xfbf72c", "0xfbf7b3", "0xfbf7c9"])

    pat = by(0xF17C00, 8)
    hits = []
    i = -1
    while True:
        i = rom("b").find(pat, i + 1)
        if i < 0:
            break
        hits.append(B_BASE + i)
    check("0xF17C00's 8 bytes occur in prom_b", len(hits), 2)
    check("  the other occurrence", [hex(h) for h in hits], ["0xf17c00", "0xf18cd5"])
    tw = [s for s in L.dl_sites() if s[0] == 0xF18CD5 and s[2]]
    check("  the twin is a one-record list called with a literal T_F42E00",
          (tw[0][2], hex(tw[0][4])) if tw else None, (RUN_A, "0xfbd235"))
    check("  0xF17C00 `lda Rr,` references anywhere in prom_a/b/c",
          len([h for h in refs24(0xF17C00) if h[2] == 0xF2]), 0)
    p32 = ptrs32(0xF17C00)
    check("  32-bit words equal to 0x00F17C00", [(k, hex(x)) for k, x in p32],
          [("b", "0xf17a7c")])
    check("  which is entry [4] of the table at 0xF17A6C",
          (p32[0][1] - 0xF17A6C) // 4, 4)
    check("  and 0xF17A6C itself has no reference of either kind",
          (len(ptrs32(0xF17A6C)),
           len([h for h in refs24(0xF17A6C) if h[2] == 0xF2])), (0, 0))
    check("  0 of 8 bytes at 0xF17C00 match the live 5th glyph at 0xF32001",
          sum(1 for i in range(8) if by(0xF17C00 + i, 1) == by(0xF32001 + i, 1)), 0)
    ev = L.anchors()[0xF17C00]
    check("  0xF17C00's LOW anchor is E6 content, not an E0 reference",
          (any(x.startswith("E6") for x in ev),
           any(x.startswith("E0") for x in ev)), (True, False))
    check("    (so the layout's `both ends are E0 references` is false for it)",
          [x[:2] for x in ev], ["E6"])

    r = frames(0xF1A14D, 0xF1A158)
    check("0xF1A14D is one op-08 len-11 record", (r[0][1], r[0][2]), (8, 11))
    check("  fit under A / under B",
          (fit(8, 11, "A"), fit(8, 11, "B")), ("VAC", "EXACT"))
    check("  `lda Rr,0xF1A14D` references", len([h for h in refs24(0xF1A14D)
                                                 if h[2] == 0xF2]), 1)
    check("  and the only one is an END address, not a start",
          [(hex(st), hex(en)) for st, en, t, _p, _a in L.dl_sites()
           if en == 0xF1A14D], [("0xf1a137", "0xf1a14d")])
    check("  no call site STARTS at 0xF1A14D",
          [s for s in L.dl_sites() if s[0] == 0xF1A14D], [])
    # the wave's off-by-one guard: a cited call site must BE an opcode
    r1 = [h for h in refs24(0xF1A14D) if h[2] == 0xF2][0]
    check("  it is cited at the `lda` OPCODE, not at its operand",
          (hex(r1[1]), hex(by(r1[1], 1, "a")[0])), ("0xfbf895", "0xf2"))
    check("  every 0xF2-flagged citation this script makes lands on an 0xF2 byte",
          all(by(h[1], 1, {"a": "a", "b": "b", "c": "c"}[h[0]])[0] == 0xF2
              for t in (0xF17C00, 0xF1814E, 0xF181D6, 0xF1A037, 0xF1A048,
                        0xF1A14D, 0xF1A158, 0xF1A0BF, 0xF1A137)
              for h in refs24(t) if h[2] == 0xF2), True)
    fam = (0xF1A137, 0xF1A14D, 0xF1A163)
    diff = [i for i in range(11) if len({by(p + i, 1)[0] for p in fam}) > 1]
    check("  the three op-08 records differ in 4 of 11 bytes", diff, [2, 3, 4, 7])
    check("  its +7 pointer is also 0xF1A158's", (hex(w32(0xF1A14D + 7)),
          hex(w32(0xF1A158 + 7))), ("0xf1a1d5", "0xf1a1d5"))
    check("bytes left reached by nothing (0xF17C00 + 0xF1A14D)", 8 + 11, 19)
    check("  which is 0.12% of the span",
          round(100.0 * 19 / (HI - LO), 2), 0.12)

    # the length-rule null
    a, b = DL.load()
    own, _ok, _bad = LA.per_site(b, DL.call_sites(a, b))
    n = w = 0
    shapes = collections.Counter()
    for p, (which, op, ln) in own.items():
        k = "A" if which == {DL.RUN_A} else "B" if which == {DL.RUN_B} else "both"
        fa, fb = fit(op, ln, "A"), fit(op, ln, "B")
        v = ("A" if fa == "EXACT" and fb != "EXACT" else
             "B" if fb == "EXACT" and fa != "EXACT" else None)
        n += 1
        if v and v != k:
            w += 1
            shapes[(op, ln)] += 1
    check("length-rule null: ground-truth records", n, 4097)
    check("  misclassified by the length rule", w, 23)
    check("  and 6 of them are `op 07 len 17`", shapes[(7, 17)], 6)

    # kinds
    rec = 0xF1AAA9
    check("0xF1AAA9 is op 03 len 12 -> 0xF17C59, BC x HL",
          (by(rec, 1)[0], by(rec + 1, 1)[0], hex(w32(rec + 2)),
           w16(rec + 8) * w16(rec + 10)), (3, 12, "0xf17c59", 51))
    check("  and 51 is the extent of the segment at 0xF17C59", lay[0xF17C59][1], 51)
    rec = 0xF1A53F
    check("0xF1A53F: mask x width = extent",
          ((by(rec + 4, 1)[0] + 1) * w16(rec + 0x0B), lay[0xF1A62F][1]), (384, 384))
    check("  swi-7 function it issues", by(rec + 6, 1)[0], 6)
    check("  entries with a byte >= 0x80",
          sum(1 for i in range(128)
              if any(c >= 0x80 for c in by(0xF1A62F + 3 * i, 3))), 53)
    check("  entry [0] and entry [127]",
          (bytes(by(0xF1A62F, 3)), bytes(by(0xF1A62F + 3 * 127, 3))),
          (b"C-2", b"G 8"))
    tc = table_consumers()
    check("record tables the `add`+one-record-call scanner reaches",
          sorted((hex(b), hex(tc[b][1])) for b in
                 (0xF1B04B, 0xF1B06B, 0xF1B08B, 0xF1B0AB, 0xF1B10B, 0xF1B12B)
                 if b in tc),
          [("0xf1b06b", "0xf42e0c"), ("0xf1b0ab", "0xf42e0c"),
           ("0xf1b10b", "0xf42e0c"), ("0xf1b12b", "0xf42e0c")])
    # the two the scanner cannot reach, checked at BYTE level instead
    disp = int.from_bytes(by(0xFBE626, 2, "a"), "little", signed=True)
    check("  0xF1B04B: prom_a 0xFBE625 is an unconditional jrl to",
          (hex(by(0xFBE625, 1, "a")[0]), hex(0xFBE625 + 3 + disp)),
          ("0x78", "0xfbe6b9"))
    check("    and prom_a 0xFBE6B9 is `call 0xF42E0C` (1D 0C 2E F4)",
          bytes(by(0xFBE6B9, 4, "a")).hex(), "1d0c2ef4")
    check("  0xF1B08B: prom_a 0xFBE6AA is `lda XBC,0x00F1B08B` (F2 8B B0 F1 31)",
          bytes(by(0xFBE6AA, 5, "a")).hex(), "f28bb0f131")
    check("    and its call is the same 0xFBE6B9", hex(0xFBE6B9), "0xfbe6b9")
    tabs4 = (0xF1B04B, 0xF1B10B, 0xF1B0AB, 0xF1B12B)
    check("the four pointer tables of 0xF185FD-0xF1881C",
          [hex(w32(t)) for t in tabs4],
          ["0xf185fd", "0xf18685", "0xf1870d", "0xf18795"])
    check("  the LAST entry of the LAST of them", hex(w32(tabs4[-1] + 4 * 7)),
          "0xf1880c")

    # counts
    kind = collections.Counter()
    byt = collections.Counter()
    for k, a, n2, w2 in S:
        kind[k] += 1
        byt[k] += n2
    check("record segments / bytes", (kind["record"], byt["record"]), (71, 484))
    check("pointer tables / bytes",
          (kind["pointer_table"], byt["pointer_table"]), (33, 1756))
    runs = [(a, n2) for k, a, n2, _w in S if k in ("display_list", "record_array")]
    check("record runs and arrays / records", (len(runs),
          sum(len(frames(a, a + n2) or []) for a, n2 in runs)), (121, 711))
    for lo, hi, want in ((0xF18A1D, 0xF19238, 171), (0xF19ABF, 0xF1A18D, 175),
                         (0xF17C8C, 0xF18066, 101)):
        got = sum(len(frames(a, a + n2) or []) for k, a, n2, _w in S
                  if lo <= a < hi and k in ("display_list", "record_array"))
        check("  records in 0x%06X-0x%06X" % (lo, hi - 1), got, want)
    dl = [(a, n2) for k, a, n2, _w in S
          if k == "display_list" and 0xF19481 <= a < 0xF19745]
    check("0xF19481-0xF19744: display-list runs", len(dl), 6)
    check("  each of 2 records", {len(frames(a, a + n2)) for a, n2 in dl}, {2})
    check("  their arrays' entry counts",
          [n2 // 8 for k, a, n2, _w in S
           if k != "display_list" and 0xF19481 <= a < 0xF19745],
          [16, 16, 8, 8, 16, 8])
    check("0xF17C00-0xF17C58: records per segment",
          [len(frames(a, a + n2) or []) for k, a, n2, _w in S
           if 0xF17C00 <= a < 0xF17C59], [1, 3, 3, 1, 1])
    sites = L.dl_sites()
    check("call sites naming the span: total / prom_a / prom_b",
          (len(sites), sum(1 for s in sites if s[3] == "a"),
           sum(1 for s in sites if s[3] == "b")), (121, 120, 1))
    ent = []
    i = 0
    while B_BASE <= w32(0xF17A6C + 4 * i) < 0xF40000:
        ent.append(w32(0xF17A6C + 4 * i))
        i += 1
    check("0xF17A6C: entries / stride / first target",
          (len(ent), {ent[i + 1] - ent[i] for i in range(len(ent) - 1)},
           hex(ent[0])), (29, {72}, "0xf17ae0"))
    check("  and the table ends exactly where its first target begins",
          hex(0xF17A6C + 4 * len(ent)), hex(ent[0]))
    n = 0
    while by(0xF0EEE0 + n, 1) == by(0xF31EE1 + n, 1):
        n += 1
    check("Data_F0EEE0 matches the live glyph module for", n, 288)
    brief = open(os.path.join(ROOT, "notes", "WAVE7-BRIEFING.md")).read().lower()
    check("WAVE7-BRIEFING.md contains the word 'thirty'", brief.count("thirty"), 0)
    check("  and the word 'shape'", brief.count("shape"), 0)

    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    want = [a for a in sys.argv[1:] if a.startswith("--")]
    if not want:
        want = ["--ambig", "--kinds", "--counts", "--calibrate", "--verdict"]
    for w in want:
        {"--ambig": ambig, "--kinds": kinds, "--counts": counts,
         "--calibrate": calibrate, "--xix": xix, "--verdict": verdict}[w]()
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
