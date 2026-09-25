#!/usr/bin/env python3
"""Where does each byte of a Music Stylist record's parameter block go?

QUESTION THIS ANSWERS
    table_data/style_records.s holds 1000 Music Stylist records of 198 bytes.
    Bytes +0x4d.. of each record were recorded as a "115-byte parameter block
    ... MIDI-range values, undecoded".  The maincpu applies that block to the
    live panel TLV stream at RAM 0xF9A0 (mirror 0x03C2C4) through three
    readers, and each reader states, instruction by instruction, which panel
    record (tag) and payload offset every parameter byte lands in.  This probe
    extracts those three maps from the program ROMs / sources, checks that
    v7, v9 and v10 agree, and checks every numeric claim that the
    style_records.s header now makes about the 1000 records.

THE THREE READERS (addresses are v10 = v9; v7 in brackets)
    EffectMode_UpdateBitFlags      0xFB6EEA [0xFB6729]
        walks the 6-byte table WidgetStyleDataTable_0x2A8 (0xEB7BDA in all
        three), entry = {u32 panel offset from 0xF9A0, u8 sub-offset,
        u8 count}, terminated by u32 0xFF; copies `count` consecutive
        parameter bytes to mirror 0x03C2C4 + offset + sub-offset.
    BitMapOut_ByteData_PatchTable  0xFB63DC [0xFB5C1B]
        the unrolled alternative that EffectMode_UpdateDisplay calls instead
        when bit 5 of RAM 0x8D52 is set; applies bit masks.  Its source is
        parsed here (v10/v9/v7 ui/bitmap_out_routines.s are identical).
    EffectMode_CopyVoiceParams     0xFB69EA [0xFB6229]
        runs after either of the above; copies parameter bytes 29..33 into
        part 03 when tag 0x70 payload +3 == 3.
    The parameter-block pointer comes from EffectMode_ClampAndLookupPreset
    (0xFB6DAB [0xFB65EA]): rec + LE32 rec[+4] (= rec + 77 = +0x4D).

RUN
    python3 notes/tonedb-2026-09-25/style_record_field_map.py          # asserts, prints the map
    python3 notes/tonedb-2026-09-25/style_record_field_map.py --json   # machine-readable map
    Needs a built tree (rebuilt_ROMs/*.llvm.elf) for the symbol addresses.
    Exits non-zero if any assertion fails.
"""
import collections
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
NM = pathlib.Path.home() / "compartilhado/llvm-project/build/bin/llvm-nm"
PANEL = 0xF9A0
MIRROR = 0x03C2C4

# Panel TLV block 0, from analysis/disk-format-probes/README-lsw-panel-schema.md
# (schema tables at 0xED8FE0; the payload of a record starts at tag+2).
# name -> (tag, payload address)
def panel_records():
    recs = [("78", 0x12)]
    recs += [("%02x" % t, 0x18) for t in range(0x00, 0x04)]
    # parts 04..0e come from a default block, same width
    recs += [("%02x" % t, 0x18) for t in range(0x04, 0x0F)]
    recs += [("%02x" % t, 0x18) for t in range(0x0F, 0x17)]
    recs += [("19", 0x18)]
    recs += [("44", 0x0A), ("45", 0x0A), ("46", 0x0A), ("47", 0x08),
             ("43", 0x04), ("48", 0x0A), ("90", 0x06), ("60", 0x04),
             ("61", 0x18), ("63", 0x18), ("64", 0x18), ("65", 0x18),
             ("66", 0x18), ("68", 0x0A), ("70", 0x08), ("72", 0x0E),
             ("92", 0x0E), ("71", 0x02), ("99", 0x1E), ("80", 0x0E)]
    out, a = {}, PANEL
    for tag, n in recs:
        out[a + 2] = (tag, n)
        a += 2 + n
    assert a == 0xFD5E, hex(a)          # block-0 terminator FF FF at 0xFD5E
    return out


PAYLOADS = panel_records()


def where(addr):
    """panel address -> (tag, payload offset)"""
    best = None
    for p, (tag, n) in PAYLOADS.items():
        if p <= addr < p + n:
            best = (tag, addr - p)
    if best is None:
        raise SystemExit("FAIL: 0x%X is not inside any block-0 payload" % addr)
    return best


def syms(ver):
    elf = ROOT / "rebuilt_ROMs" / ("kn5000_%s_program.llvm.elf" % ver)
    out = subprocess.run([str(NM), "--defined-only", str(elf)],
                         capture_output=True, text=True, check=True).stdout
    d = {}
    for ln in out.splitlines():
        a, _, n = ln.split(None, 2)
        d[n] = int(a, 16)
    return d


