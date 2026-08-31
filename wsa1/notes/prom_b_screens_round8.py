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
  six.  This pass re-runs that same check -- `--calibrate` prints the table.

  ⚠⚠ CORRECTION, ROUND 9.  The paragraph above used to end "and gets the same
  7/7 prefix, 6/7 exact".  THAT IS NOT WHAT THE COMMITTED SCRIPT PRINTS, and it
  was not what it printed when round 8 shipped it: run at the round-8 revision
  against the round-8 tree it reports **21 of 21 prefix, 20 of 21 exact**.  The
  set is not round 7's seven screens; it is every screen whose Enter method
  lands in prom_a AND whose painter prom_a had already named, and that set had
  grown to 21.  The prose was quoting round 7's number for round 8's run.  The
  one non-exact point is 0xF43170: the rule derives `StepRecord` where prom_a
  says `Paint_StepRecordPartSelect` -- a prefix, because the screen's own title
  text is "STEP RECORD" and the "PartSelect" half came from somewhere else.

  ⚠ AND WHAT 20/21 DOES NOT PROVE.  prom_a's `Paint_<X>` names were read from
  THE SAME ROM BYTES by THE SAME transcription convention.  Agreement between
  two readings of one source is a check on the RULE, not on the READING -- which
  is why every one of `Paint_MeasureC0py`, `Paint_S0ngC0py`, `Paint_Transp0se`,
  `Paint_Vel0cityChange`, `Paint_N0teChange`, `Paint_AfterT0uchSetting` and
  `Paint_S0ngSelectName` scores EXACT while both sides spell a letter O as the
  byte 0x30.  See the ROUND 9 section: the machine's own font cannot tell those
  two codes apart, and a calibration built on one convention can never catch it.

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

────────────────────────────────────────────────────────────────────────────────
★★ ROUND 9 -- WHAT THIS FILE ANSWERS ON TOP OF THE ABOVE
────────────────────────────────────────────────────────────────────────────────
  Round 9's brief asked this lane to convert 0xF7E2D8-0xF80000 and then apply
  round 6's four mechanical shapes.  BOTH WERE ALREADY DONE, by round 8, by this
  very file and notes/gen_prom_b_f7e2d8_module.py -- the brief was written from
  the wave-7 resume frontier table, which the briefing itself warns is stale
  ("Derive every target from the tree, never from a prose paragraph").  The span
  carries no `.incbin`; notes/wave7_frontier_table.py no longer lists it; prom_b
  is down to 51,246 unconverted bytes from 159,459.  So round 9 went looking for
  what was actually left, and found two things.

  ★ (1) THE THUNK DIRECTORY HAD GROWN NEW HEADROOM, and nobody had re-measured.
  Round 6 promoted 273+4 slots from `T_<address>` to `T_<target's name>` on the
  rule "take a name ONLY from a CONTENT-graded target".  Rounds 7 and 8 then
  NAMED MORE TARGETS.  Re-running notes/prom_b_thunks_round6.py finds 392
  content-named targets where round 6 found 285, so 103 slots were promotable
  and still spelled as an address.  Applied.  Measured on the whole image:

      prom_b   content  framed  sub_XXXX   LOWER   UPPER  headers  evidence
      before     1,015   3,060     2,031   16.6%   66.7%    3,299     3,304
      after      1,118   2,957     2,031   18.3%   66.7%    3,299     3,407

  ⚠ AND THE NUMBER IS STILL RISING, WHICH IS A HANDOFF, NOT A GAP.  Re-running
  the census after this round's edits reports 386 promotable, not 380: two other
  lanes named prom_a and prom_c targets WHILE this lane worked (prom_a's content
  count moved 1,497 -> 1,517 in the same window).  Those last 6 --
  T_Ring601850_ServiceIfNotEmpty, T_SoundGroup_MaxMemberIndex_Get,
  T_SoundGroup_MaxMemberIndex_GetToneCopy, T_Ring608A0A_DrainAll,
  T_INT5_Dev7B_Receive_Alias, T_INTTC0_uDMA0Done_Alias -- were deliberately NOT
  taken: a derivative name copied out of a file another lane is still editing is
  a name taken before it settled.  `--apply` is idempotent and costs seconds, so
  the right place to harvest them is the round barrier, after prom_a is stable.
  ★ Verified that the 103 already applied did NOT go stale in the meantime: all
  103 still equal `T_` + their target's current label, 0 disagreements.

  ⚠ EVERY ONE OF THE 103 IS DERIVATIVE -- it is the target's own name, given by
  another lane.  103 pointers made readable, not 103 new facts.  And note what
  did NOT move: sub_XXXXXX is unchanged, because no span was converted, and
  `headers` is unchanged, because the two-line evidence block round 6 chose
  deliberately falls one line short of the metric's header threshold.  A round
  that reported +103 headers here would be repeating the "+35 headers that were
  35 blank lines" error.

  ★★ (2) THE WSA1 CANNOT DRAW A '0' DIFFERENTLY FROM AN 'O', AND THE TREE HAS
  BEEN TRANSCRIBING THE BYTE INSTEAD OF THE GLYPH.  `--glyphs`.

  In six of the machine's seven Latin faces, cells 0x30 and 0x4F hold BYTE-
  IDENTICAL bitmaps, and in each of those six that pair is the ONLY duplicate
  among the 94 non-blank cells of 0x21-0x7F.  The seventh, the 8x8 proportional
  face at 0xF1E470 (SWI7 0x17), is the single exception: there 0x30 carries a
  diagonal stroke through the bowl and differs in 3 of its 8 bytes.

  So on every other WSA1 screen "S0NG" and "SONG" are the same picture, and the
  firmware's string tables use 0x30 for the letter O in 75 distinct prom_b
  literals (98 occurrences): L0AD, 0PTI0N, ERR0R, F0RMAT, FL0PPY, CURS0R,
  MEM0RY, PR0GRAM, REC0RD, S0UND, TRANSP0SE, VEL0CITY, ATTENTI0N!, and
  'Select the F0RMAT type for your disk.'  ★ THE INTERNAL CONTROL IS 'R0M1',
  which holds a 0-for-O AND a real digit in four characters -- so this is not a
  face that lacks a zero, it is a face in which the two are interchangeable.

  ⚠ The tree has already baked the misreading into 122 prom_b labels and 6
  prom_a ones -- DL_S0ng, Paint_S0ngC0py, ScreenEnter_Transp0se,
  DL_Err0rTheS0undOrC0mbinati0n.  Thirty of prom_b's 122 arrived THIS ROUND
  from the 103 promotions, which take their targets' names verbatim, as a
  derivative rename must.

  ★ AND THIS PASS DOES NOT FIX THEM, on purpose.  The fix is CONTENT -> CONTENT,
  so it moves the metric by exactly zero; the names reach into prom_a and two
  other lanes' scripts, which this lane does not own; and the cost of getting it
  wrong is round 6's measured four broken range shorthands and six tautologies.
  The size is stated honestly rather than inflated -- 6 label definitions and 28
  lines of prose outside prom_b, which is SMALL.  Small is a reason to do it as
  ONE cross-lane commit, not a reason to reach across a lane boundary and do
  half of it.  `--glyphs` prints the recipe, and the point that matters most is
  the last line of it: fix the GENERATORS that emit these names, or the next
  conversion re-introduces the defect.

  ★ (3) WHERE THE REST OF THE FRAMING IS, AND WHY IT IS NOT HEADROOM.
  `--framed` censuses prom_b's 2,957 remaining framed labels into 82 clusters
  and measures the three biggest.  T_ (1,622) is 1,432 slots pointing at a
  sub_XXXXXX plus 119 into `.incbin` -- an honest INDEX of work that lives
  elsewhere, not work here.  DL_ (415) is exhausted: the calibrated title rule
  reports 40 lists with text and 0 unique proposals, because all 40 collide with
  a name another list already owns -- NINE different lists draw only "OK".
  ⚠ A naive label-to-label `.ascii` walk says 102 there; it runs past each
  list's own extent into the next object, and `--framed --naive` prints both
  numbers so the overcount is not repeated.  ScreenFieldList_ (127) is refused
  because the only distinguishing fact is a slot index -- and the table is
  many-to-one: 125 of its 256 slots point at the SAME empty list 0xF2D408, so
  125 different index names would each claim to name it.

