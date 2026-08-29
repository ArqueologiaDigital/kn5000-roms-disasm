#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF4F000-0xF55000 -- the DRAWBAR SETTING screen
and the two table-heavy modules in front of it.  Wave 7 round 3, lane WRITER-B.

QUESTION IT ANSWERS
    "What is the assembly text for this 24,576-byte `.incbin` span -- the largest
     left in prom_b -- in a form the byte gate accepts, with every label, header
     comment and table entry attached to the right address?"
    This is the emitter whose output is spliced into prom_b/wsa1_prom_b.s.

WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
    notes/prom_b_f4f000_layout.py, re-derived on EVERY run by layout().  This
    script refuses to print if the segment count moved or if the segments stop
    tiling the span.  That layout was attacked in wave 7 round 2 by
    notes/prom_b_f4f000_verify.py, whose verdict is "SAFE TO CONVERT on this
    layout, unchanged.  Every correction above is to PROSE or to a grade label;
    no segment boundary moves."  Nothing here moves a boundary.

★ THE NAMING RULE FOR THIS SPAN
    The byte gate is blind to every name below, so a label gets a SEMANTIC name
    only when the name states a MECHANISM this file re-derives from the ROM on
    every run.  Never a purpose, never a guess.  Three sources qualify:
      (a) the object's own decoded content -- a string table's text, a bitmap's
          width and height taken from the record that blits it, a dispatch
          table's resolved targets;
      (b) an instruction sequence whose meaning is fixed by a routine ALREADY
          NAMED in prom_b/wsa1_prom_b.s (the veneers);
      (c) a display list named by the text its own records carry.
    Everything else stays `sub_XXXXXX` with the gap stated.  `--stats` reports
    the split between content-derived names and merely structural ones, because
    a name that is only an address in disguise should not be counted as
    understanding.

WHAT THE SPAN TURNED OUT TO BE  (all of it re-derived by --selftest)
    A NINE-DRAWBAR ORGAN REGISTRATION SCREEN.  The display list at 0xF54331
    carries nine whole-number labels reading 16, 5, 8, 4, 2, 2, 1, 1, 1 and four
    fraction labels reading 1/3, 2/3, 3/5, 1/3 -- the Hammond-style footages
    16', 5 1/3', 8', 4', 2 2/3', 2', 1 3/5', 1 1/3', 1'.  Nine routines at
    0xF5394C..0xF53D58 each step one RAM nibble toward a target nibble, re-arm
    themselves on a timer, and redraw one column at screen positions 3, 7, 11,
    ... 35 (step 4).  Their sprite base is 0xF54808 for the five integer
    footages and 0xF54AC3 for the four fractional ones -- a split with no
    exception.  The four numeric parameters below the bars are the four nibbles
    of (0x2640)/(0x2641), and each is printed exactly 25 cells after the start
    of its own caption -- `PERCUSSIVE T0NE DECAY  :`, `PERCUSSIVE T0NE LEVEL  :`,
    `DRAWBAR ATTACK TIME    :`, `DRAWBAR RELEASE TIME   :` -- which is what pairs
    a nibble with a caption.

    ⚠ `T0NE` IS SPELT WITH A ZERO IN THE ROM, in both captions and in the
    `PERCUSSIVE`/`T0NE` header strip.  It is reproduced exactly.  The machine
    really shows it; prom_b does the same in `S0NG`, `REC0RD` and
    `C0MBINATI0N M0DE` (notes/FINDINGS-prom_b-ui-variable-index.md).

FIVE CORRECTIONS TO ALREADY-COMMITTED TEXT, each re-derived by --selftest
    C1  notes/prom_b_f4f000_layout.py's HOLES[0xF4FA7A] says prom_a takes the
        address of NINE points inside the run.  It is EIGHT.  The ninth it names
        -- "the run's own start", 0xF4FA7A -- is named by no instruction in
        either image.  (Found by round 2; re-derived here.)
    C2  HOLES[0xF4FE38] says THIRTY-ONE distinct addresses inside it are named
        by proven prom_a instructions.  It is 29.  (Same.)
    C3  HOLES[0xF542A4] describes 44 of that segment's 45 bytes and never
        mentions the trailing 0x00 at 0xF542D0.  That byte is not slack: it is
        entry 8 of the NINE-entry drawbar row-offset table at 0xF542C8, whose
        entries are 0x6E 0x62 0x54 0x46 0x38 0x2A 0x1C 0x0E 0x00 -- one step of
        12 then eight of 14 -- and which ends exactly where the 4-pointer table
        at 0xF542D1 begins.  Nine entries for nine drawbar positions.
    C4  HOLES[0xF542E1] says the one-record list there stays data because
        INTER_MIN is 2.  It is CALL-SITE PROVEN: `lda XWA,0xf542e1` at 0xF53841
        pushes it as the start and `lda XBC,0xf542ed` at 0xF5383B as the end,
        two instructions before `call 0xf42e00`.  The layout's site scanner
        misses it because the pair is split by a `jr`.  The boundary does not
        move -- the layout already ends a segment at 0xF542ED -- only the
        description changes.
    C5  HOLES[0xF511DD] says "the record boundary is not pinned by anything this
        lane could measure".  It IS pinned: the 225-entry table at 0xF51E8A
        resolves to 110 distinct addresses, ALL inside the segment, and 109 of
        the 110 have the prom_a callback word 0x00FB4D61/0x00FB4D62 at exactly
        +0x10.  Those 110 are the record starts; the dominant stride is 28.
        ⚠ The 110th, 0xF514B9, has the callback at +0x12 rather than +0x10 and
        is 2 bytes in front of another entry, 0xF514BB.  It is reported, not
        smoothed.
    ⚠ notes/prom_b_f4f000_layout.py is NOT edited by this lane -- another lane
    may be running it.  The corrections live here and in the emitted header, and
    --selftest reproduces each one.  Whoever owns that file should fold them in.
    The same applies to the round-2 finding that its `refs()` is unreachable
    from its own CLI: this file exposes it as `--refs`.

NOTHING HERE CAN BREAK THE GATE
    Code comes from notes/llvm_roundtrip_autoforce.py, which assembles every
    candidate listing and byte-compares it with the ROM before returning it.
    Data is emitted from the ROM.  Then main() assembles the WHOLE emitted
    region and compares it byte for byte with the ROM, and exits non-zero
    WITHOUT PRINTING if it differs.  So the text this prints has already rebuilt
    the span.

RUN
    python3 notes/gen_prom_b_f4f000_module.py            # the assembly
    python3 notes/gen_prom_b_f4f000_module.py --check    # layout fingerprint only
    python3 notes/gen_prom_b_f4f000_module.py --stats    # segment/label census
    python3 notes/gen_prom_b_f4f000_module.py --refs     # the 134 proven prom_a
                                                         # references, which the
                                                         # layout collects but
                                                         # never prints
    python3 notes/gen_prom_b_f4f000_module.py --drawbars # the nine-bar table
    python3 notes/gen_prom_b_f4f000_module.py --selftest # every number quoted in
                                                         # a header, re-derived
