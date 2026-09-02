#!/usr/bin/env python3
r"""RE-TYPE A DATA REGION OF v10/maincpu FROM THE ROM ITSELF (lane v10seq, 2026-09-02)

QUESTION ANSWERED
-----------------
"This span is data, and the tree currently spells it as garbage mnemonics (or
as an undifferentiated `.byte` soup). What is the byte-exact typed source for
it?"  Answering that by hand is how a wrong reading gets frozen in: the byte
gate cannot object to either version.  This tool never reads the existing
directives at all.  It takes the region's SOURCE LINE RANGE, converts it to a
ROM ADDRESS RANGE with the linked address map, reads the bytes out of
`original_ROMs/kn5000_v10_program.rom`, and emits the requested types.  The
replacement therefore cannot drift from the dump by construction, and the byte
gate is a real check of the LAYOUT (segment widths), not of the byte values.

WARNING the sources are latin-1 with raw high bytes inside `.ascii` literals;
this tool reads and writes with encoding='latin-1' explicitly (see the lane
brief's 2026-09-02 addendum on the Edit tool corrupting them), and writes to a
temp file first so a failed encode can never truncate the source.

WARNING in this assembler `.word` is FOUR bytes.  16-bit is `.short`.

INPUT
  --file  REL      path relative to the repo root
  --lines A-B      1-based inclusive line range to replace.  Comment-only and
                   blank lines inside the range are DROPPED, so put anything
                   you want to keep outside it (or pass it with --header).
  --layout SPEC    segments covering the region, separated by `|` if the spec
                   contains one, else `;` if it contains one (so notes may
                   hold commas), else `,`:
                     b  = .byte, 16 per line;  bN = N per line (b8 lays out an
                          8-byte record grid one record to a line)
                     w  = .short (LE16), 8 per line; wN = N per line
                     l  = .long  (LE32), 4 per line
                     a  = .ascii      z = .zero (asserts the bytes are zero)
                   Each segment is `COUNT:kind[#note]`; COUNT is a byte count,
                   `*` means "the rest", and `#note` emits `; note` above it.
  --header TEXT    a `;` comment block inserted above the replacement
                   (\n-split).  Use it to carry forward any comment the range
                   contained, since the range's own comments are dropped.

The tool refuses if the range's first/last emitting line has no address in the
map, if a label definition is inside the range, or if the layout does not cover
the region exactly.

RUN
    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/converters/seq_type_data_region.py --amap /tmp/amap.json \
        --file v10/maincpu/sequencer/seq_event_playback.s --lines 943-1102 \
        --layout '256:w' --dry-run
    make rebuilt_ROMs/kn5000_v10_program.llvm.rom && \
      cmp rebuilt_ROMs/kn5000_v10_program.llvm.rom original_ROMs/kn5000_v10_program.rom

The address map is keyed on line numbers, so apply several conversions to one
file in DESCENDING line order, or regenerate the map between them.
"""
import argparse
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.path.join(ROOT, "original_ROMs", "kn5000_v10_program.rom")
BASE = 0xE00000
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")
NONEMIT = (".include", ".macro", ".endm", ".equ", ".set", ".globl", ".global",
           ".section", ".text", ".data", ".if", ".else", ".endif", ".ifdef",
           ".ifndef", ".end", ".type", ".size", ".extern")


def emits(s):
    if not s or s.startswith(";") or s.startswith("#"):
        return False
    if LABEL_RE.match(s) and s.split(":", 1)[1].strip() == "":
        return False
    if s.startswith("."):
        return not s.split()[0].lower().startswith(NONEMIT)
    return True


def fmt_ascii(chunk):
    out = []
    for c in chunk:
        ch = chr(c)
        if ch == '"':
            out.append('\\"')
        elif ch == "\\":
            out.append("\\\\")
        elif 0x20 <= c <= 0x7E:
            out.append(ch)
        else:
            out.append("\\%03o" % c)
    return '\t.ascii "%s"' % "".join(out)


