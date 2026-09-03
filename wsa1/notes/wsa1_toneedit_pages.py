#!/usr/bin/env python3
"""
QUESTION THIS ANSWERS
=====================
"Which EDITOR PAGE, and which FIELD of it, does each tone-edit parameter of the
0x00104000 (L7A1429) modelling LSI belong to?"

`notes/wsa1_toneedit_vocabulary.py` (wave 19) enumerated the SOUND EDIT
captions.  It could not say which caption goes with which parameter, because
the parameter number is a `pushw` immediate at a call site in the OTHER CPU's
image and there is no (screen, field) -> parameter table anywhere.  This script
crosses that gap, and it needs no table, because the firmware states the
correspondence twice over:

  (a) each MODELING page's ENTER routine in prom_a fires an ordered run of
      read-back requests, and its reply handler stores reply n at
      ((u8 *)0x27A6)[n] -- so the ORDER of the requests IS the map from
      parameter number to the RAM byte the page draws;
  (b) each page's per-field EDIT routine names an (index, parameter) pair
      directly, in two immediates a few bytes apart.

(b) is used here as a CONTROL on (a): eight independent editor bindings are
compared against the order-derived map, and all eight agree (section 6).

The RAM byte then names the field, because the display list that draws it
carries the screen position: interpreter A's fixed-pitch text opcodes and ALL of
interpreter B's value opcodes address the SED1330's display RAM directly, and
`notes/FINDINGS-display-controller.md` already establishes the geometry from
`LCD_Init_SED1330`'s own SYSTEM SET bytes -- 8 pixels per byte, C/R = 40 bytes
per line, 240 lines.  So

      pixel row = word / 40      pixel x = 8 * (word % 40)

turns every value record into a screen coordinate, and a caption at the same
pixel row (proportional text, opcode 0x17, carries x and y in pixels) names it.

RUN
===
    cd <tree>/wsa1
    python3 notes/wsa1_toneedit_pages.py             # sections 1-6
    python3 notes/wsa1_toneedit_pages.py --nulls     # nulls 1-3
    python3 notes/wsa1_toneedit_pages.py --selftest  # assertions; 0 = OK

WHAT IT READS
=============
original_ROMs/wsa1_prom_{a.ic12,b.ic13} only.  No .s file is an input, so
nothing below can be an artefact of a label someone typed.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
A_BASE, B_BASE = 0xF80000, 0xF00000
STRIDE = 40                      # bytes per display line -- SED1330 C/R+1
RUN_A, RUN_B = 0xF417F0, 0xF417F4
HTBL_A = 0x31D21                 # file offset, 36 entries
HTBL_B = 0x31DB1                 # file offset, 16 entries

# interpreter A: handler -> (text offset, position kind)
#   0xF31A3A  fixed-pitch text, +2..3 = a DISPLAY-RAM byte address, text at +4
#   0xF31A52  proportional text, +2..3 = x, +4..5 = y, both in PIXELS, text at +6
A_TEXT = {0xF31A3A: (4, "ram"), 0xF31A52: (6, "pix")}

# interpreter B record lengths, from FINDINGS-ui-display-list-interpreter-b.md
B_LEN = {0x00: 10, 0x06: 10, 0x01: 12, 0x02: 15, 0x03: 11, 0x08: 11,
         0x04: 11, 0x05: 11, 0x07: 17, 0x09: 12, 0x0A: 12, 0x0B: 13}
# where a B record keeps its display-RAM address
B_POS = {0x00: 7, 0x06: 7, 0x05: 7, 0x09: 9, 0x0A: 9, 0x0B: 9,
         0x02: 13, 0x07: 13}

DISPATCH_LO = 0xF5B9F8           # Dispatch_Code80's low table, 48 entries
DISPATCH_HI = 0xF5BA78           # its high table -- LO + 0x80
PAINT_LO = 0xF5B8F8              # Dispatch_Code80_Bracketed's, the FULL repaints

# the MODELING screens, by dispatch code.  The names are this note's, taken
# from the page titles the paint routines draw; the CODES are read from the
# tables above and asserted, not assumed.
SCREENS = {0xA0: "MODELING top", 0xA2: "DRIVER WAVEFORM",
           0xA3: "PAGE1/2 P0SITI0N PARAMETER", 0xA4: "PAGE2/2 P0SITI0N M0VEMENT",
           0xA5: "PAGE1/3 (FITTING MUTING KEY SHIFT DETUNE RESO SCALE)",
           0xA6: "PAGE2/3 TOUCH DEPTH", 0xA7: "PAGE3/3 (RESO MODE + MUTING KEY FOLLOW)"}


def rom(name):
    with open(os.path.join(ROOT, "original_ROMs", name), "rb") as f:
        return f.read()


class Img(object):
    def __init__(self, data, base):
        self.d, self.base = data, base

    def __getitem__(self, a):
        return self.d[a - self.base]

    def u16(self, a):
        return self[a] | self[a + 1] << 8

    def u32(self, a):
        return self.u16(a) | self.u16(a + 2) << 16

    def slice(self, a, n):
        return self.d[a - self.base:a - self.base + n]


def geom(word):
    """A display-RAM byte address -> (pixel row, pixel x).  STRIDE is the
    SED1330's C/R+1; see FINDINGS-display-controller.md."""
    return word // STRIDE, 8 * (word % STRIDE)


