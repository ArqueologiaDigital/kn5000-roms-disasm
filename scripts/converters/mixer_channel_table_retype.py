#!/usr/bin/env python3
r"""mixer_channel_table_retype.py -- the mixer-volume widget's 28-channel table, typed and named (v10/v9/v7).

QUESTION ANSWERED
-----------------
naka_disk_warning +0x1860..+0x1978 (280 B) was two asm slices, AcMixerVol_Confirm_Data (4 B) and
AcMixerVol_Confirm_Data_2 (276 B), with "[nakarest] purpose not established" notes, and 179 placeholder C members.
It is 28 records of 10 bytes, {u32 volume_key, u32 mute_key, u16 lsw_word}, one per mixer channel.  The widget's
+28 word is the channel index, and every reader computes 10 * index (sll 2 / add / add):
  - AcMixerVol_DrawChannel (the EVT_PARA_DRAW arm of AcMixerVolProc, formerly AcMixerVol_Confirm) reads
    SndParam_LookupReadOnly(volume_key) and prints it "%3d" with the fader bitmap at (0x80 - value) * 0x24 / 0x80.
    It reads SndParam_LookupReadOnly(mute_key) through the +4 column (`lda xwa, (<table>+4:24)`) and, when that
    value is 1, draws "MUTE" reversed.
  - The SW_IN / SW_IN_AIC / SW_BOTH arms pass (key, lsw_word) to MainLswPut / MainLswAdd.  lsw_word becomes the +6
    word of the 12-byte EVT_LSW_PUT packet MainLswPut posts to MainPmanControl; what that word selects is not
    established here.
Channels 0-22 have volume_key = 0x8000 + 0x400*T + 0x07 and mute_key = 0x8000 + 0x400*T + 0x08 for part tag
T = channel (asserted).  Those are the part parameter ids of README-lsw-param-namespace-map.md, so the field
constant k = 0x08 (part record byte +3, mask 0x80, left unnamed there) is the part's MUTE flag.  The channel names
come from the parallel pointer table at +0x175E (AcMixerVol_Paint reads it): RT1 RT2 LEFT PT4..PT16 ACP1..3 BASS
DRUM CHRD RTBS MSP MSP CTRL METR MIC.  So the part tags are 0 = RIGHT 1, 1 = RIGHT 2, 2 = LEFT, 3..15 = parts 4..16,
16..18 = ACCOMP 1..3, 19 = BASS, 20 = DRUM, 21 = CHORD, 22 = RTBS.
This script, per tree with that tree's bytes:
  - adds a typedef mixer_channel_t to naka_disk_warning.c and retypes the range as
    `mixer_channel_t AcMixerVol_Channels[28]`;
  - renames the 28-pointer member ptrs_15 to AcMixerVol_ChannelNamePtrs (code only, not comments);
  - in the asm, replaces the two slices with `AcMixerVol_Channels` (0x118 bytes) and
    `.set AcMixerVol_Channels_MuteKey, AcMixerVol_Channels + 4`, and heads the slice and the name table;
  - runs scripts/renaming/rename_mixer_channels_<tree>.sed (written here) over the tree:
    AcMixerVol_Confirm_Data -> AcMixerVol_Channels, AcMixerVol_Confirm_Data_2 -> AcMixerVol_Channels_MuteKey,
    AcMixerVol_Paint_PtrTable -> AcMixerVol_ChannelNamePtrs, and AcMixerVol_Confirm -> AcMixerVol_DrawChannel
    (with its _Str_Fmt3d / _Str_MUTE strings).

RUN (repository root, built tree)
    python3 scripts/converters/mixer_channel_table_retype.py [--apply]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all;
    assert_c_comments_preserved.py --base HEAD (the replaced [nakarest]-free C members carried no comments)
"""
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402
from name_resname_strings import segments   # noqa: E402

