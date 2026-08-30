#!/usr/bin/env python3
"""prom_c ROUND 6 -- the THREE ENVELOPE BLOCKS, the staging-word producers, and an
   honest account of what prom_c's 489 "framed" labels actually are.

QUESTION IT ANSWERS
  prom_c is territorially complete and, once the metric stopped counting
  `<parent>__<addr>` branch targets as debt, it reads 43.6% understood -- the
  SMALLEST remaining debt of any image in this tree: 492 `sub_XXXXXX` and 489
  `framed`.  Two questions follow, and this script answers both mechanically.

  1. ★ CAN THE 489 FRAMED LABELS BE PROMOTED?  Section 1 measures it instead of
     assuming.  The answer is MOSTLY NO, and for three separate reasons that have
     to be told apart, because only one of them is debt a naming round can retire:

        374  P7 byte-code objects (`P7Stream_*`, `PoolDir_FieldRec_*`) whose
             CONTENT is an undecoded byte-code for a device on port P7.  Naming
             one would be naming a blob.  FINDINGS-prom_c-p7-byte-stream-pool.md
             §0 already says the payload convention of 130 of the 297 streams is
             not the one the located interpreter runs.
         70  tail-zone data objects (`Table_FEXXXX`, `Curve_FEXXXX`, `LinCoef_*`)
             that are framed ON PURPOSE: FINDINGS-prom_c-tail-data-zone.md §7 --
             "Where only the shape and the reader are known, the name says so ...
             never a role."  Renaming those to move a metric would delete a
             deliberate statement of ignorance.
         43  labels the metric MIS-GRADES, because their trailing number IS the
             meaning: `MidiCtrl_CC07` (MIDI controller 7), `Dev10C_SetChanReg_0840`
             (device register 0x0840 + chan), `MathTable_Sin_S16_256` (256 entries),
             `Clamp_0_to_00FF` (the bound).  These are already content; the strict
             rule in notes/wave7_documentation_metrics.py cannot see it.
          2  promoted by this round, by the round-4/5 mechanism (a reader names
             the object): `unexplained_FE1315` and `Dev10C_SetChanReg_0400`.

     So prom_c's framed count is NOT a naming backlog, and a round that reported a
     large framed->content number here would have had to do damage to get it.
     ⚠ THIS IS A CORRECTION TO THIS ROUND'S OWN BRIEF, which ranked "the 489
     framed" as half the remaining work.  Measured, not argued: `--framed`.

  ★ AND ONE HEADER GAP THAT IS REAL (section 8).  prom_c's `headers` column reads
     1,088 against 6,421 labels, which the brief read as a deficit.  It is not: EVERY
     `sub_XXXXXX` in prom_c already carries a header AND an Evidence: line (492 of them at
     the round's start, 457 after it), 4,683 of the labels are branch targets, and 293 of
     the 308 header-less content labels are themselves branch targets (`RESET__clear_dram`,
     `MAIN__midi_drain`) or PresetBank rows.  The real deficit was FIFTEEN labels, and
     seven of them -- the micro-DMA accessors -- get a header here, taking the metric's
     prom_c `headers` column from 1,088 to 1,095.  The other eight are interrupt
     trampolines of one instruction each, already carrying a one-line Evidence: comment
     under a block banner that documents the whole group, and padding those to three lines
     is deliberately NOT done.  --gaps re-derives all of it.

  2. ★ WHAT CAN BE NAMED IS THE `sub_XXXXXX`, and this round names 35 of them from
     ONE subsystem (plus the two framed promotions above -- 37 renames in all), by three mechanisms that are all instruction operands:

     (a) THE STAGING-WORD MECHANISM (section 3).  `Dev10C_WriteAllChanRegs` copies
         22 words from RAM 0x00D75E into 22 registers of one channel of the device
         at 0x0010C000.  A routine that writes ONLY struct word N is therefore the
         producer of register (block(N) + chan), and can be named for it -- which is
         exactly how the already-named `Voice_StageRegs_0500_08C0_AB` and
         `Voice_StagePair_Reg0100_0140_AB` got their names.  Twelve routines, and one of
         them -- register 0x00C0 + chan -- decodes all the way to a formula (section 3b).

     (b) ★★ THE THREE ENVELOPE BLOCKS (section 2), which is this round's find.
         Six unnamed routines read the SAME 27-byte record array at RAM 0x4CCF and
         differ in exactly one operand: which of four parallel 128-entry u16 curve
         tables at 0xFDE02B / 0xFDE12B / 0xFDE22B / 0xFDE32B they index.  They pair
         up 3 x 2 -- three BASE-curve evaluators (13-bit clamp, OR'd with a 2-bit
         mode word from EGEnv_ModeBits_Table) against three VALUE-curve evaluators
         (14-bit clamp, no mode bits) -- and THE PAIRING IS PROVED BY CO-OCCURRENCE:
         every routine in the image that calls one member of a pair calls the other
         member of THAT pair and never a member of another pair (8 callers, zero
         mixed).  Each pair has its own staging routine, its own restage-for-part
         arm pair, and its own device-write routine, and the three groups stage
         three DIFFERENT registers: 0x0440/0x0480, 0x0180 and 0x04C0.
         ⚠ AND A RENAME THIS ROUND MEASURED AND THEN REJECTED.  The third base
         curve is called `Voice_FreqWrite_BaseCurve` while the first two are
         `EGEnv_BaseCurve_A` and `_B` -- three 256-byte tables 0x100 apart, read by
         three routines that differ in nothing else, and one routine (sub_FBDA2C)
         reads all three.  That looks exactly like an inconsistent name, and the
         first draft of this round renamed it `EGEnv_BaseCurve_C`.  It is WRONG to:
         all three names are KN5000 sub-CPU transplants onto BYTE-IDENTICAL tables
         (notes/FINDINGS-kn5000-transplant-offset.md, prom_c 0xFDE12B/0xFDE22B/
         0xFDE32B <- kn5000 0x10A64/0x10B64/0x10C64), so the asymmetry is the
         SIBLING'S, not this tree's, and erasing it would destroy the one thing
         that makes the transplant checkable.  The rename is not made; the three
         evaluators are named after the table each actually indexes instead.

     (c) THE 0x00104000 PACKER CHAIN (section 5), where a routine's name comes from
         the struct it fills and the globals it sets.

  3. ★ AND ONE THING THE EMULATOR CAN USE (section 4).  `sub_FAF031` is the
     parameter-change dispatcher: 68 call sites, seven of them inside named
     `MidiCtrl_CC*` handlers (1, 2, 4, 16, 17, 18, 19), a 49-entry jump table at 0xFAF08F selected by a 6-bit
     code, and its arms are the routines that push a changed parameter back out to
     every sounding voice of a part.  It is named here.
     And `VoiceRegs_Stage_B` DOES NOT RUN THE 0x00104000 PACKER AT ALL: it calls
     sub_FC571A, which block-copies a fixed 19-word image from 0xFE1315 into the
     staging struct and then patches five fields (section 5c).  Stage_A and Stage_C
     and Stage_D call the packer; Stage_B does not.

WHAT THIS ROUND DOES **NOT** ESTABLISH
  * What any of the three envelope blocks IS.  "Envelope" is the tree's existing
    word for the curve tables (EGEnv_BaseCurve_A/_B and EGEnv_ValueCurve_Simple
    were named in an earlier round from the sibling KN5000 sub-CPU, where they are
    byte-identical).  This round establishes the THREE-FOLD STRUCTURE and the
    pairing; it does not say what a block modulates.
  * What the 27-byte record at RAM 0x4CCF + 27*n is, or what n indexes.
  * What registers 0x00C0, 0x0180, 0x0440, 0x0480, 0x04C0, 0x0800-0x0A40 carry.
    The names given here say WHICH REGISTER a routine stages, never what the
    register means.  Where the tree has established a meaning elsewhere the header
    cites it and says who established it.
  * The letters A/B/C for the three blocks are THIS TREE'S labels, extending the
    existing EGEnv_BaseCurve_A/_B; block A is the one whose base curve is
    EGEnv_BaseCurve_A and whose stager writes registers 0x0440/0x0480.  No ROM byte
    spells "A".
  * `_AB` and `_CD` mean "the variant VoiceRegs_Stage_A/B (resp. C/D) calls", which
    is what the tree's existing `Voice_StageRegs_0500_08C0_AB` already means.  Four
    of the ten also have callers in the controller-update module; every such caller
    is listed in the routine's own header rather than hidden by the suffix.

RUN
    python3 notes/prom_c_understanding_round6.py             # every section
    python3 notes/prom_c_understanding_round6.py --framed    # 1: what "framed" is here
    python3 notes/prom_c_understanding_round6.py --blocks    # 2: the three envelope blocks
    python3 notes/prom_c_understanding_round6.py --staging   # 3: staging-word producers
    python3 notes/prom_c_understanding_round6.py --reg00c0  # 3b: register 0x00C0's formula
    python3 notes/prom_c_understanding_round6.py --dispatch  # 4: the param-change dispatcher
    python3 notes/prom_c_understanding_round6.py --packer    # 5: the 0x00104000 chain
    python3 notes/prom_c_understanding_round6.py --names     # 6: the rename table, asserted
    python3 notes/prom_c_understanding_round6.py --gaps      # 7: what could NOT be named
    python3 notes/prom_c_understanding_round6.py --udma      # 8: the 7 real header gaps
    python3 notes/prom_c_understanding_round6.py --cites     # 9: every cited address, checked
    python3 notes/prom_c_understanding_round6.py --apply     # perform the renames
    python3 notes/prom_c_understanding_round6.py --check-applied
    python3 notes/prom_c_understanding_round6.py --headers   # write the routine headers
    python3 notes/prom_c_understanding_round6.py --selftest  # all of it: 114 checks, exit 1 on failure

⚠ THE BYTE GATE IS BLIND TO EVERY LINE THIS SCRIPT WRITES.  After --apply or
  --headers, run `python3 scripts/analysis/assert_byte_identical.py`; a rename or a
  comment cannot change a byte, and that is exactly why nothing but a check like the
  ones below can catch a wrong one.
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000

_rom = open(ROM, "rb").read()

OK = [0]
FAIL = [0]


def check(desc, cond):
    print(("  ok    " if cond else "  FAIL  ") + desc)
    if cond:
        OK[0] += 1
    else:
        FAIL[0] += 1
    return cond


def rd(a, n):
    return _rom[a - BASE:a - BASE + n]


def u16le(a):
    return struct.unpack("<H", rd(a, 2))[0]


def u32le(a):
    return struct.unpack("<I", rd(a, 4))[0]


# ---------------------------------------------------------------------------
# The source, read once, with every line attributed to the ROUTINE it is in.
#
# prom_c spells a branch target inside a routine `<Parent>__<something>`, so the
# enclosing ROUTINE is the last column-0 label whose name contains no `__`.  That
# rule is asserted in section 0 against the label census, not assumed.
# ---------------------------------------------------------------------------
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
# The emitter writes an instruction's address as `; FA796D` and a data line's as
# `; 0xFE133B`; both spellings must be read or every DATA label loses its address.
ADDRC = re.compile(r';\s*(?:0x)?([0-9A-Fa-f]{6})\b')
_lines = open(SRC, encoding="utf-8").read().split("\n")


def walk():
    """yield (line_index, line, routine_label, address_or_None)"""
    routine = None
    for i, ln in enumerate(_lines):
        m = LABEL.match(ln)
        if m:
            if "__" not in m.group(1):
                routine = m.group(1)
            yield i, ln, routine, None
            continue
        a = ADDRC.search(ln)
        yield i, ln, routine, (int(a.group(1), 16) if a else None)


ROUTINE_OF = {}
LINE_OF_LABEL = {}
for _i, _ln, _r, _a in walk():
    m = LABEL.match(_ln)
    if m:
        LINE_OF_LABEL[m.group(1)] = _i
    ROUTINE_OF[_i] = _r


def call_sites(target_addr):
    """Every call/calr/jp/jrl/jr in the SOURCE naming this address, as
    (site_address, enclosing routine).  Both spellings the emitter uses:
    `call 0xNNNNNN` and `calr (0xNNNNNN - 0xMMMMMM)`."""
    pat = re.compile(r'\b(?:call|calr|jp|jrl|jr)\s+\(?0x%06X\b' % target_addr, re.I)
    out = []
    for i, ln, routine, a in walk():
        code = ln.split(";")[0]
        if pat.search(code):
            out.append((a, routine))
    return out


def body_lines(label):
    """The lines of one routine, from its label to the next column-0 routine label."""
    start = LINE_OF_LABEL[label]
    out = []
    for i in range(start + 1, len(_lines)):
        m = LABEL.match(_lines[i])
        if m and "__" not in m.group(1):
            break
        out.append(_lines[i])
    return out


def callees(label):
    """Every call/calr target address named inside one routine's body."""
    pat = re.compile(r'\b(?:call|calr)\s+\(?0x([0-9A-Fa-f]{6})\b')
    return [int(m.group(1), 16) for ln in body_lines(label)
            for m in [pat.search(ln.split(";")[0])] if m]


