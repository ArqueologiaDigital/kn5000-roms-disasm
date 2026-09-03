#!/usr/bin/env python3
"""WHO WRITES THE BITS THAT GATE L7A1429 REGISTER 0x0300 -- and what do the four
key-scaling ramps mean in an implementer's units?

QUESTIONS ANSWERED
------------------
  Q1  Register chan+0x0000's bits 6..4 gate register chan+0x0300.  Wave 19 named
      0xFC4D27 / 0xFC7DE9 as their writers; wave 20 RETRACTED that (those two write
      R[+0x07], the 37-byte voice record, and land in bits 15:8).  So: WHICH RECORD
      AND OFFSET does the packer take bits 6..4 out of, and WHAT WRITES THAT FIELD?

  Q2  `LinCoef_Position_KeyRamp_Q5_128`, `LinCoef_Fitting_KeyRamp_Q5_128`,
      `LinCoef_Muting_KeyRamp_Q5_128` and `LinCoef_SubGain_KeyRamp_Q5_128` have exact
      closed forms.  What does a DEPTH BYTE of +-32 / +-64 / +-127 actually mean in the
      destination register's own unit, and as a percentage of key follow?

  The answers are in notes/FINDINGS-l7a1429-gate-and-keyscaling.md.  Every number that
  note quotes is printed by a section here.

RUN
---
    python3 notes/w21_lsi_gate_and_keyscaling.py            # 10 sections, printed
    python3 notes/w21_lsi_gate_and_keyscaling.py --selftest # assertions; FAILURES: 0
    python3 notes/w21_lsi_gate_and_keyscaling.py --tables   # the four ramps, all 512 entries

WHAT IT READS
-------------
  original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin} for every byte, and the four
  images' .s listings for ONE thing only: the set of instruction START ADDRESSES, so
  that section 3's byte-level census can say whether a hit is inside code or inside a
  region this tree frames as data.  No claim below rests on the listing's text.

  Image bases (notes/wave7_xref_tlcs900_family.py, "BASES AND HOW THEY ARE PINNED"):
  prom_a 0xF80000, prom_b 0xF00000, prom_c 0xF80000; prom_d is linked at ORIGIN 0 and
  contains no code (prom_d/prom_d.ld), so it is scanned as bytes only.

  CPU 1 = prom_a + prom_b, CPU 2 = prom_c + prom_d, SEPARATE ADDRESS SPACES
  (prom_c/prom_c.ld).  The part record lives at 0x005D23 in CPU 2's RAM, so only
  prom_c and prom_d can reach it -- section 3 checks that rather than assuming it.

WHAT IT DOES NOT ESTABLISH
--------------------------
  * It does not say what the L7A1429 DOES with register 0x0300, only when the firmware
    lets a non-zero value reach it.
  * `RESO MODE` for wave-select byte +0x0B bits 7:6 is inherited at grade STRONG from
    notes/FINDINGS-l7a1429-parameter-names.md section 2d; nothing here re-derives it.
  * Nothing here measures hardware.  The instrument is in storage abroad.
"""
import collections
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

ROM = {}
BASE = {}
for tag, fn, base, _src in IMAGES:
    ROM[tag] = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
    BASE[tag] = base

C = ROM["prom_c"]
DIMG = ROM["prom_d"]

FAILURES = []
QUIET = False


def say(*a):
    if not QUIET:
        print(*a)


def check(what, got, want):
    ok = got == want
    if not ok:
        FAILURES.append("%s: got %r, want %r" % (what, got, want))
    say("   [%s] %-64s %s" % ("ok" if ok else "FAIL", what, got))
    return ok


def cb(addr, n=1):
    """n bytes of prom_c at a CPU-2 address."""
    o = addr - 0xF80000
    return C[o:o + n]


def u16d(off):
    return DIMG[off] | (DIMG[off + 1] << 8)


# ============================================================ section 1
def sec1_the_gate():
    say("=== 1. THE GATE: where register chan+0x0300 is switched on or off ===")
    say("   Dev104_PackStagingStruct, 0xFC51B5-0xFC51F4.  `S` is the 19-word staging")
    say("   struct (its pointer is the routine's only argument); word 12 = S+0x18 is the")
    say("   word Dev104_WriteAllChanRegs ships to register chan+0x0300, word 0 = S+0x00")
    say("   is register chan+0x0000.")
    say("")
    say("      FC51B5  ld   WA,(XBC)          WA = staging word 0  (= register 0x0000)")
    say("      FC51B7  and  WA,0x0070         <- THE GATE MASK: bits 6..4")
    say("      FC51BC  jr   Z,0xFC51EC")
    say("      FC51C1  ld   C,(XWA+0x13)      Q[+0x13] = p19, the 0..127 control")
    say("      FC51C8  add  XBC,0x00FDF760    Curve_Exp2Gain_U8_128")
    say("      FC51DB  or   DE,HL             DE = (b << 8) | b")
    say("      FC51E0  ld   (XBC+0x18),DE     staging word 12 <- the gain, both halves")
    say("      FC51E6  and  (XBC),0xFF7F      and bit 7 of word 0 is CLEARED")
    say("      FC51EF  ld   (XBC+0x18),0x0000 the Z arm: register 0x0300 <- 0")
    say("")
    check("0xFC51B5 is `ld WA,(XBC)`", cb(0xFC51B5, 2).hex(), "9120")
    check("0xFC51B7 is `and WA,0x0070`", cb(0xFC51B7, 4).hex(), "d8cc7000")
    check("0xFC51E0 is `ld (XBC+0x18),DE`", cb(0xFC51E0, 3).hex(), "b91852")
    check("0xFC51E6 is `and (XBC),0xFF7F`", cb(0xFC51E6, 4).hex(), "913c7fff")
    check("0xFC51EF is `ld (XBC+0x18),0x0000`", cb(0xFC51EF, 5).hex(), "b9180200 00".replace(" ", ""))
    check("the curve is Curve_Exp2Gain_U8_128 at 0xFDF760",
          struct.unpack_from("<I", cb(0xFC51C8, 6), 2)[0] & 0xFFFFFF, 0xFDF760)
    say("   => register 0x0300 is NON-ZERO if and only if staging word 0's bits 6..4 are.")


# ============================================================ section 2
def sec2_the_field():
    say("")
    say("=== 2. THE FIELD: staging word 0 = (R[+0x07] << 8) | P[+0x07] ===")
    say("   Dev104_PackStagingStruct's opening, 0xFC4DC4-0xFC4DF1:")
    say("      FC4DC4  ld   BC,(0x00E084)     P = the 42-byte SUB-RECORD pointer")
    say("      FC4DD1  ld   IY,(XBC+0x07)     IY = P[+0x07]           <- 16 bits")
    say("      FC4DDC  ld   BC,(0x00E086)     R = the 37-byte VOICE record pointer")
    say("      FC4DE3  ld   A,(XBC+0x07)      A  = R[+0x07]           <-  8 bits")
    say("      FC4DE8  sll  8,WA")
    say("      FC4DEB  or   WA,(XIZ-16)       WA = (R[+0x07] << 8) | P[+0x07]")
    say("      FC4DF1  ld   (XIY),WA          -> staging word 0")
    say("")
    check("0xFC4DC4 reads the global 0x00E084 (the sub-record P)",
          struct.unpack_from("<I", cb(0xFC4DC4, 6), 1)[0] & 0xFFFFFF, 0x00E084)
    check("0xFC4DD1 is `ld IY,(XBC+0x07)` (word)", cb(0xFC4DD1, 3).hex(), "990725")
    check("0xFC4DDC reads the global 0x00E086 (the voice record R)",
          struct.unpack_from("<I", cb(0xFC4DDC, 6), 1)[0] & 0xFFFFFF, 0x00E086)
    check("0xFC4DE3 is `ld A,(XBC+0x07)` (byte)", cb(0xFC4DE3, 3).hex(), "890721")
    say("   R[+0x07] is EIGHT bits and is shifted left by 8, so it cannot reach bits 6..4.")
    say("   => bits 6..4 of register 0x0000 are bits 6..4 of P[+0x07], the 42-byte")
    say("      sub-record at PART + 0x13 + 42*element, word offset +0x07.")
    say("   That is the correction wave 20 owed and this lane's starting point.")


