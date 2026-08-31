#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF6D002-0xF77FFF -- the PERFORMANCE /
ACCOMPANIMENT screen layer and the sequencer block above it.

QUESTION IT ANSWERS
    "What is the assembly text for the 45,054-byte `.incbin` span that 76
     already-proven call sites point into, in a form the byte gate accepts, with
     every label and header attached to the right address?"  This is the emitter
     whose output is pasted into prom_b/wsa1_prom_b.s.

WHY THIS SPAN (round 6, and NOT the run the thunk frontier ranks first)
    notes/prom_b_module_frontier.py ranks THUNK RUNS.  This span owns TWO thunk
    slots -- T_F43380 and T_F43384, naming 0xF6F400 and 0xF6F404 -- so that tool
    ranks it THIRTEENTH of fourteen, on an extent of 4 bytes.  It is nevertheless
    the right target, because the module is entered by DIRECT CALL rather than
    through the routine directory, and notes/prom_b_span_frontier.py measures
    that:

        span                     bytes  proven  thunk
        0xF6D002-0xF77FFF        45054      76      2     <- this one
        0xF7E2D8-0xF7FFFF         7464      38      0
        0xF067A6-0xF0D79B        28662       4     24
        0xF157A8-0xF27BFF        74840       0     13

    `proven` is the number of DISTINCT addresses inside the span that an
    instruction ALREADY TRANSCRIBED in prom_a/prom_b calls or jumps to.  76 is
    more than every other unconverted span in prom_b put together.

WHERE THE BOUNDARIES COME FROM
    notes/prom_b_f6d002_layout.py, which is notes/prom_b_f0ea9f_layout.py with
    LO/HI changed AND NOTHING ELSE.  That is round 6's methodological result:
    round 5's rule set is the first in this lane that transferred to a new module
    unchanged -- 0 barrier conflicts, every null still zero.  Round 5 had to add
    five rules to round 4's; round 6 added none.

RUN
    python3 notes/gen_prom_b_f6d002_module.py            # the assembly
    python3 notes/gen_prom_b_f6d002_module.py --layout   # the segment table
    python3 notes/gen_prom_b_f6d002_module.py --checks   # REFUSES to emit on fail
    python3 notes/gen_prom_b_f6d002_module.py --tables   # every data object
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import gen_prom_b_f65000_module as G                               # noqa: E402
import prom_b_f6d002_layout as LY6                                 # noqa: E402
import prom_b_f0ea9f_layout as LY                                  # noqa: E402
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402

LO, HI = LY6.LO, LY6.HI
B_BASE = 0xF00000

