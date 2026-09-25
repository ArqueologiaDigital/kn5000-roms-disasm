#!/usr/bin/env python3
r"""What do the P7 descriptor letters and the field-descriptor +5 byte mean?

QUESTION THIS ANSWERS
    Each of the 56 PoolDir_Records (prom_c 0xFDBFD9, 25 bytes) points at a
    TYPE string (+16) and a DIGIT string (+20) in DescriptorStrings, and at an
    array of 7-byte field descriptors through PoolDir_FieldRec_PtrTable.  Three
    places in the tree said the letters {b, w, v, s, h, c, B} and the
    descriptor's +5 byte were undecoded.  Both have readers:

    1. P7Unit_EmitChangedParams' generic walker (records other than 12, 13, 14,
       43, 55, which the switch at 0xFA47EB sends to hand-coded paths) steps the
       type string and the digit string in lockstep and reads each field of the
       unit's live block and its shadow by the letter (switch at 0xFA4735):
         'B' one byte sign-extended; 'c' two bytes BIG-endian; 'h' one byte
         plus 0x500; 'w' two bytes little-endian; any other letter one byte.
       On a difference the digit, through Base36DigitToValue, is the field index.
    2. sub_FA2784 (renamed here P7Unit_SendModulatedField) reads descriptor +5
       and switches on it (0xFA28F3): ' ' -> nothing sent; 'B' one byte
       sign-extended; 'W' / 'w' a 16-bit load; 'b' one byte zero-extended.
       The value goes, with the descriptor's +0 min and +2 max, to sub_FA294F
       (renamed P7Field_ModulateClamped), which returns
           clamp(value + (max-min) * (amount-64) * depth / 16256, min, max)
       and the result is sent as parameter desc[+6] by P7Unit_SendParamValue.

    The READER facts are asserted on the listing (p7_module.s, which
    `make gate-wsa1` proves byte-identical to the dump), instruction by
    instruction at the addresses cited.  The DATA facts are asserted on the
    dump itself (wsa1/original_ROMs/wsa1_prom_c.ic28):
      * every digit string is '0123...' of its type string's length (56/56);
      * in the 51 generic records every descriptor's +4 byte offset lies inside
        the byte span the letters give its +6 index (390/390) -- an
        independent check of the widths;
      * +5 takes 0x62 x204, 0x20 x196, 0x42 x34, 0x77 x4 and never 0x57;
        every 'B' has min < 0, every 'w' max > 255, every 'b' max <= 255.

    With --apply it corrects the three stale statements, writes the two
    routine headers, and renames the routines with
    scripts/renaming/rename_promcd_p7_fields.sed.

RUN
    python3 notes/lanes/promcd-2026-09-25/p7_descriptor_letters.py [--apply]
    make gate-wsa1
"""
import collections
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
MOD = os.path.join(W, "prom_c", "p7", "p7_module.s")
POOL = os.path.join(W, "prom_c", "p7", "p7_stream_pool.s")
TEM = os.path.join(W, "prom_c", "data_tables", "touch_eq_mixer.s")
SED = os.path.join(ROOT, "scripts", "renaming", "rename_promcd_p7_fields.sed")
RENAME = {"sub_FA2784": "P7Unit_SendModulatedField", "sub_FA294F": "P7Field_ModulateClamped"}
RECS, NAMES_B = 0xFDBFD9, 0xF147AC
WIDTH = {"b": 1, "B": 1, "v": 1, "s": 1, "h": 1, "w": 2, "c": 2}
HAND = (12, 13, 14, 43, 55)
DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

