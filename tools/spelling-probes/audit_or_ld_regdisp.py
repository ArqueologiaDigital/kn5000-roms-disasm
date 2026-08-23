#!/usr/bin/env python3
"""AUDIT (independent re-derivation) of the `or (r+imm),imm` / `ld r,(r+imm)` report.

Question it answers
-------------------
An earlier probe claimed: 1355 sites of these two forms in v7's reachable
ranges, 1337 spellable today, 18 closed by three proposed rules, 0 left, and no
backend gap.  This script re-derives all four numbers WITHOUT reusing that
probe's candidate generator, so the two are independent witnesses.

Method (three passes, each printed separately)
----------------------------------------------
1. ENUMERATE  - decode every reachable call-target range with the converter's
   own `decode_range()`, and record every instruction whose normalised form is
   `or (r+imm),imm` or `ld r,(r+imm)`, with its ROM bytes.  Answers "which
   addresses exist, and how many times is each reached".
2. TODAY      - for each site ask the converter's OWN speller
   (`cc.translate()` + `cc.canonical()`, encoded with `cc.encode()`, exactly as
   convert_reachable_ranges.py does) whether some candidate equals the ROM
   bytes.  Answers "what blocks the converter today".
3. PROPOSED   - generate candidates here from scratch (literal / zero-sentinel
   `+0x100` / signed `- 0xNN` displacement, crossed with the mem-immediate ALU
   mnemonic table) and assemble them in ONE llvm-mc call.  Answers "do the
   proposed rules close every blocked site, byte-exactly".

Signal read: raw bytes of original_ROMs/kn5000_v7_program.rom at load base
0xE00000 versus `llvm-mc -triple=tlcs900 --show-encoding`.
PASS = identical bytes.  "Assembled without error" is NOT a pass.

Measured 2026-08-23, repo 28bbfe1, llvm tlcs900_backend@bcf152d1fe00:
    ENUMERATE  1201 distinct (addr,text) sites, 1355 site-visits
               ld r,(r+imm) 1193/1344 · or (r+imm),imm 8/11
    TODAY      1337 visits spellable, 18 blocked at 15 distinct addresses
    PROPOSED   0 sites with no candidate reproducing the ROM bytes

Run:  TMPDIR=<dir with space> python3 tools/spelling-probes/audit_or_ld_regdisp.py
      -> exit 0 when every site is byte-exact
"""
import importlib.util, json, os, re, subprocess, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
BASE = 0xE00000
WANT = {"or (r+imm),imm", "ld r,(r+imm)"}


def _load(name, rel):
    s = importlib.util.spec_from_file_location(name, os.path.join(REPO, rel))
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


def form_of(text):
    """The converter's own form key: registers -> `r`, hex literals -> `imm`."""
    parts = text.split(None, 1)
    rest = parts[1] if len(parts) > 1 else ""
    return parts[0] + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                   re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))


# ------------------------------------------------------------- 1. ENUMERATE
crr = _load("crr", "scripts/converters/convert_reachable_ranges.py")
cc = crr.cc
os.chdir(REPO)
spans = _load("spans", "scripts/analysis/v7_undisassembled_spans.py")
ROM = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

visits, meta, reached_from = collections.Counter(), {}, collections.defaultdict(set)
for t in targets:
    try:
        insns = crr.decode_range(ROM, terr, t)
    except Exception:
        continue
    for a, n, x in insns:
        f = form_of(x)
        if f in WANT:
            visits[(a, x)] += 1
            meta[(a, x)] = (n, ROM[a - BASE:a - BASE + n], f)
            reached_from[a].add(t)

sites = []
for (a, x), c in sorted(visits.items()):
    n, by, f = meta[(a, x)]
    sites.append(dict(addr=a, text=x, form=f, raw=by, visits=c))
print("1. ENUMERATE  distinct (addr,text) sites: %d   site-visits: %d"
      % (len(sites), sum(visits.values())))
for f in sorted(WANT):
    d = [s for s in sites if s["form"] == f]
    print("     %-18s distinct=%5d  visits=%5d"
          % (f, len(d), sum(s["visits"] for s in d)))

# ----------------------------------------------------------------- 2. TODAY
blocked = []
ok_today = 0
for s in sites:
    hit = None
    for cand in list(cc.translate(s["text"])) + [cc.canonical(s["text"])]:
        try:
            if cc.encode(cand) == s["raw"]:
                hit = cand
                break
        except Exception:
            pass
    if hit:
        ok_today += s["visits"]
    else:
        blocked.append(s)