"""
import collections
import importlib.util
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

ARGV = list(sys.argv)                 # captured BEFORE any import mangles it

LO, HI = 0xF4F000, 0xF55000
B_BASE, A_BASE = 0xF00000, 0xF80000
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")

EXPECTED = 43                         # segments, as audited in wave 7 round 2
EXPECTED_BYTES = HI - LO


def _load(path, name):
    """Import a sibling tool.  ⚠ Several of them read sys.argv at import time,
    so argv is masked during the load and restored afterwards."""
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


L = _load(os.path.join(ROOT, "notes", "prom_b_f4f000_layout.py"), "f4f000_layout")
RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "rt")

_D = None


def rom():
    global _D
    if _D is None:
        _D = open(IMGB, "rb").read()
    return _D


def by(a):
    return rom()[a - B_BASE]


def sl(a, n):
    return rom()[a - B_BASE:a - B_BASE + n]


def u16(a):
    return int.from_bytes(sl(a, 2), "little")


def u32(a):
    return int.from_bytes(sl(a, 4), "little")


def txt(a, n):
    return "".join(chr(c) if 32 <= c < 127 else "." for c in sl(a, n))


# ------------------------------------------------------------------- layout
_LAY = []


def layout():
    if _LAY:
        return _LAY[0]
    segs = L.build()[0]
    if len(segs) != EXPECTED:
        sys.exit("REFUSING TO EMIT: layout has %d segments, expected %d.  The "
                 "boundaries moved since the round-2 audit; re-audit before "
                 "emitting." % (len(segs), EXPECTED))
    tot = sum(n for _k, _a, n in segs)
    if segs[0][1] != LO or tot != EXPECTED_BYTES:
        sys.exit("REFUSING TO EMIT: segments do not tile the span (%d of %d)"
                 % (tot, EXPECTED_BYTES))
    pos = LO
    for _k, a, n in segs:
        if a != pos:
            sys.exit("REFUSING TO EMIT: gap or overlap at 0x%06X" % a)
        pos = a + n
    _LAY.append(segs)
    return segs


# --------------------------------------------------------------- the code
_TR = {}


def transcribe(start, length):
    """The proven listing for [start,start+length).  autoforce assembles and
    byte-compares before returning, so these lines already rebuild the range."""
    key = (start, length)
    if key not in _TR:
        p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(start),
                            hex(length), "--quiet"],
                           capture_output=True, text=True, cwd=ROOT)
        if p.returncode != 0:
            sys.exit("REFUSING TO EMIT: autoforce failed at 0x%06X:\n%s"
                     % (start, p.stderr))
        _TR[key] = p.stdout.rstrip("\n").split("\n")
    return _TR[key]


_ROWS = []


def code_rows():
    """[(addr, source line, mame text)] over every `code` segment."""
    if _ROWS:
        return _ROWS[0]
    out = []
    for kind, a, n in layout():
        if kind != "code":
            continue
        for ln in transcribe(a, n):
            m = re.search(r";\s*([0-9A-F]{6})\s+(.*)$", ln)
            if not m:
                sys.exit("REFUSING TO EMIT: un-addressed line %r" % ln)
            out.append((int(m.group(1), 16), ln, m.group(2).strip()))
    _ROWS.append(out)
    return out


def code_at():
    return {a: t for a, _l, t in code_rows()}


def boundaries():
    return {a for a, _l, _t in code_rows()}


# ------------------------------------------------------------ entry points
def thunks():
    """{target: [slot,...]} for the `jp nnn` slots of the 0xF40000 directory."""
    d, out = rom(), {}
    for o in range(0x40000, 0x44018, 4):
        if d[o] == 0x1B:
            t = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
            if LO <= t < HI:
                out.setdefault(t, []).append(B_BASE + o)
    return out


CALL = re.compile(r"^(call|calr)\s+0x([0-9a-f]{6})$")


def internal_calls():
    """{target: [instruction address,...]} for call/calr inside the span.

    ⚠ Cited from the TRANSCRIPTION's own address column, never from a hexdump
    offset -- the systematic off-by-one this project has made twice comes from
    citing an operand byte instead of the opcode."""
    out = {}
    for a, _l, t in code_rows():
        m = CALL.match(t)
        if m and LO <= int(m.group(2), 16) < HI:
            out.setdefault(int(m.group(2), 16), []).append(a)
    return out


LDA = re.compile(r"^lda(?:_24)?\s+X(?:BC|WA|IX|IY|HL|DE),?\s*\(?0x([0-9a-f]{6})\)?$")


def lda_sites():
    """{target: [instruction address,...]} for `lda Xnn,0xf5xxxx` in the span."""
    out = {}
    for a, _l, t in code_rows():
        m = LDA.match(t.replace(", (", ",(").replace("lda_24 x", "lda_24 X")
                      .replace("(", "").replace(")", ""))
        if m and LO <= int(m.group(1), 16) < HI:
            out.setdefault(int(m.group(1), 16), []).append(a)
    return out


def dispatch(base, n):
    return [u32(base + 4 * i) for i in range(n)]


def entry_points():
    """addr -> [evidence strings] for every in-span address something outside
    the linear instruction stream names."""
    ev = collections.defaultdict(list)
    for t, slots in thunks().items():
        for s in slots:
            ev[t].append("thunk slot T_%06X" % s)
    for i, v in enumerate(dispatch(0xF54248, 23)):
        if LO <= v < HI:
            ev[v].append("DispatchTable_F54248[%d]" % i)
    for i, v in enumerate(dispatch(0xF542D1, 4)):
        if LO <= v < HI:
            ev[v].append("DispatchTable_F542D1[%d]" % i)
    for t, ss in internal_calls().items():
        ev[t].append("call from " + ", ".join("0x%06X" % x for x in ss[:6])
                     + ("" if len(ss) <= 6 else ", +%d more" % (len(ss) - 6)))
    for a, sites in prom_a_refs().items():
        if a in boundaries():
            for img, site, text in sites[:3]:
                if text.startswith("call"):
                    ev[a].append("call from prom_%s 0x%06X" % (img, site))
    return ev


_PAR = {}


def prom_a_refs():
    """{in-span address: [(image, site, source text)]} from the layout's
    proven_operands() -- the strongest evidence this span has, and the round-2
    audit found it unreachable from that script's own CLI."""
    if not _PAR:
        _PAR.update(L.proven_operands(LO, HI))
    return _PAR


# ------------------------------------------------------- the nine drawbars
DRAWBAR_STARTS = [0xF5394C, 0xF539C0, 0xF53A34, 0xF53AC3, 0xF53B52,
                  0xF53BC6, 0xF53C55, 0xF53CC9, 0xF53D58]
DRAWBAR_END = 0xF53DCC
FOOTAGE = ["16'", "5 1/3'", "8'", "4'", "2 2/3'", "2'", "1 3/5'", "1 1/3'", "1'"]
FOOTAGE_ID = ["16ft", "5_1_3ft", "8ft", "4ft", "2_2_3ft", "2ft",
              "1_3_5ft", "1_1_3ft", "1ft"]
ROWOFF = 0xF542C8              # 9 bytes, entry per drawbar position
SPRITE_A, SPRITE_B = 0xF54808, 0xF54AC3
DRAW_COLUMN, BLIT_REC = 0xF538B6, 0xF5392B


def drawbars():
    """One row per drawbar, every field READ OUT OF THE TRANSCRIPTION.

    (start, end, ram byte, 'lo'/'hi', target byte, screen column, sprite base)
    """
    rows = []
    at = code_rows()
    for i, s in enumerate(DRAWBAR_STARTS):
        e = DRAWBAR_STARTS[i + 1] if i + 1 < len(DRAWBAR_STARTS) else DRAWBAR_END
        seg = [t for a, _l, t in at if s <= a < e]
        ram = {int(m.group(1), 16) for m in
               (re.match(r"lda XIX,0x([0-9a-f]+)$", t) for t in seg) if m}
        tgt = {int(m.group(1), 16) for m in
               (re.match(r"ld A,\(0x([0-9a-f]+)\)$", t) for t in seg) if m}
        nib = "hi" if any(t == "srl 0x04,C" for t in seg) else "lo"
        base = {int(m.group(1), 16) for m in
                (re.match(r"lda XBC,0x([0-9a-f]+)$", t) for t in seg) if m}
        base -= {s}                                   # the self re-arm pointer
        col = [int(m.group(1), 16) for m in
               (re.match(r"push 0x([0-9a-f]+)$", t) for t in seg) if m]
        col = [c for c in col if c != 1]               # the timer's `push 1`
        if len(ram) != 1 or len(tgt) != 1 or len(base) != 1 or len(col) != 1:
            sys.exit("REFUSING TO EMIT: drawbar %d does not read as one shape "
                     "(ram %r tgt %r base %r col %r)" % (i + 1, ram, tgt, base, col))
        rows.append((s, e, ram.pop(), nib, tgt.pop(), col[0], base.pop()))
    return rows


def rowoffsets():
    return list(sl(ROWOFF, 9))


# -------------------------------------------------------- the display lists
def dl_lists():
    """[(start, end, interpreter, [site,...])] for every display list the layout
    frames, plus 0xF542E1 which correction C4 restores."""
    lists = L.build()[5]
    out = []
    for s in sorted(lists):
        e, interp = lists[s][0], lists[s][1] if len(lists[s]) > 1 else "?"
        out.append((s, e, interp))
    return out


def dl_records(s, e):
    """[(addr, opcode, length)] by the record's own length byte."""
    recs, a = [], s
    while a < e:
        n = by(a + 1)
        if n == 0 or a + n > e:
            sys.exit("REFUSING TO EMIT: display list 0x%06X does not frame" % s)
        recs.append((a, by(a), n))
        a += n
    return recs


def dl_text_records(s, e):
    """[(addr, opcode, position, text)] for the DLHandler_IX_Text opcodes.

    DLHandler_IX_Text (prom_b 0xF31A3A, already named in the .s) puts the word
    at +2 into IX and takes the characters from +4, so +2 IS the screen
    position and the text starts at +4."""
    return [(a, op, u16(a + 2), txt(a + 4, n - 4))
            for a, op, n in dl_records(s, e)
            if op in (0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E,
                      0x1F, 0x20, 0x21) and n > 4]


def footage_labels():
    """The nine whole-number footage labels of DL 0xF54331, in address order.

    ⚠ Selected by CONTENT, not by opcode: the list also carries nine records
    whose text is a single apostrophe -- the foot mark -- and the split between
    opcode 0x20 and opcode 0x07 does not follow the digit/mark split.  Filtering
    on "the text is all digits" is what isolates the nine, and foot_marks()
    below checks that the other nine are the marks."""
    return [(a, p, t) for a, _op, p, t in dl_text_records(0xF54331, 0xF543B0)
            if t.isdigit()]


def foot_marks():
    return [(a, p) for a, _op, p, t in dl_text_records(0xF54331, 0xF543B0)
            if t == "'"]


def fraction_labels():
    """The four op-0x17 fraction labels.  DLHandler_2Words_Text (0xF31A52)
    takes TWO words at +2/+4 and the characters from +6."""
    return [(a, u16(a + 2), u16(a + 4), txt(a + 6, n - 6))
            for a, op, n in dl_records(0xF54331, 0xF543B0) if op == 0x17]


CAPTIONS = [(0xF54513, 0x2640, 0x0F, 0), (0xF5452F, 0x2640, 0xF0, 4),
            (0xF54563, 0x2641, 0xF0, 4), (0xF5459E, 0x2641, 0x0F, 0)]