# address -> the instruction the listing must hold there (names as AFTER the rename)
READER = {
    # P7Unit_EmitChangedParams: the two cursors, from PoolDir_Records +16 / +20
    "FA3D26": "add xbc, 16", "FA3D2C": "add xbc, PoolDir_Records", "FA3D34": "ld (xiz-22), xbc",
    "FA3D3E": "add xbc, 20", "FA3D44": "add xbc, PoolDir_Records", "FA3D4C": "ld (xiz-26), xbc",
    # the generic walk: NUL test, lockstep advance by one, the letter into (XIZ-54)
    "FA4603": "ld xbc, (xiz-22)", "FA4606": "ld a, (xbc)", "FA4608": "cp a, 0:i3",
    "FA460F": "sub xbc, xbc", "FA4611": "inc 1, xbc",
    "FA4613": "add (xiz-22), xbc", "FA4616": "add (xiz-26), xbc",
    "FA461E": "ld a, (xbc)", "FA4622": "ld (xiz-54), wa",
    # the letter switch
    "FA4735": "ld bc, (xiz-54)",
    "FA4738": "cp bc, 66", "FA473C": "jr z, P7Unit_EmitChangedParams__FA46ED",
    "FA473E": "cp bc, 99", "FA4742": "jrl z, P7Unit_EmitChangedParams__FA469E",
    "FA4745": "cp bc, 0x68", "FA4749": "jrl z, P7Unit_EmitChangedParams__FA4628",
    "FA474C": "cp bc, 0x77", "FA4750": "jrl z, P7Unit_EmitChangedParams__FA4659",
    "FA4753": "jr P7Unit_EmitChangedParams__FA4711",
    # 'h': one byte + 0x500, live and shadow
    "FA462B": "ld a, (xbc)", "FA462D": "extz wa", "FA4631": "add xwa, 0x500", "FA463A": "inc 1, xbc",
    "FA4648": "add xbc, 0x500",
    # 'w': b0 + b1*0x100
    "FA465C": "ld a, (xbc)", "FA4665": "inc 1, xbc", "FA466A": "ld a, (xbc)",
    "FA466E": "mul wa, 0x100", "FA4672": "add (xiz-30), xwa", "FA4675": "inc 1, xbc",
    # 'c': (b0 << 8) + b1
    "FA46A1": "ld a, (xbc)", "FA46AA": "inc 1, xbc", "FA46AF": "ld xix, xwa", "FA46B1": "sll xix, 8",
    "FA46B4": "ld a, (xbc)", "FA46BA": "add xwa, xix", "FA46BF": "inc 1, xbc",
    # 'B': one byte, sign-extended
    "FA46F0": "ld a, (xbc)", "FA46F2": "exts wa", "FA46F9": "inc 1, xbc", "FA4703": "exts bc",
    # anything else: one byte, zero-extended
    "FA4714": "ld a, (xbc)", "FA4716": "extz wa", "FA471D": "inc 1, xbc", "FA4727": "extz bc",
    # the digit is the field index
    "FA475E": "ld xwa, (xiz-26)", "FA4761": "ld c, (xwa)", "FA4764": "calr Base36DigitToValue",
    # the five records that take hand-coded paths
    "FA47EE": "cp bc, 12", "FA47F5": "cp bc, 13", "FA47FC": "cp bc, 14", "FA4803": "cp bc, 43",
    "FA480A": "cp bc, 55", "FA4811": "jrl P7Unit_EmitChangedParams__FA4603",
    # P7Unit_SendModulatedField: record (+24) and descriptor index (+22) from the block
    "FA2790": "add xbc, 24", "FA27A8": "add xbc, 22", "FA27B9": "cp b, 0xFF",
    "FA27C1": "cp (xiz-1), 0x0E", "FA27C8": "cp (xiz-2), 0x0E", "FA27CF": "cp (xiz+10), 0x40",
    "FA27DE": "add xbc, 15", "FA27EA": "ld (xbc), 1", "FA27FA": "add xbc, 0x7E7E",
    "FA2810": "add xbc, 15", "FA281C": "ld (xbc), 0", "FA283C": "calr P7Unit_EmitChangedParams",
    # the descriptor's fields
    "FA284A": "add xbc, PoolDir_FieldRec_PtrTable",
    "FA285C": "inc 2, xwa", "FA2860": "ld iy, (xbc)", "FA2862": "ld (xiz-8), iy",
    "FA286F": "ld wa, (xbc)", "FA2871": "ld (xiz-10), wa",
    "FA287B": "inc 6, xbc", "FA2880": "ld a, (xbc)", "FA2882": "ld (xiz-3), a",
    "FA2895": "inc 4, xwa", "FA28A2": "inc 1, xbc", "FA28A4": "add xbc, 0x856E",
    "FA28B4": "inc 5, xwa", "FA28B9": "ld c, (xwa)", "FA28BD": "ld (xiz-36), bc",
    # the +5 switch and its arms
    "FA28F3": "ld bc, (xiz-36)",
    "FA28F6": "cp bc, 32", "FA28FA": "jr z, P7Unit_SendModulatedField__FA28EE",
    "FA28EE": "jrl P7Unit_SendModulatedField__FA294B",
    "FA28FC": "cp bc, 66", "FA2900": "jr z, P7Unit_SendModulatedField__FA28D8",
    "FA2902": "cp bc, 87", "FA2906": "jr z, P7Unit_SendModulatedField__FA28E4",
    "FA2908": "cp bc, 98", "FA290C": "jr z, P7Unit_SendModulatedField__FA28C2",
    "FA290E": "cp bc, 0x77", "FA2912": "jr z, P7Unit_SendModulatedField__FA28CE",
    "FA28C5": "ld a, (xbc)", "FA28C7": "extz wa",
    "FA28D1": "ld wa, (xbc)",
    "FA28DB": "ld a, (xbc)", "FA28DD": "exts wa",
    "FA28E7": "ld wa, (xbc)",
    "FA292C": "calr P7Field_ModulateClamped", "FA2946": "calr P7Unit_SendParamValue",
    # P7Field_ModulateClamped
    "FA2954": "ld c, (xiz+16)", "FA2957": "and c, 0", "FA295A": "jr z, P7Field_ModulateClamped__FA29A7",
    "FA29A7": "ld ix, (xiz+8)", "FA29B6": "ld wa, (xiz+14)", "FA29BD": "sub xwa, 64",
    "FA29C6": "ld iy, (xiz+12)", "FA29CE": "ld bc, (xiz+10)", "FA29D3": "sub xbc, xiy",
    "FA29D7": "call Multiply32_Signed", "FA29E2": "call Multiply32_Signed",
    "FA29E6": "pushw 0", "FA29E9": "pushw 0x3F80", "FA29ED": "call Divide32_Signed",
    "FA29F1": "add xiy, xix", "FA29FC": "jr le, P7Field_ModulateClamped__FA2A04",
    "FA2A0A": "jr ge, P7Field_ModulateClamped__FA2A12",
}


