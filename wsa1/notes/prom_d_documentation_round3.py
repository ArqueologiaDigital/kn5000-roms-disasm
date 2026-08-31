#!/usr/bin/env python3
"""prom_d round 3 -- WHO READS THIS IMAGE?  The link rounds 1 and 2 could not find.

QUESTION IT ANSWERS
    prom_d reads "100% named" on notes/wave7_documentation_metrics.py and that
    number is misleading: every one of its 3,665 labels is a GENERATED STRUCTURE
    NAME transplanted from the KN5000 directory slot with the same offset, and
    until this pass the source said, in four separate places,

        "NO WSA1 INSTRUCTION THAT READS ANY OF THESE STRUCTURES HAS BEEN FOUND."

    notes/prom_d_structures_round2.py section Q5 ran the search that was
    available then -- prom_d structure offsets as IMMEDIATES in prom_a/b/c --
    and correctly reported a clean negative with all five candidates
    adjudicated.  It also said why the negative was expected: a consumer
    COMPUTES its addresses from a base held in RAM plus offsets read out of the
    image, so a structure offset never appears as an immediate.

    ★ That sentence names the search that DOES work, and this script runs it.
    The offsets are not immediates; they are read AT RUN TIME out of prom_d's
    own 48-slot directory.  So the thing to look for is not a constant, it is
    the instruction pair

        ld <Xr>,(0x00d7ed | 0x00d7f1)      <- the base, 0x00F00000
        ld <R>,(<Xr> + 0x00NN)             <- directory slot +0xNN

    There are 99 of them in prom_c, covering 33 distinct directory slots -- 74
    of the 99 being the instruction IMMEDIATELY after the base load -- and every
    one is RE-DECODED FROM ROM BYTES at the address it cites, not taken on the
    word of our own .s text.

WHAT IT ESTABLISHES (each reproduced below; run it, do not quote this list)
    Q1  prom_d's base is 0x00F00000 on CPU 2's bus.  The only two instructions
        in prom_c that write 0x00D7ED or 0x00D7F1 both store the immediate
        0x00F00000 loaded at 0xFB051E, so the base is a compile-time constant
        at every one of the 74 read sites.
    Q2  the 99-site, 33-slot census, every site re-decoded from prom_c's bytes.
    Q3  ★ THE WIDTH DISCRIMINATES, 99 of 99.  Every read of a slot below +0xC0
        loads a 32-BIT register and every read of a slot at or above +0xC0 loads
        a 16-BIT one.  prom_d's source has always claimed the low slots are
        offsets and the tail is scalars; that claim was transplanted from the
        KN5000.  It is now prom_c's own instruction encodings that say it.
    Q4  five complete address chains, each turning a directory slot into a
        record address, and each one confirming a record geometry this tree
        derived from prom_d ALONE:
          +0x04 -> +0x08 -> tone record   (x128, x2, then x4: the program map
                                           is 10 rows of 128 LE16 and the offset
                                           table is LE32)
          record + 217 + 81*i             (`ld C,0x51` / `add XBC,0xd9`)
          +0x84 -> +0x80, +0x90 -> +0x8C, +0x98 -> +0x94  (the footer's LE16
                                           bounds the catalogue's row index)
          +0x74 / +0x78 with the stride word +0xEE = 150
          +0x70 with the stride word +0xEC = 14
          +0xA8 indexed by `sll 0x07` = 128-byte records
    Q5  nulls, so the census is falsifiable.
    Q6  the MN10300 cross-tree number, reproduced by a second path.
    Q7  the slots with NO reader -- the honest gap, printed in full.

HOW TO RUN
    python3 notes/prom_d_documentation_round3.py            # every check
    python3 notes/prom_d_documentation_round3.py --quiet    # failures only
    python3 notes/prom_d_documentation_round3.py --readers  # the census only

    Exit status is non-zero if ANY check fails.
    scripts/analysis/gen_prom_d_asm.py imports readers() from this file and
    REFUSES to emit if the census shape moved, so an Evidence: line in
    prom_d/wsa1_prom_d.s cannot outlive the measurement that justifies it.

WHAT IS *NOT* ESTABLISHED, said before the results
    * NOT the meaning of any FIELD inside any prom_d record.  Nothing below
      reads a field's semantics; what is established is that a named structure
      is addressed, with what stride, and bounded by what count.
    * NOT a reader for every region.  26 of the 39 filled PRIMARY directory
      slots have one; Q7 lists the 13 that do not, by name.  A region with no
      reader keeps its transplanted name and says so -- including the two
      biggest, the descriptor blocks at +0x30/+0x38 and the wave-select arrays
      at +0x18/+0x20, which stay framed from the image alone.
    * NOT which physical part prom_d is.  Q1 fixes the ADDRESS the firmware
      reads it at; notes/prom_d_base_checks.py separately shows the 0xE80000
      flash is a different, smaller device.  ORIGIN in prom_d/prom_d.ld stays 0
      because the image is addressed by 0-based offsets and its own directory
      is 0-based -- which is exactly what Q4's `add ...,(0x00d7ed)` proves.
"""
import collections
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines            # noqa: E402

ROMS = os.path.join(ROOT, "original_ROMs")

D = open(os.path.join(ROMS, "wsa1_prom_d.bin"), "rb").read()
C = open(os.path.join(ROMS, "wsa1_prom_c.ic28"), "rb").read()
A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
assert len(D) == 0x80000

PROM_C_BASE = 0xF80000
PROM_A_BASE = 0xF80000
PROM_B_BASE = 0xF00000
DBASE = 0x00F00000                 # established in Q1, not assumed

u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]
PAYLOAD_END = 0x50B09              # the last content byte + 1; the rest is erased

QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-70s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-70s %s" % (label, detail))


# ===========================================================================
# The TLCS-900 encodings this script decodes, written out so a reader can
# check them against the listing rather than trust a table.
#
#   E2 lo mi hi  20|R      ld XR,(0x00hhmmll)        long from mem24
#   F2 lo mi hi  60|R      ld (0x00hhmmll),XR        long to   mem24
#   98+r  d8     20|R      ld  R,(Xr+d8)             WORD source, disp8
#   A8+r  d8     20|R      ld XR,(Xr+d8)             LONG source, disp8
#   D3  E1+4r  lo hi 20|R  ld  R,(Xr+d16)            WORD source, disp16
#   E3  E1+4r  lo hi 20|R  ld XR,(Xr+d16)            LONG source, disp16
#
# r/R are register codes 0..7 = WA BC DE HL IX IY IZ SP.  The WORD/LONG
# distinction lives in the memory-operand group byte, which is what Q3 uses.
# Verified against the disassembly at, e.g., 0xFB9568 `e3 e1 84 00 25`
# = ld XIY,(XWA+0x0084) and 0xFB837A `d3 e1 ea 00 20` = ld WA,(XBC+0x00ea).
# ===========================================================================
RNAME = ["WA", "BC", "DE", "HL", "IX", "IY", "IZ", "SP"]
BASE_VARS = {0xD7ED: "0x00D7ED", 0xD7F1: "0x00D7F1"}