APPLY = "--apply" in sys.argv
BLOB = "naka_disk_warning"
START, N, REC = 0x1860, 28, 10
NAMES_AT = 0x175E
TYPEDEF = ("/* AcMixerVol_Channels' record: one mixer channel (scripts/converters/mixer_channel_table_retype.py). */\n"
           "typedef struct __attribute__((packed)) {\n"
           "    uint32_t volume_key;   /* +0 SndParam key of the channel volume (part k = 0x07) */\n"
           "    uint32_t mute_key;     /* +4 SndParam key of its mute flag (part k = 0x08); 1 = MUTE */\n"
           "    uint16_t lsw_word;     /* +8 passed as DE to MainLswPut / MainLswAdd (+6 of the LSW packet) */\n"
           "} mixer_channel_t;\n\n")
RULES = [("AcMixerVol_Confirm_Data_2", "AcMixerVol_Channels_MuteKey"),
         ("AcMixerVol_Confirm_Data", "AcMixerVol_Channels"),
         ("AcMixerVol_Paint_PtrTable", "AcMixerVol_ChannelNamePtrs"),
         ("AcMixerVol_Confirm_Str_Fmt3d", "AcMixerVol_DrawChannel_Str_Fmt3d"),
         ("AcMixerVol_Confirm_Str_MUTE", "AcMixerVol_DrawChannel_Str_MUTE"),
         ("AcMixerVol_Confirm", "AcMixerVol_DrawChannel")]
HEADER = [
    "; AcMixerVol_Channels -- 28 mixer channels x {u32 volume_key, u32 mute_key, u16 lsw_word}, indexed by the",
    "; AcMixerVol widget's +28 word (10 * index).  AcMixerVol_DrawChannel (EVT_PARA_DRAW) prints the volume and draws",
    "; \"MUTE\" when SndParam_LookupReadOnly(mute_key) is 1; the switch arms pass (key, lsw_word) to MainLswPut /",
    "; MainLswAdd.  Channels 0-22 are part tags 0-22 (keys 0x8000 + 0x400*T + 0x07 / + 0x08), so part field k = 0x08",
    "; is the MUTE flag.  Channel names: AcMixerVol_ChannelNamePtrs.  Typed in ui_widgets/naka_disk_warning.c",
    "; (scripts/converters/mixer_channel_table_retype.py).",
]
NAMES_HEADER = [
    "; AcMixerVol_ChannelNamePtrs -- 28 pointers to the mixer channel names (RT1 RT2 LEFT PT4..PT16 ACP1..3 BASS",
    "; DRUM CHRD RTBS MSP MSP CTRL METR MIC), parallel to AcMixerVol_Channels; read by AcMixerVol_Paint.  The",
    "; strings follow the table.",
]


def cstr(rom, a):
    o = a - 0xE00000
    return rom[o:o + 16].split(b"\0")[0].decode("latin-1")


def check(tree):
    b = open(os.path.join(ROOT, tree, "maincpu/includes/generated", BLOB + ".bin"), "rb").read()
    recs = [struct.unpack_from("<IIH", b, START + REC * i) for i in range(N)]
    for t in range(23):
        assert recs[t] == (0x8000 + 0x400 * t + 7, 0x8000 + 0x400 * t + 8, 4), (tree, t, recs[t])
    return b, recs


