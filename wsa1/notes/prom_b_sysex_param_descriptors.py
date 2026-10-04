#!/usr/bin/env python3
"""Lay out prom_b's RecordArray_F511DD as the 109 SysEx parameter DESCRIPTORS it is, each named after its parameter.

QUESTION IT ANSWERS
  RecordArray_F511DD (0xF511DD-0xF51E1F, 3139 bytes) was 223 `.byte` rows.  Its header already framed the records by
  RecordIndex: 110 starts, "16 parameter bytes, then three 32-bit prom_a pointers at +0x10, +0x14 and +0x18".  The
  twelve descriptor tables PtrTable_F51E8E .. (notes/sysex-probes/sysex_param_addresses.py TABLES) name 109 distinct
  starts; they referenced them as `RecordArray_F511DD + 0xNN`.  What each one IS is settled elsewhere:
    * byte +0 is the parameter AREA and +1 / +2 its address b7 / b8 (sysex_param_addresses.py: "`00`-area parameter
      ... b7 b8"), and notes/sysex-probes/param_names.json gives, per 00-area address, the name the Technics
      Reference Guide prints -- graded ESTABLISHED there;
    * +0x10 is the transmit-on-change method, +0x14 the setter, +0x18 the reader (FINDINGS in the setter names:
      SysExParam_*, SysExTx_SendParamValue, SysExParam_NoTransmitOnChange; commit 6a542615).
  So each start gets a label SysExParamDesc_<Reference Guide name> (CamelCase; a name the guide uses twice gets its
  address appended), the first one -- index 0 of every table, area 0, setter SysExParam_SetPlaceholder -- is
  SysExParamDesc_Placeholder, and a start that leaves room for the 0x1C-byte head is laid out as
      .byte  the 16 parameter bytes          ; area / address / size / record / offset / mask / range
      .long  +0x10, +0x14, +0x18             ; numeric here; scripts/converters/symbolize_wsa1_rom_addresses.py names them
      .byte  whatever trails before the next start
  A start that does not (0xF514B9 sits 2 bytes before 0xF514BB, the overlap the old header reported) stays bytes up to
  the next start.  Every byte is re-read from the ROM and the emitted stream is asserted equal to it.
  Then every `RecordArray_F511DD + 0xNN` that lands on a start is rewritten to the start's label.

RUN
  python3 notes/prom_b_sysex_param_descriptors.py           # the plan (start, name, layout)
  python3 notes/prom_b_sysex_param_descriptors.py --apply   # rewrite prom_b; then run the symbolizer
"""
import contextlib
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes", "sysex-probes"))
PB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
LO, HI = 0xF511DD, 0xF51E20
BASE = 0xF00000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def rb(a, n=1):
    return ROM[a - BASE:a - BASE + n]


def starts():
    with contextlib.redirect_stdout(io.StringIO()):
        saved = sys.argv
        sys.argv = ["x"]
        import sysex_param_addresses as P
        sys.argv = saved
    out = set()
    for _fam, _g, base, n in P.TABLES:
        for i in range(n):
            out.add(P.bl32(base + 4 * i))
    return sorted(out)


def camel(s):
    s = re.sub(r'[^A-Za-z0-9]+', ' ', s.replace("&", " and ")).strip()
    return "".join(w[:1].upper() + w[1:].lower() if not w.isdigit() else w for w in s.split())


def names(ds):
    pn = json.load(open(os.path.join(ROOT, "notes", "sysex-probes", "param_names.json")))
    out = {}
    for d in ds:
        area, b7, b8 = rb(d, 3)
        key = "%02X/%02X" % (b7, b8)
        if d == 0xF511F9:
            out[d] = ("SysExParamDesc_Placeholder", "the placeholder descriptor, index 0 of every descriptor table (setter SysExParam_SetPlaceholder)")
        elif area == 0 and key in pn:
            out[d] = ("SysExParamDesc_" + camel(pn[key]["name"]), "%s -- SysEx address 00 %s %s (Technics Reference Guide)" % (pn[key]["name"], "%02X" % b7, "%02X" % b8))
        else:
            out[d] = ("SysExParamDesc_%02X_%02X_%02X" % (area, b7, b8), "area %02X address %02X %02X: no guide name in param_names.json" % (area, b7, b8))
    seen = {}
    for d, (n, _w) in out.items():
        seen.setdefault(n, []).append(d)
    for n, dl in seen.items():
        if len(dl) > 1:
            for d in dl:
                b7, b8 = rb(d + 1, 2)
                out[d] = ("%s_%02X%02X" % (n, b7, b8), out[d][1])
    return out


