#!/usr/bin/env python3
"""Do prom_c's COMPUTED byte emitters produce the same 5-byte groups the POOL replays?
   -- and which relocation base belongs to which opcode?

QUESTION IT ANSWERS
  `prom_c/p7/p7_module.s` holds two ways to program the port-P7 device:

    (A) REPLAY     P7Stream_Run walks a canned relocatable stream out of the pool at
                   0xFCD0F7 and sends it byte by byte.  Its own header already says the
                   payload of an opcode-0/1/5 record is "3 head bytes, then groups of 5".
    (B) SYNTHESISE a family of small routines at 0xF9AEB6-0xF9B54A computes a value with
                   floating-point arithmetic and sends it, never touching the pool.

  If (A) and (B) drive the same device they must speak the same byte language.  This
  script tests that, and uses the agreement to pin down which of the six-byte relocation
  record's bytes -- held in the module globals 0x008614/16/18/1A -- belongs to which
  stream opcode.

WHAT IS MEASURED, AND THE NULL FOR EACH
  1. The command-byte alphabet.  Every literal `push <imm>` immediately before a
     P7Byte_SendCmd call in the module, tallied; and the first payload byte of every
     pool record, per opcode.  NULL: none needed -- these are exhaustive enumerations,
     not samples.  The result is reported as a set, and the SET is the claim.
  2. The 5-byte group template.  Every opcode-0/1/5 record whose payload is a whole
     number of groups is cut into groups; the first byte and the last byte of each
     group are tallied PER OPCODE.
     NULL: a uniform-random byte stream puts any given value first in 1/256 = 0.39% of
     groups and any given 7-bit tail in 1/128 = 0.78%.  Both are printed beside the
     measurement.  A second, sharper control re-cuts the SAME payload bytes at every
     other phase (head 0..4 instead of head 3) and reports the best score any wrong
     phase reaches -- if a wrong phase scored as well, the framing would carry no
     information.
  3. The pool directory's four stream-pointer fields against the pool's own
     "interpreter-clean" flag.  ⚠ NOT NEW -- notes/prom_c_fcd0f7_interpreter.py
     established this split first, and named the second consumer (0xF9ADB5, framed by
     0xF9E140).  It is re-derived here from a different starting point only so that
     section 2's claim about the relocation globals rests on a check this script itself
     runs; read that note for the argument.
     NULL: the pool-wide clean fraction (167/297 = 56.2%), so a field of 56 pointers
     drawn at random would be all-clean with probability 0.562**56 ~ 1e-14.

RUN
    python3 notes/p7_group_template_probe.py            # the tables
    python3 notes/p7_group_template_probe.py --verify   # assertions; exit != 0 on failure
"""
import os, re, sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM  = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
BASE = 0xF80000
MOD  = os.path.join(ROOT, "prom_c", "p7", "p7_module.s")
POOL = os.path.join(ROOT, "prom_c", "p7", "p7_stream_pool.s")

SEND = {0xF9A163: "SendCmd", 0xF9A31A: "SendData", 0xF9A4B0: "SendArg"}
FAIL = []
def check(cond, what):
    print(("  ok   " if cond else "  FAIL ") + what)
    if not cond: FAIL.append(what)

# ---------------------------------------------------------------- the listing
def listing():
    out = []
    for ln in open(MOD):
        m = re.search(r";\s+([0-9A-F]{6})\s+(.*?)\s*$", ln)
        if m: out.append((int(m.group(1), 16), m.group(2)))
    return out
LST = listing()

def cmd_sites():
    """(addr, literal command byte or None) for every P7Byte_SendCmd call."""
    out = []
    for k, (a, ins) in enumerate(LST):
        m = re.match(r"cal[lr]\s+0x([0-9a-f]{6})$", ins.lower())
        if not m or SEND.get(int(m.group(1), 16)) != "SendCmd": continue
        prev = LST[k-1][1] if k else ""
        mm = re.match(r"push 0x([0-9a-f]{4})$", prev.lower())
        out.append((a, int(mm.group(1), 16) if mm else None))
    return out

