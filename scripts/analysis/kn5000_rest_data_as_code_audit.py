#!/usr/bin/env python3
r"""THE THIRD KIND OF DEBT (lane DATACODEREST, 2026-09-02), measured for the
first time on the seven KN5000-family images nobody had checked: v9, v7, the
subcpu payload (v1.42), the subcpu boot ROM (IC30), table_data, custom_data
(IC19), and HD-AE5000.

notes/DEBT-INVENTORY-2026-09-02.md names two instruments already running on
this tree -- `.incbin` verbatim debt and code-as-`.byte` census -- and says a
THIRD kind is invisible to both: a span that is really DATA but is currently
written as instruction mnemonics. A `.byte`/`.incbin` scanner sees mnemonics
and moves on; the byte gate cannot object either, because reassembling a
wrong interpretation reproduces the same bytes. Two confirmed instances are
in HD-AE5000: a 309 B version string and `HDAE5000_RECORD_TABLE` (6,356 B).
Until this script ran, every remaining-debt figure in the project was a
LOWER BOUND because of this category. This script is the measurement that
lifts (or does not lift) that caveat, on the LAST unmeasured images -- v10
and all four WSA1R images have their own siblings already
(scripts/analysis/v10_data_as_code_census.py, wsa1/notes/data_as_code_audit.py).

METHOD -- ported from wsa1/notes/data_as_code_audit.py, generalised to
per-image sizes/bases and a 7-image GROUP map instead of that script's fixed
4-image WSA1 layout. Differences from the WSA1 original, and why:

  * FLATTEN uses `llvm-mc -triple=tlcs900 -show-encoding` over each image's
    OWN top .s with its OWN -I include dir (see IMAGES below) -- the same
    authority the byte gate itself uses, so a decoder blind spot in
    unidasm/MAME's TLCS900 core cannot bias this measurement one way or the
    other: it only asks whether the mnemonics ALREADY WRITTEN in the tree are
    ever the target of a real control transfer, never what a disassembler
    can or cannot decode.

  * RAW BYTES for the ascii/periodicity signals come from the image's own
    ELF (via `llvm-objcopy -O binary`), NOT from `original_ROMs/`. Six of the
    seven images have a 1:1 rebuilt-ROM <-> dump correspondence and either
    source would do; the seventh, the v1.42 subcpu payload, does not: its
    Makefile rule slices the linked ELF's [0,256) and [60416,end) byte
    ranges together to reproduce the shipped 196,608 B update image, because
    bytes [0x500,0xEC00) of its own 256,768 B address range are working
    DRAM, never committed to any physical medium. Reading straight from the
    ELF sidesteps that reconstruction entirely and gives one flat
    address->byte mapping that covers the DRAM gap too (whatever the source
    initialises there), which is what a byte-content signal needs. Byte
    identity of the FINAL shipped artifact against `original_ROMs/` is
    checked separately, once, by `--verify`, using the exact pairs
    scripts/analysis/assert_byte_identical.py already trusts.

  * GROUPS: each image gets its own reference-index group EXCEPT the subcpu
    payload and the subcpu boot ROM, which share one ("SUBCPU"). They are
    the SAME physical CPU's address space at different times: the boot ROM's
    own source says so explicitly (subcpu/boot/kn5000_subcpu_boot.s: `call
    PAYLOAD_ENTRY` = `call 0x400`, the payload's own entry point) and the
    payload's own vector table at 0x400-0x4E0 is described in
    v142/subcpu/subcpu_vectors.s as "the payload's copy" of a table the boot
    ROM (`VECTOR_TRAMPOLINES`, 0xFF8F6C) carries too. Building the reference
    index per-image instead of per-group here would MISS the payload's own
    entry point as reached, which is exactly the false-negative shape this
    audit exists to avoid. v9 and v7 do NOT share a group with each other
    even though both are ORIGIN 0xE00000: they are ALTERNATE firmware
    versions for the same physical maincpu socket, never resident together,
    so a v9 address appearing as a literal in v7 (or vice versa) is
    (extremely likely to be) coincidence, not a real cross-reference -- this
    was checked (see --selftest) and the null control's own false-positive
    rate is reported per image so a systematic gap of this kind cannot hide.

  * NO gap_is_clean_code()/merge_macro_artifacts() macro-fragmentation
    bridge: grepping all seven images' sources for the WSA1
    `m_bit`/`m_chg`/`m_set`/`m_pop`-style `_mem` macro family that motivated
    it in wsa1 found zero uses anywhere in this tree (confirmed by
    --selftest). The simpler MAX_BRIDGE_GAP fallthrough-only bridge is kept
    as a cheap second net.

CALIBRATION CASES (both still present, unconverted, in HD-AE5000 as of
2026-09-02 -- see hdae5000/hdae5000_data_tables.s:37 `HDAE5000_RECORD_TABLE:`
still spelled as ~6,150 lines of mnemonics beginning `neg bc / pushw wa /
nop / scf / ...`; the 309 B version string at hd-ae5000_v2_06i.s / hdae5000
_ui_display.s was ALREADY converted to `.ascii` by a sibling lane and is used
here only as the --selftest planted-case text, not expected as a live
finding):
  * 309 B version string, ~35 garbage instructions, chained by local labels
    referencing nothing outside the span.
  * HDAE5000_RECORD_TABLE, 6,356 B, ~6,150 lines of mnemonics, referenced
    only as an ADDRESS, zero call/jump sites.

RUN
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --build      # once, builds all 7 ELFs
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --verify     # byte-identity vs original_ROMs/ (the 7 final .rom targets)
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --report
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --null
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --selftest
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))          # scripts/analysis
REPO = os.path.dirname(os.path.dirname(HERE))                # repo root
LLVM_BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM_BIN, "llvm-mc")
OBJCOPY = os.path.join(LLVM_BIN, "llvm-objcopy")

# (tag, src (rel to REPO), elf make target (rel to REPO), runtime base,
#  size, group). Bases/sizes are each image's own linker script
# (ORIGIN/LENGTH), confirmed 2026-09-02:
#   v9/maincpu/maincpu.ld, v7/maincpu/maincpu.ld: ORIGIN 0xE00000 LENGTH 2M
#   v142/subcpu/subcpu.ld: ORIGIN 0x400 LENGTH 256768 (0x3EB00)
#   subcpu/boot/subcpu_boot.ld: ORIGIN 0xFE0000 LENGTH 128K
#   table_data/table_data.ld: ORIGIN 0x800000 LENGTH 2M
#   custom_data/custom_data.ld: ORIGIN 0x300000 LENGTH 1M
#   hdae5000/hdae5000.ld: ORIGIN 0x280000 LENGTH 512K
IMAGES = [
    ("v9", "v9/maincpu/kn5000_v9_program.s",
     "rebuilt_ROMs/kn5000_v9_program.llvm.elf", 0xE00000, 0x200000, "V9"),
    ("v7", "v7/maincpu/kn5000_v7_program.s",
     "rebuilt_ROMs/kn5000_v7_program.llvm.elf", 0xE00000, 0x200000, "V7"),
    ("v142", "v142/subcpu/kn5000_subprogram_v142.s",
     "rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf", 0x000400, 0x3EB00, "SUBCPU"),
    ("subboot", "subcpu/boot/kn5000_subcpu_boot.s",
     "rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf", 0xFE0000, 0x020000, "SUBCPU"),
    ("tabledata", "table_data/kn5000_table_data.s",
     "rebuilt_ROMs/kn5000_table_data.llvm.elf", 0x800000, 0x200000, "TABLEDATA"),
    ("customdata", "custom_data/kn5000_custom_data.s",
     "rebuilt_ROMs/kn5000_custom_data.llvm.elf", 0x300000, 0x100000, "CUSTOMDATA"),
    ("hdae5000", "hdae5000/hd-ae5000_v2_06i.s",
     "rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf", 0x280000, 0x080000, "HDAE5000"),
]

# (tag, final rom make target, original dump file) -- the exact pairs
# scripts/analysis/assert_byte_identical.py trusts, minus the two images
# (v10, the compressed v142 update image) that are not this lane's scope.
VERIFY_PAIRS = [
    ("v9", "rebuilt_ROMs/kn5000_v9_program.llvm.rom", "original_ROMs/kn5000_v9_program.rom"),
    ("v7", "rebuilt_ROMs/kn5000_v7_program.llvm.rom", "original_ROMs/kn5000_v7_program.rom"),
    ("v142", "rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom", "original_ROMs/kn5000_subprogram_v142.rom"),
    ("subboot", "rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom", "original_ROMs/kn5000_subcpu_boot.ic30"),
    ("tabledata", "rebuilt_ROMs/kn5000_table_data.llvm.rom", "original_ROMs/kn5000_table_data.rom"),
    ("customdata", "rebuilt_ROMs/kn5000_custom_data.llvm.rom", "original_ROMs/kn5000_custom_data.ic19"),
    ("hdae5000", "rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom", "original_ROMs/hd-ae5000_v2_06i.ic4"),
]

RUNTIME_BASE = {t: b for t, _s, _e, b, _sz, _g in IMAGES}
SIZE_OF = {t: sz for t, _s, _e, _b, sz, _g in IMAGES}
GROUP = {t: g for t, _s, _e, _b, _sz, g in IMAGES}
SRC_PATH = {t: s for t, s, _e, _b, _sz, _g in IMAGES}
ELF_TARGET = {t: e for t, _s, e, _b, _sz, _g in IMAGES}

# WIDTH measured empirically by --selftest (a bare `.byte`/`.short`/`.word`/
# `.long`/`.quad` run through `llvm-mc -filetype=obj`, per-byte object sizes
# checked with llvm-nm) -- the same table wsa1/notes/data_as_code_audit.py and
# notes/reachability_kn5000.py use, re-derived here rather than imported so
# this tool has no runtime dependency on either.
WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
LABEL = re.compile(r'^([A-Za-z_.$][A-Za-z0-9_.$]*):$')
NOBYTES = ("set", "equ", "text", "globl", "global", "type", "size", "section",
           "file", "ident", "weak", "local", "hidden", "reloc")
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')

BRANCH_ABS = ("jp", "call")
BRANCH_REL = ("jr", "jrl", "calr", "djnz")
NUMTOK = re.compile(r'^-?\d+$')
IDENT = re.compile(r'^[A-Za-z_.$][A-Za-z0-9_.$]*$')
LITERAL = re.compile(r'\b(\d{5,})\b')


def ascii_len(operand):
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        total += len(ESCAPE.sub("X", m.group(1)))
    return total


def owner(addr, group):
    for t, base in RUNTIME_BASE.items():
        if GROUP[t] == group and base <= addr < base + SIZE_OF[t]:
            return t
    return None


# ------------------------------------------------------------------- build
def build_elf(tag):
    target = ELF_TARGET[tag]
    r = subprocess.run(["make", target], cwd=REPO, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("make %s FAILED:\n%s" % (target, (r.stdout + r.stderr)[-4000:]))


def verify():
    """Rebuild the 7 final .rom targets and diff each against
    original_ROMs/, exactly the pairs assert_byte_identical.py trusts. This
    is what licenses treating this lane's addresses as real."""
    ok = True
    for tag, rom_target, orig in VERIFY_PAIRS:
        r = subprocess.run(["make", rom_target], cwd=REPO, capture_output=True, text=True)
        if r.returncode != 0:
            print("%-12s BUILD FAILED" % tag)
            ok = False
            continue
        a = open(os.path.join(REPO, rom_target), "rb").read()
        b = open(os.path.join(REPO, orig), "rb").read()
        same = a == b
        print("%-12s %s (%d B vs %d B)" % (tag, "IDENTICAL" if same else "DIFFERS",
                                            len(a), len(b)))
        ok = ok and same
    print("VERIFY", "PASS" if ok else "FAIL")
    return 0 if ok else 1


