#!/usr/bin/env python3
"""Re-emit the Music Stylist records' parameter blocks as one row per panel field.

QUESTION THIS ANSWERS
    table_data/style_records.s used to spell each record's bytes +0x4D..+0xC4
    as seven anonymous 16-byte rows ("MIDI-range values, undecoded").  The
    maincpu readers that apply those bytes to the live panel have now been read
    (notes/tonedb-2026-09-25/style_record_field_map.py prints and checks the
    map), so every parameter byte has a destination: a panel TLV record tag and
    a payload offset.  This script rewrites the rows so that each line is one
    destination group, with the decoded values in the comment, and gives every
    record a two-line header naming its decoded content.

    Bytes are taken from original_ROMs/kn5000_table_data.rom and checked
    against the bytes the OLD rows spell before anything is replaced, and the
    new rows are re-parsed and checked again, so the rewrite cannot change a
    byte.  The byte gate (`make gate`) is still the certificate.

    Idempotent: a record that already has the new rows is re-emitted
    identically.  Lines above `+0x4b display-string terminator` and the
    `+0xc5 grid pad` line are left as they are.

RUN
    python3 scripts/tools/style_records_field_rows.py            # dry run: report only
    python3 scripts/tools/style_records_field_rows.py --write    # rewrite the file
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "table_data" / "style_records.s"
ROM = ROOT / "original_ROMs" / "kn5000_table_data.rom"
BASE, STRIDE, N = 0x951000, 198, 1000
COL = 112                       # comment column used throughout the file

ACC = [("ACC1", 0x10), ("ACC2", 0x11), ("ACC3", 0x12), ("RHYTHM", 0x13), ("BASS", 0x14)]


def pad(code, comment):
    width = len(code.expandtabs(8))
    tabs = max(1, (COL - width + 7) // 8)
    return code + "\t" * tabs + "; " + comment


def hx(bs):
    return ", ".join("0x%02x" % b for b in bs)


def drawbars(b):
    """tag 44/45/46 payload +3..+7 nibbles -> registration in footage order
    16' 5 1/3' 8' 4' 2 2/3' 2' 1 3/5' 1 1/3' 1'  (README-lsw-drawbar-records.md)"""
    lo = lambda x: x & 0x0F
    hi = lambda x: x >> 4
    regs = [lo(b[3]), lo(b[4]), hi(b[3]), hi(b[4]), lo(b[5]), hi(b[5]),
            lo(b[6]), hi(b[6]), lo(b[7])]
    return "".join("%X" % v for v in regs)


def rows(r):
    p = r[0x4D:]
    out = []
    out.append(pad("\t.byte\t" + hx(p[0:10]),
                   "+0x4d RIGHT 1 (part 00 +0..+9): sound %d bank %d" % (p[0], p[1])))
    out.append(pad("\t.byte\t" + hx(p[10:20]),
                   "+0x57 RIGHT 2 (part 01 +0..+9): sound %d bank %d" % (p[10], p[11])))
    out.append(pad("\t.byte\t" + hx(p[20:29]),
                   "+0x61 LEFT (part 02 +0..+8): sound %d bank %d" % (p[20], p[21])))
    out.append(pad("\t.byte\t" + hx(p[29:34]),
                   "+0x6a part 03: sound %d, bank %d, +3, +4, +8" % (p[29], p[30])))
    out.append(pad("\t.byte\t" + hx(p[34:44]),
                   "+0x6f +3,+7 of parts 10-14 = ACC1 ACC2 ACC3 RHYTHM BASS"))
    for k, (name, tag) in enumerate((("RIGHT 1", 0x44), ("RIGHT 2", 0x45), ("LEFT", 0x46))):
        b = p[44 + 8 * k:52 + 8 * k]
        out.append(pad("\t.byte\t" + hx(b),
                       "+0x%02x %s drawbars (tag %02x +0..+7): %s" % (
                           0x79 + 8 * k, name, tag, drawbars(b))))
    out.append(pad("\t.short\t%d" % (p[68] | p[69] << 8), "+0x91 style number (tag 48 +0/+1)"))
    out.append(pad("\t.byte\t" + hx(p[70:73]), "+0x93 tag 48 +2, +3, +4"))
    out.append(pad("\t.byte\t" + hx(p[73:74]),
                   "+0x96 tag 48 +7: bits 5:4 = %d (arrangement index)" % (p[73] >> 4 & 3)))
    out.append(pad("\t.short\t%d" % (p[74] | p[75] << 8), "+0x97 tempo, BPM (tag 48 +8/+9)"))
    out.append(pad("\t.byte\t" + hx(p[76:80]), "+0x99 tag 90 +0..+3"))
    out.append(pad("\t.byte\t" + hx(p[80:81]), "+0x9d tag 60 +1"))
    out.append(pad("\t.byte\t" + hx(p[81:99]), "+0x9e DSP-effect slot-0 block (tag 61 +0..+17)"))
    out.append(pad("\t.byte\t" + hx(p[99:108]), "+0xb0 tag 63 +0..+8"))
    out.append(pad("\t.byte\t" + hx(p[108:110]), "+0xb9 tag 65 +0, +1"))
    out.append(pad("\t.byte\t" + hx(p[110:113]), "+0xbb digital-effect record (tag 70 +0, +3, +4)"))
    out.append(pad("\t.byte\t" + hx(p[113:114]), "+0xbe applied by none of the three readers"))
    out.append(pad("\t.byte\t" + hx(p[114:120]), "+0xbf constant fill"))
    return out


