#!/usr/bin/env python3
"""prom_a round 6: FOUR levers against 2,950 `sub_XXXXXX`, and the size of each.

QUESTION IT ANSWERS
    prom_a holds the largest block of unnamed routines in the tree (1,429
    content names against 2,950 `sub_XXXXXX`, LOWER 30.9%).  The wave-7 round-6
    brief proposed three levers -- CALL-SITE SHAPE AT SCALE, WHAT THE ROUTINE
    TOUCHES, and LEAF ARITHMETIC -- and asked for the reach of each, "including
    zero".  This file measures four and reports every one, the two that paid and
    the two that did not.

★★ THE ONE STRUCTURAL FIX THAT MADE EVERYTHING ELSE POSSIBLE: `calr`.
    prom_a's listing spells a `calr` whose target has no label as the RAW 16-BIT
    DISPLACEMENT -- `calr 0xf23b`, not an address.  Every reference census this
    tree has run reads those as addresses or skips them, so 2,429 call sites
    were invisible.  `target = site + 3 + signed16(displacement)`, and --calr
    proves that formula on the 2,100 `calr` lines that DO carry a symbolic
    target: 2,100 agree, 0 disagree.  The corrected census moves prom_a's
    "reached by nothing we can see" count from 805 routines to 302.

★★ THE TRAP I FELL INTO, AND THE CHECK THAT CAUGHT IT.  Round 5 retracted
    `Paint_MasterTrackClear` (0xF81AB5) and `Paint_C0mbinati0nM0de` (0xF9167C)
    because the namer credited a display-list site to the nearest preceding
    LABEL instead of scoping it to the routine's own `ret`.  The first draft of
    --painters here, scoped label-to-next-label, PROPOSED BOTH NAMES AGAIN, plus
    three more.  Re-scoping to the routine's own first `ret` (`body()` below)
    removed all five.  A mechanism that reproduces a documented retraction is
    the mechanism being wrong, not the retraction.

────────────────────────────────────────────────────────────────────────────────
THE FOUR LEVERS, WITH THEIR MEASURED REACH OVER ALL 2,950
────────────────────────────────────────────────────────────────────────────────

L1  CALL-SITE SHAPE AT SCALE -- ⚠ REJECTED, reach 13 of 2,950 (0.4%).
    The brief's first suggestion.  With the `calr` fix, 882 of the 2,950 have
    two or more call sites -- but on only THIRTEEN do all sites load the same
    register with the same immediate.  There is no repeated caller shape to
    mine, because 2,017 of the 2,950 have exactly zero or one call site.  A
    caller shape needs callers to agree, and prom_a's do not exist in enough
    numbers to agree.  --callshape prints all 13 and the histogram behind them.
    ⚠ Do not spend another round on this lever.

L2  BYTE-IDENTICAL TWINS INSIDE prom_a -- ⚠ REJECTED, reach 0.
    Round 5 rejected the prom_a/prom_c twin search.  This is the same idea
    INSIDE prom_a, on exact ROM bytes from entry to first `ret`: zero groups mix
    a content-named routine with a `sub_XXXXXX`.  --twins.

L3  WHAT THE ROUTINE TOUCHES -- ✅ THE ONE THAT PAID, reach 25.
    The SWI7 graphics API is fully documented (34 live services, all named,
    notes/FINDINGS-display-controller.md, notes/swi7_service_table.py), so a
    routine whose own immediates fix every argument of the service it issues is
    completely determined by its own bytes.  65 candidates reach `swi 7` before
    their own first `ret`; 20 are at most 12 instructions long with every
    service number resolvable and 29 more are 13-30 instructions.  TWENTY-FOUR
    are named from that: 17 from the short band and 7 from the long one where
    the extra instructions are pushes, a coordinate setup, or a `calr` to a
    routine this tree has already named.  A twenty-fifth,
    SongName_ResetToUnderscores, comes from the same thread -- the buffer the
    drawer draws -- and not from a `swi 7` at all.
    ★ Naming them also answers open questions in the tree: services 0x0E, 0x1B
      and 0x1E each carry "Unknown: callers" in their own headers, and these are
      the callers.
    --services prints the short band and says why three of it keep `sub_XXXXXX`.

L4  DISPLAY-LIST PAINTERS THROUGH THE RAW ROM -- ✅ reach 2, and the reach is
    the finding.  Round 5 could only name a painter whose list carried a prom_b
    LABEL.  This walks the list out of `original_ROMs/` instead, so it also sees
    the 112 lists that live in prom_b spans that are still `.incbin`.  Result:
    81 painters (scoped to their own `ret`), 87 interpreter-A sites, 82 of which
    FRAME exactly; and only SEVEN carry any text at all.  Five of those seven
    are the ones round 5 already refused by name (their text is `ALL`/`TRACK`,
    `USR1`/`USR2`, `R0M1`/`EXT1`, or a single `-`).  TWO are new.
    ⚠ So the extra reach of reading the ROM instead of the labels is two
      routines, not a harvest.  The remaining 64 interpreter-A lists carry NO
      text and 99 interpreter-B sites carry none by construction -- they draw
      live variables.  That is the correct answer for them, not a failure.

────────────────────────────────────────────────────────────────────────────────
TWO FINDINGS THAT ARE NOT NAMES
────────────────────────────────────────────────────────────────────────────────

F1  ⚠ THE FOUR UNREACHABLE CONTROL CHANGE SLOTS ARE NOT A NEW FINDING -- THE
    TREE GOT THERE FIRST, and I re-derived them before reading its headers.
    `sub_FA64E5` [8], `sub_FA6526` [9], `sub_FA6459` [16] and `sub_FA645A` [17]
    of `MidiIn_ControllerHandlerTable` already carry, from round 2's
    `notes/gen_prom_a_fa5aeb_module.py`, the sentence "MidiIn_ControllerNumberToIndex
    sends NO controller number to this index".  What --midi adds is the
    quantification and the closure of the chain, which that header does not state:
      * `(0x1963)` is WRITTEN at exactly one address, 0xFA6275, and READ at
        exactly one, 0xFA62A3 -- one site each in both images;
      * the value written is `MidiIn_ControllerNumberToIndex[controller]`
        (0xFA83E8, 128 bytes), and 23 of those 128 entries are not 0xFF;
      * the indices those 23 produce are
        {0,1,2,3,4,5,6,7,10,11,12,13,14,15,18,24,25,32,33,34,35,40,41};
      * 8, 9, 16 and 17 are not in that set, and each of the four routines has
        exactly ONE reference in either image: its own table slot.
    ★ AND THE TREE IS STILL AHEAD OF ME on slot 16: its header cites
    `MidiIn_IndexToControllerNumber` naming it CC 0x50 and then REFUSES the name
    because that map is only read on the outbound side.  No header is edited here
    -- all four sit inside the 0xFA5AEB emitter's range and it already says it.
    ⚠ NOT CLAIMED: that they are dead in the machine.  Another CPU, or a firmware
      revision, could write (0x1963); nothing in these two images can.

F2  ★ 336 of prom_a's 2,950 `sub_XXXXXX` RETURN IMMEDIATELY, and 283 of them
    are nothing but one `0x0E` byte.  Two counts, because they answer two
    questions and quoting one for the other would be wrong:
      * 336 -- the routine's own body up to its first `ret` IS that `ret`, so as
        an entry point it does nothing.  The ROM byte at every one is 0x0E
        (checked on all 315 that carry an address, first and last included).
      * 283 -- the whole listed extent, label to next label, is that one `ret`:
        a one-byte object that a pointer happens to name.
    219 of the 271 one-byte objects that carry an address are reached by a `jp`
    -- prom_b's directory publishes them as entry points -- and they lie in 188
    runs of consecutive addresses, the longest eleven bytes at 0xF959BD.  ⚠ That
    is a count of ROUTINES; the count of `jp` SITES is larger and the two are
    printed separately, because conflating them is exactly the class of error
    round 1 shipped.  An earlier round found this for one
    module ("34 of the 164 published targets are a bare `ret`",
    notes/FINDINGS-prom_a-msg0716-module.md §3); it is image-wide.  --retstubs.
    ⚠ THEY ARE NOT RENAMED HERE AND THE REASON IS DELIBERATE.  `RetStub_<addr>`
      would be a FRAMED name: it moves this tree's UPPER bound by six points and
      its LOWER bound by nothing, which is the kind of gain a reviewer of round 3
      correctly called out.  Worth doing only together with the ten
      `notes/gen_prom_a_*.py` emitters that would otherwise re-emit the old
      labels; 18 of the 283 are inside an emitter's range already.  Recorded here
      so the next round can act on it with the emitters in hand.

★ A THIRD FINDING, AND IT IS ABOUT THIS TREE'S OWN PROCESS
F3  ONLY THREE OF prom_a's FIFTEEN GENERATOR-OWNED RANGES SAY SO IN THE FILE.
    `notes/gen_prom_a_*.py` rebuild about 150 KB of prom_a and every one of them
    regenerates its labels from a `semantic` dict whose fallback is `sub_%06X`.
    Three announce themselves in the listing with an `emitted by` banner; the
    other twelve do not, and the first draft of this file trusted the banner and
    asserted "no name lands inside a generator range" -- which was false for five
    of its own names.  --emitters parses the spans out of the emitters themselves
    (their `LO, HI =` constant and their `insert_region.py LO HI` line) and prints,
    for every name this round applies, which emitter would revert it and the exact
    `semantic` line that repairs it.  SEVEN of the 27 are exposed.
    ⚠ This is not a defect this round introduced: it has been true of every
      naming round since round 3, and no round has stated it.
    ⚠ The emitters are not edited here -- they are not this lane's files.

★ AND THE ANSWER TO THE ROUND'S HEADLINE QUESTION, which is a zero
    "EXISTING framed labels promoted to a real name": NONE.  All 27 names here
    are `sub_XXXXXX` -> content.  prom_a's 253 framed labels are 86 single-record
    GLYPH display lists with no text in them, 28 jump tables whose selector their
    own headers already call unknown, 25 `Ring_*_<capacity>` that are fully
    documented already and sit in an emitter's range, and 41 tables whose reader
    is known and whose index is not.  --framed prints all 51 families with the
    reason for each; the Ring_* family is flagged there as the cheapest promotion
    left in the image, for whichever round owns gen_prom_a_ringbuf_module.py.

WHAT THIS FILE DOES NOT CLAIM
    * `LCD_` names say which SERVICE the routine issues and with which
      arguments.  They do not say what the pixels mean.
    * `LCD_ScreenRedraw_Begin`/`_End` is named from ORDER: five painters call
      the blank-and-reinit one first and the layers-on one last, without
      exception (--services checks the ordering at all five shared call sites).
      It is not claimed that no other routine ever calls either.
    * `SongName_*` rests on the buffer at 0x6034CA being drawn six characters
      wide by Paint_S0ngSelectName's callee and initialised from six `_` bytes;
      "Song" is the ROM's own word from that screen's lists.  Which screens
      SHARE the buffer is not established.
    * `ShowScreen_*` claims the bracket and the painter it calls, nothing about
      input handling.
    * `Paint_` is a structural verb, not ROM text; everything after the
      underscore is quoted firmware, checked by --morphemes.
    * ⚠ One renamed label, `sub_FF76FE`, is still named in PROSE in five places
      outside prom_a (prom_b's listing and three notes files).  This lane may not
      edit those; --stale lists every site and line.

WHAT IT MOVED, measured with notes/wave7_documentation_metrics.py before and after

        prom_a   content  framed  sub_XXXX   LOWER   UPPER   headers  evidence
        before     1,429     253     2,950   30.9%   36.3%     1,083     1,175
        after      1,456     253     2,923   31.4%   36.9%     1,108     1,200

    27 renames, all `sub_XXXXXX` -> content, and 27 header blocks -- 25 of them
    new, 2 REPLACING the round-5 "SCREEN IS NOT ESTABLISHED" headers on the two
    painters this round could establish.  ⚠ 0.5 of a point on LOWER.  That is
    what four levers honestly reach on this image in one round; three quarters of
    the total came from ONE of the four, and the other two are recorded as
    rejections so a later round does not pay for them again.

RUN
    python3 notes/prom_a_understanding_round6.py --calr
    python3 notes/prom_a_understanding_round6.py --callshape
    python3 notes/prom_a_understanding_round6.py --twins
    python3 notes/prom_a_understanding_round6.py --services
    python3 notes/prom_a_understanding_round6.py --painters
    python3 notes/prom_a_understanding_round6.py --midi
    python3 notes/prom_a_understanding_round6.py --retstubs
    python3 notes/prom_a_understanding_round6.py --emitters
    python3 notes/prom_a_understanding_round6.py --stale
    python3 notes/prom_a_understanding_round6.py --framed
    python3 notes/prom_a_understanding_round6.py --morphemes
    python3 notes/prom_a_understanding_round6.py --plan
    python3 notes/prom_a_understanding_round6.py --apply       # 27 renames + headers, idempotent
    python3 notes/prom_a_understanding_round6.py --verify      # read all 27 back
    python3 notes/prom_a_understanding_round6.py --selftest    # 56 checks
"""
import bisect
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
S_A_MASTER = os.path.join(ROOT, "prom_a/wsa1_prom_a.s")   # the WRITE path: write_part() guards it
S_A = image_path(ROOT, "prom_a/wsa1_prom_a.s")  # the READ path: the image, not the master
S_B = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM_A = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
ROM_B = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")

