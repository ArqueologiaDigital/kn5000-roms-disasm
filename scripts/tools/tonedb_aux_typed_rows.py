#!/usr/bin/env python3
"""Re-emit the tone database's per-record objects as typed, reader-annotated rows.

QUESTION THIS ANSWERS
    table_data/tone_database_aux.s spells four large families of records as
    anonymous 16-byte `.byte` rows under a descriptive label, with the layout
    stated once in a section header:
      * ToneSet_NNN_KeyMap / _Zones  974 chunks: each SET's key map and zone records
        (named ToneEnv_RecNNN_A / _B before 2026-09-25,
        scripts/renaming/rename_tonedb_set_chunks.sed)
      * DrawbarPreset_EnvData_0..2  the drawbar SETs' zone records
      * DrumKit_NN_*            26 drum-kit records
      * PercInst_NNN_*          610 drum-instrument (sub-tone) records
    The subcpu readers that consume them are known (cited in the section
    headers and in notes/tonedb-2026-09-25/README.md), so each object can be
    spelled in its record structure: a zone record is one typed row
    (ToneSetZone4 / ToneSetZone6 macros = .short selector, .byte field, .byte
    trim [, .short coarse]); a key map is `.long <curve label> - ToneDB_Base`
    plus its band->zone bytes; a drum kit is its head plus 128 (wave, slot)
    note pairs with the drum instrument each note resolves to; and every object
    gets a two-line header with its own decoded facts.

    Every object's OLD rows are parsed and checked against the ROM bytes at the
    label's address (from the table-data ELF) before anything is replaced, and
    the NEW rows are re-parsed (macros expanded) and checked again.  The byte
    gate is still the certificate.  Idempotent: re-running re-derives the same
    text.

RUN
    make rebuilt_ROMs/kn5000_table_data.llvm.elf        # symbol addresses
    python3 scripts/tools/tonedb_aux_typed_rows.py            # dry run
    python3 scripts/tools/tonedb_aux_typed_rows.py --write    # rewrite the file
"""
import collections
import pathlib
import re
import struct
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "table_data" / "tone_database_aux.s"
ROM = (ROOT / "original_ROMs" / "kn5000_table_data.rom").read_bytes()
ELF = ROOT / "rebuilt_ROMs" / "kn5000_table_data.llvm.elf"
NM = pathlib.Path.home() / "compartilhado/llvm-project/build/bin/llvm-nm"
B, DB = 0x800000, 0x830000
COL = 88

u8 = lambda a: ROM[a - B]
u16 = lambda a: struct.unpack_from("<H", ROM, a - B)[0]
u32 = lambda a: struct.unpack_from("<I", ROM, a - B)[0]
blob = lambda a, n: ROM[a - B:a - B + n]
dslot = lambda s: DB + u32(DB + s)

MACROS = """\
; Typed zone-record rows (ToneSet_*_Zones and DrawbarPreset_EnvData_*): one row =
; one zone record, fields as documented in the ToneEnv chunk header below.
;   ToneSetZone4  selector (LE16), level-field byte, s8 fine trim
;   ToneSetZone6  the same + s16 coarse trim (8.8 semitones)
.macro ToneSetZone4 sel, fld, trim
	.short	\\sel
	.byte	\\fld, \\trim
.endm
.macro ToneSetZone6 sel, fld, trim, coarse
	.short	\\sel
	.byte	\\fld, \\trim
	.short	\\coarse
.endm
; One SET descriptor (ToneDB_EnvDescTable, 15 bytes): flags, key-map and
; zone-record chunk labels, key range lo..hi, root key, LE16 base pitch, +0x0E.
.macro ToneSetDesc flags, keymap, zones, lo, hi, root, pitch, e
	.byte	\\flags
	.long	\\keymap - ToneDB_Base, \\zones - ToneDB_Base
	.byte	\\lo, \\hi, \\root
	.short	\\pitch
	.byte	\\e
.endm
"""
MACRO_MARK = ".macro ToneSetZone4 sel, fld, trim"
DESC_MARK = ".macro ToneSetDesc flags, keymap, zones"


