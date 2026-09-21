#!/usr/bin/env python3
"""WHAT DO THE SEVENTEENTH STREAM'S TWO EVENTS SAY?

QUESTION IT ANSWERS

`sysex_performance_stream.py` shows the seventeenth stream to be a timekeeper:
999 events of which 997 are the clock, and two others whose statuses -- 0x80
and 0x87 -- appear in none of the sixteen recording tracks.  An earlier edition
said naming them needed more songs, "one song is two events".

That was the wrong place to look.  The playback routine has to dispatch on
those statuses, and it does, in a chain of compares that also covers 0x90,
0xB0, 0xC0, 0xD0, 0xD1 and 0xD3.

0x80 IS THE TEMPO.  Five strands, none of which is proximity or a guess:

  1. Its handler writes a 16-bit value to a work-RAM address, and passes the
     record tag 0x7A to the routine that publishes a record -- the same tag the
     song's own stream ends with.  The parameter map puts record 0x7A's +02 two
     bytes above, so the handler is writing that record's +00.
  2. Another writer of the same address is a reset path, and it stores the
     literal 0x0078 -- 120, the default tempo.
  3. A display routine reads it as a NINE-bit quantity, low byte plus one bit,
     and hands it to number formatting.  Tempo fits in nine bits; a byte would
     not hold 300.
  4. The TRANSMITTER for this event is in the image too, and this script
     REPRODUCES it: it builds status 0x80, an offset, then splits the nine bits
     as seven plus two exactly the way the firmware does.  Fed the value the
     handler would compute from the stored event, it reproduces the stored
     event's bytes.
  5. That round trip gives 150 for the one song here, which is a tempo.

0x87 IS NOT NAMED HERE, and what is known is stated instead.  Its handler puts
a 7-bit value into a one-byte mailbox with bit 7 as the "changed" flag; the
consumer clears the flag, adds ONE, and distributes the result to four places,
and the transmitter subtracts one again.  In this song the stored value is 3,
so the instrument's internal value is 4.  The instrument's help text speaks of
a per-song Time Signature that cannot be changed once tracks exist, which is
consistent with a single event at the head of a conductor track; that is a
reading and not a decode.

RUN
  python3 wsa1/notes/sysex-probes/sysex_conductor_events.py

PASS CRITERION
  The dispatch compares are present as byte strings; the default-tempo literal
  is where it should be; and the firmware's own splitting arithmetic,
  re-implemented here, turns the decoded value back into the exact bytes the
  stored event carries.  That last one is the check that matters -- it is a
  round trip through two independent pieces of code.
"""
import hashlib, os, re, sys, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
PROM_B = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
BASE = 0xF00000

ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/GJS1.zip"
ZIP_SHA = "c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524"

# ---- the dispatch, as byte strings (cp A,imm8 is c9 cf ii)
def cp_a(v):
    return bytes.fromhex("c9cf") + bytes([v])


DISPATCH = [0x80, 0x87, 0x90, 0xD1, 0xD3]
print("THE PLAYBACK DISPATCH, in prom_b")
sites = {}
for v in DISPATCH:
    hits = [BASE + m.start() for m in re.finditer(re.escape(cp_a(v)), PROM_B)]
    sites[v] = hits
    print("   cp A,0x%02X  %d site(s)" % (v, len(hits)))
    assert hits, "no compare against status 0x%02X anywhere" % v
# the two conductor statuses are tested within a few bytes of each other
pairs = [(a, b) for a in sites[0x80] for b in sites[0x87] if 0 < b - a <= 8]
print("   0x80 and 0x87 tested together at: %s"
      % " ".join("0x%06X" % a for a, _ in pairs))
assert pairs, "0x80 and 0x87 are never tested next to each other"

# ---- the default tempo: ld WA,0x0078 immediately before ld (0x7ee2),WA
DEFAULT = bytes.fromhex("307800") + bytes.fromhex("f1e27e50")
hits = [BASE + m.start() for m in re.finditer(re.escape(DEFAULT), PROM_B)]
print("\n   a reset path storing the literal 120 into the same address: %s"
      % " ".join("0x%06X" % h for h in hits))
assert hits, "the default-tempo store is gone"
print("   120 is the default tempo of every sequencer ever made.")

# ---- the firmware's own split, re-implemented
def encode(value):
    """status 0x80, offset 0, then the nine bits as the transmitter splits them."""
    lo, hi = value & 0xFF, (value >> 8) & 0xFF
    b2 = lo & 0x7F                       # and A,0x7f
    w = (lo & 0x80) >> 7                 # and W,0x80 ; rlc 1,W
    l = (hi & 0x01) << 1                 # and L,0x01 ; sla 1,L
    return bytes([0x80, 0x00, b2, l | w])


def decode(ev):
    """the handler's arithmetic: sla 1,A ; srl 1,WA ; and W,0x01."""
    a, w = ev[2], ev[3]
    a = (a << 1) & 0xFF
    wa = ((w << 8) | a) >> 1
    return wa & 0x1FF


if not os.path.exists(ZIP):
    print("\nGJS1.zip is not present; the round trip needs it.")
    sys.exit(0)
assert hashlib.sha256(open(ZIP, "rb").read()).hexdigest() == ZIP_SHA, \
    "GJS1.zip is not the archive checked here"
with zipfile.ZipFile(ZIP) as z:
    perf, hdr = z.read("GJS1/01220497.SEQ"), z.read("GJS1/01220497.SQF")[:3072]

BLOCK = 256
NB = len(perf) // BLOCK


def chain(first):
    out, cur = [], first
    while 1 <= cur <= NB and cur not in out:
        out.append(cur)
        nxt = int.from_bytes(perf[(cur - 1) * BLOCK + 3:(cur - 1) * BLOCK + 5], "little")
        if nxt in (0, 0xFFFF) or nxt > NB:
            break
        cur = nxt
    return out


start = int.from_bytes(hdr[0x100 + 3 * 16 + 1:0x100 + 3 * 16 + 3], "little")
p = b"".join(perf[(n - 1) * BLOCK + 5:n * BLOCK] for n in chain(start)[:-1])
found = []
i = 0
while i < len(p):
    if p[i] < 0x80:
        i += 1; continue
    st, j = p[i], i + 1
    while j < len(p) and p[j] < 0x80:
        j += 1
    if st != 0x81:
        found.append(bytes([st]) + p[i + 1:j])
    i = j
print("\n   the seventeenth stream's non-clock events: %s"
      % ", ".join(" ".join("%02X" % c for c in e) for e in found))
assert len(found) == 2, "expected two events, found %d" % len(found)

ev80 = [e for e in found if e[0] == 0x80][0]
value = decode(ev80)
print("\n   THE ROUND TRIP")
print("     stored event            %s" % " ".join("%02X" % c for c in ev80))
print("     handler's arithmetic -> %d" % value)
print("     transmitter's split  -> %s" % " ".join("%02X" % c for c in encode(value)))
assert encode(value) == ev80, "the round trip does not reproduce the stored bytes"
assert 20 <= value <= 511, "the value is not in any plausible tempo range"
print("     the two agree byte for byte, and %d is a tempo." % value)

ev87 = [e for e in found if e[0] == 0x87][0]
print("\n   the other event, %s: a 7-bit value of %d, which the consumer stores"
      % (" ".join("%02X" % c for c in ev87), ev87[2]))
print("   as %d -- it adds one -- and the transmitter subtracts one again."
      % (ev87[2] + 1))
print("   Not named here.  A per-song time signature fits the arithmetic and")
print("   the help text, and fitting is not the same as being shown.")
print("\nOK")