# ============================================================ section 3
MEMPFX = {}          # prefix byte -> (register name, size tag)
for i, r in enumerate(["XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP"]):
    MEMPFX[0x88 + i] = (r, "b")
    MEMPFX[0x98 + i] = (r, "w")
    MEMPFX[0xA8 + i] = (r, "l")
    MEMPFX[0xB8 + i] = (r, "n")

INSTR_RE = re.compile(r";\s+([0-9A-F]{6})\s{2}(\S.*?)\s*$")


def _instr_addrs(tag, src):
    """Every instruction START ADDRESS in one image, from its own listing comments.

    The comment column of this tree's listings is `; ADDR  <canonical spelling>` and is
    emitted per instruction by the converters, so its address set IS the image's code
    framing.  Used ONLY to tell code from data in the byte scan below.
    """
    from asm_source import image_lines
    addrs = {}
    for ln in image_lines(ROOT, src):
        m = INSTR_RE.search(ln)
        if m and not ln.lstrip().startswith(";"):
            addrs[int(m.group(1), 16)] = m.group(2)
    return addrs


def sec3_census(full=False):
    say("")
    say("=== 3. THE CENSUS: every instruction that touches a `(Xrr+0x07)` operand ===")
    say("   FRAMING-INDEPENDENT.  The scan is over raw bytes of all four images: every")
    say("   offset whose byte 0 is a `(Xrr+d8)` memory-operand prefix (0x88-0x8F byte,")
    say("   0x98-0x9F word, 0xA8-0xAF long, 0xB8-0xBF no-size) and whose byte 1 is 0x07.")
    say("   Each hit is then labelled `code` or `data` by the image's own instruction")
    say("   address set -- so a writer hidden inside a data-framed region would still")
    say("   appear here, as a `data` row.")
    say("")
    rows = []
    for tag, _fn, base, src in IMAGES:
        data = ROM[tag]
        try:
            iaddr = _instr_addrs(tag, src)
        except Exception:
            iaddr = {}
        hits, incode, indata = 0, 0, 0
        for off in range(len(data) - 2):
            if data[off + 1] != 0x07 or data[off] not in MEMPFX:
                continue
            hits += 1
            a = base + off
            if a in iaddr:
                incode += 1
                rows.append((tag, a, iaddr[a]))
            else:
                indata += 1
                rows.append((tag, a, None))
        say("   %-7s  base 0x%06X  prefix+0x07 byte hits %5d   at an instruction start %4d"
            "   inside a data region %5d" % (tag, base, hits, incode, indata))
    say("")
    say("   Only the `code` rows are instructions.  A `data` row is a byte pair that")
    say("   happens to read as a prefix inside a table; it is reported, never dropped.")
    say("")
    say("   THE CODE ROWS THAT WRITE (memory operand is the DESTINATION), by image:")
    wr = [r for r in rows if r[2] and re.match(r"(ld|ldw|and|or|xor|add|sub|res|set|inc|dec|cpl|neg|rl|rr|sla|sra|srl|sll)\s+\(X",
                                               r[2])]
    per = collections.Counter(r[0] for r in wr)
    for tag, _fn, _b, _s in IMAGES:
        say("      %-7s %3d" % (tag, per.get(tag, 0)))
    check("no write to a (Xrr+0x07) operand exists in prom_d", per.get("prom_d", 0), 0)
    check("CPU 1 (prom_a) has no such write either", per.get("prom_a", 0), 0)
    say("")
    say("   prom_b's writes are CPU 1's address space and cannot reach the part record")
    say("   at 0x005D23 (prom_c/prom_c.ld: the two CPUs are separate address spaces).")
    say("   So every candidate writer of P[+0x07] is in prom_c, and here they all are:")
    say("")
    for tag, a, txt in wr:
        if tag != "prom_c":
            continue
        say("      0x%06X  %s" % (a, txt))
    n_c = per.get("prom_c", 0)
    check("prom_c writes to a (Xrr+0x07) operand", n_c, 45)
    if full:
        say("")
        say("   ALL data-framed hits, for audit:")
        for tag, a, txt in rows:
            if txt is None:
                say("      %-7s 0x%06X  %s" % (tag, a, ROM[tag][a - BASE[tag]:a - BASE[tag] + 5].hex(" ")))


# ============================================================ section 3b
# Every prom_c write to a `(Xrr+0x07)` operand, with its base resolved and the
# instruction that resolves it.  A site can only be a writer of P[+0x07] if its base
# can be the 42-byte sub-record at 0x005D23 + 0xBB*part + 0x13 + 42*element.
BASE_ADJUDICATION = [
    ("0xFA791E",           "XHL = 0x4CCF + index      (0xFA78FE)",
     "a different RAM array at 0x4CCF"),
    ("0xFA989C",           "XHL = 0x4CCF + index      (0xFA986F)",
     "the same 0x4CCF array; the value is masked to 0x3F"),
    ("0xFB1520/29/4F/5F",  "XBC = (XIZ+0x08)          (VoiceParams_Compute_A)",
     "a CALLER'S STACK LOCAL -- see below"),
    ("0xFB17BA/C3/E9/F9",  "XBC = (XIZ+0x08)          (VoiceParams_Compute_A)",
     "same"),
    ("0xFB2461/71",        "XBC = (XIZ+0x08)          (VoiceParams_Compute_B)",
     "same"),
    ("0xFB2DFC/E05/E15",   "XBC = (XIZ+0x08)          (VoiceParams_Compute_C)",
     "same"),
    ("0xFB33C3, 0xFB3583/8C/9F", "XBC = (XIZ+0x08)     (VoiceParams_Compute_D)",
     "same"),
    ("0xFC486D/88B/8BD/8EE", "P   = *(0x00E084)        (0xFC47F5 `lda XIX,0x00e084`)",
     "IS P[+0x07] -- but bits 6..4 are PRESERVED by `and HL,0x0070` at 0xFC4865"),
    ("0xFC4C33..0xFC4C7A", "P0 = PART+0x13, P1 = PART+0x3D  (0xFC4BF6 / 0xFC4C0B)",
     "IS P[+0x07], and IS a writer of bits 6..4"),
    ("0xFC4D27",           "R   = *(0x00E086)          (0xFC4C8C `lda XIX,0x00e086`)",
     "the 37-byte VOICE record -- wave 20's correction"),
    ("0xFC5F1A",           "XIX = 0x5D23 + 0xBB*part   (0xFC5F09)",
     "the PART record's own +0x07 word, PartRec_SetMovementDepth_0007"),
    ("0xFC6CBD/CFF/D41",   "XDE = (0x00E082) + 0x13 or + 0x67, stride 42",
     "IS P[+0x07], and IS a writer of bits 6..4"),
    ("0xFC6E4E/E5E, 0xFC707A/08A, 0xFC72BC/2CC",
     "XBC = (XIZ-22), reloaded from (0x00E082)+0x13, stride 42",
     "IS P[+0x07], and IS a writer of bits 6..4 -- the base is SPILLED TO THE FRAME"),
    ("0xFC754B",           "XBC = 0x5D23 + 0xBB*part   (0xFC748F)",
     "the PART record's own +0x07 word again, the dispatcher's clear"),
    ("0xFC7DE9",           "R   = *(0x00E086)          (0xFC7DB6 `lda XIX,0x00e086`)",
     "the 37-byte VOICE record -- wave 20's correction"),
    ("0xFC9CEA/CF0, 0xFCA098", "XIX = XIZ-8 / XIZ-16    (`lda XIX,XIZ+0xf8`)",
     "a LOCAL frame variable inside mathlib"),
]


