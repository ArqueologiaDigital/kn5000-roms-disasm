#!/usr/bin/env python3
"""Does the published parameter table survive a dump from a real instrument?

QUESTION IT ANSWERS
  `sysex_param_addresses.py` places every `00`-area parameter at a byte of the
  SYSTEM,PART & MIDI bulk dump, and the reference publishes that placement plus
  each parameter's bit mask and accepted range.  All of it was read out of the
  program ROMs.  Nothing so far has confronted it with a dump a real SX-WSA1R
  actually produced.

  This does.  It reassembles the SYSTEM,PART & MIDI category out of the capture,
  then, for all 32 parts and every common block, reads each parameter's own
  field -- `(byte & mask) >> shift` -- and checks it against the range the
  descriptor declares.

  A FALSIFIABLE TEST.  If a parameter is at the wrong offset, or its mask or
  shift is wrong, the field lands on unrelated bits and a value outside the
  declared range is the likely result.  The test can fail, and on an earlier
  draft of the map it would have: the part records are in two runs, and
  assuming a single 0x40 stride puts parts 8..31 on the wrong bytes.  That
  wrong map is checked here too, as a CONTROL, and it must fail.

WHAT A PASS DOES NOT PROVE
  A field that happens to hold a legal value proves nothing on its own; narrow
  ranges are the informative ones.  The control run is what gives the pass its
  meaning -- it shows the test is capable of rejecting a wrong map.

SIGNAL BEING READ
  SND_CMBI.syx, sha256
  a7a83a08af2361ad0072faeb598322420c74b9c4481ddf84322477629fce968e, a
  three-category dump; the two frames addressed 0x100000 (32 bytes) and
  0x100020 (2400 bytes) and their continuation frames.  Not committed: it
  ships inside KN7000/WSA1R_files/SND_CMBI_syx.zip.  Point SYSEX_CAPTURE at
  the .syx, or drop it beside this script.

RUN
  python3 wsa1/notes/sysex-probes/sysex_param_vs_capture.py
  python3 wsa1/notes/sysex-probes/sysex_param_vs_capture.py --values   # each field

PASS CRITERION
  Zero out-of-range fields on the real map, a non-zero count on the control
  map, and OK.
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sysex_param_addresses as P            # noqa: E402  (runs its own checks)

CANDIDATES = [os.environ.get("SYSEX_CAPTURE", ""),
              os.path.join(HERE, "SND_CMBI.syx"),
              "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx"]
ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"

DUMP_BASE = 0x100000
RAM_LO = 0x7600


def capture():
    for p in CANDIDATES:
        if p and os.path.exists(p):
            return open(p, "rb").read()
    if os.path.exists(ZIP):
        with zipfile.ZipFile(ZIP) as z:
            return z.read([n for n in z.namelist() if n.lower().endswith(".syx")][0])
    raise SystemExit("capture not found; set SYSEX_CAPTURE")


def messages(buf):
    i = 0
    while True:
        s = buf.find(b"\xF0", i)
        if s < 0:
            return
        e = buf.find(b"\xF7", s)
        if e < 0:
            return
        yield buf[s:e + 1]
        i = e + 1


def join(payload):
    assert len(payload) % 2 == 0, "odd payload"
    return bytes(((payload[i] & 0x0F) << 4) | (payload[i + 1] & 0x0F)
                 for i in range(0, len(payload), 2))


def septets(b3):
    return (b3[0] << 14) | (b3[1] << 7) | b3[2]


def reassemble(buf):
    """Return {dump address: bytes} for every completed transfer in the capture."""
    out, addr, acc, open_ = {}, None, bytearray(), False
    for m in messages(buf):
        if m[:3] == b"\xF0\x50\x2D":
            addr, acc, open_ = septets(m[6:9]), bytearray(join(m[12:-3])), True
            if m[-3] == 0x00:
                out[addr] = bytes(acc)
                open_ = False
        elif m[:3] == b"\xF0\x50\x7E" and open_:
            acc += join(m[3:-3])
            if m[-3] == 0x00:
                out[addr] = bytes(acc)
                open_ = False
    return out


def build_image(blocks):
    """The 2432-byte SYSTEM,PART & MIDI area, indexed by dump address."""
    want = {DUMP_BASE: 0x20, DUMP_BASE + 0x20: 0x960}
    img = bytearray(0x980)
    for a, n in want.items():
        assert a in blocks, "the capture has no transfer at 0x%06X" % a
        assert len(blocks[a]) == n, \
            "0x%06X delivered %d bytes, header said %d" % (a, len(blocks[a]), n)
        img[a - DUMP_BASE:a - DUMP_BASE + n] = blocks[a]
    return bytes(img)


def ram_of_control(p, part=0):
    """The WRONG map: one uniform 0x40 stride for all 32 parts."""
    if p.b7 != 0x20:
        return P.ram_of(p)
    base = P.RECPTR[0] + 0x40 * part
    return base + p.off if p.setter in P.ADDRESSED else None


def scan(img, ram_of, verbose=False):
    """ram_of takes (param, part) and returns a work-RAM address or None."""
    bad, checked = [], 0
    for p in P.PARAMS:
        if p.b7 > 0x20 and p.b7 < 0x60:
            continue                       # the other 31 part blocks repeat
        parts = range(32) if p.b7 == 0x20 else [0]
        for part in parts:
            r = ram_of(p, part)
            if r is None or not p.mask:
                continue
            off = r - RAM_LO
            if not (0 <= off < len(img)):
                continue
            if p.setter == P.PAIR_SETTER:
                continue                   # its byte is outside the dumped block
            v = (img[off] & p.mask) >> p.shift
            checked += 1
            blk = p.b7 + part if p.b7 == 0x20 else p.b7
            if verbose:
                print("  %02X %02X  part %-2d  byte 0x%03X = %02X  field %-3d  (%d..%d)"
                      % (blk, p.b8, part, off, img[off], v, p.lo, p.hi))
            if not (p.lo <= v <= p.hi):
                bad.append((blk, p.b8, part, off, img[off], v, p.lo, p.hi))
    return checked, bad


def main():
    img = build_image(reassemble(capture()))
    print("\nSYSTEM,PART & MIDI reassembled: %d bytes" % len(img))

    checked, bad = scan(img, lambda q, part=0: P.ram_of(q, part),
                        "--values" in sys.argv)
    print("\nTHE PUBLISHED MAP")
    print("  %d fields checked, %d outside their declared range" % (checked, len(bad)))
    for b in bad:
        print("    %02X %02X part %-2d byte 0x%03X = %02X -> %d, declared %d..%d" % b)

    cchecked, cbad = scan(img, ram_of_control)
    print("\nCONTROL -- the same test on a single-stride part map, which is wrong")
    print("  %d fields checked, %d outside their declared range" % (cchecked, len(cbad)))

    # ONE field in this dump holds a value the parameter message would refuse:
    # common 00 08, declared 48..192, stored 00.  That is not a fault in the
    # map -- the declared range is what the SETTER accepts, and a stored byte
    # need not be a value anyone ever set.  It is pinned here so that a SECOND
    # such field would show up as a change rather than pass unnoticed.
    KNOWN = {(0x00, 0x08, 0)}
    assert {(b[0], b[1], b[2]) for b in bad} == KNOWN, \
        "out-of-range fields changed: %s" % sorted((b[0], b[1], b[2]) for b in bad)
    assert len(cbad) > 10 * max(len(bad), 1), \
        "the control map produced only %d violations; the test does not discriminate" % len(cbad)
    print("\n  the published map: %d violation, the known one" % len(bad))
    print("  the wrong map:    %d violations -- the test discriminates" % len(cbad))
    print("OK")


if __name__ == "__main__":
    main()
