#!/usr/bin/env python3
"""Emit prom_a 0xFDFFDF-0xFE0000 (33 B), the last `.incbin` of prom_a's 0xFD
half -- REFUSED by an earlier pass, converted here.

QUESTION IT ANSWERS
    "33 bytes sit between a clean `unlk XIZ / ret` at 0xFDFFDE and the next
     module's `jp` veneers at 0xFE0000.  No decode from any of the 128 possible
     starts resynchronises on 0xFE0000.  What are they?"

★ WHAT THE EARLIER PASS CONCLUDED, AND WHY IT IS OVERTURNED

    `prom_a/wsa1_prom_a.s` carried this refusal (2026-09-01):

        "A decode continued from here never resynchronises before 0xFE0000 ...
         condition codes and operand shapes that do not occur anywhere else in
         this span, the signature of genuinely different content, not a misread
         continuation."

    The observation was right and the inference was half right: it IS different
    content.  It is not, however, unidentifiable.  It is a TRUNCATED STALE COPY
    of a routine prologue that occurs at least 26 times across prom_a and
    prom_b, and the reason no decode resynchronises on 0xFE0000 is that the
    fragment's last instruction is cut in half by the module boundary.

    The instrument that found it is `notes/prom_a_near_match.py`, which slides a
    byte range over all four images and scores Hamming similarity.  An exact
    substring search -- what the earlier pass ran -- cannot find a relocated
    copy, because a `call` target, a `jr` displacement and a 32-bit immediate
    all differ.  Those are exactly the 2 to 5 bytes that differ here.

        python3 notes/prom_a_near_match.py 0xFDFFDF 0xFE0000

        NULL over 4000 random offsets: best 5/33 (15%), mean 0.4/33 (1%)
          31/33 (94%)  prom_b 0xF00CB2, 0xF00CF3, 0xF00D34, 0xF00D75
          29/33 (88%)  prom_b 0xF0A91E
          28/33 (85%)  prom_a 0xFD054D, ... , 0xFDE71F   (and 6 more)

    94% against a 15% null, and every differing byte is an OPERAND field.

★ WHY IT STARTS AND ENDS MID-INSTRUCTION -- the point the refusal missed

    The four prom_b copies read, in full:

        30 38            pushw ... / push XWA
        9e 0a 04         pushw (XIZ+0x0a)
        9e 08 04         pushw (XIZ+0x08)
        1d 28 bd fd      call 0xfdbd28
        ef 60 / ef 64    inc 0,XSP / inc 4,XSP
        d8 cf ff ff      cp WA,0xffff
        66 1e            jr z, +0x1e
        9e fe 21 ...     ld bc,(xiz-2) ...
        e9 c8 ac 02 f0 00   add XBC,0x00f002ac

    prom_a 0xFDFFDF begins at `08 04` -- the last two bytes of `9e 08 04`.  Its
    0x9e opcode byte would sit at 0xFDFFDE, which the LIVE module overwrote with
    its `unlk XIZ / ret` epilogue.  At the other end, `e9 c8 44 01` is the head
    of `add XBC,0x00fc0144`; the immediate's top two bytes would sit at 0xFE0000
    and 0xFE0001, which the NEXT module's first `jp` veneer overwrote.

    So this is linker SLACK holding the middle of an older object: written over
    at the front by the module that ends at 0xFDFFDF, and at the back by the
    module that starts at 0xFE0000.  It is not reached by anything and never
    executes.  That is why no start makes 0xFE0000 a boundary -- the question
    "which start resynchronises" had no right answer to find.

WHAT IS EMITTED
    0xFDFFDF  2 B  `.byte` -- orphan operand bytes of `pushw (XIZ+0x08)`
    0xFDFFE1 27 B  instructions, through prom_a/roundtrip.py (re-assembled and
                   byte-compared); `8e fc 43` is written `m_mul MBD+r6,0xfc,3`,
                   the spelling this file already uses for those bytes at
                   0xFDE737
    0xFDFFFC  4 B  `.byte` -- head of `add XBC,0x00fc0144`, truncated

    The two `.byte` runs are 6 bytes and each is a NAMED half-instruction, not
    undecoded residue.

RUN
    python3 notes/gen_prom_a_fdffdf_fragment.py --audit
    python3 notes/gen_prom_a_fdffdf_fragment.py
    python3 notes/gen_prom_a_fdffdf_fragment.py --splice
"""
import importlib.util
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")