# ---------------------------------------------------------------- section 1
def dispatch_tables(b):
    lo = [b.u32(DISPATCH_LO + 4 * i) for i in range(48)]
    hi = [b.u32(DISPATCH_HI + 4 * i) for i in range(16)]
    paint = [b.u32(PAINT_LO + 4 * i) for i in range(48)]
    return lo, hi, paint


def cmd_section1(b):
    lo, hi, paint = dispatch_tables(b)
    print("=== 1. the screen dispatch, and why code 0xC0+k IS code 0xA0+k")
    print("    Dispatch_Code80 (0xF5B9B8): code >= 0xC0 indexes (0x%06X)[code-0xC0],"
          % DISPATCH_HI)
    print("    else (0x%06X)[code-0x80].  0x%06X = 0x%06X + 0x80, so the high table"
          % (DISPATCH_LO, DISPATCH_HI, DISPATCH_LO))
    print("    is the low table's entries 32..47 -- codes 0xA0..0xAF.  Checked entry")
    print("    for entry:")
    ok = all(hi[k] == lo[32 + k] for k in range(16))
    print("      0xC0+k == 0xA0+k for k = 0..15 : %s" % ("YES, all 16" if ok else "NO"))
    print()
    print("    code  full repaint      partial repaint   page")
    for c in sorted(SCREENS):
        print("    0x%02X  0x%06X          0x%06X          %s"
              % (c, paint[c - 0x80], lo[c - 0x80], SCREENS[c]))
    return lo, paint


# ---------------------------------------------------------------- section 2
def scan_lists(b, lo_a, hi_a):
    """Every `ld XIY,imm32 / ld XIX,imm32 / call 0xF417Fx` in [lo_a, hi_a),
    plus every `call imm24`, as raw byte patterns."""
    out_lists, out_calls = [], []
    o = lo_a
    while o < hi_a - 14:
        if (b[o] == 0x45 and b[o + 4] == 0x00 and b[o + 5] == 0x44
                and b[o + 9] == 0x00 and b[o + 10] == 0x1D):
            t = b[o + 11] | b[o + 12] << 8 | b[o + 13] << 16
            if t in (RUN_A, RUN_B):
                s = b[o + 1] | b[o + 2] << 8 | b[o + 3] << 16
                e = b[o + 6] | b[o + 7] << 8 | b[o + 8] << 16
                if e > s:
                    out_lists.append((o, s, e, "A" if t == RUN_A else "B"))
                    o += 14
                    continue
        if b[o] == 0x1D:
            out_calls.append((o, b[o + 1] | b[o + 2] << 8 | b[o + 3] << 16))
        o += 1
    return out_lists, out_calls


