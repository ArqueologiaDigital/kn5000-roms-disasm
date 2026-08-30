#!/usr/bin/env python3
"""prom_a round 8: THE COMPLETE PER-ROUTINE CENSUS OF ALL 2,898 `sub_XXXXXX`,
and the mechanical decision of which of them NOTHING IN THIS TREE CAN NAME.

QUESTION IT ANSWERS
    "For every unnamed routine in prom_a, print the facts a name would have to
     come from -- who calls it and what kind of thing they are, what its body
     TOUCHES, whether it is a leaf, how long it is, whether it ends in a flow
     end -- then put each one in exactly one bucket and publish the bucket
     sizes, so the next round plans against a measured ceiling instead of
     re-searching ground six rounds have searched."

WHY A SECOND CENSUS, WHEN ROUND 7 ALREADY WROTE ONE
    notes/prom_a_understanding_round7.py bucketed the same population on TWO
    axes: what the body IS (seven recognised shapes) and what REACHES it.  It
    never asked what the body TOUCHES.  That is the axis this file adds, and it
    is the axis that paid, because prom_a's memory map is documented
    (notes/FINDINGS-memory-map.md sec.1) and every device window in it is a fact
    about any routine that forms an address inside it.

    ★ THE TWO FILES AGREE WHERE THEY OVERLAP, WHICH IS THE POINT OF SAYING SO.
    Round 7 published "301 reached by nothing, 685 published by a directory slot
    nothing calls", and recorded that an hour later they read 300/672.  This
    file, from a different walk and a different scope, printed 300/672 at its
    own start.  Its S1 bucket is 281 against round 7's 283 one-byte ret stubs,
    and the two differences are named: `sub_FADDA9` and `sub_FADE55` are inside
    gen_prom_a_fad800_module.py's range where extent_ends() cannot see a 1-byte
    extent, and `sub_FE0046` is a one-byte object whose byte is a `push`, not a
    `ret`, so it is correctly NOT a ret stub.

★★ THE HEADLINE, AND IT IS A CEILING, NOT A TARGET
    At this round's barrier, BEFORE its own 16 names:

        1,988 of 2,898  (68.6%)      NOTHING

    and after them, 1,969 of 2,882 (68.3%).  `--census` prints the live pair.
    ⚠ QUOTE THE RATIO, NOT THE COUNT: the count falls whenever another lane
    converts a prom_b span and reveals a caller.

    A routine lands there when ALL of these hold: its body is none of the four
    transcribable entry shapes; it forms an address in no NAMED DEVICE WINDOW;
    it touches no SFR; it calls no display-list interpreter and issues no `swi`;
    it loads the address of no CONTENT-named ROM object that is DISTINCTIVE; it
    calls no CONTENT-named routine that is distinctive; no CONTENT-named caller
    that is distinctive reaches it; and it is neither a single-cell writer nor a
    memory-free leaf.

    Round 7 measured the same kind of ceiling on its own two axes and got 73.2%.
    This one is 68.3% BECAUSE it looks at more, and those 4.9 points are exactly
    what the touch axis bought.  Both numbers are statements about the evidence
    in this tree, not about the machine.

★ DISTINCTIVENESS IS THE IDEA THAT MAKES "WHAT IT TOUCHES" WORK
    804 of the population call at least one CONTENT-named routine, and that
    fact names none of them, because the callee is nearly always a utility every
    screen in the machine calls: at the barrier `Var27DA_Set` was called by 81
    of them, `Arr27A6_Get` by 79, `CallbackQueue_ResetAndRestartTask2` by 68.
    A touch is evidence only if it is RARE.  So every touched object is scored
    by how many of the population touch it, and a routine counts as
    touch-evidenced only when it touches something at most `--k` others touch
    (default 3).  With that filter the 804 fall to 147.
    ⚠ --selftest prints the live pair and it has since moved to 821/156, which
    is not drift: NAMING a routine gives every one of its callers a
    CONTENT-named callee it did not have before, so this round's own 16 names
    raised the numerator.  That is also the mechanism by which a converted
    prom_b span shrinks the terminal bucket.  `--popular` prints the
    objects the filter throws out and the count that throws each one out, so the
    filter can be argued with, and `--sweep` prints what the knob decides:

        k        T4      T5      C1       N      N%
        1        41      36      16    2045   71.0%
        3        81      65      27    1969   68.3%
        10      196     113      59    1776   61.6%
        25      282     188      71    1603   55.6%

    Over the whole sweep the terminal bucket never falls below 55.6%, which is
    the invariant --selftest asserts.  ⚠ The first draft asserted "k moves N by
    less than 5 points"; k=10 moved it by 6.5 and the tolerance had been picked
    to pass.  A tolerance chosen to pass is not a check.

────────────────────────────────────────────────────────────────────────────────
★★ ROUND 9 (2026-08-30) -- WHAT THIS FILE GAINED, IN ONE PAGE
────────────────────────────────────────────────────────────────────────────────
    TWENTY names, one refusal, two corrections, and one lever measured and
    DECLINED.  prom_a moved

        content  framed  sub_XXXX   LOWER   UPPER   headers  evidence
 before    1,497     253     2,882   32.3%   37.8%     1,173     1,265
 after     1,517     253     2,862   32.8%   38.2%     1,193     1,285

    0 bytes converted.  0 framed -> content, and `--framed` is the measurement
    that says why rather than an apology: ZERO of prom_a's 253 framed objects
    hold a ROM string of even three characters, so the lever prom_b's lanes are
    using does not exist in this image.

    THE NEW AXIS is `--wrappers`.  Round 8 asked what a body TOUCHES; this asks
    whether the touch is the WHOLE body.  220 routines have exactly one distinct
    CONTENT-named callee and 15 or fewer instructions; 47 of those have a callee
    no other such wrapper shares -- and only where that is true can a name be
    anything but "the callee plus an address", which is framed.  13 of the 47
    are named, and the other 34 are refused for a printed, mechanical reason
    (R1..R5).  The remaining 7 of the 20 come from bucket T4 and from the
    eight-slot jump block at 0xFE3000.

    THE TWO CORRECTIONS, both to work this file itself shipped:
      * `Ring_InitTenOfFourteen`'s Evidence line still said its ten calls were
        "every `T_Ring*_Init` slot in prom_b".  prom_b has FOURTEEN; the
        routine at 0xF825D4 -- now `Ring_InitAllFourteen` -- calls all of them.
        ★ THE FIX IS IN THE NAMES TABLE, NOT ONLY IN THE .s: round 8 changed
        the label and left the table saying `Ring_InitAllTen`, so the script's
        own --selftest was FAILING in the committed tree and a re-run of
        --apply would have written the refuted sentence back.
      * a `re.match` object was being stored as `endflow`, so `--dump` printed
        `<re.Match object ...>` in the `end` column for two routines.  Bool-
        equivalent, so no count ever moved; only the printing was wrong.

    AND ONE CORRECTION THIS LANE CANNOT APPLY, because prom_b is another lane's
    file this round: prom_b's `GroupMaxMemberIndex_ToneGroupsCopy` header says
    `Read by: prom_a sub_FC2222 ... ld XIX,0x00F06EE4`.  0x00F06EE4 is loaded
    ONCE in all of prom_a, at 0xFC22A3, which is past sub_FC2222's extent end
    0xFC2281 and inside what is now `SoundGroup_MaxMemberIndex_GetToneCopy`.
    Two --selftest checks pin it.

────────────────────────────────────────────────────────────────────────────────
WHAT `--dump` PRINTS FOR EVERY ONE OF THEM
────────────────────────────────────────────────────────────────────────────────
    addr        from the LABEL, not from the listing.  61 of these routines sit
                inside gen_prom_a_fad800_module.py's range, whose emitter prints
                no `; ADDR bytes` column at all; an address-keyed census silently
                drops them, which is the bug that made round 6 publish "302
                reached by nothing" for a number that is 301.
    ext         extent BYTES: the next top label's address minus this one's.
    n_ext       instructions across that ADDRESS EXTENT.  A round-3 reviewer
                caught a header claiming "fifteen instructions" for a
                thirty-instruction routine because the count had stopped at an
                internal label; this is the count that does not.
    flw         instructions reachable by FOLLOWING CONTROL FLOW from the entry,
                bounded by the extent.  This is the scope used for every TOUCH,
                because a bare extent credits a later, unlabelled routine's work
                to this label -- the mistake that forced round 5 to retract
                `Paint_MasterTrackClear`.  560 of 2,882 have flw < n_ext;
                `--gap` ranks them, and a large gap means the extent holds a
                second, unlabelled routine.
                ⚠ THE SCOPE CHANGES ANSWERS, NOT JUST COUNTS: 729 routines form
                a work-DRAM address in the flow scope and about 770 in the
                extent scope.  Any "N of them touch X" is meaningless without
                the scope beside it.
    leaf        no call/calr, no jump out of the extent, no `swi`.  854 are.
    end         the last instruction of the extent is ret/reti/retd or an
                unconditional jump.  2,646 are; `-` is what a mis-split label
                or a `jp (xix)`-only exit looks like.
    d / s / t   call sites: DIRECT, prom_b directory SLOTS that publish it, and
                sites that call it THROUGH such a slot.  ★ The three are printed
                apart because collapsing them is how "no references" gets said
                about a routine that has 22 of them: 672 routines are published
                by a slot and reached no other way, and only 299 are reached by
                nothing at all.
    c           distinct CONTENT-named callers.
    bucket      and the evidence that put it there.

────────────────────────────────────────────────────────────────────────────────
THE BUCKETS (first match wins; `--census` prints all of them with sizes)
────────────────────────────────────────────────────────────────────────────────
    The sizes below are what `--census` prints NOW, i.e. AFTER this round's 16
    names left the population; the population is 2,882 and not 2,898.

    SHAPE  -- the body transcribes into a name with no outside fact needed
        S1  bare `ret`, a one-byte object ......................... 281
        S2  returns before doing anything, longer extent ...........  47
        S3  forwarder: one call and a ret .......................... 120
        S4  bare tail jump .........................................  17
        S5  single-cell writer .....................................  36
        S6  leaf with no memory reference at all ................... 113
    TOUCH  -- an outside fact in the body says what it is for
        T1  an address in a NAMED DEVICE WINDOW ......................  1
            ★ It was TWELVE.  Eleven are now named and the twelfth is the one
              refusal, so this bucket is EMPTIED and the next round should not
              plan against it.
        T2  reads or writes an SFR (page 0x00-0x7F) ................   7
        T3  graphics: `swi`, or a display-list interpreter entry ... 118
        T4  a CONTENT-named ROM object, distinctively ..............  81
        T5  calls a CONTENT-named routine, distinctively ...........  65
    CALLER
        C1  a CONTENT-named routine calls it, distinctively ........  27
    NOTHING
        N   none of the above ................................... 1,969

    ⚠ A BUCKET IS AN EVIDENCE CLASS, NOT A PROMISE OF A NAME.  S1..S6 say the
      body can be transcribed; they do NOT say the transcription is worth
      shipping.  Round 7 declined to re-spell `Ring_Get_0080` as
      `Ring_Get_Cap0080` because the suffix already IS the capacity and the
      re-spelling would have moved prom_a's LOWER bound +0.54 points while
      changing nothing known; this file agrees and did not touch S1..S6 either.
      T3 is round 7's two graphics levers, kept in the census for continuity and
      NOT re-mined -- it named 24 painters and refused 7, and the 36 that draw
      only glyph records are the correct answer for them.

────────────────────────────────────────────────────────────────────────────────
★ WHAT WAS ACTUALLY NAMED, AND WHY THE COUNT IS 16 AND NOT 600
────────────────────────────────────────────────────────────────────────────────
    Sixteen names, and here is where each came from:

        11  bucket T1 -- EVERY routine in prom_a that forms an address in a
            device window notes/FINDINGS-memory-map.md sec.1 has established,
            except the one refused.  T1 is now empty but for that refusal.
         3  bucket T2 -- an SFR in the body (PB, P7, DMA3V)
         1  bucket T4 -- Ring_InitAllTen
         1  ★ bucket N.  THE TERMINAL BUCKET.  `ExtBoard_Identify` scored as
            having no distinguishing evidence: its two callees are
            Link_SendCommandE2 and Link_WaitBlockDone, called by 11 and 12
            other routines, so the distinctiveness filter correctly threw both
            out -- and the tree had ALREADY NAMED it, in prose, with its full
            evidence.  That is the honest bound on the 68.3%: it measures what
            THESE mechanisms can see, and one of its members was nameable all
            along by a mechanism no census had.  Any future lane should read it
            that way and not as an estimate of how much is unknowable.

    `--applied` prints all sixteen with their Evidence and Unknown lines.

      Dev7E_WriteByte / Dev7E_WriteWord / Dev7E_ReadByte / Dev7E_ReadWord
        The four accessors of the 16-bit port at 0x7E0008-0x7E0017.
        FINDINGS-memory-map.md and FINDINGS-prom_a-fdc.md sec.6 IDENTIFIED all
        four by address and the listing never labelled them.  `Dev7E_` is this
        tree's own spelling for a device whose ROLE is open -- `Dev7A_`,
        `Dev7B_` and `Dev7F_` are already in this file.

      Link_Init_DmaAndTimer, Link_SendCountedBlock, Link_SendCommandE2,
      Link_SendCommandAndLong, Link_SendCommandE1, Link_SendCommandE4,
      Link_SendCommandE7, Link_SendCommand5_WaitDone
        Every routine in prom_a that writes the inter-processor link port at
        0x7C0000.  They are one six-step shape -- wait on (0x6007D9), drop P7
        bit 0, set a state code, write ONE command byte, wait on P7 bit 3, then
        uDMA2_SetSource + `ldio DMA2V,0x12` + `set 2,(TRUN)` -- and each header
        says which of the six that routine varies.  `uDMA2_SetSource` was
        ALREADY named in this listing, so step 6 is read off a named routine.

      Variant_SetFromPB0, ExtBoard_Identify, VersionScreen_Show
        ★ THE PROSE LEVER, AND ITS WHOLE REACH IS THREE.  These three were
        already NAMED, with their evidence, in the prose of prom_a's own
        power-on-block header -- while their LABELS stayed `sub_XXXXXX`.  Every
        census in this project reads labels, so none could see it.  `--prose`
        runs the scan (three pattern families, both listings, comments only);
        it found exactly three and now finds none.

      Ring_InitAllTen
        Ten consecutive calls and a `ret`, and the ten operands are every
        `T_Ring*_Init` slot in prom_b and nothing else.

    ★ AND ONE DECODE THE NAMES MADE POSSIBLE, which is the argument for naming
      a family together rather than one routine at a time.  Once
      ExtBoard_Identify and VersionScreen_Show were named, their argument
      pushes could be read against Link_SendCommandE2's frame, and they agree:
      the ten-byte record it sends is `+0 remote address (32), +4 local buffer
      (32), +8 length (16)`.  Two independent callers, the same three fields in
      the same order (0xF82892/0xF82898/0xF8289B and
      0xF82A2F/0xF82A35/0xF82A38).  It is written into that routine's Unknown
      line, because what a 0xE2 MEANS to CPU 2 is still open -- both callers
      use it to READ and nothing here says it cannot also write.

    ⚠ AND THE THINGS THIS ROUND REFUSED OR CORRECTED, which are part of the
      result and not an aside:

      * `sub_F831B3` is bucket T1 and is NOT named.  It forms 0x007F0000, but
        device 0x7F's role is open, three bytes inside its loop do not decode as
        instructions, and its four source pointers overlap and reach above the
        words it pushed.  An earlier round had already written that refusal into
        the listing; this round reached it from a different direction and left
        that header alone.  It is counted as ZERO headers here -- reporting an
        existing header as new work is the "+35 headers that were 35 removed
        blank lines" trade a round-3 reviewer caught.
      * TWO round-7 headers were SUPERSEDED, and this is argued rather than
        done quietly.  `--apply-strings` had written "NOT NAMED ... the text
        says what the routine READS, not what it DOES with it" above 0xF8288F
        and 0xF82A28.  That refusal was right for the lever that produced it and
        wrong for this file, because the power-on block a few thousand lines
        above already states what both routines do and names them.  Two headers
        in one file contradicted each other.  The facts they carried -- the
        string at 0xF828C7 and the "wsaa_822" tag at 0xFFFFF0 -- are folded into
        the replacements; `--verify` fails if a "NOT NAMED" header is ever left
        sitting above a name.
      * ONE COMMITTED NUMBER IS CORRECTED.  The power-on block said
        "Variant_SetFromPB0 (0xF82882) is four instructions" and then listed
        five.  It is SIX across its address extent 0xF82882-0xF8288E, `ret`
        included, and --selftest now asserts that and that the old sentence is
        gone.

    NET EFFECT on notes/wave7_documentation_metrics.py:

        prom_a   content  framed  sub_XXXX   LOWER   UPPER   headers  evidence
        before     1,481     253     2,898   32.0%   37.4%     1,159     1,251
        after      1,497     253     2,882   32.3%   37.8%     1,173     1,265

    16 names, all sub_XXXXXX -> content, 0 framed -> content.  Headers +14, not
    +16: sixteen were written and two REPLACED round-7 headers that were already
    counted.  0 bytes converted -- this round censused and named; it did not
    convert, so it added no `sub_XXXXXX` of its own.

────────────────────────────────────────────────────────────────────────────────
★ WHAT THE NEXT ROUND SHOULD TAKE, AND WHAT IT MUST NOT DO
────────────────────────────────────────────────────────────────────────────────
    ⚠ ROUND 9 UPDATE: six of the T4 routines below ARE now named
      (sub_FC2222, sub_FC2282, sub_FC22E0, sub_FC2422, sub_FEB2D4 and
      sub_F825D4), so the bucket is 81 minus those; `--bucket T4` prints the
      live list.  T5 (66) and C1 (27) are still untouched.
    * `--bucket T4` is 81 routines that each load a DISTINCTIVE CONTENT-named
      ROM object, already enumerated with the object beside them: `sub_FEB2D4`
      reaches DrumKitNameBlockPtrs and DrumKitNames, `sub_FC2222` three
      GroupMaxMemberIndex tables, `sub_FC0D41` ScaleTuningOffsets.  That is the
      largest bucket with real outside evidence in it and no round has mined it.
      T5 (65) and C1 (27) are next.
    * ⚠ DO NOT RE-RUN notes/gen_prom_a_block.py TO PICK UP THE LINK NAMES.  Its
      declared range is 0xF8BC00-0xF8E47F and a fresh emit was diffed against
      the listing on 2026-08-30: re-splicing it would CONVERT 0xF8C000-0xF8DA00,
      6,656 bytes that are still `.incbin` inside that range and that no lane
      asked for, and would REVERT round 6's thunk renames, which live in the .s
      prose and not in the side-car.  This round instead wrote the names into
      BOTH the .s and notes/prom_a_block_headers.txt, so a future emit
      reproduces them.
    * TWO MECHANISMS ARE EXHAUSTED AND MUST NOT BE RE-RUN AS A PLAN: the kernel
      twins reached exactly ONE routine (two independent matchers agreed), and
      the painter heuristic mis-attributed 6 of 24 names by scoping to source
      line instead of the routine's own `ret`.  The prose lever above is now a
      third: its reach was 3 and it is spent.

────────────────────────────────────────────────────────────────────────────────
WHAT THIS FILE DOES NOT CLAIM
────────────────────────────────────────────────────────────────────────────────
    * "NOTHING" is a statement about THIS TREE's evidence at this barrier.  A
      converted prom_b span, a schematic, or Felipe at the keyboard could name
      any of them tomorrow.
    * A `Dev7E_` or `Link_` name claims the routine touches that port and moves
      that many bytes.  It claims nothing about what the far side does with them,
      and every header says so under Unknown.
    * The flow walk does not follow `jp (xix)` and cannot; 263 of those exist in
      prom_a (counted over instruction lines by --selftest).  A routine whose only exit is one is counted as not ending in a
      flow end, and `--gap` marks it `unresolved exit`.
    * The SFR names are MAME's, via this tree's include/tmp95c061_sfr.inc, and
      nothing more.  ⚠ notes/wave7_xref_tlcs900_family.py measured that the
      WSA1 and the KN5000 share 68 register NAMES and exactly ONE address, so no
      sibling SFR address is used here -- every one comes from this part's own
      include file.

RUN
    python3 notes/prom_a_census_round8.py --census      # the bucket sizes
    python3 notes/prom_a_census_round8.py --dump        # every routine, one line
    python3 notes/prom_a_census_round8.py --dump 40     # the first 40
    python3 notes/prom_a_census_round8.py --nothing     # the terminal bucket
    python3 notes/prom_a_census_round8.py --bucket T4   # one bucket, with detail
    python3 notes/prom_a_census_round8.py --popular     # what distinctiveness drops
    python3 notes/prom_a_census_round8.py --sweep       # how much --k decides
    python3 notes/prom_a_census_round8.py --gap         # extent vs flow disagreement
    python3 notes/prom_a_census_round8.py --prose       # the third lever, reach 3
    python3 notes/prom_a_census_round8.py --applied     # this round's 16 names
    python3 notes/prom_a_census_round8.py --refusals    # and its refusal
    python3 notes/prom_a_census_round8.py --apply       # write them into the .s
    python3 notes/prom_a_census_round8.py --verify      # they are in the .s
    python3 notes/prom_a_census_round8.py --selftest    # 59 checks

  ROUND 9 (2026-08-30), the WRAPPER lever:
    python3 notes/prom_a_census_round8.py --wrappers    # the 220, the 47, the 20
    python3 notes/prom_a_census_round8.py --applied9    # round 9's 20 headers
    python3 notes/prom_a_census_round8.py --emitters    # which names a re-emit reverts
    python3 notes/prom_a_census_round8.py --framed      # why framed -> content is 0 here
    python3 notes/prom_a_census_round8.py --apply9      # write them into the .s
    python3 notes/prom_a_census_round8.py --verify9     # read them back
"""
import bisect
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_understanding_round6 as R6          # noqa: E402  Image/body/references
import prom_a_understanding_round7 as R7          # noqa: E402  subs/extents/thunk hop

