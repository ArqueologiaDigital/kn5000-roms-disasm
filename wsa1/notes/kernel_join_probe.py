#!/usr/bin/env python3
"""Join prom_a's and prom_c's kernel blocks into ONE source, and prove the join.

QUESTION IT ANSWERS
    notes/kernel_shared_source_probe.py already established that the two WSA1
    CPUs carry the same 2,180-byte kernel and that 858 of 938 paired
    instructions are byte-identical.  That measurement is about the ROMs.  This
    tool is about the SOURCES: it pairs the two blocks LINE BY LINE, says
    exactly which lines cannot be shared verbatim and why, writes the merged
    file, and then re-checks that nothing was lost.

    ⚠ The two blocks are written in DIFFERENT HOUSE STYLES and the merge has to
    reconcile them, so "line shapes differ per image" is not a footnote here, it
    is the whole problem:

        prom_a   <asm>  ; ADDR  <hex bytes>  <prose>     -- carries the BYTES
        prom_c   <asm>  ; ADDR  <MAME text>              -- carries the DISASM

    Neither annotation is thrown away: the merged line carries both addresses,
    the bytes (both images' when they differ) and both prose columns.

MODES
    --pairs     pair the two blocks by address; report the line census
    --diffs     every pair whose ASSEMBLY TEXT differs, classified
    --symbols   the per-CPU constant table the shared source needs
    --emit      write kernel/kernel.s, kernel/kernel_maincpu.inc,
                kernel/kernel_subcpu.inc
    --verify    prove the merged file lost nothing: every prom_a line and every
                prom_c line of the two blocks is accounted for
    --metrics   what the move did to the tree-wide header / label figures
    --reachability
                notes/reachability.py's INPUTS, before the merge and after -- the
                cheap way to show the coverage figure cannot have moved
    --selftest  the checks, run on the FIRST and the LAST element of every list

RESULT
    941 instruction slots; 939 exist as source lines on both sides.  The other 2
    are 7 bytes prom_c had converted and prom_a still held as `.incbin`, so the
    merge CONVERTS them -- prom_a's .incbin total falls 46,313 -> 46,306.

        736  the two files already say the same thing
        129  same bytes, different house style      -> keep whichever text NAMES
                                                       more; 19 lines gain a name
         74  a real per-CPU value                   -> an equate, named once
          6  both at once (a macro spelling AND the per-CPU address)
          1  a self-reference prom_a already wrote as a label -> no equate needed

    21 equates cover all 80.  Nothing else differs between the two kernels.

    ★ THE PROOF IS THE BYTE GATE.  One source, two images, both byte-identical
      to the EPROMs.  --verify adds what the gate cannot see: that every comment
      line and every label of both blocks survived, that no comment was invented,
      and that substituting each CPU's equates back reproduces its own literals.

RUN
    python3 notes/kernel_join_probe.py --pairs
    python3 notes/kernel_join_probe.py --selftest
    python3 scripts/analysis/assert_byte_identical.py     # the gate, always
"""
import os
import re
import sys
from collections import Counter, OrderedDict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)

OFFSET = 0x12B65                      # prom_c address - prom_a address, every pair

# ⚠ BOUNDARIES ARE NOT GUESSED.  The instruction extents come from
# notes/kernel_shared_source_probe.py's kernel_pairs(), which reads prom_c's own
# labels; the SOURCE extents below are the lines that carry an address inside
# them, plus the section banner that introduces the block in each file.  A
# guessed boundary desynchronised an earlier paired decode by 1,628
# instructions, so --selftest asserts both ends of both blocks.
A_LO, A_HI = 0xF85606, 0xF85E8A       # prom_a, half-open
C_LO, C_HI = 0xF9816B, 0xF989EF       # prom_c, half-open
A_SRC = "prom_a/wsa1_prom_a.s"
C_SRC = "prom_c/wsa1_prom_c.s"
# ⚠ 1-based and inclusive, and they are line numbers IN THE PRE-MERGE COMMIT
# (PRE_MERGE below) -- the working tree no longer has these blocks.
A_BLOCK_LINES = (9303, 11192)         # section banner .. the kernel's last `ret`
C_BLOCK_LINES = (10048, 11759)

# --- the per-CPU constants ---------------------------------------------------
# Every row is (symbol, prom_a value, prom_c value, comment).  A row exists only
# because the two ROMs differ there -- except the ONE marked "same", which is
# named for completeness of the RAM map and whose equality the byte gate proves.
SYMBOL_TABLE = [
    ("KERNEL_STACK_TOP",         0x0060EB80, 0x0000FA00,
     "the kernel's own stack; different RAM maps"),
    ("KERNEL_CURRENT_TASK",      0x00BF,     0x0091,
     "word cell: pointer to the running task's control block, 0 = none"),
    ("KERNEL_PENDING_TICKS",     0x00BE,     0x0090,
     "byte cell: timer-3 ticks not yet serviced (INTT3_KernelTick raises it)"),
    ("KERNEL_TCB_BASE",          0x0300,     0x0100,
     "task control blocks, stride 12"),
    ("KERNEL_TASK_COUNT",        4,          3,
     "how many control blocks Kernel_InitRam clears"),
    ("KERNEL_READY_HEADS",       0x0330,     0x0124,
     "ready-queue heads, stride 4, one per priority level"),
    ("KERNEL_READY_LEVELS",      3,          2,
     "how many priority levels Kernel_Dispatch scans"),
    ("KERNEL_SEMA_QUEUES",       0x033C,     0x012C,
     "one wait-queue head per counting semaphore, stride 4"),
    ("KERNEL_SEMA_COUNTS",       0x035C,     0x013C,
     "the semaphore counts themselves, one byte each"),
    ("KERNEL_SEMA_COUNT",        8,          4,
     "how many counting semaphores this CPU has"),
    ("KERNEL_SEMA_COUNT_IMAGE",  0x00F85EBA, 0x00F9810E,
     "ROM: the power-on image of KERNEL_SEMA_COUNTS"),
    ("KERNEL_MSGQ_WAITQ",        0x0364,     0x0140,
     "one receiver wait-queue head per message queue, stride 4"),
    ("KERNEL_MSGQ_HEADS",        0x0374,     0x0148,
     "one message-list head per message queue, stride 4"),
    ("KERNEL_MSGQ_COUNT",        4,          2,
     "how many message queues this CPU has"),
    ("KERNEL_NODE_POOL",         0x0384,     0x0150,
     "the message nodes themselves, stride 8"),
    ("KERNEL_NODE_COUNT",        8,          4,
     "how many message nodes are in the pool"),
    ("KERNEL_FREE_LIST",         0x03C4,     0x0170,
     "head of the free-node list; the whole pool is appended to it at boot"),
    ("KERNEL_TIMERS",            0x03C8,     0x0174,
     "software-timer slots, stride 8"),
    ("KERNEL_TIMER_COUNT",       2,          2,
     "same on both CPUs -- named so the RAM map above is complete"),
    ("KERNEL_BOOT_TIMER_CALLBACK", 0x00F85EC2, 0x00F98112,
     "ROM: the callback in SoftTimer_Request_Boot's inline argument block"),
    ("KERNEL_TCB_TEMPLATE",      0xFFF85E7E, 0xFFF980DE,
     "the task entry-point record array minus one 12-byte stride, with the "
     "0xFF top byte the ROM literal actually carries"),
]
SYM_A = {n: a for n, a, c, _ in SYMBOL_TABLE}
SYM_C = {n: c for n, a, c, _ in SYMBOL_TABLE}

