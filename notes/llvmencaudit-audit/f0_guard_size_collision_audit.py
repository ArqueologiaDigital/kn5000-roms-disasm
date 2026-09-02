#!/usr/bin/env python3
"""f0_guard_size_collision_audit.py -- does the `Opcode < 0xF0` size-adjustment
guard in TLCS900MCCodeEmitter.cpp leave any fixed-prefix (>=0xF0) instruction
family emitting BYTE-IDENTICAL encodings for two different operand sizes?

WHY THIS SCRIPT EXISTS
  DEBT-INVENTORY-2026-09-02.md (item 6, "Where the next pass should aim")
  reports ST_RRW/ST_RRL as "documented as encoding byte-identically to
  ST_RRB" and calls it a live, unresolved encoder bug: "the ENCODER may be
  losing size information today."

  That text describes the tree as it stood BEFORE llvm-project@1b9432474daa
  ("[TLCS900] Fix two silently-wrong sub-opcodes in the F3 memory forms",
  2026-08-22 16:25:51 +0100) -- which predates the debt-inventory note by
  eleven days. On the current tlcs900_backend tip (ad8129f59880) the
  collision does not exist: ST_RRB/W/L carry SubOpc 0x40/0x50/0x60
  respectively, spelled out explicitly in TLCS900InstrInfo.td because the
  emitter's `Prefix += OpSize * 0x10` adjustment is skipped whenever
  Opcode >= 0xF0 (SriRRReg's prefix is fixed at 0xF3).

  This script is the byte evidence for that claim -- per this backend's own
  rule, "llvm-mc accepted it" is not evidence, only a byte comparison is.
  It also audits every OTHER family that shares the same fixed->=0xF0 prefix
  shape, in case some other family still has the bug the debt-inventory note
  described.

WHAT IT CHECKS
  For every family below (all of the TableGen instruction FORMATS that
  contain the `if (Opcode < 0xF0) Prefix += OpSize * 0x10;` guard in
  TLCS900MCCodeEmitter.cpp, restricted to the defs that are actually
  instantiated at a literal Opcode >= 0xF0 with more than one OpSize), it
  assembles one instance per size and asserts the encoded bytes differ.

RUN
    python3 notes/llvmencaudit-audit/f0_guard_size_collision_audit.py
    python3 notes/llvmencaudit-audit/f0_guard_size_collision_audit.py --selftest

  LLVM_MC defaults to this checkout's shared toolchain build; override with
  the environment variable of the same name to point at another build.

--selftest deliberately re-injects the pre-fix shape (three sizes sharing
one sub-opcode under a >=0xF0 prefix, by asking for the SAME mnemonic
three times) so the "assert distinct" logic is proven capable of failing,
not just capable of passing.
"""
import os
import subprocess
import sys

LLVM_MC = os.environ.get(
    "LLVM_MC",
    os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc"),
)

# Every group below shares one fixed prefix >= 0xF0 across >1 OpSize variant,
# using one of the formats gated by `if (Opcode < 0xF0)` in
# TLCS900MCCodeEmitter.cpp (ExtAddrModeSuffix/OpImm, ERPReg/SmallImm/Unary/
# ImmAfter, PIReg/Unary, RIReg/Unary/ImmAfter, SriD16Reg, SriRR*, D8Reg/Unary/
# ImmAfter, ExtImmMod, RIImmMod -- TLCS900MCCodeEmitter.cpp:1081-1514).
# PIReg/PIUnary have zero live instantiations anywhere in TLCS900InstrInfo.td
# (grep confirmed) so they carry no encoder risk and are not listed here.
GROUPS = {
    "SriRRReg / ST_RR* (F3, the family the debt-inventory note names)": [
        "st_rrb a, xbc, wa",
        "st_rrw wa, xbc, wa",
        "st_rrl xwa, xbc, wa",
    ],
    "SriRR8Reg / ST_RR8* (F3, 8-bit index)": [
        "st_rr8b a, xbc, w",
        "st_rr8w wa, xbc, w",
        "st_rr8l xwa, xbc, w",
    ],
    "D8Reg / ST_DD8* (F0)": [
        "st_dd8b a, 0x12",
        "st_dd8w wa, 0x12",
        "st_dd8l xwa, 0x12",
    ],
    "RIReg / ST_DRI3* (F3, DRI addressing)": [
        "stb_dri a, 0x12, 0x34, 0x56",
        "stw_dri wa, 0x12, 0x34, 0x56",
        "stl_dri xwa, 0x12, 0x34, 0x56",
    ],
    "ERPReg / ST_DPI* (F5, post-increment)": [
        "stb_dpi a, 0x03",
        "stw_dpi wa, 0x03",
        "stl_dpi xwa, 0x03",
    ],
    "ERPReg / ST_DPD* (F4, pre-decrement)": [
        "st_dpdb a, 0x03",
        "st_dpdw wa, 0x03",
        "st_dpdl xwa, 0x03",
    ],
}

