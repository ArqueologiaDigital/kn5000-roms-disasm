#!/usr/bin/env python3
"""asm_sweep.py -- V1a: does any ASSEMBLER spelling silently encode something other
than what it says?

For every MC instruction def of the TLCS900 backend (records.json, from
`llvm-tblgen -dump-json` of the pinned tree) and every InstAlias, build operand
instances from the AsmString's operand types (registers of every class,
memory operands in every addressing mode incl. (R+)/(-R)/bank registers/:8/:16
widths/direct addresses, condition codes, immediates), assemble each one
alone, and read the bytes with MAME's unidasm:

  ENC_DB     the assembler emitted bytes MAME calls `db` / `??`
  ENC_LEN    MAME reads a different instruction length than was emitted
  MNEM/OPERAND/NOPS/STEP*  (real mnemonics) the text and MAME disagree on the
             operation or an operand (register, order, value, step)
  REGSET     (pseudo mnemonics) the register NAMES written differ from MAME's

Run:   python3 asm_sweep.py [--limit-per-inst N]
Out:   out/asm_sweep.tsv, out/asm_sweep.counts
"""
import collections, itertools, json, os, random, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import v1a_sweep as V

HERE = os.path.dirname(os.path.abspath(__file__))
# records.json: llvm-tblgen --dump-json of the TLCS900 .td (25 MB, not committed; see README)
R = json.load(open(os.environ.get("RECORDS", os.path.join(V.OUT, "records.json"))))
LIMIT = 60
if "--limit-per-inst" in sys.argv:
    LIMIT = int(sys.argv[sys.argv.index("--limit-per-inst") + 1])

GR8 = "w a b c d e h l".split()
GR16 = "wa bc de hl ix iy iz".split()
GR16SP = GR16 + ["sp"]
GPR = "xwa xbc xde xhl xix xiy xiz xsp".split()
PREV16 = "qwa qbc qde qhl qix qiy qiz qsp".split()
MEM = ["(xbc)", "(xiz)", "(xsp)", "(xde+5)", "(xsp-1)", "(xix+127)", "(xiy-128)", "(xhl+128)",
       "(xwa-129)", "(xbc+256)", "(xiz+32767)", "(xsp-32768)", "(xhl+0:8)", "(xiz+5:16)",
       "(xsp-1:16)", "(xde+127:8)", "(xde-128:8)", "(xbc+0:16)",
       "(xde+)", "(-xbc)", "(xix+:1)", "(xix+:2)", "(xix+:4)", "(-xsp:2)", "(xbc3+)", "(-xwa0)",
       "(xhl1+:4)", "(30:8)", "(8990:16)", "(0x123456:24)", "(30)", "(8990)", "(0x123456)"]
MEMRR = ["(xix+wa)", "(xwa+bc)", "(xsp+iz)"]
MEMRR8 = ["(xix+a)", "(xwa+b)", "(xsp+l)"]
MEMRRQ = ["(xix+qwa)", "(xwa+qbc)"]
CC = "f lt le ule ov mi z c t ge gt ugt nov pl nz nc".split()
IMM = {"i8imm": ["0", "5", "127", "0x80", "0xff"], "i16imm": ["0", "5", "0x1234", "0xffff"],
       "i32imm": ["0", "1", "5", "7", "0x30", "0xe4", "0xfb", "0x1234"],
       "immi3_8": ["0", "1", "7"], "immi3_16": ["0", "1", "7"], "immi3_32": ["0", "1", "7"],
       "immio8": ["0x12"], "immio16": ["0x1234"], "brtarget": ["0x100", "5", "-3"],
       "daddr16": ["(0x1234)", "(30)"], "daddr8": ["(0x1e)"],
       "directaddr": ["(30)", "(8990)", "(0x123456)", "(8990:16)", "(30:8)", "(0x123456:24)", "30", "8990"]}
TYPES = {"GR8": GR8, "GR16": GR16, "GR16SP": GR16SP, "GPR": GPR, "GPR_with_sub8": GPR[:4],
         "GPRnoXWA": GPR[1:], "PrevGR16": PREV16, "mulpair8": ["wa", "bc", "de", "hl"],
         "gr16asx": GPR, "gpraslo16": GR16SP, "MEMri": MEM, "MEMrr": MEMRR, "MEMrr8": MEMRR8,
         "MEMrrq": MEMRRQ, "cc": CC}
TYPES.update(IMM)


def inst_operands(r):
    ops = {}
    for lst in ("OutOperandList", "InOperandList"):
        for a in r[lst]["args"]:
            ops[a[1]] = a[0]["def"]
    return ops


