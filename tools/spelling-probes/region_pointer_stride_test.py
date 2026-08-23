#!/usr/bin/env python3
"""Is an embedded region a FLAT pointer table, or a RECORD ARRAY holding one
pointer per N words?

WHY THE QUESTION DECIDES SOMETHING: 30 regions / 13,056 B resolve 25-55% of their
u32 words to real symbols -- 13-29x the 1.879% null, so they certainly hold
addresses. But a record array with one pointer per 2 words resolves at ~50% and
one per 4 words at ~25%, which is exactly the observed range. Emitting every word
as `.long` would describe the non-pointer fields wrongly while keeping the bytes
identical, so NO GATE IN THIS PROJECT WOULD OBJECT. The stride is the difference
between a correct description and a confident wrong one.

TEST: if the region is a record array, the resolving words sit at ONE residue
modulo the record length. Scattered hits mean it is not record-like.

⚠ Chance levels are 1/m -- 50% for m=2, 33% for m=3, 25% for m=4. A result AT
chance is not evidence of a flat table; it only fails to support the record
reading. Both readings can stay open, and for three of these four they do.

⚠ This test did NOT settle the question. It is committed because its numbers are
quoted in notes/FINDINGS-embedded-structure-in-blobs.md, and because knowing it
was inconclusive is worth as much as a verdict would have been. What DOES settle
it is `scripts/analysis/l3_named_offsets_into_blobs.py --base <label>`: the
sources name the interiors, and eight names inside the charmap region show it is
heterogeneous.

Run:  python3 tools/spelling-probes/region_pointer_stride_test.py
"""
import collections, importlib.util, os, pathlib, struct, sys

REPO = pathlib.Path("/home/fsanches/compartilhado/kn5000-roms-disasm")
os.chdir(REPO); sys.path.insert(0, str(REPO))
_c = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)
SY = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")

REGIONS = [("naka_widget_names_charmap.bin", 0x4C00, 0x4F00),
           ("naka_widget_tables_1.bin",      0x1000, 0x1100),
           ("naka_sequencer_channels.bin",   0x1500, 0x1600),
           ("gui_display_struct_data.bin",   0x0B00, 0x1100)]

print(f"  {'region':46} {'resolve':>10}  mod2  mod3  mod4   (chance 50/33/25)")
for base, s, e in REGIONS:
    p = REPO / "v7/maincpu/includes/generated" / base
    if not p.exists():
        print(f"  {base:46}  MISSING"); continue
    b = open(p, "rb").read()
    w = [struct.unpack("<I", b[i:i + 4])[0] for i in range(s, e - 3, 4)]
    hit = [i for i, x in enumerate(w) if x in SY]
    cols = []
    for m in (2, 3, 4):
        if not hit:
            cols.append("  -"); continue
        r = collections.Counter(i % m for i in hit)
        cols.append(f"{100*r.most_common(1)[0][1]//len(hit):3}%")
    print(f"  {base+' 0x%04x'%s:46} {len(hit):4}/{len(w):<4} "
          f"  {cols[0]}  {cols[1]}  {cols[2]}")
print()
print("  AT chance  -> not record-like; the record reading is unsupported.")
print("  ABOVE      -> partly strided, i.e. genuinely record-like.")
print("  Neither outcome establishes a FLAT pointer table, which is why all")
print("  four regions remain unconverted.")
