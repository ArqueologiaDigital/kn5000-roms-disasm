#!/usr/bin/env python3
r"""WHAT ARE THE BYTES OF ui/char_encoding_naka_state.s?  (maincpu v10/v9/v7)

QUESTION ANSWERED
    The file (v10/v9 ROM 0xEEFF78-0xEF0318, v7 0xEEFF4E-0xEF02EE, 929 bytes,
    identical in all three) was titled "Character Encoding Tables & NAKA State
    Blocks" and held an `.ascii` run, misdecoded instructions and `.zero` blocks.
    It is the tail of the SECOND work-RAM initialisation image:
    Boot_InitWorkRAM_ROMCopy2_Start copies ROM 0xEEFA66.. to RAM at boot
    (v10/v9: 0x95B bytes -> RAM 0xE35E; v7: 0x931 bytes -> RAM 0xE2C2), so this
    file is the power-on value of RAM 0xE870-0xEC10 (v7: 0xE7AA-0xEB4A), and the
    code uses those RAM addresses.  Contents, v10 RAM addresses:

      0xE870  nodes 0x21-0x7F of link array A {u8 prev, u8 next}, base RAM 0xE82E
              (node k at 0xE82E + 2k; nodes 0-0x20 are in the previous file)
      0xE92E  node 0x80 = array A's free-list sentinel {0x7F, 0x00}
      0xE930  nodes 0x81-0xA0 = 32 empty list sentinels {self, self}
      0xE970  link array B, nodes 0-0x1F, base RAM 0xE970
      0xE9B0  node 0x20 = array B's free-list sentinel {0x1F, 0x00}
      0xE9B2  nodes 0x21-0x24 = 4 empty list sentinels
      0xE9BA  five small variables (u16, then four {u8 value, 0xFF} pairs)
      0xE9C4  the song-file player's variables up to 0xEC10 (zero at power-on
              except 0xEC0D = 0xFF)

    The readers are in the v10 sources (audio/note_voice_mapping.s,
    boot/system_handlers.s, audio/dsp_config_sysex.s, audio/audioinit_routines.s);
    --probe re-finds each cited reference there, checks the node-link patterns
    byte by byte, and counts instruction-shaped references (a 0xC1/0xD1/0xE1/
    0xF1 16-bit-address prefix followed by the RAM address) in the v10, v9 and
    v7 ROMs -- v7 with its own RAM addresses (v10 - 0xC6) -- so the v7 layout is
    tested, not assumed.

    --apply rewrites <v>/maincpu/ui/char_encoding_naka_state.s as typed objects.
    The old labels are kept as `.set` aliases at their old addresses because
    other files name them (NAKA C records, fd_test_data.s, sound_editor_ui.s,
    presentation_sound_nav.s, extension_data.s, shared/positional_labels.s).

RUN
    python3 scripts/generators/gen_workram2_tail.py --probe
    python3 scripts/generators/gen_workram2_tail.py --apply v10 v9 v7
    make gate
"""
import argparse
import collections
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "generators"))
import gen_sndparam_valuemap_headers as vm  # noqa: E402  (RAM-copy locator)

B = 0xE00000
LEN = 929
V10_RAM0 = 0xE870          # RAM address of the file's first byte in v10/v9
BASE_A, BASE_B = 0xE82E, 0xE970

# legacy label -> v10 RAM address it sat at
LEGACY = {
    "CharEncoding_PrintableHi": 0xE8F8, "CharEncoding_ExtendedLo": 0xE93E,
    "CharEncoding_ExtendedHi": 0xE961, "NakaState_ZeroBlock_0": 0xE9D4,
    "NakaState_ZeroBlock_1": 0xE9EB, "NakaState_ZeroBlock_2": 0xE9ED,
    "NakaState_ZeroBlock_3": 0xEA0F, "NakaInst_BASS_ACCOMP1_ACCOMP2_ACCOMP3": 0xEA23,
    "NakaInst_RHYTHM_SELECT_TEMPO_APC_MEMORY_SPLIT_POINT": 0xEA28,
    "NakaState_ZeroBlock_4": 0xEA33, "NakaState_ZeroBlock_5": 0xEA35,
    "Naka_PresentationRootState": 0xEA37, "NakaState_PresentationTail": 0xEBAA,
}