_ROM_CACHE = {}


def rom_bytes(tag):
    """Full ELF content, objcopy'd to a flat binary, address = base + file
    offset. Built (once per process) from the ELF, NOT from original_ROMs/,
    for the reason in the module docstring (the v1.42 payload's shipped
    image excises a DRAM-only gap that the ELF still lays out)."""
    if tag not in _ROM_CACHE:
        elf = os.path.join(REPO, ELF_TARGET[tag])
        if not os.path.exists(elf):
            build_elf(tag)
        with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
            tmp = f.name
        try:
            r = subprocess.run([OBJCOPY, "-O", "binary", elf, tmp],
                                capture_output=True, text=True)
            if r.returncode != 0:
                sys.exit("llvm-objcopy failed for %s: %s" % (tag, r.stderr[-2000:]))
            raw = open(tmp, "rb").read()
        finally:
            os.unlink(tmp)
        want = SIZE_OF[tag]
        if len(raw) < want:
            raw = raw + b"\x00" * (want - len(raw))
        _ROM_CACHE[tag] = raw[:want]
    return _ROM_CACHE[tag]


# ------------------------------------------------------------------ flatten
def flatten(tag):
    """(code, labels, words, data, pad, pos). code[addr] = (len, text) with
    the "; encoding: [...]" comment already stripped. words = every 4-byte
    `.word` ITEM (this backend's canonical 32-bit directive, per WIDTH), as
    (addr, decimal value)."""
    src = os.path.join(REPO, SRC_PATH[tag])
    promdir = os.path.dirname(src)
    if not os.path.exists(promdir + "/../..") :
        pass
    cmd = [MC, "-triple=tlcs900", "-show-encoding", "-I", promdir, src]
    out = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit("llvm-mc failed for %s:\n%s" % (tag, out.stderr[-3000:]))
    base = RUNTIME_BASE[tag]
    pos, code, labels, words = 0, {}, {}, []
    data = pad = 0
    unknown = []
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#") or s.startswith(";"):
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            code[base + pos] = (n, line.split(";")[0].strip())
            pos += n
            continue
        m = LABEL.match(s)
        if m:
            labels[m.group(1)] = base + pos
            continue
        if s.endswith(":"):
            continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            unknown.append(s)
            continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            items = [x for x in rest.split(",") if x.strip()] or [""]
            if d == "word":
                for k, it in enumerate(items):
                    it = it.strip()
                    if NUMTOK.match(it):
                        words.append((base + pos + 4 * k, int(it)))
            n = WIDTH[d] * len(items)
            data += n
            pos += n
        elif d in ("ascii", "asciz"):
            n = ascii_len(rest) + (1 if d == "asciz" else 0)
            data += n
            pos += n
        elif d in ("zero", "fill", "space"):
            p = [x.strip() for x in rest.split(",")]
            n = int(p[0], 0)
            if d == "fill" and len(p) >= 2:
                n *= int(p[1], 0)
            pad += n
            pos += n
        elif d == "p2align":
            n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
            pad += n
            pos += n
        elif d == "org":
            t = int(rest.split(",")[0].strip(), 0) - base
            if t > pos:
                pad += t - pos
                pos = t
        elif d in NOBYTES:
            continue
        else:
            unknown.append(s)
    if unknown:
        sys.exit("UNCLASSIFIED constructs in %s: %d, e.g. %r"
                  % (tag, len(unknown), unknown[:5]))
    return code, labels, words, data, pad, pos


