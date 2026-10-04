#!/usr/bin/env python3
"""Name the unnamed boot-phase handlers of the 25 modules in ModuleInitDirectory_F82641.

QUESTION IT ANSWERS
  ModuleInitDirectory_F82641 lists 25 modules; each entry points (through prom_b's thunk directory) at a
  module's PHASE VECTOR, five 4-byte slots (`jp handler` or `ret`).  The walker 0xF82846 calls slot k of
  every module for boot phase k (WA = 4k), and the phases are established by their callers
  (ModuleInit_RunPhase0..3's headers):
      phase 0  MainTask_Entry 0xF827DD, early
      phase 1  ModuleInit_RunPhaseByChecksums when BOTH power-fail checksums verify -- memory intact
      phase 2  the same, when a checksum failed -- memory lost
      phase 3  MainTask_Entry 0xF827FC, later
      phase 4  the entry 0xF82842 (`ld A,0x10`), for which no caller is known
  So a still-unnamed slot target is <Module>_BootPhase<k> (+ _MemoryIntact for 1, _MemoryLost for 2;
  a target in two slots names both phases).  The module prefix comes from what the module's other
  slots or vector are already called: ParamModule (ParamModule_PhaseVector), Msg0716
  (Msg0716_InitAllRecords is its phase 0), Disk (its vector is the 0xFE0000 disk module), EditScreen
  (0xFE8046, the NOTE / DRUM EDIT module, whose shared phase 2/4 handler stores the edit fields' defaults,
  EditField_Velocity = 100 among them) and BStore for 0xF44000 (the module after the thunk table: its
  phase-0 handler seeds BStore_HeapBase's first six bytes from WorkspaceDefaults + 0x10, its phase-3
  handler calls BStore_LatchHeapBase_Veneer and stores BStore_CurrentBank).
  A vector still labelled sub_XXXXXX becomes <Module>_PhaseVector, and a `sub_..._Nop` bare `ret` that
  only its own slots jump to becomes <Module>_PhaseVector_Ret.
  The slots are read from the ROM, not from the listing.  REFUSED: a target already named.

RUN
  python3 notes/prom_a_module_boot_phase_names.py          # the walk and the plan
  python3 notes/prom_a_module_boot_phase_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RA = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
RB = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
SRC = [open(os.path.join(ROOT, p), "rb").read().decode("latin-1") for p in ("prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s")]
PREFIX = {0xFAA400: "ParamModule", 0xFC0000: "Msg0716", 0xFE0000: "Disk", 0xFE8046: "EditScreen", 0xF44000: "BStore"}
PHASE = {0: "BootPhase0", 1: "BootPhase1_MemoryIntact", 2: "BootPhase2_MemoryLost", 3: "BootPhase3", 4: "BootPhase4"}


def rd(a, n):
    return RA[a - 0xF80000:a - 0xF80000 + n] if a >= 0xF80000 else RB[a - 0xF00000:a - 0xF00000 + n]


def labels():
    out = {}
    for text in SRC:
        L = text.split("\n")
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if not m:
                continue
            for j in range(i, min(i + 4, len(L))):
                mm = re.search(r';\s*(F[0-9A-F]{5})\b', L[j])
                if mm and not L[j].startswith(";"):
                    out.setdefault(int(mm.group(1), 16), m.group(1))
                    break
    return out


def walk():
    """[(module index, vector base, [(phase, target or None)])] from the ROM."""
    out = []
    for k in range(25):
        p = int.from_bytes(rd(0xF82641 + 4 * k, 4), "little")
        vb = int.from_bytes(rd(p, 4), "little")
        slots = []
        if vb != 0x0E0E0E0E:
            for s in range(5):
                b = rd(vb + 4 * s, 4)
                slots.append((s, int.from_bytes(b[1:4], "little") if b[0] == 0x1B else None))
        out.append((k, vb, slots))
    return out


def plan():
    lab = labels()
    rows = []
    for k, vb, slots in walk():
        if vb not in PREFIX:
            continue
        if re.match(r'^sub_F[0-9A-F]{5}$', lab.get(vb, "")):
            new = PREFIX[vb] + "_PhaseVector"
            rows.append((lab[vb], new, "%s: module %d's boot phase vector -- ModuleInitDirectory_F82641[%d] reaches it; the walker calls\\n"
                         "  slot k (`jp`, 4 bytes) for boot phase k (notes/prom_a_module_boot_phase_names.py)." % (new, k, k)))
        rets = {t for _s, t in slots if t is not None and re.match(r'^sub_F[0-9A-F]{5}_Nop$', lab.get(t, "")) and rd(t, 1) == b"\x0e"}
        for t in sorted(rets):
            new = PREFIX[vb] + "_PhaseVector_Ret"
            rows.append((lab[t], new, "%s: the bare `ret` module %d's phase-vector slots jump to for the phases it does nothing in\\n"
                         "  (notes/prom_a_module_boot_phase_names.py)." % (new, k)))
        by = {}
        for s, t in slots:
            if t is not None and re.match(r'^sub_F[0-9A-F]{5}$', lab.get(t, "")):
                by.setdefault(t, []).append(s)
        for t, ph in sorted(by.items()):
            if len(ph) == 1:
                new = "%s_%s" % (PREFIX[vb], PHASE[ph[0]])
            else:
                new = "%s_BootPhase%s" % (PREFIX[vb], "And".join(str(p) for p in ph))
            rows.append((lab[t], new, "%s: module %d's boot phase %s handler -- ModuleInitDirectory_F82641[%d]'s vector 0x%06X, slot%s %s\\n"
                         "  (phase 1 runs when both power-fail checksums verify, phase 2 when one fails; notes/prom_a_module_boot_phase_names.py)." % (
                             new, k, "/".join(str(p) for p in ph), k, vb, "s" if len(ph) > 1 else "", ", ".join(str(p) for p in ph))))
    return rows


def main():
    rows = plan()
    for o, n, h in rows:
        print(("%s=%s|%s" % (o, n, h)) if "--args" in sys.argv else "%-12s -> %s" % (o, n))
    if "--args" not in sys.argv:
        print("rename %d" % len(rows))


if __name__ == "__main__":
    main()
