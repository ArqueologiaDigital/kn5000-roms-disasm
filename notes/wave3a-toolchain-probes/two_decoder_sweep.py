#!/usr/bin/env python3
"""two_decoder_sweep.py -- where does this backend's disassembler print a
DIFFERENT INSTRUCTION (wrong operation or wrong register) than MAME's unidasm
reads from the same bytes?

QUESTION IT ANSWERS
    The byte gate cannot see a text defect: `stb_dpi a, 224` assembles to
    f5 e0 31, which IS the ROM's byte string, while the CPU executes
    `lda XBC,(XWA+)` there.  A round-trip census cannot see it either -- the
    lying text re-encodes to its own bytes.  Only a SECOND decoder can.  This
    sweep synthesises one probe for every sub-opcode of every addressing prefix
    (and every primary opcode), decodes each with llvm-objdump AND unidasm, and
    classifies the pair:

      AGREE       same length, same operation family, same register names
      REG_DIFF    same length and operation, but the REGISTER NAMES differ --
                  the `cpda8 xbc,(8990)` = cp A,(0x231e) class
      MNEM_DIFF   same length, different operation family -- the swapped
                  `stb_dpi` (store) = lda class
      LEN_DIFF    the two decoders consume a different number of bytes
      LLVM_ONLY   unidasm says `db` (no instruction) but llvm decodes one
      MAME_ONLY   llvm refuses (<unknown>) but unidasm decodes an instruction
      ASYM        (extra flag) llvm's own text does not re-encode to the bytes

    Registers are compared as a multiset of register NAMES, case-folded, with
    condition codes stripped from jp/jr/jrl/call/ret/scc/djnz.  A register
    written as a RAW NUMBER (the pseudo forms' `224` for XWA) is not a name and
    so shows up as REG_DIFF; that is deliberate -- a number where a register
    belongs is exactly what a reader cannot check.

PROBE SET (all synthetic; this is a decoder property, not a ROM property)
    * register-indirect prefixes 80+r..B8+r (r = 1 = XBC; d8 = 0x05)
    * extended prefixes C0/C1/C2 (addr 0x1e / 0x231e / 0x23 1e 00), C3 (d16
      mode e5 34 12), C4/C5 (register byte e8 = XDE, step 1), and the D/E/F
      rows the same way
    * register prefixes C8+1 (A), D8+1 (BC), E8+1 (XBC), C7/D7/E7 + 0xe4
    * every primary opcode 00..FF
    each followed by 256 sub-opcodes and the trailing bytes 34 12 78 56, then
    NOP padding to a 16-byte slot so a mis-length decode cannot desynchronise
    the next probe.

RUN
    python3 notes/wave3a-toolchain-probes/two_decoder_sweep.py [--out DIR] [--show CLASS]
    MC=/path/llvm-mc OBJDUMP=/path/llvm-objdump python3 ... (test another build)

    --selftest checks the pure classification function on synthetic text.

⚠ Heuristic normalisation.  The pseudo-mnemonic names are mapped to operation
families by the rules in FAMILY below; an unmapped name is reported as such and
counted MNEM_DIFF only if its stripped stem still differs.  Read the examples,
not just the counts.  Print the toolchain with every figure.
"""
import argparse
import collections
import hashlib
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROJECTS = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM = os.path.join(PROJECTS, "llvm-project", "build", "bin")
MC = os.environ.get("MC", os.path.join(LLVM, "llvm-mc"))
OBJDUMP = os.environ.get("OBJDUMP", os.path.join(LLVM, "llvm-objdump"))
UNIDASM = os.path.join(PROJECTS, "tools", "unidasm")
SLOT = 16
TAIL = [0x34, 0x12, 0x78, 0x56]
CHUNK = 3000

OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$')
ENC_RE = re.compile(r'^\s*(.*?)\s*;\s*encoding:\s*\[([^\]]*)\]\s*$')
UNI_RE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$')

REGS = set("""a w b c d e h l wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz
xsp qa qw qb qc qd qe qh ql qwa qbc qde qhl qix qiy qiz qsp ixl ixh iyl iyh izl
izh spl sph qixl qixh qiyl qiyh qizl qizh qspl qsph sr f
xwa0 xbc0 xde0 xhl0 xwa1 xbc1 xde1 xhl1 xwa2 xbc2 xde2 xhl2 xwa3 xbc3 xde3
xhl3""".split())
CC = set("f lt le ule pe ov mi m z c t ge gt ugt po nov p pl nz nc".split())
CC_MNEM = {"jp", "jr", "jrl", "call", "ret", "scc", "calr"}

