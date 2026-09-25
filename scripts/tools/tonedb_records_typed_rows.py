#!/usr/bin/env python3
"""Re-emit the 579 tone records' head and partial blocks as reader-annotated rows.

QUESTION THIS ANSWERS
    table_data/tone_database_records.s spelled each tone record as a 5-byte
    "layer configuration" line, an 81-byte "common block" and N-1 81-byte
    "layer blocks", each block as anonymous 16-byte rows.  The subcpu readers
    are now traced (see the file header and
    notes/tonedb-2026-09-25/partial_block_reads.py):
      * +0x10 is the PART-MODE byte (Voice_SetVelocity: +0x10 & 0xC0),
      * +0x11 is the PARTIAL MASK (VoiceBuf_TypeSelector_MatchEpilogue, masks
        01/04/10/40 from subcpu table 0x00FB4E),
      * a present partial p is bound to the block at rec + 0x66 + 0x51*rank
        (WaveSel_Bind_PartRecords), which becomes the voice's paramA,
    and the voice code reads the 81-byte block in field groups (two
    envelopes, pitch, amplitude envelope, filter control, third envelope,
    filter registers).  This script splits the head into its three fields,
    says which partial each block serves, re-spells each block as one row per
    field group, and gives every record a two-line header with its decoded
    facts (which bank/program selects it, mode, partials, size).

    Old rows are parsed and checked against the ROM at the label's address
    (table-data ELF) before replacement; new rows are re-parsed and checked.
    Idempotent.  The byte gate is the certificate.

RUN
    make rebuilt_ROMs/kn5000_table_data.llvm.elf
    python3 scripts/tools/tonedb_records_typed_rows.py            # dry run
    python3 scripts/tools/tonedb_records_typed_rows.py --write
"""
import collections
import pathlib
import re
import struct
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "table_data" / "tone_database_records.s"
ROM = (ROOT / "original_ROMs" / "kn5000_table_data.rom").read_bytes()
ELF = ROOT / "rebuilt_ROMs" / "kn5000_table_data.llvm.elf"
NM = pathlib.Path.home() / "compartilhado/llvm-project/build/bin/llvm-nm"
B, DB = 0x800000, 0x830000
MODULE_END = 0x855A48
COL = 112

u8 = lambda a: ROM[a - B]
u16 = lambda a: struct.unpack_from("<H", ROM, a - B)[0]
u32 = lambda a: struct.unpack_from("<I", ROM, a - B)[0]
blob = lambda a, n: ROM[a - B:a - B + n]

MASKS = [0x01, 0x04, 0x10, 0x40]        # subcpu 0x00FB4E, partial p -> bit in +0x11
GROUPS = [  # (first, last, text) -- partial-block field groups, see the file header
    (0x00, 0x06, "head: +0x02/+0x03 wave-select pair"),
    (0x07, 0x16, "envelope 2 (Voice_Level_ComputeTriplet)"),
    (0x17, 0x26, "pitch +0x17..+0x1C (Voice_ApplyPortamento, Voice_ComputePitch)"),
    (0x27, 0x35, "envelope 1, amplitude (Voice_Calc_LevelPair_PatchAtk)"),
    (0x36, 0x3C, "filter control (TVF_Build_Dispatch, TVF_Calc_Cutoff)"),
    (0x3D, 0x4C, "envelope 3 (Voice_StereoLevel_Compute)"),
    (0x4D, 0x50, "filter registers: cutoff, slope, pair (TVF_Build_Full)"),
]


COMMON_GROUPS = [  # tone-record offsets of the common block's reader-defined groups
    (0x15, 0x28, "common: no reader found (a kit's {wave, slot} note pairs start at +0x27)"),
    (0x29, 0x29, "octave-shift index, low nibble (Pitch_Get_Patch_Octave_Shift)"),
    (0x2A, 0x2A, "two nibble indexes (Instrument_LookupProgram_Hi/LoNibble)"),
    (0x2B, 0x3A, "4-byte entries 0-3; entry (voice +0x1A & 3) byte +2 bit 7 (ExtVoice_Build_SlotRegisters)"),
    (0x3B, 0x4A, "4-byte entries 4-7, same shape; no reader found"),
    (0x4B, 0x5A, "4-byte entries 8-11, same shape; no reader found"),
    (0x5B, 0x5B, "no reader found"),
    (0x5C, 0x5C, "level offset, 0x40 = none (Level_Build_Reg0C0)"),
    (0x5D, 0x5D, "algorithm type, low nibble (AlgoType_StateWrite)"),
    (0x5E, 0x61, "algorithm parameters (Voice_Build_Partial_Descriptor, AlgoType_*)"),
    (0x62, 0x63, "no reader found"),
    (0x64, 0x65, "secondary parameters (Voice_SecondaryParam_Path2/_Epilogue)"),
]