def instances(name, asm, ops, rnd):
    toks = re.findall(r'\$\{(\w+)\}|\$(\w+)', asm)
    names = [a or b for a, b in toks]
    choices = []
    for n in names:
        t = ops.get(n)
        if t not in TYPES:
            return [], "UNTYPED:%s:%s" % (n, t)
        choices.append(TYPES[t])
    total = 1
    for ch in choices:
        total *= len(ch)
    if total <= LIMIT:
        combos = list(itertools.product(*choices)) if choices else [()]
    else:
        # every value of every operand at least once (others random), then random fill
        seen = set()
        combos = []
        for i, ch in enumerate(choices):
            for v in ch:
                c = tuple(v if j == i else rnd.choice(choices[j]) for j in range(len(choices)))
                if c not in seen:
                    seen.add(c); combos.append(c)
        tries = 0
        while len(combos) < LIMIT and tries < LIMIT * 20:
            tries += 1
            c = tuple(rnd.choice(ch) for ch in choices)
            if c not in seen:
                seen.add(c); combos.append(c)
    out = []
    for c in combos:
        it = iter(c)
        text = re.sub(r'\$\{(\w+)\}|\$(\w+)', lambda m: next(it), asm).replace("\t", " ")
        out.append(text)
    return out, None


REGNAME = re.compile(r"(?<![0-9a-z_'])([a-z]{1,3}[0-9]?)(?![0-9a-z_(])")
ALLREG = set(GR8 + GR16SP + GPR + PREV16 + "ixl ixh iyl iyh izl izh qa qw qb qc qd qe qh ql".split()) | \
    {r + b for r in ("xwa", "xbc", "xde", "xhl") for b in "0123"}


def regset(text, mame):
    def names(t):
        t = t.lower()
        mn, _, ops = t.partition(" ")
        found = []
        for m in REGNAME.finditer(ops):
            if m.group(1) in ALLREG and m.group(1) not in CC:
                found.append(m.group(1))
        return sorted(found)
    return names(text), names(mame)


def main():
    rnd = random.Random(1)
    defs = [n for n in R["!instanceof"]["Instruction"] if R[n].get("Namespace") == "TLCS900"
            and not R[n].get("isPseudo") and not R[n].get("isCodeGenOnly") and R[n].get("AsmString")]
    work = []          # (defname, text)
    skipped = collections.Counter()
    for n in sorted(defs):
        r = R[n]
        texts, why = instances(n, r["AsmString"], inst_operands(r), rnd)
        if why:
            skipped[why] += 1
        for t in texts:
            work.append((n, t))
    for a in R["!instanceof"]["InstAlias"]:
        r = R[a]
        res = r["ResultInst"]
        target = res["operator"]["def"]
        ops = {arg[1]: arg[0]["def"] for arg in res["args"] if isinstance(arg[0], dict) and arg[1]}
        texts, why = instances(a, r["AsmString"], ops, rnd)
        if why:
            skipped[why] += 1
        for t in texts:
            work.append(("ALIAS:" + r["AsmString"].split()[0] + "->" + target, t))
    print("instances", len(work), "skipped defs", sum(skipped.values()), dict(skipped.most_common(8)))
    enc = V.llvm_encode([t for _, t in work])
    ok_idx = [i for i, e in enumerate(enc) if isinstance(e, bytes) and e != b"<fixup>"]
    blobs = [enc[i] for i in ok_idx]
    md = V.mame_decode(blobs)
    ld = V.llvm_decode(blobs)
    mame_mn = set()
    for line in open(os.path.expanduser("~/compartilhado/mame/src/devices/cpu/tlcs900/dasm900.cpp")):
        if line.strip().startswith('"') and '",' in line:
            mame_mn.update(re.findall(r'"([a-z0-9]+)"', line))
    c = collections.Counter()
    rows = []
    errs = collections.Counter()
    for i, e in enumerate(enc):
        if not isinstance(e, bytes):
            errs[e[0] if isinstance(e, tuple) else "NOENC"] += 1
    for i, b, m, l in zip(ok_idx, blobs, md, ld):
        dn, t = work[i]
        mt = m[1] if m else ""
        lt = l[1] if l else ""
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
                a_, b_ = regset(t, mt)
                v = "PSEUDO_OK" if (not a_ or a_ == b_) else "REGSET"
        c[v] += 1
        if v not in ("OK", "PSEUDO_OK"):
            rows.append((v, dn, t, b.hex(" "), mt, lt))
    print(dict(errs))
    for k, n in sorted(c.items()):
        print("  %-14s %6d" % (k, n))
    os.makedirs(V.OUT, exist_ok=True)
    with open(os.path.join(V.OUT, "asm_sweep.tsv"), "w") as fo:
        fo.write("class\tdef\ttext\tbytes\tmame\tllvm_redecode\n")
        for r in rows:
            fo.write("\t".join(r) + "\n")
    with open(os.path.join(V.OUT, "asm_sweep.counts"), "w") as fo:
        fo.write("instances %d errors %s\n" % (len(work), dict(errs)))
        for k, n in sorted(c.items()):
            fo.write("%s %d\n" % (k, n))
    with open(os.path.join(V.OUT, "asm_sweep_errors.tsv"), "w") as fo:
        for (dn, t), e in zip(work, enc):
            if not isinstance(e, bytes):
                fo.write("%s\t%s\t%s\n" % (dn, t, e[1] if isinstance(e, tuple) else "noenc"))


if __name__ == "__main__":
    main()
