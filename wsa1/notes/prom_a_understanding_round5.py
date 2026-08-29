#!/usr/bin/env python3
"""prom_a round 5: can prom_a's `sub_XXXXXX` routines be named from WHAT READS
THEM, or from WHAT THEY READ, without inventing a single word?

QUESTION IT ANSWERS
    prom_a is the least-understood image in the tree (1,396 content names, 258
    framed, 2,978 `sub_XXXXXX`).  prom_d reached 83% because its records CONTAIN
    their own names; prom_a's routines do not.  So this pass asks the other half
    of the question -- name a routine from the object it reads, or from the
    routine it is a copy of -- and it asks it of FOUR levers, reporting the limit
    of each rather than a total.

    ★ THE ONE THAT PAID: THE DISPLAY-LIST PAINTERS.  prom_a runs the same
      byte-coded display lists prom_b stores, through the same two interpreters
      (`call 0xF417F0` = interpreter A, `call 0xF417F4` = B, with XIY = list
      start and XIX = list end; notes/FINDINGS-ui-display-list.md).  Wave 7
      round 4 began naming prom_b's lists from the `.ascii` inside them, and 249
      of the 717 now carry such a name (415 are still `DL_<addr>` -- their lists
      hold no text, which is the correct answer, not a failure).  A
      prom_a routine whose first display list is one of those 249 is THE ROUTINE
      THAT PAINTS THAT SCREEN, and the screen's own text names it.  That is data
      naming a routine, not a lane naming one.

      --painters prints every one, with the ROM text quoted, and --morphemes
      runs the guard that makes it safe: EVERY alphabetic morpheme of every
      proposed name must occur verbatim in the ASCII the routine's own lists
      contain.  Round 3 of this wave invented the morpheme "Home", which occurs
      ZERO times in all four images; this check is what makes that impossible
      here.  It is also why the names keep the ROM's own spelling -- the
      firmware's font draws capital O as `0` in some lists and as `O` in others,
      so `Paint_S0ngC0py` and `Paint_NoteEdit` are both literal.

    ⚠ THE THREE THAT DID NOT, AND THAT IS THE FINDING.  A lever worked to its
      limit and reporting "one" is a result; the tree has paid for guesses.

      * --twins   THE prom_a/prom_c KERNEL-TWIN LEVER IS SPENT.  Two independent
        matchers agree.  Raw bytes: 135 maximal identical runs of >= 24 bytes
        between the two images, 5,399 bytes in total, and all but a handful lie
        inside the kernel block that is ALREADY named on both sides.  Structure:
        of prom_a's routines, exactly THREE have a prom_c routine with an
        identical mnemonic sequence (>= 10 instructions), exactly ONE of those is
        `sub_XXXXXX` on the prom_a side with a content name on the prom_c side.
        One name, not a harvest: `sub_FB81CE` is a second, byte-identical copy of
        `MemCopyWords` (24 of 24 bytes equal).
      * --dups    WITHIN prom_a, the same idea: groups of routines that share a
        mnemonic sequence.  55 mix a named routine with a `sub_XXXXXX`; TWELVE
        survive the two filters below, holding SIXTEEN (named, sub_) pairs; and after
        discarding the groups whose members sit at the SAME address (a named data
        label and a `sub_` label on one object) and those whose byte difference
        changes what the routine touches, THREE names survive -- the three
        routines of the stale veneer copy at 0xFAA018-0xFAA3FF whose live twins
        at +0x400 are named (notes/FINDINGS-prom_a-message-module.md §3a).
        ⚠ FIVE candidate pairs are REFUSED here on purpose: `MidiIn_CC0A_Pan`
        against 0xFA64E5/0xFA6526 and `MidiOut_CC01_Modulation` against
        0xFA767E/0xFA77FA differ in exactly the table pointer they read, and
        `PanelScreen_RequestPending` against 0xFDA901/0xFDABF1 in the cell it
        tests.  Those bytes ARE the meaning; copying the name would assert the
        wrong controller.
      * --accessors  Round 3's single-cell accessor pass (notes/
        prom_a_naming_round3.py, 15 templates) is essentially complete.  Matching
        every already-named `Var<cell>_*`/`Arr<cell>_*` routine's BYTES against
        every `sub_XXXXXX` of the same length, and accepting only a difference
        confined to the two bytes that hold the cell address, finds exactly TWO
        more -- both missed by round 3 for the same reason, that their `ret`
        carries a label of its own so its body extraction stopped one
        instruction short.

WHAT IT DOES NOT CLAIM
    * `Paint_` is a structural verb, not ROM text.  It marks a routine whose body
      is display-list calls; everything after the underscore is quoted firmware.
    * A painter's name says what it PUTS ON THE SCREEN.  It does not claim the
      routine is the only painter of that screen, nor that it handles input.
    * Four painters are NOT named on purpose and --painters says which and why:
      0xF80384 (its lists read "ALL" and "TRACK" -- field labels, no title),
      0xF9291F ("USR2"/"USR1", and seven of its nine lists are unnamed), and
      0xF929DB / 0xF92A10, which run THE SAME list and would take the same name.
      Round 4's prom_b rule -- take a name only where it is unique file-wide --
      is the rule here too.

WHAT IT MOVED, measured with notes/wave7_documentation_metrics.py before and after

        prom_a   content  framed  sub_XXXX   LOWER   headers  evidence
        before     1,396     258     2,978   30.1%       975     1,067
        after      1,431     253     2,948   30.9%     1,083     1,175

    35 renames (30 `sub_XXXXXX` -> content, 5 framed -> content) and 108 header
    blocks: 35 above the renamed labels and 73 above the routines this pass
    deliberately did NOT name.  Those 73 are the point as much as the 24 are --
    each says what the routine mechanically IS (a display-list painter, with its
    lists and interpreter cited) and states in one sentence why it keeps
    `sub_XXXXXX`: its lists hold no text.

RUN
    python3 notes/prom_a_understanding_round5.py --painters
    python3 notes/prom_a_understanding_round5.py --twins
    python3 notes/prom_a_understanding_round5.py --dups
    python3 notes/prom_a_understanding_round5.py --accessors
    python3 notes/prom_a_understanding_round5.py --morphemes
    python3 notes/prom_a_understanding_round5.py --gaps            # the 73 NOT named
    python3 notes/prom_a_understanding_round5.py --plan
    python3 notes/prom_a_understanding_round5.py --apply           # 35 renames + headers
    python3 notes/prom_a_understanding_round5.py --apply_gaps      # the 73 gap headers
    python3 notes/prom_a_understanding_round5.py --verify_headers  # read all 97 BACK
    python3 notes/prom_a_understanding_round5.py --selftest        # 32 checks, first AND
                                                                   # last row of every table

    --apply and --apply_gaps are idempotent: both refuse to run twice (the first
    because its old labels are gone, the second because every target already has a
    header), and every lever above still reproduces its number AFTER the edit,
    which is what `was_unnamed()` is for.
"""
import argparse
import bisect
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S_A = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
S_B = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
S_C = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
R_A = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
R_C = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ANYLAB = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
INSN = re.compile(r'^\t(\S+)\s*(.*?)\s*;\s*([0-9A-F]{6})\s+([0-9a-f ]+?)(?:\s\s.*)?$')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
# the same rule notes/wave7_documentation_metrics.py grades with
FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                    r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                    r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')