SUB = re.compile(r'^sub_[0-9A-F]{6}$')
INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
TOPLABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR = re.compile(r';\s*([0-9A-F]{6})\s')
MNEM = re.compile(r'^(?:[A-Za-z_.][A-Za-z0-9_.]*:)?\s*(\.?[a-z_][a-z_0-9]*)\b')
BYTECOMMENT = re.compile(r';\s*[0-9A-F]{6}\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})')
RETS = ("ret", "reti", "retd")

# ★★ THE EMITTER-OWNED RANGES OF prom_a, PARSED OUT OF THE EMITTERS THEMSELVES.
# Only THREE of them announce themselves in the .s with an "emitted by" banner,
# so a lane that trusts the banner (as the first draft of this file did) believes
# prom_a has three generated ranges when it has at least ten.  Each
# notes/gen_prom_a_*.py declares its span as `LO, HI = 0x..., 0x...` and rebuilds
# every label inside it from a `semantic` dict with `sub_%06X` as the fallback --
# so a name applied to the .s inside one of these ranges is silently REVERTED the
# next time that emitter runs, and has been ever since round 3.  --emitters prints
# which of this round's names are exposed and the exact line that repairs each.
LOHI = re.compile(r'^LO,\s*HI\s*=\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', re.M)
SPLICE = re.compile(r'insert_region\.py\s+(0x[0-9A-Fa-f]+)\s+(0x[0-9A-Fa-f]+)')


def emitter_ranges():
    """[(basename, lo, hi)] for every prom_a emitter that declares a span.

    Two spellings, because the emitters use both and neither alone is complete:
    the `LO, HI =` constant (8 files) and the `insert_region.py LO HI` line in
    the RUN block of the docstring (which is the only declaration in
    gen_prom_a_drumnames.py, _ringbuf_module.py, _fdc_module.py and _splash.py).
    """
    out = []
    d = os.path.join(ROOT, "notes")
    for fn in sorted(os.listdir(d)):
        if not (fn.startswith("gen_prom_a_") and fn.endswith(".py")):
            continue
        text = open(os.path.join(d, fn)).read()
        spans = set()
        m = LOHI.search(text)
        if m:
            spans.add((int(m.group(1), 16), int(m.group(2), 16)))
        for m in SPLICE.finditer(text):
            spans.add((int(m.group(1), 16), int(m.group(2), 16)))
        for lo, hi in sorted(spans):
            out.append((fn, lo, hi))
    return out


def emitter_of(addr):
    if addr is None:
        return None
    for fn, lo, hi in emitter_ranges():
        if lo <= addr < hi:
            return fn
    return None


class Image(object):
    """prom_a / prom_b as a line list with an address per instruction line."""

    def __init__(self, tag, path, base):
        self.tag, self.base = tag, base
        self.lines = open(path).read().split("\n")
        self.addr = [None] * len(self.lines)
        for i, ln in enumerate(self.lines):
            if ln.startswith(";"):
                continue
            m = ADDR.search(ln)
            if m:
                self.addr[i] = int(m.group(1), 16)
        self.tops = [(i, TOPLABEL.match(ln).group(1))
                     for i, ln in enumerate(self.lines) if TOPLABEL.match(ln)]
        self.routines = {}
        self.order = []
        for k, (i, name) in enumerate(self.tops):
            end = self.tops[k + 1][0] if k + 1 < len(self.tops) else len(self.lines)
            ea = None
            for j in range(i, min(end, i + 12)):
                if self.addr[j] is not None:
                    ea = self.addr[j]
                    break
            self.routines[name] = (i, end, ea)
            self.order.append(name)
        self.instr_lines = sorted(i for i, a in enumerate(self.addr) if a is not None)
        self.line_of_addr = {}
        for i in self.instr_lines:
            self.line_of_addr.setdefault(self.addr[i], i)


_CACHE = {}


def images():
    if "a" not in _CACHE:
        _CACHE["a"] = Image("prom_a", S_A, 0xF80000)
        _CACHE["b"] = Image("prom_b", S_B, 0xF00000)
    return _CACHE["a"], _CACHE["b"]


def roms():
    if "rom" not in _CACHE:
        _CACHE["rom"] = (open(ROM_A, "rb").read(), open(ROM_B, "rb").read())
    return _CACHE["rom"]


def rom_byte(addr, n=1):
    ra, rb = roms()
    if 0xF80000 <= addr and addr - 0xF80000 + n <= len(ra):
        return ra[addr - 0xF80000:addr - 0xF80000 + n]
    if 0xF00000 <= addr < 0xF80000 and addr - 0xF00000 + n <= len(rb):
        return rb[addr - 0xF00000:addr - 0xF00000 + n]
    return None


def body(img, name):
    """★ The routine's own instructions, UP TO AND INCLUDING ITS FIRST `ret`.

    This is the scoping round 5's retraction demands: a label-to-next-label
    extent credits a later, UNLABELLED routine's work to this label, which is
    how `Paint_MasterTrackClear` and `Paint_C0mbinati0nM0de` were named and then
    retracted.  Returns [(addr, mnemonic, text-without-comment, line)].
    """
    i, end, _ea = img.routines[name]
    out = []
    for j in range(i, end):
        ln = img.lines[j]
        if ln.startswith(";") or not ln.strip():
            continue
        m = MNEM.match(ln)
        if not m:
            continue
        out.append((img.addr[j], m.group(1), ln.split(";")[0].strip(), j))
        if m.group(1) in RETS:
            break
    return out


def in_generated(addr):
    return emitter_of(addr) is not None


def is_content(name):
    return bool(name) and not SUB.match(name) and not INTERNAL.match(name) \
        and not name.startswith(".L")


# ---------------------------------------------------------------------------
# L0  the `calr` fix and the corrected reference census
# ---------------------------------------------------------------------------
LBL = r'(?:[A-Za-z_][A-Za-z0-9_.]*:)?\s*'
COND = r'(?:(?:z|nz|c|nc|lt|le|gt|ge|mi|pl|ov|nov|eq|ne|ugt|ult|uge|ule|NZ|Z),\s*)?'
CALLSYM = re.compile(r'^' + LBL + r'(call|calr|jp|jrl|jr)\s+' + COND +
                     r'([A-Za-z_][A-Za-z0-9_]*)\s*(?:;|$)')
CALLHEX = re.compile(r'^' + LBL + r'(call|calr|jp|jrl|jr)\s+' + COND +
                     r'\(?(0x[0-9a-fA-F]+)\)?\s*(?:;|$)')
LONGENT = re.compile(r'^' + LBL + r'\.long\s+0x([0-9a-fA-F]{8})')
CALRSYM = re.compile(r'^\s*calr\s+([A-Za-z_.][A-Za-z0-9_.]*)\s*;\s*'
                     r'([0-9A-F]{6})\s+1e ([0-9a-f]{2}) ([0-9a-f]{2})')


def calr_target(site_addr, disp):
    """TLCS-900 `calr` is 3 bytes and its displacement is signed 16-bit."""
    d = disp - 0x10000 if disp >= 0x8000 else disp
    return site_addr + 3 + d


def calr_check():
    """Prove the formula on every `calr` whose target the listing NAMES."""
    A, _B = images()
    labels = {}
    for n, (_i, _e, ea) in A.routines.items():
        if ea is not None:
            labels.setdefault(n, ea)
    for ln in A.lines:
        m = re.match(r'^(\.L[0-9A-F]{6}):', ln)
        if m:
            labels.setdefault(m.group(1), int(m.group(1)[2:], 16))
    ok = bad = unk = 0
    for ln in A.lines:
        m = CALRSYM.match(ln)
        if not m:
            continue
        name, addr = m.group(1), int(m.group(2), 16)
        disp = int(m.group(3), 16) | (int(m.group(4), 16) << 8)
        if name not in labels:
            unk += 1
            continue
        ok, bad = (ok + 1, bad) if labels[name] == calr_target(addr, disp) else (ok, bad + 1)
    return ok, bad, unk


