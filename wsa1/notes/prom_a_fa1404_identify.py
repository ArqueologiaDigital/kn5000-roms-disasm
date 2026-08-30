#!/usr/bin/env python3
"""WHAT IS prom_a 0xFA1404-0xFA5400?  The reference census, and the layout it forces.

QUESTION IT ANSWERS
  "This is the third-largest `.incbin` left in prom_a and `prom_a_module_frontier.py`
   lists no thunk run pointing into it.  Is it therefore data nobody reaches -- and
   what is it?"

  The answer to the first half is NO.  `--census` prints the figures rather than
  this paragraph quoting them, because they move when a round converts more code;
  as of the session that wrote this file it was 279 distinct in-span addresses
  named by 502 instruction operands, plus 231 bare LE32 pointers in prom_a, and
  ZERO slots of the prom_b thunk directory.  The negative that made this span look
  opaque is therefore true and useless: this module publishes nothing through the
  directory.  It is reached the way every UI module is reached -- by the code that
  owns it naming its tables and its display lists as 24-bit literals.
  ⚠ prom_b/prom_c/prom_d contain 5/28/7 byte sequences that read as a pointer into
  this range.  NONE is at an address any of those files emits an instruction or a
  datum at, and prom_c and prom_d address their OWN 0xFA.... space, so all 40 are
  coincidences.  They are printed by --census so that nobody has to take that on
  trust.

  ⚠ TWO OF THE REFERENCING CODE BLOCKS ARE INSIDE THE SPAN ITSELF (0xFA1404-0xFA15E8
  and 0xFA4EB5-0xFA5369).  A census built only from `prom_a/wsa1_prom_a.s` misses
  them, and with them four display lists -- 0xFA2FAF, 0xFA2FB9, 0xFA302F and the
  descriptors 0xFA1B82/0xFA1B8B.  Both blocks are decoded here with unidasm and
  folded into the census before anything is counted.

WHAT THE SPAN IS
  The data half of the WSA1's SYSTEM / OVERALL settings module, plus two blocks of
  its code.  Not one object type -- a whole module, in the shape this firmware
  always uses:

    0xFA1404-0xFA15E8   484  code + a 7-entry jump table at 0xFA146F
    0xFA15E8-0xFA1690   168  a 6-byte RAM initialiser and 18 x 9-byte descriptors
    0xFA1690-0xFA1F21  2193  16 x 23-entry handler tables, index maps and 56 more
                             9-byte / 3-byte parameter descriptors
    0xFA1F21-0xFA4EB5 12180  873 display-list records, 52 operand arrays and 34
                             string tables
    0xFA4EB5-0xFA5369  1204  three routines; NOTHING references the first
    0xFA5369-0xFA5400   151  0x0E fill, up to MIDI_EntryThunks at 0xFA5400

  The text in the display lists names the screens: TUNE & SCALE, TOUCH
  SENSITIVITY, CONTROLLER ASSIGN, RE-MAP EDIT, SOUND/COMBINATION MANAGER, MIXER,
  DRUMS MAP, MAIN OUT, EQUALIZER, DSP EFFECT, MEMORY PROTECT, DATA LOAD FILTER,
  INITIAL -- i.e. the SYSTEM menu and every page under it.  The string tables hold
  the temperaments (PIANO, ORCHSTRA, PYTHAGRN, WRKMISTR, KRNBERGR, ARABIC 1-5,
  SLENDRO, PELOG), the memory areas (ROM 1, USER 1, ROM DRUMS, EXT 1, RE-MAP 1-3),
  the 24 controller assignments (MODULATION1(# 1) ... AFTER TOUCH, NO ASSIGN) and
  the note names and octave numbers for KEY TRANSPOSE.

  ⚠ ASCII is the READER's assumption for the payload bytes.  A text record's
  OPCODE IS THE SWI7 SERVICE NUMBER (handler 0xF31A3A does `ld A,(XIY) / swi 7`),
  and notes/FINDINGS-fonts.md measured that five of the ten text services do NOT
  pass an ASCII test.  That is why several legends here read `C0NTR0LLER` and
  `0VERALL T0UCH` with byte 0x30: in that service's font 0x30 is presumably not a
  digit.  This file reports the bytes, not a reading of them.

★ IT ALSO CLOSES AN OPEN QUESTION IN prom_b
  prom_b/wsa1_prom_b.s's header for Stub_Ret_F55018 says the 4-byte slot address
  `70 2C F4 00` "occurs 397 times in prom_a+prom_b, 222 of them in one run at
  prom_a 0x216B4", and ends "Unknown: which table those 397 words belong to."
  ALL 222 of the prom_a ones are the empty slots of the sixteen 23-entry handler
  tables here, and the run at 0x216B4 is the first table's slot 9.  --selftest
  asserts both halves.

RULES, AND THE NULL MEASURED FOR EACH  (`--null`)
  R1 CALLSITE  a `lda_24 Xrr,(addr) / push Xrr / call T_F42E00|04|08|0C` group.
     T_F42E00/04 pass a START and an END, T_F42E08/0C one record.  Not a content
     rule at all -- it reads the operands out of proven instructions -- so its
     false-positive rate is not a statistic but a decode.
  R2 FRAME     a byte run walks as display-list records (opcode < bound, length
     byte == the length that opcode's handler implies) and lands EXACTLY on the
     next anchored object.  THIS one needs a null and it has one: measured over
     every maximal run of proven prom_a instruction text, sliding a window of each
     length R2 was actually trusted at, at every offset.  ⚠ ITS RATE IS NOT ZERO:
     1,318 hits in 2,583,668 trials (0.051%), and it falls with length -- 147 at
     10 bytes, 2 at 592.  R6's is not zero either (130).  See `--null`, and see
     the ★ below for why the layout survives that.
  R3 PTR23     23 consecutive LE32 words, each 0x00F42C70 (the no-op `ret` stub
     behind thunk T_F42C70) or inside 0x00F90000-0x00FB0000.
  R4 FILL      a run of >= 16 bytes of 0x0E.
  R5 EXTEND    a table whose entry width divides the bytes between it and the next
     proven object runs to that object.  Applied ONLY to holes, only when the
     division is exact, and never past the mask-implied maximum.
  R6 STRINGS   when a record's mask-implied size OVERSHOOTS the space available,
     the cut is not evidence.  For a string table the end is the first entry that
     is not a run of printable bytes.  Used exactly once, at 0xFA2BC3, and the
     entries either side of the boundary are `NO ASSIGN       ` and `+-`.

  ★ Nothing in the layout below rests on R2 alone.  All thirteen runs R2 accepted
  are bounded at BOTH ends by an object another rule proved -- `--selftest` asserts
  exactly that -- which is the check the prom_b f65000 lane calls "tiling" and the
  reason a wrong stride cannot survive.  The layout accounts for 16,380 of 16,380
  bytes with no hole and no overlap.

RUN
  python3 notes/prom_a_fa1404_identify.py                # the layout, coarse
  python3 notes/prom_a_fa1404_identify.py --fine         # every object
  python3 notes/prom_a_fa1404_identify.py --census       # who reaches the span
  python3 notes/prom_a_fa1404_identify.py --records      # the descriptor arrays
  python3 notes/prom_a_fa1404_identify.py --dl           # the display-list sites
  python3 notes/prom_a_fa1404_identify.py --null         # the calibration
  python3 notes/prom_a_fa1404_identify.py --selftest     # exits non-zero on failure
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
BASE = 0xF80000
LO, HI = 0xFA1404, 0xFA5400
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
ROM = open(IMG, "rb").read()
ROMB = open(IMGB, "rb").read()

# The code blocks INSIDE the span.  Their ends are derived, not typed: see
# code_blocks() -- each is decoded past its end and the decode must land on it.
# 0xFA146F-0xFA148B is a 7-entry jump table sitting between two of them; it is
# listed separately because unidasm decodes three of its entries as instructions
# and two as `db`, and a block that contains it is not "clean code".
CODE_HEAD_A = (0xFA1404, 0xFA146F)
JUMPTAB = (0xFA146F, 0xFA148B, 7)
CODE_HEAD_B = (0xFA148B, 0xFA15E8)
CODE_TAIL = (0xFA4EB5, 0xFA5369)
CODE_BLOCKS = (CODE_HEAD_A, CODE_HEAD_B, CODE_TAIL)

# Display-list runner thunks, read out of prom_b at import time by thunk_targets().
RUNNERS = {0xF42E00: ("A", "range"), 0xF42E04: ("B", "range"),
           0xF42E08: ("A", "one"), 0xF42E0C: ("B", "one")}

# Implied record lengths.  Interpreter A: notes/FINDINGS-ui-display-list.md, the
# handler table at 0xF31D21.  Interpreter B: notes/FINDINGS-ui-display-list-
# interpreter-b.md, the handler table at 0xF31DB1.  Both are readings of the
# handlers' own instructions, not fits to this span's data.
A_FIX = {0x00: 10, 0x01: 10, 0x02: 10, 0x05: 10, 0x09: 10, 0x0A: 10, 0x11: 10,
         0x12: 10, 0x13: 10, 0x15: 10, 0x1B: 10, 0x22: 10,
         0x0E: 8, 0x0B: 6, 0x03: 12, 0x04: 12, 0x23: 5}
A_TEXT4 = {0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E, 0x1F, 0x20, 0x21}
A_TEXT6 = {0x17, 0x1C}
A_FREE = {0x0C, 0x0D, 0x0F, 0x10, 0x14}
B_FIX = {0x00: 10, 0x06: 10, 0x01: 12, 0x02: 15, 0x03: 11, 0x08: 11, 0x04: 11,
         0x05: 11, 0x07: 17, 0x09: 12, 0x0A: 12, 0x0B: 13}
B_FREE = {0x0C, 0x0D, 0x0E}

INSTR = re.compile(r"^(?P<body>[^;]*?)\s*;\s*(?P<addr>[0-9A-F]{6})\s\s"
                   r"(?P<hex>(?:[0-9a-f]{2} )*[0-9a-f]{2})\s*$")
UROW = re.compile(r"^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$")


def b(a, n=1):
    return ROM[a - BASE:a - BASE + n]


def w16(a):
    return int.from_bytes(b(a, 2), "little")


def w32(a):
    return int.from_bytes(b(a, 4), "little")


# --------------------------------------------------------------------------
# instruction text: the transcription, plus unidasm for the span's own code
# --------------------------------------------------------------------------
def unidasm(lo, hi):
    """[(addr, nbytes, text)] from unidasm over [lo,hi).  It does not seek."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(ROM[lo - BASE:hi - BASE])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", "0x%X" % lo],
                             check=True, capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    ins = []
    for line in out.splitlines():
        m = UROW.match(line)
        if m:
            ins.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3)))
    return ins


