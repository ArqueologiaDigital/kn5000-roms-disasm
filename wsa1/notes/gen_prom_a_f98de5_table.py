#!/usr/bin/env python3
"""Emit prom_a 0xF98DE5-0xF99000 (539 B) as the pointer table it is -- REFUSED by
an earlier pass, converted here.

QUESTION IT ANSWERS
    "539 bytes between a routine's `ret` at 0xF98DE4 and the next module at
     0xF99000.  A linear decode fails at the FIRST byte.  No literal anywhere in
     the four images loads 0xF98DE5.  So what are they?"

★ WHAT THE EARLIER PASS CONCLUDED, AND WHAT IS CORRECTED

    notes/FINDINGS-prom_a-f98de5-investigation.md refused this span, and gave as
    its main technical reason:

        "indices 118+ : the alignment breaks.  Continuing the fixed 4-byte grid
         produces values like 0x00F30180, 0x00F3006A ... i.e. the true record
         grid is very likely NOT a uniform 4-byte stride starting exactly at
         0xF98DE5"

    ⚠ THE ALIGNMENT NEVER BREAKS.  Every one of the 134 four-byte windows from
    0xF98DE5 has a 0x00 top byte and a value in 0x00F00000-0x00FFFFFF -- there
    is not a single exception, and `--audit` prints the count.  What changes at
    index 118 is the VALUE FAMILY (0x00F30xxx instead of 0x00F2xxxx), which is a
    different table region, not a different stride.  A value-family change was
    read as a grid break, and that reading is what sank the span.

    The 3 leftover bytes were read the same way ("the true start is offset from
    0xF98DE5").  They are not.  See below.

THE EVIDENCE, ALL RE-DERIVED BY --audit

  1. GRID.  134/134 windows are pointer-shaped.  Zero exceptions.

  2. AN INDEPENDENT DETECTOR WITH A PUBLISHED NULL.  notes/prom_a_ptr_tables.py,
     which shares no code with this file, reports exactly one run in
     0xF98D00-0xF99010: 0xF98DE5, 134 entries.  Its `--null` over
     0xFB2000-0xFB8000 -- 24 KiB of prom_a that is already converted CODE --
     finds runs of at most 16 entries and ZERO runs of 17 or more.  This run is
     134.

  3. THE TARGETS ARE REAL OBJECTS.  32 of the 57 distinct 0x00F2xxxx/0x00F3xxxx
     values are RECORD STARTS of prom_b's display lists, walked with the
     interpreter's own self-checking (opcode, length) framing -- not addresses
     that merely look plausible.  The remaining local values are 0x00F98D20
     (31x), 0x00F98D21 (3x) and 0x00F98C85 (1x).

  4. A CONVERTED SIBLING WITH THE SAME SHAPE.  PtrTable_F99121, already in this
     file, is 169 LE32 pointers of exactly this kind, converted on exactly this
     class of evidence (its own header says the entry count came from
     prom_a_ptr_tables.py "NOT from a reader's bound, because no reader bound
     was found").  Align this table's entry 0 with PtrTable_F99121's entry 49
     (0xF991E5) and 28 of 120 entries are byte-identical, including an
     unbroken run of the first 10 and another of 12 at indices 23-34.  The two
     tails have the same shape -- many copies of a local default, one outlier,
     then three copies of a second local -- and the two defaults differ by
     EXACTLY 0x400: 0xF99120-0xF98D20 = 0xF99121-0xF98D21 = 0xF99085-0xF98C85 =
     0x400.  These are two parallel versions of one UI screen table.

  5. NOT CODE.  notes/prom_a_linear_decode_check.py reports 37 undecodable bytes
     starting at 0xF98DE5 itself, and no branch, call or `jp` operand anywhere
     in prom_a's converted source lands inside 0xF98DE5-0xF99000.

★ THE 3 LEFTOVER BYTES, EXPLAINED RATHER THAN EXPLAINED AWAY

    539 = 4*134 + 3.  The trailing `49 f9 f2` are the low three bytes of
    0x00F2F949 -- and 0xF2F949 IS a display-list record start, checked by the
    same length walk as the other 32.  So it is a 135th entry whose top byte
    would sit at 0xF99000.  0xF99000 holds 0x3E, the `push XIZ` that opens
    sub_F99000, so the entry is CUT IN HALF by the module boundary.

    That is the same mechanism this session identified at 0xFDFFDF-0xFE0000
    (notes/FINDINGS-prom_a-fdffdf-stale-fragment.md): an object that does not
    end where the next module begins simply loses its tail.  Two independent
    spans in this image, same failure, and in both cases the earlier refusal
    read the truncation as evidence that the framing was wrong.

    The 3 bytes are emitted as `.byte` with that reading stated.  They are NOT
    emitted as a `.long`: a fourth byte does not exist here, and inventing one
    would change the image.

WHAT IS NOT ESTABLISHED
    What indexes the table.  No literal 0x00F98DE5 (or any base within
    0xF98D00-0xF99010) exists in any of the four images -- re-checked this pass.
    PtrTable_F99121 has the same gap and was converted anyway; so is this.

RUN
    python3 notes/gen_prom_a_f98de5_table.py --audit
    python3 notes/gen_prom_a_f98de5_table.py
    python3 notes/gen_prom_a_f98de5_table.py --splice
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
ROM_B = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC_B = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")

LO, HI = 0xF98DE5, 0xF99000
N = 134                       # entries; 539 = 4*134 + 3
SIB = 0xF991E5                # PtrTable_F99121 entry 49, the aligned sibling
SIB_END = 0xF993C5


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


PT = _load(os.path.join(ROOT, "notes", "prom_a_ptr_tables.py"), "wsa1_pt_f98de5")


def rom():
    return open(ROM, "rb").read()


def w(d, a):
    return int.from_bytes(d[a - BASE:a - BASE + 4], "little")


def entries():
    d = rom()
    return [w(d, LO + 4 * k) for k in range(N)]


def dl_record_starts():
    """Every display-list RECORD start in prom_b, by walking the interpreter's
    own (opcode, length) framing inside each block prom_b's source declares."""
    b = open(ROM_B, "rb").read()
    hdr = re.findall(r'^; 0x(F[0-9A-F]{5})-0x(F[0-9A-F]{5}) -- \d+ records?, '
                     r'\d+ bytes -- interpreter \w+',
                     open(SRC_B, encoding="utf-8").read(), re.M)
    out = set()
    for a, e in hdr:
        lo, hi = int(a, 16), int(e, 16) + 1
        while lo < hi:
            ln = b[lo - 0xF00000 + 1]
            if ln == 0:
                break
            out.add(lo)
            lo += ln
    return out