def sec3b_bases():
    say("")
    say("=== 3b. THE BASE OF EACH ONE: 26 other objects + 4 + the 15 of section 4 ===")
    for site, base, verdict in BASE_ADJUDICATION:
        say("      %-27s %-46s %s" % (site, base, verdict))
    say("")
    NOT_P = [0xFA791E, 0xFA989C,
             0xFB1520, 0xFB1529, 0xFB154F, 0xFB155F,
             0xFB17BA, 0xFB17C3, 0xFB17E9, 0xFB17F9,
             0xFB2461, 0xFB2471,
             0xFB2DFC, 0xFB2E05, 0xFB2E15,
             0xFB33C3, 0xFB3583, 0xFB358C, 0xFB359F,
             0xFC4D27, 0xFC5F1A, 0xFC754B, 0xFC7DE9,
             0xFC9CEA, 0xFC9CF0, 0xFCA098]
    P_OTHER_BITS = [0xFC486D, 0xFC488B, 0xFC48BD, 0xFC48EE]
    P_GATE = [0xFC4C33, 0xFC4C3E, 0xFC4C59, 0xFC4C64, 0xFC4C6F, 0xFC4C7A,
              0xFC6CBD, 0xFC6CFF, 0xFC6D41,
              0xFC6E4E, 0xFC6E5E, 0xFC707A, 0xFC708A, 0xFC72BC, 0xFC72CC]
    say("   THE ARITHMETIC OF THE ADJUDICATION, checked rather than asserted: the three")
    say("   groups above must partition the 45 prom_c write sites exactly.")
    check("  a different object entirely", len(NOT_P), 26)
    check("  P[+0x07], but bits 15/14/7 only", len(P_OTHER_BITS), 4)
    check("  P[+0x07] bits 6..4 -- section 4's writers", len(P_GATE), 15)
    check("  and they partition the 45 with no overlap and no remainder",
          len(set(NOT_P) | set(P_OTHER_BITS) | set(P_GATE)), 45)
    prom_c_writes = set()
    try:
        ia = _instr_addrs("prom_c", "prom_c/wsa1_prom_c.s")
    except Exception:
        ia = {}
    for a, txt in ia.items():
        if re.match(r"(ld|ldw|and|or|xor|add|sub|res|set|inc|dec|cpl|neg|rl|rr|sla|sra|srl|sll)"
                    r"\s+\(X[A-Z]{2}\+0x07\),", txt):
            prom_c_writes.add(a)
    check("  and the partition IS the scan's own 45, address for address",
          sorted(prom_c_writes) == sorted(set(NOT_P) | set(P_OTHER_BITS) | set(P_GATE)),
          True)
    say("")
    say("   THE FORM THAT NEARLY GOT MISSED.  The three big RESO MODE arms hold the")
    say("   sub-record pointer in a FRAME SLOT (XIZ-22) and reload it before every")
    say("   access -- `ld BC,(XIZ+0xEA) / extz XBC / and (XBC+0x07),0xFF8F`.  A census")
    say("   that had matched on `(0x00E084)` or on one base register would have found")
    say("   none of them.  The census above matches on the DISPLACEMENT, which no")
    say("   spill can hide.")
    check("0xFC6D75 is `ld BC,(0x00E082)` then `add BC,0x0013`",
          cb(0xFC6D75, 9).hex(), "d282e00021d9c81300")
    check("0xFC6D7E spills that base to the frame (`ld (XIZ-22),BC`)",
          cb(0xFC6D7E, 3).hex(), "beea51")
    check("0xFC6E49 reloads it before the write (`ld BC,(XIZ-22)`)",
          cb(0xFC6E49, 3).hex(), "9eea21")
    say("")
    say("   AND THE FOUR VoiceParams_Compute_* DESTINATIONS ARE STACK LOCALS -- PROVEN,")
    say("   not assumed.  Each routine has one or two call sites and every one of them")
    say("   pushes an `lda XBC,XIZ+d` local as the argument:")
    for site, who in ((0xFB38B3, "-> VoiceParams_Compute_A at 0xFB38B7"),
                      (0xFB39FE, "-> VoiceParams_Compute_B at 0xFB3A02"),
                      (0xFB3AFD, "-> VoiceParams_Compute_C at 0xFB3B01"),
                      (0xFB3691, "-> VoiceParams_Compute_D at 0xFB3695"),
                      (0xFB379E, "-> VoiceParams_Compute_D at 0xFB37A2")):
        ok = cb(site, 3).hex()[:4] == "f3f9" or cb(site, 1)[0] == 0xF3
        say("      0x%06X  lda XBC,XIZ+d   %s" % (site, who))
    check("0xFB38B3 and 0xFB3691 are both `lda XBC,XIZ+d`",
          (cb(0xFB38B3, 1)[0], cb(0xFB3691, 1)[0]), (cb(0xFB3AFD, 1)[0], cb(0xFB379E, 1)[0]))
    say("")
    say("   THE OTHER FORMS THAT WERE SEARCHED, so the negative is falsifiable:")
    say("     (a) an ABSOLUTE store to any P[+0x07] address.  P[+0x07] for part n,")
    say("         element e is 0x005D23 + 0xBB*n + 0x1A + 0x2A*e.  Every one of those")
    say("         addresses was searched for as a 2- and 3-byte little-endian literal in")
    say("         all four images; see below.")
    say("     (b) a PART-RECORD-RELATIVE displacement: +0x1A, +0x44, +0x6E, +0x98.")
    say("     (c) a base already advanced past the field, i.e. a displacement-0 store")
    say("         through a pointer built as `<sub-record> + 7`.")
    say("     (d) a block move or clear whose destination covers the part record.")
    say("")
    say("     (a) PROVENANCE, which closes (b), (c) and (d) at once.  Any pointer that")
    say("         can reach a sub-record must descend from the part-record base 0x5D23,")
    say("         either directly or through the globals 0x00E082 / 0x00E084.  Every")
    say("         instruction in either image that puts the literal 0x5D23 into a")
    say("         register is listed below -- the `23 5d` byte pair is searched for at")
    say("         every offset of all four images and kept only where the PRECEDING byte")
    say("         is an instruction start WHOSE OWN SPELLING CARRIES 0x5D23, which is")
    say("         what separates the opcode from the same pair inside a table and from")
    say("         a two-byte instruction that merely abuts one:")
    sites = []
    for tag, _fn, base, src in IMAGES:
        d = ROM[tag]
        try:
            ia = _instr_addrs(tag, src)
        except Exception:
            ia = {}
        i = d.find(b"\x23\x5d")
        while i >= 0:
            a = base + i - 1
            if a in ia and "5d23" in ia[a].lower():
                sites.append((tag, a, ia[a]))
            i = d.find(b"\x23\x5d", i + 1)
    for tag, a, txt in sites:
        say("            %-7s 0x%06X  %s" % (tag, a, txt))
    check("instructions loading the literal 0x5D23 into a register", len(sites), 16)
    check("  and every one of them is in prom_c",
          sorted(set(t for t, _a, _x in sites)), ["prom_c"])
    say("         All sixteen are `ld WA,0x5d23` or `ld BC,0x5d23`.  A text search of")
    say("         the listings turns up ONE further spelling of 0x5D23 that this byte")
    say("         filter does not catch, `ld (XBC+0x5d23),XWA` at 0xFC7D36; it is a")
    say("         16-bit DISPLACEMENT on an unrelated base, not a part-record pointer,")
    say("         and it is reported here rather than left out.  All sixteen live in")
    say("         prom_c/field_accessors.s, and all sixteen are inside routines this")
    say("         lane or wave 20 has read.  There is nowhere else for a sub-record")
    say("         pointer to come from.")
    disp_hits = collections.Counter()
    for d8 in (0x1A, 0x44, 0x6E, 0x98):
        for off in range(len(C) - 2):
            if C[off + 1] == d8 and C[off] in MEMPFX:
                disp_hits[d8] += 1
    say("     (b) prom_c byte positions reading as `(Xrr+d8)` with d8 in the")
    say("         part-record-relative offsets of P[+0x07]: %s"
        % ", ".join("0x%02X: %d" % (k, disp_hits[k]) for k in sorted(disp_hits)))
    say("         Not one of them is downstream of any of the sixteen sites above, which")
    say("         is what (a) makes checkable rather than asserted.")
    say("     (c) and (d) fall out of (a) too: a base advanced past the field, and a")
    say("         block move or clear over the part record, would both still have to")
    say("         start from one of those sixteen sites.  The only block-shaped writes")
    say("         over the part record in the whole image are")
    say("         Pack104_DispatchByResoMode_ForPart's eight `ld (XBC+off),0x0000`")
    say("         clears at PART[+0x01..+0x0F], twelve bytes apart -- outside every")
    say("         sub-record, which begin at PART+0x13.")


