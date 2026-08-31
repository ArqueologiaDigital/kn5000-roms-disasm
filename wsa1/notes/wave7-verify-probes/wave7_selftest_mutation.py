#!/usr/bin/env python3
"""Does a layout script's --selftest actually FAIL when the ROM changes?

QUESTION IT ANSWERS
    "Is this --selftest a real criterion, or one that cannot fail?"

WHY IT EXISTS
    A self-test that passes on a mutated ROM is decoration.  This project's standing
    measurement rule is that a criterion which cannot fail is not a pass, so before
    trusting any lane's "N checks, 0 failures" somebody has to flip a byte the checks
    are supposed to depend on and confirm the count moves.

    It loads the layout module, replaces its cached ROM image with a mutated copy,
    re-runs selftest(), and prints the failure count.  A mutation inside a segment
    the checks actually read MUST produce failures > 0.

RUN
    MUT_ADDR=FAD800 MUT_VAL=00 python3 notes/wave7-verify-probes/wave7_selftest_mutation.py
    MUT_ADDR=FAD801 MUT_VAL=FF python3 notes/wave7-verify-probes/wave7_selftest_mutation.py

    Defaults to flipping the first byte of the span under test if no env is given.
    LAYOUT= may name a different layout module in notes/.
"""
import os
import sys
import importlib.util

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LAYOUT = os.environ.get("LAYOUT", "prom_a_fad800_layout.py")
ADDR = int(os.environ.get("MUT_ADDR", "FAD800"), 16)
VAL = int(os.environ.get("MUT_VAL", "00"), 16)

sys.argv = ["x", "--selftest"]
spec = importlib.util.spec_from_file_location("L", os.path.join(ROOT, "notes", LAYOUT))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

d = bytearray(open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read())
before = d[ADDR - 0xF80000]
d[ADDR - 0xF80000] = VAL
m._rom["a"] = bytes(d)

rc = m.selftest()
print("mutated 0x%06X: 0x%02X -> 0x%02X in %s" % (ADDR, before, VAL, LAYOUT))
print("EXIT", rc, "FAILURES", len(m.FAIL))
for f in m.FAIL[:6]:
    print("   ", f)
if before == VAL:
    print("NOTE: the byte already held that value -- this run mutated NOTHING and")
    print("      proves nothing. Pick a different MUT_VAL.")
elif len(m.FAIL) == 0:
    print("VERDICT: the self-test did NOT notice a changed ROM byte at this address.")
    print("         That is only acceptable if no check reads this byte -- say which.")
else:
    print("VERDICT: the self-test is a real criterion at this address; it can fail.")
