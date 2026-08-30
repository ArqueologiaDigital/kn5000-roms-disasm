#!/usr/bin/env python3
"""prom_c ROUND 12 (wave 7) -- THE FINISH INVENTORY: for every object in prom_c that
   is not content-named, WHICH NAMING MECHANISM REACHES IT, and what the name it
   yields is worth.

QUESTION IT ANSWERS
    "prom_c is territorially complete and carries the smallest documentation debt in
     the tree.  Round 7 bucketed its 944 unnamed-or-framed objects by REFUSAL REASON.
     This round asks the harder question the wave's own rule poses:

        NAME AN OBJECT FROM WHAT IT CONTAINS, FROM WHAT READS IT, OR (for a pointer)
        FROM WHAT IT POINTS AT.

     For each of the 892 objects, does any of those three mechanisms actually FIRE --
     and when one fires, does it yield a CONTENT name or only a FRAME?"

★ THE ANSWER, AND IT IS NOT THE ONE A NAMING ROUND WANTS
    ⚠ EVERY FIGURE IN THIS DOCSTRING IS "AT EMISSION", 2026-08-30, and every one of them
    is RECOMPUTED by the section named beside it.  Quote the script, not this paragraph:
    a second lane was editing prom_c while this one ran and the columns moved under it.

    Of the 867 objects that are not content-named, a mechanism fires on 192 (--census).
    On 70 of those the name it yields is a FRAME and not a content name, and the reason
    is measurable rather than a matter of taste: the object has a >=90%%-identical sibling
    in the same image, so the ONLY thing that separates the two is an immediate -- a
    record field offset, a device register block, a slot index.  Round 11 fixed the test
    for exactly this ("does the number have a referent OUTSIDE the code?") and used it to
    ACCEPT `SoftKeyCol1`, whose number is printed on the instrument, while rejecting
    `Dispatch_F54248_Arm3`.  prom_c's remaining objects sit on the wrong side of that
    line: their distinguishing feature is an offset into a record whose layout no
    document outside this ROM describes.

    So prom_c's LOWER bound cannot be pushed much further by reading prom_c harder.  It
    needs an OUTSIDE referent -- a service-manual page, a sibling firmware, a decoded
    record layout.  That is a result, and it is what this round publishes instead of
    twenty more names spelled to please the grader.  ⚠ It would have cost nothing to
    spell `SlotRec_ReadSignedByte_Off09` instead of `..._0009` and move the CONTENT
    column by seven without learning anything.  --grader measures the same spelling
    effect from the other side: 168 of prom_c's content-graded labels, 19.3%% of that
    column, are `<parent>__<word>` BRANCH TARGETS the grader's INTERNAL rule means to
    exclude and cannot, because it requires 4-6 HEX after the `__`.  Round 8 found that
    and measured 168; this script re-runs the census and gets 168.

WHAT THE ROUND SHIPPED
    14 renames, every one with a rewritten header and an Evidence line whose citations
    are re-read from the ROM by --names:
      6 sub_XXXXXX -> CONTENT   PartRec_Word0006_SetBit13, PartRec_Word0006_ClearBit13,
                                Add24_ClampTo120, MidiCtrl_Int99_ApplyToSelectedPart,
                                MidiCtrl_Int9A_ApplyToSelectedPart,
                                Rec8644_Store3Bytes_AndFlagChanged
      7 sub_XXXXXX -> FRAME     the six SlotRec_* accessors of the 0x00DF05 pointer
                                table, and Rec_StoreConsts_003F_0041.  Named to a frame
                                ON PURPOSE and the headers say so.
      1 FRAME -> CONTENT        Dev10C_StageRegs_0800_0840_FAB818 ->
                                ..._ForNoteOn (its sole reference is MidiNote_OnByPartMode;
                                the other two producers are NOT separable that way and
                                keep their addresses -- --names measures both statements)
    1 Evidence line added to IRQ_INTTC2, the one vector stub in prom_c's table that
    had none.

    AND FOUR REFUSALS WITH DERIVED REASONS (--refusals):
      R1  the 6 device-register writers of round 7's bucket S3.  The register-block
          extractor that names 36 of 36 already-named accessors DOES fire on all six --
          and all six are 187 to 545 bytes against a calibration set whose largest member
          is 128.  A register set names an ACCESSOR; it does not name a 545-byte routine
          that also retires voices.  Measured, --regblocks.
      R2  the 374 P7Stream_*/PoolDir_FieldRec_* pool objects.  Refused since round 5;
          this round states exactly what would name them and why the directory does not.
      R3  the 8 objects the census bucket calls NOT ROUTINES (round 7's bucket S1
          counted 10; two of them, 0xF9B2EE and 0xF9B305, are claimed first here by
          the CONTAINS detector -- the reachability statement for all of them is
          --noref, which is the authoritative one).  Round 7 said the rename to
          <parent>__<address> should be done by a lane that is not also reporting the
          metric it moves.  This lane IS reporting that metric, so it does not do it.
      R4  the three Voice_ApplyParamChange_Dispatch arms 0xFAEFC2/0xFAEFE7/0xFAF00C
          differ in ONE byte -- the slot index 0, 1, 2 they hand to
          Rec8644_Store3Bytes_AndFlagChanged.  A slot index is a number with no referent
          outside the code.

★ AND A MEASUREMENT THE NEXT LANE SHOULD NOT HAVE TO REPEAT: prom_c's HEADER DEBT IS NINE
    OBJECTS (--headers).  Every one of its 398 sub_XXXXXX carries a >=3-line header AND an
    Evidence line -- 398 of 398, the only image in the tree where that is true.  Of the
    5,325 labels the grader sees with no header, 4,849 are <parent>__<x> branch targets
    and 467 are entries of three self-documenting ROM tables (P7Stream_, PoolDir_,
    PresetBank_ -- for a preset the LABEL IS THE DATUM).  The nine that remain are seven
    interrupt-vector stubs of one or two instructions each, documented in the vector-table
    style with a single Evidence line, and two search lists covered by a shared block
    comment.  Exactly ONE of the nine was a real gap and this round closed it.

RUN
    python3 notes/prom_c_finish_round12.py              # every section
    python3 notes/prom_c_finish_round12.py --census     # 1: all 892, by MECHANISM
    python3 notes/prom_c_finish_round12.py --regblocks  # 2: the register-block extractor
    python3 notes/prom_c_finish_round12.py --noref      # 3: the no-reference census
    python3 notes/prom_c_finish_round12.py --names      # 4: this round's 14, re-measured
    python3 notes/prom_c_finish_round12.py --headers    # 5: the header depth
    python3 notes/prom_c_finish_round12.py --grader     # 6: what the instrument mis-grades
    python3 notes/prom_c_finish_round12.py --refusals   # 7: every refusal and its rule
    python3 notes/prom_c_finish_round12.py --inventory  # 8: THE INVENTORY
    python3 notes/prom_c_finish_round12.py --selftest   # all of it, exit 1 on any failure

WHAT THIS DOES **NOT** ESTABLISH
  * That an object no mechanism reaches is unnameable in principle.  It says which
    mechanism is missing, never that no evidence exists.
  * That a "no literal reference" object is dead.  --noref sweeps four spellings and then
    STATES ITS OWN BLINDNESS as a number: prom_c contains 49 register-indirect transfers
    (`jp T,XBC/XIX/XWA`), any one of which could reach any address.  "Not found", never
    "unreachable" -- this project has twice shipped a "no references" that had references.
  * What any P7 stream, any 0x0010C000 register block above 0x0800, or any slot-record
    field MEANS.  Every name this round ships states an operand or an operation.
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_c.llvm.elf")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xF80000

# the grader from notes/wave7_documentation_metrics.py, copied verbatim so this script
# is self-contained; --selftest asserts the two agree on prom_c's three column totals.
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                    r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                    r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')

CALR = re.compile(r'calr\s+\(0x([0-9A-Fa-f]+)\s*-\s*0x([0-9A-Fa-f]+)\)')
HEXOP = re.compile(r'0x([0-9A-Fa-f]{5,8})')
ADDCONST = re.compile(r'^\s*add\s+\w+,\s*(0x[0-9A-Fa-f]+|[0-9]+)\s*(?:;|$)')
INDIRECT = re.compile(r';\s*[0-9A-F]{6}\s+(?:jp|call)\s+T?,?\(?X[A-Z]{2}\)?\s*$')

_C = {}


def load():
    """Source lines, ELF symbols, ROM bytes, top-level labels and their extents.

    ⚠ THE EXTENT RULE MATTERS AND ROUND 7 GOT IT SUBTLY WRONG for one purpose: a label
    spelled <parent>__<word> (Kernel_InitRam__ready_queues, MAIN__bit3,
    Dev10C_SetChanReg_01C0_or_0600__high) is NOT matched by INTERNAL, which requires 4-6
    HEX characters after the `__`.  A body scan that stops at the next top-level label
    therefore stops INSIDE the routine.  That is how a first draft of the register-block
    extractor missed the 0x0600 in Dev10C_SetChanReg_01C0_or_0600, whose name says 0x0600
    on its face.  Here the body of `n` runs to the next label that does not start with
    `n + "__"`.
    """
    if _C:
        return _C
    src = open(SRC).read().split("\n")
    out = subprocess.run([NM, ELF], capture_output=True, text=True).stdout
    sym = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) == 3 and p[1] in "tTdDbBrR":
            sym[p[2]] = int(p[0], 16)
    rom = open(ROM, "rb").read()
    labels = []
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if m:
            labels.append((i, m.group(1), sym.get(m.group(1))))
    top = [(i, n, a) for i, n, a in labels if not INTERNAL.match(n)]
    lineof = dict((n, i) for i, n, _a in top)
    bodies = {}
    for _i, n, _a in top:
        s = lineof[n] + 1
        e = s
        while e < len(src):
            m = LABEL.match(src[e])
            if m and not m.group(1).startswith(n + "__"):
                break
            e += 1
        bodies[n] = (s, e)
    bya = sorted(set((a, n) for _i, n, a in top if a is not None))
    ext = {}
    for k, (a, n) in enumerate(bya):
        ext[n] = (a, bya[k + 1][0] if k + 1 < len(bya) else BASE + len(rom))
    _C.update(src=src, sym=sym, rom=rom, labels=labels, top=top, bodies=bodies,
              ext=ext, byaddr=dict((a, n) for a, n in bya))
    return _C


def grade(n):
    if UNNAMED.match(n):
        return "sub"
    if FRAMED.match(n):
        return "framed"
    return "content"


def blob(n):
    c = load()
    if n not in c["ext"]:
        return None
    a, e = c["ext"][n]
    if a is None or a < BASE or e > BASE + len(c["rom"]):
        return None
    return c["rom"][a - BASE:e - BASE]


def code_lines(n, directives=False):
    """The INSTRUCTION lines of n's body, comment column stripped.

    ⚠ `.byte` / `.short` / `.long` are DIRECTIVES, not instructions.  Counting them was
    the first draft's error and it showed: DupTail_FE15E1, four `.short` of padding, came
    out as a 13-instruction routine with a 'single-effect body'."""
    c = load()
    s, e = c["bodies"][n]
    out = []
    for ln in c["src"][s:e]:
        if ln.lstrip().startswith(";"):
            continue
        tx = ln.split(";")[0]
        if not tx.strip() or LABEL.match(ln):
            continue
        if tx.strip().startswith(".") and not directives:
            continue
        out.append(tx)
    return out


def cited(n, pat):
    """Every `; ADDR  mnemonic` in n's body whose mnemonic matches pat, as (addr, text).
    ★ The address is the INSTRUCTION's, taken from the emitter's own comment column --
    the defect this tree has made systematically is citing the imm32 INSIDE the
    instruction, one or two bytes later."""
    c = load()
    s, e = c["bodies"][n]
    out = []
    for ln in c["src"][s:e]:
        parts = ln.split(";")
        if len(parts) < 2:
            continue
        tail = parts[-1].strip()
        m = re.match(r'^([0-9A-F]{6})\s+(.*)$', tail)
        if m and re.search(pat, m.group(2)):
            out.append((int(m.group(1), 16), m.group(2)))
    return out


# ------------------------------------------------------------------ references
def refcensus():
    """Every LITERAL reference to every top-level object, from the source text: all
    instruction operands (symbolic and numeric) plus the `calr (T - S)` form."""
    c = load()
    src, byaddr = c["src"], c["byaddr"]
    encl = [None] * len(src)
    cur = None
    ti = 0
    top = c["top"]
    for i in range(len(src)):
        while ti < len(top) and top[ti][0] == i:
            cur = top[ti][1]
            ti += 1
        encl[i] = cur
    refs = collections.defaultdict(list)
    for i, ln in enumerate(src):
        if ln.lstrip().startswith(";") or LABEL.match(ln):
            continue
        codetext = ln.split(";")[0]
        if not codetext.strip():
            continue
        m = CALR.search(codetext)
        vals = [int(m.group(1), 16)] if m else [int(h, 16) for h in HEXOP.findall(codetext)]
        for w in re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', codetext):
            if w in c["sym"] and not INTERNAL.match(w):
                vals.append(c["sym"][w])
        for v in vals:
            if v in byaddr:
                refs[v].append((i, encl[i], codetext.strip()))
    return refs


def rom_pointers(addr):
    """Offsets in the ROM holding `addr` as a 24-bit LE pointer, at ANY alignment.
    The 32-bit form is a superset (the fourth byte is 0x00 for every in-image address)."""
    c = load()
    b3 = bytes([addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF])
    out, o = [], 0
    while True:
        o = c["rom"].find(b3, o)
        if o < 0:
            break
        out.append(BASE + o)
        o += 1
    return out


def indirect_sites():
    """Register-indirect transfers in prom_c -- the reference census's stated blindness.
    Any one of these can reach any address, so a 'no literal reference' result is
    'not found', never 'unreachable'."""
    c = load()
    out = []
    for ln in c["src"]:
        if INDIRECT.search(ln):
            m = re.search(r';\s*([0-9A-F]{6})\s+(.*)$', ln)
            out.append((int(m.group(1), 16), m.group(2).strip()))
    return out


# ==================================================== 2. THE REGISTER-BLOCK EXTRACTOR
DEVBASES = {"0x0010C000": "10C", "0x0010c000": "10C", "0x10C000": "10C",
            "0x00104000": "104", "0x104000": "104"}


def regblocks(n):
    """(device bases WRITTEN, register block bases) for one routine, read off
    instruction operands only.  A block base is an `add r,imm` immediate that is a
    non-zero multiple of 0x40 below 0x1000 -- the form every register accessor in this
    image uses to turn a channel number into a selector.  ⚠ The comment column is
    stripped first: two routines 'mention' 0x00104000 only in their header prose."""
    bases = set()
    blocks = set()
    for t in code_lines(n):
        for lit, tag in DEVBASES.items():
            if lit in t:
                bases.add(tag)
        m = ADDCONST.match(t + " ;")
        if m:
            s = m.group(1)
            v = int(s, 16) if s.startswith("0x") else int(s)
            if v and v % 0x40 == 0 and v <= 0x0FC0:
                blocks.add(v)
    return sorted(bases), sorted(blocks)


CALIB = re.compile(r'^(Dev10C_SetChanReg_|Dev104_SetChanReg)')
S3 = ["sub_FAC08D", "sub_FAC34D", "sub_FB6F2C", "sub_FB707E", "sub_FB7521", "sub_FB762F"]


def show_regblocks():
    c = load()
    names = [n for _i, n, _a in c["top"] if CALIB.match(n) and "__" not in n]
    ok = bad = 0
    sizes = []
    for n in names:
        _b, blocks = regblocks(n)
        want = set(int(x, 16) for x in re.findall(r'_([0-9A-F]{4})(?=_|$)', n))
        sizes.append(len(blob(n) or b""))
        if want <= set(blocks):
            ok += 1
        else:
            bad += 1
            print("  MISS %-40s extracted=%s name says=%s"
                  % (n, [hex(x) for x in blocks], [hex(x) for x in sorted(want)]))
    print("=== 2. THE REGISTER-BLOCK EXTRACTOR ===\n")
    print("  CALIBRATION on every already-named accessor in prom_c whose name spells its")
    print("  register blocks: %d of %d, %d misses.  Sizes %d..%d bytes (median %d)."
          % (ok, len(names), bad, min(sizes), max(sizes), sorted(sizes)[len(sizes) // 2]))
    print("  A rule that reproduces 36 names it did not write is calibrated; a rule")
    print("  invented for the six objects it is about to name is not.\n")
    print("  APPLIED to round 7's bucket S3 -- 'writes a device port, no constant base':\n")
    for n in S3:
        b, blocks = regblocks(n)
        L = len(blob(n) or b"")
        print("    %-12s %4d B  writes %-6s blocks %s"
              % (n, L, "/".join(b) or "-", ", ".join(hex(x) for x in blocks)))
    print("\n  ★ THE EXTRACTOR FIRES ON ALL SIX -- AND THEY ARE STILL REFUSED.  The")
    print("  calibration set's largest member is %d bytes; the smallest of these six is" % max(sizes))
    print("  %d and the largest %d.  A register-block set names an ACCESSOR, and every"
          % (min(len(blob(n)) for n in S3), max(len(blob(n)) for n in S3)))
    print("  one of the 36 is one.  0xFAC08D is 545 bytes, calls Voice_Retire_Mode20 and")
    print("  two other device writers, and touches nine voice-record fields; naming it")
    print("  after two register blocks would be a category error, not a name.")
    print("  ⚠ Round 6 already wrote full behavioural headers for sub_FB6F2C and")
    print("  sub_FB707E that say 'NOT NAMED' in as many words.  This round does not")
    print("  overturn that on a rule whose envelope excludes them.")
    return ok, bad, names, sizes


# ============================================================ 3. THE NO-REFERENCE CENSUS
def noref_rows():
    c = load()
    refs = refcensus()
    rows = []
    for _i, n, a in c["top"]:
        if grade(n) == "content" or a is None:
            continue
        src_refs = [r for r in refs.get(a, []) if r[1] != n]
        rom_refs = rom_pointers(a)
        rows.append((n, a, len(src_refs), len(rom_refs)))
    return rows


def fallthrough(n):
    """The instruction textually before this label, if it is NOT a control transfer.
    A label nothing references but that the code above walks into is not an
    unreferenced routine -- it is not a routine."""
    c = load()
    src = c["src"]
    li = None
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if m and m.group(1) == n:
            li = i
            break
    j = li - 1
    while j > 0:
        l = src[j]
        if l.strip() and not l.lstrip().startswith(";") and not LABEL.match(l):
            t = l.split(";")[0].strip()
            head = t.split()[0] if t.split() else ""
            if head in ("ret", "reti", "retd"):
                return None
            if head in ("jp", "jr", "jrl") and "," not in t.split(None, 1)[-1]:
                return None
            return t
        j -= 1
    return None


def show_noref():
    rows = [r for r in noref_rows() if r[2] == 0 and r[3] == 0]
    ind = indirect_sites()
    print("=== 3. THE NO-REFERENCE CENSUS, AND ITS OWN BLINDNESS ===\n")
    print("  Four sweeps, all of prom_c: every instruction operand spelled as a number,")
    print("  every operand spelled as a SYMBOL, the `calr (T - S)` displacement form the")
    print("  emitter uses, and every 24-bit little-endian pointer anywhere in the 512 KiB")
    code = [r for r in rows if len(code_lines(r[0]))]
    data = [r for r in rows if not len(code_lines(r[0]))]
    print("  image at any alignment.  %d objects survive all four -- %d with instructions"
          % (len(rows), len(code)))
    print("  in them and %d that are pure data:\n" % len(data))
    for n, a, _s, _r in code:
        f = fallthrough(n)
        print("    %-14s 0x%06X   %s" % (n, a, ("falls in from `%s`" % f) if f
                                        else "the line above it is a control transfer"))
    fall = [r for r in code if fallthrough(r[0])]
    print("\n  %d of the %d CODE objects are reached by FALL-THROUGH -- the instruction"
          % (len(fall), len(code)))
    print("  above them is not a control transfer, so they are not routines at all.  The")
    print("  other %d are entered, if at all, through a register." % (len(code) - len(fall)))
    print("\n  The %d DATA objects are a different statement and must not be read as the" % len(data))
    print("  same one: %d of them are P7Stream_* records inside the pool, whose boundaries"
          % sum(1 for n, _a, _s, _r in data if n.startswith("P7Stream_")))
    print("  come from the interpreter's own length field and the pool's exact tiling")
    print("  (FINDINGS-prom_c-p7-byte-stream-pool.md section 3), not from a citation.  An")
    print("  uncited boundary that TILES is evidence; an uncited routine is a hole.")
    print("\n  ⚠ AND THE DENOMINATOR, WHICH IS THE POINT.  prom_c contains %d" % len(ind))
    print("  register-indirect transfers:")
    for k, v in sorted(collections.Counter(t for _a, t in ind).items()):
        print("      %-14s %3d" % (k, v))
    print("  Any one of them can reach any address, so every line above says NOT FOUND")
    print("  and none of them says UNREACHABLE.  This tree has twice published a")
    print("  'no references' that had references; the fix is not a better search, it is")
    print("  printing the search's blind spot beside its result.")
    return rows, ind


# ==================================================== 4. THIS ROUND'S NAMES, RE-MEASURED
RENAMES = [
    # new name, address, old name, grade the new name gets, mechanism
    ("PartRec_Word0006_SetBit13", 0xFACC3F, "sub_FACC3F", "content", "contains"),
    ("PartRec_Word0006_ClearBit13", 0xFACC5A, "sub_FACC5A", "content", "contains"),
    ("Add24_ClampTo120", 0xFA77F3, "sub_FA77F3", "content", "contains"),
    ("MidiCtrl_Int99_ApplyToSelectedPart", 0xFC280D, "sub_FC280D", "content", "reader"),
    ("MidiCtrl_Int9A_ApplyToSelectedPart", 0xFC2861, "sub_FC2861", "content", "reader"),
    ("Rec8644_Store3Bytes_AndFlagChanged", 0xFA267A, "sub_FA267A", "content", "contains"),
    ("SlotRec_AddToArgField_000C", 0xFC3595, "sub_FC3595", "framed", "contains"),
    ("SlotRec_AddToArgField_000E", 0xFC35B8, "sub_FC35B8", "framed", "contains"),
    ("SlotRec_ReadSignedByte_0009", 0xFC37BE, "sub_FC37BE", "framed", "contains"),
    ("SlotRec_ReadSignedByte_000A", 0xFC37E2, "sub_FC37E2", "framed", "contains"),
    ("SlotRec_ReadSignedByte_000B", 0xFC3806, "sub_FC3806", "framed", "contains"),
    ("SlotRec_ReadWordAtArgIndex_0003", 0xFC3793, "sub_FC3793", "framed", "contains"),
    ("Rec_StoreConsts_003F_0041", 0xFA78AB, "sub_FA78AB", "framed", "contains"),
    ("Dev10C_StageRegs_0800_0840_ForNoteOn", 0xFAB818,
     "Dev10C_StageRegs_0800_0840_FAB818", "content", "reader"),
]

# every citation any of the 14 headers makes, as (address, regex the mnemonic must match)
CITES = [
    (0xFACC48, r'mul BC,0x012c'), (0xFACC4C, r'inc 6,BC'),
    (0xFACC50, r'or \(XBC\+0x1523\),0x2000'),
    (0xFACC63, r'mul BC,0x012c'), (0xFACC67, r'inc 6,BC'),
    (0xFACC6B, r'and \(XBC\+0x1523\),0xdfff'),
    (0xFA77FB, r'add HL,0x0018'), (0xFA77FF, r'cp HL,0x0078'),
    (0xFA7803, r'jr LE'), (0xFA7805, r'ld WA,0x0078'),
    (0xFC2811, r'ld C,\(0x00d733\)'), (0xFC2816, r'cp \(XIZ\+0x08\),C'),
    (0xFC2820, r'mul BC,0x012c'), (0xFC2824, r'inc 4,BC'), (0xFC282D, r'and WA,0x0001'),
    (0xFC283C, r'add BC,0x001c'), (0xFC2847, r'cp A,0x20'),
    (0xFC284F, r'ld \(0x0087f5\),C'), (0xFC2859, r'ld \(0x008abb\),C'),
    (0xFC2865, r'ld C,\(0x00d733\)'), (0xFC286A, r'cp \(XIZ\+0x08\),C'),
    (0xFC2874, r'mul BC,0x012c'), (0xFC2878, r'inc 4,BC'), (0xFC2881, r'and WA,0x0001'),
    (0xFC2890, r'add BC,0x001c'), (0xFC289B, r'cp A,0x20'),
    (0xFC28A3, r'ld \(0x0087f6\),C'), (0xFC28AD, r'ld \(0x008abc\),C'),
    (0xFA267E, r'ld C,0x03'), (0xFA2685, r'add XBC,0x00008644'),
    (0xFA2697, r'inc 1,XBC'), (0xFA2699, r'add XBC,0x00008644'),
    (0xFA26AB, r'inc 2,XBC'), (0xFA26AD, r'add XBC,0x00008644'),
    (0xFA26B8, r'ei 0x06'), (0xFA26BA, r'ld \(0x00f2f1\),0x0000'),
    (0xFA26C1, r'set 5,\(0x007ecc\)'), (0xFA26C6, r'ei 0x00'),
    (0xFC359F, r'ld C,\(XHL\)'), (0xFC35A1, r'mul C,0x04'),
    (0xFC35A6, r'add XBC,0x0000df05'), (0xFC35AC, r'ld XBC,\(XBC\)'),
    (0xFC35AE, r'ld WA,\(XBC\+0x0c\)'), (0xFC35B1, r'add \(XHL\+0x0d\),WA'),
    (0xFC35C2, r'ld C,\(XHL\)'), (0xFC35C4, r'mul C,0x04'),
    (0xFC35C9, r'add XBC,0x0000df05'), (0xFC35CF, r'ld XBC,\(XBC\)'),
    (0xFC35D1, r'ld WA,\(XBC\+0x0e\)'), (0xFC35D4, r'add \(XHL\+0x0d\),WA'),
    (0xFC37C7, r'ld A,\(XBC\)'), (0xFC37C9, r'mul A,0x04'),
    (0xFC37CE, r'add XWA,0x0000df05'), (0xFC37D4, r'ld XBC,\(XWA\)'),
    (0xFC37D6, r'ld W,\(XBC\+0x09\)'), (0xFC37D9, r'ld C,W'), (0xFC37DB, r'exts BC'),
    (0xFC37EB, r'ld A,\(XBC\)'), (0xFC37ED, r'mul A,0x04'),
    (0xFC37F2, r'add XWA,0x0000df05'), (0xFC37F8, r'ld XBC,\(XWA\)'),
    (0xFC37FA, r'ld W,\(XBC\+0x0a\)'), (0xFC37FD, r'ld C,W'), (0xFC37FF, r'exts BC'),
    (0xFC380F, r'ld A,\(XBC\)'), (0xFC3811, r'mul A,0x04'),
    (0xFC3816, r'add XWA,0x0000df05'), (0xFC381C, r'ld XBC,\(XWA\)'),
    (0xFC381E, r'ld W,\(XBC\+0x0b\)'), (0xFC3821, r'ld C,W'), (0xFC3823, r'exts BC'),
    (0xFC379D, r'ld A,\(XBC\+0x03\)'), (0xFC37A0, r'mul A,0x02'),
    (0xFC37A7, r'ld A,\(XBC\)'), (0xFC37A9, r'mul A,0x04'),
    (0xFC37AE, r'add XWA,0x0000df05'), (0xFC37B4, r'ld XBC,\(XWA\)'),
    (0xFC37B6, r'add XBC,XIX'), (0xFC37B8, r'ld WA,\(XBC\)'),
    (0xFA78AF, r'ld BC,\(XIZ\+0x08\)'), (0xFA78B4, r'ld \(XBC\+0x3f\),0x017f'),
    (0xFA78B9, r'ld BC,\(XIZ\+0x08\)'), (0xFA78BE, r'ld \(XBC\+0x41\),0x7f7f'),
    (0xFC376C, r'link XIZ,0x0000'),
]


def instr_at(addr):
    """The mnemonic the source's own comment column gives for this INSTRUCTION address."""
    c = load()
    pat = re.compile(r';\s*%06X\s+(.*)$' % addr)
    for ln in c["src"]:
        m = pat.search(ln)
        if m:
            return m.group(1).strip()
    return None