# interpreter entry thunks, from notes/FINDINGS-ui-display-list.md
INTERP = {"0xf417f0": "A", "0xf417f4": "B"}


def was_unnamed(nm):
    """`sub_XXXXXX`, or one of the names THIS pass gave such a routine.

    Without this every count below would collapse the moment --apply ran, and a
    number that only reproduces before the edit is not reproducible at all."""
    return bool(UNNAMED.match(nm)) or nm in APPLIED


# --------------------------------------------------------------------------
# reading the transcriptions
# --------------------------------------------------------------------------
def stream(path):
    """[('L', name, lineno) | ('I', mnemonic, operands, addr, nbytes, lineno)]"""
    out = []
    for i, ln in enumerate(open(path).read().split("\n")):
        m = ANYLAB.match(ln)
        if m:
            out.append(("L", m.group(1), i))
            continue
        m = INSN.match(ln)
        if m:
            out.append(("I", m.group(1), m.group(2), int(m.group(3), 16),
                        len(m.group(4).split()), i))
    return out


def routines(items, cap=200, need_ret=True):
    """label -> (start addr, end addr or None, mnemonic tuple), walking to the first
    `ret`.

    ⚠ It walks THROUGH an intervening label.  Round 3's accessor pass stopped at
    one, which is exactly why it missed the two routines --accessors finds: their
    `ret` carries a label of its own."""
    out = {}
    n = len(items)
    for i, it in enumerate(items):
        if it[0] != "L" or it[1].startswith("."):
            continue
        st = en = None
        seq = []
        for j in range(i + 1, n):
            jt = items[j]
            if jt[0] == "L":
                continue
            if jt[0] != "I":
                break
            if st is None:
                st = jt[3]
            seq.append(jt[1])
            if jt[1] in ("ret", "reti", "retd"):
                en = jt[3] + jt[4]
                break
            if len(seq) >= cap:
                break
        if st is None or (need_ret and en is None):
            continue
        out.setdefault(it[1], (st, en, tuple(seq)))
    return out


ADDR_COMMENT = re.compile(r';\s*([0-9A-F]{6})\b')


def first_addr_comment(path):
    """label -> the address on the FIRST line under it that carries one.

    ⚠ Not the same as the first line the INSN regex matches: a display-list
    `.byte 0x06, 0x0A  ; FF0D2F  op 06, ...` carries an address but its trailing
    prose defeats the instruction regex, so a label on data reads as if its body
    started later.  That is exactly how two display lists got into the duplicate
    table as if they were routines."""
    out = {}
    pend = []
    for ln in open(path).read().split("\n"):
        m = LABEL.match(ln)
        if m:
            pend.append(m.group(1))
            continue
        m = ADDR_COMMENT.search(ln)
        if m and pend:
            for nm in pend:
                out.setdefault(nm, int(m.group(1), 16))
            pend = []
    return out


def label_index(path):
    """address -> [labels], and a bisect index of (lineno, label) for enclosing()"""
    addr = collections.defaultdict(list)
    pend = []
    pos = []
    for i, ln in enumerate(open(path).read().split("\n")):
        m = LABEL.match(ln)
        if m:
            pend.append(m.group(1))
            pos.append((i, m.group(1)))
            continue
        m = INSN.match(ln)
        if m and pend:
            for nm in pend:
                addr[int(m.group(3), 16)].append(nm)
            pend = []
    return addr, pos


# --------------------------------------------------------------------------
# prom_b's display lists: address and the ASCII they contain
# --------------------------------------------------------------------------
DL_HDR = re.compile(r'^;\s*(DL_[A-Za-z0-9_]+)\s*--\s*the display list at 0x([0-9A-F]{6})')
DL_LAB = re.compile(r'^(DL_[A-Za-z0-9_]+):')
PA_DL = re.compile(r'^(DisplayList_[A-Za-z0-9_]+):')


def prom_b_lists():
    """{address: (label, [ascii records])} for the 249 CONTENT-named prom_b lists.

    prom_b has 717 `DL_` labels: 415 are still `DL_<addr>` (their lists carry no
    text, which is the right answer and not a failure) and 249 of the rest carry
    the header line "-- the display list at 0xNNNNNN" that gives this function the
    address.  Measured, not quoted: the wave-7 briefing says round 4 named 229,
    and the file now holds 249, so later rounds added twenty."""
    lines = open(S_B).read().split("\n")
    addr = {}
    text = collections.defaultdict(list)
    labels = set()
    cur = None
    for ln in lines:
        m = DL_HDR.match(ln)
        if m:
            addr[m.group(1)] = int(m.group(2), 16)
        m = DL_LAB.match(ln)
        if m:
            cur = m.group(1)
            labels.add(cur)
            continue
        if cur and ln.startswith("\t.ascii") and '"' in ln:
            text[cur].append(ln.split('"')[1])
        elif cur and not (ln.startswith("\t") or ln.startswith(";") or ln.strip() == ""):
            cur = None
    # The intersection with `labels` is a guard, not a filter: all 249 header
    # names are also labels today.  It is here so that a header left behind by a
    # rename can never contribute an address for a list that no longer exists.
    return {a: (nm, text.get(nm, [])) for nm, a in addr.items() if nm in labels}


def prom_a_lists():
    """{address: (label, [ascii records])} for prom_a's own DisplayList_<addr> labels."""
    lines = open(S_A).read().split("\n")
    at = first_addr_comment(S_A)
    out = {}
    cur = None
    text = collections.defaultdict(list)
    addr = {}
    for i, ln in enumerate(lines):
        m = PA_DL.match(ln)
        if m:
            cur = m.group(1)
            # ⚠ NOT parsed out of the label -- five of these were renamed by this
            # very file, so the address has to come from the transcription.
            if cur in at:
                addr[cur] = at[cur]
            continue
        if cur is None:
            continue
        s = ln.strip()
        if s.startswith(".ascii") and '"' in ln:
            text[cur].append(ln.split('"')[1])
        elif s.startswith((".byte", ".short", ".long", ";")) or s == "":
            continue
        else:
            cur = None
    return {a: (nm, text.get(nm, [])) for nm, a in addr.items()}


