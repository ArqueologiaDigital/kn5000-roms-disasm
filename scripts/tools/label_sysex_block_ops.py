#!/usr/bin/env python3
"""label_sysex_block_ops.py -- label the seven stubs MidiSysEx_BlockHandlers points at (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  MidiSysEx_ProcessBlock_Helper11 (midi/midi_dispatch_handlers.s) reads byte +3 of the spare MIDI-sequence buffer
  (MIDISEQ_SPARE_BUF_PTR), returns when it is >= 22, and calls MidiSysEx_BlockHandlers[byte].  The 22 entries were
  spelled `MidiSysEx_ProcessBlock_Helper11 + N` with "no label at this target yet", so the dispatch census counted the
  table as not used.  The targets are seven one-instruction stubs right after the routine's own `ret`:
      +30  ret                                    entry  0
      +31  jp SeqChan_UnhandledCmd_Join           entries 1-3    (MidiMsg_ParseChannelStream, SeqTimer_UpdateTempoReg)
      +35  jp SeqChan_UnhandledCmd_Join2          entries 4-6    (SendPartDataBlock_DoGetError, MIDI_PitchBendData_Block)
      +39  jp SeqChan_UnhandledCmd_Join3          entries 7-10   (AccDemo_InitDone)
      +43  jp SeqChan_UnhandledCmd_Join4          entries 11-14  (`call (xhl)`)
      +47  ret                                    entries 15-17
      +48  jp SeqChan_UnhandledCmd_Join5          entries 18-21  (Voice_InitBankDataSafe)
  Each stub gets a label naming where it goes (MidiSysEx_BlockOp_Ret, _ToParseStream, _ToPartDataAndBend,
  _ToAccDemoInit, _ToCallHandler, _Ret2, _ToVoiceBankInit).  The asm `.long` entries are spelled with them, and
  the table's comment drops "no label at this target yet".  What the index byte means is still unknown; the names
  claim only the destination.  Per tree, the offsets and each stub's instruction are asserted from the census map.

RUN (repository root; built tree; census maps: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_sysex_block_ops.py [--apply]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

STUBS = {30: ("MidiSysEx_BlockOp_Ret", r"^ret$"),
         31: ("MidiSysEx_BlockOp_ToParseStream", r"^jp\s+SeqChan_UnhandledCmd_Join$"),
         35: ("MidiSysEx_BlockOp_ToPartDataAndBend", r"^jp\s+SeqChan_UnhandledCmd_Join2$"),
         39: ("MidiSysEx_BlockOp_ToAccDemoInit", r"^jp\s+SeqChan_UnhandledCmd_Join3$"),
         43: ("MidiSysEx_BlockOp_ToCallHandler", r"^jp\s+SeqChan_UnhandledCmd_Join4$"),
         47: ("MidiSysEx_BlockOp_Ret2", r"^ret$"),
         48: ("MidiSysEx_BlockOp_ToVoiceBankInit", r"^jp\s+SeqChan_UnhandledCmd_Join5$")}


def main():
    for tree in ("v10", "v9", "v7"):
        m = census.load(tree)
        h = m["byname"]["MidiSysEx_ProcessBlock_Helper11"]
        edits = {}
        for off, (name, rx) in STUBS.items():
            r = census.find(m, h + off)
            assert r and r[0] == h + off and census.is_insn_row(tree, r), (tree, off)
            assert re.match(rx, r[6].split(";")[0].strip()), (tree, off, r[6])
            if not r[7]:
                edits.setdefault(r[2], []).append((r[3], name + ":"))
        p = os.path.join(REPO, tree, "maincpu/ui_widgets/widget_dispatch.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        k = L.index("MidiSysEx_BlockHandlers:")
        n = 0
        for i in range(k + 1, k + 23):
            mm = re.match(r'^\t\.long MidiSysEx_ProcessBlock_Helper11 \+ (\d+)\t; no label at this target yet$', L[i])
            if mm:
                L[i] = "\t.long %s" % STUBS[int(mm.group(1))][0]
                n += 1
        note = ("; Index: byte +3 of the spare MIDI-sequence buffer (MIDISEQ_SPARE_BUF_PTR), 0..21; each stub is labelled"
                " for its destination (scripts/tools/label_sysex_block_ops.py).")
        if n and note not in L[k - 3:k]:
            j = next(i for i in range(k - 1, k - 6, -1) if L[i].startswith("; 22 x u32 routine pointers"))
            L[j + 1:j + 1] = [note]
        print("%s: %d stub labels to place, %d table entries spelled" % (tree, sum(len(v) for v in edits.values()), n))
        if not APPLY:
            continue
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
        for rel, ops in edits.items():
            q = os.path.join(REPO, tree, "maincpu", rel)
            Q = open(q, "rb").read().decode("latin-1").split("\n")
            for li, lab in sorted(ops, reverse=True):
                Q[li:li] = [lab]
            data = "\n".join(Q).encode("latin-1")
            open(q + ".tmp", "wb").write(data)
            os.replace(q + ".tmp", q)


if __name__ == "__main__":
    main()
