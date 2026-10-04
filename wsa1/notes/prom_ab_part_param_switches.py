#!/usr/bin/env python3
"""Name the part-parameter SWITCHES, key/velocity layers and MULTIPLE MESSAGES OUTPUT items, and their prom_a handlers.

QUESTION IT ANSWERS
  notes/prom_ab_part_param_fields.py named the field descriptors whose (offset, mask, max, min) equals exactly one
  PART-area SysEx parameter.  It left the rest of the twelve tables PtrTable_F1AB13 .. PtrTable_F1ACDB numeric:
  handlers of three other shapes, and records that are not 5-byte numeric descriptors.  One more fact settles them --
  the RECORD SET:
    * IndexedParam_SetBit XORs descriptor byte +2 into PanelEvent_Flags and, when bit 4 of the result is set, adds
      0x20 to the record number (`ld C,(XIX+0x02) / xor (0x28b0),C / ... and C,0x10 / jr z / add E,0x20` at
      0xF55488-0xF55498).  IndexedParam_AdjustField does the same with byte +7 (its header).  The SysEx descriptors
      carry the same choice as their `rec` byte (+6): 0 or 32 (notes/sysex-probes/sysex_param_addresses.py).
    So a field is (record set, offset, mask), and for the single-bit switches that triple is unique among the PART
  parameters: (32, 14, 0x10) is CONTROLLER INTERNAL FILTER: MODULATION2, while (0, 14, 0xFF) is MIDI MULTIPLE
  MESSAGES OUTPUT: PROGRAM CHANGE.  The shapes:
    SWITCH  `lda XBC,<rec> / push / push 0 / push (XIZ+8) / call T_IndexedParam_SetBit` -- 3-byte record
            (offset, mask, selector); named PartParam_Step<Name>, the record PartParamField_<Name>.
    LAYER   copies a 9-byte template record to the stack (`ldw bc,9 / lda xiy,<rec> / ... ldir85`), reads byte K of
            record E+0x20 with T_IndexedTable_GetByte, stores it as the template's maximum (+3, (XIZ-6)) or minimum
            (+4, (XIZ-5)), then calls T_IndexedParam_AdjustField.  So a LOW is bounded above by its HIGH, and the
            reverse; the planner checks that each LOW names its HIGH's offset and the reverse.
    MMO     `pushw <bit> / pushw <offset> / push 0 / push (XIZ+8) / calr PartParam_StepMultipleMessagesOutputItem`.  PartParam_StepMultipleMessagesOutputItem is the common
            stepper of a MULTIPLE MESSAGES OUTPUT item.  It reads the item's byte at <offset> and the enable bit
            <bit> of byte 0x15, and folds them into an index 0..129 (enable bit set -> 0; byte bit 7 -> 1; else
            byte+2).  It steps that index within PartParamField_MidiMultipleMessagesOutputProgramChange's 0..129,
            through T_EditValue_StepBitField, and writes it back the same way (0x15 gets <bit>, or the byte gets 0x80, or the byte
            gets index-2), posting both bytes to Queue2C00.  The <offset> is the SysEx offset of the item.
    MMO ENTER  `ld L,(XIZ+8) / lda XBC,<rec> / push / pushw HL / call T_IndexedParam_SetFieldFromAsciiEntry`, with a
            0..127 value record at the item's offset.
    BANK MSB  (offset 16): `T_IndexedTable_GetPtr / add XIY,15 / test (XIY) bit 7 and (XIY+6) bit 0x20`, and only when
            both are clear AdjustField / SetFieldFromAsciiEntry on the offset-16 record.
  BANK SELECT is the one 2-byte item (SysEx 00 20 61, `size 00 00 02` at offset 15).  Its setter,
  SysExParam_SetMidiMultipleMessagesOutputBankSelect, reads a 16-bit value DE (0x4000 and 0x4001 are the two non-value
  states).  It stores `res 7` of E at offset 15 (0xFB3CC0-0xFB3CC5) and (DE >> 7) & 0x7F at offset 16
  (0xFB3CE3-0xFB3CEB).  So byte 15 is the bank number's low 7 bits, BANK LSB, and it also carries the item's state
  bit 7; byte 16 is BANK MSB.  The bare `ret` at 0xFBBCA3 that fills PtrTable_F1AB13[12] is PartParam_StepIgnored.
  REFUSED: a record whose (set, offset, mask) has no unique PART parameter, a shape the planner does not know, a
  layer pair whose companion offsets do not cross.

RUN
  python3 notes/prom_ab_part_param_switches.py           # the plan
  python3 notes/prom_ab_part_param_switches.py --records # 'old=new|header' for the rename helper (prom_b records)
  python3 notes/prom_ab_part_param_switches.py --place   # 'ADDR=Name|header' for wsa1_place.py (prom_a handlers)
"""
import collections
import contextlib
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes", "sysex-probes"))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1").split("\n")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1").split("\n")
H = "(notes/prom_ab_part_param_switches.py)"
TABLES = re.compile(r'^(PtrTable_F1A[BC][0-9A-F]{2}):')
REC = r'((?:Record_F1A[A-F]|PartParamField_)\w+)'
MMO = "MidiMultipleMessagesOutput"
# the BANK SELECT item's two bytes, from SysExParam_SetMidiMultipleMessagesOutputBankSelect (see the docstring)
BANK = {15: "BankSelectLsb", 16: "BankSelectMsb"}
STUB = {0xFBBCA3: ("PartParam_StepIgnored", "PtrTable_F1AB13[12]: a bare `ret` -- field id 12 has no adjust action")}
SHARED = {"PartParam_StepMultipleMessagesOutputItem": ("PartParam_StepMultipleMessagesOutputItem",
                         "PartParam_StepMultipleMessagesOutputItem(part, 0, offset, bit): the common stepper of a MULTIPLE\n"
                         "  MESSAGES OUTPUT item.  Index = 0 when bit <bit> of byte 0x15 is set, 1 when the byte at <offset> has bit\n"
                         "  7, else byte+2; stepped within PartParamField_MidiMultipleMessagesOutputProgramChange's 0..129 (T_EditValue_StepBitField)\n"
                         "  and written back the same way, both bytes posted to Queue2C00 " + H)}


