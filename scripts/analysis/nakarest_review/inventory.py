"""inventory.py WORKDIR [--all] -- the v10 [nakarest] 'purpose not established' slices (with --all: every slice line,
labelled or not, that still covers a placeholder C member; an unlabelled one has label None and after_label): label, blob range, the readers the
note names, its bytes, and how many placeholder / symbolic C members cover it.  Writes WORKDIR/inventory.json, the
input of a triage batch (see README.md)."""
import sys, re, glob, os, json, collections
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
WORK = os.path.abspath(sys.argv[1])
os.chdir(ROOT)
sys.path.insert(0, "scripts/converters")
import nakarest_c_model as M
import importlib.util
spec = importlib.util.spec_from_file_location("ss", "scripts/analysis/semantic_score.py")
ss = importlib.util.module_from_spec(spec); spec.loader.exec_module(ss)
INC = re.compile(r'^([A-Za-z_]\w*):\s*\.incbin\s+"includes/generated/(naka_\w+)\.bin",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)\s*(;.*)?$')
cbs = {}
INC2 = re.compile(r'^\s+\.incbin\s+"includes/generated/(naka_\w+)\.bin",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)\s*(;.*)?$')
ALL = "--all" in sys.argv          # every slice line, labelled or not, that still covers a placeholder member
out = []
for p in sorted(glob.glob("v10/maincpu/**/*.s", recursive=True)):
    L = open(p, "rb").read().decode("latin-1").split("\n")
    for i, l in enumerate(L):
        if ALL:
            m = INC.match(l)
            m2 = None if m else INC2.match(l)
            if not (m or m2):
                continue
            j = i
            h0 = i
            while h0 > 0 and L[h0 - 1].startswith(";"):
                h0 -= 1
            if m:
                lab, blob, off, size = m.group(1), m.group(2), int(m.group(3), 16), int(m.group(4), 16)
            else:
                prev = next((G.group(1) for k in range(i - 1, -1, -1) for G in [re.match(r'^([A-Za-z_]\w*):', L[k])] if G), "?")
                lab, blob, off, size = None, m2.group(1), int(m2.group(2), 16), int(m2.group(3), 16)
        else:
            if not l.startswith("; [nakarest] purpose not established"):
                continue
            j = i
            while L[j].startswith(";"):
                j += 1
            h0 = i
            while L[h0 - 1].startswith("; [nakarest]"):
                h0 -= 1
            m = INC.match(L[j])
            if not m:
                continue
            lab, blob, off, size = m.group(1), m.group(2), int(m.group(3), 16), int(m.group(4), 16)
        b = open("v10/maincpu/includes/generated/%s.bin" % blob, "rb").read()[off:off + size]
        c = "v10/maincpu/ui_widgets/%s.c" % blob
        if blob not in cbs:
            try:
                cbs[blob] = M.CBlob(c)
            except BaseException:
                cbs[blob] = None
        cb = cbs[blob]
        ph = sym = tot = 0
        if cb:
            for x in cb.members:
                if off <= x.offset < off + size:
                    tot += 1
                    ph += ss.placeholder_field(x.name)
                    sym += bool(M.SYMBOLIC_RE.search(cb.entries[cb.by_name[x.name]].expr))
        if ALL and not ph:
            continue
        rec = dict(label=lab, asm=os.path.relpath(p, "v10/maincpu"), line=j + 1, blob=blob, off=off, size=size,
                   bytes=b[:64].hex(), notes=[x[len("; [nakarest] "):] if x.startswith("; [nakarest] ") else x[2:]
                                             for x in L[h0:j]][-12:],
                   c_members=tot, c_placeholder=ph, c_symbolic=sym, generic=bool(lab and ss.GENERIC.search(lab)))
        if lab is None:
            rec["after_label"] = prev
        out.append(rec)
json.dump(out, open(os.path.join(WORK, "inventory.json"), "w"), indent=1)
print(len(out), "slices;", sum(x["c_placeholder"] for x in out), "placeholder members;", sum(x["generic"] for x in out), "generic labels")
c = collections.Counter((x["asm"]) for x in out)
print(c.most_common())