def walker_table(ver):
    rom = (ROOT / "original_ROMs" / ("kn5000_%s_program.rom" % ver)).read_bytes()
    a = syms(ver)["WidgetStyleDataTable_0x2A8"] - 0xE00000
    ents, i = [], 0
    while True:
        e = rom[a + 6 * i:a + 6 * i + 6]
        off = int.from_bytes(e[:4], "little")
        if off == 0xFF:
            break
        ents.append((off, e[4], e[5]))
        i += 1
    return ents, rom[a:a + 6 * (i + 1)]


def walker_map(ents):
    m, p = {}, 0
    for off, sub, cnt in ents:
        for k in range(cnt):
            m[p] = (PANEL + off + sub + k, 0xFF)
            p += 1
    return m


LD_SRC = re.compile(r'^\tld (c|a), \(xwa(?: \+ (\d+))?\)$')
LDA_ABS = re.compile(r'^\tlda xhl, \((0x[0-9a-f]+):16\)$')
LDA_REL = re.compile(r'^\tlda (xbc|xhl), \(xhl \+ (\d+)\)$')
INC = re.compile(r'^\tinc (\d+), xhl$')
AND = re.compile(r'^\tand (c|a), (0x[0-9a-f]+)$')
LD_DST = re.compile(r'^\tld (c|a), \((xiz|xiy|xhl|xbc)\)$')
STORE = re.compile(r'^\tld \((xiz|xiy|xhl|xbc)\), (c|a)$')


def routine(ver, rel, label):
    txt = (ROOT / ver / "maincpu" / rel).read_bytes().decode("latin-1")
    m = re.search(r'^%s:\n(.*?)^\tret$' % re.escape(label), txt, re.S | re.M)
    return m.group(1).split("\n")


def patchtable_map(ver):
    base = tgt = None
    pend = None            # (param index, mask)
    reg_is_src = False
    m = {}
    for ln in routine(ver, "ui/bitmap_out_routines.s", "BitMapOut_ByteData_PatchTable"):
        if (x := LDA_ABS.match(ln)):
            base = tgt = int(x.group(1), 16)
        elif ln == "\tld xbc, xhl":
            tgt = base
        elif (x := LDA_REL.match(ln)):
            tgt = base + int(x.group(2))
            if x.group(1) == "xhl":
                base = tgt
        elif (x := INC.match(ln)):
            tgt = base + int(x.group(1))
        elif (x := LD_SRC.match(ln)):
            pend = [int(x.group(2) or 0), 0xFF]
            reg_is_src = True
        elif (x := AND.match(ln)) and pend and reg_is_src:
            pend[1] = int(x.group(2), 16)
        elif LD_DST.match(ln):
            reg_is_src = False
        elif (x := STORE.match(ln)) and pend and reg_is_src:
            m[pend[0]] = (tgt, pend[1])
            pend, reg_is_src = None, False
        elif ln.startswith("\torb_erp") and pend:
            m[pend[0]] = (tgt, pend[1])
            pend = None
    return m


def copyvoice_map(ver):
    """EffectMode_CopyVoiceParams: base 0xFA04 (part 03 payload)."""
    lines = routine(ver, "ui/ui_mode_handlers.s", "EffectMode_CopyVoiceParams")
    m, tgt, pend, src = {}, None, None, False
    for ln in lines:
        if ln == "\tlda xix, (0xfa04:16)" or ln == "\tld xbc, xix":
            tgt = 0xFA04
        elif (x := re.match(r'^\tlda xbc, \(xix \+ (\d+)\)$', ln)):
            tgt = 0xFA04 + int(x.group(1))
        elif (x := LD_SRC.match(ln)):
            pend, src = [int(x.group(2) or 0), 0xFF], True
        elif (x := AND.match(ln)) and pend and src:
            pend[1] = int(x.group(2), 16)
        elif LD_DST.match(ln) or ln == "\tld c, (xiy)":
            src = False
        elif (x := STORE.match(ln)) and pend and src:
            m[pend[0]] = (tgt, pend[1]); pend, src = None, False
        elif ln.startswith("\torb_erp") and pend:
            m[pend[0]] = (tgt, pend[1]); pend = None
    return m


def records():
    rom = (ROOT / "original_ROMs" / "kn5000_table_data.rom").read_bytes()
    return [rom[0x951000 - 0x800000 + 198 * i:0x951000 - 0x800000 + 198 * (i + 1)]
            for i in range(1000)]


FAIL = []


def check(cond, what):
    print(("  ok   " if cond else "  FAIL ") + what)
    if not cond:
        FAIL.append(what)