print("\n2. TODAY      spellable visits: %d   blocked visits: %d   blocked sites: %d"
      % (ok_today, sum(s["visits"] for s in blocked), len(blocked)))
for s in blocked:
    print("     0x%06X  %-12s %-24s visits=%d  reached from %s"
          % (s["addr"], s["raw"].hex(), s["text"], s["visits"],
             ", ".join("0x%06X" % t for t in sorted(reached_from[s["addr"]]))))

# -------------------------------------------------------------- 3. PROPOSED
MI8 = {"or": "ormi8", "and": "and", "cp": "cp", "add": "addmi8",
       "sub": "submi8", "adc": "adcmi8", "sbc": "sbcmi8", "xor": "xormi8"}
MI16 = {"or": "ormi16", "and": "andw", "cp": "cpw", "add": "addiw_da",
        "sub": "submi16", "adc": "adcmi16", "sbc": "sbcmi16", "xor": "xormi16"}
RD_LD = re.compile(r'^ld ([A-Z]{1,3}),\(([A-Z]{2,3})\+(0x[0-9a-fA-F]+)\)$')
RD_AL = re.compile(r'^(\w+) \(([A-Z]{2,3})\+(0x[0-9a-fA-F]+)\),(0x[0-9a-fA-F]+)$')


def disp_spellings(reg, hexdisp):
    """Displacement texts to offer for a `(REG+0xNN)` unidasm printed raw.

    LD-1 zero sentinel: displacement 256 forces the wide form with d8 == 0.
    LD-2 signed: a 2-hex-digit value >= 0x80 is a negative d8, not a 16-bit one.
    """
    v = int(hexdisp, 16)
    out = ["(%s+%s)" % (reg.lower(), hexdisp)]
    if v == 0:
        out.append("(%s+0x100)" % reg.lower())
    if len(hexdisp) - 2 <= 2 and 0x80 <= v <= 0xff:
        out.append("(%s - 0x%02x)" % (reg.lower(), 0x100 - v))
    return out


cands, flat = {}, []
for i, s in enumerate(sites):
    c = []
    m = RD_LD.match(s["text"])
    if m:
        dst, base, d = m.groups()
        c = ["ld %s, %s" % (dst.lower(), a) for a in disp_spellings(base, d)]
    m = RD_AL.match(s["text"])
    if m:
        mn, base, d, imm = m.groups()
        c = ["%s %s, %s" % (tbl[mn.lower()], a, imm)
             for a in disp_spellings(base, d)
             for tbl in (MI8, MI16) if mn.lower() in tbl]
    cands[i] = c or ["<<NO CANDIDATE GENERATED>>"]
    flat += [(i, x) for x in cands[i]]

r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                   input="\n".join(x for _, x in flat) + "\n",
                   capture_output=True, text=True)
failed = {int(m) for m in re.findall(r'^<stdin>:(\d+):\d+: error:', r.stderr, re.M)}
encs = iter([bytes(int(y, 16) for y in m.split(",") if y.strip())
             for m in re.findall(r'encoding: \[([^\]]+)\]', r.stdout)])
got = [None if i in failed else next(encs) for i in range(1, len(flat) + 1)]

per_site = collections.defaultdict(list)
for k, (i, text) in enumerate(flat):
    per_site[i].append((text, got[k]))

closed, fails = [], []
for i, s in enumerate(sites):
    hits = [(t, e) for t, e in per_site[i] if e == s["raw"]]
    if not hits:
        fails.append((s, per_site[i]))
    elif s in blocked:
        closed.append((s, hits[0][0]))
print("\n3. PROPOSED   sites closed by a proposed rule: %d   sites with NO "
      "matching candidate: %d" % (len(closed), len(fails)))
for s, spell in closed:
    print("     0x%06X  %-12s %-24s -> %-28s [%s]"
          % (s["addr"], s["raw"].hex(), s["text"], spell, s["raw"].hex(" ")))
for s, cs in fails:
    print("     FAIL 0x%06X %s %s" % (s["addr"], s["raw"].hex(), s["text"]))
    for t, e in cs:
        print("            %-40s -> %s" % (t, e.hex() if e else "REJECTED"))

print("\nVERDICT: %s" % ("every site byte-exact" if not fails else "SITES LEFT UNSPELLED"))
sys.exit(1 if fails else 0)
