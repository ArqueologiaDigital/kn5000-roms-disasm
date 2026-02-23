#!/usr/bin/env python3
"""Generate TableGen instruction definitions for 170 missing extended
addressing mode instructions.

Each mnemonic follows the naming convention:
    x_{FAMILY}{SIZE?}{BYTES_AFTER_PREFIX}_{S|O}{HEX}[_T{N}]

The script parses each name, determines the instruction class
(ExtAddrModeSuffixInst or ExtAddrModeOpImmInst), and emits the
corresponding TableGen definition ready to paste into
TLCS900InstrInfo.td.

Usage:
    python3 gen_missing_instrs.py
"""

import re
import sys
from collections import OrderedDict

# ── Family → Opcode mapping ────────────────────────────────────────
FAMILY_OPCODE = {
    "erp":  0xC7,
    "sri":  0xC3,
    "spi":  0xC5,
    "spd":  0xC4,
    "dri":  0xF3,
    "dpi":  0xF5,
    "dpd":  0xF4,
    "sd8":  0xC0,
    "dd8":  0xF0,
    "sd16": 0xC1,
    "dd16": 0xF1,
    "sd24": 0xC2,
    "dd24": 0xF2,
}

# Size-letter → OpSize TableGen value
SIZE_LETTER_MAP = {
    "b": "OpSize8",
    "w": "OpSize16",
    "l": "OpSize32",
}

# Families that are "dest" (opcode >= 0xF0) — no OpSize in output
DEST_FAMILIES = {name for name, opc in FAMILY_OPCODE.items() if opc >= 0xF0}

# Families sorted longest-first so greedy match works
FAMILIES_BY_LENGTH = sorted(FAMILY_OPCODE.keys(), key=len, reverse=True)

# ── Mnemonic parser ────────────────────────────────────────────────

def parse_mnemonic(name: str):
    """Parse a mnemonic name and return a dict with all extracted fields.

    Returns dict with keys:
        family, opcode, size_letter (or None), bytes_after_prefix,
        kind ('suffix' or 'opimm'), sub_opcode, trailing_bytes (0 for suffix)
    """
    # Strip the leading "x_"
    assert name.startswith("x_"), f"Unexpected mnemonic format: {name}"
    rest = name[2:]  # e.g. "dd163_s04" or "erpb3_o03_t1" or "sd16b3_s04"

    # Try to match each known family (longest first)
    family = None
    for fam in FAMILIES_BY_LENGTH:
        if rest.startswith(fam):
            family = fam
            rest = rest[len(fam):]
            break
    assert family is not None, f"No known family in mnemonic: {name}"

    # For source families (opcode < 0xF0), next char should be size letter
    size_letter = None
    if family not in DEST_FAMILIES:
        if rest and rest[0] in "bwl":
            size_letter = rest[0]
            rest = rest[1:]
        else:
            raise ValueError(
                f"Source family '{family}' requires size letter (b/w/l) but "
                f"got '{rest[0] if rest else ''}' in mnemonic: {name}"
            )

    # Next: bytes_after_prefix (one or more digits), then underscore
    m = re.match(r"(\d+)_(.*)", rest)
    assert m, f"Expected digits_suffix in '{rest}' for mnemonic: {name}"
    bytes_after_prefix = int(m.group(1))
    rest = m.group(2)  # e.g. "s04" or "o03_t1"

    # Parse suffix (s{hex}) or opimm (o{hex}_t{n})
    m_suffix = re.fullmatch(r"s([0-9a-f]{2})", rest)
    m_opimm = re.fullmatch(r"o([0-9a-f]{2})_t(\d+)", rest)

    if m_suffix:
        sub_opcode = int(m_suffix.group(1), 16)
        return {
            "name": name,
            "family": family,
            "opcode": FAMILY_OPCODE[family],
            "size_letter": size_letter,
            "bytes_after_prefix": bytes_after_prefix,
            "kind": "suffix",
            "sub_opcode": sub_opcode,
            "trailing_bytes": 0,
        }
    elif m_opimm:
        sub_opcode = int(m_opimm.group(1), 16)
        trailing_bytes = int(m_opimm.group(2))
        return {
            "name": name,
            "family": family,
            "opcode": FAMILY_OPCODE[family],
            "size_letter": size_letter,
            "bytes_after_prefix": bytes_after_prefix,
            "kind": "opimm",
            "sub_opcode": sub_opcode,
            "trailing_bytes": trailing_bytes,
        }
    else:
        raise ValueError(f"Cannot parse suffix/opimm from '{rest}' in: {name}")


