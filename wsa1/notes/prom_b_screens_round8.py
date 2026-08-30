#!/usr/bin/env python3
"""prom_b 0xF7E2D8-0xF7FFFF -- WHAT IS IN IT, WHO REACHES EACH BYTE OF IT, and
which of its 210 routines can be NAMED from evidence rather than framed.

QUESTION IT ANSWERS
    Round 7 ended by naming this span as the next lever: "0xF7E2D8-0xF80000
    (7,464 B) holds 15 of the 25 screens' Enter methods, and converting it would
    let the same calibrated title rule name their painters, Leave methods and
    button handlers, and resolve the 4 screens still unnamed."  This script asks
    the three questions that has to answer before a byte is emitted:
      (a) WHERE are the entry points, and what reaches each one?
      (b) WHICH bytes are NOT instructions?
      (c) WHICH of them can be named, from WHAT, and -- said out loud -- which
          cannot, and why not.

────────────────────────────────────────────────────────────────────────────────
★★ THE ANSWER TO (c), AND IT IS SMALLER THAN THE LEVER PROMISED
────────────────────────────────────────────────────────────────────────────────
  The span is 210 routines.  Thirty of them get a CONTENT name, five a FRAMED
  one, and 180 keep sub_XXXXXX.  124 of those 180 are BUTTON HANDLERS and this
  pass refuses to name them, for a reason it measured rather than assumed:

    * the 32 tables at 0xF7D2D8 hold 1,024 slots; 649 of those land in this span
      and they name only 314 distinct addresses;
    * 190 of those 314 addresses ARE A SINGLE `ret` BYTE -- 510 of the 649 slots,
      78.6%.  An unused button on a screen points at the `ret` that ends whatever
      routine happens to sit above it.  ★ Those 190 get NO LABEL at all: they are
      annotated where they fall, as a trailing comment on the `ret` line, so the
      tree gains the fact without gaining 190 framed labels.  `--buttons`.
    * the other 124 are real code, and what distinguishes one from the next is
      THE BUTTON NUMBER.  Round 6 refused `Write3602_Index5` for exactly that
      reason, so these keep `sub_XXXXXX` and a header that states which screen
      and which index reach them.  Naming them needs a button VOCABULARY, and
      this pass looked for one and did not find it (`--refused`).

  So JOB 1's yield is 14 painters + 11 Leave bodies + 1 Button body + 2
  byte-identical prom_a twins + 2 label rows = 30 content names, plus 5 framed
  pointer tables -- not 210 names.  14.0% of the labels the splice adds are
  content against prom_b's standing 16.2%, so the splice moves the LOWER bound
  DOWN a little -- 16.2% -> 16.1%, measured, not estimated.

  ★★ AND THE ROUND PAYS FOR THAT SEPARATELY, with the one framed->content move
  it actually has: `--promote --apply` renames the 32 button tables at 0xF7D2D8
  from `Table_<address>` (framed: a kind plus an address) to
  `ButtonTable_<Screen>` (content: it says whose button map it is).  Round 7
  established WHAT they are; this round has the owner map, from the +8 stubs'
  own `ld XIX` immediates.  Measured on the whole image:

      prom_b        content  framed  sub_XXXX   LOWER   UPPER  headers  evidence
      before             953   3,087     1,851   16.2%   68.6%    3,233     3,057
      after the splice   983   3,092     2,031   16.1%   66.7%    3,268     3,272
      after --promote  1,015   3,060     2,031   16.6%   66.7%    3,299     3,304

  ⚠ UPPER falls either way, from 68.6% to 66.7%, and that is honest: 180 new
  sub_XXXXXX is 180 new objects nobody has named.  The territory is converted;
  the meaning is not, and the two numbers say so.

────────────────────────────────────────────────────────────────────────────────
WHAT IS IN THE SPAN
────────────────────────────────────────────────────────────────────────────────
    code    7,359   in six segments
    ptrtab    104   FIVE blink-template pointer tables (4, 5, 7, 5 and 5 words),
                    each read by an `ld XIY,<base> / ld XIY,(XIY+WA)` pair
    pad         1   one 0x0E (`ret`) byte below the 0xF7F521 table
    -----   7,464

  ★ THE FIVE TABLES ARE THE ONLY NON-INSTRUCTION BYTES, and each one is found by
  its OWN READER, not by a rule over bytes: the span's linear decode contains
  exactly five `ld XIY,imm32` whose immediate lands inside the span, and every
  one of the five is followed within two instructions by `ld XIY,(XIY+WA)` and
  then `push XIY / call 0xF42E20`.  `T_F42E20` is `Blink_Command`
  (notes/FINDINGS-prom_b-field-blink.md), so each table holds pointers to BLINK
  TEMPLATES -- the same shape, the same callee and the same two-null-entries
  opening as prom_a's already-documented `BlinkArgPtrs_F8024D` at 0xF8024D.
  ⚠ HOW MANY WORDS EACH TABLE HAS IS NOT ESTABLISHED.  Nothing bounds the index;
  the count below is "words that fit before the next ENTRY POINT", which is what
  prom_a's header claims for its own table too.  One of the five (0xF7F521)
  leaves one 0x0E byte over and it is emitted as padding, stated as such.

────────────────────────────────────────────────────────────────────────────────
★ THE FOUR UNNAMED SCREENS -- RESOLVED AS FAR AS THE EVIDENCE GOES, WHICH IS NOT
  ALL THE WAY, AND TWO OF THEM CAN NEVER BE SEPARATED BY THIS RULE
────────────────────────────────────────────────────────────────────────────────
  Round 7 left 0xF43040, 0xF43048, 0xF43160 and 0xF431D0 with no name and asked
  the next pass to resolve them if the evidence reached them.  It does not, and
  `--screens4` prints why, per screen, from the ROM:

    0xF43040  Enter -> 0xF7E971, IN THIS SPAN and now converted.  Three
              instructions: `or (0x2134),0x0002 / call T_F428B0 / ret`.  ZERO
              display-list calls, so there is no title to read.
    0xF43048  Enter -> prom_a 0xF80F3A (`sub_F80F3A`).  Zero display-list calls
              in its extent.
    0xF43160  Enter -> prom_a 0xF8101E (`sub_F8101E`).  Zero display-list calls.
    0xF431D0  Enter -> prom_a 0xF8101E -- ★ THE SAME ROUTINE AS 0xF43160.

  ★★ So the title rule cannot separate 0xF43160 from 0xF431D0 even in principle:
  two distinct screen objects share ONE Enter method, and a rule that names a
  screen after what its Enter draws must give both the same name or neither.
  That is a fact about the ROM, not a limit of this pass, and it is the reason
  the count of nameable screens stops at 21 and not 25.

────────────────────────────────────────────────────────────────────────────────
★ THE TITLE RULE, RE-CALIBRATED (`--calibrate`) -- AND WHAT THE RE-RUN IS WORTH
────────────────────────────────────────────────────────────────────────────────
  Round 7's calibration: seven screens' Enter methods land in prom_a, where
  prom_a had independently named them `Paint_<X>` months earlier from the same
  screens' text; the rule's derived title was a PREFIX of all seven and EXACT on
  six.  This pass re-runs that same check and gets the same 7/7 prefix, 6/7
  exact -- `--calibrate` prints the table.

  ⚠ AND IT SAYS PLAINLY WHAT THAT RE-RUN DOES NOT DO.  Converting this span adds
  no new calibration point, because a calibration point needs a name derived
  INDEPENDENTLY of the rule, and the 14 painters in this span had no name at
  all.  What the conversion buys is a SECOND, different check on the same 14:
  the title round 7 read from the ROM through `unidasm` must equal the title
  read from the emitted `.s` text.  14 of 14 agree (`--calibrate`).  That is a
  transcription check, not a calibration, and calling it one would be the
  "+35 headers that were 35 blank lines" mistake in another costume.

────────────────────────────────────────────────────────────────────────────────
★ JOB 2, ANSWERED WITH THE ZEROS IN IT (`--shapes`)
────────────────────────────────────────────────────────────────────────────────
  Round 6's four mechanical shapes, measured against ALL of prom_b's
  sub_XXXXXX routines -- what each WOULD reach if it were applied.  Measured
  AFTER this round's splice, so the denominator is the current 2,031:

      bare ret                  46
      one-line forwarder        41
      table-call stub            0   <- the cluster round 6 found does not
      single-cell writer         4      exist outside the span it found it in
      none of the four       1,940
      ------------------------------
      sub_XXXXXX total       2,031
  (before the splice the same run said 46 / 41 / 0 / 1 / 1,763 of 1,851, so the
   7,464 bytes converted here contributed 3 single-cell writers and nothing else
   any of the four shapes recognises.)

  ★★ AND THE CONCLUSION IS NOT TO APPLY THEM.  91 of 2,031 is 4.5%, and every
  name those shapes produce -- `BareRet_F0AAB2`, `Forwarder_F0B70F` -- is a KIND
  PLUS AN ADDRESS, which the documentation metric grades as FRAMED and which
  this project has decided is not the goal.  Applying all four would move 91
  labels from UNNAMED to FRAMED, raise the UPPER bound, leave the LOWER bound
  exactly where it is, and (round 6's measured cost) put four range shorthands
  and six sentences of existing prose at risk.  So this pass measures and stops,
  and says why rather than quietly not doing it.

RUN
    python3 notes/prom_b_screens_round8.py               # the summary
    python3 notes/prom_b_screens_round8.py --entries     # entry points + source
    python3 notes/prom_b_screens_round8.py --tables      # the five pointer tables
    python3 notes/prom_b_screens_round8.py --routines    # the 210 routines
    python3 notes/prom_b_screens_round8.py --names       # every name proposed
    python3 notes/prom_b_screens_round8.py --calibrate   # the title-rule score
    python3 notes/prom_b_screens_round8.py --screens4    # the four unnamed screens
    python3 notes/prom_b_screens_round8.py --buttons     # the button-table census
    python3 notes/prom_b_screens_round8.py --refused     # what was NOT named, why
    python3 notes/prom_b_screens_round8.py --shapes      # JOB 2: the four shapes
    python3 notes/prom_b_screens_round8.py --promote     # the 32 framed->content
    python3 notes/prom_b_screens_round8.py --promote --apply
    python3 notes/prom_b_screens_round8.py --selftest    # checks, incl. the LAST
The emitter that turns this into assembly is notes/gen_prom_b_f7e2d8_module.py.
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

LO, HI = 0xF7E2D8, 0xF80000
A_BASE, B_BASE = 0xF80000, 0xF00000
BTN_LO, BTN_HI, BTN_STRIDE = 0xF7D2D8, 0xF7E2D8, 0x80   # the 32 button tables
INTERP = {0xF417F0: "A", 0xF417F4: "B"}
BLINK_CMD = 0xF42E20                    # T_Blink_Command -> prom_b 0xF0E9CF
SRCA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")

# The two prom_a routines this span holds a byte-identical copy of.  Both
# extents are stated so the match is on WHOLE routines, not on a prefix.
TWINS = [(0xF7E2D9, 14, 0xF999F0, 14, "LCD_ScreenRedraw_Begin"),
         (0xF7E2E7, 6, 0xF999FE, 6, "LCD_ScreenRedraw_End")]

FAIL = []
_c = {}


# --------------------------------------------------------------------- ROM
def rom(which):
    if which not in _c:
        n = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13"}[which]
        _c[which] = open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return _c[which]


def byte(a):
    return rom("a")[a - A_BASE] if a >= A_BASE else rom("b")[a - B_BASE]


def bs(a, n):
    return bytes(byte(a + i) for i in range(n))


def w32(a):
    return int.from_bytes(bs(a, 4), "little")


# ------------------------------------------------------------- the decode
def decode():
    """[(addr, mame text)] for the whole span, from llvm_roundtrip_autoforce.

    ⚠ This is a LINEAR decode and it desynchronises inside the five pointer
    tables; `layout()` carves those out and the emitter transcribes each code
    segment on its own.  It is used here only to FIND the tables and to walk
    routine bodies, both of which are checked afterwards."""
    if "dec" not in _c:
        out = subprocess.run([sys.executable, AUTOFORCE, "b", hex(LO), hex(HI - LO),
                              "--quiet"], capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed:\n" + out.stderr[-2000:])
        rows = []
        for ln in out.stdout.split("\n"):
            m = re.search(r";\s*([0-9A-F]{6})\s+(.*)$", ln)
            if m:
                rows.append((int(m.group(1), 16),
                             m.group(2).split("[llvm-mc")[0].strip()))
        _c["dec"] = rows
    return _c["dec"]


def text_at():
    if "ta" not in _c:
        _c["ta"] = dict(decode())
    return _c["ta"]


# ------------------------------------------------------- the five tables
def ptr_tables():
    """[(base, entry count, pad bytes, [values], reader address)].

    FOUND BY THEIR READERS.  Every `ld XIY,imm32` in the span whose immediate is
    inside the span is a table base -- and each is confirmed by the two
    instructions that follow it (`ld XIY,(XIY+WA)` then, within four more,
    `call 0xF42E20` = Blink_Command).  The extent runs to where the linear decode
    picks code up again, which is the same bound prom_a's BlinkArgPtrs_F8024D
    header uses ("word 5 is the `call` the code resumes with")."""
    if "pt" in _c:
        return _c["pt"]
    rows = decode()
    order = [a for a, _t in rows]
    txt = dict(rows)
    bases = []
    for i, (a, t) in enumerate(rows):
        m = re.match(r"ld XIY,0x00([0-9a-f]{6})$", t)
        if m:
            v = int(m.group(1), 16)
            if LO <= v < HI:
                nxt = [txt[order[j]] for j in range(i + 1, min(i + 6, len(order)))]
                assert any("ld XIY,(XIY+WA)" in s for s in nxt), \
                    "0x%06X: base %06X not followed by an indexed load" % (a, v)
                bases.append((v, a))
    bases.sort()
    out = []
    for v, reader in bases:
        end = min(x for x in ends_of_tables(v))
        n = (end - v) // 4
        vals = [w32(v + 4 * k) for k in range(n)]
        # trailing words that are not pointers are `ret` padding, not entries
        while vals and vals[-1] not in (0,) and not (0xF00000 <= vals[-1] < 0x1000000):
            vals.pop()
            n -= 1
        out.append((v, n, end - (v + 4 * n), vals, reader))
    _c["pt"] = out
    return out


def ends_of_tables(base):
    """Where the code resumes below `base`: the lowest entry point above it, and
    the lowest instruction the linear decode agrees on above it."""
    e = [a for a in sorted(entry_points()) if a > base]
    return [e[0] if e else HI]


# ------------------------------------------------------------ entry points
def entry_points():
    """{address: sorted list of reasons} for every address something enters at.

    FOUR SOURCES, all opcode- or table-anchored, none inferred from a decode:
      1. `call nnn` / `jp nnn` (0x1D / 0x1B) at EVERY byte offset of prom_a and
         prom_b whose 24-bit operand lands in the span -- an upper bound;
      2. `calr` / `jrl` in the ALREADY-CONVERTED text of either `.s` (these are
         PC-relative, so no byte scan finds them);
      3. `call` / `calr` / `jp` inside the span's own decode;
      4. the 1,024 slots of the 32 button tables at 0xF7D2D8.
    """
    if "ep" in _c:
        return _c["ep"]
    why = collections.defaultdict(set)
    for k in ("a", "b"):
        d, base = rom(k), (A_BASE if k == "a" else B_BASE)
        for o in range(len(d) - 3):
            if d[o] in (0x1D, 0x1B):
                v = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
                if LO <= v < HI:
                    why[v].add("%s 0x%06X %s" % ("call" if d[o] == 0x1D else "jp",
                                                 base + o, k))
    for path, k in ((SRCA, "a"), (SRCB, "b")):
        for ln in open(path, encoding="utf-8"):
            mm = re.search(r"\b(calr|jrl)\b.*?0x([0-9a-f]{6})\b", ln)
            ad = re.search(r";\s*([0-9A-F]{6})\b", ln)
            if mm and ad:
                v = int(mm.group(2), 16)
                if LO <= v < HI and not (LO <= int(ad.group(1), 16) < HI):
                    why[v].add("%s 0x%s %s" % (mm.group(1), ad.group(1), k))
    for a, t in decode():
        m = re.match(r"(calr|call|jrl|jp)\s+0x([0-9a-f]+)$", t)
        if m:
            v = int(m.group(2), 16)
            if LO <= v < HI:
                why[v].add("%s 0x%06X b" % (m.group(1), a))
    for t, i, v in button_slots():
        if LO <= v < HI:
            why[v].add("button table 0x%06X entry %d" % (t, i))
    _c["ep"] = {a: sorted(s) for a, s in why.items()}
    return _c["ep"]


def button_slots():
    """[(table base, index, value)] for all 32*32 slots of the button tables."""
    if "bs" not in _c:
        _c["bs"] = [(t, i, w32(t + 4 * i))
                    for t in range(BTN_LO, BTN_HI, BTN_STRIDE) for i in range(32)]
    return _c["bs"]


# ---------------------------------------------------------------- routines
def routine_starts():
    """The entry points that begin a ROUTINE.

    An entry point whose byte is 0x0E (`ret`) is not a routine: it is one `ret`
    borrowed as an empty body, the convention round 7 documented for the +0x0C
    vtable word.  Those are annotated in place instead of labelled -- see
    --buttons for the count and the share."""
    return sorted(a for a in entry_points() if byte(a) != 0x0E)


def routines():
    """[(start, end)] -- each routine runs to the next routine start."""
    s = routine_starts()
    return [(v, s[i + 1] if i + 1 < len(s) else HI) for i, v in enumerate(s)]


# ------------------------------------------------------------ display lists
def lists_in(lo, hi):
    """[(list lo, list hi, interpreter)] drawn between `lo` and `hi`.

    XIY/XIX are the LAST such immediates loaded before the interpreter call --
    prom_a's own rule, notes/FINDINGS-ui-display-list.md."""
    xiy = xix = None
    out = []
    for a, t in decode():
        if a < lo:
            continue
        if a >= hi:
            break
        m = re.match(r"ld XIY,0x00([0-9a-f]{6})$", t)
        if m:
            xiy = int(m.group(1), 16)
            continue
        m = re.match(r"ld XIX,0x00([0-9a-f]{6})$", t)
        if m:
            xix = int(m.group(1), 16)
            continue
        m = re.match(r"call 0x([0-9a-f]+)$", t)
        if m and int(m.group(1), 16) in INTERP and xiy is not None and xix is not None:
            out.append((xiy, xix, INTERP[int(m.group(1), 16)]))
    return out


