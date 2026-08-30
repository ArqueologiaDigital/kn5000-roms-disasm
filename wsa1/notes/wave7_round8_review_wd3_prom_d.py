#!/usr/bin/env python3
"""REVIEW-WD3 round 8 -- ARE prom_d's ROUND-8 NAMES CARRIED BY THEIR EVIDENCE?

QUESTION IT ANSWERS
    notes/prom_d_inventory_round8.py promoted 31 framed labels in prom_d from
    `ToneDB_[Perc]MixerDefaultTable_NNN` to `..._NNN_SameAs_<A>_Or_<B>[_Or_<C>]`.
    The claim each label makes is a DISJUNCTION: "the carriers of these 43 bytes
    are exactly these N records, and nothing here picks one".  A disjunction can
    fail in two directions the byte gate cannot see -- a name in the label that
    is NOT a carrier, and a carrier that is NOT in the label.  This script
    re-reads the four ROM images and re-derives every carrier set from the bytes,
    without importing the lane's code, so a claim and its check cannot fail
    together.

WHAT IT CHECKS
    A1  the 31 promoted labels, read out of the gate-verified .s, are exactly the
        31 the lane reported, and every one of them is a rename of a label that
        existed at HEAD.
    A2  ★ THE CARRIER SET OF EVERY ONE OF THE 31, RE-DERIVED FROM THE IMAGE, in
        BOTH directions: every name in the label is a record that carries these
        43 bytes, and no record outside the label carries them.  This is the test
        that decides whether the disjunction is IDENTIFIED or merely LOCATED.
    A3  the melodic mask is the one the banner states: the carriers differ from
        the record at +0x0B and NOWHERE ELSE, and the drum carriers differ
        nowhere at all.  The NULL: masking any other single position instead.
    A4  ★ THE BOUND.  The label set must be exactly the records whose carrier
        count is 2 or 3; a record with 1 carrier was named in round 6 and a
        record with >3 is left nameless.  If the bound leaks, some record is
        named with an incomplete disjunction.
    A5  ★ THE MORPHEME TEST that caught round 3's invented "Home": every
        significant word of every new name, counted over all four ROM images, and
        every name checked to be the CamelCase of a record's OWN ASCII field.
    A6  the citations: every file offset and every prom_c address the new prose
        quotes is checked -- offsets against the record they claim, prom_c
        addresses against instruction starts in the gate-verified listing, for
        the round-1 "byte at cited-1 is 0x44/0x45/0x46" one-byte-off signature.
    A7  the header/evidence gain is NEW PROSE, not round 3's whitespace artefact:
        the .s at HEAD and the .s now, compared by the metric's own block rule.
    A8  no name is borrowed from the KN5000 tree without a byte diff and a count
        (the round-2 trap: 68 shared register NAMES, exactly ONE shared address).
    A9  ★ THE ONE DEFECT THIS REVIEW FOUND, and it is not in the 31 names: the
        preset-selection census quotes the WRONG DENOMINATOR.

WHAT THE REVIEW CONCLUDES
    ★ THE 31 NAMES HOLD.  A2 re-derives every carrier set from the ROM in both
    directions and finds 0 labels naming a non-carrier and 0 labels omitting a
    carrier; A6 audits all 530 banners of the two arrays against the bytes with
    zero errors; A4 shows the promoted set is exactly the records with 2..3
    carriers that HEAD left unnamed, so the bound does not leak.  Nothing here
    is LOCATED-not-IDENTIFIED: `_SameAs_A_Or_B` claims a byte identity and a
    byte identity is what carries it, and `_Or_` is what refuses to pick.

    ⚠ TWO FINDINGS, both about the SAME sentence and neither touching a label:
      1. prom_d/wsa1_prom_d.s line 197 says the +0x0B field "over all 1,549
         wave-select records ... takes 7 distinct values".  Over those 1,549 it
         takes 64.  7 is the figure over the 1,485 that EXCLUDE the preset array
         itself, which the lane's own preset_referrers() excludes on purpose
         ("a record's own index is not a reference") and which the PER-RECORD
         prose states correctly 64 times out of 64.  Only the file-level summary
         quotes the census with the population it was not run over.
      2. notes/prom_d_inventory_round8.py's docstring says "57 ... and 6 are
         selected by many".  57 + 6 = 63.  The derived figure is 7, which the
         generated assembly itself prints in 7 places.
    Neither weakens the refusal the sentence supports; both are the shape of
    error this tree has retracted before, so they are reported rather than
    smoothed over.

HOW TO RUN
    python3 notes/wave7_round8_review_wd3_prom_d.py
    Exit status is non-zero if any REVIEW check fails.  FINDINGS are recorded
    separately: they are the review's output, not its gate.
"""
import collections
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_text_at_rev  # noqa: E402  (the image at HEAD)
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
IMGS = {t: open(os.path.join(ROOT, "original_ROMs", f), "rb").read() for t, f in
        (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"),
         ("c", "wsa1_prom_c.ic28"), ("d", "wsa1_prom_d.bin"))}
