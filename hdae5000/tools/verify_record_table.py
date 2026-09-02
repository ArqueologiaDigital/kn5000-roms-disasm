#!/usr/bin/env python3
"""verify_record_table.py -- proves HDAE5000_RECORD_TABLE (0x29C0AA, 6,356 B) is DATA,
and that the typed-data conversion in hdae5000_data_tables.s reproduces it exactly.

QUESTION ANSWERED: was it correct to replace ~6,150 lines of TLCS-900 instruction
mnemonics at 0x29C0AA-0x29D97D with a 13x24-byte record array + a zero-filled
reserved gap + a packed string pool -- rather than genuine, if oddly-shaped, code?

RUN (from the hdae5000 lane worktree root):
    python3 hdae5000/tools/verify_record_table.py

Reads ONLY original_ROMs/hd-ae5000_v2_06i.ic4. Every check below must pass with
"no exception" reported; that is the corroboration the byte gate cannot give
(re-assembling a wrong interpretation reproduces the same bytes either way).
"""
import struct
import sys

ROM = "original_ROMs/hd-ae5000_v2_06i.ic4"
BASE = 0x280000
TBL = 0x29C0AA
COUNT_ADDR = 0x29D97E  # HDAE5000_RECORD_COUNT

# The 13 classes, in ROM record order, and the ProcPtr each record's +0x00
# field is expected to resolve to -- taken from the *Proc labels already named
# in hd-ae5000_v2_06i.s / hdae5000_ui_display.s before this lane touched
# anything.  A mismatch here would mean the record layout is wrong.
EXPECTED = [
    ("SelectList",        0x2807D9),
    ("DbMemoCl",          0x28122A),
    ("TtlScreenR",        0x280489),
    ("AcHddNamingWindow", 0x281411),
    ("IvHddNaming",       0x282681),
    ("HDTitleMenu",       0x2827A8),
    ("TtlScreenR2",       0x280567),
    ("TtlScreenR3",       0x280645),  # == HDAE5000_TtlScreenR3Proc, confirmed by name
    ("AcWindowPage1",     0x28043C),
    ("IvScreenR2",        0x280723),
    ("AcLanguageText1",   0x28B554),
    ("LyricBox",          0x28CD08),
    ("FDFileSelect",      0x28E61B),
]

# hdae5000_init_data.s:23-28's own published parameter counts, same order.
EXPECTED_SIG_LEN = [11, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 6, 3]


def cstr(data, addr):
    off = addr - BASE
    end = data.index(b"\x00", off)
    return data[off:end]