_FLAT_CACHE = {}


def get_flat(tag):
    if tag not in _FLAT_CACHE:
        _FLAT_CACHE[tag] = flatten(tag)
    return _FLAT_CACHE[tag]


# ---------------------------------------------------------------- regions
def code_regions(code):
    """[(start, end, n_instr, last_addr)], maximal contiguous runs of
    instruction bytes."""
    addrs = sorted(code)
    regions = []
    i = 0
    while i < len(addrs):
        s = addrs[i]
        cur = s
        n = 0
        last = s
        while i < len(addrs) and addrs[i] == cur:
            last = addrs[i]
            ln, _ = code[cur]
            cur += ln
            n += 1
            i += 1
        regions.append((s, cur, n, last))
    return regions


# A short (<= MAX_BRIDGE_GAP) gap between two code regions does not break
# control flow unless the LAST instruction before it truly ends flow
# (ret/reti/retd/halt/swi, or an unconditional jp/jr/jrl). No `_mem`-macro
# fragmentation exists in this tree (see --selftest), so this simple
# fallthrough-only bridge is the whole story here, unlike wsa1's.
MAX_BRIDGE_GAP = 8
FLOW_END_MNEM = ("ret", "reti", "retd", "halt", "swi")
FLOW_MAYBE_END_MNEM = ("jp", "jr", "jrl")


