#!/usr/bin/env python3
"""mem_subopcode_gap_census.py -- WHICH memory-prefix SUB-OPCODES can the
TLCS-900 disassembler not read?

THE QUESTION THIS ANSWERS
-------------------------
`decoder_gap_ranking.py` ranks the decoder's gaps by LEADING BYTE and shows 171
of 655 sampled v10 statements are refused or mis-sized.  But the leading byte is
NOT the unit of the gap: `9f 06 81` is refused while `9f 08 23` reads fine.
Both start 0x9f; they differ in the SUB-OPCODE byte that follows the prefix and
its displacement.  Fixing "byte 0x9f" is not a thing you can do.

So this groups every v10 instruction statement by the pair the decoder actually
dispatches on:

    (which prefix TABLE the leading byte selects, SUB-OPCODE byte)

  * source memory, byte   0x80-0x8F   (0x88-0x8F carry a d8)
  * source memory, word   0x90-0x9F
  * source memory, long   0xA0-0xAF
  * destination memory    0xB0-0xBF

and reports, per (table, sub-opcode), how many v10 statements exist and how many
the decoder refuses or mis-sizes.  That is the list a decoder fix is written
from, and re-running it after the fix is what shows the fix landed.

METHOD
------
Ground truth is v10's OWN SOURCE, exactly as in decoder_gap_ranking.py:
`llvm-mc -show-encoding` over the whole tree gives every statement's exact bytes
and exact text.  Statements with a relocated operand are skipped (their bytes in
the source stream are placeholders).

Each distinct sample is laid into a fixed 16-byte slot padded with a repeating
cycle of one-byte flag instructions (rcf/scf/ccf/zcf), so the decoder always
resynchronises at the next slot, and the whole blob is disassembled ONCE.
⚠ The padding must NOT be a run of one repeated byte: llvm-objdump elides four
or more identical consecutive lines as `...`, which desynchronises the walk --
that is what the selftest's "walk reconciles" check pins.  A sample is a GAP when the decoder does not start an
instruction at its slot, refuses it, or consumes a different number of bytes
than the assembler emitted.  ⚠ The self-check in twin_framed_spans.decode()
still applies: a walk whose addresses are not contiguous returns nothing rather
than a plausible wrong answer.

⚠ A number from this script is a property of the DECODER as much as of the
bytes.  The toolchain commit is printed first; quote it beside any figure.

⚠ A DECODE THAT SUCCEEDS IS NOT YET A DECODE THAT IS RIGHT.  `--roundtrip`
adds the second half: every sample the decoder accepts is re-assembled from the
text it printed and the bytes are compared with the ROM's.  That is what catches
a decode which produces a plausible instruction with the WRONG spelling -- the
failure `b3 c8` had before this lane, where "bit 0, (xhl)" came back as
"and (xhl), xwa" and re-assembled to `a3 c8`, two different bytes, with nothing
anywhere reporting a problem.

⚠ AND A ROUND-TRIP THAT PASSES IS STILL NOT A DECODE THAT MEANS THE RIGHT
THING.  Bytes in, same bytes out, is satisfied by any self-consistent naming --
including one that calls an ADD a SUB.  `--oracle` adds the third check:
MAME's `unidasm -arch tlcs900`, an independently written TLCS-900 disassembler,
reads the same samples and its MNEMONIC and its instruction LENGTH must agree.
Spelling differs by design (this backend writes `resm 0, (xwa)` where unidasm
writes `res 0,(XWA)`), so mnemonics are compared through an explicit alias
table and anything not in it is reported rather than passed.

RUN
    python3 scripts/analysis/mem_subopcode_gap_census.py
    python3 scripts/analysis/mem_subopcode_gap_census.py --roundtrip
    python3 scripts/analysis/mem_subopcode_gap_census.py --oracle
    python3 scripts/analysis/mem_subopcode_gap_census.py --selftest

--roundtrip covers v7, v9 and v10; the plain run covers v10 only, matching
decoder_gap_ranking.py's sample space.
"""
import collections
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import twin_framed_spans as T                                   # noqa: E402

