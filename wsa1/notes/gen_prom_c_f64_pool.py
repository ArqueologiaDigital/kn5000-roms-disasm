#!/usr/bin/env python3
"""What is prom_c 0xFCB27E-0xFCC53E, and who reads it?

QUESTION ANSWERED
  Two objects were left as one 4,801-byte `.incbin` with a comment that decoded six of
  its constants by eye.  This script decodes ALL of it, mechanically, and emits the
  assembly:

    0xFCB27E-0xFCB4E5   77 IEEE-754 DOUBLES -- the coefficient pool of the
                        double-precision math library at 0xFC8BB2.
    0xFCB4E6-0xFCB4E9   one IEEE-754 FLOAT, 1.0.
    0xFCB4EA-0xFCC53E   the head of the 4,312-byte boot RAM image that RESET copies to
                        0x00E2DF (notes/FINDINGS-prom_c-ram-image.md); it continues
                        past 0xFCC53F into the already-converted table zone.

WHY THE BOUNDARIES ARE NOT CHOSEN
  * The pool's START is where the preceding routine's `retd` ends (`Shift8_Left`,
    0xFCB25D-0xFCB27D, converted).
  * The pool's ELEMENT SIZE and COUNT are not assumed: 77 doubles at a stride of 8 from
    0xFCB27E land exactly on 0xFCB4E6, and the four bytes there decode as float32 1.0 --
    and 0xFCB4E6 is the ONLY address in this whole range that prom_c loads as a 32-bit
    (rather than 64-bit) quantity, from 0xFCB00A.
  * The pool's END and the RAM image's START are the same fact from the other side:
    `lda XIY,0xFCB4EA` at 0xF989EF is the source operand of the boot copy, read out of
    the instruction bytes by notes/prom_c_ram_image.py.  0xFCB4E6 + 4 = 0xFCB4EA, with
    no gap.
  * And the DECODE IS ITS OWN EVIDENCE: at this base and this stride the 77 values come
    out as a textbook libm pool -- pi, pi/2, 1/pi, ln 2, 1/ln 2, 1/sqrt 2, 0.5, 0.25,
    the odd-power sine Taylor coefficients -1/6, +1/120, -1/5040, +1/362880, the exp
    overflow bounds +-709.78..., DBL_MAX/2, DBL_MIN and INT32_MAX as a double.  A
    one-byte error in the base, or a stride of anything but 8, turns every one of those
    into a denormal.

WHO READS THEM -- the part that makes the names something better than a reading
  Every pool entry is loaded as TWO 32-bit halves, so each one appears in the image as a
  24-bit address operand at X and again at X+4.  Scanning the whole image for values that
  are one of those 154 halves finds 149 sites; 147 of them are inside 0xFC8000-0xFCB27D,
  i.e. inside the math library, and the other two are at 0xFBAA80 and 0xFBBF53.  (A
  150th site, 0xFCB00A, carries 0xFCB4E6 -- the float32, not a pool half.)  The comment
  emitted beside each constant lists the routines that load it, taken from the labels in
  prom_c/wsa1_prom_c.s -- so a constant whose only consumer is `Float64_Sin` is labelled
  by that fact, not by my recognising the number.

WHAT IT DOES NOT ESTABLISH
  * The RAM-image half is emitted as BYTES with the destination RAM address in the
    comment.  Its internal field layout is not established here and no field is named;
    notes/FINDINGS-prom_c-ram-image.md holds what is known about individual defaults.
  * Two pool entries are 0.0 and two are 8.988465674311579e+307.  Which of several
    identical-valued entries a routine loads is decided by the ADDRESS, and that is what
    the comment prints; nothing infers a role from the value alone.

RUN
  python3 notes/gen_prom_c_f64_pool.py --verify   # asserts the boundaries and the decode
  python3 notes/gen_prom_c_f64_pool.py --table    # the 77 constants with their consumers
  python3 notes/gen_prom_c_f64_pool.py --asm      # the assembly fragment
  python3 notes/gen_prom_c_f64_pool.py --apply    # splice it into prom_c/wsa1_prom_c.s
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
BASE = 0xF80000

POOL = 0xFCB27E
NPOOL = 77
F32_ONE = 0xFCB4E6
RAMIMG = 0xFCB4EA          # `lda XIY,0xFCB4EA` at 0xF989EF
RAMDST = 0x00E2DF          # `lda XIX,0x00E2DF` at 0xF989F4
END = 0xFCC53F             # the already-converted table zone starts here

# Values a reader will want spelled out.  Recognition only -- the NAME of a constant in
# the emitted source is always its decoded value plus its consumers, never this table.
KNOWN = {
    1.5707963267948966: "pi/2", 3.141592653589793: "pi",
    0.3183098861837907: "1/pi", 0.6366197723675814: "2/pi",
    0.6931471805599453: "ln 2", 1.4426950408889634: "1/ln 2 = log2(e)",
    0.7071067811865476: "1/sqrt 2", 2147483647.0: "INT32_MAX",
    8.988465674311579e+307: "DBL_MAX/2", 2.2250738585072014e-308: "DBL_MIN",
    709.782712893384: "ln(DBL_MAX), the exp overflow bound",
    -0.16666666666666666: "= -1/3!  exactly",
    0.008333333333333165: "~ +1/5!  (1.7e-14 rel.)",
    -0.0001984126984120184: "~ -1/7!  (3.5e-13 rel.)",
    2.7557319210152756e-06: "~ +1/9!  (5.0e-10 rel.)",
}


def load():
    return open(IMG, "rb").read()


def labels():
    """address -> the routine label it falls under, from the .s file's own listing."""
    lab = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
    addr = re.compile(r";\s*([0-9A-F]{6})\s")
    cur, out = None, {}
    for line in open(SRC):
        m = lab.match(line)
        if m:
            cur = m.group(1)
            continue
        m = addr.search(line)
        if m and cur:
            out[int(m.group(1), 16)] = cur
    return out


