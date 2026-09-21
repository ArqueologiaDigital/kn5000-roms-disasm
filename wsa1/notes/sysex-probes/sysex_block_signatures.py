#!/usr/bin/env python3
"""What does a received bulk-dump block look like, and can a librarian check it?

QUESTION THIS ANSWERS
    A tool that stores .syx dumps wants to know, before it sends a file back,
    that the file is the category the user thinks it is.  Is there anything in
    the payload to check?

    There is.  Every block begins with a fixed signature, and the SOUND and
    COMBINATION blocks carry 16-byte printable names a tool can list without
    understanding anything else.

WHERE THE SIGNAL IS
    The capture, not the ROM.  This reassembles each transfer from the wire
    exactly as a receiver would -- strip F0 and the six header bytes, strip the
    two-byte tail, rejoin each pair of nibble bytes high-first, and stop on a
    continuation flag of 0 -- then reports the first bytes of the result.

    The reassembly is self-checking: every transfer must come out at exactly
    the byte count its own header declared.  That assertion is the reason to
    trust the signatures below; a wrong nibble order or a mis-stripped tail
    would not land on the declared length.

THE CAPTURE
    SND_CMBI.syx -- 728254 bytes, 2883 messages.  Its name says SOUND and
    COMBINATION; it is in fact a THREE-category session, opening with
    SYSTEM,PART & MIDI (the category the parameter chapter maps),
    sha256 a7a83a08af2361ad0072faeb598322420c74b9c4481ddf84322477629fce968e.
    Not committed: it ships in the community archive
    KN7000/WSA1R_files/SND_CMBI_syx.zip and is unpacked automatically.

RUN
    python3 wsa1/notes/sysex-probes/sysex_block_signatures.py
    python3 wsa1/notes/sysex-probes/sysex_block_signatures.py --names

RESULT (2026-09-21)
    addr 40 00 00      32 bytes  5A 5A 01 00 "WA0"
    addr 40 00 20    2400 bytes  78 10 <16-byte name> 60 0C ...
    addr 20 00 00  262144 bytes  "WSA SOUND RAM S0" then 16-byte names
    addr 50 00 00     768 bytes  5A 5A 5A 5A 00 00 "WSA1  "
    addr 50 06 00   90112 bytes  78 10 <16-byte name> 60 0C ...

    Every one of the five reassembled to exactly its declared length.
"""
import os, re, sys, zipfile

KNOWN = "a7a83a08af2361ad0072faeb598322420c74b9c4481ddf84322477629fce968e"
ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"
HERE = os.path.dirname(os.path.abspath(__file__))


def locate():
    for p in (os.environ.get("SYSEX_CAPTURE", ""),
              os.path.join(HERE, "SND_CMBI.syx"), "/tmp/SND_CMBI.syx"):
        if p and os.path.isfile(p):
            return p
    if os.path.isfile(ZIP):
        zipfile.ZipFile(ZIP).extractall("/tmp")
        return "/tmp/SND_CMBI.syx"
    raise SystemExit("capture not found; see THE CAPTURE above")


def where_from():
    """Where the SYSTEM,PART & MIDI signature comes from, and whether anything
    checks it.

    The 32 bytes of block 1 are a literal in prom_a at 0xFE704E, and TWO
    routines copy them into RAM -- 0x7600, which is the block itself, and
    0x603600.  Both are copy loops bounded by `cp H,0x20`; neither compares.
    Nor is there a 16-bit compare against 0x5A5A anywhere in either image.

    So the instrument WRITES its signature and nothing found READS it back.  A
    librarian should not expect a block with a wrong signature to be refused.

    Coverage of that negative: three-byte little-endian pointers to the literal
    across prom_a (2 sites, both copies), and immediate compares against 0x5A5A
    across both 512 KiB images.  Code reaching the literal by an offset from
    another base, or comparing through a pointer computed elsewhere, would not
    be seen."""
    import os as _os
    roms = _os.path.abspath(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)),
                                          "..", "..", "original_ROMs"))
    A = open(_os.path.join(roms, "wsa1_prom_a.ic12"), "rb").read()
    B = open(_os.path.join(roms, "wsa1_prom_b.ic13"), "rb").read()
    AB, LIT = 0xF80000, 0xFE704E
    lit = A[LIT - AB:LIT - AB + 32]
    assert lit[:8] == bytes([0x5A, 0x5A, 0x01, 0x00, 0x57, 0x41, 0x30, 0x00]), \
        "the literal at 0x%06X is no longer the block-1 signature" % LIT
    ptr = LIT.to_bytes(3, "little")
    sites = [AB + k for k in range(len(A) - 3) if A[k:k + 3] == ptr]
    assert len(sites) == 2, "expected 2 pointers to the literal, found %d" % len(sites)
    # Each site is a byte-copy loop bounded at 0x20 -- one written `cp HL,0x0020`
    # and the other `cp H,0x20`; accept either, and require the load-store pair
    # that makes it a copy rather than a comparison.
    for s_ in sites:
        window = A[s_ - AB:s_ - AB + 0x28]
        bounded = (bytes([0xDB, 0xCF, 0x20, 0x00]) in window
                   or bytes([0xCE, 0xCF, 0x20]) in window)
        assert bounded, "the loop at 0x%06X is not bounded at 0x20" % s_
        assert bytes([0x81, 0x21]) in window, \
            "the loop at 0x%06X does not `ld A,(XBC)` -- it may not be a copy" % s_
    n5a5a = sum(A.count(bytes([op, 0xCF, 0x5A, 0x5A]))
                + B.count(bytes([op, 0xCF, 0x5A, 0x5A]))
                for op in range(0xC8, 0xE0))
    assert n5a5a == 0, "%d immediate compares against 0x5A5A now exist" % n5a5a
    print("\n  block 1's 32 bytes are a literal at 0x%06X, copied to RAM by %d"
          % (LIT, len(sites)))
    print("  routines, both plain copy loops; no compare against it was found,")
    print("  so a wrong signature is not refused (see the docstring for coverage)")