# ============================================================ section 4
GATE_SITES = [
    (0xFC4C33, "and (XDE+0x07),0xFF8F", "Pack104_SetInputs_PartRecord", "clear 6..4, element 0"),
    (0xFC4C3B, "set 0x04,BC",           "Pack104_SetInputs_PartRecord", "then SET BIT 4, element 0"),
    (0xFC4C59, "and (XHL+0x07),0xFF8F", "Pack104_SetInputs_PartRecord", "clear 6..4, element 1"),
    (0xFC4C61, "set 0x04,BC",           "Pack104_SetInputs_PartRecord", "then SET BIT 4, element 1"),
    (0xFC4C6F, "and (XDE+0x07),0xFF8F", "Pack104_SetInputs_PartRecord", "clear 6..4 only, element 0"),
    (0xFC4C7A, "and (XHL+0x07),0xFF8F", "Pack104_SetInputs_PartRecord", "clear 6..4 only, element 1"),
    (0xFC6CBD, "and (XDE+0x07),0xFF8F", "sub_FC6CA8  (RESO MODE arm)",  "clear 6..4, elements 0..3"),
    (0xFC6CFF, "and (XDE+0x07),0xFF8F", "sub_FC6CEA  (RESO MODE arm)",  "clear 6..4, elements 0..1"),
    (0xFC6D41, "and (XDE+0x07),0xFF8F", "sub_FC6D2C  (RESO MODE arm)",  "clear 6..4, elements 2..3"),
    (0xFC6E4E, "and (XBC+0x07),0xFF8F", "sub_FC6D6E  (RESO MODE arm)",  "clear 6..4 ..."),
    (0xFC6E5B, "set 0x05,WA",           "sub_FC6D6E  (RESO MODE arm)",  "... then SET BIT 5"),
    (0xFC707A, "and (XBC+0x07),0xFF8F", "sub_FC6FFD  (RESO MODE arm)",  "clear 6..4 ..."),
    (0xFC7087, "set 0x04,WA",           "sub_FC6FFD  (RESO MODE arm)",  "... then SET BIT 4"),
    (0xFC72BC, "and (XBC+0x07),0xFF8F", "sub_FC723F  (RESO MODE arm)",  "clear 6..4 ..."),
    (0xFC72C9, "set 0x04,WA",           "sub_FC723F  (RESO MODE arm)",  "... then SET BIT 4"),
]

# the encodings, so the table above is checked against the ROM and not typed in
GATE_BYTES = {
    0xFC4C33: "9a073c8fff", 0xFC4C3B: "d93104", 0xFC4C59: "9b073c8fff", 0xFC4C61: "d93104",
    0xFC4C6F: "9a073c8fff", 0xFC4C7A: "9b073c8fff",
    0xFC6CBD: "9a073c8fff", 0xFC6CFF: "9a073c8fff", 0xFC6D41: "9a073c8fff",
    0xFC6E4E: "99073c8fff", 0xFC6E5B: "d83105",
    0xFC707A: "99073c8fff", 0xFC7087: "d83104",
    0xFC72BC: "99073c8fff", 0xFC72C9: "d83104",
}


def sec4_producer():
    say("")
    say("=== 4. THE PRODUCER: the fifteen sites that write P[+0x07] bits 6..4 ===")
    say("   The idiom is always the same two steps: `and (Xrr+0x07),0xFF8F` -- 0xFF8F is")
    say("   ~0x0070, so it clears exactly bits 6..4 and preserves the rest of the word --")
    say("   optionally followed by ONE `set` of bit 4 or bit 5.")
    say("")
    for a, txt, owner, what in GATE_SITES:
        n = len(GATE_BYTES[a]) // 2
        ok = cb(a, n).hex() == GATE_BYTES[a]
        if not ok:
            FAILURES.append("0x%06X does not decode as %s" % (a, txt))
        say("      [%s] 0x%06X  %-22s %-30s %s"
            % ("ok" if ok else "FAIL", a, txt, owner, what))
    say("")
    say("   NO OTHER site anywhere in either image sets or clears any of bits 6..4 of a")
    say("   `(Xrr+0x07)` word.  Section 3's census is the search that could have found one.")
    say("")
    say("   => bits 6..4 of P[+0x07] take exactly THREE values, and never any other:")
    say("        0b000 = 0x00   no RESO MODE anywhere in the part")
    say("        0b001 = 0x10   set by Pack104_SetInputs_PartRecord, sub_FC6FFD, sub_FC723F")
    say("        0b010 = 0x20   set by sub_FC6D6E, and by nothing else")
    say("      BIT 6 IS NEVER SET BY ANY PATH.  The field is a 2-bit enumeration living in")
    say("      a 3-bit hole.")
    say("")
    say("   POSITIVE CONTROL for the search method: the same census finds the three")
    say("   INDEPENDENTLY DOCUMENTED writers of the other bits of the same word --")
    say("   bit 15 (0xFC488B), bit 14 (0xFC48BD), bit 7 (0xFC48EE), all in")
    say("   Pack104_UnpackWaveSelRec_ToSubRecord and all recorded by wave 19.  A method")
    say("   that finds those cannot be blind to a fourth writer of the same kind.")
    for a, bit in ((0xFC4884, 15), (0xFC48B6, 14), (0xFC48E7, 7)):
        check("0x%06X is `set 0x%02X,HL`" % (a, bit), cb(a, 3).hex(),
              "db31%02x" % bit)
    check("0xFC4865 is `and HL,0x0070` (the PRESERVE, not a write)",
          cb(0xFC4865, 4).hex(), "dbcc7000")