def norm(s):
    return re.sub(r"\s+", " ", s.strip())


def listing():
    code = {}
    for ln in open(MOD, encoding="latin-1"):
        m = re.match(r"^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s", ln)
        if m:
            t = m.group(1)
            for o, n in RENAME.items():
                t = t.replace(o, n)
            code[m.group(2)] = norm(t)
    return code


def rom(a, n):
    return C[a - 0xF80000:a - 0xF80000 + n]


def cstr(a):
    o = a - 0xF80000
    return C[o:C.index(b"\0", o)].decode("ascii")


def check_reader():
    code = listing()
    bad = [(a, code.get(a), want) for a, want in READER.items() if code.get(a) != norm(want)]
    for b in bad:
        print("  READER MISMATCH at 0x%s: listing %r, expected %r" % b)
    assert not bad
    print("  reader: %d instructions asserted at their addresses" % len(READER))


def check_data():
    ptr = [struct.unpack("<I", rom(0xFDD1CB + 4 * r, 4))[0] for r in range(56)]
    ends = sorted(set(ptr)) + [0xFDD1CB]
    types, flags = [], collections.Counter()
    fit = collections.Counter()
    xt = collections.Counter()
    sign = collections.Counter()
    for r in range(56):
        t = cstr(struct.unpack("<I", rom(RECS + 25 * r + 16, 4))[0])
        d = cstr(struct.unpack("<I", rom(RECS + 25 * r + 20, 4))[0])
        assert d == DIGITS[:len(t)], (r, t, d)
        types.append(t)
        offs, o = [], 0
        for ch in t:
            offs.append(o)
            o += WIDTH[ch]
        a = ptr[r]
        n = (ends[ends.index(a) + 1] - a) // 7
        for i in range(n):
            mn, mx, off, fl, idx = struct.unpack("<hhBBB", rom(a + 7 * i, 7))
            flags[fl] += 1
            ok = idx < len(t) and offs[idx] <= off < offs[idx] + WIDTH[t[idx]]
            fit[(r in HAND, ok)] += 1
            if r not in HAND:
                xt[(t[idx], chr(fl))] += 1
            if fl == 0x42:
                sign["B min<0"] += mn < 0
            if fl == 0x77:
                sign["w max>255"] += mx > 255
            if fl == 0x62:
                sign["b max<=255"] += mx <= 255
                sign["b min>=0"] += mn >= 0
    assert fit[(False, False)] == 0 and fit[(False, True)] == 390, fit
    assert flags == {0x62: 204, 0x20: 196, 0x42: 34, 0x77: 4}, flags
    assert sign["B min<0"] == 34 and sign["w max>255"] == 4 and sign["b max<=255"] == 204, sign
    letters = collections.Counter("".join(types))
    assert [t.count("v") for t in types] == [1] * 56
    s_recs = [r for r, t in enumerate(types) if "s" in t]
    h_recs = [r for r, t in enumerate(types) if "h" in t]
    B_recs = [r for r, t in enumerate(types) if "B" in t]
    c_recs = [r for r, t in enumerate(types) if "c" in t]
    assert s_recs == [12, 13] and set(s_recs) <= set(HAND)
    print("  data: 56/56 digit strings are '0123...' of their type string's length")
    print("  data: generic records' descriptors inside their letter's span: %d/%d; hand-coded: %d/%d"
          % (fit[(False, True)], fit[(False, True)] + fit[(False, False)],
             fit[(True, True)], fit[(True, True)] + fit[(True, False)]))
    print("  data: +5 values", {chr(k): v for k, v in flags.items()}, "--", dict(sign))
    print("  data: letters", dict(letters), "; 'v' once in every record; 's' in", s_recs,
          "; 'h' in", h_recs, "; 'B' in", B_recs, "; 'c' in", c_recs)
    print("  data: generic letter x +5:", ", ".join("%s/%r %d" % (k[0], k[1], v) for k, v in sorted(xt.items())))
    return types


