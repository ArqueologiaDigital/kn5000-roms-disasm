#!/usr/bin/env python3
"""prom_c ROUND 8 (wave-7 round 3) -- THE GLOBAL SETUP RECORD, and an audit of the
   instrument that grades this tree's documentation.

QUESTION IT ANSWERS
    "Round 7 left prom_c with 429 sub_XXXXXX in six buckets and said bucket S4 was
     waiting on one question.  Is there a mechanism that reaches a block of them at
     once -- and when the round is over, is prom_c's documentation debt what the
     instrument says it is?"

    Two answers, and the second one is uncomfortable:

    1. YES.  `sub_FB0338` is the handler MidiIn_ParseRingAndDispatch reaches for
       status nibble 0xF0, and its 27 arms are the WRITERS OF ONE 37-BYTE RECORD --
       the instrument's part-less settings, at RAM 0x0014FE..0x001522, ending exactly
       where the 33 part records begin.  Naming the record named twelve of its
       writers from what they contain and what reads them, and let six more be
       REFUSED with a reason that is a census result rather than a shrug.
       (--dispatch, --record)

    2. THE GRADER OVER-COUNTS prom_c's CONTENT NAMES BY 168.  notes/wave7_documentation
       _metrics.py excludes `<parent>__<hexaddr>` internal branch targets from the
       percentages, on the stated ground that a jump destination inside a routine is
       not an object awaiting a name.  prom_c spells 168 of those targets
       `<parent>__<word>` -- Kernel_InitRam__ready_queues, MAIN__bit3 -- and the
       INTERNAL regex requires 4-6 HEX characters after the `__`, so every one of them
       is graded CONTENT instead.  prom_a has 124 more.  (--grader)

★ WHAT THE RECORD BUYS, and why it is a lever and not just a table
    Before this round the twelve setters were twelve unrelated `link XIZ,0 / store /
    ret` stubs, each with a header that ended "what the routine is FOR: unknown".  The
    record turns each one into a field, and a field has TWO namable ends: the message
    code that writes it and the engine routine that reads it.  Nine fields have a
    located reader and are named from it; six have NONE, and this script's --record
    proves the absence over both spellings the record is reached by (an absolute
    store, and an offset from the `lda XIX,0x14fe` base) rather than asserting it.
    A field with a writer and no reader gets no name here.  That is the whole
    difference between this pass and a naming spree.

WHAT THE ROUND SHIPPED
    12 renames, sub_XXXXXX -> content, each with a rewritten header and an Evidence
    line: GlobalSetup_Dispatch, P7Mixer_SetGainIndex1/2, GlobalTune_StoreFineTune,
    GlobalTune_StoreTranspose, GlobalScale_StoreMode, GlobalScale_StorePitchClass
    Detune, GlobalScale_SelectGlobalOrPerTone, Voice_RestagePitchReg0400_ForList,
    GlobalTune_SetFineTune_AndRestageAll, Dev10C_SetReg0201_FromNibblePair,
    VoiceDefaults_StoreFromPackedByte.
    6 REFUSALS with derived reasons, in the source where a reader will hit them
    (sub_FADA7C, sub_FADB0F, sub_FADBEE, sub_FADBFC, sub_FADC3E, sub_FB0285).
    1 new block comment: the record itself, 66 lines, every row re-derived by --record.
    prom_c content 809 -> 821, sub_XXXXXX 429 -> 417, LOWER 46.5%% -> 47.2%%,
    UPPER 75.3%% -> 76.0%% (notes/wave7_documentation_metrics.py).
    ⚠ The `headers` and `evidence` columns did NOT move, and that is correct: all 18
    blocks this round rewrote ALREADY had three comment lines and an Evidence line,
    because round 7 gave every sub_XXXXXX one.  The instrument counts the PRESENCE of
    a header, not what it says, so a pass that replaces "what the routine is FOR:
    unknown" with a decoded field map is invisible to it.  Stated because the mirror
    of this -- counting removed blank lines as new headers -- is a mistake this tree
    has already made and published.

★ AND THE NAMES PROPAGATED, which is the point round 7 made and this round tested.
    Re-running round 7's own census over the tree this round leaves
    (`python3 notes/prom_c_finish_round7.py --census`) moves its buckets:

        objects      929 -> 917     (the twelve are content now)
        S6 opaque    258 -> 242     sixteen routines left the "every caller is a
                                    sub_XXXXXX" bucket without being touched
        S4           118 -> 122     because their callers acquired a content name

    Round 7 predicted exactly this -- "naming S4 members is how S6 gets reached at
    all; attacking S6 head-on is attacking the middle of a chain" -- and the twelve
    names cost nothing to S6 and retired sixteen of it as a side effect.

⚠ FRAMED -> CONTENT PROMOTIONS: ZERO, again, and --refusals says why for each
    candidate rather than leaving it as a miss.  The three that would have been
    honest are blocked on files this lane does not own.

WHAT THIS DOES **NOT** ESTABLISH
  * What CPU 1 calls the 27 codes.  The packets arrive over link channel 0, so the
    panel's names live in prom_a; --dispatch reports the negative search.
  * What any of the four bit-fields VoiceDefaults_StoreFromPackedByte unpacks IS.
    The offsets, the shifts and the readers are measured; the musical meaning is not.
  * That a "NO READER FOUND" field is dead.  The census is over literal spellings and
    is blind to a read through a register it does not track.

RUN
    python3 notes/prom_c_inventory_round8.py              # every section
    python3 notes/prom_c_inventory_round8.py --dispatch   # 1: the 27 arms of 0xFB0338
    python3 notes/prom_c_inventory_round8.py --record     # 2: the record, writers+readers
    python3 notes/prom_c_inventory_round8.py --claims     # 3: every citation this round made
    python3 notes/prom_c_inventory_round8.py --grader     # 4: the 168-label grader defect
    python3 notes/prom_c_inventory_round8.py --refusals   # 5: framed->content, refused
    python3 notes/prom_c_inventory_round8.py --depth      # 6: what header depth really is
    python3 notes/prom_c_inventory_round8.py --selftest   # all of it, exit 1 on a failure

★ ROUND 9 (2026-08-30) APPENDED THREE MORE SECTIONS to this file; the round-8 text
  above is unchanged and its 59 checks still run first.

    python3 notes/prom_c_inventory_round8.py --pool8      # 7: the eight-slot note pool
    python3 notes/prom_c_inventory_round8.py --framed     # 8: what `framed` really is
    python3 notes/prom_c_inventory_round8.py --refused9   # 9: round 9's refusals

  ROUND 9's ANSWER, in one line: round 8 shipped ZERO framed->content promotions and
  said the honest count might be zero.  It was six -- the note pool's five tables and
  its 68-byte device image, every one named from what READS it -- and after them
  prom_c's framed column has a PROMOTABLE REMAINDER OF SEVEN LABELS, all seven
  already carrying a refusal a committed round derived (--framed).  That is the
  finished state the brief asked for: every framed object in prom_c is now either
  named, inside a region a findings doc declares framed by decision, carrying a
  number that IS the meaning, or individually refused with a reason.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                    r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                    r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')
ADDRC = re.compile(r';\s*([0-9A-F]{6})\s+(.*)$')

FAILS = []


def check(cond, msg):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAILS.append(msg)
    return cond


_C = {}


def load():
    """The source, and every line that carries an `; AAAAAA <text>` address comment."""
    if _C:
        return _C
    src = open(SRC).read().split("\n")
    dis = {}
    order = []
    for ln in src:
        m = ADDRC.search(ln)
        if m:
            a = int(m.group(1), 16)
            dis[a] = m.group(2).strip()
            order.append(a)
    _C.update(src=src, dis=dis, order=sorted(dis))
    return _C


# ==================================================== 1. THE 27 DISPATCH ARMS
DISPATCH = 0xFB0338
DISPATCH_END = 0xFB0504


def arms():
    """Every `cp BC,imm / jrl Z,target` pair inside GlobalSetup_Dispatch, and the
    routine each arm calls.  Re-derived from the listing on every run: if an arm
    moves, this moves with it."""
    d = load()["dis"]
    body = [(a, d[a]) for a in load()["order"] if DISPATCH <= a < DISPATCH_END]
    out = []
    for i, (a, t) in enumerate(body):
        m = re.match(r'cp BC,0x([0-9a-f]+)$', t)
        if not m or i + 1 >= len(body):
            continue
        m2 = re.match(r'jrl? Z,0x([0-9a-f]+)$', body[i + 1][1])
        if not m2:
            continue
        code, dest = int(m.group(1), 16), int(m2.group(1), 16)
        callee = arg = None
        for a2, t2 in body:
            if a2 < dest:
                continue
            mp = re.match(r'push 0x([0-9a-f]+)$', t2)
            if mp and arg is None and callee is None:
                arg = int(mp.group(1), 16)
            mc = re.match(r'cal[lr] .*0x([0-9a-f]{6})', t2)
            if mc:
                callee = int(mc.group(1), 16)
                break
        out.append((code, a, dest, callee, arg))
    return out


def show_dispatch():
    a = arms()
    print("=== 1. GlobalSetup_Dispatch (0x%06X) -- the status-0xF0 arm, %d codes ===\n"
          % (DISPATCH, len(a)))
    names = labels_by_addr()
    for code, cp, dest, callee, arg in a:
        print("  code 0x%02X  cp@%06X -> %06X  %-38s%s"
              % (code, cp, dest, names.get(callee, "0x%06X" % (callee or 0)),
                 "" if arg is None else "   extra arg 0x%04X" % arg))
    d = load()["dis"]
    body = [d[x] for x in load()["order"] if DISPATCH <= x < DISPATCH_END]
    print("\n  reads of (XIX+0x01), the PART index every other status uses: %d"
          % sum(1 for t in body if "XIX+0x01" in t))
    print("  `mul BC,0x012c`, the part-record stride, anywhere in the body: %d"
          % sum(1 for t in body if "0x012c" in t.lower()))
    print("  -> the record it writes is GLOBAL, not per-part.")
    return a


def labels_by_addr():
    """address -> label name.  From the `; AAAAAA` comment on the line below the label
    where there is one, and from the linked ELF's symbol table otherwise -- a `.byte`
    data label such as PresetBank_Paris_Caffe carries no address comment at all, and
    leaving it out is how a census silently loses a third of its population."""
    if "lba" in _C:
        return _C["lba"]
    src = load()["src"]
    out = {}
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if not m:
            continue
        for j in range(i + 1, min(i + 4, len(src))):
            mm = ADDRC.search(src[j])
            if mm:
                out[int(mm.group(1), 16)] = m.group(1)
                break
    import subprocess
    nm = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
    elf = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_c.llvm.elf")
    if os.path.exists(nm) and os.path.exists(elf):
        for ln in subprocess.run([nm, elf], capture_output=True, text=True).stdout.split("\n"):
            p = ln.split()
            if len(p) == 3 and p[1] in "tTdDbBrR":
                out.setdefault(int(p[0], 16), p[2])
    _C["lba"] = out
    return out


# ==================================================== 2. THE RECORD
RECORD_BASE = 0x14FE
RECORD_END = 0x1523          # the part records begin here
# The offsets the record is reached at through a REGISTER rather than an absolute
# operand.  Pinned so the two prose copies of this list -- the block comment above
# sub_FADA7C and sub_FADBEE's refusal -- cannot drift away from the census.
REG_OFFS = (0x00, 0x01, 0x0D, 0x1B, 0x1D, 0x1E, 0x1F, 0x21, 0x23)

ROWS = [
    # offset, width, what the field is, or None where this round refused to say
    (0x00, 1, None),
    (0x01, 2, "the flag word"),
    (0x03, 1, "mixer gain index 1"),
    (0x04, 1, "mixer gain index 2"),
    (0x05, 2, "master fine tune, 1/256 semitone"),
    (0x07, 2, "master transpose, semitones * 256"),
    (0x09, 1, None),
    (0x0A, 1, None),
    (0x0B, 1, None),
    (0x0C, 1, "global scale MODE selector"),
    (0x0D, 12, "the user scale: one signed detune per pitch class"),
    (0x1B, 2, None),
    (0x1D, 1, "voice-rebuild gate"),
    (0x1E, 1, "voice-rebuild countdown"),
    (0x1F, 2, "voice default copied to four voice fields"),
    (0x21, 2, "voice default"),
    (0x23, 2, "voice default"),
]


def record_touches():
    """Every access to the record, by both spellings:
         (a) an absolute operand `(0xNNNN)` with 0x14FE <= NNNN < 0x1523;
         (b) an offset from a base register loaded `lda Xr,0x14fe`.
    Returns {offset: (writers, readers)} as lists of (address, text)."""
    d, order = load()["dis"], load()["order"]
    acc = collections.defaultdict(lambda: ([], []))
    for a in order:
        t = d[a]
        for h in re.findall(r'\(0x([0-9a-fA-F]{4})\)', t):
            v = int(h, 16)
            if RECORD_BASE <= v < RECORD_END:
                w = re.match(r'(ld|or|and|set|res|xor|inc|dec)\s+\(0x', t) is not None
                acc[v - RECORD_BASE][0 if w else 1].append((a, t))
    idx = {a: i for i, a in enumerate(order)}
    for a in order:
        m = re.search(r'lda\s+X?(\w+),0x14fe', d[a], re.I)
        if not m:
            continue
        reg = m.group(1)
        for j in range(idx[a] + 1, min(idx[a] + 140, len(order))):
            a2, t2 = order[j], d[order[j]]
            if re.match(r'ret\b', t2):
                break
            for mm in re.finditer(r'\(X?%s\+0x([0-9a-f]{2})\)' % reg, t2, re.I):
                off = int(mm.group(1), 16)
                w = re.match(r'(ld|or|and|set|res|xor|inc|dec)\s+\(', t2) is not None
                acc[off][0 if w else 1].append((a2, t2))
            # the ZERO-offset spelling, `(XIX)`, is offset +0x00 and a census that
            # only matched `+0xNN` would report the first field of the record as
            # unread while Toggle14FE_AndDispatch is reading it
            if re.search(r'\(X?%s\)' % reg, t2, re.I):
                w = re.match(r'(ld|or|and|set|res|xor|inc|dec)\s+\(X', t2) is not None
                acc[0][0 if w else 1].append((a2, t2))
    # (c) the DISPLACEMENT spelling `(Xr+0x14fe)`, where the register carries the
    # OFFSET and 0x14FE is the displacement.  Only the scale table is reached this
    # way, and both sites add 13 first -- asserted rather than assumed.
    for a in order:
        t = d[a]
        if not re.search(r'\(X\w+\+0x14fe\)', t):
            continue
        add13 = False
        for j in range(max(0, idx[a] - 8), idx[a]):
            if re.match(r'add BC,(13|0x000d)$', d[order[j]]):
                add13 = True
        if not add13:
            continue
        w = re.match(r'ld\s+\(X', t) is not None
        acc[0x0D][0 if w else 1].append((a, t))
    return acc


def show_record():
    acc = record_touches()
    names = labels_by_addr()
    encl = enclosing()
    print("=== 2. THE GLOBAL SETUP RECORD -- RAM 0x%04X..0x%04X, %d bytes ===\n"
          % (RECORD_BASE, RECORD_END - 1, RECORD_END - RECORD_BASE))
    noread = []
    for off, w, what in ROWS:
        ws, rs = acc.get(off, ([], []))
        wn = sorted(set(encl.get(a, "?") for a, _t in ws))
        rn = sorted(set(encl.get(a, "?") for a, _t in rs))
        if not rn:
            noread.append(off)
        print("  +%02X 0x%04X %2dB  %-46s" % (off, RECORD_BASE + off, w,
                                              (what or "-- role NOT claimed")[:46]))
        print("               writers: %s" % (", ".join(wn) or "none"))
        print("               readers: %s" % (", ".join(rn) or "** NO READER FOUND **"))
    print("\n  offsets reached through a REGISTER (an `lda Xr,0x14fe` base, or the")
    print("  `(Xr+0x14fe)` displacement form): %s" % " ".join("+0x%02X" % o for o in REG_OFFS))
    print("  fields with a writer and NO located reader: %s"
          % " ".join("+0x%02X" % o for o in noread))
    print("\n  ⚠ 'NO READER FOUND' is a census over literal spellings.  A read through a")
    print("    register this scan does not track would be invisible, so it says")
    print("    'not found', never 'dead'.")
    return acc, noread


def enclosing():
    """address -> the name of the top-level label the instruction sits under."""
    src = load()["src"]
    out, cur = {}, None
    for ln in src:
        m = LABEL.match(ln)
        if m and not INTERNAL.match(m.group(1)):
            cur = m.group(1)
        mm = ADDRC.search(ln)
        if mm:
            out[int(mm.group(1), 16)] = cur
    return out


# ==================================================== 3. THE CITATION AUDIT
# Every address this round wrote into a header, with the instruction it claims is
# there.  The tree's signature error is a citation one or two bytes past the opcode,
# so this asserts the TEXT and not merely that something decodes.
CLAIMS = [
    (0xFB0678, "cp BC,0x00f0"), (0xFB09E6, "call 0xfb0338"), (0xFB0340, "ld C,(XIX+0x02)"),
    (0xFB0345, "cp BC,0x0009"), (0xFB03FB, "cp BC,0x00b2"), (0xFB0479, "push 0x0000"),
    (0xFB04DD, "push 0x000b"), (0xFB04E0, "calr"),
    (0xFADAB8, "ld (0x1501),C"), (0xFADABC, "push 0x007f"), (0xFADAC2, "call 0xfa2dcd"),
    (0xFB0413, "calr"), (0xFADAD1, "ld (0x1502),C"), (0xFADAD8, "ld C,(0x1501)"),
    (0xFADADF, "call 0xfa2dcd"), (0xFB041D, "calr"),
    (0xFADAEB, "ld C,(XIZ+0x08)"), (0xFADAF5, "ld (0x1503),BC"),
    (0xFA8356, "ld BC,(0x1503)"), (0xFA83DB, "ld BC,(0x1503)"),
    (0xFADB00, "ld BC,(XIZ+0x08)"), (0xFADB08, "ld (0x1505),BC"),
    (0xFA7F4C, "ld WA,(0x1505)"), (0xFA7F3A, "ld A,(XIX+0x05)"), (0xFA7F48, "add HL,0x0080"),
    (0xFA7F5A, "ld C,(XHL+0x15)"), (0xFC36FD, "ld BC,(0x1505)"),
    (0xFADB74, "ld C,(XIZ+0x08)"), (0xFADB77, "ld (0x150a),C"), (0xFA7F9B, "ld C,(0x150a)"),
    (0xFA7F81, "ld BC,(0x14ff)"), (0xFA7F8A, "jr Z,0xfa7fe0"),
    (0xFA7FA1, "cp BC,0x0040"), (0xFA8006, "calr"), (0xFA7FA7, "cp BC,0x0041"),
    (0xFA7FAE, "cp BC,0x0042"), (0xFA7FB5, "cp BC,0x0080"), (0xFA7FB9, "jr Z,0xfa7fbb"),
    (0xFA7FFE, "cp BC,0x0080"),
    (0xFADC24, "ld H,(XIZ+0x0a)"), (0xFADC35, "ld (XBC+0x14fe),H"),
    (0xFA7FBD, "ld C,(XIX+0x05)"), (0xFA7FC5, "div C,0x0c"), (0xFA7FC8, "ld C,B"),
    (0xFA7FD2, "ld A,(XBC+0x14fe)"), (0xFA7FD9, "add WA,WA"),
    (0xFADC55, "cp (XIZ+0x08),0x00"), (0xFADC5D, "or (XIX+0x01),0x0200"),
    (0xFADC66, "and (XIX+0x01),0xfdff"), (0xFADC51, "lda XIX,0x14fe"),
    (0xFA7FE5, "ld H,(XBC+0x13)"), (0xFA8064, "add XBC,0x00fdf2c3"),
    (0xFADCD0, "inc 5,XIX"), (0xFADCD4, "cp H,0x40"), (0xFADCCA, "ld DE,0x3bcf"),
    (0xFADCD9, "ld C,0x44"), (0xFADD03, "call 0xfa8347"), (0xFADD0A, "call 0xfa83cc"),
    (0xFADD1A, "calr"),
    (0xFB0275, "calr"), (0xFB0278, "call 0xfb3d09"), (0xFB027D, "calr"),
    (0xFB0270, "push 0x00"), (0xFB027C, "push XIY"), (0xFB0427, "calr"),
    (0xFADC76, "ld D,(XIZ+0x08)"), (0xFADC79, "ld (0x1509),D"), (0xFADCB0, "and BC,0x0f9f"),
    (0xFADCB4, "or BC,IX"), (0xFADCB6, "or BC,HL"), (0xFADCB9, "calr"), (0xFB04FC, "calr"),
    (0xFADB84, "lda XIX,0x14fe"), (0xFADB94, "ld (XIX+0x1d),0x03"),
    (0xFADBA2, "ld (XIX+0x1e),0x01"), (0xFADBBB, "ld (XIX+0x1f),BC"),
    (0xFADBC7, "ld (XIX+0x21),0x8000"), (0xFADBE6, "ld (XIX+0x23),WA"),
    (0xFB3FAA, "ld BC,(0x151d)"), (0xFB3FF1, "ld BC,(0x151d)"), (0xFB3FFA, "ld BC,(0x151d)"),
    (0xFB4027, "ld BC,(0x151d)"), (0xFAC2BD, "ld BC,(0x151d)"), (0xFAC314, "ld BC,(0x151f)"),
    (0xFAC31B, "ld BC,(0x151f)"), (0xFAC322, "ld BC,(0x1521)"),
    (0xFAC35A, "ld C,(XIX+0x1d)"), (0xFAC364, "dec 1,(XIX+0x1e)"), (0xFB044F, "calr"),
    (0xFADA81, "lda XIX,0x14fe"), (0xFADA85, "cp (XIZ+0x08),0x01"),
    (0xFADA8D, "or (XIX+0x01),0x0001"), (0xFADA99, "and (XIX+0x01),0xfffe"),
    (0xFB0409, "calr"), (0xFADB15, "lda XIX,0x14fe"), (0xFADB1F, "extz XIX"),
    (0xFADB2E, "set 0x0b,BC"), (0xFADB38, "extz XIX"), (0xFADB51, "cp BC,0x0014"),
    (0xFADB66, "ld (XIX+0x1b),0x0000"), (0xFB043B, "calr"),
    (0xFADBF2, "ld C,(XIZ+0x08)"), (0xFADBF5, "ld (0x1507),C"), (0xFB0459, "calr"),
    (0xFADC05, "cp (XIZ+0x08),0x00"), (0xFADC0D, "or (XIX+0x01),0x0002"),
    (0xFADC16, "and (XIX+0x01),0xfffd"), (0xFB0469, "calr"),
    (0xFADC42, "ld C,(XIZ+0x08)"), (0xFADC45, "ld (0x1508),C"), (0xFB04EA, "calr"),
    (0xFB028E, "calr"), (0xFA72F0, "ld HL,(0x14ff)"), (0xFAA4DB, "ld BC,(0x14ff)"),
    (0xFAD700, "ld BC,(0x14ff)"), (0xFAD797, "ld BC,(0x14ff)"),
    (0xFA8233, "ld BC,(0x14ff)"), (0xFA82F0, "ld BC,(0x14ff)"),
    (0xFB0518, "or (0x14ff),0x0004"), (0xFB0510, "and (0x14ff),0xfffb"),
    (0xFB05E0, "ld (0x14fe),0x00"), (0xFB05F1, "ld C,(XIX)"), (0xFB6DA7, "ld (0x1509),0x11"),
]


def show_claims():
    d = load()["dis"]
    bad = [(a, e, d.get(a)) for a, e in CLAIMS if e.lower() not in (d.get(a) or "").lower()]
    print("=== 3. EVERY ADDRESS THIS ROUND CITED, checked against the listing ===\n")
    print("  %d citations, %d wrong" % (len(CLAIMS), len(bad)))
    for a, e, t in bad:
        print("    0x%06X  claimed %-24s  is %s" % (a, e, t))
    print("\n  ⚠ ONE citation this round makes is NOT in this table and cannot be:")
    print("    0xF98CA4, MAIN's `lda XBC,0x00E2EB`.  MAIN was converted in an older")
    print("    style that carries no per-instruction address comments, so there is no")
    print("    listing line to match.  It is fixed instead by the RELATIVE form on the")
    print("    line above it, `calr (0xF98CB9 - 0xF98CA4)`, whose second operand is the")
    print("    address of the instruction that follows -- checked below.")
    return bad


def check_f98ca4():
    src = load()["src"]
    i = next((k for k, l in enumerate(src) if "calr\t(0xF98CB9 - 0xF98CA4)" in l), None)
    ok = i is not None and "0x00E2EB" in src[i + 1]
    return ok


# ==================================================== 4. THE GRADER
def grade_labels(path):
    names = [LABEL.match(l).group(1) for l in open(path) if LABEL.match(l)]
    out = collections.Counter()
    dd = []
    for n in names:
        if INTERNAL.match(n):
            g = "internal"
        elif UNNAMED.match(n):
            g = "sub"
        elif FRAMED.match(n):
            g = "framed"
        else:
            g = "content"
        out[g] += 1
        if "__" in n and not INTERNAL.match(n):
            dd.append((n, g))
    return out, dd


def show_grader():
    print("=== 4. THE GRADER OVER-COUNTS CONTENT NAMES ===\n")
    print("  notes/wave7_documentation_metrics.py drops `<parent>__<hexaddr>` branch")
    print("  targets from BOTH sides of the percentage, because a jump destination")
    print("  inside a routine is not an object awaiting a name.  Its INTERNAL regex")
    print("  requires 4-6 HEX characters after the `__`.  These labels obey the same")
    print("  convention with a WORD after the `__`, so they are graded CONTENT:\n")
    tot = 0
    for tag in ("a", "b", "c", "d"):
        p = os.path.join(ROOT, "prom_%s" % tag, "wsa1_prom_%s.s" % tag)
        g, dd = grade_labels(p)
        n = sum(1 for _x, gg in dd if gg == "content")
        tot += n
        print("  prom_%s  %4d such labels, %4d of them graded content   e.g. %s"
              % (tag, len(dd), n, ", ".join(x for x, _ in dd[:2]) or "--"))
    print("\n  So the tree's content column is %d labels high, all of it in prom_a and"
          % tot)
    print("  prom_c.  Corrected, prom_c reads:")
    g, dd = grade_labels(SRC)
    n = sum(1 for _x, gg in dd if gg == "content")
    c, f, u = g["content"] - n, g["framed"], g["sub"]
    t = c + f + u
    print("    content %d  framed %d  sub_XXXXXX %d   LOWER %.1f%%  UPPER %.1f%%"
          % (c, f, u, 100.0 * c / t, 100.0 * (c + f) / t))
    print("    (as printed: content %d, LOWER %.1f%%)"
          % (g["content"], 100.0 * g["content"] / (g["content"] + f + u)))
    print("\n  ⚠ NOT FIXED HERE.  wave7_documentation_metrics.py is the instrument every")
    print("  lane in this round reports against; moving its denominator mid-round would")
    print("  make four lanes' before/after figures incomparable.  Reported, with the")
    print("  one-character fix stated: the INTERNAL regex needs `[0-9A-Za-z_]` where it")
    print("  now has `[0-9A-Fa-f]`.")
    print("\n  AND IT UNDER-COUNTS IN THE OTHER DIRECTION.  A framed label whose suffix")
    print("  is not the object's own address is carrying a MEANING, not a position:")
    sus = suffix_not_own_address()
    print("    prom_c has %d of them; %d are a device register, a MIDI controller, a"
          % (len(sus), len(sus) - 1))
    print("    record offset or a numeric bound.  The one that is neither:")
    rom = open(ROM, "rb").read()
    for n, tok, a in sus:
        if not re.fullmatch(r'[0-9A-Fa-f]+', tok) or tok.upper() != tok.lower().upper():
            pass
    print("      PresetBank_Paris_Caffe (0xF85840) -- `Caffe` is five HEX LETTERS, and")
    print("      the ROM string it came from, 'Paris Caffe', is at 0x%06X, four bytes"
          % (BASE + rom.find(b"Paris Caffe")))
    print("      into the record.  Same for PresetBank_Brass_1995 at 0x%06X."
          % (BASE + rom.find(b"Brass 1995")))
    return tot, sus


def suffix_not_own_address():
    """Framed labels whose distinguishing suffix is NOT this object's own address."""
    addr = {}
    for a, n in sorted(labels_by_addr().items()):
        addr.setdefault(n, a)
    out = []
    for n in sorted(addr):
        if INTERNAL.match(n) or UNNAMED.match(n) or not FRAMED.match(n):
            continue
        tok = n.rsplit("_", 1)[-1]
        try:
            v = int(tok, 16)
        except ValueError:
            continue
        if v == addr[n] or re.fullmatch(r'[0-9]{1,4}', tok):
            continue
        out.append((n, tok, addr[n]))
    return out