def reads_literal(label, addr):
    """True if the routine's body names this 24-bit literal in an address operand."""
    pat = re.compile(r'0x%06X\b' % addr, re.I)
    return any(pat.search(ln.split(";")[0]) for ln in body_lines(label))


# ---------------------------------------------------------------------------
# THE THREE ENVELOPE BLOCKS -- the constants, all of them instruction operands.
# ---------------------------------------------------------------------------
EGREC_BASE = 0x4CCF        # RAM, the 27-byte record array every evaluator indexes
EGREC_STRIDE = 27          # `ld C,0x1b` in all six evaluators
MODEBITS = 0xFDEBEC        # EGEnv_ModeBits_Table, 4 x u16, OR'd in by the base evaluators
VALUECURVE = 0xFDE02B      # EGEnv_ValueCurve_Simple  -- shared by all three value evaluators
BASECURVE = {"A": 0xFDE12B, "B": 0xFDE22B, "C": 0xFDE32B}
# ⚠ the tree's label for each, and C's is NOT `EGEnv_BaseCurve_C`: see the rejected
# rename in this file's docstring.  Printing the real label keeps the check honest.
BASECURVE_LABEL = {"A": "EGEnv_BaseCurve_A", "B": "EGEnv_BaseCurve_B",
                   "C": "Voice_FreqWrite_BaseCurve"}

# block -> (base-curve evaluator, value-curve evaluator, stager, base restage arm,
#           value restage arm, device-write routine, staging struct word)
BLOCKS = {
    "A": dict(base=0xFA796D, value=0xFA79F4,
              stager="Voice_StageChanSel_Reg0440_Reg0480",
              restage_base=0xFAE34A, restage_value=0xFAE484,
              writer=0xFB89F8, words=(8, 9)),
    "B": dict(base=0xFA7A4B, value=0xFA7AD6,
              stager="sub_FA9C60",
              restage_base=0xFAE5C7, restage_value=0xFAE703,
              writer=0xFB8AF6, words=(6,)),
    "C": dict(base=0xFA7B31, value=0xFA7C3A,
              stager="Voice_StageChanSel_Reg04C0",
              restage_base=0xFAE848, restage_value=0xFAE986,
              writer=0xFB8BF6, words=(10,)),
}

# The 0x0010C000 staging struct.  Word -> register block comes from
# notes/prom_c_dev10c_field_sources.py, which derives it from
# notes/prom_c_tg_chanmap.py's reading of Dev10C_WriteAllChanRegs; section 3
# ASSERTS this copy against that module rather than trusting either alone.
DEV10C_STRUCT = 0x00D75E
DEV10C_NWORD = 22
WORD2BLOCK = {2: 2}
for _w0, _w1, _b0 in [(1, 1, 1), (3, 6, 3), (7, 11, 16), (12, 21, 32)]:
    for _w in range(_w0, _w1 + 1):
        WORD2BLOCK[_w] = _b0 + (_w - _w0)


def struct_writes():
    """Every absolute write into the 22-word 0x0010C000 staging struct, as
    {routine: {word: [site addresses]}}.  Re-derived here from the source text, in
    the emitter's `st*_da (0xNNNN), <val>` spelling."""
    pat = re.compile(r'^\s*st[a-z0-9]*_da\s+\(0x([0-9A-Fa-f]{4})\)')
    out = {}
    for i, ln, routine, a in walk():
        m = pat.match(ln.split(";")[0])
        if not m:
            continue
        off = int(m.group(1), 16) - DEV10C_STRUCT
        if 0 <= off < 2 * DEV10C_NWORD and off % 2 == 0:
            out.setdefault(routine, {}).setdefault(off // 2, []).append(a)
    return out


# ---------------------------------------------------------------------------
# 1 -- WHAT prom_c's 489 "framed" LABELS ACTUALLY ARE
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.join(ROOT, "notes"))
import wave7_documentation_metrics as METRIC          # noqa: E402


def framed_labels():
    """prom_c's framed labels, exactly as notes/wave7_documentation_metrics.py grades
    them, each with the address of the last instruction comment above it."""
    named, framed, unnamed, internal, _h, _e = METRIC.scan("prom_c/wsa1_prom_c.s")
    return framed, named, unnamed, internal


# The four buckets.  Each rule is stated so it can be disagreed with; the script
# asserts they PARTITION the set, so a label cannot be double-counted or dropped.
def classify_framed(name):
    if name.startswith(("P7Stream", "PoolDir_FieldRec")):
        return "P7 byte-code pool (content undecoded)"
    if re.match(r'^MidiCtrl_CC\d+$', name):
        return "trailing number IS the meaning"
    if re.match(r'^(Dev10C|Dev104|Pack104)_[A-Za-z0-9_]*_[0-9A-F]{4}$', name):
        return "trailing number IS the meaning"
    if re.match(r'^(MathTable|Curve|Const|BitMasks|Voice_KeyBend_Curve|'
                r'Voice_Search_Order_List|VoiceParam_DispatchOn_17)_[A-Za-z0-9_]*_?\d+$', name):
        return "trailing number IS the meaning"
    if re.match(r'^(Clamp|Sat16)_', name):
        return "trailing number IS the meaning"
    if re.match(r'^(PartSlot_SetRecordPtr|PartRec_TallyScaledField|Flash_WriteRampPattern|'
                r'Clamp_ToRange_LowByte|Words|DupTail|BitMask_Table|Table|LinCoef|'
                r'fp_constant_pool|unexplained|PresetBank)_', name):
        return "framed on purpose / address-only"
    return "other"


# The rules are ORDERED and the first match wins; `--framed` asserts that every one
# of prom_c's framed labels matches exactly one, so nothing is dropped or counted
# twice.  Each rule says what the trailing number IS, which is the whole point:
# notes/wave7_documentation_metrics.py's strict rule calls a label whose last
# component is a number "framed", and for four of these six buckets that is right.
FRAMED_RULES = [
    ("P7 byte-code pool -- the object's CONTENT is undecoded byte-code",
     r'^(P7Stream|PoolDir_FieldRec)'),
    ("address-suffixed -- the suffix is the object's own ROM/RAM/device address",
     r'_(?:F[89A-F][0-9A-F]{4}|FE[0-9A-F]{4}|DF05|E81000)$'),
    ("the number is a DEVICE REGISTER or MIDI CONTROLLER number",
     r'^(?:MidiCtrl_CC\d+$|Dev10C_|Dev104_|Pack104_)'),
    ("the number is an ENTRY COUNT or a numeric BOUND",
     r'^(?:MathTable_|Curve_(?:Exp2|Log2)|Const_0100_|Clamp_|Sat16_|BitMasks_1shl|'
     r'VoiceParam_DispatchOn_17_|PartRec_TallyScaledField_)'),
    ("the number is an ORDINAL INDEX inside a named set",
     r'^(?:Voice_KeyBend_Curve_|Voice_Search_Order_List_)\d+$'),
    ("METRIC FALSE POSITIVE -- the suffix is a WORD of the object's own name",
     r'^PresetBank_'),
]


def classify_framed(name):
    for label, pat in FRAMED_RULES:
        if re.search(pat, name):
            return label
    return "UNCLASSIFIED"


def section_framed():
    print("\n=== 1. prom_c's 489 FRAMED labels, by WHAT the trailing number is ===\n")
    framed, named, unnamed, internal = framed_labels()
    counts = {}
    for n, _a in framed:
        counts.setdefault(classify_framed(n), []).append(n)
    total = 0
    for label, _pat in FRAMED_RULES + [("UNCLASSIFIED", None)]:
        got = counts.get(label, [])
        if not got:
            continue
        total += len(got)
        print("  %4d  %s" % (len(got), label))
        print("        e.g. " + ", ".join(sorted(got)[:4]))
    print()
    check("every framed label matched exactly one rule (none UNCLASSIFIED)",
          not counts.get("UNCLASSIFIED"))
    check("the buckets partition the framed set (%d)" % len(framed), total == len(framed))
    promotable = len(counts.get("the number is an ORDINAL INDEX inside a named set", []))
    print("\n  ★ THE PROMOTABLE POOL IS NOT 489.  %d are byte-code blobs, %d carry their own"
          % (len(counts.get(FRAMED_RULES[0][0], [])), len(counts.get(FRAMED_RULES[1][0], []))))
    print("    address BY DECISION (FINDINGS-prom_c-tail-data-zone.md §7), %d already state a"
          % (len(counts.get(FRAMED_RULES[2][0], [])) + len(counts.get(FRAMED_RULES[3][0], []))))
    print("    register/controller number or a count that IS the meaning, %d are ordinals" % promotable)
    print("    and %d are metric false positives -- `PresetBank_Paris_Caffe` is graded framed"
          % len(counts.get(FRAMED_RULES[5][0], [])))
    print("    because \"Caffe\" parses as hexadecimal.")
    print("\n  So this round promotes TWO framed labels, and says so, rather than renaming a")
    print("  hundred deliberate statements of ignorance into confident-looking guesses.")
    return counts


# ---------------------------------------------------------------------------
# 2 -- THE THREE ENVELOPE BLOCKS
# ---------------------------------------------------------------------------
ADDR_OF_LABEL = {}
LABEL_AT_ADDR = {}
_HDR_ADDR = re.compile(r'^;\s*(?:★\s*)?%s\s+--\s+0x([0-9A-F]{6})')
for _name, _ln in LINE_OF_LABEL.items():
    _a = None
    for _j in range(_ln + 1, min(_ln + 4, len(_lines))):
        _m = ADDRC.search(_lines[_j])
        if _m:
            _a = int(_m.group(1), 16)
            break
    if _a is None:
        # ⚠ NOT every data line carries an address comment -- the bulk `.short` runs of
        # the curve tables carry none at all -- so fall back to the object's own header
        # line, `; EGEnv_ValueCurve_Simple -- 0xFDE02B..0xFDE12A`.  Without this the
        # address of a large data object is simply absent, which is how three checks in
        # section 2 came to fail on tables that are plainly there.
        _pat = re.compile(_HDR_ADDR.pattern % re.escape(_name))
        for _j in range(max(0, _ln - 40), _ln):
            _m = _pat.match(_lines[_j])
            if _m:
                _a = int(_m.group(1), 16)
                break
    if _a is not None:
        ADDR_OF_LABEL[_name] = _a
        LABEL_AT_ADDR.setdefault(_a, _name)


def _evaluator_facts(addr):
    """For one of the six evaluators: which curve table it indexes, its clamp, its
    record stride and base, and whether it ORs the mode-bit table.  Everything here
    is an instruction operand read out of the byte-identical listing."""
    lbl = LABEL_AT_ADDR.get(addr)
    if lbl is None or "__" in lbl:
        return None
    body = body_lines(lbl)
    text = "\n".join(l.split(";")[0] for l in body)
    curves = sorted({int(m, 16) for m in re.findall(r'0x(FDE[0-9A-F]{3})\b', text, re.I)})
    clamps = sorted({int(m, 16) for m in re.findall(r'cp\s+xiy,\s*0x([0-9A-F]{4})\b', text, re.I)})
    up = text.upper()
    return dict(label=lbl, curves=curves, clamps=clamps,
                stride=re.search(r'\bc,\s*%d\b' % EGREC_STRIDE, text) is not None,
                recbase=("0X%04X" % EGREC_BASE) in up,
                modebits=("0X%06X" % MODEBITS) in up)


