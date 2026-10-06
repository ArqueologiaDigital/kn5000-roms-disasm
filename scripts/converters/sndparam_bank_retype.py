#!/usr/bin/env python3
r"""sndparam_bank_retype.py -- type the sound-parameter banks in C: the 25 ROM presets and the 3 flash defaults.

QUESTION ANSWERED
-----------------
A sound-parameter bank (technics-docs custom-data-flash.md, "Sound-Parameter User Banks") is 234 bytes: 39
six-byte entries {u32 live-panel RAM address, u8 b4, u8 b5}, address 0 = unused.  SndParam_GetBlockPointer hands
out block n: 0..24 are ROM presets (SndParam_PresetBanks, sound_config_lookup.c +0x8A), 0x1B..0x1D the three user
banks in Custom Data Flash (0x3D3010 / 0x3D3110 / 0x3D3210).  Two appliers (midi/midi_dispatch_handlers.s) walk a
bank, skipping address 0, and they treat its two halves differently:

  entries 0..22   SndParam_ApplyBaseBlock: addr[0] = (addr[0] & 0xF8) | b4;  addr[1] = b5
                  -- the 23 part records' payload bytes 12 (low 3 bits) and 13 (the part/routing byte)
  entries 23..38  SndParam_ApplyMaskBlock: *addr = (*addr & ~b4) | b5
                  -- tag 0x80's payload bytes 0..12, and (in 9 presets) tag 0x70's bytes 0..1

Both halves were opaque bytes in C: sound_config_lookup.c held each preset as `uint8_t data[234]`, and
naka_extension_device.c held the flash defaults (ROM 0xED933A..0xED9608: "HK " header + bank 0, bank 1, bank 2)
as field_XXXX words.  This script types them as snd_param_base_entry_t[23] + snd_param_mask_entry_t[16], each
entry annotated with the record byte it sets (decoded from the panel TLV layout tables, see
panel_tlv_schema_retype.py).  The bytes are read from each tree's compiled blob; `make all` must stay
byte-identical.

`--asm` relabels the matching .s slices (SndParamBank_DefaultHeader / _Default0..2, SndParam_PresetBanks);
scripts/renaming/rename_sndparam_banks.sed renames the routines first.

RUN (repository root, built tree)
    sed -i -f scripts/renaming/rename_sndparam_banks.sed <files>        # see the commit
    python3 scripts/converters/sndparam_bank_retype.py [--apply]       # the two C files, v10/v9/v7
    python3 scripts/converters/sndparam_bank_retype.py --asm [--apply]
C comment gate: --allow '/\* zero padding \*/' (generator notes on bytes of the banks).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M                 # noqa: E402
import panel_tlv_schema_retype as P          # noqa: E402

TREES = ("v10", "v9", "v7")
HDR, BANK0, BANK1, BANK2, END = 0x2B6E, 0x2B7E, 0x2C68, 0x2D52, 0x2E3C
N_BASE, N_MASK, BANK = 23, 16, 234
PRESETS, N_PRESETS = 138, 25
# member -> symbol: bank bytes the generic decoder read as NAKA_ADDR -- one entry's last byte and the next entry's
# address bytes, 04 53 FD 00 = 0x00FD5304 (DataBuf_Data_FormatDispatch is a real routine; this is not a use of it)
FALSE_POINTERS = {"DataBuf_Data_FormatDispatch_ptr": "DataBuf_Data_FormatDispatch"}

ENTRY_TYPEDEFS = r'''/* Sound-parameter bank entries (6 bytes; a bank is 23 base + 16 masked entries = 234 bytes, address 0 =
 * unused).  The same types are defined in sound_config_lookup.c (the 25 ROM presets) and
 * naka_extension_device.c (the three flash defaults); scripts/converters/sndparam_bank_retype.py. */
typedef struct __attribute__((packed)) {
    uint32_t address;    /* a part record's payload byte 12 in live-panel RAM */
    uint8_t  low_bits;   /* SndParam_ApplyBaseBlock: address[0] = (address[0] & 0xF8) | low_bits */
    uint8_t  next_byte;  /*                          address[1] = next_byte (payload byte 13) */
} snd_param_base_entry_t;

typedef struct __attribute__((packed)) {
    uint32_t address;    /* a live-panel RAM byte */
    uint8_t  mask;       /* SndParam_ApplyMaskBlock: *address = (*address & ~mask) | value */
    uint8_t  value;
} snd_param_mask_entry_t;
'''


def le(b, o, n=4):
    return int.from_bytes(b[o:o + n], "little")


def where(blocks, a):
    if a == 0:
        return "unused"
    w = P.where(blocks, a)                     # 'block B tag 0xTT payload byte N'
    return re.sub(r'^block \d ', '', w)


def entry_rows(bank, blocks, indent):
    base, mask = [], []
    for e in range(N_BASE + N_MASK):
        a, x, y = le(bank, 6 * e), bank[6 * e + 4], bank[6 * e + 5]
        if e < N_BASE:
            note = where(blocks, a) + ("" if a == 0 else " (low 3 bits) and the next byte")
            base.append("%s{ 0x%04X, %d, 0x%02X },  /* %s */" % (indent, a, x, y, note))
        else:
            mask.append("%s{ 0x%04X, 0x%02X, 0x%02X },  /* %s */" % (indent, a, x, y, where(blocks, a)))
    return base, mask


def check_base(bank):
    for e in range(N_BASE):
        assert bank[6 * e + 4] <= 7, (e, bank[6 * e + 4])      # only the low 3 bits are written


# ------------------------------------------------------------------------- naka_extension_device.c
def retype_naka(tree, apply, blocks):
    path = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_extension_device.c")
    blob = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_extension_device.bin"),
                "rb").read()
    if "SndParamBank_Default0_Base" in open(path, encoding="latin-1").read():
        return "already typed"
    M.TYPE_SIZES.update({"panel_tlv_layout_t": 10, "panel_reset_mask_t": 5,
                         "snd_param_base_entry_t": 6, "snd_param_mask_entry_t": 6})
    cb = M.CBlob(path)
    assert blob[HDR:HDR + 3] == b"HK "
    new = [M.string_member("SndParamBank_DefaultSignature", blob[HDR:HDR + 3], [
               "    /* SndParamBank_DefaultHeader: the 16-byte header of the Custom Data Flash banks (0x3D3000), whose"
               " first 3 bytes SndParamBank_CheckFlash compares; SndParamBank_WriteFlashDefaults writes it and bank 0"
               " (0xFA bytes) when they differ */"]),
           M.bytes_member("SndParamBank_DefaultHeaderTail", blob[HDR + 3:BANK0])]
    for k, off in enumerate((BANK0, BANK1, BANK2)):
        bank = blob[off:off + BANK]
        check_base(bank)
        base, mask = entry_rows(bank, blocks, "        ")
        pre = ["    /* SndParamBank_Default%d: the factory default of user bank %d (Custom Data Flash 0x3D3%d10,"
               " block 0x%X of SndParam_GetBlockPointer) */" % (k, k, k, 0x1B + k)]
        new.append(M.NewMember("snd_param_base_entry_t", "SndParamBank_Default%d_Base" % k, "[%d]" % N_BASE,
                               6 * N_BASE, "{\n" + "\n".join(base) + "\n    }", pre))
        new.append(M.NewMember("snd_param_mask_entry_t", "SndParamBank_Default%d_Masked" % k, "[%d]" % N_MASK,
                               6 * N_MASK, "{\n" + "\n".join(mask) + "\n    }"))
    sym = sorted(mb.name for mb in cb.members
                 if HDR <= mb.offset < END and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr))
    assert sym == sorted(FALSE_POINTERS), sym
    cb.retype(HDR, END, new, blob, false_pointers=sym)
    # the false pointer's symbol has no other use in the file: drop its extern and link-script line
    ld = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_extension_device_link.ld")
    ld_lines = open(ld, encoding="latin-1").read().split("\n")
    for sname in FALSE_POINTERS.values():
        assert cb.render().count(sname) == 1, sname
        k = cb.lines.index("extern const char %s;" % sname)
        assert k < cb.s0
        del cb.lines[k]
        for att in ("s0", "s1", "i0", "i1"):
            setattr(cb, att, getattr(cb, att) - 1)
        ld_lines = [l for l in ld_lines if not l.startswith("%s = " % sname)]
    k = next(i for i, l in enumerate(cb.lines) if l.startswith("/* -- Panel TLV schema"))
    lines = ENTRY_TYPEDEFS.rstrip("\n").split("\n") + [""]
    cb.lines[k:k] = lines
    for att in ("s0", "s1", "i0", "i1"):
        setattr(cb, att, getattr(cb, att) + len(lines))
    if apply:
        data = cb.render().encode("latin-1")
        open(path + ".tmp", "wb").write(data)
        os.replace(path + ".tmp", path)
        open(ld + ".tmp", "wb").write("\n".join(ld_lines).encode("latin-1"))
        os.replace(ld + ".tmp", ld)
    return "header + 3 default banks typed (+0x2B6E..+0x2E3C)"


# ------------------------------------------------------------------------- sound_config_lookup.c
OLD_TYPEDEF = '''/* 234-byte channel configuration record */
typedef struct __attribute__((packed)) {
    uint8_t data[SOUND_CONFIG_RECORD_SIZE];
} sound_config_record_t;
'''
OLD_MEMBER = "    sound_config_record_t records[SOUND_CONFIG_RECORD_COUNT];\n"
NEW_MEMBER = ("    snd_param_bank_t SndParam_PresetBanks[SOUND_CONFIG_RECORD_COUNT];"
              "  /* blocks 0..24 of SndParam_GetBlockPointer */\n")


def retype_soundcfg(tree, apply, blocks):
    path = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "sound_config_lookup.c")
    blob = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "sound_config_lookup.bin"), "rb").read()
    text = open(path, encoding="latin-1").read()
    if "SndParam_PresetBanks" in text:
        return "already typed"
    assert text.count(OLD_TYPEDEF) == 1 and text.count(OLD_MEMBER) == 1
    typedef = ("/* 234-byte channel configuration record */\n" + ENTRY_TYPEDEFS +
               "\n/* One bank: SndParam_ApplyBaseBlock walks .base, SndParam_ApplyMaskBlock .masked. */\n"
               "typedef struct __attribute__((packed)) {\n"
               "    snd_param_base_entry_t base[%d];\n"
               "    snd_param_mask_entry_t masked[%d];\n"
               "} snd_param_bank_t;\n" % (N_BASE, N_MASK))
    text = text.replace(OLD_TYPEDEF, typedef).replace(OLD_MEMBER, NEW_MEMBER)
    a = text.index("    .records = {\n")
    b = text.index("    /* Trailer", a)
    old = text[a:b]
    assert len(re.findall(r'/\* Record \d+ \*/', old)) == N_PRESETS
    out = ["    .SndParam_PresetBanks = {"]
    for i in range(N_PRESETS):
        bank = blob[PRESETS + BANK * i:PRESETS + BANK * (i + 1)]
        check_base(bank)
        base, mask = entry_rows(bank, blocks, "                ")
        out += ["        /* Record %d */" % i, "        {", "            .base = {"] + base + \
               ["            },", "            .masked = {"] + mask + ["            },", "        },"]
    out += ["    },", "", ""]
    text = text[:a] + "\n".join(out) + text[b:]
    if apply:
        data = text.encode("latin-1")
        open(path + ".tmp", "wb").write(data)
        os.replace(path + ".tmp", path)
    return "25 presets typed"


# ------------------------------------------------------------------------- .s
INC = '.incbin "includes/generated/naka_extension_device.bin", 0x%X, 0x%X'
S_HEADERS = {
    "SndParamBank_DefaultHeader": (HDR, 0x10, [
        "; SndParamBank_DefaultHeader..SndParamBank_Default2 -- the factory defaults of the sound-parameter user banks",
        "; in Custom Data Flash 0x3D3000 (header \"HK \" + 13 bytes, then three 234-byte banks of 23 base + 16 masked",
        "; entries {u32 RAM address, u8, u8}).  SndParamBank_CheckFlash compares the first 3 bytes with flash; when they",
        "; differ, SndParamBank_WriteFlashDefaults writes header + bank 0 (0xFA bytes) to 0x3D3000 and banks 1, 2 to",
        "; 0x3D3110, 0x3D3210.  Typed in ui_widgets/naka_extension_device.c (snd_param_base_entry_t /",
        "; snd_param_mask_entry_t); see technics-docs custom-data-flash.md."]),
    "SndParamBank_Default0": (BANK0, BANK, []),
    "SndParamBank_Default1": (BANK1, BANK, []),
    "SndParamBank_Default2": (BANK2, BANK, []),
}


def apply_asm(tree, apply):
    path = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "extension_device_screens.s")
    L = open(path, "rb").read().decode("latin-1").split("\n")
    if any(l.startswith("SndParamBank_Default0:") for l in L):
        return "already done"
    # the old slices: SndParamBank_DefaultHeader (4 B, after the sed) + 246 unlabelled B; Default1/2 label + incbin
    k0 = next(i for i, l in enumerate(L) if l.startswith("SndParamBank_DefaultHeader:\t" + INC % (HDR, 4)))
    assert L[k0 + 1].startswith("\t" + INC % (HDR + 4, 0xF6)), L[k0 + 1]
    j = k0
    while L[j - 1].startswith("; [nakarest]"):
        j -= 1
    k2 = next(i for i, l in enumerate(L) if l.startswith("SndParamBank_Default2:"))
    if L[k2] == "SndParamBank_Default2:":           # label and .incbin on two lines (v10, v9) ...
        assert L[k2 + 1] == "\t" + INC % (BANK2, BANK)
        k2 += 1
    else:                                           # ... or on one (v7)
        assert L[k2].endswith(INC % (BANK2, BANK)), L[k2]
    new = list(S_HEADERS["SndParamBank_DefaultHeader"][2])
    target = (max(len(n) + 1 for n in S_HEADERS) // 8 + 1) * 8      # the tab stop after the longest "Name:"
    for name, (off, size, _) in S_HEADERS.items():
        col, tabs = len(name) + 1, 0
        while col < target:
            col, tabs = (col // 8 + 1) * 8, tabs + 1
        new.append("%s:%s%s" % (name, "\t" * tabs, INC % (off, size)))
    L[j:k2 + 1] = new
    if apply:
        data = "\n".join(L).encode("latin-1")
        open(path + ".tmp", "wb").write(data)
        os.replace(path + ".tmp", path)
    return "slices relabelled"


OPTION_HEADER = [
    "; SndParamBank_OptionDefault_NN -- the defaults of the five fields of the 0x50-byte block at Custom Data Flash",
    "; 0x3D3400 (+0x00 2 B -- this slice is 4 B, of which the first 2 are copied --, +0x10 12 B, +0x20 4 B, +0x30 4 B,",
    "; +0x40 6 B).  SndParamBank_WriteFlashDefaults builds the block from them; SndParamBank_RestoreOptionBlock (factory",
    "; reset) rebuilds it keeping the flash's own +0x00; SndParamBank_LoadOptionBlock copies the five fields to RAM",
    "; 0x340E4, 0x340E6, 0x340F2, 0x340F6, 0x340FA, read by the ParaLoadOpt_* dialog (midi/param_load_routines.s)",
    "; and demo/file_demo_proc.s -- hence \"option\"."]
STALE_TG = ("; DSP config parameter handler A", "; DSP config parameter handler B")
ROUTINE_HEADERS = {
    "SndParamBank_CheckFlash": [
        "; Compare the first 3 bytes of Custom Data Flash 0x3D3000 with SndParamBank_DefaultHeader (\"HK \"); on any",
        "; difference fall into SndParamBank_WriteFlashDefaults."],
    "SndParamBank_WriteFlashDefaults": [
        "; FlashWrite the factory defaults of the sound-parameter banks: header + bank 0 (0xFA bytes) to 0x3D3000,",
        "; SndParamBank_Default1 / _Default2 (0xEA each) to 0x3D3110 / 0x3D3210, then the 0x50-byte option block,",
        "; assembled in a Malloc'd buffer from the five SndParamBank_OptionDefault_NN pieces, to 0x3D3400."],
    "SndParamBank_RestoreOptionBlock": [
        "; Factory reset (Boot_HandleFactoryReset): rebuild the 0x50-byte option block at 0x3D3400 from the",
        "; SndParamBank_OptionDefault_NN pieces, keeping the flash's own first 2 bytes, then Gfx_ClearFrameBuffers."],
    "SndParamBank_LoadOptionBlock": [
        "; Copy the five fields of the option block (0x3D3400 +0x00/+0x10/+0x20/+0x30/+0x40; 2, 12, 4, 4, 6 bytes)",
        "; to RAM 0x340E4 / 0x340E6 / 0x340F2 / 0x340F6 / 0x340FA."],
}


def apply_asm_headers(tree, apply):
    notes = []
    path = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "extension_device_screens.s")
    L = open(path, "rb").read().decode("latin-1").split("\n")
    k = next(i for i, l in enumerate(L) if l.startswith("SndParamBank_OptionDefault_00:"))
    if L[k - len(OPTION_HEADER):k] != OPTION_HEADER:
        L[k:k] = OPTION_HEADER
        notes.append("option-default header")
        if apply:
            data = "\n".join(L).encode("latin-1")
            open(path + ".tmp", "wb").write(data)
            os.replace(path + ".tmp", path)
    path = os.path.join(ROOT, tree, "maincpu", "audio", "tonegen_fileio_handlers.s")
    L = open(path, "rb").read().decode("latin-1").split("\n")
    n0 = len(L)
    L = [l for l in L if l not in STALE_TG]
    if len(L) != n0:
        notes.append("%d stale comments dropped" % (n0 - len(L)))
    for lab, hdr in ROUTINE_HEADERS.items():
        k = L.index(lab + ":")
        if L[k - len(hdr):k] != hdr:
            L[k:k] = hdr
            notes.append("header " + lab)
    if apply:
        data = "\n".join(L).encode("latin-1")
        open(path + ".tmp", "wb").write(data)
        os.replace(path + ".tmp", path)
    return ", ".join(notes) or "nothing to do"


def main():
    apply = "--apply" in sys.argv
    for tree in TREES:
        if "--asm" in sys.argv:
            print(tree, apply_asm(tree, apply), ";", apply_asm_headers(tree, apply))
            continue
        blocks, _ = P.decode(open(os.path.join(ROOT, tree, "maincpu", "includes", "generated",
                                                "naka_extension_device.bin"), "rb").read())
        print(tree, "naka_extension_device.c:", retype_naka(tree, apply, blocks))
        print(tree, "sound_config_lookup.c:", retype_soundcfg(tree, apply, blocks))


if __name__ == "__main__":
    main()
