"""Validate the wave-9 proposals and build wsa1_rename.py arguments (old=new|wrapped header + pointer to the evidence file)."""
import json, re, sys, textwrap, glob, os
os.chdir("/home/fsanches/compartilhado/kn5000-roms-disasm")
T = os.path.expanduser("~/compartilhado/tmp/wsa1-triage")
W = os.environ.get("WSA1_WAVE", "11")      # wave number: reads <T>/wave<W>/proposals_wave<W>_<batch>.json
BATCHES = sys.argv[1].split(",")
srcs = ["wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"] + sorted(glob.glob("wsa1/prom_c/**/*.s", recursive=True))
text = "\n".join(open(p, "rb").read().decode("latin-1") for p in srcs)
labels = set(re.findall(r'^([A-Za-z_][\w$]*):', text, re.M))
tokens = set(re.findall(r'[A-Za-z_][\w$]*', "\n".join(l.split(";")[0] for l in text.split("\n"))))
recs, bad = [], []
for k in BATCHES:
    for r in json.load(open("%s/wave%s/proposals_wave%s_%s.json" % (T, W, W, k))):
        r["_batch"] = k
        recs.append(r)
named = [r for r in recs if r["verdict"] == "name"]
olds = [r["old"] for r in named]; news = [r["new"] for r in named]
for r in named:
    if r["old"] not in labels: bad.append(("no label", r["old"]))
    if r["new"] in tokens: bad.append(("taken", r["new"]))
    if re.search(r'_(Helper|Sub|Data|Code|Block|Part|Stub|Entry|Case)\d*$|[0-9A-F]{6}', r["new"]): bad.append(("generic", r["new"]))
    if len(r.get("evidence", [])) < 2: bad.append(("thin evidence", r["old"]))
dup = {n for n in news if news.count(n) > 1} | {o for o in olds if olds.count(o) > 1}
if dup: bad.append(("dup", sorted(dup)))
print("records %d, named %d, refused %d" % (len(recs), len(named), len(recs) - len(named)))
for b in bad: print("BAD", b)
if "--args" in sys.argv:
    out = []
    for r in named:
        h = " ".join(r["header"].split())
        txt = "%s: %s (notes/naming-pilot-2026-10-06/proposals_wave%s_%s.json)" % (r["new"], h, W, r["_batch"])
        out.append("%s=%s|%s" % (r["old"], r["new"], "\n".join(textwrap.wrap(txt, 116, subsequent_indent="  "))))
    json.dump(out, open(T + "/wave%s/args.json" % W, "w"), indent=0)
    print("wrote", len(out), "args")
