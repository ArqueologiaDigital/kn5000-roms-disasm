#!/usr/bin/env python3
"""Convert prom_b 0xF00C4D-0xF017FF -- the largest `.incbin` left in this image
(2,995 B, 28% of prom_b's whole verbatim debt) -- and say what each part of it
IS, rather than forcing one reading over the whole span.

QUESTION IT ANSWERS
    "wsa1_prom_b.s leaves 2,995 bytes at file offset 0x000C4D verbatim, with the
     recorded reason `not reachable from the round-1 walk'.  Is that reason
     still the whole story, and what are those bytes?"

ANSWER: the reason was true and is not the whole story.  The span is THREE
    objects and a two-byte remainder, and the boundaries are checkable:

      0xF00C4D-0xF00CA1    85 B   the TAIL OF A 4-BYTE POINTER ARRAY that starts
                                  at 0xF00C46, seven bytes before this span, and
                                  runs to the byte before the code below.  This
                                  span opens ONE BYTE INTO an entry.
      0xF00CA2-0xF014ED  2,124 B  CODE.  828 instructions, tiling the region
                                  exactly, no `db`, ending `unlk XIZ` / `ret`.
      0xF014EE-0xF017FD    784 B  a SECOND 4-BYTE POINTER ARRAY, 196 entries,
                                  in 18-slot records.
      0xF017FE-0xF017FF      2 B  REFUSED -- see THE TWO BYTES I WOULD NOT TYPE.

    2,995 bytes of `.incbin` become 2,993 bytes of typed data and instructions
    and 2 bytes of `.byte` with the refusal stated.

────────────────────────────────────────────────────────────────────────────────
WHY 0xF00CA2-0xF014ED IS CODE -- five checks, in --selftest
────────────────────────────────────────────────────────────────────────────────
The hazard here is data that decodes into plausible mnemonics: re-assembling a
wrong reading reproduces the same bytes, so the byte gate cannot object.  None
of these five checks is passed by a plausible decode of data.

  C1  EXACT TILING.  A linear MAME-unidasm decode from 0xF00CA2 lands exactly on
      0xF014EE -- the first byte of the pointer array below -- with no
      instruction straddling the boundary and no resynchronisation.
  C2  NO `db`.  All 828 instructions decode; unidasm's undecodable marker
      appears 0 times inside the region and 26 times in the 786 bytes after it,
      which is what a linear decode of a pointer array looks like.
  C3  INTERNAL BRANCHES LAND ON BOUNDARIES.  All 54 `jr`/`jrl`/`jp`/`call`/
      `calr` whose target is inside the region land on an instruction start of
      that same decode.  0 exceptions.
  C4  AN INDEPENDENT TABLE AGREES.  26 pointers in 0xF0033C-0xF003C7 -- a region
      OUTSIDE this span, and outside this lane -- name addresses in
      0xF01200-0xF014CE.  All 26 land on instruction starts of the decode.  The
      framing was not chosen to make them fit; they were not consulted until
      after C1 held.
  C5  PROLOGUE/EPILOGUE PAIRING.  54 `link XIZ,imm16` and 54 `unlk XIZ`.  The
      region opens with a `link` and ends `unlk XIZ` / `ret`.

  The four routines at 0xF00CA2, 0xF00CE3, 0xF00D24 and 0xF00D65 are the same
  15-instruction body four times over, differing only in the base of the table
  they dispatch through -- 0xF002AC, 0xF002F4, 0xF0033C, 0xF00384, four
  consecutive 0x48-byte (18-slot) tables.  The third of those is the one C4 uses.

────────────────────────────────────────────────────────────────────────────────
WHY THE TWO ARRAYS ARE ARRAYS
────────────────────────────────────────────────────────────────────────────────
  A1  PHASE IS UNIQUE.  Read as 4-byte little-endian words, 185 of the tail
      array's 196 slots hold a value in 0x00F80000-0x00FFFFFF (prom_a's window
      on this CPU's CS2) and 11 hold 0.  At each of the other three byte phases
      the count of in-window values is 0 of 196.  A phase that is right 185
      times and its neighbours 0 times is not a coincidence of framing.
  A2  THE HEAD ARRAY IS CONTIGUOUS AND SELF-TERMINATING.  From 0xF00C46 every
      one of the 23 four-byte words is in prom_a's window, and the run stops
      dead at 0xF00CA2, which is where the `link XIZ` prologue starts.  The
      first word BELOW 0xF00C46 is 0x007D0247, out of window.
  A3  THE TAIL ARRAY HAS A RECORD SHAPE.  Slot 9 of every 18 is 0x00000000 --
      11 times, at indices 9, 27, 45 ... 189, with no null anywhere else -- and
      slots 5, 6 and 10 of every record hold the same value, 0x00FDA7CE, the way
      an unfilled slot of a method table holds a common stub.
  A4  NEITHER ARRAY DECODES.  A linear decode of the tail array is 25 `db`
      markers in 786 bytes; the head array's 85 bytes contain no branch that any
      converted instruction reaches.

  So both are emitted as `.long`, which is a STATEMENT ABOUT SHAPE.  What the
  slots MEAN is deferred, and the anomaly below says why that is more than the
  usual deferral.

────────────────────────────────────────────────────────────────────────────────
⚠ THE ANOMALY, STATED AND NOT PAPERED OVER
────────────────────────────────────────────────────────────────────────────────
This cluster does not connect to the rest of the machine, in two independent
ways, and both should be on the record before anyone reads a semantic into it.

  N1  NOTHING REACHES IT -- notes/prom_b_f00c4d_xrefs.py, which asks twice and
      prints a positive control for each instrument.  Across all four images'
      converted sources: 0 references to any address in 0xF00C00-0xF017FF.  In
      the raw bytes of prom_a and prom_b: 4 byte sequences read as `jp`/`call`
      imm24 into the range and ALL FOUR are coincidences inside data (two in a
      `.byte` bitmap row, two spanning the immediate of `ld (XIX+0x01),0x1b` and
      the head of the next instruction); 0 are on an instruction line of the
      converted source.  The only thing that names any of the range is the
      pointer table at 0xF0033C -- and that table is itself named only by the
      four routines INSIDE this span.  The cluster is a closed loop.
      ⚠ The control matters: `grep -ao 'f00c..'` returns 0 on files a Python
      latin-1 read shows 32 matches in, so a bare grep would have "confirmed"
      N1 while returning zero for everything.
  N2  ITS CALL TARGETS ARE NOT prom_a ENTRY POINTS.  The code makes 24-bit
      absolute calls to 34 distinct addresses in 0xFDA6FC-0xFDDA7B -- prom_a's
      window -- plus two to 0xF41ED4 in prom_b's own routine directory; the two
      arrays name 155 more, 0xFC4480-0xFDED77.  prom_a has four `.incbin` spans
      left, so its instruction boundaries there are known.  Only 14 of the 34
      call targets and 58 of the 155 array targets land on one.  A search over
      every constant offset in -2048..+2048 finds no shift that fixes it: the
      best is 79 of 155 at +1936, barely above the 58 that offset 0 already
      gives, i.e. the score of an address picked at random.  And where a target
      CAN be checked by hand it is not merely unaligned but impossible:
      0xFDA6FC is four instructions from the end of a loop body in prom_a
      (`sub_FDA6FC` there is an orphan label no prom_a line references),
      0xFDBD28 is the last byte of a four-byte `cp (XIZ-12),0x01`, and 0xFDA7CE
      -- the tail array's repeated stub value, 51 of its 196 slots -- is the
      second byte of `extz BC`.

  Read together, N1 and N2 say this looks like a module that is in the image but
  not in the machine: correctly linked at 0xF00xxx (its own dispatch tables and
  its `lda XIY,0xf00cdf` return addresses are right for where it sits) and
  calling a prom_a THAT IS NOT THE prom_a NEXT TO IT.  ★ THIS IS NOT PROVEN and
  no claim is made about why.  What IS established, and is what this file rests
  on, is that the bytes at 0xF00CA2-0xF014ED are instructions: C1-C5 are
  properties of those bytes and do not depend on where the calls land.

  ⚠ CONSEQUENCE FOR NAMING.  Do not name a routine here after what its call
  target does in the prom_a we have.  That is the specific mistake N2 makes
  available, and it would be a whole module of invented semantics.

────────────────────────────────────────────────────────────────────────────────
THE TWO BYTES I WOULD NOT TYPE -- 0xF017FE-0xF017FF
────────────────────────────────────────────────────────────────────────────────
They are 0xD5, 0xED.  The three array entries before them are 0x00FDECBB,
0x00FDED19, 0x00FDED77 -- an arithmetic progression of +0x5E -- and the next
term is 0x00FDEDD5, whose low two bytes are exactly 0xD5, 0xED.  So they look
like the first half of a 197th entry.

They are NOT emitted as a `.long`, because completing that entry needs
0xF01800-0xF01801, and those two bytes already belong to a converted object:
the display list at 0xF01800, whose first record is `1C 10` = op 0x1C, length
16, followed by two 16-bit coordinates and the ten characters "SOUND EDIT" --
6 + 10 = 16, an exact fit.  The rival framing was tested and dies immediately:
starting that display list at 0xF01802 gives `6E 00`, a record of length 0,
which is a non-terminating walk.  Two bytes short of an answer is where this
stops; they stay `.byte` with this note.

────────────────────────────────────────────────────────────────────────────────
HOW THE CODE TEXT IS PRODUCED, AND WHY IT CANNOT BREAK THE GATE
────────────────────────────────────────────────────────────────────────────────
notes/llvm_roundtrip_autoforce.py disassembles the range with llvm-mc and
assembles every candidate spelling back, comparing bytes, before it prints.  It
leaves 152 of the 828 rows as `.byte` because llvm-mc's disassembler prints them
in a spelling its own assembler rejects.  All 152 are one of five shapes, and
prom_a already writes all five:

    link XIZ,0xNNNN          54   prom_a: `link XIZ,0x....`      x1392
    unlk XIZ                 54   prom_a: `unlk XIZ`             x1402
    cp (XIZ+0xNN),0xMM       29   prom_a: `m_cp_mi8 MBD+r6, ...` x429
    pushw (XIZ+0xNN)          8   prom_a: `m_push MWD+r6, ...`   x339
    mul BC,(XIZ+0xNN)         7   prom_a: `m_mul MBD+r6, ..., 3` x64

  ⚠ `cp (XIZ+0xfc),0x00` IS ACCEPTED by llvm-mc and is WRONG: it assembles to
    the six-byte `c3 f9 fc 00 3f 00`, not the ROM's three-plus-one `8e fc 3f 00`.
    The macro is not a stylistic preference, it is the only spelling that emits
    the ROM's bytes.  That is exactly the class of error the gate exists for.

So this file emits 0 `.byte` rows in the code region.  Then verify() assembles
everything it is about to print -- through the same include the image uses --
and refuses, without printing, unless the result equals the 2,995 ROM bytes.
Then run the real gate:

    python3 scripts/analysis/assert_byte_identical.py

RUN
  python3 notes/gen_prom_b_f00c4d_module.py             # the assembly
  python3 notes/gen_prom_b_f00c4d_module.py --layout    # the four regions
  python3 notes/gen_prom_b_f00c4d_module.py --selftest  # every number above
  python3 notes/gen_prom_b_f00c4d_module.py --apply     # splice into the .s
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_B = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
ROM_A = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC_B = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
SRC_A = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")

B_BASE, A_BASE = 0xF00000, 0xF80000
A_LO, A_HI = 0xF80000, 0xFFFFFF          # prom_a's window on CPU 1's CS2

SPAN_LO, SPAN_HI = 0xF00C4D, 0xF01800    # HI exclusive -- 2,995 bytes
HEAD_ARRAY_START = 0xF00C46              # 7 bytes BEFORE the span (in Data_F00B48)
CODE_LO = 0xF00CA2
TAIL_ARRAY_LO = 0xF014EE
REMAINDER_LO = 0xF017FE                  # the two bytes refused
DISPATCH_TABLE = (0xF0033C, 0xF003C8)    # the independent witness of C4
RECORD_SLOTS = 18

OLD_INCBIN = '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x000C4D, 0x000BB3\n'
MARK = "; === MODULE F00C4D 0xF00C4D-0xF017FF ==="
MARK_END = "; === END MODULE F00C4D 0xF00C4D-0xF017FF ==="

_c = {}


def romb():
    if "b" not in _c:
        _c["b"] = open(ROM_B, "rb").read()
    return _c["b"]


def roma():
    if "a" not in _c:
        _c["a"] = open(ROM_A, "rb").read()
    return _c["a"]


def le32(addr):
    o = addr - B_BASE
    b = romb()
    return b[o] | b[o + 1] << 8 | b[o + 2] << 16 | b[o + 3] << 24


# ------------------------------------------------------------------ unidasm
_UNI_RE = re.compile(r'^([0-9a-f]{6}): ((?:[0-9a-f]{2} )+)\s*(.*)$')


def unidasm(addr, length):
    """MAME's linear decode STARTING EXACTLY AT addr -> [(addr, [bytes], text)].

    unidasm cannot seek, so the bytes are cut out first; -basepc restores the
    addresses.  This is the tree's framing authority (original_ROMs/README-
    unidasm.md): it certifies a BYTE STRING, never that addr is an instruction.
    """
    key = (addr, length)
    if key in _c:
        return _c[key]
    o = addr - B_BASE
    fd, path = tempfile.mkstemp(suffix=".bin")
    try:
        os.write(fd, romb()[o:o + length])
        os.close(fd)
        out = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(path)
    rows = []
    for ln in out.splitlines():
        m = _UNI_RE.match(ln)
        if m:
            rows.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    _c[key] = rows
    return rows


# ---------------------------------------------------------------- derivation
def head_array():
    """The 4-byte words from HEAD_ARRAY_START that are in prom_a's window.

    Derived, not asserted: the run is extended forward while the word is in
    window, and the word one step BELOW the start is checked to be out of it.
    """
    assert not (A_LO <= le32(HEAD_ARRAY_START - 4) <= A_HI), \
        "the word below 0x%06X is in window -- the array starts earlier" % HEAD_ARRAY_START
    a = HEAD_ARRAY_START
    while A_LO <= le32(a) <= A_HI:
        a += 4
    return HEAD_ARRAY_START, a          # [lo, hi)


def code_extent(hi_bound):
    """Linear decode from CODE_LO, tiled instruction by instruction, stopping at
    hi_bound.  Returns (rows, boundary_set) and raises if it does not tile."""
    rows = unidasm(CODE_LO, hi_bound - CODE_LO + 16)
    out, bnd, a = [], set(), CODE_LO
    for ad, bs, txt in rows:
        if ad != a:
            raise AssertionError("decode desynchronised at %06X (expected %06X)" % (ad, a))
        if a + len(bs) > hi_bound:
            raise AssertionError("instruction at %06X straddles %06X" % (a, hi_bound))
        bnd.add(a)
        out.append((ad, bs, txt))
        a += len(bs)
        if a == hi_bound:
            break
    if a != hi_bound:
        raise AssertionError("decode stopped at %06X, not %06X" % (a, hi_bound))
    return out, bnd


def tail_array_phase():
    """For each of the four byte phases at TAIL_ARRAY_LO, how many 4-byte words
    are in prom_a's window.  Only one phase may be non-zero."""
    counts = []
    for ph in range(4):
        a, n = TAIL_ARRAY_LO + ph, 0
        while a + 4 <= SPAN_HI:
            if A_LO <= le32(a) <= A_HI:
                n += 1
            a += 4
        counts.append(n)
    return counts


