#!/usr/bin/env python3
r"""convert_v142_code_islands.py -- single `.byte` lines inside v1.42 sub-CPU CODE that are
really one or more whole instructions.

QUESTION THIS ANSWERS
    Which `.byte` / `.ascii` lines of kn5000_subprogram_v142.s and subcpu_fp_math.s sit
    between instructions ("islands") and are themselves instructions -- typically forms the
    assembler once could not spell (`andmi16 (xde+4),0xfff0` = 9a 04 3c f0 ff) -- and what
    are those instructions?  With --apply it rewrites each such line in place.

HOW EACH LINE'S ADDRESS IS KNOWN
    The v142/subcpu tree is mirrored to a temp dir, a marker label is inserted before every
    byte-emitting line of the two code files, the mirror is assembled and LINKED with the real
    subcpu.ld, and the markers' addresses are read from the ELF.  The mirror's ROM image is
    asserted byte-identical to the dump first -- a label emits nothing, so a matching image
    proves the map describes THIS tree.  Each island's own bytes are then compared with the
    ROM at its mapped address (stale-map guard).

WHEN A LINE IS CONVERTED (all must hold; otherwise it is listed as REFUSED with the reason)
    * the nearest byte-emitting lines above and below are instructions (an island in code);
    * llvm-mc --disassemble decodes exactly the line's bytes, whole instructions only, with
      no warning;
    * MAME unidasm, decoding linearly from the PREVIOUS instruction line's address, has an
      instruction boundary at the island's start, at every decoded boundary, and at its end
      (so the island is not the tail of a misframed instruction);
    * every decoded instruction re-assembles to its own bytes;
    * (--apply) the whole image rebuilds byte-identical.
    Trailing comments on the island line are kept on the first new line.

RUN
    python3 scripts/converters/convert_v142_code_islands.py            # dry: list
    python3 scripts/converters/convert_v142_code_islands.py --apply
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v142/subcpu")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
PROJ = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM = os.path.join(PROJ, "llvm-project", "build", "bin")
MC = os.path.join(LLVM, "llvm-mc")
UNIDASM = os.path.join(PROJ, "tools", "unidasm")
FILES = ["kn5000_subprogram_v142.s", "subcpu_fp_math.s"]
MARK = "__isl_"

rom = open(ROM, "rb").read()


def off(a):
    return a - 0xF000 + 0x100 if a >= 0xF000 else a - 0x400


def strip_comment(s):
    out, q = [], False
    for ch in s:
        if ch == '"':
            q = not q
        if ch == ";" and not q:
            break
        out.append(ch)
    return "".join(out)


DIRECTIVE_EMIT = re.compile(r"^\s*\.(byte|short|word|long|ascii|asciz|string|zero|fill|space|incbin|org|align)\b")
LABEL = re.compile(r"^\s*[A-Za-z_.$][\w.$@]*:\s*")


def emits(line):
    c = LABEL.sub("", strip_comment(line)).strip()
    if not c:
        return None
    if c.startswith("."):
        return "data" if DIRECTIVE_EMIT.match(c) else None
    return "insn"


def link(tree_dir):
    o, e, b = (os.path.join(tree_dir, x) for x in ("m.o", "m.elf", "m.bin"))
    subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", tree_dir, "-o", o,
                    os.path.join(tree_dir, "kn5000_subprogram_v142.s")], check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", os.path.join(tree_dir, "subcpu.ld"), "-o", e, o],
                   check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b], check=True)
    full = open(b, "rb").read()
    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), e], check=True, capture_output=True, text=True).stdout
    return full[:256] + full[60416:], nm


def line_map():
    d = tempfile.mkdtemp(prefix="v142isl_")
    shutil.copytree(TREE, os.path.join(d, "t"))
    t = os.path.join(d, "t")
    info = {}
    n = 0
    for f in FILES:
        L = open(os.path.join(t, f), "rb").read().decode("latin-1").split("\n")
        out = []
        in_macro = False
        for i, ln in enumerate(L):
            s = strip_comment(ln).strip()
            if s.startswith(".macro"):
                in_macro = True
            if not in_macro and emits(ln):
                out.append("%s%d:" % (MARK, n))
                info[n] = (f, i)
                n += 1
            if s.startswith(".endm"):
                in_macro = False
            out.append(ln)
        open(os.path.join(t, f), "wb").write("\n".join(out).encode("latin-1"))
    img, nm = link(t)
    if img != rom:
        sys.exit("marked mirror is NOT byte-identical to the dump -- map would lie; abort")
    addr = {}
    for ln in nm.splitlines():
        p = ln.split()
        if len(p) == 3 and p[2].startswith(MARK):
            k = int(p[2][len(MARK):])
            addr[info[k]] = int(p[0], 16)
    shutil.rmtree(d)
    return addr


def mc_disasm(bs):
    r = subprocess.run([MC, "-triple=tlcs900", "--disassemble", "-show-encoding"],
                       input=" ".join("0x%02x" % x for x in bs), capture_output=True, text=True)
    if "warning" in r.stderr or r.returncode:
        return None
    out = []
    for ln in r.stdout.splitlines():
        m = re.match(r"^\s+(.+?)\s*; encoding: \[(.*)\]\s*$", ln)
        if m:
            out.append((re.sub(r"\s+", " ", m.group(1).strip()), [int(x, 16) for x in m.group(2).split(",")]))
    return out


def mc_encode(text):
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input="\t" + text + "\n",
                       capture_output=True, text=True)
    m = re.search(r"; encoding: \[(.*?)\]", r.stdout)
    if r.returncode or not m or "A" in m.group(1):
        return None
    return [int(x, 16) for x in m.group(1).split(",")]


def unidasm_bounds(a0, n):
    r = subprocess.run([UNIDASM, ROM, "-arch", "tlcs900", "-basepc", "%x" % a0, "-skip", str(off(a0)),
                        "-count", str(n)], capture_output=True, text=True)
    return {int(m.group(1), 16) for m in (re.match(r"^([0-9a-f]+):", l) for l in r.stdout.splitlines()) if m}


def unidasm_list(a0, n):
    r = subprocess.run([UNIDASM, ROM, "-arch", "tlcs900", "-basepc", "%x" % a0, "-skip", str(off(a0)),
                        "-count", str(n)], capture_output=True, text=True)
    out, tot = [], 0
    for ln in r.stdout.splitlines():
        m = re.match(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$", ln)
        if not m:
            continue
        a, l = int(m.group(1), 16), len(m.group(2).split())
        if a != a0 + tot:
            return None
        out.append((a, l, m.group(3).strip()))
        tot += l
        if tot == n:
            return out
    return None


def hexify(text):
    # house style: hex for immediates >= 256 (masks, addresses); leave displacements alone
    if re.match(r"^(jr|jrl|calr|call|jp|djnz)\b", text):
        return text
    return re.sub(r"(?<=, )(\d{3,})$", lambda m: "0x%x" % int(m.group(1)) if int(m.group(1)) >= 256 else m.group(1), text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    amap = line_map()
    edits = {f: {} for f in FILES}
    ok = ref = 0
    for f in FILES:
        L = open(os.path.join(TREE, f), "rb").read().decode("latin-1").split("\n")
        kinds = [(i, emits(ln)) for i, ln in enumerate(L)]
        em = [(i, k) for i, k in kinds if k]
        for j, (i, k) in enumerate(em):
            if k != "data" or j == 0 or j + 1 >= len(em):
                continue
            body = LABEL.sub("", strip_comment(L[i])).strip()
            if not re.match(r"^\.(byte|ascii)\b", body):
                continue
            if em[j - 1][1] != "insn" or em[j + 1][1] != "insn":
                continue
            ad, nx, pv = amap.get((f, i)), amap.get((f, em[j + 1][0])), amap.get((f, em[j - 1][0]))
            if None in (ad, nx, pv):
                continue
            bs = list(rom[off(ad):off(nx)])
            if body.startswith(".byte"):
                src = [int(x.strip(), 0) for x in body[5:].split(",") if x.strip()]
                if src != bs:
                    print("REFUSED %s:%d stale map / multi-line run" % (f, i + 1))
                    ref += 1
                    continue
            if all(v == 0xFF for v in bs) or all(v == 0x0E for v in bs):
                # 0xFF is fill (it would "decode" as swi 7) and a lone 0x0E run is a documented
                # stray/padding `ret`; turning either into an instruction is the data-as-code trap.
                print("SKIPPED %s:%d 0x%06X fill/stray byte(s) %s -- left as data" %
                      (f, i + 1, ad, " ".join("%02x" % v for v in bs)))
                continue
            if strip_comment(L[i]) != L[i].rstrip("\r"):
                print("SKIPPED %s:%d 0x%06X already annotated" % (f, i + 1, ad))
                continue
            ins = mc_disasm(bs)
            why = None
            if not ins or sum(len(e) for _, e in ins) != len(bs):
                # FALLBACK: unidasm frames the island; decode each instruction alone and keep the
                # ones llvm-mc cannot spell as .byte with unidasm's reading as the comment.
                ul = unidasm_list(ad, len(bs))
                ins = []
                if ul is None:
                    why = "llvm-mc does not decode these bytes and unidasm does not tile them"
                else:
                    for ia, il, it in ul:
                        one = mc_disasm(bs[ia - ad:ia - ad + il])
                        if one and len(one) == 1 and len(one[0][1]) == il:
                            ins.append(one[0])
                        else:
                            ins.append(("#UD " + it, bs[ia - ad:ia - ad + il]))
            if not why:
                ub = unidasm_bounds(pv, nx - pv + 8)
                x = ad
                bounds = [ad]
                for _, e in ins:
                    x += len(e)
                    bounds.append(x)
                if not all(b in ub for b in bounds):
                    why = "unidasm framing disagrees (island is part of a misframed instruction)"
                else:
                    for t, e in ins:
                        if t.startswith("#UD "):
                            continue
                        if mc_encode(t) != e:
                            why = "re-encode differs for `%s`" % t
                            break
            if why:
                print("REFUSED %s:%d 0x%06X %s  [%s]" % (f, i + 1, ad, why, " ".join("%02x" % v for v in bs)))
                ref += 1
                continue
            texts = []
            for t, e in ins:
                if t.startswith("#UD "):
                    texts.append(".byte " + ", ".join("0x%02x" % v for v in e) +
                                 "\t; " + t[4:] + "  (unidasm; no llvm-mc spelling)")
                    continue
                h = hexify(t)
                texts.append(h if mc_encode(h) == e else t)
            m = re.match(r"^(\s*[A-Za-z_.$][\w.$@]*:\s*)?", L[i])
            pre = m.group(1) or ""
            cm = L[i][len(strip_comment(L[i])):]
            new = []
            for n, t in enumerate(texts):
                parts = t.split(" ", 1)
                line = "\t" + parts[0] + ("\t" + parts[1] if len(parts) > 1 else "")
                if n == 0:
                    line = (pre.rstrip() + "\n" if pre.strip() else "") + line + (("\t" + cm.strip()) if cm.strip() else "")
                new.append(line)
            edits[f][i] = "\n".join(new)
            print("OK      %s:%d 0x%06X %-28s -> %s" % (f, i + 1, ad, " ".join("%02x" % v for v in bs), " / ".join(texts)))
            ok += 1
    print("islands convertible: %d, refused: %d" % (ok, ref))
    if a.apply and ok:
        backup = {}
        for f in FILES:
            p = os.path.join(TREE, f)
            raw = open(p, "rb").read()
            backup[p] = raw
            L = raw.decode("latin-1").split("\n")
            for i, t in edits[f].items():
                L[i] = t
            open(p, "wb").write("\n".join(L).encode("latin-1"))
        d = tempfile.mkdtemp(prefix="v142islv_")
        shutil.copytree(TREE, os.path.join(d, "t"))
        img, _ = link(os.path.join(d, "t"))
        if img != rom:
            for p, raw in backup.items():
                open(p, "wb").write(raw)
            sys.exit("rebuild NOT byte-identical -- all edits reverted")
        print("applied; rebuild byte-identical")


if __name__ == "__main__":
    main()
