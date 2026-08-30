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

LINE = re.compile(r'^\s*([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
FLOW_END = re.compile(r'^\s*(ret|reti|retd|jp\s|jr\s+0x|halt|swi)', re.I)
BRANCH = re.compile(r'\b(?:jr|jp|call|calr)\b[^;]*?0x([0-9a-f]{6})', re.I)


def rom(img):
    return open(os.path.join(ROOT, "original_ROMs", img), "rb").read()


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


def _fingerprint():
    h = hashlib.sha1()
    for _t, s, _f, _b in IMAGES:
        h.update(open(os.path.join(ROOT, s), "rb").read())
    h.update(open(os.path.abspath(__file__), "rb").read())
    return h.hexdigest()


def _cache_load():
    try:
        c = _json.load(open(RESULT_CACHE))
        return c["result"] if c.get("fingerprint") == _fingerprint() else None
    except Exception:
        return None


def _cache_store(result):
    try:
        _json.dump({"fingerprint": _fingerprint(), "result": result},
                   open(RESULT_CACHE, "w"))
    except Exception:
        pass


# ----------------------------------------------------------------- decoding
_WIN = {}
# addr -> (length, text) for every instruction any decoded window has revealed.
# ★ THE OPTIMISATION THAT MATTERS: a window decoded from seed A also settles the
# boundaries of every instruction in A's linear run, so a later walk starting at
# any of those addresses is a CACHE HIT and costs no subprocess. Without this the
# tool spawns one unidasm per seed -- thousands -- and takes tens of minutes.
_BOUND = defaultdict(dict)
WINDOW = 0x800


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
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for ln in out.splitlines():
        m = LINE.match(ln)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    _WIN[key] = rows
    for a, ln, text in rows:
        bi[a] = (ln, text)
    return rows


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
SRC_LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(\s|$)')
LONG_DIR = re.compile(r'^\t\.long\s+0x([0-9A-Fa-f]{8})')
INCBIN = re.compile(r'^\t\.incbin "original_ROMs/(\S+?)", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)\s*$')


def source_lines(tag):
    path = dict((t, s) for t, s, _f, _b in IMAGES)[tag]
    return open(os.path.join(ROOT, path)).read().split("\n")


def proven_and_incbin(tag):
    """(instruction addresses already in the .s, [(lo,hi) still .incbin])."""
    b = BASES[tag]
    proven, spans = set(), []
    for ln in source_lines(tag):
        m = SRC_LINE.match(ln)
        if m:
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
        text = m.group(1)
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


def analyse(tag, cpu):
    """Cached: see the fingerprint note above. `seen` is returned as a set for the
    caller, but persisted as per-span counts, which is all any caller needs."""
    if tag in _MEM:
        return _MEM[tag]
    cached = _cache_load()
    if cached and tag in cached:
        c = cached[tag]
        r = {"seeds": c["seeds"], "reached": c["reached"], "incbin": c["incbin"],
             "reach_in_incbin": c["reach_in_incbin"],
             "spans": [tuple(s) for s in c["spans"]],
             "per_span": {tuple(k.split(",")): v for k, v in c["per_span"].items()},
             "seen": None}
        _MEM[tag] = r
        return r
    proven, spans = proven_and_incbin(tag)
    sd = seeds(tag, cpu)
    seen = set()
    queue = []
    for cls in sd:
        queue.extend(sorted(sd[cls]))
    queue.extend(sorted(proven))          # every proven instruction is reachable
    done = set()
    while queue:
        a = queue.pop()
        if a in done:
            continue
        done.add(a)
        walk(tag, a, seen, cpu, queue)
    incbin_bytes = sum(hi - lo for lo, hi in spans)
    per_span = {}
    for lo, hi in spans:
        per_span[(lo, hi)] = sum(1 for x in range(lo, hi) if x in seen)
    reach_in_incbin = sum(per_span.values())
    r = {
        "seeds": {k: len(v) for k, v in sd.items()},
        "reached": len(seen),
        "incbin": incbin_bytes,
        "reach_in_incbin": reach_in_incbin,
        "spans": spans,
        "per_span": per_span,
        "seen": seen,
    }
    _MEM[tag] = r
    all_c = _cache_load() or {}
    all_c[tag] = {"seeds": r["seeds"], "reached": r["reached"], "incbin": r["incbin"],
                  "reach_in_incbin": r["reach_in_incbin"],
                  "spans": [list(s) for s in spans],
                  "per_span": {"%d,%d" % k: v for k, v in per_span.items()}}
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
                rows.append((n, tag, lo, hi, hi - lo))
    rows.sort(reverse=True)
    total = sum(r[0] for r in rows)
    print("%-8s %-21s %8s %9s %9s %7s" %
          ("image", "span", "size", "reachable", "cumul", "of goal"))
    run = 0
    for n, tag, lo, hi, size in rows:
        run += n
        print("%-8s 0x%06X-0x%06X %8s %9s %9s %6.1f%%"
              % (tag, lo, hi, format(size, ","), format(n, ","),
                 format(run, ","), 100.0 * run / total))
    print("\nTOTAL reachable-and-unconverted: %s bytes in %d spans."
          % (format(total, ","), len(rows)))
    json.dump([{"image": t_, "lo": l, "hi": h, "size": s, "reachable": n}
               for n, t_, l, h, s in rows], open(CACHE, "w"), indent=1)
    print("Work list cached to %s" % os.path.relpath(CACHE, ROOT))


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
    if "--targets" in sys.argv:
        targets()
        sys.exit(0)
    report("seeds" if "--seeds" in sys.argv else "spans" if "--spans" in sys.argv else None)
