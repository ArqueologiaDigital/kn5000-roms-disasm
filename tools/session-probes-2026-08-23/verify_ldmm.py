#!/usr/bin/env python3
"""PROPOSED RULE for `ldw (imm),(imm)` / `ld (imm),(imm)`: offer the ldmm family
and let the ROM bytes choose.  Verifies each candidate against the ROM bytes
dumped at the site, exactly as convert_reachable_ranges.py would."""
import json, os, re, subprocess, sys

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
_C = {}
def enc(t):
    if t in _C: return _C[t]
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=t, capture_output=True, text=True)
    m = ENC.search(r.stdout)
    _C[t] = bytes(int(b, 16) for b in m.group(1).split(",") if b.strip()) if m else None
    return _C[t]


def candidates(text):
    """Every ldmm spelling for a printed `ld/ldw (A),(B)` -- A dst, B src."""
    m = re.match(r'^(ldw?)\s+\((0x[0-9a-fA-F]+)\),\((0x[0-9a-fA-F]+)\)$', text.strip())
    if not m:
        return
    w = m.group(1) == "ldw"
    d, s = int(m.group(2), 16), int(m.group(3), 16)
    dl, dh = d & 0xff, (d >> 8) & 0xff
    # source direct, 16-bit source address:   D1/C1 + src16 + 0x19 + dst16
    yield f"ldmm16 0x{d:04x}, 0x{s:04x}"
    yield f"ldmm8 0x{d:04x}, 0x{s:04x}"
    # source direct, 24-bit source address:   D2/C2 + src24 + 0x19 + dst16
    yield (f"ldmm_sd24w 0x{s & 0xff:02x}, 0x{(s >> 8) & 0xff:02x}, "
           f"0x{(s >> 16) & 0xff:02x}, 0x{dl:02x}, 0x{dh:02x}")
    yield (f"ldmm_sd24b 0x{s & 0xff:02x}, 0x{(s >> 8) & 0xff:02x}, "
           f"0x{(s >> 16) & 0xff:02x}, 0x{dl:02x}, 0x{dh:02x}")
    # source direct, 8-bit source address:    C0 + src8 + 0x19 + dst16
    yield f"ldmm_sd8b 0x{s & 0xff:02x}, 0x{dl:02x}, 0x{dh:02x}"
    # DEST direct, 24-bit dest address:       F2 + dst24 + 0x16/0x14 + src16
    yield (f"ldmmw_dd24 0x{d & 0xff:02x}, 0x{(d >> 8) & 0xff:02x}, "
           f"0x{(d >> 16) & 0xff:02x}, 0x{s & 0xff:02x}, 0x{(s >> 8) & 0xff:02x}")
    yield (f"ldmmb_dd24 0x{d & 0xff:02x}, 0x{(d >> 8) & 0xff:02x}, "
           f"0x{(d >> 16) & 0xff:02x}, 0x{s & 0xff:02x}, 0x{(s >> 8) & 0xff:02x}")


ROM = open(os.path.expanduser(
    "~/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v7_program.rom"), "rb").read()
sites = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sites.json")))
sites = [s for s in sites if s["form"] == "ldw (imm),(imm)"]
seen, rows = set(), []
for s in sorted(sites, key=lambda x: x["addr"]):
    if s["addr"] in seen:
        continue
    seen.add(s["addr"])
    want = bytes.fromhex(s["bytes"])
    assert ROM[s["addr"] - 0xE00000: s["addr"] - 0xE00000 + len(want)] == want, s
    hit = None
    for c in candidates(s["text"]):
        e = enc(c)
        if e == want:
            hit = (c, e); break
    rows.append((s["addr"], want, s["text"], hit, s["target"], s["name"], s["framing"]))
ok = sum(1 for r in rows if r[3])
print(f"{len(rows)} unique site(s), {ok} byte-exact\n")
for a, w, t, hit, tg, nm, fr in rows:
    if hit:
        print(f"0x{a:06X}  {w.hex():16}  {t:26}  {hit[0]:44}  -> {hit[1].hex()}  "
              f"{'MATCH' if hit[1] == w else 'DIFFER'}   [range 0x{tg:06X} {nm} {fr}]")
    else:
        print(f"0x{a:06X}  {w.hex():16}  {t:26}  NO CANDIDATE MATCHED   [range 0x{tg:06X} {nm} {fr}]")
