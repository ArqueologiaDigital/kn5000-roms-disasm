#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF067A6-0xF0C734 -- the SOUND EDIT screen data
block and the two screen modules above it -- and, in a second mode, NAME the
display lists of prom_b from the text they draw.

QUESTION IT ANSWERS
  1. "What is the assembly text for this 24,463-byte `.incbin` span -- the
      largest left in the tree -- in a form the byte gate accepts, with every
      label, header and table entry attached to the right address?"
  2. "Which of prom_b's 672 `DL_<address>` labels can be given a name that says
      what the list DRAWS, derived from the list's own `.ascii` records?"

★ WHY TWO JOBS IN ONE FILE.  Wave 7 round 4 gives each lane exactly one filename
  under notes/ so that two lanes cannot collide on one path.  The second mode is
  the round's headline metric (FRAMED -> CONTENT) and had nowhere else to live.
  The two modes share nothing but the ROM loader; `--dl-names` does not read the
  layout and `--checks` does not read the display lists.

────────────────────────────────────────────────────────────────────────────────
PART 1 -- THE SPAN
────────────────────────────────────────────────────────────────────────────────

WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
  notes/prom_b_f067a6_layout.py, re-derived by build_layout() on EVERY run.
  27 segments; this file refuses to print if the count moves, if the segments
  stop tiling [LO,HI), or if the barrier and the descent conflict.  That layout
  was audited in wave 7 round 1 and its skeptic returned NOT REFUTED -- with
  four corrections, all of which are applied below and reproduced by --selftest.

  ⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT.  The layout grades every
  opcode-anchored `call`/`jp` site by `site_status()`, which asks whether the
  site is inside an `.incbin` (UNCONVERTED) or is a proven instruction start.
  Once this span is spliced, every site inside it flips from UNCONVERTED to
  INSN/CONVERTED and the FARSITE seed set changes.  freeze() therefore masks
  the span out of `instr_starts("b")` and puts it back into `incbin_ranges("b")`
  before build() runs, so the derivation answers the question it answered before
  the splice.  Without that guard this file would stop reproducing its own
  output the moment it succeeded, which is the trap
  notes/gen_prom_a_fa5aeb_module.py documents for prom_a.

THE FOUR ROUND-1 CORRECTIONS, APPLIED (each is a check in --selftest)
  C1  NINE of the eleven data objects have a located reader, not eleven.
      0xF08134 and 0xF08334 have none.  ⚠ AND THE SKEPTIC'S OWN SENTENCE NEEDS
      ONE WORD OF REPAIR: it said "neither base has any 32-bit spelling in
      either image", which is exact for 0xF08134 (zero hits) but not for
      0xF08334 -- that address IS spelled once, as entry [0] of the directory
      0xF08134 that points at it.  A directory naming its own pool is not a
      reader; --selftest asserts both facts separately so the distinction
      cannot be lost again.  Both objects keep a FRAMED name and a stated gap.
  C2  TWENTY-TWO display-list call sites lie below the first code segment's end
      (0xF0980D-0xF09AC2), not 24.  Sites 22..35 are in the SECOND code segment
      at 0xF09BA0-0xF09D69.  22 + 14 = 36.
  C3  0xF09E85-0xF09FFB holds THIRTEEN `link XIZ` routines, not twelve, at
      0xF09EB3 ED7 EEF F0F F24 F39 F4E F63 F78 F8D FA2 FC0 FE4, plus a 15-byte
      push/pop/ret stub at 0xF09E85, one routine at 0xF09E94 whose `link` is
      outside the region, and a bodyless `link` at 0xF09FFC.
  C4  The 160x3 array at 0xF08334 was quoted on a frame SHIFTED BY 2.  On the
      proven frame (all 128 pointers 3-byte aligned, entry[127]+3 = 0xF08514)
      it reads 00 00 10 / 02 00 18 / 00 00 ff ... and ends 7b 01 ff / 7d 03 ff /
      7b 02 ff, and 128 of the 160 records end in 0xFF -- exactly the number of
      pointers.
  ALSO: T_F41F54-T_F421A8 is a 150-slot SHARED table of which only 5 slots are
  unconverted here.  It is not described as this span's.

WHERE THE NAMES COME FROM -- AND WHERE THEY DELIBERATELY DO NOT
  ⚠ The byte gate is blind to every name below.  Four derivations carry them:

  * THE SCALE TABLE.  0xF06800 is 15 rows of 12 bytes centred on 0x80, read at
    prom_a 0xFC0D84 by a loop that runs exactly 12 times, selected by the byte
    (0x78A2), with a 12-byte USER twin in RAM at 0x78A4 (prom_a 0xFC0DB4).
    prom_b 0xF05286 holds FIFTEEN 8-character names -- OFF RANDOM PIANO
    ORCHESTR PHYTHAGO WERCKMEI KIRNBERG ARABIC1..5 SLENDRO PELOG USER -- and the
    rows agree with them one for one: rows 0-3 (OFF/RANDOM/PIANO/ORCHESTR) are
    flat 0x80, rows 4-6 (the three historical temperaments) vary, rows 7-11
    (ARABIC 1-5) carry 0x40 quarter-tone cells, rows 12-13 (SLENDRO/PELOG) vary
    heavily and row 14 (USER) is flat.  --selftest asserts the flat/varied
    pattern row by row INCLUDING THE LAST.  Name: ScaleTuningOffsets.
  * THE GROUP NAME TABLE.  0xF068B4 is 96 rows of 16 printable bytes reading
    PIANO, E.PIANO, ... SYNTH PAD 3, DRUMS 1/2, then 'U1 Combi Group 1'..16 and
    'R1 Combi Group 1'..16, with '----------------' for the rest.  Read at
    prom_a 0xFC2070 by four arms whose bases are row 0, 16, 32 and 48.
    Name: ToneGroupNames.
  * THE THREE MAX-MEMBER MAPS.  0xF06EB4/EC4/ED4 are picked by the SAME `W`
    ranges that pick the three name-table bases, in the parallel selector
    sub_FC2222 (prom_a 0xFC2222-0xFC2281): W in 0x20..0x27 -> name base
    0xF06AB4 and map 0xF06EC4; W in 0x29..0x2F -> base 0xF06BB4 and map
    0xF06ED4; otherwise base 0xF068B4 and map 0xF06EB4.  And the map value is
    0xFF at EXACTLY the rows whose name is '----------------' -- 14 of 16 for
    0xF06EC4 and 15 of 16 for 0xF06ED4, asserted cell by cell by --selftest.
    The member index is masked `and C,0x07` at prom_a 0xFC246F.
    Names: GroupMaxMemberIndex_*.  ⚠ That 0x07 means "eight members" is NOT
    asserted; the header says so.
  * THE THREE (GROUP, MEMBER) TABLES.  0xF06EF4, 0xF07134 and 0xF08514 are read
    by three different arms of the same prom_a module with the same index shape
    -- row = a group byte, column = a member 0..7, result a 16-bit code stored
    to (0x60F014)/(0x60F015) -- and they differ only in how wide the row index
    is.  ⚠ THEY ARE NOT INVERSES OF EACH OTHER: feeding 0xF07134's output back
    through 0xF08514 round-trips 1 pair of 2048 on either orientation, and
    --selftest pins that refutation so a later round does not re-invent it.
    Names: SoundCodeByGroupMember_{ModeOffsetGroup,ByteGroup,SevenBitGroup}.
  * THE SCREEN MODULES.  Nine of the span's entry points are entries [26], [27],
    [29], [45] and [0] of the two PARALLEL 48-entry selector tables
    DispatchTable_F5B8F8 (bracketed) and DispatchTable_F5B9F8.  The routines in
    the first table run a page's WHOLE display-list set unconditionally; the
    routines at the SAME INDEX in the second start `cp A,<n>` and repaint one
    field.  The lists they run carry their own text: 'C0NTR0LLER'/'SOUND EDIT'
    with 'PAGE1/2' and 'PAGE2/2', 'DIGITAL EFFECT'/'SOUND EDIT', and
    'COPY'/'SOUND EDIT'/'FROM'/'TO'.  Names: SoundEditController_*,
    SoundEditDigitalEffect_*, SoundEditCopy_*.

  EVERYTHING ELSE STAYS sub_XXXXXX WITH THE GAP STATED.  That is 144 of the 154
  code labels and both unread data objects (--selftest pins all three counts).
  The 9,733 bytes of code from 0xF0A000 up, in eight segments, are reached from
  prom_a's two computed-call tables (0xFCF21B[91..159] and 0xFCF80C[224..303])
  and nothing decoded here says what those indices enumerate, so nothing there
  is named.

NOTHING HERE CAN BREAK THE GATE
  Code comes from notes/llvm_roundtrip_autoforce.py, which assembles and byte-
  compares every candidate spelling before returning it.  Data is printed from
  the ROM.  Then verify_region() assembles the WHOLE emitted text with llvm-mc
  and compares all 24,463 bytes with the ROM, and main() exits non-zero WITHOUT
  PRINTING if it differs.

────────────────────────────────────────────────────────────────────────────────
PART 2 -- `--dl-names`: FRAMED -> CONTENT for prom_b's display lists
────────────────────────────────────────────────────────────────────────────────

  prom_b carries 672 labels of the form DL_<six hex digits>.  The address in the
  name is the only thing distinguishing them, so notes/wave7_documentation_metrics.py
  grades every one of them FRAMED: the object is delimited and typed and nobody
  has said what it is FOR.  But a display list's purpose is WRITTEN INSIDE IT --
  its text records carry the literal words the list puts on the screen.

  `--dl-names` reads prom_b/wsa1_prom_b.s, collects the `.ascii` literals of each
  DL_<addr> label up to the next label, and proposes DL_<CamelCase of the first
  literals>.  A proposal is taken ONLY if the resulting name is unique across the
  whole file; a colliding one (nine lists whose only text is 'OK') keeps its
  address.  `--dl-names --apply` rewrites the label, every reference to it, and
  inserts an `Evidence:` line quoting the literals.

  ⚠ WHAT THIS DOES AND DOES NOT CLAIM.  It claims the list DRAWS those words --
  which is what the records say and nothing more.  It does not claim to know the
  screen's function, and it does not touch a list with no text.  The ROM writes
  the digit 0 for the letter O in its large titles ('C0NTR0LLER', 'M0DELING'),
  and the names keep that spelling rather than silently correcting the ROM.