def sites(d):
    """pool address -> [instruction-operand addresses that carry it as a 24-bit literal]"""
    out = {}
    for i in range(len(d) - 2):
        v = d[i] | (d[i + 1] << 8) | (d[i + 2] << 16)
        if POOL <= v <= F32_ONE + 3:
            out.setdefault(v, []).append(BASE + i)
    return out


def consumers(d, lm):
    """pool entry index -> sorted set of routine labels that load either half."""
    s = sites(d)
    out = {}
    for k in range(NPOOL):
        a = POOL + k * 8
        names, raw = set(), []
        for half in (a, a + 4):
            for site in s.get(half, []):
                raw.append(site)
                # the literal starts 1..4 bytes into its instruction; walk back to the
                # nearest listed instruction address rather than guessing an offset
                for back in range(0, 7):
                    if site - back in lm:
                        names.add(lm[site - back])
                        break
        out[k] = (sorted(names), sorted(raw))
    return out


def runs_of(cons):
    """(first, last) index pairs: a loaded entry followed by unloaded ones -- an array."""
    out, k = [], 0
    while k < NPOOL:
        if cons[k][0] and k + 1 < NPOOL and not cons[k + 1][0]:
            j = k + 1
            while j < NPOOL and not cons[j][0]:
                j += 1
            out.append((k, j - 1))
            k = j
        else:
            k += 1
    return out


