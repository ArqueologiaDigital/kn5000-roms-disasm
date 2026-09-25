#!/usr/bin/env python3
r"""Evidence headers for the nineteen MIDI-in 32-record parameter tables (0xFA84C8-0xFA8BA7).

QUESTION THIS ANSWERS
    What does each byte of MidiIn_CC40_ParamTable .. MidiIn_CC78_ParamTable
    represent, and how do we know?  Each table is read by exactly one MIDI-in
    controller handler, with the part number (0x1976) as the index; the reader
    turns the part's record into the PARAMETER ID it posts (the 4-byte record
    at RAM 0x1950: [number][sub][value][mask]).  The same parameter NUMBERS
    index MidiOut_ParamNumberTable, whose slots are named for the controller
    they send back out -- so every Bx number is tied to its controller twice,
    once from each direction.

CHECKS (against wsa1/original_ROMs, and the linked ELF for label addresses)
    R1  each table has exactly one `ld XIX,<table>` in the source, and the ROM
        holds `44 <table LE32>` at that site
    R2  every reader has `cp A,0x1F / jr ugt` between its entry and the site
        (the part bound, hence COUNT 32); stride-3 readers then have `ld BC,(XIX+HL)` (d3 07 f0 ec 21), `cp C,0xFF`,
        `inc 2,XIX` (ec 62), `ld D,(XIX+HL)` (c3 07 f0 ec 24), `ld E,(0x1942)`,
        `ld (0x1950),BC`, `ld (0x1952),DE`, in that order within 40 bytes
        stride-2 readers: `sll 1,A` (c9 ee 01) before, then `ld BC,(XIX+A)`
        (d3 03 f0 e0 21), `cp C,0xFF`, `ld E,(0x1942)`, `ld D,0x7F` (24 7f)
    R3  tables abut: each ends where the next begins, the last at 0xFA8BA8
        (MidiIn_ProgramChange_ParamTable)
    R4  the record values quoted in each header are recomputed from the ROM

RUN
    python3 notes/proma-2026-09-25/gen_midiin_param_headers.py          # checks + preview
    python3 notes/proma-2026-09-25/gen_midiin_param_headers.py --apply
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
TABLES = [  # (label, stride)
    ("MidiIn_CC40_ParamTable", 3), ("sub_FA64E5_ParamTable", 3), ("sub_FA6526_ParamTable", 3),
    ("MidiIn_CC01_ParamTable", 3), ("MidiIn_CC07_ParamTable", 3), ("MidiIn_CC0B_ParamTable", 3),
    ("MidiIn_CC0A_ParamTable", 3), ("MidiIn_CC5D_ParamTable", 3), ("MidiIn_CC5E_ParamTable", 3),
    ("MidiIn_CC5B_ParamTable", 3), ("MidiIn_CC02_ParamTable", 3), ("MidiIn_CC04_ParamTable", 3),
    ("MidiIn_CC10_ParamTable", 3), ("MidiIn_CC11_ParamTable", 3), ("MidiIn_CC12_ParamTable", 3),
    ("MidiIn_CC13_ParamTable", 3), ("MidiIn_CC51_ParamTable", 3), ("MidiIn_CC79_ParamTable", 2),
    ("MidiIn_CC78_ParamTable", 2),
]
END = 0xFA8BA8
MIDIOUT_TABLE = 0xFA8CC8        # MidiOut_ParamNumberTable, 192 LE32
MIDIOUT_CLASS = 0xFA7180        # MidiOut_ParamClassTable, read with the SUB for numbers 0..31


def label_addr(m, name):
    a = [x for x, ns in m.by_addr.items() if name in ns]
    assert len(a) == 1, name
    return a[0]


def find_after(rom, a, pat, span):
    i = rom.find(pat, a - B, a - B + span)
    return None if i < 0 else B + i


def names_at(m, a):
    return [n for n in m.labels_at(a) if not n.startswith(".")]


def routine_of(L, i):
    j = i
    while j > 0:
        mm = re.match(r'^([A-Za-z_][\w$]*):', L[j])
        if mm:
            return mm.group(1)
        j -= 1
    raise AssertionError(i)


def analyse(m):
    rom = m.rom
    L = m.lines
    out = []
    for k, (name, stride) in enumerate(TABLES):
        a = label_addr(m, name)
        nxt = label_addr(m, TABLES[k + 1][0]) if k + 1 < len(TABLES) else END
        assert nxt - a == 32 * stride, (name, hex(a), hex(nxt))                     # R3
        sites = [i for i, l in enumerate(L) if re.match(r'^\s+ld XIX,%s\s' % re.escape(name), l)]
        assert len(sites) == 1, (name, sites)                                         # R1
        si = sites[0]
        site = int(srcmap.ADDR.search(L[si]).group(1), 16)
        assert rom[site - B:site - B + 5] == b"\x44" + a.to_bytes(4, "little"), name
        rname = routine_of(L, si)
        raddr = label_addr(m, rname)
        assert find_after(rom, raddr, b"\xc9\xcf\x1f\x6b", site - raddr) is not None, name  # R2
        if stride == 3:                                                               # R2
            seq = [b"\xd3\x07\xf0\xec\x21", b"\xcb\xcf\xff", b"\xec\x62", b"\xc3\x07\xf0\xec\x24",
                   b"\xc1\x42\x19\x25", b"\xf1\x50\x19\x51", b"\xf1\x52\x19\x52"]
        else:
            assert find_after(rom, site - 3, b"\xc9\xee\x01", 3) == site - 3, name
            seq = [b"\xd3\x03\xf0\xe0\x21", b"\xcb\xcf\xff", b"\xc1\x42\x19\x25", b"\x24\x7f",
                   b"\xf1\x50\x19\x51", b"\xf1\x52\x19\x52"]
        p = site + 5
        for pat in seq:
            q = find_after(rom, p, pat, 40)
            assert q is not None, (name, pat.hex())
            p = q + len(pat)
        recs = [rom[a - B + stride * r:a - B + stride * r + stride] for r in range(32)]
        nums = sorted({r[0] for r in recs})
        subs = [r[1] for r in recs]
        masks = sorted({r[2] for r in recs}) if stride == 3 else None
        out.append(dict(name=name, addr=a, stride=stride, site=site, rname=rname, raddr=raddr,
                        recs=recs, nums=nums, subs=subs, masks=masks))
    return out


def describe(m, t):
    rom = m.rom
    recs, stride = t["recs"], t["stride"]
    part_is_sub = all(r[1] == p for p, r in enumerate(recs))
    part_is_num = all(r[0] == p for p, r in enumerate(recs))
    part_plus = all(r[0] == 0x20 + p for p, r in enumerate(recs))
    h = []
    if stride == 3:
        h.append("; %s -- 32 x 3-byte records, one per part: [number] [class] [mask]." % t["name"])
        h.append("; Read by: %s (0x%06X): the part (from (0x1976)) passes" % (t["rname"], t["raddr"]))
        h.append(";          `cp A,0x1F / jr ugt` (hence COUNT 32); `ld XIX,<this>` at")
        h.append(";          0x%06X with HL = part*3;" % t["site"])
        h.append(";          `ld BC,(XIX+HL)` -- C = 0xFF would skip the part -- then")
        h.append(";          `inc 2,XIX / ld D,(XIX+HL)`, E = the controller value (0x1942),")
        h.append(";          and BC / DE become the parameter-change record at RAM 0x1950:")
        h.append(";          [number = C] [class = B] [value = E] [mask = D] -- the")
        h.append(";          (0x1958) number / (0x1959) class of MidiOut_DispatchByClass.")
    else:
        h.append("; %s -- 32 x 2-byte records, one per part: [number] [class]." % t["name"])
        h.append("; Read by: %s (0x%06X): the part (from (0x1976)) passes" % (t["rname"], t["raddr"]))
        h.append(";          `cp A,0x1F / jr ugt` (hence COUNT 32); `sll 1,A` and")
        h.append(";          `ld XIX,<this>` at 0x%06X," % t["site"])
        h.append(";          `ld BC,(XIX+A)` -- C = 0xFF would skip the part -- then")
        h.append(";          E = the controller value (0x1942), D = 0x7F, and BC / DE become")
        h.append(";          the parameter-change record at RAM 0x1950.")
    n0 = recs[0][0]
    if part_is_sub and len(t["nums"]) == 1:
        tgt = int.from_bytes(rom[MIDIOUT_TABLE - B + 4 * n0:MIDIOUT_TABLE - B + 4 * n0 + 4], "little")
        tn = m.best_label(tgt) or ("0x%06X" % tgt)
        h.append("; Here:    number 0x%02X for every part, class = the part (0..31)%s."
                 % (n0, ", mask 0x%02X" % t["masks"][0] if t["masks"] else ""))
        if tn != "MidiOut_Param_Ignore":
            h.append(";          MidiOut_ParamNumberTable[0x%02X] = %s: the number goes" % (n0, tn))
            h.append(";          back out through the handler named for the same message.")
    elif part_is_num and len(set(t["subs"])) == 1:
        s = recs[0][1]
        tgt = int.from_bytes(rom[MIDIOUT_CLASS - B + 4 * s:MIDIOUT_CLASS - B + 4 * s + 4], "little")
        tn = m.best_label(tgt) or ("0x%06X" % tgt)
        h.append("; Here:    number = the part (0..31), class 0x%02X for every part, mask 0x%02X:"
                 % (s, t["masks"][0]))
        h.append(";          a PART parameter.  MidiOut_ParamClassTable[0x%02X], which" % s)
        h.append(";          MidiOut_DispatchByClass indexes with that class, is")
        h.append(";          %s." % tn)
    elif part_plus and len(set(t["subs"])) == 1:
        h.append("; Here:    number = 0x20 + the part, class 0x%02X, mask 0x%02X for every part."
                 % (recs[0][1], t["masks"][0]))
        tgt = int.from_bytes(rom[MIDIOUT_TABLE - B + 4 * 0x20:MIDIOUT_TABLE - B + 4 * 0x20 + 4], "little")
        h.append(";          MidiOut_ParamNumberTable[0x20..0x3F] are all %s." % (m.best_label(tgt),))
    else:
        raise AssertionError(t["name"])
    if t["name"].startswith("sub_"):
        h.append("; ⚠ Which controller this is is not established: its handler's slot is")
        h.append(";          reached by no controller number (see that handler's header),")
        h.append(";          and MidiOut_ParamNumberTable[0x%02X] is MidiOut_Param_Ignore." % n0)
    h.append("; (header: notes/proma-2026-09-25/gen_midiin_param_headers.py, checks R1-R4)")
    return h


def main():
    m = srcmap.load()
    T = analyse(m)
    print("R1-R3 ok: %d tables, one reader each, shapes as stated, abutting to 0x%06X" % (len(T), END))
    blocks = {t["name"]: describe(m, t) for t in T}
    if "--apply" not in sys.argv:
        for t in T[:2] + T[4:5] + T[16:18]:
            print("\n".join(blocks[t["name"]]))
            print()
        return
    L = m.lines
    for name, hdr in blocks.items():
        i = L.index(name + ":")
        dash = "; ---------------------------------------------------------------------"
        assert L[i - 1] != dash, name          # no header there yet
        L[i:i] = [x.encode("utf-8").decode("latin-1") for x in [dash] + hdr + [dash]]
    open(srcmap.SRC, "w", encoding="latin-1", newline="").write("\n".join(L))
    print("applied")


if __name__ == "__main__":
    main()
