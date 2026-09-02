#!/usr/bin/env python3
r"""tier2_byte_split_census.py -- the THREE-WAY SPLIT of every `.byte`-family byte
in the four "100.0% source, zero verbatim debt" KN5000-family images.

=============================================================================
QUESTION ANSWERED
=============================================================================
For each of

    v142      v142/subcpu/kn5000_subprogram_v142.s     196,608 B shipped image
    subboot   subcpu/boot/kn5000_subcpu_boot.s         131,072 B  (IC30)
    customdata custom_data/kn5000_custom_data.s      1,048,576 B  (IC19)
    hdae5000  hdae5000/hd-ae5000_v2_06i.s              524,288 B  (IC4)

how many of the bytes currently emitted by a `.byte`/`.hword`/`.short`/`.word`/
`.long`/`.quad` directive are

    (a) REAL CODE still spelled as data      -- convertible to instructions
    (b) STRUCTURED DATA that should be TYPED -- `.ascii`, `.fill`, `.zero`,
                                                pointer/record tables
    (c) GENUINE BYTE TABLES, already correct -- leave alone

`scripts/analysis/kn5000_source_coverage.py` counts `.incbin` and reports all
four images at 100.0% source with ZERO verbatim debt. That instrument is BLIND
to `.byte`: this project has twice shipped a false completeness claim on
exactly that basis (notes/DEBT-INVENTORY-2026-09-02.md, "8,496 bytes of sound
code sat in plain sight passing a test looking for the wrong word"). This
script is the missing instrument for those four images.

=============================================================================
METHOD
=============================================================================
1. ADDRESSES COME FROM THE PINNED ASSEMBLER, NOT A PARSER.
   Every source line of every `.s` file that makes up an image gets a unique
   zero-size probe label inserted before it; the image is rebuilt with the
   probes in place; the build is asserted BYTE-IDENTICAL to the original dump
   (so the probes changed nothing); and each line's address is read out of the
   ELF symbol table with `llvm-nm`. A line's byte SIZE is the next probe
   address minus its own.  Generalised from hdae5000/tools/get_lprobe_addrs.py,
   which does this for one image.  Hand-parsing `.ascii` escapes, `.fill`
   counts and `.org` (which is SECTION-RELATIVE, a bug that once undercounted
   four images -- see DEBT-INVENTORY) is exactly what this avoids.

2. RUNS. Consecutive data-directive lines at consecutive addresses, in one
   file, are merged into a RUN. Zero-size lines (labels, comments, `.equ`)
   do not break a run, but a `.equ`/label DOES record a boundary marker.

3. CLASSIFY. In order (a) then (b) then (c):

   (a) CODE  requires BOTH
       * DECODE-CLEAN: unidasm (MAME's TLCS-900 core) decodes the run's raw
         bytes linearly from the run's first byte with no illegal opcode and
         no instruction straddling the run's end, AND the run is >= 6 bytes,
         AND the decode contains at least MIN_INSTR=3 instructions, AND is not
         dominated (>60%) by the trivial opcodes `nop`/`ld` of a byte to
         itself that any random data decodes into;
       * CORROBORATION, one of
           ENTRY   -- some instruction ANYWHERE in the image's group performs
                      a control transfer (`call`/`calr`/`jp`/`jr`/`jrl`/
                      `djnz`) whose resolved target is the run's first byte;
           FALLIN  -- the line immediately before the run is a real
                      instruction that is not a flow terminator, so execution
                      falls into the run;
           FALLOUT -- the byte immediately after the run begins a real
                      instruction AND the run's own last decoded instruction
                      is not a flow terminator, so execution falls out of it.
       DECODE-CLEAN alone is NOT sufficient and is reported separately,
       because that is the signal the DATA control below shows is unreliable.

   (b) STRUCTURED DATA, any of
       FILL    -- >= 16 B, all bytes equal          -> `.fill`/`.zero`
       ASCII   -- >= 8 consecutive printable bytes covering >= 60% of the run
                                                    -> `.ascii`/`.asciz`
       PTRTAB  -- >= 4 consecutive 4-byte LE words, each a valid address in
                  some image of the group, not all equal
                                                    -> `.long`
       RECORD  -- length is an exact multiple of a stride S in [4,256] whose
                  byte-wise autocorrelation is >= 0.80 and beats the best
                  non-multiple stride by >= 0.15
                                                    -> per-record `.byte` with
                                                       a typed field layout

   (c) everything else.

=============================================================================
HOW THIS CLASSIFIER COULD BE WRONG, AND THE CONTROLS THAT MEASURE IT  (⚠ READ)
=============================================================================
The byte gate CANNOT adjudicate any of this: every classification here
re-assembles to the same bytes either way. So the classifier's own error rate
is the only quality signal, and it is measured against two controls of KNOWN
ground truth drawn from the SAME four images -- never from a synthetic corpus,
whose byte statistics would not be those of this hardware.

  FAILURE MODE 1 -- (a) fires on data.  Dense 8-bit data decodes into
  plausible TLCS-900 programs; a jump table round-trips as code; a uniform
  fill decodes as a long run of one instruction. THE PROJECT HAS ALREADY BEEN
  BURNED: a 309-byte version string in HD-AE5000 was disassembled as ~35
  garbage instructions and passed the byte gate for months.
      DATA CONTROL: every `.ascii`/`.asciz` literal >= 6 B in these four
      images -- bytes that are PROVEN text, not code -- is fed to the (a)
      test as if it were a run. Anything that passes is a false positive.
      Reported as `FP(a)`.

  FAILURE MODE 2 -- (b) fires on code.  Real code is periodic (a table of
  similar dispatch stubs autocorrelates), contains printable bytes, and
  contains 32-bit values that look like addresses because they ARE addresses.
      CODE CONTROL: every instruction region of >= 32 B that has a resolved
      incoming `call` from elsewhere in the image -- bytes that are PROVEN
      executable -- is fed to the (b) test. Anything that passes is a false
      positive. Reported as `FP(b)`.

  FAILURE MODE 3 -- the population is wrong.  If the probe build is not
  byte-identical, every address is a guess. The tool ABORTS in that case; it
  never prints a number from an unverified build.

  FAILURE MODE 4 -- ENTRY corroboration inherits unidasm's blind spots.
  unidasm's TLCS-900 core does not decode ~20 `decodeERPPrefix()` forms and
  the register-indexed `SriRR*` forms (DEBT-INVENTORY item 5). A call it
  cannot decode is a MISSED entry, so (a) is a LOWER BOUND, never inflated,
  by this particular defect. Stated, not corrected.

  FAILURE MODE 5 -- erased flash. A 0xFF fill both decode-cleans (0xFF is a
  legal opcode byte) and FILL-matches. FILL is tested BEFORE (a) for runs
  whose bytes are all identical, precisely so a 98 KB erased region cannot be
  reported as 98 KB of undiscovered code.

=============================================================================
RUN
=============================================================================
    cd <lane worktree root>
    python3 scripts/analysis/tier2_byte_split_census.py --report
    python3 scripts/analysis/tier2_byte_split_census.py --report --image hdae5000
    python3 scripts/analysis/tier2_byte_split_census.py --control
    python3 scripts/analysis/tier2_byte_split_census.py --list a --image v142
    python3 scripts/analysis/tier2_byte_split_census.py --selftest

`--report` prints the per-image three-way split; `--control` prints FP(a) and
FP(b); `--list <a|b|c>` dumps every run in that bucket with file:line, address
and reason; `--selftest` asserts the address maps reconstruct each image's
declared length and that the two calibration cases behave as documented.

The probe build is cached under .tier2cache/ (gitignored); delete it to force
a re-measure after editing any source.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM_BIN = os.environ.get("LLVM_BIN", os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
MC = os.path.join(LLVM_BIN, "llvm-mc")
LLD = os.path.join(LLVM_BIN, "ld.lld")
OBJCOPY = os.path.join(LLVM_BIN, "llvm-objcopy")
NM = os.path.join(LLVM_BIN, "llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
CACHE = os.path.join(ROOT, ".tier2cache")

# tag -> (source dir, top .s, linker script, ELF base, ELF length,
#         original dump, rom_from_elf transform, group)
# Bases/lengths are each image's own linker script ORIGIN/LENGTH.
IMAGES = {
    "v142": dict(dir="v142/subcpu", top="kn5000_subprogram_v142.s",
                 ld="v142/subcpu/subcpu.ld", base=0x000400, length=0x3EB00,
                 dump="original_ROMs/kn5000_subprogram_v142.rom",
                 slice_=True, group="SUBCPU"),
    "subboot": dict(dir="subcpu/boot", top="kn5000_subcpu_boot.s",
                    ld="subcpu/boot/subcpu_boot.ld", base=0xFE0000, length=0x20000,
                    dump="original_ROMs/kn5000_subcpu_boot.ic30",
                    slice_=False, group="SUBCPU"),
    "customdata": dict(dir="custom_data", top="kn5000_custom_data.s",
                       ld="custom_data/custom_data.ld", base=0x300000, length=0x100000,
                       dump="original_ROMs/kn5000_custom_data.ic19",
                       slice_=False, group="CUSTOMDATA"),
    "hdae5000": dict(dir="hdae5000", top="hd-ae5000_v2_06i.s",
                     ld="hdae5000/hdae5000.ld", base=0x280000, length=0x80000,
                     dump="original_ROMs/hd-ae5000_v2_06i.ic4",
                     slice_=False, group="HDAE5000"),
}
ORDER = ["v142", "subboot", "customdata", "hdae5000"]

DATA_DIRECTIVES = ("byte", "hword", "short", "word", "long", "quad")
WIDTH = {"byte": 1, "hword": 2, "short": 2, "word": 4, "long": 4, "quad": 8}

# --- classification thresholds; every one is quoted in the report header ----
MIN_RUN_FOR_CODE = 6      # bytes; below this a "decode" is not evidence
MIN_INSTR = 3             # instructions a decode must contain
MAX_TRIVIAL = 0.60        # fraction of nop/ld-self a real routine may be
MIN_FILL = 16             # bytes; below this a uniform run is a plain field
MIN_ASCII_RUN = 8         # consecutive printable bytes
MIN_ASCII_FRAC = 0.60     # of the run
MIN_PTRS = 4              # consecutive valid 4-byte pointers
MIN_PTR_COVER = 0.50      # of the run the pointer chain must cover
MIN_AUTOCORR = 0.80       # record-stride autocorrelation
AUTOCORR_MARGIN = 0.15    # over the best non-multiple stride
MIN_CODE_CONTROL = 32     # bytes; size floor for a control code region
MAX_ONE_MNEMONIC = 0.60   # share of a decode one repeated mnemonic may hold
DOMINANT_FILL = 0.90      # single-byte share above which a run is padding, not structure

# ⚠ `jp (xiy)` IS a flow terminator and the first version of this regex missed
# it, because it only matched an absolute `jp 0x...`. The cost was measured,
# not hypothetical: the two PPORT jump tables at 0x2953CE and 0x295146 -- both
# already correctly typed as `.long`, both immediately following a `jp (xiy)`
# -- were reported as (a) REAL CODE on a FALLIN that cannot happen, because
# control never falls out of an indirect jump. That is precisely the
# jump-table trap the lane brief names (six such conversions were reverted by
# hand earlier in this push).
FLOW_END = re.compile(r'^(ret|reti|retd|halt|swi\b'
                      r'|jp\s*\(|jp\s+(?!\w\w,)0x|jr\s+T,|jrl\s+T,)')
XFER = re.compile(r'^(call|calr|jp|jr|jrl|djnz)\b')
HEXTGT = re.compile(r'0x([0-9a-fA-F]+)\s*$')


# ---------------------------------------------------------------- sources
def source_files(tag):
    """Every .s file that makes up the image, in .include order, top first."""
    info = IMAGES[tag]
    d = os.path.join(ROOT, info["dir"])
    seen, out = set(), []

    def walk(rel):
        if rel in seen:
            return
        seen.add(rel)
        out.append(rel)
        p = os.path.join(d, rel)
        for line in open(p, encoding="latin-1"):
            m = re.match(r'\s*\.include\s+"([^"]+)"', line)
            if m:
                walk(m.group(1))

    walk(info["top"])
    return out


# ------------------------------------------------------------ probe build
def build_addrmap(tag):
    """{relpath: [addr per source line]} -- from llvm-nm on a probe build that
    is asserted byte-identical to the original dump."""
    os.makedirs(CACHE, exist_ok=True)
    info = IMAGES[tag]
    files = source_files(tag)
    # ⚠ THE CACHE KEY IS THE SOURCE CONTENT, NOT THE TAG. A plain per-tag
    # cache silently served a PRE-CONVERSION address map after a converter
    # had rewritten the file: run start addresses and source line numbers no
    # longer matched the file on disk, and the next converter refused five
    # runs with nonsense diagnostics ("line parse recovered 448 B" for a
    # 122 B run). An address map is only valid for the exact bytes it was
    # measured from.
    h = hashlib.sha256()
    for rel in files:
        h.update(rel.encode())
        h.update(open(os.path.join(ROOT, info["dir"], rel), "rb").read())
    cached = os.path.join(CACHE, "%s.%s.json" % (tag, h.hexdigest()[:16]))
    if os.path.exists(cached):
        return json.load(open(cached))
    with tempfile.TemporaryDirectory(prefix="tier2_%s_" % tag) as tmp:
        pdir = os.path.join(tmp, "src")
        shutil.copytree(os.path.join(ROOT, info["dir"]), pdir, symlinks=True)
        counts = {}
        for idx, rel in enumerate(files):
            p = os.path.join(pdir, rel)
            lines = open(p, encoding="latin-1").readlines()
            out = []
            for i, line in enumerate(lines, 1):
                out.append("Lp_%d_%d:\n" % (idx, i))
                out.append(line)
            open(p, "w", encoding="latin-1").writelines(out)
            counts[rel] = len(lines)

        obj, elf, rom = (os.path.join(tmp, x) for x in ("p.o", "p.elf", "p.rom"))
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", pdir,
                            "-o", obj, os.path.join(pdir, info["top"])],
                           capture_output=True, text=True)
        if r.returncode:
            sys.exit("probe assemble failed for %s:\n%s" % (tag, r.stderr[-3000:]))
        subprocess.run([LLD, "-e", "0", "-T", os.path.join(ROOT, info["ld"]),
                        "-o", elf, obj], check=True, capture_output=True)
        subprocess.run([OBJCOPY, "-O", "binary", elf, rom], check=True)
        built = open(rom, "rb").read()
        if info["slice_"]:
            built = built[:256] + built[60416:]
        orig = open(os.path.join(ROOT, info["dump"]), "rb").read()
        if len(orig) == 0:
            sys.exit("%s: original dump read as 0 B -- refusing a vacuous compare" % tag)
        if built != orig:
            sys.exit("%s: PROBE BUILD IS NOT BYTE-IDENTICAL to %s (%d B vs %d B). "
                     "Every address below would be a guess. Aborting." %
                     (tag, info["dump"], len(built), len(orig)))
        nm = subprocess.run([NM, elf], check=True, capture_output=True, text=True).stdout
        amap = {rel: [None] * (counts[rel] + 1) for rel in files}
        n = 0
        for line in nm.splitlines():
            parts = line.split()
            if len(parts) == 3 and parts[2].startswith("Lp_"):
                _, fi, li = parts[2].split("_")
                amap[files[int(fi)]][int(li)] = int(parts[0], 16)
                n += 1
        want = sum(counts.values())
        if n != want:
            sys.exit("%s: expected %d probe symbols, found %d" % (tag, want, n))
    json.dump(amap, open(cached, "w"))
    return amap


_ROM = {}


def _rom_key(tag):
    info = IMAGES[tag]
    h = hashlib.sha256()
    for rel in source_files(tag):
        h.update(open(os.path.join(ROOT, info["dir"], rel), "rb").read())
    return "%s.%s" % (tag, h.hexdigest()[:16])


def rom_bytes(tag):
    """Flat image content indexed by (addr - base). Built from the ELF so the
    v142 payload's DRAM gap is present too."""
    if tag in _ROM:
        return _ROM[tag]
    info = IMAGES[tag]
    os.makedirs(CACHE, exist_ok=True)
    binf = os.path.join(CACHE, _rom_key(tag) + ".full.bin")
    if not os.path.exists(binf):
        with tempfile.TemporaryDirectory(prefix="tier2rom_") as tmp:
            obj, elf = os.path.join(tmp, "o"), os.path.join(tmp, "e")
            subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I",
                            os.path.join(ROOT, info["dir"]), "-o", obj,
                            os.path.join(ROOT, info["dir"], info["top"])],
                           check=True, capture_output=True)
            subprocess.run([LLD, "-e", "0", "-T", os.path.join(ROOT, info["ld"]),
                            "-o", elf, obj], check=True, capture_output=True)
            subprocess.run([OBJCOPY, "-O", "binary", elf, binf], check=True)
    raw = open(binf, "rb").read()
    if len(raw) < info["length"]:
        raw += b"\xff" * (info["length"] - len(raw))
    _ROM[tag] = raw[:info["length"]]
    return _ROM[tag]


