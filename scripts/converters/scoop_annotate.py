#!/usr/bin/env python3
r"""scoop_annotate.py -- give data objects (and routine entries) a label, an
evidence header and a record-per-line spelling, by ADDRESS, and prove the image
unchanged.

QUESTION ANSWERED
-----------------
"Can the objects that scoop_data_readers.py found be labelled and documented
where they stand -- label on the object, header directly above it, one record
per source line -- without moving a byte, and with every existing comment
kept?"

SPEC (JSON list), applied bottom-up per file:
    {"file": "v10/maincpu/display/scoop_display.s",
     "addr": "0xEFF5B9",
     "label": "Text_ChordTypeNames",             optional: new label here
     "comment": ["line", "line"],                optional: header above it
     "render": {"size": 320, "record": 5},       optional: re-spell the data
                                                 lines of [addr, addr+size)
                                                 as one record per line
     "rename": {"StringData_KeyNames_0x20": "Text_ChordTypeNames"}}
                                                 optional: re-point references
                                                 IN THE SPEC'S FILE to the new
                                                 name (definitions elsewhere
                                                 -- positional .set lines --
                                                 are left alone)

A record is spelled `.ascii "..."` when it is all printable, otherwise as
`.byte` with character literals for the printable bytes ('D', 0x88).  Labels
already inside a re-spelled range are kept at their address (a record is cut
there).  Comments inside the range are kept, in order, above the record that
holds their address.

The image is rebuilt and compared with the dump; every file is restored if a
byte differs.  Sources are handled as latin-1 bytes.

RUN
    python3 scripts/converters/scoop_annotate.py --image v10 --spec S.json [--dry-run]
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402


def lit(c):
    if c == 0x27 or c == 0x5c or not (0x20 <= c < 0x7f):
        return "0x%02x" % c
    return "'%s'" % chr(c)


def spell(rec):
    if all(0x20 <= c < 0x7f for c in rec):
        return '\t.ascii\t"%s"' % "".join(R.esc(c) for c in rec)
    return "\t.byte\t" + ", ".join(lit(c) for c in rec)


def apply_one(e, lines, addrs, ext, rb):
    a = int(e["addr"], 16)
    idx = next((i for i, x in enumerate(addrs[:len(lines)]) if x == a and ext[i] > 0), None)
    if idx is None:
        raise SystemExit("0x%06X: no source line starts there" % a)
    # an existing `Label:` prefix on that line, or label-only lines just above
    # at the same address, stay where they are; the header goes above them
    top = idx
    while top - 1 >= 0 and addrs[top - 1] == a and not ext[top - 1] and \
            R.LABEL_RE.match(R.strip_comment(lines[top - 1])[0].strip() or "x"):
        top -= 1
    new = []
    for c in e.get("comment", []):
        new.append("\t; " + c if c else "\t;")
    body_start, body_end = idx, idx + 1
    body = None
    if "render" in e:
        size, rec = e["render"]["size"], e["render"]["record"]
        b = a + size
        j = idx
        while j < len(lines) and (addrs[j] is None or addrs[j] < b):
            j += 1
        if j >= len(lines) or addrs[j] != b:
            raise SystemExit("0x%06X+%d does not end on a line boundary" % (a, size))
        cuts, carry = set(), []
        for k in range(idx, j):
            code, com = R.strip_comment(lines[k])
            c = code.strip()
            ad = addrs[k] if addrs[k] is not None else None
            if ad is None:
                kk = k
                while kk < j and addrs[kk] is None:
                    kk += 1
                ad = addrs[kk] if kk < j else b
            while R.LABEL_RE.match(c):
                nm = R.LABEL_RE.match(c).group(1)
                if k != idx or ad != a:
                    carry.append((ad, k, "label", nm))
                    cuts.add(ad)
                c = c[R.LABEL_RE.match(c).end():].strip()
            if c and not c.startswith("."):
                raise SystemExit("0x%06X: line %d is an instruction, not data" % (a, k + 1))
            if com.strip():
                carry.append((ad, k, "comment", com.strip()))
        first_prefix = ""
        m = R.LABEL_RE.match(R.strip_comment(lines[idx])[0].strip())
        if m:
            first_prefix = m.group(1)
        data = rb[a - R.BASE:b - R.BASE]
        out, off = [], 0
        starts = []
        while off < size:
            n = rec
            for cpos in sorted(cuts):
                if a + off < cpos < a + off + n:
                    n = cpos - (a + off)
                    break
            n = min(n, size - off)
            starts.append((a + off, spell(data[off:off + n])))
            off += n
        carry.sort(key=lambda x: (x[0], x[1]))
        ci = 0
        for ad, t in starts:
            while ci < len(carry) and carry[ci][0] <= ad:
                _, _, kind, txt = carry[ci]
                out.append(txt + ":" if kind == "label" else "\t" + txt)
                ci += 1
            out.append(t)
        while ci < len(carry):
            _, _, kind, txt = carry[ci]
            out.append(txt + ":" if kind == "label" else "\t" + txt)
            ci += 1
        if first_prefix:
            out.insert(0, first_prefix + ":")
        body, body_end = out, j
    if e.get("label"):
        new.append(e["label"] + ":")
    if body is None:
        return lines[:top] + new + lines[top:]
    # the header goes above the existing labels at `top`, the new label right
    # above the re-spelled body (after any label that was on the first line)
    pre = lines[top:idx]
    if body and body[0].endswith(":") and not body[0].startswith("\t"):
        first = [body[0]]
        body = body[1:]
    else:
        first = []
    lab = [x for x in new if not x.startswith("\t")]
    com = [x for x in new if x.startswith("\t")]
    return lines[:top] + com + pre + first + lab + body + lines[body_end:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--spec", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    specs = json.load(open(args.spec))
    files = sorted({s["file"] for s in specs})
    amap, _ = R.linemap(args.image, files)
    rb = R.rom(args.image)
    backup = {f: open(os.path.join(R.ROOT, f), "rb").read() for f in files}
    for f in files:
        lines = open(os.path.join(R.ROOT, f), encoding="latin-1").read().split("\n")
        addrs = amap[f]
        ext = R.line_extents(addrs)
        group = sorted([s for s in specs if s["file"] == f], key=lambda s: -int(s["addr"], 16))
        for e in group:
            lines = apply_one(e, lines, addrs, ext, rb)
        ren = {}
        for e in specs:
            if e["file"] == f:
                ren.update(e.get("rename", {}))
        if ren:
            pat = re.compile(r'(?<![\w.$])(%s)(?![\w.$])' % "|".join(re.escape(o) for o in ren))
            for i, ln in enumerate(lines):
                code, com = R.strip_comment(ln)      # comments are never rewritten
                if pat.search(code):
                    lines[i] = pat.sub(lambda m: ren[m.group(1)], code) + com
        text = "\n".join(lines)
        out = os.path.join(R.SCRATCH, "annot-" + os.path.basename(f)) if args.dry_run \
            else os.path.join(R.ROOT, f)
        open(out, "w", encoding="latin-1").write(text)
        print("%s: %d entries -> %s" % (f, len(group), out))
    if args.dry_run:
        return
    ok, _, data = R.build(args.image)
    if not ok or data != rb:
        for f, t in backup.items():
            open(os.path.join(R.ROOT, f), "wb").write(t)
        print(data[-2000:] if not ok else "image differs")
        raise SystemExit("REJECTED: restored all files")
    print("VERIFIED: %s image byte-identical" % args.image)


if __name__ == "__main__":
    main()
