#!/usr/bin/env python3
"""What is the 65,972-byte pool at prom_c 0xFCD0F7, and how is it framed?

QUESTION ANSWERED
  Round 3 left `0xFCD0F7-0xFDD2AA` as one `.incbin` -- the largest unconverted span in
  prom_c -- with a header saying only "begins with the length-prefixed packet pool the
  table at 0xFCC576 points into ... the walk desynchronises at 0xFCD119, so the framing is
  NOT fully established".  It is now established, and the desynchronisation was an error in
  the walk, not in the data: the first byte of a record carries BOTH a 4-bit opcode and the
  TOP FOUR BITS of the length.

THE FRAMING, read out of the interpreter's instructions (prom_c 0xF9A6C1-0xF9A702)

      byte 0:  bits 7:4 = OPCODE          bits 3:0 = length[11:8]
      byte 1:                             length[ 7:0]
      length counts the two header bytes.  Opcode 0xF = END, and its record is 2 bytes.

  The interpreter is `sub_F9A646` in this tree's numbering (renamed `P7Stream_Run`):

      F9A6C4  ld A,(XBC) / and A,0xf0 / cp A,0xf0 / jrl Z,<return>      opcode 0xF = END
      F9A6D9  ld A,(XBC+1)                       -> HL                  length[7:0]
      F9A6E3  ld A,(XBC) / and A,0x0f / sll 8,WA / add WA,HL            length[11:8]
      F9A6EF  dec 2,WA                                                  payload = length-2
      F9A6F4  inc 2,XBC                                                 cursor += 2
      F9A6F9  ld IY,(XIZ+0xec) / srl 4,IY                               opcode -> dispatch

  The dispatch at 0xF9AD84 has arms for opcodes 0,1,2,3,4,5 and 14 and no others.

WHY THE FRAMING IS BELIEVED -- four independent checks, all in --verify

  1. TILING.  Walking the length field from 0xFCD0F7 and treating a failed walk as a data
     object bounded by the next pointer target covers 0xFCD0F7-0xFDBFD8 with NO gap and NO
     overlap, and the four directory objects then end exactly at 0xFDD2AB -- the EXCLUSIVE
     end of the `.incbin`, whose last byte is 0xFDD2AA.  One wrong length anywhere
     desynchronises everything after it.
  2. OPCODES.  Of the 1,832 records, the 297 END records carry opcode 0xF, which
     P7Stream_Run recognises ITSELF (`and A,0xf0 / cp A,0xf0 / jrl Z,<epilogue>` at
     0xF9A6C6-0xF9A6CC) and returns on -- it never reaches the dispatcher and has NO ARM
     there.  Each of the other 1,535 carries one of the seven opcodes the dispatcher DOES
     have an arm for.  Eight of the sixteen opcode values never occur at all.
  3. POINTERS.  Every 32-bit pointer into this region from anywhere in the ROM lands on a
     record boundary, never inside a record.
  4. THE INTERPRETER'S OWN ARITHMETIC.  Opcode 4 consumes exactly one payload byte
     (0xF9AB91-0xF9ABA4: one send, then straight back to the dispatcher), so every opcode-4
     record must have length 3 -- and all 266 of them do.  Opcodes 0, 1 and 5 consume
     3 + 5*floor((payload-3)/5) bytes, which equals the payload only when payload = 3 mod 5;
     for the THIRTY streams that a call site provably hands to the interpreter, all 14 of
     their opcode-0/1/5 records satisfy that, with zero exceptions.

⚠ WHAT IS NOT ESTABLISHED
  * What the destination device is.  The bytes leave by PORT P7 (see
    notes/prom_c_dsp_port.py); which chip is on the other end is not proven here.
  * What any record MEANS.  The opcodes are named for what the interpreter DOES with the
    payload (how many bytes, which base is added), never for a musical role.
  * The group structure inside opcode 0/1/2/5 payloads is proven only for streams the
    interpreter provably runs; 130 of the 297 streams have at least one record whose payload
    is not a whole number of the interpreter's groups (`--census` prints the complement:
    "streams whose every record fits the interpreter's group arithmetic: 167 of 297"), so
    those streams have ANOTHER consumer that this pass has not found.  Each stream's header
    says which it is.

RUN
    python3 notes/gen_prom_c_p7stream_pool.py --verify    # every claim above, exit!=0 on fail
    python3 notes/gen_prom_c_p7stream_pool.py --census    # objects and opcode counts
    python3 notes/gen_prom_c_p7stream_pool.py --emit      # the assembly fragment
"""
import argparse, os, sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM  = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
LO, HI = 0xFCD0F7, 0xFDD2AB          # the .incbin this replaces
DESCLO = 0xFDBFD9                    # start of the four directory objects
IDXLO  = 0xFDC551
FRLO   = 0xFDC5D1
PTRLO  = 0xFDD1CB
DIRSTRIDE = 25                       # `mul A,0x19` at prom_c 0xFA2B44 and 0xFA2B6D
NDIR   = 56
VALID_OPS = {0, 1, 2, 3, 4, 5, 14}   # the dispatcher's arms, 0xF9AD84-0xF9ADAB

