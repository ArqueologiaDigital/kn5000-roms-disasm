#!/usr/bin/env python3
r"""Type the HAMA (factory test) object tables in factory_test/test_data.s from
their registration in InitializeHama.

QUESTION THIS ANSWERS
    factory_test/test_data.s opens with ~860 bytes of `.byte` rows and a few
    `.long`s (v10/v9 0xE1F032-0xE1F393) that the census grades "descriptive
    name only".  InitializeHama (factory_test/test_init.s) registers objects
    with RegisterObjectTable whose +10 data field points into exactly this
    range, with numeric addresses.  What is at each of those addresses?

HOW
    * Each `RegObjTableHama` / `RegObjTablHama` line gives {class, proc, +8,
      data, index}; RegisterObjectTable (ui/ui_widget_defs.s) copies the
      14-byte descriptor to the registry at 0x27ED2 + 14*index.  `RegObjTableHama`
      takes its +8 word FROM MEMORY at the third argument (`ldw_da`), the
      `...Tabl...` form takes it as an immediate.
    * FunctionProc / ApFunctionProc objects come in pairs 0x300 apart
      (0x109 / 0x409, 0x129 / 0x429): the low one's table holds code pointers
      ending in 0, the high one's the matching name pointers (entry i of the
      name table is a string naming entry i of the code table -- e.g.
      Hama_ModeParam_Table's "FlashWrite" next to FlashWrite).
    * The tables are rewritten as `.long <label>[ + off]` rows (each ROM value
      exact); every registered data address gets a label and a two-line header;
      the numeric arguments in InitializeHama become those labels.
    --apply rebuilds and compares; a mismatch restores the files.

RUN
    python3 scripts/lanes/sys/hama_tables.py --image v10 [--apply]
"""
import argparse
import bisect
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402

ROOT = pi.ROOT
BASE = pi.BASE
DATA = "factory_test/test_data.s"
INIT = "factory_test/test_init.s"
RX = re.compile(r'^\t(RegObjTableHama|RegObjTablHama)\s+(\S+),\s*(\S+),\s*(\S+),\s*(\S+),\s*(\S+)\s*$')


