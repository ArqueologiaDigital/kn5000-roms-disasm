#!/usr/bin/env python3
"""What does `RESO SCALE` do, and how does `GROUP` reach register 0x0000 bits 6:4?

QUESTIONS THIS ANSWERS
----------------------
1. `RESO SCALE` is bit 7 of wave-select byte +0x16 (p22, MAIN) and +0x20 (p32,
   SUB) -- a drawn OFF/ON control on the tone editor's `PAGE1/3`
   (notes/FINDINGS-l7a1429-editor-pages.md section 3c).  WHICH INSTRUCTION READS
   THAT BIT, and what changes when it is set?
   ⚠ That note's section 6 says it "reaches R[+0x1A] (index_bias_A), whose writer
   this lane did not locate".  Section 4 below shows the premise is wrong twice:
   `index_bias_A` is P[+0x1A], not R[+0x1A] -- two different records both have a
   +0x1A -- its writers ARE locatable, nine of them in three routines, and every
   one clears bit 7 before using the byte.  `RESO SCALE` never reaches the muting
   index at all.  It is read in exactly two places, and they are registers
   chan+0x0040 and chan+0x0080.

2. Register chan+0x0000 bits 6:4 gate register chan+0x0300 (`INTERACTION GAIN`).
   notes/FINDINGS-l7a1429-gate-and-keyscaling.md section 1 found their fifteen
   writers and showed all fifteen are selected by `Q[+0x0B] & 0xC0` -- the tone
   editor's five-state `GROUP` control, p11 bits 7:6.  What was NOT traced is the
   path from the editor's field to that byte.  Section 5 walks it, hop by hop,
   with every hop an asserted instruction.

HOW A CLAIM IS ASSERTED HERE
----------------------------
Two independent kinds of check, never one alone where it matters:
  * the CANONICAL SPELLING at an address, taken from the image's own listing --
    which is the byte-identical round-trip the converters gate on, so a spelling
    is a fact about the bytes and not a reading of them;
  * an IMMEDIATE decoded straight out of the raw ROM bytes (a stride, a mask, a
    base address), which no listing is involved in.
The censuses are FRAMING-INDEPENDENT byte scans, exactly as
notes/w21_lsi_gate_and_keyscaling.py section 3 does it, so a site inside a region
this tree frames as data still appears -- as a `data` row.

WHAT IT DOES NOT ESTABLISH
--------------------------
  * It does not say what the L7A1429 DOES with register 0x0040 or 0x0080; it says
    what the firmware puts in them and how the bit changes that.
  * The NAMES `RESO SCALE` and `GROUP` are inherited from
    notes/FINDINGS-l7a1429-editor-pages.md (drawn captions, positional argument);
    nothing here re-derives them.
  * ⚠ Nothing here measures hardware.  The instrument is in storage abroad, so
    "play a note with RESO SCALE off and on and listen" is not available, and
    section 2's reading of what the two arms MEAN is graded accordingly.

RUN
    python3 wsa1/notes/w23_reso_scale_and_group_chain.py            # sections 1-7
    python3 wsa1/notes/w23_reso_scale_and_group_chain.py --selftest # FAILURES: 0
    python3 wsa1/notes/w23_reso_scale_and_group_chain.py --census   # every census row
"""
import bisect
import importlib.util
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))

IMAGES = [
    ("prom_a", "wsa1_prom_a.ic12", 0xF80000, "prom_a/wsa1_prom_a.s"),
    ("prom_b", "wsa1_prom_b.ic13", 0xF00000, "prom_b/wsa1_prom_b.s"),
    ("prom_c", "wsa1_prom_c.ic28", 0xF80000, "prom_c/wsa1_prom_c.s"),
    ("prom_d", "wsa1_prom_d.bin",  0x000000, "prom_d/wsa1_prom_d.s"),
]

ROM, BASE = {}, {}
for _tag, _fn, _base, _src in IMAGES:
    ROM[_tag] = open(os.path.join(ROOT, "original_ROMs", _fn), "rb").read()
    BASE[_tag] = _base
C = ROM["prom_c"]

FAILURES = []
QUIET = False
FULL = False


def say(*a):
    if not QUIET:
        print(*a)


def check(what, got, want):
    ok = got == want
    if not ok:
        FAILURES.append("%s: got %r, want %r" % (what, got, want))
    say("   [%s] %-62s %s" % ("ok" if ok else "FAIL", what, got))
    return ok


def cb(addr, n=1):
    return C[addr - 0xF80000:addr - 0xF80000 + n]


def u16(addr):
    return struct.unpack_from("<H", cb(addr, 2))[0]


def u32(addr):
    return struct.unpack_from("<I", cb(addr, 4))[0]


# --------------------------------------------------------------- framing
# The `(Xrr+d8)` memory-operand prefix byte set: 0x88-0x8F byte, 0x98-0x9F word,
# 0xA8-0xAF long, 0xB8-0xBF no-size.  Scanning for THIS rather than for a
# disassembled `ld` spelling is what makes the censuses framing-independent: the
# raw-byte `extpfx*` pseudo-instructions this tree emits for operands the
# assembler does not model (`bit 7,(XIX+0x16)` is the three bytes `bc 16 cf`)
# match it too, and a text search for `ld` would miss every one of them.
MEMPFX = {}
for _i, _r in enumerate(["XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP"]):
    for _k, _sz in ((0x88, "b"), (0x98, "w"), (0xA8, "l"), (0xB8, "n")):
        MEMPFX[_k + _i] = (_r, _sz)

INSTR_RE = re.compile(r";\s+([0-9A-F]{6})\s{2}(\S.*?)\s*$")
_IA = {}


def instr_addrs(tag):
    """Every instruction START ADDRESS and canonical spelling of one image.

    Read out of the image's own listing comments, which the converters emit per
    instruction and gate on a byte-identical round trip.  Used to label a byte-scan
    hit `code` or `data`, and as the spelling half of every check below.
    """
    if tag not in _IA:
        from asm_source import image_lines
        src = dict((t, s) for t, _f, _b, s in IMAGES)[tag]
        d = {}
        for ln in image_lines(ROOT, src):
            m = INSTR_RE.search(ln)
            if m and not ln.lstrip().startswith(";"):
                d[int(m.group(1), 16)] = m.group(2)
        _IA[tag] = d
    return _IA[tag]


def sp(addr, tag="prom_c"):
    return instr_addrs(tag).get(addr, "<not an instruction start>")