# ==================================================== 5. REFUSALS
REFUSED_PROMOTIONS = [
    ("unexplained_FCC5BE", 0xFCC5BE,
     "SPLIT IT, and the split is proven: ROM 0xFCC5BE..0xFCC5C1 are the LAST FOUR "
     "BYTES of the boot RAM image (0xFCB4EA + 0x10D8 - 1 = 0xFCC5C1) and land on RAM "
     "0x00F3B3..0x00F3B6, the P7 mixer's requested and last-sent gain pairs; "
     "0xFCC5C2..0xFCC5C8 are five constants read in place.  Two objects, two names. "
     "NOT DONE: the label is load-bearing in notes/gen_prom_c_tables.py:378, which "
     "EMITS it, and in four FINDINGS docs.  Renaming it here without those would put "
     "the emitter and the source out of step -- a lane that owns them should do it."),
    ("Dev10C_StageRegs_0800_0840_FAB818", 0xFAB818,
     "REFUSED.  The address suffix distinguishes three producers of the SAME word "
     "pair (0x00D78A/0x00D78C).  Promoting any of them means saying what its two "
     "values MEAN, which the round-2 header explicitly declares unknown and which "
     "nothing this round measured."),
    ("Clamp_ToRange_LowByte_FBD88E", 0xFBD88E,
     "REFUSED, and correctly framed already.  The suffix records that this is a "
     "SEPARATELY COMPILED copy of Clamp_ToRange_LowByte, 42 bytes against 34 with 36 "
     "of the first 42 differing.  Dropping it would claim a twin that the byte diff "
     "denies."),
    ("PresetBank_Paris_Caffe", 0xF85840,
     "NOT A PROMOTION AT ALL -- a grader artefact.  The name is already content; "
     "`Caffe` is a word from the ROM string, and the grader reads it as five hex "
     "digits.  Renaming it to satisfy the metric would make the tree worse."),
    ("Sat16_0_to_7FFF / Clamp_36_to_120 / MidiCtrl_CC07 (+27 more)", None,
     "NOT A PROMOTION.  --grader lists 30 prom_c framed labels whose suffix is a "
     "device register, a controller number, a record offset or a bound.  For those "
     "THE NUMBER IS THE MEANING and a word in its place would say less."),
]