def dl_sites():
    """every prom_a display-list call site: (site addr, interpreter, list addr, lineno)"""
    items = stream(S_A)
    XIY = re.compile(r'^XIY,0x00([0-9a-f]{6})$')
    XIX = re.compile(r'^XIX,0x00([0-9a-f]{6})$')
    out = []
    for i, it in enumerate(items):
        if it[0] != "I" or it[1] != "call" or it[2] not in INTERP:
            continue
        y = x = None
        j, steps = i - 1, 0
        while j >= 0 and steps < 8:
            jt = items[j]
            if jt[0] == "I":
                if jt[1] == "ld":
                    m = XIY.match(jt[2].replace(" ", ""))
                    if m and y is None:
                        y = int(m.group(1), 16)
                    m = XIX.match(jt[2].replace(" ", ""))
                    if m and x is None:
                        x = int(m.group(1), 16)
                steps += 1
            j -= 1
        out.append((it[3], INTERP[it[2]], y, x, it[5]))
    return out


def painters():
    """prom_a routines that run at least one CONTENT-named display list.

    Returns [(routine label, [(site, interp, list addr, list label, [text])], nsites)]"""
    named = dict(prom_b_lists())
    # prom_a's own lists count only when they carry a record of >= 4 characters --
    # a screen title.  The other 13 hold one punctuation glyph each (a ruler) and
    # 0xFE829B holds "14"; naming a routine from those would say nothing.
    named.update({a: v for a, v in prom_a_lists().items()
                  if v[1] and max(len(t) for t in v[1]) >= 4})
    _addr, pos = label_index(S_A)
    idx = [p[0] for p in pos]
    per = collections.defaultdict(list)
    for site, interp, y, x, line in dl_sites():
        k = bisect.bisect_right(idx, line) - 1
        if k < 0:
            continue
        per[pos[k][1]].append((site, interp, y))
    out = []
    for rt, ss in per.items():
        ss.sort()
        rows = [(s, i, y, named[y][0], named[y][1]) for s, i, y in ss
                if y in named and named[y][1]]
        if rows:
            out.append((rt, rows, len(ss)))
    out.sort(key=lambda r: r[1][0][0])
    return out


# --------------------------------------------------------------------------
# THE NAMES.  Every one is (old label, new label, why) and every alphabetic
# morpheme of every new label is checked against the ROM by --morphemes.
# --------------------------------------------------------------------------
PAINTER_NAMES = {
    "sub_F80261": "Paint_S0ngC0py",
    "sub_F80439": "Paint_N0teChange",
    "sub_F8076C": "Paint_MeasureC0py",
    "sub_F80AC9": "Paint_MeasureInsert",
    "sub_F80E2E": "Paint_S0ngSelectName",
    "sub_F80F5A": "Paint_StepRecordPartSelect",
    "sub_F81048": "Paint_SequencerMedley",
    "sub_F81AB5": "Paint_MasterTrackClear",
    "sub_F81BD4": "Paint_StepRecordTrackClrMeas",
    "sub_F9113F": "Paint_Drawbar",
    "sub_F9167C": "Paint_C0mbinati0nM0de",
    "sub_F927A6": "Paint_SoundGroupMenu",
    "sub_F928DB": "Paint_Drum",
    "sub_F92CE7": "Paint_GroupSoundDisplayHold",
    "sub_F935D7": "Paint_CombinationGroupMenu",
    "sub_F938B9": "Paint_GroupCombiDisplayHold",
    "sub_F99B82": "Paint_Sending",
    "sub_F99CA1": "Paint_SystemExclusivePleaseWait",
    "sub_F99D0C": "Paint_GeneralMidiMode",
    "sub_FE812C": "Paint_Sequencer",
    "sub_FE8394": "Paint_NoteEditPartSelect",
    "sub_FE83CD": "Paint_DrumEditPartSelect",
    "sub_FF0340": "Paint_NoteEdit",
    "sub_FF034F": "Paint_DrumEdit",
}
# framed -> content: prom_a's OWN display lists that carry a screen title
LIST_NAMES = {
    "DisplayList_FF0E2B": "DisplayList_SequencerRealtimeEdit",
    "DisplayList_FF0F11": "DisplayList_NoteEditTrackSong",
    "DisplayList_FF10E0": "DisplayList_DrumEditTrackSong",
    "DisplayList_FF1332": "DisplayList_NoteEditPartSelect",
    "DisplayList_FF158A": "DisplayList_DrumEditPartSelect",
}
# refused painters, and the reason, printed by --painters so the gap is on record
REFUSED = {
    "sub_F80384": 'its two named lists read "  ALL   " and "TRACK" -- field labels, '
                  'not a screen title; a name from them says nothing the list label '
                  'does not already say',
    "sub_F9291F": 'its two named lists read "USR2" and "USR1", four-character field '
                  'labels, and seven of its NINE display lists are unnamed',
    "sub_F929DB": 'runs the same list as 0xF92A10 (0xF2BA73, "R0M1"/"EXT1"/"R0M2"), so '
                  'the proposed name is not unique file-wide',
    "sub_F92A10": 'runs the same list as 0xF929DB (0xF2BA73), so the proposed name is '
                  'not unique file-wide',
}
TWIN_NAMES = {"sub_FB81CE": ("MemCopyWords_Copy", "MemCopyWords", 0xF8E6E2, 24)}
DUP_NAMES = {
    "sub_FAA0A0": ("Queue2C00_PublishStagedIfPending_StaleCopy",
                   "Queue2C00_PublishStagedIfPending", 0xFAA4A0),
    "sub_FAA204": ("ParamChange_Notify_StaleCopy", "ParamChange_Notify", 0xFAA604),
    "sub_FAA26A": ("ParamRecord_WriteFieldAndStage_StaleCopy",
                   "ParamRecord_WriteFieldAndStage_Copy", 0xFAA66A),
}
ACC_NAMES = {"sub_FDA48C": ("Arr2800_Set1", "Arr27D6_Set1"),
             "sub_FDA8BC": ("Var280E_GetW", "Var27F2_GetW")}
APPLIED = (set(PAINTER_NAMES.values()) | set(LIST_NAMES.values())
           | {v[0] for v in TWIN_NAMES.values()} | {v[0] for v in DUP_NAMES.values()}
           | {v[0] for v in ACC_NAMES.values()})
# pairs deliberately NOT taken: the differing bytes ARE the meaning
DUP_REFUSED = [
    ("MidiIn_CC0A_Pan", 0xFA66DA, 0xFA64E5, 65, 3),
    ("MidiIn_CC0A_Pan", 0xFA66DA, 0xFA6526, 65, 3),
    ("MidiOut_CC01_Modulation", 0xFA771D, 0xFA767E, 63, 4),
    ("MidiOut_CC01_Modulation", 0xFA771D, 0xFA77FA, 63, 3),
    ("PanelScreen_RequestPending", 0xFD60B9, 0xFDA901, 16, 3),
    ("PanelScreen_RequestPending", 0xFD60B9, 0xFDABF1, 16, 2),
    ("Ram3800_InitDataImage", 0xFC807D, 0xF9C058, 47, 9),
    ("Ram3800_InitDataImage", 0xFC807D, 0xFBFFA6, 47, 9),
    ("Remote_E80000_Read32Blocks", 0xFB24EC, 0xFB26E7, 151, 12),
    ("LCD_EntryThunks", 0xF8E800, 0xFE0000, 25, 15),
]