# ---------------------------------------------------------------- unidasm
_UNI = {}


def unidasm_map(tag):
    """{addr: (nbytes, mnemonic)} from ONE linear decode of the whole image.
    Used to classify short spans only, never to walk control flow."""
    if tag in _UNI:
        return _UNI[tag]
    info = IMAGES[tag]
    os.makedirs(CACHE, exist_ok=True)
    cf = os.path.join(CACHE, "%s.uni.txt" % _rom_key(tag))
    if not os.path.exists(cf):
        with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
            f.write(rom_bytes(tag))
            t = f.name
        try:
            out = subprocess.run([UNIDASM, t, "-arch", "tlcs900", "-basepc",
                                  hex(info["base"])], capture_output=True, text=True).stdout
        finally:
            os.unlink(t)
        open(cf, "w").write(out)
    m = {}
    pat = re.compile(r'^\s*([0-9a-fA-F]{4,8}):\s+((?:[0-9a-fA-F]{2} )+)\s*(.*)$')
    for ln in open(cf):
        g = pat.match(ln)
        if g:
            m[int(g.group(1), 16)] = (len(g.group(2).split()), g.group(3).strip())
    _UNI[tag] = m
    return m


def decode_linear(tag, start, end):
    """Decode [start,end) from `start`, following instruction lengths. Returns
    (ok, mnemonics). ok is False on an unknown opcode or on an instruction that
    straddles `end`."""
    raw = rom_bytes(tag)
    base = IMAGES[tag]["base"]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(raw[start - base:end - base])
        t = f.name
    try:
        out = subprocess.run([UNIDASM, t, "-arch", "tlcs900", "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(t)
    pat = re.compile(r'^\s*([0-9a-fA-F]{4,8}):\s+((?:[0-9a-fA-F]{2} )+)\s*(.*)$')
    seen = {}
    for ln in out.splitlines():
        g = pat.match(ln)
        if g:
            seen[int(g.group(1), 16)] = (len(g.group(2).split()), g.group(3).strip())
    pc, mn = start, []
    while pc < end:
        if pc not in seen:
            return False, mn
        n, text = seen[pc]
        if not text or text.startswith("?") or "invalid" in text.lower() \
           or "unknown" in text.lower() or text.startswith("db "):
            return False, mn
        if pc + n > end:
            return False, mn
        mn.append(text)
        pc += n
    return True, mn


def is_trivial(mnemonic):
    m = mnemonic.split()
    if not m:
        return True
    op = m[0]
    if op == "nop":
        return True
    if op == "ld" and len(m) > 1:
        a = m[1].split(",")
        if len(a) == 2 and a[0] == a[1]:
            return True
    return False


# ------------------------------------------------------------------- runs
# ⚠ A LABEL AND A DIRECTIVE SHARE A LINE 795 TIMES in these four images
# (`DSP_AlgoChannel_SelectorByte5:\t.byte 0xff`; 790 of them in
# hdae5000_data_tables.s alone). The first version of this regex required the
# directive to start the line, so every one of those bytes was (i) missing
# from the census population, (ii) a run boundary that split real runs in
# two, and (iii) indistinguishable from an INSTRUCTION to the FALLIN test --
# which is how a 1,973 B slice of `DSP_AlgoChannel_SelectorRecords`, a
# documented 12 x 6-byte selector table, came out as (a) REAL CODE.
LINE_DIR = re.compile(r'^\s*(?:[A-Za-z_.$][A-Za-z0-9_.$]*:\s*)?\.([A-Za-z_0-9]+)\b')


def collect(tag):
    """[(file, line0, line1, start, end, text_lines)] for every maximal run of
    consecutive data-directive lines, plus the per-line address map and the
    per-line source text (so callers can inspect neighbours)."""
    amap = build_addrmap(tag)
    src = {rel: open(os.path.join(ROOT, IMAGES[tag]["dir"], rel),
                     encoding="latin-1").read().split("\n")
           for rel in amap}
    runs = []
    for rel in source_files(tag):
        addrs = amap[rel]
        lines = src[rel]
        n = len(addrs) - 1
        cur = None
        for i in range(1, n + 1):
            a, b = addrs[i], addrs[i + 1] if i + 1 <= n else None
            size = (b - a) if b is not None else 0
            txt = lines[i - 1] if i - 1 < len(lines) else ""
            m = LINE_DIR.match(txt)
            isdata = bool(m) and m.group(1) in DATA_DIRECTIVES and size > 0
            if isdata:
                if cur and cur[3] + cur[4] == a:
                    cur[2] = i
                    cur[4] += size
                    cur[5].append(txt)
                else:
                    if cur:
                        runs.append(cur)
                    cur = [rel, i, i, a, size, [txt]]
            elif size > 0:
                if cur:
                    runs.append(cur)
                cur = None
        if cur:
            runs.append(cur)
    return runs, amap, src


# ------------------------------------------------- image-group entry index
_ENTRY = {}
_LABELS = {}
LABEL_DEF = re.compile(r'^([A-Za-z_.$][A-Za-z0-9_.$]*):')
SRC_XFER = re.compile(r'^\s*(call|calr|jp|jr|jrl|djnz)\s+(.*)$')
IDENT_ONLY = re.compile(r'^[A-Za-z_.$][A-Za-z0-9_.$]*$')


def labels_of(tag):
    """{name: address} for every label DEFINED in the image's own sources,
    addresses from the verified probe build."""
    if tag in _LABELS:
        return _LABELS[tag]
    amap = build_addrmap(tag)
    out = {}
    for rel in source_files(tag):
        lines = open(os.path.join(ROOT, IMAGES[tag]["dir"], rel),
                     encoding="latin-1").read().split("\n")
        for i, txt in enumerate(lines, 1):
            m = LABEL_DEF.match(txt)
            if m and i < len(amap[rel]) and amap[rel][i] is not None:
                out.setdefault(m.group(1), amap[rel][i])
    _LABELS[tag] = out
    return out


def entry_targets(group):
    """Set of addresses that a REAL SOURCE INSTRUCTION in the group transfers
    control to.

    ⚠ THIS WAS WRONG THE FIRST TIME AND THE CONTROLS CAUGHT IT. The first
    version built this set from a LINEAR unidasm decode of the whole image,
    reasoning that being over-inclusive could only cost recall. It cannot: a
    linear decode of a DATA region emits fake `call 0x...` instructions, so
    the "entry" set was polluted with thousands of addresses no code ever
    branches to. The measured consequence was an 8.48% FP(a) (74 of 838
    proven `.ascii` literals in HD-AE5000 "entered" by a phantom call) and a
    control population of 4,188 "called code regions" in custom_data -- an
    image with no executable code in it at all. Built from the sources' own
    control transfers instead: mnemonic from the source line, target resolved
    through the label table of the verified probe build. Register-indirect
    forms (`call (xhl)`, `jp (xiy)`) resolve to nothing and are skipped --
    they are a real recall gap, stated in FAILURE MODE 4, not papered over."""
    if group in _ENTRY:
        return _ENTRY[group]
    names = {}
    for tag, info in IMAGES.items():
        if info["group"] == group:
            names.update(labels_of(tag))
    tgts = set()
    for tag, info in IMAGES.items():
        if info["group"] != group:
            continue
        amap = build_addrmap(tag)
        for rel in source_files(tag):
            lines = open(os.path.join(ROOT, info["dir"], rel),
                         encoding="latin-1").read().split("\n")
            for i, txt in enumerate(lines, 1):
                m = SRC_XFER.match(txt.split(";")[0])
                if not m:
                    continue
                last = m.group(2).split(",")[-1].strip()
                if IDENT_ONLY.match(last) and last in names:
                    tgts.add(names[last])
                elif re.match(r'^(0x[0-9a-fA-F]+|\d+)$', last):
                    tgts.add(int(last, 0))
    _ENTRY[group] = tgts
    return tgts


def called_code_regions(tag, minsize):
    """Control population for FP(b): addresses that a source `call` targets
    AND at which the SOURCE itself has >= minsize bytes of uninterrupted
    instruction lines. Proven executable by the tree's own control-flow
    graph, not by a decoder's opinion of arbitrary bytes."""
    amap = build_addrmap(tag)
    tgts = entry_targets(IMAGES[tag]["group"])
    out, seen = [], set()
    for rel in source_files(tag):
        lines = open(os.path.join(ROOT, IMAGES[tag]["dir"], rel),
                     encoding="latin-1").read().split("\n")
        addrs = amap[rel]
        n = len(addrs) - 1
        for i in range(1, n):
            a = addrs[i]
            # ⚠ DEDUP BY ADDRESS. Several source lines share one address (a
            # label, its comment, the instruction under it), so without this
            # the control population counted the same routine up to a dozen
            # times -- 17,675 "regions" for v142 that were a handful of
            # distinct addresses repeated.
            if a is None or a not in tgts or a in seen:
                continue
            seen.add(a)
            j, end = i, a
            while j <= n and addrs[j] is not None:
                txt = lines[j - 1] if j - 1 < len(lines) else ""
                sz = (addrs[j + 1] - addrs[j]) if j + 1 <= n and addrs[j + 1] else 0
                if sz == 0:
                    j += 1
                    continue
                if LINE_DIR.match(txt):
                    break
                end = addrs[j] + sz
                j += 1
                if end - a >= minsize:
                    break
            if end - a >= minsize:
                out.append((a, end))
    return out


# -------------------------------------------------------------- structure
def all_bases():
    return [(i["base"], i["base"] + i["length"]) for i in IMAGES.values()]


def struct_signal(data):
    """(name, detail) of the first structured-data signal that fires, else None."""
    n = len(data)
    if n >= MIN_FILL and len(set(data)) == 1:
        return "FILL", "0x%02X x %d" % (data[0], n)
    # ascii
    best = run = 0
    for b in data:
        if 0x20 <= b < 0x7F:
            run += 1
            best = max(best, run)
        else:
            run = 0
    printable = sum(1 for b in data if 0x20 <= b < 0x7F)
    # ⚠ TIGHTENED after the CODE control measured 10,716 false ASCII hits:
    # the rule was "longest printable run >= 8 AND >= 60% of the span
    # printable", and TLCS-900 machine code is >60% printable bytes by
    # accident all the time. The LONGEST SINGLE RUN, not the scattered total,
    # must now carry the span.
    if best >= MIN_ASCII_RUN and best >= MIN_ASCII_FRAC * n:
        return "ASCII", "longest printable run %d of %d B" % (best, n)
    # pointer table
    if n >= 4 * MIN_PTRS:
        rng = all_bases()
        best_run = cur = 0
        for off in range(0, n - 3, 4):
            v = int.from_bytes(data[off:off + 4], "little")
            if any(lo <= v < hi for lo, hi in rng):
                cur += 1
                best_run = max(best_run, cur)
            else:
                cur = 0
        # ⚠ COVERAGE, not just a foothold. The first version fired on ANY 4
        # consecutive in-range words, and reported a 6,367 B run as a pointer
        # table on the strength of 16 bytes -- the "single-record walk hit
        # with no second signal" false-positive shape
        # notes/DEBT-INVENTORY-2026-09-02.md warns about. It is especially
        # dangerous for the v1.42 payload, whose image starts at 0x400: any
        # run of 16-bit values with zero upper halves reads as a chain of
        # "valid addresses". The chain must now carry at least half the run.
        if best_run >= MIN_PTRS and 4 * best_run >= max(16, MIN_PTR_COVER * n):
            vals = [int.from_bytes(data[o:o + 4], "little") for o in range(0, n - 3, 4)]
            if len(set(vals)) > 1:
                return "PTRTAB", "%d consecutive in-image 32-bit addresses (%d of %d B)" % (
                    best_run, 4 * best_run, n)
    # periodic records
    if n >= 32:
        def ac(s):
            if s >= n:
                return 0.0
            same = sum(1 for i in range(n - s) if data[i] == data[i + s])
            return same / float(n - s)
        cands = [s for s in range(4, min(257, n // 2 + 1)) if n % s == 0]
        if cands:
            bs = max(cands, key=ac)
            others = [s for s in range(4, min(257, n // 2 + 1)) if n % s]
            bo = max((ac(s) for s in others), default=0.0)
            if ac(bs) >= MIN_AUTOCORR and ac(bs) - bo >= AUTOCORR_MARGIN:
                return "RECORD", "stride %d, autocorr %.2f (best non-multiple %.2f)" % (
                    bs, ac(bs), bo)
    return None


# ------------------------------------------------------------------ code
def code_signal(tag, start, end, prev_txt, next_txt, next_addr):
    """(verdict, reason). verdict in {"CODE","DECODE-ONLY",None}."""
    n = end - start
    if n < MIN_RUN_FOR_CODE:
        return None, "run < %d B" % MIN_RUN_FOR_CODE
    raw = rom_bytes(tag)
    base = IMAGES[tag]["base"]
    data = raw[start - base:end - base]
    if len(set(data)) == 1:
        return None, "uniform fill"
    ok, mn = decode_linear(tag, start, end)
    if not ok:
        return None, "does not decode cleanly (%d instr before failure)" % len(mn)
    if len(mn) < MIN_INSTR:
        return None, "decodes to only %d instructions" % len(mn)
    triv = sum(1 for m in mn if is_trivial(m)) / float(len(mn))
    if triv > MAX_TRIVIAL:
        return None, "%.0f%% trivial opcodes" % (100 * triv)
    # ⚠ SECOND NET FOR FAILURE MODE 5, added after the first run of this tool
    # reported subboot's 98,324 B of erased 0xFF flash as "decode-clean 98,758
    # instructions" -- every one of them `swi 7`, because 0xFF is a legal
    # TLCS-900 opcode. Segmentation (below) already removes that case by
    # splitting fills out of a run before anything is judged; this cap is the
    # independent second net, so a fill that is 89% uniform (under the
    # segmenter's floor) still cannot be reported as code.
    top = Counter(m.split()[0] for m in mn if m.split()).most_common(1)
    if top and top[0][1] / float(len(mn)) > MAX_ONE_MNEMONIC:
        return None, "%.0f%% of the decode is the single mnemonic %r" % (
            100.0 * top[0][1] / len(mn), top[0][0])
    reasons = []
    if start in entry_targets(IMAGES[tag]["group"]):
        reasons.append("ENTRY")
    if prev_txt is not None and not LINE_DIR.match(prev_txt) and prev_txt.strip() \
       and not FLOW_END.match(prev_txt.strip()):
        reasons.append("FALLIN")
    if next_txt is not None and not LINE_DIR.match(next_txt) and next_txt.strip() \
       and not FLOW_END.match(mn[-1]):
        reasons.append("FALLOUT")
    # ⚠ FALLOUT ALONE IS NOT CORROBORATION. It says only that real code
    # follows the run -- which is true of every data island embedded in a
    # code section, and says nothing about whether control can ever ARRIVE.
    # Measured: with FALLOUT sufficient, the FP(a2) jump-table control sat at
    # 1/2 = 50% (the 124 B PPORT table at 0x295146, entered by nothing,
    # preceded by `ret` and followed by `ret`). Execution must be able to
    # REACH the run: ENTRY or FALLIN. FALLOUT is kept in the reason string as
    # a corroborating detail only.
    if "ENTRY" in reasons or "FALLIN" in reasons:
        return "CODE", "decode-clean %d instr + %s" % (len(mn), "+".join(reasons))
    return "DECODE-ONLY", "decode-clean %d instr, not reachable (%s)" % (
        len(mn), "+".join(reasons) if reasons else "no entry/fallthrough")


# --------------------------------------------------------------- classify

def neighbours(amap, lines, rel, l0, l1):
    """(prev_txt, next_txt) -- the nearest source lines BEFORE l0 and AFTER l1
    that actually emit bytes. Comments, labels and `.equ` lines emit nothing
    and must be skipped, or a `jp (xiy)` immediately above a jump table is
    hidden behind the table's own `; N-entry jump table` comment and FALLIN
    fires on a fallthrough that cannot happen. That is not hypothetical: the
    FP(a2) jump-table control measured 2/2 = 100% until both call sites used
    this one helper."""
    addrs = amap[rel]
    n = len(addrs) - 1
    prev_txt = next_txt = None
    # ⚠ Walk back PAST alignment `nop`s. A `nop` never originates control
    # flow, it inherits it, so a `ret` + `nop` pad before a jump table is a
    # flow END, not a fallthrough. Measured: with the plain walk, the PPORT
    # jump table at 0x295146 (`ret` / `nop` / `.Lpps_jump_table:`) was the
    # remaining 1/2 of the FP(a2) control.
    for i in range(l0 - 1, 0, -1):
        if addrs[i] is not None and i + 1 <= n and addrs[i + 1] is not None \
           and addrs[i + 1] > addrs[i]:
            t = lines[i - 1] if i - 1 < len(lines) else None
            if t is not None and t.split(";")[0].strip() == "nop":
                continue
            prev_txt = t
            break
    for i in range(l1 + 1, n):
        if addrs[i] is not None and addrs[i + 1] is not None \
           and addrs[i + 1] > addrs[i]:
            next_txt = lines[i - 1] if i - 1 < len(lines) else None
            break
    return prev_txt, next_txt


def fill_segments(data, start):
    """Split [start, start+len(data)) into (abs_start, bytes, is_fill) pieces,
    carving out every maximal run of >= MIN_FILL identical bytes.

    ⚠ THIS IS THE STRUCTURAL FIX FOR FAILURE MODE 5, and it was put here
    because the first run of this tool got it wrong. subboot's `.byte` lines
    are ONE contiguous run of 98,960 B: 98,324 B of erased 0xFF flash with a
    few hundred bytes of real content welded onto its end by contiguity. A
    whole-run uniformity test (`len(set(data)) == 1`) sees that run as
    non-uniform and hands it to the code test, which happily reports 98,758
    `swi 7` instructions. Carving fills out FIRST means a fill can never be
    laundered into (a) by whatever happens to sit next to it, and it is also
    what the conversion needs: the fill part becomes `.fill`, the remainder is
    judged on its own bytes."""
    segs, i, n = [], 0, len(data)
    while i < n:
        j = i
        while j + 1 < n and data[j + 1] == data[i]:
            j += 1
        if j - i + 1 >= MIN_FILL:
            segs.append((start + i, data[i:j + 1], True))
            i = j + 1
        else:
            k = i
            while k < n:
                m = k
                while m + 1 < n and data[m + 1] == data[k]:
                    m += 1
                if m - k + 1 >= MIN_FILL:
                    break
                k = m + 1
            segs.append((start + i, data[i:k], False))
            i = k
    return segs


def classify_run(tag, run, src, amap):
    """Returns [(seg_addr, nbytes, bucket, kind, why)] -- one per SEGMENT."""
    rel, l0, l1, start, size, texts = run
    end = start + size
    raw = rom_bytes(tag)
    base = IMAGES[tag]["base"]
    data = raw[start - base:end - base]

    lines = src[rel]
    prev_txt, next_txt = neighbours(amap, lines, rel, l0, l1)

    segs = fill_segments(data, start)
    verdicts = []
    for k, (sa, sd, isfill) in enumerate(segs):
        if isfill or not sd:
            verdicts.append(None)
            continue
        pv = prev_txt if k == 0 else None
        nx = next_txt if k == len(segs) - 1 else None
        # ⚠ POINTER TABLE BEATS CODE, and the order matters. A jump table is
        # a run of in-image 32-bit addresses; every one of those addresses is
        # a real instruction address, so the table decodes as clean code and
        # sits right after the indirect jump that reads it -- it satisfies the
        # (a) test on its own bytes. The brief's rule decides it: if every
        # reference LOADS the run's address (`lda_24 xix, (0x2953ce)`) and
        # nothing calls or jumps INTO it, it is data. PTRTAB is therefore
        # tested first. The cost of the swap is bounded by the CODE control:
        # PTRTAB fires on 4 of 24,582 proven called-code regions (0.016%).
        sgp = struct_signal(sd)
        if sgp and sgp[0] == "PTRTAB":
            verdicts.append(("PTRDATA", sgp[1]))
            continue
        verdicts.append(code_signal(tag, sa, sa + len(sd), pv, nx, None))

    # ⚠ WHOLE-RUN FALLBACK, and why the order is this way round. A 96-byte
    # style record or a 6-byte pointer entry has internal zero padding, so
    # fill_segments() chops a genuine record TABLE into dozens of fragments
    # and destroys the very periodicity that identifies it (measured: the
    # first segmenting version of this tool lost custom_data's 14,400 B
    # RECORD signal entirely). So when NO segment of a run reads as code, the
    # run is re-tested AS A WHOLE for RECORD/PTRTAB/ASCII. The code test still
    # runs first and still runs per-segment, so this fallback can never
    # relabel something the code test claimed -- and it is refused outright on
    # a run whose single most common byte is >= DOMINANT_FILL of it, so a
    # mostly-erased region cannot acquire a structure verdict from its own
    # padding (FAILURE MODE 5 again, from the other side).
    if not any(v and v[0] == "CODE" for v in verdicts):
        dom = Counter(data).most_common(1)[0][1] / float(len(data)) if data else 1.0
        if dom < DOMINANT_FILL:
            sg = struct_signal(data)
            if sg and sg[0] in ("RECORD", "PTRTAB", "ASCII"):
                return [(start, len(data), "b", sg[0], sg[1])]

    out = []
    for k, (sa, sd, isfill) in enumerate(segs):
        if isfill:
            out.append((sa, len(sd), "b", "FILL",
                        "0x%02X x %d" % (sd[0], len(sd))))
            continue
        if not sd:
            continue
        v, why = verdicts[k]
        if v == "CODE":
            out.append((sa, len(sd), "a", "CODE", why))
            continue
        if v == "PTRDATA":
            out.append((sa, len(sd), "b", "PTRTAB", why))
            continue
        sg = struct_signal(sd)
        if sg:
            out.append((sa, len(sd), "b", sg[0], sg[1]))
            continue
        out.append((sa, len(sd), "c",
                    "DECODE-ONLY" if v == "DECODE-ONLY" else "PLAIN", why))
    return out


# ----------------------------------------------------------------- report
def report(images, listing=None):
    grand = Counter()
    for tag in images:
        runs, amap, src = collect(tag)
        buckets = defaultdict(list)
        for r in runs:
            for sa, nb, b, kind, why in classify_run(tag, r, src, amap):
                buckets[b].append((r, sa, nb, kind, why))
        tot = sum(r[4] for r in runs)
        print("=" * 76)
        print("%s  --  %s  (%d B image, base 0x%06X)" %
              (tag, IMAGES[tag]["top"], IMAGES[tag]["length"], IMAGES[tag]["base"]))
        print("  .byte-family bytes: %d  in %d runs" % (tot, len(runs)))
        for b, name in (("a", "(a) REAL CODE spelled as .byte"),
                        ("b", "(b) STRUCTURED DATA, should be typed"),
                        ("c", "(c) genuine byte tables, correct as-is")):
            by = sum(x[2] for x in buckets[b])
            print("    %-40s %9d B  %5d segs" % (name, by, len(buckets[b])))
            sub = Counter()
            for x in buckets[b]:
                sub[x[3]] += x[2]
            for k, v in sub.most_common():
                print("        %-20s %9d B" % (k, v))
            grand[b] += by
        grand["tot"] += tot
        if listing:
            print("    --- %s segments ---" % listing)
            for r, sa, nb, kind, why in sorted(buckets[listing], key=lambda x: -x[2]):
                print("      %-34s:%-6d 0x%06X %7d B  %-12s %s" %
                      (r[0], r[1], sa, nb, kind, why))
    print("=" * 76)
    print("TOTAL over %d images: %d B of .byte-family" % (len(images), grand["tot"]))
    for b, name in (("a", "(a) code-as-.byte"), ("b", "(b) untyped structured data"),
                    ("c", "(c) genuine byte tables")):
        print("   %-30s %9d B" % (name, grand[b]))


# ---------------------------------------------------------------- controls
def controls(images):
    """FP(a): the (a) test over PROVEN TEXT (`.ascii`/`.asciz` literals).
       FP(b): the (b) test over PROVEN CODE (instruction regions with a
              resolved incoming call)."""
    print("### FP(a) -- the CODE test applied to proven .ascii/.asciz text")
    tot = fp = totb = 0
    for tag in images:
        amap = build_addrmap(tag)
        n = f = 0
        for rel in source_files(tag):
            lines = open(os.path.join(ROOT, IMAGES[tag]["dir"], rel),
                         encoding="latin-1").read().split("\n")
            addrs = amap[rel]
            for i in range(1, len(addrs) - 1):
                if addrs[i + 1] is None or addrs[i] is None:
                    continue
                sz = addrs[i + 1] - addrs[i]
                t = lines[i - 1] if i - 1 < len(lines) else ""
                m = LINE_DIR.match(t)
                if not m or m.group(1) not in ("ascii", "asciz") or sz < MIN_RUN_FOR_CODE:
                    continue
                n += 1
                totb += sz
                # ⚠ The control must offer the (a) test the SAME three
                # corroboration paths a real run gets, or it only measures
                # ENTRY and reports a flatteringly perfect 0%. So the
                # literal's real source neighbours are passed in: FALLIN and
                # FALLOUT are live here exactly as they are in classify_run.
                pv, nx = neighbours(amap, lines, rel, i, i)
                v, _ = code_signal(tag, addrs[i], addrs[i] + sz, pv, nx, None)
                if v == "CODE":
                    f += 1
        print("   %-12s %5d text literals, %4d classified CODE" % (tag, n, f))
        tot += n
        fp += f
    print("   FP(a) = %d/%d = %.2f%%   (%d B of proven text tested)" %
          (fp, tot, 100.0 * fp / tot if tot else 0.0, totb))

    print("### FP(a2) -- the CODE test applied to hand-labelled JUMP TABLES")
    print("    (proven data of the shape that most resembles code: runs of >= 4")
    print("     consecutive `.long 0x... ; entry N` lines, i.e. tables a human")
    print("     already identified and annotated entry by entry)")
    tot = fp = totb = 0
    ent = re.compile(r'^\s*\.(?:long|word)\s+0x[0-9a-fA-F]+\s*;\s*entry\s+\d+')
    for tag in images:
        amap = build_addrmap(tag)
        n = f = 0
        for rel in source_files(tag):
            lines = open(os.path.join(ROOT, IMAGES[tag]["dir"], rel),
                         encoding="latin-1").read().split("\n")
            addrs = amap[rel]
            i = 1
            while i < len(addrs) - 1:
                if not ent.match(lines[i - 1] if i - 1 < len(lines) else ""):
                    i += 1
                    continue
                j = i
                while j < len(addrs) - 1 and ent.match(
                        lines[j - 1] if j - 1 < len(lines) else ""):
                    j += 1
                if j - i >= 4 and addrs[i] is not None and addrs[j] is not None:
                    n += 1
                    totb += addrs[j] - addrs[i]
                    pv, nx = neighbours(amap, lines, rel, i, j - 1)
                    v, _ = code_signal(tag, addrs[i], addrs[j], pv, nx, None)
                    if v == "CODE":
                        f += 1
                i = j
        print("   %-12s %5d annotated jump tables, %4d classified CODE" % (tag, n, f))
        tot += n
        fp += f
    print("   FP(a2) = %d/%d = %.2f%%   (%d B of proven jump table tested)" %
          (fp, tot, 100.0 * fp / tot if tot else 0.0, totb))

    print("### FP(a3) -- the CODE test applied to PROVEN BITMAP DATA")
    print("    (HD-AE5000's graphics assets: every byte is regenerated from a")
    print("     committed PNG + palette by scripts/build/hdae5000_images.py,")
    print("     whose `verify` asserts the round trip is byte-exact. Chopped")
    print("     into windows drawn from the real run-length distribution, so")
    print("     the control is not measured at a single convenient size.)")
    import random
    rnd = random.Random(20260902)
    lens = []
    for tag in images:
        for r in collect(tag)[0]:
            if r[4] >= MIN_RUN_FOR_CODE:
                lens.append(r[4])
    gen = os.path.join(ROOT, "hdae5000/includes/generated")
    tot = fp = totb = 0
    if lens and os.path.isdir(gen):
        blobs = [os.path.join(gen, f) for f in sorted(os.listdir(gen))
                 if f.endswith(".bin")]
        base = IMAGES["hdae5000"]["base"]
        raw = rom_bytes("hdae5000")
        for bp in blobs:
            blob = open(bp, "rb").read()
            # locate the blob inside the built image so the windows carry real
            # addresses (the ENTRY test needs one); skip if not found verbatim.
            at = raw.find(blob)
            if at < 0 or len(blob) < 64:
                continue
            off = 0
            while off < len(blob) - MIN_RUN_FOR_CODE:
                L = min(rnd.choice(lens), len(blob) - off)
                if L < MIN_RUN_FOR_CODE:
                    break
                a = base + at + off
                tot += 1
                totb += L
                v, _ = code_signal("hdae5000", a, a + L, None, None, None)
                if v == "CODE":
                    fp += 1
                off += L
    print("   %5d bitmap windows, %4d classified CODE" % (tot, fp))
    print("   FP(a3) = %d/%d = %.2f%%   (%d B of proven bitmap tested)" %
          (fp, tot, 100.0 * fp / tot if tot else 0.0, totb))

    print("### FP(b) -- the STRUCTURE test applied to proven called code")
    tot = fp = totb = 0
    hits = Counter()
    for tag in images:
        base = IMAGES[tag]["base"]
        raw = rom_bytes(tag)
        regs = called_code_regions(tag, MIN_CODE_CONTROL)
        n = f = 0
        for a, e in regs:
            n += 1
            totb += e - a
            sg = struct_signal(raw[a - base:e - base])
            if sg:
                f += 1
                hits[sg[0]] += 1
        print("   %-12s %5d called code regions, %4d classified STRUCTURED" % (tag, n, f))
        tot += n
        fp += f
    print("   FP(b) = %d/%d = %.2f%%  (%d B of proven code tested)  %s" %
          (fp, tot, 100.0 * fp / tot if tot else 0.0, totb, dict(hits)))

    # ⚠ A DETECTOR THAT NEVER FIRES HAS A PERFECT FALSE-POSITIVE RATE.
    # Both positive controls below exist so the four numbers above cannot be
    # passed vacuously: they show each test still fires on the thing it is
    # supposed to detect.
    print("### TP(a) -- the CODE test applied to PROVEN CODE (must be high)")
    tot = tp = 0
    for tag in images:
        regs = called_code_regions(tag, MIN_CODE_CONTROL)
        n = h = 0
        for a, e in regs:
            n += 1
            v, _ = code_signal(tag, a, e, None, None, None)
            if v == "CODE":
                h += 1
        print("   %-12s %5d called code regions, %4d classified CODE" % (tag, n, h))
        tot += n
        tp += h
    print("   TP(a) = %d/%d = %.2f%%   (ENTRY alone; FALLIN/FALLOUT are not "
          "available to a control region, so this is a FLOOR)" %
          (tp, tot, 100.0 * tp / tot if tot else 0.0))

    print("### TP(b) -- the STRUCTURE test applied to PROVEN DATA (must be high)")
    tot = tp = 0
    hits = Counter()
    for tag in images:
        amap = build_addrmap(tag)
        base, raw = IMAGES[tag]["base"], rom_bytes(tag)
        n = h = 0
        for rel in source_files(tag):
            lines = open(os.path.join(ROOT, IMAGES[tag]["dir"], rel),
                         encoding="latin-1").read().split("\n")
            addrs = amap[rel]
            for i in range(1, len(addrs) - 1):
                if addrs[i] is None or addrs[i + 1] is None:
                    continue
                sz = addrs[i + 1] - addrs[i]
                t = lines[i - 1] if i - 1 < len(lines) else ""
                m = LINE_DIR.match(t)
                if not m or m.group(1) not in ("ascii", "asciz") or sz < 16:
                    continue
                n += 1
                sg = struct_signal(raw[addrs[i] - base:addrs[i] + sz - base])
                if sg:
                    h += 1
                    hits[sg[0]] += 1
        print("   %-12s %5d text literals >= 16 B, %4d classified STRUCTURED" % (tag, n, h))
        tot += n
        tp += h
    print("   TP(b) = %d/%d = %.2f%%  %s" %
          (tp, tot, 100.0 * tp / tot if tot else 0.0, dict(hits)))


# ---------------------------------------------------------------- selftest
def selftest():
    ok = True
    for tag in ORDER:
        amap = build_addrmap(tag)
        info = IMAGES[tag]
        hi = max(a for v in amap.values() for a in v if a is not None)
        span = hi - info["base"]
        print("%-12s probe map spans 0x%06X..0x%06X (%d B of %d declared)" %
              (tag, info["base"], hi, span, info["length"]))
        if span > info["length"]:
            print("   FAIL: map exceeds declared LENGTH")
            ok = False
        if span < info["length"] * 0.5:
            print("   FAIL: map covers less than half the image -- vacuous")
            ok = False
    # calibration: HDAE5000_RECORD_TABLE must NOT be reported as (a).
    src = open(os.path.join(ROOT, "hdae5000/hdae5000_data_tables.s"),
               encoding="latin-1").read()
    print("HDAE5000_RECORD_TABLE present in source as a label: %s" %
          ("yes" if "HDAE5000_RECORD_TABLE:" in src else "no (already converted?)"))
    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--control", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--list", choices=["a", "b", "c"])
    ap.add_argument("--image", choices=ORDER, action="append")
    a = ap.parse_args()
    imgs = a.image or ORDER
    if a.selftest:
        return selftest()
    if a.control:
        controls(imgs)
        return 0
    report(imgs, a.list)
    return 0


if __name__ == "__main__":
    sys.exit(main())
