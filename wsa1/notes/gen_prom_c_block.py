#!/usr/bin/env python3
"""Build the byte-exact listing for one prom_c address range, tables and all.

Defaults to 0xFA7E2C-0xFABE2F, the voice-parameter module it was written for.

QUESTION IT ANSWERS
  "What is the byte-exact source text for the 16,388-byte block that
   notes/FINDINGS-prom_c-voice-module.md ranked as the next module, given that a
   LINEAR disassembly of it is wrong in four places?"

WHY IT EXISTS
  The block embeds FOUR computed-goto tables (notes/prom_c_jumptables.py).  A linear
  decode turns their pointer bytes into instructions; worse, the surrounding branch
  displacements then get relabelled against those phantom boundaries, and the first
  attempt at this block rebuilt 0xFA9024 as 0x26 where the ROM holds 0x25.  So the
  range is cut into alternating CODE and TABLE segments, each code segment decoded
  from its own start, each table emitted as `.long`.

  Every code segment goes through notes/llvm_roundtrip_autoforce.py, which assembles
  its own output and compares it with the ROM before printing, and the whole result
  goes through notes/prom_c_verify_fragment.py.  Nothing here is trusted on sight.

SEGMENT BOUNDARIES -- where they come from
  The four tables are found by prom_c_jumptables.py from the dispatch idiom, and each
  is bounded on the left by the `add XWA,0x00TTTTTT` immediate and on the right by
  (guard + 1) * 4, with the guard read out of the `cp WA,n` before the `jr UGT`.  The
  two readings agree on all four (`python3 notes/prom_c_jumptables.py 0xFA7E2C
  0xFABE30`).  The module's own ends are `ret` at 0xFA7E2B and `link XIZ` at both
  0xFA7E2C and 0xFABE30.

RUN
  python3 notes/gen_prom_c_block.py > /tmp/vp.s
  python3 notes/gen_prom_c_block.py --start 0xFA5949 --end 0xFA7E2C > /tmp/vp2.s
  python3 notes/prom_c_verify_fragment.py c 0xFA7E2C /tmp/vp.s

  ⚠ Set VP_CACHE=<dir> to cache the (slow) llvm round trip per segment while
  iterating.  The cache is keyed on the segment bounds and holds the wrapper's own
  byte-verified output, so a cached run proves exactly what a cold run proves.
"""
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
NOTES = os.path.join(ROOT, "notes")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
IMG = open(ROM, "rb").read()

START, END = 0xFA7E2C, 0xFABE30
PREFIX = "KX"
for _i, _a in enumerate(sys.argv):
    if _a == "--start":
        START = int(sys.argv[_i + 1], 0)
    elif _a == "--end":
        END = int(sys.argv[_i + 1], 0)
    elif _a == "--prefix":
        PREFIX = sys.argv[_i + 1]


def table_segments():
    """The embedded computed-goto tables, from prom_c_jumptables.py's own scan."""
    sys.path.insert(0, NOTES)
    import prom_c_jumptables as jt
    out = []
    for _, tbl, guard, n, _ in jt.tables():
        if START <= tbl < END:
            assert guard is not None and guard + 1 == n, (hex(tbl), guard, n)
            out.append((tbl, tbl + 4 * n))
    return sorted(out)


def segments():
    """[(kind, lo, hi)] covering START..END with no gap and no overlap."""
    segs, cur = [], START
    for lo, hi in table_segments():
        if lo > cur:
            segs.append(("code", cur, lo))
        segs.append(("table", lo, hi))
        cur = hi
    if cur < END:
        segs.append(("code", cur, END))
    assert segs[0][1] == START and segs[-1][2] == END
    for a, b in zip(segs, segs[1:]):
        assert a[2] == b[1], (a, b)
    return segs


CACHE = os.environ.get("VP_CACHE")