def page_lists(b, paint_entry, bounds):
    """The lists a paint routine runs, following one level of `call` into the
    helper routines that live in the same block."""
    hi = min([x for x in bounds if x > paint_entry] or [paint_entry + 0x200])
    lists, calls = scan_lists(b, paint_entry, hi)
    seen = set()
    for _o, t in calls:
        if t in bounds and t != paint_entry and t not in seen:
            seen.add(t)
            h2 = min([x for x in bounds if x > t] or [t + 0x200])
            l2, _c2 = scan_lists(b, t, h2)
            lists += l2
    return lists


# ---------------------------------------------------------------- section 3
def walk_A(b, s, e, hta):
    recs, p = [], s
    while p < e:
        op, ln = b[p], b[p + 1]
        if op >= 0x24 or ln < 2 or p + ln > e:
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


def walk_B(b, s, e):
    recs, p = [], s
    while p < e:
        op = b[p]
        ln = B_LEN.get(op)
        if ln is None or b[p + 1] != ln or p + ln > e:
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


def captions(b, s, e, hta):
    """[(pixel row, pixel x, text)] for the drawn text of one A list."""
    recs = walk_A(b, s, e, hta)
    out = []
    if recs is None:
        return out
    for p, op, ln in recs:
        h = hta[op]
        if h not in A_TEXT:
            continue
        txt, kind = A_TEXT[h]
        if ln <= txt:
            continue
        t = "".join(chr(c) if 0x20 <= c <= 0x7E else " " for c in b.slice(p + txt, ln - txt))
        if not t.strip():
            continue
        if kind == "pix":
            out.append((b.u16(p + 4), b.u16(p + 2), t.strip(), "pix"))
        else:
            r, x = geom(b.u16(p + 2))
            out.append((r, x, t.strip(), "ram"))
    return out


def values(b, s, e):
    """[(pixel row, pixel x, RAM address, mask, shift, table)] for one B list."""
    recs = walk_B(b, s, e)
    out = []
    if recs is None:
        return out
    for p, op, ln in recs:
        if op not in B_POS:
            continue
        ram, mask, sh = b.u16(p + 2), b[p + 4], b[p + 5] & 7
        tbl = None
        if op in (0x02, 0x07):
            ptr, w = b.u32(p + 7), b.u16(p + 11)
            n = (mask >> sh) + 1
            try:
                tbl = [bytes(b.slice(ptr + i * w, w)).decode("latin-1")
                       for i in range(min(n, 4))]
            except Exception:
                tbl = None
        r, x = geom(b.u16(p + B_POS[op]))
        out.append((r, x, ram, mask, sh, tbl))
    return out


# ---------------------------------------------------------------- section 5
# prom_a.  Three byte shapes, and nothing else is decoded:
#   0B ll hh                                     pushw imm16
#   1D t0 t1 t2                                  call imm24
#   9E FA 21 D9 12 29                            pushw the selector local
SELPUSH = bytes.fromhex("9efa21d91229")   # ld BC,(XIZ-6) / extz BC / pushw BC


def _is_send(a, o):
    """`call sub_FD61CF`, or the `lda XIY,<ret> / push XIY / jp (XIX)` trampoline
    the compiler emits when the callee address is already in XIX."""
    return a.slice(o, 4) == b"\x1d\xcf\x61\xfd" or a[o] == 0xF2


def query_runs(a, lo, hi):
    """Every `pushw <tag> / pushw <count> / pushw <param> / <sel> / <send>` in
    [lo,hi), in program order, as (addr, tag, count, param).  A `2b` (pushw HL)
    in the tag slot means the tag is held in a register."""
    out, o = [], lo
    while o < hi:
        if a.slice(o, len(SELPUSH)) == SELPUSH and _is_send(a, o + len(SELPUSH)):
            h = o - 9                          # 0B t 00  0B c 00  0B p 00
            if a[h] == 0x0B and a[h + 3] == 0x0B and a[h + 6] == 0x0B:
                out.append((h, a[h + 1], a[h + 4], a[h + 7]))
            elif a[o - 6] == 0x0B and a[o - 3] == 0x0B:
                out.append((o - 7, None, a[o - 5], a[o - 2]))
        o += 1
    return out


