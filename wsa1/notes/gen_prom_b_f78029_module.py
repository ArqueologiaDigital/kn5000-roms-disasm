#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF78029-0xF7A3FF -- a 121-object BITMAP SHEET,
its unreferenced head, an unbounded tail, and 608 bytes of `ret` padding.

QUESTION IT ANSWERS
  "What is the assembly text for this 9,175-byte `.incbin`, in a form the byte
   gate accepts -- and what, honestly, can be said about what is in it?"

────────────────────────────────────────────────────────────────────────────────
★★ READ THIS BEFORE QUOTING THE CONVERSION AS PROGRESS
────────────────────────────────────────────────────────────────────────────────
  This span is DATA.  Converting it retires 9,175 bytes of `.incbin` and adds
  **zero content names and zero sub_XXXXXX**: every label it can honestly write
  is FRAMED -- a kind plus an address.  So it moves prom_b's coverage up and its
  LOWER (understanding) bound DOWN, and the second number belongs in the report
  next to the first.  `--cost` prints both, measured, not estimated.

  Nothing here invents an identity.  What the 121 images DEPICT is not
  established and this file does not guess: no instruction in any of the four
  ROMs names the index table's base, so the reader that would say what they are
  for has not been found.

────────────────────────────────────────────────────────────────────────────────
WHAT THE SPAN IS, AND WHAT PINS EACH PART
────────────────────────────────────────────────────────────────────────────────
    data      609   0xF78029-0xF78289  head; NOTHING in four ROMs points into it
    bitmap  5,982   0xF7828A-0xF799E7  120 objects, each bounded by the NEXT
                                       entry of the index table
    data    1,976   0xF799E8-0xF7A19F  begins at the LAST index-table target;
                                       its end is bounded by nothing
    fill      608   0xF7A1A0-0xF7A3FF  pure 0x0E (`ret` padding), asserted
    -----   9,175

  **THE OBJECT BOUNDARIES ARE THE MACHINE'S OWN, not a rule this file invented.**
  prom_b holds a table of 4-byte little-endian pointers at 0xF003F9 (inside the
  still-unconverted `.incbin` at 0xF00000).  Reading it forward, 181 consecutive
  entries are one of: a value inside this span (121 of them), the default
  0x00FDB10E (50), or zero (10); entry 182 leaves the span.  The 121 targets,
  sorted, are the object starts, and an object runs to the next start.  Nothing
  else was used, and no stride was assumed.

  ⚠ EVERY PER-OBJECT COMMENT IS TWO LINES, NOT THREE, so this pass cannot inflate
  the tree's HEADER count with 120 copies of one templated sentence.  Only the
  banner and the two `Data_` blocks are headers.  `--cost` reports both numbers.

  ⚠ THE LAST OBJECT HAS NO END.  0xF799E8 is the highest target, so abutment
  bounds 120 objects and not the 121st.  The 1,976 bytes from there to the fill
  therefore carry ONE label and a stated gap, rather than a guessed division.
  A later pass that finds the reader can split them; this one may not.

★ WHY THE KIND IS `Bitmap` AND NOT `Data`, and how far that goes
  Two measurements, both reproducible with `--evidence`:

  1. NO CODE REFERENCE EXISTS.  Scanning all four ROM images at every byte
     offset for `call nnn` (0x1D) and `jp nnn` (0x1B) whose 24-bit operand lands
     in [0xF78029, 0xF7A400) gives **0 hits in prom_a and 0 in prom_b**, and the
     0xF40000 routine directory has **0 slots** pointing here.  The span is
     reached only as data.

  2. IT BEHAVES LIKE THE GLYPH TABLES AND NOT LIKE CODE, on a statistic
     calibrated against known corpora.  Mean popcount of the XOR of adjacent
     bytes -- low when consecutive bytes are consecutive rows of one image:

         font 8x14 Latin  0xF1B400   1.21      <- known glyphs
         font 16x16 Latin 0xF1CB70   2.20      <- known glyphs
         THIS SPAN, head             1.66
         THIS SPAN, indexed objects  1.97
         THIS SPAN, tail             2.14
         display-list records        3.19      <- known non-image data
         code 0xF5553F               3.54      <- known code
         code 0xF7D000               3.93      <- known code

     ⚠ WHAT THIS DOES NOT SHOW: it assumes an 8-pixel row pitch, so it says
     nothing about the WIDTH of any image, and a smooth non-image would score the
     same.  It is corroboration for the KIND, which is all a framed name claims.
     No object is given a `WxH` because no width is established.

