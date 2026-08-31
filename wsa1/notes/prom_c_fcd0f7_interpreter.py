#!/usr/bin/env python3
"""Who READS prom_c 0xFCD0F7-0xFDD2AA, and which interpreter frames which stream?

QUESTION IT ANSWERS
  Wave 7's lane C1 was briefed to "find the INTERPRETER for prom_c
  0xFCD0F7-0xFDD2AA", on the strength of a wave-6 paragraph saying the region was
  "left WHOLE ... the existing 16-bit-BE framing desynchronises at the fifth
  record.  It needs its interpreter found first".

  ⚠ THAT PARAGRAPH IS STALE, and `--stale` proves it from the tree: prom_c has no
  `.incbin`, the region is emitted record by record in prom_c/wsa1_prom_c.s, and
  the interpreter was found in wave 5 round 2 -- `P7Stream_Run` at 0xF9A646, with
  the container written up in notes/FINDINGS-prom_c-p7-byte-stream-pool.md and
  re-proved by notes/gen_prom_c_p7stream_pool.py --verify.

  So this script answers the question the region still HAD open, which that file
  states in its own §0:

      "The second consumer.  130 of the 297 streams contain at least one record
       whose payload is not a whole number of the interpreter's groups.  Those
       cannot be what `P7Stream_Run` runs.  The container is the same; the payload
       convention is not, and the routine that reads them has not been found."

  It is found here.  It is `sub_F9ADB5` (0xF9ADB5), and its framer is
  `sub_F9E140` (0xF9E140), which builds a 16-bit length out of the SAME two header
  bytes and tests it against the terminator 0xF000 -- i.e. the 16-bit reading wave 3
  tried and wave 5 replaced is not wrong, it is the OTHER HALF of the pool.

  ⚠ ONE BYTE OF THAT READING IS NOT PROVEN BY THE INSTRUCTION, and `--shift` is the
  whole argument.  0xF9E14B is `C9 EE 08`, which unidasm and MAME decode as
  `sll 0x08,A` -- an EIGHT-BIT register shifted left by eight -- and MAME's
  `tlcs900_device::sla8()` returns 0 for that (`900tbl.hxx`, `count = (s & 0x0f) ?
  (s & 0x0f) : 16`).  Under that semantics the high byte contributes NOTHING, the
  compare `cp WA,0xF000` at 0xF9E164 can never be true, and sub_F9E140 never finds a
  terminator.  It has to find one: all 297 END records in the pool are exactly
  `F0 00`.  So the value is (b0 << 8) | b1 and the byte-shift decode is the thing to
  doubt -- a candidate TLCS-900 core question for the emulator, not a fact about the
  data.  The data cannot settle it either way, and says so: every non-terminator
  record in the 142 streams this reader walks has b0 == 0x00 (max length 70), so the
  high byte only ever matters AT the terminator.  Both facts are asserted by
  `--verify`.

THE TWO READINGS, each read out of its own instructions

  P7Stream_Run, 0xF9A6C4-0xF9A702          sub_F9E140, 0xF9E149-0xF9E188
    F9A6C4 and A,0xf0 / cp A,0xf0  -> END     F9E149 ld A,(XBC)      -> b0
    F9A6D9 ld A,(XBC+1)   -> len[7:0]         F9E14B sll 8,A         -> see --shift
    F9A6E5 and A,0x0f / sll 8 -> len[11:8]    F9E152 ld A,(XBC+1)    -> b1
    F9A6EF dec 2,WA / F9A6F4 inc 2,XBC        F9E159 add DE,HL       -> len16
    F9A6FC srl 4,IY       -> opcode           F9E164 cp WA,0xF000    -> END
    F9A702 jrl 0xF9AD84   -> dispatch         F9E17F (0x861E) := ptr + len16
                                              F9E188 cursor := ptr + 2
  Note the SHAPE difference, which is the point: P7Stream_Run dispatches on the top
  nibble and its arms consume the payload; sub_F9E140 has no opcode field at all --
  it only measures a block and hands the inside to sub_F9B54B.
  The two lengths AGREE byte for byte on any record whose opcode nibble is 0, and
  only there.

WHAT SEPARATES THE TWO FAMILIES -- the measurement, not an argument
  Every one of the 56 `PoolDir_Records` (0xFDBFD9, stride 25) carries four pointers
  into the pool.  Sorted by which FIELD they sit in:

      fields +0 and +8   -> 112 distinct streams, 112 of 112 NOT group-clean,
                            112 of 112 parse under the 16-bit-BE reading
      fields +4 and +12  -> 112 distinct streams, 112 of 112 group-clean,
                              0 of 112 parse under the 16-bit-BE reading

  ★ and the code reads exactly those fields for exactly those consumers.  All four
  are located, in two sibling routines with the same `mul C,0x19 / add <off> /
  add XBC,0x00FDBFD9 / ld XBC,(XBC)` shape:

      field  loaded at   into      pushed to                at
      +0     0xFA3D14    (XIZ-6)   sub_F9ADB5 arg (XIZ+0x08) 0xFA3E12
      +8     0xFA3D02    (XIZ-10)  sub_F9ADB5 arg (XIZ+0x0C) 0xFA3E12
      +4     0xFA3B13    (XIZ-10)  P7Stream_Run              0xFA3BB6
      +12    0xFA3AEA    (XIZ-6)   P7Stream_Run              0xFA3B9C

  So the split is not a correlation this script noticed in the data: the two
  consumers read DIFFERENT FIELDS of the same record, and the fields they read hold
  streams only the reader that reads them can frame.  Separately, `P7Stream_Run`'s
  74 literal call sites hand it 30 streams, all 30 group-clean and none BE-parsable.

  ⚠ HOW STRONG THIS IS, stated exactly.  "BE-parsable" is EQUIVALENT to "every
  record in the stream carries opcode 0" (`--verify` asserts the two sets are the
  same 142 streams), because that is when the 12-bit and 16-bit readings coincide.
  So the 112/112 and 0/112 split is ONE fact seen twice, not two facts.  What makes
  it evidence about a CONSUMER is that the field a stream sits in predicts it with
  no exception, and that the field is chosen by an instruction.

  THE INDEPENDENT WITNESS, which does not go through the directory at all: nine of
  the twenty-two `call 0xF9ADB5` sites carry BOTH stream arguments as literals in
  the instruction stream (`--consumer`).  Twelve distinct streams, and 12 of 12 are
  BE-parsable.  P7Stream_Run's 74 literal sites hand it 30 distinct streams, 30 of
  30 group-clean and 0 of 30 BE-parsable.  The two sets do not intersect.

  AND THE 130 ARE ALL ACCOUNTED FOR: every one of the 130 streams P7Stream_Run
  cannot frame is BE-parsable -- 130 of 130.  Twelve further streams are framable
  BOTH ways (all-opcode-0 AND every length a multiple of five); those twelve are
  genuinely ambiguous on the container alone, and NINE of them are settled by being
  literal arguments of sub_F9ADB5 (0xFCD188 0xFCD199 0xFCD1AF 0xFCD1C0 0xFCD1D6
  0xFCD1E7 0xFCD22D 0xFCD40F 0xFCD97D).  The remaining THREE -- 0xFCD0F7, 0xFCD0FE,
  0xFCD105 -- are reached only from `P7Unit_StreamPtrsByGroupAndUnit` and stay ambiguous;
  that is the honest hole and `--verify` names them.

  ⚠ WHAT THE NAME "second consumer" IS AND IS NOT.  sub_F9ADB5 is the routine that
  READS these streams and pushes their bytes out of P7.  It is not a second
  "interpreter" in P7Stream_Run's sense: the per-record work is done by sub_F9B54B
  (0xF9B54B), which reads a byte, compares it to 0x7A, reads one more and jumps
  into 0xF9DEF0 inside sub_F9BE3A.  The inner grammar was NOT traced; see below.

CROSS-REFERENCES CHECKED AND EMPTY (a searched negative, not an assumption)
  * prom_a has no twin of either routine.  `python3 notes/prom_c_prom_a_shared_runs.py
    --window 0xF9A646 0xF9A646 549` -> longest equal run 2 of 549 bytes, 5 equal in
    all (1%).  The prom_a/prom_c shared kernel is 0xF9816B-0xF989EE
    (notes/prom_c_kernel_map.py); both routines lie above it.
  * The KN5000 sub-CPU has neither.  `python3 notes/prom_c_sibling_map.py --addr
    0xF9A646 --len 549` and `--addr 0xF9ADB5 --len 257` both print "NO occurrence of
    this exact run".  So no borrowed name is available and none is used here.

RUN
    python3 notes/prom_c_fcd0f7_interpreter.py --stale        # the briefing's premise
    python3 notes/prom_c_fcd0f7_interpreter.py --sites        # code sites, by mechanism
    python3 notes/prom_c_fcd0f7_interpreter.py --pointers     # pointer words, by object
    python3 notes/prom_c_fcd0f7_interpreter.py --frame        # both walks, to the last byte
    python3 notes/prom_c_fcd0f7_interpreter.py --shift        # the one unproven instruction
    python3 notes/prom_c_fcd0f7_interpreter.py --families     # the directory cross-tab
    python3 notes/prom_c_fcd0f7_interpreter.py --consumer     # sub_F9ADB5's literal sites
    python3 notes/prom_c_fcd0f7_interpreter.py --verify       # all of it, exit!=0 on failure

WHAT THIS SCRIPT DOES NOT ESTABLISH
  * What a record MEANS.  Nothing here reads a musical role out of a payload.
  * What `sub_F9B54B` (0xF9B54B) consumes per call.  It reads a byte, compares it
    to 0x7A, reads one more, and jumps into 0xF9DEF0 inside the 9 KB routine
    `sub_F9BE3A`; its per-call byte count was NOT traced.  So the inner grammar of
    a BE-family block is open.
  * Why 12 streams (0xFCE4BF, 0xFCE6D8, 0xFCFA2A, 0xFCFC5A, 0xFD1A01, 0xFD1C1A,
    0xFD7B55, 0xFD7D7B, 0xFD8F8A, 0xFD91A3, 0xFDAFA6, 0xFDB1D2) have NO pointer
    anywhere in the image.  `--families` lists them; they are all BE-family.
"""
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
import gen_prom_c_p7stream_pool as P                               # noqa: E402

SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
D, BASE, LO, HI = P.D, P.BASE, P.LO, P.HI
DESCLO, IDXLO, FRLO, PTRLO = P.DESCLO, P.IDXLO, P.FRLO, P.PTRLO
NDIR, DIRSTRIDE = P.NDIR, P.DIRSTRIDE

RUN_ADDR   = 0xF9A646        # P7Stream_Run
SECOND     = 0xF9ADB5        # sub_F9ADB5 -- the second consumer
FRAMER     = 0xF9E140        # sub_F9E140 -- its 16-bit-BE framer
INNER      = 0xF9B54B        # sub_F9B54B -- its per-iteration reader

# ------------------------------------------------------------------ the tiling
_T = None


def pool():
    """(objs, streams, clean, be) -- the container, from gen_prom_c_p7stream_pool."""
    global _T
    if _T is None:
        objs = P.tile()
        streams = {o["start"]: o for o in objs if o["kind"] == "STREAM"}
        clean = {s: P.group_clean(o["recs"]) for s, o in streams.items()}
        be = {s: be_walk(s)[2] and be_walk(s)[0] == o["end"]
              for s, o in streams.items()}
        _T = (objs, streams, clean, be)
    return _T


def be_walk(a, limit=DESCLO):
    """sub_F9E140's framing, 0xF9E149-0xF9E168: a 16-bit BIG-ENDIAN length whose
    terminator is exactly 0xF000.  Returns (end, records, reached_terminator).

    The only guard added over the ROM's own loop is `v == 0`, which would make the
    firmware spin forever; `--verify` re-runs the whole census with and without it
    and asserts the answer does not change."""
    n = 0
    while a < limit:
        v = (P.B(a) << 8) | P.B(a + 1)
        if v == 0xF000:
            return a + 2, n, True
        if v == 0 or a + v > limit:
            return a, n, False
        a += v
        n += 1
    return a, n, False


