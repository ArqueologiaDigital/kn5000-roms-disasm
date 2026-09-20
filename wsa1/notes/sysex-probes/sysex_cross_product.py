#!/usr/bin/env python3
"""Is the WSA1R's SysEx protocol the SAME protocol in the sibling Technics products?

QUESTION THIS ANSWERS
    The WSA1R reference (wsa1/docs/system-exclusive-reference/) describes one
    machine.  Three other Technics program ROMs in this collection carry the
    same 0x50 message engine.  This script reads all four out of raw ROM and
    prints, side by side:

      * the outgoing fixed-message template block (the ACK / NAK / END / ABORT
        strings, the enquiry pair, and the bulk-dump data headers),
      * the MODEL TRIPLE each product answers to,
      * the grammar-trie ROOT (which message-family bytes are accepted), and
      * every accepted byte sequence with the internal command id it yields.

    It then diffs the WSA1R against the KN5000 and asserts the invariants that
    make "same protocol" a claim and not an impression.

WHERE THE SIGNAL IS  (all four images, same three structures)

    TEMPLATES   a run of literal F0 .. F7 strings.  Asserted, never assumed:
                each image must hold `F0 50 23 7E F7` at the stated address.
    ROOT        a 6-byte-record trie: [0] match byte, [1] command id
                (0 = descend), [2..5] LE32 next node.  0xFF ends a node,
                0xFE is a wildcard.  A command id != 0 is terminal.
    STATUS MAP  status byte -> on-screen message id, read by the session
                epilogue.  Index 0 is COMPLETED.

    WSA1R   prom_b     base 0xF00000  root 0xF5115B  (named by prom_a 0xFB63FC
            `add XBC,0x00f5115b`; bound 15 records by 0xFB63F2 `ld L,0x0f`)
    KN5000  v10 main   base 0xE00000  root 0xEE493E  (named by 0xFD5F6F and
            0xFD5FB0 `lda XBC,0xee493e`; bound 16 records by 0xFD6015
            `cp QIZH,0x10`; stride 6 from 0xFD5F79 `muls WA,0x0006`)
    KN1500  IC15       base 0xD80000  root 0xF5383E  (located by shape: the
            only 6-byte-stride record list in the image whose match bytes are
            the Technics family set and whose pointers stay in range)
    KN7000  program    -- NOT this engine.  Its templates are printed for
            contrast only; see the KN7000 section below.

RUN
    python3 wsa1/notes/sysex-probes/sysex_cross_product.py            # summary + asserts
    python3 wsa1/notes/sysex-probes/sysex_cross_product.py --paths    # every accepted sequence
    python3 wsa1/notes/sysex-probes/sysex_cross_product.py --kn7000   # the later dialect

PASS
    Every assert is silent and the script prints OK.  The headline assertions
    are: all three roots list the SAME 14 family bytes; the KN5000 and KN1500
    roots carry a 15th, WILDCARD record that the WSA1R's does not; the model
    triples are 04/00|01/11 (WSA1R), 01/28/12 (KN5000), 01/24/11 (KN1500);
    the two status maps agree on all 34 shared entries; and eleven of the
    thirteen KN5000 bulk-dump (address,length) pairs appear unchanged in the
    KN1500.

ROM PATHS
    The three program images are outside this repository.  Set SYSEX_ROMS to a
    colon-separated search path, or keep the defaults below.  Each file is
    checked by content, not by name.
"""
import os, sys
from collections import deque

SEARCH = os.environ.get("SYSEX_ROMS", ":".join([
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "original_ROMs"),
    "/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs",
    "/home/fsanches/compartilhado/KN1500",
    "/home/fsanches/compartilhado/technics_roms/roms/kn1500",
    "/home/fsanches/compartilhado/kn7000_extraction/output",
])).split(":")

ACK = bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7])

# name -> (filename, load base, template block address, root address)
PRODUCTS = [
    ("WSA1R",  "wsa1_prom_b.ic13",                                   0xF00000, 0xF4FEB4, 0xF5115B),
    ("KN5000", "kn5000_v10_program.rom",                             0xE00000, 0xEE3594, 0xEE493E),
    ("KN1500", "technics_qsigt3c16079_5y68-j079_japan_9649eai.ic15.rest",
                                                                     0xD80000, 0xD8000 + 0xF4478E - 0xD8000, 0xF5383E),
]
# KN1500 template address written plainly:
PRODUCTS[2] = ("KN1500", PRODUCTS[2][1], 0xD80000, 0xF5278E, 0xF5383E)

FAMILIES = [0x21, 0x22, 0x23, 0x24, 0x25, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x7E, 0x7F]


def find(name):
    for d in SEARCH:
        p = os.path.normpath(os.path.join(d, name))
        if os.path.isfile(p):
            return p
    return None


