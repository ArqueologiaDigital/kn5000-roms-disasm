#!/usr/bin/env python3
r"""Re-disassemble a MISFRAMED source region with correct instruction framing.

QUESTION THIS ANSWERS
    A region whose source lines decode the ROM bytes from the wrong starting
    points (data-as-code markers, `.byte` prefixes followed by "instructions"
    made of operand bytes, branch targets landing mid-line) is rewritten with
    the framing MAME's unidasm gives from a known instruction start, and with
    declared data ranges written as data.  Byte identity is necessary and is
    checked; the framing evidence is unidasm's linear decode from `lo` (which
    must be a real instruction start -- a branch target, a routine entry or the
    byte after a `ret`) plus llvm-mc agreeing on every instruction's length.

HOW
  1. The address map of the image (address_line_map.py's marker technique)
     gives the source lines that emit [lo, hi) in FILE; the range must start
     and end on line boundaries.
  2. Code sub-ranges: unidasm decodes linearly; each instruction's bytes are
     decoded again by llvm-mc (one process per instruction) and the text is
     re-assembled in isolation; it must reproduce the bytes, else the
     instruction is written as `.byte` with unidasm's text as a comment.
  3. Data ranges (--data lo-hi:long|byte): `.long` rows (a value that is the
     address of a label becomes that label) or `.byte` rows.
  4. Every label of the old lines is re-emitted at its address.  A label that
     would fall inside an instruction stops the tool (--drop-mid-label NAME
     drops one explicitly, after the caller has checked nothing uses it).
  5. Every comment of the old lines is re-emitted, in order, before the first
     new line at or after its address.

RUN
    python3 scripts/converters/reframe_region.py --image v10 \
        --file audio/audio_control_engine.s --range 0xFCCB1D-0xFCCFF4 \
        --data 0xFCCB8F-0xFCCB9F:long ... [--apply]
    Then rebuild + compare, and run symbolize_numeric_branches.py on FILE.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
import port_v10_span_to_v7 as pt  # noqa: E402

BASE = 0xE00000
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
MC = pt.MC


def unidasm(rom, lo, hi):
    tmp = "/tmp/claude-1000/lane-audio/reframe_seg.bin"
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    open(tmp, "wb").write(rom[lo - BASE:hi - BASE])
    out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", "0x%x" % lo],
                         capture_output=True, text=True).stdout
    res = []
    for ln in out.splitlines():
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if m:
            a = int(m.group(1), 16)
            n = len(m.group(2).split())
            res.append((a, n, m.group(3).strip()))
    return res


def mc_decode(b):
    r = subprocess.run([MC, "-triple=tlcs900", "--disassemble"], input=" ".join("0x%02x" % x for x in b),
                       capture_output=True, text=True)
    lines = [l.strip() for l in r.stdout.splitlines() if l.strip() and not l.strip().startswith(".text")]
    if r.returncode != 0 or len(lines) != 1 or "warning" in r.stderr or "invalid" in r.stderr:
        return None
    t = lines[0]
    t = re.sub(r'\s+', " ", t)
    p = t.split(" ", 1)
    mn, ops = p[0], (p[1] if len(p) > 1 else "")
    ops = house_numbers(mn, ops)
    return mn + ("\t" + ops if ops else "")


BRANCH = {"jr", "jrl", "calr", "djnz", "djnz16", "djnz8"}


def house_numbers(mn, ops):
    """Project notation: addresses (anything in parentheses) and values >= 256
    in hex, small counts/values in decimal; branch displacements untouched
    (the symboliser turns them into labels)."""
    if mn in BRANCH:
        return ops

    def paren(m):
        return re.sub(r'(?<![\w.$])(\d+)(?![\w.$])', lambda n: "0x%x" % int(n.group(1)), m.group(0))
    ops = re.sub(r'\([^)]*\)', paren, ops)

    def big(m):
        v = int(m.group(1))
        return ("0x%x" % v) if v >= 256 else m.group(1)
    out, depth = [], 0
    for part in re.split(r'(\([^)]*\))', ops):
        if part.startswith("("):
            out.append(part)
        else:
            out.append(re.sub(r'(?<![\w.$:])(\d+)(?![\w.$])', big, part))
    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--range", required=True)
    ap.add_argument("--data", action="append", default=[])
    ap.add_argument("--drop-mid-label", action="append", default=[])
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    lo, hi = [int(x, 16) for x in a.range.split("-")]
    data = []
    for d in a.data:
        r, kind = d.split(":")
        x, y = [int(v, 16) for v in r.split("-")]
        data.append((x, y, kind))
    data.sort()
    rom = pt.rom(a.image)
    order, syms = pt.amap(a.image)
    pt.fill_sizes(order)
    # the file's lines covering [lo, hi)
    rows = [(i, e) for i, e in enumerate(order) if e[1] == a.file]
    first = next(k for k, (i, e) in enumerate(rows) if e[0] is not None and e[0] >= lo)
    start = rows[first]
    # extend backwards over comment/blank/label lines at lo (keep them before)
    k0 = first
    k1 = next(k for k, (i, e) in enumerate(rows) if e[0] is not None and e[0] >= hi)
    # trailing zero-size lines at hi (labels of the next object) stay outside
    while k1 > k0 and not pt.split_line(rows[k1 - 1][1][3])[1] and rows[k1 - 1][1][0] == hi:
        k1 -= 1
    seg = rows[k0:k1]
    if seg[0][1][0] != lo:
        sys.exit("range does not start on a line boundary: first line at 0x%06X" % seg[0][1][0])
    # labels and comments of the old lines
    labels, comments = [], []
    for i, e in seg:
        labs, body, com = pt.split_line(e[3])
        for l in labs:
            labels.append((e[0], l))
        t = e[3].strip()
        if t.startswith(";"):
            comments.append((e[0], t))
        elif com:
            comments.append((e[0], com.strip()))
    # new lines
    new = []   # (addr, size, text)
    cuts = [lo] + [p for x, y, _ in data for p in (x, y)] + [hi]
    pieces = []
    cur = lo
    for x, y, kind in data:
        if cur < x:
            pieces.append((cur, x, "code"))
        pieces.append((x, y, kind))
        cur = y
    if cur < hi:
        pieces.append((cur, hi, "code"))
    addr_label = {v: k for k, v in syms.items() if BASE <= v < 0x1000000}
    for x, y, kind in pieces:
        if kind == "code":
            ins = unidasm(rom, x, y)
            if not ins or ins[0][0] != x or ins[-1][0] + ins[-1][1] != y:
                sys.exit("unidasm framing of 0x%06X-0x%06X does not tile it" % (x, y))
            for (ia, n, utext) in ins:
                b = rom[ia - BASE:ia - BASE + n]
                t = mc_decode(b)
                new.append([ia, n, t, utext, b])
        elif kind == "long":
            for q in range(x, y - 3, 4):
                v = int.from_bytes(rom[q - BASE:q - BASE + 4], "little")
                nm = addr_label.get(v)
                new.append([q, 4, ".long\t%s" % (nm if nm else "0x%08x" % v), None, rom[q - BASE:q - BASE + 4]])
            rest = (y - x) % 4
            if rest:
                q = y - rest
                new.append([q, rest, ".byte\t" + ", ".join("0x%02x" % c for c in rom[q - BASE:y - BASE]), None, None])
        else:
            for q in range(x, y, 8):
                e = min(y, q + 8)
                new.append([q, e - q, ".byte\t" + ", ".join("0x%02x" % c for c in rom[q - BASE:e - BASE]), None, None])
    # verify every decoded instruction by isolated re-assembly
    idx = [k for k, r in enumerate(new) if r[3] is not None and r[2] is not None]
    got = pt.assemble_all([new[k][2] for k in idx])
    bad = 0
    for k, g in zip(idx, got):
        if g != new[k][4]:
            new[k][2] = None
    for r in new:
        if r[3] is not None and r[2] is None:
            r[2] = ".byte\t" + ", ".join("0x%02x" % c for c in r[4]) + "\t; " + r[3]
            bad += 1
    for r in new:
        if r[3] is None or r[2] is None or r[2].startswith(".byte"):
            continue
        m = re.match(r'^(ld|lda)\t(x\w\w), 0x([0-9a-f]+)$', r[2])
        if m and int(m.group(3), 16) in addr_label and int(m.group(3), 16) >= BASE:
            r[2] = "%s\t%s, %s" % (m.group(1), m.group(2), addr_label[int(m.group(3), 16)])
    starts = {r[0] for r in new}
    for adr, l in labels:
        if adr not in starts and adr != hi:
            if l in a.drop_mid_label:
                continue
            sys.exit("label %s at 0x%06X falls inside an instruction of the new framing" % (l, adr))
    labels = [(adr, l) for adr, l in labels if l not in a.drop_mid_label]
    out = []
    ci = 0
    li = 0
    comments.sort(key=lambda c: c[0])
    for r in new:
        while ci < len(comments) and comments[ci][0] <= r[0]:
            out.append(comments[ci][1])
            ci += 1
        for adr, l in labels:
            if adr == r[0]:
                out.append("%s:" % l)
        out.append("\t" + r[2])
    while ci < len(comments):
        out.append(comments[ci][1])
        ci += 1
    print("reframed 0x%06X-0x%06X: %d lines (%d as .byte), %d labels, %d comments kept" % (
        lo, hi, len(new), bad, len(labels), len(comments)))
    if not a.apply:
        for l in out[:60]:
            print("   " + l)
        return 0
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    src = open(path, "rb").read().decode("latin-1").split("\n")
    l0 = seg[0][1][2] - 1
    l1 = seg[-1][1][2]
    src[l0:l1] = out
    open(path, "wb").write("\n".join(src).encode("latin-1"))
    print("wrote %s lines %d-%d -> %d lines" % (path, l0 + 1, l1, len(out)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