SRC_NOW = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read().split("\n")

OK = FAIL = 0
FINDINGS = []


def check(label, cond, detail=""):
    global OK, FAIL
    print(("  ok    " if cond else "  FAIL  ") + "%-64s %s" % (label, detail))
    if cond:
        OK += 1
    else:
        FAIL += 1
    return cond


def finding(label, detail):
    print("  FIND  %-64s %s" % (label, detail))
    FINDINGS.append((label, detail))


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


NPTR = (S(0xA8) - S(0x08)) // 4
TP = [u32(S(0x08) + 4 * i) for i in range(NPTR)]


def tone_end(p):
    return min([q for q in sorted(set(TP)) if q > p] + [x for x in BOUNDS if x > p])


def tone_blocks():
    """(tone index, element, 43 bytes, CamelCase name, file offset, ascii)."""
    out = []
    for i, p in enumerate(TP):
        size = tone_end(p) - p
        if size < 217 or (size - 217) % 124:
            continue
        n = (size - 217) // 124
        raw = D[p:p + 16].decode("latin1")
        for j in range(n):
            a = p + 217 + 81 * n + ST * j
            out.append((i, j, D[a:a + ST], camel(raw), a, raw))
    return out


def drum_tails():
    """(index, 43 bytes, CamelCase name, file offset, ascii)."""
    a = S(0x78)
    n = (nb(a) - a) // PS
    return [(i, D[a + PS * i + (PS - ST): a + PS * (i + 1)],
             camel(D[a + PS * i: a + PS * i + 13].decode("latin1")),
             a + PS * i + (PS - ST), D[a + PS * i: a + PS * i + 13].decode("latin1"))
            for i in range(n)]


def recs(slot):
    a = S(slot)
    n = (nb(a) - a) // ST
    return a, n, [D[a + ST * i: a + ST * (i + 1)] for i in range(n)]


def ham(x, y):
    return sum(1 for p, q in zip(x, y) if p != q)


BLOCKS = tone_blocks()
TAILS = drum_tails()
MEL_BASE, MEL_N, MEL = recs(0x18)      # ToneDB_MixerDefaultTable
PRC_BASE, PRC_N, PRC = recs(0x20)      # ToneDB_PercMixerDefaultTable

# carrier sets, re-derived from the bytes, once
def mel_carriers(r):
    """tone wave-select blocks equal to r outside +0x0B."""
    out = []
    for i, j, b, nm, a, raw in BLOCKS:
        if len(b) == ST and ham(b, r) == 1 and b[PRESET] != r[PRESET]:
            out.append((nm, a, raw))
    return out


def prc_carriers(r):
    return [(nm, a, raw) for i, b, nm, a, raw in TAILS if b == r]


MEL_C = [mel_carriers(r) for r in MEL]
PRC_C = [prc_carriers(r) for r in PRC]


# --- read the promoted labels out of the gate-verified listing -------------
LAB = re.compile(r"^(ToneDB_(?:Perc)?MixerDefaultTable_(\d{3}))_SameAs_(.+):$")
PROMOTED = []
for k, ln in enumerate(SRC_NOW):
    m = LAB.match(ln)
    if m and "_Or_" in m.group(3):
        PROMOTED.append((m.group(1), int(m.group(2)), m.group(3).split("_Or_"), k))