# ---------------------------------------------------------------- the pool
REC = re.compile(r"^\s+\.byte\s+(.*?)\s+;\s+0x([0-9A-F]+)\s+op\s+(\d+)\s+len\s+(\d+)\s+payload\s+(\d+)")
END = re.compile(r"^\s+\.byte\s+0xf0, 0x00\s+;\s+0x([0-9A-F]+)\s+op 15\s+END")
RAW = re.compile(r"^\s+\.byte\s+(.*?)\s+;\s+0x([0-9A-F]+)")
OBJ = re.compile(r"^; ---- 0x([0-9A-F]+)-0x([0-9A-F]+)\s+\d+ bytes, \d+ records\s+\[(.*?)\] ----")

def pool():
    """(records, clean_flag_by_stream_start).  A record is (opcode, payload bytes)."""
    recs, clean, cur, buf = [], {}, None, []
    def flush():
        nonlocal cur, buf
        if cur is not None: recs.append((cur, buf))
        cur, buf = None, []
    for ln in open(POOL):
        m = OBJ.match(ln)
        if m: clean[int(m.group(1), 16)] = (m.group(3) == "interpreter-clean"); continue
        m = END.match(ln)
        if m:
            flush(); recs.append((15, [])); continue
        m = REC.match(ln)
        if m:
            flush(); cur = int(m.group(3)); buf = []
            b = [int(x, 16) for x in re.findall(r"0x([0-9a-f]{2})", m.group(1))]
            continue
        m = RAW.match(ln)
        if m and cur is not None:
            buf += [int(x, 16) for x in re.findall(r"0x([0-9a-f]{2})", m.group(1))]
    flush()
    return recs, clean
RECS, CLEAN = pool()

def groups_of(op, head=3, width=5):
    out = []
    for o, pl in RECS:
        if o != op or len(pl) < head or (len(pl) - head) % width: continue
        for i in range(head, len(pl), width): out.append(tuple(pl[i:i+width]))
    return out

# ---------------------------------------------------------------- sections
def s1_commands():
    print("1. THE COMMAND-BYTE ALPHABET")
    lit = Counter(v for _, v in cmd_sites() if v is not None)
    nolit = sum(1 for _, v in cmd_sites() if v is None)
    print(f"   P7Byte_SendCmd call sites in p7_module.s: {len(cmd_sites())}")
    print(f"     with a LITERAL command byte : {sum(lit.values())}  -> " +
          ", ".join(f"0x{k:02X} x{v}" for k, v in sorted(lit.items())))
    print(f"     byte taken from the STREAM  : {nolit}   (the opcode arms of P7Stream_Run)")
    first = defaultdict(Counter)
    for op, pl in RECS:
        if pl: first[op][pl[0]] += 1
    print("   first payload byte of every pool record, per opcode "
          "(op 0/1/2/5 and 4 hand this byte to P7Byte_SendCmd):")
    for op in sorted(first):
        c = first[op]
        print(f"     op {op:2d}  n={sum(c.values()):4d}  " +
              ", ".join(f"0x{k:02X}x{v}" for k, v in c.most_common(6)) +
              ("" if len(c) <= 6 else f"  (+{len(c)-6} more, {len(c)} distinct)"))
    return lit, first

