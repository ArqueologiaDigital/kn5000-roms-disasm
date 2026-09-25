#!/usr/bin/env python3
r"""carve_v142_iram_block.py -- split the sub-CPU v1.42 block 0x00F002-0x00F41F (and the touch-curve
table after ToneGen_Voice_Bitmap_Ptr) into the objects its banner already measured.

QUESTION THIS ANSWERS
    subcpu_data_tables.s's banner for 0x00F000-0x00F41F ("IRAM_FirmwareConfig -- mixed config
    block, and it is WRITABLE") measures the objects inside: the voice bitmap, a DSP default
    effect-configuration image, a 128-entry mixer gain curve, a libm double pool... yet every
    byte from 0x00F002 on sat under ONE label, ToneGen_Voice_Active_Bitmap, so the code reached
    them as `(61458:16)`, `(61760:16)`, `(0x00f34e:24)`.  The same holds for the touch-curve
    table (0x01F420, 10 x 3 bytes) that sits unlabelled after the 4-byte ToneGen_Voice_Bitmap_Ptr.
    This script gives each object its label and a header naming its reader, so the operands
    can be symbolic.  It also finds that six of the "20 bytes, UNDESCRIBED ... no consumer
    identified" at 0x00F00A-0x00F01D ARE read: 0x00F012-0x00F01D hold six RAM variables of the
    audio main loop, the audio tick and the inter-CPU DMA watchdog (the reads and writes are
    listed in each header below).

HOW
    The replaced lines are located by a fresh address map (scripts/analysis/v142_line_map.py,
    byte-identity guarded) and must hold no comments; each object's bytes are re-read from the
    ROM, and each .double/.float is emitted with Python's round-trip repr and checked to pack
    back to the same bytes.  The byte gate then certifies the carve.  Afterwards the code's
    operands are made symbolic by scripts/converters/symbolize_v142_abs24_operands.py (exact
    mode) plus the handful of interior references this script rewrites itself.

RUN
    python3 scripts/converters/carve_v142_iram_block.py            # dry
    python3 scripts/converters/carve_v142_iram_block.py --apply    # then the symboliser, make gate
"""
import argparse
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import v142_line_map as lm  # noqa: E402

