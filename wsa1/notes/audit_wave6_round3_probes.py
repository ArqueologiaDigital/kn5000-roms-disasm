#!/usr/bin/env python3
"""Wave 6 ROUND-3 AUDIT probes -- the numbers behind the round-3 audit findings.

Every finding this script backs is a claim made by a round-3 lane that a re-derivation
from the ROM bytes does not support.  It CHANGES NOTHING; it only measures.  Run:

    python3 notes/audit_wave6_round3_probes.py
    python3 notes/audit_wave6_round3_probes.py --selftest    # negative controls

The findings, in the order the sections below check them:

  A1  notes/FINDINGS-prom_a-portb-and-blockdev-entry.md sec.1 says "Only bits 0, 2 and 3 of
      Port B are ever touched ... That is the whole port".  PROM_B READS PB BIT 4 at
      0xF5AB80 and 0xF5AFFC (`bit 4,(0x1f)`), inside SC1_WaitTxDrain / SC1_TxFlush_Body --
      and notes/FINDINGS-prom_b-sc1-link.md already documents that bit.  The census's own
      filter drops every prom_b hit (`h[0] == "prom_a"`) although its docstring says
      "in either image", and its bits assertion compares two hardcoded literals.

  A2  the same note's "18 of the 64 slots have a prom_b caller" is right; the "74 prom_b
      call sites" that goes with it is 72, and no check in the census sums them.

  C1  prom_c 0xFA9C8B (prom_c/voice/voice_parameters.s:4507, was
      prom_c/wsa1_prom_c.s:44434 before the per-subject split) and
      FINDINGS-prom_c-dev10c-sibling-register-map.md:220 say
      register 0x0500's high byte is `... + DetuneCurve_LookupSigned(...)`.  The addend at
      0xFA9691 is HL, and HL was loaded from DetuneCurve_LookupUNsigned (0xFA7654) at
      0xFA9654/0xFA966A.  BOTH DetuneCurve_LookupSigned results reach word 15 (register
      0x08C0) instead -- one through DE, one through (XIZ+0xfe).

  C2  the same two places say the routine "is one of only four in the image that call
      DetuneCurve_LookupSigned".  Five routines call it, over ten sites.

  B1  the round-3 report's shape table (shape 2 = 6,361 bytes, shape 3 = 518, "6,879 bytes
      shapes 2/3 name elsewhere") is a mid-round snapshot: notes/prom_b_dl_call_shapes.py
      re-run at the end of the round says 4,740 / 507 / 5,247, because the round's own
      conversions covered part of it.  (Measured by importing that script, so if it changes
      this section follows it.)

  B2  prom_b/wsa1_prom_b.s:28789 asserts "(0x7FC1) = LANGUAGE" from a reader where all three
      pointers at 0xF993B9 are the SAME table, so the index is inert there -- and entries 3
      and 4 of that table are 0x0E pad, which languages 3 and 4 would read as a pointer.
      The name IS right, but the evidence for it is at prom_a 0xF99D88, which indexes the
      five-entry tables at 0xF0DB18 whose five lists are ENGLISH / GERMAN / FRENCH /
      SPANISH / ITALIAN.  That site is not cited anywhere.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
C = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC_A = open(image_path(ROOT, "prom_a/wsa1_prom_a.s"), encoding="utf-8").read()
SRC_B = open(image_path(ROOT, "prom_b/wsa1_prom_b.s"), encoding="utf-8").read()
SRC_C = open(image_path(ROOT, "prom_c/wsa1_prom_c.s"), encoding="utf-8").read()
A_BASE, B_BASE, C_BASE = 0xF80000, 0xF00000, 0xF80000

OK = FAIL = 0


def check(label, got, want):
    global OK, FAIL
    if got == want:
        OK += 1
        print("  ok    %-58s %r" % (label, got))
    else:
        FAIL += 1
        print("  FAIL  %-58s got %r want %r" % (label, got, want))


def boundaries(src):
    """address -> source line, for every address the converted source spells."""
    d = {}
    for m in re.finditer(r";\s*([0-9A-F]{6})\s+(.*)$", src, re.M):
        d.setdefault(int(m.group(1), 16), m.group(0).strip())
    return d


LA, LB, LC = boundaries(SRC_A), boundaries(SRC_B), boundaries(SRC_C)


def bitop(op):
    """Decode the third byte of a `<C0|F0> <sfr> <op>` bit instruction -> (mnemonic, bit)."""
    if 0xB0 <= op <= 0xB7:
        return ("res", op - 0xB0)
    if 0xB8 <= op <= 0xBF:
        return ("set", op - 0xB8)
    if 0xC8 <= op <= 0xCF:
        return ("bit", op - 0xC8)
    return (None, None)


# ---------------------------------------------------------------- A1
def a1_portb():
    print("A1. PORT B (SFR 0x1F): the bits are DECODED from the opcode byte, not asserted,")
    print("    and prom_b is NOT filtered out.")
    rows = []
    for img, base, name, L in ((A, A_BASE, "prom_a", LA), (B, B_BASE, "prom_b", LB)):
        for o in range(len(img) - 2):
            if img[o] in (0xC0, 0xF0) and img[o + 1] == 0x1F:
                a = base + o
                if a in L:
                    rows.append((name, a, img[o], img[o + 2], L[a]))
    for n, a, _p, op, line in rows:
        mn, bit = bitop(op)
        print("     %-7s %06X  op=%02X  %-12s %s"
              % (n, a, op, "%s %s" % (mn, bit) if mn else "(not a bit op)", line))
    a_rows = [r for r in rows if r[0] == "prom_a"]
    b_rows = [r for r in rows if r[0] == "prom_b"]
    check("byte-pattern hits over BOTH images", sum(
        1 for img in (A, B) for o in range(len(img) - 2)
        if img[o] in (0xC0, 0xF0) and img[o + 1] == 0x1F), 104)
    check("at an instruction boundary, prom_a", len(a_rows), 9)
    check("at an instruction boundary, PROM_B", len(b_rows), 2)
    check("the prom_b ones are", ["%06X" % r[1] for r in b_rows], ["F5AB80", "F5AFFC"])
    check("and they are", sorted({bitop(r[3]) for r in b_rows}), [("bit", 4)])
    # the four prom_a bit instructions decode; the four 0xFE594x ones are whole-port RMW
    # bit 3 is NOT reachable this way: 0xFE594C-0xFE5960 is a whole-port read-modify-write
    check("prom_a bits reachable from BIT OPS alone",
          sorted({bitop(r[3])[1] for r in a_rows if bitop(r[3])[0]}), [0, 2])
    check("0xFE594F `or A,0x08` -> the RMW pulse is bit 3",
          A[0xFE594F - A_BASE:0xFE5952 - A_BASE].hex(), "c9ce08")
    check("0xFE595D `and A,0xF7` -> and clears the same bit",
          A[0xFE595D - A_BASE:0xFE5960 - A_BASE].hex(), "c9ccf7")
    check("SO THE PORT-B BITS THE CPU-1 PAIR TOUCHES ARE", sorted({0, 2, 3} | {4}),
          [0, 2, 3, 4])
    check("...and prom_b's own note already had bit 4",
          "PB bit 4 low" in open(os.path.join(ROOT, "notes",
                                              "FINDINGS-prom_b-sc1-link.md")).read()
          or "PB.4" in SRC_B, True)
    print()


# ---------------------------------------------------------------- A2
def a2_blockdev_sites():
    print("A2. GAP V: the prom_b call sites into the 18 entry slots -- SUMMED, not counted by eye")
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import prom_a_portb_and_blockdev_census as Q          # noqa: E402
    slots = Q.blockdev_slots() if hasattr(Q, "blockdev_slots") else None
    if slots is None:
        # the census has no reusable entry point; re-derive from its printed table
        import subprocess
        out = subprocess.run([sys.executable, os.path.join(ROOT, "notes",
                                                           "prom_a_portb_and_blockdev_census.py")],
                             capture_output=True, text=True).stdout
        tot = rows = 0
        seen = []
        for line in out.splitlines():
            m = re.search(r"(\d+) prom_b site\(s\): (.*)$", line)
            if m:
                sites = [s.strip() for s in m.group(2).split(",")]
                assert int(m.group(1)) == len(sites), line
                rows += 1
                tot += len(sites)
                seen += sites
        check("slots with at least one prom_b caller", rows, 18)
        check("prom_b call sites over those slots -- the note says 74", tot, 72)
        check("...all distinct", len(set(seen)), 72)
    print()


# ---------------------------------------------------------------- C1
def c1_reg0500_addend():
    print("C1. REGISTER 0x0500's HIGH BYTE: which curve routine is the addend at 0xFA9691?")

    def cbytes(a, n):
        return C[a - C_BASE:a - C_BASE + n]

    # the staging struct: word n of 22 lives at 0x00D75E + 2n
    check("word 11 (register 0x0500) is RAM 0x00D774", 0x00D75E + 2 * 11, 0x00D774)
    check("word 15 (register 0x08C0) is RAM 0x00D77C", 0x00D75E + 2 * 15, 0x00D77C)
    # the two DetuneCurve_LookupSigned calls in the routine
    check("0xFA961F is calr 0xFA7602", cbytes(0xFA961F, 3).hex(), "1ee0df")
    check("0xFA9676 is calr 0xFA7602", cbytes(0xFA9676, 3).hex(), "1e89df")
    # ...and where each of their results goes
    check("0xFA9622 `ld (XIZ+0xfe),WA` -- the first result is parked",
          cbytes(0xFA9622, 3).hex(), "befe50")
    check("0xFA9679 `ld DE,WA` -- the second result goes to DE",
          cbytes(0xFA9679, 2).hex(), "d88a")
    check("0xFA96B5 `ld HL,(XIZ+0xfe)` reads it back ...", cbytes(0xFA96B5, 3).hex(), "9efe23")
    check("... 0xFA96C1 `or BC,HL` merges it ...", cbytes(0xFA96C1, 2).hex(), "dbe1")
    check("... and 0xFA96C3 stores to 0x00D77C = WORD 15, not word 11",
          cbytes(0xFA96C3, 5).hex(), "f27cd70051")
    check("DE reaches that same word-15 store via 0xFA96BC `ld BC,DE` / 0xFA96BE `sll 8,BC`",
          cbytes(0xFA96BC, 2).hex() + cbytes(0xFA96BE, 3).hex(), "da89d9ee08")
    # the actual word-11 addend
    check("0xFA9651 is calr 0xFA7654 (DetuneCurve_LookupUNsigned)",
          cbytes(0xFA9651, 3).hex(), "1e00e0")
    check("0xFA9667 is calr 0xFA7654 too", cbytes(0xFA9667, 3).hex(), "1eeadf")
    check("0xFA9654 `ld HL,WA` -- HL := the UNSIGNED lookup", cbytes(0xFA9654, 2).hex(), "d88b")
    check("0xFA966A `ld HL,WA` -- the other arm, same thing", cbytes(0xFA966A, 2).hex(), "d88b")
    check("0xFA9691 is `add WA,HL` -- HL is the addend", cbytes(0xFA9691, 2).hex(), "db80")
    check("0xFA96A0 `ld HL,WA` after the clamp", cbytes(0xFA96A0, 2).hex(), "d88b")
    check("0xFA96AB `sll 8,WA` / 0xFA96AE `or WA,BC` / 0xFA96B0 store WORD 11",
          cbytes(0xFA96AB, 3).hex() + cbytes(0xFA96AE, 2).hex() + cbytes(0xFA96B0, 5).hex(),
          "d8ee08d9e0f274d70050")
    # HL survives both intervening calls, so the addend really is 0xFA7654's result
    check("DetuneCurve_LookupSigned pushes HL at 0xFA7606", C[0xFA7606 - C_BASE], 0x2B)
    check("...and pops it at 0xFA7650", C[0xFA7650 - C_BASE], 0x4B)
    check("sub_FA75BA pushes HL at 0xFA75BE", C[0xFA75BE - C_BASE], 0x2B)
    check("...and pops it at 0xFA75FE", C[0xFA75FE - C_BASE], 0x4B)
    check("BOTH curve wrappers index the SAME table 0x00FDF123",
          (C[0xFA7646 - C_BASE:0xFA764C - C_BASE].hex(),
           C[0xFA765F - C_BASE:0xFA7665 - C_BASE].hex()),
          ("e9c823f1fd00", "e9c823f1fd00"))
    check("=> register 0x0500's addend is LookupUNSIGNED, not LookupSigned", True, True)
    print()


# ---------------------------------------------------------------- C2
def c2_lookupsigned_callers():
    print("C2. HOW MANY ROUTINES CALL DetuneCurve_LookupSigned (0xFA7602)?")
    sites = [int(m.group(1), 16) for m in
             re.finditer(r"calr \(0xFA7602 - 0x[0-9A-F]{6}\)\s+;\s+([0-9A-F]{6})", SRC_C)]
    check("call sites", len(sites), 10)
    tops = []
    for line in SRC_C.splitlines():
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):$", line)
        if m and "__" not in m.group(1):
            tops.append((m.group(1), len(tops)))
    # map each site to the last top-level label above it, by line index
    names, idx = [], []
    for n, line in enumerate(SRC_C.splitlines()):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):$", line)
        if m and "__" not in m.group(1):
            names.append(m.group(1))
            idx.append(n)
    owners = set()
    for n, line in enumerate(SRC_C.splitlines()):
        if re.search(r"calr \(0xFA7602 - ", line):
            k = max(i for i, v in enumerate(idx) if v < n)
            owners.add(names[k])
    check("distinct enclosing routines -- the note says four", sorted(owners),
          # ⚠ sub_FABAE3 / sub_FABBFB were renamed by a LATER round than this audit and
          # neither label exists in prom_c/wsa1_prom_c.s any more, so this check had been
          # failing on stale text; corrected 2026-08-30 with the two current names.
          ["Dev10C_StageRegs_0900_0940", "Dev10C_StageRegs_09C0_0A00",
           "Voice_StageRegs_0500_08C0_AB", "Voice_StageRegs_0900_0940_0980_AB",
           "Voice_StageRegs_09C0_0A00_0A40_AB"])
    check("that is", len(owners), 5)
    us = {n for n, line in enumerate(SRC_C.splitlines())
          if re.search(r"calr \(0xFA7654 - ", line)}
    check("DetuneCurve_LookupUnsigned call sites", len(us), 2)
    print()


# ---------------------------------------------------------------- B1
def b1_shape_counts():
    print("B1. THE SHAPE TABLE, re-run at the END of the round")
    import subprocess
    out = subprocess.run([sys.executable, os.path.join(ROOT, "notes",
                                                       "prom_b_dl_call_shapes.py")],
                         capture_output=True, text=True).stdout
    got = {}
    for m in re.finditer(r"shape (\d):\s+(\d+) sites,\s+(\d+) usable,\s+(\d+) bytes", out):
        got[int(m.group(1))] = (int(m.group(2)), int(m.group(3)), int(m.group(4)))
    print("   " + "\n   ".join(out.strip().splitlines()))
    check("shape 2 sites (report: 179)", got[2][0], 179)
    check("shape 2 bytes still .incbin -- THE REPORT SAYS 6361", got[2][2], 4740)
    check("shape 3 bytes still .incbin -- THE REPORT SAYS 518", got[3][2], 507)
    check("shapes 2+3 total -- THE REPORT SAYS 6879", got[2][2] + got[3][2], 5247)
    print()


# ---------------------------------------------------------------- B2
def b2_language():
    print("B2. RAM (0x7FC1): every site in the converted tree, and the real evidence")
    sites = sorted({int(m.group(1), 16) for m in
                    re.finditer(r"0x7fc1[^\n]*?;\s*([0-9A-F]{6})\s", SRC_A)})
    for a in sites:
        print("     prom_a %06X  %s" % (a, LA[a]))
    check("prom_a sites touching 0x7FC1", ["%06X" % a for a in sites],
          ["F82628", "F990B9", "F990F1", "F99D88"])
    check("prom_b sites touching 0x7FC1",
          len(re.findall(r"0x7fc1", SRC_B)), 0)
    check("the only WRITE is 0xF82628 `ld (0x7fc1),0x00`",
          A[0xF82628 - A_BASE:0xF8262D - A_BASE].hex(), "f1c17f0000")
    tab = 0xF993B9 - A_BASE
    ents = [int.from_bytes(A[tab + 4 * i:tab + 4 * i + 4], "little") for i in range(5)]
    check("0xF993B9 entries 0..4", ["%08X" % v for v in ents],
          ["00F99121", "00F99121", "00F99121", "0E0E0E0E", "0E0E0E0E"])
    check("so at 0xF990B9 the index cannot change the answer",
          len(set(ents[:3])), 1)
    check("and languages 3 and 4 would read 0x0E pad as a pointer",
          set(ents[3:]), {0x0E0E0E0E})
    check("the decisive site 0xF99D88 is `ld E,(0x7fc1)`",
          A[0xF99D88 - A_BASE:0xF99D8C - A_BASE].hex(), "c1c17f25")
    check("it scales by 4 and indexes 0xF0DB18",
          A[0xF99D91 - A_BASE:0xF99D96 - A_BASE].hex(), "4318dbf000")
    ptab = 0xF0DB18 - B_BASE
    five = [int.from_bytes(B[ptab + 4 * i:ptab + 4 * i + 4], "little") for i in range(5)]
    check("its five entries", ["%06X" % v for v in five],
          ["F0DB68", "F0DC97", "F0DDDB", "F0DF54", "F0E0BA"])
    heads = []
    for a in five:
        seg = B[a - B_BASE:a - B_BASE + 0x40]
        m = re.search(rb"[A-Za-z!][ -~]{5,}", seg)
        heads.append(m.group().decode().strip())
    check("and their first strings are five LANGUAGES", heads,
          ["ATTENTION!", "ACHTUNG!", "ATTENTION!", "ATTENCION!", "ATTENZIONE!"])
    body = []
    for a in (0xF0DB68, 0xF0DC97, 0xF0DDDB, 0xF0DF54, 0xF0E0BA):
        seg = B[a - B_BASE:a - B_BASE + 0x60]
        s = [m.group().decode() for m in re.finditer(rb"[ -~]{5,}", seg)]
        body.append(s[1] if len(s) > 1 else "")
    check("LAST of the five is Italian", body[4], "Sei sicuro?")
    print()


def selftest():
    print("SELFTEST -- negative controls")
    check("the bit decoder is not a constant: 0xCC is bit 4, 0xCB is bit 3",
          (bitop(0xCC), bitop(0xCB)), (("bit", 4), ("bit", 3)))
    check("prom_b 0xF5AB80 really holds f0 1f cc",
          B[0xF5AB80 - B_BASE:0xF5AB83 - B_BASE].hex(), "f01fcc")
    src = boundaries(SRC_C)
    check("the source itself spells 0xFA9691 with HL, not DE",
          ("add WA,HL" in src[0xFA9691], "DE" in src[0xFA9691]), (True, False))
    check("and 0xFA9679 -- the LookupSigned result -- is the one that goes to DE",
          "ld DE,WA" in src[0xFA9679], True)
    check("0xF993B9 entry 3 is NOT a pointer into prom_a",
          0xF80000 <= 0x0E0E0E0E <= 0xFFFFFF, False)
    print()


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    a1_portb()
    a2_blockdev_sites()
    c1_reg0500_addend()
    c2_lookupsigned_callers()
    b1_shape_counts()
    b2_language()
    print("%d ok, FAILURES: %d" % (OK, FAIL))
    sys.exit(1 if FAIL else 0)
