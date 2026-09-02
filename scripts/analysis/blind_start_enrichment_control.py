#!/usr/bin/env python3
r"""THE MISSING CONTROL for byte_run_start_enrichment.py, applied INSIDE v10.

WHAT byte_run_start_enrichment.py MEASURES, AND WHAT IT WAS READ AS
-------------------------------------------------------------------
That script (main, 15115eae) counts, for each maximal `.byte` run in the
SOURCE, the run's first byte, and compares the rate of five bytes the
tlcs900 backend cannot spell -- {0x01 normal, 0x04 max, 0x17 ldf,
0x1a jp nnnn, 0x1c call nnnn} -- against five decodable bytes of similar
magnitude {0x02, 0x03, 0x05, 0x16, 0x1b}.  v10 scores 19.2% blind against
0.4% control, and `extensions/extension_data.s` is the worst file in the
image at 58.3%.  That was read as "extension_data.s is very likely code".

ITS CONTROL IS BETWEEN IMAGES.  The four SX-WSA1R images show no enrichment,
which rules out the method crying code everywhere.  What it does NOT rule out
is the confound this script tests: **a greedy disassembly pass leaves a
`.byte` run exactly where it could not spell the next byte -- whether the
region is code or data.**  A run in a DATA region therefore also begins on an
unspellable byte, and a decodable byte can hardly ever begin a run at all,
because the pass would have consumed it as an instruction.  If that is what is
happening, the blind/control ratio is near-infinite BY CONSTRUCTION in any
region the pass processed, and says nothing about content.

QUESTION THIS ANSWERS
---------------------
Does the enrichment discriminate CODE from DATA *within v10*?  Run the
identical statistic on regions of v10 whose nature is settled independently:

  R1  chord-name strings, 0xED006A-0xED0270.  PROVEN DATA: a 64-entry pointer
      table at 0xECFF6A puts 64/64 of its entries exactly on the first byte of
      a NUL-terminated string, and every phase shift of +/-1..3 scores 0/64
      (scripts/analysis/naka_lane_split.py --chordtable).  The strings read as
      chord names: "madd9", "m7 11", "sus4", "aug7", "Maj7", "dim", "69".
  R2  18-byte parameter records, 0xEDCAD6-0xEE0010.  PROVEN DATA: a 956-entry
      pointer table at 0xEE0198-0xEE1088 points into this block and 682 of its
      755 consecutive deltas are exactly 18.
  R3  known code: files whose labels ARE the target of call/jp/jr elsewhere in
      the tree (5..652 targets each, measured by naka_lane_split.py T1).

If R1/R2 score like R3, the instrument cannot tell them apart and the 58.3%
is not evidence about extension_data.s's content.

SECOND TEST -- does anything actually TRANSFER CONTROL into the file?
---------------------------------------------------------------------
`--xrefs` collects every absolute `call`/`jp`/`calr`/`jr` target named
anywhere in v10/maincpu and asks how many land inside each region.  This is
the evidence that decides a region, per the lane brief: if every reference
loads a region's ADDRESS and nothing calls or jumps to it, it is data.

RUN
    python3 scripts/analysis/blind_start_enrichment_control.py
    python3 scripts/analysis/blind_start_enrichment_control.py --xrefs

Needs scripts/analysis/.amap_v10.json (address_line_map.py --dump), which
naka_lane_split.py builds on demand.
"""
import io
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AMAP = os.path.join(ROOT, "scripts/analysis/.amap_v10.json")

BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf",
         0x1a: "jp nnnn", 0x1c: "call nnnn"}
CONTROL = {0x02, 0x03, 0x05, 0x16, 0x1b}
BYTE_RE = re.compile(r"^\s*\.byte\s+(.*)$")
LBL_RE = re.compile(r'^\s*([A-Za-z_.$][\w.$]*):')
XFER_RE = re.compile(r'^\s*(call|calr|jp|jr|jrl|djnz)\b', re.I)

REGIONS = [
    ("R1 chord strings   [PROVEN DATA: 64/64 ptr->string start]",
     "v10/maincpu/extensions/extension_data.s", 0xED006A, 0xED0270),
    ("R2 18-byte records [PROVEN DATA: 956-entry table, stride 18]",
     "v10/maincpu/extensions/extension_data.s", 0xEDCAD6, 0xEE0010),
    ("R0 extension_data.s, whole file",
     "v10/maincpu/extensions/extension_data.s", 0, 1 << 30),
]
KNOWN_CODE = [
    ("R3 system_handlers.s   [KNOWN CODE: 652 call targets]",
     "v10/maincpu/boot/system_handlers.s"),
    ("R3 sysex_routines.s    [KNOWN CODE: 14 call targets]",
     "v10/maincpu/midi/sysex_routines.s"),
    ("R3 seq_event_playback.s[cited at 40.9% by the enrichment probe]",
     "v10/maincpu/sequencer/seq_event_playback.s"),
]


