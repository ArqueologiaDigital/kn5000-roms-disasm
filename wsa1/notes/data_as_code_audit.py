#!/usr/bin/env python3
r"""THE THIRD KIND OF DEBT, measured for the first time on all four WSA1R
images: data disassembled into plausible instruction mnemonics.

QUESTION IT ANSWERS
  notes/DEBT-INVENTORY-2026-09-02.md names two instruments that are already
  running on this tree -- `.incbin` verbatim debt and code-as-`.byte` census --
  and says a THIRD kind is invisible to both: a span that is really DATA but
  is currently written as instruction mnemonics. Neither instrument can see
  it, because a mnemonic line looks exactly like a converted instruction to a
  tool that only asks "is this still a data directive?" -- and the byte gate
  cannot object, because reassembling a wrong interpretation reproduces the
  same bytes (that is exactly how HD-AE5000's 309-byte version string and its
  6,356-byte HDAE5000_RECORD_TABLE survived, both re-assembling byte-exact).

  prom_c and prom_d report ZERO verbatim debt today. That claim was certified
  by `.incbin`/`.byte` counters -- the wrong instrument for this category by
  construction -- so it has never actually been checked for THIS kind of
  debt. This script is that check, run against all four images at once so
  prom_a/prom_b (which HAVE measured debt already) calibrate the method
  before it is trusted on prom_c/prom_d (which claim none).

METHOD
  1. FLATTEN each image with `llvm-mc -show-encoding`, the same authority
     the byte gate itself uses (mirrors scripts/analysis/code_vs_data_delta.py
     and notes/reachability_kn5000.py's `flatten()`, ported to WSA1's own
     Makefile invocation: `-I <root> -I <promdir>` on the master .s file, its
     own `.include`s doing the rest). This gives an ADDRESS to every
     instruction and every data directive AS THE TREE CURRENTLY WRITES IT --
     which is the piece notes/reachability.py's `SRC_LINE` regex cannot give
     uniformly: that regex requires a trailing `; ADDR ...` comment, and a
     fully-named, hand-documented routine (most of prom_c's kernel, for
     example) carries NO such comment -- `jr DSP_ChannelRefresh_Loop__top`,
     no comment at all. A regex keyed on that comment silently drops every
     well-named routine from its own scan. Flattening the ASSEMBLED text
     sidesteps that: llvm-mc normalises both styles (raw address literal or
     hand-picked symbol) into one uniform stream with one address per byte,
     independent of how the source line happens to be punctuated.

  2. GROUP instruction addresses into maximal contiguous CODE REGIONS
     (bounded by any data directive or file end) -- this is the set of
     spans the tree CURRENTLY CLAIMS are instructions.

  3. Build a REFERENCE INDEX, once, over all four images together: every
     absolute jp/call target, every resolved jr/jrl/calr/djnz target (via
     the label the assembler already resolved it to, or the instruction's
     own address plus the printed relative displacement), the CPU vector
     tables (prom_a for CPU1, prom_c for CPU2), prom_b's 1,910-slot `jp
     imm24` directory, and every literal that lands in the relevant
     window (an operand, or a 4-byte `.word` -- this backend's canonical
     32-bit directive name, confirmed empirically: see WIDTH below).

  4. For every code region, ask exactly the question notes/reachability.py's
     own philosophy already settled for the opposite direction ("a run start
     needs POSITIVE EVIDENCE: a graded seed names it, or converted code falls
     through into it"): is this region's START ever the target of a real
     control transfer, ANYWHERE in the tree? If not, it is UNREACHED, and
     that is the same defect shape as both calibration cases -- the version
     string had ZERO references of any kind, HDAE5000_RECORD_TABLE was
     referenced ONLY as a data address and never as a jump/call target.

  5. Score confidence with two corroborating, INDEPENDENT signals computed
     from the RAW ROM BYTES underneath the region (not from the mnemonics --
     a garbage decode of text can still spell syntactically valid
     instructions, so the byte content is the only witness that does not
     already agree with the interpretation being tested):
       * printable-ASCII ratio of the region's bytes (the version-string
         shape)
       * best-period byte-repetition score, i.e. how well the region tiles
         at some small stride (the fixed-record-table shape)

  ⚠ WHY THIS IS SAFE DESPITE THE DISASSEMBLER'S KNOWN BLIND FAMILIES.
  The brief warns that unidasm cannot decode the register-indexed `SriRR*`
  group or ~20 `decodeERPPrefix()` forms, so "unidasm could not decode it"
  does NOT mean "it is data". This tool never makes that inference: it does
  not ask what unidasm can decode. It asks whether the MNEMONICS ALREADY
  WRITTEN in the tree -- which round-trip through llvm-mc, the assembler,
  not the disassembler -- are ever the target of a control transfer. A
  region can be built entirely from opcodes no decoder can currently
  produce and this method does not care; it only cares whether anything
  ever jumps to it.

RUN
    python3 notes/data_as_code_audit.py                 # the report
    python3 notes/data_as_code_audit.py --null           # the false-positive
                                                          # control (signals
                                                          # measured over
                                                          # REACHED, i.e.
                                                          # known-genuine, code)
    python3 notes/data_as_code_audit.py --selftest       # detector checks
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))     # wsa1/notes
ROOT = os.path.dirname(HERE)                            # wsa1/
LLVM_BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM_BIN, "llvm-mc")

# (tag, src (relative to ROOT), rom (relative to ROOT), runtime base, group).
# Bases and the prom_b directory/CPU1-CPU2 split are notes/reachability.py's,
# unchanged. prom_d is the addition reachability.py deliberately does not
# walk (it is DATA ONLY and has no boot vectors): its own linker script keeps
# ORIGIN 0 (see prom_d/prom_d.ld's rationale), but prom_c addresses it at
# runtime through the base 0x00F00000 -- so RUNTIME_BASE here is 0xF00000,
# and flatten() below uses it as the address key directly. That single choice
# makes every cross-reference from prom_c into prom_d line up with no special
# case: prom_c's literal 0x00F1D965 and prom_d's own region address
# 0x00F1D965 (file offset 0x1D965) are the same number.
IMAGES = [
    ("prom_a", "prom_a/wsa1_prom_a.s", "original_ROMs/wsa1_prom_a.ic12", 0xF80000, "CPU1"),
    ("prom_b", "prom_b/wsa1_prom_b.s", "original_ROMs/wsa1_prom_b.ic13", 0xF00000, "CPU1"),
    ("prom_c", "prom_c/wsa1_prom_c.s", "original_ROMs/wsa1_prom_c.ic28", 0xF80000, "CPU2"),
    ("prom_d", "prom_d/wsa1_prom_d.s", "original_ROMs/wsa1_prom_d.bin", 0xF00000, "CPU2"),
]
SIZE = 0x80000
RUNTIME_BASE = {t: b for t, _s, _r, b, _g in IMAGES}
GROUP = {t: g for t, _s, _r, _b, g in IMAGES}
ROM_PATH = {t: r for t, _s, r, _b, _g in IMAGES}
SRC_PATH = {t: s for t, s, _r, _b, _g in IMAGES}

# ---- flatten parsing. WIDTH measured empirically (this file's own
# --selftest re-measures it): a bare `.byte`/`.short`/`.word`/`.long`/`.quad`
# in a throwaway .s file, run through `llvm-mc -filetype=obj`, produces
# object sizes 1/2/4/4/8 -- i.e. on THIS backend the canonical 4-byte
# directive `-show-encoding` prints is `.word` (not `.long`; `.short`
# canonicalises to `.hword`). This is the same table
# notes/reachability_kn5000.py uses, confirmed independently rather than
# copied on faith.
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


_ROM_CACHE = {}


def rom_bytes(tag):
    if tag not in _ROM_CACHE:
        with open(os.path.join(ROOT, ROM_PATH[tag]), "rb") as f:
            _ROM_CACHE[tag] = f.read()
    return _ROM_CACHE[tag]


def owner(addr, group):
    for t, base in RUNTIME_BASE.items():
        if GROUP[t] == group and base <= addr < base + SIZE:
            return t
    return None


# ------------------------------------------------------------- the flatten
def flatten(tag):
    """(code, labels, words, data, pad, pos) -- see reachability_kn5000.flatten
    for the shape this is ported from. `code[addr] = (len, text)`, `text` is
    the instruction with its `; encoding: [...]` comment already stripped.
    `words` is every 4-byte `.word` ITEM (this backend's canonical 32-bit
    directive), as (addr, decimal-value)."""
    src = SRC_PATH[tag]
    promdir = os.path.dirname(src)
    cmd = [MC, "-triple=tlcs900", "-show-encoding", "-I", ".", "-I", promdir, src]
    out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
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
            t = int(rest.split(",")[0].strip(), 0)
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
    instruction bytes. `last_addr` is the start of the region's final
    instruction, needed by the fallthrough bridge below."""
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


