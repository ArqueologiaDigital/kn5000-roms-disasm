#!/usr/bin/env python3
r"""RE-SPELL BACKEND PSEUDO-MNEMONICS AS THE INSTRUCTION MAME's unidasm READS.

QUESTION / JOB
--------------
This backend's disassembler prints many instructions under internal pseudo
names -- `lda_dri XWA, 0xfd, 0x2e, 0x01`, `ldiw_erp 0xe2, 0`, `cpdi8 (49277), 2`,
`addiw_da (xsp+12), 37` -- and in at least one family it prints the WRONG
register: `c1 7f c0 c1` (and A,(0xc07f)) comes out as `andda8 xbc, (49279)`,
because the 8-bit register code 1 (A) is printed through the 32-bit table
(XBC).  The bytes are right; the text misleads.  Its PARSER, however, accepts
the plain forms: `lda xwa, (xsp+302)`, `ld qwa, 0`, `cp (0xc07d:16), 2`,
`addw (xsp+12), 37`, `and a, (0xc07f:16)`.

For every instruction line of a file whose mnemonic is not a real TLCS-900
mnemonic (a pseudo), this tool takes the line's ROM bytes (address from the
census marker mirror), asks MAME's unidasm -- the independent decoder -- what
they are, converts unidasm's reading to this assembler's syntax (lower case,
absolute operands tagged :8/:16/:24 by the prefix byte, shift counts moved
behind the register, `inc 0` = 8, `lda` operands parenthesised ...), tries the
mnemonic with and without a w/b/l size suffix, and keeps the first candidate
that llvm-mc encodes to EXACTLY the ROM bytes.  So a replacement is a text
that both decoders agree on and the assembler reproduces bit for bit.  Lines
with symbolic operands, post-increment / pre-decrement or register-indexed
operands (no syntax for them) are left alone.  Label prefix and trailing
comment of the line are kept.

--apply rewrites the file (bytes in / bytes out) and re-links the image
through a fresh inert mirror; the edit is kept only if it is byte-identical.

RUN
    python3 scripts/converters/lane_uiproc_respell.py --image v10 --file ui/ui_mode_handlers.s
    python3 scripts/converters/lane_uiproc_respell.py --image v10 --file ... --apply
"""
import argparse
import concurrent.futures as cf
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
sys.path.insert(0, HERE)
import data_range_census as drc  # noqa: E402
import lane_uiproc_listing as L  # noqa: E402
import lane_uiproc_reframe as R  # noqa: E402

REAL = set("""ld ldw ldb lda ldi ldir ldiw ldirw ldd lddr lddw lddrw ldf ldc ldx push pushw pop popw
ex add adc sub sbc cp cpw and or xor inc incw dec decw cpl neg mul muls div divs mula minc1 minc2
minc4 mdec1 mdec2 mdec4 extz exts daa paa rlc rrc rl rr sla sra sll srl rld rrd bit set res chg
tset andcf orcf xorcf ldcf stcf zcf scf rcf ccf nop halt ei di swi reti ret retd call calr jp jr
jrl djnz scc link unlk bs1f bs1b mirr cpi cpir cpd cpdr addw subw andw orw xorw cpb cpl adcw sbcw
rlcw rrcw rlw rrw slaw sraw sllw srlw""".split())
SHIFTS = {"rlc", "rrc", "rl", "rr", "sla", "sra", "sll", "srl"}
REGS = set("""a w b c d e h l wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz xsp qwa qbc qde
qhl qix qiy qiz qw qa qb qc qd qe qh ql ixl ixh iyl iyh izl izh sr f""".split())
LAB = re.compile(r'^(\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?)(.*)$')


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
    if cur.strip():
        out.append(cur.strip())
    return out


def width_tag(first):
    return {0: "8", 1: "16", 2: "24"}.get(first & 0x0F if (first & 0xC0) == 0xC0 else -1)