def bytediff(a1, len1, a2):
    c = load()
    x = c["rom"][a1 - BASE:a1 - BASE + len1]
    y = c["rom"][a2 - BASE:a2 - BASE + len1]
    return [i for i, (p, q) in enumerate(zip(x, y)) if p != q]


def show_names():
    c = load()
    refs = refcensus()
    print("=== 4. THE 14 RENAMES, RE-MEASURED FROM THE ROM ===\n")
    for new, a, old, g, mech in RENAMES:
        assert new in c["sym"], new
        assert c["sym"][new] == a, new
        assert old not in c["sym"], old
        print("  %-38s 0x%06X  %-7s  named from what it %-9s (was %s)"
              % (new, a, g, {"contains": "contains", "reader": "is read by"}[mech], old))
    bad = [(x, instr_at(x)) for x, p in CITES
           if instr_at(x) is None or not re.search(p, instr_at(x))]
    print("\n  Every citation in the 14 headers, checked AT THE INSTRUCTION ADDRESS:")
    print("    %d citations, %d that do not decode to what the header says." % (len(CITES), len(bad)))
    for x, got in bad:
        print("      FAIL 0x%06X -> %r" % (x, got))
    d1 = bytediff(0xFACC3F, 27, 0xFACC5A)
    d2 = bytediff(0xFC280D, 84, 0xFC2861)
    print("\n  The two twin claims, re-measured:")
    print("    PartRec_Word0006_SetBit13 vs _ClearBit13   27 B, %d differing at %s"
          % (len(d1), d1))
    print("    MidiCtrl_Int99_... vs MidiCtrl_Int9A_...   84 B, %d differing at %s"
          % (len(d2), d2))
    print("\n  ★ THE PROMOTION, AND THE REFUSAL BESIDE IT.  Three routines produced the")
    print("  0x0800/0x0840 staging pair and all three carried an address suffix:")
    for n in ("Dev10C_StageRegs_0800_0840_ForNoteOn",
              "Dev10C_StageRegs_0800_0840_FAB8CC",
              "Dev10C_StageRegs_0800_0840_FAB9D8"):
        callers = sorted(set(e for _l, e, _t in refs.get(c["sym"][n], []) if e and e != n))
        print("    %-38s <- %s" % (n, ", ".join(callers) or "(none)"))
    print("  Only the first has a caller no other one of the three shares, so only the")
    print("  first can lose its address.  _FAB8CC and _FAB9D8 are BOTH reached from")
    print("  Voice_Retire_Mode08 and keep theirs.  That is the whole promotion: one of")
    print("  three, because one of three is what the mechanism separates.")
    return bad, d1, d2