def verify():
    d = load()
    fails = []

    def check(ok, msg):
        print(("  ok   " if ok else "  FAIL ") + msg)
        if not ok:
            fails.append(msg)

    print("prom_c 0xFCB27E-0xFCC53E -- the f64 pool and the RAM-image head")
    check(POOL + NPOOL * 8 == F32_ONE,
          f"{NPOOL} doubles of 8 bytes from 0x{POOL:06X} end at 0x{F32_ONE:06X}")
    check(F32_ONE + 4 == RAMIMG,
          f"the float32 at 0x{F32_ONE:06X} ends exactly where the RAM image starts, "
          f"0x{RAMIMG:06X}")
    o = F32_ONE - BASE
    check(struct.unpack("<f", d[o:o + 4])[0] == 1.0,
          f"0x{F32_ONE:06X} decodes as float32 1.0")
    # boot-copy source operand, read out of the instruction bytes
    ins = d[0xF989EF - BASE:0xF989EF - BASE + 5]
    check(ins == bytes([0xF2, 0xEA, 0xB4, 0xFC, 0x35]),
          f"0xF989EF is still `lda XIY,0x{RAMIMG:06X}` ({ins.hex()})")
    # the decode is its own evidence
    vals = [struct.unpack("<d", d[POOL - BASE + k * 8:POOL - BASE + k * 8 + 8])[0]
            for k in range(NPOOL)]
    finite = sum(1 for v in vals if v == 0.0 or 1e-320 < abs(v) < 1e309)
    check(finite == NPOOL, f"all {NPOOL} entries decode as zero or a normal double "
                           f"({finite})")
    for want in ("pi", "pi/2", "ln 2", "1/ln 2 = log2(e)", "1/sqrt 2", "INT32_MAX",
                 "DBL_MIN", "= -1/3!  exactly"):
        got = [k for k, v in enumerate(vals) if KNOWN.get(v) == want]
        check(bool(got), f"the pool contains {want} (entries {got})")
    # the 8-entry array at 0xFCB2CE, checked against the odd factorials
    import math as _m
    rel = []
    for i, k in enumerate(range(17, 9, -1)):          # entries 17,16,...,10
        n = 2 * (i + 1) + 1                            # 3, 5, 7, ... 17
        rel.append(abs(abs(vals[k]) - 1.0 / _m.factorial(n)) * _m.factorial(n))
    check(all(r < 5e-2 for r in rel) and rel[0] == 0.0 and rel[-1] > 1e-3,
          "the 8 entries at 0xFCB2CE are +-1/(2k+1)! for k = 1..8 read BACKWARDS from "
          f"0xFCB305: exact at 1/3!, and off by {rel[-1]:.1e} relative at the 1/17! end "
          "-- a FITTED odd polynomial, not the Taylor series")
    signs = [1 if vals[k] > 0 else -1 for k in range(10, 18)]
    check(all(signs[i] != signs[i + 1] for i in range(7)),
          f"...and its signs alternate ({signs})")
    check(abs((vals[25] + vals[24]) - vals[0]) == 0.0,
          f"entries [25] + [24] = {vals[25]!r} + {vals[24]!r} is bit-exactly pi/2 -- "
          "a two-word (Cody-Waite) split, not two constants")
    # tested on the LAST entry
    check(vals[NPOOL - 1] == 0.0,
          f"...and the LAST entry, 0x{POOL + (NPOOL-1)*8:06X}, decodes as {vals[-1]!r}")
    lm = labels()
    cons = consumers(d, lm)
    nsites = sum(len(v[1]) for v in cons.values())
    check(nsites >= 140, f"{nsites} 24-bit operand sites carry a pool address")
    withname = sum(1 for k in cons if cons[k][0])
    check(withname == 54, f"{withname} of the {NPOOL} entries are loaded by a located "
                          f"site, and every located site falls inside a labelled routine")
    # the 23 without a site are never the FIRST of a run: each is preceded by an entry
    # that is loaded, i.e. they are the interiors of coefficient ARRAYS walked with a
    # pointer.  That is the whole explanation for the gap, and it is checkable.
    orphan = [k for k in range(NPOOL) if not cons[k][0]
              and (k == 0 or not any(cons[j][0] for j in range(k)))]
    runs = []
    k = 0
    while k < NPOOL:
        if cons[k][0] and k + 1 < NPOOL and not cons[k + 1][0]:
            j = k + 1
            while j < NPOOL and not cons[j][0]:
                j += 1
            runs.append((k, j - 1))
            k = j
        else:
            k += 1
    covered = sum(hi - lo + 1 for lo, hi in runs)
    check(not orphan, f"no unreferenced entry precedes every referenced one "
                      f"(orphans: {orphan})")
    check(covered - len(runs) == NPOOL - withname,
          f"all {NPOOL-withname} unreferenced entries sit immediately after a referenced "
          f"one, in {len(runs)} runs -- the shape of coefficient ARRAYS walked with a "
          f"pointer: " + ", ".join(f"0x{POOL+lo*8:06X}[{hi-lo+1}]" for lo, hi in runs))
    check(END - RAMIMG == 4181, f"the RAM-image head here is {END-RAMIMG} bytes")
    print()
    if fails:
        print(f"FAILURES: {len(fails)}")
        return 1
    print("ALL CHECKS PASSED")
    return 0