def pad(code, comment, col=COL):
    w = len(code.expandtabs(8))
    return code + "\t" * max(1, (col - w + 7) // 8) + "; " + comment


def syms():
    out = subprocess.run([str(NM), "--defined-only", str(ELF)], capture_output=True,
                         text=True, check=True).stdout
    d = {}
    for ln in out.splitlines():
        a, t, n = ln.split(None, 2)
        d[n] = int(a, 16)            # table_data ELF symbols are absolute (0x8xxxxx)
    return d


# ---------------------------------------------------------------- spelling
NUM = r'-?(?:0x[0-9a-fA-F]+|\d+)'


def spell(lines, sym):
    out = bytearray()
    for ln in lines:
        code = ln
        q = False
        for i, ch in enumerate(ln):
            if ch == '"':
                q = not q
            elif ch == ";" and not q:
                code = ln[:i]
                break
        code = code.strip()
        if not code:
            continue
        op, _, args = code.partition("\t")
        op = op.strip()
        args = args.strip()
        if op == ".ascii":
            out += args.strip('"').encode("latin-1")
        elif op == ".byte":
            out += bytes(int(v, 0) & 0xFF for v in re.findall(NUM, args))
        elif op == ".short":
            for v in re.findall(NUM, args):
                out += (int(v, 0) & 0xFFFF).to_bytes(2, "little")
        elif op == ".long":
            for part in args.split(","):
                part = part.strip()
                m = re.fullmatch(r'(\w+) - ToneDB_Base', part)
                if m:
                    out += (sym[m.group(1)] - DB).to_bytes(4, "little")
                else:
                    out += (int(part, 0) & 0xFFFFFFFF).to_bytes(4, "little")
        elif op == "ToneSetDesc":
            a = [x.strip() for x in args.split(",")]
            out.append(int(a[0], 0))
            out += (sym[a[1]] - DB).to_bytes(4, "little") + (sym[a[2]] - DB).to_bytes(4, "little")
            out += bytes([int(a[3], 0), int(a[4], 0), int(a[5], 0)])
            out += int(a[6], 0).to_bytes(2, "little") + bytes([int(a[7], 0)])
        elif op in ("ToneSetZone4", "ToneSetZone6"):
            v = [int(x, 0) for x in re.findall(NUM, args)]
            out += (v[0] & 0xFFFF).to_bytes(2, "little") + bytes([v[1] & 0xFF, v[2] & 0xFF])
            if op == "ToneSetZone6":
                out += (v[3] & 0xFFFF).to_bytes(2, "little")
        else:
            raise SystemExit("cannot spell %r" % ln)
    return bytes(out)


def s8(x):
    return x - 256 if x & 0x80 else x


def s16(x):
    return x - 0x10000 if x & 0x8000 else x


# ---------------------------------------------------------------- the database
def load():
    D = {}
    desc = DB + u32(DB + 0x30)
    D["desc"] = []
    for i in range(487):
        b = blob(desc + 15 * i, 15)
        D["desc"].append(dict(i=i, f=b[0], A=DB + u32(desc + 15 * i + 1), B=DB + u32(desc + 15 * i + 5),
                              lo=b[9], hi=b[10], root=b[11], bp=u16(desc + 15 * i + 12), e=b[14]))
    offs = sorted([d["A"] for d in D["desc"]] + [d["B"] for d in D["desc"]])
    end = {v: (offs[k + 1] if k + 1 < len(offs) else 0x863079) for k, v in enumerate(offs)}
    D["end"] = end
    D["curves"] = [0x85AD9D + 128 * k for k in range(6)]
    D["nmA"], D["pi"], D["pstride"] = dslot(0x74), dslot(0x78), u16(DB + 0xEE)
    D["pname"] = [blob(D["pi"] + D["pstride"] * k, 13).decode("latin-1").rstrip() for k in range(610)]
    # kits and who selects them
    offt = [u32(0x831B00 + 4 * i) for i in range(629)]
    D["kits"] = []
    selmap = {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 0x40, 9: 0x41, 10: 0x70}
    for k in range(26):
        a = 0x863079 + 295 * k
        tns = [i for i, o in enumerate(offt) if DB + o == a]
        progs = [(selmap[bk], p) for bk in range(11) for p in range(128)
                 if u16(0x830180 + 2 * (bk * 128 + p)) in tns]
        D["kits"].append(dict(k=k, a=a, name=blob(a, 16).decode().strip(), tone=tns, progs=progs))
    # which PercInst each kit note resolves to (ToneDB_Resolve_NamedToneRecord)
    D["uses"] = collections.defaultdict(list)
    for kit in D["kits"]:
        notes = []
        for n in range(128):
            lo, hi = u8(kit["a"] + 0x27 + 2 * n), u8(kit["a"] + 0x28 + 2 * n)
            assert hi & 0xE0 == 0 and lo < 0x80
            pidx = u16(D["nmA"] + 2 * (((hi & 0x1F) << 7) | lo))
            notes.append((lo, hi, pidx))
            D["uses"][pidx].append((kit["name"], n))
        kit["notes"] = notes
    D["nmA_refs"] = collections.Counter(u16(D["nmA"] + 2 * i) for i in range(4096))
    return D


# ---------------------------------------------------------------- emitters
def emit_A(d, D, sym):
    a = d["A"]
    n = D["end"][a] - a
    kt = DB + u32(a)
    k = D["curves"].index(kt)
    bands = list(blob(a + 4, n - 4))
    stride = 6 if d["f"] & 0x80 else 4
    nz = (D["end"][d["B"]] - d["B"]) // stride
    hdr = ["; SET %03d key map (descriptor %03d: flags 0x%02x, keys %d..%d): key->band table "
           "ToneDB_VelocityCurve_%d," % (d["i"], d["i"], d["f"], d["lo"], d["hi"], k),
           "; %d bands -> zone index 0..%d of %d.  Walked by WaveSel_StageB_Build_Reg040 "
           "(0x023849); layout above." % (len(bands), max(bands), nz)]
    rows = [pad("\t.long\tToneDB_VelocityCurve_%d - ToneDB_Base" % k, "+0x00 key -> band table")]
    for r in range(0, len(bands), 16):
        chunk = bands[r:r + 16]
        rows.append(pad("\t.byte\t" + ", ".join("%3d" % v for v in chunk),
                        "+0x%02x bands %d-%d -> zone" % (4 + r, r, r + len(chunk) - 1)))
    return hdr, rows


def zone_rows(a, count, stride, comment):
    rows = []
    for z in range(count):
        r = a + stride * z
        sel, fld, trim = u16(r), u8(r + 2), s8(u8(r + 3))
        if stride == 6:
            co = s16(u16(r + 4))
            rows.append(pad("\tToneSetZone6\t0x%04x, 0x%02x, %d, %d" % (sel, fld, trim, co),
                            comment(z) + ", coarse %+.2f st" % (co / 256.0)))
        else:
            rows.append(pad("\tToneSetZone4\t0x%04x, 0x%02x, %d" % (sel, fld, trim), comment(z)))
    return rows


def emit_B(d, D, sym):
    a = d["B"]
    stride = 6 if d["f"] & 0x80 else 4
    n = D["end"][a] - a
    assert n % stride == 0
    cnt = n // stride
    sels = [u16(a + stride * z) for z in range(cnt)]
    hdr = ["; SET %03d zone records: %d x %d bytes (descriptor flags bit 7 %s), selectors "
           "0x%04x..0x%04x;" % (d["i"], cnt, stride, "set" if stride == 6 else "clear",
                                min(sels), max(sels)),
           "; emitted by WaveSel_Emit_ZoneRecord_S%d (0x%06X) -- fields in the chunk header above."
           % (stride, 0x022AC5 if stride == 6 else 0x022AE7)]
    return hdr, zone_rows(a, cnt, stride, lambda z: "zone %d" % z)


def emit_drawbar(label, D, sym):
    a = sym[label]
    k = int(label[-1])
    nxt = {0: "DrawbarPreset_EnvData_1", 1: "DrawbarPreset_EnvData_2", 2: "ToneDB_SourceNameList1"}[k]
    n = sym[nxt] - a
    cnt = n // 6
    users = [i for i in range(4) if DB + u32(0x870A11 + 15 * i + 5) == a]
    if cnt == 729:
        hdr = ["; Drawbar SET zone records for DrawbarPreset_EnvDescTable record(s) %s: 729 x 6 = 9*9*9,"
               % "/".join(map(str, users)),
               "; row = d2*81 + d1*9 + d0 (Voice_KeyIndex_Pack3Nibbles 0x02B2C2, three base-9 digits)."]
        com = lambda z: "digits %d%d%d" % (z // 81, z // 9 % 9, z % 9)
    else:
        hdr = ["; Drawbar SET zone records for DrawbarPreset_EnvDescTable record(s) %s: %d x 6 bytes,"
               % ("/".join(map(str, users)), cnt),
               "; indexed by WaveSel_StageB_Build_Reg040_Footage (0x0238F8) with stride 6 (header above)."]
        com = lambda z: "row %d" % z
    return hdr, zone_rows(a, cnt, 6, com)


def emit_kit(label, D, sym):
    k = int(label.split("_")[1])
    kit = D["kits"][k]
    assert kit["a"] == sym[label], label
    progs = ", ".join("sel 0x%02x prog %d" % p for p in kit["progs"])
    hdr = ["; Drum kit %02d \"%s\": tone number %s, chosen by bank %s." % (
               k, kit["name"], "/".join(map(str, kit["tone"])), progs),
           "; Part mode 0x80 (Voice_SetVelocity); note n -> PercInst via the pair at +0x27+2n (see header)."]
    a = kit["a"]
    rows = ['\t.ascii\t"%s"' % blob(a, 16).decode()]
    rows.append(pad("\t.byte\t0x%02x" % u8(a + 0x10), "+0x10 part mode 0x80 = drum kit"))
    rows.append(pad("\t.byte\t0x%02x" % u8(a + 0x11), "+0x11 varies 0..6 across kits; no reader found"))
    rows.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(a + 0x12, 0x15)),
                    "+0x12..+0x26 identical in all 26 kits"))
    for r in range(0, 128, 8):
        pairs = kit["notes"][r:r + 8]
        names = []
        for lo, hi, p in pairs:
            nm = D["pname"][p]
            names.append("-" if nm == "Silent" else nm)
        rows.append(pad("\t.byte\t" + ", ".join("0x%02x, 0x%02x" % (lo, hi) for lo, hi, _ in pairs),
                        "n%d-%d: %s" % (r, r + 7, ", ".join(names)), col=104))
    return hdr, rows