def edit_c(tree, b, recs, names):
    p = os.path.join(ROOT, tree, "maincpu/ui_widgets", BLOB + ".c")
    s = open(p, "rb").read().decode("latin-1")
    if "AcMixerVol_Channels" in s:
        return False
    k = s.index("typedef struct __attribute__((packed)) {\n    char txt_Etes_vous_su")
    s = s[:k] + TYPEDEF + s[k:]
    s = "".join(re.sub(r'\bptrs_15\b', "AcMixerVol_ChannelNamePtrs", seg) if kind == "code" else seg
                for kind, seg in segments(s))
    data = s.encode("latin-1")
    open(p + ".tmp", "wb").write(data)
    os.replace(p + ".tmp", p)
    cb = M.CBlob(p)
    nm = next(x for x in cb.members if x.name == "AcMixerVol_ChannelNamePtrs")
    assert (nm.offset, nm.size) == (NAMES_AT, 4 * N), (tree, hex(nm.offset), nm.size)
    rows = ["        { 0x%08X, 0x%08X, %d },  /* %2d %s */" % (r[0], r[1], r[2], i, names[i]) for i, r in enumerate(recs)]
    cb.retype(START, START + REC * N,
              [M.NewMember("mixer_channel_t", "AcMixerVol_Channels", "[%d]" % N, REC * N,
                           "{\n" + "\n".join(rows) + "\n    }",
                           ["    /* AcMixerVol_Channels: [mixer channel] = {volume_key, mute_key, lsw_word}; channel"
                            " names in AcMixerVol_ChannelNamePtrs.  Part tags 0-22 = channels 0-22. */"])], b)
    data = cb.render().encode("latin-1")
    if APPLY:
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
    return True


def edit_asm(tree):
    p = os.path.join(ROOT, tree, "maincpu/ui_widgets/disk_warning_strings.s")
    L = open(p, "rb").read().decode("latin-1").split("\n")
    changed = False
    i = next((k for k, x in enumerate(L) if x.startswith("AcMixerVol_Confirm_Data:")), None)
    if i is not None:
        assert '0x1860, 0x4' in L[i], (tree, L[i])
        j = next(k for k, x in enumerate(L) if x.startswith("AcMixerVol_Confirm_Data_2:"))
        assert '0x1864, 0x114' in L[j] and j > i, (tree, L[j])
        top = i
        while L[top - 1].startswith("; [nakarest]"):
            top -= 1
        L[top:j + 1] = HEADER + ['AcMixerVol_Confirm_Data:\t.incbin "includes/generated/naka_disk_warning.bin", 0x1860, 0x118',
                                 "\t.set AcMixerVol_Confirm_Data_2, AcMixerVol_Confirm_Data + 4\t; the mute_key column"]
        changed = True
    k = next((k for k, x in enumerate(L) if x.startswith("AcMixerVol_Paint_PtrTable:")), None)
    if k is not None and L[k - 1].startswith("; [nakarest]"):
        top = k
        while L[top - 1].startswith("; [nakarest]"):
            top -= 1
        L[top:k] = NAMES_HEADER
        changed = True
    if changed and APPLY:
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
    return changed


def main():
    rom = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    b10 = open(os.path.join(ROOT, "v10/maincpu/includes/generated", BLOB + ".bin"), "rb").read()
    names = [cstr(rom, struct.unpack_from("<I", b10, NAMES_AT + 4 * i)[0]) for i in range(N)]   # v10 addresses
    print("channels:", " ".join(names))
    for tree in ("v10", "v9", "v7"):
        b, recs = check(tree)
        print("%s: 28 channels, parts 0-22 asserted" % tree)
        if not APPLY:
            continue
        print("  C:", edit_c(tree, b, recs, names), " asm:", edit_asm(tree))
        sed = os.path.join(ROOT, "scripts/renaming/rename_mixer_channels_%s.sed" % tree)
        open(sed, "w").write("# rename_mixer_channels_%s.sed -- written by scripts/converters/mixer_channel_table_retype.py\n"
                             % tree + "".join("s/\\b%s\\b/%s/g\n" % r for r in RULES))
        hit = []
        for dp, _, fs in os.walk(os.path.join(ROOT, tree, "maincpu")):
            for f in fs:
                if f.endswith((".s", ".c", ".ld")):
                    q = os.path.join(dp, f)
                    t = open(q, "rb").read().decode("latin-1")
                    if any(re.search(r'\b%s\b' % a, t) for a, _ in RULES):
                        hit.append(q)
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  sed applied to %d files" % len(hit))


if __name__ == "__main__":
    main()
