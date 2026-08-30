#!/usr/bin/env python3
"""REVIEW-WD3 round 6 -- ARE prom_d's ROUND-6 NAMES CARRIED BY THEIR EVIDENCE?

QUESTION IT ANSWERS
    notes/prom_d_understanding_round6.py promoted 301 framed labels in prom_d:
    293 of the form `..._SameAs_<name>` on two wave-select arrays, and 9 spellings
    of the +0xA8 block, renamed `Unk_0FC8_Table` -> `ToneDB_OctaveShiftByProgram`.
    This script does NOT import round 6.  It re-reads the four ROM images and
    prom_c's gate-verified assembly and re-derives every load-bearing number, so
    a claim and its check cannot fail together.

    Every number quoted in the REVIEW-WD3 round-6 report comes from here.

WHAT IT CHECKS
    R1  the +0x18 twin census, re-derived: 322 records, 167 at Hamming distance
        exactly 1 from a tone wave-select block, the differing byte +0x0B in ALL
        of them, 152 resolving to one tone name -- and the NULL, that masking any
        OTHER single position instead finds 0.
    R2  the +0x20 census, re-derived: 196 of 208 byte-identical to a drum tail,
        106 one-name + 35 trailing-digit stems = 141 labelable.
    R3  ★ EVERY ONE of the 293 `_SameAs_` LABELS READ OUT OF THE .s AND CHECKED
        AGAINST THE BYTES: the named record must exist, its name must be the
        CamelCase of its own ASCII field, and the two 43-byte runs must be equal
        (drum) or equal outside +0x0B (melodic).  This is the test that decides
        whether the names are LOCATED or IDENTIFIED, and it is exhaustive rather
        than a sample.
    R4  the +0xA8 octave table, re-derived from the image: 84 nonzero cells,
        {-12: 79, +12: 5}, 11 marked columns, 3 distinct row byte-strings
        differing only at programs 14 and 122, 0 printable bytes, and the block
        ending exactly where the first tone record begins.
    R5  the READER, re-decoded from prom_c's ROM bytes rather than the listing:
        sub_FA72E9's two arms, the 16-entry sibling table at 0xFDF22A, and the
        two `sll` opcodes that make a byte table readable with a word load.
    R6  ★ THE MORPHEME TEST that caught round 3's "Home": every significant word
        of every new name, counted over all four images.
    R7  the citations: every prom_c address the round quotes is an instruction
        start in the gate-verified listing, and none has the round-1 "byte at
        cited-1 is 0x44/0x45/0x46" one-byte-off signature.
    R8  the header gain is NEW PROSE, not round 3's whitespace artefact.
    R9  ★ THE DEFECT THIS REVIEW FOUND, and it ships 142 times.  The catalogue
        banner says the +0x8C catalogue "names something no drum record has 18
        times".  18 is correctly computed but it is the OTHER direction: it is
        the count of LABEL NAMES that appear NOWHERE in the catalogue.  The
        sentence as written is measured here in both of its possible readings and
        neither gives 18 -- catalogue-wide it is 47, and at those 18 indices it
        is 8.  The refusal the sentence supports is UNAFFECTED; the English is
        what is wrong.
    R10 the two typed numbers that contradict derived ones in the same sentence:
        "the 84 marks ... 85 marks placed at random", and the FINDINGS file's
        "38 checks" against the script's own 40.

HOW TO RUN
    python3 notes/wave7_round6_review_wd3_prom_d.py
    Exit status is non-zero if any REVIEW check fails.  R9 and R10 are recorded
    as FINDINGS, not failures: they are the review's output, not its gate.
"""
import collections
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
IMG = {"prom_a": "wsa1_prom_a.ic12", "prom_b": "wsa1_prom_b.ic13",
       "prom_c": "wsa1_prom_c.ic28", "prom_d": "wsa1_prom_d.bin"}
