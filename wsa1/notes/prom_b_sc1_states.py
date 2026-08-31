#!/usr/bin/env python3
"""The SC1 state machine: table extent, index -> label map, and reachable states.

QUESTION IT ANSWERS
    Round-1 audit finding F16 flagged 25 SC1_* labels as resting only on the
    module's section banner.  The worst of those are the state handlers: the
    group header above them describes entries "[0]".."[10]" in prose but never
    says WHICH LABEL is which entry, so the reader cannot check the mapping and
    neither could I.  This script derives it instead of typing it:

      1. SC1_StateTable's entry count, from the table's own bounds;
      2. for each entry, the label that the .s puts at the target address;
      3. every state value the firmware ever WRITES to (0x2A80), read off the
         verified transcription's instruction comments, plus the inc/dec sites
         that step it;
      4. which exit stub each handler ends at.

WHAT IT DOES NOT ESTABLISH
    Not what any state MEANS at the pins.  Not that 11 is the count the
    designer intended -- the dispatch does NO bounds check (see --dispatch), so
    the table's extent rests on abutment with INTTX1_SC1_Dispatch, nothing more.

RUN
    python3 notes/prom_b_sc1_states.py              # the table, mapped
    python3 notes/prom_b_sc1_states.py --writes     # who writes (0x2A80)
    python3 notes/prom_b_sc1_states.py --dispatch   # the dispatch, byte by byte
    python3 notes/prom_b_sc1_states.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")
B_BASE = 0xF00000

TABLE = 0xF5AC67          # named by `add XHL,0x00f5ac67` in both dispatchers
TABLE_END = 0xF5AC93      # = INTTX1_SC1_Dispatch, vector 0x6C's target

# The module's THREE dispatch tables, all built the same way: an index derived
# from a byte with a mask and a shift, used UNSHIFTED as a byte offset into a
# run of 32-bit pointers.  (name, base, end, the instruction that names it)
TABLES = [
    ("SC1_StateTable",  0xF5AC67, 0xF5AC93,
     "add XHL,0x00f5ac67 at 0xF5AC9E and 0xF5ACC6; index = (0x2A80) itself"),
    ("SC1_RxOpTable",   0xF5B0B5, 0xF5B0D5,
     "add XHL,0x00f5b0b5 at 0xF5B0AB; index = (byte & 0x38) >> 1"),
    ("SC1_TxOpTable",   0xF5B299, 0xF5B2A9,
     "add XHL,0x00f5b299 at 0xF5B28F; index = (byte & 0x30) >> 2"),
]
STATE_VAR = 0x2A80


def rom():
    return open(IMG, "rb").read()


def entries(b):
    """(index, state byte, target) for every 4-byte pointer in the table."""
    out = []
    for i in range((TABLE_END - TABLE) // 4):
        o = TABLE - B_BASE + i * 4
        out.append((i, i * 4, int.from_bytes(b[o:o + 4], "little")))
    return out


def labels():
    """address -> label name, from the .s transcription's own address comments.

    A label line carries no address; the address is on the NEXT line that has
    one.  That is how the .s is written, and it is why this reads the source
    rather than guessing from the ROM."""
    at = {}
    pend = []
    for l in open(SRC):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l)
        if m:
            pend.append(m.group(1))
            continue
        m = re.search(r";\s*([0-9A-F]{6})\s", l)
        if m and pend:
            a = int(m.group(1), 16)
            for nm in pend:
                at.setdefault(a, nm)
            pend = []
    return at


def state_writes():
    """Every instruction in the .s that stores to or steps (0x2A80).

    Read off the address+mnemonic comment the transcription carries, which is
    exact: those runs were byte-verified by llvm_roundtrip_autoforce.py."""
    imm, step, read = [], [], []
    pat = re.compile(r";\s*([0-9A-F]{6})\s+(.*0x%04x.*)$" % STATE_VAR)
    for l in open(SRC):
        m = pat.search(l.rstrip("\n"))
        if not m:
            continue
        a, txt = int(m.group(1), 16), m.group(2).strip()
        mi = re.match(r"ld \(0x%04x\),(0x[0-9a-f]+)$" % STATE_VAR, txt)
        if mi:
            imm.append((a, int(mi.group(1), 16)))
        elif txt.startswith("inc") or txt.startswith("dec"):
            step.append((a, txt))
        else:
            read.append((a, txt))
    return imm, step, read


def reachable(imm, step):
    """States reachable by starting from a written immediate and applying the
    +4 / -4 steps repeatedly, clipped to the table's own extent.

    ⚠ THIS CRITERION IS NEARLY UNFALSIFIABLE AND THE OUTPUT SAYS SO.  The module
    contains BOTH an `inc 4,(0x2A80)` and a `dec 4,(0x2A80)`, so the closure of
    any single reachable state under {+4, -4} is the whole 0x00..0x28 range,
    whatever the handlers actually do.  It is computed only to show that no
    entry is stranded OUTSIDE the range, i.e. that the table's 11 slots and the
    state values the code uses agree on their bounds.  It is NOT evidence that
    any particular state occurs at run time -- nothing in this tree executes the
    firmware, and per-handler control flow is not traced here.
    """
    n = (TABLE_END - TABLE) // 4
    seen = set(v for _, v in imm)
    d = set()
    for _, t in step:
        if t.startswith("inc 4"):
            d.add(4)
        if t.startswith("dec 4"):
            d.add(-4)
    changed = True
    while changed:
        changed = False
        for s in list(seen):
            for k in d:
                v = s + k
                if 0 <= v < n * 4 and v % 4 == 0 and v not in seen:
                    seen.add(v)
                    changed = True
    return sorted(seen)


def disasm_run():
    """{entry address: [(address, mnemonic), ...]} for the two dispatch
    preambles, taken from the .s transcription's own address+mnemonic comments.
    Those runs were byte-verified by notes/llvm_roundtrip_autoforce.py, so the
    boundaries are exact."""
    want = {0xF5AC93: 0xF5ACA6, 0xF5ACBB: 0xF5ACCE}   # entry -> the `jp XHL`
    out = {a: [] for a in want}
    cur = None
    for l in open(SRC):
        m = re.search(r";\s*([0-9A-F]{6})\s+(.*?)(?:\s+\[llvm-mc.*)?$",
                      l.rstrip("\n"))
        if not m:
            continue
        a, txt = int(m.group(1), 16), m.group(2).strip()
        if a in want:
            cur = a
        if cur is not None:
            out[cur].append((a, txt))
            if a >= want[cur]:
                cur = None
    return out


EXIT_STUBS = {
    # label: (address, how many registers it pops)
    "SC1_Irq_Exit_1":          (0xF5AC58, 1),
    "SC1_Irq_Exit_1_Delayed":  (0xF5AC5A, 1),
    "SC1_Irq_Exit_3":          (0xF5ACA8, 3),
    "SC1_Irq_Exit_3_Delayed":  (0xF5ACAC, 3),
    "SC1_Irq_Exit_3b":         (0xF5ACD0, 3),
    "SC1_Irq_Exit_3b_Delayed": (0xF5ACD4, 3),
}


def branches_to(addr):
    """Every branch in the .s whose printed target is `addr`.

    The transcription prints each branch's resolved target in its comment
    (`jrl T,0xf5aca8`), so this needs no displacement arithmetic of its own."""
    pat = re.compile(r";\s*([0-9A-F]{6})\s+((?:jr|jrl|jp|call|calr)\b[^;]*"
                     r"0x%06x)\s*$" % addr)
    out = []
    for l in open(SRC):
        m = pat.search(l.rstrip("\n").split("[llvm-mc")[0].rstrip())
        if m:
            out.append((int(m.group(1), 16), m.group(2).strip()))
    return out


def literal_sites(word, width):
    """Offsets in CPU 1's two ROMs holding `word` as a little-endian value of
    `width` bytes.  Catches a target reached through a pointer rather than a
    relative branch.  Scanning every byte offset can only OVER-count."""
    x = word.to_bytes(width, "little")
    out = []
    for nm, path, base in (("prom_a", "wsa1_prom_a.ic12", 0xF80000),
                           ("prom_b", "wsa1_prom_b.ic13", 0xF00000)):
        img = open(os.path.join(ROOT, "original_ROMs", path), "rb").read()
        i = img.find(x)
        while i >= 0:
            out.append((nm, base + i))
            i = img.find(x, i + 1)
    return out


def main():
    argv = sys.argv[1:]
    b = rom()
    lab = labels()
    ents = entries(b)
    imm, step, read = state_writes()

    if "--writes" in argv:
        print("immediate stores to (0x%04X):" % STATE_VAR)
        for a, v in sorted(imm):
            print("  0x%06X  ld (0x%04X),0x%02X" % (a, STATE_VAR, v))
        print("steps:")
        for a, t in sorted(step):
            print("  0x%06X  %s" % (a, t))
        print("reads:")
        for a, t in sorted(read):
            print("  0x%06X  %s" % (a, t))
        return 0

    if "--tables" in argv:
        for nm, base, end, how in TABLES:
            n = (end - base) // 4
            print("%s  0x%06X-0x%06X  %d entries" % (nm, base, end - 1, n))
            print("  index: %s" % how)
            tgts = []
            for i in range(n):
                o = base - B_BASE + i * 4
                t = int.from_bytes(b[o:o + 4], "little")
                tgts.append(t)
                print("    [%2d]  key 0x%02X  -> 0x%06X  %s"
                      % (i, i * 4, t, lab.get(t, "-- no label --")))
            print("  %d distinct targets; upper bound abuts %s"
                  % (len(set(tgts)), lab.get(end, "-- nothing labelled --")))
            print()
        return 0

    if "--branches" in argv:
        for a in [int(x, 0) for x in argv if not x.startswith("--")]:
            br = branches_to(a)
            print("0x%06X %-26s %d branch(es)"
                  % (a, lab.get(a, ""), len(br)))
            for ad, t in br:
                print("    0x%06X  %s" % (ad, t))
        return 0

    if "--exits" in argv:
        print("the six interrupt-exit stubs, and what reaches each")
        for nm, (a, pops) in sorted(EXIT_STUBS.items(), key=lambda x: x[1][0]):
            br = branches_to(a)
            l4 = literal_sites(a, 4)
            l3 = literal_sites(a, 3)
            print("  %-24s 0x%06X  pops %d" % (nm, a, pops))
            print("      branches to it : %d %s"
                  % (len(br), ["0x%06X %s" % x for x in br] if br else ""))
            print("      32-bit literal : %d      24-bit literal : %d"
                  % (len(l4), len(l3)))
            if not br and not l4 and not l3:
                print("      => NOTHING THIS TREE CAN MEASURE REACHES IT")
        return 0

    if "--dispatch" in argv:
        # Read the two preambles out of the VERIFIED transcription, so the
        # instruction boundaries are exact rather than assumed, and let the
        # script -- not a typed sentence -- decide whether a bounds check exists.
        seq = disasm_run()
        for a in (0xF5AC93, 0xF5ACBB):
            o = a - B_BASE
            print("0x%06X  raw: %s"
                  % (a, " ".join("%02X" % c for c in b[o:o + 0x14])))
            for ad, txt in seq[a]:
                print("            0x%06X  %s" % (ad, txt))
            guards = [(ad, t) for ad, t in seq[a]
                      if re.match(r"(cp|jr|jp|and|or|bit|res|set)\b", t)
                      and not t.startswith("jp T,XHL")]
            print("          bounds-check candidates between the state load and"
                  " the indirect jump: %s"
                  % ("NONE -- the dispatch is UNCHECKED"
                     if not guards else guards))
        same = b[0xF5AC93 - B_BASE:0xF5AC93 - B_BASE + 0x14] == \
            b[0xF5ACBB - B_BASE:0xF5ACBB - B_BASE + 0x14]
        print("the two preambles' first 0x14 bytes are %s"
              % ("IDENTICAL" if same else "DIFFERENT"))
        return 0

    reach = reachable(imm, step)

    if "--selftest" in argv:
        fails = []
        if len(ents) != 11:
            fails.append("table has %d entries, notes say 11" % len(ents))
        if TABLE_END != 0xF5AC93 or lab.get(TABLE_END) != "INTTX1_SC1_Dispatch":
            fails.append("the table's upper bound is not INTTX1_SC1_Dispatch")
        # the three "unexpected" slots must be the SAME target
        u = set(t for i, s, t in ents if i in (0, 7, 10))
        if len(u) != 1:
            fails.append("entries 0, 7 and 10 are not one target: %s" % u)
        # every target must be a label in the .s
        miss = [(i, t) for i, s, t in ents if t not in lab]
        if miss:
            fails.append("targets with no label: %s"
                         % ["[%d]->0x%06X" % x for x in miss])
        # LAST entry test: entry 10 is 0x28 and is reachable
        if ents[-1][1] != 0x28:
            fails.append("last entry is state 0x%02X, not 0x28" % ents[-1][1])
        if 0x28 not in reach:
            fails.append("state 0x28 is outside the range the code's own state "
                         "values span -- the last entry would be stranded")
        # the weak-criterion guard: if this ever becomes informative, say so
        if len(reach) != len(ents):
            fails.append("the +-4 closure no longer spans the table (%d of %d) "
                         "-- re-read the caveat in reachable()"
                         % (len(reach), len(ents)))
        if imm == []:
            fails.append("no immediate write to the state byte found -- "
                         "the .s scan is broken")
        # the exit stubs, asserted individually (see --exits)
        for nm, (a, _) in EXIT_STUBS.items():
            n = len(branches_to(a)) + len(literal_sites(a, 4)) \
                + len(literal_sites(a, 3))
            dead = nm.endswith("_Delayed")
            if dead and n:
                fails.append("%s was believed unreachable but has %d "
                             "reference(s) -- correct the header" % (nm, n))
            if not dead and not n:
                fails.append("%s has no reference at all -- the branch scan "
                             "is broken" % nm)
        # the scan must be able to SEE a branch: the busiest stub has nine
        if len(branches_to(0xF5ACA8)) != 9:
            fails.append("SC1_Irq_Exit_3 has %d branches, not the 9 measured"
                         % len(branches_to(0xF5ACA8)))
        # the _3 / _3b twins: the headers claim byte identity and a ONE-byte
        # difference respectively.  Count them; never eyeball them.
        def g(a, n):
            return b[a - B_BASE:a - B_BASE + n]
        d = [i for i, (x, y) in enumerate(zip(g(0xF5ACA8, 4), g(0xF5ACD0, 4)))
             if x != y]
        if d:
            fails.append("SC1_Irq_Exit_3 / _3b differ in %d byte(s) at %s -- "
                         "the header claims byte identity" % (len(d), d))
        d2 = [i for i, (x, y) in enumerate(zip(g(0xF5ACAC, 0x0F),
                                               g(0xF5ACD4, 0x0F)))
              if x != y]
        if d2 != [5]:
            fails.append("the _Delayed twins differ in %d byte(s) at %s, not "
                         "the single byte 5 the header states" % (len(d2), d2))
        print("SC1 state table: %d entries, %d reachable, %d distinct targets"
              % (len(ents), len(reach), len(set(t for _, _, t in ents))))
        for f in fails:
            print("SELF-CHECK FAILED: " + f)
        return 1 if fails else 0

    print("SC1_StateTable at 0x%06X, %d entries, bounded above by 0x%06X (%s)"
          % (TABLE, len(ents), TABLE_END, lab.get(TABLE_END, "?")))
    print("  idx  state  target     label                        reachable")
    for i, s, t in ents:
        print("  [%2d]  0x%02X   0x%06X  %-28s %s"
              % (i, s, t, lab.get(t, "-- no label --"),
                 "yes" if s in reach else "NO"))
    print()
    print("states in range of the code's own values: %s"
          % " ".join("0x%02X" % s for s in reach))
    print("  = the closure of the immediates {%s} under the +4 and -4 steps,"
          % ", ".join("0x%02X" % v for v in sorted(set(v for _, v in imm))))
    print("  clipped to the table.  ⚠ WEAK: the module has BOTH steps, so this")
    print("  closure is the whole range no matter what the handlers do.  It")
    print("  shows only that no table slot is stranded outside the range; it is")
    print("  NOT evidence that any state occurs at run time.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
