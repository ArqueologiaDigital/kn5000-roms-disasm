#!/usr/bin/env python3
"""Blocking-site dump for chosen forms, mirroring convert_reachable_ranges.main()
exactly (branch resolution included, same acceptance gates)."""
import importlib.util, json, os, re, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, path))
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    return m
crr = load("crr", "scripts/converters/convert_reachable_ranges.py")
cc = crr.cc
spans = load("spans", "scripts/analysis/v7_undisassembled_spans.py")
os.chdir(REPO)

rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
addr2name = dict(syms)

def formkey(x):
    mn = x.split()[0]
    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))

WANT = set(sys.argv[1:]) or {"push r", "or (imm),r"}
hits = []
counts = collections.Counter()
for t in sorted(targets):
    insns = crr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    _off = t - BASE; _run = 0
    while _off + _run < len(terr) and terr[_off + _run] == 2:
        _run += 1
    ends_at_code = sum(n for _, n, _ in insns) == _run
    _last = insns[-1][2].strip()
    if (_last.split()[0].lower() not in crr.TERMINATORS
            and not crr.UNCOND_JUMP.match(_last) and not ends_at_code):
        continue
    span = sum(n for _, n, _ in insns)
    want = rom[t - BASE: t - BASE + span]
    br = crr.resolve_branches(insns, t, span, addr2name)
    if br is None:
        continue
    br_texts, br_labels = br
    pos = 0
    for bi, (a, n, x) in enumerate(insns):
        target = want[pos:pos + n]
        if br_texts[bi] is not None:
            e = cc.encode(br_texts[bi])
            if e is None or len(e) != n:
                break
            pos += n; continue
        chosen = None; tried = []
        for cand in list(cc.translate(x)) + [cc.canonical(x)]:
            e = cc.encode(cand); tried.append((cand, e))
            if e == target:
                chosen = cand; break
        if chosen is None:
            k = formkey(x)
            counts[k] += 1
            if k in WANT:
                hits.append(dict(entry=t, addr=a, bytes=target.hex(" "),
                                 text=x, form=k,
                                 tried=[(c, (e.hex(" ") if e else None)) for c, e in tried]))
            break
        pos += n

json.dump(dict(hits=hits, counts=counts.most_common(20)),
          open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/hits2.json","w"), indent=1)
print("WROTE", len(hits))
