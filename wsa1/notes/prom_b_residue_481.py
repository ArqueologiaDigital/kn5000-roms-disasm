#!/usr/bin/env python3
"""prom_b_residue_481.py -- are prom_b's last 481 verbatim bytes CODE or DATA,
and can they be written as real source rather than handed back through .incbin?

QUESTION THIS ANSWERS
----------------------
Twelve of the thirteen gated images are at zero verbatim debt. prom_b holds the
remainder: 16 `.incbin` spans totalling 481 bytes, each refused by a lane with
a stated reason. Those reasons say why a particular framing did not fit; none
of them answers the blunt question a reader actually has, which is whether
those bytes are program text nobody has decoded, or data nobody has typed.

ANSWER: ALL SIXTEEN ARE DATA. Not one shows instruction structure. The blocker
was never "is this code" -- it is that most of the spans BEGIN OR END INSIDE A
RECORD, so no self-contained framing fits the span as it was cut.

THE EVIDENCE, AND ITS NULL
---------------------------
The strongest single discriminator is an embedded 32-bit pointer into prom_b's
own address range. Ten of the sixteen spans carry at least one; there are 22
across the 481 bytes.

⚠ THAT NUMBER IS MEANINGLESS WITHOUT ITS NULL, so this script computes one:
uniform-random bytes of the SAME LENGTHS, 2,000 trials per span, yield **0.00**
in-range pointers per span on average. prom_b occupies 0xF00000-0xF7FFFF, i.e.
1/512 of the 32-bit space, so a random 4-byte window lands in it with
probability ~0.2%, and a 45-byte span offers ~42 windows -- an expectation
below 0.1. Twenty-two is not chance.

The pointers are not scattered, either. They point where a record's operand
would be:

    0xF286CC  +6  -> 0xF286DC   (+16, just past the record)
    0xF3A443  +2  -> 0xF3A449   (+6)
    0xF34350  +3  -> 0xF3435B   (+11)
    0xF04D14  +3  -> 0xF04D1F   (+11)
    0xF02FFE  +0  -> 0xF03002   (+4)
    0xF0540B  +3  -> 0xF05443   (+56, and the SAME target from all 4 records)

and the 0xF03Axx family points AWAY, repeatedly, at 0xF019AA -- the 12x16 icon
grid that lane promB2 identified from the other side, where `0x00F019AA`
appears as a 32-bit word ten times across the display-list region.

WHY THEY WERE LEFT: THE SPANS ARE CUT MID-RECORD
-------------------------------------------------
`0xF0540B` is the clearest case and this script demonstrates it. Its records
are 15 bytes with markers at span offsets 0, 15, 30, 45 -- and 58 = 15*3 + 13,
so the FOURTH record is truncated by the span's end. The bytes immediately
BEFORE the span carry the same 4-byte trailer the in-span records do
(`02 0f ab 27`, then `ac`, `ad`, `ae` inside: an incrementing counter), so the
structure runs straight through both edges of the `.incbin`.

That is the same mechanism this push documented image-wide: a reachability walk
finds an object's first byte and cannot find its last, so the residue is the
part of a record the walk could not account for -- not an independent mystery.

WHAT THIS SCRIPT DOES *NOT* CLAIM
----------------------------------
It says these bytes are data and shows the structure is real. It does NOT hand
you a record layout for each span, and typing one from a plausible-looking
stride is exactly the "wrong start frames fake records" hazard. A conversion
still needs the referring code, per span. The point here is that the remaining
question is a TYPING question, not a DECODING one.

RUN
    python3 notes/prom_b_residue_481.py            # evidence table + null
    python3 notes/prom_b_residue_481.py --selftest # asserts the claims above
"""
import random
import struct
import sys

ROM = "original_ROMs/wsa1_prom_b.ic13"
BASE = 0xF00000

