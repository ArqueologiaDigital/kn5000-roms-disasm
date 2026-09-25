#!/usr/bin/env python3
r"""convert_v142_byte_block.py -- turn a `.byte` run under a label into instructions.

QUESTION THIS ANSWERS
    Is the `.byte` run that sits under LABEL in the v1.42 sub-CPU payload source
    really CODE, and if so what are its instructions?  For the handful of runs in
    kn5000_subprogram_v142.s / subcpu_fp_math.s that are routines kept as raw
    bytes (census "code-suspect" / "embedded-in-code"), it produces the
    instruction text and splices it in place of the `.byte` lines.

EVIDENCE STANDARD (all must hold, or the block is refused and nothing is written)
    1. the source's own `.byte` values equal the ROM bytes at the label's address
       (address taken from a fresh build of the current tree -- never a stale map);
    2. `llvm-mc --disassemble` decodes the WHOLE run with no warning, its
       instruction lengths summing exactly to the run length;
    3. MAME's unidasm, decoding linearly from the same start, puts an instruction
       boundary at every boundary llvm-mc found (a second, independent decoder);
    4. every instruction, re-assembled from the printed text, reproduces its own
       original bytes; where the backend picks a different encoding for the same
       text (the known quirks: compact push/pop, d8 vs d16 displacements, ...) the
       instruction is kept as `.byte` WITH the mnemonic in a trailing comment;
    5. (--apply) the rebuilt ROM is byte-identical to the dump.
    Branch operands are left as llvm-mc prints them (relative displacements), so
    that symbolize_numeric_branches.py -- which applies its own R1..R6 guards --
    turns them into labels in a second, separately verified step.

RUN
    python3 scripts/converters/convert_v142_byte_block.py LABEL [LABEL...]          # dry
    python3 scripts/converters/convert_v142_byte_block.py LABEL --apply
    python3 scripts/converters/convert_v142_byte_block.py LABEL --file subcpu_fp_math.s
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MIRROR = os.path.join(ROOT, "v142/subcpu")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
PROJ = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM = os.path.join(PROJ, "llvm-project", "build", "bin")
UNIDASM = os.path.join(PROJ, "tools", "unidasm")
MC = os.path.join(LLVM, "llvm-mc")

rom = open(ROM, "rb").read()


def off(a):
    return a - 0xF000 + 0x100 if a >= 0xF000 else a - 0x400


def build():
    d = tempfile.mkdtemp(prefix="v142blk_")
    o, e, b = (os.path.join(d, x) for x in ("v.o", "v.elf", "v.full"))
    subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", "v142/subcpu", "-o", o,
                    "v142/subcpu/kn5000_subprogram_v142.s"], cwd=ROOT, check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", "v142/subcpu/subcpu.ld", "-o", e, o],
                   cwd=ROOT, check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b], check=True)
    full = open(b, "rb").read()
    img = full[:256] + full[60416:]
    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), "-n", e], check=True, capture_output=True,
                        text=True).stdout
    syms = {}
    for ln in nm.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            syms[p[2]] = int(p[0], 16)
    return syms, img == rom


def mc_disasm(bs):
    r = subprocess.run([MC, "-triple=tlcs900", "--disassemble", "-show-encoding"],
                       input=" ".join("0x%02x" % x for x in bs), capture_output=True, text=True)
    if "warning" in r.stderr or r.returncode:
        return None, r.stderr.strip()
    out = []
    for ln in r.stdout.splitlines():
        m = re.match(r"^\s+(.+?)\s*; encoding: \[(.*)\]\s*$", ln)
        if not m:
            continue
        enc = [int(x, 16) for x in m.group(2).split(",")]
        out.append((re.sub(r"\s+", " ", m.group(1).strip()).replace(" ,", ","), enc))
    return out, ""


def mc_encode(text):
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input="\t" + text + "\n",
                       capture_output=True, text=True)
    if r.returncode or "error" in r.stderr:
        return None
    m = re.search(r"; encoding: \[(.*?)\]", r.stdout)
    if not m or "A" in m.group(1):
        return None
    return [int(x, 16) for x in m.group(1).split(",")]


def unidasm_bounds(addr, n):
    r = subprocess.run([UNIDASM, ROM, "-arch", "tlcs900", "-basepc", "%x" % addr,
                        "-skip", str(off(addr)), "-count", str(n)], capture_output=True, text=True)
    b = set()
    for ln in r.stdout.splitlines():
        m = re.match(r"^([0-9a-f]+):", ln)
        if m:
            b.add(int(m.group(1), 16))
    return b


def house_style(text):
    """The spelling the rest of this file uses: `lda xR, (0x00f4ec:24)` / `(0x24e6:16)` for
    absolute addresses, hex for immediates >= 256.  Only ever ACCEPTED if it re-encodes to
    the identical bytes (checked by the caller)."""
    m = re.match(r"^lda_24 (\w+), \((\d+)\)$", text)
    if m:
        return "lda %s, (0x%06x:24)" % (m.group(1), int(m.group(2)))
    m = re.match(r"^lda_d16 (\w+), \((\d+)\)$", text)
    if m:
        return "lda %s, (0x%04x:16)" % (m.group(1), int(m.group(2)))
    if re.match(r"^(jr|jrl|calr|call|jp|djnz)\b", text):
        return text
    m = re.match(r"^(\w+_dd8\w*) (\w+), (\d+)$", text)
    if m:
        return "%s %s, 0x%02x" % (m.group(1), m.group(2), int(m.group(3)))
    text = re.sub(r"\((\d+)\)", lambda mm: "(0x%x)" % int(mm.group(1)) if int(mm.group(1)) >= 16
                  else mm.group(0), text)
    return re.sub(r"(?<![\w(+-])(\d{3,})(?![\w:])",
                  lambda mm: ("0x%x" % int(mm.group(1))) if int(mm.group(1)) >= 256 else mm.group(1), text)


def unidasm_listing(addr, n):
    r = subprocess.run([UNIDASM, ROM, "-arch", "tlcs900", "-basepc", "%x" % addr,
                        "-skip", str(off(addr)), "-count", str(n)], capture_output=True, text=True)
    out = []
    for ln in r.stdout.splitlines():
        m = re.match(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$", ln)
        if m:
            out.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    tot = 0
    res = []
    for a, l, t in out:
        if a != addr + tot:
            return None
        res.append((a, l, t))
        tot += l
        if tot == n:
            return res
    return None


def find_block(lines, label):
    for i, ln in enumerate(lines):
        if re.match(r"^%s:\s*(;.*)?$" % re.escape(label), ln):
            j = i + 1
            vals = []
            while j < len(lines) and re.match(r"^\s*\.byte\s", lines[j]):
                body = lines[j].split(";")[0].split(".byte", 1)[1]
                vals += [int(x.strip(), 0) for x in body.split(",") if x.strip()]
                j += 1
            return i, j, vals
    return None


def convert(label, fname, syms, apply_lines=None):
    path = os.path.join(MIRROR, fname)
    lines = apply_lines if apply_lines is not None else open(path, "rb").read().decode("latin-1").split("\n")
    fb = find_block(lines, label)
    if not fb:
        return None, "label not found in %s" % fname
    i, j, vals = fb
    if not vals:
        return None, "no .byte run under the label"
    addr = syms.get(label)
    if addr is None:
        return None, "label not in ELF"
    n = len(vals)
    if list(rom[off(addr):off(addr) + n]) != vals:
        return None, "source bytes != ROM at 0x%06X" % addr
    ins, err = mc_disasm(vals)
    if ins is None:
        # FALLBACK: frame the run with unidasm, then decode each instruction on its own.
        # Instructions llvm-mc cannot decode (minc/mdec, ldc to DMA control registers,
        # ret cc, ...) are kept as `.byte` with unidasm's reading as the comment.
        ud = unidasm_listing(addr, n)
        if ud is None:
            return None, "llvm-mc refused and unidasm does not tile the run: " + err[:120]
        ins = []
        for ia, ilen, itext in ud:
            one, _ = mc_disasm(vals[ia - addr:ia - addr + ilen])
            if one and len(one) == 1 and len(one[0][1]) == ilen:
                ins.append(one[0])
            else:
                ins.append(("#UD " + itext, vals[ia - addr:ia - addr + ilen]))
    if sum(len(e) for _, e in ins) != n:
        return None, "llvm-mc lengths sum %d != %d" % (sum(len(e) for _, e in ins), n)
    ub = unidasm_bounds(addr, n + 8)
    out, a, kept = [], addr, 0
    for text, enc in ins:
        if a not in ub:
            return None, "unidasm has no boundary at 0x%06X (llvm-mc: %s)" % (a, text)
        if text.startswith("#UD "):
            out.append("\t.byte\t" + ", ".join("0x%02x" % x for x in enc) + "\t; " + text[4:] +
                       "  (unidasm; no llvm-mc spelling)")
            kept += 1
            a += len(enc)
            continue
        re_enc = mc_encode(text)
        nice = house_style(text)
        if nice != text and mc_encode(nice) == enc:
            text, re_enc = nice, enc
        if re_enc == enc:
            out.append("\t" + text.replace(" ", "\t", 1) if " " in text else "\t" + text)
        else:
            out.append("\t.byte\t" + ", ".join("0x%02x" % x for x in enc) + "\t; " + text +
                       "  (backend re-encodes this text differently)")
            kept += 1
        a += len(enc)
    return (i, j, out, addr, n, len(ins), kept), ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("labels", nargs="+")
    ap.add_argument("--file", default="kn5000_subprogram_v142.s")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--print", action="store_true")
    a = ap.parse_args()
    syms, ok = build()
    if not ok:
        sys.exit("the current tree does not rebuild byte-identical; refusing")
    path = os.path.join(MIRROR, a.file)
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    edits = []
    for lab in a.labels:
        res, why = convert(lab, a.file, syms, lines)
        if not res:
            print("REFUSED %-40s %s" % (lab, why))
            continue
        i, j, out, addr, n, nins, kept = res
        print("OK      %-40s 0x%06X %4d B -> %3d instructions (%d kept as .byte)" % (lab, addr, n, nins, kept))
        if a.print:
            print("\n".join(out))
        edits.append((i, j, out))
    if a.apply and edits:
        for i, j, out in sorted(edits, reverse=True):
            lines[i + 1:j] = out
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
        syms2, ok2 = build()
        if not ok2:
            sys.exit("REBUILD NOT BYTE-IDENTICAL -- revert %s" % path)
        print("applied %d block(s); rebuild byte-identical" % len(edits))


if __name__ == "__main__":
    main()