_cache = {}


def transcribed():
    """Every PROVEN prom_a instruction: (addr, nbytes, text), from the .s.

    A line qualifies only if its body starts with a TAB (so it is an emitted
    instruction, not a header) and does not start with a directive dot (so
    `.byte`/`.ascii`/`.fill` data, which carries the same comment shape, is
    excluded).  Every one is byte-compared against the ROM by --selftest."""
    if "t" not in _cache:
        seq = []
        for line in open(SRC):
            m = INSTR.match(line.rstrip("\n"))
            if not m:
                continue
            body = m.group("body")
            if not body.startswith("\t"):
                continue
            txt = body.strip()
            if txt.startswith("."):
                continue
            seq.append((int(m.group("addr"), 16), len(m.group("hex").split()), txt))
        seq.sort()
        _cache["t"] = seq
    return _cache["t"]


def code_blocks():
    """The two in-span code blocks, decoded, with their ends PROVEN.

    Each is decoded 32 bytes past the end this file names; the named end must be
    an instruction boundary of that longer decode AND the decode must reach it
    with no `db`.  That is test 1+2 of notes/prom_a_linear_decode_check.py.  What
    pins the START is not this decode (a TLCS-900 decode resynchronises): it is
    the object immediately before -- the converted `lda_24` at 0xFA13FF ends at
    0xFA1404, and the display-list record at 0xFA4EAB is 10 bytes long and ends
    at 0xFA4EB5."""
    if "c" not in _cache:
        out = []
        for lo, hi in CODE_BLOCKS:
            ins = unidasm(lo, min(hi + 32, HI))
            bounds = {a for a, n, t in ins}
            assert hi in bounds, "0x%06X is not a decode boundary" % hi
            keep = [x for x in ins if x[0] < hi]
            assert keep[-1][0] + keep[-1][1] == hi, "decode overshoots 0x%06X" % hi
            assert not any(t.startswith("db") for a, n, t in keep), \
                "undecodable byte inside 0x%06X-0x%06X" % (lo, hi)
            out.append((lo, hi, keep))
        _cache["c"] = out
    return _cache["c"]


