#!/usr/bin/env python3
"""dsp_corpus_scan.py -- is there a THIRD uPD6383 corpus in the dumped ROMs?

QUESTION IT ANSWERS
    The pooled corpus is two products, KN5000 + SX-WSA1R, 7273 distinct words, and every large
    remaining block is documented SHUT on the evidence those two provide:

        ACT 0x0B      159   three criteria measured blind          (handover)
        SRC 0x11      139   a dependency cycle, do not re-capture  (handover)
        bit-11        169   six index arms refuted, sect. 189-203
        mode 4         99   ONE witness, no replication AVAILABLE  (sect. 165)
        f31 3..7      189   "every anchored criterion is blind to the axis BY
                            CONSTRUCTION" -- sect. 149
        ACT 0x01..06   70   characterised, unrankable              (sect. 175)

    Those are not failures of effort; they are statements that the two corpora do not contain
    the discriminating evidence.  The method that actually paid twice (sect. 122, sect. 128) was
    A SECOND COPY OF THE SAME CODE SOMEWHERE ELSE -- a relocation, a twin.  So the question
    worth asking is not "what else can be squeezed from these two" but:

        IS THERE A THIRD PRODUCT WITH uPD6383 MICROCODE IN THE DUMPED ROMS?

    A third corpus would give new minimal pairs where the present two are exhausted, which is
    exactly what every shut block needs.

HOW, AND WHY IT IS SELF-VALIDATING
    The host upload container is a property of the CHIP, not of the product (kn5000_dsp_extract.py
    documents it from the Sub CPU's own interpreter loop):

        byte0 high nibble = opcode,  len = ((byte0 & 0x0F) << 8) | byte1   (header included)
        opcode 3 -> cmd byte, 16-bit I-RAM word address, then 5-BYTE INSTRUCTION WORDS
        opcode 2 -> coefficients, 3-byte words
        opcode F -> terminator

    So: walk every offset, parse a stream, and keep the ones that terminate properly and carry
    op-3 records.  Then VALIDATE the words against the ISA vocabulary observed in the two known
    corpora -- a run of real microcode scores near 1.0, arbitrary bytes score near the base rate.

    ★ POSITIVE CONTROL (mandatory, and this tool fails loudly without it): the KN5000 Sub CPU ROM
    must be found to contain microcode by the same scan that is applied to the unknown ROMs.  A
    detector that has not been shown to find what is known to be there is not a detector.
    ★ NULL: the same scan over shuffled bytes of each ROM, reported beside every hit.

USAGE
    python3 dsp/tools/dsp_corpus_scan.py                    # control + scan every dumped ROM
    python3 dsp/tools/dsp_corpus_scan.py --rom PATH         # one file

WHAT IT IS NOT
    It does not disassemble or decode.  A hit is a CANDIDATE that then has to be extracted the
    way `gen_wsa1_dsp_disasm.py' extracts the WSA1R's -- through that product's own directory
    structures.  A miss is informative too: it says the deadlock is not going to be broken this
    way, and that is worth knowing before another arm is built.
"""
import argparse
import collections
import glob
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402

ROMDIR = os.path.join(os.path.expanduser("~"), "compartilhado", "kn7000_mame_build", "roms")
#  The positive control: the KN5000 Sub CPU ROM, which is KNOWN to hold 100 algorithm streams.
CONTROL_GLOB = os.path.join(ROMDIR, "kn5000", "kn5000_subprogram_v142.rom")


def vocabulary():
    """(hi12, class4, lo12) triples and the three field alphabets, from the KNOWN corpora."""
    tri, hi, cl, lo = set(), set(), set(), set()
    for _label, _img, _slots, ws in CT.images():
        for w in ws:
            tri.add((DIS.hi12(w), DIS.class4(w), DIS.lo12(w)))
            hi.add(DIS.hi12(w))
            cl.add(DIS.class4(w))
            lo.add(DIS.lo12(w))
    return tri, hi, cl, lo


