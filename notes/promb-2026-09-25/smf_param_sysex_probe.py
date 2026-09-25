#!/usr/bin/env python3
r"""prom_b 0xF74FCF-0xF75674: the SMF writer's 74 parameter-change SysEx templates.

QUESTION THIS ANSWERS
    wsa1/prom_b/wsa1_prom_b.s carried 0xF74FCF-0xF7554C as `Data_F74FCF` +
    `sub_F752DF` ("Unknown: everything about it except its bytes"; the second a
    label some stale `calr`s created) and 0xF7554D as `RamPtrTable_F7554D`
    ("Unknown: what lives at those RAM addresses").  This probe re-derives, from
    the ROM bytes alone:

      1. the READER: MAME unidasm's decode of 0xF74EC5 (SmfExport_WriteParamSysEx)
         must contain `ld XDE,0x00f74fcf`, `mul L,0x13` (stride 19),
         `cp BC,0x004a` (74 records), `ld XIZ,0x00f7554d` (the parallel
         pointer table) and `call 0xf4090c` (the checksum slot);
      2. the RECORDS: 74 x 19 bytes whose constant fields are the same in all
         74 (F0 / length 0x10 / 50 2C 04 00 11 00 / 00 00 01 / 00 / F7), whose
         +0 delta byte is < 0x80, and whose +9/+10 address pairs are distinct;
         74 * 19 must end exactly at the pointer table;
      3. the POINTER TABLE: 74 LE32 words below 0x10000, ending at 0xF75675;
         records 4..70 read RAM 0x7622 + their parameter number (+10), and the
         only address-0x11 records that do not are 1, 2, 3 and 71;
      4. the STALE CALLS: every `calr` in prom_b (unidasm instruction start)
         whose target lies inside the 1406 bytes, and that none of them lands on
         a record start.

RUN
    python3 notes/promb-2026-09-25/smf_param_sysex_probe.py
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
UNI = os.path.join(os.path.expanduser("~/compartilhado"), "tools", "unidasm")
BASE = 0xF00000
TPL, N, STRIDE = 0xF74FCF, 74, 19
PTRS = 0xF7554D
READER = 0xF74EC5
LINE = re.compile(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s*(\S+)\s*(.*)$')
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def unidasm(blob, base):
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(blob)
        f.flush()
        out = subprocess.run([UNI, f.name, "-arch", "tlcs900", "-basepc", hex(base)],
                             capture_output=True, text=True).stdout
    res = {}
    for ln in out.split("\n"):
        m = LINE.match(ln)
        if m:
            res[int(m.group(1), 16)] = (m.group(3).lower(), m.group(4).strip().lower(),
                                        len(m.group(2).split()))
    return res


def main():
    rom = open(B, "rb").read()
    at = lambda a, n=1: rom[a - BASE:a - BASE + n]
    uni = unidasm(rom, BASE)
    # 1. reader
    a, body = READER, []
    for _ in range(200):
        mn, ops, n = uni[a]
        body.append("%s %s" % (mn, ops))
        if mn == "ret":
            break
        a += n
    txt = "\n".join(body)
    print("reader 0x%06X-0x%06X, %d instructions" % (READER, a, len(body)))
    for want in ("ld xde,0x00f74fcf", "mul l,0x13", "cp bc,0x004a", "ld xiz,0x00f7554d",
                 "call 0xf4090c"):
        check("reader contains `%s`" % want, want in txt)
    # 2. records
    recs = [at(TPL + STRIDE * k, STRIDE) for k in range(N)]
    const = {1: 0xF0, 2: 0x10, 3: 0x50, 4: 0x2C, 5: 0x04, 6: 0x00, 7: 0x11, 8: 0x00,
             11: 0x00, 12: 0x00, 13: 0x01, 14: 0x00, 15: 0x00, 16: 0x00, 17: 0x00, 18: 0xF7}
    for off, v in sorted(const.items()):
        check("+%-2d == 0x%02X in all %d records" % (off, v, N), all(r[off] == v for r in recs))
    check("+0 delta < 0x80 in all records (one-byte SMF varlen)", all(r[0] < 0x80 for r in recs))
    addrs = [(r[9], r[10]) for r in recs]
    check("the %d (+9,+10) address pairs are distinct" % N, len(set(addrs)) == N)
    check("74 * 19 ends exactly at the pointer table 0x%06X" % PTRS, TPL + N * STRIDE == PTRS)
    print("  deltas: %s" % " ".join("%d:%02X" % (k, r[0]) for k, r in enumerate(recs) if r[0]))
    # 3. pointer table
    ptrs = [int.from_bytes(at(PTRS + 4 * k, 4), "little") for k in range(N)]
    check("74 pointers, all below 0x10000", all(p < 0x10000 for p in ptrs))
    nxt = int.from_bytes(at(PTRS + 4 * N, 4), "little")
    check("the word after entry 73 (0x%06X) is not one: 0x%08X" % (PTRS + 4 * N, nxt), nxt >= 0x10000)
    hit = [k for k in range(N) if addrs[k][0] == 0x11 and ptrs[k] == 0x7622 + addrs[k][1]]
    miss = [k for k in range(N) if addrs[k][0] == 0x11 and k not in hit]
    for k in miss:
        print("  record %d: address 11 %02X -> RAM 0x%04X (0x7622 + param would be 0x%04X)"
              % (k, addrs[k][1], ptrs[k], 0x7622 + addrs[k][1]))
    check("records 4..70 (67 of them): RAM = 0x7622 + parameter number",
          hit == list(range(4, 71)))
    check("the exceptions among the address-0x11 records are exactly 1, 2, 3 and 71",
          miss == [1, 2, 3, 71])
    # 4. stale calls
    lo, hi = TPL, TPL + N * STRIDE
    sites = []
    for i in range(len(rom) - 3):
        if rom[i] != 0x1E:
            continue
        d = int.from_bytes(rom[i + 1:i + 3], "little")
        d = d - 0x10000 if d & 0x8000 else d
        tgt = BASE + i + 3 + d
        if lo <= tgt < hi and uni.get(BASE + i, ("",))[0] == "calr":
            sites.append((BASE + i, tgt))
    for s, tgt in sites:
        k, off = divmod(tgt - TPL, STRIDE)
        print("  calr at 0x%06X -> 0x%06X = record %d, +%d" % (s, tgt, k, off))
    check("%d calr sites land inside the records, none on a record start" % len(sites),
          all((tgt - TPL) % STRIDE for _, tgt in sites))
    print("\nVERDICT:", "PASS" if not FAIL else "FAIL (%d)" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