def all_instructions():
    """Transcribed prom_a + the two in-span blocks, sorted, deduplicated."""
    if "a" not in _cache:
        seen = {}
        for a, n, t in transcribed():
            seen[a] = (n, t)
        for lo, hi, ins in code_blocks():
            for a, n, t in ins:
                seen[a] = (n, t)
        _cache["a"] = sorted((a, n, t) for a, (n, t) in seen.items())
    return _cache["a"]


# --------------------------------------------------------------------------
# R1 -- the reference census
# --------------------------------------------------------------------------
def literal_refs():
    """Every reference into [LO,HI) that is a 24-bit LITERAL in an instruction
    whose boundary is known.  Returns {target: [(site, text), ...]}.

    This covers `call`, `jp`, `lda_24 Xrr,(addr)`, `ld Xrr,addr` and
    `add Xrr,addr` in one sweep, because the transcription and unidasm both
    spell the operand as a 6-hex-digit literal."""
    hits = {}
    for a, n, t in all_instructions():
        for m in re.finditer(r"0x(?:00)?(fa[0-9a-f]{4})\b", t, re.I):
            v = int(m.group(1), 16) | 0xF00000
            if LO <= v < HI:
                hits.setdefault(v, []).append((a, t))
    return hits


def relative_refs():
    """Every PC-relative `jr`/`jrl`/`calr` in prom_a whose target is in [LO,HI).

    EXACT half: sites that are instruction boundaries of all_instructions().
    UPPER-BOUND half: an opcode-anchored scan at every byte offset, which is what
    catches a caller inside a span that is still `.incbin`.  Both halves are
    returned; a report that quotes only the second is quoting coincidences."""
    exact, upper = [], []
    boundaries = {a: (n, t) for a, n, t in all_instructions()}

    def target(a, op):
        if op == 0x1E:                                     # calr d16
            d = int.from_bytes(b(a + 1, 2), "little")
            return a + 3 + (d - 0x10000 if d > 0x7FFF else d)
        if 0x60 <= op <= 0x6F:                             # jr cc,d8
            d = b(a + 1)[0]
            return a + 2 + (d - 0x100 if d > 0x7F else d)
        if 0x70 <= op <= 0x7F:                             # jrl cc,d16
            d = int.from_bytes(b(a + 1, 2), "little")
            return a + 3 + (d - 0x10000 if d > 0x7FFF else d)
        return None

    for i in range(len(ROM) - 3):
        a = BASE + i
        t = target(a, ROM[i])
        if t is None or not (LO <= t < HI):
            continue
        (exact if a in boundaries else upper).append((a, t, ROM[i]))
    return exact, upper


def pointer_refs():
    """Every 4-byte little-endian word in any of the four images whose value is in
    [LO,HI).  Split by image and by whether the site is inside the span itself."""
    out = {}
    for name, path, base in (("prom_a", IMG, 0xF80000),
                             ("prom_b", IMGB, 0xF00000),
                             ("prom_c", os.path.join(ROOT, "original_ROMs",
                                                     "wsa1_prom_c.ic28"), 0xF80000),
                             ("prom_d", os.path.join(ROOT, "original_ROMs",
                                                     "wsa1_prom_d.bin"), 0)):
        d = open(path, "rb").read()
        rows = []
        for i in range(len(d) - 3):
            v = int.from_bytes(d[i:i + 4], "little")
            if LO <= v < HI:
                rows.append((base + i, v))
        out[name] = rows
    return out


# --------------------------------------------------------------------------
# R1 -- display-list call sites
# --------------------------------------------------------------------------
def thunk_targets():
    """RUNNERS, re-read from prom_b so the table cannot rot: each slot must be a
    4-byte `jp` (0x1B) and the address it names is returned."""
    out = {}
    for slot in RUNNERS:
        o = slot - 0xF00000
        assert ROMB[o] == 0x1B, "thunk 0x%06X is not a jp" % slot
        out[slot] = int.from_bytes(ROMB[o + 1:o + 4], "little")
    return out


def dl_sites():
    """Every `lda_24 Xrr,(addr) [.. push Xrr ..] call <runner>` group in prom_a.

    Returns [(site, interp, start, end)].  `end` for a one-record runner is
    start + the record's own length byte, which is what T_F42E08/0C compute
    (`ld XIX,XIY / inc 1,XIX` then the loop advances by the length byte).

    The walk back is bounded at 8 instructions and stops at a `ret`/`jp`/`jr`, so
    it cannot cross a routine boundary and invent an argument."""
    seq = all_instructions()
    sites = []
    for i, (a, n, t) in enumerate(seq):
        m = re.match(r"call 0x([0-9a-f]{6})$", t)
        if not m:
            continue
        tgt = int(m.group(1), 16)
        if tgt not in RUNNERS:
            continue
        stack, reg, j = [], {}, i - 1
        while j >= 0 and i - j <= 8:
            aa, nn, tt = seq[j]
            # two spellings: the transcription's macro form and unidasm's own
            mm = (re.match(r"lda_24 (x\w\w), \(0x([0-9a-f]{6})\)$", tt)
                  or re.match(r"lda (X\w\w),\s*0x([0-9a-f]{6})$", tt))
            pp = re.match(r"push (X\w\w)$", tt)
            if pp:
                stack.append((pp.group(1), aa))
            elif mm:
                reg.setdefault(mm.group(1).upper(), []).append(
                    (int(mm.group(2), 16), aa))
            elif re.match(r"(ret|reti|jp |jr |jrl )", tt):
                break
            j -= 1
        args = []
        for rname, pa in stack:
            v = None
            for val, va in reg.get(rname, []):
                if va < pa:
                    v = val
                    break
            args.append(v)
        interp, mode = RUNNERS[tgt]
        if mode == "range" and len(args) >= 2 and args[0] and args[1]:
            sites.append((a, interp, args[0], args[1]))
        elif mode == "one" and args and args[0]:
            s = args[0]
            sites.append((a, interp, s, s + b(s + 1)[0]))
    return [s for s in sites if LO <= s[2] < HI]


# --------------------------------------------------------------------------
# R2 -- the framing walk
# --------------------------------------------------------------------------
def ok_a(op, ln):
    if op in A_FIX:
        return ln == A_FIX[op]
    if op in A_TEXT4:
        return ln >= 4
    if op in A_TEXT6:
        return ln >= 6
    if op in A_FREE:
        return ln >= 2
    return False


