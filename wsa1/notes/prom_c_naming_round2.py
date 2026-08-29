#!/usr/bin/env python3
"""Which prom_c `sub_XXXXXX` routines carry enough evidence to be NAMED, and which do not?

QUESTION IT ANSWERS
  prom_c is territorially complete -- zero `.incbin` -- so the work left in it is
  MEANING.  At the start of wave 7 round 2, 539 of its routines were called nothing but
  their own address; this round named 15 of them, so `--census` now reports 524.  (Both
  figures are `grep -cE '^sub_[0-9A-Fa-f]{6}:' prom_c/wsa1_prom_c.s`, and --selftest
  asserts the census agrees with that grep, so neither can go stale silently.)

  Naming one is cheap and the byte gate is blind to it, so the only defence against a
  confidently wrong name is to grade the evidence FIRST and name only where the grade
  carries it.  This script produces that grade, mechanically, from the tree and the
  ROM -- never from a prose paragraph, and then it carries the round's rename table and
  re-derives every number the round wrote into a header.

  One question per mode:

  --census  "For every sub_XXXXXX in prom_c, what evidence exists?"  Six signals, each
            derived and each printed with its own denominator:

              CALLERS  how many places reference the symbol, split into CALL-shaped
                       (call/calr/jp/jrl/jr) and OTHER (a data word, an `ld` operand).
                       ⚠ A reference is a reference in the ASSEMBLY SOURCE, which is
                       what assembles to the ROM, so it is exact -- but a `.long` in a
                       dispatch table is not a call and is counted separately.
              NAMEDCALLERS  of those, how many sit inside a routine that already has a
                       semantic name.  This is the signal that actually carries a name:
                       a routine called only by `Link_Receive_Dispatch` is a link
                       routine whatever else is unknown.
              CALLEES  named (non-sub_, non-loc_) routines this body calls.  The
                       strongest single signal in this tree, because prom_c's named
                       leaf routines are peripheral drivers.
              DEV      device windows the body addresses as a literal, matched against
                       notes/FINDINGS-memory-map.md's windows (see DEVICES below).
              SFR      TMP95C061 special-function registers named in the body, from
                       include/tmp95c061_sfr.inc -- the `.inc` is the authority, not a
                       list retyped here.
              KERNEL   whether the routine falls inside the 0xF9816B-0xF989EE block
                       that prom_a and prom_c share (notes/prom_c_kernel_map.py).

            The score is the SUM of those weighted counts and it is a RANKING DEVICE
            ONLY.  A high score is a claim that evidence exists, never a claim about
            what the routine does.

  --show S  everything the census knows about one symbol, plus the body, so the
            ranking can be checked by reading rather than trusted.

  --sibling "Is any sub_XXXXXX byte-identical to a NAMED KN5000 sub-CPU routine?"
            Matches this tree's ROM bytes against the KN5000 sub-CPU ELF's own
            unspliced image (addr = 0x400 + offset; NEVER the spliced .rom -- see the
            retraction in scripts/analysis/transplant_kn5000_labels.py) and prints the
            DIFFERING BYTE COUNT for every candidate, because "identical" with no count
            is the exact shape of an error this tree has already published.

DEVICES
  The windows come from notes/FINDINGS-memory-map.md and are listed in DEVICE_WINDOWS
  below with the finding that establishes each.  A literal inside a window is evidence
  that the routine addresses that device; it is NOT evidence of what the register means.

WHAT THIS CANNOT DO
  * It cannot see a reference made through a pointer register loaded far away, and it
    cannot see one made from prom_a or prom_b.  A CALLERS count is a count of
    references VISIBLE IN prom_c's OWN SOURCE and must be quoted that way.
  * A score is not a meaning.  Every name this script motivates still needs a human to
    read the body and write an Evidence: line that cites an instruction address.

  --names   the rename table this round shipped, each with its one-line evidence.
  --apply   perform those renames in prom_c/wsa1_prom_c.s.  Idempotent; refuses if a
            source symbol is missing or a target name already exists; renames the
            `__local` labels with the routine (the regex note in rename_token is the
            reason a naive \b rename would break the build).  The FULL evidence for
            each name is the routine header the same commit writes into the .s.
  --check-applied  say which of them are in the tree, writing nothing.
  --claims  re-derive, from the ROM bytes or from a second tool, EVERY number this
            round wrote into a routine header.  This is the answer to "a claim whose
            evidence lives only in prose is a claim nobody can check".

RUN
  python3 notes/prom_c_naming_round2.py --census [--top N] [--min-score N]
  python3 notes/prom_c_naming_round2.py --names
  python3 notes/prom_c_naming_round2.py --apply
  python3 notes/prom_c_naming_round2.py --show sub_F9A86B
  python3 notes/prom_c_naming_round2.py --sibling [--minlen N]
  python3 notes/prom_c_naming_round2.py --selftest
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_c.llvm.elf")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
SFR_INC = os.path.join(ROOT, "include", "tmp95c061_sfr.inc")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")
BASE = 0xF80000

SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
SIB_ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
SIB_LINK_BASE = 0x0400

# The prom_a/prom_c shared kernel block.  Bounds from notes/prom_c_kernel_map.py's
# own BLOCK constant and from the block banner in prom_c/wsa1_prom_c.s.
KERNEL_LO, KERNEL_HI = 0xF9816B, 0xF989EE

# Device windows.  Each is a (lo, hi, tag, where-it-is-established) row; the
# provenance column is why this table is not a guess retyped into a script.
DEVICE_WINDOWS = [
    (0x00E00000, 0x00E0FFFF, "DSP",
     "notes/FINDINGS-prom_c-tone-generator.md: prom_c's DSP channel-register base "
     "(0xF980A5 loads it; the KN5000 sibling loads 0x00130000 at the same byte)"),
    (0x0010C000, 0x0010CFFF, "DEV10C",
     "notes/FINDINGS-prom_c-dev10c-producers.md / -register-meanings.md"),
    (0x00120000, 0x0012FFFF, "DEV120",
     "notes/FINDINGS-memory-map.md"),
]

CALL_MNEMONICS = {"call", "calr", "jp", "jrl", "jr", "djnz", "djnz8", "ret", "reti"}
# Mnemonics that make a symbol operand a CONTROL TRANSFER.  `ret`/`reti` never take a
# symbol; they are in the set only so a typo in the parser shows up as a zero column
# rather than as silence.


def sh(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


# ---------------------------------------------------------------- source parsing

LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
SUB_RE = re.compile(r'^(sub_[0-9A-Fa-f]{6}):')


def load_source():
    return open(SRC, encoding="utf-8", errors="replace").read().splitlines()


def strip_comment(line):
    """Drop the trailing `;` comment.  prom_c has no `;` inside a string operand that
    matters here -- .ascii lines are data and carry no symbol operands -- but a
    semicolon inside quotes is guarded for anyway."""
    out, inq = [], False
    for ch in line:
        if ch == '"':
            inq = not inq
        if ch == ';' and not inq:
            break
        out.append(ch)
    return ''.join(out)


def top_level_labels(lines):
    """[(index, name)] for every label defined in column 0, in file order.

    A '__'-containing name is a LOCAL label of the routine before it (this tree spells
    them `sub_F9A86B__F9A8FF` and `Foo__loop`), so it does not open a new routine."""
    out = []
    for i, l in enumerate(lines):
        m = LABEL_RE.match(l)
        if m and '__' not in m.group(1):
            out.append((i, m.group(1)))
    return out


def symbol_addresses():
    """name -> address, from the BUILT ELF.  The assembler's own answer, so a label
    cannot drift away from the address its name spells."""
    out = {}
    for line in sh([NM, "--numeric-sort", "--defined-only", ELF]).splitlines():
        p = line.split()
        if len(p) != 3:
            continue
        addr, typ, name = p
        if typ.lower() == 'a':          # .equ absolute (SFRs), not an image address
            continue
        out[name] = int(addr, 16)
    return out


def sfr_names():
    """The SFR name set, read from the .inc that the build actually includes."""
    names = set()
    for line in open(SFR_INC, encoding="utf-8", errors="replace"):
        m = re.match(r'\s*\.equ\s+([A-Za-z_][A-Za-z0-9_]*)\s*,', line)
        if m:
            names.add(m.group(1))
    return names


class Tree:
    def __init__(self):
        self.lines = load_source()
        self.tops = top_level_labels(self.lines)
        self.addr = symbol_addresses()
        self.sfrs = sfr_names()
        self.defined = {n for _, n in self.tops}
        # every label, including locals, so an operand can be classified
        self.all_labels = set()
        for l in self.lines:
            m = LABEL_RE.match(l)
            if m:
                self.all_labels.add(m.group(1))
        # routine bodies: name -> (start_line, end_line_exclusive)
        self.body = {}
        for k, (i, n) in enumerate(self.tops):
            end = self.tops[k + 1][0] if k + 1 < len(self.tops) else len(self.lines)
            self.body[n] = (i + 1, end)
        self.subs = [n for _, n in self.tops if SUB_RE.match(n + ':')]
        # owner of every line: which top-level routine encloses it
        self.owner = [None] * len(self.lines)
        for k, (i, n) in enumerate(self.tops):
            end = self.tops[k + 1][0] if k + 1 < len(self.tops) else len(self.lines)
            for j in range(i, end):
                self.owner[j] = n

        # addresses of TOP-LEVEL labels only, sorted -- the span of a routine runs to
        # the next one of these, never to one of its own `__` local labels.
        self.top_addrs = sorted({self.addr[n] for _, n in self.tops if n in self.addr})
        # address -> the top-level symbol that starts there (for resolving a literal)
        self.by_addr = {}
        for _, n in self.tops:
            if n in self.addr:
                self.by_addr.setdefault(self.addr[n], n)
        # address -> ANY label starting there, locals included
        self.any_by_addr = {}
        for n, a in self.addr.items():
            self.any_by_addr.setdefault(a, []).append(n)

    def sub_addr(self, name):
        if name in self.addr:
            return self.addr[name]
        return int(name[4:], 16)     # the name spells it; nm is the cross-check

    def sub_len(self, name):
        """Distance to the next TOP-LEVEL label.  This is a SPAN, not a proven routine
        length: if the next top-level label is data the span includes it.  Quoted so."""
        a = self.sub_addr(name)
        nxt = [v for v in self.top_addrs if v > a]
        return (min(nxt) - a) if nxt else 0

    def owner_of_addr(self, a):
        """Which top-level routine contains address `a`?"""
        lo = None
        for v in self.top_addrs:
            if v <= a:
                lo = v
            else:
                break
        return self.by_addr.get(lo) if lo is not None else None


def scan_references(tree):
    """symbol -> list of (line_index, owner, kind).  kind in {'call','data','operand'}.

    ⚠ THE POINT OF THIS FUNCTION.  prom_c's converted blocks spell a control transfer
    with a LITERAL, not with the callee's symbol: `call 0xFCAA2F`, and
    `calr (0xF9A31A - 0xF9A874)` for the PC-relative form.  A scanner that looks for the
    string `sub_FCAA2F` therefore finds almost nothing and reports every routine as
    uncalled -- which is the shape of the "no references" error already recorded in
    HANDOFF-RESUME-HERE.md.  So references are resolved by ADDRESS: every hex literal
    in the code half of a line is looked up in the ELF's symbol table, and a hit on a
    routine's entry address is a reference to that routine.

    A `calr (X - Y)` line contributes X (the target) and Y (the return address, which
    is NOT a reference); Y is discarded because it never equals a top-level entry --
    it is the address of the instruction AFTER the calr.  Any Y that did coincide with
    an entry would be counted, and the --show body listing is how that is caught.
    """
    want = set(tree.subs)
    want_addr = {tree.sub_addr(s): s for s in want}
    refs = {s: [] for s in want}
    hexre = re.compile(r'0x([0-9A-Fa-f]{4,8})\b')
    RELEXPR_RE = re.compile(r'\(\s*0x([0-9A-Fa-f]+)\s*-\s*0x([0-9A-Fa-f]+)\s*\)')
    symre = re.compile(r'\b(sub_[0-9A-Fa-f]{6})\b')
    for i, raw in enumerate(tree.lines):
        if raw.startswith(';'):
            continue
        code = strip_comment(raw)
        if not code.strip():
            continue
        m = LABEL_RE.match(code)
        deflabel = m.group(1) if m else None
        rest = code[m.end():] if m else code
        toks = rest.split()
        mn = toks[0].lower().rstrip(',') if toks else ''
        # `calr (TARGET - RETURN)` / `jrl (TARGET - HERE)`: only the MINUEND is a
        # reference.  The subtrahend is the address of the next instruction and would
        # otherwise be counted as a call to whatever happens to start there.
        rel = RELEXPR_RE.findall(rest)
        if rel:
            cand = [int(a, 16) for a, _ in rel]
            sub_out = {int(b, 16) for _, b in rel}
        else:
            cand = [int(h, 16) for h in hexre.findall(rest)]
            sub_out = set()
        hits = set()
        for v in cand:
            if v in want_addr and v not in sub_out:
                hits.add(want_addr[v])
        for n in symre.findall(rest):
            if n in want:
                hits.add(n)
        owner = tree.owner[i]
        for name in hits:
            if name == deflabel:
                continue
            if name == owner:
                continue          # a routine's own backward jump is not a call site
            if mn.startswith('.'):
                kind = 'data'
            elif mn in CALL_MNEMONICS:
                kind = 'call'
            else:
                kind = 'operand'
            refs[name].append((i, owner, kind))
    return refs


def named(n):
    return not (n is None or n.startswith('sub_') or n.startswith('loc_'))


def body_facts(tree, name):
    """What the body of `name` mentions: named callees, device hits, SFRs, hex literals.

    Callees are resolved BY ADDRESS as well as by symbol, for the reason spelled out in
    scan_references: prom_c writes `call 0xFCAA2F`, not `call Shift16_ArithRight`."""
    lo, hi = tree.body[name]
    callees, devices, sfrs, lits = set(), set(), set(), set()
    for i in range(lo, hi):
        raw = tree.lines[i]
        if raw.startswith(';'):
            continue
        code = strip_comment(raw)
        if not code.strip():
            continue
        m = LABEL_RE.match(code)
        rest = code[m.end():] if m else code
        for w in re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', rest):
            if w in tree.sfrs:
                sfrs.add(w)
            elif w in tree.all_labels and named(w) and '__' not in w and w != name:
                callees.add(w)
        for h in re.findall(r'0x([0-9A-Fa-f]{4,8})\b', rest):
            v = int(h, 16)
            lits.add(v)
            sym = tree.by_addr.get(v)
            if sym and named(sym) and sym != name:
                callees.add(sym)
            for dlo, dhi, tag, _ in DEVICE_WINDOWS:
                if dlo <= v <= dhi:
                    devices.add(tag)
    return callees, devices, sfrs, lits


def census(tree):
    refs = scan_references(tree)
    rows = []
    for s in tree.subs:
        r = refs[s]
        calls = [x for x in r if x[2] == 'call']
        data = [x for x in r if x[2] == 'data']
        oper = [x for x in r if x[2] == 'operand']
        ncall = sorted({x[1] for x in calls if named(x[1])})
        callees, devices, sfrs, lits = body_facts(tree, s)
        a = tree.sub_addr(s)
        kern = KERNEL_LO <= a <= KERNEL_HI
        score = (4 * len(ncall) + 2 * len(calls) + 3 * len(callees)
                 + 3 * len(devices) + 1 * len(sfrs) + 5 * (1 if kern else 0))
        rows.append(dict(sym=s, addr=a, span=tree.sub_len(s), score=score,
                         calls=len(calls), data=len(data), oper=len(oper),
                         named_callers=ncall, callees=sorted(callees),
                         devices=sorted(devices), sfrs=sorted(sfrs), kernel=kern))
    rows.sort(key=lambda d: (-d['score'], d['addr']))
    return rows


# ---------------------------------------------------------------- sibling identity

def sibling_image():
    tmp = "/tmp/kn5000_v142_full_naming_round2.bin"
    subprocess.run([OBJCOPY, "-O", "binary", SIB_ELF, tmp], check=True)
    return open(tmp, "rb").read()


def sibling_symbols():
    out = []
    for line in sh([NM, "--numeric-sort", "--defined-only", SIB_ELF]).splitlines():
        p = line.split()
        if len(p) != 3:
            continue
        addr, typ, nm_ = p
        if typ.lower() == 'a' or nm_.startswith('.L') or nm_.startswith('$'):
            continue
        out.append((int(addr, 16), nm_))
    return sorted(out)


def sibling_scan(tree, minlen=48, anchor=8):
    """For each sub_XXXXXX, is there a KN5000 sub-CPU run whose bytes match?

    ⚠ POSITIVE CONTROL FIRST.  A matcher that finds nothing is indistinguishable from a
    matcher that is broken, and this tree has already published one "no references"
    that was a broken search.  So the scan always also runs the KNOWN-GOOD case --
    prom_c 0xF9806D `DSP_WriteAllChannelRegs`, which the transplant table and
    notes/prom_c_sibling_map.py both place at KN5000 0x1FCFB -- and reports whether it
    was found.  If the control fails, the zero means nothing.

    The differing count is ALWAYS printed for a hit.  A row with diff>0 is not a
    transplant candidate; it is printed so the near-miss is visible rather than hidden.
    """
    rom = open(ROM, "rb").read()
    sib = sibling_image()
    syms = sibling_symbols()
    by_addr = {a: n for a, n in syms}

    ctrl_off = 0xF9806D - BASE
    ctrl_pos = sib.find(rom[ctrl_off:ctrl_off + anchor])
    control = (ctrl_pos >= 0, SIB_LINK_BASE + ctrl_pos if ctrl_pos >= 0 else None)

    rows = []
    for s in tree.subs:
        a, span = tree.sub_addr(s), tree.sub_len(s)
        if span < minlen:
            continue
        off = a - BASE
        ours = rom[off:off + span]
        if len(ours) < span:
            continue
        pos = sib.find(ours[:anchor])
        if pos < 0:
            continue
        sibaddr = SIB_LINK_BASE + pos
        theirs = sib[pos:pos + span]
        diff = sum(1 for x, y in zip(ours, theirs) if x != y) + abs(span - len(theirs))
        rows.append((s, a, span, sibaddr, by_addr.get(sibaddr), diff))
    return rows, control, sum(1 for s in tree.subs if tree.sub_len(s) >= minlen)


def data_reference_census(tree):
    """How many sub_XXXXXX entry addresses occur as a 32-bit LITTLE-ENDIAN word anywhere
    in the prom_c ROM?  This is the question "is any of them in a dispatch TABLE rather
    than at a call instruction", asked of the bytes and not of the assembly text, so it
    is independent of how the source spells things."""
    rom = open(ROM, "rb").read()
    hits = []
    for s in tree.subs:
        pat = tree.sub_addr(s).to_bytes(4, "little")
        if rom.find(pat) >= 0:
            hits.append(s)
    return hits, len(tree.subs)


# ---------------------------------------------------------------- the renames
#
# THE TABLE THIS ROUND SHIPS.  Each row is (old, new, one-line evidence).  The full
# evidence for every one is the routine header written into prom_c/wsa1_prom_c.s; the
# line here is the SHORT form, so that `--names` and the header cannot drift apart
# without one of them looking wrong.  A name is in this table only if the mechanism is
# provable from the bytes; everything whose PURPOSE is still open kept its address.
RENAMES = [
    # --- the 0x0010C000 six-register commit and the five routines that stage it ---
    ("sub_FB7345", "Dev10C_WriteSixChanRegs_FromD78A",
     "six select/data pairs to 0x0010C000: register arg0+{0x800,0x840,0x900,0x940,"
     "0x9C0,0xA00} <- struct+{0x2C,0x2E,0x30,0x32,0x34,0x36}; reproduced independently "
     "by notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs"),
    ("sub_FAB818", "Dev10C_StageRegs_0800_0840_FAB818",
     "absolute stores to 0x00D78A/0x00D78C at 0xFAB855/0xFAB869"),
    ("sub_FAB8CC", "Dev10C_StageRegs_0800_0840_FAB8CC",
     "absolute stores to 0x00D78A/0x00D78C at 0xFAB9C8/0xFAB9CD"),
    ("sub_FAB9D8", "Dev10C_StageRegs_0800_0840_FAB9D8",
     "absolute stores to 0x00D78A/0x00D78C at 0xFABAD3/0xFABAD8"),
    ("sub_FABAE3", "Dev10C_StageRegs_0900_0940",
     "absolute stores to 0x00D78E/0x00D790 at 0xFABBEA/0xFABBEF; sole producer of "
     "that pair"),
    ("sub_FABBFB", "Dev10C_StageRegs_09C0_0A00",
     "absolute stores to 0x00D792/0x00D794 at 0xFABCE7/0xFABCEC; sole producer of "
     "that pair"),

    # --- byte-stream operand readers and one fixed-point conversion ---
    ("sub_F9E020", "Stream_ReadU24BE",
     "three `ld A,(XBC)` separated by `inc 1,XBC`, shifted 16/8/0 and summed, stored "
     "through (XIZ+0x0C); the advanced cursor is written back and returned in XIY"),
    ("sub_F9DFB7", "Stream_ReadU24BE_Shl8",
     "same three-byte cursor read, shifted 24/16/8 -- Shift32_Left(b0,24) at 0xF9DFC8 "
     "then `and XIY,0xFF000000`"),
    ("sub_F9E077", "Int32_ToFloat32_Q31",
     "Int32_ToFloat32(arg)/Int32_ToFloat32(0x8000) then /Int32_ToFloat32(0x10000); "
     "0x8000 * 0x10000 = 2**31"),

    # --- arithmetic helpers ---
    ("sub_FC412E", "Multiply16_Signed_Shr11",
     "the whole 18-byte body is `ld BC,(XIZ+0x08) / muls XBC,(XIZ+0x0a) / sra 0x0b,XBC "
     "/ ld WA,BC`"),
    ("sub_FBD88E", "Clamp_ToRange_LowByte_FBD88E",
     "same three-way compare as Clamp_ToRange_LowByte (0xFA7EE2) but a SEPARATE "
     "compilation: 36 of 42 bytes differ and the lengths differ, 42 against 34"),
    ("sub_FBD8B8", "ByteField_AddOrSub_Clamped",
     "two byte tables at 0xFDE6A1 = 01 04 10 40 02 08 20 80 and 0xFDE6A5 gate and "
     "sign a delta, then the clamped result is masked back into *(XIZ+0x10)"),
    ("sub_FAD5C2", "Scale7Bit_ByDepth_UniOrBipolar",
     "bit 7 of record byte +1 selects `(v<<5)/0x7F` from `((v<<5)-0x800)/63 or /64`; "
     "record byte +2 multiplies and the product is `sra 6`"),
    ("sub_FA766C", "ScaleClampedDelta_Shr5",
     "`and DE,0x7F00 / srl 8` takes bits 14..8, clamps to [(XIZ+0x0C),(XIZ+0x0E)], "
     "subtracts (XIZ+0x0A), `muls` by (XIZ+0x10) and `sra 5`"),
    ("sub_FAF340", "PartRec_ResetSlotValues_ByTag",
     "six 6-byte records; where (rec+1)&0x3F or (rec+4)&0x3F equals (XIZ+0x0C) and the "
     "slot index differs from (XIZ+0x0A), writes 0x40 at 0x1523 + part*0x12C + 0x76/0x77 "
     "+ 2*slot"),
]


def do_names():
    print(f"{len(RENAMES)} renames in this round's table\n")
    for old, new, ev in RENAMES:
        print(f"  {old:<12} -> {new}")
        print(f"      {ev}")
    return 0


def rename_token(text, old, new):
    """Rewrite the identifier `old` and every `old__local` derived from it.

    `\bold\b` does NOT match inside `sub_FB7345__FB7350` (the `_` is a word
    character, so there is no boundary after the digits), which would leave the local
    labels pointing at a symbol that no longer exists and break the build.  The
    negative lookahead below accepts `_` as a following character and so renames the
    locals too, while still refusing a longer address like `sub_FB73450`."""
    return re.sub(r'\b' + old + r'(?![0-9A-Za-z])', new, text)


def do_apply(check_only=False):
    """Rewrite prom_c/wsa1_prom_c.s.  Idempotent, and refuses on any surprise."""
    text = open(SRC, encoding="utf-8").read()
    todo, done, bad = [], [], []
    for old, new, _ev in RENAMES:
        has_old = re.search(r'^' + old + r':', text, re.M) is not None
        has_new = re.search(r'^' + new + r':', text, re.M) is not None
        if has_new and not has_old:
            done.append((old, new))
        elif has_old and not has_new:
            todo.append((old, new))
        else:
            bad.append((old, new, has_old, has_new))
    for old, new, ho, hn in bad:
        print(f"  REFUSE {old} -> {new}: old present {ho}, new present {hn}")
    if bad:
        print("\nnothing written.")
        return 1
    for old, new in done:
        print(f"  already applied: {old} -> {new}")
    if check_only:
        print(f"\n{len(done)} applied, {len(todo)} pending.")
        return 0 if not todo else 2
    for old, new in todo:
        n_before = len(re.findall(r'\b' + old + r'(?![0-9A-Za-z])', text))
        text = rename_token(text, old, new)
        n_after = len(re.findall(r'\b' + old + r'(?![0-9A-Za-z])', text))
        print(f"  {old} -> {new}   ({n_before} occurrence(s), {n_after} left)")
        if n_after:
            print("  REFUSE: occurrences survived the rewrite; nothing written.")
            return 1
    if todo:
        open(SRC, "w", encoding="utf-8").write(text)
        print(f"\nwrote {SRC}: {len(todo)} rename(s).")
        print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    else:
        print("\nnothing to do.")
    return 0


# ------------------------------------------------------- the claims the headers make
#
# Every NUMBER that this round wrote into a routine header is re-derived here, from the
# ROM bytes or from a second tool, so that a reader can check the header without
# trusting it.  `--claims` runs them all and `--selftest` runs `--claims` too.
# Each entry is (label, callable -> (ok, detail)).

# The six words 0x00D78A..0x00D795 and the five routines that produce them.
STAGING_TAIL = [0x00D78A, 0x00D78C, 0x00D78E, 0x00D790, 0x00D792, 0x00D794]
STAGING_TAIL_PRODUCERS = {
    0x00D78A: {"Dev10C_StageRegs_0800_0840_FAB818", "Dev10C_StageRegs_0800_0840_FAB8CC",
               "Dev10C_StageRegs_0800_0840_FAB9D8"},
    0x00D78C: {"Dev10C_StageRegs_0800_0840_FAB818", "Dev10C_StageRegs_0800_0840_FAB8CC",
               "Dev10C_StageRegs_0800_0840_FAB9D8"},
    0x00D78E: {"Dev10C_StageRegs_0900_0940"},
    0x00D790: {"Dev10C_StageRegs_0900_0940"},
    0x00D792: {"Dev10C_StageRegs_09C0_0A00"},
    0x00D794: {"Dev10C_StageRegs_09C0_0A00"},
}
# The register/word map Dev10C_WriteSixChanRegs_FromD78A implements, as the header
# states it.  prom_c_tg_chanmap.py is asked to reproduce it from the ROM.
FB7345_MAP = [(0x0840, 0x2E), (0x0A00, 0x36), (0x0800, 0x2C),
              (0x09C0, 0x34), (0x0940, 0x32), (0x0900, 0x30)]
MAME_SHIFT_LINE = os.path.expanduser(
    "~/compartilhado/mame/src/devices/cpu/tlcs900/900tbl.hxx")


def _rom():
    return open(ROM, "rb").read()


def claim_fc412e():
    """The 18 ROM bytes Multiply16_Signed_Shr11's header quotes."""
    want = "ee0c00009e08219e0a49e9ed0bd988ee0d0e"
    got = _rom()[0xFC412E - BASE:0xFC412E - BASE + 18].hex()
    return got == want, got