# ------------------------------------------------- mechanism census, from the .s
_INS = None


def proven_instructions():
    """(addr, mame_text) for every PROVEN instruction line in prom_c/wsa1_prom_c.s.

    Every instruction line the transcription emits carries a `; ADDR  <mame text>`
    comment and the byte gate proves the file rebuilds the ROM, so these addresses
    are code beyond argument.  Directive lines (`.byte`, `.long`, `.ascii`, `.fill`)
    are excluded by requiring the body's first token not to start with a dot -- the
    same exclusion notes/prom_b_f65000_layout.py's null corpus uses, and for the
    same reason: without it a data island silently enters a census of code.

    ⚠ This is why the census cannot invent a phantom the way a linear decode can
    (notes/prom_c_frontier.py: 132 of its 135 targets are phantoms).  It reads only
    lines the gate has already certified as instructions."""
    global _INS
    if _INS is None:
        out = []
        for line in open(SRC):
            body = line.split(";")[0]
            m = re.search(r";\s*([0-9A-F]{6})\s\s(.*)$", line.rstrip("\n"))
            if not m or not body.startswith("\t"):
                continue
            if body.lstrip().startswith("."):
                continue
            out.append((int(m.group(1), 16), m.group(2).strip()))
        _INS = out
    return _INS


_LABELS = None


def labels_by_address():
    """{addr: label} for every top-level label in the .s whose NAME ends in the six
    hex digits of an address (`P7Unit_StreamPtrsByGroupAndUnit`, `P7Stream_FCD0F7`, ...).

    Naming by the convention the tree already uses is deliberate: it needs no
    address arithmetic over directive sizes, and a label whose name does not match
    its own address simply does not appear, rather than mis-naming an object."""
    global _LABELS
    if _LABELS is None:
        out = {}
        for line in open(SRC):
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
            if not m:
                continue
            h = re.search(r"([0-9A-F]{6})$", m.group(1))
            if h:
                out.setdefault(int(h.group(1), 16), m.group(1))
        _LABELS = out
    return _LABELS


def incbin_lines():
    """Lines whose CODE half (before the first `;`) holds a .incbin directive.

    ⚠ A plain `grep -c .incbin` on this file returns 34 and every one of them is
    inside a COMMENT -- routine headers that record what used to be `.incbin`.  The
    first draft of this script quoted the 34 and would have contradicted the wave-7
    briefing's own (correct) statement that prom_c has zero."""
    return [l for l in open(SRC)
            if ".incbin" in l.split(";")[0]]


MECH = [
    ("lda",  "LDA        address taken (pushed as a call argument)"),
    ("add",  "ADD-BASE   base of an indexed table read"),
    ("ld",   "LD-IMM     immediate loaded into a register"),
    ("call", "CALL       CONTROL TRANSFER -- must be zero, the region is data"),
    ("jp",   "JP         CONTROL TRANSFER -- must be zero, the region is data"),
    ("calr", "CALR       CONTROL TRANSFER -- must be zero, the region is data"),
    ("jrl",  "JRL        CONTROL TRANSFER -- must be zero, the region is data"),
    ("jr",   "JR         CONTROL TRANSFER -- must be zero, the region is data"),
]


def code_sites():
    """[(addr, mnemonic, target, text)] -- every proven prom_c instruction whose
    operand text holds a literal inside [LO,HI).

    The address reported is the address of the INSTRUCTION, which is what the `;`
    comment carries; ~20 citations in an earlier wave were the address of the
    LITERAL, one or two bytes further on."""
    out = []
    for a, txt in proven_instructions():
        for m in re.finditer(r"0x0*([0-9a-fA-F]{5,8})\b", txt):
            v = int(m.group(1), 16)
            if LO <= v < HI:
                out.append((a, txt.split()[0].lower(), v, txt))
                break
    return out


def enclosing(addr):
    """The nearest preceding top-level label in the .s, by source order."""
    best, bestname = None, None
    cur = None
    for line in open(SRC):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
        if m:
            cur = m.group(1)
            continue
        c = re.search(r";\s*([0-9A-F]{6})\s\s", line)
        if c:
            v = int(c.group(1), 16)
            if v <= addr and (best is None or v >= best):
                best, bestname = v, cur
    return bestname


# ------------------------------------------------------- pointer-word census
def pointer_words():
    """{word_address: [target, ...]} for every 32-bit LE word in the prom_c image
    whose value lands in [LO,HI).  This is gen_prom_c_p7stream_pool.seeds()'s PTR32
    half, re-derived here so this script stands alone, and grouped by CONTAINER."""
    out = defaultdict(list)
    for i in range(len(D) - 3):
        v = int.from_bytes(D[i:i + 4], "little")
        if LO <= v < HI:
            out[BASE + i].append(v)
    return out


def pointer_runs():
    """Maximal runs of pointer words at stride 4: (start, count, label_or_None)."""
    pw = sorted(pointer_words())
    runs, i = [], 0
    while i < len(pw):
        j = i
        while j + 1 < len(pw) and pw[j + 1] == pw[j] + 4:
            j += 1
        runs.append((pw[i], j - i + 1, labels_by_address().get(pw[i])))
        i = j + 1
    return runs


# ---------------------------------------------------- the two consumers' sites
def second_consumer_sites():
    """(call_addr, arg_08, arg_0C) for every `call 0xF9ADB5` whose two stream
    arguments are visible as literals.

    The shape is the compiler's:  `lda XWA,<s2> / push XWA / lda XIY,<s1> /
    push XIY / call 0xF9ADB5`, bytes  F2 <s2> 30  38  F2 <s1> 35  3D  1D B5 AD F9.
    Pushes go to the frame in reverse, so the LAST pushed is (XIZ+0x08) -- which is
    `sub_F9B54B`'s context argument -- and the one before it is (XIZ+0x0C), the
    block chain `sub_F9E140` frames."""
    out = []
    for i in range(len(D) - 16):
        if (D[i] == 0xF2 and D[i + 4] == 0x30 and D[i + 5] == 0x38
                and D[i + 6] == 0xF2 and D[i + 10] == 0x35 and D[i + 11] == 0x3D
                and D[i + 12] == 0x1D
                and int.from_bytes(D[i + 13:i + 16], "little") == SECOND):
            out.append((BASE + i + 12,
                        int.from_bytes(D[i + 7:i + 10], "little"),
                        int.from_bytes(D[i + 1:i + 4], "little")))
    return out