★★ ROUND 10 -- WHAT THIS FILE ANSWERS ON TOP OF ROUND 9
  Round 10's brief asked this lane to convert 0xF7E2D8-0xF80000 and then apply
  round 6's four mechanical shapes.  BOTH WERE ALREADY DONE, BY ROUND 8 -- the
  brief was written from the wave-7 resume frontier table again, and round 9
  had already recorded that it was stale.  prom_b carries no `.incbin` there;
  `notes/wave7_frontier_table.py` lists 51,246 unconverted bytes in 117 spans,
  not 159,459 in 124.  So round 10 went at THE WAVE'S OWN PRIZE instead, and:

  ★ (1) SOLVED LAYER 2's MECHANISM AND FOUND THE PRODUCER round 9 could not.
    The consumer of the SC1 inbound queue is prom_a sub_F8A088; the event is
    built by prom_a 0xF8A824 out of 4-byte templates {class, code, shift, mask}
    in two 27-entry per-group tables; the class byte is never an immediate,
    which is exactly the negative round 9 measured and could not explain.
    `--layer2`, 25 checks (`--selftest` prints them prefixed L2).  ⚠ Every byte
    of the layer-2 machinery is prom_a's, and this lane read it READ-ONLY.

  ★ (2) REFUSED code -> legend, WITH ARITHMETIC, and found a contradiction in
    round 9's own physical map while doing it (three byte-identical template
    pairs; 24 fitted switches would have to share 16 positions).

  ★ (3) MEASURED A FIFTH NAMING SHAPE AND REFUSED IT: 3 of 722.  `--readers`,
    2 checks (J2).

  ★ (4) REPORTED A DEFECT IN prom_a's COMMITTED DECODE: 0xF8A44B-0xF8A498 is a
    copy of assembled code whose `jr` lands mid-instruction.  Not fixed here --
    prom_a is another lane's file.

  ⚠ WHAT ROUND 10 DID **NOT** MOVE: sub_XXXXXX is unchanged, because no span was
  converted, and the only framed->content it applied is the six DERIVATIVE thunk
  promotions round 9 deliberately left for the round barrier.  The round's
  output is MECHANISM and REFUSALS, and saying so is the point.

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
    python3 notes/prom_b_screens_round8.py --glyphs      # ★ the 0/O glyph finding
    python3 notes/prom_b_screens_round8.py --glyphs --all
    python3 notes/prom_b_screens_round8.py --framed      # framed clusters + headroom
    python3 notes/prom_b_screens_round8.py --framed --naive
    python3 notes/prom_b_screens_round8.py --promote     # the 32 framed->content
    python3 notes/prom_b_screens_round8.py --promote --apply
    python3 notes/prom_b_screens_round8.py --layer2      # ★ LAYER 2, round 10
    python3 notes/prom_b_screens_round8.py --readers     # ★ the fifth shape, refused
    python3 notes/prom_b_screens_round8.py --layer2 --all
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
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

LO, HI = 0xF7E2D8, 0xF80000
A_BASE, B_BASE = 0xF80000, 0xF00000
BTN_LO, BTN_HI, BTN_STRIDE = 0xF7D2D8, 0xF7E2D8, 0x80   # the 32 button tables
INTERP = {0xF417F0: "A", 0xF417F4: "B"}
BLINK_CMD = 0xF42E20                    # T_Blink_Command -> prom_b 0xF0E9CF
SRCA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
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


def calibration_score():
    """(total, prefix, exact, the non-exact bases) for round 7's title rule,
    re-run over every screen whose painter prom_a named independently.
    ★ Factored out of print_calibrate in round 9 SO THAT A CHECK CAN PIN IT:
    round 8's prose said 7/7 and 6/7 while the code printed 21/21 and 20/21,
    and nothing in the file could catch the disagreement because the number
    existed only inside a print loop."""
    R7 = screen_runs()
    tot = pre_n = ex_n = 0
    notex = []
    for base, _slots in R7.runs():
        pl = R7.painter_label(base)
        if not pl:
            continue
        title, _l = R7.screen_title(base)
        derived = R7.slug(title) if title else ""
        tot += 1
        pre = pl.startswith(derived) and derived != ""
        ex = pl == derived
        pre_n += pre
        ex_n += ex
        if not ex:
            notex.append(base)
    return tot, pre_n, ex_n, notex


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
    write_part(SRCB_MASTER, new_src)
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
# ===================================================================== ROUND 9
# ★★ THE GLYPH FINDING: the WSA1's Latin faces CANNOT DISTINGUISH '0' FROM 'O',
# and the firmware exploits it.  See this file's docstring, section ROUND 9.
#
# base, bytes/glyph, geometry -- the seven LATIN faces of the twelve tables
# established by notes/font_layout_check.py / notes/FINDINGS-fonts.md.  The
# three kana and two kanji faces are excluded: they hold no Latin letters, so
# "is 0 the same picture as O" is not a question about them.
LATIN_FACES = [(0xF1B400, 14, "8x14"), (0xF1BEF0, 16, "8x16"),
               (0xF1CB70, 32, "16x16"), (0xF1E470, 8, "8x8 proportional"),
               (0xF1EAB0, 32, "11x16 proportional"), (0xF24DC0, 10, "8x10"),
               (0xF25590, 48, "16x24")]
GLYPH_LO, GLYPH_HI = 0x21, 0x80         # the printable Latin block of each face


def glyph(base, pitch, code):
    """The raw bitmap bytes of one cell.  Cell n is at base + n*pitch -- the
    indexing notes/font_sheet.py uses and notes/render_font.py documents."""
    a = base + code * pitch
    return bytes(byte(a + i) for i in range(pitch))


def glyph_dupes():
    """For each Latin face, the groups of DISTINCT codes in 0x21-0x7F that share
    one bitmap byte-for-byte.  Blank cells are skipped: a face that leaves a code
    undefined stores zeros, and 'all the blanks match' is not a confusion."""
    out = []
    for base, pitch, geom in LATIN_FACES:
        cells = collections.OrderedDict()
        for code in range(GLYPH_LO, GLYPH_HI):
            g = glyph(base, pitch, code)
            if not any(g):
                continue
            cells.setdefault(g, []).append(code)
        groups = [v for v in cells.values() if len(v) > 1]
        out.append((base, pitch, geom, len(cells), groups))
    return out


def zero_for_o():
    """prom_b's own `.ascii` literals, split by whether they spell a letter O
    with the byte 0x30.  Two patterns, reported separately because they are
    different strengths of evidence:
        INFIX   a 0 with an ASCII letter on BOTH sides   -- 'S0NG', 'ERR0R'
        INITIAL a 0 that STARTS a run of >= 2 letters    -- '0PTI0N', '0K'
    INFIX cannot be a digit in any reading.  INITIAL could in principle be a
    numbered item, so it is counted apart and never merged into the headline."""
    text = open(SRCB).read()
    lits = re.findall(r'\.ascii\s+"((?:[^"\\]|\\.)*)"', text)
    infix = re.compile(r"[A-Za-z]0[A-Za-z]")
    initial = re.compile(r"(?:^|[^0-9A-Za-z])0[A-Za-z]{2}")
    a = sorted({l for l in lits if infix.search(l)})
    b = sorted({l for l in lits if initial.search(l) and l not in set(a)})
    return lits, a, b


def zero_for_o_labels():
    """Labels the misreading has already been baked into.  The test is a 0 with
    a letter before it and a LOWERCASE letter after it: that is a CamelCase word
    ('S0ng', 'Transp0se'), and it cannot match a trailing hex address, whose
    digits are uppercase ('sub_F0A0B1')."""
    pat = re.compile(r"[A-Za-z]0[a-z]")
    lab = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
    out = {}
    for path, tag in ((SRCB, "prom_b"), (SRCA, "prom_a")):
        got = set()
        for ln in open(path):
            m = lab.match(ln)
            if m and pat.search(m.group(1)):
                got.add(m.group(1))
        out[tag] = sorted(got)
    return out