def ok_b(op, ln):
    if op in B_FIX:
        return ln == B_FIX[op]
    if op in B_FREE:
        return ln >= 2
    return False


def frame(s, e, mode="AB", rom=None, off=0):
    """Walk records from s; True iff the walk lands EXACTLY on e and every record
    has the length its opcode's handler implies.  `rom`/`off` let the null
    calibration run the same rule over an arbitrary buffer."""
    d = rom if rom is not None else ROM
    base = off if rom is not None else BASE
    f = ok_a if mode == "A" else ok_b if mode == "B" else \
        (lambda o, l: ok_a(o, l) or ok_b(o, l))
    p, recs = s, []
    while p < e:
        if p + 1 - base >= len(d):
            return False, recs
        op, ln = d[p - base], d[p + 1 - base]
        if not f(op, ln):
            return False, recs
        recs.append((p, op, ln))
        p += ln
    return p == e, recs


# --------------------------------------------------------------------------
# operand arrays a record points at
# --------------------------------------------------------------------------
def record_pointers(recs):
    """(record, kind, target, implied_size) for every record that carries a
    32-bit pointer.  Sizes are UPPER BOUNDS -- `(mask >> shift) + 1` bounds the
    index, it does not measure the array -- and are cut to the next object by
    solve()."""
    out = []
    for p, op, ln, interp in recs:
        if interp in ("A", "AB") and op in (3, 4) and ln == 12:
            bc, hl = w16(p + 8), w16(p + 10)
            out.append((p, "A%02X" % op, w32(p + 2), bc * hl,
                        "bitmap %dx%d" % (bc, hl), bc))
        if interp in ("B", "AB"):
            n = (b(p + 4)[0] >> (b(p + 5)[0] & 7)) + 1
            if op in (2, 7) and ln in (15, 17):
                wdt = b(p + 0x0B)[0]
                out.append((p, "B%02X" % op, w32(p + 7), wdt * n,
                            "strings w=%d n<=%d" % (wdt, n), wdt))
            elif op in (3, 8) and ln == 11:
                out.append((p, "B%02X" % op, w32(p + 7), 8 * n,
                            "8-byte x%d max" % n, 8))
            elif op == 4 and ln == 11:
                out.append((p, "B%02X" % op, w32(p + 7), 6 * n,
                            "6-byte x%d max" % n, 6))
    return out


# --------------------------------------------------------------------------
# the head-region tables
# --------------------------------------------------------------------------
# The parameter-edit primitives, and how many descriptor bytes each one READS.
# Every depth here is a sentence in prom_b/wsa1_prom_b.s's own header for that
# routine, which in turn cites the instruction that reads the highest offset.
CONSUMERS = {0xF42C78: ("sub_F550A6", 8),               # +0..+7
             0xF42C7C: ("sub_F5517B", 3),               # +0..+2
             0xF42C94: ("IndexedParam_AdjustField", 8),  # +0..+7
             0xF42C98: ("IndexedParam_SetBit", 3)}       # +0..+2


def descriptor_consumers():
    """{addr: set(consumer names)} for every address handed to a parameter-edit
    primitive as its DESCRIPTOR argument.

    This is what separates a 9-byte descriptor from any other 9-byte object, and
    it is the reason the two record sizes in this span are 9 and 3: the four
    primitives read exactly 8 and exactly 3 descriptor bytes.  The walk follows
    at most two unconditional `jr`s, because five of the sites load the pointer,
    push it and then jump to a shared `pushw <index> / call` tail."""
    seq = all_instructions()
    by_addr = {a: i for i, (a, n, t) in enumerate(seq)}
    out = {}
    for i, (a, n, t) in enumerate(seq):
        mm = (re.match(r"lda_24 (x\w\w), \(0x([0-9a-f]{6})\)$", t)
              or re.match(r"lda (X\w\w),\s*0x([0-9a-f]{6})$", t))
        if not mm:
            continue
        v = int(mm.group(2), 16)
        if not (LO <= v < HI):
            continue
        # a `ldw bc,N / lda_24 XIY,(A) / lda XIX,(XIZ-k) / ldir` copies N bytes
        # out of A into a stack local that is then handed to a primitive.  The
        # copy length is the record length, stated by the ROM.
        for k in range(max(0, i - 3), i):
            m4 = re.match(r"(?:ldw bc, |ld BC,)0x0*([0-9a-f]+)$", seq[k][2])
            if m4 and any(seq[q][2].startswith(("ldir", "ldi"))
                          for q in range(i + 1, min(len(seq), i + 4))):
                out.setdefault(v, set()).add(("ldir copy", int(m4.group(1), 16)))
        j, hops = i + 1, 0
        while j < len(seq) and hops <= 2:
            aa, nn, tt = seq[j]
            m2 = re.match(r"call 0x([0-9a-f]{6})$", tt)
            if m2 and int(m2.group(1), 16) in CONSUMERS:
                out.setdefault(v, set()).add(CONSUMERS[int(m2.group(1), 16)])
                break
            m3 = re.match(r"jr (?:T,)?\.?L?F?(?:0x)?([0-9A-Fa-f]{6})$", tt)
            if m3 and int(m3.group(1), 16) in by_addr:
                j = by_addr[int(m3.group(1), 16)]
                hops += 1
                continue
            if re.match(r"(ret|reti|jp )", tt):
                break
            j += 1
    return out