# Sanity control: LD_RR* shares prefix 0xC3 (< 0xF0), so the guard DOES apply
# and the prefix byte itself should carry the size (C3/D3/E3). This is the
# "does the guard even matter here" negative control -- these must ALSO
# differ, but via byte 0 rather than the last byte.
CONTROL_GROUP = (
    "LD_RR* (C3, prefix < 0xF0 -- adjustment applies automatically)",
    ["ld_rrb a, xbc, wa", "ld_rrw wa, xbc, wa", "ld_rrl xwa, xbc, wa"],
)


def encode(line: str) -> bytes:
    p = subprocess.run(
        [LLVM_MC, "-triple=tlcs900", "-show-encoding"],
        input=line + "\n",
        capture_output=True,
        text=True,
        check=True,
    )
    out = p.stdout.strip()
    marker = "encoding: ["
    i = out.index(marker) + len(marker)
    j = out.index("]", i)
    return bytes(int(b, 16) for b in out[i:j].split(","))


def check_group(name: str, insns: list[str]) -> bool:
    encodings = [(insn, encode(insn)) for insn in insns]
    seen = {}
    ok = True
    print(f"\n{name}")
    for insn, enc in encodings:
        print(f"    {insn:32s} -> {enc.hex(' ')}")
        if enc in seen:
            print(f"    COLLISION: identical to {seen[enc]!r}")
            ok = False
        seen[enc] = insn
    print("  " + ("PASS: all distinct" if ok else "FAIL: collision found"))
    return ok


def main() -> int:
    selftest = "--selftest" in sys.argv
    all_ok = True

    for name, insns in GROUPS.items():
        all_ok &= check_group(name, insns)

    name, insns = CONTROL_GROUP
    all_ok &= check_group(name, insns)

    if selftest:
        # Reproduce the PRE-FIX shape: three sizes, same mnemonic (so same
        # sub-opcode+reg byte), fixed >=0xF0 prefix. st_rrb/st_rrb/st_rrb is
        # of course three IDENTICAL lines, not three sizes -- that's the
        # point: it proves check_group() actually reports a collision
        # instead of vacuously passing when handed a real one.
        print("\n--selftest: deliberately-colliding input (must FAIL)")
        induced_ok = check_group(
            "induced collision (same insn 3x, simulating a shared sub-opcode)",
            ["st_rrb a, xbc, wa", "st_rrb a, xbc, wa", "st_rrb a, xbc, wa"],
        )
        if induced_ok:
            print("SELFTEST FAILED: the collision detector did not fire.")
            return 1
        print("SELFTEST OK: the collision detector fires on a real collision.")

    print()
    if all_ok:
        print("PASS: no ST_RR*/ST_DD8*/ST_DRI3*/ST_DPI*/ST_DPD* size collision "
              "exists on the current tree.")
        return 0
    else:
        print("FAIL: a real size collision was found. See above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
