#!/usr/bin/env python3
r"""wave3a_respell.py -- respell source lines whose TEXT the toolchain lane found
to be false, to the spelling that says what the CPU does, keeping every byte.

QUESTION / JOB
--------------
The TLCS-900 backend accepted (and printed) spellings that assemble to the
right bytes but name the wrong instruction or register
(TOOLCHAIN_VERSION UPDATE 17).  This tool rewrites each family, site by site:

  muldiv    MUL/MULS/DIV/DIVS register-register and memory forms name the
            RESULT register the CPU writes (MAME's reading):
              div xwa, xbc      ->  div xwa, bc        (d9 50: XWA <- XWA/BC)
              mul8rr c, h       ->  mul bc, h          (ce 43: BC <- C*H)
              mul a, (xbc)      ->  mul wa, (xbc)      (81 41: WA <- A*(XBC))
              mul wa, (xbc)     ->  mul xwa, (xbc)     (91 40: XWA <- WA*(XBC))
              mul de, qiz       ->  mul xde, qiz       (d7 fa 42)
            The immediate forms (`mul wa, 5`) are NOT touched: MAME prints
            them with the prefix register, as the backend does.
            ⚠ LOCKSTEP: under the new backend `mul wa, (xbc)` names the BYTE
            multiply (81 41), not the word one it used to mean (91 40), so an
            unconverted site changes bytes.  Convert with the NEW assembler
            in hand and gate immediately.

  autoinc   the post-increment / pre-decrement pseudo-instructions
            (`ldb_spi a, 232`, `stw_dpi bc, 225` ...) become the real
            instruction with a `(R+)` / `(-R)` operand.  Two of them were the
            WRONG instruction: `stb_dpi r8, B` is LDA r32 (F5 0x30+r) and
            `lda_dpi r32, B` is LD (mem),r8 (F5 0x40+r); both are rewritten to
            what the bytes are.  Comments that seqeng_annotate_swapped_dpi.py
            appended to explain the swap (`; = ... (backend mnemonic is
            swapped)` / `; = ... (unidasm)`) are removed from the lines this
            rewrites -- the instruction now says it.

  disp256   `(xrr+256)` -- the retired sentinel for "(Xrr+d8) carrying 0" --
            becomes `(xrr+0:8)`.  The value is matched, not the text
            (256, 0x100, 0x0100).

VERIFICATION (every site, before anything is written)
  The old line is assembled alone by the OLD assembler (--old-mc, default the
  pinned snapshot) and the new line by the NEW one (--new-mc, default the
  shared build); the two encodings must be identical.  Symbols in operands
  are defined to a fixed constant for both.  A site that cannot be assembled
  standalone (macro parameter) is listed and left alone.  Then `make
  gate-all` must be 13/13 -- the tool does not replace the gate.

RUN (from the tree root)
    python3 scripts/converters/wave3a_respell.py muldiv            # report
    python3 scripts/converters/wave3a_respell.py muldiv --apply    # write
    python3 scripts/converters/wave3a_respell.py autoinc --apply
    python3 scripts/converters/wave3a_respell.py disp256 --apply
Sources are read and written as latin-1 bytes (notes/lanes/BRIEF-2026-09-01.md).
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
PROJ = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
OLD_MC = os.path.join(PROJ, "toolchain-snapshot", "llvm-mc.snap")
NEW_MC = os.path.join(PROJ, "llvm-project", "build", "bin", "llvm-mc")

R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
PAIR8 = {"a": "wa", "c": "bc", "e": "de", "l": "hl"}   # low byte -> pair
LAB = r'(?:[A-Za-z_.$][\w.$@]*:[ \t]*)?'
LINE = re.compile(r'^([ \t]*' + LAB + r'[ \t]*)([a-z][a-z0-9_]*)([ \t]+)([^;]*?)([ \t]*)(;.*)?$',
                  re.I)


def split_ops(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    out.append(cur.strip())
    return out


def join_ops(ops, sep=", "):
    return sep.join(ops)


# ------------------------------------------------------------------ muldiv
MD = {"mul", "muls", "div", "divs"}
MD8RR = {"mul8rr": "mul", "muls8rr": "muls", "div8rr": "div", "divs8rr": "divs"}


def rw_muldiv(mn, ops):
    """-> (new mnemonic, new operand list) or None (not this family / keep)."""
    m = mn.lower()
    if m in MD8RR:
        if len(ops) != 2 or ops[0].lower() not in PAIR8 or ops[1].lower() not in R8:
            return "REFUSE:rr8-operands"
        return MD8RR[m], [PAIR8[ops[0].lower()], ops[1]]
    if m not in MD or len(ops) != 2:
        return None
    a, b = ops[0].lower(), ops[1]
    bl = b.lower()
    if a in R32 and bl in R32:                       # rr16
        return mn, [ops[0], R16[R32.index(bl)]]
    if b.startswith("("):                            # memory
        if a in R8:
            if a not in PAIR8:
                return "REFUSE:m8-even-register"
            return mn, [PAIR8[a], b]
        if a in R16:
            return mn, [R32[R16.index(a)], b]
        return None
    if a in R16 and re.fullmatch(r'q[a-z]{2}', bl):  # previous-bank / high word
        return mn, [R32[R16.index(a)], b]
    return None                                      # immediate forms: keep


# ------------------------------------------------------------------ autoinc
def regbyte_name(v):
    """Register-file byte -> (name, step) or None."""
    if v & 3 == 3:
        return None
    a = v & 0xFC
    if a >= 0xE0:
        return R32[(a - 0xE0) >> 2], 1 << (v & 3)
    if a < 0x40:
        return ["xwa", "xbc", "xde", "xhl"][(a >> 2) & 3] + str(a >> 4), 1 << (v & 3)
    return None


def pi_operand(v, pre, natural):
    r = regbyte_name(v)
    if r is None:
        return None
    name, step = r
    body = ("-" + name) if pre else (name + "+")
    if natural == 0 or step != natural:
        body += ":%d" % step
    return "(" + body + ")"


SIZE = {"b": 1, "w": 2, "l": 4}
# pseudo -> (real mnemonic, kind, data size, pre?)
#   kind: rm = `op reg, (R+)`   mr = `op (R+), reg`   st = `ld (R+), reg`
#         im8/im16 = `op (R+), imm`   incdec   push   pop
AUTOINC = {}
for op in ("add", "adc", "sub", "sbc", "and", "xor", "or", "cp"):
    AUTOINC[op + "_spib"] = (op, "rm", 1, False)
    AUTOINC[op + "_spiw"] = (op, "rm", 2, False)
    AUTOINC[op + "_spil"] = (op, "rm", 4, False)
    AUTOINC[op + "_spib_mr"] = (op, "mr", 1, False)
    AUTOINC[op + "_spiw_mr"] = (op, "mr", 2, False)
    AUTOINC[op + "_spil_mr"] = (op, "mr", 4, False)
    AUTOINC[op + "_spib_im"] = (op, "im8", 1, False)
    AUTOINC[op + "_spiw_im"] = (op + "w", "im16", 2, False)
    AUTOINC[op + "_spdb"] = (op, "rm", 1, True)
    AUTOINC[op + "_spdw"] = (op, "rm", 2, True)
    AUTOINC[op + "_spdb_mr"] = (op, "mr", 1, True)
    AUTOINC[op + "_spdb_im"] = (op, "im8", 1, True)
AUTOINC.pop("or_spib")
AUTOINC.update({
    "or_spib_rm": ("or", "rm", 1, False),
    "cpm_spiw": ("cp", "mr", 2, False),
    "ldb_spi": ("ld", "rm", 1, False), "ld_spiw": ("ld", "rm", 2, False),
    "ld_spil": ("ld", "rm", 4, False),
    "ld_spdb": ("ld", "rm", 1, True), "ld_spdw": ("ld", "rm", 2, True),
    "ld_spdl": ("ld", "rm", 4, True),
    "inc_spib": ("inc", "incdec", 1, False), "dec_spib": ("dec", "incdec", 1, False),
    "inc_spiw": ("incw", "incdec", 2, False), "dec_spiw": ("decw", "incdec", 2, False),
    "inc_spdb": ("inc", "incdec", 1, True), "dec_spdb": ("dec", "incdec", 1, True),
    "push_spib": ("push", "push", 1, False), "push_spiw": ("pushw", "push", 2, False),
    "push_spdb": ("push", "push", 1, True),
    # destination table
    "stw_dpi": ("ld", "st", 2, False), "stl_dpi": ("ld", "st", 4, False),
    "st_dpdw": ("ld", "st", 2, True), "st_dpdl": ("ld", "st", 4, True),
    "popb_dpi": ("pop", "pop", 1, False), "popw_dpi": ("popw", "pop", 2, False),
    "popb_dpd": ("pop", "pop", 1, True), "popw_dpd": ("popw", "pop", 2, True),
    "stib_dpi": ("ld", "im8", 1, False), "stib_dpd": ("ld", "im8", 1, True),
    "stiw_dpi": ("ldw", "im16", 2, False),
    # ⚠ the SWAPPED pair: the name says store/lda, the bytes say lda/store
    "stb_dpi": ("lda", "swap_lda", 0, False), "st_dpdb": ("lda", "swap_lda", 0, True),
    "lda_dpi": ("ld", "swap_st", 1, False), "lda_dpd": ("ld", "swap_st", 1, True),
})
ANNOT = re.compile(r'[ \t]*; = [^;]*\((?:backend mnemonic is swapped|unidasm)\)[ \t]*$')


def num(s, equs):
    s = s.strip()
    if re.fullmatch(r'-?(0x[0-9a-fA-F]+|\d+)', s):
        return int(s, 0)
    return equs.get(s)


def rw_autoinc(mn, ops, equs):
    spec = AUTOINC.get(mn.lower())
    if not spec:
        return None
    real, kind, size, pre = spec
    if kind in ("rm", "swap_lda", "swap_st", "st"):
        if len(ops) != 2:
            return "REFUSE:operands"
        v = num(ops[1], equs)
        if v is None:
            return "REFUSE:base-not-constant"
        reg = ops[0].lower()
        if kind == "swap_lda":                # stb_dpi r8, B  ->  lda r32, (B+:s)
            if reg not in R8:
                return "REFUSE:swap-reg"
            op = pi_operand(v, pre, 0)
            return (real, [R32[R8.index(reg)], op]) if op else "REFUSE:unnamed-register-byte"
        if kind == "swap_st":                 # lda_dpi r32, B  ->  ld (B+), r8
            if reg not in R32:
                return "REFUSE:swap-reg"
            op = pi_operand(v, pre, 1)
            return (real, [op, R8[R32.index(reg)]]) if op else "REFUSE:unnamed-register-byte"
        op = pi_operand(v, pre, size)
        if not op:
            return "REFUSE:unnamed-register-byte"
        return (real, [op, ops[0]]) if kind == "st" else (real, [ops[0], op])
    if kind == "mr":
        if len(ops) != 2:
            return "REFUSE:operands"
        v = num(ops[1], equs)
        op = pi_operand(v, pre, size) if v is not None else None
        return (real, [op, ops[0]]) if op else "REFUSE:base"
    if kind == "im8":
        if len(ops) != 2:
            return "REFUSE:operands"
        v = num(ops[0], equs)
        op = pi_operand(v, pre, size) if v is not None else None
        return (real, [op, ops[1]]) if op else "REFUSE:base"
    if kind == "im16":
        if len(ops) != 3:
            return "REFUSE:operands"
        v, lo, hi = num(ops[0], equs), num(ops[1], equs), num(ops[2], equs)
        if v is None or lo is None or hi is None:
            return "REFUSE:not-constant"
        op = pi_operand(v, pre, size)
        return (real, [op, "0x%04x" % (((hi & 0xFF) << 8) | (lo & 0xFF))]) if op else "REFUSE:base"
    if kind == "incdec":
        if len(ops) != 2:
            return "REFUSE:operands"
        cnt, v = num(ops[0], equs), num(ops[1], equs)
        op = pi_operand(v, pre, size) if v is not None else None
        if op is None or cnt is None:
            return "REFUSE:base"
        return real, [str(8 if (cnt & 7) == 0 else cnt & 7), op]
    if kind in ("push", "pop"):
        if len(ops) != 1:
            return "REFUSE:operands"
        v = num(ops[0], equs)
        op = pi_operand(v, pre, size) if v is not None else None
        return (real, [op]) if op else "REFUSE:base"
    return None


# ------------------------------------------------------------------ disp256
D256 = re.compile(r'(\(\s*x(?:wa|bc|de|hl|ix|iy|iz|sp)\s*\+\s*)(0x0*100|256)(\s*\))', re.I)


# ------------------------------------------------------------------ driver
def sources():
    out = subprocess.run(["git", "ls-files", "-z", "*.s", "*.inc", "*.S"], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\0") if p and not p.startswith("archive/")]


def collect_equs(files):
    """Numeric .equ/.set constants a pseudo's base operand may name
    (wsa1's MEM_XIX_PI2 = 0xF1 ...)."""
    eq = {}
    rx = re.compile(r'^\s*\.(?:equ|set)\s+([A-Za-z_][\w.]*)\s*,\s*(-?(?:0x[0-9a-fA-F]+|\d+))\s*(?:;.*)?$')
    for f in files:
        for line in open(os.path.join(ROOT, f), encoding="latin-1"):
            m = rx.match(line)
            if m:
                eq.setdefault(m.group(1), int(m.group(2), 0))
    return eq


def rewrite_line(fam, line, equs):
    """-> (new_line, reason) ; new_line None = no change."""
    if fam == "disp256":
        code, sep, com = line.partition(";")
        if not D256.search(code):
            return None, None
        return D256.sub(lambda m: m.group(1) + "0:8" + m.group(3), code) + sep + com, "ok"
    m = LINE.match(line)
    if not m:
        return None, None
    head, mn, ws, ops, ws2, com = m.groups()
    if "\\" in ops:
        r = rw_muldiv(mn, split_ops(ops)) if fam == "muldiv" else rw_autoinc(mn, split_ops(ops), equs)
        return (None, "REFUSE:macro-parameter") if r else (None, None)
    r = rw_muldiv(mn, split_ops(ops)) if fam == "muldiv" else rw_autoinc(mn, split_ops(ops), equs)
    if r is None:
        return None, None
    if isinstance(r, str):
        return None, r
    nm, nops = r
    com = com or ""
    if fam == "autoinc" and com:
        com = ANNOT.sub("", com).rstrip()
        if com.strip() == ";":
            com = ""
    new = head + nm + ws + join_ops(nops) + (ws2 if com else "") + com
    return new.rstrip() if not com else new, "ok"


SYM = re.compile(r'\b([A-Za-z_][\w.]*)\b')
KEEP = set(R32 + R16 + R8 + ["qwa", "qbc", "qde", "qhl", "qix", "qiy", "qiz", "qsp"] +
           ["xwa0", "xbc0", "xde0", "xhl0", "xwa1", "xbc1", "xde1", "xhl1", "xwa2",
            "xbc2", "xde2", "xhl2", "xwa3", "xbc3", "xde3", "xhl3"])


def assemble(mc, lines, equs=None):
    """Each line alone; a symbol is defined to its tree-wide .equ value when it
    has one (so an old line naming MEM_XIX_PI2 and a new line spelling its
    value agree), else to 0x1234 for BOTH spellings.  -> list of hex|None."""
    equs = equs or {}
    src = []
    for i, l in enumerate(lines):
        code = l.split(";")[0]
        code = re.sub(r'^\s*' + LAB, '\t', code)
        m = re.match(r'\s*([a-z0-9_]+)\s+(.*)$', code, re.I)
        syms = set()
        if m:
            for s in SYM.findall(m.group(2)):
                if s.lower() not in KEEP and not re.fullmatch(r'0x[0-9a-fA-F]+', s):
                    syms.add(s)
        src.append(".section .t%d,\"ax\"" % i)
        for s in sorted(syms):
            src.append("\t.set %s, %s" % (s, hex(equs[s]) if s in equs else "0x1234"))
        src.append(code)
    with tempfile.TemporaryDirectory() as td:
        p = os.path.join(td, "a.s")
        open(p, "w", encoding="latin-1").write("\n".join(src) + "\n")
        r = subprocess.run([mc, "-triple=tlcs900", "-show-encoding", p],
                           capture_output=True, text=True, errors="replace")
    bad = set()
    for e in re.finditer(r':(\d+):\d+: error', r.stderr):
        bad.add(int(e.group(1)))
    out, cur, curline = [None] * len(lines), None, 0
    # map source line numbers to sections
    secline = {}
    ln = 0
    for i, s in enumerate(src):
        if s.startswith(".section .t"):
            cur = int(s[len(".section .t"):].split(",")[0])
        secline[i + 1] = cur
    errs = {secline.get(b) for b in bad}
    cur = None
    for line in r.stdout.splitlines():
        st = line.strip()
        if st.startswith(".section\t.t") or st.startswith(".section .t"):
            cur = int(st.split(".t", 1)[1].split(",")[0])
            continue
        m = re.search(r'encoding: \[([^\]]*)\]', line)
        if m and cur is not None and cur not in errs:
            out[cur] = (out[cur] or "") + m.group(1)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("family", choices=("muldiv", "autoinc", "disp256"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--old-mc", default=OLD_MC)
    ap.add_argument("--new-mc", default=NEW_MC)
    ap.add_argument("--show", type=int, default=12)
    a = ap.parse_args()
    for label, mc in (("old", a.old_mc), ("new", a.new_mc)):
        print("%s llvm-mc %s sha256 %s" % (label, mc,
              hashlib.sha256(open(mc, "rb").read()).hexdigest()[:12]))
    files = sources()
    equs = collect_equs(files) if a.family == "autoinc" else {}
    sites, refused = [], collections.Counter()
    refused_ex = collections.defaultdict(list)
    for f in files:
        L = open(os.path.join(ROOT, f), encoding="latin-1").read().split("\n")
        for i, line in enumerate(L):
            new, why = rewrite_line(a.family, line, equs)
            if why and why.startswith("REFUSE"):
                refused[why] += 1
                refused_ex[why].append("%s:%d: %s" % (f, i + 1, line.strip()))
            elif new is not None and new != line:
                sites.append((f, i, line, new))
    print("candidate sites: %d; refused before assembly: %d" % (len(sites), sum(refused.values())))
    eo = assemble(a.old_mc, [s[2] for s in sites], equs)
    en = assemble(a.new_mc, [s[3] for s in sites], equs)
    ok, bad = [], []
    for s, o, n in zip(sites, eo, en):
        (ok if (o is not None and o == n) else bad).append((s, o, n))
    print("verified identical: %d   mismatched/unassemblable: %d" % (len(ok), len(bad)))
    for why, n in refused.most_common():
        print("  refused %-32s %d" % (why, n))
        for ex in refused_ex[why][:3]:
            print("      " + ex[:150])
    for (f, i, old, new), o, n in bad[:40]:
        print("  MISMATCH %s:%d\n     old %-50s %s\n     new %-50s %s" % (
            f, i + 1, old.strip()[:50], o, new.strip()[:50], n))
    per = collections.Counter(s[0] for (s, _, _) in ok)
    shown = 0
    for (f, i, old, new), o, n in ok:
        if shown < a.show:
            print("  %s:%d\n     - %s\n     + %s   [%s]" % (f, i + 1, old.strip(), new.strip(), o))
            shown += 1
    print("files: %d" % len(per))
    if bad:
        print("REFUSING to write: %d site(s) did not verify" % len(bad))
        sys.exit(1)
    if a.apply:
        byf = collections.defaultdict(list)
        for (f, i, old, new), _, _ in ok:
            byf[f].append((i, old, new))
        for f, ed in byf.items():
            p = os.path.join(ROOT, f)
            raw = open(p, "rb").read().decode("latin-1").split("\n")
            for i, old, new in ed:
                assert raw[i] == old, (f, i)
                raw[i] = new
            open(p, "wb").write("\n".join(raw).encode("latin-1"))
        print("wrote %d lines in %d files" % (len(ok), len(byf)))
        for f in sorted(byf):
            print("  M %s" % f)


if __name__ == "__main__":
    main()