D = open(os.path.join(ROOT, "original_ROMs", IMG["prom_d"]), "rb").read()
C = open(os.path.join(ROOT, "original_ROMs", IMG["prom_c"]), "rb").read()
PROM_C_BASE = 0xF80000
FAILED = []
FINDINGS = []


def check(label, cond, detail=""):
    print("  %-4s %-66s %s" % ("PASS" if cond else "FAIL", label, detail))
    if not cond:
        FAILED.append(label)


def finding(label, detail):
    print("  %-4s %-66s %s" % ("FIND", label, detail))
    FINDINGS.append(label)


# --- the image, re-read independently of the lane -------------------------
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]
BOUNDS = sorted(set(v for v in DIR if v != 0xFFFFFFFF)) + [0x50B08]
ST = u16(0xEA)                       # 43, the directory's own stride word
PS = u16(0xEE)                       # 150, the drum-instrument stride
PRESET = 0x0B


def nb(a):
    return min(v for v in BOUNDS if v > a)


def camel(s):
    out = re.sub(r"[^A-Za-z0-9]+", " ", s).strip()
    return "".join(p[0].upper() + p[1:] for p in out.split() if p) or "Unnamed"


def stem(s):
    return re.sub(r"\d+$", "", s)


NPTR = (S(0xA8) - S(0x08)) // 4
TP = [u32(S(0x08) + 4 * i) for i in range(NPTR)]


def tone_end(p):
    return min([q for q in sorted(set(TP)) if q > p] + [x for x in BOUNDS if x > p])


def tone_blocks():
    """(tone, element, 43 bytes, CamelCase name, file offset) per tone element."""
    out = []
    for i, p in enumerate(TP):
        size = tone_end(p) - p
        if size < 217 or (size - 217) % 124:
            continue
        n = (size - 217) // 124
        nm = camel(D[p:p + 16].decode("latin1"))
        for j in range(n):
            a = p + 217 + 81 * n + ST * j
            out.append((i, j, D[a:a + ST], nm, a))
    return out


def drum_tails():
    a = S(0x78)
    n = (nb(a) - a) // PS
    return [(i, D[a + PS * i + (PS - ST): a + PS * (i + 1)],
             camel(D[a + PS * i: a + PS * i + 13].decode("latin1"))) for i in range(n)]


def recs(slot):
    a = S(slot)
    n = (nb(a) - a) // ST
    return a, n, [D[a + ST * i: a + ST * (i + 1)] for i in range(n)]


def ham(x, y):
    return sum(1 for p, q in zip(x, y) if p != q)


BLOCKS = tone_blocks()
TAILS = drum_tails()


# --- R1 --------------------------------------------------------------------
def r1():
    print("\n=== R1.  THE +0x18 TWIN CENSUS, RE-DERIVED ===\n")
    a, n, rs = recs(0x18)
    check("R1a  the array divides exactly into 43-byte records",
          n == 322 and a + ST * n == nb(a), "0x%05X..0x%05X = %d records" % (a, nb(a), n))
    check("R1b  tone wave-select blocks to match against", len(BLOCKS) == 451,
          "%d blocks over %d tone records" % (len(BLOCKS), len(set(b[0] for b in BLOCKS))))
    hist, pos, twins = collections.Counter(), collections.Counter(), {}
    for i, r in enumerate(rs):
        best = min(ham(r, b[2]) for b in BLOCKS)
        hist[best] += 1
        if best == 1:
            ms = [b for b in BLOCKS if ham(r, b[2]) == 1]
            twins[i] = ms
            for b in ms:
                pos[next(k for k in range(ST) if r[k] != b[2][k])] += 1
    check("R1c  records at Hamming distance EXACTLY 1", hist[1] == 167,
          "%d of %d" % (hist[1], n))
    check("R1d  ★ the differing byte is +0x0B in every distance-1 PAIR",
          set(pos) == {PRESET}, "positions over all %d pairs: %s" % (sum(pos.values()), dict(pos)))
    check("R1e  no record is at distance 0", hist[0] == 0, "round 5's zero reproduced")
    print("       full distance histogram (%d records): %s"
          % (n, dict(sorted(hist.items()))))
    uniq = {i: sorted(set(b[3] for b in ms)) for i, ms in twins.items()}
    one = [i for i in uniq if len(uniq[i]) == 1]
    check("R1f  twins resolving to exactly ONE tone name", len(one) == 152,
          "%d of %d; %d ambiguous; first %d->%s, last %d->%s"
          % (len(one), len(twins), len(twins) - len(one),
             min(one), uniq[min(one)][0], max(one), uniq[max(one)][0]))
    check("R1g  the no-twin remainder is stated correctly in the per-record headers",
          n - hist[1] == 155, "%d with a twin, %d without" % (hist[1], n - hist[1]))
    # NULL: mask some OTHER position instead
    best_other, who = 0, None
    for k in range(ST):
        if k == PRESET:
            continue
        bl = set(b[2][:k] + b[2][k + 1:] for b in BLOCKS)
        cnt = sum(1 for r in rs if r[:k] + r[k + 1:] in bl)
        if cnt > best_other:
            best_other, who = cnt, k
    check("R1h  ★ NULL: masking any OTHER single position finds nothing",
          best_other == 0, "best other position %s scores %d against +0x0B's 167"
          % (who, best_other))


