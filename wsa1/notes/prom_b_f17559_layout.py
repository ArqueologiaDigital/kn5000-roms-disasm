#!/usr/bin/env python3
"""The LAYOUT of prom_b 0xF17559-0xF1B3FF (16,039 bytes), derived from the ROM.

QUESTION IT ANSWERS
  "Which bytes of this `.incbin` are display-list records, which are the operand
   and string tables those records point at, which are dispatch tables, and what
   is left over?"  Every byte of the span is assigned, in address order, with no
   gap and no overlap, and every boundary names the evidence that pins it.

WHERE THE EVIDENCE COMES FROM -- AND WHY IT IS NOT A DECODE
  The span holds NO code.  Exactly THIRTEEN addresses inside it are the target of
  a transfer anywhere in the four `.s` files, and all thirteen are the `jp` slots
  of one thunk run, T_F42FD0-T_F43000 -- which is STALE:

    * every one of the 13 slots has ZERO references: no 32-bit word in
      prom_a/prom_b/prom_c spells the slot address, and no opcode-anchored
      `call`/`jp` targets it;
    * ELEVEN of the 13 targets land INSIDE a display-list record rather than at
      its start, in lists whose two ends prom_a call sites name;
    * two of the targets, 0xF19C18 and 0xF19C19, are ONE BYTE apart.

  `--anchors --negatives` prints the census and `--selftest` re-derives all four
  numbers.  ⚠ The first draft of this check reported "NONE", which was a pass
  that could not fail: the thunk table lines are labelled and carry no `; ADDR`
  comment, so the instruction filter dropped all ~4,000 slots.  A negative is
  only worth having when the instrument can see the thing it denies.

  So a linear or recursive decode pins nothing here, and this script runs none.
  What it runs instead, in priority order:

  E0 NAMED     -- the address is an operand of a proven instruction somewhere in
     prom_a/prom_b/prom_c/prom_d.  236 distinct addresses in this span are named
     that way, from 330 instructions, and every one of them is an object
     boundary.  ⚠ Read BOTH the body and the `; ADDR  <mame text>` comment of a
     line: prom_a spells operands in hex in the body, prom_b spells them in
     DECIMAL in the body and in hex only in the comment.  This script's first
     draft read the body alone and found 2 references instead of 330.
  ⚠ THE BRIEFING'S RUN COUNT FOR THIS SPAN IS WRONG, AND --selftest SAYS SO
    notes/WAVE7-BRIEFING.md says "THIRTY-SIX of those 41 runs are inside this
    span".  `notes/prom_b_dl_call_shapes.py --new` reports 41 runs / 5,247 bytes
    in the whole image, of which **25 runs / 3,157 bytes** start inside
    0xF17559-0xF1B400 (the other 16 are at 0xF13F1E-0xF15023 and
    0xF542ED-0xF5470F).  Both numbers are re-derived by --selftest.

  E1 CALLSITE  -- a display-list call site, read off the proven text.
     `lda R,<end> / push R / lda R2,<start> / push R2` names a record run;
     `lda R,<rec> / push R / ... call T_F42E08|T_F42E0C` names ONE record.
     64 pair sites and 57 single-record sites name this span.
     ⚠ 28 of the 64 pairs have NO literal `call`: prom_a 0xFBE25F reaches the
     interpreter with `lda XIY,<return> / push XIY / jp (XIX)`.  A rule that
     insists on a literal call loses them.
     ⚠ `notes/prom_b_dl_call_shapes.py` scans BYTES for four fixed shapes; here
     it reports 26 shape-2 + 29 shape-3 sites, and every one of them is in this
     scan's 121.  It misses the register-pair variants (`lda XWA,<end> / push /
     lda XIY,<start> / push`, prom_a 0xFBFA35), the `jp (XIX)` tail-calls, and
     every site with a `jr` between the push and the call.
  E2 COPYLEN   -- `ldw BC,N / lda XIY,<obj> / ldir` (bytes) or `ldirw` (words):
     the object at <obj> is N or 2N bytes, stated by the firmware.  Eleven
     objects at 0xF1AA7C-0xF1AB0A are sized this way and TEN of the eleven land
     exactly on the next one's start -- the eleventh, 0xF1AAEC, is followed by
     nine bytes of 0x00 pad.  0xF1AAA9 is a 12-byte interpreter-A op-03 record
     copied to the stack and run, and its BC x HL = 3 x 17 is what sizes the
     51-byte bitmap at 0xF17C59.
  E3 TABLEBASE -- `add Rx,<base>` followed by a load through Rx: <base> is a
     table and the load's operand size is its entry width (1, 2 or 4).  39 bases.
     The entry COUNT is the extent to the next anchor divided by that width.
  E4 RECPTR    -- an interpreter-B record's `+7` pointer with its `+0x0B` width
     word, or an interpreter-A op-03/04 record's `+2` pointer with BC columns x
     HL rows.  ⚠ THE AND MASK IS NEVER USED AS A COUNT (see below).
  E5 PTRCHAIN  -- three or more consecutive 32-bit words that are all addresses
     inside prom_a or prom_b.  Its ENTRIES are anchors only when something
     REFERENCES the chain (see "the stale table" below).
  E6 CONTENT   -- VALUECELL, LISTCOPY, GLYPHCOPY, FILL, each with a measured
     null (`--null`).

⚠ THE FRAMING WALK IS NOT, BY ITSELF, EVIDENCE
  `--null-frame` offers every aligned chunk of 8..64 bytes of this span's PROVEN
  NON-LIST data (its `add`-sized tables and `ldir`-sized descriptors) to the same
  walk that frames a display list: 694 of 248,097 chunks (0.28%) are accepted.
  So a `display_list` segment here is never justified by the walk alone -- both
  ends are E0/E1 anchors as well, and the four runs (155 bytes, 1.0% of the span)
  whose bounds are plain E0 references with no call site say so in their evidence
  column and are listed by `--null-frame`.

⚠ THE MASK IS NOT A COUNT, AND THIS SPAN PROVES IT BOTH WAYS
  A record's `+4` AND mask, shifted right by its `+5` shift, bounds the INDEX,
  not the array.  Here the two agree (0xF1A62F: 128 indices, extent 384 = 128 x 3)
  and disagree (0xF1854D: 32 indices allowed, extent 112 = 14 x 8).  The extent
  always wins; the mask is only ever quoted as a corroboration.

⚠ THE STALE POINTER TABLE, AND WHY ITS ENTRIES ARE NOT ANCHORS
  0xF17A6C is a textbook 29-entry pointer table: 29 consecutive words, stride
  exactly 72, first target the byte after the table.  With the 13 bytes before it
  and the 288 after it, it is a TRUNCATED RELOCATED COPY of the 24x24
  value-glyph module at 0xF31DED/0xF31E6D/0xF31EE1 -- the last 13 bytes of that
  module's 128-byte quantiser, its pointer table rebased, and the first FOUR of
  its 29 glyph bitmaps, byte-identical.  Targets 4..28 (0xF17C00..0xF182C0) land
  in live display-list data that prom_a call sites name, and NOTHING in
  prom_a/prom_b/prom_c/prom_d references 0xF17A6C.  Feeding its entries to the
  tiler as anchors cuts three record arrays in the wrong place: measured by
  `--stale`, it turns 28 unassigned bytes into 2,239.  So E5 promotes a chain's
  entries to anchors only when the chain's own base is referenced.

RUN
  python3 notes/prom_b_f17559_layout.py              # the layout
  python3 notes/prom_b_f17559_layout.py --anchors    # every anchor + its evidence
  python3 notes/prom_b_f17559_layout.py --sites      # display-list call sites
  python3 notes/prom_b_f17559_layout.py --coalesced  # same, adjacent kinds folded
  python3 notes/prom_b_f17559_layout.py --residue    # unassigned runs, in hex
  python3 notes/prom_b_f17559_layout.py --stale      # the cost of the stale table
  python3 notes/prom_b_f17559_layout.py --siblings   # every value-glyph module
  python3 notes/prom_b_f17559_layout.py --null       # content-rule calibration
  python3 notes/prom_b_f17559_layout.py --null-frame # the framing rule on non-lists
  python3 notes/prom_b_f17559_layout.py --selftest   # checks, incl. LAST elements
  python3 notes/prom_b_f17559_layout.py --python     # paste-ready SEGMENTS
Exit status is non-zero if the layout does not tile, or if a self-check fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                                  # noqa: E402
import prom_b_dl_length_audit as LA                                # noqa: E402

B_BASE = 0xF00000
LO, HI = 0xF17559, 0xF1B400

# the display-list entry points, by thunk slot
RUN_A, RUN_B = 0xF42E00, 0xF42E04            # (start,end) pair on the stack
ONE_A, ONE_B = 0xF42E08, 0xF42E0C            # one record on the stack
RUN_A_I, RUN_B_I = 0xF417F0, 0xF417F4        # the XIY/XIX register forms
# routines that take a parameter descriptor as their first stack argument
DESC_CALLS = (0xF42C78, 0xF42C90, 0xF42C94, 0xF42C98, 0xF42CA8)

# the live 24x24 value-glyph module this span holds a truncated copy of
GLYPH_QUANT, GLYPH_PTRS, GLYPH_BMPS, GLYPH_N, GLYPH_SZ = \
    0xF31DED, 0xF31E6D, 0xF31EE1, 29, 72

VALUECELL = re.compile(r"^(?:[ 0-9][0-9]\.[0-9][0-9]|  \.  )$")
FILL_BYTE, FILL_MIN = 0x0E, 16

_cache = {}
FAIL = []


# ------------------------------------------------------------------ the images
def rom(which="b"):
    if which not in _cache:
        a, b = DL.load()
        _cache["a"], _cache["b"] = a, b
        _cache["c"] = open(os.path.join(ROOT, "original_ROMs",
                                        "wsa1_prom_c.ic28"), "rb").read()
    return _cache[which]


def base_of(prom):
    return B_BASE if prom == "b" else 0xF80000


def by(a, n=1):
    return rom("b")[a - B_BASE:a - B_BASE + n]


def w32(a):
    return int.from_bytes(by(a, 4), "little")


def in_image(v):
    return 0x00F00000 <= v < 0x01000000


# ------------------------------------------------- the PROVEN instruction text
def instructions(prom):
    """[(addr, text)] for every line of prom_<prom>/wsa1_prom_<prom>.s that the
    byte gate certifies is an instruction, in address order.

    A line qualifies when it carries a `; ADDR  ...` comment, its body is
    indented and its body is not a directive -- the same test
    notes/prom_b_f65000_layout.py's proven_code_runs() uses.  `text` is body and
    comment joined, because prom_a spells its operands in HEX IN THE BODY while
    prom_b spells them in DECIMAL in the body and in hex in the MAME comment; a
    scan that reads only one of the two silently misses a whole image (this one
    missed all 45 prom_a references on its first draft)."""
    key = "I" + prom
    if key in _cache:
        return _cache[key]
    p = image_path(ROOT, "prom_%s/wsa1_prom_%s.s" % (prom, prom))
    out = []
    if os.path.exists(p):
        for line in open(p):
            i = line.find(";")
            body = line[:i] if i >= 0 else line
            m = re.search(r";\s*([0-9A-F]{6})\s\s(.*)$", line.rstrip("\n"))
            if not m or not body.startswith("\t") or body.lstrip().startswith("."):
                continue
            out.append((int(m.group(1), 16), body.strip() + "  |  " + m.group(2)))
    out.sort()
    _cache[key] = out
    return out


def constants(text):
    """Every integer an instruction line names, hex or decimal."""
    v = set()
    for h in re.findall(r"0x([0-9a-fA-F]{4,8})", text):
        v.add(int(h, 16))
    for d in re.findall(r"(?<![\w.$])(\d{7,9})(?![\w.])", text):
        v.add(int(d))
    return v


def references():
    """{target inside the span: [(prom, instruction address, text)]}"""
    if "R" in _cache:
        return _cache["R"]
    out = {}
    for prom in ("a", "b", "c", "d"):
        for addr, text in instructions(prom):
            for v in constants(text):
                if LO <= v < HI:
                    out.setdefault(v, []).append((prom, addr, text))
    _cache["R"] = out
    return out


def code_targets():
    """{in-span target: [lines that transfer to it]} over ALL FOUR .s files.

    ⚠ This scans EVERY line with a transfer mnemonic, not only the lines the
    `; ADDR` filter calls instructions.  The first draft used instructions() and
    reported ZERO targets -- a pass that could not fail, because the thunk table
    is written `T_F42FD0:\tjp 0xF19C18  ; -> prom_b 0x19C18`, a labelled line
    whose comment carries no address, so instructions() drops all 4,000 thunk
    slots.  Thirteen of them point into this span."""
    out = {}
    for prom in ("a", "b", "c", "d"):
        path = image_path(ROOT, "prom_%s/wsa1_prom_%s.s" % (prom, prom))
        if not os.path.exists(path):
            continue
        for line in open(path):
            i = line.find(";")
            body = line[:i] if i >= 0 else line
            if not re.search(r"\b(call|jp|jr|jrl|calr)\b", body):
                continue
            for v in constants(line):
                if LO <= v < HI:
                    out.setdefault(v, []).append("prom_%s: %s" % (prom, line.strip()))
    return out


def slot_refs(slot):
    """(32-bit words spelling `slot`, opcode-anchored call/jp sites targeting it)
    over all four images -- the reference census for a thunk slot."""
    w = slot.to_bytes(4, "little")
    n32 = sum(rom(x).count(w) for x in ("a", "b", "c"))
    n24 = 0
    for x in ("a", "b", "c"):
        d = rom(x)
        for i in range(len(d) - 3):
            if d[i] in (0x1D, 0x1B) and (d[i + 1] | d[i + 2] << 8
                                         | d[i + 3] << 16) == slot:
                n24 += 1
    return n32, n24


def stale_thunks():
    """[(slot, target, referenced?, lands on a record boundary?)] for every thunk
    slot whose `jp` target is inside the span."""
    segs = build()
    bounds = set()
    for k, a, n, _w in segs:
        if k in ("display_list", "record_array"):
            r = framed(a, a + n)
            if r:
                bounds |= {p for p, _op, _ln in r}
    out = []
    path = image_path(ROOT, "prom_b/wsa1_prom_b.s")
    for line in open(path):
        m = re.match(r"T_([0-9A-F]{6}):\s*jp\s+0x([0-9A-F]{6})", line)
        if not m:
            continue
        slot, tgt = int(m.group(1), 16), int(m.group(2), 16)
        if LO <= tgt < HI:
            out.append((slot, tgt, slot_refs(slot), tgt in bounds))
    return out


# ------------------------------------------------------ E1: display-list sites
def dl_sites():
    """[(start, end|None, thunk, prom, call address)] from the proven text.

    The pairing is ADJACENCY-BASED, not "the last two immediates before the
    call": `lda R,(END) / push R / lda R2,(START) / push R2` is four consecutive
    instructions, and only then is a display-list call looked for in the next
    twelve.  The first draft of this function used the last-two rule and got
    0xF17C08-0xF17C2A wrong, because prom_a 0xFBE243 chooses between two lists
    with a `jr` and BOTH pairs sit before the one call.  A pair is kept only if
    the framing walk from START lands exactly on END, which is what rejects a
    pairing that crosses a branch.

    ⚠ Shape 1 (`ld XIY,<start> / ld XIX,<end> / call T_F417F0`) puts the START
    first, the stack shapes put the END first.  Both are handled; no shape-1 site
    names this span."""
    if "S" in _cache:
        return _cache["S"]
    pair = {RUN_A: "A", RUN_B: "B"}
    one = {ONE_A: "A", ONE_B: "B"}
    reg = re.compile(r"\b(?:lda_?2?4?|ld)\s+(x[a-z]{2}),\s*\(?(?:0x)?([0-9a-f]{4,8})\)?",
                     re.I)
    out = []
    for prom in ("a", "b", "c", "d"):
        ins = instructions(prom)

        def imm(k):
            """(register, value) if instruction k loads an in-span address."""
            if k < 0 or k >= len(ins):
                return None
            m = reg.search(ins[k][1])
            if not m:
                return None
            for v in constants(ins[k][1]):
                if LO <= v < HI:
                    return m.group(1).lower(), v
            return None

        def pushes(k, r):
            return k < len(ins) and re.search(r"\bpush\s+%s\b" % r, ins[k][1], re.I)

        def call_after(k, table):
            for j in range(k, min(len(ins), k + 12)):
                if not re.search(r"\bcall\b", ins[j][1]):
                    continue
                for v in constants(ins[j][1]):
                    if v in table:
                        return v, ins[j][0]
                return None
            return None

        for i in range(len(ins)):
            a, b = imm(i), imm(i + 2)
            if a and b and pushes(i + 1, a[0]) and pushes(i + 3, b[0]):
                if b[1] < a[1] and framed(b[1], a[1]):
                    c = call_after(i + 4, pair)
                    # ⚠ the call is NOT required.  prom_a 0xFBE25F reaches the
                    # interpreter with `lda XIY,<return> / push XIY / jp (XIX)`,
                    # a tail-call through a register, so a rule that insists on a
                    # literal `call T_F42E00` loses 0xF17C08-0xF17C2A and its
                    # neighbours.  What IS required is that the framing walk from
                    # START land exactly on END -- see --null-frame for the rate
                    # at which that happens by accident.
                    out.append((b[1], a[1], c[0] if c else None, prom,
                                c[1] if c else ins[i][0]))
                    continue
            if a and pushes(i + 1, a[0]):
                if b and pushes(i + 3, b[0]):
                    continue                       # it is the pair form
                c = call_after(i + 2, one)
                if c:
                    out.append((a[1], None, c[0], prom, c[1]))
        # shape 1: ld XIY,<start> / ld XIX,<end> / call
        for i in range(len(ins) - 2):
            a, b = imm(i), imm(i + 1)
            if not (a and b and a[0] == "xiy" and b[0] == "xix"):
                continue
            c = call_after(i + 2, {RUN_A_I: "A", RUN_B_I: "B"})
            if c and a[1] < b[1] and framed(a[1], b[1]):
                out.append((a[1], b[1], c[0], prom, c[1]))
    _cache["S"] = out
    return out


# ------------------------------------------------------------ E2: copy lengths
def copy_lengths():
    """{object address: (length, prom, instruction address)} from
    `ldw BC,N / lda XIY,<obj> / ldir|ldirw`."""
    out = {}
    for prom in ("a", "b"):
        ins = instructions(prom)
        for i, (addr, text) in enumerate(ins):
            m = re.search(r"lda_?2?4?\s+xiy,\s*\(0x([0-9a-f]{6})\)", text)
            if not m:
                continue
            v = int(m.group(1), 16)
            if not (LO <= v < HI):
                continue
            n = None
            for j in range(max(0, i - 3), i):
                mm = re.search(r"ldw?\s+bc,\s*0x([0-9a-f]+)", ins[j][1])
                if mm:
                    n = int(mm.group(1), 16)
            if n is None:
                continue
            for j in range(i + 1, min(len(ins), i + 5)):
                if "ldirw" in ins[j][1]:
                    out[v] = (2 * n, prom, addr)
                    break
                if "ldir" in ins[j][1]:
                    out[v] = (n, prom, addr)
                    break
    return out


# ------------------------------------------------------------- E3: table bases
WIDTH_RE = [(4, re.compile(r"\bld\s+X(?:WA|BC|DE|HL|IX|IY|IZ)\s*,\s*\(X", re.I)),
            (2, re.compile(r"\bld\s+(?:WA|BC|DE|HL|IX|IY|IZ)\s*,\s*\(X", re.I)),
            (1, re.compile(r"\bld\s+[ABCDEHLW]\s*,\s*\(X", re.I))]


def table_bases():
    """{base: (width, prom, instruction address)} from `add Rx,<base>` followed by
    a load through Rx.  The load's operand size IS the entry width."""
    out = {}
    for prom in ("a", "b"):
        ins = instructions(prom)
        for i, (addr, text) in enumerate(ins):
            m = re.search(r"add\s+X(?:WA|BC|DE|HL|IX|IY|IZ),0x00([0-9a-f]{6})", text)
            if not m:
                continue
            v = int(m.group(1), 16)
            if not (LO <= v < HI):
                continue
            for j in range(i + 1, min(len(ins), i + 3)):
                hit = None
                for w, rx in WIDTH_RE:
                    if rx.search(ins[j][1]):
                        hit = w
                        break
                if hit:
                    out[v] = (hit, prom, addr)
                    break
    return out