RUN
  python3 notes/gen_prom_b_f067a6_module.py             # the assembly
  python3 notes/gen_prom_b_f067a6_module.py --layout    # the segment table
  python3 notes/gen_prom_b_f067a6_module.py --checks    # REFUSES to emit on fail
  python3 notes/gen_prom_b_f067a6_module.py --names     # the naming census
  python3 notes/gen_prom_b_f067a6_module.py --selftest  # every quoted number
  python3 notes/gen_prom_b_f067a6_module.py --splice     # write it into the .s;
                                                         # idempotent -- it can
                                                         # replace its own output
  python3 notes/gen_prom_b_f067a6_module.py --dl-names  # PART 2, dry run
  python3 notes/gen_prom_b_f067a6_module.py --dl-names --apply
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF067A6, 0xF0C735
TBL_LO, TBL_HI = 0xF40000, 0xF44018
EXPECTED = 27

# The layout, as derived by notes/prom_b_f067a6_layout.py and re-derived on every
# emit by build_layout().  A RECORD of a measurement, never a typed guess.
LAYOUT = [
    ("fill",   0xF067A6, 0x005A),
    ("data",   0xF06800, 0x00B4),
    ("ascii",  0xF068B4, 0x0600),
    ("data",   0xF06EB4, 0x1280),
    ("ptrtab", 0xF08134, 0x0200),
    ("data",   0xF08334, 0x09A4),
    ("fill",   0xF08CD8, 0x0B28),
    ("code",   0xF09800, 0x0333),
    ("data",   0xF09B33, 0x0048),
    ("ptrtab", 0xF09B7B, 0x0020),
    ("code",   0xF09B9B, 0x02EA),
    ("data",   0xF09E85, 0x017B),
    ("code",   0xF0A000, 0x0E2F),
    ("ptrtab", 0xF0AE2F, 0x0030),
    ("code",   0xF0AE5F, 0x0097),
    ("ptrtab", 0xF0AEF6, 0x0030),
    ("code",   0xF0AF26, 0x009B),
    ("ptrtab", 0xF0AFC1, 0x0030),
    ("code",   0xF0AFF1, 0x00AA),
    ("ptrtab", 0xF0B09B, 0x0028),
    ("code",   0xF0B0C3, 0x0094),
    ("ptrtab", 0xF0B157, 0x0018),
    ("code",   0xF0B16F, 0x0113),
    ("ptrtab", 0xF0B282, 0x0030),
    ("code",   0xF0B2B2, 0x008A),
    ("ptrtab", 0xF0B33C, 0x0030),
    ("code",   0xF0B36C, 0x13C9),
]

DATA_KINDS = ("data", "ascii", "ptrtab")

# Object boundaries INSIDE the `data` segments, from the layout script's
# DATA_READERS/ISLAND_READERS.  Each is (start, name, kind).  A name that is
# `None` means the object keeps a FRAMED name and a stated gap.
OBJECTS = [
    (0xF06800, "ScaleTuningOffsets", "scale"),
    (0xF068B4, "ToneGroupNames", "names"),
    (0xF06EB4, "GroupMaxMemberIndex_ToneGroups", "maxmember"),
    (0xF06EC4, "GroupMaxMemberIndex_DrumGroups", "maxmember"),
    (0xF06ED4, "GroupMaxMemberIndex_DrumGroupsSecondWindow", "maxmember"),
    (0xF06EE4, "GroupMaxMemberIndex_ToneGroupsCopy", "maxmember"),
    (0xF06EF4, "SoundCodeByGroupMember_ModeOffsetGroup", "gm"),
    (0xF07134, "SoundCodeByGroupMember_ByteGroup", "gm"),
    (0xF08134, None, "ptrdir"),
    (0xF08334, None, "reclists"),
    (0xF08514, "SoundCodeByGroupMember_SevenBitGroup", "gm"),
    (0xF09B33, None, "island"),
    (0xF09B3B, None, "island"),
    (0xF09B7B, None, "island"),
    (0xF09E85, None, "linkisland"),
]

# The nine parallel-dispatch entry points and the two module helpers that a
# derivation names.  Every other label in the span is sub_XXXXXX.
CODE_NAMES = {
    0xF09800: "SoundEditController_PaintPage1",
    0xF0985C: "SoundEditController_PaintPage2",
    0xF098B8: "SoundEditController_PaintHeader",
    0xF098FB: "SoundEditController_RepaintFieldPage1",
    0xF09961: "SoundEditController_RepaintFieldPage2",
    0xF099F5: "SoundEditDigitalEffect_Paint",
    0xF09AA5: "SoundEditDigitalEffect_RepaintField",
    0xF09AE1: "RunDisplayListBFromPointerArray",
    0xF09B9B: "SoundEditCopy_Paint",
    0xF09C08: "SoundEditCopy_RepaintField",
}

FRAMED_PREFIX = {"data": "Data", "ascii": "Text", "ptrtab": "PtrTable"}
# The objects that stay FRAMED -- a KIND plus an ADDRESS -- because nothing
# decoded in either image says what they are FOR.  Naming them anything else
# would be a plausible guess, and this tree has paid for those.
FRAMED_NAMES = {
    0xF08134: "PtrTable_F08134",
    0xF08334: "RecordArray_F08334",
    0xF09B33: "WordTable_F09B33",
    0xF09B3B: "IndexMap_F09B3B",
    0xF09B7B: "PtrTable_F09B7B",
    0xF09E85: "Unclaimed_F09E85",
}

_cache = {}
FAIL = []


# --------------------------------------------------------------------- ROM
def rom(which="b"):
    if which not in _cache:
        _cache[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _cache[which]


def at(addr, n=1, img="b"):
    base = B_BASE if img == "b" else A_BASE
    return rom(img)[addr - base: addr - base + n]


def w16(a):
    return int.from_bytes(at(a, 2), "little")


def w32(a):
    return int.from_bytes(at(a, 4), "little")


# ------------------------------------------------- the layout, re-derived
def freeze(L):
    """Make the layout module answer as it did BEFORE this span was spliced.

    Two of its inputs are the .s itself: the set of proven instruction starts
    and the set of `.incbin` ranges.  After the splice both change INSIDE the
    span, `site_status()` stops calling the span UNCONVERTED, and the FARSITE
    seed set moves.  Masking the span out of one and back into the other makes
    build() reproduce its pre-splice answer, so this file keeps reproducing its
    own output.  (`proven_call_sites` already drops sites inside [lo,hi) itself
    -- prom_b_f0ea9f_layout.py:299 -- so it needs no help.)"""
    raw_starts, raw_incbin = L.instr_starts, L.incbin_ranges

    def starts(img):
        s = raw_starts(img)
        return set(x for x in s if not (img == "b" and LO <= x < HI)) if img == "b" else s

    def incbin(img):
        r = [(a, e) for a, e in raw_incbin(img) if not (img == "b" and a >= LO and e <= HI)]
        if img == "b" and not any(a <= LO and e >= HI for a, e in r):
            r = sorted(r + [(LO, HI)])
        return r

    L.instr_starts, L.incbin_ranges = starts, incbin


def build_layout():
    if "layout" in _cache:
        return _cache["layout"]
    import prom_b_f067a6_layout as L                                # noqa: E402
    freeze(L)
    segs, conflicts, pend, ok, seen = L.build()
    _cache["layout"] = (segs, conflicts, L)
    return _cache["layout"]


# ------------------------------------------------------------ transcription
def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        out = subprocess.run(
            [sys.executable, AUTOFORCE, "b", hex(start), hex(length), "--quiet"],
            capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, out.stderr))
        _cache[key] = out.stdout.rstrip("\n").split("\n")
    return _cache[key]


def code_lines():
    if "cl" not in _cache:
        out = []
        for kind, s, n in LAYOUT:
            if kind == "code":
                for ln in transcribe(s, n):
                    m = re.search(r";\s*([0-9A-F]{6})\s", ln)
                    out.append((int(m.group(1), 16), ln))
        _cache["cl"] = out
    return _cache["cl"]


def mame_text(a):
    for ad, ln in code_lines():
        if ad == a:
            t = ln.split(";", 1)[1].strip()
            return t[7:].strip()
    return ""


def boundaries():
    return {a for a, _ in code_lines()}


# -------------------------------------------------------------- entry points
def thunks():
    """{target: [slot, ...]} for `jp addr24` slots of the 0xF40000 table."""
    if "th" in _cache:
        return _cache["th"]
    d, out = rom("b"), {}
    for a in range(TBL_LO, TBL_HI, 4):
        if at(a, 1)[0] == 0x1B:
            t = w32(a) >> 8
            if LO <= t < HI:
                out.setdefault(t, []).append(a)
    _cache["th"] = out
    return out


def slot_refs():
    """Opcode-anchored UPPER BOUND on references to each thunk SLOT address."""
    if "sr" in _cache:
        return _cache["sr"]
    cnt = {}
    for blob, base in ((rom("a"), A_BASE), (rom("b"), B_BASE)):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if TBL_LO <= t < TBL_HI and t % 4 == 0:
                    cnt[t] = cnt.get(t, 0) + 1
    _cache["sr"] = cnt
    return cnt


EXT_TABLES = [("a", 0xFCF21B, 377, 0xFD277E), ("a", 0xFCF80C, 305, 0xFD0AD2),
              ("b", 0xF5B8F8, 48, 0xF5B8D7), ("b", 0xF5B9F8, 48, 0xF5B9DC),
              ("b", 0xF0AE2F, 12, 0xF0AE25), ("b", 0xF0AEF6, 12, 0xF0AEEC),
              ("b", 0xF0AFC1, 12, 0xF0AFB7), ("b", 0xF0B09B, 10, 0xF0B091),
              ("b", 0xF0B157, 6, 0xF0B14D), ("b", 0xF0B282, 12, 0xF0B278),
              ("b", 0xF0B33C, 12, 0xF0B332)]


