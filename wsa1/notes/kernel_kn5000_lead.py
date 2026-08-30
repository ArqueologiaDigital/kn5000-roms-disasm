#!/usr/bin/env python3
"""Regenerates the LEAD (not the verdict) that the WSA1 kernel also runs on the KN5000 sub-CPU.

QUESTION IT ANSWERS: is there a routine family in the KN5000 v142 sub-CPU that corresponds,
routine for routine, to the shared kernel the WSA1's two CPUs run?

RUN:  python3 notes/kernel_kn5000_lead.py            # the correspondence table
      python3 notes/kernel_kn5000_lead.py --dispatch # the two dispatch bodies, side by side
      python3 notes/kernel_kn5000_lead.py --selftest

★ THIS IS A LEAD, NOT EVIDENCE. It is built from LABEL NAMES, and both trees were named by agents
  on this project -- so the correspondence may reflect a shared naming habit rather than shared
  code. The admissible instrument is notes/kernel_structural_match.py (lane A2), which matches
  INSTRUCTIONS and computes a null over all ~3,874 named KN5000 routines. Names only say where to
  point it. Do not cite this file as proof of anything.
"""
import os, re, sys

WSA1 = os.path.join(os.path.dirname(__file__), "..", "kernel", "kernel.s")
KN5000 = os.path.expanduser(
    "~/compartilhado/kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s")

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')

# Hand-made pairing. The RIGHT column is what a human read off the two files; it is the claim
# under test, deliberately kept as data so a verifier can disagree with any single row.
PAIRS = [
    ("Kernel_Dispatch",              "TaskSched_Dispatch"),
    ("Kernel_Dispatch__scan",        "TaskSched_Dispatch_ScanLoop"),
    ("Kernel_Dispatch__switch_to",   "TaskSched_Dispatch_SwitchTo"),
    ("Kernel_ResumeTask",            "TaskSched_ContextRestore"),
    ("Kernel_ServiceSoftTimers",     "TaskSched_SoftTimer_Service"),
    ("Kernel_ServiceSoftTimers__next", "TaskSched_SoftTimer_Next"),
    ("Kernel_ServiceSoftTimers__fire", "TaskSched_SoftTimer_Fire"),
    ("Kernel_Idle__loop",            "TaskSched_HaltLoop"),
    ("Kernel_StartTask",             "TaskSched_SpawnTask"),
    ("Kernel_YieldRotate",           "TaskSched_PreemptiveYield"),
    ("Kernel_RotateQueue",           "TaskQueue_Dequeue"),
    ("Kernel_BlockSelf",             "TaskSched_Block_Self_Consume"),
    ("Kernel_ReadyTask",             "TaskSched_Wake_Task"),
    ("Kernel_ReadyTask_NoDispatch",  "TaskSched_Wake_Task_NoResched"),
    ("Kernel_SemaSignal",            "TaskEvent_Signal"),
    ("Kernel_SemaSignal_NoDispatch", "TaskEvent_Signal_NoResched"),
    ("Kernel_SemaWait",              "TaskEvent_Wait"),
    ("Kernel_SemaTryWait__fail",     "TaskSem_TryDec_WouldBlock"),
    ("MsgQueue_Send",                "TaskMsgQ_Send"),
    ("Kernel_InitRam__tcbs",         "TaskSched_Init_TaskDescriptors"),
    ("Kernel_InitRam__free_nodes",   "TaskSched_Init_LinkFreeNodes"),
    ("Kernel_InitRam__ready_queues", "TaskSched_Init_QueueHeaders"),
]

def labels(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return {m.group(1) for m in (LABEL.match(l) for l in fh) if m}

def body(path, name, n=20):
    out, on = [], False
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = LABEL.match(line)
            if m and m.group(1) == name:
                on = True; continue
            if on:
                if m: break
                s = line.rstrip("\n")
                if s.strip() and not s.lstrip().startswith(";"):
                    out.append(s)
                if len(out) >= n: break
    return out

def main():
    w, k = labels(WSA1), labels(KN5000)
    if "--selftest" in sys.argv:
        f = 0
        for path, what in ((WSA1, "WSA1 kernel.s"), (KN5000, "KN5000 v142 subcpu")):
            ok = os.path.exists(path)
            print(f"  {'ok  ' if ok else 'FAIL'} {what} is readable"); f += not ok
        # Invariants, NOT pinned counts -- a pinned number becomes a false alarm the moment
        # a lane legitimately improves either tree.
        for side, names, have in (("WSA1", [p[0] for p in PAIRS], w),
                                  ("KN5000", [p[1] for p in PAIRS], k)):
            missing = [n for n in names if n not in have]
            print(f"  {'ok  ' if not missing else 'FAIL'} every {side} label in PAIRS exists"
                  f"{'' if not missing else '  missing: ' + ', '.join(missing[:6])}")
            f += bool(missing)
        d = body(KN5000, "TaskSched_Dispatch")
        hit = any("xsp" in x.lower() and "+ 4" in x for x in d)
        print(f"  {'ok  ' if hit else 'FAIL'} KN5000 dispatch saves XSP at TCB offset +4"
              " (the structural fingerprint)"); f += not hit
        d2 = body(WSA1, "Kernel_Dispatch")
        hit2 = any("XSP" in x and "+0x04" in x for x in d2)
        print(f"  {'ok  ' if hit2 else 'FAIL'} ...and so does the WSA1 kernel"); f += not hit2
        print(f"\n{2 + 2 + 2} checks, {f} failures")
        return 1 if f else 0
    if "--dispatch" in sys.argv:
        a, b = body(WSA1, "Kernel_Dispatch"), body(KN5000, "TaskSched_Dispatch")
        print(f"{'WSA1 Kernel_Dispatch':<52}  KN5000 TaskSched_Dispatch")
        for i in range(max(len(a), len(b))):
            la = re.sub(r'\s*;.*', '', a[i]).strip() if i < len(a) else ""
            print(f"  {la:<50}  {b[i].strip() if i < len(b) else ''}")
        return 0
    print("WSA1 shared kernel  ->  KN5000 v142 sub-CPU   (LEAD from names; see the docstring)\n")
    for a, b in PAIRS:
        print(f"  {'ok ' if a in w and b in k else '?? '} {a:<34} {b}")
    print(f"\n  {len(PAIRS)} pairings; WSA1 kernel labels {len(w)}, KN5000 v142 labels {len(k)}")
    print("\n★ Names are inadmissible on their own. notes/kernel_structural_match.py is the instrument.")
    return 0

sys.exit(main())