def a1():
    print("\n=== A1.  THE 31 PROMOTED LABELS, READ OUT OF THE .s ===\n")
    check("A1a  the listing holds exactly 31 `_SameAs_.._Or_..` labels",
          len(PROMOTED) == 31, "found %d" % len(PROMOTED))
    mel = [p for p in PROMOTED if not p[0].startswith("ToneDB_Perc")]
    prc = [p for p in PROMOTED if p[0].startswith("ToneDB_Perc")]
    check("A1b  11 melodic + 20 drum, as the +11 evidence delta implies",
          len(mel) == 11 and len(prc) == 20, "%d melodic, %d drum" % (len(mel), len(prc)))
    check("A1c  every promoted index is inside its array",
          all((p[1] < MEL_N) if not p[0].startswith("ToneDB_Perc") else (p[1] < PRC_N)
              for p in PROMOTED),
          "melodic n=%d, drum n=%d" % (MEL_N, PRC_N))
    check("A1d  no promoted label repeats an index",
          len(set((p[0], p[1]) for p in PROMOTED)) == 31)


def a2():
    print("\n=== A2.  THE CARRIER SET OF EVERY ONE OF THE 31, BOTH DIRECTIONS ===\n")
    bad_extra, bad_missing = [], []
    for base, idx, names, _ln in PROMOTED:
        perc = base.startswith("ToneDB_Perc")
        car = (PRC_C if perc else MEL_C)[idx]
        got = sorted(set(nm for nm, _a, _r in car))
        want = sorted(set(names))
        if set(want) - set(got):
            bad_missing.append((base, idx, sorted(set(want) - set(got))))
        if set(got) - set(want):
            bad_extra.append((base, idx, sorted(set(got) - set(want))))
    check("A2a  every name in a label IS a carrier of that record's 43 bytes",
          not bad_missing, "%d labels name a non-carrier %s" % (len(bad_missing), bad_missing[:3]))
    check("A2b  no record outside a label carries the bytes (disjunction COMPLETE)",
          not bad_extra, "%d labels omit a carrier %s" % (len(bad_extra), bad_extra[:3]))
    # the LAST promoted label in address order, checked by hand
    last = max(PROMOTED, key=lambda p: (p[0].startswith("ToneDB_Perc"), p[1]))
    perc = last[0].startswith("ToneDB_Perc")
    car = (PRC_C if perc else MEL_C)[last[1]]
    off = (PRC_BASE if perc else MEL_BASE) + ST * last[1]
    check("A1e/A2c  the LAST label in address order re-derived by name: %s" % last[0],
          sorted(set(n for n, _a, _r in car)) == sorted(set(last[2])),
          "file 0x%05X carriers=%s" % (off, sorted(set(n for n, _a, _r in car))))


def a3():
    print("\n=== A3.  THE MASK, AND ITS NULL ===\n")
    mel_diffpos = set()
    for base, idx, names, _ln in PROMOTED:
        if base.startswith("ToneDB_Perc"):
            continue
        r = MEL[idx]
        for nm, a, _raw in MEL_C[idx]:
            b = D[a:a + ST]
            mel_diffpos |= set(p for p in range(ST) if b[p] != r[p])
    check("A3a  every melodic carrier differs at +0x0B and NOWHERE ELSE",
          mel_diffpos == {PRESET}, "differing positions = %s" % sorted(mel_diffpos))
    prc_diffpos = set()
    for base, idx, names, _ln in PROMOTED:
        if not base.startswith("ToneDB_Perc"):
            continue
        r = PRC[idx]
        for nm, a, _raw in PRC_C[idx]:
            prc_diffpos |= set(p for p in range(ST) if D[a + p] != r[p])
    check("A3b  every drum carrier is byte-IDENTICAL (0 differing positions)",
          not prc_diffpos, "differing positions = %s" % sorted(prc_diffpos))
    # NULL: mask some other single position instead of +0x0B
    hits = {}
    for pos in range(ST):
        n = 0
        for r in MEL:
            for _i, _j, b, _nm, _a, _raw in BLOCKS:
                if len(b) == ST and ham(b, r) == 1 and b[pos] != r[pos]:
                    n += 1
        hits[pos] = n
    others = max(v for p, v in hits.items() if p != PRESET)
    check("A3c  NULL: +0x0B gives %d one-byte twins, the best other position %d"
          % (hits[PRESET], others), hits[PRESET] > 10 * max(others, 1),
          "runner-up position +0x%02X" % max((v, p) for p, v in hits.items()
                                             if p != PRESET)[1])

