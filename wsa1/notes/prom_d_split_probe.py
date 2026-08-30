#!/usr/bin/env python3
"""prom_d's three-way split -- the proof that it MOVED lines and did not edit them.

WHAT QUESTION THIS ANSWERS
--------------------------
  "Did splitting prom_d/wsa1_prom_d.s into a header plus tone_database_directory.s
   / tone_database_records.s / tone_database_aux.s lose a comment, a label or a
   byte -- or reorder anything?"

  The byte gate (scripts/analysis/assert_byte_identical.py) answers the LAST of
  those and nothing else: comments and labels assemble to nothing, so a split
  that silently dropped a 30-line provenance banner would leave the gate green.
  This script is the other half, and it is the half that matters for a file
  whose value is 24,000 comment lines.

HOW THE BASELINE IS OBTAINED -- and why it is not a pinned copy
---------------------------------------------------------------
  scripts/analysis/gen_prom_d_asm.py emits the four files.  Run with
  `--monolithic` it emits the SAME region bodies as one file with one header --
  byte-for-byte the file that stood before the split.  So the baseline is
  RE-DERIVED on every run rather than checked in, and it cannot drift away from
  the emitter the way a stored copy would.

  ⚠ THAT ALONE WOULD BE CIRCULAR, because both sides come from one generator: a
  region dropped from the region table would vanish from both.  So Q3 does not
  trust the generator at all.  It re-assembles the four files with a 40-line
  mini-assembler for the five directives prom_d uses (.byte/.short/.long/
  .ascii/.fill) and compares the result with original_ROMs/wsa1_prom_d.bin.
  That closes the loop against the ROM without llvm-mc.

WHAT IS CHECKED
  Q1  ALIGNMENT: the four files, concatenated in .include order, contain every
      line of the monolithic rendering, in order, unaltered.  The diff must be
      INSERTIONS ONLY -- 0 deletions, 0 replacements.  Every inserted line is
      printed and must be part of a new file header or an .include directive.
  Q2  CENSUS: labels and comment lines, before vs after, with the delta
      explained line by line.  Not a total -- a multiset comparison, so a label
      that moved between files but was also silently duplicated would fail.
  Q3  BYTES: the split re-assembles to the ROM (mini-assembler, no toolchain).
  Q4  BOUNDARIES: both cut points are the ones the image's own directory
      supplies -- MEL[0] from the tone-record offset table at slot +0x08, and
      slot +0xAC -- and the three parts tile 0x00000-0x7FFFF with no gap or
      overlap.

    python3 notes/prom_d_split_probe.py             # the proof
    python3 notes/prom_d_split_probe.py --selftest  # ★ the instrument's controls

★ --selftest PINS NO NUMBER.  It builds a synthetic three-part split of a
  synthetic listing and requires that (a) a faithful split passes all four
  checks and (b) each of four specific corruptions FAILS: a deleted comment
  line, a deleted label, two parts swapped, and one byte changed.  A checker
  that cannot fail is not a check.
"""
import collections
import difflib
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines, image_files     # noqa: E402

PRIMARY = "prom_d/wsa1_prom_d.s"
PARTS = ["tone_database_directory.s", "tone_database_records.s",
         "tone_database_aux.s"]
GEN = os.path.join(ROOT, "scripts", "analysis", "gen_prom_d_asm.py")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin")

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z_0-9]*):")


def _iscomment(ln):
    """A comment line, indented or not.  prom_d has 299 indented ones."""
    return ln.lstrip().startswith(";")


INCLUDE_RE = re.compile(r'^\s*\.include\s+"([^"]+)"')

FAILS = []