def records(lo, hi):
    out, a = [], lo
    while a < hi:
        op, ln = byte(a), byte(a + 1)
        if ln < 2 or a + ln > hi:
            break
        out.append((a, op, ln, bs(a + 2, ln - 2)))
        a += ln
    return out


def title_of(lo, hi):
    """The leading run of op-0x1C records, whose payload is 4 coordinate bytes
    then text.  This is round 7's rule, unchanged and re-imported below."""
    recs = records(lo, hi)
    i = 0
    while i < len(recs) and recs[i][1] != 0x1C:
        i += 1
    parts = []
    while i < len(recs) and recs[i][1] == 0x1C:
        s = recs[i][3][4:].decode("latin-1").strip()
        if s:
            parts.append(s)
        i += 1
    return " ".join(parts)


def slug(text):
    words = re.split(r"[^A-Za-z0-9#]+", text)
    return "".join(w[:1].upper() + w[1:].lower() for w in words if w)


def painters():
    """{routine start: (title, first titled list address)} for routines in the
    span that draw a TITLED display list."""
    if "pa" in _c:
        return _c["pa"]
    out = {}
    for s, e in routines():
        for lo, hi, _i in lists_in(s, e):
            t = title_of(lo, hi)
            if t:
                out[s] = (t, lo)
                break
    _c["pa"] = out
    return out


