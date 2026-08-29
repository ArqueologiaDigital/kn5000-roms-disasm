#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF17559-0xF1B3FF -- the COMBINATION / INTERNAL
SOUND / MIDI SOUND parameter screens, their operand tables and their strings.
Wave 7 round 3, lane WRITER-B.

QUESTION IT ANSWERS
    "What is the assembly text for this 16,039-byte `.incbin` span, in a form the
     byte gate accepts, with the EIGHT corrections wave 7 round 2 established
     applied -- and with every label attached to the right address?"
    This is the emitter whose output is spliced into prom_b/wsa1_prom_b.s.

WHERE THE BOUNDARIES COME FROM
    notes/prom_b_f17559_layout.py, re-derived on EVERY run.  The span holds NO
    CODE: exactly thirteen in-span addresses are the target of a transfer
    anywhere in the four `.s` files and all thirteen are `jp` slots of one STALE
    thunk run, so the layout runs no decode at all.  Its boundaries come from
    proven operands, display-list call sites, `ldir` copy lengths and record
    framing walks.  This emitter refuses to print if the pre-correction segment
    count moved.

★ THE EIGHT CORRECTIONS, from notes/prom_b_f17559_reaudit.py --verdict
    They are applied HERE, as a post-pass over the layout's segment list, and
    each is re-derived by --selftest.  ⚠ notes/prom_b_f17559_layout.py is NOT
    edited by this lane -- another lane may be running it.

    C1  0xF1A037-0xF1A0BE is ONE interpreter-B record_array of 8 x 17, not two
        objects.  0xF1A048 is the STRIDE OPERAND of the loop in prom_a's
        sub_FBF79C -- `lda_24 xwa,(0xf1a037)` at 0xFBF7C9, `lda_24
        xix,(0xf1a048)` at 0xFBF7D1, `sub XIX,XWA` at 0xFBF7D6 -- not a
        boundary, and 0xF1A037 + 8*17 = 0xF1A0BF lands on the next proven run.
    C2  0xF1814E and 0xF181D6 are interpreter B, not AMBIG: the routine that
        runs them loads `lda XIX,0x00F42E04` at prom_a 0xFBE2EC and reaches the
        interpreter with `jp (XIX)` at 0xFBE32A and 0xFBE34E.
    C3  0xF17C00 is an interpreter-A op-0E record -- byte-identical to the
        one-record list at 0xF18CD5 that prom_a 0xFBD235 runs with a literal
        `call 0xf42e00`, and the 8-byte pattern occurs exactly twice in the
        image -- but NOTHING executes it.  Emitted UNREACHED, and the layout's
        evidence string "both ends are E0 references" is dropped: the low end is
        a CONTENT boundary, the end of the 4-glyph copy above it.
    C4  0xF1A14D is honestly UNRESOLVED.  It is a well-formed interpreter-B
        op-08 record and its only reference anywhere is as the END address of
        the run at 0xF1A137 -- i.e. one past the last byte that run's
        interpreter reads.  No mechanism is invented for it.
    C5  0xF17C59-0xF17C8B is a BITMAP, 3 bytes x 17 rows = 24 px x 17, sized by
        the BC and HL fields of the op-03 record at 0xF1AAA9.  `index_map` is
        wrong.
    C6  0xF1A62F-0xF1A7AE is the MIDI NOTE-NAME table: 128 entries x 3
        characters, note 0 `C-2` through note 127 `G 8`, with 0x88 for flat and
        0x8C for sharp.  It is NOT `ascii` (53 of the 128 entries carry a byte
        >= 0x80) and it is not an index map -- it is DRAWN, by swi-7 function 6.
    C7  0xF185FD-0xF1881C is FOUR arrays of eight 17-byte records, not one array
        of 32; the four pointer tables that address them are 0xF1B04B, 0xF1B10B,
        0xF1B0AB and 0xF1B12B, and the splits are at 0xF18685, 0xF1870D and
        0xF18795.
    C8  the `.incbin` block header already in prom_b/wsa1_prom_b.s says 0xF17A6C
        holds "a 24-entry array of pointers spaced 0x48".  The STRIDE is right
        and the COUNT is 29.  Corrected in the .s in the same edit that splices
        this text.

    ⚠ 19 BYTES -- 0xF17C00 (8) and 0xF1A14D (11), 0.12% of the span -- are
    reached by NOTHING the census sees.  They are marked UNREACHED in the source
    rather than hidden.  "Unreached" is a statement about the census: the four
    call shapes it knows are in notes/prom_b_dl_call_shapes.py, and this span
    alone needed a fifth (C1's stride loop) to be found by hand.

★ THE NAMING RULE
    A label gets a name derived from DECODED CONTENT or from a MEASURED shape,
    never from a purpose.  Display lists are named after the longest run of
    letters their own records carry -- so `DL_InternalSound` is the text in the
    ROM, not a reading of it -- and a list with no such text keeps `DL_XXXXXX`,
    the convention the 585 display lists already in this file use.  `--stats`
    reports how many names are placeholders of that kind, because the goal
    metric counts `DL_XXXXXX` as "semantic" and it states nothing.

WHAT MUST NOT BE CLAIMED (from the round-2 verdict, repeated here)
    * that 0xF17C00 or 0xF1A14D is drawn by the machine;
    * that the record LENGTH rule resolved any interpreter -- it misclassifies
      23 of the 4,097 records whose interpreter is known, six of them the exact
      shape of C2's runs;
    * a record count for this span other than 711, or a run count other than 121.

⚠ WHAT SPLICING THIS REGION BREAKS, AND WHY NONE OF IT IS A DEFECT
    Measured immediately after the splice:

      notes/prom_b_f17559_layout.py --selftest   2 failures, both of them
        `prom_b_dl_call_shapes.py --new` counts: "runs and bytes IN THIS SPAN"
        reads (0, 0) for (25, 3157) and "out of, in the whole image" reads
        (11, 1269) for (41, 5247).  That tool counts call-shape runs that point
        at bytes STILL `.incbin`; converting this span (and 0xF4F000 in the same
        round) is precisely what makes those numbers fall.  A frontier count
        that drops after a conversion is the conversion working.

      notes/prom_b_f17559_reaudit.py --selftest   0 failures.  It was written
        against the ROM rather than against the frontier, and survives.

    This emitter is immune: its layout call still returns 297 raw segments after
    the splice, and running it again reproduces its own output byte for byte.
    That was checked after the splice, not assumed.

NOTHING HERE CAN BREAK THE GATE
    Every byte is emitted from the ROM, then main() assembles the WHOLE emitted
    region and compares it byte for byte with the ROM, and exits non-zero
    WITHOUT PRINTING if it differs.

RUN
    python3 notes/gen_prom_b_f17559_module.py            # the assembly
    python3 notes/gen_prom_b_f17559_module.py --check    # layout fingerprint
    python3 notes/gen_prom_b_f17559_module.py --stats    # segment/label census
    python3 notes/gen_prom_b_f17559_module.py --corrections
    python3 notes/gen_prom_b_f17559_module.py --selftest # every number, re-derived
"""
import collections
import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

ARGV = list(sys.argv)

LO, HI = 0xF17559, 0xF1B400
B_BASE, A_BASE = 0xF00000, 0xF80000
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")

EXPECTED_RAW = 297            # segments as the layout prints them
EXPECTED_BYTES = HI - LO      # 16,039

HANDLER_A, HANDLER_B = 0xF31D21, 0xF31DB1
# C7: the four eight-record arrays inside 0xF185FD-0xF1881C, and their tables
C7_SPLITS = [0xF18685, 0xF1870D, 0xF18795]
C7_TABLES = [0xF1B04B, 0xF1B10B, 0xF1B0AB, 0xF1B12B]
C1_LO, C1_MID, C1_HI = 0xF1A037, 0xF1A048, 0xF1A0BF
C5_LO, C5_HI, C5_REC = 0xF17C59, 0xF17C8C, 0xF1AAA9
C6_LO, C6_N, C6_W = 0xF1A62F, 128, 3
UNREACHED = {0xF17C00: 8, 0xF1A14D: 11}


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


L = _load(os.path.join(ROOT, "notes", "prom_b_f17559_layout.py"), "f17559_layout")
RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "rt")

_D = {}


def rom(which="b"):
    if which not in _D:
        _D[which] = open(IMGB if which == "b" else IMGA, "rb").read()
    return _D[which]


def sl(a, n, which="b"):
    base = B_BASE if which == "b" else A_BASE
    return rom(which)[a - base:a - base + n]


def by(a):
    return sl(a, 1)[0]


def u16(a):
    return int.from_bytes(sl(a, 2), "little")


def u32(a):
    return int.from_bytes(sl(a, 4), "little")


def txt(a, n):
    return "".join(chr(c) if 32 <= c < 127 else "." for c in sl(a, n))


# ------------------------------------------------------------------- layout
_RAW, _SEGS = [], []


def raw_layout():
    if _RAW:
        return _RAW[0]
    segs = L.build()
    if len(segs) != EXPECTED_RAW:
        sys.exit("REFUSING TO EMIT: the layout has %d segments, expected %d.  "
                 "The boundaries moved since the round-2 re-audit; re-audit "
                 "before emitting." % (len(segs), EXPECTED_RAW))
    tot = sum(n for _k, _a, n, _e in segs)
    if segs[0][1] != LO or tot != EXPECTED_BYTES:
        sys.exit("REFUSING TO EMIT: the segments do not tile the span "
                 "(%d of %d)" % (tot, EXPECTED_BYTES))
    pos = LO
    for _k, a, n, _e in segs:
        if a != pos:
            sys.exit("REFUSING TO EMIT: gap or overlap at 0x%06X" % a)
        pos = a + n
    _RAW.append(segs)
    return segs


def segments():
    """The layout with corrections C1, C2, C3, C5, C6 and C7 applied.

    Each returned row is (kind, addr, length, evidence, note) where `note` is
    the correction that touched it, or None."""
    if _SEGS:
        return _SEGS[0]
    out = []
    for kind, a, n, ev in raw_layout():
        note = None
        # C1 -- merge the stride-operand split
        if a == C1_LO:
            out.append(("record_array", C1_LO, C1_HI - C1_LO,
                        "8 records of 17 bytes, interpreter B, run ONE AT A "
                        "TIME by `call 0xf42e0c` at prom_a 0xFBF7EA",
                        "C1"))
            continue
        if a == C1_MID:
            continue                       # absorbed by C1
        # C2 -- the two AMBIG runs are interpreter B
        if a in (0xF1814E, 0xF181D6):
            out.append(("display_list", a, n,
                        ev.replace("interpreter AMBIG", "interpreter B"), "C2"))
            continue
        # C3 -- the unreached copy
        if a == 0xF17C00:
            out.append(("display_list", a, n,
                        "1 record, interpreter A by BYTE-IDENTITY with the "
                        "proven one-record list at 0xF18CD5; UNREACHED", "C3"))
            continue
        # C4 -- the one that stays unresolved, with the false evidence dropped
        if a == 0xF1A14D:
            out.append(("display_list", a, n,
                        "1 record, well-formed as interpreter B by FORMAT; "
                        "interpreter NOT RESOLVED and the run is UNREACHED -- "
                        "its only reference anywhere is as the END address of "
                        "the run at 0xF1A137", "C4"))
            continue
        # C5 -- a bitmap, not an index map
        if a == C5_LO:
            out.append(("bitmap", a, n,
                        "%d bytes per row x %d rows, from the BC and HL fields "
                        "of the op-03 record at 0x%06X"
                        % (u16(C5_REC + 8), u16(C5_REC + 10), C5_REC), "C5"))
            continue
        # C6 -- the MIDI note names
        if a == C6_LO:
            out.append(("notenames", a, n,
                        "%d entries of %d characters, note 0 %r to note %d %r"
                        % (C6_N, C6_W, txt(C6_LO, 3), C6_N - 1,
                           txt(C6_LO + 3 * (C6_N - 1), 3)), "C6"))
            continue
        # C7 -- four arrays of eight, not one of 32
        if a == 0xF185FD:
            starts = [a] + C7_SPLITS
            for i, s in enumerate(starts):
                e = starts[i + 1] if i + 1 < len(starts) else a + n
                out.append(("record_array", s, e - s,
                            "8 records of 17 bytes, addressed one at a time by "
                            "the 8 entries of the pointer table at 0x%06X"
                            % C7_TABLES[i], "C7"))
            continue
        out.append((kind, a, n, ev, note))
    _SEGS.append(out)
    return out


# ------------------------------------------------------------- the interpreter
_INTERP = re.compile(r"interpreter (A|B|AMBIG)")


def interp_of(ev):
    m = _INTERP.search(ev)
    return m.group(1) if m else None


def dl_records(s, e):
    recs, a = [], s
    while a < e:
        n = by(a + 1)
        if n == 0 or a + n > e:
            return None
        recs.append((a, by(a), n))
        a += n
    return recs


# --------------------------------------------------------------- the naming
STOP = {"PAGE", "ITEM", "VALUE", "OFF", "ON"}


def dl_text(s, e, interp):
    """Every character run a display list's own records carry, longest first."""
    recs = dl_records(s, e) or []
    out = []
    for a, op, n in recs:
        if interp == "B":
            continue
        if op in (0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E, 0x1F,
                  0x20, 0x21) and n > 4:
            out.append(txt(a + 4, n - 4))
        elif op in (0x17, 0x1C) and n > 6:
            out.append(txt(a + 6, n - 6))
    return out


def slug(t, limit=26):
    """CamelCase identifier from a ROM string.  Deterministic and reversible
    enough that a reader can find the string in the record below it."""
    words = re.findall(r"[A-Za-z0-9]+", t)
    # title-case EVERY word, digits included, so the ROM's `C0MBINATI0N`
    # becomes `C0mbinati0n` and keeps its zeros where the letter O should be.
    s = "".join(w[:1].upper() + w[1:].lower() for w in words)
    return s[:limit]


def dl_name(s, e, interp):
    """The name of a display list: the longest LETTER run its records carry.

    ⚠ Chosen as the LONGEST, not the first: the first is usually `PAGE1/3`,
    which names the pagination and not the page."""
    cands = [t.strip() for t in dl_text(s, e, interp)]
    # a CAPTION, not a sentence: the machine's captions are upper-case and
    # short.  The error screens carry whole sentences in mixed case ("Please
    # select either the Main or"); slugging one of those makes a label that is
    # worse than the address, so they fall through to DL_XXXXXX and the header
    # prints the sentence instead.
    cands = [t for t in cands
             if 4 <= len(t) <= 20
             and t == t.upper()
             and re.match(r"^[A-Z0-9][A-Z0-9 ./&:%+-]*$", t)
             and len(re.sub(r"[^A-Z]", "", t)) >= 4
             and re.sub(r"[^A-Z]", "", t) not in STOP]
    if not cands:
        return None
    best = max(cands, key=lambda t: (len(re.sub(r"[^A-Za-z]", "", t)), -len(t)))
    return slug(best)


LABELS = {}
HEADERS = {}
PLACEHOLDER = set()


def H(a, *lines):
    HEADERS[a] = list(lines)


def wrap(prefix, body, width=74):
    import textwrap
    pad = " " * len(prefix)
    ls = textwrap.wrap(body, width - len(prefix)) or [""]
    return [prefix + ls[0]] + [pad + l for l in ls[1:]]


# --------------------------------------------------------- shapes from evidence
_SHAPE = [
    re.compile(r"(\d+) entries of (\d+) bytes"),
    re.compile(r"(\d+) value strings of (\d+) bytes"),
    re.compile(r"(\d+) records of (\d+) bytes"),
    re.compile(r"(\d+) entries of (\d+) characters"),
    re.compile(r"(\d+) bytes per row x (\d+) rows"),
]


def shape(kind, n, ev):
    """(count, width) for a segment, taken from the layout's own evidence string
    and CHECKED against the segment length.  Returns None when the evidence
    states no shape."""
    for rx in _SHAPE:
        m = rx.search(ev)
        if m:
            c, w = int(m.group(1)), int(m.group(2))
            if kind == "bitmap":
                c, w = w, c            # "W bytes per row x H rows" -> (rows, W)
            if c * w == n:
                return c, w
            return None
    m = re.search(r"(\d+) words", ev)
    if m and int(m.group(1)) * 4 == n:
        return int(m.group(1)), 4
    return None


# ------------------------------------------------------------------ the labels
KIND_PREFIX = {"ascii": "StringTable", "index_map": "IndexMap",
               "pointer_table": "PtrTable", "bit_table": "BitTable",
               "bitmap": "Bitmap", "record": "Record",
               "record_array": "RecordArray", "unknown": "Unknown"}


def structure():
    if LABELS:
        return
    used = collections.Counter()
    names = {}
    for kind, a, n, ev, _c in segments():
        if kind == "pad":
            continue
        if kind == "notenames":
            names[a] = "MidiNoteNames"
            continue
        if kind == "display_list":
            nm = dl_name(a, a + n, interp_of(ev) or "A")
            if nm:
                used[nm] += 1
                names[a] = "DL_" + nm
            else:
                names[a] = "DL_%06X" % a
                PLACEHOLDER.add(a)
            continue
        sh = shape(kind, n, ev)
        p = KIND_PREFIX.get(kind, "Data")
        if kind == "bitmap" and sh:
            names[a] = "Bitmap_%06X_%dx%d" % (a, sh[1] * 8, sh[0])
        else:
            names[a] = "%s_%06X" % (p, a)
    # ⚠ disambiguate: eight caption slugs occur more than once in this span
    # (`MidiOutFilter` four times).  A duplicate label would not assemble, so
    # the address is appended -- and it is appended to EVERY copy, so no reader
    # has to guess which one was "first".
    dup = {v for v in names.values() if list(names.values()).count(v) > 1}
    for a, v in names.items():
        LABELS[a] = ("%s_%06X" % (v, a)) if v in dup else v

    for kind, a, n, ev, corr in segments():
        if kind == "pad":
            continue
        sh = shape(kind, n, ev)
        head = ["%s -- %s, 0x%06X-0x%06X (%d bytes)"
                % (LABELS[a], kind.replace("_", " "), a, a + n - 1, n)]
        body = []
        if kind == "display_list":
            it = interp_of(ev) or "A"
            recs = dl_records(a, a + n) or []
            body += wrap("Interpreter: ",
                         "%s.  %d record%s, framed by their own length bytes; "
                         "the walk consumes 0x%06X-0x%06X exactly."
                         % (it, len(recs), "" if len(recs) == 1 else "s",
                            a, a + n - 1))
            t = [x.strip() for x in dl_text(a, a + n, it)
                 if len(re.sub(r"[^ -~]", "", x.strip())) >= 2]
            if t:
                body += wrap("Text it draws: ", "; ".join(repr(x) for x in t))
            body += wrap("Evidence: ", ev)
        elif sh:
            c, w = sh
            body += wrap("Shape: ", "%d entries of %d byte%s = %d bytes, which "
                         "is the whole segment." % (c, w, "" if w == 1 else "s",
                                                    c * w))
            if kind in ("ascii", "notenames"):
                body += wrap("First / last: ",
                             "%r ... %r" % (txt(a, w), txt(a + (c - 1) * w, w)))
            elif kind == "pointer_table":
                v0, v1 = u32(a), u32(a + (c - 1) * 4)
                body += wrap("First / last: ", "0x%06X ... 0x%06X" % (v0, v1))
            body += wrap("Evidence: ", ev)
        else:
            body += wrap("Evidence: ", ev)
        if a in UNREACHED:
            body += wrap("⚠ UNREACHED: ",
                         "no display-list call site in prom_a, prom_b or prom_c "
                         "names this run.  `Unreached` is a statement about the "
                         "CENSUS -- the four call shapes it knows are in "
                         "notes/prom_b_dl_call_shapes.py, and this span alone "
                         "needed a fifth (the stride loop at prom_a 0xFBF79C) "
                         "to be found by hand.  It is marked, not hidden.")
        if corr:
            body += wrap("★ CORRECTION %s: " % corr, CORRECTION_TEXT[corr])
        H(a, *(head + body))


CORRECTION_TEXT = {
    "C1": "notes/prom_b_f17559_layout.py splits this object at 0xF1A048.  That "
          "address is the STRIDE OPERAND of the loop in prom_a's sub_FBF79C: "
          "`lda_24 xwa,(0xf1a037)` at 0xFBF7C9, `lda_24 xix,(0xf1a048)` at "
          "0xFBF7D1, `sub XIX,XWA` at 0xFBF7D6 -- so 0xF1A048 is 0xF1A037 plus "
          "ONE RECORD, computed to get the stride 17, and not an object "
          "boundary.  The loop then runs each record through `call 0xf42e0c` "
          "(T_F42E0C, DisplayListB_RunOne_Stack) at 0xFBF7EA.  0xF1A037 + 8*17 "
          "= 0xF1A0BF lands on the next proven run.  The halves are merged.",
    "C2": "the layout calls this run AMBIG because its records satisfy both "
          "interpreters' implied-length tables.  It is interpreter B, and not "
          "by the length rule -- which misclassifies 23 of the 4,097 records "
          "whose interpreter is known -- but by the caller's own register: "
          "prom_a 0xFBE2EC does `lda XIX,0x00F42E04` and reaches the "
          "interpreter with `jp (XIX)` at 0xFBE32A and 0xFBE34E.",
    "C3": "the layout calls this AMBIG and says `both ends are E0 references`.  "
          "Its low end is a CONTENT boundary -- the end of the 4-glyph copy "
          "above it -- not a reference.  The eight bytes are byte-identical to "
          "the one-record list at 0xF18CD5 that prom_a 0xFBD235 runs with a "
          "literal `call 0xf42e00`, and the pattern occurs exactly twice in the "
          "whole image, so the interpreter is A.  Nothing executes THIS copy.",
    "C4": "left honestly UNRESOLVED.  It is a well-formed interpreter-B op-08 "
          "record by FORMAT, and its two neighbours are interpreter B, but the "
          "format rule has a measured 0.56% error rate all in the direction of "
          "calling an A record B.  Its only reference anywhere in prom_a, "
          "prom_b or prom_c is as the END address of the run at 0xF1A137 -- one "
          "past the last byte that run's interpreter reads.  No mechanism is "
          "invented for it.",
    "C5": "the layout calls this an index_map.  It is a BITMAP: the op-03 "
          "record at 0xF1AAA9 points at it with BC = 3 (bytes per row) and "
          "HL = 17 (rows), and 3 x 17 = 51 is the whole segment.",
    "C6": "the layout calls this ascii.  It is the MIDI NOTE-NAME table and it "
          "is not ascii: 53 of the 128 entries carry a byte >= 0x80 (0x88 for "
          "flat, 0x8C for sharp).  Nor is it an index map -- nothing indexes "
          "it; it is DRAWN, by swi-7 function 6.  A natural note is "
          "`<letter><' ' or '-'><digit>`; an accidental note is "
          "`<letter><0x88 flat | 0x8C sharp><octave>`, and because the sign "
          "takes the middle cell the octaves -2 and -1 are COMPOSITE glyphs "
          "0xBC and 0xB0 rather than two characters.  All 128 entries decode to "
          "the octave their note number implies.",
    "C7": "the layout makes 0xF185FD-0xF1881C ONE array of 32 records.  It is "
          "FOUR arrays of eight: the pointer tables 0xF1B04B, 0xF1B10B, "
          "0xF1B0AB and 0xF1B12B hold eight entries each, and their first "
          "entries are 0xF185FD, 0xF18685, 0xF1870D and 0xF18795.",
}


# ------------------------------------------------------------------ emission
def hdr_lines(a):
    out = ["", "; " + "-" * 74]
    for l in HEADERS[a]:
        out.append(("; " + l).rstrip())
    out.append("; " + "-" * 74)
    return out


def byte_rows(a, e, width, note=None):
    out, x = [], a
    while x < e:
        stop = min(x + width, e)
        c = "   ; %06X  %s" % (x, txt(x, stop - x))
        if note:
            c += "  " + note(x)
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in sl(x, stop - x))
                   + c)
        x = stop
    return out