def desc_sites():
    """Addresses passed as the first stack argument of a parameter-descriptor
    routine (`lda XBC,<obj> / push XBC / ... / call T_EditValue_StepBitField|90|94|98`)."""
    out = {}
    for prom in ("a", "b"):
        ins = instructions(prom)
        for i, (addr, text) in enumerate(ins):
            m = re.search(r"lda_?2?4?\s+xbc,\s*\(0x([0-9a-f]{6})\)", text)
            if not m:
                continue
            v = int(m.group(1), 16)
            if not (LO <= v < HI):
                continue
            for j in range(i + 1, min(len(ins), i + 7)):
                cs = constants(ins[j][1])
                if re.search(r"\bcall\b", ins[j][1]) and (cs & set(DESC_CALLS)):
                    out.setdefault(v, (prom, addr))
                    break
    return out


# ----------------------------------------------------------- E4: record fields
BPTR = {0xF31B21: (7, 11), 0xF31B39: (7, 11), 0xF31B57: (7, None),
        0xF31B86: (7, None)}
BSTRIDE = {0xF31B57: 8, 0xF31B86: 6}


def record_pointers(records):
    """{target: [(width, source record, why)]} over a set of framed records."""
    ta, tb = LA.tables(rom("b"))
    out = {}
    for p, op, ln in records:
        r = by(p, ln)
        if op < 0x0F and tb[op] in BPTR:
            kind, need = LA.IMPLIED_B[tb[op]]
            if (ln == need) if kind == "fixed" else (ln >= need):
                po, wo = BPTR[tb[op]]
                ptr = int.from_bytes(r[po:po + 4], "little")
                w = int.from_bytes(r[wo:wo + 2], "little") if wo else BSTRIDE[tb[op]]
                mask, shift = r[4], r[5] & 7
                if LO <= ptr < HI and 0 < w <= 64:
                    out.setdefault(ptr, []).append(
                        (w, p, "record 0x%06X +7, width %d, mask 0x%02X>>%d"
                         % (p, w, mask, shift)))
        if op < 0x24 and ta[op] == 0xF31ABE and ln >= 12:
            ptr = int.from_bytes(r[2:6], "little")
            bc = int.from_bytes(r[8:10], "little")
            hl = int.from_bytes(r[10:12], "little")
            if LO <= ptr < HI and bc and hl:
                out.setdefault(ptr, []).append(
                    (bc * hl, p, "op %02X blit at 0x%06X, BC=%d cols x HL=%d rows"
                     % (op, p, bc, hl)))
    return out