SLOT = 16
# rcf/scf/ccf/zcf -- four distinct one-byte instructions, so no two adjacent
# disassembly lines are identical and llvm-objdump never elides them as "...".
PAD = bytes([0x10, 0x11, 0x12, 0x13])


def pad_to_slot(blob):
    return blob + bytes(PAD[i % 4] for i in range(SLOT - len(blob)))

# leading byte -> (table name, bytes of prefix before the sub-opcode)
#
# Register-indirect prefixes carry the sub-opcode at byte 1 (no displacement) or
# byte 2 (one d8 byte).  DIRECT-ADDRESS prefixes carry 1, 2 or 3 address bytes
# first -- the low two bits of the prefix choose which -- and the sub-opcode
# comes after them.  Both families dispatch on the same sub-opcode TABLES, which
# is why they belong in one census.
def classify(lead):
    if lead in (0xC0, 0xD0, 0xE0, 0xF0):
        return ({0xC0: "d8io8", 0xD0: "d8io16", 0xE0: "d8io32",
                 0xF0: "d8io_dst"}[lead], 2)
    if lead in (0xC1, 0xD1, 0xE1, 0xF1):
        return ({0xC1: "da16_8", 0xD1: "da16_16", 0xE1: "da16_32",
                 0xF1: "da16_dst"}[lead], 3)
    if lead in (0xC2, 0xD2, 0xE2, 0xF2):
        return ({0xC2: "da24_8", 0xD2: "da24_16", 0xE2: "da24_32",
                 0xF2: "da24_dst"}[lead], 4)
    if 0x80 <= lead <= 0x87:
        return ("src8", 1)
    if 0x88 <= lead <= 0x8F:
        return ("src8+d8", 2)
    if 0x90 <= lead <= 0x97:
        return ("src16", 1)
    if 0x98 <= lead <= 0x9F:
        return ("src16+d8", 2)
    if 0xA0 <= lead <= 0xA7:
        return ("src32", 1)
    if 0xA8 <= lead <= 0xAF:
        return ("src32+d8", 2)
    if 0xB0 <= lead <= 0xB7:
        return ("dst", 1)
    if 0xB8 <= lead <= 0xBF:
        return ("dst+d8", 2)
    return (None, 0)


UNIDASM = os.path.expanduser("~/compartilhado/mame/unidasm")

# This backend's mnemonic -> the mnemonic(s) MAME's unidasm prints for the same
# bytes.  Every entry is a NAMING difference only, so adding one asserts the two
# tools mean the same instruction -- check before extending.  A set is needed
# because unidasm suffixes several mnemonics with the operand width where this
# backend puts the width in the instruction's own name, or the other way round
# (`incm8` is unidasm's `inc`, `incm` is its `incw`).
ORACLE_ALIAS = {
    "cpw": {"cp"},
    "ldw": {"ldw", "ld"}, "ldb": {"ld"},
    "addiw_da": {"add"}, "submi16": {"sub"}, "andmi16": {"and"},
    "ormi16": {"or"}, "xormi16": {"xor"}, "adcmi16": {"adc"},
    "sbcmi16": {"sbc"}, "cpmi16": {"cp"},
    "addmi8": {"add"}, "submi8": {"sub"}, "andmi8": {"and"}, "ormi8": {"or"},
    "xormi8": {"xor"}, "adcmi8": {"adc"}, "sbcmi8": {"sbc"}, "cpmi8": {"cp"},
    "resm": {"res"}, "setm": {"set"}, "bitm": {"bit"}, "chgm": {"chg"},
    "tsetm": {"tset"}, "ldcfm": {"ldcf"}, "stcfm": {"stcf"},
    "pushm": {"push", "pushw"}, "popm": {"pop"}, "popmw": {"popw"},
    "incm8": {"inc"}, "incm": {"incw"}, "decm8": {"dec"}, "decm": {"decw"},
    "ret_cc_ri": {"ret"},
    "ldir83": {"ldir"}, "ldir85": {"ldir"}, "lddr83": {"lddr"},
    "lddr85": {"lddr"}, "ldi85": {"ldi"}, "cpir83": {"cpir"},
    "ldirw93": {"ldirw"}, "ldiw": {"ldiw", "ldi"},
    "rlcw": {"rlcw"}, "rrcw": {"rrcw"}, "rlw": {"rlw"}, "rrw": {"rrw"},
    "slaw": {"slaw"}, "sraw": {"sraw"}, "sllw": {"sllw"}, "srlw": {"srlw"},
}