def claim_bitmask_tables():
    """ByteField_AddOrSub_Clamped's two byte tables, and that they are 1<<2i / 1<<(2i+1)."""
    rom = _rom()
    tbl = rom[0xFDE695 - BASE:0xFDE695 - BASE + 20]
    a = rom[0xFDE6A1 - BASE:0xFDE6A1 - BASE + 8]
    b = rom[0xFDE6A5 - BASE:0xFDE6A5 - BASE + 4]
    ok = (list(a) == [0x01, 0x04, 0x10, 0x40, 0x02, 0x08, 0x20, 0x80]
          and list(b) == [0x02, 0x08, 0x20, 0x80]
          and all(a[i] == 1 << (2 * i) for i in range(4))
          and all(b[i] == 1 << (2 * i + 1) for i in range(4))
          and len(tbl) == 20)
    return ok, f"0xFDE6A1={a.hex()} 0xFDE6A5={b.hex()}"


def claim_clamp_diff():
    """Clamp_ToRange_LowByte_FBD88E: 42 bytes against 0xFA7EE2's 34, 36 differing."""
    rom = _rom()
    a = rom[0xFBD88E - BASE:0xFBD88E - BASE + 42]
    b = rom[0xFA7EE2 - BASE:0xFA7EE2 - BASE + 42]
    diff = sum(1 for x, y in zip(a, b) if x != y)
    tree = Tree()
    la = tree.sub_len("Clamp_ToRange_LowByte_FBD88E")
    lb = tree.sub_len("Clamp_ToRange_LowByte")
    return (diff == 36 and la == 42 and lb == 34), f"diff {diff}/42, spans {la} and {lb}"


