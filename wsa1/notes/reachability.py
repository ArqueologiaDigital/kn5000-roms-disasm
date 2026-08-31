#!/usr/bin/env python3
"""Which bytes of the four WSA1R images are REACHABLE CODE, and which of those
are still `.incbin`?

QUESTION IT ANSWERS
    "If you follow every control-flow edge the machine can actually take --
     including the indirect ones through call tables, jump tables and the
     routine directory -- which bytes does execution reach, and how many of them
     has this tree not converted yet?"

    That number is the remaining work for a coverage goal. It is NOT the same as
    "bytes still .incbin": a span can be pure data, in which case converting it
    adds territory and no reachable code at all. Round 7 converted 9,175 bytes
    that had ZERO call/jp references at any byte offset in any image.

WHY A TOOL AND NOT A LANE
    Recursive descent over 2 MiB is exactly the kind of work a script does better
    than an agent, and cheaper. The agents' job is what a script cannot do: decide
    what a routine MEANS. This file deliberately does none of that.

⚠ IT NEVER WRITES A .s FILE. It reports. Emission stays with the per-span
    emitters, which splice into `.incbin` ranges only and so cannot disturb an
    existing comment or label.

DECODE AUTHORITY
    unidasm (MAME), the same authority the rest of this tree uses for instruction
    boundaries. It is called on WINDOWS, not per address: a linear run from one
    seed usually costs a single subprocess, where the older decode_at() pattern
    cost one per instruction. Results are cached per window.

RUN
    python3 notes/reachability.py                 # the coverage report
    python3 notes/reachability.py --targets       # ★ the WORK LIST, ranked by reachable
                                                  #   bytes with a cumulative column
    python3 notes/reachability.py --evidence      # ★ per-run START evidence: convert the
                                                  #   runs with it, refuse the ones without
    python3 notes/reachability.py --spans         # per-.incbin-span breakdown
    python3 notes/reachability.py --seeds         # where the walk starts, by class
    python3 notes/reachability.py --selftest      # checks, incl. the LAST element
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
ARCH = "tlcs900"

# (tag, .s file, rom file, load base). prom_d is DATA ONLY and has no load base
# established, so it is not walked -- stated, not silently skipped.
IMAGES = [
    ("prom_a", "prom_a/wsa1_prom_a.s", "wsa1_prom_a.ic12", 0xF80000),
    ("prom_b", "prom_b/wsa1_prom_b.s", "wsa1_prom_b.ic13", 0xF00000),
    ("prom_c", "prom_c/wsa1_prom_c.s", "wsa1_prom_c.ic28", 0xF80000),
]
SIZE = 0x80000

# CPU 1 fetches prom_a + prom_b; CPU 2 fetches prom_c. An address is only
# resolvable inside the images its own CPU can see.
CPU1 = ("prom_a", "prom_b")
CPU2 = ("prom_c",)

# ★★ SEED STRENGTH, and it is the difference between code and painted data.
# A DIRECTORY slot is `jp imm24`: its target is an entry point, full stop. A
# BRANCH in decoded code is an edge the CPU takes. A VECTOR is entered by
# hardware. Those are STRONG.
# An IMMEDIATE that lands in an image, or an entry of a framed `.long` table, is
# a POINTER -- and a pointer is as likely to name a TABLE as a routine. Those are
# WEAK, and walking from them paints data as code:
#   * prom_a: a splice built on weak seeds framed 701 bytes of handler pointer
#     tables and parameter descriptors as instructions. THE BYTE GATE PASSED. It
#     took three independent witnesses to catch it.
#   * prom_b: of 10,314 bytes converted on the combined figure, 8,819 were caption
#     blocks and coordinate arrays that a `.long` happened to name. A seed landing
#     in text paints everything up to the first 0x0E byte.
# So the tool now reports BOTH numbers and the strong one is the one to convert on.
STRONG = ("vector", "directory", "branch")
WEAK = ("immediate", "pointer_table")

# ⚠ AND GRADING THE SEEDS IS STILL NOT SUFFICIENT ON ITS OWN. walk() queues every
# branch target it decodes, so a walk that decodes its way INTO data queues
# whatever that data happens to look like. Round 2 found the case: prom_a
# 0xFA369A is named by NO seed of any grade, the strong walk marked 17 bytes
# there, and the bytes are the ASCII string "SOUND GROUP NAMING". Framing them
# would have emitted `ld XIX,0x4f524720` and the byte gate would have PASSED --
# the second time in two rounds that the gate would have accepted a wrong decode.
# The lane refused, against its brief, and was right.
#
# ★ THE TEST THAT SETTLES IT, from that lane, and it is decidable rather than a
# judgement: a run start has POSITIVE EVIDENCE if a graded seed names it, or if
# already-converted code FALLS THROUGH into it -- prom_a 0xF961BD is named by no
# seed and IS code, because the converted instruction at 0xF961B8 is five bytes
# and ends exactly there. A target queued out of a decode of data has neither.
# --evidence applies that test to every reachable run and prints which side each
# falls on, so a converting lane never has to guess.

LINE = re.compile(r'^\s*([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
FLOW_END = re.compile(r'^\s*(ret|reti|retd|jp\s|jr\s+0x|halt|swi)', re.I)
BRANCH = re.compile(r'\b(?:jr|jp|call|calr)\b[^;]*?0x([0-9a-f]{6})', re.I)


def rom(img):
    return open(os.path.join(ROOT, "original_ROMs", img), "rb").read()


# ⚠⚠ A FOURTH LINE SHAPE, and it is not in any prom_*.s file.
# prom_a and prom_c no longer write their shared multitasking kernel out: both
# `.include "kernel/kernel.s"`, ONE source assembled into both CPUs.  Its lines
# carry BOTH images' addresses --
#     m_ld_rm MWD+r4, 0x00, r0    ; F85788/F982ED  9c 00 20   ld WA,(XIX+0x00)
# -- so SRC_LINE, which expects ONE address followed by whitespace, matches none
# of them.  Reading only prom_a/prom_c would drop 941 PROVEN instruction
# addresses per image and quietly change every figure downstream.  The shared
# file is appended to each image's lines with its own address column selected.
# ⚠⚠ AND THERE IS NOW MORE THAN ONE OF THEM PER IMAGE.  Since the maincpu join,
# the three routines prom_a and prom_b carry TWICE are one source each, included
# at both sites, and those sources carry both images' addresses in exactly the
# same `; AAAAAA/BBBBBB` shape as the kernel.  This was a (rel, col) PAIR per
# image; it is a LIST per image, because prom_a now has three and prom_b two.
# ★ A shared source is reached through the image's own `.include` too, so
#   source_lines() must skip it there or its lines arrive twice, once unusable.
SHARED_SOURCES = {
    "prom_a": [("kernel/kernel.s", 1),
               ("maincpu/shared/indexed_table.s", 1),
               ("maincpu/shared/lcd_screen_redraw.s", 1)],
    "prom_b": [("maincpu/shared/indexed_table.s", 2),
               ("maincpu/shared/lcd_screen_redraw.s", 2)],
    "prom_c": [("kernel/kernel.s", 2)],
}
SHARED_ADDR = re.compile(r';\s*([0-9A-F]{6})/([0-9A-F]{6})\b')

# ⚠⚠ A FIFTH PLACE THE LINES CAN BE, and it is the same trap one turn further
# out.  prom_c is no longer one file either: since the per-subject split it is a
# master listing that `.include`s 26 subject sources in address order
# (notes/prom_c_split.py).  Reading only the master would drop 125,264 of its
# 127,731 lines and this tool would report the whole image as unconverted --
# LOUDLY, but for the wrong reason.  So the image's OWN `.include`s are followed
# too.  This is deliberately a SCAN of the master rather than a hand-kept list:
# a list is what goes stale when the next lane adds a file.
OWN_INCLUDE = re.compile(r'^\t\.include "([^"]+\.s)"')


def included_sources(path):
    """Every .s file the image at `path` pulls in, in the order it names them,
    resolved the way llvm-mc resolves them: `-I .` then `-I <the image's dir>`."""
    out = []
    for ln in open(os.path.join(ROOT, path)).read().split("\n"):
        m = OWN_INCLUDE.match(ln)
        if not m:
            continue
        rel = m.group(1)
        for cand in (rel, os.path.join(os.path.dirname(path), rel)):
            if os.path.exists(os.path.join(ROOT, cand)):
                out.append(cand)
                break
        else:
            raise FileNotFoundError(rel)
    return out


ROMS = {tag: rom(f) for tag, _s, f, _b in IMAGES}
BASES = {tag: b for tag, _s, _f, b in IMAGES}


def owner(addr, cpu):
    """Which image of this CPU holds `addr`, if any."""
    for tag in cpu:
        b = BASES[tag]
        if b <= addr < b + SIZE:
            return tag
    return None


# ------------------------------------------------------------- result cache
# ⚠ THE WALK IS EXPENSIVE (minutes), AND LANES RE-RUN IT. Without this, two lanes
# asking the same question spawn two full walks, and ten concurrent processes on
# an eight-core box make every one of them slower. The result is therefore cached
# against a fingerprint of its INPUTS -- the four .s files and this file -- so a
# repeat question on unchanged inputs is instant and a changed .s invalidates it
# automatically. That is the whole point of putting this work in a script.
import hashlib
import json as _json

RESULT_CACHE = os.path.join(ROOT, "notes", ".reachability-cache.json")


def _fingerprint(tag=None):
    """PER IMAGE. ⚠ The first version hashed all three .s files together, so a run
    that computed prom_a, then had another lane splice prom_b, then stored, left a
    STALE prom_a under a fingerprint that still validated. analyse() stores as it
    goes, so that window is real and a lane hit it. Each image is now keyed on its
    OWN source plus this tool, and an image whose key does not match is re-walked."""
    h = hashlib.sha1()
    for t_, s, _f, _b in IMAGES:
        if tag is None or t_ == tag:
            h.update(open(os.path.join(ROOT, s), "rb").read())
            # ⚠ AND WHAT THAT IMAGE INCLUDES.  prom_a and prom_c both pull in
            # kernel/kernel.s, and prom_c pulls in its 26 subject sources;
            # hashing only the master would let an edit to any of them validate a
            # stale entry -- the same failure the docstring above describes, one
            # indirection further out.
            rels = [r for r, _c in SHARED_SOURCES.get(t_, [])]
            for rel in dict.fromkeys(rels + included_sources(s)):
                h.update(open(os.path.join(ROOT, rel), "rb").read())
    h.update(open(os.path.abspath(__file__), "rb").read())
    return h.hexdigest()


def _cache_load():
    try:
        return _json.load(open(RESULT_CACHE))
    except Exception:
        return {}


def _cache_store(all_c):
    try:
        _json.dump(all_c, open(RESULT_CACHE, "w"))
    except Exception:
        pass


# ⚠ --evidence needs the per-byte reached set, which the cache does not persist
# (it stores per-span counts, which is all the other modes need). It used to get
# a re-walk by os.unlink()ing the result cache -- EVERY LANE'S result cache, to
# obtain an effect inside one process. This flag does the same thing to this
# process only.
FORCE_WALK = False


def _cache_get(tag):
    if FORCE_WALK:
        return None
    e = _cache_load().get(tag)
    return e if e and e.get("fingerprint") == _fingerprint(tag) else None


# ----------------------------------------------------------------- decoding
_WIN = {}
# addr -> (length, text) for every instruction any decoded window has revealed.
# ★ THE OPTIMISATION THAT MATTERS: a window decoded from seed A also settles the
# boundaries of every instruction in A's linear run, so a later walk starting at
# any of those addresses is a CACHE HIT and costs no subprocess. Without this the
# tool spawns one unidasm per seed -- thousands -- and takes tens of minutes.
_BOUND = defaultdict(dict)
WINDOW = 0x800

# ★★ AND THE WINDOW HAS AN END, WHICH THE DECODER CANNOT SEE PAST.
# An instruction that straddles the end of the 2 KiB buffer is decoded from
# TRUNCATED bytes: unidasm emits whatever shorter instruction fits, and the
# boundary index stores it, last write wins. That hands walk() the wrong LENGTH
# (it resumes at the wrong offset) and the wrong BRANCH TARGET (it queues an edge
# no control flow takes) -- the tool's own "paints data as code" failure arriving
# through the decoder instead of through a seed:
#
#     0xFA9794  truth 'jr NC,0xfa980e'  (3 bytes)
#               got   'jr NC,0xfa9796'  (2 bytes)   => FALSE EDGE to 0xFA9796
#
# MAXLEN is the longest TLCS-900 instruction MEASURED in these images -- one
# linear decode of prom_a is 274,588 instructions and none exceeds 7 bytes -- so
# a row starting more than MAXLEN-1 bytes before the end had all of its bytes in
# the buffer and is trustworthy, and every row after that point is dropped. It
# costs 6 addresses of every 2,048 (0.3%), which the next window re-asserts from
# whole bytes anyway.
# ⚠ A row is only truncated if the buffer ended EARLY. When the window runs off
# the end of the IMAGE there is nothing past it to truncate, so the guard is not
# applied there -- that is the `o + WINDOW < len(d)` test.
# Measured in notes/perf/decode_conflicts.py (52/17/15 tail conflicts across the
# three images at guard 0, all of them 0 at guard 6) and accounted for byte by
# byte in notes/perf/GUARD-ACCOUNTING-2026-08-31.txt.
MAXLEN = 7


def _decode_window(tag, start):
    """[(addr, length, text)] for the linear run beginning at `start`."""
    key = (tag, start)
    if key in _WIN:
        return _WIN[key]
    # already settled by an earlier window? then serve it from the boundary index.
    bi = _BOUND[tag]
    if start in bi:
        rows, a = [], start
        while a in bi and len(rows) < 512:
            ln, text = bi[a]
            rows.append((a, ln, text))
            a += ln
        if rows:
            return rows
    b, d = BASES[tag], ROMS[tag]
    o = start - b
    if o < 0 or o >= len(d):
        _WIN[key] = []
        return []
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d[o:o + WINDOW])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", ARCH, "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for ln in out.splitlines():
        m = LINE.match(ln)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    if o + WINDOW < len(d):
        end = start + WINDOW
        rows = [r for r in rows if r[0] + MAXLEN <= end]
    _WIN[key] = rows
    for a, ln, text in rows:
        bi[a] = (ln, text)
    return rows


# ------------------------------------------------- THE DECODE, PERSISTED
# ★★ THE ROM BYTES NEVER CHANGE. The byte gate freezes them, so what unidasm
# says an address decodes to is INVARIANT to the `.s` edit that (correctly)
# invalidates the result cache above: a lane converts a span, the result cache
# misses, and the tool re-derives -- from 84,190 subprocesses and 14 minutes --
# a decode that could not possibly have changed. 83% of a cold run is that
# subprocess. So the boundary index is persisted too, on its OWN key: the ROM,
# the decoder binary, and the two parameters that decide what a window asserts.
#
# ⚠ THIS IS ONLY SOUND BECAUSE OF THE GUARD ABOVE. While truncated tail rows
# were stored, what `_BOUND` held at an address depended on which window reached
# it first, so an index built by one walk order was not the index another would
# build, and persisting it would have changed answers. With the guard every
# stored row was decoded from whole bytes, so the entry at an address IS
# decode(address) -- measured, notes/perf/decode_conflicts.py -- and it can be
# stored, reloaded and shared.
#
# ⚠ LOADED LAZILY, on a result-cache MISS only. A warm run answers out of the
# result cache in 0.2 s and must not pay a 30 MB read to do it.
DECODE_CACHE = os.path.join(ROOT, "notes", ".reachability-decode.txt")
_DECODE_KEY = {}
_DECODE_LOADED = set()


def _decode_key(tag):
    """What the stored rows are a function of, and nothing else: the ROM, the
    decoder binary and how it is invoked, the window parameters, and the regex
    that turns its stdout into rows. ⚠ A key that misses one of those serves a
    STALE decode, which is the one failure mode this file must not have."""
    if tag not in _DECODE_KEY:
        if "unidasm" not in _DECODE_KEY:
            _DECODE_KEY["unidasm"] = hashlib.sha1(open(UNIDASM, "rb").read()).hexdigest()
        _DECODE_KEY[tag] = "%s %s %s %d %d %s" % (
            hashlib.sha1(ROMS[tag]).hexdigest(), _DECODE_KEY["unidasm"], ARCH,
            WINDOW, MAXLEN, hashlib.sha1(LINE.pattern.encode()).hexdigest()[:12])
    return _DECODE_KEY[tag]


def _decode_sections():
    """[(tag, key, [lines])] as the file holds them, so another image's section
    survives a store of ours."""
    out = []
    try:
        fh = open(DECODE_CACHE)
    except OSError:
        return out
    with fh:
        for ln in fh:
            if ln.startswith("#"):
                _, t_, key = ln.rstrip("\n").split(" ", 2)
                out.append((t_, key, []))
            elif out:
                out[-1][2].append(ln)
    return out


def _decode_load(tag):
    """Pour the persisted index into `_BOUND`, if it is for these exact bytes."""
    if tag in _DECODE_LOADED:
        return 0
    _DECODE_LOADED.add(tag)
    bi = _BOUND[tag]
    n = 0
    for t_, key, lines in _decode_sections():
        if t_ != tag or key != _decode_key(tag):
            continue
        for ln in lines:
            a, l, text = ln.rstrip("\n").split(" ", 2)
            bi.setdefault(int(a, 16), (int(l), text))
            n += 1
    if not n:
        n = _predecode(tag)
    return n


def _predecode(tag):
    """★ ONE LINEAR DECODE OF THE WHOLE IMAGE instead of tens of thousands of
    2 KiB windows. unidasm decodes all 512 KiB in ~1.1 s; the walk was paying
    847 s to settle the same boundaries 2,048 bytes at a time -- it decodes
    110 MB to settle 219,086 boundaries in prom_a, ~265x redundant.

    ⚠ It settles only the addresses ON that stream. A walk that starts between
    two of them still spawns, and that spawn's rows are canonical too, because
    with the guard an entry is decode(address) whatever window produced it.
    ⚠ No tail guard here: the buffer IS the image, so nothing is truncated by a
    window end -- only by the end of the ROM, exactly as today's last window is."""
    b, d = BASES[tag], ROMS[tag]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d)
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", ARCH, "-basepc", hex(b)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    bi = _BOUND[tag]
    n = 0
    for ln in out.splitlines():
        m = LINE.match(ln)
        if m:
            bi.setdefault(int(m.group(1), 16),
                          (len(m.group(2).split()), m.group(3).strip()))
            n += 1
    return n