# The direct-address family names every form after its ADDRESSING MODE as well
# as its operation -- `cpdi8` is "CP, direct address, immediate, 8-bit" -- where
# unidasm prints the bare operation and lets the operands say the rest.  The
# suffix alphabet is: d=direct, a=address operand, i=immediate, m=memory
# destination, b/w/l=byte/word/long, _24=24-bit address, _d8/_d16=address width,
# _dd8=8-bit destination direct.  So the operation is the leading token, and
# every entry below pairs one of this backend's names with the operation
# unidasm reads out of the same bytes.
#
# ⚠ This table only SUPPRESSES KNOWN NAMING NOISE.  The substantive checks do
# not consult it: instruction LENGTH must agree, a form unidasm calls `db` must
# not decode here, and no single name of ours may map to two different unidasm
# operations across the corpus (reported as INCONSISTENT).  A pair that is not
# in this table is printed, not passed.
for _stem, _op in [
    ("addda", "add"), ("adddi", "add"), ("adddm", "add"), ("addl_da", "add"),
    ("subda", "sub"), ("subdi", "sub"), ("subdm", "sub"),
    ("andda", "and"), ("anddi", "and"), ("anddm", "and"),
    ("orda", "or"), ("ordi", "or"), ("ordm", "or"), ("orddm", "or"),
    ("xorda", "xor"), ("xordi", "xor"), ("xordm", "xor"),
    ("cpda", "cp"), ("cpdi", "cp"), ("cpdm", "cp"), ("cpib_da", "cp"),
    ("cpw_da", "cp"),
    ("bitda", "bit"), ("bit_dd8", "bit"),
    ("setda", "set"), ("set_dd8", "set"),
    ("resda", "res"), ("res_dd8", "res"),
    ("chgda", "chg"), ("tsetda", "tset"),
    ("ldcf_dd8", "ldcf"), ("xorcf_dd8", "xorcf"),
    ("lda_", "lda"), ("lda_24", "lda"),
    ("ldb_", "ld"), ("ldw_", "ld"), ("ldl_da", "ld"), ("ldda32", "ld"),
    ("ld_sd8b", "ld"), ("ldmm8", "ld"),
    ("stb_", "ld"), ("stw_da", "ld"), ("stl_da", "ld"), ("stda", "ld"),
    ("stdi", "ld"), ("stib_", "ld"), ("stiw_", "ld"), ("st_dd8", "ld"),
    ("jp_dd8", "jp"),
]:
    pass