# --- R2 --------------------------------------------------------------------
def r2():
    print("\n=== R2.  THE +0x20 CENSUS, RE-DERIVED ===\n")
    a, n, rs = recs(0x20)
    exact = {i: [t for t in TAILS if t[1] == r] for i, r in enumerate(rs)}
    exact = {i: v for i, v in exact.items() if v}
    check("R2a  records BYTE-IDENTICAL to a drum-instrument wave-select tail",
          len(exact) == 196 and n == 208, "%d of %d" % (len(exact), n))
    uniq = {i: sorted(set(t[2] for t in v)) for i, v in exact.items()}
    one = [i for i in uniq if len(uniq[i]) == 1]
    st = [i for i in uniq if len(uniq[i]) > 1 and len(set(stem(x) for x in uniq[i])) == 1]
    check("R2b  one-name twins", len(one) == 106, "%d" % len(one))
    check("R2c  trailing-digit stems", len(st) == 35, "%d" % len(st))
    check("R2d  labelable total", len(one) + len(st) == 141,
          "%d; first %d->%s, last %d->%s" % (len(one) + len(st), min(one), uniq[min(one)][0],
                                             max(one + st), uniq[max(one + st)][0]))


# --- R3 --------------------------------------------------------------------
def r3():
    print("\n=== R3.  ★ ALL 293 `_SameAs_` LABELS, READ OUT OF THE .s, "
          "CHECKED AGAINST THE BYTES ===\n")
    mel = collections.defaultdict(list)
    for i, j, b, nm, off in BLOCKS:
        mel[nm].append((j, b, off))
    perc = collections.defaultdict(list)
    for i, b, nm in TAILS:
        perc[nm].append((i, b))
    base = {"ToneDB_MixerDefaultTable": S(0x18), "ToneDB_PercMixerDefaultTable": S(0x20)}
    src = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read().split("\n")
    labs = []
    for ln in src:
        m = re.match(r"^(ToneDB_(?:Perc)?MixerDefaultTable)_(\d{3})_SameAs_([A-Za-z0-9_]+):", ln)
        if m:
            labs.append((m.group(1), int(m.group(2)), m.group(3)))
    bad = []
    for blk, idx, rest in labs:
        rec = D[base[blk] + ST * idx: base[blk] + ST * (idx + 1)]
        if blk.endswith("PercMixerDefaultTable"):
            cands = perc.get(rest) or [c for k, v in perc.items() if stem(k) == rest for c in v]
            if not cands:
                bad.append((blk, idx, rest, "no drum record carries that name or stem"))
            elif not [c for c in cands if c[1] == rec]:
                bad.append((blk, idx, rest, "named record's tail differs from these bytes"))
        else:
            m = re.match(r"^(.*)_WaveSel(\d+)$", rest)
            nm, el = (m.group(1), int(m.group(2))) if m else (rest, None)
            cands = [c for c in mel.get(nm, []) if el is None or c[0] == el]
            if not cands:
                bad.append((blk, idx, rest, "no tone record / element with that name"))
            elif not [c for c in cands
                      if c[1][:PRESET] == rec[:PRESET] and c[1][PRESET + 1:] == rec[PRESET + 1:]]:
                bad.append((blk, idx, rest, "block differs outside +0x0B"))
    check("R3a  every `_SameAs_` label in the .s is carried by the bytes",
          len(labs) == 293 and not bad,
          "%d labels checked, %d refuted%s"
          % (len(labs), len(bad), "" if not bad else " -- " + repr(bad[:3])))
    byaddr = sorted(labs, key=lambda t: base[t[0]] + ST * t[1])
    check("R3b  the LAST label in address order is checked too", bool(byaddr),
          "%s_%03d_SameAs_%s at file 0x%05X"
          % (byaddr[-1][0], byaddr[-1][1], byaddr[-1][2],
             base[byaddr[-1][0]] + ST * byaddr[-1][1]))
    check("R3c  the 35 stem labels DISCLOSE the stem in their header",
          sum(1 for ln in src if "label uses the shared stem" in ln) == 35,
          "%d disclosures for 35 stem labels"
          % sum(1 for ln in src if "label uses the shared stem" in ln))


