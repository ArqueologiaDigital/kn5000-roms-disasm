#!/usr/bin/env python3
"""Retroactive call-target audit for v7islands2's converted `call`/`calr`/`jp`
instructions. For each absolute target address introduced by this session's
diff, walks forward from the nearest PRECEDING named label (via llvm-nm on the
freshly-built ELF) using unidasm, and reports whether the target lands
EXACTLY on an instruction boundary in that walk (real code, corroborated)
or not (SPANS/mid-instruction -- a red flag worth reading by hand).

This is NOT the jump-table lda+jp_ind audit (that is already a build-time
guard in fill_verified_islands_v7.py) -- it is the call-target corroboration
check the debt inventory and prior lanes used to report "N of M land on
routines already named in the tree".

QUESTION ANSWERED
  For a `call`/`calr`/`jp` instruction this session just converted from
  `.byte`, does its target address land on something already established
  as real code -- either an exact existing label, or a genuine instruction
  boundary reached by decoding forward from the nearest preceding label?
  A target that lands mid-instruction (SPANS) or fails to resync at all is
  a red flag worth reading by hand, the same way the three reverted
  `lda_24 (LABEL) / jp_ind` conversions and the `srl xsp, 98` conversion
  from this and the immediately preceding session were NOT caught by any
  byte-level round-trip check.

RUN
    python3 scripts/analysis/audit_v7_call_targets.py \
        rebuilt_ROMs/kn5000_v7_program.llvm.rom \
        rebuilt_ROMs/kn5000_v7_program.llvm.rom \
        0xADDR1 0xADDR2 ...

  (first two positional args are ELF then raw ROM -- pass the just-built
  rebuilt_ROMs/kn5000_v7_program.llvm.elf and .llvm.rom; targets are the
  absolute addresses decoded by the `call`/`jp` instructions your slice
  just added, in decimal or 0x-hex.)

Lane V7ISLANDS2, 2026-09-02 -- used to audit all 7,496 v7 island candidates
across the 2026-09-02 full-disassembly push (see notes/lanes/ for the slice
commits this ran against). Only checks CONTROL-TRANSFER targets you pass in
-- do not pass an immediate-load operand (`ld reg, N`) by mistake, it will
report a meaningless "SUSPECT" since N is not an address at all.
"""
import re, subprocess, sys, bisect

BASE = 0xE00000
UNI = "/home/fsanches/compartilhado/tools/unidasm"
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')

def load_nm(elf):
    out = subprocess.run(
        ["/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm", "--no-sort", elf],
        capture_output=True, text=True).stdout
    addrs = []
    for line in out.split("\n"):
        parts = line.split()
        if len(parts) == 3 and parts[1] in "tT":
            addrs.append((int(parts[0], 16), parts[2]))
    addrs.sort()
    return addrs

def nearest_label(addrs, t):
    keys = [a for a, n in addrs]
    i = bisect.bisect_right(keys, t) - 1
    return addrs[i] if i >= 0 else (None, None)

def walk_boundary(rom, label_addr, target, window=400):
    off = label_addr - BASE
    tend = min(target - BASE + 2, off + window)
    blob = rom[off:tend]
    tmp = "/tmp/audit_v7_call_targets_ctx.bin"
    open(tmp, "wb").write(blob)
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(label_addr)],
                         capture_output=True, text=True).stdout
    bnd = set()
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if m:
            bnd.add(int(m.group(1), 16))
    return target in bnd

def main():
    elf = sys.argv[1]
    rom = open(sys.argv[2], "rb").read()
    targets = [int(x, 0) for x in sys.argv[3:]]
    addrs = load_nm(elf)
    exact = boundary = neither = 0
    for t in targets:
        la, ln = nearest_label(addrs, t)
        if la == t:
            print(f"0x{t:06x}  EXACT match: {ln}")
            exact += 1
            continue
        ok = walk_boundary(rom, la, t)
        if ok:
            print(f"0x{t:06x}  +{t-la} into {ln} -- lands on a real instruction boundary")
            boundary += 1
        else:
            print(f"0x{t:06x}  +{t-la} into {ln} -- DOES NOT land on an instruction boundary (SUSPECT)")
            neither += 1
    print(f"\n=> {exact} exact-label hits, {boundary} boundary-corroborated, "
          f"{neither} UNCORROBORATED, of {len(targets)} targets")

if __name__ == "__main__":
    main()
