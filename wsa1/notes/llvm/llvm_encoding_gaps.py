#!/usr/bin/env python3
"""What must be fixed in llvm-mc so the disassembly can drop its encoding macros.

QUESTION IT ANSWERS: `wsa1/include/tlcs900_mem_ops.inc` defines 122 macros with
12,539 call sites, all of them working around llvm-mc.  Which of those are real
assembler gaps, which are already native, and which are WORSE than a gap because
llvm-mc accepts the syntax and emits different bytes?

RUN:  python3 wsa1/notes/llvm/llvm_encoding_gaps.py            # the three classes
      python3 wsa1/notes/llvm/llvm_encoding_gaps.py --selftest

★★ THE FINDING THAT MATTERS MOST is class C: `push (0x1234)` assembles, without
   any diagnostic, to `09 34` -- the address is TRUNCATED TO 8 BITS.  That is a
   silent wrong encoding, not a missing feature, and it is the reason "llvm-mc
   accepted it" is never sufficient evidence to retire a macro.  Every macro
   retired must be proven byte-identical against the ROM, which is what the
   project byte gate does.
"""
import os, subprocess, sys, tempfile

LLVM = "/home/fsanches/compartilhado/llvm-project/build/bin"
MC, OBJCOPY = os.path.join(LLVM, "llvm-mc"), os.path.join(LLVM, "llvm-objcopy")
INC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "include")

# (source, expected-bytes-or-None, note).  Expected bytes are ROM truth where the
# case is taken from a real call site; None means "we only care that it is rejected".
CASES = [
    # --- class A: already native, and CORRECT.  A macro here is pure habit.
    ("A", "mul WA,(0x1234)",     None, "accepted"),
    # --- class B: rejected outright -- a real missing feature.
    ("B", "cp (0x1234),0x56",    None, "byte/word direct memory operand"),
    ("B", "ld WA,(0x1234)",      None, "byte/word direct memory operand"),
    ("B", "and (0x1234),0x56",   None, "byte/word direct memory operand"),
    ("B", "or (0x1234),0x56",    None, "invalid operand"),
    ("B", "mul BC,(XIZ+0x08)",   None, "register-indexed memory operand"),
    # --- class C: ACCEPTED AND WRONG.  The dangerous class.
    ("C", "push (0x1234)",       "0934", "address truncated to 8 bits"),
    ("C", "push (0x5678)",       "0978", "address truncated to 8 bits"),
    ("C", "push (0x123456)",     "0956", "address truncated to 8 bits"),
    # --- class D: accepted, but a WIDER form than the ROM uses.
    ("D", "bit 1,(0x2075)",      "f2752000c9", "ROM uses f1 (16-bit) -- this is f2 (24-bit)"),
    ("D", "set 3,(0x1234)",      "f2341200bb", "ROM form is narrower"),
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
    if "--selftest" in sys.argv:
        f = 0
        def ck(d, c, extra=""):
            nonlocal f
            print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
            f += not c
        # ★ Invariants about the DEFECTS, so this file fails the day they are fixed --
        # which is the point: it is a work list, and it should go red as work lands.
        cls = lambda k: [r for r in rows if r[0] == k]
        ck("class A: at least one form assembles natively",
           any(ok for *_x, ok, _o in cls("A")))
        ck("class B: every listed form is still REJECTED",
           all(not ok for *_x, ok, _o in cls("B")),
           "if this FAILS, a gap was fixed -- retire the case and the macro")
        ck("class C: push (mem) still TRUNCATES the address",
           all(ok and out == exp for _c, _s, exp, _n, ok, out in cls("C")),
           "if this FAILS, the silent miscompile is fixed -- verify, then celebrate")
        ck("class C really is truncation: three addresses, three low bytes kept",
           {r[5] for r in cls("C")} == {"0934", "0978", "0956"})
        ck("class D: llvm-mc still picks the wider memory form",
           all(ok and out == exp for _c, _s, exp, _n, ok, out in cls("D")))
        print("\n5 checks, %d failures" % f)
        return 1 if f else 0
    hdr = {"A": "ALREADY NATIVE -- the macro is habit, not necessity",
           "B": "REJECTED -- a real missing feature in llvm-mc",
           "C": "★★ ACCEPTED AND WRONG -- silently truncated, the dangerous class",
           "D": "ACCEPTED but WIDER than the ROM's form"}
    for k in "ABCD":
        print("\n%s: %s" % (k, hdr[k]))
        for c, src, exp, note, ok, out in rows:
            if c != k: continue
            print("   %-24s %-14s %s" % (src, (out[:14] if ok else "REJECTED"), note))
    print("\n★ 'llvm-mc accepted it' is NOT evidence a macro can be retired -- see class C.")
    return 0

sys.exit(main())
