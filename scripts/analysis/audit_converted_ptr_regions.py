#!/usr/bin/env python3
"""Did any `.long` conversion emit over data that is NOT pointers?

Written after a real error: `convert_embedded_ptr_regions.py` converted
`naka_widget_names_charmap` 0x4C00..0x4C28, and those bytes are the ASCII string
table `i5 i4 i3 i2 i1 i0 Default None`. The words matched, the byte gate passed,
and the description was wrong. Nothing in this project can catch a wrong
description -- only a wrong byte -- so it has to be looked for deliberately.

FOR EVERY converted region, three checks on the ACTUAL emitted words:

  TEXT     a run of words whose bytes are mostly printable ASCII with letter
           runs. That is what caught the original defect.
  DEAD     a run of words that are neither null, nor a SENTINEL, nor in the ROM
           address range. ⚠ A sentinel IS table content: `naka_sequencer_channels`
           0x000D00 carries a repeating `00000000 / FFFFFFFF / FFFF0002` pattern,
           and `.long 0xFFFFFFFF` expresses a terminator perfectly well. Counting
           those as mis-described flagged three regions that are fine.
  MISALIGNED  the sources declare a named offset inside the region that is NOT
           4-aligned to the region start. A record at +2 cannot be a 4-aligned
           pointer, so its presence means the region is not pointer data.
           ⚠ THIS is the check that would have prevented the error: the +2
           offsets were visible and I read them as a limitation of the label
           placer rather than as evidence against the conversion.

Run:  python3 scripts/analysis/audit_converted_ptr_regions.py
Exits non-zero if any converted region trips a check.
"""
import glob, os, pathlib, re, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
ROM_LO, ROM_HI = 0xE00000, 0x1000000
RUN = re.compile(r'^EmbeddedPtrTable_(v7|v9|v10)_(\w+?)_([0-9A-F]{6}):$')
EQU = re.compile(r'^\s*\.equ\s+(\w+)\s*,\s*(\w+)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*$')


def textish(words):
    """Longest run of consecutive words that look like ASCII text."""
    best = cur = 0
    for w in words:
        b = struct.pack("<I", w)
        pr = sum(1 for c in b if 0x20 <= c < 0x7F)
        alpha = sum(1 for c in b if (c | 0x20) in range(0x61, 0x7B))
        cur = cur + 1 if (pr >= 3 and alpha >= 2) else 0
        best = max(best, cur)
    return best


def main():
    bad = []
    for f in sorted(set(glob.glob("*/maincpu/**/*.s", recursive=True))):
        lines = open(f, encoding="latin1").read().splitlines()
        base = None
        for i, ln in enumerate(lines):
            m = re.match(r'^(\w+):$', ln)
            if m and i + 1 < len(lines) and ".incbin" in lines[i + 1]:
                base = m.group(1); break
        named = {}
        for ln in lines:
            e = EQU.match(ln)
            if e and base and e.group(2) == base:
                named[int(e.group(3), 0)] = e.group(1)
        i = 0
        while i < len(lines):
            r = RUN.match(lines[i])
            if not r:
                i += 1; continue
            rev, blob, off = r.group(1), r.group(2), int(r.group(3), 16)
            words = []
            j = i + 1
            while j < len(lines) and lines[j].startswith("\t.long "):
                arg = lines[j].split(None, 1)[1].strip()
                words.append(int(arg, 16) if arg.startswith("0x") else None)
                j += 1
            nums = [w for w in words if w is not None]
            t = textish(nums)
            def sentinel(x):
                return (x & 0xFFFF0000) == 0xFFFF0000 or x in (0xFFFFFFFF, 0xFFFFFF)
            dead = sum(1 for w in nums
                       if w and not sentinel(w) and not (ROM_LO <= w < ROM_HI))
            mis = [o for o in named if off <= o < off + 4 * len(words) and (o - off) % 4]
            if t >= 4:
                bad.append((f, blob, off, f"TEXT: {t} consecutive ASCII-looking words"))
            elif mis:
                bad.append((f, blob, off,
                            f"MISALIGNED: named offset(s) at +{[hex(o-off) for o in mis[:3]]} "
                            f"are not 4-aligned to the region"))
            elif dead >= max(4, len(nums) // 4):
                bad.append((f, blob, off,
                            f"DEAD: {dead}/{len(nums)} non-null words outside ROM range"))
            i = j
    print(f"  converted regions audited for wrong description")
    if not bad:
        print("  PASS: no converted region looks like text, misaligned records, or non-pointers")
        return 0
    print(f"  *** {len(bad)} region(s) look WRONGLY described:")
    for f, blob, off, why in bad:
        print(f"    {blob} 0x{off:06X}  {why}")
        print(f"      in {f}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
