#!/usr/bin/env python3
"""Can ONE source assemble to BOTH kernels, and does it need conditionals?

QUESTION IT ANSWERS
    prom_a and prom_c hold the same kernel, all 36 routine pairs offset by the
    single constant 0x12B65. Before writing a shared source, one thing decides
    its shape:

      Are the operand differences between the two copies EXACTLY that offset?

    If YES, every difference is a SELF-REFERENCE -- the same label resolved at a
    different link address -- and a shared source written with LABELS instead of
    absolute addresses assembles correctly in both CPUs with NO .if/.else at all.
    If NO, the residue is a real per-CPU difference (a peripheral base, a RAM
    cell) and those, and only those, need a conditional.

RESULT (this is the measurement the shared-source design rests on)
    938 instructions paired across 76 routines:
        858  byte-identical                          91.5%
          5  differ by EXACTLY the 0x12B65 offset    self-references, no conditional needed
         75  differ by something else                REAL per-CPU differences

    ★ So it is NOT pure relocation, and the review's instinct was right: conditionals
    are needed. But the 75 are not 75 unrelated edits -- they are a handful of
    recurring CONSTANTS, and the top of the histogram shows the same delta over and
    over (-46 x13, -524 x13, -2 x9, -596 x8, -544 x5, -556 x5). The three kinds:
        ld XSP,0x0060eb80  vs  ld XSP,0x0000fa00     the STACK TOP -- different RAM maps
        ld (0xbf),WA       vs  ld (0x91),WA          an SFR ADDRESS -- delta -0x2E
        ld HL,0x0330       vs  ld HL,0x0124          a SIZING CONSTANT
    ★ That shape argues for symbolic `.equ`s per CPU over `.if/.else` wrapped round
    code: the BODY is then genuinely shared, and each difference is named once
    rather than duplicated at every site. The byte gate proves it -- if a single
    equate is wrong, both images stop rebuilding.

    This is the difference between a clean shared source and one littered with
    conditionals that hide relocation as if it were machine variation.

METHOD
    Decode both copies instruction by instruction, pair them positionally (the
    tiling is already proven by notes/prom_c_kernel_map.py), and for every slot
    whose bytes differ, extract the operand words and subtract.

RUN
    python3 notes/kernel_shared_source_probe.py
    python3 notes/kernel_shared_source_probe.py --selftest
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
OFFSET = 0x12B65                      # prom_c address - prom_a address
A_BASE = C_BASE = 0xF80000
# ⚠ PAIR PER ROUTINE, NOT PER BLOCK. A first draft decoded one big range from each
# side and they desynchronised (5,121 instructions against 6,749) because a guessed
# start put one side mid-instruction. The routine boundaries are already proven by
# notes/prom_c_kernel_map.py, so each routine is decoded from its own label.
BLOCK_END_C = 0xF989EF


# ⚠ UPDATED 2026-08-30, when the two kernels became ONE SOURCE.  The routine
# labels used to be read out of prom_c/wsa1_prom_c.s; prom_c now `.include`s
# kernel/kernel.s and no longer writes the block out, so reading prom_c found
# ZERO routines and this file's selftest crashed.  The labels are read from the
# shared file instead.  Its lines carry BOTH addresses -- `; F85606/F9816B` --
# and the second is prom_c's, which is what the rest of this script wants.
KERNEL_SRC = "kernel/kernel.s"


def kernel_pairs():
    """[(name, prom_c lo, prom_c hi)] for the kernel routines, read from the
    SHARED source. prom_a's address is always prom_c's minus OFFSET -- that is the
    kernel map's central finding and it is asserted, not assumed, in --selftest."""
    lines = open(os.path.join(ROOT, KERNEL_SRC)).read().split("\n")
    marks, seen = [], set()
    for i, l in enumerate(lines):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', l)
        if m:
            for l2 in lines[i + 1:i + 40]:
                mm = re.search(r';\s*[0-9A-F]{6}/([0-9A-F]{6})\b', l2)
                if mm:
                    a = int(mm.group(1), 16)
                    # the shared file carries prom_a's name for an address as a
                    # second label under prom_c's; count each address once
                    if a not in seen:
                        seen.add(a)
                        marks.append((a, m.group(1)))
                    break
                # ⚠ do NOT stop at another label: in the shared file prom_c's
                # name and prom_a's name for the SAME address sit on consecutive
                # lines, and stopping here dropped 11 routines.  `seen` keeps the
                # first name for an address, which is prom_c's.
                if re.match(r'^[A-Za-z_.][A-Za-z0-9_.]*:', l2):
                    continue
    marks.sort()
    names = set()
    for _a, n in marks:
        if n.startswith("Kernel_") or n.startswith("MsgQueue_") or n.startswith("SoftTimer_") \
           or n.startswith("IRQ_Epilogue") or n.startswith("INTT3_"):
            names.add(n)
    out = []
    for i, (a, n) in enumerate(marks):
        if n in names:
            hi = marks[i + 1][0] if i + 1 < len(marks) else BLOCK_END_C
            if 0xF98000 <= a < BLOCK_END_C and hi > a:
                out.append((n, a, min(hi, BLOCK_END_C)))
    return out


