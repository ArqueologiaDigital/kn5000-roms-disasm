#!/usr/bin/env python3
"""Do the three BY-NAME exemptions in the .incbin audit still deserve them?

`audit_incbin_legitimacy.py` skips three blobs that score as PTR_TABLE, each with
a written reason. A by-name exemption is exactly the kind of thing that keeps
passing after it stops being true, so this re-derives each reason from the bytes
and FAILS if one no longer holds.

  sound_data_organ_accordion.bin  -- claim: u16 pairs, so u32 reads like
      0x00f000f0 and lands in ROM range by coincidence.
      TEST: read the blob as u16 and require every value to have a ZERO HIGH
      BYTE (i.e. 0x00NN). That is what makes the u32 view read as 0x00NN00NN,
      which lands in 0xE00000..0xFFFFFF for any NN >= 0xE0 -- the coincidence
      the exemption claims. ⚠ An earlier version of this test demanded that the
      two halves of each u32 be EQUAL and reported 63/64 "exemption no longer
      holds". The odd word is 0x00f2,0x00f0 -- two different u16s, which is
      still a u16 pair. The test was wrong, not the exemption.
  v7_transplant_FlashWrite_BlockRef_Type{3,4}.bin -- claim: 5 words, only 2 hit
      an actual symbol; landing in the address RANGE is much weaker evidence
      than pointing AT something.
      TEST: fewer than 3 of the 5 words may match an ELF symbol address.

Run:  python3 scripts/analysis/verify_ptr_table_exemptions.py
Exit non-zero if any exemption no longer holds.
"""
import glob, os, pathlib, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
fails = []


def words(p):
    b = open(p, "rb").read()
    return [struct.unpack("<I", b[i:i + 4])[0] for i in range(0, len(b) - 3, 4)]


for p in sorted(glob.glob("*/maincpu/includes/generated/sound_data_organ_accordion.bin")):
    b = open(p, "rb").read()
    u16 = [struct.unpack("<H", b[i:i + 2])[0] for i in range(0, len(b) - 1, 2)]
    small = sum(1 for v in u16 if v <= 0xFF)
    ok = small == len(u16)
    print(f"  {p}")
    print(f"    u16 values with a zero high byte: {small}/{len(u16)}"
          f"   {'OK' if ok else '*** EXEMPTION NO LONGER HOLDS'}")
    if not ok:
        fails.append(p)

# Use the project's own symbol reader rather than shelling out to llvm-nm,
# which is not on PATH here. ⚠ An earlier draft fell back to "test skipped"
# when the ELF was missing -- i.e. it would have PASSED without testing. A
# check that silently degrades to a pass is worse than one that crashes.
elf = "rebuilt_ROMs/kn5000_v7_program.llvm.elf"
import importlib.util
_s = importlib.util.spec_from_file_location(
    "cc", os.path.join(REPO, "scripts/converters/convert_corroborated_blocks.py"))
cc = importlib.util.module_from_spec(_s); _s.loader.exec_module(cc)
if not os.path.exists(elf):
    sys.exit(f"FAIL: {elf} missing -- cannot test the transplant exemptions")
symaddrs = set(cc.elf_syms(elf))          # elf_syms returns {addr: name}

for p in sorted(glob.glob("v7/maincpu/includes/romslices/v7_transplant_FlashWrite_BlockRef_Type[34].bin")):
    w = words(p)
    hits = sum(1 for x in w if x in symaddrs)
    ok = hits < 3
    print(f"  {p}")
    print(f"    words matching an ELF symbol ADDRESS: {hits}/{len(w)}"
          f"   {'OK' if ok else '*** EXEMPTION NO LONGER HOLDS'}"
          )
    if not ok:
        fails.append(p)

print()
if fails:
    print(f"FAIL: {len(fails)} exemption(s) no longer justified")
    sys.exit(1)
print("PASS: every by-name PTR_TABLE exemption still holds on the bytes")