def _decode_store(tag):
    """Merge this run's index into the file, atomically. ⚠ Another lane may be
    writing the same file; os.replace makes the loser's rows simply absent,
    which costs a spawn and cannot corrupt an answer."""
    keep = [(t_, key, lines) for t_, key, lines in _decode_sections() if t_ != tag]
    rows = _BOUND[tag]
    tmp = DECODE_CACHE + ".%d" % os.getpid()
    try:
        with open(tmp, "w") as f:
            for t_, key, lines in keep:
                f.write("# %s %s\n" % (t_, key))
                f.writelines(lines)
            f.write("# %s %s\n" % (tag, _decode_key(tag)))
            for a in sorted(rows):
                ln, text = rows[a]
                f.write("%x %d %s\n" % (a, ln, text))
        os.replace(tmp, DECODE_CACHE)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def walk(tag, start, seen, cpu, queue):
    """Linear decode from `start` until a flow end, marking bytes and queueing
    every branch/call target. Returns the number of NEW bytes marked."""
    b, d = BASES[tag], ROMS[tag]
    new = 0
    pc = start
    guard = 0
    while guard < 4000:
        guard += 1
        if not (b <= pc < b + len(d)) or pc in seen:
            return new
        rows = _decode_window(tag, pc)
        if not rows:
            return new
        for addr, ln, text in rows:
            if addr in seen:
                return new
            if not (b <= addr < b + len(d)):
                return new
            for i in range(ln):
                if addr + i not in seen:
                    seen.add(addr + i)
                    new += 1
            for m in BRANCH.finditer(text):
                t = int(m.group(1), 16)
                if owner(t, cpu):
                    queue.append(t)
            if FLOW_END.match(text):
                return new
            pc = addr + ln
        # window exhausted without a flow end: continue from where it stopped
    return new


