#!/usr/bin/env python3
r"""port_extension_data_from_v10.py -- carry v10's TYPED extensions/extension_data.s to v9 / v7.

QUESTION ANSWERED
-----------------
"v10's `extensions/extension_data.s` (0xED0008-0xEE0010) is typed data; v9's and
v7's copies of the same file are the same bytes decoded as instructions (8,244
and 8,066 absurd data-as-code markers).  What is the v9 / v7 file when it is
written the way v10's is?"

WHY THIS IS SOUND
-----------------
The file is included at the same point in all three trees (end of
`ui_widgets/style_bitmaps.s`) and spans the same 0xED0008-0xEE0010 in all three
dumps.  Measured with this script's `--compare`:

  * v9 vs v10: 0 differing bytes in the whole range -- the v9 file is v10's file;
  * v7 vs v10: every difference is a VALUE inside a line of the same size (code
    pointers into the 0xFB/0xFC code that moved between versions, and a few
    table values), never a change of layout.

So each v10 source line is carried over unchanged when its bytes are the same
in the target dump, and REWRITTEN from the target dump when they are not:
`.byte` rows and all-hex `.short` rows get the target's values; `.long SYMBOL` gets the target symbol
that sits at the target's pointer value (looked up in the target's linked ELF,
so it must be built first); a line of any other kind that differs is a hard
failure, reported with its address, rather than guessed at.

The eight `.incbin "includes/generated/sndparam_run_*.bin"` blocks are v10-only
(the Makefile compiles `v10/maincpu/audio/sndparam_records/*.c` for v10 alone),
so in the target the `.incbin` becomes one `sndparam_descriptor` macro line
per 18-byte record, decoded from the TARGET dump; the run label and v10's
`.set <record>, <run> + <offset>` lines are kept as they are.

The byte gate (`make gate`) is the certification; this script is how the text
was produced.

RUN
    make gate                                   # target ELFs + generated bins
    python3 scripts/analysis/lane_line_map.py --ver v10 \
        --files extensions/extension_data.s --json /tmp/claude-1000/lane-ext/v10map.json
    python3 scripts/tools/port_extension_data_from_v10.py --target v9 \
        --v10map /tmp/claude-1000/lane-ext/v10map.json --compare
    python3 scripts/tools/port_extension_data_from_v10.py --target v9 \
        --v10map /tmp/claude-1000/lane-ext/v10map.json --write
"""
import argparse
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
REL = "extensions/extension_data.s"
BASE = 0xE00000
LO, HI = 0xED0008, 0xEE0010

RUN_COMMENT_RE = re.compile(r'^;  (\d+) x 18-byte sound-parameter descriptors, (0x[0-9A-F]+)-(0x[0-9A-F]+)\.')
RUN_LABEL_RE = re.compile(r'^(SndParamRun_[0-9A-F]+):\s*$')
INCBIN_RE = re.compile(r'^\s*\.incbin\s+"includes/generated/sndparam_(run_[0-9a-f]+)\.bin"\s*$')
EQU_RE = re.compile(r'^\.set ([A-Za-z_]\w*), (SndParamRun_[0-9A-F]+) \+ (\d+)\s*$')

MACRO_DEF = r"""; ---------------------------------------------------------------------------
; sndparam_descriptor -- ONE 18-byte sound-parameter descriptor
; ---------------------------------------------------------------------------
; v10 compiles these records from C (v10/maincpu/audio/sndparam_records/
; run_*.c, struct sndparam_descriptor_t in sndparam_types.h); the Makefile does
; that for v10 only, so this copy writes each record as one macro line with
; the SAME fields in the SAME order.  sndparam_types.h cites, per field, the
; SndParam_* accessor instruction that reads it -- in v10's
; audio/sndparam_routines.s; the record layout is the same in this version
; because the records are byte-for-byte the v10 ones (see the file header).
;
;   +0x00 key (u32, byte +3 always 0)   +0x04 bank_index   +0x05 bank_offset
;   +0x06 mask   +0x07 clamp_min   +0x08 clamp_max   +0x09 shift (low nibble)
;   +0x0A xor_value   +0x0B aux_index (0xff = none)   +0x0C read_accessor
;   +0x0D register_accessor   +0x0E lookup2_accessor   +0x0F codec
;   +0x10 write_accessor   +0x11 unknown_0x11 (no reader found in v10)
.macro sndparam_descriptor key, bank_index, bank_offset, mask, clamp_min, clamp_max, shift, xor_value, aux_index, read_acc, register_acc, lookup2_acc, codec, write_acc, unknown_0x11
	.long \key
	.byte \bank_index, \bank_offset, \mask, \clamp_min, \clamp_max, \shift, \xor_value, \aux_index
	.byte \read_acc, \register_acc, \lookup2_acc, \codec, \write_acc, \unknown_0x11
.endm
"""