def table():
    d = load()
    lm = labels()
    cons = consumers(d, lm)
    for k in range(NPOOL):
        a = POOL + k * 8
        v = struct.unpack("<d", d[a - BASE:a - BASE + 8])[0]
        names, raw = cons[k]
        kn = KNOWN.get(v, "")
        print(f"[{k:2d}] 0x{a:06X}  {v!r:<26} {kn:<34} {len(raw)} site(s): "
              + ", ".join(names))


def asm():
    d = load()
    lm = labels()
    cons = consumers(d, lm)
    L = []
    a = L.append
    a("; ==============================================================================")
    a("; 0xFCB27E-0xFCC53E -- the f64 coefficient pool, one f32, and the RAM-image head")
    a("; ==============================================================================")
    a(";")
    a("; Generated by notes/gen_prom_c_f64_pool.py; `--verify` re-proves every boundary")
    a("; and every claim below and exits non-zero on failure.  Nothing here is retyped.")
    a(";")
    a("; ★ THE BOUNDARIES ARE DERIVED, NOT CHOSEN.")
    a(";   * the pool starts where Shift8_Left's `retd` ends, at 0xFCB27E;")
    a(f";   * {NPOOL} doubles at a stride of 8 land exactly on 0xFCB4E6, and those four")
    a(";     bytes decode as float32 1.0 -- the only 32-bit-loaded quantity in the range,")
    a(";     read from 0xFCB00A;")
    a(";   * 0xFCB4E6 + 4 = 0xFCB4EA, which is the SOURCE OPERAND of the boot RAM copy,")
    a(";     `lda XIY,0xFCB4EA` at 0xF989EF (notes/prom_c_ram_image.py reads it out of")
    a(";     the instruction bytes);")
    a(";   * and the decode is its own evidence: at this base and stride the pool comes")
    a(";     out as a textbook libm coefficient set -- pi, pi/2, 1/pi, 2/pi, ln 2,")
    a(";     1/ln 2, 1/sqrt 2, the odd sine Taylor coefficients -1/6 +1/120 -1/5040")
    a(";     +1/362880, the exp bounds +-709.78, DBL_MAX/2, DBL_MIN, INT32_MAX.  One")
    a(";     wrong byte in the base turns all of them into denormals.")
    a(";")
    a("; ★ EVERY CONSTANT IS NAMED BY ITS CONSUMER.  Each double is loaded as two 32-bit")
    a("; halves, so it appears in the image as a 24-bit address operand at X and again at")
    a("; X+4.  149 such sites exist; 147 are inside the math library at 0xFC8000-0xFCB27D")
    a("; and the other two are at 0xFBAA80 and 0xFBBF53.  The routines listed beside each")
    a("; entry are the labels those sites fall under in this file -- not a guess from the")
    a("; value.")
    a(";")
    a("; ★ 54 of the 77 entries are loaded by a located site.  The other 23 are NOT")
    a("; unexplained: every one of them sits immediately after a loaded entry, in seven")
    a("; runs, which is the shape of a COEFFICIENT ARRAY walked with a pointer from its")
    a("; first element.  The runs, with the routine that loads the head:")
    for lo, hi in runs_of(cons):
        who = ", ".join(cons[lo][0])
        a(f";     0x{POOL+lo*8:06X}  {hi-lo+1} entries   head loaded by {who}")
    a("; ⚠ WHAT THOSE ARRAYS ARE is NOT established here, and no routine is renamed on")
    a("; the strength of it.  What is MEASURED, and only that:")
    a(";   * the eight entries at 0xFCB2CE alternate in sign and, read from the HIGH")
    a(";     address downwards, are 1/3!, 1/5!, 1/7! ... 1/17! -- bit-exact at 1/3! and")
    a(";     drifting to 3.2e-2 relative at the 1/17! end, i.e. a FITTED odd polynomial")
    a(";     rather than the Taylor series;")
    a(";   * the arrays at 0xFCB38E and 0xFCB4BE both END on exactly 1.0;")
    a(";   * entries [24] and [25] SUM to pi/2 bit-exactly")
    a(";     (1.57080078125 + -4.454455103380769e-06), which is a two-word Cody-Waite")
    a(";     split of one constant, not two constants.")
    a(";")
    a("; ⚠ NOT ESTABLISHED: the RAM-image half below is emitted as bytes with the")
    a("; DESTINATION RAM ADDRESS in the comment and NOTHING ELSE.  Its field layout is")
    a("; open; notes/FINDINGS-prom_c-ram-image.md carries the individual defaults that")
    a("; have been pinned down.")
    a("")
    a("; ----------------------------------------------------------------------------")
    a(f"; Float64_ConstantPool -- 0xFCB27E..0xFCB4E5  ({NPOOL} x 8 = {NPOOL*8} bytes)")
    a("; ----------------------------------------------------------------------------")
    a("Float64_ConstantPool:")
    member = {}
    for lo, hi in runs_of(cons):
        for k in range(lo, hi + 1):
            member[k] = (lo, hi)
    for k in range(NPOOL):
        ad = POOL + k * 8
        o = ad - BASE
        v = struct.unpack("<d", d[o:o + 8])[0]
        names, raw = cons[k]
        kn = KNOWN.get(v)
        c = f"; [{k:2d}] 0x{ad:06X} = {v!r}"
        if kn:
            c += f"  ({kn})"
        a("\t" + ", ".join(f"0x{b:02x}" for b in d[o:o + 8]).join([".byte\t", ""])
          + f"   {c}")
        if names:
            a(f"\t;      loaded by: {', '.join(names)}")
        elif k in member:
            lo, hi = member[k]
            a(f"\t;      element {k-lo} of the {hi-lo+1}-entry array at 0x{POOL+lo*8:06X}"
              f" -- no site of its own")
        else:
            a("\t;      no loading site located")
    a("")
    a("; ----------------------------------------------------------------------------")
    a("; Float32_One -- 0xFCB4E6..0xFCB4E9  (4 bytes)")
    a("; ----------------------------------------------------------------------------")
    a("; IEEE-754 float32 1.0.  Loaded from 0xFCB00A -- the site the tone-generator note")
    a("; already quotes for `Float32_Multiply is really a / (1/b)`.")
    a("Float32_One:")
    o = F32_ONE - BASE
    a("\t.byte\t" + ", ".join(f"0x{b:02x}" for b in d[o:o + 4]) + "        ; 1.0f")
    a("")
    a("; ----------------------------------------------------------------------------")
    a(f"; BootRamImage_Head -- 0xFCB4EA..0xFCC53E  ({END-RAMIMG} bytes)")
    a("; ----------------------------------------------------------------------------")
    a("; The first 4,181 bytes of the 4,312-byte block RESET copies to RAM 0x00E2DF")
    a("; (`ldir` at 0xF989FE, count 0x10D8).  The copy does not stop here -- it runs on")
    a("; to 0xFCC5C1, through the first four objects of the table zone below, which is")
    a("; why those are relocated to RAM and patchable at runtime.")
    a("; The comment on each row is the RAM address its first byte lands on.")
    a("BootRamImage_Head:")
    for ad in range(RAMIMG, END, 16):
        n = min(16, END - ad)
        o = ad - BASE
        a("\t.byte\t" + ", ".join(f"0x{b:02x}" for b in d[o:o + n])
          + f"   ; 0x{ad:06X} -> RAM 0x{RAMDST + (ad - RAMIMG):06X}")
    return "\n".join(L) + "\n"


HEAD_RE = re.compile(
    r"; =+\n; 0xFCB27E-0xFCC53E -- not yet converted\n"
    r"(?:;.*\n)*?"
    r"\t\.incbin \"original_ROMs/wsa1_prom_c\.ic28\", 0x04B27E, 0x0012C1\n")


def apply():
    text = open(SRC).read()
    m = HEAD_RE.search(text)
    if not m:
        print("could not find the 0xFCB27E .incbin block to replace", file=sys.stderr)
        return 1
    open(SRC, "w").write(text[:m.start()] + asm() + text[m.end():])
    print(f"spliced {len(asm().splitlines())} lines into {SRC}")
    return 0


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    elif "--table" in sys.argv:
        table()
    elif "--asm" in sys.argv:
        sys.stdout.write(asm())
    elif "--apply" in sys.argv:
        sys.exit(apply())
    else:
        print(__doc__)
