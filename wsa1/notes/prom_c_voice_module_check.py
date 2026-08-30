#!/usr/bin/env python3
"""Does the 0xFB0504-0xFB405E block really say what its headers claim?

QUESTION IT ANSWERS
  Round 6 converted 15,195 contiguous bytes -- the MIDI-message parser, the voice
  query/retire family, the four parameter-compute/stage pairs and the note
  dispatcher.  Every quantified claim in that block's comment, in its 32 routine
  headers and in notes/FINDINGS-prom_c-voice-module.md comes from here.

  It reads `original_ROMs/wsa1_prom_c.ic28` and matches BYTES, never unidasm's
  text and never the `.s` file, so nothing it asserts can drift when either of
  those is edited, and a header cannot quietly disagree with the ROM.

WHAT IT CHECKS
  1  the seven MIDI status arms of MidiIn_ParseRingAndDispatch, IN ORDER, read out
     of the `cp BC,0x00N0` immediates themselves -- including that 0xA0 is ABSENT
  1b PER ARM: how many ring bytes it consumes and which handler it calls, read out
     of that arm's own `cp DE,n` guard, its `decw n,(count)` and its `call`.
     ⚠ A first draft of the block comment said "every arm consumes four bytes, the
     0xC0 arm five".  The 0x80 arm consumes SIX.  This section exists because of
     that error.
  2  the 4096-byte ring mask and the four-byte packet stride
  3  the four messages MidiMsg_SendBootSequence writes, byte for byte
  4  the six VoiceQuery_* constant triples (tag / key / mask), and that the six
     are the only routines in the block that build the 0x00D815 record
  5  the voice-record geometry: base 0x00003BCF, stride 0x44, bound 0x40
  6  the part-record geometry: base 0x00001523, stride 0x012C, bound 0x21
  7  the expansion-board signature "WSA1 EXTBD" and the eight 32-bit bases
     ExtBoard_ProbeAndInstallBases installs
  8  a reference census over ALL 32 routine starts: `call`, `calr`, `jrl`, `jp`
     and any 24-bit literal -- which is where the four orphan routines come from
  9  the seven small tables at 0xFE1280-0xFE12B4, censused BYTE BY BYTE -- which
     is what fixes their edges, and what shows the mask table and the shift table
     are read as a pair (identical per-entry site counts 5/3/2/2)
 10  the call sets of the four VoiceRegs_Stage_* routines and the SET RELATIONS
     between them -- how many targets each has, how many it shares with each of
     the others, and which are its own.  Hand-counting these is exactly the kind
     of arithmetic this tree has shipped wrong before, so the headers quote this
     section rather than a count made by eye.
 11  the four ORPHAN / big-routine pairs: that each orphan's `call` targets are a
     strict SUBSET of the routine that follows it, and that the three extra
     callees are the same three every time
 12  MidiNote_OnTail and MidiNote_OffTail: same length, NOT byte-identical
 13  ⚠ THE ONE SECTION THAT READS `prom_c/wsa1_prom_c.s`: that the 32 routine
     headers' own "0xAAAAAA..0xBBBBBB (N bytes)" lines are self-consistent, name
     the 32 addresses this script knows, carry a matching label, and TILE
     0xFB0504-0xFB405E with no gap and no overlap.  A header that drifts off the
     routine it sits above is invisible to the byte gate, and this is the check
     for it.

LIMITS -- read before quoting a number
  * The reference census is an UPPER BOUND for `call`/`jp` (a byte census of
    `1D`/`1B` + literal with no instruction-boundary filter) and for `calr`/`jrl`
    (every offset whose displacement lands on the target).  It is a LOWER bound on
    nothing: a target computed at run time, or reached through a pointer the code
    builds arithmetically, is invisible.  "No reference found" is therefore a
    SEARCHED NEGATIVE, and the four orphans are reported as exactly that.
  * It cannot show that a routine COMPUTES what its name says.  It shows the bytes
    the argument rests on are there.

RUN
  python3 notes/prom_c_voice_module_check.py            # every check
  python3 notes/prom_c_voice_module_check.py --refs     # just the census
  python3 notes/prom_c_voice_module_check.py --selftest # + the LAST-element tests
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
BASE = 0xF80000
LO, HI = 0xFB0504, 0xFB405F            # the block, end-exclusive

fails = []


def check(ok, what):
    print("  %-4s %s" % ("ok" if ok else "FAIL", what))
    if not ok:
        fails.append(what)


def at(a, n):
    return ROM[a - BASE:a - BASE + n]


def find_all(pat):
    out, i = [], 0
    while True:
        i = ROM.find(pat, i)
        if i < 0:
            return out
        out.append(BASE + i)
        i += 1


# --------------------------------------------------------------------------
# 8. reference census -- run first, the other sections quote it
# --------------------------------------------------------------------------
ROUTINES = [
    (0xFB0504, "ExtBoard_ProbeAndInstallBases"),
    (0xFB05EC, "Toggle14FE_AndDispatch"),
    (0xFB060A, "MidiIn_ParseRingAndDispatch"),
    (0xFB0A0D, "MidiMsg_SendBootSequence"),
    (0xFB0A8B, "Dev10C_ChanReset"),
    (0xFB0AD0, "VoiceRegs_Stage_A"),
    (0xFB0B95, "sub_FB0B95"),
    (0xFB0E4F, "VoiceParams_Compute_A"),
    (0xFB1EBD, "VoiceRegs_Stage_B"),
    (0xFB1FB1, "sub_FB1FB1"),
    (0xFB2172, "VoiceParams_Compute_B"),
    (0xFB27EE, "VoiceRegs_Stage_C"),
    (0xFB289A, "sub_FB289A"),
    (0xFB2A98, "VoiceParams_Compute_C"),
    (0xFB2EB7, "VoiceRegs_Stage_D"),
    (0xFB2F74, "sub_FB2F74"),
    (0xFB31AB, "VoiceParams_Compute_D"),
    (0xFB3634, "MidiNote_OnTail"),
    (0xFB374A, "MidiNote_OffTail"),
    (0xFB3860, "MidiNote_OnByPartMode"),
    (0xFB3C28, "VoiceQuery_Tag80_PartNote"),
    (0xFB3C5F, "VoiceQuery_Tag80_Part"),
    (0xFB3C8B, "VoiceQuery_Tag40_Part"),
    (0xFB3CB4, "VoiceQuery_Tag00_PartBit7"),
    (0xFB3CE0, "VoiceQuery_Tag00_Part"),
    (0xFB3D09, "VoiceQuery_Tag00_All"),
    (0xFB3D26, "Voice_Retire_Mode20"),
    (0xFB3DC1, "Voice_Retire_Mode08"),
    (0xFB3E50, "Voice_Retire_Mode10"),
    (0xFB3E8B, "VoiceList_RetireByMode"),
    (0xFB3F36, "MidiNote_Dispatch"),
    (0xFB3FA0, "VoiceRecords_InitFromAlloc"),
]
ORPHANS = {0xFB0B95, 0xFB1FB1, 0xFB289A, 0xFB2F74}


def refs(t):
    """(call, calr, jrl, jp, other-literal) site lists for one address."""
    lit = struct.pack("<I", t)[:3]
    call = find_all(b"\x1d" + lit)
    jp = find_all(b"\x1b" + lit)
    anylit = find_all(lit)
    other = [a for a in anylit if a - 1 not in
             [c for c in call] + [j for j in jp]]
    calr, jrl = [], []
    for i in range(len(ROM) - 3):
        b = ROM[i]
        if b == 0x1E:
            d = struct.unpack("<h", ROM[i + 1:i + 3])[0]
            if BASE + i + 3 + d == t:
                calr.append(BASE + i)
        elif 0x70 <= b <= 0x7F:
            d = struct.unpack("<h", ROM[i + 1:i + 3])[0]
            if BASE + i + 3 + d == t:
                jrl.append(BASE + i)
    return call, calr, jrl, jp, other


def do_refs(verbose=True):
    orph = []
    rows = {}
    for a, name in ROUTINES:
        call, calr, jrl, jp, other = refs(a)
        rows[a] = (call, calr, jrl, jp, other)
        total = len(call) + len(calr) + len(jrl) + len(jp) + len(other)
        if total == 0:
            orph.append(a)
        if verbose:
            print("  %-30s 0x%06X  call %2d  calr %2d  jrl %2d  jp %2d  lit %2d   %s"
                  % (name, a, len(call), len(calr), len(jrl), len(jp), len(other),
                     " ".join("%06X" % x for x in (call + calr + jrl + jp + other)[:6])))
    return rows, orph


# --------------------------------------------------------------------------
def main():
    only_refs = "--refs" in sys.argv
    selftest = "--selftest" in sys.argv

    print("prom_c 0xFB0504-0xFB405E -- %d bytes, %d routines" % (HI - LO, len(ROUTINES)))
    print()
    print("REFERENCE CENSUS (upper bound for call/jp/calr/jrl; searched negative when 0)")
    rows, orph = do_refs()
    print()
    check(sorted(orph) == sorted(ORPHANS),
          "exactly four routines have NO reference of any kind: %s"
          % " ".join("0x%06X" % a for a in sorted(orph)))
    for a, name in ROUTINES:
        if a in ORPHANS:
            continue
        call, calr, jrl, jp, other = rows[a]
        if len(call) + len(calr) + len(jrl) + len(jp) == 0:
            check(False, "%s has no control-transfer reference" % name)
    if only_refs:
        return 0 if not fails else 1

    print()
    print("1  MIDI STATUS DISPATCH -- read out of the `cp BC,imm16` immediates")
    # `d9 cf LO HI` = cp BC,0xHILO ; each is followed by jr/jrl to the arm
    arms, a = [], 0xFB064F
    while at(a, 2) == b"\xd9\xcf":
        v = struct.unpack("<H", at(a + 2, 2))[0]
        nxt = at(a + 4, 1)[0]
        skip = 6 if nxt == 0x66 else 7          # jr Z,d8  vs  jrl Z,d16
        arms.append(v)
        a += skip
    print("        arms: " + " ".join("0x%02X" % (v >> 4 & 0xFF0 | 0) for v in arms)
          if False else "        arms: " + " ".join("0x%04X" % v for v in arms))
    check(arms == [0x0080, 0x0090, 0x00B0, 0x00C0, 0x00D0, 0x00E0, 0x00F0],
          "seven status arms in this order: 80 90 B0 C0 D0 E0 F0")
    check(0x00A0 not in arms,
          "0xA0 -- the MIDI status for polyphonic key pressure -- has NO arm; it"
          " falls to the default, which drains the ring")
    check(at(0xFB0649, 3) == b"\xcb\xcc\xf0",
          "the status byte is masked with 0xF0 first (`and C,0xf0` at 0xFB0649)")

    print()
    print("1b PER-ARM PACKET LENGTH AND HANDLER")
    ARMS = [(0x80, 0xFB0682), (0x90, 0xFB07A3), (0xB0, 0xFB080E), (0xC0, 0xFB086A),
            (0xD0, 0xFB08DA), (0xE0, 0xFB0936), (0xF0, 0xFB0992), (None, 0xFB09FA)]
    # ⚠ the 0xF0 arm ends at 0xFB09EC, NOT at the default arm's entry: 0xFB09ED is
    # the shared "too few bytes" exit and 0xFB09F1-0xFB09F9 is the default arm's
    # drain-loop BODY, which sits physically in front of the `cp DE,0` it branches
    # to.  Taking the next arm's entry as the previous arm's end put that loop's
    # `decw 1` inside the 0xF0 row and made it read "consumes 1 or 4".
    ENDS = [a for _, a in ARMS[1:-1]] + [0xFB09ED, 0xFB0A0D]

    def cnt(b):
        return 8 if (b & 7) == 0 else (b & 7)

    table = []
    for (st, a0), a1 in zip(ARMS, ENDS):
        seg = at(a0, a1 - a0)
        decs = [cnt(seg[i + 1]) for i in range(len(seg) - 1)
                if seg[i] == 0x91 and 0x68 <= seg[i + 1] <= 0x6F]
        guards = [seg[i + 1] & 7 for i in range(len(seg) - 1)
                  if seg[i] == 0xDA and 0xD8 <= seg[i + 1] <= 0xDF]
        cl = []
        for i in range(len(seg) - 3):
            if seg[i] == 0x1D:
                t = seg[i + 1] | seg[i + 2] << 8 | seg[i + 3] << 16
                if 0xF80000 <= t <= 0xFFFFFF:
                    cl.append(t)
        table.append((st, a0, guards, decs, cl))
        print("        arm %-7s 0x%06X  guard cp DE,%s  consumes %s  -> %s"
              % ("0x%02X" % st if st is not None else "default", a0,
                 sorted(set(guards)) or "-", sorted(set(decs)) or "-",
                 " ".join("0x%06X" % t for t in cl) or "-"))
    got = {st: (sorted(set(d)), c) for st, _, _, d, c in table}
    check(got[0x80] == ([6], [0xFC2600]),
          "the 0x80 arm consumes SIX bytes and calls 0xFC2600 -- it is NOT the note"
          " handler, and its packet is not four bytes")
    check(got[0x90] == ([4], [0xFB3F36, 0xFC3E02]),
          "the 0x90 arm consumes four and calls MidiNote_Dispatch, or 0xFC3E02 when"
          " packet byte [1] >= 0xF0")
    check(got[0xB0] == ([4], [0xFAFDA5]) and got[0xC0] == ([5], [0xFB6BA8]),
          "0xB0 consumes four -> 0xFAFDA5; 0xC0 consumes FIVE -> 0xFB6BA8")
    check(got[0xD0] == ([4], [0xFB0013]) and got[0xE0] == ([4], [0xFB0132]),
          "0xD0 -> 0xFB0013 and 0xE0 -> 0xFB0132, four bytes each")
    check(got[0xF0] == ([4], [0xFB0338]),
          "0xF0 -> 0xFB0338, four bytes -- exactly one decrement size, once the arm"
          " is bounded at 0xFB09EC and not at the default arm's entry")
    check(at(0xFB09F1, 8) == b"\xda\x69\xae\xf4\x21\x91\x69\x94",
          "the DEFAULT arm drains the ring ONE BYTE AT A TIME (`dec 1,DE` /"
          " `decw 1,(count)` / `incw 1,(cursor)` at 0xFB09F1) until it is empty")
    check(at(0xFB09FE, 4) == b"\x1d\xb9\x8c\xf9",
          "0xF98CB9 (KeyEvents_ToLink) is called at the LOOP TAIL (0xFB09FE), once"
          " per iteration -- it is not one of the arms' handlers")
    check(at(0xFB0A02, 5) == b"\xcf\xd8\x7e\x12\xfc",
          "and the loop repeats while L != 0, i.e. until an arm's guard finds too"
          " few bytes and sets L = 0 at 0xFB09ED")

    print()
    print("2  THE RING")
    check(at(0xFB063A, 4) == b"\xdd\xcc\xff\x0f",
          "the read cursor is masked with 0x0FFF -- a 4096-byte ring (0xFB063A)")
    # every arm decrements the count by 4 except the 0xC0 arm's own guard
    check(at(0xFB07EE, 2) == b"\x91\x6c",
          "the note arm consumes FOUR ring bytes (`decw 4,(XBC)` at 0xFB07EE)")
    check(at(0xFB0619, 2) == b"\xda\xdc" and at(0xFB086A, 2) == b"\xda\xdd",
          "the entry guard is `cp DE,4` and the 0xC0 arm's is `cp DE,5`")

    print()
    print("3  MidiMsg_SendBootSequence -- the four messages, byte for byte")
    # each `ld (0x00d7xx),imm8` is  F2 lo hi 00 00 imm
    msgs = []
    for a0, n in ((0xFB0A13, 5), (0xFB0A3B, 4), (0xFB0A4F, 4), (0xFB0A71, 4)):
        if a0 in (0xFB0A3B, 0xFB0A71):
            # (XIX) / (XIX+k) forms: B4 00 imm  then  BC kk 00 imm
            b = at(a0, 3 + 4 * 3)
            vals = [b[2]] + [b[3 + 4 * i + 3] for i in range(3)]
        else:
            vals = [at(a0 + 6 * i, 6)[5] for i in range(n)]
        msgs.append(vals)
    for i, m in enumerate(msgs):
        print("        msg %d: %s" % (i, " ".join("0x%02X" % v for v in m)))
    check(msgs[0][:5] == [0xC0, 0x00, 0x00, 0x00, 0x00],
          "message 0 = C0 00 00 00 00 -> the 0xFB6BA8 handler; FIVE bytes, which is"
          " also what the parser's 0xC0 arm consumes")
    check(msgs[1] == [0xB0, 0x00, 0x07, 0x00],
          "message 1 = B0 00 07 00 -> controller 7, MIDI CHANNEL VOLUME, value 0")
    check(msgs[2] == [0x90, 0x00, 0x30, 0x01],
          "message 2 = 90 00 30 01 -> note 0x30 velocity 1")
    check(msgs[3] == [0xB0, 0x00, 0x78, 0x7F],
          "message 3 = B0 00 78 7F -> controller 120, MIDI ALL SOUND OFF, value 127")

    print()
    print("4  THE SIX VoiceQuery_* CONSTANT TRIPLES")
    # each: lda XIX,0x00D815 (F2 15 D8 00 34) ; ld (XIX),tag (B4 00 tt)
    # and somewhere a `ld (XIX+0x03),imm16` (BC 03 02 lo hi)
    q = []
    a = LO
    while a < HI:
        i = ROM.find(b"\xf2\x15\xd8\x00\x34", a - BASE, HI - BASE)
        if i < 0:
            break
        addr = BASE + i
        tag = at(addr + 5, 3)
        mask = None
        for j in range(addr, addr + 0x40):
            if at(j, 3) == b"\xbc\x03\x02":
                mask = struct.unpack("<H", at(j + 3, 2))[0]
                break
            if at(j, 3) == b"\xbc\x03\x00":
                mask = at(j + 3, 1)[0]
                break
        q.append((addr, tag[2] if tag[0] == 0xB4 else None, mask))
        a = addr + 5
    # the tag-less form (VoiceQuery_Tag00_All writes the record with a direct store)
    direct = find_all(b"\xf2\x15\xd8\x00\x00\x00")
    for addr in direct:
        if LO <= addr < HI:
            mask = None
            for j in range(addr, addr + 0x30):
                if at(j, 3) == b"\xbc\x03\x02":
                    mask = struct.unpack("<H", at(j + 3, 2))[0]
                    break
            q.append((addr, 0x00, mask))
    q.sort()
    for addr, tag, mask in q:
        print("        0x%06X  tag 0x%02X  mask 0x%04X" % (addr, tag, mask))
    check(len(q) == 6, "exactly six routines in the block build the 0x00D815 record")
    check([t for _, t, _ in q] == [0x80, 0x80, 0x40, 0x00, 0x00, 0x00],
          "their tag bytes, in address order: 80 80 40 00 00 00")
    check([m for _, _, m in q] == [0x0000, 0x007F, 0x007F, 0x007F, 0x00FF, 0x1FFF],
          "their +3 masks, in address order: 0000 007F 007F 007F 00FF 1FFF")

    print()
    print("5  THE VOICE RECORD")
    n44 = len(find_all(b"\x23\x44"))            # ld C,0x44
    check(at(0xFB0AD6, 2) == b"\x23\x44" and at(0xFB3EA8, 2) == b"\x21\x44",
          "stride 0x44 = 68 bytes (`ld C,0x44` at 0xFB0AD6, `ld A,0x44` at 0xFB3EA8)")
    check(at(0xFB0ADD, 3) == b"\x30\xcf\x3b" and at(0xFB3E9A, 3) == b"\x34\xcf\x3b",
          "base 0x00003BCF (`ld WA,0x3bcf` at 0xFB0ADD, `ld IX,0x3bcf` at 0xFB3E9A)")
    check(at(0xFB3EA2, 3) == b"\xce\xcf\x40" and at(0xFB3FDE, 3) == b"\xce\xcf\x40",
          "bound 0x40 = 64 voices (`cp H,0x40` at 0xFB3EA2 and 0xFB3FDE)")
    # ⚠ THE LAST-ENTRY TEST.  Until 2026-08-25 this was a bare `print` of
    # "0x00003BCF-0x0000456E" -- the one number in this section the 64 checks did
    # not cover, and it was wrong by 1,888 bytes.  Base, stride and count are now
    # read out of the ROM operands checked immediately above, and the extent is
    # asserted on record 63, the LAST one the `cp H,0x40` bound admits.
    base = int.from_bytes(at(0xFB3E9A + 1, 2), "little")   # ld IX,0x3bcf
    stride = at(0xFB3EA8 + 1, 1)[0]                        # ld A,0x44
    count = at(0xFB3EA2 + 2, 1)[0]                         # cp H,0x40
    check((base, stride, count) == (0x3BCF, 0x44, 0x40),
          "base/stride/count read from the ROM operands: 0x%04X / 0x%02X / %d"
          % (base, stride, count))
    last = base + (count - 1) * stride
    check(last == 0x4C8B and last + stride - 1 == 0x4CCE,
          "record %d -- the LAST -- occupies 0x%06X-0x%06X" % (count - 1, last, last + stride - 1))
    check(base + count * stride - 1 == 0x4CCE and count * stride == 4352,
          "the table is %d * 0x%02X = %d bytes, 0x%06X-0x%06X"
          % (count, stride, count * stride, base, base + count * stride - 1))
    check(0x3BCF + 64 * 0x44 - 1 != 0x456E,
          "...and NOT 0x0000456E, the end address this section printed unchecked "
          "until 2026-08-25 (1,888 bytes short)")

    print()
    print("6  THE PART RECORD")
    check(at(0xFB386C, 4) == b"\xd9\x08\x2c\x01",
          "stride 0x012C = 300 bytes (`mul BC,0x012c` at 0xFB386C)")
    check(at(0xFB3872, 5) == b"\xe3\xe5\x23\x15\x20",
          "the pointer array is at 0x00001523 (`ld XWA,(XBC+0x1523)` at 0xFB3872)")
    check(at(0xFB3F41, 3) == b"\xcb\xcf\x21",
          "bound 0x21 = 33 parts (`cp C,0x21` at 0xFB3F41, MidiNote_Dispatch's guard)")

    print()
    print("7  THE EXPANSION BOARD")
    sig = b"WSA1 EXTBD\x00"
    hits = find_all(sig)
    print("        %s at %s" % (sig[:10].decode(),
                                " ".join("0x%06X" % h for h in hits)))
    check(0xFE129E in hits, '"WSA1 EXTBD" is at 0xFE129E -- the address'
                            " ExtBoard_ProbeAndInstallBases adds to its index")
    check(at(0xFB0573, 6) == b"\xe9\xc8\x9e\x12\xfe\x00",
          "the probe adds 0x00FE129E to the loop index (0xFB0573)")
    check(at(0xFB0588, 4) == b"\xdb\xcf\x0a\x00" and at(0xFB058E, 4) == b"\xdb\xcf\x0a\x00",
          "it compares TEN bytes -- len('WSA1 EXTBD') -- twice (0xFB0588, 0xFB058E)")
    bases = [struct.unpack("<I", at(a, 4))[0] for a in
             (0xFB051F, 0xFB052E, 0xFB0538, 0xFB0542, 0xFB054C, 0xFB0556, 0xFB0565)]
    print("        bases installed: " + " ".join("0x%06X" % b for b in bases))
    check(bases == [0x00F00000, 0x00E80000, 0x00E90000, 0x00EA0000,
                    0x00EB0000, 0x00010000, 0x00C00000],
          "the seven 32-bit literals, in order: F00000 E80000 E90000 EA0000"
          " EB0000 010000 C00000")

    print()
    print("9  THE SEVEN TABLES AT 0xFE1280-0xFE12B4")
    per = {}
    for a in range(0xFE1280, 0xFE12B5):
        n = len(find_all(struct.pack("<I", a)[:3]))
        if n:
            per[a] = n
    print("        cited bytes: " + " ".join("%04X:%d" % (a & 0xFFFF, n)
                                             for a, n in sorted(per.items())))
    check(sum(per.values()) == 41,
          "41 literal sites into the range (the old comment said twenty; found %d)"
          % sum(per.values()))
    masks = [per.get(0xFE12AD + k, 0) for k in range(4)]
    shifts = [per.get(0xFE12B1 + k, 0) for k in range(4)]
    print("        mask table sites %s   shift table sites %s" % (masks, shifts))
    check(masks == shifts == [5, 3, 2, 2],
          "0xFE12AD.. and 0xFE12B1.. are cited the SAME number of times, entry for"
          " entry -- 5/3/2/2 -- which is what makes them a PAIR")
    check(at(0xFE12AD, 4) == b"\x03\x0c\x30\xc0" and at(0xFE12B1, 4) == b"\x00\x02\x04\x06",
          "the four masks are the four 2-bit fields of a byte and the four shifts"
          " are 0/2/4/6")
    check(at(0xFE1280, 6) == bytes(1 << k for k in range(6)),
          "0xFE1280 holds 1<<0 .. 1<<5")
    check(at(0xFE1286, 4) == bytes(1 << (2 * k) for k in range(4)) and
          at(0xFE128A, 4) == bytes(1 << (2 * k + 1) for k in range(4)),
          "0xFE1286 holds the even bit positions and 0xFE128A the odd ones")
    check(at(0xFE129E, 11) == b"WSA1 EXTBD\x00",
          "0xFE129E holds \"WSA1 EXTBD\" and its NUL")
    hi = [at(0xFE128E + 2 * k + 1, 1)[0] for k in range(8)]
    lo = {at(0xFE128E + 2 * k, 1)[0] for k in range(8)}
    check(lo == {0x80} and hi == [0x60, 0x62, 0x64, 0x65, 0x67, 0x69, 0x6B, 0x6C],
          "0xFE128E is eight words, low byte 0x80 throughout, high bytes stepping"
          " 2 2 1 2 2 2 1")

    print()
    print("10  THE FOUR VoiceRegs_Stage_* CALL SETS")
    STAGE = [(0xFB0AD0, 0xFB0B95, "A"), (0xFB1EBD, 0xFB1FB1, "B"),
             (0xFB27EE, 0xFB289A, "C"), (0xFB2EB7, 0xFB2F74, "D")]
    sets = {}
    for lo_, hi_, tag in STAGE:
        tg = set()
        i = lo_ - BASE
        while i < hi_ - BASE - 3:
            if ROM[i] == 0x1D:
                t = struct.unpack("<I", ROM[i:i + 4])[0] >> 8
                if 0xF80000 <= t <= 0xFFFFFF:
                    tg.add(t)
                i += 4
            else:
                i += 1
        sets[tag] = tg
        print("        Stage_%s (0x%06X): %2d call target(s)" % (tag, lo_, len(tg)))
    for x in "ABCD":
        for y in "ABCD":
            if x < y:
                print("        %s n %s = %2d shared, %s-only %2d, %s-only %2d"
                      % (x, y, len(sets[x] & sets[y]), x, len(sets[x] - sets[y]),
                         y, len(sets[y] - sets[x])))
    WRITERS = {0xFB713A, 0xFB77EF}
    check(all(WRITERS <= sets[t] for t in "ABCD"),
          "all four call BOTH Dev10C_WriteAllChanRegs and Dev104_WriteAllChanRegs")
    check(len(sets["C"] & sets["D"]) > len(sets["C"] & sets["A"]) and
          len(sets["A"] & sets["B"]) > len(sets["A"] & sets["C"]),
          "they are TWO FAMILIES: A/B share more with each other than with C/D,"
          " and C/D likewise")
    print("        A-only vs B: " + " ".join("0x%06X" % t for t in sorted(sets["A"] - sets["B"])))
    print("        B-only vs A: " + " ".join("0x%06X" % t for t in sorted(sets["B"] - sets["A"])))
    print("        C-only vs D: " + " ".join("0x%06X" % t for t in sorted(sets["C"] - sets["D"])))
    print("        D-only vs C: " + " ".join("0x%06X" % t for t in sorted(sets["D"] - sets["C"])))

    print()
    print("10b MidiNote_OnByPartMode's ARM 0 IS A LOOP OVER AT MOST FOUR VOICES")
    check(at(0xFB3958, 5) == b"\xcb\x87\xcf\xdc\x77",
          "`add L,C` / `cp L,4` / `jrl C,...` at 0xFB3958 closes the loop -- FOUR"
          " is the bound, not a count of the staging calls")
    check(at(0xFB38E2, 6) == b"\x89\xe8\x26\xce\xcf\x40",
          "the body reads the next voice from (XIZ-0x18) and stops at `cp H,0x40`")
    check(at(0xFB3946, 2) == b"\x66\x05",
          "a `jr Z` at 0xFB3946 picks VoiceRegs_Stage_A over VoiceRegs_Stage_C")
    check(at(0xFB38FD, 5) == b"\x00\x00\x00\x00\x00",
          "the five `nop`s of bus padding between the two 0x0010C000 writes")

    print()
    print("11  THE FOUR ORPHAN / BIG-ROUTINE PAIRS")

    def call_targets(lo_, hi_):
        tg, i = set(), lo_ - BASE
        while i < hi_ - BASE - 3:
            if ROM[i] == 0x1D:
                t = struct.unpack("<I", ROM[i:i + 4])[0] >> 8
                if 0xF80000 <= t <= 0xFFFFFF:
                    tg.add(t)
                i += 4
            else:
                i += 1
        return tg

    PAIRS = [(0xFB0B95, 0xFB0E4F, 0xFB1EBD, "A"), (0xFB1FB1, 0xFB2172, 0xFB27EE, "B"),
             (0xFB289A, 0xFB2A98, 0xFB2EB7, "C"), (0xFB2F74, 0xFB31AB, 0xFB3634, "D")]
    extras = []
    for o, g, gend, tag in PAIRS:
        so, sg = call_targets(o, g), call_targets(g, gend)
        print("        %s  orphan 0x%06X %2d target(s)  big 0x%06X %2d  "
              "orphan-not-in-big %d  big-only %s"
              % (tag, o, len(so), g, len(sg), len(so - sg),
                 " ".join("0x%06X" % t for t in sorted(sg - so))))
        check(not (so - sg),
              "%s: every `call` target of the orphan is also a target of the big"
              " routine that follows it" % tag)
        extras.append(frozenset(sg - so))
    common = set.intersection(*[set(e) for e in extras])
    check(common == {0xF9A038, 0xFA6BB5, 0xFC376C},
          "and all four big routines add the SAME three callees the orphans lack:"
          " MemCopyWords 0xF9A038, 0xFA6BB5 and 0xFC376C")

    print()
    print("12  MidiNote_OnTail vs MidiNote_OffTail")
    a_ = at(0xFB3634, 0xFB374A - 0xFB3634)
    b_ = at(0xFB374A, 0xFB3860 - 0xFB374A)
    diff = sum(1 for x, y in zip(a_, b_) if x != y)
    print("        both %d bytes; %d of them differ" % (len(a_), diff))
    check(len(a_) == len(b_) == 278, "both are 278 bytes")
    check(a_ != b_ and diff == 205,
          "they are NOT byte-identical -- 205 of the 278 bytes differ, so 'twin'"
          " means same length and same call shape, never same code")

    print()
    print("13  THE 32 HEADERS TILE THE BLOCK  (reads prom_c/wsa1_prom_c.s)")
    src = open(image_path(ROOT, "prom_c/wsa1_prom_c.s"), encoding="utf-8").read()
    import re as _re
    hdr = _re.compile(r'^; (?:★+ )?([A-Za-z_][A-Za-z0-9_]*) -- '
                      r'(0x[0-9A-F]{6})\.\.(0x[0-9A-F]{6}) \((\d+) bytes\)', _re.M)
    rows = [(m.group(1), int(m.group(2), 16), int(m.group(3), 16), int(m.group(4)))
            for m in hdr.finditer(src)]
    rows = [r for r in rows if LO <= r[1] < HI]
    rows.sort(key=lambda r: r[1])
    print("        %d sized header(s) inside the block" % len(rows))
    check(len(rows) == len(ROUTINES),
          "one sized header per routine (%d of %d)" % (len(rows), len(ROUTINES)))
    check(all(b - a + 1 == n for _, a, b, n in rows),
          "every header's byte count equals its own stated extent")
    check([a for _, a, _, _ in rows] == [a for a, _ in ROUTINES],
          "the headers' start addresses are exactly the 32 routine starts")
    check(all(("\n%s:\n" % nm) in src for nm, _, _, _ in rows),
          "every header's name appears as a label in the source")
    gaps = [(rows[i][0], rows[i][2], rows[i + 1][1])
            for i in range(len(rows) - 1) if rows[i][2] + 1 != rows[i + 1][1]]
    check(not gaps and rows[0][1] == LO and rows[-1][2] == HI - 1,
          "they TILE 0x%06X-0x%06X with no gap and no overlap" % (LO, HI - 1))

    if selftest:
        print()
        print("SELFTEST -- the LAST element of every table, not the first")
        check(arms[-1] == 0x00F0, "last status arm is 0xF0")
        check(q[-1][1] == 0x00 and q[-1][2] == 0x1FFF,
              "last VoiceQuery (0x%06X) is tag 0x00 / mask 0x1FFF" % q[-1][0])
        check(msgs[-1] == [0xB0, 0x00, 0x78, 0x7F],
              "last boot message is All Sound Off")
        check(ROUTINES[-1][0] == 0xFB3FA0 and refs(0xFB3FA0)[0] == [0xFAC373],
              "last routine 0xFB3FA0 has exactly one `call` site, 0xFAC373")
        # negative control: an address that is NOT a routine start must not census clean
        c, r, j, p, o = refs(0xFB3FA1)
        check(len(c) + len(r) + len(j) + len(p) == 0,
              "negative control: 0xFB3FA1 (one byte into the last routine) has no"
              " control-transfer reference")
        check(per.get(0xFE12B4) == 2 and at(0xFE12B4, 1) == b"\x06",
              "last byte of the shift table (0xFE12B4) is 6 and is cited twice")
        check(0xFE12B5 not in per,
              "negative control: 0xFE12B5 -- the first byte PAST the range, and the"
              " start of Dev10C_GlobalRegs_ResetImage -- is not part of these tables"
              " (it has its own citation elsewhere in the file, not inside them)")

    print()
    if fails:
        print("FAILED %d check(s)" % len(fails))
        for f in fails:
            print("  - " + f)
        return 1
    print("ALL CHECKS PASS")
    return 0


sys.exit(main())