VERSION_NOTE = {
    "v9": """;
; !! THIS IS THE v9 COPY.  The ROM bytes of this file's whole range,
; 0xED0008-0xEE0010, are IDENTICAL in the v9 and v10 dumps (0 differing bytes),
; and so is this text, except that the Makefile compiles the C structs above
; for v10 only: here each of those 951 records is one `sndparam_descriptor`
; macro line (defined above the first run below) with the same fields in the
; same order.  Produced by scripts/tools/port_extension_data_from_v10.py.
""",
    "v7": """;
; !! THIS IS THE v7 COPY.  This file spans 0xED0008-0xEE0010 in the v7 dump too,
; with the same layout as v10: every v7/v10 difference in the range is a VALUE
; inside a line of the same size -- code pointers into the 0xFA-0xFC code that
; moved between versions, plus a few table values.  The text is v10's with
; those lines rewritten from the v7 dump (pointers resolved to the v7 symbol at
; the v7 address), and with each C-compiled record written as one
; `sndparam_descriptor` macro line (defined above the first run below), because
; the Makefile compiles the C for v10 only.  The records' field values were
; decoded from the v7 dump.  Produced by
; scripts/tools/port_extension_data_from_v10.py.
""",
}


def load_syms(ver):
    elf = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % ver)
    if not os.path.exists(elf):
        raise SystemExit("build first: %s missing (make gate)" % elf)
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout
    by_addr, by_name = {}, {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) != 3:
            continue
        a = int(p[0], 16)
        by_addr.setdefault(a, []).append(p[2])
        by_name[p[2]] = a
    return by_addr, by_name


def record_line(label, b):
    key = int.from_bytes(b[0:4], "little")
    k = ("0x%06x" % key) if key < 0x1000000 else ("0x%08x" % key)
    f = [k, "%d" % b[4], "%d" % b[5], "0x%02x" % b[6], "%d" % b[7], "%d" % b[8],
         "%d" % b[9], "0x%02x" % b[10], "0x%02x" % b[11], "%d" % b[12], "%d" % b[13],
         "%d" % b[14], "%d" % b[15], "%d" % b[16], "0x%02x" % b[17]]
    return label, "sndparam_descriptor " + ", ".join(f)