def show_refusals():
    print("=== 5. FRAMED -> CONTENT: every candidate, and why it was refused ===\n")
    print("  promotions shipped this round: 0\n")
    for n, a, why in REFUSED_PROMOTIONS:
        print("  %s%s" % (n, "  (0x%06X)" % a if a else ""))
        for line in re.findall(r'.{1,74}(?:\s|$)', why):
            print("      %s" % line.rstrip())
        print()


# ==================================================== 6. DEPTH
def depth():
    """Per grade: how many labels carry a >=3-line comment block, using the metric
    script's own rule (one blank line tolerated)."""
    src = load()["src"]
    run = blanks = 0
    ev = False
    out = collections.defaultdict(lambda: [0, 0, 0])
    noheader = collections.defaultdict(list)
    for ln in src:
        if ln.startswith(";"):
            run += 1
            blanks = 0
            if "Evidence:" in ln:
                ev = True
            continue
        if ln.strip() == "" and run:
            blanks += 1
            if blanks > 1:
                run, ev, blanks = 0, False, 0
            continue
        m = LABEL.match(ln)
        if m:
            n = m.group(1)
            if INTERNAL.match(n) or "__" in n:
                g = "internal"
            elif UNNAMED.match(n):
                g = "sub"
            elif FRAMED.match(n):
                g = "framed"
            else:
                g = "content"
            out[g][0] += 1
            if run >= 3:
                out[g][1] += 1
            else:
                noheader[g].append(n)
            if ev:
                out[g][2] += 1
        run, ev, blanks = 0, False, 0
    return out, noheader