# --------------------------------------------------------------- the names
def existing(path):
    if ("lab", path) in _c:
        return _c[("lab", path)]
    lab, cur = {}, []
    for ln in open(path, encoding="utf-8"):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", ln)
        if m:
            cur.append(m.group(1))
            continue
        m = re.search(r";\s*([0-9A-F]{6})\b", ln)
        if m and cur:
            for x in cur:
                lab.setdefault(int(m.group(1), 16), x)
            cur = []
    _c[("lab", path)] = lab
    return lab


def method_bodies():
    """{body address: (role, screen base, screen name or None)} for the 32 screen
    methods whose BODY lands in this span.

    The +0/+4/+8/+0x0C stubs at 0xF7D000 are one-line forwarders; this follows
    each stub's single `call`/`calr` and keeps the ones that land here.  ★ NO
    BODY IS SHARED: all 32 are owned by exactly one screen (check MB)."""
    if "mb" in _c:
        return _c["mb"]
    R7 = screen_runs()
    role = {0: "Enter", 1: "Leave", 2: "Button", 3: "Null"}
    out = {}
    for base, slots in R7.runs():
        title, _l = R7.screen_title(base)
        pl = R7.painter_label(base)
        nm = pl or (R7.slug(title) if title else None)
        for k, slot in enumerate(slots):
            t = R7.slot_target(slot)
            if t is None:
                continue
            tgt = None
            for _a, tx in R7.stub_body(t):
                m = re.match(r"(?:call|calr) 0x([0-9a-f]+)", tx)
                if m:
                    tgt = int(m.group(1), 16)
                    break
            if tgt is not None and LO <= tgt < HI:
                out.setdefault(tgt, []).append((role[k], base, nm))
    _c["mb"] = {a: v[0] for a, v in out.items() if len(v) == 1}
    _c["mb_shared"] = {a: v for a, v in out.items() if len(v) > 1}
    return _c["mb"]


