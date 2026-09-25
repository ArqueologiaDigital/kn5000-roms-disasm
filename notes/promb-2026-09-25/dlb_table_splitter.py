#!/usr/bin/env python3
r"""Type prom_b `Data_*` objects that interpreter-B display-list records read as tables.

QUESTION THIS ANSWERS
    Many `Data_*` objects in prom_b's display-list region were emitted by the
    coverage walk as `.byte` rows with no layout ("EMITTED AS DATA", "the
    extent is the walk's, not the object's"), although interpreter-B records
    point INTO them.  Those records are the readers, and they fix the layout:

      op 0x02 (15 bytes) and op 0x07 (17 bytes) -- DLB_Handler_StringTable /
          DLB_Handler_StringTable2: +0x07 is a string table, +0x0B the bytes
          per entry, +0x06 the swi 7 text service that draws entry [value];
      op 0x03 and 0x08 (11 bytes) -- DLB_Handler_Array8: +0x07 is an array of
          8-byte entries, four words copied to (0x2530)..(0x2536) -- for the
          fill/erase services 0x05 / 0x1B the inclusive box left, top, right,
          bottom in pixels (LCD_Svc_05_FillRect / LCD_Svc_1B_EraseRect);
      op 0x04 (11 bytes) -- DLB_Handler_Array6: 6-byte entries -> IY, BC, HL.

    `value` is DisplayListB_ExtractField's `((byte at +2) AND +4) >> (+5 AND 7)`,
    so the record's mask bounds the index: it admits `(mask >> shift) + 1`
    entries.

    For each object this script
      * scans prom_b for every B record of those shapes whose +0x07 lands in the
        object, and requires the set of addresses they name to be exactly the
        set of `.long <obj> [+ off]  ; +0x07 ->` fields the source spells (so a
        stray byte pattern cannot invent a table);
      * cuts the object at those addresses.  A piece's entry count is the
        distance to the next piece (or the object's end) over the width, capped
        at the number of entries the readers' masks admit; for a text-service
        table it also stops at the first entry holding a 0x00 byte when every
        entry after it does too (the fixed-width text ends there).  Bytes a cap
        leaves over get their own `Data_<addr>` label and a header saying so;
      * types a chunk in front of the first piece (or left over after one) as a
        32-bit pointer array when every long in it is a B-record start and
        RunDisplayListBFromPointerArray (0xF09AE1) is called on its address
        (`ld XIY,<addr>` / `call 0xF09AE1`, found in prom_b and prom_a bytes);
      * records, from the ROM bytes, every `ld XIX,<addr>` / `call
        T_DisplayList[B]_Run` pair that uses a piece's address as the END of a
        display list -- the code references the old headers listed are mostly
        that, not reads of the bytes;
      * REFUSES an object whose readers disagree on a piece's width or kind, a
        piece that is not whole entries, or a header not in the coverage walk's
        standard form.
      With --apply it keeps the old header (correcting only its extent sentence
      and naming the span by address instead of the retired label), emits typed
      rows -- `.ascii` for printable entries of an ASCII-font table (services
      0x06 / 0x07 / 0x17 / 0x20), `.byte` for glyph codes, decimal `.short` box
      coordinates, `.long` pointers -- and rewrites `<obj> + off` references.

RUN
    python3 notes/promb-2026-09-25/dlb_table_splitter.py [LABEL ...]           # dry run: the plan
    python3 notes/promb-2026-09-25/dlb_table_splitter.py --apply [LABEL ...]
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
    make gate-wsa1
    python3 scripts/analysis/assert_comments_preserved.py --base HEAD \
        --rename-map notes/promb-2026-09-25/dlb_table_splitter.map wsa1/prom_b/wsa1_prom_b.s
      -> the only comments it reports are the replaced objects' `; ADDR |..|` byte-dump
         comments, their `Data_X -- N bytes, EMITTED AS DATA` first lines (now the
         address range) and the corrected extent sentence (the checker's rename of
         `Data_F05AB4` inside the kept history sentence shows as one more).
    On commit a57ab5d9 the first three commands reproduce the source as of the
    commit after 5ad3922c ("range and count", which changed two header lines by hand
    and this rule to match) byte for byte.
    With no LABEL it takes every `Data_*` object of prom_b that the census files as
    a research target and a B record reads.
"""
import json
import os
import re
import subprocess
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE, BASE_A = 0xF00000, 0xF80000
REC_LEN = {2: 15, 7: 17, 3: 11, 8: 11, 4: 11}
KIND = {2: "text", 7: "text", 3: "box", 8: "box", 4: "area"}
ASCII_FONTS = {0x06, 0x07, 0x17, 0x20}
FN = {0x05: "LCD_Svc_05_FillRect", 0x1B: "LCD_Svc_1B_EraseRect", 0x06: "LCD_Svc_06_DrawText8x14",
      0x07: "LCD_Svc_07_DrawText8x16", 0x17: "LCD_Svc_17_DrawText8x8Packed",
      0x20: "LCD_Svc_20_DrawText8x10", 0x1C: "LCD_Svc_1C_DrawText16x16Packed",
      0x08: "LCD_Svc_08_DrawText16x16", 0x09: "LCD_Svc_09_DrawBox", 0x13: "LCD_Svc_13_DrawBoxPatterned"}