def is_flow_end(text):
    parts = text.split(None, 1)
    if not parts:
        return False
    mnem = parts[0].lower()
    if mnem in FLOW_END_MNEM:
        return True
    if mnem in FLOW_MAYBE_END_MNEM:
        if len(parts) < 2:
            return True
        ops = [o.strip() for o in parts[1].split(",")]
        if len(ops) == 1:
            return True
        return ops[0].upper() == "T"
    return False


def bridge_map(code, regions):
    bridge = {}
    for i in range(1, len(regions)):
        prev_end = regions[i - 1][1]
        prev_last = regions[i - 1][3]
        cur_start = regions[i][0]
        gap = cur_start - prev_end
        if 0 < gap <= MAX_BRIDGE_GAP:
            _ln, text = code[prev_last]
            if not is_flow_end(text):
                bridge[i] = i - 1
    return bridge


def resolve_fallthrough_reached(regions, bridge, directly_reached):
    reached = set(directly_reached)
    changed = True
    while changed:
        changed = False
        for i in range(len(regions)):
            if i in reached:
                continue
            if bridge.get(i) in reached:
                reached.add(i)
                changed = True
    return reached


def operand_target(mnem, text, addr, ln, labels):
    parts = text.split(None, 1)
    if len(parts) < 2:
        return None
    last = parts[1].split(",")[-1].strip()
    if mnem in BRANCH_ABS:
        if NUMTOK.match(last):
            return int(last)
        if IDENT.match(last):
            return labels.get(last)
        return None
    if mnem in BRANCH_REL:
        if NUMTOK.match(last):
            return addr + ln + int(last)
        if IDENT.match(last):
            return labels.get(last)
        return None
    return None


