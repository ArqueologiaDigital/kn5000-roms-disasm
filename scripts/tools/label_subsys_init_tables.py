#!/usr/bin/env python3
"""label_subsys_init_tables.py -- the subsystem init-phase tables and two pointer runs spelled as data (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  Subsys_HandlerTableList holds 19 tables of 4 routine pointers, one table per subsystem.  ScreenGroup_Dispatch
  (WA = slot) calls slot WA of every table in list order.  The boot code
  (kn5000_v<N>_program.s, after SubCPU_Send_Payload) calls it with:
    slot 0 -- right after the Sub-CPU payload transfer (the dispatcher also runs ScreenGroup_InitState before
              and ScreenGroup_ReInit after);
    slot 1 -- if SubCPU_Payload_GetErrorFlag is 0, or slot 2 if it is not;
    slot 3 -- once (1024) = 6.
  The audio table reads Audio_InitAllDefaults | Audio_ReinitToneGenAndOutput | Audio_ResetAfterPayloadError |
  Audio_FullReinitWithPreset, which agrees with that.  Four of the list entries had no label at their target, and
  were spelled `Label + N`:
    [14] AccompSeq_ResetToFactoryBanks ... (already four `.long`s)            -> AccompSeq_InitFuncTable
    [15] AccTone_StubReturn_B, _A, AccDemo_InitDone, AccPatch_InitAndCountSlots, decoded as 16 bytes of nonsense
         instructions (`push_f; cp xiy, xbc; nop; ldf 233 ...`)               -> AccPatch_InitFuncTable, 4 .long
    [16] SoundRam_HandlerTable (labelled; the entry still said `Subsys_HandlerTable01 + 82`)
    [17] FDemoText_StubReturn_A ... FDemoText_RescanAllVoices (an .incbin slice) -> FDemoText_InitFuncTable
  (the name follows Seq_InitFuncTable, entry [0]).  Two pointer runs held as `.byte` are spelled `.long` too:
    WidgetDispatch_FDTestPtrTable (list entry [2]: LoadXaprInit_Entry, HamaStub1..3_Entry);
    AccPlayMode_Dispatch_Execute_Data, the 8 handlers AccPlayMode_Dispatch calls by the running-state mask
      (bit 2 of RAM 1054 -> 4, of SEQ_TRANSPORT_STATE -> 8, of RAM 1056 -> 16).  Mask 0's handler is the `ret` just
      after the table (`0e 00 00` = ret; nop; nop): AccPlayMode_OnMask0_Nop.  Masks 3 and 4 had no label:
      AccPlayMode_OnMask3 / AccPlayMode_OnMask4.
  Everything is located per tree from that tree's own ROM and ELF (list position, the reader's operand); the bytes
  cannot change and `make gate-all` checks it.

RUN (repository root; built tree; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_subsys_init_tables.py [--apply]
"""
import collections
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
LIST_NAMES = {14: "AccompSeq_InitFuncTable", 15: "AccPatch_InitFuncTable", 17: "FDemoText_InitFuncTable"}
HEADER_OLD = "; NULL-terminated list of 19 handler tables (19 x u32 + 0).  VoiceInit_Dispatch"
HEADER_ADD = [
    "; The four slots are init phases (scripts/tools/label_subsys_init_tables.py): the boot code calls",
    "; ScreenGroup_Dispatch with WA = 0 after the Sub-CPU payload transfer, then 1 if SubCPU_Payload_GetErrorFlag",
    "; is 0 or 2 if not, then 3 -- the audio table reads Audio_InitAllDefaults | Audio_ReinitToneGenAndOutput |",
    "; Audio_ResetAfterPayloadError | Audio_FullReinitWithPreset.",
]


def syms(tree):
    out = subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % tree)],
                         capture_output=True, text=True, check=True).stdout
    at, by = collections.defaultdict(list), {}
    for line in out.splitlines():
        f = line.split()
        if len(f) == 3 and f[1] in "tT":
            at[int(f[0], 16)].append(f[2])
            by.setdefault(f[2], int(f[0], 16))
    return at, by