def spells(addr, want, tag="prom_c"):
    return check("0x%06X spells `%s`" % (addr, want), sp(addr, tag), want)


def scan(d8, tag):
    """Every offset of one image whose byte 0 is a (Xrr+d8) prefix and byte 1 is d8."""
    data, base = ROM[tag], BASE[tag]
    ia = instr_addrs(tag)
    keys = sorted(ia)
    code, dat = [], []
    for off in range(len(data) - 3):
        if data[off + 1] != d8 or data[off] not in MEMPFX:
            continue
        a = base + off
        if a in ia:
            j = bisect.bisect_right(keys, a)
            code.append((a, ia[a], [ia[keys[k]] for k in range(j, min(j + 2, len(keys)))]))
        else:
            dat.append(a)
    return code, dat


# ============================================================ section 1
def sec1_the_reader():
    say("=== 1. THE READER OF `RESO SCALE`: Dev104_PackStagingStruct, two sites ===")
    say("   Q is the 43-byte WAVE-SELECT record.  Dev104_PackStagingStruct loads it ONCE,")
    say("   into its own frame slot (XIZ-4); every later Q read goes through that slot.")
    say("   ★ That is the `base spilled to a frame` shape which has hidden writers from")
    say("   this tree twice -- section 3's scan is immune to it because it matches the")
    say("   DISPLACEMENT, which no spill can hide.")
    say("")
    spells(0xFC4DCB, "ld XWA,(XBC+0x03)")
    spells(0xFC4DCE, "ld (XIZ+0xfc),XWA")
    check("0xFC4DC4's absolute operand is 0x00E084 (the sub-record P)",
          "0x%06X" % (u32(0xFC4DC4 + 1) & 0xFFFFFF), "0x00E084")
    say("      => (XIZ-4) holds Q = P[+0x03].")
    say("")
    say("   MAIN, register chan+0x0040 (staging word 1, struct offset +0x02):")
    spells(0xFC4E25, "ld XBC,(XIZ+0xfc)")
    spells(0xFC4E28, "ld A,(XBC+0x16)")
    spells(0xFC4E2B, "and A,0x80")
    spells(0xFC4E2E, "jr Z,0xfc4e66")
    spells(0xFC4E3A, "sub DE,WA")
    spells(0xFC4E72, "neg WA")
    spells(0xFC4E9F, "ld (XBC+0x02),HL")
    check("0xFC4E30's absolute operand is 0x00E08A", "0x%06X" % (u32(0xFC4E30 + 1) & 0xFFFFFF), "0x00E08A")
    check("0xFC4E35's absolute operand is 0x00E08D", "0x%06X" % (u32(0xFC4E35 + 1) & 0xFFFFFF), "0x00E08D")
    check("0xFC4E66's absolute operand is 0x00E086 (the voice record R)",
          "0x%06X" % (u32(0xFC4E66 + 1) & 0xFFFFFF), "0x00E086")
    spells(0xFC4E6D, "ld DE,(XBC+0x0c)")
    say("      set   -> d1 = (0x00E08A) - (0x00E08D)")
    say("      clear -> d1 = -R[+0x0C]")
    say("      and the accumulated word goes to staging word 1 = register chan+0x0040.")
    say("")
    say("   SUB, register chan+0x0080 (staging word 2, struct offset +0x04):")
    spells(0xFC4ED4, "ld XBC,(XIZ+0xfc)")
    spells(0xFC4ED7, "ld A,(XBC+0x20)")
    spells(0xFC4EDA, "and A,0x80")
    spells(0xFC4F4E, "ld (XBC+0x04),HL")
    check("0xFC4EDF's absolute operand is 0x00E08A", "0x%06X" % (u32(0xFC4EDF + 1) & 0xFFFFFF), "0x00E08A")
    check("0xFC4EE4's absolute operand is 0x00E08D", "0x%06X" % (u32(0xFC4EE4 + 1) & 0xFFFFFF), "0x00E08D")
    check("0xFC4F15's absolute operand is 0x00E086", "0x%06X" % (u32(0xFC4F15 + 1) & 0xFFFFFF), "0x00E086")
    say("")
    say("   ★★ NULL 1 -- the two are ONE piece of code written twice, not two sightings.")
    a = cb(0xFC4E25, 63)
    b = cb(0xFC4ED4, 63)
    diff = [(i, a[i], b[i]) for i in range(63) if a[i] != b[i]]
    check("the MAIN and SUB spans are both 63 bytes and differ in", len(diff), 1)
    check("  the ONE differing byte is the displacement, 0x16 vs 0x20",
          [(i, hex(x), hex(y)) for i, x, y in diff], [(4, '0x16', '0x20')])
    say("       Sixty-three bytes, one byte different, and the relative branch")
    say("       displacements are identical because the two spans are the same length.")
    n, where = _null_span_pairs(a, 4)
    check("  other 63-byte prom_c spans within 4 bytes of the MAIN span", n, 1)
    check("  and it is the SUB span itself", where, ["0xfc4ed4"])
    say("       THE NULL: over all 512 KB of prom_c there is exactly one other 63-byte")
    say("       window within four bytes of this one, and it is the site being paired.")


def _null_span_pairs(ref, tol):
    n, L, out = 0, len(ref), []
    refoff = 0xFC4E25 - 0xF80000
    for off in range(len(C) - L):
        if off == refoff:
            continue
        d = 0
        for i in range(L):
            if C[off + i] != ref[i]:
                d += 1
                if d > tol:
                    break
        else:
            n += 1
            out.append(hex(0xF80000 + off))
    return n, out