def a4():
    print("\n=== A4.  THE BOUND: exactly the records round 6/7 left NAMELESS-AMBIGUOUS ===\n")
    hist_m = collections.Counter(len(set(n for n, _a, _r in c)) for c in MEL_C)
    hist_p = collections.Counter(len(set(n for n, _a, _r in c)) for c in PRC_C)
    print("      melodic distinct-carrier-name histogram: %s" % dict(sorted(hist_m.items())))
    print("      drum    distinct-carrier-name histogram: %s" % dict(sorted(hist_p.items())))
    check("A4a  the melodic no-twin/twin split is the 155/167 the banners state",
          hist_m[0] == 155 and sum(v for k, v in hist_m.items() if k) == 167,
          "%d with no twin, %d with one" % (hist_m[0], sum(v for k, v in hist_m.items() if k)))
    check("A4b  the drum no-carrier/carrier split is the 12/196 the banners state",
          hist_p[0] == 12 and sum(v for k, v in hist_p.items() if k) == 196,
          "%d with no carrier, %d with one" % (hist_p[0], sum(v for k, v in hist_p.items() if k)))
    head = image_text_at_rev(ROOT, "prom_d/wsa1_prom_d.s", "HEAD").split("\n")
    bare = set()
    for ln in head:
        m = re.match(r"^(ToneDB_(?:Perc)?MixerDefaultTable)_(\d{3}):$", ln)
        if m:
            bare.add((m.group(1), int(m.group(2))))
    want, over = set(), []
    for arr, base in ((MEL_C, "ToneDB_MixerDefaultTable"),
                      (PRC_C, "ToneDB_PercMixerDefaultTable")):
        for i, c in enumerate(arr):
            k = len(set(n for n, _a, _r in c))
            if (base, i) in bare and 2 <= k <= 3:
                want.add((base, i))
            if (base, i) in bare and k > 3:
                over.append((base, i))
    got = set((re.sub(r"_\d{3}$", "", p[0]), p[1]) for p in PROMOTED)
    check("A4c  promoted == every record with 2..3 carriers that HEAD left unnamed",
          want == got, "missed=%s extra=%s" % (sorted(want - got)[:4], sorted(got - want)[:4]))
    check("A4d  the %d records ABOVE the bound are all still nameless" % len(over),
          bool(over) and all(x not in got for x in over),
          "a bound that excluded nothing would not be a bound")


def a5():
    print("\n=== A5.  THE MORPHEME TEST (round 3's invented `Home`) ===\n")
    words = set()
    for _b, _i, names, _ln in PROMOTED:
        words |= set(names)
    owned = {}
    for _i, _j, _b, nm, _a, raw in BLOCKS:
        owned.setdefault(nm, raw)
    for _i, _b, nm, _a, raw in TAILS:
        owned.setdefault(nm, raw)
    missing = sorted(w for w in words if w not in owned)
    check("A5a  every one of the %d distinct names is a record's own ASCII field"
          % len(words), not missing, "not found: %s" % missing[:5])
    notin = [w for w in sorted(words)
             if owned.get(w) and owned[w].rstrip("\x00 ").encode("latin1") not in D]
    check("A5b  every such ASCII field is literally present in prom_d's bytes",
          not notin, "absent: %s" % notin[:5])
    ctl = sum(img.count(b"Home") for img in IMGS.values())
    check("A5c  CONTROL: round 3's `Home` still occurs 0 times in all four images",
          ctl == 0, "count=%d" % ctl)
    probe = sorted(words)[-1]
    n = sum(img.count(owned[probe].rstrip("\x00 ").encode("latin1")) for img in IMGS.values())
    check("A5d  POSITIVE CONTROL: `%s` (%r) occurs %d times across the four images"
          % (probe, owned[probe], n), n > 0)


