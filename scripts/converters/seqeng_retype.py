#!/usr/bin/env python3
r"""seqeng_retype.py -- retype a DATA object that the source spells as code.

QUESTION ANSWERED
-----------------
"Rewrite the N bytes at label L of one of lane seqeng's files as typed data
(`.long`/`.short`/`.byte`/`.ascii`), taken from the dump at L's address, under
an evidence header -- and prove nothing is lost."

A retype is written as a small Python spec (see notes/seqeng-2026-09-25/
retypes.py) so the header text, the layout and the evidence live next to
each other and can be re-applied to v10, v9 and v7 alike:

    dict(file="sequencer/smf_event_processor.s", label="VoiceChannel_ParamTable1",
         size=128, fmt="long4", header=[...comment lines...],
         after_label="VoiceChannel_SetRecordByte3", after_header=[...])

SAFETY
  * the lines replaced are exactly those whose bytes lie in [L, L+size) per the
    proven-inert line map (scripts/analysis/seqeng_line_map.py); a line that
    straddles either edge aborts the retype;
  * a label defined inside the span must be unreferenced anywhere in the
    image's tree (real grep, comments excluded) -- else abort;
  * comments inside the span are kept, in order, after the header;
  * the body is generated from the ORIGINAL dump, so a wrong size or address
    cannot silently reproduce other bytes -- the byte gate still certifies.

RUN
    python3 scripts/converters/seqeng_retype.py v10 notes/seqeng-2026-09-25/retypes.py [--apply] [--only LABEL]
"""
import argparse
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
from seqeng_line_map import line_map, strip_comment, ROOT, IMAGES  # noqa: E402

LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$@]*):')