# Which symbol a differing literal maps to.  Keyed by (prom_a value, prom_c
# value) where that pair is unambiguous, and by prom_a ADDRESS where it is not
# -- the loop bounds 8/4 and 4/2 each serve two different arrays, and guessing
# would put the wrong name on one of them.
BY_VALUE = {
    (0x0060EB80, 0x0000FA00): "KERNEL_STACK_TOP",
    (0x00BF, 0x0091):         "KERNEL_CURRENT_TASK",
    (0x00BE, 0x0090):         "KERNEL_PENDING_TICKS",
    (0x0300, 0x0100):         "KERNEL_TCB_BASE",
    (0x02F4, 0x00F4):         "KERNEL_TCB_BASE-12",
    (0x0330, 0x0124):         "KERNEL_READY_HEADS",
    (0x032C, 0x0120):         "KERNEL_READY_HEADS-4",
    (0x033C, 0x012C):         "KERNEL_SEMA_QUEUES",
    (0x0338, 0x0128):         "KERNEL_SEMA_QUEUES-4",
    (0x035C, 0x013C):         "KERNEL_SEMA_COUNTS",
    (0x035B, 0x013B):         "KERNEL_SEMA_COUNTS-1",
    (0x0364, 0x0140):         "KERNEL_MSGQ_WAITQ",
    (0x0360, 0x013C):         "KERNEL_MSGQ_WAITQ-4",
    (0x0374, 0x0148):         "KERNEL_MSGQ_HEADS",
    (0x0370, 0x0144):         "KERNEL_MSGQ_HEADS-4",
    (0x0384, 0x0150):         "KERNEL_NODE_POOL",
    (0x03C4, 0x0170):         "KERNEL_FREE_LIST",
    (0x03C8, 0x0174):         "KERNEL_TIMERS",
    (0x03C0, 0x016C):         "KERNEL_TIMERS-8",
    (0x00F85EBA, 0x00F9810E): "KERNEL_SEMA_COUNT_IMAGE",
    (0x00F85EC2, 0x00F98112): "KERNEL_BOOT_TIMER_CALLBACK",
    (0xFFF85E7E, 0xFFF980DE): "KERNEL_TCB_TEMPLATE",
}
BY_ADDRESS = {
    0xF8561D: "KERNEL_READY_LEVELS",     # ldb b, 3   -- clear the ready heads
    0xF8562F: "KERNEL_TASK_COUNT",       # ldb b, 4   -- clear the TCBs
    0xF85642: "KERNEL_TIMER_COUNT",      # ldb b, 2   -- clear the timer slots
    0xF8565D: "KERNEL_SEMA_COUNT",       # ldw bc, 8  -- bytes copied from ROM
    0xF85667: "KERNEL_SEMA_COUNT",       # ldb b, 8   -- semaphore wait queues
    0xF85679: "KERNEL_NODE_COUNT",       # ldb b, 8   -- node pool
    0xF85698: "KERNEL_NODE_COUNT",       # ldb b, 8   -- append them all
    0xF856BA: "KERNEL_MSGQ_COUNT",       # ldb b, 4   -- receiver wait queues
    0xF856CC: "KERNEL_MSGQ_COUNT",       # ldb b, 4   -- message lists
    0xF85746: "KERNEL_READY_LEVELS",     # ldb b, 3   -- Kernel_Dispatch's scan
}


# --- reading the two blocks --------------------------------------------------
# ⚠ THE BLOCKS ARE READ OUT OF GIT, NOT OUT OF THE WORKING TREE.  Once the merge
# has been applied prom_a and prom_c hold two `.include` lines where the kernel
# used to be, so a tool that read the working tree would measure an empty block
# and report a clean result.  This is the commit whose prom_a/prom_c still carry
# the kernel written out inline; it is what --emit built from and what --verify
# compares against.
PRE_MERGE = "8ff84e5"
_cache = {}