def claim_staging_tail():
    """Six words, their producers, and that prom_c contains no absolute LOAD of them.

    The FIRST and the LAST word are both checked -- the whole list is, one row each --
    because a producer census that only proved its first row is how this tree has been
    wrong before."""
    tree = Tree()
    st = re.compile(r'^\s*st[a-z0-9]*_da\s*\(0x([0-9A-Fa-f]{4,6})\)')
    ld = re.compile(r'^\s*ld[a-z0-9]*_da\s+[a-z]+\s*,\s*\(0x([0-9A-Fa-f]{4,6})\)')
    stores, loads = {a: set() for a in STAGING_TAIL}, {a: set() for a in STAGING_TAIL}
    for i, raw in enumerate(tree.lines):
        if raw.startswith(';'):
            continue
        code = strip_comment(raw)
        m = st.match(code)
        if m and int(m.group(1), 16) in stores:
            stores[int(m.group(1), 16)].add(tree.owner[i])
        m = ld.match(code)
        if m and int(m.group(1), 16) in loads:
            loads[int(m.group(1), 16)].add(tree.owner[i])
    bad = []
    for a in STAGING_TAIL:
        if stores[a] != STAGING_TAIL_PRODUCERS[a]:
            bad.append(f"0x{a:04X} producers {sorted(stores[a])}")
        if loads[a]:
            bad.append(f"0x{a:04X} HAS an absolute load: {sorted(loads[a])}")
    return not bad, ("; ".join(bad) if bad else
                     f"{len(STAGING_TAIL)} words, producers as documented, no absolute load")