def show_depth():
    out, noheader = depth()
    print("=== 6. HEADER DEPTH -- what the brief for this round got wrong ===\n")
    print("  The brief said prom_c has '1,096 headers and 866 Evidence: lines for 6,421")
    print("  labels -- most named routines are a name and nothing else'.  6,421 counts")
    print("  every branch target in the image.  Per grade, with `<parent>__*` treated as")
    print("  internal throughout:\n")
    print("  %-9s %7s %8s %9s" % ("grade", "labels", "header", "evidence"))
    for g in ("content", "framed", "sub", "internal"):
        t, h, e = out[g]
        print("  %-9s %7d %8d %9d" % (g, t, h, e))
    nh = noheader["content"]
    pb = [n for n in nh if n.startswith("PresetBank")]
    print("\n  content labels with NO header: %d, of which %d are PresetBank_* records"
          % (len(nh), len(pb)))
    print("  the rest: %s" % ", ".join(sorted(set(nh) - set(pb))))
    print("\n  So every sub_XXXXXX in prom_c already carries a header AND an Evidence")
    print("  line (round 7's doing), and the only real objects without one are the")
    print("  two-instruction interrupt-vector stubs, which carry an Evidence line each")
    print("  anyway.  prom_c's remaining debt is MEANING, not prose volume, and a lane")
    print("  told to 'add headers' here would be padding.")
    return out, nh


# ==================================================== SHIPPED
SHIPPED = {
    "GlobalSetup_Dispatch": 0xFB0338,
    "P7Mixer_SetGainIndex1": 0xFADAB1,
    "P7Mixer_SetGainIndex2": 0xFADACA,
    "GlobalTune_StoreFineTune": 0xFADAE7,
    "GlobalTune_StoreTranspose": 0xFADAFC,
    "GlobalScale_StoreMode": 0xFADB70,
    "GlobalScale_StorePitchClassDetune": 0xFADC1F,
    "GlobalScale_SelectGlobalOrPerTone": 0xFADC4C,
    "Voice_RestagePitchReg0400_ForList": 0xFADCC3,
    "GlobalTune_SetFineTune_AndRestageAll": 0xFB026C,
    "Dev10C_SetReg0201_FromNibblePair": 0xFADC6F,
    "VoiceDefaults_StoreFromPackedByte": 0xFADB7E,
}
REFUSED_ROUTINES = ["sub_FADA7C", "sub_FADB0F", "sub_FADBEE", "sub_FADBFC",
                    "sub_FADC3E", "sub_FB0285"]


def header_block(name):
    src = load()["src"]
    i = next((k for k, l in enumerate(src) if l.startswith("; %s -- 0x" % name)), None)
    if i is None:
        return None
    j = i
    while j < len(src) and not src[j].startswith("%s:" % name):
        j += 1
    return "\n".join(src[i:j])


# ==================================================== SELFTEST
def selftest():
    print("=== SELFTEST ===\n")
    a = arms()
    check(len(a) == 27, "GlobalSetup_Dispatch has 27 arms")
    check(a[0][0] == 0x09 and a[0][2] == 0xFB0405, "the FIRST arm is code 0x09 -> 0xFB0405")
    check(a[-1][0] == 0xB2 and a[-1][2] == 0xFB04F8,
          "the LAST arm is code 0xB2 -> 0xFB04F8")
    check(a[-1][3] == 0xFADC6F,
          "...and the LAST arm calls Dev10C_SetReg0201_FromNibblePair (0xFADC6F)")
    twelve = [x for x in a if 0xA4 <= x[0] <= 0xAF]
    check(len(twelve) == 12 and all(x[3] == 0xFADC1F for x in twelve),
          "the twelve arms 0xA4..0xAF all call 0xFADC1F")
    check([x[4] for x in twelve] == list(range(12)),
          "...and their extra argument runs 0x0000..0x000B, in order")
    d = load()["dis"]
    body = [d[x] for x in load()["order"] if DISPATCH <= x < DISPATCH_END]
    check(not any("XIX+0x01" in t for t in body),
          "no arm reads (XIX+0x01), the part index -- the record is GLOBAL")
    check(not any("0x012c" in t.lower() for t in body),
          "no arm uses the part-record stride 0x012C")

    acc, noread = show_record_quiet()
    check(set(noread) == {0x04, 0x09, 0x0A, 0x0B},
          "exactly four record fields have a writer and no located reader")
    check(all(acc[o][0] for o, _w, _x in ROWS),
          "every field in the table has at least one located writer")
    check(0x09 in noread and 0x0A in noread,
          "...including +0x09 (0x1507) and +0x0A (0x1508), the two refusals")
    offs = set(o for o in acc)
    check(0x0D in offs and 0x1F in offs,
          "the scale table (+0x0D) and the voice default (+0x1F) are both seen")
    check(RECORD_END - RECORD_BASE == 37, "the record is 37 bytes, 0x14FE..0x1522")
    regoff = tuple(o for o in sorted(acc)
                   if any("X" in t and "(0x" not in t.split(",")[-1]
                          for _a, t in acc[o][0] + acc[o][1]))
    check(regoff == REG_OFFS,
          "the record is reached through a register at exactly %s"
          % " ".join("+0x%02X" % o for o in REG_OFFS))
    e = enclosing()
    wnames = set()
    for _o, (w, _r) in acc.items():
        for a, _t in w:
            wnames.add(e.get(a))
    wnames.discard(None)
    armfns = set(labels_by_addr().get(x[3]) for x in arms())
    check(len(wnames) == 18, "eighteen routines write into the record")
    check(len(wnames & armfns) == 13, "...thirteen of them are arms of the dispatcher")
    check(wnames - armfns == {"ExtBoard_ProbeAndInstallBases", "Toggle14FE_AndDispatch",
                              "sub_FB6CEE", "sub_FAC34D", "GlobalTune_StoreFineTune"},
          "...and the other five are the four outside the message plus "
          "GlobalTune_StoreFineTune, one level below arm 0x82")
    src2 = open(SRC).read()
    lst = ", ".join("+0x%02X" % o for o in REG_OFFS)
    check(src2.count(lst) == 2,
          "both prose copies of that list, in the block comment and in "
          "sub_FADBEE's refusal, spell it identically")

    bad = [(x, e) for x, e in CLAIMS if e.lower() not in (d.get(x) or "").lower()]
    check(not bad, "all %d citations decode to the instruction they claim" % len(CLAIMS))
    check(CLAIMS[-1][1].lower() in (d.get(CLAIMS[-1][0]) or "").lower(),
          "...tested on the LAST citation as well as the first (0x%06X)" % CLAIMS[-1][0])
    check(check_f98ca4(), "0xF98CA4 is fixed by `calr (0xF98CB9 - 0xF98CA4)` above it")

    src = load()["src"]
    for n, addr in sorted(SHIPPED.items()):
        blk = header_block(n)
        check(blk is not None and blk.count("\n") >= 3 and "Evidence:" in blk,
              "%s has a header with an Evidence: line" % n)
        check(any(l.startswith("%s:" % n) for l in src), "%s is defined" % n)
    for n in REFUSED_ROUTINES:
        blk = header_block(n)
        check(blk is not None and "Refused:" in blk,
              "%s carries a REFUSAL with a derived reason" % n)
    stale = [l for l in src if "sub_FB0338" in l and not l.lstrip().startswith(";")]
    check(not stale, "no CODE line still spells the old name sub_FB0338 (the one "
                     "comment that does is the deliberate `was sub_FB0338` provenance)")

    tot, sus = grader_quiet()
    check(tot == 291, "291 `<parent>__<word>` labels are graded content across the tree")
    g, dd = grade_labels(SRC)
    check(sum(1 for _x, gg in dd if gg == "content") == 168,
          "...168 of them in prom_c")
    check(len(sus) == 30, "30 prom_c framed labels carry a suffix that is not their "
                          "own address")
    check(any(n == "PresetBank_Paris_Caffe" for n, _t, _a in sus),
          "...and PresetBank_Paris_Caffe is one of them")
    rom = open(ROM, "rb").read()
    check(rom.find(b"Paris Caffe") == 0xF85844 - BASE,
          "the string 'Paris Caffe' really is at 0xF85844, inside that record")

    out, nh = depth_quiet()
    check(out["sub"][0] == out["sub"][1] == out["sub"][2],
          "every remaining sub_XXXXXX carries a header AND an Evidence line")
    check(len([n for n in nh if not n.startswith("PresetBank")]) == 7,
          "only seven non-PresetBank content labels lack a header")

    print("\n%d checks, %d failures" % (CHECKS[0], len(FAILS)))
    return 1 if FAILS else 0


