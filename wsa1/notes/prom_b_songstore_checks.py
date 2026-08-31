#!/usr/bin/env python3
"""Are the numbers in the 0xF7A400-0xF7CFFF headers and in
FINDINGS-prom_b-song-store.md actually true of the ROM?

WHY IT EXISTS
    The byte gate proves the LISTING rebuilds the image and is blind to every
    claim in a comment.  Three claims made by this conversion CORRECT text that
    was already written down elsewhere, which is the most expensive kind to get
    wrong:

      * FINDINGS-prom_b-block-store.md: "⚠ How many entries the directory has
        is NOT established."  It is now: the initialiser writes 17.
      * FINDINGS-memory-map.md row 0x603400 and FINDINGS-prom_b-block-store.md:
        "+0x7E/+0xA0 are 16 saved cursors".  The initialiser writes 17 of each,
        and the two arrays abut at 17, not at 16.
      * the name BStore_SeekBlock_Alloc borrows BStore_SeekBlock's.  Borrowed
        names in this tree must come with a byte diff.

    Each row below re-reads the bytes it argues from.  Exits non-zero on any
    FAIL.  Verified falsifiable: perturbing the loop count, the array base or
    the differing-byte total each produces a FAIL and a non-zero exit.

WHERE THE OTHER CHECKS LIVE -- read this before citing this file
    ⚠ The audit of 2026-08-24 (finding F9) found the round report naming THIS
    script for three claims it does not contain.  It never did: the checks for
    `SongStore_BitMask32`, for the six dispatch tables and for the ten-banks
    chain are not here.  Two of the three are in the module's EMITTER, which
    re-runs them on every emit and refuses to emit if one fails:

        python3 notes/gen_prom_b_songstore_module.py --checks      # 79 rows

    The third -- "the ten banks are the ten songs" -- was checked by NOTHING when
    the claim was written.  It is checked here now, in banks() below, and that is
    the whole reason this docstring section exists.  Cite this file for the free
    list, the 17-entry arrays, the sibling diff, the padding runs and the bank
    chain; cite the emitter for the bit-mask island, the dispatch tables and the
    step-size ladder.

RUN
    python3 notes/prom_b_songstore_checks.py
    python3 notes/prom_b_songstore_checks.py --arrays   # the init census only
    python3 notes/prom_b_songstore_checks.py --banks    # the ten-banks chain only
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
FAIL = []


def at(a, n=1):
    return B[a - 0xF00000: a - 0xF00000 + n]


def at_a(a, n=1):
    return A[a - 0xF80000: a - 0xF80000 + n]


def check(msg, got, want):
    ok = got == want
    print("  %-62s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# The five initialiser loops of BStore_FreeList_Init, as (address of the
# `ld XHL,imm32`, address of the `ld BC,imm16`, address of the `djnz BC`,
# stride).  Nothing is typed twice: base, count and stride are all re-read.
LOOPS = [
    (0xF7A47F, 0xF7A484, 0xF7A495, 3),
    (0xF7A498, 0xF7A49D, 0xF7A4A6, 2),
    (0xF7A4A9, 0xF7A4AE, 0xF7A4B6, 1),
    (0xF7A4B9, 0xF7A4BE, 0xF7A4C7, 2),
    (0xF7A4CA, 0xF7A4CF, 0xF7A4D7, 1),
]


def arrays():
    """(base, count, stride, extent) for each init loop, read from the ROM."""
    out = []
    for lda, ldbc, djnz, stride in LOOPS:
        # `ld XHL,imm32` is 0xC3-family: opcode byte, then 4 bytes LE
        base = int.from_bytes(at(lda + 1, 4), "little")
        cnt = int.from_bytes(at(ldbc + 1, 2), "little")
        out.append((base, cnt, stride, cnt * stride))
    return out


def main():
    only = "--arrays" in sys.argv
    print("BStore_FreeList_Init -- the five arrays it clears")
    print("  %-12s %5s %6s %7s  %s" % ("base", "count", "stride", "bytes", "extent"))
    for base, cnt, stride, n in arrays():
        print("  0x%08X %5d %6d %7d  0x%06X-0x%06X"
              % (base, cnt, stride, n, base, base + n - 1))
    print()
    # 1. every loop counts 17.  TLCS-900 `djnz r,d` decrements THEN tests
    #    (../mame/src/devices/cpu/tlcs900/900tbl.hxx:2061-2070), so BC = 17 runs
    #    the body 17 times.
    check("all five init loops load BC = 17",
          sorted({c for _, c, _, _ in arrays()}), [17])
    check("the LAST loop is 0x006034A0, 17 bytes of 0x05",
          ("0x%08X" % arrays()[-1][0], arrays()[-1][3], at(0xF7A4D2 + 2, 1)[0]),
          ("0x006034A0", 17, 0x05))
    # 2. the saved-cursor pair: word array then byte array, abutting at 17
    w, b_ = arrays()[3], arrays()[4]
    check("saved-cursor word array base", "0x%08X" % w[0], "0x0060347E")
    check("saved-cursor byte array base", "0x%08X" % b_[0], "0x006034A0")
    check("the word array of 17 ends exactly where the byte array starts",
          "0x%08X" % (w[0] + w[3]), "0x%08X" % b_[0])
    check("at 16 entries it would NOT abut (this is what fixes 17, not 16)",
          w[0] + 16 * 2 == b_[0], False)
    check("the same 0x22 separation the append path uses (0x6034A0-0x60347E)",
          b_[0] - w[0], 0x22)
    # 3. the directory: 17 entries of 3 bytes at 0x00603500
    d = arrays()[0]
    check("directory base / count / stride / bytes",
          ("0x%08X" % d[0], d[1], d[2], d[3]), ("0x00603500", 17, 3, 51))
    check("its per-entry writes are byte 0x00 then word 0xFFFF",
          (at(0xF7A487 + 2, 1)[0], at(0xF7A48A + 3, 2)), (0x00, b"\xff\xff"))
    # 4. the internal-RAM twin pair at 0x3460 / 0x3482, same shape
    check("twin word array at 0x00003460, 17 entries",
          ("0x%08X" % arrays()[1][0], arrays()[1][1]), ("0x00003460", 17))
    check("twin byte array at 0x00003482, and 0x3482-0x3460 = 0x22",
          ("0x%08X" % arrays()[2][0], arrays()[2][0] - arrays()[1][0]),
          ("0x00003482", 0x22))
    if only:
        return finish()
    # 5. the borrowed name: BStore_SeekBlock_Alloc vs BStore_SeekBlock
    x, y = at(0xF7A5FF, 0x14), at(0xF63BAE, 0x14)
    diff = [i for i in range(20) if x[i] != y[i]]
    check("0xF7A5FF vs 0xF63BAE: differing bytes in the first 20", len(diff), 18)
    check("the first two bytes of 0xF7A5FF are `ld HL,IY` (0xDD 0x8B)",
          at(0xF7A5FF, 2), b"\xdd\x8b")
    check("0xF63BAE opens with `dec 1,HL` (0xDB 0x69) instead",
          at(0xF63BAE, 2), b"\xdb\x69")
    check("0xF7A5FF adds (0x12A2): the 4 bytes at 0xF7A608",
          at(0xF7A608, 4), b"\xe1\xa2\x12\x83")
    check("0xF63BAE adds (0x3604): the 4 bytes at 0xF63BB5",
          at(0xF63BB5, 4), b"\xe1\x04\x36\x83")
    check("their shared tail (ld (0x126E),XHL / xor XHL,XHL / ret) is 7 bytes",
          at(0xF7A60C, 7), at(0xF63BB9, 7))
    check("and the 8th byte is already the next routine, so the tail stops at 7",
          at(0xF7A60C + 7, 1) == at(0xF63BB9 + 7, 1), False)
    # 6. the two padding runs, re-read
    check("0xF7A7EB-0xF7A9FF is 533 bytes of 0x0E",
          (len(at(0xF7A7EB, 533)), sorted(set(at(0xF7A7EB, 533)))), (533, [0x0E]))
    check("0xF7CE68-0xF7CFFF is 408 bytes of 0x0E",
          (len(at(0xF7CE68, 408)), sorted(set(at(0xF7CE68, 408)))), (408, [0x0E]))
    check("0xF7A7EA, the byte before the first run, is NOT 0x0E",
          at(0xF7A7EA, 1)[0] != 0x0E, True)
    # ⚠ 0xF7CE67 IS 0x0E -- because `ret` IS 0x0E.  The raw run of 0x0E is 409
    # bytes, 0xF7CE67-0xF7CFFF; the transcription reads the FIRST of them as the
    # `ret` that closes the routine ending in `djnz C,0xf7ce3b` at 0xF7CE64,
    # because a routine reached by `call` must return.  Where the routine stops
    # and the padding starts is therefore a READING, not a measurement -- the
    # bytes cannot tell them apart.  Recorded rather than hidden.
    run = 0
    while at(0xF7CE68 - 1 - run, 1)[0] == 0x0E:
        run += 1
    check("the raw 0x0E run reaches back exactly 1 byte, to the closing `ret`",
          run, 1)
    check("the instruction before it is `djnz C,0xf7ce3b` (0xCB 0x1C 0xD4)",
          at(0xF7CE64, 3), b"\xcb\x1c\xd4")
    return finish()


def banks():
    """"The ten banks are the ten SONGS" -- every byte of that chain, re-read.

    FINDINGS-prom_b-song-store.md argues it in four steps.  Three are byte facts
    and are checked here; the fourth (that the variable drawn on screen is the
    song number) rests on display-list NEARNESS, which is evidence for a name and
    not a proof of one -- the finding says so and this script does not pretend
    otherwise.  What IS established below:

      1. one routine copies the bank selector (0x360A) to (0x0E02) and the
         selector PLUS ONE to (0x12F6) -- so the screen variable is index + 1;
      2. this module clamps (0x0E02) to 0..9 in both directions;
      3. prom_a clamps the same (0x360A) to 0..9 in both directions.
    Ten values, 0..9, is where "ten" comes from -- from the two bounds, not from
    counting banks anywhere.

    Falsifiable: every row is a byte comparison against the ROM; change any
    expected byte string and it FAILs and the exit status is non-zero.
    """
    print("the ten-banks chain")
    # 1. the assignment chain at 0xF7AA35, instruction by instruction
    check("0xF7AA35 is `ld A,(0x360a)`", at(0xF7AA35, 4), b"\xc1\x0a\x36\x21")
    check("0xF7AA39 is `ld (0x0e02),A`", at(0xF7AA39, 4), b"\xf1\x02\x0e\x41")
    check("0xF7AA3D is `inc 1,A`", at(0xF7AA3D, 2), b"\xc9\x61")
    check("0xF7AA3F is `ld (0x12f6),A`", at(0xF7AA3F, 4), b"\xf1\xf6\x12\x41")
    # 2. this module's own two bounds on (0x0E02)
    check("0xF7AA99 is `cp A,0x0a` (the way up)", at(0xF7AA99, 3), b"\xc9\xcf\x0a")
    check("0xF7AAC3 is `cp A,0x0a` (the wrap)", at(0xF7AAC3, 3), b"\xc9\xcf\x0a")
    check("0xF7AAC8 is `ld A,0x09` -- the wrap value", at(0xF7AAC8, 2), b"\x21\x09")
    # 3. prom_a's two bounds on the SAME variable.  The load is named as well as
    #    the compare: a `cp` on its own does not say what is being bounded.
    check("prom_a 0xF8143B is `ld A,(0x360a)`", at_a(0xF8143B, 4), b"\xc1\x0a\x36\x21")
    check("prom_a 0xF8143F is `cp A,0` (lower bound)", at_a(0xF8143F, 2), b"\xc9\xd8")
    check("prom_a 0xF814CE is `ld A,(0x360a)`", at_a(0xF814CE, 4), b"\xc1\x0a\x36\x21")
    check("prom_a 0xF814D2 is `cp A,0x09` (upper bound)", at_a(0xF814D2, 3), b"\xc9\xcf\x09")
    # 4. and the count that follows from the two bounds
    lo, hi = at_a(0xF8143F, 2)[1] ^ 0xD8, at_a(0xF814D2, 3)[2]
    check("so the selector's range is 0..9, i.e. TEN values", (lo, hi, hi - lo + 1),
          (0, 9, 10))
    # 5. the bank selector is the one FINDINGS-prom_b-block-store.md derives
    check("0xF64B3F (the block store's own read) is `ld A,(0x360a)`",
          at(0xF64B3F, 4), b"\xc1\x0a\x36\x21")
    return finish()


def finish():
    print("\n%s (%d failed)" % ("PASS" if not FAIL else "FAIL", len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    if "--banks" in sys.argv:
        sys.exit(banks())
    sys.exit(main())