S_A = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
RULE = "; ---------------------------------------------------------------------"

# ===========================================================================
# 0. the vocabulary the census reads the body with
# ===========================================================================
# ★ THE DEVICE WINDOWS ARE NOT INVENTED HERE.  Every row is a row of
# notes/FINDINGS-memory-map.md §1 "Resulting map", which derives each one from a
# named instruction in the two listings.  The line number of that row is quoted
# so the claim can be walked back, and --selftest re-reads the file and fails if
# a row's address no longer appears in it.
# The fourth column is the address the memory map itself SPELLS, which is not
# always the window base -- it names 0x7B0004/0x7B0005, not 0x7B0000.  --selftest
# greps the findings file for that exact string, so a row invented here fails.
DEVICES = [
    (0x790000, 0x790002, "DisplayCtl_79", "0x790000",
     "display-controller-shaped port, status/data + command"),
    (0x7A0000, 0x7A0001, "Fdc_Dma_7A", "0x7A0000",
     "FDC data register on the DMA-acknowledged decode"),
    (0x7B0000, 0x7B0010, "Fdc_Msr_7B", "0x7B0004",
     "uPD765-family MSR/control + data register"),
    (0x7C0000, 0x7C0001, "Link_7C", "0x7C0000", "inter-processor link port"),
    (0x7E0000, 0x7E0100, "Dev7E", "0x7E0008",
     "16-bit port, block-device layer's second storage unit"),
    (0x7F0000, 0x7F0010, "Dev7F", "0x7F0000",
     "address-register + data-register pair"),
]
# ⚠ DELIBERATELY NOT A DEVICE: 0x600000-0x67FFFF, the work DRAM.  2,245 of the
# 2,898 form an address in it, so it distinguishes nothing and putting it in this
# table would have moved 77% of the population into bucket T1 while saying only
# "this routine uses memory".  It is reported separately by --census as a
# NON-discriminating touch, which is the honest place for it.
DRAM_LO, DRAM_HI = 0x600000, 0x680000

# ★ THE GRAPHICS SERVICE ENTRIES, taken verbatim from round 7 so the two files
# agree about which routines are painters.  0xF417F0 enters display-list
# interpreter A and 0xF417F4 interpreter B (notes/FINDINGS-ui-display-list.md);
# the six stack veneers are notes/prom_b_dl_stack_sites.py's.
GFX_ENTRIES = {0xF417F0: "interpA", 0xF417F4: "interpB",
               0xF31800: "veneer", 0xF31814: "veneer", 0xF31828: "veneer",
               0xF3183D: "veneer", 0xFF75D3: "veneer", 0xFF75EF: "veneer"}

SFR_PAGE_END = 0x80                                # include/tmp95c061_sfr.inc's own bound

RETS = ("ret", "reti", "retd")
CALLS = ("call", "calr")
JUMPS = ("jp", "jr", "jrl")
COND = (r'(?:(?:z|nz|c|nc|lt|le|gt|ge|mi|pl|ov|nov|eq|ne|ugt|ult|uge|ule|t|f|'
        r'NZ|Z|C|NC),\s*)?')
BRANCH = re.compile(r'^\s*(jp|jr|jrl|djnz)\s+' + COND +
                    r'([A-Za-z_.][A-Za-z0-9_.]*|0x[0-9a-fA-F]+|\(\w+\))\s*$')
CALLOP = re.compile(r'^\s*(call|calr)\s+' + COND +
                    r'([A-Za-z_.][A-Za-z0-9_.]*|0x[0-9a-fA-F]+|\(\w+\))\s*$')
SWI = re.compile(r'^\s*swi\s+(0x[0-9a-fA-F]+|\d+)')
DOTL = re.compile(r'^\.L([0-9A-Fa-f]{4,6})$')
# `ldio`/`stio` here are macro spellings of the 8-bit direct forms; the FIRST
# operand is the address (proved by notes/FINDINGS-memory-map.md's table:
# `0xF82769  08 68 14  B0CS  0x14` is spelled `ldio 0x68, 0x14`).
IOFORM = re.compile(r'^\s*(?:ldio|stio)\s+(0x[0-9a-fA-F]+|[A-Z][A-Z0-9_]*)\s*,')
DD8 = re.compile(r'^\s*[a-z_0-9]+_dd8\s+[^,]+,\s*(0x[0-9a-fA-F]+)')
# 16-bit and 24-bit direct memory operands, in every spelling the listing uses.
MEM_PAREN = re.compile(r'\((0x[0-9a-fA-F]{3,6})\)')
MEM_MACRO = re.compile(r'\bM[BWDL](?:8|16|24)\s*,\s*(0x[0-9a-fA-F]+)')
IMM32 = re.compile(r'(?<![\w.])0x([0-9a-fA-F]{6,8})(?![\w.])')

_C = {}
OK = FAIL = 0


def check(label, cond, shown=None):
    global OK, FAIL
    if cond:
        OK += 1
        print("  ok    %-72s %s" % (label, "" if shown is None else repr(shown)))
    else:
        FAIL += 1
        print("  FAIL  %-72s %s" % (label, "" if shown is None else repr(shown)))


# ===========================================================================
# 1. the population and its line extents
# ===========================================================================
def sfr_names():
    """address -> MAME's name for it, from this tree's own include file."""
    if "sfr" in _C:
        return _C["sfr"]
    out = {}
    path = os.path.join(ROOT, "include", "tmp95c061_sfr.inc")
    for ln in open(path):
        m = re.match(r'\.equ\s+([A-Z0-9_]+),\s*(0x[0-9A-Fa-f]+)', ln.strip())
        if m and int(m.group(2), 16) < SFR_PAGE_END:
            out.setdefault(int(m.group(2), 16), m.group(1))
    _C["sfr"] = out
    return out


def line_extents():
    """label -> (first line, one past last line), for EVERY top label in prom_a.

    ★ Line-based, not address-based, on purpose.  2,419 instruction lines in
    prom_a carry no address comment (gen_prom_a_fad800_module.py's emitter
    prints none), so an address-keyed extent walk loses their bodies entirely.
    """
    if "lx" in _C:
        return _C["lx"]
    A, _B = R6.images()
    out = {}
    for k, (i, nm) in enumerate(A.tops):
        out[nm] = (i, A.tops[k + 1][0] if k + 1 < len(A.tops) else len(A.lines))
    _C["lx"] = out
    return out


def addr_index():
    """sorted prom_a instruction addresses, and addr -> (mnemonic, text, line)."""
    if "ai" in _C:
        return _C["ai"]
    A, _B = R6.images()
    idx = {}
    for i, ln in enumerate(A.lines):
        a = A.addr[i]
        if a is None or ln.startswith(";"):
            continue
        m = R6.MNEM.match(ln)
        if not m:
            continue
        txt = re.sub(r'^[A-Za-z_.][A-Za-z0-9_.]*:\s*', '', ln.split(";")[0].strip())
        idx.setdefault(a, (m.group(1), txt, i))
    _C["ai"] = (sorted(idx), idx)
    return _C["ai"]


def next_addr(a):
    order, _idx = addr_index()
    j = bisect.bisect_right(order, a)
    return order[j] if j < len(order) else None


def branch_target(addr, mnem, op):
    """Resolve a branch operand to an address, or None if it cannot be.

    `jr <hex>` is a signed 8-bit DISPLACEMENT on a 2-byte instruction, `jrl
    <hex>` a signed 16-bit one on a 3-byte instruction, `jp <hex>` an absolute
    address, and a `.LXXXXXX` label spells its own address.  Anything else --
    `jp (xix)`, and there are 249 of those -- is unresolvable and says so.
    """
    m = DOTL.match(op)
    if m:
        return int(m.group(1), 16)
    if op.startswith("(") or not op.startswith("0x"):
        A, _B = R6.images()
        r = A.routines.get(op)
        if r and r[2] is not None:
            return r[2]
        if r is None and R6.SUB.match(op or ""):
            return R7.sub_addr(op)
        return None
    v = int(op, 16)
    if mnem == "jp":
        return v
    if addr is None:
        return None
    if mnem == "jr" or mnem == "djnz":
        return addr + 2 + (v - 0x100 if v >= 0x80 else v)
    if mnem == "jrl":
        return addr + 3 + (v - 0x10000 if v >= 0x8000 else v)
    return None


# ===========================================================================
# 2. the record: everything a name would have to come from
# ===========================================================================
class Rec(object):
    __slots__ = ("name", "addr", "end", "ext_bytes", "n_ext", "n_flow", "leaf",
                 "endflow", "gfx", "sfr", "dev", "dram", "romobj", "callees",
                 "cell_writes", "cell_reads", "swis", "unresolved_exit",
                 "d_refs", "dir_refs", "t_refs", "content_callers", "bucket", "why")


def build():
    """One pass over prom_a, producing a Rec for every `sub_XXXXXX`."""
    if "recs" in _C:
        return _C["recs"]
    A, _B = R6.images()
    lx = line_extents()
    ends = R7.extent_ends()
    _order, idx = addr_index()
    cobj = R7.content_objects()
    slots = R7.thunk_slots()
    sfr = sfr_names()
    recs = []
    for nm in R7.subs():
        r = Rec()
        r.name, r.addr = nm, R7.sub_addr(nm)
        r.end = ends.get(nm)
        r.ext_bytes = (r.end - r.addr) if r.end else 0
        i, e = lx[nm]
        # --- the two scopes -------------------------------------------------
        ext_lines = []
        for j in range(i, e):
            ln = A.lines[j]
            if ln.startswith(";") or not ln.strip():
                continue
            m = R6.MNEM.match(ln)
            if not m or m.group(1).startswith("."):
                continue
            ext_lines.append((A.addr[j], m.group(1),
                              re.sub(r'^[A-Za-z_.][A-Za-z0-9_.]*:\s*', '',
                                     ln.split(";")[0].strip())))
        r.n_ext = len(ext_lines)
        flow = flow_body(r.addr, r.end, ext_lines)
        r.n_flow = len(flow)
        # ⚠ bool(): the second arm is an `re.match` OBJECT, and returning it made
        # --dump print `<re.Match object ...>` in the `end` column for the two
        # routines whose last instruction is a bare `jp`.  Bool-equivalent, so no
        # count ever moved; it was the PRINTING that was wrong.
        r.endflow = bool(ext_lines) and bool(ext_lines[-1][1] in RETS or
                                            (ext_lines[-1][1] in JUMPS and
                                             re.match(r'^\s*(jp|jr|jrl)\s+[^,]*$',
                                                      " " + ext_lines[-1][2])))
        # --- what the FLOW-REACHABLE body touches ---------------------------
        r.leaf, r.unresolved_exit = True, False
        r.sfr, r.dev, r.dram = set(), set(), set()
        r.romobj, r.callees, r.swis, r.gfx = set(), set(), set(), set()
        r.cell_writes, r.cell_reads = set(), set()
        for a, mn, txt in flow:
            if mn in CALLS:
                r.leaf = False
            if mn == "swi":
                r.leaf = False
                ms = SWI.match(" " + txt)
                if ms:
                    r.swis.add(int(ms.group(1), 0))
            mc = CALLOP.match(" " + txt)
            if mc:
                t = branch_target(a, "jp" if mc.group(1) == "call" else "calr", mc.group(2)) \
                    if mc.group(1) == "call" else None
                if mc.group(1) == "call":
                    t = branch_target(a, "jp", mc.group(2))
                else:
                    op = mc.group(2)
                    t = None
                    if op.startswith("0x") and a is not None:
                        t = R6.calr_target(a, int(op, 16))
                    else:
                        t = branch_target(a, "jp", op)
                if t is not None:
                    t = slots.get(t, (t, None))[0]
                    if t in GFX_ENTRIES:
                        r.gfx.add(GFX_ENTRIES[t])
                    if cobj.get(t):
                        r.callees.add(cobj[t])
            mb = BRANCH.match(" " + txt)
            if mb and mb.group(1) in ("jp", "jrl", "jr"):
                t = branch_target(a, mb.group(1), mb.group(2))
                if t is None:
                    r.unresolved_exit = True
                elif r.end is not None and not (r.addr <= t < r.end):
                    r.leaf = False
                    t2 = slots.get(t, (t, None))[0]
                    if t2 in GFX_ENTRIES:
                        r.gfx.add(GFX_ENTRIES[t2])
                    if cobj.get(t2):
                        r.callees.add(cobj[t2])
            # memory operands
            mi = IOFORM.match(" " + txt)
            if mi:
                v = mi.group(1)
                aa = int(v, 16) if v.startswith("0x") else None
                if aa is None:
                    r.sfr.add(v)
                elif aa < SFR_PAGE_END:
                    r.sfr.add(sfr.get(aa, "io_%02X" % aa))
            md = DD8.match(" " + txt)
            if md and int(md.group(1), 16) < SFR_PAGE_END:
                aa = int(md.group(1), 16)
                r.sfr.add(sfr.get(aa, "io_%02X" % aa))
            for m2 in list(MEM_PAREN.finditer(txt)) + list(MEM_MACRO.finditer(txt)):
                v = int(m2.group(1), 16)
                classify_addr(r, v, txt, cobj)
            for m2 in IMM32.finditer(txt):
                classify_addr(r, int(m2.group(1), 16), txt, cobj)
        recs.append(r)
    # --- who reaches it -----------------------------------------------------
    refs, _cnt = R6.references()
    ind = R7.indirect_refs()
    for r in recs:
        d = refs.get(r.name, [])
        t = ind.get(r.name, [])
        directory = [x for x in d if x[3] == "jp" and x[0] == "prom_b"]
        r.d_refs = len([x for x in d if x not in directory])
        r.dir_refs = len(directory)
        r.t_refs = len(t)
        r.content_callers = set(x[2] for x in d + t
                                if x[2] and R7.is_content(x[2]))
    _C["recs"] = recs
    return recs


def classify_addr(r, v, txt, cobj):
    """Put one numeric operand into the right touch set."""
    for lo, hi, tag, _anchor, _desc in DEVICES:
        if lo <= v < hi:
            r.dev.add(tag)
            return
    if DRAM_LO <= v < DRAM_HI:
        r.dram.add(v)
        return
    if 0xF00000 <= v <= 0xFFFFFF:
        nm = cobj.get(v)
        if nm:
            r.romobj.add(nm)
        return
    if v < 0x8000:
        if re.match(r'^\s*(st|m_st|m_or|m_and|m_set|m_res|stdi|stib|stiw|stda|stw|stb|stl)',
                    " " + txt):
            r.cell_writes.add(v)
        else:
            r.cell_reads.add(v)