ORACLE_ALIAS.update({
    "addda8": {"add"}, "addda8_24": {"add"}, "addda16": {"add"},
    "addda16_24": {"add"}, "addda32": {"add"}, "addda32_24": {"add"},
    "adddi8": {"add"}, "adddi16": {"add"}, "adddi16_24": {"add"},
    "adddm8": {"add"}, "adddm16": {"add"}, "adddm16_24": {"add"},
    "adddm32": {"add"}, "addl_da": {"add"},
    "subda8": {"sub"}, "subda8_24": {"sub"}, "subda16": {"sub"},
    "subda16_24": {"sub"}, "subda32": {"sub"},
    "subdi8": {"sub"}, "subdi16": {"sub"}, "subdi16_24": {"sub"},
    "subdm8": {"sub"}, "subdm8_24": {"sub"}, "subdm16": {"sub"},
    "subdm32": {"sub"}, "subdm32_24": {"sub"},
    "andda8": {"and"}, "andda8_24": {"and"}, "andda16": {"and"},
    "andda16_24": {"and"}, "anddi8": {"and"}, "anddi8_24": {"and"},
    "anddi16": {"and"}, "anddi16_24": {"and"}, "anddm8": {"and"},
    "anddm8_24": {"and"}, "anddm16": {"and"}, "anddm16_24": {"and"},
    "orda8": {"or"}, "orda16": {"or"}, "orddm8": {"or"}, "orddm16": {"or"},
    "ordi8": {"or"}, "ordi8_24": {"or"}, "ordi16": {"or"}, "ordi16_24": {"or"},
    "ordm8_24": {"or"}, "ordm16_24": {"or"},
    "xorda8": {"xor"}, "xordi8": {"xor"}, "xordm8": {"xor"},
    "xordm16_24": {"xor"},
    "ldcfda": {"ldcf"}, "ldcfda_24": {"ldcf"},
    "stcfda": {"stcf"}, "stcfda_24": {"stcf"},
    "tsetda16": {"tset"}, "tsetda16_24": {"tset"},
    "pushdi_b": {"push"}, "pushdi_w": {"pushw"}, "pushdi_24": {"pushw"},
    "andda32_24": {"and"}, "anddm32_24": {"and"},
    "orda32_24": {"or"}, "ordm32_24": {"or"},
    "and_sd8b_im": {"and"}, "or_sd8b_im": {"or"},
    "cpda8": {"cp"}, "cpda8_24": {"cp"}, "cpda16": {"cp"}, "cpda16_24": {"cp"},
    "cpda32": {"cp"}, "cpda32_24": {"cp"}, "cpdi8": {"cp"}, "cpdi16": {"cp"},
    "cpdm8": {"cp"}, "cpdm8_24": {"cp"}, "cpdm16": {"cp"}, "cpdm16_24": {"cp"},
    "cpdm32": {"cp"}, "cpdm32_24": {"cp"}, "cpib_da": {"cp"}, "cpw_da": {"cp"},
    "bitda": {"bit"}, "bitda_24": {"bit"}, "bit_dd8": {"bit"},
    "setda": {"set"}, "setda_24": {"set"}, "set_dd8": {"set"},
    "resda": {"res"}, "resda_24": {"res"}, "res_dd8": {"res"},
    "chgda_24": {"chg"}, "tsetda": {"tset"}, "tsetda_24": {"tset"},
    "ldcf_dd8": {"ldcf"}, "xorcf_dd8": {"xorcf"},
    "lda_24": {"lda"}, "lda_d16": {"lda"}, "lda_dd8l": {"lda"},
    "ldb_d8": {"ld"}, "ldb_da": {"ld"}, "ldw_d16": {"ld"}, "ldw_da": {"ld"},
    "ldl_da": {"ld"}, "ldda32": {"ld"}, "ld_sd8b": {"ld"},
    "ldmm8": {"ld"}, "ldmm16": {"ldw"},
    "stb_d8": {"ld"}, "stb_da": {"ld"}, "stw_da": {"ld"}, "stl_da": {"ld"},
    "stda16": {"ld"}, "stda32": {"ld"}, "stdi8": {"ld"}, "stdi16": {"ld"},
    "stib_d8": {"ld"}, "stib_da": {"ld"}, "stiw_d8": {"ld"}, "stiw_da": {"ld"},
    "st_dd8b": {"ld"}, "st_dd8w": {"ld"}, "st_dd8l": {"ld"},
    "incdi8": {"inc"}, "incdi8_24": {"inc"}, "incdi16": {"incw"},
    "incdi16_24": {"incw"},
    "decdi8": {"dec"}, "decdi8_24": {"dec"}, "decdi16": {"decw"},
    "decdi16_24": {"decw"},
    "jp_dd8": {"jp"}, "jp_24": {"jp"}, "call_24": {"call"},
})


def unidasm(blob):
    """-> {offset: (nbytes, mnemonic)} from MAME's TLCS-900 disassembler."""
    import re
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        b = os.path.join(td, "b.bin")
        open(b, "wb").write(blob)
        r = subprocess.run([UNIDASM, b, "-arch", "tlcs900"],
                           capture_output=True, text=True)
    out, pend = {}, None
    for ln in r.stdout.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s+(\S+)', ln)
        if m:
            out[int(m.group(1), 16)] = (len(m.group(2).split()),
                                        m.group(3).lower())
    return out