def rom(which):
    f = "wsa1_prom_a.ic12" if which == "a" else "wsa1_prom_c.ic28"
    return open(os.path.join(ROOT, "original_ROMs", f), "rb").read()


def decode(which, lo, hi):
    d = rom(which)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d[lo - 0xF80000:hi - 0xF80000])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(lo)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for ln in out.splitlines():
        m = re.match(r'^\s*([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if m:
            rows.append((int(m.group(1), 16),
                         bytes.fromhex(m.group(2).replace(" ", "")),
                         m.group(3).strip()))
    return rows


def main():
    pairs = kernel_pairs()
    print("kernel routines paired from the shared source's labels: %d\n" % len(pairs))
    same = reloc = other = 0
    skipped = 0
    deltas = Counter()
    examples = []
    slots = 0
    for name, clo, chi in pairs:
        rc = decode("c", clo, chi)
        ra = decode("a", clo - OFFSET, chi - OFFSET)
        if len(ra) != len(rc):
            skipped += 1
            continue
        slots += len(ra)
        for i in range(len(ra)):
            aa, ab, at = ra[i]
            ca, cb, ct = rc[i]
            if ab == cb:
                same += 1
                continue
            if len(ab) != len(cb):
                other += 1
                continue
            diff = [k for k in range(len(ab)) if ab[k] != cb[k]]
            if not diff:
                same += 1
                continue
            lo_, hi_ = diff[0], diff[-1] + 1
            wa = int.from_bytes(ab[lo_:hi_], "little")
            wc = int.from_bytes(cb[lo_:hi_], "little")
            d = wc - wa
            deltas[d] += 1
            if d == OFFSET:
                reloc += 1
            else:
                other += 1
                if len(examples) < 12:
                    examples.append((aa, ca, at, ct, d))
    print("instructions paired: %d   (routines skipped for a decode mismatch: %d)\n"
          % (slots, skipped))
    print("  byte-identical                       %5d" % same)
    print("  differ by EXACTLY the 0x%05X offset  %5d   <- self-references, need NO conditional"
          % (OFFSET, reloc))
    print("  differ by something else             %5d   <- these, and only these, need one" % other)
    print("\ndelta histogram (top 8):")
    for d, c in deltas.most_common(8):
        tag = "  == OFFSET (relocation)" if d == OFFSET else ""
        print("   %+9d (0x%X)  x%d%s" % (d, d & 0xFFFFFF, c, tag))
    if examples:
        print("\nnon-relocation differences, which a shared source must handle explicitly:")
        for aa, ca, at, ct, d in examples:
            print("   a 0x%06X  %-34s" % (aa, at[:34]))
            print("   c 0x%06X  %-34s  delta %+d" % (ca, ct[:34], d))
    return 0


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    pairs = kernel_pairs()
    check("kernel routines found in the shared kernel source", len(pairs) > 20, "%d" % len(pairs))
    agree = 0
    for name, clo, chi in pairs:
        if len(decode("c", clo, chi)) == len(decode("a", clo - OFFSET, chi - OFFSET)):
            agree += 1
    # ⚠ 76 of 77, and the one exception is expected: Kernel_InitRam carries an
    # 8-byte INLINE DATA block (SoftTimer_Request_Boot) that is data in both
    # images, so a linear decode frames it differently on each side. That is the
    # same routine prom_c_kernel_map.py already reports as the only pair with a
    # structural difference. Pinning 77 would be pinning a wrong expectation.
    check("76 of 77 routines decode to the SAME instruction count on both sides",
          agree == 77 - 1, "%d of %d" % (agree, len(pairs)))
    name, clo, chi = pairs[-1]
    rcl = decode("c", clo, chi)
    ral = decode("a", clo - OFFSET, chi - OFFSET)
    check("the LAST routine (%s) pairs too" % name, len(rcl) == len(ral))
    check("...and its first slot is offset by exactly 0x%05X" % OFFSET,
          rcl[0][0] - ral[0][0] == OFFSET)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