# ------------------------------------------------------------------- seeds
# ⚠ THE IMAGES DO NOT SHARE A LINE SHAPE, and assuming they did emptied three of
# the five seed classes for prom_b. prom_a writes `<text> ; ADDR hh hh hh`;
# prom_b writes `<llvm-mc text> ; ADDR <mame text>`, where the llvm operand is in
# DECIMAL and useless for a seed scan -- the MAME text after the address is the
# one to read. This regex takes the address and EVERYTHING after it, and callers
# scan that tail. Measured: the old pattern matched 8,473 of prom_b's 78,022
# addressed lines; this one matches all of them.
SRC_LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$')
# ★★ AN ADDRESSED LINE IS NOT NECESSARILY AN INSTRUCTION. A converted data table
# carries an address comment exactly like a converted instruction does, and
# 20,464 of prom_b's 78,022 addressed lines are .byte/.ascii/.long/.short rows.
# Feeding those into the walk as `proven` SEEDS THE STRONG PASS ON DATA -- which
# is why prom_b reported 913 STRONG-reachable bytes that a lane then correctly
# refused to convert. Grading the seed CLASSES (commit 47d4094) did not fix this,
# because the bad seeds were arriving through `proven`, not through a class.
DATA_DIRECTIVE = re.compile(r'^\.(byte|ascii|asciz|short|word|long|quad|fill|space|zero|incbin|align|org)\b')
LONG_DIR = re.compile(r'^\t\.long\s+0x([0-9A-Fa-f]{8})')
INCBIN = re.compile(r'^\t\.incbin "original_ROMs/(\S+?)", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)\s*$')




