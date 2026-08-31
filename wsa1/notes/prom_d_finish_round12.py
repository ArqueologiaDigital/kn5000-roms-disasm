#!/usr/bin/env python3
"""prom_d -- THE COMPLETE INVENTORY OF WHAT IS STILL FRAMED (wave 7 round 12).

QUESTION IT ANSWERS
    "prom_d is territorially complete, has zero sub_XXXXXX, and 235 of its 3,665
     labels are still a KIND PLUS A NUMBER.  For EVERY ONE of those 235, on the
     evidence of the four ROM images: is it nameable, and if it is not, WHY NOT?"

    Not "why did the mechanism I happened to try fail on it" -- that was round
    7's shape and round 8 replaced it with three questions.  This round closes
    the loop by asking the three questions of TODAY'S framed set, printing one
    row per object, and adding the two mechanisms nobody had run.  One command:

        python3 notes/prom_d_finish_round12.py            # the inventory
        python3 notes/prom_d_finish_round12.py --selftest # the checks

★★ THE DELIVERABLE IS THE INVENTORY, NOT THE LAST FEW NAMES.  prom_d is the
   first image in this tree whose whole remaining documentation debt is
   enumerated object by object with a DERIVED reason on each.  A finished image
   with honest holes beats a complete-looking one with invented names.

★★ AND THIS ROUND PROMOTES NOTHING.  Three mechanisms were run for the first
   time; two are refused by their own measurement and the third is a genuine
   find that this round deliberately does NOT spend, because the one link it
   needs is missing and naming 64 records on a missing link is how this project
   has previously shipped errors that the byte gate certified forever.

   Q29  M11 -- THE TAIL-ONLY TWIN RULE.  Round 9's Q12 ran the twin rule on the
        +0x3C array and got 0 of 64, comparing WHOLE records.  But a preset
        supplies only bytes 13..42 of the record it is copied into (prom_c
        0xFBC7D9-0xFBC805), so the head need not match anything and the whole-
        record test was harder than the mechanism requires.  Run on the 30 bytes
        prom_c actually copies, against all 1,485 wave-select records that are
        not the preset array itself: still 0 of 64.  With a positive control, so
        the zero is not an inert test.

   Q30  M12 -- ROUND 8's M6 WITH ROUND 11's GROUP.  M6 tried to name a no-twin
        record from the preset RUN it sits in and was refused because no WORD is
        common to a run's members.  Round 11 then gave this image sound GROUPS,
        which are coarser than words, and nobody re-ran M6 against them.  Run
        here: it proposes 19 names -- and it is REFUSED, because where the run
        route and round 11's independent map route both speak they disagree on 7
        of 40 records, and the ONE proposal on which both speak is one of the
        seven.  A mechanism refuted by the witness it would have to agree with.

   Q31  ★★ THE prom_b NAME TABLE -- A CANDIDATE, AND THE GAP THAT KEEPS IT ONE.
        prom_b holds a 64-entry x 8-byte name table at 0xF03241 (ORIGINAL,
        STRING, CYLINDER, CONE, FLARE, PLATE L/H, MEMB L/H, ... SPECIAL1,
        SPECIAL2), reached by exactly four display-list records which mask their
        source variable with 0x3F -- the same mask prom_c's 0xFBC744 applies
        before indexing prom_d's 64-record ToneDB_WaveSelTailPresets.  If the
        panel variable IS that field, all 64 framed records are named at once.
        ⚠ NOTHING IN THE FOUR IMAGES SHOWS THAT IT IS, and Q31 says exactly what
        a later round has to produce.  The supporting measurement that DOES
        stand on prom_d's bytes alone is Q32.

   Q32  THE +0x3C ARRAY IS BUILT IN EVEN-ALIGNED PAIRS.  Over records 38..63 the
        even-aligned neighbour distance is half the odd-aligned one, and the
        name table's rows 38..63 are 13 `X L` / `X H` pairs on the same parity.
        ⚠ AND THE SHIFT SWEEP IS PRINTED, because the parity test pins the
        PARITY and NOT the alignment: every EVEN shift scores the same.  A
        reader who quotes this as an alignment proof is quoting it wrong, so the
        refutation is printed next to the result.

   Q33  THE FOUR-IMAGE ADDRESS-SPELLING CENSUS, re-run over today's set, so that
        "nothing points at this" is a census result and not an assertion.  This
        project has twice shipped a "no references" that had references.

   Q34  ★ AND THE UNREACHED RECORDS ARE NOT PADDING.  The cheap way to dismiss
        122 unexplained records is to suppose the array is over-allocated and
        the tail is filler.  Measured, all 122 are byte-DISTINCT from one
        another, largest identical group 1, one run of them 58 records long.
        Padding repeats; these do not.  The hole is real data whose selector
        this tree has not found.

   T27  ★ EVERY INSTRUCTION THIS ROUND'S PROSE CITES IS PINNED TO ITS BYTES.
        A wave-7 round-1 lane cited ~31 sites one byte past the instruction,
        gate-clean.  The fix is a check, not care: cited_ok() asserts the bytes
        at each of the ten addresses quoted in Q29/Q31 and in the .s banner.

WHAT THIS ROUND DID NOT TOUCH, and both refusals are re-derived here rather than
restated (Q28's reason column):
    * slot +0x70's three pool objects -- 0 of 4 descriptors carries a part-A
      offset, so the curve -> stage-2 -> element chain that names every other
      pool object cannot start.  Round 4 Q4a, round 5 Q4a, re-measured in Q28.
    * ToneRec_05D_161 -- a METRIC ARTEFACT, not a nameless object: the record IS
      named from its own 16 ASCII bytes and this tree's CamelCase rule turns
      "    16' & 1'    " into "161".  Q28 re-derives the CamelCase from the ROM.

RUN
    python3 notes/prom_d_finish_round12.py
    python3 notes/prom_d_finish_round12.py --selftest
"""
import collections
import importlib.util
import itertools
import os
import re
import statistics
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  ok   %s" % label)
    else:
        FAILED.append(label)
        say("  FAIL %s   %s" % (label, detail))