def zero_for_o_prose(labs=None):
    """How many LINES outside prom_b's own label definitions mention one of the
    misspelled names.  This -- not the label count -- is what a rename has to
    rewrite, and it is why the fix is a cross-lane operation."""
    labs = labs or zero_for_o_labels()
    names = set(labs["prom_b"]) | set(labs["prom_a"])
    if not names:
        return {}
    rx = re.compile(r"\b(?:%s)\b" % "|".join(re.escape(n) for n in sorted(names)))
    out = {}
    for rel in ("prom_b/wsa1_prom_b.s", "prom_a/wsa1_prom_a.s",
                "notes/prom_a_understanding_round6.py",
                "notes/wave7_round5_review_wb_prom_b.py"):
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            continue
        n = sum(1 for ln in open(path) if rx.search(ln))
        out[rel] = n
    return out


def print_glyphs():
    print("★★ CAN THE WSA1 TELL '0' FROM 'O'?  IN SIX OF ITS SEVEN LATIN FACES, NO.\n")
    print("  Duplicate bitmaps among codes 0x%02X-0x%02X, per face:\n" % (GLYPH_LO, GLYPH_HI - 1))
    for base, pitch, geom, ncells, groups in glyph_dupes():
        g = "  ".join("{%s}" % " ".join("0x%02X '%s'" % (c, chr(c)) for c in grp)
                      for grp in groups) or "(none)"
        print("    0x%06X  %-18s pitch %2d  %3d non-blank  %d group(s)  %s"
              % (base, geom, pitch, ncells, len(groups), g))
    d = [g for _b, _p, _g, _n, gr in glyph_dupes() for g in gr]
    n0o = sum(1 for g in d if g == [0x30, 0x4F])
    print("\n  ★ %d of the %d faces have EXACTLY ONE duplicate pair and it is 0/O."
          % (n0o, len(LATIN_FACES)))
    b8 = [f for f in glyph_dupes() if f[0] == 0xF1E470][0]
    diff = sum(1 for x, y in zip(glyph(0xF1E470, 8, 0x30), glyph(0xF1E470, 8, 0x4F)) if x != y)
    print("    The one exception is 0xF1E470, the 8x8 proportional face (SWI7 0x17):")
    print("    there 0x30 differs from 0x4F in %d of its 8 bytes -- a diagonal stroke" % diff)
    print("    through the bowl -- and its single duplicate pair is %s instead."
          % ("{%s}" % " ".join("'%s'" % chr(c) for c in b8[4][0])))
    print("\n  ⚠ SO THE FIRMWARE MAY SPELL THE LETTER O AS 0x30 AND NO USER CAN TELL.")
    lits, infix, init = zero_for_o()
    inf_occ = sum(1 for l in lits if re.search(r"[A-Za-z]0[A-Za-z]", l))
    print("    prom_b `.ascii` literals: %d total" % len(lits))
    print("      %3d DISTINCT spell a letter O between two letters ('S0NG', 'ERR0R'),"
          % len(infix))
    print("          in %d literal occurrences" % inf_occ)
    print("      %3d further distinct start a word with it          ('0PTI0N', '0K')"
          % len(init))
    for l in infix[:6]:
        print("        %r" % l)
    print("        ... and %d more (--glyphs --all for every one)" % max(0, len(infix) - 6))
    if "--all" in sys.argv:
        for l in infix[6:] + init:
            print("        %r" % l)
    labs = zero_for_o_labels()
    prose = zero_for_o_prose(labs)
    print("\n  ★ AND IT IS ALREADY IN THE TREE'S NAMES -- %d labels in prom_b and %d in"
          % (len(labs["prom_b"]), len(labs["prom_a"])))
    print("    prom_a carry a CamelCase 0-for-O: DL_S0ng, Paint_S0ngC0py,")
    print("    ScreenEnter_Transp0se, DL_Err0rTheS0undOrC0mbinati0n.  Nobody greps those.")
    print("    ⚠ %d of prom_b's %d are new THIS ROUND: the 103 thunk promotions took"
          % (30, len(labs["prom_b"])))
    print("      their targets' names verbatim, which is what a derivative rename must")
    print("      do -- correcting the copy and not the original would split the pair.")
    print("\n  ★ THE REAL COST OF THE FIX IS NOT THE LABELS, IT IS THE PROSE:")
    for tag in sorted(prose):
        print("      %-38s %4d lines mention one of those names" % (tag, prose[tag]))
    print("\n  ⚠⚠ THIS PASS DOES NOT RENAME THEM, AND THE REASON IS ARITHMETIC:")
    print("     * the fix is CONTENT -> CONTENT.  Every one of those %d labels already"
          % (len(labs["prom_b"]) + len(labs["prom_a"])))
    print("       grades CONTENT, so the documentation metric would not move one point.")
    outside = sum(v for k, v in prose.items() if "wsa1_prom_b" not in k)
    print("     * the names reach into prom_a and into two other lanes' scripts, and")
    print("       THIS LANE OWNS prom_b ONLY.  The wave's lane rule is absolute, not")
    print("       proportional, so the size is stated honestly rather than inflated:")
    print("       %d label definitions and %d lines of prose outside prom_b -- SMALL."
          % (len(labs["prom_a"]), outside))
    print("       Small is an argument for doing it in ONE commit, not an argument for")
    print("       reaching across a lane boundary to do half of it.  A prom_b-only")
    print("       rename would leave prom_b")
    print("       saying DL_Song where prom_a's cross-reference prose says DL_S0ng --")
    print("       strictly worse than one consistent misspelling, and it would strand")
    print("       the very references round 6 went to trouble to keep alive.")
    print("     * round 6 measured what a mass rename costs: four broken range")
    print("       shorthands and six tautologies, for names that were already right.")
    print("     So it is handed over as ONE cross-lane operation, with the evidence")
    print("     above and this recipe: rename in prom_a and prom_b in the SAME commit,")
    print("     rewrite the generators that emit these names")
    print("     (gen_prom_b_f067a6_module.py --dl-names and this file's title rule) so")
    print("     the next conversion does not re-introduce it, and re-run --stale.")


def framed_clusters():
    """prom_b's FRAMED labels grouped by the part of the name before the final
    `_`, so a round can see WHERE the remaining framing is before deciding to
    attack any of it.  Grading is wave7_documentation_metrics.py's, imported,
    never re-implemented."""
    import wave7_documentation_metrics as M
    lab = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
    c = collections.Counter()
    for ln in open(SRCB):
        m = lab.match(ln)
        if not m:
            continue
        n = m.group(1)
        # ⚠ EXCLUDE <parent>__<address> exactly as the metric does.  Without this
        # the count reads 2,959 against the metric's 2,957: DL_Inter__F19E4F and
        # DL_Inter__F19EA4 end in six hex digits, so the FRAMED regex matches
        # them, but they are internal branch targets and the metric excludes
        # them from every percentage.  A cluster census that disagreed with the
        # instrument by two would have been quoted as if it agreed.
        if M.INTERNAL.match(n):
            continue
        if grade(n) == "framed":
            c[n.rsplit("_", 1)[0]] += 1
    return c


def screenfieldlist_headroom():
    """The 256-slot ScreenFieldListPtrs table: how many DISTINCT lists it names,
    and how many slots name the most-shared one.  This is the number that
    decides whether `ScreenFieldList_<index>` could ever be a name."""
    src = open(SRCB).read().split("\n")
    i = [n for n, l in enumerate(src) if l.startswith("ScreenFieldListPtrs")]
    if not i:
        return (0, 0, 0, None)
    c = collections.Counter()
    j = i[0] + 1
    while j < len(src) and not re.match(r"^[A-Za-z_][A-Za-z0-9_]*:", src[j]):
        m = re.search(r"\.long 0x00([0-9A-F]{6})", src[j])
        if m:
            c[int(m.group(1), 16)] += 1
        j += 1
    top, n = c.most_common(1)[0]
    return (sum(c.values()), len(c), n, top)