def emit(kind, chunk):
    lines = []
    if kind[0] == "b":
        per = int(kind[1:]) if len(kind) > 1 else 16
        for i in range(0, len(chunk), per):
            row = chunk[i:i + per]
            txt = "".join(chr(x) if 0x20 <= x <= 0x7E else "." for x in row)
            lines.append("\t.byte " + ", ".join("0x%02x" % x for x in row)
                         + "\t; |%s|" % txt)
    elif kind[0] == "w":
        per = int(kind[1:]) if len(kind) > 1 else 8
        assert len(chunk) % 2 == 0, "short segment is not a multiple of 2"
        vals = [chunk[i] | (chunk[i + 1] << 8) for i in range(0, len(chunk), 2)]
        for i in range(0, len(vals), per):
            lines.append("\t.short " + ", ".join("0x%04x" % v for v in vals[i:i + per]))
    elif kind == "l":
        assert len(chunk) % 4 == 0, "long segment is not a multiple of 4"
        vals = [int.from_bytes(chunk[i:i + 4], "little") for i in range(0, len(chunk), 4)]
        for i in range(0, len(vals), 4):
            lines.append("\t.long " + ", ".join("0x%08x" % v for v in vals[i:i + 4]))
    elif kind == "a":
        lines.append(fmt_ascii(chunk))
    elif kind == "z":
        assert all(x == 0 for x in chunk), ".zero segment is not all zero"
        lines.append("\t.zero %d" % len(chunk))
    else:
        raise SystemExit("unknown segment kind %r" % kind)
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--lines", required=True)
    ap.add_argument("--layout", required=True)
    ap.add_argument("--header", default="")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    lo_line, hi_line = (int(x) for x in a.lines.split("-"))
    amap = {}
    for e in json.load(open(a.amap)):
        if e["src"] == a.file:
            amap[e["line"]] = e["addr"]

    path = os.path.join(ROOT, a.file)
    with open(path, encoding="latin-1") as fh:
        src = fh.read().split("\n")

    first = last = None
    for n in range(lo_line, hi_line + 1):
        s = src[n - 1].split(";", 1)[0].strip()
        if LABEL_RE.match(s) and s.split(":", 1)[1].strip() == "":
            raise SystemExit("line %d defines label %r inside the range" % (n, s))
        if emits(s):
            first = n if first is None else first
            last = n
    if first is None:
        raise SystemExit("no emitting line in range")
    nxt = None
    for n in range(hi_line + 1, len(src) + 1):
        s = src[n - 1].split(";", 1)[0].strip()
        if emits(s):
            nxt = n
            break
    if first not in amap or nxt not in amap:
        raise SystemExit("range endpoints not in the address map")
    addr_lo, addr_hi = amap[first], amap[nxt]
    size = addr_hi - addr_lo
    with open(ROM, "rb") as fh:
        rom = fh.read()
    region = rom[addr_lo - BASE: addr_hi - BASE]
    assert len(region) == size

    segs, pos = [], 0
    sep = "|" if "|" in a.layout else (";" if ";" in a.layout else ",")
    for part in a.layout.split(sep):
        spec, _, note = part.partition("#")
        n_s, _, kind = spec.partition(":")
        n = size - pos if n_s.strip() == "*" else int(n_s, 0)
        segs.append((n, kind.strip() or "b", note))
        pos += n
    if pos != size:
        raise SystemExit("layout covers %d B, region is %d B (0x%06X-0x%06X)"
                         % (pos, size, addr_lo, addr_hi))

    out = []
    if a.header:
        out += ["; " + h for h in a.header.split("\n")]
    off = 0
    for n, kind, note in segs:
        if note:
            out.append("; " + note.strip())
        out += emit(kind, region[off:off + n])
        off += n

    print("%s:%d-%d  0x%06X-0x%06X  %d B  ->  %d lines"
          % (a.file, lo_line, hi_line, addr_lo, addr_hi, size, len(out)))
    if a.dry_run:
        print("\n".join(out))
        return
    new = "\n".join(src[:lo_line - 1] + out + src[hi_line:])
    blob = new.encode("latin-1")          # encode BEFORE truncating anything
    tmp = path + ".tmp-retype"
    with open(tmp, "wb") as fh:
        fh.write(blob)
    os.replace(tmp, path)
    print("written")


if __name__ == "__main__":
    main()