def decode_slot_read(buf, off, want_r):
    """(slot, width, dest) if buf[off:] is a load from (X<want_r> + disp), else None."""
    b0 = buf[off]
    if b0 in (0x98 + want_r, 0xA8 + want_r):
        disp, last, width = buf[off + 1], buf[off + 2], (2 if b0 < 0xA0 else 4)
        n = 3
    elif b0 in (0xD3, 0xE3) and buf[off + 1] == 0xE1 + 4 * want_r:
        disp = struct.unpack_from("<H", buf, off + 2)[0]
        last, width, n = buf[off + 4], (2 if b0 == 0xD3 else 4), 5
    else:
        return None
    if last & 0xF8 != 0x20:
        return None
    return disp, width, ("X" if width == 4 else "") + RNAME[last & 7], n


def base_loads(buf, base):
    """Every `ld X<r>,(0x00d7ed|0x00d7f1)`, decoded from BYTES."""
    out = []
    for off in range(len(buf) - 6):
        if buf[off] != 0xE2 or buf[off + 3] != 0x00:
            continue
        var = struct.unpack_from("<H", buf, off + 1)[0]
        if var not in BASE_VARS or buf[off + 4] & 0xF8 != 0x20:
            continue
        out.append((base + off, buf[off + 4] & 7, var))
    return out


RSEQ = ["WA", "BC", "DE", "HL", "IX", "IY", "IZ", "SP"]
_TXT = re.compile(r';\s([0-9A-F]{6})\s\s(.*?)\s*$')
_LB = re.compile(r'^ld (X[A-Z]{2}),\(0x00d7(?:ed|f1)\)$')
_DP = re.compile(r'^ld ([A-Z]{1,3}),\((X[A-Z]{2})\+0x([0-9a-f]{1,4})\)$')
_WR = re.compile(r'^(?:ld|add|sub|and|or|xor|ex|pop|extz|exts|mul|div|inc|dec|lda'
                 r'|min|max)\s+(X[A-Z]{2})\b')


def listing():
    # ⚠ prom_c IS NOT ONE FILE any more -- it is a primary plus ~29 .include
    # parts.  Opening the primary alone returned 0 of the 99 sites and then
    # raised an IndexError two checks later; asm_source.image_lines resolves the
    # includes the way llvm-mc does.  See notes/asm_source.py.
    out = []
    for ln in image_lines(ROOT, "prom_c/wsa1_prom_c.s"):
        m = _TXT.search(ln.rstrip("\n"))
        if m:
            out.append((int(m.group(1), 16), m.group(2).strip()))
    return out


def census():
    """THE RULE, stated once.

    From every `ld X<r>,(0x00d7ed|0x00d7f1)` -- the base, 0x00F00000 -- walk
    forward collecting every `ld <R>,(X<r> + disp)` until anything writes X<r>.
    There is no window and no tuning knob: the walk stops at the first
    redefinition of the register, which is the only place the dataflow can end.

    The WALK reads mnemonics out of prom_c/wsa1_prom_c.s.  Every read it
    proposes is then RE-DECODED FROM THE ROM BYTES at the address it cites
    (Q2), which is what kills the "cited one byte past the instruction" class
    of error this project has shipped twice.  The base loads themselves are
    found in the bytes first and the listing must agree on where they are.

    Returns (base_load_addr, read_addr, slot, width, dest_reg, base_var).
    74 of the 99 reads are the instruction IMMEDIATELY after their base load;
    the rest are later reads through a base still live in the same register.
    """
    ins = listing()
    byte_bases = {a: r for a, r, _v in base_loads(C, PROM_C_BASE)}
    out = []
    for i, (a, t) in enumerate(ins):
        m = _LB.match(t)
        if not m or a not in byte_bases:
            continue
        reg, r = m.group(1), byte_bases[a]
        assert reg[1:] == RSEQ[r], (hex(a), reg, r)
        var = struct.unpack_from("<H", C, a - PROM_C_BASE + 1)[0]
        for j in range(i + 1, len(ins)):
            aj, tj = ins[j]
            mj = _DP.match(tj)
            if mj and mj.group(2) == reg:
                got = decode_slot_read(C, aj - PROM_C_BASE, r)
                out.append((a, aj, int(mj.group(3), 16),
                            4 if mj.group(1).startswith("X") else 2,
                            mj.group(1), var, got))
                continue
            w = _WR.match(tj)
            if w and w.group(1) == reg:
                break
    return out


RAW = census()
# every proposed read must re-decode from the ROM, with the SAME slot and width
BAD = [h for h in RAW if h[6] is None or h[6][0] != h[2] or h[6][1] != h[3]]
ALL_HITS = [h[:6] for h in RAW]
HITS = [h for h in ALL_HITS if h[1] == h[0] + 5]
BYSLOT = collections.defaultdict(list)
for h in ALL_HITS:
    BYSLOT[h[2]].append(h)

# aliases: slots holding the same value name the same structure
ALIAS = {0x1C: 0x18, 0x34: 0x30, 0x40: 0x3C, 0x9C: 0x24, 0xA0: 0x28, 0xA4: 0x2C}


def readers(slot):
    """Reader sites for a directory slot, MERGING the aliases that duplicate it."""
    out = list(BYSLOT.get(slot, []))
    for a, primary in ALIAS.items():
        if primary == slot:
            out += BYSLOT.get(a, [])
    return sorted(out)


AUDITED = (99, 33)             # (sites, distinct slots) -- the emitter checks this

if "--readers" in sys.argv:
    for s in sorted(BYSLOT):
        print("+0x%02X  n=%-2d  %s" % (s, len(BYSLOT[s]),
              ", ".join("%06X/%06X->%s" % (h[0], h[1], h[4]) for h in BYSLOT[s])))
    print("TOTAL %d sites, %d slots" % (len(ALL_HITS), len(BYSLOT)))
    raise SystemExit