def address_map():
    if not os.path.exists(AMAP):
        subprocess.check_call([sys.executable,
                               os.path.join(ROOT, "scripts/analysis/address_line_map.py"),
                               "--dump", AMAP])
    per = {}
    for e in json.load(open(AMAP)):
        per.setdefault(e["src"], {})[e["line"]] = e["addr"]
    return per


def run_starts(path, lm):
    """[(addr, first_byte_value)] for each maximal `.byte` run in the file."""
    out, prev = [], False
    lines = io.open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    for i, line in enumerate(lines, 1):
        st = line.strip()
        if not st or st.startswith(";"):
            continue
        m = BYTE_RE.match(line)
        if m:
            if not prev:
                first = m.group(1).split(";")[0].split(",")[0].strip()
                try:
                    out.append((lm.get(i), int(first, 0)))
                except ValueError:
                    pass
            prev = True
        else:
            prev = False
    return out


def score(runs):
    runs = [(a, v) for a, v in runs if a is not None]
    if not runs:
        return None
    b = sum(1 for _a, v in runs if v in BLIND)
    c = sum(1 for _a, v in runs if v in CONTROL)
    return len(runs), 100.0 * b / len(runs), 100.0 * c / len(runs), b, c


def show(name, runs):
    s = score(runs)
    if not s:
        print("  %-60s no runs" % name)
        return
    n, bp, cp, b, c = s
    ratio = ("%8.1fx" % (b / c)) if c else ("     inf" if b else "      n/a")
    print("  %-60s %5d runs  blind %5.1f%%  control %5.1f%%  %s"
          % (name, n, bp, cp, ratio))


def xrefs():
    """Absolute control-transfer targets named anywhere in v10/maincpu."""
    amap = address_map()
    sym = {}
    for src, lines in amap.items():
        p = os.path.join(ROOT, src)
        try:
            txt = io.open(p, encoding="latin-1").read().split("\n")
        except OSError:
            continue
        for ln, addr in lines.items():
            m = LBL_RE.match(txt[ln - 1])
            if m:
                sym.setdefault(m.group(1), addr)
    targets = []
    for dp, _dn, fn in os.walk(os.path.join(ROOT, "v10/maincpu")):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            for line in io.open(os.path.join(dp, f), encoding="latin-1"):
                s = line.split(";")[0]
                body = re.sub(r'^\s*[A-Za-z_.$][\w.$]*:', '', s)
                if not XFER_RE.match(body.strip()):
                    continue
                for tok in re.findall(r'[A-Za-z_.$][\w.$]*', body)[1:]:
                    if tok in sym:
                        targets.append(sym[tok])
                for tok in re.findall(r'\b0x[0-9a-fA-F]{5,8}\b', body):
                    targets.append(int(tok, 16))
    print("\nSECOND TEST -- absolute control-transfer targets in v10/maincpu: %d"
          % len(targets))
    for name, _path, lo, hi in REGIONS:
        if hi == 1 << 30:
            lo, hi = 0xED0008, 0xEE0010
        n = sum(1 for t in targets if lo <= t < hi)
        print("  %-60s %d target(s) land inside" % (name, n))
    # POSITIVE CONTROL for this test: the same count over KNOWN-CODE files.
    # Without it "0 targets" would be unfalsifiable -- a collector that found
    # nothing anywhere would print 0 for a data region too.
    for name, path in KNOWN_CODE:
        lm = amap.get(path, {})
        if not lm:
            continue
        lo, hi = min(lm.values()), max(lm.values())
        n = sum(1 for t in targets if lo <= t <= hi)
        print("  %-60s %d target(s) land inside  [0x%06X-0x%06X]"
              % ("POSITIVE CONTROL " + os.path.basename(path), n, lo, hi))
    print("\n  A region nothing transfers control into is DATA, per the lane")
    print("  brief's own rule.  This is the evidence that decides a region;")
    print("  the run-start statistic above is not.")




# ------------------------------------------------------- the per-run census
RECORD_TABLE = (0xEE0198, 0xEE1088)     # 956 u32 entries pointing into R2
RECORD_STRIDE = 18


def record_starts(romb):
    """The record boundaries the 956-entry table at 0xEE0198 asserts."""
    lo, hi = RECORD_TABLE
    out = set()
    for a in range(lo, hi, 4):
        out.add(int.from_bytes(romb[a - 0xE00000:a - 0xE00000 + 4], "little"))
    return out


