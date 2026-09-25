#!/usr/bin/env python3
r"""sequi_header_evidence.py -- re-derive every NUMBER quoted in lane sequi's
2026-09-25 headers, from the dumps and the linked ELFs.

QUESTION THIS ANSWERS
    The headers written into sequencer/*.s on 2026-09-25 quote counts and
    equalities ("63 of their first 64 bytes equal", "16 of the 17 calr
    sites", "differs only at entry 7", "0x7F exactly where the offset table
    holds 0xFFFF", ...).  Are they still true?  Each claim is re-computed and
    printed PASS / FAIL; the exit status is the number of failures.

RUN (needs the ELFs: make rebuilt_ROMs/kn5000_{v10,v9,v7}_program.llvm.elf)
    python3 scripts/analysis/sequi_header_evidence.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000


def rom(img):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % img), "rb").read()


def sym(img):
    out = subprocess.run([NM, "--defined-only", os.path.join(
        ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % img)],
        capture_output=True, text=True, check=True).stdout
    d = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) == 3:
            d.setdefault(p[2], int(p[0], 16))
    return d


FAIL = 0


def claim(text, ok):
    global FAIL
    print("%s  %s" % ("PASS" if ok else "FAIL", text))
    FAIL += 0 if ok else 1


def main():
    R = {v: rom(v) for v in ("v10", "v9", "v7")}
    S = {v: sym(v) for v in ("v10", "v9", "v7")}

    def at(v, a, n):
        return R[v][a - B:a - B + n]

    # seq_audio_mode: v7 Malloc/Free identity (Heap_AllocAndFreeTwoBlocks header)
    for n10, a7, want in (("Malloc", 0xFF06A3, 63), ("Free", 0xFF0315, 62)):
        x, y = at("v10", S["v10"][n10], 64), at("v7", a7, 64)
        eq = sum(1 for i in range(64) if x[i] == y[i])
        claim("v7 0x%06X vs v10 %s: %d/64 leading bytes equal (header says %d)"
              % (a7, n10, eq, want), eq == want)
    # AccPedal_BankBaseTableCopy == AccVoice_BankBaseTable entries 1-7
    for v in ("v10", "v7"):
        a = at(v, S[v]["AccPedal_BankBaseTableCopy"], 28)
        b = at(v, S[v]["AccVoice_BankBaseTable"], 32)
        claim("%s AccPedal_BankBaseTableCopy == AccVoice_BankBaseTable[1..7]" % v, a == b[4:])
    # rhythm tables
    for v in ("v10", "v7"):
        im = at(v, S[v]["Rhythm_InstrMapTable_Default"], 147)
        vl = at(v, S[v]["Rhythm_VelocityTable_A"], 98)
        d = [(k, i) for k in range(2) for i in range(49) if im[49 * k + i] != vl[49 * k + i]]
        claim("%s Rhythm_VelocityTable_A differs from InstrMap variants 0-1 only at entry 7: %s"
              % (v, d), d == [(0, 7), (1, 7)])
        claim("%s InstrMap values are row numbers 0..20" % v, max(im) == 20)
    claim("v7 rhythm InstrMap/PitchShift/Velocity tables == v10's",
          all(at("v7", S["v7"][n], k) == at("v10", S["v10"][n], k) for n, k in (
              ("Rhythm_InstrMapTable_Default", 147), ("Rhythm_PitchShiftTable_Default", 98),
              ("Rhythm_VelocityTable_A", 98))))
    sr10 = at("v10", S["v10"]["Rhythm_SeqResetTable"], 68)
    sr7 = at("v7", S["v7"]["Rhythm_SeqResetTable"], 68)
    l10 = [int.from_bytes(sr10[i:i + 4], "little") for i in range(0, 68, 4)]
    l7 = [int.from_bytes(sr7[i:i + 4], "little") for i in range(0, 68, 4)]
    claim("Rhythm_SeqResetTable v7 = v10 - 0x9C in every non-zero slot",
          all((a == b == 0) or (a - b == 0x9C) for a, b in zip(l10, l7)))
    # SMF_HeaderConstants
    for v in ("v10", "v7"):
        h = at(v, S[v]["SMF_HeaderConstants"], 0x66)
        w = [int.from_bytes(h[0x1A + 2 * i:0x1C + 2 * i], "little") for i in range(20)]
        t = list(h[0x52:0x66])
        claim("%s SMF offsets are 0x36+26k (k=0..15) or 0xFFFF" % v,
              sorted(x for x in w if x != 0xFFFF) == [0x36 + 26 * k for k in range(16)])
        claim("%s SMF +0x52 byte is 0x7F exactly where +0x1A holds 0xFFFF" % v,
              [x == 0xFFFF for x in w] == [y == 0x7F for y in t])
        claim("%s SMF GM On/Off events" % v,
              h[0x42:0x52] == bytes.fromhex("00f0057e7f0901f7" "00f0057e7f0902f7"))
    claim("SMF_HeaderConstants v7 bytes == v10 bytes",
          at("v7", S["v7"]["SMF_HeaderConstants"], 0x66) == at("v10", S["v10"]["SMF_HeaderConstants"], 0x66))
    # SMF_TranslateChannel call sites (source)
    for v in ("v10", "v7"):
        L = open(os.path.join(ROOT, v, "maincpu/sequencer/smf_config_routines.s"),
                 encoding="latin-1").read().split("\n")
        tot = n = 0
        for i, ln in enumerate(L):
            if re.match(r"\s*calr\s+SMF_TranslateChannel\b", ln):
                tot += 1
                win = " ".join(L[i + 1:i + 6])
                n += "bit 7, a" in win and "ormi8 (xiy)" in win
        claim("%s SMF_TranslateChannel: %d calr sites, %d use bit 7 as a flag (header: 17 / 16)"
              % (v, tot, n), (tot, n) == (17, 16))
    # Composer tables: counts and registration record in the ROM
    for v, ap in (("v10", "ApFunctionProc"), ("v7", "ApFunctionProc")):
        code = R[v]
        rec124 = bytes([0xf2]) + (0xE16284).to_bytes(3, "little") + bytes([0x30, 0xb9, 0x0a, 0x60, 0x30, 0x24, 0x01])
        rec424 = bytes([0xf2]) + (0xE163AC).to_bytes(3, "little") + bytes([0x30, 0xb9, 0x0a, 0x60, 0x30, 0x24, 0x04])
        claim("%s registers 0xE16284 as id 0x124 and 0xE163AC as id 0x424" % v,
              code.find(rec124) >= 0 and code.find(rec424) >= 0)
    ft = at("v10", 0xE16284, 74 * 4)
    ptrs = [int.from_bytes(ft[i:i + 4], "little") for i in range(0, 74 * 4, 4)]
    claim("Composer_FunctionTable: 73 non-zero entries (the registered 0x49) then 0",
          all(ptrs[:73]) and ptrs[73] == 0 and S["v10"]["Composer_CallbackNameTable"] == 0xE16284 + 74 * 4)
    nt = at("v10", S["v10"]["Composer_CallbackNameTable"], 74 * 4)
    names = [int.from_bytes(nt[i:i + 4], "little") for i in range(0, 74 * 4, 4)]
    claim("Composer_CallbackNameTable: 74 entries, the last -> FuncName_Empty_0",
          names[73] == S["v10"]["FuncName_Empty_0"]
          and S["v10"]["FuncName_Empty_0"] == S["v10"]["Composer_CallbackNameTable"] + 74 * 4)
    print("%d failure(s)" % FAIL)
    sys.exit(FAIL)


if __name__ == "__main__":
    main()
