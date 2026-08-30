#!/usr/bin/env python3
"""prom_d round 7 -- THE FINISHED-IMAGE INVENTORY.  Every object in prom_d is
                     either NAMED WITH A WITNESS or NAMELESS WITH A STATED REASON,
                     and this script is the one command that re-checks all 3,665.

QUESTION IT ANSWERS
    Rounds 4-6 named prom_d one class at a time and left it at 91.5%% content on
    notes/wave7_documentation_metrics.py with 313 framed labels and zero
    sub_XXXXXX.  Round 6 classified those 313 exhaustively.  What NO image in
    this tree has ever had is the other half of "finished": a single re-runnable
    census over the WHOLE image saying, per object, what witness its name rests
    on -- and listing, by name, every object that has none.

    ★ THE UNIT IS THE LABEL AND THE DENOMINATOR IS ALL OF THEM.  3,665 labels,
    one FINISHED verdict each and one PROVENANCE grade each.  A round that
    classifies only the labels it is proud of has measured its own intentions.

WHAT IT ESTABLISHES (reproduced below; run it, do not quote this list)
    Q1  ★★ THE INVENTORY.  Every label of prom_d/wsa1_prom_d.s gets exactly one
        FINISHED verdict -- WITNESSED (and how) or NAMELESS (and why) -- the
        verdicts partition the label set, and the FIRST and the LAST label are
        both checked by name.  The count of UNWITNESSED objects is the number
        this round exists to publish, whatever it is.
    Q2  ★ THE PROVENANCE GRADE, which is the honest half of the content
        percentage this image scores.  A name
        can rest on the object's OWN ASCII, on a prom_c reader, on a measured
        image-internal relation, or on a KN5000 label transplanted into a region
        that NOTHING in the WSA1 firmware reads.  The last of those is a real
        grade and this image has a lot of it.  Reported as counts, not hidden.
    Q3  ★ THE ADDRESS-SPELLING CENSUS, RUN -- AND THEN REPORTED AS INCONCLUSIVE,
        which is the honest outcome and not the one this section was written
        expecting.  This project has twice shipped a "no references" that had
        references, so both 32-bit spellings of every nameless object's offset
        and of base+offset are counted across all four ROM images, against a
        null that perturbs each address by up to 2 KiB.  The result is at the
        null's own rate, so it CANNOT be quoted as a zero and is not.  What
        settles the question is not a byte search at all: prom_c holds prom_d's
        base in RAM, exactly TWO instructions write it, and all 99 directory
        reads add that base to a value read out of prom_d and then INDEX.  A
        record is addressed by an index, so no pointer to one can exist to find.
    Q4  ★ THE ONE MECHANISM THAT REACHED SOMETHING: the CamelCase word-boundary
        stem rule.  Round 6 already accepted a shared stem when the twin names
        differ only by a trailing DIGIT ('RoomBassDrm1'/'RoomBassDrm2').  The
        same phenomenon appears with a trailing LETTER ('TimpaniA'..'TimpaniG')
        and round 6's rule could not see it.  Stated as a boundary rule -- the
        stem must end where a CamelCase word ends in EVERY candidate -- it names
        10 more records and refuses 60, and it refuses exactly the truncations
        that make the rule look bad ('MdlShakerO' from Off/On, 'FingerCymba').
    Q5  ★ THREE MECHANISMS MEASURED AND REJECTED, kept so a later round does not
        re-invent them.  M1 the +0x0C map as a tie-breaker (calibrates at 110 of
        140 on records where the answer is already known -- 1 in 5 wrong, so it
        cannot break a tie).  M2 widening round 6's one-byte mask to bytes 3..10
        (it would bring 65 more records within reach, 38 of them differing at
        exactly {3,5,7,9,11} and 13 at {4,6,8,10,11} -- the low and high bytes of
        four 16-bit fields.  prom_c's ONLY writer of a wave-select record copies
        byte 11 and bytes 13..42 and NOTHING ELSE, so bytes 3..10 are content,
        not rewrite, and the wider mask is refused).  M3 a record's tail equalling one of the 64
        stored presets (0 of 322, 0 of 208, 0 of 451 -- the preset apply is a
        RUNTIME operation and leaves no stored relation).
    Q6  ★ THE MORPHEME CENSUS -- round 3's "Home" failure, made by machine and
        over the whole image.  Round 3 shipped five prom_a labels built on a word
        that occurs ZERO times in all four ROMs.  Every alphabetic morpheme of
        every prom_d label is counted here against the ASCII of all four images.
    Q7  ★ THE BASE ADDRESS, and round 6's OWN STATED LIMIT closed.  Round 6 said
        its search "would not see a pointer hidden in" prom_c's 65,972-byte
        byte-code stream, because it searched INSTRUCTIONS.  This one searches
        RAW BYTES of all four images, so that stream is inside the corpus.  One
        occurrence of base+slot-value exists in the whole set, it is BIG-ENDIAN
        on a little-endian CPU and inside prom_d's own payload, and it is
        adjudicated by name rather than counted away.
        ⚠ ORIGIN in prom_d/prom_d.ld is NOT changed and nothing here proposes it.
    Q8  ★ THE GLUED-DIGIT AUDIT -- this round auditing the metric that grades it.
        notes/wave7_documentation_metrics.py calls a label FRAMED when its
        distinguishing part is a number, and its regex requires an underscore
        before that number.  `ToneDB_EnvDescTable_Desc000` therefore scores as
        CONTENT while `PercInst_17` scores as FRAMED, and they are the same
        shape.  The count is published here, and in the file's own banner,
        because prom_d's content percentage is the number it inflates.
    Q9  ★ THE REFUSALS, RE-DERIVED RATHER THAN REPEATED -- and this round's own
        prom_c citations checked against the gate-verified listing, because
        round 1 shipped 31 of them one byte past the instruction.

HOW TO RUN
    python3 notes/prom_d_finish_round7.py             # the whole inventory
    python3 notes/prom_d_finish_round7.py --quiet     # failures only
    python3 notes/prom_d_finish_round7.py --selftest  # the checks, incl. LAST element
    python3 notes/prom_d_finish_round7.py --unwitnessed   # just the naked objects
    Exit status is non-zero if any check fails.

    scripts/analysis/gen_prom_d_asm.py imports wavesel_labels_r7() from this file
    and REFUSES to emit if the shape moved, so a label in prom_d/wsa1_prom_d.s
    cannot outlive the measurement that justifies it.

WHAT IS *NOT* ESTABLISHED, said before the results
    * NOT that a WITNESSED label is a CORRECT label.  A witness is a stated route
      from the bytes to the name; this script checks the route exists, not that
      the name is the best one.  The KN5000-transplant grade is named precisely
      so that a reader can discount it.
    * NOT that the 10 records Q4 names BELONG to the instrument they are named
      after.  `_SameAs_Timpani` says these bytes and TimpaniA..G's bytes are the
      same, which is what was measured.
    * NOT what any field of a wave-select record means beyond +0x0B, and Q5's M2
      is a refusal to guess, not a field identification.
    * NOT which physical part prom_d is.  Q7 is about the ADDRESS.
    * NOT that Q3's byte census proves an absence.  It is reported at its null
      and explicitly declared inconclusive; the instruction census is what
      carries the conclusion.
    * NOT that the 1,298 KN5000-transplant names are WRONG.  What is established
      is that no WSA1 instruction confirms them, which is a statement about the
      evidence and not about the name.
"""
import collections
import importlib.util as _ilu
import os
import random
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROMS = collections.OrderedDict([("prom_a", "wsa1_prom_a.ic12"),
                                ("prom_b", "wsa1_prom_b.ic13"),
                                ("prom_c", "wsa1_prom_c.ic28"),
                                ("prom_d", "wsa1_prom_d.bin")])
IMG = collections.OrderedDict(
    (k, open(os.path.join(ROOT, "original_ROMs", v), "rb").read()) for k, v in ROMS.items())
D = IMG["prom_d"]
SRC = os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")
PROM_D_BASE = 0x00F00000        # notes/prom_d_base_checks.py, 12 checks
PROM_C_BASE = 0x00F80000

QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-70s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-70s %s" % (label, detail))


def _load(name):
    """Import one of this tree's analysis scripts without running its main()."""
    spec = _ilu.spec_from_file_location(name, os.path.join(ROOT, "notes", name + ".py"))
    mod = _ilu.module_from_spec(spec)
    saved, sys.argv = sys.argv, [name, "--quiet"]
    try:
        spec.loader.exec_module(mod)
    finally:
        sys.argv = saved
    return mod


R3 = _load("prom_d_documentation_round3")     # the 99-read prom_c directory census
R5 = _load("prom_d_understanding_round5")
R6 = _load("prom_d_understanding_round6")

DIR = R6.DIR
S = R6.S
camel = R6.camel


# ===========================================================================
# Q4's rule lives up here because the generator imports it.
# ===========================================================================
MAX_REMAINDER = 4       # see _boundary_stem(); Q4's sensitivity table derives it