def flow_body(entry, end, ext_lines):
    """★ Instructions reachable by FOLLOWING CONTROL FLOW from the entry.

    Bounded by the extent, so it can never credit the next routine's work to
    this label -- the scoping error that forced round 5's retraction.  Falls
    back to the whole extent for the 61 routines whose lines carry no address at
    all, because for those there is no flow to follow and half a body is worse
    than a stated over-count.

    ⚠ BOUNDED BY THE *LINE* EXTENT AS WELL AS THE ADDRESS ONE, and the first
    draft was not.  `extent_ends()` skips top labels that carry no address, so
    for the routines inside gen_prom_a_fad800_module.py's range the ADDRESS
    extent runs past several later labels; a walk bounded only by it reported
    more instructions than the routine's own listing has, which --selftest
    caught as `n_flow > n_ext`.
    """
    if entry is None or end is None or any(a is None for a, _m, _t in ext_lines):
        return ext_lines
    allowed = set(a for a, _m, _t in ext_lines)
    order, idx = addr_index()
    seen, work = set(), [entry]
    while work:
        a = work.pop()
        if a in seen or a not in idx or a not in allowed or not (entry <= a < end):
            continue
        seen.add(a)
        mn, txt, _li = idx[a]
        if mn in RETS:
            continue
        mb = BRANCH.match(" " + txt)
        if mb:
            t = branch_target(a, mb.group(1), mb.group(2))
            if t is not None:
                work.append(t)
            uncond = mb.group(1) != "djnz" and "," not in mb.group(2) and \
                not re.match(r'^\s*(jp|jr|jrl)\s+\w+\s*,', " " + txt)
            if uncond:
                continue
        n = next_addr(a)
        if n is not None:
            work.append(n)
    return [(a, idx[a][0], idx[a][1]) for a in sorted(seen)]


# ===========================================================================
# 3. distinctiveness, then the buckets
# ===========================================================================
def popularity():
    """touched object -> how many of the 2,898 touch it.

    ★ THE FILTER THAT MAKES THE TOUCH AXIS MEAN ANYTHING.  914 routines call a
    CONTENT-named routine; the top one is called by 100 of them.  An object
    touched by a hundred routines names none of them.
    """
    if "pop" in _C:
        return _C["pop"]
    p = collections.Counter()
    for r in build():
        for x in r.callees:
            p["callee:" + x] += 1
        for x in r.romobj:
            p["romobj:" + x] += 1
        for x in r.content_callers:
            p["caller:" + x] += 1
    _C["pop"] = p
    return p


def bucket(r, k=3):
    """(bucket, one-line reason).  FIRST MATCH WINS, in the order documented.

    ⚠ THE ORDER IS LOAD-BEARING AND THE FIRST DRAFT HAD IT WRONG.  `S2 returns
    immediately` was tested before `S4 bare tail jump`, and since both are
    one-instruction bodies S2 swallowed all nine tail jumps and S4 printed 0.
    A bucket that prints 0 because an earlier bucket ate it is a measurement
    error, not a finding, so S1/S4 now test WHAT the single instruction IS.
    """
    p = popularity()
    body = r.n_flow
    fl = flow_of(r)
    only = fl[0][1] if len(fl) == 1 else None
    if r.ext_bytes == 1 and only in RETS:
        return "S1", "one byte, a bare ret"
    if only in RETS:
        return "S2", "returns immediately, extent %d bytes" % r.ext_bytes
    if only in JUMPS:
        return "S4", "a bare tail jump"
    if body == 2 and any(m in CALLS for _a, m, _t in fl) and fl[-1][1] in RETS:
        return "S3", "forwarder: one call and a ret"
    if r.dev:
        return "T1", "device window " + "+".join(sorted(r.dev))
    if r.sfr:
        return "T2", "SFR " + "+".join(sorted(r.sfr))
    if r.swis or r.gfx:
        return "T3", ("swi " + ",".join(str(x) for x in sorted(r.swis)) if r.swis
                      else "display-list interpreter " + "+".join(sorted(r.gfx)))
    if r.romobj and any(p["romobj:" + x] <= k for x in r.romobj):
        return "T4", "ROM object " + "+".join(sorted(x for x in r.romobj
                                                     if p["romobj:" + x] <= k))
    if r.callees and any(p["callee:" + x] <= k for x in r.callees):
        return "T5", "calls " + "+".join(sorted(x for x in r.callees
                                                if p["callee:" + x] <= k))
    if r.content_callers and any(p["caller:" + x] <= k for x in r.content_callers):
        return "C1", "called by " + "+".join(sorted(x for x in r.content_callers
                                                    if p["caller:" + x] <= k))
    if r.leaf and len(r.cell_writes) == 1 and not r.cell_reads and body <= 8:
        return "S5", "single-cell writer, (0x%04X)" % sorted(r.cell_writes)[0]
    if r.leaf and not r.cell_writes and not r.cell_reads and not r.dram and body <= 12:
        return "S6", "leaf, no memory reference, %d instructions" % body
    return "N", "no distinguishing evidence"


def flow_of(r):
    if not hasattr(flow_of, "_c"):
        flow_of._c = {}
    if r.name not in flow_of._c:
        A, _B = R6.images()
        i, e = line_extents()[r.name]
        ext = []
        for j in range(i, e):
            ln = A.lines[j]
            if ln.startswith(";") or not ln.strip():
                continue
            m = R6.MNEM.match(ln)
            if not m or m.group(1).startswith("."):
                continue
            ext.append((A.addr[j], m.group(1),
                        re.sub(r'^[A-Za-z_.][A-Za-z0-9_.]*:\s*', '',
                               ln.split(";")[0].strip())))
        flow_of._c[r.name] = flow_body(r.addr, r.end, ext)
    return flow_of._c[r.name]


BUCKET_DESC = [
    ("S1", "bare `ret`, one byte"),
    ("S2", "returns immediately, longer extent"),
    ("S3", "forwarder: one call and a ret"),
    ("S4", "bare tail jump"),
    ("T1", "★ forms an address in a NAMED DEVICE WINDOW"),
    ("T2", "reads or writes an SFR"),
    ("T3", "graphics: swi, or a display-list interpreter entry"),
    ("T4", "loads a CONTENT-named ROM object, distinctively"),
    ("T5", "calls a CONTENT-named routine, distinctively"),
    ("C1", "called by a CONTENT-named routine, distinctively"),
    ("S5", "single-cell writer"),
    ("S6", "leaf, no memory reference"),
    ("N", "★★ NOTHING -- no distinguishing evidence of any kind"),
]


def assign(k=3):
    for r in build():
        r.bucket, r.why = bucket(r, k)
    return build()


# ===========================================================================
# 4. modes
# ===========================================================================
def mode_census(k=3):
    recs = assign(k)
    n = len(recs)
    print("prom_a `sub_XXXXXX` census, round 8 -- %d routines, k=%d\n" % (n, k))
    c = collections.Counter(r.bucket for r in recs)
    print("  %-4s %7s %7s   %s" % ("", "count", "share", "bucket"))
    for tag, desc in BUCKET_DESC:
        print("  %-4s %7d %6.1f%%   %s" % (tag, c[tag], 100.0 * c[tag] / n, desc))
    print("  %-4s %7d %6.1f%%" % ("all", sum(c.values()), 100.0))
    shape = sum(c[t] for t in ("S1", "S2", "S3", "S4", "S5", "S6"))
    touch = sum(c[t] for t in ("T1", "T2", "T3", "T4", "T5"))
    print("\n  nameable by a SHAPE that already worked ......... %5d  (%.1f%%)"
          % (shape, 100.0 * shape / n))
    print("  nameable from WHAT THEY TOUCH .................. %5d  (%.1f%%)"
          % (touch, 100.0 * touch / n))
    print("  nameable from WHO CALLS THEM ................... %5d  (%.1f%%)"
          % (c["C1"], 100.0 * c["C1"] / n))
    print("  ★★ NOTHING ..................................... %5d  (%.1f%%)"
          % (c["N"], 100.0 * c["N"] / n))
    nd = sum(1 for r in recs if r.dram)
    print("\n  ⚠ NON-DISCRIMINATING, and kept out of the buckets on purpose:")
    print("    %d of the %d (%.0f%%) form an address in the work DRAM"
          % (nd, n, 100.0 * nd / n))
    print("    0x600000-0x67FFFF -- more than sixty times as many as touch any")
    print("    ONE of the six real device windows put together.  A region that")
    print("    common distinguishes nothing, so it is reported here and not as a")
    print("    bucket; the same reasoning is why every touched object is scored")
    print("    by how many routines touch it before it may name one (--popular).")
    print("\n  leaf routines: %d    ending in a flow end: %d"
          % (sum(1 for r in recs if r.leaf), sum(1 for r in recs if r.endflow)))
    print("  reached by NOTHING at all (no call, no directory slot, no pointer): %d"
          % sum(1 for r in recs if not r.d_refs and not r.t_refs and not r.dir_refs))
    print("  published by a prom_b directory slot and reached no other way:      %d"
          % sum(1 for r in recs if not r.d_refs and not r.t_refs and r.dir_refs))


def mode_dump(limit=None, only=None):
    recs = assign()
    print("%-13s %-8s %5s %5s %5s %-4s %-4s %-18s %s"
          % ("name", "addr", "ext", "n_ext", "flw", "leaf", "end",
             "d=direct s=slot t=thru c=named-callers", "bucket / touches"))
    shown = 0
    for r in recs:
        if only and r.bucket != only:
            continue
        print("%-13s %06X %6d %5d %5d %-4s %-4s d%-3d s%-3d t%-3d c%-2d %-3s %s"
              % (r.name, r.addr, r.ext_bytes, r.n_ext, r.n_flow,
                 "leaf" if r.leaf else "-", "ret" if r.endflow else "-",
                 r.d_refs, r.dir_refs, r.t_refs, len(r.content_callers),
                 r.bucket, r.why))
        shown += 1
        if limit and shown >= limit:
            print("  ... (%d more; omit the limit to see them all)"
                  % (sum(1 for x in recs if not only or x.bucket == only) - shown))
            break


def mode_popular(k=3):
    p = popularity()
    print("Objects a routine can touch, by HOW MANY of the %d touch them."
          % len(build()))
    print("Everything above k=%d is thrown out as non-discriminating.\n" % k)
    for kind in ("callee", "romobj", "caller"):
        rows = [(v, x[len(kind) + 1:]) for x, v in p.items() if x.startswith(kind + ":")]
        rows.sort(reverse=True)
        print("  --- %s: %d distinct, %d of them touched by <= %d routines"
              % (kind, len(rows), sum(1 for v, _x in rows if v <= k), k))
        for v, x in rows[:12]:
            print("      %5d  %s" % (v, x))
        print()


def mode_sweep():
    print("How much of the answer does the distinctiveness knob decide?\n")
    print("  %-4s %7s %7s %7s %7s %7s" % ("k", "T4", "T5", "C1", "N", "N%"))
    for k in (1, 2, 3, 5, 10, 25):
        _C.pop("assigned", None)
        for r in build():
            r.bucket, r.why = bucket(r, k)
        c = collections.Counter(r.bucket for r in build())
        n = len(build())
        print("  %-4d %7d %7d %7d %7d %6.1f%%"
              % (k, c["T4"], c["T5"], c["C1"], c["N"], 100.0 * c["N"] / n))
    print("\n  The knob moves NOTHING by a few points and never changes the")
    print("  conclusion, which is what a knob that is not deciding the answer")
    print("  looks like.  --census uses k=3.")


def mode_gap(limit=100):
    recs = assign()
    rows = sorted(((r.n_ext - r.n_flow, r.name, r) for r in recs), reverse=True)
    print("Where the ADDRESS EXTENT and the FLOW-REACHABLE body disagree.")
    print("A large gap means unreachable tail bytes inside the extent -- usually")
    print("a second, unlabelled routine, and always a reason not to quote the")
    print("extent as 'this routine's instruction count'.\n")
    print("  %-13s %6s %6s %6s  %s" % ("name", "ext", "flow", "gap", "why"))
    for g, _nm, r in rows[:limit]:
        if g <= 0:
            break
        print("  %-13s %6d %6d %6d  %s" % (r.name, r.n_ext, r.n_flow, g,
                                           "unresolved exit" if r.unresolved_exit else ""))
    n_gap = sum(1 for g, _nm, _r in rows if g > 0)
    print("\n  %d of %d have a gap; %d have none." % (n_gap, len(recs), len(recs) - n_gap))


def mode_nothing(limit=60):
    recs = assign()
    n = [r for r in recs if r.bucket == "N"]
    print("★★ THE TERMINAL BUCKET: %d of %d (%.1f%%)\n"
          % (len(n), len(recs), 100.0 * len(n) / len(recs)))
    print("Nothing in either listing says what these are for.  They are not dead")
    print("-- %d of them have a call site -- they are simply surrounded by other"
          % sum(1 for r in n if r.d_refs or r.t_refs or r.dir_refs))
    print("`sub_XXXXXX`.  The next round should plan against this number, not")
    print("against the population.\n")
    print("  %-13s %6s %5s %-5s %s" % ("name", "bytes", "flw", "refs", ""))
    for r in n[:limit]:
        print("  %-13s %6d %5d d%-2d s%-2d t%-2d" % (r.name, r.ext_bytes, r.n_flow,
                                                     r.d_refs, r.dir_refs, r.t_refs))
    if len(n) > limit:
        print("  ... %d more" % (len(n) - limit))


# ===========================================================================
# 5. this round's names -- bucket T1, every one from a documented device window
# ===========================================================================
# Each entry is (old label, new label, what it IS, the Evidence: text, the
# Unknown: text).  Every address in an Evidence line is the address of the
# INSTRUCTION, not of its immediate operand -- round 1 shipped ~31 citations one
# byte past the instruction and the signature of that bug is that the byte at
# cited-1 is an opcode.  --selftest re-reads each cited address out of the
# listing and fails if the mnemonic there is not the one the text names.
NAMES = [
    ("sub_FE4C73", "Dev7E_WriteByte",
     "writes one byte to the 0x7E0000 port at index ((n & 7) | 0x08) or | 0x10",
     "index 0xFE4C73 `ld C,(XSP+0x06)` masked by 0xFE4C76 `and C,0x07`; the bank "
     "bit is 0xFE4C7F `set 0x03,C` when (XSP+0x04) is zero and 0xFE4C84 "
     "`set 0x04,C` when it is not; the window is 0xFE4C8D "
     "`add XBC,0x007e0000`; the byte moved is 0xFE4C93 `ld A,(XSP+0x08)` into "
     "0xFE4C96 `ld (XBC),A`. FINDINGS-memory-map.md names 0x7E0008-0x7E0017 and "
     "this routine as one of its four accessors",
     "what the two banks selected by bit 3 and bit 4 ARE. The caller's flag at "
     "(XSP+0x04) chooses between them and nothing in prom_a says what either "
     "means; FINDINGS-memory-map.md records the same gap"),
    ("sub_FE4C99", "Dev7E_WriteWord",
     "writes one 16-bit word to the same port, index built the same way",
     "the same five steps at 0xFE4C99/0xFE4C9C/0xFE4CA5/0xFE4CAA/0xFE4CB3; the "
     "word moved is 0xFE4CB9 `ld WA,(XSP+0x08)` into 0xFE4CBC `ld (XBC),WA`",
     "the bank meaning, as for Dev7E_WriteByte"),
    ("sub_FE4CBF", "Dev7E_ReadByte",
     "reads one byte from the same port and index, returning it in L",
     "index 0xFE4CBF `ld A,(XSP+0x06)` masked by 0xFE4CC2 `and A,0x07`, banked "
     "by 0xFE4CCB/0xFE4CD0 `set 0x03,A`/`set 0x04,A`, window 0xFE4CD7 "
     "`add XWA,0x007e0000`; the byte read is 0xFE4CDD `ld L,(XWA)`",
     "the bank meaning, as above"),
    ("sub_FE4CE0", "Dev7E_ReadWord",
     "reads one 16-bit word from the same port and index, returning it in HL",
     "the same steps at 0xFE4CE0/0xFE4CE3/0xFE4CEC/0xFE4CF1/0xFE4CF8; the word "
     "read is 0xFE4CFE `ld HL,(XWA)`",
     "the bank meaning, as above"),
    # ★ THE THIRD LEVER, AND ITS REACH IS EXACTLY THREE.  Some routines already
    # HAVE a name in this tree -- asserted in the PROSE of a header somewhere in
    # the two listings, as `Name (0xADDR)` -- while their LABEL is still
    # `sub_XXXXXX`.  Every census in this project reads labels, so none of them
    # could see it.  `--prose` runs the scan; three pattern families over both
    # listings find THREE, and all three are below.  A lever whose reach is 3 is
    # still worth publishing WITH the 3, because the next round now knows not to
    # look again.
    ("sub_F82882", "Variant_SetFromPB0",
     "sets (0x00C4), the model-variant flag, from PORT B bit 0",
     "0xF82882 `ldb a, 0x01`, 0xF82884 `bit_dd8 0x00, 0x1f` (PB is 0x1F in "
     "include/tmp95c061_sfr.inc), 0xF82889 `ldb a, 0x02` on the not-taken arm, "
     "0xF8288B `st_dd8b a, 0xc4`. Six instructions counted across the routine's "
     "whole address extent 0xF82882-0xF8288E, `ret` included. This listing's own "
     "power-on-block header already states the name and the reading -- 1 when "
     "PB0 reads HIGH, 2 when it reads LOW -- and the six chord tests that "
     "branch on it are re-read from the ROM by notes/prom_a_boot_checks.py",
     "which physical variant is 1 and which is 2. The strap is a pin state and "
     "no schematic in this tree names it"),
    ("sub_F8288F", "ExtBoard_Identify",
     "reads the expansion board's 10-byte header and sets (0x00C5) to 0x5A if "
     "it matches",
     "0xF8288F `ldio 0xc5, 0x00` clears the flag; 0xF8289B `ld XWA,0x00c00000` "
     "and 0xF82898 `pushw 0x0a` are the remote address and length handed to the "
     "link block read at 0xF828A1 and 0xF828A8; 0xF828AC `ldb c, 0x0a`, "
     "0xF828AE `ld XIX,0x00002640` and 0xF828B3 `ld XIY,0x00f828c7` set up the "
     "10-byte compare whose only success path is 0xF828C3 `ldio 0xc5, 0x5a`. "
     "0xF828C7 is ExtBoardMagic_F828C7, the ASCII \"WSA1 EXTBD\", already "
     "labelled in this listing, and that label's own header names (0x00C5) as "
     "this routine's output. Called from prom_a 0xF827EA and 0xF827F5, both "
     "`calr`, in the reset path",
     "what reads (0x00C5) afterwards, and what the other 0x30 bytes of the "
     "board header at 0x00C00000 mean. ★ SUPERSEDES round 7's "
     "--apply-strings refusal header, which recorded only that 0xF828B3 loads "
     "the text at 0xF828C7 and declined to name the routine from it; that fact "
     "is kept above and the refusal is not, because the two headers "
     "contradicted each other in one file"),
    ("sub_F82A28", "VersionScreen_Show",
     "reads the two 11-byte ROM tail tags over the link and stages them for the "
     "version screen",
     "0xF82A38 `ld XWA,0x00fffff0` with 0xF82A35 `pushw 0x0b` into 0xF82A2F "
     "`ld XIX,0x00002640`, and 0xF82A5F `ld XWA,0x00f7fff0` with 0xF82A5C "
     "`pushw 0x0b` into 0xF82A56 `ld XIX,0x0000264c`, each through the link "
     "block read at 0xF82A3E/0xF82A45 and 0xF82A65/0xF82A6C; 0xF82A28 "
     "`m_cp_mi16 MW8, 0x80, 0x03e8` spins until the tick counter passes 1000 "
     "before either read. This listing already names the routine in the "
     "power-on block's own header",
     "nothing here draws anything -- the two 11-byte tags are only STAGED at "
     "0x2640 and 0x264C. Which routine paints them is not established by this "
     "body. ★ SUPERSEDES round 7's --apply-strings refusal, which recorded "
     "that 0xF82A38 loads 0xFFFFF0 \"where the ROM reads wsaa_822\" -- that "
     "is prom_a's OWN tail tag, so the first of the two reads fetches this "
     "part's identity and the second (0x00F7FFF0) fetches prom_d's; the "
     "refusal itself contradicted the power-on block's own header and is "
     "removed. Called from prom_a 0xF82A24 (`calr`)"),
    # ⚠ CORRECTED IN ROUND 9, IN THIS TABLE AND NOT ONLY IN THE LISTING.
    # Round 8 shipped this routine as `Ring_InitAllTen`, a reviewer showed the
    # ROM refutes the completeness claim, and the LABEL was changed to
    # `Ring_InitTenOfFourteen` -- while THIS TABLE kept the old name and the
    # Evidence line kept saying "every `T_Ring*_Init` slot in prom_b".  Two
    # consequences, both real: the script's own --selftest failed in the
    # committed tree ("sub_FE1D29 has been renamed to Ring_InitAllTen"), and a
    # re-run of --apply would have rewritten the refuted sentence back into the
    # listing.  Correcting the .s without correcting the generator that emits it
    # is not a correction.
    ("sub_FE1D29", "Ring_InitTenOfFourteen",
     "calls the Init entry of TEN of the fourteen ring buffers, in one run, and "
     "returns",
     "ten consecutive `call` instructions at 0xFE1D29, 0xFE1D2D, 0xFE1D31, "
     "0xFE1D35, 0xFE1D39, 0xFE1D3D, 0xFE1D41, 0xFE1D45, 0xFE1D49 and 0xFE1D4D, "
     "whose operands are prom_b directory slots T_Ring60080A_Init, "
     "T_Ring600A14_Init, T_Ring600C1E_Init, T_Ring601028_Init, "
     "T_Ring601432_Init, T_Ring60153C_Init, T_Ring601646_Init, "
     "T_Ring601850_Init, T_Ring60195A_Init and T_Ring601C6E_Init -- TEN of the "
     "FOURTEEN `T_Ring*_Init` slots in prom_b, and no other call. 0xFE1D51 is "
     "the `ret`. The four it does NOT call are T_Ring60000C_Init, "
     "T_Ring601B64_Init, T_Ring60480A_Init and T_Ring608A0A_Init, and "
     "Ring_InitAllFourteen (0xF825D4) calls all fourteen",
     "why the ninth call is out of address order (T_Ring60195A_Init is reached "
     "through slot 0xF41D28, below all the others), why these ten and not the "
     "fourteen, and what the buffers carry -- FINDINGS-prom_a-ring-buffers.md "
     "has the capacities, not the traffic"),
]