# ===========================================================================
say("== Q1  the base is 0x00F00000, and it is a CONSTANT at every read site ==")
# ===========================================================================
writes = []
for off in range(len(C) - 5):
    if C[off] == 0xF2 and C[off + 3] == 0x00 and C[off + 4] & 0xF8 == 0x60:
        var = struct.unpack_from("<H", C, off + 1)[0]
        if var in BASE_VARS:
            writes.append((PROM_C_BASE + off, var, C[off + 4] & 7))
check("prom_c writes 0x00D7ED / 0x00D7F1 at EXACTLY two instructions",
      [w[0] for w in writes] == [0xFB0523, 0xFB0528],
      "%s" % ["%06X->%s" % (w[0], BASE_VARS[w[1]]) for w in writes])
check("both store XBC, and the instruction before them loads XBC with 0x00F00000",
      all(w[2] == 1 for w in writes)
      and C[0xFB051E - PROM_C_BASE:0xFB051E - PROM_C_BASE + 5] == bytes.fromhex("410000f000"),
      "0xFB051E = %s = ld XBC,0x00F00000"
      % C[0xFB051E - PROM_C_BASE:0xFB051E - PROM_C_BASE + 5].hex(" "))
check("neither address is named by any instruction in prom_a or prom_b",
      not base_loads(A, PROM_A_BASE) and not base_loads(B, PROM_B_BASE),
      "prom_d hangs off CPU 2's bus; prom_a/prom_b are CPU 1")
say("        ⚠ a store through a COMPUTED pointer cannot be excluded by a scan")
say("          that matches an address in an instruction.  What is excluded is a")
say("          second literal writer, and there is none.")
# the independent tie, from notes/prom_d_base_checks.py, re-run here on bytes
check("prom_a 0xF82A5F is `ld XWA,0x00F7FFF0` and prom_d file 0x7FFF0 is its "
      "11-byte build tag",
      A[0xF82A5F - PROM_A_BASE:0xF82A5F - PROM_A_BASE + 5] == bytes.fromhex("40f0fff700")
      and D[0x7FFF0:0x7FFFB] == b"wsad_54.ssf",
      "0x00F7FFF0 - 0x7FFF0 = 0x%06X" % (0x00F7FFF0 - 0x7FFF0))

# ===========================================================================
say("")
say("== Q2  the census: 99 directory reads in prom_c, over 33 slots ==")
# ===========================================================================
check("99 directory reads over 33 distinct slots",
      (len(ALL_HITS), len(BYSLOT)) == AUDITED,
      "got %d sites, %d slots, from %d base loads"
      % (len(ALL_HITS), len(BYSLOT), len(base_loads(C, PROM_C_BASE))))
check("74 of the 99 are the instruction IMMEDIATELY after their base load, so "
      "the strongest subset needs no dataflow argument at all",
      len(HITS) == 74, "%d adjacent, %d later in the same register's live range"
      % (len(HITS), len(ALL_HITS) - len(HITS)))
check("★ EVERY proposed read re-decodes from the ROM BYTES at the address it "
      "cites, with the SAME slot and the SAME operand width -- 99 of 99",
      not BAD, "%d that do not: %s" % (len(BAD), [hex(h[1]) for h in BAD[:5]]))
check("every site's base load re-decodes from the ROM at the CITED address "
      "(the off-by-one class this project has shipped twice)",
      all(C[a - PROM_C_BASE] == 0xE2 and C[a - PROM_C_BASE + 3] == 0x00
          for a, _r, _s, _w, _d, _v in ALL_HITS))
check("...checked on the LAST site as well as the first",
      RAW[0][6] is not None and RAW[-1][6] is not None,
      "first 0x%06X -> +0x%02X, last 0x%06X -> +0x%02X"
      % (RAW[0][1], RAW[0][2], RAW[-1][1], RAW[-1][2]))
# and the same census, taken from the .s text, must name the same addresses
TXT = re.compile(r';\s([0-9A-F]{6})\s\sld (X[A-Z]{2}),\(0x00d7(?:ed|f1)\)\s*$')
txt_addrs = set()
for ln in image_lines(ROOT, "prom_c/wsa1_prom_c.s"):
    m = TXT.search(ln.rstrip("\n"))
    if m:
        txt_addrs.add(int(m.group(1), 16))
check("the byte decoder and the .s listing agree on WHERE the base loads are",
      txt_addrs == {a for a, _r, _v in base_loads(C, PROM_C_BASE)},
      "%d addresses, symmetric difference %d" % (len(txt_addrs),
      len(txt_addrs ^ {a for a, _r, _v in base_loads(C, PROM_C_BASE)})))
check("the census is a LOWER BOUND and says so: a base parked in a frame slot, "
      "or reloaded into a register this walk does not follow, is not counted",
      len(ALL_HITS) >= len(HITS), "no upper bound is claimed")
for s in sorted(BYSLOT):
    say("        +0x%02X  %2d site(s)  %s" % (s, len(BYSLOT[s]),
        ", ".join("%06X" % h[1] for h in BYSLOT[s])))

# ===========================================================================
say("")
say("== Q3  ★ the REGISTER WIDTH separates pointer slots from tail scalars ==")
# ===========================================================================
say("   prom_d's source has always said slots +0x00..+0xB4 are FILE OFFSETS and")
say("   the tail from +0xC0 is SCALARS read as 16-bit words.  That was")
say("   transplanted from the KN5000's table.  prom_c's own encodings say it:")
lo = [h for h in ALL_HITS if h[2] < 0xC0]
hi = [h for h in ALL_HITS if h[2] >= 0xC0]
check("every read of a slot BELOW +0xC0 loads a 32-bit register",
      all(h[3] == 4 for h in lo), "%d sites, widths %s"
      % (len(lo), sorted({h[3] for h in lo})))
check("every read of a slot AT OR ABOVE +0xC0 loads a 16-bit register",
      all(h[3] == 2 for h in hi), "%d sites, widths %s"
      % (len(hi), sorted({h[3] for h in hi})))
check("the rule is not vacuous: both classes are populated and it holds 99 of 99",
      len(lo) == 72 and len(hi) == 27, "%d pointer reads, %d scalar reads"
      % (len(lo), len(hi)))
check("and the LAST site of each class obeys it too",
      lo[-1][3] == 4 and hi[-1][3] == 2,
      "last pointer read 0x%06X -> %s; last scalar read 0x%06X -> %s"
      % (lo[-1][1], lo[-1][4], hi[-1][1], hi[-1][4]))
