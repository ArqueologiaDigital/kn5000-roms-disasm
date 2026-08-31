#!/usr/bin/env python3
"""Recursive-descent code tracer for the WSA1 TLCS-900/H ROMs.

WHAT QUESTION IT ANSWERS
    "Which bytes of a WSA1 ROM are really instructions, and which absolute
     addresses does that *code* (as opposed to misdisassembled data) touch?"

    A straight linear sweep of these images is worthless for a memory map:
    prom_c's IEEE-754 double table at 0xFCB27E..0xFCB4E6 decodes as a tidy
    stride-4 register file that does not exist.  This walker only reports
    operands of instructions that control flow can actually reach.

HOW
    A TLCS-900 instruction decodes identically no matter where the sweep that
    found it started, so we build a length/text table by running unidasm once
    per byte phase (0..PHASES-1) and merging.  Then we walk from the reset
    vector and the interrupt vector table.

USAGE
    python3 scripts/analysis/trace_code.py a          # prom_a  (base 0xF80000)
    python3 scripts/analysis/trace_code.py c          # prom_c  (base 0xF80000)
    python3 scripts/analysis/trace_code.py a b        # CPU 1: prom_a+prom_b as one space
Output: coverage stats, then every absolute address referenced by reached code,
grouped into runs, with reference counts.
"""
import os, re, subprocess, sys, tempfile, collections

ROOT    = "/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1"
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
PHASES  = 32

ROMS = {
    "a": (f"{ROOT}/original_ROMs/wsa1_prom_a.ic12", 0xF80000),
    "b": (f"{ROOT}/original_ROMs/wsa1_prom_b.ic13", 0xF00000),
    "c": (f"{ROOT}/original_ROMs/wsa1_prom_c.ic28", 0xF80000),
    "d": (f"{ROOT}/original_ROMs/wsa1_prom_d.bin",  0x000000),
}

LINE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(.*)$')

def decode_table(path, base):
    """addr -> (length, text) for every address any phase-shifted sweep reached."""
    tab = {}
    data = open(path, "rb").read()
    with tempfile.TemporaryDirectory() as td:
        for ph in range(PHASES):
            chunk = os.path.join(td, "c.bin")
            open(chunk, "wb").write(data[ph:])
            out = subprocess.run([UNIDASM, chunk, "-arch", "tlcs900",
                                  "-basepc", hex(base + ph)],
                                 capture_output=True, text=True).stdout
            for ln in out.splitlines():
                m = LINE.match(ln)
                if not m:
                    continue
                a = int(m.group(1), 16)
                n = len(m.group(2).split())
                if a not in tab:
                    tab[a] = (n, m.group(3).strip())
    return tab

TARGET   = re.compile(r'0x([0-9a-f]{2,8})\s*$')
MEMOPND  = re.compile(r'\(0x([0-9a-f]{2,8})\)')

def is_flow_end(txt):
    t = txt.split()
    if not t: return True
    op = t[0]
    if op in ("ret", "reti", "retd"):
        return len(t) == 1 or t[1] in ("T",)
    if op in ("jp", "jrl", "jr"):
        # unconditional forms: bare, or condition "T"
        if len(t) == 1: return True
        arg = txt.split(None, 1)[1]
        return not re.match(r'^(NZ|Z|NC|C|PO|PE|P|M|NV|V|GE|LT|GT|LE|UGE|ULT|UGT|ULE|F),', arg)
    return False

def branch_targets(txt):
    t = txt.split()
    if not t: return []
    op = t[0]
    if op not in ("jp", "jr", "jrl", "call", "calr", "djnz"): return []
    m = TARGET.search(txt)
    return [int(m.group(1), 16)] if m else []

def main(letters):
    tab, lo, hi = {}, None, None
    spans = []
    for L in letters:
        path, base = ROMS[L]
        sz = os.path.getsize(path)
        spans.append((L, base, base + sz - 1))
        tab.update(decode_table(path, base))
    inrange = lambda a: any(b <= a <= e for _, b, e in spans)

    # entry points: the 33 vectors at 0xFFFF00.. of whichever image holds them
    entries = set()
    for L in letters:
        path, base = ROMS[L]
        d = open(path, "rb").read()
        if base <= 0xFFFF00 <= base + len(d) - 1:
            off = 0xFFFF00 - base
            for i in range(0, 0x84, 4):
                v = int.from_bytes(d[off+i:off+i+4], "little")
                if inrange(v): entries.add(v)
    if not entries:
        print("no vector table in this image set", file=sys.stderr); return

    seen, work = set(), list(entries)
    while work:
        a = work.pop()
        while True:
            if a in seen or a not in tab: break
            seen.add(a)
            n, txt = tab[a]
            for t in branch_targets(txt):
                if t not in seen and inrange(t): work.append(t)
            if is_flow_end(txt): break
            a += n

    total = sum(e - b + 1 for _, b, e in spans)
    covered = sum(tab[a][0] for a in seen)
    print("images: " + ", ".join("%s=0x%06X-0x%06X" % s for s in spans))
    print("entry points from vector table: %d" % len(entries))
    print("instructions reached: %d   bytes: %d / %d  (%.1f%%)"
          % (len(seen), covered, total, 100.0 * covered / total))

    refs = collections.Counter()
    for a in seen:
        for m in MEMOPND.finditer(tab[a][1]):
            refs[int(m.group(1), 16)] += 1
    print("\ndistinct memory operands in reached code: %d" % len(refs))
    runs, s, p, cnt = [], None, None, 0
    for v in sorted(refs):
        if s is None: s = p = v; cnt = refs[v]; continue
        if v - p <= 0x800: p = v; cnt += refs[v]
        else: runs.append((s, p, cnt)); s = p = v; cnt = refs[v]
    if s is not None: runs.append((s, p, cnt))
    for b, e, c in runs:
        print("  0x%06X - 0x%06X   refs=%d" % (b, e, c))
    return refs, seen, tab

if __name__ == "__main__":
    main(sys.argv[1:] or ["a"])
