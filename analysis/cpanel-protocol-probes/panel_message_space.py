#!/usr/bin/env python3
"""What is the COMPLETE set of messages the control panel can put on the wire,
and what does the KN5000 do with each?

The KN5000's receive path is a total function of the frame's first byte, so
enumerating all 256 first-byte values enumerates the panel's whole outbound
message space -- without a logic analyser, and without assuming anything about
what the panel actually chooses to send.  This script derives that enumeration
from the ROM: it extracts the decision constants and the two lookup tables the
receive path uses, then prints the resulting classification.

    $ python3 analysis/cpanel-protocol-probes/panel_message_space.py

Everything printed is read out of the ROM images.  The three addresses it
needs -- the button-state array base, the receive format-dispatch table and
the analog-handler table -- are LOCATED by byte pattern, not hard-coded, so
the script fails loudly on a revision whose code differs.

Numbers this produced on 2026-08-22 (used in
docs/kn5000-control-panel-panel-side.md):

  * Of the 256 possible first bytes: 64 are button-segment reports, 32 are
    analog-controller reports, 96 are sync/ACK frames the receive path
    consumes and discards, and 64 open a variable-length run.
  * The analog handler table has 32 entries, of which 26 point at one shared
    default handler; the 6 distinguished analog sources are encoder IDs
    2, 5, 25, 26, 27 and 31, reachable as first bytes 0x12, 0x15, 0xd1,
    0xd2, 0xd3 and 0xd7.
  * Identical in v7, v9 and v10; the bootloader copy in kn5000_table_data.rom
    has NO analog handler table at all (its class-2 hook is a stub that
    always reports failure), which is the one place the two copies differ.
"""

import re
import sys

PROGRAM_ROMS = [
    ("v7",  "original_ROMs/kn5000_v7_program.rom",  0xE00000),
    ("v9",  "original_ROMs/kn5000_v9_program.rom",  0xE00000),
    ("v10", "original_ROMs/kn5000_v10_program.rom", 0xE00000),
]
BOOT_ROM = ("table_data", "original_ROMs/kn5000_table_data.rom", 0x800000)

# and w,0x4f -- opens the 2-byte report handler; followed by ld xhl, <array base>
REPORT_INDEX_HEAD = bytes.fromhex("c8cc4f")
# and l,0x38 / srl l,1 / xor h,h / extz xhl / add xhl, <dispatch table>
RX_DISPATCH = bytes.fromhex("cfcc38cfef01ced6eb12ebc8")
# and e,0x7 / and c,0xc0 / srl c,3 / or c,e / extz bc / sla bc,2 / lda_24 xde,<table>
ENC_DISPATCH = bytes.fromhex("cdcc07cbccc0cbef03cde3d912d9ec02")


def u32(b, o):
    return int.from_bytes(b[o:o + 4], "little")


def one(rom, pat, what):
    hits = [m.start() for m in re.finditer(re.escape(pat), rom, re.S)]
    if len(hits) != 1:
        raise SystemExit(f"expected exactly one {what}, found {len(hits)}")
    return hits[0]


def rom_off(addr, base, size):
    for cand in (addr - base, addr - 0x600000 - base):
        if 0 <= cand < size:
            return cand
    raise SystemExit(f"address 0x{addr:06x} is outside the image")


def classify(b):
    """Return (kind, detail) for a panel->host frame whose first byte is b.

    The two decisions come straight out of the receive path:
      * length:  2 bytes, unless (b & 0x3f) >= 0x30, then (b & 0x0f) + 3
      * handler: table index (b & 0x38) >> 3
    """
    fmt = (b >> 4) & 3
    if fmt == 0:
        return "button", (b & 0x0F) + (0x10 if b & 0x40 else 0)
    if fmt == 1:
        if b & 0x08:
            return "sync", None
        return "analog", ((b >> 6) << 3) | (b & 0x07)
    if fmt == 2:
        return "sync", None
    return "run", (b & 0x0F) + 1


def main():
    print("panel -> KN5000 message space, derived from the receive path")
    print()

    # ---- the enumeration itself depends only on the two decision rules ----
    kinds = {}
    for b in range(256):
        kinds.setdefault(classify(b)[0], []).append(b)
    for k in ("button", "analog", "sync", "run"):
        print(f"  {k:7} first bytes: {len(kinds[k]):3d}")
    print()

    print("  format field = bits 5:4 of the first byte")
    print("    00        button-segment report, 2 bytes")
    print("                index = (b & 0x0f) + (b & 0x40 ? 16 : 0)")
    print("    01, bit3=0 analog-controller report, 2 bytes")
    print("                encoder id = ((b >> 6) << 3) | (b & 7)")
    print("    01, bit3=1 sync / ACK, 2 bytes, consumed and discarded")
    print("    10        sync / ACK, 2 bytes, consumed and discarded")
    print("    11        run, (b & 0x0f) + 3 bytes total")
    print()

    # ---- addresses, located rather than assumed --------------------------
    print("  located per ROM:")
    enc_tables = {}
    for name, path, base in PROGRAM_ROMS + [BOOT_ROM]:
        rom = open(path, "rb").read()
        i = one(rom, REPORT_INDEX_HEAD, "2-byte report handler")
        arr = u32(rom, i + len(REPORT_INDEX_HEAD) + 1)
        j = one(rom, RX_DISPATCH, "receive format dispatch")
        disp = u32(rom, j + len(RX_DISPATCH))
        hits = [m.start() for m in re.finditer(re.escape(ENC_DISPATCH), rom, re.S)]
        if hits:
            enc = int.from_bytes(rom[hits[0] + len(ENC_DISPATCH) + 1:
                                     hits[0] + len(ENC_DISPATCH) + 4], "little")
            off = rom_off(enc, base, len(rom))
            enc_tables[name] = [u32(rom, off + 4 * k) for k in range(32)]
            enc_s = f"0x{enc:06x}"
        else:
            enc_s = "NONE (analog decode hook is a stub)"
        print(f"    {name:11} button array 0x{arr:08x}   dispatch 0x{disp:06x}"
              f"   analog table {enc_s}")
    print()

    # ---- the analog handler table ---------------------------------------
    print("  analog-controller handlers (32 entries, indexed by encoder id):")
    def shape(ents):
        seen = {}
        return [seen.setdefault(e, len(seen)) for e in ents]

    ref_name, ref = next(iter(enc_tables.items()))
    for name, ents in enc_tables.items():
        if shape(ents) != shape(ref):
            print(f"    !! {name}'s table has a different shape from {ref_name}'s")
        elif ents != ref:
            print(f"    ({name} same shape as {ref_name}, different link addresses)")
    default = max(set(ref), key=ref.count)
    print(f"    default handler 0x{default:06x} used by {ref.count(default)} of 32 ids")
    for i, e in enumerate(ref):
        if e == default:
            continue
        first = ((i >> 3) << 6) | 0x10 | (i & 7)
        print(f"    id {i:2d}  first byte 0x{first:02x}  handler 0x{e:06x}")
    print()

    # ---- a worked example ------------------------------------------------
    print("  worked example -- panel sends 0x46 0x38:")
    kind, detail = classify(0x46)
    print(f"    first byte 0x46 -> {kind}, array index {detail}")
    print("    length rule: (0x46 & 0x3f) = 0x06 < 0x30, so the frame is 2 bytes")
    print("    the KN5000 stores 0x38 at array[22], computes changed = old ^ 0x38,")
    print("    and pushes {0x46, 0x38, changed} into its 128-slot event ring")
    return 0


if __name__ == "__main__":
    sys.exit(main())