def calr_sites(target):
    """`calr` sites for `target`, taken from the .s (which spells the displacement as
    `calr (0xTARGET - 0xRETURN)`), so the count is read rather than assumed."""
    pat = re.compile(r"calr\s*\(0x%06X\s*-" % target, re.I)
    out = []
    for line in open(SRC):
        if pat.search(line):
            m = re.search(r";\s*([0-9A-F]{6})\s\s", line)
            if m:
                out.append(int(m.group(1), 16))
    return out


def all_second_calls():
    """Opcode-anchored `call 0xF9ADB5` sites -- an upper bound, used only to state
    how many of the routine's call sites the literal scan above accounts for."""
    return [BASE + i for i in range(len(D) - 4)
            if D[i] == 0x1D and int.from_bytes(D[i + 1:i + 4], "little") == SECOND]


def dir_fields():
    """{field_offset: {stream_start: [record_index, ...]}} for the four in-pool
    pointer fields of the 56 25-byte PoolDir_Records."""
    out = {}
    for f in range(4):
        d = defaultdict(list)
        for k in range(NDIR):
            d[P.U32(DESCLO + DIRSTRIDE * k + 4 * f)].append(k)
        out[4 * f] = dict(d)
    return out


# -------------------------------------------------------------------- reports
def rep_stale():
    src = open(SRC).read()
    inc = incbin_lines()
    print("THE BRIEFING'S PREMISE, CHECKED AGAINST THE TREE")
    print("  `.incbin` DIRECTIVES in prom_c/wsa1_prom_c.s: %d" % len(inc))
    print("     (`.incbin` also occurs %d times inside COMMENTS -- a plain grep says 34)"
          % (sum(1 for l in src.splitlines() if ".incbin" in l) - len(inc)))
    lab = "P7Stream_FCD0F7:"
    print("  label %-18s present in the .s: %s" % (lab, lab in src))
    print("  label %-18s present in the .s: %s" % ("P7Stream_Run:", "P7Stream_Run:" in src))
    objs, streams, clean, be = pool()
    print("  the region is emitted as %d objects, %d of them streams, %d records"
          % (len(objs), len(streams),
             sum(len(o["recs"]) for o in objs if o["kind"] == "STREAM")))
    print("  => the interpreter was found in wave 5 round 2; it is P7Stream_Run at 0x%06X."
          % RUN_ADDR)
    print("     notes/FINDINGS-prom_c-p7-byte-stream-pool.md, "
          "notes/gen_prom_c_p7stream_pool.py --verify")
    print()
    print("  ⚠ The one thing the wave-6 paragraph got RIGHT and this lane confirms: the")
    print("    16-bit-BE framing DOES desynchronise -- on 155 of the 297 streams.  It is")
    print("    exact on the other 142, and those 142 are a different consumer's.  See")
    print("    --families.")


def rep_sites():
    sites = code_sites()
    print("CODE SITES IN prom_c THAT NAME AN ADDRESS INSIDE 0x%06X-0x%06X" % (LO, HI - 1))
    print("derived from the %d PROVEN instruction lines of prom_c/wsa1_prom_c.s"
          % len(proven_instructions()))
    print()
    byop = Counter(m for _, m, _, _ in sites)
    for key, desc in MECH:
        print("  %-6s %-62s %4d" % (key, desc, byop.get(key, 0)))
    other = {m: c for m, c in byop.items() if m not in dict(MECH)}
    if other:
        print("  other mnemonics: %s" % other)
    print("  ---- %d sites total" % len(sites))
    print()
    print("  BY TARGET OBJECT (the base a table is indexed from):")
    bytgt = Counter(t for _, _, t, _ in sites)
    for t, c in sorted(bytgt.items(), key=lambda x: (-x[1], x[0])):
        nm = labels_by_address().get(t) or ""
        note = {DESCLO: "PoolDir_Records, stride 25 (`mul A,0x19`)",
                IDXLO: "PoolDir_RecordForUnitProgram",
                FRLO: "PoolDir_FieldRecords",
                PTRLO: "PoolDir_FieldRec_PtrTable, stride 4"}.get(t, nm)
        print("    0x%06X  x%-3d %s" % (t, c, note))
    print()
    print("  FIRST site 0x%06X %s" % (sites[0][0], sites[0][3]))
    print("  LAST  site 0x%06X %s" % (sites[-1][0], sites[-1][3]))


def rep_pointers():
    runs = pointer_runs()
    pw = pointer_words()
    print("POINTER WORDS (32-bit LE) IN THE prom_c IMAGE THAT LAND IN THE REGION")
    print("  %d words, in %d maximal stride-4 runs" % (len(pw), len(runs)))
    print()
    dirruns = [r for r in runs if DESCLO <= r[0] < IDXLO]
    big = [r for r in runs if r[1] >= 3 and not (DESCLO <= r[0] < IDXLO)]
    for a, n, lab in big:
        where = ("inside the region" if LO <= a < HI else "outside")
        print("  0x%06X  %3d words  %-28s %s" % (a, n, lab or "-", where))
    if dirruns:
        print("  0x%06X  %3d words  %-28s inside the region  <- %d runs of %d, one per"
              % (dirruns[0][0], sum(n for _, n, _ in dirruns), "PoolDir_Records",
                 len(dirruns), dirruns[0][1]))
        print("                                                    25-byte record; "
              "LAST run at 0x%06X" % dirruns[-1][0])
    single = [r for r in runs if r[1] < 3]
    print("  ... plus %d runs of 1-2 words (%d words), which are the 24-bit operands of"
          % (len(single), sum(n for _, n, _ in single)))
    print("      `lda`/`add` instructions read as if they were pointer words.")
    print()
    print("  ⚠ The 224 words in PoolDir_Records are NOT one table: they are field +0,")
    print("    +4, +8 and +12 of 56 25-byte records, and --families shows the four")
    print("    fields do not behave alike.")