def code_listing(lo, hi, prefix):
    if CACHE:
        cf = os.path.join(CACHE, "raw_%06X_%06X.s" % (lo, hi))
        if os.path.exists(cf):
            raw_out = open(cf).read()
            pretty = subprocess.run([sys.executable, os.path.join(NOTES, "prom_c_listing_prep.py"),
                                     "/dev/stdin", "--prefix", prefix],
                                    input=raw_out, capture_output=True, text=True, cwd=ROOT)
            if pretty.returncode:
                sys.stderr.write(pretty.stderr)
                raise SystemExit("listing prep failed for 0x%06X-0x%06X" % (lo, hi))
            return pretty.stdout
    raw = subprocess.run([sys.executable, os.path.join(NOTES, "llvm_roundtrip_autoforce.py"),
                          "c", hex(lo), hex(hi - lo), "--quiet"],
                         capture_output=True, text=True, cwd=ROOT)
    if raw.returncode:
        sys.stderr.write(raw.stderr)
        raise SystemExit("round-trip failed for 0x%06X-0x%06X" % (lo, hi))
    if CACHE:
        os.makedirs(CACHE, exist_ok=True)
        open(os.path.join(CACHE, "raw_%06X_%06X.s" % (lo, hi)), "w").write(raw.stdout)
    pretty = subprocess.run([sys.executable, os.path.join(NOTES, "prom_c_listing_prep.py"),
                             "/dev/stdin", "--prefix", prefix],
                            input=raw.stdout, capture_output=True, text=True, cwd=ROOT)
    if pretty.returncode:
        sys.stderr.write(pretty.stderr)
        raise SystemExit("listing prep failed for 0x%06X-0x%06X" % (lo, hi))
    return pretty.stdout


def table_listing(lo, hi):
    n = (hi - lo) // 4
    out = ["; %d x u32 computed-goto table, 0x%06X-0x%06X, %d bytes."
           % (n, lo, hi - 1, hi - lo),
           "; THE ENTRY COUNT IS ESTABLISHED TWICE AND THE TWO AGREE: the `cp rr,%d`"
           % (n - 1),
           "; guard before the `jr UGT` gives %d, and reading consecutive words while"
           % n,
           "; each is a plausible code address also gives %d.  The word after the last" % n,
           "; entry is not a plausible entry, so the table ends here rather than being",
           "; assumed to.  (python3 notes/prom_c_jumptables.py 0x%06X 0x%06X;" % (START, END),
           "; asserted per table by notes/prom_c_voiceparam_checks.py section 2.)",
           "; Entry 0 is the SAME address the out-of-range guard branches to."]
    for k in range(n):
        v = struct.unpack_from("<I", IMG, lo - BASE + 4 * k)[0]
        out.append("\t.long 0x%08X\t; 0x%06X  entry %d -> 0x%06X%s"
                   % (v, lo + 4 * k, k, v, "   (also the out-of-range arm)" if k == 0 else ""))
    return "\n".join(out) + "\n"


def boundary_check(text, tabs):
    """★ THE DECODE-ALIGNMENT TEST.  Every address DECODED CODE transfers to inside
    this range must be an instruction boundary in the listing.

    A round trip proves the listing rebuilds the bytes; it does NOT prove it decoded
    them at the right offsets, because a misaligned decode of data can re-encode to
    the same bytes.  This is the independent check: if the ROM says `call 0xFA7F28`,
    then 0xFA7F28 must be the start of a line.  A run of embedded data shifts every
    boundary after it and this fires at once -- it is what would have caught the four
    computed-goto tables without waiting for the fragment verifier.

    ⚠ THE SITES ARE TAKEN FROM DECODED INSTRUCTIONS ONLY -- the `; ADDR  <text>`
    comments of prom_c/wsa1_prom_c.s and of this listing -- never from a byte-pattern
    scan.  A raw scan for `1D`/`1E` finds hits inside longer instructions: at
    0xFA8972 the `1E` is the displacement byte of the `jr` at 0xFA8971, and reading
    it as a `calr` invents a call to 0xFA8813.  Six such phantoms appeared the first
    time this check was written, and every one of them was a byte pattern, not an
    instruction.

    ⚠ Targets inside a computed-goto table are skipped -- those bytes are `.long` and
    have no instruction boundary by construction.
    """
    def decoded(lines):
        out = []
        for ln in lines:
            m = re.search(r';\s*([0-9A-F]{6})\s\s(.*)$', ln)
            if m:
                out.append((int(m.group(1), 16), m.group(2)))
        return out

    mine = decoded(text.splitlines())
    bounds = {a for a, _ in mine}
    src = decoded(open(image_path(ROOT, "prom_c/wsa1_prom_c.s")).read().splitlines())
    XFER = re.compile(r'^(?:call|calr|jp|jrl|jr)\b.*?0x([0-9a-f]{6})\s*$')
    bad, seen = [], set()
    for site, txt in mine + src:
        m = XFER.match(txt.strip())
        if not m:
            continue
        t = int(m.group(1), 16)
        if not (START < t < END):
            continue
        if any(lo <= t < hi for lo, hi in tabs):
            continue
        seen.add(t)
        if t not in bounds:
            bad.append((t, site, txt.strip()))
    if bad:
        sys.stderr.write("DECODE-ALIGNMENT FAILURE: %d transfer target(s) inside "
                         "0x%06X-0x%06X are not instruction boundaries\n"
                         % (len(bad), START, END - 1))
        for t, site, txt in bad[:20]:
            sys.stderr.write("    0x%06X  from 0x%06X  %s\n" % (t, site, txt))
        raise SystemExit(1)
    sys.stderr.write("decode-alignment: all %d distinct transfer target(s) inside "
                     "0x%06X-0x%06X, from decoded instructions only, are instruction "
                     "boundaries\n" % (len(seen), START, END - 1))


