#!/usr/bin/env python3
"""How well DOCUMENTED is this disassembly? The goal metric, per image.

QUESTION IT ANSWERS
    "The byte gate says the bytes are right. What says the disassembly is
     UNDERSTOOD -- how many routines carry a semantic name rather than
     sub_XXXXXX, how many carry an Evidence: line, and how many have a real
     header comment?"

WHY IT EXISTS
    The project goal is a perfectly byte-matching AND well-documented
    disassembly.  Byte-matching has a gate; documentation had no instrument at
    all, so every report reached for coverage instead -- the number that is easy
    to measure rather than the one that matters.  Worse, the two move in
    OPPOSITE directions: converting a span imports every routine inside it and
    none is born with a name.  Measured across wave 7:

        span 0xFAD800   18,432 B   84 labels,   0 semantic   -> sub_ +82
        span 0xFA5AEB   17,685 B  227 labels, 100 semantic   -> sub_ +18

    Same size of territory, a quarter of the damage, because the second lane
    named as it went.  That comparison is the argument for this script existing.

★ THREE GRADES, NOT TWO -- AND THE SECOND GRADE IS WHY
    The first version of this script had two grades, sub_XXXXXX and "semantic",
    and it was WRONG in exactly the way prom_d's 100%% is wrong.  The wave-7
    prom_b lane said so about its own work, unprompted: of 373 non-sub_ labels it
    added, 88 were placeholders and a further 180 were "a KIND plus an address"
    (StringTable_F1828A, IndexMap_..., PtrTable_..., Bitmap_WxH) -- real, derived,
    and NOT understanding.  Only 104 were content-derived.  A metric that scores
    all 373 the same rewards framing and calls it meaning.

    So labels are now graded:
      UNNAMED   sub_XXXXXX
      FRAMED    a structural KIND plus an address -- Table_F4EF40, DL_F17C00,
                Bitmap_24x17_F17C59.  The object is delimited and typed; nobody
                has said what it is FOR.  This is real work and a necessary step;
                it is just not the goal.
      CONTENT   a name that says what the thing IS or DOES.
    ⚠ AND THE LINE BETWEEN FRAMED AND CONTENT IS A JUDGEMENT, SO THIS SCRIPT
    REPORTS A BRACKET AND NOT A NUMBER.  The strict rule below (a label whose
    distinguishing part is a NUMBER is positional) is deliberately harsh: it
    classifies `Dev10C_StageRegs_0800_0840_FAB818` as framed, though that name
    plainly states a mechanism and only carries an address to disambiguate.  The
    loose rule (anything not sub_XXXXXX) is deliberately generous: it counts
    `Table_F4EF40` as understanding.  The truth is between them.

        CONT%%   = STRICT, a LOWER BOUND on how much is understood
        named%%  = LOOSE, an UPPER BOUND

    The one hand-classified calibration point in the tree: the wave-7 round-3
    prom_b lane graded its OWN 373 new non-sub_ labels as 104 content-derived,
    180 kind-plus-address, and 88 placeholders.  So for that sample the truth sat
    at 28%% of the loose number, and the strict rule would have said less.  Quote
    the bracket.  A metric that resolves a judgement by picking a threshold is
    how prom_d came to read 100%%.

WHAT COUNTS AS WHAT
    * A label matching sub_[0-9A-F]{6} is UNNAMED. Anything else at column 0
      ending in ':' is a SEMANTIC name.  Compiler-local .L labels are excluded
      -- counting them was a real error in a wave-7 audit (they inflated a
      label count by 8,237).
    * An "Evidence:" line is a comment line stating why a name is what it is.
    * A HEADER is a comment block of >= 3 consecutive comment lines above a label,
      with at most ONE blank line between the block and the label -- the house
      style used around DSP_ChanFreq_CurvePool.
      ⚠ The blank-line tolerance was added in round 3 because without it the count
      was an artefact of whitespace: a wave-7 reviewer proved that prom_c's whole
      +35 "headers" gain was 35 REMOVED BLANK LINES, each sitting between an
      existing comment block and its label, with zero newly written headers. The
      prose was already there; only the metric could not see it. A measurement
      that moves when you delete whitespace is measuring the whitespace.

RUN
    python3 notes/wave7_documentation_metrics.py
    python3 notes/wave7_documentation_metrics.py --range a 0xFA5AEB 0xFAA000
    python3 notes/wave7_documentation_metrics.py --selftest    # 14 checks
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_files                # noqa: E402


def _image_lines(path):
    """Every line of the IMAGE at `path`, `.include`s expanded -- minus any part
    that has its own row in IMAGES (see SKIP_OWN_ROW)."""
    out = []
    files = image_files(ROOT, path)
    for i, f in enumerate(files):
        rel = os.path.relpath(f, ROOT)
        # never skip the file that was ASKED for -- kernel/kernel.s is both an
        # included part of two images and a row of its own.
        if i and (rel in SKIP_OWN_ROW or rel.endswith(".inc")):
            continue
        # ⚠ VERBATIM, `.include` lines included.  Deleting them would join a
        # comment block to the label after the directive instead of stopping at
        # it, which moved prom_a's and prom_b's header counts by 3 each -- a
        # measurement changed by the instrument, in the two images this fix was
        # not supposed to touch.
        out.extend(open(f, encoding="utf-8", errors="replace").read().split("\n"))
    return out
IMAGES = [("prom_a", "wsa1_prom_a.s", 0xF80000), ("prom_b", "wsa1_prom_b.s", 0xF00000),
          ("prom_c", "wsa1_prom_c.s", 0xF80000), ("prom_d", "wsa1_prom_d.s", 0x000000),
          # ⚠ NOT AN IMAGE.  kernel/kernel.s is ONE source that prom_a and prom_c
          # both `.include`; without this row its 96 labels and 37 headers would
          # be invisible here and the totals would read as a loss.
          ("kernel", "kernel.s", 0xF80000)]

EV_ADDRS = {}
# ★★ AN INTERNAL BRANCH TARGET IS NOT A DOCUMENTATION DEBT.
# prom_c spells the branch targets inside a routine as <parent>__<address> --
# sub_FBDCD3__FBDD01, VoiceParams_Compute_A__FA1234. They are jump destinations,
# the exact equivalent of the .L compiler-locals this script already excludes, and
# they are NOT objects waiting for a name. The first four versions of this script
# counted all 4,975 of them (24.7% of every label in the tree, 4,851 of them in
# prom_c alone) as unnamed or merely framed, which is why prom_c read 11.8%
# understood while being territorially complete and heavily annotated.
# ⚠ The denominator changed when this was fixed, so figures from earlier rounds are
# not comparable to later ones. Both are printed.
INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
# ★★ AND THE DESCRIPTIVE ONES ARE BRANCH TARGETS TOO. Round 12's prom_c lane
# measured that 168 labels of the form Parent__word -- RESET__clear_iram,
# DSP_ChannelRegs_Init__loop -- were being counted in the CONTENT column, 19.3%
# of prom_c's content total. When the hex-suffixed form was excluded in round 9
# the descriptive form was deliberately KEPT as content, on the grounds that it
# says what the branch is for. That was half right and half wrong: it IS
# documentation, but it is not an OBJECT awaiting a name, so scoring it beside
# DSP_ChanFreq_CurvePool conflates a landmark inside a routine with the routine.
# They now have their own column. This LOWERS the content percentage, which is
# the correct direction for a measurement that was flattering.
DESCRIPTIVE_BRANCH = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[A-Za-z][A-Za-z0-9_]*$')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
# A "framed" name is a structural kind with an address glued on, in any of the
# spellings the wave-7 lanes actually used. The trailing-address test alone is not
# enough (Kernel_InitRam_F82D11 would be content), so a structural PREFIX is required.
FRAMED_KIND = (r'sub|DL|Table|PtrTable|StringTable|IndexMap|RecordArray|Bitmap|Data|'
               r'Blob|Pool|Pad|Fill|Array|Records?|Map|Curve|Seg|Block|Chunk|Unk|'
               r'Unknown|Word|Byte|Ptr|Str|Buf')
# ★ THE GENERAL RULE, which subsumes the prefix list: a label whose DISTINGUISHING
# part is a NUMBER is positional, not semantic.  `PercInst_17` says "element 17 of
# the percussion instrument array" -- the object is framed and indexed, and nobody
# has said what it IS.  Same for `Table_F4EF40`.  Both are real work and neither is
# understanding.  This is what made prom_d read 100% on the first draft of this
# script: its 3,665 labels are `ToneDB_EnvDescTable_Pool_<addr>` and `PercInst_<n>`.
# Deliberately NOT caught: Int32_ToFloat32_Q31, Multiply16_Signed_Shr11,
# Kernel_InitRam -- their trailing digits are part of a word, not the whole suffix.
FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                    r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                    r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')
ADDR_COMMENT = re.compile(r';\s*([0-9A-F]{6})\b')


# ⚠ AN IMAGE IS NOT ONE FILE ANY MORE.  On 2026-08-30 prom_c and prom_d were each
# split into a primary plus `.include` parts, and this table went on opening the
# primary alone: prom_c fell to 3 content labels and prom_d to 2, and prom_d's
# LOWER/UPPER both read 100% off those two.  A headline metric quietly measuring
# a header file is worse than no metric.  scan() now follows the includes.
#
# ⚠ EXCEPT a file that has its OWN ROW here.  kernel/kernel.s is included by
# prom_a AND prom_c and is listed below as its own line precisely so its 96
# labels are visible; expanding it into both images as well would count it three
# times and inflate the total.  SKIP_OWN_ROW is that rule, stated once.
#
# ⚠ AND `include/*.inc` IS SKIPPED IN EVERY IMAGE.  Those files define macros and
# equates rather than image content, and prom_a, prom_b and kernel/kernel.s all
# include the same one -- counting it per image would triple-count it.  Skipping
# them is also what keeps prom_a's and prom_b's rows nearly what they were
# before this change, which is the control that says the fix touched only the
# images that were broken.
#
# ⚠ AND ONE THING IT DOES NOT SOLVE, said here rather than left to be found: a
# shared CONTENT part with no row of its own -- maincpu/shared/lcd_screen_redraw.s
# and maincpu/shared/indexed_table.s, which prom_a and prom_b both include -- is
# counted in BOTH rows.  That is why prom_a moved 1,470 -> 1,473 when this fix
# landed: three labels that were invisible before are now visible twice.  Give
# such a file its own row here the moment there is more than a handful.
SKIP_OWN_ROW = {"kernel/kernel.s"}


def scan(path, want_ev=False):
    """Walk the source once, classifying every label and the comment block above it."""
    lines = _image_lines(path)
    named, framed, unnamed, internal, branch, with_header, with_evidence = [], [], [], [], [], 0, 0
    run = 0                      # consecutive comment lines above
    blanks = 0                   # blank lines seen since the comment run ended
    last_addr = None
    ev_in_block = False
    for ln in lines:
        m = ADDR_COMMENT.search(ln)
        if m:
            last_addr = int(m.group(1), 16)
        if ln.startswith(";"):
            run += 1
            if "Evidence:" in ln:
                ev_in_block = True
            blanks = 0
            continue
        if ln.strip() == "" and run:
            # One blank line does not break a header block; two do.
            blanks += 1
            if blanks > 1:
                run, ev_in_block, blanks = 0, False, 0
            continue
        lm = LABEL.match(ln)
        if lm:
            name = lm.group(1)
            if INTERNAL.match(name):
                internal.append((name, last_addr))
            elif DESCRIPTIVE_BRANCH.match(name):
                branch.append((name, last_addr))
            elif UNNAMED.match(name):
                unnamed.append((name, last_addr))
            elif FRAMED.match(name):
                framed.append((name, last_addr))
            else:
                named.append((name, last_addr))
            if run >= 3:
                with_header += 1
            if ev_in_block:
                with_evidence += 1
                EV_ADDRS.setdefault(path, set()).add(last_addr)
        run, ev_in_block, blanks = 0, False, 0
    return named, framed, unnamed, internal, branch, with_header, with_evidence


def report(rng=None):
    tn = tf = tu = th = te = ti = 0
    print("%-8s %9s %8s %9s %8s %8s %9s %9s  %8s"
          % ("image", "content", "framed", "sub_XXXX", "LOWER", "UPPER", "headers", "evidence",
             "internal"))
    for tag, src, _base in IMAGES:
        named, framed, unnamed, internal, branch, hdr, ev = scan(os.path.join(tag, src))
        n, f, u, il = len(named), len(framed), len(unnamed), len(internal) + len(branch)
        ti += il
        tn, tf, tu, th, te = tn + n, tf + f, tu + u, th + hdr, te + ev
        tot = n + f + u
        print("%-8s %9s %8s %9s %7.1f%% %7.1f%% %9s %9s  %8s"
              % (tag, format(n, ","), format(f, ","), format(u, ","),
                 100.0 * n / tot if tot else 0.0,
                 100.0 * (n + f) / tot if tot else 0.0, format(hdr, ","), format(ev, ","),
                 format(il, ",")))
    tot = tn + tf + tu
    print("%-8s %9s %8s %9s %7.1f%% %7.1f%% %9s %9s  %8s"
          % ("TOTAL", format(tn, ","), format(tf, ","), format(tu, ","),
             100.0 * tn / tot if tot else 0.0, 100.0 * (tn + tf) / tot if tot else 0.0,
             format(th, ","), format(te, ","), format(ti, ",")))
    print("\n  'internal' = <parent>__<address> AND <parent>__<word> branch targets,")
    print("  EXCLUDED from the percentages. Both are jump destinations inside a routine,")
    print("  not objects awaiting a name -- the same reason .L locals are excluded.")
    print("  ⚠ The DESCRIPTIVE form was counted as content until round 12, when prom_c's")
    print("  lane measured 168 of them, 19.3% of that image's content column. Excluding")
    print("  them LOWERS every content figure, which is the correct direction.")
    print("\n★ LOWER and UPPER BRACKET how much of the tree is UNDERSTOOD; neither alone is")
    print("  the answer, and the gap between them is the work of deciding what a name claims.")
    print("  LOWER treats every label whose distinguishing part is a number as merely FRAMED;")
    print("  UPPER treats every non-sub_ label as understood. The tree's one hand-graded")
    print("  sample (round-3 prom_b, 373 labels) landed at 28% of its UPPER figure.")
    print("  Coverage measures TERRITORY; this measures MEANING, and converting a span moves")
    print("  the two in OPPOSITE directions unless the lane names as it goes.")
    print("  The byte gate is blind to every number on this page.")


def in_range(tag, lo, hi):
    key = tag if tag.startswith("prom_") else "prom_" + tag
    src = dict((t, s) for t, s, _b in IMAGES)[key]
    named, framed, unnamed, _il, _br, _h, _e = scan(os.path.join(key, src))
    n = [x for x in named if x[1] is not None and lo <= x[1] < hi]
    fr = [x for x in framed if x[1] is not None and lo <= x[1] < hi]
    u = [x for x in unnamed if x[1] is not None and lo <= x[1] < hi]
    ev = len([a for a in EV_ADDRS.get(os.path.join(key, src), set())
              if a is not None and lo <= a < hi])
    print("prom_%s 0x%06X-0x%06X: %d labels -- %d content, %d framed, %d sub_XXXXXX; %d evidenced"
          % (key[-1], lo, hi, len(n) + len(fr) + len(u), len(n), len(fr), len(u), ev))
    return len(n) + len(fr), len(u), ev


def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    tot_u = 0
    for tag, src, _b in IMAGES:
        named, framed, unnamed, _il, _br, hdr, ev = scan(os.path.join(tag, src))
        tot_u += len(unnamed)
        check("%s: every 'unnamed' really matches sub_ + 6 hex" % tag,
              all(UNNAMED.match(n) for n, _a in unnamed))
        check("%s: no semantic name is a sub_XXXXXX in disguise" % tag,
              not any(UNNAMED.match(n) for n, _a in named))
        check("%s: no .L compiler-local counted as a label (they inflated a count by 8,237)" % tag,
              not any(n.startswith(".L") for n, _a in named + unnamed))
    # agrees with the independent grep the handoff documents
    import subprocess
    # ⚠ kernel/ is in the file list because the shared kernel source moved 11
    # sub_XXXXXX labels out of prom_a; scanning prom_*/*.s alone made this check
    # fail by exactly those 11.
    #
    # ★★ AND THE FILE LIST IS NO LONGER A SHELL GLOB, for the same reason.
    # It used to be `grep -rhoE ... prom_*/*.s kernel/*.s`.  That glob is ONE
    # LEVEL DEEP, and on 2026-08-30 the prom_c split moved 24 of its sources into
    # prom_c/{boot,link,midi,keyscan,voice,p7,tone_db,devices,storage,mathlib,
    # data_tables}/ -- two levels.  The glob stopped seeing them and the grep fell
    # from 5,131 distinct names to 4,843, so this check has been FAILING at HEAD
    # ever since, reported as "routines (5133) minus duplicates (2) != 4843".
    # ⚠ NOTHING WAS WRONG WITH EITHER SIDE OF THE ARITHMETIC.  The scan reads the
    # image through asm_source and was right; the grep read a directory listing
    # and was wrong; 5133 - 2 == 5131 is the identity that was true all along.
    # This is the same collateral as a probe opening a now-stubbed .s by path --
    # a stale FILE LIST, not a stale number -- so the fix is the same in kind:
    # ask git for the sources instead of guessing their depth.
    #   old glob        prom_*/*.s kernel/*.s                -> 4,843
    #   with subdirs    + prom_*/*/*.s                       -> 5,131
    #   git ls-files    every tracked .s under those trees   -> 5,131
    files = subprocess.run(
        ["git", "ls-files", "--", "prom_a/*.s", "prom_b/*.s", "prom_c/*.s",
         "prom_d/*.s", "kernel/*.s", "maincpu/*.s"],
        cwd=ROOT, capture_output=True, text=True).stdout.split()
    g = subprocess.run(["grep", "-hoE", "^sub_[0-9A-Fa-f]{6}:"] + files,
                       cwd=ROOT, capture_output=True, text=True).stdout.split()
    g = str(len(set(g)))
    # ⚠ The documented grep pipes through `sort -u`, so it counts DISTINCT NAMES.
    # prom_a and prom_c are BOTH based at 0xF80000, so the same sub_XXXXXX name can
    # legitimately exist in both files and is two different routines. This script
    # counts ROUTINES; the grep counts names. The difference is real and is checked
    # here rather than papered over -- quoting one number for the other would
    # undercount the work still to do.
    allnames = []
    for _t, _s, _b in IMAGES:
        allnames += [n for n, _a in scan(os.path.join(_t, _s))[2]]
    dupes = len(allnames) - len(set(allnames))
    check("routines (%d) minus cross-file duplicate NAMES (%d) equals the documented grep (%s)"
          % (tot_u, dupes, g), tot_u - dupes == int(g))
    check("every duplicate name is shared between prom_a and prom_c, which share base 0xF80000",
          all(sum(1 for _t, _s, _b in IMAGES
                  if n in [x for x, _a in scan(os.path.join(_t, _s))[2]]) <= 2
              for n in set(x for x in allnames if allnames.count(x) > 1)))
    # the two wave-7 conversions, checked on the LAST one as well as the first
    # ★ THE COMPARISON THIS SCRIPT EXISTS FOR, and a lesson about pinning.
    # AT EMISSION on 2026-08-29 the two spans were:
    #     0xFAD800  18,432 B   84 labels,   0 semantic,   0 evidenced  -> sub_ +82
    #     0xFA5AEB  17,685 B  227 labels, 193 semantic, 103 evidenced  -> sub_ +18
    # ⚠ The first draft of this script PINNED "0xFAD800: 84/0/0" as a check. It
    # then FAILED -- because a later lane went back and named part of that span,
    # which is the tree getting BETTER. A constant pinned to a number that is
    # supposed to move is a check that punishes progress. The emission figures
    # above are HISTORY and live in this comment; the check below asserts the
    # INVARIANT instead: the span that was converted without naming still trails
    # the span that was named as it went.
    n1, u1, e1 = in_range("a", 0xFAD800, 0xFB2000)
    n2, u2, e2 = in_range("a", 0xFA5AEB, 0xFAA000)
    d1 = n1 / float(n1 + u1) if (n1 + u1) else 0.0
    d2 = n2 / float(n2 + u2) if (n2 + u2) else 0.0
    check("0xFAD800 (converted WITHOUT naming) is %.1f%% named" % (100 * d1), n1 + u1 > 0)
    check("0xFA5AEB (named AS IT WENT) is %.1f%% named" % (100 * d2), n2 + u2 > 0)
    check("...and the named-as-it-went span still leads -- the invariant, not a pin",
          d2 > d1)
    check("0xFA5AEB carries more Evidence: lines than 0xFAD800 (%d vs %d)" % (e2, e1),
          e2 > e1)
    # the classifier itself, on names taken from the tree, both directions
    for nm in ("DSP_ChanFreq_CurvePool", "Int32_ToFloat32_Q31", "Kernel_InitRam",
               "Multiply16_Signed_Shr11", "Stream_ReadU24BE"):
        check("classifier: %s is CONTENT, not framed" % nm, not FRAMED.match(nm))
    for nm in ("Table_F4EF40", "PercInst_17", "DL_F17C00", "Bitmap_24x17_F17C59",
               "ToneDB_MixerDefaultTable_204"):
        check("classifier: %s is FRAMED, not content" % nm, bool(FRAMED.match(nm)))
    # ★ Internal branch targets: excluded, but ONLY the undescriptive ones.
    for nm in ("sub_FBDCD3__FBDD01", "VoiceParams_Compute_A__FA1234",
               "P7Unit_EmitChangedParams__FB0011"):
        check("classifier: %s is an INTERNAL branch target, excluded" % nm,
              bool(INTERNAL.match(nm)))
    # ⚠ ROUND 12 REVERSED THIS. These were counted as CONTENT until prom_c's lane
    # measured 168 of them, 19.3% of that image's content column. They document a
    # branch, but they are not objects awaiting a name.
    for nm in ("RESET__clear_iram", "DSP_ChannelRegs_Init__loop",
               "SeqBuf_AppendMarker__done", "Kernel_InitRam__ready_queues"):
        check("classifier: %s is a DESCRIPTIVE branch label -- EXCLUDED, not content" % nm,
              bool(DESCRIPTIVE_BRANCH.match(nm)) and not FRAMED.match(nm))
    _br = 0
    for _t, _s, _b in IMAGES:
        _br += len(scan(os.path.join(_t, _s))[4])
    check("descriptive branch labels excluded tree-wide: %s (prom_c's lane measured 168)"
          % format(_br, ","), _br > 150)
    _tot_int = 0
    for _t, _s, _b in IMAGES:
        _tot_int += len(scan(os.path.join(_t, _s))[3])
    check("internal branch targets excluded tree-wide: %s, nearly all in prom_c"
          % format(_tot_int, ","), _tot_int > 4000)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--range" in sys.argv:
        i = sys.argv.index("--range")
        in_range(sys.argv[i + 1], int(sys.argv[i + 2], 16), int(sys.argv[i + 3], 16))
        sys.exit(0)
    report()