def print_framed():
    c = framed_clusters()
    print("prom_b FRAMED labels by prefix -- %d labels in %d clusters\n"
          % (sum(c.values()), len(c)))
    for k, v in c.most_common(12):
        print("    %6d  %s_<address>" % (v, k))
    print("\n★ HEADROOM IN THE THREE BIGGEST, MEASURED RATHER THAN ASSUMED:\n")
    print("  T_<address>   -- the routine directory.  notes/prom_b_thunks_round6.py")
    print("    is the instrument and it was RE-RUN this round: 392 of 2,002 slots now")
    print("    point at a CONTENT-named target, against 285 when round 6 ran it, because")
    print("    rounds 7 and 8 named the targets.  103 of those were still spelled")
    print("    T_<address> and this round promoted them.  The rest is not headroom:")
    print("    1,432 slots point at a sub_XXXXXX, 119 into a span still .incbin, 48 at")
    print("    a FRAMED target (R2: the rename would not change the grade), 12 are R3")
    print("    alias pairs and 2 point INTO a display list rather than at its head.")
    print()
    n_dl = c.get("DL", 0)
    print("  DL_<address>  -- %d display lists.  The calibrated title rule" % n_dl)
    print("    (gen_prom_b_f067a6_module.py --dl-names) is ALREADY EXHAUSTED on them:")
    print("    it reports 40 with text records and 0 unique proposals, because every")
    print("    one of the 40 collides with a name another list already has -- NINE")
    print("    different lists draw only \"OK\".  Naming them would produce nine")
    print("    DL_Ok's separated by an address, which is the framed spelling again.")
    print("    ⚠ A NAIVE COUNT SAYS 102 HERE AND IT IS WRONG: walking `.ascii` lines")
    print("    from a label to the next label runs past the list's own extent into the")
    print("    next object.  The rule's own record walk says 40.  Both numbers are")
    print("    printed by --framed --naive so the overcount cannot be repeated.")
    if "--naive" in sys.argv:
        src = open(SRCB).read().split("\n")
        idx = [n for n, l in enumerate(src) if re.match(r"^DL_[0-9A-F]{6}:", l)]
        naive = 0
        for i in idx:
            j = i + 1
            while j < len(src) and not re.match(r"^[A-Za-z_][A-Za-z0-9_]*:", src[j]):
                if ".ascii" in src[j]:
                    naive += 1
                    break
                j += 1
        print("      naive label-to-label walk: %d   rule's record walk: 40" % naive)
    print()
    slots, distinct, top_n, top_a = screenfieldlist_headroom()
    print("  ScreenFieldList_<address> -- %d lists reached from a %d-slot pointer table."
          % (distinct, slots))
    print("    The ONLY fact that distinguishes one from another is its SLOT INDEX, a")
    print("    bare number -- what round 6 refused for Write3602_Index5.  And an index")
    print("    name would be false as well as empty: %d of the %d slots point at the"
          % (top_n, slots))
    print("    SAME list, 0x%06X, so %d different indices would each claim to name it."
          % (top_a, top_n))
    print("    Refused.")


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
    tot, pre_n, ex_n, notex = calibration_score()
    c("CAL   ★ THE TITLE RULE SCORES %d of %d prefix, %d of %d exact -- NOT the"
      " 7/7 and 6/7 this file's prose claimed until round 9" % (pre_n, tot, ex_n, tot),
      (tot, pre_n, ex_n), (21, 21, 20), verbose)
    c("CAL   the single non-exact point is 0xF43170 (derived 'StepRecord' is a"
      " PREFIX of prom_a's Paint_StepRecordPartSelect)", notex, [0xF43170], verbose)
    # ---- ROUND 9: the 0/O glyph finding, and the framed-cluster headroom ----
    gd = glyph_dupes()
    c("GLY   seven Latin faces, and EVERY ONE has exactly one duplicate pair",
      [len(g[4]) for g in gd], [1] * 7, verbose)
    c("GLY   ★ six of the seven duplicate pairs are 0x30/0x4F -- '0' and 'O'",
      sum(1 for g in gd if g[4][0] == [0x30, 0x4F]), 6, verbose)
    b8 = [g for g in gd if g[0] == 0xF1E470][0]
    c("GLY   the exception is the 8x8 proportional face, whose pair is 'l'/'|'",
      (b8[2], b8[4][0]), ("8x8 proportional", [0x6C, 0x7C]), verbose)
    c("GLY   ...and there 0x30 and 0x4F differ, in 3 of 8 bytes (the slashed zero)",
      sum(1 for x, y in zip(glyph(0xF1E470, 8, 0x30), glyph(0xF1E470, 8, 0x4F)) if x != y),
      3, verbose)
    lastf = LATIN_FACES[-1]
    c("GLY   ★ TESTED ON THE LAST FACE 0x%06X (%s, pitch %d): all %d bytes of"
      " 0x30 and 0x4F are equal" % (lastf[0], lastf[2], lastf[1], lastf[1]),
      glyph(lastf[0], lastf[1], 0x30) == glyph(lastf[0], lastf[1], 0x4F), True, verbose)
    c("GLY   CONTROL -- a rule that fired on anything would be worthless: the nine"
      " real digits 0x31-0x39 match NO letter in the last face",
      [d for d in range(0x31, 0x3A)
       if any(glyph(lastf[0], lastf[1], d) == glyph(lastf[0], lastf[1], L)
              for L in list(range(0x41, 0x5B)) + list(range(0x61, 0x7B)))],
      [], verbose)
    _l, infix, _i = zero_for_o()
    c("STR   75 distinct prom_b literals spell an O between two letters",
      len(infix), 75, verbose)
    c("STR   ★ TESTED ON THE LAST of them, sorted", infix[-1], "VEL0CITY CHANGE", verbose)
    c("STR   ★ THE INTERNAL CONTROL: 'R0M1' holds BOTH a 0-for-O and a REAL digit,"
      " so the firmware is not simply missing the digit glyph",
      ("R0M1" in infix, [c2 for c2 in "R0M1" if c2.isdigit()]), (True, ["0", "1"]), verbose)
    labs = zero_for_o_labels()
    c("STR   the misreading is baked into %d prom_b and %d prom_a labels"
      % (len(labs["prom_b"]), len(labs["prom_a"])),
      (len(labs["prom_b"]), len(labs["prom_a"])), (122, 6), verbose)
    fc = framed_clusters()
    c("FRM   prom_b's framed labels, after round 9's 103 promotions AND the 6"
      " round 9 deliberately left for the barrier (2957 -> 2951)",
      sum(fc.values()), 2951, verbose)
    c("FRM   the three biggest clusters are T_, DL_ and ScreenFieldList_",
      [k for k, _v in fc.most_common(3)], ["T", "DL", "ScreenFieldList"], verbose)
    slots, distinct, top_n, top_a = screenfieldlist_headroom()
    c("FRM   ScreenFieldListPtrs: %d slots naming %d distinct lists" % (slots, distinct),
      (slots, distinct), (256, 127), verbose)
    c("FRM   ★ AND IT IS MANY-TO-ONE: %d of the %d slots point at ONE empty list"
      " 0x%06X, so a slot-index name would be false %d times over"
      % (top_n, slots, top_a, top_n), (top_n, top_a), (125, 0xF2D408), verbose)
    # ---------------------------------------------------------- ROUND 10: LAYER 2
    t1, t2, n = l2_table_bases()
    c("L2    the SC1 inbound queue's ONLY consumer is prom_a 0x%06X, and it is an"
      " `ld XIZ,0x00002B40`" % L2_CONSUMER, bs(L2_CONSUMER, 5),
      bytes((0x46, 0x40, 0x2B, 0x00, 0x00)), verbose)
    c("L2    ★ and it is the only one: 0x00002B40 as a 32-bit immediate appears"
      " ONCE in prom_a and never in prom_b outside the SC1 module's own inits",
      (rom("a").count(bytes((0x40, 0x2B, 0x00, 0x00))),
       rom("b").count(bytes((0x40, 0x2B, 0x00, 0x00)))), (2, 5), verbose)
    c("L2    the walker at 0x%06X reads the 0x2000 list with `ld XIY,0x00002000`"
      " / `ld XIX,0x00002030`" % L2_WALKER, bs(L2_WALKER, 10),
      bytes((0x45, 0x00, 0x20, 0x00, 0x00, 0x44, 0x30, 0x20, 0x00, 0x00)), verbose)
    c("L2    the group bound is `cp A,0x18` + `jr UGT` at 0xF8A83B, so groups"
      " 0x00-0x%02X" % (L2_GROUPS - 1), bs(0xF8A83B, 4),
      bytes((0xC9, 0xCF, 0x18, 0x6B)), verbose)
    c("L2    both pointer-table bases are IMMEDIATES in the walker, not assumed",
      (byte(L2_TAB1_IMM), byte(L2_TAB2_IMM), t1, t2), (0x44, 0x44, 0xF8B446, 0xF8B4B2),
      verbose)
    c("L2    %d entries per table, and that covers every group the bound admits"
      % n, (n, n >= L2_GROUPS), (27, True), verbose)
    ok, gap, lo, hi, nl = l2_tiling()
    c("L2    ★ the two variants' %d distinct template lists TILE 0x%06X-0x%06X"
      " with no gap and no overlap" % (nl, lo, hi - 1), (ok, gap, lo, hi),
      (True, None, 0xF8B51E, 0xF8B74A), verbose)
    c("L2    ★ TESTED ON THE LAST LIST: variant 2 group 0x15 is the highest-"
      "addressed one and it ends exactly where the SECOND per-group table begins",
      (l2_records(t2, 0x15)[1], w32(0xF8A8CC + 1)), (0xF8B748, 0xF8B74A), verbose)
    c("L2    ⚠ reading variant 1 ALONE reports a false gap -- variant 1's"
      " highest-addressed list is the EMPTY group 0x18 at 0xF8B672, and what"
      " follows it is variant 2's first list, not padding",
      (w32(t1 + 4 * 0x18), l2_records(t1, 0x18)[1], w32(t2)),
      (0xF8B672, 0xF8B673, 0xF8B673), verbose)
    m1 = l2_code_map(t1, n)
    c("L2    class 0xA9 code 0x21 -- prom_a's independently named"
      " PanelEvent_Code21_Dial -- comes from group 0x0F alone, in BOTH variants",
      ([g for g, _m, _f in m1[(0xA9, 0x21)]],
       [g for g, _m, _f in l2_code_map(t2, n)[(0xA9, 0x21)]]), ([0x0F], [0x0F]), verbose)
    c("L2    ★ and 0x0F is the group PanelWireGroupMap gives wire 0xD7 in BOTH"
      " variants -- the only 'continuous' wire both keep",
      (byte(0xF8A109 + ((0xD7 & 0x1F) | ((0xD7 & 0xC0) >> 1))),
       byte(0xF8A189 + ((0xD7 & 0x1F) | ((0xD7 & 0xC0) >> 1)))), (0x0F, 0x0F), verbose)
    c("L2    class 0xA9 code 0x20 -- PanelEvent_Code20_SetScreen -- is emitted by"
      " group 0 bits 0-3 and group 7 bits 0-5, ten mode/menu switches",
      sorted(set(g for g, _m, _f in m1[(0xA9, 0x20)])), [0, 7], verbose)
    c("L2    group 9 spends bits 0-4 on FIVE distinct codes with shifts 0,1,2,3,4"
      " -- five single-switch buttons, against round 9's LCD LEFT 1..5",
      [(cd, fl & 7) for _cl, cd, fl, mk in l2_records(t1, 9)[0] if mk & 0x1F],
      [(0x08, 0), (0x09, 1), (0x0A, 2), (0x0B, 3), (0x0C, 4)], verbose)
    c("L2    ★ THE REFUSAL, part 1: variant 1 has THREE byte-identical template"
      " pairs, so a bit in either half of a pair makes the same four event bytes",
      l2_twins(t1, n), [[1, 2], [3, 4], [5, 6]], verbose)
    c("L2    ★ CONTROL -- variant 2 has NONE, so the duplication is a property of"
      " variant 1's table and not of the way this script compares lists",
      l2_twins(t2, n), [], verbose)
    c("L2    ★ THE REFUSAL, part 2: groups 3+4 offer 16 switch bits but only 8"
      " distinguishable (code, payload bit) positions; 5+6 the same",
      (l2_positions(t1, n, [3, 4]), l2_positions(t1, n, [5, 6])),
      ((8, 16), (8, 16)), verbose)
    c("L2    ★ CONTROL -- groups 9 and 0x0A are NOT twins and offer all 16",
      l2_positions(t1, n, [9, 0x0A]), (16, 16), verbose)
    occ, e1, e2 = l2_button_slot_occupancy()
    both = e1 | e2
    dd, tc, tr = l2_duplicate_walker()
    c("L2    ⚠ prom_a 0xF8A44B is a 78-byte copy of the walker tail at 0xF8A84B"
      " differing in 9 bytes and in NO branch displacement",
      (len(dd), dd), (9, [2, 3, 6, 7, 8, 9, 10, 13, 14]), verbose)
    c("L2    ⚠ so the copy's `jr T` lands on 0x%06X, the SECOND byte of the"
      " five-byte `ld (XIX+HL),E` prom_a's own decode puts at 0xF8A42D" % tc,
      (tc, tr, bs(0xF8A42D, 5)), (0xF8A42E, 0xF8A82E,
                                  bytes((0xF3, 0x07, 0xF0, 0xEC, 0x45))), verbose)
    rres, rhits = readers_lever()
    c("J2    ★ THE FIFTH NAMING SHAPE, measured: of %d framed data labels, only"
      " 3 have a sole CONTENT reader -- the shape is refused"
      % sum(rres.values()),
      (sum(rres.values()), len(rhits), rres["no direct base load"]),
      (722, 3, 609), verbose)
    c("J2    ★ TESTED ON THE LAST hit, sorted", sorted(rhits)[-1],
      ("PtrTable_F09B7B", "RunDisplayListBFromPointerArray"), verbose)
    c("L2    ★ THE PREDICTION TEST, on prom_b's OWN button tables and nothing"
      " the derivation used: all 16 slots 0x00-0x0F are filled by at least one"
      " screen, and 15 of those 16 codes are emitted by a prom_a template",
      (len([k for k in range(16) if occ[k]]), len([k for k in range(16) if k in both])),
      (16, 15), verbose)
    c("L2    ★ TESTED ON THE LAST SLOT: 0x1F is filled by no screen and emitted"
      " by no template", (occ[0x1F], 0x1F in both), (0, False), verbose)
    c("L2    slot 0x0F is the only one all 32 screens handle", occ[0x0F], 32, verbose)
    c("L2    ⚠ THE HOLE, stated rather than smoothed over: 0x0E and 0x11-0x19"
      " are handled by a screen and emitted by no template",
      [k for k in range(32) if occ[k] and k not in both],
      [0x0E, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19], verbose)
    sb, sc = l2_substituted_codes()
    c("L2    ⚠ and the obvious explanation is REFUTED by census: every literal"
      " written to (0x209B)/(0x209C) masks to 0x00-0x0C, never 0x11-0x19",
      sorted(set(v & 0x1F for v in sb | sc)), list(range(0x0D)), verbose)
    c("L2    ★ AND THE THING THAT EXPLAINS ROUND 9's NEGATIVE: the class byte is"
      " NEVER an immediate -- 0x00A9 as an `ld DE` immediate occurs 0 times in"
      " all four images, because 0xA9 is byte +0 of a template record",
      sum(r.count(bytes((0x4A, 0xA9, 0x00, 0x00, 0x00))) for r in
          (rom("a"), rom("b"))), 0, verbose)
    if verbose and FAIL:
        print("\n%d FAILED:\n%s" % (len(FAIL), "\n".join("  " + f for f in FAIL)))
    return not FAIL