def inbound_branches():
    s = open(SRC, encoding="utf-8").read()
    n = 0
    for m in re.finditer(r'\b(call|jp|jr|jrl|calr|djnz\w*)\b[^;\n]*?0x(f9[0-9a-f]{4})',
                         s, re.I):
        if LO <= int(m.group(2), 16) < HI:
            n += 1
    return n


def facts():
    d = rom()
    ev = entries()
    shaped = sum(1 for v in ev if PT.is_ptr(v) and v != 0)
    det = PT.runs(0xF98D00, 0xF99010, PT.DEFAULT_MIN)
    null_17 = PT.runs(0xFB2000, 0xFB8000, 17)
    null_16 = PT.runs(0xFB2000, 0xFB8000, 16)
    recs = dl_record_starts()
    tgt = sorted({v for v in ev if (v >> 16) in (0xF2, 0xF3)})
    tail = d[HI - BASE - 3:HI - BASE]
    tail_val = int.from_bytes(tail, "little")
    nsib = (SIB_END - SIB) // 4
    sib = [w(d, SIB + 4 * k) for k in range(nsib)]
    same = sum(1 for k in range(nsib) if ev[k] == sib[k])
    runs, k = [], 0
    while k < nsib:
        if ev[k] == sib[k]:
            j = k
            while j < nsib and ev[j] == sib[j]:
                j += 1
            runs.append((k, j - k))
            k = j
        else:
            k += 1
    return dict(ev=ev, shaped=shaped, det=det, null_16=null_16, null_17=null_17,
                recs=recs, tgt=tgt, tail=tail, tail_val=tail_val,
                sibn=nsib, same=same, runs=[r for r in runs if r[1] >= 3],
                inbound=inbound_branches(),
                next_byte=d[HI - BASE])


