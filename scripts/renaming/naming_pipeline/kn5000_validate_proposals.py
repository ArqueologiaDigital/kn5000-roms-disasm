import json, re, glob, os, sys
os.chdir("/home/fsanches/compartilhado/kn5000-roms-disasm")
T = os.path.expanduser("~/compartilhado/tmp/kn5000-naming")
labs = {}
for t in ("v10", "v9", "v7"):
    s = set()
    for p in glob.glob(t + "/maincpu/**/*.s", recursive=True):
        s |= set(re.findall(r'^([A-Za-z_][\w$]*):', open(p, "rb").read().decode("latin-1"), re.M))
    labs[t] = s
recs = []
for k in sys.argv[1].split(","):
    for r in json.load(open("%s/proposals_kbatch_%s.json" % (T, k))):
        r["_b"] = k; recs.append(r)
nm = [r for r in recs if r["verdict"] == "name"]
print("records", len(recs), "named", len(nm))
news = [r["new"] for r in nm]
for r in nm:
    if r["old"] not in labs["v10"]: print("NO OLD", r["old"])
    for t in ("v10", "v9", "v7"):
        if r["new"] in labs[t]: print("TAKEN", t, r["new"])
    if re.search(r'_(Helper|Sub|Data|Code|Block|Part|Stub|Entry|Case)\d*$|[0-9A-F]{6}', r["new"]): print("GENERIC", r["new"])
    if news.count(r["new"]) > 1: print("DUP", r["new"])
for f in glob.glob("analysis/kn5000-naming/proposals-*.json"):
    for r in json.load(open(f)):
        if r.get("verdict") == "name" and r["new"] in news: print("PRIOR", r["new"], f)