def src(rel):
    """The PRE-MERGE text of a source file, from git."""
    if rel not in _cache:
        import subprocess
        r = subprocess.run(["git", "-C", ROOT, "show", "%s:%s" % (PRE_MERGE, rel)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit("cannot read %s at %s: %s" % (rel, PRE_MERGE, r.stderr))
        _cache[rel] = r.stdout.split("\n")
    return _cache[rel]


def now(rel):
    """The IMAGE as it stands in the working tree.

    ⚠ image_path, not os.path.join: prom_c's primary is a 2,517-line header
    since the per-subject split, and the kernel body it is asked about is in
    kernel/kernel.s, which the primary `.include`s.
    """
    return open(image_path(ROOT, rel)).read().split("\n")


def rom(which):
    f = "wsa1_prom_a.ic12" if which == "a" else "wsa1_prom_c.ic28"
    return open(os.path.join(ROOT, "original_ROMs", f), "rb").read()


ADDR_RE = re.compile(r';\s*([0-9A-F]{6})\b')
LABEL_RE = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):(.*)$')


def block(lines, first, last, lo, hi):
    """Split a source block into items.  One item per INSTRUCTION-bearing line:
    (address, [preceding non-instruction lines], the line itself)."""
    items, pending = [], []
    for raw in lines[first - 1:last]:
        m = ADDR_RE.search(raw)
        a = int(m.group(1), 16) if m else None
        if a is not None and lo <= a < hi:
            items.append((a, pending, raw))
            pending = []
        else:
            pending.append(raw)
    return items, pending


def load():
    a_items, a_tail = block(src(A_SRC), A_BLOCK_LINES[0], A_BLOCK_LINES[1], A_LO, A_HI)
    c_items, c_tail = block(src(C_SRC), C_BLOCK_LINES[0], C_BLOCK_LINES[1], C_LO, C_HI)
    return a_items, a_tail, c_items, c_tail


def code_of(line):
    return re.sub(r'\s+', ' ', line.split(";")[0].strip())


def note_of(line):
    """Everything the trailing comment says after the address token."""
    m = ADDR_RE.search(line)
    if not m:
        return ""
    return line[m.end():].strip()


def hex_of(line):
    """prom_a writes the instruction's BYTES after the address; prom_c does not."""
    m = re.search(r';\s*[0-9A-F]{6}\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(?:\s|$)', line)
    return m.group(1) if m else ""


def literals(text):
    """Numeric literals in an operand field, with their spans."""
    out = []
    for m in re.finditer(r'0x[0-9a-fA-F]+|(?<![\w.$])-?\d+', text):
        s = m.group(0)
        v = int(s, 16) if s.lower().startswith("0x") else int(s)
        out.append((m.start(), m.end(), v))
    return out


def norm(text):
    """Compare two assembly texts ignoring case, spacing and radix."""
    t = text.lower()
    t = re.sub(r'0x([0-9a-f]+)', lambda m: str(int(m.group(1), 16)), t)
    return re.sub(r'[\s,]+', ' ', t).strip()


PLACEHOLDER_NAME = re.compile(r'^(\.L[0-9A-Fa-f]{4,}|sub_[0-9A-Fa-f]{4,})$')


def symbolic_score(text):
    """How many MEANINGFUL names the operands use.  Higher is the better source.

    ⚠ A name spelled from an address is not a name.  prom_a labels seven targets
    in this block `.LF85B29`-style and prom_c gives the same seven addresses real
    names; without this rule the tie-break would keep the address spellings and
    the merge would be a documentation LOSS at exactly the places where prom_c is
    ahead."""
    ops = text.split(None, 1)
    if len(ops) < 2:
        return 0
    names = re.findall(r'(?<![\w.])[A-Za-z_.][A-Za-z0-9_.]{2,}', ops[1])
    return sum(0 if PLACEHOLDER_NAME.match(n) else 1 for n in names)


def label_map():
    """address -> [labels defined there], prom_c's names first.

    Both blocks label the same 66 addresses; prom_c labels 11 more and gives real
    names to seven that prom_a spells from the address.  Where the two names
    differ BOTH are kept -- the merged source emits prom_c's as the label and
    prom_a's underneath it, so nothing that referred to either still dangles."""
    out = OrderedDict()
    for rel, first, last, base in ((C_SRC, C_BLOCK_LINES[0], C_BLOCK_LINES[1], OFFSET),
                                   (A_SRC, A_BLOCK_LINES[0], A_BLOCK_LINES[1], 0)):
        lines = src(rel)[first - 1:last]
        pending = []
        for raw in lines:
            m = LABEL_RE.match(raw)
            if m:
                pending.append((m.group(1), m.group(2).strip()))
                continue
            am = ADDR_RE.search(raw)
            if am and pending:
                a = int(am.group(1), 16) - base
                for name, trail in pending:
                    out.setdefault(a, [])
                    if name not in [n for n, _ in out[a]]:
                        out[a].append((name, trail))
                pending = []
            elif am:
                pending = []
    return out


_sfr = {}


def sfr_equates():
    """The TMP95C061 SFR names from include/tmp95c061_sfr.inc, with their values.

    ★ Needed because the merge takes prom_c's `ldio T23MOD, 14` over prom_a's
    `ldio 0x28, 0x0e` at four sites -- prom_c names the register and prom_a did
    not.  Resolving the names here means --verify re-proves that each name still
    carries the number prom_a's listing had, which is the one thing a borrowed
    register name must never silently change.  (⚠ Both CPUs are the SAME PART, so
    the map transfers between them.  It does NOT transfer to the KN5000: 68 SFR
    names are shared with that machine and exactly one ADDRESS is.)"""
    if not _sfr:
        for l in open(os.path.join(ROOT, "include", "tmp95c061_sfr.inc")):
            m = re.match(r'\s*\.equ\s+([A-Za-z_][A-Za-z0-9_]*),\s*(0x[0-9A-Fa-f]+|\d+)', l)
            if m:
                _sfr[m.group(1)] = int(m.group(2), 0)
    return _sfr


def byte_diff_map():
    """address -> do the two ROMs disagree on this instruction's bytes?

    Read from the EPROMs, not from either listing.  The block is contiguous, so
    a slot's length is the distance to the next slot -- no decode, no guess."""
    a_items, _, c_items, _ = load()
    addrs = sorted(set(a for a, _, _ in a_items) |
                   set(a - OFFSET for a, _, _ in c_items))
    ra, rc = rom("a"), rom("c")
    out = {}
    for i, a in enumerate(addrs):
        n = (addrs[i + 1] if i + 1 < len(addrs) else A_HI) - a
        out[a] = (ra[a - 0xF80000:a - 0xF80000 + n] !=
                  rc[a + OFFSET - 0xF80000:a + OFFSET - 0xF80000 + n])
    return out


def paired():
    """[(a_addr, a_item_or_None, c_item_or_None)] over the union of addresses."""
    a_items, _, c_items, _ = load()
    ma = {a: it for a, *it in [(a, p, l) for a, p, l in a_items]}
    mc = {a - OFFSET: it for a, *it in [(a, p, l) for a, p, l in c_items]}
    out = []
    for a in sorted(set(ma) | set(mc)):
        out.append((a, ma.get(a), mc.get(a)))
    return out


# --- reporting ---------------------------------------------------------------
def cmd_pairs():
    a_items, a_tail, c_items, c_tail = load()
    print("prom_a block  lines %d-%d   %d instruction lines"
          % (A_BLOCK_LINES[0], A_BLOCK_LINES[1], len(a_items)))
    print("prom_c block  lines %d-%d   %d instruction lines"
          % (C_BLOCK_LINES[0], C_BLOCK_LINES[1], len(c_items)))
    p = paired()
    both = [x for x in p if x[1] and x[2]]
    only_a = [x for x in p if x[1] and not x[2]]
    only_c = [x for x in p if x[2] and not x[1]]
    print("\naddresses paired on both sides   %4d" % len(both))
    print("in prom_a only                   %4d" % len(only_a))
    print("in prom_c only                   %4d   <- prom_c has converted bytes"
          " prom_a still holds as .incbin" % len(only_c))
    for a, ai, ci in only_c:
        print("     0x%06X  %s" % (a, code_of(ci[1])))
    same = sum(1 for a, ai, ci in both if norm(code_of(ai[1])) == norm(code_of(ci[1])))
    print("\nassembly text identical (case/space/radix normalised)  %4d" % same)
    print("assembly text differs                                  %4d" % (len(both) - same))
    print("\nnon-instruction source lines carried into the merge:")
    print("   from prom_a  %4d" % (sum(len(p_) for _, p_, _ in a_items) + len(a_tail)))
    print("   from prom_c  %4d" % (sum(len(p_) for _, p_, _ in c_items) + len(c_tail)))
    return 0


# Address-shaped constants, keyed by the prom_a literal alone.  Used ONLY on a
# slot whose two ROMs actually differ, and ONLY for values >= 0x80 -- a loop
# bound of 4 must never be substituted by value, because 4 is KERNEL_TASK_COUNT
# at one site and KERNEL_MSGQ_COUNT at two others.  Those go through BY_ADDRESS.
A_VALUE = {a: sym for (a, c), sym in BY_VALUE.items() if a >= 0x80}


def classify(a_addr, a_line, c_line, bytes_differ=None):
    """Why this pair's text differs, and what the shared source should say.

    ⚠ `bytes_differ` is not optional in practice.  The first version of this
    function decided "the two texts are only a house-style difference" from the
    TEXTS alone, and prom_a writes `m_ld_rm MW8, 0xbf, r4` where prom_c writes
    `extpfx3 0xD0, 0x91, 0x24` -- the same instruction, a different spelling AND
    a different address, with a different literal count so the operand-by-operand
    comparison never ran.  Six such lines went through with prom_a's 0xBF baked
    in and prom_c stopped rebuilding by exactly six bytes.  The gate caught it;
    this argument is what stops it happening again."""
    at, ct = code_of(a_line), code_of(c_line)
    if a_addr in BY_ADDRESS:
        # A named ARRAY BOUND.  These go by address because the same pair of
        # numbers means different things at different sites -- 8/4 is the
        # semaphore count at one site and the node-pool count at two others --
        # and because one of them (KERNEL_TIMER_COUNT) is 2 on BOTH CPUs, so a
        # value-driven rule would never see it and the RAM map in the two .inc
        # files would have a hole exactly where the two processors agree.
        sym = BY_ADDRESS[a_addr]
        lits = literals(at)
        s_, e_, _ = lits[-1]
        return ("symbol:" + sym, at[:s_] + sym + at[e_:])
    if norm(at) == norm(ct):
        if bytes_differ:
            return ("UNRESOLVED", at)
        return ("same", at)
    la, lc = literals(at), literals(ct)
    diff = [k for k in range(min(len(la), len(lc))) if la[k][2] != lc[k][2]]
    if len(la) == len(lc) and diff:
        # a real per-CPU constant, or a self-reference into the block
        out, shift = at, 0
        named = []
        for k in diff:
            av, cv = la[k][2], lc[k][2]
            sym = BY_ADDRESS.get(a_addr) or BY_VALUE.get((av & 0xFFFFFFFF, cv & 0xFFFFFFFF))
            if sym is None and cv - av == OFFSET and A_LO <= av < A_HI:
                # a SELF-REFERENCE: the same label, linked at two addresses.  It
                # needs no equate at all -- writing the label makes the shared
                # source assemble correctly in both images.
                lm = label_map().get(av)
                if lm:
                    sym = lm[0][0]
            if sym is None:
                return ("UNRESOLVED", "%s | %s" % (at, ct))
            s, e = la[k][0] + shift, la[k][1] + shift
            out = out[:s] + sym + out[e:]
            shift += len(sym) - (e - s)
            named.append(sym)
        return ("symbol:" + ",".join(named), out)
    # Different house style.  Keep whichever text names more things -- but if
    # the two ROMs differ here, the kept text still carries one CPU's literal and
    # must be made symbolic before it can be shared.
    text = at if symbolic_score(at) >= symbolic_score(ct) else ct
    if not bytes_differ:
        return ("style", text)
    out, shift, named = text, 0, []
    for s_, e_, v in literals(text):
        sym = BY_ADDRESS.get(a_addr) or A_VALUE.get(v & 0xFFFFFFFF)
        if sym is None:
            continue
        out = out[:s_ + shift] + sym + out[e_ + shift:]
        shift += len(sym) - (e_ - s_)
        named.append(sym)
    if not named:
        # A self-reference already written as a LABEL needs no equate: the same
        # symbol simply links at two addresses.  `ld XIX,SoftTimer_Request_Boot`
        # is prom_a's spelling of prom_c's `ld xix, 0xF98245`.
        block_labels = {n for v in label_map().values() for n, _ in v}
        if any(t in block_labels
               for t in re.findall(r'[A-Za-z_.][A-Za-z0-9_.]*', text)):
            return ("style/selfref", text)
        return ("UNRESOLVED", "%s | %s" % (at, ct))
    return ("style+symbol:" + ",".join(named), out)


def cmd_diffs():
    n = Counter()
    bd = byte_diff_map()
    for a, ai, ci in paired():
        if not (ai and ci):
            continue
        kind, text = classify(a, ai[1], ci[1], bd[a])
        if kind == "same":
            n["same"] += 1
            continue
        n[kind.split(":")[0]] += 1
        print("0x%06X/%06X  %-8s  %-44s" % (a, a + OFFSET, kind.split(":")[0], text))
        print("            a  %s" % code_of(ai[1]))
        print("            c  %s" % code_of(ci[1]))
    print("\n" + "  ".join("%s=%d" % kv for kv in sorted(n.items())))
    return 1 if n["UNRESOLVED"] else 0


def cmd_symbols():
    print("%-28s %-12s %-12s %s" % ("symbol", "prom_a", "prom_c", "meaning"))
    for name, av, cv, why in SYMBOL_TABLE:
        tag = "  (same)" if av == cv else ""
        print("%-28s 0x%-10X 0x%-10X %s%s" % (name, av, cv, why, tag))
    use = Counter()
    bd = byte_diff_map()
    for a, ai, ci in paired():
        if not (ai and ci):
            continue
        kind, _ = classify(a, ai[1], ci[1], bd[a])
        if ":" in kind:
            for name in kind.split(":", 1)[1].split(","):
                use[name.split("-")[0]] += 1
    print("\nsites per symbol:")
    for name, _, _, _ in SYMBOL_TABLE:
        print("   %-28s %d" % (name, use.get(name, 0)))
    unused = [n for n, _, _, _ in SYMBOL_TABLE if not use.get(n)]
    if unused:
        print("   ⚠ never used: %s" % ", ".join(unused))
    return 0



KERNEL_HEADER_TMPL = r"""; ==============================================================================
; Technics SX-WSA1R -- THE MULTITASKING KERNEL, ONE SOURCE FOR BOTH PROCESSORS
; ==============================================================================
;
; The WSA1R has two Toshiba TMP95C061s and they run THE SAME KERNEL.  Until now
; that fact lived in a note.  This file is the fact itself: prom_a and prom_c
; both `.include` it, and both ROMs still rebuild byte for byte.
;
;     prom_a/wsa1_prom_a.s        CPU 1, "MICROCOMPUTER (MAIN)", IC1/IC12
;         .include "kernel/kernel_maincpu.inc"
;         .include "kernel/kernel.s"          ->  0xF85606-0xF85E89
;
;     prom_c/wsa1_prom_c.s        CPU 2, "MICROCOMPUTER (SUB)",  IC2/IC28
;         .include "kernel/kernel_subcpu.inc"
;         .include "kernel/kernel.s"          ->  0xF9816B-0xF989EE
;
;     every pair of addresses differs by exactly 0x12B65, first slot to last
;
; ★★ THE BYTE GATE IS THE PROOF, AND IT IS THE WHOLE POINT.
;
;     python3 scripts/analysis/assert_byte_identical.py
;
;   Two listings that look alike prove nothing.  ONE SOURCE that assembles to
;   2,180 bytes of prom_a and 2,180 bytes of prom_c, both byte-identical to the
;   original EPROMs, cannot be a resemblance.  If a single equate in either
;   kernel_*.inc is wrong, BOTH images stop rebuilding.
;
; ------------------------------------------------------------------------------
; HOW THE TWO COPIES DIFFER, measured before this file was written
; ------------------------------------------------------------------------------
;
;     python3 notes/kernel_join_probe.py --pairs
;     python3 notes/kernel_join_probe.py --diffs
;     python3 notes/kernel_join_probe.py --symbols
;
;   %(slots)d instruction slots, of which %(both)d exist on both sides as source lines.
;   %(same)d of those %(both)d already say the same thing.  Of the %(differ)d that do not:
;
;     %(style)3d  the two files' HOUSE STYLE differs -- prom_a writes
;          `m_ld_rm MWD+r4, 0x00, r0` where prom_c writes `extpfx3 0x9C, 0x00,
;          0x20`, prom_c writes `ldio T23MOD, 14` where prom_a writes
;          `ldio 0x28, 0x0e`, and one of them uses a label where the other uses a
;          raw displacement.  The merge keeps whichever text NAMES MORE THINGS,
;          so neither file loses and %(cwins)d lines gain a name they did not have.
;     %(sym)3d  a value that kernel_maincpu.inc and kernel_subcpu.inc name, each
;          named ONCE and used symbolically here.  %(sym_diff)d of them genuinely differ
;          between the two CPUs; the other %(sym_same)d is KERNEL_TIMER_COUNT, which is 2
;          on both and is named only so the RAM map in the .inc files has no hole
;          exactly where the two processors agree.  (%(both_kinds)d of the %(sym)d are also a
;          house-style difference: a macro spelling AND a per-CPU address.)
;
;   ⚠ Those %(sym)d sites are NOT %(sym)d unrelated edits: they are %(nsym)d constants --
;     TWELVE RAM addresses (the stack top, two low-RAM cells and nine array
;     bases), SIX array sizes and THREE ROM pointers.  The two processors run the
;     same kernel over different RAM maps and with different array counts -- 4
;     tasks against 3, 8 semaphores against 4, 4 message queues against 2 -- and
;     that is the entire difference between them.
;
;   ⚠ These numbers are FORMATTED FROM THE MEASUREMENT, not typed: they cannot
;     disagree with what --diffs prints.
;
; ★ There is NO `.if CPU_MAINCPU` anywhere in this file, and that is deliberate.
;   Wrapping code in conditionals would duplicate every differing line at its
;   site; equates name each difference once and leave the body genuinely shared.
;
; ------------------------------------------------------------------------------
; WHAT THE MERGE DID TO THE TEXT -- so a reviewer can check it rather than trust it
; ------------------------------------------------------------------------------
;
; * Comments and headers were MOVED, not rewritten.  Where both files document
;   the same routine, BOTH headers are here, each under a banner saying which
;   file it came from.  prom_a's and prom_c's headers were written by different
;   passes and cite different call sites, so keeping one would have destroyed
;   real documentation.
; * Both files' LABELS are kept.  Where the two files name the same address
;   differently, prom_c's name is the label and prom_a's is emitted underneath it,
;   so a reference to either still resolves.  prom_c splits the block more finely
;   and gives real names to %(nsub)d addresses prom_a still spells `sub_F85B0D` and
;   %(ndotl)d it spells `.LF85B29`, so prom_a's kernel is better named than it was.
; * ⚠ ONE COMMENT LINE IS REWRITTEN, and it is enumerated in CORRECTIONS in
;   notes/kernel_join_probe.py rather than done quietly.  The banner
;   `; 0xF85D1C-0xF85E89 -- not yet converted` was WRONG BEFORE THE MERGE -- that
;   range has been converted for two rounds, and it is the standing "0 of 1"
;   failure of notes/prom_a_byte_checks.py's span-banner check.  Moving it here
;   unfixed would have made that check vacuous, because prom_a would have had no
;   banner left to fail on.
; * Each instruction line carries BOTH addresses, the bytes (both images' when
;   they differ), prom_c's disassembly text and prom_a's prose.  prom_a's block
;   carried the bytes and prom_c's carried the disassembly; the merged line
;   carries both.
; * ⚠ ONE prom_a name is NOT kept: prom_a calls 0xF85C89 `MsgQueue_ReceiveBlocking`
;   and prom_c calls the address three bytes later by that same name, having
;   split the routine into a stack face and a register face.  Keeping both would
;   define one symbol twice.  prom_c's finer split wins; prom_b reaches the
;   routine by address (`T_MsgQueue_ReceiveBlocking: jp 0xF85C89`), so nothing
;   dangles.
; * ★ prom_a GAINS 7 CONVERTED BYTES.  It held 0xF85C3D-0xF85C43 as `.incbin`;
;   prom_c has the same seven bytes decoded, and they are byte-identical in the
;   two EPROMs (`bf 0e 02 ff ff 68 f2`), so the merge takes prom_c's version and
;   prom_a's last `.incbin` inside the kernel disappears.
;
; ------------------------------------------------------------------------------
; THE ONE ROUTINE THE EARLIER PROBE COULD NOT PAIR
; ------------------------------------------------------------------------------
; notes/kernel_shared_source_probe.py reports 76 of 77 routines decoding to the
; same instruction count, the exception being Kernel_InitRam -- because the
; 8-byte block `SoftTimer_Request_Boot` is DATA inside the code stream and a
; linear decode frames it differently on each side.  That is a fact about the
; DISASSEMBLER, not about the source: both files already write those 8 bytes as
; `.short / .short / .long`, identically.  So it needs no duplication and no
; conditional -- only the callback address is per-CPU, and it is the equate
; KERNEL_BOOT_TIMER_CALLBACK.  Handled explicitly, not forced.
;
; ------------------------------------------------------------------------------
; ⚠ REGENERATING THIS FILE
; ------------------------------------------------------------------------------
; `python3 notes/kernel_join_probe.py --emit` produced the first version from
; prom_a's and prom_c's blocks.  It is kept as the RECORD OF THE MERGE, not as a
; build step: this file is the source now, and a re-run would discard anything
; edited here.  `--verify` re-checks the merge against both originals in git and
; is the thing to run after editing.
; ==============================================================================

; ------------------------------------------------------------------------------
; TLCS-900 byte-emitter macros, needed by the lines below that llvm-mc cannot
; spell.  MOVED VERBATIM from prom_a/wsa1_prom_a.s, which defines these (and 56
; more) near the top of its own file and therefore must not see them twice --
; llvm-mc rejects a redefined macro.  kernel_maincpu.inc sets the guard symbol;
; kernel_subcpu.inc does not, because prom_c has no such block of its own.
;
; ⚠ These emit BYTES.  The gate proves the bytes; it cannot prove the NAME on a
;   macro is the right mnemonic.  That comes from MAME's dasm900.cpp tables, as
;   argued at prom_a/wsa1_prom_a.s's own definitions, and every use below carries
;   unidasm's text in its trailing comment so the two can be compared by eye.
; ------------------------------------------------------------------------------
.ifndef KERNEL_MEM_OPS_PROVIDED

; --- operand prefixes: <size><address width> ---------------------------------
.equ MB8,  0xC0		; byte operand, 8-bit direct address	(n)
.equ MW8,  0xD0		; word operand, 8-bit direct address
.equ ML8,  0xE0		; long operand, 8-bit direct address
.equ MD8,  0xF0		; "dst"-table op, 8-bit direct address
; --- the same operations, with a REGISTER-relative operand -------------------
; dasm900.cpp:1473-1521.  Add the register index r0-r7: `MWD+r7` is "word-size
; operand at (XSP+d8)".  The +d8 forms take exactly one displacement byte.
.equ MBD, 0x88		; byte operand at (Rn+d8)	-> mnemonic_88[]
.equ MWD, 0x98		; word operand at (Rn+d8)	-> mnemonic_98[]
.equ MLD, 0xA8		; long operand at (Rn+d8)	-> mnemonic_a0[]
.equ MDD, 0xB8		; "dst"-table op at (Rn+d8)	-> mnemonic_b8[]
; --- register index inside an operation byte ---------------------------------
; dasm900.cpp:1345-1347.  The same index selects W/A/B/C/D/E/H/L,
; WA/BC/DE/HL/IX/IY/IZ/SP or XWA/XBC/XDE/XHL/XIX/XIY/XIZ/XSP according to the
; size the prefix already chose.
.equ r0, 0	; W   / WA / XWA
.equ r1, 1	; A   / BC / XBC
.equ r2, 2	; B   / DE / XDE
.equ r3, 3	; C   / HL / XHL
.equ r4, 4	; D   / IX / XIX
.equ r5, 5	; E   / IY / XIY
.equ r6, 6	; H   / IZ / XIZ
.equ r7, 7	; L   / SP / XSP
; --- the operand-size byte for the two `ldc` forms ---------------------------
.equ RW,   0xD8		; + index -> WA BC DE HL IX IY IZ SP

.macro _mem pfx, addr
	.byte \pfx
	.if ((\pfx) & 0xC0) == 0xC0
	.byte (\addr) & 0xFF
	.if ((\pfx) & 3) >= 1
	.byte ((\addr) >> 8) & 0xFF
	.endif
	.if ((\pfx) & 3) >= 2
	.byte ((\addr) >> 16) & 0xFF
	.endif
	.else
	.if ((\pfx) & 0x08) != 0
	.byte (\addr) & 0xFF
	.endif
	.endif
.endm
.macro m_ld_rm pfx, addr, r		; ld  R,(addr)			op 0x20+r
	_mem \pfx, \addr
	.byte 0x20 + (\r)
.endm
.macro m_cp_mr pfx, addr, r		; cp  (addr),R			op 0xF8+r
	_mem \pfx, \addr
	.byte 0xF8 + (\r)
.endm
.macro m_ld_mi16 pfx, addr, imm		; ldw (addr),#imm16		op 0x02
	_mem \pfx, \addr
	.byte 0x02, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_st_mr16 pfx, addr, r		; ld (addr),R16			op 0x50+r
	_mem \pfx, \addr
	.byte 0x50 + (\r)
.endm
.macro m_ldc_cr_reg rp, cr		; ldc <cr>,R			op 0x2E
	.byte \rp, 0x2E, \cr
.endm
.macro m_ldc_reg_cr rp, cr		; ldc R,<cr>			op 0x2F
	.byte \rp, 0x2F, \cr
.endm

.endif
"""



def kernel_header():
    """The file header, with every count formatted from the live measurement so
    the prose cannot drift away from what --diffs reports."""
    bd = byte_diff_map()
    kinds = Counter()
    cwins = 0
    for a, ai, ci in paired():
        if not (ai and ci):
            continue
        kind, text = classify(a, ai[1], ci[1], bd[a])
        kinds[kind.split(":")[0]] += 1
        if kind.startswith("style") and text == code_of(ci[1]):
            cwins += 1
    both = kinds["same"] + kinds["style"] + kinds["style+symbol"] \
        + kinds["style/selfref"] + kinds["symbol"]
    sym_diff = sum(1 for a, ai, ci in paired() if ai and ci and bd[a]
                   and ":" in classify(a, ai[1], ci[1], bd[a])[0]
                   and classify(a, ai[1], ci[1], bd[a])[0].startswith(("symbol", "style+")))
    sym_same = kinds["symbol"] + kinds["style+symbol"] - sym_diff
    return KERNEL_HEADER_TMPL % {
        "slots": len(paired()),
        "both": both,
        "same": kinds["same"],
        "differ": both - kinds["same"],
        "style": kinds["style"] + kinds["style+symbol"] + kinds["style/selfref"],
        "sym": kinds["symbol"] + kinds["style+symbol"],
        "both_kinds": kinds["style+symbol"],
        "nsym": len(SYMBOL_TABLE),
        "cwins": cwins,
        "sym_diff": sym_diff,
        "sym_same": sym_same,
        "nsub": sum(1 for v in label_map().values() for n, _ in v[1:]
                    if n.startswith("sub_")),
        "ndotl": sum(1 for v in label_map().values() for n, _ in v[1:]
                     if n.startswith(".L")),
    }

# --- writing the merged source ----------------------------------------------
BANNER_A = ("; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor "
            ">>>>>>>>>>>>>")
BANNER_C = ("; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor "
            ">>>>>>>>>>>>>>")

# ⚠ ONE naming collision, and it is not a duplicate: prom_a calls 0xF85C89
# `MsgQueue_ReceiveBlocking` while prom_c splits the same routine into a stack
# face at that address and gives the name `MsgQueue_ReceiveBlocking` to the
# REGISTER face three bytes later.  Emitting prom_a's spelling as an alias would
# define one symbol at two addresses.  prom_c's finer split wins and prom_a's
# name is dropped HERE ONLY; prom_b reaches the routine by address
# (`T_MsgQueue_ReceiveBlocking: jp 0xF85C89`), so nothing dangles.
DROPPED_ALIASES = {0xF85C89: "MsgQueue_ReceiveBlocking"}

CODE_COL = 46

# ⚠⚠ THE ONLY COMMENT LINE THE MERGE REWRITES, and the reason it is a dict rather
# than an edit: every other line of both blocks moves verbatim, --verify proves
# it, and an exception that is not enumerated is indistinguishable from a slip.
#
# The banner was WRONG BEFORE THE MERGE: 0xF85D1C-0xF85E89 has been converted
# code for two rounds and the banner still claimed otherwise, which is the
# standing "0 of 1" failure of notes/prom_a_byte_checks.py's span-banner check.
# Moving it into a shared file without fixing it would have made that check
# VACUOUS -- prom_a would have had no banners left to fail on.  The replacement
# copies, deliberately, the wording wave 5 round 2 used on the neighbouring
# 0xF85904-0xF85C88 banner, which was the same mistake.
CORRECTIONS = {
    "; 0xF85D1C-0xF85E89 -- not yet converted": [
        "; 0xF85D1C-0xF85E89 -- CONVERTED.  This banner said \"not yet converted\" and sat",
        "; directly above converted code; corrected 2026-08-30 when the kernel became one",
        "; shared source.  Same failure and same wording as the 0xF85904-0xF85C88 banner",
        "; two screens up, which wave 5 round 2 corrected for the same reason.",
        "; notes/prom_a_byte_checks.py fails if a \"not yet converted\" banner has no",
        "; `.incbin` under it, and this one had none -- it was the \"0 of 1\" that check has",
        "; been reporting.",
    ],
}


def instr_length_map(addrs):
    """Byte length per address.  The block is CONTIGUOUS, so a slot's length is
    the distance to the next one -- no decode and no guess."""
    out = {}
    for i, a in enumerate(addrs):
        out[a] = (addrs[i + 1] if i + 1 < len(addrs) else A_HI) - a
    return out


def prose_of(line):
    """prom_a's human comment: what is left after the address AND the bytes."""
    m = re.search(r';\s*[0-9A-F]{6}\s+(?:(?:[0-9a-f]{2} )*[0-9a-f]{2})?\s*(.*)$', line)
    return m.group(1).strip() if m else ""


def strip_labels(lines):
    """Split a gap into (prose lines, [(label, trailing comment)])."""
    prose, labels = [], []
    for raw in lines:
        m = LABEL_RE.match(raw)
        if m:
            labels.append((m.group(1), m.group(2).strip()))
        else:
            prose.append(raw)
    return prose, labels


def trim(lines):
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return lines


def emit_kernel():
    a_items, a_tail, c_items, c_tail = load()
    ma = {a: (p, l) for a, p, l in a_items}
    mc = {a - OFFSET: (p, l) for a, p, l in c_items}
    addrs = sorted(set(ma) | set(mc))
    lens = instr_length_map(addrs)
    ra, rc = rom("a"), rom("c")
    lm = label_map()
    dropped_incbin = []
    out = [kernel_header()]

    for a in addrs:
        ai, ci = ma.get(a), mc.get(a)
        n = lens[a]
        ahex = " ".join("%02x" % b for b in ra[a - 0xF80000:a - 0xF80000 + n])
        chex = " ".join("%02x" % b for b in rc[a + OFFSET - 0xF80000:
                                               a + OFFSET - 0xF80000 + n])

        # labels are dropped here and re-emitted below from label_map(), which
        # is what merges the two files' names for the same address
        gap_a, _ = strip_labels(ai[0] if ai else [])
        gap_c, _ = strip_labels(ci[0] if ci else [])
        keep_a = []
        for ln in gap_a:
            if re.match(r'^\s*\.incbin\b', ln):
                dropped_incbin.append((a, ln.strip()))
                continue
            if ln.rstrip() in CORRECTIONS:
                keep_a.extend(CORRECTIONS[ln.rstrip()])
                continue
            keep_a.append(ln)
        gap_a, gap_c = trim(keep_a), trim(gap_c)
        if gap_a:
            out.append("")
            out.append(BANNER_A)
            out.extend(gap_a)
        if gap_c:
            out.append("")
            out.append(BANNER_C)
            out.extend(gap_c)
        if gap_a or gap_c:
            out.append("")

        # labels: prom_c's first (it splits finer and names more), then any
        # prom_a name for the SAME address that prom_c does not already use.
        seen = set()
        for name, trail in lm.get(a, []):
            if name in seen or DROPPED_ALIASES.get(a) == name:
                continue
            seen.add(name)
            if len(seen) == 1:
                out.append("%s:%s" % (name, ("   " + trail) if trail else ""))
            else:
                extra = ("  " + trail.lstrip("; ")) if trail else ""
                out.append("%s:   ; <- prom_a's name for this address.%s"
                           % (name, extra))

        if ai and ci:
            _, code = classify(a, ai[1], ci[1], ahex != chex)
        elif ci:
            code = code_of(ci[1])
        else:
            code = code_of(ai[1])

        bytes_col = ahex if ahex == chex else "a=%s c=%s" % (ahex, chex)
        notes = []
        cn = note_of(ci[1]) if ci else ""
        an = prose_of(ai[1]) if ai else ""
        if cn:
            notes.append(("c: " + cn) if ahex != chex else cn)
        if an:
            notes.append(an)
        comment = "; %06X/%06X  %s%s" % (a, a + OFFSET, bytes_col,
                                         ("   " + "   ".join(notes)) if notes else "")
        line = "\t" + code
        pad = max(1, CODE_COL - len(line))
        out.append(line + " " * pad + comment)

    tail = trim([l for l in (a_tail or [])
                 if not re.match(r'^\s*\.incbin\b', l)])
    tailc = trim(c_tail or [])
    if tail or tailc:
        out.append("")
        if tail:
            out.append(BANNER_A)
            out.extend(tail)
        if tailc:
            out.append(BANNER_C)
            out.extend(tailc)
    out.append("")
    write(os.path.join(ROOT, "kernel", "kernel.s"), "\n".join(out))
    return addrs, dropped_incbin


def emit_inc(which):
    cpu = "maincpu (CPU 1, prom_a)" if which == "a" else "subcpu (CPU 2, prom_c)"
    other = "prom_c" if which == "a" else "prom_a"
    L = [
        "; " + "=" * 76,
        "; kernel/kernel_%s.inc -- what the SHARED kernel source means on the %s"
        % ("maincpu" if which == "a" else "subcpu",
           "MAIN" if which == "a" else "SUB"),
        "; processor of the Technics SX-WSA1R.",
        "; " + "=" * 76,
        ";",
        "; kernel/kernel.s is ONE source assembled into BOTH CPUs.  Everything that",
        "; genuinely differs between the two copies is named here and nowhere else, so",
        "; the shared body never has to ask which processor it is being built for.",
        ";",
        "; ⚠ EVERY VALUE BELOW IS A MEASUREMENT, not a decision.  Each one is the",
        ";   literal the ROM carries at the sites listed by",
        ";       python3 notes/kernel_join_probe.py --symbols",
        ";   and if one of them is wrong by a single byte the image stops rebuilding:",
        ";       python3 scripts/analysis/assert_byte_identical.py",
        ";",
        "; ★ Read together, these equates ARE %s's kernel RAM map." % cpu,
        ";   The other processor's is in kernel_%s.inc, and the two differ in"
        % ("subcpu" if which == "a" else "maincpu"),
        ";   every row but one -- same kernel, different RAM.",
        "",
    ]
    if which == "a":
        L += [
            "; prom_a already defines the TLCS-900 byte-emitter macros (m_ld_rm,",
            "; m_st_mr16, m_ldc_cr_reg, ...) near the top of its own file, so kernel.s",
            "; must NOT define them again -- llvm-mc rejects a redefined macro.  prom_c",
            "; has no such block, which is why the definitions in kernel.s are guarded",
            "; on this symbol rather than being unconditional.",
            ".equ KERNEL_MEM_OPS_PROVIDED, 1",
            "",
        ]
    width = max(len(n) for n, _, _, _ in SYMBOL_TABLE)
    for name, av, cv, why in SYMBOL_TABLE:
        v = av if which == "a" else cv
        note = why + ("   ⚠ SAME on both CPUs" if av == cv else "")
        L.append(".equ %-*s 0x%08X\t; %s" % (width + 1, name + ",", v, note))
    L.append("")
    write(os.path.join(ROOT, "kernel",
                       "kernel_maincpu.inc" if which == "a" else "kernel_subcpu.inc"),
          "\n".join(L))


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)
    print("  wrote %s  (%d lines)" % (os.path.relpath(path, ROOT), text.count("\n")))