def emit_perc(label, old, D, sym):
    k = int(label.split("_")[1])
    a = D["pi"] + D["pstride"] * k
    assert a == sym[label], label
    m = u8(a + 0x0D)
    lay = "layers 0 and 1" if m & 0x04 else "layer 0 only"
    fx = ", bit 5 fixed-level" if m & 0x20 else ""
    uses = D["uses"].get(k, [])
    if uses:
        shown = ", ".join("%s n%d" % u for u in uses[:3])
        more = " +%d more" % (len(uses) - 3) if len(uses) > 3 else ""
        u = "played by %d kit note(s): %s%s." % (len(uses), shown, more)
    else:
        u = "played by none of the 26 kits (DrumKit_NoteMapA refs: %d)." % D["nmA_refs"][k]
    hdr = ["; PercInst %03d \"%s\": drum-instrument record, mask 0x%02x = %s%s;" % (
               k, D["pname"][k], m, lay, fx),
           "; %s  Layout and readers: section header." % u]
    # keep the old lines, only add a trailing comment where there is none
    notes = ["+0x00 name (13 chars)", "+0x0d layer mask, +0x0e, +0x0f",
             "+0x10 layer 0 (paramA = rec+0x10)", "+0x25 layer 1 (paramA = rec+0x25)"]
    rows = []
    for i, ln in enumerate(old):
        if ";" in ln.split('"')[-1] or i >= len(notes):
            rows.append(ln)
        else:
            rows.append(pad(ln, notes[i], col=112 if i >= 2 else 40))
    return hdr, rows