# The two 8-record label rows, named from the ROM's own text.  Kept as data
# rather than derived by a rule, because a rule general enough to find them
# would also fire on rows this pass has no reading of.
LABEL_ROWS = {0xF7E89F: ("Paint_TrackLabels1To8", 0xF3B5D1, "TR 1", "TR 8"),
              0xF7E8B6: ("Paint_TrackLabels9To16", 0xF3B611, "TR 9", "TR16")}


def single_record_veneers():
    """{start: (list address, opcode)} for routines whose whole body is one
    interpreter-A call over a list holding exactly ONE record.

    ⚠ INTERPRETER A ONLY.  Interpreter A puts the SWI7 function number at the
    record's +0, so the opcode IS the service; interpreter B puts it at +6
    (notes/FINDINGS-ui-display-list.md), so a B record's leading byte says
    nothing about which service draws it."""
    out = {}
    for s, e in routines():
        L = lists_in(s, e)
        if len(L) != 1 or L[0][2] != "A":
            continue
        recs = records(L[0][0], L[0][1])
        if len(recs) == 1:
            out[s] = (L[0][0], recs[0][1])
    return out


# prom_a's SWI7 service names, transcribed from its own labels.  Only the
# services this span's single-record lists actually use are listed.
SWI7_NAME = {0x0E: "ClearColumns", 0x1B: "EraseRect", 0x06: "DrawText8x14"}


def names():
    """{start: (label, evidence lines)} -- every label this pass proposes.

    SIX RULES REACH A NAME AND NOTHING ELSE DOES:
      X  byte-identical, over BOTH whole extents, to a named prom_a routine;
      T  draws a display list whose leading op-0x1C run spells a title ->
         Paint_<Title>, the rule round 7 calibrated;
      M  it is the BODY of a named screen's Leave or Button method -> a name
         that says whose method it is (the screen is the distinguishing part,
         not a number);
      L  a label row whose records spell their own text -> Paint_TrackLabels*;
      V  a one-record interpreter-A list whose opcode is a SWI7 service that no
         OTHER routine in the span draws alone -> DrawList_<Service>;
      P  a blink-template pointer table -> BlinkArgPtrs_<addr>, FRAMED.
    Everything else is sub_XXXXXX with the gap stated."""
    if "nm" in _c:
        return _c["nm"]
    out = {}
    twin_by_addr = {t[0]: t for t in TWINS}
    pa, mb = painters(), method_bodies()
    srv = single_record_veneers()
    seen_srv = collections.Counter(op for _l, op in srv.values())
    for s, e in routines():
        if s in twin_by_addr:
            _a, n, ad, n2, lab = twin_by_addr[s]
            out[s] = (lab, [
                "byte-identical to prom_a's %s (0x%06X) over BOTH whole" % (lab, ad),
                "extents: %d bytes here, %d bytes there, differing in 0 of %d" % (n, n2, n),
                "positions.  Each ends at its own `ret`, so this is not a prefix",
                "match.  --selftest re-reads both from the ROM images and",
                "re-compares them."])
            continue
        if s in pa:
            t, lst = pa[s]
            out[s] = ("Paint_" + slug(t), [
                "the routine loads XIY = 0x%06X and calls the display-list" % lst,
                "interpreter; the leading run of op-0x1C records in that list",
                'spells "%s", and the name is that text CamelCased, with the' % t,
                "ROM's own spelling kept (zeros for O's included).  The rule is",
                "round 7's, calibrated on seven screens prom_a had named",
                "independently: notes/prom_b_screens_round8.py --calibrate."])
            continue
        if s in mb and mb[s][0] in ("Leave", "Button") and mb[s][2]:
            role, base, nm = mb[s]
            out[s] = ("Screen%sBody_%s" % (role, nm), [
                "the whole body of screen object 0x%06X's +%d method." % (base, {"Leave": 4, "Button": 8}[role]),
                "prom_a's PanelScreen_VtableTable names that object, and its",
                "readers take +0 Enter, +4 Leave, +8 Button; the stub at 0x%06X"
                % _stub_of(base, role),
                "is `call 0x%06X` then `ret` and nothing else calls this" % s,
                "address.  The screen's own name is round 7's, from its title text."])
            continue
        if s in LABEL_ROWS:
            lab, lst, first, last = LABEL_ROWS[s]
            out[s] = (lab, [
                "the routine's one display list, 0x%06X, holds eight op-0x06" % lst,
                "records -- LCD_Svc_06_DrawText8x14 -- and their text bytes spell",
                '"%s" through "%s", read from the ROM.  The name is that text;' % (first, last),
                'TR is the ROM own abbreviation for a sequencer track, and the',
                "screen that reaches this row is the one whose title spells",
                "TRACK ASSIGN."])
            continue
        if s in srv and seen_srv[srv[s][1]] == 1 and srv[s][1] in SWI7_NAME:
            lst, op = srv[s]
            out[s] = ("DrawList_" + SWI7_NAME[op], [
                "the whole body is `ld XIY,0x00%06X / ld XIX / call 0x%06X / ret`"
                % (lst, 0xF417F0),
                "-- interpreter A over a list holding exactly ONE record, opcode",
                "0x%02X.  Interpreter A puts the SWI7 function number at the" % op,
                "record's +0 (notes/FINDINGS-ui-display-list.md), and prom_a names",
                "service 0x%02X LCD_Svc_%02X_%s.  No other routine in the span"
                % (op, op, SWI7_NAME[op]),
                "draws a single record of this opcode."])
            continue
        out[s] = ("sub_%06X" % s, [])
    for base, n, _pad, vals, reader in ptr_tables():
        out[base] = ("BlinkArgPtrs_%06X" % base, [
            "read by `ld XIY,0x00%06X` at 0x%06X followed by `ld XIY,(XIY+WA)`,"
            % (base, reader),
            "`push XIY` and `call 0x%06X` -- T_Blink_Command, prom_b 0xF0E9CF"
            % BLINK_CMD,
            "(notes/FINDINGS-prom_b-field-blink.md).  Same shape, same callee and",
            "the same two leading NULL entries as prom_a's BlinkArgPtrs_F8024D.",
            "FRAMED on purpose: nothing bounds the index, and what the %d"
            % sum(1 for v in vals if v),
            "templates it names are for is not established."])
    _c["nm"] = out
    return out


def _stub_of(base, role):
    """The stub address of screen `base`'s method, for the evidence line."""
    R7 = screen_runs()
    k = {"Enter": 0, "Leave": 1, "Button": 2, "Null": 3}[role]
    for b, slots in R7.runs():
        if b == base and len(slots) > k:
            return R7.slot_target(slots[k]) or 0
    return 0


def grade(lab):
    import wave7_documentation_metrics as M
    if M.UNNAMED.match(lab):
        return "unnamed"
    return "framed" if M.FRAMED.match(lab) else "content"