NOTHING HERE CAN BREAK THE GATE
  Every byte is printed from the ROM.  verify_region() then assembles the WHOLE
  emitted text with llvm-mc and compares all 9,175 bytes against the ROM, and
  --splice refuses to write if that differs or if any check fails.

RUN
  python3 notes/gen_prom_b_f78029_module.py             # the assembly
  python3 notes/gen_prom_b_f78029_module.py --layout    # the segment table
  python3 notes/gen_prom_b_f78029_module.py --evidence  # the two measurements
  python3 notes/gen_prom_b_f78029_module.py --cost      # the naming cost
  python3 notes/gen_prom_b_f78029_module.py --selftest  # checks, incl. the LAST
  python3 notes/gen_prom_b_f78029_module.py --splice    # write it into the .s
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF78029, 0xF7A400
IDX_BASE = 0xF003F9                 # the index table, inside the 0xF00000 .incbin
DEFAULT_ENTRY = 0x00FDB10E          # the "absent" entry it repeats
TBL_LO, TBL_HI = 0xF40000, 0xF44018  # the routine directory
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
FAIL = []


def rom(which="b"):
    n = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13",
         "c": "wsa1_prom_c.ic28", "d": "wsa1_prom_d.bin"}[which]
    return open(os.path.join(ROOT, "original_ROMs", n), "rb").read()


_R = {}


def img(which="b"):
    if which not in _R:
        _R[which] = rom(which)
    return _R[which]


def at(addr, n=1, which="b"):
    base = B_BASE if which == "b" else (A_BASE if which in "ac" else 0)
    o = addr - base
    return img(which)[o:o + n]


def w32(a):
    return int.from_bytes(at(a, 4), "little")


# ------------------------------------------------------------------- layout
def index_entries():
    """The run of index-table entries that belong to this span.

    Walks 0xF003F9 forward while each 4-byte value is a target inside [LO,HI),
    the default 0x00FDB10E, or zero.  Returns [(entry address, value)]."""
    out, a = [], IDX_BASE
    while True:
        v = w32(a)
        if not (LO <= v < HI or v == DEFAULT_ENTRY or v == 0):
            break
        out.append((a, v))
        a += 4
    return out


def objects():
    """[(start, end)] -- the 121 index-table targets, sorted, each running to the
    next.  The LAST one's end is the start of the trailing fill, and that is a
    bound on the RUN, not on the object; see the docstring."""
    t = sorted({v for _a, v in index_entries() if LO <= v < HI})
    ends = t[1:] + [fill_start()]
    return list(zip(t, ends))


def fill_start():
    """The first byte of the trailing 0x0E run, measured from the ROM."""
    a = HI
    while at(a - 1, 1)[0] == 0x0E:
        a -= 1
    return a


def layout():
    obj = objects()
    return [("data", LO, obj[0][0] - LO),
            ("bitmap", obj[0][0], obj[-1][0] - obj[0][0]),
            ("data", obj[-1][0], fill_start() - obj[-1][0]),
            ("fill", fill_start(), HI - fill_start())]


# ---------------------------------------------------------------- evidence
def code_refs():
    """Opcode-anchored `call nnn` / `jp nnn` into the span, over all four images,
    at EVERY byte offset -- an upper bound, and it is zero."""
    n = 0
    for k in "abcd":
        d = img(k)
        for o in range(len(d) - 3):
            if d[o] in (0x1D, 0x1B):
                v = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
                if LO <= v < HI:
                    n += 1
    return n


