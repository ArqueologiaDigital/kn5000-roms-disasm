#!/usr/bin/env python3
"""REVIEW-WD3 round 4 -- are prom_d's NEW names carried by their evidence?

QUESTION IT ANSWERS
    Wave 7 round 4 renamed 2,503 labels in prom_d/wsa1_prom_d.s and added 1,572
    header/Evidence blocks.  The byte gate is blind to every one of them.  This
    script attacks them from OUTSIDE the lane's code -- it never imports
    notes/prom_d_understanding_round4.py -- by re-reading the ROM images and the
    .s text and asking whether each claim is true.

⚠ SCOPE, AND TWO CHECKS THAT ARE ROUND-4-SPECIFIC -- read this before reporting
   a failure.  W1-W5, W7 and W9 re-read the ROM and the .s and are true or false
   whatever else changes.  W6b and W8a are NOT: they measure ROUND 4's WORKING
   DIFF against the commit that was HEAD when this script was written, and they
   have both been red since long before anything after round 4 touched the tree.
     * W6b asserts a literal sentence is present in `git show HEAD:...`.  That
       sentence was DERIVED into the generator instead (which is the correct fix,
       and is what W6c/W6d/W6e verify), so it is legitimately absent from HEAD.
       Verified red at commit 66cc1d0, before round 5 began.
     * W8a wants added comment lines to exceed deleted ones twentyfold, which was
       true of round 4 because round 4 renamed LABELS.  Round 5 renamed six
       DescCurve labels, and each rename rewrites the comment lines that mention
       them: 479 `Reached as ToneDB_DescCurve_N[i]` plus 318 `descriptor N stage
       2:` lines are one deletion and one addition each.  That is a rename showing
       up as churn, not prose being lost.
   Neither threshold has been weakened to make it pass.  A future round that wants
   a diff-shape check should write its own against its own baseline.

WHAT IT CHECKS (run it; do not quote this list)
    W1  THE RECORD NAMES ARE THE RECORDS' OWN BYTES.  All 274 tone-record and
        504 drum-instrument labels, camel-cased by an independently written
        camelizer, must equal the label suffix in the .s -- checked on the LAST
        of each (tone index 273 'GM Orchestra Kit', drum 503 'Slap Shot').
    W2  THE PER-RECORD REACHABILITY NUMBERS.  Every one of the 274 "Selected by
        N of the 1280 entries" lines and every one of the 504 "Named by N ... and
        M ..." lines is recomputed from the program map (slot +0x04) and the two
        drum note maps (slots +0x74 / +0x7C).
    W3  THE INDEX CHAIN AT SLOT +0x30 IS REAL, AND IT IS NOT ARITHMETIC LUCK.
        JOIN 1 and JOIN 2 are recomputed (318/318 each) and each is given a
        PERMUTATION NULL -- pair each part A with a random other descriptor's
        part B / curve.  A join whose null also scores 318 would prove nothing.
    W4  ★ THE SAME CHAIN AT SLOT +0x38 IS DEGENERATE, AND THE BANNER DOES NOT
        SAY SO.  All 161 descriptors share ONE part-A object whose 128 bytes are
        ALL ZERO, so max(part A) = 0 and every part B is one 6-byte element.
        "JOIN 2  elements == max(part A) + 1   161 of 161" is therefore a
        criterion that CANNOT FAIL: its permutation null also scores 161/161.
        This is the round-1 "25 blocks of 32 that is one block 25 times" shape.
    W5  ★ 160 DANGLING LABEL REFERENCES.  160 of the 161 Perc ElemArray headers
        route through `ToneDB_EnvDescTable_Perc_NNN_CurveStepToElem`, a label
        that is never defined -- only Perc_000_CurveStepToElem exists, because
        there is only one part-A object.
    W6  ★ A ROUND-3 CORRECTION WAS REVERTED.  Commit 1706229 replaced the
        slot +0x28 Evidence line "ends at 0x22A3B, which is the next value in
        the same directory" with a 13-line retraction, because 0x22A3B is NOT a
        directory value.  Round 4 regenerated the file and the FALSE wording is
        back verbatim.  Neither HEAD's nor the current gen_prom_d_asm.py carries
        the correction, so it was hand-applied to generated output.
    W7  EVERY POOL-OBJECT HEADER'S ARITHMETIC (798 of them) and every ElemArray's
        named curve (479) recomputed from the image.
    W8  THE HEADERS ARE NEW PROSE, NOT REMOVED WHITESPACE -- the round-3 failure.
        Counts added vs deleted comment lines and blank lines in the diff.
    W9  THE KN7000 CROSS-ARCHITECTURE NAME MATCH (202/274 tone, 101/504 drum)
        with a byte-shuffle null, so the match is shown to be able to fail.

HOW TO RUN
    python3 notes/wave7_round4_review_wd3_prom_d.py
    Exit status is non-zero if any check fails.  W4, W5 and W6 are EXPECTED TO
    FAIL: they are the findings, not regressions in this script.
"""
import collections
import os
import random
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
SRC = open(image_path(ROOT, "prom_d/wsa1_prom_d.s")).read().split("\n")
KN7000 = ("/home/fsanches/compartilhado/technics_roms/roms/kn7000/kn7000_table.rom")