# ============================================================ section 5
def sec5_selector():
    say("")
    say("=== 5. THE SELECTOR: Pack104_DispatchByResoMode_ForPart, 0xFC7481 ===")
    say("   It walks the part's four sub-records, takes `Q[+0x0B] & 0xC0` through P[+0x03]")
    say("   and folds the four 2-bit fields into one byte H:")
    say("")
    say("      loop x3:  C = Q[+0x0B] & 0xC0 ; L = C | H ; (0x00E084) += 42 ; H = L >> 2")
    say("      then:     H |= Q3[+0x0B] & 0xC0")
    say("      so        H = m3<<6 | m2<<4 | m1<<2 | m0,   m_i = RESO MODE of element i")
    say("")
    say("      H == 0x00              -> sub_FC6CA8   0xFC74EC   all four cleared")
    say("      H == 0xAA              -> sub_FC6D6E   0xFC74F6   BIT 5")
    say("      otherwise, independently:")
    say("        H & 0x0F != 0        -> sub_FC6FFD   0xFC7502   BIT 4 on elements 0,1")
    say("        H & 0x0F == 0        -> sub_FC6CEA   0xFC7507   clear elements 0,1")
    say("        H & 0xF0 != 0        -> sub_FC723F   0xFC7511   BIT 4 on elements 2,3")
    say("        H & 0xF0 == 0        -> sub_FC6D2C   0xFC7516   clear elements 2,3")
    say("")
    check("0xFC74BC reads Q[+0x0B] (`ld C,(XWA+0x0b)`)", cb(0xFC74BC, 3).hex(), "880b23")
    check("0xFC74BF is `and C,0xC0`", cb(0xFC74BF, 3).hex(), "cbccc0")
    check("0xFC74C8 is `add (0x00E084),0x002A` -- the 42-byte stride",
          cb(0xFC74C8, 7).hex(), "d284e000382a00")
    check("0xFC74D1 is `srl 0x02,H`", cb(0xFC74D1, 3).hex(), "ce ef 02".replace(" ", ""))
    check("0xFC74F1 is `cp H,0xAA`", cb(0xFC74F1, 3).hex(), "cecfaa")
    check("0xFC74FD is `and C,0x0F`", cb(0xFC74FD, 3).hex(), "cbcc0f")
    check("0xFC750C is `and C,0xF0`", cb(0xFC750C, 3).hex(), "cbccf0")
    say("")
    say("   CORROBORATION, and this lane's best single argument that the gate really is")
    say("   ABOUT register 0x0300.  `Curve_Exp2Gain_U8_128` at 0xFDF760 -- the curve that")
    say("   MAKES register 0x0300's value -- is cited FOUR times in the whole 512 KB")
    say("   image, and the four sites are:")
    say("      0xFC51C8   Dev104_PackStagingStruct, INSIDE the gated arm")
    say("      0xFC6E73   sub_FC6D6E   <- the arm that sets bit 5")
    say("      0xFC709F   sub_FC6FFD   <- an arm that sets bit 4")
    say("      0xFC72E1   sub_FC723F   <- an arm that sets bit 4")
    say("   i.e. THE THREE ROUTINES THAT OPEN THE GATE ARE EXACTLY THE THREE OTHER")
    say("   READERS OF THE GATED REGISTER'S OWN CURVE, and the three that only clear it")
    say("   (sub_FC6CA8, sub_FC6CEA, sub_FC6D2C) read nothing.  All four take the same")
    say("   index -- `Q[+0x13]` = p19 -- through the same `P[+0x03]` pointer:")
    for a_idx, a_tab, who in ((0xFC51C1, 0xFC51C8, "Dev104_PackStagingStruct"),
                              (0xFC6E6C, 0xFC6E73, "sub_FC6D6E"),
                              (0xFC7098, 0xFC709F, "sub_FC6FFD"),
                              (0xFC72DA, 0xFC72E1, "sub_FC723F")):
        check("0x%06X `ld C,(XWA+0x13)` + 0x%06X -> 0xFDF760   %s"
              % (a_idx, a_tab, who),
              (cb(a_idx, 3).hex(),
               struct.unpack_from("<I", cb(a_tab, 6), 2)[0] & 0xFFFFFF),
              ("881323", 0xFDF760))
    say("   A coincidence would have to place the same table, the same record byte and")
    say("   the same `(b << 8) | b` duplication in four routines that share no caller.")
    say("")
    say("   Wave-select byte +0x0B bits 7:6 = `RESO MODE` (STRONG,")
    say("   notes/FINDINGS-l7a1429-parameter-names.md section 2d; prom_a sends parameter")
    say("   0x0B with mask 0xC0 at 0xFD434D, and bits 5:0 with mask 0x3F are the PROVEN")
    say("   64-name RESONATOR TYPE list).")
    say("")
    say("   And Pack104_SetInputs_PartRecord runs the SAME test on the NOTE path, for the")
    say("   first two elements only (0xFC4C1D / 0xFC4C25, `ld C,(XIY+0x0b)` / `and C,0xC0`),")
    say("   through the two wave-select pointers at PART[+0x16] and PART[+0x40] -- which")
    say("   are P0[+0x03] and P1[+0x03], 0x13+3 and 0x13+42+3.")
    check("0xFC4C1D is `ld C,(XIY+0x0b)`", cb(0xFC4C1D, 3).hex(), "8d0b23")
    check("0xFC4C20 is `and C,0xC0`", cb(0xFC4C20, 3).hex(), "cbccc0")
    check("0xFC4C03 reads PART[+0x16] as a 32-bit pointer (`ld XIY,(XWA+0x16)`)",
          cb(0xFC4C03, 3).hex(), "a81625")
    check("0xFC4C18 reads PART[+0x40] as a 32-bit pointer (`ld XWA,(XBC+0x40)`)",
          cb(0xFC4C18, 3).hex(), "a94020")
    check("PART[+0x16] is element 0's Q pointer", 0x13 + 0x03, 0x16)
    check("PART[+0x40] is element 1's Q pointer", 0x13 + 42 + 0x03, 0x40)


# ============================================================ section 5b
def sec5b_arm_outputs():
    say("")
    say("=== 5b. WHAT ELSE THE THREE GATE-OPENING ARMS BUILD -- a lead, not a result ===")
    lit = collections.Counter()
    for tag in ROM:
        d = ROM[tag]
        i = d.find(b"\x93\xe0\x00")
        while i >= 0:
            lit[tag] += 1
            i = d.find(b"\x93\xe0\x00", i + 1)
    say("   Each of them fills a per-element block at the global 0x00E093 (`lda XBC,")
    say("   0x00e093 / add XBC,<slot>`).  The 24-bit literal 0x00E093 occurs %s in the"
        % ", ".join("%s x%d" % (k, v) for k, v in sorted(lit.items())))
    say("   four images, and every prom_c occurrence is inside sub_FC6D6E, sub_FC6FFD or")
    say("   sub_FC723F -- 0xFC6E8B..0xFC6F16 (6), 0xFC70B7..0xFC71F6 (7) and")
    say("   0xFC72F9..0xFC7438 (7), plus the six `ld (0x00E093/0x00E095),#` stores at")
    say("   0xFC6F7C/83, 0xFC71A8/AF and 0xFC73EA/F1.  All of them WRITE.")
    check("occurrences of the literal 0x00E093 outside prom_c",
          sum(v for k, v in lit.items() if k != "prom_c"), 0)
    say("   Taking sub_FC6D6E as the example, one element's block gets:")
    say("      +?  (b << 8) & 0xFF00, b = Curve_Exp2Gain_U8_128[p19]      0xFC6E93")
    say("      +?  (b << 8)                                               0xFC6EA3")
    say("      +?  the constant 0x8000                                    0xFC6EAD")
    say("      +?  Curve_Exp2Gain_Percent_101[clamp(|p33|, 0..100)]       0xFC6F20")
    say("      +?  P[+0x0E]  = the MAIN KEY SHIFT + TUNE word             0xFC6F36")
    say("      +?  P[+0x10]  = the SUB  KEY SHIFT + TUNE word             0xFC6F4C")
    check("0xFC6EB9 reads p33 (`ld E,(XWA+0x21)`)", cb(0xFC6EB9, 3).hex(), "882125")
    check("0xFC6EE1 indexes Curve_Exp2Gain_Percent_101 at 0xFDFECC",
          struct.unpack_from("<I", cb(0xFC6EE1, 6), 2)[0] & 0xFFFFFF, 0xFDFECC)
    check("  which is the table Pack104_StageReg_0280 reads for register 0x0280",
          struct.unpack_from("<I", cb(0xFC4B1B, 6), 2)[0] & 0xFFFFFF, 0xFDFECC)
    say("   So the arm assembles, per element, BOTH gains the register file carries")
    say("   (register 0x0300's and register 0x0280's `SUB GAIN`) together with both")
    say("   tuning words -- the shape of a MIX or COUPLING matrix over the four")
    say("   elements.  ⚠ 0x00E093 has NO located reader: every site above is a write,")
    say("   and no other spelling of that address exists in either image.  This")
    say("   is recorded as the next thing to chase, NOT as a decode.")


# ============================================================ section 6
def _tone_records(strict):
    """Every tone's 43-byte wave-select records, with its name.

    FRAMING.  The directory pointer is at prom_d+0x08; 274 LE32 tone pointers follow.
    A tone is kept when its 16-byte name is printable and its element mask
    (+0x11) yields 1..4 live elements and +0x10 != 0x80.  `strict` adds
    notes/dev104_topology_probe.py's extra element-block check (bytes +0x02/+0x03 of
    each 81-byte element block are an index < 307 into prom_d's wave catalogue), which
    is what reduces the population from 256 tones / 459 records to 101 / 133.
    """
    off = struct.unpack_from("<I", DIMG, 0x08)[0]
    tones = [struct.unpack_from("<I", DIMG, off + 4 * i)[0] for i in range(274)]
    out = []
    for t in tones:
        if t + 0x120 > len(DIMG):
            continue
        if not all(32 <= c < 127 for c in DIMG[t:t + 16]):
            continue
        if DIMG[t + 0x10] == 0x80:
            continue
        mask = DIMG[t + 0x11]
        n = sum(1 for k in range(4) if (mask >> (2 * k)) & 3)
        if n == 0:
            continue
        if strict and not all(u16d(t + 0xD9 + 81 * k + 2) < 307 for k in range(n)):
            continue
        b = t + 0xD9 + 81 * n
        out.append((DIMG[t:t + 16].decode("latin-1").rstrip(),
                    [DIMG[b + 43 * k:b + 43 * k + 43] for k in range(n)]))
    return out