TEX = []

BLOCKNAME = {
    (0x40, 0x00, 0x00): "\\textsc{system, part \\& midi} 1",
    (0x40, 0x00, 0x20): "\\textsc{system, part \\& midi} 2",
    (0x20, 0x00, 0x00): "\\textsc{sound}",
    (0x50, 0x00, 0x00): "\\textsc{combination} 1",
    (0x50, 0x06, 0x00): "\\textsc{combination} 2",
}


def main():
    import hashlib
    path = locate()
    data = open(path, "rb").read()
    got = hashlib.sha256(data).hexdigest()
    if got != KNOWN and "--any" not in sys.argv:
        raise SystemExit("unexpected capture (sha256 %s); pass --any to override" % got[:16])

    msgs = re.findall(rb"\xf0[^\xf0]*?\xf7", data)
    print("capture %s: %d bytes, %d messages" % (os.path.basename(path), len(data), len(msgs)))

    def reassemble(start):
        pl = bytearray()
        for m in msgs[start:]:
            b = m[1:-1]
            if b[:2] == b"\x50\x2d":
                chunk = b[11:-2]
            elif b[:2] == b"\x50\x7e":
                chunk = b[2:-2]
            else:
                break
            pl += chunk
            if b[-2] == 0x00:
                break
        return bytes(((pl[j] & 0x0F) << 4) | (pl[j + 1] & 0x0F)
                     for j in range(0, len(pl) - 1, 2))

    heads = [(i, m) for i, m in enumerate(msgs)
             if m[:3] == b"\xf0\x50\x2d" and len(m) > 12]
    assert heads, "no data headers in this capture"

    def septets(b):
        return (b[0] << 14) | (b[1] << 7) | b[2]

    for i, m in heads:
        declared = septets(m[9:12])
        raw = reassemble(i)
        assert len(raw) == declared, (
            "addr %s reassembled to %d, header declared %d"
            % (m[6:9].hex(" "), len(raw), declared))
        head = raw[:16]
        printable = "".join(chr(c) if 32 <= c < 127 else "." for c in head)
        # print all SIXTEEN bytes: the text column has always shown 16
        # characters, and showing 8 bytes beside them invites the reader to
        # match two columns that do not correspond.
        print("  addr %-9s %7d bytes  %s"
              % (m[6:9].hex(" ").upper(), len(raw), head.hex(" ").upper()))
        print("  %-9s %7s          '%s'" % ("", "", printable))
        TEX.append((m[6:9], len(raw), head, printable))

        if "--names" in sys.argv:
            off, names = 16, []
            while off + 16 <= len(raw):
                s = raw[off:off + 16]
                if all(32 <= c < 127 for c in s):
                    names.append(s.decode()); off += 16
                else:
                    break
            if names:
                print("      %d names from offset 16: %s ... %s"
                      % (len(names), repr(names[0]), repr(names[-1])))
    print("every transfer reassembled to exactly its declared length")
    where_from()

    if "--tex" in sys.argv:
        out = ["%% GENERATED by notes/sysex-probes/sysex_block_signatures.py --tex",
               "%% Regenerate after any change to the capture or the reassembler",
               "",
               "\\begin{center}",
               "{\\small",
               "\\begin{tabular}{llll}",
               "\\toprule",
               "block & \\textsc{adr} & first sixteen bytes & as text \\\\",
               "\\midrule"]
        for adr, n, head, printable in TEX:
            key = tuple(adr)
            out.append("%s & \\bytes{%s} & \\bytes{%s} & \\texttt{%s} \\\\"
                       % (BLOCKNAME.get(key, "?"), adr.hex(" ").upper(),
                          head[:8].hex(" ").upper(),
                          printable[:8].replace(" ", "~")))
            out.append(" & & \\bytes{%s} & \\texttt{%s} \\\\"
                       % (head[8:].hex(" ").upper(),
                          printable[8:].replace(" ", "~")))
        out += ["\\bottomrule", "\\end{tabular}", "}", "\\end{center}", ""]
        text = "\n".join(out)
        target = sys.argv[sys.argv.index("--tex") + 1]
        open(target, "w").write(text)
        print("wrote %s" % target)

    print("OK")


if __name__ == "__main__":
    main()