NFAIL = [0]


def check(msg, ok, detail=""):
    NFAIL[0] += not ok
    print("  %-4s %-72s %s" % ("PASS" if ok else "FAIL", msg, detail))


def say(s):
    print(s)


def U32(a):
    return struct.unpack_from("<I", D, a)[0]


def U16(a):
    return struct.unpack_from("<H", D, a)[0]


def camel(raw):
    """Independently written: words of [A-Za-z0-9], each capitalised, joined."""
    return "".join(w[:1].upper() + w[1:]
                   for w in re.split(r"[^A-Za-z0-9]+", raw) if w)


# The region boundaries the emitter uses are NOT all directory values (that is
# W6's subject), so read them back out of the banners the .s prints for itself.
BANNER = re.compile(r"^; file 0x([0-9A-F]{5}) \.\. 0x([0-9A-F]{5})\s+\((\d+) bytes\)$")
REGION = [(int(m.group(1), 16), int(m.group(2), 16) + 1)
          for m in (BANNER.match(l) for l in SRC) if m]


def region_of(addr):
    for lo, hi in REGION:
        if lo <= addr < hi:
            return lo, hi
    raise KeyError(addr)


def descriptors(slot):
    """The 14-byte descriptor array at a directory slot, plus its pool extents."""
    a = U32(slot)
    _lo, b = region_of(a)
    recs, p = [], a
    while True:
        recs.append((p, D[p], U32(p + 1), U32(p + 5)))
        p += 14
        nz = [o for _q, _t, x, y in recs for o in (x, y) if o]
        if nz and p >= min(nz):
            break
    nz = sorted({o for _q, _t, x, y in recs for o in (x, y) if o})
    ext = {o: (nz[j + 1] if j + 1 < len(nz) else b) - o for j, o in enumerate(nz)}
    return recs, ext, a, b


