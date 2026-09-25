#!/usr/bin/env python3
r"""WHERE DO THE COMPUTED JUMPS IN LANE uiproc's FILES GO?  (and label the targets)

QUESTION ANSWERED
-----------------
The UI procedures dispatch events through a computed jump:

    sub   xwa, 0x1c00017        ; optional: event code -> index
    cp    xwa, 0x0 / jrl lt, <default>
    cp    xwa, 0x6 / jrl gt, <default>      ; index range 0..N
    add   xwa, xwa                          ; word table
    add   xwa, <TableSymbol>                ; 16-bit OFFSETS, in Naka data
    ld    wa, (xwa)
    lda   xix, (<Base>:24)
    jp_ind 8, 0x07, 0xf0, 0xe0              ; jp T,(XIX+WA)   (0xe4: +BC,
                                            ;  0xe8: +DE, 0xec: +HL)

Every target is <Base> + table[i].  None of those targets is reachable by a
branch the symboliser can see, so most of them carry NO label at all -- they
are routine entry points invisible in the source.  This tool reads each table
from the ROM (the table address comes from the image's own symbol table, the
index range from the `cp` bound), prints index / event -> target, and with
--apply inserts a label at every target that has none and a comment block
above the jump documenting the table.  After insertion it re-links the image,
asserts byte identity, and asserts that every inserted label sits at the
address it was computed for (a bare label is invisible to the byte gate).

Labels are named `<Routine>_Evt<code>` when the index is an event code
(`sub xREG, 0x1c00017` precedes the bound check; <code> is the low byte group,
e.g. `_Evt1C00018`) else `<Routine>_Case<i>`; <Routine> is the nearest
non-structural label above the jump.  The tables themselves live in other
lanes' files (Naka data); the report lists them so their owners can rewrite
the `.short` words as `Target - Base`.

RUN
    python3 scripts/analysis/lane_uiproc_dispatch_tables.py --image v10 --file ui/drawbar_panel_ui.s
    python3 scripts/analysis/lane_uiproc_dispatch_tables.py --image v10 --file ... --apply
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import data_range_census as drc  # noqa: E402
import lane_uiproc_listing as L  # noqa: E402

JP_RE = re.compile(r'^\s*jp_ind\s+8\s*,\s*0x07\s*,\s*0xf0\s*,\s*0x(e0|e4|e8|ec)\b')
REG = {"e0": "wa", "e4": "bc", "e8": "de", "ec": "hl"}
STRUCT = re.compile(r'_(Skip|Join|Loop|Epilogue|Entry|Return|Helper|Sub)\d*$')
LAB = re.compile(r'^([A-Za-z_][\w]*):')


def code(l):
    return drc.strip_comment(l).strip()


def find(lines, rel, amap, syms, rom, img):
    res = []
    base_addr = img["base"]
    for i, l in enumerate(lines):
        m = JP_RE.match(code(l))
        if not m:
            continue
        r = REG[m.group(1)]
        base = table = bound = evt = None
        doubled = False
        for j in range(i - 1, max(-1, i - 16), -1):
            c = code(lines[j])
            if LAB.match(lines[j]) and j < i - 1 and base is not None:
                pass
            mm = re.match(r'^lda\s+xix\s*,\s*\(\s*([A-Za-z_][\w]*)\s*:24\s*\)$', c)
            if mm and base is None:
                base = mm.group(1)
            mm = re.match(r'^add\s+x%s\s*,\s*([A-Za-z_][\w]*)$' % r, c)
            if mm and table is None:
                table = mm.group(1)
            if re.match(r'^add\s+x%s\s*,\s*x%s$' % (r, r), c):
                doubled = True
            mm = re.match(r'^cp\s+x%s\s*,\s*(0x[0-9a-f]+|\d+)$' % r, c)
            if mm and bound is None and int(mm.group(1), 0) > 0:
                bound = int(mm.group(1), 0)
            mm = re.match(r'^sub\s+x%s\s*,\s*(0x[0-9a-f]+)$' % r, c)
            if mm and evt is None:
                evt = int(mm.group(1), 16)
        if not (base and table and bound is not None and doubled):
            res.append(dict(line=i, skip="shape not recognised (base=%s table=%s bound=%s)"
                            % (base, table, bound)))
            continue
        if base not in syms or table not in syms:
            res.append(dict(line=i, skip="symbol not in image"))
            continue
        b, t = syms[base], syms[table]
        entries = []
        for k in range(bound + 1):
            o = t - base_addr + 2 * k
            off = rom[o] | rom[o + 1] << 8
            entries.append((k, off, (b + off) & 0xFFFFFF))
        routine = None
        for j in range(i, -1, -1):
            mm = LAB.match(lines[j])
            if mm and not STRUCT.search(mm.group(1)) and mm.group(1) != base:
                routine = mm.group(1)
                break
        res.append(dict(line=i, base=base, table=table, bound=bound, evt=evt, b=b, t=t,
                        entries=entries, routine=routine, reg=r))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    img = L.image(a.image)
    srcroot = os.path.join(ROOT, img["mirror"])
    path = os.path.join(srcroot, a.file)
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    amap, rom, syms = L.build(img)
    inv = {}
    for k, v in syms.items():
        inv.setdefault(v, []).append(k)
    # address -> first emitting line of THIS file at that address
    line_at = {}
    for k, ad in amap.items():
        rel, li = k.rsplit(":", 1)
        if rel == a.file and not LAB.match(lines[int(li)]):
            li = int(li)
            if ad not in line_at or li < line_at[ad]:
                line_at[ad] = li
    found = find(lines, a.file, amap, syms, rom, img)
    inserts = {}      # line -> [text]
    planned = {}      # label -> addr
    for d in found:
        if "skip" in d:
            print("%s:%d  SKIPPED: %s" % (a.file, d["line"] + 1, d["skip"]))
            continue
        print("%s:%d  jp (%s + %s[i]) base %06X table %s @%06X  i=0..%d%s  in %s" % (
            a.file, d["line"] + 1, d["base"], d["reg"], d["b"], d["table"], d["t"], d["bound"],
            ("  (i = event - 0x%x)" % d["evt"]) if d["evt"] else "", d["routine"]))
        doc = ["; Computed jump: target = %s + %s[i], %s = 16-bit offsets (%d words, read"
               % (d["base"], d["table"], d["table"], d["bound"] + 1),
               ";   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i ="
               + ((" event - 0x%x:" % d["evt"]) if d["evt"] else " index:")]
        for k, off, tg in d["entries"]:
            names = [n for n in inv.get(tg, []) if not n.startswith(drc.MARK)]
            if not names:
                nm = "%s_%s" % (d["routine"], ("Evt%X" % (d["evt"] + k)) if d["evt"] else "Case%d" % k)
                if nm in syms or nm in planned:
                    if planned.get(nm) != tg:
                        nm = nm + "_%06X" % tg
                if tg not in line_at:
                    print("    %d: +0x%04x -> %06X  NO LINE OF THIS FILE STARTS THERE" % (k, off, tg))
                    names = ["0x%06x" % tg]
                else:
                    planned[nm] = tg
                    inv.setdefault(tg, []).append(nm)
                    inserts.setdefault(line_at[tg], [])
                    if nm + ":" not in inserts[line_at[tg]]:
                        inserts[line_at[tg]].append(nm + ":")
                    names = [nm]
                    print("    %d: +0x%04x -> %06X  NEW %s" % (k, off, tg, nm))
            else:
                print("    %d: +0x%04x -> %06X  %s" % (k, off, tg, names[0]))
            doc.append(";   %s -> %s" % ((("0x%x" % (d["evt"] + k)) if d["evt"] else str(k)), names[0]))
        if not any(l.startswith("; Computed jump: target = %s +" % d["base"])
                   for l in lines[max(0, d["line"] - 30):d["line"]]):
            inserts.setdefault(d["line"], [])
            inserts[d["line"]] = doc + inserts[d["line"]]
    if not a.apply:
        return
    out = []
    for i, l in enumerate(lines):
        out += inserts.get(i, [])
        out.append(l)
    open(path, "wb").write("\n".join(out).encode("latin-1"))
    try:
        amap2, rom2, syms2 = L.build(img)
    except SystemExit:
        open(path, "wb").write(raw)
        raise
    bad = [(n, a2, syms2.get(n)) for n, a2 in planned.items() if syms2.get(n) != a2]
    if bad:
        open(path, "wb").write(raw)
        sys.exit("REFUSED: labels not at their computed addresses: %s" % bad)
    print("APPLIED: %d labels inserted; image byte-identical; every label at its address"
          % len(planned))


if __name__ == "__main__":
    main()