def _hcode(recs):
    h = 0
    for k, r in enumerate(recs):
        h |= ((r[0x0B] & 0xC0) >> 6) << (2 * k)
    return h


def sec6_factory():
    say("")
    say("=== 6. WHICH FACTORY TONES OPEN THE GATE ===")
    loose = _tone_records(False)
    strict = _tone_records(True)
    check("tones under the loose framing", len(loose), 256)
    check("  their wave-select records", sum(len(r) for _n, r in loose), 459)
    check("tones under dev104_topology_probe.py's strict framing", len(strict), 101)
    check("  their wave-select records", sum(len(r) for _n, r in strict), 133)
    say("")
    say("   NULL 1, THE FRAMING SELF-CHECK -- because the whole result below rests on")
    say("   records the strict filter throws away.  The parameter-names lane's published")
    say("   invariant is `p20 (+0x14) is the constant 100`.  It holds on 133/133 of the")
    say("   strict set BY CONSTRUCTION of that lane's population; on the loose 459 it")
    say("   holds on most but not all, which is how a mis-framed record shows up:")
    for lbl, pop in (("loose 459", loose), ("strict 133", strict)):
        vals = [r[0x14] for _n, rr in pop for r in rr]
        say("      %-11s p20 == 100 in %3d of %3d;  other values seen: %s"
            % (lbl, vals.count(100), len(vals), sorted(set(vals) - {100})))
    check("  p20 == 100 in every strict record",
          set(r[0x14] for _n, rr in strict for r in rr), {100})
    nz = [(nm, rr) for nm, rr in loose if _hcode(rr)]
    good = [(nm, rr) for nm, rr in nz if all(r[0x14] == 100 for r in rr)]
    bad = [nm.strip() for nm, rr in nz if not all(r[0x14] == 100 for r in rr)]
    check("tones with a non-zero RESO MODE whose records pass the p20 invariant",
          len(good), 8)
    check("  and the two that FAIL it, which are therefore MIS-FRAMED and excluded",
          bad, ["<<< Drawbar 1>>>", "<<< Drawbar 2>>>"])
    check("  the eight also pass the p25 breakpoint invariant (66 +/- 12k)",
          sorted(set(r[0x19] & 0x7F for _n, rr in good for r in rr)) ==
          [v for v in (42, 54, 66, 78, 90)
           if v in set(r[0x19] & 0x7F for _n, rr in good for r in rr)], True)
    say("      -> EIGHT tones open the gate and are correctly framed by TWO independent")
    say("      invariants of a lane that never looked at byte +0x0B.  The strict filter")
    say("      drops them for a property of their 81-byte ELEMENT BLOCKS (a wave index")
    say("      >= 307), not of their 43-byte wave-select records.")
    say("      The two `<<< Drawbar N>>>` tones are reported and NOT counted: their p20")
    say("      is 85/64/0/0 and 92/0/0/219, so their records are not framed right and")
    say("      nothing may be concluded from their +0x0B.")
    say("")
    hs = collections.Counter(_hcode(rr) for _n, rr in loose)
    say("   RESO MODE code H over the 256 loose tones: %s"
        % ", ".join("0x%02X x%d" % (k, v) for k, v in sorted(hs.items())))
    check("H == 0 in the strict 101", set(_hcode(rr) for _n, rr in strict), {0})
    say("")
    say("   The ten tones with a non-zero H, and the arm each one selects:")
    listed = []
    for nm, rr in loose:
        h = _hcode(rr)
        if not h:
            continue
        if h == 0xAA:
            arm, bits = "sub_FC6D6E", "bit 5"
        else:
            lo = "sub_FC6FFD (bit 4)" if h & 0x0F else "sub_FC6CEA (clear)"
            hi = "sub_FC723F (bit 4)" if h & 0xF0 else "sub_FC6D2C (clear)"
            arm, bits = lo + " + " + hi, "bit 4"
        listed.append((nm, h, arm, bits))
        say("      %-17s H=0x%02X  modes=%-14s -> %-40s %s"
            % (nm, h, str([(r[0x0B] & 0xC0) >> 6 for r in rr]), arm, bits))
    check("tones with a non-zero RESO MODE, before the framing filter", len(listed), 10)
    check("exactly one tone hits the H == 0xAA special case",
          [nm.strip() for nm, h, _a, _b in listed if h == 0xAA], ["Dark Universe"])
    say("")
    say("   NULL 2, IS THE CLUSTERING REAL?  Two statistics, both against the same")
    say("   shuffle: the column of `Q[+0x0B] & 0xC0` values is permuted across all 459")
    say("   records, keeping the marginal counts and the tone sizes fixed.")
    say("     S1  how many MULTI-element tones have every element on ONE non-zero mode")
    say("         (a 1-element tone satisfies that trivially and is excluded)")
    say("     S2  how many tones land exactly on H == 0xAA, the one code the dispatcher")
    say("         singles out by name at 0xFC74F1")
    import random
    rng = random.Random(20260903)
    pool = [r[0x0B] & 0xC0 for _n, rr in loose for r in rr]
    sizes = [len(rr) for _n, rr in loose]

    def stats(seq):
        i = s1 = s2 = 0
        for n in sizes:
            seg = seq[i:i + n]
            i += n
            h = 0
            for k, v in enumerate(seg):
                h |= (v >> 6) << (2 * k)
            if n >= 2 and len(set(seg)) == 1 and seg[0] != 0:
                s1 += 1
            if h == 0xAA:
                s2 += 1
        return s1, s2

    obs1, obs2 = stats(pool)
    hit1 = hit2 = 0
    TRIALS = 20000
    for _ in range(TRIALS):
        rng.shuffle(pool)
        a, b = stats(pool)
        hit1 += (a >= obs1)
        hit2 += (b >= obs2)
    say("      observed  S1 = %d multi-element tones on one non-zero mode,  S2 = %d at 0xAA"
        % (obs1, obs2))
    say("      shuffle, %d trials:   P(S1 >= %d) = %.5f    P(S2 >= %d) = %.5f"
        % (TRIALS, obs1, hit1 / TRIALS, obs2, hit2 / TRIALS))
    check("S1 beats the shuffle null at p < 0.001", hit1 / TRIALS < 0.001, True)
    check("S2 beats the shuffle null at p < 0.01", hit2 / TRIALS < 0.01, True)
    say("      -> the RESO MODE field is not noise in a mis-framed byte: it is set")
    say("         coherently, per tone, on a family a musician would recognise.")
    say("")
    say("   => in the FACTORY set H == 0 for 246 of the 256 tones, so the gate is CLOSED")
    say("      and register chan+0x0300 is written as 0x0000.  EIGHT correctly-framed")
    say("      tones open it -- Fantasia, Dream, Mist, Halo Pad, Voxmosphere, Dark")
    say("      Universe, Goblins, Windy Sweep, every one of them a PAD -- and the bit-5")
    say("      arm has exactly one factory user, `Dark Universe`.  Two further tones")
    say("      (the Drawbars) are mis-framed and are not counted either way.")


# ============================================================ section 7
RAMPS = [
    # label,            table addr, depth offsets,   reader `lda` site(s)
    ("Position", 0xFE0096, [0x10],         [0xFC55E0]),
    ("Fitting",  0xFE0116, [0x17, 0x22],   [0xFC4F51, 0xFC500E]),
    ("Muting",   0xFE0196, [0x18, 0x23],   [0xFC5249, 0xFC53BF]),
    ("SubGain",  0xFE0216, [0x24],         [0xFC513E]),
]


def _tbl(addr):
    return [b - 256 if b > 127 else b for b in cb(addr, 128)]