def fmt_body(bs, fmt):
    out = []
    if fmt.startswith("long"):
        n = int(fmt[4:] or 4)
        assert len(bs) % 4 == 0
        v = struct.unpack("<%dI" % (len(bs) // 4), bs)
        for i in range(0, len(v), n):
            out.append("\t.long " + ", ".join("0x%08x" % x for x in v[i:i + n]))
    elif fmt.startswith("short"):
        n = int(fmt[5:] or 8)
        assert len(bs) % 2 == 0
        v = struct.unpack("<%dH" % (len(bs) // 2), bs)
        for i in range(0, len(v), n):
            out.append("\t.short " + ", ".join("0x%04x" % x for x in v[i:i + n]))
    elif fmt.startswith("byte"):
        n = int(fmt[4:] or 8)
        for i in range(0, len(bs), n):
            out.append("\t.byte " + ", ".join("0x%02x" % x for x in bs[i:i + n]))
    elif fmt == "ascii":
        s = "".join(chr(b) if 32 <= b < 127 and chr(b) not in '"\\' else "\\%03o" % b for b in bs)
        out.append('\t.ascii "%s"' % s)
    else:
        raise SystemExit("unknown fmt " + fmt)
    return out


NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
_SYMS = {}


def syms(image):
    """name -> address and address -> [names] from the image's last build."""
    if image not in _SYMS:
        elf = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % image)
        n2a, a2n = {}, {}
        for ln in subprocess.run([NM, "-n", elf], capture_output=True, text=True).stdout.split("\n"):
            p = ln.split()
            if len(p) >= 3 and p[1] in "tT" and not p[2].startswith((".", "__")):
                n2a[p[2]] = int(p[0], 16)
                a2n.setdefault(int(p[0], 16), []).append(p[2])
        _SYMS[image] = (n2a, a2n)
    return _SYMS[image]


def fill(text, image):
    """`{@Name}` in header text -> the 0xADDRESS of Name in THIS image."""
    n2a, _ = syms(image)
    return re.sub(r'\{@(\w+)\}', lambda m: "0x%06X" % n2a[m.group(1)], text)


def ptr_body(bs, image, n=1):
    _, a2n = syms(image)
    v = struct.unpack("<%dI" % (len(bs) // 4), bs)
    out = []
    for x in v:
        names = [k for k in a2n.get(x, []) if not re.search(r'_0x[0-9A-Fa-f]+$', k)] or a2n.get(x, [])
        out.append(names[0] if names else "0x%08x" % x)
    return ["\t.long " + ", ".join(out[i:i + n]) for i in range(0, len(out), n)]


def referenced(name, image):
    root = os.path.join(ROOT, image, "maincpu")
    r = subprocess.run(["grep", "-rnaw", "--include=*.s", name, root], capture_output=True, text=True)
    for ln in r.stdout.split("\n"):
        if not ln:
            continue
        _, _, text = ln.split(":", 2)
        code = strip_comment(text)
        if re.search(r'\b%s\b' % re.escape(name), code) and not re.match(r'^\s*%s:' % re.escape(name), code):
            return True
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", choices=sorted(IMAGES))
    ap.add_argument("spec")
    ap.add_argument("--only", action="append", default=[])
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    ns = {}
    exec(open(a.spec).read(), ns)
    specs = [s for s in ns["RETYPES"] if not a.only or s["label"] in a.only]
    specs = [s for s in specs if a.image in s.get("images", ("v10", "v9", "v7"))]
    img = IMAGES[a.image]
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    byfile = {}
    for s in specs:
        byfile.setdefault(s["file"], []).append(s)
    rows_all = line_map(a.image, list(byfile))
    for rel, ss in byfile.items():
        path = os.path.join(ROOT, a.image, "maincpu", rel)
        src = open(path, "rb").read().decode("latin-1").split("\n")
        rows = rows_all[rel]
        addr_of_line = {ln: (ad, sz) for ln, ad, sz in rows}
        edits = []
        for s in ss:
            lab = s["label"]
            li = next((i for i, t in enumerate(src) if re.match(r'^%s:' % re.escape(lab), t)), None)
            if li is None:
                print("SKIP %s: label not found in %s" % (lab, rel))
                continue
            hdr = [("; " + fill(h, a.image)) if h else ";" for h in s["header"]]
            if s["fmt"] == "keep":
                # header only, ABOVE the label (the object's own text is kept)
                if any(re.match(r'^;\s*' + re.escape(hdr[0][2:].strip()[:40]), src[k]) for k in range(max(0, li - len(hdr) - 2), li)):
                    print("SKIP %s: header already present" % lab)
                    continue
                edits.append((li + 1, li, hdr, lab, 0, 0))
                print("HEADER %s:%d %s -> %d lines" % (rel, li + 1, lab, len(hdr)))
                continue
            if (addr_of_line.get(li + 1, (0, 0))[1] or 0) > 0:
                print("REFUSE %s: the label line itself emits bytes" % lab)
                continue
            first = min(ln for ln in addr_of_line if ln > li + 1)   # first marked line after the label
            a0 = addr_of_line[first][0]
            a1 = a0 + s["size"]
            span = [ln for ln in sorted(addr_of_line)
                    if a0 <= addr_of_line[ln][0] < a1 and (addr_of_line[ln][1] or 0) > 0]
            last = span[-1]
            if addr_of_line[last][0] + (addr_of_line[last][1] or 0) != a1:
                print("REFUSE %s: a line straddles the end (0x%06X)" % (lab, a1))
                continue
            if any(src[k].strip() == hdr[0].strip() for k in range(li + 1, last)):
                print("SKIP %s: already retyped (its header is present)" % lab)
                continue
            # lines from label+1 .. last (inclusive) are replaced
            keep_comments, bad = [], None
            for ln in range(li + 2, last + 1):
                t = src[ln - 1]
                c = strip_comment(t).strip()
                m = LABEL_RE.match(c)
                while m:
                    if referenced(m.group(1), a.image):
                        bad = m.group(1)
                    c = c[m.end():].strip()
                    m = LABEL_RE.match(c)
                if ";" in t and t[len(strip_comment(t)):].strip():
                    keep_comments.append(t[len(strip_comment(t)):].strip())
            if bad:
                print("REFUSE %s: inner label %s is referenced" % (lab, bad))
                continue
            bs = rom[a0 - img["base"]:a1 - img["base"]]
            body = list(hdr)
            body += [c if c.startswith(";") else "; " + c for c in keep_comments]
            body += ptr_body(bs, a.image, s.get("per_line", 1)) if s["fmt"] == "ptr" else fmt_body(bs, s["fmt"])
            if s.get("after_label"):
                body += [("; " + fill(h, a.image)) if h else ";" for h in s.get("after_header", [])]
                body.append(s["after_label"] + ":")
            edits.append((li + 2, last, body, lab, a0, a1))
            print("RETYPE %s:%d-%d %s 0x%06X-0x%06X %d B -> %d lines" % (
                rel, li + 2, last, lab, a0, a1, a1 - a0, len(body)))
        if a.apply and edits:
            for l0, l1, body, *_ in sorted(edits, key=lambda e: -e[0]):
                src[l0 - 1:l1] = body
            open(path, "wb").write("\n".join(src).encode("latin-1"))
            print("written", path)


if __name__ == "__main__":
    main()