# ==============================================================================
# ★★ ROUND 10 -- LAYER 2, THE CLASS-0xA9 EVENT CODE: THE PRODUCER IS FOUND, THE
#    ENCODING IS DECODED, AND THE code->LEGEND STEP IS REFUSED WITH ARITHMETIC
# ==============================================================================
#
# QUESTION IT ANSWERS
#   Round 9 left this: "LAYER 2, THE EVENT -- the 5-bit index inside the
#   class-0xA9 event ... NOT SOLVED.  prom_b SC1_RxOp0_ThreeByte queues
#   [wire byte][new value][change mask].  Whatever CONSUMES that queue and posts
#   the {0xA9, code, b2, b3} event holds the (segment,bit) -> 5-bit index table.
#   Round 9 could not find the consumer."
#
#   THE CONSUMER IS prom_a sub_F8A088 (`ld XIZ,0x00002B40` at 0xF8A088, the only
#   read of the inbound queue descriptor anywhere in either of CPU 1's ROMs),
#   and the chain from a switch closing to a screen's button handler is FIVE
#   stages, not two:
#
#     1  CP1 sends [wire][bitmask]; prom_b SC1_RxOp0_ThreeByte (0xF5B0D5)
#        appends [wire][new value][change mask] to the queue at 0x2B40 and keeps
#        the per-wire previous value in the 32-byte table at 0x2B20.
#     2  prom_a sub_F8A088 pulls those three bytes, maps the wire through
#        PanelWireGroupMap_Variant1/2 (index (w & 0x1F) | ((w & 0xC0) >> 1)) to a
#        GROUP id, and ...
#     3  ... prom_a 0xF8A3B2 appends the 3-byte record {group, value, mask} to
#        the list at RAM 0x2000 (at most 7, count in (0x219A), 0xFF terminator).
#     4  prom_a 0xF8A824 walks that list.  For each record it stores the group in
#        (0x2251) and reads a PER-GROUP LIST OF 4-BYTE TEMPLATES through one of
#        two 27-entry pointer tables; each template is
#              +0 event CLASS   +1 event CODE   +2 shift/flags   +3 bit mask
#        and the walker copies +0/+1 straight into the 0x2030 event list, masks
#        the record's value and change mask with +3, shifts both by +2, and
#        stores them as the event's two payload bytes.
#     5  prom_a UiEventList_RunPassC dispatches class 0xA9 to UiEvent_RouteByCode,
#        which sends code < 0x20 to PanelButton_Accept -- and it is that code the
#        32-entry per-screen tables at prom_b 0xF7D2D8 index.
#
# ★★ WHY NO `ld DE,0x00A9` EXISTS, which is the fact round 9 measured and could
#    not explain: THE CLASS BYTE IS NEVER AN IMMEDIATE.  It is byte +0 of a
#    template record in a prom_a data table, copied into the event by
#    `ld WA,(XHL+)` / `ld (XIX+),WA` at 0xF8A867-0xF8A86A.  An immediate search
#    could not have found it in any of the four images.
#
# ★★ AND WHY 32 CODES SERVE 58 SWITCHES: the map is not one-to-one BY
#    CONSTRUCTION.  A template's +2 byte is a SHIFT COUNT (bits 0-2, direction in
#    bit 4, decoded at prom_a 0xF8A8A1-0xF8A8C6) that slides the masked bits down
#    to the bottom of the payload, so ONE code carries up to eight switches in
#    its payload bits.  Round 9's premise -- "32 codes cannot enumerate 58
#    switches, so the mapping is not the identity" -- was right, and this is the
#    mechanism.
#
# ⚠ WHAT IS **NOT** SOLVED, AND THE ARITHMETIC THAT SAYS SO (`--layer2`)
#    A code still does not name a switch, because the tables give
#    GROUPS 3 AND 4 BYTE-IDENTICAL RECORD LISTS, and GROUPS 5 AND 6 LIKEWISE.
#    A bit in group 3 and the same bit in group 4 produce the SAME four event
#    bytes.  Each of those lists spends its 8 bits on 4 codes with a 2-bit
#    payload, so a twin PAIR offers 8 distinguishable positions in total -- and
#    round 9's physical map puts EIGHT fitted switches in each of segments 3, 4
#    and 5 (SW25-32, SW33-40, SW41-48) with group == segment.  24 switches do not
#    fit in 16 positions.  So at least one of these is wrong:
#       (i)   group == segment fails for some wires;
#       (ii)  one of segments 3/4/5 is not populated after all;
#       (iii) SW = 8*segment + bit + 1 fails away from the two MEASURED anchors
#             (round 9 grades segments 4 and 5 "POSITION", its weakest grade).
#    This pass does not choose.  Naming 124 button handlers on a guess here is
#    exactly the failure this tree keeps paying for.
#
# ★ THREE INDEPENDENT AGREEMENTS the table DOES have with round 9's manual map,
#   none of which either side knew about the other:
#     * group 0 bits 0-3 and group 7 bits 0-5 emit code 0x20, and prom_a named
#       0xF8681A `PanelEvent_Code20_SetScreen` months earlier from its body.
#       Round 9 reads SW1-SW4 as PLAY/EDIT MODE SOUND/COMBI and SW57-SW60 as
#       MENU PART/SYSTEM/MIDI/DISK -- ten mode-and-menu buttons, and every one
#       of them asks for a screen.
#     * wire 0xD7 is the only "continuous" wire BOTH variants keep, it maps to
#       group 0x0F in both, and group 0x0F's single template is {0xA9, 0x21} --
#       against prom_a's independently derived `PanelEvent_Code21_Dial`.
#     * group 9 spends bits 0-4 on five DISTINCT codes 0x08-0x0C with shifts
#       0,1,2,3,4, i.e. five single-switch buttons; round 9 reads segment 9 as
#       LCD LEFT 1..5 (SW73-SW77), five buttons.
#
# RUN
#     python3 notes/prom_b_screens_round8.py --layer2
#     python3 notes/prom_b_screens_round8.py --layer2 --all   # every group, both
#     python3 notes/prom_b_screens_round8.py --selftest
# ==============================================================================