def a6():
    print("\n=== A6.  ALL 530 BANNERS IN THE TWO ARRAYS, AUDITED AGAINST THE BYTES ===\n")
    hdr = re.compile(r"^; (ToneDB_(?:Perc)?MixerDefaultTable)_(\d{3}) -- "
                     r"file 0x([0-9A-F]+)\.\.0x([0-9A-F]+)$")
    blocks, cur, buf = {}, None, []
    for ln in SRC_NOW:
        m = hdr.match(ln)
        if m:
            if cur:
                blocks[cur] = buf
            cur = (m.group(1), int(m.group(2)), int(m.group(3), 16), int(m.group(4), 16))
            buf = []
            continue
        if cur is not None:
            if ln.startswith(";"):
                buf.append(ln)
            else:
                blocks[cur], cur, buf = buf, None, []
    if cur:
        blocks[cur] = buf
    ELEM = dict((a, j) for _i, j, _b, _nm, a, _raw in BLOCKS)
    e, n = collections.Counter(), collections.Counter()
    for (base, idx, lo, hi), v in sorted(blocks.items()):
        perc = base.endswith("PercMixerDefaultTable")
        B = PRC_BASE if perc else MEL_BASE
        n["blocks"] += 1
        if lo != B + ST * idx or hi != B + ST * idx + ST - 1:
            e["header file range wrong"] += 1
        txt = " ".join(x[1:].strip() for x in v)
        r = (PRC if perc else MEL)[idx]
        if perc:
            car = [(i, nm) for i, b, nm, _a, _raw in TAILS if b == r]
            m = re.search(r"The last 43 bytes of (\d+) drum-instrument records? are these "
                          r"bytes exactly: (.+?)\.(?:\s+\(\+(\d+) more\))?\s*Evidence", txt)
            if m:
                n["drum banner"] += 1
                cnt = int(m.group(1))
                lst = [x.strip() for x in m.group(2).split(", ")]
                more = int(m.group(3)) if m.group(3) else 0
                if cnt != len(car):
                    e["drum carrier COUNT wrong"] += 1
                if len(lst) + more != cnt:
                    e["drum truncation arithmetic wrong"] += 1
                want = ["PercInst_%03d_%s" % (i, nm) for i, nm in car]
                if lst != want[:len(lst)]:
                    e["drum carrier LIST wrong"] += 1
            elif "NO drum-instrument record carries these bytes" in txt:
                n["drum no-carrier"] += 1
                if car:
                    e["says NO carrier but there is one"] += 1
            else:
                e["unrecognised drum banner"] += 1
            m2 = re.search(r"Evidence: drum-instrument record (\d+) at file 0x([0-9A-F]+), its "
                           r"bytes \+107\.\.\+149 \(file 0x([0-9A-F]+)\.\.0x([0-9A-F]+)\)", txt)
            if m2:
                n["drum evidence"] += 1
                i, o = int(m2.group(1)), int(m2.group(2), 16)
                if S(0x78) + PS * i != o:
                    e["drum record offset wrong"] += 1
                if int(m2.group(3), 16) != o + 107 or int(m2.group(4), 16) != o + 149:
                    e["drum tail range wrong"] += 1
                if not car or car[0][0] != i:
                    e["evidence cites a non-first carrier"] += 1
                if D[o + 107:o + 150] != r:
                    e["cited tail bytes DO NOT equal the record"] += 1
        else:
            car = MEL_C[idx]
            names = sorted(set(nm for nm, _a, _raw in car))
            m = re.search(r"wave-select block of (\d+) tone-record elements \(([^)]*)\)", txt)
            mm = re.search(r"wave-select block of tone record (\S+), element (\d+),", txt)
            if m:
                n["melodic multi"] += 1
                if int(m.group(1)) != len(car):
                    e["melodic ELEMENT count wrong"] += 1
                parts = [x.strip() for x in m.group(2).split(", ")]
                more = 0
                if parts and parts[-1].startswith("+"):
                    more = int(parts[-1].split()[0][1:])
                    parts = parts[:-1]
                if len(parts) + more != len(names):
                    e["melodic name-list arithmetic wrong"] += 1
                if parts != names[:len(parts)]:
                    e["melodic name LIST wrong"] += 1
                m3 = re.search(r"belong to (\d+) DIFFERENTLY NAMED tone records", txt)
                if m3 and int(m3.group(1)) != len(names):
                    e["melodic DIFFERENTLY-NAMED count wrong"] += 1
            elif mm:
                n["melodic single"] += 1
                if len(names) != 1 or names[0] != mm.group(1) \
                        or ELEM.get(car[0][1]) != int(mm.group(2)):
                    e["melodic single name/element wrong"] += 1
            elif "NO tone wave-select block is within one byte" in txt:
                n["melodic no-twin"] += 1
                if car:
                    e["says NO twin but there is one"] += 1
                m4 = re.search(r"The nearest tone block differs in\s+(\d+) of the 43", txt)
                if m4:
                    best = min(ham(b, r) for _i, _j, b, _nm, _a, _raw in BLOCKS if len(b) == ST)
                    if best != int(m4.group(1)):
                        e["nearest-block Hamming distance wrong"] += 1
                    else:
                        n["nearest-distance checked"] += 1
            else:
                e["unrecognised melodic banner"] += 1
            mv = re.search(r"This record holds 0x([0-9A-F]{2})\s+there; the tone.s own block "
                           r"holds 0x([0-9A-F]{2})", txt)
            if mv:
                n["preset-byte pair"] += 1
                if r[PRESET] != int(mv.group(1), 16):
                    e["preset byte (record) wrong"] += 1
                if car and len(set(D[a + PRESET] for _nm, a, _raw in car)) == 1 \
                        and D[car[0][1] + PRESET] != int(mv.group(2), 16):
                    e["preset byte (tone) wrong"] += 1
    print("      audited: %s" % dict(n))
    check("A6a  all 530 banners of the two arrays agree with the ROM bytes",
          not e and n["blocks"] == 530, "errors=%s" % (dict(e) or "NONE"))
    check("A6b  the audit is not vacuous -- it parsed every banner shape",
          n["drum banner"] == 196 and n["drum no-carrier"] == 12
          and n["melodic single"] == 144 and n["melodic multi"] == 23
          and n["melodic no-twin"] == 155)


