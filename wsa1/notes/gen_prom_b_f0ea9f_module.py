#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF0EA9F-0xF13D33 -- the block the top run of
the frontier points into, and the biggest contiguous unconverted code in prom_b.

QUESTION IT ANSWERS
    "What is the assembly text for the twelve-slot thunk run T_DspEffect_SetSection-T_F42F6C
     and everything reachable with it, in a form the byte gate accepts, with
     every label and header attached to the right address?"  This is the emitter
     whose output is pasted into prom_b/wsa1_prom_b.s.

WHY THIS BLOCK (round 5, chosen with the frontier tool, not by address order)
    notes/prom_b_module_frontier.py ranks whole thunk RUNS by CONTIGUOUS
    unconverted target extent.  Its top run is
        T_DspEffect_SetSection-T_F42F6C  12 slots  extent 13,084  targets 0xF0F018-0xF12334
    and T_DspParam_WriteByNumber-T_DspParam_ReadByNumber (2 slots, 0xF11C30 / 0xF1220B) points into the same
    span.  Both are inside 0xF0EA9F-0xF13D33.

WHERE THE BOUNDARIES COME FROM
    notes/prom_b_f0ea9f_layout.py, which is notes/prom_b_f65000_layout.py plus
    FIVE changes this module needed and that one did not.  Read that file first;
    its docstrings carry the null measurement for each.  In short:
      * the pointer-table window is the whole image, not 0x00F6xxxx;
      * a table the firmware DEREFERENCES rather than transfers to does not seed
        the code walk (the consumer rule) -- two of this module's three
        128-entry tables are of that kind;
      * a table whose entries are an arithmetic progression is an ARRAY
        descriptor and does not seed the walk either (STRIDED);
      * an ascending byte table with 0xFF holes is framed as data, not decoded
        and not called a string (BYTEMAP);
      * the walk does not follow loaded 32-bit immediates at all, and an
        unreached run is code only if its decode also ENDS IN A FLOW END.

RUN
    python3 notes/gen_prom_b_f0ea9f_module.py            # the assembly
    python3 notes/gen_prom_b_f0ea9f_module.py --layout   # the segment table
    python3 notes/gen_prom_b_f0ea9f_module.py --checks   # REFUSES to emit on fail
    python3 notes/gen_prom_b_f0ea9f_module.py --tables   # every data object
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import gen_prom_b_f65000_module as G                               # noqa: E402
import prom_b_f0ea9f_layout as LY                                  # noqa: E402
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402
import trace_code as TC                                            # noqa: E402

LO, HI = LY.LO, LY.HI
B_BASE = 0xF00000

