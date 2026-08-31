#!/usr/bin/env python3
"""prom_c 0xF9816B-0xF989EE: is it really prom_a's kernel, and is the RAM map right?

QUESTION IT ANSWERS
  Two questions, and every quantified claim in the `0xF9816B-0xF989EE` block comment
  and in the 28 routine headers under it comes from one of them:

  (3) --callers "Which of the kernel's published entry points does anything in prom_c
               actually call?"  Runs prom_c_xrefs.py over every entry, pairs each
               stack face with its register face, and EXCLUDES the five entries that
               are reached by RESET's `jp`, by falling through or by a `jrl` -- which
               prom_c_xrefs.py cannot see, and which would otherwise be miscounted as
               unused.  This is where the "N entries have no caller" figure comes
               from; it is a searched negative and says so.

  (1) --map    "What arrays does Kernel_InitRam create, how many entries does each
               have, and do they TILE their address range with no gap and no
               overlap?"  The bases and the counts are read out of the INSTRUCTION
               BYTES, not out of a disassembly and not out of the .s file, so the
               header cannot drift away from the ROM.  The tiling is the check that
               makes the counts something better than a reading: nine arrays whose
               sizes are literal `ldb b,N` operands have to add up to the distance
               between their literal bases, and here they do -- 0x0100 to 0x0184
               exactly.

  (2) --pairs  "Is each prom_c routine the SAME routine as the prom_a one at the
               matching slot?"  Runs prom_c_prom_a_routine_diff.py over all 36 pairs
               -- the 35 contiguous rows of PAIRS plus INTT3_KernelTick, which sits
               just BELOW the block and so cannot be part of the tiling -- and prints
               slots / identical / operand-only / STRUCTURAL for each.  A pair that
               breaks the tiling, or that has a structural difference the table does
               not expect, is a FAILURE and the script exits non-zero.
               (* CORRECTED 2026-08-25, round-2 audit F6: this said "35 pairs" while
               do_pairs has always run 36 and printed 36.)

               *** WHAT --pairs DOES NOT PROVE.  The length column is ONE number used
               for BOTH images, so "the two routines have the same length" is an INPUT
               to the comparison and never an output of it.  What is checked is that
               the table's own addresses and lengths TILE each block with no gap and no
               overlap -- from the first row through the LAST, whose end is checked
               against the published block end in both images -- and that every row's
               prom_c-minus-prom_a difference is the SAME constant 0x12B65.  Those two
               together are why the shared length column is defensible; a reader who
               wants the boundaries proved from the ROM instead wants a decoder, and
               this is not one.

  --selftest runs both, and asserts the LAST pair of the table as well as the first
  (the boundary this tree has got wrong before), plus the four semaphore counts, the
  eight-byte boot software-timer request, and the bound on EntryPoint_Records' level
  column.

RUN
  python3 notes/prom_c_kernel_map.py --map
  python3 notes/prom_c_kernel_map.py --pairs
  python3 notes/prom_c_kernel_map.py --callers
  python3 notes/prom_c_kernel_map.py --selftest

WHAT IT CANNOT DO
  --pairs compares unidasm's TEXT, exactly as prom_c_prom_a_routine_diff.py does; see
  that script's own warning.  A "0 structural differences" row means the two
  disassemblies use the same mnemonics in the same order, which is strong evidence
  that two routines are the same routine and is not a proof.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROM_C = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
PROM_C_BASE = 0xF80000
DIFF = os.path.join(ROOT, "notes", "prom_c_prom_a_routine_diff.py")

ROM = open(PROM_C, "rb").read()


def at(addr, n):
    return ROM[addr - PROM_C_BASE: addr - PROM_C_BASE + n]


def le16(addr):
    b = at(addr, 2)
    return b[0] | (b[1] << 8)


def le32(addr):
    b = at(addr, 4)
    return b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)


# --------------------------------------------------------------------------
# (1) the RAM map, read out of Kernel_InitRam's bytes
# --------------------------------------------------------------------------
# Each row: (address of the base-loading instruction, its expected opcode bytes,
#            address of the `ldb b,N` count, element size, what it is).
# `ldw hl,imm16` = 33 lo hi ; `ldw ix,imm16` = 34 lo hi ; `ldw iy,imm16` = 35 lo hi
# `ldb b,imm8`   = 22 nn
LOADW = {0x33: "hl", 0x34: "ix", 0x35: "iy"}

MAP_ROWS = [
    # base insn, count insn (None = a fixed 1), stride, name
    (0xF9818F, 0xF98194, 12, "task control blocks       (+9 state := 0)"),
    (0xF9817A, 0xF98182, 4,  "ready-queue heads         (self-linked)"),
    (0xF981C7, 0xF981CC, 4,  "semaphore wait queues     (self-linked)"),
    (None,     None,     1,  "semaphore counts          (ldir from ROM 0xF9810E)"),
    (0xF9821A, 0xF9821F, 4,  "message WAIT queues       (self-linked)"),
    (0xF9822C, 0xF98231, 4,  "MESSAGE queues            (self-linked)"),
    (0xF981D9, 0xF981DE, 8,  "free nodes                (+4 := 0xFFFFFFFF)"),
    (0xF981EF, None,     4,  "free-list head            (self-linked)"),
    (0xF981A2, 0xF981A7, 8,  "software timers           (+4 := 0xFFFFFFFF)"),
]

# the ldir that installs the semaphore counts: ld XHL,imm32 / ldw de,imm16 / extz
# xde / ldw bc,imm16 / ldir
LDIR_SRC = 0xF981B8      # 43 0e 81 f9 00      ld XHL,0x00F9810E
LDIR_DST = 0xF981BD      # 32 3c 01            ldw de,0x013C
LDIR_CNT = 0xF981C2      # 31 04 00            ldw bc,0x0004


def read_base(addr):
    op = at(addr, 1)[0]
    if op not in LOADW:
        raise SystemExit("FAIL: 0x%06X is 0x%02X, not a 16-bit immediate load" % (addr, op))
    return le16(addr + 1)


def read_count(addr):
    if at(addr, 1)[0] != 0x22:
        raise SystemExit("FAIL: 0x%06X is not `ldb b,imm8`" % addr)
    return at(addr, 2)[1]


def do_map(verbose=True):
    if at(LDIR_SRC, 1)[0] != 0x43 or at(LDIR_DST, 1)[0] != 0x32 or at(LDIR_CNT, 1)[0] != 0x31:
        raise SystemExit("FAIL: the semaphore-count ldir is not the expected three loads")
    sema_src = le32(LDIR_SRC + 1) & 0xFFFFFF
    sema_dst = le16(LDIR_DST + 1)
    sema_cnt = le16(LDIR_CNT + 1)

    rows = []
    for base_a, cnt_a, stride, what in MAP_ROWS:
        if base_a is None:
            base, cnt = sema_dst, sema_cnt
        else:
            base = read_base(base_a)
            cnt = 1 if cnt_a is None else read_count(cnt_a)
        rows.append((base, cnt, stride, what))
    rows.sort(key=lambda r: r[0])

    if verbose:
        print("Kernel_InitRam's RAM map, read out of the instruction bytes")
        print("  semaphore-count image: ROM 0x%06X -> RAM 0x%04X, %d byte(s)"
              % (sema_src, sema_dst, sema_cnt))
        print()
        print("   base    n  stride  end     what")
    ok = True
    prev_end = None
    for base, cnt, stride, what in rows:
        end = base + cnt * stride
        if verbose:
            print("  0x%04X %3d   %2d    0x%04X  %s" % (base, cnt, stride, end, what))
        if prev_end is not None and base != prev_end:
            ok = False
            if verbose:
                print("     ^^ GAP/OVERLAP: previous array ended at 0x%04X" % prev_end)
        prev_end = end
    lo, hi = rows[0][0], prev_end
    if verbose:
        print()
        print("  the nine arrays tile 0x%04X-0x%04X with %s"
              % (lo, hi - 1, "NO gap and NO overlap" if ok else "A GAP OR OVERLAP"))
    if not ok:
        raise SystemExit("FAIL: the arrays do not tile")
    if (lo, hi) != (0x0100, 0x0184):
        raise SystemExit("FAIL: expected the map to cover 0x0100-0x0183, got 0x%04X-0x%04X"
                         % (lo, hi - 1))
    return rows, (sema_src, sema_dst, sema_cnt)


# --------------------------------------------------------------------------
# (2) the 36 routine pairs: 35 contiguous rows here + INTT3_PAIR below
# --------------------------------------------------------------------------
# prom_c address, prom_a address, length, name.
# *** ONE length column serves BOTH images, so equal lengths are ASSUMED, not measured
# (round-2 audit F6).  do_pairs() checks the two things that make the assumption
# defensible and fails loudly if either breaks: (a) the rows TILE, i.e. every row ends
# exactly where the next begins in BOTH images and the LAST row ends exactly at the
# published end of the block in both; (b) every row's prom_c-minus-prom_a difference is
# the same constant BLOCK_DELTA.  A wrong boundary then shows up as a tiling failure.
PAIRS = [
    (0xF9816B, 0xF85606, 0xE6, "Kernel_InitRam", 2),
    (0xF98251, 0xF856EC, 0x25, "Kernel_Start", 0),
    (0xF98276, 0xF85711, 0x04, "Kernel_Idle", 0),
    (0xF9827A, 0xF85715, 0x4E, "Kernel_Dispatch", 0),
    (0xF982C8, 0xF85763, 0x09, "Kernel_ResumeTask", 0),
    (0xF982D1, 0xF8576C, 0x4B, "Kernel_ServiceSoftTimers", 0),
    (0xF9831C, 0xF857B7, 0x1F, "IRQ_Epilogue", 0),
    (0xF9833B, 0xF857D6, 0x03, "Kernel_StartTask_StackArg", 0),
    (0xF9833E, 0xF857D9, 0x71, "Kernel_StartTask", 0),
    (0xF983AF, 0xF8584A, 0x2A, "Kernel_ExitTask", 0),
    (0xF983D9, 0xF85874, 0x03, "Kernel_YieldRotate_StackArg", 0),
    (0xF983DC, 0xF85877, 0x49, "Kernel_YieldRotate", 0),
    (0xF98425, 0xF858C0, 0x44, "Kernel_RotateQueue", 0),
    (0xF98469, 0xF85904, 0x26, "Kernel_BlockSelf", 0),
    (0xF9848F, 0xF8592A, 0x03, "Kernel_ReadyTask_StackArg", 0),
    (0xF98492, 0xF8592D, 0x40, "Kernel_ReadyTask", 0),
    (0xF984D2, 0xF8596D, 0x3E, "Kernel_ReadyTask_NoDispatch", 0),
    (0xF98510, 0xF859AB, 0x03, "Kernel_SemaSignal_StackArg", 0),
    (0xF98513, 0xF859AE, 0x6E, "Kernel_SemaSignal", 0),
    (0xF98581, 0xF85A1C, 0x06, "Kernel_SemaSignal_NoDispatch_StackArg", 0),
    (0xF98587, 0xF85A22, 0x71, "Kernel_SemaSignal_NoDispatch", 0),
    (0xF985F8, 0xF85A93, 0x03, "Kernel_SemaWait_StackArg", 0),
    (0xF985FB, 0xF85A96, 0x59, "Kernel_SemaWait", 0),
    (0xF98654, 0xF85AEF, 0x1E, "Kernel_SemaTryWait", 0),
    (0xF98672, 0xF85B0D, 0x12, "MsgQueue_Send_StackArg", 0),
    (0xF98684, 0xF85B1F, 0xB5, "MsgQueue_Send", 0),
    (0xF98739, 0xF85BD4, 0xB5, "MsgQueue_Send_NoDispatch", 0),
    (0xF987EE, 0xF85C89, 0x03, "MsgQueue_ReceiveBlocking_StackArg", 0),
    (0xF987F1, 0xF85C8C, 0x90, "MsgQueue_ReceiveBlocking", 0),
    (0xF98881, 0xF85D1C, 0x5C, "MsgQueue_Receive_NoBlock", 0),
    (0xF988DD, 0xF85D78, 0x2A, "SoftTimer_Register", 0),
    (0xF98907, 0xF85DA2, 0x06, "Kernel_SetTaskLevel_StackArg", 0),
    (0xF9890D, 0xF85DA8, 0x5A, "Kernel_SetTaskLevel", 0),
    (0xF98967, 0xF85E02, 0x59, "Kernel_SetTaskLevel_NoDispatch", 0),
    (0xF989C0, 0xF85E5B, 0x2F, "Kernel_KillTask_StackArg", 0),
]
# Kernel_InitRam is the one row that expects structural differences: BOTH images
# embed an 8-byte software-timer request block inside the code stream, and an
# instruction decoder renders the two blocks as two different pieces of nonsense.
# 2 is that block, and nothing else.

INTT3_PAIR = (0xF98165, 0xF85600, 0x06, "INTT3_KernelTick", 0)

# The two blocks are the same code relocated by a constant, and the LAST row has to end
# exactly at the block end -- the element this tree has got wrong before.
BLOCK_DELTA = 0x12B65               # prom_c address - prom_a address, every row
BLOCK_END_C = 0xF989EF              # one past 0xF989EE, the published end of the block
BLOCK_END_A = BLOCK_END_C - BLOCK_DELTA


def run_pair(ca, aa, n):
    p = subprocess.run([sys.executable, DIFF, hex(ca), hex(aa), hex(n)],
                       capture_output=True, text=True)
    got = {}
    for line in p.stdout.splitlines():
        if "instruction slots compared:" in line:
            got["slots"] = int(line.split(":")[1].split()[0])
        elif "identical text:" in line:
            got["same"] = int(line.split(":")[1].strip())
        elif "same mnemonic, different operand:" in line:
            got["operand"] = int(line.split(":")[1].strip())
        elif "DIFFERENT MNEMONIC:" in line:
            got["struct"] = int(line.split(":")[1].split()[0])
    if len(got) != 4:
        raise SystemExit("FAIL: could not parse the diff of 0x%06X" % ca)
    return got


def do_pairs(verbose=True):
    rows = PAIRS + [INTT3_PAIR]
    # the lengths must be the distance to the next entry, in BOTH images.  The LAST
    # row is checked too, against the published end of the block -- before 2026-08-25
    # the loop stopped one short and the final row's length was unchecked entirely.
    for i in range(len(PAIRS)):
        ca, aa, n, name, _ = PAIRS[i]
        if i + 1 < len(PAIRS):
            nc, na = PAIRS[i + 1][0], PAIRS[i + 1][1]
        else:
            nc, na = BLOCK_END_C, BLOCK_END_A
        if ca + n != nc or aa + n != na:
            raise SystemExit("FAIL: %s does not end where the next entry begins "
                             "(prom_c 0x%06X+0x%X vs 0x%06X, prom_a 0x%06X+0x%X vs 0x%06X)"
                             % (name, ca, n, nc, aa, n, na))
    # and every row is the same routine relocated by ONE constant
    for ca, aa, n, name, _ in rows:
        if ca - aa != BLOCK_DELTA:
            raise SystemExit("FAIL: %s is offset by 0x%X, not the block's 0x%X"
                             % (name, ca - aa, BLOCK_DELTA))
    if verbose:
        print("prom_c kernel routines against prom_a's, instruction by instruction")
        print("  %-38s %6s %6s %8s %9s" % ("routine", "slots", "same", "operand", "STRUCT"))
    bad = 0
    for ca, aa, n, name, expect in rows:
        g = run_pair(ca, aa, n)
        flag = "" if g["struct"] == expect else "   <-- UNEXPECTED"
        if g["struct"] != expect:
            bad += 1
        if verbose:
            print("  %-38s %6d %6d %8d %9d%s"
                  % (name, g["slots"], g["same"], g["operand"], g["struct"], flag))
    if verbose:
        print()
        print("  %d pair(s) (35 tiling rows + INTT3_KernelTick); "
              "%d with an unexpected structural difference" % (len(rows), bad))
        print("  all %d offset by the one constant 0x%X; the last row ends at "
              "prom_c 0x%06X / prom_a 0x%06X, the published block ends"
              % (len(rows), BLOCK_DELTA, BLOCK_END_C, BLOCK_END_A))
        print("  ⚠ the length column is shared by both images -- see the module "
              "docstring for what that does and does not prove")
        print("  (Kernel_InitRam's 2 are the 8-byte inline SoftTimer_Request_Boot block,")
        print("   which is data in both images -- see its header in prom_c/wsa1_prom_c.s)")
    if bad:
        raise SystemExit("FAIL: %d pair(s) differ structurally" % bad)
    return len(rows)


# --------------------------------------------------------------------------
# (3) which kernel entry points are actually called from prom_c
# --------------------------------------------------------------------------
# One row per PUBLISHED entry (the internal `__` labels are not entries).  Where a
# routine has a stack face and a register face they are one row with two addresses:
# a caller uses one or the other, so "is this routine used" is the OR of the two.
XREFS = os.path.join(ROOT, "notes", "prom_c_xrefs.py")

ENTRIES = [
    ("Kernel_InitRam",                [0xF9816B], "RESET + IRQ_UNUSED"),
    ("Kernel_Start",                  [0xF98251], "fallen into"),
    ("Kernel_Idle",                   [0xF98276], "jr from Kernel_Dispatch__scan"),
    ("Kernel_Dispatch",               [0xF9827A], "jrl, ten sites in the block"),
    ("Kernel_ResumeTask",             [0xF982C8], "jrl + fall-through"),
    ("Kernel_ServiceSoftTimers",      [0xF982D1], ""),
    ("IRQ_Epilogue",                  [0xF9831C], "jrl from INTT3_KernelTick"),
    ("Kernel_StartTask",              [0xF9833B, 0xF9833E], ""),
    ("Kernel_ExitTask",               [0xF983AF], ""),
    ("Kernel_YieldRotate",            [0xF983D9, 0xF983DC], ""),
    ("Kernel_RotateQueue",            [0xF98425], "one UNVERIFIED calr candidate"),
    ("Kernel_BlockSelf",              [0xF98469], ""),
    ("Kernel_ReadyTask",              [0xF9848F, 0xF98492], ""),
    ("Kernel_ReadyTask_NoDispatch",   [0xF984D2], ""),
    ("Kernel_SemaSignal",             [0xF98510, 0xF98513], ""),
    ("Kernel_SemaSignal_NoDispatch",  [0xF98581, 0xF98587], ""),
    ("Kernel_SemaWait",               [0xF985F8, 0xF985FB], ""),
    ("Kernel_SemaTryWait",            [0xF98654], ""),
    ("MsgQueue_Send",                 [0xF98672, 0xF98684], ""),
    ("MsgQueue_Send_NoDispatch",      [0xF98739], ""),
    ("MsgQueue_ReceiveBlocking",      [0xF987EE, 0xF987F1], ""),
    ("MsgQueue_Receive_NoBlock",      [0xF98881], ""),
    ("SoftTimer_Register",            [0xF988DD], ""),
    ("Kernel_SetTaskLevel",           [0xF98907, 0xF9890D], ""),
    ("Kernel_SetTaskLevel_NoDispatch",[0xF98967], ""),
    ("Kernel_KillTask",               [0xF989C0, 0xF989C3], ""),
]

# The five entries reached WITHOUT a call/calr -- by RESET's `jp`, by falling
# through, or by a `jrl` from inside the block.  prom_c_xrefs.py finds literal
# addresses and `calr` displacements; it does NOT search `jrl`, so these five would
# read as zero and must not be counted as unused.  Each one's route is named in its
# header and in the third column above.
NOT_BY_CALL = {"Kernel_Start", "Kernel_Idle", "Kernel_Dispatch",
               "Kernel_ResumeTask", "IRQ_Epilogue"}


def count_sites(addr):
    p = subprocess.run([sys.executable, XREFS, hex(addr), "--no-window"],
                       capture_output=True, text=True)
    lit = calr = None
    for line in p.stdout.splitlines():
        if "TOTAL literal-addressed sites:" in line:
            lit = int(line.split(":")[1].split()[0])
            calr = int(line.rsplit("CALR:", 1)[1].strip())
    if lit is None:
        raise SystemExit("FAIL: could not parse prom_c_xrefs.py for 0x%06X" % addr)
    return lit, calr


def do_callers(verbose=True):
    if verbose:
        print("kernel entry points, and whether anything in prom_c calls them")
        print("  %-32s %5s %5s  %s" % ("routine", "lit", "calr", "note"))
    unused = []
    for name, addrs, note in ENTRIES:
        lit = calr = 0
        for a in addrs:
            l, c = count_sites(a)
            lit += l
            calr += c
        if verbose:
            print("  %-32s %5d %5d  %s" % (name, lit, calr, note))
        if lit + calr == 0 and name not in NOT_BY_CALL:
            unused.append(name)
    if verbose:
        print()
        print("  %d published entry point(s); %d reached by something other than a"
              % (len(ENTRIES), len(NOT_BY_CALL)))
        print("  call/calr and excluded; %d with NO call site found in prom_c:" % len(unused))
        for n in unused:
            print("      %s" % n)
        print()
        print("  ⚠ prom_c_xrefs.py does not see a target computed at run time, and does")
        print("    not search `jrl`.  'no call site found' is a searched negative.")
    return unused


# --------------------------------------------------------------------------
def selftest():
    rows, (src, dst, cnt) = do_map(verbose=False)

    # the semaphore counts themselves
    counts = list(at(src, cnt))
    assert counts == [0x01, 0x00, 0x01, 0x01], counts
    assert (src, dst, cnt) == (0xF9810E, 0x013C, 4)

    # the boot software-timer request block, and that the `jr` steps over it
    assert at(0xF9823E, 1)[0] == 0x44 and le32(0xF9823F) & 0xFFFFFF == 0xF98245
    assert at(0xF98243, 2) == b"\x68\x08"          # jr +8 -> 0xF9824D
    assert le16(0xF98245) == 1 and le16(0xF98247) == 1
    assert le32(0xF98249) == 0x00F98112             # the callback
    assert at(0xF9824D, 1)[0] == 0x1D and le32(0xF9824E) & 0xFFFFFF == 0xF988DD

    # EntryPoint_Records: three records, and every level indexes INSIDE the two
    # ready queues the map above found.
    nqueues = [r[1] for r in rows if r[0] == 0x0124][0]
    levels = [le16(0xF980EA + i * 12 + 10) for i in range(3)]
    assert levels == [2, 2, 1], levels
    assert all(1 <= v <= nqueues for v in levels), (levels, nqueues)
    # ... and a FOURTH record would have no task control block: 3 blocks, stride 12
    ntcb = [r[1] for r in rows if r[0] == 0x0100][0]
    assert ntcb == 3

    # the two "unreferenced trampoline" targets that land mid-instruction
    assert at(0xF9860F, 3) == b"\x80\x3f\x00"       # cp (XWA),0x00 -- 0xF98610 is inside it
    assert at(0xF9854C, 3) == b"\x9c\x00\x20"       # ld WA,(XIX+0) -- 0xF9854E is inside it

    unused = do_callers(verbose=False)
    assert "MsgQueue_Send" in unused and "Kernel_KillTask" in unused, unused
    assert "Kernel_SemaWait" not in unused and "Kernel_SemaTryWait" not in unused, unused

    # the two counts the kernel headers quote for the scheduler's entry points, and
    # the one-0x09 argument in Kernel_ReadyTask.  ⚠ A first draft of those headers
    # said "ten sites" (it is 13) and gave the 0x09 address as "0xF98493+...".
    import struct as _s

    def jump_sites(target, lo=0xF9816B, hi=0xF989EE):
        out = []
        for a in range(lo, hi):
            b = at(a, 1)[0]
            if b == 0x68 and a + 2 + _s.unpack("<b", at(a + 1, 1))[0] == target:
                out.append(a)
            elif b in (0x78, 0x76, 0x7E) and a + 3 + _s.unpack("<h", at(a + 1, 2))[0] == target:
                out.append(a)
        return out

    disp = jump_sites(0xF9827A)
    resume = jump_sites(0xF982C8)
    assert len(disp) == 13, [hex(x) for x in disp]
    assert len(resume) == 8, [hex(x) for x in resume]
    rt = at(0xF98492, 0x40)
    nines = [0xF98492 + i for i, x in enumerate(rt) if x == 0x09]
    assert nines == [0xF984A8], [hex(x) for x in nines]
    assert at(0xF984A7, 4) == b"\x8c\x09\x3f\x03", "the 0x09 is the guard's displacement"

    n = do_pairs(verbose=False)
    assert n == 36, n
    # explicitly re-run the LAST pair of the table on its own
    last = PAIRS[-1]
    g = run_pair(last[0], last[1], last[2])
    assert g["struct"] == 0 and g["slots"] == 23, (last[3], g)

    print("SELFTEST PASS")
    print("  RAM map tiles 0x0100-0x0183 over 9 arrays, no gap, no overlap")
    print("  semaphore counts 01 00 01 01 from ROM 0xF9810E, 4 bytes, to RAM 0x013C")
    print("  SoftTimer_Request_Boot = {1, 1, 0x00F98112}, stepped over by `jr +8`")
    print("  EntryPoint_Records levels %s, all inside the %d ready queues" % (levels, nqueues))
    print("  %d routine pairs against prom_a, last one (%s) re-checked alone"
          % (n, last[3]))
    print("  %d of %d published entry points have no call site in prom_c"
          % (len(unused), len(ENTRIES)))
    print("  Kernel_Dispatch is entered by %d jumps, Kernel_ResumeTask by %d, and"
          % (len(disp), len(resume)))
    print("  Kernel_ReadyTask contains the byte 0x09 exactly once, at 0xF984A8")


def main():
    args = sys.argv[1:]
    if "--selftest" in args:
        selftest()
    elif "--pairs" in args:
        do_pairs()
    elif "--map" in args:
        do_map()
    elif "--callers" in args:
        do_callers()
    else:
        print(__doc__)
        return 2
    return 0


sys.exit(main())
