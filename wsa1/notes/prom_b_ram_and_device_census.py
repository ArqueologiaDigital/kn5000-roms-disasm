#!/usr/bin/env python3
"""What memory does CONVERTED prom_b actually touch — and does it touch any device?

WHAT QUESTIONS THIS ANSWERS
    Three, all of them about `src/mame/matsushita/wsa1.cpp`'s memory map, and
    all of them re-measured from the committed source rather than remembered.
    The write-up is notes/FINDINGS-prom_b-for-the-mame-driver.md; this is what
    every number in its first two sections comes from.

    --lowram    "Does prom_b stay inside the CS1 SRAM the driver maps?"  NO.
                The driver maps 0x000080-0x0051FF, from the boot clear loop,
                and says in its own comment that that is a lower bound.  This
                lists every absolute memory operand above 0x0051FF, with a call
                site for each.  Read-modify-writes are the strongest shape here:
                the firmware both reads and writes the byte and expects the
                write to stick.

    --devices   "Which addresses at or above 0x600000 does prom_b name?"  Only
                work DRAM.  The driver has six unidentified `noprw()` devices on
                CPU 1 (0x790000, 0x7A0000, 0x7B0004, 0x7C0000, 0x7E0008,
                0x7F0000) and prom_b names NONE of them, nor any other address
                in 0x700000-0x7FFFFF.  A negative result, and a useful one: this
                image is the UI/text/table half and drives no hardware, so the
                driver's "identify the CS0 devices" TODO has nothing to gain
                here.

    --orphans   "Is any CONVERTED CODE attributed to a DATA label?"  Wave 8
                found two routines emitted with no label of their own -- the SMF
                reader at 0xF6F530, under Data_F6F528, and the accompaniment
                volume line at 0xF6E4F2, under a 64-byte `.ascii`.  Both are
                labelled now.  This is the standing check that there is not a
                third: it lists every code row that follows a data row under a
                data-kind label, and marks the ones a decoded transfer or a
                thunk slot names -- those are routine ENTRIES that have lost
                their label.  The rest are tables embedded mid-routine, which
                the code jumps over, and must NOT be labelled.

⚠ SCOPE.  Everything here is measured over the CONVERTED part of prom_b, which
   `python3 scripts/analysis/source_coverage.py` puts at 80.2% substantive.  A
   device touched only from an `.incbin` would not appear.

RUN
    python3 notes/prom_b_ram_and_device_census.py --lowram
    python3 notes/prom_b_ram_and_device_census.py --devices
    python3 notes/prom_b_ram_and_device_census.py --orphans
    python3 notes/prom_b_ram_and_device_census.py            # all three
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402

B_BASE = 0xF00000
SRAM_MAPPED_TOP = 0x0051FF        # what wsa1.cpp maps today
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ADDRC = re.compile(r";\s*([0-9A-F]{6})\s\s(.*)$")
DATA = re.compile(r"^\s*\.(byte|ascii|long|word|short|fill|incbin)\b")
DATA_LABEL = re.compile(r"^(Data|Text|ByteMap|PtrTable|RamPtrTable|DataPtrTable|IndexMap"
                        r"|DispatchTable|Bitmap|Record|DL|SmfChunkTags|SmfFileTemplate"
                        r"|EffectParamDescriptors)")
DRIVER_NOPRW = (0x790000, 0x7A0000, 0x7B0004, 0x7C0000, 0x7E0008, 0x7F0000)


def rows():
    """(address, mame text, is-data, enclosing label) for every addressed line."""
    cur = None
    for ln in image_lines(ROOT, "prom_b/wsa1_prom_b.s"):
        m = LABEL.match(ln)
        if m:
            cur = m.group(1)
            yield None, None, None, cur          # a label boundary
            continue
        if ln.lstrip().startswith(";") or not ln.strip():
            continue
        m2 = ADDRC.search(ln)
        if m2:
            yield int(m2.group(1), 16), m2.group(2).strip(), bool(DATA.match(ln)), cur


def lowram():
    hits = collections.defaultdict(list)
    for a, t, isdata, _ in rows():
        if a is None or "cannot encode" in t:
            continue
        for h in re.findall(r"\((0x[0-9a-fA-F]+)\)", t):
            v = int(h, 16)
            if SRAM_MAPPED_TOP < v < 0x10000:
                hits[v].append((a, t))
    print(f"absolute memory operands above 0x{SRAM_MAPPED_TOP:04X} "
          f"(the top of what wsa1.cpp maps): {len(hits)} addresses, "
          f"{sum(len(v) for v in hits.values())} references")
    for v in sorted(hits):
        a, t = hits[v][0]
        print(f"  0x{v:04X}  x{len(hits[v]):<3d}  e.g. 0x{a:06X}  {t}")
    if hits:
        print(f"\n  => CPU 1's CS1 SRAM must reach at least 0x{max(hits) + 1:06X}.")


def devices():
    hits = collections.defaultdict(int)
    for a, t, isdata, _ in rows():
        if a is None or "cannot encode" in t:
            continue
        for h in re.findall(r"0x00?([0-9a-fA-F]{6})\b", t) + re.findall(r"\((0x[0-9a-fA-F]{6,8})\)", t):
            v = int(h, 16) if not str(h).startswith("0x") else int(h, 16)
            if 0x600000 <= v < 0x800000:
                hits[v] += 1
    banks = collections.Counter(v & 0xFFF00000 for v in hits)
    print(f"addresses >= 0x600000 named by converted prom_b: {len(hits)} distinct, "
          f"{sum(hits.values())} references")
    for k in sorted(banks):
        lo = min(v for v in hits if v & 0xFFF00000 == k)
        hi = max(v for v in hits if v & 0xFFF00000 == k)
        print(f"  0x{k:06X}xx  {banks[k]} distinct, 0x{lo:06X}-0x{hi:06X}")
    bad = [d for d in DRIVER_NOPRW if any(d <= v <= d + 15 for v in hits)]
    print(f"\n  the driver's six unidentified CPU-1 devices named here: {len(bad)} "
          f"{[hex(x) for x in bad]}")
    n7 = [v for v in hits if 0x700000 <= v < 0x800000]
    print(f"  any address at all in 0x700000-0x7FFFFF: {len(n7)}")


def orphans():
    prev_kind, cur = None, None
    found = []
    # every transfer target and thunk target, for the "is it an ENTRY" test
    tgt = set()
    with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as f:
        b = f.read()
    for off in range(0x40000, 0x44018, 4):
        if b[off] == 0x1B:
            tgt.add(b[off + 1] | b[off + 2] << 8 | b[off + 3] << 16)
    for path in ("prom_b/wsa1_prom_b.s", "prom_a/wsa1_prom_a.s"):
        for ln in image_lines(ROOT, path):
            if ln.lstrip().startswith(";"):
                continue
            for m in re.finditer(r"\b(call|calr|jp|jr|jrl)\b[^;]*?0x00?(f[0-9a-f]{5})", ln):
                tgt.add(int(m.group(2), 16))
    for a, t, isdata, lab in rows():
        if a is None:
            cur, prev_kind = lab, None
            continue
        if not isdata and prev_kind is True and cur and DATA_LABEL.match(cur):
            found.append((a, cur, t, a in tgt))
        prev_kind = isdata
    ent = [x for x in found if x[3]]
    print(f"code rows following a data row under a data-kind label: {len(found)}")
    print(f"  of those, named by a decoded transfer or a thunk slot (= a LOST "
          f"ROUTINE ENTRY): {len(ent)}")
    for a, lab, t, _ in ent:
        print(f"    0x{a:06X}  under {lab}  {t}")
    if not ent:
        print("  => none.  Every remaining case is a table embedded mid-routine.")


if __name__ == "__main__":
    want = [x for x in ("--lowram", "--devices", "--orphans") if x in sys.argv] or \
           ["--lowram", "--devices", "--orphans"]
    for i, w in enumerate(want):
        if i:
            print()
        {"--lowram": lowram, "--devices": devices, "--orphans": orphans}[w]()
