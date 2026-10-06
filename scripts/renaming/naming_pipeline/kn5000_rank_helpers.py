"""Rank v10 *_Helper* routines by references from named (non-generic) routines."""
import re, glob, os, json, collections
os.chdir("/home/fsanches/compartilhado/kn5000-roms-disasm")
G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
GEN = re.compile(r'_(Helper|Data|Code|Block|Branch|Stub|Part|Case|Entry|Sub|Thunk|Wrapper|Body|Chunk|Tail|Frag|Fragment)\d*(_\d+)*$|_Switch\d+_Case\d+$')
HELP = re.compile(r'_Helper\d*$')
defs, refs = {}, collections.defaultdict(list)
for p in sorted(glob.glob("v10/maincpu/**/*.s", recursive=True)):
    L = open(p, "rb").read().decode("latin-1").split("\n")
    cur = None
    for i, l in enumerate(L):
        m = G.match(l)
        if m:
            n = m.group(1)
            if HELP.search(n):
                defs[n] = (os.path.relpath(p, "v10/maincpu"), i + 1)
            if not LOC.search(n) and not n.startswith("."):
                cur = n
        code = l.split(";")[0]
        mm = re.match(r'^\s+(call|calr|jp|jr|jrl|ld|lda)\b.*?\b([A-Za-z_]\w*_Helper\d*)\b', code)
        if mm and cur and cur != mm.group(2):
            refs[mm.group(2)].append(cur)
rows = []
for n, (f, ln) in defs.items():
    nc = sorted({c for c in refs.get(n, []) if not GEN.search(c) and not re.search(r'_[0-9A-F]{6}$', c)})
    rows.append(dict(name=n, file=f, line=ln, named_callers=nc[:10], n_named=len(nc)))
rows.sort(key=lambda r: (-r["n_named"], r["name"]))
json.dump(rows, open(os.path.expanduser("~/compartilhado/tmp/kn5000-naming/helpers.json"), "w"), indent=1)
print(len(rows), collections.Counter(min(r["n_named"], 4) for r in rows))
