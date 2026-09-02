#!/usr/bin/env python3
"""
QUESTION: when the backend re-assembles unidasm's own text and gets DIFFERENT
          bytes, WHAT information did unidasm's text fail to carry?

Reads oracle_ab_reassembly.csv (produced by oracle_ab.py) and buckets every
UNI_ASSEMBLES_DIFF spelling by comparing the bytes the ROM has (want) against
the bytes the backend produced from unidasm's text (got):

  ADDR_WIDTH      the two differ only in the memory-operand PREFIX TIER and
                  the length of the address field.  The TLCS-900 spells the
                  same direct address in an 8-, 16- or 24-bit field (C0/C1/C2,
                  D0/D1/D2, E0/E1/E2, F0/F1/F2) and unidasm prints "(0x0516)"
                  for all three.  ⚠ The width is NOT recoverable from the
                  value: this firmware writes set 7,(0x00008a) as F2 8A 00 00
                  BF for an address that fits in eight bits.
  SHORT_FORM      the ROM uses a one-byte opcode and the backend chose the
                  two-byte prefixed form, or vice versa (push WA = 28 vs
                  d8 04; ld HL,0 = db a8 vs db 03 00 00).
  OTHER           anything else -- listed in full so it can be looked at.

EXACT COMMAND (from the tree root):

    python3 notes/syntax-convergence-probes/diff_causes.py \
        notes/syntax-convergence-probes/out
"""
import csv, collections, sys, os

# memory-operand prefix tiers: (8-bit addr, 16-bit addr, 24-bit addr)
TIERS = [(0xC0, 0xC1, 0xC2), (0xD0, 0xD1, 0xD2),
         (0xE0, 0xE1, 0xE2), (0xF0, 0xF1, 0xF2)]
TIER_OF = {}
for t in TIERS:
    for w, b in enumerate(t):
        TIER_OF[b] = (t, w)
WIDTH_BYTES = (1, 2, 3)


def strip_direct(b):
    """(tier, tail) for a direct-memory-operand encoding, else None."""
    if not b or b[0] not in TIER_OF:
        return None
    tier, w = TIER_OF[b[0]]
    n = WIDTH_BYTES[w]
    if len(b) < 1 + n:
        return None
    addr = int.from_bytes(b[1:1 + n], "little")
    return (tier, addr, b[1 + n:])


def classify(want, got):
    a, c = strip_direct(want), strip_direct(got)
    if a and c and a[0] == c[0] and a[1] == c[1] and a[2] == c[2]:
        return "ADDR_WIDTH"
    # short form: one is a bare opcode, the other the same op behind a prefix
    if abs(len(want) - len(got)) >= 1 and (
            (want[0] in TIER_OF) != (got[0] in TIER_OF)):
        return "SHORT_FORM"
    if len(want) != len(got) and (want[0] & 0xF8) != (got[0] & 0xF8):
        return "SHORT_FORM"
    return "OTHER"


def main(outdir):
    rows = list(csv.DictReader(open(os.path.join(outdir,
                                                 "oracle_ab_reassembly.csv"))))
    cnt, sites = collections.Counter(), collections.Counter()
    others = []
    for r in rows:
        if r["verdict"] != "UNI_ASSEMBLES_DIFF":
            continue
        try:
            want = bytes.fromhex(r["want_bytes"])
            got = bytes.fromhex(r["got_bytes"])
        except ValueError:
            k = "OTHER"
        else:
            k = classify(want, got)
        cnt[k] += 1
        sites[k] += int(r["sites"])
        if k == "OTHER":
            others.append(r)
    print("%-14s %10s %10s" % ("cause", "spellings", "sites"))
    for k in ("ADDR_WIDTH", "SHORT_FORM", "OTHER"):
        print("%-14s %10d %10d" % (k, cnt[k], sites[k]))
    print("%-14s %10d %10d" % ("TOTAL", sum(cnt.values()), sum(sites.values())))
    byn = collections.Counter()
    for r in others:
        byn[r["llvm_mnemonic"]] += int(r["sites"])
    print("\ntop OTHER by tree mnemonic:")
    for k, v in byn.most_common(20):
        print("   %-16s %8d" % (k, v))
    with open(os.path.join(outdir, "diff_causes_other.csv"), "w") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        for r in sorted(others, key=lambda r: -int(r["sites"])):
            w.writerow(r)
    print("\nwrote %s/diff_causes_other.csv" % outdir)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else
         "notes/syntax-convergence-probes/out")
