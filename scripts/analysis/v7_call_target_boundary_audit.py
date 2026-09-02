#!/usr/bin/env python3
"""v7_call_target_boundary_audit.py -- do converted call targets land ON an
instruction boundary?

QUESTION ANSWERED
  For every absolute call/calr/jp target introduced by a conversion diff, walk
  forward with unidasm from the nearest PRECEDING named label (found via
  llvm-nm on the freshly built ELF) and report whether the target lands exactly
  on an instruction boundary in that walk.

★ THIS IS STRICTLY STRONGER THAN "the target resolves to a name". A target can
  name a real routine and still land MID-INSTRUCTION, which means the framing
  that produced it is wrong even though the name looks reassuring. The
  established corroboration figures in this tree ("N of M land on routines
  already named") answer the weaker question; this one answers the boundary
  question, and a mid-instruction hit is a red flag to read by hand.

  It is also NOT the jump-table audit -- the lda+jp_ind check is a build-time
  guard in fill_verified_islands_v7.py. Both are needed; neither subsumes the
  other.

RUN
    python3 scripts/analysis/v7_call_target_boundary_audit.py

⚠ A clean result is corroboration, not proof. The byte gate cannot object to a
  wrong interpretation at all -- re-assembling one reproduces the same bytes --
  so this check exists precisely because the gate is silent here.

PROVENANCE
  Lane V7ISLANDS2, 2026-09-02; recovered from session scratch.
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
    tmp = "/tmp/audit_ctx.bin"
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
