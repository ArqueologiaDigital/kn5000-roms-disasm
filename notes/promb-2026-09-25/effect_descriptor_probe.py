#!/usr/bin/env python3
r"""DSP-effect parameter descriptors: what bytes 1-3 of each 4-byte group are, and the units column.

QUESTION THIS ANSWERS
    EffectParamDescriptors_F12F24 (128 pointers, one per effect algorithm)
    names, per algorithm, eight 4-byte groups.  Wave 8 decoded byte 0 (a row of
    EffectParamNames_F15024) and wrote "Bytes 1-3 are NOT interpreted";
    DLTable_HzHzHzHzHzSSSSMsMsMs (the 32 x 7 units column) said "Unknown: which
    effect parameter each row belongs to".  This probe re-derives, from the ROM:

      1. the READER: MAME unidasm's decode of DspEffect_PaintParamEditor
         (0xF11057) must load byte 4p+1 of the descriptor into C, store it to
         (0x2640), and run record 15*line of DLB_Records_F157A8 (whose eight
         source variables are (0x2640) masked 0x1F and whose table is the units
         column); then multiply the same byte by 4 to index ScreenTable_F13264
         and ScreenDisplayLists_F132E4; then load byte 4p+3 into L;
      2. the TABLE: every live group's byte 1 is < 32 (the units table's and the
         mask's size), and the units string each parameter gets, printed per
         effect -- REVERB TIME must come out in seconds, PRE DELAY and the
         delay times in milliseconds, LFO SPEED in Hz;
      3. byte 2 of the live groups, and byte 3's values.

RUN
    python3 notes/promb-2026-09-25/effect_descriptor_probe.py          # checks + table
    python3 notes/promb-2026-09-25/effect_descriptor_probe.py --quiet  # checks only
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
UNI = os.path.join(os.path.expanduser("~/compartilhado"), "tools", "unidasm")
BASE = 0xF00000
DESC, NAMES, PNAMES, UNITS = 0xF12F24, 0xF147AC, 0xF15024, 0xF156C8
PAINT = 0xF11057
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def main():
    quiet = "--quiet" in sys.argv
    rom = open(B, "rb").read()
    at = lambda a, n=1: rom[a - BASE:a - BASE + n]
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(at(PAINT, 0x140))
        f.flush()
        txt = subprocess.run([UNI, f.name, "-arch", "tlcs900", "-basepc", hex(PAINT)],
                             capture_output=True, text=True).stdout.lower()
    seq = [l.split(None, 1)[1] if len(l.split(None, 1)) > 1 else "" for l in
           [re.sub(r'^\s*[0-9a-f]+:\s+(?:[0-9a-f]{2}\s)+\s*', '', ln) for ln in txt.split("\n")]]
    body = "\n".join(s for s in [re.sub(r'^\s*[0-9a-f]+:\s+(?:[0-9a-f]{2}\s)+\s*', '', ln).strip()
                                 for ln in txt.split("\n")] if s)
    for want in ("inc 1,xbc", "add xwa,0x00f12f24", "ld c,(xwa)", "ld (0x2640),c",
                 "add xbc,0x00f157a8", "call 0xf42e0c", "add xbc,0x00f13264",
                 "lda xbc,0xf132e4", "inc 3,xbc", "ld l,(xwa)"):
        check("DspEffect_PaintParamEditor contains `%s`" % want, want in body)
    i1 = body.index("inc 1,xbc")
    i2 = body.index("ld (0x2640),c")
    i3 = body.index("add xbc,0x00f157a8")
    check("byte 4p+1 -> (0x2640) -> units record, in that order", i1 < i2 < i3)
    # units records: 8 x op02, source (0x2640), mask 0x1F, table = UNITS, width 7
    ok = True
    for k in range(8):
        r = at(0xF157A8 + 15 * k, 15)
        ok &= (r[0] == 0x02 and r[1] == 0x0F and r[2:4] == b"\x40\x26" and r[4] == 0x1F
               and int.from_bytes(r[7:11], "little") == UNITS and r[11:13] == b"\x07\x00")
    check("DLB_Records_F157A8[0..7]: op 02, source (0x2640), mask 0x1F, table 0xF156C8, width 7", ok)
    units = [at(UNITS + 7 * k, 7).decode("latin-1").strip() for k in range(32)]
    names = [at(NAMES + 16 * k, 16).decode("latin-1").strip() for k in range(128)]
    pnames = [at(PNAMES + 17 * k, 17).decode("latin-1").strip().rstrip(":").strip() for k in range(100)]
    seen, b1max, rows, b3vals = set(), 0, [], set()
    for k in range(128):
        p = int.from_bytes(at(DESC + 4 * k, 4), "little")
        if p in seen or names[k].startswith("---"):
            continue
        seen.add(p)
        ps = []
        for j in range(8):
            g = at(p + 4 * j, 4)
            if g[0] == 0 and g[2] == 0xFF:
                continue
            b1max = max(b1max, g[1])
            b3vals.add(g[3])
            ps.append((pnames[g[0]], g[1], units[g[1] & 0x1F], g[2], g[3]))
        rows.append((k, names[k], ps))
    check("every live group's byte 1 is < 32 (max 0x%02X)" % b1max, b1max < 32)
    lookup = {(n, pn): u for k, n, ps in rows for pn, b1, u, b2, b3 in ps}
    check("ROOM REVERB 1: REVERB TIME in s, PRE DELAY in ms",
          lookup.get(("ROOM REVERB 1", "REVERB TIME")) == "s" and
          lookup.get(("ROOM REVERB 1", "PRE DELAY")) == "ms")
    check("CHORUS: LFO SPEED in Hz", lookup.get(("CHORUS", "LFO SPEED")) == "Hz")
    check("SINGLE DELAY: DELAY L and DELAY R in ms",
          lookup.get(("SINGLE DELAY", "DELAY L")) == "ms" and lookup.get(("SINGLE DELAY", "DELAY R")) == "ms")
    if not quiet:
        for k, n, ps in rows:
            print("%3d %-16s %s" % (k, n, " | ".join("%s [%02X %s] b2=%02X b3=%02X" % (pn, b1, u or "-", b2, b3)
                                                    for pn, b1, u, b2, b3 in ps)))
        print("byte-3 values over all live groups:", " ".join("%02X" % v for v in sorted(b3vals)))
    print("\nVERDICT:", "PASS" if not FAIL else "FAIL (%d)" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
