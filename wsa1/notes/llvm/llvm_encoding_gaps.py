#!/usr/bin/env python3
"""What must still be fixed in llvm-mc so the disassembly can drop its macros.

QUESTION IT ANSWERS: `wsa1/include/tlcs900_mem_ops.inc` defines 122 macros with
12,539 call sites, all of them working around llvm-mc.  Which of those are real
assembler gaps, which are already native, and which are WORSE than a gap because
llvm-mc accepts the syntax and emits different bytes?

RUN:  python3 wsa1/notes/llvm/llvm_encoding_gaps.py            # the classes
      python3 wsa1/notes/llvm/llvm_encoding_gaps.py --selftest

★ THIS FILE IS A WORK LIST AND IT CHANGES AS WORK LANDS.  Its selftest used to
assert the DEFECTS, so that it went red the day they were fixed.  On 2026-09-01
they were fixed -- llvm tlcs900_backend e7a43c67fdca and f29a4827693f -- and the
FIXED cases moved here from their defect class into class F below, where the
selftest now asserts the CORRECT bytes against ROM truth.  Anything still broken
stays in class B/C/D, where the selftest asserts the defect.

  ★★ HOW A FIXED CASE IS PROVEN.  Not by "llvm-mc accepted it" -- that is
  exactly the trap class C was.  Every expected byte string in class F is the
  encoding the macro emits, i.e. the encoding in the physical ROM.  The
  companion tool assembles BOTH spellings of all 12,539 real call sites and
  compares them:

      python3 wsa1/notes/llvm/llvm_native_equivalence.py

★★ CLASS C IS NOW EMPTY, and the selftest asserts that.  Two forms moved out
   of it into class R -- refused rather than encodable, which is the outcome
   the brief asked for when an encoding is not available:

     push 0x1234      was 09 34, the immediate truncated to eight bits
     ld wa,(xix+iz)   was d3 f1 00 00 20 -- the REGISTER-INDEXED operand read
                      as (xix+d16) with the index register swallowed as an
                      undefined symbol named `iz`.  The ROM has d3 07 f0 f8 20.
                      It only failed later, at link time, and only because
                      nothing happened to define a symbol called `iz`.

   The register-indexed operand is the biggest thing still missing: 1,761 of
   the 12,539 call sites (the mx_* macros) use it.  Run
   `llvm_native_equivalence.py --classes` for the full split.

WHAT WAS FIXED (2026-09-01)
  * class C, the silent miscompiles.  `push (0x1234)` assembled to `09 34` --
    the address truncated to eight bits with no diagnostic -- because `push`
    had no memory form, so the parenthesised address was read as an immediate.
    `mul WA,(0x1234)` was the same defect wearing the "already native" label:
    it emitted `d8 08 34 12`, a multiply by the ADDRESS.  Both now encode a
    memory operand.
  * class D, the too-wide form.  A direct memory operand was always emitted as
    the 24-bit prefix.  The width is now requested in the source, `(0x2075:16)`,
    because it CANNOT be derived from the address value: firmware really does
    write `set 7,(0x00008a)` as F2 8A 00 00 BF.  No suffix = the old 24-bit
    default, so nothing that already assembled changed.
  * one case the brief had mis-spelled: `mul BC,(XIZ+0x08)` was listed as a
    register-indexed operand that llvm-mc rejected.  Its ROM bytes, 8e 08 43,
    are a register-plus-DISPLACEMENT operand at BYTE size, so the register is
    C and not BC -- and the addressing mode was never the problem; MUL simply
    had no memory form at all.  `mul c,(xiz+0x08)` now emits 8e 08 43.
  * class B, the rejected forms.  Byte and word direct memory operands were
    refused with "ISel should have materialized the address first".  That was a
    restriction aimed at the compiler path and the assembler had no reason to
    inherit it; C0/C1/C2 and D0/D1/D2 are valid prefixes and now encode.
"""
import os, subprocess, sys, tempfile

LLVM = "/home/fsanches/compartilhado/llvm-project/build/bin"
MC, OBJCOPY = os.path.join(LLVM, "llvm-mc"), os.path.join(LLVM, "llvm-objcopy")
INC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "include")

