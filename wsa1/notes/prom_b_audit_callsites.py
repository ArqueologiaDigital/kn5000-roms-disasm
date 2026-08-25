#!/usr/bin/env python3
"""Does every address a prom_b header CITES really start an instruction that reaches the object?

WHY THIS EXISTS
  The audit of round 1 (finding F2) caught twelve `Read by:` citations in
  prom_b/wsa1_prom_b.s that named the address of an OPERAND rather than of the
  instruction that owns it -- the tree's oldest recurring defect, "~20 call sites
  cited one byte past the instruction".  prom_c has notes/prom_c_audit_callsites.py
  and its 148 new citations came through clean; prom_b had no such tool and shipped
  the defect.  This is prom_b's.

  It is deliberately stricter than prom_c's in three ways, each of which is a
  defect the round-1 audit found or nearly found:

  1. THE OBJECT'S ADDRESS COMES FROM THE LINKER, NOT FROM A COMMENT.  prom_c's
     version reads the object address off the `; ADDR` comment on the first
     instruction line after the label.  That works for code and fails silently for
     DATA labels (`SongStore_DispatchA_1:` is followed by `.long`, which carries no
     address comment) -- exactly the labels F2 was about.  Here the address of every
     label is read from the symbol table of the ELF the gate builds
     (`llvm-nm rebuilt_ROMs/wsa1_prom_b.llvm.elf`), so it is the assembler's own
     answer and a comment cannot lie about it.
  2. IT SUGGESTS THE CORRECTION.  On a miss it decodes backwards up to 8 bytes and
     reports the instruction that CONTAINS the cited address, if that instruction
     names the object.  That is the fingerprint of the off-by-N defect, and it
     prints the address the header should have used.
  3. IT FOLLOWS THE THUNK TABLE.  prom_b routines are reached through the 0xF40000
     directory; a call to slot T_x that `jp`s to the object is a real call site and
     is reported OK (via thunk), not as a miss.

WHAT IT CHECKS AND WHAT IT DOES NOT
  CHECKED: that the cited address decodes (unidasm, MAME's decoder) to ONE
  instruction whose text names the object -- either a transfer (call/calr/jp/jr/jrl,
  possibly through a thunk slot) or a reference (any other instruction that spells
  the object's address, e.g. `ld XDE,0x00f7c6e6`).
  NOT CHECKED: that the site is reachable, that it executes, or that the decode's
  instruction boundary is the one the CPU sees -- unidasm is started AT the cited
  address, so a citation inside a longer instruction decodes as something, and only
  the backwards scan can show that.  Rows are therefore a list to READ.
  A citation in a `Calls:` line is a CALLEE, not a site, so `Calls:` is not parsed.

THE RESIDUE, AS OF 2026-08-25 (693 citations, 669 resolved, 24 not)
  Twenty-four rows print `??`.  All were read by hand and all are legitimate --
  they are the shapes this method cannot type-check, not errors in the .s.  The
  large class, 20 of the 24, is ONE shape:

    A CITATION OF THE CONSUMER.  A header may name the instruction that USES a
    table rather than the one that names its address -- `ld A,(XHL+IX)` at
    0xF5DC69 for the RoundMaps, `ld L,(XDE+HL)` at 0xF7CD74 for
    SongStore_StepSizeTable, `ld XIY,(XDE+HL)` at 0xF5DBA8 for RoundMap_Table.
    `ld A,(0x3629)` and `call T,XIX` at 0xF45E8C/0xF45E97 for Dispatch_3629.
    The consumer reaches the object through a register or a RAM pointer, so no
    operand of it spells the address and no test here can bind it.  In every case
    the SAME header also cites the address load, and that citation resolves.
    The seven RoundMaps have no direct citation at all, because nothing in the
    image names them individually: they are reached only through RoundMap_Table,
    and their headers say so.

  The other four:
    DLB_Handler_StringTable2  cited 0xF31B21 (x2) -- the OTHER opcode-02 handler,
        which jumps INTO this one at 0xF31B3C; the citation names that handler's
        entry point, and a decode at it is that handler's own first instruction.
    DisplayListB_ExtractField cited 0xF31DB1        -- interpreter B's handler
        TABLE.  Every entry `calr`s this routine, but the routine is not IN the
        table, so neither the transfer test nor the pointer test can see it.
    Zero9                     cited 0xF57D2D        -- an `ldir` that reads the
        object as DATA through XIY; no operand anywhere names the address.
    SongStore_StepSizeTable   cited 0xF7CD74        -- the indexed read
        `ld L,(XDE+HL)` that CONSUMES the table.  The address load, at 0xF7CD6F,
        is cited in the same header and resolves OK-ref.
  So 24 is the expected floor. A twenty-fifth row is a new claim to check, not
  noise -- and an OFF-BY row of any kind is never expected: there are ZERO in both
  modes as of 2026-08-25.

  With --evidence the residue is much larger and MEANS LESS: an `Evidence:` line
  cites the instructions that SUPPORT a claim, and most of them have no reason to
  name the object's address.  Use --evidence to look for OFF-BY rows; ignore its
  `??`.

RUN
  make -C .. all      (or scripts/analysis/assert_byte_identical.py -- this needs the ELF)
  python3 notes/prom_b_audit_callsites.py
  python3 notes/prom_b_audit_callsites.py --quiet    # only rows that did not check out
  python3 notes/prom_b_audit_callsites.py --selftest
Exit status is non-zero only for --selftest failures; the audit itself always
exits 0, because a miss can be legitimate.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_b.llvm.elf")
LLVM = os.environ.get("LLVM_BIN", "/home/fsanches/compartilhado/llvm-project/build/bin")
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")

A_BASE, B_BASE = 0xF80000, 0xF00000
TBL_LO, TBL_HI = 0xF40000, 0xF44018            # the prom_b thunk table

IMG = {"a": open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read(),
       "b": open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()}

ADDR = re.compile(r'0x([0-9A-Fa-f]{6})\b')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
# citation-bearing header keys.  `Calls:` is excluded on purpose: it names callees.
CITES = re.compile(r'^;\s*(Called from|Read by|Referenced by|Reached from|Written by):')
CITES_EV = re.compile(r'^;\s*(Called from|Read by|Referenced by|Reached from|Written by|'
                      r'Evidence):')
STOPS = re.compile(r'^;\s*(Inputs|Outputs|Evidence|Unknown|Calls|Touches|Notes?|Layout|'
                   r'Extent|Entry count|What it does|Packet|Dispatch|Why the name)s?:')
ROW = re.compile(r'^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


def fetch(addr, n):
    if A_BASE <= addr < A_BASE + len(IMG["a"]):
        return IMG["a"][addr - A_BASE:addr - A_BASE + n]
    if B_BASE <= addr < B_BASE + len(IMG["b"]):
        return IMG["b"][addr - B_BASE:addr - B_BASE + n]
    return b""


def dis(addr, n=16):
    """[(addr, nbytes, text)] decoded linearly from `addr`."""
    blob = fetch(addr, n)
    if not blob:
        return []
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(blob)
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for line in out.splitlines():
        m = ROW.match(line)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return rows


def symbols():
    """{label: address} from the ELF the gate builds -- the assembler's own answer."""
    p = subprocess.run([os.path.join(LLVM, "llvm-nm"), ELF], capture_output=True, text=True)
    if p.returncode:
        sys.exit("llvm-nm failed on %s -- run `make all` first.\n%s" % (ELF, p.stderr))
    out = {}
    for line in p.stdout.splitlines():
        parts = line.split()
        if len(parts) == 3:
            out[parts[2]] = int(parts[0], 16)
    return out