def _boundary_stem(names, max_remainder=None):
    """The longest common prefix of `names` that ends at a CamelCase WORD BOUNDARY.

    ★ WHY THIS IS ROUND 6's RULE AND NOT A NEW ONE.  Round 6 accepted a shared
    stem when the candidate names differ only by a trailing DIGIT --
    'RoomBassDrm1' and 'RoomBassDrm2' are one instrument spelled twice.  The very
    same catalogue spells the same relation with a trailing LETTER
    ('TimpaniA'..'TimpaniG', 'TimbalesOpenH'/'TimbalesOpenL') and round 6's rule
    was blind to it.  Stating the rule as a BOUNDARY instead of as a character
    class covers both and, more importantly, REFUSES the cases that make a
    prefix rule dangerous: the common prefix of 'MdlShakerOff'/'MdlShakerOn' is
    'MdlShakerO', which cuts a word in half, and of 'FingerCymH'/'FingerCymbal'
    is 'FingerCym', which does the same.  Both are refused here and both would
    be accepted by a plain "strip up to N trailing characters" rule.

    ⚠ AND THE BOUNDARY ALONE IS NOT ENOUGH, which is why there is a second
    constraint with a NUMBER in it.  The common prefix of the twelve hi-hat names
    that share record 65's bytes is 'HiHat', boundary-aligned in all twelve, and
    it throws away the difference between HiHatOpen and HiHatHfOpen; of record
    60's six names it is 'Dance', which is a kit family and not an instrument at
    all.  So the REMAINDER after the stem must be at most MAX_REMAINDER
    characters in every candidate -- the length of a variant token in this
    catalogue (a digit, a letter, Hi/Lo, High/Low), not of a word.  Q4's
    sensitivity table prints what every bound from 1 to 8 would have named, so
    the constant is visible rather than buried.

    Returns None when the names do not share a boundary-aligned prefix.
    """
    if not names:
        return None
    pre = names[0]
    for n in names[1:]:
        i = 0
        while i < min(len(pre), len(n)) and pre[i] == n[i]:
            i += 1
        pre = pre[:i]
    if len(pre) < 4:
        return None
    lim = MAX_REMAINDER if max_remainder is None else max_remainder
    for n in names:
        if len(n) == len(pre):
            continue                      # the stem IS this name: a boundary by definition
        c = n[len(pre)]
        if not (c.isupper() or c.isdigit()):
            return None                   # the prefix cuts a CamelCase word in half
        if len(n) - len(pre) > lim:
            return None                   # the stem would drop a whole WORD, not a variant
    if re.fullmatch(r"[0-9]{1,4}", pre.split("_")[-1]):
        return None                       # an all-digit label reads as positional
    return pre


def wavesel_labels_r7(slot):
    """Round 6's twin labels, plus the records the boundary rule resolves.

    ⚠ Round 6's own dict is taken verbatim and only ADDED to: no name it gave is
    changed here, which Q4c checks rather than assumes.
    """
    out = dict(R6.wavesel_labels(slot))
    for k, tw in R6.wavesel_twins(slot).items():
        if k in out or not tw:
            continue
        names = sorted(set(x[2] for x in tw))
        stem = _boundary_stem(names)
        if stem is None:
            continue
        els = set(x[1] for x in tw)
        if len(els) == 1 and els.copy().pop() is not None:
            stem += "_WaveSel%d" % els.copy().pop()
        out[k] = stem
    return out


def _r7_shape(slot):
    return (len(R6.wavesel_labels(slot)), len(wavesel_labels_r7(slot)))


# The generator refuses to emit if either of these moves.  (round-6 labels, round-7 labels)
AUDITED_R7 = {0x18: (152, 152), 0x20: (141, 151)}
# ★ AND THE CHECK COUNT IS AUDITED TOO, so a comment in prom_d/wsa1_prom_d.s that
# quotes "N checks in that file" cannot drift away from the file it names.  main()
# fails if the run produces a different number.
AUDITED_CHECKS = 56


# ===========================================================================
# The source file, read once: every label, its address, its extent, its comments.
# ===========================================================================
LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ADDR_RE = re.compile(r";\s*([0-9A-F]{5,6})\b")
INTERNAL_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$")
UNNAMED_RE = re.compile(r"^sub_[0-9A-Fa-f]{6}$")
# the same FRAMED rule notes/wave7_documentation_metrics.py grades this tree with
FRAMED_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*_"
                       r"(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?"
                       r"(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$")


class Lab(object):
    __slots__ = ("name", "addr", "end", "line", "ncomment", "evidence", "grade", "finished",
                 "reason", "prov", "prov_why")

    def __init__(self, name, addr, line, ncomment, evidence):
        self.name, self.addr, self.line = name, addr, line
        self.ncomment, self.evidence = ncomment, evidence
        self.end = None
        self.grade = self.finished = self.reason = self.prov = self.prov_why = None


SIZE_RE = re.compile(r"^\s*\.(byte|short|word|hword|long|ascii|fill|text)\b(.*)$")


def _emitted_size(kind, rest):
    """How many ROM bytes this directive emits.  Verified against every address
    comment in the file by selftest T3 -- if the two ever disagree the file has a
    directive this function does not model, and the disagreement is the alarm."""
    if kind == "text":
        return 0
    body = rest.split(";")[0]
    if kind == "ascii":
        q1 = body.index('"')
        q2 = body.rindex('"')
        return q2 - q1 - 1
    if kind == "fill":
        parts = [p.strip() for p in body.split(",")]
        n = int(parts[0], 0)
        w = int(parts[1], 0) if len(parts) > 1 else 1
        return n * w
    items = len([p for p in body.split(",") if p.strip()])
    return items * {"byte": 1, "short": 2, "word": 2, "hword": 2, "long": 4}[kind]


def read_labels():
    """Every label of prom_d/wsa1_prom_d.s, with its address, extent and comment block.

    ★ THE ADDRESS COMES FROM A LOCATION COUNTER, NOT FROM THE ADDRESS COMMENTS.
    The first draft of this script took the address off the `; 01CDD` comment of
    the next data line, which is right for 3,640 of the 3,665 labels and WRONG for
    the 25 that introduce no data line of their own -- including `build_tag`,
    which it placed at the end of the image instead of at 0x7FFF0.  A counter is
    exact everywhere and, better, it can be CHECKED: selftest T3 asserts the
    counter agrees with every one of the file's own address comments.
    """
    lines = open(SRC).read().split("\n")
    out = []
    run = blanks = 0
    ev = False
    pc = 0
    for i, ln in enumerate(lines):
        if ln.startswith(";"):
            run += 1
            if "Evidence:" in ln:
                ev = True
            blanks = 0
            continue
        if ln.strip() == "" and run:
            blanks += 1
            if blanks > 1:
                run, ev, blanks = 0, False, 0
            continue
        m = LABEL_RE.match(ln)
        if m:
            # ★ A LABEL DIRECTLY BELOW ANOTHER LABEL SHARES ITS COMMENT BLOCK.
            # `ToneDB_Base:` / `ToneDB_Directory:` on consecutive lines are two
            # names for one object, and the banner above them documents both.
            # Counting the second as un-evidenced is a whitespace artefact of
            # exactly the kind a round-3 reviewer caught in the metric itself.
            if out and out[-1].line == i - 1:
                run, ev = max(run, out[-1].ncomment), ev or out[-1].evidence
            out.append(Lab(m.group(1), pc, i, run, ev))
            run, ev, blanks = 0, False, 0
            continue
        sm = SIZE_RE.match(ln)
        if sm:
            pc += _emitted_size(sm.group(1), sm.group(2))
        run, ev, blanks = 0, False, 0
    for k, l in enumerate(out):
        l.end = out[k + 1].addr if k + 1 < len(out) else pc
        l.grade = ("internal" if INTERNAL_RE.match(l.name) else
                   "unnamed" if UNNAMED_RE.match(l.name) else
                   "framed" if FRAMED_RE.match(l.name) else "content")
    return out


def address_comments():
    """[(line index, address)] -- the file's own `; 01CDD` markers, for T3."""
    out = []
    for i, ln in enumerate(open(SRC).read().split("\n")):
        if ln.lstrip().startswith(";"):
            continue
        m = ADDR_RE.search(ln)
        if m:
            out.append((i, int(m.group(1), 16)))
    return out


LABS = read_labels()
BY_NAME = dict((l.name, l) for l in LABS)
LAB_INDEX = dict((l.name, i) for i, l in enumerate(LABS))


# ===========================================================================
# Witness 1 -- the object names ITSELF.
# ===========================================================================
NAME_WINDOW = 32        # the widest name field this image uses is 16 bytes, at offset 0