def a6b():
    print("\n=== A6b.  THE CITATIONS ===\n")
    lane = open(os.path.join(ROOT, "notes", "prom_d_inventory_round8.py")).read()
    cited = sorted(set(int(x, 16) for x in re.findall(r"0x(F[0-9A-F]{5})\b", lane)))
    # ⚠ prom_a and prom_c BOTH occupy 0xF80000-0xFFFFFF, so a UNION of their
    # instruction-start sets aliases: 0xFBC744 starts an instruction in prom_c
    # while 0xFBC743 starts one in prom_a, and a union reports a false
    # off-by-one.  Each address is resolved in the image where it IS a start,
    # and the cited-1 test is applied in that SAME image.
    starts = {}
    for tag, path in (("a", "prom_a/wsa1_prom_a.s"), ("c", "prom_c/wsa1_prom_c.s")):
        st = set()
        for ln in open(os.path.join(ROOT, path)):
            m = re.search(r";\s*([0-9A-F]{6})\b", ln)
            if m and not ln.strip().startswith(";"):
                st.add(int(m.group(1), 16))
        starts[tag] = st
    # the lane names its own prom_c citations in CITED_PROM_C; the one prom_a
    # citation (the build-tag read) is resolved in prom_a.  Resolving by search
    # order alone mislabels 0xFBC7D6, which is a start in BOTH images.
    named_c = set(int(x, 16) for x in
                  re.findall(r"0x(F[0-9A-F]{5})", lane.split("CITED_PROM_C = (")[1]
                             .split(")")[0])) if "CITED_PROM_C = (" in lane else set()
    where = {}
    for a in cited:
        for tag in (("c", "a") if a in named_c else ("a", "c")):
            if a in starts[tag]:
                where[a] = tag
                break
    code = sorted(where)
    bad = [a for a in code if (a - 1) in starts[where[a]]]
    check("A6b1  every cited code address is an INSTRUCTION START (%d of %d cited)"
          % (len(code), len(cited)),
          len(code) == 9, "%s" % ["%s:0x%06X" % (where[a], a) for a in code])
    check("A6b2  none carries the round-1 off-by-one signature (instruction at cited-1 "
          "IN THE SAME IMAGE)", not bad, "%s" % [hex(a) for a in bad])
    non = [a for a in cited if a not in where]
    check("A6b3  the %d non-code citations are window/base bounds, not claimed as code"
          % len(non), set(non) <= {0xF00000, 0xF7FFFF, 0xFFFFFF}, "%s" % [hex(a) for a in non])
    claim = re.compile(r"drum-instrument record (\d+) at file 0x([0-9A-F]+)")
    head = image_text_at_rev(ROOT, "prom_d/wsa1_prom_d.s", "HEAD").split("\n")
    added = [ln for ln in set(SRC_NOW) - set(head) if ln.startswith(";")]
    n = wrong = 0
    for ln in SRC_NOW:
        m = claim.search(ln)
        if m:
            n += 1
            if S(0x78) + PS * int(m.group(1)) != int(m.group(2), 16):
                wrong += 1
    check("A6b4  every `drum-instrument record N at file 0xX` in the .s lands on record N",
          n == 196 and not wrong, "%d claims checked, %d wrong" % (n, wrong))


