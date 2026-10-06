#!/usr/bin/env python3
"""label_seq_timer_handlers.py -- name the three unlabelled targets of SeqStep_TimerDispatch_ProcTables (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  SeqStep_TimerDispatchA/B/C (sequencer/seq_step_routines.s) jump through SeqStep_TimerDispatch_ProcTables[0..2]
  indexed by the sequencer state at RAM 0x22FC (0..22).  Three of the targets had no label -- they start inside
  SeqPlay_StopAndClearSequence_Join2's run of code in sequencer/sequencer_engine.s -- and the C table
  (ui_widgets/naka_widget_descriptors.c) spelled them as numbers.  The dispatch census's stride-8 U detector
  reported the table (dispatch-census-2026-10-06-11).  Read from the code:
    v10 0xF438D2  SeqPlay_CountInToLastBar  bit 2 of RAM 0x28B2 set, the measure counter (RAM 0x2668, sign-
                  magnitude: 0x8002 = -2, 0x8001 = -1) at -2 and RAM 0x434 >= 1: counter = -1, then
                  NoteEditSy_SendModeScrollReset
    v10 0xF438F5  SeqPlay_AdvanceMeasure    once a bar of beats has passed since RAM 0x2330 (SEQ_BEAT_COUNT -
                  0x2330 >= 0x2332): counter + 1, at most 999, re-arm 0x2330/0x2332 (SeqPlay_BufferUpdateBlock
                  is the looping variant)
    v10 0xF43931  SeqPlay_CountInEnd        bit 1 of 0x28B2 set, counter at -1, the last beat of the bar (RAM
                  0x433 - 1 == 0x416) and tick 0x415 >= 72: clear bit 3 of 0x28B3 and step the sequencer state
                  8 -> 9, 12 -> 13, 16 -> 17, 20 -> 21 (the count-in states and the states they lead to)
  and SeqStep_PlaybackMaxPart, the table's most common entry, is a bare `ret` -> SeqStep_TimerNop (renamed by
  scripts/renaming/rename_seq_timer_nop.sed first).
  Per tree (each tree's own addresses, by table position against v10): a label line before each target's
  instruction in sequencer_engine.s (census map), the C words as NAKA_ADDR(name), the symbols added to that
  tree's naka_widget_descriptors_link.ld.  Then: regenerate_v7_c_divergence.py --apply; make all; gate.

RUN (repository root; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_seq_timer_handlers.py [--apply]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

TABLE, N = 0x140A0, 3 * 23
NAMES = {0xF438D2: "SeqPlay_CountInToLastBar", 0xF438F5: "SeqPlay_AdvanceMeasure", 0xF43931: "SeqPlay_CountInEnd"}
HEADERS = {
    "SeqPlay_CountInToLastBar": "; SeqStep_TimerDispatch_ProcTables target: count-in measure -2 -> -1 (RAM 0x2668, sign-magnitude)",
    "SeqPlay_AdvanceMeasure": "; SeqStep_TimerDispatch_ProcTables target: measure counter + 1 per bar of beats, at most 999",
    "SeqPlay_CountInEnd": "; SeqStep_TimerDispatch_ProcTables target: the count-in ends -- sequencer state 8/12/16/20 -> + 1",
}


def words(tree):
    b = open(os.path.join(REPO, tree, "maincpu/includes/generated/naka_widget_descriptors.bin"), "rb").read()
    return [int.from_bytes(b[TABLE + 4 * i:TABLE + 4 * i + 4], "little") for i in range(N)]


def main():
    ref = words("v10")
    for tree in ("v10", "v9", "v7"):
        w = words(tree)
        addr = {}
        for x, y in zip(w, ref):
            if y in NAMES:
                assert addr.setdefault(NAMES[y], x) == x, (tree, NAMES[y])
        m = census.load(tree)
        edits = {}
        for nm, a in addr.items():
            r = census.find(m, a)
            assert r and r[0] == a and r[4] == "code" and not r[7], (tree, nm, hex(a), r and r[:8])
            edits.setdefault(r[2], []).append((r[3], nm))
        print(tree, ", ".join("%s 0x%06X" % (n, a) for n, a in sorted(addr.items(), key=lambda t: t[1])))
        if not APPLY:
            continue
        for rel, ops in edits.items():
            p = os.path.join(REPO, tree, "maincpu", rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for li, nm in sorted(ops, reverse=True):
                L[li:li] = [HEADERS[nm], nm + ":"]
            data = "\n".join(L).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
        c = os.path.join(REPO, tree, "maincpu/ui_widgets/naka_widget_descriptors.c")
        s = open(c, "rb").read().decode("latin-1")
        for v10a, nm in NAMES.items():
            lit = "0x%08X," % v10a
            assert s.count(lit) >= 1, (tree, lit)
            s = s.replace(lit, "NAKA_ADDR(%s)," % nm)
        k = s.index("\nextern const char ") + 1
        s = s[:k] + "".join("extern const char %s;\n" % nm for nm in sorted(NAMES.values())) + s[k:]
        data = s.encode("latin-1")
        open(c + ".tmp", "wb").write(data)
        os.replace(c + ".tmp", c)
        ld = os.path.join(REPO, tree, "maincpu/ui_widgets/naka_widget_descriptors_link.ld")
        t = open(ld, "rb").read().decode("latin-1").rstrip("\n") + "\n"
        t += "".join("%s = 0x%08X;\n" % (nm, a) for nm, a in sorted(addr.items()))
        data = t.encode("latin-1")
        open(ld + ".tmp", "wb").write(data)
        os.replace(ld + ".tmp", ld)


if __name__ == "__main__":
    main()