def emit_dl(a, e, interp):
    out, recs = [], dl_records(a, e)
    tab = HANDLER_B if interp == "B" else HANDLER_A
    for x, op, n in recs:
        h = u32(tab + 4 * op)
        out.append("\t.byte 0x%02x, 0x%02x\t; %06X  op %02X, %d bytes -> "
                   "handler 0x%06X" % (op, n, x, op, n, h))
        body = x + 2
        if interp == "B":
            out.append("\t.short 0x%04X\t\t; +2  RAM variable" % u16(x + 2))
            if n >= 7:
                out.append("\t.byte 0x%02x, 0x%02x, 0x%02x\t; +4  mask, shift, "
                           "swi 7 function" % (by(x + 4), by(x + 5), by(x + 6)))
                body = x + 7
                if n >= 11:
                    v = u32(x + 7)
                    out.append("\t.long 0x%08X\t; +7  -> %s"
                               % (v, LABELS.get(v, "0x%06X" % v)))
                    body = x + 11
            else:
                body = x + 4
        elif op in (0x03, 0x04) and n >= 12:
            v = u32(x + 2)
            out.append("\t.long 0x%08X\t; +2  source -> %s"
                       % (v, LABELS.get(v, "0x%06X" % v)))
            out.append("\t.short 0x%04X, 0x%04X, 0x%04X\t; +6 IX, +8 BC (%d "
                       "bytes/row), +10 HL (%d rows)"
                       % (u16(x + 6), u16(x + 8), u16(x + 10),
                          u16(x + 8), u16(x + 10)))
            body = x + 12
        elif op in (0x17, 0x1C) and n >= 6:
            out.append("\t.short 0x%04X, 0x%04X\t; +2  the two words"
                       % (u16(x + 2), u16(x + 4)))
            body = x + 6
        elif op in (0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E,
                    0x1F, 0x20, 0x21) and n >= 4:
            out.append("\t.short 0x%04X\t\t; +2  IX (screen position)"
                       % u16(x + 2))
            body = x + 4
        if body < x + n:
            t = txt(body, x + n - body)
            if all(32 <= c < 127 for c in sl(body, x + n - body)) \
                    and '"' not in t and "\\" not in t:
                out.append("\t.ascii \"%s\"\t; +%d" % (t, body - x))
            else:
                out.append("\t.byte " + ", ".join(
                    "0x%02x" % b for b in sl(body, x + n - body))
                    + "\t; +%d  %r" % (body - x, t))
    return out


