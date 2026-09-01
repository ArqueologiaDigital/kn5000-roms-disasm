#!/usr/bin/env python3
r"""The DSP channel-register driver: ONE SOURCE, TWO PROCESSORS -- and the proof.

WHAT QUESTION THIS ANSWERS
--------------------------
  "Did folding prom_a 0xF85F0F-0xF85FF8 and prom_c 0xF98000-0xF980E9 into ONE
   source move the text, or change it?"

  The byte gate (`python3 scripts/analysis/assert_byte_identical.py`) proves the
  two ROMs still rebuild.  It CANNOT see a lost comment: comments assemble to
  nothing.  This script is the other half, and it is the same division of labour
  `notes/kernel_join_probe.py` has for the 2,180-byte kernel merge one level up.

★★ THE DUAL BUILD IS THE PROOF, AND IT IS THE WHOLE POINT.  `dsp/dsp_channel_regs.s`
  assembles to 234 bytes of prom_a AND 234 bytes of prom_c, both byte-identical
  to the original EPROMs.  Two listings that look alike prove nothing; one source
  that reproduces both images cannot be a resemblance.  If either `.inc`'s single
  equate is wrong by one byte, one of the two images stops rebuilding.

MODES
-----
  python3 notes/sound/wsa1_dsp_join_probe.py --rom      ★ ROM-ONLY: 231 of 234,
                                                          computed from the two
                                                          EPROM images alone, with
                                                          the misalignment null.
                                                          Checkable without ever
                                                          reading the disassembly.
  python3 notes/sound/wsa1_dsp_join_probe.py --pairs    the 97-instruction
                                                          pairing, from the two
                                                          PRE-MERGE blocks at
                                                          BASE_REV
  python3 notes/sound/wsa1_dsp_join_probe.py --emit     regenerate the merged
                                                          source and the two .inc
  python3 notes/sound/wsa1_dsp_join_probe.py --verify   ★ the preservation proof
  python3 notes/sound/wsa1_dsp_join_probe.py --images    what the merge did to
                                                          each IMAGE's text
  python3 notes/sound/wsa1_dsp_join_probe.py --selftest the instrument's own
                                                          controls

★ NOTHING HERE IS SLICED BY LINE NUMBER.  The two pre-merge blocks are found by
  their LABELS and by walking 97 instructions from the first of them, so the tool
  still answers after the very edit it exists to verify -- which moved code out of
  both files and would have invalidated any absolute line range.  ROOT comes from
  `__file__`, not from a path typed into the file.

★ AND NOTHING HERE PINS A COUNT AS AN INVARIANT.  `--selftest` asserts SHAPES: the
  regions start at the labels they should, the two sides hold the same number of
  instructions, every differing byte is a byte of the base literal and no other,
  a misaligned comparison does NOT match, and the equates are the values the ROMs
  carry.  A pinned "231" would keep passing the day someone edits a comment and
  would say nothing about whether the merge was faithful.

WHAT IT DOES NOT DO
-------------------
  It certifies no bytes.  `scripts/analysis/assert_byte_identical.py` is the only
  certificate, and `scripts/analysis/assert_images_assemble.py` is what catches an
  image that stopped assembling while the gate stayed green.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))          # .../wsa1
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, HERE)
from asm_source import git_show                                  # noqa: E402
# ★ The ROM-side numbers are NOT recomputed here.  They live in the probe that
#   established them, and importing rather than copying is what keeps the two
#   files from drifting into two different "231".
from wsa1_dsp_driver_shared import diff as rom_diff, LEN, PA, PC, ROUTINES  # noqa: E402

# The revision the two pre-merge blocks are read from.  ⚠ PINNED, like
# notes/prom_c_split.py's BASE_COMMIT: this tool answers "did THE MERGE preserve
# the text", a question about one commit, and the answer must stay true forever.
BASE_REV = "fe5d86362949e2c2f85d5197ccb3d8c2aabb1e75"

PROM_A = "prom_a/wsa1_prom_a.s"
PROM_C = "prom_c/boot/boot_and_main.s"
MERGED = "dsp/dsp_channel_regs.s"
INC = {"a": "dsp/dsp_channel_regs_maincpu.inc",
       "c": "dsp/dsp_channel_regs_subcpu.inc"}
BASE_EQU = "DSP_REGS_BASE"
DSP_BASE = {"a": 0x007F0000, "c": 0x00E00000}
NINSN = 97
# prom_c's split files carry an extraction header above the moved block; it
# belongs to the FILE, not to the driver, so the block starts after it.
SENTINEL = "; >>> END OF EXTRACTION HEADER"

# The four routines' entry labels, in address order.  These are the ANCHORS --
# everything else is found relative to them.
ENTRY = ["DSP_ChannelRegs_Init", "DSP_ChannelRegs_Write8",
         "DSP_WriteAllChannelRegs", "DSP_WriteChannelRegs_Inner"]

# ---------------------------------------------------------------------------
# ★ THE ADOPTIONS.  The 97 instruction pairs say the same thing 86 times and are
#   spelled differently 11 times.  Each of those 11 is listed here with the side
#   the merge KEEPS and why -- "whichever text NAMES MORE THINGS", the rule the
#   kernel merge used.  --verify requires that the DROPPED spelling still appear
#   verbatim in the merged line's trailing comment, so no text is lost.
#   The three base-literal sites are not an adoption: they are the one per-CPU
#   value, named once in each .inc.
# ---------------------------------------------------------------------------
ADOPTIONS = {
    0:  ("a", "prom_c spells the four bytes raw (`link32 0xEE,0x0C,0xF8,0xFF`); "
              "prom_a's `link XIZ,0xfff8` names the frame register and its size"),
    7:  ("a", "prom_c spells the PC-relative displacement as arithmetic on two "
              "addresses; prom_a names the callee"),
    10: ("a", "as +0x013"),
    13: ("a", "as +0x013"),
    16: ("a", "as +0x013"),
    24: ("c", "the loop label.  prom_c's spelling is the primary label and "
              "prom_a's is emitted at the same address, so both still resolve"),
    25: ("a", "`unlk32 xiz` is the byte-emitter spelling; `unlk XIZ` is the "
              "mnemonic"),
    44: ("a", "as +0x013"),
    48: ("a", "as +0x013"),
    52: ("a", "as +0x013"),
    56: ("a", "as +0x013"),
    57: ("c", "★ prom_a GAINS AN HONEST NUMBER.  `inc 0,XSP` spells the ENCODED "
              "FIELD; `inc 8, xsp` spells the +8 the CPU actually performs, and "
              "both assemble to ef 60"),
}
BASE_SITES = (18, 32, 67)      # ordinals whose operand becomes DSP_REGS_BASE

# ⚠ COMMENT LINES THE MERGE DID NOT CARRY OVER VERBATIM.  Enumerated, never
#   done quietly -- the kernel merge set that standard with its own CORRECTIONS.
#   Empty means every comment line of both blocks survives character for
#   character.
CORRECTIONS = {}

# ⚠ AND CLAIMS THE MOVE MADE WRONG *OUTSIDE* THE BLOCK.  A range banner or an
#   index row that names an address range which has just left the file is a
#   silent lie the byte gate cannot see -- the kernel merge hit exactly this and
#   recorded it rather than fixing it quietly.  Each is listed here with the text
#   before and after; --images uses the net line count to account for prom_a's
#   comment delta, so an unlisted edit shows up as UNEXPLAINED rather than being
#   absorbed.
HOST_CORRECTIONS = [
    (PROM_A, 3, 4,
     "the file index said `0xF85E8A-0xF85F58  207  EntryPoint_Records ..., and "
     "DSP_ChannelRegs_Init` over two rows plus `0xF85F59-0xF85FF8  160  the DSP "
     "/ tone-generator register writers`.  Both ranges lost their code to the "
     "shared source, so they are now `0xF85E8A-0xF85F0E  133` (the records and "
     "the refresh task, which DID stay) and `0xF85F0F-0xF85FF8  234` naming "
     "dsp/dsp_channel_regs.s.  Four rows where there were three: +1 line."),
    (PROM_A, 1, 1,
     "the region banner `; 0xF85E8A-0xF85F58 -- the task entry-point records, "
     "and the DSP refresh task` overstated its range by the 74 bytes of "
     "DSP_ChannelRegs_Init, which is no longer under it.  Now 0xF85E8A-0xF85F0E."),
]

MERGED_HEADER = '''\
; ==============================================================================
; Technics SX-WSA1R -- THE DSP CHANNEL-REGISTER DRIVER, ONE SOURCE FOR BOTH CPUs
; ==============================================================================
;
; The WSA1R has two Toshiba TMP95C061s and each of them drives a DSP register
; file of its own.  They drive it with THE SAME 234 BYTES.  Until now that fact
; lived in a probe; this file is the fact itself: prom_a and prom_c both
; `.include` it, and both ROMs still rebuild byte for byte.
;
;     prom_a/wsa1_prom_a.s        CPU 1, "MICROCOMPUTER (MAIN)", IC1/IC12
;         .include "dsp/dsp_channel_regs_maincpu.inc"
;         .include "dsp/dsp_channel_regs.s"     ->  0xF85F0F-0xF85FF8
;
;     prom_c/boot/boot_and_main.s CPU 2, "MICROCOMPUTER (SUB)",  IC2/IC28
;         .include "dsp/dsp_channel_regs_subcpu.inc"
;         .include "dsp/dsp_channel_regs.s"     ->  0xF98000-0xF980E9
;
;     every pair of addresses differs by exactly 0x120F1, first slot to last
;
; ★★ THE BYTE GATE IS THE PROOF, AND IT IS THE WHOLE POINT.
;
;     python3 scripts/analysis/assert_byte_identical.py
;
;   ONE SOURCE that assembles to 234 bytes of prom_a and 234 bytes of prom_c,
;   both byte-identical to the original EPROMs, cannot be a resemblance.  If the
;   single equate in either dsp/dsp_channel_regs_*.inc is wrong by one byte, that
;   image stops rebuilding.
;
; ------------------------------------------------------------------------------
; HOW THE TWO COPIES DIFFER, measured before this file was written
; ------------------------------------------------------------------------------
;
;     python3 notes/sound/wsa1_dsp_driver_shared.py            <- from the ROMs
;     python3 notes/sound/wsa1_dsp_join_probe.py --pairs       <- from the sources
;     python3 notes/sound/wsa1_dsp_join_probe.py --verify      <- the preservation proof
;
;   234 bytes on each side.  231 OF THEM ARE THE SAME BYTE.  The three that are
;   not are A23..A16 of each routine's base literal -- 0x7F on CPU 1, 0xE0 on
;   CPU 2 -- at block offsets 0x034, 0x05A and 0x0A8, and nothing else:
;
;       0xF85F43 / 0xF98034      `ld XBC,DSP_REGS_BASE`   in DSP_ChannelRegs_Init
;       0xF85F69 / 0xF9805A      `ld XBC,DSP_REGS_BASE`   in DSP_ChannelRegs_Write8
;       0xF85FB7 / 0xF980A8      `ld XIY,DSP_REGS_BASE`   in DSP_WriteChannelRegs_Inner
;
;   ★ AND THE NULL SAYS IT IS NOT AN ARTEFACT OF COMPARING TWO BLOBS.  The same
;   comparison at eight neighbouring alignments scores 5 to 19 of 234.  Only the
;   true alignment matches.
;
;   As SOURCE the two blocks are %(NINSN)d instructions each, pairing 1:1 in order.
;   %(SAME)d of the %(NINSN)d pairs already said the same thing in two house styles; %(ADOPT)d are
;   enumerated as ADOPTIONS in notes/sound/wsa1_dsp_join_probe.py, each with the
;   side kept and the reason; %(NBASE)d are the one per-CPU value.
;
;   ⚠ Those numbers are FORMATTED FROM THE MEASUREMENT, not typed: they cannot
;     disagree with what --pairs prints.
;
; ★ There is NO `.if CPU_MAINCPU` anywhere in this file, and that is deliberate.
;   Wrapping code in conditionals would duplicate every differing line at its
;   site; ONE equate names the one difference and leaves the body genuinely
;   shared.  There is exactly one per-CPU value in 234 bytes.
;
; ------------------------------------------------------------------------------
; WHAT THE MERGE DID TO THE TEXT -- so a reviewer can check it rather than trust it
; ------------------------------------------------------------------------------
;
; * Comments and headers were MOVED, not rewritten.  BOTH files' headers are
;   here, each under a banner saying which file it came from.  They were written
;   by different lanes, cite different call sites and disagree about what is
;   established, so keeping one would have destroyed real documentation.
;   `--verify` fails on a single changed character.
; * Both files' LABELS are kept.  The one address the two files name differently
;   -- prom_c's `DSP_ChannelRegs_Init__loop`, prom_a's `DSP_ChannelRegs_Init_Loop`
;   -- carries BOTH labels, so a reference to either still resolves.
; * Each instruction line carries BOTH addresses, the bytes (both images' when
;   they differ), the DROPPED spelling where the two files disagreed (`c:` or
;   `a:`), and both files' prose separated by ` / ` where they wrote different
;   prose.  prom_a gains prom_c's per-channel and per-register annotations; prom_c
;   gains prom_a's addresses and bytes, which its hand-written block never had.
; * ⚠ NO COMMENT LINE WAS REWRITTEN.  CORRECTIONS in the probe is EMPTY, and it
;   is printed by --verify rather than assumed.
;
; ------------------------------------------------------------------------------
; ⚠ WHAT THIS FILE DOES **NOT** ESTABLISH
; ------------------------------------------------------------------------------
; That the two processors run the same driver is a fact about the CODE.  What the
; eight per-channel registers HOLD is not established for either machine, and
; "DSP" is a name BORROWED from the KN5000 lane whose byte-identical routine
; drives its own register file at 0x00130000.  prom_c's header below argues that
; borrowing at length and marks its limit; nothing here strengthens it.
;
; ------------------------------------------------------------------------------
; ⚠ REGENERATING THIS FILE
; ------------------------------------------------------------------------------
; `python3 notes/sound/wsa1_dsp_join_probe.py --emit` produced the first version
; from prom_a's and prom_c's blocks as they stood at BASE_REV.  It is kept as the
; RECORD OF THE MERGE, not as a build step: this file is the source now, and a
; re-run would discard anything edited here.  `--verify` re-checks it against both
; originals in git and is the thing to run after editing.
; ==============================================================================

'''

INC_HEADER = '''\
; ============================================================================
; %(path)s -- what the SHARED DSP driver means on the
; %(WHICH)s processor of the Technics SX-WSA1R.
; ============================================================================
;
; dsp/dsp_channel_regs.s is ONE source assembled into BOTH CPUs.  The ONLY thing
; that differs between the two copies is named here and nowhere else, so the
; shared body never has to ask which processor it is being built for.
;
; ⚠ THIS VALUE IS A MEASUREMENT, not a decision.  It is the literal the ROM
;   carries at the three sites listed by
;       python3 notes/sound/wsa1_dsp_join_probe.py --pairs
;   and if it is wrong by a single byte the image stops rebuilding:
;       python3 scripts/analysis/assert_byte_identical.py
;
; ⚠ THE ADDRESS IS NOT DERIVABLE FROM THE SIBLING.  The KN5000 sub-CPU runs the
;   same routines against 0x00130000; copying its comment across would have
;   written a peripheral address that does not exist on this machine, and the
;   byte gate would never have noticed -- it would simply have stopped matching
;   here, which is exactly why the equate is a measurement.

.equ %(EQU)s, 0x%(VAL)08X\t; %(NOTE)s
'''

INC_NOTE = {
    "a": "CPU 1's DSP register file: 8-bit index at +0, data at +2",
    "c": "CPU 2's DSP register file: 8-bit index at +0, data at +2",
}
INC_WHICH = {"a": ("MAIN", "maincpu (CPU 1, prom_a)"),
             "c": ("SUB", "subcpu (CPU 2, prom_c)")}


# ---------------------------------------------------------------------------
# reading the two PRE-MERGE blocks, by label
# ---------------------------------------------------------------------------
LABEL_RE = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
ADDR_RE = re.compile(r'\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} ?)+?)(?:\s\s+(.*))?$')


def kind(line):
    s = line.strip()
    if not s:
        return "blank"
    if s.startswith(";"):
        return "comment"
    if LABEL_RE.match(s):
        return "label"
    return "code"


def block(text):
    """The driver's lines in `text`, found by ANCHOR, never by line number.

    Starts after whatever precedes the block -- the last code line before the
    first entry label, or prom_c's extraction-header sentinel -- and ends on the
    NINSN'th instruction after that label.  ⚠ RAISES if the anchors are not
    there: returning a short block is the failure this shape prevents.
    """
    lines = text.split("\n")
    first = None
    for i, ln in enumerate(lines):
        if LABEL_RE.match(ln) and LABEL_RE.match(ln).group(1) == ENTRY[0]:
            first = i
            break
    if first is None:
        raise LookupError("no `%s:` label -- the block cannot be anchored"
                          % ENTRY[0])
    start = 0
    for i in range(first):
        if kind(lines[i]) == "code" or lines[i].startswith(SENTINEL):
            start = i + 1
    n, end = 0, None
    for i in range(first, len(lines)):
        if kind(lines[i]) == "code":
            n += 1
            if n == NINSN:
                end = i
                break
    if end is None:
        raise LookupError("only %d instructions after `%s:`, wanted %d"
                          % (n, ENTRY[0], NINSN))
    return lines[start:end + 1]


def code_of(line):
    return line.split(";", 1)[0].strip()


def comment_of(line):
    return line.split(";", 1)[1].strip() if ";" in line else ""


def norm(text):
    """Two house styles, one instruction.  Case, whitespace and the WIDTH of a
    literal are style; the value is not.  `pushw 0x00` and `pushw 0x0000` are the
    same instruction and this is what says so."""
    t = re.sub(r'\s+', ' ', text.strip().lower())
    t = re.sub(r'0x([0-9a-f]+)', lambda m: str(int(m.group(1), 16)), t)
    t = re.sub(r'\b0+(\d)', r'\1', t)
    return re.sub(r'[ ,]+', ' ', t)


def rows(rev=BASE_REV):
    """The 97 instruction pairs, with the ROM bytes for both images."""
    a = block(git_show(PROM_A, rev, root=ROOT))
    c = block(git_show(PROM_C, rev, root=ROOT))
    ac = [l for l in a if kind(l) == "code"]
    cc = [l for l in c if kind(l) == "code"]
    if len(ac) != len(cc):
        raise AssertionError("%d prom_a instructions against %d prom_c -- the "
                             "1:1 pairing this tool assumes does not hold"
                             % (len(ac), len(cc)))
    ra = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    rc = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
    out, off = [], 0
    for x, y in zip(ac, cc):
        m = ADDR_RE.match(comment_of(x) and " " + comment_of(x) or "")
        if not m:
            raise AssertionError("prom_a line has no `; ADDR bytes` comment: %r" % x)
        addr, byts = int(m.group(1), 16), m.group(2).strip()
        n = len(byts.split())
        if addr != PA + off:
            raise AssertionError("prom_a address %06X where %06X was expected -- "
                                 "the block is not contiguous" % (addr, PA + off))
        out.append(dict(a_code=code_of(x), c_code=code_of(y), addr=addr,
                        caddr=PC + off, n=n, byts=byts,
                        abytes=ra[addr - 0xF80000:addr - 0xF80000 + n].hex(" "),
                        cbytes=rc[PC + off - 0xF80000:PC + off - 0xF80000 + n].hex(" "),
                        a_prose=(m.group(3) or "").strip(),
                        c_prose=comment_of(y)))
        off += n
    if off != LEN:
        raise AssertionError("the 97 instructions cover %d bytes, not %d" % (off, LEN))
    return a, c, out


# ---------------------------------------------------------------------------
# --emit
# ---------------------------------------------------------------------------
LABELS_AT = {0: [ENTRY[0]],
             21: ["DSP_ChannelRegs_Init__loop", "DSP_ChannelRegs_Init_Loop"],
             27: [ENTRY[1]], 34: ["DSP_ChannelRegs_Write8__loop"],
             41: [ENTRY[2]], 61: [ENTRY[3]]}
BANNER_A = ("; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor "
            ">>>>>>>>>>")
BANNER_C = ("; >>>>>> moved from prom_c/boot/boot_and_main.s -- CPU 2, the SUB "
            "processor >>>")


def chunks(lines):
    """The comment/blank run that precedes each entry label, in order."""
    out, cur, seen = [], [], 0
    for ln in lines:
        m = LABEL_RE.match(ln)
        if m and m.group(1) in ENTRY:
            out.append(cur)
            cur = []
            seen += 1
        elif kind(ln) in ("comment", "blank"):
            cur.append(ln)
        else:
            cur = []
    if seen != len(ENTRY):
        raise AssertionError("found %d of the %d entry labels" % (seen, len(ENTRY)))
    return out


def emit_body(a_lines, c_lines, rs):
    ach, cch = chunks(a_lines), chunks(c_lines)
    ent = {i: e for i, e in zip(sorted(k for k in LABELS_AT
                                       if LABELS_AT[k][0] in ENTRY), ENTRY)}
    out = []
    for i, r in enumerate(rs):
        if i in ent:
            k = ENTRY.index(ent[i])
            for banner, ch in ((BANNER_A, ach[k]), (BANNER_C, cch[k])):
                body = [l for l in ch]
                while body and not body[0].strip():
                    body.pop(0)
                while body and not body[-1].strip():
                    body.pop()
                if not body:
                    continue
                out += ["", banner] + body
            out.append("")
        for lb in LABELS_AT.get(i, []):
            out.append(lb + ":")
        out.append(merged_line(i, r))
    return "\n".join(out).lstrip("\n") + "\n"


def merged_line(i, r):
    dropped = ""
    if i in BASE_SITES:
        code = re.sub(r'0x0*[0-9a-fA-F]{6,8}', BASE_EQU, r["a_code"])
    elif i in ADOPTIONS:
        side = ADOPTIONS[i][0]
        code = re.sub(r'\s+', ' ', r["%s_code" % side])
        other = "c" if side == "a" else "a"
        dropped = "%s: %s" % (other, re.sub(r'\s+', ' ', r["%s_code" % other]))
    else:
        code = r["a_code"]
    by = (r["byts"] if r["abytes"] == r["cbytes"]
          else "a=%s c=%s" % (r["abytes"], r["cbytes"]))
    ap, cp = r["a_prose"], r["c_prose"]
    prose = ap if ap == cp else " / ".join(x for x in (ap, cp) if x)
    tail = "; %06X/%06X  %s" % (r["addr"], r["caddr"], by)
    if dropped:
        tail += "   " + dropped
    if prose:
        tail += "   " + prose
    return "\t%-45s%s" % (code, tail)


def cmd_emit():
    a, c, rs = rows()
    same = sum(1 for i, r in enumerate(rs)
               if norm(r["a_code"]) == norm(r["c_code"]))
    head = MERGED_HEADER % dict(NINSN=len(rs), SAME=same, ADOPT=len(ADOPTIONS),
                                NBASE=len(BASE_SITES))
    write(os.path.join(ROOT, MERGED), head + emit_body(a, c, rs))
    for side in ("a", "c"):
        short, long_ = INC_WHICH[side]
        write(os.path.join(ROOT, INC[side]),
              INC_HEADER % dict(path=INC[side], WHICH=short, EQU=BASE_EQU,
                                VAL=DSP_BASE[side], NOTE=INC_NOTE[side]))
        print("  wrote %s   (%s)" % (INC[side], long_))
    print("  wrote %s" % MERGED)
    return 0


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w", encoding="utf-8").write(text)


# ---------------------------------------------------------------------------
# --pairs
# ---------------------------------------------------------------------------
def cmd_pairs():
    _a, _c, rs = rows()
    print("THE 97 INSTRUCTION PAIRS, prom_a against prom_c, at BASE_REV %s"
          % BASE_REV[:8])
    print("=" * 78)
    print("  #  prom_a addr  prom_c addr  bytes                  verdict")
    same = 0
    for i, r in enumerate(rs):
        if r["abytes"] == r["cbytes"]:
            if norm(r["a_code"]) == norm(r["c_code"]):
                v, same = "same instruction, same bytes", same + 1
            else:
                v = "same bytes, TWO SPELLINGS -- adoption %s" % (
                    ADOPTIONS.get(i, ("?",))[0])
        else:
            v = "★ PER-CPU: a=%s c=%s" % (r["abytes"], r["cbytes"])
        print("%3d  0x%06X     0x%06X     %-22s %s"
              % (i, r["addr"], r["caddr"], r["byts"], v))
    print("\n%d of %d pairs identical after normalising house style; "
          "%d adoptions; %d per-CPU sites."
          % (same, len(rs), len(ADOPTIONS), len(BASE_SITES)))
    print("\nthe %d ADOPTIONS -- the side kept, and why:" % len(ADOPTIONS))
    for i in sorted(ADOPTIONS):
        side, why = ADOPTIONS[i]
        print("  +0x%03X  keep prom_%s   %s" % (rs[i]["addr"] - PA, side, why))
    print("\nthe %d PER-CPU sites -- one equate, three uses.  The instruction is at"
          % len(BASE_SITES))
    print("block offset +0xNNN; the byte that differs is its FOURTH, A23..A16:")
    for i in BASE_SITES:
        print("  instruction +0x%03X  0x%06X/0x%06X   differing byte +0x%03X   %s"
              % (rs[i]["addr"] - PA, rs[i]["addr"], rs[i]["caddr"],
                 rs[i]["addr"] - PA + 3, rs[i]["a_code"]))
    return 0


# ---------------------------------------------------------------------------
# --rom
# ---------------------------------------------------------------------------
def cmd_rom():
    d = rom_diff()
    print("FROM THE TWO EPROM IMAGES ALONE -- no disassembly is read")
    print("=" * 78)
    print("prom_a 0x%06X..0x%06X   prom_c 0x%06X..0x%06X   %d bytes"
          % (PA, PA + LEN - 1, PC, PC + LEN - 1, LEN))
    print("%d of %d bytes identical; %d differ" % (LEN - len(d), LEN, len(d)))
    for i, x, y in d:
        print("   +0x%03X (%3d)   prom_a 0x%06X = 0x%02X   prom_c 0x%06X = 0x%02X"
              % (i, i, PA + i, x, PC + i, y))
    print("\nNULL CONTROL -- the same comparison at eight nearby alignments:")
    for s in (-4, -3, -2, -1, 1, 2, 3, 4):
        print("   shift %+d bytes: %3d of %d identical"
              % (s, LEN - len(rom_diff(s)), LEN))
    print("\n  ★ Only the true alignment matches, so 231/234 is a fact about the")
    print("    code and not about whatever surrounds it.  Full argument and the")
    print("    routine table: notes/sound/wsa1_dsp_driver_shared.py")
    return 0


# ---------------------------------------------------------------------------
# --verify -- THE PRESERVATION PROOF
# ---------------------------------------------------------------------------
def cmd_verify():
    a, c, rs = rows()
    merged = open(os.path.join(ROOT, MERGED), encoding="utf-8").read()
    mlines = merged.split("\n")
    mset = set(mlines)
    fails = []
    print("PRESERVATION OF THE TWO PRE-MERGE BLOCKS  (BASE_REV %s)" % BASE_REV[:8])
    print("=" * 78)

    # 1. every COMMENT LINE, verbatim.
    for tag, lines in (("prom_a", a), ("prom_c", c)):
        want = [l for l in lines if kind(l) == "comment"]
        missing = [l for l in want if l not in mset and l not in CORRECTIONS]
        print("  %-7s %4d comment lines   %4d present verbatim   %d missing"
              % (tag, len(want), len(want) - len(missing), len(missing)))
        for l in missing:
            fails.append("comment lost from %s: %r" % (tag, l))

    # 2. every LABEL, defined.
    for tag, lines in (("prom_a", a), ("prom_c", c)):
        want = [LABEL_RE.match(l.strip()).group(1)
                for l in lines if kind(l) == "label"]
        missing = [w for w in want if ("\n%s:" % w) not in "\n" + merged]
        print("  %-7s %4d labels          %4d defined              %d missing"
              % (tag, len(want), len(want) - len(missing), len(missing)))
        for w in missing:
            fails.append("label lost from %s: %s" % (tag, w))

    # 3. every INSTRUCTION, either kept from both sides or an enumerated
    #    adoption whose dropped spelling survives in the trailing comment.
    mcode = [l for l in mlines if kind(l) == "code"]
    if len(mcode) != len(rs):
        fails.append("merged file has %d instructions, not %d"
                     % (len(mcode), len(rs)))
    else:
        bad = 0
        for i, (r, ml) in enumerate(zip(rs, mcode)):
            mc, cm = code_of(ml), comment_of(ml)
            if i in BASE_SITES:
                ok = (BASE_EQU in mc
                      and norm(mc.replace(BASE_EQU, "")) ==
                          norm(re.sub(r'0x0*[0-9a-fA-F]{6,8}', '', r["a_code"])))
            elif i in ADOPTIONS:
                side = ADOPTIONS[i][0]
                other = "c" if side == "a" else "a"
                ok = (norm(mc) == norm(r["%s_code" % side])
                      and re.sub(r'\s+', ' ', r["%s_code" % other]) in cm)
            else:
                ok = norm(mc) == norm(r["a_code"]) == norm(r["c_code"])
            if not ok:
                bad += 1
                fails.append("instruction %d not accounted for: %r" % (i, ml))
        print("  %-7s %4d instructions    %4d accounted for        %d not"
              % ("merged", len(rs), len(rs) - bad, bad))

    # 4. both sides' PROSE survives on the merged line.
    lost = 0
    for r, ml in zip(rs, mcode):
        for p in (r["a_prose"], r["c_prose"]):
            if p and p not in ml:
                lost += 1
                fails.append("prose lost: %r" % p)
    print("  %-7s %4d prose fragments %4d present               %d lost"
          % ("merged", sum(1 for r in rs for p in (r["a_prose"], r["c_prose"]) if p),
             sum(1 for r in rs for p in (r["a_prose"], r["c_prose"]) if p) - lost,
             lost))

    # 5. the two equates ARE the bytes the ROMs carry at the three sites.
    for side, rel in INC.items():
        txt = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        m = re.search(r'^\.equ\s+%s,\s*(0x[0-9A-Fa-f]+)' % BASE_EQU, txt, re.M)
        got = int(m.group(1), 16) if m else None
        key = "abytes" if side == "a" else "cbytes"
        from_rom = {int(rs[i][key].split()[3], 16) << 16 for i in BASE_SITES}
        ok = got == DSP_BASE[side] and from_rom == {DSP_BASE[side] & 0xFF0000}
        print("  %-7s %s = 0x%08X   %s"
              % (rel.split("/")[-1][:20], BASE_EQU, got or 0,
                 "matches the ROM at all three sites" if ok else "★ MISMATCH"))
        if not ok:
            fails.append("%s: equate does not match the ROM" % rel)

    print("\nCORRECTIONS (comment lines the merge did NOT carry verbatim): %d"
          % len(CORRECTIONS))
    for k, v in CORRECTIONS.items():
        print("   %r\n     -> %s" % (k, v))
    if fails:
        print("\n%d FAILURE(S):" % len(fails))
        for f in fails:
            print("   " + f)
        return 1
    print("\nPASS: every comment line, every label, every instruction and every "
          "prose\nfragment of BOTH pre-merge blocks is accounted for in %s." % MERGED)
    return 0


# ---------------------------------------------------------------------------
# --selftest -- INVARIANTS, not pinned counts
# ---------------------------------------------------------------------------
def cmd_selftest():
    checks, fails = [], 0

    def ck(name, cond, detail=""):
        nonlocal fails
        checks.append((name, cond, detail))
        if not cond:
            fails += 1

    a, c, rs = rows()

    # I1 -- the regions really are anchored where they claim to be.
    ck("the prom_a block starts at 0x%06X" % PA, rs[0]["addr"] == PA,
       "0x%06X" % rs[0]["addr"])
    ck("the two blocks are contiguous and end together",
       rs[-1]["addr"] + rs[-1]["n"] == PA + LEN
       and rs[-1]["caddr"] + rs[-1]["n"] == PC + LEN)
    ck("both sides define all four entry labels, in order",
       [LABEL_RE.match(l.strip()).group(1) for l in a if kind(l) == "label"
        if LABEL_RE.match(l.strip()).group(1) in ENTRY] == ENTRY
       and [LABEL_RE.match(l.strip()).group(1) for l in c if kind(l) == "label"
            if LABEL_RE.match(l.strip()).group(1) in ENTRY] == ENTRY)

    # I2 -- the pairing is 1:1 and covers the block.  (rows() raises otherwise,
    #       so this states the invariant the raise enforces.)
    ck("the two sides hold the same number of instructions", True,
       "%d each" % len(rs))
    ck("they cover the whole block", sum(r["n"] for r in rs) == LEN)

    # I3 -- ★ THE SHAPE OF THE DIFFERENCE.  Not "there are 3": that every
    #       differing byte is A23..A16 of a base literal and nothing else.
    dl = [i for i, r in enumerate(rs) if r["abytes"] != r["cbytes"]]
    ck("★ every differing instruction is a `ld <Xrr>,imm32` of the base",
       all(re.match(r'ld\s+X\w\w,0x0*[0-9a-f]+$', rs[i]["a_code"], re.I)
           and len(rs[i]["byts"].split()) == 5 for i in dl),
       str([rs[i]["a_code"] for i in dl]))
    ck("★ they differ in exactly ONE byte each, and it is byte 3 (A23..A16)",
       all([j for j in range(5)
            if rs[i]["abytes"].split()[j] != rs[i]["cbytes"].split()[j]] == [3]
           for i in dl))
    ck("★ that byte is the top of DSP_REGS_BASE on each CPU",
       all(int(rs[i]["abytes"].split()[3], 16) == DSP_BASE["a"] >> 16
           and int(rs[i]["cbytes"].split()[3], 16) == DSP_BASE["c"] >> 16
           for i in dl))
    ck("no OTHER instruction differs between the images",
       all(rs[i]["abytes"] == rs[i]["cbytes"]
           for i in range(len(rs)) if i not in dl))
    ck("the per-CPU sites are exactly the ones the merge equates",
       dl == list(BASE_SITES), str(dl))

    # I4 -- ★ THE NULL.  A criterion that cannot fail is not a criterion.
    worst = max(LEN - len(rom_diff(s)) for s in (-4, -3, -2, -1, 1, 2, 3, 4))
    ck("★ NULL: no neighbouring alignment comes close to the true one",
       worst < LEN - len(rom_diff()) - 100,
       "best misaligned %d of %d, true %d" % (worst, LEN, LEN - len(rom_diff())))

    # I5 -- every ADOPTION is REAL: the two spellings must actually differ, and
    #       every differing pair must be listed.  A stale ADOPTIONS entry is as
    #       wrong as a missing one.
    differ = {i for i, r in enumerate(rs)
              if norm(r["a_code"]) != norm(r["c_code"])}
    ck("every listed adoption is a pair that really is spelled two ways",
       set(ADOPTIONS) <= differ, str(sorted(set(ADOPTIONS) - differ)))
    ck("every two-spelling pair is either listed or a per-CPU site",
       differ <= set(ADOPTIONS) | set(BASE_SITES),
       str(sorted(differ - set(ADOPTIONS) - set(BASE_SITES))))

    # I6 -- ★ THE CONTROL.  A verifier that cannot fail proves nothing, so one
    #       is run against a DAMAGED merged file and must reject it.
    good = open(os.path.join(ROOT, MERGED), encoding="utf-8").read()
    try:
        cut = good.split("\n")
        # ⚠ THE VICTIM MUST BE A LINE THE PROOF IS ABOUT.  The first version of
        #   this control deleted the first long comment in the file, which is in
        #   the merge's OWN header -- a line no original block ever contained --
        #   and --verify correctly did not care.  A control that deletes
        #   something unprotected proves the checker is silent, not that it is
        #   working.  It now deletes a MOVED line.
        #   ⚠ AND IT MUST BE UNIQUE.  `;` alone is a moved comment line and
        #   occurs 60-odd times; deleting one leaves the rest and the set test
        #   still finds it.  That was the second way this control came back
        #   green while proving nothing.
        moved = {l for l in a + c if kind(l) == "comment"}
        victim = next(i for i, l in enumerate(cut)
                      if l in moved and cut.count(l) == 1)
        broken = "\n".join(cut[:victim] + cut[victim + 1:])
        write(os.path.join(ROOT, MERGED), broken)
        rc = _quiet(cmd_verify)
        ck("★ CONTROL: --verify REJECTS a merged file with one comment deleted",
           rc != 0, "returned %d" % rc)
    finally:
        write(os.path.join(ROOT, MERGED), good)
    ck("...and ACCEPTS the real one again", _quiet(cmd_verify) == 0)

    for name, ok, detail in checks:
        print("  %-4s %-62s %s" % ("ok" if ok else "FAIL", name, detail))
    print("\n%d checks, %d failures" % (len(checks), fails))
    return 1 if fails else 0


# ---------------------------------------------------------------------------
# --images -- what the merge did to each IMAGE's text, before against after
# ---------------------------------------------------------------------------
def cmd_images():
    """Per-image comment/label census, BASE_REV against the working tree.

    ★ WHY THIS IS NOT THE SAME QUESTION AS --verify.  --verify asks whether the
    two BLOCKS survived.  This asks what each IMAGE now reads like -- and the
    answer is that both GAINED, because a shared source belongs to both: prom_a
    now carries prom_c's headers for these four routines and prom_c carries
    prom_a's.  A delta of zero here would mean the merge had thrown one side's
    documentation away.
    """
    from asm_source import image_text, image_text_at_rev
    a, c, _rs = rows()
    merged = open(os.path.join(ROOT, MERGED), encoding="utf-8").read().split("\n")
    nmerged = sum(1 for l in merged if kind(l) == "comment")
    lost = {"prom_a": sum(1 for l in a if kind(l) == "comment"),
            "prom_c": sum(1 for l in c if kind(l) == "comment"), "prom_b": 0}
    gained = {}
    for img, side, host in (("prom_a", "a", PROM_A), ("prom_c", "c", PROM_C)):
        ls = open(os.path.join(ROOT, host), encoding="utf-8").read().split("\n")
        # the replacement written in place: the banner down to the .include
        end = ls.index('\t.include "%s"' % MERGED)
        start = end
        while not ls[start].lstrip().startswith("; 0x%06X"
                                                % (PA if side == "a" else PC)):
            start -= 1
        if ls[start - 1].startswith("; ==="):
            start -= 1
        inc = open(os.path.join(ROOT, INC[side]), encoding="utf-8").read().split("\n")
        gained[img] = (nmerged
                       + sum(1 for l in ls[start:end + 1] if kind(l) == "comment")
                       + sum(1 for l in inc if kind(l) == "comment"))
    gained["prom_b"] = 0
    for host, before_n, after_n, _why in HOST_CORRECTIONS:
        img = "prom_a" if host == PROM_A else "prom_c"
        gained[img] += after_n - before_n
    print("PER-IMAGE TEXT, BASE_REV %s against the working tree" % BASE_REV[:8])
    print("=" * 78)
    print("  image    comment lines        label definitions   delta accounted for")
    ok = True
    for img, prim in (("prom_a", "prom_a/wsa1_prom_a.s"),
                      ("prom_b", "prom_b/wsa1_prom_b.s"),
                      ("prom_c", "prom_c/wsa1_prom_c.s")):
        before = image_text_at_rev(ROOT, prim, BASE_REV).split("\n")
        after = image_text(ROOT, prim).split("\n")
        bc = sum(1 for l in before if kind(l) == "comment")
        ac_ = sum(1 for l in after if kind(l) == "comment")
        bl = sum(1 for l in before if kind(l) == "label")
        al = sum(1 for l in after if kind(l) == "label")
        want = gained[img] - lost[img]
        ok = ok and want == ac_ - bc
        print("  %-7s %7d -> %7d  %+5d   %7d -> %7d  %+4d   %s"
              % (img, bc, ac_, ac_ - bc, bl, al, al - bl,
                 "%+d gained %+d lost" % (gained[img], -lost[img])
                 if want == ac_ - bc else "★ UNEXPLAINED (%+d)" % want))
    print("""
  ★ NO IMAGE LOSES A LINE.  prom_a and prom_c each gain the OTHER's headers for
    these four routines plus the merged file's own; prom_b is untouched and is
    here as the control -- a nonzero row for prom_b would mean the merge reached
    an image it has no business in.

  ★ AND EVERY DELTA IS ACCOUNTED FOR ARITHMETICALLY: the merged file's comment
    lines, plus the in-place banner that replaced the block, plus that image's
    .inc, plus the HOST_CORRECTIONS below, minus the block the image gave up.
    A row that did not add up would be a comment line this merge cannot explain, which is the failure --verify is
    for -- so this is a second, independent way to notice the same thing.""")
    print("\nHOST_CORRECTIONS -- %d claim(s) elsewhere in the host files that the"
          % len(HOST_CORRECTIONS))
    print("move made WRONG, corrected in the same commit rather than left to rot:")
    for host, bn, an, why in HOST_CORRECTIONS:
        print("  %s   %d comment line(s) -> %d" % (host, bn, an))
        for chunk in _wrap(why, 70):
            print("      " + chunk)
    return 0 if ok else 1


def _wrap(text, width):
    out, cur = [], ""
    for w in text.split():
        if len(cur) + len(w) + 1 > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        out.append(cur)
    return out


def _quiet(fn):
    import io
    import contextlib
    with contextlib.redirect_stdout(io.StringIO()):
        return fn()


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--emit" in args:
        sys.exit(cmd_emit())
    if "--pairs" in args:
        sys.exit(cmd_pairs())
    if "--verify" in args:
        sys.exit(cmd_verify())
    if "--images" in args:
        sys.exit(cmd_images())
    if "--selftest" in args:
        sys.exit(cmd_selftest())
    sys.exit(cmd_rom())