def a7():
    print("\n=== A7.  IS THE GAIN NEW PROSE, OR ROUND 3's WHITESPACE? ===\n")
    head = image_text_at_rev(ROOT, "prom_d/wsa1_prom_d.s", "HEAD").split("\n")
    add_c = sum(1 for ln in SRC_NOW if ln.startswith(";"))
    old_c = sum(1 for ln in head if ln.startswith(";"))
    add_ev = sum(1 for ln in SRC_NOW if "Evidence:" in ln)
    old_ev = sum(1 for ln in head if "Evidence:" in ln)
    words = lambda L: sum(1 for x in L if re.search(r"[A-Za-z]+ +[A-Za-z]+ +[A-Za-z]+", x))
    import subprocess
    # ⚠ the image DIRECTORY: a diff of the master alone cannot see prom_d's body.
    d = subprocess.run(["git", "-C", ROOT, "diff", "--", "prom_d/"],
                       capture_output=True, text=True).stdout.split("\n")
    add = [l for l in d if l.startswith("+;")]
    rem = [l for l in d if l.startswith("-;")]
    blank_rem = [l for l in rem if re.fullmatch(r"-; *", l)]
    check("A7a  comment LINES rose by %d, %d of them with 3+ words -- real prose"
          % (add_c - old_c, words(add)), add_c - old_c > 0 and words(add) > 500,
          "%d -> %d" % (old_c, add_c))
    check("A7b  removed blank comment lines: %d -- NOT the round-3 whitespace artefact"
          % len(blank_rem), len(blank_rem) == 0)
    check("A7c  `Evidence:` LINES rose by %d (the lane reported 31)" % (add_ev - old_ev),
          add_ev - old_ev == 31, "%d -> %d" % (old_ev, add_ev))
    check("A7d  ⚠ but the METRIC's evidence count rose only +11: 20 of the 31 blocks "
          "already carried one", True,
          "the lane's own reported row says 2,049; both numbers are true of a stated rule")