def pad(code, comment, col=COL):
    w = len(code.expandtabs(8))
    return code + "\t" * max(1, (col - w + 7) // 8) + "; " + comment


def syms():
    out = subprocess.run([str(NM), "--defined-only", str(ELF)], capture_output=True,
                         text=True, check=True).stdout
    return {n: int(a, 16) for a, t, n in (ln.split(None, 2) for ln in out.splitlines())}


def spell(lines):
    out = bytearray()
    for ln in lines:
        code, q = ln, False
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
        if op == ".ascii":
            out += args.strip().strip('"').encode("latin-1")
        elif op == ".byte":
            out += bytes(int(v, 0) for v in re.findall(r'0x[0-9a-fA-F]+|\d+', args))
        else:
            raise SystemExit("cannot spell %r" % ln)
    return bytes(out)


def selection():
    """tone number -> [(path, selector, program)]"""
    sel = collections.defaultdict(list)
    main_sel = [0, 1, 2, 3, 4, 5, 6, 7, 0x40, 0x41, 0x70]
    for bk, s in enumerate(main_sel):
        for p in range(128):
            sel[u16(0x830180 + 2 * (bk * 128 + p))].append(("Main", s, p))
    cmap = {}
    for s in range(128):
        b = u8(0x830C80 + s)
        if b or s == 0:
            cmap.setdefault(b, s)
    for bk, s in sorted(cmap.items()):
        for p in range(128):
            sel[u16(0x830D00 + 2 * (bk * 128 + p))].append(("Coeff", s, p))
    return sel


def partial_blocks(mask, nblocks):
    """partial p -> block rank, as VoiceBuf_TypeSelector_MatchEpilogue computes
    it for a ROM bank selector < 0x10 (packed)."""
    out = {}
    for p in range(4):
        if not mask & MASKS[p]:
            continue
        out[p] = sum(1 for b in range(1, p + 1) if mask & MASKS[b])
    return out


def main():
    write = "--write" in sys.argv
    sym = syms()
    offt = [u32(0x831B00 + 4 * i) for i in range(629)]
    idx_of = collections.defaultdict(list)
    for i, o in enumerate(offt):
        idx_of[DB + o].append(i)
    starts = sorted({DB + o for o in offt if DB + o < MODULE_END and DB + o >= 0x8324D4})
    end = {a: (starts[k + 1] if k + 1 < len(starts) else MODULE_END) for k, a in enumerate(starts)}
    sel = selection()
    lines = SRC.read_bytes().decode("latin-1").split("\n")
    out, i, changed, nrec = [], 0, 0, 0
    census = collections.Counter()
    while i < len(lines):
        ln = lines[i]
        m = re.match(r'^(ToneRec_(\d{3})):', ln)
        if not m:
            out.append(ln)
            i += 1
            continue
        label = m.group(1)
        a = sym[label]
        size = end[a] - a
        nb = (size - 21) // 81
        assert 21 + 81 * nb == size, label
        j = i + 1
        while j < len(lines) and lines[j].strip() and not re.match(r'^[A-Za-z_.]', lines[j]) \
                and not lines[j].startswith("; ---"):
            j += 1
        old = lines[i + 1:j]
        if spell(old) != blob(a, size):
            raise SystemExit("%s: old rows do not spell the ROM bytes" % label)
        mode, mask = u8(a + 0x10), u8(a + 0x11)
        idx = sorted(idx_of[a])
        streams = [k - 338 for k in idx if 338 <= k <= 377]
        pb = partial_blocks(mask, nb - 1)
        # ---- header
        picks = []
        for k in idx:
            picks += sel.get(k, [])
        pick_txt = ", ".join("%s sel 0x%02x prog %d" % s for s in picks[:2])
        if len(picks) > 2:
            pick_txt += " +%d more" % (len(picks) - 2)
        if not picks:
            pick_txt = "no bank program"
        if streams:
            pick_txt += "; staging stream %d" % streams[0]
        ptxt = ", ".join("%d" % p for p in sorted(pb)) or "none"
        name = blob(a, 16).decode("latin-1").strip()
        hdr = ["; Tone record %s \"%s\" (table index %s; %s):" % (
                   label[8:], name, "/".join(map(str, idx[:3])) + ("..." if len(idx) > 3 else ""), pick_txt),
               "; part mode 0x%02x, partial mask 0x%02x = partials %s; %d bytes = 21 + %d*81.  Layout: file header."
               % (mode & 0xC0, mask, ptxt, size, nb)]
        while out and (out[-1].startswith("; Tone record ToneRec_") or
                       re.match(r'^; Tone record \d{3} "', out[-1]) or
                       re.match(r'^; part mode 0x[0-9a-f]{2}, partial mask', out[-1])):
            out.pop()
        out += hdr
        out.append(ln)
        # ---- body
        new = []
        k = 0
        body = old
        # name line
        assert body[0].lstrip().startswith(".ascii"), label
        new.append(body[0])
        k = 1
        # head: either the old 5-byte line or our three split lines
        if "; +0x10 layer configuration" in body[k]:
            k += 1
        else:
            while not body[k].strip().startswith("; common block"):
                k += 1
        bits = "bit 4 set" if mode & 0x10 else "bit 4 clear"
        new.append(pad("\t.byte\t0x%02x" % mode, "+0x10 part-mode byte: mode 0x%02x (bits 7:6), %s, bits 5:4 = %d"
                       % (mode & 0xC0, bits, mode >> 4 & 3)))
        new.append(pad("\t.byte\t0x%02x" % mask, "+0x11 partial mask: partials %s" % ptxt))
        new.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(a + 0x12, 3)), "+0x12..+0x14"))
        # common block: keep its "; common block" line, re-cut the rows into
        # the groups the readers define (see the file header)
        while k < len(body) and not re.match(r'^\s*; layer block \d', body[k]):
            if body[k].strip().startswith(";"):
                new.append(body[k])
            k += 1
        for lo, hi, txt in COMMON_GROUPS:
            new.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(a + lo, hi - lo + 1)),
                           "+0x%02x %s" % (lo, txt)))
        # partial blocks
        rank_to_p = {r: p for p, r in pb.items()}
        blk = 0
        while k < len(body):
            mb = re.match(r'^\s*; layer block (\d+)', body[k])
            assert mb, (label, body[k])
            new.append(body[k])
            k += 1
            if k < len(body) and re.match(r'^\s*; (= partial|bound to no partial)', body[k]):
                k += 1
            r = blk
            if r in rank_to_p:
                new.append("\t; = partial %d (rank %d): bound by WaveSel_Bind_PartRecords to part +0x%02x, the voice's paramA"
                           % (rank_to_p[r], r, 0x6E + 0x25 * rank_to_p[r]))
            else:
                new.append("\t; bound to no partial by this record's mask (a 426-byte staging-stream record keeps all 4 blocks)")
            # skip the old rows of this block
            while k < len(body) and not re.match(r'^\s*; layer block \d', body[k]):
                k += 1
            base = a + 0x66 + 0x51 * blk
            for lo, hi, txt in GROUPS:
                new.append(pad("\t.byte\t" + ", ".join("0x%02x" % b for b in blob(base + lo, hi - lo + 1)),
                               "+0x%02x blk+0x%02x %s" % (base - a + lo, lo, txt)))
            blk += 1
        assert blk == nb - 1, label
        if spell(new) != blob(a, size):
            raise SystemExit("%s: new rows spell different bytes" % label)
        if new != old:
            changed += 1
        census[(size, len(pb) == nb - 1)] += 1
        out += new
        i = j
        nrec += 1
    assert nrec == 579, nrec
    print("%d records, %d changed; (size, partials == blocks) census: %s" % (nrec, changed, dict(census)))
    if write:
        SRC.write_bytes("\n".join(out).encode("latin-1"))
        print("wrote", SRC.relative_to(ROOT))
    else:
        print("dry run; pass --write")


if __name__ == "__main__":
    main()