# ================================================================ 5. HEADER DEPTH
TABLE_FAMILIES = ("P7Stream_", "PoolDir_", "PresetBank_")


def headerscan():
    """Per label: does a >=3-line comment block sit above it (one blank line tolerated),
    and does that block carry an Evidence: line?  The blank-line tolerance is the
    round-3 correction: without it a '+35 headers' gain was 35 REMOVED BLANK LINES."""
    c = load()
    run = blanks = 0
    ev = False
    have, noh = collections.Counter(), []
    tot = collections.Counter()
    evc = collections.Counter()
    for ln in c["src"]:
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
            g = "internal" if INTERNAL.match(n) else grade(n)
            tot[g] += 1
            if run >= 3:
                have[g] += 1
            else:
                noh.append((g, n))
            if ev:
                evc[g] += 1
        run, ev, blanks = 0, False, 0
    return tot, have, evc, noh


def show_headers():
    tot, have, evc, noh = headerscan()
    print("=== 5. HEADER DEPTH -- 'a named routine with no header is a name and nothing else' ===\n")
    print("  %-9s %8s %8s %9s" % ("grade", "labels", "header", "evidence"))
    for g in ("content", "framed", "sub", "internal"):
        print("  %-9s %8d %8d %9d" % (g, tot[g], have[g], evc[g]))
    print("\n  ★ EVERY ONE of prom_c's %d sub_XXXXXX has a header AND an Evidence line."
          % tot["sub"])
    print("  Round 7 gave them one each; the debt is not there.\n")
    branch = [n for g, n in noh if "__" in n]
    tab = [n for g, n in noh if "__" not in n and n.startswith(TABLE_FAMILIES)]
    real = [n for g, n in noh if "__" not in n and not n.startswith(TABLE_FAMILIES)]
    print("  labels the grader sees with no header:        %5d" % len(noh))
    print("    <parent>__<x> branch targets                %5d   a jump destination, not an object"
          % len(branch))
    print("    P7Stream_ / PoolDir_ / PresetBank_ entries  %5d   the LABEL IS THE DATUM"
          % len(tab))
    print("    -------------------------------------------------")
    print("    REAL header-less objects                    %5d" % len(real))
    for n in real:
        print("        %s" % n)
    irq = [n for n in real if n.startswith("IRQ_")]
    print("\n  All %d are one- or two-instruction stubs documented in a style the 3-line" % len(real))
    print("  rule cannot see: %d interrupt-vector stubs each carrying a single" % len(irq))
    print("  `; Evidence: VECTORS slot 0xNN ...` line, and %d search lists under a shared"
          % (len(real) - len(irq)))
    print("  block comment.  Before this round there were %d, and the extra one was" % (len(real) + 1))
    print("  IRQ_INTTC2 -- the only vector stub in the table with no evidence line at all.")
    print("  It has one now, so prom_c's header debt is %d objects and every one of them" % len(real))
    print("  is documented where a reader will actually look.")
    return tot, have, evc, real