def emit_longs(a, n):
    out = []
    for i in range(n // 4):
        v = u32(a + 4 * i)
        if v in LABELS:
            tag = "   -> %s" % LABELS[v]
        elif LO <= v < HI:
            tag = "   -> 0x%06X (inside this span)" % v
        elif A_BASE <= v < 0x1000000:
            tag = "   -> prom_a 0x%06X" % v
        elif B_BASE <= v < A_BASE:
            tag = "   -> prom_b 0x%06X" % v
        else:
            tag = ""
        out.append("\t.long 0x%08X                       ; %06X  [%d]%s"
                   % (v, a + 4 * i, i, tag))
    return out


ACCIDENTAL = {0x88: "b", 0x8C: "#"}
# ⚠ octaves -2 and -1 do not fit: the accidental sign takes the middle cell, so
# the octave has to go into ONE cell and the ROM uses a COMPOSITE glyph for it.
COMPOSITE_OCTAVE = {0xBC: -2, 0xB0: -1}


def note_name(i):
    """The name entry i spells, decoded rather than printed as characters.

    Natural notes are `<letter><' ' or '-'><digit>`; accidental notes are
    `<letter><0x88 flat | 0x8C sharp><octave>`, where the octave is an ASCII
    digit for 0..8 and the composite glyph 0xBC (-2) or 0xB0 (-1) below that.
    This mapping is re-derived for all 128 entries by --selftest check G."""
    x = C6_LO + i * C6_W
    b = sl(x, C6_W)
    letter = chr(b[0])
    if b[1] in ACCIDENTAL:
        oct_ = (COMPOSITE_OCTAVE[b[2]] if b[2] in COMPOSITE_OCTAVE
                else b[2] - 0x30)
        return "%s%s%d" % (letter, ACCIDENTAL[b[1]], oct_)
    return "%s%d" % (letter, -(b[2] - 0x30) if b[1] == 0x2D else b[2] - 0x30)


def note_octave(i):
    return (i // 12) - 2


def emit_notenames(a, c, w):
    """One row per MIDI note, with the note number and the decoded name.

    ⚠ The accidental bytes are 0x88 and 0x8C and the low-octave bytes are 0xBC
    and 0xB0 -- none of them ASCII.  Printing them as characters is what made
    the layout call this table `ascii`."""
    out = []
    for i in range(c):
        x = a + i * w
        raw = sl(x, w)
        tag = ""
        if raw[1] in ACCIDENTAL:
            tag = "  0x%02X = %s" % (raw[1], ACCIDENTAL[raw[1]])
            if raw[2] in COMPOSITE_OCTAVE:
                tag += ", 0x%02X = the octave %d in one cell" % (
                    raw[2], COMPOSITE_OCTAVE[raw[2]])
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in raw)
                   + "   ; %06X  note %3d  %-4s%s" % (x, i, note_name(i), tag))
    return out