def oracle(argv):
    """Compare this backend's decode of every v10 memory-prefix sample with
    MAME unidasm's, on LENGTH and MNEMONIC."""
    print("toolchain: %s" % subprocess.run(
        ["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
         "log", "-1", "--format=%h"], capture_output=True, text=True).stdout.strip())
    if not os.path.exists(UNIDASM):
        raise SystemExit("no unidasm at %s -- refusing to report an oracle "
                         "result without the oracle" % UNIDASM)
    T.load_roms()
    rom = T.ROMS["v10"]
    seen, index, flat = set(), [], bytearray()
    for off, ln, txt, reloc in T.flatten("v10")[5]:
        if reloc:
            continue
        tbl, pfx = classify(rom[off])
        if tbl is None or ln <= pfx or ln >= SLOT:
            continue
        blob = bytes(rom[off:off + ln])
        if blob in seen:
            continue
        seen.add(blob)
        index.append((len(flat), tbl, rom[off + pfx], blob, off))
        flat += pad_to_slot(blob)
    _, _, text, pos = T.decode(bytes(flat))
    if pos != len(flat):
        raise SystemExit("decode walk did not reconcile")
    mine = {o: (n, mn) for o, n, mn in text}
    theirs = unidasm(bytes(flat))
    agree = lenbad = mnbad = onlyme = onlythem = 0
    rows = []
    # ours -> {every unidasm operation seen for it}.  More than one entry is a
    # real signal: a name of ours covering two different operations means the
    # decoder is routing distinct sub-opcodes to the same definition.
    seen_pairs = collections.defaultdict(set)
    for slot, tbl, sub, blob, off in index:
        a = mine.get(slot)
        b = theirs.get(slot)
        if not a or not a[1]:
            if b and b[1] != "db":
                onlythem += 1
                rows.append(("THEM-ONLY", tbl, sub, off, blob, "-", b[1]))
            continue
        if not b or b[1] == "db":
            onlyme += 1
            rows.append(("ME-ONLY", tbl, sub, off, blob, a[1], "db"))
            continue
        amn = a[1].split()[0].split("\t")[0].lower()
        seen_pairs[amn].add(b[1])
        if a[0] != b[0]:
            lenbad += 1
            rows.append(("LENGTH", tbl, sub, off, blob,
                         "%d %s" % (a[0], amn), "%d %s" % (b[0], b[1])))
        elif b[1] not in ORACLE_ALIAS.get(amn, {amn}):
            mnbad += 1
            rows.append(("MNEMONIC", tbl, sub, off, blob, amn, b[1]))
        else:
            agree += 1
    print("\nv10 memory-prefix samples vs MAME unidasm:")
    print("  %5d agree on length and mnemonic" % agree)
    print("  %5d disagree on LENGTH        <- a real decoding disagreement" % lenbad)
    print("  %5d disagree on MNEMONIC      <- naming, or a real one; look" % mnbad)
    print("  %5d only this backend decodes (unidasm says db)" % onlyme)
    print("  %5d only unidasm decodes      <- remaining decoder gap" % onlythem)
    incons = {k: v for k, v in seen_pairs.items() if len(v) > 1}
    print("  %5d of our mnemonics map to MORE THAN ONE unidasm operation "
          "<- real" % len(incons))
    for k, v in sorted(incons.items()):
        print("        %-18s -> %s" % (k, ", ".join(sorted(v))))
    # Aggregated: one line per (kind, table, sub-opcode, ours, theirs), with a
    # count and the first real ROM address.  A per-sample dump buries a single
    # genuine disagreement under hundreds of copies of one naming difference.
    agg = collections.OrderedDict()
    for kind, tbl, sub, off, blob, a, b in rows:
        k = (kind, tbl, sub, a, b)
        if k not in agg:
            agg[k] = [0, off, blob]
        agg[k][0] += 1
    print("\n  %-9s %-9s %5s %6s  %-18s %-14s %s"
          % ("kind", "table", "subop", "count", "ours", "unidasm", "first site"))
    for (kind, tbl, sub, a, b), (n, off, blob) in sorted(
            agg.items(), key=lambda kv: -kv[1][0]):
        print("  %-9s %-9s  0x%02x %6d  %-18s %-14s 0x%06X [%s]"
              % (kind, tbl, sub, n, a, b, T.BASE + off, blob.hex(" ")))
    return 0