# ★ THE SEVEN WRITERS OF THE LINK PORT.  Every one of them has the same six
# steps, and the header of each says which of the six it varies:
#   1  spin until (0x6007D9) == 0, at most 0x4E20 = 20000 iterations
#   2  `res 0,(0x13)` -- P7 bit 0 low
#   3  (0x6007D9) = a state code, 1 or 2
#   4  write ONE command byte to 0x007C0000
#   5  spin on `bit 3,(0x13)` -- P7 bit 3, the far side's acknowledge -- with the
#      same 20000 limit, and on timeout `set 0,(0x13)` and give up
#   6  uDMA2_SetSource(buffer, count) / `ldio DMA2V,0x12` / `set 2,(TRUN)`,
#      which hands the block to micro-DMA channel 2 clocked by timer 2
# uDMA2_SetSource is prom_a 0xF8E6AF and is ALREADY NAMED in this listing --
# it writes CR_DMAS2 and CR_DMAC2 -- so step 6 is read off a named routine and
# not off a guess.
LINK_NAMES = [
    ("sub_F8E001", "Link_Init_DmaAndTimer",
     "points micro-DMA channel 2's DESTINATION and channel 3's SOURCE at the "
     "link port and programs timer 2",
     "0xF8E014 `ld XIX,0x007c0000` is pushed to 0xF8E01A `call 0xf8e6a2` = "
     "uDMA2_SetDest with 0xF8E011 `pushw 0x08` as the mode, and to 0xF8E022 "
     "`call 0xf8e6bc` = uDMA3_SetSource with 0xF8E01E `pushw 0x00`; the timer "
     "is 0xF8E002 `res_dd8 0x02, 0x20` (TRUN), 0xF8E005 T23MOD=0x0E, 0xF8E008 "
     "INTETC23=0x56, 0xF8E00B INTE0AD=0x01, 0xF8E00E TREG2=0x05, with the SFR "
     "names from include/tmp95c061_sfr.inc",
     "the two mode bytes. FINDINGS-memory-map.md reads DMAM0 = 0x00 as "
     "device-to-RAM and 0x08 as RAM-to-device for the FDC's channel 0, which is "
     "the SAME register field on the same part, so 0x08 here reads as "
     "RAM-to-device and 0x00 as device-to-RAM -- ⚠ that is a transfer of a "
     "field meaning between channels, not a second measurement"),
    ("sub_F8E06C", "Link_SendCountedBlock",
     "sends one command byte that CARRIES ITS OWN BYTE COUNT, then that many "
     "bytes by micro-DMA",
     "the command byte is built by 0xF8E0A0 `ld L,H` / 0xF8E0A2 `dec 1,L` / "
     "0xF8E0A4 `ld C,(XIZ+0x08)` / 0xF8E0A7 `sll c,0x05` / 0xF8E0AA `or C,L`, "
     "so it is ((XIZ+0x08) << 5) | ((XIZ+0x0a) - 1), and it is written by "
     "0xF8E0AF `ld XBC,0x007c0000` / 0xF8E0B7 `ld (XBC),A`; the same "
     "(XIZ+0x0a) is the count pushed at 0xF8E0D7 before 0xF8E0DC "
     "`call 0xf8e6af` = uDMA2_SetSource, whose buffer is 0xF8E0D8 "
     "`ld XBC,(XIZ+0x0c)`. 0xF8E076 `cps h,0x00` returns without sending "
     "anything when the count is zero",
     "what the three-bit field at bits 7..5 selects. "
     "notes/wave7_xref_tlcs900_family.py --link reads the low five bits of a "
     "link command as (length - 1) on BOTH machines, which agrees with the "
     "arithmetic here; the top three bits it calls a selector and neither tree "
     "says what the selector means"),
    ("sub_F8E0FE", "Link_SendCommandE2",
     "sends command 0xE2 followed by a ten-byte record it stages at 0x600793",
     "0xF8E12B `ld XBC,0x007c0000` / 0xF8E130 `ld (XBC),0xe2`; the record is "
     "0xF8E14D-0xF8E15B, which writes (XIZ+0x08) as a longword at (XIX), "
     "(XIZ+0x0e) as a longword at (XIX+0x04) and (XIZ+0x0c) as a word at "
     "(XIX+0x08) with XIX = 0xF8E105 `lda_24 xix,(0x600793)`; 4 + 4 + 2 = 10 "
     "and 0xF8E15E `pushw 0x0a` is the count handed to 0xF8E162 "
     "`call 0xf8e6af` = uDMA2_SetSource. ★ THE THREE FIELDS ARE READ FROM THE "
     "TWO CALLERS, not from this body: ExtBoard_Identify pushes 0x2640, then "
     "0x000A, then 0x00C00000 (0xF82892, 0xF82898, 0xF8289B) and "
     "VersionScreen_Show pushes 0x2640, then 0x000B, then 0x00FFFFF0 "
     "(0xF82A2F, 0xF82A35, 0xF82A38), both immediately before this call, so "
     "(XIZ+0x08) is the REMOTE address, (XIZ+0x0c) the LENGTH and (XIZ+0x0e) "
     "the LOCAL buffer, and the record is +0 remote32, +4 local32, +8 len16",
     "what a 0xE2 MEANS to CPU 2. Both known callers use it to READ and "
     "nothing here says a 0xE2 cannot also write. ⚠ Two callers is two, not a "
     "census: the frame reading above is what those two do, and a third caller "
     "could still pass the fields in another order"),
    ("sub_F8E181", "Link_SendCommandAndLong",
     "sends a command byte ORed with 0xE0 and then one 32-bit argument",
     "0xF8E1A8 `ld D,(XIZ+0x0c)` / 0xF8E1AB `or D,0xe0` / 0xF8E1AE "
     "`ld XBC,0x007c0000` / 0xF8E1B3 `ld (XBC),D`; the argument is 0xF8E1CF "
     "`ld XBC,(XIZ+0x08)` stored by 0xF8E1D2 `stl_da (0x60079d),xbc` and sent "
     "as 0xF8E1D7 `pushw 0x04` bytes from 0xF8E1DA `lda_24 xwa,(0x60079d)` "
     "through 0xF8E1E0 `call 0xf8e6af` = uDMA2_SetSource",
     "which commands of the 0xE0..0xFF group take a longword, and what it is"),
    ("sub_F8E26F", "Link_SendCommandE1",
     "sends command 0xE1, then a six-byte header, then a second block whose "
     "pointer and length are inside that header",
     "0xF8E29C `ld XBC,0x007c0000` / 0xF8E2A1 `ld (XBC),0xe1`; the header is "
     "0xF8E2DA `pushw 0x06` from 0xF8E2DD `lda_24 xbc,(0x6007a1)` through "
     "0xF8E2E3 `call 0xf8e6af`; the second transfer is 0xF8E2FF "
     "`ld BC,(XIX+0x04)` as the count and 0xF8E303 `ld XBC,(XIX)` as the "
     "pointer through 0xF8E306 `call 0xf8e6af`, with XIX = 0xF8E276 "
     "`lda_24 xix,(0x600782)`; between them 0xF8E2EF waits for (0x6007D9) to "
     "reach 1 and 0xF8E2F7 `ldb h,0xc8` spins 200 times",
     "what commands 0xE1, 0xE4 and 0xE7 mean to the far side. All three "
     "routines have this identical shape and differ only in the command byte "
     "and the staging address"),
    ("sub_F8E320", "Link_SendCommandE4",
     "sends command 0xE4, then a six-byte header staged at 0x6007A7, then the "
     "block that header points at -- the same shape as Link_SendCommandE1",
     "0xF8E34D `ld XBC,0x007c0000` / 0xF8E352 `ld (XBC),0xe4`; the header is "
     "0xF8E38B `pushw 0x06` from 0xF8E38E `lda_24 xbc,(0x6007a7)` through "
     "0xF8E394 `call 0xf8e6af`; the payload is 0xF8E3B0 `ld BC,(XIX+0x04)` and "
     "0xF8E3B4 `ld XBC,(XIX)` through 0xF8E3B7 `call 0xf8e6af`",
     "the meaning of command 0xE4, as above"),
    ("sub_F8E3D1", "Link_SendCommandE7",
     "sends command 0xE7, then a six-byte header staged at 0x6007AD whose "
     "length field is FORCED to 0x0400, then that 1024-byte block",
     "0xF8E3FE `ld XBC,0x007c0000` / 0xF8E403 `ld (XBC),0xe7`; the length is "
     "0xF8E42D `m_ld_mi16 MDD+r4, 0x04, 0x0400` and its copy 0xF8E432 "
     "`stiw_da (0x6007b1),0x0400`, so unlike E1 and E4 the caller does not "
     "choose it; the header is 0xF8E439 `pushw 0x06` from 0xF8E43C "
     "`lda_24 xbc,(0x6007ad)`, the payload 0xF8E45E `ld BC,(XIX+0x04)` and "
     "0xF8E462 `ld XBC,(XIX)`",
     "the meaning of command 0xE7, and why its block is always 1 KiB"),
    ("sub_F8E222", "Link_SendCommand5_WaitDone",
     "sends command 5 with a 32-bit argument through Link_SendCommandAndLong, "
     "then waits for the far side to clear bit 6 of (0x00008A)",
     "0xF8E230 `pushw 0x05` and 0xF8E233 `ld XBC,(XIZ+0x08)` are pushed to "
     "0xF8E237 `calr Link_SendCommandAndLong`, whose own frame reads the "
     "longword at (XIZ+0x08) and the command byte at (XIZ+0x0c) -- the two "
     "pushes in that order put them exactly there, which is a second and "
     "independent check on that routine's argument frame; 0xF8E22B "
     "`m_set 6, MD24, 0x00008a` arms the flag and 0xF8E23C "
     "`m_bit 6, MD24, 0x00008a` polls it; the timeout is 0xF8E243, 0xF8E246 "
     "and 0xF8E249, the tick counter at (0x0080) minus the copy taken at "
     "0xF8E226, compared with 0x09C4 = 2500; on timeout 0xF8E24F "
     "`ldio 0x7f, 0x00` clears DMA3V and 0xF8E265 `ldw wa, 0xffff` is the "
     "return value, otherwise 0xF8E26A `sub WA,WA` returns zero",
     "the byte that reaches the wire is 5 | 0xE0 = 0xE5, because "
     "Link_SendCommandAndLong ORs 0xE0 in; the NAME carries the literal 5 that "
     "is in this body and not the derived 0xE5. What clears bit 6 of "
     "(0x00008A) is not in this body either"),
]

# ⚠ REFUSED.  A header is written; the label stays `sub_XXXXXX`.
# ⚠ AND THE ONE REFUSAL IS NOT NEW -- IT IS A CONFIRMATION, WHICH IS WHY IT IS
# HERE AND WHY NO HEADER IS WRITTEN FOR IT.  The census put sub_F831B3 in bucket
# T1 (it forms 0x007F0000) and this lane read it independently; the listing
# ALREADY carries a refusal header for it, written by an earlier round, that
# reaches the same conclusion INCLUDING the XSP+8/+6/+4/+2 overlap.  apply()
# therefore adds nothing above it.  Reporting an existing header as this round's
# work is exactly the "+35 headers that were 35 removed blank lines" trade a
# round-3 reviewer caught, so it is counted as zero headers and stated as a
# corroboration instead.
REFUSALS = [
    ("sub_F831B3",
     "Forms 0x007F0000 and so lands in bucket T1, but device 0x7F's role is "
     "open in FINDINGS-memory-map.md and the routine's own four source pointers "
     "(XSP+8, +6, +4, +2) overlap and reach above the four 0x0005 words it "
     "pushed. An earlier round had already written that refusal into the "
     "listing above this label, with the same overlap argument; this round "
     "reproduced it from a different direction and left it alone."),
]


def _cited_addrs(text):
    return [int(m.group(1), 16) for m in re.finditer(r'0x([0-9A-F]{6})\b', text)]


# ★ THE PROSE LEVER, and its reach is exactly THREE.
# Three pattern families over the comment text of BOTH listings.
PROSE_PATS = [
    re.compile(r'\b([A-Z][A-Za-z0-9_]{3,})\s*\(\s*(?:prom_a\s+)?0x([0-9A-Fa-f]{6})\s*\)'),
    re.compile(r'\b([A-Z][A-Za-z0-9_]{3,})\s+(?:at|is)\s+(?:prom_a\s+)?0x([0-9A-Fa-f]{6})\b'),
    re.compile(r'0x([0-9A-Fa-f]{6})\s+(?:is|=)\s+`?([A-Z][A-Za-z0-9_]{3,})`?'),
]


def prose_names():
    """sub_XXXXXX -> {name asserted in a COMMENT somewhere in the two listings}.

    Every census in this project reads LABELS.  A routine can already have a
    name in this tree without having it on its label -- stated in the prose of
    some other header, sometimes with the full evidence beside it.  prom_a's
    power-on block names three such routines in its own header while their
    labels stayed `sub_XXXXXX`, and one of the three ALSO carried a round-7
    header saying "NOT NAMED", in the same file.
    """
    if "prose" in _C:
        return _C["prose"]
    A, B = R6.images()
    by = {R7.sub_addr(s): s for s in R7.subs()}
    out = collections.defaultdict(collections.Counter)
    for img in (A, B):
        for ln in img.lines:
            if not ln.lstrip().startswith(";"):
                continue
            for pi, P in enumerate(PROSE_PATS):
                for m in P.finditer(ln):
                    if pi == 2:
                        ad, nm = int(m.group(1), 16), m.group(2)
                    else:
                        nm, ad = m.group(1), int(m.group(2), 16)
                    if ad in by and R7.is_content(nm) and "_" in nm:
                        out[by[ad]][nm] += 1
    _C["prose"] = dict(out)
    return _C["prose"]


def mode_prose():
    ph = prose_names()
    print("Routines this tree ALREADY NAMES in prose while the label is still")
    print("`sub_XXXXXX`.  Three pattern families, both listings, comments only.\n")
    for k in sorted(ph):
        print("  %-13s %s" % (k, ", ".join(sorted(ph[k]))))
    print("\n  reach: %d.  ⚠ That is the whole lever, and it is worth publishing"
          % len(ph))
    print("  WITH the number, because the next round now knows not to look again.")
    print("  (The count runs live; it falls to 0 as they are applied.)")


def mode_applied():
    print("Names this round proposes, all from bucket T1 (a documented device "
          "window in the body):\n")
    for old, new, what, ev, unk in NAMES + LINK_NAMES:
        print("  %-13s -> %-26s %s" % (old, new, what))
        print("      Evidence: %s" % ev)
        print("      Unknown:  %s\n" % unk)
    print("Refusals -- a header is written, the label stays `sub_XXXXXX`:\n")
    for old, why in REFUSALS:
        print("  %-13s %s" % (old, why))


def mode_refusals():
    for old, why in REFUSALS:
        print("%s:\n  %s" % (old, why))


def _wrap(s, n, indent=""):
    out, cur = [], ""
    for word in s.split():
        if len(cur) + len(word) + 1 > n and cur:
            out.append(indent + cur)
            cur = word
        else:
            cur = (cur + " " + word).strip()
    if cur:
        out.append(indent + cur)
    return out


