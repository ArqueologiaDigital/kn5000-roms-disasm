#!/usr/bin/env python3
"""verify_respells.py -- adversarial check of the wave-3a source respells.

Question: for every line a T1 respell commit ADDED to a .s file, does the new
text name the operation the CPU actually executes?  Each added instruction line
is assembled alone with the pinned llvm-mc (fixup bytes zeroed), the bytes are
decoded by MAME's unidasm, and the SOURCE TEXT (not llvm's disassembly) is
compared with MAME's reading: mnemonic family, register names, pre/post
direction, displacement / immediate / address values (symbols are wildcards).
ERP LD lines are checked for direction (ldto r,N == MAME ld r,R_N).

Run: python3 verify_respells.py <commit> ...   (in the kn5000-roms-disasm tree)
Writes resp_<commit>.tsv with every non-OK line.
"""
import collections, os, re, subprocess, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import strict_sweep as S

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
HERE = os.path.dirname(os.path.abspath(__file__))
REGS = set("""a w b c d e h l wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz xsp qa qw qb qc
qd qe qh ql qwa qbc qde qhl qix qiy qiz qsp ixl ixh iyl iyh izl izh spl sph qixl qixh qiyl qiyh
qizl qizh qspl qsph sr f""".split()) | {"%s%d" % (r, b) for r in ("xwa", "xbc", "xde", "xhl") for b in range(4)}
CC = set("f lt le ule pe ov mi m z c t ge gt ugt po nov p pl nz nc eq ne".split())


def added_lines(commit):
    raw = subprocess.run(["git", "-C", REPO, "show", "-U0", "--format=", commit, "--", "*.s"],
                         capture_output=True).stdout.decode("latin-1")
    out, f = [], None
    for ln in raw.splitlines():
        if ln.startswith("+++ "):
            f = ln[6:]
        elif ln.startswith("+") and not ln.startswith("+++"):
            out.append((f, ln[1:]))
    return out


def strip(line):
    # drop comment (';' outside quotes), label prefix
    s, q = "", False
    for ch in line:
        if ch == '"':
            q = not q
        if ch == ";" and not q:
            break
        s += ch
    s = s.strip()
    m = re.match(r'^[A-Za-z_.$][\w.$]*:\s*(.*)$', s)
    if m:
        s = m.group(1).strip()
    return s


def is_insn(s):
    if not s or s.startswith(".") or s.startswith("#") or "\\" in s or "=" in s.split()[0]:
        return False
    return re.match(r'^[a-z][a-z0-9_]*\b', s, re.I) is not None


def encode(texts):
    res = [None] * len(texts)
    CH = 3000
    for start in range(0, len(texts), CH):
        part = texts[start:start + CH]
        src = []
        for i, t in enumerate(part):
            src.append('.section .q%d,"ax"' % i)
            src.append("\t" + t)
        p = os.path.join(HERE, "_resp.s")
        open(p, "w", encoding="latin-1").write("\n".join(src) + "\n")
        r = subprocess.run([S.MC, "-triple=tlcs900", "--show-encoding", p],
                           capture_output=True, text=True, encoding="latin-1")
        cur = None
        for line in r.stdout.splitlines():
            st = line.strip()
            if st.startswith(".section"):
                try:
                    cur = int(st.split(".q")[1].split(",")[0])
                except Exception:
                    cur = None
                continue
            m = S.ENC_RE.match(line)
            if m and cur is not None and res[start + cur] is None:
                raw = [x.strip() for x in m.group(2).split(",") if x.strip()]
                bs = []
                for x in raw:
                    try:
                        bs.append(int(x, 16))
                    except ValueError:
                        bs.append(0)
                res[start + cur] = bytes(bs)
    return res


def has_symbol(op):
    ids = re.findall(r'[A-Za-z_][\w.$]*', op)
    return any(i.lower() not in REGS and not re.fullmatch(r'0x[0-9a-f]+', i.lower()) for i in ids)