def main():
    as_json = "--json" in sys.argv
    tabs = {v: walker_table(v) for v in ("v10", "v9", "v7")}
    check(tabs["v10"][1] == tabs["v9"][1] == tabs["v7"][1],
          "WidgetStyleDataTable_0x2A8 is byte-identical in v10/v9/v7 (%d entries + terminator)"
          % len(tabs["v10"][0]))
    wm = walker_map(tabs["v10"][0])
    check(sorted(wm) == list(range(113)),
          "walker consumes parameter bytes 0..112 exactly (113 bytes, +0x4D..+0xBD)")
    pms = {v: patchtable_map(v) for v in ("v10", "v9", "v7")}
    check(pms["v10"] == pms["v9"] == pms["v7"],
          "BitMapOut_ByteData_PatchTable map identical in v10/v9/v7 (%d bytes)" % len(pms["v10"]))
    cvs = {v: copyvoice_map(v) for v in ("v10", "v9", "v7")}
    check(cvs["v10"] == cvs["v9"] == cvs["v7"],
          "EffectMode_CopyVoiceParams map identical in v10/v9/v7")
    pm, cv = pms["v10"], cvs["v10"]
    check(sorted(cv) == [29, 30, 31, 32, 33], "CopyVoiceParams reads parameter bytes 29..33")
    check(max(pm) == 112 and all(p in wm for p in pm),
          "every PatchTable source byte is also a walker byte (max index 112)")
    # agreement between the two general readers
    agree = [p for p in pm if pm[p][0] == wm[p][0]]
    disagree = [p for p in pm if pm[p][0] != wm[p][0]]
    check(disagree == [], "walker and PatchTable agree on the destination of every byte both copy (%d)"
          % len(agree))
    only_walker = sorted(set(wm) - set(pm))
    print("       bytes the walker copies and PatchTable does not: %s" % only_walker)
    cvdis = [p for p in cv if cv[p][0] != wm[p][0]]
    print("       CopyVoiceParams vs walker destination differs for bytes %s" % cvdis)
    check(cvdis == [29, 30], "the only walker/CopyVoiceParams disagreement is bytes 29,30")

    recs = records()
    P = lambda r, p: r[0x4D + p]
    check(all(r[0:8] == bytes([197, 0, 0, 0, 77, 0, 0, 0]) for r in recs),
          "all 1000 records: +0 = 197, +4 = 77")
    for p, v in ((2, 0), (6, 0), (12, 0), (16, 0), (22, 0), (26, 0), (52, 0), (60, 0),
                 (64, 0x80), (65, 0x80), (66, 0), (70, 0), (71, 0xEA), (75, 0), (101, 0)):
        check(all(P(r, p) == v for r in recs), "parameter byte %d is 0x%02X in all 1000" % (p, v))
    check(all(P(r, 69) <= 7 for r in recs), "style-number high byte (param 69) is 0..7 in all 1000")
    tempo_ok = [i for i, r in enumerate(recs)
                if int(r[0x48:0x4B].decode().strip()) == P(r, 74) | (P(r, 75) << 8)]
    check(len(tempo_ok) == 991, "tempo word (params 74/75) = display-string tempo in 991 of 1000")
    print("       the 9 that differ: %s" % [i for i in range(1000) if i not in tempo_ok])
    var_ok = [i for i, r in enumerate(recs) if P(r, 73) == (i % 4) << 4]
    check(len(var_ok) == 998, "param 73 (tag 48 +7) == (record index mod 4) << 4 in 998 of 1000")
    print("       exceptions: %s" % [i for i in range(1000) if i not in var_ok])
    trail = collections.Counter(r[0xBE] for r in recs)
    check(sorted(trail) == [0x40, 0x97, 0x99, 0xAD], "+0xBE takes exactly 0x40/0x97/0x99/0xAD")
    print("       +0xBE census: %s" % dict(trail))
    check(all(r[0xBF:0xC5] == b"\xff" * 6 for r in recs), "+0xBF..+0xC4 = 6 x 0xFF in all 1000")
    groups = collections.defaultdict(set)
    for r in recs:
        groups[r[0x18:0x28]].add(P(r, 68) | (P(r, 69) << 8))
    multi = {k.decode(): sorted(v) for k, v in groups.items() if len(v) > 1}
    check(len(multi) == 1, "style number is constant within a style name, except %s" % multi)

    rows = []
    for p in range(113):
        tag, off = where(wm[p][0])
        rows.append(dict(param=p, rec_off=0x4D + p, walker=(tag, off),
                         patch=(where(pm[p][0]) + ("0x%02X" % pm[p][1],)) if p in pm else None,
                         copyvoice=(where(cv[p][0]) + ("0x%02X" % cv[p][1],)) if p in cv else None))
    if as_json:
        print(json.dumps(rows, indent=1))
    else:
        print("\n param  rec   walker(tag,+off)  PatchTable(tag,+off,mask)  CopyVoiceParams")
        for r in rows:
            print("  %3d  +0x%02X  %s +%-2d       %-26s %s" % (
                r["param"], r["rec_off"], r["walker"][0], r["walker"][1],
                ("%s +%d & %s" % r["patch"]) if r["patch"] else "-",
                ("%s +%d & %s" % r["copyvoice"]) if r["copyvoice"] else ""))
    if FAIL:
        print("\nFAIL: %d check(s)" % len(FAIL))
        sys.exit(1)
    print("\nPASS")


if __name__ == "__main__":
    main()