def references():
    """prom_a routine -> [(image, site address, containing label, kind)].

    Sources: symbolic call/jp inside prom_a, absolute `call`/`jp 0xNNNNNN` in
    either image, `.long` pointer-table entries, and -- the part every earlier
    census missed -- `calr <displacement>` resolved through calr_target().
    """
    A, B = images()
    by_addr = {}
    for n, (_i, _e, ea) in A.routines.items():
        if ea is not None:
            by_addr.setdefault(ea, n)
    refs = collections.defaultdict(list)
    counts = collections.Counter()
    for img in (A, B):
        cur = None
        for i, ln in enumerate(img.lines):
            m = TOPLABEL.match(ln)
            if m:
                cur = m.group(1)
            ms = CALLSYM.match(ln)
            if ms:
                if img is A and ms.group(2) in A.routines:
                    refs[ms.group(2)].append((img.tag, img.addr[i], cur, ms.group(1)))
                    counts["symbolic"] += 1
                continue
            mh = CALLHEX.match(ln)
            if mh:
                kind, v = mh.group(1), int(mh.group(2), 16)
                if kind in ("call", "jp"):
                    tgt = v
                    counts["absolute"] += 1
                elif kind == "calr" and img.addr[i] is not None:
                    tgt = calr_target(img.addr[i], v)
                    counts["calr"] += 1
                else:
                    continue
                if tgt in by_addr:
                    refs[by_addr[tgt]].append((img.tag, img.addr[i], cur, kind))
                continue
            ml = LONGENT.match(ln)
            if ml:
                v = int(ml.group(1), 16) & 0xFFFFFF
                if v in by_addr:
                    refs[by_addr[v]].append((img.tag, img.addr[i], cur, ".long"))
                    counts["long"] += 1
    return dict(refs), counts


def subs():
    A, _B = images()
    return [n for n in A.order if SUB.match(n)]


def candidates():
    """★ The population every lever is measured over: prom_a's `sub_XXXXXX`
    PLUS the labels this round renamed.  Without the second half every count in
    --selftest would FALL when --apply runs, which is a check that punishes the
    work it is supposed to certify -- the exact trap
    notes/wave7_documentation_metrics.py documents in its own selftest."""
    A, _B = images()
    return subs() + [n for _o, n, _w, _y in NAMES if n in A.routines]


def current_label(old):
    """`old` if --apply has not run for it, otherwise the name it now carries."""
    A, _B = images()
    for o, n, _w, _y in NAMES:
        if o == old:
            return n if n in A.routines else o
    return old


# ---------------------------------------------------------------------------
# L4  the display-list walker, over the ROM rather than over prom_b's labels
# ---------------------------------------------------------------------------
# Record format and the two text handlers: notes/FINDINGS-ui-display-list.md.
#   +0 opcode (bound 0x24)   +1 length of the WHOLE record
#   handler 0xF31A3A, opcodes 06 07 08 16 18 19 1A 1D 1E 1F 20 21 -> chars at +4
#   handler 0xF31A52, opcodes 17 1C                               -> chars at +6
TEXT_AT_4 = {0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E, 0x1F, 0x20, 0x21}
TEXT_AT_6 = {0x17, 0x1C}


def dl_walk(lo, hi, limit=400):
    """Walk interpreter A's records from lo to hi. Returns (records, frames)."""
    recs, a, n = [], lo, 0
    while a < hi and n < limit:
        b = rom_byte(a, 2)
        if b is None:
            return recs, False
        op, ln = b[0], b[1]
        if ln == 0 or op >= 0x24:
            return recs, False
        txt = None
        if op in TEXT_AT_4 and ln > 4:
            txt = rom_byte(a + 4, ln - 4)
        elif op in TEXT_AT_6 and ln > 6:
            txt = rom_byte(a + 6, ln - 6)
        recs.append((a, op, ln, txt))
        a += ln
        n += 1
    return recs, (a == hi)


def dl_text(lo, hi):
    """The printable strings a list draws, in record order, and whether it frames."""
    recs, ok = dl_walk(lo, hi)
    out = []
    for _a, _op, _ln, t in recs:
        if t is None:
            continue
        s = "".join(chr(c) for c in t if 0x20 <= c < 0x7F)
        if s.strip():
            out.append(s)
    return out, ok


def painters():
    """Every sub_XXXXXX that reaches a display-list interpreter BEFORE its own
    first `ret`, with the (XIY, XIX) bounds of each site."""
    A, _B = images()
    out = {}
    for s in candidates():
        c = body(A, s)
        if not c or c[-1][1] not in RETS:
            continue
        sites, xiy, xix = [], None, None
        for a, _mn, txt, _j in c:
            m = re.match(r'^ld\s+XIY,\s*0x([0-9a-fA-F]+)', txt)
            if m:
                xiy = int(m.group(1), 16) & 0xFFFFFF
            m = re.match(r'^ld\s+XIX,\s*0x([0-9a-fA-F]+)', txt)
            if m:
                xix = int(m.group(1), 16) & 0xFFFFFF
            m = re.match(r'^call\s+0xf417f([04])', txt)
            if m:
                sites.append((a, "A" if m.group(1) == "0" else "B", xiy, xix))
        if sites:
            out[s] = (sites, len(c))
    return out


def painter_text():
    """The painters whose interpreter-A lists FRAME and carry text."""
    got = {}
    for s, (sites, _n) in painters().items():
        rows = []
        for a, interp, lo, hi in sites:
            if interp != "A" or lo is None or hi is None or hi <= lo or hi - lo > 4096:
                continue
            t, ok = dl_text(lo, hi)
            if ok and t:
                rows.append((a, lo, hi, t))
        if rows:
            got[s] = rows
    return got


# ---------------------------------------------------------------------------
# L3  the SWI7 graphics-service wrappers
# ---------------------------------------------------------------------------
SERVICE = {
    0x02: ("LCD_Svc_02_DrawVLine", "a solid vertical run of pixels"),
    0x05: ("LCD_Svc_05_FillRect", "fill the rectangle in (0x2530..0x2536)"),
    0x06: ("LCD_Svc_06_DrawText8x14", "draw 8x14 text"),
    0x08: ("LCD_Svc_08_DrawText16x16", "draw 16x16 text"),
    0x09: ("LCD_Svc_09_DrawBox", "outline the rectangle in (0x2530..0x2536)"),
    0x0C: ("LCD_Svc_0C_SetLayersOn", "rebuild DISP ON: C bits 0/1/2 = layers 1/2/3 steady on"),
    0x0E: ("LCD_Svc_0E_ClearColumns", "zero BC columns x HL bytes at IY in the current layer"),
    0x10: ("LCD_Svc_10_SetPanel3Layer", "re-issue SYSTEM SET for a three-layer panel"),
    0x1B: ("LCD_Svc_1B_EraseRect", "erase the rectangle in (0x2530..0x2536)"),
    0x1E: ("LCD_Svc_1E_ScrollCurrentLayer", "move the current layer's window"),
}


def swi7_wrappers():
    """sub_XXXXXX that issue `swi 7` before their own first `ret`."""
    A, _B = images()
    out = []
    for s in candidates():
        c = body(A, s)
        if not c or c[-1][1] not in RETS:
            continue
        svc = []
        for k, (a, _mn, txt, _j) in enumerate(c):
            if not re.match(r'^swi\s+7\b', txt):
                continue
            v = None
            for kk in range(k - 1, -1, -1):
                if re.match(r'^swi\s+7\b', c[kk][2]):
                    break
                m = re.match(r'^ldb?\s+[aA],\s*0x([0-9a-fA-F]+)', c[kk][2])
                if m:
                    v = int(m.group(1), 16)
                    break
            svc.append((a, v))
        if svc:
            # "all-immediate" = no `ld <reg>,(0xNNNN)` feeding the call
            loads = [t for _a, _m, t, _j in c
                     if re.match(r'^(ldb?_d8|ldb?_da|ldw_d16|ldw_da|ldl_da|ldda32)\s', t)]
            out.append((s, c, svc, len(loads)))
    return out


