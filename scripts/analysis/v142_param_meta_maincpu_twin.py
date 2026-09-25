#!/usr/bin/env python3
r"""v142_param_meta_maincpu_twin.py -- the sub-CPU effect-parameter metadata is a copy of main-CPU tables.

QUESTION THIS ANSWERS
    v142/subcpu/subcpu_data_tables.s holds, at 0x0133CF-0x014738, a block of per-effect
    parameter metadata (range arrays, 23-byte "defaults" records, a count table, two
    100-entry pointer tables and 8 trailing bytes) that NOTHING in the sub-CPU payload
    reads (searched forms: see the block header's RE-CHECKED note).  Is it a copy of
    something that IS read somewhere?

    Yes.  This script proves, from the ROM dumps alone, that every part of the block is
    byte-identical (or relocation-identical, for the pointer tables) to a table in the
    main-CPU program ROM at 0xEE4FC6-0xEE636B -- the same address in v7, v9 and v10 -- and
    that the main-CPU copy has readers whose instructions hold the table addresses:

        main 0xEE6044  range-array pointer table   <- DSPCfg_LookupAndExtract, DSPCfg_ClampAndExtract, DSPCfg_Data_003
        main 0xEE5FE0  parameter-count table       <- DSPCfg_GetSlotCount, DSPCfg_ApplyParamStruct
        main 0xEE61D4  defaults pointer table      <- DSPCfg_ResolveWithFallback, DSPCfg_WriteAllSlots_Direct/_Clamped
        main 0xEE6364  4-byte table                <- DSPCfg_Data_001
        main 0xEE6368  4-byte table                <- DSPCfg_Data_002
        main 0xEE75F6  descriptor pointer table    <- DSPCfg_ReadViaTableLookup (indexed by defaults byte 0)

    (routine names are the v10 source's; the script checks the ADDRESS and the operand
    bytes in the ROM, and names the enclosing v10 symbol only if a v10 ELF is present).

    It also checks two facts the sub-CPU headers quote:
      * every dedicated defaults record's byte 0 equals the effect number that points at it;
      * the main-CPU defaults records are 24 bytes = the sub's 23 + one 0xFF.

SIGNALS / WHAT PASS MEANS
    Each check prints PASS/FAIL; the exit status is non-zero on any FAIL.

RUN
    python3 scripts/analysis/v142_param_meta_maincpu_twin.py
    (optional: `make rebuilt_ROMs/kn5000_v10_program.llvm.elf` first, to get symbol names)
"""
import bisect
import os
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SUB = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
MAIN = {v: os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v) for v in ("v10", "v9", "v7")}
OLDSUB = {v: os.path.join(ROOT, "original_ROMs/kn5000_subprogram_%s.rom" % v) for v in ("v140", "v141")}
ELF = os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")

SUB_DELTA = 0xEF00          # sub-CPU address = ROM file offset + 0xEF00 (payload linked at 0xF000, 0x100 header)
MAIN_BASE = 0xE00000

# sub-CPU layout (addresses, from subcpu_data_tables.s)
S_RANGES, S_DEFAULTS, S_COUNTS, S_RPTR, S_DPTR, S_TAIL, S_END = (
    0x0133CF, 0x013E49, 0x0143AD, 0x014411, 0x0145A1, 0x014731, 0x014739)
N_DEFAULTS = (S_COUNTS - S_DEFAULTS) // 23          # 60
# main-CPU layout (v10/v9/v7)
M_RANGES, M_DEFAULTS, M_COUNTS, M_RPTR, M_DPTR, M_TAIL = (
    0xEE4FC6, 0xEE5A40, 0xEE5FE0, 0xEE6044, 0xEE61D4, 0xEE6364)

# (constant, routine address, v10 name, what) -- operand bytes must be inside the routine
READERS = [
    (M_RPTR, 0xFDC41D, "DSPCfg_LookupAndExtract", "range-array pointer table"),
    (M_RPTR, 0xFDC803, "DSPCfg_ClampAndExtract", "range-array pointer table"),
    (M_RPTR, 0xFDC4B7, "DSPCfg_Data_003", "range-array pointer table"),
    (M_COUNTS, 0xFDC456, "DSPCfg_GetSlotCount", "count table"),
    (M_DPTR, 0xFDC710, "DSPCfg_ResolveWithFallback", "defaults pointer table"),
    (M_TAIL, 0xFDC448, "DSPCfg_Data_001", "4-byte table A"),
    (M_TAIL + 4, 0xFDC464, "DSPCfg_Data_002", "4-byte table B"),
    (0xEE75F6, 0xFDC364, "DSPCfg_ReadViaTableLookup", "descriptor pointer table"),
]

fails = 0


def check(ok, msg):
    global fails
    print("  %s  %s" % ("PASS" if ok else "FAIL", msg))
    if not ok:
        fails += 1


def S(rom, a, n):
    return rom[a - SUB_DELTA:a - SUB_DELTA + n]


def M(rom, a, n):
    return rom[a - MAIN_BASE:a - MAIN_BASE + n]


def symbols():
    if not (os.path.exists(ELF) and os.path.exists(NM)):
        return None
    out = subprocess.run([NM, "-n", ELF], capture_output=True, text=True).stdout
    rows = []
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT":
            rows.append((int(p[0], 16), p[2]))
    return rows