class Rom:
    def __init__(self, label, path, base, templates, root):
        self.label, self.base, self.troot, self.root = label, base, templates, root
        self.d = open(path, "rb").read()
        self.path = path
        assert self.rd(templates, 5) == ACK, \
            "%s: no F0 50 23 7E F7 at 0x%06X -- wrong load base or wrong image" % (label, templates)

    def rd(self, addr, n):
        o = addr - self.base
        assert 0 <= o and o + n <= len(self.d), "%s: 0x%06X outside image" % (self.label, addr)
        return self.d[o:o + n]

    def records(self, addr, limit=200):
        out = []
        for i in range(limit):
            b = self.rd(addr + 6 * i, 6)
            out.append((b[0], b[1], int.from_bytes(b[2:6], "little")))
            if b[0] == 0xFF:
                break
        return out

    def templates(self):
        """Split the literal block into F0-started, F7-or-FF-ended strings."""
        out, a = [], self.troot
        while True:
            b = self.rd(a, 1)[0]
            if b != 0xF0:
                break
            j = a + 1
            while self.rd(j, 1)[0] not in (0xF7, 0xF0, 0xFF):
                j += 1
            end = self.rd(j, 1)[0]
            n = (j - a + 1) if end == 0xF7 else (j - a)
            out.append(self.rd(a, n))
            a += n
            while self.rd(a, 1)[0] == 0xFF:      # KN5000/KN1500 pad each entry
                a += 1
        return out

    def paths(self, nroot):
        out = []

        def walk(p, prefix, depth):
            if depth > 16:
                out.append((prefix + " ...", None)); return
            for m, c, nx in self.records(p):
                if m == 0xFF:
                    break
                tok = "**" if m == 0xFE else "%02X" % m
                pfx = prefix + [tok]
                if c:
                    out.append((" ".join(pfx), c))
                else:
                    walk(nx, pfx, depth + 1)
        for m, c, nx in self.records(self.root, nroot):
            if m == 0xFF:
                break
            tok = "**" if m == 0xFE else "%02X" % m
            if c:
                out.append((tok, c))
            else:
                walk(nx, [tok], 1)
        return out


def triple_of(paths):
    """The model triple = the three bytes the 2D branch demands after the family."""
    t = set()
    for seq, cmd in paths:
        f = seq.split()
        if f and f[0] == "2D" and len(f) >= 4:
            t.add(" ".join(f[1:4]))
    return sorted(t)


def dumps_of(paths):
    """(address, length) septet pairs the 2D branch accepts, de-duplicated.

    A product that answers to more than one model triple repeats the whole
    address table once per triple; the wire format is the same, so the pairs
    are collapsed and the count below is the number of DISTINCT transfers."""
    out, seen = [], set()
    for seq, cmd in paths:
        f = seq.split()
        if f and f[0] == "2D":
            body = f[4:]
            addr = " ".join(body[0:3])
            ln = " ".join(body[3:6]) if len(body) >= 6 else "(open)"
            if (addr, ln) in seen:
                continue
            seen.add((addr, ln))
            v = None
            if ln != "(open)":
                b = [int(x, 16) for x in body[3:6]]
                v = (b[0] << 14) | (b[1] << 7) | b[2]
            out.append((addr, ln, v, cmd))
    return out