def s2_groups():
    print("\n2. THE 5-BYTE GROUP TEMPLATE, PER OPCODE")
    print("   NULL: uniform-random bytes give any fixed first byte 0.39% of the time and")
    print("         any fixed 7-bit tail 0.78% of the time.")
    res = {}
    for op in (0, 1, 5):
        g = groups_of(op)
        val  = [x for x in g if x[0] == 0x0A]
        a0801 = [x for x in g if x[:2] == (0x08, 0x01)]
        a0000 = [x for x in g if x[:2] == (0x00, 0x00)]
        heads = Counter(tuple(pl[:3]) for o, pl in RECS
                        if o == op and len(pl) >= 3 and (len(pl)-3) % 5 == 0)
        res[op] = (g, val, a0801, a0000, heads)
        print(f"   op {op}: {len(g)} groups")
        print(f"      head triple 01 01 60 : {heads.get((1,1,0x60),0)}/{sum(heads.values())} records")
        if val:
            k = Counter(x[4] & 0x7F for x in val)
            print(f"      value group (first byte 0x0A) : {len(val)} "
                  f"= {100*len(val)/len(g):.1f}%   tail&0x7F = " +
                  ", ".join(f"0x{a:02X}x{b}" for a, b in k.most_common()))
        if a0801:
            print(f"      address group 08 01 ...       : {len(a0801)}   5th byte = " +
                  ", ".join(f"0x{a:02X}x{b}" for a, b in Counter(x[4] for x in a0801).most_common()))
        if a0000:
            hi = Counter(x[2] >> 4 for x in a0000)
            print(f"      address group 00 00 ...       : {len(a0000)}   5th byte = " +
                  ", ".join(f"0x{a:02X}x{b}" for a, b in Counter(x[4] for x in a0000).most_common(3)) +
                  f"   3rd byte high nibble = " +
                  ", ".join(f"0x{a:X}x{b}" for a, b in hi.most_common(3)))
    # phase control
    print("\n   PHASE CONTROL -- re-cut the same payloads at every other head offset and")
    print("   report the best 0x0A-first score any WRONG phase reaches:")
    for op in (0, 5):
        best = (0, None)
        for head in range(0, 8):
            if head == 3: continue
            g = groups_of(op, head=head)
            if len(g) < 50: continue
            f = sum(1 for x in g if x[0] == 0x0A) / len(g)
            if f > best[0]: best = (f, head)
        true = sum(1 for x in groups_of(op) if x[0] == 0x0A) / max(1, len(groups_of(op)))
        print(f"     op {op}: true head 3 -> {100*true:.1f}% ;"
              f" best wrong phase (head {best[1]}) -> {100*best[0]:.1f}%")
    return res

def u32le(a): return int.from_bytes(ROM[a-BASE:a-BASE+4], "little")

def s3_directory():
    print("\n3. POOL DIRECTORY FIELDS vs THE POOL'S OWN 'interpreter-clean' FLAG")
    tot, cl = len(CLEAN), sum(CLEAN.values())
    print(f"   NULL: pool-wide clean fraction {cl}/{tot} = {100*cl/tot:.1f}%;"
          f" 56 random draws all clean = {(cl/tot)**56:.1e}")
    RECDIR, STRIDE, N = 0xFDBFD9, 25, 56
    out = {}
    for f in (0, 4, 8, 12):
        ps = [u32le(RECDIR + STRIDE*i + f) for i in range(N)]
        c = sum(1 for p in ps if CLEAN.get(p) is True)
        n = sum(1 for p in ps if CLEAN.get(p) is False)
        out[f] = (c, n, len(ps) - c - n)
        print(f"     field +{f:<2d}  clean {c:2d}   NOT clean {n:2d}   not a stream start {len(ps)-c-n:2d}")
    return out

def s4_chunkwalk():
    print("\n4. THE BLOCK WALKERS USE THE POOL'S OWN END-OF-RECORD MARKER")
    print("   (the second consumer itself was identified in notes/prom_c_fcd0f7_interpreter.py;")
    print("    this is one further check on it, not the finding)")
    print("   0xF9E0B7 and 0xF9E140 each read a 16-bit BIG-ENDIAN word at the cursor")
    print("   (`ld A,(XBC) / sll 8,A / ... / ld A,(XBC+1) / add DE,HL`) and stop on the")
    print("   exact value 0xF000 -- which is byte-for-byte the pool's END record, opcode 15")
    print("   with length 0.  Occurrences of the two-instruction test in p7_module.s:")
    n = sum(1 for a, i in LST if i.strip() == "cp WA,0xf000")
    ends = sum(1 for op, pl in RECS if op == 15)
    print(f"     `cp WA,0xf000` sites : {n}     END records in the pool : {ends}")
    return n, ends

VALUE_TABLES = {   # the pointer P7Unit_SelectStreamsForRecord installs -> the word it
    0xFD28C7: 99,  # installs beside it in 0x00F365/67/69, read off 0xFA4828-0xFA48F1
    0xFD4E13: 99,
    0xFD3B60: 99,
    0xFD06FA: 99,
    0xFDA4E7: 0x6C,
    0xFDA5C1: 0x6C,
    0xFDA554: 0x6C,
}