def reencode(lines):
    """Assemble one statement per line; -> [bytes] with None where refused.

    Assembled in ONE llvm-mc run when every line is accepted, and line by line
    only when that run fails, so a single unparseable statement cannot make the
    whole census report a false gap.
    """
    import re
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "a.s")
        open(s, "w").write(".text\n" + "\n".join(lines) + "\n")
        o = os.path.join(td, "a.o")
        r = subprocess.run([T.MC, "-triple=tlcs900", "-show-encoding", s],
                           capture_output=True, text=True)
        if r.returncode == 0:
            out = [None] * len(lines)
            i = 0
            for ln in r.stdout.split("\n"):
                m = re.search(r'encoding:\s*\[([^\]]*)\]', ln)
                if m:
                    out[i] = bytes(int(x, 16) for x in m.group(1).split(",")
                                   if x.strip())
                    i += 1
            if i == len(lines):
                return out
        out = []
        for ln in lines:
            open(s, "w").write(".text\n" + ln + "\n")
            r = subprocess.run([T.MC, "-triple=tlcs900", "-show-encoding", s],
                               capture_output=True, text=True)
            m = re.search(r'encoding:\s*\[([^\]]*)\]', r.stdout) if not r.returncode else None
            out.append(bytes(int(x, 16) for x in m.group(1).split(",")
                             if x.strip()) if m else None)
        return out


def roundtrip(argv):
    """Decode every distinct memory-prefix sample, re-assemble what was
    printed, and require the bytes back.  Covers all three images."""
    print("toolchain: %s" % subprocess.run(
        ["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
         "log", "-1", "--format=%h"], capture_output=True, text=True).stdout.strip())
    T.load_roms()
    for key in ("v7", "v9", "v10"):
        rom = T.ROMS[key]
        seen, index, flat = set(), [], bytearray()
        for off, ln, txt, reloc in T.flatten(key)[5]:
            if reloc:
                continue
            tbl, pfx = classify(rom[off])
            if tbl is None or ln <= pfx or ln >= SLOT:
                continue
            blob = bytes(rom[off:off + ln])
            if blob in seen:
                continue
            seen.add(blob)
            index.append((len(flat), tbl, rom[off + pfx], blob, off,
                          txt.strip().replace("\t", " ")))
            flat += pad_to_slot(blob)
        _, _, text, pos = T.decode(bytes(flat))
        if pos != len(flat):
            raise SystemExit("%s: decode walk did not reconcile" % key)
        got = {o: (n, mn) for o, n, mn in text}
        refused, printed = [], []
        for slot, tbl, sub, blob, off, txt in index:
            n, mn = got.get(slot, (0, ""))
            if not mn or n != len(blob):
                refused.append((tbl, sub, off, txt, blob))
            else:
                printed.append((tbl, sub, off, txt, blob, mn))
        back = reencode([p[5] for p in printed])
        bad = [(p, b) for p, b in zip(printed, back) if b != p[4]]
        print("\n%s: %d distinct memory-prefix samples, %d refused, "
              "%d decoded" % (key, len(index), len(refused), len(printed)))
        print("     %d of the decoded ones do NOT re-assemble to the ROM's bytes"
              % len(bad))
        # Aggregated by (table, sub-opcode, printed mnemonic): one genuine
        # class of failure buries itself among hundreds of its own instances
        # otherwise.
        agg = collections.OrderedDict()
        for (tbl, sub, off, txt, blob, mn), b in bad:
            k = (tbl, sub, mn.split()[0].split("\t")[0])
            if k not in agg:
                agg[k] = [0, off, txt, mn, blob, b]
            agg[k][0] += 1
        for (tbl, sub, _), (n, off, txt, mn, blob, b) in sorted(
                agg.items(), key=lambda kv: -kv[1][0]):
            print("       %-9s 0x%02x x%-4d 0x%06X  src %-24s -> %-24s "
                  "[%s] != [%s]"
                  % (tbl, sub, n, T.BASE + off, txt,
                     re.sub(r"\s+", " ", mn), blob.hex(" "),
                     b.hex(" ") if b else "REFUSED"))
    return 0


