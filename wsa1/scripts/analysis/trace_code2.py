#!/usr/bin/env python3
"""Seeded recursive-descent tracer -- WSA1 memory-map evidence.

QUESTION IT ANSWERS
    "Which absolute addresses does *reachable code* touch, per CPU?"
    Straight linear disassembly is unusable here: prom_c's IEEE-754 constant
    table at 0xFCB27E.. decodes as a tidy stride-4 register file that does not
    exist.  Only operands of instructions control flow can reach are reported.

SEEDS
    (1) the 33 reset/interrupt vectors at 0xFFFF00;
    (2) `jp abs` thunk tables -- >=4 consecutive 4-byte-aligned `1B lo mid hi`
        words whose targets land in ROM (prom_b has one at 0xF42D60);
    (3) function-pointer tables -- >=4 consecutive 4-byte-aligned LE32 words
        pointing at addresses that already decode as instructions.
    (2) and (3) are heuristics; (1) is not.  Run with --strict to use (1) only.

USAGE
    python3 scripts/analysis/trace_code2.py a b     # CPU 1 (prom_a @F80000 + prom_b @F00000)
    python3 scripts/analysis/trace_code2.py c       # CPU 2 (prom_c @F80000)
Needs unidasm; set UNIDASM= to override the default path.  Decode tables are
cached under $WSA1_CACHE (default /tmp/wsa1_dectab.pkl) -- rebuild takes ~25 s/ROM.
"""
import collections, os, pickle, re, sys, importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("tc", os.path.join(HERE, "trace_code.py"))
tc = importlib.util.module_from_spec(spec); spec.loader.exec_module(tc)

CACHE = os.environ.get("WSA1_CACHE", "/tmp/wsa1_dectab.pkl")
MEMOPND = re.compile(r'\(0x([0-9a-f]{2,8})\)')

def tables(letters):
    cache = {}
    if os.path.exists(CACHE):
        cache = pickle.load(open(CACHE, "rb"))
    tab, spans = {}, []
    dirty = False
    for L in letters:
        path, base = tc.ROMS[L]
        if L not in cache:
            cache[L] = tc.decode_table(path, base); dirty = True
        tab.update(cache[L])
        spans.append((L, base, base + os.path.getsize(path) - 1))
    if dirty:
        pickle.dump(cache, open(CACHE, "wb"))
    return tab, spans

def descend(tab, seeds, inrange):
    seen, work = set(), list(seeds)
    while work:
        a = work.pop()
        while True:
            if a in seen or a not in tab: break
            seen.add(a)
            n, txt = tab[a]
            for t in tc.branch_targets(txt):
                if t not in seen and inrange(t): work.append(t)
            if tc.is_flow_end(txt): break
            a += n
    return seen

def main(letters, strict=False):
    tab, spans = tables(letters)
    inrange = lambda a: any(b <= a <= e for _, b, e in spans)
    images = {L: (open(tc.ROMS[L][0], "rb").read(), tc.ROMS[L][1]) for L in letters}

    seeds = set()
    for L, (d, base) in images.items():
        if base <= 0xFFFF00 <= base + len(d) - 1:
            off = 0xFFFF00 - base
            for i in range(0, 0x84, 4):
                v = int.from_bytes(d[off+i:off+i+4], "little")
                if inrange(v): seeds.add(v)
    nvec = len(seeds)

    if not strict:
        for L, (d, base) in images.items():
            # (2) jp-abs thunk tables
            run = []
            for off in range(0, len(d) - 3, 4):
                ok = d[off] == 0x1B and inrange(int.from_bytes(d[off+1:off+4], "little"))
                if ok: run.append(base + off)
                else:
                    if len(run) >= 4: seeds.update(run)
                    run = []
            if len(run) >= 4: seeds.update(run)
            # (3) function-pointer tables
            run = []
            for off in range(0, len(d) - 3, 4):
                v = int.from_bytes(d[off:off+4], "little")
                ok = inrange(v) and v in tab
                if ok: run.append(v)
                else:
                    if len(run) >= 4: seeds.update(run)
                    run = []
            if len(run) >= 4: seeds.update(run)

    seen = descend(tab, seeds, inrange)
    total = sum(e - b + 1 for _, b, e in spans)
    covered = sum(tab[a][0] for a in seen)
    print("images: " + ", ".join("%s=0x%06X-0x%06X" % s for s in spans))
    print("seeds: %d vectors + %d table entries = %d" % (nvec, len(seeds) - nvec, len(seeds)))
    print("instructions reached: %d   bytes: %d / %d  (%.1f%%)"
          % (len(seen), covered, total, 100.0 * covered / total))

    refs = collections.Counter(); who = collections.defaultdict(set)
    for a in seen:
        for m in MEMOPND.finditer(tab[a][1]):
            v = int(m.group(1), 16); refs[v] += 1; who[v].add(a)
    print("\ndistinct memory operands in reached code: %d" % len(refs))
    runs, s, p, c, sites = [], None, None, 0, set()
    for v in sorted(refs):
        if s is None or v - p > 0x2000:
            if s is not None: runs.append((s, p, c, len(sites)))
            s = p = v; c = refs[v]; sites = set(who[v]); continue
        p = v; c += refs[v]; sites |= who[v]
    if s is not None: runs.append((s, p, c, len(sites)))
    print("  %-26s %8s %8s" % ("range", "refs", "sites"))
    for b, e, c, n in runs:
        print("  0x%06X - 0x%06X   %8d %8d" % (b, e, c, n))
    return refs, who, seen, tab

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    main(args or ["a"], strict="--strict" in sys.argv)