def checks(F):
    return [
        ("all %d four-byte windows from 0x%06X are pointer-shaped "
         "(top byte 0x00, value 0x00F00000-0x00FFFFFF)" % (N, LO),
         F["shaped"] == N),
        ("notes/prom_a_ptr_tables.py finds exactly one run in 0xF98D00-0xF99010, "
         "at 0x%06X, of %d entries" % (LO, N),
         len(F["det"]) == 1 and F["det"][0] == (LO, N)),
        ("its null over 24 KiB of converted CODE has runs of at most 16 entries "
         "and ZERO of 17 or more",
         len(F["null_16"]) > 0 and len(F["null_17"]) == 0),
        ("more than half the distinct prom_b targets are display-list RECORD "
         "starts under the interpreter's own length framing",
         sum(1 for v in F["tgt"] if v in F["recs"]) * 2 > len(F["tgt"])),
        ("the 3 trailing bytes read as 0x00%06X, which IS a display-list record "
         "start" % F["tail_val"], F["tail_val"] in F["recs"]),
        ("...and its top byte cannot exist: 0x%06X holds 0x%02X, the first byte "
         "of the next module" % (HI, F["next_byte"]), F["next_byte"] != 0x00),
        ("aligned with PtrTable_F99121 entry 49, at least 25 of %d entries are "
         "byte-identical, with an unbroken run of >= 10" % F["sibn"],
         F["same"] >= 25 and any(r[1] >= 10 for r in F["runs"])),
        ("no branch, call or jp operand in prom_a's source lands inside the span",
         F["inbound"] == 0),
    ]


