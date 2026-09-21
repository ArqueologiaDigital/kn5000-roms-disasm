#!/usr/bin/env python3
"""Emit the reference's worked-example appendix, with every byte computed.

QUESTION IT ANSWERS
  An implementer gets three things wrong in this format: the seven-bit address
  encoding, the high-nibble-first payload, and which bytes the checksum covers.
  One fully worked message catches all three -- but only if its bytes are right,
  and a hand-typed example is exactly where they stop being right.

  So no byte in the appendix is typed.  The parameter examples come from
  `sysex_param_wire_format.py`, which builds them from the decoded grammar.  The
  bulk-dump example is lifted from a dump a real SX-WSA1R put on the wire, and
  this script re-encodes that frame from its own decoded payload and asserts the
  reconstruction is byte-identical to the capture -- so the encoder printed in
  the appendix is demonstrably the encoder the instrument used.

SIGNAL BEING READ
  * `sysex_param_wire_format.py` stdout, its WORKED EXAMPLE block.
  * SND_CMBI.syx, a SOUND + COMBINATION dump, 728254 bytes, 2883 messages,
    sha256 a7a83a08af2361ad0072faeb598322420c74b9c4481ddf84322477629fce968e.
    Not committed: it is a regenerable capture that ships inside the community
    archive KN7000/WSA1R_files/SND_CMBI_syx.zip.  Point SYSEX_CAPTURE at the
    .syx, or drop it beside this script.

RUN
  python3 wsa1/notes/sysex-probes/sysex_examples_tex.py \
      wsa1/docs/system-exclusive-reference/tbl-examples.tex

PASS CRITERION
  The re-encoded frame equals the captured frame byte for byte, every printed
  checksum re-verifies, and the script prints OK.
"""
import os
import re
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
WIRE = os.path.join(HERE, "sysex_param_wire_format.py")

CAPTURE_CANDIDATES = [
    os.environ.get("SYSEX_CAPTURE", ""),
    os.path.join(HERE, "SND_CMBI.syx"),
    "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx",
]
CAPTURE_ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"

# The eight blocks, by the (address, length) pair their header carries.  The
# capture below contains five of them, spanning THREE categories -- its name
# says SND_CMBI, but it opens with SYSTEM,PART & MIDI.
BLOCKS = {
    ("40 00 00", "00 00 20"): ("system, part \\& midi", 1),
    ("40 00 20", "00 12 60"): ("system, part \\& midi", 2),
    ("20 00 00", "10 00 00"): ("sound", 1),
    ("50 00 00", "00 06 00"): ("combination", 1),
    ("50 06 00", "05 40 00"): ("combination", 2),
}


# ------------------------------------------------------------ the format
def checksum(body):
    """body = every byte from the 50 identifier through the continuation flag."""
    return (0 - sum(body)) & 0x7F


def to_nibbles(src):
    out = bytearray()
    for b in src:
        out.append(b >> 4)
        out.append(b & 0x0F)
    return bytes(out)


def from_nibbles(payload):
    assert len(payload) % 2 == 0, "an odd payload is invalid"
    return bytes(((payload[i] & 0x0F) << 4) | (payload[i + 1] & 0x0F)
                 for i in range(0, len(payload), 2))


def septets(value):
    return bytes([(value >> 14) & 0x7F, (value >> 7) & 0x7F, value & 0x7F])


def unseptets(b):
    return (b[0] << 14) | (b[1] << 7) | b[2]


# ------------------------------------------------- the capture, for proof
def load_capture():
    for p in CAPTURE_CANDIDATES:
        if p and os.path.exists(p):
            return open(p, "rb").read()
    if os.path.exists(CAPTURE_ZIP):
        with zipfile.ZipFile(CAPTURE_ZIP) as z:
            name = [n for n in z.namelist() if n.lower().endswith(".syx")][0]
            return z.read(name)
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


def first_data_frame(buf):
    for m in messages(buf):
        if m[:3] == b"\xF0\x50\x2D":
            return m
    raise SystemExit("no 2D data frame in the capture")


def prove_encoder(frame):
    """Re-encode the captured frame from its own decoded payload."""
    assert frame[0] == 0xF0 and frame[-1] == 0xF7
    head, payload = frame[:12], frame[12:-3]   # head includes the leading F0
    flag, sums = frame[-3], frame[-2]
    src = from_nibbles(payload)
    rebuilt = head + to_nibbles(src) + bytes([flag])
    rebuilt += bytes([checksum(rebuilt[1:])]) + bytes([0xF7])
    assert rebuilt == frame, "the re-encoded frame differs from the capture"
    assert checksum(frame[1:-2]) == sums, "the captured checksum does not verify"
    return head, src