# ------------------------------------------------------------- the census
def button_census():
    inspan = [(t, i, v) for t, i, v in button_slots() if LO <= v < HI]
    tgt = sorted({v for _t, _i, v in inspan})
    rets = [v for v in tgt if byte(v) == 0x0E]
    slots_ret = sum(1 for _t, _i, v in inspan if byte(v) == 0x0E)
    return dict(slots=len(button_slots()), inspan=len(inspan), targets=len(tgt),
                ret_targets=len(rets), ret_slots=slots_ret,
                code_targets=len(tgt) - len(rets),
                code_slots=len(inspan) - slots_ret, rets=rets)


def screen_runs():
    """Round 7's 25 screen objects, imported rather than re-derived."""
    if "sr" not in _c:
        import prom_b_entrypoints_round7 as R7
        _c["sr"] = R7
    return _c["sr"]


def table_owner():
    """{button table base: [screen title or base]} -- which screen loads it.

    The `ld XIX,imm32` immediates of the +8 Button stubs, read from prom_b's
    ALREADY-CONVERTED text at 0xF7D000."""
    R7 = screen_runs()
    out = collections.defaultdict(list)
    for base, slots in R7.runs():
        title, _l = R7.screen_title(base)
        who = title or ("screen 0x%06X" % base)
        if len(slots) > 2:
            t = R7.slot_target(slots[2])
            if t is None:
                continue
            kind, det = R7.shape(t)
            if kind == "table":
                for tb in det[0]:
                    out[tb].append(who)
    return out


# ------------------------------------------------------------------ output
def print_entries():
    ep = entry_points()
    for a in sorted(ep):
        kind = "ret " if byte(a) == 0x0E else "code"
        print("  0x%06X %s  %s" % (a, kind, "; ".join(ep[a][:3])))
    print("  %d entry points, %d of them a single `ret` byte"
          % (len(ep), sum(1 for a in ep if byte(a) == 0x0E)))


def print_tables():
    for base, n, pad, vals, reader in ptr_tables():
        print("  BlinkArgPtrs_%06X  %d entries + %d pad byte(s), reader 0x%06X"
              % (base, n, pad, reader))
        for k, v in enumerate(vals):
            print("      [%d] 0x%08X" % (k, v))


def print_routines():
    nm = names()
    for s, e in routines():
        print("  0x%06X-0x%06X %5d  %-28s %s"
              % (s, e - 1, e - s, nm[s][0], grade(nm[s][0])))
    print("  %d routines" % len(routines()))


def print_names():
    nm = names()
    g = collections.Counter(grade(v[0]) for v in nm.values())
    for s in sorted(nm):
        lab, ev = nm[s]
        if ev:
            print("  0x%06X  %-32s %s" % (s, lab, grade(lab)))
    print("  content %d, framed %d, unnamed %d"
          % (g["content"], g["framed"], g["unnamed"]))


def print_calibrate():
    """Round 7's calibration, re-run, plus the transcription check this pass adds."""
    R7 = screen_runs()
    ok_prefix = ok_exact = tot = 0
    print("  A. ROUND 7'S CALIBRATION, RE-RUN: screens whose Enter method is in")
    print("     prom_a, where prom_a named the painter independently months ago.")
    for base, _slots in R7.runs():
        pl = R7.painter_label(base)
        if not pl:
            continue
        title, _l = R7.screen_title(base)
        derived = R7.slug(title) if title else ""
        tot += 1
        pre = pl.startswith(derived) and derived != ""
        ex = pl == derived
        ok_prefix += pre
        ok_exact += ex
        print("     0x%06X  prom_a Paint_%-26s derived %-26s %s"
              % (base, pl, derived, "EXACT" if ex else ("prefix" if pre else "MISS")))
    print("     %d of %d prefix, %d of %d exact" % (ok_prefix, tot, ok_exact, tot))
    print()
    print("  B. THE CHECK THIS CONVERSION ADDS -- a TRANSCRIPTION check, not a")
    print("     calibration: the title round 7 read from the ROM through unidasm")
    print("     must equal the title read from this span's own emitted decode.")
    agree = 0
    pa = painters()
    for base, _slots in R7.runs():
        ent = R7.slot_target(base)
        if ent is None:
            continue
        body = R7.stub_body(ent)
        tgt = None
        for _a, t in body:
            m = re.match(r"(?:call|calr) 0x([0-9a-f]+)", t)
            if m:
                tgt = int(m.group(1), 16)
                break
        if tgt is None or not (LO <= tgt < HI):
            continue
        r7title, _l = R7.screen_title(base)
        mine = pa.get(tgt, ("", 0))[0]
        same = (r7title or "") == (mine or "")
        agree += same
        print("     0x%06X -> 0x%06X  round7 %-24r here %-24r %s"
              % (base, tgt, r7title, mine, "agree" if same else "DIFFER"))
    print("     %d agree" % agree)


def print_screens4():
    R7 = screen_runs()
    print("  The four screen objects round 7 could not name, and why the evidence")
    print("  still does not reach them:")
    for base in (0xF43040, 0xF43048, 0xF43160, 0xF431D0):
        ent = R7.slot_target(base)
        tgt = None
        for _a, t in R7.stub_body(ent):
            m = re.match(r"(?:call|calr) 0x([0-9a-f]+)", t)
            if m:
                tgt = int(m.group(1), 16)
                break
        where = "IN THIS SPAN" if (tgt and LO <= tgt < HI) else "prom_a"
        if tgt is not None and LO <= tgt < HI:
            _e = next(e for st, e in routines() if st == tgt)
            where += ", 0x%06X-0x%06X" % (tgt, _e - 1)
        if tgt is None:
            print("    0x%06X  no call in the stub at all" % base)
            continue
        if LO <= tgt < HI:
            end = next(e for st, e in routines() if st == tgt)
            n = len(lists_in(tgt, end))
        else:
            n = prom_a_lists(tgt)
        lab = existing(SRCA if tgt >= A_BASE else SRCB).get(tgt, "-")
        print("    0x%06X  Enter -> 0x%06X (%s, %s): %d display-list call(s)"
              % (base, tgt, where, lab, n))
    print("  ★ 0xF43160 and 0xF431D0 have the SAME Enter method, so a rule that")
    print("    names a screen after what its Enter draws cannot separate them.")


def prom_a_lists(start, span=0x180):
    """Display-list interpreter calls in prom_a's ALREADY-CONVERTED text, counted
    from its own `.s` lines rather than re-disassembled."""
    n, xiy, xix = 0, None, None
    for ln in open(SRCA, encoding="utf-8"):
        m = re.search(r";\s*([0-9A-F]{6})\b", ln)
        if not m:
            continue
        a = int(m.group(1), 16)
        if a < start or a >= start + span:
            continue
        if re.search(r"ld XIY,0x00[0-9a-f]{6}", ln):
            xiy = 1
        if re.search(r"ld XIX,0x00[0-9a-f]{6}", ln):
            xix = 1
        if re.search(r"call 0xf417f[04]", ln) and xiy and xix:
            n += 1
        if re.match(r"\s*ret\b", ln):
            break
    return n