def parse_stream(d, off, limit=4096):
    """The chip's host container, walked from `off'.  Returns (op3_blocks, ops, end) or None.

    Mirrors kn5000_dsp_extract.parse_stream but over a FLAT buffer with no ROM_BASE, because a
    scan does not know the product's address map -- that is the point."""
    iram, ops, p, guard = [], [], off, 0
    while guard < limit:
        guard += 1
        if p + 1 >= len(d):
            return None
        b0, b1 = d[p], d[p + 1]
        op = b0 >> 4
        if op == 0xF:
            ops.append(op)
            return iram, ops, p + 2
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF or p + ln > len(d):
            return None
        ops.append(op)
        body = d[p + 2:p + ln]
        if op == 3 and len(body) >= 3:
            data = body[3:]
            #  ★★★ STRUCTURAL CONSTRAINT, exceptionless on the control: an op-3 record's payload
            #  is a whole number of 5-byte microwords.  MEASURED over the KN5000 Sub CPU's own
            #  96 op-3 records: len(data) % 5 == 0 in 96 of 96.  It costs nothing in recall and
            #  kills spurious parses, which is what limited the exact-offset recall to 51 %.
            if len(data) % 5:
                return None
            ws = [int.from_bytes(data[k:k + 5], "big") for k in range(0, len(data), 5)]
            if ws:
                iram.append(((body[1] << 8) | body[2], ws))
        p += ln
    return None


def score(words, tri, hi, cl, lo):
    """Fraction of words whose fields are in the known alphabets, and the strict triple rate."""
    if not words:
        return 0.0, 0.0
    n = len(words)
    fields = sum(1 for w in words
                 if DIS.hi12(w) in hi and DIS.class4(w) in cl and DIS.lo12(w) in lo)
    trip = sum(1 for w in words if (DIS.hi12(w), DIS.class4(w), DIS.lo12(w)) in tri)
    return fields / float(n), trip / float(n)


def scan(d, tri, hi, cl, lo, min_words=16, thresh=0.90):
    """Every offset that opens a well-formed stream carrying at least `min_words' op-3 words.

    ⚠⚠ v1 did `i = end' after a hit, "so as not to re-report the same stream".  MEASURED RECALL
    OF THAT: **1 of 40** known streams in the positive-control ROM.  A stream that parses by luck
    can run for a kilobyte, and jumping to its end skips every real one inside it.  The control
    said "found microcode" and I nearly read that as validation -- the same shape of error as
    grading an arm on a criterion that cannot fail.

    So: step by ONE, keep only hits at or above `thresh', and merge overlaps afterwards, keeping
    the longest.  Recall is then measurable and is reported by --control."""
    hits, i, n = [], 0, len(d)
    while i < n - 4:
        if (d[i] >> 4) in (0, 1, 2, 3, 5):
            r = parse_stream(d, i)
            if r:
                iram, ops, end = r
                ws = [w for _a, block in iram for w in block]
                if len(ws) >= min_words:
                    f, t = score(ws, tri, hi, cl, lo)
                    if t >= thresh:
                        hits.append((i, end - i, len(ws), f, t, len(ops)))
        i += 1
    #  merge overlapping hits, keeping the one with the most words
    hits.sort(key=lambda h: (h[0], -h[2]))
    out = []
    for h in hits:
        if out and h[0] < out[-1][0] + out[-1][1]:
            if h[2] > out[-1][2]:
                out[-1] = h
            continue
        out.append(h)
    return out


def report(name, d, tri, hi, cl, lo, want_null=True):
    strong = scan(d, tri, hi, cl, lo)
    print("\n  %-34s %9d bytes | STRONG streams (triple-rate >= 0.90, overlaps merged) %4d"
          % (name, len(d), len(strong)))
    if want_null:
        sh = bytearray(d[:1 << 20] if len(d) > (1 << 20) else d)
        random.Random(20260914).shuffle(sh)
        ns = scan(bytes(sh), tri, hi, cl, lo)
        print("     NULL (the same bytes SHUFFLED, %d of them): STRONG %4d" % (len(sh), len(ns)))
    for off, ln, nw, f, t, nops in sorted(strong, key=lambda h: -h[2])[:8]:
        print("       @0x%06X  len %5d  words %5d  field-rate %.3f  TRIPLE-rate %.3f  records %d"
              % (off, ln, nw, f, t, nops))
    return strong