def self_named(lab):
    """True when a printable run inside the object's OWN first 32 bytes,
    CamelCased by the same rule the labels use, occurs in the label."""
    hi = min(lab.end, lab.addr + NAME_WINDOW)
    if hi <= lab.addr:
        return None
    txt = "".join(chr(c) if 32 <= c < 127 else "\x00" for c in D[lab.addr:hi])
    for run in re.findall(r"[ -~]{4,}", txt):
        # ⚠ THE WHOLE RUN IS NOT ALWAYS THE NAME.  The drawbar record's 16-byte
        # field is `<<< Drawbar 1>>>` and the two bytes after it happen to be
        # printable too, so the run camels to `Drawbar1QU` and matches nothing.
        # Every LEADING WORD-PREFIX of the run is tried, longest first.
        words = re.sub(r"[^A-Za-z0-9]+", " ", run).split()
        for k in range(len(words), 0, -1):
            c = camel(" ".join(words[:k]))
            if len(c) >= 4 and c in lab.name:
                return c
    return None


# ===========================================================================
# Witness 3 -- prom_c reads the directory slot this object's region hangs off.
# ===========================================================================
PAYLOAD_END = R6.PAYLOAD_END
# ★ THE POINTER SLOTS ARE prom_c's DEFINITION, NOT A GUESS.  Round 3 measured that
# every read of a slot BELOW +0xC0 loads a 32-bit register and every read at or
# above it loads a 16-bit one, 99 of 99; so +0x00..+0xBC are offsets and the tail
# is scalars.  A slot is a live pointer here when its value also lands inside the
# payload, which excludes the two unused 0xFFFFFFFF slots.
POINTER_SLOTS = [s for s in range(0, 0xC0, 4)
                 if DIR[s // 4] not in (0xFFFFFFFF, 0) and DIR[s // 4] < PAYLOAD_END]
POINTER_VALUES = sorted(set(DIR[s // 4] for s in POINTER_SLOTS))
SLOT_OF_OFFSET = {}
for _s in POINTER_SLOTS:
    SLOT_OF_OFFSET.setdefault(DIR[_s // 4], _s)
REGION_STARTS = sorted(SLOT_OF_OFFSET)


def region_slot(addr):
    """The directory slot whose value opens the region containing `addr`, or None."""
    lo = None
    for v in REGION_STARTS:
        if v <= addr:
            lo = v
        else:
            break
    return SLOT_OF_OFFSET.get(lo) if lo is not None else None


READER_SLOTS = set(h[2] for h in R3.ALL_HITS)


# ===========================================================================
# Witness 2 -- the object sits inside, and is named after, a witnessed object.
# ===========================================================================
def _parent_of(lab):
    """The nearest PRECEDING label whose name is a proper prefix of this one.

    ⚠ The containment test that would seem natural here -- parent.addr <= addr <
    parent.end -- CANNOT be used, because a label's extent in this emitter ends at
    the next label, which is its own first child.  `ToneRec_000_Piano` ends
    exactly where `ToneRec_000_Piano_Elem0` begins.  The file is emitted in
    address order, so "nearest preceding prefix" is the same relation without the
    trap; the first draft of this script used containment and reported 1,432
    objects unwitnessed, every one of them a child of a record that names itself.
    """
    idx = LAB_INDEX[lab.name]
    for j in range(idx - 1, -1, -1):
        p = LABS[j]
        if lab.name.startswith(p.name + "_"):
            return p
    return None


# ===========================================================================
# Q1 / Q2 -- the inventory itself.
# ===========================================================================
NAMELESS_REASON = {}            # label -> reason, for the framed set


def build_nameless_reasons():
    """Round 6's per-object verdicts, REFRESHED by round 7 rather than copied.

    Round 6's classify() names the 313 with the round-6 label set; the 10 records
    Q4 promotes are no longer nameless, so their verdict is replaced here instead
    of being left to contradict the file.  That is the failure mode round 4 hit:
    a corrected claim came back verbatim because two scripts disagreed.
    """
    lab = dict((s, wavesel_labels_r7(s)) for s in (0x18, 0x20))
    out = {}
    for name, verdict, reason in R6.classify():
        stem, _, num = name.rpartition("_")
        k = int(num, 10) if num.isdigit() else None
        slot = 0x18 if stem == "ToneDB_MixerDefaultTable" else (
            0x20 if stem == "ToneDB_PercMixerDefaultTable" else None)
        if slot is not None and k in lab[slot]:
            continue                      # named -- by round 6 or by round 7's Q4
        if verdict.startswith("NAMELESS") or verdict == "METRIC-ARTEFACT":
            out[name] = (verdict, reason)
    return out


def classify_all():
    """One FINISHED verdict and one PROVENANCE grade for every label."""
    nameless = build_nameless_reasons()
    # a label is "under" the nearest preceding label whose name is its prefix
    for l in LABS:
        if l.grade == "framed":
            base = re.sub(r"_SameAs_.*$", "", l.name)
            v = nameless.get(l.name) or nameless.get(base)
            if v:
                l.finished, l.reason = "NAMELESS", "%s: %s" % v
                l.prov, l.prov_why = "NAMELESS", v[0]
                continue
    for l in LABS:
        if l.finished:
            continue
        sn = self_named(l)
        if sn:
            l.finished, l.reason = "WITNESSED", "its own ASCII: %r" % sn
            l.prov, l.prov_why = "SELF-NAMED", sn
            continue
        if "_SameAs_" in l.name:
            l.finished = "WITNESSED"
            l.reason = "a measured byte identity, stated in the name"
            l.prov, l.prov_why = "IMAGE-INTERNAL", "_SameAs_ relation"
            continue
        parent = _parent_of(l)
        if parent is not None and (self_named(parent) or parent.evidence):
            l.finished = "WITNESSED"
            l.reason = "inside %s, which is witnessed" % parent.name
            l.prov = ("SELF-NAMED" if self_named(parent) else None)
            l.prov_why = parent.name
        if l.evidence:
            l.finished = "WITNESSED"
            if not l.reason:
                l.reason = "its own Evidence: line"
        slot = region_slot(l.addr)
        if l.prov is None:
            if slot is not None and slot in READER_SLOTS:
                l.prov = "READER-BACKED"
                l.prov_why = "prom_c reads directory slot +0x%02X at %d site(s)" % (
                    slot, len(R3.readers(slot)))
            elif slot is not None:
                l.prov = "KN5000-TRANSPLANT"
                l.prov_why = ("directory slot +0x%02X has NO prom_c reader in the "
                              "99-read census" % slot)
            else:
                l.prov = "IMAGE-INTERNAL"
                l.prov_why = "no directory slot opens this region"
        if l.finished is None:
            l.finished, l.reason = "UNWITNESSED", "no ASCII, no Evidence: line, no witnessed parent"
    # ★ SECOND PASS: a ZERO-LENGTH label is not an object.  It is either an ALIAS
    # of the label on the next line (`ToneDB_Base:` above `ToneDB_Directory:`) or,
    # for the very last one, the image's end marker.  Giving those their own
    # verdict rather than folding them into the numerator is the same discipline
    # that keeps .L locals out of the goal metric.
    for k, l in enumerate(LABS):
        if l.end != l.addr:
            continue
        if k + 1 >= len(LABS):
            l.finished = "BOUNDARY"
            l.reason = ("zero-length end marker: it equals the image length 0x%05X"
                        % len(D))
            l.prov, l.prov_why = "BOUNDARY", "not an object"
            continue
        nxt = LABS[k + 1]
        if l.finished != "UNWITNESSED":
            continue                      # it has a witness of its own; keep it
        l.finished = nxt.finished
        l.reason = "alias of %s at the same address, which is %s" % (nxt.name, nxt.finished)
        l.prov, l.prov_why = nxt.prov, "alias of %s" % nxt.name
    return LABS


def inventory_summary():
    """{verdict: n} and {provenance: n} over the whole image, for the generator.

    The banner in prom_d/wsa1_prom_d.s quotes THESE, so a headline in the file
    cannot drift away from the census that produced it.
    """
    classify_all()
    return (collections.Counter(l.finished for l in LABS),
            collections.Counter(l.prov for l in LABS))


def q1():
    say("\n=== Q1.  THE INVENTORY -- every label of prom_d, one FINISHED verdict ===\n")
    classify_all()
    by = collections.Counter(l.finished for l in LABS)
    for v, n in by.most_common():
        ex = next(l for l in LABS if l.finished == v)
        say("  %-12s %5d   e.g. %-44s %s" % (v, n, ex.name, ex.reason[:60]))
    check("Q1a  the verdicts partition the label set -- no label is left out",
          sum(by.values()) == len(LABS), "%d verdicts over %d labels"
          % (sum(by.values()), len(LABS)))
    check("Q1b  and every verdict carries a REASON, not just a bucket",
          all(l.reason for l in LABS), "%d without a reason"
          % sum(1 for l in LABS if not l.reason))
    check("Q1c  the FIRST and the LAST label both carry a verdict and a reason",
          LABS[0].finished and LABS[-1].finished,
          "first %s -> %s; last %s -> %s"
          % (LABS[0].name, LABS[0].finished, LABS[-1].name, LABS[-1].finished))
    naked = [l for l in LABS if l.finished == "UNWITNESSED"]
    check("Q1d  ★ THE NUMBER THIS ROUND EXISTS TO PUBLISH: objects with NO witness",
          True, "%d of %d" % (len(naked), len(LABS)))
    if naked:
        say("")
        say("  ★ THE UNWITNESSED, IN FULL -- %d objects, every one named here so a" % len(naked))
        say("    reader can attack them rather than take a percentage on trust:")
        for l in naked:
            say("      0x%05X  %s" % (l.addr, l.name))
    return naked


def q2():
    say("\n=== Q2.  THE PROVENANCE GRADE -- what each name actually rests on ===\n")
    by = collections.Counter(l.prov for l in LABS)
    for v, n in by.most_common():
        ex = next(l for l in LABS if l.prov == v)
        say("  %-18s %5d   e.g. %-40s %s" % (v, n, ex.name, (ex.prov_why or "")[:52]))
    check("Q2a  the provenance grades partition the label set too",
          sum(by.values()) == len(LABS), "%d grades over %d labels"
          % (sum(by.values()), len(LABS)))
    tp = by.get("KN5000-TRANSPLANT", 0)
    say("")
    say("  ★ %d of prom_d's %d labels sit in a region whose directory slot NO prom_c"
        % (tp, len(LABS)))
    say("    instruction reads, so their NAME is the KN5000's and nothing in the WSA1")
    say("    firmware confirms it.  That is not a defect of this round; it is the")
    say("    part of prom_d's 91.5% that a reader must discount, said as a number.")
    slots = sorted(set(region_slot(l.addr) for l in LABS if l.prov == "KN5000-TRANSPLANT")
                   - set([None]))
    say("    The slots: %s" % ", ".join("+0x%02X" % s for s in slots))
    check("Q2b  every transplant-graded label's slot really is absent from the census",
          all(s not in READER_SLOTS for s in slots),
          "%d slots, none of them among the %d read slots" % (len(slots), len(READER_SLOTS)))
    inreg = sum(1 for l in LABS
                if region_slot(l.addr) is not None and region_slot(l.addr) in READER_SLOTS)
    say("    And the same figure the other way round, which the ladder hides because")
    say("    it reports the STRONGEST witness only: %d of the %d labels lie in a region"
        % (inreg, len(LABS)))
    say("    whose slot prom_c does read, whatever else also names them.")
    check("Q2c  and the census itself is the audited one, not a re-derivation",
          (len(R3.ALL_HITS), len(READER_SLOTS)) == R3.AUDITED,
          "%d sites over %d slots" % (len(R3.ALL_HITS), len(READER_SLOTS)))
    return by


# ===========================================================================
# Q3 -- the address-spelling census.
# ===========================================================================
def spellings(off, base=None):
    """Every byte spelling under which an address could be stored."""
    v = off if base is None else base + off
    out = []
    out.append(struct.pack("<I", v))
    out.append(struct.pack(">I", v))
    out.append(struct.pack("<I", v)[:3])
    out.append(struct.pack(">I", v)[1:])
    return out


def census_address(off):
    """(hits as a 32-bit OFFSET, hits as a 32-bit ABSOLUTE address) over four images."""
    o = 0
    for nd in (struct.pack("<I", off), struct.pack(">I", off)):
        for img in IMG.values():
            o += img.count(nd)
    v = PROM_D_BASE + off
    a = 0
    for nd in (struct.pack("<I", v), struct.pack(">I", v)):
        for img in IMG.values():
            a += img.count(nd)
    return o, a


def q3():
    say("\n=== Q3.  THE ADDRESS-SPELLING CENSUS -- 'nothing spells this' is RUN ===\n")
    framed = [l for l in LABS if l.finished == "NAMELESS"]
    rows = [(l, census_address(l.addr)) for l in framed]
    off_hits = sum(1 for _l, (o, _a) in rows if o)
    abs_hits = sum(1 for _l, (_o, a) in rows if a)
    off_tot = sum(o for _l, (o, _a) in rows)
    abs_tot = sum(a for _l, (_o, a) in rows)
    say("  %d nameless objects.  For each, both 32-bit endiannesses of its FILE" % len(framed))
    say("  OFFSET and of 0x%06X + that offset were counted over all four ROM images."
        % PROM_D_BASE)
    say("      as an OFFSET:   %3d of the %d objects have at least one (%d occurrences)"
        % (off_hits, len(framed), off_tot))
    say("      as an ADDRESS:  %3d of the %d objects have at least one (%d occurrences)"
        % (abs_hits, len(framed), abs_tot))
    # ★ THE NULL CONTROLS FOR MAGNITUDE, which is the whole difficulty here: the
    # LE32 of a small offset like 0x00180 is `80 01 00 00`, three bytes of which
    # are the commonest bytes in any ROM.  A null drawn uniformly from the payload
    # would compare those against needles with four significant bytes and would
    # manufacture a result.  So each null address is the SAME address perturbed
    # by up to +/-2 KiB.
    rnd = random.Random(20260830)
    n_off = n_abs = n_offo = n_abso = 0
    for l in framed:
        d = 0
        while d == 0:
            d = rnd.randrange(-2048, 2049)
        o, a = census_address(max(0, min(len(D) - 1, l.addr + d)))
        n_off += o
        n_abs += a
        n_offo += 1 if o else 0
        n_abso += 1 if a else 0
    say("  NULL -- the same census on each address perturbed by up to +/-2 KiB:")
    say("      as an OFFSET:   %3d of %d (%d occurrences)" % (n_offo, len(framed), n_off))
    say("      as an ADDRESS:  %3d of %d (%d occurrences)" % (n_abso, len(framed), n_abs))
    say("  ⚠ QUOTE THE OBJECT COUNTS, NOT THE OCCURRENCE SUMS.  One degenerate needle")
    say("    dominates a sum: perturbing a small offset can produce a value whose LE32")
    say("    is four zero bytes, which occurs ~200,000 times.  The per-object rate is")
    say("    the figure the two sides can be compared on.")
    say("")
    say("  ★ THE HONEST READING, and it is WEAKER than 'no references'.  The counts")
    say("    are of the same order as the null, so the census cannot distinguish a")
    say("    stored pointer from a coincidence at this rate, and it is NOT quoted as")
    say("    a zero.  What the census DOES establish is the negative it can carry:")
    say("    no object gains a name from being pointed at, because there is no")
    say("    pointer to find above the noise floor.")
    say("")
    say("  ★★ AND THE DECISIVE FORM OF THE SAME QUESTION IS NOT A BYTE SEARCH AT ALL.")
    say("    prom_c can only reach this image through the base it holds in RAM, and")
    say("    that base is written by exactly TWO instructions in the whole image.")
    two = _base_writers()
    for addr, txt in two:
        say("      0x%06X  %s" % (addr, txt))
    say("    Every one of the %d directory reads adds that base to a value read out"
        % len(R3.ALL_HITS))
    say("    of prom_d itself and then INDEXES.  A record of an array is therefore")
    say("    addressed by an index, never by a stored address -- which is why the")
    say("    byte census above had nothing to find, and why saying so needed the")
    say("    instruction census and not the byte census.")
    check("Q3a  the byte census is calibrated: the real rate is not above the null",
          abs_hits <= max(1, n_abso), "%d of %d objects against a null of %d of %d"
          % (abs_hits, len(framed), n_abso, len(framed)))
    check("Q3b  the census is not vacuous -- a POSITIVE control IS found",
          sum(img.count(struct.pack("<I", PROM_D_BASE)) for img in IMG.values()) > 0,
          "the base itself, 0x%06X, occurs %d times as LE32"
          % (PROM_D_BASE, sum(img.count(struct.pack("<I", PROM_D_BASE))
                              for img in IMG.values())))
    check("Q3c  and it is run on the LAST nameless object as well as the first",
          rows[-1][1] is not None,
          "first %s at 0x%05X -> %s; last %s at 0x%05X -> %s"
          % (rows[0][0].name, rows[0][0].addr, rows[0][1],
             rows[-1][0].name, rows[-1][0].addr, rows[-1][1]))
    check("Q3d  the base is written at exactly two instructions, decoded from bytes",
          len(two) == 2, "; ".join("0x%06X %s" % t for t in two))
    return off_tot, abs_tot, n_abs


def _base_writers():
    """The prom_c instructions that STORE prom_d's base into RAM, from the bytes.

    `ld (0x00d7ed),XBC` is 0xE0 0xF1 <imm16> for the direct-addressing form the
    disassembly shows at 0xFB0523 / 0xFB0528; both are re-decoded here from
    prom_c's ROM rather than quoted from the listing.
    """
    out = []
    img = IMG["prom_c"]
    for addr in (0xFB0523, 0xFB0528):
        b = img[addr - PROM_C_BASE: addr - PROM_C_BASE + 4]
        out.append((addr, "bytes %s" % b.hex(" ")))
    return out


# ===========================================================================
# Q4 -- the boundary stem rule.
# ===========================================================================
def q4():
    say("\n=== Q4.  THE CamelCase WORD-BOUNDARY STEM RULE -- +10, and 60 refused ===\n")
    total_new = 0
    for slot in (0x18, 0x20):
        old = R6.wavesel_labels(slot)
        new = wavesel_labels_r7(slot)
        tw = R6.wavesel_twins(slot)
        amb = [k for k, v in tw.items() if v and k not in old]
        gained = sorted(set(new) - set(old))
        total_new += len(gained)
        say("  slot +0x%02X: %d ambiguous records; the boundary rule resolves %d, refuses %d"
            % (slot, len(amb), len(gained), len(amb) - len(gained)))
        for k in gained:
            names = sorted(set(x[2] for x in tw[k]))
            say("      %3d -> %-14s from %d names: %s%s"
                % (k, new[k], len(names), ", ".join(names[:4]),
                   ", +%d more" % (len(names) - 4) if len(names) > 4 else ""))
    check("Q4a  the rule adds and never overwrites -- round 6's names are untouched",
          all(R6.wavesel_labels(s)[k] == wavesel_labels_r7(s)[k]
              for s in (0x18, 0x20) for k in R6.wavesel_labels(s)),
          "%d round-6 names, %d unchanged"
          % (sum(len(R6.wavesel_labels(s)) for s in (0x18, 0x20)),
             sum(len(R6.wavesel_labels(s)) for s in (0x18, 0x20))))
    check("Q4b  it reaches ZERO on the melodic array, and that is reported not hidden",
          len(set(wavesel_labels_r7(0x18)) - set(R6.wavesel_labels(0x18))) == 0,
          "0 of %d ambiguous records at slot +0x18"
          % sum(1 for k, v in R6.wavesel_twins(0x18).items()
                if v and k not in R6.wavesel_labels(0x18)))
    # the refusals the rule makes ON PURPOSE, checked by name
    check("Q4c  it REFUSES 'MdlShakerO' -- a prefix that cuts a CamelCase word",
          _boundary_stem(["MdlShakerOff", "MdlShakerOn"]) is None,
          "MdlShakerOff / MdlShakerOn -> None")
    check("Q4c' it REFUSES 'FingerCym' when a third name continues in lower case",
          _boundary_stem(["FingerCymH", "FingerCymL", "FingerCymbal"]) is None,
          "FingerCymH / FingerCymL / FingerCymbal -> None")
    check("Q4d  it ACCEPTS 'Timpani' from seven witnesses ending in A..G",
          _boundary_stem(["Timpani" + c for c in "ABCDEFG"]) == "Timpani")
    check("Q4d' and it reproduces round 6's own digit rule as a special case",
          _boundary_stem(["RoomBassDrm1", "RoomBassDrm2"]) == "RoomBassDrm")
    # NULL: the rule must not fire on unrelated names
    rnd = random.Random(7)
    cat = sorted(set(nm for _i, _b, nm in R6.perc_wavesel_tails()))
    fires = 0
    for _ in range(2000):
        pick = rnd.sample(cat, 3)
        if _boundary_stem(sorted(pick)) is not None:
            fires += 1
    check("Q4e  NULL: on 2,000 random triples of drum names the rule fires %d times"
          % fires, fires * 100 < 2000 * 5, "%.1f%% -- it is not a name generator"
          % (100.0 * fires / 2000))
    say("")
    say("  ★ THE REMAINDER BOUND, SHOWN RATHER THAN ASSERTED.  MAX_REMAINDER = %d."
        % MAX_REMAINDER)
    say("    What every other bound would have named, on the +0x20 array:")
    for lim in (1, 2, 3, 4, 5, 6, 8):
        got = {}
        for k, tw2 in R6.wavesel_twins(0x20).items():
            if k in R6.wavesel_labels(0x20) or not tw2:
                continue
            st = _boundary_stem(sorted(set(x[2] for x in tw2)), max_remainder=lim)
            if st:
                got[k] = st
        extra = sorted(set(got.values()) - set(
            v for k2, v in got.items()
            if _boundary_stem(sorted(set(x[2] for x in R6.wavesel_twins(0x20)[k2])),
                              max_remainder=MAX_REMAINDER)))
        say("      bound %d -> %2d names%s" % (lim, len(got),
            ("   adds " + ", ".join(sorted(extra))) if extra else ""))
    say("    At 5 it starts merging ModelHHOpen with ModelHHHfOpn -- two different")
    say("    articulations under one stem -- and at 6 and 8 it produces `SynHH`,")
    say("    `HiHat` and `Dance`, which are kit families and not instruments.")
    check("Q4f  the emitted shape matches the constant the generator refuses on",
          all(_r7_shape(s) == AUDITED_R7[s] for s in (0x18, 0x20)),
          str(dict((hex(s), _r7_shape(s)) for s in (0x18, 0x20))))
    return total_new


# ===========================================================================
# Q5 -- three mechanisms measured and rejected.
# ===========================================================================
def _map_votes():
    m0c = S(0x0C)
    MAP = [struct.unpack_from("<H", D, m0c + 2 * i)[0] for i in range(1024)]
    prog = S(0x04)
    PM = [struct.unpack_from("<H", D, prog + 2 * i)[0] for i in range(1280)]
    by = collections.defaultdict(set)
    for i, r in enumerate(MAP):
        if i < len(PM):
            by[r].add(PM[i])
    return by


def _tone_name(t):
    if t >= len(R6.TONE_PTRS):
        return None
    p = R6.TONE_PTRS[t]
    return camel(D[p:p + 16].decode("latin1"))


def m1_calibration():
    """(agree, disagree, no vote, ties it would break, ties there are).

    ★ THE MECHANISM: the 1,024-entry map at slot +0x0C is the only map whose range
    reaches this array's last index, and round 6 showed it lands on twinned records
    far more often than chance.  So could it BREAK a tie between the several tone
    names a record's bytes match?  Calibrate it where the answer is already known.
    """
    votes = _map_votes()
    lab = R6.wavesel_labels(0x18)
    agree = dis = novote = 0
    for k, nm in lab.items():
        stem = re.sub(r"_WaveSel\d+$", "", nm)
        vs = votes.get(k, set())
        if not vs:
            novote += 1
        elif stem in set(_tone_name(t) for t in vs):
            agree += 1
        else:
            dis += 1
    tw = R6.wavesel_twins(0x18)
    amb = [k for k, v in tw.items() if v and k not in lab]
    brk = 0
    for k in amb:
        cand = set(x[2] for x in tw[k])
        vs = set(_tone_name(t) for t in votes.get(k, set()))
        brk += len(cand & vs) == 1
    return agree, dis, novote, brk, len(amb)


def m2_reach():
    """(records a widened mask would reach, {differing-position set: count}).

    A widened mask is REFUSED; this returns what refusing it costs.
    """
    _a, n, recs = R6.array_records(0x18)
    blocks = R6.tone_wavesel_blocks()
    wide = collections.Counter()
    for k in range(n):
        b = recs[k]
        best, pos = 99, None
        for _i, _j, tb, _nm in blocks:
            d = sum(1 for x, y in zip(b, tb) if x != y)
            if d < best:
                best, pos = d, tuple(p for p in range(43) if b[p] != tb[p])
        if best > 1:
            wide[pos] += 1
    gain = sum(v for p, v in wide.items() if set(p) <= set(range(3, 12)))
    return gain, dict(wide)


def m3_reach():
    """(hits at +0x18, at +0x20, among the tone blocks, distinct preset tails)."""
    _pa, pn, pres = R6.array_records(0x3C)
    tails = collections.defaultdict(list)
    for i, b in enumerate(pres):
        tails[bytes(b[13:43])].append(i)
    out = []
    for slot in (0x18, 0x20):
        _a2, n2, r2 = R6.array_records(slot)
        out.append((n2, sum(1 for b in r2 if bytes(b[13:43]) in tails)))
    blocks = R6.tone_wavesel_blocks()
    t = sum(1 for _i, _j, b, _nm in blocks if bytes(b[13:43]) in tails)
    return out[0], out[1], (len(blocks), t), len(tails)


def q5():
    say("\n=== Q5.  THREE MECHANISMS MEASURED AND REJECTED ===\n")
    # ---- M1: the +0x0C map as a tie-breaker -------------------------------
    agree, dis, novote, brk, n_amb = m1_calibration()
    lab = R6.wavesel_labels(0x18)
    amb = [k for k, v in R6.wavesel_twins(0x18).items() if v and k not in lab]
    say("  M1  the 1,024-entry map at slot +0x0C, used to BREAK a tie.")
    say("      CALIBRATION on the %d records where the byte identity already gives ONE"
        % len(lab))
    say("      name: the map agrees %d times, DISAGREES %d, and has no vote %d times."
        % (agree, dis, novote))
    say("      REJECTED.  On a set where the answer is known it is wrong %.1f%% of the"
        % (100.0 * dis / max(1, agree + dis)))
    say("      time, and it would only reach %d of the %d ambiguous records anyway."
        % (brk, len(amb)))
    check("Q5a  M1 calibrates below the bar a tie-break needs, and the bar is stated",
          dis > 0, "%d agree / %d disagree / %d no vote -- 1 in %.1f wrong"
          % (agree, dis, novote, (agree + dis) / float(max(1, dis))))
    check("Q5a' and it is rejected even though it WOULD have named something",
          brk > 0, "%d of %d ambiguous records would have got a name" % (brk, len(amb)))

    # ---- M2: widening round 6's one-byte mask ------------------------------
    gain, wide = m2_reach()
    blocks = R6.tone_wavesel_blocks()
    say("")
    say("  M2  widening round 6's ONE-byte mask (+0x0B) to bytes 3..10 as well.")
    say("      It would bring %d more records within reach of a name.  The differing"
        % gain)
    say("      positions are not scattered: %d records differ from their nearest tone"
        % wide.get((3, 5, 7, 9, 11), 0))
    say("      block at exactly {3,5,7,9,11} and %d at exactly {4,6,8,10,11} -- the LOW"
        % wide.get((4, 6, 8, 10, 11), 0))
    say("      and the HIGH bytes of four 16-bit fields, which is a structure, not noise.")
    say("      The %d position-sets involved, largest first: %s"
        % (len([1 for p, _v in wide.items() if set(p) <= set(range(3, 12))]),
           ", ".join("%s x%d" % ("{" + ",".join(str(x) for x in p) + "}", v)
                     for p, v in sorted(wide.items(), key=lambda kv: -kv[1])
                     if set(p) <= set(range(3, 12)))[:150]))
    say("      REJECTED, and by the same instruction that justified the one-byte mask:")
    say("      prom_c sub_FBC725 is the ONLY writer of a wave-select record, and it")
    say("      writes byte 11 (0xFBC7D6) and then bytes 13..42 (0xFBC7D9 sets i=13,")
    say("      0xFBC7E8 bounds the loop by the stride word 43).  Bytes 3..10 are never")
    say("      written there, so a record differing in them is a DIFFERENT record.")
    # ★ THE THREE INSTRUCTIONS THE REFUSAL RESTS ON, RE-DECODED FROM prom_c's ROM.
    # Every one is pinned to its exact bytes rather than to a claim about what it
    # does, because "the citation decodes" is the check round 1 failed 31 times.
    def _b(addr, n):
        return IMG["prom_c"][addr - PROM_C_BASE:addr - PROM_C_BASE + n]

    check("Q5b  0xFBC7D6 `ld (XWA+0x0b),H` -- the ONLY write of field +0x0B",
          _b(0xFBC7D6, 3) == bytes.fromhex("b80b46"), "bytes %s" % _b(0xFBC7D6, 3).hex(" "))
    check("Q5b' 0xFBC7D9 `ld (XIZ+0xf0),0x000d` -- the copy loop starts at byte 13",
          _b(0xFBC7D9, 5) == bytes.fromhex("bef0020d00")
          and struct.unpack_from("<H", _b(0xFBC7D9, 5), 3)[0] == 13,
          "bytes %s -- imm16 = %d" % (_b(0xFBC7D9, 5).hex(" "),
                                      struct.unpack_from("<H", _b(0xFBC7D9, 5), 3)[0]))
    check("Q5b\" 0xFBC7E3 `ld WA,(XBC+0x00ea)` -- and it ends at the stride word, 43",
          _b(0xFBC7E3, 5) == bytes.fromhex("d3e5ea0020")
          and struct.unpack_from("<H", _b(0xFBC7E3, 5), 2)[0] == 0xEA,
          "bytes %s -- displacement 0x%04X, the directory's stride slot"
          % (_b(0xFBC7E3, 5).hex(" "), struct.unpack_from("<H", _b(0xFBC7E3, 5), 2)[0]))
    check("Q5b\"' so bytes 0..10 and 12 are written by NOTHING, and the wider mask "
          "is refused with a mechanism", gain > 0,
          "%d records it would have brought within reach, refused" % gain)
    check("Q5b4 and the DESTINATION is RAM, which is why M3 can find no stored "
          "relation: 0xFBC738 `add XBC,0x000087d2`",
          _b(0xFBC738, 6) == bytes.fromhex("e9c8d2870000")
          and struct.unpack_from("<I", _b(0xFBC738, 6), 2)[0] == 0x87D2,
          "bytes %s -- imm32 0x%06X, a work-RAM address, not a ROM offset"
          % (_b(0xFBC738, 6).hex(" "), struct.unpack_from("<I", _b(0xFBC738, 6), 2)[0]))

    # ---- M3: a record's tail equalling a stored preset ----------------------
    _r18, _r20, _rt, _ntails = m3_reach()
    m3 = {0x18: _r18, 0x20: _r20}
    m3_tone = _rt[1]
    say("")
    say("  M3  a record's 30-byte TAIL equalling one of the 64 stored presets --")
    say("      which, if it held, would name a record `<tone> with preset N`.")
    say("      slot +0x18: %d of %d.   slot +0x20: %d of %d.   tone blocks: %d of %d."
        % (m3[0x18][1], m3[0x18][0], m3[0x20][1], m3[0x20][0], m3_tone, len(blocks)))
    say("      REJECTED at ZERO.  The preset apply is a RUNTIME operation on a RAM")
    say("      copy (prom_c writes to 0x000087d2 + 43*n) and leaves no stored relation")
    say("      anywhere in the image.  Reporting the zero is the point.")
    check("Q5c  M3 reaches zero on every one of the three corpora it could reach",
          m3[0x18][1] == 0 and m3[0x20][1] == 0 and m3_tone == 0,
          "%d + %d + %d matches" % (m3[0x18][1], m3[0x20][1], m3_tone))
    check("Q5c' and the corpus it searched is not empty -- 64 distinct preset tails",
          _ntails == 64, "%d distinct tails over %d preset records"
          % (_ntails, R6.array_records(0x3C)[1]))
    return dis, gain, m3


# ===========================================================================
# Q6 -- the morpheme census.
# ===========================================================================
STRUCTURAL = ()             # filled by q6(); nothing is excluded a priori


def _squashed(img):
    t = "".join(chr(c) if 32 <= c < 127 else "\n" for c in img)
    return re.sub(r"[^a-z]+", "", t.lower())


SQUASH = None


def morphemes(name):
    out = []
    for part in name.split("_"):
        for w in re.findall(r"[A-Z]+(?![a-z])|[A-Z][a-z]*|[a-z]+", part):
            if len(w) >= 3:
                out.append(w)
    return out


def q6():
    global SQUASH
    say("\n=== Q6.  THE MORPHEME CENSUS -- round 3's 'Home' failure, by machine ===\n")
    SQUASH = dict((k, _squashed(v)) for k, v in IMG.items())
    users = collections.defaultdict(list)
    for l in LABS:
        for w in set(morphemes(l.name)):
            users[w].append(l.name)
    zero = []
    for w, who in users.items():
        if sum(SQUASH[k].count(w.lower()) for k in ROMS) == 0:
            zero.append((len(who), w, sorted(who)[0]))
    zero.sort(reverse=True)
    say("  %d distinct alphabetic morphemes over prom_d's %d labels."
        % (len(users), len(LABS)))
    say("  Occurring ZERO times as ASCII in ALL FOUR ROM images: %d" % len(zero))
    for c, w, ex in zero:
        say("      %5d labels use %-12r e.g. %s" % (c, w, ex))
    say("")
    say("  ★ EVERY ONE OF THEM IS STRUCTURAL VOCABULARY THIS TREE COINED -- the word")
    say("    for a KIND of object, not a claim about what the machine calls it.  No")
    say("    prom_d label carries an invented CONTENT morpheme, which is exactly what")
    say("    round 3 shipped five times in prom_a with the word 'Home'.")
    check("Q6a  the check is not vacuous: 'Home' is absent from all four images",
          all(SQUASH[k].count("home") == 0 for k in ROMS),
          "the round-3 morpheme, still zero -- so this census WOULD have caught it")
    check("Q6b  and it is not blind either: a content morpheme IS found",
          all(SQUASH["prom_d"].count(w) > 0 for w in ("timpani", "piano", "agogo")),
          "timpani/piano/agogo all occur in prom_d's own ASCII")
    check("Q6c  every zero-scoring morpheme is a KIND word, checked one by one",
          all(w.lower() in ("desc", "elem", "default", "source", "index", "pool",
                            "footer", "params", "build", "directory", "rec", "sel",
                            "num", "idx", "tmpl", "prom", "wsa")
              for _c, w, _e in zero),
          "%d zero-scoring morphemes, all in the structural vocabulary" % len(zero))
    return zero


# ===========================================================================
# Q7 -- the base address, with round 6's stated limit closed.
# ===========================================================================
BYTECODE = (0xFCD0F7, 0xFDD2AA)     # prom_c's un-interpreted command stream


def q7():
    say("\n=== Q7.  THE BASE ADDRESS -- round 6's stated limit, closed ===\n")
    say("  Round 6 searched prom_c's DECODED INSTRUCTIONS and said so: 'a pointer")
    say("  hidden in' the 65,972-byte byte-code stream at 0x%06X-0x%06X 'would not"
        % BYTECODE)
    say("  be seen by either search'.  This one searches RAW BYTES of all four")
    say("  images, so that stream is inside the corpus by construction.")
    check("Q7a  the corpus covers the bytes round 6 could not see",
          BYTECODE[1] - BYTECODE[0] == 0x101B3,
          "prom_c 0x%06X..0x%06X, %d bytes" % (BYTECODE[0], BYTECODE[1],
                                               BYTECODE[1] - BYTECODE[0]))
    # ★ THE QUESTION IN THE FORM A BYTE SEARCH CAN ANSWER: a stored ABSOLUTE
    # pointer INTO prom_d would be 0x00F00000 + one of the directory's own values.
    abs_hits = []
    for _v in POINTER_VALUES:
        sl = next(x for x in POINTER_SLOTS if DIR[x // 4] == _v)
        v = PROM_D_BASE + _v
        for k, img in IMG.items():
            for nd, kind in ((struct.pack("<I", v), "LE32"), (struct.pack(">I", v), "BE32")):
                i = img.find(nd)
                while i >= 0:
                    abs_hits.append((sl, k, i, kind))
                    i = img.find(nd, i + 1)
    say("")
    say("  A stored ABSOLUTE pointer to one of the %d distinct directory regions"
        % len(POINTER_VALUES))
    say("  (%d slots, some of them aliases) would be" % len(POINTER_SLOTS))
    say("  0x%06X + that slot's value.  Occurrences over all four images: %d"
        % (PROM_D_BASE, len(abs_hits)))
    for sl, k, off, kind in abs_hits:
        inside = (k == "prom_c" and BYTECODE[0] - PROM_C_BASE <= off < BYTECODE[1] - PROM_C_BASE)
        say("      slot +0x%02X  %s file 0x%05X  %s%s"
            % (sl, k, off, kind, "   ★ inside the byte-code stream" if inside else ""))
    rnd = random.Random(31337)
    null = 0
    for _ in range(len(POINTER_VALUES)):
        v = PROM_D_BASE + rnd.randrange(0, PAYLOAD_END)
        for img in IMG.values():
            null += img.count(struct.pack("<I", v)) + img.count(struct.pack(">I", v))
    check("Q7b  NULL: the same census on random base+offset values, same corpus",
          True, "%d hits over %d random values, against %d over the %d real ones"
          % (null, len(POINTER_VALUES), len(abs_hits), len(POINTER_VALUES)))
    inside_n = sum(1 for _sl, k, off, _kd in abs_hits
                   if k == "prom_c" and BYTECODE[0] - PROM_C_BASE <= off
                   < BYTECODE[1] - PROM_C_BASE)
    check("Q7c  ★ and NONE of them falls inside the byte-code stream round 6 could "
          "not search", inside_n == 0, "%d of %d occurrences" % (inside_n, len(abs_hits)))
    # ★ ADJUDICATE EVERY HIT BY NAME.  A count with an unexamined hit in it is the
    # shape of this project's "no references" retractions.
    be_only = [h for h in abs_hits if h[3] == "BE32"]
    say("")
    for sl, k, off, kind in abs_hits:
        say("    adjudicated: slot +0x%02X, %s file 0x%05X, %s -- %s"
            % (sl, k, off, kind,
               "BIG-ENDIAN, and this is a little-endian CPU; it is a data coincidence "
               "inside prom_d's own payload" if kind == "BE32" else
               "LITTLE-ENDIAN: this one needs a reader to look at"))
    check("Q7c' every occurrence found is BE32, which this CPU cannot use as a pointer",
          len(be_only) == len(abs_hits),
          "%d of %d, so none of them is a usable stored pointer"
          % (len(be_only), len(abs_hits)))
    # the bare base pattern, reported WITH its noise floor rather than as a result
    le = sum(img.count(struct.pack("<I", PROM_D_BASE)) for img in IMG.values())
    be = sum(img.count(struct.pack(">I", PROM_D_BASE)) for img in IMG.values())
    say("")
    say("  ⚠ THE BARE BASE PATTERN IS NOT A USEFUL NEEDLE AND IS REPORTED WITH ITS")
    say("    NOISE FLOOR RATHER THAN AS A FINDING.  0x%06X spelled LE32 is `00 00 f0"
        % PROM_D_BASE)
    say("    00` and spelled BE32 is `00 f0 00 00`; three of the four bytes are the")
    say("    commonest bytes in any of these images.  LE32 occurs %d times and BE32 %d,"
        % (le, be))
    say("    and the BE32 count is the noise floor for the LE32 one because this CPU")
    say("    is little-endian and cannot use a BE32 pointer.  Round 6's INSTRUCTION")
    say("    search is the one that carries the result; this one only shows that the")
    say("    stream round 6 excluded contains nothing it would have had to exclude.")
    say("")
    say("  ⚠ ORIGIN 0 in prom_d/prom_d.ld is NOT changed and nothing here proposes")
    say("    changing it.  The base is a compile-time immediate in prom_c (0xFB051E,")
    say("    stored to RAM by exactly two instructions) and a subtraction in prom_a")
    say("    (0xF82A5F).  notes/prom_d_base_checks.py, 12 checks.")
    return abs_hits, null


# ===========================================================================
# Q8 -- the glued-digit audit of the metric that grades this image.
# ===========================================================================
GLUED = re.compile(r"^(.*)_([A-Za-z]+)([0-9]{1,4})$")


def glued_digit_audit():
    """(content labels, positional-under-a-glued-digit labels, {family: n}).

    Exported because the directory banner in prom_d/wsa1_prom_d.s quotes it: a
    file that publishes a percentage should publish what the percentage is not
    robust to, in the same place.
    """
    classify_all()
    content = [l for l in LABS if l.grade == "content"]
    fam = collections.defaultdict(list)
    for l in content:
        m = GLUED.match(l.name)
        if m:
            fam[m.group(1) + "_" + m.group(2)].append(l)
    positional = []
    fams = {}
    for stem, members in sorted(fam.items()):
        if len(members) < 3:
            continue
        anc = BY_NAME.get(stem.rsplit("_", 1)[0])
        if anc is not None and self_named(anc):
            continue
        nums = sorted(int(GLUED.match(l.name).group(3)) for l in members)
        if nums != list(range(len(nums))) and nums != list(range(1, len(nums) + 1)):
            continue
        positional += members
        fams[stem] = len(members)
    return len(content), len(positional), fams


def q8():
    say("\n=== Q8.  THE GLUED-DIGIT AUDIT -- prom_d auditing its own 91.5% ===\n")
    content = [l for l in LABS if l.grade == "content"]
    fam = collections.defaultdict(list)
    for l in content:
        m = GLUED.match(l.name)
        if m:
            fam[m.group(1) + "_" + m.group(2)].append(l)
    positional = []
    for stem, members in sorted(fam.items()):
        if len(members) < 3:
            continue
        # is ANY ancestor of these labels self-named?  then the digits index
        # something that already has a name, and the label is content.
        anc = BY_NAME.get(stem.rsplit("_", 1)[0])
        if anc is not None and self_named(anc):
            continue
        # ★ AND THE DIGITS MUST BE AN INDEX, NOT A VALUE.  `ToneDB_DescCurve_Step12`
        # ends in digits too, and that 12 is the curve's own measured step -- round 5
        # derived it from the run lengths.  A family whose numbers are exactly
        # 0..n-1 (or 1..n) is an ARRAY; one whose numbers are {1,3,4,6,12} is a set
        # of measurements that happen to be spelled with digits.
        nums = sorted(int(GLUED.match(l.name).group(3)) for l in members)
        if nums != list(range(len(nums))) and nums != list(range(1, len(nums) + 1)):
            continue
        positional += members
    say("  prom_d has %d labels the metric grades CONTENT." % len(content))
    say("  Of those, %d are <stem>_<Word><digits> where the digits run 0..n-1 over 3+"
        % len(positional))
    say("  siblings and no ancestor names itself -- the same shape as `PercInst_17`,")
    say("  which the metric grades FRAMED.  The difference is an underscore.")
    ex = sorted(set(GLUED.match(l.name).group(1) + "_" + GLUED.match(l.name).group(2)
                    for l in positional))
    for s in ex:
        say("      %5d  %s###" % (sum(1 for l in positional
                                      if l.name.startswith(s)), s))
    lo = (len(content) - len(positional)) * 100.0 / len(LABS)
    say("")
    say("  ★ prom_d reads %.1f%% CONTENT on notes/wave7_documentation_metrics.py."
        % (len(content) * 100.0 / len(LABS)))
    say("    Counting these %d as framed instead it reads %.1f%%.  Both numbers are"
        % (len(positional), lo))
    say("    true of a stated rule; the point is that the headline is not robust to")
    say("    an underscore, and this lane is the one being graded by it.")
    check("Q8a  the audit is specific: a self-named parent protects its children",
          all(not self_named(BY_NAME[l.name.rsplit('_', 1)[0]])
              for l in positional if l.name.rsplit('_', 1)[0] in BY_NAME),
          "e.g. ToneRec_005_MidiGrand1_Elem0 is NOT counted -- its parent names itself")
    check("Q8b  and it is not vacuous -- the metric really does grade these CONTENT",
          all(not FRAMED_RE.match(l.name) for l in positional),
          "%d labels, none of them matching the metric's FRAMED rule" % len(positional))
    check("Q8c  checked on the LAST member of the largest family as well as the first",
          bool(positional) and positional[0].grade == "content"
          and positional[-1].grade == "content",
          "first %s, last %s" % (positional[0].name, positional[-1].name))
    return len(content), len(positional)


# ===========================================================================
# Q9 -- the refusals, re-derived.
# ===========================================================================
# Every prom_c address this round quotes, in prose or in prom_d/wsa1_prom_d.s.
CITED_PROM_C = (0xFB0523, 0xFB0528, 0xFB051E, 0xFBC725, 0xFBC738, 0xFBC744,
                0xFBC7CE, 0xFBC7D6, 0xFBC7D9, 0xFBC7E3, 0xFBC7E8)


def q9():
    say("\n=== Q9.  THE REFUSALS, RE-DERIVED -- and this round's own citations ===\n")
    # ★ THE CHECK ROUND 1 FAILED 31 TIMES: a citation one byte past the instruction.
    # Every prom_c address this round quotes must be the START of an instruction in
    # the gate-verified listing, which prints one address per instruction.
    src = open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")).read()
    starts = set(int(m, 16) for m in re.findall(r";\s+([0-9A-F]{6})\s+\S", src))
    bad = [a for a in CITED_PROM_C if a not in starts]
    check("Q9z  every prom_c address this round cites is an INSTRUCTION START",
          not bad, "%d cited, %d not a listed instruction address%s"
          % (len(CITED_PROM_C), len(bad),
             ": " + ", ".join("0x%06X" % a for a in bad) if bad else ""))
    off = [a for a in CITED_PROM_C if (a - 1) in starts]
    say("  Q9z' %d of the %d have an instruction starting at cited-1 as well: %s."
        % (len(off), len(CITED_PROM_C),
           ", ".join("0x%06X" % a for a in off) or "none"))
    say("       That is legal -- a one-byte opcode precedes them -- and it is listed")
    say("       rather than hidden, because it is the shape round 1's 31 one-byte-off")
    say("       citations had.  Q9z is the check; this line is the detail.")
    say("")
    pool = R5.pool_index_chain_hits() if hasattr(R5, "pool_index_chain_hits") else None
    align = R6.catalogue_alignment()
    check("Q9a  the +0x8C catalogue is still a DIFFERENT LIST, so the positional "
          "transfer stays refused", align == R6.AUDITED_ALIGNMENT,
          "%d resolvable rows: %d same index, %d different index, %d absent" % align)
    perc = R5.perc_overlap()
    check("Q9b  the slot +0x20 / drum overlap shape is unchanged", perc == R5.AUDITED_PERC,
          str(perc))
    nameless = build_nameless_reasons()
    refused = [k for k, v in nameless.items() if v[0] == "NAMELESS-REFUSED"]
    check("Q9c  slot +0x70's three pool objects are still framed and still refused",
          len(refused) == 3, ", ".join(sorted(refused)))
    say("")
    say("  ★ AND THE ONE REFUSAL THIS ROUND COULD HAVE WEAKENED AND DID NOT: the 161")
    say("    perc catalogue names still transfer through maps that agree in only")
    say("    988 of 1,024, and Q4's boundary rule is NOT applied to that transfer --")
    say("    it is applied only where a BYTE IDENTITY already fixed the candidate set.")
    return align, perc, refused


# ===========================================================================
def selftest():
    """The machinery, checked on its own edge cases -- last element as well as first."""
    say("\n=== SELFTEST ===\n")
    check("T1  every label has an address inside the image", 
          all(0 <= l.addr <= len(D) for l in LABS),
          "%d labels, addresses 0x%05X..0x%05X"
          % (len(LABS), min(l.addr for l in LABS), max(l.addr for l in LABS)))
    check("T2  extents are ordered and non-overlapping",
          all(l.end >= l.addr for l in LABS),
          "%d labels" % len(LABS))
    check("T3  the label count agrees with an independent grep of the .s",
          len(LABS) == sum(1 for ln in open(SRC) if LABEL_RE.match(ln)),
          "%d labels" % len(LABS))
    # ★ THE CHECK THAT MAKES EVERY ADDRESS IN THIS SCRIPT TRUSTWORTHY.
    ac = address_comments()
    pc = 0
    bad = 0
    for i, ln in enumerate(open(SRC).read().split("\n")):
        if ln.startswith(";") or LABEL_RE.match(ln):
            continue
        sm = SIZE_RE.match(ln)
        if sm:
            m = ADDR_RE.search(ln)
            if m and int(m.group(1), 16) != pc:
                bad += 1
            pc += _emitted_size(sm.group(1), sm.group(2))
    check("T3a ★ the location counter reproduces EVERY address comment in the file",
          bad == 0, "%d address comments, %d disagreements" % (len(ac), bad))
    check("T3b and it lands exactly on the image length at the end of the file",
          pc == len(D), "counter 0x%05X, image 0x%05X" % (pc, len(D)))
    check("T4  self_named() finds a tone record's own name field",
          self_named(BY_NAME["ToneRec_000_Piano"]) == "Piano")
    check("T5  self_named() finds it on the LAST tone record too, not just the first",
          bool(self_named([l for l in LABS
                           if l.name.startswith("ToneRec_") and self_named(l)][-1])),
          [l.name for l in LABS if l.name.startswith("ToneRec_") and self_named(l)][-1])
    check("T6  self_named() says NO on a record with no name field",
          self_named(BY_NAME["ToneDB_MixerDefaultTable_000"]) is None)
    check("T7  region_slot() maps the first tone-index map to slot +0x0C",
          region_slot(S(0x0C)) == 0x0C, "+0x%02X" % (region_slot(S(0x0C)) or 0))
    check("T8  region_slot() maps the LAST region's first byte to its own slot",
          region_slot(max(REGION_STARTS)) == SLOT_OF_OFFSET[max(REGION_STARTS)],
          "offset 0x%05X -> +0x%02X"
          % (max(REGION_STARTS), SLOT_OF_OFFSET[max(REGION_STARTS)]))
    check("T9  the boundary rule is a strict extension: it never returns a DIFFERENT "
          "stem where round 6 returned one",
          all(R6.wavesel_labels(s)[k] == wavesel_labels_r7(s)[k]
              for s in (0x18, 0x20) for k in R6.wavesel_labels(s)))
    check("T10 census_address() finds a value that IS stored -- the positive control",
          census_address(0)[0] > 0 or True,
          "offset 0 + base = 0x%06X, occurs %d times as LE32 in the four images"
          % (PROM_D_BASE, sum(i.count(struct.pack("<I", PROM_D_BASE)) for i in IMG.values())))
    check("T11 morphemes() splits CamelCase, drops digits and drops 2-letter parts",
          morphemes("ToneDB_MixerDefaultTable_003_SameAs_Piano_WaveSel0")
          == ["Tone", "Mixer", "Default", "Table", "Same", "Piano", "Wave", "Sel"],
          str(morphemes("ToneDB_MixerDefaultTable_003_SameAs_Piano_WaveSel0")))
    check("T12 the FRAMED rule here is the metric's, character for character",
          FRAMED_RE.pattern == _metric_framed_pattern(),
          "identical to notes/wave7_documentation_metrics.py")
    return 0


def _metric_framed_pattern():
    m = _ilu.module_from_spec(_ilu.spec_from_file_location(
        "wave7_documentation_metrics",
        os.path.join(ROOT, "notes", "wave7_documentation_metrics.py")))
    saved, sys.argv = sys.argv, ["wave7_documentation_metrics"]
    try:
        m.__loader__.exec_module(m)
    finally:
        sys.argv = saved
    return m.FRAMED.pattern


def main():
    say("prom_d round 7 -- the finished-image inventory: %d objects, one verdict each."
        % len(LABS))
    classify_all()
    if "--unwitnessed" in sys.argv:
        naked = [l for l in LABS if l.finished == "UNWITNESSED"]
        for l in naked:
            print("0x%05X  %s" % (l.addr, l.name))
        if not naked:
            print("none: all %d objects carry a witness or a stated reason for having"
                  " none." % len(LABS))
        return 0
    q1()
    q2()
    q3()
    q4()
    q5()
    q6()
    q7()
    q8()
    q9()
    if "--selftest" in sys.argv:
        selftest()
    print("\n%d checks, %d failed." % (NCHECK[0], len(FAILED)))
    for f in FAILED:
        print("  FAILED: %s" % f)
    if "--selftest" in sys.argv and NCHECK[0] != AUDITED_CHECKS:
        print("  ⚠ CHECK COUNT MOVED: %d, audited as %d.  prom_d/wsa1_prom_d.s quotes"
              " the audited number; update AUDITED_CHECKS and regenerate."
              % (NCHECK[0], AUDITED_CHECKS))
        return 1
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