def main():
    sub = open(SUB, "rb").read()
    print("1. range arrays + defaults + counts are byte-identical in every main-CPU version")
    ranges = S(sub, S_RANGES, S_DEFAULTS - S_RANGES)
    counts = S(sub, S_COUNTS, 100)
    tail = S(sub, S_TAIL, 8)
    for v, p in MAIN.items():
        m = open(p, "rb").read()
        check(M(m, M_RANGES, len(ranges)) == ranges,
              "%s: sub 0x%06X..0x%06X (%d B range arrays) == main 0x%06X" % (
                  v, S_RANGES, S_DEFAULTS - 1, len(ranges), M_RANGES))
        ok = all(M(m, M_DEFAULTS + 24 * k, 23) == S(sub, S_DEFAULTS + 23 * k, 23) and
                 M(m, M_DEFAULTS + 24 * k + 23, 1) == b"\xff" for k in range(N_DEFAULTS))
        check(ok, "%s: %d sub 23-byte defaults records == main 24-byte records' first 23 bytes, "
                  "24th byte 0xFF in all" % (v, N_DEFAULTS))
        check(M(m, M_COUNTS, 100) == counts, "%s: 100-byte count table == main 0x%06X" % (v, M_COUNTS))
        check(M(m, M_TAIL, 8) == tail, "%s: 8 trailing bytes %s == main 0x%06X" % (v, tail.hex(" "), M_TAIL))
        rp_s = struct.unpack("<100I", S(sub, S_RPTR, 400))
        rp_m = struct.unpack("<100I", M(m, M_RPTR, 400))
        check(all(a - S_RANGES == b - M_RANGES for a, b in zip(rp_s, rp_m)),
              "%s: range pointer table: sub entry - 0x%06X == main entry - 0x%06X for all 100" % (
                  v, S_RANGES, M_RANGES))
        dp_s = struct.unpack("<100I", S(sub, S_DPTR, 400))
        dp_m = struct.unpack("<100I", M(m, M_DPTR, 400))
        check(all((a - S_DEFAULTS) % 23 == 0 and (b - M_DEFAULTS) % 24 == 0 and
                  (a - S_DEFAULTS) // 23 == (b - M_DEFAULTS) // 24 for a, b in zip(dp_s, dp_m)),
              "%s: defaults pointer table: same record index in all 100 entries (stride 23 vs 24)" % v)
        if v == "v10":
            check(struct.unpack("<I", M(m, M_RPTR, 4))[0] == M_RANGES,
                  "v10: main pointer table entry 0 is at 0x%06X (the v10 label ToneKit_VoiceDispatch_Table "
                  "sits 4 bytes later, at 0x%06X)" % (M_RPTR, M_RPTR + 4))
    for v, p in OLDSUB.items():
        o = open(p, "rb").read()
        check(S(o, S_RANGES, S_END - S_RANGES) == S(sub, S_RANGES, S_END - S_RANGES),
              "%s payload holds the same 0x%06X..0x%06X block at the same address" % (v, S_RANGES, S_END - 1))

    print("2. defaults record byte 0 == the effect number whose pointer entry points at it")
    dp_s = struct.unpack("<100I", S(sub, S_DPTR, 400))
    users = {}
    for e, a in enumerate(dp_s):
        users.setdefault(a, []).append(e)
    ded = [(a, es) for a, es in users.items() if len(es) == 1]
    ok = all(S(sub, a, 1)[0] == es[0] for a, es in ded)
    shared = [(a, es) for a, es in users.items() if len(es) > 1]
    check(ok, "%d dedicated records: byte 0 == effect number in all" % len(ded))
    for a, es in shared:
        print("        shared record 0x%06X (%d effects incl. %s): byte 0 = %d" % (a, len(es), es[:3], S(sub, a, 1)[0]))
    check(all(S(sub, S_DEFAULTS + 23 * k + 22, 1) == b"\x63" for k in range(N_DEFAULTS)),
          "byte 22 of all %d records is 99 (0x63)" % N_DEFAULTS)

    print("3. main-CPU v10 readers hold the main twin's addresses as instruction operands")
    m = open(MAIN["v10"], "rb").read()
    syms = symbols()
    for const, rtn, name, what in READERS:
        win = M(m, rtn, 0x60)
        off = win.find(const.to_bytes(3, "little"))
        where = ""
        if syms:
            addrs = [a for a, _ in syms]
            i = bisect.bisect_right(addrs, rtn + max(off, 0)) - 1
            where = " [ELF: %s+%d]" % (syms[i][1], rtn + off - syms[i][0]) if off >= 0 else ""
        check(off >= 0, "0x%06X (%s) is an operand at 0x%06X, %d bytes into %s @ 0x%06X%s" % (
            const, what, rtn + off, off, name, rtn, where))
    hits = []
    i = m.find((M_RPTR + 4).to_bytes(3, "little"))
    while i >= 0:
        hits.append(i)
        i = m.find((M_RPTR + 4).to_bytes(3, "little"), i + 1)
    check(not hits, "0x%06X (where v10 puts the label ToneKit_VoiceDispatch_Table) occurs nowhere in the "
                    "v10 ROM as a 3-byte LE value" % (M_RPTR + 4))
    print("\n%s" % ("ALL PASS" if not fails else "%d FAIL" % fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