def u(s):
    """UTF-8 text into a latin-1-decoded line list."""
    return s.encode("utf-8").decode("latin-1")


def replace_block(lines, old, new, path):
    old = [u(x) for x in old]
    for i in range(len(lines) - len(old) + 1):
        if lines[i:i + len(old)] == old:
            return lines[:i] + [u(x) for x in new] + lines[i + len(old):]
    sys.exit("block not found in %s: %r" % (path, old[0]))


def insert_after(lines, anchor, new, path):
    a = u(anchor)
    assert lines.count(a) == 1, (path, anchor)
    i = lines.index(a)
    return lines[:i + 1] + [u(x) for x in new] + lines[i + 1:]


def edit(path, fn):
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    lines = fn(lines, path)
    data = "\n".join(lines).encode("latin-1")      # encode BEFORE opening
    open(path, "wb").write(data)


REF = "notes/lanes/promcd-2026-09-25/p7_descriptor_letters.py"


def apply():
    if "P7Unit_SendModulatedField" in open(MOD, encoding="latin-1").read():
        sys.exit("already applied")

    def tem(L, p):
        L = replace_block(L, [
            "; What the letters mean individually is NOT ESTABLISHED -- 'b'/'w' as byte/word",
            "; is the obvious reading but nothing here proves it.",
        ], [
            "; ★ THE LETTERS ARE DECODED FROM THEIR READER (2026-09-25, lane promcd; " + REF + ").",
            "; P7Unit_EmitChangedParams walks a record's type string and digit string in lockstep",
            "; and reads each field of the unit block by its letter (switch at 0xFA4735):",
            ";     'b'  one byte                          'B'  one byte, sign-extended",
            ";     'w'  two bytes, little-endian          'c'  two bytes, BIG-endian",
            ";     'h'  one byte, plus 0x500              any other letter ('v', 's')  one byte",
            "; and the digit, through Base36DigitToValue (0xFA4764), is the field index.  Every digit",
            "; string is '0123...' of its type string's length (56/56), and in the 51 records that",
            "; walker handles every field descriptor's +4 byte offset lies inside the span the letters",
            "; give its index (390/390) -- the widths are confirmed by a second table.  'v' occurs",
            "; exactly once in every record (56/56); 's' only in records 12 and 13 (PEDAL WAH, AUTO",
            "; WAH), which the walker hands to hand-coded paths, so what 'v' and 's' select beyond a",
            "; one-byte width is still open.  (Corrected: the two lines that stood here said the",
            "; letters' individual meaning was unproven and byte/word only the obvious reading.)",
        ], p)
        L = insert_after(L, "; ⚠ What any constant is FOR is NOT established; the comments give values only.", [
            "; (2026-09-25, lane promcd: each element's header now also gives its loading sites and",
            "; the double-library call it is pushed for -- pool_element_readers.py,",
            "; pool_element_consumers.py.  What the constants are FOR is still the open question.)",
        ], p)
        return L

    def pool(L, p):
        L = insert_after(L, ";       uint8_t  flag;              /* +5                                          */", [
            ";       /* +5 is a VALUE-TYPE letter -- 'b' u8, 'B' s8, 'w' u16, ' ' not sent --  */",
            ";       /* read by P7Unit_SendModulatedField's switch at 0xFA28F3              */",
        ], p)
        L = replace_block(L, [
            ";       +5      u8    a flag.  ⚠ NOT DECODED.  It takes only four values in the whole",
            ";                     table -- 0x62 x204, 0x20 x196, 0x42 x34, 0x77 x4 -- and nothing",
            ";                     here reads them.",
        ], [
            ";       +5      u8    VALUE TYPE, an ASCII letter: 0x62 'b' x204, 0x20 ' ' x196,",
            ";                     0x42 'B' x34, 0x77 'w' x4.  P7Unit_SendModulatedField reads it",
            ";                     (`inc 5,XWA` 0xFA28B4) and switches on it (0xFA28F3): 'b' one",
            ";                     byte zero-extended, 'B' one byte sign-extended, 'w' (and 'W',",
            ";                     which no descriptor holds) a 16-bit load, ' ' sends nothing.",
            ";                     Every 'B' has a negative minimum (34/34), every 'w' a maximum",
            ";                     above 255 (4/4), every 'b' a maximum of at most 255 (204/204).",
            ";                     (Corrected 2026-09-25, lane promcd, " + REF.split("/")[-1] + ":",
            ";                     these lines called it an undecoded flag that nothing read.)",
        ], p)
        L = replace_block(L, [
            "; ⚠ What a 7-byte entry MEANS is not established.",
        ], [
            "; ★ WHAT A 7-BYTE ENTRY IS (2026-09-25, lane promcd): the descriptor of one field -- or of",
            "; one byte of a two-byte field -- of an effect's parameter block: its range (+0/+2, the",
            "; bounds P7Field_ModulateClamped clamps to), its place (+4), its value type (+5) and its",
            "; index (+6, the position of its letter in the record's type string).  In the 51 records",
            "; P7Unit_EmitChangedParams' generic walker handles, every +4 lies inside the byte span the",
            "; type-string letters give that index (390/390; " + REF.split("/")[-1] + ").",
            "; (Corrected: this line said what an entry means was open.)",
        ], p)
        return L

    def mod(L, p):
        L = replace_block(L, [
            ";   * what the descriptor type letters {b, w, v, s, h, c, B} mean, or the flag at",
            ";     descriptor +5 (four values in the whole table: 0x62, 0x20, 0x42, 0x77).",
        ], [
            ";   * (CORRECTED 2026-09-25, lane promcd: the descriptor type letters and the +5 byte",
            ";     are decoded from their readers -- see P7Unit_EmitChangedParams and",
            ";     P7Unit_SendModulatedField.  What remains is what 'v' and 's' select beyond a",
            ";     one-byte width: the generic walker reads both as one byte, and 's' occurs only in",
            ";     records 12 and 13, which take hand-coded paths.)",
        ], p)
        L = replace_block(L, [
            "; Unknown:  what the descriptor TYPE LETTERS mean.  The comparison and the emission",
            ";          are traced; the alphabet {b,w,v,s,h,c,B} is not decoded.",
        ], [
            "; ★ TYPE LETTERS (lane promcd, 2026-09-25; " + REF + ").",
            ";          Records 12, 13, 14, 43 and 55 take hand-coded paths (switch at 0xFA47EB);",
            ";          for every other record the GENERIC walker steps the type string (+16,",
            ";          cursor XIZ-22) and the digit string (+20, XIZ-26) in lockstep, one character",
            ";          each (0xFA460F-0xFA4616), stops at the NUL (0xFA4608), and reads each field",
            ";          of the live block (XIZ-14) and of the shadow (XIZ-18) by its letter:",
            ";            'B'   one byte, sign-extended           0xFA46ED  exts WA / exts BC",
            ";            'c'   two bytes, BIG-endian (b0<<8|b1)  0xFA469E  sll 0x08,XIX / add XWA,XIX",
            ";            'h'   one byte, plus 0x500              0xFA4628  add XWA,0x00000500",
            ";            'w'   two bytes, little-endian          0xFA4659  mul WA,0x0100",
            ";            else  one byte ('b', 'v'; 's' is never seen here)  0xFA4711",
            ";          and where they differ the digit is the field index (Base36DigitToValue,",
            ";          0xFA4764).  The widths agree with the descriptors' +4 offsets in all 51",
            ";          records this walker handles (390/390).  Still open: what 'v' (once in every",
            ";          record) and 's' select beyond width.  (Corrected: this said the alphabet was",
            ";          not decoded.)",
        ], p)
        # the two routine headers
        L = replace_block(L, [
            "; Calls:   0xFA294F = sub_FA294F, 0xFA2D11 = P7Unit_SendParamValue",
            ";          0xFA3CD7 = P7Unit_EmitChangedParams",
            "; Evidence: the listing below is the byte-identical round-trip of 0xFA2784-0xFA294E",
            ";          (notes/gen_prom_c_block.py, cleared by",
            ";          notes/prom_c_verify_fragment.py before insertion).  Every field above",
            ";          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;",
            ";          the call sites are notes/prom_c_module_map.py's image-wide scan.",
            "; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,",
            ";          so the name is an address.",
        ], [
            "; Calls:   0xFA294F = sub_FA294F, 0xFA2D11 = P7Unit_SendParamValue",
            ";          0xFA3CD7 = P7Unit_EmitChangedParams",
            "; Evidence: the listing below is the byte-identical round-trip of 0xFA2784-0xFA294E",
            ";          (notes/gen_prom_c_block.py, cleared by",
            ";          notes/prom_c_verify_fragment.py before insertion).  Every field above",
            ";          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;",
            ";          the call sites are notes/prom_c_module_map.py's image-wide scan.",
            "; ★ NAMED 2026-09-25 (lane promcd; " + REF + ").",
            "; Name:    sends ONE field of a unit -- the one its block names at +22 -- offset by a",
            ";          caller's amount: (unit, amount, flag, depth, mode).",
            "; Evidence: block +22 is a descriptor index (`add XBC,0x00000016` 0xFA27A8; 0xFF = none,",
            ";          return at 0xFA27B9) into the field descriptors of the record at block +24",
            ";          (0xFA2790).  The field is read at block +1+desc[+4] (0xFA2895-0xFA28A4) by",
            ";          the desc[+5] letter (switch 0xFA28F3: ' ' returns, 'B' exts, 'W'/'w' 16-bit,",
            ";          'b' extz), handed with desc[+0] min and desc[+2] max (0xFA286F, 0xFA2860)",
            ";          and amount/flag/depth to sub_FA294F (0xFA292C), and the result is sent as",
            ";          parameter desc[+6] (0xFA2880) by P7Unit_SendParamValue (0xFA2946), the",
            ";          fifth argument as its mode.  Record 14 (ROTARY SPEAKER) with descriptor 14",
            ";          is special-cased at 0xFA27C1-0xFA2805: block +15 and its twin at RAM",
            ";          0x7E7E + 26*unit + 15 become 1 when the amount is >= 0x40, else 0, and",
            ";          P7Unit_EmitChangedParams runs.  The calls at 0xFA2BEC and 0xFA2C04 pass",
            ";          amount 64 and depth 0 -- an offset of zero, i.e. the field as it stands.",
            ";          (Corrected: this header said nothing here read the meaning of a field.)",
        ], p)
        L = replace_block(L, [
            "; Calls:   0xFCB0D3 = Multiply32_Signed, 0xFCB141 = Divide32_Signed",
            "; Evidence: the listing below is the byte-identical round-trip of 0xFA294F-0xFA2A18",
            ";          (notes/gen_prom_c_block.py, cleared by",
            ";          notes/prom_c_verify_fragment.py before insertion).  Every field above",
            ";          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;",
            ";          the call sites are notes/prom_c_module_map.py's image-wide scan.",
            "; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,",
            ";          so the name is an address.",
        ], [
            "; Calls:   0xFCB0D3 = Multiply32_Signed, 0xFCB141 = Divide32_Signed",
            "; Evidence: the listing below is the byte-identical round-trip of 0xFA294F-0xFA2A18",
            ";          (notes/gen_prom_c_block.py, cleared by",
            ";          notes/prom_c_verify_fragment.py before insertion).  Every field above",
            ";          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;",
            ";          the call sites are notes/prom_c_module_map.py's image-wide scan.",
            "; ★ NAMED 2026-09-25 (lane promcd; " + REF + ").",
            "; Name:    (value, max, min, amount, flag, depth) ->",
            ";              clamp(value + (max - min) * (amount - 64) * depth / 16256, min, max)",
            "; Evidence: `sub XWA,0x00000040` 0xFA29BD (amount - 64), `sub XBC,XIY` 0xFA29D3",
            ";          (max - min), Multiply32_Signed at 0xFA29D7 and 0xFA29E2, Divide32_Signed by",
            ";          0x00003F80 = 16256 = 127*128 (0xFA29E6-0xFA29ED), `add XIY,XIX` 0xFA29F1",
            ";          (+ value), then the clamp to max (0xFA29F9) and to min (0xFA2A07).  The only",
            ";          caller, 0xFA292C, passes the field descriptor's min and max.  The flag",
            ";          argument cannot choose the other arm (the same sum without the -64):",
            ";          `ld C,(XIZ+0x10) / and C,0x00` at 0xFA2954-0xFA2957 is always zero, so",
            ";          `jr Z` at 0xFA295A always takes the -64 arm.",
            ";          (Corrected: this header said nothing here read the meaning of a field.)",
        ], p)
        return L

    edit(TEM, tem)
    edit(POOL, pool)
    edit(MOD, mod)
    for p in (MOD, POOL):
        subprocess.check_call(["sed", "-i", "-f", SED, p], env=dict(os.environ, LC_ALL="C"))
    print("  applied: corrections in touch_eq_mixer.s, p7_stream_pool.s, p7_module.s; renamed",
          ", ".join("%s -> %s" % kv for kv in RENAME.items()))


if __name__ == "__main__":
    applying = "--apply" in sys.argv
    check_reader()
    check_data()
    if applying:
        apply()
        check_reader()
    print("ALL ASSERTIONS HOLD")