# ============================================================ section 2
def sec2_what_the_arms_carry():
    say("")
    say("=== 2. WHAT THE TWO ARMS CARRY -- every term identified at its own writer ===")
    say("   `chan+0x0040 = SatAsym(P[+0x0A] + P[+0x12] + d1)`; only d1 depends on the bit.")
    say("")
    say("   (0x00E08A) = voice[+0x08], the pitch BEFORE the last stage of Voice_ComputePitch")
    spells(0xFC4D72, "ld BC,(XIZ+0x0a)")
    check("0xFC4D75's absolute operand is 0x00E08A", "0x%06X" % (u32(0xFC4D75 + 1) & 0xFFFFFF), "0x00E08A")
    spells(0xFB0AF0, "ld BC,(XDE+0x08)")
    spells(0xFB0AF8, "call 0xfc4d63")
    say("        (the call site pushes voice[+0x08] into that argument slot)")
    spells(0xFA8078, "ld (XIX+0x08),WA")
    say("        and Voice_ComputePitch stores voice[+0x08] there, immediately before its")
    say("        key-follow stage at 0xFA807B-0xFA80E2.")
    say("")
    say("   (0x00E08D) = voice[+0x0A], the pitch the WAVE is played at plus the zone offset")
    spells(0xFC4DB2, "ld BC,(XIZ+0x0a)")
    check("0xFC4DB5's absolute operand is 0x00E08D", "0x%06X" % (u32(0xFC4DB5 + 1) & 0xFFFFFF), "0x00E08D")
    spells(0xFB0B4F, "ld BC,(XDE+0x0a)")
    spells(0xFB0B57, "call 0xfc4da1")
    say("")
    say("   R[+0x0C]   = the KEY-ZONE record's word +0x06 -- the SAME word that")
    say("                voice[+0x0A] is voice[+0x06] plus:")
    spells(0xFA748D, "ld BC,(XIX+0x06)")
    spells(0xFA7490, "ld (0x5a4f),BC")
    spells(0xFA7494, "ld BC,(XIX+0x06)")
    spells(0xFA74A0, "call 0xfc4d85")
    spells(0xFC4D90, "ld WA,(XIZ+0x0c)")
    spells(0xFC4D93, "ld (XBC+0x0c),WA")
    say("        zone[+0x06] is pushed LAST of three, so it is the (XIZ+0x0C) argument, and")
    say("        Pack104_SetInputs_Rec0C_E08C puts it in R[+0x0C].  The same routine stores")
    say("        it to RAM 0x005A4F, which Voice_PitchAddZoneOffset_AB adds to voice[+0x06]")
    say("        to make voice[+0x0A].")
    say("")
    say("   SO, WITH THE SATURATIONS SET ASIDE:")
    say("        RESO SCALE ON :  d = voice[+0x08] - voice[+0x06] - zone[+0x06]")
    say("        RESO SCALE OFF:  d =                             - zone[+0x06]")
    say("   Both arms remove the key zone's offset.  The ON arm ALSO adds")
    say("   `voice[+0x08] - voice[+0x06]`, which is the whole last stage of")
    say("   Voice_ComputePitch: the key-follow compression around a pivot, and the key")
    say("   zone's own sample tuning.  Adding it back cancels it, so the resonator is")
    say("   tuned from the RAW note rather than from the pitch the wave is played at.")
    say("   ⚠ GRADE: PROVEN for the arithmetic and for every term's writer; STRONG for")
    say("   the sentence above, which reads a meaning out of an identity.  Settling it")
    say("   would take the instrument, and the instrument is in storage.")