def section_blocks():
    print("\n=== 2. THE THREE ENVELOPE BLOCKS -- six evaluators, four curve tables ===\n")
    print("  Every evaluator indexes the SAME 27-byte record array at RAM 0x%04X" % EGREC_BASE)
    print("  (`ld C,0x1b` then `ld <r>,0x4ccf`) and differs in ONE operand: the curve.\n")
    print("  %-6s %-30s %-10s %-8s %s" % ("block", "routine", "curve", "clamp", "mode bits"))
    facts = {}
    for letter in "ABC":
        for kind in ("base", "value"):
            a = BLOCKS[letter][kind]
            f = _evaluator_facts(a)
            facts[(letter, kind)] = f
            if f is None:
                print("  %-6s 0x%06X  NOT FOUND" % (letter + "/" + kind, a))
                continue
            print("  %-6s %-30s %-10s %-8s %s"
                  % (letter + "/" + kind, f["label"],
                     ",".join("%06X" % c for c in f["curves"]),
                     ",".join("%04X" % c for c in f["clamps"]),
                     "yes" if f["modebits"] else "no"))
    for letter in "ABC":
        check("0x%06X really is the label %s in the source"
              % (BASECURVE[letter], BASECURVE_LABEL[letter]),
              LABEL_AT_ADDR.get(BASECURVE[letter]) == BASECURVE_LABEL[letter])
    check("0x%06X really is the label EGEnv_ValueCurve_Simple" % VALUECURVE,
          LABEL_AT_ADDR.get(VALUECURVE) == "EGEnv_ValueCurve_Simple")
    check("0x%06X really is the label EGEnv_ModeBits_Table" % MODEBITS,
          LABEL_AT_ADDR.get(MODEBITS) == "EGEnv_ModeBits_Table")
    print()
    for letter in "ABC":
        fb = facts[(letter, "base")]
        fv = facts[(letter, "value")]
        check("block %s base evaluator indexes %s (0x%06X)"
              % (letter, BASECURVE_LABEL[letter], BASECURVE[letter]),
              fb and BASECURVE[letter] in fb["curves"])
        check("block %s value evaluator indexes EGEnv_ValueCurve_Simple (0x%06X)"
              % (letter, VALUECURVE), fv and VALUECURVE in fv["curves"])
        check("block %s base evaluator clamps to 0x1FFF, value evaluator to 0x3FFF" % letter,
              fb and fv and 0x1FFF in fb["clamps"] and 0x3FFF in fv["clamps"])
        check("block %s base evaluator ORs EGEnv_ModeBits_Table, value evaluator does not" % letter,
              fb and fv and fb["modebits"] and not fv["modebits"])
        check("block %s: both evaluators index RAM 0x%04X with stride %d"
              % (letter, EGREC_BASE, EGREC_STRIDE),
              fb and fv and fb["recbase"] and fv["recbase"] and fb["stride"] and fv["stride"])
    # ★ the pairing, proved by co-occurrence -- stated in the form that survives the
    # ONE exception the census finds, rather than in the form that would have hidden it.
    kind_of = {}
    for letter in "ABC":
        kind_of[BLOCKS[letter]["base"]] = (letter, "base")
        kind_of[BLOCKS[letter]["value"]] = (letter, "value")
    callers = {}
    for a, lk in kind_of.items():
        for _site, routine in call_sites(a):
            callers.setdefault(routine, set()).add(lk)
    print("\n  ★ THE PAIRING, BY CO-OCCURRENCE over every caller of any of the six:")
    for r in sorted(callers):
        print("     %-40s %s" % (r, " ".join(sorted(l + "/" + k for l, k in callers[r]))))
    # (a) a value evaluator is never called beside another block's base evaluator
    crossed = []
    for r, s_ in callers.items():
        vs = {l for l, k in s_ if k == "value"}
        bs = {l for l, k in s_ if k == "base"}
        if vs and bs and vs != bs:
            crossed.append(r)
        if len(vs) > 1:
            crossed.append(r)
    check("no routine calls one block's VALUE evaluator beside another block's BASE "
          "evaluator, and none calls two blocks' value evaluators (%d callers)" % len(callers),
          not crossed)
    # (b) the one caller that spans blocks, named rather than smoothed away
    multi = {r: sorted({l for l, k in s_}) for r, s_ in callers.items()
             if len({l for l, k in s_}) > 1}
    print("\n  ⚠ THE ONE EXCEPTION, stated rather than smoothed away: %s"
          % (", ".join(sorted(multi)) or "none"))
    check("exactly one routine spans blocks and it is sub_FABE30/its new name",
          len(multi) == 1 and list(multi)[0] in ("sub_FABE30", "Voice_RecomputeAllThreeBaseCurves"))
    if multi:
        r = list(multi)[0]
        check("that routine calls all three BASE evaluators and NO value evaluator",
              {l for l, k in callers[r] if k == "base"} == {"A", "B", "C"}
              and not [1 for l, k in callers[r] if k == "value"])
    check("at least 12 distinct callers were examined", len(callers) >= 12)
    return facts, callers


# ---------------------------------------------------------------------------
# 3 -- THE 0x0010C000 STAGING-WORD PRODUCERS
# ---------------------------------------------------------------------------
# old name -> the register blocks it is being named for.  The blocks are DERIVED
# (struct_writes() x WORD2BLOCK); this table only records which routines the round
# claims, so a routine that stops writing the words it is named for fails a check.
STAGERS = {
    "sub_FAA0BC": ("Voice_StageRegs_00C0_AB", ["VoiceRegs_Stage_A", "VoiceRegs_Stage_B"]),
    "sub_FAA1A5": ("Voice_StageRegs_00C0_CD", ["VoiceRegs_Stage_C", "VoiceRegs_Stage_D"]),
    "sub_FAA4C3": ("Voice_StageRegs_0800_A", ["VoiceRegs_Stage_A"]),
    "sub_FAACEE": ("Voice_StageRegs_0800_B_ModeLt3", ["VoiceRegs_Stage_B"]),
    "sub_FAB0BD": ("Voice_StageRegs_0800_B_ModeGe3", ["VoiceRegs_Stage_B"]),
    "sub_FAA96C": ("Voice_StageRegs_0800_CD", ["VoiceRegs_Stage_C", "VoiceRegs_Stage_D"]),
    "sub_FAA87E": ("Voice_StageRegs_0840_0880_AB", ["VoiceRegs_Stage_A", "VoiceRegs_Stage_B"]),
    "sub_FAAC00": ("Voice_StageRegs_0840_0880_CD", ["VoiceRegs_Stage_C", "VoiceRegs_Stage_D"]),
    "sub_FA842D": ("Voice_StageRegs_0900_0940_0980_AB", ["VoiceRegs_Stage_A", "VoiceRegs_Stage_B"]),
    "sub_FA93AF": ("Voice_StageRegs_09C0_0A00_0A40_AB", ["VoiceRegs_Stage_A", "VoiceRegs_Stage_B"]),
    "sub_FA9C60": ("Voice_StageRegs_0180_AB", ["VoiceRegs_Stage_A", "VoiceRegs_Stage_B"]),
    "sub_FA826C": ("Voice_StageRegs_0040_B", ["VoiceRegs_Stage_B"]),
}
NEWNAME = {v[0]: k for k, v in STAGERS.items()}


def section_staging():
    print("\n=== 3. THE 0x0010C000 STAGING-WORD PRODUCERS this round names ===\n")
    # the join table, cross-checked against the module that owns it
    try:
        import prom_c_dev10c_field_sources as FS
        check("WORD2BLOCK agrees with notes/prom_c_dev10c_field_sources.py",
              FS.WORD2BLOCK == WORD2BLOCK)
    except Exception as e:                                     # pragma: no cover
        print("  [skip] could not import prom_c_dev10c_field_sources (%s)" % e)
    writes = struct_writes()
    print("  %-34s %-22s %s" % ("routine", "staged word -> register", "write site(s)"))
    for old, (new, want_callers) in STAGERS.items():
        key = old if old in writes else new
        w = writes.get(key, {})
        regs = ", ".join("%d -> 0x%04X+ch" % (wd, WORD2BLOCK[wd] * 0x40) for wd in sorted(w))
        sites = " ".join("%06X" % a for wd in sorted(w) for a in w[wd] if a)
        print("  %-34s %-22s %s" % (key, regs or "(none)", sites))
        # the name claims exactly these register blocks
        claimed = re.findall(r'_([0-9A-F]{4})(?=_|$)', new)
        got = {"%04X" % (WORD2BLOCK[wd] * 0x40) for wd in w}
        check("%s writes exactly the register block(s) its name claims (%s)"
              % (new, ",".join(sorted(claimed))), set(claimed) == got)
        # and the callers the _AB / _CD / _A / _B suffix claims
        callers = {r for _s, r in call_sites(ADDR_OF_LABEL[key])}
        check("%s is called from %s" % (new, ", ".join(want_callers)),
              all(any(c == w or c.startswith(w + "__") for c in callers) for w in want_callers))
    # ★ the mode split inside VoiceRegs_Stage_B, which is what _ModeLt3/_ModeGe3 mean
    body = "\n".join(l for l in body_lines("VoiceRegs_Stage_B"))
    split = re.search(r'ld\s+l,\s*\(xde\+3\).*?;\s*(FB1F55).*?cps?\s+l,\s*3.*?;\s*(FB1F5F).*?'
                      r'jr nc,.*?;\s*(FB1F61)', body, re.S | re.I)
    check("VoiceRegs_Stage_B splits on voice_record[+0x03] < 3 at 0xFB1F55/0xFB1F5F/0xFB1F61",
          split is not None)
    lt3 = re.search(r'call\s+0xFAACEE|call\s+0x00faacee|Voice_StageRegs_0800_B_ModeLt3', body, re.I)
    ge3 = re.search(r'call\s+0xFAB0BD|Voice_StageRegs_0800_B_ModeGe3', body, re.I)
    check("both arms of that split are in VoiceRegs_Stage_B's body", bool(lt3) and bool(ge3))
    print("\n  ★ WHY `_ModeLt3` AND `_ModeGe3`.  VoiceRegs_Stage_B reads the voice record's")
    print("    byte +0x03 (`ld L,(XDE+0x03)` at 0xFB1F55), compares it with 3 (0xFB1F5F) and")
    print("    branches unsigned-not-carry at 0xFB1F61: below 3 it calls 0xFAACEE, at or above")
    print("    3 it calls 0xFAB0BD.  Both write the SAME staging word 12 (register 0x0800+ch).")
    print("    ⚠ What byte +0x03 of the voice record IS is not established here.")
    return writes


# ---------------------------------------------------------------------------
# 4 -- THE PARAMETER-CHANGE DISPATCHER
# ---------------------------------------------------------------------------
DISPATCH = 0xFAF031
DISPATCH_TABLE = 0xFAF08F
DISPATCH_N = 49            # index 0..0x30 -- `cp BC,0x30 / jrl UGT` at 0xFAF07B


def section_dispatch():
    print("\n=== 4. sub_FAF031 -- THE PARAMETER-CHANGE DISPATCHER ===\n")
    lbl = LABEL_AT_ADDR.get(DISPATCH) or "Voice_ApplyParamChange_Dispatch"
    sites = call_sites(DISPATCH)
    print("  entry 0x%06X, %d call sites in prom_c's own source" % (DISPATCH, len(sites)))
    named_cc = sorted({r for _a, r in sites if r and r.startswith("MidiCtrl_")})
    print("  callers whose own name is a MIDI controller number: %s" % ", ".join(named_cc))
    # the jump table, read out of the ROM
    ents = [u32le(DISPATCH_TABLE + 4 * k) for k in range(DISPATCH_N)]
    lo, hi = min(ents), max(ents)
    print("  jump table 0x%06X..0x%06X, %d entries, targets 0x%06X..0x%06X, %d distinct"
          % (DISPATCH_TABLE, DISPATCH_TABLE + 4 * DISPATCH_N - 1, DISPATCH_N, lo, hi, len(set(ents))))
    check("the table ends exactly where the first arm begins (0x%06X)"
          % (DISPATCH_TABLE + 4 * DISPATCH_N), DISPATCH_TABLE + 4 * DISPATCH_N == ents[0])
    check("every one of the %d entries points inside the routine (0x%06X..0xFAF33F)"
          % (DISPATCH_N, DISPATCH_TABLE),
          all(DISPATCH <= e <= 0xFAF33F for e in ents))
    check("the LAST entry (index %d) is 0x%06X and is a real arm"
          % (DISPATCH_N - 1, ents[-1]), DISPATCH <= ents[-1] <= 0xFAF33F)
    check("sub_FAF031 has %d call sites, not the header's 'no site outside this module'"
          % len(sites), len(sites) == 68)
    check("exactly seven MidiCtrl_CC* handlers call it (%s)" % ", ".join(named_cc),
          len(named_cc) == 7)
    # the six restage arms this round names, and the block each belongs to
    print("\n  ★ THE SIX ARMS THIS ROUND NAMES, one BASE and one VALUE per envelope block:")
    for letter in "ABC":
        for kind in ("base", "value"):
            a = BLOCKS[letter]["restage_" + kind]
            here = [s for s, r in call_sites(a)]
            inside = [s for s in here if s and DISPATCH <= s <= 0xFAF33F]
            print("     block %s %-5s 0x%06X  called from %d site(s), %d inside the dispatcher"
                  % (letter, kind, a, len(here), len(inside)))
            check("restage arm 0x%06X is reached only from inside the dispatcher" % a,
                  len(here) == len(inside) == 1)
    return sites, ents


# ---------------------------------------------------------------------------
# 5 -- THE 0x00104000 CHAIN, and the image VoiceRegs_Stage_B loads instead
# ---------------------------------------------------------------------------
D104_STRUCT_WORDS = 19     # Dev104_WriteAllChanRegs moves 19 words, fields 0x00..0x24
STAGEB_IMAGE = 0xFE1315    # 38 bytes = 19 words, block-copied into the struct
STAGEB_LOADER = 0xFC571A
PACKER_ADDR = 0xFC4DBD