def thunk_target(addr):
    """If `addr` is a `jp nnn` slot of the 0xF40000 table, its target; else None."""
    if not (TBL_LO <= addr < TBL_HI) or addr % 4:
        return None
    s = fetch(addr, 4)
    if len(s) == 4 and s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
        return s[1] | s[2] << 8 | s[3] << 16
    return None


_KEYS = CITES          # switched to CITES_EV by --evidence


def _indent(ln):
    """Column at which the comment TEXT starts, or None for a bare `;`."""
    m = re.match(r'^;(\s*)(\S)', ln)
    return None if not m else 1 + len(m.group(1))


IDENT = re.compile(r'[A-Za-z_][A-Za-z0-9_]{2,}')


def block_objects(lines, i, sym):
    """Every label NAME the comment block containing line i mentions.

    prom_b headers routinely document a family together --
    `; SC1_Service / SC1_TxFlush / SC1_Entry_F40F18_Ret / ... -- the module's
    public entry points` -- and then give one `Called from:` list covering all
    six, saying which address belongs to which.  A checker that binds the whole
    list to the first label reports the other five as misses; the first draft did,
    and produced 40-odd phantom rows in the SC1 module alone.  So the citation is
    checked against EVERY label the block names, and only fails if it resolves to
    none of them."""
    lo = i
    while lo > 0 and lines[lo - 1].startswith(";"):
        lo -= 1
    hi = i
    while hi + 1 < len(lines) and lines[hi + 1].startswith(";"):
        hi += 1
    names, tails = set(), set()
    for ln in lines[lo:hi + 1]:
        for w in IDENT.findall(ln):
            if w in sym:
                names.add(w)
            elif w.startswith("_"):
                tails.add(w)
    # `; SC1_Irq_Exit_3 / _3_Delayed / _3b / _3b_Delayed` abbreviates the family
    # after the first name.  Complete each tail against every '_'-boundary prefix
    # of a name already found.
    for t in tails:
        for n in list(names):
            parts = n.split("_")
            for k in range(1, len(parts) + 1):
                cand = "_".join(parts[:k]) + t
                if cand in sym:
                    names.add(cand)
    return names