def source_lines(tag):
    path = dict((t, s) for t, s, _f, _b in IMAGES)[tag]
    lines = open(os.path.join(ROOT, path)).read().split("\n")
    shared = dict(SHARED_SOURCES.get(tag, []))
    for rel in included_sources(path):
        if rel in shared:
            continue          # appended below, with its address column selected
        lines += open(os.path.join(ROOT, rel)).read().split("\n")
    for rel, col in SHARED_SOURCES.get(tag, []):
        for ln in open(os.path.join(ROOT, rel)).read().split("\n"):
            m = SHARED_ADDR.search(ln)
            if m:
                ln = ln[:m.start()] + "; " + m.group(col) + " " + ln[m.end():]
            lines.append(ln)
    return lines


def proven_and_incbin(tag):
    """(instruction addresses already in the .s, [(lo,hi) still .incbin])."""
    b = BASES[tag]
    proven, spans = set(), []
    for ln in source_lines(tag):
        m = SRC_LINE.match(ln)
        if m:
            if not DATA_DIRECTIVE.match(m.group(1)):
                proven.add(int(m.group(2), 16))
            continue
        m = INCBIN.match(ln)
        if m:
            off, n = int(m.group(2), 16), int(m.group(3), 16)
            spans.append((b + off, b + off + n))
    return proven, spans


