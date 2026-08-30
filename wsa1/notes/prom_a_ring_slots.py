#!/usr/bin/env python3
"""Which prom_b directory slot publishes each ring-buffer `_Get` veneer?

QUESTION IT ANSWERS: "the fifteen `Ring*_Get` group headers in prom_a each say
`Called from: prom_b directory slot T_XXXXXX`.  Is that this group's slot, or
somebody else's?"

WHY IT EXISTS.  Round-2 audit F9.  All fifteen headers used to carry the same
`Called from: the prom_b directory, module T_F41CD0-T_F41EC4` text, and the
call-site auditor reported the first address in it, 0xF41CD0, as unresolved for
twelve of them -- correctly: 0xF41CD0 is `jp 0xf842df`, which is Ring608A0A_Get
and nobody else.  A range is not a call site, and a copied header is not a
citation.  This script derives the slot for each veneer straight from the ROM.

METHOD (no source-file parsing for the answer, only for the claim):
  * a prom_b directory slot is `1B lo mid hi` = `jp 0x00hhmmll` at a 4-byte
    stride in 0xF40000-0xF44018 (notes/FINDINGS-prom_b-thunk-table.md);
  * scan every slot, build target -> [slots];
  * take each `Ring*_Get` label's address from its own `; ADDR` comment in
    prom_a/wsa1_prom_a.s (the file is byte-verified, so the comment is the
    address) and look the target up.

    python3 notes/prom_a_ring_slots.py            # the table
    python3 notes/prom_a_ring_slots.py --checks   # assertions, exit 1 on failure
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018
B_BASE = 0xF00000

# What the fifteen headers now claim, and what the audit says reaches each slot.
CLAIM = {
    "Ring608A0A_Get":      (0xF41CD0, 0xF842DF),
    "Ring60480A_Get":      (0xF41CF4, 0xF84382),
    "Ring601B64_Get":      (0xF41D3C, 0xF84425),
    "Ring60000C_Get":      (0xF41E80, 0xF844C8),
    "Ring60080A_Get":      (0xF41D60, 0xF8456B),
    "Ring600A14_Get":      (0xF41D84, 0xF8460E),
    "Ring600C1E_Get":      (0xF41DA8, 0xF846B1),
    "Ring601028_Get":      (0xF41DCC, 0xF84754),
    "Ring601432_Get":      (0xF41DF0, 0xF847F7),
    "Ring60153C_Get":      (0xF41E14, 0xF8489A),
    "Ring60195A_Get":      (0xF41D18, 0xF8493D),
    "Ring601646_Get":      (0xF41E38, 0xF849E0),
    "Ring601C6E_Get":      (0xF41EA4, 0xF84A83),
    "Ring601850_Get":      (0xF41E5C, 0xF84B26),
    "Ring601850_Copy_Get": (None,     0xF84BC9),   # ★ no slot at all
}


def slot_map():
    """target address -> sorted list of directory slots that `jp` to it."""
    out = {}
    for a in range(THUNK_LO, THUNK_HI, 4):
        o = a - B_BASE
        if B[o] != 0x1B:
            continue
        t = B[o + 1] | (B[o + 2] << 8) | (B[o + 3] << 16)
        out.setdefault(t, []).append(a)
    return out


def label_addrs():
    """label -> address, from the byte-verified `; ADDR` comment after it."""
    out, pend = {}, []
    for line in open(SRC, encoding="utf-8"):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
        if m:
            pend.append(m.group(1))
            continue
        m = re.search(r";\s([0-9A-F]{6})\b", line)
        if m and pend:
            for n in pend:
                out.setdefault(n, int(m.group(1), 16))
            pend = []
    return out


FAILS, RAN = [], []


def check(name, cond, detail=""):
    RAN.append(name)
    if not cond or "-v" in sys.argv:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


def main():
    sm = slot_map()
    la = label_addrs()
    checks = "--checks" in sys.argv
    if not checks:
        print("%-22s %-9s %-10s %s" % ("veneer", "address", "slot", "other slots"))
    names = list(CLAIM)
    for name in names:
        want_slot, want_addr = CLAIM[name]
        addr = la.get(name)
        slots = sm.get(addr, []) if addr is not None else []
        if not checks:
            print("%-22s 0x%06X  %-10s %s" % (
                name, addr or 0, ("T_%06X" % slots[0]) if slots else "-none-",
                ", ".join("T_%06X" % s for s in slots[1:]) or "-"))
            continue
        check("%s label is at 0x%06X" % (name, want_addr), addr == want_addr,
              "0x%06X" % (addr or 0))
        if want_slot is None:
            check("%s has NO directory slot" % name, slots == [],
                  ", ".join("T_%06X" % s for s in slots))
        else:
            check("%s is published by T_%06X and by that slot only" % (name, want_slot),
                  slots == [want_slot], ", ".join("T_%06X" % s for s in slots) or "none")
    if not checks:
        return 0

    # The error this script exists for: 0xF41CD0 belongs to exactly one veneer.
    t = B[0xF41CD0 - B_BASE + 1] | (B[0xF41CD0 - B_BASE + 2] << 8) | \
        (B[0xF41CD0 - B_BASE + 3] << 16)
    check("0xF41CD0 is `jp 0xF842DF`, i.e. Ring608A0A_Get and nobody else",
          B[0xF41CD0 - B_BASE] == 0x1B and t == 0xF842DF, "0x%06X" % t)
    check("the fifteen veneers claim fifteen DISTINCT slots (one of them: none)",
          len({v[0] for v in CLAIM.values()}) == 15, "")

    # LAST-ELEMENT test: the last veneer in the table, spelled out.
    last = names[-1]
    check("LAST entry %s: address 0x%06X, zero slots" % (last, CLAIM[last][1]),
          la.get(last) == 0xF84BC9 and sm.get(0xF84BC9, []) == [],
          "addr 0x%06X slots %s" % (la.get(last, 0), sm.get(0xF84BC9, [])))

    print("\n%d checks, %d FAILED" % (len(RAN), len(FAILS)))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