# ---------------------------------------------------------------------------
def w1_names():
    say("\n=== W1.  the record names are the RECORDS' OWN BYTES ===\n")
    offs = [U32(0xB80 + 4 * i) for i in range(274)]
    labs = {}
    for ln in SRC:
        m = re.match(r"^(?:ToneRec|DrumKit)_([0-9A-F]{3})_([A-Za-z0-9]+):$", ln)
        if m:
            labs[int(m.group(1), 16)] = m.group(2)
    bad = [i for i, nm in labs.items() if camel(D[offs[i]:offs[i] + 16].decode("latin1")) != nm]
    check("W1a  274 tone labels equal camel(record's own 16 bytes)",
          len(labs) == 274 and not bad, "%d labels, %d wrong" % (len(labs), len(bad)))
    check("W1a' checked on the LAST tone record, index 273",
          273 in labs and camel(D[offs[273]:offs[273] + 16].decode("latin1")) == labs.get(273),
          "0x%05X %r -> %s" % (offs[273], D[offs[273]:offs[273] + 16].decode("latin1"),
                               labs.get(273)))
    a = U32(0x78)
    stride = U16(0xEE)
    plabs = {}
    for ln in SRC:
        m = re.match(r"^PercInst_(\d{3})_([A-Za-z0-9]+):$", ln)
        if m:
            plabs[int(m.group(1))] = m.group(2)
    pbad = [i for i, nm in plabs.items()
            if camel(D[a + stride * i:a + stride * i + 13].decode("latin1")) != nm]
    check("W1b  504 drum labels equal camel(record's own 13 bytes)",
          len(plabs) == 504 and not pbad, "%d labels, %d wrong" % (len(plabs), len(pbad)))
    p = a + stride * 503
    check("W1b' checked on the LAST drum record, 503",
          camel(D[p:p + 13].decode("latin1")) == plabs.get(503),
          "0x%05X %r -> %s" % (p, D[p:p + 13].decode("latin1"), plabs.get(503)))
    check("W1c  every one of the 778 name fields is printable ASCII",
          all(all(32 <= c < 127 for c in D[o:o + 16]) for o in offs)
          and all(all(32 <= c < 127 for c in D[a + stride * i:a + stride * i + 13])
                  for i in range(504)))


def w2_reachability():
    say("\n=== W2.  the per-record reachability numbers, all 778 ===\n")
    prog = [U16(0x180 + 2 * i) for i in range(1280)]
    cnt = collections.Counter(prog)
    check("W2a  program map: 1280 entries, no 0xFFFF, values 0..273, ONTO",
          len(prog) == 1280 and 0xFFFF not in prog and max(prog) == 273
          and set(prog) == set(range(274)),
          "%d distinct, counts %d..%d" % (len(set(prog)), min(cnt.values()), max(cnt.values())))
    bad, n = [], 0
    for i, ln in enumerate(SRC):
        m = re.match(r"^; ---- tone 0x([0-9A-F]{3}) ", ln)
        if not m:
            continue
        idx = int(m.group(1), 16)
        mm = re.search(r"Selected by (\d+) of the (\d+) entries", "\n".join(SRC[i:i + 6]))
        n += 1
        if not mm or (int(mm.group(1)), int(mm.group(2))) != (cnt[idx], 1280):
            bad.append(idx)
    check("W2b  all 274 'Selected by N of the 1280' lines recomputed",
          n == 274 and not bad, "%d headers, %d wrong" % (n, len(bad)))
    mA = [U16(U32(0x74) + 2 * i) for i in range(2048)]
    mB = [U16(U32(0x7C) + 2 * i) for i in range(2048)]
    cA, cB = collections.Counter(mA), collections.Counter(mB)
    check("W2c  note map A names all 504 drum records; map B names 503",
          set(mA) == set(range(504)) and set(range(504)) - set(mB) == {503},
          "map B misses record 503 %r and holds 0xFFFF"
          % D[U32(0x78) + U16(0xEE) * 503:U32(0x78) + U16(0xEE) * 503 + 13].decode("latin1"))
    bad, n = [], 0
    for i, ln in enumerate(SRC):
        m = re.match(r"^; ---- drum instrument\s+(\d+) ", ln)
        if not m:
            continue
        idx = int(m.group(1))
        mm = re.search(r"Named by (\d+) of the 2,048 DrumKit_NoteMapA entries "
                       r"\(slot \+0x74\) and (\d+)", "\n".join(SRC[i:i + 5]))
        n += 1
        if not mm or (int(mm.group(1)), int(mm.group(2))) != (cA[idx], cB[idx]):
            bad.append(idx)
    check("W2d  all 504 'Named by N ... and M ...' lines recomputed",
          n == 504 and not bad, "%d headers, %d wrong" % (n, len(bad)))