def camel(s):
    s = re.sub(r'[^A-Za-z0-9]+', ' ', s.replace("&", " and ")).strip()
    return "".join(w[:1].upper() + w[1:].lower() if not w.isdigit() else w for w in s.split())


ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
ENABLE_BIT = {}   # MMO item offset -> the enable bit its SysEx descriptor names after its three pointers


def sysex():
    with contextlib.redirect_stdout(io.StringIO()):
        saved, sys.argv = sys.argv, ["x"]
        import sysex_param_addresses as P
        sys.argv = saved
    names = json.load(open(os.path.join(ROOT, "notes", "sysex-probes", "param_names.json")))
    out = collections.defaultdict(list)
    for p in P.PARAMS:
        if p.b7 == 0x20:
            out[(p.rec, p.off, p.mask)].append(names["%02X/%02X" % (p.b7, p.b8)]["name"])
            # an MMO descriptor is followed by `.byte 0x00, 0x15, bit, bit` (byte 0x15, the item's enable bit)
            t = ROM[p.desc - 0xF00000 + 0x1C:p.desc - 0xF00000 + 0x20]
            if 0x60 <= p.b8 <= 0x67 and t[:2] == bytes([0, 0x15]) and t[2] == t[3]:
                ENABLE_BIT[p.off] = t[2]
    return out


def records():
    out = {}
    for i, l in enumerate(B):
        m = re.match(r'^%s:' % REC, l)
        if m:
            mm = re.match(r'^\s*\.byte\s+([^;]+)', B[i + 1])
            if mm:
                out[m.group(1)] = [int(x, 0) for x in mm.group(1).split(",")]
    return out


def code_index():
    at = {}
    for i, l in enumerate(A):
        m = re.search(r';\s*([0-9A-F]{6})\s', l)
        c = l.split(";")[0].strip()
        if m and c and not re.match(r'^[\w.$]+:$', c):
            at.setdefault(int(m.group(1), 16), i)
    return at


def body(at, a, n=24):
    """The handler's code lines from its first instruction, up to and including its first `ret`."""
    out, q = [], at[a]
    while len(out) < n and q < len(A):
        c = re.sub(r'\s+', ' ', A[q].split(";")[0]).strip()
        if c and not re.match(r'^[\w.$]+:$', c):
            out.append(c)
            if c == "ret":
                break
        q += 1
    return out


def slots():
    out = collections.defaultdict(list)
    for i, l in enumerate(B):
        m = TABLES.match(l)
        if not m:
            continue
        k = 0
        for x in B[i + 1:i + 40]:
            mm = re.match(r'^\s*\.long\s+(\S+)', x)
            if mm:
                if mm.group(1).startswith("0x"):
                    out[int(mm.group(1), 16)].append((m.group(1), k))
                k += 1
            elif x.strip() and not x.startswith(";"):
                break
    return out