LAYOUT = [
    ("code", 0xF0EA9F, 0x02B1),
    ("ptrtab", 0xF0ED50, 0x009C),
    ("data", 0xF0EDEC, 0x0080),
    ("ptrtab", 0xF0EE6C, 0x0074),
    ("data", 0xF0EEE0, 0x011F),
    ("ramtab", 0xF0EFFF, 0x0018),
    ("data", 0xF0F017, 0x0001),
    ("code", 0xF0F018, 0x00B6),
    ("ptrtab", 0xF0F0CE, 0x0018),
    ("code", 0xF0F0E6, 0x006C),
    ("ptrtab", 0xF0F152, 0x0018),
    ("code", 0xF0F16A, 0x007E),
    ("ptrtab", 0xF0F1E8, 0x0018),
    ("code", 0xF0F200, 0x009A),
    ("ptrtab", 0xF0F29A, 0x0018),
    ("code", 0xF0F2B2, 0x0046),
    ("ptrtab", 0xF0F2F8, 0x0018),
    ("code", 0xF0F310, 0x0037),
    ("ptrtab", 0xF0F347, 0x0018),
    ("code", 0xF0F35F, 0x004F),
    ("ptrtab", 0xF0F3AE, 0x0018),
    ("code", 0xF0F3C6, 0x0044),
    ("ptrtab", 0xF0F40A, 0x0018),
    ("code", 0xF0F422, 0x003F),
    ("ptrtab", 0xF0F461, 0x0018),
    ("code", 0xF0F479, 0x004B),
    ("ptrtab", 0xF0F4C4, 0x0018),
    ("code", 0xF0F4DC, 0x003A),
    ("ptrtab", 0xF0F516, 0x0018),
    ("code", 0xF0F52E, 0x002A),
    ("ptrtab", 0xF0F558, 0x0018),
    ("code", 0xF0F570, 0x004E),
    ("ptrtab", 0xF0F5BE, 0x0018),
    ("code", 0xF0F5D6, 0x0068),
    ("ptrtab", 0xF0F63E, 0x0018),
    ("code", 0xF0F656, 0x004E),
    ("ptrtab", 0xF0F6A4, 0x0018),
    ("code", 0xF0F6BC, 0x004C),
    ("ptrtab", 0xF0F708, 0x0018),
    ("code", 0xF0F720, 0x1642),
    ("data", 0xF10D62, 0x009E),
    ("code", 0xF10E00, 0x000F),
    ("data", 0xF10E0F, 0x00F0),
    ("code", 0xF10EFF, 0x083B),
    ("data", 0xF1173A, 0x0004),
    ("code", 0xF1173E, 0x0D68),
    ("data", 0xF124A6, 0x0048),
    ("ramtab", 0xF124EE, 0x001C),
    ("data", 0xF1250A, 0x0018),
    ("ramtab", 0xF12522, 0x0010),
    ("data", 0xF12532, 0x0018),
    ("ramtab", 0xF1254A, 0x0010),
    ("data", 0xF1255A, 0x0018),
    ("ramtab", 0xF12572, 0x0010),
    ("data", 0xF12582, 0x01C4),
    ("ramtab", 0xF12746, 0x0020),
    ("data", 0xF12766, 0x00C8),
    ("ramtab", 0xF1282E, 0x001C),
    ("data", 0xF1284A, 0x06DA),
    ("ptrtab", 0xF12F24, 0x0200),
    ("data", 0xF13124, 0x00C0),
    ("ptrtab", 0xF131E4, 0x0200),
    ("bytemap", 0xF133E4, 0x0064),
    ("data", 0xF13448, 0x001C),
    ("bytemap", 0xF13464, 0x002C),
    ("data", 0xF13490, 0x0001),
    ("bytemap", 0xF13491, 0x0064),
    ("data", 0xF134F5, 0x001C),
    ("bytemap", 0xF13511, 0x002C),
    ("data", 0xF1353D, 0x0011),
    ("bytemap", 0xF1354E, 0x0054),
    ("data", 0xF135A2, 0x001D),
    ("ident", 0xF135BF, 0x000C),
    ("bytemap", 0xF135CB, 0x002B),
    ("data", 0xF135F6, 0x0007),
    ("ptrtab", 0xF135FD, 0x005C),
    ("data", 0xF13659, 0x001B),
    ("ptrtab", 0xF13674, 0x0200),
    ("data", 0xF13874, 0x00DB),
    ("ptrtab", 0xF1394F, 0x005C),
    ("data", 0xF139AB, 0x0389),
]

# ^ derived, not typed: notes/prom_b_f0ea9f_layout.py --all


def install():
    """Point the shared emitter helpers at THIS module's range and layout.

    gen_prom_b_f65000_module's helpers (transcribe/code_lines/labels/touched/
    direct_refs/...) all read their module globals, so swapping the globals
    reuses them without a second copy of the code.  Nothing else in the tree
    imports that module at run time, so this is process-local."""
    G.LO, G.HI, G.LAYOUT = LO, HI, LAYOUT
    G.STUB, G.DEFAULT_SLOT = STUB, 0x00F42C70
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
             "ascii": "strings", "bittab": "bit-weight tables"}
ORDER = ("code", "ptrtab", "data", "bytemap", "ramtab", "ident", "ascii",
         "bittab")
STUB = None          # this module has no single do-nothing entry; see counts()


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


