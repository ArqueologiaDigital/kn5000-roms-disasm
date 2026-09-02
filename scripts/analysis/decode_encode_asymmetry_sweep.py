#!/usr/bin/env python3
"""decode_encode_asymmetry_sweep.py -- how many REAL instructions in this tree
does llvm-objdump print as a DIFFERENT instruction than the one in the ROM?

QUESTION IT ANSWERS
    `decode_encode_asymmetry.py` reports five hand-sampled byte sequences, four
    of which do not round-trip.  It cannot say whether four is the whole
    problem or the tip of it.  This script answers that: it takes EVERY
    instruction in every committed image source -- the ones the byte gate
    certifies reproduce the dumps exactly -- decodes its bytes with
    llvm-objdump and re-encodes the printed text with llvm-mc, and counts the
    ones that come back different.

WHY THIS IS THE RIGHT POPULATION
    An arbitrary offset into a ROM is usually data, so a linear sweep over raw
    dump bytes measures mostly noise.  The tree's own sources give REAL
    instruction boundaries with no framing guesswork: `llvm-mc --show-encoding`
    reports, per source line, the exact bytes the assembler emits, and those
    bytes are the ROM's (that is what `make gate-all` certifies).  So every
    probe here is a genuine instruction at a genuine boundary.

THREE OUTCOME CLASSES, and they are not equally bad
    OK        re-encoding the printed text reproduces the instruction's bytes.
    ASYM      the decoder consumed the right number of bytes but printed a text
              that encodes to DIFFERENT bytes.  Silent: a reader believes a
              wrong instruction, and the byte gate has no opinion because the
              text never enters the tree.
    LENGTH    the decoder consumed a different number of bytes than the
              instruction really has.  Worse: a linear sweep past one of these
              desynchronises and everything after it is garbage.
    NODECODE  the decoder refused the bytes outright (`<unknown>`).  Loud, and
              counted by the decoder-gap probes; reported separately here so it
              cannot be confused with an asymmetry.

    ⚠ LENGTH is judged against the assembler's own byte count for that source
    line, which is ground truth.  A decode that runs PAST the instruction sees
    real following bytes, because each probe carries the next CONTEXT_BYTES
    bytes of the true stream where the stream is contiguous.

RUN
    python3 scripts/analysis/decode_encode_asymmetry_sweep.py
    python3 scripts/analysis/decode_encode_asymmetry_sweep.py --images v7
    python3 scripts/analysis/decode_encode_asymmetry_sweep.py --selftest

⚠ The number this prints is a property of the DECODER as much as of the bytes.
It prints the toolchain commit; quote that beside any figure taken from it.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROJECTS = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM = os.path.join(PROJECTS, "llvm-project", "build", "bin")
MC = os.path.join(LLVM, "llvm-mc")
OBJDUMP = os.path.join(LLVM, "llvm-objdump")

CONTEXT_BYTES = 8       # trailing real bytes handed to the decoder with each probe
CHUNK = 4000            # probes per llvm-mc/llvm-objdump invocation

# (name, include dir(s), root source) -- the eight KN5000 images, exactly the
# `llvm-mc -filetype=obj` invocations in the Makefile (see
# assert_images_assemble.py, which keeps the same list), plus the four SX-WSA1R
# images from wsa1/Makefile.
IMAGES = [
    ("v10",       "v10/maincpu",  "v10/maincpu/kn5000_v10_program.s"),
    ("v9",        "v9/maincpu",   "v9/maincpu/kn5000_v9_program.s"),
    ("v7",        "v7/maincpu",   "v7/maincpu/kn5000_v7_program.s"),
    ("v142",      "v142/subcpu",  "v142/subcpu/kn5000_subprogram_v142.s"),
    ("subboot",   "subcpu/boot",  "subcpu/boot/kn5000_subcpu_boot.s"),
    ("hdae5000",  "hdae5000",     "hdae5000/hd-ae5000_v2_06i.s"),
    ("table",     "table_data",   "table_data/kn5000_table_data.s"),
    ("custom",    "custom_data",  "custom_data/kn5000_custom_data.s"),
    # ⚠ The wsa1 images take TWO include dirs, exactly as wsa1/Makefile passes
    # them (`-I . -I prom_X` from inside wsa1/).  Giving prom_d only `wsa1`
    # left three `.include`s unresolved and the image reported ZERO
    # instructions -- a silent hole in the census that looked like a clean row.
    ("prom_a",    "wsa1:wsa1/prom_a", "wsa1/prom_a/wsa1_prom_a.s"),
    ("prom_b",    "wsa1:wsa1/prom_b", "wsa1/prom_b/wsa1_prom_b.s"),
    ("prom_c",    "wsa1:wsa1/prom_c", "wsa1/prom_c/wsa1_prom_c.s"),
    ("prom_d",    "wsa1:wsa1/prom_d", "wsa1/prom_d/wsa1_prom_d.s"),
]

ENC_RE = re.compile(r'^\s*(.*?)\s*;\s*encoding:\s*\[([^\]]*)\]\s*$')
BYTE_RE = re.compile(r'^\s*\.byte\s+(.+)$')
OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$')


def toolchain():
    return subprocess.run(["git", "-C", os.path.join(PROJECTS, "llvm-project"),
                           "log", "-1", "--format=%h"],
                          capture_output=True, text=True).stdout.strip()


def show_encoding(incdir, root):
    """Assemble one image with --show-encoding and return the echoed stream as a
    list of (kind, text, bytes).  kind is 'i' for an instruction, 'd' for data
    whose bytes are recoverable, 'x' for anything opaque (a discontinuity)."""
    inc = []
    for d in incdir.split(":"):
        inc += ["-I", os.path.join(ROOT, d)]
    r = subprocess.run([MC, "-triple=tlcs900", "--show-encoding"] + inc +
                       [os.path.join(ROOT, root)],
                       capture_output=True, text=True)
    errs = [l for l in (r.stdout + r.stderr).splitlines() if ": error:" in l]
    out = []
    for line in r.stdout.splitlines():
        m = ENC_RE.match(line)
        if m:
            txt = m.group(1).strip()
            raw = [x.strip() for x in m.group(2).split(",") if x.strip()]
            try:
                b = bytes(int(x, 16) for x in raw)
            except ValueError:
                out.append(("x", line.strip(), b""))   # fixup/relocation encoding
                continue
            out.append(("i", txt, b))
            continue
        s = line.strip()
        if not s or s.startswith("."):
            m = BYTE_RE.match(s)
            if m:
                try:
                    vals = [int(v.strip(), 0) & 0xFF for v in m.group(1).split(",")]
                    out.append(("d", s, bytes(vals)))
                    continue
                except ValueError:
                    pass
            if s.startswith(".text") or s.startswith(".section") or not s:
                continue
            out.append(("x", s, b""))      # opaque: breaks stream contiguity
    return out, errs


def probes_from_stream(stream):
    """-> list of (instr_bytes, context_bytes, printed_source_text).

    Context is drawn from the bytes that really follow in the image, and stops
    at the first opaque element -- never invented."""
    probes = []
    n = len(stream)
    for idx in range(n):
        kind, txt, b = stream[idx]
        if kind != "i" or not b:
            continue
        ctx = b""
        j = idx + 1
        while j < n and len(ctx) < CONTEXT_BYTES:
            k2, _, b2 = stream[j]
            if k2 == "x":
                break
            ctx += b2
            j += 1
        probes.append((b, ctx[:CONTEXT_BYTES], txt))
    return probes


def batch_decode(blobs):
    """Decode many independent blobs in one llvm-objdump run.  Each blob gets
    its own SECTION so the linear sweep restarts at its first byte and cannot
    run in from the previous blob."""
    res = [None] * len(blobs)
    for start in range(0, len(blobs), CHUNK):
        part = blobs[start:start + CHUNK]
        src = []
        for i, b in enumerate(part):
            src.append('.section .p%d,"ax"' % i)
            src.append(".byte " + ",".join(str(x) for x in b))
        with tempfile.TemporaryDirectory() as td:
            s = os.path.join(td, "b.s")
            o = os.path.join(td, "b.o")
            open(s, "w").write("\n".join(src) + "\n")
            subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                           check=True, capture_output=True)
            r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", o],
                               capture_output=True, text=True)
        cur = None
        for line in r.stdout.splitlines():
            if line.startswith("Disassembly of section .p"):
                cur = int(line[len("Disassembly of section .p"):].rstrip(":"))
                continue
            if cur is None:
                continue
            m = OBJDUMP_RE.match(line)
            if m and int(m.group(1), 16) == 0 and res[start + cur] is None:
                nb = bytes(int(x, 16) for x in m.group(2).split())
                res[start + cur] = (nb, m.group(3).strip())
    return res


def batch_encode(texts):
    """Assemble many one-line texts in one llvm-mc run, attributing each result
    to its input via a per-line section marker.  A line that does not assemble
    comes back as None."""
    res = [None] * len(texts)
    for start in range(0, len(texts), CHUNK):
        part = texts[start:start + CHUNK]
        src = []
        for i, t in enumerate(part):
            src.append('.section .q%d,"ax"' % i)
            src.append("\t" + t)
        with tempfile.TemporaryDirectory() as td:
            s = os.path.join(td, "a.s")
            open(s, "w").write("\n".join(src) + "\n")
            r = subprocess.run([MC, "-triple=tlcs900", "--show-encoding", s],
                               capture_output=True, text=True)
        cur = None
        for line in r.stdout.splitlines():
            st = line.strip()
            if st.startswith(".section\t.q") or st.startswith(".section .q"):
                cur = int(st.split(".q")[1].split(",")[0])
                continue
            m = ENC_RE.match(line)
            if m and cur is not None and res[start + cur] is None:
                raw = [x.strip() for x in m.group(2).split(",") if x.strip()]
                try:
                    res[start + cur] = bytes(int(x, 16) for x in raw)
                except ValueError:
                    res[start + cur] = None
    return res


def verdict_of(orig, decoded, text, reenc):
    """The whole classification rule, as a pure function of the four facts, so
    that the selftest can exercise every branch on synthetic input.

    ⚠ It must be testable WITHOUT the decoder: an earlier version of this file
    used the real `85 11` as its negative control, and when another lane fixed
    that form the selftest went red on a script that was working perfectly.  A
    control that dies when the bug it names is fixed is not a control."""
    if decoded is None or text.startswith("<unknown>"):
        # The decoder refused these bytes; llvm-objdump prints `<unknown>` and
        # steps ONE byte.  That is a refusal, not a length error, and conflating
        # the two would inflate the desynchronisation count with cases that are
        # loud rather than silent.
        return "NODECODE"
    if len(decoded) != len(orig):
        return "LENGTH"
    if reenc is not None and reenc == orig:
        return "OK"
    return "ASYM"


def classify(unique):
    """unique: list of (instr_bytes, ctx).  -> dict key -> (verdict, printed, reenc)"""
    blobs = [b + c for b, c in unique]
    dec = batch_decode(blobs)
    texts, need = [], []
    for i, d in enumerate(dec):
        if d is not None:
            need.append(i)
            texts.append(d[1])
    enc = batch_encode(texts)
    # index -> re-encoding.  ⚠ A list `.index()` here is O(n) inside an O(n)
    # loop; with 238,587 unique probes in v10 alone that turned a 15-second
    # sweep into one that had not finished in ten minutes.
    encof = {j: enc[k] for k, j in enumerate(need)}
    out = {}
    for i, (b, c) in enumerate(unique):
        d = dec[i]
        nb, txt = d if d is not None else (None, "")
        e = encof.get(i)
        out[(b, c)] = (verdict_of(b, nb, txt, e), txt, e)
    return out


def run(only=None, verbose=False):
    print("toolchain: tlcs900_backend@%s" % toolchain())
    grand = Counter()
    per_form = Counter()
    form_example = {}
    per_image = {}
    for name, incdir, root in IMAGES:
        if only and name not in only:
            continue
        if not os.path.exists(os.path.join(ROOT, root)):
            print("  %-9s SOURCE MISSING -- skipped" % name)
            continue
        stream, errs = show_encoding(incdir, root)
        if errs:
            print("  %-9s %d ASSEMBLER ERROR(S) -- results unreliable: %s"
                  % (name, len(errs), errs[0].strip()[:70]))
        probes = probes_from_stream(stream)
        keys = sorted({(b, c) for b, c, _ in probes})
        if os.environ.get("SWEEP_PROGRESS"):
            print("  %-9s %d instructions, %d unique probes ..."
                  % (name, len(probes), len(keys)), flush=True)
        verdicts = classify(keys)
        cnt = Counter()
        for b, c, srctxt in probes:
            v, txt, e = verdicts[(b, c)]
            cnt[v] += 1
            if v in ("ASYM", "LENGTH"):
                per_form[(v, b, txt)] += 1
                form_example.setdefault((v, b, txt), (name, srctxt, e))
        per_image[name] = (len(probes), cnt)
        grand.update(cnt)
        print("  %-9s %8d instructions   OK %8d   ASYM %5d   LENGTH %5d   NODECODE %5d"
              % (name, len(probes), cnt["OK"], cnt["ASYM"], cnt["LENGTH"], cnt["NODECODE"]))

    total = sum(grand.values())
    print("\nTOTAL %d real instructions swept" % total)
    print("  OK        %8d  (%.4f%%)" % (grand["OK"], 100.0 * grand["OK"] / max(total, 1)))
    print("  ASYM      %8d  (%.4f%%)  wrong text, right length -- SILENT" % (
        grand["ASYM"], 100.0 * grand["ASYM"] / max(total, 1)))
    print("  LENGTH    %8d  (%.4f%%)  wrong length -- DESYNCHRONISES a sweep" % (
        grand["LENGTH"], 100.0 * grand["LENGTH"] / max(total, 1)))
    print("  NODECODE  %8d  (%.4f%%)  refused outright -- loud" % (
        grand["NODECODE"], 100.0 * grand["NODECODE"] / max(total, 1)))

    if per_form:
        print("\nDISTINCT BROKEN FORMS: %d  (by site count)" % len(per_form))
        print("%-8s %-22s %-34s %-16s %s" % ("class", "rom bytes", "objdump prints",
                                             "re-encodes to", "sites"))
        for (v, b, txt), n in per_form.most_common(60 if not verbose else 10 ** 9):
            name, srctxt, e = form_example[(v, b, txt)]
            es = e.hex(" ") if e else "REJECTED"
            print("%-8s %-22s %-34s %-16s %6d   (%s: %s)" % (
                v, b.hex(" "), txt.replace("\t", " ")[:34], es[:16], n, name, srctxt[:40]))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("llvm-mc exists", os.path.exists(MC))
    ck("llvm-objdump exists", os.path.exists(OBJDUMP))

    # 1. The batched decoder must reproduce what a standalone decode says, or
    #    the section trick is silently changing the answer.
    blobs = [bytes([0x85, 0x11, 0xec, 0x61, 0xc9]),
             bytes([0x11, 0x11, 0x11]),
             bytes([0x9e, 0x04, 0x04, 0x0b, 0xe7, 0x00])]
    d = batch_decode(blobs)
    ck("batched decode returns one result per blob", all(x is not None for x in d))
    ck("a section boundary does not leak context",
       d[1][0] == bytes([0x11]), "0x11 -> %s" % (d[1][1] if d[1] else "?"))

    # 2. Every branch of the rule, on synthetic input, so the control cannot be
    #    invalidated by a backend fix.
    ck("verdict OK: re-encoding reproduces the bytes",
       verdict_of(b"\x85\x11", b"\x85\x11", "ldir85", b"\x85\x11") == "OK")
    ck("verdict ASYM: same length, different bytes",
       verdict_of(b"\x85\x11", b"\x85\x11", "ldir", b"\x80\x11") == "ASYM")
    ck("verdict ASYM: a text that will not assemble is not OK",
       verdict_of(b"\x85\x11", b"\x85\x11", "ldir", None) == "ASYM")
    ck("verdict LENGTH: decoder consumed a different count",
       verdict_of(b"\x9e\x04\x04", b"\x9e\x04", "x", b"\x9e\x04") == "LENGTH")
    ck("verdict NODECODE: the decoder refused",
       verdict_of(b"\x1f", b"\x1f", "<unknown>", None) == "NODECODE")

    # 3. And the rule must still be wired to the real tools: a form the
    #    assembler and disassembler agree on has to come back OK end to end.
    v = classify([(bytes([0x11]), b"\x11\x11")])
    ck("a symmetric form classifies OK end-to-end (0x11 scf)",
       v[(bytes([0x11]), b"\x11\x11")][0] == "OK",
       str(v[(bytes([0x11]), b"\x11\x11")]))

    # 4. The encoder batcher must attribute results to the right input line.
    e = batch_encode(["scf", "ldir85", "this is not an instruction", "pushw (xiz+4)"])
    ck("batched encode attributes by line", e[0] == b"\x11" and e[1] == b"\x85\x11"
       and e[3] == b"\x9e\x04\x04", str([x.hex() if x else None for x in e]))
    ck("a line that does not assemble comes back None", e[2] is None)

    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--images", default=None,
                    help="comma-separated subset, e.g. v7,prom_a")
    ap.add_argument("--verbose", action="store_true", help="list every broken form")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    sys.exit(run(set(a.images.split(",")) if a.images else None, a.verbose))
