#!/usr/bin/env python3
"""Emit any prom_a address range as assembly, with address labels and .fill pads.

QUESTION IT ANSWERS
  "I want the whole of this .incbin span in the source; what does it look like?"
  notes/gen_prom_a_ringbuf_module.py answers that for one module whose meaning is
  fully established.  This is the general form, for spans where some routines are
  understood and some are not:

    * instructions come from prom_a/roundtrip.py, which assembles and byte-compares
      every candidate spelling and re-assembles the labelled block before printing
      it, so nothing it emits can break the byte gate;
    * a LABEL is placed at every address in range that some site actually names --
      absolute `call`/`jp`, PC-relative `calr`/`jr`/`jrl`, or a prom_b directory
      slot -- computed by notes/prom_a_ringbuf_map.all_refs();
    * labels are `sub_XXXXXX` by default.  That is an ADDRESS label, not a claim:
      this tree's rule is to prefer one plus a stated gap over a plausible name.
      Semantic names come from a table passed in, one entry per name that has an
      Evidence line in the header file;
    * runs of 0x0E (RET) padding become `.fill`, and the script REFUSES if the run
      is not uniform, so a pad claim is checked byte by byte rather than sampled.

  ⚠ It decodes LINEARLY from the start of the range.  That is legitimate for a
  span that begins at a module boundary, but a table embedded in the middle of one
  desynchronises the decode; unidasm's own text is kept in a trailing comment on
  every line so the damage is visible, and roundtrip falls back to `.byte`.

RUN
  python3 notes/gen_prom_a_block.py 0xF8BC00 0xF8E47F > /tmp/region.s
  python3 prom_a/insert_region.py 0xF8BC00 0xF8E47F /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import roundtrip as RT                                          # noqa: E402
import prom_a_ringbuf_map as MAP                                # noqa: E402

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
HDRS = os.path.join(ROOT, "notes", "prom_a_block_headers.txt")
MIN_PAD = 32


def load_headers():
    """notes/prom_a_block_headers.txt -> ({addr: header}, {addr: name}, [data]).

    Keys:
      @@AT   0xADDR              header block placed above 0xADDR's label
      @@NAME 0xADDR Some_Name    the same, and the label is Some_Name not sub_
      @@DATA 0xLO 0xHI Name      0xLO..0xHI is DATA: emitted as .byte, never
                                 decoded, with this header above it
      @@LONG 0xLO 0xHI Name      the same, but emitted as one `.long` per
                                 4-byte little-endian word, each with its own
                                 index and value in a trailing comment.  Use it
                                 only where the 4-byte framing is ESTABLISHED
                                 (an entry count read out of the reader's own
                                 compare, a last-entry test); `.byte` is the
                                 honest default and this is the claim.
                                 REFUSES if the span is not a multiple of 4.
    """
    hdr, name, data = {}, {}, []
    if not os.path.exists(HDRS):
        return hdr, name, data
    for part in open(HDRS, encoding="utf-8").read().split("@@")[1:]:
        key, _, body = part.partition("\n")
        key, body = key.strip(), body.rstrip("\n")
        m = re.match(r"^(NAME|AT)\s+(0x[0-9A-Fa-f]+)(?:\s+(\S+))?$", key)
        if m:
            at = int(m.group(2), 16)
            if m.group(1) == "NAME":
                name[at] = m.group(3)
            hdr[at] = body
            continue
        m = re.match(r"^(DATA|LONG)\s+(0x[0-9A-Fa-f]+)\s+(0x[0-9A-Fa-f]+)\s+(\S+)$",
                     key)
        if m:
            data.append((int(m.group(2), 16), int(m.group(3), 16), m.group(4), body,
                         m.group(1)))
    return hdr, name, data


def bytes_block(lo, hi, label, header):
    """A data region, emitted as .byte and never decoded."""
    out = [header, "%s:" % label]
    for at in range(lo, hi, 16):
        row = ROM[at - BASE:min(at + 16, hi) - BASE]
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in row)
                   + "%s ; %06X" % (" " * max(1, 76 - 7 - 6 * len(row)), at))
    return out


def longs_block(lo, hi, label, header):
    """A data region whose 4-byte framing is established: one `.long` per word."""
    if (hi - lo) % 4:
        sys.exit("REFUSED: 0x%06X-0x%06X is not a whole number of 32-bit words"
                 % (lo, hi))
    out = [header, "%s:" % label]
    for k, at in enumerate(range(lo, hi, 4)):
        w = int.from_bytes(ROM[at - BASE:at - BASE + 4], "little")
        out.append("\t.long 0x%08x%s ; %06X  [%3d]" % (w, " " * 32, at, k))
    return out


def pad_runs(lo, hi):
    """[(start, end)] maximal runs of >= MIN_PAD 0x0E bytes inside [lo,hi).

    ⚠ THE FIRST BYTE OF A RUN THAT FOLLOWS CODE BELONGS TO THE CODE.  0x0E is
    RET, so a routine's own return instruction is indistinguishable from the
    pad that follows it, and a naive run scan swallows it -- which it did on
    0xF83215, 0xF8BF21, 0xF8DAB9 and 0xF8DDE5, in every case leaving the last
    routine of a module without its return.  So a run that does not start at
    `lo` gives its first byte back.  The byte gate is blind to this either way;
    what it costs is a routine that reads as falling off its own end.
    """
    out, i = [], lo
    while i < hi:
        if ROM[i - BASE] == 0x0E:
            j = i
            while j < hi and ROM[j - BASE] == 0x0E:
                j += 1
            if j - i >= MIN_PAD:
                out.append((i + 1, j) if i > lo else (i, j))
            i = j
        else:
            i += 1
    return out


_DECODED = {}


def decode_region(lo, hi):
    """RT.emit_block, cached, plus the set of addresses that really got an
    instruction line.  main() needs that set BEFORE it renders anything: a
    label is only legal if some line defines it, and this generator used to
    substitute `call sub_FAAE92` for `call 0xfaae92` on the strength of an
    opcode-anchored reference scan alone -- for an address that is two bytes
    inside another instruction and therefore never gets a line.  The result was
    `ld.lld: error: undefined symbol`.  Failing at link is the lucky case; the
    unlucky one is a label that lands somewhere plausible."""
    if (lo, hi) not in _DECODED:
        lines, ok, stats = RT.emit_block(lo, hi)
        if not ok:
            sys.exit("REFUSED: 0x%06X-0x%06X did not re-assemble to the ROM"
                     % (lo, hi))
        _DECODED[(lo, hi)] = (lines, {a for _, a, _, _ in lines if a is not None})
    return _DECODED[(lo, hi)]


def emit(lo, hi, labels, hdr):
    lines, _ = decode_region(lo, hi)
    out, seen = [], set()

    def put_label(a):
        if a in hdr:
            out.append(hdr[a])
        out.append("%s:" % labels[a])
        seen.add(a)

    udis = {r[0]: r[4] for r in RT.convert(lo, hi)[0]}
    for text, addr, bs, why in lines:
        if addr is None:
            a = int(text.strip().rstrip(":")[2:], 16)
            if a in labels:
                put_label(a)
            else:
                out.append(text)
            continue
        t = text
        for a, nm in labels.items():
            t = t.replace(".L%06X" % a, nm)
        for kw in ("call ", "jp "):
            if t.strip().startswith(kw):
                op = t.strip()[len(kw):].strip()
                if op.startswith("0x") and int(op, 16) in labels:
                    t = "\t%s%s" % (kw, labels[int(op, 16)])
        if addr in labels and addr not in seen:
            put_label(addr)
        tail = ""
        if t.strip().startswith(".byte") and udis.get(addr):
            tail = "   " + udis[addr]
        out.append("%-53s ; %06X  %s%s"
                   % (t, addr, " ".join("%02x" % b for b in bs), tail))
    return out, None


def fill(lo, hi):
    seen = set(ROM[lo - BASE:hi - BASE])
    if seen != {0x0E}:
        sys.exit("REFUSED: 0x%06X-0x%06X is not uniform 0x0E (%r)" % (lo, hi, seen))
    return ["",
            "; 0x%06X-0x%06X -- %d bytes of 0x0E (RET), module padding."
            % (lo, hi - 1, hi - lo),
            "; Checked byte by byte, not sampled: notes/gen_prom_a_block.py "
            "refuses to",
            "; emit this directive unless set(ROM[lo:hi]) == {0x0E}.",
            "\t.fill %d, 1, 0x0E" % (hi - lo), ""]


def main():
    lo, hi = int(sys.argv[1], 16), int(sys.argv[2], 16)
    hdr, semantic, data = load_headers()
    refs = MAP.all_refs()
    thunks = MAP.thunk_targets()
    # ⚠ all_refs() is opcode-anchored at every byte offset, so its `jr`/`jrl`
    # rows (opcodes 0x60-0x7F -- a quarter of the byte space) are mostly
    # coincidence: on the 0xF8DA00 module they invented five labels inside
    # instructions.  Intra-block branches do not need them anyway -- roundtrip
    # labels every branch target it DECODES.  So only the call-shaped
    # references and the directory slots put a label here.
    named = {t for t, sites in refs.items()
             if lo <= t < hi and any(k in ("call", "jp", "calr") for k, _ in sites)}
    named |= {t for t in thunks if lo <= t < hi}
    named.add(lo)
    labels = {a: semantic.get(a, "sub_%06X" % a) for a in named}

    # regions that must NOT be decoded: 0x0E pad, and the declared data tables
    regions = [(a, b, "pad", None, None) for a, b in pad_runs(lo, hi)]
    regions += [(a, b, kind.lower(), nm, hd)
                for a, b, nm, hd, kind in data if lo <= a < hi]
    regions.sort()
    for i in range(1, len(regions)):
        if regions[i][0] < regions[i - 1][1]:
            sys.exit("REFUSED: overlapping non-code regions %r %r"
                     % (regions[i - 1][:3], regions[i][:3]))
    # PASS 1 -- which addresses will actually carry an instruction line?
    code, at = [], lo
    for rlo, rhi, kind, nm, hd in regions:
        if rlo > at:
            code.append((at, rlo))
        at = rhi
    if at < hi:
        code.append((at, hi))
    emitted = set()
    for clo, chi in code:
        emitted |= decode_region(clo, chi)[1]
    dropped = sorted(a for a in labels if a not in emitted)
    labels = {a: n for a, n in labels.items() if a in emitted}
    for a in dropped:
        sys.stderr.write("no label at 0x%06X: it is not an instruction boundary "
                         "of this decode, or it is inside a declared data "
                         "region\n" % a)

    # PASS 2 -- render
    out, at = [], lo
    for rlo, rhi, kind, nm, hd in regions:
        if rlo > at:
            b, _ = emit(at, rlo, labels, hdr)
            out += b
        if kind == "pad":
            out += fill(rlo, rhi)
        elif kind == "long":
            out += longs_block(rlo, rhi, nm, hd)
        else:
            out += bytes_block(rlo, rhi, nm, hd)
        at = rhi
    if at < hi:
        b, _ = emit(at, hi, labels, hdr)
        out += b
    text = "\n".join(out)
    # REFUSE rather than emit an undefined symbol: every name used must be
    # defined by a line of this block.
    used = set(re.findall(r"\b(sub_[0-9A-F]{6})\b", text))
    defined = set(re.findall(r"^(sub_[0-9A-F]{6}):", text, re.M))
    if used - defined:
        sys.exit("REFUSED: %d label(s) referenced but never defined: %s"
                 % (len(used - defined), ", ".join(sorted(used - defined))))
    print(text)


if __name__ == "__main__":
    main()