def loop_runs(a, lo, hi):
    """`ld HL,imm16 / ldb D,imm8` immediately before a query block whose param
    comes from HL -- the firmware's own `for (p = base; n--; p++)` run."""
    out, o = [], lo
    while o < hi - 6:
        if a[o] == 0x33 and a[o + 3] == 0x24:
            base, n = a[o + 1] | a[o + 2] << 8, a[o + 4]
            if 1 <= n <= 8 and base < 0x60:
                out.append((o, base, n))
        o += 1
    return out


PAGES = [
    # code, name, prom_a ENTER routine, the window its query run lives in,
    #             whether a sub_FD7719 call precedes the reply run (base index 1)
    (0xC3, "PAGE1/2", 0xFDD7F9, (0xFDD82D, 0xFDD870), 0),
    (0xC4, "PAGE2/2", 0xFDD958, (0xFDD987, 0xFDD9A0), 0),
    (0xC5, "PAGE1/3", 0xFDDA1C, (0xFDDA51, 0xFDDAE2), 1),
    (0xC6, "PAGE2/3", 0xFDDC3A, (0xFDDC71, 0xFDDCCA), 1),
    (0xC7, "PAGE3/3", 0xFDDDAA, (0xFDDDE2, 0xFDDE76), 1),
]

# the eight (RAM index, parameter) pairs each page's FIELD EDITOR names
# directly, as two immediates in the same basic block.  Address = the `cp
# (local),0` that opens the two-armed selection; the pairs are read from the
# arms by decode_editor().
EDITORS = [
    (0xC5, 0xFD4BA4, 0xFD4BD9),
    (0xC7, 0xFD5732, 0xFD5769),
    (0xC7, 0xFD5883, 0xFD58BC),
    (0xC7, 0xFD5A0E, 0xFD5A47),
]


def decode_editor(a, at):
    """The two (RAM index, parameter) pairs one editor's first arm names.

    The arm is a run of immediate loads ending at a `jr` (0x68).  Two of them
    are RAM indices -- the first `ldb E/H,imm8` (0x25/0x26) and the `ld
    (XIZ-7),imm8` spelled `BE F9 00 nn` -- and two are parameters, which are the
    immediates >= 0x11 among the `ldb D,imm8` (0x24) and `ld (XIZ-n),imm8` (BE)
    forms.  0x11 is the lowest wave-select parameter any MODELING page reads, so
    the split is a bound and not a guess."""
    w = a.slice(at, 40)
    idx, par, i = [], [], 0
    while i < len(w) - 3:
        if w[i] == 0x68:
            break
        if w[i] in (0x25, 0x26) and w[i + 1] < 0x11 and not idx:
            idx.append(w[i + 1])
            i += 2
            continue
        if w[i] == 0x24 and w[i + 1] >= 0x11:
            par.append(w[i + 1])
            i += 2
            continue
        if w[i] == 0xBE and w[i + 2] == 0x00:
            if w[i + 1] == 0xF9 and len(idx) < 2:
                idx.append(w[i + 3])
            elif w[i + 3] >= 0x11:
                par.append(w[i + 3])
            i += 4
            continue
        i += 1
    return idx[:2], par[:2]


