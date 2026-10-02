"""pseudo_ops.py: does every PSEUDO mnemonic encode the OPERATION its name says?  For every
assembled pseudo instance in the asm_sweep corpus (re-assembled here), the name's operation root
(e.g. sll_a_erpw -> sll, addb_erp -> add, ldto_werp -> ld, stb_dri -> ld) vs MAME's mnemonic.
Prints (def, name-root, MAME op, tree uses) for every def whose instances disagree."""
import collections, random, re, subprocess
import v1a_sweep as V, asm_sweep as A
mame_mn = set()
for line in open("/home/fsanches/compartilhado/mame/src/devices/cpu/tlcs900/dasm900.cpp"):
    if line.strip().startswith('"') and '",' in line:
        mame_mn.update(re.findall(r'"([a-z0-9]+)"', line))
SPECIAL = {"ldto": "ld", "ldfr": "ld", "st": "ld", "sti": "ld", "stib": "ld", "stiw": "ld", "ldib": "ld",
           "ldiw": "ld", "ldi": "ld", "cpib": "cp", "cpiw": "cp", "cpi": "cp", "lds": "ld", "ldmm": "ld",
           "ldmmb": "ld", "ldmmw": "ld", "mri": None, "mril": None, "mriw": None, "mrid": None, "extpfx": None,
           "ld2": "ld", "inc1b": "inc", "dec1b": "dec", "inc4": "inc", "inc1": "inc", "dec1": "dec",
           "ex8": "ex", "ex16": "ex", "djnz8": "djnz", "djnz16": "djnz", "unlk32": "unlk", "link32": "link",
           "jp16": "jp", "call16": "call", "slaa": "sla", "slla": "sll", "sraa": "sra", "srla": "srl"}
def root(name):
    r = name.lower().split("_")[0]
    if r in SPECIAL: return SPECIAL[r]
    if r in mame_mn: return r
    r2 = re.sub(r"\d+$", "", r)
    if r2 in SPECIAL: return SPECIAL[r2]
    if r2 in mame_mn: return r2
    for cut in (1, 2):
        if r2[:-cut] in mame_mn: return r2[:-cut]
    return "?" + r
rnd = random.Random(9)
work = []
for n in A.R["!instanceof"]["Instruction"]:
    r = A.R[n]
    if r.get("Namespace") != "TLCS900" or not r.get("AsmString") or r.get("isCodeGenOnly"): continue
    mn = r["AsmString"].split("\t")[0].split(" ")[0]
    if mn in mame_mn or V.fam(mn) in mame_mn: continue          # real mnemonics: asm_sweep compares them fully
    t, _ = A.instances(n, r["AsmString"], A.inst_operands(r), rnd)
    work += [(n, x) for x in t[:12]]
enc = V.llvm_encode([t for _, t in work])
ok = [(w, e) for w, e in zip(work, enc) if isinstance(e, bytes) and e != b"<fixup>"]
md = V.mame_decode([e for _, e in ok])
per = collections.defaultdict(collections.Counter); ex = {}
for ((n, t), e), m in zip(ok, md):
    mm = (m[1].split()[0].lower() if m else "?")
    rt = root(t.split()[0])
    if rt is None: continue
    good = (mm == rt or V.fam(mm) == rt or (rt == "ld" and mm in ("ld", "ldw", "lda")) or mm == "db")
    per[n]["ok" if good else "BAD"] += 1
    if not good: ex.setdefault(n, (t, e.hex(" "), m[1] if m else ""))
for n, c in sorted(per.items()):
    if c["BAD"]:
        t = ex[n][0].split()[0]
        uses = subprocess.run(["bash", "-c", "cd /home/fsanches/compartilhado/kn5000-roms-disasm && git grep -I -a -c -w '%s' -- '*.s' '*.inc' | awk -F: '{s+=$2} END{print s+0}'" % t], capture_output=True, text=True).stdout.strip()
        print("%-16s bad=%-3d ok=%-3d tree=%-5s e.g. %-34r -> %-16s MAME %s" % (n, c["BAD"], c["ok"], uses, ex[n][0], ex[n][1], ex[n][2]))