# ============================================================ section 3
def sec3_census_bit7():
    say("")
    say("=== 3. THE CENSUS: who else can see wave-select bytes +0x16 and +0x20? ===")
    tot = {}
    for d8 in (0x16, 0x20):
        for tag, _fn, _b, _s in IMAGES:
            code, dat = scan(d8, tag)
            tot[(d8, tag)] = (len(code), len(dat))
            say("   d8=0x%02X  %-7s %4d at an instruction start, %4d inside data"
                % (d8, tag, len(code), len(dat)))
    check("d8=0x16 code hits in prom_c", tot[(0x16, "prom_c")][0], 80)
    check("d8=0x20 code hits in prom_c", tot[(0x20, "prom_c")][0], 42)
    check("prom_d has no code hit at either displacement",
          tot[(0x16, "prom_d")][0] + tot[(0x20, "prom_d")][0], 0)
    say("")
    say("   ★ ADDRESS-SPACE ELIMINATION.  prom_a and prom_b are CPU 1's images and CPU 1")
    say("   has its own address space (prom_c/prom_c.ld); the staged wave-select records")
    say("   live in CPU 2 RAM at 0x0087D2+0x21D.  Only prom_c's hits can be readers of")
    say("   p22/p32, so the adjudication below is over prom_c.")
    say("")
    say("   ⚠ THE QUESTION IS NARROWER THAN THE SCAN: which sites can see BIT 7?")
    rows = {"tests bit 7": [], "clears bit 7": [], "other": []}
    for d8 in (0x16, 0x20):
        for a, spl, nxt in scan(d8, "prom_c")[0]:
            nx = nxt[0] if nxt else ""
            if re.match(r"and [ABCDEHLW],0x80$", nx):
                rows["tests bit 7"].append((a, d8, spl))
            elif nx.startswith("res 0x07"):
                rows["clears bit 7"].append((a, d8, spl))
            else:
                rows["other"].append((a, d8, spl))
    for k in ("tests bit 7", "clears bit 7"):
        say("     %-13s %2d: %s" % (k, len(rows[k]), " ".join("%06X" % a for a, _, _ in rows[k])))
    say("     %-13s %2d (adjudicated below)" % ("other", len(rows["other"])))
    check("sites that read the byte and immediately test bit 7", len(rows["tests bit 7"]), 2)
    check("  and they are the two of section 1",
          sorted("%06X" % a for a, _, _ in rows["tests bit 7"]), ["FC4E28", "FC4ED7"])
    check("sites that read the byte and immediately CLEAR bit 7", len(rows["clears bit 7"]), 18)
    if FULL:
        for a, d8, spl in rows["other"]:
            say("        other  %06X  d8=0x%02X  %s" % (a, d8, spl))
    say("")
    say("   ★ THE 102 `other` ROWS, PARTITIONED MECHANICALLY rather than waved past.")
    say("   A row can only carry bit 7 of p22/p32 if it READS the byte (or a wider value")
    say("   containing it) and something downstream masks that bit.  Classifying all 122")
    say("   prom_c hits by what the instruction is, and, for every READ, by whether any")
    say("   of the next three instructions applies a bit-7 mask:")
    cls, suspects = _classify_reads()
    for k in sorted(cls):
        say("     %-34s %3d" % (k, cls[k]))
    check("every prom_c hit is classified", sum(cls.values()), 122)
    check("READS whose next three instructions mask bit 7 of the LOW byte",
          sorted("%06X" % a for a in suspects),
          sorted(["FC3600", "FC4E28", "FC4ED7",
                  "FC64A5", "FC64CA", "FC64EC", "FC6483", "FC6510", "FC6522",
                  "FC6B83", "FC6BA5", "FC6BCA", "FC6BEC", "FC6C10", "FC6C24",
                  "FC78E0", "FC7902", "FC7927", "FC7949", "FC796D", "FC797F",
                  "FB211C", "FB2A14", "FB312D"]))
    say("       TWENTY-FOUR, and twenty are already accounted for: the two that TEST the")
    say("       bit and the eighteen that CLEAR it.  The other four:")
    spells(0xFB211C, "ld C,(XIZ+0x16)")
    spells(0xFB211F, "set 0x07,C")
    say("         0xFB211C, 0xFB2A14, 0xFB312D -- base XIZ, the routine's OWN FRAME.  A")
    say("           wave-select pointer is never the frame pointer, and each of the three")
    say("           SETS the bit in a stack local it then stores back to the frame.")
    say("         0xFC3600 -- named below.")
    say("       NO OTHER READ ANYWHERE IN prom_c -- byte, word or long -- puts a bit-7")
    say("       mask on either byte.")
    say("")
    say("   THE ROWS THAT NEED NAMING.  A row matters only if its base can be a wave-select record.")
    say("   Every wave-select pointer in CPU 2 descends from Part_GetWaveSelectRecord")
    say("   (section 5, hop 5), so the qualifying bases are Dev104_PackStagingStruct's")
    say("   frame slot (XIZ-4), Pack104_LoadElementWaveSelRec's (XIZ+0x0C) argument, and")
    say("   P[+0x03] dereferenced in place.  Two rows need naming:")
    spells(0xFC3600, "bit 7,(XIX+0x16)")
    say("        -- a RAW-BYTE `extpfx3` form the byte scan catches and a text search for")
    say("           `ld` would not.  Its XIX is the 23-byte SLOT record at 0x00DC0E,")
    say("           reached through the 0x00DF05 pointer table (0xFC35E9 `mul C,0x04`,")
    say("           0xFC35EE `add XBC,0x0000df05`), not a wave-select record.")
    spells(0xFC35EE, "add XBC,0x0000df05")
    spells(0xFC7A4B, "ld XWA,(XBC+0x16)")
    spells(0xFC7A4E, "ld C,(XWA+0x0b)")
    spells(0xFC7A51, "and C,0xc0")
    say("        -- XBC is the PART record and +0x16 is 0x13+3 = P0[+0x03], the tone")
    say("           POINTER.  This is the GROUP selector read of section 5, not a p22 read.")
    say("   The remaining rows' bases are the staging struct, the part record, the voice")
    say("   record, a mathlib frame or a stack local; none is a wave-select record.")
    say("")
    say("   ⇒ IN THE WHOLE OF prom_c EXACTLY TWO INSTRUCTIONS SEE p22/p32 BIT 7:")
    say("     0xFC4E2B and 0xFC4EDA.  Eighteen other sites read the same two bytes and")
    say("     clear bit 7 first.")
    say("")
    say("   ★ THE ABSOLUTE FORM, RUN RATHER THAN ASSERTED.  While a part is staged the")
    say("   four wave-select records are at FIXED CPU-2 addresses, so an absolute access")
    say("   is a real possibility and the displacement scan would not see it.  Scanning")
    say("   prom_c for the eight staged byte addresses as an LE16 or LE24 literal:")
    want, hits = _absolute_literal_scan()
    check("the eight staged addresses of +0x16 and +0x20",
          sorted("0x%04X" % x for x in want),
          ["0x8A05", "0x8A0F", "0x8A30", "0x8A3A", "0x8A5B", "0x8A65", "0x8A86", "0x8A90"])
    check("literal occurrences of any of them anywhere in prom_c", len(hits), 1)
    check("  and the one hit is inside a data table, not at an instruction start",
          [("0x%06X" % a, a in instr_addrs("prom_c")) for a in hits], [("0xFE0940", False)])
    say("       0xFE0940 straddles two entries of the monotone 16-bit table at 0xFE0939")
    say("       (`0x0FA9, 0x0C8A` -> the bytes `0f 8a`).  There is no absolute reader.")
    say("")
    say("   ★ THE `BASE ADVANCED PAST THE FIELD` FORM, ALSO RUN.  A shared worker that")
    say("   takes a POINTER as an argument writes through a generic `(Xrr)`, and the")
    say("   identity lives in the CALLER -- the displacement scan is blind to it.  So:")
    say("   every `add`/`inc` in prom_c whose immediate is 0x16, 0x20 or 0x1A, with what")
    say("   the next three instructions say the base is:")
    sites, lits = _base_advance_census()
    check("such sites in prom_c", len(sites), 50)
    say("      the object literals that appear next to them: " + ", ".join(lits))
    check("the literal set, in full",
          lits, ["0x1523", "0x856e", "0x85bc", "0xdc0e", "0xfdf4f1", "XSP"])
    check("  neither the tone staging image 0x0087D2 nor the part base 0x5D23 is in it",
          ("0x87d2" in lits, "0x5d23" in lits), (False, False))
    say("       The bases are the RAM arrays at 0x00856E and 0x0085BC, the 300-byte part")
    say("       record array at 0x1523, the 23-byte slot array at 0x00DC0E, a ROM table,")
    say("       or XSP being unwound.  Three sites -- 0xFBB7F5, 0xFBCDA1 and the pair at")
    say("       0xFBB82B -- push `base + 0x1A` to the shared worker")
    say("       Voice_ApplyParamChange_Dispatch (0xFAF031), which is exactly the shape")
    say("       that hides a writer; their base is `part[+0x00]`, the 713-byte TONE")
    say("       RECORD, not the 42-byte sub-record:")
    spells(0xFBCD2E, "ld XIY,(XWA+0x1523)")
    spells(0xFBCD33, "ld (XIZ+0xfc),XIY")
    say("       so their +0x1A is offset 26 of the tone record head.  ADJUDICATED, not")
    say("       assumed.")
    say("")
    say("   ⚠ THE FORMS THIS NEGATIVE SEARCHED, so it can be attacked:")
    for line in FORMS:
        say("     " + line)


