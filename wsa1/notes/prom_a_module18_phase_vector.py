#!/usr/bin/env python3
"""prom_a_module18_phase_vector.py -- module 18's boot phase vector (prom_a 0xFF75B6), proven from the ROM and labelled.

QUESTION IT ANSWERS
  ModuleInitDirectory_F82641[18] is prom_b slot 0xF42250 (then T_F42250).  Unlike most slots it is not a `jp`: it holds
  the word 0x00FF75B6, and the walker (0xF82846: `ld XIX,(XIX)` / `lda XIX,(XIX+WA)` / `call (XIX)`) takes that
  word as the module's PHASE VECTOR base and calls base + 4k for boot phase k.  notes/FINDINGS-prom_b-thunk-table.md
  had recorded 0xFF75B6 as "code, not a table", because its slots are not `jp`.  It is a phase vector of six 4-byte
  slots of short code:
      0xFF75B6  jr 0xFF75CD / ret / (00)    phase 0
      0xFF75BA  nop / nop / ret / (00)      phases 1-4, and a sixth slot no phase reaches (0xFF75CA, 3 bytes)
  and 0xFF75CD is `ld (Disk_SelectedEntry:16), 0x14 / ret`: phase 0 sets the disk screens' selected directory entry
  to 0x14, one past the largest value the Medley code stores (0x13).  That write is the module's only work, so it is
  named for it: DiskScreens_PhaseVector, DiskScreens_InitSelectedEntry (was the local .LFF75CD), and the prom_b
  slot T_DiskScreens_PhaseVector (through wsa1_rename.py, which declares it to the preservation checks).
  The census (scripts/analysis/dispatch_table_census) counted the slot as a numeric pointer to an unlabelled
  instruction start in the prom_b routine directory.
  Every byte above is asserted from original_ROMs/ before anything is written.

RUN (from wsa1/)
  python3 notes/prom_a_module18_phase_vector.py            # assert the chain and the slot bytes
  python3 notes/prom_a_module18_phase_vector.py --apply    # place the prom_a labels and headers
  then: wsa1_rename.py T_F42250=T_DiskScreens_PhaseVector (done 2026-10-06), and
        python3 scripts/converters/symbolize_wsa1_rom_addresses.py --apply (from the repository root)
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RA = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
RB = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
VEC, INIT = 0xFF75B6, 0xFF75CD
HDR_VEC = [
    "; DiskScreens_PhaseVector: module 18's boot phase vector -- ModuleInitDirectory_F82641[18] reaches it through prom_b's",
    ";   pointer slot T_DiskScreens_PhaseVector (0xF42250, a word, not a `jp`); the walker calls slot k (4 bytes) for boot",
    ";   phase k.  The slots are short code: phase 0 `jr DiskScreens_InitSelectedEntry`, phases 1-4 `nop / nop / ret`, and",
    ";   a sixth slot no phase reaches (notes/prom_a_module18_phase_vector.py).",
]
HDR_INIT = [
    "; DiskScreens_InitSelectedEntry: boot phase 0 of module 18 -- Disk_SelectedEntry = 0x14, one past the largest entry",
    ";   (0x13) the Medley code stores.",
]


def rd(a, n):
    return RA[a - 0xF80000:a - 0xF80000 + n] if a >= 0xF80000 else RB[a - 0xF00000:a - 0xF00000 + n]


def check():
    slot = int.from_bytes(rd(0xF82641 + 4 * 18, 4), "little")
    assert slot == 0xF42250, hex(slot)
    vb = int.from_bytes(rd(slot, 4), "little")
    assert vb == VEC, hex(vb)
    assert rd(VEC, 4) == bytes([0x68, 0x15, 0x0E, 0x00]), rd(VEC, 4).hex()
    assert VEC + 2 + 0x15 == INIT
    for k in range(1, 5):
        assert rd(VEC + 4 * k, 4) == bytes([0x00, 0x00, 0x0E, 0x00]), (k, rd(VEC + 4 * k, 4).hex())
    assert rd(VEC + 20, 3) == bytes([0x00, 0x00, 0x0E])
    assert rd(INIT, 6) == bytes([0xF1, 0x24, 0x27, 0x00, 0x14, 0x0E]), rd(INIT, 6).hex()   # ld (0x2724:16), 0x14 / ret
    print("module 18: directory slot 0x%06X -> phase vector 0x%06X; phase 0 -> 0x%06X (Disk_SelectedEntry = 0x14)"
          % (slot, vb, INIT))


def apply():
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    if any(x.startswith("DiskScreens_PhaseVector:") for x in L):
        print("already applied")
        return
    k = next(i for i, x in enumerate(L) if x.startswith("\tjr .LFF75CD ") and "; FF75B6 " in x)
    j = L.index(".LFF75CD:")
    assert sum(x.count(".LFF75CD") for x in L) == 2
    L[k] = L[k].replace("jr .LFF75CD ", "jr DiskScreens_InitSelectedEntry ", 1)
    L[j:j + 1] = HDR_INIT + ["DiskScreens_InitSelectedEntry:"]
    L[k:k] = HDR_VEC + ["DiskScreens_PhaseVector:"]
    data = "\n".join(L).encode("latin-1")
    with open(SRC + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(SRC + ".tmp", SRC)
    print("prom_a: DiskScreens_PhaseVector and DiskScreens_InitSelectedEntry placed")


if __name__ == "__main__":
    check()
    if "--apply" in sys.argv:
        apply()