RUN_PTR_ARRAY = 0xF09AE1
REG32 = ("XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP")
IMM = {}   # addr -> [(site, reg)]: every `ld <r32>,<addr>` 32-bit immediate in prom_b/prom_a bytes
# Names chosen from each table's own entries (the auto name is the fallback).
NAMES = {
    0xF04DB7: "DLText_Minus6ToPlus9By3",
    0xF04DC3: "DLText_Minus12ToPlus18By6",
    0xF04DD5: "DLText_DashesMinus6ToPlus6",
    0xF05469: "DLText_SinTriSqrSaw",
    0xF05801: "DLText_UserDrumKits",
    0xF05B60: "DLText_NoteNamesCm2ToG8",
    0xF05CF8: "DLText_Frequencies65HzTo48K",
    0xF06598: "DLText_OffMainSub1To3",
    0xF28522: "DLText_PanL64CtrR63",
    0xF297A0: "DLText_PartCodes",
    0xF32A4E: "DLText_CtrLRRdm",
    0xF34E88: "DLText_P1ToP32",
    0xF3A6F9: "DLText_0To16All",
    0xF3A72F: "DLText_0To16MasterAll",
    0xF3A7A1: "DLText_0To17All",
    0xF3AD7A: "DLText_GlyphPairs_F3AD7A",
    0xF3B095: "DLText_NoteNamesInOctave",
    0xF3B0AD: "DLText_OctavesMinus2To8",
    0xF3C53F: "DLText_ChordApcControlRhythm",
}
LIST_RUNNERS = {0xF417F0: "T_DisplayList_Run", 0xF417F4: "T_DisplayListB_Run"}
# Objects the rules above would cut but that another layout already accounts for.
SKIP = {
    # 0xF2B422 onwards is typed by the "tail of a word array" block below it, which
    # puts a 16-byte word array at 0xF2B41F -- inside this object's last 8-byte
    # entry by this script's rule.  Left to that block's author.
    "Data_F2B38F",
}
HISTORY = [
    ("; span.  The first 12 bytes used to be the tail of Data_F05AB4, the last\n"
     "; 12 were the `.incbin` at file offset 0x005CEC.\n",
     "; span.  The first 12 bytes used to be the tail of Data_F05AB4, the last\n"
     "; 12 were the `.incbin` at file offset 0x005CEC.\n"
     "; (Data_F05AB4 is now DLBoxes_F05AB4, Data_F05B34 and\n"
     "; DLText_NoteNamesCm2ToG8 -- notes/promb-2026-09-25/dlb_table_splitter.py.)\n"),
]
OLD_EXTENT = ("; ⚠ The extent is the reachability walk's, not the object's; the rest of\n"
              ";   this span is unreachable and stays `.incbin`.  Why this is data and\n"
              ";   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.")