def _records_tool():
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "tonedb_records_typed_rows", ROOT / "scripts" / "tools" / "tonedb_records_typed_rows.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def emit_drawbar_tone(label, D, sym):
    """DrawbarPreset_Jazz/_Rock: 426-byte tone records, part mode 0x40, all four
    partial blocks bound unpacked (bank selector 0x70 >= 0x10)."""
    R = _records_tool()
    a = sym[label]
    tone = {"DrawbarPreset_Jazz": 336, "DrawbarPreset_Rock": 337}[label]
    hdr = ["; Tone record %d \"%s\" (bank selector 0x70; program 1 -> 337, the other programs -> 336):"
           % (tone, blob(a, 16).decode().strip()),
           "; part mode 0x40, partial mask 0x%02x; 426 bytes = 21 + 5*81, partials 0-3 in blocks 1-4 (header above)."
           % u8(a + 0x11)]
    rows = ['\t.ascii\t"%s"' % blob(a, 16).decode()]
    rows.append(pad("\t.byte\t0x%02x" % u8(a + 0x10), "+0x10 part-mode byte: mode 0x40 (bits 7:6), bits 5:4 = %d"
                    % (u8(a + 0x10) >> 4 & 3), col=112))
    rows.append(pad("\t.byte\t0x%02x" % u8(a + 0x11), "+0x11 partial mask (selector 0x70: only partial 0 is tested)",
                    col=112))
    rows.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(a + 0x12, 3)), "+0x12..+0x14", col=112))
    rows.append("\t; common block")
    for lo, hi, txt in R.COMMON_GROUPS:
        rows.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(a + lo, hi - lo + 1)),
                        "+0x%02x %s" % (lo, txt), col=112))
    for blk in range(4):
        base = a + 0x66 + 0x51 * blk
        rows.append("\t; partial %d block (unpacked binding: partial p -> block p)" % blk)
        for lo, hi, txt in R.GROUPS:
            rows.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(base + lo, hi - lo + 1)),
                            "+0x%02x blk+0x%02x %s" % (base - a + lo, lo, txt), col=112))
    return hdr, rows