def section_packer():
    print("\n=== 5. THE 0x00104000 STAGING STRUCT: one packer, and one fixed image ===\n")
    try:
        import prom_c_dev10c_field_sources as FS
        w = FS.dev104()
        offs = sorted({o for _a, o, _v in w})
        print("  the packer makes %d write sites covering %d DISTINCT struct offsets: %s"
              % (len(w), len(offs), " ".join("%02X" % o for o in offs)))
        even = sorted(o for o in offs if o % 2 == 0)
        allf = list(range(0, 2 * D104_STRUCT_WORDS, 2))
        missing = [o for o in allf if o not in even]
        print("  Dev104_WriteAllChanRegs reads %d words at 0x00..0x%02X; the packer's own"
              % (D104_STRUCT_WORDS, allf[-1]))
        print("  instructions leave %d of them alone: %s"
              % (len(missing), " ".join("+0x%02X" % o for o in missing)))
        check("the packer writes 19 SITES, not 19 offsets -- the figure "
              "FINDINGS-prom_c-dev10c-producers.md §3 states as '19 offsets'", len(w) == 19)
        check("those 19 sites cover 16 distinct offsets, 15 of them even",
              len(offs) == 16 and len(even) == 15)
        check("every offset the packer writes is inside 0x00..0x%02X" % allf[-1],
              all(0 <= o <= allf[-1] for o in offs))
    except Exception as e:                                     # pragma: no cover
        print("  [skip] prom_c_dev10c_field_sources not importable (%s)" % e)
    # ★ and the half of the story that was missing: Stage_B does not pack at all
    print("\n  ★ VoiceRegs_Stage_B DOES NOT RUN THE PACKER.")
    for stage in ("VoiceRegs_Stage_A", "VoiceRegs_Stage_B", "VoiceRegs_Stage_C",
                  "VoiceRegs_Stage_D"):
        cs = callees(stage)
        print("     %-20s packer 0x%06X: %-3s   image loader 0x%06X: %s"
              % (stage, PACKER_ADDR, "yes" if PACKER_ADDR in cs else "no",
                 STAGEB_LOADER, "yes" if STAGEB_LOADER in cs else "no"))
    check("Stage_A, Stage_C and Stage_D call the packer and Stage_B does not",
          all(PACKER_ADDR in callees(s) for s in
              ("VoiceRegs_Stage_A", "VoiceRegs_Stage_C", "VoiceRegs_Stage_D"))
          and PACKER_ADDR not in callees("VoiceRegs_Stage_B"))
    check("VoiceRegs_Stage_B calls the image loader 0x%06X and no other stage does"
          % STAGEB_LOADER,
          STAGEB_LOADER in callees("VoiceRegs_Stage_B")
          and not any(STAGEB_LOADER in callees(s) for s in
                      ("VoiceRegs_Stage_A", "VoiceRegs_Stage_C", "VoiceRegs_Stage_D")))
    # the image itself
    lbl = LABEL_AT_ADDR.get(STAGEB_IMAGE) or "Dev104_StagingStruct_StageBImage"
    words = [u16le(STAGEB_IMAGE + 2 * k) for k in range(D104_STRUCT_WORDS)]
    print("\n  the image at 0x%06X (%s), %d words:" % (STAGEB_IMAGE, lbl, D104_STRUCT_WORDS))
    print("     " + " ".join("%04X" % w for w in words))
    loader = body_lines(LABEL_AT_ADDR[STAGEB_LOADER])
    txt = "\n".join(l.split(";")[0] for l in loader)
    check("the loader block-copies 0x26 = %d bytes = %d words from 0x%06X"
          % (2 * D104_STRUCT_WORDS, D104_STRUCT_WORDS, STAGEB_IMAGE),
          "0x%06X" % STAGEB_IMAGE in txt.upper().replace("0XFE1315", "0xFE1315")
          or "0xFE1315" in txt)
    check("the copy count is 38 (`push 0x0026` at 0xFC5751)",
          re.search(r'pushw\s+38\b', txt) is not None)
    # the five patches are `extpfx5`-encoded in the code column, so they are read
    # from the DECODED text the emitter puts in the comment column instead.
    dec = "\n".join(l.split(";", 1)[1] for l in loader if ";" in l)
    patches = re.findall(r'ld\s+\(XIX(?:\+(0x[0-9a-f]+))?\),(\S+)', dec)
    print("  and then patches %d fields: %s"
          % (len(patches), ", ".join("+%s=%s" % (o or "0x00", v) for o, v in patches)))
    check("the loader patches exactly five struct fields after the copy", len(patches) == 5)
    other = [u16le(STAGEB_IMAGE + 2 * D104_STRUCT_WORDS + 2 * k)
             for k in range(D104_STRUCT_WORDS)]
    diff = [k for k in range(D104_STRUCT_WORDS) if words[k] != other[k]]
    print("  Dev104_StagingStruct_ResetImage, the 19 words that follow it:")
    print("     " + " ".join("%04X" % w for w in other))
    print("  the two images differ in %d of the 19 words: %s"
          % (len(diff), " ".join("word %d %04X/%04X" % (k, words[k], other[k]) for k in diff)))
    check("the two 19-word images differ in 15 of the 19 words (they are NOT twins -- "
          "the first draft of this check guessed one and was wrong)", len(diff) == 15)
    patched_words = {5, 6, 10, 11}
    check("every word the loader patches after the copy (5, 6, 10, 11) is ZERO in the "
          "ROM image, so the image is deliberately incomplete",
          all(words[k] == 0 for k in patched_words))
    check("the image is 19 words and ends where Dev104_StagingStruct_ResetImage begins "
          "(0x%06X)" % (STAGEB_IMAGE + 2 * D104_STRUCT_WORDS),
          LABEL_AT_ADDR.get(STAGEB_IMAGE + 2 * D104_STRUCT_WORDS)
          == "Dev104_StagingStruct_ResetImage")
    return words


# ---------------------------------------------------------------------------
# 6 -- THE RENAME TABLE
# ---------------------------------------------------------------------------
# (old, new, one-line evidence).  The FULL evidence for each is the routine header
# --headers writes into prom_c/wsa1_prom_c.s, and every number in those headers is
# re-derived by the sections above.
RENAMES = [
    # -- the 0x0010C000 staging-word producers (section 3) --------------------
    ("sub_FAA0BC", "Voice_StageRegs_00C0_AB",
     "writes staging word 3 (register 0x00C0+chan) at 0xFAA19A; called from "
     "VoiceRegs_Stage_A 0xFB0B39 and VoiceRegs_Stage_B 0xFB1F27"),
    ("sub_FAA1A5", "Voice_StageRegs_00C0_CD",
     "writes staging word 3 at 0xFAA2AB; called from VoiceRegs_Stage_C 0xFB2839 and "
     "VoiceRegs_Stage_D 0xFB2F0E"),
    ("sub_FAA4C3", "Voice_StageRegs_0800_A",
     "writes staging word 12 (register 0x0800+chan) at 0xFAA649; one caller, "
     "VoiceRegs_Stage_A 0xFB0B43"),
    ("sub_FAACEE", "Voice_StageRegs_0800_B_ModeLt3",
     "writes staging word 12 at 0xFAAE88; one caller, VoiceRegs_Stage_B 0xFB1F63, on the "
     "arm taken when voice_record[+0x03] < 3 (`cp L,3 / jr NC` 0xFB1F5F/0xFB1F61)"),
    ("sub_FAB0BD", "Voice_StageRegs_0800_B_ModeGe3",
     "writes staging word 12 at 0xFAB236; one caller, VoiceRegs_Stage_B 0xFB1F7B, the "
     "other arm of the same compare"),
    ("sub_FAA96C", "Voice_StageRegs_0800_CD",
     "writes staging word 12 at 0xFAAA31; called from VoiceRegs_Stage_C 0xFB2843, "
     "VoiceRegs_Stage_D 0xFB2F18 and two controller-update paths"),
    ("sub_FAA87E", "Voice_StageRegs_0840_0880_AB",
     "writes staging words 13 and 14 (registers 0x0840+chan and 0x0880+chan) at five "
     "sites 0xFAA8F5-0xFAA961; called from VoiceRegs_Stage_A and _B"),
    ("sub_FAAC00", "Voice_StageRegs_0840_0880_CD",
     "writes the same two words at six sites 0xFAAC77-0xFAACE3; called from "
     "VoiceRegs_Stage_C and _D"),
    ("sub_FA842D", "Voice_StageRegs_0900_0940_0980_AB",
     "writes staging words 16, 17 and 18 (registers 0x0900/0x0940/0x0980+chan) at "
     "0xFA85C0, 0xFA8649 and 0xFA865C; called from VoiceRegs_Stage_A and _B"),
    ("sub_FA93AF", "Voice_StageRegs_09C0_0A00_0A40_AB",
     "writes staging words 19, 20 and 21 (registers 0x09C0/0x0A00/0x0A40+chan) at "
     "0xFA94F1, 0xFA95B0 and 0xFA95C3; called from VoiceRegs_Stage_A and _B"),
    ("sub_FA9C60", "Voice_StageRegs_0180_AB",
     "writes staging word 6 (register 0x0180+chan) at 0xFA9F0E, the register the "
     "firmware reads back; called from VoiceRegs_Stage_A 0xFB0B2F and _B 0xFB1F1D"),
    ("sub_FA826C", "Voice_StageRegs_0040_B",
     "writes staging word 1 (register 0x0040+chan, the word the played note selects out "
     "of a key-zone record) at 0xFA82E4, 0xFA830F and 0xFA8318; one caller, "
     "VoiceRegs_Stage_B 0xFB1EF0"),
    # -- the two shared halves of the restage arms ----------------------------
    ("sub_FAE242", "Voice_RestageArm_BaseCurve_Shared",
     "called from exactly the three BASE restage arms (0xFAE386, 0xFAE603, 0xFAE884) and "
     "nowhere else"),
    ("sub_FAE2C6", "Voice_RestageArm_ValueCurve_Shared",
     "called from exactly the three VALUE restage arms (0xFAE4C0, 0xFAE73F, 0xFAE9C2) and "
     "nowhere else"),
    # -- the six envelope-record evaluators (section 2) ------------------------
    ("sub_FA796D", "EGEnv_Eval_BaseCurveA",
     "indexes EGEnv_BaseCurve_A (0xFDE12B) at 0xFA798B with field +1 of the 27-byte "
     "record at RAM 0x4CCF, clamps to 0x1FFF and ORs EGEnv_ModeBits_Table"),
    ("sub_FA7A4B", "EGEnv_Eval_BaseCurveB",
     "the same routine shape indexing EGEnv_BaseCurve_B (0xFDE22B) at 0xFA7A6D"),
    ("sub_FA7B31", "EGEnv_Eval_FreqWriteBaseCurve",
     "the same routine shape indexing Voice_FreqWrite_BaseCurve (0xFDE32B) at 0xFA7B5B"),
    ("sub_FA79F4", "EGEnv_Eval_ValueCurve_WithBaseCurveA",
     "indexes EGEnv_ValueCurve_Simple (0xFDE02B) at 0xFA7A13 with field +3, clamps to "
     "0x3FFF; every caller that calls it also calls EGEnv_Eval_BaseCurveA and no other "
     "base evaluator"),
    ("sub_FA7AD6", "EGEnv_Eval_ValueCurve_WithBaseCurveB",
     "the same, paired by co-occurrence with EGEnv_Eval_BaseCurveB"),
    ("sub_FA7C3A", "EGEnv_Eval_ValueCurve_WithFreqWriteCurve",
     "the same, paired by co-occurrence with EGEnv_Eval_FreqWriteBaseCurve"),
    # -- the three per-block device writers, and the all-three recompute -------
    ("sub_FB89F8", "Voice_RecomputeEnv_AndWriteSlot2",
     "calls EGEnv_Eval_BaseCurveA + its paired value evaluator and "
     "Dev10C_Slot2_WriteGateAndValue (0xFB7C27)"),
    ("sub_FB8AF6", "Voice_RecomputeEnv_AndWriteSlot1",
     "the block-B twin, ending in Dev10C_Slot1_WriteGateAndValue (0xFB7E13)"),
    ("sub_FB8BF6", "Voice_RecomputeEnv_AndWriteSlot1or3",
     "the block-C twin, ending in Dev10C_Slot1or3_WriteGateAndValue (0xFB7F09)"),
    ("sub_FABE30", "Voice_RecomputeAllThreeBaseCurves",
     "the only routine in the image that calls all three BASE evaluators and none of "
     "the three value evaluators"),
    # -- the parameter-change dispatcher and its six restage arms (section 4) --
    ("sub_FAF031", "Voice_ApplyParamChange_Dispatch",
     "68 call sites; a 49-entry jump table at 0xFAF08F selected by "
     "((arg2+1) & 0x3F) - 1, bounded by `cp BC,0x30 / jrl UGT` at 0xFAF07B"),
    ("sub_FAE34A", "Voice_Restage_Reg0440_BaseCurve_ForPart",
     "walks VoiceQuery_Tag00_Part's voice list and per voice calls "
     "Voice_StageChanSel_Reg0440_Reg0480 then Dev10C_SetChanReg_0440"),
    ("sub_FAE484", "Voice_Restage_Reg0440_ValueCurve_ForPart",
     "the value-curve arm of the same register: calls "
     "EGEnv_Eval_ValueCurve_WithBaseCurveA and Dev10C_SetChanReg_0440"),
    ("sub_FAE5C7", "Voice_Restage_Reg0180_BaseCurve_ForPart",
     "calls EGEnv_Eval_BaseCurveB and Dev10C_SetChanReg_0180"),
    ("sub_FAE703", "Voice_Restage_Reg0180_ValueCurve_ForPart",
     "calls EGEnv_Eval_ValueCurve_WithBaseCurveB and Dev10C_SetChanReg_0180"),
    ("sub_FAE848", "Voice_Restage_Reg04C0_BaseCurve_ForPart",
     "calls EGEnv_Eval_FreqWriteBaseCurve and Dev10C_SetChanReg_04C0"),
    ("sub_FAE986", "Voice_Restage_Reg04C0_ValueCurve_ForPart",
     "calls EGEnv_Eval_ValueCurve_WithFreqWriteCurve and Dev10C_SetChanReg_04C0"),
    # -- the 0x00104000 chain (section 5) -------------------------------------
    ("sub_FC4DBD", "Dev104_PackStagingStruct",
     "19 write sites over 16 distinct offsets of the struct its only argument points "
     "at -- the same 0x00..0x24 span Dev104_WriteAllChanRegs reads"),
    ("sub_FC4BB6", "Pack104_SetInputs_PartRecord",
     "sets the global 0x00E082 to 0x005D23 + 0xBB*arg, the part record the packer then "
     "reads; called from the five MidiNote_* sites"),
    ("sub_FC4C85", "Pack104_SetInputs_SubRecordPair",
     "sets 0x00E084 = (0x00E082) + 0x2A*arg + 0x13 and 0x00E086 = 0x00753E + 0x25*arg, "
     "the two sub-records the packer reads"),
    ("sub_FC571A", "Dev104_LoadStageBImage",
     "block-copies 38 bytes (19 words) from 0xFE1315 into the struct its argument "
     "points at and then patches five fields; VoiceRegs_Stage_B calls it INSTEAD of "
     "the packer"),
    # -- framed -> content (section 1's two promotions) ------------------------
    ("unexplained_FE1315", "Dev104_StagingStruct_StageBImage",
     "19 words = the 19 registers Dev104_WriteAllChanRegs writes; the block copy at "
     "0xFC575B moves it into the 0x00104000 staging struct"),
    ("Dev10C_SetChanReg_0400", "Dev10C_SetChanPitch_Reg0400",
     "register 0x0400+chan is the PITCH in 1/256 semitone -- established by "
     "notes/FINDINGS-prom_c-dev10c-register-meanings.md and "
     "notes/prom_c_dev10c_meaning_checks.py, not by this round"),
]


