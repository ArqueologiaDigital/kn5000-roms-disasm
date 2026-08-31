#!/usr/bin/env python3
"""What EVIDENCE exists for the prom_b routines that are still `sub_XXXXXX`?

WHAT QUESTION THIS ANSWERS
    A naming round has to decide what to look at first, and "1,864 unnamed
    routines" is not a work list.  This sorts them by the KIND of evidence the
    tree already contains for each one, so the next round can start at the top
    instead of reading addresses in order.

    The classes, strongest first.  They are NOT exclusive -- a routine can be in
    several, and `--summary` prints both the per-class counts and how many
    routines have no class at all:

      STRING   a non-transfer operand of the routine lands on >= 4 printable ROM
               bytes.  ⚠ THE WEAKEST-LOOKING STRONG CLASS: about a third of
               these are display-list runners whose `ld XIX,imm` is the list's
               END pointer.  notes/prom_b_string_refs.py splits that; use it
               before naming anything from this class.
      TABLE    an operand lands exactly on a label that already has a SEMANTIC
               name.  The routine indexes, or reads through, something the tree
               has already identified.
      CALLER   a semantically named routine, in either image, calls or jumps to
               it -- directly or through a 0xF40000 directory slot.
      CALLEE   it calls a semantically named routine.
      DEVICE   it names an absolute address at or above 0x600000.
      ORPHAN   nothing calls it at all in either image, and no directory slot
               names it.  Not evidence FOR anything; it is here because it is
               the class where a name is least likely to be checkable, and it is
               big.

HOW THE CALL GRAPH IS BUILT
    From the `; ADDR  <disassembler text>` comment on every line of the two CPU-1
    images -- the DECODE AUTHORITY this tree keeps on each row -- plus the 1,976
    `jp` slots of the routine directory at 0xF40000, read out of the ROM.  A
    `call`/`jp` whose operand is a directory slot is credited to the slot's
    TARGET, so a caller is not lost behind the thunk.

⚠ WHAT A NUMBER HERE IS NOT
    It is not a call count.  Operands are taken from the text of instructions
    this tree has already transcribed, so a routine reached only from code that
    is still `.incbin` looks like an ORPHAN and is not one.  The classes rank
    candidates; they do not settle anything.

RUN
    python3 notes/prom_b_naming_evidence.py                # the summary
    python3 notes/prom_b_naming_evidence.py --class TABLE  # one class, listed
    python3 notes/prom_b_naming_evidence.py --named        # summary over ALL
                                                           # routines, named too
    python3 notes/prom_b_naming_evidence.py --selftest     # invariants
Exit status is non-zero only if --selftest fails.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402

IMAGES = (("prom_b", "prom_b/wsa1_prom_b.s", 0xF00000),
          ("prom_a", "prom_a/wsa1_prom_a.s", 0xF80000))
TBL_LO, TBL_HI = 0x40000, 0x44018          # the routine directory, file offsets
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ADDRC = re.compile(r";\s*([0-9A-F]{6})\s\s(.*)$")
XFER = re.compile(r"^(call|calr|jp|jr|jrl|djnz)\b")
HEX = re.compile(r"0x([0-9a-fA-F]+)")
GENERIC = re.compile(r"^(sub|L|T|Data|DataPtrTable|Text|ByteMap|PtrTable|RamPtrTable"
                     r"|IndexMap|DispatchTable|Bitmap|Record|DL|DLB_Records|DLBTable"
                     r"|DLTable|StringTable|WordTable|Fwd|Nop_Ret|Veneer)_[0-9A-F]{4,6}$")
BARE = re.compile(r"^sub_[0-9A-F]{6}$")

with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as _f:
    ROMB = _f.read()
with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb") as _f:
    ROMA = _f.read()


def thunks():
    """slot address -> target, for every `jp imm24` slot of the directory."""
    out = {}
    for off in range(TBL_LO, TBL_HI, 4):
        if ROMB[off] == 0x1B:
            out[0xF00000 + off] = ROMB[off + 1] | ROMB[off + 2] << 8 | ROMB[off + 3] << 16
    return out


def ascii_at(a, n=4):
    if 0xF00000 <= a < 0xF80000:
        r, o = ROMB, a - 0xF00000
    elif 0xF80000 <= a < 0x1000000:
        r, o = ROMA, a - 0xF80000
    else:
        return False
    return all(0x20 <= r[o + i] < 0x7F for i in range(n))


def parse():
    """-> labels[img] = [(addr, name)], rows[img][name] = [texts]

    ★ EVERY label is listed, including one that has no addressed row of its own:
    an ALIAS -- two labels in a row, or a label in front of an `.incbin` -- takes
    the address of the next addressed row, which is where it actually is.  An
    earlier draft only listed labels with their own first row and reported 3,281
    of prom_b's 6,259, which is why the count is now an asserted invariant.
    """
    labels, rows = {}, {}
    for img, path, _base in IMAGES:
        rows[img] = collections.OrderedDict()
        pending, out = [], []
        cur, last = None, None
        for ln in image_lines(ROOT, path):
            m = LABEL.match(ln)
            if m:
                cur = m.group(1)
                rows[img].setdefault(cur, [])
                pending.append(cur)
                continue
            if ln.lstrip().startswith(";"):
                continue
            m2 = ADDRC.search(ln)
            if m2 and cur is not None:
                a = last = int(m2.group(1), 16)
                for n in pending:
                    out.append((a, n))
                pending = []
                rows[img][cur].append(m2.group(2).strip())
        # a label with NO addressed row after it at all -- the tail of a file, or
        # a label in front of the final `.incbin` -- takes the last address seen.
        # It is a real label and must be counted; the address is a lower bound.
        for n in pending:
            out.append((last if last is not None else 0, n))
        labels[img] = out
    return labels, rows


def semantic(name):
    return not (BARE.match(name) or GENERIC.match(name) or name.startswith("__")
                or re.fullmatch(r"[LT]_[0-9A-F]{6}", name))


def build():
    labels, rows = parse()
    T = thunks()
    addr_of = {img: {n: a for a, n in labels[img]} for img in rows}
    at = {}
    for img in rows:
        for a, n in labels[img]:
            at.setdefault(a, (img, n))
    callers = collections.defaultdict(set)     # target addr -> {(img, caller)}
    ev = collections.defaultdict(set)          # (img, name) -> classes
    for img in rows:
        for name, ts in rows[img].items():
            for t in ts:
                xf = bool(XFER.match(t))
                for h in HEX.findall(t):
                    v = int(h, 16)
                    if 0xF00000 <= v < 0x1000000:
                        tgt = T.get(v, v)
                        if xf:
                            callers[tgt].add((img, name))
                        else:
                            if ascii_at(v):
                                ev[(img, name)].add("STRING")
                            if tgt in at and semantic(at[tgt][1]):
                                ev[(img, name)].add("TABLE")
                    elif 0x600000 <= v < 0x800000:
                        ev[(img, name)].add("DEVICE")
    for tgt, cs in callers.items():
        if tgt in at:
            for c in cs:
                if semantic(c[1]):
                    ev[at[tgt]].add("CALLER")
            if semantic(at[tgt][1]):
                for c in cs:
                    ev[c].add("CALLEE")
    for img in rows:
        for a, n in labels[img]:
            if not callers.get(a):
                ev[(img, n)].add("ORPHAN")
    return labels, rows, ev, addr_of


ORDER = ("STRING", "TABLE", "CALLER", "CALLEE", "DEVICE", "ORPHAN")


def main():
    labels, rows, ev, addr_of = build()
    want_named = "--named" in sys.argv
    pick = sys.argv[sys.argv.index("--class") + 1].upper() if "--class" in sys.argv else None
    subj = [(a, n) for a, n in labels["prom_b"]
            if want_named or BARE.match(n)]
    if pick:
        rowsout = [(a, n) for a, n in subj if pick in ev.get(("prom_b", n), ())]
        print(f"{pick}: {len(rowsout)} of {len(subj)} prom_b routines")
        for a, n in rowsout:
            print(f"  0x{a:06X} {n:34s} {sorted(ev[('prom_b', n)])}")
        return 0
    c = collections.Counter()
    none = 0
    for a, n in subj:
        k = ev.get(("prom_b", n), set())
        if not k:
            none += 1
        for x in k:
            c[x] += 1
    scope = "ALL prom_b routines" if want_named else "prom_b routines still called sub_XXXXXX"
    print(f"{scope}: {len(subj)}")
    for k in ORDER:
        print(f"  {k:8s} {c[k]:5d}")
    print(f"  {'(none)':8s} {none:5d}")
    print("\n  Classes overlap.  STRING is the one to check with "
          "notes/prom_b_string_refs.py before naming anything.")
    return 0


def selftest():
    ok = True

    def ck(cond, what):
        nonlocal ok
        ok &= bool(cond)
        print(("  ok   " if cond else "  FAIL ") + what)

    T = thunks()
    ck(len(T) > 1900, f"the routine directory yields {len(T)} `jp` slots")
    ck(all(0xF00000 <= v < 0x1000000 for v in T.values()),
       "every directory target is inside the two CPU-1 EPROMs")
    labels, rows, ev, addr_of = build()
    # INVARIANT: the tool must see every label the image declares, not only the
    # ones with an addressed row of their own.
    import subprocess
    for img, path, _b in IMAGES:
        declared = sum(1 for ln in image_lines(ROOT, path) if LABEL.match(ln))
        seen = len(labels[img])
        ck(seen == declared, f"{img}: {seen} labels seen == {declared} declared")
    bare = [n for _a, n in labels["prom_b"] if BARE.match(n)]
    ck(bare, f"{len(bare)} prom_b routines are still sub_XXXXXX")
    # INVARIANT, not a pinned count: naming a routine can only ever REMOVE it
    # from the bare set, so the bare set must be a subset of the labels.
    ck(set(bare) <= {n for _a, n in labels["prom_b"]}, "the bare set is a subset of the labels")
    # every class this reports must be one of the declared ones
    seen = {k for v in ev.values() for k in v}
    ck(seen <= set(ORDER), f"only declared classes are produced: {sorted(seen)}")
    # a NEGATIVE CONTROL: `semantic()` must reject the generic spellings
    for n in ("sub_F6D410", "L_F6D410", "T_F6D410", "Data_F6D410", "DL_F6D410",
              "ByteMap_F6D410"):
        ck(not semantic(n), f"`{n}` is not counted as a semantic name")
    for n in ("MsgLine_PartPanpot", "Smf_ReadFile", "EffectNames_F147AC"):
        ck(semantic(n), f"`{n}` IS counted as a semantic name")
    # and one end-to-end: a routine this lane named from a string must be in STRING
    ck("STRING" in ev.get(("prom_b", "MsgLine_PartPanpot"), set()),
       "MsgLine_PartPanpot lands in STRING, which is how it was named")
    ck("TABLE" in ev.get(("prom_b", "DspEffect_LoadParamNames"), set()),
       "DspEffect_LoadParamNames lands in TABLE, which is how it was named")
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