# (v10 RAM, size, label, header lines, [(v10 RAM referenced, routine label), ...])
# {R} in a header line is replaced by the version's RAM address of the object,
# {A:0x....} by the version's RAM address of that v10 RAM address.
OBJS = [
    (0xE870, 190, "WorkRam2_VoiceLinkA_Nodes21", [
        "; Nodes 0x21-0x7F of link array A: {u8 prev, u8 next} per node, node k at",
        "; RAM {A:0xE82E} + 2k (nodes 0-0x20 are the last bytes of the previous file).",
        "; Power-on state: nodes 0-0x7F chained on the free list, prev = k-1, next = k+1.",
        "; NoteMap_AllocNewVoiceEntry and others take the base (`lda xwa,({A:0xE82E})`,",
        "; `lda xde,({A:0xE82E})`) and pass it with a node index to NoteMap_SwapVoiceLinks",
        "; and NoteMap_LinkVoiceSlots."],
     [(0xE82E, "NoteMap_AllocNewVoiceEntry")]),
    (0xE92E, 2, "WorkRam2_VoiceLinkA_FreeList", [
        "; Node 0x80 of array A: free-list sentinel {prev = tail 0x7F, next = head 0}.",
        "; AllocNewVoiceEntry_LoadParam: `ld a,({A:0xE92F}); ... cp a,0x80` -- the",
        "; list is empty when the head is the sentinel itself."],
     [(0xE92F, "AllocNewVoiceEntry_LoadParam")]),
    (0xE930, 64, "WorkRam2_VoiceLinkA_ListHeads", [
        "; Nodes 0x81-0xA0 of array A: 32 list sentinels, each {self, self} = an empty",
        "; circular list at power-on (node 0x81 = bytes 0x81,0x81 ... 0xA0 = 0xA0,0xA0)."],
     []),
    (0xE970, 64, "WorkRam2_VoiceLinkB_Nodes", [
        "; Link array B {u8 prev, u8 next}, node k at RAM {A:0xE970} + 2k; nodes 0-0x1F",
        "; chained on the free list at power-on.  NoteMap_FindEntry takes the base",
        "; (`lda xwa,({A:0xE970})`); NoteMap_FindEntry_AdvanceSlotD follows next links",
        "; (`lda xix,({A:0xE971}); ld d,(xix+bc)` with bc = 2 * node)."],
     [(0xE970, "NoteMap_FindEntry"), (0xE971, "NoteMap_FindEntry_AdvanceSlotD")]),
    (0xE9B0, 2, "WorkRam2_VoiceLinkB_FreeList", [
        "; Node 0x20 of array B: free-list sentinel {tail 0x1F, head 0}.",
        "; FindEntry_LoadParam: `ld a,({A:0xE9B1}); ... cp a,0x20` (empty = sentinel)."],
     [(0xE9B1, "FindEntry_LoadParam")]),
    (0xE9B2, 8, "WorkRam2_VoiceLinkB_ListHeads", [
        "; Nodes 0x21-0x24 of array B: 4 list sentinels {self, self}, empty at power-on;",
        "; NoteMap_FindEntry_AdvanceSlotD stops a walk at `cp c,0x21`."],
     []),
    (0xE9BA, 2, "WorkRam2_VoiceLinks_Count", [
        "; u16, 0 at power-on: VoiceLinks_SlotLoop `incw 1,({A:0xE9BA})`,",
        "; VoiceLinks_SkipEmpty `decw 1,({A:0xE9BA})`."],
     [(0xE9BA, "VoiceLinks_SlotLoop"), (0xE9BA, "VoiceLinks_SkipEmpty")]),
    (0xE9BC, 2, "WorkRam2_VoiceMatchCountdown", [
        "; {u8 count, 0xFF}; count 10 at power-on.  VoiceMap_AllocateSlo_Block2 sets it",
        "; to 10, NoteMap_FindBestMatch to 0; SeqEvt_CheckExpiry decrements it and calls",
        "; NoteMap_FindBestMatch when it reaches 0 (`ld a,({A:0xE9BC}); ... dec 1,a`)."],
     [(0xE9BC, "VoiceMap_AllocateSlo_Block2"), (0xE9BC, "NoteMap_FindBestMatch"),
      (0xE9BC, "SeqEvt_CheckExpiry")]),
    (0xE9BE, 2, "WorkRam2_CallbackIndex", [
        "; {u8 index, 0xFF}; 20 at power-on.  UIStateEvt_EffectSelect_Data_Skip4 stores",
        "; (RAM 0xC07E) & 15 here; UIParam_CallbackDispatch reads it as the index of a",
        "; u32 entry (`ld c,({A:0xE9BE}); sla bc,2`) and calls through that entry."],
     [(0xE9BE, "UIStateEvt_EffectSelect_Data_Skip4"), (0xE9BE, "UIParam_CallbackDispatch")]),
    (0xE9C0, 2, "WorkRam2_EffectSelectByte", [
        "; {u8 value, 0xFF}; 0 at power-on.  UIStateEvt_EffectSelect_Data_Skip3 stores",
        "; RAM 0xC07E here; AudioInit_Pan_CheckReverbChannel compares it with 14 and",
        "; AudioInit_Pan_Reverb_CopyFromMain copies it to RAM 0xC2BC."],
     [(0xE9C0, "UIStateEvt_EffectSelect_Data_Skip3"), (0xE9C0, "AudioInit_Pan_CheckReverbChannel"),
      (0xE9C0, "AudioInit_Pan_Reverb_CopyFromMain")]),
    (0xE9C2, 2, "WorkRam2_SendEpilogueByte", [
        "; {u8 value, 0xFF}; 0 at power-on.  SendEpilogue_Data_Skip2 stores it,",
        "; SendEpilogue_Data_Skip compares a register with it (`cp ...,({A:0xE9C2})`)."],
     [(0xE9C2, "SendEpilogue_Data_Skip2")]),
    (0xE9C4, 0xEC11 - 0xE9C4, "WorkRam2_SongPlayerState", [
        "; Variables of the SeqFile_/SeqPlay_/SongFile_ routines (the song-file player),",
        "; zero at power-on except RAM {A:0xEC0D} = 0xFF, which no instruction names.",
        "; Offsets from here, with the routines that use them (audio/note_voice_mapping.s):",
        ";  +0x00 u8 state; the block from +0 is also passed by address",
        ";        (OutputFlush_Prologue, SeqFile_ParseHeader, LoadAndStartPlayback_LoadParam3",
        ";        `lda xwa,({A:0xE9C4})`, StoreAndReturn_Block clears it)",
        ";  +0x20 u8 mode 0-4 (OutputFlush_InitVal `cp ...,4`, RecordReadOK_LoadReg sets 2)",
        ";  +0x21 u16 flag bits 0x01/0x02/0x04/0x10 (SeqState_GetFlags, Acc_TransitionPlayMode,",
        ";        Acc_StopPlayMode, Acc_StartFillIn, DecodeMidiEvent_LoadParam3)",
        ";  +0x23 u32 running total (SeqFile_AccumulateLength, ConfigureBanks_Block,",
        ";        ToneGen_AccumulateDelta `add ({A:0xE9E7}),...`)",
        ";  +0x27 u32 (ConfigureBanks_LoadReg4, RecordReadOK_Block, MidiSysMsg_Handler_Helper)",
        ";  +0x2B u16 set to 384 or 480 (RecordReadOK_Block7, ToneGen_ReadFileRecord) or read",
        ";        from the file (SeqFile_ReadDivisionByte1); [INFERENCE] the SMF time",
        ";        division (384 and 480 are usual ticks-per-quarter values)",
        ";  +0x2D u16 (SeqFile_StoreTempoByte1, SeqFile_ReadTempoByte2)",
        ";  +0x2F u16 (FileIO_ReadChunk, SendSinglePacket_LoadReg)",
        ";  +0x31 u32 (SeqPlay_ReadRecord_Entry, SeqPlay_AccumulateDelta)",
        ";  +0x35, +0x37 buffers passed by address (DecodeMidiEvent_Block2,",
        ";        SeqPlay_CheckSysExMarker, SeqPlay_CopyToMidiBuffer)",
        ";  +0x135 u16 count and +0x137 buffer (DecodeMidiEvent_Block2, SeqPlay_CopyToMidiBuffer,",
        ";        SongFile_DecodeMidiEvent, SeqPlay_CheckMidiBuffer)",
        ";  +0x237 u16 count (SongFile_DecodeMidiEvent, SeqPlay_ClearMidiCount)",
        ";  +0x239 u32, +0x23D u16, +0x23F/+0x240/+0x241 u8 (Epilogue_Block,",
        ";        ToneGen_ProcessMidiConverge, ToneGen_ValidateRange_Loop `cp ...,7`,",
        ";        ProcessMidiConverge_LoadDRAM clamps +0x241 to 127)",
        ";  +0x24A u16 countdown from 6 (PlayModeStateMachine_Prologue)",
        ";  +0x24C u8 (SeqPlay_CheckStatusByte)"],
     [(0xE9C4, "OutputFlush_Prologue"), (0xE9C4, "SeqFile_ParseHeader"),
      (0xE9E4, "OutputFlush_InitVal"), (0xE9E4, "RecordReadOK_LoadReg"),
      (0xE9E5, "SeqState_GetFlags"), (0xE9E5, "Acc_StartFillIn"),
      (0xE9E7, "SeqFile_AccumulateLength"), (0xE9E7, "ToneGen_AccumulateDelta"),
      (0xE9EB, "ConfigureBanks_LoadReg4"), (0xE9EF, "RecordReadOK_Block7"),
      (0xE9EF, "ToneGen_ReadFileRecord"), (0xE9EF, "SeqFile_ReadDivisionByte1"),
      (0xE9F1, "SeqFile_StoreTempoByte1"), (0xE9F3, "FileIO_ReadChunk"),
      (0xE9F5, "SeqPlay_AccumulateDelta"), (0xE9F9, "SeqPlay_CheckSysExMarker"),
      (0xE9FB, "SeqPlay_CopyToMidiBuffer"), (0xEAF9, "DecodeMidiEvent_Block2"),
      (0xEAFB, "SongFile_DecodeMidiEvent"), (0xEBFB, "SeqPlay_ClearMidiCount"),
      (0xEBFD, "Epilogue_Block"), (0xEC01, "ToneGen_ProcessMidiConverge"),
      (0xEC04, "ToneGen_ValidateRange_Loop"), (0xEC05, "ProcessMidiConverge_LoadDRAM"),
      (0xEC0E, "PlayModeStateMachine_Prologue"), (0xEC10, "SeqPlay_CheckStatusByte")]),
]


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def layout(v):
    """-> (ROM address of the file's first byte, RAM delta vs v10)."""
    L = vm.locate(v)
    d = rom(v)
    # array A's free-list head read (`ld a,(X); ldb_erp; cp a,0x80`) -> X = sentinel+1
    hits = [int.from_bytes(m.group(1), "little")
            for m in re.finditer(rb"\xc1(..)\x21\xc7\xfb\x99\xc9\xcf\x80", d, re.S)]
    assert len(hits) == 1, (v, hits)
    base_a = hits[0] - 1 - 2 * 0x80
    ram0 = base_a + 2 * 0x21
    rom0 = L["src"] + (ram0 - L["dest"])
    assert L["dest"] <= ram0 and ram0 + LEN == L["table"] - L["src"] + L["dest"], v
    return rom0, ram0 - V10_RAM0, L