def section_names():
    print("\n=== 6. THE %d RENAMES THIS ROUND SHIPS ===\n" % len(RENAMES))
    text = open(SRC, encoding="utf-8").read()
    n_sub = n_framed = 0
    for old, new, ev in RENAMES:
        kind = ("sub_ -> content" if old.startswith("sub_") else "framed -> content")
        if old.startswith("sub_"):
            n_sub += 1
        else:
            n_framed += 1
        print("  %-38s -> %-42s [%s]" % (old, new, kind))
        print("      %s" % ev)
    print()
    check("every rename is present in the source under exactly one of its two names",
          all((re.search(r'^%s:' % o, text, re.M) is not None) !=
              (re.search(r'^%s:' % n, text, re.M) is not None) for o, n, _e in RENAMES))
    check("no two renames target the same new name",
          len({n for _o, n, _e in RENAMES}) == len(RENAMES))
    # the grade the goal metric will give each new name, computed with the metric's
    # own regexes so the round cannot claim a promotion the metric will not see
    graded = [n for _o, n, _e in RENAMES
              if not METRIC.FRAMED.match(n) and not METRIC.UNNAMED.match(n)
              and not METRIC.INTERNAL.match(n)]
    check("all %d new names grade CONTENT under notes/wave7_documentation_metrics.py"
          % len(RENAMES), len(graded) == len(RENAMES))
    print("\n  %d sub_XXXXXX retired, %d framed labels promoted." % (n_sub, n_framed))
    # ★ THE NUMBERS THIS ROUND REPORTS, re-derived so they cannot be quoted from prose.
    nm, fr, un, it, hdr, ev = METRIC.scan("prom_c/wsa1_prom_c.s")
    print("  notes/wave7_documentation_metrics.py, prom_c row AFTER this round:")
    print("     content %d   framed %d   sub_XXXXXX %d   LOWER %.1f%%   UPPER %.1f%%"
          % (len(nm), len(fr), len(un), 100.0 * len(nm) / (len(nm) + len(fr) + len(un)),
             100.0 * (len(nm) + len(fr)) / (len(nm) + len(fr) + len(un))))
    print("     BEFORE (the round's brief): content 757  framed 489  sub_XXXXXX 492"
          "  LOWER 43.6%  UPPER 71.7%")
    check("prom_c content is 757 + %d = %d" % (len(RENAMES), 757 + len(RENAMES)),
          len(nm) == 757 + len(RENAMES))
    n_framed_promoted = len([1 for o, _n, _e in RENAMES if not o.startswith("sub_")])
    n_sub_retired = len(RENAMES) - n_framed_promoted
    check("prom_c framed is 489 - %d = %d" % (n_framed_promoted, 489 - n_framed_promoted),
          len(fr) == 489 - n_framed_promoted)
    check("prom_c sub_XXXXXX is 492 - %d = %d" % (n_sub_retired, 492 - n_sub_retired),
          len(un) == 492 - n_sub_retired)
    n_mark = open(SRC, encoding="utf-8").read().count(MARK)
    print("  routine headers carrying this round's prose: %d (grep -c '%s')" % (n_mark, MARK))
    check("one round-6 paragraph per rename plus one per uDMA accessor (%d + %d)"
          % (len(RENAMES), len(UDMA)), n_mark == len(RENAMES) + len(UDMA))
    print("  ⚠ THE METRIC'S `headers` COLUMN MOVES BY ONLY %d, and that is correct: it"
          % len(UDMA))
    print("  counts LABELS THAT HAVE a >=3-line comment block, and all %d renamed routines"
          % len(RENAMES))
    print("  already had one.  What this round wrote for them is PROSE INSIDE an existing")
    print("  block -- %d new paragraphs -- while the %d micro-DMA accessors (section 8) had"
          % (len(RENAMES), len(UDMA)))
    print("  only a one-line comment and are the round's only NEW header blocks.")
    print("  A round-3 lane reported '+35 headers' that were 35 deleted blank lines; this")
    print("  is the opposite error to guard against, so both numbers are reported.")
    print("  ⚠ Five COMMITTED SCRIPTS name six of these routines as literal strings and")
    print("  would fail after the rename; --apply patches them in the same pass and")
    print("  --selftest re-runs them:")
    for f in AFFECTED_SCRIPTS:
        print("     %s" % f)


# Committed scripts that compare against the OLD label text and must move with it.
# --apply rewrites them; --selftest re-runs each and requires exit 0.
AFFECTED_SCRIPTS = [
    "notes/prom_c_curve_table_census.py",
    "notes/audit_wave6_round3_probes.py",
    "notes/prom_c_gapA_remaining_regs.py",
    "notes/prom_c_dev10c_field_sources.py",
    "notes/gen_prom_c_tail_tables.py",
]


# ---------------------------------------------------------------------------
# 7 -- WHAT THIS ROUND COULD NOT NAME, AND WHY
# ---------------------------------------------------------------------------
def section_gaps():
    print("\n=== 7. THE HONEST INVENTORY: what prom_c's remaining debt actually is ===\n")
    named, framed, unnamed, internal = framed_labels()[1], None, None, None
    nm, fr, un, it, hdr, ev = METRIC.scan("prom_c/wsa1_prom_c.s")
    print("  content %d   framed %d   sub_XXXXXX %d   internal %d   headers %d   evidence %d"
          % (len(nm), len(fr), len(un), len(it), hdr, ev))
    print()
    print("  ★ THE HEADER FIGURE IS NOT A DEFICIT, and the brief's reading of it is wrong.")
    # every sub_XXXXXX already carries a header and an Evidence: line
    lines = open(SRC, encoding="utf-8").read().split("\n")
    run = blanks = 0
    have_ev = False
    sub_no_hdr, sub_no_ev, content_no_hdr, internal_names = [], [], [], 0
    for ln in lines:
        if ln.startswith(";"):
            run += 1
            if "Evidence:" in ln:
                have_ev = True
            blanks = 0
            continue
        if ln.strip() == "" and run:
            blanks += 1
            if blanks > 1:
                run, have_ev, blanks = 0, False, 0
            continue
        m = LABEL.match(ln)
        if m:
            n = m.group(1)
            if METRIC.INTERNAL.match(n):
                pass
            elif METRIC.UNNAMED.match(n):
                if run < 3:
                    sub_no_hdr.append(n)
                if not have_ev:
                    sub_no_ev.append(n)
            elif not METRIC.FRAMED.match(n):
                if run < 3:
                    content_no_hdr.append(n)
                    if "__" in n:
                        internal_names += 1
        run, have_ev, blanks = 0, False, 0
    check("every one of prom_c's %d sub_XXXXXX already has a >=3-line header" % len(un),
          not sub_no_hdr)
    check("every one of them already has an Evidence: line", not sub_no_ev)
    print("     %d content labels have no header -- but %d of those are `Parent__word`"
          % (len(content_no_hdr), internal_names))
    print("     BRANCH TARGETS (RESET__clear_dram, MAIN__midi_drain), for which a header")
    print("     would be noise, and %d more are PresetBank_* rows of a named table."
          % len([n for n in content_no_hdr if n.startswith("PresetBank")]))
    real = [n for n in content_no_hdr
            if "__" not in n and not n.startswith("PresetBank")]
    print("     The real header deficit in prom_c is %d labels: %s"
          % (len(real), ", ".join(sorted(real)[:12]) + (" ..." if len(real) > 12 else "")))
    check("the real header deficit is under 20 labels, not 308", len(real) < 20)
    print()
    print("  ★ WHAT REMAINS UNNAMEABLE, and what would settle each:")
    print("    * 297 P7Stream_* + 56 PoolDir_FieldRec_* (374 framed labels).  Their bytes")
    print("      are byte-code for a device on port P7 and 130 of the 297 streams do not")
    print("      even frame as the located interpreter's payload")
    print("      (FINDINGS-prom_c-p7-byte-stream-pool.md §0).  SETTLED BY: finding the")
    print("      SECOND consumer, the routine that reads the other payload convention.")
    print("    * 44 tail-zone Table_/Curve_/LinCoef_ objects.  Shape and reader known,")
    print("      role not.  SETTLED BY: reading one reader end to end; the headers already")
    print("      carry the index, the closed form and the citation.")
    print("    * The 27-byte record array at RAM 0x4CCF that all six envelope evaluators")
    print("      index.  This round establishes the ARRAY, its stride and five of its")
    print("      fields; nothing here says what its index n selects.  SETTLED BY: the")
    print("      routine that WRITES 0x4CCF -- not searched for in this round.")
    print("    * What each of the three envelope blocks modulates.  Three blocks, three")
    print("      registers, three curve tables; no ROM byte names a role.")
    print("    * sub_FB0B95 (698 B) stays sub_: NOTHING in the image references it.")
    print("      A name would have to say what it is FOR and nothing calls it.")


# ---------------------------------------------------------------------------
# THE ROUTINE HEADERS.  One entry per new name; --headers splices them into the
# comment block above the label and deletes the auto-generated
# "Unknown: what the routine is FOR ... so the name is an address" paragraph,
# which stops being true the moment the routine has a name.
# ---------------------------------------------------------------------------
MARK = "★ ROUND 6"
BOILERPLATE = (
    "; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,",
    ";          so the name is an address.",
)

_STAGE_NOTE = """%s -- stages %s of the 0x0010C000 per-channel
         staging struct at RAM 0x00D75E, and nothing else in that struct.
         Write site(s): %s.
         Argument: the caller pushes XDE, the 68-byte VOICE RECORD at 0x003BCF + 0x44*voice
         (`ld C,0x44 / mul BC,(XIZ+0x08) / ld <r>,0x3bcf` at the top of every
         VoiceRegs_Stage_*), immediately before the call.
         Called from: %s.
         Evidence: the write addresses above are instruction operands, listed by
         `python3 notes/prom_c_understanding_round6.py --staging`, which also asserts that
         this routine writes EXACTLY the register block(s) its name claims and no other.
         The struct-word -> register-block map is Dev10C_WriteAllChanRegs's own
         (notes/prom_c_tg_chanmap.py), cross-checked against
         notes/prom_c_dev10c_field_sources.py by the same section.
         Unknown: what register %s carries.  The name states WHICH register this
         routine produces, never what the register means."""


def _reg_note(new, words, writes_map):
    w = writes_map
    regs = ", ".join("word %d (register 0x%04X + chan)" % (wd, WORD2BLOCK[wd] * 0x40)
                     for wd in sorted(w))
    sites = ", ".join("0x%06X" % a for wd in sorted(w) for a in w[wd] if a)
    onereg = " / ".join("0x%04X" % (WORD2BLOCK[wd] * 0x40) for wd in sorted(w))
    callers = sorted({r for _s, r in call_sites(ADDR_OF_LABEL[new])
                      if r} )
    return _STAGE_NOTE % (new, regs, sites, ", ".join(callers), onereg)


