#!/usr/bin/env python3
"""sp_asm_check.py -- T1 fix round: with SP accepted where a GR16 operand is
expected (the assembler's second matching pass), does every def / alias that
has a GR16 operand encode SP where MAME reads SP?

For each MC def and InstAlias with at least one GR16 operand, build instances
(asm_sweep.instances) with EVERY GR16 operand = sp, assemble them alone with
$MC, read the bytes with unidasm, and classify exactly as asm_sweep.py does
(OK / PSEUDO_OK vs ENC_DB / ENC_LEN / MNEM / OPERAND / REGSET).  Instances the
assembler refuses are counted, not judged (they were refused before too).

Run:  MC=... OBJDUMP=... python3 sp_asm_check.py     (records.json = llvm-tblgen -dump-json)
Out:  $OUTDIR/sp_asm_check_<REG>.tsv + counts on stdout.  REG=sp (default) or REG=wa for the twin run.
"""
import collections, os, random, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asm_sweep as A
import v1a_sweep as V

REG = os.environ.get("REG", "sp")
A.TYPES["GR16"] = [REG]
rnd = random.Random(7)
R = A.R
work = []
for n in sorted(R["!instanceof"]["Instruction"]):
    r = R[n]
    if r.get("Namespace") != "TLCS900" or r.get("isPseudo") or r.get("isCodeGenOnly") or not r.get("AsmString"):
        continue
    ops = A.inst_operands(r)
    names = [a or b for a, b in re.findall(r'\$\{(\w+)\}|\$(\w+)', r["AsmString"])]
    if not any(ops.get(x) == "GR16" for x in names):
        continue
    texts, why = A.instances(n, r["AsmString"], ops, rnd)
    work += [(n, t) for t in texts]
for a in R["!instanceof"]["InstAlias"]:
    r = R[a]
    res = r["ResultInst"]
    ops = {arg[1]: arg[0]["def"] for arg in res["args"] if isinstance(arg[0], dict) and arg[1]}
    names = [x or y for x, y in re.findall(r'\$\{(\w+)\}|\$(\w+)', r["AsmString"])]
    if not any(ops.get(x) == "GR16" for x in names):
        continue
    texts, why = A.instances(a, r["AsmString"], ops, rnd)
    work += [("ALIAS:" + r["AsmString"].split()[0] + "->" + res["operator"]["def"], t) for t in texts]
print("instances with sp in every GR16 operand:", len(work))
enc = V.llvm_encode([t for _, t in work])
ok_idx = [i for i, e in enumerate(enc) if isinstance(e, bytes) and e != b"<fixup>"]
blobs = [enc[i] for i in ok_idx]
md = V.mame_decode(blobs)
mame_mn = set()
for line in open(os.path.expanduser("~/compartilhado/mame/src/devices/cpu/tlcs900/dasm900.cpp")):
    if line.strip().startswith('"') and '",' in line:
        mame_mn.update(re.findall(r'"([a-z0-9]+)"', line))
c = collections.Counter()
rows = []
refused = sum(1 for e in enc if not isinstance(e, bytes))
for i, b, m in zip(ok_idx, blobs, md):
    dn, t = work[i]
    mt = m[1] if m else ""
    if m is None or mt.split()[0].lower() == "db" or "??" in mt:
        v = "ENC_DB"
    elif m[0] != len(b):
        v = "ENC_LEN"
    else:
        mn = t.split()[0].lower()
        step = (1 << (b[1] & 3)) if b[0] in (0xC4, 0xC5, 0xD4, 0xD5, 0xE4, 0xE5, 0xF4, 0xF5) else None
        if V.fam(mn) in mame_mn or mn in mame_mn:
            v = V.compare(t, mt, step)
        else:
            a_, b_ = A.regset(t, mt)
            v = "PSEUDO_OK" if (not a_ or a_ == b_) else "REGSET"
    sp_ok = REG.upper() in re.sub(r"X" + REG.upper(), "", mt.upper())
    c[(v, sp_ok)] += 1
    rows.append((v, str(sp_ok), dn, t, b.hex(" "), mt))
print("refused by the assembler:", refused, " assembled:", len(ok_idx))
for k, n in sorted(c.items()):
    print("  %-12s mame-names-SP=%-5s %6d" % (k[0], k[1], n))
os.makedirs(V.OUT, exist_ok=True)
with open(os.path.join(V.OUT, "sp_asm_check_%s.tsv" % REG), "w") as fo:
    fo.write("class\tmame_names_SP\tdef\ttext\tbytes\tmame\n")
    for r in rows:
        fo.write("\t".join(r) + "\n")