def emit_entries(a, c, w, kind):
    out = []
    for i in range(c):
        x = a + i * w
        tail = ""
        if kind in ("ascii",):
            tail = "  %r" % txt(x, w)
        elif w == 1:
            tail = "  = %d" % by(x)
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in sl(x, w))
                   + "   ; %06X  [%d]%s" % (x, i, tail))
    return out


def emit():
    structure()
    out = []
    for kind, a, n, ev, _c in segments():
        if kind == "pad":
            vals = set(sl(a, n))
            if len(vals) != 1:
                sys.exit("REFUSING TO EMIT: pad 0x%06X is not one value" % a)
            out += ["", "; --- 0x%06X-0x%06X  %d bytes of 0x%02X padding ---"
                    % (a, a + n - 1, n, list(vals)[0]),
                    "\t.fill\t%d, 1, 0x%02X\t; asserted a single value"
                    % (n, vals.pop())]
            continue
        out += hdr_lines(a)
        out.append(LABELS[a] + ":")
        sh = shape(kind, n, ev)
        if kind == "display_list":
            out += emit_dl(a, a + n, interp_of(ev) or "A")
        elif kind == "pointer_table":
            out += emit_longs(a, n)
        elif kind == "notenames":
            out += emit_notenames(a, C6_N, C6_W)
        elif kind == "bitmap" and sh:
            out += byte_rows(a, a + n, sh[1])
        elif kind == "record_array" and sh:
            out += emit_entries(a, sh[0], sh[1], kind)
        elif sh and sh[1] <= 16:
            out += emit_entries(a, sh[0], sh[1], kind)
        else:
            out += byte_rows(a, a + n, 16)
    return out