# --- R4 --------------------------------------------------------------------
def r4():
    print("\n=== R4.  THE +0xA8 OCTAVE TABLE, RE-DERIVED FROM THE IMAGE ===\n")
    T = S(0xA8)
    cells, cols, rows = collections.Counter(), collections.Counter(), []
    for bank in range(8):
        for prog in range(128):
            v = D[T + 128 * bank + prog]
            if v:
                sv = v - 256 if v > 127 else v
                cells[sv] += 1
                cols[prog] += 1
    check("R4a  nonzero cells and their values", sum(cells.values()) == 84
          and dict(cells) == {-12: 79, 12: 5}, "%d cells %s" % (sum(cells.values()), dict(cells)))
    check("R4b  the marked columns", sorted(cols) == [14, 88, 89, 90, 91, 92, 93, 94, 95, 122, 126],
          "%s" % sorted(cols))
    check("R4c  programs 88-95 are marked in EVERY bank",
          all(cols[p] == 8 for p in range(88, 96)), "%s" % {p: cols[p] for p in range(88, 96)})
    check("R4d  the block ends exactly where the first tone record begins",
          T + 8 * 128 == min(TP), "0x%05X + 1024 = 0x%05X = first tone pointer" % (T, min(TP)))
    cl = collections.defaultdict(list)
    for b in range(8):
        cl[D[T + 128 * b: T + 128 * (b + 1)]].append(b)
    dif = sorted({k for a in cl for b in cl for k in range(128) if a[k] != b[k]})
    check("R4e  3 distinct row byte-strings, differing only at programs 14 and 122",
          len(cl) == 3 and dif == [14, 122], "%s ; differ at %s" % (list(cl.values()), dif))
    check("R4f  0 printable bytes in the 1024",
          sum(1 for k in range(1024) if 32 <= D[T + k] < 127) == 0, "content carries no name")
    # the program map names the marked columns
    PB = S(0x04)
    fam = {}
    for prog in sorted(cols):
        fam[prog] = sorted({D[TP[u16(PB + 256 * b + 2 * prog)]:
                              TP[u16(PB + 256 * b + 2 * prog)] + 16].decode("latin1").strip()
                            for b in range(8) if D[T + 128 * b + prog]})
    check("R4g  ★ the marked columns name themselves through the +0x04 program map",
          fam[88] == ["Jazz Organ"] and fam[122] == ["Agogo"] and fam[126] == ["Timpani"],
          "88=%s 122=%s 126=%s" % (fam[88], fam[122], fam[126]))
    print("       every marked column: %s" % {p: fam[p] for p in sorted(fam)})
    n = sum(cells.values())
    exp = 128 * (1 - (127 / 128) ** n)
    check("R4h  NULL: %d random marks would fill ~%.0f of 128 columns, not 11" % (n, exp),
          exp > 55, "E[distinct columns] = %.1f against the observed 11" % exp)