def labels():
    """{address: label}.  Data objects are named for their CONTENT and for the
    table kind the consumer rule established; routines are sub_XXXXXX."""
    got = {}
    for t in G.thunks():
        got[t] = None
    for callee in G.internal_calls():
        got[callee] = None
    # ⚠ and the two entry sources the 0xF65000 emitter did not label: an address
    # an ALREADY-PROVEN instruction calls (0xF0EA9F, the block's own head, had no
    # header at all before this), and an entry of a table the consumer rule
    # classed TRANSFER -- which is a routine entry point by that rule's own
    # argument, and half this block's code is reached only that way.
    for t in LY.proven_call_sites():
        got[t] = None
    for t in LY.table_entry_seeds(rom("b"), LO, HI):
        got[t] = None
    for kind, s, n in LAYOUT:
        if kind in DATA_KINDS:
            got[s] = None
    b = G.boundaries()
    data_starts = {s: (k, n) for k, s, n in LAYOUT if k in DATA_KINDS}
    for a in list(got):
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


def provenance_of(a, seen_by):
    return seen_by.get(a, "TABLE")


def data_block(kind, s, n, lab):
    name = lab[s]
    out = ["; " + "-" * 74]
    if kind == "ptrtab":
        tk = kind_of_table(s, n)
        ps = [w32(s + 4 * i) for i in range(n // 4)]
        nd = sorted(set(ps))
        out += G.wrap("; %s -- " % name,
                      "%d 32-bit words, every one an address in "
                      "0x00F00000-0x00F7FFFF, i.e. inside this image.  %d "
                      "distinct value%s.  notes/prom_b_f0ea9f_layout.py "
                      "classes it %s."
                      % (n // 4, len(nd), "" if len(nd) == 1 else "s", tk))
        why = {"TRANSFER": "the code that indexes it fetches an entry and then "
                           "TRANSFERS to it, so the entries are ENTRY POINTS and "
                           "they seed this block's code walk",
               "DEREF": "the code that indexes it fetches an entry and then "
                        "READS THROUGH IT (an 8- or 16-bit load), so the entries "
                        "are DATA addresses; they do NOT seed the code walk, and "
                        "what they point at is emitted as bytes",
               "STRIDED": "its entries are an arithmetic progression, which is "
                          "an ARRAY of fixed-size records rather than a set of "
                          "handlers; the entries do not seed the code walk",
               "UNKNOWN": "no instruction in prom_a or prom_b spells this "
                          "address as a 32-bit word in a decodable operand, so "
                          "nothing here says how it is indexed; the entries do "
                          "NOT seed the code walk"}[tk]
        out += G.wrap("; Why %s: " % tk, why)
        if tk == "STRIDED":
            out += G.wrap("; Stride: ", "%d bytes, constant across all %d "
                          "entries, from 0x%06X to 0x%06X."
                          % (ps[1] - ps[0], n // 4, ps[0], ps[-1]))
        out += G.wrap("; Read by: ", G.reader_line(s))
        out += G.wrap("; Entry count: ",
                      "%d, and it is NOT a byte extent divided by four.  The "
                      "chain rule that finds it stops at the first word that is "
                      "not an 0x00F0xxxx-0x00F7xxxx address; that word is at "
                      "0x%06X.  Entry %d, the last, is 0x%08X."
                      % (n // 4, s + n, n // 4 - 1, ps[-1]))
        out += G.wrap("; Evidence: ",
                      "every one of the %d words is re-read and range-asserted "
                      "on every emit.  The PTRTAB rule at this window fires ZERO "
                      "times over the proven prom_b instruction text "
                      "(`python3 notes/prom_b_f0ea9f_layout.py --null-ptr`), and "
                      "the STRIDED rule fires zero times over the 33 proven "
                      "dispatch tables of this image (`--null-stride`)."
                      % (n // 4))
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
        out += G.wrap("; %s -- " % name,
                      "%d bytes: a BYTE MAP.  %d of them are 0xFF and the other "
                      "%d ASCEND STRICTLY, 0x%02X to 0x%02X, with jumps.  0xFF "
                      "is the absent marker the consumer tests for -- "
                      "`ld H,(XWA)` at 0xF10619, `cp H,0xff` at 0xF1061B."
                      % (n, n - len(vals), len(vals), vals[0], vals[-1]))
        asc = L.ascii_runs(rom("b"), s, s + n)
        if asc:
            out += G.wrap("; \u26a0 ",
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
                      "0x%02X." % (n, at(s - 1, 1)[0]))
        out += G.wrap("; Evidence: ",
                      "every non-0xFF byte is compared with its predecessor "
                      "on every emit.  The BYTEMAP rule fires ZERO times over "
                      "the proven prom_b instruction text at (16 bytes, 12 "
                      "values) and also at (20,14), (24,16) and (16,16) "
                      "(`python3 notes/prom_b_f0ea9f_layout.py --null-ptr`).")
        out += G.wrap("; Unknown: ", "what the two index spaces ARE.  The name "
                      "describes the CONTENT.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += G.byte_rows(s, n)
        return out
    if kind == "ramtab":
        vs = [w32(s + 4 * i) for i in range(n // 4)]
        dif = sorted(set(vs[i + 1] - vs[i] for i in range(len(vs) - 1)))
        out += G.wrap("; %s -- " % name,
                      "%d 32-bit words, every one below 0x10000, i.e. a 16-bit "
                      "RAM address stored one per long word.  First 0x%04X, last "
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
                      "proven prom_b instruction text "
                      "(`python3 notes/prom_b_f0ea9f_layout.py --null-ptr`).")
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
                      "times over the proven prom_b instruction text.")
        out += G.wrap("; Unknown: ", "why an index map that returns its own "
                      "index exists.  Recorded, not explained.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += G.byte_rows(s, n)
        return out
    # plain data -- NEGATIVE classification, and the round-5 rules are named so
    # the reader knows which tests it failed rather than only that it failed.
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
        out += G.wrap("; \u26a0 ",
                      "these bytes DO decode cleanly as instructions%s.  That is "
                      "not evidence: round 4's rule, which accepted a run on a "
                      "clean decode alone, accepts 13.9%% of record-aligned "
                      "chunks of PROVEN display-list data as code "
                      "(`python3 notes/prom_b_f0ea9f_layout.py --null-accept`)."
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
    """{code-segment start: provenance grade} -- see prom_b_f0ea9f_layout."""
    d = rom("b")
    proven = LY.proven_call_sites()
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
              "that carries the call site rebuilds the image",
    "THUNK": "a `jp` slot of the 0xF40000 routine directory holds `jp` to this "
             "address, so the firmware's own routine table names it",
    "CALL": "an opcode-anchored `call`/`jp addr24` in prom_a or prom_b targets "
            "it.  The scan is at every byte offset, so a hit is an upper bound "
            "on the CALL COUNT -- but a hit that decodes is still a real "
            "instruction",
    "TABLE": "it is an entry of a pointer table the consumer rule classed "
             "TRANSFER: the code that indexes that table fetches the entry and "
             "then transfers to it.  ⚠ Two of this module's three 128-entry "
             "tables are NOT of that kind and their targets are emitted as data",
    "BRANCH": "a branch decoded inside this block targets it, and the block's "
              "own code is reached from the grades above",
}


def header(a, end, lab, th, sr, ic, gr):
    out = ["; " + "-" * 74, "; %s" % lab[a]]
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    # ⚠ THE BLOCK'S RANGE, NOT THE ROUTINE'S (fixed 2026-08-25, round 6).
    # `proven_call_sites(a, a + 1)` asks "does any transcribed transfer target
    # exactly `a`", which once THIS block is in the `.s` is answered YES by the
    # block's own `calr`s -- so the line "an already-converted call site
    # ELSEWHERE in the image" would appear on every routine called from inside.
    # While the block was `.incbin` the two questions coincided, which is why the
    # emitted file is right and the generator was not.
    ext = a in LY.proven_call_sites(LO, HI)
    if ext:
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
        print("  %-72s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                              % (got, want)))
    return ok


def checks(verbose=True):
    del FAIL[:]
    d = rom("b")
    segs, conflicts, pend, ok, seen = LY.build()
    c("LAYOUT equals notes/prom_b_f0ea9f_layout.py's derivation", segs, LAYOUT,
      verbose)
    c("  the layout's barrier rules reclaim no descent byte", len(conflicts), 0,
      verbose)
    c("  LAYOUT is contiguous and covers 0x%06X-0x%06X" % (LO, HI - 1),
      [(LAYOUT[0][1], sum(n for _, _, n in LAYOUT))], [(LO, HI - LO)], verbose)
    th = G.thunks()
    c("thunk slots of 0xF40000 landing in this block",
      sum(len(v) for v in th.values()), 14, verbose)
    for run, lo_, hi_ in (("T_DspEffect_SetSection-T_F42F6C", 0xF42F40, 0xF42F6C),
                          ("T_DspParam_WriteByNumber-T_DspParam_ReadByNumber", 0xF434A0, 0xF434A4)):
        tg = [w32(x) >> 8 for x in range(lo_, hi_ + 4, 4)]
        c("  every target of %s is inside this block" % run,
          [t for t in tg if not (LO <= t < HI)], [], verbose)
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
        if kind == "bittab":
            c("  bittab 0x%06X: entry k == 1 << k" % s,
              [i for i in range(n // 4) if w32(s + 4 * i) != 1 << i], [], verbose)
        if kind == "ident":
            bad = []
            for a, ln, v0, v1 in G.ident_subruns(s, n):
                if [at(a + k, 1)[0] for k in range(ln)] != list(range(v0, v0 + ln)):
                    bad.append(hex(a))
            c("  ident 0x%06X: every sub-run counts up by one" % s, bad, [],
              verbose)
        if kind == "bytemap":
            last, bad = None, []
            for i, v in enumerate(at(s, n)):
                if v == 0xFF:
                    continue
                if last is not None and v <= last:
                    bad.append(i)
                last = v
            c("  bytemap 0x%06X: every non-0xFF byte exceeds its predecessor, "
              "and the run does not end in 0xFF" % s,
              (bad, at(s + n - 1, 1)[0] == 0xFF), ([], False), verbose)
        if kind == "ascii":
            # ⚠ NOT "and the neighbours are not printable": the BYTEMAP rule is
            # painted over ASCII, so a surviving ascii segment can abut a
            # printable byte that belongs to a byte map.  The claim this check
            # makes is the one the emitted header makes.
            c("  ascii 0x%06X: every byte printable" % s,
              all(32 <= x < 127 for x in at(s, n)), True, verbose)
    lab, b = labels(), G.boundaries()
    data_starts = {s for k, s, _ in LAYOUT if k in DATA_KINDS}
    c("every data segment start has a label",
      sorted("0x%06X" % x for x in data_starts if x not in lab), [], verbose)
    c("every non-data label is an instruction boundary",
      sorted("0x%06X" % x for x in lab if x not in data_starts and x not in b),
      [], verbose)
    for kind, s, n in LAYOUT:
        if kind == "code":
            ls = [a for a, _ in G.code_lines() if s <= a < s + n]
            c("  code 0x%06X..0x%06X transcribed, first==start" % (s, s + n - 1),
              (min(ls), len(G.transcribe(s, n))), (s, len(ls)), verbose)
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


def banner():
    k, b, tk = counts()
    sm, bg = G.touched(LO, HI)
    top_small = sorted(sm.items(), key=lambda x: -x[1])[:6]
    gr = grades()
    gcount = {}
    for kind, s, n in LAYOUT:
        if kind == "code" and s in gr:
            gcount[gr[s]] = gcount.get(gr[s], 0) + 1
    return """
; ==============================================================================
; 0xF0EA9F-0xF13D33 -- THE BLOCK THE FRONTIER'S TOP RUN POINTS INTO
;   T_DspEffect_SetSection-T_F42F6C (12 slots) and T_DspParam_WriteByNumber-T_DspParam_ReadByNumber (2), converted as one
;   contiguous span of %d bytes
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_module_frontier.py ranks whole thunk RUNS by the
; CONTIGUOUS unconverted extent of their targets.  Its top run was
;
;   T_DspEffect_SetSection-T_F42F6C  12 slots  extent 13,084  targets 0xF0F018-0xF12334
;
; and T_DspParam_WriteByNumber-T_DspParam_ReadByNumber (0xF11C30, 0xF1220B) points into the same span.  The
; block starts where the already-converted field-blink engine's last routine
; ends: 0xF0EA9F is the target of `calr 0xf0ea9f` at 0xF0EA97, which is a PROVEN
; call site -- an instruction in this very file, not a byte-window hit.
;
; @@ WHERE THE BOUNDARIES COME FROM, AND WHAT THIS ROUND HAD TO FIX FIRST.
; notes/prom_b_f0ea9f_layout.py is notes/prom_b_f65000_layout.py plus THREE new
; rules, each with its own measured null.  All three exist because round 4's
; method, applied unchanged here, produced FALSE CODE that the byte gate cannot
; see:
;
;   1. THE CONSUMER RULE.  Round 4 seeded the code walk with every entry of every
;      pointer table.  Two of this module's three 128-entry tables are not
;      dispatch tables at all.  At 0xF10607-0xF1061D the firmware does
;      `ld A,0x04 / mul WA,(0x2796) / extz XWA / add XWA,0x00f12f24 /
;      ld XWA,(XWA) / add XWA,XBC / ld H,(XWA) / cp H,0xff` -- it READS A BYTE
;      through the entry and compares it with the absent-marker 0xFF.  Only
;      0xF131E4 is transferred to: 0xF10700 `add XBC,0x00f131e4 / ld XBC,(XBC) /
;      lda XIY,0xf10710 / push XIY / jp T,XBC`.  Seeding from the other two
;      decoded the 4-byte records at 0xF124EC-0xF12EE4 (`00 00 ff ff /
;      01 01 01 00 / 19 01 02 01`) as instructions, including nine one-byte
;      "routines" whose single byte is 0x07.  Every table below carries its
;      classification and the instruction that decided it.
;   2. STRIDED.  0xF0EE6C is 29 words stepping by exactly 72, and its first four
;      targets are 4 x 72 bytes of bitmap at 0xF0EEE0-0xF0EFFF, which came out as
;      `nop nop nop nop nop / normal / pop SR / reti` -- and that run even ENDS
;      in `reti`, so rule 4 below would not have caught it either.  A constant
;      stride is an ARRAY, not a handler set.  NULL: zero of the image's 33
;      proven dispatch tables (655 entries) is strided (`--null-stride`).
;   3. BYTEMAP.  An ascending byte table with 0xFF holes -- exactly what rule 1's
;      consumer compares against.  IDENT needs +1 exactly and sees only the
;      unbroken stretches, so the gaps were decoded as `nop / normal / push SR /
;      pop SR / max / halt / ei 0xff / reti`.  @@ AND THE ASCII RULE WAS MAKING
;      IT WORSE: 0xF13464 is `00 01 ... 0b 20 21 ... 63`, whose tail is 36
;      printable bytes, so the 20-byte ASCII rule framed it as a STRING.  Six
;      runs here are index tables and none is text, so BYTEMAP is painted OVER
;      ascii.  NULL: zero false positives over the proven prom_b instruction text
;      at (16 bytes, 12 values), (20,14), (24,16) and (16,16).
;
; And two of round 4's own decisions are OFF here, both for a measured reason:
;
;   4. THE TAIL RULE.  An unreached run is code only if its decode ALSO ends in a
;      `ret`/`reti`/unconditional transfer.  Round 4's rule without that accepts
;      13.9%% of record-aligned chunks of PROVEN display-list data as code;
;      with it, 1 of 1,884 (`--null-accept`).
;   5. NO IMMEDIATE-SEEDING.  Round 4 followed every 32-bit immediate an
;      instruction loads and priced that at +4,688 bytes.  Here it is wrong eight
;      times out of eight: `--provenance` graded eight segments (266 bytes) as
;      reachable ONLY that way and all eight are data -- seven are fragments of
;      the byte maps of rule 3 and 0xF13874 is 218 bytes of `60 00 01 /
;      61 00 ff / 61 01 ff ...`.  So the source is off, and the cost is stated rather than
;      hidden: any routine reachable only through a stored address is `.byte`
;      here.
;
; @@ EVERY ROUTINE CARRIES ITS PROVENANCE GRADE, not just a claim that it is
; code.  `Evidence (PROVEN|THUNK|CALL|TABLE|BRANCH)` says which of the five
; reasons is the strongest one its entry point has, and the grades are counted
; here: %s.
; `python3 notes/prom_b_f0ea9f_layout.py --provenance` re-derives them.
;
; LAYOUT.  %d segments, %d bytes, counted from the LAYOUT literal:
%s;   pointer tables by kind: %s.
; No `.fill`: this block has no padding run of 16 bytes or more, so every byte of
; it is substantive.
;
; WHAT THE BLOCK TOUCHES, measured over the transcription itself.  Heaviest
; 16-bit RAM words: %s.
; (0x2540) and (0x2640) are the display-list interpreters' own working words
; (notes/FINDINGS-ui-display-list.md); (0x2075)/(0x2076) are the UI
; redraw-request bytes of notes/FINDINGS-prom_b-field-blink.md.  There is NOT ONE
; absolute operand in 0x600000-0x7FFFFF anywhere in the block: it touches no
; device, only RAM.
;
; @@ WHAT THIS BLOCK IS -- A CORRESPONDENCE, NOT AN IDENTIFICATION.  Immediately
; above it sit the strings `DSP EFFECT`, `ALGORITHM :`, `OUT SELECT`, and
; EffectNames_F147AC -- converted this round, 128 entries of 16 characters, 56
; real names (`NO OPERATION`, `CHORUS`, `GATED REVERB`, `PLATE REVERB 1`,
; `PEQ+COMPR+DIST`) and 72 `----------` placeholders -- followed by
; EffectParamNames_F15024 (`WET`, `DRIVE`, `EMPHASIS Fc`, `LFO WAVEFORM`,
; `REVERB TIME`).  This block's three big tables have 128 entries each, and the
; index into them comes from (0x2796).  128 names and 128 table entries is a
; correspondence worth recording and it is NOT proof that the index is the effect
; number: nothing decoded here reads the name table, and nothing in prom_a or
; prom_b spells 0x00F147AC in a decodable operand at all.  Every routine here is
; `sub_XXXXXX`.
;
; @@ WHAT IS LEFT, AND THE RULE THAT WILL TAKE IT.  Above 0xF13D34 all that is
; converted is the two text tables of notes/gen_prom_b_effect_tables.py; the rest
; is a record region.  scripts/analysis/prom_b_display_lists.py cannot frame it:
; that tool finds a list's ENDS from `ld XIY,start / ld XIX,end` call sites and
; these lists have none.  What they have instead is in THIS block:
;     0xF110B9  add XBC,0x00f157a8 / push XBC / call 0xf42e0c
;     0xF11154  add XBC,0x00f15820 / push XBC / call 0xf42e0c
; and T_F42E0C is `jp DisplayListB_RunOne_Stack` (0xF3183D), already converted.
; Walking record lengths from those two bases gives 16 and 8 records of opcode
; 0x02, 15 bytes each, BOTH ending at 0xF15898, with the bases 8 x 15 apart --
; two entry points into one array (`python3 notes/prom_b_dlb_record_arrays.py`).
; That is a self-checking framing argument and it is the next round's rule.
;
; REGENERATE:  python3 notes/gen_prom_b_f0ea9f_module.py
; CHECKS:      python3 notes/gen_prom_b_f0ea9f_module.py --checks
; ==============================================================================
""" % (HI - LO,
       " ".join("%s %d" % t for t in sorted(gcount.items(), key=lambda x: -x[1])),
       len(LAYOUT), sum(b.values()),
       "".join(";   %-22s %3d segments %6d bytes\n" % (KIND_NAME[kk], k[kk], b[kk])
               for kk in ORDER if k.get(kk)),
       ", ".join("%d %s" % (v, kk) for kk, v in sorted(tk.items())),
       " ".join("(0x%04X) (x%d)" % t for t in top_small))


def emit():
    lab, th, sr, ic = labels(), G.thunks(), G.slot_refs(), G.internal_calls()
    gr = grades()
    keys = sorted(lab)
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else HI)
            for i, a in enumerate(keys)}
    out = banner().replace("@@", "⚠").strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
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
            print("  %-6s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
            tot[kind] = tot.get(kind, 0) + n
        print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("  substantive %d of %d" % (sum(tot.values()), HI - LO))
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
