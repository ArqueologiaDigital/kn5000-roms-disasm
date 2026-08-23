#!/usr/bin/env python3
"""Which of the 45 embedded pointer regions are actually CONVERTIBLE?

`l3_embedded_structure_scan.py` says 45 regions / 25,344 B inside OPAQUE blobs
hold ROM-range u32s with a clean shuffle control. "Lands in the ROM address
range" is a weak property, though: 0xE00000..0xFFFFFF is a sixth of the u32
space, and the organ/accordion blob scores 64/64 on it while holding u16 drawbar
levels. Before proposing any conversion, each region needs stronger evidence and
a check that the mechanics are even possible.

FOUR TESTS, reported separately -- never summed:

  T1 RESOLVES   what fraction of the words hit an ACTUAL ELF symbol address, not
                merely the address range. Compared against the base rate for
                uniformly random ROM-range addresses, so "many hits" means
                something.
  T2 ORDERED    a table of pointers to variable-length records is usually
                MONOTONIC -- in EITHER direction. ⚠ The first version accepted
                only ascending and scored the 100%-resolving charmap table at 0%,
                because it descends -- as does the documented
                `DspEffectName_PtrTable`, which the sources say is stored in
                descending effect order. Descriptive, not disqualifying.
  T3 TARGET     how wide a span the targets cover. Descriptive only: a table may
                legitimately point across the whole ROM.
  T4 PLACEABLE  is the blob `.incbin`'d exactly once, so a split has one site to
                edit? A blob included from several places cannot be split
                without deciding what each site should now say.

QUALIFICATION = T1 >> null AND T4. T2/T3 are printed because they characterise
the table, not because a table failing them is disqualified.

⚠ THREE separate bookkeeping defects in this probe produced clean, wrong
disqualifications before any of them was the data's fault: globbing v7 twice so
every blob looked multiply-included (T4=0/45); scoring v9 and v10 blobs against
v7's symbol table (identical regions differing 100% vs 54.7%); and accepting only
ascending order (T2=0% on a descending table). Each printed a confident number.
Same family as the DATA=0 constant -- when a criterion disqualifies EVERYTHING,
suspect the criterion.

⚠ A region passing the qualification is a CANDIDATE. Nothing here proves the words are
pointers; it says the cheap disqualifiers do not fire. The conversion itself is
gated by the byte-match, as always.

Run:  python3 tools/spelling-probes/qualify_embedded_ptr_regions.py
"""
import glob, importlib.util, os, pathlib, re, struct, subprocess, sys

REPO = pathlib.Path("/home/fsanches/compartilhado/kn5000-roms-disasm")
os.chdir(REPO)
ROM_LO, ROM_HI = 0xE00000, 0x1000000

sys.path.insert(0, str(REPO))
_s = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_s); _s.loader.exec_module(cc)
# ⚠ SCORE EACH BLOB AGAINST ITS OWN REVISION. The first version tested v9 and
# v10 blobs against v7's symbol table, so the identical region scored 100% in v7
# and 54.7% in v9/v10 -- a difference that was entirely the wrong symbol table.
_ELF = {"v7": "rebuilt_ROMs/kn5000_v7_program.llvm.elf",
        "v9": "rebuilt_ROMs/kn5000_v9_program.llvm.elf",
        "v10": "rebuilt_ROMs/kn5000_v10_program.llvm.elf"}
SYMS = {}
for _rev, _path in _ELF.items():
    if os.path.exists(_path):
        SYMS[_rev] = set(cc.elf_syms(_path))
symaddrs = SYMS.get("v7", set())


def syms_for(path):
    parts = str(path).split(os.sep)
    for rev in ("v7", "v9", "v10"):
        if rev in parts:
            return SYMS.get(rev, symaddrs)
    return symaddrs

_e = importlib.util.spec_from_file_location(
    "scan", REPO / "scripts/analysis/l3_embedded_structure_scan.py")