def rep_frame():
    objs, streams, clean, be = pool()
    print("THE TWO FRAMINGS, WALKED FROM 0x%06X TO THE LAST BYTE OF THE REGION" % LO)
    print()
    a, nrec, nobj, stops = LO, 0, 0, []
    while a < DESCLO:
        e, recs, good = P.walk(a, DESCLO)
        if good:
            nrec += len(recs)
            nobj += 1
            a = e
        else:
            nxt = min([s for s in sorted(P.SEEDS)
                       if s > a and s < DESCLO and P.walk(s, DESCLO)[2]] + [DESCLO])
            stops.append((a, nxt, nobj))
            a = nxt
    print("  P7Stream_Run's reading (opcode nibble + 12-bit length, END = 0xFn):")
    print("    parses %d objects and %d records and reaches 0x%06X, the first byte of"
          % (nobj, nrec, DESCLO))
    print("    PoolDir_Records -- WITHOUT desynchronising, EXCEPT at %d places:" % len(stops))
    for s, e, k in stops:
        lab = labels_by_address().get(s) or "-"
        print("      after object #%-3d it stops at 0x%06X and resumes at 0x%06X "
              "(%d bytes, %s)" % (k, s, e, e - s, lab))
    print("    Each of those is a DATA table, not a desynchronisation: it is bounded by")
    print("    the next POINTED-AT address from which a walk does succeed, and the six of")
    print("    them plus the four directory objects tile the region exactly "
          "(gen_prom_c_p7stream_pool.py --verify).")
    print()
    nbe = sum(1 for s in streams if be[s])
    print("  sub_F9E140's reading (16-bit BIG-ENDIAN length, END = 0xF000):")
    print("    walked from every one of the %d stream starts, it reaches the terminator"
          % len(streams))
    print("    exactly on the object end for %d of them and DESYNCHRONISES on %d."
          % (nbe, len(streams) - nbe))
    firstbad = next(s for s in sorted(streams) if not be[s])
    k, ra, rop, rln = divergence(firstbad)
    v = (P.B(ra) << 8) | P.B(ra + 1)
    print("    First failure, cited at the RECORD the two readings first disagree on,")
    print("    not at the stream: stream 0x%06X, its record #%d at 0x%06X."
          % (firstbad, k, ra))
    print("      bytes %02X %02X ->  12-bit reading: opcode %2d, length %5d, next record"
          % (P.B(ra), P.B(ra + 1), rop, rln))
    print("                                                        at 0x%06X" % (ra + rln))
    print("                    ->  16-bit BE reading: length %5d, next record at 0x%06X"
          % (v, ra + v))
    print("    The object ends at 0x%06X; the BE walk leaves it after this record."
          % streams[firstbad]["end"])
    print("    Every one of the 155 failures is of this shape: the FIRST record whose")
    print("    opcode nibble is non-zero (checked for all 155 by --verify).")
    print()
    print("  ★ The two readings COINCIDE exactly when every record's opcode nibble is 0.")
    allop0 = {s for s, o in streams.items() if {op for _, op, _ in o["recs"]} <= {0, 15}}
    print("    all-opcode-0 streams: %d      BE-parsable streams: %d      same set: %s"
          % (len(allop0), nbe, allop0 == {s for s in streams if be[s]}))


def divergence(stream):
    """(record_index, addr, opcode, len12) of the FIRST record of `stream` on which
    P7Stream_Run's 12-bit reading and sub_F9E140's 16-bit-BE reading disagree, or
    None if they never do.

    They agree on a record when its opcode nibble is 0 (identical lengths) and on
    the END record when its bytes are exactly F0 00 (both stop).  Written in
    lockstep rather than by comparing two independent walks, because once the walks
    diverge their record NUMBERS stop meaning the same thing -- a mistake this
    script's first draft made and printed."""
    _, streams, _, _ = pool()
    for k, (a, op, ln) in enumerate(streams[stream]["recs"]):
        v = (P.B(a) << 8) | P.B(a + 1)
        if op == 15:
            if v != 0xF000:
                return k, a, op, ln
        elif not (op == 0 and v == ln):
            return k, a, op, ln
    return None


def rep_shift():
    _, streams, clean, be = pool()
    print("THE ONE INSTRUCTION THIS LANE COULD NOT PROVE, AND WHY IT STILL CONCLUDES")
    print()
    print("  0xF9E14B holds the three bytes  C9 EE 08.")
    print("    unidasm  : sll 0x08,A       (C9 = the 8-bit register A; D8 would be WA)")
    print("    the .s   : sll a, 8         (the LLVM backend agrees it is the byte form)")
    print("    MAME     : tlcs900_device::sla8(a, 8) shifts a BYTE left eight -> 0")
    print("               (900tbl.hxx: `count = (s & 0x0f) ? (s & 0x0f) : 16`)")
    print("  For comparison, P7Stream_Run's equivalent at 0xF9A6EA is D8 EE 08 --")
    print("  `sll 0x08,WA`, the SIXTEEN-bit form.  The two differ in the prefix byte only.")
    print()
    print("  Under MAME's semantics the high byte is discarded, so the value compared at")
    print("  0xF9E164 can never be 0xF000 and sub_F9E140 can never terminate.  It must")
    print("  terminate, and the data says exactly where:")
    ends = [(a, P.B(a), P.B(a + 1)) for s, o in streams.items()
            for a, op, ln in o["recs"] if op == 15]
    print("    END records in the pool: %d ; number whose bytes are NOT F0 00: %d"
          % (len(ends), sum(1 for _, b0, b1 in ends if (b0, b1) != (0xF0, 0x00))))
    allop0 = [s for s, o in streams.items() if {op for _, op, _ in o["recs"]} <= {0, 15}]
    lens = [ln for s in allop0 for _, op, ln in streams[s]["recs"] if op == 0]
    print("    non-terminator records in the %d streams this reader walks: %d"
          % (len(allop0), len(lens)))
    print("    of those, records with length >= 256 (i.e. b0 != 0x00): %d ; longest: %d"
          % (sum(1 for l in lens if l >= 256), max(lens)))
    print()
    print("  So the high byte matters ONLY at the terminator, and there it must weigh")
    print("  0x100.  The framing conclusion is safe; what is NOT settled is whether the")
    print("  byte-register decode of C9 EE 08 is right.  ⚠ If it is, MAME's TLCS-900 core")
    print("  and the real chip disagree here, and this routine is a test case for it.")