# ---------------------------------------------------------------------------
# THE NAMES.  Every one carries the mechanism that produced it.  `what` is the
# one-line header title; `why` becomes the Evidence: block.  Nothing here is
# inferred from a routine's neighbours or from a caller's name alone.
# ---------------------------------------------------------------------------
NAMES = [
    # --- L3: SWI7 service wrappers whose arguments are all immediates --------
    ("sub_F999F0", "LCD_ScreenRedraw_Begin",
     "blank the panel, re-issue SYSTEM SET, select layer 0",
     "its four instructions before the `ret` are `ld C,0x00` + service 0x0C, then\n"
     "service 0x10, then `ld (0x2540),0x00`.  Service 0x0C REBUILDS the DISP ON\n"
     "byte from C, so C = 0 turns all three layers off and sets bit 0 of (0xC6),\n"
     "the driver's do-not-poll-BUSY flag; 0x10 re-issues SYSTEM SET for a\n"
     "three-layer panel; (0x2540) is the current-layer number.  It is called\n"
     "FIRST by every one of its callers and LCD_ScreenRedraw_End LAST by the same\n"
     "callers -- checked at all ten sites by --services."),
    ("sub_F999FE", "LCD_ScreenRedraw_End",
     "make all three layers visible again",
     "`ld C,0x07` + `ld A,0x0C` + `swi 7` + `ret`, six bytes.  In service 0x0C's\n"
     "own documented convention C bits 0/1/2 select layers 1/2/3, so 0x07 is all\n"
     "three steady on, and a non-zero DISP byte also clears (0xC6) bit 0.  It is\n"
     "the LAST call of each of its four callers."),
    ("sub_FE80F7", "LCD_ScreenRedraw_Begin_Copy",
     "a second, byte-identical copy of LCD_ScreenRedraw_Begin",
     "the fourteen ROM bytes at 0xFE80F7 equal the fourteen at 0xF999F0 exactly\n"
     "(checked byte for byte by --selftest).  Its one caller, Paint_Sequencer,\n"
     "calls it at 0xFE8130 and the End copy at 0xFE8161, in that order."),
    ("sub_FE8105", "LCD_ScreenRedraw_End_Copy",
     "a second, byte-identical copy of LCD_ScreenRedraw_End",
     "the six ROM bytes at 0xFE8105 equal the six at 0xF999FE exactly."),
    ("sub_FF7615", "LCD_ShowAllThreeLayers_SaveRegs",
     "service 0x0C with C = 7, with four registers preserved",
     "`push XIZ/XIX/XHL/XDE`, `ld C,0x07`, service 0x0C, then the four pops.\n"
     "Same effect as LCD_ScreenRedraw_End; the pushes are what distinguish it."),
    ("sub_F9C02E", "LCD_ShowLayers1And2_SaveRegs",
     "service 0x0C with C = 3 -- layers 1 and 2 on, layer 3 off",
     "identical in shape to LCD_ShowAllThreeLayers_SaveRegs except for the\n"
     "immediate: `ld C,0x03`, so bits 0 and 1 are set and bit 2 is not.  Service\n"
     "0x0C rebuilds the whole DISP byte, so layer 3 is turned OFF here, not left\n"
     "alone -- that is the documented difference between services 0x0C and 0x0D."),
    ("sub_F941F4", "LCD_ScrollLayer0_Back3Lines",
     "hardware-scroll layer 0 back by three scan lines",
     "`ld (0x2540),0x00` selects layer 0; `ld C,0x40` + `or C,0x03` makes C =\n"
     "0x43; service 0x1E reads bits 7:6 as the arm and bits 3:0 as the amount,\n"
     "and arm 0x40 is `base := base - n*0x28` with 0x28 = AP = 40 bytes per scan\n"
     "line.  n = 3.  ★ Service 0x1E's own header says `Unknown: callers`; this\n"
     "routine and LCD_ScrollLayer2_Forward3Lines are two of them."),
    ("sub_F94202", "LCD_ScrollLayer2_Forward3Lines",
     "hardware-scroll layer 2 forward by three scan lines",
     "`ld (0x2540),0x02`, then C = 0x00 | 0x03 = 0x03: arm 0x00 of service 0x1E is\n"
     "`base := base + n*0x28`, n = 3.  Same routine as the one above with the two\n"
     "immediates changed, which is what makes the pair readable."),
    ("sub_F9347C", "LCD_ClearLayer0_Rows29To235",
     "zero the full width of layer 0 from row 29 to row 235",
     "`ld (0x2540),0x00`, `ld IY,0x0488`, `ld BC,0x0028`, `ld HL,0x00CF`, service\n"
     "0x0E.  Service 0x0E takes IY as a byte offset inside the current layer, BC\n"
     "as columns and HL as bytes down each column.  AP is 40 = 0x28, so BC = 40\n"
     "is the full 320-pixel width and 0x0488 = 1160 = 29 x 40 EXACTLY -- the\n"
     "offset is the start of row 29.  0xCF = 207 rows, so the last row cleared is\n"
     "235.  ★ Service 0x0E's header also says `Unknown: callers`."),
    ("sub_F81E6A", "LCD_ClearLayer2_32Cols10Rows",
     "zero a 32-column by 10-row block of layer 2 at the caller's IY",
     "`ld (0x2540),0x02`, `ld BC,0x0020`, `ld HL,0x000A`, service 0x0E.  IY is NOT\n"
     "loaded anywhere in the body, so the block's position is the caller's and\n"
     "only its SIZE is fixed here: 32 byte-columns = 256 pixels wide, 10 rows."),
    ("sub_F9348E", "LCD_EraseLayer1_FixedRect",
     "erase one compile-time rectangle of layer 1",
     "`ld (0x2540),0x01` then the four coordinate words written as immediates --\n"
     "(0x2530)=0x000D, (0x2532)=0x0022, (0x2534)=0x0132, (0x2536)=0x00A7 -- and\n"
     "service 0x1B, which erases the rectangle those four words hold.  So the\n"
     "rectangle is x 13..306, y 34..167 and nothing about it comes from the\n"
     "caller.  ★ Service 0x1B's header says `Unknown: callers`."),
    ("sub_FF01F2", "LCD_FillRect_Grown2Rows",
     "grow the pending rectangle by two rows each way and fill it",
     "`sub (0x2532),0x0002` and `add (0x2536),0x0002` move Y0 up and Y1 down by\n"
     "two before service 0x05 fills (0x2530..0x2536).  This routine's own\n"
     "instructions never touch X0 or X1, so all IT contributes is four rows of\n"
     "height.  ⚠ Where the rectangle comes from is NOT established: the `calr`\n"
     "at 0xFF01F2 resolves to sub_FF0092, which this round did not trace."),
    ("sub_FF76FE", "LCD_DrawText8x14_Layer0_SaveRegs",
     "draw the caller's 8x14 string on layer 0, preserving four registers",
     "`push WA/BC/XIY/XIX`, `ld (0x2540),0x00`, service 0x06, then the four pops.\n"
     "None of XIY, BC, HL or IX is loaded in the body, so every argument of the\n"
     "text service is the caller's; the routine contributes the layer and the\n"
     "register discipline."),
    ("sub_F94210", "LCD_DrawAllInitialSettingMessage",
     "draw the 20-character message ALL INITIAL SETTING! and light layer 1",
     "`ld XIY,0x00F9422C` + `ld BC,0x0014` + `ld IX,0x07D0` + service 0x08, and\n"
     "the twenty ROM bytes at 0xF9422C are the ASCII `ALL INITIAL SETTING!`\n"
     "(checked byte for byte by --selftest).  It then issues service 0x0C with\n"
     "C = 1, leaving layer 1 alone visible.  Every morpheme of the name is that\n"
     "ROM string; `Draw` and `Message` are structural."),
    ("sub_FEFE69", "LCD_DrawVRuleLeft_Layer1",
     "a vertical rule on layer 1 whose column tracks (0x601F54)",
     "`ld (0x2540),0x01`; (0x2532)=0x0029 and (0x2536)=0x00A8 fix the ends;\n"
     "X0 and X1 are BOTH set to (0x601F54)/4 + 0x10, so the rectangle is one\n"
     "pixel wide, and service 0x02 draws a vertical run.  `Left` is relative to\n"
     "LCD_DrawVRuleRight_Layer1 below, which adds 0x59 to the same quantity."),
    ("sub_FEFE94", "LCD_DrawVRuleRight_Layer1",
     "the companion vertical rule, 73 pixels to the right",
     "the same nine instructions as LCD_DrawVRuleLeft_Layer1 with three\n"
     "immediates changed: Y0 0x2A, Y1 0xA1, and X = (0x601F54)/4 + 0x59.  0x59 -\n"
     "0x10 = 0x49 = 73, which is what `Right` claims and all it claims."),
    # --- L3: what the routine touches, on a RAM buffer the tree already reads -
    ("sub_F8165E", "SongName_Draw6Chars",
     "draw the six-character name buffer at 0x6034CA",
     "`ld HL,0x0000` + `ld BC,0x0006` + `ld XIY,0x006034CA` + `ld IX,0x0998` +\n"
     "service 0x08, the 16x16 text service, so it draws six characters from that\n"
     "buffer at screen offset 0x998.  The buffer is six bytes wide because\n"
     "SongName_ResetToUnderscores fills it with the six ROM bytes at 0xF81948,\n"
     "which are `5F 5F 5F 5F 5F 5F` = `______`, and the 37 characters that can\n"
     "stand in it are CharSet_F81768 = `_` + `A`-`Z` + `0`-`9`.  `Song` is the\n"
     "ROM's own word: this routine's caller at 0xF80E71 is Paint_S0ngSelectName."),
    ("sub_F818EA", "SongName_ResetToUnderscores",
     "blank all three copies of the six-character name buffer",
     "three `ldir` runs of BC = 6 from the same source 0xF81948 (`______`) to\n"
     "0x006034CA, to 0x00610000 + ((0x360A) << 11) + ((0x360A) << 10) + 0xCA, and\n"
     "to 0x0012F6.  The destinations are read straight off the three `ld XIX`\n"
     "sequences; that the second is indexed by (0x360A) is why this routine, and\n"
     "not the drawer, is where the buffer's aliases are visible."),
    ("sub_F81E17", "LCD_DrawEndOrClear",
     "draw END on layer 2, or clear the three blocks it would stand in",
     "the arm at 0xF81E4E is `ld (0x2540),0x02` + `ld XIY,0x00F81E79` +\n"
     "`ld BC,0x0003` + service 0x06, and the three ROM bytes at 0xF81E79 are\n"
     "`45 4E 44` = `END` (checked by --selftest).  The other arm calls\n"
     "LCD_ClearLayer2_32Cols10Rows three times, with IY = 0x0821, 0x0F29 and\n"
     "0x1631.  Which arm runs is decided by (0x1075) and (0x1076) both being\n"
     "non-zero; what those two counters COUNT is not established."),
    ("sub_F94C2B", "LCD_BlankThenSetPanel2Layer",
     "blank the panel and re-issue SYSTEM SET for TWO layers",
     "`xor C,C` + service 0x0C blanks; service 0x0F follows.  0x0F is the\n"
     "TWO-layer SYSTEM SET and 0x10 the three-layer one, which is the whole\n"
     "difference between this routine and LCD_ScreenRedraw_Begin -- the pair is\n"
     "why the layer count belongs in both names."),
    ("sub_F94C3C", "LCD_ShowLayers1And2_StackFrame",
     "service 0x0C with C = 3, from inside a stack frame",
     "same three instructions as LCD_ShowLayers1And2_SaveRegs (`ld C,0x03`,\n"
     "service 0x0C) but preceded by `push XIZ` + `ld XIZ,XSP`, so it builds a\n"
     "frame the other one does not.  The two are NOT byte-identical and are not\n"
     "named as copies of each other."),
    ("sub_F94D82", "LCD_PrintLine40_AdvanceRow",
     "draw a 40-character line at the cursor and advance the cursor one row",
     "`ld HL,0x0000` + `ld BC,0x0028` + `ld IX,(0x284F)` + service 0x06, then\n"
     "`add (0x284F),0x01B8`.  BC = 40 characters; the cursor is the RAM word\n"
     "(0x284F); and 0x01B8 = 440 = 11 x 40, i.e. eleven scan lines at AP = 40,\n"
     "the height of one 8x14 row plus leading.  XIY, the string, is the\n"
     "caller's."),
    ("sub_F94DBD", "LCD_FlashWholePanel",
     "blank, fill the whole panel, show it, blank again",
     "the four coordinate words are written as immediates -- (0x2530)=0,\n"
     "(0x2532)=0, (0x2534)=0x013F, (0x2536)=0x00EF -- which is exactly the\n"
     "320x240 panel SYSTEM SET programs, so the service-0x05 fill covers all of\n"
     "it.  It is bracketed by service 0x0C with C = 0, then C = 7, then C = 0,\n"
     "with sub_F95128 called after each of the last two."),
    ("sub_FE836F", "ShowScreen_NoteEditPartSelect",
     "blank, re-init the panel, run the NOTE EDIT part-select painter, show it",
     "`xor C,C` + service 0x0C, service 0x10, then `calr Paint_NoteEditPartSelect`\n"
     "-- a name this tree already carries -- and finally `ld C,0x07` + service\n"
     "0x0C.  The bracket is LCD_ScreenRedraw_Begin's and _End's, written out\n"
     "inline.  ⚠ It also clears bit 0 of (0x601F70); what that bit selects is not\n"
     "established, and ShowScreen_DrumEditPartSelect SETS the same bit."),
    ("sub_FE83A3", "ShowScreen_DrumEditPartSelect",
     "the same sequence around the DRUM EDIT part-select painter",
     "identical in shape to ShowScreen_NoteEditPartSelect, calling\n"
     "Paint_DrumEditPartSelect instead, and SETTING bit 0 of (0x601F70) where\n"
     "the other clears it.  It also clears bit 0 of (0x601F77), which the note\n"
     "one does not touch."),
    # --- L4: display-list painters, text walked out of the ROM ---------------
    ("sub_F99A04", "Paint_SysexBulkDump",
     "paint the SYSEX BULK DUMP menu",
     "one interpreter-A site at 0xF99A3D, list 0xF0D6AF-0xF0D77F, which FRAMES\n"
     "exactly and whose text records read `SYSEX BULK DUMP`, `MIDI`,\n"
     "` TOTAL KEYBOARD`, ` SEND`, ` SOUND`, ` COMBINATION`,\n"
     "` SYSTEM,PART & MIDI`.  ⚠ 0xF0D6AF carries NO label in prom_b's listing --\n"
     "it is inside a span that is still `.incbin` -- so round 5's label-based\n"
     "painter rule could not see it.  The text is walked out of\n"
     "original_ROMs/wsa1_prom_b.ic13 by this file's dl_walk(); --selftest checks\n"
     "both the framing and the absence of the label.\n"
     "⚠⚠ THIS CORRECTS THE HEADER ROUND 5 LEFT HERE, which said `Not one of these\n"
     "lists holds an .ascii record`.  It does: seven text records, quoted above.\n"
     "The claim was true of the LABELS round 5 could search and false of the ROM.\n"
     "The bounds themselves are derived exactly as round 5 derived them -- the\n"
     "LAST `ld XIY,imm32` and `ld XIX,imm32` before the cited `call`, with\n"
     "0xF417F0 entering interpreter A and 0xF417F4 interpreter B\n"
     "(notes/FINDINGS-ui-display-list.md)."),
    ("sub_F99C5C", "Paint_SysPartMidiSoundCombination",
     "paint the three-row label block of that menu",
     "one interpreter-A site at 0xF99C76, list 0xF0D7E2-0xF0D81B, which FRAMES\n"
     "exactly and draws `SYS,PART&MIDI :`, `SOUND         :` and\n"
     "`COMBINATION   :`.  Every morpheme of the name is in that text.  ⚠ What the\n"
     "three rows' VALUES are is not established -- they are drawn elsewhere.\n"
     "⚠⚠ THIS TOO CORRECTS ROUND 5's `Not one of these lists holds an .ascii\n"
     "record` on this label; it holds three."),
]