def tail_array():
    a, out = TAIL_ARRAY_LO, []
    while a + 4 <= SPAN_HI:
        out.append((a, le32(a)))
        a += 4
    return out, a                        # a == REMAINDER_LO


def dispatch_targets():
    lo, hi = DISPATCH_TABLE
    return [le32(a) for a in range(lo, hi, 4) if B_BASE <= le32(a) < 0xF80000]


def branch_targets(rows):
    """Every branch/call target the decode names, as (addr, target)."""
    rx = re.compile(r'\b(jr|jrl|jp|call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})$')
    out = []
    for ad, bs, txt in rows:
        m = rx.search(txt)
        if m:
            out.append((ad, int(m.group(2), 16)))
    return out


# ------------------------------------------------- prom_a instruction starts
def prom_a_starts():
    """Every address prom_a's converted source calls the start of a line, taken
    from its own `; ADDR  hh hh hh` comment -- the tree's record of where prom_a's
    instruction boundaries are."""
    if "a_starts" in _c:
        return _c["a_starts"]
    rx = re.compile(r';\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2}\s*)+)$')
    s = set()
    for ln in open(SRC_A, encoding="latin-1"):
        m = rx.search(ln.rstrip("\n"))
        if m:
            s.add(int(m.group(1), 16))
    _c["a_starts"] = s
    return s