# ── TableGen emitter ───────────────────────────────────────────────

def emit_definition(parsed: dict) -> str:
    """Emit a single TableGen instruction definition."""
    name = parsed["name"]
    upper_name = name.upper()
    lower_name = name.lower()

    opcode = parsed["opcode"]
    sub_opcode = parsed["sub_opcode"]
    bytes_after_prefix = parsed["bytes_after_prefix"]
    size = bytes_after_prefix + 1
    num_operands = bytes_after_prefix - 1

    # Build operand lists
    ins_list = ", ".join(f"i32imm:$b{i}" for i in range(num_operands))
    asm_operands = ", ".join(f"$b{i}" for i in range(num_operands))

    # OpSize line (only for source families)
    opsize_line = ""
    if parsed["size_letter"] is not None:
        opsize_name = SIZE_LETTER_MAP[parsed["size_letter"]]
        opsize_line = f"\n  let OpSize = {opsize_name}.Value;"

    lines = []

    if parsed["kind"] == "suffix":
        lines.append(
            f"def {upper_name} : ExtAddrModeSuffixInst<{size}, "
            f"0x{sub_opcode:02X}, (outs),"
        )
        lines.append(f"    (ins {ins_list}),")
        lines.append(f'    "{lower_name}", "{asm_operands}", []> {{')
        lines.append(f"  let Opcode = 0x{opcode:02X};{opsize_line}")
        lines.append("}")
    else:
        # OpImm
        trailing = parsed["trailing_bytes"]
        npreops = bytes_after_prefix - 1 - trailing
        lines.append(
            f"def {upper_name} : ExtAddrModeOpImmInst<{size}, "
            f"0x{sub_opcode:02X}, {npreops}, (outs),"
        )
        lines.append(f"    (ins {ins_list}),")
        lines.append(f'    "{lower_name}", "{asm_operands}", []> {{')
        lines.append(f"  let Opcode = 0x{opcode:02X};{opsize_line}")
        lines.append("}")

    return "\n".join(lines)


# ── Main ───────────────────────────────────────────────────────────