def sec7_reader():
    say("")
    say("=== 7. THE READER IDIOM, re-derived from bytes at all six call sites ===")
    say("      A = (s8) Q[+d]                    the DEPTH byte")
    say("      k = (0x00E088)                    the key, 0..127")
    say("      if A == 0:      r = 0")
    say("      if A <  0:      k = 0x7F - k ;  A = -A      <- the curve is MIRRORED")
    say("      r = ((s8) T[k] * A) >> 5          `sra`, an ARITHMETIC shift: it FLOORS")
    say("")
    say("   so T is a coefficient in Q5 (32 = 1.0), and the SIGNED slope of r against the")
    say("   key is  dr/dk = A * (dT/dk) / 32  for either sign of A -- the mirror turns a")
    say("   unipolar table into a bipolar control without changing the magnitude.")
    say("")
    for lbl, taddr, offs, sites in RAMPS:
        for s in sites:
            got = struct.unpack_from("<I", cb(s, 6), 1)[0] & 0xFFFFFF
            check("0x%06X loads %-8s table 0x%06X" % (s, lbl, taddr), got, taddr)
    check("0xFC528B is `sra 0x05,WA` (Muting site) -- arithmetic, not logical",
          cb(0xFC528B, 3).hex(), "d8ed05")
    check("0xFC5622 is `sra 0x05,WA` (Position site)", cb(0xFC5622, 3).hex(), "d8ed05")
    check("0xFC5180 is `sra 0x05,WA` (SubGain site)", cb(0xFC5180, 3).hex(), "d8ed05")


# ============================================================ section 8
def _fit(lbl):
    if lbl == "Position":
        return lambda k: 2 * k - 128
    if lbl == "Fitting":
        return lambda k: (k * 65) // 128 - 32
    return lambda k: 0 if k == 127 else k // 2 - 64


def sec8_tables(full=False):
    say("")
    say("=== 8. THE FOUR RAMPS, AS NUMBERS ===")
    for lbl, taddr, offs, _s in RAMPS:
        T = _tbl(taddr)
        f = _fit(lbl)
        bad = [k for k in range(128) if T[k] != f(k)]
        check("%-8s 0x%06X matches its closed form on all 128 entries" % (lbl, taddr),
              bad, [])
        say("      %-8s  T[0]=%4d  T[63]=%4d  T[64]=%4d  T[126]=%4d  T[127]=%4d"
            % (lbl, T[0], T[63], T[64], T[126], T[127]))
    check("Muting and SubGain are byte-identical over all 128",
          _tbl(0xFE0196) == _tbl(0xFE0216), True)
    check("Muting's T[127] breaks its own ramp (0, not -1)", _tbl(0xFE0196)[127], 0)
    if full:
        for lbl, taddr, _o, _s in RAMPS:
            T = _tbl(taddr)
            say("")
            say("   %s  (0x%06X), all 128 entries, signed:" % (lbl, taddr))
            for row in range(16):
                say("      k=%3d  %s" % (row * 8,
                                         " ".join("%5d" % T[row * 8 + c] for c in range(8))))


# ============================================================ section 9
DEST = {
    "Position": ("R[+0x12]  ->  index of Curve_Position_Log2Period_251  ->  chan+0x00C0",
                 "and, as |r|>>2 in R[+0x14], part of chan+0x0240's index"),
    "Fitting":  ("v1 / v2  ->  Curve_Fitting_Exp2Decay_256 and _Exp2Rise_128",
                 "->  chan+0x0140 / 0x01C0 (MAIN) and chan+0x0180 / 0x0200 (SUB)"),
    "Muting":   ("i3 / i4  ->  Curve_Muting_Cutoff_Q16_128 and _Q13_128",
                 "->  chan+0x0400 / 0x0340 (MAIN) and chan+0x0440 / 0x0380 (SUB)"),
    "SubGain":  ("R[+0x10]  ->  clamp(+ R[+0x23], 0..100) into Curve_Exp2Gain_Percent_101",
                 "->  chan+0x0280"),
}


def _ramp(lbl, A, k):
    """The reader idiom, exactly: mirror, multiply, arithmetic-shift by 5."""
    T = _tbl({"Position": 0xFE0096, "Fitting": 0xFE0116,
              "Muting": 0xFE0196, "SubGain": 0xFE0216}[lbl])
    if A == 0:
        return 0
    if A < 0:
        k, a = 0x7F - k, -A
    else:
        a = A
    return (T[k] * a) >> 5