def claim_fb7345_map():
    """Ask notes/prom_c_tg_chanmap.py to reproduce the six register/word pairs."""
    tool = os.path.join(ROOT, "notes", "prom_c_tg_chanmap.py")
    out = subprocess.run([sys.executable, tool, "0xFB7345", "0xAB", "--pairs"],
                         capture_output=True, text=True, cwd=ROOT).stdout
    got = [(int(m.group(1), 16), int(m.group(2), 16)) for m in
           re.finditer(r'register arg0 \+ 0x([0-9A-Fa-f]{4})\s+<- struct\+0x([0-9A-Fa-f]{2})',
                       out)]
    return got == FB7345_MAP, f"{len(got)} pair(s): {[(hex(a), hex(b)) for a, b in got]}"


def claim_mame_shift16():
    """The line the sll-0 = shift-by-16 note cites must still be there."""
    try:
        txt = open(MAME_SHIFT_LINE, encoding="utf-8", errors="replace").read().splitlines()
    except OSError as e:
        return False, f"cannot read {MAME_SHIFT_LINE}: {e}"
    hits = [i + 1 for i, l in enumerate(txt) if "( s & 0x0f ) ? ( s & 0x0f ) : 16" in l]
    return (1011 in hits), f"lines {hits}"


def claim_faf340_constants():
    """PartRec_ResetSlotValues_ByTag's stride, base, offsets and loop bound."""
    tree = Tree()
    lo, hi = tree.body["PartRec_ResetSlotValues_ByTag"]
    body = "\n".join(strip_comment(l) for l in tree.lines[lo:hi])
    want = ["0x12C", "0x1523", "0x76", "0x77", "12"]
    missing = [w for w in want if w not in body]
    six = body.count("0x1523")
    return (not missing and six >= 2), f"missing {missing}, 0x1523 x{six}"