def print_buttons():
    c = button_census()
    own = table_owner()
    print("  the 32 tables at 0x%06X hold %d slots" % (BTN_LO, c["slots"]))
    print("  %d of them land in this span, naming %d distinct addresses"
          % (c["inspan"], c["targets"]))
    print("  %d of those addresses are a single `ret` byte, covering %d slots (%.1f%%)"
          % (c["ret_targets"], c["ret_slots"], 100.0 * c["ret_slots"] / c["inspan"]))
    print("  %d are real code, covering %d slots" % (c["code_targets"], c["code_slots"]))
    print("  ★ the %d `ret` addresses get NO LABEL: each is annotated as a trailing"
          % c["ret_targets"])
    print("    comment on the `ret` line it falls on, so the tree gains the fact")
    print("    without gaining %d framed labels." % c["ret_targets"])
    print()
    print("  which screen loads which table (from the +8 stubs' `ld XIX` immediates):")
    for t in sorted(own):
        print("    0x%06X  %s" % (t, " / ".join(own[t])))


def print_refused():
    print("  R1  NAMING A BUTTON HANDLER AFTER ITS INDEX.  124 of the span's")
    print("      routines are reached only from a button table, and what")
    print("      distinguishes one from the next is the button NUMBER.  Round 6")
    print("      refused Write3602_Index5 for exactly that -- a bare number grades")
    print("      as content while stating nothing.  They keep sub_XXXXXX and a")
    print("      header naming the screen and the index.")
    print("  R2  A BUTTON VOCABULARY WAS LOOKED FOR AND NOT FOUND.  prom_a's")
    print("      PanelButton_Route special-cases indices 0x0D (the data dial),")
    print("      0x0E and 0x0F, and that is the whole of the ROM's own naming of")
    print("      the 32 codes.  The service screen Paint_PanelSwLedCheck, which")
    print('      would be the natural place for a list, draws "Please push a any')
    print('      button." and no per-switch text.  So there is nothing to map an')
    print("      index onto, and inventing one is how five prom_a labels were")
    print('      built on a morpheme ("Home") that occurs zero times in the ROMs.')
    ep = entry_points()
    multi = sorted((a for a, w in ep.items()
                    if byte(a) != 0x0E
                    and len([r for r in w if not r.startswith("button")]) > 1),
                   key=lambda a: -len(ep[a]))
    print("  R3  NAMING THE PAINTERS' CALLEES FROM THEM.  A painter's own title")
    print("      does not transfer to a helper it calls, because a helper can")
    print("      serve several screens.  %d of the span's routines have more than"
          % len(multi))
    print("      one non-button caller; the busiest are %s."
          % ", ".join("0x%06X (%d sites)"
                      % (a, len([r for r in ep[a] if not r.startswith("button")]))
                      for a in multi[:3]))
    print("      Only the routine that DRAWS the titled list is named after it.")
    print("  R4  SPLITTING THE 190 `ret` TARGETS INTO OBJECTS.  Each is one byte")
    print("      inside another routine's tail; labelling them would add 190")
    print("      framed labels for a fact a comment states exactly as well.")


# --------------------------------------------- PROMOTION: framed -> content
def promotions():
    """{old label: (new label, evidence sentence)} for the 32 button tables.

    ★ THIS IS THE ONE FRAMED->CONTENT MOVE THIS ROUND HAS.  The 32 tables at
    0xF7D2D8 carry `Table_<address>` -- a kind plus an address, which the
    documentation metric grades FRAMED and which says nothing about what the
    table is for.  Round 7 established what they ARE (one screen's 32 panel
    buttons) and this pass has the owner map, so each can carry the SCREEN's
    name instead, which is what the object is for.

    ⚠ WHERE A SCREEN HAS TWO TABLES the distinguishing part is NOT a position.
    The +8 stub is `ld XIX,<T1> / cp (flag),0x00 / jr Z,<skip> / ld XIX,<T2>`,
    so T1 is the map used when the flag byte is ZERO and T2 the one used when it
    is not.  The names say that -- `..._0C10Zero` / `..._0C10NonZero` -- and NOT
    `_A`/`_B`, which would be an index wearing a letter.  What the flag MEANS is
    still not established, and neither name claims it is."""
    if "pr" in _c:
        return _c["pr"]
    R7 = screen_runs()
    out = {}
    for base, slots in R7.runs():
        if len(slots) <= 2:
            continue
        t = R7.slot_target(slots[2])
        if t is None:
            continue
        kind, det = R7.shape(t)
        if kind != "table":
            continue
        tabs, flag = det
        title, _l = R7.screen_title(base)
        nm = R7.painter_label(base) or (R7.slug(title) if title else None)
        if not nm:
            continue
        for k, tb in enumerate(tabs):
            if len(tabs) == 1:
                new = "ButtonTable_%s" % nm
                ev = ("the +8 Button stub at 0x%06X loads it with a single "
                      "`ld XIX,0x00%06X`" % (t, tb))
            else:
                new = "ButtonTable_%s_%04XZero" % (nm, flag) if k == 0 else \
                      "ButtonTable_%s_%04XNonZero" % (nm, flag)
                ev = ("the +8 Button stub at 0x%06X loads it when (0x%04X) is %s"
                      % (t, flag, "zero" if k == 0 else "non-zero"))
            out["Table_%06X" % tb] = (new, ev)
    _c["pr"] = out
    return out


# ---- the prose detector the briefing requires, and the proof that it fires ---
def detect(lines, labels):
    """[(rule, line number, text)] for prose a rename can break.

    D1  a RANGE SHORTHAND `Foo_x-Bar_y` naming labels that no longer both exist.
        Round 6's thunk pass broke four of these.
    D2  a TAUTOLOGY: `; <Label> -- <text>` where the text, lower-cased and
        stripped of punctuation, is exactly the label's own words.  Round 6 made
        six of these."""
    hits = []
    for i, ln in enumerate(lines, 1):
        if not ln.lstrip().startswith(";"):
            continue
        for m in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]{3,})-([A-Za-z_][A-Za-z0-9_]{3,})\b", ln):
            a, b = m.group(1), m.group(2)
            if (a in labels or b in labels) and not (a in labels and b in labels):
                hits.append(("D1", i, ln.strip()))
        m = re.match(r"^;\s*([A-Za-z_][A-Za-z0-9_]*)\s+--\s+(.*)$", ln.strip())
        if m:
            words = re.findall(r"[A-Z]?[a-z0-9]+", m.group(1))
            txt = re.sub(r"[^a-z0-9 ]", " ", m.group(2).lower()).split()
            if words and [w.lower() for w in words] == txt:
                hits.append(("D2", i, ln.strip()))
    return hits


def detector_selftest():
    """★ PROVE THE DETECTOR FIRES.  A detector that has never returned a hit is
    not evidence of anything, which is why this exists and is run by --promote
    BEFORE the rename and by --selftest always."""
    labs = {"ButtonTable_Edit", "Keep_Me"}
    corpus = ["; the run ButtonTable_Edit-Table_F7E258 is the whole block",
              "; ButtonTable_Edit -- button table edit",
              "; a line that should not fire at all",
              "\tret\t; F7E2D8  ret"]
    got = detect(corpus, labs)
    return sorted(r for r, _i, _t in got) == ["D1", "D2"]