def candidates(u, bs):
    """unidasm reading -> list of llvm-syntax candidate texts."""
    u = u.strip()
    if not u or "+)" in u or "(-" in u or re.search(r'\([A-Z]+\+[A-Z]+\)', u):
        return []
    p = u.split(None, 1)
    mn = p[0].lower()
    ops = split_ops(p[1]) if len(p) > 1 else []
    tag = width_tag(bs[0])
    out_ops = []
    for o in ops:
        o = o.lower()
        m = re.match(r'^\((0x[0-9a-f]+)\)$', o)
        if m:
            if not tag:
                return []
            o = "(%s:%s)" % (m.group(1), tag)
        m = re.match(r'^\(([a-z]+)([+-])(0x[0-9a-f]+)\)$', o)
        if m:
            o = "(%s%s%d)" % (m.group(1), m.group(2), int(m.group(3), 16))
        out_ops.append(o)
    if mn == "lda" and len(out_ops) == 2:
        s = out_ops[1]
        m = re.match(r'^([a-z]+)\+(0x[0-9a-f]+)$', s)
        if m:
            out_ops[1] = "(%s+%d)" % (m.group(1), int(m.group(2), 16))
        elif re.match(r'^0x[0-9a-f]+$', s) and tag:
            out_ops[1] = "(%s:%s)" % (s, tag)
        elif s in REGS:
            out_ops[1] = "(%s)" % s
    if mn in SHIFTS and len(out_ops) == 2 and re.match(r'^0x[0-9a-f]+$', out_ops[0]):
        n = int(out_ops[0], 16) or 16
        out_ops = [out_ops[1], str(n)]
    if mn in ("inc", "dec", "incw", "decw") and len(out_ops) == 2 and out_ops[0] in ("0", "0x00"):
        out_ops[0] = "8"
    if mn in ("bit", "set", "res", "chg", "tset") and out_ops and re.match(r'^0x[0-9a-f]+$', out_ops[0]):
        out_ops[0] = str(int(out_ops[0], 16))
    # immediates in hex -> keep hex, small -> decimal
    fixed = []
    for o in out_ops:
        m = re.match(r'^0x([0-9a-f]+)$', o)
        if m:
            v = int(m.group(1), 16)
            o = str(v) if v < 10 else "0x%x" % v
        fixed.append(o)
    out_ops = fixed
    body = ", ".join(out_ops)
    res = []
    for m2 in (mn, mn + "w", mn + "b", mn + "l"):
        res.append((m2 + " " + body).strip())
    # signed 8-bit displacement variant
    alt = []
    for c in res:
        m = re.search(r'\(([a-z]+)\+(\d+)\)', c)
        if m and 128 <= int(m.group(2)) < 256:
            alt.append(c.replace(m.group(0), "(%s-%d)" % (m.group(1), 256 - int(m.group(2)))))
    return res + alt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", type=int, default=25)
    a = ap.parse_args()
    img = L.image(a.image)
    srcroot = os.path.join(ROOT, img["mirror"])
    path = os.path.join(srcroot, a.file)
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    amap, rom, syms = L.build(img)
    emit = sorted((ad, int(k.rsplit(":", 1)[1])) for k, ad in amap.items()
                  if k.rsplit(":", 1)[0] == a.file)
    size = {}
    for i, (ad, li) in enumerate(emit):
        if i + 1 < len(emit):
            size[li] = emit[i + 1][0] - ad
    in_macro = False
    todo = []
    for li, l in enumerate(lines):
        c = drc.strip_comment(l).strip()
        if re.match(r'^\.macro\b', c):
            in_macro = True
        if re.match(r'^\.endm\b', c):
            in_macro = False
            continue
        if in_macro or li not in size or size[li] <= 0:
            continue
        m = LAB.match(drc.strip_comment(l))
        ins = m.group(2).strip()
        if not ins or ins.startswith("."):
            continue
        mn = ins.split()[0].lower()
        if mn in REAL:
            continue
        opers = ins[len(mn):]
        idents = re.findall(r'[A-Za-z_][\w]*', opers)
        if any(x.lower() not in REGS for x in idents):
            continue            # symbolic operand: leave alone
        todo.append(li)
    addr = {li: ad for ad, li in emit}
    off = lambda x: x - img["base"]

    def work(li):
        ad = addr[li]
        bs = rom[off(ad):off(ad) + size[li]]
        dec = R.unidasm_linear(rom, img, ad, ad + size[li])
        if len(dec) != 1 or dec[0][1] != size[li]:
            return li, None, "unidasm frames it differently"
        for cnd in candidates(dec[0][2], bs):
            if R.encode(cnd) == list(bs):
                return li, cnd, dec[0][2]
        return li, None, dec[0][2]
    with cf.ThreadPoolExecutor(8) as ex:
        results = list(ex.map(work, todo))
    done = [(li, c, u) for li, c, u in results if c]
    left = [(li, u) for li, c, u in results if not c]
    print("%s %s: %d pseudo-mnemonic lines, %d re-spelt, %d left" % (
        a.image, a.file, len(todo), len(done), len(left)))
    for li, c, u in done[:a.show]:
        print("  %6d  %-40s -> %-32s (unidasm: %s)" % (
            li + 1, drc.strip_comment(lines[li]).strip()[:40], c, u))
    from collections import Counter
    cnt = Counter(drc.strip_comment(lines[li]).strip().split()[0] for li, u in left)
    print("  left, by mnemonic:", dict(cnt.most_common(20)))
    if not a.apply:
        return
    new = list(lines)
    for li, c, u in done:
        l = lines[li]
        code = drc.strip_comment(l)
        comment = l[len(code):]
        m = LAB.match(code)
        pre = m.group(1)
        p = c.split(None, 1)
        txt = "\t" + p[0] + ("\t" + p[1] if len(p) > 1 else "")
        if pre.strip():
            txt = pre.rstrip() + txt
        new[li] = txt + (("\t" + comment.strip()) if comment.strip() else "")
    open(path, "wb").write("\n".join(new).encode("latin-1"))
    try:
        L.build(img)
    except SystemExit:
        open(path, "wb").write(raw)
        raise
    print("APPLIED %d re-spellings; image byte-identical" % len(done))


if __name__ == "__main__":
    main()
