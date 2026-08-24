#!/usr/bin/env python3
"""WHOLE-IMAGE sweep of the two rules, with a negative control.

For every occurrence of the printed form in a linear unidasm of v7, v9 and v10,
assemble the proposed spelling and require it to reproduce the disassembled
bytes EXACTLY.  Also runs a negative control per family: the deliberately WRONG
family member must NOT reproduce them (a family that always matches proves
nothing).

Run:  python3 lsp_sweep.py <dir with v7.lst v9.lst v10.lst>
"""
import collections, os, re, subprocess, sys

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$')
_C = {}


def enc_many(texts):
    todo = [t for t in dict.fromkeys(texts) if t not in _C]
    for i in range(0, len(todo), 400):
        chunk = todo[i:i + 400]
        r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                           input="\n".join(chunk) + "\n", capture_output=True, text=True)
        got = ENC.findall(r.stdout)
        if len(got) == len(chunk):
            for t, e in zip(chunk, got):
                _C[t] = bytes(int(b, 16) for b in e.split(",") if b.strip())
        else:                                   # a line failed: fall back one by one
            for t in chunk:
                r1 = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                                    input=t, capture_output=True, text=True)
                m = ENC.search(r1.stdout)
                _C[t] = bytes(int(b, 16) for b in m.group(1).split(",") if b.strip()) if m else None


MM = re.compile(r'^(ldw?)\s+\((0x[0-9a-fA-F]+)\),\((0x[0-9a-fA-F]+)\)$')


def family(text):
    m = MM.match(text.strip())
    if not m:
        return []
    d, s = int(m.group(2), 16), int(m.group(3), 16)
    dl, dh, dm = d & 0xff, (d >> 8) & 0xff, (d >> 16) & 0xff
    s0, s1, s2 = s & 0xff, (s >> 8) & 0xff, (s >> 16) & 0xff
    return [f"ldmm16 0x{d:04x}, 0x{s:04x}",
            f"ldmm8 0x{d:04x}, 0x{s:04x}",
            f"ldmm_sd24w 0x{s0:02x}, 0x{s1:02x}, 0x{s2:02x}, 0x{dl:02x}, 0x{dh:02x}",
            f"ldmm_sd24b 0x{s0:02x}, 0x{s1:02x}, 0x{s2:02x}, 0x{dl:02x}, 0x{dh:02x}",
            f"ldmm_sd8b 0x{s0:02x}, 0x{dl:02x}, 0x{dh:02x}",
            f"ldmmw_dd24 0x{dl:02x}, 0x{dh:02x}, 0x{dm:02x}, 0x{s0:02x}, 0x{s1:02x}",
            f"ldmmb_dd24 0x{dl:02x}, 0x{dh:02x}, 0x{dm:02x}, 0x{s0:02x}, 0x{s1:02x}"]


SP = re.compile(r'^ld\s+SP,(0x[0-9a-fA-F]{1,4})$')


def sp_family(text):
    m = SP.match(text.strip())
    if not m:
        return []
    v = m.group(1)
    return [f"ldw sp, {v}", f"ldw SP, {v}", f"ld sp, {v}", f"lds sp, {v}",
            f"ldw xsp, {v}", f"ld xsp, {v}", f"ldw_erp sp, {v}"]


def sweep(path):
    mm_sites, sp_sites = [], []
    for line in open(path):
        m = LINE.match(line)
        if not m:
            continue
        raw = bytes(int(b, 16) for b in m.group(2).split())
        txt = m.group(3).strip()
        if MM.match(txt):
            mm_sites.append((int(m.group(1), 16), raw, txt))
        elif SP.match(txt):
            sp_sites.append((int(m.group(1), 16), raw, txt))
    return mm_sites, sp_sites


for path in sys.argv[1:]:
    name = os.path.basename(path)
    mm, sp = sweep(path)
    enc_many([c for _a, _r, t in mm for c in family(t)])
    hit = miss = 0
    which = collections.Counter()
    neg_wrong = 0
    for a, raw, t in mm:
        cands = family(t)
        chosen = next((c for c in cands if _C.get(c) == raw), None)
        if chosen:
            hit += 1
            which[chosen.split()[0]] += 1
            # NEGATIVE CONTROL: every OTHER family member must differ.
            neg_wrong += sum(1 for c in cands if c != chosen and _C.get(c) == raw)
        else:
            miss += 1
    enc_many([c for _a, _r, t in sp for c in sp_family(t)])
    sp_hit = sum(1 for a, raw, t in sp
                 if any(_C.get(c) == raw for c in sp_family(t)))
    print(f"{name}:  `ld/ldw (imm),(imm)` {hit + miss} site(s) -> "
          f"{hit} byte-exact, {miss} unmatched; negative-control collisions {neg_wrong}")
    print(f"           chosen mnemonic: {dict(which)}")
    print(f"           `ld SP,imm16`      {len(sp)} site(s) -> {sp_hit} byte-exact "
          f"(0 = the gap)")
