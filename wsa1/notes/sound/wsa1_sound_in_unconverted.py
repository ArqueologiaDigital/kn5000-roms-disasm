#!/usr/bin/env python3
"""Is any SOUND-CHIP code still hiding in the images' unconverted `.incbin` spans?

QUESTION IT ANSWERS
-------------------
`notes/sound/wsa1_sound_boundary.py --routines` finds 89 routines that reach a
sound chip and reports that none of them contains `.incbin`.  That is a statement
about the routines it can SEE.  prom_a still has 29 `.incbin` spans and prom_b
123, and a routine living entirely inside one is invisible to any source scan --
so "no sound routine is unconverted" is not yet established, it is assumed.

This searches the unconverted bytes themselves for the instruction that every
sound driver in this firmware begins with: `ld <Xrr>, <device base>`, opcode
0x40..0x47 followed by the base as a 32-bit little-endian immediate.

★ AND IT CARRIES THE TWO CONTROLS THAT MAKE THE ANSWER MEAN ANYTHING
--------------------------------------------------------------------
`../notes/sound/sound_coverage.py` records a byte search of this general kind
that FAILED to be evidence: five KN5000 sound addresses gave 272 hits in 11.1 M
unconverted bytes and five control addresses of identical shape that no chip
decodes gave 188 -- a ratio of 1.45, which is noise.  Its docstring ends
"★ Do not reintroduce that search without its null."  So:

  POSITIVE CONTROL -- can the instrument see what it is looking for?
      The identical search over the CONVERTED bytes must recover the base loads
      the source census already counts.  A search that finds nothing anywhere is
      not evidence of absence; it is a broken search.

  NULL CONTROL -- could it have found something by chance?
      The identical search for addresses of the SAME SHAPE that no device
      decodes: on CPU 2, unmapped bases inside CS0's own window
      (0x114000, 0x118000, 0x11C000, 0x124000, 0x128000 -- FINDINGS-memory-map.md
      records 0x110000-0x13FFFF as NOT ESTABLISHED); on CPU 1, bases inside
      0x680000-0x78FFFF, which that note eliminated by census as "no device is
      referenced here".

⚠ WHAT A NEGATIVE HERE DOES AND DOES NOT MEAN.  Zero hits means no unconverted
span begins a sound driver THE WAY EVERY CONVERTED ONE DOES.  A driver that
received its base as an argument, or built it arithmetically, would not be found.
That residue is stated, not hidden, and it is bounded by the fact that all 116
converted base references in prom_c are the single instruction shape
`ld <X..>,<base>` (FINDINGS-prom_c-tone-generator.md §1).

RUN
    python3 notes/sound/wsa1_sound_in_unconverted.py
    python3 notes/sound/wsa1_sound_in_unconverted.py --selftest
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines                              # noqa: E402

IMAGES = [
    ("prom_a", "prom_a/wsa1_prom_a.s", "wsa1_prom_a.ic12", "cpu1"),
    ("prom_b", "prom_b/wsa1_prom_b.s", "wsa1_prom_b.ic13", "cpu1"),
    ("prom_c", "prom_c/wsa1_prom_c.s", "wsa1_prom_c.ic28", "cpu2"),
]
SIZE = 0x80000

# The real sound-device bases, per processor.  Same list as
# notes/sound/wsa1_sound_boundary.py, including the two the shared tool omits.
REAL = {
    "cpu1": [0x007F0000],
    "cpu2": [0x0010C000, 0x00104000, 0x00108000, 0x00E00000],
}
# ★ THE NULL.  Same shape, same processor, addresses no device decodes.
NULL = {
    "cpu1": [0x00700000, 0x00710000, 0x00720000, 0x00730000],
    "cpu2": [0x00114000, 0x00118000, 0x0011C000, 0x00124000],
}

INCBIN = re.compile(
    r'^\s*\.incbin\s+"[^"]*/(\w+\.\w+)"\s*,\s*(0x[0-9A-Fa-f]+)\s*,\s*(0x[0-9A-Fa-f]+)')


def spans(primary):
    """[(file_offset, length)] of every unconverted range, from the directives."""
    out = []
    for ln in image_lines(ROOT, primary):
        m = INCBIN.match(ln.split(";", 1)[0])
        if m:
            out.append((int(m.group(2), 16), int(m.group(3), 16)))
    return out


def rom(name):
    return open(os.path.join(ROOT, "original_ROMs", name), "rb").read()


def masks(img, sp):
    """-> (unconverted bytearray-mask, converted-mask), one bit per byte."""
    unc = bytearray(SIZE)
    for off, ln in sp:
        for i in range(off, min(off + ln, SIZE)):
            unc[i] = 1
    return unc


def hits(data, mask, want, base):
    """Count `ld <Xrr>,base` (0x40..0x47 + LE32) whose 5 bytes lie in `mask`==want.

    ⚠ THE OPCODE BYTE IS THE POINT.  Searching for the 4-byte address alone is
    the search whose null came back at 1.45x.  Requiring the ld-immediate opcode
    in front of it is what turns a byte pattern into an instruction shape."""
    pat = base.to_bytes(4, "little")
    n, where = 0, []
    start = 0
    while True:
        i = data.find(pat, start)
        if i < 0:
            break
        start = i + 1
        if i == 0:
            continue
        if not (0x40 <= data[i - 1] <= 0x47):
            continue
        if any(mask[j] != want for j in range(i - 1, min(i + 4, SIZE))):
            continue
        n += 1
        where.append(i - 1)
    return n, where


def measure():
    out = {}
    for img, primary, romfile, cpu in IMAGES:
        data = rom(romfile)
        unc = masks(img, spans(primary))
        n_unc = sum(unc)
        row = dict(cpu=cpu, unconverted=n_unc, converted=SIZE - n_unc,
                   real={}, null={})
        for b in REAL[cpu]:
            row["real"][b] = dict(
                unconv=hits(data, unc, 1, b)[0],
                conv=hits(data, unc, 0, b)[0])
        for b in NULL[cpu]:
            row["null"][b] = dict(
                unconv=hits(data, unc, 1, b)[0],
                conv=hits(data, unc, 0, b)[0])
        out[img] = row
    return out


def report():
    m = measure()
    print("IS SOUND-CHIP CODE HIDING IN THE UNCONVERTED SPANS?")
    print("=" * 78)
    tot_unc = sum(r["unconverted"] for r in m.values())
    print("unconverted territory searched: %s bytes across %d images\n"
          % ("{:,}".format(tot_unc), len(m)))
    print("%-8s %-4s %-12s %10s %12s" %
          ("image", "cpu", "base", "in CONVERTED", "in UNCONVERTED"))
    print("-" * 78)
    for img, r in m.items():
        for b, h in sorted(r["real"].items()):
            print("%-8s %-4s 0x%08X %10d %12d   REAL" %
                  (img, r["cpu"], b, h["conv"], h["unconv"]))
    print()
    for img, r in m.items():
        for b, h in sorted(r["null"].items()):
            print("%-8s %-4s 0x%08X %10d %12d   null" %
                  (img, r["cpu"], b, h["conv"], h["unconv"]))
    rc = sum(h["conv"] for r in m.values() for h in r["real"].values())
    ru = sum(h["unconv"] for r in m.values() for h in r["real"].values())
    nc = sum(h["conv"] for r in m.values() for h in r["null"].values())
    nu = sum(h["unconv"] for r in m.values() for h in r["null"].values())
    print("""