LAYOUT = [
    ("data", 0xF6D002, 0x0021),
    ("code", 0xF6D023, 0x044A),
    ("data", 0xF6D46D, 0x000A),
    ("code", 0xF6D477, 0x0001),
    ("data", 0xF6D478, 0x000A),
    ("code", 0xF6D482, 0x0038),
    ("data", 0xF6D4BA, 0x000C),
    ("code", 0xF6D4C6, 0x0061),
    ("data", 0xF6D527, 0x0019),
    ("code", 0xF6D540, 0x0021),
    ("data", 0xF6D561, 0x0019),
    ("code", 0xF6D57A, 0x0022),
    ("ascii", 0xF6D59C, 0x0019),
    ("code", 0xF6D5B5, 0x00B8),
    ("ascii", 0xF6D66D, 0x0068),
    ("code", 0xF6D6D5, 0x00F2),
    ("bytemap", 0xF6D7C7, 0x0021),
    ("ascii", 0xF6D7E8, 0x007F),
    ("data", 0xF6D867, 0x0004),
    ("code", 0xF6D86B, 0x0083),
    ("data", 0xF6D8EE, 0x0005),
    ("code", 0xF6D8F3, 0x0022),
    ("ascii", 0xF6D915, 0x004E),
    ("code", 0xF6D963, 0x007F),
    ("data", 0xF6D9E2, 0x0019),
    ("code", 0xF6D9FB, 0x011E),
    ("data", 0xF6DB19, 0x0018),
    ("ascii", 0xF6DB31, 0x0032),
    ("data", 0xF6DB63, 0x0001),
    ("ascii", 0xF6DB64, 0x0018),
    ("data", 0xF6DB7C, 0x007D),
    ("code", 0xF6DBF9, 0x007E),
    ("data", 0xF6DC77, 0x0085),
    ("ascii", 0xF6DCFC, 0x001C),
    ("data", 0xF6DD18, 0x0087),
    ("ascii", 0xF6DD9F, 0x0018),
    ("code", 0xF6DDB7, 0x0059),
    ("ascii", 0xF6DE10, 0x00E7),
    ("code", 0xF6DEF7, 0x0059),
    ("data", 0xF6DF50, 0x0007),
    ("code", 0xF6DF57, 0x0063),
    ("data", 0xF6DFBA, 0x000A),
    ("code", 0xF6DFC4, 0x0063),
    ("data", 0xF6E027, 0x0007),
    ("code", 0xF6E02E, 0x0059),
    ("data", 0xF6E087, 0x000A),
    ("code", 0xF6E091, 0x005A),
    ("data", 0xF6E0EB, 0x0067),
    ("code", 0xF6E152, 0x0054),
    ("data", 0xF6E1A6, 0x000B),
    ("code", 0xF6E1B1, 0x005A),
    ("data", 0xF6E20B, 0x0007),
    ("code", 0xF6E212, 0x0047),
    ("data", 0xF6E259, 0x0008),
    ("code", 0xF6E261, 0x004B),
    ("data", 0xF6E2AC, 0x000E),
    ("code", 0xF6E2BA, 0x0045),
    ("data", 0xF6E2FF, 0x0007),
    ("code", 0xF6E306, 0x0039),
    ("data", 0xF6E33F, 0x000E),
    ("ascii", 0xF6E34D, 0x0090),
    ("data", 0xF6E3DD, 0x0010),
    ("ascii", 0xF6E3ED, 0x0051),
    ("data", 0xF6E43E, 0x0025),
    ("code", 0xF6E463, 0x004F),
    ("ascii", 0xF6E4B2, 0x0040),
    ("code", 0xF6E4F2, 0x0050),
    ("ascii", 0xF6E542, 0x0060),
    ("code", 0xF6E5A2, 0x005D),
    ("data", 0xF6E5FF, 0x0008),
    ("code", 0xF6E607, 0x0008),
    ("ascii", 0xF6E60F, 0x0017),
    ("code", 0xF6E626, 0x0044),
    ("data", 0xF6E66A, 0x000E),
    ("code", 0xF6E678, 0x005C),
    ("ascii", 0xF6E6D4, 0x0018),
    ("code", 0xF6E6EC, 0x0001),
    ("ascii", 0xF6E6ED, 0x0017),
    ("code", 0xF6E704, 0x0024),
    ("data", 0xF6E728, 0x0012),
    ("code", 0xF6E73A, 0x0051),
    ("data", 0xF6E78B, 0x000C),
    ("code", 0xF6E797, 0x0051),
    ("data", 0xF6E7E8, 0x000B),
    ("code", 0xF6E7F3, 0x0051),
    ("data", 0xF6E844, 0x0005),
    ("code", 0xF6E849, 0x0051),
    ("data", 0xF6E89A, 0x000C),
    ("code", 0xF6E8A6, 0x0051),
    ("data", 0xF6E8F7, 0x000C),
    ("code", 0xF6E903, 0x0051),
    ("data", 0xF6E954, 0x000B),
    ("code", 0xF6E95F, 0x0051),
    ("data", 0xF6E9B0, 0x000B),
    ("code", 0xF6E9BB, 0x009C),
    ("data", 0xF6EA57, 0x01DA),
    ("code", 0xF6EC31, 0x006E),
    ("fill", 0xF6EC9F, 0x0361),
    ("code", 0xF6F000, 0x019C),
    ("data", 0xF6F19C, 0x0264),
    ("code", 0xF6F400, 0x0128),
    ("data", 0xF6F528, 0x0008),
    ("code", 0xF6F530, 0x0455),
    ("bytemap", 0xF6F985, 0x0046),
    ("data", 0xF6F9CB, 0x0013),
    ("code", 0xF6F9DE, 0x00D6),
    ("data", 0xF6FAB4, 0x0003),
    ("code", 0xF6FAB7, 0x0731),
    ("data", 0xF701E8, 0x0008),
    ("code", 0xF701F0, 0x00A8),
    ("bytemap", 0xF70298, 0x0022),
    ("data", 0xF702BA, 0x0076),
    ("code", 0xF70330, 0x015D),
    ("ptrtab", 0xF7048D, 0x0040),
    ("code", 0xF704CD, 0x0451),
    ("bytemap", 0xF7091E, 0x0040),
    ("code", 0xF7095E, 0x0179),
    ("data", 0xF70AD7, 0x0012),
    ("code", 0xF70AE9, 0x0153),
    ("data", 0xF70C3C, 0x0003),
    ("code", 0xF70C3F, 0x0020),
    ("bytemap", 0xF70C5F, 0x0012),
    ("data", 0xF70C71, 0x0049),
    ("code", 0xF70CBA, 0x046C),
    ("data", 0xF71126, 0x0017),
    ("code", 0xF7113D, 0x019A),
    ("data", 0xF712D7, 0x0006),
    ("code", 0xF712DD, 0x0235),
    ("data", 0xF71512, 0x0013),
    ("code", 0xF71525, 0x0242),
    ("data", 0xF71767, 0x01D8),
    ("code", 0xF7193F, 0x02A7),
    ("data", 0xF71BE6, 0x0004),
    ("code", 0xF71BEA, 0x048A),
    ("data", 0xF72074, 0x0008),
    ("code", 0xF7207C, 0x0001),
    ("bytemap", 0xF7207D, 0x0012),
    ("code", 0xF7208F, 0x0294),
    ("ptrtab", 0xF72323, 0x0040),
    ("code", 0xF72363, 0x0132),
    ("data", 0xF72495, 0x0012),
    ("code", 0xF724A7, 0x00AE),
    ("bytemap", 0xF72555, 0x0021),
    ("data", 0xF72576, 0x0063),
    ("code", 0xF725D9, 0x0BD2),
    ("bytemap", 0xF731AB, 0x0020),
    ("ident", 0xF731CB, 0x000E),
    ("data", 0xF731D9, 0x0002),
    ("bytemap", 0xF731DB, 0x0022),
    ("code", 0xF731FD, 0x05FA),
    ("bytemap", 0xF737F7, 0x0020),
    ("code", 0xF73817, 0x002D),
    ("data", 0xF73844, 0x001B),
    ("code", 0xF7385F, 0x0FAB),
    ("ramtab", 0xF7480A, 0x0040),
    ("bytemap", 0xF7484A, 0x0021),
    ("code", 0xF7486B, 0x0001),
    ("data", 0xF7486C, 0x0019),
    ("code", 0xF74885, 0x00BA),
    ("data", 0xF7493F, 0x0063),
    ("code", 0xF749A2, 0x062D),
    ("data", 0xF74FCF, 0x057E),
    ("ramtab", 0xF7554D, 0x0128),
    ("data", 0xF75675, 0x0010),
    ("code", 0xF75685, 0x0A19),
    ("bytemap", 0xF7609E, 0x0021),
    ("data", 0xF760BF, 0x0063),
    ("code", 0xF76122, 0x04D8),
    ("data", 0xF765FA, 0x0002),
    ("code", 0xF765FC, 0x00A1),
    ("data", 0xF7669D, 0x011E),
    ("ramtab", 0xF767BB, 0x0040),
    ("bytemap", 0xF767FB, 0x0021),
    ("data", 0xF7681C, 0x0FF9),
    ("bytemap", 0xF77815, 0x0021),
    ("data", 0xF77836, 0x019F),
    ("code", 0xF779D5, 0x038A),
    ("data", 0xF77D5F, 0x0002),
    ("code", 0xF77D61, 0x0288),
    ("data", 0xF77FE9, 0x0017),
]

# ^ derived, not typed: `python3 notes/prom_b_f6d002_layout.py --all`


def install():
    """Point the shared emitter helpers at THIS module's range and layout.

    gen_prom_b_f65000_module's helpers (transcribe/code_lines/labels/touched/
    direct_refs/...) all read their module globals, so swapping the globals
    reuses them without a third copy of the code."""
    G.LO, G.HI, G.LAYOUT = LO, HI, LAYOUT
    G.STUB, G.DEFAULT_SLOT = None, 0x00F42C70
    G.PREFIX = PREFIX
    G._cache.clear()


