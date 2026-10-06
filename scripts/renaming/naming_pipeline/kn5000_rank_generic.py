"""Rank v10 generic labels (default _EntryN) by CALLS (call/calr) and jumps from named routines other than their own parent."""
import re, glob, os, json, collections, sys
os.chdir("/home/fsanches/compartilhado/kn5000-roms-disasm")
SUF = sys.argv[1] if len(sys.argv) > 1 else "Entry"
G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
GEN = re.compile(r'_(Helper|Data|Code|Block|Branch|Stub|Part|Case|Entry|Sub|Thunk|Wrapper|Body|Chunk|Tail|Frag|Fragment)\d*(_\d+)*$|_Switch\d+_Case\d+$|_0x[0-9A-Fa-f]+$|_[0-9A-F]{4,}$')
TGT = re.compile(r'_%s\d*$' % SUF)
defs, refs = {}, collections.defaultdict(list)
for p in sorted(glob.glob("v10/maincpu/**/*.s", recursive=True)):
    L = open(p, "rb").read().decode("latin-1").split("\n")
    cur = None
    for i, l in enumerate(L):
        m = G.match(l)
        if m:
            n = m.group(1)
            if TGT.search(n):
                defs[n] = (os.path.relpath(p, "v10/maincpu"), i + 1)
            if not LOC.search(n) and not n.startswith(".") and not TGT.search(n):
                cur = n
        code = l.split(";")[0]
        mm = re.match(r'^\s+(call|calr|jp|jr|jrl)\b(.*)$', code)
        if mm and cur:
            for t in re.findall(r'\b([A-Za-z_]\w*_%s\d*)\b' % SUF, mm.group(2)):
                refs[t].append((cur, mm.group(1)))
        for t in re.findall(r'\.long\s+([A-Za-z_]\w*_%s\d*)\b' % SUF, code):
            refs[t].append((cur or "?", ".long"))
rows = []
for n, (f, ln) in defs.items():
    stem = TGT.sub("", n)
    r = refs.get(n, [])
    calls = [c for c, k in r if k in ("call", "calr", ".long")]
    named = sorted({c for c, k in r if not GEN.search(c) and not c.startswith(stem)})
    rows.append(dict(name=n, file=f, line=ln, named_callers=named[:8], n_named=len(named), n_calls=len(calls), n_refs=len(r)))
rows.sort(key=lambda x: (-x["n_named"], -x["n_calls"], x["name"]))
json.dump(rows, open(os.path.expanduser("~/compartilhado/tmp/kn5000-naming/%s_ranked.json" % SUF.lower()), "w"), indent=1)
c = collections.Counter((min(r["n_named"], 3), r["n_calls"] > 0) for r in rows)
print(len(rows), sorted(c.items()))
for r in rows[:12]:
    print(r["n_named"], r["n_calls"], r["name"], r["named_callers"][:3])
