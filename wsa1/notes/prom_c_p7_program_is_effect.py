#!/usr/bin/env python3
"""Is the P7 unit's "PROGRAM 0..127" the DSP EFFECT NUMBER?  Two ROMs, one join.

WHAT QUESTION THIS ANSWERS
--------------------------
Two tables in two different EPROMs have been sitting a few centimetres apart
with an open question on each of them:

  prom_c 0xFDC551  PoolDir_RecordForUnitProgram -- 128 bytes.  The P7 unit
      block's byte +0 is a number 0..127 that this table turns into a
      PoolDir_Records index.  prom_c/p7/p7_module.s calls it a "PROGRAM" and
      says outright: "⚠ what a PROGRAM 0..127 sounds like" is not established.

  prom_b 0xF147AC  EffectNames_F147AC -- 128 x 16 ASCII effect names, 56 real
      and 72 spelled "   ----------   ".  Its own header says
      "Read by: NOTHING in prom_a or prom_b spells 0x00F147AC in a decodable
      operand" and "⚠ Unknown: that entry k is effect algorithm k."

THE JOIN, and it is a measurement, not a resemblance
----------------------------------------------------
Slot k of the NAME table carries a real name if and only if slot k of the
prom_c table maps to a record other than the catch-all -- 127 of 128 slots, the
single exception being slot 0, "  NO OPERATION  ", which is a real name that
correctly resolves to the catch-all because it has nothing to load.  And the 56
real names map to 56 DISTINCT records: a bijection, not a coincidence of counts.

That answers both open questions at once:

  * what indexes prom_b's name table lives in prom_c -- it is the P7 unit's
    program byte;
  * and a P7 "PROGRAM" is a DSP EFFECT NUMBER, whose name is already in this
    tree.  Program 1 is CHORUS, 5 is PHASER, 20 is ENSEMBLE.

⚠ WHAT THIS DOES **NOT** ESTABLISH
  * the part number of the chip on the other end of port P7.  Nothing in any
    WSA1 ROM names one.  "Three destinations and three uPD6383GF DSPs in the
    machine is consistent and is NOT proof" (prom_c/p7/p7_module.s).
  * what any individual P7Stream byte means.  This joins a NUMBER to a NAME; it
    does not decode a payload.

★ NO LABEL IS RENAMED BY THIS SCRIPT, and none was renamed by the pass that
  wrote it.  572 P7* labels is a bulk rename, and a bulk rename belongs in its
  own pass with its own byte gate, not bolted onto a source reorganisation.
  The recommended mapping is in notes/FINDINGS-prom_c-p7-is-dsp-effects.md.

RUN
---
  python3 notes/prom_c_p7_program_is_effect.py            the measurement
  python3 notes/prom_c_p7_program_is_effect.py --selftest invariants + the
                                                          NEGATIVE control
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PROM_C, BASE_C = "wsa1_prom_c.ic28", 0xF80000
PROM_B, BASE_B = "wsa1_prom_b.ic13", 0xF00000

# Both addresses are LABELS IN THE SOURCE, not offsets chosen here:
#   prom_c/p7/p7_stream_pool.s   PoolDir_RecordForUnitProgram -- 0xFDC551, 128 bytes
#   prom_b/wsa1_prom_b.s         EffectNames_F147AC           -- 0xF147AC, 128 x 16
PROGRAM_TABLE = 0xFDC551
NAME_TABLE = 0xF147AC
N = 128
NAME_LEN = 16
CATCH_ALL = 53          # the record 72 of the 128 programs share

# The directory the record index addresses, from p7_module.s's chain:
#   PoolDir_Records[idx]   `mul A,0x19 / add XWA,0x00FDBFD9`   (0xFA2B44)
# fields +0/+4/+8/+12 are four little-endian P7Stream pointers.
POOLDIR = 0xFDBFD9
POOLDIR_STRIDE = 0x19

# ★ THE CROSS-TREE CORROBORATION.  Four P7Stream objects are BYTE-IDENTICAL runs
# of NAMED objects in the KN5000 sub-CPU ROM, and the KN5000's own name carries
# the EFFECT NUMBER.  Every row below was re-found by searching the KN5000 image
# for the WSA1 bytes -- the offsets are not copied from a note.
#   (prom_c address, length, kn5000 v142 offset, kn5000 label, effect number)
KN5000_ROM = ("../kn5000-roms-disasm/original_ROMs/kn5000_subprogram_v142.rom")
KN5000_RUNS = [
    (0xFD7764, 164, 0x007316, "DSP_Eff05_Coef_Bytecode", 5),
    (0xFD0C4B,  95, 0x00A933, "DSP_Eff65_Param_Values", 65),
    (0xFD08CD,  49, 0x00A66C, "DSP_Eff64_Param_Values", 64),
    (0xFD1399,  49, 0x00B499, "DSP_Eff68_Param_Values", 68),
]


def rom(name):
    with open(os.path.join(ROOT, "original_ROMs", name), "rb") as fh:
        return fh.read()


def tables():
    c, b = rom(PROM_C), rom(PROM_B)
    off = PROGRAM_TABLE - BASE_C
    prog = list(c[off:off + N])
    off = NAME_TABLE - BASE_B
    names = [b[off + NAME_LEN * i: off + NAME_LEN * (i + 1)].decode("latin1")
             for i in range(N)]
    return prog, names


def le32(buf, base, addr):
    o = addr - base
    return int.from_bytes(buf[o:o + 4], "little")


def streams_for(c, record):
    """The four P7Stream pointers of PoolDir_Records[record]."""
    rec = POOLDIR + record * POOLDIR_STRIDE
    return [le32(c, BASE_C, rec + k) for k in (0, 4, 8, 12)]


def chain():
    """program -> name -> record -> stream -> the KN5000 object it IS.

    ★ This is the end-to-end join, and its strength is that the EFFECT NUMBER
      appears twice independently: once as the WSA1's program index, once inside
      the KN5000's own label for the identical bytes.
    """
    c = rom(PROM_C)
    prog, names = tables()
    out = []
    try:
        k = open(os.path.join(ROOT, KN5000_ROM), "rb").read()
    except OSError:
        k = None
    for addr, n, koff, klabel, eff in KN5000_RUNS:
        rec = prog[eff]
        ptrs = streams_for(c, rec)
        field = ptrs.index(addr) * 4 if addr in ptrs else None
        same = None
        if k is not None:
            same = c[addr - BASE_C:addr - BASE_C + n] == k[koff:koff + n]
        out.append((eff, names[eff].strip(), rec, field, addr, n, klabel, same))
    return out


def is_placeholder(name):
    """The name table's own 'this slot is empty' spelling, '   ----------   '."""
    return set(name.strip()) <= set("-")