# --------------------------------------------------------------------------
# the morpheme guard -- the thing that makes "Home" impossible
# --------------------------------------------------------------------------
def split_camel(name):
    tail = name.split("_", 1)[1] if "_" in name else name
    return [w for w in re.findall(r'[A-Z][a-z0-9]*|[0-9]+', tail) if re.search(r'[A-Za-z]', w)]


def morpheme_check(verbose=False):
    """every alphabetic morpheme of every proposed name must occur VERBATIM in the
    ASCII of a display list the routine itself runs.  Returns list of failures."""
    # keyed by the label as it stands NOW, so the guard still runs after --apply
    p = {rt: rows for rt, rows, _n in painters()}
    fails = []
    rows = []
    for old, new in sorted(PAINTER_NAMES.items()):
        pool = "".join("".join(r[4]) for r in p.get(old, p.get(new, []))).upper()
        pool = re.sub(r'[^A-Z0-9]', '', pool)
        miss = [w for w in split_camel(new) if w.upper() not in pool]
        rows.append((old, new, len(pool), miss))
        if miss:
            fails.append((old, new, miss))
    for old, new in sorted(LIST_NAMES.items()):
        a = int(old.split("_")[1], 16)
        txt = prom_a_lists().get(a, ("", []))[1]
        pool = re.sub(r'[^A-Z0-9]', '', "".join(txt).upper())
        miss = [w for w in split_camel(new) if w.upper() not in pool]
        rows.append((old, new, len(pool), miss))
        if miss:
            fails.append((old, new, miss))
    if verbose:
        print("morpheme guard: every alphabetic morpheme of a proposed name must occur")
        print("verbatim in the ASCII the routine's OWN display lists contain.")
        for old, new, n, miss in rows:
            print("  %-22s -> %-32s pool=%4d chars  %s"
                  % (old, new, n, "OK" if not miss else "MISSING " + ",".join(miss)))
        print("  %d proposed names, %d failures" % (len(rows), len(fails)))
    return fails


# --------------------------------------------------------------------------
# lever 1: prom_a <-> prom_c
# --------------------------------------------------------------------------
def shared_runs(k=24, minset=4):
    A = open(R_A, "rb").read()
    C = open(R_C, "rb").read()
    idx = collections.defaultdict(list)
    for i in range(len(C) - k + 1):
        w = C[i:i + k]
        if len(set(w)) < minset:
            continue
        idx[w].append(i)
    seen, runs = set(), []
    for i in range(len(A) - k + 1):
        w = A[i:i + k]
        if len(set(w)) < minset:
            continue
        for j in idx.get(w, ()):
            d = i - j
            if (d, i) in seen:
                continue
            lo = 0
            while i - lo - 1 >= 0 and j - lo - 1 >= 0 and A[i - lo - 1] == C[j - lo - 1]:
                lo += 1
            hi = 0
            while i + hi + 1 < len(A) and j + hi + 1 < len(C) and A[i + hi + 1] == C[j + hi + 1]:
                hi += 1
            n = lo + hi + 1
            for t in range(i - lo, i - lo + n - k + 1):
                seen.add((d, t))
            runs.append((n, BASE + i - lo, BASE + j - lo))
    runs.sort(reverse=True)
    return runs


def twins(verbose=False):
    ra = routines(stream(S_A), cap=64, need_ret=False)
    rc = routines(stream(S_C), cap=64, need_ret=False)
    byseq = collections.defaultdict(list)
    for nm, (st, en, sq) in rc.items():
        if len(sq) >= 10:
            byseq[sq].append(nm)
    matches = []
    for nm, (st, en, sq) in ra.items():
        if len(sq) < 10:
            continue
        for cnm in byseq.get(sq, ()):
            matches.append((nm, st, cnm, len(sq)))
    useful = [m for m in matches
              if was_unnamed(m[0]) and not UNNAMED.match(m[2]) and not FRAMED.match(m[2])]
    if verbose:
        runs = shared_runs()
        print("prom_a <-> prom_c, RAW BYTES: %d maximal identical runs of >= 24 bytes, "
              "%d bytes total" % (len(runs), sum(r[0] for r in runs)))
        print("  longest five:")
        for n, a, c in runs[:5]:
            print("    %6d  prom_a %06X  prom_c %06X" % (n, a, c))
        print("prom_a <-> prom_c, STRUCTURE: %d prom_a routines share a prom_c routine's "
              "exact mnemonic sequence" % len(matches))
        for nm, st, cnm, n in sorted(matches, key=lambda m: m[1]):
            tag = "  <== USABLE" if (nm, st, cnm, n) in useful else ""
            print("    %-18s %06X  == prom_c %-24s (%d instructions)%s"
                  % (nm, st, cnm, n, tag))
        print("  usable (prom_a side sub_XXXXXX, prom_c side a content name): %d"
              % len(useful))
        A = open(R_A, "rb").read()
        C = open(R_C, "rb").read()
        for old, (new, src, srcaddr, ln) in TWIN_NAMES.items():
            st = ra[old][0]
            ca = rc[src][0]
            d = sum(1 for t in range(ln)
                    if A[st - BASE + t] != C[ca - BASE + t])
            e = sum(1 for t in range(ln)
                    if A[st - BASE + t] != A[srcaddr - BASE + t])
            print("  %s @%06X -> %s: %d of %d bytes differ from prom_c %s @%06X, "
                  "%d of %d from prom_a %s @%06X"
                  % (old, st, new, d, ln, src, ca, e, ln, src, srcaddr))
    return matches, useful


