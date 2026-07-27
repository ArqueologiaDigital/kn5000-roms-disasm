#!/usr/bin/env python3
"""RETRACTION SWEEP -- find claims whose PREMISE has been withdrawn.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  stdlib only.

    python3 dsp/tools/retraction_sweep.py selftest   # ! the CONTROL -- run it first
    python3 dsp/tools/retraction_sweep.py sweep      # the checklist
    python3 dsp/tools/retraction_sweep.py sweep -v   # ... with every COVERED hit too
    python3 dsp/tools/retraction_sweep.py code       # the SHIPPED-CODE assertions

WHY THIS EXISTS.  Three times in this project a claim has outlived the model it
was proved in -- twice in prose and once inside a solver.  The most expensive
instance: MAME's ALU predicate had a class guard, a routing guard and an
operation guard and NO FORMAT guard, so `C00.A.47.407' -- the frame terminator --
was executed as a class-A multiply-and-store, and 62 delay-RAM words ran as
arithmetic.  The premise ("class4 selects the DRAM family") had been withdrawn;
nobody propagated it into the predicate.

WHAT IT DOES.  It is a PROPAGATION checker, not a truth oracle.  For each
premise known to be withdrawn it holds (a) SIGNATURE patterns that indicate a
document is ASSERTING the claim and (b) BANNER patterns that indicate the same
document is RETRACTING it.  A signature hit with no banner within WINDOW lines
is reported LIVE: a place where the retraction was never propagated.

WHAT IT IS NOT.  A LIVE verdict is a PROMPT TO READ THE LINE, not a proof the
line is wrong -- the classifier is textual and cannot understand a sentence.
Read every LIVE hit before acting on it.  `selftest' exists because a checker
that cannot report BOTH outcomes is worthless: it runs planted assertions that
MUST come out LIVE and planted retractions that MUST come out COVERED, and it
FAILS LOUDLY if either direction stops working.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DSP = os.path.dirname(HERE)
DISASM_REPO = os.path.dirname(DSP)
MAME = os.path.join(os.path.dirname(DISASM_REPO), "kn7000_mame")
NOTES = os.path.join(MAME, "notes")
DEVICE = os.path.join(MAME, "src", "devices", "cpu", "upd6383")

WINDOW = 3              # lines either side searched for a retraction banner
FILE_BANNER_LINES = 90  # head of a file in which a WHOLE-FILE banner counts

# --------------------------------------------------------------------------
#  The BANNER vocabulary -- how this project marks a claim as dead.
#  House style is to retract in place, visibly, so these words are the signal.
# --------------------------------------------------------------------------
BANNER = re.compile(
    r"withdraw|withdrew|falsif|retract|supersed|no longer|"
    r"does not survive|did not survive|was wrong|is wrong|"
    r"not origin-free|corrected|demote|old reading|the old '|"
    r"cannot be|is FALSE|now false|is not a property|dead|"
    r"CAUTION|WRONG|✘|⚠",
    re.I)

# --------------------------------------------------------------------------
#  THE RETRACTED PREMISES.
#  `retracted_by' is the pass that killed it and MUST cite where.
#  `sig' asserts the claim; `exempt' is signature text that is really a
#  retraction phrasing and must never count as an assertion.
# --------------------------------------------------------------------------
PREMISES = [
    dict(
        id="P1",
        claim="`ldptr' (lo12 = 0x821) loads the D-RAM OPERAND POINTER; "
              "origin unit 0 = 0x70, unit 1 = 0x50",
        retracted_by="K3 -- dsp/analysis/k3-pointers.md sect. 4 (FORCED): 0x821 "
                     "addresses the COEFFICIENT space",
        sig=[r"origin[^.\n]{0,60}0x70",
             r"unit 0[^.\n]{0,30}0x70[^.\n]{0,40}unit 1[^.\n]{0,30}0x50",
             r"via the .?0x821.? register",
             r"0x821[^.\n]{0,60}(data|operand) pointer",
             r"(data|operand) pointer[^.\n]{0,60}0x821"],
        exempt=[r"not the (D-RAM )?(data|operand) pointer",
                r"cannot be the"],
    ),
    dict(
        id="P2",
        claim="`801.0.NN.821' is the COEFFICIENT CURSOR",
        retracted_by="K3 -- k3-pointers.md sect. 4: it is a C-RAM POINTER; the "
                     "cursor is a different register (FORCED)",
        sig=[r"821[^.\n]{0,40}cursor", r"cursor[^.\n]{0,40}\b821\b"],
        exempt=[r"not the (implicit )?(coefficient )?cursor",
                r"neither the cursor"],
    ),
    dict(
        id="P3",
        claim="the two resident effect units get THE TWO HALVES of the 256-word "
              "C-RAM (unit 1 from 0x80)",
        retracted_by="K4 -- dsp/analysis/k4-cursor.md sect. 1, sect. 4: the "
                     "resident table 0x50..0x8B STRADDLES 0x80; unit 1 starts "
                     "at 0x90 and it is a SOFTWARE allocation",
        sig=[r"two halves of the 256-word",
             r"halves of the (256-word )?coefficient RAM",
             r"unit 1'?s? bank base is\s*`?\+?0x80",
             r"coefficient-space base of `?0x80"],
        exempt=[],
    ),
    dict(
        id="P4",
        claim="the output stage's two host-written words carry a LINEAR LEVEL "
              "(x2 / x4)",
        retracted_by="K5 -- dsp/analysis/k5-output-stage.md: they are CALL "
                     "VECTORS (`setvec'); a disconnected unit goes SILENT, it is "
                     "not attenuated by 6/12 dB",
        sig=[r"[x×]2\s*/\s*[x×]4",
             r"linear level",
             r"exact [x×]2 ?/ ?[x×]4 pair"],
        exempt=[r"not a linear level"],
    ),
    dict(
        id="P5",
        claim="`hi12 == 0xC40' = ENVELOPE / LEVEL DETECTOR",
        retracted_by="K5 -- k5-output-stage.md sect. 2.3: wrong on ALL 61 sites; "
                     "the family is a 13-bit IMMEDIATE LOAD",
        sig=[r"envelope\s*/?\s*level detector", r"envelope detector"],
        exempt=[],
    ),
    dict(
        id="P6",
        claim="\"the chip has three serial input ports and THIS BOARD USES ONE "
              "STEREO PAIR\"",
        retracted_by="dsp-audiopath-wiring.md sect. 1.1, sect. 2 (MEASURED from "
                     "the service manual): ALL THREE DI and ALL THREE DO are "
                     "wired.  K6 finding 6 re-derives the two-channel "
                     "CONCLUSION on sound evidence -- the conclusion survives, "
                     "this REASON does not",
        sig=[r"one stereo pair"],
        exempt=[],
    ),
    dict(
        id="P7",
        claim="the input stage splits 6 + 6 (I-RAM 0..5 / 6..11)",
        retracted_by="K6 finding 2 (MEASURED): the split is 0..6 / 7..11 = 7 + 5",
        sig=[r"0\.\.5\s*/\s*6\.\.11", r"\b6\s*\+\s*6\b"],
        exempt=[],
    ),
    dict(
        id="P8",
        claim="the delay-DRAM family is selected by class4 == 1 WITHOUT a "
              "C-format guard",
        retracted_by="the adjudication -- dsp/analysis/isa-adjudication.md "
                     "sect. 1 (FORCED): C40.1.80.000 and C40.2.C0.000 are the "
                     "SAME instruction, differing only in bit 8 of the immediate",
        sig=[r"C40\.1\.80\.000[^.\n]{0,80}(class-1|delay-DRAM|DRAM)",
             r"class-1 delay-DRAM words"],
        exempt=[],
    ),
    dict(
        id="P9",
        claim="K6 FINDING 5 -- the I/O window X+0..X+6 is touched by 0 OF THE 38 "
              "BODY IMAGES; X+2 / X+5 are READ AND NEVER WRITTEN",
        retracted_by="dsp/analysis/closure-pointer.md item F (MEASURED): under "
                     "the completed shared-pointer walk 79 OF 79 unit-0 images "
                     "enter the window and 10 of 79 touch an input latch.  "
                     "Finding 5's step 1 was flagged in K6 itself as resting on "
                     "the `801.0.NN.821 = ldptr' reading, which K3 withdrew (P1)",
        sig=[r"0 of 38", r"0 of the 38 body images", r"\b0/38\b",
             r"read and never written", r"READ and NEVER WRITTEN"],
        exempt=[],
    ),
    dict(
        id="P10",
        claim="the FRAME-CLOSURE criterion is FORCED (net pointer displacement "
              "must be 0 mod 256)",
        retracted_by="INHERITS P9.  closure-pointer.md item F: \"the closure "
                     "criterion's own FORCED status does not survive\".  The "
                     "criterion may still be TRUE -- Package B -- but it is no "
                     "longer FORCED, it is CONSISTENT",
        sig=[r"FORCED criterion",
             r"criterion is\s*\*{0,2}FORCED",
             r"closure[^.\n]{0,40}\*{0,2}FORCED",
             r"criterion[^.\n]{0,30}FORCED, not assumed"],
        exempt=[r"does not survive", r"no longer"],
    ),
    dict(
        id="P11",
        claim="`880.1.60.*' / `880.1.20.*' = external-DRAM BRACKET (open/close)",
        retracted_by="R1 -- dsp/analysis/r1-allpass-motif.md sect. 5 (FORCED): "
                     "one is a READ and the other a WRITE; the bracket reading "
                     "was already falsified by the per-frame counts",
        sig=[r"external-DRAM bracket", r"DRAM bracket", r"bracket \(MCC"],
        exempt=[],
    ),
    dict(
        id="P12",
        claim="`hi12' bit 23 = MULTIPLY ENABLE",
        retracted_by="notes/kn5000-dsp-axes.md sect. 2.2: it is the "
                     "CURSOR-FETCH enable -- 18 of the phaser's 20 all-pass "
                     "sections fetch no coefficient and still need gains",
        sig=[r"bit 23 = multiplier", r"bit 23[^.\n]{0,30}multiply enable",
             r"multiply enable"],
        exempt=[r"NOT a multiply enable", r"not a multiply"],
    ),
    dict(
        id="P13",
        claim="the D-RAM pointer DOES NOT RETURN because it is RELOADED EVERY "
              "FRAME from the header",
        retracted_by="INHERITS P1.  With `ldptr' withdrawn NOTHING loads the "
                     "D-RAM pointer, so the non-return is UNEXPLAINED again -- "
                     "and it is exactly the +121 closure residue measured on "
                     "1 130 880 of 1 130 880 frames",
        sig=[r"reloaded every frame", r"reloaded from the header",
             r"it is \*{0,2}reloaded"],
        exempt=[],
    ),
    dict(
        id="P14",
        claim="`lo12 = 0x827' (payloads 0x6C / 0x64) inherits the D-RAM-ORIGIN "
              "slot",
        retracted_by="the adjudication -- isa-adjudication.md sect. 5.1: the "
                     "host's zero-fill lands inside the body's pointer reach in "
                     "0 OF 85 streams (vs 47 of 85 for 0x50/0xD0)",
        sig=[r"0x827[^.\n]{0,60}(origin|inherits)",
             r"(origin|D-RAM-origin)[^.\n]{0,40}0x827"],
        exempt=[r"falsif", r"0 of 85"],
    ),
    dict(
        id="P15",
        claim="the D-RAM ORIGIN is OPEN / UNKNOWN, and the +121 closure residue "
              "is an open DEFECT of the walk model",
        retracted_by="output-stage-decode.md items A/B/D (FORCED) and its "
                     "application on 2026-07-27: the per-unit body base is "
                     "0x05 | (unit << 7), a rebase between the two CALLs is "
                     "FORCED to exist (net(body0) takes 8 values across the 37 "
                     "unit-0 images), and with it performed the residue is 0 on "
                     "1 080 959 of 1 106 880 complete frames and X settles on "
                     "0xFF.  Re-derived host-free before it was applied: the "
                     "reverb reaches all six kernel-named unit-1 indices at "
                     "exactly one origin of 256.  What is STILL open is which "
                     "word, if any, performs the rebase -- not the value",
        sig=[r"D-RAM origin is (OPEN|UNKNOWN)",
             r"origin of the D-RAM (pointer|operand pointer) is (OPEN|UNKNOWN)",
             r"residue is \+?121",
             r"\+121 (residue|closure)"],
        # DELIBERATELY SHORT.  `exempt' DROPS a line before it is classified, so
        # anything put here can never come out COVERED -- and the whole point of
        # this tool is that a retraction must be VISIBLE next to the claim, which
        # is what BANNER checks.  Only the two forms that are not assertions of
        # the premise at all are listed: a line reporting the historical
        # number, and the house retraction opener.
        exempt=[r"was \+?121", r"used to"],
    ),
    dict(
        id="P16",
        claim="the reverb delay-line lengths are the RAW descriptor payloads -- "
              "ROOM REVERB 1's ladder is 127 / 435 / 489 / 183 / 522 and its "
              "pre-delay 4452",
        retracted_by="r3-delaydram.md sect. 5(c): bit 7 of the tag byte is the "
                     "payload's LSB, so EVERY delay length in the tree is HALF "
                     "of what it should be.  ROOM REVERB 1's ladder is "
                     "255 / 869 / 979 / 366 / 1044 and the long head is 8905.  "
                     "Re-derived independently by adjudicate4.py `segments' / "
                     "`schroeder': the descriptor block is a CONTIGUOUS ADDRESS "
                     "PARTITION whose 11 segment lengths are 83 172 356 513 739 "
                     "240 119 247 428 616 360, and the even two-segment sums "
                     "reproduce r3's chain 0 to the digit.  ★ THIS ONE MATTERS "
                     "OPERATIONALLY: a control or an impulse test sized against "
                     "the halved numbers amputates the feedback of every line "
                     "(schroeder-topology.md sect. 3 is the published instance)",
        sig=[r"127[ ,/]+435[ ,/]+489[ ,/]+183[ ,/]+522",
             r"\[127, 435, 489, 183, 522\]",
             r"pre-?delay[^.\n]{0,30}4,?452"],
        exempt=[r"not 127", r"halved", r"HALF of what", r"RETRACT", r"withdraw"],
    ),
    dict(
        id="P17",
        claim="H-DIR -- `SRC == 0x0B' is the delay-DRAM READ -- and its "
              "consequence that 99 of 276 corpus delay-DRAM words (35.9 %) are "
              "reads",
        retracted_by="dram-direction.md item B FORCED the direction FIELD to "
                     "`addr8' bit 6 by exhaustive elimination (SRC reaches zero "
                     "violations in 0 of 64 boolean functions) and "
                     "adjudication-round5.md item D closed the POLARITY "
                     "(0x20/0x30 = READ, 0x60 = WRITE), which SHIPPED to both "
                     "mirrors.  Re-scored against it over all 276 corpus "
                     "delay-DRAM words, H-DIR agrees 111 of 276 = 40.2 % -- "
                     "BELOW CHANCE; the inverted rule gets 59.8 %; and SRC 0x0B "
                     "sits on BOTH sides (49 read words, 50 write words).  The "
                     "replacement census is READ 164 / WRITE 112 / trapping 0.  "
                     "second-dsp-and-ready.md sect. 5; reproduce with "
                     "`python3 dsp/tools/second_dsp.py darkf'",
        sig=[r"99 of 276", r"35\.9 ?%",
             r"SRC ..?0x0B..? ?(is|=|<=>|\u21d4)[^.\n]{0,30}READ"],
        # A line that ASKS for the retirement, or reports the historical
        # number as history, is not an assertion of the premise.  These four
        # phrasings are the ones the two notes that predicted this retirement
        # actually used, and they are listed individually rather than as a
        # blanket so that a future ASSERTION cannot hide behind them.
        exempt=[r"RETIRED", r"RETRACT", r"below chance", r"FALSIFIED",
                r"40\.2", r"111 of 276",
                r"is retired", r"should be retired", r"anti-correlated",
                r"not FORCED", r"falsified"],
    ),
    dict(
        id="P18",
        claim="algorithms 57-60 configure BOTH chips, and {79,88,89,90,91} is "
              "the set of DSP2 algorithms -- so the IC311 population is 95/96",
        retracted_by="second-dsp-and-ready.md sect. 2: an algorithm is IC310's "
                     "iff any of its records carries cmd 0x30, and the split is "
                     "IC311 91 / IC310 9 / both 0 / neither 0.  Algo 57's "
                     "program stream is ONE op-E cmd-0x30 record and its "
                     "parameter stream is FOUR; there is no IC311 traffic in any "
                     "of the nine.  Only five were ever flagged because their "
                     "cmd-0x30 rides on record opcode 3; 57-60's rides on "
                     "opcode 0x0E and parses to nothing.  Reproduce with "
                     "`python3 dsp/tools/second_dsp.py dsp2'",
        sig=[r"57.{0,6}60[^.\n]{0,40}both chips",
             r"configure \*?\*?both\*?\*? chips",
             r"96 valid programs"],
        exempt=[r"FALSIFIED", r"RETRACT", r"corrected", r"is 91", r"91 IC311"],
    ),
    dict(
        id="P19",
        claim="SINGLE DELAY FORCES the BLOCKING read (`land = -1'), 5145/5145 "
              "-- and its re-measured successor 5635/5635",
        retracted_by="adjudication-round7.md items A and D: at the polarity "
                     "adjudication-round5.md item D forced, SINGLE DELAY has NO "
                     "closed executable delay loop at all (both loops cross "
                     "w21..w24, ACTION 0x0D/0x0E), so the count cannot be "
                     "re-scored in ANY window; and the premise it rested on -- "
                     "`the read word's own ACTION consumes the fetched sample' "
                     "-- is false by exhaustive count, 0 of 416 read words "
                     "carry a capture ACTION.  13 of 83 CEILING words argue the "
                     "other way.  Reproduce with `python3 "
                     "dsp/tools/readjudicate7.py windows blockread'",
        sig=[r"5\s?145\s*/\s*5\s?145", r"5\s?635\s*/\s*5\s?635",
             r"blocking read[^.\n]{0,40}FORCED",
             r"FORCED[^.\n]{0,40}blocking read",
             r"land\s*=\s*-1[^.\n]{0,30}FORCED"],
        exempt=[r"FALSIFIED", r"RETRACT", r"withdraw", r"void", r"VOID",
                r"UNRE-SCOREABLE", r"no search", r"cannot be re-scored",
                r"never be quoted", r"stale"],
    ),
    dict(
        id="P20",
        claim="`order = adder' is FORCED, 18 of 18, by three independent "
              "contexts (biquad AND LFO AND SINGLE DELAY)",
        retracted_by="adjudication-round7.md item E: the SINGLE DELAY leg is "
                     "void (its 72 survivors come from a one-cell delay line at "
                     "the reversed polarity, and the block has no scoreable "
                     "loop at the forced one).  biquad AND LFO alone leave "
                     "THREE orders -- act_first 576 / adder 576 / act_last 72 "
                     "of 1224 -- because PARAMETRIC EQ carries no ACTION 0x00 "
                     "word and is blind to the question.  FORCED -> CONSISTENT. "
                     "Reproduce with `python3 dsp/tools/readjudicate7.py adder'",
        sig=[r"order\s*=\s*adder[^.\n]{0,30}FORCED",
             r"FORCED[^.\n]{0,30}order\s*=\s*adder",
             r"18 survivors[^.\n]{0,40}all 18 agree",
             r"all 18 agree"],
        exempt=[r"FALSIFIED", r"RETRACT", r"withdraw", r"CONSISTENT",
                r"void", r"VOID", r"no longer", r"reverts"],
    ),
]

# --------------------------------------------------------------------------
#  The document set.
# --------------------------------------------------------------------------


def doc_set():
    """Every document a future pass might read a claim out of."""
    out = []
    for p in (os.path.join(DSP, "instruction-set.md"),
              os.path.join(DSP, "README.md")):
        if os.path.exists(p):
            out.append(p)
    for sub in ("analysis", "algorithms"):
        d = os.path.join(DSP, sub)
        if os.path.isdir(d):
            out += [os.path.join(d, f) for f in sorted(os.listdir(d))
                    if f.endswith(".md")]
    if os.path.isdir(NOTES):
        out += [os.path.join(NOTES, f) for f in sorted(os.listdir(NOTES))
                if (f.startswith("dsp-") or f.startswith("kn5000-dsp-"))
                and f.endswith(".md")]
    return out


def code_set():
    """The SHIPPED artefacts -- where a stale premise is dangerous, not untidy."""
    out = []
    for f in ("upd6383.cpp", "upd6383.h", "upd6383d.cpp", "upd6383d.h"):
        p = os.path.join(DEVICE, f)
        if os.path.exists(p):
            out.append(p)
    for f in ("dsp_disasm.py", "gen_dsp_disasm.py", "gen_dsp_flowcharts.py"):
        p = os.path.join(HERE, f)
        if os.path.exists(p):
            out.append(p)
    return out


# --------------------------------------------------------------------------
#  ARCHIVAL TRACE files.  These are VERBATIM records of what the disassembler
#  printed on a given day -- per-word frame dumps, trap lists, census tables.
#  A retracted label inside one of them is not a live claim, it is EVIDENCE OF
#  THE BUG, and rewriting it would destroy the record.  They take ONE banner at
#  the top of the file/table, never a per-row edit.  Separated out so the
#  actionable list stays actionable.
# --------------------------------------------------------------------------
TRACE_FILES = {
    "dsp-perframe-execution.md",
    "dsp-audiopath-wired.md",
    "dsp-k6-input-stage-applied.md",
    "dsp-mirror-sync.md",
    "kn5000-dsp-core-draft.md",
}


def is_trace(path):
    return os.path.basename(path) in TRACE_FILES


def rel(path):
    for root, tag in ((DISASM_REPO, "kn5000-roms-disasm"), (MAME, "kn7000_mame")):
        if path.startswith(root):
            return tag + path[len(root):]
    return path


def scan(paths, premises=PREMISES):
    """-> list of (premise, path, lineno, line, covered)."""
    hits = []
    for path in paths:
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                lines = fh.read().splitlines()
        except OSError:
            continue
        for pr in premises:
            sigs = [re.compile(s, re.I) for s in pr["sig"]]
            exempts = [re.compile(s, re.I) for s in pr.get("exempt", [])]

            # ---- A WHOLE-FILE RETRACTION BANNER ------------------------
            # House style is a banner at the top of the document naming the
            # claim it kills.  A reader meets that before any of the prose
            # below it, so it really does cover the file -- but ONLY for the
            # premise it names.  Scanned over the head of the file (a banner
            # buried on page 9 does not warn anybody opening page 2).
            head = lines[:FILE_BANNER_LINES]
            file_bannered = any(BANNER.search(h) and any(s.search(h) for s in sigs)
                                for h in head)

            for i, line in enumerate(lines):
                if not any(s.search(line) for s in sigs):
                    continue
                if any(e.search(line) for e in exempts):
                    continue
                # ---- IS IT RETRACTED IN PLACE? -------------------------
                # ★ A BANNER ONLY COUNTS IF IT IS A BANNER *ABOUT THIS
                # CLAIM*.  The first version of this checker accepted any
                # banner within the window, and it promptly reproduced the
                # exact bug it was built to find: in
                # notes/kn5000-dsp-INDEX.md the sentence `an earlier "4
                # bands" was retracted' sits two lines below the "Roles"
                # bullet and was read as covering `bit 23 = multiplier',
                # `880.1.60/20 = DRAM bracket' and `0xC40 = envelope
                # detector' -- three live assertions of retracted premises,
                # silently marked COVERED by a banner about something else.
                # So: a same-line banner always counts; a NEARBY banner
                # counts only if that line itself names the claim.
                #
                # The classifier is deliberately BIASED TOWARD `LIVE'.  A
                # false LIVE costs one read.  A false COVERED costs an
                # un-propagated retraction -- which is the entire failure
                # mode this tool exists to catch.
                covered = bool(BANNER.search(line)) or file_bannered
                if not covered:
                    lo = max(0, i - WINDOW)
                    hi = min(len(lines), i + WINDOW + 1)
                    for j in range(lo, hi):
                        if j == i:
                            continue
                        near = lines[j]
                        if BANNER.search(near) and any(s.search(near) for s in sigs):
                            covered = True
                            break
                hits.append((pr, path, i + 1, line.strip(), covered))
    return hits


def report(hits, verbose, title):
    live = [h for h in hits if not h[4]]
    cov = [h for h in hits if h[4]]
    print("=" * 78)
    print(title)
    print("=" * 78)
    by = {}
    for h in live:
        by.setdefault(h[0]["id"], []).append(h)
    n_prose = n_trace = 0
    for pr in PREMISES:
        rows = by.get(pr["id"], [])
        if not rows and not verbose:
            continue
        prose = [r for r in rows if not is_trace(r[1])]
        trace = [r for r in rows if is_trace(r[1])]
        n_prose += len(prose)
        n_trace += len(trace)
        print("\n--- %s  %s" % (pr["id"], pr["claim"]))
        print("    RETRACTED BY: %s" % pr["retracted_by"])
        if not rows:
            print("    no un-bannered assertion found.")
        for _, path, ln, line, _ in prose:
            txt = line if len(line) <= 132 else line[:129] + "..."
            print("    LIVE  %s:%d" % (rel(path), ln))
            print("          %s" % txt)
        if trace:
            files = sorted({rel(r[1]) for r in trace})
            print("    trace-only (%d rows in archival dumps -- ONE banner per "
                  "file, never per row):" % len(trace))
            for f in files:
                print("          %s" % f)
    print("\n%s" % ("-" * 78))
    print("TOTAL: %d signature hits, %d LIVE, %d covered" % (len(hits), len(live), len(cov)))
    print("       of the LIVE: %d in PROSE (actionable), %d in ARCHIVAL TRACES"
          % (n_prose, n_trace))
    if verbose and cov:
        print("\nCOVERED (a banner is adjacent -- listed for audit):")
        for pr, path, ln, line, _ in cov:
            txt = line if len(line) <= 110 else line[:107] + "..."
            print("    %-4s %s:%d  %s" % (pr["id"], rel(path), ln, txt))
    return len(live)


# --------------------------------------------------------------------------
#  THE CONTROL.  A checker that cannot say BOTH things is not a checker.
# --------------------------------------------------------------------------
POSITIVE = [
    ("P1",  "The data-pointer ORIGIN is unit 0 = 0x70, unit 1 = 0x50."),
    ("P5",  "This word is the envelope / level detector (INFERRED)."),
    ("P6",  "the chip has three ports and this board uses one stereo pair"),
    ("P9",  "Simulated for all 38 images: 0 of 38 touch any of X+0..X+6"),
    ("P10", "FRAME CLOSURE (FORCED criterion: the DI latches are fixed)"),
    ("P11", "880.1.60/20.* = external-DRAM bracket (MCC +0.944)"),
    ("P13", "The pointer does not return -- it is reloaded every frame."),
    ("P15", "The D-RAM origin is OPEN, so the pointer moves only by post-increment."),
]
NEGATIVE = [
    ("P1",  "K3 WITHDREW the reading that 0x821 is the data pointer."),
    ("P5",  "the old 'envelope detector' reading is WITHDRAWN -- C40 is an immediate"),
    ("P6",  "FALSIFIED: \"this board uses one stereo pair\" -- all three DI are wired"),
    ("P9",  "0 of 38 was MEASURED under an origin model K3 has since withdrawn"),
    ("P11", "the external-DRAM bracket reading is FALSIFIED by the per-frame counts"),
    ("P15", "the D-RAM origin is OPEN -- WITHDRAWN, it is PINNED at 0x05 | (unit << 7)"),
]


def selftest():
    import tempfile
    ok = True
    print("=" * 78)
    print("SELFTEST -- the harness must be able to say LIVE *and* COVERED")
    print("=" * 78)

    def run(rows, want_live, label):
        nonlocal ok
        for pid, text in rows:
            pr = [p for p in PREMISES if p["id"] == pid][0]
            with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as fh:
                fh.write("padding\npadding\n%s\npadding\npadding\n" % text)
                tmp = fh.name
            hits = scan([tmp], [pr])
            os.unlink(tmp)
            if not hits:
                print("  FAIL %s  %-8s signature did NOT match: %s"
                      % (label, pid, text[:56]))
                ok = False
                continue
            got_live = not hits[0][4]
            good = (got_live == want_live)
            print("  %s %s  %-4s -> %s   %s"
                  % ("ok  " if good else "FAIL", label, pid,
                     "LIVE   " if got_live else "COVERED", text[:52]))
            if not good:
                ok = False

    run(POSITIVE, True, "assert ")
    run(NEGATIVE, False, "retract")
    print("\nSELFTEST %s" % ("PASSED -- both directions work"
                             if ok else "*** FAILED ***"))
    return 0 if ok else 1


def main():
    argv = sys.argv[1:]
    cmd = argv[0] if argv else "sweep"
    verbose = "-v" in argv or "--verbose" in argv
    if cmd == "selftest":
        return selftest()
    if cmd == "code":
        hits = scan(code_set())
        n = report(hits, verbose,
                   "SHIPPED CODE -- a stale premise here is DANGEROUS, not untidy")
        print("\nNOTE: comments in the device legitimately QUOTE a withdrawn claim "
              "in order\n      to retract it.  Every LIVE hit above must be read "
              "before it is believed.")
        return 0
    if cmd in ("sweep", "docs"):
        hits = scan(doc_set())
        report(hits, verbose, "DOCUMENTS -- claims whose PREMISE has been retracted")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