# The four unreachable Control Change slots (F1). No names; headers only.
MIDI_DEAD = {
    "sub_FA64E5": 8,
    "sub_FA6526": 9,
    "sub_FA6459": 16,
    "sub_FA645A": 17,
}
MIDI_INDEX_TABLE = 0xFA83E8


# ---------------------------------------------------------------------------
# reporting modes
# ---------------------------------------------------------------------------
def mode_calr():
    ok, bad, unk = calr_check()
    print("`calr <target>` lines whose target the listing NAMES: %d" % (ok + bad + unk))
    print("  formula  target = site + 3 + signed16(displacement)")
    print("  agree %d   disagree %d   label not resolvable %d" % (ok, bad, unk))
    refs, counts = references()
    print("\nreference sites found, by spelling: %s"
          % dict(sorted(counts.items(), key=lambda kv: -kv[1])))
    hist = collections.Counter(min(len(refs.get(s, [])), 8) for s in subs())
    print("\nprom_a sub_XXXXXX by number of references (8 = eight or more):")
    for k in sorted(hist):
        print("   %d: %5d" % (k, hist[k]))
    print("\n★ WITHOUT the calr resolution the zero-reference count is 805; with it, %d."
          % hist[0])


def mode_callshape():
    """L1: do a routine's callers agree on what they set up?"""
    A, B = images()
    refs, _c = references()
    IM = {"prom_a": A, "prom_b": B}
    SET = re.compile(r'^(ld|ldb|ldw|lda|lda_24|ldl)\s+([A-Za-z_0-9]+),\s*(0x[0-9a-fA-F]+)')

    def before(tag, addr, k=4):
        img = IM[tag]
        ln = img.line_of_addr.get(addr)
        if ln is None:
            return []
        p = bisect.bisect_left(img.instr_lines, ln)
        return [img.lines[img.instr_lines[q]].split(";")[0].strip()
                for q in range(max(0, p - k), p)]

    multi, agree = 0, []
    pop = candidates()
    for s in pop:
        rs = [r for r in refs.get(s, []) if r[3] in ("call", "calr", "jp", "jrl")]
        if len(rs) < 2:
            continue
        multi += 1
        sets = []
        for tag, addr, _caller, _kind in rs:
            d = {}
            for t in before(tag, addr):
                m = SET.match(t)
                if m:
                    d.setdefault(m.group(2).upper(), m.group(3).lower())
            sets.append(d)
        keys = set(sets[0])
        for d in sets[1:]:
            keys &= set(d)
        common = {k: sets[0][k] for k in keys if len(set(d[k] for d in sets)) == 1}
        if common:
            agree.append((s, len(rs), common))
    print("L1  CALL-SITE SHAPE AT SCALE")
    print("  routines measured (prom_a sub_XXXXXX + this round's names) %d" % len(pop))
    print("  ... with two or more call sites .................. %d" % multi)
    print("  ... whose sites ALL load the same register with")
    print("      the same immediate .......................... %d" % len(agree))
    for s, n, c in agree:
        print("        %-14s x%-3d %s" % (s, n, c))
    print("\n  ⚠ REJECTED as a naming lever: %.1f%% of the %d.  A caller shape needs"
          % (100.0 * len(agree) / len(pop), len(pop)))
    print("    callers that agree, and %d of the routines have fewer than two."
          % (len(pop) - multi))


def mode_twins():
    """L2: byte-identical routines inside prom_a, entry to first `ret`."""
    A, _B = images()
    buckets = collections.defaultdict(list)
    sized = 0
    for n in A.order:
        c = body(A, n)
        if not c or c[-1][1] not in RETS or c[0][0] is None or c[-1][0] is None:
            continue
        mb = BYTECOMMENT.search(A.lines[c[-1][3]])
        lo, hi = c[0][0], c[-1][0] + (len(mb.group(1).split()) if mb else 1)
        if hi - lo < 6 or hi - lo > 4096:
            continue
        by = rom_byte(lo, hi - lo)
        if by is None:
            continue
        sized += 1
        buckets[by].append(n)
    mixed = [(len(k), v) for k, v in buckets.items()
             if len(v) > 1 and any(is_content(x) for x in v) and any(SUB.match(x) for x in v)]
    groups = [v for v in buckets.values() if len(v) > 1]
    print("L2  BYTE-IDENTICAL TWINS INSIDE prom_a")
    print("  routines measured (entry .. first ret, 6..4096 bytes) .. %d" % sized)
    print("  groups of two or more identical routines ............... %d" % len(groups))
    print("  ... that mix a CONTENT name with a sub_XXXXXX .......... %d" % len(mixed))
    for L, v in mixed:
        print("        %4d B  %s" % (L, v))
    print("\n  ⚠ REJECTED, reach 0.  Round 5 spent the prom_a/prom_c twin search;")
    print("    the same idea inside prom_a is spent too.")


def mode_services():
    """L3: the SWI7 wrappers, named and not named."""
    refs, _c = references()
    rows = swi7_wrappers()
    named = {}
    for o, n, _w, _y in NAMES:
        named[o] = n
        named[n] = n          # after --apply the label IS the new name
    print("L3  WHAT THE ROUTINE TOUCHES -- the SWI7 graphics API")
    print("  sub_XXXXXX reaching `swi 7` before their own first `ret` ... %d" % len(rows))
    short = [r for r in rows if len(r[1]) <= 12 and all(v is not None for _a, v in r[2])]
    print("  ... <= 12 instructions with every service number resolved .. %d" % len(short))
    print("  ... named by this round ..................................... %d"
          % sum(1 for r in short if r[0] in named))
    for s, c, svc, loads in short:
        tag = named.get(s, "-- KEEPS sub_XXXXXX --")
        print("    %-14s %2d instr  loads=%d  svc=%s"
              % (s, len(c), loads,
                 ",".join("0x%02X@%06X" % (v, a) for a, v in svc)))
        print("        -> %s" % tag)
    print("\n  the three that keep sub_XXXXXX, and why:")
    print("    sub_FEB03D  its rectangle's Y is 10*(0x601F73)+0x2A -- a row INDEX")
    print("                whose meaning is not established, so `what it fills` is not")
    print("                sayable without naming that variable.")
    print("    sub_FF0178  TWO service-0x05 fills bracketing two `calr` sites this round")
    print("                did not trace; what the PAIR draws is not established, and one")
    print("                fill alone would be half the claim.")
    print("    sub_FEFFF3  its service 0x09 box is preceded by a branch on bit 0 of")
    print("                (0x601F70) choosing between two unlabelled setups.")
    # the ordering claim behind ScreenRedraw_Begin/_End
    print("\n  the ordering check behind LCD_ScreenRedraw_Begin / _End:")
    pairs = (("sub_F999F0", "sub_F999FE"), ("sub_FE80F7", "sub_FE8105"))
    for b, e in pairs:
        bs = {r[2]: r[1] for r in refs.get(current_label(b), [])}
        es = {r[2]: r[1] for r in refs.get(current_label(e), [])}
        for caller in sorted(set(bs) & set(es)):
            print("    %-34s begin 0x%06X < end 0x%06X  %s"
                  % (caller, bs[caller], es[caller], "OK" if bs[caller] < es[caller] else "NO"))


