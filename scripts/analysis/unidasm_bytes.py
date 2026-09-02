#!/usr/bin/env python3
r"""unidasm_bytes.py -- what does MAME's disassembler make of THESE BYTES?

QUESTION ANSWERED
-----------------
"Is this backend's name for these bytes the right name?"  A round trip cannot
answer it: re-assembling our own text gives our own bytes back whatever we call
the instruction, so it cannot tell an ADD called SUB from an ADD.  The only
independent answer available is MAME's `unidasm -arch tlcs900`, written from
Toshiba's tables with no stake in this backend.

This is the one-liner form of the same call that regindexed_convergence.py and
memtomem_test_sites.py make internally.  It exists as its own tool because the
interactive question -- "what is `f3 07 e4 e0 e8`?" -- is asked constantly and
was being asked from session scratch, where the answer is not reproducible.

EXACT COMMAND
    python3 scripts/analysis/unidasm_bytes.py '0xf3 0x07 0xe4 0xe0 0xe8'
    python3 scripts/analysis/unidasm_bytes.py 'c3 07 e0 fa 21' 'b0 14 38 8d'

WHAT IT SETTLED IN THE BACKEND LANE (2026-09-02), each a claim in
TOOLCHAIN_VERSION UPDATE 14:
    f3 07 e4 e0 e8  ->  call T,XBC+WA        CALL cc,(base+idx) is 0xE0|cc,
    f3 07 e4 e0 10  ->  db                   not the 0x08|cc `call_rr` used.
    c3 07 e0 fa 21  ->  ld A,(XWA+QIZ)       a previous-bank index on the LOAD
                                             side, which the decoder refused as
                                             "no previous-bank source form".
    b0 14 38 8d     ->  ld (XWA),(0x8d38)    NOT a store-immediate, which is
                                             what `ldmi16` calls it.
    f3 39 01 00 55  ->  ld (XDE3+0x0001),IY  a BANK-RELATIVE base register,
                                             which this backend cannot name.
"""
import os
import subprocess
import sys
import tempfile

UNIDASM = os.path.expanduser("~/compartilhado/mame/unidasm")


def dis(byts, arch="tlcs900"):
    """Return unidasm's rendering of one byte sequence, or its error text."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(bytes(byts))
        path = f.name
    try:
        r = subprocess.run([UNIDASM, path, "-arch", arch],
                           capture_output=True, text=True)
    finally:
        os.unlink(path)
    return r.stdout, r.stderr


if __name__ == "__main__":
    if not os.path.exists(UNIDASM):
        sys.exit("unidasm not found at %s -- build it in the MAME tree" % UNIDASM)
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for arg in sys.argv[1:]:
        byts = [int(x, 16) if not x.lower().startswith("0x") else int(x, 0)
                for x in arg.replace(",", " ").split()]
        out, err = dis(byts)
        lines = out.splitlines()
        print("%-40s => %s" % (arg, lines[0] if lines else err.strip()[:100]))