def header(i, r):
    cat = r[0x08:0x18].decode().strip()
    sty = r[0x18:0x28].decode().strip()
    p = r[0x4D:]
    return [
        "; Stylist record %03d: %s / %s, arrangement %d of 4 (style %d, tempo %d BPM);"
        % (i, cat, sty, i % 4 + 1, p[68] | p[69] << 8, p[74] | p[75] << 8),
        "; RIGHT 1 sound %d/%d, RIGHT 2 %d/%d, LEFT %d/%d.  Field layout and readers: file header."
        % (p[0], p[1], p[10], p[11], p[20], p[21]),
    ]


NUM = re.compile(r'0x[0-9a-fA-F]+|\d+')


def spelled(lines):
    """bytes spelled by .byte / .short directives (only those occur here)"""
    out = bytearray()
    for ln in lines:
        code = ln.split(";", 1)[0].strip()
        if not code:
            continue
        op, _, args = code.partition("\t")
        vals = [int(v, 0) for v in NUM.findall(args)]
        if op == ".byte":
            out += bytes(vals)
        elif op == ".short":
            for v in vals:
                out += v.to_bytes(2, "little")
        else:
            raise SystemExit("unexpected directive in parameter block: %r" % ln)
    return bytes(out)


def main():
    write = "--write" in sys.argv
    rom = ROM.read_bytes()
    lines = SRC.read_bytes().decode("latin-1").split("\n")
    i = 0
    changed = 0
    out = []
    rec = 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r'^StyleRec_(\d{3}):', ln)
        if not m:
            out.append(ln)
            i += 1
            continue
        n = int(m.group(1))
        assert n == rec, (n, rec)
        r = rom[BASE - 0x800000 + STRIDE * n:BASE - 0x800000 + STRIDE * (n + 1)]
        # drop an existing two-line record header (idempotency)
        while out and out[-1].startswith(("; Stylist record ", "; RIGHT 1 sound ")):
            out.pop()
        out += header(n, r)
        out.append(ln)
        i += 1
        while "; +0x4b display-string terminator" not in lines[i]:
            out.append(lines[i])
            i += 1
        out.append(lines[i])
        i += 1
        j = i
        while "; +0xc5 grid pad" not in lines[j]:
            j += 1
        old = lines[i:j]
        if spelled(old) != r[0x4D:0xC5]:
            raise SystemExit("StyleRec_%03d: old rows do not spell the ROM bytes" % n)
        new = rows(r)
        if spelled(new) != r[0x4D:0xC5]:
            raise SystemExit("StyleRec_%03d: new rows do not spell the ROM bytes" % n)
        if new != old:
            changed += 1
        out += new
        i = j
        rec += 1
    assert rec == N, rec
    text = "\n".join(out)
    print("%d of %d records re-emitted with new rows" % (changed, N))
    if write:
        SRC.write_bytes(text.encode("latin-1"))
        print("wrote", SRC.relative_to(ROOT))
    else:
        print("dry run; pass --write to rewrite")


if __name__ == "__main__":
    main()