NEW_EXTENT = ("; ⚠ CORRECTED: that extent came from the coverage walk, not from the object;\n"
              ";   the display-list records that read these bytes now fix the pieces below\n"
              ";   (notes/promb-2026-09-25/dlb_table_splitter.py).  The rest of this span\n"
              ";   is unreachable and stays `.incbin`.  Why this is data and not code: THE\n"
              ";   PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.")

OLD_EXTENT_L1 = OLD_EXTENT.encode("utf-8").decode("latin-1")


def u32(b, i):
    return int.from_bytes(b[i:i + 4], "little")


def b_records(b):
    """{target: [(rec_addr, op, src, mask, shift, fn, width)]} for every op-2/3/4/7/8 B record."""
    out = {}
    for i in range(len(b) - 17):
        op, ln = b[i], b[i + 1]
        if op in REC_LEN and ln == REC_LEN[op]:
            t = u32(b, i + 7)
            if not (BASE <= t < BASE + len(b)):
                continue
            src = int.from_bytes(b[i + 2:i + 4], "little")
            w = int.from_bytes(b[i + 11:i + 13], "little") if KIND[op] == "text" else \
                {"box": 8, "area": 6}[KIND[op]]
            out.setdefault(t, []).append((BASE + i, op, src, b[i + 4], b[i + 5] & 7, b[i + 6], w))
    return out


def code_uses(roms):
    """(pointer-array readers {addr: [site]}, list-end uses {addr: [(site, list_start, runner)]})."""
    parr, ends = {}, {}
    for base, b in roms:
        call_pa = b"\x1d" + RUN_PTR_ARRAY.to_bytes(3, "little")
        for i in range(len(b) - 24):
            # `ld XIY,<addr>` then, within 12 bytes (the `ld (0x2540),0` store sits
            # between them at 0xF5BFAE), `call RunDisplayListBFromPointerArray`
            if b[i] == 0x45 and b[i + 4] == 0 and call_pa in b[i + 5:i + 17]:
                parr.setdefault(u32(b, i + 1), []).append(base + i)
            if 0x40 <= b[i] <= 0x47 and b[i + 4] == 0 and BASE <= u32(b, i + 1) < BASE + 0x80000:
                IMM.setdefault(u32(b, i + 1), []).append((base + i, REG32[b[i] - 0x40]))
            if b[i] == 0x44 and b[i + 4] == 0 and b[i + 5] == 0x1D:
                tgt = int.from_bytes(b[i + 6:i + 9], "little")
                if tgt in LIST_RUNNERS and i >= 5 and b[i - 5] == 0x45:
                    ends.setdefault(u32(b, i + 1), []).append((base + i, u32(b, i - 4),
                                                               LIST_RUNNERS[tgt]))
    return parr, ends


def obj_extent(L, i):
    """The object whose label is on line i: its first data address, the address after its last
    data line, and that line's index.  Any line that is not a `; XXXXXX  |..|` data row ends it."""
    lo, last = None, None
    k = i + 1
    while k < len(L):
        m = re.match(r'^\t\.byte\t(0x[0-9A-F]{2}(?:, 0x[0-9A-F]{2})*)\t; ([0-9A-F]{6})  \|.*\|$', L[k])
        if not m:
            break
        if lo is None:
            lo = int(m.group(2), 16)
        last = k
        hi = int(m.group(2), 16) + len(m.group(1).split(","))
        k += 1
    if lo is None:
        return None
    return lo, hi, last