FORMS = [
    "a literal displacement (Xrr+0x16)/(Xrr+0x20) on any base ... the byte scan, all 4 images",
    "a base SPILLED TO A FRAME and reloaded ................... the scan matches the",
    "                                                            displacement, which no spill",
    "                                                            can hide -- and the reader",
    "                                                            FOUND is exactly this shape",
    "a base held in a register across a call .................. same argument",
    "a base ADVANCED PAST the field, then (Xrr) ............... provenance: every wave-select",
    "                                                            pointer comes from",
    "                                                            Part_GetWaveSelectRecord or",
    "                                                            PartElement_SetWaveSelect-",
    "                                                            Pointer_ToRomDefault; both are",
    "                                                            asserted in section 5",
    "an ABSOLUTE access to a staged record byte ............... the four staged addresses are",
    "                                                            0x8A05/0x8A30/0x8A5B/0x8A86",
    "                                                            (+0x16) and 0x8A0F/0x8A3A/",
    "                                                            0x8A65/0x8A90 (+0x20); scanned",
    "                                                            for as LE16 and LE24 literals",
    "a BLOCK MOVE over the record ............................. ToneStage_ApplyWaveSelTailPreset",
    "                                                            overwrites bytes 13..42, so it",
    "                                                            WRITES both bytes; it reads",
    "                                                            neither",
    "an address minus an index (TABLE - 4*k) .................. the literal scan above; the",
    "                                                            records are RAM, not a table",
    "a pointer stored in ANOTHER table ........................ P[+0x03] and the part record's",
    "                                                            +0x8C+41*e slot, both walked",
    "                                                            in section 5",
    "a raw-byte `extpfx*` pseudo-instruction .................. the scan is over BYTES, so these",
    "                                                            match; 0xFC3600 is one and it",
    "                                                            is in the census",
]



def _classify_reads():
    """Partition prom_c's (Xrr+0x16)/(Xrr+0x20) hits, and find every READ that masks bit 7.

    A hit can carry p22/p32 bit 7 only if it READS the byte -- or a word/long value
    containing it -- and something nearby masks that bit.  `suspects` is every read
    whose next three instructions contain a bit-7 operation on the low byte, in any
    spelling: `and r,0x80`, `and rr,0x0080`, `bit 7,`, `res 0x07,`, `set 0x07,`.
    """
    ia = instr_addrs("prom_c")
    keys = sorted(ia)
    cls, suspects = {}, []
    BIT7 = re.compile(r"^(and [ABCDEHLW],0x80|and [A-Z]{2},0x0080|bit 7,|res 0x07,|set 0x07,)")
    for d8 in (0x16, 0x20):
        for a, spl, _n in scan(d8, "prom_c")[0]:
            size = MEMPFX[C[a - 0xF80000]][1]
            if spl.startswith("ld (X") or spl.startswith("or (X") or spl.startswith("add (X") \
                    or spl.startswith("sub (X") or spl.startswith("xor (X") or spl.startswith("and (X"):
                cls["store / read-modify-write"] = cls.get("store / read-modify-write", 0) + 1
                continue
            k = {"b": "byte read", "w": "word read", "l": "long read", "n": "unsized operand"}[size]
            cls[k] = cls.get(k, 0) + 1
            if BIT7.match(spl):
                suspects.append(a)
                continue
            j = bisect.bisect_right(keys, a)
            for t in range(j, min(j + 3, len(keys))):
                if BIT7.match(ia[keys[t]]):
                    suspects.append(a)
                    break
    return cls, suspects


def _base_advance_census():
    """Every `add`/`inc <reg>,{0x16,0x20,0x1A}` in prom_c, and the literals beside it.

    The `base advanced past the field` form, which the displacement scan cannot see:
    a shared worker handed `record + 0x1A` writes through a generic `(Xrr)` and the
    identity lives in the caller.  Returns the sites and the set of object literals
    naming what each base is, read off the next three instructions.
    """
    ia = instr_addrs("prom_c")
    keys = sorted(ia)
    pat = re.compile(r"^(add|inc)\s+(X?[A-Z]{2}),0x0*(16|20|1a)$")
    lit = re.compile(r"0x0*([0-9a-f]{4,6})")
    sites, lits = [], set()
    for i, a in enumerate(keys):
        if not pat.match(ia[a]):
            continue
        sites.append(a)
        if ia[a].split(",")[0].endswith("XSP"):
            lits.add("XSP")
        for j in range(i + 1, min(i + 4, len(keys))):
            if re.match(r"(jr|jrl|jp|call|calr|djnz)\b", ia[keys[j]]):
                continue        # a branch target is not an object literal
            for v in lit.findall(ia[keys[j]]):
                if int(v, 16) > 0x100:
                    lits.add("0x%x" % int(v, 16))
    return sites, sorted(lits)

def _absolute_literal_scan():
    """Any LE16/LE24 literal in prom_c equal to a staged wave-select +0x16/+0x20 byte."""
    want = set()
    for e in range(4):
        b = 0x0087D2 + 0x21D + 43 * e
        want.add(b + 0x16)
        want.add(b + 0x20)
    hits = []
    for off in range(len(C) - 3):
        v16 = C[off] | (C[off + 1] << 8)
        v24 = v16 | (C[off + 2] << 16)
        if v16 in want or v24 in want:
            hits.append(0xF80000 + off)
    return want, hits


