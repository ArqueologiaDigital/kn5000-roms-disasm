#!/usr/bin/env python3
"""Find NEAR-identical copies of a byte range anywhere in the four WSA1R images.

QUESTION IT ANSWERS
    "These bytes resisted every decode and every pointer scan.  Are they a
     near-copy of something already understood -- the same routine linked at a
     different address, so that only operand fields differ?"

WHY IT EXISTS
    An exact substring search answers "is this byte-for-byte duplicated", and
    for relocated code the answer is always no: a `call`'s target, a `jr`'s
    displacement and a 32-bit immediate all change.  Those are 5 or 6 bytes out
    of 33, so an exact search misses a 94% match.  This tool slides the pattern
    over every image and reports Hamming similarity, which is what actually
    separates "unknown content" from "a known routine, relocated".

    ★ It is what identified prom_a 0xFDFFDF-0xFE0000, refused by an earlier
      pass as "genuinely different content": it is 31/33 identical to four
      copies in prom_b (0xF00CB2, 0xF00CF3, 0xF00D34, 0xF00D75) and 28/33 to
      prom_a's own 0xFDE71F, and every differing byte is an operand field.

    ★ A NULL IS PRINTED WITH EVERY ANSWER.  `--null` reports the best score the
      same pattern gets against random offsets, so "94%" can be read against
      what an unrelated stretch of the same ROMs scores.  Without that, a high
      percentage on a short pattern means nothing.

RUN
    python3 notes/prom_a_near_match.py 0xFDFFDF 0xFE0000
    python3 notes/prom_a_near_match.py 0xF8E77C 0xF8E7CD --threshold 60
    python3 notes/prom_a_near_match.py 0xFDFFDF 0xFE0000 --diff prom_b:0xF00CB8
"""
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = {
    "prom_a": ("original_ROMs/wsa1_prom_a.ic12", 0xF80000),
    "prom_b": ("original_ROMs/wsa1_prom_b.ic13", 0xF00000),
    "prom_c": ("original_ROMs/wsa1_prom_c.ic28", 0xF80000),
    "prom_d": ("original_ROMs/wsa1_prom_d.bin", 0x000000),
}


def load(name):
    p, base = IMAGES[name]
    return open(os.path.join(ROOT, p), "rb").read(), base


def scan(pat, skip=None, threshold=70):
    n, out = len(pat), []
    for name in IMAGES:
        d, base = load(name)
        for i in range(len(d) - n + 1):
            if skip and skip == (name, base + i):
                continue
            m = sum(x == y for x, y in zip(pat, d[i:i + n]))
            if m * 100 >= threshold * n:
                out.append((m, name, base + i))
    out.sort(key=lambda r: (-r[0], r[1], r[2]))
    return out


def null(pat, trials=4000, seed=1):
    """Best similarity the SAME pattern gets at random offsets: the control."""
    rnd = random.Random(seed)
    n, best, tot = len(pat), 0, 0
    names = list(IMAGES)
    for _ in range(trials):
        d, _b = load(rnd.choice(names))
        i = rnd.randrange(len(d) - n)
        m = sum(x == y for x, y in zip(pat, d[i:i + n]))
        best = max(best, m)
        tot += m
    return best, tot / trials


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo, hi = int(args[0], 16), int(args[1], 16)
    thr = 70
    for a in sys.argv[1:]:
        if a.startswith("--threshold"):
            thr = int(a.split("=")[1]) if "=" in a else int(sys.argv[sys.argv.index(a) + 1])
    d, base = load("prom_a")
    pat = d[lo - base:hi - base]
    n = len(pat)

    for a in sys.argv[1:]:
        if a.startswith("--diff"):
            spec = a.split("=")[1] if "=" in a else sys.argv[sys.argv.index(a) + 1]
            nm, adr = spec.split(":")
            e, eb = load(nm)
            o = int(adr, 16) - eb
            print("byte-by-byte 0x%06X (prom_a) vs %s 0x%06X" % (lo, nm, int(adr, 16)))
            for k in range(n):
                x, y = pat[k], e[o + k]
                print("  +%02d  %06X %02x   %02x  %s" % (k, lo + k, x, y, "" if x == y else "<-- differs"))
            return 0

    hits = scan(pat, skip=("prom_a", lo), threshold=thr)
    b, mean = null(pat)
    print("pattern prom_a 0x%06X-0x%06X, %d bytes" % (lo, hi, n))
    print("NULL over 4000 random offsets in the same four images: "
          "best %d/%d (%.0f%%), mean %.1f/%d (%.0f%%)"
          % (b, n, 100.0 * b / n, mean, n, 100.0 * mean / n))
    print("matches at or above %d%%:" % thr)
    for m, nm, adr in hits[:20]:
        print("  %3d/%d (%3.0f%%)  %s 0x%06X" % (m, n, 100.0 * m / n, nm, adr))
    if not hits:
        print("  none -- nothing in these four images resembles this range")
    if len(hits) > 20:
        print("  ... %d more" % (len(hits) - 20))
    return 0


if __name__ == "__main__":
    sys.exit(main())
