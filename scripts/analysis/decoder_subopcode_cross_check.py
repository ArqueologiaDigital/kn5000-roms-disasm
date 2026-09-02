#!/usr/bin/env python3
"""decoder_subopcode_cross_check.py -- ask a SECOND decoder about every
sub-opcode of every TLCS-900 prefix table, and report where this backend
disagrees with it.

QUESTION IT ANSWERS
    "For prefix P, which of the 256 sub-opcodes does llvm-objdump read as a
     different instruction than MAME's unidasm, and which does it print as a
     text that re-encodes to different bytes?"

    `decode_encode_asymmetry_sweep.py` finds the misdecodes that actually occur
    in this tree's ROMs.  This one finds the ones that COULD -- it walks the
    encoding space table by table, so a wrong entry is found even if no image
    happens to contain it yet.  It is also what settles WHICH SIDE IS WRONG:
    unidasm is an independent decoder with no stake in this backend, so where
    unidasm and this backend's ENCODER agree and its DECODER does not, the
    decoder is the defect.

    ⚠ unidasm is a second opinion, not the ROM.  Where the two decoders agree
    the entry is corroborated; where they disagree this script reports the
    disagreement as the finding and does not pick a winner on its own.

CLASSES
    AGREE       same mnemonic and same length, and the printed text re-encodes
                to the bytes it was decoded from.
    ASYM        both decoders agree on the instruction, but llvm's printed text
                re-encodes to DIFFERENT bytes (an encoder/printer mismatch).
    MNEMONIC    the printed text DOES re-encode to the bytes it came from, but
                the two decoders name the instruction differently.  Usually a
                spelling convention (`ldcfm` vs `ldcf`), occasionally a real
                misreading that happens to be self-consistent.
    LENGTH      the two decoders consume a different number of bytes.
    LLVM-NONE   llvm refuses; unidasm decodes.   (a decoder gap)
    UNI-NONE    unidasm refuses; llvm decodes.  ⚠ NOT harmless: a decode MAME
                leaves undefined is exactly what lets a linear sweep walk
                through a data table and keep producing plausible code.
    BOTH-NONE   neither decodes -- almost always genuinely undefined space.

RUN
    python3 scripts/analysis/decoder_subopcode_cross_check.py
    python3 scripts/analysis/decoder_subopcode_cross_check.py --family B8
    python3 scripts/analysis/decoder_subopcode_cross_check.py --selftest
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from decode_encode_asymmetry_sweep import (batch_decode, batch_encode,  # noqa: E402
                                           toolchain)

PROJECTS = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
UNIDASM = os.path.join(PROJECTS, "mame", "unidasm")

TRAIL = bytes([0x00] * 8)   # filler beyond the sub-opcode

# name -> (prefix bytes, filler between prefix and sub-opcode)
# The filler is the displacement / direct address the prefix carries; its VALUE
# is irrelevant to which instruction the sub-opcode names, which is what this
# script compares.
FAMILIES = [
    ("80", bytes([0x80]),                   b""),            # (XWA)      src byte
    ("88", bytes([0x88]),                   b"\x04"),        # (XWA+d8)   src byte
    ("90", bytes([0x90]),                   b""),            # (XWA)      src word
    ("98", bytes([0x98]),                   b"\x04"),        # (XWA+d8)   src word
    ("A0", bytes([0xA0]),                   b""),            # (XWA)      src long
    ("A8", bytes([0xA8]),                   b"\x04"),        # (XWA+d8)   src long
    ("B0", bytes([0xB0]),                   b""),            # (XWA)      dst
    ("B8", bytes([0xB8]),                   b"\x04"),        # (XWA+d8)   dst
    ("C0", bytes([0xC0]),                   b"\x34"),        # (n8)       src byte
    ("C1", bytes([0xC1]),                   b"\x34\x12"),    # (n16)      src byte
    ("C2", bytes([0xC2]),                   b"\x56\x34\x12"),# (n24)      src byte
    ("D0", bytes([0xD0]),                   b"\x34"),        # (n8)       src word
    ("D1", bytes([0xD1]),                   b"\x34\x12"),    # (n16)      src word
    ("D2", bytes([0xD2]),                   b"\x56\x34\x12"),# (n24)      src word
    ("E0", bytes([0xE0]),                   b"\x34"),        # (n8)       src long
    ("E1", bytes([0xE1]),                   b"\x34\x12"),    # (n16)      src long
    ("E2", bytes([0xE2]),                   b"\x56\x34\x12"),# (n24)      src long
    ("F0", bytes([0xF0]),                   b"\x34"),        # (n8)       dst
    ("F1", bytes([0xF1]),                   b"\x34\x12"),    # (n16)      dst
    ("F2", bytes([0xF2]),                   b"\x56\x34\x12"),# (n24)      dst
    ("C8", bytes([0xC8]),                   b""),            # r8  (W)   register
    ("D8", bytes([0xD8]),                   b""),            # r16 (WA)  register
    ("E8", bytes([0xE8]),                   b""),            # r32 (XWA) register
]

UNI_RE = re.compile(r'^\s*0:\s((?:[0-9a-f]{2} )+)\s*(.*)$')


def unidasm_one(blob, tmpdir):
    p = os.path.join(tmpdir, "u.bin")
    open(p, "wb").write(blob)
    r = subprocess.run([UNIDASM, p, "-arch", "tlcs900"],
                       capture_output=True, text=True)
    for line in r.stdout.splitlines():
        m = UNI_RE.match(line)
        if m:
            nb = len(m.group(1).split())
            txt = m.group(2).strip()
            if txt == "db" or txt.startswith("db "):
                return None
            return (nb, txt)
    return None


def mnemonic(t):
    return re.split(r'[\s,]', t.strip(), maxsplit=1)[0].lower()


def run_family(name, prefix, filler, show_all=False):
    blobs, subs = [], []
    for sub in range(256):
        blobs.append(prefix + filler + bytes([sub]) + TRAIL)
        subs.append(sub)
    dec = batch_decode(blobs)
    texts, idxs = [], []
    for i, d in enumerate(dec):
        if d is not None and not d[1].startswith("<unknown>"):
            idxs.append(i)
            texts.append(d[1])
    enc = batch_encode(texts)
    encof = {j: enc[k] for k, j in enumerate(idxs)}
    rows = []
    with tempfile.TemporaryDirectory() as td:
        for i, sub in enumerate(subs):
            u = unidasm_one(blobs[i], td)
            d = dec[i]
            llvm_ok = d is not None and not d[1].startswith("<unknown>")
            if not llvm_ok and u is None:
                cls = "BOTH-NONE"
                rows.append((sub, cls, "", "" if u is None else u[1], ""))
                continue
            if not llvm_ok:
                rows.append((sub, "LLVM-NONE", "", u[1], ""))
                continue
            if u is None:
                rows.append((sub, "UNI-NONE", d[1], "", ""))
                continue
            e = encof.get(i)
            es = e.hex(" ") if e else "REJECTED"
            # ⚠ ORDER MATTERS.  ASYM is judged on BYTES and is objective; a
            # mnemonic difference is often only a naming convention (this
            # backend spells LDCF `ldcfm`, INC (mem) `incdi8`, ...).  Testing
            # the name first hid 40 real byte-level asymmetries behind a
            # cosmetic label on the first run of this script.
            if len(d[0]) != u[0]:
                cls = "LENGTH"
            elif e != d[0]:
                cls = "ASYM"
            elif mnemonic(d[1]) != mnemonic(u[1]) and not _alias(d[1], u[1]):
                cls = "MNEMONIC"
            else:
                cls = "AGREE"
            rows.append((sub, cls, d[1], u[1], es))
    return rows


# Spellings this backend uses that name the same instruction as unidasm's.
# Kept SMALL and explicit: an over-eager alias list would hide real disagreement.
_ALIASES = {
    ("ldirw", "ldir"), ("ldiw", "ldi"), ("lddrw", "lddr"), ("lddw", "ldd"),
    ("cpirw", "cpir"), ("cpiw", "cpi"), ("cpdrw", "cpdr"), ("cpdw", "cpd"),
    ("pushw", "push"), ("popw", "pop"), ("ldw", "ld"), ("cpw", "cp"),
    ("bitda", "bit"), ("setda", "set"), ("resda", "res"), ("tsetda", "tset"),
    ("bitm", "bit"), ("setm", "set"), ("resm", "res"), ("tsetm", "tset"),
    ("incw", "inc"), ("decw", "dec"), ("addw", "add"), ("subw", "sub"),
    ("andw", "and"), ("orw", "or"), ("xorw", "xor"), ("exw", "ex"),
    ("mulw", "mul"), ("divw", "div"), ("rldm", "rld"), ("rrdm", "rrd"),
}


def _alias(a, b):
    ma, mb = mnemonic(a), mnemonic(b)
    ma = ma.split("_")[0]
    mb = mb.split("_")[0]
    return ma == mb or (ma, mb) in _ALIASES or (mb, ma) in _ALIASES


def run(only=None, show_all=False):
    print("toolchain: tlcs900_backend@%s   unidasm: %s" % (toolchain(), UNIDASM))
    grand = Counter()
    for name, prefix, filler in FAMILIES:
        if only and name.upper() not in only:
            continue
        rows = run_family(name, prefix, filler)
        c = Counter(r[1] for r in rows)
        grand.update(c)
        # ⚠ UNI-NONE is printed, not just counted.  A form THIS BACKEND decodes
        # and MAME leaves undefined is the shape that lets a linear sweep walk
        # through a data table emitting plausible instructions -- EXTS8 (C8+r,
        # 0x13) and CALL_DD8 (F0, addr8, 0x08) are both in this class, and all
        # eight of their sites in the tree sit in data-framed-as-code regions.
        bad = [r for r in rows
               if r[1] in ("ASYM", "MNEMONIC", "LENGTH", "LLVM-NONE", "UNI-NONE")]
        print("\n=== prefix %s%s ===  AGREE %d  ASYM %d  MNEMONIC %d  LENGTH %d  "
              "LLVM-NONE %d  UNI-NONE %d  BOTH-NONE %d"
              % (name, " " + filler.hex(" ") if filler else "", c["AGREE"],
                 c["ASYM"], c["MNEMONIC"], c["LENGTH"], c["LLVM-NONE"],
                 c["UNI-NONE"], c["BOTH-NONE"]))
        for sub, cls, lt, ut, es in (rows if show_all else bad):
            if cls == "LLVM-NONE" and not show_all:
                continue
            print("  %02x  %-9s llvm=%-30s uni=%-28s reenc=%s"
                  % (sub, cls, lt.replace("\t", " ")[:30], ut[:28], es))
    print("\nTOTALS  " + "  ".join("%s %d" % (k, grand[k]) for k in
          ("AGREE", "ASYM", "MNEMONIC", "LENGTH", "LLVM-NONE", "UNI-NONE", "BOTH-NONE")))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("unidasm exists", os.path.exists(UNIDASM))
    with tempfile.TemporaryDirectory() as td:
        u = unidasm_one(bytes([0x11, 0x11, 0x11]), td)
        ck("unidasm decodes 0x11 as scf", u is not None and mnemonic(u[1]) == "scf",
           str(u))
        u2 = unidasm_one(bytes([0x1f, 0x1f, 0x1f, 0x1f]), td)
        ck("unidasm`s `db` (0x1f, genuinely undefined) is a refusal", u2 is None,
           str(u2))
    # A control: a table this backend gets right must come back mostly AGREE, or
    # the comparison is miscalibrated and every table would look broken.
    rows = run_family("C8", bytes([0xC8]), b"")
    c = Counter(r[1] for r in rows)
    ck("the r8 register table is mostly AGREE (calibration)", c["AGREE"] >= 100,
       "AGREE=%d of 256" % c["AGREE"])
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--family", default=None, help="comma-separated, e.g. B8,F1")
    ap.add_argument("--all", action="store_true", help="print every sub-opcode")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    sys.exit(run(set(x.upper() for x in a.family.split(",")) if a.family else None,
                 a.all))