def head_objects(refs):
    """Objects in 0xFA15E8-0xFA1F21, each bounded by the NEXT referenced address.

    Every object here starts at an address some instruction names.  Its extent is
    the distance to the next such address, so both ends of every object are pinned
    by the ROM and not by a stride this script chose.  The kinds are read off the
    size and the content:
      +92 and 23 in-range LE32 words   -> a 23-entry handler table (R3)
      +9, +6, +3                       -> a parameter descriptor
      anything else                    -> reported as a byte table with its size
    """
    ks = sorted(k for k in refs if 0xFA15E8 <= k < 0xFA1F21)
    cons = descriptor_consumers()
    objs = []
    for i, a in enumerate(ks):
        e = ks[i + 1] if i + 1 < len(ks) else 0xFA1F21
        n = e - a
        if n == 92 and all(w32(a + 4 * k) == 0xF42C70 or
                           0xF90000 <= w32(a + 4 * k) < 0xFB0000
                           for k in range(23)):
            kind = "handler_table_23"
        elif n in (9, 3) and any(d == n or (n == 9 and d == 8)
                                 for name, d in cons.get(a, ())):
            kind = "descriptor_%d" % n
        elif n == 6 and any(d == 6 for name, d in cons.get(a, ())):
            kind = "descriptor_6"
        elif n % 4 == 0 and n >= 8 and all(
                w32(a + 4 * k) == 0xF42C70 or 0xF90000 <= w32(a + 4 * k) < 0xFB0000
                for k in range(n // 4)):
            kind = "pointer_table_%d" % (n // 4)
        else:
            kind = "byte_table_%d" % n
        objs.append((a, e, kind))
    return objs


# --------------------------------------------------------------------------
# the solver
# --------------------------------------------------------------------------
def solve():
    """The whole layout, as a list of (lo, hi, kind, evidence)."""
    refs = literal_refs()
    objs = []
    for lo, hi in CODE_BLOCKS:
        objs.append((lo, hi, "code", "unidasm decode lands on 0x%06X" % hi))
    objs.append((JUMPTAB[0], JUMPTAB[1], "jump_table",
                 "add XBC,0x00FA146F at 0xFA1465 then ld XBC,(XBC) / jp XBC; "
                 "cp BC,6 / jr UGT at 0xFA145E bounds the index at 6, so 7 "
                 "entries, and entry 0 IS 0x%06X -- the table ends on its own "
                 "first target" % w32(JUMPTAB[0])))
    fill = 0xFA5369
    objs.append((fill, HI, "pad", "%d x 0x0E to MIDI_EntryThunks" % (HI - fill)))
    for a, e, kind in head_objects(refs):
        objs.append((a, e, kind, "named at %s" %
                     ", ".join("0x%06X" % s for s, t in refs[a][:2])))

    anchors = {}
    for site, interp, s, e in dl_sites():
        anchors.setdefault((s, e), set()).add(interp)

    def place(lst):
        lst = sorted(lst)
        merged = []
        for lo, hi, k, ev in lst:
            if merged and lo < merged[-1][1]:
                merged[-1] = (merged[-1][0], max(merged[-1][1], hi),
                              merged[-1][2], merged[-1][3])
            else:
                merged.append((lo, hi, k, ev))
        return merged

    dl = [(s, e, "display_list", "call site") for (s, e) in anchors]
    known = place(objs + dl)

    # fixpoint: fill gaps with record runs, follow the pointers those records
    # carry, and cut every array to the next object that starts after it.
    for _ in range(12):
        grew = False
        gaps = []
        prev = LO
        for lo, hi, k, ev in known:
            if prev < lo:
                gaps.append((prev, lo))
            prev = max(prev, hi)
        if prev < HI:
            gaps.append((prev, HI))
        for gs, ge in gaps:
            hit = False
            for mode in ("A", "B", "AB"):
                ok, _ = frame(gs, ge, mode)
                if ok:
                    known = place(known + [(gs, ge, "display_list",
                                            "frames as %s records between "
                                            "0x%06X and 0x%06X" % (mode, gs, ge))])
                    grew = hit = True
                    break
            if hit:
                continue
            # PARTIAL frame.  A gap is often records FOLLOWED BY the array those
            # records point at (0xFA2D45 is two op-03 records and then their two
            # 8-byte arrays).  Walk records from the gap start and stop the moment
            # the walk arrives at an address one of the records already walked
            # NAMES: that is the array's own base, so the prefix is records and the
            # boundary is stated by the data rather than chosen.
            p, walked = gs, []
            while p < ge:
                op, ln = b(p)[0], b(p + 1)[0]
                named = {t for pp, kk, t, sz, nn, ww
                         in record_pointers([(x, y, z, "AB") for x, y, z in walked])}
                if p > gs and p in named:
                    known = place(known + [(gs, p, "display_list",
                                            "records 0x%06X-0x%06X, ended by a "
                                            "pointer one of them carries"
                                            % (gs, p))])
                    grew = True
                    break
                if not (ok_a(op, ln) or ok_b(op, ln)):
                    break
                walked.append((p, op, ln))
                p += ln
        recs = []
        for lo, hi, k, ev in known:
            if k != "display_list":
                continue
            interp = "AB"
            for (s, e), iv in anchors.items():
                if s >= lo and e <= hi and len(iv) == 1:
                    pass
            p = lo
            while p < hi:
                op, ln = b(p)[0], b(p + 1)[0]
                if ln == 0:
                    break
                recs.append((p, op, ln, "AB"))
                p += ln
        # ⚠ the cut has to know about EVERY pointer target, not only the objects
        # already placed.  Cutting only to placed objects made 0xFA3439 swallow
        # 0xFA345D, which two other records point at: the byte total still tiled,
        # and the boundary was still wrong.
        allptr = {t for pp, kk, t, sz, nn, ww in record_pointers(recs)
                  if LO <= t < HI}
        starts = sorted({lo for lo, hi, k, ev in known} | allptr)
        # ⚠ several records can point at ONE array with different masks -- twelve
        # records reach 0xFA4B7D with mask 0x0F and four with 0x1F.  The array has
        # to hold the largest index any of them can produce, so the bound is the
        # MAXIMUM over the records, not the first one found.  Taking the first
        # left 0xFA4B9D-0xFA4B9F ("F ") outside every object.
        biggest = {}
        for pp, kk, tt, sz, nn, ww in record_pointers(recs):
            if biggest.get(tt, (0,))[0] < sz:
                biggest[tt] = (sz, pp, kk, nn, ww)
        for p, kind, tgt, size, note, width in record_pointers(recs):
            if not (LO <= tgt < HI):
                continue
            size, p, kind, note, width = (biggest[tgt][0], biggest[tgt][1],
                                          biggest[tgt][2], biggest[tgt][3],
                                          biggest[tgt][4])
            if any(lo <= tgt < hi for lo, hi, k, ev in known):
                continue
            nxt = min([s for s in starts if s > tgt] + [HI])
            end = min(tgt + size, nxt)
            why = "cut to 0x%06X" % end
            # R6 STRINGS.  When the mask-implied size OVERSHOOTS the space
            # available, the cut boundary is not evidence -- it is "wherever the
            # next thing happens to be", and at 0xFA2BC3 that swallowed 188 bytes
            # of display-list records.  For a STRING table there is a content
            # test that is not a guess: an entry is a fixed-width run of printable
            # characters, so the table ends at the first entry that is not one.
            # 0x88 and 0x8C are admitted because the note-name table spells D-flat
            # and F-sharp with them (0xFA22A0, 0xFA4B4B).
            if "strings" in note and tgt + size > nxt and width:
                k = 0
                while tgt + (k + 1) * width <= nxt and all(
                        0x20 <= c < 0x7F or c in (0x88, 0x8C)
                        for c in b(tgt + k * width, width)):
                    k += 1
                if 0 < k * width < end - tgt:
                    end = tgt + k * width
                    why = ("R6: %d entries are printable, entry %d is not, "
                           "so the table ends at 0x%06X" % (k, k, end))
            if end > tgt:
                known = place(known + [(tgt, end, "operand_table",
                                        "%s at 0x%06X: %s, %s [w=%d max=%d]"
                                        % (kind, p, note, why, width, size))])
                grew = True
        if not grew:
            break

    # R5 EXTEND -- a record's `(mask >> shift) + 1` bounds the INDEX; it does not
    # measure the array (FINDINGS-ui-display-list-interpreter-b.md says so, with
    # the 0xF030E6 counter-example).  So where a hole follows a table of entry
    # width w and is a whole number of w-byte entries, the table really runs to
    # the next proven object.  Only holes are touched, and only exactly-divisible
    # ones: a hole this cannot close stays UNACCOUNTED and is reported as such.
    for _ in range(4):
        prev, holes = LO, []
        for lo, hi, k, ev in known:
            if prev < lo:
                holes.append((prev, lo))
            prev = max(prev, hi)
        if prev < HI:
            holes.append((prev, HI))
        if not holes:
            break
        changed = False
        recs2 = []
        for lo, hi, k, ev in known:
            if k != "display_list":
                continue
            p = lo
            while p < hi:
                op, ln = b(p)[0], b(p + 1)[0]
                if ln == 0:
                    break
                recs2.append((p, op, ln, "AB"))
                p += ln
        allptr = {t for pp, kk, t, sz, nn, ww in record_pointers(recs2)
                  if LO <= t < HI}
        for hs, he in holes:
            for i, (lo, hi, k, ev) in enumerate(known):
                if hi != hs or k != "operand_table" or "[w=" not in ev:
                    continue
                w = int(ev.split("[w=")[1].split("]")[0].split(" ")[0])
                mx = int(ev.split("max=")[1].split("]")[0]) if "max=" in ev else 0
                if (w and (he - hs) % w == 0 and he - lo <= mx
                        and not any(hs < t < he for t in allptr)):
                    known[i] = (lo, he, k, ev.split(" [w=")[0] +
                                ", EXTENDED to 0x%06X (%d more %d-byte "
                                "entries) [w=%d max=%d]"
                                % (he, (he - hs) // w, w, w, mx))
                    changed = True
                break
        if not changed:
            break
        known = place(known)
    return known


def coarse(known):
    """The six-way summary the report quotes."""
    cuts = [(LO, 0xFA15E8, "code"), (0xFA15E8, 0xFA1690, "record_array"),
            (0xFA1690, 0xFA1F21, "table_block"), (0xFA1F21, 0xFA4EB5, "display_lists"),
            (0xFA4EB5, 0xFA5369, "code"), (0xFA5369, HI, "pad")]
    return cuts


# --------------------------------------------------------------------------
# null calibration
# --------------------------------------------------------------------------
def proven_code_runs():
    """Maximal runs of PROVEN prom_a instruction text, as (lo, hi) byte ranges.

    Excludes the two in-span blocks: they are the thing being classified."""
    seq = transcribed()
    runs, cur = [], []
    for a, n, t in seq:
        if cur and a != cur[-1][0] + cur[-1][1]:
            if len(cur) > 1:
                runs.append((cur[0][0], cur[-1][0] + cur[-1][1]))
            cur = []
        cur.append((a, n))
    if len(cur) > 1:
        runs.append((cur[0][0], cur[-1][0] + cur[-1][1]))
    return [r for r in runs if not (LO <= r[0] < HI)]


def null(verbose=True):
    runs = proven_code_runs()
    tot = sum(e - s for s, e in runs)
    known = solve()
    # calibrate on the lengths R2 was actually TRUSTED at -- the runs the solver
    # accepted because they frame between two objects other rules proved.
    used = sorted({hi - lo for lo, hi, k, ev in known
                   if k == "display_list" and ev.startswith("frames as")})
    lengths = used or [64]
    if verbose:
        print("NULL corpus: every maximal run of PROVEN prom_a instruction text in")
        print("prom_a/wsa1_prom_a.s OUTSIDE the span -- %d runs, %d bytes."
              % (len(runs), tot))
        print("A rule that fires inside one of these runs is a FALSE POSITIVE.")
        print("  ⚠ this corpus GROWS as rounds convert code; it was measured on")
        print("  the working tree of the session that wrote this file.")
    # R2 -- frame a window of each real gap length at every offset
    fp2 = 0
    trials = 0
    win = lengths
    per = {}
    for s, e in runs:
        for L in win:
            for p in range(s, e - L):
                trials += 1
                ok, _ = frame(p, p + L, "AB")
                if ok:
                    fp2 += 1
                    per[L] = per.get(L, 0) + 1
    # R3 -- 23 in-range LE32 words
    fp3 = 0
    for s, e in runs:
        for p in range(s, e - 92):
            if all(w32(p + 4 * k) == 0xF42C70 or
                   0xF90000 <= w32(p + 4 * k) < 0xFB0000 for k in range(23)):
                fp3 += 1
    # R4 -- 16 x 0x0E
    fp4 = 0
    for s, e in runs:
        p = s
        while p < e:
            if b(p)[0] == 0x0E:
                q = p
                while q < e and b(q)[0] == 0x0E:
                    q += 1
                if q - p >= 16:
                    fp4 += 1
                p = q
            else:
                p += 1
    if verbose:
        print("  R2 FRAME  (%d window lengths, %d..%d, x every offset = %d trials)"
              % (len(win), min(win), max(win), trials))
        print("            false positives: %d   (%.4f%%)"
              % (fp2, 100.0 * fp2 / max(trials, 1)))
        for L in win:
            print("              len %4d of %6d trials: %5d false positives"
                  % (L, sum(max(0, e - s - L) for s, e in runs), per.get(L, 0)))
        # R6 -- an "entry" of w printable bytes.  Measured at w=16, the only
        # width R6 actually decided a boundary at, and for TWO consecutive
        # entries, which is the least the rule needs before it moves anything.
        fp6 = 0
        for s2, e2 in runs:
            for q in range(s2, e2 - 32):
                if all(0x20 <= c < 0x7F or c in (0x88, 0x8C) for c in b(q, 32)):
                    fp6 += 1
        print("  R6 STRINGS  2 x 16 printable bytes -- false positives: %d" % fp6)
        print("  R3 PTR23    false positives: %d" % fp3)
        print("  R4 FILL     false positives: %d  (0x0E is `ret`, so a run of "
              "`ret` stubs inside code IS a run of 0x0E)" % fp4)
        print("  \u26a0 R2 is the rule with the real rate, and it is never used "
              "alone: every")
        print("  run it accepts is bounded at BOTH ends by an object another rule "
              "proved,")
        print("  which --selftest asserts.")
    return dict(runs=len(runs), bytes=tot, trials=trials, fp_frame=fp2,
                fp_ptr23=fp3, fp_fill=fp4)


# --------------------------------------------------------------------------
def cmd_census():
    refs = literal_refs()
    n = sum(len(v) for v in refs.values())
    print("=== R1  24-bit literals in instructions with a known boundary")
    print("  %d distinct addresses, %d reference sites" % (len(refs), n))
    inside = sum(1 for v in refs.values() for s, t in v if LO <= s < HI)
    print("  of those sites, %d are INSIDE the span itself (the two code blocks)"
          % inside)
    kinds = {}
    for v in refs.values():
        for s, t in v:
            kinds[t.split(",")[0].split(" (")[0]] = \
                kinds.get(t.split(",")[0].split(" (")[0], 0) + 1
    for k in sorted(kinds, key=lambda x: -kinds[x]):
        print("    %-24s %d" % (k, kinds[k]))
    ex, up = relative_refs()
    print("=== R1  PC-relative jr/jrl/calr")
    print("  at a proven instruction boundary: %d   (EXACT)" % len(ex))
    for a, t, op in ex:
        print("    0x%06X -> 0x%06X" % (a, t))
    print("  opcode-anchored elsewhere:        %d   (UPPER BOUND, mostly "
          "coincidence)" % len(up))
    print("=== R1  bare 32-bit little-endian pointers")
    for name, rows in pointer_refs().items():
        ins = [r for r in rows if name == "prom_a" and LO <= r[0] < HI]
        print("  %-7s %4d  (%d of them inside the span itself)"
              % (name, len(rows), len(ins)))
    print("=== the prom_b thunk directory")
    hits = [a for a in range(0xF40000, 0xF44018, 4)
            if LO <= int.from_bytes(ROMB[a - 0xF00000 + 1:a - 0xF00000 + 4],
                                    "little") < HI and ROMB[a - 0xF00000] in (0x1B, 0x1D)]
    print("  slots naming an address in the span: %d" % len(hits))


def cmd_dl():
    tt = thunk_targets()
    for k in sorted(tt):
        print("  T_%06X -> 0x%06X   interpreter %s, %s"
              % (k, tt[k], RUNNERS[k][0], RUNNERS[k][1]))
    sites = dl_sites()
    ok = 0
    for site, interp, s, e in sites:
        good, recs = frame(s, e, interp)
        ok += bool(good)
        if not good:
            print("  NOT FRAMED  site 0x%06X %s 0x%06X-0x%06X" % (site, interp, s, e))
    print("  %d call sites naming the span; %d frame under their own interpreter"
          % (len(sites), ok))


def cmd_records(verbose=True):
    refs = literal_refs()
    objs = head_objects(refs)
    groups = []
    for a, e, kind in objs:
        if kind.startswith("descriptor"):
            n = int(kind.split("_")[1])
            if groups and groups[-1][2] == n and groups[-1][1] == a:
                groups[-1] = (groups[-1][0], e, n, groups[-1][3] + 1)
            else:
                groups.append((a, e, n, 1))
    if verbose:
        print("  parameter-descriptor arrays (stride proven on the LAST record: the")
        print("  address after it is itself named by an instruction)")
        for s, e, n, c in groups:
            print("    0x%06X-0x%06X  %2d x %d bytes   last record 0x%06X  %s"
                  % (s, e, c, n, e - n, b(e - n, n).hex(" ")))
        print("  total %d records in %d arrays"
              % (sum(g[3] for g in groups), len(groups)))
    return groups


def cmd_layout(fine=False):
    known = solve()
    prev, holes = LO, []
    for lo, hi, k, ev in known:
        if prev < lo:
            holes.append((prev, lo))
        prev = max(prev, hi)
    if prev < HI:
        holes.append((prev, HI))
    tot = {}
    if fine:
        for lo, hi, k, ev in known:
            print("  %-18s 0x%06X-0x%06X %6d  %s" % (k, lo, hi, hi - lo, ev))
        for lo, hi in holes:
            print("  %-18s 0x%06X-0x%06X %6d  --" % ("UNACCOUNTED", lo, hi, hi - lo))
    for lo, hi, k, ev in known:
        tot[k] = tot.get(k, 0) + hi - lo
    for lo, hi in holes:
        tot["UNACCOUNTED"] = tot.get("UNACCOUNTED", 0) + hi - lo
    print("  ---- by kind")
    for k in sorted(tot, key=lambda x: -tot[x]):
        print("    %-18s %6d" % (k, tot[k]))
    print("    %-18s %6d of %d" % ("TOTAL", sum(tot.values()), HI - LO))
    print("  ---- coarse")
    for lo, hi, k in coarse(known):
        print("    %-16s 0x%06X-0x%06X %6d" % (k, lo, hi, hi - lo))
    return known, holes


def selftest():
    fails = []
    nchecks = [0]

    def chk(name, cond):
        nchecks[0] += 1
        print("  %-62s %s" % (name, "ok" if cond else "FAIL"))
        if not cond:
            fails.append(name)

    for a, n, t in transcribed()[:0] or []:
        pass
    bad = 0
    for line in open(SRC):
        m = INSTR.match(line.rstrip("\n"))
        if not m or not m.group("body").startswith("\t"):
            continue
        if m.group("body").strip().startswith("."):
            continue
        a = int(m.group("addr"), 16)
        h = bytes(int(x, 16) for x in m.group("hex").split())
        if h != b(a, len(h)):
            bad += 1
    chk("every transcribed instruction matches the ROM bytes", bad == 0)
    tt = thunk_targets()
    chk("T_F42E00 -> 0xF31800 (interpreter A, start+end)", tt[0xF42E00] == 0xF31800)
    chk("T_F42E04 -> 0xF31814 (interpreter B, start+end)", tt[0xF42E04] == 0xF31814)
    chk("T_F42E08 -> 0xF31828 (interpreter A, one record)", tt[0xF42E08] == 0xF31828)
    chk("T_F42E0C -> 0xF3183D (interpreter B, one record)", tt[0xF42E0C] == 0xF3183D)
    blocks = code_blocks()
    chk("code 0xFA1404-0xFA146F decodes, ends on the jump table",
        blocks[0][1] == JUMPTAB[0])
    chk("code 0xFA148B-0xFA15E8 decodes and ends in ret",
        blocks[1][2][-1][2].startswith("ret"))
    chk("code 0xFA4EB5-0xFA5369 decodes and ends in ret",
        blocks[2][2][-1][2].startswith("ret"))
    chk("the 7 jump-table entries all land in 0xFA148B-0xFA15E8",
        all(0xFA148B <= w32(JUMPTAB[0] + 4 * k) < 0xFA15E8 for k in range(7)))
    chk("the jump table ends exactly on its own entry 0",
        w32(JUMPTAB[0]) == JUMPTAB[1])
    chk("0xFA5369-0xFA5400 is 151 bytes of 0x0E",
        set(b(0xFA5369, HI - 0xFA5369)) == {0x0E})
    chk("0xFA5368 is the routine's own ret, not pad",
        b(0xFA5368)[0] == 0x0E and blocks[2][1] == 0xFA5369)
    sites = dl_sites()
    framed = sum(1 for s, i, a, e in sites if frame(a, e, i)[0])
    chk("all %d display-list call sites frame (%d)" % (len(sites), framed),
        framed == len(sites))
    g = cmd_records(verbose=False)
    first = [x for x in g if x[0] == 0xFA15EE][0]
    chk("0xFA15EE array is 18 x 9 and its last record is 0xFA1687",
        first[2] == 9 and first[3] == 18 and first[1] - 9 == 0xFA1687)
    chk("the byte after that array, 0xFA1690, is itself a named table base",
        0xFA1690 in literal_refs())
    known, holes = solve(), None
    prev, holes = LO, []
    for lo, hi, k, ev in known:
        if prev < lo:
            holes.append((prev, lo))
        prev = max(prev, hi)
    if prev < HI:
        holes.append((prev, HI))
    chk("no overlaps in the derived layout",
        all(known[i][1] <= known[i + 1][0] for i in range(len(known) - 1)))
    print("  unaccounted: %d bytes in %d holes"
          % (sum(h[1] - h[0] for h in holes), len(holes)))
    ex, up = relative_refs()
    chk("no PC-relative branch at a proven boundary reaches 0xFA4EB5",
        not any(t == 0xFA4EB5 for a, t, op in ex))
    chk("no LE32 pointer anywhere names 0xFA4EB5",
        not any(v == 0xFA4EB5 for rows in pointer_refs().values() for a, v in rows))
    # every run R2 accepted must be bounded at BOTH ends by an object some other
    # rule proved -- R2's measured false-positive rate is NOT zero (--null), so a
    # run it accepted with a free end would be a guess.
    ends = {hi for lo, hi, k, ev in known
            if not (k == "display_list" and ev.startswith("frames as"))} | {LO}
    starts = {lo for lo, hi, k, ev in known
              if not (k == "display_list" and ev.startswith("frames as"))} | {HI}
    r2 = [(lo, hi) for lo, hi, k, ev in known
          if k == "display_list" and ev.startswith("frames as")]
    chk("all %d R2-accepted runs are bounded at both ends by another rule"
        % len(r2), all(lo in ends and hi in starts for lo, hi in r2))
    chk("the layout covers the span exactly", sum(hi - lo for lo, hi, k, ev in known)
        == HI - LO)
    # ★ WHY 23.  sub_F55019 (thunk T_F42C74, prom_b 0xF55019, converted) is the
    # index normaliser every handler-table reader calls before `mul A,0x04`.  It
    # rejects an index above 0x1F, subtracts 0x11 from 0x11..0x19 and 9 from
    # 0x1A..0x1F.  So the set of values it can return is 0x00..0x16 -- TWENTY-THREE
    # -- and that, not the distance to the next table, is why the tables are 92
    # bytes.  Transcribed from prom_b/wsa1_prom_b.s:sub_F55019 (0xF55026 `cp
    # HL,0x1F`, 0xF5505E/0xF55065 the 0x11..0x19 window, 0xF5507A the >= 0x1A cut).
    outs = set()
    for i in range(0x20):
        v = i
        if 0x11 <= i <= 0x19:
            v = i - 0x11
        if i >= 0x1A:
            v = i - 9
        outs.add(v)
    chk("sub_F55019 has exactly 23 distinct outputs, so 23-entry tables",
        len(outs) == 23 and max(outs) == 0x16)
    nt = sum(1 for lo, hi, k, ev in known if k == "handler_table_23")
    noop = sum(1 for lo, hi, k, ev in known if k == "handler_table_23"
               for j in range(23) if w32(lo + 4 * j) == 0xF42C70)
    chk("16 handler tables, 222 of their 368 slots are the T_F42C70 no-op",
        nt == 16 and noop == 222)
    allp = [i for i in range(len(ROM) - 3)
            if ROM[i:i + 4] == b"\x70\x2c\xf4\x00"]
    chk("all 222 `70 2C F4 00` words in prom_a are those slots -- which answers "
        "prom_b's open question about the 397", len(allp) == 222
        and all(LO <= 0xF80000 + i < HI for i in allp))
    print("  %d checks, %d failed" % (nchecks[0], len(fails)))
    return 1 if fails else 0


def main():
    if "--census" in sys.argv:
        cmd_census()
    elif "--dl" in sys.argv:
        cmd_dl()
    elif "--records" in sys.argv:
        cmd_records()
    elif "--null" in sys.argv:
        null()
    elif "--selftest" in sys.argv:
        return selftest()
    else:
        cmd_layout("--fine" in sys.argv)
    return 0


if __name__ == "__main__":
    sys.exit(main())
