#!/usr/bin/env python3
r"""label_v142_task_kernel_entries.py -- six task-kernel routines of the sub-CPU v1.42 payload had no entry label.

QUESTION THIS ANSWERS / WHAT IT DOES
    In kn5000_subprogram_v142.s six routines of the task kernel start right after another
    routine's unconditional `jrl TaskSched_Dispatch` / `jrl TaskSched_ContextRestore` with no
    label, although some of their internal labels (TaskSem_TryDec_WouldBlock,
    TaskMsgQ_Send_Guard_*, Task_Reassign_*) and one header (TaskSem_GetCount: "TaskSem_TryDec
    (0x0204A9) is the non-blocking one") already name them.  None has a caller in v1.42 (their
    addresses occur nowhere as 3-byte LE values, and no calr displacement lands on them): they
    are library entry points this build does not use.  Each gets a label and a header written
    from its instructions; three have main-CPU twins (v142_maincpu_shared_code_scan.py).
    Each anchor is matched on the exact instruction before and at the entry, so a drifted
    source is refused.  Labels emit no bytes; `make gate` still certifies.

RUN
    python3 scripts/renaming/label_v142_task_kernel_entries.py --apply ; make gate
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
P = os.path.join(ROOT, "v142/subcpu/kn5000_subprogram_v142.s")

# (text that must end the previous routine + the entry's first lines, label, header lines)
SITES = [
    ("\tjrl TaskSched_Dispatch\n\tei 6\n\tld xsp, 0x40B1E\n", "TaskSched_ExitCurrentTask", [
        "; Terminate the calling task: back on the scheduler stack (SP = 0x40B1E, the value",
        "; TaskSched_Init uses), the current TCB (pointer at 0x1046) gets state +0x09 = 0 and pending",
        "; count +0x0A = 0, 0x1046 is cleared, the TCB is unlinked from its queue and",
        "; TaskSched_Dispatch picks the next task.  No caller in v1.42."]),
    ("\tjrl TaskSched_Dispatch\n\tld hl, (4306:16)\n", "TaskSched_GetCurrentTaskId", [
        "; HL = the running task's id (TCB +0x0B, the byte TaskSched_SpawnTask stores), or 0 when the",
        "; scheduler lock depth at 0x10D2 is non-zero.  No caller in v1.42."]),
    ("\tjrl TaskSched_Dispatch\n\textz wa\n\tadd wa, 0x1091\n", "TaskSem_TryDec", [
        "; Non-blocking P() on semaphore A: under interrupt level 6, if the count at 0x1091 + A is 0",
        "; return HL = 0xFFFF, else decrement it and return HL = 0.  Named in TaskSem_GetCount's header;",
        "; no caller in v1.42."]),
    ("\tjrl TaskSched_Dispatch\n\tpush xwa\n\tpush xix\n\tpush xiy\n\tpush xiz\n\tpush xhl\n\tpush xbc\n\tld xiz, xbc\n",
     "TaskMsgQ_Send_NoResched", [
        "; TaskMsgQ_Send without rescheduling: saves six registers instead of the full context frame,",
        "; then the same queue logic (waiter list 0x1092 + 4*A, message list 0x109A + 4*A, free nodes",
        "; at 0x10C6); a waiting receiver is made READY and linked, and the routine RETURNS to its",
        "; caller.  Main-CPU twin: TaskMsg_Send_NB.  No caller in v1.42."]),
    ("\tjrl TaskSched_Dispatch\n\tpush\tsr\n\tei 6\n\tpush xhl\n\tpush xwa\n\tpush xbc\n\tpush xde\n\tpush xix\n\tpush xiy\n\tpush xiz\n\tld e, c\n",
     "TaskSched_ChangePriority", [
        "; Give task A priority C: TCB = 0x103C + 12*A.  If the task is READY (state +0x09 == 4) it is",
        "; unlinked, its priority byte +0x08 set and it is relinked at the tail of ready queue",
        "; 0x1068 + 4*C, then TaskSched_Dispatch runs; otherwise only +0x08 is written",
        "; (Task_Reassign_NotRunning).  Main-CPU twin: TaskSched_ChangePriority.  No caller in v1.42."]),
    ("\tjrl TaskSched_ContextRestore\n\tpush xwa\n\tpush xix\n\tpush xiy\n\tpush xhl\n\tpushw de\n\tld e, c\n",
     "TaskSched_ChangePriority_NoResched", [
        "; TaskSched_ChangePriority without the context frame and without rescheduling: the same",
        "; relink under `push sr / ei 6`, then return to the caller.  No caller in v1.42."]),
]


def main():
    t = open(P, "rb").read().decode("latin-1")
    for anchor, lab, hdr in SITES:
        if t.count(anchor) != 1:
            sys.exit("anchor for %s found %d times" % (lab, t.count(anchor)))
        first, rest = anchor.split("\n", 1)
        t = t.replace(anchor, first + "\n\n" + "\n".join(hdr) + "\n" + lab + ":\n" + rest)
    if "--apply" in sys.argv:
        open(P, "wb").write(t.encode("latin-1"))
        print("labelled %d entries" % len(SITES))
    else:
        print("all %d anchors found (dry run)" % len(SITES))


if __name__ == "__main__":
    main()