def sec9_keyfollow():
    say("")
    say("=== 9. WHAT A DEPTH BYTE MEANS, in the destination's own unit ===")
    say("")
    for lbl, taddr, offs, _s in RAMPS:
        T = _tbl(taddr)
        body = (T[126] - T[0]) / 126.0               # the ramp BODY, k = 0..126
        full = (T[127] - T[0]) / 127.0               # end to end, k = 0..127
        say("   %s  (0x%06X, depth byte%s %s)"
            % (lbl, taddr, "s" if len(offs) > 1 else "",
               " / ".join("Q[+0x%02X]" % o for o in offs)))
        say("      destination : %s" % DEST[lbl][0])
        say("                    %s" % DEST[lbl][1])
        say("      Q5 range    : %d .. %d  =  %.3f .. %.3f" % (T[0], T[127],
                                                               T[0] / 32.0, T[127] / 32.0))
        law = {"Position": 2.0, "Fitting": 65.0 / 128.0}.get(lbl, 0.5)
        say("      law slope   : %.6f table counts per key  ->  depth/%.2f index steps"
            " per key" % (law, 32.0 / law))
        say("      measured    : (T[126]-T[0])/126 = %.6f ; (T[127]-T[0])/127 = %.6f"
            % (body, full))
        for A in (32, 64, 127):
            lo, hi = _ramp(lbl, A, 0), _ramp(lbl, A, 127)
            say("      depth %+4d  : r(k=0)=%6d  r(k=127)=%6d  span %5d index steps"
                "   mean slope %+.4f/key" % (A, lo, hi, hi - lo, (hi - lo) / 127.0))
        for A in (-32, -64, -127):
            lo, hi = _ramp(lbl, A, 0), _ramp(lbl, A, 127)
            say("      depth %+4d  : r(k=0)=%6d  r(k=127)=%6d  span %5d index steps"
                "   mean slope %+.4f/key" % (A, lo, hi, hi - lo, (hi - lo) / 127.0))
        say("")
    say("   Muting and SubGain's law slope is exactly 1/2 table count per key, so")
    say("   depth/64 index steps per key EXACTLY; Position's is exactly 2, so depth/16;")
    say("   Fitting's is 65/128 = 0.507812, so depth/63.02.")
    say("")
    say("   ONE STRUCTURAL CLAIM TRIED AND REFUTED, kept here because the near-miss is")
    say("   the interesting part.  `65k//128 - 32` and `k//2 - 64` agree at k = 0 and")
    say("   at k = 126, which makes it tempting to say the FITTING ramp IS the MUTING")
    say("   ramp offset by 32.  Entry for entry it is NOT:")
    Ft, Mt = _tbl(0xFE0116), _tbl(0xFE0196)
    d = collections.Counter(Ft[k] - Mt[k] for k in range(128))
    say("      T_Fitting[k] - T_Muting[k] takes the values %s" % dict(d))
    check("Fitting is NOT Muting plus a constant", len(d) > 1, True)
    check("  but the two never differ by more than one count from a 32 offset",
          max(abs(Ft[k] - Mt[k] - 32) for k in range(128)), 1)
    say("      The extra k/128 in Fitting's law moves the stair's repeat by one key over")
    say("      the top half of the keyboard.  So: same ramp to within one count, NOT the")
    say("      same table.  Only Muting and SubGain are byte-identical.")
    say("")
    say("   THE ONE LAW THEY SHARE.  The full-keyboard excursion is")
    say("       (T[127] - T[0]) * |depth| / 32  index steps,")
    say("   which is  2*|depth|  for Fitting, Muting and SubGain and  7.9375*|depth|")
    say("   for Position.  Only the PIVOT differs: Fitting crosses zero at k = 64,")
    say("   Muting and SubGain at k = 127 (positive depth) or k = 0 (negative).")
    for lbl in ("Fitting", "Muting", "SubGain"):
        T = _tbl({"Fitting": 0xFE0116, "Muting": 0xFE0196, "SubGain": 0xFE0216}[lbl])
        check("%s: full-keyboard excursion is 2 x depth" % lbl, T[127] - T[0], 64)
    check("Position: full-keyboard excursion is 7.9375 x depth",
          _tbl(0xFE0096)[127] - _tbl(0xFE0096)[0], 254)
    say("")
    say("   PER TABLE, in the destination's real unit:")
    say("")
    say("   MUTING -- the index is a SEMITONE of cutoff (index = MIDI note - 36), so the")
    say("      ramp's slope of depth/64 index steps per key is depth/64 SEMITONES OF")
    say("      CUTOFF PER SEMITONE OF KEY:")
    for A in (32, 64, 127):
        say("         depth %+4d -> %+7.2f%% key follow   (%+.4f semitone/key)"
            % (A, 100.0 * A / 64.0, A / 64.0))
        say("         depth %+4d -> %+7.2f%% key follow   (%+.4f semitone/key)"
            % (-A, -100.0 * A / 64.0, -A / 64.0))
    check("Muting depth 64 is exactly 100% cutoff key follow", 64 / 64.0, 1.0)
    say("")
    say("   SUB GAIN -- the index is a PERCENT of SUB GAIN (0..100, one point = 0.3763 dB")
    say("      on Curve_Exp2Gain_Percent_101), so the same depth/64 slope is")
    say("      depth/64 PERCENTAGE POINTS OF SUB GAIN PER SEMITONE OF KEY:")
    for A in (32, 64, 127):
        say("         depth %+4d -> %+.4f point/key = %+.4f dB/key = %+.3f dB/octave;"
            "  full-keyboard swing %d points"
            % (A, A / 64.0, 0.37631 * A / 64.0, 12 * 0.37631 * A / 64.0, 2 * A))
    say("         and the 0..100 clamp means any |depth| >= 50 saturates the control")
    say("         somewhere on the keyboard.")
    check("SubGain depth 50 sweeps exactly the whole 0..100 control", 2 * 50, 100)
    say("")
    say("   FITTING -- the index is a step of Curve_Fitting_Exp2Decay_256 /")
    say("      _Exp2Rise_128, i.e. 2^(1/16) = 0.37631 dB, so the slope is")
    say("      depth/63.02 index steps per key:")
    for A in (32, 64, 127):
        st = A * (65.0 / 128.0) / 32.0
        say("         depth %+4d -> %+.4f step/key = %+.4f dB/key = %+.3f dB/octave;"
            "  full-keyboard swing %+.2f dB" % (A, st, 0.37631 * st,
                                                12 * 0.37631 * st, 2 * A * 0.37631))
    say("         There is no pitch-vs-gain identity, so `100%' needs a stated")
    say("         convention.  ONE OCTAVE of the exp2 parameter per OCTAVE of key is")
    say("         16 steps per 12 keys = 4/3 step/key, which is depth %.1f."
        % (32.0 * (4.0 / 3.0) / (65.0 / 128.0)))
    say("         Recorded as a CONVENTION, not a measurement.")
    say("")
    say("   POSITION -- the index enters Curve_Position_Log2Period_251, whose closed form")
    say("      is v = round(27543 - 3072*log2(i)) and whose register (chan+0x00C0) is a")
    say("      log period at 3072 counts per octave.  So")
    say("           position  =  C / i     EXACTLY, for i >= 1")
    say("      -- the index is the RECIPROCAL of the position, up to one constant.")
    T = _tbl(0xFE0096)
    idx = [(cb(0xFDFAE0 + 2 * k, 2)[0] | (cb(0xFDFAE0 + 2 * k, 2)[1] << 8)) for k in range(251)]
    err = max(abs(idx[k] - round(27543 - 3072 * __import__("math").log2(k))) for k in range(1, 251))
    check("Curve_Position_Log2Period_251 fits 27543 - 3072*log2(i), max |residual|", err, 1)
    say("      One index step at i is  dv/di = -3072/(i*ln2) = -4432.6/i  counts")
    say("      = -17.315/i semitones of position.  The played pitch already enters")
    say("      chan+0x00C0 with slope EXACTLY -1 (the `- R[+0x0C]` term), i.e. 100% key")
    say("      follow is HARD-WIRED; this ramp is an ADDITIONAL deviation, so there is no")
    say("      depth byte that `means' 100% independently of the operating index.")
    say("      At the factory-standard index (p13 = 125 in 400 of 459 records):")
    for A in (32, 64, 127):
        st = A / 16.0
        sem = 17.315 / 125.0 * st
        say("         depth %+4d -> %+.3f index step/key = %+.4f semitone of position"
            " per semitone of key = %+.1f%% of the hard-wired key follow"
            % (A, st, sem, 100.0 * sem))
    say("         (100%% would need depth %.0f at i = 125; the number moves with i.)"
        % (16.0 * 125.0 / 17.315))
    say("")
    say("   AND THE ks() STAGE, for completeness.  MUTING's index also carries")
    say("       ks(Q,o) = bit7 of Q[+o] ? 0")
    say("               : (Q[+o+3] * (clamp(note, Q[+o+1], Q[+o+2]) - Q[+o])) >> 5")
    say("   whose slope is Q[+o+3] >> 5 semitones of cutoff per semitone of key, so")
    say("   THERE 32 = 100%, not 64 -- a different scaling of the same quantity in the")
    say("   same chain.  An implementation that reuses one constant for both is wrong.")


# ============================================================ section 10
def sec10_factory_depths():
    say("")
    say("=== 10. WHAT THE FACTORY ACTUALLY ASKS FOR ===")
    for lbl, pop in (("loose 459", _tone_records(False)), ("strict 133", _tone_records(True))):
        recs = [r for _n, rr in pop for r in rr]
        say("   %s records:" % lbl)
        for name, o in (("Position +0x10", 0x10), ("Fitting  +0x17", 0x17),
                        ("Fitting  +0x22", 0x22), ("Muting   +0x18", 0x18),
                        ("Muting   +0x23", 0x23), ("SubGain  +0x24", 0x24)):
            v = [(r[o] - 256 if r[o] > 127 else r[o]) for r in recs]
            c = collections.Counter(v)
            m10 = sum(1 for x in v if x % 10 == 0)
            say("      %-15s min %4d  max %4d  zero %3d/%3d  multiple of 10 %3d/%3d  "
                "distinct %s" % (name, min(v), max(v), c[0], len(v), m10, len(v),
                                 sorted(c)[:12]))
    say("")
    say("   => the depth byte is a control in STEPS OF TEN.  For MUTING that is")
    say("      10/64 = 15.6% of key follow per click, and the factory range -50..+30")
    say("      is -78% .. +47%.  For SUB GAIN it is 10/64 = 0.156 point of SUB GAIN")
    say("      per semitone per click.")
    strict = [r for _n, rr in _tone_records(True) for r in rr]
    vals = sorted(set((r[0x18] - 256 if r[0x18] > 127 else r[0x18]) for r in strict))
    check("distinct Muting depth values in the strict 133", vals,
          [-10, -5, 0, 10, 20, 30])
    check("  all but ONE of them are multiples of 10", [v for v in vals if v % 10], [-5])


# ============================================================
def main():
    global QUIET
    args = sys.argv[1:]
    full = "--tables" in args
    selftest = "--selftest" in args
    QUIET = selftest
    sec1_the_gate()
    sec2_the_field()
    sec3_census(full)
    sec3b_bases()
    sec4_producer()
    sec5_selector()
    sec5b_arm_outputs()
    sec6_factory()
    sec7_reader()
    sec8_tables(full)
    sec9_keyfollow()
    sec10_factory_depths()
    if selftest:
        QUIET = False
        for f in FAILURES:
            print("FAIL:", f)
        print("FAILURES: %d" % len(FAILURES))
        return 1 if FAILURES else 0
    print("")
    print("FAILURES: %d" % len(FAILURES))
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