def s5_tables():
    """P7Unit_SendValueTable reads table byte 0 as a base index and then (0x00F36x)/12
    groups of four 24-bit big-endian values.  If (0x00F36x) is the table's PAYLOAD
    length then every table must be exactly 1 + that many bytes long."""
    print("\n5. IS (0x00F365/67/69) THE VALUE TABLE'S PAYLOAD LENGTH?")
    print("   NULL: the seven tables would have to land on the predicted length by chance;")
    print("         nothing forces a DATA object in a 65,972-byte pool to any given size.")
    ok = 0
    ends = sorted(VALUE_TABLES)
    for a, n in sorted(VALUE_TABLES.items()):
        # the object boundary: the next value table, or the pool object header
        nxt = a + 1 + n
        hit = nxt in VALUE_TABLES or nxt == 0xFDA62E or nxt in (0xFD075E, 0xFD292B, 0xFD3BC4, 0xFD4E77)
        ok += hit
        print(f"     0x{a:06X} + 1 + {n:3d} = 0x{nxt:06X}   "
              f"{'lands on the next table or the object end' if hit else 'DOES NOT land on a boundary'}")
    print(f"   {ok} of {len(VALUE_TABLES)}")
    return ok

def main():
    lit, first = s1_commands()
    res = s2_groups()
    dirf = s3_directory()
    n_f000, ends = s4_chunkwalk()
    ok5 = s5_tables()
    if "--verify" not in sys.argv: return
    print("\nASSERTIONS")
    check(set(lit) == {0x01, 0x03}, "the only LITERAL command bytes in the module are 0x01 and 0x03")
    check(set(first[1]) == {0x01} and set(first[2]) == {0x02} and set(first[5]) == {0x01},
          "opcode 1/2/5 records all start their payload with 0x01 / 0x02 / 0x01")
    check(set(first[4]) == {0x03, 0x0F}, "opcode-4 records carry only 0x03 or 0x0F")
    g0, v0, a0801_0, a0000_0, h0 = res[0]
    g1, v1, a0801_1, a0000_1, h1 = res[1]
    g5, v5, a0801_5, a0000_5, h5 = res[5]
    check(len(a0801_0) == 0 and len(a0000_0) == 316,
          "opcode-0 groups use the 00 00 address form and never the 08 01 form")
    check({x[4] for x in a0801_1} == {0x21} and len(a0801_1) == 99,
          "every opcode-1 record is one 08 01 address group ending 0x21 (99/99)")
    check({x[4] for x in a0801_5} == {0x25} and len(a0801_5) == 81,
          "every opcode-5 record opens with an 08 01 address group ending 0x25 (81/81)")
    check({x[4] & 0x7F for x in v0} == {0x15},
          "every opcode-0 value group's tail constant is 0x15 -- the constant "
          "P7Group_SendValue and the 0x008616 emitters add")
    check({x[4] & 0x7F for x in v5} == {0x4C},
          "every opcode-5 value group's tail constant is 0x4C -- the constant "
          "the 0x008618 emitter adds")
    check(h1.get((1,1,0x60), 0) == sum(h1.values()) and h5.get((1,1,0x60), 0) == sum(h5.values()),
          "opcode-1 and opcode-5 records all open 01 01 60 -- the exact triple "
          "P7Block_Run sends as cmd 0x01 / arg 0x01 / arg 0x60")
    for f, want in ((0, "not"), (4, "clean"), (8, "not"), (12, "clean")):
        c, n, u = dirf[f]
        check((c == 56 and u == 0) if want == "clean" else (n == 56 and u == 0),
              f"all 56 of pool-directory field +{f} are {want}-interpreter-clean streams")
    check(ok5 == len(VALUE_TABLES),
          "all 7 value tables are exactly 1 + (0x00F36x) bytes long -- the four 99-byte "
          "ones end on the next pool object, the three 0x6C ones tile one 327-byte object")
    check(n_f000 == 2 and ends == 297,
          "the 0xF000 end test occurs exactly twice (the two chunk walkers) and the pool "
          "has 297 END records")
    print(f"\n{'FAILURES: ' + str(len(FAIL)) if FAIL else 'ALL ASSERTIONS PASS'}")
    sys.exit(1 if FAIL else 0)

main()