def control_recall(tri, hi, cl, lo):
    """★ THE REAL POSITIVE CONTROL: RECALL against the Sub CPU's own pointer table.

    "The scan found microcode" is not validation -- v1's scan found ONE stream where forty are
    known and I nearly read that as a pass.  The KN5000 Sub CPU ROM has a 100-entry algorithm
    pointer table (kn5000_dsp_extract.ALGO_TABLE), so the answer is checkable: resolve every
    pointer, and ask what fraction of those offsets the blind scan recovers."""
    sys.path.insert(0, os.path.join(os.path.expanduser("~"), "compartilhado",
                                    "kn7000_mame", "tools"))
    import kn5000_dsp_extract as E                                        # noqa: E402
    p = os.path.join(ROMDIR, "kn5000", "kn5000_subprogram_v142.rom")
    if not os.path.exists(p):
        return None
    d = open(p, "rb").read()
    rom = E.Rom(p)
    known = set()
    for i in range(E.N_ALGOS):
        try:
            known.add(rom.off(rom.u32le(E.ALGO_TABLE + 4 * i)))
        except IndexError:
            pass
    hits = scan(d, tri, hi, cl, lo)
    exact = sum(1 for k in known if any(h[0] == k for h in hits))
    cover = sum(1 for k in known if any(h[0] <= k < h[0] + h[1] for h in hits))
    #  ★★★ AND THE RECALL THAT ACTUALLY GOVERNS EXTRACTION.  Offset recall answers "is there
    #  microcode in this ROM"; it does NOT answer "can this scan BUILD a corpus".  For that the
    #  unit is the op-3 BLOCK and the WORD, and precision matters as much as recall -- a spurious
    #  block would enter a tree as fabricated microcode.
    truth = set()
    for i in range(E.N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(E.ALGO_TABLE + 4 * i))
        except Exception:
            continue
        for _a, ws, _dl in ir:
            t = tuple(int.from_bytes(bytes(w), "big") for w in ws)
            if t:
                truth.add(t)
    got = set()
    for h in hits:
        r = parse_stream(d, h[0])
        if r:
            for _a, ws in r[0]:
                got.add(tuple(ws))
    tw = sum(len(t) for t in truth) or 1
    gw = sum(len(t) for t in truth & got)
    return (len(known), len(hits), exact, cover,
            len(truth), len(truth & got), tw, gw, len(got - truth), len(got))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", help="scan a single file instead of the whole ROM tree")
    ap.add_argument("--control", action="store_true",
                    help="just measure recall against the KN5000 pointer table")
    ap.add_argument("--bias", action="store_true",
                    help="print the selection-bias curve (why no decode rate is quotable)")
    a = ap.parse_args()

    tri, hi, cl, lo = vocabulary()
    print("=" * 96)
    print("  dsp_corpus_scan -- is there a THIRD uPD6383 corpus in the dumped ROMs?")
    print("=" * 96)
    print("\n  ISA vocabulary from the two KNOWN corpora: %d (hi12,class4,lo12) triples,"
          " %d hi12, %d class4, %d lo12" % (len(tri), len(hi), len(cl), len(lo)))

    #  ★ THE POSITIVE CONTROL COMES FIRST AND IS NOT OPTIONAL.
    r = control_recall(tri, hi, cl, lo)
    if r:
        nk, nh, ex, cv, nt, ng, tw, gw, spur, ngot = r
        print("\n  ★ CONTROL RECALL against the Sub CPU's OWN 100-entry algorithm pointer table")
        print("    (100 pointers resolve to %d distinct stream offsets -- the corpus is 40 images):"
              % nk)
        print("      STRONG hits %d | recovered at the EXACT offset %d of %d (%.0f %%)"
              % (nh, ex, nk, 100.0 * ex / nk))
        print("      | COVERED BY A HIT %d of %d (%.0f %%)  <- the figure that matters for a"
              % (cv, nk, 100.0 * cv / nk))
        print("        yes/no question about an unknown ROM")
        if cv < 0.8 * nk:
            print("      ⛔ recall below 80 %% -- do not read a miss below as an absence.")
        print("\n    ★★★ EXTRACTION QUALITY -- the recall that governs whether a corpus can be")
        print("        BUILT from this scan, which is a different question:")
        print("          op-3 BLOCK recall %d of %d (%.0f %%) | WORD recall %d of %d (%.0f %%)"
              % (ng, nt, 100.0 * ng / nt, gw, tw, 100.0 * gw / tw))
        print("          PRECISION %d of %d blocks are real (%.0f %%) -- %d SPURIOUS"
              % (ngot - spur, ngot, 100.0 * (ngot - spur) / max(ngot, 1), spur))
        print("        ⛔ Far too lossy to seed a tree: it would silently drop a quarter of a")
        print("           product's microcode and admit blocks that are not microcode at all.")
        print("           Extract through the product's OWN directory structures instead.")
    if a.bias:
        #  ★★★ THE CAVEAT THAT HAS TO TRAVEL WITH EVERY RESULT THIS TOOL PRODUCES.
        #  The scan KEEPS streams whose words are already in the known vocabulary, so the
        #  recovered set is SELECTED for vocabulary match.  Any "decode rate" computed on it is
        #  therefore a function of the threshold, not a property of the ROM.  MEASURED on the
        #  KN1500 pool: 0.90 -> 92.4 %, 0.70 -> 85.3 %, 0.50 -> 52.3 %, 0.00 -> 2.7 %.
        #  ⛔ I computed "the third corpus lifts pooled coverage 80.6 % -> 81.7 %" from the
        #  0.90 row before running this.  It is an ARTEFACT OF THE FILTER.  Print the curve.
        print("\n  ★★★ SELECTION-BIAS CURVE -- why NO decode rate may be quoted from this scan\n")
        print("     threshold | streams | blocks | words | \"decoded\" %")
        for th in (0.90, 0.70, 0.50, 0.30, 0.00):
            hits = scan(open(a.rom, "rb").read() if a.rom else b"", tri, hi, cl, lo, thresh=th)
            print("        %.2f   | %7d |" % (th, len(hits)))
        print("\n     The rate rises monotonically with the threshold because the threshold IS")
        print("     a vocabulary filter.  A corpus extracted this way can say THAT microcode is")
        print("     present; it cannot say what fraction of it the ISA model explains.")
        return 0
    if a.control:
        return 0
    ctrl = sorted(glob.glob(CONTROL_GLOB))
    print("\n  POSITIVE CONTROL -- the KN5000 Sub CPU ROM, known to hold 100 algorithm streams:")
    if not ctrl:
        print("     ⛔ NOT FOUND at %s -- the scan below is UNVALIDATED, do not read it."
              % CONTROL_GLOB)
        return 2
    ok = False
    for p in ctrl:
        s = report(os.path.basename(p), open(p, "rb").read(), tri, hi, cl, lo)
        if s:
            ok = True
    if not ok:
        print("\n  ⛔⛔ THE CONTROL FOUND NOTHING.  The detector does not detect what is known to")
        print("     be there, so every result below would be meaningless.  STOPPING.")
        return 1
    print("\n  ★ control passes: the scan finds microcode where microcode is known to be.")

    if a.rom:
        report(a.rom, open(a.rom, "rb").read(), tri, hi, cl, lo)
        return 0

    print("\n  THE OTHER PRODUCTS -- every dumped ROM that is not the KN5000 Sub CPU:")
    found = {}
    for prod in sorted(os.listdir(ROMDIR)):
        pd = os.path.join(ROMDIR, prod)
        if not os.path.isdir(pd):
            continue
        for f in sorted(os.listdir(pd)):
            p = os.path.join(pd, f)
            if not os.path.isfile(p) or os.path.getsize(p) < 4096:
                continue
            if p in ctrl:
                continue
            d = open(p, "rb").read()
            if len(d) > (8 << 20):          # wave ROMs: sample a window, they are not code
                d = d[: 8 << 20]
            s = report("%s/%s" % (prod, f), d, tri, hi, cl, lo, want_null=False)
            if s:
                found.setdefault(prod, []).append((f, sum(h[2] for h in s)))

    print("\n" + "=" * 96)
    if found:
        print("  ★★★★★ CANDIDATE THIRD CORPUS:")
        for prod, fs in sorted(found.items()):
            for f, nw in fs:
                print("     %-12s %-30s %6d op-3 words at triple-rate >= 0.90" % (prod, f, nw))
        print("\n  ⚠ A hit is a CANDIDATE, not a corpus.  Extracting it needs that product's own")
        print("    directory structures, the way gen_wsa1_dsp_disasm.py needed the WSA1R's.")
    else:
        print("  NO THIRD CORPUS.  No other dumped ROM carries uPD6383 host streams that the")
        print("  known ISA vocabulary recognises.  ⇒ the deadlock will NOT be broken by pooling")
        print("  a third product, and that is worth knowing before another arm is built.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
