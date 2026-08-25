#!/usr/bin/env python3
"""The 616-byte floating-point constant pool at prom_c 0xFCC81A: where do its elements start?

QUESTION IT ANSWERS
  This pool was the last `.incbin` in prom_c, and it was left as one ON PURPOSE.  The
  source said so: "it is an IEEE-754 constant pool -- IEEE doubles are visible in it by eye
  ... but the element boundaries are NOT established: decoding it as f64 from any of the
  obvious start offsets yields mostly denormal garbage (7 of 76 candidates come out as
  round numbers from the best-looking alignment) ... An honest .incbin beats an invented
  stride."

  The boundaries do not have to be guessed.  EVERY element of this pool is loaded by a
  literal-addressed instruction, so the code fixes all of them:

    * `notes/prom_c_tail_census.py`'s classifier, run over 0xFCC81A-0xFCCA81, finds 154
      cited addresses -- 4-byte aligned, consecutive, and covering the 616 bytes exactly.
    * A DOUBLE is pushed as two 32-bit halves, HIGH first, by two `ld XBC,(nnn) / push XBC`
      pairs six bytes apart:
          F9C2DE  ld XBC,(0xFCC9EE)   <- high half
          F9C2E3  push XBC
          F9C2E4  ld XBC,(0xFCC9EA)   <- low half, the double's address
          F9C2E9  push XBC
      so "element A and element A+4 are one f64" is not an assumption about stride: it is
      an instruction at a known address loading A+4 and the instruction six bytes later
      loading A.  76 of the 78 elements pair that way, and all 76 have at least one such
      witness.
    * The two that do NOT pair are what broke the stride, which is why decoding from a
      fixed 8-byte grid failed: 0xFCC81A is used as `add XBC,(0xFCC81A)` -- an ADDRESS, the
      value 0x0000FFF0 -- and 0xFCC8FE is pushed alone to a routine that takes a float32.

  76 doubles + 2 four-byte elements = 616 bytes, and 48 of the 76 are exact integers
  (56, 16, 1100, 81, 550, 44100, 441, 2147483648, ...), which no wrong alignment produces.

★ THE POOL NAMES THE SAMPLE RATE.  44100 is in it, cited from EIGHTEEN sites, and so are
  1/44100, 1/220500 and 1/441000.  Its heaviest user is sub_F9BE3A (8,573 bytes, the whole
  double-precision library), whose header lists 64 of the pool's four-byte slots among its
  absolute reads.  ⚠ That routine has NO located caller: the one citation an image-wide scan
  produced for it, 0xF95B01, lies inside the preset bank's record 125 and is a data field,
  not a call (notes/prom_c_phantom_callsites.py).

WHAT IS NOT ESTABLISHED
  * what any constant is FOR.  The emitted comment gives the decoded value and nothing else.
  * the f32 reading of 0xFCC8FE rests on its ONE call site's argument shape, not on a
    declaration.

RUN
  python3 notes/gen_prom_c_fp_pool.py --verify
  python3 notes/gen_prom_c_fp_pool.py --emit
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prom_c_tail_census as CEN                                     # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = CEN.BASE
IMG = CEN.IMG
LO, HI = 0xFCC81A, 0xFCCA82


def u32(a):
    return int.from_bytes(IMG[a - BASE:a - BASE + 4], "little")


def f64(a):
    return struct.unpack("<d", IMG[a - BASE:a - BASE + 8])[0]


def f32(a):
    return struct.unpack("<f", IMG[a - BASE:a - BASE + 4])[0]


def elements():
    """(addr, kind, witnesses) for every element, derived from the citations."""
    hits, _ = CEN.census(LO, HI, exclude_inside=False)
    sites = {a: [s for s, _ in v] for a, v in hits.items()}
    out, a = [], LO
    while a < HI:
        hi_sites = set(sites.get(a + 4, []))
        lo_sites = set(sites.get(a, []))
        wit = sorted(s for s in hi_sites if s + 6 in lo_sites)
        if a + 8 <= HI and wit:
            out.append((a, "f64", wit))
            a += 8
        else:
            out.append((a, "u32", sorted(lo_sites)))
            a += 4
    return out, sites


def fmt(v):
    if v == int(v) and abs(v) < 1e17:
        return "%d" % int(v)
    return "%.10g" % v


def verify():
    bad = []

    def chk(c, m):
        print(("  ok   " if c else "  FAIL ") + m)
        if not c:
            bad.append(m)

    els, sites = elements()
    chk(sorted(sites) == [LO + 4 * i for i in range(154)],
        "154 cited addresses, 4-byte aligned and consecutive, 0x%06X-0x%06X" % (LO, HI - 1))
    n64 = sum(1 for e in els if e[1] == "f64")
    n32 = sum(1 for e in els if e[1] == "u32")
    chk(n64 == 76 and n32 == 2, "%d doubles + %d four-byte elements" % (n64, n32))
    chk(sum(8 if e[1] == "f64" else 4 for e in els) == HI - LO,
        "the elements tile the pool exactly: %d bytes" % (HI - LO))
    chk(all(e[2] for e in els), "every element has at least one citing site")
    chk(all(e[2] for e in els if e[1] == "f64"),
        "every double has at least one high-then-low witness six bytes apart")
    ints = [e for e in els if e[1] == "f64" and f64(e[0]) == int(f64(e[0]))]
    chk(len(ints) == 48, "%d of the %d doubles are exact integers" % (len(ints), n64))
    chk(u32(LO) == 0x0000FFF0, "the first element is the long 0x%08X, used as an address "
        "(`add XBC,(0x%06X)` at 0xF998AA)" % (u32(LO), LO))
    chk(abs(f32(0xFCC8FE) - 50.0 / 51.0) < 1e-7,
        "the other four-byte element is the float32 %.9g = 50/51" % f32(0xFCC8FE))
    vals = [f64(e[0]) for e in els if e[1] == "f64"]
    chk(44100.0 in vals and (1.0 / 44100.0) in vals,
        "44100 and 1/44100 are both in the pool")
    chk(els[-1][1] == "f64" and els[-1][0] == 0xFCCA7A and f64(0xFCCA7A) == 2147483648.0,
        "LAST element: 0x%06X, a double = %s -- and it ends on the pool's last byte"
        % (els[-1][0], fmt(f64(els[-1][0]))))
    print()
    if bad:
        print("%d CHECK(S) FAILED" % len(bad))
        return 1
    print("ALL CHECKS PASSED")
    return 0


def emit(out):
    els, sites = elements()
    L = out.append
    L("; " + "-" * 76)
    L("; fp_constant_pool_FCC81A -- 0xFCC81A-0xFCCA81  (616 bytes, 78 elements)")
    L(";")
    L("; Generated by notes/gen_prom_c_fp_pool.py --emit; --verify re-proves all of it.")
    L("; ⚠ THIS WAS LEFT AS A DELIBERATE `.incbin` UNTIL ROUND 3, because decoding it on a")
    L("; fixed 8-byte grid produced denormal garbage.  It is not on a fixed grid: TWO of its")
    L("; 78 elements are four bytes wide, at 0xFCC81A and 0xFCC8FE, and they shift every")
    L("; double after them by 4.  The element starts are not inferred -- all 154 four-byte")
    L("; slots are cited by literal-addressed loads, and a double is recognised by the")
    L("; instruction pair that pushes it HIGH HALF FIRST, six bytes apart:")
    L(";     F9C2DE  ld XBC,(0xFCC9EE) / push XBC     <- high")
    L(";     F9C2E4  ld XBC,(0xFCC9EA) / push XBC     <- low = the double's address")
    L("; 76 doubles + 2 longs = 616 bytes, and 48 of the 76 are exact integers.")
    L(";")
    L("; ★ 44100 IS IN HERE, cited from eighteen sites, with 1/44100, 1/220500 and 1/441000.")
    L("; The pool's heaviest user is sub_F9BE3A (8,573 bytes), which cites 64 of the 154 slots.")
    L("; ⚠ What any constant is FOR is NOT established; the comments give values only.")
    L("; ★ The KN5000 has a pool of the same kind (v142/subcpu/subcpu_data_tables.s:2695);")
    L("; its contents do NOT match, so the sibling could not have supplied the boundaries")
    L("; either -- prom_c's own load instructions did.")
    L("; " + "-" * 76)
    L("fp_constant_pool_FCC81A:")
    for addr, kind, wit in els:
        if kind == "f64":
            L("\t.long\t0x%08X, 0x%08X   ; 0x%06X  f64 %s"
              % (u32(addr), u32(addr + 4), addr, fmt(f64(addr))))
        else:
            L("\t.long\t0x%08X               ; 0x%06X  32-bit element: %s"
              % (u32(addr), addr,
                 "address 0x%08X" % u32(addr) if addr == LO else "f32 %.9g" % f32(addr)))


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    if "--emit" in sys.argv:
        buf = []
        emit(buf)
        print("\n".join(buf))
    else:
        print(__doc__)
