#!/usr/bin/env python3
"""RULE + PROOF for the memory-to-memory move `ld (imm),(imm)` / `ldw (imm),(imm)`.

QUESTION THIS ANSWERS
  convert_reachable_ranges.py truncates a range at the first instruction it
  cannot spell.  `ldw (0x2796),(0x2792)` was one of those.  Which llvm-mc
  spelling emits the ROM's bytes, at EVERY site, and does the family discriminate?

THE RULE
  The printed text carries the two ADDRESSES and nothing else.  It does NOT
  carry (a) the operand WIDTH -- byte or word -- and (b) WHICH side the leading
  prefix addresses, nor (c) how wide that prefix address is (8, 16 or 24 bits).
  All three pick a different member of the `ldmm` family, so the rule is: offer
  the whole family and let the ROM bytes choose.  Printed order is DST, SRC.

     mnemonic            encoding                              chosen when
     ldmm8    D, S       C1 + S16 + 19 + D16                   byte, 16-bit src
     ldmm16   D, S       D1 + S16 + 19 + D16                   word, 16-bit src
     ldmm_sd24b s0,s1,s2,dl,dh   C2 + S24 + 19 + D16           byte, 24-bit src
     ldmm_sd24w s0,s1,s2,dl,dh   D2 + S24 + 19 + D16           word, 24-bit src
     ldmm_sd8b  s0,dl,dh         C0 + S8  + 19 + D16           byte, 8-bit src
     ldmmb_dd24 d0,d1,d2,s0,s1   F2 + D24 + 14 + S16           byte, 24-bit dst
     ldmmw_dd24 d0,d1,d2,s0,s1   F2 + D24 + 16 + S16           word, 24-bit dst

  ⚠ THE OPERAND ORDER FLIPS BETWEEN THE TWO HALVES OF THE FAMILY.  The `sd*`
  members put the SOURCE in the prefix; the `dd24` members put the DESTINATION
  there, and their sub-opcode is 0x14/0x16 rather than 0x19.  Guessing from the
  mnemonic gets this backwards; only the byte comparison settles it.

NEGATIVE CONTROL
  For every site, every family member OTHER than the chosen one must fail to
  reproduce the bytes.  A family where several members match would mean the
  selection is arbitrary.  Measured: 0 collisions in v7, v9 and v10.

MEASURED 2026-08-23 (tlcs900 llvm-mc from ~/compartilhado/llvm-project/build)
  v7   630 printed sites -> 621 byte-exact, 9 unmatched, 0 collisions
  v9   628 printed sites -> 621 byte-exact, 7 unmatched, 0 collisions
  v10  628 printed sites -> 621 byte-exact, 7 unmatched, 0 collisions
  The unmatched residue is the DD8 (F0) and DD16 (F1) destination-direct forms,
  which the backend has no def for -- see README-ldmm_memtomem.md.  None of them
  is at a blocking site of the converter.

RUN
  python3 tools/spelling-probes/verify_ldmm_memtomem.py \
      original_ROMs/kn5000_v7_program.rom [more ROMs...]
  Needs ~/compartilhado/tools/unidasm and ~/compartilhado/llvm-project/build/bin.
"""
import collections, os, re, subprocess, sys, tempfile

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$')
MM = re.compile(r'^(ldw?)\s+\((0x[0-9a-fA-F]+)\),\((0x[0-9a-fA-F]+)\)$')
_C = {}


def family(text):
    """Every ldmm spelling for a printed `ld/ldw (DST),(SRC)`, best first."""
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


def encode_all(texts):
    """Assemble many one-line sources, memoised; falls back per line on error."""
    todo = [t for t in dict.fromkeys(texts) if t not in _C]
    for i in range(0, len(todo), 400):
        chunk = todo[i:i + 400]
        r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                           input="\n".join(chunk) + "\n", capture_output=True, text=True)
        got = ENC.findall(r.stdout)
        if len(got) == len(chunk):
            for t, e in zip(chunk, got):
                _C[t] = bytes(int(b, 16) for b in e.split(",") if b.strip())
        else:
            for t in chunk:
                r1 = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                                    input=t, capture_output=True, text=True)
                m = ENC.search(r1.stdout)
                _C[t] = bytes(int(b, 16) for b in m.group(1).split(",")
                              if b.strip()) if m else None


def sites_of(rom_path, tmp):
    lst = os.path.join(tmp, os.path.basename(rom_path) + ".lst")
    with open(lst, "w") as fh:
        subprocess.run([UNIDASM, rom_path, "-arch", "tlcs900", "-basepc", hex(BASE)],
                       stdout=fh, stderr=subprocess.DEVNULL, check=True)
    out = []
    for line in open(lst):
        m = LINE.match(line)
        if m and MM.match(m.group(3).strip()):
            out.append((int(m.group(1), 16),
                        bytes(int(b, 16) for b in m.group(2).split()),
                        m.group(3).strip()))
    return out


def main(argv):
    if not argv:
        sys.exit(__doc__.strip().rsplit("RUN", 1)[-1])
    rc = 0
    with tempfile.TemporaryDirectory(prefix="ldmm_probe_") as tmp:
        for rom_path in argv:
            sites = sites_of(rom_path, tmp)
            encode_all([c for _a, _b, t in sites for c in family(t)])
            hit = coll = 0
            which, missed = collections.Counter(), []
            for a, raw, t in sites:
                cands = family(t)
                chosen = next((c for c in cands if _C.get(c) == raw), None)
                if chosen is None:
                    missed.append((a, raw, t)); continue
                hit += 1
                which[chosen.split()[0]] += 1
                coll += sum(1 for c in cands if c != chosen and _C.get(c) == raw)
            print(f"{os.path.basename(rom_path)}: {len(sites)} printed site(s) -> "
                  f"{hit} byte-exact, {len(missed)} unmatched, "
                  f"{coll} negative-control collision(s)")
            print(f"    by mnemonic: {dict(which)}")
            for a, raw, t in missed:
                print(f"    UNMATCHED 0x{a:06X}  {raw.hex(' '):22} {t}")
            if coll:
                rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