# --------------------------------------------------------------------------
# lever 2: prom_a against itself
# --------------------------------------------------------------------------
def dups(verbose=False):
    A = open(R_A, "rb").read()
    ra = routines(stream(S_A))
    byseq = collections.defaultdict(list)
    for nm, (st, en, sq) in ra.items():
        if len(sq) >= 6 and sq[-1] in ("ret", "reti", "retd"):
            byseq[sq].append((nm, st, en))
    groups = [g for g in byseq.values() if len(g) > 1]
    mixed = [g for g in groups
             if any(not was_unnamed(x[0]) for x in g) and any(was_unnamed(x[0]) for x in g)]
    # Two filters, and both were needed.  (a) A group whose members share ONE
    # address is a named data label plus a `sub_` label on the same object, not a
    # duplicate routine.  (b) A group whose NAMED member's label sits at a
    # different address from the first instruction under it is a DATA label
    # (DisplayList_FF0D2F, DisplayList_FEB0BC) whose bytes a linear decode happens
    # to print as instructions; comparing those compares display-list records.
    at = first_addr_comment(S_A)
    real = [g for g in mixed if len({x[1] for x in g}) > 1
            and all(at.get(x[0]) == x[1] for x in g if not was_unnamed(x[0]))]
    if verbose:
        print("prom_a against itself: %d groups share a mnemonic sequence (>= 6 "
              "instructions, ret-terminated)" % len(groups))
        print("  %d mix a named routine with a sub_XXXXXX" % len(mixed))
        print("  %d of those are at DIFFERENT addresses (the rest are two labels on one "
              "object)" % len(real))
        for g in sorted(real, key=lambda g: g[0][1]):
            named = [x for x in g if not was_unnamed(x[0])][0]
            for x in g:
                if not was_unnamed(x[0]):
                    continue
                n = min(named[2] - named[1], x[2] - x[1])
                d = sum(1 for t in range(n)
                        if A[named[1] - BASE + t] != A[x[1] - BASE + t])
                inv = {v[0]: k for k, v in DUP_NAMES.items()}
                inv.update({v[0]: k for k, v in ACC_NAMES.items()})
                inv.update({v[0]: k for k, v in TWIN_NAMES.items()})
                key = inv.get(x[0], x[0])
                verdict = ("TAKEN" if key in DUP_NAMES else
                           "taken by --accessors" if key in ACC_NAMES else
                           "taken by --twins" if key in TWIN_NAMES else "refused")
                print("    %-36s %06X  <- %-14s %06X  %d bytes, %d differ   %s"
                      % (named[0], named[1], x[0], x[1], n, d, verdict))
        print("  refused pairs and why: the differing bytes are the table pointer or the")
        print("  cell the routine reads, so the name would name the wrong object.")
    return groups, mixed, real


# --------------------------------------------------------------------------
# lever 3: single-cell accessors round 3 could not see
# --------------------------------------------------------------------------
ACC = re.compile(r'^(Var|Arr)([0-9A-F]{4})_([A-Za-z0-9]+)$')


def accessors(verbose=False):
    A = open(R_A, "rb").read()
    ra = routines(stream(S_A), cap=64)
    tmpl = []
    for nm, (st, en, sq) in ra.items():
        m = ACC.match(nm)
        if not m or en - st > 64:
            continue
        cell = int(m.group(2), 16)
        body = A[st - BASE:en - BASE]
        le = bytes([cell & 0xFF, (cell >> 8) & 0xFF])
        pos = [k for k in range(len(body) - 1) if body[k:k + 2] == le]
        if len(pos) == 1:
            tmpl.append((nm, m.group(1), m.group(3), body, pos[0]))
    found, byname = {}, collections.defaultdict(list)
    subs = {nm: v for nm, v in ra.items() if was_unnamed(nm) and v[1] - v[0] <= 64}
    for snm, (st, en, sq) in subs.items():
        body = A[st - BASE:en - BASE]
        for tnm, kind, sfx, tb, p in tmpl:
            if len(tb) != len(body):
                continue
            diff = [k for k in range(len(tb)) if tb[k] != body[k]]
            if diff and set(diff) <= {p, p + 1}:
                cell = body[p] | (body[p + 1] << 8)
                new = "%s%04X_%s" % (kind, cell, sfx)
                found[snm] = (new, tnm, st, len(tb), len(diff))
                byname[new].append(snm)
                break
    for k, v in list(byname.items()):
        # `k in ra` would reject a name this pass has already applied, so the two
        # rows have to survive their own --apply
        if len(v) > 1 or (k in ra and k not in APPLIED):
            for s in v:
                found.pop(s, None)
    if verbose:
        print("%d already-named single-cell accessors are usable as byte templates"
              % len(tmpl))
        print("%d sub_XXXXXX routines have a `ret` within 64 bytes" % len(subs))
        print("%d are byte-for-byte a named accessor except in the two bytes that hold "
              "the cell address:" % len(found))
        for s in sorted(found, key=lambda x: found[x][2]):
            new, tnm, st, ln, d = found[s]
            print("   %s @%06X -> %-14s  (template %s, %d bytes, %d differing)"
                  % (s, st, new, tnm, ln, d))
    return found


# --------------------------------------------------------------------------
# the plan, and applying it
# --------------------------------------------------------------------------
def gap_painters():
    """prom_a routines that run ONLY display lists nothing has named.

    These are the other half of the thesis.  The mechanism is fully established --
    the routine paints something -- and the screen is NOT, because its lists carry
    no `.ascii` for the round-4 rule to read.  They get a HEADER that says exactly
    that and they keep `sub_XXXXXX`.  Returns [(label, [(site, interp, list)],
    instruction count)]."""
    named = dict(prom_b_lists())
    named.update({a: v for a, v in prom_a_lists().items()
                  if v[1] and max(len(t) for t in v[1]) >= 4})
    _addr, pos = label_index(S_A)
    idx = [q[0] for q in pos]
    per = collections.defaultdict(list)
    for site, interp, y, x, line in dl_sites():
        k = bisect.bisect_right(idx, line) - 1
        if k >= 0:
            per[pos[k][1]].append((site, interp, y, x))
    ra = routines(stream(S_A), cap=400, need_ret=False)
    out = []
    for rt, ss in per.items():
        if any(t[2] in named for t in ss):
            continue
        if not was_unnamed(rt) or rt not in ra:
            continue
        st, en, sq = ra[rt]
        # ⚠ TWO filters, and a header would have been WRONG without either.
        # (a) the enclosing-label walk attributes a site to the last label above
        #     it, so a site BEYOND this routine's first `ret` belongs to an
        #     unlabelled routine underneath, not to this one;
        # (b) six of the 288 sites do not resolve XIY, and printing 0x000000 as a
        #     list address would be a fabricated citation.
        keep = [t for t in ss if t[2] is not None and t[3] is not None
                and en is not None and t[0] < en]
        if not keep:
            continue
        out.append((rt, sorted(keep), len(sq)))
    out.sort(key=lambda r: r[1][0][0])
    return out


def has_header(src, i, minlines=3):
    """the same rule notes/wave7_documentation_metrics.py counts a header by:
    >= 3 consecutive comment lines above, at most ONE blank line between."""
    run = blanks = 0
    j = i - 1
    while j >= 0:
        if src[j].startswith(";"):
            run += 1
            blanks = 0
        elif src[j].strip() == "" and blanks < 1:
            blanks += 1
        else:
            break
        j -= 1
    return run >= minlines


