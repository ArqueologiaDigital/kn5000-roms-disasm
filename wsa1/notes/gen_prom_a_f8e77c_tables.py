#!/usr/bin/env python3
"""Emit prom_a 0xF8E77C-0xF8E7CD (81 B), the last `.incbin` in prom_a --
REFUSED twice, converted here as two LE32 address tables and 13 bytes of
identified residue.

QUESTION IT ANSWERS
    "81 bytes between a converted zero-init block and a byte-verified 0x0E pad.
     A naive decode dies 9 bytes in.  No reader cites either apparent table.
     What record shape do the bytes actually have?"

★ WHAT THE EARLIER REFUSAL SAID, AND WHAT IS CORRECTED

    notes/FINDINGS-prom_a-f8e6fa-boundary.md refused these bytes:

        "the pattern breaks immediately after: the next 4 bytes (`6e f7 0e 07`)
         are not a plausible pointer, then 9 more zero bytes, then the following
         'pointers' are off by ONE byte relative to a fixed 4-byte grid (`da e6
         f8 00` starts at 0xF8E7A9, not the expected 0xF8E7A8)"

    Every observation is correct.  The inference -- that one 4-byte grid is
    broken -- is not: there are TWO tables on TWO grids with 13 bytes between
    them, and both are found independently by notes/prom_a_ptr_tables.py, which
    knows nothing about this file:

        python3 notes/prom_a_ptr_tables.py 0xF8E700 0xF8E7D0

        0xF8E774   10 entries  0xF8E774-0xF8E79B  2 null  range 0xF8E000-0xF8E6DF
        0xF8E7A1   11 entries  0xF8E7A1-0xF8E7CC  2 null  range 0xF8E000-0xF8E70C

    Each run's first two entries are 0x00000000 -- the detector extends
    backwards into the 9-byte zero pad that precedes each table -- so the tables
    proper are 0xF8E77C (8 entries) and 0xF8E7A9 (9 entries).  Nothing is "off by
    one": the second table is simply not 4-aligned, which this ROM does elsewhere
    (the detector's own docstring cites ModuleInitDirectory_F82641, which starts
    on an odd address).

★ THE DETECTOR'S NULL, RE-READ -- this is what licenses runs this short

    prom_a_ptr_tables.py's `--null` runs the same detector over
    0xFB2000-0xFB8000, "24 KiB of prom_a that is already converted CODE", and
    reports 5 runs, two of them 16 entries long.  Read as a false-positive rate,
    that would make runs of 10 and 11 worthless.

    IT IS NOT A FALSE-POSITIVE RATE.  All five control hits -- 0xFB2081,
    0xFB3517, 0xFB42D1, 0xFB6240, 0xFB62F6 -- are the FIRST ENTRY of a `.long`
    table already declared in wsa1_prom_a.s; the source line at each is
    `.long 0x... ; <addr>  [  0]`.  The control region is code AND its declared
    tables, and the detector found the tables and nothing else.  Its precision
    in the control is 5/5 and its false-positive count on code is ZERO.
    `--audit` re-derives that from the source text on every run.

WHAT ELSE PINS THE FRAMING

  * The second table ends EXACTLY at 0xF8E7CD, where a 51-byte run of 0x0E
    begins that an earlier pass verified byte by byte.  That end is fixed by
    something other than the run.
  * All 17 values are addresses inside this module's own 0xF8E000-0xF8E70C.
  * The 13 bytes between the tables (0xF8E79C-0xF8E7A9) are BYTE-IDENTICAL to
    0xF8E76F-0xF8E77C: the last four bytes of the init routine at 0xF8E74B
    (`jr nz / ret / reti`) followed by the nine-byte LDIR source that routine
    names by address.  That 13-byte string occurs in prom_a exactly twice, at
    those two addresses.  So the gap is residue of the SAME shape, not a broken
    record -- the same linker-slack phenomenon this session identified at
    0xFDFFDF-0xFE0000.

⚠ WHAT IS NOT ESTABLISHED, AND IS NOT CLAIMED

  * No reader.  A whole-image LE24/LE32 scan for 0xF8E77C and for 0xF8E7A9 finds
    zero hits in any of the four images.
  * THESE ARE NOT ROUTINE-ENTRY TABLES.  Only 5 of the 17 values land on an
    instruction boundary of the converted code around them, which is roughly
    what chance gives at this instruction density.  Two of the five are real
    leaf routines this module dispatches to by address (uDMA3_SetDest 0xF8E6C9,
    reached via `lda XIX,0xF8E6C9 / jp (XIX)` at 0xF8E484, and uDMA3_GetCount
    0xF8E6DA); the other twelve point into the middle of instructions.  What
    they address is UNKNOWN.  The emitted names say `AddrTable`, which records
    the record SHAPE -- LE32 in-image addresses -- and no role.
  * The 4 bytes `6e f7 0e 07` are typed as bytes, NOT disassembled as
    `jr nz / ret / reti`.  Framing them as instructions would assert a control
    path that nothing reaches; they are the tail of an object that was
    overwritten.

RUN
    python3 notes/gen_prom_a_f8e77c_tables.py --audit
    python3 notes/gen_prom_a_f8e77c_tables.py
    python3 notes/gen_prom_a_f8e77c_tables.py --splice
"""
import importlib.util
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")