def classify(b):
    j = " | ".join(b)
    if b == ["ret"]:
        return ("stub",)
    m = re.match(r'link XIZ,0x0000 \| lda xbc, \(%s:24\) \| push XBC \| push 0x00 \| m_push MBD\+r6, 0x08 \| call T_IndexedParam_SetBit\b' % REC, j)
    if m:
        return ("switch", m.group(1))
    m = re.match(r'link XIZ,0xfff7 \| push XIX \| ldw bc, 0x09 \| lda xiy, \(%s:24\) \| lda xix, \(xiz-9\) \| ldir85 \| pushw (0x[0-9a-f]+) \|'
                 r'.*call T_IndexedTable_GetByte \| ld \(xiz-(\d)\), a \|.*call T_IndexedParam_AdjustField' % REC, j)
    if m:
        return ("layer", m.group(1), int(m.group(2), 16), {"6": "max", "5": "min"}.get(m.group(3)))
    m = re.match(r'link XIZ,0x0000 \| pushw (0x[0-9a-f]+) \| pushw (0x[0-9a-f]+) \| push 0x00 \| m_push MBD\+r6, 0x08 \| calr PartParam_StepMultipleMessagesOutputItem\b', j)
    if m:
        return ("mmo", int(m.group(2), 16), int(m.group(1), 16))
    m = re.match(r'link XIZ,0x0000 \| pushw hl \| ld L,\(XIZ\+0x08\) \| lda xbc, \(%s:24\) \| push XBC \| pushw hl \| call T_IndexedParam_SetFieldFromAsciiEntry\b' % REC, j)
    if m:
        return ("mmo_enter", m.group(1))
    m = re.match(r'link XIZ,0x0000 \| push XIX \| push 0x00 \| m_push MBD\+r6, 0x08 \| call T_IndexedTable_GetPtr \| ld XIX,XIY \| add XIY,0x0000000f \|'
                 r' ld XIX,XIY \| ld C,\(XIY\) \| and C,0x80 \| popw wa \| jr nz, \S+ \| ld C,\(XIY\+0x06\) \| and C,0x20 \| jr nz, \S+ \|'
                 r' lda xbc, \(%s:24\) \| push XBC \| push 0x00 \| m_push MBD\+r6, 0x08 \| call (T_IndexedParam_AdjustField|T_IndexedParam_SetFieldFromAsciiEntry)\b' % REC, j)
    if m:
        return ("bank_msb", m.group(1), "Step" if m.group(2).endswith("AdjustField") else "Enter")
    return None