def check_bytes(v, rom0):
    d = rom(v)
    t = d[rom0 - B:rom0 - B + LEN]
    assert t == rom("v10")[0xEEFF78 - B:0xEEFF78 - B + LEN], v

    def node(ram):
        o = ram - V10_RAM0
        return t[o], t[o + 1]
    for k in range(0x21, 0x80):
        assert node(BASE_A + 2 * k) == (k - 1, 0x80 if k == 0x7F else k + 1), hex(k)
    assert node(BASE_A + 0x100) == (0x7F, 0x00)
    for k in range(0x81, 0xA1):
        assert node(BASE_A + 2 * k) == (k, k)
    for k in range(0x20):
        assert node(BASE_B + 2 * k) == (0x20 if k == 0 else k - 1, 0x20 if k == 0x1F else k + 1)
    assert node(BASE_B + 0x40) == (0x1F, 0x00)
    for k in range(0x21, 0x25):
        assert node(BASE_B + 2 * k) == (k, k)
    tail = t[0xE9C4 - V10_RAM0:]
    assert all(b == 0 for i, b in enumerate(tail) if i != 0xEC0D - 0xE9C4) and tail[0xEC0D - 0xE9C4] == 0xFF


def source_refs(v="v10"):
    """RAM address -> set of routine labels whose instructions name it (v10 source)."""
    lab_re = re.compile(r"^([A-Za-z_.$][\w.$]*):")
    num = re.compile(r"\b0x([0-9a-fA-F]{4})\b")
    out = collections.defaultdict(set)
    for f in glob.glob(os.path.join(ROOT, v, "maincpu", "**", "*.s"), recursive=True):
        lab = None
        for ln in open(f, encoding="latin-1"):
            m = lab_re.match(ln)
            if m:
                lab = m.group(1)
            code = ln.split(";")[0]
            if not code.startswith("\t") or code.strip().startswith("."):
                continue
            if "(" not in code and not code.strip().startswith("ldmm"):
                continue
            for m in num.finditer(code):
                out[int(m.group(1), 16)].add(lab)
    return out


