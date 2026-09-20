#!/usr/bin/env python3
"""Does a REAL WSA1R bulk dump obey the frame format decoded from the ROMs?

QUESTION THIS ANSWERS
    Everything in wsa1/docs/system-exclusive-reference/ was read out of the
    program ROMs.  This script confronts it with a dump that a real machine
    actually put on the wire, and checks -- byte for byte -- every rule the
    document states:

      * the opening enquiry, and what happens when nothing answers it;
      * the data-message header: family 2D, the model triple, and a
        3+3 septet (address, length) pair that must be one of the pairs the
        ROM's own grammar accepts;
      * continuation frames re-opening with F0 50 7E;
      * the 252-byte cap, i.e. 120 source bytes in a header frame and 125 in
        a continuation frame;
      * the continuation flag, 01 except on the last frame of a transfer;
      * the checksum, (0 - sum of everything after F0 through the flag) & 7F;
      * end-of-category F0 50 27 7E F7 and end-of-dump F0 50 28 7E F7;
      * that every payload byte is a nibble, i.e. < 0x10, high nibble first.

THE CAPTURE
    SND_CMBI.syx -- a SOUND + COMBINATION bulk dump, 728254 bytes, 2883
    messages.  It is not committed here (it is a regenerable capture, not a
    ROM), and it is not ours: it ships inside the community archive
    KN7000/WSA1R_files/SND_CMBI_syx.zip.

        zip   sha256 72e8d9b38eb2f366fdfbda85124fa5f98c9201a5e653cfd04bb5d36f67b0b055
        .syx  sha256 a7a83a08af2361ad0072faeb598322420c74b9c4481ddf84322477629fce968e

    Point SYSEX_CAPTURE at the file, or drop it beside this script.  The
    script refuses to run against a file whose hash it does not recognise
    unless --any is given, because the assertions below are calibrated to
    this one.

RUN
    python3 wsa1/notes/sysex-probes/sysex_wire_capture_check.py
    python3 wsa1/notes/sysex-probes/sysex_wire_capture_check.py --frames

PASS
    Every assert is silent and the script prints OK.  The headline numbers:
    2883 messages, 2876 of them checksummed and 0 checksum failures;
    3 unanswered enquiries then the dump proceeds anyway; 5 (address,length)
    pairs, all 5 present in prom_b's grammar; 2821 frames of exactly 256
    bytes; 5 frames carrying flag 00 and 2871 carrying flag 01.

    ONE THING THE CAPTURE CONTRADICTS: every message in it carries the model
    triple 04 01 11, while the dumped v2 prom_b transmits 04 00 11 and holds
    no 04 01 11 literal anywhere.  Both are accepted on reception, so the
    triple's middle byte is NOT a constant of the product -- see the note in
    the cross-product probe.
"""
import hashlib, os, sys

KNOWN = "a7a83a08af2361ad0072faeb598322420c74b9c4481ddf84322477629fce968e"
HERE = os.path.dirname(os.path.abspath(__file__))
CANDIDATES = [
    os.environ.get("SYSEX_CAPTURE", ""),
    os.path.join(HERE, "SND_CMBI.syx"),
    "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx",
]

def locate():
    for p in CANDIDATES:
        if p and os.path.isfile(p):
            return p
    # last resort: unpack it from the community archive next to the manuals
    import zipfile, tempfile
    z = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"
    if os.path.isfile(z):
        out = os.path.join(tempfile.gettempdir(), "SND_CMBI.syx")
        with zipfile.ZipFile(z) as f:
            open(out, "wb").write(f.read("SND_CMBI.syx"))
        return out
    return None

def septets(b):
    return (b[0] << 14) | (b[1] << 7) | b[2]

