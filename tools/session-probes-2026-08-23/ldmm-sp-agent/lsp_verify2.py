#!/usr/bin/env python3
"""PROPOSED SPELLINGS for the two assigned blocking forms, checked against the ROM.

  A. `ldw (imm),(imm)`  -> the ldmm family; which member depends on the address
     WIDTHS and on WHICH side the prefix carries, neither of which is in the
     printed text.  So offer the family and let the bytes choose.
  B. `ld SP,imm16`      -> no spelling exists (see lsp_sp_probe.py).

Every row prints SITE ADDRESS, ROM BYTES, the spelling and llvm-mc's encoding.
"""
import json, os, re, subprocess, sys

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ROMP = os.path.expanduser("~/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v7_program.rom")
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
HERE = os.path.dirname(os.path.abspath(__file__))
_C = {}


def enc(t):
    if t not in _C:
        r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                           input=t, capture_output=True, text=True)
        m = ENC.search(r.stdout)
        _C[t] = bytes(int(b, 16) for b in m.group(1).split(",") if b.strip()) if m else None
    return _C[t]


def candidates(text):
    """Every ldmm spelling for a printed `ld/ldw (DST),(SRC)`."""
    m = re.match(r'^(ldw?)\s+\((0x[0-9a-fA-F]+)\),\((0x[0-9a-fA-F]+)\)$', text.strip())
    if not m:
        return
    d, s = int(m.group(2), 16), int(m.group(3), 16)
    dl, dh = d & 0xff, (d >> 8) & 0xff
    s0, s1, s2 = s & 0xff, (s >> 8) & 0xff, (s >> 16) & 0xff
    d0, d1, d2 = dl, dh, (d >> 16) & 0xff
    yield f"ldmm16 0x{d:04x}, 0x{s:04x}"                       # D1+src16+19+dst16
    yield f"ldmm8 0x{d:04x}, 0x{s:04x}"                        # C1+src16+19+dst16
    yield f"ldmm_sd24w 0x{s0:02x}, 0x{s1:02x}, 0x{s2:02x}, 0x{dl:02x}, 0x{dh:02x}"
    yield f"ldmm_sd24b 0x{s0:02x}, 0x{s1:02x}, 0x{s2:02x}, 0x{dl:02x}, 0x{dh:02x}"
    yield f"ldmm_sd8b 0x{s0:02x}, 0x{dl:02x}, 0x{dh:02x}"      # C0+src8+19+dst16
    yield f"ldmmw_dd24 0x{d0:02x}, 0x{d1:02x}, 0x{d2:02x}, 0x{s0:02x}, 0x{s1:02x}"
    yield f"ldmmb_dd24 0x{d0:02x}, 0x{d1:02x}, 0x{d2:02x}, 0x{s0:02x}, 0x{s1:02x}"


ROM = open(ROMP, "rb").read()
sites = json.load(open(os.path.join(HERE, (sys.argv[1] if len(sys.argv)>1 else "lsp_sites.json"))))
sites = [s for s in sites if s["spell"] is None]
seen, rows = set(), []
for s in sorted(sites, key=lambda x: x["addr"]):
    if s["addr"] in seen:
        continue
    seen.add(s["addr"])
    want = bytes.fromhex(s["bytes"])
    assert ROM[s["addr"] - 0xE00000:][:len(want)] == want, f"ROM mismatch at {s['addr']:x}"
    hit = next(((c, enc(c)) for c in candidates(s["text"]) if enc(c) == want), None)
    rows.append((s, want, hit))

ok = sum(1 for _s, _w, h in rows if h)
print(f"{len(rows)} unique unspellable site(s); {ok} now byte-exact\n")
print(f"{'SITE':9} {'ROM BYTES':16} {'unidasm text':26} {'llvm-mc spelling':46} "
      f"{'llvm-mc encoding':16} EQ")
for s, w, h in rows:
    if h:
        print(f"0x{s['addr']:06X}  {w.hex():16} {s['text']:26} {h[0]:46} "
              f"{h[1].hex():16} {'YES' if h[1] == w else 'NO'}")
    else:
        print(f"0x{s['addr']:06X}  {w.hex():16} {s['text']:26} "
              f"{'-- NO SPELLING FOUND --':46} {'':16} --")
