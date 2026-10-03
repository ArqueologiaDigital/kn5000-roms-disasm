#!/usr/bin/env python3
"""Name the routines of prom_b's four SMF-writer copies (FINDINGS-prom_b-smf-writer.md: "every routine
in the 4,186 converted bytes is sub_XXXXXX.  Semantic naming is deferred").

QUESTION IT ANSWERS
  The findings name four copies of one Standard MIDI File writer by their 99-byte templates:
  A = SmfFileTemplate_F7493F, B = _F760BF, C = _F768F0, D = _F77836, and leave open "what
  distinguishes the three live writer modules".  Reading their byte-commit routines answers it:
    * A is Smf_WriteFile's own pass.  Its byte-commit (0xF74B3A) stores the output cursor and, when
      the 1,024-byte window 0x60A700-0x60AAFF is full, WRITES it: the first window through
      0xF765E6 (which computes the file size from SmfOut_TrackLength + 22 before its disk calls),
      later ones through 0xF76661 (Disk_Flags bit 1, T_F425AC), the disk status landing in (0x1238).
    * B is SmfSize_Pass, which Smf_WriteFile calls (0xF739CE) BEFORE A writes the header.  Its
      byte-commit (0xF762BD) only wraps the cursor and counts the window in SmfOut_WindowsFlushed --
      it writes nothing -- and B is the copy that computes SmfOut_TrackLength (0xF76123:
      windows*1024 + cursor - 0x60A700 - 22, stored most significant byte first).  So B is a SIZING
      pass: it produces the MTrk length that A's header then carries (the findings' "copy A ...
      writes (0x10C4) and (0x10C6) into the file").
    * C and D have no caller anywhere (the findings: the fourth template is referenced by nothing;
      D's entry SmfSizeCopy_Pass has no call site).  By identical masked instruction sequences C is a copy
      of A's helpers and D of B's -- the findings' two pairs {F7493F, F768F0} and {F760BF, F77836}.
  Prefixes: SmfWrite_ (A), SmfSize_ (B), SmfWriteCopy_ (C), SmfSizeCopy_ (D).
  Roles, each read from the body (one reading per role, the copies being identical up to literals):
    EncodeVlq          the SMF variable-length quantity of the 21-bit value at (0x11AA..0x11AC) into
                       (0x1193..0x1195), 7 bits a byte, bit 7 = more, clamped to 0x1FFFFF (KN5000's
                       twin is SMF_EncodeTimeDelta, 54 of 54 instructions)
    EncodeDeltaTime    (0x11AA) = (0x107E) + C - (0x1082), the tick difference from the previous
                       event; C becomes the previous (0x1082); then EncodeVlq
    WriteChannelEvent  the VLQ bytes, then status A, data W and -- unless the status is 0xC0 or 0xD0,
                       one data byte -- data L, each through CommitOutputByte
    WriteControlChange status 0xB0 | ((0x119A) & 0x0F), then WriteChannelEvent
    CommitOutputByte   (see above: A and C write a full window to disk, B and D only count it)
    AgePendingNoteOffs the 33 five-byte records at 0x305A whose bit 7 is set: subtract the elapsed
                       delta (0x11AA) from each one's time word (+3); the ones that come due go to the
                       due list at 0x10D3 (three bytes each); then SortDueNoteOffs
    SortDueNoteOffs    exchange-sorts the due list by its time word, then WriteDueNoteOffs
    WriteDueNoteOffs   walks the sorted due list: delta, then the record's +1 word as status and key
                       with data L = 0 -- a note-on of velocity 0, the SMF note-off -- through
                       WriteChannelEvent, and clears the record's two flag bits (and 0x3F)
    ClearDueList       96 bytes of 0xFF at 0x10D3
    ClearEventFields   zeroes the four words 0x1198-0x119F ((0x119A) is the channel WriteControlChange uses)
    ClearPendingNoteOffs  zeroes 256 words from 0x305A (the note-off records and what follows)
    StageTempoFromBpm  SmfOut_Tempo = 600000 / HL * 100 = 60,000,000 / HL: microseconds per quarter
    StageTempo         SmfOut_Tempo = ceil(HL*100000/24000) * 1000 (B/D's formula; what HL is is not read here)
    WriteTempoEvent    the VLQ delta, then FF 51 03 and SmfOut_Tempo most significant byte first
    StoreTrackLength   (see above)
    ReadSongByte       A = the byte at the block-store cursor (BStore_CursorBlock/_Offset)
    AdvanceSongCursor  the block-store cursor + 1; at offset 255 it follows the block's +3 link to the
                       next block, offset 5
    Save/RestoreFileName  the 8 name bytes Disk_FileName <-> RAM 0x123A
  KN5000 names were NOT copied: its twin of WriteDueNoteOffs is called SMF_UpdateTempo, of
  StoreTrackLength SMF_CalcFilePosition (notes/kn5000_twin_routines.py).
  Each run re-checks, in the source, the call chain every role relies on (CHECKS) and that each
  old label still exists.

RUN
  python3 notes/prom_b_smf_writer_names.py          # the plan and the checks
  python3 notes/prom_b_smf_writer_names.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
PREFIX = {"A": "SmfWrite", "B": "SmfSize", "C": "SmfWriteCopy", "D": "SmfSizeCopy"}
# role -> {copy: address}
ROLES = collections.OrderedDict([
    ("EncodeVlq",            {"A": 0xF74D99, "B": 0xF7647A, "C": 0xF76D38, "D": 0xF77BDF}),
    ("EncodeDeltaTime",      {"A": 0xF74A74, "B": 0xF76219, "C": 0xF76A25, "D": 0xF77990}),
    ("WriteChannelEvent",    {"A": 0xF74AC5, "B": 0xF7626A, "C": 0xF76A6A, "D": 0xF779D5}),
    ("WriteControlChange",   {"A": 0xF74A66, "B": 0xF7620B, "D": 0xF77982}),
    ("CommitOutputByte",     {"A": 0xF74B3A, "B": 0xF762BD, "C": 0xF76ADF, "D": 0xF77A28}),
    ("AgePendingNoteOffs",   {"A": 0xF74BF6, "B": 0xF762DF, "C": 0xF76B9B, "D": 0xF77A4A}),
    ("SortDueNoteOffs",      {"A": 0xF74C87, "B": 0xF7636C, "C": 0xF76C2C, "D": 0xF77AD7}),
    ("WriteDueNoteOffs",     {"A": 0xF74CF2, "B": 0xF763D7, "C": 0xF76C97, "D": 0xF77B42}),
    ("ClearDueList",         {"A": 0xF74E4C, "B": 0xF7652D, "C": 0xF76DEB, "D": 0xF77C92}),
    ("ClearEventFields",     {"A": 0xF74E60, "B": 0xF76541, "D": 0xF77CA6}),
    ("ClearPendingNoteOffs", {"A": 0xF74EAE}),
    ("StageTempoFromBpm",    {"A": 0xF749A2, "C": 0xF76953}),
    ("StageTempo",           {"B": 0xF7615B, "D": 0xF778D2}),
    ("WriteTempoEvent",      {"B": 0xF761A1, "D": 0xF77918}),
    ("StoreTrackLength",     {"B": 0xF76123, "D": 0xF7789A}),
    ("ReadSongByte",         {"B": 0xF76552, "D": 0xF77CB7}),
    ("AdvanceSongCursor",    {"A": 0xF74E86, "B": 0xF76567, "D": 0xF77CCC}),
    ("SaveFileName",         {"A": 0xF7492F, "B": 0xF768E0}),
    ("RestoreFileName",      {"A": 0xF7491F, "B": 0xF768D0}),
    ("Pass",                 {"B": 0xF75685, "D": 0xF76E74}),
])
# (caller role, callee role): the call each copy's caller must make to that copy's callee
CHECKS = [("EncodeDeltaTime", "EncodeVlq"), ("WriteControlChange", "WriteChannelEvent"),
          ("WriteChannelEvent", "CommitOutputByte"), ("AgePendingNoteOffs", "SortDueNoteOffs"),
          ("SortDueNoteOffs", "WriteDueNoteOffs"), ("WriteDueNoteOffs", "WriteChannelEvent"),
          ("WriteDueNoteOffs", "EncodeVlq"), ("WriteTempoEvent", "CommitOutputByte")]
HDR = {
    "Pass": "the whole %s pass over the song (its main; see the module note)",
}


def body_calls(label):
    """call/calr/jp/jr targets of `label` through its local labels."""
    L = B.split("\n")
    i = [k for k, l in enumerate(L) if l.startswith(label + ":")][0]
    out = set()
    for l in L[i + 1:i + 600]:
        m = re.match(r'^([A-Za-z_][\w$]*):', l)
        if m and not re.search(r'_(Skip|Join|Loop|Return|Epilogue)\d*$', m.group(1)):
            break
        out.update(re.findall(r'\b(?:call|calr|jp|jr|jrl)\s+(?:\w+,\s*)?(\w+)', l.split(";")[0], re.I))
    return out


def plan():
    rows, bad = [], []
    labels = set(re.findall(r'^([A-Za-z_][\w$]*):', B, re.M))
    for role, cp in ROLES.items():
        for c, a in cp.items():
            old = "sub_%06X" % a
            new = "%s_%s" % (PREFIX[c], role)
            if new in labels:
                continue                                   # already applied
            if old not in labels:
                bad.append("%s: no label %s" % (new, old))
                continue
            rows.append((old, new, c, role))
    cur = {(c, role): ("sub_%06X" % a if "sub_%06X" % a in labels else "%s_%s" % (PREFIX[c], role))
           for role, cp in ROLES.items() for c, a in cp.items()}
    for r1, r2 in CHECKS:
        for c in "ABCD":
            if (c, r1) in cur and (c, r2) in cur and cur[(c, r2)] not in body_calls(cur[(c, r1)]):
                bad.append("copy %s: %s does not call %s" % (c, cur[(c, r1)], cur[(c, r2)]))
    return rows, bad


def main():
    rows, bad = plan()
    for o, n, c, role in rows:
        if "--args" in sys.argv:
            what = HDR.get(role, "the %s routine") % ("sizing" if c in "BD" else "writing")
            print("%s=%s|%s: copy %s of prom_b's SMF writer (%s), %s -- notes/prom_b_smf_writer_names.py" % (
                o, n, n, c, {"A": "Smf_WriteFile's writing pass", "B": "the sizing pass Smf_WriteFile runs first",
                             "C": "an unreferenced copy of A", "D": "an unreferenced copy of B"}[c],
                what if role == "Pass" else "role %s as its docstring reads it from the body" % role))
        else:
            print("%-11s -> %s" % (o, n))
    if "--args" not in sys.argv:
        for b in bad:
            print("CHECK FAILED", b)
        print("rename %d, failed checks %d" % (len(rows), len(bad)))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