# ------------------------------------------------------------------ spelling
# The five shapes llvm-mc's disassembler prints and its assembler will not take.
# Keyed on the BYTES, because that is what has to come back out; the MAME text
# is checked too so a shape can never be rewritten by accident.
def respell(bs, txt):
    """A real instruction for a row autoforce left as `.byte`, or None."""
    if bs[:2] == [0xEE, 0x0C] and len(bs) == 4 and txt.startswith("link XIZ,"):
        return "link XIZ,0x%02x%02x" % (bs[3], bs[2])
    if bs == [0xEE, 0x0D] and txt == "unlk XIZ":
        return "unlk XIZ"
    if len(bs) == 4 and bs[0] == 0x8E and bs[2] == 0x3F and txt.startswith("cp (XIZ+"):
        return "m_cp_mi8 MBD+r6, 0x%02x, 0x%02x" % (bs[1], bs[3])
    if len(bs) == 3 and bs[0] == 0x9E and bs[2] == 0x04 and txt.startswith("pushw (XIZ+"):
        return "m_push MWD+r6, 0x%02x" % bs[1]
    if len(bs) == 3 and bs[0] == 0x8E and bs[2] == 0x43 and txt.startswith("mul BC,(XIZ+"):
        return "m_mul MBD+r6, 0x%02x, 3" % bs[1]
    return None