BASE = set("""ld lda ldi ldir ldd lddr cpi cpir cpd cpdr push pop ex add adc sub
sbc cp and or xor inc dec mul muls div divs rlc rrc rl rr sla sra sll srl rld rrd
bit set res chg tset andcf orcf xorcf ldcf stcf jp jr jrl call calr ret reti retd
djnz scc nop halt ei di swi link unlk ldf ldc ldx extz exts paa daa cpl neg mirr
bs1f bs1b minc1 minc2 minc4 mdec1 mdec2 mdec4 mula incf decf rcf scf ccf zcf
max normal push_f pop_f push_a pop_a ex_ff""".split())

# Pseudo stems -> operation family.  Order matters (first match wins).
FAMILY = [
    (r'^st[bwl]?(_|$)', 'ld'), (r'^st[bwl]?_', 'ld'), (r'^sti[bwl]?(_|$)', 'ld'),
    (r'^ldto_', 'ld'), (r'^ldfr_', 'ld'),
    (r'^ldi[bwl]?_', 'ld'), (r'^ld[bwl]?_', 'ld'), (r'^ldmi', 'ld'),
    (r'^ldmw', 'ld'), (r'^ldmm', 'ld'), (r'^ldda', 'ld'), (r'^mx_lda', 'lda'),
    (r'^m_lda', 'lda'), (r'^lda', 'lda'), (r'^cpm', 'cp'), (r'^cpd[am]', 'cp'),
    (r'^cpi[bwl]?_', 'cp'), (r'^cp[bwl]?_', 'cp'), (r'^pushm', 'push'),
    (r'^pushw', 'push'), (r'^popw', 'pop'), (r'^popb', 'pop'), (r'^push', 'push'),
    (r'^pop', 'pop'), (r'^bitm', 'bit'), (r'^chgm', 'chg'), (r'^tsetm', 'tset'),
    (r'^bit', 'bit'), (r'^set', 'set'), (r'^res', 'res'), (r'^chg', 'chg'),
    (r'^tset', 'tset'), (r'^inc', 'inc'), (r'^dec', 'dec'),
    (r'^add[ci]?', 'add'), (r'^adc', 'adc'), (r'^sub', 'sub'), (r'^sbc', 'sbc'),
    (r'^and', 'and'), (r'^xor', 'xor'), (r'^or', 'or'),
    (r'^mul8rr|^mul', 'mul'), (r'^div8rr|^div', 'div'),
]


def family(m):
    m = m.lower()
    if m in BASE:
        return m
    # size-suffixed real forms: ldw, pushw, cpw, addw, incw, ...
    if m[:-1] in BASE and m[-1] in "bwl":
        return m[:-1]
    for pat, fam in FAMILY:
        if re.match(pat, m):
            # adc must not be caught by add's rule
            if fam == 'add' and m.startswith('adc'):
                return 'adc'
            return fam
    return '?' + m


def regs_of(mnem, ops):
    toks = [t.lower() for t in re.findall(r'[A-Za-z][A-Za-z0-9]*', ops)]
    fam = family(mnem)
    if fam in CC_MNEM and toks and toks[0] in CC:
        toks = toks[1:]
    return sorted(t for t in toks if t in REGS)


def split_text(text):
    text = text.strip()
    if not text:
        return "", ""
    parts = text.split(None, 1)
    return parts[0], (parts[1] if len(parts) > 1 else "")


def classify(llvm_len, llvm_text, mame_len, mame_text):
    """Pure function: the whole verdict rule, testable without either decoder."""
    lm, lo = split_text(llvm_text or "")
    mm, mo = split_text(mame_text or "")
    llvm_ok = llvm_len is not None and llvm_text and not llvm_text.startswith("<unknown>")
    mame_ok = mame_len is not None and mm.lower() != "db"
    if not llvm_ok and not mame_ok:
        return "BOTH_REFUSE"
    if not llvm_ok:
        return "MAME_ONLY"
    if not mame_ok:
        return "LLVM_ONLY"
    if llvm_len != mame_len:
        return "LEN_DIFF"
    fl, fm = family(lm), family(mm)
    if fl != fm:
        return "MNEM_DIFF"
    if regs_of(lm, lo) != regs_of(mm, mo):
        return "REG_DIFF"
    return "AGREE"