def plan(label, L, b, recs, parr):
    if label in SKIP:
        return None, "in SKIP (see the note there)"
    i = [k for k, t in enumerate(L) if t.startswith(label + ":")]
    if len(i) != 1:
        return None, "label not found once"
    i = i[0]
    ext = obj_extent(L, i)
    if not ext:
        return None, "not a coverage-walk `.byte` object"
    lo, hi, last = ext
    pieces = {t: rs for t, rs in recs.items() if lo <= t < hi}
    if not pieces:
        return None, "no B record reads it"
    head = "\n".join(L[max(0, i - 40):i])
    if OLD_EXTENT_L1 not in head or not re.search(r'^; %s -- \d+ bytes, EMITTED AS DATA' % label,
                                               head, re.M):
        return None, "header is not the coverage walk's standard form"
    fields = set()
    for t in L:
        m = re.match(r'^\t\.long\s+%s(?: \+ (0x[0-9A-Fa-f]+))?\s*; \+0x07 ->' % re.escape(label), t)
        if m:
            fields.add(lo + (int(m.group(1), 16) if m.group(1) else 0))
    if fields != set(pieces):
        return None, "the source's +0x07 fields name %s; the ROM scan's records name %s" % (
            sorted("%06X" % x for x in fields), sorted("%06X" % x for x in pieces))
    starts = sorted(pieces)
    segs = []
    if starts[0] > lo:
        segs.append(chunk(lo, starts[0], b, parr, "front", "the first table"))
    for k, s in enumerate(starts):
        e = starts[k + 1] if k + 1 < len(starts) else hi
        rs = pieces[s]
        ws = set(r[6] for r in rs)
        kinds = set(KIND[r[1]] for r in rs)
        if len(ws) != 1 or len(kinds) != 1:
            return None, "records disagree on 0x%06X (widths %s, kinds %s)" % (s, ws, kinds)
        w, kind = ws.pop(), kinds.pop()
        reach = max((r[3] >> r[4]) + 1 for r in rs)
        n_ext = (e - s) // w if w else 0
        if w == 0 or n_ext == 0:
            return None, "piece 0x%06X has width %d over %d bytes" % (s, w, e - s)
        n, why = n_ext, "ext"
        if reach < n_ext:
            n, why = reach, "mask"
        fns = set(r[5] for r in rs)
        if kind == "text" and fns <= ASCII_FONTS:
            ents = [b[s - BASE + w * j:s - BASE + w * j + w] for j in range(n)]
            z = [0 in x for x in ents]
            if any(z) and not z[0]:
                first = z.index(True)
                if all(z[first:]):
                    n, why = first, "text"
        if n == n_ext and why == "ext" and (e - s) % w:
            return None, "piece 0x%06X-0x%06X is not whole %d-byte entries" % (s, e - 1, w)
        segs.append(dict(type="table", start=s, end=s + n * w, width=w, kind=kind, n=n, why=why,
                         reach=reach, recs=rs, fns=fns, bound_end=e, bound_is_obj_end=(e == hi)))
        if s + n * w < e:
            segs.append(chunk(s + n * w, e, b, parr, "left",
                              "the object's end" if e == hi else "the next table"))
    return dict(label=label, lo=lo, hi=hi, line=i, last=last, segs=segs), None


def chunk(s, e, b, parr, where, bound):
    """A stretch no table owns: a pointer array when the rules allow it, else plain bytes."""
    d = dict(type="bytes", start=s, end=e, where=where, bound=bound)
    if (e - s) % 4 == 0 and s in parr:
        ps = [u32(b, a - BASE) for a in range(s, e, 4)]
        # a B-record start: an opcode the 0xF31DB1 table dispatches and a length byte
        # the prom_b_dl_length_audit found for B records
        if all(BASE <= p < BASE + len(b) and b[p - BASE] < 0x0F and
               b[p - BASE + 1] in (10, 11, 13, 15, 17) for p in ps):
            d.update(type="ptrs", ptrs=ps, readers=parr[s])
    return d


def camel(s):
    return "".join(t[:1].upper() + t[1:].lower() for t in re.findall(r'[A-Za-z]+|[0-9]+', s))


def auto_name(sg, b, taken):
    s, w = sg["start"], sg["width"] if sg["type"] == "table" else 0
    if s in NAMES:
        base = NAMES[s]
    elif sg["type"] == "table" and sg["kind"] == "text":
        ents = [b[s - BASE + w * k:s - BASE + w * k + w].decode("latin-1") for k in range(sg["n"])]
        toks = [camel(e) for e in ents if re.search(r'[A-Za-z]', e)]
        base = "DLText_" + "".join(toks[:3]) if toks else "DLText_%06X" % s
    elif sg["type"] == "table":
        base = {"box": "DLBoxes_%06X", "area": "DLAreas_%06X"}[sg["kind"]] % s
    elif sg["type"] == "ptrs":
        base = "DLBRecordPtrs_%06X" % s
    else:
        base = "Data_%06X" % s
    base = base[:44]
    name = base if base not in taken else "%s_%06X" % (base, s)
    assert name not in taken, name
    taken.add(name)
    return name