def cmd_prom_a(a):
    print("=== 5. prom_a: the ordered read-back run of each page's ENTER routine")
    print("    Each request is `pushw <tag> / pushw <count> / pushw <param> /")
    print("    pushw <selector> / call sub_FD61CF`.  The reply handler stores reply")
    print("    n at ((u8*)0x27A6)[n], so request order IS the RAM index.")
    print()
    order = {}
    for code, name, enter, (lo, hi), base in PAGES:
        qs = query_runs(a, lo, hi)
        loops = loop_runs(a, lo, hi)
        params = []
        for _o, tag, cnt, par in qs:
            params.extend(range(par, par + max(cnt, 1)))
        for _o, bse, n in loops:
            params.extend(range(bse, bse + n))
        params = sorted(set(params), key=params.index)
        order[code] = {base + i: p for i, p in enumerate(params)}
        print("    %s  enter 0x%06X  base index %d" % (name, enter, base))
        print("        parameters, in request order: %s"
              % " ".join("0x%02X" % p for p in params))
        print("        -> 0x27A6[%s]" % ", ".join(
            "%d=p%d" % (k, v) for k, v in sorted(order[code].items())))
    return order


def cmd_editors(a, order):
    print()
    print("=== 6. THE CONTROL: the same map read off the FIELD EDITORS")
    print("    Each editor names an (index, parameter) pair in two immediates.")
    hits = tot = 0
    for code, fn, at in EDITORS:
        idx, par = decode_editor(a, at)
        pairs = list(zip(idx, par))
        for i, p in pairs:
            tot += 1
            want = order.get(code, {}).get(i)
            good = (want == p)
            hits += good
            print("    0x%02X editor 0x%06X: index %-2d <- p%-3d   order says p%-4s %s"
                  % (code, fn, i, p, want, "AGREE" if good else "DISAGREE"))
    print("    %d of %d agree." % (hits, tot))
    return hits, tot


# ---------------------------------------------------------------- section 7
def senders(a):
    """The tone-message BUILDERS, derived from the ROM: every `calr` (0x1E,
    3 bytes, PC-relative from the next instruction) whose target is
    sub_FD6132 -- the routine that posts a built message -- then the
    `link XIZ,imm16` (0xEE 0x0C) that opens the routine containing it."""
    POST = 0xFD6132
    out = []
    for o in range(A_BASE, A_BASE + len(a.d) - 3):
        if a[o] != 0x1E:
            continue
        d = a.u16(o + 1)
        if d >= 0x8000:
            d -= 0x10000
        if o + 3 + d != POST:
            continue
        k = o
        while k > A_BASE and not (a[k] == 0xEE and a[k + 1] == 0x0C):
            k -= 1
        if k not in out:
            out.append(k)
    return sorted(out)


def param_census(a, imm):
    """Every call site of every sender that carries `pushw <imm>` (0x0B lo hi)
    in the 30 bytes before the `call` (0x1D + 24-bit target)."""
    S = set(senders(a))
    pat = bytes([0x0B, imm, 0x00])
    hits, sites = [], 0
    for o in range(A_BASE, A_BASE + len(a.d) - 4):
        if a[o] != 0x1D:
            continue
        t = a[o + 1] | a[o + 2] << 8 | a[o + 3] << 16
        if t not in S:
            continue
        sites += 1
        if pat in a.slice(o - 30, 30):
            hits.append((o, t))
    return sites, hits


def cmd_senders(a):
    S = senders(a)
    print()
    print("=== 7. is p15 (wave-select byte +0x0F) an editor parameter AT ALL?")
    print("    prom_a's tone-message builders, derived from the ROM as the")
    print("    routines containing a `calr sub_FD6132`: %d of them," % len(S))
    print("    %s" % " ".join("0x%06X" % x for x in S))
    for imm, what in ((0x0F, "p15"), (0x0D, "p13 -- the positive control"),
                      (0x13, "p19 -- the positive control")):
        sites, hits = param_census(a, imm)
        print("    `pushw 0x%02X` within 30 bytes before a sender call (%s):"
              % (imm, what))
        print("        %d of %d call sites%s" % (len(hits), sites,
              ("  ->  " + " ".join("0x%06X" % h[0] for h in hits)) if hits else ""))
    print("    ⚠ NULL for the window: prom_a holds %d `0B xx 00` triples in all,"
          % sum(1 for o in range(A_BASE, A_BASE + len(a.d) - 3)
                if a[o] == 0x0B and a[o + 2] == 0x00))
    print("    so a 30-byte window catching one by chance is not rare; what makes")
    print("    the p15 count meaningful is that the SAME window catches p13 and")
    print("    p19 at the sites the pages use, and catches 0x0F exactly once --")
    print("    at 0xFD5F12, whose selector immediate is 0x00, i.e. arm 1, the")
    print("    300-byte part record and not the 43-byte wave-select record.")