CLAIMS = [
    ("Multiply16_Signed_Shr11's 18 quoted ROM bytes", claim_fc412e),
    ("ByteField_AddOrSub_Clamped's two mask tables are 1<<2i / 1<<(2i+1)", claim_bitmask_tables),
    ("Clamp_ToRange_LowByte_FBD88E: 36 of 42 bytes differ; spans 42 and 34", claim_clamp_diff),
    ("staging tail 0x00D78A..0x00D794: producers, and no absolute load", claim_staging_tail),
    ("Dev10C_WriteSixChanRegs_FromD78A's six register/word pairs", claim_fb7345_map),
    ("the MAME line the `sll 0 = 16` note cites (900tbl.hxx:1011)", claim_mame_shift16),
    ("PartRec_ResetSlotValues_ByTag's 0x12C / 0x1523 / 0x76 / 0x77 / 12", claim_faf340_constants),
]


def do_claims():
    bad = 0
    print("re-deriving every number this round wrote into a routine header\n")
    for label, fn in CLAIMS:
        ok, detail = fn()
        print(f"  [{'ok' if ok else 'FAIL'}] {label}\n         {detail}")
        bad += 0 if ok else 1
    print(f"\n{'PASS' if not bad else 'FAIL'}: {bad} failing claim(s) of {len(CLAIMS)}")
    return 1 if bad else 0