def probes():
    """-> list of (group, bytes)."""
    out = []
    def row(group, head):
        for s in range(256):
            out.append((group, bytes(head + [s] + TAIL)))
    # register-indirect: src 80/90/A0 (+r), d8 88/98/A8, dst B0/B8
    for base, grp in ((0x80, "80+r"), (0x90, "90+r"), (0xA0, "A0+r"), (0xB0, "B0+r")):
        row(grp, [base + 1])
        row(grp.replace("0+r", "8+r:d8"), [base + 8 + 1, 0x05])
    for hi, grp in ((0xC0, "C"), (0xD0, "D"), (0xE0, "E"), (0xF0, "F")):
        row(grp + "0:a8", [hi + 0, 0x1E])
        row(grp + "1:a16", [hi + 1, 0x1E, 0x23])
        row(grp + "2:a24", [hi + 2, 0x1E, 0x23, 0x00])
        row(grp + "3:d16", [hi + 3, 0xE5, 0x34, 0x12])
        row(grp + "4:-r", [hi + 4, 0xE8 + (0 if hi in (0xC0, 0xF0) else 1 if hi == 0xD0 else 2)])
        row(grp + "5:r+", [hi + 5, 0xE8 + (0 if hi in (0xC0, 0xF0) else 1 if hi == 0xD0 else 2)])
    row("C8+r", [0xC9])
    row("D8+r", [0xD9])
    row("E8+r", [0xE9])
    row("C7:erp", [0xC7, 0xE4])
    row("D7:erp", [0xD7, 0xE4])
    row("E7:erp", [0xE7, 0xE4])
    for op in range(256):
        out.append(("primary", bytes([op] + TAIL)))
    return out


def llvm_decode(blobs):
    res = [None] * len(blobs)
    for start in range(0, len(blobs), CHUNK):
        part = blobs[start:start + CHUNK]
        src = []
        for i, b in enumerate(part):
            src.append('.section .p%d,"ax"' % i)
            src.append(".byte " + ",".join(str(x) for x in b))
        with tempfile.TemporaryDirectory() as td:
            s, o = os.path.join(td, "b.s"), os.path.join(td, "b.o")
            open(s, "w").write("\n".join(src) + "\n")
            subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                           check=True, capture_output=True)
            r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", o],
                               capture_output=True, text=True)
        cur = None
        for line in r.stdout.splitlines():
            if line.startswith("Disassembly of section .p"):
                cur = int(line[len("Disassembly of section .p"):].rstrip(":"))
                continue
            m = OBJDUMP_RE.match(line)
            if cur is not None and m and int(m.group(1), 16) == 0 and res[start + cur] is None:
                res[start + cur] = (len(m.group(2).split()), m.group(3).strip().replace("\t", " "))
    return res


def llvm_encode(texts):
    res = [None] * len(texts)
    for start in range(0, len(texts), CHUNK):
        part = texts[start:start + CHUNK]
        src = []
        for i, t in enumerate(part):
            src.append('.section .q%d,"ax"' % i)
            src.append("\t" + (t or "nop"))
        with tempfile.TemporaryDirectory() as td:
            s = os.path.join(td, "a.s")
            open(s, "w").write("\n".join(src) + "\n")
            r = subprocess.run([MC, "-triple=tlcs900", "--show-encoding", s],
                               capture_output=True, text=True)
        cur = None
        for line in r.stdout.splitlines():
            st = line.strip()
            if st.startswith(".section\t.q") or st.startswith(".section .q"):
                cur = int(st.split(".q")[1].split(",")[0])
                continue
            m = ENC_RE.match(line)
            if m and cur is not None and res[start + cur] is None:
                raw = [x.strip() for x in m.group(2).split(",") if x.strip()]
                try:
                    res[start + cur] = bytes(int(x, 16) for x in raw)
                except ValueError:
                    res[start + cur] = b"<fixup>"
    return res


