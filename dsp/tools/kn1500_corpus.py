#!/usr/bin/env python3
"""kn1500_corpus.py -- the KN1500's uPD6383 microcode, as a corpus other tools can import.

WHAT THIS IS
    The KN1500 is the THIRD product found to carry uPD6383GF microcode (N-INPUT-GATE-OPENED
    sect. 204).  Felipe confirmed the chip independently, AFTER the scan found it: a
    **D6383GF-3BA at IC3**.  Its programs live in IC15 at roughly 0x1A414D..0x1AC18B and are
    recovered by `dsp_corpus_scan.py', whose extraction quality is measured on the KN5000
    control at **93 % block recall / 94 % word recall / 95 % precision** (sect. 206).

    ⚠⚠ THIS IS NOT A DISASM TREE AND MUST NOT BE MISTAKEN FOR ONE.  `class_twins.CORPORA' is the
    authoritative pooled corpus and is built from two hand-verified trees; this module is a
    SCAN-DERIVED corpus with a known 5-7 % error rate in both directions, kept separate on
    purpose.  Merging it into a published RATE would be wrong twice over: the extraction is
    lossy, and the scan SELECTS streams by vocabulary match, so any decode rate computed on it
    is manufactured by that filter (sect. 205; `dsp_corpus_scan.py --bias' prints the curve).

WHAT IT IS FOR
    The one KN1500 avenue still open (sect. 208, after relocation was tested and failed): its
    **175 distinct words that exist in NO other product** and have never been through the static
    instruments -- `class_twins', `idiom_sequence', `topology_fingerprint' -- that the other two
    corpora have had.

USAGE
    import kn1500_corpus as K
    K.blocks()      -> [(iram_addr, (word, ...)), ...]   distinct op-3 blocks
    K.words()       -> [word, ...]                        every word, in block order
    K.new_words()   -> [word, ...]                        those in NO other product
    python3 dsp/tools/kn1500_corpus.py                    summary + the new-word census
"""
import collections
import functools
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_corpus_scan as S                                               # noqa: E402
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402

ROM = os.path.join(os.path.expanduser("~"), "compartilhado", "kn7000_mame_build", "roms",
                   "kn1500", "technics_qsigt3c16079_5y68-j079_japan_9649eai.ic15.rest")


@functools.lru_cache(maxsize=1)
def blocks():
    """Distinct op-3 blocks, in ROM order: [(iram_addr, (word, ...)), ...]."""
    d = open(ROM, "rb").read()
    tri, hi, cl, lo = S.vocabulary()
    out, seen = [], set()
    for h in S.scan(d, tri, hi, cl, lo):
        r = S.parse_stream(d, h[0])
        if not r:
            continue
        for a, ws in r[0]:
            t = tuple(ws)
            if t in seen:
                continue
            seen.add(t)
            out.append((a, t))
    return out


def words():
    return [w for _a, ws in blocks() for w in ws]


@functools.lru_cache(maxsize=1)
def known_words():
    """Every word of the authoritative pooled corpus (KN5000 + SX-WSA1R)."""
    s = set()
    for _l, _img, _sl, ws in CT.images():
        s.update(ws)
    return s


def new_words():
    """Words present in the KN1500 and in NO other product, in block order."""
    k = known_words()
    return [w for w in words() if w not in k]


def main():
    bl = blocks()
    ws = words()
    nw = new_words()
    nd = sorted(set(nw))
    print("=" * 88)
    print("  kn1500_corpus -- the third product's microcode")
    print("=" * 88)
    print("\n  distinct op-3 blocks %d | words %d | already in the pooled corpus %d (%.0f %%)"
          % (len(bl), len(ws), len(ws) - len(nw), 100.0 * (len(ws) - len(nw)) / len(ws)))
    print("  NEW words %d occurrences, %d DISTINCT -- present in no other product"
          % (len(nw), len(nd)))
    print("\n  blocks by I-RAM load address:")
    for a, n in sorted(collections.Counter(a for a, _w in bl).items()):
        print("     0x%04X  %2d blocks" % (a, n))

    import acc_blind as AB                                                # noqa: E402
    dec = sum(1 for w in nd if DIS.decoded(w))
    print("\n  of the %d distinct NEW words: %d decode under the current model, %d do not"
          % (len(nd), dec, len(nd) - dec))
    ax = collections.Counter(tuple(sorted(AB.open_axes(w))) for w in nd if not DIS.decoded(w))
    print("\n  open-axis sets among the new undecoded words:")
    for a, n in ax.most_common():
        print("     %3d  %s" % (n, ", ".join(a) if a else "(none)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