# ---------------------------------------------------------------- modes

def do_census(args):
    tree = Tree()
    rows = census(tree)
    print(f"prom_c: {len(rows)} sub_XXXXXX routines")
    shown = [r for r in rows if r['score'] >= args.min_score][:args.top]
    print(f"showing {len(shown)} (min-score {args.min_score}, top {args.top})\n")
    print(f"{'symbol':<14}{'span':>6}{'score':>6}{'call':>5}{'data':>5}{'oper':>5}"
          f"  named-callers / callees / devices")
    for r in shown:
        bits = []
        if r['named_callers']:
            bits.append("<-" + ",".join(r['named_callers'][:3]))
        if r['callees']:
            bits.append("->" + ",".join(r['callees'][:4]))
        if r['devices']:
            bits.append("dev:" + ",".join(r['devices']))
        if r['sfrs']:
            bits.append("sfr:" + ",".join(r['sfrs'][:4]))
        if r['kernel']:
            bits.append("KERNEL")
        print(f"{r['sym']:<14}{r['span']:>6}{r['score']:>6}{r['calls']:>5}"
              f"{r['data']:>5}{r['oper']:>5}  " + " ".join(bits))
    nz = sum(1 for r in rows if r['score'] > 0)
    print(f"\n{nz} of {len(rows)} have a non-zero score; "
          f"{len(rows) - nz} have NO evidence signal at all and should keep their address.")
    return 0