# --- R5 --------------------------------------------------------------------
def r5():
    print("\n=== R5.  THE READER, RE-DECODED FROM prom_c's ROM BYTES ===\n")
    sib = [v - 256 if v > 127 else v for v in C[0xFDF22A - PROM_C_BASE:][:16]]
    check("R5a  the sibling table at 0xFDF22A is 16 multiples of 12, centred on 0",
          all(v % 12 == 0 for v in sib) and sib[8] == 0 and sib[0] == -96 and sib[15] == 84,
          "%s" % sib)
    for a, want, what in ((0xFA7351, b"\xd9\xee\x07", "sll 0x07,BC -- bank * 128"),
                          (0xFA735F, b"\xd9\xee\x08", "sll 0x08,BC -- the value's encoding"),
                          (0xFA7332, b"\xe3\xe1\xa8\x00\x25", "ld XIY,(XWA+0x00a8)"),
                          (0xFA7301, b"\xa9\x6c\x20", "ld XWA,(XBC+0x6c) -- ToneDB_BankMap"),
                          (0xFA735D, b"\x95\x21", "ld BC,(XIY) -- a 16-bit load"),
                          (0xFA7375, b"\xcb\xcc\x0f", "and C,0x0f -- a 4-bit octave field"),
                          (0xFBC7D6, b"\xb8\x0b\x46", "ld (XWA+0x0b),H -- the +0x0B write")):
        got = C[a - PROM_C_BASE: a - PROM_C_BASE + len(want)]
        check("R5b  0x%06X" % a, got == want, "%s = %s" % (what, got.hex(" ")))
    check("R5c  the two shifts differ ONLY in the count",
          C[0xFA7351 - PROM_C_BASE:][:2] == C[0xFA735F - PROM_C_BASE:][:2],
          "d9 ee 07 vs d9 ee 08 -- so a byte table read with a word load loses the high byte")
    src = open(image_path(ROOT, "prom_c/wsa1_prom_c.s")).read().split("\n")
    calls = [ln for ln in src if "calr" in ln and "0xFA72E9" in ln]
    check("R5d  sub_FA72E9 has exactly ONE call site in the whole tree", len(calls) == 1,
          "%s" % (calls[0].split(";")[-1].strip() if calls else "none"))