def run(argv):
    print("toolchain: %s" % subprocess.run(
        ["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
         "log", "-1", "--format=%h"], capture_output=True, text=True).stdout.strip())
    T.load_roms()
    instrs = T.flatten("v10")[5]
    rom = T.ROMS["v10"]

    # (table, subop) -> {"n": statements, "samples": {bytes: (off, text)}}
    groups = collections.defaultdict(lambda: {"n": 0, "samples": {}})
    for off, ln, txt, reloc in instrs:
        if reloc:
            continue
        tbl, pfx = classify(rom[off])
        if tbl is None or ln <= pfx:
            continue
        sub = rom[off + pfx]
        g = groups[(tbl, sub)]
        g["n"] += 1
        blob = bytes(rom[off:off + ln])
        if blob not in g["samples"] and len(blob) < SLOT:
            g["samples"][blob] = (off, txt.strip().replace("\t", " "))

    # One flat blob of every distinct sample, decoded in a single pass.
    flat, index = bytearray(), []
    for key in sorted(groups):
        for blob, (off, txt) in groups[key]["samples"].items():
            index.append((len(flat), key, blob, off, txt))
            flat += pad_to_slot(blob)
    _, _, text, pos = T.decode(bytes(flat))
    if pos != len(flat):
        raise SystemExit("decode walk did not reconcile -- refusing to report")
    got = {o: (n, mn) for o, n, mn in text}

    bad = collections.defaultdict(list)
    for slot, key, blob, off, txt in index:
        n, mn = got.get(slot, (0, ""))
        if not mn or n != len(blob):
            bad[key].append((off, txt, blob))

    print("\n%-9s %5s %7s %7s  %s" % ("table", "subop", "stmts", "gap", "example"))
    tot_n = tot_g = 0
    for key in sorted(groups, key=lambda k: (-len(bad.get(k, ())), k)):
        tbl, sub = key
        g = groups[key]
        tot_n += g["n"]
        b = bad.get(key, [])
        tot_g += len(b)
        if not b and "--all" not in argv:
            continue
        ex = ("0x%06X %s [%s]" % (T.BASE + b[0][0], b[0][1],
                                  b[0][2].hex(" ")) if b else "-")
        print("%-9s  0x%02x %7d %7d  %s" % (tbl, sub, g["n"], len(b), ex))
    print("\n%d distinct (table, sub-opcode) shapes; %d have at least one "
          "sample the decoder cannot read." % (len(groups), len(bad)))
    print("%d of %d distinct memory-prefix samples are refused or mis-sized."
          % (sum(len(v) for v in bad.values()), len(index)))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("classify splits 0x9f (src16+d8) from 0x90 (src16)",
       classify(0x9F) == ("src16+d8", 2) and classify(0x90) == ("src16", 1))
    ck("classify ignores a non-memory leading byte", classify(0x11)[0] is None)
    # The slot mechanism itself: a form the decoder DOES read must come back
    # with the right size, and 0x00 padding must not be mistaken for it.
    blob = pad_to_slot(bytes([0x11])) + pad_to_slot(bytes([0x11]))
    _, _, text, pos = T.decode(blob)
    got = {o: (n, mn) for o, n, mn in text}
    ck("a 1-byte instruction lands in slot 0 with size 1",
       got.get(0) == (1, "scf"), repr(got.get(0)))
    ck("the next slot starts a fresh decode", got.get(SLOT, (0, ""))[0] == 1)
    ck("the walk reconciles", pos == len(blob))
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--roundtrip" in sys.argv:
        sys.exit(roundtrip(sys.argv))
    sys.exit(oracle(sys.argv) if "--oracle" in sys.argv else run(sys.argv))
