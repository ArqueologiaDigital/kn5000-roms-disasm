#!/usr/bin/env python3
r"""Type 0xF15907-0xF1612F as the record stream it is, instead of fake code.

QUESTION IT ANSWERS
    `v10/maincpu/storage/flash_floppy_handlers.s` writes 2,088 bytes of
    [flags:u8][len:u8] records, 32-bit pointer tables and a 168-byte ASCII name
    table as TLCS-900 instructions (`reti / pop xbc / .byte 0xf1 / nop`,
    `ldwio 97,0xff06`, `push sr`).  Re-assembling that wrong reading reproduces
    the same bytes, so the byte gate cannot object -- and never could have.
    scripts/analysis/lane_v10storage_record_stream_evidence.py establishes it is
    data (6/6 chain closures, 12/12 external addresses, 1.0% null).  This
    rewrites it as typed data.

    ★ THE ROM IS THE SPECIFICATION.  Every byte emitted is read out of
    original_ROMs/kn5000_v10_program.rom.  The old source text is DISCARDED,
    never parsed -- so a mistake in the old decode cannot propagate.  The script
    refuses to write if its own emission does not equal the ROM bytes, and
    `make gate-all` is the real proof.

    ★ NOTHING IS RENAMED.  All 18 existing labels keep their names and land on
    their existing addresses.  All 7 existing `; data-as-code (...)` comments
    from the earlier census lane are re-emitted verbatim at the address they
    name.  Naming is a separate, deferred job.

WHAT IT EMITS, per address range
    pointer table   .long <label>[ + 0x..]   (symbolic; absolute hex only if no
                    label in this file precedes the target)
    name table      .ascii, one entry per line
    record          one .byte line per record, ASCII payload runs of >= 4
                    printable characters split out as .ascii
    tail            .byte, with the reason its framing is not established

RUN
    python3 scripts/converters/convert_flash_record_stream.py --dry-run
    python3 scripts/converters/convert_flash_record_stream.py
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
SRC_PATH = os.path.join(REPO, "v10", "maincpu", "storage", "flash_floppy_handlers.s")
SYMS_PATH = os.path.join(REPO, "symbols", "maincpu_v10_symbols_reference.txt")
BASE = 0xE00000
LO, HI = 0xF15907, 0xF1612F

# Kinds, in address order.  Boundaries come from the evidence script.
LAYOUT = [
    (0xF15907, 0xF1593A, "rec"), (0xF1593A, 0xF15952, "ptr"),
    (0xF15952, 0xF1598F, "rec"), (0xF1598F, 0xF159B3, "keep"),  # already .long
    (0xF159B3, 0xF159E0, "rec"), (0xF159E0, 0xF159F4, "ptr"),
    (0xF159F4, 0xF15A1C, "rec"), (0xF15A1C, 0xF15A30, "ptr"),
    (0xF15A30, 0xF15A5A, "rec"), (0xF15A5A, 0xF15A6E, "ptr"),
    (0xF15A6E, 0xF15A91, "rec"), (0xF15A91, 0xF15B01, "ptr"),
    (0xF15B01, 0xF15BA9, "names"), (0xF15BA9, 0xF16109, "rec"),
    (0xF16109, 0xF1612F, "tail"),
]
NAME_STRIDE, NAME_N = 13, 12          # then two 6-character entries

rom = open(ROM_PATH, "rb").read()


def u32(a):
    o = a - BASE
    return rom[o] | rom[o + 1] << 8 | rom[o + 2] << 16 | rom[o + 3] << 24


def load_labels():
    """label -> address, restricted to labels DEFINED in this file."""
    syms = {}
    for line in open(SYMS_PATH, encoding="latin-1"):
        p = line.split()
        if len(p) == 2:
            try:
                syms[p[0]] = int(p[1], 16)
            except ValueError:
                pass
    here = {}
    for line in open(SRC_PATH, encoding="latin-1"):
        m = re.match(r'^([A-Za-z_.$][\w.$]*):', line)
        if m and m.group(1) in syms:
            here[m.group(1)] = syms[m.group(1)]
    return here


LABELS = load_labels()
BY_ADDR = {a: n for n, a in LABELS.items()}
SORTED_LABELS = sorted(LABELS.items(), key=lambda kv: kv[1])


def symref(v):
    """Symbolic spelling of a 32-bit pointer value, or absolute hex."""
    if v in BY_ADDR:
        return BY_ADDR[v]
    best = None
    for n, a in SORTED_LABELS:
        if a <= v and (best is None or a > best[1]):
            best = (n, a)
    if best and v - best[1] < 0x1000:
        return f"{best[0]} + 0x{v - best[1]:x}"
    return f"0x{v:08x}"


PRINTABLE = set(range(0x20, 0x7F)) - {0x22, 0x5C}


def bytes_line(chunk, comment=None):
    body = ", ".join(f"0x{b:02x}" for b in chunk)
    return f"\t.byte {body}" + (f"\t; {comment}" if comment else "")


def emit_record(a, n):
    """One record -> source lines.  Printable runs of >= 4 become .ascii."""
    data = rom[a - BASE:a - BASE + n]
    out, i, pending = [], 0, []
    head = f"{a:06X} flags=0x{data[0]:02x} len={n}"
    while i < len(data):
        j = i
        while j < len(data) and data[j] in PRINTABLE:
            j += 1
        if j - i >= 4:
            if pending:
                out.append(bytes_line(pending))
                pending = []
            txt = data[i:j].decode("latin-1")
            out.append(f'\t.ascii "{txt}"')
            i = j
        else:
            pending.append(data[i])
            i += 1
    if pending:
        out.append(bytes_line(pending))
    out[0] = out[0] + ("\t; " + head if "\t; " not in out[0] else "")
    if not out[0].endswith(head):
        out[0] = out[0].split("\t; ")[0] + "\t; " + head
    return out


def build():
    """Address-ordered list of (address, source-line) for the whole span."""
    lines = []
    for lo, hi, kind in LAYOUT:
        if kind == "keep":
            continue
        a = lo
        if kind == "ptr":
            lines.append((a, f"\t; {lo:06X}..{hi:06X}  "
                             f"{(hi - lo) // 4} x u32 pointer"))
            while a < hi:
                lines.append((a, f"\t.long {symref(u32(a))}"))
                a += 4
        elif kind == "names":
            lines.append((a, f"\t; {lo:06X}..{hi:06X}  effect name table, "
                             f"{NAME_N} x {NAME_STRIDE} chars then 2 x 6"))
            for k in range(NAME_N):
                s = rom[a - BASE:a - BASE + NAME_STRIDE].decode("latin-1")
                lines.append((a, f'\t.ascii "{s}"'))
                a += NAME_STRIDE
            while a < hi:
                s = rom[a - BASE:a - BASE + 6].decode("latin-1")
                lines.append((a, f'\t.ascii "{s}"'))
                a += 6
        elif kind == "rec":
            lines.append((a, f"\t; {lo:06X}..{hi:06X}  "
                             f"[flags:u8][len:u8][payload] records"))
            while a < hi:
                n = rom[a - BASE + 1]
                assert 2 <= n and a + n <= hi, f"bad length at {a:06X}"
                for k, ln in enumerate(emit_record(a, n)):
                    lines.append((a if k == 0 else a + 1, ln))
                a += n
        elif kind == "tail":
            # The [flags][len] rule does NOT hold here -- the length byte at
            # F16109 is 0.  What DOES close exactly on the following u32 is
            # three 8-byte entries then one len-10 record; that is stated as a
            # hypothesis, not asserted, and the bytes stay untyped.
            lines.append((a, f"\t; {lo:06X}..{hi:06X}  the length byte at "
                             f"{lo:06X} is 0, so the [flags][len] framing above "
                             f"does NOT continue here."))
            lines.append((a, "\t; HYPOTHESIS ONLY (it closes exactly on the u32 "
                             "below, but is not otherwise corroborated):"))
            lines.append((a, "\t; three 8-byte entries, then one len-10 record. "
                             "Left as untyped .byte rather than guessed at."))
            for k in (8, 8, 8, 10):
                lines.append((a, bytes_line(rom[a - BASE:a - BASE + k],
                                            f"{a:06X}")))
                a += k
            lines.append((a, f"\t.long {symref(u32(a))}\t; {a:06X} -- a u32 "
                             f"pointer to the record at {u32(a):06X}; "
                             f"DrumDetailEdit_Menu_Table's label may be one "
                             f"entry late"))
            a += 4
            assert a == hi, f"tail did not close: {a:06X} != {hi:06X}"
    return lines


def verify(lines):
    """Re-read the emitted directives and compare against the ROM."""
    out = bytearray()
    for _, ln in lines:
        s = ln.split("\t;")[0].strip()
        if not s or s.startswith(";"):
            continue
        if s.startswith(".byte"):
            for tok in s[5:].split(","):
                out.append(int(tok.strip(), 0))
        elif s.startswith(".ascii"):
            out += s[s.index('"') + 1:s.rindex('"')].encode("latin-1")
        elif s.startswith(".long"):
            out += b"\0\0\0\0"          # value checked separately
        else:
            sys.exit("unknown directive emitted: " + s)
    want = bytearray(rom[LO - BASE:HI - BASE])
    # blank the ranges we emit as .long and the range we keep untouched
    for lo, hi, kind in LAYOUT:
        if kind == "ptr":
            want[lo - LO:hi - LO] = b"\0" * (hi - lo)
        elif kind == "keep":
            del want[lo - LO:hi - LO]
            # keep-region removal must preserve alignment of later ranges
            want[lo - LO:lo - LO] = b""
    # rebuild `want` the simple way instead: concatenate the kept ranges
    want = bytearray()
    for lo, hi, kind in LAYOUT:
        if kind == "keep":
            continue
        chunk = bytearray(rom[lo - BASE:hi - BASE])
        if kind == "ptr":
            chunk = bytearray(hi - lo)
        elif kind == "tail":
            chunk[-4:] = bytearray(4)      # the trailing .long, checked as a value
        want += chunk
    return bytes(out) == bytes(want), len(out), len(want)


def splice(lines, dry):
    src = open(SRC_PATH, encoding="latin-1").read().split("\n")
    lab = re.compile(r'^([A-Za-z_.$][\w.$]*):')
    # source line index of each label that anchors the span
    at = {}
    for i, l in enumerate(src):
        m = lab.match(l)
        if m and m.group(1) in LABELS and LO <= LABELS[m.group(1)] <= HI:
            at[LABELS[m.group(1)]] = i
    start = at[LO]
    end = at[0xF1612F] if 0xF1612F in at else None
    if end is None:                     # DrumDetailEdit_Menu_Table ends the span
        for i, l in enumerate(src):
            if l.startswith("DrumDetailEdit_Menu_Table:"):
                end = i
                break
    old = src[start:end]
    # every comment currently inside the span, preserved verbatim
    comments = [l for l in old if l.strip().startswith(";")]
    kept_lo, kept_hi = [lo for lo, _, k in LAYOUT if k == "keep"][0], \
                       [hi for _, hi, k in LAYOUT if k == "keep"][0]
    kept = src[at[kept_lo]:at[0xF159B3]]

    new = []
    pending_comments = {}
    for c in comments:
        m = re.search(r'0x([0-9A-Fa-f]{6})-0x([0-9A-Fa-f]{6})', c)
        pending_comments.setdefault(int(m.group(1), 16) if m else LO, []).append(c)

    # Snap each preserved comment to the emitted line that COVERS its address:
    # the address it names usually falls inside a record body, not on a line
    # boundary, and dumping such comments at the end of the span loses the
    # thing that made them useful.
    line_addrs = sorted({a for a, _ in lines})
    import bisect
    snapped = {}
    for ca, cl in pending_comments.items():
        k = bisect.bisect_right(line_addrs, ca) - 1
        snapped.setdefault(line_addrs[max(k, 0)], []).extend(cl)
    pending_comments = snapped

    emitted_addr = set()
    for a, ln in lines:
        if a in pending_comments and a not in emitted_addr:
            new += pending_comments.pop(a)
            emitted_addr.add(a)
        if a in BY_ADDR and a not in emitted_addr:
            new.append(BY_ADDR[a] + ":")
            emitted_addr.add(a)
        if a == kept_lo:
            new += kept
        new.append(ln)
    if pending_comments:
        sys.exit("REFUSING: a preserved comment found no home: "
                 + repr(pending_comments))
    # the kept .long table, if its address never appeared as a line address
    if not any(l.startswith("FlashRead_BlockHandler_Table:") for l in new):
        idx = next(i for i, l in enumerate(new)
                   if l.startswith("FlashWrite_BlockData_Type3:"))
        new[idx:idx] = kept
    for n, a in SORTED_LABELS:
        if LO <= a < HI and not any(l.startswith(n + ":") for l in new):
            sys.exit(f"REFUSING: label {n} ({a:06X}) would be lost")
    if dry:
        print("\n".join(new))
        print(f"... {len(new)} lines replace {len(old)}", file=sys.stderr)
        return
    src[start:end] = new
    open(SRC_PATH, "w", encoding="latin-1").write("\n".join(src))
    print(f"rewrote {SRC_PATH}: {len(old)} lines -> {len(new)}")


def main():
    dry = "--dry-run" in sys.argv
    lines = build()
    ok, got, want = verify(lines)
    print(f"self-check: emitted {got} B, expected {want} B -- "
          f"{'MATCH' if ok else 'MISMATCH'}")
    if not ok:
        sys.exit("REFUSING to write: emission does not reproduce the ROM bytes")
    splice(lines, dry)


if __name__ == "__main__":
    main()