MNEMONICS = """
x_dd163_s04, x_dd163_s06, x_dd163_s2c, x_dd163_s9c, x_dd163_s9f,
x_dd163_sa8, x_dd163_sa9, x_dd163_saa, x_dd163_sab, x_dd163_sac,
x_dd163_sad, x_dd163_sae, x_dd163_saf, x_dd246_o14_t2, x_dd246_o16_t2,
x_dd82_s31, x_dd82_s33, x_dd82_s41, x_dd82_s9c, x_dd82_s9e,
x_dd82_sb0, x_dd82_sb1, x_dd82_sb2, x_dd82_sb3, x_dd82_sb8,
x_dd82_sb9, x_dd82_sba, x_dd82_sbb, x_dd82_sc8, x_dd82_sc9,
x_dd82_sca, x_dd82_scb, x_dd82_scd, x_dd82_sce, x_dpd3_o00_t1,
x_dpi2_s31, x_dpi2_s32, x_dpi2_s33, x_dpi2_s34, x_dpi2_s35,
x_dpi2_s40, x_dpi2_s41, x_dpi2_s42, x_dpi2_s43, x_dpi2_s45,
x_dpi2_s47, x_dpi2_s50, x_dpi2_s51, x_dpi2_s52, x_dpi2_s54,
x_dpi2_s55, x_dpi2_s60, x_dpi2_s61, x_dpi2_s63, x_dpi2_s64,
x_dpi3_o00_t1, x_dpi4_o02_t2, x_dri4_s98, x_dri4_s9a, x_dri4_s9f,
x_dri4_sb4, x_dri4_sb7, x_dri4_sbd, x_dri4_sbe, x_dri4_sc8,
x_dri4_sc9, x_dri4_sca, x_dri4_scb, x_dri4_scc, x_dri4_scd,
x_dri4_sce, x_dri4_scf, x_dri4_sd8, x_dri5_o00_t1, x_dri6_o02_t2,
x_dri6_o14_t2, x_dri6_o16_t2, x_erpb3_o03_t1, x_erpb3_o09_t1,
x_erpb3_o30_t1, x_erpb3_o31_t1, x_erpb3_o33_t1, x_erpb3_oc8_t1,
x_erpb3_oca_t1, x_erpb3_occ_t1, x_erpb3_oce_t1, x_erpb3_ocf_t1,
x_erpb3_oef_t1, x_erpl6_oc8_t4, x_erpw3_o33_t1, x_erpw3_oef_t1,
x_erpw4_o03_t2, x_erpw4_oc8_t2, x_erpw4_oce_t2, x_erpw4_ocf_t2,
x_sd16b3_s04, x_sd16b3_s30, x_sd16b3_s41, x_sd16b3_s43, x_sd16b3_s7c,
x_sd16w3_s04, x_sd16w3_s48, x_sd24b6_o19_t2, x_sd24w4_s04,
x_sd24w6_o19_t2, x_sd8b2_s21, x_sd8b2_s23, x_sd8b3_o3c_t1,
x_sd8b3_o3e_t1, x_spib3_o3f_t1, x_srib4_s61, x_srib4_s69,
x_srib4_s88, x_srib4_s89, x_srib4_sa9, x_srib4_sc1, x_srib4_sc9,
x_srib4_sd1, x_srib4_se1, x_srib4_se3, x_srib4_se9, x_srib4_seb,
x_srib4_sf1, x_srib4_sf3, x_srib4_sf5, x_srib4_sf8, x_srib4_sf9,
x_srib4_sfb, x_srib4_sfd, x_srib4_sff, x_srib5_o3a_t1,
x_srib5_o3c_t1, x_srib5_o3e_t1, x_srib5_o3f_t1, x_srib6_o19_t2,
x_sril4_s80, x_sril4_s82, x_sril4_s83, x_sril4_s84, x_sril4_s85,
x_sril4_s86, x_sril4_s88, x_sril4_sab, x_sril4_sf0, x_sril4_sf1,
x_sril4_sf3, x_sril4_sf8, x_sril4_sfe, x_sriw4_s04, x_sriw4_s30,
x_sriw4_s61, x_sriw4_s68, x_sriw4_s6a, x_sriw4_s81, x_sriw4_s84,
x_sriw4_s88, x_sriw4_sa0, x_sriw4_sc0, x_sriw4_sc2, x_sriw4_se0,
x_sriw4_se2, x_sriw4_sf0, x_sriw4_sf2, x_sriw4_sf6, x_sriw4_sfb,
x_sriw6_o19_t2, x_sriw6_o3f_t2
""".strip()


def main():
    # Parse the comma-separated list
    names = [n.strip() for n in MNEMONICS.replace("\n", " ").split(",")]
    names = [n for n in names if n]  # drop empties

    print(f"// === Auto-generated extended addressing mode instructions ===")
    print(f"// Generated by scripts/gen_missing_instrs.py")
    print(f"// {len(names)} instruction definitions")
    print()

    # Group by family for organized output
    by_family = OrderedDict()

    for name in names:
        parsed = parse_mnemonic(name)
        fam = parsed["family"]
        if fam not in by_family:
            by_family[fam] = []
        by_family[fam].append(parsed)

    # Emit grouped by family
    for family, entries in by_family.items():
        opc = FAMILY_OPCODE[family]
        print(f"// --- {family.upper()} (base opcode 0x{opc:02X}) ---")
        for parsed in entries:
            print(emit_definition(parsed))
        print()


if __name__ == "__main__":
    main()