def do_show(args):
    tree = Tree()
    s = args.show
    if s.startswith('0x'):
        s = 'sub_' + s[2:].upper()
    if s not in tree.body:
        print(f"no such top-level symbol: {s}", file=sys.stderr)
        return 1
    rows = {r['sym']: r for r in census(tree)}
    r = rows.get(s)
    print(f"{s}  0x{tree.sub_addr(s):06X}  span {tree.sub_len(s)}")
    if r:
        print(f"  score {r['score']}  calls {r['calls']} data {r['data']} oper {r['oper']}")
        print(f"  named callers : {r['named_callers']}")
        print(f"  named callees : {r['callees']}")
        print(f"  devices       : {r['devices']}")
        print(f"  sfrs          : {r['sfrs']}")
        print(f"  in kernel     : {r['kernel']}")
    refs = scan_references(tree)[s]
    print("  reference sites:")
    for i, own, kind in refs:
        print(f"    line {i+1:>7} {kind:<8} in {own}: {tree.lines[i].strip()[:100]}")
    lo, hi = tree.body[s]
    print("  body:")
    for i in range(lo, min(hi, lo + args.lines)):
        print("    " + tree.lines[i].rstrip()[:120])
    return 0


def do_sibling(args):
    tree = Tree()
    rows, control, denom = sibling_scan(tree, args.minlen, args.anchor)
    ok, ca = control
    print(f"POSITIVE CONTROL: prom_c 0xF9806D DSP_WriteAllChannelRegs found in the "
          f"KN5000 image: {ok}" + (f" at 0x{ca:X}" if ok else ""))
    if not ok:
        print("  ⚠ the control FAILED, so a zero below would mean nothing.  Stop here.")
        return 1
    print(f"\ncandidates: sub_XXXXXX with span >= {args.minlen}: {denom}")
    print(f"of those, first {args.anchor} bytes occur in the KN5000 sub-CPU image: {len(rows)}")
    if rows:
        print(f"{'symbol':<14}{'span':>6}{'kn5000':>10}  {'diff':>5}  sibling symbol")
        for s, a, span, sa, nm_, diff in rows:
            print(f"{s:<14}{span:>6}  0x{sa:06X}  {diff:>5}  {nm_ or '(unnamed offset)'}")
        exact = [r for r in rows if r[5] == 0]
        print(f"\n{len(exact)} of {len(rows)} identical over the FULL span (diff 0).")
    else:
        print("\n★ ZERO.  With the control passing, this says the KN5000 sub-CPU tree has")
        print("  NO name to lend any unnamed prom_c routine: the shared code is already")
        print("  named on both sides.  A borrowed name is not available here.")
    hits, tot = data_reference_census(tree)
    print(f"\nsub_XXXXXX entry addresses occurring as an LE32 word in the prom_c ROM: "
          f"{len(hits)} of {tot}")
    if not hits:
        print("  -> every reference the census counts is a control transfer, not a "
              "dispatch-table entry.")
    return 0