BARE = re.compile(r'^(?P<m>jrl?|jp)\s+(?:(?P<cc>[a-z]+),\s*)?(?P<op>0x[0-9A-F]+|-?\d+)$')
TGT = re.compile(r'0x([0-9a-f]{6})\s*$')


def cross_segment_labels(text):
    """Give a branch that jumps ACROSS a table a label, like every other branch.

    notes/prom_c_listing_prep.py labels branch targets within ONE decoded segment.
    A range containing a computed-goto table is decoded as several segments, so a
    `jrl` from one segment to another keeps the raw displacement the round trip
    produced.  That assembles to the same bytes -- the byte gate and the fragment
    verifier both pass either way -- but it leaves a control transfer whose target
    only the trailing comment names, and notes/prom_c_frontier_src.py's completeness
    check reports it as an unmatched literal, which makes every count it prints
    suspect.  Eight such lines survived the 0xFB828E-0xFC3406 conversion.

    The rewrite is spelling only: the operand becomes a label, and the label is
    defined at the address unidasm's own text names.  If that address were wrong the
    displacement would change and prom_c_verify_fragment.py would fail on the next
    run -- which is why this is safe to do mechanically.
    """
    lines = text.split("\n")
    addr_line = {}
    for i, ln in enumerate(lines):
        m = re.search(r';\s*([0-9A-F]{6})\s\s', ln)
        if m:
            addr_line.setdefault(int(m.group(1), 16), i)
    wanted = {}
    for i, ln in enumerate(lines):
        m = re.match(r'^\t(?P<code>.*?)\s*;\s*[0-9A-F]{6}\s\s(?P<txt>.*)$', ln)
        if not m:
            continue
        b = BARE.match(m.group("code").replace("\t", " ").strip())
        if not b:
            continue
        t = TGT.search(m.group("txt"))
        if not t:
            continue
        tgt = int(t.group(1), 16)
        if not (START <= tgt < END) or tgt not in addr_line:
            continue
        name = "%s_%06X" % (PREFIX, tgt)
        lines[i] = ln.replace(m.group("code"),
                              "%s %s%s" % (b.group("m"),
                                           (b.group("cc") + ", ") if b.group("cc") else "",
                                           name), 1)
        wanted[tgt] = name
    for tgt, name in sorted(wanted.items(), reverse=True):
        i = addr_line[tgt]
        if i > 0 and lines[i - 1].strip() == name + ":":
            continue
        lines.insert(i, name + ":")
    if wanted:
        sys.stderr.write("cross-segment labels: %d branch target(s) across a table span "
                         "given a label (%s)\n"
                         % (len(wanted), " ".join("0x%06X" % t for t in sorted(wanted))))
    return "\n".join(lines)


def main():
    out, tabs = [], []
    for kind, lo, hi in segments():
        if kind == "code":
            out.append(code_listing(lo, hi, PREFIX))
        else:
            tabs.append((lo, hi))
            out.append(table_listing(lo, hi))
    text = cross_segment_labels("".join(out))
    boundary_check(text, tabs)
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