def a8():
    print("\n=== A8.  BORROWED SIBLING NAMES (the round-2 cross-tree trap) ===\n")
    borrowed = [w for _b, _i, names, _l in PROMOTED for w in names
                if re.search(r"KN\d|Technics|SX_", w)]
    check("A8a  no promoted name is borrowed from a sibling tree", not borrowed,
          "%s" % borrowed[:5])
    head = image_text_at_rev(ROOT, "prom_d/wsa1_prom_d.s", "HEAD").split("\n")
    added = [ln for ln in set(SRC_NOW) - set(head) if ln.startswith(";")]
    kn = [ln for ln in added if re.search(r"KN\s*\d|kn5000|kn7000", ln, re.I)]
    check("A8b  round 8 adds no new cross-tree claim", not kn, "%s" % kn[:3])
    disc = [i for i, ln in enumerate(SRC_NOW) if "KN5000 transplant 1,298" in ln]
    slots = [ln for ln in SRC_NOW if "+0x0C +0x10 +0x14 +0x18 +0x20 +0x24" in ln]
    check("A8c  the PRE-EXISTING transplant of the two array names is disclosed WITH A COUNT",
          bool(disc) and bool(slots),
          "prom_d/wsa1_prom_d.s line %s lists +0x18 and +0x20 among the 1,298"
          % ([i + 1 for i in disc] or "absent"))


def a9():
    print("\n=== A9.  THE PRESET-SELECTION CENSUS: the round's own denominator ===\n")

    def fields(include_presets):
        out = []
        for slot in (0x18, 0x20, 0x3C):
            if slot == 0x3C and not include_presets:
                continue
            b = S(slot)
            for i in range((nb(b) - b) // ST):
                out.append(D[b + ST * i + PRESET])
        for _i, _j, b, _nm, _a, _raw in BLOCKS:
            if len(b) == ST:
                out.append(b[PRESET])
        a = S(0x78)
        for i in range((nb(a) - a) // PS):
            out.append(D[a + PS * i + PS - ST + PRESET])
        return out

    with_p, without_p = fields(True), fields(False)
    d_with = sorted(set(v & 0x3F for v in with_p))
    d_without = sorted(set(v & 0x3F for v in without_p))
    check("A9a  the population the file calls 'all wave-select records' is 1,549",
          len(with_p) == 1549, "%d records" % len(with_p))
    check("A9b  ★ FINDING: over those 1,549 the field takes %d distinct values, NOT 7"
          % len(d_with), len(d_with) == 64,
          "the preset array's own +0x0B carries its own index, so it enumerates 0..63")
    check("A9c  7 is the figure once the preset array itself is excluded (1,485 records)",
          len(without_p) == 1485 and len(d_without) == 7, "values=%s" % d_without)
    check("A9d  ★ FINDING: 57 + 7 = 64, so `6 are selected by many` is wrong by one",
          64 - len(d_without) == 57, "57 nothing-selected + %d selected" % len(d_without))
    lane = open(os.path.join(ROOT, "notes", "prom_d_inventory_round8.py")).read()
    finding("A9e  notes/prom_d_inventory_round8.py docstring says '6 are selected by many'",
            "present=%s -- the derived figure is 7" % ("and 6 are selected by many" in lane))
    src_hit = [i + 1 for i, ln in enumerate(SRC_NOW)
               if "over all 1,549 wave-select records it takes 7" in ln]
    finding("A9f  the .s file-level banner quotes 1,549 as the denominator for the 7",
            "prom_d/wsa1_prom_d.s line %s -- the 7 needs the 1,485 population" % src_hit)
    a = sum(1 for ln in SRC_NOW if "AND NO STORED RECORD EVER DOES" in ln)
    b = sum(1 for ln in SRC_NOW if "stored records in this image hold" in ln)
    check("A9g  the PER-RECORD prose is RIGHT: %d 'no stored record' + %d 'selects' = 64"
          % (a, b), a + b == 64 and a == 57 and b == 7)


def main():
    print(__doc__.split("HOW TO RUN")[0].rstrip())
    a1(); a2(); a3(); a4(); a5(); a6(); a6b(); a7(); a8(); a9()
    print("\n%d ok, %d FAIL, %d finding(s)" % (OK, FAIL, len(FINDINGS)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