LO, HI = 0xF8E77C, 0xF8E7CD
T1, T1N = 0xF8E77C, 8
GAP, GAPN = 0xF8E79C, 13
T2, T2N = 0xF8E7A9, 9
TWIN = 0xF8E76F                 # the gap's byte-identical twin


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


PT = _load(os.path.join(ROOT, "notes", "prom_a_ptr_tables.py"), "wsa1_pt_f8e77c")


def rom():
    return open(ROM, "rb").read()


def w(d, a):
    return int.from_bytes(d[a - BASE:a - BASE + 4], "little")


def source_addrs():
    return set(int(m, 16) for m in
               re.findall(r';\s*(F[89A-F][0-9A-F]{4})\b',
                          open(SRC, encoding="utf-8").read()))


def control_hits_are_declared_tables():
    """The re-reading of prom_a_ptr_tables.py's null: is every control hit the
    FIRST ENTRY of a `.long` table already declared in the source?"""
    s = open(SRC, encoding="utf-8").read()
    out = []
    for a, _n in PT.runs(0xFB2000, 0xFB8000, 4):
        m = re.search(r'^\s*\.long\s+0x[0-9a-f]+\s*;\s*%06X\s+\[\s*0\]' % a, s, re.M)
        out.append((a, bool(m)))
    return out


def facts():
    d = rom()
    ev1 = [w(d, T1 + 4 * k) for k in range(T1N)]
    ev2 = [w(d, T2 + 4 * k) for k in range(T2N)]
    det = PT.runs(0xF8E700, 0xF8E7D0, 4)
    ctrl = control_hits_are_declared_tables()
    gap = d[GAP - BASE:GAP - BASE + GAPN]
    twin = d[TWIN - BASE:TWIN - BASE + GAPN]
    occ, i = [], d.find(bytes(gap))
    while i >= 0:
        occ.append(BASE + i)
        i = d.find(bytes(gap), i + 1)
    ins = source_addrs()
    return dict(ev1=ev1, ev2=ev2, det=det, ctrl=ctrl, gap=gap, twin=twin,
                occ=occ, ins=ins,
                onstart=sum(1 for v in ev1 + ev2 if v in ins),
                pad=set(d[HI - BASE:0xF8E800 - BASE]))


def checks(F):
    return [
        ("prom_a_ptr_tables.py finds exactly two runs in 0xF8E700-0xF8E7D0",
         len(F["det"]) == 2),
        ("their non-null parts are exactly 0x%06X x%d and 0x%06X x%d"
         % (T1, T1N, T2, T2N),
         F["det"] == [(T1 - 8, T1N + 2), (T2 - 8, T2N + 2)]),
        ("EVERY hit of the detector's own null control is the first entry of a "
         "`.long` table already declared in this source (precision %d/%d, "
         "false positives on code: 0)"
         % (sum(1 for _a, ok in F["ctrl"] if ok), len(F["ctrl"])),
         F["ctrl"] and all(ok for _a, ok in F["ctrl"])),
        ("all %d values are addresses inside 0xF8E000-0xF8E70C"
         % (T1N + T2N),
         all(0xF8E000 <= v <= 0xF8E70C for v in F["ev1"] + F["ev2"])),
        ("the 13-byte gap is byte-identical to 0x%06X" % TWIN,
         F["gap"] == F["twin"]),
        ("...and that 13-byte string occurs in prom_a exactly twice, at those "
         "two addresses", F["occ"] == [TWIN, GAP]),
        ("the second table ends exactly where the 0x0E pad begins",
         F["pad"] == {0x0E}),
        ("★ the values are NOT routine entries: only %d of %d land on an "
         "instruction boundary" % (F["onstart"], T1N + T2N),
         F["onstart"] * 2 < (T1N + T2N)),
    ]