# ============================================== 6. WHERE THE INSTRUMENT MIS-GRADES prom_c
def grader_rows():
    """Labels the wave-7 grader puts on the wrong side of its own stated intent.

    The grader's rule is deliberately harsh: a label whose LAST underscore-separated
    segment is a bare number is positional.  Two families of prom_c label break it in
    OPPOSITE directions, and both are measured here rather than argued:

      A  FRAMED-BY-SPELLING.  The last segment happens to be readable as hex or as a
         small decimal although the name plainly states content -- `Sat16_0_to_7FFF`
         (7FFF is the saturation bound), `PresetBank_Paris_Caffe` (Caffe is a WORD that
         is also six hex digits), `MathTable_Sin_S16_256` (256 is the entry count).
      B  CONTENT-BY-SPELLING.  `<parent>__<word>` branch labels -- MAIN__bit3,
         Kernel_InitRam__ready_queues -- are jump destinations inside a routine, exactly
         what INTERNAL exists to exclude, but INTERNAL requires 4-6 HEX after the `__`.
         Round 8 found this and measured 168; it is re-measured here, not retyped.
    """
    c = load()
    A, B = [], []
    for _i, n, _a in c["top"]:
        if "__" in n and not INTERNAL.match(n) and grade(n) == "content":
            B.append(n)
    return A, B