def gap_header(rt, ss, ninsn):
    L = ["; %s -- a display-list painter whose SCREEN IS NOT ESTABLISHED" % rt,
         ";",
         "; Its body reaches the display-list interpreters %d time(s) in the %d"
         % (len(ss), ninsn),
         "; instructions to its first `ret`:"]
    for site, interp, y, x in ss:
        L.append(";     site 0x%06X  interpreter %s  list 0x%06X-0x%06X"
                 % (site, interp, y or 0, x or 0))
    L.append("; Evidence: the list bounds are the `ld XIY,0x00...` and `ld XIX,0x00...`")
    L.append(";          immediates of the LAST such loads before each cited `call` -- within")
    L.append(";          five instructions above it; --selftest measures every distance;")
    L.append(";          0xF417F0 enters interpreter A and 0xF417F4 interpreter B")
    L.append(";          (notes/FINDINGS-ui-display-list.md).")
    L.append("; Unknown: WHAT SCREEN.  Not one of these lists holds an `.ascii` record,")
    L.append(";          so the rule that named 24 of prom_a's painters -- take the")
    L.append(";          name from the text the list draws -- has nothing to read here.")
    L.append(";          The label stays sub_XXXXXX on purpose; naming it would need the")
    L.append(";          list's opcodes decoded or a caller that says what it is.")
    L.append("; ---------------------------------------------------------------------")
    return L


def apply_gaps():
    rows = gap_painters()
    src = open(S_A).read().split("\n")
    ins = []
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if not m:
            continue
        for rt, ss, n in rows:
            if m.group(1) == rt and not has_header(src, i):
                ins.append((i, gap_header(rt, ss, n)))
                break
    for i, block in reversed(ins):
        src[i:i] = block
    open(S_A, "w").write("\n".join(src))
    print("applied: %d gap headers (of %d gap painters; the rest already had one)"
          % (len(ins), len(rows)))
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


HDR_SITE = re.compile(r'^;\s+site 0x([0-9A-F]{6})\s+interpreter ([AB])\s+list 0x([0-9A-F]{6})')


def verify_headers(verbose=False):
    """Re-derive every header this pass wrote and compare it with what is in the
    file.  Returns the list of mismatches.

    ⚠ THIS CHECK EXISTS BECAUSE IT CAUGHT A REAL CORRUPTION.  A repair pass that
    edited the source list while enumerating it shifted its own indices and wrote
    ONE painter's site lines into ANOTHER's header (0xF9291F's `DL_Usr2`/`DL_Usr1`
    into Paint_Drum's).  The byte gate saw nothing: they are comments.  Nothing but
    a check that reads the header BACK and compares it with the data could see it,
    so the check is permanent."""
    src = open(S_A).read().split("\n")
    P = {rt: rs for rt, rs, _n in painters() if rt in set(PAINTER_NAMES.values())}
    G = {rt: ss for rt, ss, _n in gap_painters()}
    bad = []
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if not m:
            continue
        nm = m.group(1)
        if nm not in P and nm not in G:
            continue
        st = None
        for j in range(i - 1, max(0, i - 90), -1):
            if src[j].startswith("; %s -- " % nm):
                st = j
                break
            if not (src[j].startswith(";") or src[j].strip() == ""):
                break
        if st is None:
            bad.append((nm, "no header"))
            continue
        got = [(int(a, 16), b, int(c, 16))
               for a, b, c in (HDR_SITE.match(x).groups() for x in src[st:i]
                               if HDR_SITE.match(x))]
        want = ([(s0, ip, ad) for s0, ip, ad, _l, _t in P[nm]] if nm in P
                else [(s0, ip, y) for s0, ip, y, _x in G[nm]])
        if got != want:
            bad.append((nm, "sites %r != %r" % (got, want)))
        elif not any(x.startswith("; Evidence:") for x in src[st:i]):
            bad.append((nm, "no Evidence line"))
        elif not src[i - 1].startswith("; ---"):
            bad.append((nm, "header does not end on the rule line"))
    if verbose:
        print("%d headers written by this pass re-derived and compared; %d mismatch"
              % (len(P) + len(G), len(bad)))
        for b in bad:
            print("   ", b)
    return bad


def plan():
    out = []
    p = {rt: rows for rt, rows, _n in painters()}
    for old, new in sorted(PAINTER_NAMES.items(), key=lambda kv: kv[0]):
        rows = p.get(old, [])
        out.append((old, new, "painter", rows))
    for old, new in sorted(LIST_NAMES.items()):
        out.append((old, new, "display list", []))
    for old, (new, src, addr, ln) in sorted(TWIN_NAMES.items()):
        out.append((old, new, "prom_c twin of %s" % src, []))
    for old, (new, src, addr) in sorted(DUP_NAMES.items()):
        out.append((old, new, "stale copy of %s @%06X" % (src, addr), []))
    for old, (new, src) in sorted(ACC_NAMES.items()):
        out.append((old, new, "accessor sibling of %s" % src, []))
    return out


def header_for(old, new, kind, rows):
    L = []
    if kind == "painter":
        first = rows[0]
        nsites = next((n for rt, rs, n in painters() if rs == rows), len(rows))
        L.append("; %s -- paints the screen whose own text reads %s"
                 % (new, ", ".join('"%s"' % t for t in first[4][:3])))
        L.append(";")
        L.append("; It reaches the display-list interpreters at 0xF417F0 (A) and 0xF417F4 (B)")
        L.append("; %d time(s); XIY = list start, XIX = list end.  %d of those %d list(s)"
                 % (nsites, len(rows), nsites))
        L.append("; carry text, and those are the ones that name this routine:")
        for site, interp, addr, lab, txt in rows:
            L.append(";     site 0x%06X  interpreter %s  list 0x%06X  %s" % (site, interp, addr, lab))
            L.append(";        text: %s" % "; ".join('"%s"' % t for t in txt[:6]))
        L.append("; Evidence: the list address is the `ld XIY,0x00%06X` IMMEDIATE at the"
                 % rows[0][2])
        L.append(";          instruction two before the cited `call`, and the text quoted")
        L.append(";          above is the `.ascii` the interpreter draws verbatim.  Every")
        L.append(";          alphabetic morpheme of this name occurs in that text; the")
        L.append(";          check is notes/prom_a_understanding_round5.py --morphemes.")
        L.append(";          `Paint_` is a structural verb, not ROM text.")
        L.append("; Unknown: whether this routine also handles input for the screen, and")
        L.append(";          whether any other routine paints it.  Neither was searched.")
    elif kind == "display list":
        a = int(old.split("_")[1], 16)
        txt = prom_a_lists().get(a, ("", []))[1]
        L.append("; %s -- the display list at 0x%06X, renamed from its framed label"
                 % (new, a))
        L.append(";                  `%s`.  Its own text records read:" % old)
        L.append(";     %s" % "; ".join('"%s"' % t for t in txt[:10]))
        L.append("; Evidence: the `.ascii` literals printed below this label, which the")
        L.append(";          display-list interpreter draws verbatim.  The name is the")
        L.append(";          CamelCase of the first of them and says what the list PUTS ON")
        L.append(";          THE SCREEN and nothing more -- the rule wave 7 round 4 used")
        L.append(";          for prom_b's 249 named lists.")
    elif kind.startswith("prom_c twin"):
        L.append("; %s -- a second, byte-identical copy of %s" % (new, kind.split("of ")[1]))
        L.append(";")
        L.append("; Evidence: 24 of 24 bytes equal to prom_a's MemCopyWords at 0xF8E6E2 and")
        L.append(";          to prom_c's at 0xF9A038 (zero differing on both diffs), and the")
        L.append(";          eleven-instruction mnemonic sequence is identical.  Reproduced")
        L.append(";          by notes/prom_a_understanding_round5.py --twins, which prints")
        L.append(";          the differing count for both diffs.")
        L.append("; Unknown: why the copy exists, and which of the two the callers of this")
        L.append(";          address use.  Neither was established.")
    elif kind.startswith("stale copy"):
        L.append("; %s -- the stale copy of %s" % (new, kind.split("of ")[1]))
        L.append(";")
        L.append("; Evidence: 0xFAA018-0xFAA3FF is a copy of 0xFAA418-0xFAA7FF differing in")
        L.append(";          exactly ten bytes, established in")
        L.append(";          notes/FINDINGS-prom_a-message-module.md section 3a; this")
        L.append(";          routine's own body is byte-identical to its twin at +0x400.")
        L.append(";          Nothing publishes an entry into the copy: zero directory slots")
        L.append(";          point into it against 37 for the live block.")
        L.append("; Unknown: whether anything ever calls it.  The name asserts what the code")
        L.append(";          IS, not that it runs.")
    else:
        L.append("; %s -- %s" % (new, kind))
        L.append(";")
        L.append("; Evidence: byte-for-byte identical to that routine except in the two")
        L.append(";          bytes that hold the absolute cell address, so it is the same")
        L.append(";          single-cell accessor on a different cell.  Round 3's pass")
        L.append(";          (notes/prom_a_naming_round3.py) could not see it because its")
        L.append(";          `ret` carries a label of its own and the body extraction")
        L.append(";          stopped one instruction short.  Reproduced by")
        L.append(";          notes/prom_a_understanding_round5.py --accessors.")
        L.append("; Unknown: what the cell holds.  The name states the cell and the")
        L.append(";          direction and claims nothing about meaning.")
    L.append("; ---------------------------------------------------------------------")
    return L