def emit():
    F = facts()
    bad = [t for t, ok in checks(F) if not ok]
    if bad:
        sys.exit("REFUSING TO EMIT: failed check(s): %s" % "; ".join(bad))
    ins = F["ins"]
    L = []
    L.append("; ---------------------------------------------------------------------")
    L.append("; 0x%06X-0x%06X (81 B) -- TWO LE32 ADDRESS TABLES with 13 bytes of" % (LO, HI))
    L.append("; identified residue between them.  Converted 2026-09-02 by")
    L.append("; notes/gen_prom_a_f8e77c_tables.py; argument in")
    L.append("; notes/FINDINGS-prom_a-f8e6fa-boundary.md, extended this pass.")
    L.append(";")
    L.append("; ★ THIS OVERTURNS THE REFUSAL IN THAT FINDINGS FILE.  Its reason was that")
    L.append(";   \"the following 'pointers' are off by ONE byte relative to a fixed 4-byte")
    L.append(";   grid\".  They are not off by one: there are TWO tables on TWO grids with")
    L.append(";   13 bytes between them, and notes/prom_a_ptr_tables.py -- which knows")
    L.append(";   nothing about this file -- finds both:")
    for a, n in F["det"]:
        L.append(";       0x%06X  %2d entries (the first two are 0x00000000, inside the"
                 % (a, n))
        L.append(";                  9-byte zero pad that precedes the table)")
    L.append(";   The second table is simply not 4-aligned, which this ROM does elsewhere.")
    L.append(";")
    L.append("; ★ WHY RUNS THIS SHORT ARE BELIEVED.  The detector's `--null` control over")
    L.append(";   0xFB2000-0xFB8000 reports 5 runs, two of them 16 entries -- which looks")
    L.append(";   like a false-positive rate that would sink a 10-entry run.  It is not.")
    L.append(";   ALL FIVE control hits (%s)"
             % ", ".join("0x%06X" % a for a, _ok in F["ctrl"]))
    L.append(";   are the FIRST ENTRY of a `.long` table already declared in this file.")
    L.append(";   The detector's false-positive count on code in the control is ZERO.")
    L.append(";")
    L.append("; Also pinned: the second table ends EXACTLY at 0x%06X, where the" % HI)
    L.append("; byte-verified 51-byte 0x0E pad begins; all 17 values are addresses inside")
    L.append("; this module's own 0xF8E000-0xF8E70C; and the 13-byte gap is BYTE-IDENTICAL")
    L.append("; to 0x%06X-0x%06X -- the last four bytes of the init routine at 0xF8E74B"
             % (TWIN, TWIN + GAPN))
    L.append("; plus the nine-byte LDIR source it names -- a string that occurs in prom_a")
    L.append("; exactly twice, here and there.  Residue of the same shape, not a broken")
    L.append("; record; the same slack seen at 0xFDFFDF-0xFE0000.")
    L.append(";")
    L.append("; ⚠ NOT ESTABLISHED.  No reader: a whole-image LE24/LE32 scan for 0x%06X" % T1)
    L.append(";   and 0x%06X finds zero hits.  And these are NOT routine-entry tables --" % T2)
    L.append(";   only %d of the 17 values land on an instruction boundary, about what"
             % F["onstart"])
    L.append(";   chance gives here.  `AddrTable` names the record SHAPE (LE32 in-image")
    L.append(";   addresses), not a role; what they address is unknown.")
    L.append("; ---------------------------------------------------------------------")
    L.append("AddrTable_F8E77C:   ; 8 entries")
    for k, v in enumerate(F["ev1"]):
        L.append("\t.long 0x%08x   ; %06X  [%d]%s"
                 % (v, T1 + 4 * k, k, "  instruction boundary" if v in ins else ""))
    L.append("; 0x%06X-0x%06X (13 B) -- RESIDUE, byte-identical to 0x%06X-0x%06X:"
             % (GAP, T2, TWIN, TWIN + GAPN))
    L.append("; `jr nz / ret / reti` closing the init routine at 0xF8E74B, then the")
    L.append("; nine-byte LDIR source that follows it.  Left as bytes on purpose: framing")
    L.append("; these four as instructions would assert a control path nothing reaches.")
    L.append("\t.byte %-46s ; %06X"
             % (", ".join("0x%02x" % x for x in F["gap"][:4]), GAP))
    L.append("\t.byte %-46s ; %06X"
             % (", ".join("0x%02x" % x for x in F["gap"][4:]), GAP + 4))
    L.append("AddrTable_F8E7A9:   ; 9 entries; ends exactly where the 0x0E pad begins")
    for k, v in enumerate(F["ev2"]):
        L.append("\t.long 0x%08x   ; %06X  [%d]%s"
                 % (v, T2 + 4 * k, k, "  instruction boundary" if v in ins else ""))
    return L


def verify(lines):
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
        F = facts()
        print("0x%06X-0x%06X, %d bytes" % (LO, HI, HI - LO))
        print("  detector runs        %s"
              % ", ".join("0x%06X x%d" % r for r in F["det"]))
        print("  control hits         %s"
              % ", ".join("0x%06X %s" % (a, "declared table" if ok else "NOT")
                          for a, ok in F["ctrl"]))
        print("  table 1              %s" % ["0x%06X" % v for v in F["ev1"]])
        print("  table 2              %s" % ["0x%06X" % v for v in F["ev2"]])
        print("  on instruction start %d/%d" % (F["onstart"], T1N + T2N))
        print("  13-byte gap          %s" % " ".join("%02x" % x for x in F["gap"]))
        print("  its occurrences      %s" % ["0x%06X" % a for a in F["occ"]])
        bad = 0
        for t, ok in checks(F):
            print("  [%s] %s" % ("ok" if ok else "FAIL", t))
            bad += not ok
        return 1 if bad else 0
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