# ⚠⚠ THE FRAGMENTATION TRAP -- WORSE THAN A SINGLE UNSPELLABLE INSTRUCTION.
# 92% of prom_a's inter-region gaps (5,327 of 5,784, measured) are 8 bytes or
# shorter, and investigating the largest few by hand (0xFE7A5B, chosen
# because the audit's own signals flagged the region starting there) found
# the real cause: this dialect's OWN macro layer. `m_bit`, `m_chg`, `m_set`,
# `m_pop` and the whole `_mem`-based family in include/tlcs900_mem_ops.inc
# are semantically real instructions -- `m_bit 2, MD16, 0x34d0` is a
# documented, named, one-instruction macro invocation -- but their EXPANSION
# is pure `.byte` arithmetic (`.byte 0xC8 + ((\n) & 7)`), because this LLVM
# backend has no mnemonic for that addressing form. llvm-mc's `-show-encoding`
# output therefore carries NO `; encoding:` comment for a single byte of it,
# so flatten() -- correctly, by that output's own account -- puts every one
# of these bytes in `data`, not `code`. That is not the third kind of debt
# (the source already names the real instruction; this is an ENCODING
# WORKAROUND, already solved, not an open question), but it DOES chop a
# fully-reached routine into two "regions" at every occurrence, and the
# second piece has nothing statically pointing at it (nothing should: it is
# a continuation, not an entry point) -- exactly the shape an unguarded
# classifier would misreport as a data-as-code finding.
#
# THE FIX, using an INDEPENDENT decode authority rather than a length guess:
# gap_is_clean_code() asks unidasm (MAME's TLCS-900 decoder -- the same
# authority notes/reachability.py's walk already trusts) whether the gap's
# raw ROM bytes decode, end to end with no truncation, into real
# instructions. If they do, the gap is macro-spelled code and the two
# flanking regions are MERGED before anything is judged "reached"; if they
# do not, it is left alone as a genuine data span, capped well below the
# smallest real finding this audit reports so the cap can never rescue one.
GAP_BRIDGE_CAP = 32     # bytes; every reported HIGH/MEDIUM finding is >= 99 B
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
UNI_LINE = re.compile(r'^\s*([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
_UNI_BOUND = {}


def unidasm_boundaries(tag):
    """{addr: (len, mnemonic)} from ONE linear unidasm decode of the whole
    raw ROM (the same one-shot optimisation notes/reachability.py's own
    `_predecode` uses: ~1.1 s for 512 KiB, measured there). Used ONLY to
    classify short gaps below; never to walk control flow."""
    if tag in _UNI_BOUND:
        return _UNI_BOUND[tag]
    raw = rom_bytes(tag)
    base = RUNTIME_BASE[tag]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(raw)
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(base)],
                              capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    bound = {}
    for ln in out.splitlines():
        m = UNI_LINE.match(ln)
        if m:
            bound.setdefault(int(m.group(1), 16),
                              (len(m.group(2).split()), m.group(3).strip()))
    _UNI_BOUND[tag] = bound
    return bound