CHECKS = [0]
_check = check


def check(cond, msg):  # noqa: F811
    CHECKS[0] += 1
    return _check(cond, msg)


def _quiet(fn):
    import io
    old = sys.stdout
    sys.stdout = io.StringIO()
    try:
        return fn()
    finally:
        sys.stdout = old


def show_record_quiet():
    return _quiet(show_record)


def grader_quiet():
    return _quiet(show_grader)


def depth_quiet():
    return _quiet(show_depth)


# ============================================================================
# ROUND 9 (2026-08-30), writer-C -- THE EIGHT-SLOT NOTE POOL, AND WHAT `framed` IS
# ============================================================================
# Appended below round 8; nothing above this line was changed.  Three sections:
#
#   --pool8      every citation the note-pool module's twelve headers make,
#                checked AT the cited address; the 68-byte device image against
#                its reset twin, word by word; and the two-sweep census that
#                turns "the pool state is private" into a measurement.
#   --framed     what prom_c's `framed` column actually contains.  This round's
#                headline number is framed->content promotions, and a promotion
#                only means anything for a label that is a KIND PLUS ITS OWN
#                ADDRESS.  The partition is derived, so the promotable population
#                is a measurement rather than an impression.
#   --refused9   this round's refusals, each with its arithmetic.
#
# THE QUESTION: "round 8 shipped ZERO framed->content promotions in prom_c.  Was
# that because there is nothing to promote, or because nobody looked?"  Both, in
# measurable parts.  Six were there and are shipped -- the note pool's five
# tables and its 68-byte device image, every one named from what READS it.  What
# is left in the column is, by --framed, almost entirely labels whose number IS
# the meaning; the promotable remainder is eight labels, named one by one.

POOL8_ENTRY = 0xFC3E02
POOL8_LO, POOL8_HI = 0xFC3CB9, 0xFC3FAD
POOL_ROTOR, POOL_NOTES = 0x00E005, 0x00E006
RESET_IMAGE, POOL_IMAGE, IMAGE_LEN = 0xFE12CF, 0xFE1540, 68
LEVEL_FIELD_TOP = 0x0FF4        # 2*Voice_OutputLevel_Table[255]: the 0x0080 field max

POOL8_CLAIMS = [
    (0xFB07FD, "cp H,0xf0"), (0xFB0800, "jr NC,0xfb0808"),
    (0xFB0802, "call 0xfb3f36"), (0xFB0808, "call 0xfc3e02"),
    (0xFC3E17, "and L,0x0f"), (0xFC3E1A, "cp L,6"), (0xFC3E1E, "ld L,0x00"),
    (0xFC3E25, "inc 1,C"), (0xFC3E27, "and C,0x07"), (0xFC3E2A, "ld (0x00e005),C"),
    (0xFC3E35, "res 0x07,D"), (0xFC3E3B, "res 0x07,H"),
    (0xFC3E3E, "cp D,0"), (0xFC3E40, "jrl Z,0xfc3f47"),
    (0xFC3E4C, "add IX,0x0840"), (0xFC3E58, "ld (XWA),IX"),
    (0xFC3E5D, "ld (XBC+0x02),0xff00"),
    (0xFC3E70, "add IX,0x0800"), (0xFC3E7C, "ld (XBC),IX"),
    (0xFC3E81, "ld (XBC+0x02),0xff80"),
    (0xFC3EA1, "call 0xfb7a58"), (0xFC3EA9, "call 0xfc571a"), (0xFC3ECD, "call 0xfb77ef"),
    (0xFC3ED1, "push 0x0044"), (0xFC3ED8, "lda XWA,0xfe1540"), (0xFC3EDE, "call 0xf9a038"),
    (0xFC3EEC, "cp L,1"), (0xFC3EEE, "jr NZ,0xfc3efb"),
    (0xFC3EF4, "calr 0xfc3daf"), (0xFC3F04, "calr 0xfc3d26"),
    (0xFC3F17, "call 0xfb713a"), (0xFC3F1B, "ld BC,(XIZ+0x92)"),
    (0xFC3F1F, "ld BC,(0x00e005)"), (0xFC3F27, "call 0xfb732c"),
    (0xFC3F2D, "set 0x07,L"), (0xFC3F39, "add XBC,0x0000e006"),
    (0xFC3F47, "set 0x07,H"), (0xFC3F63, "cp A,H"),
    (0xFC3F74, "ld (XBC+0x02),0xa200"), (0xFC3F8B, "ld (XBC+0x02),0xa280"),
    (0xFC3F98, "and (XBC),0x7f"),
    (0xFC3FA1, "inc 1,L"), (0xFC3FA3, "cp L,0x08"), (0xFC3FA6, "jr C,0xfc3f52"),
    (0xFC3D35, "add XBC,0x00fe1584"), (0xFC3D3D, "add A,(XIZ+0x0a)"),
    (0xFC3D42, "res 0x07,L"), (0xFC3D49, "sll 0x08,BC"), (0xFC3D4F, "or (XWA+0x0e),BC"),
    (0xFC3D58, "or (XBC),WA"), (0xFC3D60, "or (XBC+0x06),WA"),
    (0xFC3D73, "or (XBC+0x04),WA"),
    (0xFC3D7A, "div C,0x0c"), (0xFC3D7D, "ld A,B"), (0xFC3D7F, "mul A,0x02"),
    (0xFC3D87, "cp H,6"), (0xFC3D8B, "add XWA,0x00fe1599"), (0xFC3D96, "ld (XWA+0x02),BC"),
    (0xFC3D9B, "lda XBC,0xfe15b1"), (0xFC3DA7, "ld (XBC+0x02),WA"),
    (0xFC3DBD, "div C,0x0c"), (0xFC3DC0, "ld H,B"), (0xFC3DC5, "sub C,B"),
    (0xFC3DCC, "sll 0x08,BC"), (0xFC3DCF, "or (XIX+0x0e),BC"),
    (0xFC3DD4, "mul BC,H"), (0xFC3DD8, "add XBC,0x00fe15c9"), (0xFC3DE0, "or (XIX),BC"),
    (0xFC3DE5, "or (XIX+0x06),WA"), (0xFC3DE8, "push 0x0001"), (0xFC3DEB, "push 0x007f"),
    (0xFC3DF1, "or (XIX+0x04),WA"), (0xFC3DF4, "ld BC,(0xfe1599)"),
    (0xFC3DF9, "ld (XIX+0x02),BC"),
    (0xFC3CC2, "cp D,4"), (0xFC3CC9, "sll 0x05,BC"), (0xFC3CCE, "add BC,0x001f"),
    (0xFC3CE2, "cp BC,WA"), (0xFC3CE4, "jr LE,0xfc3cf4"), (0xFC3CE6, "ld C,0x02"),
    (0xFC3CFC, "ld C,(0x1533)"), (0xFC3D04, "sll 0x08,HL"),
    (0xFC3D07, "ld C,(0x1534)"), (0xFC3D0D, "or BC,HL"),
    (0xFC3D13, "ld C,(0x153c)"), (0xFC3D17, "srl 0x04,C"), (0xFC3D1A, "cp C,5"),
    (0xFC3D1E, "ld WA,0x0c00"), (0xFC3D23, "sub WA,WA"),
    (0xFAA0D3, "ld C,(XHL+0x11)"), (0xFAA12E, "ld C,(XDE+0x10)"),
    (0xFAA110, "cp IX,0x007f"), (0xFAA181, "cp HL,0x007f"),
    (0xFAA18C, "sll 0x08,BC"), (0xFAA19A, "ld (0x00d764),BC"),
    (0xFB0C29, "mul WA,0x012c"), (0xFB0C8A, "ld BC,0x1523"),
    (0xFB0CD3, "add BC,(XIZ+0xfa)"), (0xFB0CD6, "ld (XHL+0x23),BC"),
    (0xFAD851, "add BC,0x0010"), (0xFAD85A, "ld (XBC+0x1523),A"),
    (0xFAD86F, "add BC,0x0011"), (0xFAD878, "ld (XBC+0x1523),A"),
    (0xFA7F48, "add HL,0x0080"), (0xFA7FC5, "div C,0x0c"),
    (0xFB814F, "lda XWA,0xfe12cf"), (0xFB8155, "call 0xf9a038"),
    (0xFB817E, "calr 0xfb713a"),
]