def cmd_emit():
    emit_inc("a")
    emit_inc("c")
    addrs, dropped = emit_kernel()
    print("  %d instruction slots, 0x%06X-0x%06X (prom_a) / 0x%06X-0x%06X (prom_c)"
          % (len(addrs), addrs[0], A_HI - 1, addrs[0] + OFFSET, C_HI - 1))
    for a, ln in dropped:
        print("  DROPPED before 0x%06X: %s" % (a, ln))
        print("    -- prom_c has those bytes converted; the merge takes prom_c's"
              " version, so prom_a gains 7 converted bytes.")
    return 0



# --- proving the merge lost nothing ------------------------------------------
def cmd_verify():
    """Every line of both original blocks accounted for, in both directions."""
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    kern = now("kernel/kernel.s")
    kset = set(l.rstrip() for l in kern)
    a_items, a_tail, c_items, c_tail = load()

    # 1. prose.  Every comment line of both blocks must be in the merged file
    #    VERBATIM -- this is the "movement, not rewriting" claim, checked rather
    #    than asserted.
    for tag, items, tail in (("prom_a", a_items, a_tail), ("prom_c", c_items, c_tail)):
        prose = [l.rstrip() for _, p_, _ in items for l in p_
                 if l.strip().startswith(";")]
        prose += [l.rstrip() for l in tail if l.strip().startswith(";")]
        missing = [l for l in prose if l not in kset and l not in CORRECTIONS]
        check("%s: all %d comment lines present verbatim (%d deliberate correction%s)"
              % (tag, len(prose), len(CORRECTIONS) if tag == "prom_a" else 0,
                 "" if len(CORRECTIONS) == 1 else "s"),
              not missing, "" if not missing else "missing %d, first: %s"
              % (len(missing), missing[0][:60]))

    # 1b. THE REVERSE.  Every comment line in the merged file must come from one
    #     of the two blocks, from this tool's own header, or be one of the three
    #     kinds of line the merge adds.  Without this, "nothing was lost" would
    #     be checked and "nothing was invented" would not.
    origin = set()
    for items, tail in ((a_items, a_tail), (c_items, c_tail)):
        origin |= {l.rstrip() for _, p_, _ in items for l in p_}
        origin |= {l.rstrip() for l in tail}
    origin |= {l.rstrip() for l in kernel_header().split("\n")}
    origin |= {l for v in CORRECTIONS.values() for l in v}
    stray = []
    for l in kern:
        t = l.rstrip()
        if not t.strip().startswith(";"):
            continue
        if t in origin or t in (BANNER_A, BANNER_C):
            continue
        stray.append(t)
    check("no comment line in kernel.s came from anywhere but the two blocks and"
          " this tool's header", not stray,
          "" if not stray else "%d stray, first: %s" % (len(stray), stray[0][:70]))

    # 2. labels.  Both files' names, minus the one documented collision.
    lm = label_map()
    defined = set()
    for l in kern:
        m = LABEL_RE.match(l)
        if m:
            defined.add(m.group(1))
    want = {n for a, v in lm.items() for n, _ in v
            if DROPPED_ALIASES.get(a) != n}
    check("every label of both blocks is defined in kernel.s (%d)" % len(want),
          want <= defined, str(sorted(want - defined))[:80])
    check("the one dropped alias is NOT defined",
          not (set(DROPPED_ALIASES.values()) & (defined - want)))

    # 3. ★ REVERSIBILITY.  Substituting each CPU's own values back into the
    #    shared line must reproduce what that CPU's file said.  The byte gate
    #    proves the BYTES; this proves the merged TEXT still says, to each
    #    processor, exactly what its own listing said.
    bd = byte_diff_map()
    kcode = {}
    for l in kern:
        m = ADDR_RE.search(l)
        if m and l.startswith("\t"):
            kcode[int(m.group(1), 16)] = code_of(l)
    bad_a = bad_c = 0
    checked = skipped = 0
    block_labels = {n for v in lm.values() for n, _ in v}
    for a, ai, ci in paired():
        if a not in kcode:
            continue
        text = kcode[a]
        if not (ai and ci):
            skipped += 1
            continue
        at, ct = code_of(ai[1]), code_of(ci[1])
        # ⚠ WHAT THIS CHECK CAN AND CANNOT SEE.  It compares LITERALS, so it can
        # only run where the two files chose the same mnemonic and neither line
        # names a label: `m_ld_rm MW8, ..., r4` against `extpfx3 0xD0, ..., 0x24`
        # is the same instruction spelled two ways and their literal sets differ
        # by construction, and `djnz8 b, <label>` against `djnz8 b, -11` differ
        # because one is position-independent.  Those slots are proved by the
        # byte gate and by --diffs, not here.
        if at.split()[0] != ct.split()[0] or \
           any(t in block_labels for t in re.findall(r'[A-Za-z_.][A-Za-z0-9_.]*',
                                                     at + " " + ct + " " + text)):
            skipped += 1
            continue
        for which, item, table in (("a", ai, dict(SYM_A, **sfr_equates())),
                                   ("c", ci, dict(SYM_C, **sfr_equates()))):
            def resolve(t):
                for name in sorted(table, key=len, reverse=True):
                    t = re.sub(r'(?<![\w.])%s(?![\w.])' % name, "0x%X" % table[name], t)
                # fold the arithmetic the shared source does at the use site,
                # e.g. KERNEL_READY_HEADS-4, so the two texts compare as numbers
                return re.sub(r'0x([0-9A-Fa-f]+)\s*([-+])\s*(\d+)',
                              lambda m: "0x%X" % (int(m.group(1), 16) +
                                                  (int(m.group(3)) if m.group(2) == "+"
                                                   else -int(m.group(3)))), t)
            back = resolve(text)
            orig = resolve(code_of(item[1]))
            if [v for _, _, v in literals(back)] == [v for _, _, v in literals(orig)]:
                checked += 1
                continue
            if which == "a":
                bad_a += 1
            else:
                bad_c += 1
            if bad_a + bad_c < 8:
                print("       0x%06X %s: shared %r  <-  %r" % (a, which, back, orig))
    check("substituting prom_a's equates back reproduces prom_a's literals", bad_a == 0,
          "%d mismatches" % bad_a)
    check("substituting prom_c's equates back reproduces prom_c's literals", bad_c == 0,
          "%d mismatches" % bad_c)
    check("...on the %d of %d slots where a literal comparison is possible;"
          " the other %d are the gate's" % (checked // 2, len(kcode), skipped),
          checked > 0)

    # 3b. ⚠ THE GATE MUST BE ABLE TO SEE AN EDIT TO THE SHARED FILE.  `make` only
    #     rebuilds what it knows is stale; while kernel/ was not a prerequisite,
    #     a corrected kernel.s left prom_c's object untouched and the gate passed
    #     on a stale build.  It cost a six-byte failure that survived its own fix.
    mk = open(os.path.join(ROOT, "Makefile")).read()
    for img in ("a", "c"):
        line = [l for l in mk.split("\n")
                if l.startswith("rebuilt_ROMs/wsa1_prom_%s.llvm.o:" % img)]
        check("Makefile: prom_%s's object depends on the shared kernel source" % img,
              bool(line) and ("KERNEL_SRC" in line[0] or "kernel/kernel.s" in line[0]),
              line[0] if line else "no rule found")

    # 4. the two images now include the shared file and no longer carry the block
    for rel, inc in ((A_SRC, "kernel_maincpu.inc"), (C_SRC, "kernel_subcpu.inc")):
        txt = "\n".join(now(rel))
        check("%s includes %s and kernel/kernel.s" % (rel, inc),
              inc in txt and 'include "kernel/kernel.s"' in txt)
        check("%s no longer writes the kernel out inline" % rel,
              "Kernel_Dispatch__drain_ticks:" not in txt)
    return 1 if fail else 0


def cmd_selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    # boundaries: FIRST and LAST line of each block, named rather than counted
    a_lines, c_lines = src(A_SRC), src(C_SRC)
    check("prom_a block starts at the section banner",
          a_lines[A_BLOCK_LINES[0] - 1].startswith("; ====="))
    check("prom_a block ends on the kernel's last `ret` (0xF85E89)",
          "F85E89" in a_lines[A_BLOCK_LINES[1] - 1])
    check("...and the line after it is NOT part of the kernel",
          "F85E8" not in a_lines[A_BLOCK_LINES[1]])
    check("prom_c block starts at the section banner",
          c_lines[C_BLOCK_LINES[0] - 1].startswith("; ====="))
    check("prom_c block ends on the kernel's last `ret` (0xF989EE)",
          "F989EE" in c_lines[C_BLOCK_LINES[1] - 1])

    p = paired()
    both = [x for x in p if x[1] and x[2]]
    check("941 slots over the union, 939 on both sides",
          (len(p), len(both)) == (941, 939), "%d / %d" % (len(p), len(both)))
    check("the FIRST slot is 0xF85606 / 0xF9816B", p[0][0] == A_LO)
    check("the LAST slot is 0xF85E89 / 0xF989EE and pairs on both sides",
          p[-1][0] == 0xF85E89 and p[-1][1] and p[-1][2])

    # the length model: lengths come from the gap to the next slot, and prom_a's
    # own hex comments are an independent witness for all 939 of them
    addrs = [a for a, _, _ in p]
    lens = instr_length_map(addrs)
    ra = rom("a")
    wrong = witnessed = 0
    for a, ai, ci in p:
        if not ai:
            continue
        got = hex_of(ai[1])
        if not got:
            # the three `.short`/`.long` data lines carry prose, not bytes
            continue
        want = " ".join("%02x" % b for b in ra[a - 0xF80000:a - 0xF80000 + lens[a]])
        if want != got:
            wrong += 1
        witnessed += 1
    check("slot lengths from the address gaps agree with prom_a's own hex column"
          " (%d lines carry one)" % witnessed, wrong == 0, "%d disagree" % wrong)

    bd = byte_diff_map()
    kinds = Counter(classify(a, ai[1], ci[1], bd[a])[0].split(":")[0]
                    for a, ai, ci in both)
    check("no pair is left UNRESOLVED", kinds["UNRESOLVED"] == 0,
          "%d" % kinds["UNRESOLVED"])
    check("the two ROMs differ on %d of the 941 slots" % sum(bd.values()),
          sum(bd.values()) > 0)

    lm = label_map()
    check("77 labelled addresses, prom_c's name first",
          len(lm) == 77, "%d" % len(lm))
    check("the LAST labelled address carries BOTH files' names",
          len(lm[max(lm)]) == 2, str(lm[max(lm)]))

    used = Counter()
    for a, ai, ci in both:
        kind, _ = classify(a, ai[1], ci[1], bd[a])
        if ":" in kind:
            for n in kind.split(":", 1)[1].split(","):
                used[n.split("-")[0]] += 1
    unused = [n for n, _, _, _ in SYMBOL_TABLE if not used.get(n)]
    check("every equate in SYMBOL_TABLE is actually used", not unused, str(unused))

    print()
    rc = cmd_verify()
    print()
    rr = cmd_reachability()
    print("\n%d structural checks, %d failures (verify: %s, reachability inputs: %s)"
          % (ok + fail, fail, "PASS" if rc == 0 else "FAIL",
             "PASS" if rr == 0 else "FAIL"))
    return 1 if (fail or rc or rr) else 0



# --- what the move did to the tree-wide documentation figures ----------------
def cmd_metrics():
    """Did the merge cost the tree any label or any header?

    ⚠ notes/wave7_documentation_metrics.py counts headers PER LABEL, and the two
    images used to define the same 46 kernel labels twice -- once each.  After
    the merge they are defined once, so its header and Evidence totals FALL by
    26 and 22.  That is DE-DUPLICATION, not loss, and the way to tell the two
    apart is to compare the set of label NAMES rather than the count of
    definitions.  This mode does both, from the pre-merge commit."""
    import shutil
    import tempfile
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import wave7_documentation_metrics as W

    tmp = tempfile.mkdtemp(prefix="kernel_join_metrics_")
    try:
        for tag, rel in (("prom_a", A_SRC), ("prom_c", C_SRC)):
            os.makedirs(os.path.join(tmp, tag), exist_ok=True)
            open(os.path.join(tmp, tag, os.path.basename(rel)), "w").write(
                "\n".join(src(rel)))
        for tag in ("prom_b", "prom_d"):
            os.symlink(os.path.join(ROOT, tag), os.path.join(tmp, tag))

        def measure(root, images):
            W.ROOT = root
            h = e = 0
            names = set()
            for tag, sfile, _b in images:
                n, f, u, i, br, hh, ee = W.scan("%s/%s" % (tag, sfile))
                h, e = h + hh, e + ee
                for grp in (n, f, u, i, br):
                    names |= {x[0] for x in grp}
            return h, e, names

        # the pre-merge tree had no kernel/ row; the post-merge one must
        four = [r for r in W.IMAGES if r[0] != "kernel"]
        pre = measure(tmp, four)
        post = measure(ROOT, W.IMAGES)
    finally:
        W.ROOT = ROOT
        shutil.rmtree(tmp, ignore_errors=True)

    print("                       pre-merge (%s)   now" % PRE_MERGE)
    print("  headers                    %6d   %6d   %+d" % (pre[0], post[0], post[0] - pre[0]))
    print("  Evidence lines             %6d   %6d   %+d" % (pre[1], post[1], post[1] - pre[1]))
    print("  distinct label NAMES       %6d   %6d   %+d"
          % (len(pre[2]), len(post[2]), len(post[2]) - len(pre[2])))
    lost, gained = sorted(pre[2] - post[2]), sorted(post[2] - pre[2])
    print("\n  names LOST:   %d %s" % (len(lost), lost[:6]))
    print("  names GAINED: %d %s" % (len(gained), gained[:6]))
    print("\n  ★ The header and Evidence figures fall because the two images used to")
    print("    define the same kernel labels TWICE, once each, and each definition")
    print("    carried its own header.  No NAME is lost, which is the check that")
    print("    distinguishes de-duplication from destruction.")
    return 1 if lost else 0



# --- did the move change what the coverage tool SEES? ------------------------
def cmd_reachability():
    """notes/reachability.py's inputs, before the merge and after.

    ⚠ THIS IS THE CHECK THAT MATTERS, and it is cheap where the full walk is not.
    reachability.py decides coverage from two things per image: the set of
    addresses the source already PROVES are instructions, and the `.incbin`
    spans that are still unconverted.  The merge moved 941 instruction lines out
    of prom_a and prom_c into a file whose line shape neither image uses, so if
    the tool had not been taught about kernel/kernel.s it would have lost 938
    proven addresses per image and every downstream figure would have moved --
    silently, because a smaller proven set produces a plausible-looking result.

    Comparing the INPUTS before and after settles it exactly: if they are equal,
    the walk cannot produce a different answer, and no walk needs re-running.
    """
    import shutil
    import tempfile
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import reachability as R

    now_in = {t: R.proven_and_incbin(t) for t in ("prom_a", "prom_b", "prom_c")}

    tmp = tempfile.mkdtemp(prefix="kernel_join_reach_")
    real_source_lines = R.source_lines
    try:
        pre_text = {A_SRC: src(A_SRC), C_SRC: src(C_SRC)}

        def pre_source_lines(tag):
            path = dict((t, s_) for t, s_, _f, _b in R.IMAGES)[tag]
            if path in pre_text:
                return pre_text[path]          # ⚠ and NO shared file appended
            return real_source_lines(tag)

        R.source_lines = pre_source_lines
        pre_in = {t: R.proven_and_incbin(t) for t in ("prom_a", "prom_b", "prom_c")}
    finally:
        R.source_lines = real_source_lines
        shutil.rmtree(tmp, ignore_errors=True)

    bad = 0
    for t in ("prom_a", "prom_b", "prom_c"):
        pr, sp = now_in[t]
        bpr, bsp = pre_in[t]
        add, rem = sorted(pr - bpr), sorted(bpr - pr)
        gone = sorted(set(bsp) - set(sp))
        new = sorted(set(sp) - set(bsp))
        print("%-7s proven %6d -> %6d   .incbin %6d -> %6d bytes"
              % (t, len(bpr), len(pr),
                 sum(h - l for l, h in bsp), sum(h - l for l, h in sp)))
        if add:
            print("        proven GAINED: %s" % [hex(x) for x in add])
        if rem:
            print("        ⚠ proven LOST: %s" % [hex(x) for x in rem][:8])
            bad += 1
        if gone:
            print("        .incbin span CONVERTED: %s"
                  % [(hex(l), hex(h)) for l, h in gone])
        if new:
            print("        ⚠ .incbin span ADDED: %s"
                  % [(hex(l), hex(h)) for l, h in new])
            bad += 1
    print("\n  Expected, and the only difference there should be: prom_a gains the two")
    print("  instructions at 0xF85C3D and 0xF85C42 and loses the 7-byte .incbin that")
    print("  held them.  Anything else means a tool stopped seeing the kernel.")
    return 1 if bad else 0


if __name__ == "__main__":
    if "--diffs" in sys.argv:
        sys.exit(cmd_diffs())
    if "--symbols" in sys.argv:
        sys.exit(cmd_symbols())
    if "--emit" in sys.argv:
        sys.exit(cmd_emit())
    if "--verify" in sys.argv:
        sys.exit(cmd_verify())
    if "--metrics" in sys.argv:
        sys.exit(cmd_metrics())
    if "--reachability" in sys.argv:
        sys.exit(cmd_reachability())
    if "--selftest" in sys.argv:
        sys.exit(cmd_selftest())
    sys.exit(cmd_pairs())