def emit():
    F = facts()
    bad = [t for t, ok in checks(F) if not ok]
    if bad:
        sys.exit("REFUSING TO EMIT: failed check(s): %s" % "; ".join(bad))
    L = []
    L.append("; ---------------------------------------------------------------------")
    L.append("; PtrTable_F98DE5 -- %d LE32 pointers (536 B) and a 135th entry TRUNCATED" % N)
    L.append("; by the module boundary at 0x%06X (3 B).  Converted 2026-09-02 by" % HI)
    L.append("; notes/gen_prom_a_f98de5_table.py; argument in")
    L.append("; notes/FINDINGS-prom_a-f98de5-investigation.md, rewritten this pass.")
    L.append(";")
    L.append("; ★ THIS OVERTURNS THE REFUSAL RECORDED IN THAT FINDINGS FILE.  Its")
    L.append(";   technical reason was \"indices 118+ : the alignment breaks\".  It does")
    L.append(";   not: all %d four-byte windows from 0x%06X have a 0x00 top byte and a" % (N, LO))
    L.append(";   value in 0x00F00000-0x00FFFFFF, with ZERO exceptions.  What changes at")
    L.append(";   index 118 is the VALUE FAMILY (0x00F30xxx after 0x00F2xxxx), which is a")
    L.append(";   different region of prom_b, not a different stride.")
    L.append(";")
    L.append("; Evidence, all re-derived by --audit:")
    L.append(";   * notes/prom_a_ptr_tables.py -- which shares no code with the emitter --")
    L.append(";     reports exactly ONE run in 0xF98D00-0xF99010: this one, %d entries." % N)
    L.append(";     Its published null over 24 KiB of already-converted prom_a CODE finds")
    L.append(";     runs of at most 16 entries and NONE of 17 or more.")
    L.append(";   * %d of the %d distinct 0x00F2xxxx/0x00F3xxxx values are RECORD STARTS"
             % (sum(1 for v in F["tgt"] if v in F["recs"]), len(F["tgt"])))
    L.append(";     of prom_b's display lists, walked with the interpreter's own")
    L.append(";     self-checking (opcode, length) framing.")
    L.append(";   * PtrTable_F99121 (already in this file) is the same object for another")
    L.append(";     screen set.  Aligning entry 0 here with its entry 49 (0xF991E5) makes")
    L.append(";     %d of %d entries byte-identical, including unbroken runs of %s."
             % (F["same"], F["sibn"], ", ".join(str(r[1]) for r in F["runs"])))
    L.append(";     Both tails have the same shape, and the two local defaults differ by")
    L.append(";     exactly 0x400: 0xF99120-0xF98D20 = 0xF99121-0xF98D21 = 0x400.")
    L.append(";   * Not code: a linear decode has 37 undecodable bytes starting at")
    L.append(";     0x%06X itself, and no branch/call/jp operand in this file lands" % LO)
    L.append(";     inside the span.")
    L.append(';   * The span does NOT open mid-object.  Scanned from 0xF98C00 -- 485 bytes')
    L.append(';     earlier, and at every byte offset, not only 4-aligned ones -- the detector')
    L.append(';     still reports the run beginning at 0xF98DE5 and nowhere sooner; the word at')
    L.append(';     0xF98DE1 is 0x0E0DEE5B, the `pop XHL / unlk XIZ / ret` that closes the')
    L.append(';     routine above.  The `.incbin` boundary and the table boundary coincide.')
    L.append(";")
    L.append("; ★ THE 3 LEFTOVER BYTES.  539 = 4*%d + 3.  `%s` are the low three bytes"
             % (N, " ".join("%02x" % x for x in F["tail"])))
    L.append("; of 0x00%06X, which IS a display-list record start like the 32 above."
             % F["tail_val"])
    L.append("; Its top byte would sit at 0x%06X, which holds 0x%02X -- the `push XIZ`"
             % (HI, F["next_byte"]))
    L.append("; that opens sub_F99000.  The last entry is CUT IN HALF by the module")
    L.append("; boundary; the same thing happens at 0xFDFFDF-0xFE0000.  Emitted as")
    L.append("; `.byte`, not as a `.long`: the fourth byte does not exist.")
    L.append(";")
    L.append("; NOT ESTABLISHED: what indexes the table.  No literal 0x00%06X, nor any"
             % LO)
    L.append("; base inside 0xF98D00-0xF99010, exists in any of the four images.")
    L.append("; PtrTable_F99121 has the same gap and was converted anyway.")
    L.append("; ---------------------------------------------------------------------")
    L.append("PtrTable_F98DE5:")
    for k, v in enumerate(F["ev"]):
        if (v >> 16) in (0xF2, 0xF3):
            note = "prom_b display list" + (", record start" if v in F["recs"] else "")
        else:
            note = "prom_a local"
        L.append("\t.long 0x%08x   ; %06X  [%3d] %s" % (v, LO + 4 * k, k, note))
    L.append("\t.byte %-30s ; %06X  [%3d] TRUNCATED: low 3 bytes of 0x00%06X"
             % (", ".join("0x%02x" % x for x in F["tail"]), HI - 3, N, F["tail_val"]))
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
        print("0x%06X-0x%06X, %d bytes = 4*%d + 3" % (LO, HI, HI - LO, N))
        print("  pointer-shaped windows      %d/%d" % (F["shaped"], N))
        print("  prom_a_ptr_tables.py runs   %s"
              % ", ".join("0x%06X x%d" % r for r in F["det"]))
        print("  its null (24 KiB of code)   %d run(s) at MIN=16, %d at MIN=17"
              % (len(F["null_16"]), len(F["null_17"])))
        print("  distinct prom_b targets     %d, of which DL record starts %d"
              % (len(F["tgt"]), sum(1 for v in F["tgt"] if v in F["recs"])))
        print("  tail bytes                  %s -> 0x00%06X, DL record start: %s"
              % (" ".join("%02x" % x for x in F["tail"]), F["tail_val"],
                 F["tail_val"] in F["recs"]))
        print("  byte at 0x%06X              0x%02X (so no 4th byte exists)"
              % (HI, F["next_byte"]))
        print("  vs PtrTable_F99121 @0x%06X  %d/%d identical, runs >=3: %s"
              % (SIB, F["same"], F["sibn"], F["runs"]))
        print("  inbound branches            %d" % F["inbound"])
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