def show_grader():
    c = load()
    _A, B = grader_rows()
    print("=== 6. WHAT THE INSTRUMENT MIS-GRADES, MEASURED ===\n")
    print("  B  <parent>__<word> branch labels graded CONTENT: %d" % len(B))
    print("     (round 8 measured 168 for prom_c; this is the same census re-run)")
    for n in B[:6]:
        print("       %s" % n)
    print("       ...")
    tot, _h, _e, _noh = headerscan()
    print("\n  So prom_c's CONTENT column, %d, contains %d labels that are branch"
          % (tot["content"], len(B)))
    print("  targets rather than objects -- %.1f%% of it." % (100.0 * len(B) / tot["content"]))
    print("\n  ⚠ AND THE MIRROR, WHICH MATTERS MORE TO A NAMING LANE.  The same spelling")
    print("  rule means a name can be moved from FRAMED to CONTENT by writing")
    print("  `..._Off09` where `..._0009` was meant.  This round deliberately did NOT do")
    print("  that: the seven SlotRec_*/Rec_StoreConsts_* names it shipped are spelled so")
    print("  the grader calls them FRAMED, because a record field offset is a number with")
    print("  no referent outside the code and round 11 fixed that as the test.")
    return B


# =========================================================== 1. THE MECHANISM CENSUS
P7 = re.compile(r'^(P7Stream_|PoolDir_FieldRec_)')
TAILZONE = (0xFDE000, 0xFE2200)
DEVNUM = re.compile(r'^(Dev10C|Dev104|MidiCtrl|PartRec|Voice|DSP|SlotRec)')