def join(prog, names):
    """(agreeing slots, disagreeing slots)."""
    agree, bad = [], []
    for i in range(N):
        (agree if is_placeholder(names[i]) == (prog[i] == CATCH_ALL)
         else bad).append(i)
    return agree, bad


def report():
    prog, names = tables()
    assert len(prog) == N and len(names) == N
    real = [i for i in range(N) if not is_placeholder(names[i])]
    agree, bad = join(prog, names)
    print(f"  prom_c 0x{PROGRAM_TABLE:06X} PoolDir_RecordForUnitProgram   "
          f"{N} bytes, values {min(prog)}..{max(prog)}")
    print(f"  prom_b 0x{NAME_TABLE:06X} EffectNames_F147AC             "
          f"{N} x {NAME_LEN} ASCII, {len(real)} named, {N - len(real)} placeholder")
    print()
    print(f"  slots where 'has a real name' == 'maps to a record != {CATCH_ALL}':"
          f"  {len(agree)} of {N}")
    for i in bad:
        print(f"    exception  slot {i:3d}  name {names[i]!r}  record {prog[i]}")
    recs = {prog[i] for i in real}
    print(f"  distinct records the {len(real)} named programs map to: {len(recs)}"
          f"   ({'BIJECTION' if len(recs) == len(real) else 'NOT a bijection'})")
    ph = {prog[i] for i in range(N) if is_placeholder(names[i])}
    print(f"  records the {N - len(real)} placeholder programs map to:   {sorted(ph)}")
    print()
    print("  a few programs, by number:")
    for i in (1, 5, 6, 20, 50, 64, 99):
        print(f"    program {i:3d} -> record {prog[i]:3d}   {names[i]!r}")
    print()
    print("  ★ END TO END -- program -> name -> record -> stream -> KN5000 object:")
    for eff, nm, rec, field, addr, n, klabel, same in chain():
        f = f"+{field:2d}" if field is not None else " ?? "
        v = {True: "BYTE-IDENTICAL", False: "DIFFERS", None: "(KN5000 ROM absent)"}[same]
        print(f"    program {eff:3d} {nm:18s} record {rec:3d} field {f} -> "
              f"0x{addr:06X} ({n:3d} B)  {v} to {klabel}")
    return 0


def selftest():
    """INVARIANTS plus the NEGATIVE control.

    ⚠ The point of the negative control: 'the two tables agree' is only evidence
    if DISAGREEMENT WAS POSSIBLE.  Rotating one table by one slot must destroy
    the agreement; if it does not, the join is measuring the shape of the tables
    rather than their contents and proves nothing.
    """
    ok = True
    prog, names = tables()

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    check(len(prog) == N, f"the program table is {N} bytes")
    check(len(names) == N and all(len(n) == NAME_LEN for n in names),
          f"the name table is {N} rows of {NAME_LEN} characters")
    check(all(0 <= v < 64 for v in prog),
          "every program resolves to a plausible record index")
    check(all(all(32 <= ord(ch) < 127 for ch in n) for n in names),
          "every name row is printable ASCII")

    agree, bad = join(prog, names)
    check(len(agree) + len(bad) == N, "the join classifies every slot exactly once")
    check(len(bad) <= 1, "at most one slot disagrees")
    check(all(not is_placeholder(names[i]) for i in bad),
          "any disagreement is a NAMED program on the catch-all, never the reverse")

    # ★ THE NEGATIVE CONTROL, over every non-zero rotation.
    worst = min(len(join(prog, names[k:] + names[:k])[1]) for k in range(1, N))
    check(worst > len(bad),
          f"every one of the {N - 1} misalignments disagrees more than the true "
          f"alignment ({worst} vs {len(bad)}) -- the join CAN fail")

    rows = chain()
    check(all(r[3] is not None for r in rows),
          "every corroborating stream IS one of its program's four pool pointers")
    if all(r[7] is None for r in rows):
        print("  skip  the KN5000 sub-CPU ROM is not present; byte identity unchecked")
    else:
        check(all(r[7] for r in rows),
              "every corroborating stream is byte-identical to the KN5000 object")
        # ⚠ NEGATIVE CONTROL for the identity: the SAME length taken one byte
        # earlier must NOT match, or "identical" is measuring a run of padding.
        c, k = rom(PROM_C), open(os.path.join(ROOT, KN5000_ROM), "rb").read()
        shifted = [c[a - BASE_C - 1:a - BASE_C - 1 + n] == k[o:o + n]
                   for a, n, o, _l, _e in KN5000_RUNS]
        check(not any(shifted),
              "the same runs shifted by one byte do NOT match -- not padding")

    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else report())