def citations(sym=None):
    """[(label, key, cited_addr, srcline)] in file order.

    A citation block is the key line plus the lines that CONTINUE it, and this
    file's convention for a continuation is a deeper comment indent -- the
    operands of `; Read by:` are aligned under its text.  Stopping on anything
    else matters: `; Called from: the 15-entry table at 0xF31DB1` at 0xF31B21 is
    the first line of a 60-line BLOCK comment, and a parser that swallows to the
    next label attributes all sixty lines' addresses to one handler.  It did, in
    the first draft, and produced 60-odd phantom misses."""
    lines = open(SRC).read().splitlines()
    out, pending, i = [], [], 0
    while i < len(lines):
        ln = lines[i]
        if _KEYS.match(ln):
            key = _KEYS.match(ln).group(1)
            keyind = _indent(ln)
            sibs = block_objects(lines, i, sym) if sym else set()
            blk = [ln]
            for m in ADDR.findall(ln):
                pending.append((key, int(m, 16), i + 1, sibs))
            j = i + 1
            while j < len(lines) and lines[j].startswith(";"):
                ind = _indent(lines[j])
                if ind is None or ind <= keyind or STOPS.match(lines[j]):
                    break
                blk.append(lines[j])
                for m in ADDR.findall(lines[j]):
                    pending.append((key, int(m, 16), j + 1, sibs))
                j += 1
            # An address a header explicitly calls an OPERAND field is being cited
            # AS one; that is the corrected form of the F2 defect, not the defect.
            # Narrow on purpose: the word has to FOLLOW that address within 60
            # characters, which is the phrasing ("0xF7C6DA, which is that
            # instruction's OPERAND field"), so one mention cannot exempt a whole
            # header and the address the instruction is AT is not exempted; the
            # byte facts are still checked underneath.
            flat = " ".join(x.lstrip(";").strip() for x in blk)
            low = flat.lower()
            for k in range(len(pending)):
                if len(pending[k]) == 5:
                    continue                     # already flagged by an earlier block
                key_, a_, sl_, sb_ = pending[k]
                hit = any("operand" in low[m.end():m.end() + 60]
                          for m in re.finditer(re.escape("0x%06X" % a_), flat))
                pending[k] = (key_, a_, sl_, sb_, hit)
            i = j
            continue
        m = LABEL.match(ln)
        if m:
            for rec in pending:
                key, a, srcline, sibs = rec[:4]
                as_operand = rec[4] if len(rec) == 5 else False
                out.append((m.group(1), key, a, srcline, sibs, as_operand))
            pending = []
        elif ln.strip() and not ln.startswith(";") and pending and "\t" in ln:
            pending = []          # citations that never reached a label
        i += 1
    return out