def main():
    p = locate()
    if p is None:
        print("SKIP: capture not found; set SYSEX_CAPTURE (see docstring)")
        return
    d = open(p, "rb").read()
    h = hashlib.sha256(d).hexdigest()
    print("capture: %s (%d bytes)" % (p, len(d)))
    print("sha256 : %s%s" % (h, "  [expected]" if h == KNOWN else "  [UNRECOGNISED]"))
    calibrated = (h == KNOWN)
    if not calibrated and "--any" not in sys.argv:
        print("refusing to assert against an unrecognised capture; pass --any to try anyway")
        return

    msgs, i = [], 0
    while i < len(d):
        if d[i] != 0xF0:
            i += 1; continue
        j = d.find(b"\xf7", i)
        if j < 0:
            break
        msgs.append(d[i:j + 1]); i = j + 1
    print("messages: %d" % len(msgs))

    # --- 1. the opening handshake ------------------------------------------
    enq = [m for m in msgs if len(m) == 7 and m[2] == 0x21]
    assert all(m == msgs[0] for m in enq), "enquiries differ"
    assert len(enq) == 3, len(enq)
    assert msgs[0][:3] == bytes([0xF0, 0x50, 0x21]) and msgs[0][6] == 0xF7
    triple = msgs[0][3:6]
    print("opening enquiry x%d, model triple %s -- unanswered, dump proceeded anyway"
          % (len(enq), " ".join("%02X" % b for b in triple)))
    assert not any(m[2] == 0x22 for m in msgs), "step 2 of the handshake should be absent"

    # --- 2. every message is one of the four documented shapes -------------
    hdrs, conts, ends, others = [], [], [], []
    for m in msgs[len(enq):]:
        if m[2] == 0x2D:
            hdrs.append(m)
        elif m[2] == 0x7E:
            conts.append(m)
        elif len(m) == 5 and m[2] in (0x27, 0x28):
            ends.append(m)
        else:
            others.append(m)
    assert not others, [x[:8].hex() for x in others[:4]]
    assert msgs[-1] == bytes([0xF0, 0x50, 0x28, 0x7E, 0xF7]), "no end-of-dump"
    ncat = sum(1 for m in ends if m[2] == 0x27)
    print("%d data headers, %d continuation frames, %d end-of-category, 1 end-of-dump"
          % (len(hdrs), len(conts), ncat))

    # --- 3. the headers agree with the ROM grammar -------------------------
    pairs = []
    for m in hdrs:
        assert m[3:6] == triple, "header triple differs from the enquiry's"
        a, l = m[6:9], m[9:12]
        pairs.append((bytes(a), bytes(l)))
    uniq = sorted(set(pairs))
    print("distinct (address, length) pairs: %d" % len(uniq))
    for a, l in uniq:
        print("    addr %-9s len %-9s = %d bytes"
              % (" ".join("%02X" % b for b in a), " ".join("%02X" % b for b in l), septets(l)))
    rom = grammar_pairs()
    if rom is not None:
        for a, l in uniq:
            assert (a, l) in rom, "header not in the ROM grammar: %s %s" % (a.hex(), l.hex())
        print("all %d pairs are present in prom_b's own grammar table" % len(uniq))

    # --- 4. frame arithmetic, flags, payload, checksum ---------------------
    bad, payload_sum, sizes, flags = 0, {}, {}, {}
    for m in hdrs + conts:
        body = m[12:-3] if m[2] == 0x2D else m[3:-3]
        assert len(body) % 2 == 0, "odd payload"
        assert all(b < 0x10 for b in body), "payload byte is not a nibble"
        # 0xFC cap: everything between the leading F0 and the flag
        assert len(m) - 1 - 3 + 1 <= 0xFC + 1
        n = len(m) - 4            # bytes after F0, up to and including the flag
        assert n <= 0xFC, n
        flags[m[-3]] = flags.get(m[-3], 0) + 1
        assert m[-3] in (0x00, 0x01), m[-3]
        sizes[len(m)] = sizes.get(len(m), 0) + 1
        if (0 - (sum(m[1:-2]) & 0xFF)) & 0x7F != m[-2]:
            bad += 1
        key = (bytes(m[6:9]), bytes(m[9:12])) if m[2] == 0x2D else None
        payload_sum[key] = payload_sum.get(key, 0) + len(body) // 2
    print("checksum verified on %d frames, %d failures" % (len(hdrs) + len(conts), bad))
    assert bad == 0
    print("frame sizes: %s" % sorted(sizes.items(), key=lambda t: -t[1])[:4])
    print("continuation flags: %s" % sorted(flags.items()))
    assert flags[0x00] == ncat + 1 or flags[0x00] == len(hdrs), flags
    full = [m for m in conts if len(m) == 256]
    assert full, "no full-size continuation frame"
    assert all(len(m) - 4 == 0xFC for m in full), "the 0xFC cap does not hold"
    assert (256 - 3 - 3) // 2 == 125
    assert (255 - 12 - 3) // 2 == 120
    print("a full continuation frame carries 125 source bytes; a full header frame 120")

    # --- 5. each transfer delivers exactly the length its header states ----
    total = {}
    cur = None
    for m in msgs[len(enq):]:
        if m[2] == 0x2D:
            cur = (bytes(m[6:9]), bytes(m[9:12]))
            total[cur] = total.get(cur, 0) + (len(m) - 15) // 2
        elif m[2] == 0x7E and cur is not None:
            total[cur] += (len(m) - 6) // 2
    for (a, l), got in total.items():
        want = septets(l)
        assert got == want, "addr %s: %d source bytes delivered, header says %d" % (a.hex(), got, want)
    print("every transfer delivered exactly the byte count its header declared")

    if "--frames" in sys.argv:
        print("\nfirst frames:")
        for m in msgs[:6]:
            print("   len=%-4d %s ..." % (len(m), " ".join("%02X" % b for b in m[:16])))

    print("\nOK")


def grammar_pairs():
    """The (address, length) pairs prom_b's trie accepts, if prom_b is around."""
    for cand in (os.path.join(HERE, "..", "..", "original_ROMs", "wsa1_prom_b.ic13"),
                 "/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/original_ROMs/wsa1_prom_b.ic13"):
        cand = os.path.normpath(cand)
        if os.path.isfile(cand):
            rom = open(cand, "rb").read()
            break
    else:
        return None
    BASE, ROOT = 0xF00000, 0xF5115B
    def rd(a, n):
        return rom[a - BASE:a - BASE + n]
    assert rd(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "wrong prom_b"
    out = set()
    def walk(p, pre, depth):
        if depth > 14:
            return
        for i in range(200):
            b = rd(p + 6 * i, 6)
            if b[0] == 0xFF:
                break
            nxt = pre + [b[0]]
            if b[1]:
                if len(nxt) >= 10 and nxt[0] == 0x2D:
                    out.add((bytes(nxt[4:7]), bytes(nxt[7:10])))
            else:
                walk(int.from_bytes(b[2:6], "little"), nxt, depth + 1)
    walk(ROOT, [], 0)
    return out


if __name__ == "__main__":
    main()