def prefix_hits(d, ram):
    lo, hi = ram & 0xFF, ram >> 8
    return [B + m.start() for m in re.finditer(re.escape(bytes([lo, hi])), d)
            if m.start() >= 1 and d[m.start() - 1] in (0xC1, 0xD1, 0xE1, 0xF1) and B + m.start() >= 0xEF0000]


def probe():
    refs = source_refs()
    lay = {v: layout(v) for v in ("v10", "v9", "v7")}
    for v, (rom0, delta, L) in lay.items():
        check_bytes(v, rom0)
        print("%s: file ROM 0x%06X-0x%06X = RAM 0x%04X-0x%04X (RAM delta vs v10 %+#x); copy at 0x%06X"
              % (v, rom0, rom0 + LEN - 1, V10_RAM0 + delta, V10_RAM0 + delta + LEN - 1, delta, L["copy_at"]))
    print("node links, sentinels and the zero tail verified byte by byte in all three")
    ds = {v: rom(v) for v in lay}
    bad = 0
    for ram, size, name, hdr, cites in OBJS:
        for (a, routine) in cites:
            if routine not in refs.get(a, ()):
                print("  MISSING: %s does not name RAM 0x%04X in the v10 source" % (routine, a))
                bad += 1
        addrs = sorted({a for a, _ in cites})
        cnt = {v: sum(len(prefix_hits(ds[v], a + lay[v][1])) for a in addrs) for v in lay}
        print("%-30s RAM 0x%04X  %3d B  cited %2d  prefix-operand hits v10 %2d v9 %2d v7 %2d"
              % (name, ram, size, len(cites), cnt["v10"], cnt["v9"], cnt["v7"]))
    assert not bad
    return 0