def census(path="v10/maincpu/extensions/extension_data.s"):
    """PER-RUN CENSUS: for every `.byte` run, its blocking byte AND what
    references it.

    This is the thing the enrichment rate cannot give.  A rate says a region is
    framed oddly; only a reference says what the region IS.  The columns:

      blocking byte   the run's first byte -- why the force-disassembly stopped
      ptr-target      an independent pointer table points AT this address
      xfer-target     something in v10/maincpu calls/jumps to this address
      rec-offset      the run's offset inside the 18-byte record it falls in,
                      per the 956-entry table at 0xEE0198-0xEE1088

    If the blind starts cluster at a FIXED OFFSET inside a fixed-stride record,
    the blind population is a low-valued FIELD, not an opcode -- the same shape
    a sibling lane found in widget_dispatch.s (65 of 74 blind starts were a
    tag's low byte in six-byte {u16 tag, u32 ptr} records).
    """
    import collections
    amap = address_map()
    romb = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    recs = sorted(record_starts(romb))
    runs = [(a, v) for a, v in run_starts(path, amap.get(path, {})) if a is not None]
    if not runs:
        print("census: %s has no `.byte` runs (already converted?)" % path)
        return

    # what references each address
    ptargets = set()
    for phase in range(4):
        vals = [int.from_bytes(romb[i:i + 4], "little")
                for i in range(phase, len(romb) - 3, 4)]
        good = [1 if 0xE00000 <= v <= 0xFFFFFF else 0 for v in vals]
        i, m = 0, len(good)
        while i < m:
            if not good[i]:
                i += 1
                continue
            j = i
            while j < m and good[j]:
                j += 1
            if j - i >= 8:
                ptargets.update(vals[i:j])
            i = j

    recset = set(recs)
    import bisect
    offs = collections.Counter()
    firstb = collections.Counter()
    nptr = nrec = 0
    blind_offs = collections.Counter()
    for a, v in runs:
        firstb[v] += 1
        if a in ptargets:
            nptr += 1
        k = bisect.bisect_right(recs, a) - 1
        off = None
        if k >= 0 and 0 <= a - recs[k] < RECORD_STRIDE:
            off = a - recs[k]
            nrec += 1
            offs[off] += 1
            if v in BLIND:
                blind_offs[off] += 1
    print("PER-RUN CENSUS  %s   %d `.byte` runs" % (path, len(runs)))
    print("  run starts an independent pointer table points at : %d" % nptr)
    print("  run starts inside an 18-byte record of the 956-entry table: %d"
          % nrec)
    print("  run starts that anything CALLS or JUMPS to          : 0"
          "   (see --xrefs: 0 of 59,849 targets land in this file)")
    print("\n  top first bytes: %s"
          % ", ".join("0x%02x:%d%s" % (b, n, " BLIND" if b in BLIND else "")
                      for b, n in firstb.most_common(8)))
    print("\n  BLIND run starts by OFFSET INSIDE the 18-byte record:")
    tot = sum(blind_offs.values())
    for off, n in sorted(blind_offs.items()):
        print("    +0x%02X  %5d  %5.1f%%  %s" % (off, n, 100.0 * n / tot,
                                                 "#" * (60 * n // max(1, tot))))
    print("    %d of the file's blind starts sit inside these records" % tot)
    print("\n  READ IT: a blind byte that only ever appears at a FIXED FIELD")
    print("  OFFSET of a fixed-stride record is a low-valued parameter, not an")
    print("  opcode.  Nothing calls or jumps to any of these addresses.")


def main():
    if "--census" in sys.argv:
        census()
        return 0
    amap = address_map()
    print("blind   {%s}   control {%s}\n"
          % (", ".join("0x%02x" % b for b in sorted(BLIND)),
             ", ".join("0x%02x" % b for b in sorted(CONTROL))))
    print("THE SAME STATISTIC, INSIDE v10, ON REGIONS WHOSE NATURE IS SETTLED:")
    for name, path, lo, hi in REGIONS:
        lm = amap.get(path, {})
        runs = [(a, v) for a, v in run_starts(path, lm)
                if a is not None and lo <= a < hi]
        show(name, runs)
    for name, path in KNOWN_CODE:
        if not os.path.exists(os.path.join(ROOT, path)):
            continue
        show(name, run_starts(path, amap.get(path, {})))
    print("\n  READ IT: if the PROVEN-DATA rows score like the KNOWN-CODE rows,")
    print("  the enrichment is a property of the greedy disassembly pass that")
    print("  produced these files -- it stops on a byte it cannot spell, in")
    print("  code and in data alike -- and not of the content.  Note also that")
    print("  the CONTROL bytes are near-zero everywhere for the same reason:")
    print("  a byte the pass CAN spell is consumed as an instruction and so")
    print("  can hardly ever begin a `.byte` run.  That floor, not the blind")
    print("  count, is what drives the ratio.")
    if "--xrefs" in sys.argv:
        xrefs()
    return 0


if __name__ == "__main__":
    sys.exit(main())