# ---------------------------------------------------------------- nulls
def cmd_nulls(b):
    print("=== NULL 1 -- is the 40-byte stride FITTED, or is it the hardware's?")
    print("    PAGE1/3's ten value records must fall into TWO rows of FIVE whose")
    print("    column sets are identical.  Sweep every stride 4..256:")
    ws = [b.u16(p + B_POS[b[p]]) for p in page_value_records(b, 0xF034DE, 0xF0355D)]
    good = []
    for S in range(4, 257):
        d = {}
        for w in ws:
            d.setdefault(w // S, []).append(w % S)
        if len(d) == 2 and all(len(v) == 5 for v in d.values()):
            x, y = [sorted(v) for v in d.values()]
            if x == y:
                good.append(S)
    print("      strides that survive: %s" % good)
    print("      -- all four divide the row gap 1240, so the structure alone does")
    print("      NOT pick one.  What picks 40 is OUTSIDE this script: the SED1330")
    print("      SYSTEM SET bytes LCD_Init_SED1330 sends (C/R+1 = 40 bytes per line,")
    print("      FX+1 = 8 pixels per byte, L/F+1 = 240 lines), already documented in")
    print("      notes/FINDINGS-display-controller.md.  The other three imply a")
    print("      panel 992, 1240 or 1984 pixels wide; the widest pixel x any")
    print("      proportional-text record in this image carries is %d." % max_pix_x(b))
    print()
    print("=== NULL 2 -- does the MAIN/SUB row pairing survive a swap?")
    print("    The caption list 0xF02B47, drawn by the SAME paint routine, puts")
    print("    'MAIN'+'RESONATOR' and 'SUB'+'RESONATOR' at pixel rows:")
    caps = [c for c in captions(b, 0xF02B47, 0xF02D08, hta(b))
            if c[2] in ("MAIN", "SUB", "RESONATOR") and c[0] > 140]
    for r, x, t, k in caps:
        print("        y=%3d x=%3d %r" % (r, x, t))
    rows = sorted(set(w // STRIDE for w in ws))
    print("    the value rows are %s" % rows)
    m = min(c[0] for c in caps if c[2] == "MAIN")
    s = min(c[0] for c in caps if c[2] == "SUB")
    print("        MAIN label %d -> row %d : offset %+d" % (m, rows[0], rows[0] - m))
    print("        SUB  label %d -> row %d : offset %+d" % (s, rows[1], rows[1] - s))
    print("        swapped:  %+d and %+d -- unequal, and one is negative"
          % (rows[1] - m, rows[0] - s))
    print()
    print("=== NULL 3 -- how often does a caption share a row with a value by chance?")
    print("    PAGE1/2 has 5 value records; each must sit on the row of the caption")
    print("    that names it.  Measured, and against 100000 random word draws from")
    print("    the same address range:")
    import random
    vs = [b.u16(p + B_POS[b[p]]) for p in page_value_records(b, 0xF03441, 0xF03478)]
    cs = [c for c in captions(b, 0xF02671, 0xF027AF, hta(b)) if c[3] == "ram"]
    crows = set(c[0] for c in cs)
    hit = sum(1 for w in vs if w // STRIDE in crows)
    lo, hi = min(vs + [c[0] * STRIDE for c in cs]), max(vs) + 1
    random.seed(7)
    tot = 0
    for _ in range(100000):
        tot += sum(1 for _ in vs if random.randrange(lo, hi) // STRIDE in crows)
    print("      measured %d of %d on a caption row; random mean %.3f of %d"
          % (hit, len(vs), tot / 100000.0, len(vs)))


def page_value_records(b, s, e):
    return [p for p, op, ln in (walk_B(b, s, e) or []) if op in B_POS]


def hta(b):
    return [b.u32(B_BASE + HTBL_A + i * 4) for i in range(36)]


def max_pix_x(b):
    """The widest pixel x the MODELING block's proportional-text records carry."""
    best = 0
    for s, e in ((0xF01F96, 0xF02F22), (0xF03892, 0xF04560)):
        for r, x, t, k in captions(b, s, e, hta(b)):
            if k == "pix":
                best = max(best, x + 6 * len(t))
    return best


# ---------------------------------------------------------------- main
def cmd_pages(b, paint):
    print()
    print("=== 2/3. what each MODELING page DRAWS, in screen coordinates")
    bounds = set(paint) | {0xF5C144, 0xF5C338, 0xF5C34C, 0xF5C360, 0xF5C374,
                           0xF5C388, 0xF5BFBD, 0xF5BAB8, 0xF5BB00, 0xF5CBD9,
                           0xF5CC64, 0xF5C424, 0xF5C4B8}
    h = hta(b)
    for code in sorted(SCREENS):
        entry = paint[code - 0x80]
        print()
        print("--- code 0x%02X  %s   paint 0x%06X" % (code, SCREENS[code], entry))
        for _o, s, e, kind in page_lists(b, entry, bounds):
            if kind == "B":
                for r, x, ram, mask, sh, tbl in values(b, s, e):
                    print("    VALUE  row %3d x %3d   (0x%04X) & 0x%02X >> %d%s"
                          % (r, x, ram, mask, sh,
                             ("  -> %s" % tbl) if tbl else ""))
            else:
                for r, x, t, k in captions(b, s, e, h):
                    if k == "pix":
                        print("    text   y   %3d x %3d   %r  (proportional)" % (r, x, t))
                    else:
                        print("    text   row %3d x %3d   %r" % (r, x, t))


def selftest(a, b):
    fail = []

    def ck(name, cond):
        if not cond:
            fail.append(name)

    lo, hi, paint = dispatch_tables(b)
    ck("S1 code 0xC0+k aliases 0xA0+k", all(hi[k] == lo[32 + k] for k in range(16)))
    ck("S2 paint 0xA5 is 0xF5C10A", paint[0xA5 - 0x80] == 0xF5C10A)
    ck("S3 partial 0xA5 is 0xF5CD46", lo[0xA5 - 0x80] == 0xF5CD46)

    # the PAGE1/3 grid
    vs = [b.u16(p + B_POS[b[p]]) for p in page_value_records(b, 0xF034DE, 0xF0355D)]
    ck("S4 PAGE1/3 has ten value records", len(vs) == 10)
    rows = sorted(set(w // STRIDE for w in vs))
    ck("S5 PAGE1/3 rows are 156 and 187", rows == [156, 187])
    cols = sorted(set(8 * (w % STRIDE) for w in vs))
    ck("S6 PAGE1/3 columns are 48/88/128/160/208",
       cols == [48, 88, 128, 160, 208])

    caps = captions(b, 0xF02A46, 0xF02B47, hta(b))
    hdr = dict(((t, x) for r, x, t, k in caps if k == "pix" and r == 125))
    ck("S7 PAGE1/3 header line 1 is FIT MUT KEY DE RESO",
       sorted(hdr) == ["DE", "FIT", "KEY", "MUT", "RESO"])
    hdr2 = dict(((t, x) for r, x, t, k in caps if k == "pix" and r == 135))
    ck("S8 PAGE1/3 header line 2 is TING ING SHIFT TUNE SCALE",
       sorted(hdr2) == ["ING", "SCALE", "SHIFT", "TING", "TUNE"])
    ck("S9 the SCALE column is the rightmost", hdr2["SCALE"] == max(hdr2.values()))

    mb = captions(b, 0xF02B47, 0xF02D08, hta(b))
    mrow = [r for r, x, t, k in mb if t == "MAIN" and r > 140]
    srow = [r for r, x, t, k in mb if t == "SUB" and r > 140]
    ck("S10 MAIN row label at 152", mrow == [152])
    ck("S11 SUB row label at 183", srow == [183])
    ck("S12 both labels sit 4 rows above their value row",
       rows[0] - 152 == 4 and rows[1] - 183 == 4)

    # the read-back orders
    order = {}
    for code, name, enter, (l, h2), base in PAGES:
        params = []
        for _o, tag, cnt, par in query_runs(a, l, h2):
            params.extend(range(par, par + max(cnt, 1)))
        for _o, bse, n in loop_runs(a, l, h2):
            params.extend(range(bse, bse + n))
        params = sorted(set(params), key=params.index)
        order[code] = {base + i: p for i, p in enumerate(params)}
    ck("S13 PAGE1/2 reads p13 p14 p19",
       list(order[0xC3].values()) == [0x0D, 0x0E, 0x13])
    ck("S14 PAGE2/2 reads p16 p17 p18",
       list(order[0xC4].values()) == [0x10, 0x11, 0x12])
    ck("S15 PAGE1/3 reads 0x15 16 1D 1E 1F 20 29 2A",
       list(order[0xC5].values()) == [0x15, 0x16, 0x1D, 0x1E, 0x1F, 0x20, 0x29, 0x2A])
    ck("S16 PAGE2/3 reads 0x17 18 21 22 23 24",
       list(order[0xC6].values()) == [0x17, 0x18, 0x21, 0x22, 0x23, 0x24])
    ck("S17 PAGE3/3 reads 0x15 1F 19 1A 1B 1C 25 26 27 28",
       list(order[0xC7].values()) == [0x15, 0x1F, 0x19, 0x1A, 0x1B, 0x1C,
                                      0x25, 0x26, 0x27, 0x28])
    ck("S18 PAGE1/2 indexes from 0", min(order[0xC3]) == 0)
    ck("S19 PAGE1/3 indexes from 1", min(order[0xC5]) == 1)

    # the control
    n = ok = 0
    for code, fn, at in EDITORS:
        idx, par = decode_editor(a, at)
        for i, p in zip(idx, par):
            n += 1
            ok += (order[code].get(i) == p)
    ck("S20 all eight editor bindings agree with the read-back order",
       n == 8 and ok == 8)

    # the two ends of the L7A1429 chain that this note leans on
    allp = set()
    for code in order:
        allp |= set(order[code].values())
    allp |= {0x0B, 0x0D}                      # the two named single-field editors
    ck("S21 wave-select byte +0x0F is on no MODELING page", 0x0F not in allp)
    ck("S23 prom_a has twenty tone-message builders", len(senders(a)) == 20)
    _n, h0f = param_census(a, 0x0F)
    ck("S24 exactly one sender call site carries pushw 0x0F, at 0xFD5F12",
       len(h0f) == 1 and h0f[0][0] == 0xFD5F12)
    ck("S25 that site's selector immediate is 0x00 (arm 1, not the wave-select record)",
       a.slice(0xFD5F0F, 3) == b"\x0b\x00\x00")
    ck("S22 the pages cover 0x0B,0x0D-0x28 minus 0x0F,0x14 and 0x29-0x2A",
       allp == {0x0B, 0x0D, 0x0E, 0x10, 0x11, 0x12, 0x13, 0x15, 0x16, 0x17,
                0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21,
                0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A})

    print("FAILURES: %d" % len(fail))
    for f in fail:
        print("   %s" % f)
    return len(fail)


def main():
    a = Img(rom("wsa1_prom_a.ic12"), A_BASE)
    b = Img(rom("wsa1_prom_b.ic13"), B_BASE)
    if "--selftest" in sys.argv:
        sys.exit(1 if selftest(a, b) else 0)
    if "--nulls" in sys.argv:
        cmd_nulls(b)
        return
    lo, paint = cmd_section1(b)
    cmd_pages(b, paint)
    print()
    order = cmd_prom_a(a)
    cmd_editors(a, order)
    cmd_senders(a)


if __name__ == "__main__":
    main()