def joins(slot):
    recs, ext, _a, _b = descriptors(slot)
    mA = [max(D[o1 + 4:o1 + ext[o1]]) for _q, _t, o1, _o2 in recs]
    nE = [ext[o2] // (8 if t & 0x80 else 6) for _q, t, _o1, o2 in recs]
    lenA = [ext[o1] - 4 for _q, _t, o1, _o2 in recs]
    cur = [U32(o1) for _q, _t, o1, _o2 in recs]
    return recs, ext, mA, nE, lenA, cur


def w3_chain_30():
    say("\n=== W3.  the index chain at slot +0x30, WITH PERMUTATION NULLS ===\n")
    recs, ext, mA, nE, lenA, cur = joins(0x30)
    j1 = sum(1 for c, l in zip(cur, lenA) if max(D[c:c + 128]) + 1 == l)
    j2 = sum(1 for x, y in zip(mA, nE) if x + 1 == y)
    check("W3a  JOIN 1  len(part A) - 4 == max(curve) + 1", j1 == 318 == len(recs),
          "%d/%d" % (j1, len(recs)))
    check("W3b  JOIN 2  elements == max(part A) + 1", j2 == 318 == len(recs),
          "%d/%d" % (j2, len(recs)))
    random.seed(0)
    runs, t1, t2 = 200, 0, 0
    for _ in range(runs):
        q = cur[:]
        random.shuffle(q)
        t1 += sum(1 for c, l in zip(q, lenA) if max(D[c:c + 128]) + 1 == l)
        q = nE[:]
        random.shuffle(q)
        t2 += sum(1 for x, y in zip(mA, q) if x + 1 == y)
    check("W3c  NULL: JOIN 1 against a RANDOM other descriptor's curve",
          t1 / runs < 0.5 * len(recs), "mean %.1f/%d, not %d" % (t1 / runs, len(recs), j1))
    check("W3d  NULL: JOIN 2 against a RANDOM other descriptor's part B",
          t2 / runs < 0.5 * len(recs), "mean %.1f/%d, not %d" % (t2 / runs, len(recs), j2))
    check("W3e  max(part A) actually VARIES here, so JOIN 2 has content",
          len(set(mA)) > 2, "%d distinct values, 0..%d; %d records have max>0"
          % (len(set(mA)), max(mA), sum(1 for x in mA if x)))
    e8 = sum(1 for _q, t, _o1, _o2 in recs if t & 0x80)
    ok8 = all(ext[o2] % 8 == 0 for _q, t, _o1, o2 in recs if t & 0x80)
    ok6 = all(ext[o2] % 6 == 0 for _q, t, _o1, o2 in recs if not t & 0x80)
    check("W3f  tag bit 7 SET -> part B length a multiple of 8; CLEAR -> of 6",
          ok8 and ok6, "%d set, %d clear" % (e8, len(recs) - e8))
    disc = sum(1 for _q, _t, _o1, o2 in recs if not (ext[o2] % 6 == 0 and ext[o2] % 8 == 0))
    check("W3g  and the rule DISCRIMINATES for 264 of 318 (banner's number)",
          disc == 264, "%d of %d lengths are not multiples of both" % (disc, len(recs)))
    q, t, o1, o2 = recs[-1]
    check("W3h  checked on the LAST descriptor, 317", ext[o2] // 6 == max(D[o1 + 4:o1 + ext[o1]]) + 1,
          "0x%05X tag 0x%02X A=0x%05X(%dB) B=0x%05X(%dB)" % (q, t, o1, ext[o1], o2, ext[o2]))


def w4_chain_38():
    say("\n=== W4.  ★ the SAME chain at slot +0x38 is DEGENERATE ===\n")
    recs, ext, mA, nE, lenA, cur = joins(0x38)
    parts = {o1 for _q, _t, o1, _o2 in recs}
    tab = D[list(parts)[0] + 4:list(parts)[0] + ext[list(parts)[0]]]
    say("  161 descriptors, %d distinct part-A object(s); its table is %d bytes,"
        % (len(parts), len(tab)))
    say("  distinct values %s -- so max(part A) = 0 for every descriptor and every"
        % sorted(set(tab)))
    say("  part B is %s bytes = ONE element.  'JOIN 2 ... 161 of 161' is then the"
        % sorted({ext[o2] for _q, _t, _o1, o2 in recs}))
    say("  statement 0 + 1 == 1, repeated 161 times.\n")
    j2 = sum(1 for x, y in zip(mA, nE) if x + 1 == y)
    random.seed(0)
    q = nE[:]
    random.shuffle(q)
    null = sum(1 for x, y in zip(mA, q) if x + 1 == y)
    check("W4a  JOIN 2 at +0x38 reproduces the banner's 161 of 161", j2 == 161,
          "%d/%d" % (j2, len(recs)))
    # The null DOES score 161/161 -- that is the finding, and it is a fact about the
    # data, not something a fix can change. What the fix changes is whether the tree
    # SAYS so. So this check now records the fact and W4c checks the disclosure.
    check("W4b  the PERMUTATION NULL also scores 161 -- so the join proves nothing here",
          null == len(recs),
          "null = %d/%d" % (null, len(recs)))
    banner = "\n".join(SRC)
    idx = banner.find("ToneDB_EnvDescTable_Perc -- directory slot +0x38")
    blk = banner[idx:idx + 4000] if idx >= 0 else ""
    # ⚠ FINDING APPLIED. The generator now emits the disclosure only where the join
    # cannot fail, so this check asserts the FIXED state rather than the defect.
    check("W4c  the +0x38 banner discloses that the join is not independent evidence",
          "NOT INDEPENDENT EVIDENCE HERE" in blk,
          "the banner prints 'JOIN 2 ... 161 of 161' unqualified")
    j1 = sum(1 for c, l in zip(cur, lenA) if max(D[c:c + 128]) + 1 == l)
    check("W4d  the banner is RIGHT not to claim JOIN 1's +0x30 form here",
          j1 == 0 and "NOT claimed here" in blk, "JOIN 1 in the +0x30 form: %d/161" % j1)


def w5_dangling():
    say("\n=== W5.  ★ dangling label references in the new prose ===\n")
    text = "\n".join(SRC)
    defined = set(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):", text, re.M))
    refs = set(re.findall(r"(ToneDB_EnvDescTable(?:_Perc)?_\d+_(?:CurveStepToElem|ElemArray))",
                          text))
    dang = sorted(r for r in refs if r not in defined)
    check("W5a  every label named in a pool header is actually defined",
          not dang, "%d of %d references dangle, e.g. %s"
          % (len(dang), len(refs), dang[0] if dang else "-"))
    # ⚠ FINDING APPLIED: the prose now names the shared stage-2 step table, which
    # exists, instead of a per-record _CurveStepToElem label that never did.
    check("W5b  ...and none of them is a _CurveStepToElem label any more",
          not any(r.endswith("_CurveStepToElem") for r in dang),
          "%d dangling, last = %s" % (len(dang), dang[-1] if dang else "-"))


def w6_reverted():
    say("\n=== W6.  ★ was a round-3 correction reverted by the round-4 regen? ===\n")
    false_claim = ('; 0x2223B, which is directory slot +0x28\'s value, and ends at 0x22A3B,')
    correction = "0x22A3B is not a directory value at all"
    text = "\n".join(SRC)
    head = subprocess.run(["git", "show", "HEAD:prom_d/wsa1_prom_d.s"], cwd=ROOT,
                          capture_output=True, text=True).stdout
    dirvals = {U32(s) for s in range(0, 0xC0, 4)}
    check("W6a  0x22A3B really is NOT a directory value", 0x22A3B not in dirvals,
          "next value after 0x2223B is 0x%05X" % min(v for v in dirvals if v > 0x2223B))
    check("W6b  HEAD carries the round-3 correction", correction in head)
    # ⚠ FINDING APPLIED, AND AT THE RIGHT LAYER THIS TIME. The round-3 fix was
    # hand-applied to GENERATED output and regenerating put the false wording back.
    # It now lives in scripts/analysis/gen_prom_d_asm.py and is DERIVED per slot:
    # the "next value in the same directory" sentence is emitted only when the cut
    # really is a directory value, so the false form cannot be regenerated.
    check("W6c  the false 'next directory value' wording is gone from ALL slots",
          false_claim not in text,
          "still present" if false_claim in text else "")
    check("W6d  the false claim is absent from the current file", false_claim not in text,
          "present" if false_claim in text else "")
    gen = open(os.path.join(ROOT, "scripts", "analysis", "gen_prom_d_asm.py")).read()
    check("W6e  ...and the generator does not carry the correction either "
          "(so it was hand-applied)", correction not in gen,
          "which is WHY regenerating reverted it")


def curve_index_map():
    """suffix -> k for the six ToneDB_DescCurve_* labels, read out of the .s itself.

    ⚠ PARSER FIX, wave 7 round 5.  This reviewer matched `ToneDB_DescCurve_(\d)`
    and round 5 renamed the six curves after their own run lengths (Step12, Step6,
    Step4, Step3, Step4And2, Step1), which made W7a report 479 false positives and
    made W7c crash.  The CHECKS are unchanged; only the label pattern is.  The map
    is built from each curve's own emitted file address, so this reviewer still
    does not import the code it is reviewing.
    """
    out = {}
    for ln in SRC:
        m = re.match(r"^; (ToneDB_DescCurve_\w+) -- file 0x([0-9A-F]{5})\.\.", ln)
        if m:
            out[m.group(1)] = (int(m.group(2), 16) - 0x22A3B) // 128
    return out


def w7_pool_headers():
    say("\n=== W7.  every pool-object header's arithmetic, recomputed ===\n")
    CK = curve_index_map()
    check("W7pre the six curve labels resolve to k = 0..5 by their own addresses",
          sorted(CK.values()) == list(range(6)),
          ", ".join("%s=%d" % (k, v) for k, v in sorted(CK.items(), key=lambda x: x[1])))
    hdr = re.compile(r"^; (ToneDB_EnvDescTable(?:_Perc)?_\d+_(?:CurveStepToElem|ElemArray))"
                     r" -- file 0x([0-9A-F]{5})\.\.0x([0-9A-F]{5}) \((\d+) bytes\)$")
    bmap = {}
    for slot in (0x30, 0x38):
        recs, _ext, _a, _b = descriptors(slot)
        for _q, _t, o1, o2 in recs:
            bmap[o2] = (U32(o1) - 0x22A3B) // 128
    n = bad = 0
    curve_bad = 0
    for i, ln in enumerate(SRC):
        m = hdr.match(ln)
        if not m:
            continue
        n += 1
        lo, hi, nb = int(m.group(2), 16), int(m.group(3), 16), int(m.group(4))
        blk = "\n".join(SRC[i:i + 12])
        if hi - lo + 1 != nb:
            bad += 1
        if m.group(1).endswith("CurveStepToElem"):
            mm = re.search(r"largest entry is (\d+); that array is (\d+)\n; bytes / (\d+) = "
                           r"(\d+) elements, and (\d+) \+ 1 = (\d+)\.", blk)
            if not mm or int(mm.group(1)) != max(D[lo + 4:hi + 1]) \
                    or int(mm.group(5)) + 1 != int(mm.group(6)):
                bad += 1
        else:
            mm = re.search(r"Reached as (ToneDB_DescCurve_\w+)\[i\]", blk)
            m3 = re.search(r"element size (\d+) is this descriptor's tag 0x([0-9A-F]{2}), "
                           r"bit 7 (SET|CLEAR)", blk)
            if not (mm and m3):
                bad += 1
                continue
            if CK.get(mm.group(1), -2) != bmap.get(lo, -1):
                curve_bad += 1
            tag, esz = int(m3.group(2), 16), int(m3.group(1))
            if (esz == 8) != bool(tag & 0x80):
                bad += 1
    check("W7a  798 pool-object headers, arithmetic self-consistent and matching the ROM",
          n == 798 and bad == 0, "%d headers, %d wrong" % (n, bad))
    check("W7b  479 ElemArray headers name the descriptor's ACTUAL curve",
          curve_bad == 0, "%d wrong" % curve_bad)
    heads = collections.Counter()
    first = {}
    recs, _e, _a, _b = descriptors(0x30)
    for _q, _t, o1, _o2 in recs:
        heads[U32(o1)] += 1
        first.setdefault(U32(o1), o1)
    cbad = 0
    for i, ln in enumerate(SRC):
        m = re.match(r"^; Evidence: (\d+) of the 318 part-A objects at slot \+0x30 "
                     r"name THIS curve", ln)
        if not m:
            continue
        lab = None
        for j in range(i, i + 6):
            mo = re.match(r"^(ToneDB_DescCurve_\w+):", SRC[j])
            if mo:
                lab = CK.get(mo.group(1))
                break
        if lab is None:
            cbad += 1
            continue
        c = 0x22A3B + 128 * lab
        mm = re.search(r"the first is the object at 0x([0-9A-F]{5})", "\n".join(SRC[i:i + 3]))
        if int(m.group(1)) != heads[c] or int(mm.group(1), 16) != first.get(c, -1):
            cbad += 1
    check("W7c  the six DescCurve consumer counts and first-object addresses",
          cbad == 0 and sum(heads.values()) == 318,
          "136+27+7+11+7+130 = %d" % sum(heads.values()))


def w8_prose():
    say("\n=== W8.  are the +1,572 headers NEW PROSE or removed whitespace? ===\n")
    diff = subprocess.run(["git", "diff", "-U0", "prom_d/wsa1_prom_d.s"], cwd=ROOT,
                          capture_output=True, text=True).stdout.split("\n")
    add_c = sum(1 for l in diff if l.startswith("+;"))
    del_c = sum(1 for l in diff if l.startswith("-;"))
    head = subprocess.run(["git", "show", "HEAD:prom_d/wsa1_prom_d.s"], cwd=ROOT,
                          capture_output=True, text=True).stdout.split("\n")
    ob = sum(1 for l in head if not l.strip())
    nb = sum(1 for l in SRC if not l.strip())
    check("W8a  added comment lines vastly exceed deleted ones", add_c > 20 * del_c,
          "+%d comment lines, -%d" % (add_c, del_c))
    check("W8b  blank lines INCREASED, so the gain cannot be the round-3 artefact",
          nb > ob, "%d -> %d blank lines" % (ob, nb))
    check("W8c  the label COUNT is unchanged: this round renamed, it did not convert",
          len(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):", "\n".join(head), re.M))
          == len(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):", "\n".join(SRC), re.M)),
          "3,665 labels before and after; 2,503 of them renamed")


def w9_kn7000():
    say("\n=== W9.  the KN7000 cross-architecture name match, with a null ===\n")
    if not os.path.exists(KN7000):
        say("  SKIP  %s not present" % KN7000)
        return
    K = open(KN7000, "rb").read()
    offs = [U32(0xB80 + 4 * i) for i in range(274)]
    a, stride = U32(0x78), U16(0xEE)
    tn = {D[p:p + 16] for p in offs}
    pn = {D[a + stride * i:a + stride * i + 13] for i in range(504)}
    t = sum(1 for s in tn if s in K)
    p = sum(1 for s in pn if s in K)
    check("W9a  tone names verbatim in the KN7000 table ROM", (t, len(tn)) == (202, 274),
          "%d of %d" % (t, len(tn)))
    check("W9b  drum names verbatim", (p, len(pn)) == (101, 504), "%d of %d" % (p, len(pn)))
    random.seed(0)
    nt = sum(1 for s in tn if bytes(random.sample(list(s), len(s))) in K)
    np_ = sum(1 for s in pn if bytes(random.sample(list(s), len(s))) in K)
    check("W9c  NULL: the same names with their bytes SHUFFLED", (nt, np_) == (0, 0),
          "%d and %d -- so the match is not an artefact of length or alphabet" % (nt, np_))


def main():
    say("REVIEW-WD3 round 4 -- prom_d's new names against the images themselves")
    w1_names()
    w2_reachability()
    w3_chain_30()
    w4_chain_38()
    w5_dangling()
    w6_reverted()
    w7_pool_headers()
    w8_prose()
    w9_kn7000()
    say("\nREVIEW-WD3 round 4: %d FAILED  (the round-4 findings W4c, W5a/W5b and "
        "W6c are APPLIED; W4b now records the null as a fact) -- was "
        "FINDINGS)" % NFAIL[0])
    sys.exit(1 if NFAIL[0] else 0)


main()