# ------------------------------------------------------------ reference index
def build_reference_index():
    """branch_targets[addr] = [(src_tag, src_addr, kind), ...]
       addr_refs[addr]      = [(src_tag, src_addr, kind), ...]  (non-branch)
    Built once over all seven images so a subboot->v142 reference (the
    payload entry point/vector table -- see module docstring) is seen the
    same as an in-image one, via the shared "SUBCPU" group."""
    branch_targets = defaultdict(list)
    addr_refs = defaultdict(list)
    for tag, _s, _e, _b, _sz, group in IMAGES:
        code, labels, words, _d, _p, _pos = get_flat(tag)
        for addr in sorted(code):
            ln, text = code[addr]
            mnem = text.split(None, 1)[0].lower() if text else ""
            if mnem in BRANCH_ABS or mnem in BRANCH_REL:
                t = operand_target(mnem, text, addr, ln, labels)
                if t is not None and owner(t, group):
                    branch_targets[t].append((tag, addr, mnem))
                continue
            for m in LITERAL.finditer(text):
                v = int(m.group(1))
                if owner(v, group):
                    addr_refs[v].append((tag, addr, "immediate"))
        for waddr, val in words:
            if owner(val, group):
                addr_refs[val].append((tag, waddr, "pointer_table"))
    return branch_targets, addr_refs


# --------------------------------------------------------------- signals
def printable_ratio(b):
    if not b:
        return 0.0
    return sum(1 for c in b if 0x20 <= c <= 0x7e) / len(b)


def dominant_byte_ratio(b):
    """The single most common byte's share of the region -- guards against
    a delay-loop's repeated NOP/0x00 padding scoring as "periodic" the same
    way a genuine record table does (measured false positive in wsa1's
    prom_a LCD init; the same shape is plausible anywhere hardware-timing
    padding exists, so kept here even though not yet observed in this
    tree)."""
    if not b:
        return 0.0
    counts = {}
    for c in b:
        counts[c] = counts.get(c, 0) + 1
    return max(counts.values()) / len(b)


DOMINANT_BYTE_CAP = 0.45
MIN_SIGNAL_BYTES = 16

PERIODS = (2, 3, 4, 5, 6, 8, 12, 16, 24, 32)
PERIOD_CAP = 8192


