#!/usr/bin/env python3
"""audit_host_packets.py -- AUDIT_HOST, read-only.

Replays the two uC-IF captures through (a) the CURRENT upd6383.cpp poke-port
decode and (b) the decode the notes give, and diffs the three resulting
address spaces.

  (a) DEVICE   : a 5-byte poke group is a DATA packet iff byte0 == 0x0A.
                 Anything else is treated as an instruction word that aims a
                 pointer; if it aims none, it is counted as `other' and the
                 auto-increment does NOT advance.
  (b) NOTES    : k3-pointers.md sect. 7 item 6 + register-space.md sect. 1.1 --
                 byte0 == 0x0B is the SAME packet with one extra flag bit;
                 44 of 1751 canned packets and 12 of the captured ones carry it.

Usage:  python3 dsp/tools/audit_host_packets.py [capture ...]
"""
import re
import sys
import os

DEFAULT = [
    os.path.expanduser(
        "~/compartilhado/kn7000_mame/notes/data/kn5000_dsp1_upload_coldboot.txt"),
    os.path.expanduser(
        "~/compartilhado/kn7000_mame/notes/data/kn5000_dsp1_upload_parametriceq.txt"),
]

XFER = re.compile(r"^transfer\s+(\d+):\s+cmd\s+0x([0-9A-Fa-f]+)")
HEXL = re.compile(r"^\s+[0-9A-Fa-f]{4}:\s+((?:[0-9A-Fa-f]{2}\s*)+)$")


def read_capture(path):
    xfers = []
    cur = None
    for line in open(path):
        m = XFER.match(line)
        if m:
            cur = {"n": int(m.group(1)), "cmd": int(m.group(2), 16), "p": []}
            xfers.append(cur)
            continue
        m = HEXL.match(line)
        if m and cur is not None:
            cur["p"] += [int(b, 16) for b in m.group(1).split()]
    return xfers


def lo12(w):
    return w & 0xFFF


def class4(w):
    return (w >> 20) & 0xF


def addr8(w):
    return (w >> 12) & 0xFF


def replay(xfers, accept_0b):
    """Return (spaces, stats).  spaces = {'15':{cell:val}, '4c':..., '26':...}"""
    sp = {0x15: {}, 0x4C: {}, 0x26: {}}
    wp = {0x15: 0, 0x4C: 0, 0x26: 0}
    cram_set = False
    st = dict(pkt=0, other=0, ptr=0, b0=dict())
    for x in xfers:
        if x["cmd"] != 0x01:
            continue
        p = x["p"]
        if len(p) < 2:
            continue
        addr = (p[0] << 8) | p[1]
        if addr != 0x0160:
            continue
        body = p[2:]
        for i in range(0, len(body) - 4, 5):
            g = body[i:i + 5]
            st["b0"][g[0]] = st["b0"].get(g[0], 0) + 1
            is_pkt = (g[0] == 0x0A) or (accept_0b and g[0] == 0x0B)
            if is_pkt:
                v = (g[1] << 16) | (g[2] << 8) | g[3]
                v = (v << 1) & 0xFFFFFF          # sect.111 x2, mask bit 31 (ON)
                if g[4] & 0x80:
                    v |= 1                        # sect.188 LSB, mask bit 63 (ON)
                tag = g[4] & 0x7F
                if tag in sp:
                    if tag == 0x26 and not cram_set:
                        pass
                    else:
                        sp[tag][wp[tag] & 0xFF] = v
                        wp[tag] = (wp[tag] + 1) & 0xFF
                    st["pkt"] += 1
                else:
                    st["other"] += 1
            else:
                w = 0
                for b in g:
                    w = (w << 8) | b
                w &= 0xFFFFFFFFF
                lo, ad = lo12(w), addr8(w)
                if lo == 0x825:
                    wp[0x4C] = ad
                    st["ptr"] += 1
                elif lo == 0x821:
                    wp[0x26] = ad
                    cram_set = True
                    st["ptr"] += 1
                elif class4(w) == 1 and lo == 0x000:
                    wp[0x15] = ad
                    st["ptr"] += 1
                else:
                    st["other"] += 1
    return sp, st


def main():
    paths = sys.argv[1:] or DEFAULT
    for path in paths:
        xf = read_capture(path)
        print("=" * 78)
        print(os.path.basename(path), "--", len(xf), "transfers")
        dev, sdev = replay(xf, accept_0b=False)
        note, snote = replay(xf, accept_0b=True)
        print("  poke byte0 histogram :",
              {hex(k): v for k, v in sorted(sdev["b0"].items())})
        print("  DEVICE  packets %4d  ptr %3d  other %3d"
              % (sdev["pkt"], sdev["ptr"], sdev["other"]))
        print("  NOTES   packets %4d  ptr %3d  other %3d"
              % (snote["pkt"], snote["ptr"], snote["other"]))
        for tag in (0x15, 0x4C, 0x26):
            d, n = dev[tag], note[tag]
            cells = sorted(set(d) | set(n))
            diff = [c for c in cells if d.get(c) != n.get(c)]
            print("  tag %02X : device %3d cells, notes %3d cells, "
                  "%d cells DIFFER" % (tag, len(d), len(n), len(diff)))
            if diff:
                print("      first 16 differing cells (cell: device -> notes)")
                for c in diff[:16]:
                    print("        %02X: %s -> %s"
                          % (c,
                             ("--" if c not in d else "0x%06X" % d[c]),
                             ("--" if c not in n else "0x%06X" % n[c])))
        # the independent control: tag-0x15 0x50.. vs tag-0x4C descriptor cells
        print("  ---- CONTROL: CHORUS tap lengths written TWICE ----")
        print("     tag-15 cells 50..57 :",
              " ".join("%02X=%s" % (c, note[0x15].get(c, "--"))
                       for c in range(0x50, 0x58)))
        print("     device            :",
              " ".join("%02X=%s" % (c, dev[0x15].get(c, "--"))
                       for c in range(0x50, 0x58)))
        print("     tag-4C cells 26..2D :",
              " ".join("%02X=%s" % (c, note[0x4C].get(c, "--"))
                       for c in range(0x26, 0x2E)))


if __name__ == "__main__":
    main()