def print_promote():
    apply_ = "--apply" in sys.argv
    pm = promotions()
    src = open(SRCB, encoding="utf-8").read()
    lines = src.split("\n")
    labels = set(re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l).group(1)
                 for l in lines if re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l))
    print("  detector self-test (D1 and D2 must both fire): %s"
          % ("PASS" if detector_selftest() else "FAIL"))
    if not detector_selftest():
        raise SystemExit("refusing to rename: the prose detector does not fire")
    before = detect(lines, labels)
    print("  prose defects BEFORE the rename: %d" % len(before))
    done = sum(1 for old in pm if old not in labels)
    print("  %d promotions, %d already applied" % (len(pm), done))
    for old in sorted(pm):
        new, ev = pm[old]
        n = src.count(old)
        print("    %-16s -> %-40s (%d occurrence(s))  %s"
              % (old, new, n, "" if n else "ALREADY APPLIED"))
    if not apply_:
        print("  (dry run; add --apply to write)")
        return
    new_src = src
    # ★ IDEMPOTENT REFLOW.  The first --apply wrote the Evidence sentence on one
    # over-long line; re-running --apply fixes it in place and changes nothing
    # else, so the script and the file agree however many times it is run.
    new_src = re.sub(
        r"; Evidence: (the \+8 Button stub at 0x[0-9A-F]{6} loads it[^\n]*?\.)  "
        r"(Round 7 established)",
        lambda m: "; Evidence: %s\n;           %s" % (m.group(1), m.group(2)),
        new_src)
    for old in sorted(pm):
        new, ev = pm[old]
        if old + ":" not in new_src:
            continue
        blk = ("; %s -- the 32 panel-button handlers of this screen\n"
               "; Evidence: %s.\n"
               ";           Round 7 established that the 32 tables are indexed\n"
               ";           by the panel BUTTON NUMBER (two independent 5-bit masks\n"
               ";           over a 128-byte table), so what the object needs is the\n"
               ";           SCREEN that owns the map -- which is this name.  ⚠ What\n"
               ";           the selector byte MEANS is still not established.\n"
               ";           Promoted from the framed `Table_<address>` spelling by\n"
               ";           notes/prom_b_screens_round8.py --promote --apply\n"
               "%s:" % (new, ev, new))
        new_src = new_src.replace("%s:" % old, blk)
        new_src = new_src.replace(old + " ", new + " ").replace(old + ",", new + ",")
    open(SRCB, "w", encoding="utf-8").write(new_src)
    lines = new_src.split("\n")
    labels = set(re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l).group(1)
                 for l in lines if re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l))
    after = detect(lines, labels)
    left = sum(new_src.count(o) for o in pm)
    print("  applied.  old labels still present: %d (must be 0)" % left)
    print("  prose defects AFTER the rename: %d (was %d)" % (len(after), len(before)))
    for r, i, t in after[:5]:
        print("    %s line %d: %s" % (r, i, t[:100]))


# ---------------------------------------------------------------- JOB 2
SHAPES_DOC = """The four mechanical shapes round 6 used, measured across ALL of
prom_b's sub_XXXXXX routines -- what each one WOULD reach if it were applied.

⚠ THIS PASS MEASURES AND DOES NOT RENAME.  Round 6's thunk pass renamed in bulk
and broke four range shorthands and turned six sentences into tautologies; the
briefing for this round says a mass rename must be followed by a prose audit and
a detector that fires.  The numbers below are the input to that decision, not
the decision.  Read them as an upper bound: a shape MATCHING is not the same as
the name it would produce being CONTENT -- 'a bare ret' and 'a stub that calls
table entry HL' say what the code is, not what it is for."""


def shapes():
    """{shape: [sub_XXXXXX label, ...]} over prom_b's whole .s.

    A routine's body is the instruction lines between its label and the next
    label at column 0.  Only `sub_XXXXXX` labels are considered."""
    if "sh" in _c:
        return _c["sh"]
    body, cur, out = [], None, collections.defaultdict(list)
    def flush(lab, b):
        if lab is None or not b:
            return
        m = [t for t in b]
        if m == ["ret"]:
            out["bare ret"].append(lab)
        elif len(m) == 2 and m[1] == "ret" and m[0].split()[0] in ("call", "calr"):
            out["one-line forwarder"].append(lab)
        elif (m[0].startswith("ld XIX,0x00") and m[-1] == "ret"
              and any("call 0xf41b08" in t for t in m)):
            out["table-call stub"].append(lab)
        elif (len(m) == 2 and m[1] == "ret"
              and re.match(r"ld \((0x[0-9a-f]+)\),", m[0])):
            out["single-cell writer"].append(lab)
        else:
            out["none of the four"].append(lab)
    for ln in open(SRCB, encoding="utf-8"):
        lm = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", ln)
        if lm:
            flush(cur, body)
            cur, body = (lm.group(1) if lm.group(1).startswith("sub_") else None), []
            continue
        m = re.search(r";\s*[0-9A-F]{6}\s+(.*)$", ln)
        if m and cur:
            body.append(m.group(1).split("[llvm-mc")[0].strip())
    flush(cur, body)
    _c["sh"] = out
    return out


def print_shapes():
    print(SHAPES_DOC)
    print()
    sh = shapes()
    tot = sum(len(v) for v in sh.values())
    for k in ("bare ret", "one-line forwarder", "table-call stub",
              "single-cell writer", "none of the four"):
        v = sh.get(k, [])
        print("  %-22s %5d   %s" % (k, len(v), ", ".join(v[:4]) + ("" if len(v) <= 4 else " ...")))
    print("  %-22s %5d" % ("sub_XXXXXX total", tot))
    print()
    print("  ★ REPORTED INCLUDING THE ZEROS.  A shape with 0 hits is a result: it")
    print("    says the cluster round 6 found in one span does not exist here.")


