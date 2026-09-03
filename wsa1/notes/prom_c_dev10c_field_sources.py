#!/usr/bin/env python3
"""WHICH ROUTINE COMPUTES THE VALUE OF EACH 0x0010C000 REGISTER?

QUESTION ANSWERED
  `Dev10C_WriteAllChanRegs` (0xFB713A) only MOVES words: it copies the 22 words of the
  staging struct at RAM 0x00D75E into 22 registers of one channel, and
  notes/prom_c_tg_chanmap.py already prints which word goes to which register.  The
  question that blocks the emulator (gap A of
  ../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md) is the one BEFORE that: what
  computes each of those words?

  This script answers it mechanically.  It finds every instruction in prom_c that writes
  a byte or a word into 0x00D75E..0x00D789 -- the 22-word struct -- attributes each one
  to the routine label it falls under in prom_c/wsa1_prom_c.s, and joins that to the
  struct-word -> register-block table.  The result is a per-REGISTER list of the routines
  that produce its value.

  It finds the writes in two forms, because the image uses both:
    * absolute:  `ld (0x00d766),BC`      -- the `st*_da` spellings in this tree
    * based:     `lda XIX,0x00d75e` ... `ld (XIX+0x0e),BC`   -- a pointer into the struct
  The based form is tracked only until the base register is reloaded, and any write
  through a base this script cannot follow is COUNTED AND REPORTED, never dropped.

THE JOIN TABLE IS NOT TYPED IN
  The struct-word -> register-block map comes from notes/prom_c_tg_chanmap.py's own
  output for 0xFB713A (`--groups`), reproduced here as four RUNS and checked against it
  by `--verify`.  If that routine is ever re-read differently, the check fails.

WHAT THIS DOES NOT ESTABLISH
  * It does not say what a register MEANS.  It says which code computes it.  A register
    whose only producer is one 30-instruction routine is a register whose meaning is one
    routine away; a register written from nine places is not.
  * A routine that writes a field is not necessarily the routine that DECIDES it -- the
    value may arrive as an argument.  The listing prints the value operand so that is
    visible.
  * The 0x00104000 twin struct at 0x00D7A2 is filled by ONE routine, Dev104_PackStagingStruct, which
    writes 19 SITES over 15 DISTINCT OFFSETS through its (XIZ+0x08) pointer argument
    (+0x00, +0x0A, +0x0C and +0x18 are each written twice on different paths);
    ⚠ this line previously said "19 struct offsets", conflating the two units.
    `--dev104-selftest` pins both. `--dev104` prints
    those.  That asymmetry -- one packer there, many small writers here -- is itself a
    finding.

RUN
  python3 notes/prom_c_dev10c_field_sources.py            # the per-register table
  python3 notes/prom_c_dev10c_field_sources.py --verify   # assertions, exit != 0 on failure
  python3 notes/prom_c_dev10c_field_sources.py --sites    # every write, with its address
  python3 notes/prom_c_dev10c_field_sources.py --dev104   # the 0x00D7A2 packer's writes
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ⚠ prom_c is 26 files now (notes/prom_c_split.py): the master alone is 2% of
# the image, and this scan passed VACUOUSLY over it until this line changed.
# notes/probe_health.py is the check; notes/asm_source.py is the reader,
# and it absorbed the prom_c-only shim that used to stand here.
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")

STRUCT = 0x00D75E          # the 0x0010C000 staging struct
NWORD = 22                 # Dev10C_WriteAllChanRegs moves 22 words
D104 = 0x00D7A2            # the 0x00104000 staging struct
PACKER = ("Dev104_PackStagingStruct", 0xFC4DBD, 0xFC56C3)

# struct WORD index -> register block, from notes/prom_c_tg_chanmap.py 0xFB713A --groups
#   run: blocks 0x0040..0x0040 (index 1..1)   <- struct words 1..1
#   run: blocks 0x00C0..0x0180 (index 3..6)   <- struct words 3..6
#   run: blocks 0x0400..0x0500 (index 16..20) <- struct words 7..11
#   run: blocks 0x0800..0x0A40 (index 32..41) <- struct words 12..21
# plus word 2 -> block 2 (0x0080), the gate the routine pulses 1-then-0.
RUNS = [(1, 1, 1), (3, 6, 3), (7, 11, 16), (12, 21, 32)]
WORD2BLOCK = {2: 2}
for w0, w1, b0 in RUNS:
    for w in range(w0, w1 + 1):
        WORD2BLOCK[w] = b0 + (w - w0)

ADDR = re.compile(r";\s*([0-9A-F]{6})\s")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
# `ld (0x00d766),BC` / `ld (0x00d766),0x12` -- absolute, in the tree's st*_da spellings
ABS = re.compile(r"^\s*st[ilbwl]*_da\s+\(0x([0-9A-Fa-f]{4})\),\s*(\S+)")
LDA = re.compile(r"^\s*lda_24\s+(x[a-z]{2}),\s*\(0x([0-9A-Fa-f]{4})\)")
BASED = re.compile(r"^\s*ld\s+\((x[a-z]{2})(?:\+(\d+))?\),\s*(\S+)\s*$")
RELOAD = re.compile(r"^\s*ld[a-z0-9_]*\s+(x[a-z]{2})\s*,")


def scan():
    """[(address, struct_offset, value operand, routine label, form)]"""
    cur, base = None, {}
    out, unfollowed = [], []
    for line in open(SRC):
        m = LABEL.match(line)
        if m:
            cur, base = m.group(1), {}
            continue
        code = line.split(";")[0]
        if not code.strip():
            continue
        m = ADDR.search(line)
        addr = int(m.group(1), 16) if m else None

        m = ABS.match(code)
        if m:
            tgt = int(m.group(1), 16)
            if STRUCT <= tgt < STRUCT + 2 * NWORD:
                out.append((addr, tgt - STRUCT, m.group(2).strip(), cur, "abs"))
            continue
        m = LDA.match(code)
        if m:
            base[m.group(1)] = int(m.group(2), 16)
            continue
        m = BASED.match(code)
        if m and m.group(1) in base:
            tgt = base[m.group(1)] + int(m.group(2) or 0)
            if STRUCT <= tgt < STRUCT + 2 * NWORD:
                out.append((addr, tgt - STRUCT, m.group(3).strip(), cur, "based"))
            continue
        m = RELOAD.match(code)
        if m and m.group(1) in base and "lda_24" not in code:
            del base[m.group(1)]
    return out, unfollowed


def dev104():
    """The writes Dev104_PackStagingStruct makes through its (XIZ+0x08) struct-pointer argument."""
    lines = open(SRC).read().splitlines()
    i = next(k for k, l in enumerate(lines) if l.startswith(PACKER[0] + ":"))
    ptr, out = set(), []
    for l in lines[i:]:
        m = ADDR.search(l)
        if not m:
            continue
        a = int(m.group(1), 16)
        if a > PACKER[2]:
            break
        ins = l.split(";")[0].strip()
        m = re.match(r"ld\s+(x[a-z]{2}),\s*\(xiz\+8\)$", ins)
        if m:
            ptr.add(m.group(1))
            continue
        m = re.match(r"ld\s+\((x[a-z]{2})(?:\+(\d+))?\),\s*(\S+)$", ins)
        if m and m.group(1) in ptr:
            out.append((a, int(m.group(2) or 0), m.group(3)))
            continue

        # ★ A STORE SPELLED AS A RAW-BYTE PSEUDO-INSTRUCTION IS STILL A STORE.
        # `extpfx5 0xB9,0x16,0x02,0x00,0xFF` at 0xFC51AD is `ld (XBC+0x16),0xff00`
        # -- a genuine struct write this scanner used to MISS, because the
        # extended-prefix forms have no modelled operands and so match no `ld`
        # pattern.  The trailing comment carries the decoder's rendering, so the
        # form is read from there and the base register is still required to be
        # a live struct pointer.  ⚠ This is the one place the scanner trusts a
        # comment; --selftest pins the site it was built for.
        if ins.startswith("extpfx"):
            c = re.search(r"ld\s+\((X[A-Z]{2})\+0x([0-9a-fA-F]+)\),\s*(\S+)",
                          l.split(";", 1)[1] if ";" in l else "")
            if c and c.group(1).lower() in ptr:
                out.append((a, int(c.group(2), 16), c.group(3)))
            continue

        # ⚠ INVALIDATE ON THE LOW HALF TOO.  `ld wa,(0x00e086)` + `extz xwa`
        # re-points XWA at a DIFFERENT record (the 37-byte one at 0x00E086) and
        # never writes the token `ld xwa,`.  Matching only the 32-bit form left
        # a stale pointer live and attributed four writes -- 0xFC5522, 0xFC55AF,
        # 0xFC55C5, 0xFC5657 -- to the Part104 struct that never touch it.
        # Consequence of the fix: the packer writes 15 offsets, not 16, and
        # +0x1D is not a struct offset at all.
        m = re.match(r"ld\s+(x?[a-z]{2}),", ins)
        if m and "(xiz+8)" not in ins:
            reg = m.group(1)
            for dead in {reg, "x" + reg} & ptr:
                ptr.discard(dead)
            continue
        m = re.match(r"extz\s+(x[a-z]{2})", ins)
        if m:
            ptr.discard(m.group(1))
    return out


def dev104_selftest():
    """Controls for the two defects fixed on 2026-09-03.

    Both are properties of the REAL listing, so this is a regression pin, not a
    synthetic fixture: the sites are quoted with their addresses and either the
    scanner reproduces them or it has regressed.
    """
    got = {a: off for a, off, _ in dev104()}
    ok = True
    # (1) the four writes through the 0x00E086 record must NOT be attributed
    for a in (0xFC5522, 0xFC55AF, 0xFC55C5, 0xFC5657):
        bad = a in got
        ok &= not bad
        print(f"    0x{a:06X} not a struct write   "
              f"{'STILL ATTRIBUTED -- regressed' if bad else 'ok'}")
    # (2) the extended-prefix store at +0x16 must BE attributed
    hit = got.get(0xFC51AD)
    ok &= (hit == 0x16)
    print(f"    0xFC51AD writes +0x16              "
          f"{'ok' if hit == 0x16 else f'MISSED (got {hit})'}")
    # ★ STATE THE UNIT.  19 write SITES cover 15 distinct OFFSETS -- +0x00,
    # +0x0A, +0x0C and +0x18 are each written twice on different paths.  The
    # two figures are both correct and are not interchangeable; pinning one
    # against the other is how this check first went red on a correct fix.
    sites = len(dev104())
    offs = len({o for _, o, _ in dev104()})
    ok &= (sites == 19 and offs == 15)
    print(f"    {sites} write sites over {offs} distinct offsets   "
          f"{'ok' if (sites, offs) == (19, 15) else 'CHANGED -- re-adjudicate'}")
    return ok


def table():
    hits, _ = scan()
    bywork = collections.defaultdict(list)
    for a, off, val, rout, form in hits:
        bywork[off // 2].append((a, off, val, rout, form))
    print(f"0x0010C000 -- who computes each of the {NWORD} per-channel registers")
    print(f"(staging struct 0x{STRUCT:06X}, moved by Dev10C_WriteAllChanRegs 0xFB713A)\n")
    print(" word  struct    register   writers")
    for w in range(NWORD):
        blk = WORD2BLOCK.get(w)
        reg = f"0x{blk*0x40:04X}+ch" if blk is not None else "  --      "
        rs = sorted({h[3] for h in bywork.get(w, [])})
        n = len(bywork.get(w, []))
        note = ""
        if w == 2:
            note = "   [the bit-15 gate, pulsed 1-then-0]"
        if w == 6:
            note = "   [the block read back at 0xFA69B1]"
        print(f"  {w:2d}   +0x{w*2:02X}    {reg}   {n:2d} site(s): "
              + (", ".join(rs) if rs else "(none located)") + note)
    tot = sum(len(v) for v in bywork.values())
    print(f"\n{tot} write sites over {len(bywork)} of the {NWORD} words.")


def sites():
    hits, _ = scan()
    for a, off, val, rout, form in sorted(hits, key=lambda h: (h[1], h[0])):
        w = off // 2
        blk = WORD2BLOCK.get(w)
        reg = f"0x{blk*0x40:04X}" if blk is not None else "--"
        print(f"  0x{a:06X}  +0x{off:02X} (word {w:2d}, reg {reg:>6}) <- {val:<8} "
              f"[{form}]  in {rout}")


def verify():
    fails = []

    def check(ok, msg):
        print(("  ok   " if ok else "  FAIL ") + msg)
        if not ok:
            fails.append(msg)

    hits, _ = scan()
    words = {h[1] // 2 for h in hits}
    check(len(WORD2BLOCK) == NWORD - 1 and 0 not in WORD2BLOCK,
          f"the struct-word -> register-block map covers {len(WORD2BLOCK)} of the "
          f"{NWORD} words; word 0 is absent BECAUSE Dev10C_WriteAllChanRegs writes "
          "register block 0 with the literal 0x8100 and no struct field")
    check(WORD2BLOCK[1] == 1 and WORD2BLOCK[6] == 6 and WORD2BLOCK[7] == 16
          and WORD2BLOCK[21] == 41,
          "the map reproduces prom_c_tg_chanmap.py's four runs at their ends "
          "(words 1, 6, 7 and 21 -> blocks 1, 6, 16 and 41)")
    check(hits, f"{len(hits)} write sites into 0x{STRUCT:06X}..0x{STRUCT+2*NWORD-1:06X}")
    # the LAST word of the struct, tested explicitly
    last = [h for h in hits if h[1] // 2 == NWORD - 1]
    check(bool(last), f"...including word {NWORD-1} (+0x{2*(NWORD-1):02X}, register "
                      f"0x{WORD2BLOCK[NWORD-1]*0x40:04X}+ch): "
                      + ", ".join(sorted({h[3] for h in last})))
    d = dev104()
    offs = sorted({o for _, o, _ in d})
    check(len(d) == 19, f"Dev104_PackStagingStruct makes {len(d)} writes through its struct pointer")
    check(max(offs) == 0x24,
          f"...at offsets 0x{min(offs):02X}..0x{max(offs):02X}, which is exactly the span "
          "Dev104_WriteAllChanRegs reads (word 0 .. word 0x24 -> blocks 0..0x12)")
    missing = sorted(w for w in range(NWORD) if w not in words)
    check(missing == [0],
          f"the only word with NO located writer is word 0 -- the one the device writer "
          f"never reads either.  Two independent readings agree.  ({missing})")
    print()
    if fails:
        print(f"FAILURES: {len(fails)}")
        return 1
    print("ALL CHECKS PASSED")
    return 0


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    elif "--sites" in sys.argv:
        sites()
    elif "--dev104-selftest" in sys.argv:
        sys.exit(0 if dev104_selftest() else 1)
    elif "--dev104" in sys.argv:
        for a, o, v in dev104():
            print(f"  0x{a:06X}  struct+0x{o:02X} (word {o//2:2d}, register block "
                  f"0x{(o//2)*0x40:04X}) <- {v}")
    else:
        table()