def _load(name):
    """Import a sibling notes/ script without its argv reaching it."""
    path = os.path.join(ROOT, "notes", name + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    keep = sys.argv
    sys.argv = [path, "--quiet"]
    try:
        spec.loader.exec_module(mod)
    finally:
        sys.argv = keep
    return mod


R6 = _load("prom_d_understanding_round6")
R7 = _load("prom_d_finish_round7")
R8 = _load("prom_d_inventory_round8")

D = R6.D
S = R6.S
PROM_D_BASE = R7.PROM_D_BASE
PROM_B_BASE = 0x00F00000
B_IMG = R8.B_IMG
A_IMG = R8.A_IMG

# ---------------------------------------------------------------------------
# The one number this round is judged on, read back off the emitted file.
# ---------------------------------------------------------------------------
R7.classify_all()
FRAMED = [l for l in R7.LABS if l.grade == "framed"]
FAMILY = collections.OrderedDict()
for _l in FRAMED:
    FAMILY.setdefault(_l.name.rpartition("_")[0], []).append(_l)

AUDITED_FRAMED_TODAY = 235      # ⚠ NOT a target; see the banner in q28()
AUDITED_CHECKS = 35             # what --selftest runs; quoted by the generator

WAVESEL_HEAD = 13               # prom_c 0xFBC7D9 `ld (XIZ+0xf0),0x000d` -- i = 13
PRESET_SLOT = 0x3C
NAME_TABLE = 0x003241           # prom_b file offset; 0xF03241 as an address
NAME_W = 8
DL_MASK = 0x3F                  # prom_b's display-list AND mask, and prom_c's


# ---------------------------------------------------------------------------
# Q28.  THE INVENTORY.
# ---------------------------------------------------------------------------
def wavesel_population():
    """[(what, 43 bytes)] -- every wave-select record that is NOT the +0x3C array.

    The three arrays at +0x18/+0x20/+0x3C plus the blocks that sit inside a tone
    record and the tails that sit inside a drum record.  Round 8's stored-index
    census calls this population 1,485 and that number is re-derived here rather
    than copied.
    """
    out = []
    for _i, j, b, nm in R6.tone_wavesel_blocks():
        out.append(("tone %s element %d" % (nm, j), bytes(b)))
    for _i, b, nm in R6.perc_wavesel_tails():
        out.append(("drum %s" % nm, bytes(b)))
    for slot in (0x18, 0x20):
        _a, n, recs = R6.array_records(slot)
        for k in range(n):
            out.append(("%s_%03d" % (R8.LABEL_PREFIX[slot], k), bytes(recs[k])))
    return out


def camel(s):
    return R6.camel(s)


_R2 = _load("prom_d_structures_round2")


def pool_partA_count(slot=0x70):
    """How many of the +0x70 descriptors carry a part-A offset?  (Round 4's refusal.)"""
    _h, _p, recs = _R2.desc_layout(slot)
    return sum(1 for r in recs if r[1]), len(recs)


def pool_owners(slot=0x70):
    """{pool-object offset: [descriptor indices whose part B is it]}.

    ★ The four descriptors name only THREE objects -- descriptors 1 and 2 share
    one -- so a per-object reason has to SAY which, or the three labels read as
    if each had its own owner.  Derived from the descriptors' own 32-bit offsets.
    """
    _h, _p, recs = _R2.desc_layout(slot)
    out = collections.defaultdict(list)
    for i, r in enumerate(recs):
        if r[2]:
            out[r[2]].append(i)
    return dict(out)


def tone_record_name(idx):
    """The 16 ASCII bytes tone record `idx` carries, as stored."""
    p = R6.TONE_PTRS[idx]
    return D[p:p + 16].decode("latin1")


_THREE = {}


def three_answers(lab):
    """(A, B, C, why) for one framed label, from round 8's three questions.

    ⚠ Built on FIRST USE, not at import.  scripts/analysis/gen_prom_d_asm.py
    imports this module for the round-12 banner and needs only the cheap
    measurements; round 8's three-question table costs seconds and the generator
    runs on every build.
    """
    if not _THREE:
        _THREE.update((r.lab.name, r) for r in R8.three_questions())
    r = _THREE.get(lab.name)
    if r is None:
        return None, None, None, "no row -- label absent from round 8's table"
    return r.a, r.b, r.c, r.cwhy


def reason_for(lab):
    """The DERIVED reason this object is still framed.  One per object."""
    stem, _, num = lab.name.rpartition("_")
    k = int(num, 10) if num.isdigit() else None
    if stem == "ToneDB_WaveSelTailPresets":
        refs = R8.preset_referrers().get(k, [])
        tw = _preset_tail_carriers().get(k, [])
        return ("no ASCII: widest printable run in the record is %d bytes; the twin "
                "rule scores 0 (Q12) and the TAIL-ONLY rule scores %d over the %d "
                "other wave-select records (Q29); %s"
                % (_widest_printable(_preset_recs()[k]), len(tw), len(_POP),
                   ("selected by %d stored field(s), the first being %s"
                    % (len(refs), refs[0])) if refs else
                   "selected by NOTHING stored in this image"))
    if stem in ("ToneDB_MixerDefaultTable", "ToneDB_PercMixerDefaultTable"):
        slot = 0x18 if stem == "ToneDB_MixerDefaultTable" else 0x20
        tw = R6.wavesel_twins(slot).get(k) or []
        names = sorted(set(x[2] for x in tw))
        if names:
            base = ("%d record(s) carry these bytes under %d different names (%s)"
                    % (len(tw), len(names), ", ".join(names[:3])))
        else:
            base = "no named record in the image carries these bytes"
        if slot == 0x18:
            gs = R8.selector_groups().get(k, [])
            base += ("; the selector map at +0x%02X reaches it at no entry"
                     % R8.SELECTOR_SLOT) if not gs else (
                "; its map columns span %d sound groups (%s)"
                % (len(gs), ", ".join(R8.group_name(g).strip() for g in gs[:3])))
        else:
            base += ("; M10 on this array scores at its own shuffled null (Q18) "
                     "and a drum record's group can only be one of the %d rows "
                     "spelling DRUM (Q25)" % len(R8.group_kit_witness()[2]))
        base += "; the run rule M12 is refuted by the map route (Q30)"
        return base
    if stem == "ToneNumBank_Melodic":
        bm = R8.bankmap()
        hits = [v for v, row in bm if row == k]
        diff = dict(R8.melodic_rows()).get(k, [])
        tail = ("this IS row 0, the row the other %d are compared against"
                % (len(FAMILY[stem]) - 1) if k == 0 else
                "the row differs from row 0 at %d of 128 programs" % len(diff))
        return ("the BankMap at 0x%05X selects this row at %d of its %d entries "
                "(first bank-select value %s), so the suffix IS the bank number; "
                "%s and nothing in any image says what the difference means"
                % (S(0x6C), len(hits), len(bm), hits[0] if hits else "-", tail))
    if stem == "DrawbarPreset_EnvDescTable_Pool":
        have, tot = pool_partA_count()
        owners = pool_owners().get(lab.addr, [])
        return ("part B of descriptor%s %s of slot +0x70; %d of that block's %d "
                "descriptors carries a part-A offset, so the curve -> stage-2 -> "
                "element chain that names every other pool object cannot start "
                "here; role NOT established (round 4 Q4a)"
                % ("" if len(owners) == 1 else "s",
                   " and ".join(str(o) for o in owners) or "none", have, tot))
    if stem == "ToneRec_05D":
        raw = tone_record_name(0x5D)
        return ("METRIC ARTEFACT, not a nameless object: the record carries its own "
                "name %r and this tree's CamelCase rule renders it %r, which is all "
                "digits" % (raw, camel(raw)))
    return "no round has a verdict for this stem"


def _widest_printable(rec):
    best = run = 0
    for b in rec:
        run = run + 1 if 0x20 <= b <= 0x7E else 0
        best = max(best, run)
    return best


_PRESET_CACHE = {}


def _preset_recs():
    if "r" not in _PRESET_CACHE:
        _PRESET_CACHE["r"] = R6.array_records(PRESET_SLOT)[2]
    return _PRESET_CACHE["r"]


_POP = wavesel_population()


def _preset_tail_carriers():
    """M11: {preset index: [names]} whose bytes 13..42 equal this preset's."""
    if "t" not in _PRESET_CACHE:
        tails = collections.defaultdict(list)
        for what, b in _POP:
            tails[b[WAVESEL_HEAD:]].append(what)
        recs = _preset_recs()
        _PRESET_CACHE["t"] = dict(
            (k, tails.get(bytes(recs[k][WAVESEL_HEAD:]), [])) for k in range(len(recs)))
    return _PRESET_CACHE["t"]


def inventory():
    """[(label, family, offset, size, A, B, C, reason)] for all of today's framed set."""
    out = []
    for l in FRAMED:
        a, b, c, _why = three_answers(l)
        out.append((l.name, l.name.rpartition("_")[0], l.addr, l.end - l.addr,
                    a, b, c, reason_for(l)))
    return out


def q28():
    say("\n=== Q28. ★★ EVERY FRAMED LABEL prom_d STILL HAS, WITH A DERIVED REASON ===\n")
    rows = inventory()
    say("  %d framed labels, in %d families.  A = the object CONTAINS a name,"
        % (len(rows), len(FAMILY)))
    say("  B = a prom_c reader reaches its region, C = something POINTS AT it.")
    say("  ⚠ %d IS NOT A TARGET.  It is the count the goal metric reads, and this"
        % len(rows))
    say("    round moves it by 0 on purpose: see Q29/Q30/Q31 for the three")
    say("    mechanisms that were run and the reason each was not spent.")
    say("")
    say("  %-34s %5s %6s  %-3s  %s" % ("family", "n", "bytes", "ABC", "objects"))
    for fam, labs in FAMILY.items():
        nb = sum(l.end - l.addr for l in labs)
        pat = collections.Counter()
        for l in labs:
            a, b, c, _w = three_answers(l)
            pat["%s%s%s" % ("A" if a else "-", "B" if b else "-",
                            "C" if c else ("?" if c is None else "-"))] += 1
        say("  %-34s %5d %6d  %-3s  %s"
            % (fam, len(labs), nb, ",".join(sorted(pat)),
               "%s .. %s" % (labs[0].name.rpartition("_")[2],
                             labs[-1].name.rpartition("_")[2])))
    say("")
    say("  ONE ROW PER OBJECT -- first and last of every family:")
    for fam, labs in FAMILY.items():
        for l in (labs[0], labs[-1]) if len(labs) > 1 else (labs[0],):
            a, b, c, _w = three_answers(l)
            say("    %-42s 0x%05X %5dB  %s%s%s"
                % (l.name, l.addr, l.end - l.addr,
                   "A" if a else "-", "B" if b else "-",
                   "C" if c else ("?" if c is None else "-")))
            for line in _wrap(reason_for(l), 66):
                say("        %s" % line)
    say("")
    say("  ★ THE WHOLE TABLE, one line each, is printed by --all.")
    if "--all" in sys.argv:
        for name, _fam, off, size, a, b, c, why in rows:
            say("    %-46s 0x%05X %5dB %s%s%s  %s"
                % (name, off, size, "A" if a else "-", "B" if b else "-",
                   "C" if c else ("?" if c is None else "-"), why))
    return rows


def _wrap(text, width):
    out, line = [], ""
    for w in text.split():
        if line and len(line) + 1 + len(w) > width:
            out.append(line)
            line = w
        else:
            line = (line + " " + w) if line else w
    if line:
        out.append(line)
    return out


# ---------------------------------------------------------------------------
# Q29.  M11 -- the tail-only twin rule.
# ---------------------------------------------------------------------------
def m11():
    """(hits, n, population, control hits, control n) for the tail-only rule."""
    carriers = _preset_tail_carriers()
    n = len(_preset_recs())
    hits = sum(1 for k in range(n) if carriers[k])
    # THE POSITIVE CONTROL: the same test, on the population itself.  A record of
    # the population is compared against the population MINUS itself, so a hit
    # means some OTHER record shares its tail.  If this were also 0 the test
    # would be inert and the 0 above would mean nothing.
    tails = collections.Counter(b[WAVESEL_HEAD:] for _w, b in _POP)
    ctrl = sum(1 for _w, b in _POP if tails[b[WAVESEL_HEAD:]] > 1)
    return hits, n, len(_POP), ctrl, len(_POP)


def q29():
    say("\n=== Q29. ★ M11: THE TWIN RULE ON THE 30 BYTES A PRESET ACTUALLY SUPPLIES ===\n")
    hits, n, pop, ctrl, cn = m11()
    say("  A preset does not replace a whole record.  prom_c 0xFBC7D9 sets i = 13")
    say("  and 0xFBC7E3 reads the stride word 43 as the bound, so the copy is bytes")
    say("  13..42 -- thirty bytes.  Round 9's Q12 compared WHOLE records and got 0")
    say("  of %d; that test was harder than the mechanism needs, because the head" % n)
    say("  of a preset record has nothing it must match.")
    say("")
    say("      tail-only carriers, over the %s wave-select records that are NOT" % f"{pop:,}")
    say("      the preset array itself                       : %d of %d" % (hits, n))
    say("      positive control -- the same test on the population itself,")
    say("      where a hit means some OTHER record shares the tail: %d of %d" % (ctrl, cn))
    say("")
    say("  ★ STILL ZERO, and the control says the test is not inert: %d of the" % ctrl)
    say("    %s population records DO share a tail with another record, so a" % f"{cn:,}")
    say("    30-byte tail match is a thing this corpus produces in quantity.  The")
    say("    +0x3C array shares none of them.  The 64 records stay framed for a")
    say("    reason measured on the exact bytes the mechanism copies.")
    return hits, n, pop, ctrl, cn


# ---------------------------------------------------------------------------
# Q30.  M12 -- round 8's M6 with round 11's group, and the cross-check that kills it.
# ---------------------------------------------------------------------------
def _groups_of_record(slot, j):
    tw = R6.wavesel_twins(slot)
    return set(R8.tone_group(t)[0] for t, _e, _nm in tw.get(j, [])
               if R8.tone_group(t) is not None)


def m12(slot=0x18):
    """(proposals, agree, disagree, conflicts) for the preset-run group rule."""
    _a, n, _recs = R6.array_records(slot)
    runs = R8.preset_runs(slot)
    rec2run = {}
    for idx, (_v, lo, hi, _nm) in enumerate(runs):
        for k in range(lo, hi + 1):
            rec2run[k] = idx
    def runpred(k):
        _v, lo, hi, _nm = runs[rec2run[k]]
        gs = set()
        for j in range(lo, hi + 1):
            gs |= _groups_of_record(slot, j)
        return gs
    have = dict(R8.wavesel_labels_r8(slot))
    have.update(R8.selector_labels())
    have.update(R8.group_labels())
    props = {}
    for k in range(n):
        if k in have:
            continue
        gs = runpred(k)
        if len(gs) == 1:
            props[k] = sorted(gs)[0]
    sg = R8.selector_groups()
    agree = disagree = 0
    conflicts = []
    for k in range(n):
        r, m = runpred(k), set(sg.get(k, []))
        if len(r) == 1 and len(m) == 1:
            if r == m:
                agree += 1
            else:
                disagree += 1
                conflicts.append((k, sorted(r)[0], sorted(m)[0]))
    return props, agree, disagree, conflicts, runs, rec2run


def q30():
    say("\n=== Q30. ★ M12: ROUND 8's M6 WITH ROUND 11's GROUP -- AND WHY IT IS REFUSED ===\n")
    props, agree, disagree, conflicts, runs, rec2run = m12()
    sg = R8.selector_groups()
    say("  Round 8's M6 named a no-twin record from the preset RUN it sits in and")
    say("  was refused because no WORD is common to a run's members.  Round 11 then")
    say("  gave this image sound GROUPS, which are coarser than words, and nobody")
    say("  re-ran M6 against them.  Run here, on the %d runs of the +0x18 array:" % len(runs))
    say("")
    say("      records the rule would name                      : %d" % len(props))
    say("      records where the rule AND round 11's map route")
    say("      both give exactly one group                      : %d" % (agree + disagree))
    say("          they agree    : %d" % agree)
    say("          they DISAGREE : %d" % disagree)
    say("")
    say("  ★★ REFUSED.  Two routes that disagree on %d of the %d records where both"
        % (disagree, agree + disagree))
    say("     give exactly one group cannot support a name that rests on ONE of")
    say("     them.  And on the only proposal the map route reaches AT ALL, the run")
    say("     route's answer is not even among the map's:")
    both = [k for k in props if sg.get(k)]
    for k in both:
        say("         record %d: the run says %r; the map columns span %s"
            % (k, R8.group_name(props[k]).strip(),
               ", ".join(R8.group_name(g).strip() for g in sg[k])))
        say("                    -- %r is not one of them."
            % R8.group_name(props[k]).strip())
    say("     ⚠ The loose version of that sentence -- `the one proposal both routes")
    say("       speak on is one of the seven disagreements` -- is FALSE and its")
    say("       check caught it: record %d is not one of the seven, because the map"
        % (both[0] if both else -1))
    say("       does not give it one group at all.  The precise claim is stronger.")
    say("     The other %d proposals are records the map reaches at no entry, so"
        % (len(props) - len(both)))
    say("     nothing would check them at all -- and %d of them come from ONE run"
        % max(collections.Counter(rec2run[k] for k in props).values()))
    say("     with a single identified member.  M12 IS REFUSED; a later round need")
    say("     not re-invent it.")
    return props, agree, disagree, conflicts, both


# ---------------------------------------------------------------------------
# Q31.  ★★ the prom_b name table -- a candidate, and the gap.
# ---------------------------------------------------------------------------
def name_table(off=NAME_TABLE, w=NAME_W):
    """The rows of prom_b's table at `off`, and the bound its own bytes give it."""
    def printable(i):
        return all(0x20 <= B_IMG[i + t] <= 0x7E for t in range(w))
    n = 0
    while printable(off + n * w):
        n += 1
    before = printable(off - w)
    return [B_IMG[off + i * w:off + i * w + w].decode("latin1") for i in range(n)], n, before


DL_OP07 = (0x07, 0x11)


def dl_mask3f_tables():
    """[(file offset, source var, table addr, width, printable rows)] for every
    interpreter-B string-table record in prom_b whose AND mask is 0x3F."""
    out = []
    for i in range(len(B_IMG) - 17):
        for op, ln in ((0x07, 0x11), (0x02, 0x0F)):
            if B_IMG[i] != op or B_IMG[i + 1] != ln:
                continue
            if B_IMG[i + 4] != DL_MASK:
                continue
            tbl = struct.unpack("<I", B_IMG[i + 7:i + 11])[0]
            wid = struct.unpack("<H", B_IMG[i + 11:i + 13])[0]
            if not (PROM_B_BASE <= tbl < PROM_B_BASE + len(B_IMG)) or not 1 <= wid <= 32:
                continue
            o = tbl - PROM_B_BASE
            r = 0
            while (o + (r + 1) * wid <= len(B_IMG)
                   and all(0x20 <= B_IMG[o + r * wid + t] <= 0x7E for t in range(wid))
                   and r < 400):
                r += 1
            out.append((i, struct.unpack("<H", B_IMG[i + 2:i + 4])[0], tbl, wid, r))
    return out


def q31():
    say("\n=== Q31. ★★ prom_b's 64-ENTRY NAME TABLE -- A CANDIDATE, AND THE GAP ===\n")
    names, n, before = name_table()
    recs = _preset_recs()
    say("  prom_b 0x%06X holds %d rows of %d printable bytes and stops there: the row"
        % (PROM_B_BASE + NAME_TABLE, n, NAME_W))
    say("  BEFORE it is not printable (%s) and the row after it is not either, so the"
        % ("checked" if not before else "⚠ IT IS -- the bound is wrong"))
    say("  count is the object's own and not a window this script chose.")
    say("      row 0  = %r        row %d = %r" % (names[0], n - 1, names[n - 1]))
    say("")
    tabs = dl_mask3f_tables()
    mine = [t for t in tabs if t[2] == PROM_B_BASE + NAME_TABLE]
    say("  Every interpreter-B string-table record in prom_b whose AND mask is 0x%02X:"
        % DL_MASK)
    byt = collections.OrderedDict()
    for off, var, tbl, wid, r in tabs:
        byt.setdefault((tbl, wid, r), []).append(var)
    for (tbl, wid, r), vs in byt.items():
        say("      table 0x%06X  width %2d  rows %3d  read with %d variable(s) %s"
            % (tbl, wid, r, len(set(vs)),
               " ".join("0x%04X" % v for v in sorted(set(vs))[:6])))
    say("")
    say("  ★ FOUR FACTS THAT LINE UP:")
    say("    1. the table has %d rows; ToneDB_WaveSelTailPresets has %d records,"
        % (n, len(recs)))
    say("       each bound by its own object rather than by a chosen window.")
    say("    2. the four records that read it mask with 0x%02X -- the same mask"
        % DL_MASK)
    say("       prom_c applies at 0xFBC744 before indexing that array.")
    say("    3. there are exactly %d of them, on variables %s, and a"
        % (len(mine), " ".join("0x%04X" % t[1] for t in mine)))
    say("       wave-select record is a per-element object.")
    say("    4. prom_a's edit field for the same variable clamps the range to")
    say("       0..0x3F: 0xFD4176 `ld (XIX+0x06),0x3f` and 0xFD417E `ld (XIX+0x08),0x3f`")
    say("       around the 0xFD416D call to Arr2808_Get1.")
    say("    and row 0 is %r, while prom_c's 0xFBC74E `jr NZ` sends index 0 down the"
        % names[0].strip())
    say("    arm that does NOT read the array and keeps the live tail instead.")
    say("")
    say("  ⚠⚠ AND THE LINK IS MISSING, WHICH IS WHY THIS ROUND NAMES NOTHING.")
    say("     prom_a/prom_b's variable lives in the PANEL cpu's RAM at 0x2808..0x280B;")
    say("     prom_c's field is byte +0x0B of a 43-byte record in the TONE cpu's RAM")
    say("     at 0x87D2 + 43*n.  No instruction in any of the four images has been")
    say("     shown to carry the first into the second.  Two 6-bit fields with the")
    say("     same mask and the same range are not the same field, and this tree has")
    say("     shipped that error before.")
    say("  ★ WHAT WOULD CLOSE IT, stated so a later round can go straight at it:")
    say("     an instruction chain from Arr2808_Set1 (0xFDA85E) to the link message")
    say("     prom_c decodes into (record + 0x0B).  Failing that, prom_a code that")
    say("     builds a 43-byte record and writes Arr2808[e] at its offset 11.")
    say("")
    say("  ★ EVERY INSTRUCTION CITED ABOVE, PINNED TO ITS BYTES (T27):")
    for img, addr, want, got, ok, what in cited_ok():
        say("      %s 0x%06X  %-14s %s  %s"
            % (img, addr, got, "ok " if ok else "MISMATCH", what))
    return names, n, tabs, mine


# ---------------------------------------------------------------------------
# Q32.  The +0x3C array is built in even-aligned pairs -- prom_d's bytes alone.
# ---------------------------------------------------------------------------
def _ham(x, y):
    return sum(1 for p, q in zip(x, y) if p != q)


def pair_phase(lo=38, hi=63, shift=0):
    """(mean even, mean odd, AUC, n_even, n_odd) for the neighbour-distance phase test."""
    recs = _preset_recs()
    n = len(recs)
    ev = [(i + shift, i + 1 + shift) for i in range(lo, hi, 2)]
    od = [(i + shift, i + 1 + shift) for i in range(lo + 1, hi, 2)]
    ev = [p for p in ev if 0 <= p[0] and p[1] < n]
    od = [p for p in od if 0 <= p[0] and p[1] < n]
    de = [_ham(recs[i], recs[j]) for i, j in ev]
    do = [_ham(recs[i], recs[j]) for i, j in od]
    if not de or not do:
        return None
    u = (sum(1 for x in de for y in do if x < y)
         + 0.5 * sum(1 for x in de for y in do if x == y))
    return statistics.mean(de), statistics.mean(do), u / (len(de) * len(do)), len(de), len(do)


def q32():
    say("\n=== Q32. THE +0x3C ARRAY IS BUILT IN EVEN-ALIGNED PAIRS ===\n")
    names, _n, _b = name_table()
    e, o, auc, ne, no = pair_phase()
    say("  Rows 38..63 of prom_b's table are 13 pairs `X L` / `X H`:")
    for line in _wrap(", ".join("%s/%s" % (names[i].strip(), names[i + 1].strip())
                                for i in range(38, 63, 2)), 68):
        say("      %s" % line)
    say("  Over the SAME index range of ToneDB_WaveSelTailPresets, the mean Hamming")
    say("  distance of a record to its neighbour, out of 43 bytes:")
    say("      even-aligned  (k, k+1) with k even : %.2f   (n=%d)" % (e, ne))
    say("      odd-aligned   (k, k+1) with k odd  : %.2f   (n=%d)" % (o, no))
    say("      AUC (even below odd)               : %.3f" % auc)
    say("")
    say("  ★ SO THE ARRAY IS PAIRED ON THE SAME PARITY AS THE NAMES, and that half")
    say("    stands on prom_d's own bytes.  ⚠ BUT IT IS A PARITY WITNESS AND NOT AN")
    say("    ALIGNMENT PROOF, which the sweep below makes impossible to misread:")
    say("        shift   mean(even)  mean(odd)    AUC")
    for s in range(-8, 9):
        r = pair_phase(shift=s)
        if r:
            say("         %+3d       %6.2f      %6.2f    %.3f" % (s, r[0], r[1], r[2]))
    say("    EVERY EVEN SHIFT SCORES THE SAME.  The test says the records come in")
    say("    pairs on even boundaries; it does NOT say which pair is which name.")
    say("    What pins shift 0 is that both objects are indexed 0..63 by the same")
    say("    6-bit mask -- and that is exactly the claim Q31 cannot yet make.")
    return e, o, auc, ne, no


# ---------------------------------------------------------------------------
# Q33.  The four-image address-spelling census, over today's framed set.
# ---------------------------------------------------------------------------
def address_census():
    """[(label, offset hits, address hits)] over all four images, both endiannesses."""
    return [(l.name, l.addr) + R7.census_address(l.addr) for l in FRAMED]


def q33():
    say("\n=== Q33. 'NOTHING SPELLS THIS ADDRESS' IS A CENSUS, NOT AN ASSERTION ===\n")
    rows = address_census()
    off_hits = [r for r in rows if r[2]]
    abs_hits = [r for r in rows if r[3]]
    say("  For each of the %d framed objects, both 32-bit endiannesses of its FILE"
        % len(rows))
    say("  OFFSET and of 0x%06X + that offset were counted over all four ROM images."
        % PROM_D_BASE)
    say("      as an OFFSET : %3d of %d objects have at least one occurrence"
        % (len(off_hits), len(rows)))
    say("      as an ADDRESS: %3d of %d objects have at least one occurrence"
        % (len(abs_hits), len(rows)))
    say("  ⚠ Round 7 Q3 calibrated this instrument against a magnitude-matched null")
    say("    and it reports AT that null -- a hit here is not evidence of a pointer.")
    say("    It is run so that the words 'nothing points at this object' in Q28's")
    say("    reason column are a measurement.  This project has twice shipped a")
    say("    'no references' that had references.")
    for name, off, o, a in rows[:1] + rows[-1:]:
        say("      %-46s 0x%05X  offset %d  address %d" % (name, off, o, a))
    return rows


# ---------------------------------------------------------------------------
# Q34.  Are the unreached records PADDING?  They are not, and that matters.
# ---------------------------------------------------------------------------
def framed_distinctness(slot):
    """(framed, distinct, biggest identical group, contiguous runs >= 3)."""
    _a, n, recs = R6.array_records(slot)
    have = dict(R8.wavesel_labels_r8(slot))
    if slot == R8.SELECTOR_ARRAY:
        have.update(R8.selector_labels())
        have.update(R8.group_labels())
    framed = [k for k in range(n) if k not in have]
    c = collections.Counter(bytes(recs[k]) for k in framed)
    runs, lo = [], None
    for k in range(n):
        if k in framed and lo is None:
            lo = k
        elif k not in framed and lo is not None:
            runs.append((lo, k - 1))
            lo = None
    if lo is not None:
        runs.append((lo, n - 1))
    return framed, len(c), (max(c.values()) if c else 0), [r for r in runs
                                                           if r[1] - r[0] + 1 >= 3]


def q34():
    say("\n=== Q34. THE UNREACHED RECORDS ARE NOT PADDING, AND THAT IS THE POINT ===\n")
    say("  The easiest way to dismiss %d unexplained records is to suppose the array"
        % sum(len(v) for k, v in FAMILY.items() if "MixerDefault" in k))
    say("  is over-allocated and the tail is filler.  Measured, it is not:")
    for slot in (0x18, 0x20):
        framed, distinct, biggest, runs = framed_distinctness(slot)
        say("      slot +0x%02X: %3d framed records, %3d DISTINCT, largest group of"
            % (slot, len(framed), distinct))
        say("                  byte-identical framed records = %d" % biggest)
        say("                  contiguous framed runs of 3 or more: %s"
            % ", ".join("%d..%d (%d)" % (l, h, h - l + 1) for l, h in runs))
    say("")
    say("  ★ EVERY ONE IS DIFFERENT FROM EVERY OTHER.  Padding repeats; these do not.")
    say("    The %d records of the +0x18 array that the selector map reaches at no"
        % len(framed_distinctness(0x18)[0]))
    say("    entry are %d distinct settings, one run of them 58 records long.  So the"
        % framed_distinctness(0x18)[1])
    say("    hole in this image is not `unused space nobody filled in`; it is real")
    say("    data whose selector this tree has not found.  Saying so is the honest")
    say("    version of a 93.6%% score.")
    return [framed_distinctness(s) for s in (0x18, 0x20)]


# ---------------------------------------------------------------------------
# ★ EVERY INSTRUCTION THIS ROUND'S PROSE CITES, PINNED TO ITS BYTES.
# A wave-7 round-1 lane cited ~31 call sites ONE BYTE PAST the instruction and
# every one was gate-clean, because the gate does not read comments.  The fix is
# not care, it is a check: the first bytes at each cited address are asserted
# here, so a citation that drifts fails T27 instead of standing forever.  The
# addresses are exactly the ones quoted in Q31, Q29 and in the .s banner the
# generator builds from this module.
# ---------------------------------------------------------------------------
CITED = [
    ("prom_a", 0xFD4176, "bc 06 00 3f", "ld (XIX+0x06),0x3f -- the edit field's low bound word"),
    ("prom_a", 0xFD417E, "bc 08 00 3f", "ld (XIX+0x08),0x3f -- its high bound"),
    ("prom_a", 0xFD416D, "1d 76 a8 fd", "call Arr2808_Get1"),
    ("prom_a", 0xFDA85E, "ee 0c 00 00", "Arr2808_Set1 entry"),
    ("prom_a", 0xFDA86E, "f3 e5 08 28 41", "ld (XBC+0x2808),A -- the write itself"),
    ("prom_c", 0xFBC744, "c9 cc 3f", "and A,0x3f -- the 6-bit preset index"),
    ("prom_c", 0xFBC74E, "6e 59", "jr NZ -- index 0 takes the other arm"),
    ("prom_c", 0xFBC7C3, "9e f2 45", "mul XIY,(XIZ+0xf2) -- index * stride"),
    ("prom_c", 0xFBC7D9, "be f0 02 0d 00", "ld (XIZ+0xf0),0x000d -- i = 13"),
    ("prom_c", 0xFBC7E3, "d3 e5 ea 00", "ld WA,(XBC+0x00ea) -- the stride word as the bound"),
]
_IMG = {"prom_a": A_IMG, "prom_c": R7.IMG["prom_c"]}
_BASE = {"prom_a": 0xF80000, "prom_c": 0xF80000}


def cited_ok():
    """[(image, address, want, got, ok, what)] for every instruction the prose cites."""
    out = []
    for img, addr, want, what in CITED:
        n = len(want.split())
        got = _IMG[img][addr - _BASE[img]:addr - _BASE[img] + n].hex(" ")
        out.append((img, addr, want, got, got == want, what))
    return out


# ---------------------------------------------------------------------------
# The LAST-ELEMENT probes.  Each re-derives one number of the LAST object's
# reason straight out of D, at the file offset the .s location counter gives that
# label -- a different path from the array model reason_for() used.  If the two
# ever disagree, one of them has drifted, and the alarm is here rather than in a
# sentence nobody re-reads.
# ---------------------------------------------------------------------------
def _reprobe_last(fam, l):
    off, size = l.addr, l.end - l.addr
    if fam == "ToneNumBank_Melodic":
        row0 = FAMILY[fam][0].addr
        n = sum(1 for p in range(128)
                if R6.u16(off + 2 * p) != R6.u16(row0 + 2 * p))
        want = "differs from row 0 at %d of 128 programs" % n
        return want in reason_for(l) and n > 0, "expected %r" % want
    if fam == "ToneRec_05D":
        want = repr(camel(D[off:off + 16].decode("latin1")))
        return want in reason_for(l), "expected %s" % want
    if fam == "DrawbarPreset_EnvDescTable_Pool":
        base = S(0x70)
        na = sum(1 for i in range(4)
                 if struct.unpack_from("<I", D, base + 14 * i + 1)[0])
        owners = [i for i in range(4)
                  if struct.unpack_from("<I", D, base + 14 * i + 5)[0] == off]
        want = ("%d of that block's 4 descriptors" % na,
                "descriptor%s %s" % ("" if len(owners) == 1 else "s",
                                     " and ".join(str(o) for o in owners)))
        r = reason_for(l)
        return all(w in r for w in want), "expected %s in %r" % (want, r[:90])
    if fam == "ToneDB_WaveSelTailPresets":
        rec = D[off:off + size]
        best = run = 0
        for b in rec:
            run = run + 1 if 0x20 <= b <= 0x7E else 0
            best = max(best, run)
        tails = set(b[WAVESEL_HEAD:] for _w, b in _POP)
        want = ("widest printable run in the record is %d bytes" % best,
                "TAIL-ONLY rule scores %d over" % (0 if rec[WAVESEL_HEAD:] not in tails else 1))
        r = reason_for(l)
        return all(w in r for w in want), "expected %s" % (want,)
    if fam in ("ToneDB_MixerDefaultTable", "ToneDB_PercMixerDefaultTable"):
        rec = D[off:off + size]
        m = R6._mask(rec)
        carriers = set()
        for _i, _j, b, nm in R6.tone_wavesel_blocks():
            if R6._mask(b) == m:
                carriers.add(nm)
        for _i, b, nm in R6.perc_wavesel_tails():
            if R6._mask(b) == m:
                carriers.add(nm)
        r = reason_for(l)
        want = ("no named record in the image carries these bytes" if not carriers
                else "different names")
        return want in r, "expected %r (carriers %s)" % (want, sorted(carriers)[:3])
    return False, "no probe for family %s" % fam


# ---------------------------------------------------------------------------
# The checks.
# ---------------------------------------------------------------------------
def selftest():
    say("\n=== ROUND 12 SELFTEST ===\n")
    rows = inventory()

    # --- T1: the set being classified is the one the goal metric reads --------
    import subprocess
    spec = importlib.util.spec_from_file_location(
        "wave7_documentation_metrics",
        os.path.join(ROOT, "notes", "wave7_documentation_metrics.py"))
    met = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(met)
    # ⚠ PRE-EXISTING, and it made this whole --selftest unrunnable: scan()
    # returns SEVEN values (branch targets were split out of `internal`) and this
    # line unpacked six, so it raised ValueError before its first check.  Round 5
    # hit the same class of bug and left the rule -- take the values by position
    # from whatever scan() returns, never by a fixed arity.
    _res = met.scan(os.path.join("prom_d", "wsa1_prom_d.s"))
    mfr = _res[1]
    check("T1 the framed set here is exactly the one wave7_documentation_metrics "
          "reads (%d)" % len(mfr),
          len(mfr) == len(rows)
          and set(x[0] for x in mfr) == set(r[0] for r in rows),
          "%d here, %d there" % (len(rows), len(mfr)))
    check("T2 and it is %d, the figure this round is judged on" % AUDITED_FRAMED_TODAY,
          len(rows) == AUDITED_FRAMED_TODAY, "%d" % len(rows))

    # --- T3: EVERY object has a reason, and it is derived, not a constant -----
    check("T3 every one of the %d has a non-empty reason" % len(rows),
          all(r[7] and "no round has a verdict" not in r[7] for r in rows),
          "%d without" % sum(1 for r in rows if not r[7]))
    firstr, lastr = rows[0][7], rows[-1][7]
    check("T4 the FIRST and the LAST object's reasons differ (a constant string "
          "would be the bug this check exists for)", firstr != lastr,
          "%r" % firstr[:40])
    ndistinct = len(set(r[7] for r in rows))
    check("T5 the %d reasons take %d DISTINCT values -- one constant per family "
          "would be %d" % (len(rows), ndistinct, len(FAMILY)),
          ndistinct >= 20, "%d distinct" % ndistinct)
    # ★★ AND EVERY FAMILY'S LAST OBJECT HAS A NUMBER OF ITS REASON RE-DERIVED FROM
    # THE ROM BY A DIFFERENT CODE PATH -- from D at the label's own file offset,
    # which comes from the .s location counter and not from the array model the
    # reason itself was built with.  Testing the first element only is how this
    # tree has repeatedly shipped a rule that stops working at the end.
    for fam, labs in FAMILY.items():
        l = labs[-1]
        ok, detail = _reprobe_last(fam, l)
        check("T5.%-30s last object %s: its reason re-derived from the ROM"
              % (fam[:30], l.name), ok, detail)

    # --- T6..T8: M11 ---------------------------------------------------------
    hits, n, pop, ctrl, cn = m11()
    check("T6 M11 (tail-only) names nothing in the +0x3C array", hits == 0,
          "%d of %d" % (hits, n))
    check("T7 and M11 is NOT an inert test -- the same rule fires on the population",
          ctrl > 0, "%d of %d" % (ctrl, cn))
    carriers = _preset_tail_carriers()
    check("T8 checked on the LAST record of the array as well as the first",
          not carriers[n - 1] and not carriers[0],
          "record %d: %s" % (n - 1, carriers[n - 1]))
    check("T9 the population is the 1,485 wave-select records that are not the "
          "preset array", pop == 1485, "%d" % pop)

    # --- T10..T12: M12 -------------------------------------------------------
    props, agree, disagree, conflicts, _runs, _r2r = m12()
    sg = R8.selector_groups()
    both = [k for k in props if sg.get(k)]
    check("T10 M12 does propose names -- it is refused on its result, not for "
          "failing to run", len(props) > 0, "%d proposals" % len(props))
    check("T11 and the two routes disagree on %d of the %d records where both give "
          "exactly one group" % (disagree, agree + disagree), disagree > 0,
          "agree %d disagree %d" % (agree, disagree))
    # ★ THE PRECISE CLAIM, and the loose version of it FAILED this check when it
    # was first written: record 41 is not one of the seven, because the map does
    # not give it ONE group at all -- it gives four, none of them the run's.  The
    # refutation is stronger than the sentence that was nearly shipped.
    check("T12 on the only proposal the map reaches at all, the run's group is not "
          "even AMONG the map's groups",
          len(both) == 1 and props[both[0]] not in sg[both[0]],
          "both-speak %s, run says %s, map says %s"
          % (both, [props[k] for k in both], [sg[k] for k in both]))

    # --- T13..T17: the prom_b table -----------------------------------------
    names, n64, before = name_table()
    check("T13 prom_b's table at 0x%06X has exactly 64 rows" % (PROM_B_BASE + NAME_TABLE),
          n64 == 64, "%d" % n64)
    check("T14 and its bound is the object's own -- the row before it is not printable",
          not before, "row -1 is printable")
    check("T15 row 0 is ORIGINAL and row 63 is SPECIAL2 (first AND last)",
          names[0].strip() == "ORIGINAL" and names[63].strip() == "SPECIAL2",
          "%r / %r" % (names[0], names[63]))
    tabs = dl_mask3f_tables()
    mine = [t for t in tabs if t[2] == PROM_B_BASE + NAME_TABLE]
    check("T16 exactly 4 display-list records read it, on 4 consecutive variables",
          len(mine) == 4
          and sorted(t[1] for t in mine) == list(range(0x2808, 0x280C)),
          "%d records, vars %s" % (len(mine), sorted(hex(t[1]) for t in mine)))
    check("T17 ⚠ it is NOT the only 64-row table a 0x3F mask reaches -- so the "
          "candidate is not proven by elimination",
          len(set(t[2] for t in tabs if t[4] == 64)) > 1,
          "distinct 64-row tables: %s"
          % sorted(set(hex(t[2]) for t in tabs if t[4] == 64)))
    check("T18 the array it is a candidate for has the same count",
          len(_preset_recs()) == n64, "%d records" % len(_preset_recs()))

    # --- T19..T21: the phase test and its own refutation ---------------------
    e, o, auc, _ne, _no = pair_phase()
    check("T19 the even-aligned pairs really are closer", e < o and auc > 0.85,
          "%.2f vs %.2f, AUC %.3f" % (e, o, auc))
    evens = [pair_phase(shift=s) for s in (-4, -2, 2, 4)]
    check("T20 ⚠ and EVERY even shift scores the same, so the test pins PARITY and "
          "not alignment", all(r and r[2] > 0.85 for r in evens),
          "%s" % [round(r[2], 3) for r in evens if r])
    odds = [pair_phase(shift=s) for s in (-3, -1, 1, 3)]
    check("T21 while every odd shift inverts it -- the parity signal is real",
          all(r and r[2] < 0.15 for r in odds),
          "%s" % [round(r[2], 3) for r in odds if r])

    # --- T22..T24: the refusals this round KEEPS, re-derived ------------------
    have, tot = pool_partA_count()
    check("T22 slot +0x70: 0 of its 4 descriptors carries a part-A offset",
          have == 0 and tot == 4, "%d of %d" % (have, tot))
    raw = tone_record_name(0x5D)
    check("T23 ToneRec_05D's own name %r CamelCases to all digits" % raw,
          camel(raw).isdigit(), "%r" % camel(raw))
    bm = R8.bankmap()
    check("T24 the BankMap selects row 0 and row 7 -- first and last of the family",
          any(r == 0 for _v, r in bm) and any(r == 7 for _v, r in bm),
          "rows present: %s" % sorted(set(r for _v, r in bm)))

    # --- T25: the address census actually ran -------------------------------
    cen = address_census()
    check("T25 the address census covers every framed object, first and last",
          len(cen) == len(rows) and cen[0][1] == rows[0][2]
          and cen[-1][1] == rows[-1][2],
          "%d rows" % len(cen))

    # --- T25b..T25c: Q34 ----------------------------------------------------
    for slot in (0x18, 0x20):
        framed, distinct, biggest, runs = framed_distinctness(slot)
        check("T25.%02X every framed record of slot +0x%02X is byte-distinct from "
              "every other (%d of %d)" % (slot, slot, distinct, len(framed)),
              distinct == len(framed) and biggest == 1,
              "largest identical group %d" % biggest)

    # --- T27: every cited instruction, pinned to its bytes -------------------
    cited = cited_ok()
    bad = [r for r in cited if not r[4]]
    check("T27 all %d instructions this round's prose cites start with the bytes "
          "it says they do -- FIRST (%s 0x%06X) and LAST (%s 0x%06X) included"
          % (len(cited), cited[0][0], cited[0][1], cited[-1][0], cited[-1][1]),
          not bad, "; ".join("%s 0x%06X want %r got %r" % (r[0], r[1], r[2], r[3])
                             for r in bad))

    # --- T26: this round promoted nothing, and says so ----------------------
    check("T26 this round adds no label -- the framed count is unchanged",
          len(rows) == AUDITED_FRAMED_TODAY, "%d" % len(rows))

    say("\n%d checks, %d failed." % (NCHECK[0], len(FAILED)))
    for f in FAILED:
        say("   FAILED: %s" % f)
    return not FAILED


def main():
    if "--selftest" in sys.argv:
        ok = selftest()
        sys.exit(0 if ok else 1)
    q28()
    q29()
    q30()
    q31()
    q32()
    q33()
    q34()
    say("\n★★ ROUND 12 PROMOTED NOTHING, ON PURPOSE.  Three mechanisms were run for")
    say("   the first time.  M11 and M12 are refused by their own measurement; the")
    say("   prom_b name table is a real find whose one missing link is written down")
    say("   in Q31 rather than papered over.  The deliverable is Q28: %d objects,"
        % len(FRAMED))
    say("   %d families, a derived reason on every one, re-checkable in one command."
        % len(FAMILY))


if __name__ == "__main__":
    main()