def aligned(rows):
    """rows: [(label, body)] -> tab-aligned lines (tab stop 8)."""
    w = max(len(l) + 1 for l, _ in rows)
    col = (w // 8 + 1) * 8
    out = []
    for l, body in rows:
        lab = l + ":"
        ntabs = max(1, (col - len(lab) + 7) // 8)
        out.append(lab + "\t" * ntabs + body)
    return out


def split_comment(line):
    q = None
    for i, ch in enumerate(line):
        if q:
            if ch == q:
                q = None
            continue
        if ch in "\"'":
            q = ch
        elif ch == ";":
            return line[:i], line[i:]
    return line, ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", required=True, choices=["v9", "v7"])
    ap.add_argument("--v10map", required=True)
    ap.add_argument("--compare", action="store_true", help="only report differing lines")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--out")
    a = ap.parse_args()

    src = open(os.path.join(ROOT, "v10/maincpu", REL), encoding="latin-1").read().split("\n")
    m = json.load(open(a.v10map))[REL]
    at = {lno: (addr, size) for lno, addr, size, _ in m}
    r10 = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    rt = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % a.target), "rb").read()
    ndiff = sum(1 for x in range(LO, HI) if r10[x - BASE] != rt[x - BASE])
    print("%s vs v10: %d differing bytes in 0x%06X-0x%06X" % (a.target, ndiff, LO, HI))

    syms_t = None
    out = []
    problems = []
    rewritten = []
    i = 0
    macro_emitted = False
    n = len(src)
    while i < n:
        ln = src[i]
        lno = i + 1
        if ln.startswith("; generator refuses those rather than guessing where to cut."):
            out.append(ln)
            out.extend(VERSION_NOTE[a.target].rstrip("\n").split("\n"))
            i += 1
            continue
        mc = RUN_COMMENT_RE.match(ln)
        if mc:
            # the 6-line v10 comment block that introduces one C run
            cnt, lo_s, hi_s = mc.groups()
            j = i
            while j < n and src[j].startswith(";"):
                j += 1
            # (the sndparam_descriptor macro is defined in the v10 text itself
            # since 2026-09-25, so it is carried over like any other line)
            out.append(";  %s x 18-byte sound-parameter descriptors, %s-%s, one" % (cnt, lo_s, hi_s))
            out.append(";  `sndparam_descriptor` per record (fields: the macro above).  v10")
            out.append(";  compiles the same records from audio/sndparam_records/%s.c;" %
                       src[j + 1].split("sndparam_")[-1].split(".bin")[0])
            out.append(";  the record labels follow the run as `.set` equates, as in v10.")
            i = j
            continue
        ml = RUN_LABEL_RE.match(ln)
        if ml and i + 1 < n and INCBIN_RE.match(src[i + 1]):
            # keep v10's shape: the run label, one macro line per record where
            # v10 has the .incbin, then v10's own `.set Name, Run + off` lines
            runlab = ml.group(1)
            base, size = at[lno + 1]
            names = {}
            j = i + 2
            while j < n and EQU_RE.match(src[j]):
                nm, rl, off = EQU_RE.match(src[j]).groups()
                assert rl == runlab
                names[int(off)] = nm
                j += 1
            if size < 0:
                # the file's last byte-emitting line: the map cannot size it,
                # so size it by its record labels and require it to end the file
                size = 18 * len(names)
                assert base + size == HI, (runlab, hex(base + size))
            assert size % 18 == 0 and len(names) == size // 18, (runlab, size, len(names))
            out.append(ln)
            for k in range(size // 18):
                ad = base + 18 * k
                out.append("\t" + record_line(names[18 * k], rt[ad - BASE:ad - BASE + 18])[1])
            out.extend(src[i + 2:j])
            i = j
            continue
        if lno in at:
            addr, size = at[lno]
            code, cmt = split_comment(ln)
            if size > 0 and not code.lstrip().startswith(".include") and \
                    r10[addr - BASE:addr - BASE + size] != rt[addr - BASE:addr - BASE + size]:
                T = rt[addr - BASE:addr - BASE + size]
                mb = re.match(r'^(\s*(?:[A-Za-z_]\w*:\s*)?)\.byte\s', code)
                ml4 = re.match(r'^(\s*(?:[A-Za-z_]\w*:\s*)?)\.long\s+([A-Za-z_]\w*)\s*$', code)
                msh = re.match(r'^(\s*(?:[A-Za-z_]\w*:\s*)?)\.short\s+0x[0-9a-f]{4}(\s*,\s*0x[0-9a-f]{4})*\s*$', code)
                if mb:
                    new = mb.group(1) + ".byte " + ", ".join("0x%02x" % x for x in T)
                elif msh and size % 2 == 0:
                    new = msh.group(1) + ".short " + ", ".join(
                        "0x%04x" % int.from_bytes(T[k:k + 2], "little") for k in range(0, size, 2))
                elif ml4 and size == 4:
                    if syms_t is None:
                        syms_t = load_syms(a.target)
                    v = int.from_bytes(T, "little")
                    old = ml4.group(2)
                    cands = syms_t[0].get(v, [])
                    good = [c for c in cands if not c.startswith(("__", ".L"))]
                    if old in good:
                        pick = old
                    elif good:
                        pick = sorted(good, key=lambda s: (s.startswith("sub_"), s))[0]
                    else:
                        pick = None
                        problems.append("%d 0x%06X no %s symbol at 0x%06X (v10: %s)" % (lno, addr, a.target, v, old))
                    new = ml4.group(1) + ".long " + (pick or ("0x%08x" % v))
                else:
                    problems.append("%d 0x%06X %d B differs and is not .byte/.long: %s" % (lno, addr, size, ln.strip()[:80]))
                    new = code
                ln2 = new + ((" " + cmt) if cmt and not new.endswith(" ") else cmt)
                rewritten.append("%d 0x%06X: %s  ->  %s" % (lno, addr, ln.strip()[:70], ln2.strip()[:70]))
                ln = ln2
        out.append(ln)
        i += 1

    print("rewritten lines: %d" % len(rewritten))
    for r in rewritten[:400]:
        print("  " + r)
    if problems:
        print("PROBLEMS: %d" % len(problems))
        for p in problems:
            print("  " + p)
    if a.compare:
        return
    text = "\n".join(out)
    dest = a.out or os.path.join(ROOT, a.target, "maincpu", REL)
    if a.write or a.out:
        open(dest, "w", encoding="latin-1").write(text)
        print("wrote %s (%d lines)" % (dest, len(out)))
    if problems:
        sys.exit(2)


if __name__ == "__main__":
    main()