def seeds(tag, cpu):
    """Every address execution can ENTER at, by class. This is where indirection
    is handled: a jump table's entries and a directory slot's target are entry
    points that no linear or branch-following walk would ever reach."""
    b, d = BASES[tag], ROMS[tag]
    out = defaultdict(set)

    # S1 -- the CPU's vector table. A TMP95C061 fetches its reset PC at 0xFFFF00
    # and its vectors below it; both boot images are based so that lands in them.
    for v in range(0xFFFF00, 0x1000000, 4):
        t = owner_word(d, b, v)
        if t is not None and owner(t, cpu):
            out["vector"].add(t)

    # S2 -- the ROUTINE DIRECTORY (prom_b 0x40000..0x44018): each slot is
    # `jp imm24`, opcode 0x1B. THE canonical indirection in this machine.
    if "prom_b" in cpu:
        db = ROMS["prom_b"]
        for slot in range(0x40000, 0x44018, 4):
            if db[slot] == 0x1B:
                t = db[slot + 1] | db[slot + 2] << 8 | db[slot + 3] << 16
                if owner(t, cpu):
                    out["directory"].add(t)

    # S3/S4 -- what ALREADY-CONVERTED code names: branch targets, and 32-bit
    # immediates that land in an image (a jump-table base, a callback pointer).
    for ln in source_lines(tag):
        m = SRC_LINE.match(ln)
        if not m:
            continue
        if DATA_DIRECTIVE.match(m.group(1)):
            continue          # a .long row's "operand" is a datum, not an edge
        text = m.group(1) + " " + m.group(3)
        for mm in BRANCH.finditer(text):
            t = int(mm.group(1), 16)
            if owner(t, cpu):
                out["branch"].add(t)
        for mm in re.finditer(r'0x00([0-9A-Fa-f]{6})', text):
            t = int(mm.group(1), 16)
            if owner(t, cpu):
                out["immediate"].add(t)

    # S5 -- POINTER TABLES the tree has already framed as `.long`. These are the
    # jump tables and dispatch tables; their entries are entry points.
    for ln in source_lines(tag):
        m = LONG_DIR.match(ln)
        if m:
            t = int(m.group(1), 16)
            if owner(t, cpu):
                out["pointer_table"].add(t)
    return out


