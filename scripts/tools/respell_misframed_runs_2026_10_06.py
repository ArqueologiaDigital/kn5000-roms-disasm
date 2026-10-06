#!/usr/bin/env python3
"""respell_misframed_runs_2026_10_06.py -- four places where code and data were framed wrongly (v10/v9/v7).

QUESTION IT ANSWERS
  The KN5000 helper-naming triage of 2026-10-06 (analysis/kn5000-naming/proposals-2026-10-06-helpers-{e,g}.json)
  found four places where the source frames the bytes wrongly:
    A. audio/note_voice_mapping.s, twice: `.byte 0x9f / ccf / push xsp / pushw wa / nop` is one instruction,
       `cpw (xsp+18), 40` (9f 12 3f 28 00).
    B. sequencer/accompaniment_engine.s, CmpStep_DataBlock: `.byte 0xc1, 0x37, 0x8d / push xsp / ld (xiz), xiz /
       pop_f` is `cp (PREVIOUS_TITLE:16), 182 / jr z, <the push before call CmpStep_DrawScreen>`.  The label is
       CmpStepTitleFunc_ProcTable[0]: TT_CMSTEP's paint method.  When the previous title was TT_CMSTEP (0xB6) the
       palette set-up is skipped.  The table's other three entries (0xF6A32C / 0xF6A339 / 0xF6A346 in v10) are the
       stubs after it.  DirmdEmulator calls method 1 on EVT_HIDE and method 2 on EVT_SW_IN; nothing calls method 3,
       a lone `ret`.  They get labels: CmpStepTitle_OnPaint / _OnHide / _OnSwitchIn / _Method3Nop.
    C. sequencer/accompaniment_engine.s: `.ascii "<=>89:;\\xe8" / .byte 0xd0` is `push xix .. push xhl` (seven) and
       `xor xwa, xwa`, the prologue of the second unlabelled save-all wrapper after AccPedal_DirectionA_Wrap.  It is
       the same shape as the first wrapper, which earlier respells had already written as instructions.
    D. sequencer/accompaniment_engine.s, DrumKit_InlineCode1_Code: a 30-byte table that
       DrumKit_UpdateStatusFlags_Helper reads by the slot number (0x34D6).  It was spelled as
       nop / ld w / rcf / .ascii.  It becomes `.byte` under the name DrumKit_SlotClassBits.
  A and C are proved by llvm-mc: the old lines and the new lines encode to the same bytes.  B's `cp` is proved the
  same way and its `jr` by the build.  D is proved against the ROM at the label's ELF address.  The byte gate is the
  final proof.

RUN (repository root, built tree)
  python3 scripts/tools/respell_misframed_runs_2026_10_06.py [--apply]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
TREES = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}


def enc(lines):
    out = b""
    for x in lines:
        if x.strip().startswith(".ascii"):                # the string may hold a ';'
            out += bytes(x[x.index('"') + 1:x.rindex('"')], "latin-1")
            continue
        s = x.split(";")[0].strip()
        if not s:
            continue
        if s.startswith(".byte"):
            out += bytes(int(v, 0) for v in s[5:].split(","))
            continue
        r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input=s.replace("PREVIOUS_TITLE", "0x8d37") + "\n",
                           capture_output=True, text=True)
        m = re.search(r'encoding: \[([^\]]*)\]', r.stdout)
        assert m, (s, r.stderr)
        out += bytes(int(v, 16) for v in m.group(1).split(","))
    return out


def norm(x):
    return " ".join(x.split(";")[0].split())


def find_seq(L, seq, start=0):
    n = [norm(x) for x in seq]
    return [i for i in range(start, len(L) - len(seq) + 1) if [norm(x) for x in L[i:i + len(seq)]] == n]


def main():
    apply = "--apply" in sys.argv
    for tree, stem in TREES.items():
        syms = {}
        for ln in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs", stem + ".llvm.elf")],
                                 capture_output=True, text=True, check=True).stdout.split("\n"):
            f = ln.split()
            if len(f) == 3:
                syms.setdefault(f[2], int(f[0], 16))
        rom = open(os.path.join(ROOT, "original_ROMs", stem + ".rom"), "rb").read()
        # A
        pa = os.path.join(ROOT, tree, "maincpu", "audio", "note_voice_mapping.s")
        A = open(pa, "rb").read().decode("latin-1").split("\n")
        old = ["\t.byte 0x9f", "\tccf", "\tpush\txsp", "\tpushw\twa", "\tnop"]
        new = ["\tcpw\t(xsp+18), 40"]
        hits = find_seq(A, old)
        assert len(hits) in ((0, 2) if tree == "v7" else (2,)) and enc(old) == enc(new) == bytes.fromhex("9f123f2800"), (tree, hits)
        for i in reversed(hits):
            A[i:i + len(old)] = new
        done = ["A %d x cpw (xsp+18), 40" % len(hits)]
        # B, C, D in accompaniment_engine.s
        pb = os.path.join(ROOT, tree, "maincpu", "sequencer", "accompaniment_engine.s")
        B = open(pb, "rb").read().decode("latin-1").split("\n")
        if "CmpStep_DataBlock:" not in B:
            assert tree == "v7" and any(x.startswith("CmpStep_DataBlock:\t.incbin") for x in B), tree
            done.append("B skipped (v7 holds it as a transplant .incbin)")
        else:
            done.append("B CmpStepTitle_OnPaint + 3 method labels")
            site_b(B, tree)
        site_cd(B, tree, syms, rom, done)
        print("%s: %s" % (tree, "; ".join(done)))
        if apply:
            for p, X in ((pa, A), (pb, B)):
                data = "\n".join(X).encode("latin-1")
                with open(p + ".tmp", "wb") as fh:
                    fh.write(data)
                os.replace(p + ".tmp", p)


def site_b(B, tree):
        k = B.index("CmpStep_DataBlock:")
        oldb = B[k + 1:k + 5]
        assert [norm(x) for x in oldb] == [".byte 0xc1, 0x37, 0x8d", "push xsp", "ld (xiz), xiz", "pop_f"], (tree, oldb)
        assert enc(oldb)[:5] == enc(["\tcp\t(PREVIOUS_TITLE:16), 182"]) == bytes.fromhex("c1378d3fb6"), tree
        d = next(i for i in range(k, k + 30) if norm(B[i]) == "call CmpStep_DrawScreen") - 4
        h = next(i for i in range(d, d + 30) if norm(B[i]) == "call CmpStep_OnHide") - 4
        s = next(i for i in range(h, h + 30) if norm(B[i]) == "call CmpStep_DispatchSwitch") - 4
        assert all(norm(B[x]) == "push xde" for x in (d, h, s)) and norm(B[h - 1]) == norm(B[s - 1]) == "ret", tree
        n3 = s + 10
        assert norm(B[n3 - 1]) == "ret" and norm(B[n3]) == "ret", (tree, B[n3 - 1:n3 + 1])
        B[n3:n3] = ["; CmpStepTitle_Method3Nop: CmpStepTitleFunc_ProcTable[3], a lone `ret`; DirmdEmulator calls only methods 0-2.",
                    "CmpStepTitle_Method3Nop:"]
        B[s:s] = ["; CmpStepTitle_OnSwitchIn: CmpStepTitleFunc_ProcTable[2], which DirmdEmulator calls on EVT_SW_IN: CmpStep_DispatchSwitch",
                  ";   with XDE/XHL/XIX/XIZ preserved.",
                  "CmpStepTitle_OnSwitchIn:"]
        B[h:h] = ["; CmpStepTitle_OnHide: CmpStepTitleFunc_ProcTable[1], which DirmdEmulator calls on EVT_HIDE: CmpStep_OnHide with",
                  ";   XDE/XHL/XIX/XIZ preserved.",
                  "CmpStepTitle_OnHide:"]
        B[d:d] = ["CmpStepTitle_OnPaint_Draw:"]
        B[k:k + 5] = ["; CmpStepTitle_OnPaint: CmpStepTitleFunc_ProcTable[0], TT_CMSTEP's paint method (DirmdEmulator: EVT_ALL_PAINT,",
                      ";   EVT_PARA_DRAW).  Unless the previous title was TT_CMSTEP (0xB6) it repeats DirmdEmulator's palette set-up",
                      ";   (GraphicsRender_ByteData, background 245, the palette bands), then calls CmpStep_DrawScreen.  Its first",
                      ";   instructions were spelled `.byte 0xc1, 0x37, 0x8d / push xsp / ld (xiz), xiz / pop_f` (respelled",
                      ";   2026-10-06, scripts/tools/respell_misframed_runs_2026_10_06.py).",
                      "CmpStepTitle_OnPaint:",
                      "\tcp\t(PREVIOUS_TITLE:16), 182",
                      "\tjr\tz, CmpStepTitle_OnPaint_Draw"]
        B[:] = [x.replace("CmpStep_DataBlock", "CmpStepTitle_OnPaint") for x in B]


def site_cd(B, tree, syms, rom, done):
        # C
        oldc = ['\t.ascii "<=>89:;\xe8"', "\t.byte 0xd0"]
        newc = ["\tpush\txix\t; was .ascii \"<=>89:;\\xe8\" / .byte 0xd0", "\tpush\txiy", "\tpush\txiz", "\tpush\txwa",
                "\tpush\txbc", "\tpush\txde", "\tpush\txhl", "\txor\txwa, xwa"]
        hc = find_seq(B, oldc)
        assert len(hc) in ((0,) if tree == "v7" else (1,)) and enc(oldc) == enc(newc) == bytes.fromhex("3c3d3e38393a3be8d0"), (tree, hc)
        for i in hc:
            B[i:i + 2] = newc
        done.append("C %d x 7 pushes + xor" % len(hc))
        # D
        k = B.index("DrumKit_InlineCode1_Code:")
        a = syms["DrumKit_InlineCode1_Code"] - 0xE00000
        tab = bytes([0] * 4 + [0x20] * 4 + [0x10] * 4 + [0] * 6 + [0x20] * 6 + [0x10] * 6)
        assert rom[a:a + 30] == tab, (tree, rom[a:a + 30].hex())
        j = k + 1
        while norm(B[j]) in ("nop", "ld w, 32:opc", "rcf", '.ascii " "') or norm(B[j]).startswith('.ascii "  '):
            j += 1
        assert enc(B[k + 1:j]) == tab and re.match(r"^\w+:$", B[j]), (tree, B[j])   # v7 names the next label DrumKit_UpdateStatusFlags_Sub
        B[k:j] = ["; DrumKit_SlotClassBits: for each slot (0x34D6) 0..29, the (0x34CD) bits 4-5 its class has: slots 0-3 and",
                  ";   12-17 -> 0, 4-7 and 18-23 -> 0x20, 8-11 and 24-29 -> 0x10.  DrumKit_UpdateStatusFlags_Helper compares it",
                  ";   with (0x34CD) & 0x30 and, when they differ, moves the slot to 0, 4 or 8 and sends the program change.",
                  ";   Spelled as nop / ld w / rcf / .ascii until 2026-10-06.",
                  "DrumKit_SlotClassBits:\t.byte 0x00, 0x00, 0x00, 0x00, 0x20, 0x20, 0x20, 0x20, 0x10, 0x10, 0x10, 0x10",
                  "\t\t\t.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20",
                  "\t\t\t.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10"]
        B[:] = [x.replace("DrumKit_InlineCode1_Code", "DrumKit_SlotClassBits") for x in B]
        done.append("D DrumKit_SlotClassBits")


if __name__ == "__main__":
    main()