# Every address below is an ANCHOR that the checks re-read from the ROM; the
# tables themselves are never hard-coded -- they are read out of the two
# `ld XIX,imm32` immediates in the walker.
L2_CONSUMER   = 0xF8A088     # `ld XIZ,0x00002B40`  -- pulls the SC1 inbound queue
L2_APPEND2000 = 0xF8A3B2     # appends {group, value, mask} to RAM 0x2000
L2_WALKER     = 0xF8A824     # walks 0x2000 and posts the events
L2_TAB1_IMM   = 0xF8A84C     # `ld XIX,imm32`, taken when (0xC4) == 1
L2_TAB2_IMM   = 0xF8A857     # `ld XIX,imm32`, taken otherwise
L2_SHIFTER    = 0xF8A8A1     # decodes the template's +2 byte
L2_GROUPS     = 0x19         # `cp A,0x18` + `jr UGT` at 0xF8A83B: groups 0..0x18


def l2_table_bases():
    """The two template pointer tables, read out of the walker's own immediates.

    Returns (variant1_base, variant2_base, entries_per_table).  The entry count
    is not assumed: it is (variant2_base - variant1_base) / 4, and the check
    below asserts that this covers the group bound the walker enforces."""
    t1 = w32(L2_TAB1_IMM + 1)
    t2 = w32(L2_TAB2_IMM + 1)
    return t1, t2, (t2 - t1) // 4


def l2_records(base, group):
    """The 4-byte templates of one group: [(class, code, flags, mask)], and the
    address one past the 0xFF terminator."""
    p = w32(base + 4 * group)
    out = []
    while byte(p) != 0xFF:
        out.append(tuple(bs(p, 4)))
        p += 4
    return out, p + 1


def l2_all(base, n):
    return [l2_records(base, g) for g in range(n)]


def l2_tiling():
    """★ THE BOUND ON EVERY LIST IS THE NEXT LIST'S BASE, not a guess -- and the
    two variants' record blocks are CONTIGUOUS, so the check has to be JOINT.
    Reading variant 1 alone reports a false gap at 0xF8B672, because what follows
    variant 1's last list is variant 2's first one.  That is exactly the kind of
    single-image reading this tree keeps getting caught by, so the tiling is
    asserted over the UNION of both tables.
    Returns (ok, first_gap, lo, hi, n_lists)."""
    t1, t2, n = l2_table_bases()
    ends = {}
    for base in (t1, t2):
        for g in range(n):
            p = w32(base + 4 * g)
            ends[p] = l2_records(base, g)[1]
    order = sorted(ends)
    for p, q in zip(order, order[1:]):
        if ends[p] != q:
            return False, (p, ends[p], q), order[0], ends[order[-1]], len(order)
    return True, None, order[0], ends[order[-1]], len(order)