def ext_entries():
    """{target: [(table, index), ...]} over the eleven TRANSFER tables that name
    an entry point inside the span.  The tables and their indexers are the ones
    notes/prom_b_f067a6_layout.py --tables derives; this function re-reads their
    words from the ROM rather than trusting the list."""
    if "ee" in _cache:
        return _cache["ee"]
    out = {}
    for img, base, n, _ix in EXT_TABLES:
        for i in range(n):
            a = base + 4 * i
            v = int.from_bytes(at(a, 4, img), "little")
            if LO <= v < HI:
                out.setdefault(v, []).append((base, i))
    _cache["ee"] = out
    return out


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own comments."""
    if "ic" in _cache:
        return _cache["ic"]
    out = {}
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr|jp)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(2), 16)
            if LO <= t < HI:
                out.setdefault(t, []).append(a)
    _cache["ic"] = out
    return out


def dl_sites():
    """[(site, start, end, interpreter)] for every `ld XIY,s / ld XIX,e / call
    0xF417F0|F4` triple in the TRANSCRIPTION -- proven instruction text, not a
    byte scan.  The site is the address of the `ld XIY`, i.e. the first opcode."""
    if "dl" in _cache:
        return _cache["dl"]
    lines = code_lines()
    txt = {a: mame_text(a) for a, _ in lines}
    order = [a for a, _ in lines]
    out = []
    for i, a in enumerate(order[:-2]):
        m1 = re.match(r"ld XIY,0x00([0-9a-f]{6})$", txt[a])
        if not m1:
            continue
        m2 = re.match(r"ld XIX,0x00([0-9a-f]{6})$", txt[order[i + 1]])
        m3 = re.match(r"call 0x(f417f[04])$", txt[order[i + 2]])
        if m2 and m3:
            out.append((a, int(m1.group(1), 16), int(m2.group(1), 16),
                        int(m3.group(1), 16)))
    _cache["dl"] = out
    return out


def dl_text(start, end):
    """The TEXT a display list draws: printable runs of >= 3 bytes that contain
    two adjacent letters.

    ⚠ The letter test is not cosmetic.  Without it a run like ` "0` -- three
    printable bytes that are really a coordinate and an opcode -- is quoted in a
    header as if it were something the list writes on the screen, and a header
    that presents noise as text is exactly the class of error round 3's
    reviewers found.  Every literal quoted by a `Draws:` line passes it."""
    img = "b" if 0xF00000 <= start < 0xF80000 else "a"
    d, out, cur = at(start, end - start, img), [], b""
    for ch in d:
        if 32 <= ch < 127:
            cur += bytes([ch])
        else:
            if len(cur) >= 3 and re.search(rb"[A-Za-z]{2}", cur):
                out.append(cur.decode())
            cur = b""
    if len(cur) >= 3 and re.search(rb"[A-Za-z]{2}", cur):
        out.append(cur.decode())
    return out


# ------------------------------------------------------------------- labels
def labels():
    if "lab" in _cache:
        return _cache["lab"]
    got = {}
    for t in thunks():
        got[t] = None
    for t in ext_entries():
        got[t] = None
    for t in internal_calls():
        got[t] = None
    b = boundaries()
    obj = {a for a, _n, _k in OBJECTS}
    for a in list(got):
        if a not in b:
            del got[a]
    for a, name, _kind in OBJECTS:
        got[a] = name
    for a in got:
        if got[a] is not None:
            continue
        if a in CODE_NAMES:
            got[a] = CODE_NAMES[a]
        elif a in obj:
            kind = seg_of(a)[0]
            got[a] = FRAMED_NAMES.get(a, "%s_%06X" % (FRAMED_PREFIX.get(kind, "Data"), a))
        else:
            got[a] = "sub_%06X" % a
    for a, name, _k in OBJECTS:
        if got[a] is None:
            kind = seg_of(a)[0]
            got[a] = FRAMED_NAMES.get(a, "%s_%06X" % (FRAMED_PREFIX.get(kind, "Data"), a))
    for kind, s, n in LAYOUT:
        if kind in DATA_KINDS and s not in got:
            got[s] = "%s_%06X" % (FRAMED_PREFIX[kind], s)
    _cache["lab"] = got
    return got


def seg_of(a):
    for kind, s, n in LAYOUT:
        if s <= a < s + n:
            return kind, s, n
    return None, None, None


def obj_end(a):
    """The end of the OBJECT starting at a: the next object start, or the end of
    the segment it lives in.  Derived, never asserted."""
    kind, s, n = seg_of(a)
    nxt = [x for x, _n, _k in OBJECTS if s <= x < s + n and x > a]
    return min(nxt) if nxt else s + n


# ------------------------------------------------------------------ headers
def wrap(prefix, text, width=78):
    body = textwrap.wrap(text, width - len(prefix)) or [""]
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def touched(lo, hi):
    small, big = {}, {}
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        t = ln.split(";", 1)[1] if ";" in ln else ""
        for m in re.findall(r"\(0x([0-9a-f]{4})\)", t):
            small[int(m, 16)] = small.get(int(m, 16), 0) + 1
        for m in re.findall(r"0x00([0-9a-f]{6})", t):
            v = int(m, 16)
            if not (LO <= v < HI) and v >= 0x600000:
                big[v] = big.get(v, 0) + 1
    return small, big


def calls_out(lo, hi, lab):
    out = []
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r";\s*[0-9A-F]{6}\s+(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(1), 16)
            x = lab.get(t) or ("T_%06X" % t if TBL_LO <= t < TBL_HI else "0x%06X" % t)
            if x not in out:
                out.append(x)
    return out


NAMED_WHY = {
    0xF09800: ("entry [45] of DispatchTable_F5B8F8, the BRACKETED selector table. "
               "It calls SoundEditController_PaintHeader (which draws the list at "
               "0xF32C2A, text 'C0NTR0LLER' and 'SOUND EDIT') and then runs the "
               "list at 0xF32D2C, whose own text is 'PAGE1/2'."),
    0xF0985C: ("entry [27] of DispatchTable_F5B8F8.  Same header call, then the "
               "list at 0xF32E71, text 'PAGE2/2', 'AFTER TOUCH', 'CTRL PEDAL'."),
    0xF098B8: ("called by both CONTROLLER page painters and by nothing else in "
               "the transcription.  It runs the list at 0xF32C2A, whose text is "
               "'C0NTR0LLER' and 'SOUND EDIT' -- the page header -- choosing "
               "between two end bounds on (0x27F5)."),
    0xF098FB: ("entry [45] of DispatchTable_F5B9F8, the table PARALLEL to "
               "0xF5B8F8: same index, same screen.  It starts `cp A,0 / cp A,0x0E "
               "/ cp A,0x0C` and repaints a SUBSET of the page's lists, where the "
               "[45] routine of the first table repaints all of them."),
    0xF09961: ("entry [27] of DispatchTable_F5B9F8 -- the parallel of the PAGE2/2 "
               "painter -- and it likewise starts `cp A,0 / cp A,0x32 / cp A,0x0C`."),
    0xF099F5: ("entry [26] of DispatchTable_F5B8F8.  It runs the prom_a list at "
               "0xFC40F0 (or 0xFC410F when (0x27B6) == 0x0A), whose text is "
               "'DIGITAL EFFECT', 'SOUND EDIT', 'INTENSITY', 'TYPE', "
               "'REVERB DEPTH  :', and then indexes two arrays of list bounds at "
               "prom_a 0xFC4532 and 0xFC47FF by the same (0x27B6)."),
    0xF09AA5: ("entry [26] of DispatchTable_F5B9F8 -- the parallel slot of the "
               "DIGITAL EFFECT painter -- and it starts `cp A,0 / cp A,7`, the "
               "per-field shape."),
    0xF09AE1: ("`extz XWA / xor W,W / sla 2,WA / add XIY,XWA / ld XIY,(XIY) / "
               "call 0xF41830`: XIY is an array of 32-bit display-list pointers, "
               "A is the index, and 0xF41830 is thunk slot T_F41830, which holds "
               "`jp DisplayListB_RunOne`.  The name states exactly that."),
    0xF09B9B: ("entry [29] of DispatchTable_F5B8F8.  It runs the prom_a lists at "
               "0xFC4BA7, 0xFC4D77, 0xFC4DEB and 0xFC4E54, whose text is 'COPY', "
               "'SOUND EDIT', 'FROM', 'TO  ', 'TONE:  ', 'BANK:  ', "
               "'DRUM KIT:  ' and '1st TONE  '.."),
    0xF09C08: ("entry [29] of DispatchTable_F5B9F8, the parallel slot of the COPY "
               "painter."),
}


def code_header(a, end, lab, th, sr, ic, ee):
    L = ["; " + "-" * 74, "; %s" % lab[a]]
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    if a in ee:
        parts.append("table " + ", ".join("0x%06X[%d]" % t for t in ee[a][:6]) +
                     (" +%d more" % (len(ee[a]) - 6) if len(ee[a]) > 6 else ""))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    L += wrap("; Called from: ", "; ".join(parts) if parts else
              "no thunk slot, no pointer-table entry and no in-module call or jp "
              "site -- reached only by a branch from the routine above, or by a "
              "computed transfer this census does not see")
    sm, bg = touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sorted(sm)[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in sorted(bg)[:6]) + \
              (" +%d more" % (len(bg) - 6) if len(bg) > 6 else "")
    L += wrap("; Touches: ", tt or "nothing with an absolute address")
    co = calls_out(a, end, lab)
    if co:
        L += wrap("; Calls:   ", " ".join(co[:12]) +
                  (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    ds = [d for d in dl_sites() if a <= d[0] < end]
    if ds:
        seen, shown = set(), []
        for site, s_, e_, _i in ds:
            t = " / ".join(dl_text(s_, e_))[:60]
            key = (s_, e_)
            if key in seen:
                continue
            seen.add(key)
            shown.append("0x%06X-0x%06X%s" % (s_, e_, (" \"%s\"" % t) if t else ""))
        # ⚠ The quoted strings are the PRINTABLE RUNS of the list's bytes, not a
        # decode of its text records: most of these lists live in prom_a and are
        # still `.incbin`, so nothing has framed their records.  A run can
        # therefore carry one adjacent coordinate byte ("g DEPTH" is the record
        # `06 09 / .short 0x2067 / "DEPTH"`).  The header says "printable runs"
        # rather than "text" for exactly that reason.  ⚠ And the COUNT of sites
        # and the number of listed ranges are stated separately, because two
        # sites often run the SAME list and a single number would contradict
        # the list under it.
        L += wrap("; Draws:   ", "%d display-list call site%s naming %d distinct "
                  "list%s; their printable runs: %s"
                  % (len(ds), "" if len(ds) == 1 else "s", len(shown),
                     "" if len(shown) == 1 else "s", "; ".join(shown[:5]) +
                     (" +%d more list(s)" % (len(shown) - 5) if len(shown) > 5 else "")))
    if a in NAMED_WHY:
        L += wrap("; Evidence: ", NAMED_WHY[a])
    elif a in th:
        L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`, and "
                  "0x%06X is an instruction boundary of this transcription "
                  "(re-asserted on every emit).  That is ALL the name rests on."
                  % (th[a][0], a, a))
    elif a in ee:
        b_, i_ = ee[a][0]
        L += wrap("; Evidence: ", "word [%d] of the pointer table at 0x%06X reads "
                  "0x00%06X, that table's reader TRANSFERS to the word it loads, "
                  "and 0x%06X is an instruction boundary of this transcription."
                  % (i_, b_, a, a))
    else:
        L += wrap("; Evidence: ", "reached by a `call`/`calr`/`jp` decoded in this "
                  "transcription (the sites are listed above), so 0x%06X is an "
                  "instruction boundary." % a)
    if a not in NAMED_WHY:
        L += wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX "
                  "with the gap stated, per this tree's rule that a stated gap "
                  "beats a plausible guess.")
    L.append("; " + "-" * 74)
    return L


# ------------------------------------------------------------- data printing
def byte_rows(a, n, per=16, note=""):
    out = []
    for off in range(0, n, per):
        k = min(per, n - off)
        blk = at(a + off, k)
        txt = "".join(chr(x) if 32 <= x < 127 else "." for x in blk)
        out.append("\t.byte\t%s\t; %06X  |%s|%s"
                   % (", ".join("0x%02X" % x for x in blk), a + off, txt, note))
    return out


SCALE_NAMES = ["OFF", "RANDOM", "PIANO", "ORCHESTR", "PHYTHAGO", "WERCKMEI",
               "KIRNBERG", "ARABIC1", "ARABIC2", "ARABIC3", "ARABIC4", "ARABIC5",
               "SLENDRO", "PELOG", "USER"]
SCALE_NAME_TABLE = 0xF05286


def data_object(a, end, lab, kind):
    """One data object, with a header that states its derivation."""
    n, name = end - a, lab[a]
    out = ["; " + "-" * 74]
    if kind == "scale":
        rows = [list(at(a + 12 * i, 12)) for i in range(n // 12)]
        varied = [i for i, r in enumerate(rows) if set(r) != {0x80}]
        out += wrap("; %s -- " % name,
                    "%d rows of 12 bytes, one row per SCALE (temperament) and one "
                    "byte per semitone, 0x80 = no offset.  Rows %s are flat 0x80; "
                    "the other %d vary.  A twelve-byte USER copy lives in RAM at "
                    "0x78A4 and is read by the same loop."
                    % (len(rows), ",".join(str(i) for i in range(len(rows))
                                           if i not in varied), len(varied)))
        out += wrap("; Read by: ", "prom_a 0xFC0D78-0xFC0D9D -- `ld W,0x0C / "
                    "mul8rr A,W / ld XHL,0x00F06800 / add XHL,XWA`, then a loop "
                    "bounded by `cp A,0x0C` that visits all twelve bytes.  The row "
                    "index is the byte (0x78A2) mapped through 0xF43420; the "
                    "special values 0x40/0x41/0x42 select row 0 and a separate arm "
                    "at prom_a 0xFC0DAF reads the RAM copy at 0x78A4 instead.")
        out += wrap("; Evidence: ", "prom_b 0xF05286 holds FIFTEEN eight-character "
                    "names -- %s -- and this table has exactly fifteen rows.  Rows "
                    "0-3 (OFF, RANDOM, PIANO, ORCHESTR) need no per-semitone "
                    "offset and are flat; rows 4-6 are the three historical "
                    "temperaments and vary; rows 7-11 (ARABIC 1-5) each carry "
                    "0x40 cells, the quarter-tone step those scales need; rows "
                    "12-13 (SLENDRO, PELOG) vary heavily; row 14 (USER) is flat "
                    "because the editable copy is the RAM one.  --selftest asserts "
                    "the flat/varied pattern row by row, the LAST row included."
                    % " ".join(SCALE_NAMES))
        out += wrap("; Unknown: ", "the UNIT of the offset.  0x80 is plainly the "
                    "zero point and 0x40 plainly a large flat step, but no "
                    "cents-per-count constant is decoded here and none is claimed.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, r in enumerate(rows):
            out += byte_rows(a + 12 * i, 12, 12, "  [%d] %s" % (i, SCALE_NAMES[i]))
        return out
    if kind == "names":
        rows = n // 16
        strs = [at(a + 16 * i, 16).decode("latin1") for i in range(rows)]
        dashes = sum(1 for s in strs if set(s) == {"-"})
        out += wrap("; %s -- " % name,
                    "%d rows of 16 printable bytes: the names of the tone and "
                    "combination GROUPS, blank-padded, %d of them filled with "
                    "'-' as an unused slot.  Rows 0-33 are the preset tone groups "
                    "(PIANO .. DRUMS 2), rows 64-79 are 'U1 Combi Group 1'..16 and "
                    "rows 80-95 are 'R1 Combi Group 1'..16."
                    % (rows, dashes))
        out += wrap("; Read by: ", "prom_a 0xFC2070/0xFC2077/0xFC207E/0xFC2085 -- "
                    "four `ld XIY,imm32` arms whose bases are this table's rows 0, "
                    "16, 32 and 48 -- followed by `mul WA,0x0010 / add XIY,XWA` at "
                    "0xFC208D.  The arm is chosen by W (the group KIND).")
        out += wrap("; Evidence: ", "the bytes themselves: every row is 16 "
                    "printable characters, and --selftest checks row 0 = 'PIANO', "
                    "row 33 = 'DRUMS 2' and the LAST row, 95, = 'R1 Combi "
                    "Group16'.  The stride is the reader's own `mul WA,0x0010`.")
        out += wrap("; Unknown: ", "which SCREEN presents the list.  The names are "
                    "unambiguous; the page that shows them is not decoded here, so "
                    "no `*Screen*` name is proposed.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, s in enumerate(strs):
            out.append("\t.ascii\t\"%s\"\t; %06X  [%d]" % (s, a + 16 * i, i))
        return out
    if kind == "maxmember":
        vals = list(at(a, n))
        base = {0xF06EB4: 0xF068B4, 0xF06EC4: 0xF06AB4,
                0xF06ED4: 0xF06BB4, 0xF06EE4: 0xF068B4}[a]
        nm = [at(base + 16 * i, 16).decode("latin1") for i in range(n)]
        ff = [i for i, v in enumerate(vals) if v == 0xFF]
        dash = [i for i, s in enumerate(nm) if set(s) == {"-"}]
        out += wrap("; %s -- " % name,
                    "%d bytes, one per group of the ToneGroupNames window that "
                    "starts at 0x%06X (rows %d..%d).  Values: %s."
                    % (n, base, (base - 0xF068B4) // 16,
                       (base - 0xF068B4) // 16 + n - 1,
                       " ".join("0x%02X x%d" % (v, vals.count(v))
                                for v in sorted(set(vals)))))
        out += wrap("; Read by: ", "prom_a sub_FC2222 (0xFC2222-0xFC2281): a chain "
                    "of `cp W,...` tests picks this base with `ld XIX,0x00%06X`, "
                    "then `ld A,(XIX+WA)` returns the byte for group A." % a)
        out += wrap("; Evidence: ", "the SAME `cp W` ladder that picks this map "
                    "picks the name-table base 0x%06X in prom_a 0xFC2050-0xFC2085, "
                    "and the map's 0xFF cells fall on EXACTLY the rows whose name "
                    "is '----------------': 0xFF at %s, dashes at %s.  The member "
                    "index is masked `and C,0x07` at prom_a 0xFC246F, so 7 is the "
                    "largest value the index can take."
                    % (base,
                       (",".join(str(i) for i in ff) if ff else "no row"),
                       (",".join(str(i) for i in dash) if dash else "no row")))
        out += wrap("; Unknown: ", "that 0x07 MEANS 'eight members'.  The masking "
                    "makes it the largest legal member index, but no code decoded "
                    "here uses this byte as a count, and the one 0x01 cell has not "
                    "been shown to mean 'two'.  ⚠ AND 'MEMBER' IS THIS FILE'S WORD, "
                    "NOT THE ROM'S: the string MEMBER occurs ZERO times in prom_a "
                    "and prom_b (--selftest asserts it), and it is used here only "
                    "to name the SECOND index of the pair (0x60F010)/(0x60F011).  "
                    "⚠ Nor is it established what distinguishes the two drum "
                    "windows at name-table rows 32-47 and 48-63; only the selector "
                    "ranges that pick them, 0x20-0x27 and 0x29-0x2F, are decoded.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, v in enumerate(vals):
            out.append("\t.byte\t0x%02X\t; %06X  [%d] %s"
                       % (v, a + i, i, nm[i].rstrip() or "(blank)"))
        return out
    if kind == "gm":
        rows, cols = n // 16, 8
        vals = [[w16(a + 16 * r + 2 * c) for c in range(cols)] for r in range(rows)]
        rd = {0xF06EF4: ("prom_a sub_FC22E0 (0xFC22E0-0xFC232F): `add XBC,"
                         "0x00F06EF4 / ld WA,(XBC)` with the row index A = "
                         "(0x60F010) plus 0x10, 0x20 or 0x22 according to "
                         "(0x60F013) and bit 2 of (0x7F4D), and the column "
                         "C = (0x60F011)"),
              0xF07134: ("prom_a 0xFC245D-0xFC2489: `ld XIX,0x00F07134 / add "
                         "XIX,XBC / ld WA,(XIX)` with the row index A = "
                         "(0x60F010) or'd with 0x80 when bit 5 of (0x60F011) is "
                         "set -- a FULL BYTE -- and the column (0x60F011) & 7"),
              0xF08514: ("prom_a 0xFC2574-0xFC258B: `and B,0x07 / and C,0x7F / "
                         "sla 3,BC / or C,A / sla 1,BC / ld XIX,0x00F08514`, i.e. "
                         "row = (0x60F010) & 0x7F, column = (0x60F011) & 7")}[a]
        out += wrap("; %s -- " % name,
                    "%d rows of %d 16-bit words: a (group, member) pair selects one "
                    "word, and the word is stored to (0x60F014)/(0x60F015).  This "
                    "is one of THREE tables of the same shape read by three arms "
                    "of the same prom_a module; they differ in how wide the row "
                    "index may be, and that is what the name says."
                    % (rows, cols))
        out += wrap("; Read by: ", rd)
        out += wrap("; Evidence: ", "the index arithmetic above is the whole of it: "
                    "row stride 16 bytes, column stride 2, and the destination "
                    "cells (0x60F014)/(0x60F015) are the same pair every arm "
                    "writes.  The row count %d is the object's extent divided by "
                    "the reader's own stride, and the extent comes from the next "
                    "object's base." % rows)
        out += wrap("; Unknown: ", "what the 16-bit word ENCODES.  The reader at "
                    "prom_a 0xFC248D classifies its low byte against 0x0F, 0x1F, "
                    "0x20 and 0x21, so the low byte is a kind and the high byte a "
                    "value -- but which kind, and of what, is not decoded here.  "
                    "⚠ 'MEMBER' IS THIS FILE'S WORD FOR THE SECOND INDEX, not the "
                    "ROM's: the string MEMBER occurs ZERO times in either image.  "
                    "⚠ AND THE THREE TABLES ARE NOT INVERSES OF ONE ANOTHER: "
                    "feeding 0xF07134's output back through 0xF08514 round-trips "
                    "1 pair of 2048 in either orientation (--selftest pins it), so "
                    "do not describe any of them as a reverse lookup.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for r in range(rows):
            out.append("\t.short\t%s\t; %06X  [%d]"
                       % (", ".join("0x%04X" % v for v in vals[r]), a + 16 * r, r))
        left = n - rows * 16
        if left:
            out += byte_rows(a + rows * 16, left, 16, "  tail, not a whole row")
        return out
    if kind == "ptrdir":
        ps = [w32(a + 4 * i) for i in range(n // 4)]
        out += wrap("; %s -- " % name,
                    "%d 32-bit pointers, sorted, all landing in 0x%06X-0x%06X -- "
                    "the record array immediately below this table.  Entry [%d], "
                    "the last, is 0x%06X, and 0x%06X + 3 is 0x%06X, the base of "
                    "the next object.  Every entry is 3-byte aligned on 0x%06X."
                    % (len(ps), min(ps), max(ps), len(ps) - 1, ps[-1], ps[-1],
                       ps[-1] + 3, 0xF08334))
        out += wrap("; Read by: ", "NOTHING.  ⚠ CORRECTION C1: round 1's dossier "
                    "said all eleven data objects of this span have a named "
                    "reader; nine do.  This base has NO 32-bit spelling anywhere "
                    "in prom_a or prom_b, so whatever indexes it computes the "
                    "address.  Its extent is pinned from the OTHER side instead, "
                    "by the abutment above.")
        out += wrap("; Evidence: ", "the %d pointers partition the %d records "
                    "below into %d runs, each run closed by a record whose third "
                    "byte is 0xFF, and there are exactly %d such records.  That "
                    "correspondence is asserted by --selftest on every run, the "
                    "LAST run included."
                    % (len(ps), 160, len(ps),
                       sum(1 for i in range(160) if at(0xF08334 + 3 * i + 2, 1)[0] == 0xFF)))
        out += wrap("; Unknown: ", "what the lists ARE.  The name stays FRAMED -- "
                    "kind plus address -- because nothing decoded in either image "
                    "says what a list means.  A stated gap beats a plausible guess.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, p in enumerate(ps):
            out.append("\t.long\t0x00%06X\t; %06X  [%d] -> record %d"
                       % (p, a + 4 * i, i, (p - 0xF08334) // 3))
        return out
    if kind == "reclists":
        recs = [list(at(a + 3 * i, 3)) for i in range(n // 3)]
        term = [i for i, r in enumerate(recs) if r[2] == 0xFF]
        out += wrap("; %s -- " % name,
                    "%d three-byte records.  %d of them end in 0xFF and the other "
                    "%d end in 0x10, 0x18 or 0x20; PtrTable_F08134 above has "
                    "exactly %d entries, so the array is %d variable-length lists, "
                    "each closed by its 0xFF record."
                    % (len(recs), len(term), len(recs) - len(term), 128, 128))
        out += wrap("; Read by: ", "NOTHING -- see CORRECTION C1 on the table "
                    "above.  This base is spelled as a 32-bit word EXACTLY ONCE "
                    "in prom_a and prom_b together, at 0xF08134, which is entry "
                    "[0] of the directory that points at this pool.  A directory "
                    "naming its own pool is not a reader.")
        out += wrap("; Evidence: ", "⚠ CORRECTION C4.  Round 1 quoted the triples "
                    "`ff 03 02 / ff 03 00 / 18 04 02` for this array; those bytes "
                    "occur only at offsets congruent to 2 mod 3, i.e. on a frame "
                    "SHIFTED BY 2.  The frame used here is proven from the other "
                    "side: all 128 pointers of PtrTable_F08134 are 3-byte aligned "
                    "on 0x%06X and the last of them plus 3 is 0x%06X, the next "
                    "object's base.  On THAT frame the array reads 00 00 10 / "
                    "02 00 18 / 00 00 ff / 03 02 ff ... and ends 7b 01 ff / "
                    "7d 03 ff / 7b 02 ff.  --selftest pins the first three and the "
                    "LAST three records." % (a, 0xF08514))
        out += wrap("; Unknown: ", "what the two leading bytes mean and what 0x10, "
                    "0x18 and 0x20 select.  FRAMED name kept on purpose.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, r in enumerate(recs):
            out.append("\t.byte\t0x%02X, 0x%02X, 0x%02X\t; %06X  [%d]%s"
                       % (r[0], r[1], r[2], a + 3 * i, i,
                          "  <- end of list" if r[2] == 0xFF else ""))
        return out
    if kind == "island":
        why = {0xF09B33: ("four 16-bit words, read at prom_b 0xF09AF6 by "
                          "`ld XIY,0x00F09B33 / ld W,A / sla 1,A / ld IX,(XIY+A)`"),
               0xF09B3B: ("64 bytes whose values run 0..7, read at prom_b 0xF09B12 "
                          "by `and A,0x3F / ld XBC,0x00F09B3B / ld D,(XBC+A)`.  "
                          "The mask 0x3F and the 64-byte extent agree"),
               0xF09B7B: ("eight 32-bit words, 0x00FC48D7..0x00FC4B4D, with a "
                          "CONSTANT stride of 0x5A.  A constant stride makes this "
                          "an ARRAY DESCRIPTOR, not a handler table, and the "
                          "layout walk correctly does not follow it: prom_b "
                          "0xF09B24 loads one into XIY and hands it to `swi 7` "
                          "with A=3 / BC=6 / HL=0x0F four instructions later.  "
                          "★ LEAD FOR A prom_a LANE: prom_a 0xFC48D7-0xFC4BA6 is "
                          "8 x 90 bytes and is still `.incbin`")}[a]
        out += wrap("; %s -- " % name, why + ".")
        out += wrap("; Evidence: ", "the reading instruction named above is in the "
                    "PROVEN transcription of this block, and the object's extent "
                    "is closed by the next object: the byte map's largest value is "
                    "7, so the table it indexes has 8 entries, so that table ends "
                    "at 0xF09B9B -- which is where the next code segment starts.")
        out += wrap("; Unknown: ", "what the three objects select.  FRAMED name "
                    "kept: kind plus address, and the gap is stated.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        if a == 0xF09B7B:
            for i in range(n // 4):
                out.append("\t.long\t0x00%06X\t; %06X  [%d]  +0x%02X"
                           % (w32(a + 4 * i), a + 4 * i, i,
                              0 if i == 0 else w32(a + 4 * i) - w32(a + 4 * i - 4)))
        elif a == 0xF09B33:
            for i in range(n // 2):
                out.append("\t.short\t0x%04X\t; %06X  [%d]" % (w16(a + 2 * i), a + 2 * i, i))
        else:
            out += byte_rows(a, n)
        return out
    if kind == "linkisland":
        pro = link_prologues()
        out += wrap("; %s -- " % name,
                    "%d bytes that are ALMOST CERTAINLY CODE and are deliberately "
                    "NOT claimed as code.  Nothing in either image references any "
                    "address inside them, so the layout has no entry point to "
                    "start a walk from, and this tree does not promote a run to "
                    "code on the strength of a decode alone." % n)
        out += wrap("; Decodes as: ", "a 15-byte `push`x7 / `pop`x7 / `ret` stub at "
                    "0x%06X; one routine at 0xF09E94 whose `link` lies OUTSIDE the "
                    "region and which ends `unlk XIZ` 0xF09EB0 / `ret` 0xF09EB2; "
                    "then THIRTEEN `link XIZ,0x0000 / ... / unlk XIZ / ret` "
                    "routines at %s; then a 4-byte `link XIZ,0x0000` at 0xF09FFC "
                    "with no body at all."
                    % (a, " ".join("0x%06X" % x for x in pro)))
        out += wrap("; Evidence: ", "⚠ CORRECTION C3.  Round 1 said TWELVE such "
                    "routines; there are THIRTEEN.  Each is closed by its own "
                    "`unlk XIZ / ret` and the next `link` starts at the very next "
                    "byte, so the framing is self-checking; a raw scan for the "
                    "`link XIZ` opcode pair 0xEE 0x0C over 0x%06X-0x%06X finds %d "
                    "hits, of which the bodyless 0xF09FFC is the fourteenth.  "
                    "--selftest re-derives the thirteen addresses from the ROM."
                    % (a, a + n - 1, len(pro) + 1))
        out += wrap("; Unknown: ", "who calls any of them.  ⚠ Round 1's open "
                    "question 5 stands: 0xF09FFC is a `link XIZ,0x0000` with no "
                    "body, immediately before a thunk target that begins "
                    "`link XIZ,0xFFFC`.  It is not padding in any shape this tree "
                    "has seen.  What this region needs is a REFERENCE, not a "
                    "better decoder.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += byte_rows(a, n)
        return out
    if kind == "jptab":
        ps = [w32(a + 4 * i) for i in range(n // 4)]
        ix = dict((t[1], t[3]) for t in EXT_TABLES).get(a)
        tgt = sorted(set(ps))
        out += wrap("; %s -- " % name,
                    "%d 32-bit entries, all inside this block (0x%06X-0x%06X), "
                    "naming %d distinct target%s.  A jump table, not a call "
                    "table: the reader ends `ld XBC,(XBC) / jp (XBC)`."
                    % (len(ps), min(ps), max(ps), len(tgt),
                       "" if len(tgt) == 1 else "s"))
        out += wrap("; Read by: ", "prom_b 0x%06X, `add XBC,0x00%06X / "
                    "ld XBC,(XBC) / jp (XBC)`, with the index bounded by the "
                    "`cp BC,0x%04X / jrl UGT` immediately above it."
                    % (ix, a, len(ps) - 1) if ix else
                    "no indexer located in this transcription")
        out += wrap("; Evidence: ", "every word is re-read on every emit and "
                    "asserted to land inside 0x%06X-0x%06X, and the entry count "
                    "%d is the extent divided by four -- the extent itself coming "
                    "from the code segment that starts at 0x%06X."
                    % (LO, HI, len(ps), a + n))
        out += wrap("; Unknown: ", "what the index enumerates.  FRAMED name kept.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, p in enumerate(ps):
            t2 = lab.get(p) or ("0x%06X" % p)
            out.append("\t.long\t0x00%06X\t; %06X  [%d] -> %s" % (p, a + 4 * i, i, t2))
        return out
    # generic
    out += wrap("; %s -- " % name, "%d bytes, printed from the ROM." % n)
    out.append("; " + "-" * 74)
    out.append("%s:" % name)
    out += byte_rows(a, n)
    return out


def link_prologues():
    """The THIRTEEN `link XIZ,0x0000` prologues of 0xF09E85-0xF09FFB, re-derived
    from the ROM.  CORRECTION C3: round 1 said twelve."""
    out = []
    for x in range(0xF09E85, 0xF09FFC):
        if at(x, 2) == b"\xee\x0c":
            out.append(x)
    return out


# ------------------------------------------------------------------- banner
def banner():
    k, b = {}, {}
    for kind, _s, n in LAYOUT:
        k[kind] = k.get(kind, 0) + 1
        b[kind] = b.get(kind, 0) + n
    lab = labels()
    nsub = sum(1 for v in lab.values() if v.startswith("sub_"))
    nnamed = len(lab) - nsub
    sm, bg = touched(LO, HI)
    top_small = sorted(sm.items(), key=lambda x: -x[1])[:6]
    top_big = sorted(bg.items(), key=lambda x: -x[1])[:5]
    ds = dl_sites()
    below = [d for d in ds if d[0] < 0xF09B33]
    return """
