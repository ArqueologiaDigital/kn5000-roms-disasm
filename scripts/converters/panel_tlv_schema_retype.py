#!/usr/bin/env python3
r"""panel_tlv_schema_retype.py -- type the panel TLV schema in naka_extension_device.c (v10/v9/v7).

QUESTION ANSWERED
-----------------
0xED8ADA..0xED92D8 of the naka_extension_device blob (+0x230E..+0x2B0C, 2,046 B) is not widget data.  It is the
schema of the panel TLV stream (docs/kn-disk-file-formats.md, "The framing is FIRMWARE FACT"):

  +0x230E  32 field-rule lists, each ended by 0xFF and followed by one more 0xFF when that leaves it at an
           odd address (the next list starts even);
  +0x2814  PanelTlv_Block0_Layout, 46 x 10 B: the records of block 0 (live panel RAM 0xF9A0, and each of the
           80 panel memories at 0x1ED400 + 960*n);
  +0x29E0  PanelTlv_Block1_Layout, 30 x 10 B: the records of block 1 (live panel RAM 0xFD60).

A layout record is {u32 offset of the record from the block base, u32 -> its rule list, u8 tag, u8 len}.
PanelTlv_WriteRecordHeader (audio/tonegen_fileio_handlers.s) stores tag and len at base + offset;
PanelTlv_ValidateRecord walks the rule list over the payload at base + offset + 2, one rule per call of
PanelTlv_ApplyFieldRule, whose type byte selects one of nine cases through PanelTlv_ApplyFieldRule_CaseOffsets.
Each case returns the rule's length in hl:

  type 0  {0, off, mask}                     payload[off] &= mask                        PanelTlv_Rule_KeepBits
  type 1  {1, off, mask}                     payload[off] &= ~mask                       PanelTlv_Rule_ClearBits
  type 2  {2, off, mask}                     payload[off] |= mask                        PanelTlv_Rule_SetBits
  type 3  {3, off, mask, lo, hi, dflt}       field (= byte & mask) outside lo..hi -> dflt PanelTlv_Rule_ResetOutsideRange
  type 4  {4, off, mask, lo, hi, dflt}       field inside lo..hi -> dflt                 PanelTlv_Rule_ResetInsideRange
  type 5  {5, off, mask, n, dflt, v1..vn}    field not among v1..vn -> dflt              PanelTlv_Rule_ResetUnlessListed
  type 6  {6, off, mask, n, dflt, v1..vn}    field among v1..vn -> dflt                  PanelTlv_Rule_ResetIfListed
  type 7  {7, off, value}                    payload[off] = value                        PanelTlv_Rule_StoreByte
  type 8  {8, off}                           payload[off] = 0                            PanelTlv_Rule_ZeroByte

("-> dflt" keeps the bits outside the mask: byte = (byte & ~mask) | dflt.)  The generic decoder had spelled the
region as 600-odd field_XXXX / ptr_XXXX / str_N / pad_N members.  This script replaces them with one uint8_t
array per rule list, written with RULE_* macros, and two arrays of panel_tlv_layout_t, keeping every pointer as
SELF(list).  Asserted before writing: the lists tile +0x230E..+0x2814 exactly with 0xFF padding only, every type
byte is 0..8, every layout pointer lands on a list start, and every record chains -- offset[i+1] = offset[i] +
2 + len[i] -- in both blocks.

The values are read from the blob compiled from the unmodified C; the result must be byte-identical (`make all`,
compare_roms.py).  The C comment gate needs `--allow '/\* zero padding \*/'`: those are the generator's notes on
members that were bytes of the lists and tables.

RUN (repository root, built tree)
    python3 scripts/converters/panel_tlv_schema_retype.py            # report
    python3 scripts/converters/panel_tlv_schema_retype.py --apply    # rewrite the three C files
    python3 scripts/converters/panel_tlv_schema_retype.py --asm [--apply]   # the .s headers and labels, after
        sed -i -f scripts/renaming/rename_panel_tlv_schema.sed  (the DSPCfg_* / ToneGen_* routine renames)
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M          # noqa: E402

TREES = ("v10", "v9", "v7")
BASE = 0xED67CC
RULES, LAYOUT0, LAYOUT1, END = 0x230E, 0x2814, 0x29E0, 0x2B0C
COUNT0, COUNT1 = 46, 30
LEN = {0: 3, 1: 3, 2: 3, 3: 6, 4: 6, 7: 3, 8: 2}
MACRO = {0: "RULE_KEEP_BITS", 1: "RULE_CLEAR_BITS", 2: "RULE_SET_BITS", 3: "RULE_RANGE", 4: "RULE_NOT_RANGE",
         5: "RULE_ONE_OF", 6: "RULE_NONE_OF", 7: "RULE_STORE", 8: "RULE_ZERO"}
LOW_MASKS = {0x01, 0x03, 0x07, 0x0F, 0x1F, 0x3F, 0x7F, 0xFF}
# member -> symbol: rule/record bytes the generic decoder read as NAKA_ADDR (no other reader of either symbol)
FALSE_POINTERS = {"NakaData_FileScreenDispatch_ptr": "NakaData_FileScreenDispatch",   # +0x2594, tag 0x48's rules
                  "NakaData_StyleBitmapPad_ptr": "NakaData_StyleBitmapPad"}           # +0x286C, records 8/9

TYPEDEF = r'''/* -- Panel TLV schema (+0x230E..+0x2B0C; scripts/converters/panel_tlv_schema_retype.py) --
 * The live panel (RAM 0xF9A0 = block 0, 0xFD60 = block 1) and each of the 80 panel memories (RAM
 * 0x1ED400 + 960*n, block 0 only) are streams of [tag][len][payload] records.  A layout record says where
 * one record sits and which rules its payload obeys.  PanelTlv_WriteRecordHeader stores tag and len at
 * base + record_offset; PanelTlv_ValidateRecord runs the rule list over the payload, which starts at
 * base + record_offset + 2, one PanelTlv_ApplyFieldRule call per rule.  Records chain:
 * record_offset[i + 1] = record_offset[i] + 2 + len[i].  The last record of each block is tag 0xFF, len
 * 0xFF with no rules: the stream's FF FF end mark. */
typedef struct __attribute__((packed)) {
    uint32_t record_offset;  /* of the tag byte, from the block base */
    uint32_t field_rules;    /* SELF(list): the RULE_* list below, ended by RULES_END */
    uint8_t  tag;
    uint8_t  len;            /* payload bytes after the 2-byte header */
} panel_tlv_layout_t;

/* One field rule = one PanelTlv_ApplyFieldRule case, by its type byte.  `off` is a payload byte; `mask` picks
 * the bits a rule governs, and a reset keeps the bits outside it: byte = (byte & ~mask) | dflt. */
#define RULE_KEEP_BITS(off, mask)               0, (off), (mask)                    /* byte &= mask */
#define RULE_CLEAR_BITS(off, mask)              1, (off), (mask)                    /* byte &= ~mask */
#define RULE_SET_BITS(off, mask)                2, (off), (mask)                    /* byte |= mask */
#define RULE_RANGE(off, mask, lo, hi, dflt)     3, (off), (mask), (lo), (hi), (dflt) /* outside lo..hi -> dflt */
#define RULE_NOT_RANGE(off, mask, lo, hi, dflt) 4, (off), (mask), (lo), (hi), (dflt) /* inside lo..hi -> dflt */
#define RULE_ONE_OF(off, mask, n, dflt, ...)    5, (off), (mask), (n), (dflt), __VA_ARGS__ /* not listed -> dflt */
#define RULE_NONE_OF(off, mask, n, dflt, ...)   6, (off), (mask), (n), (dflt), __VA_ARGS__ /* listed -> dflt */
#define RULE_STORE(off, value)                  7, (off), (value)                   /* byte = value */
#define RULE_ZERO(off)                          8, (off)                            /* byte = 0 */
#define RULES_END                               0xFF
'''


def le(b, o, n):
    return int.from_bytes(b[o:o + n], "little")


def parse_list(b, o):
    rules = []
    while b[o] != 0xFF:
        t = b[o]
        assert 0 <= t <= 8, (hex(o), t)
        n = 5 + b[o + 3] if t in (5, 6) else LEN[t]
        rules.append(bytes(b[o:o + n]))
        o += n
    return rules, o + 1


def val(v, mask):
    return "%d" % v if mask in LOW_MASKS else "0x%02X" % v


def render_rule(r):
    t, off = r[0], r[1]
    if t in (0, 1, 2):
        args = ["%d" % off, "0x%02X" % r[2]]
    elif t in (3, 4):
        mask, lo, hi, d = r[2], r[3], r[4], r[5]
        if mask == 0xFF and lo == 0x20 and hi < 0x7F and d == 0x20:
            args = ["%d" % off, "0xFF", "' '", "'%s'" % chr(hi), "' '"]
        else:
            args = ["%d" % off, "0x%02X" % mask, val(lo, mask), val(hi, mask), val(d, mask)]
    elif t in (5, 6):
        mask, n, d = r[2], r[3], r[4]
        assert len(r) == 5 + n
        args = ["%d" % off, "0x%02X" % mask, "%d" % n, val(d, mask)] + [val(x, mask) for x in r[5:]]
    elif t == 7:
        args = ["%d" % off, "%d" % r[2]]
    else:
        args = ["%d" % off]
    return "%s(%s)" % (MACRO[t], ", ".join(args))


def decode(b):
    blocks = []
    for start, count, base in ((LAYOUT0, COUNT0, 0xF9A0), (LAYOUT1, COUNT1, 0xFD60)):
        recs = []
        for i in range(count):
            e = start + 10 * i
            recs.append((le(b, e, 4), le(b, e + 4, 4) - BASE, b[e + 8], b[e + 9]))
        for i in range(count - 1):
            assert recs[i + 1][0] == recs[i][0] + 2 + recs[i][3], (hex(base), i, recs[i], recs[i + 1])
        assert recs[-1][2:] == (0xFF, 0xFF), recs[-1]
        blocks.append((start, count, base, recs))
    starts = sorted({r[1] for _, _, _, recs in blocks for r in recs})
    assert starts[0] == RULES, hex(starts[0])
    lists = {}
    for k, s in enumerate(starts):
        nxt = starts[k + 1] if k + 1 < len(starts) else LAYOUT0
        rules, end = parse_list(b, s)
        assert s % 2 == 0 and end in (nxt, nxt - 1), (hex(s), hex(end), hex(nxt))
        assert all(x == 0xFF for x in b[end:nxt]), hex(s)
        lists[s] = (rules, nxt - s, nxt - end)
    return blocks, lists


def list_names(blocks):
    users, names = {}, {}
    for blk, (_, _, base, recs) in enumerate(blocks):
        for i, (off, ptr, tag, ln) in enumerate(recs):
            users.setdefault(ptr, []).append((blk, i, off, tag, ln))
    for ptr, us in users.items():
        tag = us[0][3]
        names[ptr] = "PanelTlv_Rules_End" if tag == 0xFF else "PanelTlv_Rules_Tag%02X" % tag
    assert len(set(names.values())) == len(names)
    return users, names


def users_text(us):
    """'block 0 tag 0x78 (+0x000, len 18)', 'block 0 tags 0x00-0x0E (len 24)', 'block 0 end mark (+0x3BE)'."""
    out = []
    for blk in sorted({u[0] for u in us}):
        mine = [u for u in us if u[0] == blk]
        if mine[0][3] == 0xFF:
            out.append("block %d end mark (+0x%03X)" % (blk, mine[0][2]))
        elif len(mine) == 1:
            out.append("block %d tag 0x%02X (+0x%03X, len %d)" % (blk, mine[0][3], mine[0][2], mine[0][4]))
        else:
            tags = [u[3] for u in mine]
            runs, k = [], 0
            while k < len(tags):
                j = k
                while j + 1 < len(tags) and tags[j + 1] == tags[j] + 1:
                    j += 1
                runs.append("0x%02X" % tags[k] if j == k else "0x%02X-0x%02X" % (tags[k], tags[j]))
                k = j + 1
            lens = sorted({u[4] for u in mine})
            out.append("block %d tags %s (len %s)" % (blk, ", ".join(runs), "/".join(map(str, lens))))
    return ", ".join(out)


def build(b):
    blocks, lists = decode(b)
    users, names = list_names(blocks)
    new = []
    first = True
    for s in sorted(lists):
        rules, size, pad = lists[s]
        us = users[s]
        who = users_text(us)
        pre = []
        if first:
            pre += M.comment_block(
                "The 32 field-rule lists, in ROM order.  Each list is named after the first tag that\n"
                "uses it; the comment above it names every user.  An odd-length list carries one more\n"
                "0xFF so that the next list starts at an even address.")
            first = False
        pre.append("    /* %s: %s%s */" % (names[s], who, "" if rules else "; no rules"))
        body = ["        %s," % render_rule(r) for r in rules]
        if s == 0x2310:
            body.insert(14, "        /* the firmware checks byte 13 twice and byte 14 never */")
        body.append("        RULES_END,%s" % (" 0xFF  /* to an even address */" if pad else ""))
        expr = "{\n" + "\n".join(body) + "\n    }"
        new.append(M.NewMember("uint8_t", names[s], "[%d]" % size, size, expr, pre))
    for blk, (start, count, base, recs) in enumerate(blocks):
        rows = []
        for i, (off, ptr, tag, ln) in enumerate(recs):
            rows.append("        /* %2d */ { 0x%03X, SELF(%s), 0x%02X, %s }," %
                        (i, off, names[ptr], tag, "0xFF" if tag == 0xFF else "%d" % ln))
        name = "PanelTlv_Block%d_Layout" % blk
        pre = ["    /* %s: the %d records of block %d (RAM 0x%04X%s), read by PanelTlv_WriteBlock%dHeaders"
               " and PanelTlv_ValidateBlock%d (audio/tonegen_fileio_handlers.s) */"
               % (name, count, blk, base, "; and the 80 panel memories at 0x1ED400 + 960*n" if blk == 0 else "",
                  blk, blk)]
        new.append(M.NewMember("panel_tlv_layout_t", name, "[%d]" % count, 10 * count,
                               "{\n" + "\n".join(rows) + "\n    }", pre))
    return new, blocks, lists


# ---------------------------------------------------------------------------------------------- the .s side
STALE = re.compile(r'^; PanelTlv_ValidateBlock0 (handler: entry \d|setup before dispatch|bounds check and dispatch|'
                   r'dispatch|finalize after dispatch)$')
ROUTINE_HEADERS = {
    "PanelTlv_ValidateLivePanel": [
        "; Validate the live panel -- block 0 at RAM 0xF9A0, block 1 at 0xFD60 -- then ToneGen_DispatchByMode."],
    "PanelTlv_ValidatePanelMemories": [
        "; Validate block 0 of each of the 80 panel memories (RAM 0x1ED400 + 960*n)."],
    "PanelTlv_ValidatePanelMemory": [
        "; Validate block 0 of panel memory wa, at RAM 0x1ED400 + 960*wa (wa >= 80 returns at once)."],
    "PanelTlv_ValidateAll": [
        "; Validate the live panel, then the 80 panel memories."],
    "PanelTlv_WriteAllHeaders": [
        "; Write every record header ([tag][len]) of the live panel and of the 80 panel memories."],
    "PanelTlv_WriteLivePanelHeaders": [
        "; Write the record headers of the live panel: block 0 at RAM 0xF9A0, block 1 at 0xFD60."],
    "PanelTlv_WritePanelMemoryHeaders": [
        "; Write the block-0 record headers of each of the 80 panel memories (RAM 0x1ED400 + 960*n)."],
    "PanelTlv_WriteBlock0Headers": [
        "; xwa = a block-0 base.  PanelTlv_WriteRecordHeader for each of the 46 PanelTlv_Block0_Layout records",
        "; (10 bytes each: index*5*2)."],
    "PanelTlv_ValidateBlock0": [
        "; xwa = a block-0 base.  PanelTlv_ValidateRecord for each of the 46 PanelTlv_Block0_Layout records; then",
        "; the five effect records go to DSPCfg_WriteAllSlots_Combined as slots 0..4 -- tags 0x61, 0x63, 0x65, 0x66,",
        "; 0x64, whose payloads sit at base + 0x2D4, 0x2EE, 0x322, 0x33C, 0x308 (spelled 0xFC74.. - 0xF9A0 below)."],
    "PanelTlv_ValidateBlock1": [
        "; xwa = a block-1 base.  PanelTlv_ValidateRecord for each of the 30 PanelTlv_Block1_Layout records."],
    "PanelTlv_ValidateRecord": [
        "; xwa = block base, xbc -> a layout record {u32 record_offset, u32 -> field rules, u8 tag, u8 len}",
        "; (PanelTlv_Block0_Layout / PanelTlv_Block1_Layout, typed as panel_tlv_layout_t in",
        "; ui_widgets/naka_extension_device.c).  The payload starts at base + record_offset + 2; the rules are",
        "; applied in order, each by PanelTlv_ApplyFieldRule, which returns the rule's length in hl, up to the 0xFF",
        "; that ends the list."],
    "PanelTlv_ApplyFieldRule": [
        "; xwa = record payload, xbc -> one field rule.  Byte 0 is the type; the case named below applies it and",
        "; returns its length in hl.  `off` is a payload byte; a reset keeps the bits outside the mask:",
        ";   0 {0, off, mask}                  payload[off] &= mask                          KeepBits",
        ";   1 {1, off, mask}                  payload[off] &= ~mask                         ClearBits",
        ";   2 {2, off, mask}                  payload[off] |= mask                          SetBits",
        ";   3 {3, off, mask, lo, hi, dflt}    (byte & mask) outside lo..hi -> dflt          ResetOutsideRange",
        ";   4 {4, off, mask, lo, hi, dflt}    (byte & mask) inside lo..hi -> dflt           ResetInsideRange",
        ";   5 {5, off, mask, n, dflt, v1..vn} (byte & mask) not among v1..vn -> dflt        ResetUnlessListed",
        ";   6 {6, off, mask, n, dflt, v1..vn} (byte & mask) among v1..vn -> dflt            ResetIfListed",
        ";   7 {7, off, value}                 payload[off] = value                          StoreByte",
        ";   8 {8, off}                        payload[off] = 0                              ZeroByte",
        "; The rule lists are PanelTlv_FieldRules (ui_widgets/extension_device_screens.s), written out with RULE_*",
        "; macros in ui_widgets/naka_extension_device.c."],
    "PanelTlv_ApplyFieldRule_Case0": [
        "; the nine cases, by type byte, through PanelTlv_ApplyFieldRule_CaseOffsets"],
    "PanelTlv_ApplyFieldRule_UnknownType": [
        "; a type byte above 8 counts as a 1-byte rule"],
    "PanelTlv_WriteBlock1Headers": [
        "; xwa = a block-1 base.  PanelTlv_WriteRecordHeader for each of the 30 PanelTlv_Block1_Layout records."],
    "PanelTlv_WriteRecordHeader": [
        "; xwa = block base, xbc -> a layout record: base[record_offset] = tag, base[record_offset + 1] = len."],
}
TABLE_HEADERS = {
    "PanelTlv_FieldRules": (0x230E, 0x506, [
        "; PanelTlv_FieldRules -- the 32 field-rule lists of the panel TLV schema (+0x230e..+0x2814, 1286 B):",
        "; each list is ended by 0xFF, and by one more 0xFF when that leaves it at an odd address.  Read by",
        "; PanelTlv_ValidateRecord through the +4 pointer of every PanelTlv_Block0_Layout / PanelTlv_Block1_Layout",
        "; record; PanelTlv_ApplyFieldRule (audio/tonegen_fileio_handlers.s) decodes one rule per call, type byte",
        "; 0..8.  Typed in ui_widgets/naka_extension_device.c as PanelTlv_Rules_<first tag> with RULE_* macros."]),
    "PanelTlv_Block0_Layout": (0x2814, 0x1CC, [
        "; PanelTlv_Block0_Layout -- 46 records x 10 B {u32 record_offset, u32 -> field rules, u8 tag, u8 len}:",
        "; where each [tag][len][payload] record of panel block 0 sits -- the live panel at RAM 0xF9A0 and each of",
        "; the 80 panel memories at 0x1ED400 + 960*n.  Records chain (offset[i+1] = offset[i] + 2 + len[i]); the",
        "; last, tag 0xFF len 0xFF at +0x3BE, is the stream's FF FF end mark.  Read by PanelTlv_WriteBlock0Headers",
        "; (tag, len) and PanelTlv_ValidateBlock0 (rules); typed as panel_tlv_layout_t in",
        "; ui_widgets/naka_extension_device.c.  See docs/kn-disk-file-formats.md, \"The framing is FIRMWARE FACT\"."]),
    "PanelTlv_Block1_Layout": (0x29E0, 0x12C, [
        "; PanelTlv_Block1_Layout -- 30 records x 10 B, the same shape for panel block 1 (live panel RAM 0xFD60,",
        "; tags 0x17, 0x18, 0x98, 0x91, 0x93, 0xC0..0xD4, 0xD7, 0x49, 0x9A; end mark at +0x25E).  Read by",
        "; PanelTlv_WriteBlock1Headers and PanelTlv_ValidateBlock1; typed as panel_tlv_layout_t in",
        "; ui_widgets/naka_extension_device.c."]),
}
INCBIN = '.incbin "includes/generated/naka_extension_device.bin", 0x%X, 0x%X'


def apply_asm(tree, apply):
    out = []
    p = os.path.join(ROOT, tree, "maincpu", "audio", "tonegen_fileio_handlers.s")
    L = open(p, "rb").read().decode("latin-1").split("\n")
    if not any(l.startswith("; xwa = a block-0 base.") for l in L):
        n_stale = sum(1 for l in L if STALE.match(l))
        L = [l for l in L if not STALE.match(l)]
        for lab, hdr in ROUTINE_HEADERS.items():
            k = L.index(lab + ":")
            L[k:k] = hdr
        out.append((p, L, "%d stale comments dropped, %d headers" % (n_stale, len(ROUTINE_HEADERS))))
    p = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "extension_device_screens.s")
    L = open(p, "rb").read().decode("latin-1").split("\n")
    if not any(l.startswith("PanelTlv_FieldRules:") for l in L):
        for lab, (off, size, hdr) in TABLE_HEADERS.items():
            inc = INCBIN % (off, size)
            k = next(i for i, l in enumerate(L) if l.startswith("\t" + inc) or l == lab + ":")
            if L[k] == lab + ":":
                assert L[k + 1] == "\t" + inc, L[k + 1]
                j = k
                while L[j - 1].startswith("; [nakarest]"):
                    j -= 1
                L[j:k + 2] = hdr + ["%s:\t%s" % (lab, inc)]
            else:
                L[k:k + 1] = hdr + ["%s:\t%s" % (lab, inc)]
        out.append((p, L, "3 slices headed and labelled"))
    for path, lines, what in out:
        print("  %s: %s" % (os.path.relpath(path, ROOT), what))
        if apply:
            data = "\n".join(lines).encode("latin-1")
            open(path + ".tmp", "wb").write(data)
            os.replace(path + ".tmp", path)


def main():
    apply = "--apply" in sys.argv
    if "--asm" in sys.argv:
        for tree in TREES:
            print(tree)
            apply_asm(tree, apply)
        return
    M.TYPE_SIZES["panel_tlv_layout_t"] = 10
    for tree in TREES:
        path = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_extension_device.c")
        blob = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_extension_device.bin"),
                    "rb").read()
        text = open(path, encoding="latin-1").read()
        if "PanelTlv_Block0_Layout" in text:
            print("%s: already typed" % tree)
            continue
        cb = M.CBlob(path)
        assert cb.base() == BASE
        new, blocks, lists = build(blob)
        sym = {mb.name: cb.entries[cb.by_name[mb.name]].expr for mb in cb.members
               if RULES <= mb.offset < END and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)}
        gone_ptrs = [n for n, e in sym.items() if e.startswith("SELF(")]
        false_ptrs = sorted(set(sym) - set(gone_ptrs))
        assert false_ptrs == sorted(FALSE_POINTERS), false_ptrs
        new[-1]._keeps.update(gone_ptrs)
        new[-2]._keeps.update(gone_ptrs)
        k0, k1 = cb.index_at(RULES), cb.index_at(END - 1)
        n_old = k1 - k0 + 1
        cb.retype(RULES, END, new, blob, false_pointers=false_ptrs)
        # the two false pointers' symbols are used nowhere else in the file: drop their externs and link lines
        ld = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_extension_device_link.ld")
        ld_lines = open(ld, encoding="latin-1").read().split("\n")
        for sname in FALSE_POINTERS.values():
            body = cb.render()
            assert body.count(sname) == 1, (sname, body.count(sname))     # the extern alone
            k = cb.lines.index("extern const char %s;" % sname)
            assert k < cb.s0
            del cb.lines[k]
            for a in ("s0", "s1", "i0", "i1"):
                setattr(cb, a, getattr(cb, a) - 1)
            ld_lines = [l for l in ld_lines if not l.startswith("%s = " % sname)]
        lines = TYPEDEF.rstrip("\n").split("\n") + [""]
        cb.lines[cb.s0:cb.s0] = lines
        for a in ("s0", "s1", "i0", "i1"):
            setattr(cb, a, getattr(cb, a) + len(lines))
        print("%s: %d members -> %d (%d rule lists, 2 layout tables of %d + %d records); %d pointers kept as SELF"
              % (tree, n_old, len(new), len(lists), COUNT0, COUNT1, len(gone_ptrs)))
        if apply:
            data = cb.render().encode("latin-1")
            open(path + ".tmp", "wb").write(data)
            os.replace(path + ".tmp", path)
            open(ld + ".tmp", "wb").write("\n".join(ld_lines).encode("latin-1"))
            os.replace(ld + ".tmp", ld)


if __name__ == "__main__":
    main()