LO, HI = 0xFDFFDF, 0xFE0000
MID_LO, MID_HI = 0xFDFFE1, 0xFDFFFC
# the closest witness, and the offset in it that lines up with LO
WITNESS = ("prom_b", 0xF00CB2, 0xF00000, 0)
EXPECT_MATCH = 31          # of 33, against that witness's aligned window


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "wsa1_rt_fdffdf")


def rom():
    return open(ROM, "rb").read()


def witness_diff():
    a = rom()[LO - BASE:HI - BASE]
    nm, wadr, wbase, off = WITNESS
    b = open(os.path.join(ROOT, "original_ROMs",
                          {"prom_b": "wsa1_prom_b.ic13"}[nm]), "rb").read()
    o = wadr - wbase + off
    w = b[o:o + len(a)]
    return a, w, [k for k in range(len(a)) if a[k] != w[k]]


def emit():
    a, w, diff = witness_diff()
    if len(a) - len(diff) != EXPECT_MATCH:
        sys.exit("REFUSING TO EMIT: witness match is %d/%d, audited at %d/%d"
                 % (len(a) - len(diff), len(a), EXPECT_MATCH, len(a)))
    d = rom()
    L = []
    L.append("; ---------------------------------------------------------------------")
    L.append("; 0x%06X-0x%06X (33 B) -- LINKER SLACK holding the middle of a STALE COPY" % (LO, HI))
    L.append("; of a routine prologue.  Converted 2026-09-02 by")
    L.append("; notes/gen_prom_a_fdffdf_fragment.py; argument in")
    L.append("; notes/FINDINGS-prom_a-fdffdf-stale-fragment.md.")
    L.append(";")
    L.append("; ★ THIS OVERTURNS THE REFUSAL THAT STOOD HERE.  That text (kept below,")
    L.append(";   above the fragment) said the bytes were \"the signature of genuinely")
    L.append(";   different content\" and that no start makes 0xFE0000 a boundary.  Both")
    L.append(";   observations are correct.  The conclusion drawn from them -- that the")
    L.append(";   content could not be identified -- is not: it IS different content,")
    L.append(";   and it is a 94%-identical copy of a prologue that 26 places in prom_a")
    L.append(";   and prom_b match at 70% or better.  No start makes 0xFE0000 a boundary")
    L.append(";   because the fragment's last instruction is CUT IN HALF by that boundary.")
    L.append(";")
    L.append("; Evidence: notes/prom_a_near_match.py 0xFDFFDF 0xFE0000 --")
    L.append(";   31/33 identical to prom_b 0xF00CB2, 0xF00CF3, 0xF00D34 and 0xF00D75,")
    L.append(";   29/33 to prom_b 0xF0A91E, 28/33 to twenty-one more including")
    L.append(";   prom_a's own 0xFDE71F, against a NULL of best 5/33 (15%) over 4000")
    L.append(";   random offsets in the same four images.  Every differing byte is an")
    L.append(";   operand field: the `call` target, the `jr` displacement, the imm32.")
    L.append(";")
    L.append("; It starts and ends mid-instruction because it is slack: the live module")
    L.append("; that ends at 0x%06X overwrote the leading `9e` of `pushw (XIZ+0x08)` at" % LO)
    L.append("; 0xFDFFDE, and the module starting at 0xFE0000 overwrote the top two bytes")
    L.append("; of the trailing `add XBC,0x00fc0144`.  Nothing reaches it; it never runs.")
    L.append("; ---------------------------------------------------------------------")
    b0 = d[LO - BASE:MID_LO - BASE]
    L.append("\t.byte %-46s ; %06X  orphan operands of `pushw (XIZ+0x08)`; its 0x9e"
             % (", ".join("0x%02x" % x for x in b0), LO))
    L.append("\t;                                                     opcode byte at 0xFDFFDE is under the live `ret`")
    block, ok, _cs = RT.emit_block(MID_LO, MID_HI)
    if not ok:
        sys.exit("REFUSING TO EMIT: 0x%06X-0x%06X did not round-trip" % (MID_LO, MID_HI))
    for text, addr, bs, _why in block:
        if addr is None:
            L.append(text)
            continue
        t = text.lstrip("\t")
        if t.startswith(".byte 0x8e, 0xfc, 0x43"):
            t = "m_mul MBD+r6, 0xfc, 3"          # as at 0xFDE737 in this file
        raw = " ".join("%02x" % x for x in bs)
        L.append("\t%-52s ; %06X  %s" % (t, addr, raw))
    b1 = d[MID_HI - BASE:HI - BASE]
    L.append("\t.byte %-46s ; %06X  head of `add XBC,0x00fc0144`, truncated"
             % (", ".join("0x%02x" % x for x in b1), MID_HI))
    L.append("\t;                                                     by the module that starts at 0xFE0000")
    return L