; ==============================================================================
; 0xF067A6-0xF0C734 -- THE SOUND EDIT SCREEN DATA BLOCK AND THE TWO SCREEN
;   MODULES ABOVE IT.  24,463 bytes; the largest `.incbin` left in the tree.
; ==============================================================================
;
; TWO THINGS WITH A 2,856-BYTE `ret` MOAT BETWEEN THEM.
;
;   0xF067A6-0xF097FF is DATA and not one byte of it is reached by any code
;   walk: the scale-tuning table, the 96 tone-GROUP names, three max-member
;   maps, three (group, member) tables, and one directory-plus-record-pool pair
;   that NOTHING in either image addresses.  Nine of the eleven objects have a
;   located reader in prom_a 0xFC0D70-0xFC25A1; ⚠ TWO DO NOT, and round 1's
;   dossier said eleven -- CORRECTION C1, applied.  The whole span's RAM state
;   is the same handful of cells the painters use: the array at 0x27A6
;   (prom_a Arr27A6_Get / Arr27A6_Set), the flag at 0x27F5 (prom_a Var27F5_Get)
;   and the group/member pair at 0x60F010/0x60F011.
;
;   0xF09800-0xF0C734 is CODE: handlers of the two PARALLEL 48-entry selector
;   tables DispatchTable_F5B8F8 / DispatchTable_F5B9F8, of prom_a's two
;   computed-call tables at 0xFCF21B (377 entries, 50 in this span) and
;   0xFCF80C (305 entries, 43 in this span), and of eight small `jp (XBC)`
;   tables inside the block itself.
;
; @@ WHERE THE BOUNDARIES COME FROM.  notes/prom_b_f067a6_layout.py, re-derived
; on EVERY run of this file and compared segment for segment (%d segments).  Not
; from a linear decode -- notes/prom_a_linear_decode_check.py records why one
; pins nothing.  Content rules run FIRST and become barriers the code walk may
; not enter; the descent is seeded from thunk slots, from every already-proven
; call site, from opcode-anchored far sites whose SITE is not proven data, and
; from the entries of pointer tables whose reader transfers.  Each rule's false
; positives are measured against proven instruction text and proven display-list
; DATA, and the layout's own `--null-*` modes print them.
;
; @@ THE FOUR ROUND-1 CORRECTIONS, ALL APPLIED AND ALL PINNED BY --selftest.
;   C1  nine of eleven data objects have a reader, not eleven.  PtrTable_F08134
;       and RecordArray_F08334 have none and keep FRAMED names.
;   C2  %d display-list call sites lie below the first code segment's end, not
;       24; the other %d are in the SECOND code segment at 0xF09BA0-0xF09D69.
;   C3  0xF09E85-0xF09FFB holds THIRTEEN `link XIZ` routines, not twelve.
;   C4  the 160x3 array at 0xF08334 was quoted on a frame SHIFTED BY 2.
;
; @@ AND ONE THING THAT IS NOT THIS SPAN'S.  T_F41F54-T_F421A8 is a 150-slot
; SHARED thunk run that also appears in the prom_a frontier; only FIVE of its
; slots point in here.  It is not described as this block's table.
;
; LAYOUT.  %d segments: %d code (%d bytes), %d pointer tables (%d bytes),
; %d `.byte` data runs (%d bytes), %d string table (%d bytes) and %d runs of
; 0x0E `ret` padding (%d bytes).  Substantive: %d of %d.
;
; LABELS.  %d, of which %d carry a name derived from something and %d are
; sub_XXXXXX with the gap stated.  The %d bytes of code from 0xF0A000 up, in
; %d segments, are reached only through prom_a's two computed-call tables, and
; nothing decoded here says what their indices enumerate, so nothing there is
; named.
;
; WHAT THE BLOCK TOUCHES, measured over the transcription itself.
; Heaviest 16-bit RAM words: %s.
; Heaviest absolute operands: %s.
; That is a measurement of what the code ADDRESSES, not a claim about what it
; IS, and no routine is named on the strength of it.
;
; REGENERATE:  python3 notes/gen_prom_b_f067a6_module.py
; CHECKS:      python3 notes/gen_prom_b_f067a6_module.py --checks
; NAMES:       python3 notes/gen_prom_b_f067a6_module.py --names
; ==============================================================================
""" % (EXPECTED, len(below), len(ds) - len(below),
       len(LAYOUT), k.get("code", 0), b.get("code", 0),
       k.get("ptrtab", 0), b.get("ptrtab", 0),
       k.get("data", 0), b.get("data", 0),
       k.get("ascii", 0), b.get("ascii", 0),
       k.get("fill", 0), b.get("fill", 0),
       sum(v for kk, v in b.items() if kk != "fill"), HI - LO,
       len(lab), nnamed, nsub,
       sum(n for k_, s_, n in LAYOUT if k_ == "code" and s_ >= 0xF0A000),
       sum(1 for k_, s_, _n in LAYOUT if k_ == "code" and s_ >= 0xF0A000),
       " ".join("(0x%04X) x%d" % t for t in top_small),
       " ".join("0x%06X x%d" % t for t in top_big))


# --------------------------------------------------------------------- emit
def emit():
    lab, th, sr, ic, ee = labels(), thunks(), slot_refs(), internal_calls(), ext_entries()
    keys = sorted(a for a in lab if seg_of(a)[0] == "code")
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else 0) for i, a in enumerate(keys)}
    out = banner().replace("@@", "⚠").strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted "
                    "pure 0x0E)" % (n, s, s + n - 1), ""]
            continue
        if kind in DATA_KINDS:
            starts = sorted(a for a, _n, _k in OBJECTS if s <= a < s + n) or [s]
            for a in starts:
                k2 = dict((x, kk) for x, _n, kk in OBJECTS).get(
                    a, "jptab" if kind == "ptrtab" else "generic")
                out += [""] + data_object(a, obj_end(a), lab, k2) + [""]
            continue
        seg_end = s + n
        for a, ln in [(a, l) for a, l in code_lines() if s <= a < seg_end]:
            if a in lab:
                e = ends[a] if ends[a] and ends[a] < seg_end else seg_end
                out += [""] + code_header(a, e, lab, th, sr, ic, ee)
                tag = "\t\t; <- %s" % ", ".join("T_%06X" % x for x in th[a]) \
                      if a in th else ""
                out.append("%s:%s" % (lab[a], tag))
            out.append(ln)
    return out


def verify_region(lines):
    """Assemble the WHOLE emitted text and compare all %d bytes with the ROM."""
    import llvm_roundtrip as RT
    body = [l + "\n" for l in lines if not l.startswith(";") and l.strip()]
    got, err = RT.assemble(body)
    if got is None:
        return False, "llvm-mc refused the emitted text:\n" + err[-3000:]
    want = at(LO, HI - LO)
    if got != want:
        for i in range(min(len(got), len(want))):
            if got[i] != want[i]:
                return False, ("first difference at 0x%06X: emitted 0x%02X, "
                               "ROM 0x%02X (emitted %d bytes, want %d)"
                               % (LO + i, got[i], want[i], len(got), len(want)))
        return False, "length differs: emitted %d, ROM %d" % (len(got), len(want))
    return True, "%d bytes re-assemble to the ROM exactly" % len(got)


# ------------------------------------------------------------------- checks
def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    if verbose:
        print(("  ok    " if ok else "  FAIL  ") + desc)
    return ok


def checks(verbose=True, layout=True):
    del FAIL[:]
    if layout:
        segs, conflicts, _L = build_layout()
        c("LAYOUT equals notes/prom_b_f067a6_layout.py's derivation", segs, LAYOUT, verbose)
        c("  its segment count is still %d" % EXPECTED, len(segs), EXPECTED, verbose)
        c("  the barrier rules reclaim no descent byte", len(conflicts), 0, verbose)
    c("LAYOUT tiles 0x%06X-0x%06X with no gap and no overlap" % (LO, HI),
      [(LAYOUT[0][1], sum(n for _k, _s, n in LAYOUT))], [(LO, HI - LO)], verbose)
    p = LO
    tiles = True
    for _k, s, n in LAYOUT:
        tiles = tiles and s == p
        p = s + n
    c("  every segment starts where the previous one ends", (tiles, p), (True, HI), verbose)
    for kind, s, n in LAYOUT:
        if kind == "fill":
            c("  fill 0x%06X..0x%06X is pure 0x0E" % (s, s + n - 1),
              sorted(set(at(s, n))), [0x0E], verbose)
    # ---- CORRECTION C1: nine of eleven, and the two exceptions have NO 32-bit
    #      spelling anywhere in either image
    for base in (0xF08134, 0xF08334):
        tgt = base.to_bytes(4, "little")
        hits = []
        for blob, b0 in ((rom("a"), A_BASE), (rom("b"), B_BASE)):
            i = 0
            while True:
                i = blob.find(tgt, i)
                if i < 0:
                    break
                hits.append(b0 + i)
                i += 1
        # ⚠ REFINEMENT OF ROUND 1's C1.  The skeptic wrote "neither base has any
        # 32-bit spelling in either image".  For 0xF08134 that is exact.  For
        # 0xF08334 there is ONE hit and it is entry [0] of PtrTable_F08134 --
        # the directory pointing at its own pool -- which is not a reader.
        outside = [h for h in hits if not (0xF08134 <= h < 0xF08334)]
        c("C1  0x%06X has no 32-bit spelling outside PtrTable_F08134" % base,
          [hex(h) for h in outside], [], verbose)
        if base == 0xF08334:
            c("C1  ...and its ONLY spelling anywhere is that table's entry [0]",
              [hex(h) for h in hits], ["0xf08134"], verbose)
    c("C1  and both keep a FRAMED name",
      [labels()[0xF08134], labels()[0xF08334]],
      ["PtrTable_F08134", "RecordArray_F08334"], verbose)
    # ---- CORRECTION C2: 22 sites below the first code segment's end, 14 above
    ds = dl_sites()
    below = [d for d in ds if d[0] < 0xF09B33]
    above = [d for d in ds if d[0] >= 0xF09B33]
    c("C2  display-list call sites in the span", len(ds), 36, verbose)
    c("C2  ...of which BELOW the first code segment's end (round 1 said 24)",
      len(below), 22, verbose)
    c("C2  ...and the rest are in the second code segment", len(above), 14, verbose)
    c("C2  the below-block runs 0x%06X-0x%06X" % (below[0][0], below[-1][0]),
      (below[0][0], below[-1][0]), (0xF0980D, 0xF09AC2), verbose)
    c("C2  the above-block runs 0x%06X-0x%06X" % (above[0][0], above[-1][0]),
      (above[0][0], above[-1][0]), (0xF09BA0, 0xF09D69), verbose)
    c("C2  17 sites call 0xF417F0 and 19 call 0xF417F4",
      (sum(1 for d in ds if d[3] == 0xF417F0), sum(1 for d in ds if d[3] == 0xF417F4)),
      (17, 19), verbose)
    c("C2  the highest list END named by any site is 0xFC52B4, not 0xFC527A",
      max(d[2] for d in ds), 0xFC52B4, verbose)
    # ---- CORRECTION C3: thirteen link routines
    pro = link_prologues()
    c("C3  `link XIZ` prologues in 0xF09E85-0xF09FFB (round 1 said twelve)",
      len(pro), 13, verbose)
    c("C3  and they are at exactly these addresses", pro,
      [0xF09EB3, 0xF09ED7, 0xF09EEF, 0xF09F0F, 0xF09F24, 0xF09F39, 0xF09F4E,
       0xF09F63, 0xF09F78, 0xF09F8D, 0xF09FA2, 0xF09FC0, 0xF09FE4], verbose)
    c("C3  each is closed by `unlk XIZ` (0xEE 0x0D) + `ret` (0x0E) and the next "
      "`link` follows immediately",
      [x for x in pro[1:] if at(x - 3, 3) != b"\xee\x0d\x0e"], [], verbose)
    c("C3  0xF09FFC is a fourteenth `link XIZ,0x0000` with NO body",
      (at(0xF09FFC, 4), 0xF09FFC in pro), (b"\xee\x0c\x00\x00", False), verbose)
    # ---- CORRECTION C4: the 160x3 array on the PROVEN frame
    recs = [bytes(at(0xF08334 + 3 * i, 3)) for i in range(160)]
    c("C4  the first three records on the proven frame", recs[:3],
      [b"\x00\x00\x10", b"\x02\x00\x18", b"\x00\x00\xff"], verbose)
    c("C4  the LAST three records on the proven frame", recs[-3:],
      [b"\x7b\x01\xff", b"\x7d\x03\xff", b"\x7b\x02\xff"], verbose)
    c("C4  records ending 0xFF == pointer count",
      (sum(1 for r in recs if r[2] == 0xFF), 512 // 4), (128, 128), verbose)
    ps = [w32(0xF08134 + 4 * i) for i in range(128)]
    c("C4  every pointer is 3-byte aligned on 0xF08334 and sorted",
      (sorted(set((p - 0xF08334) % 3 for p in ps)), ps == sorted(ps)),
      ([0], True), verbose)
    c("C4  entry[127] + 3 is the next object's base", ps[127] + 3, 0xF08514, verbose)
    c("C4  and the pointers partition the records: every pointed-at run ends at "
      "the record after the next pointer",
      [i for i in range(127)
       if not any(recs[j][2] == 0xFF
                  for j in range((ps[i] - 0xF08334) // 3, (ps[i + 1] - 0xF08334) // 3))],
      [], verbose)
    # ---- the names
    rows = [bytes(at(0xF06800 + 12 * i, 12)) for i in range(15)]
    flat = [i for i, r in enumerate(rows) if set(r) == {0x80}]
    c("SCALE  fifteen rows of twelve, and the flat ones are OFF/RANDOM/PIANO/"
      "ORCHESTR + USER (the LAST row)", flat, [0, 1, 2, 3, 14], verbose)
    c("SCALE  ALL FIVE ARABIC rows carry the 0x40 quarter-tone cell",
      [i for i in range(7, 12) if 0x40 not in rows[i]], [], verbose)
    c("SCALE  and no NON-Arabic row does",
      [i for i in range(15) if i not in range(7, 12) and 0x40 in rows[i]], [], verbose)
    c("SCALE  prom_b 0x%06X holds fifteen 8-character names ending USER"
      % SCALE_NAME_TABLE,
      [at(SCALE_NAME_TABLE + 8 * i, 8).decode("latin1").strip() for i in range(15)],
      SCALE_NAMES, verbose)
    nm = [at(0xF068B4 + 16 * i, 16).decode("latin1") for i in range(96)]
    c("NAMES  row 0, row 33 and the LAST row 95",
      [nm[0].strip(), nm[33].strip(), nm[95]],
      ["PIANO", "DRUMS 2", "R1 Combi Group16"], verbose)
    c("NAMES  every one of the 96 rows is 16 printable bytes",
      [i for i, s in enumerate(nm) if not all(32 <= ord(x) < 127 for x in s)], [], verbose)
    for m_, base in ((0xF06EB4, 0xF068B4), (0xF06EC4, 0xF06AB4), (0xF06ED4, 0xF06BB4)):
        vals = list(at(m_, 16))
        dash = [i for i in range(16)
                if set(at(base + 16 * i, 16).decode("latin1")) == {"-"}]
        c("MAXMEM 0x%06X: the 0xFF cells are EXACTLY the '----' rows of the name "
          "window at 0x%06X" % (m_, base),
          [i for i, v in enumerate(vals) if v == 0xFF], dash, verbose)
    c("MAXMEM 0xF06EE4 is byte-identical to 0xF06EB4 (a second copy, read by the "
      "parallel selector sub_FC2282)", at(0xF06EE4, 16), at(0xF06EB4, 16), verbose)
    # the refutation that must not be re-invented
    def rt(orient):
        ok = 0
        for g in range(256):
            for m2 in range(8):
                x = w16(0xF07134 + 16 * g + 2 * m2)
                lo_, hi_ = x & 0xFF, x >> 8
                i = ((hi_ if orient else lo_) & 0x7F) * 8 + ((lo_ if orient else hi_) & 7)
                if i < 994:
                    r = w16(0xF08514 + 2 * i)
                    if (r >> 8) == g and (r & 0xFF) == m2:
                        ok += 1
        return ok
    c("GM     0xF07134 and 0xF08514 are NOT inverses -- 1 of 2048 in either "
      "orientation, which is chance", (rt(True), rt(False)), (1, 1), verbose)
    # dispatch-table parallelism, the evidence behind the screen-module names
    par = []
    for i in (26, 27, 29, 45):
        par.append((int.from_bytes(at(0xF5B8F8 + 4 * i, 4), "little"),
                    int.from_bytes(at(0xF5B9F8 + 4 * i, 4), "little")))
    c("SCREEN entries [26],[27],[29],[45] of the two PARALLEL tables", par,
      [(0x00F099F5, 0x00F09AA5), (0x00F0985C, 0x00F09961),
       (0x00F09B9B, 0x00F09C08), (0x00F09800, 0x00F098FB)], verbose)
    c("SCREEN every second-table routine of those four starts `cp A,`",
      [hex(x) for x in (0xF09AA5, 0xF09961, 0xF09C08, 0xF098FB)
       if not mame_text(x).startswith("cp A,")], [], verbose)
    c("SCREEN and no first-table routine of those four does",
      [hex(x) for x in (0xF099F5, 0xF0985C, 0xF09B9B, 0xF09800)
       if mame_text(x).startswith("cp A,")], [], verbose)
    txt = {s: " / ".join(dl_text(s, e)) for _a, s, e, _i in dl_sites()}
    c("SCREEN the CONTROLLER header list says so, and PAGE1/2 and PAGE2/2 are in "
      "the lists the two painters run",
      ["C0NTR0LLER" in txt.get(0xF32C2A, ""), "PAGE1/2" in txt.get(0xF32D2C, ""),
       "PAGE2/2" in txt.get(0xF32E71, ""), "DIGITAL EFFECT" in txt.get(0xFC40F0, ""),
       "COPY" in txt.get(0xFC4BA7, "")], [True] * 5, verbose)
    # ⚠ ROUND 3's LESSON, PINNED.  A reviewer found five prom_a labels built on
    # the morpheme "Home", which occurs ZERO times in all four images: the
    # concept was invented.  Every morpheme this file puts in a name is counted
    # against the ROM here, and the ONE that scores zero -- MEMBER -- is
    # disclosed as this file's own word in every header that uses it.
    vocab = dict((w, sum(rom(i).count(w.encode()) for i in "ab"))
                 for w in ("CONTROLLER", "SOUND EDIT", "DIGITAL EFFECT", "COPY",
                           "SCALE", "TUNING", "GROUP", "TONE", "DRUM", "MEMBER"))
    c("VOCAB  every morpheme in a derived name occurs in the ROM (%s)"
      % ", ".join("%s x%d" % kv for kv in sorted(vocab.items())),
      [w for w, n2 in vocab.items() if n2 == 0], ["MEMBER"], verbose)
    c("VOCAB  ...and MEMBER, the one that does not, is disclosed in both headers "
      "that use it",
      sum(1 for kk in ("maxmember", "gm")
          if "THIS FILE'S WORD" in "\n".join(
              data_object(0xF06EB4 if kk == "maxmember" else 0xF06EF4,
                          obj_end(0xF06EB4 if kk == "maxmember" else 0xF06EF4),
                          labels(), kk))), 2, verbose)
    # label hygiene
    lab = labels()
    b_ = boundaries()
    objs = {a for a, _n, _k in OBJECTS} | {s_ for k_, s_, _n in LAYOUT
                                           if k_ in DATA_KINDS}
    c("every label address is an instruction boundary or an object base",
      [hex(a) for a in lab if a not in b_ and a not in objs], [], verbose)
    c("no two labels share a name", len(set(lab.values())), len(lab), verbose)
    codel = [a for a in lab if seg_of(a)[0] == "code"]
    c("COUNTS code labels, of which sub_XXXXXX; and code bytes above 0xF0A000",
      (len(codel), sum(1 for a in codel if lab[a].startswith("sub_")),
       sum(n for k_, s_, n in LAYOUT if k_ == "code" and s_ >= 0xF0A000),
       sum(1 for k_, s_, _n in LAYOUT if k_ == "code" and s_ >= 0xF0A000)),
      (154, 144, 9733, 8), verbose)
    # ⚠ THIS CHECK CAUGHT ITS OWN HEADER.  The first draft of the banner said
    # "eight small `jp (XBC)` tables"; the layout has NINE ptrtab segments, of
    # which one is the record directory in the DATA block and one is a strided
    # array descriptor, leaving SEVEN jump tables.  "A handler count of 35 that
    # was 34" is on this tree's error list; this is the same shape, caught
    # before it shipped.
    ptabs = [s_ for k_, s_, _n in LAYOUT if k_ == "ptrtab"]
    c("COUNTS nine pointer tables: one record directory, one strided array "
      "descriptor (constant stride 0x5A), SEVEN jump tables",
      (len(ptabs), 0xF08134 in ptabs,
       sorted(set(w32(0xF09B7B + 4 * i + 4) - w32(0xF09B7B + 4 * i)
                  for i in range(7))), len(ptabs) - 2),
      (9, True, [0x5A], 7), verbose)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAILED",
                                    len(FAIL)))
        for f in FAIL:
            print("   ! " + f)
    return not FAIL


# =============================================================================
# PART 2 -- `--dl-names`: naming prom_b's display lists from the text they draw
# =============================================================================
DL_LABEL = re.compile(r"^(DL_[0-9A-F]{6}):")
ANY_LABEL = re.compile(r"^[A-Za-z_.][A-Za-z0-9_.]*:")
ASCII_REC = re.compile(r'\.ascii\s+"([^"]*)"')
SLUG_MIN = 24          # characters of CamelCase to accumulate before stopping
SLUG_MAX = 40


def camel(s):
    out = []
    for w in re.split(r"[^A-Za-z0-9]+", s):
        if w:
            out.append(w[0].upper() + w[1:].lower())
    return "".join(out)


def dl_label_text(lines):
    """[(index, label, [literal, ...])] for every DL_<addr> label in the file.

    The literals are the `.ascii` records between the label and the NEXT label
    or section rule -- i.e. the list's own text records, and nothing else's."""
    idx = [i for i, l in enumerate(lines) if DL_LABEL.match(l)]
    out = []
    for k, i in enumerate(idx):
        j = idx[k + 1] if k + 1 < len(idx) else len(lines)
        for m in range(i + 1, j):
            if ANY_LABEL.match(lines[m]) or lines[m].startswith("; ---"):
                j = m
                break
        body = "\n".join(lines[i + 1:j])
        lit = [t.strip() for t in ASCII_REC.findall(body)]
        lit = [t for t in lit if re.search(r"[A-Za-z]{2}", t)]
        out.append((i, DL_LABEL.match(lines[i]).group(1), lit))
    return out


def dl_proposals(lines):
    """{old: (new, [literal, ...])} for every DL_<addr> whose text yields a name
    that is UNIQUE in the whole file.  A collision keeps its address."""
    recs = dl_label_text(lines)
    taken = set(re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l).group(1)
                for l in lines if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:", l))
    prop, seen = {}, {}
    for _i, old, lit in recs:
        if not lit:
            continue
        s = ""
        for t in lit:
            s += camel(t)
            if len(s) >= SLUG_MIN:
                break
        new = "DL_" + s[:SLUG_MAX]
        if new == old or len(new) < 5:
            continue
        seen.setdefault(new, []).append(old)
        prop[old] = (new, lit)
    out = {}
    for old, (new, lit) in prop.items():
        if len(seen[new]) == 1 and new not in taken:
            out[old] = (new, lit)
    return out, seen


def dl_names(apply=False):
    text = open(SRCB).read()
    lines = text.split("\n")
    prop, seen = dl_names_cached(lines)
    total = len(dl_label_text(lines))
    withtext = sum(1 for _i, _o, l in dl_label_text(lines) if l)
    print("prom_b DL_<address> labels: %d, of which %d contain text records"
          % (total, withtext))
    print("unique proposals: %d   collisions left FRAMED: %d"
          % (len(prop), withtext - len(prop)))
    coll = sorted((k, v) for k, v in seen.items() if len(v) > 1)
    if coll:
        print("  the %d colliding names (kept as addresses):" % len(coll))
        for k, v in coll[:12]:
            print("    %-44s %s" % (k, " ".join(v)))
    for old, (new, lit) in sorted(prop.items())[:12]:
        print("  %-14s -> %-42s  %s" % (old, new, " / ".join(lit)[:44]))
    print("  ... (%d more)" % max(0, len(prop) - 12))
    if not apply:
        print("\n(dry run; add --apply to rewrite prom_b/wsa1_prom_b.s)")
        return 0
    out, k = [], 0
    ren = dict((o, n) for o, (n, _l) in prop.items())
    rx = re.compile(r"\b(%s)\b" % "|".join(sorted(ren)))
    for ln in lines:
        m = DL_LABEL.match(ln)
        if m and m.group(1) in ren:
            old = m.group(1)
            new, lit = prop[old]
            addr = int(old[3:], 16)
            out += wrap("; %s -- " % new,
                        "the display list at 0x%06X.  Its own text records read: "
                        "%s." % (addr, "; ".join('"%s"' % t for t in lit[:8]) +
                                 (" +%d more" % (len(lit) - 8) if len(lit) > 8 else "")))
            out += wrap("; Evidence: ", "the `.ascii` literals printed below this "
                        "label, which the display-list interpreter draws verbatim; "
                        "the name is CamelCase of the first of them and says what "
                        "the list PUTS ON THE SCREEN and nothing more.  Generated "
                        "by notes/gen_prom_b_f067a6_module.py --dl-names.")
            out.append(new + ":" + ln[m.end():])
            k += 1
            continue
        if "DL_F" in ln:
            ln = rx.sub(lambda mm: ren[mm.group(1)], ln)
        out.append(ln)
    write_part(SRCB_MASTER, "\n".join(out))
    print("\nrewrote %d labels in %s" % (k, SRCB))
    return 0


def dl_names_cached(lines):
    if "dlp" not in _cache:
        _cache["dlp"] = dl_proposals(lines)
    return _cache["dlp"]


# --------------------------------------------------------------------- main
def splice():
    """Replace the span's `.incbin` line in prom_b/wsa1_prom_b.s with the emitted
    text.  Refuses unless checks() and verify_region() both pass first."""
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to splice: a check failed (see above)")
    lines = emit()
    good, msg = verify_region(lines)
    if not good:
        raise SystemExit("refusing to splice: " + msg)
    src = open(SRCB).read().split("\n")
    want = ('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X'
            % (LO - B_BASE, HI - LO))
    hit = [i for i, l in enumerate(src) if l == want]
    if len(hit) == 1:
        i = hit[0]
        lo_ = i - 1 if src[i - 1].startswith("; --- 0xF067A6") else i
        hi_ = i
        how = "over the `.incbin`"
    else:
        # Already spliced: replace the region in place, so re-running this file
        # after a prose fix does not need the `.incbin` back.  Both anchors carry
        # a ROM address in their comment, so both are unique in the file.
        first, last = lines[[bool(l) and not l.startswith(";")
                             for l in lines].index(True)], lines[-1]
        a_ = [k for k, l in enumerate(src) if l == first]
        b_ = [k for k, l in enumerate(src) if l == last]
        if len(a_) != 1 or len(b_) != 1:
            raise SystemExit("cannot locate the spliced region: %d head anchors, "
                             "%d tail anchors" % (len(a_), len(b_)))
        lo_, hi_ = a_[0], b_[0]
        while lo_ and (src[lo_ - 1].startswith(";") or not src[lo_ - 1].strip()):
            lo_ -= 1
        how = "in place over lines %d-%d" % (lo_ + 1, hi_ + 1)
    out = src[:lo_] + lines + src[hi_ + 1:]
    write_part(SRCB_MASTER, "\n".join(out))
    print("spliced %d lines %s; %s" % (len(lines), how, msg))
    return 0


def main():
    if "--splice" in sys.argv:
        return splice()
    if "--dl-names" in sys.argv:
        return dl_names("--apply" in sys.argv)
    if "--layout" in sys.argv:
        tot = {}
        for kind, s, n in LAYOUT:
            print("  %-6s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
            tot[kind] = tot.get(kind, 0) + n
        print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("  substantive %d of %d"
              % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
        return 0
    if "--names" in sys.argv:
        lab = labels()
        for a in sorted(lab):
            kind = seg_of(a)[0]
            print("  0x%06X  %-6s %-40s %s"
                  % (a, kind, lab[a], "DERIVED" if not lab[a].startswith("sub_")
                     and not re.match(r"^[A-Za-z]+_[0-9A-F]{6}$", lab[a])
                     else ("framed" if lab[a][0].isupper() else "gap stated")))
        n = sum(1 for v in lab.values() if v.startswith("sub_"))
        f = sum(1 for v in lab.values() if re.match(r"^[A-Za-z]+_[0-9A-F]{6}$", v)
                and not v.startswith("sub_"))
        print("  %d labels: %d content, %d framed, %d sub_XXXXXX"
              % (len(lab), len(lab) - n - f, f, n))
        return 0
    if "--selftest" in sys.argv or "--checks" in sys.argv:
        ok = checks()
        if ok:
            good, msg = verify_region(emit())
            print(("  ok    " if good else "  FAIL  ") + "whole region: " + msg)
            ok = ok and good
        return 0 if ok else 1
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    lines = emit()
    good, msg = verify_region(lines)
    if not good:
        raise SystemExit("refusing to emit: " + msg)
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
