#!/usr/bin/env python3
r"""INCOMING-SYSEX RECOGNITION TRIE (maincpu 0xEE3678-0xEE4A0F): prove, emit, apply.

QUESTION ANSWERED
-----------------
What are the bytes the tree called DisplayScript_NullNode .. DisplayScript_NodeCont_015
and WidgetParam_Entry_000..018 (partly decoded as `swi 7 / jrl -4554 / reti`)?
An array of 817 six-byte entries {u8 key, u8 action, u32 next} that the MIDI
receive code walks to recognise system-exclusive messages byte by byte,
followed by four small tables.

THE READER (midi/*, v10 addresses; the routine names there are older guesses)
  MidiSeq_AssignVoiceSlots 0xFD5F57 / MidiSeq_ScanSlot0_Loop 0xFD5F74:
      `lda xbc,(0xEE493E)` then per entry `muls wa,6; add xwa,xbc` and
      `cp (xwa),255` -> end of list (reports code 7),
      `cp (xwa),l`   -> the entry matches the received byte in l,
      `cp (xwa),254` -> wildcard, matches any byte;
  MidiSeq_Slot0_WriteParams 0xFD5F9A: `ld e,(xwa+1)` = the entry's action,
      `lda xwa,(0xEE4940); ld_rrl xwa,xwa,bc` = its +2 next-list pointer;
  MidiSeq_Slot0_StorePtr 0xFD600A: `ld xwa,(xwa+2)` = descend.
  The root list (entries 801-816, 0xEE493E) holds exactly the third bytes of
  the Technics messages this ROM also sends (0x21-0x25, 0x27-0x2D after
  F0 50, see SysEx_Msg_* / SysEx_TechMsg_*) plus 0x7E / 0x7F (Universal
  Non-Real-Time / Real-Time); following e.g. 0x21 -> 0x01 -> 0x28 -> 0x12
  reaches action 7, the byte sequence of SysEx_Msg_35BC (F0 50 21 01 28 12).

WHAT --probe ASSERTS
  1. every +2 pointer is 0 or lands on an entry boundary of the array;
  2. no 32-bit word outside the array points into it on its 6-byte grid (an
     entry or an entry's +2); the only instruction references are 0xEE493E and
     0xEE4940 (the root list and its +2 field);
  3. v10, v9 and v7 hold identical bytes over 0xEE3678-0xEE4A0F.

RUN
    python3 scripts/generators/gen_sysex_rx_trie.py --probe
    python3 scripts/generators/gen_sysex_rx_trie.py --apply v10 v9 v7
      (needs a fresh line map: uses scripts/analysis/file_line_addresses.py;
       replaces the lines from 0xEE3678 up to the line at 0xEE4A10, i.e. up to
       `ToneKit_FrequencyTable:` and the comments above it; then `make gate`)
"""
import argparse
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
B = 0xE00000
LO, END_TRIE, HI = 0xEE3678, 0xEE499E, 0xEE4A10
N = (END_TRIE - LO) // 6
ROOT_E = 801
KEEP_ALIAS = {795: "WidgetParam_Entry_018"}   # shared/positional_labels.s base


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def entries(d):
    return [(d[LO - B + 6 * i], d[LO - B + 6 * i + 1],
             struct.unpack_from("<I", d, LO - B + 6 * i + 2)[0]) for i in range(N)]