scan = importlib.util.module_from_spec(_e); _e.loader.exec_module(scan)
_t = importlib.util.spec_from_file_location(
    "tri", REPO / "scripts/analysis/l3_slice_structure_triage.py")
tri = importlib.util.module_from_spec(_t); _t.loader.exec_module(tri)

# How often does a UNIFORM ROM-range address hit a real symbol? The null for T1.
import random
rng = random.Random(11)
null = sum(1 for _ in range(20000)
           if rng.randrange(ROM_LO, ROM_HI) in symaddrs) / 20000
print(f"  ELF symbols: {len(symaddrs)}")
print(f"  NULL: a uniform ROM-range address hits a symbol {100*null:.2f}% of the time")
print()

# ⚠ DEDUPE. The first version globbed "v7/maincpu/**/*.s" AND "*/**/*.s", which
# both match every v7 file, so every blob appeared included at least twice and
# T4 was 0 for all 45 regions -- a clean, wrong disqualification produced by the
# search, not the tree. Same family as the DATA=0 constant.
incbin_sites = {}
for f in sorted(set(glob.glob("*/**/*.s", recursive=True))):
    try:
        txt = open(f, encoding="latin1").read()
    except OSError:
        continue
    # ⚠ KEY ON (revision, basename), NOT basename. The same blob exists in v7,
    # v9 and v10, so keying on the basename alone counted three revisions as
    # three include sites and T4 was 0 for every region -- the second wrong
    # disqualification this probe produced from its own bookkeeping.
    _rev = next((r for r in ("v7", "v9", "v10") if r in f.split(os.sep)), "?")
    for m in re.finditer(r'\.incbin\s+"([^"]+)"', txt):
        incbin_sites.setdefault((_rev, os.path.basename(m.group(1))), []).append(f)

rows = []
for f in tri.blobs():
    b = open(f, "rb").read()
    if len(b) < scan.WIN:
        continue
    k, _ = tri.classify(b)
    if k != "OPAQUE":
        continue
    for s, e, kind in scan.scan(b):
        if kind != "PTR_TABLE" or e - s < 256:
            continue
        w = [struct.unpack("<I", b[i:i + 4])[0] for i in range(s, e - 3, 4)]
        if not w:
            continue
        _sy = syms_for(f)
        t1 = sum(1 for x in w if x in _sy) / max(1, len(w))
        _up = sum(1 for i in range(len(w) - 1) if w[i + 1] >= w[i])
        _dn = (len(w) - 1) - _up
        t2 = max(_up, _dn) / max(1, len(w) - 1)       # monotonic EITHER way
        spanw = max(w) - min(w)
        t3 = spanw < 0x40000
        base = os.path.basename(str(f))
        _r = next((r for r in ("v7", "v9", "v10") if r in str(f).split(os.sep)), "?")
        t4 = len(incbin_sites.get((_r, base), [])) == 1
        rows.append((e - s, t1, t2, t3, t4, str(f.relative_to(REPO)), s, e))

rows.sort(reverse=True)
print(f"  {'bytes':>7} {'T1resolv':>9} {'T2asc':>6} {'T3':>3} {'T4':>3}  region            blob")
for n, t1, t2, t3, t4, base, s, e in rows[:22]:
    print(f"  {n:7,} {100*t1:8.1f}% {100*t2:5.0f}% {str(t3):>3} {str(t4):>3}"
          f"  0x{s:06x}-0x{e:06x}  {base}")

strong = [r for r in rows if r[1] > 10 * null and r[4]]
print()
print(f"  QUALIFIED (T1 >> null AND single .incbin site) : {len(strong)}"
      f"   ({sum(r[0] for r in strong):,} B)")
print(f"  regions where T1 beats the null by 10x         : "
      f"{sum(1 for r in rows if r[1] > 10*null)}")
print(f"  regions whose blob has ONE .incbin site (T4)   : "
      f"{sum(1 for r in rows if r[4])}")
print()
print("  ⚠ Counts are of DIFFERENT tests and are not additive.")