def apply():
    fails = morpheme_check()
    if fails:
        print("REFUSING to apply: the morpheme guard failed on %s" % fails)
        return 1
    rows = plan()
    src = open(S_A).read().split("\n")
    # a rename that lands on an existing label would silently merge two objects
    existing = {m.group(1) for m in (LABEL.match(l) for l in src) if m}
    clash = [n for _o, n, _k, _r in rows if n in existing]
    if clash:
        print("REFUSING to apply: these names already exist in prom_a: %s" % clash)
        return 1
    missing = [o for o, _n, _k, _r in rows if o not in existing]
    if missing:
        print("REFUSING to apply: these labels are not in prom_a (already renamed?): %s"
              % missing)
        return 1
    # 1. headers, inserted above the label line (walk from the end so line numbers hold)
    want = {old: (new, kind, r) for old, new, kind, r in rows}
    ins = []
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if m and m.group(1) in want:
            new, kind, r = want[m.group(1)]
            ins.append((i, header_for(m.group(1), new, kind, r)))
    for i, block in reversed(ins):
        src[i:i] = block
    text = "\n".join(src)
    # 2. rename every occurrence of the label as a whole word
    for old, new, _k, _r in rows:
        text = re.sub(r'\b%s\b' % re.escape(old), new, text)
    open(S_A, "w").write(text)
    print("applied: %d renames, %d header blocks inserted into %s"
          % (len(rows), len(ins), S_A))
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