def wrap(text):
    return textwrap.wrap(text, width=76, initial_indent="; ", subsequent_indent=";   ")


def text_row(e, a, k, fns):
    if fns <= ASCII_FONTS and all(0x20 <= c < 0x7F and c not in (0x22, 0x5C) for c in e):
        return '\t.ascii\t"%s"\t; %06X  [%d]' % (e.decode("latin-1"), a, k)
    note = ""
    if fns <= ASCII_FONTS:
        note = '  "%s"' % "".join(chr(c) if 0x20 <= c < 0x7F else "<%02X>" % c for c in e)
    return "\t.byte\t%s\t; %06X  [%d]%s" % (", ".join("0x%02X" % x for x in e), a, k, note)


def emit_seg(sg, nm, b, ends, prev_name):
    out = ["; " + "-" * 74]
    s, e = sg["start"], sg["end"]
    endtxt = ""
    if s in ends:
        us = ends[s]
        endtxt = ("  This address is also the END of a display list: %s."
                  % "; ".join("`ld XIY,0x%06X / ld XIX,this / call %s` at 0x%06X" % (ls, rn, site)
                              for site, ls, rn in us[:4])
                  + ("" if len(us) <= 4 else " (and %d more sites)" % (len(us) - 4)))
    if sg["type"] == "table":
        rs = sg["recs"]
        rtxt = ", ".join("0x%06X ((0x%04X) AND 0x%02X >> %d)" % (r[0], r[2], r[3], r[4])
                         for r in rs[:4])
        if len(rs) > 4:
            rtxt += " and %d more" % (len(rs) - 4)
        ops = sorted(set(r[1] for r in rs))
        fn = " / ".join(FN.get(f, "swi 7 service 0x%02X" % f) for f in sorted(sg["fns"]))
        if sg["kind"] == "text":
            what = "%d entries of %d bytes, text drawn by %s" % (sg["n"], sg["width"], fn)
            how = ("DLB_Handler_StringTable%s draws entry [value] with +0x0B = %d as the width"
                   % ("2" if ops == [7] else "" if ops == [2] else "/StringTable2", sg["width"]))
        elif sg["kind"] == "box":
            what = ("%d entries of four words, left / top / right / bottom" % sg["n"]
                    + (" of the inclusive pixel box %s fills or erases" % fn
                       if sg["fns"] <= {0x05, 0x1B} else ", handed to %s" % fn))
            how = "DLB_Handler_Array8 copies entry [value] to (0x2530)..(0x2536) (`sla 3,HL`)"
            if b[s - BASE:s - BASE + 8] == bytes([0, 0, 0, 0, 1, 0, 1, 0]):
                how += ("; entry 0 is (0,0)-(1,1), a 2 x 2-pixel box in the panel's top-left "
                        "corner, so value 0 draws next to nothing (wsa1/scripts/analysis/"
                        "sizing_defect_hunt.py calls this shape an 8-byte header; the reader "
                        "indexes it as entry 0)")
        else:
            what = "%d entries of IY, BC, HL" % sg["n"]
            how = "DLB_Handler_Array6 loads entry [value] (`mul HL,6`)"
        cnt = {"ext": "the distance to %s over the width" % ("the object's end" if
                                                             sg["bound_is_obj_end"] else
                                                             "the next table"),
               "mask": "the %d values the readers' masks admit (the bytes after that are not"
                       " indexed by them)" % sg["reach"],
               "text": "the text: entry %d would hold 0x00 bytes, as does every slot after it"
                       % sg["n"]}[sg["why"]]
        body = ("%s -- 0x%06X-0x%06X, %s.  Read by the interpreter-B op-%s record%s at %s -- "
                "value = (byte at the +2 address) AND mask >> shift -- whose +0x07 names this "
                "address; %s.  Entry count: %s%s.%s"
                % (nm, s, e - 1, what, "/".join("0x%02X" % o for o in ops),
                   "s" if len(rs) > 1 else "", rtxt, how, cnt,
                   "" if sg["why"] == "mask" else "; the masks admit %d" % sg["reach"], endtxt))
        out += wrap(body)
        out.append("; " + "-" * 74)
        out.append("%s:" % nm)
        for k in range(sg["n"]):
            a = s + sg["width"] * k
            ent = b[a - BASE:a - BASE + sg["width"]]
            if sg["kind"] == "text":
                out.append(text_row(ent, a, k, sg["fns"]))
            else:
                ws = [int.from_bytes(ent[j:j + 2], "little") for j in range(0, sg["width"], 2)]
                if sg["kind"] == "box":
                    out.append("\t.short\t%s\t; %06X  [%d]" % (", ".join("%d" % x for x in ws), a, k))
                else:
                    out.append("\t.short\t%s\t; %06X  [%d]" % (", ".join("0x%04X" % x for x in ws),
                                                               a, k))
        return out
    if sg["type"] == "ptrs":
        body = ("%s -- 0x%06X-0x%06X, %d 32-bit pointers, each to the first byte of an "
                "interpreter-B record.  Read by RunDisplayListBFromPointerArray (0xF09AE1: "
                "`sla 2,WA / add XIY,XWA / ld XIY,(XIY)`, then ONE record is run) with XIY = this "
                "address at %s.  Entry count: the distance to %s over 4 -- the reader "
                "indexes by A and does not bound it.%s"
                % (nm, s, e - 1, len(sg["ptrs"]), ", ".join("0x%06X" % x for x in sg["readers"]),
                   sg["bound"], endtxt))
        out += wrap(body)
        out.append("; " + "-" * 74)
        out.append("%s:" % nm)
        for k, p in enumerate(sg["ptrs"]):
            out.append("\t.long\t0x%08X\t; %06X  [%d]" % (p, s + 4 * k, k))
        return out
    imm = [x for x in IMM.get(s, []) if (x[0], x[1]) not in
           [(u[0], "XIX") for u in ends.get(s, [])]]
    body = ("%s -- 0x%06X-0x%06X, %d bytes %s.  No interpreter-B record's +0x07 and no "
            "pointer-array run names them%s; purpose not established.%s"
            % (nm, s, e - 1, e - s, "in front of the tables below" if sg["where"] == "front" else
               "after the last entry %s's readers index" % prev_name,
               "" if not imm else " (a 32-bit immediate does: %s)" % ", ".join(
                   "`ld %s,this` at 0x%06X" % (r, a) for a, r in imm[:4]), endtxt))
    out += wrap(body)
    out.append("; " + "-" * 74)
    out.append("%s:" % nm)
    for a in range(s, e, 16):
        n = min(16, e - a)
        out.append("\t.byte\t%s\t; %06X" % (", ".join("0x%02X" % x for x in b[a - BASE:a - BASE + n]),
                                            a))
    return out