def check(name, cond, detail=""):
    print("  %s  %s%s" % ("PASS" if cond else "FAIL", name,
                          ("   " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


# ---------------------------------------------------------------------------
# Q3's mini-assembler.  prom_d uses exactly five directives and no .org and no
# .align, so its layout is the concatenation of the emitted bytes in file order.
# Deliberately NOT llvm-mc: this must be able to disagree with the toolchain.
# ---------------------------------------------------------------------------
_NUM = re.compile(r"0x[0-9A-Fa-f]+|\d+")


def assemble(lines):
    out = bytearray()
    for ln in lines:
        body = ln.split("\t;")[0].rstrip()
        s = body.strip()
        if not s.startswith("."):
            continue
        d, _, rest = s.partition(" ")
        if d == ".byte":
            out += bytes(int(v, 0) for v in _NUM.findall(rest))
        elif d == ".short":
            for v in _NUM.findall(rest):
                out += struct.pack("<H", int(v, 0))
        elif d == ".long":
            for v in _NUM.findall(rest):
                out += struct.pack("<I", int(v, 0))
        elif d == ".ascii":
            m = re.match(r'^"(.*)"$', rest.strip())
            assert m, "unparsed .ascii: %r" % ln
            out += m.group(1).encode("latin1")
        elif d == ".fill":
            n, sz, val = (int(v, 0) for v in _NUM.findall(rest)[:3])
            assert sz == 1, "only byte fills are handled: %r" % ln
            out += bytes([val]) * n
        elif d == ".text":
            pass
        else:
            raise AssertionError("unhandled directive %r in %r" % (d, ln))
    return bytes(out)


def monolithic():
    r = subprocess.run([sys.executable, GEN, "--monolithic"],
                       cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr[-3000:]
    return r.stdout.split("\n")


def q1(before, after):
    print("\n=== Q1.  ALIGNMENT -- insertions only ===\n")
    sm = difflib.SequenceMatcher(a=before, b=after, autojunk=False)
    dele = repl = 0
    inserted = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "delete":
            dele += i2 - i1
        elif tag == "replace":
            repl += max(i2 - i1, j2 - j1)
        elif tag == "insert":
            inserted.extend(after[j1:j2])
    check("Q1a  no line of the pre-split file was DELETED", dele == 0,
          "%d deleted" % dele)
    check("Q1b  no line was ALTERED (a replace is an edit wearing a move's "
          "clothes)", repl == 0, "%d replaced" % repl)
    check("Q1c  the pre-split order is preserved exactly",
          dele == 0 and repl == 0)
    body = [l for l in inserted if l.strip() and not _iscomment(l)]
    check("Q1d  every inserted line is a COMMENT or blank -- the split adds "
          "headers and nothing else", not body,
          "%d other: %s" % (len(body), [l.strip() for l in body][:4]))
    # ⚠ THE .include LINES ARE NOT IN `after`: image_lines EXPANDS them, which is
    # the point -- the expansion is what must equal the pre-split file.  So they
    # are checked where they actually live, in the primary, unexpanded.
    own = open(os.path.join(ROOT, PRIMARY), encoding="utf-8").read().split("\n")
    incs = [m.group(1) for l in own for m in [INCLUDE_RE.match(l)] if m]
    check("Q1e  the primary .includes exactly the %d parts, in address order"
          % len(PARTS), incs == PARTS, str(incs))
    print("  %d line(s) inserted in total: %d comment, %d blank."
          % (len(inserted), sum(1 for l in inserted if _iscomment(l)),
             sum(1 for l in inserted if not l.strip())))
    return inserted


def q2(before, after, inserted):
    print("\n=== Q2.  CENSUS -- labels and comments, before vs after ===\n")
    lb = collections.Counter(m.group(1) for l in before
                             for m in [LABEL_RE.match(l)] if m)
    la = collections.Counter(m.group(1) for l in after
                             for m in [LABEL_RE.match(l)] if m)
    check("Q2a  every label survives, with the SAME multiplicity", lb == la,
          "lost %s, gained %s"
          % (sorted((lb - la).elements())[:5], sorted((la - lb).elements())[:5]))
    # ⚠ INDENTED comment lines count too.  Anchoring on column 0 would have
    # ignored 299 of prom_d's comment lines and called their loss a pass.
    cb = collections.Counter(l for l in before if _iscomment(l))
    ca = collections.Counter(l for l in after if _iscomment(l))
    check("Q2b  no comment line was lost", not (cb - ca),
          "%d lost, e.g. %r" % (sum((cb - ca).values()),
                                next(iter((cb - ca)), "")))
    gained = ca - cb
    hdr_lines = sum(1 for l in inserted if _iscomment(l))
    check("Q2c  every ADDED comment line is one of the new file headers",
          sum(gained.values()) <= hdr_lines,
          "%d gained, %d inserted by the split"
          % (sum(gained.values()), hdr_lines))
    print("  labels    %s before, %s after" % (format(sum(lb.values()), ","),
                                               format(sum(la.values()), ",")))
    print("  comments  %s before, %s after  (+%s, all header)"
          % (format(sum(cb.values()), ","), format(sum(ca.values()), ","),
             format(sum(ca.values()) - sum(cb.values()), ",")))


def q3(after):
    print("\n=== Q3.  BYTES -- the split re-assembles to the ROM ===\n")
    rom = open(ROM, "rb").read()
    got = assemble(after)
    check("Q3a  the four files assemble to %s bytes" % format(len(rom), ","),
          len(got) == len(rom), "got %s" % format(len(got), ","))
    first = next((i for i, (x, y) in enumerate(zip(rom, got)) if x != y), None)
    check("Q3b  ★ and every one of them is the ROM's", got == rom,
          "first difference at 0x%X" % first if first is not None else "")


def q4():
    print("\n=== Q4.  BOUNDARIES -- both cut points come from the directory ===\n")
    D = open(ROM, "rb").read()
    u32 = lambda o: struct.unpack_from("<I", D, o)[0]
    DIR = [u32(4 * i) for i in range(48)]
    ptrs = [u32(DIR[2] + 4 * i) for i in range(274)]
    cut_rec, cut_aux = min(ptrs[:256]), DIR[0xAC // 4]
    files = [os.path.basename(f) for f in image_files(ROOT, PRIMARY)]
    check("Q4a  the primary .includes exactly the three parts, in address order",
          files[1:] == PARTS, str(files))
    lens = [len(assemble(open(os.path.join(ROOT, "prom_d", p),
                              encoding="utf-8").read().split("\n")))
            for p in PARTS]
    check("Q4b  part 1 ends at the FIRST TONE-RECORD OFFSET in slot +0x08",
          lens[0] == cut_rec, "part 1 is 0x%05X bytes, MEL[0] = 0x%05X"
          % (lens[0], cut_rec))
    check("Q4c  part 2 ends at DIRECTORY SLOT +0xAC (ToneDB_DefaultLayerParams)"
          " -- where ../kn5000-roms-disasm's aux module also starts",
          lens[0] + lens[1] == cut_aux,
          "0x%05X vs slot +0xAC = 0x%05X" % (lens[0] + lens[1], cut_aux))
    check("Q4d  the three parts TILE the image with no gap and no overlap",
          sum(lens) == len(D), "%s vs %s" % (format(sum(lens), ","),
                                             format(len(D), ",")))
    print("  directory 0x00000..0x%05X   records 0x%05X..0x%05X   aux 0x%05X..0x%05X"
          % (cut_rec - 1, cut_rec, cut_aux - 1, cut_aux, len(D) - 1))


# ---------------------------------------------------------------------------
def _synth():
    """A tiny listing and a faithful three-way split of it."""
    mono = ["\t.text", "; header line 1", "; header line 2", "",
            "; ==== part A ====", "LabA:", "\t.byte 0x01, 0x02", "",
            "; ==== part B ====", "LabB:", "\t.short 0x0403", "",
            "; ==== part C ====", "LabC:", '\t.ascii "hi"', "", "the_end:"]
    parts = [mono[4:8], mono[8:12], mono[12:16]]
    primary = mono[0:4] + ["; NEW HEADER"] + [
        '\t.include "p%d.s"' % i for i in range(3)] + ["", "the_end:"]
    return mono, primary, parts


def _flatten(primary, parts):
    out = []
    for ln in primary:
        m = INCLUDE_RE.match(ln)
        if m:
            out.extend(["; NEW PART HEADER"] + parts[int(m.group(1)[1])])
        else:
            out.append(ln)
    return out


def _verdict(mono, flat, rom):
    """The four checks, as booleans, over synthetic input."""
    sm = difflib.SequenceMatcher(a=mono, b=flat, autojunk=False)
    ops = sm.get_opcodes()
    align = not any(t in ("delete", "replace") for t, *_ in ops)
    labs = (collections.Counter(m.group(1) for l in mono
                                for m in [LABEL_RE.match(l)] if m)
            == collections.Counter(m.group(1) for l in flat
                                   for m in [LABEL_RE.match(l)] if m))
    cb = collections.Counter(l for l in mono if _iscomment(l))
    ca = collections.Counter(l for l in flat if _iscomment(l))
    return align, labs, not (cb - ca), assemble(flat) == rom


def _selftest():
    print("=== the instrument's own controls ===\n")
    mono, primary, parts = _synth()
    rom = assemble(mono)
    a, l, c, b = _verdict(mono, _flatten(primary, parts), rom)
    check("T1  a FAITHFUL split passes alignment, labels, comments and bytes",
          a and l and c and b, "%s" % [a, l, c, b])

    bad = [list(p) for p in parts]
    bad[1] = [x for x in bad[1] if x != "; ==== part B ===="]
    a, l, c, b = _verdict(mono, _flatten(primary, bad), rom)
    check("T2  ONE DELETED COMMENT LINE fails alignment and the comment census",
          not a and not c, "align=%s comments=%s" % (a, c))

    bad = [list(p) for p in parts]
    bad[0] = [x for x in bad[0] if x != "LabA:"]
    a, l, c, b = _verdict(mono, _flatten(primary, bad), rom)
    check("T3  ONE DELETED LABEL fails alignment and the label census",
          not a and not l, "align=%s labels=%s" % (a, l))

    swapped = [parts[1], parts[0], parts[2]]
    a, l, c, b = _verdict(mono, _flatten(primary, swapped), rom)
    check("T4  TWO PARTS SWAPPED fails alignment AND the byte check -- order is "
          "load-bearing", not a and not b, "align=%s bytes=%s" % (a, b))

    bad = [list(p) for p in parts]
    bad[0] = [x.replace("0x01", "0x09") for x in bad[0]]
    a, l, c, b = _verdict(mono, _flatten(primary, bad), rom)
    check("T5  ONE CHANGED BYTE fails the byte check", not b, "bytes=%s" % b)

    check("T6  the mini-assembler handles every directive prom_d uses",
          assemble(["\t.byte 0x01", "\t.short 0x0302", "\t.long 0x07060504",
                    '\t.ascii "AB"', "\t.fill 2, 1, 0xFF"])
          == bytes([1, 2, 3, 4, 5, 6, 7, 0x41, 0x42, 0xFF, 0xFF]))


def main():
    if "--selftest" in sys.argv:
        _selftest()
    else:
        print("prom_d three-way split -- did it move lines, or change them?\n")
        before = monolithic()
        after = image_lines(ROOT, PRIMARY)
        ins = q1(before, after)
        q2(before, after, ins)
        q3(after)
        q4()
    print("\nFAILURES: %d" % len(FAILS))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