def main():
    for tree in ("v10", "v9", "v7"):
        root = os.path.join(REPO, tree, "maincpu")
        m = census.load(tree)
        at, by = syms(tree)
        word = lambda a: census.le(m, a, 4)
        newlab = {}                                 # address -> name (labels to create)
        rows_replace = {}                           # (file, first line) -> (n lines, new lines)
        respell = {}                                # (file, line) -> new text

        def name_of(a):
            return newlab.get(a) or (at[a][0] if at.get(a) else None)

        def longs(base, n):
            out = []
            for k in range(n):
                v = word(base + 4 * k)
                nm = name_of(v)
                assert nm, (tree, hex(base), k, hex(v))
                out.append("\t.long\t" + nm)
            return out

        def rows_tiling(lo, hi):
            r = census.find(m, lo)
            assert r and r[0] == lo, (tree, hex(lo))
            k = m["los"].index(lo)
            rows = []
            while m["rows"][k][0] < hi:
                rows.append(m["rows"][k])
                k += 1
            assert rows[-1][1] == hi and len({x[2] for x in rows}) == 1, (tree, hex(lo), hex(hi))
            assert rows[-1][3] - rows[0][3] + 1 == len(rows), (tree, hex(lo), "rows not consecutive")
            return rows

        lst = by["Subsys_HandlerTableList"]
        # the AccPlayMode run: its own labels first, so the list and run entries can use them
        ap = by["AccPlayMode_Dispatch_Execute_Data"]
        tail = ap + 32
        assert m["raw"][tail - m["base"]:tail - m["base"] + 3] == b"\x0e\x00\x00", tree
        newlab[tail] = "AccPlayMode_OnMask0_Nop"
        for k, nm in ((3, "AccPlayMode_OnMask3"), (4, "AccPlayMode_OnMask4")):
            v = word(ap + 4 * k)
            if not at.get(v):
                newlab[v] = nm
        for idx, nm in LIST_NAMES.items():
            t = word(lst + 4 * idx)
            if not at.get(t):
                newlab[t] = nm
        # the list's entries 14..17
        for idx in (14, 15, 16, 17):
            r = census.find(m, lst + 4 * idx)
            assert r[0] == lst + 4 * idx and r[5] == ".long", (tree, idx)
            respell[(r[2], r[3])] = "\t.long\t" + name_of(word(lst + 4 * idx))
        # [15]: instructions -> four .long; [2]: .byte -> four .long; AccPlayMode: .byte -> 8 .long + ret; nop; nop
        t15 = word(lst + 4 * 15)
        rows = rows_tiling(t15, t15 + 16)
        assert all(census.is_insn_row(tree, x) or x[5] == ".byte" for x in rows), tree
        rows_replace[(rows[0][2], rows[0][3])] = (len(rows), [LIST_NAMES[15] + ":"] + longs(t15, 4))
        t2 = word(lst + 4 * 2)
        rows = rows_tiling(t2, t2 + 16)
        if not all(x[5] == ".long" for x in rows):        # v7 already spells it as four .long
            assert all(x[5] == ".byte" for x in rows), tree
            rows_replace[(rows[0][2], rows[0][3])] = (len(rows), longs(t2, 4))   # its label line stays above
        rows = rows_tiling(ap, tail + 3)
        assert all(x[5] == ".byte" for x in rows) and rows[0][7] == "AccPlayMode_Dispatch_Execute_Data", tree
        rows_replace[(rows[0][2], rows[0][3])] = (len(rows), ["AccPlayMode_Dispatch_Execute_Data:"] + longs(ap, 8)
                                                  + ["AccPlayMode_OnMask0_Nop:", "\tret", "\tnop", "\tnop"])
        # plain label lines for the other new labels (an instruction, a .long or an .incbin starts there)
        inserts = collections.defaultdict(list)
        for a, nm in newlab.items():
            if a in (t15, tail):
                continue
            r = census.find(m, a)
            assert r and r[0] == a, (tree, nm, hex(a))
            inserts[(r[2], r[3])].append(nm + ":")
        print("%s: %s" % (tree, ", ".join("%s 0x%06X" % (n, a) for a, n in sorted(newlab.items()))))
        if not APPLY:
            continue
        files = {k[0] for k in list(rows_replace) + list(respell) + list(inserts)} | {"ui_widgets/widget_dispatch.s"}
        for rel in files:
            p = os.path.join(root, rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            out, i = [], 0
            while i < len(L):
                out.extend(inserts.get((rel, i), []))
                if (rel, i) in rows_replace:
                    n, new = rows_replace[(rel, i)]
                    out.extend(new)
                    i += n
                    continue
                line = respell.get((rel, i), L[i])
                if line == HEADER_OLD:
                    out.extend(HEADER_ADD)
                out.append(line)
                i += 1
            data = "\n".join(out).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