HEADER_NOTES = {
    "EGEnv_Eval_BaseCurveA": """EGEnv_Eval_BaseCurveA -- one of SIX evaluators of the
         27-byte record array at RAM 0x4CCF (`ld C,0x1b` 0xFA7974, `ld HL,0x4ccf` 0xFA797C).
         value = ((EGEnv_BaseCurve_A[rec+1] * rec[+2]) - correction) >> 7, clamped to
         0x1FFF, OR'd with EGEnv_ModeBits_Table[rec[+0] & 3].
             0xFA798B  add XBC,0x00FDE12B   the curve, indexed by rec[+1]*2
             0xFA79C2  srl 0x07,XIY         the >> 7
             0xFA79C7  cp XIY,0x1FFF        the clamp
             0xFA79E2  add XBC,0x00FDEBEC   EGEnv_ModeBits_Table, indexed by rec[+0]&3
         The correction (skipped when rec[+5] == 0) is sub_FA7927(product, rec[+6], rec[+5]).
         Evidence: `python3 notes/prom_c_understanding_round6.py --blocks`, which reads all
         six evaluators out of the listing and asserts that each indexes exactly one base
         curve, that the base evaluators clamp to 0x1FFF and the value evaluators to
         0x3FFF, and that only the base evaluators touch the mode-bit table.
         ★ THIS IS BLOCK A OF THREE.  A/B/C are THIS TREE'S labels for three groups that
         differ in one operand -- which of the three 256-byte base curves at 0xFDE12B,
         0xFDE22B and 0xFDE32B they index.  Block A's stager writes registers 0x0440 and
         0x0480; block B's writes 0x0180; block C's writes 0x04C0.  No ROM byte spells "A".
         Unknown: what the record at 0x4CCF is, what its index selects, and what the block
         modulates.""",
    "EGEnv_Eval_BaseCurveB": """EGEnv_Eval_BaseCurveB -- block B's base evaluator: the same
         shape as EGEnv_Eval_BaseCurveA with ONE operand changed, EGEnv_BaseCurve_B
         (`add XBC,0x00FDE22B` at 0xFA7A6D instead of 0x00FDE12B).  Same record array, same
         fields +0/+1/+2/+5/+6, same 0x1FFF clamp, same EGEnv_ModeBits_Table OR.
         Evidence: notes/prom_c_understanding_round6.py --blocks.""",
    "EGEnv_Eval_FreqWriteBaseCurve": """EGEnv_Eval_FreqWriteBaseCurve -- block C's base
         evaluator: the same shape again, indexing Voice_FreqWrite_BaseCurve (0xFDE32B) at
         0xFA7B5B and 0xFA7BCE, and it evaluates the record TWICE, storing 0x00D796 and
         0x00D7A0.
         ⚠ WHY NOT `EGEnv_Eval_BaseCurveC`.  0xFDE32B is the third of three 256-byte tables
         0x100 apart read by three routines that differ in nothing else, so
         `Voice_FreqWrite_BaseCurve` beside `EGEnv_BaseCurve_A` and `_B` looks like an
         inconsistency -- and renaming it was considered and REJECTED this round.  All three
         names are KN5000 sub-CPU transplants onto BYTE-IDENTICAL tables (prom_c 0xFDE12B /
         0xFDE22B / 0xFDE32B <- kn5000 sub-CPU 0x10A64 / 0x10B64 / 0x10C64,
         notes/FINDINGS-kn5000-transplant-offset.md).  The asymmetry is the SIBLING'S;
         erasing it would destroy what makes the transplant checkable.
         Evidence: notes/prom_c_understanding_round6.py --blocks.""",
    "EGEnv_Eval_ValueCurve_WithBaseCurveA": """EGEnv_Eval_ValueCurve_WithBaseCurveA -- the
         other half of block A.  value = (EGEnv_ValueCurve_Simple[rec[+3]] * rec[+4]) >> 7,
         clamped to 0x3FFF, with NO mode bits.
             0xFA7A13  add XBC,0x00FDE02B   EGEnv_ValueCurve_Simple, indexed by rec[+3]*2
             0xFA7A2F  srl 0x07,XIY
             0xFA7A34  cp XIY,0x3FFF
         ★ THE PAIRING IS MEASURED, NOT ASSUMED.  All three value evaluators read the SAME
         table with the SAME fields, so what makes this one block A's is CO-OCCURRENCE: over
         the thirteen routines in the image that call any of the six evaluators, none calls
         one block's value evaluator beside another block's base evaluator, and none calls
         two blocks' value evaluators.  The one routine that spans blocks --
         Voice_RecomputeAllThreeBaseCurves -- calls all three BASE evaluators and no value
         evaluator, and is named rather than smoothed away.
         Evidence: notes/prom_c_understanding_round6.py --blocks prints the whole caller
         table and asserts both properties.""",
    "EGEnv_Eval_ValueCurve_WithBaseCurveB": """EGEnv_Eval_ValueCurve_WithBaseCurveB -- block
         B's value evaluator; `add XBC,0x00FDE02B` at 0xFA7AF9, clamp 0x3FFF at 0xFA7B1A.
         Paired with EGEnv_Eval_BaseCurveB by the co-occurrence census
         (notes/prom_c_understanding_round6.py --blocks).""",
    "EGEnv_Eval_ValueCurve_WithFreqWriteCurve": """EGEnv_Eval_ValueCurve_WithFreqWriteCurve --
         block C's value evaluator; `add XBC,0x00FDE02B` at 0xFA7C5D, clamp 0x3FFF at
         0xFA7C84.  It also tests bit 5 of rec[+0] (`and C,0x20` at 0xFA7C95) and writes the
         globals 0x00D798 and 0x00D79C, which the other two value evaluators do not.
         Paired with EGEnv_Eval_FreqWriteBaseCurve by the co-occurrence census.""",
    "Voice_RecomputeEnv_AndWriteSlot2": """Voice_RecomputeEnv_AndWriteSlot2 -- re-evaluates
         BLOCK A's envelope record (EGEnv_Eval_BaseCurveA at 0xFB8AC9 and
         EGEnv_Eval_ValueCurve_WithBaseCurveA at 0xFB8AD7) and pushes the result straight at
         the device through Dev10C_Slot2_WriteGateAndValue (0xFB7C27), without going through
         the 22-word staging struct.  Called from four consecutive sites 0xFBBB99-0xFBBBC6.
         Evidence: the callee addresses are instruction operands; the block letter is the
         co-occurrence census in notes/prom_c_understanding_round6.py --blocks.""",
    "Voice_RecomputeEnv_AndWriteSlot1": """Voice_RecomputeEnv_AndWriteSlot1 -- block B's twin
         of the routine above: EGEnv_Eval_BaseCurveB (0xFB8BC9),
         EGEnv_Eval_ValueCurve_WithBaseCurveB (0xFB8BD7), then
         Dev10C_Slot1_WriteGateAndValue (0xFB7E13).  Four call sites 0xFBBBD5-0xFBBC02.""",
    "Voice_RecomputeEnv_AndWriteSlot1or3": """Voice_RecomputeEnv_AndWriteSlot1or3 -- block C's
         twin: EGEnv_Eval_FreqWriteBaseCurve (0xFB8CC9),
         EGEnv_Eval_ValueCurve_WithFreqWriteCurve (0xFB8CD2), then
         Dev10C_Slot1or3_WriteGateAndValue (0xFB7F09).  Four call sites 0xFBBC11-0xFBBC3E.""",
    "Voice_RecomputeAllThreeBaseCurves": """Voice_RecomputeAllThreeBaseCurves -- the ONE
         routine in the image that calls all three BASE evaluators (0xFABE60, 0xFABEEB,
         0xFABF7E) and none of the three value evaluators, writing 0x00D796, 0x00D79E and
         0x00D7A0 and then Dev10C_SetChanReg_01C0_b / _0600_b / _01C0_or_0600_b.
         Evidence: the co-occurrence census in notes/prom_c_understanding_round6.py --blocks
         enumerates every caller of every evaluator; this is the only row with more than one
         block letter, and the check that says so names it explicitly.""",
    "Voice_ApplyParamChange_Dispatch": """★★ Voice_ApplyParamChange_Dispatch -- the routine
         that pushes ONE changed parameter back out to the hardware.  68 call sites in
         prom_c, seven of them inside named MIDI controller handlers (MidiCtrl_CC01, CC02,
         CC04, CC16, CC17, CC18, CC19).
             H  = (XIZ+0x08)   a part or voice selector
             DE = (XIZ+0x0a)   the new value
             XIX= (XIZ+0x0c)   a record whose byte +1 carries the 6-bit TARGET CODE
         `ld L,(XIX+0x01) / and L,0x3f` at 0xFAF041 and 0xFAF044 takes the code; the value is
         then normalised -- for code 1, `DE & 0x8000 ? DE &= 0x7FFF : DE <<= 7`
         (0xFAF04D-0xFAF05A); for every other code, `DE & 0x8000 ? DE = (DE & 0x7FFF) >> 7`
         (0xFAF063-0xFAF06E).  Then `dec 1,BC / cp BC,0x30 / jrl UGT` (0xFAF079-0xFAF07F)
         bounds the index to 0..48 and `sll 2,BC / add XBC,0x00FAF08F / ld XBC,(XBC) /
         jp (XBC)` dispatches through a 49-entry table.
         ★ THE TABLE IS 49 ENTRIES AND 48 DISTINCT ARMS, and the two facts are independent:
         0xFAF08F + 4*49 = 0xFAF153, which is exactly where the first arm begins, and entry
         0 and the out-of-range path both reach 0xFAF33A.
         Evidence: every address above is an instruction operand; the table is read out of
         the ROM bytes and the arm count, the last entry and the 68 call sites are asserted
         by `python3 notes/prom_c_understanding_round6.py --dispatch`.
         Unknown: what the 6-bit target code MEANS, i.e. what parameter each of the 49
         entries is.  The arms are named for the REGISTER each one refreshes, which is an
         instruction operand, and for nothing else.""",
    "Dev104_PackStagingStruct": """★ Dev104_PackStagingStruct -- the ONE routine that fills the
         0x00104000 staging struct.  Its only argument is the struct pointer, and it makes
         19 WRITE SITES over 16 DISTINCT OFFSETS inside 0x00..0x24 -- the same span
         Dev104_WriteAllChanRegs reads as 19 consecutive words.
         ⚠ CORRECTION: notes/FINDINGS-prom_c-dev10c-producers.md §3 says "writes 19 offsets
         in 0x00..0x24".  Nineteen is the number of WRITE SITES; the distinct offsets are
         16, of which 15 are even (whole words) and one (+0x1D) is a high-byte write.  Four
         of the nineteen even fields -- +0x06, +0x08, +0x12 and +0x16 -- are not written by
         this routine's own instructions at all; +0x06 and +0x08 come from sub_FC49AD, which
         it calls at 0xFC56AA.
         Its inputs are the globals 0x00E082-0x00E08D, set by Pack104_SetInputs_PartRecord,
         Pack104_SetInputs_SubRecordPair, Pack104_SetInputs_E088_E089_E08A and
         Pack104_SetInputs_Rec0E_E08D.
         Evidence: `python3 notes/prom_c_understanding_round6.py --packer`, which counts the
         sites and the offsets with notes/prom_c_dev10c_field_sources.py's own scanner and
         asserts 19/16/15.""",
    "Pack104_SetInputs_PartRecord": """Pack104_SetInputs_PartRecord -- sets the global
         0x00E082 to 0x005D23 + 0xBB*arg, i.e. selects one 187-byte PART RECORD as the one
         Dev104_PackStagingStruct will read, and also writes 0x00E08F-0x00E092.
         Called from the five MidiNote_* sites 0xFB369D, 0xFB37AA, 0xFB38BF, 0xFB3A0A and
         0xFB3B09, so "the part this note-on belongs to" is what it selects.
         Evidence: the stride 0xBB and the base 0x005D23 are instruction operands; the
         caller list is the routine's own Called-from census.""",
    "Pack104_SetInputs_SubRecordPair": """Pack104_SetInputs_SubRecordPair -- sets the two
         sub-record pointers the packer reads: 0x00E084 = (0x00E082) + 0x2A*arg + 0x13 (a
         42-byte sub-record at +0x13 inside the part record; 187 - 19 = 168 = 4 x 42) and
         0x00E086 = 0x00753E + 0x25*arg (a 37-byte record array), the latter through
         `lda XIX,0x00e086` at 0xFC4C8C.
         Called from the same five MidiNote_* paths as Pack104_SetInputs_PartRecord.
         Unknown: what either sub-record IS.""",
    "Dev104_LoadStageBImage": """★ Dev104_LoadStageBImage -- and the finding that goes with it:
         VoiceRegs_Stage_B NEVER RUNS THE 0x00104000 PACKER.  Stage_A, Stage_C and Stage_D
         all call Dev104_PackStagingStruct; Stage_B calls this instead, at 0xFB1F42, with the
         same struct pointer 0x00D7A2.
         It zeroes four fields of the record at (0x00E086) (+5, +8, +0x0A, +0x1C), block-
         copies 38 bytes = 19 words from Dev104_StagingStruct_StageBImage (0xFE1315) through
         MemCopyWords (`push 0x0026` at 0xFC5751, `call 0xF9A038` at 0xFC575B), and then
         patches five fields of the struct:
             (+0x00) = (0x00E086)[+7] << 8      0xFC576E
             (+0x0A) = 0x05A8                   0xFC5770
             (+0x0C) = 0x05A8                   0xFC5775
             (+0x14) = 0x8000                   0xFC577F
             (+0x16) = 0xFF00                   0xFC577A
         Evidence: `python3 notes/prom_c_understanding_round6.py --packer` asserts the
         packer/loader split across all four VoiceRegs_Stage_* routines, the copy count, and
         that exactly five fields are patched.
         ⚠ WHAT THIS IS WORTH TO THE EMULATOR: on the Stage_B path the nineteen 0x00104000
         registers of a voice are a CONSTANT image plus five patched words, not a computed
         packing.  Unknown: what selects the Stage_B path.""",
    "Dev104_StagingStruct_StageBImage": """★ Dev104_StagingStruct_StageBImage -- 0xFE1315,
         38 bytes = NINETEEN 16-bit words, and 19 is the number of registers
         Dev104_WriteAllChanRegs writes from 19 consecutive words of the 0x00104000 staging
         struct.  Dev104_LoadStageBImage block-copies it there (`push 0x0026` at 0xFC5751,
         `lda XBC,0xfe1315` at 0xFC5755, `call 0xF9A038` = MemCopyWords at 0xFC575B) on the
         VoiceRegs_Stage_B path, which does not run the packer at all.
         It ends exactly where Dev104_StagingStruct_ResetImage (0xFE133B) begins -- two
         19-word images of the same struct, back to back, one loaded per note by Stage_B and
         one loaded per channel by Dev10C_ResetAllChannels.  ⚠ THEY ARE NOT TWINS: 15 of the
         19 words differ (the first draft of this round's check guessed "one" and the check
         caught it).  Nine of this image's words are ZERO where the reset image has a value,
         and FOUR of those nine -- words 5, 6, 10 and 11 -- are exactly the words
         Dev104_LoadStageBImage patches after the copy, so the ROM image is deliberately
         incomplete and the loader finishes it.
         ⚠ WAS `unexplained_FE1315`.  The count 19 and the copy are instruction operands;
         `python3 notes/prom_c_understanding_round6.py --packer` asserts both, and that the
         object abuts the reset image.
         Unknown: what any of the nineteen words means -- the same gap the reset image has.""",
    "Voice_RestageArm_BaseCurve_Shared": """Voice_RestageArm_BaseCurve_Shared -- the body
         the three BASE restage arms share.  Its ONLY call sites are 0xFAE386 in
         Voice_Restage_Reg0440_BaseCurve_ForPart, 0xFAE603 in
         Voice_Restage_Reg0180_BaseCurve_ForPart and 0xFAE884 in
         Voice_Restage_Reg04C0_BaseCurve_ForPart -- three of three, and nothing else in the
         512 KiB.  Its value-curve counterpart is Voice_RestageArm_ValueCurve_Shared, whose
         three call sites are the other three arms.
         The two are 132 bytes each and differ in which helper they call (0xFAD37E and
         0xFB501F here, 0xFAD43E and 0xFB5103 there); they share 0xFB53C5.
         ⚠ NOT ESTABLISHED: what any of those helpers computes.  The name records the
         PARTITION -- base arms here, value arms there -- which is a call census, and
         nothing else.
         Evidence: the call sites are the routine's own Called-from census, reproduced by
         `python3 notes/prom_c_understanding_round6.py --names`.""",
    "Voice_RestageArm_ValueCurve_Shared": """Voice_RestageArm_ValueCurve_Shared -- the body
         the three VALUE restage arms share; call sites 0xFAE4C0, 0xFAE73F and 0xFAE9C2,
         three of three and nothing else.  See Voice_RestageArm_BaseCurve_Shared above for
         the partition and for what it does NOT establish.""",
    "Dev10C_SetChanPitch_Reg0400": """⚠ RENAMED (was Dev10C_SetChanReg_0400).  Register
         0x0400 + chan of the 0x0010C000 device is the PITCH, in 1/256 of a semitone --
         established by notes/FINDINGS-prom_c-dev10c-register-meanings.md and re-derived by
         `python3 notes/prom_c_dev10c_meaning_checks.py`, NOT by this round.  The register
         number is kept in the name so the claim stays checkable against that finding.""",
}