def mode_painters():
    stats = collections.Counter()
    P = painters()
    for _s, (sites, _n) in P.items():
        for _a, interp, lo, hi in sites:
            stats["sites_" + interp] += 1
            if lo is None or hi is None or hi <= lo:
                stats["unresolved"] += 1
                continue
            if interp != "A":
                continue
            t, ok = dl_walk(lo, hi)
            stats["A_frames" if ok else "A_does_not_frame"] += 1
            if ok:
                txt, _ = dl_text(lo, hi)
                stats["A_frames_with_text" if txt else "A_frames_no_text"] += 1
    got = painter_text()
    print("L4  DISPLAY-LIST PAINTERS, lists walked out of original_ROMs/")
    print("  sub_XXXXXX reaching an interpreter before their own first `ret` .. %d" % len(P))
    for k in sorted(stats):
        print("    %-22s %d" % (k, stats[k]))
    print("  painters with at least one framing interpreter-A list that has text: %d"
          % len(got))
    for s in sorted(got):
        print("    %s" % s)
        for a, lo, hi, t in got[s]:
            print("      site 0x%06X  list 0x%06X-0x%06X  %s"
                  % (a, lo, hi, "; ".join('"%s"' % x for x in t)))
    print("\n  five of the seven are the ones round 5 already refused BY NAME")
    print("  (0xF80384 ALL/TRACK, 0xF9291F USR1/USR2, 0xF929DB and 0xF92A10 the same")
    print("  R0M1/EXT1 list, 0xF931A4 a single '-').  Two are new and are named.")
    print("\n  ★ AND THE CHECK THAT MATTERS: with the extent taken to the next LABEL")
    print("  instead of to the routine's own `ret`, this same code proposes")
    print("  0xF81AB5 and 0xF9167C -- the two names ROUND 5 RETRACTED -- and three")
    print("  more.  --selftest asserts that the ret-scoped run does NOT reach them.")


def mode_midi():
    """F1: re-derive the reachable set of MidiIn_ControllerHandlerTable."""
    A, B = images()
    tbl = rom_byte(MIDI_INDEX_TABLE, 128)
    live = [(cc, tbl[cc]) for cc in range(128) if tbl[cc] != 0xFF]
    idx = sorted(set(v for _cc, v in live))
    print("F1  MidiIn_ControllerNumberToIndex at 0x%06X, 128 bytes" % MIDI_INDEX_TABLE)
    print("  controller numbers that map anywhere: %d" % len(live))
    for cc, v in live:
        print("     CC 0x%02X (%3d) -> index %d" % (cc, cc, v))
    print("  reachable indices: %s" % idx)
    for s, slot in sorted(MIDI_DEAD.items(), key=lambda kv: kv[1]):
        print("  slot %2d -> %-12s reachable=%s" % (slot, s, slot in idx))
    for img in (A, B):
        w = [img.addr[i] for i, ln in enumerate(img.lines)
             if not ln.startswith(";") and re.search(r'\(0x1963\),\s*[aA]\b', ln)]
        r = [img.addr[i] for i, ln in enumerate(img.lines)
             if not ln.startswith(";") and re.search(r'[aA],\s*\(0x1963\)', ln)]
        print("  %s: (0x1963) written at %s, read at %s"
              % (img.tag, ["0x%06X" % x for x in w], ["0x%06X" % x for x in r]))
    refs, _c = references()
    for s in sorted(MIDI_DEAD):
        print("  %-12s references: %s"
              % (s, [(x[0], "0x%06X" % x[1], x[2], x[3]) for x in refs.get(s, [])]))


def retstubs(strict=False):
    """F2: sub_XXXXXX that return immediately.

    strict=False -- the routine's own body up to its first `ret` IS that `ret`.
    strict=True  -- the WHOLE listed extent, label to next label, is that `ret`,
                    i.e. a one-byte object.  The two counts are different
                    questions and this file prints both rather than one.
    """
    A, _B = images()
    out = []
    for s in subs():
        c = body(A, s)
        if [x[1] for x in c] != ["ret"]:
            continue
        if strict:
            i, end, _ea = A.routines[s]
            n = 0
            for j in range(i, end):
                ln = A.lines[j]
                if ln.startswith(";") or not ln.strip():
                    continue
                if MNEM.match(ln):
                    n += 1
            if n != 1:
                continue
        a = A.routines[s][2]
        out.append((s, a, (rom_byte(a, 1)[0] if a is not None else None)))
    return out


def mode_retstubs():
    refs, _c = references()
    rows = retstubs()
    strict = retstubs(strict=True)
    withaddr = [r for r in rows if r[1] is not None]
    print("F2  sub_XXXXXX THAT RETURN IMMEDIATELY")
    print("  entry point does nothing (body to first ret IS the ret) ... %d of %d"
          % (len(rows), len(subs())))
    print("  the WHOLE listed extent is that one ret ..................... %d" % len(strict))
    print("  with an address in the listing .............. %d" % len(withaddr))
    print("  whose ROM byte really is 0x0E ............... %d"
          % sum(1 for _s, _a, b in withaddr if b == 0x0E))
    print("  referenced at all ........................... %d"
          % sum(1 for s, _a, _b in withaddr if refs.get(s)))
    kinds = collections.Counter()
    for s, _a, _b in withaddr:
        for r in refs.get(s, []):
            kinds[r[3]] += 1
    print("  reference SITES by spelling ................. %s" % dict(kinds))
    print("  one-byte objects reached by a `jp` (ROUTINES) %d"
          % sum(1 for _s, a, _b in strict if a is not None
                and any(r[3] == "jp" for r in refs.get(_s, []))))
    print("  inside a generator-emitted range ............ %d"
          % sum(1 for _s, a, _b in withaddr if in_generated(a)))
    addrs = sorted(a for _s, a, _b in strict if a is not None)
    runs, cur = [], [addrs[0]]
    for a in addrs[1:]:
        if a == cur[-1] + 1:
            cur.append(a)
        else:
            runs.append(cur)
            cur = [a]
    runs.append(cur)
    print("  runs of consecutive addresses ............... %d" % len(runs))
    print("  longest runs ................................ %s"
          % sorted((("0x%06X" % r[0], len(r)) for r in runs), key=lambda x: -x[1])[:5])
    print("\n  ⚠ NOT RENAMED.  `RetStub_<addr>` is a FRAMED name: it would move this")
    print("    image's UPPER bound by about six points and its LOWER bound by nothing,")
    print("    and %d of them sit inside a gen_prom_a_*.py range that would re-emit the"
          % sum(1 for _s, a, _b in withaddr if in_generated(a)))
    print("    old label.  Do it in a round that owns the emitters too.")


def mode_morphemes():
    """Every alphabetic morpheme of a Paint_ name must occur in the ROM text
    its own lists draw.  Round 3 of this wave invented the morpheme `Home`,
    which occurs zero times in all four images; this is what forbids that."""
    got = painter_text()
    ok = True
    for old, new, _w, _y in NAMES:
        if not new.startswith("Paint_"):
            continue
        text = " ".join(x for _a, _lo, _hi, t in got.get(current_label(old), [])
                        for x in t).upper()
        parts = re.findall(r'[A-Z][a-z0-9]*|[A-Z0-9]+', new[len("Paint_"):])
        for p in parts:
            hit = p.upper() in text
            print("  %-34s morpheme %-16s in its own list text: %s"
                  % (new, p, "yes" if hit else "NO"))
            ok = ok and hit
    print("  all morphemes present: %s" % ok)
    return ok


def mode_plan():
    A, _B = images()
    refs, _c = references()
    print("%-14s -> %-36s %s" % ("old", "new", "sites"))
    for old, new, what, _why in NAMES:
        a = A.routines[old][2] if old in A.routines else None
        print("%-14s -> %-36s %d   %s"
              % (old, new, len(refs.get(old, [])), what))
        if a is not None and in_generated(a):
            print("      ⚠ inside a generator range")
    print("\n%d renames" % len(NAMES))


# ---------------------------------------------------------------------------
# --apply
# ---------------------------------------------------------------------------
RULE = "; ---------------------------------------------------------------------"


def _called_from(refs, old):
    rs = refs.get(old, [])
    if not rs:
        return ["nothing in either image names this address."]
    by = collections.defaultdict(list)
    for tag, addr, caller, kind in rs:
        by[(tag, caller or "?", kind)].append(addr)
    out = []
    for (tag, caller, kind), addrs in sorted(by.items(), key=lambda kv: kv[1][0] or 0):
        out.append("%s %s (`%s`) at %s"
                   % (tag, caller, kind,
                      ", ".join("0x%06X" % a for a in sorted(addrs) if a is not None)))
    return out


def _header(old, new, what, why, refs, A):
    svc = []
    for s, c, sv, _loads in swi7_wrappers():
        if s == old:
            svc = sv
            break
    lines = [RULE, "; %s -- %s" % (new, what), ";"]
    cf = _called_from(refs, old)
    lines.append("; Called from: %s" % cf[0])
    for extra in cf[1:]:
        lines.append(";          %s" % extra)
    if svc:
        for a, v in svc:
            nm = SERVICE.get(v, ("service 0x%02X" % v, "not in this file's table"))
            lines.append("; Issues:  SWI7 service 0x%02X at 0x%06X -- %s, %s"
                         % (v, a, nm[0], nm[1]))
    for i, ln in enumerate(why.split("\n")):
        lines.append("; %s%s" % ("Evidence: " if i == 0 else "          ", ln))
    lines.append("; Named by notes/prom_a_understanding_round6.py --apply; the byte gate")
    lines.append(";          is blind to this name, --verify reads it back.")
    lines.append(RULE)
    return lines


def _own_header_span(lines, label_line, old):
    """The contiguous comment run directly above `label_line` IF it is this
    routine's own header (it mentions the old label).  Else None."""
    j = label_line - 1
    blanks = 0
    end = label_line
    while j >= 0:
        if lines[j].startswith(";"):
            blanks = 0
            j -= 1
            continue
        if lines[j].strip() == "" and blanks == 0:
            blanks += 1
            j -= 1
            continue
        break
    start = j + 1
    if start >= label_line:
        return None
    block = "\n".join(lines[start:label_line])
    if old in block and "; %s --" % old in block:
        return (start, label_line)
    return None