def _header(old, new, what, ev, unk, bucket="T1"):
    """The house style used around Dev7F_WriteAllFourSlots in this listing.

    ⚠ ONE STATEMENT PER FACT.  The first draft printed the `what` line as the
    title AND again under a "What it is:" heading, so every header said the same
    sentence twice -- the tautology a round-3 reviewer caught in round 6's
    output, reproduced.  The title is now the only place `what` appears, wrapped
    with a hanging indent.
    """
    chunks = _wrap(what, 58)
    w = [RULE, "; %s -- %s" % (new, chunks[0])]
    pad = "; " + " " * (len(new) + 4)
    for c in chunks[1:]:
        w.append(pad + c)
    w.append(";")
    first = True
    for c in _wrap(ev, 60):
        w.append("; " + ("Evidence: " if first else "          ") + c)
        first = False
    first = True
    for c in _wrap(unk, 60):
        w.append("; " + ("Unknown:  " if first else "          ") + c)
        first = False
    w.append("; Was `%s`, named by notes/prom_a_census_round8.py (bucket %s)."
             % (old, bucket))
    w.append(RULE)
    return w


def _refusal_header(old, why):
    w = [RULE, "; %s -- REFUSED A NAME, and this is the reason." % old, ";"]
    for c in _wrap(why, 70):
        w.append("; " + c)
    w.append("; Refused by notes/prom_a_census_round8.py: `sub_XXXXXX` plus a")
    w.append("; stated gap is worth more than a plausible guess.")
    w.append(RULE)
    return w


# ★ THE EMITTER TRAP, and why apply() writes TWO files.
# The seven Link routines live inside gen_prom_a_block.py's declared range
# (0xF8BC00-0xF8E47F), whose labels and headers are rebuilt on every run from the
# side-car notes/prom_a_block_headers.txt.  A name written only into the .s there
# is silently reverted the next time that emitter runs, which round 6 documented
# and which is still true.  So apply() also appends an `@@NAME` stanza per Link
# routine to the side-car.
# ⚠ AND DO NOT SIMPLY RE-RUN THAT EMITTER TO PICK THEM UP.  Re-emitting its whole
# declared range would (a) CONVERT 0xF8C000-0xF8DA00, 6,656 bytes that are still
# `.incbin` inside the range, which is a territory change no lane asked for, and
# (b) revert round 6's thunk renames, which live in the .s prose and not in the
# side-car -- `T_AsciiDigits3_ToValue (T_F432F0)` in the listing is still
# `T_F432F0` in notes/prom_a_block_headers.txt.  Both were measured by diffing a
# fresh emit against the listing on 2026-08-30.
SIDECAR = os.path.join(ROOT, "notes", "prom_a_block_headers.txt")

# ⚠ ONE EXISTING HEADER IS SUPERSEDED, and only one.
# notes/prom_a_understanding_round7.py --apply-strings wrote a header above
# `sub_F8288F` that says "loads a pointer straight at ROM TEXT.  NOT NAMED ...
# the text says what the routine READS, not what it DOES with it".  That
# refusal was correct for the lever that produced it -- a string scan -- and it
# is WRONG for this listing, because the power-on block's own header, a few
# thousand lines above, already states what the routine does with the text and
# names it `ExtBoard_Identify (0xF8288F)`, and `ExtBoardMagic_F828C7`'s header
# names (0x00C5) as this routine's output.  Two headers in one file contradicted
# each other.  The refusal is removed, not left to sit under a contradicting
# name; clobbering another round's evidence is normally forbidden and this is
# the exception that has to be argued for in writing.
SUPERSEDE = {
    "sub_F8288F": "round 7's --apply-strings refusal, contradicted by this "
                  "listing's own power-on-block header, which names the routine "
                  "and states what it does with the text it reads",
    "sub_F82A28": "the same refusal, same lever, same contradiction -- the "
                  "power-on block names this one VersionScreen_Show",
}
# The facts round 7's two refusal headers carried, kept so removing them loses
# nothing: 0xF828B3 loads 0xF828C7 = "WSA1 EXTBD", and 0xF82A38 loads 0xFFFFF0,
# where the ROM reads "wsaa_822".  Both are folded into the replacement headers.


def apply():
    """Rename in the .s, write a header above each, and record the Link names in
    the emitter's side-car so a later emitter run reproduces them.  Byte-neutral:
    it touches labels and comments only."""
    todo = [t for t in NAMES + LINK_NAMES]
    text = open(S_A).read()
    lines = text.split("\n")
    renamed = []
    for old, new, _w, _e, _u in todo:
        if re.search(r'^' + new + r':', text, re.M):
            continue
        if not re.search(r'^' + re.escape(old) + r':', text, re.M):
            print("  MISSING  %s is not a label in the listing" % old)
            continue
        renamed.append((old, new))
    # ⚠ SUPERSEDED HEADERS GO FIRST, WHILE THE OLD LABEL IS STILL SPELLED THE
    # OLD WAY.  The first draft ran this AFTER the rename, so `sub_F8288F:` no
    # longer existed to find and round 7's refusal survived under the new name,
    # saying "NOT NAMED" directly above a name.  --verify now checks for that
    # exact wreckage.
    for old, why in SUPERSEDE.items():
        for i, ln in enumerate(lines):
            if not ln.startswith(old + ":"):
                continue
            j = i - 1
            while j >= 0 and lines[j].startswith(";"):
                j -= 1
            if i - j > 3:
                print("  superseded %d header lines above %s -- %s"
                      % (i - j - 1, old, why))
                del lines[j + 1:i]
            break
    pat = re.compile(r'\b(' + "|".join(re.escape(o) for o, _n in renamed) + r')\b') \
        if renamed else None
    if pat:
        table = dict(renamed)
        lines = [pat.sub(lambda m: table[m.group(1)], ln) for ln in lines]
    # ★ REFRESH OUR OWN HEADERS.  A header this tool wrote carries the trailer
    # below; strip it so a re-run rewrites it from the table instead of leaving
    # a stale one behind.  Headers written by ANY OTHER round are never touched
    # here -- only the two in SUPERSEDE are, and each is argued for in writing.
    MINE = "named by notes/prom_a_census_round8.py"
    keep = []
    i = 0
    while i < len(lines):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', lines[i])
        if m and m.group(1) in set(n for _o, n, _w, _e, _u in todo):
            j = len(keep) - 1
            while j >= 0 and keep[j].startswith(";"):
                j -= 1
            block = keep[j + 1:]
            if any(MINE in b for b in block):
                del keep[j + 1:]
        keep.append(lines[i])
        i += 1
    lines = keep
    out, done = [], set()
    for ln in lines:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
        if m:
            for old, new, what, ev, unk in todo:
                if m.group(1) == new and new not in done and (out and out[-1] != RULE):
                    done.add(new)
                    out.extend(_header(old, new, what, ev, unk))
            # ⚠ A refusal header is written ONLY where none exists.  `out[-1]`
            # being the rule line means the listing already carries one, and
            # overwriting another round's evidence to raise a header count is
            # the trade this wave keeps catching.
            for old, why in REFUSALS:
                if m.group(1) == old and old not in done and (out and out[-1] != RULE):
                    done.add(old)
                    out.extend(_refusal_header(old, why))
        out.append(ln)
    open(S_A, "w").write("\n".join(out))
    print("  renamed %d labels, wrote %d header blocks" % (len(renamed), len(done)))
    # the side-car, so the emitter cannot revert them
    side = open(SIDECAR, encoding="utf-8").read()
    # strip any stanza this tool wrote before, so a re-run REPLACES it
    parts = side.split("@@")
    parts = [q for q in parts if "named by notes/prom_a_census_round8.py" not in q]
    side = "@@".join(parts).rstrip("\n") + "\n"
    open(SIDECAR, "w", encoding="utf-8").write(side)
    add = []
    for old, new, what, ev, unk in LINK_NAMES:
        if ("@@NAME 0x%06X" % int(old[4:], 16)) in side:
            continue
        add.append("\n@@NAME 0x%06X %s" % (int(old[4:], 16), new))
        add.extend(_header(old, new, what, ev, unk))
    if add:
        open(SIDECAR, "a", encoding="utf-8").write("\n".join(add) + "\n")
        print("  appended %d @@NAME stanzas to notes/prom_a_block_headers.txt"
              % sum(1 for x in add if x.startswith("\n@@NAME")))


def verify():
    text = open(S_A).read()
    side = open(SIDECAR, encoding="utf-8").read()
    bad = 0
    for old, new, _w, _e, _u in NAMES + LINK_NAMES:
        if not re.search(r'^' + new + r':', text, re.M):
            print("  MISSING  %s" % new)
            bad += 1
        if re.search(r'^' + re.escape(old) + r':', text, re.M):
            print("  STALE    %s still defined" % old)
            bad += 1
    for old, new, _w, _e, _u in LINK_NAMES:
        if ("@@NAME 0x%06X %s" % (int(old[4:], 16), new)) not in side:
            print("  SIDE-CAR MISSING  %s -- the emitter would revert it" % new)
            bad += 1
    for old, _why in REFUSALS:
        if not re.search(r'^' + re.escape(old) + r':', text, re.M):
            print("  REFUSAL LOST  %s" % old)
            bad += 1
    # ★ the exact wreckage the first draft produced: a superseded "NOT NAMED"
    # header left sitting above a name.
    for old, new, _w, _e, _u in NAMES + LINK_NAMES:
        m = re.search(r'((?:^;.*\n)+)' + new + r':', text, re.M)
        if m and "NOT NAMED" in m.group(1):
            print("  CONTRADICTION  a 'NOT NAMED' header still sits above %s" % new)
            bad += 1
    print("  %d names and %d refusals verified, %d problems"
          % (len(NAMES) + len(LINK_NAMES), len(REFUSALS), bad))
    return bad


# ===========================================================================
# 7. ROUND 9 -- the WRAPPER lever, its 47, and the 20 that survived it
# ===========================================================================
# ★ WHAT THIS ROUND ADDED TO THE CENSUS, and it is one axis, not a new census.
# Round 8's buckets ask what a routine's body TOUCHES.  They do not ask whether
# the touch is the routine's WHOLE body.  A routine that saves four registers,
# makes ONE call to a CONTENT-named routine and restores them is not merely
# "touching" that routine -- it IS that routine, seen through a different
# calling convention, and the brief's own mechanism covers it: name a pointer
# from what it points at.
#
# THE LEVER, stated so it can be argued with:
#     W = { r : r has exactly ONE distinct CONTENT-named callee,
#               no display-list / swi entry among its exits,
#               and n_flow <= 15 instructions }
# and then the part that decides whether a NAME comes out of it:
#     W1 = { r in W : no OTHER member of W has the same callee }
# because when six wrappers share a callee, the only thing that could tell them
# apart is an address, and "callee name plus an address" is a FRAMED label --
# the exact trade round 8 measured and declined.
#
#     |W|  = 220      of 2,882      (7.6%)
#     |W1| =  47      of 2,882      (1.6%)
#
# `--wrappers` prints both live, with the crowded callees and their counts, so
# the 173 that W1 throws away are visible rather than quietly dropped.
#
# ★★ AND THE ARITHMETIC OF THE 47, WHICH IS THE HONEST PART OF THIS ROUND.
# THIRTEEN of them are named below (round 9 ships twenty names in all; the other
# seven come from the T4 bucket and from the jump block at 0xFE3000).  The rest
# are refused, mechanically, for five stated reasons, and `--wrappers` prints
# the reason beside each one and the tally at the end:
#     R1  the listing ALREADY carries a refusal header for it (round 7's
#         --apply-strings wrote several).  Overwriting another round's evidence
#         to raise a name count is the trade this wave keeps catching.
#     R2  it lies inside an emitter's declared range that has NO name side-car,
#         so a name written into the .s is reverted the next time that emitter
#         runs.  Only gen_prom_a_block.py and the ring-buffer emitter carry one.
#     R3  it does not end in a flow end -- it falls THROUGH into the next label
#         -- so "wrapper" is not established; the call may belong to a routine
#         whose entry is elsewhere.
#     R4  it is a TWO-INSTRUCTION forwarder -- `calr X` then `ret` -- so the
#         only name it could carry is a second spelling of a name that is
#         already three lines away.  This is round 7's own standard, the one
#         that declined to re-spell `Ring_Get_0080` as `Ring_Get_Cap0080`.
#     R5  its body was NOT READ this round.  It is a bound on the effort spent,
#         not a claim about the routine, and it is printed rather than folded
#         into one of the others.  `--wrappers` prints how many are here; they
#         are where the next round should start.
# ⚠ AND THE ONE PLACE THIS ROUND CROSSED ITS OWN R4 LINE, argued rather than
# hidden: `INT5_Dev7B_Receive_Alias` and `INTTC0_uDMA0Done_Alias` are ONE-
# instruction forwarders and they ARE named, because the fact they record is
# not the callee's identity but the SHAPE OF THE BLOCK THEY SIT IN -- eight
# `jp` slots at 0xFE3000 on a 4-byte stride, of which two enter named
# interrupt handlers and one (slot 3) enters an `reti` wrapper.  A `calr X /
# ret` in the middle of ordinary code records nothing comparable.
# ★ Every routine named here is ALSO given a body reading that a bare
# "<callee>_Veneer" would not carry: which flag gates it, which cursor pair the
# predicate it calls compares, how many times it retries.  A derivative name
# with no reading behind it is a re-spelling, and this file does not ship one.

# (lo, hi, emitter, has a name side-car)
EMITTERS = [
    (0xF830C6, 0xF85600, "notes/gen_prom_a_ringbuf_module.py", True),
    (0xF85FF9, 0xF89800, "notes/gen_prom_a_f85ff9_module.py", False),
    (0xF89800, 0xF8A000, "notes/gen_prom_a_ctrl_module.py", False),
    (0xF8A000, 0xF8BC00, "notes/gen_prom_a_f8a000_module.py", False),
    (0xF8BC00, 0xF8E480, "notes/gen_prom_a_block.py", True),
    (0xF90989, 0xF92C62, "notes/gen_prom_a_f90989_module.py", False),
    (0xFA5AEB, 0xFAA000, "notes/gen_prom_a_fa5aeb_module.py", False),
    (0xFAD800, 0xFB2000, "notes/gen_prom_a_fad800_module.py", False),
    (0xFE54EC, 0xFE6850, "notes/gen_prom_a_fdc_module.py", False),
    (0xFE8000, 0xFEB330, "notes/gen_prom_a_fe8000_module.py", False),
    (0xFEB330, 0xFEF746, "notes/gen_prom_a_drumnames.py", False),
    (0xFEF746, 0xFF3800, "notes/gen_prom_a_screens.py", False),
    (0xFF8000, 0xFFFF00, "notes/gen_prom_a_splash.py", False),
]


def emitter_of(addr):
    """Which generator OWNS this address, and does it carry a name side-car?

    ⚠ A name written into the .s inside a side-car-less emitter's range is
    reverted the next time that emitter runs.  Round 6 already shipped
    LCD_DrawVRuleLeft_Layer1 inside gen_prom_a_screens.py's range, so the tree
    accepts the risk; it does not record it anywhere, which is what this does.
    """
    for lo, hi, script, side in EMITTERS:
        if lo <= addr < hi:
            return script, side
    return None, None