_ARM_NOTE = """%s -- one of the 49 arms of
         Voice_ApplyParamChange_Dispatch (its ONLY caller, at 0x%06X), and the one that
         refreshes register 0x%s + chan for every voice the part owns.
         It obtains the part's voice list from VoiceQuery_Tag00_Part (0xFB3CE0), walks it
         while the voice number is below 0x40, forms voice_record = 0x003BCF + 0x44*voice,
         and per voice calls %s and then %s.
         Evidence: the callee addresses are instruction operands;
         `python3 notes/prom_c_understanding_round6.py --dispatch` asserts that this arm has
         exactly one call site and that it is inside the dispatcher, and --blocks asserts
         which envelope block its evaluator belongs to.
         Unknown: what register 0x%s carries, and what the dispatcher's target code
         for this arm means."""

ARMS = {
    "Voice_Restage_Reg0440_BaseCurve_ForPart":
        (0xFAE34A, "0440", "Voice_StageChanSel_Reg0440_Reg0480 (0xFA9915)",
         "Dev10C_SetChanReg_0440 (0xFACFD6)"),
    "Voice_Restage_Reg0440_ValueCurve_ForPart":
        (0xFAE484, "0440", "EGEnv_Eval_ValueCurve_WithBaseCurveA (0xFA79F4)",
         "Dev10C_SetChanReg_0440 (0xFACFD6) / _0580 / _0600"),
    "Voice_Restage_Reg0180_BaseCurve_ForPart":
        (0xFAE5C7, "0180", "EGEnv_Eval_BaseCurveB (0xFA7A4B)",
         "Dev10C_SetChanReg_0180 (0xFACFB4) / _01C0"),
    "Voice_Restage_Reg0180_ValueCurve_ForPart":
        (0xFAE703, "0180", "EGEnv_Eval_ValueCurve_WithBaseCurveB (0xFA7AD6)",
         "Dev10C_SetChanReg_0180 (0xFACFB4) / _01C0 / _0540"),
    "Voice_Restage_Reg04C0_BaseCurve_ForPart":
        (0xFAE848, "04C0", "EGEnv_Eval_FreqWriteBaseCurve (0xFA7B31)",
         "Dev10C_SetChanReg_04C0 (0xFACFF8) / _01C0_or_0600"),
    "Voice_Restage_Reg04C0_ValueCurve_ForPart":
        (0xFAE986, "04C0", "EGEnv_Eval_ValueCurve_WithFreqWriteCurve (0xFA7C3A)",
         "Dev10C_SetChanReg_04C0 (0xFACFF8) / _0540_or_0580"),
}


# ---------------------------------------------------------------------------
# The one register this round decodes to a FORMULA rather than to a producer.
# Every address below is checked against the listing line at that exact address by
# section_reg00C0(), which is the defence against this tree's documented
# cited-one-byte-past-the-instruction defect.
# ---------------------------------------------------------------------------
REG00C0_CITES = [
    (0xFAA0C8, "(xbc+35)",  "P   = voice_record[+0x23], a 16-bit pointer"),
    (0xFAA0CD, "(xhl+39)",  "low depth  = P[+0x27]"),
    (0xFAA0D3, "(xhl+17)",  "low base   = P[+0x11]"),
    (0xFAA0EF, "0x80",      "gate: voice_record[+0x25][+0x1A] & 0x80"),
    (0xFAA0FA, "0x80",      "sign: voice_record[+0x25][+0x1C] & 0x80 -> subtract"),
    (0xFAA110, "0x7F",      "low field clamped to 0..0x7F"),
    (0xFAA128, "(xde+41)",  "high depth = P[+0x29]"),
    (0xFAA12E, "(xde+16)",  "high base  = P[+0x10]"),
    (0xFAA14A, "0x100",     "gate: the SAME two bytes, bit 8 instead of bit 7"),
    (0xFAA155, "0x100",     "sign: bit 8"),
    (0xFAA171, "(xwa+0x74)", "high field also takes a SIGNED trim P[+0x74]"),
    (0xFAA181, "0x7F",      "high field clamped to 0..0x7F"),
    (0xFAA18C, "sll",       "high field shifted into the top byte"),
    (0xFAA198, "or",        "word = (high << 8) | low"),
    (0xFAA19A, "0xD764",    "stored to staging word 3 = register 0x00C0 + chan"),
]


def line_at(addr):
    """The CODE line whose address comment is exactly this address.

    ⚠ Comment lines are skipped deliberately.  Once this round wrote its citation
    addresses into a routine header, a header line reading `0xFAA0C8 P   0xFAA0D3 ...`
    matched the address regex and shadowed the instruction, and four of the fifteen
    citation checks below started failing on their own documentation.  A citation check
    that can be satisfied -- or broken -- by prose is not a citation check."""
    for i, ln, _r, a in walk():
        if a == addr and not ln.lstrip().startswith(";"):
            return ln
    return None


def section_reg00C0():
    print("\n=== 3b. REGISTER 0x00C0 + chan DECODES TO A FORMULA ===\n")
    print("  Voice_StageRegs_00C0_AB builds staging word 3 as a PAIR of 7-bit fields:")
    print("      low  = clamp(P[+0x11] +- P[+0x27], 0, 0x7F)")
    print("      high = clamp(P[+0x10] +- P[+0x29] + (int8)P[+0x74], 0, 0x7F)")
    print("      word = (high << 8) | low")
    print("  where P = voice_record[+0x23] and the +- is chosen by two bits of the object")
    print("  at voice_record[+0x25]: bit 7 of its +0x1A enables the LOW field's modulation")
    print("  and bit 7 of its +0x1C makes it subtract; bit 8 of the SAME TWO BYTES does the")
    print("  same for the HIGH field.  One 16-bit word, two fields, two enable/sign bit pairs.\n")
    for addr, want, what in REG00C0_CITES:
        ln = line_at(addr)
        ok = ln is not None and want.lower() in ln.split(";")[0].lower()
        check("0x%06X  %-46s [%s]" % (addr, what, want), ok)
    print("\n  ⚠ NOT ESTABLISHED: what register 0x00C0 + chan carries, what P is, or what")
    print("  the bit-7/bit-8 pair at (voice_record[+0x25])[+0x1A]/[+0x1C] selects.  What is")
    print("  established is the ARITHMETIC, and it is the same shape as the one the tree")
    print("  already documents for register 0x0500 in Voice_StageRegs_0500_08C0_AB: a byte")
    print("  pair, each half clamped to 0..0x7F, assembled with `sll 8 / or`.")


# Extra prose for individual staging producers, appended to the generated note.
DETAIL = {
    "Voice_StageRegs_00C0_AB": """
         ★ AND THIS ONE DECODES TO A FORMULA.  Staging word 3 is a PAIR of 7-bit fields:
             low  = clamp( P[+0x11] +- P[+0x27], 0, 0x7F )
             high = clamp( P[+0x10] +- P[+0x29] + (int8)P[+0x74], 0, 0x7F )
             word = (high << 8) | low
         where P = voice_record[+0x23].  The +- is chosen by TWO BIT PAIRS in one object:
         with Q = voice_record[+0x25], bit 7 of Q[+0x1A] enables the LOW field's
         modulation and bit 7 of Q[+0x1C] makes it subtract; bit 8 of the SAME TWO BYTES
         does the same for the HIGH field.
             0xFAA0C8 P   0xFAA0D3 low base   0xFAA0CD low depth  0xFAA0EF/0xFAA0FA bit 7
             0xFAA12E high base   0xFAA128 high depth  0xFAA14A/0xFAA155 bit 8
             0xFAA171 signed trim P[+0x74]   0xFAA110/0xFAA181 the two clamps
             0xFAA18C sll 8   0xFAA198 or   0xFAA19A the store
         Every one of those %d citations is checked AT THE CITED ADDRESS by
         `python3 notes/prom_c_understanding_round6.py --reg00c0` -- this tree has published
         a whole class of citations one byte past the instruction, and that check is the
         defence against it.
         The shape is the one Voice_StageRegs_0500_08C0_AB already documents for register
         0x0500: a byte pair, each half clamped to 0..0x7F, assembled with `sll 8 / or`.
         Unknown: what P is, what the bit-7/bit-8 pair selects, and what 0x00C0 carries.""",
    "Voice_StageRegs_00C0_CD": """
         The C/D-path twin of Voice_StageRegs_00C0_AB: same staging word, same pointer
         voice_record[+0x23], same 0x80/0x100 bit pair at voice_record[+0x25].
         ⚠ Its arithmetic was NOT decoded in this round -- only the A/B twin was (section
         3b).  It is NOT asserted to be the same formula; the two routines are 233 and 216
         bytes and no byte comparison was made.""",
}