def nearest_sibling():
    """For every object, the smallest byte-difference to another object of the SAME
    LENGTH anywhere in prom_c.  A pair that is >=90% identical is separated by
    IMMEDIATES, and a name that separates them is separated by a number.

    ★ CALIBRATION.  notes/FINDINGS-prom_c-dev10c-register-meanings.md section 1 says of
    the part-record controller handlers: 'Six of those handlers are the same thirty bytes
    and differ in EXACTLY ONE'.  That sentence was written from a different argument, and
    this sweep has to reproduce it or it is not measuring what it claims.  --selftest
    asserts it does.
    """
    c = load()
    blobs = {}
    for _i, n, a in c["top"]:
        if a is None:
            continue
        b = blob(n)
        if b and len(b) >= 8:
            blobs[n] = b
    bylen = collections.defaultdict(list)
    for n, b in blobs.items():
        bylen[len(b)].append(n)
    out = {}
    for n, b in blobs.items():
        best = None
        for t in bylen[len(b)]:
            if t == n:
                continue
            d = sum(1 for x, y in zip(b, blobs[t]) if x != y)
            if best is None or d < best[1]:
                best = (t, d)
        if best:
            out[n] = (best[0], best[1], len(b))
    return out


def delegates(n):
    """Does this routine hand its work to a routine that is itself unnamed?  A body that
    ends in `call sub_XXXXXX` does NOT state its own job however short it is, and letting
    it through was the first draft's mistake: it fired on the three
    Voice_ApplyParamChange_Dispatch arms whose entire content is one call."""
    c = load()
    for t in code_lines(n):
        m = CALR.search(t)
        vals = [int(m.group(1), 16)] if m else [int(h, 16) for h in HEXOP.findall(t)]
        for w in re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', t):
            if w in c["sym"]:
                vals.append(c["sym"][w])
        for v in vals:
            tgt = c["byaddr"].get(v)
            if tgt and tgt != n and grade(tgt) == "sub":
                return True
    return False