def owner_word(d, base, addr):
    o = addr - base
    if o < 0 or o + 4 > len(d):
        return None
    v = d[o] | d[o + 1] << 8 | d[o + 2] << 16
    return v if v else None


# ------------------------------------------------------------------ report
_MEM = {}


def _walk_from(tag, cpu, sd, classes, proven=()):
    seen, queue, done = set(), [], set()
    for cls in classes:
        queue.extend(sorted(sd.get(cls, ())))
    queue.extend(sorted(proven))
    while queue:
        a = queue.pop()
        if a in done:
            continue
        done.add(a)
        walk(tag, a, seen, cpu, queue)
    return seen


def analyse(tag, cpu):
    """Cached: see the fingerprint note above. `seen` is returned as a set for the
    caller, but persisted as per-span counts, which is all any caller needs."""
    if tag in _MEM:
        return _MEM[tag]
    c = _cache_get(tag)
    if c:
        r = {"seeds": c["seeds"], "reached": c["reached"], "incbin": c["incbin"],
             "reach_in_incbin": c["reach_in_incbin"],
             "spans": [tuple(s) for s in c["spans"]],
             # ⚠ ints, not strings. The first version rehydrated these as
             # tuple(k.split(",")) -- a tuple of STRINGS -- which matched no
             # (lo, hi) lookup, so --targets printed an empty list and OVERWROTE
             # the tracked work list with []. Caught by a verifier, not by me.
             "per_span": {(int(k.split(",")[0]), int(k.split(",")[1])): v
                          for k, v in c["per_span"].items()},
             "per_span_strong": {(int(k.split(",")[0]), int(k.split(",")[1])): v
                                 for k, v in c.get("per_span_strong", {}).items()},
             "reach_strong": c.get("reach_strong", 0),
             "seen": None}
        _MEM[tag] = r
        return r
    proven, spans = proven_and_incbin(tag)
    sd = seeds(tag, cpu)
    # ★ past the result cache, so this run is going to walk: NOW the decode is
    # worth loading, and only now.
    _decode_load(tag)
    # STRONG first -- these are the bytes worth converting.
    strong = _walk_from(tag, cpu, sd, STRONG, proven)
    # then everything, so the difference is attributable to the weak classes.
    seen = _walk_from(tag, cpu, sd, list(sd), proven)
    incbin_bytes = sum(hi - lo for lo, hi in spans)
    per_span, per_span_strong = {}, {}
    for lo, hi in spans:
        per_span[(lo, hi)] = sum(1 for x in range(lo, hi) if x in seen)
        per_span_strong[(lo, hi)] = sum(1 for x in range(lo, hi) if x in strong)
    reach_in_incbin = sum(per_span.values())
    reach_strong = sum(per_span_strong.values())
    r = {
        "seeds": {k: len(v) for k, v in sd.items()},
        "reached": len(seen),
        "incbin": incbin_bytes,
        "reach_in_incbin": reach_in_incbin,
        "spans": spans,
        "per_span": per_span,
        "per_span_strong": per_span_strong,
        "reach_strong": reach_strong,
        "seen": seen,
    }
    _MEM[tag] = r
    _decode_store(tag)
    all_c = _cache_load()
    all_c[tag] = {"fingerprint": _fingerprint(tag),
                  "seeds": r["seeds"], "reached": r["reached"], "incbin": r["incbin"],
                  "reach_in_incbin": r["reach_in_incbin"],
                  "spans": [list(s) for s in spans],
                  "reach_strong": r["reach_strong"],
                  "per_span": {"%d,%d" % k: v for k, v in per_span.items()},
                  "per_span_strong": {"%d,%d" % k: v for k, v in per_span_strong.items()}}
    _cache_store(all_c)
    return r


CACHE = os.path.join(ROOT, "notes", "reachability-cache.json")


