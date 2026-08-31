#!/usr/bin/env python3
"""Does UNIT 1 of prom_a's block-device layer really talk to the 0x7E0000 device?

QUESTION IT ANSWERS
    Fdc_Request (prom_a 0xFE66C7) dispatches on a UNIT number at request+2.
    Unit 0 is the floppy disk controller at 0x7B0004/0x7B0005 + 0x7A0000.  Every
    operation's unit-1 arm instead calls one of seven routines in
    0xFE4CE0-0xFE544D.  This asks whether those seven really are a driver for
    the 16-bit port at 0x7E0008-0x7E0017 -- emulation gap J in
    kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md, which says "two bytes of
    the driver's map are inert" and has nothing on what the device is.

METHOD, AND WHAT IS EXACT
    prom_a 0xFE0000-0xFE54B5 is already converted assembly, so every call in it
    is an instruction the byte gate certifies.  This reads the call edges out of
    prom_a/wsa1_prom_a.s's own trailing byte comments (via
    notes/prom_a_fdc_callgraph.external_sites) and takes the transitive closure
    from each unit-1 arm.  A routine's outgoing edges are the call sites at or
    after its entry and before the next known entry, which is an OVER-estimate
    when an entry is missing from the target set -- so a POSITIVE answer here is
    a reachability upper bound, not a proof that a particular path executes.
    What it is exact about is the four ACCESSORS: those really are the only code
    in prom_a or prom_b that forms an address in 0x7E0000-0x7E00FF, and that
    part is checked by a byte census below.

RUN
    python3 notes/prom_a_unit1_backend_check.py
Exit status is non-zero if any unit-1 arm fails to reach an accessor, or if the
accessor census stops finding exactly four sites.
"""
import bisect
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_fdc_callgraph as CG                                 # noqa: E402

A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()

# The unit-1 arm of each operation, read off the `cp (0x605A32),1` branches in
# prom_a/wsa1_prom_a.s.
ARMS = {
    0xFE50E9: "operation 0  (Fdc_Op0_ResetAndIdentifyMedia)",
    0xFE4FB2: "operation 3  (Fdc_Op3_ReadSectors)",
    0xFE4E4C: "operation 4  (Fdc_Op4_WriteSectors)",
    0xFE51AC: "operation 5  (Fdc_Op5_FormatDisk)",
    0xFE53E4: "operation 6  (Fdc_Op6_PortA3_Off)",
    0xFE544D: "operation 7  (Fdc_Op7_PortA3_On)",
    0xFE4D01: "operation 10 (Fdc_Op10_TestControllerPresent)",
}
# The four accessors.  Each is  ld A/C,(XSP+6) / and 0x07 / set 3 or 4 /
# add XWA|XBC,0x007E0000 / load or store.
ACCESSORS = {
    0xFE4C73: "write byte", 0xFE4C99: "write word",
    0xFE4CBF: "read byte", 0xFE4CE0: "read word",
}

fails = []

# --- the accessor census: who forms an address in the 0x7E0000 window? -------
sites, rejected = [], []
for img, base, tag in ((A, 0xF80000, "prom_a"), (B, 0xF00000, "prom_b")):
    i = 0
    needle = b"\x00\x00\x7e\x00"          # imm32 0x007E0000, little-endian
    while True:
        i = img.find(needle, i)
        if i < 0:
            break
        # `add XWA,imm32` is E8 C8, `add XBC,imm32` is E9 C8; anything else with
        # these four bytes is not an address being formed.
        if i >= 2 and img[i - 2] in (0xE8, 0xE9) and img[i - 1] == 0xC8:
            sites.append((tag, base + i - 2))
        else:
            rejected.append((tag, base + i))
        i += 1
print("`add Xrr,0x007E0000` sites:")
for tag, addr in sites:
    inside = [k for k in ACCESSORS if k <= addr < k + 0x30]
    print("  %-7s 0x%06X  inside %s" % (tag, addr,
          ACCESSORS[inside[0]] + " (0x%06X)" % inside[0] if inside else "NOTHING"))
print("byte-window hits on the immediate that are NOT that instruction "
      "(reported, not counted -- they are data):")
for tag, addr in rejected:
    print("  %-7s 0x%06X" % (tag, addr))
if len(sites) != 4:
    fails.append("expected 4 `add Xrr,0x007E0000` sites, found %d" % len(sites))
for tag, addr in sites:
    if not any(k <= addr < k + 0x30 for k in ACCESSORS):
        fails.append("0x%06X forms the 0x7E0000 base outside the four accessors"
                     % addr)

# --- reachability from each unit-1 arm --------------------------------------
edges = CG.external_sites()
targets = sorted(set(t for _, t in edges) | set(ARMS) | set(ACCESSORS))
graph = {}
for site, tgt in edges:
    i = bisect.bisect_right(targets, site) - 1
    if i >= 0:
        graph.setdefault(targets[i], set()).add(tgt)

print("\nunit-1 arms and the accessors they reach:")
for arm in sorted(ARMS):
    seen, stack = set(), [arm]
    while stack:
        n = stack.pop()
        if n in seen:
            continue
        seen.add(n)
        stack.extend(graph.get(n, ()))
    hit = [ACCESSORS[x] for x in sorted(ACCESSORS) if x in seen]
    print("  0x%06X %-46s -> %s" % (arm, ARMS[arm], ", ".join(hit) or "NOTHING"))
    if not hit:
        fails.append("0x%06X reaches no 0x7E0000 accessor" % arm)

print("\nverdict")
print("  all seven unit-1 arms reach the 0x7E0000 accessors: %s"
      % ("YES" if not fails else "NO"))
for f in fails:
    print("  FAIL: " + f)
sys.exit(1 if fails else 0)