# --------------------------------------------------------------------------
def selftest():
    ok = fail = 0

    def chk(name, cond, got=""):
        nonlocal ok, fail
        if cond:
            ok += 1
            print("  PASS  %s" % name)
        else:
            fail += 1
            print("  FAIL  %s  %s" % (name, got))

    p = painters()
    chk("painters(): 28 routines run a content-named list (23 prom_b + 5 prom_a)",
        len(p) == 28, "got %d" % len(p))
    nsub = sum(1 for r in p if was_unnamed(r[0]))
    chk("all 28 were sub_XXXXXX before this pass", nsub == 28, "got %d" % nsub)
    # FIRST and LAST row of the painter table
    chk("FIRST painter row is 0xF80261's, running the list whose text opens \"S0NG C0PY\"",
        p[0][1][0][4][0] == "S0NG C0PY", "got %r" % (p[0][1][0][4][:1],))
    chk("LAST painter row is 0xFF034F's, running the list whose text opens \"DRUM EDIT\"",
        p[-1][1][0][4][0] == "DRUM EDIT", "got %r" % (p[-1][1][0][4][:1],))
    chk("morpheme guard passes on all %d proposed names" % (len(PAINTER_NAMES) + len(LIST_NAMES)),
        morpheme_check() == [])
    # the sentence every painter header states, pinned by a check
    XIY = re.compile(r'^XIY,0x00([0-9a-f]{6})$')
    items = stream(S_A)
    dist = {}
    for i, it in enumerate(items):
        if it[0] != "I" or it[1] != "call" or it[2] not in INTERP:
            continue
        d, j = 0, i - 1
        while j >= 0 and d < 8:
            jt = items[j]
            if jt[0] == "I":
                d += 1
                if jt[1] == "ld" and XIY.match(jt[2].replace(" ", "")):
                    dist[it[3]] = d
                    break
            j -= 1
    off = [(rt, s0) for rt, rs, _n in p for s0, _i, _a, _l, _t in rs if dist.get(s0) != 2]
    chk("every NAMED painter site's `ld XIY` is EXACTLY two instructions before the "
        "`call` -- the sentence those 24 headers state", not off, "got %r" % off[:4])
    # ⚠ and it is NOT two everywhere: four gap sites put one or three instructions
    # between the load and the call, which is why the 73 gap headers say "the LAST
    # such loads ... within five instructions" and not "two instructions before"
    gsp = [(rt, s0, dist.get(s0)) for rt, ss, _n in gap_painters()
           for s0, _i, _y, _x in ss]
    chk("every site quoted in a GAP header has its `ld XIY` within FIVE instructions",
        all(d is not None and d <= 5 for _r, _s, d in gsp),
        "got %r" % [g for g in gsp if not g[2] or g[2] > 5][:4])
    chk("and four of them are NOT two (two at distance 3, two at distance 5) -- the "
        "reason those 73 headers do not say 'two'",
        sum(1 for _r, _s, d in gsp if d != 2) == 4,
        "got %r" % sorted({d for _r, _s, d in gsp}))
    unhandled = [rt for rt, _rs, _n in p
                 if rt not in PAINTER_NAMES and rt not in REFUSED
                 and rt not in set(PAINTER_NAMES.values())]
    chk("every painter row is either named or listed in REFUSED with a reason",
        not unhandled, "got %r" % unhandled)
    src = open(S_A).read()
    present = [n for _o, n, _k, _r in plan() if re.search(r'^%s:' % re.escape(n), src, re.M)]
    # a DEFINITION, not any mention: five headers legitimately quote the framed
    # label they replaced, and an occurrence test would call that a survivor
    gone = [o for o, _n, _k, _r in plan()
            if re.search(r'^%s:' % re.escape(o), src, re.M)
            or re.search(r'\b%s\b(?!`)' % re.escape(o), src.replace("`%s`" % o, ""))]
    chk("after --apply all 35 new labels are defined in prom_a", len(present) == 35,
        "got %d" % len(present))
    chk("after --apply none of the 35 old labels survives anywhere in prom_a",
        not gone, "got %r" % gone[:4])
    sites = dl_sites()
    chk("288 display-list call sites in prom_a", len(sites) == 288, "got %d" % len(sites))
    res = [s for s in sites if s[2] is not None and s[3] is not None]
    chk("282 of them resolve both XIY and XIX", len(res) == 282, "got %d" % len(res))
    inb = [s for s in res if s[2] < 0xF80000]
    chk("191 of the resolved sites pass a list that lives in prom_b",
        len(inb) == 191, "got %d" % len(inb))
    named_b = prom_b_lists()
    chk("249 prom_b lists carry a content name and a header address",
        len(named_b) == 249, "got %d" % len(named_b))
    chk("FIRST of them, 0xF01800, is DL_SoundEditWriteCopy reading \"SOUND EDIT\"",
        named_b.get(0xF01800, ("", []))[0] == "DL_SoundEditWriteCopy"
        and named_b[0xF01800][1][0] == "SOUND EDIT")
    last = max(named_b)
    chk("LAST of them, 0x%06X, carries at least one .ascii record" % last,
        len(named_b[last][1]) >= 1, "got %r" % (named_b[last],))
    pa = {a: v for a, v in prom_a_lists().items() if v[1]}
    chk("18 of prom_a's own 91 DisplayList_ labels carry .ascii", len(pa) == 18,
        "got %d" % len(pa))
    chk("the LAST prom_a list with text, 0xFF158A, opens \"DRUM\"",
        pa[max(pa)][1][0] == "DRUM", "got %r" % (pa[max(pa)][1][:1],))
    m, useful = twins()
    chk("exactly 3 prom_a routines share a prom_c mnemonic sequence", len(m) == 3,
        "got %d" % len(m))
    chk("exactly 1 of them is usable (sub_ here, content name there)", len(useful) == 1,
        "got %r" % (useful,))
    chk("and it is the routine at 0xFB81CE, == prom_c's MemCopyWords",
        useful and useful[0][1] == 0xFB81CE and useful[0][2] == "MemCopyWords",
        "got %r" % (useful,))
    g, mixed, real = dups()
    chk("55 mnemonic-sequence groups mix a named routine with a sub_XXXXXX",
        len(mixed) == 55, "got %d" % len(mixed))
    chk("12 groups survive both filters (different addresses, named member is code)",
        len(real) == 12, "got %d" % len(real))
    taken = sum(1 for g in real for x in g if x[0] in APPLIED)
    chk("6 of the 16 pairs in those groups are taken, 10 refused", taken == 6,
        "got %d" % taken)
    acc = accessors()
    chk("exactly 2 new single-cell accessor siblings", len(acc) == 2, "got %r" % list(acc))
    gp = gap_painters()
    chk("73 routines run ONLY display lists nothing has named, inside their own body",
        len(gp) == 73, "got %d" % len(gp))
    ra2 = routines(stream(S_A), cap=400, need_ret=False)
    bad = [(rt, s0) for rt, ss, _n in gp for s0, _i, _y, _x in ss
           if ra2[rt][1] is None or s0 >= ra2[rt][1]]
    chk("every site quoted in a gap header lies before its routine's first `ret`",
        not bad, "got %r" % bad[:3])
    chk("none of the 73 shares a routine with the 24 named painters",
        not (set(r[0] for r in gp) & set(PAINTER_NAMES.values())))
    src2 = open(S_A).read().split("\n")
    li = {}
    for i, ln in enumerate(src2):
        mm = LABEL.match(ln)
        if mm and mm.group(1) not in li:
            li[mm.group(1)] = i
    nohdr = [r[0] for r in gp if r[0] in li and not has_header(src2, li[r[0]])]
    chk("after --apply_gaps every one of them carries a header", not nohdr,
        "%d without" % len(nohdr))
    vh = verify_headers()
    chk("all 97 headers this pass wrote still match the data they were derived from",
        not vh, "got %r" % vh[:3])
    lastacc = max(acc, key=lambda k: acc[k][2]) if acc else None
    chk("the LAST accessor sibling by address carries the name Var280E_GetW",
        lastacc and acc[lastacc][0] == "Var280E_GetW", "got %r" % (acc,))
    print("%d checks passed, %d failed" % (ok, fail))
    return 1 if fail else 0


def main():
    ap = argparse.ArgumentParser()
    for f in ("painters", "twins", "dups", "accessors", "morphemes", "plan", "apply",
              "gaps", "apply_gaps", "verify_headers", "selftest"):
        ap.add_argument("--" + f, action="store_true")
    o = ap.parse_args()
    if o.painters:
        rows = painters()
        print("prom_a routines that run at least one CONTENT-named display list: %d" % len(rows))
        for rt, rs, n in rows:
            print("  %-32s %d display-list site(s), %d named" % (rt, n, len(rs)))
            for site, interp, addr, lab, txt in rs:
                print("      site %06X  %s  list %06X  %-42s %s"
                      % (site, interp, addr, lab, "; ".join('"%s"' % t for t in txt[:4])))
        print()
        print("NOT named on purpose:")
        for k, v in sorted(REFUSED.items()):
            print("  %-14s %s" % (k, v))
    if o.twins:
        twins(verbose=True)
    if o.dups:
        dups(verbose=True)
    if o.accessors:
        accessors(verbose=True)
    if o.morphemes:
        return 1 if morpheme_check(verbose=True) else 0
    if o.plan:
        for old, new, kind, rows in plan():
            print("  %-22s -> %-34s  %s" % (old, new, kind))
        print("  %d renames" % len(plan()))
    if o.gaps:
        rows = gap_painters()
        print("prom_a routines that run ONLY unnamed display lists: %d" % len(rows))
        for rt, ss, n in rows:
            print("  %-14s %2d site(s), %3d instructions: %s"
                  % (rt, len(ss), n, ", ".join("%06X/%s" % (t[2] or 0, t[1]) for t in ss)))
    if o.apply:
        return apply()
    if o.apply_gaps:
        return apply_gaps()
    if o.verify_headers:
        return 1 if verify_headers(verbose=True) else 0
    if o.selftest:
        return selftest()
    if not any(vars(o).values()):
        ap.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