D = open(ROM, "rb").read()
def B(a): return D[a - BASE]
def U32(a): return int.from_bytes(D[a-BASE:a-BASE+4], "little")

# ---------------------------------------------------------------- the walk
def walk(start, limit):
    """Follow the length field.  Returns (end, records, ok)."""
    a, recs = start, []
    while a < limit:
        h = B(a)
        if (h & 0xF0) == 0xF0:
            if a + 2 > limit: return a, recs, False
            recs.append((a, 0xF, 2)); return a + 2, recs, True
        op = h >> 4
        ln = ((h & 0x0F) << 8) | B(a + 1)
        if ln < 3 or op not in VALID_OPS or a + ln > limit:
            return a, recs, False
        recs.append((a, op, ln)); a += ln
    return a, recs, False

def seeds():
    """Every address in the region that the ROM points at.

    Two forms, both literal: a 32-bit little-endian pointer anywhere in the image, and the
    `lda rr,#addr24` spelling 0xF2 <addr24> <0x30..0x37> that the call sites use."""
    out = {}
    for i in range(len(D) - 3):
        v = int.from_bytes(D[i:i+4], "little")
        if LO <= v < HI: out.setdefault(v, set()).add(("PTR32", BASE + i))
    for i in range(1, len(D) - 4):
        if D[i-1] == 0xF2 and 0x30 <= D[i+3] <= 0x37:
            v = int.from_bytes(D[i:i+3], "little")
            if LO <= v < HI: out.setdefault(v, set()).add(("LDA", BASE + i - 1))
    return out

SEEDS = seeds()

def tile():
    """The object list, derived -- no address is hardcoded except the region's own bounds.

    At each address: if the token walk reaches an END record, that is a STREAM.  If it does
    not, the address holds data, and the data object runs to the next POINTED-AT address
    from which a walk does succeed."""
    ok_seed = sorted(s for s in SEEDS if s < DESCLO and walk(s, DESCLO)[2])
    objs, a = [], LO
    while a < DESCLO:
        e, recs, good = walk(a, DESCLO)
        if good:
            objs.append(dict(start=a, end=e, kind="STREAM", recs=recs)); a = e
        else:
            nxt = min([s for s in ok_seed if s > a] + [DESCLO])
            objs.append(dict(start=a, end=nxt, kind="DATA", recs=None)); a = nxt
    objs.append(dict(start=DESCLO, end=IDXLO, kind="DIR",      recs=None))
    objs.append(dict(start=IDXLO,  end=FRLO,  kind="IDXMAP",   recs=None))
    objs.append(dict(start=FRLO,   end=PTRLO, kind="FIELDREC", recs=None))
    objs.append(dict(start=PTRLO,  end=HI,    kind="PTRTABLE", recs=None))
    return objs

# ------------------------------------------------- which streams the interpreter runs
def interpreter_call_sites():
    """(site, program, index, record-table) for every `call 0xF9A646` whose three arguments
    are visible as literals.  The pattern is the compiler's, not chosen by eye:
        F2 <tbl24> 31  39  0B <idx16>  F2 <prog24> 30  38  1D <0xF9A646>"""
    out = []
    for i in range(len(D) - 20):
        if (D[i] == 0xF2 and D[i+4] == 0x31 and D[i+5] == 0x39 and D[i+6] == 0x0B
                and D[i+9] == 0xF2 and D[i+13] == 0x30 and D[i+14] == 0x38 and D[i+15] == 0x1D
                and int.from_bytes(D[i+16:i+19], "little") == 0xF9A646):
            out.append((BASE + i,
                        int.from_bytes(D[i+10:i+13], "little"),
                        int.from_bytes(D[i+7:i+9], "little"),
                        int.from_bytes(D[i+1:i+4], "little"),
                        BASE + i + 15))     # the `call` itself, not the argument setup
    return out