# ============================================================ section 4
def sec4_index_bias():
    say("")
    say("=== 4. THE PREMISE THAT WAS WRONG: `RESO SCALE reaches R[+0x1A]` ===")
    say("   TWO DIFFERENT RECORDS HAVE A +0x1A and the open item names the wrong one:")
    say("     P[+0x1A] = `index_bias_A`, added to the MUTING index i3")
    say("     R[+0x1A] = the word register 0x0480 carries, copied there from P[+0x26]")
    check("0xFC5298's absolute operand is 0x00E084 (P)", "0x%06X" % (u32(0xFC5298 + 1) & 0xFFFFFF), "0x00E084")
    spells(0xFC529F, "ld IY,(XWA+0x1a)")
    check("0xFC5678's absolute operand is 0x00E086 (R)", "0x%06X" % (u32(0xFC5678 + 1) & 0xFFFFFF), "0x00E086")
    spells(0xFC5675, "ld WA,(XBC+0x26)")
    spells(0xFC567F, "ld (XBC+0x1a),WA")
    say("")
    say("   THE WRITERS OF P[+0x1A], LOCATED.  Byte scan for d8=0x1A, all four images:")
    for tag, _fn, _b, _s in IMAGES:
        code, dat = scan(0x1A, tag)
        say("     %-7s %3d at an instruction start, %3d inside data" % (tag, len(code), len(dat)))
    code, _ = scan(0x1A, "prom_c")
    stores = [(a, s) for a, s, _n in code if s.startswith("ld (X") and "+0x1a)," in s]
    check("prom_c STORES through a `(Xrr+0x1a)` operand", len(stores), 13)
    if FULL:
        for a, s in stores:
            say("        %06X  %s" % (a, s))
    p1a = [0xFC64A2, 0xFC64E9, 0xFC651F, 0xFC6B9F, 0xFC6BE6, 0xFC6C1E,
           0xFC78FF, 0xFC7946, 0xFC797C]
    check("  nine of the thirteen write P[+0x1A]",
          sorted("%06X" % a for a, _ in stores if a in p1a),
          sorted("%06X" % a for a in p1a))
    say("       0xFC64A2 0xFC64E9 0xFC651F   PartRec_SetMutingOffset_000B, three arms")
    say("       0xFC6B9F 0xFC6BE6 0xFC6C1E   Pack104_LoadElementWaveSelRec, three arms")
    say("       0xFC78FF 0xFC7946 0xFC797C   Pack104_DispatchByResoMode_ForPart, three arms")
    say("     The other four are a different object, each named by its own base:")
    say("       0xFAC318  base XIX in an init loop that also writes +0x1C from (0x151F)")
    say("       0xFC52FB  base (XIZ+0x08) = the 19-word STAGING STRUCT (word 13 = reg 0x0340)")
    say("       0xFC567F  base (0x00E086) = R, the 37-byte voice record")
    say("       0xFC7A8C  base P[+0x03]   = Q ITSELF, and a BYTE store: Q[+0x1A] = p26")
    spells(0xFC7A81, "ld XBC,(XHL+0x03)")
    spells(0xFC7A8C, "ld (XBC+0x1a),A")
    say("")
    say("   ★★ AND ALL NINE MASK BIT 7 OFF.  Each takes the p22 byte three instructions")
    say("   before the store and applies `res 0x07` to it at once:")
    pairs = [(0xFC6483, 0xFC6486, "ld C,(XIX+0x16)", "res 0x07,C"),
             (0xFC64CA, 0xFC64CD, "ld C,(XIX+0x16)", "res 0x07,C"),
             (0xFC6510, 0xFC6513, "ld C,(XIX+0x16)", "res 0x07,C"),
             (0xFC6B83, 0xFC6B86, "ld A,(XBC+0x16)", "res 0x07,A"),
             (0xFC6BCA, 0xFC6BCD, "ld A,(XBC+0x16)", "res 0x07,A"),
             (0xFC6C10, 0xFC6C13, "ld A,(XBC+0x16)", "res 0x07,A"),
             (0xFC78E0, 0xFC78E3, "ld C,(XIX+0x16)", "res 0x07,C"),
             (0xFC7927, 0xFC792A, "ld C,(XIX+0x16)", "res 0x07,C"),
             (0xFC796D, 0xFC7970, "ld C,(XIX+0x16)", "res 0x07,C")]
    bad = [("%06X" % r, sp(r), sp(m)) for r, m, wr, wm in pairs
           if sp(r) != wr or sp(m) != wm]
    check("nine (read p22, res 7) pairs, all present and all on +0x16", bad, [])
    say("     and the SUB half is the same nine on +0x20:")
    pairs2 = [(0xFC64A5, 0xFC64A8), (0xFC64EC, 0xFC64EF), (0xFC6522, 0xFC6525),
              (0xFC6BA5, 0xFC6BA8), (0xFC6BEC, 0xFC6BEF), (0xFC6C24, 0xFC6C27),
              (0xFC7902, 0xFC7905), (0xFC7949, 0xFC794C), (0xFC797F, 0xFC7982)]
    bad2 = [("%06X" % r, sp(r), sp(m)) for r, m in pairs2
            if "+0x20)" not in sp(r) or not sp(m).startswith("res 0x07")]
    check("nine (read p32, res 7) pairs, all present and all on +0x20", bad2, [])
    say("")
    say("   ⇒ `RESO SCALE` DOES NOT REACH THE MUTING INDEX.  The 0x0340/0x0400 chain reads")
    say("     p22 with bit 7 already cleared, nine times out of nine.  The open item in")
    say("     FINDINGS-l7a1429-editor-pages.md section 6 rested on a field-name collision,")
    say("     and the answer was in registers 0x0040/0x0080 all along.")