def directory_slots():
    """Routine-directory slots whose `jp` target is inside the span."""
    d, n = img("b"), 0
    for o in range(TBL_LO - B_BASE, TBL_HI - B_BASE, 4):
        s = d[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            v = s[1] | s[2] << 8 | s[3] << 16
            if LO <= v < HI:
                n += 1
    return n


CORPORA = [("font 8x14 Latin  0xF1B400", 0xF1B400, 0xF1BEF0),
           ("font 16x16 Latin 0xF1CB70", 0xF1CB70, 0xF1E470),
           ("THIS SPAN, head           ", LO, None),
           ("THIS SPAN, indexed objects", None, None),
           ("THIS SPAN, tail           ", None, None),
           ("display-list records      ", 0xF3A461, 0xF3A589),
           ("code 0xF5553F             ", 0xF5553F, 0xF55755),
           ("code 0xF7D000             ", 0xF7D000, 0xF7D2D8)]


def rowxor(lo, hi):
    r = at(lo, hi - lo)
    x = [bin(r[i] ^ r[i + 1]).count("1") for i in range(len(r) - 1)]
    return sum(x) / len(x)


def evidence():
    obj = objects()
    print("  code references into 0x%06X-0x%06X, all four images, every offset: %d"
          % (LO, HI, code_refs()))
    print("  routine-directory slots pointing into it: %d" % directory_slots())
    print("  index-table entries at 0x%06X that belong to this span: %d "
          "(%d targets, %d default, %d zero)"
          % (IDX_BASE, len(index_entries()),
             len({v for _a, v in index_entries() if LO <= v < HI}),
             sum(1 for _a, v in index_entries() if v == DEFAULT_ENTRY),
             sum(1 for _a, v in index_entries() if v == 0)))
    print()
    print("  mean popcount of the XOR of adjacent bytes:")
    rows = [("font 8x14 Latin  0xF1B400", 0xF1B400, 0xF1BEF0),
            ("font 16x16 Latin 0xF1CB70", 0xF1CB70, 0xF1E470),
            ("THIS SPAN, head           ", LO, obj[0][0]),
            ("THIS SPAN, indexed objects", obj[0][0], obj[-1][0]),
            ("THIS SPAN, tail           ", obj[-1][0], fill_start()),
            ("display-list records      ", 0xF3A461, 0xF3A589),
            ("code 0xF5553F             ", 0xF5553F, 0xF55755),
            ("code 0xF7D000             ", 0xF7D000, 0xF7D2D8)]
    for nm, a, b in rows:
        print("      %-28s %5d bytes   %.2f" % (nm, b - a, rowxor(a, b)))


def cost():
    lines = emit()
    lab = sum(1 for l in lines if l.endswith(":") and not l.startswith(";"))
    print("  bytes converted            : %d" % (HI - LO))
    print("  labels added               : %d, ALL FRAMED (counted from emit())" % lab)
    print("      Data_%06X (head), %d x Bitmap_XXXXXX, Data_%06X (tail)"
          % (LO, len(objects()) - 1, objects()[-1][0]))
    print("  content names added        : 0")
    print("  sub_XXXXXX added           : 0")
    print("  headers added              : 2 (the banner and the two Data_ blocks);")
    print("      every per-object comment is TWO lines on purpose, so 120 copies of")
    print("      one templated sentence do NOT enter the tree's header count.")
    print("  ⚠ prom_b's LOWER bound falls: the denominator gains %d framed labels"
          % lab)
    print("    and the numerator gains nothing.  Measured on the whole image:")
    print("      python3 notes/wave7_documentation_metrics.py   ->  prom_b LOWER")
    print("      16.5% before this splice, 16.2% after; UPPER 67.9% -> 68.6%.")
    print("    ⚠ Do NOT quote --range for this window.  It binds a label to the")
    print("      address of the PREVIOUS content line, so the window loses")
    print("      Data_%06X at the bottom and gains sub_%06X at the top: it says"
          % (LO, HI))
    print("      \"121 framed, 1 sub\" for a splice that wrote 122 framed and 0 sub.")


# -------------------------------------------------------------------- emit
def rows(a, n, per=16):
    out = []
    for i in range(0, n, per):
        k = min(per, n - i)
        out.append("\t.byte " + ", ".join("0x%02X" % c for c in at(a + i, k))
                   + "\t; %06X" % (a + i))
    return out


def banner():
    obj = objects()
    L = ["; " + "=" * 78,
         "; 0x%06X-0x%06X -- A 121-OBJECT BITMAP SHEET, INDEXED FROM prom_b 0x%06X"
         % (LO, HI - 1, IDX_BASE),
         "; " + "=" * 78,
         ";",
         "; %d bytes.  DATA: no instruction in any of the four ROM images calls or"
         % (HI - LO),
         "; jumps into it (0 hits scanning every byte offset for `call nnn` / `jp nnn`)",
         "; and the 0xF40000 routine directory has 0 slots pointing here.",
         ";",
         "; THE OBJECT BOUNDARIES ARE THE MACHINE'S OWN.  prom_b holds 4-byte LE",
         "; pointers at 0x%06X (still inside the 0xF00000 `.incbin`).  Reading it" % IDX_BASE,
         "; forward, %d consecutive entries are a target in this span (%d of them), the"
         % (len(index_entries()), len(obj)),
         "; default 0x%08X (%d) or zero (%d); entry %d leaves the span.  The %d"
         % (DEFAULT_ENTRY,
            sum(1 for _a, v in index_entries() if v == DEFAULT_ENTRY),
            sum(1 for _a, v in index_entries() if v == 0),
            len(index_entries()) + 1, len(obj)),
         "; targets, sorted, are the object starts; an object runs to the next start.",
         "; No stride was assumed and no boundary was chosen here.",
         ";",
         "; ⚠ THE LAST OBJECT HAS NO END.  0x%06X is the highest target, so abutment"
         % obj[-1][0],
         "; bounds %d objects and not the %dth.  The %d bytes from there to the fill"
         % (len(obj) - 1, len(obj), fill_start() - obj[-1][0]),
         "; carry ONE label and a stated gap instead of a guessed division.",
         ";",
         "; ★ WHY `Bitmap` AND NOT `Data`: mean popcount of the XOR of adjacent bytes",
         "; is 1.97 over the indexed objects, against 1.21 and 2.20 for the two KNOWN",
         "; glyph tables at 0xF1B400 and 0xF1CB70, and 3.19 / 3.54 / 3.93 for known",
         "; display-list data and two proven code regions.  ⚠ It assumes an 8-pixel",
         "; row pitch, so it says nothing about any image's WIDTH -- which is why no",
         "; object carries a `WxH`.  Corroboration for the KIND, not an identity.",
         ";",
         "; ⚠ NOT ESTABLISHED: what the images DEPICT, and what indexes them.  No",
         "; instruction in any of the four images names 0x%06X, so the reader that" % IDX_BASE,
         "; would say what the sheet is for has not been found.  Every label below is",
         "; FRAMED on purpose.",
         ";",
         "; ⚠ CORRECTION.  The comment this block replaces said the trailing 0x0E run",
         "; is `0xF7A3F0-0xF7A3FF` -- 16 bytes.  It is 0x%06X-0x%06X, %d bytes, and"
         % (fill_start(), HI - 1, HI - fill_start()),
         "; a check asserts the run is pure and that the byte below it is not 0x0E.",
         "; That comment also cited notes/FINDINGS-fonts.md for this span; that note is",
         "; about the twelve character generators at 0xF1B400-0xF27C00 and says nothing",
         "; about 0xF78029.  The kind evidence used here is the two measurements above.",
         ";",
         "; Re-derive all of it, and the naming cost, with",
         ";     python3 notes/gen_prom_b_f78029_module.py --evidence --cost --selftest",
         "; " + "=" * 78]
    return L


def emit():
    obj = objects()
    out = [""] + banner() + [""]
    head_end = obj[0][0]
    out += ["; ---------------------------------------------------------------------",
            "; Data_%06X -- the %d bytes below the first indexed object" % (LO, head_end - LO),
            "; Evidence: NOTHING points here.  Of the %d index-table entries, the"
            % len(index_entries()),
            ";           lowest target is 0x%06X; and the four-image scan for a code"
            % head_end,
            ";           reference into this span returns 0.  Its row-XOR statistic",
            ";           (1.66) sits with the glyph tables, not with code, so it is",
            ";           probably more of the same sheet -- but nothing INDEXES it,",
            ";           so it gets no object division and no kind stronger than Data.",
            "; ---------------------------------------------------------------------",
            "Data_%06X:" % LO] + rows(LO, head_end - LO) + [""]
    for i, (a, e) in enumerate(obj):
        if i == len(obj) - 1:
            out += ["; ---------------------------------------------------------------------",
                    "; Data_%06X -- the LAST index-table target, and the %d bytes after it"
                    % (a, e - a),
                    "; Evidence: 0x%06X is entry %s of the table at 0x%06X.  It is the"
                    % (a, ", ".join("%d" % ((x - IDX_BASE) // 4)
                                    for x, v in index_entries() if v == a), IDX_BASE),
                    ";           HIGHEST target, so no next target bounds it; the run ends",
                    ";           only where the 0x0E padding begins, at 0x%06X." % e,
                    ";           ⚠ The object's own extent is UNKNOWN and this label",
                    ";           deliberately covers the whole run rather than guess it.",
                    "; ---------------------------------------------------------------------",
                    "Data_%06X:" % a] + rows(a, e - a) + [""]
        else:
            idx = ", ".join("%d" % ((x - IDX_BASE) // 4)
                            for x, v in index_entries() if v == a)
            # ⚠ TWO lines, deliberately.  wave7_documentation_metrics.py counts a
            # HEADER as >= 3 consecutive comment lines above a label, and a
            # three-line block here would have added 120 "headers" for one
            # templated sentence repeated 120 times -- the defect a wave-7
            # reviewer caught when a "+35 headers" gain turned out to be 35
            # removed blank lines.  The per-object evidence (its own index entry
            # and its own bound) is real and stays; the prose lives in the banner.
            out += ["; Bitmap_%06X -- %d bytes.  FRAMED: what the image depicts is not "
                    "established." % (a, e - a),
                    "; Evidence: index-table entry %s at 0x%06X names 0x%06X; the next "
                    "target, 0x%06X, bounds it." % (idx, IDX_BASE, a, e),
                    "Bitmap_%06X:" % a] + rows(a, e - a) + [""]
    f = fill_start()
    out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted pure 0x0E)"
            % (HI - f, f, HI - 1), ""]
    return out


def verify_region(lines):
    import llvm_roundtrip as RT
    body = [l + "\n" for l in lines if not l.startswith(";") and l.strip()]
    got, err = RT.assemble(body)
    if got is None:
        return False, "llvm-mc refused the emitted text:\n" + err[-2000:]
    want = at(LO, HI - LO)
    if got != want:
        for i in range(min(len(got), len(want))):
            if got[i] != want[i]:
                return False, ("first difference at 0x%06X: emitted 0x%02X, ROM 0x%02X"
                               % (LO + i, got[i], want[i]))
        return False, "length differs: emitted %d, ROM %d" % (len(got), len(want))
    return True, "%d bytes re-assemble to the ROM exactly" % len(got)


# ------------------------------------------------------------------ checks
def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    if verbose:
        print(("  ok    " if ok else "  FAIL  ") + desc)
    return ok


def checks(verbose=True):
    del FAIL[:]
    obj = objects()
    L = layout()
    c("LAYOUT tiles 0x%06X-0x%06X with no gap and no overlap" % (LO, HI),
      [(L[0][1], sum(n for _k, _s, n in L))], [(LO, HI - LO)], verbose)
    p, tiles = LO, True
    for _k, s, n in L:
        tiles = tiles and s == p
        p = s + n
    c("  every segment starts where the previous one ends", (tiles, p), (True, HI), verbose)
    c("IDX   the index run at 0x%06X is 181 entries long" % IDX_BASE,
      len(index_entries()), 181, verbose)
    c("IDX   entry 182 (0x%06X) leaves the span" % (IDX_BASE + 4 * 181),
      LO <= w32(IDX_BASE + 4 * 181) < HI, False, verbose)
    c("IDX   it names %d distinct objects" % len(obj), len(obj), 121, verbose)
    c("OBJ   the FIRST object starts at the LOWEST target",
      obj[0][0], min(v for _a, v in index_entries() if LO <= v < HI), verbose)
    c("OBJ   the LAST object starts at the HIGHEST target, 0x%06X" % obj[-1][0],
      obj[-1][0], max(v for _a, v in index_entries() if LO <= v < HI), verbose)
    c("OBJ   the LAST object's end is the fill start, not another target",
      (obj[-1][1], obj[-1][1] in [a for a, _e in obj]), (fill_start(), False), verbose)
    c("OBJ   every object is non-empty and they abut",
      ([a for a, e in obj if e <= a],
       [obj[i][1] - obj[i + 1][0] for i in range(len(obj) - 1) if obj[i][1] != obj[i + 1][0]]),
      ([], []), verbose)
    c("FILL  0x%06X..0x%06X is pure 0x0E (%d bytes)"
      % (fill_start(), HI - 1, HI - fill_start()),
      sorted(set(at(fill_start(), HI - fill_start()))), [0x0E], verbose)
    c("FILL  ...and the byte below it is not 0x0E", at(fill_start() - 1, 1)[0] != 0x0E,
      True, verbose)
    c("DATA  no code reference into the span, in any of the four images",
      (code_refs(), directory_slots()), (0, 0), verbose)
    c("KIND  the indexed objects' row-XOR statistic is below the display-list and "
      "code controls and inside the two known glyph tables' range",
      (round(rowxor(obj[0][0], obj[-1][0]), 2) < round(rowxor(0xF3A461, 0xF3A589), 2),
       round(rowxor(0xF1B400, 0xF1BEF0), 2) <= round(rowxor(obj[0][0], obj[-1][0]), 2)
       <= round(rowxor(0xF1CB70, 0xF1E470), 2)), (True, True), verbose)
    lines = emit()
    good, msg = verify_region(lines)
    c("BYTES %s" % msg, good, True, verbose)
    if verbose and FAIL:
        print("\n%d FAILED:\n%s" % (len(FAIL), "\n".join("  " + f for f in FAIL)))
    return not FAIL


def splice():
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to splice: a check failed (see above)")
    lines = emit()
    good, msg = verify_region(lines)
    if not good:
        raise SystemExit("refusing to splice: " + msg)
    src = open(SRCB, encoding="utf-8").read().split("\n")
    want = ('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X'
            % (LO - B_BASE, HI - LO))
    hit = [i for i, l in enumerate(src) if l == want]
    if len(hit) == 1:
        i = hit[0]
        lo_ = i
        while lo_ and (src[lo_ - 1].startswith(";") or not src[lo_ - 1].strip()):
            lo_ -= 1
        hi_, how = i, "over the `.incbin`"
    else:
        body = [k for k, l in enumerate(lines) if l.strip() and not l.startswith(";")]
        first, last = lines[body[0]], lines[body[-1]]
        a_ = [k for k, l in enumerate(src) if l == first]
        b2 = [k for k, l in enumerate(src) if l == last]
        if len(a_) != 1 or len(b2) != 1:
            raise SystemExit("cannot locate the spliced region: %d head anchors, "
                             "%d tail anchors" % (len(a_), len(b2)))
        lo_, hi_ = a_[0], b2[0]
        while lo_ and (src[lo_ - 1].startswith(";") or not src[lo_ - 1].strip()):
            lo_ -= 1
        while hi_ + 1 < len(src) and not src[hi_ + 1].strip():
            hi_ += 1
        how = "in place over lines %d-%d" % (lo_ + 1, hi_ + 1)
    open(SRCB, "w", encoding="utf-8").write("\n".join(src[:lo_] + lines + src[hi_ + 1:]))
    print("spliced %d lines %s; %s" % (len(lines), how, msg))
    return 0


def main():
    a = sys.argv[1:]
    if "--splice" in a:
        return splice()
    if "--layout" in a:
        for k, s, n in layout():
            print("  %-8s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        return 0
    done = False
    if "--evidence" in a:
        evidence()
        done = True
    if "--cost" in a:
        cost()
        done = True
    if "--selftest" in a:
        return 0 if checks() else 1
    if done:
        return 0
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
