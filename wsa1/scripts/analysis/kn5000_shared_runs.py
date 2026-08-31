#!/usr/bin/env python3
"""Which WSA1 byte runs also occur in the KN5000 sub-CPU payload, and are they CODE?

Question answered: `technics_roms/tools/wsa1_kinship.py` measured 31,046 bytes shared
between the KN5000 sub-CPU payload and the WSA1 images (null: 0 bytes against an unrelated
Technics ROM). That establishes kinship. It does NOT establish that the shared bytes are
code, and only code carries transplantable labels.

This locates each run in BOTH images and grades it, so that documentation imported from
../kn5000-roms-disasm rests on a run that is actually a routine.

⚠ THE GUARD THAT MATTERS. A long run of identical or near-identical bytes matches by
accident: 0xFF erase fill, 0x00 padding, and repeated table filler all produce long
"shared runs" that mean nothing. Every run is therefore scored and runs are REJECTED when:

  * distinct byte values < MIN_DISTINCT (default 12), or
  * the most common byte is more than MAX_FILL of the run (default 60%), or
  * the run is a single repeating period of <= 4 bytes.

The rejected set is printed, not silently dropped -- if it is most of the mass, the
kinship is in padding and the whole transplant idea is dead. That is the outcome this
script exists to be able to report.

Second guard: a SHUFFLE NULL. The same matcher is run against a byte-shuffled copy of the
payload, which preserves the byte histogram but destroys sequence. Any run length that
scores on shuffled data is reachable by chance at this histogram.

Run:  python3 scripts/analysis/kn5000_shared_runs.py [--minrun N]
"""
import collections
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
PAYLOAD = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")
IMAGES = [("prom_a", "wsa1_prom_a.ic12", 0xF80000),
          ("prom_b", "wsa1_prom_b.ic13", 0xF00000),
          ("prom_c", "wsa1_prom_c.ic28", 0xF80000),
          ("prom_d", "wsa1_prom_d.bin",  0x000000)]

MIN_DISTINCT = 12
MAX_FILL = 0.60


def low_entropy(run):
    c = collections.Counter(run)
    if len(c) < MIN_DISTINCT:
        return True
    if c.most_common(1)[0][1] / len(run) > MAX_FILL:
        return True
    for p in (1, 2, 3, 4):
        if len(run) > 2 * p and run[:-p] == run[p:]:
            return True
    return False


def find_runs(hay, needle_index, minrun):
    """Every maximal run of >= minrun bytes of `hay` that occurs in the payload."""
    out, i, n = [], 0, len(hay)
    while i <= n - minrun:
        key = hay[i:i + minrun]
        if key in needle_index:
            j = needle_index[key][0]
            L = minrun
            while (i + L < n and j + L < needle_index['__len__'] and
                   hay[i + L] == needle_index['__buf__'][j + L]):
                L += 1
            out.append((i, j, L))
            i += L
        else:
            i += 1
    return out


def index(buf, minrun):
    idx = {}
    for i in range(len(buf) - minrun + 1):
        idx.setdefault(buf[i:i + minrun], []).append(i)
    idx['__buf__'] = buf
    idx['__len__'] = len(buf)
    return idx


def main():
    minrun = 16
    if "--minrun" in sys.argv:
        minrun = int(sys.argv[sys.argv.index("--minrun") + 1])
    payload = open(PAYLOAD, "rb").read()
    idx = index(payload, minrun)

    print(f"payload {os.path.basename(PAYLOAD)}: {len(payload):,} bytes, minrun={minrun}\n")
    kept_total = rej_total = 0
    kept_rows = []
    for name, fn, base in IMAGES:
        buf = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        runs = find_runs(buf, idx, minrun)
        k = r = 0
        for off, poff, L in runs:
            if low_entropy(buf[off:off + L]):
                r += L
            else:
                k += L
                kept_rows.append((name, base + off, poff, L))
        kept_total += k
        rej_total += r
        print(f"  {name:7s} {len(runs):5d} runs   kept {k:7,} B   rejected(low-entropy) {r:7,} B")

    print(f"\n  TOTAL kept {kept_total:,} B   rejected {rej_total:,} B")
    if kept_total == 0:
        print("  => the kinship is entirely in fill/padding. No labels are transplantable.")
        return

    # shuffle null
    sh = bytearray(payload)
    random.seed(11)
    random.shuffle(sh)
    sidx = index(bytes(sh), minrun)
    snull = 0
    for name, fn, base in IMAGES:
        buf = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        for off, poff, L in find_runs(buf, sidx, minrun):
            if not low_entropy(buf[off:off + L]):
                snull += L
    print(f"  SHUFFLE NULL (same histogram, sequence destroyed): {snull:,} B kept")
    print(f"  signal-to-null: {kept_total / max(snull, 1):.0f}x\n")

    kept_rows.sort(key=lambda r: -r[3])
    print("  longest surviving runs (wsa1 addr -> payload offset, length):")
    for name, addr, poff, L in kept_rows[:25]:
        print(f"    {name:7s} 0x{addr:06X} -> payload 0x{poff:05X}  {L:5d} B")


if __name__ == "__main__":
    main()