def judge(obj, cited, end=None):
    """(verdict, detail) for one citation.  `end` is the object's extent, i.e. the
    next symbol's address, so that a transfer INTO the object -- a second entry
    point, which prom_b's SC1 vtable uses heavily -- is distinguished from a miss."""
    hexo = "%06x" % obj
    d = dis(cited)
    if not d:
        return "??", "<outside both images>"
    a0, n0, t0 = d[0]
    body = t0.lower()
    mnem = body.split()[0] if body.split() else ""
    transfer = mnem in ("call", "calr", "jp", "jr", "jrl")
    if hexo in body:
        return ("OK" if transfer else "OK-ref"), t0
    if transfer:
        # `0*` first: unidasm prints `ld XIX,0x00f4608a` with EIGHT hex digits,
        # and a bare 6-digit match reads "00f460" -- a different, wrong address.
        m = re.search(r'0x0*([0-9a-f]{6})\b', body)
        if m:
            direct = int(m.group(1), 16)
            tt = thunk_target(direct)
            if tt == obj:
                return "OK-thunk", "%s  -> slot 0x%s jp 0x%06x" % (t0, m.group(1), obj)
            if end and tt is not None and obj < tt < end:
                return "OK-thunk-inner", "%s -> slot jp 0x%06X, inside the object" % (t0, tt)
            if end and obj < direct < end:
                return "OK-inner", "%s  (enters the object at +%d)" % (t0, direct - obj)
    # a NON-transfer instruction that names an address inside the object
    if end:
        for m in re.finditer(r'0x0*([0-9a-f]{6})\b', body):
            v = int(m.group(1), 16)
            if obj < v < end:
                return "OK-ref-inner", "%s  (names object+%d)" % (t0, v - obj)
    # the off-by-N fingerprint: an instruction that STARTS earlier and covers `cited`
    for k in range(1, 9):
        back = dis(cited - k)
        if not back:
            continue
        ba, bn, bt = back[0]
        if ba + bn > cited and hexo in bt.lower():
            return "OFF-BY-%d" % k, "instruction is at 0x%06X: %s" % (ba, bt)
    # the cited address is INSIDE the object: a second entry point, or the address
    # a thunk slot names.  A pure address fact, and what several headers point at.
    if end and obj < cited < end:
        return "OK-within", "%s   (object+%d)" % (t0, cited - obj)
    # the cited instruction ENDS exactly where the object starts.  Three prom_b
    # headers cite that relation ("plus fall-through from 0xF5B05A, the last
    # instruction of SC1_TxFlush_Body").  Whether control really falls through is
    # a separate question and the detail says which: a `ret`/`reti` does not.
    for k in range(1, 9):
        back = dis(cited)
        if back and back[0][0] + back[0][1] == obj:
            m0 = back[0][2].split()[0].lower()
            return "OK-abut", ("%s  ends AT the object%s"
                               % (back[0][2],
                                  "; it is a %s, so this is not fall-through" % m0
                                  if m0 in ("ret", "reti", "retd") else ", i.e. falls through"))
        break
    # ⚠ ORDER MATTERS.  The two blocks below must stay AFTER the off-by-N scan.
    # The defect this tool exists for -- citing the OPERAND of `ld XDE,0x00f7c6e6`
    # instead of the instruction -- has, at the cited address, a 32-bit word that
    # IS the object's address, so a data check placed first calls it a legitimate
    # pointer and the tool goes blind to its own reason for existing.  It did, for
    # one revision; the selftest's negative control is what caught it.
    # the site may be DATA, not an instruction: a pointer field of a record, a
    # dispatch-table entry, or an interrupt vector.  Those are real references and
    # they are checkable -- the 32-bit word has to BE the object's address.
    w = fetch(cited, 4)
    if len(w) == 4 and int.from_bytes(w, "little") == obj:
        return "OK-data", "the 32-bit word at the cited address IS 0x%06X" % obj
    # a RECORD: the citation names the record's first byte and the pointer field
    # sits at a fixed offset inside it (interpreter B puts it at +7).  Byte
    # granular, window 32 = longer than the longest record in the image (17).
    rec = fetch(cited, 32)
    for k in range(len(rec) - 3):
        if int.from_bytes(rec[k:k + 4], "little") == obj:
            return "OK-ptr", "the 32-bit word at cited+%d IS 0x%06X" % (k, obj)
    # a TABLE: the citation names the table's base and the object is one entry.
    tbl = fetch(cited, 4 * 64)
    for k in range(len(tbl) // 4):
        if int.from_bytes(tbl[4 * k:4 * k + 4], "little") == obj:
            return "OK-table", "entry [%d] of the table at the cited address" % k
    return "??", t0


def _rank(v):
    return 0 if v.startswith("OK") else (1 if v.startswith("OFF-BY") else 2)


def best(cands, cited, extent):
    """The best verdict over every object the header block names."""
    out = None
    for o in cands:
        v, d = judge(o, cited, end=extent.get(o))
        if out is None or _rank(v) < _rank(out[0]):
            out = (v, d, o)
        if _rank(v) == 0:
            break
    return out


def selftest():
    fails = []

    def check(msg, got, want):
        ok = got == want
        print("  %-64s %-30s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
        if not ok:
            fails.append(msg)

    sym = symbols()
    # 1. the linker agrees with a known code label's own address comment
    check("BStore_AllocBlock is at 0xF7A4DB", "0x%06X" % sym["BStore_AllocBlock"], "0xF7A4DB")
    # 2. a DATA label -- the case prom_c's tool cannot address at all
    check("SongStore_DispatchA_1 is at 0xF7C6E6",
          "0x%06X" % sym["SongStore_DispatchA_1"], "0xF7C6E6")
    # 3. the positive control: the true instruction address verdicts OK-ref
    v, _ = judge(0xF7C6E6, 0xF7C6D9)
    check("0xF7C6D9 (the real `ld XDE`) verdicts OK-ref", v, "OK-ref")
    # 4. the NEGATIVE control: the round-1 defect must NOT pass
    v, d = judge(0xF7C6E6, 0xF7C6DA)
    check("0xF7C6DA (operand, the F2 defect) verdicts OFF-BY-1", v, "OFF-BY-1")
    check("  ...and it names the correct address", "0xF7C6D9" in d, True)
    # 5. a transfer control: T_F42880's slot jp is a real call target
    tt = thunk_target(0xF42880)
    check("thunk slot 0xF42880 is a jp", tt is not None, True)
    # 6. a slot that is not a jp must not be followed
    check("0xF42882 (mid-slot) is not a thunk", thunk_target(0xF42882), None)
    # 7. the parser must find at least the six dispatch tables' Read by: lines
    cits = citations(sym)
    n = len([c for c in cits if c[0].startswith("SongStore_Dispatch")])
    check("dispatch-table citations found", n >= 6, True)
    # 7c. the EIGHT-hex-digit immediate.  `ld XIX,0x00f4608a` must be read as
    #     0xF4608A, not as 0x00F460 -- which is what a bare `[0-9a-f]{6}` match
    #     gives, and it made ten WorkspaceDefaults citations look unresolvable.
    v, d = judge(0xF46074, 0xF44051, end=0xF46115)
    check("`ld XIX,0x00f4608a` resolves inside WorkspaceDefaults", v, "OK-ref-inner")
    check("  ...and names the right offset", "object+22" in d, True)
    # 7b. the operand-field rule must be NARROW: it exempts only an address the
    #     text calls an operand, and only near that word.
    cits_ = citations(sym)
    flags = {(c[0], c[2]): c[5] for c in cits_}
    check("SongStore_DispatchA_1's 0xF7C6DA is flagged as an operand field",
          flags.get(("SongStore_DispatchA_1", 0xF7C6DA)), True)
    check("...while its 0xF7C6D9 (the instruction) is NOT flagged",
          flags.get(("SongStore_DispatchA_1", 0xF7C6D9), False), False)
    check("...and no address in SongStore_StepSizeTable's block is flagged",
          [k for k, v in flags.items() if v and k[0] == "SongStore_StepSizeTable"], [])
    # 8. THE ORDERING INVARIANT, checked structurally.  Two revisions of this file
    #    put a permissive verdict ahead of the off-by-N scan and went blind to the
    #    defect the tool exists for; the negative control above caught it once, but
    #    only because that control's object happens to sit outside every window.
    import inspect
    src = inspect.getsource(judge)
    pos = {k: src.find(k) for k in ('"OFF-BY-%d"', '"OK-within"', '"OK-abut"',
                                    '"OK-data"', '"OK-ptr"', '"OK-table"')}
    check("the off-by-N scan precedes every permissive verdict",
          all(pos['"OFF-BY-%d"'] < v for k, v in pos.items() if k != '"OFF-BY-%d"'),
          True)
    print("\n%d self-check(s) failed" % len(fails))
    return 1 if fails else 0


def main():
    global _KEYS
    if "--evidence" in sys.argv:
        _KEYS = CITES_EV        # also audit the addresses cited on `Evidence:` lines
    if "--selftest" in sys.argv:
        return selftest()
    quiet = "--quiet" in sys.argv
    sym = symbols()
    addrs = sorted(set(sym.values()))
    extent = {a: (addrs[i + 1] if i + 1 < len(addrs) else a + 0x40)
              for i, a in enumerate(addrs)}
    cits = citations(sym)
    counts, missing = {}, 0
    unresolved = []
    for label, key, a, srcline, sibs, as_operand in cits:
        if label not in sym:
            unresolved.append((label, srcline))
            continue
        obj = sym[label]
        cands = [obj] + sorted(sym[n] for n in sibs if sym[n] != obj)
        if a in cands:
            continue                       # a header citing one of its own addresses
        v, d, obj = best(cands, a, extent)
        if as_operand and v.startswith("OFF-BY"):
            v = "OK-operand"        # the header names it as an operand field, and it is
        who = label if obj == sym[label] else \
            next(n for n in ([label] + sorted(sibs)) if sym.get(n) == obj)
        counts[v] = counts.get(v, 0) + 1
        if v.startswith("OK"):
            if quiet:
                continue
        else:
            missing += 1
        print("%-40s 0x%06X  %-14s cited 0x%06X (line %5d)  %-9s %s"
              % (who, obj, key, a, srcline, v, d))
    print("\n%d citation(s) checked over %d label(s)" % (sum(counts.values()), len(sym)))
    for k in sorted(counts):
        print("   %-10s %d" % (k, counts[k]))
    print("%d did not resolve to the object." % missing)
    if unresolved:
        print("%d citation block(s) whose label is not in the symbol table "
              "(macro-generated or renamed):" % len(unresolved))
        for lab, srcline in unresolved[:20]:
            print("   %-40s line %d" % (lab, srcline))
    return 0


if __name__ == "__main__":
    sys.exit(main())