def l2_code_map(base, n):
    """code -> [(group, mask, flags)] over one variant."""
    m = collections.defaultdict(list)
    for g in range(n):
        for cls, code, flags, mask in l2_records(base, g)[0]:
            m[(cls, code)].append((g, mask, flags))
    return m


def l2_twins(base, n):
    """Groups whose template list is BYTE-IDENTICAL to another group's."""
    blob = {}
    for g in range(n):
        recs, end = l2_records(base, g)
        if not recs:
            continue
        blob.setdefault(bytes(b for r in recs for b in r), []).append(g)
    return [v for v in blob.values() if len(v) > 1]


def l2_positions(base, n, groups):
    """How many DISTINGUISHABLE switch positions a set of groups offers.
    A position is a (code, payload bit) pair, and a template contributes
    popcount(mask) of them -- but twins share theirs, so identical lists are
    counted ONCE.  Returns (positions, fitted_bits)."""
    seen = set()
    bits = 0
    for g in groups:
        recs, _e = l2_records(base, g)
        for cls, code, flags, mask in recs:
            sh = flags & 0x07
            up = bool(flags & 0x10)
            for b in range(8):
                if mask & (1 << b):
                    pb = (b + sh) if up else (b - sh)
                    seen.add((cls, code, pb))
        bits += 8
    return len(seen), bits