def rep_families():
    objs, streams, clean, be = pool()
    F = dir_fields()
    print("THE 56 PoolDir_Records (0x%06X, stride %d) -- FOUR POINTER FIELDS, TWO FAMILIES"
          % (DESCLO, DIRSTRIDE))
    print()
    print("  ⚠ WHICH FIELD 0xFA3D02 READS rests on one byte.  The instruction before it,")
    print("    0xFA3D00, is rendered `inc 0,XBC` by unidasm/MAME and `inc 8, xbc` by the")
    print("    LLVM backend the gate uses -- TLCS-900 encodes #8 as the 3-bit field 000.")
    print("    The LLVM reading is the right one, and the stack arithmetic in this very")
    print("    module proves it independently: sub_F9ADB5 cleans up three 4-byte")
    print("    arguments with `inc 8,XSP / inc 4,XSP` at 0xF9AE8D-0xF9AE8F (12 = 8+4, not")
    print("    4 = 0+4), and one word plus one long with `inc 6,XSP` at 0xF9AE34.")
    print()
    print("  field   distinct   group-clean   BE-parsable   read by")
    reader = {0:  "0xFA3D14 -> (XIZ-6)  -> sub_F9ADB5  arg+0x08 @0xFA3E12",
              4:  "0xFA3B13 -> (XIZ-10) -> P7Stream_Run           @0xFA3BB6",
              8:  "0xFA3D02 -> (XIZ-10) -> sub_F9ADB5  arg+0x0C @0xFA3E12",
              12: "0xFA3AEA -> (XIZ-6)  -> P7Stream_Run           @0xFA3B9C"}
    for f in (0, 4, 8, 12):
        tg = F[f]
        print("   +%-4d  %4d       %4d          %4d          %s"
              % (f, len(tg), sum(clean[s] for s in tg), sum(be[s] for s in tg), reader[f]))
    A = set(F[0]) | set(F[8])
    B = set(F[4]) | set(F[12])
    print()
    print("  +0 | +8  : %3d distinct streams   group-clean %3d   BE-parsable %3d"
          % (len(A), sum(clean[s] for s in A), sum(be[s] for s in A)))
    print("  +4 | +12 : %3d distinct streams   group-clean %3d   BE-parsable %3d"
          % (len(B), sum(clean[s] for s in B), sum(be[s] for s in B)))
    print("  overlap  : %d" % len(A & B))
    print()
    rest = sorted(set(streams) - A - B)
    print("  %d streams are in NEITHER family.  Of those, %d are group-clean and %d are"
          % (len(rest), sum(clean[s] for s in rest), sum(be[s] for s in rest)))
    print("  BE-parsable; %d have NO pointer anywhere in the image:" % len(
        [s for s in rest if s not in P.SEEDS]))
    for s in [s for s in rest if s not in P.SEEDS]:
        print("      0x%06X  %-11s %s" % (s, "group-clean" if clean[s] else "NOT clean",
                                          "BE-parsable" if be[s] else "not BE"))
    print()
    print("  LAST record, k=%d at 0x%06X:" % (NDIR - 1, DESCLO + DIRSTRIDE * (NDIR - 1)))
    for f in (0, 4, 8, 12):
        v = P.U32(DESCLO + DIRSTRIDE * (NDIR - 1) + f)
        print("    +%-3d 0x%06X  %-11s %s" % (f, v, "group-clean" if clean[v] else "NOT clean",
                                              "BE-parsable" if be[v] else "not BE"))


def rep_consumer():
    objs, streams, clean, be = pool()
    lit = second_consumer_sites()
    allc = all_second_calls()
    progs = sorted({c[1] for c in P.CALLS})
    print("THE SECOND CONSUMER: sub_F9ADB5 at 0x%06X" % SECOND)
    print()
    print("  It reads the SAME six-byte relocation record as P7Stream_Run, at")
    print("  `record_table + 6*index - 6`:")
    print("      0xF9ADBA  ld BC,0x0006 / muls XBC,(XIZ+0x1a) / dec 6,XBC / add XBC,(XIZ+0x16)")
    print("      bytes 0,1,2,4,5 -> (0x008614) (0x008616) (0x008618) (0x00861A) (0x00861C)")
    print("      byte 5 is the DESTINATION: `ld C,(0x00861C) / push BC` before every")
    print("      P7Byte_SendCmd (0xF9AE5D, 0xF9AEAC) and P7Byte_SendArg (0xF9AE6A, 0xF9AE77).")
    print("      ⚠ It does NOT read byte 3, and does not shift byte 4 left 8, both of")
    print("        which P7Stream_Run does -- so the two are not the same decoder.")
    print("  Its framer is sub_F9E140 (0x%06X): 16-bit BIG-ENDIAN length, END = 0xF000." % FRAMER)
    print("  Its per-iteration reader is sub_F9B54B (0x%06X), reached from the loop at" % INNER)
    print("  0xF9AE48 that runs while the cursor is below (0x00861E) -- the block end")
    print("  sub_F9E140 stored at 0xF9E17F.")
    print()
    calr = calr_sites(SECOND)
    print("  LITERAL CALL SITES (%d of the %d `call 0x%06X` sites carry two literal streams;"
          % (len(lit), len(allc), SECOND))
    print("  there are %d further `calr` site(s) -- %s -- which pass RAM pointers, so the"
          % (len(calr), " ".join("0x%06X" % a for a in calr)))
    print("  routine's own header count of %d is accounted for):" % (len(allc) + len(calr)))
    for a, s08, s0c in lit:
        print("    call 0x%06X   (XIZ+0x08)=0x%06X %-11s   (XIZ+0x0C)=0x%06X %-11s"
              % (a, s08, "BE" if be.get(s08) else "not BE",
                 s0c, "BE" if be.get(s0c) else "not BE"))
    S = {s for _, a, b in [(0, x, y) for _, x, y in lit] for s in (a, b)}
    print()
    print("  distinct streams at those sites: %d   BE-parsable: %d   group-clean: %d"
          % (len(S), sum(be[s] for s in S), sum(clean[s] for s in S)))
    print("  distinct streams at P7Stream_Run's %d literal sites: %d   BE-parsable: %d   "
          "group-clean: %d" % (len(P.CALLS), len(progs), sum(be[s] for s in progs),
                               sum(clean[s] for s in progs)))
    print("  overlap between the two consumers' literal streams: %d"
          % len(S & set(progs)))