def emit_default_block(label, D, sym):
    """ToneDB_DefaultLayerParams (dir +0xAC): the partial block bound to an absent
    partial -- same seven field groups as a tone record's partial blocks."""
    R = _records_tool()
    a = sym[label]
    rows = []
    for lo, hi, txt in R.GROUPS:
        rows.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(a + lo, hi - lo + 1)),
                        "blk+0x%02x %s" % (lo, txt), col=112))
    return [], rows


LABEL = re.compile(r'^(ToneSet_(\d{3})_(KeyMap|Zones)|DrumKit_\d\d_\w+|PercInst_\d{3}_\w+|'
                   r'DrawbarPreset_EnvData_\d|DrawbarPreset_Jazz|DrawbarPreset_Rock|ToneDB_DefaultLayerParams):\s*$')
MY_HEADERS = [re.compile(x) for x in (
    r'^; SET \d{3} (key map|zone records)', r'^; \d+ bands -> zone index',
    r'^; emitted by WaveSel_Emit_ZoneRecord', r'^; Drawbar SET zone records for',
    r'^; row = d2\*81', r'^; indexed by WaveSel_StageB_Build_Reg040_Footage',
    r'^; Drum kit \d\d "', r'^; Part mode 0x80 \(Voice_SetVelocity\)',
    r'^; PercInst \d{3} "', r'^; played by ', r'^; Tone record 33[67] "',
    r'^; part mode 0x40, partial mask')]


def is_my_header(ln):
    return any(r.match(ln) for r in MY_HEADERS)


