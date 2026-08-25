#!/usr/bin/env python3
"""Where in prom_a is a run of LE32 POINTERS that a linear decode would eat?

QUESTION IT ANSWERS: "notes/prom_a_linear_decode_check.py catches a table only
when some site CALLS into the middle of it.  A pointer table that nobody calls
into passes that check and is then emitted as ~30 lines of plausible-looking
garbage instructions -- which the byte gate cannot see either.  Where are they?"

METHOD.  A word is POINTER-SHAPED if its four bytes are `lo mid hi 00` with
0x00F00000 <= value <= 0x00FFFFFF (an address in prom_a or prom_b), or if it is
0x00000000 (a NULL slot, which real tables contain).  A RUN is >= MIN
consecutive pointer-shaped words at stride 4.  Runs are reported per starting
alignment and the longest at each start position wins.

⚠ THE NULL CONTROL IS THE POINT.  Ordinary TLCS-900 code contains 32-bit
immediates that are prom_a addresses (`ld XIX,0x00f80300`), so short runs occur
by chance.  `--null` runs the SAME detector over a span of prom_a that is
already converted and known to be code, and prints how many runs of each length
it finds there.  Read the null before believing a hit: at MIN=6 the null over
0xFB2000-0xFB8000 (23 KiB of converted code with its tables declared) is what
calibrates it.  Do not lower MIN without re-running the null.

    python3 notes/prom_a_ptr_tables.py 0xF99021 0xFA1404
    python3 notes/prom_a_ptr_tables.py 0xF99021 0xFA1404 --min 8
    python3 notes/prom_a_ptr_tables.py --null
    python3 notes/prom_a_ptr_tables.py --checks
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000
DEFAULT_MIN = 6


def word(addr):
    o = addr - BASE
    return int.from_bytes(A[o:o + 4], "little")


def is_ptr(w):
    return w == 0 or 0x00F00000 <= w <= 0x00FFFFFF


def runs(lo, hi, minlen=DEFAULT_MIN):
    """[(start, entries)] maximal runs of >= minlen pointer-shaped words.

    Scanned at every byte offset, not only 4-aligned ones: these tables are NOT
    aligned in this ROM (ModuleInitDirectory_F82641 starts on an odd address).
    A run that starts inside a longer one is dropped."""
    out = []
    i = lo
    while i < hi - 4:
        n = 0
        j = i
        while j + 4 <= hi and is_ptr(word(j)):
            n += 1
            j += 4
        if n >= minlen:
            out.append((i, n))
            i = j                     # do not re-report suffixes of this run
        else:
            i += 1
    # keep only runs not contained in a longer already-reported one
    out.sort(key=lambda r: (-r[1], r[0]))
    kept = []
    for s, n in out:
        if not any(k <= s and s + 4 * n <= k + 4 * m for k, m in kept):
            kept.append((s, n))
    return sorted(kept)


def show(lo, hi, minlen):
    rs = runs(lo, hi, minlen)
    total = sum(4 * n for _, n in rs)
    print("0x%06X-0x%06X, MIN=%d: %d run(s), %d bytes"
          % (lo, hi - 1, minlen, len(rs), total))
    for s, n in rs:
        ws = [word(s + 4 * k) for k in range(n)]
        nn = sum(1 for w in ws if w == 0)
        print("  0x%06X  %3d entries  0x%06X-0x%06X  %d null  range 0x%06X-0x%06X"
              % (s, n, s, s + 4 * n - 1, nn,
                 min(w for w in ws if w) if any(ws) else 0, max(ws)))
    return rs


NULL_LO, NULL_HI = 0xFB2000, 0xFB8000       # converted code, tables declared


def null_control(minlen):
    print("NULL CONTROL: the same detector over 0x%06X-0x%06X, %d bytes of prom_a "
          "that is already converted CODE" % (NULL_LO, NULL_HI, NULL_HI - NULL_LO))
    for m in (4, 5, 6, 8, 12, 16):
        rs = runs(NULL_LO, NULL_HI, m)
        print("   MIN=%-3d %3d run(s), %6d bytes" % (m, len(rs), sum(4 * n for _, n in rs)))
    print("   (a detector whose null is not near zero at the MIN you use is "
          "measuring code, not tables)")


def checks():
    fails = []

    def t(msg, cond, detail=""):
        print("%-4s %s%s" % ("ok" if cond else "FAIL", msg,
                             ("  -- " + detail) if detail else ""))
        if not cond:
            fails.append(msg)

    # 1. it finds a table this tree has ALREADY established by other means
    rs = dict(runs(0xF82600, 0xF826C0, 6))
    t("finds ModuleInitDirectory_F82641 (25 pointers) as a run at 0xF82641",
      rs.get(0xF82641) == 25, str(rs))
    # 2. and the blink table, which is only 6 entries with two NULLs
    rs = dict(runs(0xF80740, 0xF80780, 6))
    t("finds BlinkArgPtrs_F80754 (6 entries, 2 NULL)", rs.get(0xF80754) == 6, str(rs))
    # 3. NEGATIVE CONTROL: a run of pure code produces nothing at MIN=6
    n = len(runs(0xF8E5F6, 0xF8E6A2, 6))       # Link_ServiceTask + WaitBlockDone
    t("NEGATIVE CONTROL: Link_ServiceTask/Link_WaitBlockDone (172 B of known "
      "code) yields 0 runs at MIN=6", n == 0, str(n))
    # 4. the null over 24 KiB of converted code is small at MIN=6
    nb = sum(4 * k for _, k in runs(NULL_LO, NULL_HI, 6))
    t("null over 0xFB2000-0xFB8000 is under 2%% of the span at MIN=6",
      nb < 0.02 * (NULL_HI - NULL_LO), "%d bytes of %d" % (nb, NULL_HI - NULL_LO))
    # 5. LAST-ELEMENT test on the ModuleInitDirectory run: the word after it is
    #    the terminator, which is NOT pointer-shaped, and that is why the run stops
    t("LAST-ELEMENT: the word after the 25-entry run is 0xFFFFFFFF, not a pointer",
      word(0xF82641 + 100) == 0xFFFFFFFF and not is_ptr(0xFFFFFFFF),
      "0x%08X" % word(0xF82641 + 100))
    print("\n%d checks, %d FAILED" % (5, len(fails)))
    return 1 if fails else 0


def main():
    if "--checks" in sys.argv:
        return checks()
    minlen = DEFAULT_MIN
    if "--min" in sys.argv:
        minlen = int(sys.argv[sys.argv.index("--min") + 1])
    if "--null" in sys.argv:
        null_control(minlen)
        return 0
    args = [x for x in sys.argv[1:] if x.startswith("0x")]
    if len(args) != 2:
        print(__doc__)
        return 2
    show(int(args[0], 16), int(args[1], 16), minlen)
    return 0


if __name__ == "__main__":
    sys.exit(main())
