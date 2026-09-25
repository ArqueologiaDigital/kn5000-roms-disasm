#!/usr/bin/env python3
r"""lane_accomp_v7_uidatablock.py -- port v10's typed AccScreen_UIDataBlock to v7.

QUESTION ANSWERED
-----------------
v7 carries AccScreen_UIDataBlock (2,096 B) as one verbatim ROM slice,
`includes/romslices/v7_block_accscreen_uidatablock.bin`.  v10 spells the same
block as typed data + three C-compiled screen descriptors + two 7-byte
routines.  Is v7's block the same object, and if so what is its v7 source?

  1. `--diff` compares the two 2,096-byte blocks (v10 at the address of the
     `Accomp` string table minus 713, v7 likewise) and prints every differing
     run.  Measured 2026-09-25: 66 bytes differ, all of them either the low
     byte of a RAM variable id (v7 = v10 - 0x9C) or the low two bytes of a ROM
     pointer (v7 = v10 - 0x404), plus four operand bytes of the three routines
     at the head (calls into 0xFB15xx, v7 - 0x40D, and one RAM operand).
  2. Without `--diff` it WALKS v10's source statements for the block over v7's
     bytes: `.byte` lines take v7's bytes at the same offset, `.ascii` lines
     must match v7 byte-for-byte, `.incbin "includes/generated/*.bin"` lines
     must match v7's own compiled bin (v7/maincpu/sequencer/accomp_screens/*.c,
     which this lane made v7-correct), and instruction lines are re-decoded
     from v7's bytes with llvm-mc, which must round-trip.  Any disagreement is
     a hard failure, so a structural difference cannot be papered over.

RUN
    python3 scripts/converters/lane_accomp_v7_uidatablock.py --diff
    python3 scripts/converters/lane_accomp_v7_uidatablock.py            # print v7 text
    python3 scripts/converters/lane_accomp_v7_uidatablock.py --apply    # replace the slice
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.join(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
                    "llvm-project", "build", "bin")
MC, OBJCOPY = os.path.join(LLVM, "llvm-mc"), os.path.join(LLVM, "llvm-objcopy")
BASE = 0xE00000
SIZE = 2096
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lane_reframe_islands import respell  # noqa: E402  (verified native spellings)
PAT = b"CONTROL PITCH BEND ="        # the section-parameter names, block + 713


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % v), "rb").read()


def block_addr(r):
    i = r.find(PAT)
    assert i > 0 and r.count(PAT) == 1
    return BASE + i - 713


def assemble(line):
    with tempfile.TemporaryDirectory() as d:
        s, o, b = (os.path.join(d, x) for x in ("a.s", "a.o", "a.bin"))
        open(s, "w").write(line + "\n")
        r = subprocess.run([MC, "--triple=tlcs900", "-filetype=obj", "-o", o, s],
                           capture_output=True, text=True)
        if r.returncode:
            raise SystemExit("cannot assemble %r: %s" % (line, r.stderr))
        subprocess.run([OBJCOPY, "-O", "binary", "-j", ".text", o, b], check=True)
        return open(b, "rb").read()


def decode(blob):
    toks = " ".join("0x%02x" % x for x in blob)
    r = subprocess.run([MC, "--triple=tlcs900", "--disassemble"], input=toks,
                       capture_output=True, text=True)
    if "warning" in r.stderr:
        raise SystemExit("v7 bytes do not decode: %s" % toks)
    ins = [l.strip() for l in r.stdout.split("\n") if l.strip() and not l.strip().startswith(".text")]
    assert len(ins) == 1, ins
    return ins[0]


def dump_comment(chunk):
    return "; |" + "".join(chr(c) if 0x20 <= c < 0x7f else "." for c in chunk) + "|"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--diff", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--map10", help="lane_line_map.py JSON of v10 (line sizes of the block)")
    a = ap.parse_args()
    r10, r7 = rom("v10"), rom("v7")
    a10, a7 = block_addr(r10), block_addr(r7)
    b10 = r10[a10 - BASE:a10 - BASE + SIZE]
    b7 = r7[a7 - BASE:a7 - BASE + SIZE]
    if a.diff:
        print("v10 block 0x%06X, v7 block 0x%06X (delta 0x%X)" % (a10, a7, a10 - a7))
        d = [i for i in range(SIZE) if b10[i] != b7[i]]
        print("%d differing bytes" % len(d))
        k = 0
        while k < len(d):
            m = k
            while m + 1 < len(d) and d[m + 1] == d[m] + 1:
                m += 1
            s, e = d[k], d[m] + 1
            print("  +0x%03X %d B  v10 %s  v7 %s" % (s, e - s, b10[s:e].hex(), b7[s:e].hex()))
            k = m + 1
        return

    src10 = open(os.path.join(ROOT, "v10/maincpu/sequencer/accompaniment_engine.s"),
                 encoding="latin-1").read().split("\n")
    import json
    sizes = {}
    if a.map10:
        mp = json.load(open(a.map10))
        for ln, ad, sz, text in mp["files"]["sequencer/accompaniment_engine.s"]:
            if src10[ln - 1] != text:
                sys.exit("stale v10 map")
            sizes[ln] = sz
    s0 = src10.index("AccScreen_UIDataBlock:")
    s1 = src10.index("AccPatch_InitSlotChain_Wrap:")
    seg = src10[s0:s1]
    while seg and not seg[-1].strip():
        seg.pop()
    out = [seg[0],
           "; ** v7 PORT 2026-09-25 (lane accomp) of the v10 typing below.  Was one verbatim",
           "; ROM slice (includes/romslices/v7_block_accscreen_uidatablock.bin).  v7's block is",
           "; the SAME 2,096-byte object as v10's: 66 bytes differ and every one is a RAM",
           "; variable id (v7 = v10 - 0x9C), a ROM pointer (v7 = v10 - 0x404) or a call",
           "; target (v7 = v10 - 0x40D) -- scripts/converters/lane_accomp_v7_uidatablock.py",
           "; --diff lists them, and the same script generated this text by walking v10's",
           "; statements over v7's bytes.  ADDRESSES QUOTED IN THE COMMENTS BELOW ARE v9/v10",
           "; ADDRESSES (subtract 0x404 for v7); the byte values in the directives are v7's."]
    off = 0
    gen = os.path.join(ROOT, "v7/maincpu/includes/generated")
    for idx, ln in enumerate(seg[1:]):
        lineno = s0 + 2 + idx       # 1-based line number of `ln` in v10
        code = ln.split(";")[0].strip() if not ln.strip().startswith(".ascii") else ln.strip()
        if not code:
            out.append(ln)
            continue
        if re.match(r'^[A-Za-z_]\w*:$', code):
            out.append(ln)
            continue
        if code.startswith(".byte"):
            n = len(code[5:].split(","))
            c = b7[off:off + n]
            t = "\t.byte " + ", ".join("0x%02x" % x for x in c)
            if ";" in ln:
                t += "\t" + dump_comment(c) if "; |" in ln else "\t" + ln[ln.index(";"):]
            out.append(t)
            off += n
            continue
        if code.startswith(".ascii"):
            s = code[code.index('"') + 1:code.rindex('"')].encode("latin-1")
            if b7[off:off + len(s)] != s:
                sys.exit("v7 differs from v10 inside .ascii at +0x%X" % off)
            out.append(ln)
            off += len(s)
            continue
        m = re.match(r'^\.incbin\s+"includes/generated/([\w.]+)"$', code)
        if m:
            g = open(os.path.join(gen, m.group(1)), "rb").read()
            if b7[off:off + len(g)] != g:
                sys.exit("v7 compiled %s does not equal v7's ROM at +0x%X" % (m.group(1), off))
            out.append(ln)
            off += len(g)
            continue
        # an instruction: its v10 length, then v7's own decode of those bytes
        n = sizes[lineno] if lineno in sizes else len(assemble(code))
        v7t = decode(b7[off:off + n])
        sp, _ = respell([v7t])
        if assemble(sp[0]) == b7[off:off + n]:
            v7t = sp[0]
        if assemble(v7t) != b7[off:off + n]:
            sys.exit("v7 decode does not round-trip at +0x%X: %s" % (off, v7t))
        parts = re.split(r'\s+', v7t.strip(), maxsplit=1)
        out.append("\t" + parts[0] + ("\t" + parts[1] if len(parts) > 1 else ""))
        off += n
    if off != SIZE:
        sys.exit("walked %d bytes, block is %d" % (off, SIZE))
    if not a.apply:
        print("\n".join(out))
        return
    p = os.path.join(ROOT, "v7/maincpu/sequencer/accompaniment_engine.s")
    L = open(p, encoding="latin-1").read().split("\n")
    i = L.index("AccScreen_UIDataBlock:")
    assert L[i + 1].strip() == '.incbin "includes/romslices/v7_block_accscreen_uidatablock.bin"'
    L[i:i + 2] = out
    tmp = p + ".tmp"
    open(tmp, "w", encoding="latin-1").write("\n".join(L))
    os.replace(tmp, p)
    print("replaced the v7 slice with %d lines" % len(out))


if __name__ == "__main__":
    main()