# --- R6 --------------------------------------------------------------------
def r6():
    print("\n=== R6.  \u2605 THE MORPHEME TEST -- what carries each new word? ===\n")
    B = {k: open(os.path.join(ROOT, "original_ROMs", f), "rb").read() for k, f in IMG.items()}

    def cnt(w):
        return {k: len(re.findall(w.encode(), v)) + len(re.findall(w.upper().encode(), v))
                for k, v in B.items()}

    # DOMAIN words -- these CLAIM something about the instrument, so they are gated.
    # "Home" is round 3's control: it occurs nowhere and five labels were built on it.
    for w in ("Octave", "Shift", "Program", "Bank", "Mixer", "Perc"):
        t = cnt(w)
        check("R6  domain morpheme %-9s occurs in the images" % ("'%s'" % w),
              sum(t.values()) > 0, "%d occurrences %s" % (sum(t.values()), t))
    t = cnt("Home")
    check("R6  'Home' still occurs ZERO times (round 3's control)", sum(t.values()) == 0, "%s" % t)
    # \u2605 and in the RIGHT SENSE: the single PROGRAM in the images is "PROGRAM CHANGE",
    # the MIDI program number 0..127 -- which is exactly the range the octave table's
    # second index is claimed to have.
    i = B["prom_b"].find(b"PROGRAM")
    check("R6y  \u2605 the one 'PROGRAM' is in the MIDI sense the name needs",
          b"CHANGE" in B["prom_b"][i:i + 24],
          "prom_b 0x%05X: %r -- a MIDI PROGRAM CHANGE caption; plus 3 x 'PROG'"
          % (i, B["prom_b"][i:i + 21]))
    # STRUCTURAL words -- analyst vocabulary, reported but NOT gated.  A name is not
    # required to quote the ROM for "Table"; it IS required not to invent a concept.
    for w in ("Default", "Table", "Tone"):
        t = cnt(w)
        print("  NOTE structural morpheme %-9s %d occurrences %s"
              % ("'%s'" % w, sum(t.values()), t))
    finding("R6x  'MixerDefault' has ZERO textual support and is an unaudited KN5000 "
            "transplant",
            "inherited from round 1-2, NOT this round's -- and the block banner says so "
            "outright: 'Readers: NONE FOUND ... NOTHING in the WSA1 firmware confirms it'. "
            "All 293 new labels hang off it.")
    src = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read()
    names = set(re.findall(r"_SameAs_([A-Za-z0-9]+?)(?:_WaveSel\d)?:", src))
    have = set(b[3] for b in BLOCKS) | set(t2[2] for t2 in TAILS)
    have |= set(stem(x) for x in have)
    check("R6z  \u2605 every name a label uses is the CamelCase of a real ASCII field",
          names <= have, "%d distinct names, %d not found in the image: %s"
          % (len(names), len(names - have), sorted(names - have)[:5]))


# --- R7 --------------------------------------------------------------------
def r7():
    print("\n=== R7.  THE CITATIONS ===\n")
    src = open(image_path(ROOT, "prom_c/wsa1_prom_c.s")).read().split("\n")
    addrs = set()
    for ln in src:
        m = re.search(r";\s*([0-9A-F]{6})\s\s", ln)
        if m:
            addrs.add(int(m.group(1), 16))
    cited = [0xFA72E9, 0xFA7301, 0xFA7332, 0xFA734A, 0xFA7351, 0xFA7356, 0xFA7358,
             0xFA735D, 0xFA735F, 0xFA7375, 0xFA737C, 0xFA7F7A, 0xFBC7D6]
    missing = [a for a in cited if a not in addrs]
    check("R7a  every cited prom_c address is an instruction START", not missing,
          "%d cited, %d not in the %d listed instruction addresses"
          % (len(cited), len(missing), len(addrs)))
    sig = [a for a in cited if C[a - PROM_C_BASE - 1] in (0x44, 0x45, 0x46)]
    check("R7b  none carries round 1's one-byte-off signature at cited-1", not sig,
          "0 of %d have 0x44/0x45/0x46 at cited-1" % len(cited))


# --- R8 --------------------------------------------------------------------
def r8():
    print("\n=== R8.  IS THE HEADER GAIN NEW PROSE? ===\n")
    import subprocess
    # ⚠ the image DIRECTORY: a diff of the master alone cannot see prom_d's body.
    d = subprocess.run(["git", "-C", ROOT, "diff", "--", "prom_d/"],
                       capture_output=True, text=True).stdout.split("\n")
    add = [l for l in d if l.startswith("+;")]
    rem = [l for l in d if l.startswith("-;")]
    blank_add = [l for l in add if re.fullmatch(r"\+; *", l)]
    blank_rem = [l for l in rem if re.fullmatch(r"-; *", l)]
    prose = [l for l in add if re.search(r"[A-Za-z]+ +[A-Za-z]+ +[A-Za-z]+", l)]
    check("R8  the gain is written prose, not round 3's removed blank lines",
          len(prose) > 1000 and len(blank_rem) < 20,
          "%d comment lines added (%d with 3+ words), %d removed; blank-ish +%d/-%d"
          % (len(add), len(prose), len(rem), len(blank_add), len(blank_rem)))


