#!/usr/bin/env python3
"""twin_framed_spans.py -- which v7 `.byte` spans are ALREADY FRAMED AS CODE in
the v9/v10 twin, and does a linear decode of the v7 bytes agree with the twin's
framing instruction for instruction?

THE QUESTION THIS ANSWERS
-------------------------
`notes/DATA-CENSUS-2026-09-02.md` §8 locates 222,810 B of `embedded-in-code`
debt -- undocumented data sitting between two instruction regions -- of which
139,927 B is in v7.  The census is explicit that this is "a disassembly job,
not a data job", and equally explicit that the flag is NOT a verdict.

Converting on decodability alone is forbidden and would be wrong: the TLCS-900
opcode space is dense enough that random bytes decode cleanly ~24 % of the time
(`scripts/analysis/blind_run_decode_census.py`).  What this script supplies
instead is an argument that comes from OUTSIDE the span:

  * v7, v9 and v10 are three versions of ONE firmware.  Where a span in v7 is
    `.byte` under a label L, and the SAME label L in v9 or v10 covers a span of
    the SAME byte length whose source is written as instructions, the twin has
    already fixed both boundaries -- the start (L is a defined symbol in both)
    and the end (the next label is a defined symbol in both, at the same
    distance).  Neither boundary is taken from inside the span, which is the
    trap the lane brief warns about: a misaligned decode RESYNCHRONISES, so
    agreement downstream of a wrong start proves nothing about the start.

FIVE GATES, ALL OF WHICH MUST PASS
----------------------------------
  A  SAME LABEL, SAME LENGTH.  L and the next emitting label after it exist in
     both images' flattened streams, and (next - L) is identical.  A span whose
     length differs between versions is refused: the routine changed.
  B  THE TWIN'S SOURCE IS CODE THERE.  Built the same way as
     l1_territory_map.py -- llvm-mc -show-encoding over the twin's whole tree,
     walking the emitted byte stream, reconciled against the ROM size so a
     mis-sized directive cannot pass silently.  Requires >= 95 % of the twin
     span's bytes to be instruction bytes.
  C  THE TWIN'S LINEAR DECODE REPRODUCES THE TWIN'S SOURCE FRAMING.  Decode the
     twin's ROM bytes over the span with `llvm-mc --disassemble` and require the
     instruction START OFFSETS to equal the twin source's own.  This is the
     control: it proves linear decode is the right instrument FOR THIS BYTE
     STREAM before it is used on v7, rather than assuming it.
  D  v7's LINEAR DECODE AGREES WITH THE TWIN'S, BOUNDARY FOR BOUNDARY, AND
     ACCOUNTS FOR EVERY BYTE OF THE SPAN.  Reported as a fraction; default
     threshold 0.98.  v7 and its twin differ in the operand VALUES of calls and
     jumps (the images are laid out differently), so byte equality is NOT
     required and is reported separately as context.
  E  SAME REFUSAL PATTERN.  Bytes the decoder cannot spell must occur at the
     same relative offsets in v7 as in the twin.  A v7 span that refuses where
     its twin does not is refused: something is different there and the twin's
     framing is not evidence about it.

WHAT THIS SCRIPT DOES NOT ESTABLISH
-----------------------------------
It inherits the twin's judgement.  If v9/v10's source is wrong about a span
being code, this makes the same error in v7 -- tidily, and byte-exactly.  Gate C
limits that only to the extent that the twin's framing must be self-consistent
under an independent decode, and every emitted region's header names the twin
symbol it was framed from so the inheritance is visible rather than implied.

⚠ It also inherits the decoder's gaps.  Where `llvm-mc` refuses a byte, the
twin's own source spells it `.byte` and resumes one byte later; this script does
the same, so those bytes stay debt and are counted as such.  They are NOT
claimed as converted.

RUN
    python3 scripts/analysis/twin_framed_spans.py --selftest
    python3 scripts/analysis/twin_framed_spans.py --report --min 64
    python3 scripts/analysis/twin_framed_spans.py --emit LABEL

`make all` must have been run: the flatten walks are reconciled against the
rebuilt ROM sizes.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MC = os.environ.get("LLVM_MC") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJDUMP = os.environ.get("LLVM_OBJDUMP") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-objdump")
BASE = 0xE00000

IMAGES = {
    "v7":  dict(root="v7/maincpu/kn5000_v7_program.s",  inc="v7/maincpu",
                elf="rebuilt_ROMs/kn5000_v7_program.llvm.elf",
                rom="original_ROMs/kn5000_v7_program.rom"),
    "v9":  dict(root="v9/maincpu/kn5000_v9_program.s",  inc="v9/maincpu",
                elf="rebuilt_ROMs/kn5000_v9_program.llvm.elf",
                rom="original_ROMs/kn5000_v9_program.rom"),
    "v10": dict(root="v10/maincpu/kn5000_v10_program.s", inc="v10/maincpu",
                elf="rebuilt_ROMs/kn5000_v10_program.llvm.elf",
                rom="original_ROMs/kn5000_v10_program.rom"),
}

WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
LABEL = re.compile(r'^([A-Za-z_.$][\w.$]*):')


def ascii_len(operand):
    return sum(len(ESCAPE.sub("X", m.group(1)))
               for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand))


_FLAT = {}


def flatten(key):
    """-> (kinds, starts, labels, order, size), memoised.

    kinds   bytearray per ROM byte: 1 = instruction byte, 0 = data or padding
    starts  bytearray: 1 at each instruction's FIRST byte
    labels  {name: offset}
    order   [(offset, name)] sorted, so `the next label` is meaningful

    The walk must consume exactly the ROM's size; it raises otherwise, so a
    directive this script sizes wrongly cannot pass silently.
    """
    if key in _FLAT:
        return _FLAT[key]
    img = IMAGES[key]
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", "-I", img["inc"],
                          img["root"]], capture_output=True, text=True, cwd=ROOT)
    if out.returncode != 0:
        raise SystemExit("llvm-mc failed on %s:\n%s" % (key, out.stderr[:600]))
    size = os.path.getsize(os.path.join(ROOT, img["rom"]))
    kinds = bytearray(size)
    starts = bytearray(size)
    labels, order, pos = {}, [], 0
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            if pos < size:
                starts[pos] = 1
            for i in range(pos, min(pos + n, size)):
                kinds[i] = 1
            pos += n
            continue
        m = LABEL.match(s)
        if m:
            nm = m.group(1)
            if nm not in labels:
                labels[nm] = pos
                order.append((pos, nm))
            continue
        if s.startswith(";"):
            continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            pos += WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
        elif d in ("ascii", "asciz"):
            pos += ascii_len(rest) + (1 if d == "asciz" else 0)
        elif d in ("zero", "fill", "space"):
            parts = [p.strip() for p in rest.split(",")]
            n = int(parts[0], 0)
            if d == "fill" and len(parts) >= 2:
                n *= int(parts[1], 0)
            pos += n
        elif d == "p2align":
            pos += (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
        elif d == "org":
            t = int(rest.split(",")[0].strip(), 0)
            if t > pos:
                pos = t
    if pos != size:
        raise SystemExit("%s: flatten consumed %d bytes, ROM is %d -- refusing "
                         "to report from an unreconciled walk" % (key, pos, size))
    order.sort()
    _FLAT[key] = (kinds, starts, labels, order, size)
    return _FLAT[key]


OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$')


def decode(blob):
    """Linear disassembly of `blob`.  -> (starts, refused, text, pos).

    starts   sorted offsets at which an instruction begins
    refused  sorted offsets the decoder could not spell
    text     [(offset, nbytes, mnemonic-text)] -- mnemonic is "" for a refusal
    pos      bytes accounted for; a caller MUST require pos == len(blob)

    ⚠ THIS DELIBERATELY DOES NOT USE `llvm-mc --disassemble --show-encoding`.
    That prints a RE-ENCODING of the instruction, which is not always the byte
    span the disassembler consumed -- `notes/DEBT-INVENTORY-2026-09-02.md`
    records a 407 B figure that was retracted for exactly this reason -- and it
    reports a refused byte only on stderr, without saying how many bytes the
    decoder skipped.  Measured here on v10 0x1808E6+7134: summing its encoding
    lengths plus its stderr warnings gives 7,115 B for a 7,134 B span, and a
    greedy re-sync against the real bytes desynchronises at instruction 105.

    `llvm-objdump -d` instead prints the ADDRESS and the RAW CONSUMED BYTES of
    every instruction, and prints `<unknown>` with its raw bytes where it
    refuses.  The walk is still self-checked: the addresses must be contiguous
    from 0 and the raw bytes must equal the blob, or pos comes back -1.
    """
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        binp = os.path.join(td, "b.bin")
        open(binp, "wb").write(blob)
        srcp = os.path.join(td, "b.s")
        open(srcp, "w").write('.text\n.incbin "%s"\n' % binp)
        objp = os.path.join(td, "b.o")
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", objp, srcp],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return [], [], [], -1
        r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", objp],
                           capture_output=True, text=True)
    starts, refused, text, pos = [], [], [], 0
    for line in r.stdout.split("\n"):
        m = OBJDUMP_RE.match(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        raw = bytes(int(x, 16) for x in m.group(2).split())
        mn = m.group(3).strip()
        if addr != pos or blob[pos:pos + len(raw)] != raw:
            return [], [], [], -1
        if mn.startswith("<unknown>"):
            refused.extend(range(pos, pos + len(raw)))
            text.append((pos, len(raw), ""))
        else:
            starts.append(pos)
            text.append((pos, len(raw), mn))
        pos += len(raw)
    if pos != len(blob):
        return [], [], [], -1
    return starts, sorted(refused), text, pos


def label_spans(order, size):
    out = []
    for i, (off, nm) in enumerate(order):
        end = order[i + 1][0] if i + 1 < len(order) else size
        if end > off:
            out.append((nm, off, end - off))
    return out


def adjudicate(nm, off, n, twin_keys, thresh):
    """-> dict verdict for one v7 span."""
    k7, s7, l7, o7, sz7 = flatten("v7")
    rom7 = ROMS["v7"]
    chosen, why = None, "no twin symbol"
    for tk in twin_keys:
        kt, st, lt, ot, szt = flatten(tk)
        if nm not in lt:
            continue
        idx = [i for i, (o, x) in enumerate(ot) if x == nm]
        if not idx:
            continue
        i = idx[0]
        toff = ot[i][0]
        tend = ot[i + 1][0] if i + 1 < len(ot) else szt
        if tend - toff != n:
            why = "twin %s span is %d B, v7's is %d" % (tk, tend - toff, n)
            continue
        frac = sum(kt[toff:toff + n]) / float(n)
        if frac < 0.95:
            why = "twin %s is only %.0f%% instruction bytes" % (tk, 100 * frac)
            continue
        chosen = (tk, toff)
        break
    if chosen is None:
        return dict(name=nm, off=off, n=n, verdict="REFUSED", why=why)
    tk, toff = chosen
    kt, st, lt, ot, szt = flatten(tk)
    tstarts_src = set(i - toff for i in range(toff, toff + n) if st[i])
    tblob = ROMS[tk][toff:toff + n]
    tdec, tref, ttext, tpos = decode(tblob)
    if tpos != n:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate C: twin %s decode accounts for %d of %d B" % (tk, tpos, n))
    agreeC = len(tstarts_src & set(tdec)) / float(max(len(tstarts_src), 1))
    if agreeC < thresh:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate C: twin %s decode vs its own source framing %.3f"
                        % (tk, agreeC))
    blob = rom7[off:off + n]
    dec, ref, text, pos = decode(blob)
    if pos != n:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate D: v7 decode accounts for %d of %d B" % (pos, n))
    agreeD = len(set(dec) & set(tdec)) / float(max(len(tdec), 1))
    if agreeD < thresh:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate D: v7 decode vs twin %s framing %.3f" % (tk, agreeD))
    if set(ref) != set(tref):
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate E: v7 refuses %d bytes, twin %s refuses %d, at "
                        "different offsets" % (len(ref), tk, len(tref)))
    same = sum(1 for a, b in zip(blob, tblob) if a == b)
    return dict(name=nm, off=off, n=n, verdict="PASS", twin=tk, toff=toff,
                agreeC=agreeC, agreeD=agreeD, refusals=len(ref),
                byte_same=same, ninstr=len(text), text=text, refset=ref)


ROMS = {}


def load_roms():
    for k in IMAGES:
        ROMS[k] = open(os.path.join(ROOT, IMAGES[k]["rom"]), "rb").read()


def analyse(min_size, twin_keys=("v10", "v9"), thresh=0.98):
    load_roms()
    for k in ("v7",) + tuple(twin_keys):
        sys.stderr.write("flattening %s ...\n" % k)
        flatten(k)
    k7, s7, l7, o7, sz7 = flatten("v7")
    res, stats = [], dict(total=0, bytes_total=0, pass_=0, bytes_pass=0)
    for nm, off, n in label_spans(o7, sz7):
        if n < min_size:
            continue
        if sum(k7[off:off + n]) > 0.02 * n:
            continue                    # already code in v7
        stats["total"] += 1
        stats["bytes_total"] += n
        r = adjudicate(nm, off, n, twin_keys, thresh)
        if r["verdict"] == "PASS":
            stats["pass_"] += 1
            stats["bytes_pass"] += n
        res.append(r)
    return res, stats


def toolchain():
    return subprocess.run(["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
                           "log", "-1", "--format=%h (%H)"],
                          capture_output=True, text=True).stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--emit", default="")
    ap.add_argument("--min", type=int, default=64)
    ap.add_argument("--thresh", type=float, default=0.98)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if a.emit:
        load_roms()
        flatten("v7")
        k7, s7, l7, o7, sz7 = flatten("v7")
        hit = [(nm, o, n) for nm, o, n in label_spans(o7, sz7) if nm == a.emit]
        if not hit:
            sys.exit("no v7 label span named %s" % a.emit)
        nm, off, n = hit[0]
        r = adjudicate(nm, off, n, ("v10", "v9"), a.thresh)
        if r["verdict"] != "PASS":
            sys.exit("%s: %s" % (nm, r["why"]))
        for o, ln, mn in r["text"]:
            print("\t%s" % mn)
        return 0
    print("toolchain: %s" % toolchain())
    res, st = analyse(a.min, thresh=a.thresh)
    ps = sorted([r for r in res if r["verdict"] == "PASS"], key=lambda r: -r["n"])
    import collections
    rc = collections.Counter()
    for r in res:
        if r["verdict"] == "REFUSED":
            rc[r["why"].split(":")[0].split(",")[0]] += 1
    print("\nv7 DATA label-spans >= %d B considered: %d (%d B)"
          % (a.min, st["total"], st["bytes_total"]))
    print("  PASS all five gates ......... %4d spans, %7d B"
          % (st["pass_"], st["bytes_pass"]))
    for k, v in rc.most_common():
        print("  refused: %-32s %4d" % (k[:32], v))
    print("\n  %-46s %7s %5s %6s %6s %6s %6s" %
          ("label", "bytes", "twin", "gateC", "gateD", "refus", "same%"))
    for r in ps:
        print("  %-46s %7d %5s %6.3f %6.3f %6d %5.1f%%"
              % (r["name"], r["n"], r["twin"], r["agreeC"], r["agreeD"],
                 r["refusals"], 100.0 * r["byte_same"] / r["n"]))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("llvm-mc exists", os.path.exists(MC), MC)
    load_roms()
    for k in IMAGES:
        ck("%s ROM loaded" % k, len(ROMS[k]) == 2097152)
    kinds, starts, labels, order, size = flatten("v10")
    ck("v10 flatten reconciles to the ROM size", True, "%d B" % size)
    ck("v10 flatten found labels", len(labels) > 1000, str(len(labels)))
    s, r, t, p = decode(bytes([0x11, 0x11, 0x11]))
    ck("three scf bytes decode as three instructions", len(t) == 3 and p == 3)
    # a byte the decoder cannot spell must be REPORTED, not silently absorbed
    s, r, t, p = decode(bytes([0x11, 0x95, 0x11]))
    ck("an unspellable byte is reported as a refusal at its own offset",
       r == [1] and p == 3 and s == [0, 2], "refused=%s pos=%d starts=%s" % (r, p, s))
    # the null the lane brief demands: random bytes must not sail through
    import random
    rnd = random.Random(4242)
    blob = bytes(rnd.randrange(256) for _ in range(2048))
    s2, r2, t2, p2 = decode(blob)
    ck("random 2 KiB is not fully accounted for", len(r2) > 0,
       "refusals %d" % len(r2))
    # AudioCtrl_DataBlock: the worked example the lane report cites
    k7, s7, l7, o7, sz7 = flatten("v7")
    hit = [(nm, o, n) for nm, o, n in label_spans(o7, sz7)
           if nm == "AudioCtrl_DataBlock"]
    ck("v7 AudioCtrl_DataBlock is a 7134 B span", hit and hit[0][2] == 7134,
       str(hit))
    if hit:
        r = adjudicate(*hit[0], twin_keys=("v10", "v9"), thresh=0.98)
        ck("AudioCtrl_DataBlock passes all five gates",
           r["verdict"] == "PASS", r.get("why", ""))
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    sys.exit(main())
