#!/usr/bin/env python3
r"""Give numeric `.long` code pointers of a dispatch table labels at their targets.

QUESTION THIS ANSWERS
    After a region is reframed (scripts/converters/reframe_region.py) its
    jump tables are `.long 0x00fcce9a` rows: correct bytes, but a numeric
    cross-reference, which policy forbids.  Given a table address and one name
    per distinct target, this inserts `Name:` before the instruction at each
    target (refusing a target that is not the first byte of a source line),
    rewrites the `.long` rows to the names, and puts a header above the table.

RUN
    python3 scripts/tools/label_table_targets.py --image v10 --file audio/audio_control_engine.s \
        --table 0xFCCB8F --count 4 --names 0xFCCB9F=Foo_Mode0,0xFCCC12=Foo_Mode1 \
        --header-file hdr.txt [--apply]
    A target that already has a label keeps it and is not renamed.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
import port_v10_span_to_v7 as pt  # noqa: E402

BASE = 0xE00000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--table", action="append", default=[],
                    help="ADDR:COUNT:NAME=ADDR,NAME=ADDR...:HEADERFILE")
    ap.add_argument("--label", action="append", default=[],
                    help="ADDR=NAME[:HEADERFILE]: a label (and header) for a code address reached"
                         " through a table in ANOTHER file")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rom = pt.rom(a.image)
    order, syms = pt.amap(a.image)
    pt.fill_sizes(order)
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    src = open(path, "rb").read().decode("latin-1").split("\n")
    byaddr = {}
    for (adr, rel, ln, text) in order:
        if rel == a.file and adr is not None and pt.split_line(text)[1]:
            byaddr.setdefault(adr, ln)       # first byte-emitting line at adr
    labels_at = {}
    for (adr, rel, ln, text) in order:
        for l in pt.split_line(text)[0]:
            labels_at.setdefault(adr, l)
    inserts = {}        # line number -> [lines to insert before]
    edits = {}          # line number -> new text
    for spec in a.table:
        taddr, count, names, hdr = spec.split(":")
        taddr, count = int(taddr, 16), int(count)
        want = {}
        for kv in names.split(","):
            if kv:
                nm, ad = kv.split("=")
                want[int(ad, 16)] = nm
        for k in range(count):
            q = taddr + 4 * k
            v = int.from_bytes(rom[q - BASE:q - BASE + 4], "little")
            ln = byaddr.get(q)
            m = re.match(r'^\s*\.long\s+([A-Za-z_.$][\w.$]*)\s*$', src[ln - 1]) if ln else None
            if m and syms.get(m.group(1)) == v:
                continue                     # already symbolic and right
            if ln is None or not re.match(r'^\s*\.long\s+0x%08x\s*$' % v, src[ln - 1], re.I):
                sys.exit("table row at 0x%06X is not `.long 0x%08x` (line %s: %r)" % (
                    q, v, ln, src[ln - 1] if ln else None))
            if v == 0xFFFFFFFF:
                continue
            name = labels_at.get(v) or want.get(v)
            if not name:
                sys.exit("no name given for target 0x%06X (row %d)" % (v, k))
            if v not in labels_at:
                tl = byaddr.get(v)
                if tl is None:
                    sys.exit("target 0x%06X of %s is not the first byte of a source line" % (v, name))
                inserts.setdefault(tl, [])
                if name + ":" not in inserts[tl]:
                    inserts[tl].append(name + ":")
                labels_at[v] = name
            edits[ln] = "\t.long\t%s" % name
        if hdr:
            first = byaddr[taddr]
            inserts.setdefault(first, [])
            # bytes pass through unchanged: the header is decoded as latin-1
            # like the source, so UTF-8 in it survives the round trip
            inserts[first] = open(hdr, "rb").read().decode("latin-1").rstrip("\n").split("\n") + inserts[first]
    for spec in a.label:
        ad, rest = spec.split("=", 1)
        nm, _, hdr = rest.partition(":")
        ad = int(ad, 16)
        if ad in labels_at:
            sys.exit("0x%06X already has label %s" % (ad, labels_at[ad]))
        tl = byaddr.get(ad)
        if tl is None:
            sys.exit("0x%06X is not the first byte of a source line" % ad)
        lines = open(hdr, "rb").read().decode("latin-1").rstrip("\n").split("\n") if hdr else []
        inserts.setdefault(tl, [])
        inserts[tl] = inserts[tl] + lines + [nm + ":"]
        labels_at[ad] = nm
    out = []
    for i, line in enumerate(src, 1):
        out.extend(inserts.get(i, []))
        out.append(edits.get(i, line))
    print("%d label lines, %d rows rewritten" % (sum(len(v) for v in inserts.values()), len(edits)))
    if a.apply:
        open(path, "wb").write("\n".join(out).encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