def print_cost():
    nm = names()
    g = collections.Counter(grade(v[0]) for v in nm.values())
    print("  bytes converted        : %d" % (HI - LO))
    print("  labels added           : %d" % len(nm))
    print("      content %d, framed %d, unnamed (sub_XXXXXX) %d"
          % (g["content"], g["framed"], g["unnamed"]))
    print("  labels NOT added       : %d (the `ret` button targets, R4)"
          % button_census()["ret_targets"])
    print("  framed -> content        : %d (the 32 button tables, --promote)"
          % len(promotions()))
    print()
    print("  ⚠ only %.1f%% of the labels the SPLICE adds are content, against prom_b's"
          % (100.0 * g["content"] / len(nm)))
    print("    standing 16.2%, so the splice alone LOWERS the bound.  The promotion")
    print("    more than pays for it.  MEASURED with wave7_documentation_metrics.py,")
    print("    three runs in one session:")
    print()
    print("      prom_b            content  framed  sub_XXXX  LOWER  UPPER  hdr   ev")
    print("      before                953   3,087     1,851  16.2%  68.6% 3,233 3,057")
    print("      after the splice      983   3,092     2,031  16.1%  66.7% 3,268 3,272")
    print("      after --promote     1,015   3,060     2,031  16.6%  66.7% 3,299 3,304")
    print()
    print("    ⚠ UPPER falls 68.6%% -> 66.7%% either way: %d new sub_XXXXXX is %d new"
          % (g["unnamed"], g["unnamed"]))
    print("    objects nobody has named.  Quote both bounds; the gap between them is")
    print("    the work this span still owes.")


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
    ep, rt, pt = entry_points(), routines(), ptr_tables()
    cen = button_census()
    c("EP    every entry point is inside [0x%06X,0x%06X)" % (LO, HI),
      sorted(a for a in ep if not (LO <= a < HI)), [], verbose)
    c("EP    the LOWEST entry point is 0x%06X -- the span's own first byte, which"
      " is a `ret` a button table names" % LO, (min(ep), byte(LO)), (LO, 0x0E), verbose)
    c("EP    the HIGHEST entry point is 0x%06X and it is real code" % max(ep),
      (max(ep), byte(max(ep)) != 0x0E), (0xF7FFFB, True), verbose)
    c("RT    the routines tile [first start, 0x%06X) with no gap" % HI,
      [(rt[i][1], rt[i + 1][0]) for i in range(len(rt) - 1) if rt[i][1] != rt[i + 1][0]],
      [], verbose)
    c("RT    the LAST routine ends exactly at 0x%06X" % HI, rt[-1][1], HI, verbose)
    c("PT    five pointer tables, every one found by its own reader", len(pt), 5, verbose)
    for base, n, pad, vals, reader in pt:
        c("PT    0x%06X: reader 0x%06X, %d entries, %d pad, entries 0 and 1 NULL"
          % (base, reader, n, pad), (vals[0], vals[1], n >= 4), (0, 0, True), verbose)
    last = pt[-1]
    c("PT    ★ LAST TABLE 0x%06X + %d*4 = 0x%06X, which is the next entry point"
      % (last[0], last[1], last[0] + 4 * last[1]),
      (last[0] + 4 * last[1] + last[2]) in entry_points(), True, verbose)
    for a, n, ad, n2, lab in TWINS:
        c("TWIN  0x%06X == prom_a 0x%06X (%s): %d bytes, 0 differ"
          % (a, ad, lab, n),
          (bs(a, n) == bs(ad, n2), n, n2), (True, n, n2), verbose)
    c("TWIN  ...and the byte AFTER each twin's extent is a new entry point or a "
      "`ret`", [a + n for a, n, _b, _c2, _l in TWINS
                if (a + n) not in entry_points() and byte(a + n) != 0x0E], [], verbose)
    c("BTN   %d of the 1,024 button slots land in the span" % cen["inspan"],
      (cen["slots"], cen["inspan"]), (1024, 649), verbose)
    c("BTN   they name %d distinct addresses, %d of which are one `ret` byte"
      % (cen["targets"], cen["ret_targets"]),
      (cen["targets"], cen["ret_targets"]), (314, 190), verbose)
    c("BTN   the %d `ret` addresses cover %d slots" % (cen["ret_targets"], cen["ret_slots"]),
      cen["ret_slots"], 510, verbose)
    c("BTN   ...and NONE of them is a routine start",
      [a for a in cen["rets"] if a in routine_starts()], [], verbose)
    pa = painters()
    c("TITLE the title rule reaches %d routines in the span" % len(pa),
      len(pa), 14, verbose)
    c("TITLE every derived title is non-empty and yields a CONTENT grade",
      sorted({grade("Paint_" + slug(t)) for t, _l in pa.values()}), ["content"], verbose)
    # ★ the LAST element, not just the first
    ls = sorted(pa)
    c("TITLE ★ the LAST painter 0x%06X derives %r from list 0x%06X"
      % (ls[-1], pa[ls[-1]][0], pa[ls[-1]][1]),
      (ls[-1], pa[ls[-1]][0]), (0xF7FF27, "ADVANCE/DELAY"), verbose)
    R7 = screen_runs()
    same = []
    for base, _s in R7.runs():
        ent = R7.slot_target(base)
        if ent is None:
            continue
        for _a, t in R7.stub_body(ent):
            m = re.match(r"(?:call|calr) 0x([0-9a-f]+)", t)
            if m:
                same.append((base, int(m.group(1), 16)))
                break
    d = collections.Counter(t for _b, t in same)
    c("S4    0xF43160 and 0xF431D0 share ONE Enter method, prom_a 0xF8101E",
      sorted(b for b, t in same if t == 0xF8101E), [0xF43160, 0xF431D0], verbose)
    c("S4    ...and it is the only Enter method two screens share",
      [t for t, n in d.items() if n > 1], [0xF8101E], verbose)
    nm = names()
    c("NAME  every routine start has a proposal",
      sorted(s for s, _e in routines() if s not in nm), [], verbose)
    g = collections.Counter(grade(v[0]) for v in nm.values())
    c("NAME  %d content, %d framed, %d unnamed" % (g["content"], g["framed"], g["unnamed"]),
      (g["content"], g["framed"]), (30, 5), verbose)
    mb = method_bodies()
    c("MB    %d screen-method bodies land in the span and NONE is shared" % len(mb),
      (len(mb), _c["mb_shared"]), (36, {}), verbose)
    c("MB    ...11 Leave bodies and 1 Button body are real code on a NAMED screen",
      collections.Counter(r for r, _b, n in mb.values()
                          if n and byte(_k) != 0x0E for _k in [0])
      if False else
      sorted(collections.Counter(
          r for a, (r, _b, n) in mb.items()
          if n and byte(a) != 0x0E and r in ("Leave", "Button")).items()),
      [("Button", 1), ("Leave", 11)], verbose)
    srv = single_record_veneers()
    seen = collections.Counter(op for _l, op in srv.values())
    c("V     ★ THE ONE-RECORD-VENEER RULE REACHED ZERO: %d such routines, but "
      "no opcode is unique to one of them" % len(srv),
      sorted(seen.values()), [3, 7], verbose)
    c("PROM  32 button tables are promoted from Table_<addr> to ButtonTable_<screen>",
      len(promotions()), 32, verbose)
    c("PROM  every promoted name grades CONTENT, none of them FRAMED",
      sorted({grade(n) for n, _e in promotions().values()}), ["content"], verbose)
    c("PROM  ★ the prose detector FIRES on a corpus built to break it (D1 and D2)",
      detector_selftest(), True, verbose)
    if verbose and FAIL:
        print("\n%d FAILED:\n%s" % (len(FAIL), "\n".join("  " + f for f in FAIL)))
    return not FAIL


def main():
    a = sys.argv[1:]
    if "--selftest" in a:
        return 0 if checks() else 1
    did = False
    for flag, fn in (("--entries", print_entries), ("--tables", print_tables),
                     ("--routines", print_routines), ("--names", print_names),
                     ("--calibrate", print_calibrate), ("--screens4", print_screens4),
                     ("--buttons", print_buttons), ("--refused", print_refused),
                     ("--shapes", print_shapes), ("--promote", print_promote),
                     ("--cost", print_cost)):
        if flag in a:
            fn()
            did = True
    if not did:
        print("  span 0x%06X-0x%06X, %d bytes" % (LO, HI - 1, HI - LO))
        print("  %d entry points, %d routine starts, %d pointer tables"
              % (len(entry_points()), len(routine_starts()), len(ptr_tables())))
        print_cost()
    return 0


if __name__ == "__main__":
    sys.exit(main())