def apply():
    A, _B = images()
    refs, _c = references()
    src = open(S_A).read()
    todo = []
    for old, new, what, why in NAMES:
        done = bool(re.search(r'^%s:' % new, src, re.M))
        here = bool(re.search(r'^%s:' % old, src, re.M))
        if done and not here:
            continue                      # already applied in an earlier run
        if not here:
            print("REFUSED: neither %s nor %s is a label in prom_a" % (old, new))
            return 1
        if re.search(r'\b%s\b' % new, src):
            print("REFUSED: %s already occurs in prom_a but %s is still a label"
                  % (new, old))
            return 1
        todo.append((old, new, what, why))
    if not todo:
        print("nothing to do: all %d names are already applied" % len(NAMES))
        return 0
    lines = src.split("\n")
    # 1. headers first, by descending line number so earlier indices stay valid
    plan = []
    for old, new, what, why in todo:
        li = A.routines[old][0]
        plan.append((li, old, new, what, why))
    for li, old, new, what, why in sorted(plan, reverse=True):
        hdr = _header(old, new, what, why, refs, A)
        span = _own_header_span(lines, li, old)
        if span:
            lines[span[0]:span[1]] = hdr
        else:
            lines[li:li] = hdr
    src = "\n".join(lines)
    # 2. rename every whole-word occurrence
    for old, new, _w, _y in todo:
        src, n = re.subn(r'\b%s\b' % old, new, src)
        if n < 1:
            print("REFUSED: no occurrence of %s survived header insertion" % old)
            return 1
    write_part(S_A_MASTER, src)
    print("applied %d renames and %d header blocks to %s" % (len(todo), len(todo), S_A))
    print("now run: python3 scripts/analysis/assert_byte_identical.py")
    return 0


def verify():
    """Read every applied name BACK out of the file, with its header."""
    src = open(S_A).read().split("\n")
    bad = 0
    for _old, new, _w, _y in NAMES:
        hits = [i for i, ln in enumerate(src) if ln.startswith(new + ":")]
        if len(hits) != 1:
            print("MISSING %s (%d definitions)" % (new, len(hits)))
            bad += 1
            continue
        i = hits[0]
        j = i - 1
        run = 0
        while j >= 0 and src[j].startswith(";"):
            run += 1
            j -= 1
        ev = any("Evidence:" in src[k] for k in range(j + 1, i))
        print("  %-36s header %2d lines, Evidence: %s" % (new, run, "yes" if ev else "NO"))
        if run < 3 or not ev:
            bad += 1
    print("%d of %d verified" % (len(NAMES) - bad, len(NAMES)))
    return 1 if bad else 0


