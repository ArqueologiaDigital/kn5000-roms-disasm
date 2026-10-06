"""Rank prom_a/prom_b sub_ routines by references from NAMED routines (call/jp/calr/jr/.long), via T_ thunks too."""
import re, collections, json, os
G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$|__[0-9A-Fa-f]{4,6}$')
SUB = re.compile(r'^sub_F[0-9A-F]{5}$')
src = {i: open("%s/wsa1_%s.s" % (i, i), "rb").read().decode("latin-1").split("\n") for i in ("prom_a", "prom_b")}
thunk = {}   # T_xxx -> target name
for l in src["prom_b"]:
    m = re.match(r'^(T_\w+):\s*jp\s+(\w+)', l)
    if m:
        thunk[m.group(1)] = m.group(2)
refs = collections.defaultdict(list)
defs = {}
for img, L in src.items():
    cur = None
    for i, l in enumerate(L):
        m = G.match(l)
        if m:
            n = m.group(1)
            if SUB.match(n):
                defs[n] = (img, i + 1)
            if not LOC.search(n) and not n.startswith("."):
                cur = n
        code = l.split(";")[0]
        for t in re.findall(r'\b((?:sub|T)_F[0-9A-F]{5}|T_\w+)\b', code):
            t2 = thunk.get(t, t)
            if SUB.match(t2) and cur and cur != t2:
                kind = "long" if ".long" in code else "code"
                refs[t2].append((cur, kind, img, i + 1))
rows = []
for n, (img, ln) in defs.items():
    r = refs.get(n, [])
    named = sorted({c for c, k, _, _ in r if not SUB.match(c) and not c.startswith("T_F") and not re.search(r'_[0-9A-F]{6}$', c)})
    rows.append((len(named), n, img, ln, named[:8], len(r)))
rows.sort(key=lambda x: (-x[0], x[1]))
json.dump([dict(name=n, img=img, line=ln, named_callers=nc, refs=nr, n_named=k) for k, n, img, ln, nc, nr in rows],
          open(os.path.expanduser("~/compartilhado/tmp/wsa1-triage/ranked.json"), "w"), indent=1)
import collections as C
print(len(rows), C.Counter(min(k, 5) for k, *_ in rows))
for k, n, img, ln, nc, nr in rows[:25]:
    print(k, n, img, nc[:4])
