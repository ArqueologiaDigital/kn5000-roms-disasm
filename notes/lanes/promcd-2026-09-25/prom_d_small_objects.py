#!/usr/bin/env python3
r"""Evidence headers for prom_d's last small name-only objects.

QUESTION THIS ANSWERS
    Which reader locates each of these, and what does each hold?
      * ToneDB_OctaveShiftByProgram_Bank0..7 (8 x 128 B, slot +0xA8)
      * ToneDB_DefaultLayerParams_WaveSel (43 B, slot +0xAC + 0x51)
      * ToneRec_Template_Clear_Elem0..3 / _WaveSel0..3 (slot +0xB0)
      * ToneRec_058_Drawbar1_Elem0..3, ToneRec_059_Drawbar2_Elem0..3
      * DrawbarPreset_EnvDescTable_Desc000..003 (slot +0x70)
    and it corrects the drawbar banner's "Nothing has been found that reads
    these two records specifically, and nothing explains why they carry no
    wave-select array": Part_LoadToneRecordAndPointers (prom_c 0xFB47C4) reads
    tone +0x10 (0xFB47F3), takes its drawbar arm for bits 7:6 = 0x40
    (0xFB4805; both drawbar records hold 0x71), and there points each
    element's wave-select pointer at prom_c's own 43-byte Table_FE14A0
    (PartElement_SetWaveSelectPointer_ToRomDefault, called at 0xFB48CF)
    instead of at a record inside the tone -- which is why none is stored.
    Every cited encoding is asserted against wsa1/original_ROMs.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_d_small_objects.py          # checks
    python3 notes/lanes/promcd-2026-09-25/prom_d_small_objects.py --apply  # + edit
"""
import os
import re
import struct
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
D = open(os.path.join(W, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
AUX = os.path.join(W, "prom_d", "tone_database_aux.s")
DIRF = os.path.join(W, "prom_d", "tone_database_directory.s")
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]

CODE = [(0xFA7332, "e3 e1 a8 00 25"), (0xFA7351, "d9 ee 07"), (0xFA7358, "e2 ed d7 00 85"),
        (0xFA735F, "d9 ee 08"),
        (0xFB43F3, "e3 e5 ac 00 20"), (0xFB4401, "e8 c8 51 00 00 00"),
        (0xFB9D9A, "e3 e5 ac 00 20"), (0xFB9DAB, "e8 c8 51 00 00 00"),
        (0xFB9DCA, "23 2b"), (0xFB9DD1, "e9 c8 1d 02 00 00"),
        (0xFB9D76, "e3 e5 b0 00 20"), (0xFB9D87, "0b 1d 02"), (0xFB9D8A, "f2 d2 87 00 35"),
        (0xFB9D91, "1d 38 a0 f9"), (0xFB41F1, "e3 e5 b0 00 20"),
        (0xFB47F3, "8d 10 21"), (0xFB47F6, "c9 cc c0"), (0xFB4805, "76 8f 00"),
        (0xFB48CF, "1d 30 29 fc"), (0xFB48DC, "1d 5b 29 fc"),
        (0xFC28F3, "88 02 23"), (0xFC28FA, "88 03 23"), (0xFC2906, "da cc ff 0f"),
        (0xFC2983, "88 03 23"), (0xFC2986, "cb cc 30"), (0xFC2989, "cb ef 04")]


def wrap(body):
    return ["; " + x for x in textwrap.wrap(body, 90, break_long_words=False, break_on_hyphens=False)]


def headers():
    h = {}
    for b in range(8):
        h["ToneDB_OctaveShiftByProgram_Bank%d" % b] = wrap(
            "Read by Voice_GetOctaveShift (prom_c 0xFA72E9): dir[+0xA8] at 0xFA7332, + 128*bank "
            "(`sll 0x07` 0xFA7351, the bank row from ToneDB_BankMap) + the in-row index (the program, "
            "as the banner above reads it), + base at 0xFA7358; "
            "the byte lands in the high half of WA (`sll 0x08` 0xFA735F), the encoding of the "
            "+-12-step octave table at prom_c 0xFDF22A.  This is bank %d's row." % b)
    h["ToneDB_DefaultLayerParams_WaveSel"] = wrap(
        "The wave-select half of slot +0xAC, at +0x51.  Read by ToneRec_GetWaveSelectRecord "
        "(prom_c 0xFB43CB) when the element index maps to 0xFF: dir[+0xAC] at 0xFB43F3, + 0x51 "
        "at 0xFB4401; and by sub_FB9B69's template arm (dir[+0xAC] 0xFB9D9A, + 0x51 0xFB9DAB), "
        "which builds each of the four staged wave-select records (RAM 0x0087D2 + 0x21D + 43*j, "
        "0xFB9DCA/0xFB9DD1) from bytes 0..10 and 13..42 of this one.")
    tp = u32(0xB0)
    for k in range(4):
        h["ToneRec_Template_Clear_Elem%d" % k] = wrap(
            "Element block %d of the Clear template: record + 0xD9 + 81*%d.  sub_FB9B69 (prom_c "
            "0xFB9B69) copies the template's first 0x21D = 541 bytes -- the 217-byte head and "
            "these four blocks -- into the tone staging image at RAM 0x0087D2 (dir[+0xB0] "
            "0xFB9D76, `push 0x021d` 0xFB9D87, MemCopyWords 0xFB9D91).  Selector +0x02/+0x03 "
            "= 0x%02X/0x%02X, bank 0 program 127: ToneDB_SourceIndexMapA entry 127, the "
            "fallback entry, row 181 'Silent'." % (k, k, D[tp + 0xD9 + 81 * k + 2],
                                                     D[tp + 0xD9 + 81 * k + 3]))
        h["ToneRec_Template_Clear_WaveSel%d" % k] = wrap(
            "Wave-select record %d of the Clear template: record + 0x21D + 43*%d.  The template "
            "arm of sub_FB9B69 does NOT copy it -- it builds the staged records from "
            "ToneDB_DefaultLayerParams_WaveSel (0xFB9DCA-0xFB9E23) -- and no instruction that "
            "reads these 43 bytes has been pinned; the template's mask +0x11 = 0x%02X gives one "
            "element, so ToneRec_GetWaveSelectRecord would not reach record %d here either."
            % (k, k, D[tp + 0x11], k))
    ptr = [u32(0xB80 + 4 * i) for i in range(274)]
    for t, nm in ((0x58, "ToneRec_058_Drawbar1"), (0x59, "ToneRec_059_Drawbar2")):
        p = ptr[t]
        assert D[p + 0x10] & 0xC0 == 0x40 and D[p + 0x11] == 0x55
        for k in range(4):
            e = p + 0xD9 + 81 * k
            lo, hi = D[e + 2], D[e + 3]
            setting = ((hi << 8) | lo) & 0xFFF
            desc = (hi & 0x30) >> 4
            assert desc == k
            h["%s_Elem%d" % (nm, k)] = wrap(
                "Element block %d of this DRAWBAR tone: record + 0xD9 + 81*%d, fetched by "
                "Part_LoadToneRecordAndPointers' drawbar arm (prom_c 0xFB4805, kind +0x10 = "
                "0x%02X).  +0x02/+0x03 = 0x%02X/0x%02X: sub_FC28B5 packs them to the live "
                "drawbar setting 0x%03X (0xFC28F3, 0xFC28FA, `and DE,0x0FFF` 0xFC2906), and "
                "DrawbarPreset_GetDescriptor takes bits 5:4 of +0x03 (0xFC2983/0xFC2986/0xFC2989) "
                "= %d, i.e. DrawbarPreset_EnvDescTable_Desc%03d."
                % (k, k, D[p + 0x10], lo, hi, setting, desc, desc))
    for k in range(4):
        h["DrawbarPreset_EnvDescTable_Desc%03d" % k] = wrap(
            "Descriptor %d = dir[+0x70] + 14*%d, returned by DrawbarPreset_GetDescriptor (prom_c "
            "0xFC295B); element %d of both drawbar tones selects it (+0x03 bits 5:4 = %d)."
            % (k, k, k, k))
    return h


OLD_DB = ("; ⚠ Nothing has been found that reads these two records specifically, and\n"
          "; nothing explains why they carry no wave-select array.\n")
NEW_DB = ("; ★ CORRECTED 2026-09-25 (lane promcd).  This said nothing read these two\n"
          "; records specifically and nothing explained the missing wave-select array.\n"
          "; Part_LoadToneRecordAndPointers (prom_c 0xFB47C4) tests +0x10 bits 7:6\n"
          "; (0xFB47F3/0xFB47F6) and takes its DRAWBAR arm for 0x40 (0xFB4805) -- both\n"
          "; records carry 0x71, no other tone does -- and there, per element, calls\n"
          "; PartElement_SetWaveSelectPointer_ToRomDefault (0xFB48CF), which points the\n"
          "; element's wave-select pointer at prom_c's own 43-byte Table_FE14A0, then\n"
          "; DrawbarPreset_GetDescriptor (0xFB48DC).  A drawbar tone's wave-select\n"
          "; record lives in prom_c, so the tone stores none.\n")


def check():
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        got = C[a - 0xF80000:a - 0xF80000 + len(want)]
        assert got == want, "prom_c 0x%06X: %s want %s" % (a, got.hex(" "), enc)
    ptr = [u32(0xB80 + 4 * i) for i in range(274)]
    kinds = [t for t in range(274) if D[ptr[t] + 0x10] & 0xC0 == 0x40]
    assert kinds == [0x58, 0x59], kinds
    b = u32(0x50)
    assert u16(u32(0x44) + 2 * 127) == 181 and D[b + 16 * 181:b + 16 * 181 + 6] == b"Silent"
    print("  %d cited encodings hold; kind 0x40 is exactly tones 0x58/0x59" % len(CODE))


def insert(path, h):
    lines = open(path, "rb").read().decode("utf-8").split("\n")
    res, done = [], set()
    for ln in lines:
        m = re.match(r"^(\w+):", ln)
        if m and m.group(1) in h:
            res.extend(h[m.group(1)])
            done.add(m.group(1))
        res.append(ln)
    return "\n".join(res), done


def apply(h):
    src = open(AUX, "rb").read().decode("utf-8")
    if "CORRECTED 2026-09-25 (lane promcd).  This said nothing read these two" in src:
        sys.exit("already applied")
    assert src.count(OLD_DB) == 1
    open(AUX, "wb").write(src.replace(OLD_DB, NEW_DB).encode("utf-8"))
    txt, d1 = insert(AUX, h)
    open(AUX, "wb").write(txt.encode("utf-8"))
    txt, d2 = insert(DIRF, h)
    open(DIRF, "wb").write(txt.encode("utf-8"))
    assert d1 | d2 == set(h), set(h) - (d1 | d2)
    print("applied: drawbar banner correction, %d object headers" % len(h))


if __name__ == "__main__":
    check()
    h = headers()
    print("  %d objects" % len(h))
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply(h)