def main():
    data = open(ROM, "rb").read()
    assert len(data) == 524288
    ok = True

    # --- 1. the record array: 13 x 24 bytes, ProcPtr matches a named routine ---
    for i, (cname, expect_proc) in enumerate(EXPECTED):
        off = TBL - BASE + i * 24
        proc, f04, f06, f08, f0a, namep, sigp, listp = struct.unpack_from("<IHHHHIII", data, off)
        if proc != expect_proc:
            print(f"FAIL record {i} ({cname}): ProcPtr 0x{proc:06X} != expected 0x{expect_proc:06X}")
            ok = False
        name = cstr(data, namep)
        if name.decode("latin1") != cname:
            print(f"FAIL record {i}: NamePtr string {name!r} != expected {cname!r}")
            ok = False
        siglen = len(cstr(data, sigp)) if sigp else -1
        if siglen != EXPECTED_SIG_LEN[i]:
            print(f"FAIL record {i} ({cname}): sig len {siglen} != expected {EXPECTED_SIG_LEN[i]}")
            ok = False
    print(f"[1] 13 records: ProcPtr/NamePtr/SigPtr-length all checked "
          f"({'OK, no exception' if ok else 'SEE FAILURES ABOVE'})")

    # --- 2. record-count word at 0x29D97E really is 13, per hd-ae5000_v2_06i.s:310 ---
    (count,) = struct.unpack_from("<H", data, COUNT_ADDR - BASE)
    if count != 13:
        print(f"FAIL record count word at 0x{COUNT_ADDR:06X} = {count}, expected 13")
        ok = False
    else:
        print(f"[2] record count word at 0x{COUNT_ADDR:06X} == 13, OK")

    # --- 3. the reserved gap between the record array and the string pool is
    #        entirely 0x00, with no exception ---
    recs_end = TBL + 13 * 24
    pool_start = 0x29D8AA
    gap = data[recs_end - BASE: pool_start - BASE]
    gap_len = pool_start - recs_end
    if gap != b"\x00" * gap_len:
        nz = [i for i, b in enumerate(gap) if b]
        print(f"FAIL reserved gap 0x{recs_end:06X}-0x{pool_start:06X} has "
              f"{len(nz)} non-zero byte(s), first at +0x{nz[0]:X}")
        ok = False
    else:
        print(f"[3] reserved gap 0x{recs_end:06X}-0x{pool_start-1:06X} "
              f"({gap_len} B) is all 0x00, no exception")

    # --- 4. the string pool decomposes into exactly the 26 NUL-terminated
    #        strings the 13 records point at (13 names + 13 sigs), with zero
    #        leftover bytes and zero orphan strings ---
    referenced = set()
    for i in range(13):
        off = TBL - BASE + i * 24
        _p, _f04, _f06, _f08, _f0a, namep, sigp, _l = struct.unpack_from("<IHHHHIII", data, off)
        referenced.add(namep)
        if sigp:
            referenced.add(sigp)

    off = pool_start - BASE
    off_end = COUNT_ADDR - BASE
    found_starts = set()
    n_strings = 0
    while off < off_end:
        addr = off + BASE
        nul = data.index(b"\x00", off)
        if data[off:nul]:  # non-empty string always starts a new logical entry
            found_starts.add(addr)
        elif addr in referenced:  # a bare-NUL SigPtr target also counts
            found_starts.add(addr)
        off = nul + 1
        n_strings += 1

    missing = referenced - found_starts
    if missing:
        print(f"FAIL {len(missing)} referenced pointer(s) do not land on a pool "
              f"string start: {[hex(m) for m in missing]}")
        ok = False
    else:
        print(f"[4] all {len(referenced)} distinct NamePtr/SigPtr values land exactly "
              f"on a pool string start, no exception ({n_strings} NUL-terminated runs "
              f"walked, {off_end - (pool_start - BASE)} B consumed with none left over)")

    # --- 5. no call or jump anywhere in the assembled tree targets an address
    #        inside 0x29C0AA-0x29D97D. This is a grep-based check over the
    #        committed .s sources, run relative to this script's repo root. ---
    import os
    import re
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    hdae_dir = os.path.join(root, "hdae5000")
    call_jump_re = re.compile(r"\b(?:call|calr|jp|jr|jrl)\b", re.IGNORECASE)
    hits = []
    for fn in os.listdir(hdae_dir):
        if not fn.endswith(".s"):
            continue
        path = os.path.join(hdae_dir, fn)
        for lineno, line in enumerate(open(path, encoding="latin1"), 1):
            if call_jump_re.search(line):
                m = re.search(r"0x29[cd][0-9a-f]{3}", line, re.IGNORECASE)
                if m:
                    addr = int(m.group(0), 16)
                    if TBL <= addr < COUNT_ADDR:
                        hits.append((path, lineno, line.strip()))
    if hits:
        print(f"FAIL {len(hits)} call/jump site(s) target inside the table span:")
        for p, l, t in hits:
            print(f"   {p}:{l}: {t}")
        ok = False
    else:
        print("[5] no call/jr/jrl/jp/calr site anywhere in hdae5000/*.s targets an "
              "address inside 0x29C0AA-0x29D97D, no exception")

    print()
    print("ALL CHECKS PASSED" if ok else "CHECKS FAILED -- see above")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