def plan():
    sx, recs, at = sysex(), records(), code_index()
    rname, place, refused = {}, {}, []

    def field(r, sel_at):
        v = recs[r]
        rs = 32 if v[sel_at] & 0x10 else 0
        c = sx.get((rs, v[0], v[1]), [])
        return v, rs, c

    def name_record(r, n, why):
        if r.startswith("Record_") and rname.get(r, (n,))[0] == n:
            rname[r] = (n, why)
        elif r.startswith("Record_"):
            refused.append((r, "two names %s / %s" % (rname[r][0], n)))

    hs = slots()
    for a in sorted(hs):
        uses = ", ".join("%s[%d]" % u for u in hs[a])
        if a not in at:
            refused.append(("0x%06X" % a, "not a code line"))
            continue
        k = classify(body(at, a))
        if k is None:
            refused.append(("0x%06X" % a, "shape not known (%s)" % uses))
            continue
        if k[0] == "stub" and a in STUB:
            place[a] = STUB[a]
        elif k[0] == "switch":
            r = k[1]
            v, rs, c = field(r, 2)
            if len(c) != 1:
                refused.append((r, "(set %d, offset %d, mask 0x%02X) matches %s" % (rs, v[0], v[1], c)))
                continue
            nm = camel(c[0])
            why = "record set %d (selector +2 = 0x%02X), offset %d, mask 0x%02X: the only PART parameter with that bit is %s" % (rs, v[2], v[0], v[1], c[0])
            name_record(r, "PartParamField_" + nm, why)
            place[a] = ("PartParam_Step" + nm, "%s: forces bit 0x%02X of byte %d of part record E%s by the step direction (T_IndexedParam_SetBit, %s); %s"
                        % (c[0], v[1], v[0], "+0x20" if rs else "", r, uses))
        elif k[0] == "layer":
            r, comp, slot = k[1], k[2], k[3]
            v, rs, c = field(r, 7)
            c = [n for n in c if "LAYER" in n]
            if len(c) != 1 or not slot:
                refused.append((r, "layer template does not name one LAYER parameter: %s" % c))
                continue
            low = c[0].endswith("LOW")
            if (slot == "max") != low or comp != v[0] + (1 if low else -1):
                refused.append((r, "the companion byte %d / %s does not cross with offset %d" % (comp, slot, v[0])))
                continue
            nm = camel(c[0])
            name_record(r, "PartParamField_" + nm, "the 9-byte template: record set %d (+7 = 0x%02X), offset %d, mask 0x%02X, %d..%d: %s"
                        % (rs, v[7], v[0], v[1], v[4], v[3], c[0]))
            place[a] = ("PartParam_Step" + nm, "%s: steps byte %d of part record E+0x20 with its %s replaced by byte %d (the %s end), so the pair cannot\n"
                        "  cross; template %s; %s" % (c[0], v[0], "maximum" if low else "minimum", comp, "HIGH" if low else "LOW", r, uses))
        elif k[0] == "mmo":
            off, bit = k[1], k[2]
            c = sx.get((0, off, 0xFF), [])
            if off in BANK:
                item = BANK[off]
                # BANK SELECT's setter writes enable bit 0x20 of byte 0x15 (`ld (XIX+0x01),0x15 / ld (XIX+0x02),0x20`, 0xFB3CA9)
                ok = bit == 0x20
            elif len(c) == 1 and c[0].startswith("MIDI MULTIPLE MESSAGES OUTPUT: "):
                item = camel(c[0].split(": ", 1)[1])
                ok = ENABLE_BIT.get(off) == bit
            else:
                refused.append(("0x%06X" % a, "MMO offset %d matches %s" % (off, c)))
                continue
            if not ok:
                refused.append(("0x%06X" % a, "MMO offset %d: enable bit 0x%02X, the SysEx descriptor says %s" % (off, bit, ENABLE_BIT.get(off))))
                continue
            place[a] = ("PartParam_Step%s%s" % (MMO, item), "MULTIPLE MESSAGES OUTPUT %s: PartParam_StepMultipleMessagesOutputItem on byte %d, enable bit 0x%02X of\n"
                        "  byte 0x15; %s" % (item, off, bit, uses))
        elif k[0] in ("mmo_enter", "bank_msb"):
            r = k[1]
            v = recs[r]
            c = sx.get((0, v[0], 0xFF), [])
            if v[0] in BANK:
                item = BANK[v[0]]
            elif len(c) == 1 and c[0].startswith("MIDI MULTIPLE MESSAGES OUTPUT: "):
                item = camel(c[0].split(": ", 1)[1])
            else:
                refused.append((r, "value record offset %d matches %s" % (v[0], c)))
                continue
            kind = "Enter" if k[0] == "mmo_enter" else k[2]
            name_record(r, "PartParamField_%s%sValue" % (MMO, item), "the 0..%d value of MULTIPLE MESSAGES OUTPUT %s: offset %d, mask 0x%02X%s"
                        % (v[3], item, v[0], v[1], " (BANK SELECT's byte 16: SysExParam_SetMidiMultipleMessagesOutputBankSelect)" if v[0] == 16 else ""))
            place[a] = ("PartParam_%s%s%s" % (kind, MMO, item), "MULTIPLE MESSAGES OUTPUT %s: %s %s%s; %s" % (
                item, "T_IndexedParam_AdjustField on" if kind == "Step" else "number entry into", r,
                ", only while byte 15 holds a value (bit 7 clear) and BANK SELECT's enable bit 0x20 of byte 0x15 is clear" if k[0] == "bank_msb" else "",
                uses))
    # the shared stepper: named only when every MMO handler above was accepted
    if any(n.startswith("PartParam_Step" + MMO) for n, _w in place.values()):
        for old, (new, hdr) in SHARED.items():
            place[old] = (new, hdr)
    # names must be unique: a duplicate gets its record's / handler's address
    cnt = collections.Counter(n for n, _w in rname.values())
    rlab = {r: (n if cnt[n] == 1 else n + "_" + r[-6:], w) for r, (n, w) in rname.items()}
    cnt = collections.Counter(n for n, _w in place.values())
    for a in list(place):
        n, w = place[a]
        if cnt[n] > 1:
            place[a] = (n + "_%06X" % a, w)
    return rlab, place, refused, at


def main():
    rlab, place, refused, at = plan()
    if "--records" in sys.argv:
        for r, (n, w) in sorted(rlab.items()):
            print("%s=%s|%s: %s %s" % (r, n, n, w, H))
        return
    if "--place" in sys.argv:
        for a, (n, w) in sorted((k, v) for k, v in place.items() if isinstance(k, int)):
            print("%06X=%s|%s: %s %s" % (a, n, n, w.replace("\n", "\\n"), H))
        return
    if "--rename" in sys.argv:
        for old, (n, w) in sorted((k, v) for k, v in place.items() if isinstance(k, str)):
            print("%s=%s|%s" % (old, n, w.replace("\n", "\\n")))
        return
    for r, (n, w) in sorted(rlab.items()):
        print("%-14s -> %-58s %s" % (r, n, w[:60]))
    for a, (n, w) in sorted(place.items(), key=lambda x: str(x[0])):
        print("%-10s -> %-58s %s" % (("0x%06X" % a) if isinstance(a, int) else a, n, w[:60].replace("\n", " ")))
    for r, why in refused:
        print("REFUSED %s: %s" % (r, why))
    print("records %d, handlers %d, refused %d" % (len(rlab), len(place), len(refused)))


if __name__ == "__main__":
    main()