# --- R9: THE DEFECT --------------------------------------------------------
def r9():
    print("\n=== R9.  ★ THE DEFECT -- the catalogue sentence, in every reading ===\n")
    a8c = S(0x8C)
    ncat = (nb(a8c) - a8c) // 16
    cat = [camel(D[a8c + 16 * i: a8c + 16 * i + 13].decode("latin1")) for i in range(ncat)]
    check("R9a  the +0x8C catalogue is 208 rows of 16 -- no truncation in the compare",
          ncat == 208, "0x%05X..0x%05X = %d rows" % (a8c, nb(a8c), ncat))
    _a, n, rs = recs(0x20)
    lab = {}
    for i, r in enumerate(rs):
        ms = [t for t in TAILS if t[1] == r]
        if not ms:
            continue
        nm = sorted(set(t[2] for t in ms))
        if len(nm) == 1:
            lab[i] = nm[0]
        elif len(set(stem(x) for x in nm)) == 1:
            lab[i] = stem(nm[0])
    same = elsewhere = absent = 0
    absent_idx = []
    for k, v in lab.items():
        hits = [i for i, c in enumerate(cat) if c in (v, stem(v))]
        if k in hits:
            same += 1
        elif hits:
            elsewhere += 1
        else:
            absent += 1
            absent_idx.append((k, v))
    check("R9b  the shipped triple (141, 61, 62, 18) is arithmetically right",
          (len(lab), same, elsewhere, absent) == (141, 61, 62, 18),
          "%s" % ((len(lab), same, elsewhere, absent),))
    drum = set(t[2] for t in TAILS) | set(stem(t[2]) for t in TAILS)
    reading_a = sum(1 for c in cat if c not in drum and stem(c) not in drum)
    reading_b = sum(1 for k, _v in absent_idx if cat[k] not in drum and stem(cat[k]) not in drum)
    finding("R9c  the sentence 'names something no drum record has 18 times' is BACKWARDS",
            "measured = 18 LABEL NAMES ABSENT FROM THE CATALOGUE; "
            "catalogue-wide the sentence's own reading gives %d, and at those 18 "
            "indices it gives %d.  Neither is 18." % (reading_a, reading_b))
    src = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read()
    finding("R9d  and it ships %d times in prom_d/wsa1_prom_d.s"
            % src.count("names something no"),
            "1 block banner + %d per-record headers" % (src.count("names something no") - 1))


# --- R10: the typed numbers ------------------------------------------------
def r10():
    print("\n=== R10.  TYPED NUMBERS THAT CONTRADICT DERIVED ONES ===\n")
    s = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read()
    finding("R10a  '.s: The 84 marks ... 85 marks placed at random' -- one sentence, "
            "two counts",
            "84 is derived from the image (R4a); 85 is typed.  Also in "
            "gen_prom_d_asm.py, FINDINGS-prom-d-tone-database.md and round6.py."
            if "The 84 marks" in s and "85 marks placed at random" in s
            else "not present -- already fixed")
    md = open(os.path.join(ROOT, "notes", "FINDINGS-prom-d-tone-database.md")).read()
    finding("R10b  FINDINGS says the round-6 script runs '38 checks'; it prints 40",
            "%d occurrences of '38 checks' in the FINDINGS file" % md.count("38 checks"))


def main():
    print("REVIEW-WD3 round 6 -- are prom_d's new names carried by their evidence?")
    for f in (r1, r2, r3, r4, r5, r6, r7, r8, r9, r10):
        f()
    print("\n%d check(s) failed; %d finding(s) recorded." % (len(FAILED), len(FINDINGS)))
    for x in FAILED:
        print("   FAILED:", x)
    sys.exit(1 if FAILED else 0)


if __name__ == "__main__":
    main()