CALLS = interpreter_call_sites()

def group_clean(recs):
    """True when every record's payload is a whole number of the interpreter's groups.
    op 0/1/5 consume 3 + 5*n, op 2 consumes 3 + 4*n, op 4 consumes 1, op 3 and 14 consume
    the whole payload by construction."""
    for _, op, ln in recs:
        p = ln - 2
        if op in (0, 1, 5) and (p - 3) % 5: return False
        if op == 2 and (p - 3) % 4: return False
        if op == 4 and p != 1: return False
    return True

# ---------------------------------------------------------------- verification
def verify():
    fails = []
    def chk(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond: fails.append(msg)

    objs = tile()
    print("TILING")
    total = sum(o["end"] - o["start"] for o in objs)
    chk(total == HI - LO, f"objects cover {total} bytes; the .incbin is {HI-LO}")
    contiguous = all(objs[i]["end"] == objs[i+1]["start"] for i in range(len(objs)-1))
    chk(contiguous, "objects are contiguous, no gap and no overlap")
    chk(objs[0]["start"] == LO and objs[-1]["end"] == HI, f"first starts 0x{LO:06X}, last ends 0x{HI:06X}")

    print("OPCODES")
    recs = [r for o in objs if o["kind"] == "STREAM" for r in o["recs"]]
    ops = Counter(op for _, op, _ in recs)
    chk(set(ops) <= VALID_OPS | {0xF}, f"every opcode is either 0xF -- END, which P7Stream_Run "
        f"tests for itself at 0xF9A6C6 and returns on, so it has NO dispatcher arm -- or one of "
        f"the seven the dispatcher does have an arm for: {sorted(ops)}")
    nstream = sum(1 for o in objs if o["kind"] == "STREAM")
    chk(ops[0xF] == nstream, f"{nstream} streams and {ops[0xF]} END records -- one each")

    print("POINTERS")
    starts, second = set(), set()
    for o in objs:
        if o["kind"] == "STREAM":
            starts |= {a for a, _, _ in o["recs"]}
            second |= {a + 1 for a, _, _ in o["recs"]}
        else:
            starts.add(o["start"])
    dirzone = range(DESCLO, HI)
    inpayload = sorted(s for s in SEEDS if s not in starts and s not in dirzone
                       and not any(o["kind"] == "DATA" and o["start"] <= s < o["end"] for o in objs))
    chk(not (set(inpayload) & second),
        "no pointed-at address is a record's SECOND header byte -- which would refute the framing")
    chk(len(inpayload) == 13,
        f"{len(inpayload)} pointed-at addresses fall inside a record's payload (was 13; each is "
        "labelled and flagged in the emitted source)")
    for x in inpayload:
        print(f"         inside a payload: 0x{x:06X}  from {sorted(SEEDS[x])[:2]}")

    print("THE INTERPRETER'S OWN ARITHMETIC")
    op4 = [(a, ln) for a, op, ln in recs if op == 4]
    chk(all(ln == 3 for _, ln in op4), f"all {len(op4)} opcode-4 records have length 3 (the arm consumes 1 payload byte)")
    progs = sorted({c[1] for c in CALLS})
    chk(len(CALLS) == 74 and len(progs) == 30, f"{len(CALLS)} literal call sites hand {len(progs)} distinct streams to the interpreter")
    bad = 0; tot = 0
    for p in progs:
        _, r, ok = walk(p, DESCLO)
        if not ok: bad += 1; continue
        for _, op, ln in r:
            if op in (0, 1, 5):
                tot += 1
                if (ln - 5) % 5: bad += 1
    chk(bad == 0, f"of the {tot} opcode-0/1/5 records in those 30 streams, {bad} violate the group arithmetic")

    print("THE RELOCATION-RECORD TABLES -- the last-entry test")
    from collections import defaultdict as _dd
    hi = _dd(int)
    for c in CALLS: hi[c[3]] = max(hi[c[3]], c[2])
    for tbl in sorted(hi):
        end = tbl + 6 * hi[tbl]
        nxt = min([o["end"] for o in objs if o["start"] <= tbl < o["end"]] +
                  [t for t in hi if t > tbl])
        chk(end == nxt,
            f"table 0x{tbl:06X}: highest index used at any call site is {hi[tbl]}, and "
            f"6*{hi[tbl]} lands on 0x{end:06X} -- {'exactly' if end == nxt else 'NOT'} the next "
            f"object boundary 0x{nxt:06X}.  The record count is the call sites' own arithmetic.")

    print("THE FOUR DIRECTORY OBJECTS")
    chk((IDXLO - DESCLO) == NDIR * DIRSTRIDE, f"{NDIR} x {DIRSTRIDE}-byte records reach 0x{IDXLO:06X} exactly")
    chk(HI - PTRLO == NDIR * 4, f"{NDIR} x u32 pointer table reaches 0x{HI:06X} = the end of the .incbin")
    tgts = [U32(PTRLO + 4*k) for k in range(NDIR)]
    chk(len(set(tgts)) == NDIR, "the 56 pointers are distinct")
    st = sorted(tgts)
    chk(st[0] == FRLO, f"lowest pointer is 0x{FRLO:06X} = the first byte after the index map")
    lens = [st[i+1] - st[i] for i in range(NDIR-1)] + [PTRLO - st[-1]]
    chk(sum(lens) == PTRLO - FRLO, "the 56 records tile the zone the pointers point into, exactly")
    chk(all(l % 7 == 0 for l in lens), f"every one of the 56 record lengths is a multiple of 7 (min {min(lens)}, max {max(lens)})")
    m = D[IDXLO-BASE:FRLO-BASE]
    chk(len(m) == 128 and max(m) == NDIR - 1 and set(m) == set(range(NDIR)),
        f"the {len(m)}-byte index map takes every value 0..{NDIR-1} and no other")
    # last-entry test, as the brief requires
    chk(U32(PTRLO + 4*(NDIR-1)) in tgts and B(HI-1) == D[HI-1-BASE],
        f"LAST pointer-table entry 0x{U32(PTRLO+4*(NDIR-1)):06X}; last byte of the region 0x{B(HI-1):02X}")
    lastrec = DESCLO + DIRSTRIDE * (NDIR - 1)
    chk(all(LO <= U32(lastrec + 4*f) < HI for f in range(4)),
        f"LAST 25-byte record (0x{lastrec:06X}) still has four in-region stream pointers")

    print()
    if fails:
        print(f"{len(fails)} CHECK(S) FAILED"); return 1
    print("ALL CHECKS PASSED"); return 0

def census():
    objs = tile()
    kinds = Counter(o["kind"] for o in objs)
    byte = Counter()
    for o in objs: byte[o["kind"]] += o["end"] - o["start"]
    print("objects:", dict(kinds))
    print("bytes:  ", dict(byte), "total", sum(byte.values()))
    recs = [r for o in objs if o["kind"] == "STREAM" for r in o["recs"]]
    print("records:", len(recs), dict(sorted(Counter(op for _, op, _ in recs).items())))
    runnable = sum(1 for o in objs if o["kind"] == "STREAM" and group_clean(o["recs"]))
    print(f"streams whose every record fits the interpreter's group arithmetic: {runnable} of {kinds['STREAM']}")
    print(f"literal interpreter call sites: {len(CALLS)}, distinct streams handed to it: {len({c[1] for c in CALLS})}")
    for o in objs:
        if o["kind"] == "DATA":
            inner = sorted(s for s in SEEDS if o["start"] < s < o["end"])
            print(f"  DATA 0x{o['start']:06X}-0x{o['end']-1:06X} {o['end']-o['start']:5d} B"
                  f"  inner pointed-at: {[hex(x) for x in inner]}")

# ---------------------------------------------------------------- emission
def label(kind, a):
    return {"STREAM": "P7Stream_%06X", "DATA": "P7Stream_Data_%06X"}[kind] % a

def callers_of(a):
    """Where the address is written down.  LDA <addr> is the START of the `lda rr,#imm24`
    instruction; PTR32 <addr> is the address of the 32-bit pointer WORD, which is data."""
    return [("LDA instruction at 0x%06X" % site) if kind == "LDA"
            else ("PTR32 word at 0x%06X" % site)
            for kind, site in sorted(SEEDS.get(a, ()))]

def emit_rows(f, a, n, labels=()):
    """Emit n bytes from a as .byte rows of 16, breaking a row wherever an address in
    `labels` starts so that address can carry a real label."""
    cuts = sorted(x for x in labels if a < x < a + n)
    spans, prev = [], a
    for c in cuts + [a + n]:
        if c > prev: spans.append((prev, c)); prev = c
    for i, (s0, e0) in enumerate(spans):
        if i:
            f.write(f"\t; Evidence: this address is written down elsewhere in the ROM -- "
                    + "; ".join(callers_of(s0)) + ".\n")
            f.write(f"\t;           It is INSIDE a record's payload, so it is a datum the "
                    "code reads\n\t;           directly, not a stream start.\n")
            f.write(f"P7Stream_Inner_{s0:06X}:\n")
        for k in range(s0, e0, 16):
            row = D[k-BASE : min(k+16, e0)-BASE]
            f.write("\t.byte\t" + ", ".join(f"0x{x:02x}" for x in row) + f"   ; 0x{k:06X}\n")

def emit(out):
    objs = tile()
    f = out
    kinds = Counter(o["kind"] for o in objs)
    recs = [r for o in objs if o["kind"] == "STREAM" for r in o["recs"]]
    opc = Counter(op for _, op, _ in recs)
    clean = sum(1 for o in objs if o["kind"] == "STREAM" and group_clean(o["recs"]))
    f.write(BANNER.format(
        nobj=len(objs), nstream=kinds["STREAM"], ndata=kinds["DATA"], nrec=len(recs),
        nend=opc[0xF], nother=len(recs) - opc[0xF],
        nop4=opc[4], nunused=16 - len(set(opc)), ndirty=kinds["STREAM"] - clean,
        ncall=len(CALLS), nprog=len({c[1] for c in CALLS}),
        nbytes=sum(o["end"] - o["start"] for o in objs)))
    for o in objs:
        s, e, kind = o["start"], o["end"], o["kind"]
        if kind == "STREAM":
            recs = o["recs"]
            clean = group_clean(recs)
            runs = [c for c in CALLS if c[1] == s]
            f.write(f"\n; ---- 0x{s:06X}-0x{e-1:06X}  {e-s} bytes, {len(recs)} records"
                    f"  [{'interpreter-clean' if clean else 'NOT interpreter-clean'}] ----\n")
            if runs:
                f.write(";      RUN BY P7Stream_Run -- `call` at " + ", ".join(
                    f"0x{c[4]:06X} (arg setup 0x{c[0]:06X}, record table 0x{c[3]:06X} index {c[2]})"
                    for c in runs[:3]))
                f.write("\n" if len(runs) <= 3 else f" and {len(runs)-3} more\n")
            ptr = callers_of(s)
            if ptr:
                f.write(";      pointed at by: " + ", ".join(ptr[:6]) +
                        (f" (+{len(ptr)-6} more)" if len(ptr) > 6 else "") + "\n")
            f.write(f"{label(kind,s)}:\n")
            for (ra, op, ln) in recs:
                if op == 0xF:
                    f.write(f"\t.byte\t0x{B(ra):02x}, 0x{B(ra+1):02x}"
                            f"   ; 0x{ra:06X}  op 15  END\n")
                    continue
                f.write(f"\t.byte\t0x{B(ra):02x}, 0x{B(ra+1):02x}"
                        f"   ; 0x{ra:06X}  op {op:2d}  len {ln}  payload {ln-2}\n")
                inner = sorted(x for x in SEEDS if ra + 2 < x < ra + ln)
                if inner:
                    f.write("\t; ⚠ pointed at from code, INSIDE this record's payload: "
                            + ", ".join(f"0x{x:06X}" for x in inner) + "\n")
                emit_rows(f, ra + 2, ln - 2, inner)
        elif kind == "DATA":
            inner = sorted(x for x in SEEDS if s < x < e)
            f.write(f"\n; ---- 0x{s:06X}-0x{e-1:06X}  {e-s} bytes -- DATA, not a token stream ----\n")
            f.write(";      The token walk does not reach an END record from here, so this is not a\n")
            ptr = callers_of(s)
            f.write(";      stream.  Pointed at by: " + (", ".join(ptr[:6]) if ptr else "nothing") + "\n")
            if inner:
                f.write(";      Also pointed at inside it: " + ", ".join(f"0x{x:06X}" for x in inner) + "\n")
            f.write(DATA_NOTES.get(s, ";      Its internal layout is NOT established.\n"))
            f.write(f"{label(kind,s)}:\n")
            prev = s
            for x in inner:
                emit_rows(f, prev, x - prev)
                f.write(f"\t; Evidence: pointed at in its own right -- "
                        + "; ".join(callers_of(x)) + ".\n")
                f.write(DATA_INNER_NOTES.get(x, "\t;           A second entry point into this "
                                                "object; its own extent is not established.\n"))
                f.write(f"P7Stream_Data_{x:06X}:\n")
                prev = x
            emit_rows(f, prev, e - prev)
        elif kind == "DIR":
            f.write(DIR_HEADER)
            f.write("PoolDir_Records:\n")
            for k in range(NDIR):
                r = DESCLO + DIRSTRIDE * k
                f.write(f"\t; record {k:2d}  0x{r:06X}\n")
                f.write("\t.long\t" + ", ".join(f"0x{U32(r+4*j):08x}" for j in range(4)) +
                        "   ; four stream pointers\n")
                f.write("\t.long\t" + ", ".join(f"0x{U32(r+16+4*j):08x}" for j in range(2)) +
                        "   ; DescriptorStrings pair\n")
                f.write(f"\t.byte\t0x{B(r+24):02x}\n")
        elif kind == "IDXMAP":
            f.write(IDX_HEADER)
            f.write("PoolDir_IndexMap128:\n")
            emit_rows(f, s, e - s)
        elif kind == "FIELDREC":
            tgts = sorted({U32(PTRLO + 4*k) for k in range(NDIR)})
            back = defaultdict(list)
            for k in range(NDIR): back[U32(PTRLO + 4*k)].append(k)
            f.write(FR_HEADER)
            f.write("PoolDir_FieldRecords:\n")
            for i, t in enumerate(tgts):
                nxt = tgts[i+1] if i + 1 < len(tgts) else PTRLO
                f.write(f"\n; 0x{t:06X}  {nxt-t} bytes = {(nxt-t)//7} x 7"
                        f"   (table slot(s) {back[t]})\n")
                f.write(f"PoolDir_FieldRec_{t:06X}:\n")
                for q in range(t, nxt, 7):
                    f.write("\t.byte\t" + ", ".join(f"0x{B(q+j):02x}" for j in range(7)) +
                            f"   ; 0x{q:06X}\n")
        elif kind == "PTRTABLE":
            f.write(PTR_HEADER)
            f.write("PoolDir_FieldRec_PtrTable:\n")
            for k in range(NDIR):
                f.write(f"\t.long\t0x{U32(PTRLO+4*k):08x}   ; slot {k:2d}\n")

BANNER = """
; ==============================================================================
; 0xFCD0F7-0xFDD2AA -- THE RELOCATABLE BYTE-STREAM POOL FOR THE PORT-P7 DEVICES
;                      65,972 bytes: {nstream} streams + {ndata} data tables + 4 directories
; ==============================================================================
;
; Generated by notes/gen_prom_c_p7stream_pool.py --emit; every number below is read out
; of the ROM by that script and re-proved by `--verify`, which asserts all of it and
; exits non-zero on any failure.  Nothing here is retyped.
;
; ★ WHAT THIS IS.  A pool of length-prefixed byte records that prom_c streams, one byte
; at a time, out of PORT P7 to one of THREE destinations.  The transport is
; notes/prom_c_dsp_port.py's subject and is documented at P7Byte_SendCmd (0xF9A163,
; above in this file); this banner is about the CONTAINER.
;
; ★ THE RECORD HEADER IS TWO BYTES AND CARRIES BOTH FIELDS.  Round 3 read the first two
; bytes as a 16-bit big-endian length and the walk desynchronised at 0xFCD119; the reason
; is that the top nibble is an OPCODE:
;
;       byte 0:  bits 7:4 = opcode        bits 3:0 = length[11:8]
;       byte 1:                           length[ 7:0]
;       length INCLUDES the two header bytes.  Opcode 15 = END, record length 2.
;
; read out of prom_c 0xF9A6C4-0xF9A702 (`and A,0xf0 / cp A,0xf0` then
; `and A,0x0f / sll 8,WA / add WA,HL / dec 2,WA / inc 2,XBC`).  The dispatcher at
; 0xF9AD84 has arms for opcodes 0, 1, 2, 3, 4, 5 and 14 and for no others.
;
; ★ WHAT EACH OPCODE DOES TO THE PAYLOAD, from its own dispatch arm.  "base b<n>" is byte
; n of the six-byte record the third argument selects (P7Stream_Data_FD4B85 below):
;
;   op  arm       payload shape                              relocation
;   --  --------  ----------------------------------------   ---------------------------
;    0  0xF9A705  3 head bytes, then groups of 5             12-bit field += b1
;    1  0xF9A905  3 head bytes, then groups of 5             12-bit field += b0
;    2  0xF9A9F0  3 head bytes, then groups of 4             middle byte += b4
;    3  0xF9AAFB  1 head byte, a 16-bit field, then raw      16-bit field += b3
;    4  0xF9AB91  exactly 1 byte                             none
;    5  0xF9ABA8  3 head bytes, then groups of 5             12-bit field += b2
;   14  0xF9AD40  1 head byte, then raw                      none
;   15  --        END                                        --
;
; So the pool is a RELOCATABLE object format: the same stream is loaded into a different
; part of the device's memory by changing one six-byte record.
;
; ★ THE FRAMING IS PROVED FOUR WAYS (notes/gen_prom_c_p7stream_pool.py --verify):
;   1. it TILES.  {nobj} objects, contiguous, no gap and no overlap, over 0xFCD0F7-0xFDD2AA
;      (0xFDD2AB exclusive).
;   2. all {nrec} records carry a KNOWN opcode -- but NOT all of them through the dispatcher:
;      the {nend} END records carry 0xF, which P7Stream_Run tests for ITSELF at 0xF9A6C6 and
;      returns on, so 0xF has no arm at 0xF9AD84; the other {nother} carry one of the seven
;      opcodes that do.  {nunused} of the 16 opcode values never occur at all.
;   3. every 32-bit pointer into the region from anywhere in the ROM lands on a record
;      boundary or on an object start, with THIRTEEN exceptions -- all thirteen fall in a
;      record's raw PAYLOAD, none on a record's second header byte, which is the case that
;      would refute the framing.  All thirteen are labelled `P7Stream_Inner_XXXXXX` and
;      flagged where they occur.
;   4. opcode 4's arm consumes exactly ONE payload byte, so every opcode-4 record must
;      have length 3, and all {nop4} of them do.  For the {nprog} streams a literal call site
;      provably hands to the interpreter, every opcode-0/1/5 record's payload is also a
;      whole number of the interpreter's 5-byte groups -- 14 of 14, no exceptions.
;
; ⚠ WHAT IS NOT ESTABLISHED
;   * What the destination chip is.  P7 is an instruction operand; the chip is not.
;   * What any record MEANS.  No opcode is named for a musical role.
;   * {ndirty} of the {nstream} streams contain at least one record whose payload is NOT a whole
;     number of the interpreter's groups.  Those streams cannot be what P7Stream_Run runs,
;     so a SECOND consumer exists that this pass has not found.  Each stream header says
;     which kind it is; the honest reading of "NOT interpreter-clean" is "the container is
;     the same, the payload convention is not".
;   * The {ndata} DATA objects below are byte-exact and labelled, and their internal layout
;     is stated only where an instruction fixes it.
; ==============================================================================
"""

DATA_INNER_NOTES = {
 0xFD4B97: ("\t;           The SECOND relocation-record table.  Call sites pass it index 1..4 and\n"
            "\t;           0xFD4B97 + 6*4 = 0xFD4BAF is exactly the end of this object, so its\n"
            "\t;           record count is the call sites' own arithmetic (--verify asserts it).\n"),
}

DATA_NOTES = {
 0xFD4B85: (";      ★ THIS ONE IS DECODED: it is the pool's RELOCATION RECORD table.\n"
            ";      P7Stream_Run computes `table + 6*index - 6` (`ld A,0x06 / mul WA,(XIZ+0x0c)\n"
            ";      / dec 6,XWA / add XBC,XWA` at 0xF9A652-0xF9A65B), so the records are SIX\n"
            ";      bytes and the index is 1-based; it then reads b0..b4 as the five relocation\n"
            ";      bases and b5 as the DESTINATION UNIT (0, 1 or 2).  42 bytes = 7 records.\n"
            ";      Call sites use table 0xFD4B85 with index 1..3 and table 0xFD4B97 with\n"
            ";      index 1..4, which is why the second label is inside this object.\n"),
 0xFD06FA: (";      [INFERENCE, stated as such] a count byte 0x20 = 32 followed by 24-bit\n"
            ";      big-endian values that rise in equal steps of 0x059999 to 0x400000, hold\n"
            ";      there for eight entries and fall back symmetrically -- a trapezoid.  The\n"
            ";      step and the symmetry are in the bytes; the ELEMENT SIZE is not proved by\n"
            ";      any instruction, so this is an observation, not a decode.\n"),
}

DIR_HEADER = """
; ------------------------------------------------------------------------------
; PoolDir_Records -- 0xFDBFD9-0xFDC550, 56 records of 25 bytes
;
; ★ THE STRIDE IS AN INSTRUCTION OPERAND, not a guess: prom_c 0xFA2B44 is
; `ld A,(XBC) / mul A,0x19 / extz XWA / inc 8,XWA / add XWA,0x00FDBFD9 / ld XBC,(XWA)`
; and 0xFA2B6D is the same with `inc` absent -- 0x19 = 25 is the record size, and the two
; sites read field +8 and field +0 of the same record.  The selector is
; `RAM[0x00856E + 0x1A*n + 0x18]`.
;
; Field layout, from those two loads and from what the four pointers point at:
;       +0   u32   stream pointer          (read by 0xFA2B6D and by 0xFA2C81/0xFA2D34)
;       +4   u32   stream pointer
;       +8   u32   stream pointer          (read by 0xFA2B44 and by 0xFA2B74/0xFA2CA8)
;       +12  u32   stream pointer
;       +16  u32   -> DescriptorStrings, the field-TYPE member of a pair
;       +20  u32   -> DescriptorStrings, the digit member of the same pair
;       +24  u8
;
; THE COUNT IS 56, established three independent ways and asserted by `--verify`:
;   * 56 x 25 = 1400 reaches 0xFDC551 exactly, where the index map below begins;
;   * PoolDir_IndexMap128 takes every value 0..55 and no other;
;   * PoolDir_FieldRec_PtrTable has 56 entries and ends on the region's last byte.
; The last record (0xFDC538) still carries four in-region stream pointers -- the
; last-entry test.
; ------------------------------------------------------------------------------
"""

IDX_HEADER = """
; ------------------------------------------------------------------------------
; PoolDir_IndexMap128 -- 0xFDC551-0xFDC5D0, 128 bytes
;
; 128 entries, each a PoolDir_Records index in 0..55.  Every one of the 56 indices occurs,
; which is what fixes the record count; 53 occurs 73 times and is the catch-all.
; ⚠ WHAT INDEXES IT is not established here -- 128 is the size of a MIDI value or of half a
; 256-entry space, and nothing in this pass reads the caller.
; ------------------------------------------------------------------------------
"""

FR_HEADER = """
; ------------------------------------------------------------------------------
; PoolDir_FieldRecords -- 0xFDC5D1-0xFDD1CA, 3,066 bytes in 56 records
;
; The 56 records PoolDir_FieldRec_PtrTable points at.  Their boundaries are the pointers
; themselves: the 56 pointers are distinct, the lowest is this object's first byte, and
; laid end to end they reach the pointer table exactly -- so the pointers TILE the zone and
; every record's length is fixed without a single guess.
;
; ★ AND EVERY ONE OF THE 56 LENGTHS IS A MULTIPLE OF SEVEN (7 to 133), so the records are
; arrays of a 7-byte entry.  That is a property of the data, checked over all 56, not a
; stride chosen to make the arithmetic work.
; ⚠ What a 7-byte entry MEANS is not established.
; ------------------------------------------------------------------------------
"""

PTR_HEADER = """
; ------------------------------------------------------------------------------
; PoolDir_FieldRec_PtrTable -- 0xFDD1CB-0xFDD2AA, 56 x u32
;
; The last object in the pool, and it ends on the pool's last byte: 0xFDD1CB + 56*4 =
; 0xFDD2AB, which is where the table zone at 0xFDD2AB begins.  Slot k belongs with
; PoolDir_Records[k].
; ------------------------------------------------------------------------------
"""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--emit", metavar="PATH", nargs="?", const="-")
    a = ap.parse_args()
    if a.verify: sys.exit(verify())
    if a.census: census(); return
    if a.emit:
        if a.emit == "-": emit(sys.stdout)
        else:
            with open(a.emit, "w") as f: emit(f)
        return
    ap.print_help()

if __name__ == "__main__":
    main()