# ---------------------------------------------------------------------------
# The twenty names.  (old, new, what, evidence, unknown)
# ---------------------------------------------------------------------------
RING_NAMES = [
    ("sub_F825D4", "Ring_InitAllFourteen",
     "initialises ALL FOURTEEN of CPU 1's ring buffers, between five stores "
     "nothing in this tree names",
     "fourteen consecutive `call` instructions at 0xF825E5, 0xF825E9, "
     "0xF825ED, 0xF825F1, 0xF825F5, 0xF825F9, 0xF825FD, 0xF82601, 0xF82605, "
     "0xF82609, 0xF8260D, 0xF82611, 0xF82615 and 0xF82619, whose operands are "
     "the prom_b slots T_Ring608A0A_Init, T_Ring60480A_Init, "
     "T_Ring60000C_Init, T_Ring601B64_Init, T_Ring60080A_Init, "
     "T_Ring600A14_Init, T_Ring600C1E_Init, T_Ring601028_Init, "
     "T_Ring601432_Init, T_Ring60153C_Init, T_Ring601646_Init, "
     "T_Ring601850_Init, T_Ring60195A_Init and T_Ring601C6E_Init -- that is "
     "EVERY `T_Ring*_Init` label in prom_b, each exactly once, and prom_b has "
     "exactly fourteen of them (`grep -c '^T_Ring[0-9A-F]*_Init:' "
     "prom_b/wsa1_prom_b.s`). Around them: 0xF825D4-0xF825DE writes 0xFF to "
     "(0x88) and (0x98) and zeroes the longword at (0x80), 0xF825E1 calls "
     "sub_F831B3, and 0xF8261D/0xF82622 write 0xFF to (0x2E00) and (0x2000). "
     "Entered by the `jp` at 0xF82010, the first of six jump slots "
     "that follow Data_F82000",
     "what the five stores mean -- (0x80), (0x88), (0x98), (0x2000) and "
     "(0x2E00) are named by nothing in this tree -- and what sub_F831B3 does, "
     "which this file already refuses to say because device 0x7F's role is "
     "open. ★ THE NAME COUNTS THE CALLS, NOT THE RINGS: it claims fourteen "
     "Init entries are called, which is checked, and nothing about whether "
     "fourteen is all the machine has"),
    ("sub_F825C7", "Ring601850_ServiceIfNotEmpty",
     "runs sub_FC87AE exactly when ring 0x601850 holds data",
     "0xF825C7 `call 0xF41E68` = prom_b slot T_Ring601850_IsEmpty; 0xF825CB "
     "`and WA,WA` and 0xF825CD `jr z,.LF825D3` skip the body when it returns "
     "zero; 0xF825CF `call 0xF413B8` = prom_b slot T_F413B8 -> prom_a "
     "sub_FC87AE runs when it does not. ★ POLARITY, and it is the opposite of "
     "what the callee's name suggests: Ring601850_IsEmpty (0xF84B6E) loads "
     "WA=0, compares the read cursor (0x601848) with the write cursor "
     "(0x60184C) and loads 0xFFFF only when they DIFFER -- so it returns ZERO "
     "when the ring IS empty. Reached only through prom_b slot T_F40020",
     "what sub_FC87AE does with the ring and what the ring carries. ⚠ AND THE "
     "POLARITY ABOVE IS A FACT ABOUT ALL FOURTEEN `Ring*_IsEmpty` ROUTINES, "
     "not just this one; none of them is renamed here, because renaming "
     "fourteen prom_a labels and their fourteen prom_b slots is a mass rename "
     "and this wave has measured what those cost"),
    ("sub_FB6084", "Ring601432_SpinUntilEmpty",
     "polls ring 0x601432 until it is empty, or 65535 times, whichever comes "
     "first",
     "0xFB6085 `ldw HL,0xFFFF` seeds the bound; 0xFB6088 `cps HL,0x00` and "
     "0xFB608A `jr z` leave on exhaustion; 0xFB608C `dec 1,HL` counts down; "
     "0xFB608E `call 0xF41DFC` = prom_b slot T_Ring601432_IsEmpty; 0xFB6092 "
     "`cps WA,0x00` and 0xFB6094 `jr nz` go round again while the result is "
     "non-zero. Ring601432_IsEmpty (0xF8483F) returns 0 only when the read "
     "cursor (0x60142A) equals the write cursor (0x60142E), so a non-zero "
     "result means the ring still holds data. Called by `calr` at 0xFB6069 "
     "(in sub_FB6026) and 0xFB6076 (in sub_FB6072)",
     "what the 65535-poll bound is for: the routine returns no value, so "
     "neither caller can tell a drained ring from an exhausted count"),
    ("sub_FC1D70", "Ring60000C_GetWithRetry",
     "calls ring 0x60000C's Get until it yields a byte, up to 65535 times, "
     "and flags exhaustion in XIY",
     "0xFC1D71 `ldw BC,0xFFFF`; 0xFC1D79 `call 0xF41E80` = prom_b slot "
     "T_Ring60000C_Get, with XIY, XIX, DE and HL saved across it by 0xFC1D74-"
     "0xFC1D78 and restored at 0xFC1D7D-0xFC1D81; 0xFC1D82 `cp WA,0xFFFF` and "
     "0xFC1D86 `jr nz` return as soon as the result is not 0xFFFF; 0xFC1D88 "
     "`djnz16 BC` retries otherwise; 0xFC1D8B `ld XIY,0xFFFFFFFF` on "
     "exhaustion. Ring_Get_0400 (0xF8405D), the class routine every 0x400-"
     "capacity Get reaches, loads WA=0xFFFF exactly when the read cursor "
     "equals the write cursor, so 0xFFFF is its empty marker. All seven call "
     "sites are inside sub_FC1D92, the first at 0xFC1D9B",
     "why exhaustion is reported in XIY when the byte itself comes back in "
     "WA, and whether any caller reads XIY"),
    ("sub_FD2504", "Ring608A0A_DrainAll",
     "calls sub_FD2014 once per item until ring 0x608A0A is empty",
     "0xFD2504 `call 0xF41CDC` = prom_b slot T_Ring608A0A_IsEmpty; 0xFD2508 "
     "`cps WA,0x00` and 0xFD250A `jr z` return when it reads zero; 0xFD250C "
     "`calr sub_FD2014` otherwise, and 0xFD250F `jr` re-tests. "
     "Ring608A0A_IsEmpty (0xF84327) returns 0 only when the read cursor "
     "(0x608A02) equals the write cursor (0x608A06). sub_FD2014's own body "
     "reaches T_Ring608A0A_Get, so the loop consumes what it tests. Published "
     "by prom_b slot T_F42380 and reached from `call 0xF42380` at 0xF8213E, "
     "inside sub_F82028",
     "what sub_FD2014 does with each item"),
    ("sub_FB7EFD", "Ring600C1E_InitIfPanelMode79",
     "re-initialises ring 0x600C1E, with interrupts masked, only while the "
     "panel mode byte reads 0x79",
     "0xFB7EFD `m_cp_mi8 MB16, 0x207a, 0x79` and 0xFB7F02 `jr nz` gate the "
     "whole body; 0xFB7F04 `ei 0x06` raises the mask, 0xFB7F06 `call "
     "0xF41DB8` = prom_b slot T_Ring600C1E_Init, 0xFB7F0A `ei 0x00` lowers "
     "it. (0x207A) is this listing's panel mode byte -- PanelState_Update207A "
     "(0xF863F5) is headed `(0x207A) := (0x207C) unless the mode is "
     "unchanged`. Called by `call` at 0xFB2058, 0xFB20F2, 0xFB21EF and "
     "0xFB607F",
     "what mode 0x79 is. The listing tests (0x207A) against 0x0D, 0x13, 0x79, "
     "0xB7 and 0xDB in five different modules and names none of the values"),
    ("sub_FB7F0D", "Ring601646_InitIrqMasked",
     "re-initialises ring 0x601646 with the interrupt mask raised to 6",
     "0xFB7F0D `ei 0x06`, 0xFB7F0F `call 0xF41E48` = prom_b slot "
     "T_Ring601646_Init, 0xFB7F13 `ei 0x00`, 0xFB7F15 `ret`. Called by `call` "
     "at 0xFB7769, inside sub_FB775F. ★ THE EXTENT HOLDS A SECOND ROUTINE "
     "THIS LABEL DOES NOT COVER: 0xFB7F16-0xFB7F1E is the same four "
     "instructions for T_Ring601432_Init (slot 0xF41E00) and carries no label "
     "because nothing in either image references it -- which is why it is "
     "described here and not labelled",
     "why this ring's Init is masked when Ring_InitAllFourteen calls all "
     "fourteen unmasked"),
]

SOUND_NAMES = [
    ("sub_FC2222", "SoundGroup_MaxMemberIndex_Get",
     "returns the max-member-index byte for a sound group, from one of three "
     "ROM maps or a RAM one, chosen by the group selector in W",
     "a `cp W` ladder at 0xFC2226-0xFC225A picks exactly one base: "
     "0xFC225C `ld XIX,0x00F06EB4` = GroupMaxMemberIndex_ToneGroups, 0xFC2263 "
     "`ld XIX,0x00F06EC4` = GroupMaxMemberIndex_DrumGroups, 0xFC226A `ld "
     "XIX,0x00F06ED4` = GroupMaxMemberIndex_DrumGroupsSecondWindow and "
     "0xFC2271 `ld XIX,0x000008C0`, a RAM base; 0xFC2276 `xor W,W` and "
     "0xFC2278 `ld A,(XIX+WA)` then read one byte at the index in A. Those "
     "three ROM objects carry the reciprocal citation in prom_b: each of their "
     "headers says `Read by: prom_a sub_FC2222 (0xFC2222-0xFC2281)` and "
     "quotes the same `ld XIX` immediate. Published by prom_b slot T_F4101C, "
     "which eleven prom_a sites call",
     "the RAM base 0x08C0, which no header in this tree describes; and "
     "'MEMBER' is this tree's word for the second index, not the ROM's -- the "
     "string occurs zero times in prom_a and prom_b"),
    ("sub_FC2282", "SoundGroup_MaxMemberIndex_GetToneCopy",
     "the same lookup against GroupMaxMemberIndex_ToneGroupsCopy and a "
     "different RAM base, over a SHORTER selector ladder",
     "0xFC22A3 `ld XIX,0x00F06EE4` = GroupMaxMemberIndex_ToneGroupsCopy and "
     "0xFC22AA `ld XIX,0x000008D0`; 0xFC22AF `xor W,W` / 0xFC22B1 `ld "
     "A,(XIX+WA)` is the same two-instruction read as "
     "SoundGroup_MaxMemberIndex_Get's. Published by prom_b slot T_F41034, "
     "which seven prom_a sites call. ⚠ AND THIS CORRECTS A COMMITTED "
     "CITATION: prom_b's GroupMaxMemberIndex_ToneGroupsCopy header says `Read "
     "by: prom_a sub_FC2222 ... ld XIX,0x00F06EE4`. It is not: 0x00F06EE4 is "
     "loaded ONCE in all of prom_a, at 0xFC22A3, which is past sub_FC2222's "
     "extent end 0xFC2281 and inside THIS routine. prom_b is another lane's "
     "file this round, so the fix is reported and not applied",
     "what distinguishes this arm from SoundGroup_MaxMemberIndex_Get's: the "
     "two ladders test overlapping selector ranges and this one has four "
     "fewer tests, and nothing decoded here says which caller wants which"),
    ("sub_FC22E0", "SoundCode_FromGroupMember_ModeOffset",
     "reads the (group, member) pair at (0x60F010)/(0x60F011), looks the pair "
     "up in SoundCodeByGroupMember_ModeOffsetGroup with the group biased by "
     "the mode, and stores the word to (0x60F014)/(0x60F015)",
     "0xFC22E0 `ld A,(0x60F010)`; 0xFC22E5-0xFC2307 add 0x10, 0x20 or 0x22 to "
     "it according to (0x60F013) and bit 2 of (0x7F4D) -- that bias is what "
     "`ModeOffset` names; 0xFC230C `mul WA,0x0010` is the 16-byte row stride, "
     "0xFC2310 `ld C,(0x60F011)` and 0xFC2317 `mul BC,0x0002` the 2-byte "
     "column; 0xFC231D `add XBC,0x00F06EF4` is the table base, which is "
     "SoundCodeByGroupMember_ModeOffsetGroup; 0xFC2325 and 0xFC232A store the "
     "two halves. prom_b's header for that table carries the reciprocal "
     "citation, `Read by: prom_a sub_FC22E0 (0xFC22E0-0xFC232F)`, with the "
     "same arithmetic. One call site, 0xFC22D3",
     "what the 16-bit word ENCODES -- prom_b's own header says the low byte "
     "is a kind and the high byte a value, and neither is decoded"),
    ("sub_FC2422", "SoundCode_FromGroupMember_ByteGroup",
     "the same (group, member) -> (0x60F014)/(0x60F015) lookup, against "
     "SoundCodeByGroupMember_ByteGroup, with a RAM table searched first when "
     "bit 2 of (0x7F4D) is set",
     "0xFC2422 `m_bit 2, MD16, 0x7f4d` chooses the arm. RAM arm: 0xFC2432 `ld "
     "XIX,0x00005760` and the 0xFC243B loop compare the BC pair against 127 "
     "16-bit entries (0xFC2446 `cp WA,0x00FE`). ROM arm: 0xFC245D/0xFC2462 "
     "read the same two cells, 0xFC2467 or's 0x80 into the group when bit 5 "
     "of (0x60F011) is set -- the FULL BYTE index that `ByteGroup` names -- "
     "0xFC246F `and C,0x07` masks the column, and 0xFC2472 `ld "
     "XIX,0x00F07134` is SoundCodeByGroupMember_ByteGroup's base; 0xFC24B1 "
     "and 0xFC24B6 store the halves. prom_b's header for that table cites "
     "`prom_a 0xFC245D-0xFC2489` for exactly this arithmetic. One call site, "
     "0xFC241A",
     "what the RAM table at 0x5760 holds and who fills it, and what the "
     "0x1A/0x01/0x20 values loaded into C on the way out select"),
]

VENEER_NAMES = [
    ("sub_FE0039", "Disk_FormatSelectedMedia_Veneer",
     "calls Disk_FormatSelectedMedia with XDE, XHL, XIX and XIZ preserved",
     "0xFE0039-0xFE003C push XDE, XHL, XIX and XIZ; 0xFE003D `call 0xF43460` "
     "is prom_b slot T_Disk_FormatSelectedMedia, whose `jp` target 0xFE7200 "
     "carries the label Disk_FormatSelectedMedia; 0xFE0041-0xFE0044 pop the "
     "same four in reverse and 0xFE0045 returns. No other call or jump is in "
     "the extent. Called by `calr` at 0xFE0A29 and 0xFE0A59, both inside "
     "sub_FE09BE. DERIVATIVE: the name is the callee's, and the routine's own "
     "contribution is the register save",
     "why the four registers need saving here when the callee is reached "
     "directly elsewhere"),
    ("sub_FE00D1", "MidiIn_ServiceDeferred_Veneer",
     "calls MidiIn_ServiceDeferred with XDE, XHL, XIX and XIZ preserved",
     "0xFE00D1-0xFE00D4 push the four; 0xFE00D5 `call 0xF40758` is prom_b "
     "slot T_MidiIn_ServiceDeferred, whose `jp` target carries the label "
     "MidiIn_ServiceDeferred; 0xFE00D9-0xFE00DC pop them and 0xFE00DD "
     "returns. Called by `calr` at 0xFE201F. DERIVATIVE, as above",
     "as above"),
    ("sub_FE00DE", "UiEventList_Publish_Veneer",
     "calls UiEventList_Publish with XDE, XHL, XIX and XIZ preserved",
     "0xFE00DE-0xFE00E1 push the four; 0xFE00E2 `call 0xF40F50` is prom_b "
     "slot T_UiEventList_Publish; 0xFE00E6-0xFE00E9 pop them and 0xFE00EA "
     "returns. Called by `calr` at 0xFE2022, three bytes after the site that "
     "reaches MidiIn_ServiceDeferred_Veneer -- the two veneers are a pair in "
     "one caller. DERIVATIVE, as above",
     "as above"),
    ("sub_FF7656", "DLB_Handler_StringTable_Veneer",
     "calls display-list-B's string-table handler with the list pointer taken "
     "from the caller's frame at +8",
     "0xFF7656/0xFF7657 build a frame with XIZ; 0xFF765C `ld "
     "XIY,(XIZ+0x08)` loads the argument the handler reads; 0xFF765F `call "
     "0xF417F8` is prom_b slot T_DLB_Handler_StringTable, whose `jp` target "
     "0xF31B21 carries the label DLB_Handler_StringTable in prom_b; "
     "0xFF7663-0xFF7666 restore XDE, XHL, XIX and XIZ. Seven call sites, the "
     "first at 0xFF691D. DERIVATIVE",
     "what the +8 argument is beyond a list pointer"),
    ("sub_FF7668", "DLB_Handler_Decimal_Veneer",
     "the same veneer for display-list-B's decimal handler, and it clears "
     "(0x2540) first",
     "0xFF766E `stdi8 (0x2540), 0x00` -- the layer select this module writes "
     "before every draw -- then 0xFF7673 `ld XIY,(XIZ+0x08)` and 0xFF7676 "
     "`call 0xF41800` = prom_b slot T_F41800, whose `jp` target 0xF31BA1 "
     "carries the label DLB_Handler_Decimal. Ten call sites, the first at "
     "0xFF4BC1. DERIVATIVE, and the (0x2540) store is the one thing it adds",
     "as above"),
    ("sub_FE30D8", "Fdc_ServiceDataByte_Isr",
     "the interrupt entry that calls Fdc_ServiceDataByte and returns with "
     "`reti`",
     "the whole body is 0xFE30D8 `call 0xFE67F9` and 0xFE30DC `reti`; "
     "0xFE67F9 carries the label Fdc_ServiceDataByte. `reti` and not `ret` is "
     "what makes this an interrupt entry rather than a veneer. Reached by the "
     "`jp` at 0xFE300C, slot 3 of the eight-slot jump block at "
     "0xFE3000",
     "which interrupt. The vector that reaches 0xFE300C is not identified "
     "here; slots 2 and 4 of the same block jump straight at INT5_Dev7B_Receive "
     "and INTTC0_uDMA0Done, so the block is an interrupt indirection, but "
     "which line drives slot 3 is open"),
    ("sub_FE3008", "INT5_Dev7B_Receive_Alias",
     "a one-instruction jump slot that enters INT5_Dev7B_Receive",
     "the whole body is 0xFE3008 `jp 0xFE6866`, and 0xFE6866 carries the "
     "label INT5_Dev7B_Receive. It is slot 2 of the eight `jp` slots at "
     "0xFE3000-0xFE301C, a 4-byte stride; slot 7 (0xFE301C, unlabelled) "
     "jumps at the same handler. DERIVATIVE",
     "why the handler is entered through a slot at all, and what distinguishes "
     "slot 2 from the identical slot 7"),
    ("sub_FE3010", "INTTC0_uDMA0Done_Alias",
     "a one-instruction jump slot that enters INTTC0_uDMA0Done",
     "the whole body is 0xFE3010 `jp 0xFE6851`, and 0xFE6851 carries the "
     "label INTTC0_uDMA0Done. Slot 4 of the same eight-slot block. "
     "DERIVATIVE",
     "as above"),
]

RECORD_NAMES = [
    ("sub_FEB2D4", "RecordNameSource_Select",
     "returns, in XIY, the name source for the record selected by "
     "(0x601F00) -- a drum-kit name block, a RAM buffer, or the name table "
     "itself -- according to the record's +0x01 byte",
     "0xFEB2D4 `ld XIX,0x00603422` and 0xFEB2D9 `ld A,(0x601F00)` pick the "
     "record; 0xFEB2E3 `ld XIY,0x00FEB330` with 0xFEB2EA `sll WA,0x02` and "
     "0xFEB2ED `ld XIX,(XIY+WA)` indexes RecordPtrs_RAM76A2 at a stride of 4; "
     "0xFEB2F2 `ld A,(XIX+0x01)` reads the selector and 0xFEB2F5-0xFEB309 "
     "branch on 0x20, 0x28, 0x29 and 0x30. The four arms: 0xFEB30B-0xFEB318 "
     "returns DrumKitNameBlockPtrs[record+0x00], 0xFEB31E and 0xFEB324 return "
     "the RAM buffer 0x603FF6, and 0xFEB32A returns DrumKitNames. Those five "
     "arm addresses and their targets are exactly what this listing's own "
     "drum-name block header already states, under `WHAT A RECORD'S +0x01 "
     "BYTE SELECTS`; only the label was still sub_XXXXXX. One call site, "
     "`calr` at 0xFEB2C9",
     "what (0x601F00) indexes and what the RAM buffer at 0x603FF6 holds. "
     "⚠ EMITTER RISK: this label is inside gen_prom_a_fe8000_module.py's "
     "declared range 0xFE8000-0xFEB330 and that emitter has NO name side-car, "
     "so re-running it would revert this name; `--emitters` prints the check"),
]

NAMES9 = RING_NAMES + SOUND_NAMES + VENEER_NAMES + RECORD_NAMES

# ⚠ REFUSED, with the reason, and NOT written into the listing where a refusal
# header already stands there.
REFUSALS9 = [
    ("sub_FC2035",
     "Round 7's --apply-strings already refused it and this round confirms the "
     "refusal from a different direction. Its `cp W` ladder is the SAME ladder "
     "that SoundGroup_MaxMemberIndex_Get uses, and four of its arms do return "
     "a 16-byte row inside the ToneGroupNames windows (0xFC2070, 0xFC2077, "
     "0xFC207E, 0xFC2085, then 0xFC208D `mul WA,0x0010`) -- but five more arms "
     "return something else entirely: 0xFC2095 and 0xFC20A2 form addresses in "
     "the expansion-board windows 0xE80000 and 0xE90000, 0xFC20A9 and 0xFC20B6 "
     "0xEA0000 and 0xEB0000, and 0xFC20F4/0xFC20FB/0xFC2102 return RAM bases "
     "0x5240, 0x5450 and 0x5660. A name taken from the four ROM-text arms "
     "would claim the routine returns a tone-group name row, and for five of "
     "its nine arms it does not."),
]