TREE = os.path.join(ROOT, "v142/subcpu")
DATA, CODE, FPM = "subcpu_data_tables.s", "kn5000_subprogram_v142.s", "subcpu_fp_math.s"
rom = open(os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom"), "rb").read()
STAR = "\u2605".encode("utf-8").decode("latin-1")


def R(a, n):
    return rom[a - 0xEF00:a - 0xEF00 + n]


def rows(a, n, per=8):
    b = R(a, n)
    return ["\t.byte " + ", ".join("0x%02x" % x for x in b[k:k + per]) for k in range(0, n, per)]


NO_READER = ("; No reader found: no absolute operand (hex or decimal, :16 or :24) and no 3-byte LE\n"
             "; value in the image names an address in this range.  Purpose not established.")

# FP pool: address, size, label, meaning, reader note
FP = [
    (0xF34E, 8, "FPConst_InvFact3", "1/3!", "FP_SinCos_Kernel_Phase4 (fp_math, twice)"),
    (0xF356, 8, "FPConst_InvFact5", "1/5! (minimax-trimmed in the last bits)", "FP_SinCos_Kernel_Phase4"),
    (0xF35E, 8, "FPConst_InvFact7", "1/7!", "FP_SinCos_Kernel_Phase4"),
    (0xF366, 8, "FPConst_InvFact9", "1/9!", "FP_SinCos_Kernel_Phase4"),
    (0xF36E, 8, "FPConst_InvFact11", "1/11!", "FP_SinCos_Kernel_Phase4"),
    (0xF376, 8, "FPConst_InvFact13", "1/13!", "FP_SinCos_Kernel_Phase4"),
    (0xF37E, 8, "FPConst_InvFact15", "1/15!", None),
    (0xF386, 8, "FPConst_InvFact17", "1/17!", None),
    (0xF38E, 8, "FPConst_PiLo_CodyWaite", "low part of a Cody-Waite pi (PiHi - this == pi)", "FP_SinCos_Kernel_Phase4"),
    (0xF396, 8, "FPConst_InvPi", "1/pi", "FP_SinCos_Kernel_InRange"),
    (0xF39E, 8, "FPConst_PiHi_CodyWaite", "high part of a Cody-Waite pi", "FP_SinCos_Kernel_Phase4"),
    (0xF3A6, 8, "FPConst_SinCos_Epsilon", "2.3283e-10, the small-argument cut-off", "FP_SinCos_Kernel_Phase4"),
    (0xF3AE, 4, "FPConst_FltEpsilon", "FLT_EPSILON", None),
    (0xF3B2, 4, "FPConst_FltMax", "FLT_MAX", None),
    (0xF3B6, 4, "FPConst_FltMin", "FLT_MIN", None),
    (0xF3BA, 8, "FPConst_Pi", "pi", None),
    (0xF3C2, 8, "FPConst_TwoPi", "2*pi", None),
    (0xF3CA, 8, "FPConst_HalfPi", "pi/2", "FP_cos (kn5000_subprogram_v142.s)"),
    (0xF3D2, 8, "FPConst_Ln2", "ln 2", "FP_log_IterLoop"),
    (0xF3DA, 8, "FPConst_Log10_2", "log10 2", None),
    (0xF3E2, 8, "FPConst_Ln10", "ln 10", None),
    (0xF3EA, 8, "FPConst_DblEpsilon", "DBL_EPSILON", None),
    (0xF3F2, 8, "FPConst_DblMax", "DBL_MAX (the same value as FPConst_MaxNorm below)", None),
    (0xF3FA, 8, "FPConst_DblMin", "DBL_MIN", None),
    (0xF402, 8, "FPConst_NegZero", "-0.0", None),
]


def fp_line(a, n, lab, meaning, reader):
    b = R(a, n)
    v = struct.unpack("<d" if n == 8 else "<f", b)[0]
    txt = repr(v)
    assert struct.pack("<d" if n == 8 else "<f", float(txt)) == b, (hex(a), txt)
    who = ("read by %s" % reader) if reader else "no reader found in the payload (library constant)"
    return "%s:\t.%s %s\t; %s, %s" % (lab, "double" if n == 8 else "float", txt, meaning, who)


def iram_block():
    out = []
    out += rows(0xF002, 8)
    out += [
        "; --- 0x00F00A-0x00F011  8 bytes 0xFF after the voice bitmap.",
        NO_READER,
        "IRAM_Unreferenced_F00A:",
    ] + rows(0xF00A, 8)
    b = R(0xF012, 12)
    assert b == bytes([0, 0, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0, 0, 0]), b.hex()
    out += [
        "; --- 0x00F012-0x00F01D  six RAM variables (initial values as shipped).  The banner above",
        "; lists 0x00F00A-0x00F01D as \"UNDESCRIBED ... no consumer identified\"; these twelve bytes",
        "; do have consumers, all through the 16-bit absolute form `(addr:16)`:",
        "; u16, read and written by AudioLoop_CheckPeriodicReinit (0x01FAFF): incremented on every",
        "; periodic re-init, reset to 0 once it passes 0x0A.",
        "AudioLoop_ReinitCounter:\t.short 0",
        "; u8, Timer_AudioTick_Handler (0x01FB41) reads it, increments it and dispatches on the old",
        "; value 0..5 through OFFSETS_F460; AudioTick_Variant_6 (0x01FB97) resets it to 0.",
        "AudioTick_Phase:\t.byte 0",
        "\t.byte 0xff\t\t; not referenced (high byte of a word slot)",
        "; u8, counted 0..7 by AudioTick_Variant_6 (0x01FB97); at 8 it sets bit 5 of (0x103E) and",
        "; restarts from 0.",
        "AudioTick_Phase6Count:\t.byte 0",
        "\t.byte 0xff\t\t; not referenced",
        "; u8, `inc 1,(this)` by the DMA-stuck recovery in Cmd_Check_DMA_Timeout (0x020FD9): the",
        "; number of inter-CPU DMA transfers it has aborted.",
        "InterCPU_DmaAbort_Count:\t.byte 0",
        "\t.byte 0xff\t\t; not referenced",
        "; u16, Cmd_Check_DMA_Timeout (0x020FD9): incremented while the DMA byte count (control",
        "; register 0x40) has not moved since the last check, reset when it moves or DMA is idle;",
        "; above 0x0A the transfer is aborted.",
        "InterCPU_DmaStuck_Count:\t.short 0",
        "; u16, Cmd_Check_DMA_Timeout: the DMA byte count seen at the previous check.",
        "InterCPU_DmaLast_Count:\t.short 0",
    ]
    out += [
        "; --- 0x00F01E-0x00F13F  DEFAULT DSP EFFECT-CONFIGURATION IMAGE, 290 bytes (see the banner).",
        "; DSP_Reset (0x0360A7) copies it `ld xiy,this / ld xix,0x448E / ldw bc,0x91 / ldirw` (0x91",
        "; words) into the live effect-config buffer at DRAM 0x448E, then reads the word at +8 of",
        "; THIS image `ld iz,(this+8:16)` and passes it to DSP_WriteAlgoInitPreset and",
        "; DSP_ApplyAlgoForVoiceType.",
        "DSP_DefaultEffectConfig_Image:",
    ] + rows(0xF01E, 290)
    curve = struct.unpack("<128I", R(0xF140, 512))
    assert all(curve[k] < curve[k + 1] for k in range(127)) and curve[-1] == 0x7FFFFF00
    out += [
        "; --- 0x00F140-0x00F33F  128 x u32 increasing gain curve ending at 0x7FFFFF00 (see the banner):",
        "; read by DSP_MixerCoeff_Compute (0x03C067) at three sites, `lda_d16 xbc,(this:16)`,",
        "; indexed 4*WA and 4*DE, the lookups multiplied against DSP_MixerGain_Curve[4*BC] and",
        "; written to DSP2 (MN19413) registers 0xD0 / 0xD3.",
        "DSP2_MixerGain_Curve:",
    ] + ["\t.long " + ", ".join("0x%08x" % x for x in curve[k:k + 4]) for k in range(0, 128, 4)]
    out += [
        "; --- 0x00F340-0x00F34D  14 bytes between the curve and the pool (0xEE9AFF00, 0x10000003, zeros).",
        NO_READER,
        "IRAM_Unreferenced_F340:",
    ] + rows(0xF340, 14)
    out += [
        "; --- 0x00F34E-0x00F409  the head of the libm double pool (the banner above decodes it; the",
        "; tail is FPConst_MaxNorm / FPConst_Zero / FPConst_Sqrt2 at 0x00F420+).  One label per",
        "; constant; \"read by\" names the routine whose `lda (label:24)` loads it.",
    ]
    out += [fp_line(*f) for f in FP]
    out += [
        "; --- 0x00F40A-0x00F41F  22 bytes that do not decode as clean doubles at this alignment.",
        NO_READER,
        "IRAM_Unreferenced_F40A:",
    ] + rows(0xF40A, 22)
    return out


def touch_table():
    b = R(0x01F41C, 4)
    assert b == bytes([0x02, 0xF0, 0, 0])
    t = R(0x01F420, 30)
    assert [t[3 * k] for k in range(10)] == [0x10 * k for k in range(10)]
    out = ["\t.long ToneGen_Voice_Active_Bitmap\t; = 0x0000F002",
           "; --- 0x01F420-0x01F43D  touch-curve parameters, 10 records x 3 bytes {gain (Q7), output",
           "; level at the pivot, black-key trim}, read by Keybed_Decode_Event (0x03D11F) at",
           "; [this + 3*curve], +1 and +2, curve = Keybed_Touch_Mode (0x004A48); 10 rows by",
           "; Audio_CmdHandler_A0_BF's `cp (xbc+1),0x9` check (see the note above).  Same name as the",
           "; byte-identical table in the boot ROM (kn5000_subcpu_boot.s, 0xFF802E).",
           "ToneGen_VelCurve_ModeParams:"]
    for k in range(10):
        out.append("\t.byte %d, %d, %d\t\t; curve %d" % (t[3 * k], t[3 * k + 1], t[3 * k + 2], k))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    amap = lm.line_map()
    D = open(os.path.join(TREE, DATA), "rb").read().decode("latin-1").split("\n")
    at = {}
    for (f, i), ad in amap.items():
        if f == DATA:
            at.setdefault(ad, i)
    # IRAM block: the version word, then ToneGen_Voice_Active_Bitmap's rows up to 0x00F41F
    vi = at[0xF000]
    assert D[vi].strip() == ".byte 0x8e, 0x00" and D[vi - 1] == "IRAM_FirmwareConfig:"
    bi = at[0xF002]
    assert D[bi - 1] == "ToneGen_Voice_Active_Bitmap:"
    ei = at[0xF420]
    while not D[ei - 1].strip().startswith("."):
        ei -= 1
    span = D[bi:ei]
    assert not any(";" in x for x in span), "comment inside the carved span"
    # touch table: the 5 rows under ToneGen_Voice_Bitmap_Ptr
    ti = at[0x01F41C]
    assert D[ti - 1] == "ToneGen_Voice_Bitmap_Ptr:"
    te = at[0x01F43E]
    while not D[te - 1].strip().startswith("."):
        te -= 1
    assert not any(";" in x for x in D[ti:te])
    new_iram, new_touch = iram_block(), touch_table()
    print("IRAM block: %d lines -> %d; touch table: %d lines -> %d" % (ei - bi, len(new_iram), te - ti, len(new_touch)))
    if not a.apply:
        return
    D2 = D[:vi] + ["\t.short 142\t\t; payload version 1.42 (0x008E); see the banner"] + D[vi + 1:bi] + new_iram \
        + D[ei:ti] + new_touch + D[te:]
    txt = "\n".join(D2)
    # FPConst_Ln2 at 0x00F42C holds sqrt(2): rename it (label + the one reader) and say so
    old = "FPConst_Ln2:\n"
    assert txt.count(old) == 1
    txt = txt.replace(old, "; %s Renamed 2026-09-25 from FPConst_Ln2 (the note above proves the value is sqrt(2)); the\n"
                           "; name FPConst_Ln2 now labels the real ln 2 at 0x00F3D2.\nFPConst_Sqrt2:\n" % STAR)
    o2 = ";             00 00 00 00. Listed only so the range tiles; no consumer identified.\n"
    assert txt.count(o2) == 1
    txt = txt.replace(o2, o2 + ";             %s CORRECTED 2026-09-25: 0x00F012-0x00F01D are six RAM variables that DO have\n"
                                ";             readers (AudioLoop_ReinitCounter .. InterCPU_DmaLast_Count, carved below);\n"
                                ";             only 0x00F00A-0x00F011 and three 0xFF high bytes are unreferenced.\n" % STAR)
    open(os.path.join(TREE, DATA), "wb").write(txt.encode("latin-1"))
    F = open(os.path.join(TREE, FPM), "rb").read().decode("latin-1")
    assert F.count("(FPConst_Ln2:24)") == 1
    F = F.replace("(FPConst_Ln2:24)", "(FPConst_Sqrt2:24)")
    open(os.path.join(TREE, FPM), "wb").write(F.encode("latin-1"))
    C = open(os.path.join(TREE, CODE), "rb").read().decode("latin-1")
    for o, n, cnt in [("(61478:16)", "(DSP_DefaultEffectConfig_Image+8:16)", 1),
                      ("(0x01f421:24)", "(ToneGen_VelCurve_ModeParams+1:24)", 1),
                      ("(0x01f422:24)", "(ToneGen_VelCurve_ModeParams+2:24)", 1)]:
        assert C.count(o) == cnt, (o, C.count(o))
        C = C.replace(o, n)
    open(os.path.join(TREE, CODE), "wb").write(C.encode("latin-1"))
    print("written; now: symbolize_v142_abs24_operands.py --apply ; make gate")


if __name__ == "__main__":
    main()