def cmp_src(src, mtext):
    lm, _, lo = src.replace("\t", " ").partition(" ")
    mm, _, mo = mtext.partition(" ")
    lm, mm = lm.lower(), mm.lower()
    lops_raw = S.split_ops(lo) if lo.strip() else []
    ms = S.split_ops(mo) if mo.strip() else []
    mops = []
    for i, x in enumerate(ms):
        ea = (mm == "lda" and i == 1) or (mm in ("jp", "call") and i == len(ms) - 1)
        mops.append(S.norm_mame_op(x, mm if ea else "-"))
    if mm in ("inc", "dec", "incw", "decw") and mops and mops[0] == ("imm", 0):
        mops[0] = ("imm", 8)
    if mm in ("jp", "call", "ret", "jr", "jrl") and mops and mops[0][0] == "reg" and mops[0][1] in ("t",):
        mops = mops[1:]
    lops = []
    for x in lops_raw:
        if has_symbol(x):
            lops.append(("sym", x))
        else:
            lops.append(S.norm_llvm_op(x))
    if lm in ("jp", "call", "ret", "jr", "jrl") and lops and lops[0] == ("reg", "t"):
        lops = lops[1:]
    # ERP LD direction
    if lm.startswith("ldto_") or lm.startswith("ldfr_"):
        if mm != "ld" or len(ms) != 2:
            return "MNEM"
        r = lops_raw[0].strip().lower()
        if lm.startswith("ldto_") and ms[0].strip().lower() != r:
            return "ERPDIR"
        if lm.startswith("ldfr_") and ms[1].strip().lower() != r:
            return "ERPDIR"
        return "OK"
    if S.fam(lm) != S.fam(mm):
        return "MNEM"
    if len(lops) != len(mops):
        return "NOPS"
    for a, b in zip(lops, mops):
        if a[0] == "sym":
            # symbol: shape must be compatible
            ap = a[1].strip()
            if ap.startswith("(") and b[0] not in ("abs", "mem", "idx"):
                return "OPERAND"
            if b[0] == "mem":
                base = re.match(r'\(\s*([a-z0-9]+)', ap.lower())
                if not base or base.group(1) != b[1]:
                    return "OPERAND"
            continue
        if a[0] == "?":
            return "UNPARSED_SRC"
        if b[0] == "?":
            return "UNPARSED_MAME"
        if a == b:
            continue
        if a[0] == "imm" and b[0] == "imm" and ((a[1] - b[1]) % (1 << 32) == 0 or (a[1] & 0xffff) == b[1] or (a[1] & 0xff) == b[1]):
            continue
        return "OPERAND"
    return "OK"


def main():
    for c in sys.argv[1:]:
        lines = added_lines(c)
        cand = [(f, l, strip(l)) for f, l in lines]
        cand = [(f, l, s) for f, l, s in cand if is_insn(s)]
        enc = encode([s for _, _, s in cand])
        blobs, idx = [], []
        for i, e in enumerate(enc):
            if e:
                blobs.append(e + bytes(S.SLOT - len(e)) if len(e) <= S.SLOT else e[:S.SLOT])
                idx.append(i)
        md = S.mame_decode([b[:S.SLOT] for b in blobs]) if blobs else []
        cnt = collections.Counter()
        rows = []
        trees = collections.Counter()
        for (i, m) in zip(idx, md):
            f, l, s = cand[i]
            e = enc[i]
            if m is None:
                v = "NO_MAME"
            elif m[0] != len(e):
                v = "LEN"
            elif m[1].split()[0].lower() == "db":
                v = "MAME_DB"
            else:
                v = cmp_src(s, m[1])
            cnt[v] += 1
            trees[f.split("/")[0]] += 1
            if v != "OK":
                rows.append((v, f, s, e.hex(" "), m[1] if m else ""))
        nenc = sum(1 for e in enc if e)
        print("== %s: %d added lines, %d instruction lines, %d assembled standalone" % (
            c, len(lines), len(cand), nenc))
        for k, n in sorted(cnt.items()):
            print("   %-14s %6d" % (k, n))
        print("   trees:", dict(trees))
        with open(os.path.join(HERE, "resp_%s.tsv" % c), "w", encoding="latin-1") as fo:
            for r in rows:
                fo.write("\t".join(r) + "\n")
        # not-assembled list
        with open(os.path.join(HERE, "resp_%s_noasm.txt" % c), "w", encoding="latin-1") as fo:
            for i, e in enumerate(enc):
                if not e:
                    fo.write("%s\t%s\n" % (cand[i][0], cand[i][2]))


if __name__ == "__main__":
    main()