def val(tok, syms):
    tok = tok.strip()
    if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', tok):
        return int(tok, 0)
    return syms.get(tok)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    img = args.image
    order, syms = pi.amap(img)
    rom = pi.rom(img)
    lo = syms["Hama_ModeInit_Table"]
    hi = syms["Hama_ModeParam_Table"]
    names_end = struct.unpack_from("<I", rom, hi - BASE)[0]    # first name string
    code = sorted((v, k) for k, v in syms.items() if 0xE00000 <= v < 0x1000000
                  and not k.startswith(("__", ".")))
    ck = [v for v, k in code]

    def near(v):
        if v == 0:
            return "0"
        i = bisect.bisect_right(ck, v) - 1
        if i < 0 or v - ck[i] > 0x4000:
            return "0x%08x" % v
        k = code[i][1]
        return k if ck[i] == v else "%s + 0x%x" % (k, v - ck[i])
    # registrations
    initp = os.path.join(ROOT, img, "maincpu", INIT)
    regs = []
    for ln in open(initp, encoding="latin-1"):
        m = RX.match(ln)
        if m:
            mac, cls, proc, p8, data, idx = m.groups()
            regs.append(dict(mac=mac, cls=val(cls, syms), proc=proc, procv=val(proc, syms), p8=p8,
                             data=val(data, syms), datatok=data, idx=val(idx, syms), line=ln))
    inr = [r for r in regs if r["data"] is not None and lo <= r["data"] < names_end]
    for r in inr:
        print("  0x%06X  object 0x%03X  class 0x%08X  %s  +8 %s" % (r["data"], r["idx"], r["cls"], r["proc"], r["p8"]))
    by = {r["data"]: r for r in inr}
    # pointer tables: a registered data address whose words are pointers up to a 0 word
    objs = {}
    for d0, r in by.items():
        if r["proc"] in ("FunctionProc", "ApFunctionProc") and r["idx"] < 0x400:
            q = d0
            while True:            # code pointers up to and including the 0
                v = struct.unpack_from("<I", rom, q - BASE)[0]
                q += 4
                if v == 0 or q >= names_end:
                    break
            objs[d0] = ("ptrs", q - d0, r)
        elif r["proc"] not in ("FunctionProc", "ApFunctionProc"):
            objs[d0] = ("block", None, r)
    for d0, r in by.items():
        if r["proc"] in ("FunctionProc", "ApFunctionProc") and r["idx"] >= 0x400:
            # the name table has as many entries as its pair's code table
            pair = next((x for x, (k, sz, rr) in objs.items() if k == "ptrs" and rr["idx"] == r["idx"] - 0x300), None)
            objs[d0] = ("ptrs", objs[pair][1] if pair else 4, r)
    # the ApFunctionProc code table ends at the 0 before the names table
    # labels
    label_of = {}
    for d0 in sorted(objs):
        existing = [k for k, v in syms.items() if v == d0 and not k.startswith(("__", "."))]
        label_of[d0] = existing[0] if existing else "HamaObj_%03X_Data" % objs[d0][2]["idx"]
    heads = {}
    for d0, (kind, size, r) in objs.items():
        pair = r["idx"] ^ 0x700 if r["idx"] & 0x700 in (0x100, 0x400) else None
        if kind == "ptrs" and r["idx"] >= 0x400:
            what = "table of %d pointers to the NAME strings of the functions in object 0x%03X's table" % (
                size // 4, r["idx"] - 0x300)
        elif kind == "ptrs":
            what = "table of %d code pointers, ending in 0 (object 0x%03X holds their names)" % (
                size // 4, r["idx"] + 0x300)
        else:
            what = "parameter block of object 0x%03X (class 0x%08X, proc %s); its descriptor's +8 word" \
                   " is read from %s" % (r["idx"], r["cls"], r["proc"], r["p8"])
        heads[d0] = ["; %s" % what,
                     "; evidence: InitializeHama `%s %s, %s, %s, <this>, 0x%x` -> RegisterObjectTable"
                     " (descriptor +10 = this; registry 0x27ED2 + 14*index)"
                     % (r["mac"], hex(r["cls"]), r["proc"], r["p8"], r["idx"])]
    heads[lo] = ["; table of 6 pointers to NakaInst_* instruction texts (\"Select the sound for each part\" and",
                 "; its A-D variants); evidence: SndArrLangCheck (audio/sound_editor_ui.s) returns this address in",
                 "; XHL when XBC = 0x01E0009F.  Not HAMA mode data; the name is kept because that file uses it."]
    # render [lo, hi): keep existing labels, comments and typed string lines; pointer words -> .long
    rows = [e for e in order if e[1] == DATA]
    i0 = next(i for i, e in enumerate(rows) if e[0] == lo and e[4] > 0)
    i1 = next(i for i, e in enumerate(rows) if e[0] is not None and e[0] >= hi and e[4] > 0)
    # the range's own lines: strings (aligned_string) are atoms we keep; the rest re-rendered
    keep_atoms, labels, notes = {}, {}, {}
    cur = lo
    for e in rows[i0:i1]:
        labs, body, com = pi.split_line(e[3])
        ad = e[0] if e[0] is not None else cur
        if e[0] is not None and e[4] > 0:
            cur = e[0] + e[4]
        for lab in labs:
            labels.setdefault(ad, []).append(lab)
        t = e[3].strip()
        if t.startswith(";"):
            notes.setdefault(ad, []).append(t)
        elif com.strip():
            notes.setdefault(ad, []).append(com.strip())
        if body.startswith(("aligned_string", ".ascii", ".asciz", ".zero")):
            keep_atoms[e[0]] = (e[4], "\t" + body)
    for d0 in objs:
        if label_of[d0] not in labels.get(d0, []):
            labels.setdefault(d0, []).append(label_of[d0])
    ptr_ranges = [(d0, d0 + s) for d0, (k, s, r) in objs.items() if k == "ptrs"]
    # exact names for pointer words: labels, plus new labels on string atoms
    exact = {}
    for k2, v2 in syms.items():
        if 0xE00000 <= v2 < 0x1000000 and not k2.startswith(("__", ".")):
            exact.setdefault(v2, k2)
    for ad, (n, body) in keep_atoms.items():
        m = re.match(r'^\taligned_string\s+"([A-Za-z0-9_]+)"', body)
        if m and ad not in labels and ad not in exact:
            nm = "HamaStr_" + m.group(1)
            if nm not in syms:
                labels[ad] = [nm]
                exact[ad] = nm
    for ad, labs in labels.items():
        for lab in labs:
            exact.setdefault(ad, lab)
    ptr_ranges.append((lo, lo + 24))          # six NakaInst_* pointers read via Hama_ModeInit_Table
    out = []
    a = lo
    cuts = sorted(set(keep_atoms) | set(labels) | set(notes) | {x for r in ptr_ranges for x in r} | {hi})
    while a < hi:
        for h in heads.get(a, []):
            out.append(h)
        for lab in labels.get(a, []):
            out.append("%s:" % lab)
        out.extend(notes.get(a, []))
        if a in keep_atoms:
            n, ln = keep_atoms[a]
            out.append(ln)
            a += n
            continue
        nxt = min(c for c in cuts if c > a)
        inptr = any(x <= a < y for x, y in ptr_ranges)
        if inptr and (nxt - a) % 4 == 0:
            for q in range(a, nxt, 4):
                out.append("\t.long\t%s" % near(struct.unpack_from("<I", rom, q - BASE)[0]))
        else:
            # inside a parameter block: a word, aligned to the block, that is
            # the exact address of a label becomes `.long label`
            blk = max((d0 for d0 in objs if d0 <= a), default=lo)
            pend = []

            def flush():
                for q in range(0, len(pend), 8):
                    out.append("\t.byte\t" + ", ".join("0x%02x" % x for x in pend[q:q + 8]))
                pend.clear()
            q = a
            while q < nxt:
                if (q - blk) % 4 == 0 and q + 4 <= nxt:
                    v = struct.unpack_from("<I", rom, q - BASE)[0]
                    nm = exact.get(v)
                    if nm:
                        flush()
                        out.append("\t.long\t%s" % nm)
                        q += 4
                        continue
                pend.append(rom[q - BASE])
                q += 1
            flush()
        a = nxt
    out.extend(heads.get(hi, []))          # Hama_ModeParam_Table's own header
    out.extend(notes.get(hi, []))
    out.extend("%s:" % lab for lab in labels.get(hi, []))
    print("%s: %d -> %d lines" % (img, i1 - i0, len(out)))
    if not args.apply:
        print("\n".join(out[:90]))
        return 0
    p = os.path.join(ROOT, img, "maincpu", DATA)
    raw_p, raw_i = open(p, "rb").read(), open(initp, "rb").read()
    L = raw_p.decode("latin-1").split("\n")
    L[rows[i0][2] - 1:rows[i1 - 1][2]] = out
    open(p, "wb").write("\n".join(L).encode("latin-1"))
    t = raw_i.decode("latin-1")
    for d0 in objs:
        r = objs[d0][2]
        if re.match(r'^0x', r["datatok"]):
            newline = r["line"].replace(r["datatok"], label_of[d0], 1)
            t = t.replace(r["line"], newline, 1)
    open(initp, "wb").write(t.encode("latin-1"))
    built, err = pi.fast_build(img, os.path.join(pi.SCRATCH, "build"))
    if built == rom:
        print("%s IDENTICAL" % img)
        return 0
    print("MISMATCH/FAIL; restoring", err[-1500:] if built is None else "")
    open(p, "wb").write(raw_p)
    open(initp, "wb").write(raw_i)
    return 1


if __name__ == "__main__":
    sys.exit(main())