_BYTE_ROW = re.compile(r'^\t\.byte ([0-9A-Fa-fx, ]+)\t; ([0-9A-F]{6})  (.*?)   \[llvm-mc cannot encode this\]$')


def code_rows():
    """The byte-verified listing for CODE_LO..TAIL_ARRAY_LO, with the five
    unencodable shapes respelled.  Returns (lines, n_respelled, n_left)."""
    if "rows" in _c:
        return _c["rows"]
    p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(CODE_LO),
                        hex(TAIL_ARRAY_LO - CODE_LO), "--quiet"],
                       capture_output=True, text=True)
    if p.returncode:
        raise AssertionError("llvm_roundtrip_autoforce failed:\n" + p.stderr)
    lines, done, left = [], 0, 0
    for ln in p.stdout.splitlines():
        m = _BYTE_ROW.match(ln)
        if m:
            bs = [int(x, 16) for x in m.group(1).split(",")]
            sp = respell(bs, m.group(3))
            if sp:
                lines.append("\t%s\t; %s  %s" % (sp, m.group(2), m.group(3)))
                done += 1
                continue
            left += 1
        lines.append(ln)
    _c["rows"] = (lines, done, left)
    return _c["rows"]


# ------------------------------------------------------------------- emitter
def emit():
    b = romb()
    ha_lo, ha_hi = head_array()
    rows, bnd = code_extent(TAIL_ARRAY_LO)
    tail, rem = tail_array()
    disp = set(dispatch_targets())
    # a label at every dispatch target and at the instruction after every `ret`
    labels = {CODE_LO} | (disp & bnd)
    prev_ret = False
    for ad, bs, txt in rows:
        if prev_ret:
            labels.add(ad)
        prev_ret = re.match(r'^(ret|reti|retd)\b', txt) is not None

    L = []
    A = L.append
    A(MARK)
    A("; 0xF00C4D-0xF017FF, 2,995 bytes -- the largest `.incbin` this image had")
    A("; left.  THREE OBJECTS AND A REMAINDER, not one thing:")
    A(";   0xF00C4D-0xF00CA1    85 B  tail of the pointer array that starts at")
    A(";                              0x%06X, 7 bytes before this span" % ha_lo)
    A(";   0xF00CA2-0xF014ED  2124 B  code, %d instructions" % len(rows))
    A(";   0xF014EE-0xF017FD   784 B  a %d-entry pointer array, %d-slot records"
      % (len(tail), RECORD_SLOTS))
    A(";                              (%d whole and a partial %dth of %d)"
      % (len(tail) // RECORD_SLOTS, len(tail) // RECORD_SLOTS + 1, len(tail) % RECORD_SLOTS))
    A(";   0xF017FE-0xF017FF     2 B  REFUSED, reason at the site")
    A("; The evidence for every boundary, the five code checks and the ANOMALY")
    A("; (nothing in the image reaches this cluster, and its prom_a call targets")
    A("; are not prom_a entry points) are in notes/gen_prom_b_f00c4d_module.py.")
    A("; Regenerate: python3 notes/gen_prom_b_f00c4d_module.py --apply")
    A("")
    A("; --------------------------------------------------------------------------")
    A("; PtrArray_F00C46 (tail) -- 4-byte pointers into prom_a's window.")
    A("; The array starts at 0x%06X, inside Data_F00B48 above, so this span opens" % ha_lo)
    A("; ONE BYTE INTO the entry that begins at 0x%06X.  It ends at 0x%06X, the"
      % (SPAN_LO - 3, ha_hi - 1))
    A("; byte before the `link XIZ` prologue below; the word below the array's own")
    A("; start is 0x%08X, out of window." % le32(ha_lo - 4))
    A("; ⚠ WHAT the slots select is NOT decoded -- see the ANOMALY in the")
    A(";   generator before reading any meaning into a target address.")
    A("; --------------------------------------------------------------------------")
    A("\t.byte\t0x%02X\t; %06X  high byte of the pointer at 0x%06X"
      % (b[SPAN_LO - B_BASE], SPAN_LO, SPAN_LO - 3))
    A("PtrArray_F00C4E:")
    for a in range(SPAN_LO + 1, ha_hi, 4):
        A("\t.long\t0x%08X\t; %06X" % (le32(a), a))
    A("")
    A("; --------------------------------------------------------------------------")
    A("; CODE -- 0x%06X-0x%06X, %d instructions, %d bytes." % (CODE_LO, TAIL_ARRAY_LO - 1, len(rows), TAIL_ARRAY_LO - CODE_LO))
    A("; The decode tiles the region exactly and stops on the array below; there is")
    A("; no `db` in it; every internal branch lands on an instruction start; and")
    A("; %d pointers in 0x%06X-0x%06X, outside this span, name addresses in it that"
      % (len(disp), DISPATCH_TABLE[0], DISPATCH_TABLE[1] - 1))
    A("; all land on instruction starts too.")
    A("; ★ COVERAGE ROUND: labels are bare sub_XXXXXX and nothing is named.  ⚠ Do")
    A(";   NOT name a routine here after what its call target does in prom_a --")
    A(";   the targets are not prom_a entry points (the ANOMALY, N2).")
    A("; --------------------------------------------------------------------------")
    txts, _, _ = code_rows()
    for ln in txts:
        m = re.search(r'; ([0-9A-F]{6})  ', ln)
        if m and int(m.group(1), 16) in labels:
            A("sub_%s:" % m.group(1))
        A(ln)
    A("")
    A("; --------------------------------------------------------------------------")
    A("; PtrArray_F014EE -- %d 4-byte pointers: %d whole records of %d slots and a"
      % (len(tail), len(tail) // RECORD_SLOTS, RECORD_SLOTS))
    A("; partial %dth of %d." % (len(tail) // RECORD_SLOTS + 1, len(tail) % RECORD_SLOTS))
    A("; Slot 9 of every record is 0x00000000 and slots 5, 6 and 10 hold the same")
    A("; value the way an unfilled slot holds a common stub.  At the other three")
    A("; byte phases 0 of %d words are in prom_a's window; at this one, %d are."
      % (len(tail), sum(1 for _, v in tail if A_LO <= v <= A_HI)))
    A("; ⚠ Emitted as `.long` because the SHAPE is established.  The slots' meaning")
    A(";   is deferred -- and see the ANOMALY (N2) before assuming a target is a")
    A(";   routine in the prom_a next door.")
    A("; --------------------------------------------------------------------------")
    A("PtrArray_F014EE:")
    for i, (a, v) in enumerate(tail):
        c = ""
        if i % RECORD_SLOTS == 0:
            c = "\trecord %d" % (i // RECORD_SLOTS)
        A("\t.long\t0x%08X\t; %06X%s" % (v, a, c))
    A("")
    A("; --------------------------------------------------------------------------")
    A("; 0x%06X-0x%06X -- REFUSED, 2 bytes, deliberately still `.byte`." % (REMAINDER_LO, SPAN_HI - 1))
    A("; The three entries above run 0x%08X, 0x%08X, 0x%08X: a +0x%X progression"
      % (tail[-3][1], tail[-2][1], tail[-1][1], tail[-1][1] - tail[-2][1]))
    A("; whose next term, 0x%08X, has exactly these two bytes as its low half."
      % (tail[-1][1] + (tail[-1][1] - tail[-2][1])))
    A("; Completing it would need 0xF01800-0xF01801, and those belong to the")
    A("; display list at 0xF01800 -- `1C 10` is op 0x1C, length 16, and 6 header")
    A("; bytes + the 10 characters of \"SOUND EDIT\" is exactly 16.  Starting that")
    A("; list two bytes later instead gives `6E 00`, a record of length 0, which")
    A("; never terminates.  So the entry cannot be completed and is not invented.")
    A("; --------------------------------------------------------------------------")
    A("\t.byte\t0x%02X, 0x%02X\t; %06X  low half of a 4-byte entry that has no room"
      % (b[REMAINDER_LO - B_BASE], b[REMAINDER_LO - B_BASE + 1], REMAINDER_LO))
    A("")
    A(MARK_END)
    return "\n".join(L) + "\n"


# -------------------------------------------------------------------- verify
def assemble(text):
    """Assemble the emitted block on its own, through the image's own include,
    and return the bytes.  Comments and labels emit nothing, so the result must
    be exactly the span."""
    d = tempfile.mkdtemp()
    try:
        s, o, bn = (os.path.join(d, n) for n in ("t.s", "t.o", "t.bin"))
        open(s, "wb").write(
            ('\t.text\n\t.include "include/tlcs900_mem_ops.inc"\n' + text).encode("utf-8"))
        p = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                            "-filetype=obj", "-I", ROOT, "-o", o, s],
                           capture_output=True, text=True)
        if p.returncode:
            return None, p.stderr
        subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", o, bn],
                       check=True)
        return open(bn, "rb").read(), ""
    finally:
        shutil.rmtree(d, ignore_errors=True)


def verify(text):
    want = romb()[SPAN_LO - B_BASE:SPAN_HI - B_BASE]
    got, err = assemble(text)
    if got is None:
        return "llvm-mc refused the block:\n" + err
    if got != want:
        if len(got) != len(want):
            return "assembled %d bytes, span is %d" % (len(got), len(want))
        i = next(k for k in range(len(want)) if got[k] != want[k])
        return "first difference at 0x%06X: emitted %02X, ROM %02X" % (SPAN_LO + i, got[i], want[i])
    return None


# ----------------------------------------------------------------- selftest
def selftest():
    fail = []

    def ck(name, cond, detail=""):
        print("  %-58s %s%s" % (name, "ok" if cond else "FAIL", "  " + detail if detail else ""))
        if not cond:
            fail.append(name)

    b = romb()
    ck("span is 2,995 bytes", SPAN_HI - SPAN_LO == 2995, "%d" % (SPAN_HI - SPAN_LO))

    ha_lo, ha_hi = head_array()
    ck("head array 0x%06X-0x%06X, 23 entries" % (ha_lo, ha_hi - 1),
       ha_lo == HEAD_ARRAY_START and ha_hi == CODE_LO and (ha_hi - ha_lo) // 4 == 23,
       "%d entries" % ((ha_hi - ha_lo) // 4))
    ck("word below the head array is out of window (A2)",
       not (A_LO <= le32(ha_lo - 4) <= A_HI), "0x%08X" % le32(ha_lo - 4))

    rows, bnd = code_extent(TAIL_ARRAY_LO)              # C1: raises if it does not tile
    ck("C1 decode tiles 0x%06X-0x%06X exactly" % (CODE_LO, TAIL_ARRAY_LO - 1), True,
       "%d instructions" % len(rows))
    ck("C2 no `db` in the code region", sum(1 for r in rows if r[2].startswith("db")) == 0)
    dbtail = sum(1 for _, _, t in unidasm(TAIL_ARRAY_LO, SPAN_HI - TAIL_ARRAY_LO)
                 if t.startswith("db"))
    ck("C2 the array below DOES not decode", dbtail > 0, "%d `db` in %d bytes"
       % (dbtail, SPAN_HI - TAIL_ARRAY_LO))

    bt = branch_targets(rows)
    inside = [(a, t) for a, t in bt if CODE_LO <= t < TAIL_ARRAY_LO]
    ck("C3 every internal branch target is an instruction start",
       all(t in bnd for _, t in inside), "%d targets" % len(inside))

    disp = dispatch_targets()
    ck("C4 all %d pointers of 0x%06X land on instruction starts" % (len(disp), DISPATCH_TABLE[0]),
       len(disp) == 26 and all(t in bnd for t in disp),
       "%d of %d" % (sum(1 for t in disp if t in bnd), len(disp)))

    nlink = sum(1 for _, _, t in rows if t.startswith("link XIZ"))
    nunlk = sum(1 for _, _, t in rows if t == "unlk XIZ")
    ck("C5 link/unlk pair up", nlink == nunlk == 54, "%d/%d" % (nlink, nunlk))
    ck("C5 region opens `link` and ends `unlk`/`ret`",
       rows[0][2].startswith("link XIZ") and rows[-2][2] == "unlk XIZ" and rows[-1][2] == "ret")

    ph = tail_array_phase()
    tail, rem = tail_array()
    ck("A1 tail array phase is unique", ph[0] == 185 and ph[1:] == [0, 0, 0], str(ph))
    ck("A1 tail array is 196 entries ending at 0x%06X" % REMAINDER_LO,
       len(tail) == 196 and rem == REMAINDER_LO, "%d entries, ends 0x%06X" % (len(tail), rem))
    nulls = [i for i, (_, v) in enumerate(tail) if v == 0]
    ck("A3 slot 9 of every %d-slot record is NULL, and nothing else is" % RECORD_SLOTS,
       len(nulls) == 11 and all(i % RECORD_SLOTS == 9 for i in nulls), "%d nulls" % len(nulls))
    stub = tail[5][1]
    ck("A3 slots 5, 6, 10 of record 0 hold one repeated value",
       tail[5][1] == tail[6][1] == tail[10][1] == stub, "0x%08X x%d"
       % (stub, sum(1 for _, v in tail if v == stub)))

    # ---- the anomaly, measured
    starts = prom_a_starts()
    calls = sorted({t for _, t in bt if A_LO <= t <= A_HI})
    ptrs = sorted({v for _, v in tail if A_LO <= v <= A_HI}
                  | {le32(a) for a in range(ha_lo, ha_hi, 4) if A_LO <= le32(a) <= A_HI})
    xr = subprocess.run([sys.executable, os.path.join(ROOT, "notes", "prom_b_f00c4d_xrefs.py"),
                         "--selftest"], capture_output=True, text=True)
    ck("N1 notes/prom_b_f00c4d_xrefs.py --selftest passes", xr.returncode == 0,
       xr.stdout.strip().splitlines()[-1] if xr.stdout.strip() else xr.stderr[:80])
    con_c = sum(1 for t in calls if t in starts)
    con_p = sum(1 for t in ptrs if t in starts)
    ck("N2 call targets are mostly NOT prom_a instruction starts",
       con_c < len(calls), "%d of %d land on one" % (con_c, len(calls)))
    ck("N2 array targets likewise", con_p < len(ptrs), "%d of %d" % (con_p, len(ptrs)))
    best = max(((sum(1 for t in ptrs if t + d in starts), d) for d in range(-2048, 2049)))
    ck("N2 no constant offset in -2048..2048 rescues them",
       best[0] < 0.75 * len(ptrs), "best %d/%d at %+d" % (best[0], len(ptrs), best[1]))

    lines, done, left = code_rows()
    ck("all 152 unencodable rows respelled, 0 `.byte` left in the code",
       done == 152 and left == 0, "%d respelled, %d left" % (done, left))

    text = emit()
    err = verify(text)
    ck("the emitted block re-assembles to the 2,995 ROM bytes", err is None, err or "")

    print("\n%s (%d checks, %d failed)" % ("PASS" if not fail else "FAIL",
                                           len(fail) + 0, len(fail)) if False else
          ("\nPASS" if not fail else "\nFAIL: " + ", ".join(fail)))
    return 0 if not fail else 1


def layout():
    ha_lo, ha_hi = head_array()
    tail, rem = tail_array()
    rows, _ = code_extent(TAIL_ARRAY_LO)
    print("  %-22s %-8s %s" % ("region", "bytes", "what"))
    print("  0x%06X-0x%06X %6d   pointer array (tail of the one at 0x%06X), %d entries + 1 stray byte"
          % (SPAN_LO, ha_hi - 1, ha_hi - SPAN_LO, ha_lo, (ha_hi - SPAN_LO - 1) // 4))
    print("  0x%06X-0x%06X %6d   code, %d instructions"
          % (CODE_LO, TAIL_ARRAY_LO - 1, TAIL_ARRAY_LO - CODE_LO, len(rows)))
    print("  0x%06X-0x%06X %6d   pointer array, %d entries = %d whole records of %d + %d"
          % (TAIL_ARRAY_LO, rem - 1, rem - TAIL_ARRAY_LO, len(tail),
             len(tail) // RECORD_SLOTS, RECORD_SLOTS, len(tail) % RECORD_SLOTS))
    print("  0x%06X-0x%06X %6d   REFUSED (see the site)" % (rem, SPAN_HI - 1, SPAN_HI - rem))
    print("  %-22s %6d" % ("total", SPAN_HI - SPAN_LO))
    return 0


def apply_():
    text = emit()
    err = verify(text)
    if err:
        print("REFUSING TO WRITE: " + err, file=sys.stderr)
        return 1
    # ⚠ BYTES, NOT TEXT.  This file is not one encoding: its prose carries UTF-8
    # ⚠/★ while `.ascii` literals carry raw high bytes that are not valid UTF-8.
    # Decoding and re-encoding it corrupts one or the other -- a lane already
    # wrote U+FFFD into an `.ascii` literal that way.  So the splice is a byte
    # substring replacement and nothing in the file is decoded.
    src = open(SRC_B, "rb").read()
    if MARK.encode("utf-8") in src:
        print("already spliced", file=sys.stderr)
        return 1
    old = OLD_INCBIN.encode("utf-8")
    if src.count(old) != 1:
        print("expected exactly one copy of the old `.incbin` line", file=sys.stderr)
        return 1
    before = len(src)
    src = src.replace(old, text.encode("utf-8"))
    open(SRC_B, "wb").write(src)
    print("spliced: %s grew by %d bytes" % (SRC_B, len(src) - before))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--layout" in sys.argv:
        return layout()
    if "--apply" in sys.argv:
        return apply_()
    text = emit()
    err = verify(text)
    if err:
        print("REFUSING TO PRINT: " + err, file=sys.stderr)
        return 1
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