def fill(line, delta):
    return re.sub(r"\{A:0x([0-9A-F]{4})\}", lambda m: "0x%04X" % (int(m.group(1), 16) + delta), line)


def rows(data, ram, per=16):
    out = []
    for k in range(0, len(data), per):
        chunk = data[k:k + per]
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in chunk) + "\t; RAM 0x%04X" % (ram + k))
    return out


def emit(v):
    rom0, delta, L = layout(v)
    check_bytes(v, rom0)
    t = rom(v)[rom0 - B:rom0 - B + LEN]
    r0 = V10_RAM0 + delta
    out = [
        "; =============================================================================",
        "; Work-RAM image 2, tail: ROM 0x%06X-0x%06X -> RAM 0x%04X-0x%04X" % (rom0, rom0 + LEN - 1, r0, r0 + LEN - 1),
        "; =============================================================================",
        "; Not read in ROM.  Boot_InitWorkRAM_ROMCopy2_Start (0x%06X) copies ROM" % L["copy_at"],
        "; 0x%06X-0x%06X (0x%X bytes) to RAM 0x%04X at boot, so each byte here is the" % (
            L["src"], L["src"] + L["len"] - 1, L["len"], L["dest"]),
        "; power-on value of a RAM byte and the code uses the RAM addresses (given",
        "; per row below).  The image starts in ui_widgets/sequencer_channel_containers.s",
        "; and ends with SndParam_ValueMapGrid (ui/charmap_dispatch_table.s).",
        "; Formerly titled \"Character Encoding Tables & NAKA State Blocks\": the text-like",
        "; bytes and most instructions decoded here were node links, the rest small",
        "; variables; the zero blocks are song-player variables.  The old labels stay",
        "; as `.set` aliases at the end.",
        "; Pinned by scripts/generators/gen_workram2_tail.py --probe (v10, v9, v7).",
    ]
    if v == "v7":
        out.append("; v7 holds the same 929 bytes; its RAM addresses are v10's minus 0xC6.  Routine")
        out.append("; names are v10's (the v7 counterparts use the v7 RAM addresses).")
    out += ["; Extracted from kn5000_v10_program.s",
            "; ============================================================================="]
    for ram, size, name, hdr, cites in OBJS:
        o = ram - V10_RAM0
        out.extend(fill(h, delta) for h in hdr)
        out.append("%s:" % name)
        data = t[o:o + size]
        if name == "WorkRam2_SongPlayerState":
            # zero runs as .zero, the one 0xFF byte as .byte
            k = 0
            while k < size:
                j = k
                while j < size and data[j] == 0:
                    j += 1
                if j > k:
                    out.append("\t.zero %d\t; RAM 0x%04X" % (j - k, ram + delta + k))
                    k = j
                else:
                    out.append("\t.byte 0x%02x\t; RAM 0x%04X" % (data[k], ram + delta + k))
                    k += 1
        else:
            out.extend(rows(data, ram + delta))
    out.append("; Legacy labels, kept because other files name them (NAKA C records, factory_test/")
    out.append("; fd_test_data.s, audio/sound_editor_ui.s, audio/presentation_sound_nav.s,")
    out.append("; extensions/extension_data.s, shared/positional_labels.s):")
    owners = sorted((r, n) for r, _, n, _, _ in OBJS)
    for leg, lram in sorted(LEGACY.items(), key=lambda x: x[1]):
        base = max((r, n) for r, n in owners if r <= lram)
        off = lram - base[0]
        out.append("\t.set %s, %s%s" % (leg, base[1], (" + %d" % off) if off else ""))
    return "\n".join(out) + "\n"


def apply(v):
    path = os.path.join(ROOT, v, "maincpu/ui/char_encoding_naka_state.s")
    old = open(path, "rb").read().decode("latin-1")
    assert "Character Encoding Tables & NAKA State Blocks" in old.split("\n")[1], "already applied?"
    open(path, "wb").write(emit(v).encode("latin-1"))
    print("%s rewritten" % path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--emit")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if a.emit:
        sys.stdout.write(emit(a.emit))
        return 0
    if a.apply:
        for v in a.apply:
            apply(v)
        return 0
    return probe()


if __name__ == "__main__":
    sys.exit(main())