def targets():
    """Every .incbin span that holds reachable code, ranked by HOW MUCH, with a
    running total. This is the work list for a coverage goal: convert from the
    top and stop when the cumulative column says you are done.

    ⚠ Ranking by SPAN SIZE instead sends you at the wrong spans -- prom_a's
    0xFA1404 is 16,380 bytes and only 1,060 of them are reachable, while
    0xF85D1C is 366 bytes and ALL of them are."""
    import json
    rows = []
    for tag, _s, _f, _b in IMAGES:
        cpu = CPU1 if tag in CPU1 else CPU2
        r = analyse(tag, cpu)
        for lo, hi in r["spans"]:
            n = r["per_span"].get((lo, hi), 0)
            if n:
                rows.append((r["per_span_strong"].get((lo, hi), 0), n, tag, lo, hi, hi - lo))
    rows.sort(reverse=True)
    total_s = sum(x[0] for x in rows)
    total_a = sum(x[1] for x in rows)
    print("%-8s %-21s %8s %8s %8s %9s %7s" %
          ("image", "span", "size", "STRONG", "any", "cumul(S)", "of goal"))
    run = 0
    for s, n, tag, lo, hi, size in rows:
        run += s
        print("%-8s 0x%06X-0x%06X %8s %8s %8s %9s %6.1f%%"
              % (tag, lo, hi, format(size, ","), format(s, ","), format(n, ","),
                 format(run, ","), 100.0 * run / total_s if total_s else 0.0))
    print("\nTOTAL reachable-and-unconverted: STRONG %s bytes, ANY %s, in %d spans."
          % (format(total_s, ","), format(total_a, ","), len(rows)))
    print("★ CONVERT ON THE **STRONG** COLUMN. `any` includes bytes reached only from a")
    print("  32-bit immediate or a framed .long entry, and a pointer is as likely to name")
    print("  a TABLE as a routine -- walking from one paints data as code. Round 1 framed")
    print("  701 bytes of pointer tables as instructions that way and the byte gate PASSED.")
    json.dump([{"image": t_, "lo": l, "hi": h, "size": s,
                "reachable_strong": st, "reachable_any": n}
               for st, n, t_, l, h, s in rows], open(CACHE, "w"), indent=1)
    print("Work list cached to %s" % os.path.relpath(CACHE, ROOT))


def runs_of(seen, lo, hi):
    """Maximal contiguous runs of marked bytes inside [lo,hi)."""
    out, start = [], None
    for x in range(lo, hi):
        if x in seen:
            if start is None:
                start = x
        elif start is not None:
            out.append((start, x))
            start = None
    if start is not None:
        out.append((start, hi))
    return out


def fallthrough_index(tag, proven):
    """{the address a proven instruction ENDS at: that instruction}, built ONCE.

    ⚠ WHY ONCE. start_evidence() used to scan the WHOLE proven set for every run
    it graded -- 257,759 proven addresses across the tree, each one a
    _decode_window() call -- so --evidence was O(runs x proven) and cost more
    than the walk it depends on. The question it asks of that scan is only "does
    some proven instruction end exactly here", and that is one dict.

    ★ The length at `a` comes from the boundary index when the walk has already
    settled it, which is what _decode_window() would have returned for that
    address anyway (its first row IS the index entry); an address the walk never
    reached still costs its one spawn, exactly as before."""
    bi = _BOUND[tag]
    out = {}
    for a in proven:
        e = bi.get(a)
        if e is None:
            rows = _decode_window(tag, a)
            if not rows or rows[0][0] != a:
                continue
            e = (rows[0][1], rows[0][2])
        out.setdefault(a + e[0], a)
    return out


def start_evidence(tag, cpu, addr, sd, proven, fall=None):
    """Does anything POSITIVELY say execution enters at `addr`?

    Two admissible witnesses, and nothing else:
      SEED       -- a graded seed names it (a directory slot, a branch in
                    converted code, a hardware vector, or a weak pointer).
      FALLTHROUGH-- already-converted code runs straight into it: some proven
                    instruction ends exactly here.
    A target queued while the walk was DECODING has neither, and that is the
    case that would have framed "SOUND GROUP NAMING" as `ld XIX,0x4f524720`."""
    for cls in list(STRONG) + list(WEAK):
        if addr in sd.get(cls, ()):
            return cls
    if fall is None:
        fall = fallthrough_index(tag, proven)
    if addr in fall:
        return "fallthrough"
    return None


def evidence():
    """Every reachable run still inside an .incbin, with the evidence for its
    START. Convert the ones with evidence; refuse the ones without."""
    for tag, _s, _f, _b in IMAGES:
        cpu = CPU1 if tag in CPU1 else CPU2
        r = analyse(tag, cpu)
        if r["seen"] is None:
            print("%s: cached run has no byte set; delete notes/.reachability-cache.json"
                  " and re-run to use --evidence" % tag)
            continue
        sd = seeds(tag, cpu)
        proven, _ = proven_and_incbin(tag)
        pset = set(proven)
        fall = fallthrough_index(tag, pset)
        good = bad = 0
        for lo, hi in r["spans"]:
            for a, b in runs_of(r["seen"], lo, hi):
                ev = start_evidence(tag, cpu, a, sd, pset, fall)
                if ev:
                    good += b - a
                else:
                    bad += b - a
                    print("  %s 0x%06X-0x%06X %5d B  ⚠ NO EVIDENCE for the start -- refuse"
                          % (tag, a, b, b - a))
        print("%-8s runs with start evidence: %s bytes; WITHOUT: %s bytes"
              % (tag, format(good, ","), format(bad, ",")))
    print("\n★ A run whose START nothing names was queued while the walk was DECODING,")
    print("  and the walk can decode its way into data. Two rounds running, framing such")
    print("  a run would have passed the byte gate with a wrong instruction.")


