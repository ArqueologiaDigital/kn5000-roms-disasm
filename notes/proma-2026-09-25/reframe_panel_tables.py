#!/usr/bin/env python3
r"""Retype eleven lookup tables in prom_a's panel-event modules that were framed as code.

    ⚠ SUPERSEDED IN PART: the NAMES and HEADERS below are this script's first
    reading and three of its claims were wrong (which handlers are dead, how
    the 17-byte tables are used, and that the bit-mask routines are twins).
    retitle_panel_tables.py corrected them in the source; the typing (extent,
    element width, count) is unchanged.  Its dry run still checks the readers.

QUESTION THIS ANSWERS
    The panel-event expansion modules (0xF8A000 and its dead copy, 0xF8BE00)
    keep small C lookup tables right after the routines that index them, and
    the linear decode ran straight through them: `nop / normal / push SR / max /
    ld (0x10:8),0x20:io / ...`.  For each table this script cites the reader
    (the instruction that forms its base and the index it adds), derives the
    entry count from that reader's bound, checks the table ends where an
    existing source line resumes the real code (or re-decodes the few bytes in
    between with prom_a/roundtrip.py, which assembles and byte-compares every
    instruction it prints), and with --apply writes the typed table.

      table     n  elem  reader (base-forming instruction)       bound
      F8A530    9   1    sub_F8A51C  0xF8A524 ld XIX,<t>           cp E,0x08 / jr ule
      F8A550   17   2    0xF8A539    0xF8A544 ld XIX,<t> (E*2)     cp E,0x10 / jr ule
      F8A589   33   4    0xF8A572    0xF8A57D ld XIX,<t> (E*4)     cp E,0x20 / jr ule
      F8BE4D   33   4    sub_F8BE36  0xF8BE41 ld XIX,<t> (E*4)     cp E,0x20 / jr ule
      F8A686    9   1    0xF8A666    0xF8A674 add XDE,<t>          LowestSetBitIndex1Based: 0..8
      F8A6AF    9   1    0xF8A68F    0xF8A69D add XDE,<t>          (same)
      F8AB39    9   1    0xF8AB19-ish, dead copy (add XDE,<t>)     (same)
      F8AB67    9   1    dead copy (add XDE,<t>)                   (same)
      F8ADCD   17   1    0xF8AD75 add XDE,<t>                      ordinal 0..8, +8 unless A==1
      F8AE57   17   1    0xF8ADFF add XDE,<t>                      (same)
      F8B07E   13   1    0xF8AFD7 / 0xF8B099 add XWA,<t>, A-0x0B  extent: code resumes at 0xF8B08B

    Every reader's bytes are asserted at its address, every table's end is
    asserted to be an existing line start or re-decoded, and no label may lie
    strictly inside a table.

RUN
    python3 notes/proma-2026-09-25/reframe_panel_tables.py [--apply]
    make gate-wsa1
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
WSA1 = srcmap.WSA1


def reader_ok(rom, site, pat):
    return rom[site - B:site - B + len(pat)] == pat


def le(v):
    return v.to_bytes(4, "little")


BITMASK_HDR = [
    "; BitMask{w}_ByOrdinal{sfx} -- {n} x {s}-bit values: 0, then 1<<0 .. 1<<{m}.  Entry k is",
    ";          the mask of bit k-1, entry 0 is 0 -- the inverse of",
    ";          LowestSetBitIndex1Based (0xF8A913).",
    "; Read by: {reader} -- `push XIX / cp E,{bound:#04x} / jr ule / xor E,E /",
    ";          {scale}ld XIX,<this> / ld {reg},(XIX+E)`, so any E above {bound} reads",
    ";          entry 0.  COUNT {n} = that bound + 1.",
]
EVT_HDR = [
    "; {name} -- {n} bytes: a switch-bit ordinal -> event code.",
    "; Read by: {reader}: E = LowestSetBitIndex1Based(mask) (0 = no bit, 1..8 =",
    ";          the lowest set bit + 1){plus}, then `add XDE,<this> / ld E,(XDE)` and",
    ";          `ld D,0xFF / jp sub_F8A500`, which stores DE at (XIX+) -- one event",
    ";          word per switch.  COUNT {n} = the ordinal range{plus2}.",
]

SPECS = [
    # (start, n, elem, name, reader-site, reader-bytes, header-lines, code-fix-label)
    (0xF8A530, 9, 1, "BitMask8_ByOrdinal", 0xF8A524, b"\x44" + le(0xF8A530),
     [x.format(w=8, sfx="", n=9, s=8, m=7, reader="sub_F8A51C, renamed BitMask8_FromOrdinal",
               bound=8, scale="", reg="E") for x in BITMASK_HDR], "BitMask16_FromOrdinal"),
    (0xF8A550, 17, 2, "BitMask16_ByOrdinal", 0xF8A544, b"\x44" + le(0xF8A550),
     [x.format(w=16, sfx="", n=17, s=16, m=15, reader="BitMask16_FromOrdinal (0xF8A539)",
               bound=16, scale="sla 1,E / ", reg="DE") for x in BITMASK_HDR], "BitMask32_FromOrdinal"),
    (0xF8A589, 33, 4, "BitMask32_ByOrdinal", 0xF8A57D, b"\x44" + le(0xF8A589),
     [x.format(w=32, sfx="", n=33, s=32, m=31, reader="BitMask32_FromOrdinal (0xF8A572)",
               bound=32, scale="sla 2,E / ", reg="XDE") for x in BITMASK_HDR], None),
    (0xF8BE4D, 33, 4, "BitMask32_ByOrdinal_Copy", 0xF8BE41, b"\x44" + le(0xF8BE4D),
     [x.format(w=32, sfx="_Copy", n=33, s=32, m=31, reader="sub_F8BE36, renamed BitMask32_FromOrdinal_Copy",
               bound=32, scale="sla 2,E / ", reg="XDE") for x in BITMASK_HDR] +
     ["; A byte-for-byte twin of BitMask32_ByOrdinal (0xF8A589) in the dead-copy",
      "; module; gen check: identical 132 bytes."], None),
    (0xF8A686, 9, 1, "PanelBitToEvent_F8A686", 0xF8A674, b"\xea\xc8" + le(0xF8A686),
     [x.format(name="PanelBitToEvent_F8A686", n=9, reader="the handler at 0xF8A666 (when (0x2806) is 0)",
               plus="", plus2=" 0..8") for x in EVT_HDR], None),
    (0xF8A6AF, 9, 1, "PanelBitToEvent_F8A6AF", 0xF8A69D, b"\xea\xc8" + le(0xF8A6AF),
     [x.format(name="PanelBitToEvent_F8A6AF", n=9, reader="the handler at 0xF8A68F (when (0x2806) is 0)",
               plus="", plus2=" 0..8") for x in EVT_HDR], None),
    (0xF8AB39, 9, 1, "PanelBitToEvent_F8AB39", None, b"\xea\xc8" + le(0xF8AB39),
     [x.format(name="PanelBitToEvent_F8AB39", n=9, reader="the dead-copy handler before it",
               plus="", plus2=" 0..8") for x in EVT_HDR] +
     ["; Byte-identical to PanelBitToEvent_F8A686: the dead copy's twin."], None),
    (0xF8AB67, 9, 1, "PanelBitToEvent_F8AB67", None, b"\xea\xc8" + le(0xF8AB67),
     [x.format(name="PanelBitToEvent_F8AB67", n=9, reader="the dead-copy handler before it",
               plus="", plus2=" 0..8") for x in EVT_HDR] +
     ["; Byte-identical to PanelBitToEvent_F8A6AF: the dead copy's twin."], None),
    (0xF8ADCD, 17, 1, "PanelBitToEvent_F8ADCD", 0xF8AD75, b"\xea\xc8" + le(0xF8ADCD),
     [x.format(name="PanelBitToEvent_F8ADCD", n=17, reader="the handler at 0xF8AD62 (XBC = 0x2267)",
               plus=" plus 8 unless A == 1 (0xF8AD6A-0xF8AD6E)", plus2=" 0..16")
      for x in EVT_HDR] +
     ["; A result of 0x0F is special-cased right after the read (0xF8AD7D)."], None),
    (0xF8AE57, 17, 1, "PanelBitToEvent_F8AE57", 0xF8ADFF, b"\xea\xc8" + le(0xF8AE57),
     [x.format(name="PanelBitToEvent_F8AE57", n=17, reader="the handler at 0xF8ADEC (XBC = 0x2267)",
               plus=" plus 8 unless A == 1 (0xF8ADF4-0xF8ADF8)", plus2=" 0..16")
      for x in EVT_HDR] +
     ["; A result of 0x0F is special-cased right after the read (0xF8AE07)."], None),
    (0xF8B07E, 13, 1, "ControlIndexMap_F8B07E", 0xF8AFD7, b"\xe8\xc8" + le(0xF8B07E),
     ["; ControlIndexMap_F8B07E -- 13 bytes, indexed by A - 0x0B.",
      "; Read by: 0xF8AFD7 and 0xF8B099: `sub A,0x0B / add XWA,<this> / ld A,(XWA)`;",
      ";          the second reader then reads (0x7F12 + that value) and tests it",
      ";          against 0x40, the first compares it with 0x15/0x16 when (0xC4) is 2.",
      "; COUNT 13 is the extent: the real code resumes at 0xF8B08B (`cp (0xC4),2`).",
      ";          What the index and the values denote is not established."], None),
]


def main():
    apply_ = "--apply" in sys.argv
    m = srcmap.load()
    rom = m.rom
    L = m.lines
    addr_line = {}
    for i, l in enumerate(L):
        mm = srcmap.ADDR.search(l)
        if mm and l.strip() and not l.lstrip().startswith(";"):
            addr_line.setdefault(int(mm.group(1), 16), i)
    assert rom[0xF8A589 - B:0xF8A589 - B + 132] == rom[0xF8BE4D - B:0xF8BE4D - B + 132]
    assert rom[0xF8A686 - B:0xF8A686 - B + 9] == rom[0xF8AB39 - B:0xF8AB39 - B + 9]
    assert rom[0xF8A6AF - B:0xF8A6AF - B + 9] == rom[0xF8AB67 - B:0xF8AB67 - B + 9]
    plans = []
    for start, n, elem, name, site, pat, hdr, fixlab in SPECS:
        end = start + n * elem
        if site is not None:
            assert reader_ok(rom, site, pat), "%s: reader bytes not at 0x%06X" % (name, site)
        else:
            i = rom.find(pat)
            assert i >= 0 and rom.find(pat, i + 1) < 0, name
        i0 = addr_line.get(start)
        assert i0 is not None, "%s: 0x%06X is not a line start" % (name, start)
        # the first existing line start at or after `end` that is ALSO an instruction
        # boundary of the true decode from `end` (unidasm framing, via roundtrip.py):
        # from there on the existing lines and the true decode coincide
        if end in addr_line:
            R = end
        else:
            probe = subprocess.run([sys.executable, os.path.join(WSA1, "prom_a", "roundtrip.py"),
                                    "0x%X" % end, "0x%X" % (end + 48)], capture_output=True, text=True,
                                   cwd=WSA1).stdout
            T = {int(x, 16) for x in re.findall(r';\s*([0-9A-F]{6})\s', probe)}
            R = min(a for a in addr_line if a >= end and a in T)
        code = []
        if R != end:
            r = subprocess.run([sys.executable, os.path.join(WSA1, "prom_a", "roundtrip.py"),
                                "0x%X" % end, "0x%X" % R, "--block"], capture_output=True, text=True,
                               cwd=WSA1)
            assert "round-trip: OK" in r.stdout + r.stderr, \
                "%s: tail 0x%06X-0x%06X does not round-trip" % (name, end, R)
            code = [l for l in r.stdout.split("\n")
                    if l.startswith("\t") or re.match(r'^\.L[0-9A-F]{6}:$', l)]
            code = [l for l in code if not re.match(r'^\.L%06X:$' % end, l)]
        i1 = addr_line[R]
        while i1 - 1 > i0 and (re.match(r'^[A-Za-z_.$][\w.$]*:\s*(;.*)?$', L[i1 - 1])
                               or L[i1 - 1].startswith(";") or not L[i1 - 1].strip()):
            i1 -= 1              # keep R's own labels and header with R
        # no label strictly inside the table
        inside = [x for a, ns in m.by_addr.items() for x in ns if start < a < end]
        for x in inside:         # only an ORPHAN may be dropped: named by no source line
            for p in (srcmap.SRC, os.path.join(WSA1, "prom_b", "wsa1_prom_b.s")):
                t = open(p, encoding="latin-1").read()
                assert x not in t.replace(x + ":", ""), "%s: label %s inside is referenced" % (name, x)
            a = int(x[4:], 16) if re.match(r'^sub_[0-9A-F]{6}$', x) else None
            assert a is not None, "%s: non-address label %s inside" % (name, x)
            for f in ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13"):
                blob = open(os.path.join(WSA1, "original_ROMs", f), "rb").read()
                assert a.to_bytes(3, "little") not in blob, "%s: %s's address occurs in %s" % (name, x, f)
        if inside:
            print("    dropping orphan label(s) inside %s: %s" % (name, inside))
        plans.append((i0, i1, start, n, elem, name, hdr, fixlab, end, code))
        print("  0x%06X %3d x %d  %-28s tail %d line(s) re-decoded" % (start, n, elem, name, len(code)))
    if not apply_:
        return
    rows = []
    for (i0, i1, start, n, elem, name, hdr, fixlab, end, code) in sorted(plans, reverse=True):
        blk = ["; ---------------------------------------------------------------------"] + hdr + [
            "; (was framed as code; notes/proma-2026-09-25/reframe_panel_tables.py)",
            "; ---------------------------------------------------------------------",
            "%s:" % name]
        vals = [int.from_bytes(rom[start - B + elem * k:start - B + elem * k + elem], "little") for k in range(n)]
        per = {1: 16, 2: 8, 4: 4}[elem]
        d = {1: ".byte", 2: ".short", 4: ".long"}[elem]
        f = {1: "0x%02x", 2: "0x%04x", 4: "0x%08x"}[elem]
        for r in range(0, n, per):
            blk.append("\t%s %s  ; %06X  [%d]" % (d, ", ".join(f % v for v in vals[r:r + per]),
                                                   start + elem * r, r))
        if code:
            blk += ["", "; %s -- E = the mask of bit E-1 (0 for E = 0 or out of range), read" % fixlab,
                    ";          from the table after it.  The linear decode had run this",
                    ";          routine's first instructions into the table above.",
                    "%s:" % fixlab] + code
        L[i0:i1] = blk
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(L))
    print("applied")


if __name__ == "__main__":
    main()