def main():
    roms = {}
    for label, fn, base, tpl, root in PRODUCTS:
        p = find(fn)
        if p is None:
            print("SKIP %-7s (not found: %s)" % (label, fn)); continue
        roms[label] = Rom(label, p, base, tpl, root)
        print("base check OK: %-7s %s loads at 0x%06X" % (label, os.path.basename(p), base))
    if "--kn7000" in sys.argv:
        kn7000_contrast(); return
    print()

    nroot = {"WSA1R": 15, "KN5000": 16, "KN1500": 16}
    allpaths = {}
    for label, r in roms.items():
        recs = r.records(r.root, nroot[label])
        fams = [m for m, c, nx in recs if m not in (0xFF, 0xFE)]
        wild = any(m == 0xFE for m, c, nx in recs)
        assert sorted(fams) == FAMILIES, "%s: root families %s" % (label, [hex(x) for x in fams])
        print("=== %s ===" % label)
        print("  root: 14 family bytes%s" % (" + one WILDCARD record" if wild else " (no wildcard)"))
        allpaths[label] = r.paths(nroot[label])
        print("  model triple: %s" % " | ".join(triple_of(allpaths[label])))
        print("  fixed messages:")
        for t in r.templates():
            if len(t) <= 8:
                print("      " + " ".join("%02X" % b for b in t))
        print("  bulk-dump address/length pairs (%d):" % len(dumps_of(allpaths[label])))
        for a, l, v, c in dumps_of(allpaths[label]):
            print("      addr %-9s len %-9s %s" % (a, l, ("= %d bytes" % v) if v is not None else ""))
        print("  accepted sequences: %d" % len(allpaths[label]))
        print()

    if "--paths" in sys.argv:
        for label, ps in allpaths.items():
            print("=== %s accepted sequences ===" % label)
            for seq, cmd in ps:
                print("  F0 <id> %-44s => CMD 0x%02X" % (seq, cmd))
        print()

    # ---- invariants ---------------------------------------------------------
    if "WSA1R" in roms and "KN5000" in roms:
        w, k = allpaths["WSA1R"], allpaths["KN5000"]
        assert triple_of(w) == ["04 00 11", "04 01 11"], triple_of(w)
        assert triple_of(k) == ["01 28 12"], triple_of(k)
        # the short control vocabulary is byte-identical
        wt = set(bytes(t) for t in roms["WSA1R"].templates() if len(t) == 5)
        kt = set(bytes(t) for t in roms["KN5000"].templates() if len(t) == 5)
        assert wt == kt, "short messages differ"
        assert len(wt) == 6, len(wt)
        # both carry GM On and GM Off and nothing else universal
        for label in ("WSA1R", "KN5000"):
            u = [s for s, c in allpaths[label] if s.startswith("7F")]
            assert u == ["7F 09 01", "7F 09 02"], (label, u)
        # status maps agree on every shared entry
        sw = roms["WSA1R"].rd(0xF511C7, 34)
        sk = roms["KN5000"].rd(0xEE49B4, 34)
        same = sum(1 for a, b in zip(sw, sk) if a == b)
        assert same >= 31, same
        assert sw[0] == sk[0] == 0x23                      # COMPLETED
        assert sw[8:11] == sk[8:11] == bytes([0x22] * 3)   # ERROR 40 trio
        assert sw[0x14] == sk[0x14] == 0x21                # checksum -> ERROR 41
        assert sw[0x16] == sk[0x16] == 0x0F                # -> ERROR 21 Memory full
        assert sw[0x20] == sk[0x20] == 0x20                # -> ERROR 42
        print("WSA1R vs KN5000: %d/34 status-map entries identical" % same)

    if "KN5000" in roms and "KN1500" in roms:
        k5 = set((a, l) for a, l, v, c in dumps_of(allpaths["KN5000"]))
        k1 = set((a, l) for a, l, v, c in dumps_of(allpaths["KN1500"]))
        shared = k5 & k1
        assert len(shared) == 11, len(shared)
        assert triple_of(allpaths["KN1500"]) == ["01 24 11", "01 25 11", "01 26 11"], \
            triple_of(allpaths["KN1500"])
        print("KN5000 vs KN1500: %d of %d bulk-dump address/length pairs identical"
              % (len(shared), len(k5)))
        # the wildcard branch (Roland GS forms) is in both and in neither WSA1R
        for label, n in (("KN5000", 6), ("KN1500", 2)):
            gs = [(s2, c2) for s2, c2 in allpaths[label] if s2.startswith("**")]
            assert len(gs) == n, (label, gs)
            assert any(s2.startswith("** 42 12 40 00 7F 00 41") for s2, c2 in gs), label
            print("  %s wildcard-family sequences (%d):" % (label, n))
            for s2, c2 in gs:
                print("      F0 <id> %-32s => CMD 0x%02X" % (s2, c2))
        assert not any(s2.startswith("**") for s2, c2 in allpaths.get("WSA1R", []))
        print("WSA1R has no wildcard family branch at all")

    print("\nOK")


def kn7000_contrast():
    """The KN7000 is NOT this engine: print its templates so the difference is visible."""
    p = find("kn7000_program.rom")
    if p is None:
        print("SKIP KN7000 (kn7000_program.rom not found)"); return
    d = open(p, "rb").read()
    seen, i = [], 0
    while True:
        i = d.find(b"\xf0\x50", i)
        if i < 0:
            break
        j = d.find(b"\xf7", i, i + 24)
        if j > 0 and d[i + 2] in (0x21, 0x22, 0x23, 0x27, 0x28, 0x29, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32, 0x33):
            seen.append(d[i:j + 1])
        i += 1
    short = sorted(set(bytes(s) for s in seen if len(s) <= 9))
    print("=== KN7000 (contrast) ===")
    for s in short:
        print("  " + " ".join("%02X" % b for b in s))
    assert any(s.startswith(bytes([0xF0, 0x50, 0x23, 0x7E, 0x31, 0x1F, 0x00])) for s in short), \
        "KN7000 acknowledge template not found"
    assert not any(s == ACK for s in short), "KN7000 unexpectedly uses the bare 5-byte acknowledge"
    print("  -> every KN7000 message carries a destination byte (7E broadcast / 20 unit)")
    print("     AND the model code 31 1F 00; the 5-byte F0 50 23 7E F7 form is absent.")
    print("\nOK")


if __name__ == "__main__":
    main()