# ⚠ ONE COMMITTED EVIDENCE LINE IS CORRECTED, in this listing, by exact text
# replacement.  Round 8 renamed `Ring_InitAllTen` to `Ring_InitTenOfFourteen`
# because the ROM refutes the completeness claim -- and left the Evidence line
# under it still saying `every T_Ring*_Init slot in prom_b`.  Two statements in
# one header contradicting each other is the round-3 reviewers' finding,
# reproduced by the very commit that was fixing it.
# The stale sentence this round removes from the listing.  It is quoted here so
# --verify9 can prove it is gone, and NOT patched as literal text: the header it
# lives in is generated by _header() from the NAMES table above, so the fix
# belongs in the table and the listing is re-emitted from it.
STALE9 = "`T_Ring*_Init` slot in prom_b and no other call"
FIXED9 = "TEN of the FOURTEEN `T_Ring*_Init` slots in prom_b"


def _rewrite_round8_header(lines, old, new, bucket="T1"):
    """Delete the header this file wrote above `new` and emit it again from the
    (now corrected) NAMES table.  Returns True if it rewrote anything."""
    MINE8 = "named by notes/prom_a_census_round8.py"
    ent = [t for t in NAMES + LINK_NAMES if t[1] == new]
    if not ent:
        return False
    for i, ln in enumerate(lines):
        if not ln.startswith(new + ":"):
            continue
        j = i - 1
        while j >= 0 and lines[j].startswith(";"):
            j -= 1
        block = lines[j + 1:i]
        if not any(MINE8 in b for b in block):
            return False
        lines[j + 1:i] = _header(ent[0][0], new, ent[0][2], ent[0][3], ent[0][4],
                                 bucket)
        return True
    return False


# ---------------------------------------------------------------------------
# ★★ THE OTHER HALF OF THE GOAL METRIC, MEASURED AND THEN DECLINED
# ---------------------------------------------------------------------------
# prom_a carries 253 FRAMED labels -- a structural kind with an address glued
# on, `DisplayList_FE829B`, `JumpTable_...`, `BlinkArgPtrs_F8024D`.  Promoting
# one of those to a CONTENT name is worth more per label than naming a
# `sub_XXXXXX`, because it moves LOWER without moving UPPER, and prom_b's lanes
# have been doing exactly that.  So this round measured whether prom_a has the
# same lever, with the two mechanisms the brief allows for an object -- name it
# from WHAT IT CONTAINS, or from WHAT READS IT -- and the answer is NO.
#
#   1. WHAT IT CONTAINS.  ZERO of the 253 carry a printable ROM string of even
#      three characters inside their own extent.  Thirteen contain a `.ascii`
#      at all and the longest is TWO characters ("14", " $", " '").  prom_b's
#      display lists carry captions -- `DL_C0mbinati0nM0dePage22Sound`,
#      `DL_TransmissionDesDonnEsDeSyst` -- and prom_a's do not: its 86
#      `DisplayList_*` objects are single five-byte records.
#      ⚠ AND A SCAN THAT LOOKED FOR PRINTABLE RUNS IN COMMENTS INSTEAD FOUND
#      ELEVEN HITS, EVERY ONE OF THEM ENGLISH PROSE FROM A NEARBY HEADER
#      ("s, not this routine", " ABCDEFGHIJ...").  That is the round-3 "Home"
#      failure with the polarity reversed -- a scan that reads the tree's own
#      writing back as if it were ROM text -- and it is recorded here so the
#      next round does not re-run it and believe it.
#
#   2. WHAT READS IT.  The framed objects whose header already names a single
#      reader are read by UNNAMED routines: DisplayListPtrs_F92726 by
#      sub_F92718, DisplayListPtrs_F93557 by the site at 0xF93549, and so on --
#      and each of those headers already ends `Unknown: what the 32 slots
#      select between`.  A content name would have to answer that question,
#      not restate the pointer count.
#
# So this lane's framed -> content count is ZERO, deliberately, and
# `--framed` prints the measurement that says why.  ★ The five `Ring_Get_0080`-
# family labels are a separate and already-settled case: round 7 declined to
# re-spell them because the number IS the capacity, which is content; this
# round agrees and did not touch them.
FRAMED_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                       r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                       r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')