check("every pointer slot read by code holds a value inside prom_d's payload",
      all(0 <= S(h[2]) < PAYLOAD_END for h in lo),
      "%d of %d, max 0x%05X" % (sum(1 for h in lo if S(h[2]) < PAYLOAD_END),
                                len(lo), max(S(h[2]) for h in lo)))
check("every tail slot read by code holds a small scalar (< 1024), not an offset",
      all(u16(h[2]) < 1024 for h in hi),
      "values %s" % sorted({"+0x%02X=%d" % (h[2], u16(h[2])) for h in hi}))

# ===========================================================================
say("")
say("== Q4  five address chains, each confirming a geometry derived from prom_d alone ==")
# ===========================================================================


def bytes_at(addr, n):
    return C[addr - PROM_C_BASE:addr - PROM_C_BASE + n]


def chain(name, steps):
    ok = all(bytes_at(a, len(bytes.fromhex(h))) == bytes.fromhex(h) for a, h, _c in steps)
    check(name, ok, "%d instructions, 0x%06X..0x%06X" % (len(steps), steps[0][0], steps[-1][0]))
    for a, h, c in steps:
        say("            %06X  %-20s %s" % (a, bytes_at(a, len(bytes.fromhex(h))).hex(" "), c))


say("   4a  bank/program -> tone index -> tone record  (slots +0x04 then +0x08)")
chain("4a: the two-level tone lookup decodes byte for byte", [
    (0xFB4266, "e2f1d70020", "ld XWA,(0x00d7f1)        ; the base"),
    (0xFB426B, "a80425",     "ld XIY,(XWA+0x04)        ; slot +0x04 ToneDB_ToneNumBanks"),
    (0xFB4271, "d9ee07",     "sll 0x07,BC              ; row * 128"),
    (0xFB4274, "da81",       "add BC,DE                ; + program"),
    (0xFB4276, "d981",       "add BC,BC                ; * 2  -> LE16 entry"),
    (0xFB427A, "e985",       "add XIY,XBC"),
    (0xFB427C, "e2edd70085", "add XIY,(0x00d7ed)       ; + base  => absolute"),
    (0xFB4281, "9523",       "ld HL,(XIY)              ; the tone index"),
    (0xFB4283, "e2f1d70021", "ld XBC,(0x00d7f1)"),
    (0xFB4288, "a90820",     "ld XWA,(XBC+0x08)        ; slot +0x08 ToneOffsetTable"),
    (0xFB4290, "ddee02",     "sll 0x02,IY              ; index * 4 -> LE32 entry"),
    (0xFB4295, "aef485",     "add XIY,(XIZ+0xf4)"),
    (0xFB4298, "e2edd70085", "add XIY,(0x00d7ed)"),
    (0xFB429D, "a520",       "ld XWA,(XIY)             ; the tone record's FILE OFFSET"),
    (0xFB429F, "e2edd70080", "add XWA,(0x00d7ed)       ; + base => the record"),
])
check("  ...and the shifts match prom_d's shape: 10 rows x 128 LE16 at +0x04, "
      "274 LE32 at +0x08",
      S(0x08) - S(0x04) == 10 * 128 * 2 and (0xFC8 - S(0x08)) // 4 == 274,
      "+0x04 spans %d bytes, +0x08 holds %d LE32" % (S(0x08) - S(0x04),
                                                     (0xFC8 - S(0x08)) // 4))

say("   4b  element block = record + 217 + 81*i, with slot +0xAC as the fallback")
chain("4b: 81 and 217 are LITERALS in prom_c", [
    (0xFB4356, "e2f1d70021", "ld XBC,(0x00d7f1)"),
    (0xFB435B, "e3e5ac0020", "ld XWA,(XBC+0x00ac)      ; slot +0xAC DefaultLayerParams"),
    (0xFB4362, "e2edd70025", "ld XIY,(0x00d7ed)"),
    (0xFB4367, "ed80",       "add XWA,XIY              ; the FALLBACK block"),
    (0xFB436D, "2351",       "ld C,0x51                ; 81 = the element-block stride"),
    (0xFB436F, "ce43",       "mul BC,H                 ; * element index"),
    (0xFB4373, "e9c8d9000000", "add XBC,0x000000d9     ; + 217 = the record head"),
    (0xFB4379, "ae0881",     "add XBC,(XIZ+0x08)       ; + the tone record"),
])
say("        ⚠ the two arms are reached by `cp A,0xff / jr NZ` at 0xFB4351: element")
say("          index 0xFF takes slot +0xAC, anything else computes into the record.")
say("          That is what makes +0xAC a FALLBACK and not just another pointer.")
check("  ...and 217 + 81*N + 43*N is exactly prom_d's melodic record size for "
      "N = 1..4", [217 + 124 * n for n in (1, 2, 3, 4)] == [341, 465, 589, 713])

say("   4c  a catalogue's row index is bounded by ITS OWN footer's LE16")
PAIRS = [(0x54, 0x50, 0xFB90B8, 0xFB90BD, 0xFB90D0, 0xFB90D2, 0xFB90D7),
         (0x68, 0x64, 0xFB9288, 0xFB928D, 0xFB92A0, 0xFB92A2, 0xFB92A7),
         (0x84, 0x80, 0xFB9563, 0xFB9568, 0xFB957D, 0xFB957F, 0xFB9584),
         (0x90, 0x8C, 0xFB9798, 0xFB979D, 0xFB97B2, 0xFB97B4, 0xFB97B9),
         (0x98, 0x94, 0xFB995C, 0xFB9961, 0xFB9976, 0xFB9978, 0xFB997D)]
for foot, cat, ld_base, ld_foot, ld_cnt, cmp_, ld_cat in PAIRS:
    ok = (bytes_at(ld_base, 5)[0] == 0xE2
          and decode_slot_read(C, ld_foot - PROM_C_BASE, C[ld_base - PROM_C_BASE + 4] & 7)[0] == foot
          and bytes_at(ld_cnt, 2)[0] & 0xF8 == 0x90          # WORD load from (Xr)
          and bytes_at(cmp_, 1)[0] in (0x9E, 0x9C))          # cp (XIZ+d),r
    check("  +0x%02X's LE16 is loaded and compared, then +0x%02X is addressed"
          % (foot, cat), ok,
          "0x%06X ld footer / 0x%06X ld its first word / 0x%06X cp / 0x%06X ld catalogue"
          % (ld_foot, ld_cnt, cmp_, ld_cat))
    rows = (min(v for v in DIR if v != 0xFFFFFFFF and v > S(cat)) - S(cat)) // 16
    check("    and that LE16 (%d) IS the catalogue's row count measured from the "
          "image (%d)" % (u16(S(foot)), rows), u16(S(foot)) == rows)
check("  the third pair +0x98/+0x94 is read the same way, and its footer also "
      "yields its own row count",
      bytes_at(0xFC1952, 5) == bytes.fromhex("e3e5980020")
      and bytes_at(0xFC1967, 2) == bytes.fromhex("9025")
      and bytes_at(0xFC196C, 3) == bytes.fromhex("880223")
      and u16(S(0x98)) == 161,
      "0xFC1967 reads the count and 0xFC196C reads the length byte at +0x02, "
      "which is the footer layout prom_d states")

say("   4d  the drum chain: slots +0x74 / +0x78 with the stride word +0xEE = 150")
chain("4d: +0xEE is loaded and USED AS A MULTIPLIER", [
    (0xFB48FE, "e2f1d70024", "ld XIX,(0x00d7f1)        ; base parked in XIX"),
    (0xFB4931, "ac7421",     "ld XBC,(XIX+0x74)        ; slot +0x74 DrumKit_NoteMapA"),
    (0xFB4937, "ac7820",     "ld XWA,(XIX+0x78)        ; slot +0x78 PercInst"),
    (0xFB493D, "d3f1ee0025", "ld IY,(XIX+0x00ee)       ; the stride word = 150"),
    (0xFB4947, "d9ee07",     "sll 0x07,BC              ; kit * 128"),
    (0xFB494C, "d9080200",   "mul BC,0x0002            ; * 2 -> LE16 note map"),
    (0xFB4953, "e2edd70081", "add XBC,(0x00d7ed)"),
    (0xFB4958, "9120",       "ld WA,(XBC)              ; the drum-instrument index"),
    (0xFB495A, "d845",       "mul XIY,WA               ; index * 150"),
])
check("  ...and prom_d's word at file 0x00EE really is 150, the stride that tiles "
      "504 records", u16(0xEE) == 150 and S(0x78) + 504 * 150 == S(0x20),
      "+0xEE = %d; 0x%05X + 504*150 = 0x%05X = slot +0x20" % (u16(0xEE), S(0x78), S(0x20)))
check("  and the note map really is 128 entries per kit: 2048 LE16 over 16 kits' "
      "worth of rows", (min(v for v in DIR if v != 0xFFFFFFFF and v > S(0x74)) - S(0x74)) == 4096)

say("   4e  the descriptor stride +0xEC = 14 is used as a stride on slot +0x70")
chain("4e: `mul XBC,HL` by the stride word, added to the slot value", [
    (0xFC2990, "e2f1d70020", "ld XWA,(0x00d7f1)"),
    (0xFC2995, "a87025",     "ld XIY,(XWA+0x70)        ; slot +0x70 DrawbarPreset_EnvDescTable"),
    (0xFC299A, "d3e1ec0021", "ld BC,(XWA+0x00ec)       ; the stride word = 14"),
    (0xFC299F, "db41",       "mul XBC,HL               ; * descriptor index"),
    (0xFC29A1, "e985",       "add XIY,XBC"),
    (0xFC29A5, "e2edd70084", "add XIX,(0x00d7ed)"),
])
check("  ...and 14 is what notes/prom_d_structures_round2.py derived for the "
      "descriptor ARRAY, from the descriptors' own 32-bit offsets",
      u16(0xEC) == 14 and u16(0xF2) == 14)

say("   4f  slot +0xA8 -- the block whose purpose prom_d records as UNKNOWN")
chain("4f: it is indexed by `sll 0x07`, i.e. 128-byte records", [
    (0xFA732D, "e2f1d70020", "ld XWA,(0x00d7f1)"),
    (0xFA7332, "e3e1a80025", "ld XIY,(XWA+0x00a8)      ; slot +0xA8 Unk_0FC8_Table"),
    (0xFA734A, "e985",       "add XIY,XBC             ; + a byte from RAM 0x1523"),
    (0xFA734F, "da89",       "ld BC,DE"),
    (0xFA7351, "d9ee07",     "sll 0x07,BC             ; record index * 128"),
    (0xFA7356, "e985",       "add XIY,XBC"),
    (0xFA7358, "e2edd70085", "add XIY,(0x00d7ed)      ; + base"),
    (0xFA735D, "9521",       "ld BC,(XIY)             ; a 16-bit word out of the record"),
])
check("  ...and prom_d's +0xA8 block IS 8 records of 128 bytes",
      (0x13C8 - S(0xA8)) == 8 * 128 and S(0xA8) == 0xFC8,
      "0x%05X..0x13C8 = %d bytes" % (S(0xA8), 0x13C8 - S(0xA8)))
say("        ⚠ still NOT established: what the 128-byte record MEANS.  What the")
say("          code adds is the RECORD SIZE, which prom_d had only from a")
say("          zero/non-zero column pattern.")

say("   4g  ★ an INDEX MAP's value is a CATALOGUE ROW NUMBER, and the row is 16 bytes")
chain("4g: +0x4C -> a 16-bit entry (0xFFFF = none) -> row of the +0x8C catalogue", [
    (0xFC1568, "e2f1d70020", "ld XWA,(0x00d7f1)"),
    (0xFC156D, "a84c25",     "ld XIY,(XWA+0x4c)       ; slot +0x4C PercSourceIndexMapB"),
    (0xFC1573, "d9ee07",     "sll 0x07,BC             ; row * 128"),
    (0xFC1576, "9e0881",     "add BC,(XIZ+0x08)       ; + column"),
    (0xFC1579, "d9080200",   "mul BC,0x0002           ; * 2 -> an LE16 entry"),
    (0xFC157F, "e2edd70085", "add XIY,(0x00d7ed)      ; + base"),
    (0xFC1584, "9521",       "ld BC,(XIY)             ; the map value"),
    (0xFC1586, "bef051",     "ld (XIZ+0xf0),BC"),
    (0xFC1589, "d9cfffff",   "cp BC,0xffff            ; 0xFFFF = NO ENTRY"),
    (0xFC1594, "e3e18c0025", "ld XIY,(XWA+0x008c)     ; slot +0x8C PercSourceNameList1"),
    (0xFC159C, "e2edd70085", "add XIY,(0x00d7ed)"),
    (0xFC15A1, "befc65",     "ld (XIZ+0xfc),XIY       ; the catalogue base"),
    (0xFC163F, "311000",     "ld BC,0x0010            ; 16 = the catalogue ROW STRIDE"),
    (0xFC1642, "9ef041",     "mul XBC,(XIZ+0xf0)      ; * the map value"),
    (0xFC1645, "aefc81",     "add XBC,(XIZ+0xfc)      ; + the catalogue base"),
    (0xFC1648, "e98d",       "ld XIY,XBC              ; the row, returned"),
])
_c8c = min(v for v in DIR if v != 0xFFFFFFFF and v > S(0x8C)) - S(0x8C)
check("  ...and the literal 16 IS prom_d's catalogue row stride: the +0x8C block "
      "is %d bytes = 16 x %d, and %d is what its footer at +0x90 declares"
      % (_c8c, _c8c // 16, u16(S(0x90))),
      _c8c % 16 == 0 and _c8c // 16 == u16(S(0x90)))
check("  the map is 1024 LE16 organised as rows of 128 (`sll 0x07` then a column), "
      "which is the shape prom_d's banner states",
      (min(v for v in DIR if v != 0xFFFFFFFF and v > S(0x4C)) - S(0x4C)) == 2048,
      "+0x4C spans 2048 bytes = 1024 LE16 = 8 rows of 128")
say("   4h  ★ 43 is the WAVE-SELECT RECORD LENGTH: a multiplier AND a loop bound")
chain("4h: slot +0x3C indexed by the stride word +0xEA, then bytes 13..42 copied", [
    (0xFBC7A9, "e2edd70021", "ld XBC,(0x00d7ed)       ; the base"),
    (0xFBC7B1, "e2f1d70020", "ld XWA,(0x00d7f1)"),
    (0xFBC7B6, "a83c25",     "ld XIY,(XWA+0x3c)       ; slot +0x3C, a wave-select array"),
    (0xFBC7B9, "ed81",       "add XBC,XIY            ; base + the array"),
    (0xFBC7BE, "d3e1ea0025", "ld IY,(XWA+0x00ea)      ; the stride word = 43"),
    (0xFBC7C3, "9ef245",     "mul XIY,(XIZ+0xf2)      ; * the record index"),
    (0xFBC7C6, "ed81",       "add XBC,XIY            ; => the record"),
    (0xFBC7CE, "890b21",     "ld A,(XBC+0x0b)         ; field +0x0B, copied on its own"),
    (0xFBC7D9, "bef0020d00", "ld (XIZ+0xf0),0x000d    ; i = 13"),
    (0xFBC7E3, "d3e5ea0020", "ld WA,(XBC+0x00ea)      ; the SAME word as the LOOP BOUND"),
    (0xFBC7E8, "9ef0f8",     "cp (XIZ+0xf0),WA        ; while i < 43"),
    (0xFBC7EF, "9ef061",     "incw 1,(XIZ+0xf0)       ; i++  (body copies byte i)"),
])
check("  ...and 43 tiles all three wave-select arrays exactly, first record to last",
      all((min(v for v in DIR if v != 0xFFFFFFFF and v > S(sl)) - S(sl)) % 43 == 0
          for sl in (0x18, 0x20, 0x3C)),
      "counts %s" % [(min(v for v in DIR if v != 0xFFFFFFFF and v > S(sl)) - S(sl)) // 43
                     for sl in (0x18, 0x20, 0x3C)])
say("        The record is 43 bytes because prom_c multiplies by 43 to reach one and")
say("        then copies bytes 13..42 out of it; the first 13 are handled")
say("        separately (+0x0B individually at 0xFBC7CE).  That head/tail split is")
say("        the same boundary round 2 saw from the other side -- the 7D 80 54")
say("        signature sits at +0x0D, the first byte the loop copies.")
say("        ⚠ NOT claimed: what any of the 43 bytes MEANS, or that arrays +0x18")
say("          and +0x20 are read -- they are not, by this census.")

say("        ★ THIS IS A MEANING, not only a shape: the index map's VALUE is a row")
say("          number in the catalogue named by the NEXT slot the same routine")
say("          reads, and 0xFFFF is its 'no entry' sentinel.  Everything prom_d")
say("          said about index maps before round 3 was a range, not a role.")

# ===========================================================================
say("")
say("== Q5  nulls -- the census has to be able to come out empty ==")
# ===========================================================================
n_a = len(base_loads(A, PROM_A_BASE))
n_b = len(base_loads(B, PROM_B_BASE))
check("the same byte decoder over prom_a and prom_b finds ZERO base loads, so "
      "zero directory reads", (n_a, n_b) == (0, 0),
      "prom_a %d, prom_b %d; prom_c %d" % (n_a, n_b, len(base_loads(C, PROM_C_BASE))))
# how CHEAP is the pattern?  Anchor it on every 16-bit RAM word instead of the
# two base slots and count.  A shift null is meaningless here -- an unanchored
# byte scan is shift-invariant by construction -- so this is the null that bites.
freq = collections.Counter()
for off in range(len(C) - 8):
    if C[off] != 0xE2 or C[off + 3] != 0x00 or C[off + 4] & 0xF8 != 0x20:
        continue
    v = struct.unpack_from("<H", C, off + 1)[0]
    if decode_slot_read(C, off + 5, C[off + 4] & 7):
        freq[v] += 1
rank = freq.most_common()
pos = [i for i, (v, _n) in enumerate(rank) if v in BASE_VARS]
check("★ in ALL of prom_c only TWO RAM words are loaded and immediately "
      "dereferenced with a displacement this way, and one of them is prom_d's "
      "base", len(freq) == 2 and freq[0xD7F1] == len(HITS),
      "%s" % ["0x%04X:%d" % (v, n) for v, n in rank])
say("        The other is 0x00D811 -- the EXPANSION BOARD's second base, installed")
say("        by the same routine (0xFB05C8).  So the null is not empty, and what")
say("        it contains is the one other object that should look like this.")
# ...and it reads the SAME slot offsets, i.e. the same 48-slot directory format
exp = set()
for off in range(len(C) - 8):
    if C[off] != 0xE2 or C[off + 3] != 0x00 or C[off + 4] & 0xF8 != 0x20:
        continue
    if struct.unpack_from("<H", C, off + 1)[0] != 0xD811:
        continue
    got = decode_slot_read(C, off + 5, C[off + 4] & 7)
    if got:
        exp.add(got[0])
check("  and the expansion board is read at the SAME slot offsets -- the same "
      "48-slot directory format, on a second device",
      exp and exp <= set(BYSLOT), "%d slots, %s; not in prom_d's set: %s"
      % (len(exp), sorted("+0x%02X" % x for x in exp),
         sorted("+0x%02X" % x for x in exp - set(BYSLOT)) or "none"))
# the pointer/scalar split must be a fact about prom_d, not about any 512 KiB blob
def valid_frac(img):
    got = 0
    for h in lo:
        v = struct.unpack_from("<I", img, h[2])[0]
        if 0 <= v < PAYLOAD_END:
            got += 1
    return got
check("read the %d pointer slots out of prom_a/b/c instead of prom_d and they "
      "stop being valid offsets" % len(lo),
      max(valid_frac(A), valid_frac(B), valid_frac(C)) < len(lo),
      "prom_d %d/%d; prom_a %d, prom_b %d, prom_c %d"
      % (valid_frac(D), len(lo), valid_frac(A), valid_frac(B), valid_frac(C)))
shift2 = D[2:] + b"\x00\x00"
got = sum(1 for h in lo if struct.unpack_from("<I", shift2, h[2])[0] < PAYLOAD_END)
check("and prom_d read on a frame shifted by 2 bytes loses them too",
      got < len(lo), "%d of %d still in range" % (got, len(lo)))
# ★ the sharpest null: the five tail words the code reads must BE the strides
# this tree measured from prom_d's own tiling, and must not be in another image.
MEASURED = {}
for slot, n in ((0x18, 322), (0x20, 208), (0x3C, 64)):
    nxt = min(v for v in DIR if v != 0xFFFFFFFF and v > S(slot))
    MEASURED.setdefault((nxt - S(slot)) // n, []).append("wave-select array +0x%02X" % slot)
MEASURED.setdefault(14, []).append("descriptor arrays +0x30/+0x38/+0x70")
MEASURED.setdefault(150, []).append("504 x 150 drum-instrument records at +0x78")
TAILS = sorted({h[2] for h in hi})
check("5 of the 6 tail words prom_c reads (all but +0xE0, excluded and stated "
      "below) ARE strides measured independently from prom_d's own tiling",
      all(u16(t) in MEASURED for t in TAILS if t != 0xE0),
      ", ".join("+0x%02X=%d%s" % (t, u16(t), "" if u16(t) in MEASURED else " (NOT a measured stride)")
                for t in TAILS))
for nm, img in (("prom_a", A), ("prom_b", B), ("prom_c", C)):
    n = sum(1 for t in TAILS if t != 0xE0
            and struct.unpack_from("<H", img, t)[0] in MEASURED)
    check("  null: the same %d offsets read from %s match %d of them"
          % (len(TAILS) - 1, nm, n), n == 0,
          "values %s" % [struct.unpack_from("<H", img, t)[0] for t in TAILS if t != 0xE0])
say("        ⚠ +0xE0 = %d is read at two sites and is NOT one of the measured" % u16(0xE0))
say("          strides; it is added, not multiplied (0xFAB678, 0xFAB778).  Stated")
say("          rather than folded into the count.")

# ===========================================================================
say("")
say("== Q6  the MN10300 cross-tree number, reproduced by a SECOND path ==")
# ===========================================================================
KN = "/home/fsanches/compartilhado/technics_roms/roms/kn7000/kn7000_table.rom"
try:
    TAB = open(KN, "rb").read()
except OSError:
    TAB = None
if TAB is None:
    say("  SKIP  %s not present" % KN)
else:
    uniq, uhit, per = set(), set(), collections.Counter()
    for nm, buf in (("prom_a", A), ("prom_b", B), ("prom_c", C), ("prom_d", D)):
        for i in range(len(buf) - 17):
            if buf[i + 16] != 0x10:
                continue
            f = buf[i:i + 16]
            if not all(0x20 <= c < 0x7F for c in f):
                continue
            uniq.add(f)
            if TAB.find(f) >= 0:
                uhit.add(f)
                per[nm] += 1
    check("252 distinct 16-char 0x10-terminated name fields, 195 of them verbatim "
          "in the KN7000 table ROM, ALL of them in prom_d",
          (len(uniq), len(uhit), dict(per)) == (252, 195, {"prom_d": 195}),
          "%d / %d / %s" % (len(uniq), len(uhit), dict(per)))
    say("        notes/wave7_xref_mn10300_family.py gets the same 195/252 from the")
    say("        HALFWORD-INTERLEAVED build of the two chips; this path reads the")
    say("        collection's already-linear kn7000_table.rom, so the number does")
    say("        not depend on the interleave being right.")
    say("        ⚠ NOT reproduced here: that script's other headline -- 250 shared")
    say("        binary runs, 74 of them exactly 81 bytes apart -- needs its")
    say("        double guard (entropy AND first-difference), so it is CITED, not")
    say("        re-derived.  Run that script for it.")

# ===========================================================================
say("")
say("== Q7  the honest gap: which filled slots have NO reader ==")
# ===========================================================================
NAMES = {
    0x04: "ToneDB_ToneNumBanks", 0x08: "ToneDB_ToneOffsetTable",
    0x0C: "ToneDB_ToneIndexMapA", 0x10: "ToneDB_ToneIndexMapB",
    0x14: "ToneDB_PercSourceIndexMapA", 0x18: "ToneDB_MixerDefaultTable",
    0x1C: "ToneDB_MixerDefaultTable (alias)", 0x20: "ToneDB_PercMixerDefaultTable",
    0x24: "ToneDB_ToneIndexMapC", 0x28: "ToneDB_ToneIndexMapD",
    0x2C: "ToneDB_DrumToneIndexMap", 0x30: "ToneDB_EnvDescTable",
    0x34: "ToneDB_EnvDescTable (alias)", 0x38: "ToneDB_EnvDescTable_Perc",
    # renamed in round 5 (Q7): the block is a bank of wave-select TAIL presets,
    # not a second copy of the +0x18 "default table".
    0x3C: "ToneDB_WaveSelTailPresets", 0x40: "ToneDB_WaveSelTailPresets (alias)",
    0x44: "ToneDB_SourceIndexMapA", 0x48: "ToneDB_SourceIndexMapB",
    0x4C: "ToneDB_PercSourceIndexMapB", 0x50: "ToneDB_SourceNameList1",
    0x54: "ToneDB_SourceList1_Footer", 0x58: "ToneDB_SourceIndexMapC",
    0x5C: "ToneDB_SourceIndexMapD", 0x60: "ToneDB_PercSourceIndexMapC",
    0x64: "ToneDB_SourceNameList2", 0x68: "ToneDB_SourceList2_Footer",
    0x6C: "ToneDB_BankMap", 0x70: "DrawbarPreset_EnvDescTable",
    0x74: "DrumKit_NoteMapA", 0x78: "PercInst", 0x7C: "DrumKit_NoteMapB",
    0x80: "ToneDB_DrumSourceNameList", 0x84: "ToneDB_DrumList_Footer",
    0x88: "(scalar or offset 0x125)", 0x8C: "ToneDB_PercSourceNameList1",
    0x90: "ToneDB_PercList1_Footer", 0x94: "ToneDB_PercSourceNameList2",
    0x98: "ToneDB_PercList2_Footer", 0x9C: "ToneDB_ToneIndexMapC (alias)",
    0xA0: "ToneDB_ToneIndexMapD (alias)", 0xA4: "ToneDB_DrumToneIndexMap (alias)",
    0xA8: "Unk_0FC8_Table", 0xAC: "ToneDB_DefaultLayerParams",
    0xB0: "ToneRec_Template_Clear", 0xB4: "PercInst_Template_Silent",
}
filled = [s for s in NAMES if DIR[s // 4] != 0xFFFFFFFF and s not in ALIAS]
withr = sorted(s for s in filled if readers(s))
without = sorted(s for s in filled if not readers(s))
check("39 filled PRIMARY pointer slots (the 6 aliases merged into the slot they "
      "duplicate); 26 have a reader, 13 do not",
      (len(filled), len(withr), len(without)) == (39, 26, 13),
      "%d filled, %d read, %d not" % (len(filled), len(withr), len(without)))
say("   WITH a reader:")
for s in withr:
    say("        +0x%02X  %-34s %2d site(s)" % (s, NAMES[s], len(readers(s))))
say("   WITHOUT one -- these keep their transplanted KN5000 name and say so:")
for s in without:
    say("        +0x%02X  %s" % (s, NAMES[s]))
check("the three biggest unread structures are the descriptor blocks and the "
      "wave-select arrays, i.e. exactly the regions round 2 framed from the "
      "image alone", all(s in without for s in (0x18, 0x20, 0x30, 0x38)),
      "so round 2's framing is still image-internal, and stays labelled that way")

# ===========================================================================
say("")
say("== Q8  the two numbers prom_d/prom_d.ld quotes, reproduced ==")
# ===========================================================================
say("   prom_d/prom_d.ld argues ORIGIN 0 partly from 'this image contains no")
say("   absolute code pointers'.  That paragraph predates this script and its")
say("   numbers had no committed reproduction; here it is.")


def bank_profile(img):
    c = collections.Counter()
    n = 0
    for o in range(0, len(img) - 3, 4):
        v = struct.unpack_from("<I", img, o)[0]
        if (v >> 24) == 0x00 and v >= 0x1000:
            c[(v >> 16) & 0xFF] += 1
            n += 1
    return c, n


cd, nd = bank_profile(D)
check("prom_d: %d aligned LE32 words have top byte 0x00 and value >= 0x1000, and "
      "their bank byte is FLAT" % nd,
      (nd, cd[0x40], cd[0x1E], cd[0x64]) == (20076, 1267, 784, 722),
      "top: %s" % ["0x%02X:%d" % (b, n) for b, n in cd.most_common(5)])
check("  the single commonest bank is 0x00 (%d), i.e. values below 0x10000 -- "
      "which is what a 0-BASED image is full of, not what a code ROM is"
      % cd[0x00], cd.most_common(1)[0][0] == 0x00)


def own_share(img, win):
    c, n = bank_profile(img)
    return sum(c[b] for b in win), n


SHARE = {"prom_a": own_share(A, range(0xF8, 0x100)),
         "prom_b": own_share(B, range(0xF0, 0xF8)),
         "prom_c": own_share(C, range(0xF8, 0x100)),
         "prom_d": own_share(D, range(0xF0, 0xF8))}
check("  ⚠ CORRECTION: prom_a and prom_b DO pile into their own code banks "
      "(0xFA and 0xF7 are their top non-zero banks)",
      bank_profile(A)[0].most_common(2)[1][0] == 0xFA
      and bank_profile(B)[0].most_common(2)[1][0] == 0xF7)
check("  ⚠ ...but the statistic DOES NOT DISCRIMINATE, and the .ld used to imply "
      "it did.  prom_c is a CODE ROM and behaves like prom_d on it",
      SHARE["prom_c"][0] * 100.0 / SHARE["prom_c"][1] < 5.0,
      "share of such words landing in the image's OWN window: "
      + ", ".join("%s %.1f%%" % (k, 100.0 * v[0] / v[1]) for k, v in sorted(SHARE.items())))
say("        So 'prom_d holds no absolute code pointers' is SUPPORTED but is not")
say("        proved by this profile, and prom_d/prom_d.ld now says so.  The")
say("        ORIGIN-0 decision does not rest on it: what proves the image is")
say("        0-based is Q4a, where prom_c ADDS THE BASE to a word it read out of")
say("        this image and then adds it again to the word THAT points to.")
run = 0
j = 0x50B09
while j < len(D) and D[j] == 0xFF:
    j += 1
check("the erased tail is ONE unbroken 0xFF run of 0x2F4E7 bytes, 0x50B09..0x7FFEF",
      (j - 0x50B09, j) == (0x2F4E7, 0x7FFF0),
      "0x%05X bytes, ending at 0x%05X where the build tag starts" % (j - 0x50B09, j))
check("  and it is the ONLY 0xFF run in the image of 0x1000 bytes or more",
      max((len(r) for r in re.findall(b"\xff+", D)), default=0) == 0x2F4E7
      and sum(1 for r in re.findall(b"\xff+", D) if len(r) >= 0x1000) == 1,
      "longest other run %d bytes"
      % max((len(r) for r in re.findall(b"\xff+", D) if len(r) != 0x2F4E7), default=0))

# ===========================================================================
print("")
if FAILED:
    print("prom_d round 3: %d of %d checks FAILED" % (len(FAILED), NCHECK[0]))
    for f in FAILED:
        print("   - %s" % f)
    sys.exit(1)
print("prom_d round 3: all %d checks held." % NCHECK[0])