# ------------------------------------------------------------------- verify
def verify():
    fails = []

    def chk(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)

    objs, streams, clean, be = pool()
    F = dir_fields()
    A = set(F[0]) | set(F[8])
    B = set(F[4]) | set(F[12])
    sites = code_sites()
    lit = second_consumer_sites()
    progs = sorted({c[1] for c in P.CALLS})

    print("THE BRIEFING'S PREMISE")
    chk(not incbin_lines(),
        "prom_c/wsa1_prom_c.s has NO .incbin DIRECTIVE (a plain grep finds 34, all in "
        "comments) -- the region is converted")
    src = open(SRC).read()
    chk("P7Stream_Run:" in src and "P7Stream_FCD0F7:" in src,
        "the interpreter label P7Stream_Run and the first stream label are both in the .s")

    print("MECHANISM CENSUS (from the byte-gate-proven .s)")
    ctl = [s for s in sites if s[1] in ("call", "jp", "jr", "jrl", "calr")]
    chk(not ctl, "NO proven instruction transfers control into the region -- %d such sites "
                 "(it is data, not code)" % len(ctl))
    chk(len(sites) > 0 and all(LO <= t < HI for _, _, t, _ in sites),
        "%d code sites, every literal inside the region" % len(sites))
    lda = [s for s in sites if s[1] == "lda"]
    add = [s for s in sites if s[1] == "add"]
    chk(len(lda) + len(add) == len(sites),
        "every site is `lda` (%d, address taken) or `add` (%d, indexed base) -- no other "
        "mnemonic reaches the region" % (len(lda), len(add)))
    bases = {t for _, m, t, _ in sites if m == "add"}
    chk(bases == {DESCLO, IDXLO, PTRLO},
        "the indexed bases are exactly THREE of the four directory objects: %s.  "
        "PoolDir_FieldRecords (0x%06X) is NOT indexed from a literal -- it is reached "
        "only through PoolDir_FieldRec_PtrTable, `mul C,4 / add XBC,0x00FDD1CB / "
        "ld XBC,(XBC) / add XBC,XIX` at 0xFA3DC6-0xFA3DD5, and the 7-byte stride of "
        "its records is the `mul C,0x07` at 0xFA3DBD"
        % (" ".join("0x%06X" % b for b in sorted(bases)), FRLO))
    # last-element test
    chk(sites[-1][0] > sites[0][0] and LO <= sites[-1][2] < HI,
        "LAST site 0x%06X (%s) -- checked, not only the first (0x%06X)"
        % (sites[-1][0], sites[-1][3], sites[0][0]))

    print("THE FRAMING, TO THE LAST BYTE")
    total = sum(o["end"] - o["start"] for o in objs)
    chk(total == HI - LO and objs[-1]["end"] == HI,
        "the 12-bit reading tiles all %d bytes and its last object ends at 0x%06X" % (total, HI))
    nbe = sum(1 for s in streams if be[s])
    allop0 = {s for s, o in streams.items() if {op for _, op, _ in o["recs"]} <= {0, 15}}
    chk(allop0 == {s for s in streams if be[s]},
        "BE-parsable == all-opcode-0, both %d streams -- so the two readings coincide "
        "exactly there and nowhere else" % nbe)
    # the loose-guard control: does the v==0 guard change the answer?
    def be_noguard(a, limit=DESCLO):
        seen = 0
        while a < limit and seen < 100000:
            v = (P.B(a) << 8) | P.B(a + 1)
            if v == 0xF000:
                return a + 2, True
            if v == 0 or a + v > limit:
                return a, False
            a += v
            seen += 1
        return a, False
    chk(all((be_noguard(s)[1] and be_noguard(s)[0] == o["end"]) == be[s]
            for s, o in streams.items()),
        "the v==0 loop guard changes no stream's verdict")
    div = {s: divergence(s) for s in streams}
    chk(all((div[s] is None) == be[s] for s in streams),
        "a stream is BE-parsable exactly when NO record diverges -- lockstep check over "
        "all %d streams" % len(streams))
    chk(all(div[s][2] != 0 for s in streams if div[s] is not None),
        "all %d failures diverge at a record whose opcode nibble is NON-ZERO"
        % sum(1 for s in streams if div[s] is not None))
    ends = [(P.B(a), P.B(a + 1)) for s, o in streams.items()
            for a, op, ln in o["recs"] if op == 15]
    chk(all(e == (0xF0, 0x00) for e in ends),
        "all %d END records are exactly F0 00 -- which is 0xF000 only if the high byte "
        "weighs 0x100, so sub_F9E140's compare at 0xF9E164 fixes the reading (see "
        "--shift)" % len(ends))
    allop0 = [s for s in streams if be[s]]
    lens = [ln for s in allop0 for _, op, ln in streams[s]["recs"] if op == 0]
    chk(max(lens) < 256,
        "no non-terminator record in the %d streams that reader walks has length >= 256 "
        "(longest %d), so b0 is 0x00 everywhere except at the terminator -- the data "
        "cannot discriminate the two shift semantics and does not pretend to"
        % (len(allop0), max(lens)))

    print("THE TWO FAMILIES")
    chk(len(A) == 112 and len(B) == 112 and not (A & B),
        "fields +0|+8 reach %d streams, fields +4|+12 reach %d, and the two sets are "
        "DISJOINT" % (len(A), len(B)))
    chk(sum(clean[s] for s in A) == 0,
        "0 of the %d +0|+8 streams is group-clean -- P7Stream_Run cannot frame any of them"
        % len(A))
    chk(sum(be[s] for s in A) == len(A),
        "%d of %d +0|+8 streams parse under sub_F9E140's 16-bit-BE reading, to the exact "
        "object end" % (sum(be[s] for s in A), len(A)))
    chk(sum(clean[s] for s in B) == len(B),
        "%d of %d +4|+12 streams ARE group-clean" % (sum(clean[s] for s in B), len(B)))
    chk(sum(be[s] for s in B) == 0,
        "0 of the %d +4|+12 streams is BE-parsable" % len(B))
    dirty = {s for s in streams if not clean[s]}
    chk(dirty <= {s for s in streams if be[s]},
        "ALL %d streams P7Stream_Run cannot frame are BE-parsable (%d BE-parsable in all, "
        "so %d are framable BOTH ways and are genuinely ambiguous)"
        % (len(dirty), nbe, nbe - len(dirty)))
    # last-element test on the directory
    k = NDIR - 1
    last = [P.U32(DESCLO + DIRSTRIDE * k + 4 * f) for f in range(4)]
    chk(all(v in streams for v in last)
        and not clean[last[0]] and clean[last[1]]
        and not clean[last[2]] and clean[last[3]]
        and be[last[0]] and not be[last[1]] and be[last[2]] and not be[last[3]],
        "LAST record k=%d at 0x%06X obeys the same +0/+4/+8/+12 pattern as the first "
        "(%s)" % (k, DESCLO + DIRSTRIDE * k, " ".join("0x%06X" % v for v in last)))
    first = [P.U32(DESCLO + 4 * f) for f in range(4)]
    chk(not clean[first[0]] and clean[first[1]] and not clean[first[2]] and clean[first[3]],
        "FIRST record k=0 at 0x%06X likewise (%s)"
        % (DESCLO, " ".join("0x%06X" % v for v in first)))

    print("THE FOUR DIRECTORY FIELDS ARE READ BY NAMED CODE")
    # (offset, literal-load site, the call it is pushed to, callee)
    FIELDREAD = [(0x00, 0xFA3D14, 0xFA3E12, SECOND),
                 (0x04, 0xFA3B13, 0xFA3BB6, RUN_ADDR),
                 (0x08, 0xFA3D02, 0xFA3E12, SECOND),
                 (0x0C, 0xFA3AEA, 0xFA3B9C, RUN_ADDR)]
    txt = {a: t for a, t in proven_instructions()}
    for off, site, call, callee in FIELDREAD:
        ok = (txt.get(site, "").replace(" ", "").lower()
              == "addxbc,0x00fdbfd9" or
              txt.get(site, "").replace(" ", "").lower() == "addxwa,0x00fdbfd9")
        ok = ok and txt.get(call, "").lower().replace(" ", "") == "call0x%06x" % callee
        chk(ok, "field +%-2d: 0x%06X is `%s` and 0x%06X is `%s`"
            % (off, site, txt.get(site, "?"), call, txt.get(call, "?")))
    chk({c for _, _, _, c in FIELDREAD} == {SECOND, RUN_ADDR},
        "the four fields are split two-and-two between the two consumers")

    print("THE SECOND CONSUMER'S CALL SITES")
    allc = all_second_calls()
    calr = calr_sites(SECOND)
    chk(len(allc) == 22 and len(lit) == 9 and len(calr) == 1,
        "%d `call` + %d `calr` = %d sites for 0x%06X (its header says 23); %d of the "
        "`call` sites carry two literal pool streams"
        % (len(allc), len(calr), len(allc) + len(calr), SECOND, len(lit)))
    S = set()
    for _, a, b in lit:
        S |= {a, b}
    chk(all(s in streams for s in S), "all %d literal arguments are stream starts" % len(S))
    chk(all(be[s] for s in S),
        "%d of %d literal arguments are BE-parsable -- ZERO exceptions" % (sum(be[s] for s in S), len(S)))
    chk(sum(be[s] for s in progs) == 0,
        "0 of P7Stream_Run's %d literal streams is BE-parsable" % len(progs))
    chk(not (S & set(progs)),
        "the two consumers' literal stream sets do not overlap (|A|=%d |B|=%d)"
        % (len(S), len(progs)))
    both = {s for s in streams if be[s] and clean[s]}
    chk(len(both) == 12,
        "%d streams are framable BOTH ways (all-opcode-0 AND every length a multiple "
        "of 5)" % len(both))
    chk(both & S == {s for s in S if clean[s]} and len(both & S) == 9,
        "%d of those %d are literal sub_F9ADB5 arguments, so their consumer is settled"
        % (len(both & S), len(both)))
    chk(sorted(both - S) == [0xFCD0F7, 0xFCD0FE, 0xFCD105],
        "the remaining %d stay AMBIGUOUS -- %s -- and are reached only from "
        "P7Unit_StreamPtrsByGroupAndUnit" % (len(both - S),
                                    " ".join("0x%06X" % x for x in sorted(both - S))))
    chk(lit[-1] == (0xFA4DFA, 0xFCD97D, 0xFCD173),
        "LAST literal site is call 0x%06X (0x%06X, 0x%06X) -- checked, not only the first "
        "(call 0x%06X)" % (lit[-1] + (lit[0][0],)))

    print()
    if fails:
        print("FAILED: %d check(s)" % len(fails))
        return 1
    print("ALL CHECKS PASSED")
    return 0


def main():
    if "--stale" in sys.argv:
        rep_stale()
    elif "--sites" in sys.argv:
        rep_sites()
    elif "--pointers" in sys.argv:
        rep_pointers()
    elif "--frame" in sys.argv:
        rep_frame()
    elif "--shift" in sys.argv:
        rep_shift()
    elif "--families" in sys.argv:
        rep_families()
    elif "--consumer" in sys.argv:
        rep_consumer()
    elif "--verify" in sys.argv:
        return verify()
    else:
        print(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main())