def old_breaks():
    """Start addresses of the old listing's `.byte` rows, so a row the old listing had survives verbatim."""
    L = open(PB, "rb").read().decode("latin-1").split("\n")
    out = set()
    for l in L:
        m = re.match(r'^\t\.byte [^;]+;\s*(F5[0-9A-F]{4})\b', l)
        if m and LO <= int(m.group(1), 16) < HI:
            out.add(int(m.group(1), 16))
    return out


BREAKS = old_breaks()


def rows(a, b):
    out = []
    while a < b:
        n = min(16, b - a)
        nxt = [x for x in BREAKS if a < x < a + n]
        if nxt:
            n = min(nxt) - a
        bs = rb(a, n)
        txt = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in bs)
        out.append("\t.byte " + ", ".join("0x%02x" % c for c in bs) + "   ; %06X  %s" % (a, txt))
        a += n
    return out


def emit(ds, nm):
    out = rows(LO, ds[0])
    for k, d in enumerate(ds):
        nxt = ds[k + 1] if k + 1 < len(ds) else HI
        name, what = nm[d]
        out.append("; %s: %s" % (name, what))
        out.append(name + ":")
        if nxt - d >= 0x1C:
            h = rb(d, 16)
            # the field reading goes on its own comment line, so the 16-byte row keeps the old listing's exact text
            out.append(";   area %02X adr %02X %02X  size %02X %02X %02X  rec %02X off %02X mask %02X  range %d..%d" % (
                h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8], h[9], h[10]))
            out += rows(d, d + 16)
            for off, role in ((0x10, "transmit-on-change"), (0x14, "setter (2C)"), (0x18, "reader (2B request)")):
                v = int.from_bytes(rb(d + off, 4), "little")
                out.append("\t.long 0x%08X\t; %06X  +0x%02X %s" % (v, d + off, off, role))
            out += rows(d + 0x1C, nxt)
        else:
            out += rows(d, nxt)
    return out


def check(lines):
    got = bytearray()
    for l in lines:
        c = l.split(";")[0].strip()
        if c.startswith(".byte"):
            got += bytes(int(v, 0) for v in c[5:].split(","))
        elif c.startswith(".long"):
            got += int(c[5:].strip(), 0).to_bytes(4, "little")
    assert bytes(got) == rb(LO, HI - LO), "emitted bytes differ from the ROM"


def main():
    ds = starts()
    assert ds[0] == 0xF511F9 and all(LO <= d < HI for d in ds), "a start outside the array"
    nm = names(ds)
    new = emit(ds, nm)
    check(new)
    if "--apply" not in sys.argv:
        for d in ds:
            print("0x%06X %s" % (d, nm[d][0]))
        print("starts %d, lines %d" % (len(ds), len(new)))
        return
    L = open(PB, "rb").read().decode("latin-1").split("\n")
    i = next(k for k, l in enumerate(L) if l.startswith("RecordArray_F511DD:"))
    j = i + 1
    while L[j].lstrip().startswith(".byte"):
        j += 1
    head = ["; 2026-10-04: LAID OUT as the %d descriptors the twelve descriptor tables name, each labelled after its parameter" % len(ds),
            ";   (notes/prom_b_sysex_param_descriptors.py); the bytes are unchanged and re-checked against the ROM."]
    L[i + 1:j] = new
    L[i:i] = head
    s = "\n".join(L)
    for d in ds:
        s = re.sub(r'\bRecordArray_F511DD \+ 0x%X\b' % (d - LO), nm[d][0], s)
    data = s.encode("latin-1")
    with open(PB + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(PB + ".tmp", PB)
    print("laid out %d descriptors" % len(ds))


if __name__ == "__main__":
    main()