def main():
    write = "--write" in sys.argv
    sym = syms()
    D = load()
    descs = {d["i"]: d for d in D["desc"]}
    lines = SRC.read_bytes().decode("latin-1").split("\n")
    out = []
    i = 0
    n_obj = collections.Counter()
    changed = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("ToneDB_EnvDescTable:"):
            out.append(ln)
            i += 1
            base = sym["ToneDB_EnvDescTable"]
            for k in range(487):
                d = D["desc"][k]
                if lines[i].lstrip().startswith("ToneSetDesc"):
                    old = [lines[i]]
                    i += 1
                else:
                    old = lines[i:i + 3]
                    i += 3
                want = spell(old, sym)
                if want != blob(base + 15 * k, 15):
                    raise SystemExit("EnvDescTable record %d: old rows do not spell the ROM" % k)
                cmt = old[0].split(";", 1)[1].strip() if ";" in old[0] else str(k)
                code = "\tToneSetDesc\t0x%02x, ToneSet_%03d_KeyMap, ToneSet_%03d_Zones, %d, %d, 0x%02x, 0x%04x, %d" % (
                    d["f"], k, k, d["lo"], d["hi"], d["root"], d["bp"], d["e"])
                assert sym["ToneSet_%03d_KeyMap" % k] == d["A"] and sym["ToneSet_%03d_Zones" % k] == d["B"]
                row = code + "\t; " + cmt
                if spell([row], sym) != want:
                    raise SystemExit("EnvDescTable record %d: new row spells different bytes" % k)
                if [row] != old:
                    changed += 1
                out.append(row)
            n_obj["EnvDesc"] += 487
            continue
        m = LABEL.match(ln)
        if not m:
            out.append(ln)
            i += 1
            continue
        label = m.group(1)
        j = i + 1
        # an object runs until a blank line, a column-0 comment or the next
        # label; indented comments ("\t; common block") belong to it
        while j < len(lines) and lines[j].strip() and not lines[j].startswith(";") \
                and not re.match(r'^[A-Za-z_][\w.]*:', lines[j]):
            j += 1
        old = lines[i + 1:j]
        addr = sym[label]
        if label.startswith("ToneSet_"):
            d = descs[int(m.group(2))]
            assert addr == (d["A"] if m.group(3) == "KeyMap" else d["B"]), label
            hdr, rows = (emit_A if m.group(3) == "KeyMap" else emit_B)(d, D, sym)
            kind = "ToneEnv"
        elif label == "ToneDB_DefaultLayerParams":
            hdr, rows = emit_default_block(label, D, sym)
            kind = "DefaultBlock"
        elif label in ("DrawbarPreset_Jazz", "DrawbarPreset_Rock"):
            hdr, rows = emit_drawbar_tone(label, D, sym)
            kind = "DrawbarTone"
        elif label.startswith("DrawbarPreset"):
            hdr, rows = emit_drawbar(label, D, sym)
            kind = "Drawbar"
        elif label.startswith("DrumKit"):
            hdr, rows = emit_kit(label, D, sym)
            kind = "DrumKit"
        else:
            hdr, rows = emit_perc(label, old, D, sym)
            kind = "PercInst"
        want = spell(old, sym)
        if want != blob(addr, len(want)):
            raise SystemExit("%s: old rows do not spell the ROM bytes" % label)
        got = spell(rows, sym)
        if got != want:
            raise SystemExit("%s: new rows spell different bytes (%d vs %d)" % (label, len(got), len(want)))
        while out and is_my_header(out[-1]):
            out.pop()
        out += hdr
        out.append(ln)
        out += rows
        if rows != old:
            changed += 1
        n_obj[kind] += 1
        i = j
    text = "\n".join(out)
    if MACRO_MARK in text and DESC_MARK not in text:
        zend = text.index(".endm\n", text.index(".macro ToneSetZone6")) + len(".endm\n")
        dm = MACROS[MACROS.index("; One SET descriptor"):]
        text = text[:zend] + dm + text[zend:]
    if MACRO_MARK not in text:
        anchor = "\t.org 0x855A48 - 0x800000, 0xff\n"
        assert text.count(anchor) == 1
        text = text.replace(anchor, anchor + "\n" + MACROS)
    print(dict(n_obj), "objects;", changed, "with changed rows")
    if write:
        SRC.write_bytes(text.encode("latin-1"))
        print("wrote", SRC.relative_to(ROOT))
    else:
        print("dry run; pass --write")


if __name__ == "__main__":
    main()
