#!/usr/bin/env python3
"""b1's report quotes "a single linear pass alone gets 339,261 = 94.51%" and
attributes it to --selftest. No mode of the script prints it -- it appears only
in the docstring. Measure it directly with the script's own linear_decode."""
import os, sys, tempfile, shutil
sys.path.insert(0, os.path.expanduser("~/compartilhado/kn5000-roms-disasm/notes"))
import reachability_kn5000 as R
data, base = R.rom_bytes(), R.TARGET["base"]
mirror = tempfile.mkdtemp(prefix="verify-b1-linear-")
try:
    R.build_mirror(mirror)
    code, labels, words, dbytes, pbytes, total = R.flatten(mirror)
finally:
    shutil.rmtree(mirror, ignore_errors=True)
R._BOUND.clear()
R.linear_decode(data, base, base, len(data))
hit = sum(1 for a in code if a in R._BOUND)
lendis = sum(1 for a, (n, _t) in code.items() if a in R._BOUND and R._BOUND[a][0] != n)
print("single linear pass: %d of %d boundaries = %.2f%%" % (hit, len(code), 100.0*hit/len(code)))
print("length disagreements on those: %d" % lendis)