# (class, source, expected-bytes-or-None, note).  Expected bytes are ROM truth:
# they are what tlcs900_mem_ops.inc emits for the same instruction.
CASES = [
    # --- class F: FIXED, and the bytes below are the ROM's ---------------
    ("F", "bit 1,(0x2075:16)",   "f17520c9",   "was f2 (24-bit); ROM uses f1"),
    ("F", "set 7,(0x8a:24)",     "f28a0000bf", "the wide form for a small address"),
    ("F", "set 3,(0x1234:16)",   "f13412bb",   "narrow form now reachable"),
    ("F", "push (0x1234:16)",    "c1341204",   "was 09 34 -- address truncated"),
    ("F", "pushw (0x1234:16)",   "d1341204",   "the word-size memory push"),
    ("F", "mul wa,(0x1234:16)",  "d1341240",   "was d8 08 34 12 -- mul by the ADDRESS"),
    ("F", "cp (0x1234:16),0x56", "c134123f56", "was rejected outright"),
    ("F", "cp (0x9c:8),0xa5",    "c09c3fa5",   "the 8-bit direct form the I/O page uses"),
    ("F", "ld wa,(0x1234:16)",   "d1341220",   "was rejected outright"),
    ("F", "and (0x1234:16),0x56","c134123c56", "was rejected outright"),
    ("F", "or (0x9c:8),0x56",    "c09c3e56",   "was 'invalid operand'"),
    ("F", "popw (0x1234:16)",    "f1341206",   "destination-table pop"),
    ("F", "andcf a,(0x9c:8)",    "f09c28",     "carry-flag group"),
    ("F", "jp z,(0x1234:16)",    "f13412d6",   "conditional jump through memory"),
    ("F", "inc 1,(0x9c:8)",      "c09c61",     "was only spellable as incm8"),
    ("F", "rlc (0x9c:8)",        "c09c78",     "shift on a memory operand"),
    ("F", "mul c,(xiz+0x08)",    "8e0843",     "reg+d8 mul -- see the note below"),
    # --- class B: still rejected -- a real missing feature ----------------
    ("B", "ld sp,(0x9c:8)",      None, "SP is not in the 16-bit memory-load class"),
    ("B", "ldir (xiy)",          None, "the block transfer's operand register"),
    # --- class R: was a SILENT MISCOMPILE, now a diagnostic ---------------
    # Still not encodable -- but refused instead of quietly wrong, which is
    # the outcome that matters.  Promote to class F if either gains a real
    # encoding.
    ("R", "push 0x1234",         None, "was 09 34: immediate truncated to 8 bits"),
    ("R", "ld wa,(xix+iz)",      None,
     "was d3 f1 00 00 20: REGISTER-INDEXED read as (xix+d16) with iz "
     "swallowed as an undefined symbol.  ROM is d3 07 f0 f8 20"),
]


def assemble(src):
    """-> (ok, hexbytes_or_errortext)"""
    with tempfile.TemporaryDirectory() as d:
        s, o, b = (os.path.join(d, n) for n in ("t.s", "t.o", "t.bin"))
        open(s, "w").write(src + "\n")
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", INC, "-o", o, s],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return False, (r.stderr.strip().split("\n") or [""])[0]
        subprocess.run([OBJCOPY, "-O", "binary", "--only-section=.text", o, b],
                       capture_output=True)
        return True, open(b, "rb").read().hex()


def main():
    if not os.path.exists(MC):
        print("llvm-mc not built at %s" % MC); return 2
    rows = [(c, src, exp, note) + assemble(src) for c, src, exp, note in CASES]
    cls = lambda k: [r for r in rows if r[0] == k]
    if "--selftest" in sys.argv:
        f = 0
        def ck(d, c, extra=""):
            nonlocal f
            print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
            f += not c
        bad = [(s, exp, out) for _c, s, exp, _n, ok, out in cls("F") if not ok or out != exp]
        ck("class F: every FIXED form emits the ROM's bytes", not bad,
           "" if not bad else repr(bad[:2]))
        ck("class B: every listed form is still REJECTED",
           all(not ok for *_x, ok, _o in cls("B")),
           "if this FAILS, a gap was fixed -- move the case to class F")
        ck("class C is EMPTY: no known form assembles to the wrong bytes",
           not cls("C"))
        ck("class R: the two former silent miscompiles are now DIAGNOSED",
           all(not ok for *_x, ok, _o in cls("R")),
           "if this FAILS, one of them assembles again -- check the bytes")
        ck("class F is not empty -- this file records fixes, not only defects",
           len(cls("F")) >= 16)
        print("\n5 checks, %d failures" % f)
        return 1 if f else 0
    hdr = {"F": "FIXED -- and these bytes are the ROM's, not just 'accepted'",
           "R": "REFUSED now, SILENTLY WRONG before -- still not encodable",
           "B": "REJECTED -- a real missing feature in llvm-mc",
           "C": "★★ ACCEPTED AND WRONG -- silently truncated, the dangerous class",
           "D": "ACCEPTED but WIDER than the ROM's form"}
    for k in "FRBCD":
        if not cls(k):
            continue
        print("\n%s: %s" % (k, hdr[k]))
        for c, src, exp, note, ok, out in rows:
            if c != k: continue
            mark = "" if (not ok or exp is None or out == exp) else "  <-- MISMATCH vs %s" % exp
            print("   %-24s %-14s %s%s" % (src, (out[:16] if ok else "REJECTED"), note, mark))
    print("\n★ 'llvm-mc accepted it' is NOT evidence a macro can be retired -- see class C.")
    print("★ For the byte-for-byte proof over all 12,539 real call sites, run")
    print("  python3 wsa1/notes/llvm/llvm_native_equivalence.py")
    return 0

sys.exit(main())