def caption_pairs():
    """[(caption record, caption text, B record, RAM addr, mask, shift, gap)].

    The pairing is the +25: each interpreter-B value cell is printed exactly 25
    cells after the start of its own 24-character caption, i.e. one cell past
    the colon.  Four captions, four cells, one constant."""
    brec = [a for a, op, n in dl_records(0xF54668, 0xF546A4) if op == 0x02]
    out = []
    for i, (c, ram, mask, sh) in enumerate(CAPTIONS):
        b = brec[i]
        out.append((c, txt(c + 4, by(c + 1) - 4), b, ram, mask, sh,
                    u16(b + 0x0D) - u16(c + 2)))
    return out


# ------------------------------------------------------ the record array
RECTAB, RECTAB_N = 0xF51E8A, 225
RECARR_LO, RECARR_HI = 0xF511DD, 0xF51E20
CALLBACKS = (0x00FB4D61, 0x00FB4D62)


def record_starts():
    return sorted(set(u32(RECTAB + 4 * i) for i in range(RECTAB_N)))


def record_callback_hits():
    return sum(1 for v in record_starts() if u32(v + 0x10) in CALLBACKS)


# ------------------------------------------------------------ the sprites
SLICE = 233                     # bytes between the three columns of one sprite
WINDOW = 0x7B                   # rows the blit takes out of a slice
BITMAPS = [(0xF54718, 6, 20), (0xF54790, 6, 20), (0xF54D7E, 38, 6)]
DUP_AT = 0xF54EDA


def dup_occurrences():
    """How many times the 0xF54D7E bitmap occurs in the whole prom_b image."""
    pat, d, out, i = sl(0xF54D7E, 228), rom(), [], 0
    while True:
        j = d.find(pat, i)
        if j < 0:
            break
        out.append(B_BASE + j)
        i = j + 1
    return out


# ------------------------------------------------------------- the labels
LABELS = {}
HEADERS = {}
CONTENT_NAMED = set()           # names derived from decoded CONTENT, not shape


def H(addr, *lines):
    HEADERS[addr] = [l for l in lines]


def wrap(prefix, body, width=74):
    import textwrap
    pad = " " * len(prefix)
    ls = textwrap.wrap(body, width - len(prefix)) or [""]
    return [prefix + ls[0]] + [pad + l for l in ls[1:]]