# ---------------------------------------------------------------------------
# 8 -- THE SEVEN MICRO-DMA ACCESSORS, the only real header deficit in prom_c
# ---------------------------------------------------------------------------
# Section 7 measures prom_c's header deficit and finds 15 labels, not 308.  Seven of
# the 15 are these; the other eight are the interrupt trampolines at 0xFFF0A2 and
# BitMasks_OddBits, each already carrying a one-line Evidence: comment under a block
# banner that documents the whole group.  Padding those to three lines would be the
# mirror image of the round-3 lane that reported "+35 headers" for 35 deleted blank
# lines, so they are deliberately left alone and this section says so.
UDMA = [
    ("uDMA2_SetDest",   0xF99FF8, [(0xF99FFB, "CR_DMAD2"), (0xF9A001, "CR_DMAM2")]),
    ("uDMA2_SetSource", 0xF9A005, [(0xF9A008, "CR_DMAS2"), (0xF9A00E, "CR_DMAC2")]),
    ("uDMA3_SetSource", 0xF9A012, [(0xF9A015, "CR_DMAS3"), (0xF9A01B, "CR_DMAM3")]),
    ("uDMA3_SetDest",   0xF9A01F, [(0xF9A022, "CR_DMAD3"), (0xF9A028, "CR_DMAC3")]),
    ("uDMA2_GetCount",  0xF9A02C, [(0xF9A02C, "CR_DMAC2")]),
    ("uDMA3_GetCount",  0xF9A030, [(0xF9A030, "CR_DMAC3")]),
    ("uDMA3_GetDest",   0xF9A034, [(0xF9A034, "CR_DMAD3")]),
]

UDMA_SET_NOTE = """%s -- micro-DMA channel %s SETTER.  It has no `link`
         frame, so its arguments sit on the stack above the return address: (XSP+4) is a
         32-bit address and (XSP+8) the second argument, and the routine copies them into
         the CPU control registers %s.
         Evidence: the `ldc` operands at %s; the register numbers are the `.equ`s at the
         head of this group, each cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
         ⚠ CHANNELS 2 AND 3 PAIR THEIR REGISTERS THE OPPOSITE WAY ROUND, which is a
         property of the ROM and not a typo here: on channel 2 the DESTINATION setter also
         writes the MODE register and the SOURCE setter writes the COUNT; on channel 3 the
         SOURCE setter writes the mode and the DESTINATION setter writes the count.
         `python3 notes/prom_c_understanding_round6.py --udma` asserts that pairing from
         the listing, so if either routine is ever re-read it fails rather than drifting.
         Unknown: what either channel transfers.  Channel 3's count is read by
         Link_ServiceTask; nothing here says what channel 2 is for."""

UDMA_GET_NOTE = """%s -- micro-DMA channel %s GETTER.  It takes NO argument
         and has no frame: one `ldc` from %s and a `ret`, returning the value in the
         register the instruction names.
         Evidence: the `ldc` operand at %s; the register number is the `.equ` at the head
         of this group, cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp.
         Unknown: what the channel transfers."""


def section_udma():
    print("\n=== 8. THE SEVEN MICRO-DMA ACCESSORS ===\n")
    for name, addr, regs in UDMA:
        got = []
        for a, want in regs:
            ln = line_at(a)
            ok = ln is not None and want in ln
            got.append(ok)
            check("%-16s 0x%06X names %s" % (name, a, want), ok)
    # the asymmetry, re-derived rather than asserted in prose alone
    pair = {n: [r for _a, r in regs] for n, _addr, regs in UDMA}
    check("channel 2: SetDest writes the MODE register, SetSource the COUNT",
          pair["uDMA2_SetDest"] == ["CR_DMAD2", "CR_DMAM2"]
          and pair["uDMA2_SetSource"] == ["CR_DMAS2", "CR_DMAC2"])
    check("channel 3: SetSource writes the MODE register, SetDest the COUNT -- the "
          "OPPOSITE pairing",
          pair["uDMA3_SetSource"] == ["CR_DMAS3", "CR_DMAM3"]
          and pair["uDMA3_SetDest"] == ["CR_DMAD3", "CR_DMAC3"])
    print("\n  These seven are the only labels in prom_c that are NAMED, are real")
    print("  routines, and have no >=3-line header.  --headers writes one for each.")


EXTRA_HEADERS = {}
for _n, _addr, _regs in UDMA:
    _t = UDMA_SET_NOTE if "Set" in _n else UDMA_GET_NOTE
    EXTRA_HEADERS[_n] = _t % (
        _n, _n[4], " and ".join(r for _a, r in _regs),
        ", ".join("0x%06X" % a for a, _r in _regs))


def build_header_notes():
    """HEADER_NOTES plus the entries that are DERIVED rather than typed: the eleven
    staging producers (from struct_writes()) and the six dispatcher arms."""
    notes = dict(HEADER_NOTES)
    notes.update(EXTRA_HEADERS)
    writes = struct_writes()
    for old, (new, _want) in STAGERS.items():
        key = new if new in ADDR_OF_LABEL else old
        w = writes.get(key) or writes.get(old) or writes.get(new) or {}
        if not w:
            continue
        regs = ", ".join("word %d (register 0x%04X + chan)" % (wd, WORD2BLOCK[wd] * 0x40)
                         for wd in sorted(w))
        sites = ", ".join("0x%06X" % a for wd in sorted(w) for a in w[wd] if a)
        onereg = " / ".join("0x%04X" % (WORD2BLOCK[wd] * 0x40) for wd in sorted(w))
        callers = sorted({(r or "?").split("__")[0]
                          for _s, r in call_sites(ADDR_OF_LABEL[key])})
        notes[new] = (_STAGE_NOTE % (new, regs, sites, ", ".join(callers), onereg)
                      + (DETAIL.get(new, "") % len(REG00C0_CITES)
                         if "%d" in DETAIL.get(new, "") else DETAIL.get(new, "")))
    for new, (addr, reg, ev, setter) in ARMS.items():
        key = new if new in ADDR_OF_LABEL else LABEL_AT_ADDR.get(addr, new)
        sites = [s for s, _r in call_sites(addr)]
        notes[new] = _ARM_NOTE % (new, sites[0] if sites else 0, reg, ev, setter, reg)
    return notes


# ---------------------------------------------------------------------------
# --apply / --check-applied / --headers
# ---------------------------------------------------------------------------
def rename_token(text, old, new):
    r"""Rewrite `old` and every `old__local` derived from it.  `\bold\b` does NOT match
    inside `sub_FB7345__FB7350` -- `_` is a word character, so there is no boundary after
    the digits -- which would leave the branch targets pointing at a symbol that no longer
    exists and break the build.  The negative lookahead accepts `_` as a following
    character and so renames the locals too, while still refusing a longer name."""
    return re.sub(r'\b' + re.escape(old) + r'(?![0-9A-Za-z])', new, text)


def do_apply(check_only=False):
    text = open(SRC, encoding="utf-8").read()
    todo, done, bad = [], [], []
    for old, new, _ev in RENAMES:
        has_old = re.search(r'^%s:' % re.escape(old), text, re.M) is not None
        has_new = re.search(r'^%s:' % re.escape(new), text, re.M) is not None
        if has_new and not has_old:
            done.append((old, new))
        elif has_old and not has_new:
            todo.append((old, new))
        else:
            bad.append((old, new, has_old, has_new))
    for old, new, ho, hn in bad:
        print("  REFUSE %s -> %s: old present %s, new present %s" % (old, new, ho, hn))
    if bad:
        print("\nnothing written.")
        return 1
    for old, new in done:
        print("  already applied: %s -> %s" % (old, new))
    if check_only:
        print("\n%d applied, %d pending." % (len(done), len(todo)))
        return 0 if not todo else 2
    for old, new in todo:
        n_before = len(re.findall(r'\b' + re.escape(old) + r'(?![0-9A-Za-z])', text))
        text = rename_token(text, old, new)
        n_after = len(re.findall(r'\b' + re.escape(old) + r'(?![0-9A-Za-z])', text))
        print("  %-38s -> %-42s (%d occurrence(s), %d left)" % (old, new, n_before, n_after))
        if n_after:
            print("  REFUSE: occurrences survived the rewrite; nothing written.")
            return 1
    if todo:
        open(SRC, "w", encoding="utf-8").write(text)
        print("\nwrote %s: %d rename(s)." % (SRC, len(todo)))
    # ★ and the committed scripts that name these labels as literal strings
    moved = 0
    for rel in AFFECTED_SCRIPTS:
        p = os.path.join(ROOT, rel)
        t = open(p, encoding="utf-8").read()
        orig = t
        for old, new, _ev in RENAMES:
            t = rename_token(t, old, new)
        if t != orig:
            open(p, "w", encoding="utf-8").write(t)
            moved += 1
            print("  patched %s" % rel)
    if todo or moved:
        print("\nNOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


def do_headers():
    """Splice this round's prose into the comment block above each renamed label, and
    delete the auto-generated 'the name is an address' paragraph, which a named routine
    contradicts.  Idempotent: a block that already carries the round marker is skipped."""
    lines = open(SRC, encoding="utf-8").read().split("\n")
    notes = build_header_notes()
    written = skipped = missing = 0
    for new, prose in sorted(notes.items()):
        idx = None
        for i, ln in enumerate(lines):
            if ln == new + ":":
                idx = i
                break
        if idx is None:
            print("  MISSING label %s (run --apply first)" % new)
            missing += 1
            continue
        # walk up the comment block, tolerating one blank line
        j = idx - 1
        blanks = 0
        while j >= 0:
            if lines[j].startswith(";"):
                blanks = 0
            elif lines[j].strip() == "" and blanks == 0:
                blanks = 1
            else:
                break
            j -= 1
        top = j + 1
        block = lines[top:idx]
        # Idempotent BY REPLACEMENT: an existing round-6 paragraph is cut out and the
        # current text written in its place, so the prose can be corrected in a later
        # pass without the header growing a second copy.
        if any(MARK in b for b in block):
            k = next(i for i, b in enumerate(block) if MARK in b)
            tail = [b for b in block[k:] if re.match(r'^;\s*-{10,}\s*$', b)]
            block = block[:k] + tail
            skipped += 1
        block = [b for b in block if b not in BOILERPLATE]
        add = ["; " + MARK + " ------------------------------------------------------------"]
        for para in prose.split("\n"):
            add.append("; " + para.strip() if not para.startswith("         ")
                       else ";          " + para.strip())
        # keep the block's closing rule last if it has one
        if block and re.match(r'^;\s*-{10,}\s*$', block[-1]):
            block = block[:-1] + add + [block[-1]]
        else:
            block = block + add
        lines[top:idx] = block
        written += 1
    open(SRC, "w", encoding="utf-8").write("\n".join(lines))
    print("\n%d header(s) written (%d of them REPLACED an earlier round-6 paragraph), "
          "%d label(s) missing." % (written, skipped, missing))
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 1 if missing else 0


# ---------------------------------------------------------------------------
# 9 -- EVERY ADDRESS THIS ROUND WROTE INTO A HEADER, CHECKED AGAINST THE LISTING
# ---------------------------------------------------------------------------
# This tree has published ~20 call sites cited one byte past the instruction, and a
# whole class of tail-zone citations one or two bytes past it.  Neither the byte gate
# nor a reviewer reading prose can see that.  So: collect every 24-bit address inside
# a round-6 header paragraph and require it to be the address of a real listing line.
def section_cites():
    print("\n=== 9. EVERY ADDRESS IN THIS ROUND'S HEADERS, CHECKED AGAINST THE LISTING ===\n")
    # A listing line's address, OR a LABEL's address -- the bulk `.short` runs of the
    # curve tables carry no per-line address comment, so an object cited by its base
    # (EGEnv_BaseCurve_A at 0xFDE12B) is legitimate and would otherwise read as an error.
    known = {a for _i, ln, _r, a in walk()
             if a is not None and not ln.lstrip().startswith(";")}
    known |= set(ADDR_OF_LABEL.values())
    inblock = False
    cited = {}
    for i, ln, _r, _a in walk():
        if MARK in ln:
            inblock = True
            continue
        if not ln.startswith(";"):
            inblock = False
            continue
        if inblock:
            for m in re.findall(r'0x([0-9A-F]{6})\b', ln):
                v = int(m, 16)
                if 0xF80000 <= v <= 0xFFFFFF:
                    cited.setdefault(v, 0)
                    cited[v] += 1
    bad = sorted(a for a in cited if a not in known)
    print("  %d distinct ROM addresses cited in %d round-6 header paragraph(s)"
          % (len(cited), open(SRC, encoding="utf-8").read().count(MARK)))
    for a in bad:
        print("    ⚠ 0x%06X is NOT the address of any listing line" % a)
    check("every ROM address cited in a round-6 header is a listing-line address "
          "(the defence against this tree's cited-one-byte-past-the-instruction class)",
          not bad)


# ---------------------------------------------------------------------------
def main():
    args = sys.argv[1:]
    if "--apply" in args:
        return do_apply()
    if "--check-applied" in args:
        return do_apply(check_only=True)
    if "--headers" in args:
        return do_headers()
    want = [a for a in args if a.startswith("--")]
    run = {
        "--framed": section_framed,
        "--blocks": section_blocks,
        "--staging": section_staging,
        "--reg00c0": section_reg00C0,
        "--dispatch": section_dispatch,
        "--packer": section_packer,
        "--names": section_names,
        "--gaps": section_gaps,
        "--udma": section_udma,
        "--cites": section_cites,
    }
    if want and want != ["--selftest"]:
        for w in want:
            if w in run:
                run[w]()
    else:
        for fn in (section_framed, section_blocks, section_staging, section_reg00C0,
                   section_dispatch,
                   section_packer, section_names, section_gaps, section_udma,
                   section_cites):
            fn()
    if "--selftest" in args or not want:
        print("\n%d ok, FAILURES: %d" % (OK[0], FAIL[0]))
        return 1 if FAIL[0] else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