def report(mode=None):
    tot_i = tot_r = 0
    for tag, _s, _f, _b in IMAGES:
        cpu = CPU1 if tag in CPU1 else CPU2
        r = analyse(tag, cpu)
        tot_i += r["incbin"]
        tot_r += r["reach_in_incbin"]
        pct = 100.0 * r["reach_in_incbin"] / r["incbin"] if r["incbin"] else 0.0
        print("%-8s reached %8s bytes | still .incbin %7s | ★ REACHABLE AND UNCONVERTED %7s (%.1f%%)"
              % (tag, format(r["reached"], ","), format(r["incbin"], ","),
                 format(r["reach_in_incbin"], ","), pct))
        if mode == "seeds":
            for k in sorted(r["seeds"]):
                print("             seed %-14s %6d" % (k, r["seeds"][k]))
        if mode == "spans" and r["incbin"]:
            for lo, hi in sorted(r["spans"], key=lambda s: -(s[1] - s[0])):
                n = r["per_span"].get((lo, hi), 0)
                if n:
                    print("             0x%06X-0x%06X  %6d bytes, %5d reachable (%.0f%%)"
                          % (lo, hi, hi - lo, n, 100.0 * n / (hi - lo)))
    print("\nTOTAL still .incbin %s, of which REACHABLE CODE %s (%.1f%%)"
          % (format(tot_i, ","), format(tot_r, ","),
             100.0 * tot_r / tot_i if tot_i else 0.0))
    print("\n★ The reachable figure is the coverage goal's remaining work. The rest of the")
    print("  .incbin is data or unreached, and converting it adds territory, not coverage.")
    print("  prom_d is DATA ONLY with no established load base and is not walked.")


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    # the decoder agrees with the tree's own proven boundaries
    for tag in ("prom_a", "prom_b", "prom_c"):
        proven, _ = proven_and_incbin(tag)
        pl = sorted(proven)
        hit = 0
        sample = pl[::max(1, len(pl) // 200)][:200]
        for a in sample:
            rows = _decode_window(tag, a)
            if rows and rows[0][0] == a:
                hit += 1
        check("%s: decoder lands on the tree's own proven boundary, %d of %d sampled"
              % (tag, hit, len(sample)), hit == len(sample))
        check("%s: the sample includes the LAST proven instruction (0x%06X)"
              % (tag, pl[-1]), pl[-1] in proven)

    # ★★ EVERY SHARED SOURCE REACHES EVERY IMAGE THAT INCLUDES IT.  A shared
    # file's lines carry BOTH addresses -- `; FB77D8/F55321` -- a shape SRC_LINE
    # matches for neither, so a file this table does not know about is read as
    # zero instructions and the image looks less converted than it is, silently.
    # The check is per (image, shared file): at least one address from that
    # file's own column must be in that image's proven set.
    for tag, rels in SHARED_SOURCES.items():
        proven, _ = proven_and_incbin(tag)
        for rel, col in rels:
            # ⚠ ONLY THE INSTRUCTION LINES.  A shared source carries data rows
            # too -- kernel/kernel.s has three `.short`/`.long` slots with dual
            # addresses -- and proven_and_incbin excludes a data directive on
            # purpose, so a flat count of dual-address lines fails for the right
            # behaviour.  The filter here is the same DATA_DIRECTIVE.
            addrs = []
            for ln in open(os.path.join(ROOT, rel)).read().split("\n"):
                m = SHARED_ADDR.search(ln)
                if not m:
                    continue
                conv = ln[:m.start()] + "; " + m.group(col) + " " + ln[m.end():]
                mm = SRC_LINE.match(conv)
                if mm and not DATA_DIRECTIVE.match(mm.group(1)):
                    addrs.append(int(m.group(col), 16))
            got = sum(1 for a in addrs if a in proven)
            check("%s reaches %s: %d of %d instruction addresses proven"
                  % (tag, rel, got, len(addrs)), addrs and got == len(addrs))

    # indirection is actually being followed
    sd = seeds("prom_b", CPU1)
    check("the routine directory yields entry points no branch walk would reach",
          len(sd["directory"]) > 1000, "%d slots" % len(sd["directory"]))
    check("pointer tables (jump/dispatch) contribute entry points",
          len(sd["pointer_table"]) > 100, "%d" % len(sd["pointer_table"]))
    check("prom_a has vector-table entry points",
          len(seeds("prom_a", CPU1)["vector"]) > 0)

    # a walk marks whole instructions, never partial ones
    seen, q = set(), []
    proven, _ = proven_and_incbin("prom_c")
    start = sorted(proven)[len(proven) // 2]
    walk("prom_c", start, seen, CPU2, q)
    check("a walk from a proven address marks bytes", len(seen) > 0, "%d" % len(seen))
    check("...and the start address is among them", start in seen)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--evidence" in sys.argv:
        # this mode always re-walks: it needs the per-byte set. Stated rather
        # than silently slow -- and it no longer deletes the shared cache to
        # arrange that.
        FORCE_WALK = True
        evidence()
        sys.exit(0)
    if "--targets" in sys.argv:
        targets()
        sys.exit(0)
    report("seeds" if "--seeds" in sys.argv else "spans" if "--spans" in sys.argv else None)