# ------------------------------------------------------------------ selftest
FAIL = []
_NC = [0]


def check(msg, got, want):
    _NC[0] += 1
    ok = got == want
    print("  %-64s %-22s %s" % (msg, repr(got)[:22],
                                "OK" if ok else "FAILED (want %r)" % (want,)))
    if not ok:
        FAIL.append(msg)


def selftest():
    del FAIL[:]
    raw, segs = raw_layout(), segments()
    structure()
    print("A. the layout has not moved, and the corrections change what they say")
    check("raw segments", len(raw), EXPECTED_RAW)
    check("they tile the span", sum(n for _k, _a, n, _e in raw), EXPECTED_BYTES)
    check("after C1 (merge -1) and C7 (split +3)", len(segs), EXPECTED_RAW + 2)
    check("still tiling", sum(n for _k, _a, n, _e, _c in segs), EXPECTED_BYTES)
    pos = LO
    for _k, a, n, _e, _c in segs:
        if a != pos:
            check("contiguous at 0x%06X" % a, a, pos)
        pos = a + n
    check("the LAST segment ends at HI", pos, HI)
    check("segments carrying a correction",
          collections.Counter(c for _k, _a, _n, _e, c in segs if c),
          {"C1": 1, "C2": 2, "C3": 1, "C4": 1, "C5": 1, "C6": 1, "C7": 4})

    print("B. C1 -- the stride operand is not a boundary")
    # ⚠ cite the SOURCE LINE at the instruction address, not a substring
    # search: prom_a spells this operand `lda_24 xwa, (0xf1a037)`, and an
    # earlier draft of this check looked for `lda XWA,0x00f1a037` and found
    # nothing -- a negative that would have passed as "no such instruction".
    for ad, want in ((0xFBF7C9, "lda_24 xwa, (0xf1a037)"),
                     (0xFBF7D1, "lda_24 xix, (0xf1a048)"),
                     (0xFBF7D6, "sub XIX,XWA"),
                     (0xFBF7EA, "call 0xf42e0c")):
        check("  prom_a 0x%06X is `%s`" % (ad, want), prom_a_line(ad), want)
    check("8 x 17 lands on the next proven run", C1_LO + 8 * 17, C1_HI)
    check("the merged object is one segment",
          [(k, n) for k, a, n, _e, _c in segs if a == C1_LO],
          [("record_array", 8 * 17)])
    check("  and 0xF1A048 is no longer a segment start",
          [a for _k, a, _n, _e, _c in segs if a == C1_MID], [])

    print("C. C2 -- the caller's own XIX resolves the interpreter")
    for ad, want in ((0xFBE2EC, "lda_24 xix, (0xf42e04)"),
                     (0xFBE32A, "jp (xix)"),
                     (0xFBE34E, "jp (xix)"),
                     (0xFBE342, "lda_24 xwa, (0xf181d6)")):
        check("  prom_a 0x%06X is `%s`" % (ad, want), prom_a_line(ad), want)
    check("  and the XIX it jumps through is loaded ONCE in that routine",
          [a for a in range(0xFBE2E0, 0xFBE360)
           if prom_a_line(a).startswith("lda_24 xix,")], [0xFBE2EC])
    check("both runs are interpreter B now",
          [interp_of(e) for k, a, _n, e, _c in segs
           if a in (0xF1814E, 0xF181D6)], ["B", "B"])
    check("no segment still says AMBIG except the one C4 leaves unresolved",
          [("0x%06X" % a) for _k, a, _n, e, _c in segs
           if interp_of(e) == "AMBIG"], [])

    print("D. C3 -- byte identity, and the count of copies")
    pat = sl(0xF17C00, 8)
    check("0xF17C00 == 0xF18CD5, 8 bytes", pat == sl(0xF18CD5, 8), True)
    occ, i = [], 0
    while True:
        j = rom().find(pat, i)
        if j < 0:
            break
        occ.append(B_BASE + j)
        i = j + 1
    check("the 8-byte pattern occurs exactly twice in prom_b",
          ["0x%06X" % x for x in occ], ["0xF17C00", "0xF18CD5"])
    check("prom_a 0xFBD235 runs the other copy with a literal call",
          "call 0xf42e00" in prom_a_line(0xFBD235), True)

    print("E. C4 -- honestly unresolved, and marked so")
    check("0xF1A14D is 11 bytes", dict((a, n) for _k, a, n, _e, _c in segs
                                       ).get(0xF1A14D), 11)
    check("its header says NOT RESOLVED",
          any("NOT RESOLVED" in l for l in HEADERS[0xF1A14D]), True)
    check("the two UNREACHED runs are 19 bytes, 0.12% of the span",
          (sum(UNREACHED.values()),
           round(100.0 * sum(UNREACHED.values()) / EXPECTED_BYTES, 2)),
          (19, 0.12))

    print("F. C5 -- a bitmap, sized by the record that blits it")
    check("the op-03 record at 0x%06X points at 0x%06X" % (C5_REC, C5_LO),
          u32(C5_REC + 2), C5_LO)
    check("  BC x HL", (u16(C5_REC + 8), u16(C5_REC + 10)), (3, 17))
    check("  3 x 17 = the segment length", 3 * 17, C5_HI - C5_LO)

    print("G. C6 -- the MIDI note names")
    hi = [i for i in range(C6_N * C6_W) if by(C6_LO + i) >= 0x80]
    check("entries carrying a byte >= 0x80", len({i // C6_W for i in hi}), 53)
    check("note 0 and note 127", (txt(C6_LO, 3), txt(C6_LO + 127 * 3, 3)),
          ("C-2", "G 8"))
    check("  the LAST entry ends the segment", C6_LO + C6_N * C6_W, 0xF1A7AF)
    check("the accidental bytes are 0x88 and 0x8C",
          sorted({by(C6_LO + 3 * i + 1) for i in range(C6_N)}
                 - {ord(" "), ord("-")}), [0x88, 0x8C])
    check("every entry decodes to the octave its NOTE NUMBER implies",
          [i for i in range(C6_N)
           if not note_name(i).endswith(str(note_octave(i)))], [])
    check("  including the LAST (note 127)",
          (note_name(127), note_octave(127)), ("G8", 8))
    check("  and the composite low-octave glyphs are exactly 0xBC and 0xB0",
          sorted({by(C6_LO + 3 * i + 2) for i in range(C6_N)
                  if by(C6_LO + 3 * i + 1) in ACCIDENTAL} - set(range(0x30, 0x3A))),
          [0xB0, 0xBC])

    print("H. C7 -- four arrays of eight, and the four tables")
    check("the splits", [a for _k, a, _n, _e, c in segs if c == "C7"],
          [0xF185FD] + C7_SPLITS)
    for i, t in enumerate(C7_TABLES):
        check("  table 0x%06X entry 0 is array %d's start" % (t, i),
              u32(t), ([0xF185FD] + C7_SPLITS)[i])
        check("    and its 8 entries are 17 apart",
              [u32(t + 4 * k) - u32(t) for k in range(8)],
              [17 * k for k in range(8)])

    print("I. C8 -- the .incbin header's array count")
    n = 0
    while u32(0xF17A6C + 4 * n) and LO <= u32(0xF17A6C + 4 * n) < HI:
        n += 1
    check("0xF17A6C holds 29 pointers, not 24", n, 29)
    check("  spaced 0x48 (the stride the header got right)",
          sorted({u32(0xF17A6C + 4 * (k + 1)) - u32(0xF17A6C + 4 * k)
                  for k in range(n - 1)}), [0x48])
    check("  and they end where the glyph bitmaps start",
          u32(0xF17A6C), 0xF17AE0)

    print("J. the naming")
    ph = [v for v in LABELS.values() if re.match(r"^DL_[0-9A-F]{6}$", v)]
    check("no duplicate label", len(set(LABELS.values())), len(LABELS))
    check("display lists named from their own text",
          sum(1 for a, v in LABELS.items()
              if v.startswith("DL_") and a not in PLACEHOLDER),
          len([1 for k, a, _n, _e, _c in segs
               if k == "display_list" and a not in PLACEHOLDER]))
    check("  placeholders, reported not hidden", len(ph), len(PLACEHOLDER))

    print("K. the emitted text rebuilds the span")
    body = emit()
    got = RT.assemble_block("\t.text\n" + "\n".join(banner()) + "\n"
                            + "\n".join(body) + "\n")
    check("assembles", got is not None, True)
    check("byte-identical to the ROM", got == sl(LO, HI - LO), True)

    print("\n%d checks, %d failures" % (_NC[0], len(FAIL)))
    for m in FAIL:
        print("  FAILED: %s" % m)
    return 1 if FAIL else 0


_SRC = {}


def prom_a_src():
    if "s" not in _SRC:
        _SRC["s"] = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read()
    return _SRC["s"]


def prom_a_text():
    return prom_a_src().lower()


def prom_a_line(addr):
    m = re.search(r"^(.*);\s*%06X\s" % addr, prom_a_src(), re.M)
    return m.group(1).strip() if m else ""


# ------------------------------------------------------------------- banner
def bw(prefix, body, width=78):
    """Banner wrapper -- every returned line already starts with ';', because
    these lines go into the .s as-is and a continuation without the comment
    character assembles to bytes.  main() assembles the banner with the body."""
    import textwrap
    pad = ";" + " " * (len(prefix) - 1)
    ls = textwrap.wrap(body, width - len(prefix)) or [""]
    return ["; " + prefix[2:] + ls[0]] + [pad + l for l in ls[1:]]


def banner():
    structure()
    segs = segments()
    b = collections.Counter()
    for k, _a, n, _e, _c in segs:
        b[k] += n
    ph = len(PLACEHOLDER)
    out = ["", "; " + "=" * 78,
           "; 0xF17559-0xF1B3FF -- THE COMBINATION / INTERNAL SOUND / MIDI SOUND",
           ";                      PARAMETER SCREENS, AND THEIR TABLES",
           "; " + "=" * 78, ";"]
    out += bw("; ", "16,039 bytes in %d objects: %s.  The span holds NO CODE -- "
              "exactly thirteen in-span addresses are the target of a transfer "
              "anywhere in the four `.s` files and all thirteen are `jp` slots "
              "of one STALE thunk run (T_F42FD0-T_F43000, every slot with zero "
              "references, eleven of them landing INSIDE a record).  So no "
              "decode is run here; the boundaries come from proven operands, "
              "display-list call sites, `ldir` copy lengths and record framing "
              "walks.  notes/prom_b_f17559_layout.py."
              % (len(segs), ", ".join("%s %d" % (k, v)
                                      for k, v in sorted(b.items()))))
    out += [";"]
    out += bw("; ", "WHAT IT DRAWS.  `INTERNAL SOUND` pages 1-3, `MIDI SOUND` "
              "pages 1-3, `MIDI OUT FILTER`, `C0MBINATI0N EDIT`, `COMBINATION "
              "NAMING`, `KEY LAYER`, `VELOCITY LAYER`, `MAIN OUT EQUALIZER` and "
              "the two write-protect / output-conflict message screens.  With "
              "them: the 32 `PART nn` names, the 128-entry pan ladder `L64`.."
              "`R63`, a 100-entry decimal value ladder ` 0.10`..`30.00`, and "
              "the MIDI note names `C-2`..`G 8`.")
    out += [";"]
    out += bw("; ⚠ ", "The ROM spells several captions with a ZERO for the "
              "letter O -- `S0UND`, `V0LUME`, `PR0GRAM`, `C0MBINATI0N`, "
              "`MEM0RY`, `CH0RUS`.  Reproduced exactly; the machine really "
              "shows them.")
    out += [";"]
    out += bw("; ⚠ ", "EIGHT CORRECTIONS from notes/prom_b_f17559_reaudit.py "
              "are applied here rather than in the layout script (another lane "
              "may be running it), and every one is re-derived by "
              "--selftest: C1 0xF1A048 is a stride operand, not a boundary; C2 "
              "0xF1814E/0xF181D6 are interpreter B by the caller's own XIX; C3 "
              "0xF17C00 is interpreter A by byte-identity and is UNREACHED; C4 "
              "0xF1A14D stays UNRESOLVED; C5 0xF17C59 is a bitmap; C6 0xF1A62F "
              "is the MIDI note-name table and is not ascii; C7 0xF185FD is "
              "FOUR arrays of eight; C8 the old block header's `24-entry array` "
              "at 0xF17A6C is 29.")
    out += [";"]
    out += bw("; ⚠ ", "19 BYTES -- 0xF17C00 (8) and 0xF1A14D (11), 0.12% of the "
              "span -- are reached by NOTHING the census sees, and are marked "
              "UNREACHED where they sit.  `Unreached` is a statement about the "
              "census, not about the machine.")
    out += [";"]
    out += bw("; ", "NAMING.  %d labels.  %d display lists are named after the "
              "longest run of letters their OWN records carry; %d keep "
              "`DL_XXXXXX` because they carry none.  Every other label is a "
              "KIND plus its address -- `StringTable_`, `IndexMap_`, "
              "`PtrTable_`, `RecordArray_`, `Bitmap_WxH` -- which states the "
              "measured shape and nothing more.  ⚠ The documentation metric "
              "counts all of those as `semantic`; only the caption-derived ones "
              "carry meaning, and --stats prints the split."
              % (len(LABELS),
                 sum(1 for k, a, _n, _e, _c in segs
                     if k == "display_list" and a not in PLACEHOLDER), ph))
    out += [";"]
    out += bw("; ", "REGENERATE:  python3 notes/gen_prom_b_f17559_module.py")
    out += bw("; ", "CHECKS:      python3 notes/gen_prom_b_f17559_module.py "
              "--selftest")
    out += ["; " + "=" * 78]
    return out


# ----------------------------------------------------------------------- CLI
def main():
    raw_layout()
    if "--check" in ARGV:
        print("layout OK: %d raw segments -> %d after the corrections, tiling "
              "0x%06X-0x%06X" % (len(raw_layout()), len(segments()), LO, HI))
        return 0
    if "--selftest" in ARGV:
        return selftest()
    if "--corrections" in ARGV:
        structure()
        for kind, a, n, ev, c in segments():
            if c:
                print("  %-4s %-14s 0x%06X-0x%06X  %-28s"
                      % (c, kind, a, a + n - 1, LABELS.get(a, "")))
                print("       %s" % ev)
        return 0
    body = emit()
    head = "\n".join(banner())
    text = "\n".join(body)
    got = RT.assemble_block("\t.text\n" + head + "\n" + text + "\n")
    want = sl(LO, HI - LO)
    if got != want:
        nd = -1 if got is None else sum(1 for i in range(min(len(got), len(want)))
                                        if got[i] != want[i])
        sys.exit("REFUSING TO PRINT: the emitted text does not rebuild the span "
                 "(%s, %d differing bytes)"
                 % ("assembly failed" if got is None
                    else "len %d vs %d" % (len(got), len(want)), nd))
    if "--stats" in ARGV:
        segs = segments()
        c = collections.Counter(k for k, _a, _n, _e, _c in segs)
        print("objects by kind:", dict(c))
        print("labels: %d" % len(LABELS))
        cap = sum(1 for k, a, _n, _e, _c in segs
                  if k == "display_list" and a not in PLACEHOLDER)
        kind_addr = len(LABELS) - cap - len(PLACEHOLDER) - 1
        print("  %d named from the ROM's own captions" % cap)
        print("  %d are a KIND plus an address (StringTable_, IndexMap_, ...)"
              % kind_addr)
        print("  %d are DL_XXXXXX placeholders -- the address in another dress"
              % len(PLACEHOLDER))
        print("  1 is a unique object name (MidiNoteNames)")
        ev = sum(1 for h in HEADERS.values()
                 if any(l.startswith("Evidence:") for l in h))
        print("headers: %d; carrying an Evidence: line: %d" % (len(HEADERS), ev))
        print("emitted lines: %d; re-assembles to the ROM exactly" % len(body))
        return 0
    print(head)
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