DATA_KINDS = ("data", "ident", "ptrtab", "ramtab", "bittab", "ascii",
              "bytemap")
PREFIX = {"data": "Data", "ident": "IndexMap", "ptrtab": "PtrTable",
          "ramtab": "RamPtrTable", "bittab": "BitWeight", "ascii": "Text",
          "bytemap": "ByteMap"}
KIND_PREFIX = {"TRANSFER": "DispatchTable", "DEREF": "DataPtrTable",
               "STRIDED": "ArrayDescriptor", "UNKNOWN": "PtrTable"}
KIND_NAME = {"code": "code", "ptrtab": "pointer tables",
             "data": "unsplit `.byte` runs", "bytemap": "byte maps",
             "ramtab": "RAM-pointer tables", "ident": "index maps",
             "ascii": "strings", "bittab": "bit-weight tables",
             "fill": "`ret` padding (.fill)"}
ORDER = ("code", "ptrtab", "data", "bytemap", "ramtab", "ident", "ascii",
         "bittab", "fill")


def rom(which="b"):
    return L.rom(which)


def at(addr, n=1):
    return rom("b")[addr - B_BASE: addr - B_BASE + n]


def w32(a):
    return int.from_bytes(at(a, 4), "little")


def ascii_of(a, n):
    return "".join(chr(x) if 32 <= x < 127 else "." for x in at(a, n))


def kind_of_table(s, n):
    return LY.table_kind(rom("b"), s, s + n)


def bytemap_subruns(s, n):
    """The BYTEMAP rule's own maximal ascending runs inside one segment.

    build() paints every run the rule returns the same colour, so N ADJACENT
    maps arrive as ONE `bytemap` segment.  Six of this module's fifteen byte-map
    segments are like that (2, 2, 2, 2, 2 and 4 maps); the 0xF0EA9F module had
    none, which is why round 5's emitter assumes one run per segment."""
    return LY.monotone_maps(rom("b"), s, s + n)


def labels():
    """{address: label}.  Data objects are named for their CONTENT; routines are
    sub_XXXXXX.  Five entry sources: a thunk slot, an in-module call, a PROVEN
    call site, an entry of a table the consumer rule classed TRANSFER, and the
    start of every data segment."""
    got = {}
    for t in G.thunks():
        got[t] = None
    for callee in G.internal_calls():
        got[callee] = None
    for t in LY.proven_call_sites(LO, HI):
        got[t] = None
    for t in LY.table_entry_seeds(rom("b"), LO, HI):
        got[t] = None
    for kind, s, n in LAYOUT:
        if kind in DATA_KINDS:
            got[s] = None
    b = G.boundaries()
    data_starts = {s: (k, n) for k, s, n in LAYOUT if k in DATA_KINDS}
    fill = [(s, s + n) for k, s, n in LAYOUT if k == "fill"]
    for a in list(got):
        if any(s <= a < e for s, e in fill):
            del got[a]
            continue
        if a not in b and a not in data_starts:
            del got[a]
            continue
        if a in data_starts:
            k, n = data_starts[a]
            pre = KIND_PREFIX[kind_of_table(a, n)] if k == "ptrtab" else PREFIX[k]
            got[a] = "%s_%06X" % (pre, a)
        else:
            got[a] = "sub_%06X" % a
    return got


NULL_CITE = "`python3 notes/prom_b_f6d002_layout.py --null-ptr`"