# ---------------------------------------------------------------------------
# --selftest.  Every quantified claim in the docstring, and the LAST element of
# every table as well as the first.
# ---------------------------------------------------------------------------
def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    A, B = images()
    applied = any(ln.startswith(NAMES[0][1] + ":") for ln in A.lines)
    check("prom_a parses: %d top-level labels, %d instruction lines"
          % (len(A.tops), len(A.instr_lines)), len(A.tops) > 4000)

    # --- the calr formula -------------------------------------------------
    c_ok, c_bad, c_unk = calr_check()
    check("calr formula agrees on every NAMED calr target: %d agree, %d disagree"
          % (c_ok, c_bad), c_bad == 0 and c_ok > 2000)
    check("calr formula: at most one target label it cannot resolve (%d)" % c_unk, c_unk <= 1)
    # first and last calr line in the file, checked individually
    calrs = [(i, ln) for i, ln in enumerate(A.lines) if CALRSYM.match(ln)]
    for tag, (i, ln) in (("FIRST", calrs[0]), ("LAST", calrs[-1])):
        m = CALRSYM.match(ln)
        want = None
        nm = m.group(1)
        if nm.startswith(".L"):
            want = int(nm[2:], 16)
        elif nm in A.routines:
            want = A.routines[nm][2]
        got = calr_target(int(m.group(2), 16),
                          int(m.group(3), 16) | (int(m.group(4), 16) << 8))
        check("%s calr line in the file (%s -> 0x%06X) resolves correctly"
              % (tag, nm, got), want == got)

    refs, counts = references()
    check("the reference census sees calr sites at all: %d" % counts["calr"],
          counts["calr"] > 2000)
    hist = collections.Counter(min(len(refs.get(s, [])), 8) for s in subs())
    check("zero-reference sub_XXXXXX falls to %d (805 without the calr fix)" % hist[0],
          hist[0] < 400)

    # --- L1 -----------------------------------------------------------------
    multi = sum(1 for s in candidates()
                if len([r for r in refs.get(s, []) if r[3] in ("call", "calr", "jp", "jrl")]) >= 2)
    check("L1: %d of %d candidates have two or more call sites"
          % (multi, len(candidates())), multi > 800)

    # --- L3, the SWI7 wrappers ---------------------------------------------
    rows = swi7_wrappers()
    short = [r for r in rows if len(r[1]) <= 12 and all(v is not None for _a, v in r[2])]
    check("L3: %d candidates reach `swi 7` before their own ret; %d are short and"
          " fully resolved" % (len(rows), len(short)), len(rows) >= 60 and len(short) >= 18)
    # the two ROM strings the names rest on, byte for byte
    check("0xF9422C really is the ASCII `ALL INITIAL SETTING!`",
          rom_byte(0xF9422C, 20) == b"ALL INITIAL SETTING!")
    check("0xF81E79 really is the three bytes `END`", rom_byte(0xF81E79, 3) == b"END")
    check("0x01B8 is 11 rows at AP=40, the advance LCD_PrintLine40_AdvanceRow claims",
          0x01B8 == 11 * 40)
    check("(0,0)-(0x13F,0xEF) is the whole 320x240 panel LCD_FlashWholePanel fills",
          0x13F + 1 == 320 and 0xEF + 1 == 240)
    check("0xF81948 really is six underscores",
          rom_byte(0xF81948, 6) == b"______")
    check("CharSet_F81768 really is `_` + A-Z + 0-9, 37 bytes",
          rom_byte(0xF81768, 37) == b"_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    # the two byte-identical copies the _Copy names claim
    check("0xFE80F7 and 0xF999F0 are byte-identical over 14 bytes",
          rom_byte(0xFE80F7, 14) == rom_byte(0xF999F0, 14))
    check("0xFE8105 and 0xF999FE are byte-identical over 6 bytes",
          rom_byte(0xFE8105, 6) == rom_byte(0xF999FE, 6))
    # the ScreenRedraw ordering, at every site
    order = []
    for b, e in (("sub_F999F0", "sub_F999FE"), ("sub_FE80F7", "sub_FE8105")):
        nb = dict((o, n) for o, n, _w, _y in NAMES)
        kb, ke = (nb[b], nb[e]) if applied else (b, e)
        bs = {r[2]: r[1] for r in refs.get(kb, [])}
        es = {r[2]: r[1] for r in refs.get(ke, [])}
        for caller in set(bs) & set(es):
            order.append(bs[caller] < es[caller])
    check("ScreenRedraw Begin precedes End at all %d shared call sites" % len(order),
          len(order) == 5 and all(order))
    # the arithmetic behind LCD_ClearLayer0_Rows29To235
    check("0x0488 / 0x28 is exactly 29 with no remainder -- the row the clear starts at",
          0x0488 % 0x28 == 0 and 0x0488 // 0x28 == 29)
    check("0x0488/0x28 + 0xCF - 1 = 235, the last row cleared",
          0x0488 // 0x28 + 0xCF - 1 == 235)
    check("0x59 - 0x10 = 73, the gap the VRuleRight name claims", 0x59 - 0x10 == 73)

    # --- L4, the painters and the retraction check --------------------------
    P = painters()
    got = painter_text()
    check("L4: %d painters scoped to their own ret; %d have a framing list with text"
          % (len(P), len(got)), len(P) >= 75 and len(got) == 7)
    check("★ ret-scoping does NOT reach 0xF81AB5, whose name round 5 retracted",
          "sub_F81AB5" not in got)
    check("★ ret-scoping does NOT reach 0xF9167C, whose name round 5 retracted",
          "sub_F9167C" not in got)
    # the walker, proved on lists the tree has already converted and labelled
    t, fr = dl_text(0xF3BF80, 0xF3BFF8)
    check("the walker reproduces DL_S0ngC0pyFromToSongSongOk's own text",
          fr and t[:2] == ["S0NG C0PY", "FROM"])
    t, fr = dl_text(0xF01800, 0xF01873)
    check("the walker reproduces the SOUND EDIT list documented in FINDINGS",
          fr and t == ["SOUND EDIT", " WRITE", "COPY"])
    # the two lists the two new painter names rest on
    t, fr = dl_text(0xF0D6AF, 0xF0D77F)
    check("0xF0D6AF frames and its first record is `SYSEX BULK DUMP`",
          fr and t[0] == "SYSEX BULK DUMP")
    t, fr = dl_text(0xF0D7E2, 0xF0D81B)
    check("0xF0D7E2 frames and draws the three-row label block",
          fr and t == ["SYS,PART&MIDI :", "SOUND         :", "COMBINATION   :"])
    check("both of those lists lie inside prom_b .incbin territory (no prom_b label)",
          0xF0D6AF not in [B.routines[n][2] for n in B.order] and
          0xF0D7E2 not in [B.routines[n][2] for n in B.order])
    check("morpheme guard passes for every Paint_ name", mode_morphemes_quiet())

    # --- L2 ------------------------------------------------------------------
    A2 = A
    buckets = collections.defaultdict(list)
    for n in A2.order:
        c = body(A2, n)
        if not c or c[-1][1] not in RETS or c[0][0] is None or c[-1][0] is None:
            continue
        mb = BYTECOMMENT.search(A2.lines[c[-1][3]])
        lo, hi = c[0][0], c[-1][0] + (len(mb.group(1).split()) if mb else 1)
        if 6 <= hi - lo <= 4096:
            by = rom_byte(lo, hi - lo)
            if by:
                buckets[by].append(n)
    mixed = [v for v in buckets.values()
             if len(v) > 1 and any(is_content(x) for x in v) and any(SUB.match(x) for x in v)]
    check("L2: %d identical groups, %d mixing a content name with a sub_ (rejected)"
          % (sum(1 for v in buckets.values() if len(v) > 1), len(mixed)), len(mixed) == 0)

    # --- F1 ------------------------------------------------------------------
    tbl = rom_byte(MIDI_INDEX_TABLE, 128)
    live = sorted(set(tbl[cc] for cc in range(128) if tbl[cc] != 0xFF))
    check("F1: the controller table maps %d numbers onto %d distinct indices"
          % (sum(1 for cc in range(128) if tbl[cc] != 0xFF), len(live)),
          len(live) == 23)
    for s, slot in sorted(MIDI_DEAD.items(), key=lambda kv: kv[1]):
        check("F1: slot %d (%s) is unreachable from the controller table" % (slot, s),
              slot not in live)
        check("F1: %s has exactly one reference, its own table slot" % s,
              len(refs.get(s, [])) == 1 and refs[s][0][3] == ".long")
    check("F1: CC 0x40 maps to index 0, which the tree names MidiIn_CC40_Hold",
          tbl[0x40] == 0)
    check("F1: CC 0x78 maps to index 41, the LAST live entry -- checked as well as"
          " the first", tbl[0x78] == 41)

    # --- F2 ------------------------------------------------------------------
    rs = retstubs()
    withaddr = [r for r in rs if r[1] is not None]
    strict = retstubs(strict=True)
    check("F2: %d sub_XXXXXX return immediately; %d are a one-byte object"
          % (len(rs), len(strict)), len(rs) >= 330 and len(strict) >= 280)
    check("F2: every one of the %d with an address has ROM byte 0x0E" % len(withaddr),
          all(b == 0x0E for _s, _a, b in withaddr))
    check("F2: the FIRST of them (%s) is 0x0E" % withaddr[0][0], withaddr[0][2] == 0x0E)
    check("F2: the LAST of them (%s) is 0x0E" % withaddr[-1][0], withaddr[-1][2] == 0x0E)
    check("F2: 219 of the one-byte objects are reached by a `jp` (routines, not sites)",
          sum(1 for s, a, _b in strict if a is not None
              and any(r[3] == "jp" for r in refs.get(s, []))) == 219)

    # --- the names themselves ------------------------------------------------
    seen = set()
    dupe = [n for _o, n, _w, _y in NAMES if n in seen or seen.add(n)]
    check("the %d proposed names are distinct" % len(NAMES), not dupe)
    FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                        r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                        r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')
    bad = [n for _o, n, _w, _y in NAMES if FRAMED.match(n)]
    check("no proposed name is FRAMED by wave7_documentation_metrics.py: %s" % bad, not bad)
    rs = emitter_ranges()
    check("the emitter inventory finds %d prom_a ranges, not the 3 that carry a"
          " banner" % len(rs), len(rs) >= 15)
    exposed = [n for o, n, _w, _y in NAMES
               if emitter_of(A.routines.get(n, A.routines.get(o, (0, 0, None)))[2])]
    check("%d of the %d names sit inside an emitter range and --emitters prints the"
          " repair line for each" % (len(exposed), len(NAMES)),
          len(exposed) == mode_emitters_quiet())
    check("gen_prom_a_screens.py really owns 0xFEF746-0xFF3800, where three of them are",
          ("gen_prom_a_screens.py", 0xFEF746, 0xFF3800) in rs)
    check("prom_a still has %d FRAMED labels and this round promoted none; --framed"
          " says why per family" % mode_framed_quiet(), mode_framed_quiet() == 253)
    st = stale_mentions()
    check("exactly one renamed label is still named in prose elsewhere in the tree"
          " (%s), and --stale lists every site"
          % ", ".join(sorted(set(o for _p, _l, o, _n in st))),
          sorted(set(o for _p, _l, o, _n in st)) == ["sub_FF76FE"])
    if applied:
        check("--apply has run: every new name is defined exactly once",
              all(sum(1 for ln in A.lines if ln.startswith(n + ":")) == 1
                  for _o, n, _w, _y in NAMES))
        check("--apply has run: no old sub_ name survives",
              not any(re.search(r'\b%s\b' % o, "\n".join(A.lines)) for o, _n, _w, _y in NAMES))
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


def mode_framed_quiet():
    A, _B = images()
    return sum(1 for n in A.order
               if not SUB.match(n) and not INTERNAL.match(n) and FRAMED_RE.match(n))


def mode_emitters_quiet():
    A, _B = images()
    return sum(1 for o, n, _w, _y in NAMES
               if emitter_of(A.routines.get(n, A.routines.get(o, (0, 0, None)))[2]))


def mode_morphemes_quiet():
    got = painter_text()
    for old, new, _w, _y in NAMES:
        if not new.startswith("Paint_"):
            continue
        text = " ".join(x for _a, _lo, _hi, t in got.get(current_label(old), [])
                        for x in t).upper()
        for p in re.findall(r'[A-Z][a-z0-9]*|[A-Z0-9]+', new[len("Paint_"):]):
            if p.upper() not in text:
                return False
    return True


def mode_emitters():
    """★ WHICH prom_a RANGES ARE REBUILT BY A GENERATOR, and which of this
    round's names sit inside one."""
    A, _B = images()
    rs = emitter_ranges()
    print("prom_a ranges owned by a notes/gen_prom_a_*.py emitter: %d" % len(rs))
    banner = sum(1 for ln in A.lines if "emitted by notes/gen_" in ln)
    print("  ... of which announce themselves in the .s with a banner: %d" % banner)
    for fn, lo, hi in rs:
        print("    0x%06X-0x%06X  %s" % (lo, hi, fn))
    print("\n  ⚠ EVERY one of those emitters rebuilds its labels from a `semantic`")
    print("    dict with `sub_%06X` as the fallback, so a name written into the .s")
    print("    inside one of these ranges is REVERTED the next time it runs.  That")
    print("    has been true since round 3 and no round has stated it.")
    print("\n  this round's names that are exposed, with the repair:")
    n = 0
    for old, new, _w, _y in NAMES:
        a = A.routines.get(new, A.routines.get(old, (0, 0, None)))[2]
        fn = emitter_of(a)
        if not fn:
            continue
        n += 1
        print("    %-36s 0x%06X  %s" % (new, a, fn))
        print("        add to that file's `semantic` dict:  0x%06X: \"%s\"," % (a, new))
    print("  %d of %d exposed." % (n, len(NAMES)))
    return n


def stale_mentions():
    """Files OUTSIDE prom_a that still name a label this round renamed.

    A rename inside prom_a is proved by the byte gate; a PROSE mention of the old
    name in another file is not, and nothing in this tree checks for one.  This
    lane may not edit prom_b's listing or another lane's notes, so it lists them.
    """
    out = []
    for root, _dirs, files in os.walk(ROOT):
        if os.sep + ".git" in root:
            continue
        for fn in sorted(files):
            if not fn.endswith((".s", ".py", ".md", ".txt")):
                continue
            path = os.path.join(root, fn)
            if os.path.abspath(path) in (os.path.abspath(S_A),
                                         os.path.abspath(__file__)):
                continue
            try:
                text = open(path, errors="replace").read()
            except OSError:
                continue
            for old, new, _w, _y in NAMES:
                for i, ln in enumerate(text.split("\n")):
                    if re.search(r'\b%s\b' % old, ln):
                        out.append((os.path.relpath(path, ROOT), i + 1, old, new))
    return out


def mode_stale():
    rows = stale_mentions()
    print("mentions of a renamed label OUTSIDE prom_a/wsa1_prom_a.s: %d" % len(rows))
    for path, line, old, new in rows:
        print("  %-52s:%-6d %s -> %s" % (path, line, old, new))
    print("\n  ⚠ All of these are PROSE, not code: the byte gate cannot see them and")
    print("    this lane may not edit prom_b's listing or another lane's notes in")
    print("    this round.  Fix them in the round that owns those files.")
    return len(rows)


FRAMED_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                       r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                       r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')
# Why each family of prom_a's FRAMED labels resisted promotion this round.
# ★ This is the round's asked-for headline -- "EXISTING framed labels promoted to
# a real name" -- and the honest answer for prom_a is ZERO.  Here is why, family
# by family, so a later round does not re-derive it.
FRAMED_WHY = {
    "DisplayList": "single-record op-0x23 GLYPH lists: `23 05 <glyph> <pos16>`.  Almost "
                   "none holds an .ascii record, so the rule that named 229 of prom_b's "
                   "lists has nothing to read.  Naming them needs the glyph table decoded.",
    "JumpTable": "the selector is an argument, not a documented value -- e.g. "
                 "JumpTable_F99F96's index is (XIZ+0x08), and its own header already "
                 "says `Unknown: the selector`.  An index with no meaning names nothing.",
    "MidiOut_PartRecordPtrs": "inside gen_prom_a_fa5aeb_module.py's range; a rename here "
                              "is reverted by that emitter (see --emitters).",
    "MidiIn_BuildList": "same emitter range.  The suffix is the RAM address of the list "
                        "each builds (0x19F0..0x1A90 at stride 0x10), which is real but "
                        "is an address, not a meaning.",
    "Ring_Get": "★ THE CHEAPEST PROMOTION IN THE IMAGE AND IT IS NOT TAKEN.  The suffix "
                "of the 25 Ring_* labels is a CAPACITY, not an address -- Ring_Get_0080's "
                "wrap mask is 0x7F -- and the family is already fully documented above "
                "itself in the listing.  Renaming to a spelling the metric reads as "
                "content would be honest AND would remove a real ambiguity, but "
                "gen_prom_a_ringbuf_module.py owns 0xF830C6-0xF85600 and would revert it. "
                "Do it in the round that owns that emitter.",
    "Dispatch": "pointer tables whose reader is known and whose INDEX is not.",
    "DisplayListPtrs": "tables of the textless lists above; the same gap one level up.",
    "ScreenDispatch": "inside gen_prom_a_fe8000_module.py's range.",
}
FRAMED_WHY["Ring_Scan"] = FRAMED_WHY["Ring_ScanToPut"] = FRAMED_WHY["Ring_Put"] = \
    FRAMED_WHY["Ring_Init"] = FRAMED_WHY["Ring_Get"]


def mode_framed():
    A, _B = images()
    fam = collections.Counter()
    for n in A.order:
        if SUB.match(n) or INTERNAL.match(n) or not FRAMED_RE.match(n):
            continue
        fam[re.sub(r'_[0-9A-Fa-f]{4,6}$', '', re.sub(r'_[0-9]{1,4}$', '', n))] += 1
    print("prom_a FRAMED labels: %d in %d families" % (sum(fam.values()), len(fam)))
    print("★ promoted to content by this round: 0.  Why, family by family:\n")
    said = set()
    for k, v in fam.most_common():
        why = FRAMED_WHY.get(k)
        if why is None:
            why = "(single or tiny family; not attacked)"
        elif why in said:
            why = "as above"
        said.add(FRAMED_WHY.get(k, ""))
        print("  %4d  %-26s %s" % (v, k, why))
    return sum(fam.values())


MODES = {
    "--calr": mode_calr, "--callshape": mode_callshape, "--twins": mode_twins,
    "--services": mode_services, "--painters": mode_painters, "--midi": mode_midi,
    "--retstubs": mode_retstubs, "--morphemes": mode_morphemes, "--plan": mode_plan,
    "--emitters": mode_emitters, "--stale": mode_stale, "--framed": mode_framed,
}

if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--apply" in sys.argv:
        sys.exit(apply())
    if "--verify" in sys.argv:
        sys.exit(verify())
    for a in sys.argv[1:]:
        if a in MODES:
            MODES[a]()
            sys.exit(0)
    print(__doc__)