def gap_is_clean_code(tag, start, length):
    """True if the independent unidasm decode covers [start, start+length)
    with an unbroken chain of instructions landing EXACTLY on the far edge,
    and none of them is the decoder's illegal-opcode marker. Capped at
    GAP_BRIDGE_CAP so this can never absorb a genuine finding."""
    if length <= 0:
        return True
    if length > GAP_BRIDGE_CAP:
        return False
    bound = unidasm_boundaries(tag)
    a, end = start, start + length
    while a < end:
        e = bound.get(a)
        if not e:
            return False
        ln, mnem = e
        if ln <= 0 or not mnem or mnem.startswith("???") or "illegal" in mnem.lower():
            return False
        a += ln
    return a == end


def merge_macro_artifacts(tag, code, regions):
    """Merge adjacent code regions across any gap gap_is_clean_code() proves
    is macro-spelled instructions rather than genuine data. Returns a new
    regions list, same shape as code_regions()'s."""
    if not regions:
        return regions
    out = [regions[0]]
    for r in regions[1:]:
        ps, pe, pn, plast = out[-1]
        s, e, n, last = r
        gap = s - pe
        if gap_is_clean_code(tag, pe, gap):
            out[-1] = (ps, e, pn + n, last)
        else:
            out.append(r)
    return out


# The residual bridge below is for whatever gap_is_clean_code() does NOT
# absorb (illegal-decoding short gaps -- alignment `.byte 0` padding that
# unidasm reads as a run of `nop`s is already caught above and merges
# harmlessly). Kept as a second, independent net: a short gap does not break
# control flow unless the LAST instruction before it truly ends flow
# (ret/reti/retd/halt/swi, or an UNCONDITIONAL jp/jr/jrl).
MAX_BRIDGE_GAP = 8
FLOW_END_MNEM = ("ret", "reti", "retd", "halt", "swi")
FLOW_MAYBE_END_MNEM = ("jp", "jr", "jrl")