def mame_decode(blobs):
    res = [None] * len(blobs)
    img = bytearray()
    for b in blobs:
        img += b + bytes(SLOT - len(b))
    with tempfile.TemporaryDirectory() as td:
        f = os.path.join(td, "u.bin")
        open(f, "wb").write(img)
        r = subprocess.run([UNIDASM, f, "-arch", "tlcs900", "-basepc", "0"],
                           capture_output=True, text=True)
    for line in r.stdout.splitlines():
        m = UNI_RE.match(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        if addr % SLOT == 0 and addr // SLOT < len(blobs):
            res[addr // SLOT] = (len(m.group(2).split()), m.group(3).strip())
    return res


def toolchain():
    h = hashlib.sha256(open(MC, "rb").read()).hexdigest()[:12]
    g = subprocess.run(["git", "-C", os.path.join(PROJECTS, "llvm-project"), "log",
                        "-1", "--format=%h"], capture_output=True, text=True).stdout.strip()
    d = subprocess.run(["git", "-C", os.path.join(PROJECTS, "llvm-project"), "status",
                        "--porcelain", "--untracked-files=no"], capture_output=True,
                       text=True).stdout.strip()
    return "llvm-project HEAD %s%s, llvm-mc sha256 %s" % (g, " (DIRTY)" if d else "", h)


def selftest():
    cases = [
        ((3, "lda xbc, (xwa+:1)", 3, "lda XBC,XWA+"), "AGREE"),
        ((3, "stb_dpi a, 224", 3, "lda XBC,XWA+"), "MNEM_DIFF"),
        ((4, "cpda8 xbc, (8990)", 4, "cp A,(0x231e)"), "REG_DIFF"),
        ((4, "cp a, (0x231e:16)", 4, "cp A,(0x231e)"), "AGREE"),
        ((2, "mul wa, (xbc)", 2, "mul XWA,(XBC)"), "REG_DIFF"),
        ((2, "jp (xwa)", 2, "jp T,XWA"), "AGREE"),
        ((2, "ret c", 2, "ret C"), "AGREE"),
        ((None, "<unknown>", 2, "ld A,(XDE+)"), "MAME_ONLY"),
        ((2, "nop", 2, "db"), "LLVM_ONLY"),
        ((3, "ld a, (xde)", 2, "ld A,(XDE)"), "LEN_DIFF"),
        ((2, "pushm (xwa)", 2, "pushw (XWA)"), "AGREE"),
        ((2, "ei 7", 2, "ei 0x07"), "AGREE"),
    ]
    bad = 0
    for args, want in cases:
        got = classify(*args)
        if got != want:
            bad += 1
            print("SELFTEST FAIL", args, "want", want, "got", got)
    print("selftest: %d/%d" % (len(cases) - bad, len(cases)))
    return bad == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", help="directory for the per-probe TSV")
    ap.add_argument("--show", default="REG_DIFF,MNEM_DIFF,LEN_DIFF,ASYM",
                    help="classes to list examples of")
    ap.add_argument("--limit", type=int, default=400)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(0 if selftest() else 1)
    print("toolchain:", toolchain())
    pr = probes()
    blobs = [b for _, b in pr]
    ld = llvm_decode(blobs)
    md = mame_decode(blobs)
    texts = [(x[1] if x else None) for x in ld]
    re_enc = llvm_encode([t if t and not t.startswith("<unknown>") else "nop" for t in texts])
    counts = collections.Counter()
    rows = []
    for (grp, b), l, m, e in zip(pr, ld, md, re_enc):
        v = classify(l[0] if l else None, l[1] if l else None,
                     m[0] if m else None, m[1] if m else None)
        asym = ""
        if l and not l[1].startswith("<unknown>") and e is not None and e != b"<fixup>":
            if e != b[:l[0]]:
                asym = "ASYM"
        counts[v] += 1
        if asym:
            counts["ASYM"] += 1
        rows.append((grp, b, l, m, v, asym))
    print("probes: %d" % len(pr))
    for k in ("AGREE", "REG_DIFF", "MNEM_DIFF", "LEN_DIFF", "LLVM_ONLY", "MAME_ONLY",
              "BOTH_REFUSE", "ASYM"):
        print("  %-12s %6d" % (k, counts[k]))
    show = set(a.show.split(","))
    shown = 0
    for grp, b, l, m, v, asym in rows:
        if (v in show or (asym and "ASYM" in show)) and shown < a.limit:
            shown += 1
            n = l[0] if l else (m[0] if m else len(b))
            print("%-9s %-10s %-16s | llvm: %-34s | mame: %s" % (
                v, asym + ("" if not asym else ""), b[:max(n, 1)].hex(" "), l[1] if l else "-",
                m[1] if m else "-") + ("  [" + grp + "]"))
    if a.out:
        os.makedirs(a.out, exist_ok=True)
        with open(os.path.join(a.out, "two_decoder_sweep.tsv"), "w") as f:
            f.write("group\tbytes\tllvm_len\tllvm_text\tmame_len\tmame_text\tclass\tasym\n")
            for grp, b, l, m, v, asym in rows:
                f.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (
                    grp, b.hex(" "), l[0] if l else "", l[1] if l else "",
                    m[0] if m else "", m[1] if m else "", v, asym))


if __name__ == "__main__":
    main()