def structure():
    """Assign every label and header.  Called once, before emission."""
    if LABELS:
        return
    segs = layout()
    th, ic, ev = thunks(), internal_calls(), entry_points()
    par = prom_a_refs()
    bnd = boundaries()
    db = drawbars()
    off = rowoffsets()

    # ---- (b) the veneer whose target is already named in the .s -------------
    LABELS[0xF4F017] = "DrawValueGlyph_Veneer"
    CONTENT_NAMED.add(0xF4F017)
    H(0xF4F017,
      "DrawValueGlyph_Veneer -- stack veneer for DrawValueGlyph_24x24",
      "Called from: prom_a 0xFBE7D4 (x3), by `call 0xf4f017`",
      "Inputs:  (XIZ+8) = position -> IX, (XIZ+10) = value -> L",
      "Evidence: the body is `ld IX,(XIZ+0x08) / extz XIX / ld L,(XIZ+0x0a) /",
      "          call 0xf41834`, and thunk slot T_F41834 holds `jp 0x00F31873`.",
      "          0xF31873 is DrawValueGlyph_24x24 in this file, whose stated",
      "          inputs are exactly `L = value; IX = position`.  Both halves of",
      "          the name come from a label the tree already carries.")

    # ---- the two sibling veneers, which do NOT get a name -------------------
    for a, tgt, arg in ((0xF4F000, 0xF415B4, "A"), (0xF4F02E, None, None)):
        LABELS[a] = "sub_%06X" % a
    H(0xF4F000,
      "sub_F4F000 -- the same veneer shape as DrawValueGlyph_Veneer, for a",
      "routine that has no name yet",
      "Called from: prom_a 0xFBE85C, by `call 0xf4f000`",
      "Evidence: `ld IX,(XIZ+0x08) / ld A,(XIZ+0x0a) / call 0xf415b4`; slot",
      "          T_F415B4 holds `jp 0x00F9458C`, which is `sub_F9458C` in",
      "          prom_a/wsa1_prom_a.s.",
      "Unknown: what the callee does.  Its target is unnamed, so naming the",
      "         veneer would be inventing a meaning the tree does not have.")
    H(0xF4F02E,
      "sub_F4F02E",
      "Called from: prom_a 0xFBBA9B, by `call 0xf4f02e`",
      "Touches: the pointer array at (0x60F018), (0x2760)-(0x2763), (0x28B0)",
      "Evidence: the call site above; 0xF4F02E is an instruction boundary of",
      "          this transcription, re-asserted on every emit.",
      "Unknown: what the routine is FOR.  A stated gap beats a plausible guess.")

    # ---- (a)/(c) the drawbar machinery -------------------------------------
    for i, (s, e, ram, nib, tgt, col, base) in enumerate(db):
        name = "Drawbar%d_%s_Update" % (i + 1, FOOTAGE_ID[i])
        LABELS[s] = name
        CONTENT_NAMED.add(s)
        H(s,
          "%s -- drawbar %d of 9, footage %s" % (name, i + 1, FOOTAGE[i]),
          *(wrap("Called from: ",
                 "%s; and PaintAllDrawbars (0xF536FF) calls all nine in order."
                 % (", ".join("T_%06X" % x for x in th.get(s, [])) or
                    ", ".join("0x%06X" % x for x in ic.get(s, [])) or "NOTHING FOUND"))
            + wrap("What it does: ",
                   "reads the %s nibble of (0x%04X), compares it with the %s "
                   "nibble of (0x%04X), and if they differ writes the value one "
                   "step nearer, re-arms ITSELF through the timer (`lda "
                   "XBC,0x%06X / call 0xf42e84 / push 1 / call 0xf42dc0`) and "
                   "falls into the redraw.  Then it calls Drawbar_DrawColumn "
                   "with (index = that nibble, column = %d, sprite = "
                   "Bitmap_Drawbar%s)."
                   % ("high" if nib == "hi" else "low", ram,
                      "high" if nib == "hi" else "low", tgt, s, col,
                      "A" if base == SPRITE_A else "B"))
            + wrap("Evidence: ",
                   "every field above is read out of this transcription by "
                   "drawbars() and re-checked by --selftest: `lda XIX,0x%04x`, "
                   "`ld A,(0x%04x)`, `push 0x%04x` and `lda XBC,0x%06x` all "
                   "occur exactly once in 0x%06X-0x%06X.  The footage is the "
                   "op-0x20 label of DL_DrawbarFootageScale whose screen "
                   "position is one cell of column %d (bijection, --selftest check F)."
                   % (ram, tgt, col, base, s, e - 1, col))
            + wrap("Note: ",
                   "the sprite split is exact -- the five INTEGER footages "
                   "(16', 8', 4', 2', 1') use Bitmap_DrawbarA and the four "
                   "FRACTIONAL ones (5 1/3', 2 2/3', 1 3/5', 1 1/3') use "
                   "Bitmap_DrawbarB, with no exception.  It is close to but not "
                   "equal to the Hammond white/coloured pattern, which would "
                   "put 16' in the other group, so the two sprites are recorded "
                   "as A and B and NOT named by colour.")))

    LABELS[DRAW_COLUMN] = "Drawbar_DrawColumn"
    CONTENT_NAMED.add(DRAW_COLUMN)
    H(DRAW_COLUMN,
      "Drawbar_DrawColumn -- blit one drawbar, three 8-pixel slices wide",
      *(wrap("Called from: ",
             ", ".join("0x%06X" % x for x in ic.get(DRAW_COLUMN, [])))
        + wrap("Inputs:  ",
               "(XIZ+8) = the bar's 0..15 value, (XIZ+0x0A) = the screen column, "
               "(XIZ+0x0C) = the sprite base.")
        + wrap("What it does: ",
               "builds an 11-byte display-list-shaped record on its own stack "
               "frame -- opcode 3, BC = 1 byte per row, HL = 0x%02X rows, IX = "
               "column + 0x10B8, XIY = base + DrawbarRowOffsets[value] -- and "
               "hands it to Blit_FromStackRecord three times, advancing IX by 1 "
               "and XIY by %d each time." % (WINDOW, SLICE))
        + wrap("Evidence: ",
               "`ld (XIX),0x03`, `ld (XIX+0x01),0x0001`, `ld (XIX+0x03),0x%04x`, "
               "`add BC,0x10b8`, `add XBC,0x00f542c8` and `ld A,(XBC)` at "
               "0xF538D1-0xF538F5; then `ld XBC,0x000000e9` (= %d) added to "
               "(XIX+7) twice.  0x%02X + 0x6E = 0x%02X = %d, so the window and "
               "the largest row offset fill one slice exactly."
               % (WINDOW, SLICE, WINDOW, WINDOW + 0x6E, SLICE))
        + wrap("Unknown: ",
               "nothing bounds the value at 9 -- the callers mask it to 4 bits. "
               "Nine is the number of offsets that fit before the pointer table "
               "at 0xF542D1 begins.")))

    LABELS[BLIT_REC] = "Blit_FromStackRecord"
    CONTENT_NAMED.add(BLIT_REC)
    H(BLIT_REC,
      "Blit_FromStackRecord -- issue one `swi 7` from an 11-byte record",
      *(wrap("Called from: ",
             ", ".join("0x%06X" % x for x in ic.get(BLIT_REC, [])))
        + wrap("Inputs:  ", "(XSP+0x18) = the record.")
        + wrap("What it does: ",
               "BC = (rec+1), HL = (rec+3), IX = (rec+5), XIY = (rec+7), "
               "A = (rec+0), `swi 7`.  That is the same register set "
               "DLHandler_FarPtr (0xF31ABE) loads from an opcode-3 display-list "
               "record, taken from RAM instead of from ROM.")
        + wrap("Evidence: ",
               "the five loads at 0xF53936-0xF53942 and the `swi 7` at "
               "0xF53944, read out of this transcription.")))

    LABELS[0xF536FF] = "PaintAllDrawbars"
    CONTENT_NAMED.add(0xF536FF)
    H(0xF536FF,
      "PaintAllDrawbars -- step and redraw all nine bars",
      *(wrap("Called from: ",
             ", ".join("0x%06X" % x for x in ic.get(0xF536FF, [])) or "NOTHING FOUND")
        + wrap("What it does: ",
               "returns at once if (0x289E) != 0, else `calr` each of the nine "
               "Drawbar*_Update routines in footage order.")
        + wrap("Evidence: ",
               "nine `calr` instructions at 0xF53706, 0xF53709, 0xF5370C, "
               "0xF5370F, 0xF53712, 0xF53715, 0xF53718, 0xF5371B and 0xF5371E, "
               "whose targets are exactly the nine drawbar entry points and "
               "nothing else (--selftest check E4).")))

    LABELS[0xF5302A] = "DrawbarScreen_Dispatch"
    CONTENT_NAMED.add(0xF5302A)
    H(0xF5302A,
      "DrawbarScreen_Dispatch -- the module's message entry",
      *(wrap("Called from: ",
             ", ".join("T_%06X" % x for x in th.get(0xF5302A, [])) or "NOTHING FOUND")
        + wrap("What it does: ",
               "`link XIZ,0 / pushw (XIZ+0x0A) / pushw (XIZ+0x08) / call "
               "0xf42c74 / mul A,4 / add XWA,0x00f54248 / ld XBC,(XWA) / jp "
               "(XBC)` -- the image-wide message-dispatch idiom, here through "
               "DispatchTable_F54248.")
        + wrap("Evidence: ",
               "the byte-identical idiom appears at sub_F0F17C, sub_F4C4B5 and "
               "0xF1233E in this same file, each with its own table; the only "
               "thing this file adds is WHICH table.  The name states the "
               "mechanism and the table, not a purpose.")))

    # ---- the display lists --------------------------------------------------
    DLNAME = {
        0xF542E1: ("DL_Flag2896b5_Set", "one op-03 record: %s at position 0x%04X"),
        0xF542ED: ("DL_Flag2896b5_Clear", None),
        0xF542F9: ("DL_Flag2896b4_Set", None),
        0xF54305: ("DL_Flag2896b4_Clear", None),
        0xF54311: ("DL_DrawbarScaleStrip", None),
        0xF54331: ("DL_DrawbarFootageScale", None),
        0xF543B0: ("DL_F543B0", None),
        0xF543C4: ("DL_F543C4", None),
        0xF543D6: ("DL_DrawbarTitle", None),
        0xF54416: ("DL_PercussiveToneHeader", None),
        0xF544AD: ("DL_SoundEditBar", None),
        0xF544EB: ("DL_DrawbarSettingPage", None),
        0xF54668: ("DL_DrawbarParamValues", None),
        0xF546C4: ("DL_ParamCursorBar", None),
        0xF546FA: ("DL_F546FA", None),
        0xF54705: ("DL_F54705", None),
    }
    for s, (name, _f) in DLNAME.items():
        LABELS[s] = name
        if not name.startswith("DL_F"):
            CONTENT_NAMED.add(s)

    ic_lda = lda_sites()
    for s, (name, _f) in sorted(DLNAME.items()):
        e = dl_end(s)
        recs = dl_records(s, e)
        strings = [txt(a + 4, n - 4) for a, op, n in recs
                   if op in (0x20, 0x06) and n > 5]
        strings += [txt(a + 6, n - 6) for a, op, n in recs
                    if op in (0x17, 0x1C) and n > 7]
        strings = [t for t in strings if len(re.sub(r"[^ -~]", "", t)) >= 2]
        sites = ic_lda.get(s, [])
        H(s,
          "%s -- a UI display list, %d record%s, 0x%06X-0x%06X"
          % (name, len(recs), "" if len(recs) == 1 else "s", s, e - 1),
          *(wrap("Run by: ",
                 ("`lda XWA,0x%06x` at %s pushes it as the list START, with the "
                  "END pushed just before it, then `call 0xf42e00` (interpreter "
                  "A) or `call 0xf42e04` (interpreter B)."
                  % (s, ", ".join("0x%06X" % x for x in sites)))
                 if sites else "NO SITE FOUND in this span.")
            + (wrap("Text it draws: ", "; ".join(repr(t) for t in strings))
               if strings else [])
            + wrap("Evidence: ",
                   "the records above are framed by their own length bytes, and "
                   "the walk consumes 0x%06X-0x%06X exactly -- a miscount "
                   "anywhere would end somewhere else." % (s, e - 1))))

    # a few of the lists deserve more than the generic header
    H(0xF54331, *(HEADERS[0xF54331] + wrap("★ Footages: ",
        "nine whole-number labels reading %s, nine foot marks, and four "
        "fraction labels reading %s.  "
        "Read together they are the nine Hammond-style drawbar footages %s.  "
        "The numeric labels' screen positions run 0x%04X..0x%04X and each "
        "falls within one cell of its bar's own column (--selftest check F)."
        % (", ".join(repr(t) for _a, _p, t in footage_labels()),
           ", ".join(repr(t) for _a, _x, _y, t in fraction_labels()),
           " ".join(FOOTAGE), footage_labels()[0][1], footage_labels()[-1][1]))))

    cp = caption_pairs()
    H(0xF54668, *(HEADERS[0xF54668] + wrap("★ The pairing: ",
        "four interpreter-B op-02 records, each printing a nibble of "
        "(0x2640)/(0x2641) through DLTableB_SignedNibble.  Each is placed "
        "exactly %d cells after the START of one 24-character caption in "
        "DL_DrawbarSettingPage, so the value sits one cell past the colon: %s."
        % (cp[0][6], "; ".join("%r <- (0x%04X) & 0x%02X >> %d"
                               % (c[1].strip(), c[3], c[4], c[5]) for c in cp)))))

    H(0xF542E1, *(HEADERS[0xF542E1] + wrap("⚠ CORRECTION: ",
        "notes/prom_b_f4f000_layout.py's HOLES table calls this a display list "
        "its INTER_MIN = 2 rule refuses.  It is CALL-SITE PROVEN: `lda "
        "XWA,0xf542e1` at 0xF53841 and `lda XBC,0xf542ed` at 0xF5383B, two "
        "instructions before the `call 0xf42e00` at 0xF53855.  The layout's "
        "site scanner misses it because a `jr` splits the pair.  No boundary "
        "moves.")))

    # ---- the data objects ---------------------------------------------------
    def obj(a, name, *hdr):
        """A label whose name is only its own address dressed up."""
        LABELS[a] = name
        H(a, *hdr)

    def objc(a, name, *hdr):
        """A label whose name is derived from DECODED CONTENT."""
        LABELS[a] = name
        CONTENT_NAMED.add(a)
        H(a, *hdr)

    objc(ROWOFF, "DrawbarRowOffsets",
        *(["DrawbarRowOffsets -- 9 source-row offsets, one per drawbar position"]
          + wrap("Read by: ",
                 "Drawbar_DrawColumn, `add XBC,0x00f542c8 / ld A,(XBC)` at "
                 "0xF538EF/0xF538F5, indexed by the bar's 0..15 nibble.")
          + wrap("Entries: ",
                 "%s -- one step of %d and then eight of %d."
                 % (" ".join("0x%02X" % v for v in off), off[0] - off[1],
                    off[1] - off[2]))
          + wrap("Entry count: ",
                 "NINE, and nine is measured twice: 0x%06X + 9 = 0x%06X, which "
                 "is exactly where DispatchTable_F542D1 starts; and the screen "
                 "shows nine drawbars.  ⚠ This is CORRECTION C3: the layout's "
                 "HOLES table describes 44 of this segment's 45 bytes and never "
                 "mentions the trailing 0x00, which is entry 8."
                 % (ROWOFF, ROWOFF + 9))))

    obj(0xF542A4, "Table_F542A4",
        "Table_F542A4 -- nine 32-bit words of zero in front of DrawbarRowOffsets",
        *(wrap("Evidence: ",
               "read from the ROM.  If they are empty slots of "
               "DispatchTable_F54248 that table would have 32 entries and end "
               "at 0xF542C8; nothing in the code bounds the index, so the "
               "layout stops the table at 23 and this stays a separate object.")
          + wrap("Unknown: ", "whether they belong to the table before them.")))

    objc(0xF54248, "DispatchTable_F54248",
        *(["DispatchTable_F54248 -- 23 pointers, the module's message table"]
          + wrap("Read by: ",
                 "DrawbarScreen_Dispatch, `add XWA,0x00f54248` at 0xF5303D "
                 "after `mul A,4`.")
          + wrap("Entries: ",
                 "%d, %d distinct; the last %d are the image-wide default stub "
                 "0x00F42C70, whose target is a bare `ret`."
                 % (23, len(set(dispatch(0xF54248, 23))),
                    sum(1 for v in dispatch(0xF54248, 23) if v == 0xF42C70)))
          + wrap("Entry count: ",
                 "23 is where the layout's chain rule stops, because entry 23 "
                 "is a zero word and a zero is not an address.  ⚠ Nothing in "
                 "the code bounds the index, so 23 is a READING of the data, "
                 "not a measurement of the table.")))

    objc(0xF542D1, "DispatchTable_F542D1",
        "DispatchTable_F542D1 -- 4 pointers into this module's code",
        "Evidence: four 32-bit words, all four landing on instruction",
        "          boundaries of this transcription; it starts exactly where",
        "          DrawbarRowOffsets ends and ends where DL_Flag2896b5_Set",
        "          begins.",
        "Unknown: what indexes it.  No `add XWA,0x00f542d1` occurs in either",
        "         image, so its reader computes the address.")

    objc(0xF546A4, "DLTableB_SignedNibble",
        *(["DLTableB_SignedNibble -- 16 two-character cells, `%s`"
           % txt(0xF546A4, 32)]
          + wrap("Read by: ",
                 "the four op-02 records of DL_DrawbarParamValues, each of "
                 "which carries 0x00F546A4 at +7 and an entry width of 2 at "
                 "+0x0B.  DLB_Handler_StringTable is the interpreter-B handler "
                 "for opcode 02 (see FINDINGS-ui-display-list-interpreter-b.md).")
          + wrap("Entries: ",
                 "16 x 2 = 32 bytes, and 16 is what the records' mask says "
                 "(0x0F, and 0xF0 with shift 4).  Cell k reads ' 0' for k = 0, "
                 "'+1'..'+7' for k = 1..7 and '-8'..'-1' for k = 8..15 -- the "
                 "4-bit two's-complement value, printed with a sign.")))

    objc(0xF546DA, "ParamCursorRects",
        *(["ParamCursorRects -- 4 entries of four 16-bit words"]
          + wrap("Read by: ",
                 "DL_ParamCursorBar's two records, opcodes 08 and 03, whose "
                 "handler DLB_Handler_Array8 (0xF31B57) does `sla 3,HL` before "
                 "indexing -- which is what fixes the entry at 8 bytes -- and "
                 "then four `ld BC,(XIX+n)` at n = 0, 2, 4, 6.")
          + wrap("Entries: ",
                 "4, and 4 is what the records' mask says (0x03).  The words "
                 "are (0x0029, y, 0x0110, y+15) for y = 0x80, 0x95, 0xAA, 0xBF "
                 "-- first and third constant, second and fourth 15 apart, y "
                 "stepping 21: four horizontal bands, one per parameter row of "
                 "DL_DrawbarSettingPage.")
          + wrap("Unknown: ",
                 "what `swi 7` functions 0x1B and 0x05 do with the four words. "
                 "The geometry above is arithmetic, not a decoded service.")))

    objc(0xF54710, "ParamCursorRect_Single",
        "ParamCursorRect_Single -- one 8-byte entry, words 0x000B 0x0045",
        "          0x008D 0x0050",
        "Read by: DL_F546FA and DL_F54705, both with mask 0x00 -- so the entry",
        "         index is always 0 and this array has exactly one entry.",
        "Evidence: the two records carry 0x00F54710 at +7 and 0x00 at +4;",
        "          0xF54710 + 8 = 0xF54718, where Bitmap_F54718 begins.")

    for a, w, h in BITMAPS:
        nm = "Bitmap_%06X_%dx%d" % (a, w * 8, h)
        objc(a, nm,
            *(["%s -- %d bytes: %d bytes per row x %d rows" % (nm, w * h, w, h)]
              + wrap("Read by: ",
                     "an opcode-03 interpreter-A record, whose handler "
                     "DLHandler_FarPtr (0xF31ABE) loads XIY from +2, IX from "
                     "+6, BC from +8 and HL from +10 -- so BC IS the width in "
                     "bytes and HL the row count.  The record that names this "
                     "one carries BC = %d and HL = %d." % (w, h))
              + wrap("Evidence: ",
                     "%d x %d = %d and 0x%06X + %d = 0x%06X, the next object "
                     "in address order." % (w, h, w * h, a, w * h, a + w * h))))

    for base, tag in ((SPRITE_A, "A"), (SPRITE_B, "B")):
        objc(base, "Bitmap_Drawbar%s" % tag,
            *(["Bitmap_Drawbar%s -- one drawbar sprite: 3 slices of %d bytes"
               % (tag, SLICE)]
              + wrap("Read by: ",
                     "Drawbar_DrawColumn, as `base + DrawbarRowOffsets[value]`, "
                     "blitted three times 1 byte x 0x%02X rows with the source "
                     "advanced by %d between slices -- so the drawn image is 24 "
                     "pixels wide and %d rows tall, taken out of a %d-row slice."
                     % (WINDOW, SLICE, WINDOW, SLICE))
              + wrap("Used by: ",
                     "the %s footages -- %s."
                     % ("integer" if tag == "A" else "fractional",
                        ", ".join(FOOTAGE[i] for i, r in enumerate(db)
                                  if r[6] == base)))
              + wrap("Evidence: ",
                     "3 x %d = %d and 0x%06X + %d = 0x%06X, the next object in "
                     "address order.  The 110 zero bytes that end each slice "
                     "are what the %d-row window leaves unused at offset 0."
                     % (SLICE, 3 * SLICE, base, 3 * SLICE, base + 3 * SLICE,
                        WINDOW))))

    objc(DUP_AT, "Bitmap_F54D7E_Duplicate",
        *(["Bitmap_F54D7E_Duplicate -- 228 bytes byte-identical to "
           "Bitmap_%06X_%dx%d" % (BITMAPS[2][0], BITMAPS[2][1] * 8, BITMAPS[2][2])]
          + wrap("Evidence: ",
                 "the 228-byte block occurs exactly TWICE in the whole prom_b "
                 "image, at 0x%06X and here; nothing in either image names this "
                 "copy." % BITMAPS[2][0])
          + wrap("Unknown: ",
                 "how it got here, and what the 10 bytes and 110 zero bytes in "
                 "front of it are.  prom_b already carries one dead duplicate "
                 "of exactly this kind -- Table_F4EF40, 36 bytes identical to "
                 "0xF4EF1C with no reference anywhere -- so this is recorded "
                 "and not explained.")))

    objc(0xF4FF61, "LinkTable_F4FF61",
        *(["LinkTable_F4FF61 -- 782 records of `[u16 key][u32 next]`"]
          + wrap("Evidence: ",
                 "%d of the %d `next` pointers are non-zero and ALL %d of them "
                 "land exactly on a record boundary of this table -- the rule "
                 "the layout's link_tables() walks, whose null corpus is "
                 "107,345 bytes of proven prom_b instruction text on which it "
                 "fires zero times."
                 % (link_stats()[1], link_stats()[0], link_stats()[1]))
          + wrap("Read by: ",
                 "prom_a 0xFB63FC does `add XBC,0x00f5115b`, and 0xF5115B is "
                 "record %d of this table exactly -- so prom_a indexes a "
                 "sub-array that begins %d records in."
                 % ((0xF5115B - 0xF4FF61) // 6, (0xF5115B - 0xF4FF61) // 6))
          + wrap("Unknown: ",
                 "what the keys mean.  %d distinct keys over %d records, "
                 "spanning 0x0000-0xFFFF.  The traversal that follows `next` is "
                 "not located." % (len(set(link_keys())), link_stats()[0]))))

    objc(RECARR_LO, "RecordArray_F511DD",
        *(["RecordArray_F511DD -- 110 variable-length records, framed by "
           "RecordIndex_F51E8A"]
          + wrap("★ CORRECTION C5: ",
                 "the layout's HOLES table says \"the record boundary is not "
                 "pinned by anything this lane could measure\".  It is pinned. "
                 "The 225 entries of RecordIndex_F51E8A resolve to 110 distinct "
                 "addresses, every one of them inside this segment, and %d of "
                 "the 110 carry the prom_a callback word 0x00FB4D61 or "
                 "0x00FB4D62 at exactly +0x10.  Those 110 ARE the record "
                 "starts." % record_callback_hits())
          + wrap("Record shape: ",
                 "16 parameter bytes, then three 32-bit prom_a pointers at "
                 "+0x10, +0x14 and +0x18, then 0 or more trailing bytes.  "
                 "Head-to-head strides: %s."
                 % ", ".join("%d x%d" % (s, n) for s, n in
                             sorted(record_strides().items(),
                                    key=lambda kv: -kv[1])))
          + wrap("⚠ The one exception: ",
                 "0xF514B9 carries the callback at +0x12, not +0x10, and sits 2 "
                 "bytes in front of 0xF514BB, which is also an index entry.  "
                 "Reported, not smoothed.")
          + wrap("Unknown: ",
                 "what the 16 parameter bytes mean, and why the first 28 bytes "
                 "of the segment (0x%06X-0x%06X) are in front of the first "
                 "record." % (RECARR_LO, record_starts()[0] - 1))))

    objc(RECTAB, "RecordIndex_F51E8A",
        "RecordIndex_F51E8A -- 225 pointers into RecordArray_F511DD",
        "Evidence: all 225 entries land inside 0xF511DD-0xF51E1F, and they",
        "          resolve to 110 distinct addresses; 0xF51E8A + 225*4 =",
        "          0xF5220E, exactly where the 0x0E padding run begins.",
        "Read by: prom_a spells 8 addresses inside it (`add XWA,0x00f51e8e`",
        "         at 0xFB3578 and seven more at a 0x5C/0x50 spacing), so the",
        "         225 entries are read as several sub-arrays, not one.",
        "Unknown: where each sub-array starts and how long it is.")

    objc(0xF51E88, "RecordIndex_Count",
        "RecordIndex_Count -- the two bytes 0x%02X 0x%02X in front of"
        % (by(0xF51E88), by(0xF51E89)),
        "          RecordIndex_F51E8A",
        "Evidence: prom_a 0xFB4288 does `add XBC,0x00f51e88`.",
        "Unknown: 0x%04X is not 225, so it is NOT the entry count of the table"
        % u16(0xF51E88),
        "         behind it.  The layout's HOLES table calls it \"a count word\";",
        "         that reading is not supported and is corrected here to a",
        "         stated gap.")

    objc(0xF4FA9B, "ByteMap_F4FA9B",
        "ByteMap_F4FA9B -- 129 strictly increasing bytes, 0x%02X..0x%02X"
        % (by(0xF4FA9B), by(0xF4FA9B + 128)),
        "Read by: prom_a 0xFB3AE2, `add XWA,0x00f4fa9c` (x2) -- one byte PAST",
        "         the run's start, so the map prom_a indexes is the 128-entry",
        "         tail and 0xF4FA9B is its element -1.",
        "Evidence: the layout's monotone_maps() rule, whose null corpus is the",
        "          proven instruction text of prom_b.")

    objc(0xF511C7, "AsciiRun_F511C7",
        "AsciiRun_F511C7 -- 22 bytes that are printable but are not text:",
        "          %r" % txt(0xF511C7, 22),
        "Read by: prom_a 0xFB7E54, `add XWA,0x00f511c7` -- an indexed table,",
        "         not a string.",
        "Evidence: the layout's ascii rule fires on it at threshold 20; the",
        "          bytes are 0x21-0x24, i.e. a small-integer map that happens",
        "          to fall in the printable range.  Named for what it IS.")

    # romtab / ptrtab objects: one label per address prom_a actually names
    for k, a, n in segs:
        if k not in ("romtab", "ptrtab", "ramtab"):
            continue
        named = sorted(x for x in par if a <= x < a + n and (x - a) % 4 == 0)
        starts = named or [a]
        if starts[0] != a:
            starts.insert(0, a)
        for i, s in enumerate(starts):
            e = starts[i + 1] if i + 1 < len(starts) else a + n
            if s in LABELS:
                continue
            vals = [u32(s + 4 * j) for j in range((e - s) // 4)]
            ina = sum(1 for v in vals if A_BASE <= v < 0x1000000)
            inb = sum(1 for v in vals if B_BASE <= v < A_BASE)
            objc(s, "PtrTable_%06X" % s,
                *(["PtrTable_%06X -- %d 32-bit pointers, %d into prom_a and %d "
                   "into prom_b" % (s, len(vals), ina, inb)]
                  + wrap("Read by: ",
                         ("; ".join("prom_%s 0x%06X `%s`" % (im, si, tx)
                                    for im, si, tx in par[s][:3]))
                         if s in par else
                         "NOTHING NAMES THIS ADDRESS.  It is the head of the "
                         "segment; the addresses prom_a does name inside it are "
                         "labelled below.")
                  + wrap("Entry count: ",
                         "%d, measured by abutment: the next address prom_a "
                         "names is 0x%06X and %d x 4 = %d bytes reaches it "
                         "exactly." % (len(vals), e, len(vals), 4 * len(vals)))))

    # every remaining routine entry gets sub_XXXXXX with its evidence
    for a in sorted(ev):
        if a in LABELS or a not in bnd:
            continue
        LABELS[a] = "sub_%06X" % a
        H(a, "sub_%06X" % a,
          *(wrap("Called from: ", "; ".join(ev[a]))
            + wrap("Evidence: ",
                   "0x%06X is an instruction boundary of this transcription, "
                   "re-asserted on every emit, and the reference above names "
                   "it.  That is ALL the name rests on -- the name IS the "
                   "address." % a)
            + wrap("Unknown: ",
                   "what the routine is FOR.  Left as sub_XXXXXX with the gap "
                   "stated, per this tree's rule that a stated gap beats a "
                   "plausible guess.")))


# ------------------------------------------------------------ small helpers
def dl_end(s):
    for k, a, n in layout():
        if a <= s < a + n:
            if k == "dl":
                nxt = [x for x in sorted(LDL) if a <= x < a + n and x > s]
                return nxt[0] if nxt else a + n
            return a + n
    raise AssertionError


LDL = (0xF542ED, 0xF54305, 0xF54311, 0xF54331, 0xF543B0, 0xF543C4, 0xF543D6,
       0xF54416, 0xF544AD, 0xF544EB, 0xF54668, 0xF546C4, 0xF54705)


def link_keys():
    n = (0xF511B5 - 0xF4FF61) // 6
    return [u16(0xF4FF61 + 6 * i) for i in range(n)]


def link_stats():
    lo, hi = 0xF4FF61, 0xF511B5
    n = (hi - lo) // 6
    ptr = [u32(lo + 6 * i + 2) for i in range(n)]
    nz = [p for p in ptr if p]
    on = sum(1 for p in nz if lo <= p < hi and (p - lo) % 6 == 0)
    return n, len(nz), on


def record_strides():
    st = collections.Counter()
    r = record_starts()
    for i in range(len(r) - 1):
        st[r[i + 1] - r[i]] += 1
    return st


# ------------------------------------------------------------------ emission
def hdr_lines(a):
    if a not in HEADERS:
        return []
    out = ["", "; " + "-" * 74]
    for l in HEADERS[a]:
        out.append(("; " + l).rstrip())
    out.append("; " + "-" * 74)
    return out


def label_line(a, th):
    tag = ""
    if a in th:
        tag = "\t\t; <- " + ", ".join("T_%06X" % x for x in th[a])
    return "%s:%s" % (LABELS[a], tag)


def emit_code(a, e, th):
    out = []
    for addr, ln, _t in code_rows():
        if not (a <= addr < e):
            continue
        if addr in LABELS:
            out += hdr_lines(addr)
            out.append(label_line(addr, th))
        out.append(ln)
    return out


def byte_rows(a, e, breaks, width=16, note=None):
    out, x = [], a
    while x < e:
        stop = min(x + width, e)
        for y in range(x + 1, stop):
            if y in breaks:
                stop = y
                break
        row = sl(x, stop - x)
        c = "   ; %06X  %s" % (x, txt(x, stop - x))
        if note:
            c += "  " + note(x)
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in row) + c)
        x = stop
    return out


def emit_generic(a, e, th, breaks, width=16, note=None):
    out, x = [], a
    stops = sorted(y for y in breaks if a < y < e)
    for s in [a] + stops:
        t = next((y for y in stops if y > s), e)
        if s in LABELS:
            out += hdr_lines(s)
            out.append(label_line(s, th))
        out += byte_rows(s, t, breaks, width, note)
    return out


def emit_longs(a, e, th):
    out, x = [], a
    base = a
    while x < e:
        if x in LABELS:
            out += hdr_lines(x)
            out.append(label_line(x, th))
            base = x
        v = u32(x)
        tag = ""
        if v in LABELS:
            tag = "   -> %s" % LABELS[v]
        elif LO <= v < HI:
            tag = "   -> 0x%06X" % v
        elif A_BASE <= v < 0x1000000:
            tag = "   -> prom_a 0x%06X" % v
        elif B_BASE <= v < A_BASE:
            tag = "   -> prom_b 0x%06X" % v
        out.append("\t.long 0x%08X                       ; %06X  [%d]%s"
                   % (v, x, (x - base) // 4, tag))
        x += 4
    return out


def emit_link(a, e, th):
    out = []
    if a in LABELS:
        out += hdr_lines(a)
        out.append(label_line(a, th))
    for i, x in enumerate(range(a, e, 6)):
        k, p = u16(x), u32(x + 2)
        rec = "" if not p else ("-> rec %d" % ((p - a) // 6) if a <= p < e
                                else "-> 0x%06X" % p)
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in sl(x, 6))
                   + "   ; %06X  [%3d] key 0x%04X  %s" % (x, i, k, rec))
    return out


HANDLER_A, HANDLER_B = 0xF31D21, 0xF31DB1


def emit_dl(s, e, th, interp):
    out = []
    if s in LABELS:
        out += hdr_lines(s)
        out.append(label_line(s, th))
    tab = HANDLER_B if interp == "B" else HANDLER_A
    for a, op, n in dl_records(s, e):
        h = u32(tab + 4 * op)
        out.append("\t.byte 0x%02x, 0x%02x\t; %06X  op %02X, %d bytes -> "
                   "handler 0x%06X" % (op, n, a, op, n, h))
        body, pos = a + 2, a + n
        if interp == "B":
            out.append("\t.short 0x%04X\t\t; +2  RAM variable" % u16(a + 2))
            out.append("\t.byte 0x%02x, 0x%02x\t; +4  mask, shift"
                       % (by(a + 4), by(a + 5)))
            out.append("\t.byte 0x%02x\t\t; +6  swi 7 function" % by(a + 6))
            out.append("\t.long 0x%08X\t; +7  -> %s"
                       % (u32(a + 7), LABELS.get(u32(a + 7),
                                                 "0x%06X" % u32(a + 7))))
            body = a + 11
        elif op in (0x03, 0x04):
            src = u32(a + 2)
            out.append("\t.long 0x%08X\t; +2  source -> %s"
                       % (src, LABELS.get(src, "0x%06X" % src)))
            out.append("\t.short 0x%04X\t\t; +6  IX  (screen position)" % u16(a + 6))
            out.append("\t.short 0x%04X\t\t; +8  BC  (%d bytes per row)"
                       % (u16(a + 8), u16(a + 8)))
            out.append("\t.short 0x%04X\t\t; +10 HL  (%d rows)"
                       % (u16(a + 10), u16(a + 10)))
            body = a + 12
        elif op in (0x17, 0x1C):
            out.append("\t.short 0x%04X, 0x%04X\t; +2  the two words"
                       % (u16(a + 2), u16(a + 4)))
            body = a + 6
        elif op in (0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E,
                    0x1F, 0x20, 0x21):
            out.append("\t.short 0x%04X\t\t; +2  IX (screen position)" % u16(a + 2))
            body = a + 4
        if body < pos:
            t = txt(body, pos - body)
            if all(32 <= c < 127 for c in sl(body, pos - body)) \
                    and '"' not in t and "\\" not in t:
                out.append("\t.ascii \"%s\"\t; +%d" % (t, body - a))
            else:
                out.append("\t.byte " + ", ".join("0x%02x" % b
                                                  for b in sl(body, pos - body))
                           + "\t; +%d  %r" % (body - a, t))
    return out


def emit():
    structure()
    segs, th = layout(), thunks()
    breaks = set(LABELS) | set(record_starts()) | {DUP_AT}
    for b, _t in ((SPRITE_A, 0), (SPRITE_B, 0)):
        for k in range(1, 3):
            breaks.add(b + k * SLICE)
    out = []
    for kind, a, n in segs:
        e = a + n
        if kind == "code":
            out += emit_code(a, e, th)
            continue
        out.append("")
        out.append("; --- 0x%06X-0x%06X  %s (%d bytes) ---" % (a, e - 1, kind, n))
        if kind == "fill":
            vals = set(sl(a, n))
            if len(vals) != 1:
                sys.exit("REFUSING TO EMIT: 0x%06X-0x%06X is not one value"
                         % (a, e))
            out.append("\t.fill\t%d, 1, 0x%02X\t; asserted a single value"
                       % (n, vals.pop()))
        elif kind in ("romtab", "ptrtab", "ramtab"):
            out += emit_longs(a, e, th)
        elif kind == "link":
            out += emit_link(a, e, th)
        elif kind == "dl":
            for s in sorted(x for x in LDL if a <= x < e) or [a]:
                out += emit_dl(s, dl_end(s), th,
                               "B" if s >= 0xF54668 else "A")
        elif a in (0xF542E1, 0xF542F9):
            out += emit_dl(a, e, th, "A")
        elif a == 0xF546DA:
            out += emit_generic(a, 0xF546FA, th, breaks, 8)
            out += emit_dl(0xF546FA, e, th, "B")
        else:
            out += emit_generic(a, e, th, breaks, 16)
    return out


# ------------------------------------------------------------------ selftest
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-22s %s" % (msg, repr(got)[:22],
                                "OK" if ok else "FAILED (want %r)" % (want,)))
    if not ok:
        FAIL.append(msg)


def selftest():
    del FAIL[:]
    segs = layout()
    structure()
    db, off = drawbars(), rowoffsets()

    print("A. the layout has not moved")
    check("segments", len(segs), EXPECTED)
    check("they tile the span", sum(n for _k, _a, n in segs), EXPECTED_BYTES)
    check("first segment starts at LO", segs[0][1], LO)
    check("LAST segment ends at HI", segs[-1][1] + segs[-1][2], HI)
    check("bytes by kind", dict(collections.Counter(
        {k: 0 for k, _a, _n in segs}) | {}) is not None, True)

    print("B. the code really rebuilds the ROM")
    for kind, a, n in segs:
        if kind != "code":
            continue
        got = RT.assemble_block("\t.text\n" + "\n".join(transcribe(a, n)) + "\n")
        check("  code 0x%06X-0x%06X reassembles" % (a, a + n - 1),
              got == sl(a, n), True)
    b = boundaries()
    check("every thunk target is an instruction boundary",
          sorted("0x%06X" % t for t in thunks() if t not in b), [])
    last = max(thunks())
    check("the LAST thunk target (0x%06X) is on a boundary" % last, last in b, True)
    dsp = [v for v in dispatch(0xF54248, 23) if LO <= v < HI]
    check("every in-span DispatchTable_F54248 entry is on a boundary",
          sorted("0x%06X" % v for v in dsp if v not in b), [])
    check("  and so is the LAST of them (0x%06X)" % max(dsp), max(dsp) in b, True)
    d2 = [v for v in dispatch(0xF542D1, 4) if LO <= v < HI]
    check("every DispatchTable_F542D1 entry is on a boundary",
          sorted("0x%06X" % v for v in d2 if v not in b), [])

    print("C. the entry-point citations are at INSTRUCTION addresses")
    bad = [a for t, ss in internal_calls().items() for a in ss if a not in b]
    check("every cited call site is an instruction start", bad, [])
    check("  sites cited", sum(len(v) for v in internal_calls().values()) > 0, True)

    print("D. the proven prom_a references (the layout never prints these)")
    par = prom_a_refs()
    check("distinct in-span addresses prom_a/prom_b name", len(par), 81)
    check("reference lines", sum(len(v) for v in par.values()), 134)
    check("all of them are in prom_a",
          sorted({im for v in par.values() for im, _s, _t in v}), ["a"])
    check("CORRECTION C1: points named inside 0xF4FA7A-0xF4FA9A",
          sum(1 for a in par if 0xF4FA7A <= a <= 0xF4FA9A), 8)
    check("  and 0xF4FA7A itself is NOT one of them", 0xF4FA7A in par, False)
    check("CORRECTION C2: distinct addresses named inside 0xF4FE38-0xF4FF60",
          sum(1 for a in par if 0xF4FE38 <= a <= 0xF4FF60), 29)

    print("E. the nine drawbars")
    check("nine routines", len(db), 9)
    check("screen columns", [r[5] for r in db], list(range(3, 3 + 9 * 4, 4)))
    check("RAM value bytes", ["0x%04X%s" % (r[2], r[3]) for r in db],
          ["0x2897lo", "0x2898lo", "0x2897hi", "0x2898hi", "0x2899lo",
           "0x2899hi", "0x289Alo", "0x289Ahi", "0x289Blo"])
    check("target bytes are the value bytes minus 5",
          [r[4] for r in db], [r[2] - 5 for r in db])
    check("sprite A <=> the footage is an integer",
          [r[6] == SPRITE_A for r in db],
          ["/" not in f for f in FOOTAGE])
    calls = internal_calls()
    check("E4: PaintAllDrawbars calls exactly the nine, and nothing else",
          sorted(t for t, ss in calls.items()
                 if any(0xF536FF <= x < 0xF53721 for x in ss)),
          sorted(DRAWBAR_STARTS))
    check("  the LAST drawbar (0x%06X) is one of them" % DRAWBAR_STARTS[-1],
          DRAWBAR_STARTS[-1] in calls, True)
    check("each drawbar re-arms ITSELF (its own address is an `lda XBC`)",
          all(any(t == "lda XBC,0x%06x" % r[0]
                  for a2, _l, t in code_rows() if r[0] <= a2 < r[1])
              for r in db), True)

    print("F. the footage labels, and the bijection to the columns")
    fl = footage_labels()
    check("nine numeric labels", [t for _a, _p, t in fl],
          ["16", "5", "8", "4", "2", "2", "1", "1", "1"])
    check("nine foot marks to go with them", len(foot_marks()), 9)
    check("four op-0x17 fraction labels",
          [t for _a, _x, _y, t in fraction_labels()],
          ["1/3", "2/3", "3/5", "1/3"])
    check("  the fractions belong to the four fractional footages",
          [FOOTAGE[i] for i, r in enumerate(db) if r[6] == SPRITE_B],
          ["5 1/3'", "2 2/3'", "1 3/5'", "1 1/3'"])
    p0 = fl[0][1]
    check("every label sits within one cell of its bar's column",
          [(p - p0) - (r[5] - db[0][5]) for (_a, p, _t), r in zip(fl, db)],
          [0, 0, 1, 1, 0, 1, 0, 0, 1])
    check("  the LAST label (0x%04X) belongs to the LAST bar (column %d)"
          % (fl[-1][1], db[-1][5]),
          (fl[-1][1] - p0) - (db[-1][5] - db[0][5]) in (0, 1), True)

    print("G. DrawbarRowOffsets -- CORRECTION C3")
    check("nine entries", off, [0x6E, 0x62, 0x54, 0x46, 0x38, 0x2A, 0x1C, 0x0E, 0])
    check("one step of 12 then eight of 14",
          [off[i] - off[i + 1] for i in range(8)], [12] + [14] * 7)
    check("the table ends exactly where DispatchTable_F542D1 begins",
          ROWOFF + 9, 0xF542D1)
    check("the LAST entry is the byte the layout's HOLES table never mentions",
          (ROWOFF + 8, off[8]), (0xF542D0, 0x00))
    check("the largest offset plus the blit window is one slice",
          off[0] + WINDOW, SLICE)

    print("H. the sprites and bitmaps")
    check("Bitmap_DrawbarA + 3 slices = Bitmap_DrawbarB",
          SPRITE_A + 3 * SLICE, SPRITE_B)
    check("Bitmap_DrawbarB + 3 slices = the 304x6 bitmap",
          SPRITE_B + 3 * SLICE, BITMAPS[2][0])
    for a, w, h in BITMAPS:
        check("  0x%06X: %d x %d, ending at 0x%06X" % (a, w, h, a + w * h),
              a + w * h in (0xF54790, 0xF54808, 0xF54E62), True)
    check("the 228-byte bitmap occurs exactly twice in prom_b",
          ["0x%06X" % x for x in dup_occurrences()], ["0xF54D7E", "0xF54EDA"])
    check("  the duplicate ends one byte before the 0x0E padding run",
          DUP_AT + 228, 0xF54FBE)

    print("I. the interpreter-B value cells -- the +25 pairing")
    cp = caption_pairs()
    check("four captions", [c[1].strip() for c in cp],
          ["PERCUSSIVE T0NE DECAY  :", "PERCUSSIVE T0NE LEVEL  :",
           "DRAWBAR ATTACK TIME    :", "DRAWBAR RELEASE TIME   :"])
    check("every value cell is 25 cells past its caption's start",
          [c[6] for c in cp], [25] * 4)
    check("  which is one cell past the 24-character caption",
          sorted({len(c[1]) for c in cp}), [24])
    check("the four nibbles", ["(0x%04X)&0x%02X>>%d" % (c[3], c[4], c[5])
                               for c in cp],
          ["(0x2640)&0x0F>>0", "(0x2640)&0xF0>>4",
           "(0x2641)&0xF0>>4", "(0x2641)&0x0F>>0"])
    s16 = [txt(0xF546A4 + 2 * k, 2) for k in range(16)]
    check("DLTableB_SignedNibble is the signed 4-bit value with a sign",
          s16, [" 0"] + ["+%d" % k for k in range(1, 8)]
          + ["-%d" % k for k in range(8, 0, -1)])
    check("  and the LAST cell is '-1'", s16[-1], "-1")

    print("J. the record array -- CORRECTION C5")
    rs = record_starts()
    check("225 index entries", RECTAB_N, 225)
    check("all of them land inside the record array",
          all(RECARR_LO <= u32(RECTAB + 4 * i) < RECARR_HI
              for i in range(RECTAB_N)), True)
    check("110 distinct record starts", len(rs), 110)
    check("109 carry the prom_a callback at +0x10", record_callback_hits(), 109)
    check("  the one exception is 0xF514B9", 
          [x for x in rs if u32(x + 0x10) not in CALLBACKS], [0xF514B9])
    check("  and its callback is at +0x12 instead", u32(0xF514B9 + 0x12) in CALLBACKS, True)
    check("the LAST record start is 0xF51DF8", "0x%06X" % rs[-1], "0xF51DF8")
    check("  and it too carries the callback at +0x10",
          u32(rs[-1] + 0x10) in CALLBACKS, True)
    check("the dominant stride is 28", record_strides().most_common(1)[0], (28, 99))
    check("RecordIndex_F51E8A ends where the padding run begins",
          RECTAB + 4 * RECTAB_N, 0xF5220E)

    print("K. the link table")
    n, nz, on = link_stats()
    check("782 records of 6 bytes", n, 782)
    check("non-zero next pointers", nz, 779)
    check("all of them land on a record boundary of the table", on, nz)
    check("prom_a's base 0xF5115B is record 767", (0xF5115B - 0xF4FF61) // 6, 767)

    print("L. CORRECTION C4 -- 0xF542E1 is call-site proven")
    at = code_at()
    check("`lda XBC,0xf542ed` at 0xF5383B", at.get(0xF5383B), "lda XBC,0xf542ed")
    check("`lda XWA,0xf542e1` at 0xF53841", at.get(0xF53841), "lda XWA,0xf542e1")
    check("`call 0xf42e00` two instructions later", at.get(0xF53855),
          "call 0xf42e00")
    check("the selecting test is `and C,0x20` at 0xF53836",
          at.get(0xF53836), "and C,0x20")

    print("M. the emitted text rebuilds the span")
    body = emit()
    got = RT.assemble_block("\t.text\n" + "\n".join(body) + "\n")
    check("assembles", got is not None, True)
    check("byte-identical to the ROM", got == sl(LO, HI - LO), True)

    print("\n%d checks, %d failures" % (n_checks(), len(FAIL)))
    for m in FAIL:
        print("  FAILED: %s" % m)
    return 1 if FAIL else 0


_NCHK = [0]


def n_checks():
    return _NCHK[0]


_check_raw = check


def check(msg, got, want):          # noqa: F811  (counted wrapper)
    _NCHK[0] += 1
    return _check_raw(msg, got, want)


# ----------------------------------------------------------------------- CLI
def refs_mode():
    par = prom_a_refs()
    kind = {}
    for k, a, n in layout():
        for x in range(a, a + n):
            kind[x] = k
    print("addresses in 0x%06X-0x%06X named by an instruction already in the .s:"
          % (LO, HI))
    print("  %d distinct addresses, %d reference lines"
          % (len(par), sum(len(v) for v in par.values())))
    for a in sorted(par):
        im, site, t = par[a][0]
        print("  0x%06X  %-7s x%-2d  prom_%s 0x%06X  %s"
              % (a, kind.get(a, "?"), len(par[a]), im, site, t))


def drawbars_mode():
    structure()
    off = rowoffsets()
    print("  #  footage   entry     value nibble   target nibble  col  sprite")
    for i, (s, e, ram, nib, tgt, col, base) in enumerate(drawbars()):
        print("  %d  %-8s 0x%06X  (0x%04X) %s      (0x%04X) %s      %2d   %s"
              % (i + 1, FOOTAGE[i], s, ram, nib, tgt, nib, col,
                 "A" if base == SPRITE_A else "B"))
    print("  DrawbarRowOffsets 0x%06X: %s"
          % (ROWOFF, " ".join("0x%02X" % v for v in off)))


def main():
    segs = layout()
    if "--check" in ARGV:
        print("layout OK: %d segments tiling 0x%06X-0x%06X"
              % (len(segs), LO, HI))
        return 0
    if "--selftest" in ARGV:
        return selftest()
    if "--refs" in ARGV:
        refs_mode()
        return 0
    if "--drawbars" in ARGV:
        drawbars_mode()
        return 0
    body = emit()
    text = "\n".join(body)

    # THE SELF-PROOF: assemble what we are about to print, compare with the ROM.
    got = RT.assemble_block("\t.text\n" + text + "\n")
    want = sl(LO, HI - LO)
    if got != want:
        nd = -1 if got is None else sum(1 for i in range(min(len(got), len(want)))
                                        if got[i] != want[i])
        sys.exit("REFUSING TO PRINT: the emitted text does not rebuild the span "
                 "(%s, %d differing bytes)"
                 % ("assembly failed" if got is None
                    else "len %d vs %d" % (len(got), len(want)), nd))
    if "--stats" in ARGV:
        c = collections.Counter(k for k, _a, _n in segs)
        b = collections.Counter()
        for k, _a, n in segs:
            b[k] += n
        sem = [v for a, v in LABELS.items() if not v.startswith("sub_")]
        print("segments by kind:", dict(c))
        print("bytes by kind:   ", dict(b))
        print("labels: %d  (%d semantic, %d sub_XXXXXX)"
              % (len(LABELS), len(sem), len(LABELS) - len(sem)))
        print("  of the %d semantic names, %d are CONTENT-derived and %d are "
              "structural (an address in the name)"
              % (len(sem), len(CONTENT_NAMED),
                 len(sem) - len(CONTENT_NAMED)))
        ev = sum(1 for a, h in HEADERS.items()
                 if any(l.startswith("Evidence:") or "Evidence: " in l
                        for l in h))
        print("headers: %d; of which carry an Evidence: line: %d"
              % (len(HEADERS), ev))
        print("emitted lines: %d; re-assembles to the ROM exactly" % len(body))
        return 0
    print("; ==== 0xF4F000-0xF54FFF -- emitted by "
          "notes/gen_prom_b_f4f000_module.py ====")
    print("; Layout from notes/prom_b_f4f000_layout.py (43 segments, unchanged);")
    print("; names and counts from this emitter's --selftest.  Run it before")
    print("; trusting any number in a header below.  This text was assembled and")
    print("; byte-compared with the ROM before printing.")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