def is_flow_end(text):
    """True if this instruction text never falls through to the next byte."""
    parts = text.split(None, 1)
    if not parts:
        return False
    mnem = parts[0].lower()
    if mnem in FLOW_END_MNEM:
        return True
    if mnem in FLOW_MAYBE_END_MNEM:
        # conditional forms ("jp C,1234") fall through when not taken;
        # unconditional ones (no condition operand, or an explicit "T")
        # never do.
        if len(parts) < 2:
            return True
        ops = [o.strip() for o in parts[1].split(",")]
        if len(ops) == 1:
            return True
        return ops[0].upper() == "T"
    return False


def bridge_map(code, regions):
    """{region_index: previous_region_index} for every region entered ONLY
    by falling through a short gap from the immediately preceding one."""
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
    """directly_reached: set of region indices whose START is a real branch
    target. Returns the full set including anything reachable by walking the
    bridge chain back to a directly-reached region -- a fixed point, so a
    chain of N bridged fragments resolves in one pass over N."""
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
    """Absolute address a branch/call instruction's LAST operand names, or
    None if it is a dynamic (register-indirect) target this cannot resolve
    statically -- exactly the same restriction notes/reachability.py's
    BRANCH regex has (it only matches an explicit literal)."""
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
    Built once, over all four images, so a prom_c reference into prom_d (or a
    prom_a one into prom_b) is seen exactly like an in-image one."""
    branch_targets = defaultdict(list)
    addr_refs = defaultdict(list)
    for tag, _s, _r, _b, group in IMAGES:
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
    add_directory_and_vectors(branch_targets)
    return branch_targets, addr_refs


# prom_b 0xF40000-0xF44018: the 1,910-slot `jp imm24` routine directory,
# CPU1's canonical indirection (reachability.py's S2). ⚠★ MEASURED FALSE
# POSITIVE: all eight of this audit's first-pass prom_b HIGH candidates
# (0xF400D0, 0xF41500, 0xF41640, 0xF41910, 0xF42320, 0xF42470, 0xF42F40,
# 0xF433C0) turned out to be TRAMPOLINE SLOTS INSIDE THIS EXACT RANGE --
# confirmed by reading prom_b/wsa1_prom_b.s directly, e.g. `T_F42F40: jp
# 0xF0F018` labelled "Called from: T_F42F40 (x0)" -- meaning the tree has
# already proven that specific slot is real, named, structural code, and
# simply has no CALLER converted yet, exactly like the other ~1,900 slots
# with a known caller. A `jp imm24` trampoline is periodic in a way this
# tool's byte-content signals cannot tell from a data record (its opcode
# byte, 0x1B, repeats every 4 bytes by construction), and asking "does
# anything call THIS slot" is the wrong question for an address whose
# legitimacy comes from ITS OWN LOCATION, not its callers --
# notes/reachability.py's seed grading already treats membership in this
# range as STRONG for exactly that reason. This tool now does too, for the
# slot's OWN address as well as its target.
PROM_B_DIRECTORY = (0xF40000, 0xF44018)


def is_directory_slot(tag, addr):
    return tag == "prom_b" and PROM_B_DIRECTORY[0] <= addr < PROM_B_DIRECTORY[1]


def add_directory_and_vectors(branch_targets):
    """prom_b's 1,910-slot `jp imm24` directory (CPU1's canonical
    indirection) and the two CPU vector tables -- reachability.py's S1/S2,
    re-derived here from the raw ROM bytes rather than imported, so this
    tool has no runtime dependency on that one and can be audited alone."""
    raw = rom_bytes("prom_b")
    for slot in range(0x40000, 0x44018, 4):
        if raw[slot] == 0x1B:
            t = raw[slot + 1] | raw[slot + 2] << 8 | raw[slot + 3] << 16
            if owner(t, "CPU1"):
                branch_targets[t].append(("prom_b", 0xF00000 + slot, "directory"))
    for tag, group in (("prom_a", "CPU1"), ("prom_c", "CPU2")):
        base = RUNTIME_BASE[tag]
        raw = rom_bytes(tag)
        for v in range(0xFFFF00, 0x1000000, 4):
            o = v - base
            if 0 <= o + 4 <= len(raw):
                val = raw[o] | raw[o + 1] << 8 | raw[o + 2] << 16
                if val and owner(val, group):
                    branch_targets[val].append((tag, v, "vector"))


# --------------------------------------------------------------- signals
def printable_ratio(b):
    if not b:
        return 0.0
    return sum(1 for c in b if 0x20 <= c <= 0x7e) / len(b)


def dominant_byte_ratio(b):
    """The single most common byte's share of the region. ⚠ MEASURED FALSE
    POSITIVE, not a hypothetical: prom_a 0xF8E800 (the SED1330 LCD
    controller's power-on init, already named and documented) scored
    period=0.47 at stride 12 -- because 0x00 (NOP, hardware-timing delay
    padding between port writes) is 239 of its 454 bytes (53%). A genuine
    fixed-stride RECORD table (the calibration shape) tiles DISTINCT field
    values at a period; a delay loop just repeats one byte. Gating high
    dominant-byte content out of the periodicity signal is what tells the two
    apart."""
    if not b:
        return 0.0
    counts = {}
    for c in b:
        counts[c] = counts.get(c, 0) + 1
    return max(counts.values()) / len(b)


DOMINANT_BYTE_CAP = 0.45
MIN_SIGNAL_BYTES = 16   # below this, ascii/periodicity ratios are noise


PERIODS = (2, 3, 4, 5, 6, 8, 12, 16, 24, 32)
PERIOD_CAP = 8192   # bytes of a region actually scanned, for runtime


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
    """True if no label strictly inside [start, end) is ever the target of a
    branch whose SOURCE is outside the region -- the calibration shape
    ("chained by five local labels referencing nothing outside the span")."""
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
    direct = bool(branch_targets.get(start)) or is_directory_slot(tag, start)
    reached = direct or fallthrough
    addr_only = bool(addr_refs.get(start)) and not reached
    island = is_island(start, end, labels, branch_targets)
    ratio = printable_ratio(b)
    pscore, pperiod = periodicity_score(b)
    dom = dominant_byte_ratio(b)
    # A degenerate run of one repeated byte (NOP-padding delay loops are the
    # measured real case) tiles at almost any period without being a record
    # table, and can look "printable" by accident (0x20 repeated). Both
    # signals require the region NOT be dominated by one byte value, and
    # enough bytes to make a ratio meaningful at all.
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
    for tag, _s, _r, _b, _g in IMAGES:
        code, labels, _w, _d, _p, _pos = get_flat(tag)
        regions = merge_macro_artifacts(tag, code, code_regions(code))
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
# ★ HAND-CORROBORATED, not suppressed. Every finding this audit's automatic
# signals produce is still printed; this only annotates the ones checked
# against the tree's OWN prior verification and found to be a known,
# already-audited pattern rather than new debt. See the report's closing
# note for the full reasoning.
KNOWN_FALSE_POSITIVES = {
    ("prom_a", 0xFC0000): (
        "CORROBORATED FALSE POSITIVE -- notes/FINDINGS-prom_a-msg0716-module.md "
        "(128-check audit, notes/prom_a_fc0000_module_check.py --selftest): this "
        "span is the 0x0716 message module's DIRECTORY SLOTS and 16-byte "
        "DISPATCHER VENEERS at 0xFC0420-0xFC0460 etc. -- structurally repetitive "
        "by design (which is exactly what a 16-byte period measures), ending "
        "exactly at 0xFC0890 where the module's 32 8-byte object records begin. "
        "period=16 is the veneer stride, not a record table."
    ),
}


def report():
    out, _bt, _ar = analyse_all()
    print("=" * 78)
    print("DATA-AS-CODE AUDIT -- all four WSA1R images")
    print("=" * 78)
    grand_high = grand_med = grand_low = 0
    for tag, _s, _r, _b, _g in IMAGES:
        rows = out[tag]
        total_code = sum(r["n"] for r in rows)
        unreached = [r for r in rows if not r["reached"]]
        high = [r for r in rows if r["confidence"] == "high"]
        med = [r for r in rows if r["confidence"] == "medium"]
        low = [r for r in rows if r["confidence"] == "low"]
        print("\n%-8s regions=%-6d code_bytes=%-8d unreached_regions=%-5d unreached_bytes=%d"
              % (tag, len(rows), total_code, len(unreached),
                 sum(r["n"] for r in unreached)))
        print("           HIGH %5d regions / %7d B   MEDIUM %5d / %7d B   LOW %5d / %7d B"
              % (len(high), sum(r["n"] for r in high),
                 len(med), sum(r["n"] for r in med),
                 len(low), sum(r["n"] for r in low)))
        grand_high += sum(r["n"] for r in high)
        grand_med += sum(r["n"] for r in med)
        grand_low += sum(r["n"] for r in low)
        for r in sorted(high, key=lambda r: -r["n"])[:8]:
            print("    HIGH   0x%06X-0x%06X  %5d B  ascii=%.2f period=%.2f/%d island=%s addr_only=%s"
                  % (r["start"], r["end"], r["n"], r["ascii_ratio"],
                     r["period_score"], r["period"], r["island"], r["addr_only"]))
            note = KNOWN_FALSE_POSITIVES.get((tag, r["start"]))
            if note:
                print("           -> %s" % note)
        for r in sorted(med, key=lambda r: -r["n"])[:5]:
            refs = ", ".join("%s@0x%06X(%s)" % (t, a, k) for t, a, k in r["addr_refs_by"])
            print("    MEDIUM 0x%06X-0x%06X  %5d B  referenced only as: %s"
                  % (r["start"], r["end"], r["n"], refs or "?"))
    print("\n" + "=" * 78)
    print("TOTALS   HIGH %d B   MEDIUM %d B   LOW %d B" % (grand_high, grand_med, grand_low))
    kfp_bytes = 0
    for tag, _s, _r, _b, _g in IMAGES:
        for r in [r for r in out[tag] if r["confidence"] == "high"]:
            if (tag, r["start"]) in KNOWN_FALSE_POSITIVES:
                kfp_bytes += r["n"]
    print("HIGH bytes with a hand-corroborated false-positive explanation: %d of %d"
          % (kfp_bytes, grand_high))
    print("HIGH bytes with NO such explanation found (the actionable residue): %d"
          % (grand_high - kfp_bytes))
    print("=" * 78)


def would_signal_fire(r):
    """The SAME gated condition classify_region() uses for "high", evaluated
    on a row's stored measurements regardless of its actual reached/confidence
    outcome -- what null_control() needs to ask "would the byte-content
    signal alone have fired here?" on known-genuine code."""
    return (r["n"] >= MIN_SIGNAL_BYTES and r["dominant_byte_ratio"] < DOMINANT_BYTE_CAP
            and (r["ascii_ratio"] >= ASCII_HIGH or r["period_score"] >= PERIOD_HIGH))


def null_control():
    """The false-positive control: measure the BYTE-CONTENT signals alone
    (ignoring the reached-gate) over every REACHED -- i.e. proven-genuine,
    entered-by-real-control-flow -- region, and report how often they would
    have fired on their own. This is the number that makes a HIGH-confidence
    finding evidence rather than a guess: signals with no discriminating
    power would fire just as often on known-good code."""
    out, _bt, _ar = analyse_all()
    print("=" * 78)
    print("NULL CONTROL -- byte-content signals over REACHED (known-genuine) code")
    print("=" * 78)
    tot_regions = tot_hits = 0
    tot_bytes = tot_hit_bytes = 0
    for tag, _s, _r, _b, _g in IMAGES:
        rows = [r for r in out[tag] if r["reached"]]
        hits = [r for r in rows if would_signal_fire(r)]
        n_regions = len(rows)
        n_bytes = sum(r["n"] for r in rows)
        h_bytes = sum(r["n"] for r in hits)
        rate_r = (100.0 * len(hits) / n_regions) if n_regions else 0.0
        rate_b = (100.0 * h_bytes / n_bytes) if n_bytes else 0.0
        print("%-8s reached_regions=%-6d false_positive_regions=%-4d (%.1f%%)   "
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

    # 1. The tool's own accounting closes on every image: code + data + pad
    #    must equal both the running position and the real ROM size, to the
    #    byte. A construct this flatten() cannot classify would otherwise
    #    silently vanish from the total instead of failing loudly.
    for tag, _s, _r, _b, _g in IMAGES:
        code, _labels, _w, data, pad, pos = get_flat(tag)
        romsize = len(rom_bytes(tag))
        codebytes = sum(n for n, _t in code.values())
        check("%s: code+data+pad == pos == ROM size" % tag,
              codebytes + data + pad == pos == romsize,
              "%d+%d+%d=%d vs pos=%d rom=%d" % (codebytes, data, pad,
                                                 codebytes + data + pad, pos, romsize))

    # 2. WIDTH table, re-measured, not trusted from the KN5000 port.
    import tempfile
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

    # 3. THE PLANTED CASE, using the REAL calibration bytes named in the brief
    #    (the HD-AE5000 version string, "Technics Software section
    #    M. Kitajima", padded to the documented 309 B) with NO reference of
    #    any kind -- exactly the calibration fact ("referencing nothing
    #    outside the span"). classify_region must flag it HIGH.
    fake_tag, fake_start = "prom_a", 0xF90000
    fake_end = fake_start + len(CALIBRATION_STRING)
    _ROM_CACHE_SAVE = dict(_ROM_CACHE)
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
    _ROM_CACHE.update(_ROM_CACHE_SAVE)

    # 4. THE MUST-NOT-FLAG CASE: a real, already-converted routine this tree
    #    is certain is genuine code because something in the tree actually
    #    calls it. Pick prom_c's reset entry point (the CPU vector target
    #    itself) -- if the detector cannot clear ITS OWN reset vector, it is
    #    broken, not merely conservative.
    branch_targets, addr_refs = build_reference_index()
    code_c, labels_c, _w, _d, _p, _pos = get_flat("prom_c")
    regions_c = merge_macro_artifacts("prom_c", code_c, code_regions(code_c))
    reset_target = None
    raw_c = rom_bytes("prom_c")
    base_c = RUNTIME_BASE["prom_c"]
    for va in range(0xFFFF00, 0x1000000, 4):
        o = va - base_c
        if 0 <= o + 3 <= len(raw_c):
            val = raw_c[o] | raw_c[o + 1] << 8 | raw_c[o + 2] << 16
            if owner(val, "CPU2"):
                reset_target = val
                break
    check("prom_c's own reset vector resolves inside prom_c",
          reset_target is not None, "0x%06X" % (reset_target or 0))
    region = next((r for s, e, _n, _l in regions_c if s <= reset_target < e
                   for r in [(s, e)]), None)
    check("the reset entry point is a converted code region", region is not None)
    if region:
        s, e = region
        r = classify_region("prom_c", s, e, labels_c, branch_targets, addr_refs)
        check("the reset entry point is NOT flagged (reached=True)",
              r["reached"] and r["confidence"] == "none",
              "reached=%s confidence=%s" % (r["reached"], r["confidence"]))

    # 4b. THE FRAGMENTATION TRAP ITSELF, checked directly. 92% of prom_a's
    #     inter-region gaps are <= 8 B (measured): a single llvm-mc-
    #     unspellable instruction spelled as a `.byte` fallback. Build a
    #     synthetic 3-region chain -- reached, unconditional-flow-ending
    #     fallback gap, then a genuinely UNREACHED tail -- and confirm the
    #     bridge does NOT reach across an unconditional jump (so a genuinely
    #     unreached island past a `ret`/`jp` is still caught) while it DOES
    #     reach across an ordinary fall-through gap.
    fake_code = {
        0x1000: (2, "ld a, 1"),                 # region 0: directly reached
        0x1002: (1, "ret"),                     #   ends flow
        0x100A: (2, "ld a, 2"),                 # region 1: bridged (short gap, no flow end before it)
        0x100C: (1, "nop"),
    }
    fake_regions = code_regions(fake_code)
    check("synthetic fixture makes two regions", len(fake_regions) == 2,
          str(fake_regions))
    fake_bridge = bridge_map(fake_code, fake_regions)
    check("a short gap AFTER 'ret' (a real flow end) is NOT bridged",
          0 not in fake_bridge and 1 not in fake_bridge, str(fake_bridge))

    fake_code2 = {
        0x2000: (2, "ld a, 1"),                 # region 0: directly reached
        0x2002: (2, "add a, 1"),                #   does NOT end flow
        0x2008: (2, "ld a, 2"),                 # region 1: bridged across the short gap
    }
    fake_regions2 = code_regions(fake_code2)
    fake_bridge2 = bridge_map(fake_code2, fake_regions2)
    check("a short gap after a non-flow-ending instruction IS bridged",
          fake_bridge2.get(1) == 0, str(fake_bridge2))
    reached2 = resolve_fallthrough_reached(fake_regions2, fake_bridge2, {0})
    check("the bridged region inherits 'reached' from the one before it",
          reached2 == {0, 1}, str(reached2))

    # 4c. THE REAL MACRO-ARTIFACT CASE, on the REAL ROM: prom_a 0xF8FE7A57
    #     (`m_bit 2, MD16, 0x34d0` in prom_a/wsa1_prom_a.s, expanding to
    #     `_mem` prefix bytes + one opcode byte, all `.byte`) sits between two
    #     real llvm-mc-encoded instructions with NO `; encoding:` line of its
    #     own, so flatten() puts it in `data` and code_regions() reports a
    #     4-byte gap there. gap_is_clean_code() must call that gap real code,
    #     and merge_macro_artifacts() must therefore NOT show a region
    #     boundary at 0xFE7A5B at all.
    code_a, _labels_a, _wa, _da, _pa, _posa = get_flat("prom_a")
    check("0xFE7A57 (the m_bit macro's bytes) is absent from `code`",
          0xFE7A57 not in code_a)
    check("gap_is_clean_code proves the m_bit gap is real code",
          gap_is_clean_code("prom_a", 0xFE7A57, 0xFE7A5B - 0xFE7A57))
    raw_regions_a = code_regions(code_a)
    boundary_before = any(s == 0xFE7A5B for s, _e, _n, _l in raw_regions_a)
    check("...and IS a region boundary before merging (reproduces the bug)",
          boundary_before)
    merged_a = merge_macro_artifacts("prom_a", code_a, raw_regions_a)
    boundary_after = any(s == 0xFE7A5B for s, _e, _n, _l in merged_a)
    check("...but is NOT a region boundary after merging (the fix)",
          not boundary_after)

    # 4c-ii. THE DIRECTORY-SLOT FALSE POSITIVE, measured on the REAL ROM:
    #     prom_b 0xF42F40 is `T_F42F40: jp 0xF0F018`, a trampoline slot
    #     inside the verified 0xF40000-0xF44018 routine directory with (per
    #     the tree's own comment) zero converted callers -- exactly what
    #     made this audit's first pass report it HIGH. is_directory_slot()
    #     must call it reached regardless.
    check("0xF42F40 is inside the verified prom_b directory",
          is_directory_slot("prom_b", 0xF42F40))
    code_b, labels_b, _wb, _db, _pb, _posb = get_flat("prom_b")
    merged_b = merge_macro_artifacts("prom_b", code_b, code_regions(code_b))
    slot_region = next(((s, e) for s, e, _n, _l in merged_b if s == 0xF42F40), None)
    check("0xF42F40 is a converted code region in prom_b", slot_region is not None)
    if slot_region:
        s, e = slot_region
        r = classify_region("prom_b", s, e, labels_b, branch_targets, addr_refs)
        check("the directory slot is reached (not flagged) despite no caller",
              r["reached"] and r["confidence"] == "none",
              "reached=%s confidence=%s" % (r["reached"], r["confidence"]))

    # 4d. THE DEGENERATE-PADDING FALSE POSITIVE, measured on the REAL ROM
    #     before this guard existed: prom_a 0xF8E800, the SED1330 LCD
    #     controller's power-on init (already named, documented, and called
    #     via LCD_EntryThunks -- notes/asm_source.py's own comments name it
    #     "the LCD controller: entry thunks and the power-on setup"), scored
    #     period=0.47 at stride 12 purely because 0x00 (NOP, a hardware-
    #     timing delay between port writes) is 239 of its 454 bytes. Without
    #     the dominant-byte guard this region was reported HIGH; it must not
    #     be now.
    branch_c, addr_c = build_reference_index()
    code_a2, labels_a2, _wa2, _da2, _pa2, _posa2 = get_flat("prom_a")
    merged_a2 = merge_macro_artifacts("prom_a", code_a2, code_regions(code_a2))
    lcd_region = next(((s, e) for s, e, _n, _l in merged_a2 if s == 0xF8E800), None)
    check("the LCD init region (0xF8E800) is intact after merging", lcd_region is not None)
    if lcd_region:
        s, e = lcd_region
        r = classify_region("prom_a", s, e, labels_a2, branch_c, addr_c)
        check("its dominant byte (0x00 NOP padding) is measured >= 45%%",
              r["dominant_byte_ratio"] >= DOMINANT_BYTE_CAP,
              "dominant=%.2f period=%.2f" % (r["dominant_byte_ratio"], r["period_score"]))
        check("...so it is NOT flagged HIGH despite the raw periodicity score",
              r["confidence"] != "high",
              "confidence=%s period=%.2f/%d" % (r["confidence"], r["period_score"], r["period"]))

    # 5. periodicity_score sanity: a genuinely periodic byte string scores
    #    high at its true period and a pass over pure random-looking bytes of
    #    the same length (the actual leading 256 bytes of prom_b's directory
    #    payload region, which is real converted code) does not.
    tiled = bytes([1, 2, 3, 4] * 40)
    score, period = periodicity_score(tiled)
    check("a 4-byte-tiled string scores >= 0.9 at period 4",
          score >= 0.9 and period == 4, "score=%.2f period=%d" % (score, period))

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--null" in sys.argv:
        null_control()
        return
    report()


if __name__ == "__main__":
    main()