POOL8_NAMES = [
    ("NotePool8_LevelFromVelocity", 0xFC3CB9),
    ("NotePool8_Reg00C0_FromPart0Ctrl91And93", 0xFC3CFB),
    ("NotePool8_Word0Bits_FromPart0Ctrl9B", 0xFC3D13),
    ("NotePool8_StageVoice", 0xFC3D26),
    ("NotePool8_StageVoice_Var1", 0xFC3DAF),
    ("NotePool8_NoteOnOff", 0xFC3E02),
]
POOL8_TABLES = [
    ("Dev10C_StagingStruct_NotePool8Image", 0xFE1540, 68),
    ("NotePool8_TransposeByVariant", 0xFE1584, 7),
    ("NotePool8_LevelCapByVariant", 0xFE158B, 14),
    ("NotePool8_Reg0040_ByPitchClass", 0xFE1599, 24),
    ("NotePool8_Reg0040_ByPitchClass_Var6", 0xFE15B1, 24),
    ("NotePool8_Word0_ByPitchClass_Var1", 0xFE15C9, 24),
]
OLD_POOL8_NAMES = ["sub_FC3CB9", "sub_FC3CFB", "sub_FC3D13", "sub_FC3D26",
                   "sub_FC3DAF", "sub_FC3E02", "Table_FE1540", "Table_FE1584",
                   "Table_FE158B", "Table_FE1599", "Table_FE15B1", "Table_FE15C9"]
# staging word -> 0x0010C000 register, as notes/prom_c_tg_chanmap.py 0xFB713A
# 0x1F2 --pairs prints it.  22 words, 0x00 unsent by that routine.
WORD2REG = {1: 0x0040, 2: 0x0080, 3: 0x00C0, 4: 0x0100, 5: 0x0140, 6: 0x0180,
            7: 0x0400, 8: 0x0440, 9: 0x0480, 10: 0x04C0, 11: 0x0500, 12: 0x0800,
            13: 0x0840, 14: 0x0880, 15: 0x08C0, 16: 0x0900, 17: 0x0940,
            18: 0x0980, 19: 0x09C0, 20: 0x0A00, 21: 0x0A40}
P7R = re.compile(r'^P7Stream_[0-9A-Fa-f]{6}$')
DEV_BLOCKS = set(range(0x0000, 0x0A80, 0x40))     # block*0x40, the device's stride


def rom_bytes():
    if "rom9" not in _C:
        _C["rom9"] = open(ROM, "rb").read()
    return _C["rom9"]


def w16(a):
    r = rom_bytes()
    return r[a - BASE] | (r[a - BASE + 1] << 8)