# --------------------------------------------- the parameter examples
EX = re.compile(r"^\s{2,}(?:(write|request|reply)\s+)?(F0(?: [0-9A-F]{2})+ F7)\s*$")


def wire_examples():
    out = subprocess.run([sys.executable, WIRE], capture_output=True,
                         text=True, check=True).stdout
    block = out.split("WORKED EXAMPLE", 1)[1].split("PORTS", 1)[0]
    lines, label = [], None
    for raw in block.splitlines():
        m = EX.match(raw)
        if m:
            lines.append((m.group(1) or label, m.group(2)))
        elif raw.strip().startswith("the same parameter"):
            label = "part 7"
        elif raw.strip().startswith("a three-byte parameter"):
            label = "three-byte"
    assert len(lines) >= 5, "the probe's worked examples moved"
    # every one must re-verify under the rule stated in the document
    for _, hexs in lines:
        b = bytes(int(x, 16) for x in hexs.split())
        assert checksum(b[1:-2]) == b[-2], "example %s fails its own checksum" % hexs
    return lines, out.split("WORKED EXAMPLE", 1)[1].splitlines()[0].strip()


def main():
    lines, caption = wire_examples()
    head, src = prove_encoder(first_data_frame(load_capture()))
    addr, count = unseptets(head[6:9]), unseptets(head[9:12])

    o = []
    w = o.append
    w("%% GENERATED by notes/sysex-probes/sysex_examples_tex.py -- do not edit")
    w("")
    w("\\section{A parameter, written and read back}")
    w("The example is %s." % caption.lower().replace("worked example", "").strip()
      .replace("part 0, parameter 03 (one byte, 0..127), set to 100",
               "part~0's parameter \\bytes{03}, a one-byte value, set to 100"))
    w("")
    w("\\begin{center}")
    w("\\begin{tabular}{ll}")
    w("\\toprule")
    w("& message \\\\")
    w("\\midrule")
    for label, hexs in lines:
        w("%s & \\bytes{%s} \\\\" % (label or "", hexs))
    w("\\bottomrule")
    w("\\end{tabular}")
    w("\\end{center}")
    w("")
    w("The value 100 is \\bytes{64}, which \\textsc{dt} carries as the two bytes")
    w("\\bytes{06 04}. The three bytes before it are \\textsc{siz}, and the \\bytes{00}")
    w("after it is \\textsc{cn}. \\textsc{sm} closes the message.")
    w("")
    ahex = " ".join("%02X" % b for b in head[6:9])
    lhex = " ".join("%02X" % b for b in head[9:12])
    block, part = BLOCKS[(ahex, lhex)]

    w("\\section{A frame from a real instrument}")
    w("The bytes below open the first data message of a dump recorded from an")
    w("SX-WSA1R, a transfer of three categories in one session:")
    w("")
    w("\\begin{center}")
    w("\\bytes{%s \\ldots}" % " ".join("%02X" % b for b in head))
    w("\\end{center}")
    w("")
    w("Reading it by the rules of chapter~\\ref{ch:bulk}: \\textsc{cmd} is \\bytes{2D}")
    w("\\textsc{btr}; \\bytes{%s} are \\textsc{pc}, \\textsc{md} and \\textsc{ver}, the"
      % " ".join("%02X" % b for b in head[3:6]))
    w("middle one being the rack's; then \\textsc{adr} \\bytes{%s} and \\textsc{siz}"
      % ahex)
    w("\\bytes{%s}," % lhex)
    w("which together name block~%d of \\textsc{%s}. The length decodes to %s source"
      % (part, block, format(count, ",d")))
    w("bytes and the frame carries %d of them." % len(src))
    w("")
    w("The payload decodes to \\bytes{%s}\\ldots, the signature chapter~5 gives for"
      % " ".join("%02X" % b for b in src[:8]))
    w("that block.")
    w("")
    w("That block is the one chapter~\\ref{ch:params} maps: a dump of this category can be")
    w("read against table~\\ref{tbl:partparams} directly, which is the cheapest way to")
    w("confirm a parameter address without an instrument to hand.")

    text = "\n".join(o) + "\n"
    if len(sys.argv) > 1:
        open(sys.argv[1], "w").write(text)
        print("wrote %s" % sys.argv[1])
    else:
        sys.stdout.write(text)

    print("  %d parameter examples, all checksums re-verified" % len(lines))
    print("  captured frame re-encoded byte-identically: address %d, length %d, %d bytes"
          % (addr, count, len(src)))
    print("OK")


if __name__ == "__main__":
    main()