# ============================================================ section 5
def sec5_group_chain():
    say("")
    say("=== 5. THE `GROUP` CHAIN: p11 bits 7:6 -> register chan+0x0000 bits 6:4 ===")
    say("")
    say("   HOP 1 -- prom_a builds a six-byte tone message: byte[0] 0x88|arm, byte[1]")
    say("   part, byte[2] (element<<6)|parameter, byte[4] value, byte[5] mask.  The")
    say("   MODELING top page's GROUP editor sends parameter 0x0B with mask 0xC0.")
    say("   INHERITED, grade PROVEN, from FINDINGS-l7a1429-parameter-names.md 2c/2d and")
    say("   FINDINGS-l7a1429-editor-pages.md 1a.  Not re-derived here.")
    say("")
    say("   HOP 2 -- ToneMsg_Dispatch: bit 3 of byte[0] picks the WRITE table at 0xFC2754,")
    say("   bits 0:2 pick the arm.  Arm 4 stages the part, then calls sub_FBC958.")
    check("write-table entry 4", "0x%06X" % (u32(0xFC2754 + 16) & 0xFFFFFF), "0xFC26E9")
    spells(0xFC26EC, "ld A,(XBC+0x01)")
    spells(0xFC26F0, "calr 0xfbaaa2")
    spells(0xFC26F8, "calr 0xfbc958")
    say("")
    say("   HOP 3 -- sub_FBC958 decodes the message and STORES THE BYTE:")
    spells(0xFBC966, "ld W,(XBC+0x02)")
    spells(0xFBC96C, "and W,0xc0")
    spells(0xFBC972, "srl 0x06,W")
    spells(0xFBC97A, "mul C,0x2b")
    spells(0xFBC97F, "add XBC,0x0000021d")
    spells(0xFBC985, "add XBC,0x000087d2")
    spells(0xFBC994, "and A,0x3f")
    spells(0xFBC99B, "add XBC,XWA")
    spells(0xFBC9A0, "ld A,(XIY+0x04)")
    spells(0xFBC9A3, "ld (XBC),A")
    check("0x2B is 43, the wave-select record stride", cb(0xFBC97C, 1)[0], 43)
    check("the two adds are 0x21D and 0x87D2 as raw immediates",
          (u32(0xFBC97F + 2), u32(0xFBC985 + 2)), (0x21D, 0x87D2))
    say("      => *(0x0087D2 + 0x21D + 43*element + parameter) = value.")
    say("      ⚠ THE MASK byte[5] IS NOT APPLIED HERE -- prom_a sends the whole byte.  It")
    say("        is read only by the parameter-11 arm, which reloads the RESONATOR TYPE")
    say("        preset over bytes 13..42 when the mask is 0x3F or 0xFF, and does NOT when")
    say("        it is 0xC0.  So a GROUP write changes p11 bits 7:6 and leaves the thirty")
    say("        coefficients alone -- which is what a second control sharing that byte")
    say("        has to do, and it is the mask's only use in this image.")
    spells(0xFBCA1D, "cp A,0x3f")
    spells(0xFBCA25, "cp A,0xff")
    spells(0xFBCA34, "calr 0xfbc725")
    say("")
    say("   HOP 4 -- then, on EVERY parameter, the tail at 0xFBCB09 reloads the element:")
    spells(0xFBCB31, "ld C,0x29")
    spells(0xFBCB3D, "mul WA,0x012c")
    spells(0xFBCB43, "add WA,0x008c")
    spells(0xFBCB49, "ld XBC,(XWA+0x1523)")
    spells(0xFBCB59, "call 0xfc6803")
    check("0x29 is 41, the part-element sub-record stride", cb(0xFBCB32, 1)[0], 41)
    check("0x012C is 300, the part-record stride", u16(0xFBCB3D + 2), 300)
    check("+0x8C is +0x88+4, the sub-record's SECOND pointer", u16(0xFBCB43 + 2), 0x8C)
    say("")
    say("   HOP 5 -- and that pointer IS the address hop 3 wrote into.")
    say("   Part_GetWaveSelectRecord returns the STAGED record whenever the part's")
    say("   `staged` bit is set, and Part_LoadToneRecordAndPointers stores the return in")
    say("   part[+0x8C+41*e]:")
    spells(0xFB4505, "ld WA,(XIX+BC)")
    spells(0xFB450A, "and WA,0x0001")
    spells(0xFB4510, "ld C,0x2b")
    spells(0xFB4517, "add XBC,0x0000021d")
    spells(0xFB451D, "add XBC,0x000087d2")
    spells(0xFB4865, "add BC,0x008c")
    spells(0xFB486B, "ld (XBC+0x1523),XIY")
    spells(0xFB485C, "calr 0xfb44ec")
    say("   and arm 4 sets that bit itself, through ToneStage_EnsurePartLoaded (hop 2):")
    spells(0xFBAB04, "or (XBC+0x1523),0x0001")
    check("Part_GetWaveSelectRecord's staged arm uses the same 43 / 0x21D / 0x87D2",
          (cb(0xFB4511, 1)[0], u32(0xFB4517 + 2), u32(0xFB451D + 2)), (43, 0x21D, 0x87D2))
    say("")
    say("   HOP 6 -- Pack104_LoadElementWaveSelRec binds it: P[+0x03] = that pointer.")
    check("0xFC681B's absolute operand is 0x00E082 (the PART)", "0x%06X" % (u32(0xFC681B + 1) & 0xFFFFFF), "0x00E082")
    spells(0xFC6816, "ld WA,0x5d23")
    spells(0xFC6820, "ld C,0x2a")
    spells(0xFC6825, "add BC,0x0013")
    spells(0xFC6831, "ld XWA,(XIZ+0x0c)")
    spells(0xFC6834, "ld (XBC+0x03),XWA")
    check("42 and 0x13: the sub-record stride and the offset of sub[0] in the part record",
          (cb(0xFC6821, 1)[0], u16(0xFC6825 + 2)), (42, 0x13))
    say("")
    say("   HOP 7 -- Pack104_DispatchByResoMode_ForPart folds the four elements'")
    say("   `Q[+0x0B] & 0xC0` and dispatches to the writers of P[+0x07] bits 6:4.")
    spells(0xFBCB9E, "call 0xfc7481")
    spells(0xFC748F, "ld WA,0x5d23")
    spells(0xFC7A4B, "ld XWA,(XBC+0x16)")
    spells(0xFC7A4E, "ld C,(XWA+0x0b)")
    spells(0xFC7A51, "and C,0xc0")
    say("   The fifteen `and (Xrr+0x07),0xFF8F` writers are")
    say("   notes/FINDINGS-l7a1429-gate-and-keyscaling.md section 1.3; not re-derived.")
    say("")
    say("   HOP 8 -- Dev104_PackStagingStruct ships it, and the gate reads it:")
    spells(0xFC4DD1, "ld IY,(XBC+0x07)")
    spells(0xFC51B5, "ld WA,(XBC)")
    spells(0xFC51B7, "and WA,0x0070")
    say("")
    say("   ⇒ THE CHAIN IS CLOSED, every hop an instruction: p11 bits 7:6 -> the staged")
    say("     wave-select record byte +0x0B -> Pack104_DispatchByResoMode_ForPart ->")
    say("     P[+0x07] bits 6:4 -> staging word 0 -> register chan+0x0000 bits 6:4 ->")
    say("     the gate on register chan+0x0300.")