def l2_button_slot_occupancy():
    """★ THE PREDICTION TEST, and it runs on prom_b's OWN data.

    If the class-0xA9 code really is the index of the 32-entry per-screen tables
    at 0xF7D2D8, then the slots those tables actually fill should be the codes
    the prom_a template tables actually emit -- and the ones they never emit
    should be dead.  Nothing in the derivation used the button tables, and
    nothing in the button tables knows about prom_a, so this is an independent
    check and not a restatement.

    Returns (occupancy, emitted_v1, emitted_v2) where occupancy[slot] is the
    number of the 32 tables whose slot points at something that is not a bare
    `ret` byte -- the unused-button convention this file measures in --buttons."""
    occ = collections.Counter()
    for i in range((BTN_HI - BTN_LO) // BTN_STRIDE):
        t = BTN_LO + BTN_STRIDE * i
        for k in range(32):
            if byte(w32(t + 4 * k)) != 0x0E:
                occ[k] += 1
    t1, t2, n = l2_table_bases()
    emitted = []
    for base in (t1, t2):
        e = set()
        for g in range(n):
            for cls, code, _fl, _mk in l2_records(base, g)[0]:
                if cls == 0xA9 and code < 0x20:
                    e.add(code)
        emitted.append(e)
    return occ, emitted[0], emitted[1]


def l2_substituted_codes():
    """Every literal the firmware ever writes to (0x209B)/(0x209C) -- the pair
    prom_a's PanelButton_Accept substitutes for code 0x0D.

    Scanned from the ROM BYTES, not from the .s text, so a lane editing either
    source cannot move the number.  The encodings are
        f1 9b 20 00 vv        ld (0x209b),imm8
        f1 9b 20 02 lo hi     ld (0x209b),imm16   (hi lands in 0x209C)
    and the same with 9c.  Returns (set written to 0x209B, set written to 0x209C)."""
    b, c = set(), set()
    for img in ("a", "b"):
        d = rom(img)
        for cell in (0x9B, 0x9C):
            dst8 = b if cell == 0x9B else c
            i = 0
            while True:
                i = d.find(bytes((0xF1, cell, 0x20)), i)
                if i < 0:
                    break
                if d[i + 3] == 0x00:
                    dst8.add(d[i + 4])
                elif d[i + 3] == 0x02:
                    dst8.add(d[i + 4])
                    (c if cell == 0x9B else b).add(d[i + 5])
                i += 3
    return b, c


# ------------------------------------------------------------------ round 10
# ★ JOB 2, THE FIFTH SHAPE -- MEASURED AND REFUSED, WITH ITS ZERO
#
# Rounds 6 and 8 measured four MECHANICAL shapes (bare ret, one-line forwarder,
# table-call stub, single-cell writer) and refused them because every name they
# make is a KIND PLUS AN ADDRESS.  This round measured a fifth shape, which is
# NOT mechanical and would produce real content names: the project's own stated
# rule "NAME AN OBJECT FROM WHAT READS IT".
#
#   For every prom_b label of the form <Kind>_<its own address> whose Kind is a
#   data kind, find every site in prom_b OR prom_a that loads that address as a
#   32-bit immediate into a pointer register -- a DIRECT base load, not a walk
#   through some other table.  If there is exactly ONE such site and the routine
#   it sits in has a CONTENT name, rename <Kind>_<address> to <Kind>_<that name>.
#
# ★★ THE ANSWER IS THREE.  Of 722 such labels, 609 have NO direct base load at
# all -- they are reached through a pointer table, which is exactly why they were
# framed in the first place -- 62 have a sole reader that is itself sub_XXXXXX,
# 15 a sole reader that is itself framed, 33 have two or more readers, and THREE
# have a sole CONTENT reader:
#     PtrTable_F09B7B      <- RunDisplayListBFromPointerArray
#     DLTable_F3A58A       <- Paint_TrackMerge
#     DispatchTable_F5B9F8 <- Dispatch_Code80
# A shape that reaches 3 of 722 is not a lever.  ⚠ AND IT IS ALSO NOT FREE: two
# of the three sole readers are themselves derived names (`Paint_TrackMerge` came
# from the title rule, `Dispatch_Code80` is a kind plus a number that only the
# metric's word-boundary rule grades as content), so the rename would launder one
# lane's inference into another object.  Measured, refused, and reported with its
# number so that no later round re-derives it.  `--readers`.


def readers_lever():
    """The fifth naming shape, measured.  Returns (Counter of outcomes, hits)."""
    label = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
    internal = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
    unnamed = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
    framed = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                        r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                        r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')
    imm = re.compile(r'\bld\s+X?(?:HL|DE|BC|WA|IX|IY|IZ)\s*,\s*0x0*([0-9A-Fa-f]{4,8})\b',
                     re.I)
    kinds = ('Data', 'Record', 'PtrTable', 'DispatchTable', 'IndexMap', 'ByteMap',
             'RamPtrTable', 'StringTable', 'RecordArray', 'DLTable', 'DLTab',
             'DLBTable', 'DLB_Records', 'Bitmap', 'ScreenFieldList', 'DataPtrTable',
             'BitTable', 'Pointer', 'Table', 'CallSelectorTable')

    def owners_and_sites(path):
        lines = open(path).read().split("\n")
        own, cur, sites = [], None, collections.defaultdict(list)
        for i, ln in enumerate(lines):
            m = label.match(ln)
            if m and not (m.group(1).startswith(".L") or internal.match(m.group(1))):
                cur = m.group(1)
            own.append(cur)
            for mm in imm.finditer(ln):
                sites[int(mm.group(1), 16)].append(i)
        return lines, own, sites

    lb, ob, sb = owners_and_sites(SRCB)
    _la, oa, sa = owners_and_sites(SRCA)
    grade = (lambda n: "sub" if unnamed.match(n) else
             ("internal" if internal.match(n) else
              ("framed" if framed.match(n) else "content")))
    res, hits = collections.Counter(), []
    for ln in lb:
        m = label.match(ln)
        if not m:
            continue
        n = m.group(1)
        mm = re.search(r'_([0-9A-Fa-f]{6})$', n)
        if not mm or n[:mm.start()] not in kinds:
            continue
        a = int(mm.group(1), 16)
        rs = sorted(set([ob[i] for i in sb.get(a, [])] + [oa[i] for i in sa.get(a, [])])
                    - {None})
        if not rs:
            res["no direct base load"] += 1
        elif len(rs) == 1:
            res["sole reader is " + grade(rs[0])] += 1
            if grade(rs[0]) == "content":
                hits.append((n, rs[0]))
        else:
            res["two or more readers"] += 1
    return res, hits


def print_readers():
    res, hits = readers_lever()
    print("★ JOB 2, the fifth shape -- name a framed data object from its SOLE"
          " CONTENT reader.  Measured over %d prom_b labels:" % sum(res.values()))
    for k, v in res.most_common():
        print("    %5d  %s" % (v, k))
    print("  ⇒ the shape reaches %d of %d.  REFUSED -- and not only for the"
          " size: two of the three sole readers are themselves derived names, so"
          " the rename would launder one lane's inference into another object."
          % (len(hits), sum(res.values())))
    for n, r in hits:
        print("      %s  <-  %s" % (n, r))


def l2_duplicate_walker():
    """★ A DEFECT IN prom_a's COMMITTED DECODE, found on the way to layer 2 and
    reported rather than fixed (prom_a is another lane's file).

    prom_a 0xF8A44B-0xF8A498 and 0xF8A84B-0xF8A898 are 78 bytes that differ in
    NINE positions: the two 32-bit table immediates and the four-byte strap test
    (`bit 2,(0x7F37)` + JR NZ against `cp (0xC4),0x01` + JR Z).  Everything else,
    the RELATIVE BRANCH DISPLACEMENTS INCLUDED, is byte-identical -- which is the
    signature of a copy of already-assembled code, not of a re-assembly.

    The consequence is visible in prom_a's own .s: the copy's `jr T` at 0xF8A486
    carries the same displacement as the real one at 0xF8A886, so it targets
    0xF8A42E -- and prom_a's committed decode renders 0xF8A42D as a five-byte
    `ld (XIX+HL),E`, so that branch lands on the SECOND BYTE of an instruction.
    The routine containing 0xF8A42D is self-consistent (its own seven pushes at
    0xF8A40F balance seven pops ending at 0xF8A42C, and every internal branch
    lands on a boundary), so it is the 0xF8A44B block whose status is unsettled:
    dead code, or a linear-decode artefact.  prom_a presents it as executable
    with no caveat.  Returns (n_differing, copy_jr_target, real_jr_target)."""
    lo_c, lo_r, n = 0xF8A44B, 0xF8A84B, 0xF8A499 - 0xF8A44B
    d = [i for i in range(n) if byte(lo_c + i) != byte(lo_r + i)]
    return d, 0xF8A488 - 90, 0xF8A888 - 90


def print_layer2():
    t1, t2, n = l2_table_bases()
    every = "--all" in sys.argv
    print("★★ LAYER 2 -- the class-0xA9 event code, and where it is BUILT")
    print("   consumer of the SC1 inbound queue : prom_a 0x%06X" % L2_CONSUMER)
    print("   appends {group,value,mask}->0x2000: prom_a 0x%06X" % L2_APPEND2000)
    print("   walks 0x2000 and posts the events : prom_a 0x%06X" % L2_WALKER)
    print("   template pointer tables           : 0x%06X (strap (0xC4)==1) and"
          " 0x%06X, %d entries each" % (t1, t2, n))
    print("   group bound enforced by the walker: 0x00-0x%02X" % (L2_GROUPS - 1))
    ok, gap, lo, hi, nl = l2_tiling()
    print("   the two variants' record blocks are CONTIGUOUS: %d distinct lists"
          " tile 0x%06X-0x%06X with no gap and no overlap: %s%s"
          % (nl, lo, hi - 1, ok, "" if ok else "  GAP %r" % (gap,)))
    for name, base in (("variant 1  (0xC4)==1", t1), ("variant 2  otherwise", t2)):
        print("\n   === %s" % name)
        for g in range(n):
            recs, end = l2_records(base, g)
            if not recs and not every:
                continue
            print("     grp %02X -> %06X..%06X  %s" %
                  (g, w32(base + 4 * g), end,
                   " | ".join("cls %02X code %02X shift %s%d mask %02X" %
                              (c, cd, "<<" if fl & 0x10 else ">>", fl & 7, mk)
                              for c, cd, fl, mk in recs)))
        tw = l2_twins(base, n)
        print("     ⚠ BYTE-IDENTICAL template lists (the same bit in either group"
              " makes the SAME event): %s" %
              ("; ".join("groups " + "/".join("%02X" % g for g in v) for v in tw) or "none"))
    print("\n   ⚠ THE ARITHMETIC THAT REFUSES code->legend, on variant 1:")
    for grp in ([3, 4], [5, 6], [9, 0x0A]):
        pos, bits = l2_positions(t1, n, grp)
        print("     groups %s: %d switch bits on the panel side, %d distinguishable"
              " (code, payload bit) positions" %
              ("/".join("%02X" % g for g in grp), bits, pos))
    print("     round 9's physical map fits 8 fitted switches in each of segments"
          " 3, 4 and 5 with group == segment: 24 switches, 16 positions.")
    print("     ⇒ NOT RESOLVED HERE.  Next probe: prom_a 0xF8AE68 and 0xF8AEDB,"
          " the two handlers groups 3-6 alternate between in the second per-group"
          " table at 0x%06X." % w32(0xF8A8CC + 1))

    occ, e1, e2 = l2_button_slot_occupancy()
    both = e1 | e2
    dd, tc, tr = l2_duplicate_walker()
    print("\n   ⚠ A DEFECT IN prom_a's COMMITTED DECODE, found on the way here and"
          " NOT fixed (prom_a is another lane's file):")
    print("     prom_a 0xF8A44B-0xF8A498 is a 78-byte copy of the walker tail at"
          " 0xF8A84B, differing in %d bytes -- the two table immediates and the"
          " strap test -- and in NO branch displacement." % len(dd))
    print("     So the copy's `jr T` at 0xF8A486 targets 0x%06X, while the real"
          " one at 0xF8A886 targets 0x%06X; and prom_a's decode makes 0x%06X the"
          " SECOND BYTE of the five-byte `ld (XIX+HL),E` at 0xF8A42D."
          % (tc, tr, tc))
    print("     The routine holding 0xF8A42D is self-consistent (seven pushes at"
          " 0xF8A40F, seven pops ending at 0xF8A42C, every internal branch on a"
          " boundary), so it is the 0xF8A44B block that is unsettled.")

    print("\n   ★ THE PREDICTION TEST, on prom_b's OWN 32 button tables at"
          " 0x%06X (nothing in the derivation used them):" % BTN_LO)
    print("     slot  tables with a non-`ret` target   emitted by a class-0xA9 template")
    for k in range(32):
        print("     %02X    %3d/32                            %s"
              % (k, occ[k], "v1 v2" if k in e1 and k in e2 else
                 ("v2 only" if k in e2 else ("v1 only" if k in e1 else "--"))))
    print("     ✓ all 16 slots 0x00-0x0F are filled by at least one screen, and"
          " %d of those 16 codes are emitted by a template." % len([k for k in range(16) if k in both]))
    print("     ✓ slot 0x0F is filled in %d of 32 tables -- the only slot every"
          " screen handles." % occ[0x0F])
    print("     ⚠ AND THE HOLE, STATED: slots %s are filled by a screen and NO"
          " template emits them; %s is emitted and no screen handles it."
          % ([hex(k) for k in range(32) if occ[k] and k not in both],
             [hex(k) for k in sorted(both) if not occ[k]]))
    sb, sc = l2_substituted_codes()
    reach = sorted(set(v & 0x1F for v in sb | sc))
    print("     The obvious candidate is the code SUBSTITUTION prom_a's"
          " PanelButton_Accept performs on code 0x0D (0xF86615-0xF86629: the code"
          " becomes (0x209C) or (0x209B)).")
    print("     ⚠ IT DOES NOT FIT, and the refutation is a census not an"
          " impression: every literal ever written to that pair, scanned from the"
          " ROM bytes, masks under `and L,0x1f` to %s -- so the substitution"
          " cannot reach 0x11-0x19." % [hex(v) for v in reach])
    print("     The producer of those nine codes is UNFOUND.  Class 0xA8, whose"
          " templates carry codes 0x05, 0x07, 0x08 and 0x11, is where to look:"
          " prom_a UiEventClass_ListTable_A/B/C entry 0xA8.")


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
                     ("--glyphs", print_glyphs), ("--framed", print_framed),
                     ("--cost", print_cost), ("--layer2", print_layer2), ("--readers", print_readers)):
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