def main():
    b = open(ROMB, "rb").read()
    ba = open(ROMA, "rb").read()
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    recs = b_records(b)
    parr, ends = code_uses([(BASE, b), (BASE_A, ba)])
    labels = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not labels:
        cen = "/tmp/claude-1000/lane-promb/split_census.json"
        subprocess.run([sys.executable, os.path.join(ROOT, "scripts", "analysis",
                                                     "data_range_census.py"),
                        "--images", "prom_b", "--json", cen], capture_output=True, cwd=ROOT)
        d = json.load(open(cen))
        labels = sorted(set(r["label"] for r in d["regions"] if r["image"] == "prom_b" and
                            r["label"] and r["label"].startswith("Data_") and r["grade"] != "CODE"
                            and (r["grade"] == "UNKNOWN" or r.get("admits"))))
    plans, refused = [], []
    for lab in labels:
        pl, why = plan(lab, L, b, recs, parr)
        if pl:
            plans.append(pl)
        elif why not in ("no B record reads it", "not a coverage-walk `.byte` object"):
            refused.append((lab, why))
    taken = set(re.findall(r'^([A-Za-z_]\w*):', txt, re.M))
    for pl in plans:
        segs = pl["segs"]
        for sg in segs:
            sg["name"] = (pl["label"] if sg["start"] == pl["lo"] and sg["type"] == "bytes"
                          else auto_name(sg, b, taken))
        print("%-14s 0x%06X-0x%06X" % (pl["label"], pl["lo"], pl["hi"] - 1))
        for sg in segs:
            extra = ""
            if sg["type"] == "table":
                extra = "%s w%d x%d (%s; masks admit %d)" % (sg["kind"], sg["width"], sg["n"],
                                                             sg["why"], sg["reach"])
            elif sg["type"] == "ptrs":
                extra = "%d ptrs" % len(sg["ptrs"])
            print("    0x%06X-0x%06X %-6s %-32s %s" % (sg["start"], sg["end"] - 1, sg["type"],
                                                     sg["name"], extra))
    for lab, why in refused:
        print("REFUSED %-14s %s" % (lab, why))
    print("%d objects typed, %d bytes; %d refused" % (len(plans), sum(p["hi"] - p["lo"] for p in plans),
                                                     len(refused)))
    if "--apply" not in sys.argv:
        return 0
    # bottom-up, so line numbers stay valid
    for pl in sorted(plans, key=lambda p: -p["line"]):
        i = pl["line"]
        h = i
        while h > 0 and L[h - 1].startswith(";"):
            h -= 1
        head = "\n".join(L[h:i])
        head = head.replace(OLD_EXTENT_L1, NEW_EXTENT)
        # the retired label becomes the address range -- or, where a later
        # SUPERSEDED note explains that the stated count was the walk's and too
        # long (0xF05AB4, 0xF28522), just the start address, so range and count
        # cannot contradict each other
        head = re.sub(r'^; %s -- (\d+) bytes, EMITTED AS DATA' % pl["label"],
                      lambda m: ("; 0x%06X-0x%06X -- %s bytes, EMITTED AS DATA" % (
                          pl["lo"], pl["hi"] - 1, m.group(1)) if int(m.group(1)) == pl["hi"] - pl["lo"]
                          else "; 0x%06X -- %s bytes, EMITTED AS DATA" % (pl["lo"], m.group(1))),
                      head, count=1, flags=re.M)
        head = head.replace(pl["label"], "OLD<<%s>>" % pl["label"].replace("_", "@"))
        new = head.split("\n")
        prev = None
        for sg in pl["segs"]:
            seg = emit_seg(sg, sg["name"], b, ends, prev)
            if prev is None and new and new[-1] == seg[0]:
                seg = seg[1:]        # the old header's closing rule opens the first piece
            new += seg
            prev = sg["name"]
        new = [x.encode("utf-8").decode("latin-1") if any(ord(c) > 0xFF for c in x) else x
               for x in new]
        L = L[:h] + new + L[pl["last"] + 1:]
    txt = "\n".join(L)
    # a history sentence that must keep naming the retired label, plus a pointer on
    for a, c in HISTORY:
        if a in txt:
            txt = txt.replace(a, c.replace("Data_F05AB4 is", "OLD<<Data@F05AB4>> is").replace(
                "tail of Data_F05AB4", "tail of OLD<<Data@F05AB4>>"))
    for pl in plans:
        old = pl["label"]
        segs = [(sg["start"], sg["name"]) for sg in pl["segs"]]

        def repl(m, segs=segs, lo=pl["lo"]):
            a = lo + (int(m.group(1), 16) if m.group(1) else 0)
            st, nm = max((x for x in segs if x[0] <= a), key=lambda x: x[0])
            return nm if a == st else "%s + 0x%X" % (nm, a - st)
        txt = re.sub(r'\b%s(?: \+ (0x[0-9A-Fa-f]+))?\b' % re.escape(old), repl, txt)
    txt = re.sub(r'OLD<<(\w+?)@(\w+)>>', lambda m: m.group(1) + "_" + m.group(2), txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC)
    return 0


if __name__ == "__main__":
    sys.exit(main())