def data_block(kind, s, n, lab):
    """The header + directives for one data object.

    ⚠ Every citation in here names THIS module's own instructions or THIS
    module's own null run.  Round 5's emitter hard-codes `ld H,(XWA)` at
    0xF10619 into its BYTEMAP header, which is a true statement about the
    0xF0EA9F block and would be a false citation here; that is the class of
    defect this tree has shipped before, so the text is rewritten rather than
    imported."""
    name = lab[s]
    out = ["; " + "-" * 74]
    if kind == "ptrtab":
        tk = kind_of_table(s, n)
        ps = [w32(s + 4 * i) for i in range(n // 4)]
        nd = sorted(set(ps))
        out += G.wrap("; %s -- " % name,
                      "%d 32-bit words, every one an address in "
                      "0x00F00000-0x00F7FFFF, i.e. inside this image.  %d "
                      "distinct value%s.  notes/prom_b_f6d002_layout.py classes "
                      "it %s."
                      % (n // 4, len(nd), "" if len(nd) == 1 else "s", tk))
        why = {"TRANSFER": "the code that indexes it fetches an entry and then "
                           "TRANSFERS to it, so the entries are ENTRY POINTS and "
                           "they seed this block's code walk",
               "DEREF": "the code that indexes it fetches an entry and then "
                        "READS THROUGH IT (an 8- or 16-bit load), so the entries "
                        "are DATA addresses; they do NOT seed the code walk",
               "STRIDED": "its entries are an arithmetic progression, which is "
                          "an ARRAY of fixed-size records rather than a set of "
                          "handlers; the entries do not seed the code walk",
               "UNKNOWN": "no instruction in prom_a or prom_b spells this "
                          "address as a 32-bit word in a decodable operand, so "
                          "nothing here says how it is indexed; the entries do "
                          "NOT seed the code walk"}[tk]
        out += G.wrap("; Why %s: " % tk, why)
        out += G.wrap("; Read by: ", G.reader_line(s))
        out += G.wrap("; Entry count: ",
                      "%d, and it is NOT a byte extent divided by four.  The "
                      "chain rule that finds it stops at the first word that is "
                      "not an 0x00F0xxxx-0x00F7xxxx address; that word is at "
                      "0x%06X.  Entry %d, the LAST, is 0x%08X."
                      % (n // 4, s + n, n // 4 - 1, ps[-1]))
        out += G.wrap("; Evidence: ",
                      "every one of the %d words is re-read and range-asserted "
                      "on every emit.  The PTRTAB rule at this window fires ZERO "
                      "times over the proven prom_b instruction text (%s), and "
                      "the STRIDED rule fires zero times over the proven "
                      "dispatch tables of this image "
                      "(`--null-stride`)." % (n // 4, NULL_CITE))
        out += G.wrap("; Unknown: ", "what indexes it, and what the entries mean."
                      if tk != "TRANSFER" else
                      "what the handlers do.  Each is sub_XXXXXX.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, p in enumerate(ps):
            tag = lab.get(p) or ("0x%06X" % p)
            out.append("\t.long\t0x00%06X\t; %06X  [%d] -> %s"
                       % (p, s + 4 * i, i, tag))
        return out
    if kind == "bytemap":
        vals = [x for x in at(s, n) if x != 0xFF]
        subs = bytemap_subruns(s, n)
        if len(subs) == 1:
            out += G.wrap("; %s -- " % name,
                          "%d bytes: a BYTE MAP.  %d of them are 0xFF and the "
                          "other %d ASCEND STRICTLY, 0x%02X to 0x%02X, with "
                          "jumps.  The name describes the CONTENT; what the two "
                          "index spaces are is not established here."
                          % (n, n - len(vals), len(vals), vals[0], vals[-1]))
        else:
            # ⚠ ROUND 6 IS THE FIRST BLOCK WHERE TWO BYTE MAPS ABUT.  The
            # BYTEMAP rule returns MAXIMAL ascending runs and build() paints them
            # all the same colour, so N adjacent maps arrive here as ONE segment
            # -- and "the N non-0xFF bytes ascend strictly, 0xAA to 0xBB" would
            # then be FALSE, because the count restarts at each map.  Round 5's
            # emitter would have written exactly that sentence; the check below
            # caught it before a line was emitted.
            out += G.wrap("; %s -- " % name,
                          "%d bytes: %d BYTE MAPS end to end, %s.  Each ascends "
                          "STRICTLY on its own and the sequence RESTARTS at each "
                          "boundary, so this is N maps of the same shape rather "
                          "than one long one.  The name describes the CONTENT; "
                          "what the index spaces are is not established here."
                          % (n, len(subs),
                             ", ".join("%d bytes at 0x%06X (0x%02X..0x%02X)"
                                       % (e - a, a,
                                          min(x for x in at(a, e - a) if x != 0xFF),
                                          max(x for x in at(a, e - a) if x != 0xFF))
                                       for a, e in subs)))
        asc = L.ascii_runs(rom("b"), s, s + n)
        if asc:
            out += G.wrap("; ⚠ ",
                          "%d bytes of this run form a maximal printable run of "
                          "20 or more (%s), so the ASCII rule framed that part as "
                          "a STRING.  It is not one: those are this map's own "
                          "ascending values, which happen to fall in 0x20-0x7E.  "
                          "BYTEMAP is painted OVER ascii for exactly this reason."
                          % (sum(e - a for a, e in asc),
                             " ".join("0x%06X-0x%06X" % (a, e - 1)
                                      for a, e in asc)))
        out += G.wrap("; Read by: ", G.reader_line(s))
        out += G.wrap("; Entry count: ",
                      "%d bytes.  The run is trimmed of trailing 0xFF, so it "
                      "claims no padding it did not earn; the byte before it is "
                      "0x%02X and the LAST byte of it is 0x%02X."
                      % (n, at(s - 1, 1)[0], at(s + n - 1, 1)[0]))
        out += G.wrap("; Evidence: ",
                      "every non-0xFF byte is compared with its predecessor on "
                      "every emit, WITHIN EACH of the %d maximal ascending runs "
                      "the rule returns, and the runs are asserted to tile this "
                      "segment exactly.  The BYTEMAP rule fires ZERO times over "
                      "the proven prom_b instruction text at (16 bytes, 12 "
                      "values) and also at (20,14), (24,16) and (16,16) (%s)."
                      % (len(subs), NULL_CITE))
        out += G.wrap("; Unknown: ", "what the two index spaces ARE, and who "
                      "reads it.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += G.byte_rows(s, n)
        return out
    if kind == "ramtab":
        vs = [w32(s + 4 * i) for i in range(n // 4)]
        dif = sorted(set(vs[i + 1] - vs[i] for i in range(len(vs) - 1)))
        out += G.wrap("; %s -- " % name,
                      "%d 32-bit words, every one below 0x10000, i.e. a 16-bit "
                      "RAM address stored one per long word.  First 0x%04X, LAST "
                      "0x%04X; the step between neighbours takes %d distinct "
                      "value%s (%s)."
                      % (n // 4, vs[0], vs[-1], len(dif),
                         "" if len(dif) == 1 else "s",
                         " ".join("0x%X" % x for x in dif)))
        out += G.wrap("; Read by: ", G.reader_line(s))
        out += G.wrap("; Entry count: ",
                      "%d.  The chain stops at the first word that is not below "
                      "0x10000, at 0x%06X." % (n // 4, s + n))
        out += G.wrap("; Evidence: ", "every word is re-read and range-asserted "
                      "on every emit.  The RAMTAB rule fires ZERO times over the "
                      "proven prom_b instruction text (%s)." % NULL_CITE)
        out += G.wrap("; Unknown: ", "what lives at those RAM addresses.  The "
                      "name describes the CONTENT of the table, not its purpose.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, v in enumerate(vs):
            out.append("\t.long\t0x%08X\t; %06X  [%d] -> RAM 0x%04X"
                       % (v, s + 4 * i, i, v))
        return out
    if kind == "ident":
        subs = G.ident_subruns(s, n)
        out += G.wrap("; %s -- " % name,
                      "%s.  The name describes the CONTENT and claims nothing "
                      "about the purpose."
                      % "; ".join("%d bytes at 0x%06X counting 0x%02X..0x%02X"
                                  % (ln, a, v0, v1) for a, ln, v0, v1 in subs))
        out += G.wrap("; Read by: ", G.reader_line(s))
        out += G.wrap("; Entry count: ",
                      "%d bytes.  The byte before 0x%06X is 0x%02X and the byte "
                      "at 0x%06X is 0x%02X, so neither end extends."
                      % (n, s, at(s - 1, 1)[0], s + n, at(s + n, 1)[0]))
        out += G.wrap("; Evidence: ", "every byte is compared with its "
                      "predecessor + 1 on every emit.  The IDENT rule fires ZERO "
                      "times over the proven prom_b instruction text (%s)."
                      % NULL_CITE)
        out += G.wrap("; Unknown: ", "why an index map that returns its own "
                      "index exists.  Recorded, not explained.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += G.byte_rows(s, n)
        return out
    if kind == "ascii":
        out += G.wrap("; %s -- " % name,
                      "%d printable bytes: '%s'." % (n, ascii_of(s, n)))
        out += G.wrap("; Read by: ", G.reader_line(s))
        out += G.wrap("; Entry count: ",
                      "%d bytes; the byte before is 0x%02X and the byte after is "
                      "0x%02X.  ⚠ NOT \"neither is printable\": the BYTEMAP "
                      "rule is painted OVER ascii, so a surviving string can abut "
                      "a printable byte that belongs to a byte map."
                      % (n, at(s - 1, 1)[0], at(s + n, 1)[0]))
        out += G.wrap("; Evidence: ", "the text is re-read and every byte "
                      "re-checked for 0x20-0x7E on every emit.  The ASCII rule "
                      "at its 20-byte threshold fires ZERO times over the proven "
                      "prom_b instruction text (%s)." % NULL_CITE)
        out += G.wrap("; Unknown: ", "which screen draws it, and how the "
                      "fixed-width columns inside it are indexed.  The string is "
                      "evidence about the MODULE, not about any routine.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out.append('\t.ascii\t"%s"\t; %06X  %d bytes'
                   % (ascii_of(s, n).replace("\\", "\\\\").replace('"', '\\"'),
                      s, n))
        return out
    clean = L.selfconsistent(rom("b"), s, s + n, set())[0]
    tail = clean and L.ends_in_flow_end(s, s + n)
    out += G.wrap("; %s -- " % name,
                  "%d byte%s this block could not split.  No content rule framed "
                  "it -- not PTRTAB, RAMTAB, BITTAB, IDENT, BYTEMAP or ASCII -- "
                  "and the code walk never reached it from a thunk slot, a proven "
                  "call site, an opcode-anchored call or an entry of a table the "
                  "firmware transfers to.  So it is emitted as bytes rather than "
                  "guessed." % (n, "" if n == 1 else "s"))
    if clean:
        out += G.wrap("; ⚠ ",
                      "these bytes DO decode cleanly as instructions%s.  That is "
                      "not evidence: round 4's rule, which accepted a run on a "
                      "clean decode alone, accepts 13.9%% of record-aligned "
                      "chunks of PROVEN display-list data as code "
                      "(`python3 notes/prom_b_f6d002_layout.py --null-accept`)."
                      % (" and the decode even ends in a flow end, but nothing "
                         "reaches the run" if tail else
                         ", but the decode does not end in a "
                         "`ret`/`reti`/unconditional transfer"))
    if any(32 <= c < 127 for c in at(s, n)):
        out += G.wrap("; Contains: ", "printable bytes |%s|" % ascii_of(s, n))
    out += G.wrap("; Read by: ", G.reader_line(s))
    out += G.wrap("; Evidence: ", "the bytes are re-read on every emit; the "
                  "classification is NEGATIVE (no rule matched, no walk arrived) "
                  "and is stated as such.")
    out += G.wrap("; Unknown: ", "everything about it except its bytes.")
    out.append("; " + "-" * 74)
    out.append("%s:" % name)
    out += G.byte_rows(s, n)
    return out


# ------------------------------------------------------------------ headers
def grades():
    """{code-segment start: provenance grade}.

    Same five grades as round 5, in the same strength order.  See
    notes/prom_b_f6d002_layout.py --provenance, which prints the per-segment
    table and lists every weak grade by hand."""
    d = rom("b")
    proven = LY.proven_call_sites(LO, HI)
    thunk = set(t for _, t in MT.thunk_entries(LO, HI))
    far = L.far_calls(d, LO, HI)
    tab = LY.table_entry_seeds(d, LO, HI)
    out = {}
    for a in sorted(set(labels()) | {x for k, x, _ in LAYOUT if k == "code"}):
        out[a] = ("PROVEN" if a in proven else "THUNK" if a in thunk else
                  "CALL" if a in far else "TABLE" if a in tab else "BRANCH")
    return out


GRADE_TEXT = {
    "PROVEN": "an instruction ALREADY PROVEN in prom_a/prom_b's transcription "
              "calls or jumps here.  That is the strongest grade in this block: "
              "no byte-window scan is involved, the byte gate proves the file "
              "that carries the call site rebuilds the image.  This module has "
              "76 such addresses, more than every other unconverted prom_b span "
              "put together (`python3 notes/prom_b_span_frontier.py --by proven`)",
    "THUNK": "a `jp` slot of the 0xF40000 routine directory holds `jp` to this "
             "address, so the firmware's own routine table names it.  Only TWO "
             "slots reach this module -- T_F43380 and T_F43384 -- which is why "
             "the thunk-run frontier ranks it thirteenth and why it was chosen "
             "with a different tool",
    "CALL": "an opcode-anchored `call`/`jp addr24` in prom_a or prom_b targets "
            "it.  The scan is at every byte offset, so a hit is an upper bound "
            "on the CALL COUNT -- but a hit that decodes is still a real "
            "instruction",
    "TABLE": "it is an entry of a pointer table the consumer rule classed "
             "TRANSFER: the code that indexes that table fetches the entry and "
             "then transfers to it.  This module has two such tables, both of 16 "
             "entries, at 0xF7048D and 0xF72323",
    "BRANCH": "a branch decoded inside this block targets it, and the block's "
              "own code is reached from the grades above",
}


_extp = []


def _external_proven():
    """The 76 addresses an already-converted instruction OUTSIDE this block
    calls or jumps to.

    ⚠ IT MUST BE THE BLOCK'S RANGE, NOT THE ROUTINE'S.  The first draft asked
    `LY.proven_call_sites(a, a + 1)`, i.e. "is there any transcribed transfer to
    exactly `a`".  While the block was `.incbin` that was the same question; once
    the block is in the `.s`, every in-module `calr` answers YES, and 100+
    routines gained the line "an already-converted call site ELSEWHERE in the
    image" directly after their in-module call sites were listed.  Same defect as
    the one in prom_b_f0ea9f_layout.proven_call_sites, one level up."""
    if not _extp:
        _extp.append(LY.proven_call_sites(LO, HI))
    return _extp[0]


def header(a, end, lab, th, sr, ic, gr):
    out = ["; " + "-" * 74, "; %s" % lab[a]]
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    if a in _external_proven():
        parts.append("an already-converted call site elsewhere in the image")
    out += G.wrap("; Called from: ", "; ".join(parts) if parts else
                  "no thunk slot and no in-module call or jp site -- reached "
                  "only by a branch from the routine above, or through a table")
    sm, bg = G.touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sorted(sm)[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in sorted(bg)[:6])
    out += G.wrap("; Touches: ", tt or "nothing with an absolute address")
    co = G.calls_out(a, end, lab)
    if co:
        out += G.wrap("; Calls:   ", " ".join(co[:12]) +
                      (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    g = gr.get(a, "BRANCH")
    out += G.wrap("; Evidence (%s): " % g,
                  GRADE_TEXT[g] + ".  0x%06X is an instruction boundary of this "
                  "transcription, re-asserted on every emit.  The name IS the "
                  "address." % a)
    out += G.wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX "
                  "with the gap stated, per this tree's rule that a stated gap "
                  "beats a plausible guess.")
    out.append("; " + "-" * 74)
    return out


# ------------------------------------------------------------------- checks
FAIL = []


def c(name, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append((name, got, want))
    if verbose:
        print("  %-76s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                              % (got, want)))
    return ok


def checks(verbose=True):
    del FAIL[:]
    segs, conflicts, pend, ok, seen = LY6.build()
    c("LAYOUT equals notes/prom_b_f6d002_layout.py's derivation", segs, LAYOUT,
      verbose)
    c("  the layout's barrier rules reclaim no descent byte", len(conflicts), 0,
      verbose)
    c("  LAYOUT is contiguous and covers 0x%06X-0x%06X" % (LO, HI - 1),
      [(LAYOUT[0][1], sum(n for _, _, n in LAYOUT))], [(LO, HI - LO)], verbose)
    c("  the LAST LAYOUT segment ends exactly on 0x%06X" % HI,
      LAYOUT[-1][1] + LAYOUT[-1][2], HI, verbose)
    th = G.thunks()
    c("thunk slots of 0xF40000 landing in this block",
      sum(len(v) for v in th.values()), 2, verbose)
    c("  and they are T_F43380 and T_F43384",
      sorted("T_%06X" % s for v in th.values() for s in v),
      ["T_F43380", "T_F43384"], verbose)
    c("distinct PROVEN call targets inside the block",
      len(LY.proven_call_sites(LO, HI)), 76, verbose)
    for kind, s, n in LAYOUT:
        if kind == "ptrtab":
            c("  ptrtab 0x%06X: all %d words are 0x00F0xxxx-0x00F7xxxx"
              % (s, n // 4),
              [i for i in range(n // 4)
               if not (0x00F00000 <= w32(s + 4 * i) < 0x00F80000)], [], verbose)
        if kind == "ramtab":
            c("  ramtab 0x%06X: all %d words are below 0x10000" % (s, n // 4),
              [i for i in range(n // 4) if not (0 < w32(s + 4 * i) < 0x10000)],
              [], verbose)
        if kind == "ident":
            bad = []
            for a, ln, v0, v1 in G.ident_subruns(s, n):
                if [at(a + k, 1)[0] for k in range(ln)] != list(range(v0, v0 + ln)):
                    bad.append(hex(a))
            c("  ident 0x%06X: every sub-run counts up by one" % s, bad, [],
              verbose)
        if kind == "bytemap":
            subs = bytemap_subruns(s, n)
            bad = []
            for a, e in subs:
                last = None
                for i, v in enumerate(at(a, e - a)):
                    if v == 0xFF:
                        continue
                    if last is not None and v <= last:
                        bad.append((a, i))
                    last = v
            tiles = (bool(subs) and subs[0][0] == s and subs[-1][1] == s + n
                     and all(subs[i][1] == subs[i + 1][0]
                             for i in range(len(subs) - 1)))
            c("  bytemap 0x%06X: its %d maximal ascending run%s tile%s the "
              "segment exactly, each ascends strictly, and it does not end in "
              "0xFF" % (s, len(subs), "" if len(subs) == 1 else "s",
                        "s" if len(subs) == 1 else ""),
              (bad, tiles, at(s + n - 1, 1)[0] == 0xFF), ([], True, False),
              verbose)
        if kind == "ascii":
            c("  ascii 0x%06X: every one of %d bytes is 0x20-0x7E" % (s, n),
              all(32 <= x < 127 for x in at(s, n)), True, verbose)
        if kind == "fill":
            c("  fill 0x%06X..0x%06X is pure 0x0E (`ret`)" % (s, s + n - 1),
              set(at(s, n)), {0x0E}, verbose)
            c("  fill 0x%06X is MAXIMAL: neither neighbour is 0x0E" % s,
              (at(s - 1, 1)[0] == 0x0E, at(s + n, 1)[0] == 0x0E),
              (False, False), verbose)
    lab, b = labels(), G.boundaries()
    data_starts = {s for k, s, _ in LAYOUT if k in DATA_KINDS}
    c("every data segment start has a label",
      sorted("0x%06X" % x for x in data_starts if x not in lab), [], verbose)
    c("every non-data label is an instruction boundary",
      sorted("0x%06X" % x for x in lab if x not in data_starts and x not in b),
      [], verbose)
    c("no label falls inside the .fill run",
      sorted("0x%06X" % a for a in lab
             if any(k == "fill" and s <= a < s + n for k, s, n in LAYOUT)),
      [], verbose)
    for kind, s, n in LAYOUT:
        if kind == "code":
            ls = [a for a, _ in G.code_lines() if s <= a < s + n]
            c("  code 0x%06X..0x%06X transcribed, first==start" % (s, s + n - 1),
              (min(ls), len(G.transcribe(s, n))), (s, len(ls)), verbose)
    # LAST-ELEMENT TEST: the tree's standing rule is that a quantified claim is
    # tested on the last element, because a loop that stops early passes
    # everything else.
    klast, slast, nlast = LAYOUT[-1]
    c("LAST segment (%s 0x%06X+%d) is emitted: its label exists and its last "
      "byte is 0x%02X" % (klast, slast, nlast, at(slast + nlast - 1, 1)[0]),
      (slast in lab, slast + nlast), (True, HI), verbose)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


def counts():
    k, b = {}, {}
    for kind, _, n in LAYOUT:
        k[kind] = k.get(kind, 0) + 1
        b[kind] = b.get(kind, 0) + n
    tk = {}
    for kind, s, n in LAYOUT:
        if kind == "ptrtab":
            t = kind_of_table(s, n)
            tk[t] = tk.get(t, 0) + 1
    return k, b, tk


STRINGS_CITED = [
    (0xF6D527, "  TEMPO  "),
    (0xF6D66D, "START   STOP    FILL IN1FILL IN2INTRO1  COUNT IN"),
    (0xF6D7E7, "P 1 P 2 P 3 ... P32"),
    (0xF6DE10, "VOLUME="),
    (0xF6DF50, "PANPOT="),
    (0xF6DFBA, "KEY SHIFT="),
    (0xF6E027, "TUNING="),
    (0xF6E087, "BEND SENS="),
    (0xF6E0EB, "SUSTAIN ON  OFF "),
    (0xF6E1A6, "DSP EFFECT "),
    (0xF6E2FF, "REVERB="),
    (0xF6E33F, "PANEL MEMORY="),
    (0xF6E34D, "APC OFF         ONE FINGER      FINGERED        PIANIST"),
    (0xF6E43F, "DYNAMIC ACCOMP ON "),
    (0xF6E452, "TECHNI-CHORD ON "),
    (0xF6E542, "ACC. TOTAL VOL.="),
    (0xF6E66A, "TOTAL REVERB "),
    (0xF6E6ED, "M.S.A. OFF ON  #2  #3  "),
    (0xF6E728, "TIME SIGNATURE: /4"),
    (0xF6E7E8, "CTRL.PEDAL="),
    (0xF6E89A, "R.T.CREAT.X="),
    (0xF6F528, "MThdMTrk"),
]


def banner():
    k, b, tk = counts()
    sm, bg = G.touched(LO, HI)
    top_small = sorted(sm.items(), key=lambda x: -x[1])[:6]
    gr = grades()
    gcount = {}
    for kind, s, n in LAYOUT:
        if kind == "code" and s in gr:
            gcount[gr[s]] = gcount.get(gr[s], 0) + 1
    strs = "".join(";     0x%06X  `%s`\n" % (a, t) for a, t in STRINGS_CITED)
    dev = ("NOT ONE absolute operand in 0x600000-0x7FFFFF: the block touches no "
           "device, only RAM." if not bg else
           "absolute operands outside RAM: " +
           " ".join("0x%06X" % x for x in sorted(bg)[:12]))
    return """
; ==============================================================================
; 0xF6D002-0xF77FFF -- THE PERFORMANCE / ACCOMPANIMENT SCREEN LAYER
;   45,054 bytes converted as one contiguous span, closing the largest `.incbin`
;   in prom_b that any already-converted instruction calls into
; ==============================================================================
;
; @@ WHY THIS SPAN, AND WHY NOT THE THUNK FRONTIER'S TOP RUN.
; notes/prom_b_module_frontier.py ranks whole thunk RUNS by the contiguous
; unconverted extent of their targets, and by that measure this span is
; THIRTEENTH of fourteen: it owns exactly two `jp` slots of the 0xF40000 routine
; directory, T_F43380 -> 0xF6F400 and T_F43384 -> 0xF6F404, an extent of 4 bytes.
; That tool is blind to a module entered by DIRECT CALL, and this one is.
; notes/prom_b_span_frontier.py ranks the `.incbin` SPANS instead, by how many
; DISTINCT addresses inside them an ALREADY-TRANSCRIBED instruction calls or
; jumps to:
;
;     span                     bytes  proven  thunk
;     0xF6D002-0xF77FFF        45054      76      2    <- this one
;     0xF7E2D8-0xF7FFFF         7464      38      0
;     0xF067A6-0xF0D79B        28662       4     24
;     0xF157A8-0xF27BFF        74840       0     13
;
; 76 is more than every other unconverted prom_b span put together.  `proven` is
; the strongest evidence this tree has that a span holds code: the byte gate
; proves the file carrying the call site rebuilds the image, so no byte-window
; scan is involved.
;
; @@ WHAT THE BLOCK IS -- FROM ITS OWN STRINGS, WHICH NAME THE SCREENS.
%s;
; That is the PERFORMANCE and ACCOMPANIMENT screen layer, and from 0xF6F000
; upwards the sequencer/song side of it -- `MThdMTrk`, the Standard MIDI File
; header and track tags, sits at 0xF6F528 as a template.  @@ THAT IS WHAT THE
; STRINGS SAY AND IT IS ALL IT SAYS.  Not one routine below is named for a
; screen: every one is `sub_XXXXXX` with its evidence grade, because a string
; near a routine is not a claim about the routine.
;
; @@ ONE OBJECT IN HERE IS IDENTIFIED BEYOND ARGUMENT: A STANDARD MIDI FILE
; READER.  The routines stay `sub_XXXXXX` -- that is this lane's rule and a
; string near a routine does not name it -- but the PARSE is decoded, and it is
; checked rather than asserted (`python3 notes/prom_b_smf_reader.py --list`,
; 40 checks, every instruction re-decoded from the ROM):
;
;   * 0xF6F528 holds `MThdMTrk`, the SMF header-chunk tag and track-chunk tag,
;     used as two 4-byte compare templates -- 0xF6F59B `ld XIY,0x00f6f528` and
;     0xF6F658 `ld XIY,0x00f6f52c`, each with `ld BC,0x0004` and `cp A,(XIY+)`.
;   * The input is a 1,024-byte sliding window at 0x60A700-0x60AAFF.  The cursor
;     is (0x1088); the byte fetch is 0xF7138F (`ld XIX,(0x1088) / ld A,(XIX+)`)
;     and it refills through 0xF765D4 when the cursor passes 0x60AAFF
;     (0xF7139C and 0xF6FD9E both `cp XIX,0x0060aaff`).
;   * The six header bytes go to six RAM bytes as big-endian pairs: format
;     (0x1079)/(0x1078), ntrks (0x107B)/(0x107A), division (0x107D)/(0x107C).
;   * All three of the SMF specification's own rejections are implemented:
;     0xF6F5FE `bit 0x07,A` on the division HIGH byte then `jrl NZ` -- a
;     NEGATIVE division is SMPTE timecode and this reader refuses it; division
;     low word 0 -> 0x30 in (0x2880); and format must be 0 or 1 (0xF6F61E
;     `cp (0x1078),0x0000`, 0xF6F626 `cp (0x1078),0x0001`, `jrl NZ` otherwise).
;   * A failed `MThd` match retries ONCE at 0x60A700 + 0x80 and then gives up
;     with 0x31 in (0x2880).
;   * 0xF7661E-0xF7662C writes 0x4D 0x49 0x44 -- `M` `I` `D` -- into
;     (0x21D0)-(0x21D2), an 8.3 filename EXTENSION field.
;
; @@ WHAT IS NOT ESTABLISHED ABOUT IT.  WHERE the bytes come from: the refill
; leaves prom_b through T_F425A8/T_F425B0/T_F425E8 into prom_a 0xFE1C3A /
; 0xFE1C55 / 0xFE1CB3, all three of which are `sub_` there.  And whose buffer
; 0x60A700 is: it lies inside the 0x60A000 region prom_a's block/remote reader
; passes as a DESTINATION -- `lda_24 XBC,(0x60a000)` at 21 sites in prom_a's
; transcription, `grep -c 'lda_24 xbc, (0x60a000)' prom_a/wsa1_prom_a.s` -- and
; THIS block names 0x60A000 itself as well as 0x60A700.  That is an ADJACENCY and
; not a proof that the same transfer fills the buffer; what does is a prom_a
; question, and the prom_a lane has already had to retract one conclusion built
; on this region.
;
; @@ WHERE THE BOUNDARIES COME FROM -- AND ROUND 6 ADDED NO RULE.
; notes/prom_b_f6d002_layout.py is notes/prom_b_f0ea9f_layout.py with LO/HI
; changed AND NOTHING ELSE.  Round 5 had to add five rules to round 4's because
; round 4's method produced false code here; round 6 had to add none, and the
; measurements say so rather than the author:
;   * barrier conflicts: 0 (`--conflicts`);
;   * every content rule (PTRTAB, RAMTAB, BITTAB, IDENT, ASCII, BYTEMAP) still
;     fires ZERO times over the proven prom_b instruction text (`--null-ptr`);
;   * accept()'s tail rule is unchanged and its null is the same proven
;     display-list corpus (`--null-accept`).
; The one thing that IS new is a measurement, not a rule: this span carries an
; 865-byte run of 0x0E at 0xF6EC9F, the first `.fill` any prom_b round has met.
; It is FILLER and is excluded from the substantive total below.
;
; @@ EVERY ROUTINE CARRIES ITS PROVENANCE GRADE.
; `Evidence (PROVEN|THUNK|CALL|TABLE|BRANCH)` says which of the five reasons is
; the strongest one its entry point has: %s.
; @@ THAT LINE COUNTS CODE SEGMENTS AND USES FIVE GRADES;
; `python3 notes/prom_b_f6d002_layout.py --provenance` USES NINE AND WILL NOT
; PRINT THE SAME NUMBERS.  It separates FALL, IMMED and ACCEPT out of what this
; line calls BRANCH, so its table reads BRANCH 25 + ACCEPT 9 where this one reads
; BRANCH 34; PROVEN 31, CALL 6, TABLE 3 and THUNK 1 are identical in both.  The
; weak grades are 3 TABLE segments (1,585 bytes) and 9 ACCEPT segments (1,637
; bytes) -- 9.9%% of the code -- and --provenance prints every one of the twelve
; individually so it can be looked at by hand.  ZERO segments have no reason at
; all.  ⚠ And the ROUTINE grades are a THIRD unit again: 316 routines carry a
; header here, graded PROVEN 75 / BRANCH 188 / CALL 36 / TABLE 15 / THUNK 2.
; Segments are not routines; do not compare the three tables row for row.
;
; LAYOUT.  %d segments, %d bytes, counted from the LAYOUT literal:
%s;   pointer tables by kind: %s.
;   substantive %d bytes, filler %d bytes.
;
; WHAT THE BLOCK TOUCHES, measured over the transcription itself.  Heaviest
; 16-bit RAM words: %s.
; %s
;
; REGENERATE:  python3 notes/gen_prom_b_f6d002_module.py
; CHECKS:      python3 notes/gen_prom_b_f6d002_module.py --checks
; ==============================================================================
""" % (strs,
       " ".join("%s %d" % t for t in sorted(gcount.items(), key=lambda x: -x[1])),
       len(LAYOUT), sum(b.values()),
       "".join(";   %-24s %3d segments %6d bytes\n"
               % (KIND_NAME[kk], k[kk], b[kk]) for kk in ORDER if k.get(kk)),
       ", ".join("%d %s" % (v, kk) for kk, v in sorted(tk.items())),
       sum(v for kk, v in b.items() if kk != "fill"), b.get("fill", 0),
       " ".join("(0x%04X) (x%d)" % t for t in top_small),
       dev)


def emit():
    lab, th, sr, ic = labels(), G.thunks(), G.slot_refs(), G.internal_calls()
    gr = grades()
    keys = sorted(lab)
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else HI)
            for i, a in enumerate(keys)}
    out = banner().replace("@@", "⚠").strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["", "\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding "
                    "(asserted pure 0x0E, and maximal)" % (n, s, s + n - 1), ""]
            continue
        if kind in DATA_KINDS:
            out += [""] + data_block(kind, s, n, lab) + [""]
            continue
        for a, ln in [(a, l) for a, l in G.code_lines() if s <= a < s + n]:
            if a in lab:
                out += [""] + header(a, ends[a], lab, th, sr, ic, gr)
                tag = "\t\t; <- %s" % ", ".join("T_%06X" % x for x in th[a]) \
                      if a in th else ""
                out.append("%s:%s" % (lab[a], tag))
            out.append(ln)
    return out


def main():
    install()
    if "--layout" in sys.argv:
        tot = {}
        for kind, s, n in LAYOUT:
            print("  %-8s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
            tot[kind] = tot.get(kind, 0) + n
        print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("  substantive %d of %d"
              % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
        return 0
    if "--tables" in sys.argv:
        lab = labels()
        for kind, s, n in LAYOUT:
            if kind in DATA_KINDS:
                extra = kind_of_table(s, n) if kind == "ptrtab" else ""
                print("  %-8s %-26s 0x%06X  %5d bytes  refs %d  %s"
                      % (kind, lab[s], s, n, len(G.direct_refs(s)), extra))
        return 0
    if "--checks" in sys.argv:
        return 0 if checks() else 1
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