def image_diff():
    """The reset staging image against the note-pool one, word by word, straight
    out of the ROM.  If either image moves, this moves with it."""
    r = rom_bytes()
    diff = [(i, w16(RESET_IMAGE + 2 * i), w16(POOL_IMAGE + 2 * i), WORD2REG.get(i))
            for i in range(IMAGE_LEN // 2)
            if w16(RESET_IMAGE + 2 * i) != w16(POOL_IMAGE + 2 * i)]
    nb = sum(1 for i in range(IMAGE_LEN)
             if r[RESET_IMAGE - BASE + i] != r[POOL_IMAGE - BASE + i])
    return diff, nb


def pool_state_census():
    """Two independent sweeps for anything naming the pool's two RAM cells:
    (a) every ADDRESSED source line whose disassembly text spells the address;
    (b) every 24-bit little-endian occurrence in all 524,288 ROM bytes.
    Both are blind to a reach through a register.  The result is 'nothing else
    in the image names it', never 'dead'."""
    d = load()["dis"]
    src_hits = [(a, t) for a, t in sorted(d.items())
                if re.search(r'0x0*e00[56]\b', t, re.I)]
    rom_hits = []
    r = rom_bytes()
    for target in (POOL_ROTOR, POOL_NOTES):
        pat = target.to_bytes(3, "little")
        i = r.find(pat)
        while i != -1:
            rom_hits.append((BASE + i, target))
            i = r.find(pat, i + 1)
    return src_hits, sorted(rom_hits)


def mnemonic(a):
    """The disassembly text at `a` with any leading raw-byte run stripped.  Some
    listing lines read `f2 cf 12 fe 30    lda XWA,0xfe12cf`; the citation names the
    instruction, not the bytes."""
    t = (load()["dis"].get(a) or "")
    return re.sub(r'^(?:[0-9a-f]{2}\s+)+', '', t).strip()


def pool8_bad_claims():
    return [(a, t, mnemonic(a)) for a, t in POOL8_CLAIMS
            if not mnemonic(a).lower().startswith(t.lower())]


def source_labels():
    return set(m.group(1) for m in (LABEL.match(l) for l in load()["src"]) if m)


def show_pool8():
    print("=== 7. THE EIGHT-SLOT NOTE POOL -- every claim, re-derived ===\n")
    print("  The 0x90 (note-on) arm of MidiIn_ParseRingAndDispatch branches on packet")
    print("  byte [1]: below 0xF0 to MidiNote_Dispatch and the 33 part records, at 0xF0")
    print("  or above to NotePool8_NoteOnOff.  That second path is this module, and it")
    print("  was the '⚠ what packet byte [1] >= 0xF0 means' line in that routine's own")
    print("  Unknown section.\n")
    bad = pool8_bad_claims()
    d = load()["dis"]
    print("  citations checked AT the cited address: %d, mismatching: %d"
          % (len(POOL8_CLAIMS), len(bad)))
    for a, t, got in bad:
        print("    MISMATCH %06X  want %-26r got %r" % (a, t, got))
    la, lt = POOL8_CLAIMS[-1]
    print("  the LAST citation, 0x%06X, wants %r and decodes as %r"
          % (la, lt, mnemonic(la)))

    print("\n  -- the module's twelve objects --")
    lab = source_labels()
    for n, a in POOL8_NAMES:
        print("    %-40s 0x%06X            %s"
              % (n, a, "defined" if n in lab else "MISSING"))
    for n, a, ln in POOL8_TABLES:
        print("    %-40s 0x%06X  %3d B     %s"
              % (n, a, ln, "defined" if n in lab else "MISSING"))

    print("\n  -- the 68-byte device image against its reset twin --")
    diff, nb = image_diff()
    print("    bytes differing %d of %d ; words differing %d of %d"
          % (nb, IMAGE_LEN, len(diff), IMAGE_LEN // 2))
    for i, x, y, reg in diff:
        where = ("register chan+0x%04X" % reg) if reg is not None else (
            "staging word 0 -- the word Dev10C_WriteAllChanRegs never sends"
            if i == 0 else "beyond the 0x2C struct")
        print("      word %2d  reset 0x%04X  pool 0x%04X   %s" % (i, x, y, where))

    print("\n  -- is the pool state private?  two sweeps --")
    src_hits, rom_hits = pool_state_census()
    ins = [a for a, _t in src_hits if POOL8_ENTRY <= a <= POOL8_HI]
    rin = [a for a, _t in rom_hits if POOL8_ENTRY <= a <= POOL8_HI]
    print("    addressed source lines naming 0x%06X / 0x%06X : %d, inside"
          " NotePool8_NoteOnOff %d" % (POOL_ROTOR, POOL_NOTES, len(src_hits), len(ins)))
    print("    24-bit LE occurrences in the 512 KiB image      : %d, inside it %d"
          % (len(rom_hits), len(rin)))
    print("    ⚠ both sweeps are blind to a reach through a register.")

    print("\n  -- the five tables, read out of the ROM --")
    r = rom_bytes()
    tv = [r[0xFE1584 - BASE + i] for i in range(7)]
    print("    NotePool8_TransposeByVariant        : %s" % tv)
    print("      as signed semitones               : %s"
          % [v - 256 if v > 127 else v for v in tv])
    for nm, a, cnt in (("NotePool8_LevelCapByVariant", 0xFE158B, 7),
                       ("NotePool8_Reg0040_ByPitchClass", 0xFE1599, 12),
                       ("NotePool8_Reg0040_ByPitchClass_Var6", 0xFE15B1, 12),
                       ("NotePool8_Word0_ByPitchClass_Var1", 0xFE15C9, 12)):
        print("    %-36s: %s"
              % (nm, " ".join("%04X" % w16(a + 2 * i) for i in range(cnt))))
    for v in sorted(set(w16(0xFE158B + 2 * i) for i in range(7))):
        print("    level cap 0x%04X : %4d counts below 0x%04X -> %.1f dB at 256/octave"
              % (v, LEVEL_FIELD_TOP - v, LEVEL_FIELD_TOP,
                 (LEVEL_FIELD_TOP - v) * 6.0206 / 256.0))

    print("\n  -- what the module does NOT establish --")
    print("    * what the seven variants are.  The packets arrive over link channel 0")
    print("      from CPU 1, so any name for them lives in prom_a; prom_c spells")
    print("      0xF0..0xF6 as a part selector nowhere else.")
    print("    * whether the note-off pair 0xA200/0xA280 is a release envelope or a")
    print("      second quiescent state.  Nothing in this image reads either back.")
    print("    * what staging word 0's bit fields mean.")
    return bad, diff, nb, src_hits, rom_hits


# ------------------------------------------ 8. WHAT prom_c's `framed` COLUMN IS
def framed_labels():
    """(name, address) for every prom_c label the metric grades FRAMED."""
    addr = {}
    for a, n in sorted(labels_by_addr().items()):
        addr.setdefault(n, a)
    return sorted(((n, addr[n]) for n in addr
                   if not INTERNAL.match(n) and not UNNAMED.match(n)
                   and FRAMED.match(n)), key=lambda t: t[1])


def own_address_framed():
    """Framed labels that really are A KIND PLUS THEIR OWN ADDRESS -- the only
    population for which the word `promotion` means anything.  Derived: the
    trailing 4-6 hex digits equal the low bits of the label's own address."""
    out = []
    for n, a in framed_labels():
        m = re.search(r'_([0-9A-Fa-f]{4,6})$', n)
        if not m:
            continue
        if a & ((1 << (4 * len(m.group(1)))) - 1) == int(m.group(1), 16):
            out.append((n, a))
    return out


# The two regions of prom_c that a committed findings doc declares framed BY
# DECISION.  Neither is typed as a guess: the first is the extent
# FINDINGS-prom_c-p7-byte-stream-pool.md gives for the byte-stream pool and its
# directory, the second runs from the pool's end to the last byte of the image's
# data tail (gen_prom_c_tail_tables.py's R1_LO..R3_HI plus the curves below it).
P7_POOL = (0xFCD0F7, 0xFDD2AB)
DATA_TAIL = (0xFDD2AB, 0xFE21E6)


def framed_partition():
    """Every prom_c framed label in exactly one DERIVED class.  The split that
    matters is whether the suffix is the object's OWN ADDRESS -- only then is
    'promotion' the right word -- and, for those, which declared-framed region
    the object sits in."""
    own = set(n for n, _a in own_address_framed())
    part = collections.OrderedDict(
        [("own address, inside the P7 byte-stream pool", []),
         ("own address, inside the data tail", []),
         ("own address, ELSEWHERE -- the promotable remainder", []),
         ("the suffix is NOT this object's address: the number IS the meaning", [])])
    for n, a in framed_labels():
        if n not in own:
            part["the suffix is NOT this object's address: the number IS the "
                 "meaning"].append((n, a))
        elif P7_POOL[0] <= a < P7_POOL[1]:
            part["own address, inside the P7 byte-stream pool"].append((n, a))
        elif DATA_TAIL[0] <= a < DATA_TAIL[1]:
            part["own address, inside the data tail"].append((n, a))
        else:
            part["own address, ELSEWHERE -- the promotable remainder"].append((n, a))
    return part


# The promotable remainder, one line each.  Every one carries a REFUSAL that a
# committed round already derived; --selftest asserts the set is exactly these
# seven, so a new one appearing anywhere in prom_c fails the check instead of
# slipping past.
REMAINDER_STANDING = {
    "Dev10C_StageRegs_0800_0840_FAB818":
        "REFUSED round 8.  One of three producers of the SAME word pair "
        "(0x00D78A/0x00D78C); promoting one means saying what its two values MEAN, "
        "which the round-2 header declares unknown.",
    "Dev10C_StageRegs_0800_0840_FAB8CC": "REFUSED round 8, same reason.",
    "Dev10C_StageRegs_0800_0840_FAB9D8": "REFUSED round 8, same reason.",
    "Clamp_ToRange_LowByte_FBD88E":
        "REFUSED round 8, and correctly framed.  The suffix records a SEPARATELY "
        "COMPILED copy of Clamp_ToRange_LowByte -- 42 bytes against 34, 36 of the "
        "first 42 differing.  Dropping it would claim a twin the byte diff denies.",
    "unexplained_FCC5BE":
        "REFUSED round 8.  It needs a SPLIT (0xFCC5BE..0xFCC5C1 are the last four "
        "bytes of the boot RAM image; 0xFCC5C2..0xFCC5C8 are five constants read in "
        "place) and the label is emitted by notes/gen_prom_c_tables.py, which the "
        "round-8 lane did not own.",
    "unexplained_FCCB6E":
        "REFUSED round 5, in the source, with an Evidence line.  Three bytes 00 01 "
        "00 indexed by the port-P7 UNIT number at 0xFA2C1F / 0xFA2CD7 / 0xFA2D8A; "
        "the fetched byte reaches sub_F9E0B7 and nothing reads that routine's "
        "meaning, so it keeps its address.",
    "fp_constant_pool_FCC81A":
        "NOT A PROMOTION.  The suffix is the pool's own address because the pool is "
        "what the name is FOR; notes/gen_prom_c_fp_pool.py emits it and --verify "
        "checks its 76 doubles and 2 longs.",
}


def show_framed():
    print("=== 8. WHAT prom_c's `framed` COLUMN ACTUALLY CONTAINS ===\n")
    print("  This round's headline number is framed->content promotions, so the first")
    print("  question is how many of the column could even BE promoted.  A promotion")
    print("  means something only for a label that is a KIND PLUS ITS OWN ADDRESS.  A")
    print("  label whose suffix is a device register, a MIDI controller number, a")
    print("  saturation bound or a table length is already as specific as it can be,")
    print("  and a word in place of the number would say LESS.  The test is mechanical:")
    print("  do the trailing 4-6 hex digits equal the low bits of the label's own")
    print("  address?\n")
    part = framed_partition()
    tot = 0
    for k, v in part.items():
        tot += len(v)
        print("    %-58s %4d" % (k[:58], len(v)))
    print("    %-58s %4d" % ("TOTAL framed in prom_c", tot))

    rem = part["own address, ELSEWHERE -- the promotable remainder"]
    print("\n  ★ THE WHOLE PROMOTABLE REMAINDER IS %d LABELS, and every one of them"
          % len(rem))
    print("  already carries a refusal that a committed round derived:\n")
    for n, a in rem:
        print("    %-38s 0x%06X" % (n, a))
        for line in re.findall(r'.{1,68}(?:\s|$)',
                               REMAINDER_STANDING.get(n, "NOT ADJUDICATED")):
            if line.strip():
                print("        %s" % line.rstrip())
    print("\n  The two big classes are declared framed BY DECISION, in the tree, with a")
    print("  reason that is a census result rather than a shrug:")
    print("    * the P7 byte-stream pool, 0x%06X-0x%06X: the objects' CONTENT is"
          % (P7_POOL[0], P7_POOL[1] - 1))
    print("      undecoded byte-code for the port-P7 device, so a name would be naming")
    print("      a blob (FINDINGS-prom_c-p7-byte-stream-pool.md sec 0).")
    print("    * the data tail, 0x%06X-0x%06X: shape and reader known, ROLE NOT"
          % (DATA_TAIL[0], DATA_TAIL[1] - 1))
    print("      claimed (FINDINGS-prom_c-tail-data-zone.md sec 7).  Six of them left")
    print("      that class this round, because their reader finally gave them a role.")
    print("\n  ⚠ SO prom_c's framed COLUMN IS NOT A BACKLOG.  It is one declared-blob")
    print("  region, one declared-shape-only region, %d names whose number is the"
          % len(part["the suffix is NOT this object's address: the number IS the "
                     "meaning"]))
    print("  meaning, and %d adjudicated leftovers.  Any report of the column that does"
          % len(rem))
    print("  not say so is misleading about where the number comes from.")
    return part


# --------------------------------------------------- 9. ROUND 9's REFUSALS
REFUSALS9 = [
 ("THE TEN BUCKET-S1 LABELS STAY sub_XXXXXX, and that is the arithmetic talking.", [
  "They are not routines.  Nothing in the image references them at any spelling and",
  "the instruction above each is not a control transfer, so the code above walks",
  "into them (prom_c_finish_round7.py --noref, ten of twenty-six).  Renaming them to",
  "the tree's <parent>__<address> convention would be CORRECT -- and would move ten",
  "labels out of the sub_XXXXXX column into `internal`, which the metric excludes",
  "from both sides, so LOWER and UPPER would both rise while nobody understood one",
  "more thing.  Round 7 left the job to 'a lane that is not also reporting the metric",
  "it would move'.  This lane reports the metric.  Refused; the list stays in",
  "--noref for a lane that does not."]),
 ("Voice_StageRegs_00C0_AB IS NOT RENAMED, although its register is now named.", [
  "Register chan+0x00C0 is established this round as (MIDI controller 91 << 8) |",
  "MIDI controller 93.  A promotion to Voice_StageCtrl91And93_Reg00C0_AB was drafted",
  "and dropped for three measured reasons: the label and its interior labels occur",
  "35 times in prom_c/wsa1_prom_c.s -- 33 before this round added two mentions of it",
  "to its own header; the name belongs to a family",
  "(Voice_StageRegs_0500_08C0_AB, Voice_StageRegs_0180_AB, Voice_StageRegs_CD) whose",
  "value is that they are spelled alike; and its suffix is a DEVICE REGISTER, where",
  "the number is the meaning.  The finding went into the routine's header and into",
  "the 0x0010C000 block comment, which is where a reader meets it."]),
 ("THE BRIEF'S ITEM 4 -- 'prom_c has 1,096 headers for 6,421 labels, add headers'.", [
  "Refused as stated; round 8 measured why and this round re-ran it (--depth).  6,421",
  "counts every branch target in the image.  Per grade, EVERY remaining sub_XXXXXX",
  "already carries a header AND an Evidence line, and the content labels with no",
  "header are 127 PresetBank_* records plus seven two-instruction interrupt stubs.",
  "New header text there is padding.  What this round did instead is REWRITE headers",
  "that already existed: six routine headers whose `Unknown: what the routine is FOR.",
  "Nothing here reads the meaning of a field' became a decoded field map, and three",
  "more -- MidiIn_ParseRingAndDispatch, Dev10C_WriteAllChanRegs and",
  "Voice_StageRegs_00C0_AB -- had a flagged Unknown closed.  The instrument cannot",
  "see any of that: it counts the PRESENCE of a header, not what it says."]),
 ("A COMMITTED SELFTEST HAS BEEN FAILING SINCE ROUND 7, and it is not this "
  "round's doing.", [
  "`python3 notes/prom_c_understanding_round6.py --selftest` prints 110 ok and FOUR",
  "failures.  Three of them are round 6's own before/after ledger -- 'prom_c content",
  "is 757 + 37 = 794', 'framed is 489 - 2 = 487', 'sub_XXXXXX is 492 - 35 = 457' --",
  "and rounds 7 and 8 moved all three numbers before this lane started (round 8 left",
  "prom_c at 821 / 500 / 417).  The fourth, 'every framed label matched exactly one",
  "rule', is broken by the twelve PartRec_ApplyParam_00XX labels ROUND 7 shipped,",
  "which its classifier has no rule for.  VERIFIED, not assumed: checked out with",
  "`git show HEAD:notes/prom_c_understanding_round6.py` and",
  "`git show HEAD:prom_c/wsa1_prom_c.s` into a scratch tree and re-run there, where",
  "it prints the same '110 ok, FAILURES: 4' with the same four lines.",
  "NOT FIXED HERE: three of the four are another round's before/after",
  "record and rewriting them would destroy the ledger they exist to be.  Reported so",
  "that the next lane does not read the failure as fresh damage."]),
 ("THE BRIEF'S ITEM 5 -- 'gap A is still open: 0x0440, 0x0480, 0x04C0, 0x0500'.", [
  "Stale.  Round 4 gave all four an accessor and notes/prom_c_gapA_remaining_regs.py",
  "(16 sections plus 8 negative controls) establishes that the low bits of 0x0440,",
  "0x0480 and 0x04C0 are a 0x0010C000 CHANNEL NUMBER -- the same number the producer",
  "hands to a Dev10C_Slot* accessor a few instructions later -- and that 0x0500 is a",
  "decoded byte pair.  notes/WSA1-EMULATION-DISASM-GAPS.md carries the retraction,",
  "and prom_c_finish_round7.py --gapA already reported the brief as stale a round",
  "ago.  Re-deriving it would be a lane spending itself on a closed question.  What",
  "gap A still wants is a register with a MUSICAL meaning, and this round added one:",
  "chan+0x00C0 = (controller 91 << 8) | controller 93, from two unrelated producers",
  "that agree on the split."]),
]


def show_refused9():
    print("=== 9. ROUND 9's REFUSALS, each with its arithmetic ===\n")
    for title, body in REFUSALS9:
        print("  %s" % title)
        for l in body:
            print("      %s" % l)
        print()


def selftest9():
    """Round 9's checks.  --selftest runs these after round 8's."""
    print("\n--- round 9 ---")
    d = load()["dis"]
    bad = pool8_bad_claims()
    check(not bad, "all %d note-pool citations decode AT the cited address"
          % len(POOL8_CLAIMS))
    la, lt = POOL8_CLAIMS[-1]
    check(mnemonic(la).lower().startswith(lt.lower()),
          "...tested on the LAST citation too (0x%06X wants %r)" % (la, lt))

    lab = source_labels()
    src = open(SRC).read()
    for n, _a in POOL8_NAMES:
        check(n in lab, "%s is defined in the source" % n)
        blk = header_block(n)
        check(blk is not None and "Evidence:" in blk,
              "...and its header carries an Evidence: line")
    for n, _a, _l in POOL8_TABLES:
        check(n in lab, "%s is defined in the source" % n)
        # the emitted data block is  <SEP> ... <SEP> <label>: ; take the text
        # between the OPENING separator and the label, i.e. skip the closing one.
        i = src.index("\n%s:\n" % n)
        head = src[max(0, i - 6000):i]
        j = head.rfind("; ---")
        j = head.rfind("; ---", 0, j)
        check("Evidence:" in head[j:], "...and its block carries an Evidence: line")
    for old in OLD_POOL8_NAMES:
        check(old not in src, "the old name %s is gone from the source" % old)

    diff, nb = image_diff()
    check(nb == 9, "the note-pool image differs from the reset image in 9 of 68 bytes")
    check(len(diff) == 8, "...which is 8 of its 34 words")
    check(diff[0][:3] == (0, 0x1200, 0xF000),
          "the FIRST differing word is word 0, 0x1200 -> 0xF000")
    check(diff[-1][:3] == (23, 0xFF00, 0xA000),
          "the LAST differing word is word 23, 0xFF00 -> 0xA000")
    check(w16(POOL_IMAGE + 2 * 7) == 0x0080,
          "the pool image seeds word 7 (register 0x0400) with the pitch centring 0x0080")
    check(w16(POOL_IMAGE + 2 * 2) == 0x8000,
          "and word 2 (register 0x0080) with the gate bit and a zero level field")

    src_hits, rom_hits = pool_state_census()
    check(len(src_hits) == 13, "13 addressed source lines name the pool's two RAM cells")
    check(all(POOL8_ENTRY <= a <= POOL8_HI for a, _t in src_hits),
          "...every one of them inside NotePool8_NoteOnOff")
    check(len(rom_hits) == 13, "13 24-bit LE ROM occurrences of the same two addresses")
    check(all(POOL8_ENTRY <= a <= POOL8_HI for a, _t in rom_hits),
          "...every one of them inside NotePool8_NoteOnOff too")

    r = rom_bytes()
    tv = [r[0xFE1584 - BASE + i] for i in range(7)]
    check(tv == [0, 0, 0x18, 0xE8, 0, 0, 0],
          "NotePool8_TransposeByVariant is 0,0,+24,-24,0,0,0 as signed bytes")
    caps = [w16(0xFE158B + 2 * i) for i in range(7)]
    check(len(caps) == 7 and max(caps) < LEVEL_FIELD_TOP,
          "all seven level caps are below the 0x0080 field's top 0x0FF4")
    check(caps[-1] == 0x0B42, "...and the LAST cap, variant 6, is 0x0B42")
    pc = [w16(0xFE1599 + 2 * i) for i in range(12)]
    check(all((v & 0x0FFF) == 0 for v in pc),
          "every NotePool8_Reg0040_ByPitchClass entry has a ZERO 12-bit payload")
    check(pc[-1] == 0x0000, "...tested on the LAST entry as well as the first")
    pc6 = [w16(0xFE15B1 + 2 * i) for i in range(12)]
    check(all((v & 0x0FFF) == 0 for v in pc6) and pc6[-1] == 0xC000,
          "the _Var6 table too, LAST entry 0xC000")

    part = framed_partition()
    tot = sum(len(v) for v in part.values())
    check(tot == len(framed_labels()), "every framed label lands in exactly one class")
    rem = part["own address, ELSEWHERE -- the promotable remainder"]
    check(set(n for n, _a in rem) == set(REMAINDER_STANDING),
          "the promotable remainder is EXACTLY the %d labels with a recorded refusal"
          % len(REMAINDER_STANDING))
    check(len(rem) == 7, "...and there are seven of them")
    check(len(part["own address, inside the P7 byte-stream pool"]) == 374,
          "374 own-address labels are inside the P7 byte-stream pool")
    check(len(part["own address, inside the data tail"]) == 28,
          "28 are inside the data tail")
    nk = part["the suffix is NOT this object's address: the number IS the meaning"]
    check(len(nk) == 85, "85 framed labels do NOT spell their own address")
    check(all(not re.search(r'_([0-9A-Fa-f]{4,6})$', n)
              or a & ((1 << (4 * len(re.search(r'_([0-9A-Fa-f]{4,6})$', n).group(1)))) - 1)
              != int(re.search(r'_([0-9A-Fa-f]{4,6})$', n).group(1), 16)
              for n, a in nk),
          "...and not one of those 85 accidentally spells it after all")

    check(mnemonic(0xFAD851).startswith("add BC,0x0010")
          and mnemonic(0xFAD85A).startswith("ld (XBC+0x1523),A"),
          "MidiCtrl_CC91 writes part[+0x10] (0xFAD851 / 0xFAD85A)")
    check(mnemonic(0xFAD86F).startswith("add BC,0x0011")
          and mnemonic(0xFAD878).startswith("ld (XBC+0x1523),A"),
          "MidiCtrl_CC93 writes part[+0x11] (0xFAD86F / 0xFAD878)")
    check(mnemonic(0xFB0C8A).startswith("ld BC,0x1523")
          and mnemonic(0xFB0CD6).startswith("ld (XHL+0x23),BC"),
          "voice_record[+0x23] is 0x1523 + 0x012C*part -- it IS the part record")
    check(0x1523 + 0x10 == 0x1533 and 0x1523 + 0x11 == 0x1534,
          "so RAM 0x001533/0x001534 are part 0's +0x10 and +0x11")
    check(0x1523 + 0x19 == 0x153C,
          "and 0x00153C is part 0's +0x19, the field MidiCtrl_Int9B writes")
    # the one number REFUSALS9 quotes that nothing else re-derives
    check(src.count("Voice_StageRegs_00C0_AB") == 35,
          "Voice_StageRegs_00C0_AB and its interior labels occur 35 times in the "
          "source -- the count the rename refusal rests on")


def main():
    args = sys.argv[1:]
    if "--selftest" in args:
        rc = selftest()
        selftest9()
        print("\n%d checks, %d failures (rounds 8 and 9)" % (CHECKS[0], len(FAILS)))
        sys.exit(1 if FAILS else rc)
    run_all = not args
    if run_all or "--dispatch" in args:
        show_dispatch()
        print()
    if run_all or "--record" in args:
        show_record()
        print()
    if run_all or "--claims" in args:
        show_claims()
        print()
    if run_all or "--grader" in args:
        show_grader()
        print()
    if run_all or "--refusals" in args:
        show_refusals()
    if run_all or "--depth" in args:
        show_depth()
        print()
    if run_all or "--pool8" in args:
        show_pool8()
        print()
    if run_all or "--framed" in args:
        show_framed()
        print()
    if run_all or "--refused9" in args:
        show_refused9()


if __name__ == "__main__":
    main()
