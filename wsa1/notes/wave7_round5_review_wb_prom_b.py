#!/usr/bin/env python3
"""REVIEW-WB: are round 5's new prom_b names carried by their evidence?

QUESTION IT ANSWERS
    "88 framed prom_b labels were promoted to content names and 16,289 bytes at
     0xF353AB were converted with 15 named labels.  Independently of the lane's
     own scripts, does the ROM carry every one of those names -- and is every
     quantified claim in the new headers true?"

Nothing here imports the lane's scripts.  Every number is re-derived from
original_ROMs/ and from the committed .s text, so a bug in the lane's tooling
cannot make this file agree with it.

WHAT IT CHECKS, and what each answer means
  1  RENAME PAIRS.  Recovers the 88 old->new label pairs from `git diff` and
     asserts the count.
  2  TABLE NAMES vs THE ROM.  For each of the 60 Text_/StringTable_/DLTable_/
     DLBTable_/Table_ renames, reads the object's bytes STRAIGHT OUT OF THE ROM
     and asserts the new name's letters occur there.  Reports, separately, the
     tables whose name does NOT start at entry 0 -- the Evidence boilerplate
     says "CamelCase of its first entries" and for those it is the first
     LETTER-BEARING entries.
  3  M3 CAPTION ARITHMETIC.  For five named readout lists, finds the caption
     record in the ROM and asserts  pos + (len - 4) == the readout's IX  with
     no tolerance.  This is the whole of the M3 claim.
  4  CALL-SITE CITATIONS.  Every "Called from:" address in the new span must be
     a `call`/`calr` line in the transcription whose target is the routine the
     header sits on -- the tree's off-by-one signature is a cited address whose
     predecessor is the opcode.
  5  THE UNCLAIMED RUN.  Re-measures, O(n^2) over the ROM, the longest repeated
     byte run in 0xF38C4F-0xF38CFE and the link/unlk positions.  ⚠ THE SPAN
     HEADER SAYS 76 BYTES AND THE OBJECT HEADER SAYS 77.  77 is right.
  6  THE PACK TWINS' WIDTHS.  0xF36849 ORs through XWA/XIY (32-bit) and
     0xF36800 through DE/BC/WA (16-bit).  ⚠ THE 0xF36849 HEADER CLAIMS "the
     same 16-bit truncation as its twin".  It does not truncate.
  7  THE RESIDUE BOUND.  `cp IY,0x0029` = 41 admits 0..41.  ⚠ TWO HEADERS CALL
     41 "the largest residue mod 43".  The largest residue mod 43 is 42.
  8  CODE-LABEL COUNTS.  56 code labels in the span, 49 of them sub_XXXXXX.
     ⚠ THE GENERATOR DOCSTRING SAYS "45 of the 53".
  9  MORPHEMES.  Every alphabetic morpheme of >=3 letters in every new name is
     searched for, case-insensitively, in ALL FOUR ROM IMAGES.  This is the
     round-3 "Home" test: a name built on a word no image contains is invented.
 10  NEW PROSE, NOT WHITESPACE.  Counts added comment lines against removed
     blank lines, because a past round's "+35 headers" was 35 deleted blanks.

RUN
    python3 notes/wave7_round5_review_wb_prom_b.py
Exit status is 0 when every check that SHOULD hold holds; the six ⚠ items above
are reported as FINDINGS and are expected to fail until they are corrected.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
BASE = 0xF00000
IMAGES = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13",
          "c": "wsa1_prom_c.ic28", "d": "wsa1_prom_d.bin"}
LAB = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR = re.compile(r';\s*([0-9A-F]{6})\b')
ASC = re.compile(r'\.ascii\s+"([^"]*)"')
SPAN = (0xF353AB, 0xF3934C)

_ok = _bad = 0
FINDINGS = []


def check(label, got, want):
    global _ok, _bad
    if got == want:
        _ok += 1
        print("  ok    %s" % label)
    else:
        _bad += 1
        print("  FAIL  %s\n          got %r want %r" % (label, got, want))


def finding(label, got, claimed):
    FINDINGS.append((label, got, claimed))
    print("  ⚠ FINDING  %s\n          measured %r ; the header claims %r"
          % (label, got, claimed))


def rom(k):
    return open(os.path.join(ROOT, "original_ROMs", IMAGES[k]), "rb").read()


def src():
    return open(SRCB).read().split("\n")


def norm(s):
    return re.sub(r'[^A-Za-z0-9]', '', s).lower()


def camel(s):
    return "".join(w[0].upper() + w[1:].lower()
                   for w in re.split(r"[^A-Za-z0-9]+", s) if w)


def label_lines():
    """{label: line index} for the first definition of every column-0 label."""
    out = {}
    for i, l in enumerate(src()):
        m = LAB.match(l)
        if m:
            out.setdefault(m.group(1), i)
    return out


def pairs():
    """The (old, new) label renames, recovered from the uncommitted diff.

    A `-LABEL:` line followed, inside the same hunk, by a `+LABEL:` line."""
    d = subprocess.run(["git", "-C", ROOT, "diff", "-U0", "--",
                        "prom_b/wsa1_prom_b.s"],
                       capture_output=True, text=True).stdout.split("\n")
    pat = re.compile(r'^([-+])([A-Za-z_][A-Za-z0-9_]*):$')
    out = []
    for i, l in enumerate(d):
        m = pat.match(l)
        if not (m and m.group(1) == "-"):
            continue
        for j in range(i + 1, min(i + 40, len(d))):
            if d[j].startswith("@@"):
                break
            m2 = pat.match(d[j])
            if m2 and m2.group(1) == "+":
                out.append((m.group(2), m2.group(2)))
                break
    return out


# ---------------------------------------------------------------- the checks
def c1_pairs(P):
    print("\n1  RENAME PAIRS")
    check("88 framed labels were promoted to content names", len(P), 88)
    kinds = sorted(set(o.split("_")[0] for o, _n in P))
    check("the kinds renamed", kinds,
          ["DL", "DLBTable", "DLTable", "StringTable", "Table", "Text"])


def c2_tables(P):
    print("\n2  TABLE NAMES vs THE ROM BYTES  (independent of the lane's reader)")
    b = rom("b")
    tabs = [p for p in P if re.match(r'^(Text|StringTable|DLTable|DLBTable|Table)_', p[0])]
    check("text-bearing objects renamed", len(tabs), 60)
    miss = []
    for old, new in tabs:
        a = int(old.split("_")[-1], 16)
        window = b[a - BASE:a - BASE + 4000]
        have = norm("".join(chr(c) if 32 <= c < 127 else " " for c in window))
        if norm(new.split("_", 1)[1]) not in have:
            miss.append(new)
    check("every renamed table's name occurs verbatim in its own ROM bytes",
          miss, [])

    # and where does the name START?  The boilerplate says "its first entries".
    S, LL = src(), label_lines()
    late = []
    for _old, new in tabs:
        i = LL[new]
        j = i + 1
        while j < len(S) and not LAB.match(S[j]):
            j += 1
        ents = [m.group(1) for k in range(i + 1, j) for m in [ASC.search(S[k])] if m]
        if not ents:
            continue
        lead = 0
        for e in ents:
            if re.search(r'[A-Za-z]', e):
                break
            lead += 1
        if lead:
            late.append((new, lead, len(ents)))
    if late:
        finding("the M4 boilerplate says the name is CamelCase of the object's "
                "FIRST entries; for these it is the first LETTER-BEARING ones",
                sorted(late), "first entries")
    else:
        check("every table name starts at entry 0", late, [])


def c3_captions():
    print("\n3  M3 CAPTION ARITHMETIC  (pos + (len-4) == the readout's IX, exactly)")
    b = rom("b")
    # (caption text as the ROM spells it, the IX the named list prints at)
    cases = [(" REALTIME COMMANDS : ", 0x0B7F, "DL_RealtimeCommandsClock"),
             (" CLOCK  :", 0x17A3, "DL_RealtimeCommandsClock"),
             ("P0SITI0N  :", 0x1236, "DL_P0siti0n"),
             ("MEMORY BANK:", 0x1373, "DL_MemoryBank"),
             ("LAST MEASURE    :", 0x175C, "DL_LastMeasure"),
             ("AFTER TOUCH RECORD :", 0x1467, "DL_AfterTouchRecord")]
    for txt, ix, who in cases:
        t = txt.encode("latin1")
        hit, i = None, b.find(t)
        while i >= 0:
            ln, pos = b[i - 3], b[i - 2] | (b[i - 1] << 8)
            if b[i - 4] in (0x07, 0x20) and ln - 4 == len(txt) and pos + (ln - 4) == ix:
                hit = BASE + i - 4
                break
            i = b.find(t, i + 1)
        check("%s: a caption %r ends exactly at 0x%04X" % (who, txt, ix),
              hit is not None, True)
    # ...and the rule needs no tolerance: shift the position by one and it misses
    t = b" CLOCK  :"
    i = b.find(t)
    check("shifting that caption's end by one byte does NOT reach 0x17A3",
          (b[i - 2] | (b[i - 1] << 8)) + (b[i - 3] - 4) + 1 == 0x17A3, False)


def c4_citations():
    print("\n4  CALL-SITE CITATIONS  (an instruction start, and the right target)")
    S = src()
    ins = {}
    for l in S:
        if l.startswith(";") or not l.strip():
            continue
        m = ADDR.search(l)
        if m:
            ins[int(m.group(1), 16)] = l
    want = {0xF36FAC: 0xF36800, 0xF379B5: 0xF36800,
            0xF37584: 0xF3702F, 0xF3799A: 0xF3702F,
            0xF36D0E: 0xF37F3A, 0xF36D54: 0xF37F3A,
            0xF375BA: 0xF37F3A, 0xF37BFA: 0xF37F3A,
            0xF3708D: 0xF37F91, 0xF37182: 0xF37F91, 0xF375F4: 0xF37F91,
            0xF37A0F: 0xF37069, 0xF37BD5: 0xF37594}
    bad = []
    for site, target in sorted(want.items()):
        l = ins.get(site, "")
        if not re.search(r'\bcal[lr]\b', l) or ("0x%06x" % target) not in l.lower():
            bad.append("0x%06X" % site)
    check("all %d cited call sites are call/calr at the cited address, with "
          "the cited target" % len(want), bad, [])
    # the six thunk slots the span says the ids arrive through
    b = rom("b")
    slots = [0xF41250 + 4 * i for i in range(6)]
    tgt = []
    for s in slots:
        o = s - BASE
        tgt.append(b[o] == 0x1B and SPAN[0] <= (b[o + 1] | b[o + 2] << 8 | b[o + 3] << 16) < SPAN[1])
    check("T_F41250..T_F41264 are six `jp` slots landing inside the span",
          tgt, [True] * 6)
    check("0xF7AE62 spells 0x00F37E23 as an LE32, the lead the header leaves open",
          b[0xF7AE62 - BASE:0xF7AE62 - BASE + 4], bytes([0x23, 0x7E, 0xF3, 0x00]))


def c5_unclaimed():
    print("\n5  THE UNCLAIMED RUN 0xF38C4F-0xF38CFE")
    b = rom("b")
    lo, hi = 0xF38C4F, 0xF38CFF
    seg = b[lo - BASE:hi - BASE]
    n, best = len(seg), (0, None, None)
    for i in range(n):
        for j in range(i + 1, n):
            k = 0
            while j + k < n and seg[i + k] == seg[j + k]:
                k += 1
            if k > best[0]:
                best = (k, lo + i, lo + j)
    check("one `link XIZ` (EE 0C), at 0xF38C4F",
          [lo + i for i in range(n - 1) if seg[i] == 0xEE and seg[i + 1] == 0x0C],
          [0xF38C4F])
    check("three `unlk XIZ` (EE 0D)",
          ["0x%06X" % (lo + i) for i in range(n - 1)
           if seg[i] == 0xEE and seg[i + 1] == 0x0D],
          ["0xF38CA0", "0xF38CED", "0xF38CFD"])
    check("the longest repeated run is 77 bytes at 0xF38C56 and 0xF38CA3",
          best, (77, 0xF38C56, 0xF38CA3))
    txt = "\n".join(src())
    if "byte-identical for 76 bytes" in txt:
        finding("the SPAN header still carries the withdrawn 76-byte figure, "
                "which the object header 3,000 lines below calls wrong",
                "77 bytes at 0xF38C56", "76 bytes")


def c6_pack_widths():
    print("\n6  THE PACK TWINS' REGISTER WIDTHS")
    b = rom("b")

    def at(a, n):
        return b[a - BASE:a - BASE + n]
    # 0xF36800's merge: 16-bit (ld IY,(XIZ+0xfc) / or DE,WA / or BC,DE / ld WA,BC)
    check("0xF36838 is `ld IY,(XIZ+0xfc)`, a 16-bit load of a 32-bit slot",
          at(0xF36838, 3), bytes([0x9E, 0xFC, 0x25]))
    check("0xF3683D/0xF3683F are the 16-bit `or DE,WA` / `or BC,DE`",
          (at(0xF3683D, 2), at(0xF3683F, 2)),
          (bytes([0xD8, 0xE2]), bytes([0xDA, 0xE1])))
    # 0xF36849's merge: 32-bit (or XWA,(XIZ+0xfc) / or XWA,XBC / ld XIY,XWA)
    check("0xF3687D is `or XWA,(XIZ+0xfc)`, a 32-bit OR",
          at(0xF3687D, 3), bytes([0xAE, 0xFC, 0xE0]))
    check("0xF36880/0xF36882 are the 32-bit `or XWA,XBC` / `ld XIY,XWA`",
          (at(0xF36880, 2), at(0xF36882, 2)),
          (bytes([0xE9, 0xE0]), bytes([0xE8, 0x8D])))
    txt = "\n".join(src())
    if "the same 16-bit truncation as its twin" in txt:
        finding("Pack3x7BitFields_Bytes6To8 (0xF36849) merges through XWA/XIY, "
                "32-bit, so it does NOT truncate and does not differ from its "
                "twin only in its return register",
                "32-bit ORs, full 21-bit result",
                "the same 16-bit truncation as its twin")


def c7_residue():
    print("\n7  THE RESIDUE BOUND AT 0xF37093")
    b = rom("b")
    # cp IY,0x0029  then  jrl UGT
    check("the divisor pushed at 0xF37089 is 43", b[0xF3708A - BASE], 0x2B)
    check("the bound compared at 0xF37093 is 41",
          b[0xF37095 - BASE] | (b[0xF37096 - BASE] << 8), 0x0029)
    check("residues mod 43 run 0..42, so the LARGEST is 42", 43 - 1, 42)
    txt = "\n".join(src())
    if "largest residue mod 43" in txt:
        finding("the bound 41 admits 0..41, i.e. 42 of the 43 residues; it is "
                "NOT the largest residue",
                "largest residue mod 43 = 42, bound = 41",
                "41 is exactly the largest residue mod 43")


def c8_label_counts():
    print("\n8  CODE-LABEL COUNTS IN THE SPAN")
    S = src()
    lo, hi = SPAN
    rows = []
    for i, l in enumerate(S):
        m = LAB.match(l)
        if not m:
            continue
        a = None
        for k in range(i, min(i + 6, len(S))):
            mm = ADDR.search(S[k])
            if mm and not S[k].startswith(";"):
                a = int(mm.group(1), 16)
                break
        if a is None or not (lo <= a < hi):
            continue
        kind = "data"
        for k in range(i + 1, len(S)):
            s = S[k].strip()
            if not s or s.startswith(";"):
                continue
            if s.startswith((".long", ".ascii", ".fill", ".short")):
                kind = "data"
            elif s.startswith(".byte"):
                kind = "code" if "llvm-mc cannot encode" in S[k] else "data"
            else:
                kind = "code"
            break
        rows.append((m.group(1), kind))
    code = [r for r in rows if r[1] == "code"]
    check("64 labels in the span", len(rows), 64)
    check("56 of them are code labels", len(code), 56)
    check("49 of the code labels are sub_XXXXXX",
          sum(1 for n, _k in code if n.startswith("sub_")), 49)
    gen = open(os.path.join(ROOT, "notes",
                            "gen_prom_b_f353ab_module.py")).read()
    if "45 of the 53 code labels" in gen:
        finding("the generator's docstring counts the span's code labels",
                "49 of 56", "45 of the 53")


def c9_morphemes(P):
    print("\n9  MORPHEMES  (the round-3 'Home' test, over ALL FOUR images)")
    imgs = {k: rom(k) for k in IMAGES}
    names = [n for _o, n in P] + [
        "ClampFieldToRange", "ClampParamValueById_From541",
        "ClampParamValueById_From408", "Divide32_Unsigned_Quotient",
        "Divide32_Unsigned_Remainder", "Pack3x7BitFields_Bytes6To8",
        "Pack3x7BitFields_Bytes9To11", "DL_YesAreYouSure"]
    # Structural English that describes what the CODE does is allowed to be
    # absent from the ROM; a word a name claims the ROM SAYS is not.
    STRUCTURAL = {"Clamp", "Field", "Range", "Param", "Value", "Bytes",
                  "Quotient", "Remainder", "Unsigned", "Divide", "Pack",
                  "Fields", "From", "Table", "Arms", "Unclaimed"}
    words = set()
    for n in names:
        body = n.split("_", 1)[1] if "_" in n else n
        for w in re.findall(r'[A-Z][a-z]{2,}', body):
            words.add(w)
    absent = sorted(w for w in words if w not in STRUCTURAL
                    and not any(re.search(re.escape(w).encode(), d, re.I)
                                for d in imgs.values()))
    check("every ROM-text morpheme in a new name occurs in some image", absent, [])


def c10_prose():
    print("\n10 NEW PROSE, NOT DELETED WHITESPACE")
    d = subprocess.run(["git", "-C", ROOT, "diff", "--", "prom_b/wsa1_prom_b.s"],
                       capture_output=True, text=True).stdout.split("\n")
    add_c = sum(1 for l in d if l.startswith("+;"))
    del_blank = sum(1 for l in d if l == "-")
    print("     added comment lines: %d   removed blank lines: %d" % (add_c, del_blank))
    check("the header gain is new prose, not removed blank lines",
          (add_c > 1000, del_blank), (True, 0))


def main():
    P = pairs()
    c1_pairs(P)
    c2_tables(P)
    c3_captions()
    c4_citations()
    c5_unclaimed()
    c6_pack_widths()
    c7_residue()
    c8_label_counts()
    c9_morphemes(P)
    c10_prose()
    print("\n%d checks passed, %d failed, %d findings" % (_ok, _bad, len(FINDINGS)))
    for f in FINDINGS:
        print("  ⚠ %s" % f[0])
    return 1 if _bad else 0


if __name__ == "__main__":
    sys.exit(main())