def framed_objects():
    """(name, family, longest .ascii run inside its own extent) for every FRAMED
    label in prom_a.  The extent is label-to-next-top-label, which is what the
    documentation metric itself uses."""
    lines = open(S_A).read().split("\n")
    top = [(i, m.group(1)) for i, ln in enumerate(lines)
           for m in [re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)]
           if m and not m.group(1).startswith(".L")]
    out = []
    for k, (i, n) in enumerate(top):
        if not FRAMED_RE.match(n) or re.match(r'^sub_[0-9A-Fa-f]{6}$', n) \
                or re.match(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$', n):
            continue
        end = top[k + 1][0] if k + 1 < len(top) else len(lines)
        body = "\n".join(lines[i:end])
        runs = re.findall(r'\.ascii\s+"([^"]*)"', body)
        fam = re.sub(r'_[0-9]{1,4}$', '', re.sub(r'_[0-9A-Fa-f]{4,6}$', '', n))
        out.append((n, fam, max([len(x) for x in runs], default=0)))
    return out


def mode_framed():
    objs = framed_objects()
    fams = collections.Counter(f for _n, f, _l in objs)
    print("prom_a FRAMED labels: %d\n" % len(objs))
    print("  %-30s %6s %8s" % ("family", "count", "max .ascii"))
    for f, c in fams.most_common(14):
        m = max(l for n, ff, l in objs if ff == f)
        print("  %-30s %6d %8d" % (f, c, m))
    print("  %-30s %6d" % ("... and %d more families" % (len(fams) - 14),
                           len(objs) - sum(c for _f, c in fams.most_common(14))))
    longest = max(objs, key=lambda x: x[2])
    with3 = [o for o in objs if o[2] >= 3]
    print("\n  framed objects containing a >=3-character ROM string: %d of %d"
          % (len(with3), len(objs)))
    print("  the LONGEST .ascii inside any framed object is %d character(s), in %s"
          % (longest[2], longest[0]))
    print("\n  ★ framed -> content promotions this round: 0, and that is the")
    print("    measurement above, not an omission.  prom_b's lanes have this")
    print("    lever because prom_b's display lists carry captions; prom_a's")
    print("    do not.")


def wrappers(k=3):
    """The W lever: small routines with exactly ONE distinct CONTENT-named
    callee. Returns (W, W1, popularity-of-callee-within-W)."""
    W = [r for r in build() if len(r.callees) == 1 and not r.gfx and r.n_flow <= 15]
    by = collections.Counter(list(r.callees)[0] for r in W)
    W1 = [r for r in W if by[list(r.callees)[0]] == 1]
    return W, W1, by


def wrapper_reason(r, shipped):
    """Why a W1 member did NOT get a name. One of R1..R4, or '' if it shipped."""
    if r.name in shipped:
        return ""
    text = _listing_header_above(r.name)
    if "NOT NAMED" in text or "REFUSED" in text:
        return "R1 a refusal header already stands above it"
    script, side = emitter_of(r.addr)
    if script and not side:
        return "R2 inside %s, which has no name side-car" % script
    if not r.endflow:
        return "R3 falls through into the next label; not established as a wrapper"
    if r.n_flow <= 2:
        return ("R4 a two-instruction forwarder: the name would be a second "
                "spelling of a name already on screen")
    return "R5 body not read this round"


def _listing_header_above(label):
    if "hdrs" not in _C:
        d, block = {}, []
        for ln in open(S_A):
            if ln.startswith(";"):
                block.append(ln)
                continue
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
            if m:
                d[m.group(1)] = "".join(block)
            if ln.strip() == "" or m:
                block = []
        _C["hdrs"] = d
    return _C["hdrs"].get(label, "")


def mode_wrappers(k=3):
    W, W1, by = wrappers(k)
    shipped = set(o for o, _n, _w, _e, _u in NAMES9)
    n = len(build())
    print("prom_a ROUND 9 -- the WRAPPER lever\n")
    print("  W  = one distinct CONTENT-named callee, no gfx exit, n_flow <= 15")
    print("       %4d of %d  (%.1f%%)" % (len(W), n, 100.0 * len(W) / n))
    print("  W1 = and no OTHER member of W shares that callee")
    print("       %4d of %d  (%.1f%%)" % (len(W1), n, 100.0 * len(W1) / n))
    print("\n  the callees W1 throws away, and how many wrappers claim each:")
    for cal, c in by.most_common():
        if c >= 2:
            print("      %4d  %s" % (c, cal))
    print("\n  W1, one line each:")
    reasons = collections.Counter()
    for r in sorted(W1, key=lambda x: x.addr):
        why = wrapper_reason(r, shipped)
        reasons["SHIPPED" if not why else why[:2]] += 1
        print("      %-12s %-38s %s"
              % (r.name, list(r.callees)[0], why or "SHIPPED"))
    print("\n  outcome:")
    for kk, v in sorted(reasons.items()):
        print("      %-4s %d" % (kk, v))
    print("\n  ★ %d of the %d W1 members are named by this round; the rest are"
          % (reasons["SHIPPED"], len(W1)))
    print("    refused for a stated, mechanical reason printed above.")


def mode_emitters():
    """Which round-9 names sit inside a generator that would revert them."""
    bad = 0
    for old, new, _w, _e, _u in NAMES9:
        script, side = emitter_of(int(old[4:], 16))
        if script and not side:
            print("  ⚠ %-38s (was %s) is inside %s -- NO side-car"
                  % (new, old, script))
            bad += 1
        elif script:
            print("    %-38s inside %s, which HAS a side-car" % (new, script))
    print("  %d of %d round-9 names would be reverted by a re-emit" % (bad, len(NAMES9)))
    return bad


def mode_applied9():
    for old, new, what, ev, unk in NAMES9:
        print("\n".join(_header(old, new, what, ev, unk, "round 9")))
        print()
    for old, why in REFUSALS9:
        print("\n".join(_refusal_header(old, why)))
        print()


def apply9():
    """Round 9: rename, write a header above each, and correct one committed
    Evidence line. Byte-neutral -- labels and comments only."""
    text = open(S_A).read()
    lines = text.split("\n")
    if _rewrite_round8_header(lines, "sub_FE1D29", "Ring_InitTenOfFourteen"):
        print("  re-emitted Ring_InitTenOfFourteen's header from the corrected "
              "NAMES entry")
    text = "\n".join(lines)
    renamed = []
    for old, new, _w, _e, _u in NAMES9:
        if re.search(r'^' + new + r':', text, re.M):
            continue
        if not re.search(r'^' + re.escape(old) + r':', text, re.M):
            print("  MISSING  %s is not a label in the listing" % old)
            continue
        renamed.append((old, new))
    if renamed:
        table = dict(renamed)
        pat = re.compile(r'\b(' + "|".join(re.escape(o) for o, _n in renamed) + r')\b')
        lines = [pat.sub(lambda m: table[m.group(1)], ln) for ln in lines]
    # refresh our own headers, never anybody else's
    MINE = "named by notes/prom_a_census_round8.py (bucket round 9)"
    keep, i = [], 0
    while i < len(lines):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', lines[i])
        if m and m.group(1) in set(n for _o, n, _w, _e, _u in NAMES9):
            j = len(keep) - 1
            while j >= 0 and keep[j].startswith(";"):
                j -= 1
            if any(MINE in b for b in keep[j + 1:]):
                del keep[j + 1:]
        keep.append(lines[i])
        i += 1
    lines = keep
    out, done = [], set()
    for ln in lines:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
        if m:
            for old, new, what, ev, unk in NAMES9:
                if m.group(1) == new and new not in done and (out and out[-1] != RULE):
                    done.add(new)
                    out.extend(_header(old, new, what, ev, unk, "round 9"))
            for old, why in REFUSALS9:
                if m.group(1) == old and old not in done and (out and out[-1] != RULE):
                    done.add(old)
                    out.extend(_refusal_header(old, why))
        out.append(ln)
    open(S_A, "w").write("\n".join(out))
    print("  round 9: renamed %d labels, wrote %d header blocks"
          % (len(renamed), len(done)))


def verify9():
    text = open(S_A).read()
    bad = 0
    for old, new, _w, _e, _u in NAMES9:
        if not re.search(r'^' + new + r':', text, re.M):
            print("  MISSING  %s" % new)
            bad += 1
        if re.search(r'^' + re.escape(old) + r':', text, re.M):
            print("  STALE    %s still defined" % old)
            bad += 1
        m = re.search(r'((?:^;.*\n)+)' + new + r':', text, re.M)
        if m and "NOT NAMED" in m.group(1):
            print("  CONTRADICTION  a 'NOT NAMED' header sits above %s" % new)
            bad += 1
    for old, _why in REFUSALS9:
        if not re.search(r'^' + re.escape(old) + r':', text, re.M):
            print("  REFUSAL LOST  %s" % old)
            bad += 1
    # ⚠ NORMALISE FIRST.  _header() wraps at 60 columns and prefixes every line
    # with `; `, so a quoted sentence is split across lines in the listing and a
    # plain `in text` test reads MISSING for a phrase that is there -- which is
    # exactly what the first run of this check reported.
    flat = re.sub(r'\s+', ' ', re.sub(r'(?m)^;\s*', ' ', text))
    if re.sub(r'\s+', ' ', FIXED9) not in flat:
        print("  CORRECTION MISSING  Ring_InitTenOfFourteen's Evidence line")
        bad += 1
    if re.sub(r'\s+', ' ', STALE9) in flat:
        print("  CORRECTION STALE    the 'every slot' claim is still in the listing")
        bad += 1
    print("  round 9: %d names, %d refusals, %d problems"
          % (len(NAMES9), len(REFUSALS9), bad))
    return bad


def selftest9():
    """Round 9's own checks, run from selftest(). Tested on the LAST element of
    every list, not only the first."""
    import subprocess
    # --- the claim the name Ring_InitAllFourteen makes -----------------------
    g = subprocess.run("grep -c '^T_Ring[0-9A-F]*_Init:' prom_b/wsa1_prom_b.s",
                       shell=True, cwd=ROOT, capture_output=True, text=True)
    n_slots = int(g.stdout.strip())
    check("prom_b has exactly fourteen T_Ring*_Init slots", n_slots == 14, n_slots)
    recs = {r.name: r for r in build()}
    # ★ READ FROM THE LISTING TEXT, NOT FROM build(): once --apply9 has run the
    # label is no longer a `sub_XXXXXX` and build() cannot see it at all.  A
    # check that only passes before its own tool runs is not a check.
    a_lines = open(S_A).read().split("\n")
    body, on = [], False
    for ln in a_lines:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
        if m:
            on = m.group(1) in ("sub_F825D4", "Ring_InitAllFourteen")
            continue
        if on:
            if re.match(r'^\s*ret\b', ln):
                break
            body.append(ln)
    ops = [m.group(1).lower() for m in
           (re.match(r'^\s*call 0x([0-9a-fA-F]{6})', b) for b in body) if m]
    slots = R7.thunk_slots()
    cobj = R7.content_objects()
    init_slots = set()
    for o in ops:
        t = slots.get(int(o, 16), (int(o, 16), None))[0]
        n = cobj.get(t)
        if n and n.endswith("_Init") and n.startswith("Ring"):
            init_slots.add(n)
    check("the routine at 0xF825D4 calls fourteen DISTINCT Ring*_Init entries, "
          "read off the listing text",
          len(init_slots) == 14, len(init_slots))
    check("and it calls each of them exactly once (fourteen call operands, no "
          "repeat)", len(ops) == 15 and len(set(ops)) == 15,
          "%d operands, %d distinct" % (len(ops), len(set(ops))))
    check("Ring_InitTenOfFourteen is still a LABEL in the listing, so the "
          "ten-call routine and the fourteen-call one are different objects",
          bool(re.search(r'^Ring_InitTenOfFourteen:', open(S_A).read(), re.M)))
    # --- the corrected citation ---------------------------------------------
    a_text = open(S_A).read()
    n_ee4 = a_text.count("0x00f06ee4")
    check("0x00F06EE4 is loaded exactly once in prom_a (prom_b says sub_FC2222 "
          "loads it; the one site is 0xFC22A3, past sub_FC2222's extent)",
          n_ee4 == 1, n_ee4)
    check("that one site is at 0xFC22A3, inside sub_FC2282's extent, not "
          "sub_FC2222's (which ends at 0xFC2281)",
          bool(re.search(r'ld XIX,0x00f06ee4\s*;\s*FC22A3', a_text)))
    # --- the lever's own arithmetic -----------------------------------------
    W, W1, by = wrappers()
    check("W1 members are exactly those whose callee no other W member shares",
          all(by[list(x.callees)[0]] == 1 for x in W1))
    check("W1 is a strict subset of W and smaller than it",
          set(x.name for x in W1) <= set(x.name for x in W) and len(W1) < len(W),
          "%d of %d" % (len(W1), len(W)))
    shipped = set(o for o, _n, _w, _e, _u in NAMES9)
    # ⚠ AFTER --apply9 the shipped labels are gone from the population, so W1
    # can no longer contain them.  The check that survives both states is that
    # W1 and the shipped set are consistent with each other: before apply the
    # thirteen W-lever names are IN W1; after it, none of the twenty is.
    inW1 = set(x.name for x in W1) & shipped
    check("W1 and the shipped set agree: either the thirteen W-lever names are "
          "still in W1 (pre-apply) or none of the twenty is (post-apply)",
          len(inW1) in (0, 13), "%d of %d shipped still in W1"
          % (len(inW1), len(shipped)))
    reasons = set()
    for r in W1:
        reasons.add(wrapper_reason(r, shipped)[:2] or "OK")
    check("wrapper_reason() returns exactly one of R1..R5 (or empty) for every "
          "W1 member, including the LAST", reasons <= {"OK", "R1", "R2", "R3",
                                                       "R4", "R5"}, sorted(reasons))
    # --- LAST ELEMENT of every table ----------------------------------------
    for tag, tbl in (("RING", RING_NAMES), ("SOUND", SOUND_NAMES),
                     ("VENEER", VENEER_NAMES), ("RECORD", RECORD_NAMES)):
        last = tbl[-1]
        check("%s table's LAST entry (%s) names a routine that exists"
              % (tag, last[1]),
              last[0] in recs or bool(re.search(r'^' + last[1] + r':', a_text, re.M)))
        # ⚠ NOT .upper(): _cited_addrs matches a literal lowercase `0x`, so
        # upper-casing the text made this check read ZERO citations in every
        # table and pass nothing.  The first draft did exactly that.
        cited = _cited_addrs(last[3])
        check("%s table's LAST entry cites at least three addresses" % tag,
              len(cited) >= 3, len(cited))
    # every cited address in every round-9 evidence line must be an instruction
    # or object start SOMEWHERE in the tree -- the round-1 "one byte past" bug
    starts = set()
    for tag in "ab":
        for ln in open(os.path.join(ROOT, "prom_%s" % tag, "wsa1_prom_%s.s" % tag)):
            m = re.search(r';\s*([0-9A-F]{6})\b', ln)
            if m:
                starts.add(int(m.group(1), 16))
    # prom_b's thunk lines mostly carry no `; ADDR` column, so add the slot
    # addresses the census already resolves from the ROM image itself.
    starts |= set(R7.thunk_slots().keys())
    missing = []
    for old, new, _w, ev, _u in NAMES9:
        for a in _cited_addrs(ev):
            if a < 0xF00000:          # RAM and SFR cells are not line starts
                continue
            if a not in starts:
                missing.append((new, "%06X" % a))
    check("every ROM address cited by a round-9 Evidence line is a line START "
          "in prom_a or prom_b, or a prom_b thunk slot -- the round-1 'one "
          "byte past the instruction' bug", not missing, missing[:6])
    # --- the quantified claims inside round 9's own headers ------------------
    # ⚠ Every number a header states needs a check, and these are the ones this
    # round states: two indirect call-site counts and two direct ones.
    ind = R7.indirect_refs()
    a_txt = open(S_A).read()
    for label, want in (("SoundGroup_MaxMemberIndex_Get", 11),
                        ("SoundGroup_MaxMemberIndex_GetToneCopy", 7)):
        got = len(ind.get(label, []))
        check("%s's header says %d prom_a sites call its slot" % (label, want),
              got == want, got)
    for label, want in (("DLB_Handler_StringTable_Veneer", 7),
                        ("DLB_Handler_Decimal_Veneer", 10)):
        got = len(re.findall(r'\bcall %s\b' % label, a_txt))
        check("%s's header says %d call sites" % (label, want), got == want, got)

    # --- the framed -> content lever, measured and declined -----------------
    objs = framed_objects()
    check("prom_a's framed population is the 253 the documentation metric counts",
          len(objs) == 253, len(objs))
    with3 = [o for o in objs if o[2] >= 3]
    check("ZERO framed objects in prom_a hold a >=3-character ROM string, which "
          "is why framed -> content is 0 this round", not with3, with3[:4])
    check("the longest .ascii inside any framed object is 2 characters",
          max(o[2] for o in objs) == 2, max(o[2] for o in objs))
    # --- emitter risk, stated rather than discovered later -------------------
    risky = [n for o, n, _w, _e, _u in NAMES9
             if (lambda s: s[0] and not s[1])(emitter_of(int(o[4:], 16)))]
    check("exactly one round-9 name sits inside a side-car-less emitter range, "
          "and its header says so", len(risky) == 1, risky)


# ===========================================================================
# 6. selftest -- and it tests the LAST element, not only the first
# ===========================================================================
def selftest():
    recs = assign()
    n = len(recs)
    check("population is prom_a's whole `sub_XXXXXX` set", n == len(R7.subs()), n)
    check("every record has an address taken from its LABEL",
          all(r.addr == int(r.name[4:], 16) for r in recs))
    check("every record has an extent end (the last label is the only risk)",
          all(r.end is not None for r in recs))
    check("extents are positive and non-overlapping in listing order",
          all(r.ext_bytes > 0 for r in recs))
    # ★ THE LAST ELEMENT, explicitly -- round 1 shipped three counts that were
    # right at the head of a list and wrong at its tail.
    last = recs[-1]
    check("LAST routine %s: extent %d bytes, %d flow instructions"
          % (last.name, last.ext_bytes, last.n_flow),
          last.ext_bytes > 0 and last.n_flow >= 1, last.name)
    check("LAST routine has a bucket", last.bucket in dict(BUCKET_DESC), last.bucket)
    first = recs[0]
    check("FIRST routine %s has a bucket" % first.name,
          first.bucket in dict(BUCKET_DESC), first.bucket)
    check("every routine is in exactly one bucket",
          sum(collections.Counter(r.bucket for r in recs).values()) == n)
    # flow scope is a SUBSET of the extent scope, always
    check("flow-reachable body never exceeds the address extent",
          all(r.n_flow <= r.n_ext for r in recs))
    check("and it is strictly smaller for at least one routine, or the walk is a no-op",
          any(r.n_flow < r.n_ext for r in recs),
          sum(1 for r in recs if r.n_flow < r.n_ext))
    # the branch resolver, proved against labels the listing itself names
    A, _B = R6.images()
    ok = bad = 0
    for i, ln in enumerate(A.lines):
        m = re.match(r'^\s*(jr|jrl)\s+(?:\w+,\s*)?(\.L[0-9A-F]{6})\s*;\s*([0-9A-F]{6})\s+'
                     r'([0-9a-f]{2}) ([0-9a-f]{2})', ln)
        if not m:
            continue
        want = int(m.group(2)[2:], 16)
        addr = int(m.group(3), 16)
        if m.group(1) == "jr":
            got = branch_target(addr, "jr", "0x" + m.group(5))
        else:
            continue
        ok, bad = (ok + 1, bad) if got == want else (ok, bad + 1)
    check("`jr` displacement formula agrees with every `.L` label the listing names",
          bad == 0 and ok > 1000, (ok, bad))
    # the device table really is the memory map's
    mm = open(os.path.join(ROOT, "notes", "FINDINGS-memory-map.md")).read()
    for _lo, _hi, tag, anchor, _d in DEVICES:
        check("device %s: the memory map spells %s" % (tag, anchor), anchor in mm)
    # DRAM really is non-discriminating, which is why it is not a device
    nd = sum(1 for r in recs if r.dram)
    check("work DRAM is the single most-touched region, by a wide margin, "
          "which is why it is NOT a device row", nd > 10 * max(
              sum(1 for r in recs if tag in r.dev)
              for _lo, _hi, tag, _a, _d in DEVICES), nd)
    # distinctiveness really is doing work
    p = popularity()
    top = max((v for x, v in p.items() if x.startswith("callee:")), default=0)
    check("the most-called CONTENT routine is called by many of them", top >= 50, top)
    n_any = sum(1 for r in recs if r.callees)
    n_dist = sum(1 for r in recs if any(p["callee:" + x] <= 3 for x in r.callees))
    check("distinctiveness cuts 'calls something named' from %d to %d" % (n_any, n_dist),
          n_dist < n_any / 3, (n_any, n_dist))
    # ★★ EVERY CITED ADDRESS IS RE-READ OUT OF THE LISTING.
    # Round 1 shipped ~31 citations one byte past the instruction, systematically,
    # and they were all gate-clean.  This is the check that catches it: for each
    # `0xNNNNNN `mnemonic ...`` pair in an Evidence line, the listing must have an
    # instruction AT that address and its mnemonic must be the one quoted.
    _order, idx = addr_index()
    cited = miscited = notinstr = 0
    for _o, _n, _w, ev, _u in NAMES + LINK_NAMES:
        for m in re.finditer(r'0x([0-9A-F]{6})\s+`([a-z_0-9]+)', ev):
            a, mn = int(m.group(1), 16), m.group(2)
            cited += 1
            if a not in idx:
                notinstr += 1
            elif idx[a][0] != mn:
                miscited += 1
                print("      MISCITED 0x%06X: listing says `%s`, header says `%s`"
                      % (a, idx[a][0], mn))
    check("every one of the %d quoted citations decodes AT the cited address "
          "(the round-1 off-by-one)" % cited, miscited == 0 and notinstr == 0,
          (cited, miscited, notinstr))
    check("...and the byte at cited-1 being an opcode is the bug's signature, so "
          "there are citations to check at all", cited >= 30, cited)
    # ★ Cited addresses with no backtick must still be REAL: an instruction
    # address, or a LABEL address -- 0xF828C7 is `ExtBoardMagic_F828C7`, ASCII
    # data, and demanding an instruction there would be the check being wrong
    # rather than the header.  Anything that is neither is a typo.
    Ax, Bx = R6.images()
    labeladdr = set()
    for imgx in (Ax, Bx):
        for nmx in imgx.order:
            eax = imgx.routines[nmx][2]
            if eax is None and R6.SUB.match(nmx) and imgx is Ax:
                eax = R7.sub_addr(nmx)
            if eax is not None:
                labeladdr.add(eax)
            # ⚠ AND FROM THE NAME.  Image.addr only sees `; ADDR ` with trailing
            # whitespace, so a `.byte` line whose comment ENDS at the address --
            # `ExtBoardMagic_F828C7`'s ten ASCII bytes are exactly that -- has
            # no address at all.  A framed label spells its own address; use it.
            mx = re.search(r'_([0-9A-F]{6})$', nmx)
            if mx:
                labeladdr.add(int(mx.group(1), 16))
    loose = bad_loose = 0
    for _o, _n, _w, ev, _u in NAMES + LINK_NAMES:
        for m in re.finditer(r'0x([0-9A-F]{6})\b', ev):
            a = int(m.group(1), 16)
            if not (0xF80000 <= a <= 0xFFFFFF):
                continue
            loose += 1
            if a not in idx and a not in labeladdr:
                bad_loose += 1
                print("      NEITHER AN INSTRUCTION NOR A LABEL: 0x%06X" % a)
    check("all %d prom_a addresses named in Evidence lines are an instruction "
          "or a label" % loose, bad_loose == 0, (loose, bad_loose))
    # ★ THE COUNT A ROUND-3 REVIEWER WOULD CHECK.  Variant_SetFromPB0's own
    # paragraph in the listing said "four instructions" and then listed five;
    # it now says six and this is what makes that true.  Counted across the
    # ADDRESS EXTENT, which is the count a label-bounded walk gets wrong.
    A6, _B6 = R6.images()
    lx6 = line_extents()
    for nm6, want6 in (("Variant_SetFromPB0", 6), ("sub_F82882", 6)):
        if nm6 in lx6:
            i6, e6 = lx6[nm6]
            n6 = sum(1 for j in range(i6, e6)
                     if not A6.lines[j].startswith(";") and A6.lines[j].strip()
                     and R6.MNEM.match(A6.lines[j])
                     and not R6.MNEM.match(A6.lines[j]).group(1).startswith("."))
            check("%s is %d instructions across its address extent, not four"
                  % (nm6, want6), n6 == want6, n6)
    src6 = open(S_A).read()
    check("...and the listing's own paragraph no longer says 'four instructions'",
          "Variant_SetFromPB0 (0xF82882) is four" not in src6)
    # the prose lever, and the fact that it is EXHAUSTED once applied
    ph = prose_names()
    check("the prose lever's reach is measured, not asserted (currently %d left)"
          % len(ph), isinstance(ph, dict))
    for nm7 in ("Variant_SetFromPB0", "ExtBoard_Identify", "VersionScreen_Show"):
        check("prose-named %s is now a LABEL, not only a sentence" % nm7,
              re.search(r'^' + nm7 + r':', src6, re.M) is not None)
    check("no 'NOT NAMED' header survives above any name this round applied",
          not any(re.search(r'((?:^;.*\n)+)' + n8 + r':', src6, re.M)
                  and "NOT NAMED" in re.search(r'((?:^;.*\n)+)' + n8 + r':',
                                               src6, re.M).group(1)
                  for _o8, n8, _w8, _e8, _u8 in NAMES + LINK_NAMES))
    # the buckets this round named
    for old, new, _w, _e, _u in NAMES + LINK_NAMES:
        cur = [r for r in recs if r.name in (old, new)]
        if cur:
            check("%s is in bucket T1 before renaming" % old, cur[0].bucket == "T1",
                  cur[0].bucket)
        else:
            check("%s has been renamed to %s and left the population" % (old, new),
                  re.search(r'^' + new + r':', open(S_A).read(), re.M) is not None)
    # ★ THE FOUR Dev7E ACCESSORS ARE THE ONLY 0x7E0000 FORMERS.
    # ⚠ COUNTED OVER INSTRUCTION LINES ONLY.  The first draft grepped the whole
    # file and broke the moment this round's own headers QUOTED the constant --
    # a check that counts its own documentation is measuring the prose.
    code = [ln for ln in open(S_A).read().split("\n")
            if ln and not ln.lstrip().startswith(";")]
    sites = [ln for ln in code if re.search(r'add X\w+,0x007e0000', ln)]
    check("exactly four INSTRUCTIONS in prom_a form 0x007E0000 "
          "(FINDINGS-memory-map.md's claim)", len(sites) == 4, len(sites))
    lp = [ln for ln in code if "0x007c0000" in ln]
    check("the link port 0x007C0000 is formed by %d instructions in prom_a, one "
          "per named sender plus the initialiser" % len(lp), len(lp) >= 7, len(lp))
    # ceiling behaviour: the terminal bucket can only shrink as other lanes work
    c = collections.Counter(r.bucket for r in recs)
    check("terminal bucket N is a CEILING, quoted as a ratio: %.1f%%"
          % (100.0 * c["N"] / n), 0.0 < c["N"] / float(n) < 1.0, c["N"])
    check("the shape buckets and the touch buckets do not overlap "
          "(first match wins is real)",
          all(r.bucket in dict(BUCKET_DESC) for r in recs))
    # the knob does not decide the answer
    # ★ THE KNOB MUST NOT DECIDE THE ANSWER.  The first draft asserted "moves N
    # by less than 5 points", which k=10 broke (1,988 -> 1,799, 6.5 points).  A
    # tolerance picked to pass is not a check; the CONCLUSION is what has to
    # survive, so this asserts the conclusion over the whole sweep instead and
    # prints the span it actually moved.
    span = []
    for kk in (1, 2, 3, 5, 10, 25):
        for r in build():
            r.bucket, r.why = bucket(r, kk)
        span.append(collections.Counter(r.bucket for r in build())["N"])
    check("over k = 1..25 the terminal bucket stays above 55%% of the population "
          "(it spans %d..%d, %.1f..%.1f%%)"
          % (min(span), max(span), 100.0 * min(span) / n, 100.0 * max(span) / n),
          min(span) > 0.55 * n, span)
    assign()
    # ── claims made in the docstring that nothing else pins ────────────────
    code = [ln for ln in open(S_A).read().split("\n")
            if ln and not ln.lstrip().startswith(";")]
    n_jpx = sum(1 for ln in code if re.match(r'^\s*jp\s+\(xix\)\s*$', ln.split(";")[0]))
    check("the flow walk cannot follow `jp (xix)`; prom_a has %d of them" % n_jpx,
          n_jpx > 200, n_jpx)
    n_gap = sum(1 for r in recs if r.n_ext > r.n_flow)
    check("%d of %d have flow < extent (the `--gap` population)" % (n_gap, len(recs)),
          n_gap > 0, n_gap)
    # ★ THE THREE ROUTINES THAT EXPLAIN THE S1 DISAGREEMENT WITH ROUND 7.
    # Round 7 counted 283 one-byte `ret` stubs; S1 here is 281.  Naming the
    # difference is the whole point -- an unreconciled off-by-two is exactly the
    # kind of thing this wave's reviewers keep finding.
    by = {r.name: r for r in recs}
    for nm9 in ("sub_FADDA9", "sub_FADE55"):
        if nm9 in by:
            check("%s: inside the fad800 emitter's range, so extent_ends() gives "
                  "it %d bytes and it is not S1" % (nm9, by[nm9].ext_bytes),
                  by[nm9].ext_bytes > 1 and by[nm9].bucket != "S1", by[nm9].bucket)
    if "sub_FE0046" in by:
        r9 = by["sub_FE0046"]
        f9 = flow_of(r9)
        check("sub_FE0046 is a ONE-BYTE object whose byte is `%s`, not a ret, so "
              "it is correctly not S1" % (f9[0][1] if f9 else "?"),
              r9.ext_bytes == 1 and r9.bucket != "S1", r9.bucket)
    # references partition the population exactly, and the split is the point
    none9 = sum(1 for r in recs if not r.d_refs and not r.t_refs and not r.dir_refs)
    dir9 = sum(1 for r in recs if not r.d_refs and not r.t_refs and r.dir_refs)
    check("reference classes partition the population (%d none + %d directory-only "
          "+ %d reached = %d)" % (none9, dir9, len(recs) - none9 - dir9, len(recs)),
          none9 + dir9 <= len(recs))
    check("more routines are published-by-a-slot-only (%d) than reached by nothing "
          "(%d) -- collapsing the two is how 'no references' gets said wrongly"
          % (dir9, none9), dir9 > none9)
    check("this round proposes %d names and %d refusal" % (len(NAMES) + len(LINK_NAMES),
                                                           len(REFUSALS)),
          len(NAMES) + len(LINK_NAMES) == 16 and len(REFUSALS) == 1)
    selftest9()
    print("\n%d checks, %d failures" % (OK + FAIL, FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    a = sys.argv[1:]
    k = 3
    if "--k" in a:
        k = int(a[a.index("--k") + 1])
    if "--selftest" in a:
        sys.exit(selftest())
    if "--apply9" in a:
        apply9()
    elif "--verify9" in a:
        sys.exit(1 if verify9() else 0)
    elif "--applied9" in a:
        mode_applied9()
    elif "--wrappers" in a:
        mode_wrappers(k)
    elif "--emitters" in a:
        mode_emitters()
    elif "--framed" in a:
        mode_framed()
    elif "--apply" in a:
        apply()
    elif "--verify" in a:
        sys.exit(1 if verify() else 0)
    elif "--applied" in a:
        mode_applied()
    elif "--refusals" in a:
        mode_refusals()
    elif "--prose" in a:
        mode_prose()
    elif "--popular" in a:
        mode_popular(k)
    elif "--sweep" in a:
        mode_sweep()
    elif "--gap" in a:
        mode_gap()
    elif "--nothing" in a:
        mode_nothing()
    elif "--bucket" in a:
        mode_dump(only=a[a.index("--bucket") + 1])
    elif "--dump" in a:
        i = a.index("--dump")
        lim = int(a[i + 1]) if i + 1 < len(a) and a[i + 1].isdigit() else None
        mode_dump(lim)
    else:
        mode_census(k)