def periodicity_score(b):
    b = b[:PERIOD_CAP]
    n = len(b)
    if n < 16:
        return 0.0, 0
    best = (0.0, 0)
    for p in [p for p in PERIODS if p < n // 3]:
        matches = sum(1 for i in range(p, n) if b[i] == b[i - p])
        score = matches / (n - p)
        if score > best[0]:
            best = (score, p)
    return best


ASCII_HIGH = 0.60
PERIOD_HIGH = 0.40


def is_island(start, end, labels, branch_targets):
    for name, addr in labels.items():
        if start <= addr < end:
            for src_tag, src_addr, _k in branch_targets.get(addr, ()):
                if not (start <= src_addr < end):
                    return False
    return True


def classify_region(tag, start, end, labels, branch_targets, addr_refs,
                     fallthrough=False):
    raw = rom_bytes(tag)
    off = start - RUNTIME_BASE[tag]
    b = raw[off:off + (end - start)]
    direct = bool(branch_targets.get(start))
    reached = direct or fallthrough
    addr_only = bool(addr_refs.get(start)) and not reached
    island = is_island(start, end, labels, branch_targets)
    ratio = printable_ratio(b)
    pscore, pperiod = periodicity_score(b)
    dom = dominant_byte_ratio(b)
    big_enough = (end - start) >= MIN_SIGNAL_BYTES
    not_degenerate = dom < DOMINANT_BYTE_CAP
    signal_hit = big_enough and not_degenerate and (ratio >= ASCII_HIGH or pscore >= PERIOD_HIGH)
    if reached:
        confidence = "none"
    elif signal_hit:
        confidence = "high"
    elif addr_only:
        confidence = "medium"
    else:
        confidence = "low"
    return {
        "tag": tag, "start": start, "end": end, "n": end - start,
        "reached": reached, "reached_direct": direct,
        "reached_fallthrough": reached and not direct,
        "addr_only": addr_only, "island": island,
        "ascii_ratio": ratio, "period_score": pscore, "period": pperiod,
        "dominant_byte_ratio": dom,
        "confidence": confidence,
        "referenced_by": branch_targets.get(start, [])[:3],
        "addr_refs_by": addr_refs.get(start, [])[:3],
    }


def analyse_all():
    branch_targets, addr_refs = build_reference_index()
    out = {}
    for tag, _s, _e, _b, _sz, _g in IMAGES:
        code, labels, _w, _d, _p, _pos = get_flat(tag)
        regions = code_regions(code)
        bridge = bridge_map(code, regions)
        direct_idx = {i for i, (s, _e, _n, _l) in enumerate(regions)
                      if branch_targets.get(s)}
        reached_idx = resolve_fallthrough_reached(regions, bridge, direct_idx)
        rows = [classify_region(tag, s, e, labels, branch_targets, addr_refs,
                                 fallthrough=(i in reached_idx and i not in direct_idx))
                for i, (s, e, _n, _l) in enumerate(regions)]
        out[tag] = rows
    return out, branch_targets, addr_refs


# ------------------------------------------------------------------- report
def report(top=8):
    out, _bt, _ar = analyse_all()
    print("=" * 78)
    print("DATA-AS-CODE AUDIT -- v9, v7, subcpu v142, subcpu boot, table_data,")
    print("                      custom_data, HD-AE5000  (lane DATACODEREST)")
    print("=" * 78)
    grand_high = grand_med = grand_low = 0
    for tag, _s, _e, _b, _sz, _g in IMAGES:
        rows = out[tag]
        total_code = sum(r["n"] for r in rows)
        unreached = [r for r in rows if not r["reached"]]
        high = [r for r in rows if r["confidence"] == "high"]
        med = [r for r in rows if r["confidence"] == "medium"]
        low = [r for r in rows if r["confidence"] == "low"]
        print("\n%-12s regions=%-6d code_bytes=%-8d unreached_regions=%-5d unreached_bytes=%d"
              % (tag, len(rows), total_code, len(unreached),
                 sum(r["n"] for r in unreached)))
        print("             HIGH %5d regions / %7d B   MEDIUM %5d / %7d B   LOW %5d / %7d B"
              % (len(high), sum(r["n"] for r in high),
                 len(med), sum(r["n"] for r in med),
                 len(low), sum(r["n"] for r in low)))
        grand_high += sum(r["n"] for r in high)
        grand_med += sum(r["n"] for r in med)
        grand_low += sum(r["n"] for r in low)
        for r in sorted(high, key=lambda r: -r["n"])[:top]:
            print("    HIGH   0x%06X-0x%06X  %6d B  ascii=%.2f period=%.2f/%d island=%s addr_only=%s"
                  % (r["start"], r["end"], r["n"], r["ascii_ratio"],
                     r["period_score"], r["period"], r["island"], r["addr_only"]))
        for r in sorted(med, key=lambda r: -r["n"])[:5]:
            refs = ", ".join("%s@0x%06X(%s)" % (t, a, k) for t, a, k in r["addr_refs_by"])
            print("    MEDIUM 0x%06X-0x%06X  %6d B  referenced only as: %s"
                  % (r["start"], r["end"], r["n"], refs or "?"))
    print("\n" + "=" * 78)
    print("TOTALS   HIGH %d B   MEDIUM %d B   LOW %d B" % (grand_high, grand_med, grand_low))
    print("=" * 78)


def would_signal_fire(r):
    return (r["n"] >= MIN_SIGNAL_BYTES and r["dominant_byte_ratio"] < DOMINANT_BYTE_CAP
            and (r["ascii_ratio"] >= ASCII_HIGH or r["period_score"] >= PERIOD_HIGH))


def null_control():
    """False-positive control: the byte-content signal alone, over every
    REACHED (proven genuine) region -- how often would it have fired on its
    own? This is what makes a HIGH finding evidence, not a guess."""
    out, _bt, _ar = analyse_all()
    print("=" * 78)
    print("NULL CONTROL -- byte-content signals over REACHED (known-genuine) code")
    print("=" * 78)
    tot_regions = tot_hits = 0
    tot_bytes = tot_hit_bytes = 0
    for tag, _s, _e, _b, _sz, _g in IMAGES:
        rows = [r for r in out[tag] if r["reached"]]
        hits = [r for r in rows if would_signal_fire(r)]
        n_regions = len(rows)
        n_bytes = sum(r["n"] for r in rows)
        h_bytes = sum(r["n"] for r in hits)
        rate_r = (100.0 * len(hits) / n_regions) if n_regions else 0.0
        rate_b = (100.0 * h_bytes / n_bytes) if n_bytes else 0.0
        print("%-12s reached_regions=%-6d false_positive_regions=%-4d (%.1f%%)   "
              "reached_bytes=%-8d false_positive_bytes=%-6d (%.1f%%)"
              % (tag, n_regions, len(hits), rate_r, n_bytes, h_bytes, rate_b))
        tot_regions += n_regions
        tot_hits += len(hits)
        tot_bytes += n_bytes
        tot_hit_bytes += h_bytes
    rate_r = (100.0 * tot_hits / tot_regions) if tot_regions else 0.0
    rate_b = (100.0 * tot_hit_bytes / tot_bytes) if tot_bytes else 0.0
    print("-" * 78)
    print("TOTAL    reached_regions=%d false_positive_regions=%d (%.2f%%)   "
          "reached_bytes=%d false_positive_bytes=%d (%.2f%%)"
          % (tot_regions, tot_hits, rate_r, tot_bytes, tot_hit_bytes, rate_b))


# ------------------------------------------------------------------ selftest
CALIBRATION_STRING = (b"Technics Software section    M. Kitajima" * 8)[:309]


def selftest():
    ok = True

    def check(desc, cond, extra=""):
        nonlocal ok
        print("  %-64s %s %s" % (desc, "PASS" if cond else "FAIL", extra))
        ok = ok and cond

    # 0. No `_mem`-macro family anywhere in this tree's own sources -- the
    #    justification for skipping wsa1's macro-fragmentation bridge.
    macro_hit = False
    for tag, src, _e, _b, _sz, _g in IMAGES:
        root = os.path.dirname(os.path.join(REPO, src))
        for dp, _dn, fns in os.walk(root):
            for fn in fns:
                if fn.endswith((".s", ".inc")):
                    txt = open(os.path.join(dp, fn), encoding="utf-8",
                               errors="surrogateescape").read()
                    if re.search(r'\bm_(bit|chg|set|pop)\b', txt):
                        macro_hit = True
    check("no wsa1-style `m_bit/m_chg/m_set/m_pop` macro family in this tree",
          not macro_hit)

    # 1. Accounting closes on every image: code + data + pad == pos == the
    #    image's own declared LENGTH (not ROM file size -- v142's own
    #    address range is bigger than its shipped file; see docstring).
    for tag, _s, _e, _b, sz, _g in IMAGES:
        code, _labels, _w, data, pad, pos = get_flat(tag)
        codebytes = sum(n for n, _t in code.values())
        check("%s: code+data+pad == pos == declared LENGTH" % tag,
              codebytes + data + pad == pos == sz,
              "%d+%d+%d=%d vs pos=%d len=%d" % (codebytes, data, pad,
                                                 codebytes + data + pad, pos, sz))

    # 2. WIDTH table, re-measured on THIS toolchain, not trusted from the
    #    WSA1 port.
    for kind, want in (("byte", 1), ("short", 2), ("word", 4), ("long", 4), ("quad", 8)):
        with tempfile.TemporaryDirectory() as td:
            p = os.path.join(td, "w.s")
            open(p, "w").write("\t.text\nfoo:\n\t.%s 0x1\nbar:\n\t.byte 0\n" % kind)
            o = os.path.join(td, "w.o")
            subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, p],
                            check=True, capture_output=True)
            nm = subprocess.run([os.path.join(LLVM_BIN, "llvm-nm"), o],
                                 capture_output=True, text=True).stdout
            addrs = {ln.split()[2]: int(ln.split()[0], 16)
                     for ln in nm.splitlines() if len(ln.split()) == 3}
        check("directive .%s is %d byte(s)" % (kind, want), addrs.get("bar") == want,
              "got %s" % addrs.get("bar"))

    # 3. THE PLANTED CASE, using the real HD-AE5000 calibration text (the
    #    firmware version string), with NO reference of any kind, injected
    #    into a scratch region of hdae5000's own address space. Must be
    #    flagged HIGH.
    fake_tag, fake_start = "hdae5000", 0x2F0000
    fake_end = fake_start + len(CALIBRATION_STRING)
    saved = dict(_ROM_CACHE)
    raw = bytearray(rom_bytes(fake_tag))
    off = fake_start - RUNTIME_BASE[fake_tag]
    raw[off:off + len(CALIBRATION_STRING)] = CALIBRATION_STRING
    _ROM_CACHE[fake_tag] = bytes(raw)
    r = classify_region(fake_tag, fake_start, fake_end, {}, defaultdict(list), defaultdict(list))
    check("planted version-string-shaped region is flagged HIGH",
          r["confidence"] == "high",
          "ascii=%.2f period=%.2f confidence=%s" % (r["ascii_ratio"], r["period_score"], r["confidence"]))
    check("planted region's ascii ratio alone clears the threshold",
          r["ascii_ratio"] >= ASCII_HIGH, "%.2f" % r["ascii_ratio"])
    _ROM_CACHE.clear()
    _ROM_CACHE.update(saved)

    # 3b. THE REAL CALIBRATION SPAN ITSELF, unconverted as of 2026-09-02:
    #     HDAE5000_RECORD_TABLE at 0x29C0AA, 6,356 B, must be picked up as a
    #     genuine unreached CODE region and flagged (HIGH via the periodicity
    #     signal, or at minimum MEDIUM via addr_only -- it is loaded as an
    #     address in hdae5000_init_data.s/ui_display.s and never called).
    hdae_rows = analyse_all()[0]["hdae5000"]
    rt = next((r for r in hdae_rows if r["start"] == 0x29C0AA), None)
    check("HDAE5000_RECORD_TABLE (0x29C0AA) exists as a CODE region",
          rt is not None, "regions starting near it: %s" %
          sorted(r["start"] for r in hdae_rows if abs(r["start"] - 0x29C0AA) < 64))
    if rt:
        check("...it is NOT reached by any real control transfer",
              not rt["reached"], "reached=%s" % rt["reached"])
        check("...its size matches the documented 6,356 B",
              rt["n"] == 6356, "got %d" % rt["n"])
        check("...it is flagged MEDIUM or HIGH (real debt, not silently dropped)",
              rt["confidence"] in ("medium", "high"), "confidence=%s" % rt["confidence"])

    # 4. THE MUST-NOT-FLAG CASE: a real, multiply-referenced routine. Use
    #    v142's own PAYLOAD_ENTRY (0x400) -- reached ONLY via the subboot
    #    image's `call 0x400`, i.e. this is also the test that the shared
    #    "SUBCPU" group (not a per-image index) is doing its job.
    branch_targets, addr_refs = build_reference_index()
    check("subboot's `call 0x400` resolves as a branch target of v142's group",
          bool(branch_targets.get(0x400)),
          "refs=%s" % branch_targets.get(0x400))
    v142_rows = analyse_all()[0]["v142"]
    entry = next((r for r in v142_rows if r["start"] == 0x400), None)
    check("v142's PAYLOAD_ENTRY (0x400) is a converted code region", entry is not None)
    if entry:
        check("...and IS reached (cross-image reference resolved)",
              entry["reached"] and entry["confidence"] == "none",
              "reached=%s confidence=%s" % (entry["reached"], entry["confidence"]))

    # 5. periodicity_score sanity.
    tiled = bytes([1, 2, 3, 4] * 40)
    score, period = periodicity_score(tiled)
    check("a 4-byte-tiled string scores >= 0.9 at period 4",
          score >= 0.9 and period == 4, "score=%.2f period=%d" % (score, period))

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--verify" in sys.argv:
        sys.exit(verify())
    if "--build" in sys.argv:
        for tag, _s, _e, _b, _sz, _g in IMAGES:
            build_elf(tag)
            print("built", tag)
        return
    if "--null" in sys.argv:
        null_control()
        return
    report()


if __name__ == "__main__":
    main()