def verify(lines):
    # NOT RT.macro_prelude(): in this tree it returns only the header.  It slices
    # the image file between the BEGIN and END markers, and the image has the
    # include INLINED, whose own prose quotes the END marker -- so the slice stops
    # before any `.macro`.  That is why roundtrip.py never picks a macro spelling
    # here.  The include below is exactly what the master source does at its top.
    src = ('\t.include "include/tlcs900_mem_ops.inc"\n\t.text\n'
           + "\n".join(lines) + "\n")
    d = tempfile.mkdtemp()
    a_s, a_o, a_b = d + "/r.s", d + "/r.o", d + "/r.bin"
    open(a_s, "w").write(src)
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "-filetype=obj", "-I", ROOT,
                        "-I", os.path.join(ROOT, "prom_a"), "-o", a_o, a_s],
                       capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        return False, r.stderr[-2000:]
    r = subprocess.run([OBJCOPY, "-O", "binary", "--only-section=.text", a_o, a_b],
                       capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        return False, r.stderr[-2000:]
    got = open(a_b, "rb").read()
    want = rom()[LO - BASE:HI - BASE]
    return got == want, ("%d vs %d bytes" % (len(got), len(want)) if got != want else "")


def main():
    if "--audit" in sys.argv:
        a, w, diff = witness_diff()
        nm, wadr, _wb, off = WITNESS
        print("0x%06X-0x%06X, %d bytes; witness %s 0x%06X+%d"
              % (LO, HI, len(a), nm, wadr, off))
        print("  identical %d/%d (%.0f%%), differing offsets %s"
              % (len(a) - len(diff), len(a), 100.0 * (len(a) - len(diff)) / len(a),
                 ", ".join("+%d" % k for k in diff)))
        for k in diff:
            print("    +%-2d  0x%06X  ours %02x  witness %02x" % (k, LO + k, a[k], w[k]))
        print("  [%s] match is the audited %d/%d"
              % ("ok" if len(a) - len(diff) == EXPECT_MATCH else "FAIL",
                 EXPECT_MATCH, len(a)))
        return 0
    lines = emit()
    ok, why = verify(lines)
    if not ok:
        sys.exit("REFUSING TO PRINT: emitted text does not rebuild the span (%s)" % why)
    if "--splice" in sys.argv:
        tmp = tempfile.mktemp(suffix=".s")
        open(tmp, "w").write("\n".join(lines) + "\n")
        r = subprocess.run([sys.executable,
                            os.path.join(ROOT, "prom_a", "insert_region.py"),
                            hex(LO), hex(HI), tmp],
                           capture_output=True, text=True, cwd=ROOT)
        os.unlink(tmp)
        if r.returncode != 0:
            sys.exit("splice failed: %s%s" % (r.stdout, r.stderr))
        print(r.stdout.strip())
        return 0
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