# ---------------------------------------------------------- E5: pointer chains
def ptr_chains(lo=LO, hi=HI, minent=3):
    """Maximal chains of >= minent consecutive 32-bit words that are all
    addresses inside prom_a or prom_b."""
    out, p = [], lo
    while p < hi - 3:
        k, q = 0, p
        while q <= hi - 4 and in_image(w32(q)):
            k += 1
            q += 4
        if k >= minent:
            out.append((p, p + 4 * k, k))
            p = p + 4 * k
        else:
            p += 1
    return out


# ------------------------------------------------------------ E6: content rules
def fill_runs(lo=LO, hi=HI, n=FILL_MIN):
    out, p = [], lo
    while p < hi:
        if by(p)[0] == FILL_BYTE:
            q = p
            while q < hi and by(q)[0] == FILL_BYTE:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def value_tables(lo=LO, hi=HI, minc=8):
    """Maximal runs of >= minc consecutive 5-byte cells that all read as a
    numeric value string -- ` 0.10`, `10.00`, `  .  `.  All five grid phases are
    tried and the longest run wins; a run is reported once."""
    best = {}
    for phase in range(5):
        p = lo + phase
        while p + 5 <= hi:
            q = p
            while q + 5 <= hi and VALUECELL.match(
                    by(q, 5).decode("latin-1")):
                q += 5
            if (q - p) // 5 >= minc:
                best[p] = q
            p = max(q, p + 5)
    out, taken = [], set()
    for s in sorted(best, key=lambda s: -(best[s] - s)):
        e = best[s]
        if any(x in taken for x in range(s, e)):
            continue
        taken |= set(range(s, e))
        out.append((s, e, (e - s) // 5))
    return sorted(out)


def list_copies(lo=LO, hi=HI):
    """Every occurrence inside the span of the 51-byte display list at 0xF1774D
    -- the one the only prom_b call site of this span names."""
    src = dl_sites()
    anchor = [(s, e) for s, e, t, _p, _a in src
              if e is not None and lo <= s and e <= hi]
    if not anchor:
        return []
    s0, e0 = min(anchor)
    pat, out, i = by(s0, e0 - s0), [], lo
    while True:
        j = rom("b").find(pat, i - B_BASE)
        if j < 0 or B_BASE + j + len(pat) > hi:
            break
        out.append((B_BASE + j, B_BASE + j + len(pat)))
        i = B_BASE + j + 1
    return out


def glyph_copy():
    """The truncated copy of the 24x24 value-glyph module.

    Returns (quantiser tail, pointer table, bitmaps, glyph count) or None.
    Each part is proved by a byte comparison against the LIVE module at
    0xF31DED/0xF31E6D/0xF31EE1: the quantiser tail is the longest suffix of the
    live 128-byte quantiser that matches the bytes ending at the pointer table's
    base, and the bitmap count is how many consecutive 72-byte blocks are
    byte-identical to the live module's."""
    tab = None
    for s, e, k in ptr_chains():
        if k >= GLYPH_N and w32(s) == e and all(
                w32(s + 4 * i) == w32(s) + GLYPH_SZ * i for i in range(k)):
            tab = (s, e, k)
    if tab is None:
        return None
    s, e, k = tab
    q = 0
    while q < 128 and by(s - q - 1)[0] == \
            rom("b")[GLYPH_QUANT - B_BASE + 127 - q]:
        q += 1
    n = 0
    while (e + (n + 1) * GLYPH_SZ <= HI
           and by(e + n * GLYPH_SZ, GLYPH_SZ)
           == rom("b")[GLYPH_BMPS - B_BASE + n * GLYPH_SZ:
                       GLYPH_BMPS - B_BASE + (n + 1) * GLYPH_SZ]):
        n += 1
    return (s - q, s), (s, e), (e, e + n * GLYPH_SZ), n, k


def glyph_modules():
    """Every 24x24 value-glyph module in prom_b, found image-wide.

    A module is a chain of >= 29 32-bit words with a constant stride of 72 whose
    first entry is the word immediately after the chain.  For each, this reports
    how many of its 72-byte blocks are byte-identical to the LIVE module's
    (0xF31EE1, the one `DrawValueGlyph_24x24` indexes), whether its 128-byte
    quantiser is byte-identical to the live one at 0xF31DED, and whether anything
    in the four images spells the table's address.

    Result: THREE modules, and two of them are unreferenced copies truncated at
    exactly four glyphs.  0xF0EE6C is the `ArrayDescriptor_F0EE6C` of the round-5
    block, whose header in prom_b/wsa1_prom_b.s says "Unknown: what indexes it,
    and what the entries mean" -- this answers the second half."""
    out = []
    for s, e, k in ptr_chains(B_BASE, B_BASE + len(rom("b")), GLYPH_N):
        if not (w32(s) == e and all(w32(s + 4 * i) == w32(s) + GLYPH_SZ * i
                                    for i in range(k))):
            continue
        q = 0
        while q < 128 and by(s - q - 1)[0] == \
                rom("b")[GLYPH_QUANT - B_BASE + 127 - q]:
            q += 1
        n = 0
        while (n < k and by(e + n * GLYPH_SZ, GLYPH_SZ)
               == rom("b")[GLYPH_BMPS - B_BASE + n * GLYPH_SZ:
                           GLYPH_BMPS - B_BASE + (n + 1) * GLYPH_SZ]):
            n += 1
        refs = sum(rom(x).count(s.to_bytes(4, "little")) for x in ("a", "b", "c"))
        out.append((s, e, k, q, n, refs))
    return out


# ------------------------------------------------------------------- the tiler
def all_pointers(s, n):
    return n >= 8 and n % 4 == 0 and all(in_image(w32(s + i)) for i in range(0, n, 4))


def bit_weights(s, n):
    if n < 16 or n % 4:
        return False
    w0 = w32(s)
    return w0 != 0 and all(w32(s + 4 * k) == (w0 << k) & 0xFFFFFFFF
                           and (w0 << k) <= 0xFFFFFFFF for k in range(n // 4))


def ptr_tables_split():
    """ptr_chains(), cut wherever an `add Rx,<base>` names a base inside a chain.
    Without the cut, six adjacent 8-entry tables at 0xF1B03F-0xF1B0CB read as one
    44-entry chain and every entry is reported against the wrong base."""
    cuts = set(table_bases()) | set(references())
    out = []
    for a, e, _k in ptr_chains():
        marks = sorted({a, e} | {c for c in cuts if a < c < e and (c - a) % 4 == 0})
        for x, y in zip(marks, marks[1:]):
            out.append((x, y, (y - x) // 4))
    return out


def chain_entry(s):
    """(chain base, index) if s is entry k of a REFERENCED pointer chain."""
    R = references()
    for a, e, k in ptr_tables_split():
        if a not in R:
            continue
        for i in range(k):
            if w32(a + 4 * i) == s:
                return a, i
    return None


def framed(s, e):
    """The records of [s,e) if the display-list framing walk lands exactly on e,
    else None."""
    out, p = [], s
    while p < e:
        op, ln = by(p)[0], by(p + 1)[0]
        if op >= 0x24 or ln < 2 or p + ln > e:
            return None
        out.append((p, op, ln))
        p += ln
    return out if p == e and out else None


def interp_of(recs):
    ta, tb = LA.tables(rom("b"))

    def fits(table, implied, bound):
        for _p, op, ln in recs:
            if op >= bound:
                return False
            kind, n = implied[table[op]]
            if (ln != n) if kind == "fixed" else (ln < n):
                return False
        return True
    a, b = fits(ta, LA.IMPLIED_A, 0x24), fits(tb, LA.IMPLIED_B, 0x0F)
    return "A" if a and not b else "B" if b and not a else "AMBIG" if a else None


def anchors(use_stale=False, extra=None):
    """{address: [evidence strings]}.  Everything that pins a boundary."""
    A = {LO: ["span start"], HI: ["span end"]}

    def add(x, why):
        if LO <= x <= HI:
            A.setdefault(x, []).append(why)

    for v, sites in references().items():
        prom, ia, text = sites[0]
        add(v, "E0 named by prom_%s 0x%06X (%s)%s"
            % (prom, ia, text.split("  |  ")[0],
               "" if len(sites) == 1 else " and %d more" % (len(sites) - 1)))
    for s, e, t, prom, ia in dl_sites():
        add(s, "E1 list start, prom_%s 0x%06X%s"
            % (prom, ia, " -> T_%06X" % t if t else " (pair, no literal call)"))
        if e is None:
            add(s + by(s + 1)[0], "E1 one record, length byte")
        else:
            add(e, "E1 list end, prom_%s 0x%06X" % (prom, ia))
    for v, (n, prom, ia) in copy_lengths().items():
        add(v, "E2 ldir source, prom_%s 0x%06X" % (prom, ia))
        add(v + n, "E2 ldir source + %d bytes" % n)
    for v, (w, prom, ia) in table_bases().items():
        add(v, "E3 table base, prom_%s 0x%06X, entry width %d" % (prom, ia, w))
    for v, (prom, ia) in desc_sites().items():
        add(v, "E4 descriptor argument, prom_%s 0x%06X" % (prom, ia))
    # E5: pointer chains.  A chain's own bounds are always anchors; its ENTRIES
    # only when the chain is referenced -- see the module docstring.
    R = references()
    for s, e, k in ptr_chains():
        add(s, "E5 pointer chain, %d entries" % k)
        add(e, "E5 pointer chain end")
        if use_stale or s in R:
            for x in range(s, e, 4):
                add(w32(x), "E5 entry of the chain at 0x%06X" % s)
    for s, e in fill_runs():
        add(s, "E6 fill run start")
        add(e, "E6 fill run end")
    for s, e in list_copies():
        add(s, "E6 copy of the 51-byte list")
        add(e, "E6 copy of the 51-byte list, end")
    for s, e, n in value_tables():
        add(s, "E6 value-string table, %d cells" % n)
        add(e, "E6 value-string table end")
    g = glyph_copy()
    if g:
        add(g[0][0], "E6 glyph-module quantiser tail")
        add(g[2][1], "E6 glyph-module bitmaps end (%d glyphs)" % g[3])
    for x, why in (extra or []):
        add(x, why)
    return A


def framed_records(A):
    """Every record of every interval between consecutive anchors that frames,
    plus the ldir-copied descriptors -- 0xF1AAA9 is a 12-byte interpreter-A
    op-03 record that prom_a copies to the stack and runs, and its BC x HL is
    what sizes the 51-byte bitmap at 0xF17C59."""
    out, ad = [], sorted(A)
    for i in range(len(ad) - 1):
        r = framed(ad[i], ad[i + 1])
        if r and interp_of(r):
            out += r
    for v, (n, _p, _a) in copy_lengths().items():
        r = framed(v, v + n)
        if r:
            out += r
    return out


def settle(use_stale=False):
    """Anchors, iterated: the pointer field of a framed record is itself an
    anchor, and adding it frames more records, which carry more pointers.  Three
    rounds reach a fixpoint here and the fourth is asserted to add nothing."""
    A, extra, seen = anchors(use_stale), [], set()
    for _ in range(6):
        ptrs = record_pointers(framed_records(A))
        new = [(t, "E4 pointer field of %s" % ptrs[t][0][2])
               for t in ptrs if t not in seen]
        if not new:
            return A, ptrs
        seen |= set(t for t, _w in new)
        extra += new
        A = anchors(use_stale, extra)
    return A, record_pointers(framed_records(A))


def build(use_stale=False):
    """[(kind, lo, length, evidence)] covering [LO,HI) with no gap or overlap."""
    A, ptrs = settle(use_stale)
    sites = {}
    for s, e, t, _p, _a in dl_sites():
        if e is not None:
            sites[(s, e)] = ("B" if t in (RUN_B, RUN_B_I) else "A") if t else None
        else:
            sites[(s, s + by(s + 1)[0])] = "B" if t in (ONE_B, RUN_B_I) else "A"
    copies = dict(((s, e), True) for s, e in list_copies())
    vals = dict(((s, e), n) for s, e, n in value_tables())
    fills = dict(fill_runs())
    chains = dict(((s, e), k) for s, e, k in ptr_chains())
    tb = table_bases()
    cl = copy_lengths()
    ds = desc_sites()
    g = glyph_copy()

    segs, ad = [], sorted(A)
    for i in range(len(ad) - 1):
        s, e, n = ad[i], ad[i + 1], ad[i + 1] - ad[i]
        r = framed(s, e)
        which = interp_of(r) if r else None
        if (s, e) in fills.items() or (s in fills and fills[s] == e):
            segs.append(("pad", s, n, "%d bytes of 0x0E" % n))
            continue
        if by(s, n) == b"\x00" * n:
            segs.append(("pad", s, n, "%d zero bytes" % n))
            continue
        if (s, e) in chains and s not in tb:
            segs.append(("pointer_table", s, n,
                         "%d words, all addresses in prom_a/prom_b%s"
                         % (chains[(s, e)],
                            "" if s in references() else "; UNREFERENCED")))
            continue
        if r and which and (s, e) in sites:
            k = sites[(s, e)]
            segs.append(("display_list", s, n,
                         "%d records, interpreter %s, %s"
                         % (len(r), k or which,
                            "named by its call site's thunk" if k else
                            "named by a push pair whose framing walk lands on "
                            "the end address")))
            continue
        if (s, e) in copies:
            segs.append(("display_list", s, n,
                         "%d records; byte-identical copy of the list at 0x%06X"
                         % (len(r) if r else 0, min(copies)[0])))
            continue
        if (s, e) in vals:
            segs.append(("ascii", s, n, "%d value strings of 5 bytes" % vals[(s, e)]))
            continue
        if g and (s, e) == g[0]:
            segs.append(("bit_table", s, n,
                         "last %d bytes of the 128-byte glyph quantiser at 0x%06X"
                         % (n, GLYPH_QUANT)))
            continue
        if g and (s, e) == g[2]:
            segs.append(("bitmap", s, n,
                         "%d x 72-byte 24x24 glyphs, byte-identical to 0x%06X"
                         % (g[3], GLYPH_BMPS)))
            continue
        if s in cl and cl[s][0] == n:
            segs.append(("record", s, n,
                         "%d bytes, stated by `ldw BC` at prom_%s 0x%06X"
                         % (n, cl[s][1], cl[s][2])))
            continue
        if bit_weights(s, n):
            segs.append(("bit_table", s, n,
                         "%d words, w[k] = w[0] << k" % (n // 4)))
            continue
        if all_pointers(s, n) and s not in tb:
            segs.append(("pointer_table", s, n,
                         "%d words, all addresses in prom_a/prom_b%s"
                         % (n // 4, "" if s in references()
                            else "; base referenced by a pointer chain"
                            if chain_entry(s) else "; UNREFERENCED")))
            continue
        if s in tb:
            w = tb[s][0]
            if n % w == 0:
                segs.append(("index_map" if w == 1 else "pointer_table" if w == 4
                             else "index_map", s, n,
                             "%d entries of %d bytes; base and width from prom_%s "
                             "0x%06X" % (n // w, w, tb[s][1], tb[s][2])))
                continue
        if s in ptrs:
            for w, src, why in ptrs[s]:
                if n % w == 0:
                    segs.append(("ascii" if _texty(s, n) else "index_map", s, n,
                                 "%d entries of %d bytes; %s"
                                 % (n // w, w, why)))
                    break
            else:
                segs.append(("unknown", s, n, "pointer target, no width divides %d" % n))
            continue
        if r and which:
            host = [(a, b) for (a, b) in sites if a <= s and e <= b and (a, b) != (s, e)]
            segs.append(("display_list", s, n,
                         "%d records, interpreter %s, inside the call-site run "
                         "0x%06X-0x%06X" % (len(r), sites[host[0]] or which,
                                            host[0][0], host[0][1])
                         if host else
                         "%d records, interpreter %s; both ends are E0 "
                         "references but no display-list call site names the run"
                         % (len(r), which)))
            continue
        ce = chain_entry(s)
        if ce:
            d = by(s, n)
            if d[-1] == 0xFF and 0xFF not in d[:-1]:
                segs.append(("index_map", s, n,
                             "%d byte values then the 0xFF terminator; entry [%d] "
                             "of the pointer table at 0x%06X" % (n - 1, ce[1], ce[0])))
            elif _texty(s, n):
                segs.append(("ascii", s, n, "%d characters; entry [%d] of the "
                             "pointer table at 0x%06X" % (n, ce[1], ce[0])))
            else:
                segs.append(("index_map", s, n,
                             "%d byte values; entry [%d] of the pointer table at "
                             "0x%06X" % (n, ce[1], ce[0])))
            continue
        if s in ds:
            segs.append(("record", s, n,
                         "descriptor, %d bytes to the next anchor; prom_%s 0x%06X"
                         % (n, ds[s][0], ds[s][1])))
            continue
        segs.append(("unknown", s, n, hole(s, n)))
    return merge_arrays(segs)


def hole(s, n):
    """What IS known about a run no rule assigns."""
    lists = list_copies()
    if lists:
        a, b = lists[0]
        for i in range(1, b - a):
            if by(s, n) == by(a + (b - a) - n, n) and n == 25:
                return ("%d bytes, byte-identical to the LAST %d bytes of the "
                        "51-byte list at 0x%06X; not a record run of its own "
                        "(its first byte is opcode 0x%02X with length byte 0x%02X)"
                        % (n, n, a, by(s)[0], by(s + 1)[0]))
            break
    vt = [x for x in value_tables() if x[0] > s]
    if vt and vt[0][0] - s == n:
        return ("%d bytes; the 5-byte grid of the %d-cell value table at 0x%06X "
                "does not reach back this far, and the object before it ends "
                "exactly here" % (n, vt[0][2], vt[0][0]))
    return "no rule assigns it"


def b_pointer_resolves(p):
    """Does the record at p carry an interpreter-B `+7` pointer that lands inside
    the span?  Used only to break a length-rule TIE, never to classify a record,
    and its false-positive rate over the span's call-site-proven interpreter-A
    records is printed by --null-frame."""
    op, ln = by(p)[0], by(p + 1)[0]
    _ta, tb = LA.tables(rom("b"))
    if op >= 0x0F or tb[op] not in BPTR:
        return False
    kind, need = LA.IMPLIED_B[tb[op]]
    if (ln != need) if kind == "fixed" else (ln < need):
        return False
    return LO <= int.from_bytes(by(p + 7, 4), "little") < HI


def merge_tables(segs):
    """Fold adjacent operand/string tables of the SAME entry width into one.

    Eight interpreter-B records point at 0xF1A22D, 0xF1A231 ... 0xF1A249, each
    with width 4: that is ONE 32-entry table indexed from eight different bases,
    not eight tables of one entry.  Splitting it at every base was the tiler's
    first output and it hid the fact that the table's extent (32 entries) is
    exactly what the widest mask (0x1F) allows.

    ⚠ The merge fires ONLY when consecutive bases are exactly one entry apart.
    Without that clause it also welded 0xF1854D (14 x 8, mask 0x1F) to 0xF185BD
    (8 x 8, mask 0x07) -- two arrays whose bases are 112 bytes apart -- into a
    single 22-entry table that neither record can index."""
    rx = re.compile(r"^(\d+) entries of (\d+) bytes; record 0x([0-9A-F]{6}) \+7, "
                    r"width \d+, mask 0x([0-9A-F]{2})>>(\d)$")
    out = []
    for row in segs:
        k, s, n, w = row[0], row[1], row[2], row[3]
        m = rx.match(w) if len(row) == 4 else None
        if m and out and out[-1][0] in ("ascii", "index_map") \
                and out[-1][1] + out[-1][2] == s and len(out[-1]) == 5 \
                and isinstance(out[-1][4], tuple) \
                and out[-1][4][0] == int(m.group(2)) \
                and s - out[-1][4][3] == int(m.group(2)):
            pk, ps, pn, _pw, (width, refs, masks, _lb) = out[-1]
            out[-1] = (k if _texty(ps, pn + n) else pk, ps, pn + n, "",
                       (width, refs + [int(m.group(3), 16)],
                        masks + [(int(m.group(4), 16) >> int(m.group(5))) + 1], s))
            continue
        if m:
            out.append((k, s, n, "",
                        (int(m.group(2)), [int(m.group(3), 16)],
                         [(int(m.group(4), 16) >> int(m.group(5))) + 1], s)))
            continue
        out.append(row)
    final = []
    for row in out:
        if len(row) == 5 and isinstance(row[4], tuple):
            k, s, n, _w, (width, refs, masks, _lb) = row
            final.append((k, s, n,
                          "%d entries of %d bytes; %d record(s) point into it, "
                          "the first at 0x%06X, whose mask allows at most %d "
                          "indices" % (n // width, width, len(refs), refs[0],
                                       max(masks))))
        else:
            final.append(row)
    return final


def merge_arrays(segs):
    """Fold a run of adjacent ONE-RECORD display lists of equal length into a
    single array segment.

    These are not separate lists: they are the entries of a pointer table that
    prom_a indexes and hands to `DisplayListB_RunOne_Stack` one at a time, which
    is the same construction `FINDINGS-prom_b-fonts-and-dsp-value-lists.md` sec.2
    describes at a 15-byte stride.  Keeping them as N segments of 1 record each
    hides the stride, which is the structural fact."""
    out = []
    for k, s, n, w in segs:
        one = (k == "display_list" and w.startswith("1 records")
               and ("no display-list call site names the run" in w
                    or "inside the call-site run" in w))
        if (one and out and out[-1][0] == "record_array"
                and out[-1][1] + out[-1][2] == s and out[-1][4] == n):
            p, q, m, _e, _n = out[-1]
            out[-1] = (p, q, m + n, "", n)
            continue
        if one and out and out[-1][0] == "display_list" \
                and out[-1][3].startswith("1 records") \
                and out[-1][1] + out[-1][2] == s and out[-1][2] == n:
            out[-1] = ("record_array", out[-1][1], out[-1][2] + n, "", n)
            continue
        out.append((k, s, n, w) if not one else (k, s, n, w))
    out = merge_tables(out)
    final = []
    for row in out:
        if row[0] != "record_array":
            final.append(row[:4] if len(row) > 4 else row)
            continue
        _k, s, n, _w, stride = row
        cnt = n // stride
        ce = chain_entry(s)
        why = ("%d records of %d bytes, individually addressed (stride %d)"
               % (cnt, stride, stride))
        if ce:
            why += "; entries [%d..] of the pointer table at 0x%06X" % (ce[1], ce[0])
        if all(b_pointer_resolves(s + i * stride) for i in range(cnt)):
            why += "; interpreter B -- every record's +7 pointer lands in the span"
        final.append(("record_array", s, n, why))
    return final


def _texty(s, n):
    d = by(s, n)
    return sum(1 for c in d if 32 <= c < 127) * 10 >= len(d) * 9


# ------------------------------------------------------------------ the nulls
def proven_code_runs(prom="b"):
    """Maximal runs of PROVEN instruction text, as (lo, hi) address pairs.

    ⚠ Read in FILE ORDER, not sorted: a run ends at the first line that is not an
    instruction (a `.byte`/`.ascii`/`.long`/`.fill` directive, a label, a
    comment).  Sorting the addresses first -- which this function did in its
    first draft -- welds the whole image into ONE run of 453,331 bytes that
    includes every data island, and a null measured on that corpus is
    meaningless.  Same construction as
    notes/prom_b_f65000_layout.py::proven_code_runs()."""
    path = image_path(ROOT, "prom_%s/wsa1_prom_%s.s" % (prom, prom))
    seq = []
    for line in open(path):
        i = line.find(";")
        body = line[:i] if i >= 0 else line
        m = re.search(r";\s*([0-9A-F]{6})\s\s", line)
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


def null():
    runs = proven_code_runs("b")
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: every maximal run of PROVEN instruction text in")
    print("prom_b/wsa1_prom_b.s -- %d runs, %d bytes.  A content rule that fires"
          % (len(runs), tot))
    print("inside one of these runs is a FALSE POSITIVE.")
    print("  ⚠ the corpus GROWS as later rounds convert code; re-run and quote")
    print("    the run/byte counts printed above with any number taken from here.")
    tests = [("PTRCHAIN >= 3 words", lambda a, b: [(s, e) for s, e, _k in ptr_chains(a, b)]),
             ("VALUECELL >= 8 cells", lambda a, b: [(s, e) for s, e, _n in value_tables(a, b)]),
             ("VALUECELL >= 4 cells (rejected)",
              lambda a, b: [(s, e) for s, e, _n in value_tables(a, b, 4)]),
             ("VALUECELL >= 2 cells (rejected)",
              lambda a, b: [(s, e) for s, e, _n in value_tables(a, b, 2)]),
             ("FILL >= 16 bytes", lambda a, b: fill_runs(a, b)),
             ("FILL >= 4 bytes (rejected)", lambda a, b: fill_runs(a, b, 4))]
    for name, f in tests:
        hits = []
        for s, e in runs:
            hits += f(s, e)
        print("  %-32s false positives: %3d   %s"
              % (name, len(hits),
                 " ".join("0x%06X(%d)" % (a, b - a) for a, b in hits[:4])))
    print("  The rejected thresholds are printed so the choice is visible as a")
    print("  measurement and not as a preference.")
    print()
    print("SECOND NULL, over DATA rather than code: this span's own pointer")
    print("tables, index maps and bitmaps -- objects the firmware's own `add`")
    print("and `ldir` instructions size, so they are PROVEN not to be text.")
    segs = build()
    data = [(a, n) for k, a, n, _w in segs
            if k in ("pointer_table", "index_map", "bit_table", "bitmap")]
    hits = []
    for a, n in data:
        hits += value_tables(a, a + n)
    print("  corpus                    %d objects, %d bytes"
          % (len(data), sum(n for _a, n in data)))
    print("  VALUECELL >= 8 cells      false positives: %d" % len(hits))
    hits4 = []
    for a, n in data:
        hits4 += value_tables(a, a + n, 4)
    print("  VALUECELL >= 4 cells      false positives: %d" % len(hits4))


def null_frame():
    """How often does the display-list framing walk accept data that is PROVEN
    not to be a display list?

    The corpus is this span's own proven non-list objects: every pointer table
    whose base an `add Rx,imm32` names, every ldir-sized descriptor, and the
    128-entry note-name and 5-byte value tables.  For each, every aligned chunk
    of 8 bytes and up is offered to framed()+interp_of()."""
    segs = build()
    corpus = [(s, n, k) for k, s, n, _w in segs
              if k in ("pointer_table", "index_map", "record", "ascii", "bitmap")]
    tried = acc = 0
    worst = []
    for s, n, _k in corpus:
        for a in range(s, s + n):
            for b in range(a + 8, min(s + n, a + 64) + 1):
                tried += 1
                r = framed(a, b)
                if r and interp_of(r):
                    acc += 1
                    if len(worst) < 6:
                        worst.append((a, b))
    print("NULL for the framing rule: chunks of PROVEN NON-LIST data in this span")
    print("  corpus objects            %d  (%d bytes)"
          % (len(corpus), sum(n for _s, n, _k in corpus)))
    print("  chunks offered            %d" % tried)
    print("  accepted as a record run  %d  (%.2f%%)"
          % (acc, 100.0 * acc / max(tried, 1)))
    print("  examples: %s" % " ".join("0x%06X-0x%06X" % (a, b) for a, b in worst))
    print("  ⇒ the framing walk ALONE is not evidence, so every `display_list`")
    print("     segment also has BOTH ends anchored by E0/E1.  The ones whose")
    print("     bounds are plain E0 references, with no call site, are:")
    weak = [(s, n) for k, s, n, w in segs
            if k == "display_list" and "no display-list call site names the run" in w]
    for a, n in weak:
        print("       0x%06X  %4d bytes" % (a, n))
    print("     %d run(s), %d bytes -- %.1f%% of the span."
          % (len(weak), sum(n for _a, n in weak),
             100.0 * sum(n for _a, n in weak) / (HI - LO)))
    ta, _tb = LA.tables(rom("b"))
    aonly = [(p, op, ln) for k, s, n, w in segs if k == "display_list"
             and "interpreter A" in w for p, op, ln in (framed(s, s + n) or [])]
    res = sum(1 for p, _op, _ln in aonly if b_pointer_resolves(p))
    print("  NULL for the +7-pointer tie-break: of %d records this layout calls"
          % len(aonly))
    print("     interpreter A, %d carry a `+7` word that lands inside the span."
          % res)


def stale():
    good, bad = build(False), build(True)
    gb = sum(n for k, _s, n, _w in good if k == "unknown")
    bb = sum(n for k, _s, n, _w in bad if k == "unknown")
    print("Feeding the entries of EVERY pointer chain to the tiler as anchors,")
    print("including the unreferenced table at 0x%06X:" % 0xF17A6C)
    print("  unassigned bytes, entries used only from REFERENCED chains: %d" % gb)
    print("  unassigned bytes, entries used from every chain:            %d" % bb)
    print("  the stale table costs                                      %d bytes"
          % (bb - gb))


# ------------------------------------------------------------------- self-test
def check(msg, got, want):
    ok = got == want
    print("  %-64s %-22s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def _frames(a, b, s, e):
    """CS's own framing test, reimplemented so the count below does not depend on
    a private function."""
    for img, base in ((b, B_BASE), (a, 0xF80000)):
        if base <= s < e <= base + len(img):
            p, n = s, 0
            while p < e:
                op, ln = img[p - base], img[p - base + 1]
                if op >= 0x24 or ln < 2 or p + ln > e:
                    return False
                p += ln
                n += 1
            return p == e and n > 0
    return False


def selftest():
    print("prom_b_f17559_layout.py --selftest")
    segs = build()
    check("segments tile the span with no gap",
          [(hex(s), n) for i, (_k, s, n, _w) in enumerate(segs)
           if s != (LO if i == 0 else segs[i - 1][1] + segs[i - 1][2])], [])
    check("segments cover every byte", sum(n for _k, _s, n, _w in segs), HI - LO)
    check("first segment starts at the span start", hex(segs[0][1]), hex(LO))
    check("LAST segment ends at the span end",
          hex(segs[-1][1] + segs[-1][2]), hex(HI))
    ct = code_targets()
    st = stale_thunks()
    check("every in-span transfer target is a thunk slot of ONE run",
          sorted(ct) == sorted(t for _s, t, _r, _b in st), True)
    check("  that run is T_F42FD0-T_F43000, 13 slots",
          (len(st), hex(st[0][0]), hex(st[-1][0])), (13, "0xf42fd0", "0xf43000"))
    check("  every one of the 13 slots has ZERO references in the four images",
          sorted({r for _s, _t, r, _b in st}), [(0, 0)])
    check("  11 of the 13 targets land INSIDE a display-list record, not at its "
          "start", sum(1 for _s, _t, _r, b in st if not b), 11)

    # E1 -- and the comparison with the byte-level shape scanner
    s = dl_sites()
    inspan = [x for x in s if LO <= x[0] < HI]
    pairs = [x for x in inspan if x[1] is not None]
    ones = [x for x in inspan if x[1] is None]
    check("display-list sites naming this span", (len(pairs), len(ones)), (64, 57))
    check("  pairs with no literal call (`jp (XIX)`, prom_a 0xFBE265)",
          sum(1 for x in pairs if x[2] is None), 28)
    key = lambda r: (r[0], r[1] or 0, r[4])
    lastsite, firstsite = max(inspan, key=key), min(inspan, key=key)
    check("  the LAST site, by list address",
          "0x%06X-0x%06X <- prom_%s 0x%06X"
          % (lastsite[0], lastsite[1] or 0, lastsite[3], lastsite[4]),
          "0xF1A999-0xF1AA7C <- prom_a 0xFBFF55")
    check("  the FIRST site, by list address",
          "0x%06X-0x%06X" % (firstsite[0], firstsite[1] or 0),
          "0xF1774D-0xF17780")
    check("  a site the byte-level shapes miss: the XWA/XIY pair at prom_a 0xFBFA41",
          any(x[0] == 0xF1A53F and x[1] == 0xF1A62F for x in s), True)
    try:
        import prom_b_dl_call_shapes as CS
        mine = {(x[0], x[1]) for x in inspan}
        theirs = set()
        for shape, _site, st, en, _t in CS.scan(rom("a"), rom("b")):
            if not (LO <= st < HI):
                continue
            theirs.add((st, en if shape != 3 else None))
        check("  every site the byte-level scanner reports here is found here too",
              sorted(theirs - mine), [])
        check("  ... and this scan finds more", len(mine) - len(theirs & mine) > 0, True)
    except Exception as exc:                                  # pragma: no cover
        check("  cross-check against prom_b_dl_call_shapes.py", str(exc), "ran")

    # the wave-7 briefing's count of prom_b_dl_call_shapes.py runs in this span
    try:
        import prom_b_dl_call_shapes as CS
        a, b = rom("a"), rom("b")
        spans = CS.incbin_spans()
        cov = set()
        for shape, _site, st, en, _t in CS.scan(a, b):
            if shape == 1:
                continue                 # already converted; CS --new skips it
            if shape == 3:
                if not (B_BASE <= st < B_BASE + len(b) - 2):
                    continue
                op, ln = b[st - B_BASE], b[st - B_BASE + 1]
                if op >= 0x0F:
                    continue
                kind, want = LA.IMPLIED_B[CS.LA.tables(b)[1][op]]
                if not ((ln >= want) if kind == "min" else (ln == want)):
                    continue
                en = st + ln
            elif not (st < en and _frames(a, b, st, en)):
                continue
            if any(x <= st < y for x, y in spans):
                cov |= set(range(st, en))
        runs = []
        for x in sorted(cov):
            if runs and x == runs[-1][1] + 1:
                runs[-1][1] = x
            else:
                runs.append([x, x])
        mine = [r for r in runs if LO <= r[0] < HI]
        check("prom_b_dl_call_shapes.py --new: runs and bytes IN THIS SPAN",
              (len(mine), sum(b_ - a_ + 1 for a_, b_ in mine)), (25, 3157))
        check("  ... out of, in the whole image",
              (len(runs), sum(b_ - a_ + 1 for a_, b_ in runs)), (41, 5247))
    except Exception as exc:                                   # pragma: no cover
        check("  reproduce prom_b_dl_call_shapes.py --new", str(exc), "ran")

    # E2 -- the ldir chain, first and last
    cl = copy_lengths()
    chain = sorted(x for x in cl if 0xF1AA7C <= x < 0xF1AB13)
    check("ldir-sized objects at 0xF1AA7C..", len(chain), 11)
    check("  FIRST is 0xF1AA7C, 9 bytes, and lands on the second",
          (hex(chain[0]), cl[chain[0]][0], chain[0] + cl[chain[0]][0] == chain[1]),
          ("0xf1aa7c", 9, True))
    check("  LAST is 0xF1AAEC, 30 bytes, and 9 zero bytes follow it",
          (hex(chain[-1]), cl[chain[-1]][0],
           by(chain[-1] + cl[chain[-1]][0], 9) == b"\x00" * 9),
          ("0xf1aaec", 30, True))
    check("  every link but the last lands on the next object's start",
          [hex(a) for a, b in zip(chain, chain[1:]) if a + cl[a][0] != b], [])
    check("  0xF1AAA9 is the op-03 record that sizes the bitmap at 0xF17C59",
          (by(0xF1AAA9, 2).hex(),
           int.from_bytes(by(0xF1AAA9 + 8, 2), "little")      # BC = columns
           * int.from_bytes(by(0xF1AAA9 + 0x0A, 2), "little")),  # HL = rows
          ("030c", 51))

    # E3 -- the last dispatch table, and the fill that follows it
    tb = table_bases()
    last = max(tb)
    check("LAST `add Rx,imm` table base in the span", hex(last), "0xf1b34d")
    check("  its entry width, and 23 entries reaching the 0x0E pad",
          (tb[last][0], (0xF1B3A9 - last) // tb[last][0]), (4, 23))
    check("  the pad is 0x0E all the way to the span end",
          by(0xF1B3A9, HI - 0xF1B3A9) == bytes([FILL_BYTE]) * (HI - 0xF1B3A9), True)
    check("  the FIRST table base, and its width",
          (hex(min(tb)), tb[min(tb)][0]), ("0xf1ab13", 4))
    check("  the 6-byte count table at 0xF1AF6D holds len-1 for each of the six "
          "byte lists the pointer table at 0xF1AFA5 frames",
          [by(0xF1AF6D + k)[0] for k in range(6)],
          [(w32(0xF1AFA5 + 4 * (k + 1)) if k < 5 else 0xF1AFA5)
           - w32(0xF1AFA5 + 4 * k) - 1 for k in range(6)])

    # E4 -- the mask agrees on one table and disagrees on another
    d = {s: (n, w) for k, s, n, w in segs}
    check("0xF1A62F is 128 x 3 and its mask 0x7F agrees",
          (d[0xF1A62F][0], "128 entries of 3" in d[0xF1A62F][1]), (384, True))
    check("0xF1854D is 14 x 8 although its mask 0x1F would allow 32",
          (d[0xF1854D][0], "14 entries of 8" in d[0xF1854D][1]), (112, True))

    # E6 -- the truncated glyph copy
    g = glyph_copy()
    check("glyph copy: quantiser tail / table / bitmaps / glyphs / table entries",
          (hex(g[0][0]), hex(g[1][0]), hex(g[2][0]), g[3], g[4]),
          ("0xf17a5f", "0xf17a6c", "0xf17ae0", 4, 29))
    check("  the table has 29 entries and only 4 glyphs follow it",
          (g[4], g[3], hex(g[2][1])), (29, 4, "0xf17c00"))
    check("  entry [4] lands on live display-list data, not on a glyph",
          (hex(w32(0xF17A6C + 16)), w32(0xF17A6C + 16) == g[2][1]),
          ("0xf17c00", True))
    check("  entry [28], the LAST, lands 0x48 past entry [27]",
          (hex(w32(0xF17A6C + 4 * 28)),
           w32(0xF17A6C + 4 * 28) - w32(0xF17A6C + 4 * 27)), ("0xf182c0", 72))
    check("  nothing in prom_a/prom_b/prom_c/prom_d references the table",
          0xF17A6C in references(), False)
    check("  the 13-byte quantiser tail IS the tail of the live one",
          by(0xF17A5F, 13) == rom("b")[GLYPH_QUANT - B_BASE + 115:
                                       GLYPH_QUANT - B_BASE + 128], True)
    gm = glyph_modules()
    check("prom_b holds THREE such modules",
          [(hex(a), k, q, n, r) for a, _b, k, q, n, r in gm],
          [("0xf0ee6c", 29, 128, 4, 0), ("0xf17a6c", 29, 13, 4, 0),
           ("0xf31e6d", 29, 128, 29, 1)])
    check("  only the LIVE one at 0xF31E6D has all 29 glyphs and a reference",
          [hex(a) for a, _b, _k, _q, n, r in gm if n == 29 and r], ["0xf31e6d"])

    # E6 -- the value tables, the list copies and the two holes
    vt = value_tables()
    check("value-string tables (first, last)",
          [(hex(s), n) for s, _e, n in (vt[0], vt[-1])],
          [("0xf17559", 100), ("0xf179a5", 27)])
    check("  the LAST cell of the FIRST table is `  .  `",
          by(vt[0][1] - 5, 5).decode("latin-1"), "  .  ")
    check("  the LAST cell of the LAST table is `  .  `",
          by(vt[-1][1] - 5, 5).decode("latin-1"), "  .  ")
    check("  the FIRST cell of the LAST table",
          by(vt[-1][0], 5).decode("latin-1"), " 7.60")
    lc = list_copies()
    check("copies of the 51-byte list", [hex(x) for x, _y in lc],
          ["0xf1774d", "0xf17959", "0xf17a2c"])
    check("  only the FIRST of the three is named by a call site",
          [hex(x) for x, _y in lc
           if any(a == x for a, _b, _t, _p, _i in dl_sites())], ["0xf1774d"])

    unk = [(hex(s), n) for k, s, n, _w in segs if k == "unknown"]
    check("unassigned runs -- the honest holes", unk,
          [("0xf17780", 3), ("0xf1798c", 25)])
    check("  the 25-byte one is the LAST 25 bytes of the 51-byte list",
          by(0xF1798C, 25) == by(0xF1774D + 26, 25), True)
    check("  the 3-byte one is the ASCII `.20`", by(0xF17780, 3).decode("latin-1"),
          ".20")
    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


# ------------------------------------------------------------------------ main
def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--null" in sys.argv:
        null()
        return 0
    if "--null-frame" in sys.argv:
        null_frame()
        return 0
    if "--siblings" in sys.argv:
        print("24x24 value-glyph modules in prom_b (table, bitmaps, entries,")
        print("quantiser-tail bytes matching 0xF31DED, glyphs matching 0xF31EE1,")
        print("32-bit references to the table):")
        for s, e, k, q, n, refs in glyph_modules():
            print("  table 0x%06X  bitmaps 0x%06X  %d entries  quantiser tail %3d"
                  "  glyphs %2d/%d  references %d"
                  % (s, e, k, q, n, k, refs))
        return 0
    if "--stale" in sys.argv:
        stale()
        return 0
    if "--anchors" in sys.argv:
        A = anchors()
        if "--negatives" in sys.argv:
            ct = code_targets()
            print("in-span targets of a call/jp/jr anywhere in the four .s files:")
            for t in sorted(ct):
                print("   0x%06X  %s" % (t, ct[t][0]))
            print("all of them are thunk slots; their reference census:")
            for slot, tgt, (n32, n24), b in stale_thunks():
                print("   T_%06X -> 0x%06X  32-bit words %d, call/jp sites %d, "
                      "record boundary %s" % (slot, tgt, n32, n24, b))
        for a in sorted(A):
            print("  0x%06X  %s" % (a, " ; ".join(sorted(set(A[a])))))
        print("  %d anchors" % len(A))
        return 0
    if "--sites" in sys.argv:
        for s, e, t, prom, ia in sorted(dl_sites(), key=lambda r: (r[0], r[3], r[4])):
            if not (LO <= s < HI):
                continue
            print("  0x%06X-%-12s %-10s prom_%s 0x%06X"
                  % (s, "0x%06X" % e if e else "(one record)",
                     "T_%06X" % t if t else "(jp (XIX))", prom, ia))
        return 0
    segs = build()
    if "--coalesced" in sys.argv:
        co = []
        for k, a, n, w in segs:
            if co and co[-1][0] == k and co[-1][1] + co[-1][2] == a:
                co[-1] = (k, co[-1][1], co[-1][2] + n, co[-1][3] + 1, co[-1][4])
            else:
                co.append((k, a, n, 1, w))
        for k, a, n, c, w in co:
            print("  %-14s 0x%06X-0x%06X %6d  x%-3d %s" % (k, a, a + n - 1, n, c, w))
        print("  %d runs, %d segments, %d bytes"
              % (len(co), len(segs), sum(n for _k, _a, n, _c, _w in co)))
        return 0
    if "--python" in sys.argv:
        print("SEGMENTS = [")
        for k, s, n, w in segs:
            print('    ("%s", 0x%06X, 0x%04X),   # %s' % (k, s, n, w))
        print("]")
        return 0
    if "--residue" in sys.argv:
        for k, s, n, w in segs:
            if k != "unknown":
                continue
            print("0x%06X-0x%06X  %d bytes -- %s" % (s, s + n - 1, n, w))
            raw = by(s, n)
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "."
                                 for c in raw[i:i + 16])))
        return 0
    tot = {}
    for k, s, n, w in segs:
        print("  %-14s 0x%06X-0x%06X %6d  %s" % (k, s, s + n - 1, n, w))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    cov = sum(n for _k, _s, n, _w in segs)
    print("  %d segments, %d of %d bytes assigned, %d unassigned"
          % (len(segs), cov, HI - LO, tot.get("unknown", 0)))
    return 0 if cov == HI - LO else 1


if __name__ == "__main__":
    sys.exit(main())