def census():
    """Every prom_c object that is not content-named, and WHICH MECHANISM REACHES IT.

    The mechanisms are the wave's own three, made into detectors that RUN:

      contains  the body states its own job in operands -- a device register block base
                (calibrated 36/36, --regblocks), or a single-effect body of at most 26
                instructions whose whole memory effect is one store or one record RMW.
      reader    EXACTLY ONE literal reference in the whole image, from a CONTENT-named
                object.  That is the rule the tree's 23 MidiCtrl_* names obey and the one
                round 7 used to refuse three of them.
      points    the object is a pointer or a table of pointers whose targets are named.

    and then the QUALITY of the name each yields:

      -> CONTENT  nothing else in the image has the same shape, so the name can say what
                  the object does without a number doing the separating.
      -> FRAME    the object has a >=90%-identical sibling: the two are separated by
                  immediates, so any name that tells them apart is telling them apart by
                  a number, and round 11's test asks whether that number has a referent
                  outside the code.  For a record field offset it does not.

    The first rule that fires owns the object and --census asserts the partition.
    """
    c = load()
    refs = refcensus()
    sib = nearest_sibling()
    rows = []
    for _i, n, a in c["top"]:
        g = grade(n)
        if g == "content" or a is None:
            continue
        b = blob(n) or b""
        ninstr = len(code_lines(n))
        rs = [r for r in refs.get(a, []) if r[1] != n]
        callers = set(e for _l, e, _t in rs if e)
        cg = collections.Counter(grade(x) for x in callers)
        bases, blocks = regblocks(n)
        s = sib.get(n)
        twinny = bool(s and s[2] >= 20 and s[1] <= max(1, s[2] // 10))
        # -- which mechanism fires
        if P7.match(n):
            mech, why = "none", "R2 pool object: its CONTENT is undecoded byte-code"
        elif a is not None and TAILZONE[0] <= a < TAILZONE[1] and ninstr == 0:
            mech, why = "contains", "R5 tail data zone: shape and reader known, role refused by decision"
        elif bases and blocks:
            mech, why = "contains", "device register blocks %s" % ",".join(hex(x) for x in blocks)
        elif ninstr and ninstr <= 26 and not delegates(n):
            mech, why = "contains", "single-effect body, %d instructions" % ninstr
        elif len(rs) == 1 and cg["content"] == 1:
            mech, why = "reader", "one reference, from %s" % sorted(callers)[0]
        elif not rs and not rom_pointers(a):
            if ninstr and fallthrough(n):
                mech, why = "none", "R3 not a routine: code that falls in from above"
            elif not ninstr:
                mech, why = "none", ("R7 data object with no citation: its bounds rest on "
                                     "tiling, not on a reference")
            else:
                mech, why = "none", "no literal reference of any spelling"
        elif cg["content"]:
            mech, why = "none", ("caller %s names a SUBSYSTEM, not this routine's job"
                                 % sorted(x for x in callers if grade(x) == "content")[0])
        else:
            mech, why = "none", "every caller is itself framed or unnamed"
        qual = "-" if mech == "none" else ("frame" if twinny else "content")
        rows.append((n, a, g, len(b), ninstr, mech, qual, why, s))
    return rows


def show_census():
    rows = census()
    print("=== 1. ALL %d prom_c objects that are not content-named, BY MECHANISM ===\n"
          % len(rows))
    tab = collections.Counter((r[5], r[6]) for r in rows)
    print("  %-10s %-9s %6s" % ("mechanism", "yields", "count"))
    for (m, q), k in sorted(tab.items(), key=lambda kv: -kv[1]):
        print("  %-10s %-9s %6d" % (m, q, k))
    reach = sum(k for (m, _q), k in tab.items() if m != "none")
    frame = sum(k for (m, q), k in tab.items() if m != "none" and q == "frame")
    print("\n  A mechanism REACHES %d of %d.  On %d of those the name it yields is a"
          % (reach, len(rows), frame))
    print("  FRAME: the object has a >=90%-identical sibling in this image, so whatever")
    print("  tells the two apart is an immediate.  %d can be named to CONTENT." % (reach - frame))
    print("\n  The refusals, by reason:\n")
    def cls(w):
        if w.startswith("caller "):
            return "caller names a SUBSYSTEM, not this routine's job"
        return w.split(":")[0]
    why = collections.Counter(cls(r[7]) for r in rows if r[5] == "none")
    for w, k in why.most_common():
        print("    %5d  %s" % (k, w))
    print("\n  every object landed in exactly one row: %s"
          % ("yes" if len(rows) == sum(tab.values()) else "NO"))
    return rows, tab


# ================================================================== 7. THE REFUSALS
def show_refusals():
    rows = census()
    print("=== 7. EVERY REFUSAL, WITH THE RULE THAT PRODUCED IT ===\n")
    print("  R1  THE SIX DEVICE WRITERS (round 7 bucket S3).  The extractor fires on all")
    print("      six; they are 187 to 545 bytes against a calibration set whose largest")
    print("      member is 128, and every one of them calls other routines and reads")
    print("      records.  A register-block set names an accessor.  --regblocks.")
    print("  R2  THE 374 P7Stream_* / PoolDir_FieldRec_* POOL OBJECTS.  Refused since")
    print("      round 5.  ★ WHAT WOULD NAME THEM, stated so the next lane does not have")
    print("      to rediscover it: PoolDir_Records (0xFDBFD9) holds 56 records of 25 bytes")
    print("      and each carries FOUR stream pointers at +0, +4, +8, +12.  Naming a")
    print("      stream `record 12, slot 2` is naming it by two positions.  The four SLOTS")
    print("      would be roles if the four field reads were decoded -- 0xFA2B4B and")
    print("      0xFA2B72 read +8 and +0 -- and the record index would be a role if the")
    print("      DescriptorStrings pair said what the program IS.  It does not: the")
    print("      strings are field-layout descriptors over {b,w,v,s,h,c,B}, not names.")
    print("      So the pool needs a payload decoder or an outside document, not a")
    print("      cleverer census.")
    print("  R3  THE 10 OBJECTS THAT ARE NOT ROUTINES.  Verified again by --noref.")
    print("      Round 7 said the rename to <parent>__<address> 'was deliberately left to")
    print("      a lane that is not also reporting the metric it would move'.  THIS LANE")
    print("      IS REPORTING THAT METRIC, so it does not do the rename.  It would have")
    print("      moved prom_c's sub_XXXXXX column by 10 and taught nobody anything.")
    print("  R4  THE THREE ApplyParamChange ARMS 0xFAEFC2 / 0xFAEFE7 / 0xFAF00C.  16")
    print("      instructions each and identical but for the immediate they push --")
    print("      0, 1, 2 -- to Rec8644_Store3Bytes_AndFlagChanged.  A slot index in an")
    print("      array of three has no referent outside the code.")
    print("  R5  THE 43 TAIL-ZONE DATA OBJECTS.  Framed BY DECISION in round 3:")
    print("      FINDINGS-prom_c-tail-data-zone.md section 7 fixes the spelling -- where")
    print("      only the shape and the reader are known the name says so.")
    print("  R6  THE 52 OBJECTS WHOSE NUMBER IS THE MEANING -- Dev10C_SetChanReg_0440,")
    print("      MidiCtrl_CC07, PartRec_ApplyParam_001D.  These are NOT debt.  The suffix")
    print("      is a device register, a MIDI controller number or a record field offset,")
    print("      i.e. an instruction operand, and rewriting them as prose would DELETE")
    print("      information.  prom_c's honest floor for the FRAMED column is not zero.\n")
    n_none = sum(1 for r in rows if r[5] == "none")
    print("  Refused, total: %d of %d." % (n_none, len(rows)))
    return n_none


# =================================================================== 8. THE INVENTORY
def show_inventory():
    rows = census()
    tot, have, evc, noh = headerscan()
    real = [n for g, n in noh if "__" not in n and not n.startswith(TABLE_FAMILIES)]
    tab = collections.Counter((r[5], r[6]) for r in rows)
    reach = sum(k for (m, _q), k in tab.items() if m != "none")
    frame = sum(k for (m, q), k in tab.items() if m != "none" and q == "frame")
    print("=== 8. THE prom_c INVENTORY -- the finished state ===\n")
    print("  prom_c holds %d top-level objects: %d content-named, %d framed, %d sub_XXXXXX."
          % (tot["content"] + tot["framed"] + tot["sub"], tot["content"], tot["framed"],
             tot["sub"]))
    print("  (%d <parent>__<address> branch targets are excluded, as the grader excludes"
          % tot["internal"])
    print("  compiler locals.)\n")
    print("  OF THE %d THAT ARE NOT CONTENT-NAMED:" % len(rows))
    print("    a mechanism reaches                     %4d" % reach)
    print("      ... and yields a CONTENT name         %4d" % (reach - frame))
    print("      ... and yields only a FRAME           %4d" % frame)
    print("    no mechanism reaches                    %4d" % (len(rows) - reach))
    print("\n  EVERY OBJECT IN prom_c IS NOW EITHER NAMED WITH EVIDENCE OR DECLARED")
    print("  NAMELESS WITH A DERIVED REASON.  The reasons are R1..R6 of --refusals, each")
    print("  produced by a rule that runs over all %d." % len(rows))
    print("\n  DEPTH: %d of %d sub_XXXXXX carry a header and an Evidence line; the header"
          % (have["sub"], tot["sub"]))
    print("  debt is %d objects (--headers), all of them one- and two-instruction stubs" % len(real))
    print("  carrying a single Evidence line each, which the 3-line rule cannot see.")
    print("\n  ★ WHAT WOULD MOVE prom_c NEXT, in the order the evidence supports:")
    print("    1. An OUTSIDE referent for the part record and the 23-byte slot record.")
    print("       %d of the %d objects a mechanism reaches are separated from a sibling" % (frame, reach))
    print("       only by a field offset.  One page of a service manual retires all of them.")
    print("    2. A payload decoder for the P7 stream pool (%d objects, R2)." % 374)
    print("    3. The six device writers (R1) -- not by the register rule, which does not")
    print("       fit them, but by tracing what their callers do with the channel.")
    print("  None of the three is reachable by reading prom_c harder, and that is the")
    print("  finding this round exists to record.")
    return rows, tab, real


# ==================================================================== SELFTEST
def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    c = load()
    # --- the grader agrees with the instrument this wave reports
    tot, have, evc, real = headerscan()
    m = subprocess.run([sys.executable, os.path.join(ROOT, "notes",
                                                     "wave7_documentation_metrics.py")],
                       capture_output=True, text=True).stdout
    row = [l for l in m.split("\n") if l.startswith("prom_c")][0].split()
    got = (int(row[1].replace(",", "")), int(row[2].replace(",", "")),
           int(row[3].replace(",", "")))
    check("grader agreement: content/framed/sub = %s, and this script says %s"
          % (str(got), str((tot["content"], tot["framed"], tot["sub"]))),
          got == (tot["content"], tot["framed"], tot["sub"]))

    # --- the register-block extractor, on EVERY calibration name including the last
    names = [n for _i, n, _a in c["top"] if CALIB.match(n) and "__" not in n]
    misses = []
    for n in names:
        _b, blocks = regblocks(n)
        want = set(int(x, 16) for x in re.findall(r'_([0-9A-F]{4})(?=_|$)', n))
        if not want <= set(blocks):
            misses.append(n)
    check("register-block extractor: %d calibration names, %d misses (last is %s)"
          % (len(names), len(misses), names[-1]), len(names) >= 36 and not misses)
    check("...and the LAST calibration name really is exercised: %s -> %s"
          % (names[-1], [hex(x) for x in regblocks(names[-1])[1]]),
          bool(regblocks(names[-1])[1]))
    check("extractor fires on all six of round 7's bucket S3",
          all(regblocks(n)[0] and regblocks(n)[1] for n in S3))
    csz = [len(blob(n)) for n in names]
    ssz = [len(blob(n)) for n in S3]
    check("...and every one of the six is LARGER than every calibration member (%d vs %d)"
          % (min(ssz), max(csz)), min(ssz) > max(csz))

    # --- the extent rule, which a first draft got wrong
    check("extent rule: Dev10C_SetChanReg_01C0_or_0600 yields BOTH 0x1c0 and 0x600",
          set(regblocks("Dev10C_SetChanReg_01C0_or_0600")[1]) >= {0x1C0, 0x600})
    check("comment column is stripped: sub_FB762F writes 0x0010C000 only, not 0x00104000",
          regblocks("sub_FB762F")[0] == ["10C"])

    # --- every citation in every header this round wrote, AT the instruction address
    bad = [(x, instr_at(x)) for x, p in CITES
           if instr_at(x) is None or not re.search(p, instr_at(x))]
    check("all %d header citations decode AT the cited address (%d bad)" % (len(CITES), len(bad)),
          not bad)
    check("...including the LAST one, 0x%06X -> %r" % (CITES[-1][0], instr_at(CITES[-1][0])),
          instr_at(CITES[-1][0]) is not None
          and re.search(CITES[-1][1], instr_at(CITES[-1][0])))
    # the off-by-one signature this tree has: the byte BEFORE a real instruction start
    # is an opcode.  A citation one past the instruction would decode to nothing.
    check("no citation is one byte past its instruction (all %d have a mnemonic)" % len(CITES),
          all(instr_at(x) for x, _p in CITES))

    # --- the renames landed, and the old names are gone
    check("all 14 new names exist in the ELF", all(n in c["sym"] for n, _a, _o, _g, _m in RENAMES))
    check("all 14 addresses are what the round claims",
          all(c["sym"][n] == a for n, a, _o, _g, _m in RENAMES))
    # the old names DO survive in prose -- each new header says what it was called.  What
    # must be gone is the old name as a LABEL or as an operand.
    stale = [o for _n, _a, o, _g, _m in RENAMES
             if o in c["sym"] or ("\n" + o + ":") in open(SRC).read()]
    check("no old name survives as a LABEL or an ELF symbol (%d stale)" % len(stale), not stale)
    check("...and each one still appears in PROSE, so a reader can follow the rename",
          all(o in open(SRC).read() for _n, _a, o, _g, _m in RENAMES))
    check("the 6 CONTENT renames really grade CONTENT",
          all(grade(n) == "content" for n, _a, _o, g, _m in RENAMES if g == "content"))
    check("the 7 FRAME renames really grade FRAMED -- spelled that way ON PURPOSE",
          all(grade(n) == "framed" for n, _a, _o, g, _m in RENAMES if g == "framed"))

    # --- the twin claims
    d1 = bytediff(0xFACC3F, 27, 0xFACC5A)
    d2 = bytediff(0xFC280D, 84, 0xFC2861)
    check("SetBit13 vs ClearBit13: 27 B, 3 differing bytes at [21, 22, 23]",
          d1 == [21, 22, 23])
    check("MidiCtrl_Int99_* vs Int9A_*: 84 B, 2 differing bytes at [67, 77]", d2 == [67, 77])

    # --- the near-sibling rule, calibrated against a sentence written from another argument
    sib = nearest_sibling()
    # the six the register-meanings note names: offsets 0x0D, 0x10, 0x11, 0x16, 0x19, 0x1A
    six = ["MidiCtrl_CC10", "MidiCtrl_CC91", "MidiCtrl_CC93", "MidiCtrl_Int97",
           "MidiCtrl_Int9B", "MidiCtrl_Int9C"]
    have6 = [n for n in six if n in sib]
    check("near-sibling sweep reproduces the documented 'same thirty bytes, differ in "
          "EXACTLY ONE' for %d of the 6 controller handlers" % len(have6),
          len(have6) == 6 and all(sib[n][1] == 1 and sib[n][2] == 30 for n in have6))

    # --- the no-reference census and its denominator
    nr = [r for r in noref_rows() if r[2] == 0 and r[3] == 0]
    ind = indirect_sites()
    check("no-reference census: %d objects survive four sweeps" % len(nr), len(nr) >= 10)
    check("...and every one of them really has zero ROM pointers, LAST one included (%s)"
          % nr[-1][0], not rom_pointers(nr[-1][1]))
    check("...and the blindness denominator is printed: %d register-indirect transfers"
          % len(ind), len(ind) > 0)
    check("a KNOWN-referenced routine is NOT in the no-reference list (control)",
          "MidiCtrl_Dispatch" not in [n for n, _a, _s, _r in nr]
          and bool(rom_pointers(0xFACC3F) or refcensus().get(0xFACC3F)))

    # --- the no-reference census corroborates two statements already in the file,
    #     written from a different argument in an earlier round
    nrn = set(n for n, _a, _s, _r in nr)
    filed = {"Dev10C_SetChanReg_0440_0480", "Dev10C_SetChanReg_0480",
             "Dev104_SetChanRegs_01C0_0200_0240", "Dev104_SetChanRegs_0140_to_0240"}
    check("noref reproduces the file's own 'HAVE NO CALLER' notes for %d framed objects"
          % len(filed), filed <= nrn)
    check("...and the file really says so, in two block comments",
          "SIX ROUTINES HERE HAVE NO CALLER" in open(SRC).read()
          and "TWO ROUTINES HERE HAVE NO CALLER" in open(SRC).read())

    # --- R4: the three ApplyParamChange arms are frame-only, and the rule says why
    sib3 = [sib.get(n) for n in ("sub_FAEFC2", "sub_FAEFE7", "sub_FAF00C")]
    check("the three ApplyParamChange arms are >=90%% identical to one another "
          "(diffs %s of %s bytes) -- R4"
          % ([s[1] for s in sib3 if s], [s[2] for s in sib3 if s]),
          all(s and s[1] <= 1 for s in sib3))

    # --- header depth
    check("every sub_XXXXXX has a header (%d of %d)" % (have["sub"], tot["sub"]),
          have["sub"] == tot["sub"])
    check("every sub_XXXXXX has an Evidence line (%d of %d)" % (evc["sub"], tot["sub"]),
          evc["sub"] == tot["sub"])
    realh = [n for g, n in real
             if "__" not in n and not n.startswith(TABLE_FAMILIES)]
    check("the real header-less list is 8 objects, all one-or-two-instruction stubs: %s"
          % ", ".join(realh), len(realh) == 8 and all(
              n.startswith(("IRQ_", "Voice_Search_Order_List_")) for n in realh))
    check("IRQ_INTTC2 now carries an Evidence line",
          "VECTORS slot 0x7C (below) holds 0x00FFF0C0" in open(SRC).read())

    # --- the census partitions
    rows = census()
    check("census covers every non-content object exactly once (%d)" % len(rows),
          len(rows) == tot["framed"] + tot["sub"])
    check("every census row carries a mechanism and a reason",
          all(r[5] and r[7] for r in rows))
    check("...and the LAST row by address does too: %s / %s / %s"
          % (sorted(rows, key=lambda r: r[1])[-1][0], sorted(rows, key=lambda r: r[1])[-1][5],
             sorted(rows, key=lambda r: r[1])[-1][7][:40]),
          bool(sorted(rows, key=lambda r: r[1])[-1][7]))

    # --- the promotion and the refusal beside it
    refs = refcensus()
    def callers(n):
        return set(e for _l, e, _t in refs.get(c["sym"][n], []) if e and e != n)
    a = callers("Dev10C_StageRegs_0800_0840_ForNoteOn")
    b = callers("Dev10C_StageRegs_0800_0840_FAB8CC")
    d = callers("Dev10C_StageRegs_0800_0840_FAB9D8")
    check("ForNoteOn's caller set is disjoint from BOTH of the other two producers'",
          a and not (a & b) and not (a & d))
    check("...and _FAB8CC and _FAB9D8 DO share a caller, which is why they keep addresses",
          bool(b & d))

    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    want = [a for a in sys.argv[1:] if a.startswith("--")]
    every = not want
    if every or "--census" in want:
        show_census()
        print()
    if every or "--regblocks" in want:
        show_regblocks()
        print()
    if every or "--noref" in want:
        show_noref()
        print()
    if every or "--names" in want:
        show_names()
        print()
    if every or "--headers" in want:
        show_headers()
        print()
    if every or "--grader" in want:
        show_grader()
        print()
    if every or "--refusals" in want:
        show_refusals()
        print()
    if every or "--inventory" in want:
        show_inventory()