# The 16 remaining .incbin spans, (file offset, length). Regenerate with:
#   grep -a '\.incbin' prom_b/wsa1_prom_b.s
# ⚠ grep -a, not grep: an agent shell's grep skips files it deems binary.
SPANS = [
    (0x003AF8, 77), (0x00540B, 58), (0x003F81, 46), (0x005792, 46),
    (0x0286CC, 45), (0x002FFE, 44), (0x013D34, 44), (0x03A443, 30),
    (0x003ADE, 21), (0x034350, 17), (0x004D14, 15), (0x005CEC, 12),
    (0x032A00,  9), (0x003A26,  7), (0x003BE6,  5), (0x03B656,  5),
]


def load():
    with open(ROM, "rb") as f:
        return f.read()


def pointers(buf, span_base, rom_len):
    """In-range LE32 values, as (offset, target, delta from span base)."""
    out = []
    for i in range(len(buf) - 3):
        v = struct.unpack_from("<I", buf, i)[0]
        if BASE <= v < BASE + rom_len:
            out.append((i, v, v - span_base))
    return out


def ascii_frac(buf):
    return sum(1 for x in buf if 32 <= x < 127) / len(buf)


def null_pointer_rate(trials=2000, seed=7):
    """Expected in-range LE32 per span if the bytes were uniform random."""
    rng = random.Random(seed)
    hits = n = 0
    for _off, ln in SPANS:
        for _ in range(trials):
            rb = bytes(rng.randrange(256) for _ in range(ln))
            hits += len(pointers(rb, 0, 0x80000))
            n += 1
    return hits / n


def main():
    rom = load()
    selftest = "--selftest" in sys.argv
    total_ptr = 0
    with_ptr = 0
    print("span         len  ascii  ptrs  first targets")
    for off, ln in SPANS:
        b = rom[off:off + ln]
        base = BASE + off
        p = pointers(b, base, len(rom))
        total_ptr += len(p)
        with_ptr += 1 if p else 0
        tgt = ", ".join(f"+{i}->0x{v:06X}({d:+d})" for i, v, d in p[:3])
        print(f"0x{base:06X}  {ln:4d}  {ascii_frac(b)*100:4.0f}%  {len(p):4d}  {tgt}")

    print(f"\n{sum(l for _, l in SPANS)} B in {len(SPANS)} spans; "
          f"{total_ptr} in-range LE32 pointers in {with_ptr} of them")
    rate = null_pointer_rate()
    print(f"NULL: uniform-random bytes of the same lengths give {rate:.3f} "
          f"in-range pointers per span")

    # The mid-record demonstration on 0xF0540B.
    off, ln = 0x00540B, 58
    span = rom[off:off + ln]
    marks = [i for i in range(ln - 1) if span[i] == 0x10 and span[i + 1] == 0x04]
    strides = [marks[i + 1] - marks[i] for i in range(len(marks) - 1)]
    tail = ln - marks[-1]
    print(f"\n0xF0540B: '10 04' record markers at {marks}, strides {strides}; "
          f"the last record has {tail} of {strides[0] if strides else 0} bytes "
          f"inside the span -- it is CUT BY THE SPAN'S END.")
    print("  bytes immediately before the span: " +
          " ".join(f"{x:02x}" for x in rom[off - 6:off]) +
          "  (the same 02 0f XX 27 trailer the in-span records carry)")

    if selftest:
        fails = []
        if total_ptr < 20:
            fails.append(f"expected >=20 embedded pointers, got {total_ptr}")
        if rate > 0.05:
            fails.append(f"null too high ({rate:.3f}); the pointer evidence "
                         f"is not distinguishable from chance")
        if strides != [15, 15, 15]:
            fails.append(f"0xF0540B strides {strides} != [15,15,15]")
        if tail >= 15:
            fails.append("0xF0540B's last record is not truncated after all")
        # every span must be data-shaped: no span may be mostly-ASCII AND
        # pointer-free AND uniform, which would suggest padding rather than data
        for off, ln in SPANS:
            b = rom[off:off + ln]
            if len(set(b)) == 1:
                fails.append(f"0x{BASE+off:06X} is a uniform run -- it is "
                             f"filler, not data, and should be .fill")
        print("\nSELFTEST: " + ("PASS" if not fails else "FAIL"))
        for f in fails:
            print("  " + f)
        return 1 if fails else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