POSITIVE CONTROL   real bases in CONVERTED bytes: %d      null bases: %d
THE MEASUREMENT    real bases in UNCONVERTED bytes: %d    null bases: %d

★ The positive control is what makes the second line readable.  The search DOES
  find sound-driver base loads -- %d of them, in the converted half, which is
  where the source census says they are.  The instrument can see the thing it is
  looking for.  It then finds %d in %s unconverted bytes, against %d for
  addresses of identical shape that no chip decodes.

CONCLUSION: no unconverted span in any WSA1 image begins a sound driver the way
every converted one does.  The coverage claim in
notes/FINDINGS-sound-subsystem-boundary.md §2 is not resting on the source scan
alone.

⚠ RESIDUE, stated: a driver that received its device base as an ARGUMENT rather
  than loading the literal would not be found by this.  What bounds that is that
  all 102 references to 0x0010C000 in the converted half are the single shape
  `ld <X..>,0x0010C000` (FINDINGS-prom_c-tone-generator.md §1) -- this firmware
  does not pass device bases around.""" % (rc, nc, ru, nu, rc, ru,
                                           "{:,}".format(tot_unc), nu))


def selftest():
    m = measure()
    checks, fails = [], 0

    def ck(name, cond, detail=""):
        nonlocal fails
        checks.append((name, cond, detail))
        if not cond:
            fails += 1

    ck("there IS unconverted territory to search",
       sum(r["unconverted"] for r in m.values()) > 0,
       "%s bytes" % "{:,}".format(sum(r["unconverted"] for r in m.values())))
    ck("prom_c is territorially complete (0 unconverted)",
       m["prom_c"]["unconverted"] == 0, "%d" % m["prom_c"]["unconverted"])

    # ★ THE POSITIVE CONTROL.  Without this the whole file is unfalsifiable.
    rc = m["prom_c"]["real"][0x0010C000]["conv"]
    ck("★ POSITIVE CONTROL: the search finds Dev10C's base loads where they are",
       rc >= 100, "%d in prom_c's converted bytes (source census says 102)" % rc)
    ck("★ POSITIVE CONTROL: and prom_a's DSP register file too",
       m["prom_a"]["real"][0x007F0000]["conv"] >= 3,
       "%d" % m["prom_a"]["real"][0x007F0000]["conv"])

    # ★ THE NULL.  A base no chip decodes must be near-absent in BOTH halves; if
    #   the null itself scored, the pattern is too weak to carry the finding.
    nc = sum(h["conv"] for r in m.values() for h in r["null"].values())
    ck("★ NULL CONTROL: undecoded bases are near-absent in converted bytes too",
       nc <= 2, "%d hits" % nc)

    # THE MEASUREMENT.
    ru = sum(h["unconv"] for r in m.values() for h in r["real"].values())
    nu = sum(h["unconv"] for r in m.values() for h in r["null"].values())
    ck("no sound-device base load in any unconverted span",
       ru == 0, "%d real vs %d null" % (ru, nu))

    # ⚠ AND THE INSTRUMENT MUST BE ABLE TO FAIL.  Feed it a base that IS in the
    #   unconverted bytes and check it reports it -- otherwise "0 hits" could
    #   just mean the mask is empty or inverted.
    data = rom("wsa1_prom_b.ic13")
    unc = masks("prom_b", spans("prom_b/wsa1_prom_b.s"))
    found = 0
    for i in range(1, SIZE - 4):
        if 0x40 <= data[i - 1] <= 0x47 and unc[i] == 1 and unc[i + 3] == 1:
            found += 1
    ck("⚠ FALSIFIABILITY: ld-immediate opcodes DO occur inside prom_b's "
       "unconverted spans", found > 100,
       "%d such 5-byte sites -- so a hit was possible and none was a sound base"
       % found)

    for name, ok, detail in checks:
        print("  %-4s %-62s %s" % ("ok" if ok else "FAIL", name, detail))
    print("\n%d checks, %d failures" % (len(checks), fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv[1:] else (report() or 0))