# ============================================================ section 6
def sec6_nulls():
    say("")
    say("=== 6. NULLS FOR SECTION 5's STRUCTURAL CLAIMS ===")
    say("")
    say("   NULL 2 -- `0x21D + 43*e` is the wave-select block of a 713-byte tone record,")
    say("   not an address that happens to fit.  Two additions, made from the literals the")
    say("   code uses, land on prom_d's own record sizes:")
    check("0xD9 + 4*81 == 0x21D  (the four element blocks end where hop 3 begins)",
          hex(0xD9 + 4 * 81), hex(0x21D))
    check("0x21D + 4*43 == 713 == 0x2C9  (the tone record size)", 0x21D + 4 * 43, 713)
    say("       Under a wrong stride neither closes: 42 gives 0x2C5 and 44 gives 0x2CD,")
    say("       and neither is a size prom_d uses.")
    say("")
    say("   NULL 3 -- the part record tiles the same way, which is why hop 4's +0x8C and")
    say("   hop 5's +0x8C are the same slot:")
    check("0x88 + 4*41 == 300 == 0x12C  (the part-record size)", 0x88 + 4 * 41, 300)
    check("  and +0x8C is +0x88 + 4, the SECOND 32-bit pointer of the sub-record",
          0x8C - 0x88, 4)
    say("")
    say("   NULL 4 -- is `test bit 7 of a wave-select byte` a special shape, or a shape")
    say("   that occurs everywhere?  Census of `ld r,(Xrr+d8)` followed immediately by")
    say("   `and r,0x80`, over the whole of prom_c, by displacement:")
    hits = _bit7_census()
    say("      " + "  ".join("+0x%02X:%d" % (d, len(v)) for d, v in sorted(hits.items())))
    check("total sites with that shape in prom_c", sum(len(v) for v in hits.values()), 39)
    q = {0x0E: [0xFC4A06], 0x12: [0xFC54E3, 0xFC6105, 0xFC637C],
         0x15: [0xFC4873], 0x16: [0xFC4E28], 0x19: [0xFC48F4, 0xFC51F7],
         0x1F: [0xFC48A5], 0x20: [0xFC4ED7], 0x25: [0xFC492C, 0xFC536D]}
    got = {}
    for d, v in hits.items():
        keep = [a for a in v if a in sum(q.values(), [])]
        if keep:
            got[d] = keep
    check("  restricted to sites whose base is Q, the displacements are",
          sorted(got), sorted(q))
    check("  and the sites are exactly", {d: sorted(v) for d, v in got.items()},
          {d: sorted(v) for d, v in q.items()})
    say("       EIGHT of the 43 wave-select bytes carry a bit-7 test on the packer path:")
    say("         +0x0E  p14 b7  FORMANT      drawn FIX / MOVE   (PAGE1/2)")
    say("         +0x12  p18 b7  S/H          drawn OFF / ON     (PAGE2/2)")
    say("         +0x15  p21 b7  RESO MODE    drawn OFF / ON     (PAGE3/3, MAIN)")
    say("         +0x16  p22 b7  RESO SCALE   drawn OFF / ON     (PAGE1/3, MAIN)")
    say("         +0x1F  p31 b7  RESO MODE    drawn OFF / ON     (PAGE3/3, SUB)")
    say("         +0x20  p32 b7  RESO SCALE   drawn OFF / ON     (PAGE1/3, SUB)")
    say("         +0x19  p25 b7  the key-follow breakpoint DISABLE (not a drawn caption)")
    say("         +0x25  p37 b7  the same, SUB")
    say("       SIX of the eight are the SIX two-state controls the editor draws out of a")
    say("       wave-select bit 7, and there are exactly six -- so the correspondence is")
    say("       six of six in both directions.  The other two are the documented")
    say("       `bit 7 DISABLES` on the two key-follow breakpoints.  NOT ONE of the")
    say("       0..127 VALUE fields is read this way.  A shape that landed on flags by")
    say("       chance would have hit value fields too: 35 of the 43 bytes are values.")


def _bit7_census():
    ia = instr_addrs("prom_c")
    keys = sorted(ia)
    hits = {}
    for i, a in enumerate(keys):
        m = re.match(r"ld [ABCDEHLW],\(X\w\w\+0x([0-9a-f]{2})\)$", ia[a])
        if not m or i + 1 >= len(keys):
            continue
        if not re.match(r"and [ABCDEHLW],0x80$", ia[keys[i + 1]]):
            continue
        hits.setdefault(int(m.group(1), 16), []).append(a)
    return hits


# ============================================================ section 7
def sec7_factory():
    say("")
    say("=== 7. WHAT THE FACTORY TONES ASK FOR -- WITH THE DENOMINATORS STATED ===")
    say("   ⚠ A RATE OVER FACTORY TONES IS ONLY AS GOOD AS ITS POPULATION, and three")
    say("   different ones are in use across these notes.  All are named here.")
    spec = importlib.util.spec_from_file_location(
        "w21", os.path.join(ROOT, "notes", "w21_lsi_gate_and_keyscaling.py"))
    m = importlib.util.module_from_spec(spec)
    saved, sys.argv = sys.argv, ["w21", "--quiet"]
    try:
        spec.loader.exec_module(m)
    except SystemExit:
        pass
    finally:
        sys.argv = saved
    say("")
    for label, strict, want in (
            ("loose: every tone prom_d's directory frames", False, (256, 459)),
            ("strict: + dev104_topology_probe.py's element-block filter", True, (101, 133))):
        pop = m._tone_records(strict)
        recs = [r for _n, rr in pop for r in rr]
        n = len(recs)
        main = sum(1 for r in recs if r[0x16] & 0x80)
        sub = sum(1 for r in recs if r[0x20] & 0x80)
        grp = sum(1 for r in recs if r[0x0B] & 0xC0)
        dis = sum(1 for r in recs if bool(r[0x16] & 0x80) != bool(r[0x20] & 0x80))
        say("   %-58s %3d tones / %3d records" % (label, len(pop), n))
        say("        RESO SCALE MAIN (p22 b7) set in %3d / %3d = %5.1f%%" % (main, n, 100.0 * main / n))
        say("        RESO SCALE SUB  (p32 b7) set in %3d / %3d = %5.1f%%" % (sub, n, 100.0 * sub / n))
        say("        MAIN and SUB DISAGREE in     %3d / %3d records" % (dis, n))
        say("        GROUP (p11 bits 7:6) non-zero in %3d / %3d" % (grp, n))
        check("  population size", (len(pop), n), want)
        if not strict:
            check("  RESO SCALE MAIN set, loose", main, 403)
            check("  RESO SCALE SUB set, loose", sub, 402)
            check("  MAIN/SUB disagreements, loose", dis, 3)
        else:
            check("  RESO SCALE MAIN set, strict", main, 128)
    say("")
    say("   ⚠ THE THIRD POPULATION.  FINDINGS-l7a1429-editor-pages.md section 4b quotes")
    say("     `346 of 392` for RESO SCALE.  Those 392 records are MELODIC tones only,")
    say("     reached through prom_d's 17-byte-name chain; the 403/459 above is the rate")
    say("     over every tone this tree can frame.  Neither is wrong.  A rate quoted")
    say("     without its population is.")
    say("")
    say("   ★ AND A REAL FINDING RATHER THAN A RATE: the MAIN and SUB flags disagree in")
    say("     only 3 of 459 records, so the control is very nearly a per-TONE switch even")
    say("     though the register path is per-RESONATOR.  That is a fact about the")
    say("     factory bank, not about the firmware, and it is stated as such.")


def main():
    global QUIET, FULL
    args = sys.argv[1:]
    QUIET = "--quiet" in args
    FULL = "--census" in args
    sec1_the_reader()
    sec2_what_the_arms_carry()
    sec3_census_bit7()
    sec4_index_bias()
    sec5_group_chain()
    sec6_nulls()
    sec7_factory()
    say("")
    say("FAILURES: %d" % len(FAILURES))
    for f in FAILURES:
        say("   " + f)
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
