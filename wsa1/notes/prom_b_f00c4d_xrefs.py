#!/usr/bin/env python3
"""Does ANYTHING reach prom_b's 0xF00C00-0xF017FF cluster?

QUESTION IT ANSWERS
    notes/gen_prom_b_f00c4d_module.py converts that span and rests part of its
    reading on claim N1, "nothing in the image reaches this cluster".  N1 is a
    NEGATIVE, and a negative from a search is exactly the kind of answer this
    project has repeatedly found to be an instrument failure rather than a fact.
    So this script asks it twice, by two independent instruments, and prints a
    POSITIVE CONTROL for each so a silent zero cannot be mistaken for evidence.

    ⚠ THE CONTROL IS THE POINT.  While this was being written, `grep -ao
    'f00c[0-9a-f][0-9a-f]' prom_*.s` returned 0 matches on files a Python read
    with encoding='latin-1' shows 32 in.  (This environment resolves `grep` to
    ugrep.)  Had the control not been run, "no references" would have been
    reported from an instrument that was returning zero for everything.

THE TWO INSTRUMENTS
  1. SOURCE.  Every line of all four images' converted assembly (through
     notes/asm_source.py, so `.include`d parts are not missed), scanned for a
     hex address in 0xF00C00-0xF017FF.  This sees what the tree has already
     decoded, including operands that only appear in the `; ADDR  <mame text>`
     decode comments.  TWO EXCLUSIONS, both stated in source_hits() and both
     counted and printed rather than applied silently: whole-line COMMENTS
     (prose about the range is not a reference into it) and lines whose own
     `; ADDR` is inside the range (the cluster's own internal branches cannot
     be evidence that anything reaches it).
  2. ROM BYTES.  Every 32-bit little-endian word and every 24-bit little-endian
     byte triple in prom_a and prom_b, for a value in the same range.  This sees
     what the tree has NOT decoded -- the 24-bit operand of a `jp`/`call`, a
     pointer in an unframed table -- which instrument 1 by construction cannot.

RUN
    python3 notes/prom_b_f00c4d_xrefs.py
    python3 notes/prom_b_f00c4d_xrefs.py --selftest   # exits 1 if N1 breaks
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402

IMAGES = [("prom_a/wsa1_prom_a.s", "original_ROMs/wsa1_prom_a.ic12", 0xF80000),
          ("prom_b/wsa1_prom_b.s", "original_ROMs/wsa1_prom_b.ic13", 0xF00000),
          ("prom_c/wsa1_prom_c.s", "original_ROMs/wsa1_prom_c.ic28", 0xF80000),
          ("prom_d/wsa1_prom_d.s", None, 0)]

LO, HI = 0xF00C00, 0xF01800          # the cluster: the span plus the 0xF00C46 array
# The one line in the tree that legitimately names the range: the coverage-round
# banner that records the span as unconverted.  It is prose, not a reference.
BANNER = "coverage round 1"

# POSITIVE CONTROLS -- addresses that certainly ARE referenced, so a zero result
# from either instrument is visibly an instrument failure and not a finding.
CTRL_SRC = 0xF40ED4        # called from prom_b's own converted code


WHOLE_LINE_COMMENT = re.compile(r'^\s*;')


def source_hits(lo, hi):
    """(file, line, text) for every CODE line of the four images whose text names
    an address in [lo,hi) -- including the `; ADDR  <mame text>` decode comment
    that trails an instruction, which is where prom_b's operands are legible.

    ⚠ WHOLE-LINE COMMENTS ARE EXCLUDED, and that is not a convenience.  Prose
    ABOUT a range is not a reference INTO it, and once a range is converted its
    own header block names it dozens of times: the module block this script
    supports made a self-scan report 86 "references", every one of them a line
    of its own documentation.  A census that counts its own subject's name is
    measuring the wrong thing.  Returns the prose count separately so the
    exclusion is visible rather than silent.
    """
    rx = re.compile(r'0x([0-9a-fA-F]{6})')
    own = re.compile(r';\s*([0-9A-F]{6})\s')
    out, prose, inside = [], 0, 0
    for src, _rom, _b in IMAGES:
        for i, ln in enumerate(image_lines(ROOT, src)):
            if not rx.search(ln):
                continue
            # ⚠ A LINE THAT LIVES IN THE RANGE CANNOT BE EVIDENCE THAT SOMETHING
            # REACHES IT.  Once the cluster is converted its own 54 internal
            # branches decode as `jr T,0xf0102e` and would be counted as
            # references to itself.  N1 asks about the world OUTSIDE it.
            m0 = own.search(ln)
            if m0 and lo <= int(m0.group(1), 16) < hi:
                inside += 1
                continue
            for m in rx.finditer(ln):
                v = int(m.group(1), 16)
                if lo <= v < hi:
                    if WHOLE_LINE_COMMENT.match(ln):
                        prose += 1
                    else:
                        out.append((src, i + 1, ln.strip()))
    return out, prose, inside


def rom_hits(lo, hi):
    """(rom, addr, value, kind) for every raw-byte reference into [lo,hi).

    TWO KINDS, and they are not equally strong:
      le32  a 32-bit little-endian word.  Cheap and noisy -- a 4-byte window
            sliding over display-list data hits any range by accident.
      jpcal a 24-bit operand of `jp imm24` (0x1B) or `call imm24` (0x1D), i.e.
            the byte BEFORE the operand is that opcode.  This is the one that
            answers "does anything transfer control into the range", and it is
            how the 1,910-slot routine directory names everything it reaches.
    """
    out = []
    for _src, rom, base in IMAGES:
        if not rom:
            continue
        d = open(os.path.join(ROOT, rom), "rb").read()
        for o in range(1, len(d) - 3):
            v32 = d[o] | d[o + 1] << 8 | d[o + 2] << 16 | d[o + 3] << 24
            v24 = v32 & 0xFFFFFF
            if lo <= v32 < hi:
                out.append((rom, base + o, v32, "le32"))
            if lo <= v24 < hi and d[o - 1] in (0x1B, 0x1D):
                out.append((rom, base + o - 1, v24, "jpcal"))
    return out


DATA_DIRECTIVE = re.compile(r'^\s*\.(byte|long|short|word|ascii|asciz|fill|zero|incbin)\b')


def instruction_lines(src):
    """{addr: line} for every line of an image's source that is an INSTRUCTION --
    i.e. carries a `; ADDR` decode comment and is not a data directive.

    ⚠ WITHOUT THE DATA FILTER THIS IS USELESS HERE.  Both `.byte` data rows and
    instruction rows carry `; ADDR`, and every false positive this script had to
    reject was a byte inside data that happened to read as `jp`/`call`.
    """
    rx = re.compile(r';\s*([0-9A-F]{6})\s')
    out = {}
    for ln in image_lines(ROOT, src):
        if DATA_DIRECTIVE.match(ln):
            continue
        m = rx.search(ln)
        if m:
            out[int(m.group(1), 16)] = ln.strip()
    return out


def covering_line(src, addr):
    """The source line whose `; ADDR` is the nearest at or below addr."""
    rx = re.compile(r';\s*([0-9A-F]{6})\s')
    best = None
    for ln in image_lines(ROOT, src):
        m = rx.search(ln)
        if m:
            a = int(m.group(1), 16)
            if a <= addr and (best is None or a > best[0]):
                best = (a, ln.strip())
    return best


def main():
    print("POSITIVE CONTROLS -- a zero here means the instrument is broken")
    cs, _, _ = source_hits(CTRL_SRC, CTRL_SRC + 1)
    print("  source scan sees 0x%06X                       %d hits" % (CTRL_SRC, len(cs)))
    reach = rom_hits(0xF00000, 0xF00C00)
    nj = sum(1 for h in reach if h[3] == "jpcal")
    nw = sum(1 for h in reach if h[3] == "le32")
    print("  rom scan sees 0xF00000-0xF00BFF, the SAME PAGE that")
    print("    the round-1 walk did reach:  %d jp/call imm24, %d le32 words" % (nj, nw))
    ok = len(cs) > 0 and nj > 0

    print("\nREFERENCES INTO 0x%06X-0x%06X" % (LO, HI - 1))
    sh_all, prose, inside = source_hits(LO, HI)
    sh = [h for h in sh_all if BANNER not in h[2]]
    print("  from converted source (code lines):             %d" % len(sh))
    print("    (%d further mentions are whole-line COMMENTS -- this module's own"
          " documentation and the round-1 banner talking ABOUT the range, not"
          " into it; %d further lines LIVE in the range -- its own internal"
          " branches)" % (prose, inside))
    for s_, n, t in sh[:20]:
        print("      %s:%d  %s" % (s_, n, t[:110]))
    rh = rom_hits(LO, HI)
    jp = [h for h in rh if h[3] == "jpcal"]
    w32 = [h for h in rh if h[3] == "le32"]
    loop = [h for h in w32 if 0xF00340 <= h[1] < 0xF003C8]
    other = [h for h in w32 if not (0xF00340 <= h[1] < 0xF003C8)]
    # ⚠ A BYTE THAT READS AS `jp`/`call` IS NOT AN INSTRUCTION.  Each candidate
    # is checked against the image's own converted source: confirmed only if the
    # opcode address is on an INSTRUCTION line there.  All four candidates found
    # on 2026-09-02 were bytes inside data -- two inside a `.byte` bitmap row in
    # prom_b's font area, two the immediate of `ld (XIX+0x01),0x1b` followed by
    # the first three bytes of `ldb_da c,(0x60f014)` in prom_a.
    SRC_OF = {"original_ROMs/wsa1_prom_a.ic12": "prom_a/wsa1_prom_a.s",
              "original_ROMs/wsa1_prom_b.ic13": "prom_b/wsa1_prom_b.s"}
    ins = {k: instruction_lines(v) for k, v in SRC_OF.items()}
    confirmed = [h for h in jp if h[1] in ins.get(h[0], {})]
    print("  jp/call imm24 candidates into the range:        %d" % len(jp))
    for r, a, v, k in jp[:20]:
        cov = covering_line(SRC_OF[r], a)
        verdict = "CONFIRMED INSTRUCTION" if a in ins.get(r, {}) else "coincidence, inside"
        print("      %s %06X -> %06X  %s: %s"
              % (os.path.basename(r), a, v, verdict, (cov[1][:70] if cov else "?")))
    print("  ★ of those, real instructions:                   %d" % len(confirmed))
    print("  le32 words inside the cluster's OWN dispatch table 0xF00340: %d" % len(loop))
    print("  le32 words anywhere else:                       %d" % len(other))
    print("    -- not claimed to be zero: a sliding 4-byte window over display-list")
    print("       data hits any range by accident.  %d distinct values, and none of"
          % len({v for _r, _a, v, _k in other}))
    print("       them is a jp/call target, which is the line above.")

    if "--selftest" in sys.argv:
        bad = []
        if not ok:
            bad.append("a positive control returned zero")
        if sh:
            bad.append("%d converted-source references appeared" % len(sh))
        if confirmed:
            bad.append("%d real jp/call imm24 now enter the range" % len(confirmed))
        if not loop:
            bad.append("the cluster's own dispatch table no longer points into it")
        print("\n" + ("PASS" if not bad else "FAIL: " + "; ".join(bad)))
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