def probe():
    ds = {v: rom(v) for v in ("v10", "v9", "v7")}
    for v in ("v9", "v7"):
        assert ds[v][LO - B:HI - B] == ds["v10"][LO - B:HI - B], v
    print("3. v10 == v9 == v7 over 0x%06X..0x%06X" % (LO, HI))
    d = ds["v10"]
    ents = entries(d)
    for i, (k, a, p) in enumerate(ents):
        assert p == 0 or (LO <= p < END_TRIE and (p - LO) % 6 == 0), (i, hex(p))
    print("1. %d entries; every non-zero +2 pointer is an entry of the array" % N)
    outside = []
    for i in range(len(d) - 3):
        t = struct.unpack_from("<I", d, i)[0]
        if LO <= t < END_TRIE and not (LO <= B + i < END_TRIE) and (t - LO) % 6 in (0, 2):
            outside.append((hex(B + i), hex(t)))
    print("2. 32-bit words outside the array that point on its 6-byte grid (entry or +2):",
          outside or "none")
    roots = [(k, a, (p - LO) // 6 if p else None) for k, a, p in ents[ROOT_E:]]
    print("   root list:", " ".join("%02X" % k for k, a, p in roots))
    return 0


def emit(d):
    ents = entries(d)
    targets = sorted({(p - LO) // 6 for k, a, p in ents if p})
    lab = {}
    for t in targets:
        lab[t] = "SysExRx_Trie_%03d" % t
    lab[ROOT_E] = "SysExRx_TrieRoot"
    L = []
    w = L.append
    w("; =============================================================================")
    w("; INCOMING SYSTEM-EXCLUSIVE RECOGNITION TRIE  (0xEE3678-0xEE499D, 817 x 6 bytes)")
    w("; =============================================================================")
    w("; Entry = {u8 key, u8 action, u32 next list}.  A list is consecutive entries")
    w("; ending with key 0xFF; key 0xFE matches any byte.  The receive code walks it")
    w("; one incoming byte at a time -- MidiSeq_ScanSlot0_Loop (0xFD5F74): `muls wa,6`")
    w("; entry index, `cp (xwa),255` end of list (error code 7), `cp (xwa),l` match,")
    w("; `cp (xwa),254` wildcard; MidiSeq_Slot0_WriteParams (0xFD5F9A) takes the")
    w("; action from +1 and the next list from +2 (`lda xwa,(SysExRx_TrieRoot+2);")
    w("; ld_rrl`), MidiSeq_Slot0_StorePtr (0xFD600A) descends with `ld xwa,(xwa+2)`.")
    w("; SysExRx_TrieRoot (entry 801) lists the third byte after F0 50: 0x21-0x25,")
    w("; 0x27-0x2D -- the Technics messages this ROM also sends (SysEx_Msg_*,")
    w("; SysEx_TechMsg_*) -- and 0x7E/0x7F (Universal SysEx).  Example path:")
    w("; root 0x21 -> 0x01 -> 0x28 -> 0x12 gives action 7 = F0 50 21 01 28 12.")
    w("; On key-0xFF entries the +1 byte (0x07..0x10) is not read by the root scan.")
    w("; Pinned by scripts/generators/gen_sysex_rx_trie.py --probe: every pointer")
    w("; lands on an entry; nothing outside the array points into it; the only")
    w("; instruction references are SysExRx_TrieRoot and SysExRx_TrieRoot+2.")
    w("; Byte-identical in v7, v9 and v10.")
    w("; =============================================================================")
    w(".macro sysex_rx_entry key, action, next")
    w("\t.byte \\key, \\action")
    w("\t.long \\next")
    w(".endm")
    for i, (k, a, p) in enumerate(ents):
        if i in lab:
            if i == ROOT_E:
                w("; root list (entries 801-816): first byte after F0 50 / the Universal id")
            w("%s:" % lab[i])
        if i in KEEP_ALIAS:
            w("\t.set %s, %s" % (KEEP_ALIAS[i], lab.get(i, "SysExRx_Trie_%03d" % i)))
            if i not in lab:
                raise SystemExit("alias entry %d has no label" % i)
        nxt = lab[(p - LO) // 6] if p else "0"
        note = ""
        if k == 0xFF:
            note = "\t; end of list"
        elif k == 0xFE:
            note = "\t; any byte"
        w("\tsysex_rx_entry 0x%02x, 0x%02x, %s%s" % (k, a, nxt, note))
    # the four tables after the trie
    w("; 22 x u8 monotone map 0..12.  MidiSeq_UpdateToneParam (0xFD740A) and")
    w("; MidiSeq_UpdateToneParam_Lower (0xFD743A): `lda xbc,(<this>); ld_rrb c,xbc,hl`,")
    w("; the byte is stored to RAM 0xBD00.")
    w("MidiRx_ToneParam_ByteMap:")
    w("\t.byte " + ", ".join("%d" % b for b in d[0xEE499E - B:0xEE49B4 - B]))
    w("; 36 x u8 (0x20-0x23, 0x0F, one 0xFF).  MidiSeq_PartLookup_Data_Helper3 (0xFD759F):")
    w("; `lda xbc,(<this>); ld (0x7F42),(xbc+hl)` -- copies the indexed byte to RAM.")
    w("MidiRx_PartLookup_ByteMap:")
    seg = d[0xEE49B4 - B:0xEE49D8 - B]
    w("\t.byte " + ", ".join("0x%02x" % b for b in seg[:18]))
    w("\t.byte " + ", ".join("0x%02x" % b for b in seg[18:]))
    w("; 16-byte template: ArpQueue_InitBuffer (0xFD83D2) copies it into the queue buffer")
    w("; (`ld xiy,<this>; ld xix,xde; ldw bc,8; ldirw`).")
    w("ArpQueue_InitTemplate:")
    w("\t.byte " + ", ".join("0x%02x" % b for b in d[0xEE49D8 - B:0xEE49E8 - B]))
    w("; 40 bytes of MIDI control records.  0xEE49E8 is the sentinel")
    w("; MidiPkt_MatchParamInTable (0xFDA258) stops at (`lda xix,(<this>)`, `cp xix,xhl;")
    w("; ret z`) and MidiPkt_EnqueueControl_3354 (0xFDA278) compares record pointers against;")
    w("; readers take +2/+3/+7/+8/+11 of such records.  Record boundaries inside")
    w("; these 40 bytes (and in the records after them) are not established yet.")
    w("MidiCtl_SentinelRecord:")
    seg = d[0xEE49E8 - B:HI - B]
    for j in range(0, len(seg), 10):
        w("\t.byte " + ", ".join("0x%02x" % b for b in seg[j:j + 10]))
    return "\n".join(L) + "\n"


def apply(v):
    import file_line_addresses as fla
    path = os.path.join(ROOT, v, "maincpu/ui_widgets/widget_dispatch.s")
    ent = fla.build(v, "ui_widgets/widget_dispatch.s")
    first = {}
    for e in ent:
        first.setdefault(e["addr"], e["line"])
    assert LO in first and HI in first, "range ends are not line starts"
    raw = open(path, "rb").read()
    lines = raw.split(b"\n")
    fl, ll = first[LO], first[HI] - 1
    while ll >= fl and (not lines[ll - 1].strip() or lines[ll - 1].lstrip().startswith(b";")):
        ll -= 1
    old = lines[fl - 1:ll]
    assert not any(b";" in l for l in old if not l.lstrip().startswith(b".ascii")), \
        "comment inside the replaced block"
    new = emit(rom(v)).encode("latin-1").rstrip(b"\n").split(b"\n")
    lines[fl - 1:ll] = new
    open(path, "wb").write(b"\n".join(lines))
    print("%s: replaced lines %d..%d (%d) with %d" % (path, fl, ll, ll - fl + 1, len(new)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if a.probe:
        return probe()
    if a.emit:
        sys.stdout.write(emit(rom("v10")))
        return 0
    for v in a.apply or []:
        apply(v)
    return 0


if __name__ == "__main__":
    sys.exit(main())