def do_selftest():
    """Checks the census against facts read independently of the census code, and
    checks the LAST element of every list as well as the first."""
    tree = Tree()
    fails = []

    def chk(label, got, want):
        ok = got == want
        print(f"  [{'ok' if ok else 'FAIL'}] {label}: {got!r}"
              + ("" if ok else f"  expected {want!r}"))
        if not ok:
            fails.append(label)

    def chk_true(label, cond, detail=""):
        print(f"  [{'ok' if cond else 'FAIL'}] {label}  {detail}")
        if not cond:
            fails.append(label)

    # 1-2: the census enumerates the same set grep does, first AND last
    grep = subprocess.run(["grep", "-cE", r'^sub_[0-9A-Fa-f]{6}:', SRC],
                          capture_output=True, text=True).stdout.strip()
    chk("sub count matches grep", len(tree.subs), int(grep))
    chk_true("first sub is the lowest address",
             tree.subs[0] == min(tree.subs, key=tree.sub_addr), tree.subs[0])
    chk_true("LAST sub is the highest address",
             tree.subs[-1] == max(tree.subs, key=tree.sub_addr), tree.subs[-1])

    # 3-4: every sub_ name spells its own ELF address -- first and last
    bad = [s for s in tree.subs if s in tree.addr and tree.addr[s] != int(s[4:], 16)]
    chk("names that disagree with the ELF address", bad, [])
    chk_true("LAST sub's ELF address checked",
             tree.subs[-1] in tree.addr and
             tree.addr[tree.subs[-1]] == int(tree.subs[-1][4:], 16),
             f"{tree.subs[-1]} -> 0x{tree.addr.get(tree.subs[-1], -1):X}")

    # 5: the ROM bytes at the first and last sub are what the ELF says
    rom = open(ROM, "rb").read()
    for tag, s in (("first", tree.subs[0]), ("LAST", tree.subs[-1])):
        a = tree.sub_addr(s)
        chk_true(f"{tag} sub address inside the image", BASE <= a < BASE + len(rom),
                 f"{s} = 0x{a:X}")

    # 6: reference scanner finds the known call sites of a known-good case.
    # DSP_WriteChannelRegs_Inner is called by four calr sites in one routine; the
    # equivalent sub_ case used here is picked from the census itself so the check
    # cannot go stale.
    rows = census(tree)
    chk_true("at least one sub_ has a named caller",
             any(r['named_callers'] for r in rows),
             f"{sum(1 for r in rows if r['named_callers'])} do")
    chk_true("at least one sub_ has zero evidence",
             any(r['score'] == 0 for r in rows),
             f"{sum(1 for r in rows if r['score'] == 0)} do")

    # 7: the scanner does not count a definition line as a reference
    refs = scan_references(tree)
    selfref = [s for s in tree.subs
               if any(tree.lines[i].startswith(s + ':') for i, _, _ in refs[s])]
    chk("subs counting their own definition as a reference", selfref, [])

    # 8: the classifier really can produce all three kinds -- checked on synthetic
    # lines, because prom_c itself contains only one of them and a column that is
    # always zero must be shown to be a FACT and not a dead code path.
    probe = [("\tcall\t0xF9915C", 'call'),
             ("\t.long\t0xF9915C", 'data'),
             ("\tld\txbc, 0xF9915C", 'operand')]
    got = []
    for line, _want in probe:
        rest = strip_comment(line)
        toks = rest.split()
        mn = toks[0].lower().rstrip(',')
        got.append('data' if mn.startswith('.') else
                   ('call' if mn in CALL_MNEMONICS else 'operand'))
    chk("classifier on synthetic call/.long/ld lines", got, [k for _, k in probe])

    # 8b: and prom_c really does contain only control transfers -- asked of the BYTES
    hits, tot = data_reference_census(tree)
    chk("sub_ entry addresses appearing as an LE32 word in the ROM", hits, [])
    kinds = sorted({k for s in tree.subs for _, _, k in refs[s]})
    chk("reference kinds actually present in prom_c", kinds, ['call'])

    # 9: SFR table really came from the .inc
    chk_true("SFR names loaded from include/tmp95c061_sfr.inc",
             len(tree.sfrs) > 40 and 'P7' in tree.sfrs, f"{len(tree.sfrs)} names")

    # 10: device windows are ordered and non-overlapping
    ws = sorted(DEVICE_WINDOWS)
    chk_true("device windows do not overlap",
             all(ws[i][1] < ws[i + 1][0] for i in range(len(ws) - 1)), "")

    # 11: kernel block bound agrees with prom_c_kernel_map.py's own constant
    km = open(os.path.join(ROOT, "notes", "prom_c_kernel_map.py"),
              encoding="utf-8", errors="replace").read()
    chk_true("kernel bounds appear in prom_c_kernel_map.py",
             f"{KERNEL_LO:X}".lower() in km.lower()
             and f"{KERNEL_HI:X}".lower() in km.lower(),
             f"0x{KERNEL_LO:X}-0x{KERNEL_HI:X}")

    # 12: the sibling matcher's POSITIVE CONTROL must pass, or its zero means nothing
    sib, control, denom = sibling_scan(tree, 48, 8)
    chk_true("sibling POSITIVE CONTROL (0xF9806D found in the KN5000 image)",
             control[0], f"at 0x{control[1]:X}" if control[0] else "NOT FOUND")
    chk_true("sibling denominator is the whole candidate set, first to LAST",
             denom == sum(1 for s in tree.subs if tree.sub_len(s) >= 48),
             f"{denom} of {len(tree.subs)}")
    if sib:
        chk_true("LAST sibling row carries a differing count",
                 isinstance(sib[-1][5], int), f"{sib[-1][0]} diff={sib[-1][5]}")

    # 13: the span of the LAST sub runs to a top-level label, not to one of its own
    # `__` locals -- the bug that made the first draft of this script report span 1.
    last = tree.subs[-1]
    la = tree.sub_addr(last)
    locals_after = [a for n, a in tree.addr.items() if '__' in n and a > la]
    chk_true("LAST sub's span is not truncated by its own local labels",
             tree.sub_len(last) > 0 and
             (not locals_after or tree.sub_len(last) != min(locals_after) - la),
             f"{last} span {tree.sub_len(last)}")

    # 14-19: the rename table.  Every row is checked, and the LAST row explicitly,
    # because "tested on the first element only" is this project's recorded failure.
    names = [n for _, n, _ in RENAMES]
    chk("rename table has no duplicate target name",
        sorted({n for n in names if names.count(n) > 1}), [])
    olds = [o for o, _, _ in RENAMES]
    chk("rename table has no duplicate source", sorted({o for o in olds if olds.count(o) > 1}), [])
    chk("every row carries an evidence string",
        [o for o, _, e in RENAMES if len(e) < 30], [])
    txt = open(SRC, encoding="utf-8").read()
    missing = [o for o, n, _ in RENAMES
               if not re.search(r'^(' + o + '|' + n + r'):', txt, re.M)]
    chk("every rename row resolves to a label in the .s (old or new)", missing, [])
    fo, fn, _ = RENAMES[0]
    lo, ln, _ = RENAMES[-1]
    chk_true("FIRST row resolves", bool(re.search(r'^(' + fo + '|' + fn + r'):', txt, re.M)),
             f"{fo} -> {fn}")
    chk_true("LAST row resolves", bool(re.search(r'^(' + lo + '|' + ln + r'):', txt, re.M)),
             f"{lo} -> {ln}")

    # 20: rename_token renames the __local labels too (the bug a naive \b would hide)
    probe = "sub_FB7345:\n\tcalr sub_FB7345__FB7350\nsub_FB7345__FB7350:\nsub_FB73450:"
    out = rename_token(probe, "sub_FB7345", "NEW")
    chk_true("rename_token renames locals and leaves a longer address alone",
             "NEW__FB7350" in out and "sub_FB73450:" in out and "sub_FB7345:" not in out,
             out.replace(chr(10), ' | '))

    print("\n  --- claims (every number a header of this round states) ---")
    for label, fn in CLAIMS:
        ok, detail = fn()
        chk_true("claim: " + label, ok, detail)

    print(f"\n{'PASS' if not fails else 'FAIL'}: {len(fails)} failing check(s)")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--names", action="store_true")
    ap.add_argument("--claims", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--check-applied", action="store_true")
    ap.add_argument("--show")
    ap.add_argument("--sibling", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--top", type=int, default=60)
    ap.add_argument("--min-score", type=int, default=1)
    ap.add_argument("--minlen", type=int, default=48)
    ap.add_argument("--anchor", type=int, default=8)
    ap.add_argument("--lines", type=int, default=40)
    a = ap.parse_args()
    if a.selftest:
        return do_selftest()
    if a.names:
        return do_names()
    if a.claims:
        return do_claims()
    if a.apply:
        return do_apply()
    if a.check_applied:
        return do_apply(check_only=True)
    if a.show:
        return do_show(a)
    if a.sibling:
        return do_sibling(a)
    return do_census(a)


if __name__ == "__main__":
    sys.exit(main())
